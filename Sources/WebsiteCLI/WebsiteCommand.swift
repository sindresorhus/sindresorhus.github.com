import ArgumentParser
import Foundation
import SiteKit
import Subprocess
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
	Each mistake on its own line that starts with `Error:`, like each warning starts with `Warning:`, so a search for `^Error:` finds all of them. On GitHub Actions, each is an annotation (``GitHubAnnotation``).
	*/
	fileprivate var errorLines: String {
		errors
			.map { error in
				GitHubAnnotation(.error, at: error.location, error.reason)?.description ?? "Error: \(error)"
			}
			.joined(separator: "\n")
	}
}

/**
A warning or an error as a workflow command of GitHub Actions, like `::warning file=content/apps/dato/index.md,line=12::Unknown word: “shorcut”.`, which GitHub shows as an annotation at its file and line, on the page of the run and on the commit, as nobody reads the log of a run that passed, like a nightly run with new App Store data. The log shows it like the other lines. The annotations do not fail the run.

Limitation: GitHub shows at most 10 annotations of each kind for each step, but the log has all of them. So the warnings with the rarest kinds are printed first (``Swift/Array/inAnnotationOrder``), and `website check` ends with a notice when it has more.

Annotation inputs must use LF line endings. CRLF is rejected.
*/
struct GitHubAnnotation: CustomStringConvertible {
	enum Kind: String {
		case warning
		case error
		case notice
	}

	/**
	Whether the tool runs on GitHub Actions (`GITHUB_ACTIONS`), which shows the annotations.
	*/
	static var isEnabled: Bool {
		ProcessInfo.processInfo.environment["GITHUB_ACTIONS"] == "true"
	}

	let kind: Kind
	let location: SourceLocation?
	let message: String

	/**
	`nil` when the tool does not run on GitHub Actions (`GITHUB_ACTIONS`), so the line is printed as usual.
	*/
	init?(_ kind: Kind, at location: SourceLocation?, _ message: String) {
		guard Self.isEnabled else {
			return nil
		}

		self.kind = kind
		self.location = location
		self.message = message
	}

	var description: String {
		// A page has no file, so it is in the message, like in the other lines.
		switch location {
		case .file(let url, let line):
			let properties = ["file=\(Self.escapedProperty(SourceLocation.file(url).description))"] + (line.map { ["line=\($0)"] } ?? [])
			return "::\(kind.rawValue) \(properties.joined(separator: ","))::\(Self.escapedData(message))"
		case .page(let path):
			return "::\(kind.rawValue)::\(Self.escapedData("\(path): \(message)"))"
		case nil:
			return "::\(kind.rawValue)::\(Self.escapedData(message))"
		}
	}

	/**
	The message with the characters that end a workflow command escaped, like a line break, as GitHub decodes them.
	*/
	private static func escapedData(_ text: String) -> String {
		// Annotation data and property values must not contain CRLF.
		precondition(!text.contains("\r\n"), "CRLF line endings are not supported in GitHub annotation inputs. Use LF line endings.")

		return text
			.replacing("%", with: "%25")
			.replacing("\r", with: "%0D")
			.replacing("\n", with: "%0A")
	}

	/**
	A value of a property, like the file, which also escapes the characters that separate the properties.
	*/
	private static func escapedProperty(_ text: String) -> String {
		escapedData(text)
			.replacing(":", with: "%3A")
			.replacing(",", with: "%2C")
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

extension String {
	/**
	The path without the line at its end, like `content/apps/dato/index.md` for `content/apps/dato/index.md:12` or `content/apps/dato/index.md:12:`, the location that a warning or an error starts with, so it can be copied from the output.
	*/
	fileprivate var removingLineNumber: String {
		replacing(/:\d+:?$/, with: "")
	}

	/**
	Whether an argument of `website check` is a path of the site, like `/dato`, the form that the warnings of pages and the address bar of the preview show, not a path of a file: it starts with `/`, and no file has the path. The root is the home page, not the disk. So a mistyped absolute path of a file is taken as a path of the site.
	*/
	fileprivate var isSitePath: Bool {
		self == "/" || (hasPrefix("/") && !URL(filePath: self).exists)
	}
}

extension URL {
	/**
	A directory that the command line names, relative to the current directory, like `dist`.
	*/
	fileprivate static func directory(_ path: String) -> Self {
		URL(filePath: path, directoryHint: .isDirectory, relativeTo: .currentDirectory())
	}
}

/**
The output directory of `website build` and `website serve`. `website check` has its own, so a check does not change the preview.
*/
struct OutputOption: ParsableArguments {
	@Option(help: "The output directory, `dist` by default. Files in it that the site does not publish are deleted.", transform: URL.directory)
	var output: URL?

	var directory: URL {
		output ?? .directory("dist")
	}
}

/**
The options of the commands that publish the site.
*/
struct SiteOptions: ParsableArguments {
	@Flag(help: "Print how long each build step takes.")
	var verbose = false

	/**
	The start of the day in UTC. Without it, the site is built for now.

	Limitation: only what reads the day of the build changes, like what a `@Scheduled` block shows and the apps of the day. The data from other services, like the prices of the App Store, is of today, and the check that a `publicationDate` is not in the future compares with the real day.
	*/
	@Option(help: "Build the site as on this day (UTC), like `2026-11-27`, to see what a `@Scheduled` block shows. The data from other services, like the App Store, is of today.", transform: Self.day)
	var date: Date?

	/**
	The day of a `--date` value, like `2026-11-27`. A day that does not exist, like `2026-11-31`, or text after the day is an error, as the parser would silently accept them.
	*/
	private static func day(_ text: String) throws -> Date {
		let style = Date.ISO8601FormatStyle().year().month().day()

		guard
			let date = try? Date(text, strategy: style),
			date.formatted(style) == text
		else {
			throw ValidationError("`\(text)` is not a day, like `2026-11-27`.")
		}

		return date
	}

	/**
	Publishes the site, checks the internal links, and prints the report, with the broken links.

	- Parameter output: The output directory.
	- Parameter isPreview: Publishes the component gallery and the drafts too, for the preview server.
	- Parameter printsWarnings: Prints the warnings of the build, like failed requests. `website check` prints them with its own.
	- Parameter onPublished: Called after the files are written, before the links are checked.
	*/
	@discardableResult
	func build(
		output: URL,
		isPreview: Bool,
		printsWarnings: Bool = true,
		onPublished: @Sendable () -> Void = {}
	) async throws -> Site.BuildReport {
		let project = Project.current
		let report = try await Site.build(
			project: project,
			output: output,
			externalData: Project.externalData,
			buildDate: date ?? .now,
			isPreview: isPreview,
			onPublished: onPublished
		)

		if printsWarnings {
			printWarnings(report.warnings)
		}

		if verbose {
			print(report.steps)
		}

		print("Published \(report.routes.count) routes to \(output.path(percentEncoded: false)).")

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
	The broken links as a list, or `nil` when every link works. On GitHub Actions, each is an error annotation at its file and line (``GitHubAnnotation``), as a broken link fails the build.
	*/
	fileprivate var brokenLinksText: String? {
		guard !brokenLinks.isEmpty else {
			return nil
		}

		let lines = brokenLinks.map { brokenLink in
			GitHubAnnotation(.error, at: brokenLink.location, brokenLink.message)?.description ?? "- \(brokenLink)"
		}

		return (["Broken internal links:"] + lines).joined(separator: "\n")
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
		var output: OutputOption

		@OptionGroup
		var options: SiteOptions

		@Flag(help: "Fail the build when there is a warning, like a failed request.")
		var strict = false

		func run() async throws {
			let report = try await options.build(output: output.directory, isPreview: false)

			try report.checkForFailures(isStrict: strict, warnings: report.warnings)
		}
	}

	struct Check: AsyncParsableCommand {
		static let configuration = CommandConfiguration(abstract: "Build the site, and print possible mistakes that do not fail the build, like spelling mistakes and OS requirements that the App Store does not agree with.")

		@Option(help: "The output directory, `.build/check` by default, so a check does not change the preview of `website serve`. Files in it that the site does not publish are deleted.", transform: URL.directory)
		var output: URL?

		private var outputDirectory: URL {
			output ?? .directory(".build/check")
		}

		@OptionGroup
		var options: SiteOptions

		@Flag(help: "Fail the check when there is a warning, like a failed request or a spelling mistake. With paths or `--changed`, it counts only the printed warnings.")
		var strict = false

		@Argument(help: "Only print the warnings of these files and directories, like `content/apps/dato`, or of the content file of a page of the site, like `/dato`. A warning of a page, like a skipped heading level, counts for the content file of the page. Warnings without a file, like a failed request, and warnings of a page without a content file, like `/apps`, are then left out. A line after a path is ignored, like in `content/apps/dato/index.md:12`, the location that a warning starts with.", transform: \.removingLineNumber)
		var paths: [String] = []

		@Flag(help: "Only print the warnings of the files that git lists as changed or new, like the ones you are editing.")
		var changed = false

		/**
		A mistyped path would print “No warnings.” It is checked before the build, so it does not fail only after the whole build. A path of the site, like `/dato`, is checked after the build (``contentFiles(ofSitePathsIn:)``), as only the content knows its file.

		The check publishes to its own directory (``outputDirectory``), as the preview server serves `dist`, and a check deletes the files that only the preview publishes, like the gallery.
		*/
		func validate() throws {
			if let missingPath = paths.first(where: { !$0.isSitePath && !URL(filePath: $0, relativeTo: .currentDirectory()).exists }) {
				throw ValidationError("The path \(missingPath) does not exist.")
			}
		}

		func run() async throws {
			// Before the build, so a folder without git does not fail only after the whole build.
			let shownFilesOfArguments = try await shownFiles()

			// A check loads no drafts, so it would print “No warnings.” for a draft, also for a changed one. Only the preview has them.
			let draftFiles = (shownFilesOfArguments ?? []).filter { url in
				(try? MarkdownFile(url: url.pathExtension == "md" ? url : url.appending(path: "index.md")))?.isDraft == true
			}

			for file in draftFiles {
				print("\(file.path(relativeTo: Project.current.root)) is a draft, so it is not checked. Open it in `website serve`.")
			}

			// Only drafts leave nothing to check.
			guard
				changed || paths.isEmpty || draftFiles.count < paths.count
			else {
				return
			}
			let report = try await options.build(output: outputDirectory, isPreview: false, printsWarnings: false)
			let shownFiles = try shownFilesOfArguments.map { $0 + (try contentFiles(ofSitePathsIn: report)) }
			// With the warnings of the build, like failed requests.
			let (allWarnings, steps) = await report.content.warnings(
				published: report.published,
				routes: report.routes,
				textFiles: shownFiles,
				externalData: Project.externalData
			)
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
			let summary = count == 0 ? "No warnings." : "\(count.formatted(counting: "warning"))."

			print(summary + (hiddenCount > 0 ? " \(hiddenCount) more not shown." : ""))

			if
				count > 10,
				let notice = GitHubAnnotation(.notice, at: nil, "\(count.formatted(counting: "warning")), 10 shown as annotations. The log has all of them.")
			{
				print(notice)
			}

			// After the warnings, so a broken link does not hide them. Only the printed warnings count, so `--strict` works for the files being edited.
			try report.checkForFailures(isStrict: strict, warnings: warnings)
		}

		/**
		The files and directories whose warnings are printed, or `nil` for all the warnings. Without the content files of the paths of the site, like `/dato`, which only the build knows (``contentFiles(ofSitePathsIn:)``).
		*/
		private func shownFiles() async throws -> [URL]? {
			guard !paths.isEmpty || changed else {
				return nil
			}

			let files = paths.filter { !$0.isSitePath }.map { URL(filePath: $0, relativeTo: .currentDirectory()) }
			let changedFiles = changed ? try await Project.current.changedFiles() : []
			return files + changedFiles
		}

		/**
		The content files of the arguments that are paths of the site, like `content/apps/dato/index.md` for `/dato`, the same map that counts a warning of a page for its content file. A path without a page, or of a page without a content file, like `/apps`, is an error, as it would print “No warnings.”
		*/
		private func contentFiles(ofSitePathsIn report: Site.BuildReport) throws -> [URL] {
			try paths.filter(\.isSitePath).map { path in
				let routePath = try RoutePath(validating: path)

				if let file = report.content.contentFile(ofPage: routePath) {
					return file
				}

				guard report.routes.contains(where: { $0.path == routePath }) else {
					throw ContentError(reason: "The site has no page at \(path), and no file has that path.")
				}

				throw ContentError(reason: "The page \(path) has no content file. Run `website check` without a path for its warnings.")
			}
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
		var output: OutputOption

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
				directory: output.directory,
				port: port,
				reloadsPages: true,
				servesLocalNetwork: localNetwork,
				projectDirectory: project.root
			)

			// Before the first build, which takes seconds and writes to the directory that another preview on the port serves. Not after a restart, as the tool had the port, and the open pages would reload from the listener of the check, and then find no server during the build.
			if !restarted {
				try await server.checkPort()
			}

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

		- Parameter warnings: The warnings of the first build, so each rebuild prints only the changes (``build(server:toolError:previousWarnings:editedFiles:)``).
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

					guard let failure = await ToolRestarter.build(project: .current) else {
						return .restart
					}

					// The build stopped because the watcher stopped, not because of errors.
					guard !Task.isCancelled else {
						return .stopped
					}

					print(failure.terminalMessage)
					toolError = failure.pageMessage
					server.show(error: toolError)

					// Content that changed at the same time is still rebuilt.
					guard changed.count > changedSources.count else {
						continue
					}
				}

				print("Rebuilding the site…")
				warnings = await build(
					server: server,
					toolError: toolError,
					previousWarnings: warnings,
					editedFiles: Array(changed)
				)
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

			Task {
				_ = try? await Subprocess.run(.name("open"), arguments: [url], output: .discarded)
			}
		}

		/**
		Builds the site, and reloads the open pages as soon as the files are written. Errors are printed and shown on the pages instead of thrown, so a mistake in the content does not stop the server.

		The first build prints all the warnings. A rebuild prints only the warnings that are new or gone, the warnings of `website check` at the edited content files, and then a line with the time of the rebuild and the number of warnings, like “Rebuilt in 2s 712ms. 1 warning, as before. 2 check warnings in the edited file.”, so the warnings that an edit causes do not hide among the ones that were printed before. Limitation: the tool forgets the warnings when it restarts after a source change, so its first build prints all of them again. A warning is new when its text or its line changes, so an edit that moves the lines of a file prints its warnings again, as new and gone.

		- Parameter toolError: An error that stays on the pages, like a tool that does not build.
		- Parameter previousWarnings: The warnings of the previous build, or `nil` for the first build.
		- Parameter editedFiles: The files that changed since the previous build, whose warnings of `website check` a rebuild prints (``printCheckWarnings(of:editedFiles:)``).
		- Returns: The warnings of the build, or the previous ones when it failed.
		*/
		private func build(
			server: PreviewServer,
			toolError: String? = nil,
			previousWarnings: [Warning]? = nil,
			editedFiles: [URL] = []
		) async -> [Warning] {
			let buildError: String?
			var warnings = previousWarnings ?? []
			let start = ContinuousClock.now

			do {
				let formattedFiles = try Project.current.formatFrontmatter()

				if !formattedFiles.isEmpty {
					print(frontmatterFormatMessage(count: formattedFiles.count))

					// The watcher reports the formatted files, so the next rebuild builds them, and a build now would build the site twice. The first build is the exception, as no rebuild follows it. Limitation: the next rebuild prints the check warnings only of the formatted files, not of other files of the same change.
					if let previousWarnings {
						return previousWarnings
					}
				}

				let report = try await options.build(output: output.directory, isPreview: true, printsWarnings: previousWarnings == nil) {
					server.reload()
				}

				buildError = report.brokenLinksText
				warnings = report.warnings

				if let previousWarnings {
					let duration = ContinuousClock.now - start
					let changes = printChanges(from: previousWarnings, to: warnings)
					let checkSummary = await printCheckWarnings(of: report, editedFiles: editedFiles)
					print("Rebuilt in \(duration.formatted(.site)). \(changes)\(checkSummary.map { " \($0)" } ?? "")")
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
		Prints the warnings of a rebuild that are new or gone, and returns the number of warnings, like “3 warnings: 1 new, 1 gone.”
		*/
		private func printChanges(from previousWarnings: [Warning], to warnings: [Warning]) -> String {
			let previous = Set(previousWarnings)
			let current = Set(warnings)
			let newWarnings = warnings.filter { !previous.contains($0) }
			let goneWarnings = previousWarnings.filter { !current.contains($0) }

			printWarnings(newWarnings)

			for warning in goneWarnings {
				print("Gone: \(warning)")
			}

			let count = warnings.count.formatted(counting: "warning")
			let changes = [
				newWarnings.isEmpty ? nil : "\(newWarnings.count) new",
				goneWarnings.isEmpty ? nil : "\(goneWarnings.count) gone",
			].compactMap(\.self)
			return "\(count)\(changes.isEmpty ? ", as before" : ": " + changes.joined(separator: ", "))."
		}

		/**
		Prints the warnings of `website check` at the edited content files that the build does not have, like a promise in an FAQ answer or a spelling mistake, so the writer sees them while writing, not only at the next check. The checks of the text and of the published pages only read the edited files (``SiteContent/warnings(published:routes:textFiles:)``). It runs after the pages reloaded, and each rebuild prints them again while the file has them, like `Check: content/apps/dato/index.md:12: …`, in the order of their lines, and each one once.

		- Returns: The number of the warnings, like “2 check warnings in the edited file.”, or `nil` when no content file was edited.
		*/
		private func printCheckWarnings(of report: Site.BuildReport, editedFiles: [URL]) async -> String? {
			let contentFiles = editedFiles.filter { $0.isInside(Project.current.contentDirectory) }

			guard !contentFiles.isEmpty else {
				return nil
			}

			let buildWarnings = Set(report.warnings)
			let checkWarnings = await report.content.warnings(published: report.published, routes: report.routes, textFiles: contentFiles).warnings

			// A check can find the same mistake twice, like a word three times in a row.
			var seenWarnings = buildWarnings
			let newWarnings = checkWarnings.filter { report.content.warning($0, isAtAnyOf: contentFiles) && seenWarnings.insert($0).inserted }

			for warning in newWarnings.inPrintOrder {
				print("Check: \(warning)")
			}

			return "\(newWarnings.count.formatted(counting: "check warning")) in the edited \("file".pluralized(for: contentFiles.count))."
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
	Builds this tool with `swift build`, in the configuration of the running executable (debug or release), in its build folder. Returns `nil` when it succeeded, or else why it failed, with the output of the build.

	The output is read, not sent to the terminal, as the build prints one error once for each file that it compiles together with the file of the error, so hundreds of times (``BuildFailure/errors``). So the build shows no progress.

	It uses the native build system, which rebuilds the tool in about 1 second instead of 3 to 4 seconds. It is deprecated, so remove `--build-system native` when SwiftPM removes it, or when Swift Build is as fast. The native build system has its own build folder, so the first rebuild after a `swift build` compiles all the changes again, and it points the `debug` link of the build folder to its folder.
	*/
	static func build(project: Project) async -> BuildFailure? {
		let arguments = [
			"build",
			"--build-system",
			"native",
			"--package-path",
			project.root.path(percentEncoded: false),
			"--scratch-path",
			buildDirectory(project: project).path(percentEncoded: false)
		] + (isRelease ? ["--configuration", "release"] : [])

		// When the task is cancelled, like when the watcher stops, the build is stopped too.
		do {
			let result = try await Subprocess.run(
				.name("swift"),
				arguments: Arguments(arguments),
				output: .string(limit: 64_000_000),
				error: .string(limit: 64_000_000)
			)

			guard !result.terminationStatus.isSuccess else {
				return nil
			}

			return BuildFailure(output: [result.standardOutput, result.standardError].compactMap(\.self).joined(separator: "\n"), project: project)
		} catch is CancellationError {
			// The watcher stopped, so the result is not needed.
			return BuildFailure(output: "", project: project)
		} catch {
			return BuildFailure(output: "Error: Could not run `swift build`: \(error)", project: project)
		}
	}

	/**
	Why the tool did not build: errors in the code, or maybe a full disk, like when several builds share the disk, as then the linker cannot write the tool (“No space left on device”), and the code has no errors to fix.

	A disk with little space left is only a likely cause, next to the errors, as the output is only read for the errors of the compiler.
	*/
	struct BuildFailure {
		/**
		What `swift build` printed.
		*/
		let output: String

		/**
		Whether the volume of the project has less than 1 GB free after the build failed, as a build of the tool writes much more.
		*/
		let isDiskLow: Bool

		/**
		The root of the project, which the locations of the errors are relative to.
		*/
		private let root: URL

		init(output: String, project: Project) {
			self.output = output
			self.root = project.root
			self.isDiskLow = (try? project.root.resourceValues(forKeys: [.volumeAvailableCapacityKey]))?.volumeAvailableCapacity.map { $0 < 1_000_000_000 } ?? false
		}

		/**
		The first line of an error of the compiler, like `/Users/…/Sources/Website/Site.swift:12:3: error: expected '}'`.
		*/
		nonisolated(unsafe) private static let errorLine = #/^.+:\d+:\d+: error: /#

		/**
		A line of the source excerpt below an error, like `12 | let x =` or `   |         `- error: …`.
		*/
		nonisolated(unsafe) private static let excerptLine = /^\s*\d*\s*\|/

		/**
		The distinct errors of the compiler in the output, each with its source excerpt, and with its file relative to the project, like `Sources/Website/Site.swift:12:3: error: expected '}'`, so one mistake is one error, not one for each file that the build compiled with it.
		*/
		var errors: [String] {
			var errors = [[Substring]]()
			var isInError = false

			for line in output.split(separator: "\n", omittingEmptySubsequences: false) {
				if line.contains(Self.errorLine) {
					errors.append([line])
					isInError = true
				} else if
					isInError,
					line.contains(Self.excerptLine)
				{
					errors[errors.count - 1].append(line)
				} else {
					isInError = false
				}
			}

			let rootPath = root.path(percentEncoded: false)
			let rootPrefix = rootPath.hasSuffix("/") ? rootPath : rootPath + "/"

			return errors
				.map { $0.joined(separator: "\n").replacing(rootPrefix, with: "") }
				.uniqued(by: \.self)
		}

		/**
		The errors, or all the output when it has no error of the compiler, like for an error of the linker, so a failed build always says why.
		*/
		var terminalMessage: String {
			let errors = errors
			let details = errors.isEmpty ? output : errors.joined(separator: "\n\n")
			let diskNote = isDiskLow ? " The disk has less than 1 GB free, so the build may have failed because the disk is full, like with “No space left on device”. Then free some space, and save a file in `Sources` to build again." : ""
			return "\(details)\nFix the \("error".pluralized(for: max(errors.count, 1))) to continue.\(diskNote)"
		}

		/**
		The message on the open pages: the first error, which says its file and line, and how many more the terminal has.
		*/
		var pageMessage: String {
			let errors = errors
			let diskNote = isDiskLow ? " The disk has less than 1 GB free, so it may be full." : ""

			guard let firstError = errors.first?.split(separator: "\n").first else {
				return "The tool does not build.\(diskNote) The errors are in the terminal."
			}

			let moreErrors = errors.count > 1 ? " The terminal has \((errors.count - 1).formatted(counting: "more error"))." : ""
			return "The tool does not build.\(diskNote)\(moreErrors)\n\n\(firstError)"
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
	"Formatted frontmatter in \(count.formatted(counting: "file"))."
}

/**
Prints current warnings with the same prefix in builds, checks, and rebuilds, in the order of their files and lines (``Swift/Array/inPrintOrder``). On GitHub Actions, the rarest kinds come first (``Swift/Array/inAnnotationOrder``).
*/
private func printWarnings(_ warnings: [Warning]) {
	for warning in GitHubAnnotation.isEnabled ? warnings.inAnnotationOrder : warnings.inPrintOrder {
		print(GitHubAnnotation(.warning, at: warning.location, warning.message)?.description ?? "Warning: \(warning)")
	}
}

extension [Warning] {
	/**
	The warnings with the rarest kind first, and each kind in the order of its files and lines, as GitHub shows only the first 10 warning annotations of a step (``GitHubAnnotation``). A new kind of warning is the one that needs action, while the many warnings of a known kind, like the missing screenshots, would fill the 10.
	*/
	fileprivate var inAnnotationOrder: Self {
		Dictionary(grouping: self, by: \.kind)
			.values
			.sorted(using: [KeyPathComparator(\.count), KeyPathComparator(\.first?.kind.description)])
			.flatMap(\.inPrintOrder)
	}

	/**
	The warnings in the order of their files and lines, so the warnings of one file are together, like when working on one app. The warnings without a location, like a failed request, come last, in their order.
	*/
	fileprivate var inPrintOrder: Self {
		filter { $0.location != nil }.sorted(using: [KeyPathComparator(\.location?.path), KeyPathComparator(\.location?.line)]) + filter { $0.location == nil }
	}
}

extension SourceLocation {
	/**
	The path of the file or the page, without the line.
	*/
	fileprivate var path: String {
		switch self {
		case .file(let url, _):
			url.path(percentEncoded: false)
		case .page(let path):
			path.description
		}
	}

	fileprivate var line: SiteKit.SourceLocation.Line? {
		guard case .file(_, let line) = self else {
			return nil
		}

		return line
	}
}
