import ArgumentParser
import Foundation
import SiteKit
import System
import SystemConfiguration
import Website

@main
struct WebsiteCommand: AsyncParsableCommand {
	static let configuration = CommandConfiguration(
		commandName: "website",
		abstract: "Build sindresorhus.com.",
		subcommands: [Build.self, Check.self, Format.self, Routes.self, Serve.self],
		defaultSubcommand: Build.self
	)

	/**
	Writes the output line by line, also when it goes to a file or a pipe, where it would otherwise wait in a buffer. So the URL of the preview server and the warnings show while the command runs, like in `website serve > serve.log`.
	*/
	static func main() async {
		setvbuf(stdout, nil, _IOLBF, 0)

		// Like `main(_:)` of ArgumentParser, which would start only the first line of the content mistakes with `Error:`.
		do {
			var command = try await asyncParseAsRoot()

			if var command = command as? any AsyncParsableCommand {
				try await command.run()
			} else {
				try command.run()
			}
		} catch let errors as ContentErrors {
			FileHandle.standardError.write(Data("\(errors.errorLines)\n".utf8))
			exit(withError: ExitCode.failure)
		} catch {
			exit(withError: error)
		}
	}
}

extension ContentErrors {
	/**
	Each mistake on its own line that starts with `Error:`, like each warning starts with `Warning:`, so a search for `^Error:` finds all of them.
	*/
	fileprivate var errorLines: String {
		errors.map { "Error: \($0)" }.joined(separator: "\n")
	}
}

extension Project {
	/**
	The project in the current directory, the repository root.
	*/
	fileprivate static var current: Self {
		.site(root: .currentDirectory())
	}

	/**
	The data of a build of the project in the current directory. The builds of the process share one cache, so `website serve` reuses the decoded responses of the earlier builds while they are fresh, instead of reading and decoding them again after each edit.
	*/
	fileprivate static var externalData: ExternalData {
		.fetch(responseCache.forAnotherBuild)
	}

	private static let responseCache = ResponseCache.forBuilds(of: .current)
}

/**
The options of the commands that publish the site.
*/
struct SiteOptions: ParsableArguments {
	@Option(help: "The output directory, `dist` by default, or `.build/check` for `website check`, so a check does not change the preview of `website serve`. Files in it that the site does not publish are deleted.", transform: { URL(filePath: $0, directoryHint: .isDirectory, relativeTo: .currentDirectory()) })
	var output: URL?

	var outputDirectory: URL {
		output ?? URL(filePath: "dist", directoryHint: .isDirectory, relativeTo: .currentDirectory())
	}

	@Flag(help: "Print how long each build step takes.")
	var verbose = false

	@Flag(help: "Fail the build and the check when there is a warning, like a failed request or a spelling mistake. With paths or `--changed`, the check counts only the printed warnings.")
	var strict = false

	/**
	Publishes the site, checks the internal links, and prints the report, with the broken links.

	- Parameter includesGallery: Publishes the component gallery too, for the preview server.
	- Parameter printsWarnings: Prints the warnings of the build, like failed requests. `website check` prints them with its own.
	- Parameter onPublished: Called after the files are written, before the links are checked.
	*/
	@discardableResult
	func build(
		includesGallery: Bool = false,
		printsWarnings: Bool = true,
		onPublished: @Sendable () -> Void = {}
	) async throws -> Site.BuildReport {
		let project = Project.current
		let report = try await Site.build(
			project: project,
			output: outputDirectory,
			externalData: Project.externalData,
			includesGallery: includesGallery,
			onPublished: onPublished
		)

		if printsWarnings {
			printWarnings(report.warnings)
		}

		if verbose {
			print(report.steps)
		}

		print("Published \(report.routes.count) routes to \(outputDirectory.path(percentEncoded: false)).")

		if let brokenLinksText = report.brokenLinksText {
			print(brokenLinksText)
		}

		return report
	}
}

extension Site.BuildReport {
	/**
	Fails after output is printed when links are broken, or when strict mode counts any of the supplied warnings. Filtered checks supply only their printed warnings.
	*/
	fileprivate func checkForFailures(isStrict: Bool, warnings: [Warning]) throws(ExitCode) {
		guard
			brokenLinks.isEmpty,
			!isStrict || warnings.isEmpty
		else {
			throw .failure
		}
	}

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
	struct Format: ParsableCommand {
		static let configuration = CommandConfiguration(abstract: "Format frontmatter, with publication status first in app and blog pages.")

		func run() throws {
			let files = try Project.current.formatFrontmatter()
			print(frontmatterFormatMessage(count: files.count))
		}
	}

	struct Build: AsyncParsableCommand {
		static let configuration = CommandConfiguration(abstract: "Publish the site and check the internal links.")

		@OptionGroup
		var options: SiteOptions

		func run() async throws {
			let report = try await options.build()

			try report.checkForFailures(isStrict: options.strict, warnings: report.warnings)
		}
	}

	struct Check: AsyncParsableCommand {
		static let configuration = CommandConfiguration(abstract: "Build the site, and print possible mistakes that do not fail the build, like spelling mistakes and OS requirements that the App Store does not agree with.")

		@OptionGroup
		var options: SiteOptions

		@Argument(help: "Only print the warnings of these files and directories, like `content/apps/dato`. A warning of a page, like a skipped heading level, counts for the content file of the page. Warnings without a file, like a failed request, and warnings of a page without a content file, like `/apps`, are then left out.")
		var paths: [String] = []

		@Flag(help: "Only print the warnings of the files that git lists as changed or new, like the ones you are editing.")
		var changed = false

		/**
		A mistyped path would print “No warnings.” It is checked before the build, so it does not fail only after the whole build.

		The check publishes to its own directory, as the preview server serves `dist`, and a check deletes the files that only the preview publishes, like the gallery.
		*/
		mutating func validate() throws {
			options.output = options.output ?? URL(filePath: ".build/check", directoryHint: .isDirectory, relativeTo: .currentDirectory())

			if let missingPath = paths.first(where: { !URL(filePath: $0, relativeTo: .currentDirectory()).exists }) {
				throw ValidationError("The path \(missingPath) does not exist.")
			}
		}

		func run() async throws {
			// Before the build, so a folder without git does not fail only after the whole build.
			let shownFiles = try await shownFiles()
			let report = try await options.build(printsWarnings: false)
			// With the warnings of the build, like failed requests.
			let (allWarnings, steps) = await report.content.warnings(published: report.published, routes: report.routes)
			let warnings = shownFiles.map { files in allWarnings.filter { report.content.warning($0, isAtAnyOf: files) } } ?? allWarnings

			printWarnings(warnings)

			// After the steps of the build, which the build printed.
			if options.verbose {
				print(steps)
			}

			// The number of each kind, the most common first, so the many warnings of one kind do not hide a new one.
			let kindCounts = Dictionary(grouping: warnings, by: \.kind)
				.map { (kind: $0.key, count: $0.value.count) }
				.sorted(using: [KeyPathComparator(\.count, order: .reverse), KeyPathComparator(\.kind.description, comparator: .localizedStandard)])

			for (kind, count) in kindCounts {
				print("\(kind): \(count)")
			}

			let count = warnings.count
			let hiddenCount = allWarnings.count - count
			let summary = switch count {
			case 0:
				"No warnings."
			case 1:
				"1 warning."
			default:
				"\(count) warnings."
			}

			print(summary + (hiddenCount > 0 ? " \(hiddenCount) more not shown." : ""))

			// After the warnings, so a broken link does not hide them. Only the printed warnings count, so `--strict` works for the files being edited.
			try report.checkForFailures(isStrict: options.strict, warnings: warnings)
		}

		/**
		The files and directories whose warnings are printed, or `nil` for all the warnings.
		*/
		private func shownFiles() async throws -> [URL]? {
			guard !paths.isEmpty || changed else {
				return nil
			}

			let files = paths.map { URL(filePath: $0, relativeTo: .currentDirectory()) }
			let changedFiles = changed ? try await Project.current.changedFiles() : []
			return files + changedFiles
		}
	}

	struct Routes: AsyncParsableCommand {
		static let configuration = CommandConfiguration(abstract: "List every route of the site.")

		func run() async throws {
			let project = Project.current
			let content = try await SiteContent.load(from: project, externalData: Project.externalData)
			let routes = Site(content: content).routes()

			for route in routes.sorted(using: KeyPathComparator(\.path.description, comparator: String.StandardComparator.lexical)) {
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
			discussion: "Frontmatter is formatted before the first build and each rebuild. Changes in `content` and `public`, and of the scripts of elements in `Sources`, rebuild the site. Other changes in `Sources` rebuild this tool and restart it. Open pages reload after each rebuild, and show build errors."
		)

		@OptionGroup
		var options: SiteOptions

		@Option(name: .shortAndLong, help: "The HTTP port. 0 picks a free port.")
		var port: UInt16 = 4321

		@Flag(help: "Serve on the local network too, to test on other devices, like an iPhone. It prints the URL as a QR code. Anyone on the network can open the site while it runs.")
		var localNetwork = false

		@Flag(help: "Do not open the site in the default browser. It is not opened either when the output is not a terminal, like for a script.")
		var noOpen = false

		/**
		Set when the tool restarts itself after a source change, so it does not open the browser again.
		*/
		@Flag(help: .hidden)
		var restarted = false

		func run() async throws {
			let project = Project.current
			let sources = project.root.appending(path: "Sources")
			let server = PreviewServer(
				directory: options.outputDirectory,
				port: port,
				reloadsPages: true,
				servesLocalNetwork: localNetwork
			)

			// The watcher starts before the first build, so edits during the build are seen.
			let changes = DirectoryWatcher(directories: [project.contentDirectory, project.publicDirectory, sources]).makeAsyncIterator()

			let warnings = await build(server: server)

			let (listeningPorts, listeningPortContinuation) = AsyncStream.makeStream(of: UInt16.self)

			let outcome = try await withThrowingTaskGroup(of: ServeOutcome.self) { group in
				group.addTask {
					try await server.run { port in
						listeningPortContinuation.yield(port)
						opened(port: port)
					}

					return .stopped
				}

				group.addTask {
					await rebuildUntilSourcesChange(changes: changes, sources: sources, server: server, warnings: warnings)
				}

				// The server stops before a restart, so the new process can use the port.
				defer {
					group.cancelAll()
				}

				return try await group.next() ?? .stopped
			}

			listeningPortContinuation.finish()

			if outcome == .restart {
				// The port the system chose for `--port 0`, so the open pages find the new server.
				var ports = listeningPorts.makeAsyncIterator()
				try ToolRestarter.restart(project: project, port: await ports.next() ?? port)
			}
		}

		/**
		Watches for changes: content and public files rebuild the site, and sources rebuild the tool. The scripts of elements in the sources (``ElementScript``) only rebuild the site, as the build reads them from the sources, like the scripts in `public`. Returns `.restart` when the sources changed and the tool was rebuilt, so it can restart, and `.stopped` when the task is cancelled.

		- Parameter warnings: The warnings of the first build, so each rebuild prints only the changes (``build(server:toolError:previousWarnings:)``).
		*/
		private func rebuildUntilSourcesChange(
			changes: DirectoryWatcher.Iterator,
			sources: URL,
			server: PreviewServer,
			warnings: [Warning]
		) async -> ServeOutcome {
			var changes = changes
			var warnings = warnings

			// The tool that does not build, so a rebuild of the site keeps showing it, as the server still runs the old tool.
			var toolError: String?

			while let changed = await changes.next() {
				let changedSources = changed.filter { $0.isInside(sources) }

				if changedSources.contains(where: { $0.pathExtension != "js" }) {
					print("The sources changed. Rebuilding the tool…")

					if await ToolRestarter.build(project: .current) {
						return .restart
					}

					// The build stopped because the watcher stopped, not because of errors.
					guard !Task.isCancelled else {
						return .stopped
					}

					let failure = ToolRestarter.BuildFailure(project: .current)
					print(failure.terminalMessage)
					toolError = failure.pageMessage
					server.show(error: toolError)

					// Content that changed at the same time is still rebuilt.
					guard changed.count > changedSources.count else {
						continue
					}
				}

				print("Rebuilding the site…")
				warnings = await build(server: server, toolError: toolError, previousWarnings: warnings)
			}

			return .stopped
		}

		/**
		Prints the URL and opens it in the default browser, unless the tool restarted, `--no-open` is set, or the output is not a terminal, like for a script or an agent, which would open a tab each time. On the local network, it also prints the URL for other devices, and as a QR code the first time.
		*/
		private func opened(port: UInt16) {
			// The server only listens on IPv4 addresses, and `localhost` can resolve to IPv6 first.
			let url = "http://127.0.0.1:\(port)"
			print("Serving at \(url)")

			// By the Bonjour name of this Mac, which other devices resolve without a DNS server, and which stays the same when the IP address changes.
			let localNetworkURL = localNetwork ? ProcessInfo.processInfo.localHostName.flatMap { URL(string: "http://\($0).local:\(port)") } : nil

			if let localNetworkURL {
				print("Serving on the local network at \(localNetworkURL)")
			} else if localNetwork {
				print("Serving on the local network, but this Mac has no local hostname. Set one in System Settings › General › Sharing.")
			}

			guard !restarted else {
				return
			}

			if let localNetworkURL {
				print(QRCode(url: localNetworkURL, label: "The URL on the local network").terminalText)
			}

			guard
				!noOpen,
				FileHandle.standardOutput.isTerminal
			else {
				return
			}

			let process = Process()
			process.executableURL = URL(filePath: "/usr/bin/open")
			process.arguments = [url]
			try? process.run()
		}

		/**
		Builds the site, and reloads the open pages as soon as the files are written. Errors are printed and shown on the pages instead of thrown, so a mistake in the content does not stop the server.

		The first build prints all the warnings. A rebuild prints only the warnings that are new or gone, and a line with the time of the rebuild and the number of warnings, like “Rebuilt in 2.7 s. 1 warning, as before.”, so the warnings that an edit causes do not hide among the ones that were printed before. Limitation: the tool forgets the warnings when it restarts after a source change, so its first build prints all of them again. A warning is new when its text or its line changes, so an edit that moves the lines of a file prints its warnings again, as new and gone.

		- Parameter toolError: An error that stays on the pages, like a tool that does not build.
		- Parameter previousWarnings: The warnings of the previous build, or `nil` for the first build.
		- Returns: The warnings of the build, or the previous ones when it failed.
		*/
		private func build(server: PreviewServer, toolError: String? = nil, previousWarnings: [Warning]? = nil) async -> [Warning] {
			let buildError: String?
			var warnings = previousWarnings ?? []
			let start = ContinuousClock.now

			do {
				let formattedFiles = try Project.current.formatFrontmatter()

				if !formattedFiles.isEmpty {
					print(frontmatterFormatMessage(count: formattedFiles.count))
				}

				let report = try await options.build(includesGallery: true, printsWarnings: previousWarnings == nil) {
					server.reload()
				}

				buildError = report.brokenLinksText
				warnings = report.warnings

				if let previousWarnings {
					printChanges(from: previousWarnings, to: warnings, duration: ContinuousClock.now - start)
				}
			} catch {
				// Like `website build` prints it (ArgumentParser): a Foundation error, like a missing directory, as its sentence, without its domain and code. Foundation errors are `NSError` objects, and the errors of the site are Swift types.
				let message = error.descriptiveMessage
				print((error as? ContentErrors)?.errorLines ?? "Error: \(message)")
				buildError = message
			}

			let errors = [toolError, buildError].compactMap(\.self)
			server.show(error: errors.isEmpty ? nil : errors.joined(separator: "\n\n"))
			return warnings
		}

		/**
		Prints the warnings of a rebuild that are new or gone, and the time of the rebuild with the number of warnings, like “Rebuilt in 2.7 s. 3 warnings: 1 new, 1 gone.”
		*/
		private func printChanges(from previousWarnings: [Warning], to warnings: [Warning], duration: Duration) {
			let previous = Set(previousWarnings)
			let current = Set(warnings)
			let newWarnings = warnings.filter { !previous.contains($0) }
			let goneWarnings = previousWarnings.filter { !current.contains($0) }

			printWarnings(newWarnings)

			for warning in goneWarnings {
				print("Gone: \(warning)")
			}

			let count = warnings.count == 1 ? "1 warning" : "\(warnings.count) warnings"
			let changes = [
				newWarnings.isEmpty ? nil : "\(newWarnings.count) new",
				goneWarnings.isEmpty ? nil : "\(goneWarnings.count) gone",
			].compactMap(\.self)
			let seconds = (duration / .seconds(1)).formatted(.number.precision(.fractionLength(1)))
			print("Rebuilt in \(seconds) s. \(count)\(changes.isEmpty ? ", as before" : ": " + changes.joined(separator: ", ")).")
		}
	}
}

/**
Whether the preview stopped or needs to restart with a rebuilt tool.
*/
private enum ServeOutcome {
	case restart
	case stopped
}

extension ProcessInfo {
	/**
	The Bonjour name of this Mac, like `Sindres-MacBook-Pro`, which other devices find as `Sindres-MacBook-Pro.local`.
	*/
	fileprivate var localHostName: String? {
		SCDynamicStoreCopyLocalHostName(nil) as String?
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
	The build folder of the running executable, like `.build`, or the folder of `swift build --scratch-path`, so a rebuild reuses the build of the running tool instead of building everything again in `.build`. It is the first folder above the executable with the `workspace-state.json` of SwiftPM.
	*/
	private static func buildDirectory(project: Project) -> URL {
		let defaultDirectory = project.root.appending(path: ".build")

		guard let executableDirectory = Bundle.main.executableURL?.resolvingSymlinksInPath().deletingLastPathComponent() else {
			return defaultDirectory
		}

		let ancestors = sequence(first: executableDirectory) { directory in
			directory.pathComponents.count > 1 ? directory.deletingLastPathComponent() : nil
		}

		return ancestors.first { $0.appending(path: "workspace-state.json").exists } ?? defaultDirectory
	}

	/**
	Builds this tool with `swift build`, in the configuration of the running executable (debug or release), in its build folder. Returns whether it succeeded.

	It uses the native build system, which rebuilds the tool in about 1 second instead of 3 to 4 seconds. It is deprecated, so remove `--build-system native` when SwiftPM removes it, or when Swift Build is as fast. The native build system has its own build folder, so the first rebuild after a `swift build` compiles all the changes again, and it points the `debug` link of the build folder to its folder.
	*/
	static func build(project: Project) async -> Bool {
		let process = Process()
		process.executableURL = URL(filePath: "/usr/bin/env")
		process.arguments = [
			"swift",
			"build",
			"--build-system",
			"native",
			"--package-path",
			project.root.path(percentEncoded: false),
			"--scratch-path",
			buildDirectory(project: project).path(percentEncoded: false)
		] + (isRelease ? ["--configuration", "release"] : [])

		do {
			return try await process.runUntilExit() == .exit(0)
		} catch is CancellationError {
			// The watcher stopped, so the result is not needed.
			return false
		} catch {
			print("Error: Could not run `swift build`: \(error)")
			return false
		}
	}

	/**
	Why the tool did not build: errors in the code, or maybe a full disk, like when several builds share the disk, as then the linker cannot write the tool (“No space left on device”), and the code has no errors to fix.

	Limitation: the output of `swift build` goes to the terminal as it is, with its colors, so the tool does not read it, and a disk with little space left is only a likely cause, next to the errors.
	*/
	enum BuildFailure {
		case errors
		case lowDiskSpace

		/**
		Low disk space when the volume of the project has less than 1 GB free after the build failed, as a build of the tool writes much more.
		*/
		init(project: Project) {
			guard
				let freeBytes = (try? project.root.resourceValues(forKeys: [.volumeAvailableCapacityKey]))?.volumeAvailableCapacity,
				freeBytes < 1_000_000_000
			else {
				self = .errors
				return
			}

			self = .lowDiskSpace
		}

		var terminalMessage: String {
			switch self {
			case .errors:
				"Fix the errors to continue."
			case .lowDiskSpace:
				"Fix the errors to continue. The disk has less than 1 GB free, so the build may have failed because the disk is full, like with “No space left on device”. Then free some space, and save a file in `Sources` to build again."
			}
		}

		/**
		The message on the open pages.
		*/
		var pageMessage: String {
			switch self {
			case .errors:
				"The tool does not build. The errors are in the terminal."
			case .lowDiskSpace:
				"The tool does not build. The disk has less than 1 GB free, so it may be full. The errors are in the terminal."
			}
		}
	}

	/**
	Replaces the process with the rebuilt executable, with the same arguments and the port the server used, so the open pages find the new server.
	*/
	static func restart(project: Project, port: UInt16) throws -> Never {
		// Through the `debug` link of the build folder, which points to the folder of the build system that built last, not the folder of the running executable.
		let executable = buildDirectory(project: project).appending(path: "\(isRelease ? "release" : "debug")/website").path(percentEncoded: false)

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

extension FileHandle {
	/**
	Whether the handle is a terminal, not a file or a pipe.
	*/
	fileprivate var isTerminal: Bool {
		isatty(fileDescriptor) == 1
	}
}

/**
The shared status sentence for frontmatter formatting; callers decide whether to show a zero count.
*/
private func frontmatterFormatMessage(count: Int) -> String {
	"Formatted frontmatter in \(count) \(count == 1 ? "file" : "files")."
}

/**
Prints current warnings with the same prefix in builds, checks, and rebuilds.
*/
private func printWarnings(_ warnings: [Warning]) {
	for warning in warnings {
		print("Warning: \(warning)")
	}
}
