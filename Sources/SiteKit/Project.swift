import Foundation

/**
The source directory of a site: content, data, and the public assets that are copied as-is.
*/
public struct Project: Sendable {
	public let root: URL

	public init(root: URL) {
		self.root = root.standardizedFileURL
	}

	/**
	Files that are published unchanged, like images and scripts.
	*/
	public var publicDirectory: URL {
		root.appending(path: "public")
	}

	/**
	The content files. A page can be a directory with an `index.md` (a page bundle), and the other files in that directory, like images, are published unchanged at their path relative to this directory, like `/apps/dato/icon.png` for `content/apps/dato/icon.png`.

	Limitation: Only the files directly next to the `index.md` are published, not the files in its subdirectories.
	*/
	public var contentDirectory: URL {
		root.appending(path: "content")
	}

	/**
	The file or directory behind a public URL path, like `/apps/dato/icon.png`: in a page bundle in the content directory, or else in the public directory.
	*/
	public func publicFile(_ path: RoutePath) -> URL {
		let contentFile = contentDirectory.appending(path: path.relativePath)

		if
			contentFile.appending(path: "index.md").isFile
				|| contentFile.isPageBundleFile
		{
			return contentFile
		}

		return publicDirectory.appending(path: path.relativePath)
	}

	/**
	The path of a file of a page bundle in the site, like `/apps/dato/icon.png` for `content/apps/dato/icon.png`. `nil` for any other file.
	*/
	public func publicPath(ofContentFile file: URL) -> RoutePath? {
		guard
			file.isPageBundleFile,
			file.isInside(contentDirectory)
		else {
			return nil
		}

		return RoutePath("/" + file.path(relativeTo: contentDirectory))
	}

	/**
	The files that are published unchanged, as their path relative to the output directory and their source: the files in the public directory, and the files of the page bundles in the content directory. `.DS_Store` files are left out.
	*/
	public func publicFiles() throws -> [(path: String, source: URL)] {
		let bundleFiles = contentDirectory.isDirectory ? try contentDirectory.filesRecursively().filter(\.isPageBundleFile) : []

		return (try publicDirectory.filesRecursively().map { (path: $0.path(relativeTo: publicDirectory), source: $0) } + bundleFiles.map { (path: $0.path(relativeTo: contentDirectory), source: $0) })
			.filter { $0.source.lastPathComponent != ".DS_Store" }
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
		var lines = [String]()

		let exitStatus = try? await process.runUntilExit {
			for try await line in pipe.fileHandleForReading.bytes.lines {
				lines.append(line)
			}
		}

		guard exitStatus == 0 else {
			return [:]
		}

		var dates = [String: Date]()
		var date: Date?

		// The name that an older path has today, after the renames seen so far.
		var currentNames = [String: String]()

		// Commits are newest first, so the first change of a file is its latest.
		for line in lines {
			if line.hasPrefix("\0") {
				date = try? Date(String(line.dropFirst()), strategy: .iso8601)
				continue
			}

			let fields = line.split(separator: "\t").map(String.init)

			guard
				let date,
				let status = fields.first,
				let path = fields.last
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
				currentNames[fields[1]] = currentName
			}
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
