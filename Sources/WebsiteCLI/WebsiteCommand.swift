import ArgumentParser
import Foundation
import SiteKit
import Website

@main
struct WebsiteCommand: AsyncParsableCommand {
	static let configuration = CommandConfiguration(
		commandName: "website",
		abstract: "Build sindresorhus.com.",
		subcommands: [Build.self, Routes.self, Serve.self],
		defaultSubcommand: Build.self
	)
}

struct SiteOptions: ParsableArguments {
	@Option(help: "The repository root.")
	var root = "."

	@Option(help: "The output directory. Files in it that the site does not publish are deleted. Defaults to <root>/dist.")
	var output: String?

	var project: Project {
		Project(root: URL(filePath: root, directoryHint: .isDirectory, relativeTo: .currentDirectory()))
	}

	var outputDirectory: URL {
		output.map { URL(filePath: $0, directoryHint: .isDirectory, relativeTo: .currentDirectory()) } ?? project.root.appending(path: "dist")
	}

	@Flag(help: "Print how long each build step takes.")
	var verbose = false

	func loadSite() async throws -> Site {
		try await Site(content: SiteContent.load(from: project, cache: .forBuilds(of: project)))
	}

	/**
	Publishes the site and checks the internal links.

	- Parameter includesGallery: Publishes the component gallery too, for the preview server.
	*/
	func build(includesGallery: Bool = false) async throws {
		let site = try await measure("Load content and data") {
			try await loadSite()
		}

		let routes = site.routes(project: project, includesGallery: includesGallery)

		try await measure("Render and write \(routes.count) routes") {
			try await Publisher(site: Site.url, project: project, output: outputDirectory).publish(routes)
		}

		print("Published \(routes.count) routes to \(outputDirectory.path).")

		let brokenLinks = try await measure("Check links") {
			try await LinkValidator(site: Site.url, output: outputDirectory).brokenLinks()
		}

		guard brokenLinks.isEmpty else {
			print("Broken internal links:")

			for link in brokenLinks {
				let locations = site.content.sourceLocations(ofLink: link.link, onPage: link.page, project: project)
				print(locations.isEmpty ? "- \(link)" : locations.map { "- \($0): \(link.description.dropFirst(link.page.count + 2))" }.joined(separator: "\n"))
			}

			throw ExitCode.failure
		}
	}

	/**
	Runs a build step, and prints its duration with `--verbose`.
	*/
	private func measure<Value>(_ step: String, _ operation: () async throws -> Value) async rethrows -> Value {
		let clock = ContinuousClock()
		let start = clock.now
		let value = try await operation()

		if verbose {
			print("\(step): \((clock.now - start).formatted(.units(allowed: [.seconds, .milliseconds], width: .narrow)))")
		}

		return value
	}
}

extension WebsiteCommand {
	struct Build: AsyncParsableCommand {
		static let configuration = CommandConfiguration(abstract: "Publish the site and check the internal links.")

		@OptionGroup
		var options: SiteOptions

		func run() async throws {
			try await options.build()
		}
	}

	struct Routes: AsyncParsableCommand {
		static let configuration = CommandConfiguration(abstract: "List every route of the site.")

		@OptionGroup
		var options: SiteOptions

		func run() async throws {
			let routes = try await options.loadSite().routes(project: options.project)

			for route in routes.sorted(using: KeyPathComparator(\.path.description)) {
				let kind = switch route.output {
				case .page(let isInSitemap, _):
					isInSitemap ? "page" : "page (not indexed)"
				case .redirect(let destination):
					"redirect → \(destination)"
				case .file:
					"file"
				}

				print("\(route.path)  \(kind)")
			}
		}
	}

	struct Serve: AsyncParsableCommand {
		static let configuration = CommandConfiguration(
			abstract: "Publish the site, serve it locally, and rebuild it on changes.",
			discussion: "Changes in `content` and `public` rebuild the site. Changes in `Sources` rebuild this tool and restart it. Open pages reload after each rebuild."
		)

		@OptionGroup
		var options: SiteOptions

		@Option(name: .shortAndLong, help: "The HTTP port.")
		var port: UInt16 = 4321

		/**
		Set when the tool restarts itself after a source change, so it does not open the browser again.
		*/
		@Flag(help: .hidden)
		var restarted = false

		func run() async throws {
			// The watcher starts before the first build, so edits during the build are seen.
			let sources = options.project.root.appending(path: "Sources")
			let changes = DirectoryWatcher(directories: [options.project.root.appending(path: "content"), options.project.publicDirectory, sources]).makeAsyncIterator()

			await buildReportingErrors()

			// The server only listens on the IPv4 loopback address, and `localhost` can resolve to IPv6 first.
			let url = "http://127.0.0.1:\(port)"
			let server = PreviewServer(directory: options.outputDirectory, port: port, reloadsPages: true)

			let sourcesChanged = try await withThrowingTaskGroup(of: Bool.self) { group in
				group.addTask {
					try await server.run {
						print("Serving at \(url)")

						guard !restarted else {
							return
						}

						// Opens the site in the default browser.
						let process = Process()
						process.executableURL = URL(filePath: "/usr/bin/open")
						process.arguments = [url]
						try? process.run()
					}

					return false
				}

				group.addTask {
					await rebuildUntilSourcesChange(changes: changes, sources: sources, server: server)
				}

				// The server stops before a restart, so the new process can use the port.
				defer {
					group.cancelAll()
				}

				return try await group.next() ?? false
			}

			if sourcesChanged {
				try restart()
			}
		}

		/**
		Rebuilds the site when the content or public files change. Returns `true` when the sources change and the tool was rebuilt, and `false` when the task is cancelled.
		*/
		private func rebuildUntilSourcesChange(changes: DirectoryWatcher.Iterator, sources: URL, server: PreviewServer) async -> Bool {
			var changes = changes

			while let changed = await changes.next() {
				if changed.contains(sources) {
					print("The sources changed. Rebuilding the tool…")

					if buildTool() {
						return true
					}

					print("Fix the errors to continue.")

					// Content that changed at the same time is still rebuilt.
					guard changed.count > 1 else {
						continue
					}
				}

				print("Rebuilding the site…")
				await buildReportingErrors()
				server.reload()
			}

			return false
		}

		/**
		Builds the site. Errors are printed instead of thrown, so a mistake in the content does not stop the server.
		*/
		private func buildReportingErrors() async {
			do {
				try await options.build(includesGallery: true)
			} catch is ExitCode {
				// The broken links are already printed.
			} catch {
				print("Error: \(error)")
			}
		}

		/**
		Builds this tool with `swift build`, in the configuration of the running executable (debug or release). Returns whether it succeeded.
		*/
		private func buildTool() -> Bool {
			let configuration = Bundle.main.executableURL?.deletingLastPathComponent().lastPathComponent == "release" ? "release" : "debug"
			let process = Process()
			process.executableURL = URL(filePath: "/usr/bin/env")
			process.arguments = ["swift", "build", "--package-path", options.project.root.path(percentEncoded: false), "--product", "website", "--configuration", configuration]

			do {
				try process.run()
				process.waitUntilExit()
				return process.terminationStatus == 0
			} catch {
				print("Error: Could not run `swift build`: \(error)")
				return false
			}
		}

		/**
		Replaces the process with the rebuilt executable, with the same arguments.
		*/
		private func restart() throws {
			guard let executable = Bundle.main.executablePath else {
				throw ValidationError("Could not find the executable to restart.")
			}

			let arguments = CommandLine.arguments.contains("--restarted") ? CommandLine.arguments : CommandLine.arguments + ["--restarted"]
			var cArguments = arguments.map { strdup($0) } + [nil]
			fflush(stdout)

			// The new process keeps the signal mask of this thread, and concurrency threads block signals, which would make Control-C stop working.
			var signals = sigset_t()
			sigemptyset(&signals)
			pthread_sigmask(SIG_SETMASK, &signals, nil)

			execv(executable, &cArguments)

			// `execv` only returns when it fails.
			throw ValidationError("Could not restart: \(String(cString: strerror(errno)))")
		}
	}
}
