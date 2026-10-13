import Foundation

/**
The source directory of a site: content, data, and the public assets that are copied as-is.
*/
public struct Project: Sendable {
	public let root: URL

	/**
	The path of the pages of each content directory, keyed by the path of the directory relative to the root, like `/` for `content/apps`, so the files of a page bundle are published next to its page, like `/dato/icon.png` for `content/apps/dato/icon.png`. The files of the other content directories are published at their path relative to the content directory. The directories must not be inside each other.
	*/
	public let pageRoutes: [String: RoutePath]

	public init(root: URL, pageRoutes: [String: RoutePath] = [:]) {
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
	The content files. A page is a Markdown file, or a directory with an `index.md` (a page bundle). The other files in that directory, like images, are published unchanged next to the page (``pageRoutes``).

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
	The files that are published unchanged, as their path relative to the output directory and their source: the files in the public directory, and the files of the page bundles in the content directory. `.DS_Store` files are left out.
	*/
	public func publicFiles() throws -> [(path: String, source: URL)] {
		let bundleFiles = contentDirectory.isDirectory ? try contentDirectory.filesRecursively().compactMap { file in publicPath(ofContentFile: file).map { (path: $0.relativePath, source: file) } } : []

		return (try publicDirectory.filesRecursively().map { (path: $0.path(relativeTo: publicDirectory), source: $0) } + bundleFiles)
			.filter { $0.source.lastPathComponent != ".DS_Store" }
	}

	/**
	The script files of the elements (``ElementScript``): every `.js` file in a `Scripts` folder in the `Sources` directory, with the path that the build publishes it at, like `/scripts/elements/Clock.js` for `Sources/Website/Scripts/Clock.js`. Empty without a `Sources` directory.

	The file name is the path, so two scripts with the same name would be published to the same file, which the publisher refuses.
	*/
	public func elementScripts() -> [(path: RoutePath, source: URL)] {
		root.appending(path: "Sources").contentsRecursively(includesHiddenFiles: false)
			.filter {
				$0.pathExtension == "js"
					&& $0.deletingLastPathComponent().lastPathComponent == "Scripts"
			}
			.sorted(using: KeyPathComparator(\.path, comparator: String.StandardComparator.lexical))
			.map { (path: ElementScript.directory.appending($0.lastPathComponent), source: $0) }
	}

	/**
	The date of the last commit that changed each Markdown file, keyed by the path relative to the project root, like `content/apps/dato/index.md`. Load it once for all content types, as it runs `git log`.

	Moving a file without changing it does not count as a change, so the dates survive a reorganization. Empty when the project is not a git repository or git is missing. A shallow clone only knows the dates of its commits.
	*/
	public func lastCommitDates() async -> [String: Date] {
		let process = Process()
		process.executableURL = URL(filePath: "/usr/bin/env")
		// Without `core.quotePath=false`, git quotes paths with non-ASCII characters, so they would not match the files.
		process.arguments = ["git", "-C", root.path(percentEncoded: false), "-c", "core.quotePath=false", "log", "--find-renames", "--name-status", "--format=%x00%cI", "--relative", "--", "*.md"]
		process.standardError = FileHandle.nullDevice
		let pipe = Pipe()
		process.standardOutput = pipe

		// The output is read asynchronously, so waiting for git does not block a thread of the concurrency pool.
		var dates = [String: Date]()
		var date: Date?

		// The name that an older path has today, after the renames seen so far.
		var currentNames = [String: String]()

		let exitStatus = try? await process.runUntilExit {
			// Commits are newest first, so the first change of a file is its latest.
			for try await line in pipe.fileHandleForReading.bytes.lines {
				if line.hasPrefix("\0") {
					date = try? Date(String(line.dropFirst()), strategy: .iso8601)
					continue
				}

				let fields = line.split(separator: "\t")

				guard
					let date,
					let status = fields.first,
					let path = fields.last.map(String.init)
				else {
					continue
				}

				let currentName = currentNames[path] ?? path

				// `R100` is a rename without changes.
				if
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

		guard exitStatus == 0 else {
			return [:]
		}

		return dates
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
