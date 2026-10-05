import ArgumentParser
import Foundation
import SiteKit
import System
import Website

@main
struct WebsiteCommand: AsyncParsableCommand {
	static let configuration = CommandConfiguration(
		commandName: "website",
		abstract: "Build sindresorhus.com.",
		subcommands: [Build.self, Check.self, Routes.self, Serve.self],
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

	var externalData: ExternalData {
		.fetch(.forBuilds(of: project))
	}

	/**
	Publishes the site, checks the internal links, and prints the report, with the broken links.

	- Parameter includesGallery: Publishes the component gallery too, for the preview server.
	- Parameter onPublished: Called after the files are written, before the links are checked.
	*/
	@discardableResult
	func build(includesGallery: Bool = false, onPublished: @Sendable () -> Void = {}) async throws -> Site.BuildReport {
		let report = try await Site.build(project: project, output: outputDirectory, externalData: externalData, includesGallery: includesGallery, onPublished: onPublished)

		for warning in report.warnings {
			print("Warning: \(warning)")
		}

		if verbose {
			for step in report.steps {
				print("\(step.name): \(step.duration.formatted(.units(allowed: [.seconds, .milliseconds], width: .narrow)))")
			}
		}

		print("Published \(report.routeCount) routes to \(outputDirectory.path(percentEncoded: false)).")

		if let brokenLinksText = report.brokenLinksText {
			print(brokenLinksText)
		}

		return report
	}
}

extension Site.BuildReport {
	/**
	The broken links as a list, or `nil` when every link works.
	*/
	fileprivate var brokenLinksText: String? {
		guard !brokenLinks.isEmpty else {
			return nil
		}

		return (["Broken internal links:"] + brokenLinks.map { "- \($0)" }).joined(separator: "\n")
	}
}

extension WebsiteCommand {
	struct Build: AsyncParsableCommand {
		static let configuration = CommandConfiguration(abstract: "Publish the site and check the internal links.")

		@OptionGroup
		var options: SiteOptions

		func run() async throws {
			guard try await options.build().brokenLinks.isEmpty else {
				throw ExitCode.failure
			}
		}
	}

	struct Check: AsyncParsableCommand {
		static let configuration = CommandConfiguration(abstract: "Build the site, and print possible mistakes that do not fail the build, like spelling mistakes and OS requirements that the App Store does not agree with.")

		@OptionGroup
		var options: SiteOptions

		func run() async throws {
			let report = try await options.build()
			let warnings = await report.content.warnings(project: options.project, output: options.outputDirectory)

			for warning in warnings {
				print("Warning: \(warning)")
			}

			// The build printed its own warnings, like failed requests, so they are counted too.
			let count = report.warnings.count + warnings.count
			print(count == 1 ? "1 warning." : "\(count == 0 ? "No" : String(count)) warnings.")

			// After the warnings, so a broken link does not hide them.
			guard report.brokenLinks.isEmpty else {
				throw ExitCode.failure
			}
		}
	}

	struct Routes: AsyncParsableCommand {
		static let configuration = CommandConfiguration(abstract: "List every route of the site.")

		@OptionGroup
		var options: SiteOptions

		func run() async throws {
			let content = try await SiteContent.load(from: options.project, externalData: options.externalData)
			let routes = Site(content: content).routes(project: options.project)

			for route in routes.sorted(using: KeyPathComparator(\.path.description)) {
				let kind = switch route.output {
				case .page(let sitemapEntry, _):
					sitemapEntry == nil ? "page (not indexed)" : "page"
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
			discussion: "Changes in `content` and `public`, and of the scripts of elements in `Sources`, rebuild the site. Other changes in `Sources` rebuild this tool and restart it. Open pages reload after each rebuild, and show build errors."
		)

		@OptionGroup
		var options: SiteOptions

		@Option(name: .shortAndLong, help: "The HTTP port. 0 picks a free port.")
		var port: UInt16 = 4321

		/**
		Set when the tool restarts itself after a source change, so it does not open the browser again.
		*/
		@Flag(help: .hidden)
		var restarted = false

		func run() async throws {
			let project = options.project
			let sources = project.root.appending(path: "Sources")
			let server = PreviewServer(directory: options.outputDirectory, port: port, reloadsPages: true)

			// The watcher starts before the first build, so edits during the build are seen.
			let changes = DirectoryWatcher(directories: [project.contentDirectory, project.publicDirectory, sources]).makeAsyncIterator()

			await build(server: server)

			let (listeningPorts, listeningPortContinuation) = AsyncStream.makeStream(of: UInt16.self)

			let sourcesChanged = try await withThrowingTaskGroup { group in
				group.addTask {
					try await server.run { port in
						listeningPortContinuation.yield(port)
						opened(port: port)
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

			listeningPortContinuation.finish()

			if sourcesChanged {
				// The port the system chose for `--port 0`, so the open pages find the new server.
				var ports = listeningPorts.makeAsyncIterator()
				try ToolRestarter.restart(project: options.project, port: await ports.next() ?? port)
			}
		}

		/**
		Watches for changes: content and public files rebuild the site, and sources rebuild the tool. The scripts of elements in the sources (``ElementScript``) only rebuild the site, as the build reads them from the sources, like the scripts in `public`. Returns `true` when the sources changed and the tool was rebuilt, so it can restart, and `false` when the task is cancelled.
		*/
		private func rebuildUntilSourcesChange(changes: DirectoryWatcher.Iterator, sources: URL, server: PreviewServer) async -> Bool {
			var changes = changes

			while let changed = await changes.next() {
				let changedSources = changed.filter { $0.isInside(sources) }

				if changedSources.contains(where: { $0.pathExtension != "js" }) {
					print("The sources changed. Rebuilding the tool…")

					if await ToolRestarter.build(project: options.project) {
						return true
					}

					// The build stopped because the watcher stopped, not because of errors.
					guard !Task.isCancelled else {
						return false
					}

					print("Fix the errors to continue.")
					server.show(error: "The tool does not build. The errors are in the terminal.")

					// Content that changed at the same time is still rebuilt.
					guard changed.count > changedSources.count else {
						continue
					}
				}

				print("Rebuilding the site…")
				await build(server: server)
			}

			return false
		}

		/**
		Prints the URL and opens it in the default browser, unless the tool restarted.
		*/
		private func opened(port: UInt16) {
			// The server only listens on the IPv4 loopback address, and `localhost` can resolve to IPv6 first.
			let url = "http://127.0.0.1:\(port)"
			print("Serving at \(url)")

			guard !restarted else {
				return
			}

			let process = Process()
			process.executableURL = URL(filePath: "/usr/bin/open")
			process.arguments = [url]
			try? process.run()
		}

		/**
		Builds the site, and reloads the open pages as soon as the files are written. Errors are printed and shown on the pages instead of thrown, so a mistake in the content does not stop the server.
		*/
		private func build(server: PreviewServer) async {
			do {
				let report = try await options.build(includesGallery: true) {
					server.reload()
				}

				server.show(error: report.brokenLinksText)
			} catch {
				print("Error: \(error)")
				server.show(error: "\(error)")
			}
		}
	}
}

/**
Rebuilds this tool after a source change, and replaces the running process with the new executable.
*/
private enum ToolRestarter {
	/**
	Whether the running executable is a release build. The folder is `release` with the native build system, and `Release` with Swift Build.
	*/
	private static var isRelease: Bool {
		Bundle.main.executableURL?.deletingLastPathComponent().lastPathComponent.lowercased() == "release"
	}

	/**
	Builds this tool with `swift build`, in the configuration of the running executable (debug or release). Returns whether it succeeded.

	It uses the native build system, which rebuilds the tool in about 1 second instead of 3 to 4 seconds. It is deprecated, so remove `--build-system native` when SwiftPM removes it, or when Swift Build is as fast. The native build system has its own build folder, so the first rebuild after a `swift build` compiles all the changes again, and it points `.build/debug` to its folder.
	*/
	static func build(project: Project) async -> Bool {
		let process = Process()
		process.executableURL = URL(filePath: "/usr/bin/env")
		process.arguments = ["swift", "build", "--build-system", "native", "--package-path", project.root.path(percentEncoded: false)] + (isRelease ? ["--configuration", "release"] : [])

		do {
			return try await process.runUntilExit() == 0
		} catch is CancellationError {
			// The watcher stopped, so the result is not needed.
			return false
		} catch {
			print("Error: Could not run `swift build`: \(error)")
			return false
		}
	}

	/**
	Replaces the process with the rebuilt executable, with the same arguments and the port the server used, so the open pages find the new server.
	*/
	static func restart(project: Project, port: UInt16) throws -> Never {
		// Through the `.build/debug` link, which points to the folder of the build system that built last, not the folder of the running executable.
		let executable = project.root.appending(path: ".build/\(isRelease ? "release" : "debug")/website").path(percentEncoded: false)

		// A later option wins, so the port the system chose for `--port 0` is kept. A restarted tool already has it.
		let arguments = CommandLine.arguments.contains("--restarted") ? CommandLine.arguments : CommandLine.arguments + ["--restarted", "--port", String(port)]
		var argumentPointers = arguments.map { strdup($0) } + [nil]
		fflush(stdout)

		// The new process keeps the signal mask of this thread, and concurrency threads block signals, which would make Control-C stop working.
		var signals = sigset_t()
		sigemptyset(&signals)
		pthread_sigmask(SIG_SETMASK, &signals, nil)

		execv(executable, &argumentPointers)

		// `execv` only returns when it fails.
		throw Errno(rawValue: errno)
	}
}
