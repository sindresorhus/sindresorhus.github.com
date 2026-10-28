import Foundation

/**
The source directory of a site: content, data, and the public assets that are copied as-is.
*/
public struct Project: Sendable {
	public let root: URL

	/**
	The path of the pages of each content directory, keyed by the canonical path of the directory relative to the root, like `/` for `content/apps`, so the files of a page bundle are published next to its page, like `/dato/icon.png` for `content/apps/dato/icon.png`. The files of the page bundles in the other content directories are published at their path relative to the content directory. Either way, they are only published when the site publishes their page (``contentDirectory``). The directories must not be inside each other, and their paths must not have empty, `.`, or `..` components, or NUL characters.
	*/
	public let pageRoutes: [String: RoutePath]

	public init(root: URL, pageRoutes: [String: RoutePath] = [:]) {
		let directories = pageRoutes.keys.map { directory in
			let components = directory.split(separator: "/", omittingEmptySubsequences: false)
			precondition(!directory.contains("\0") && !components.contains { $0.isEmpty || $0 == "." || $0 == ".." }, "A page route source directory must be a canonical relative path: \(directory)")
			return components
		}

		for (index, directory) in directories.enumerated() {
			precondition(!directories.dropFirst(index + 1).contains { directory.starts(with: $0) || $0.starts(with: directory) }, "Page route source directories must not be inside each other.")
		}

		self.root = root.standardizedFileURL
		self.pageRoutes = pageRoutes
	}

	/**
	Files that are published unchanged, like images and scripts.
	*/
	public var publicDirectory: URL {
		root.appending(path: "public")
	}

	/**
	The content files. A page is a Markdown file, or a directory with an `index.md` (a page bundle). The other files in that directory, like images, are published unchanged next to the page (``pageRoutes``), but only when the site publishes the page, so a draft does not publish its files.

	Limitation: Only the files directly next to the `index.md` are published, not the files in its subdirectories.
	*/
	public var contentDirectory: URL {
		root.appending(path: "content")
	}

	/**
	The file or directory behind a public URL path, like `/dato/icon.png`: in a page bundle in the content directory, or else in the public directory.
	*/
	public func publicFile(_ path: RoutePath) -> URL {
		let candidates = pageRoutes.compactMap { directory, route in
			path.relative(to: route).map { root.appending(path: directory).appending(path: $0) }
		}
		// The files of the content directories without a page route are at their path relative to the content directory.
		let unroutedFile = contentDirectory.appending(path: path.relativePath)
		let isUnrouted = !pageRoutes.keys.contains { unroutedFile.isInside(root.appending(path: $0)) }

		let file = (candidates + (isUnrouted ? [unroutedFile] : [])).first {
			$0.appending(path: "index.md").isFile
				|| $0.isPageBundleFile
		}

		return file ?? publicDirectory.appending(path: path.relativePath)
	}

	/**
	The file behind a public URL path, like `dato/icon.png`, or `nil` when there is none. Use it to check that a file that content names exists, like an icon or a script, so a call site cannot forget to test the result of ``publicFile(_:)``.
	*/
	public func existingPublicFile(_ path: RoutePath) -> URL? {
		let file = publicFile(path)
		return file.isFile ? file : nil
	}

	/**
	The path of a file of a page bundle in the site, like `/dato/icon.png` for `content/apps/dato/icon.png`. `nil` for any other file.
	*/
	public func publicPath(ofContentFile file: URL) -> RoutePath? {
		guard
			file.isPageBundleFile,
			file.isInside(contentDirectory)
		else {
			return nil
		}

		for (directory, route) in pageRoutes {
			let directoryURL = root.appending(path: directory)

			if file.isInside(directoryURL) {
				return RoutePath("\(route)/\(file.path(relativeTo: directoryURL))")
			}
		}

		return RoutePath("/" + file.path(relativeTo: contentDirectory))
	}

	/**
	The files that are published unchanged, as their path in the site and their source: the files in the public directory, and the files of the page bundles in the content directory. `.DS_Store` files are left out.
	*/
	public func publicFiles() throws -> [PublishedAsset] {
		let bundleFiles = contentDirectory.isDirectory ? try contentDirectory.filesRecursively().compactMap { file in publicPath(ofContentFile: file).map { PublishedAsset(path: $0, source: file) } } : []

		return (try publicDirectory.filesRecursively().map { PublishedAsset(path: RoutePath("/" + $0.path(relativeTo: publicDirectory)), source: $0) } + bundleFiles)
			.filter { $0.source.lastPathComponent != ".DS_Store" }
	}

	/**
	The script files of the elements (``ElementScript``): every `.js` file in a `Scripts` folder in the `Sources` directory, with the path that the build publishes it at, like `/scripts/elements/Clock.js` for `Sources/Website/Scripts/Clock.js`. Empty without a `Sources` directory.

	The file name is the path, so two scripts with the same name would be published to the same file, which the publisher refuses.
	*/
	public func elementScripts() -> [PublishedAsset] {
		root.appending(path: "Sources").contentsRecursively(includesHiddenFiles: false)
			.filter {
				$0.pathExtension == "js"
					&& $0.deletingLastPathComponent().lastPathComponent == "Scripts"
			}
			.sorted(using: KeyPathComparator(\.path, comparator: String.StandardComparator.lexical))
			.map { PublishedAsset(path: ElementScript.publishedPath(of: $0), source: $0) }
	}

	/**
	The date of the last commit that changed each Markdown file, keyed by the path relative to the project root, like `content/apps/dato/index.md`. Load it once for all content types, as it runs `git log`.

	Moving a file without changing it does not count as a change, so the dates survive a reorganization. The commits in ``ignoredCommitsFile``, like a change of the syntax of all the files, do not count either, as search engines trust the dates only when they are the last real change of a page. Empty when the project is not a git repository or git is missing. A shallow clone only knows the dates of its commits.
	*/
	public func lastCommitDates() async -> [String: Date] {
		let ignoredCommits = ignoredCommits

		var dates = [String: Date]()
		var date: Date?

		// The name that an older path has today, after the renames seen so far.
		var currentNames = [String: String]()

		// Without `core.quotePath=false`, git quotes paths with non-ASCII characters, so they would not match the files.
		let exitStatus = try? await runGit(["-c", "core.quotePath=false", "log", "--find-renames", "--name-status", "--format=%x00%H %cI", "--relative", "--", "*.md"]) { output in
			// Commits are newest first, so the first change of a file is its latest.
			for try await line in output.bytes.lines {
				if line.hasPrefix("\0") {
					let parts = line.dropFirst().split(separator: " ")
					let isIgnored = parts.first.map { hash in ignoredCommits.contains { hash.hasPrefix($0) } } ?? false
					// An ignored commit has no date, so it changes no date, but its renames still count.
					date = isIgnored ? nil : parts.last.flatMap { try? Date(String($0), strategy: .iso8601) }
					continue
				}

				let fields = line.split(separator: "\t")

				guard
					let status = fields.first,
					let path = fields.last.map(String.init)
				else {
					continue
				}

				let currentName = currentNames[path] ?? path

				// `R100` is a rename without changes.
				if
					let date,
					status != "R100",
					dates[currentName] == nil
				{
					dates[currentName] = date
				}

				if
					status.hasPrefix("R"),
					fields.count == 3
				{
					currentNames[String(fields[1])] = currentName
				}
			}
		}

		guard exitStatus == .exit(0) else {
			return [:]
		}

		return dates
	}

	/**
	The files that git lists as changed or new, like for `website check --changed`: each file of a new directory, and both paths of a renamed file. Throws when the project is not a git repository or git is missing. Limitation: the paths are relative to the root of the repository, so the project root must be the root of the repository, like for the site.
	*/
	public func changedFiles() async throws -> [URL] {
		var output = Data()

		// `-z` separates the paths with NUL characters and does not quote them, and `-uall` lists each file of a new directory, not only the directory.
		let exitStatus = try await runGit(["status", "--porcelain", "-z", "-uall"]) { handle in
			output = try await handle.readDataToEnd()
		}

		guard exitStatus == .exit(0) else {
			throw ContentError(reason: "Could not list the changed files with git.")
		}

		// Each entry is the status, a space, and the path, like `M  content/apps/dato/index.md`. A rename or copy is followed by its old path, without a status.
		var paths = [String]()
		var entries = output.split(separator: 0).map { String(decoding: $0, as: UTF8.self) }.makeIterator()

		while let entry = entries.next() {
			paths.append(String(entry.dropFirst(3)))

			// The index or the worktree column can have the rename, like ` R` for a file that was moved without git, and whose new path was added with `--intent-to-add`.
			let status = entry.prefix(2)

			if
				status.contains("R") || status.contains("C"),
				let oldPath = entries.next()
			{
				paths.append(oldPath)
			}
		}

		return paths.map { root.appending(path: $0) }
	}

	/**
	Runs git in the project root with the arguments, like `["status"]`, and returns how it terminated. The closure reads the output while git runs, asynchronously, so waiting for git does not block a thread of the concurrency pool. The errors of git are left out. Throws when git cannot start, or when the closure throws.
	*/
	private func runGit(_ arguments: [String], readingOutput read: (FileHandle) async throws -> Void) async throws -> Process.Termination {
		let process = Process()
		process.executableURL = URL(filePath: "/usr/bin/env")
		process.arguments = ["git", "-C", root.path(percentEncoded: false)] + arguments
		process.standardError = FileHandle.nullDevice
		let pipe = Pipe()
		process.standardOutput = pipe

		return try await process.runUntilExit {
			try await read(pipe.fileHandleForReading)
		}
	}
}

/**
A file published unchanged at a site path, retaining its source alongside its destination.
*/
public struct PublishedAsset: Sendable {
	public let path: RoutePath
	public let source: URL

	/**
	A source file and the site path at which it is published.
	*/
	public init(path: RoutePath, source: URL) {
		self.path = path
		self.source = source
	}

	/**
	The destination file relative to the output directory.
	*/
	public var outputFile: PublishedFilePath {
		PublishedFilePath(path.relativePath)
	}
}

extension Project {
	/**
	The file with the commits that do not count as changes of the pages (``lastCommitDates()``), one hash or the start of one per line, like `fb119204`, with `#` comments. For a commit that changes many files without changing what they say to readers, like a change of the syntax of the frontmatter.
	*/
	public var ignoredCommitsFile: URL {
		root.appending(path: ".lastmod-ignore-revs")
	}

	/**
	The hashes in ``ignoredCommitsFile``, or none without the file.
	*/
	private var ignoredCommits: [String] {
		let text = (try? String(contentsOf: ignoredCommitsFile, encoding: .utf8)) ?? ""

		return text.split(whereSeparator: \.isNewline)
			.map { line in line.prefix { $0 != "#" }.trimmingCharacters(in: .whitespaces) }
			.filter { !$0.isEmpty }
	}
}

extension URL {
	/**
	Whether the URL is a file next to the `index.md` of a page bundle, like `content/apps/dato/icon.png`. Markdown files are content, so they are not.
	*/
	fileprivate var isPageBundleFile: Bool {
		pathExtension != "md"
			&& isFile
			&& deletingLastPathComponent().appending(path: "index.md").isFile
	}
}
