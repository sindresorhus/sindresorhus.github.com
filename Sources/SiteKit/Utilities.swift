import Foundation

extension URL {
	/**
	Whether a file or directory exists at the URL.
	*/
	public var exists: Bool {
		FileManager.default.fileExists(atPath: path(percentEncoded: false))
	}

	/**
	Whether the URL is an existing directory. Symbolic links are followed.
	*/
	public var isDirectory: Bool {
		var isDirectory: ObjCBool = false
		return FileManager.default.fileExists(atPath: path(percentEncoded: false), isDirectory: &isDirectory) && isDirectory.boolValue
	}

	/**
	Whether the URL is an existing file that is not a directory. Symbolic links are followed.
	*/
	public var isFile: Bool {
		var isDirectory: ObjCBool = false
		return FileManager.default.fileExists(atPath: path(percentEncoded: false), isDirectory: &isDirectory) && !isDirectory.boolValue
	}

	/**
	The files directly in the directory, without the files in subdirectories. Empty when the directory does not exist.
	*/
	public var files: [URL] {
		((try? FileManager.default.contentsOfDirectory(at: self, includingPropertiesForKeys: nil)) ?? []).filter(\.isFile)
	}

	/**
	The files in the directory and its subdirectories, sorted by path so the order does not depend on the file system.

	Throws if the directory does not exist, so a wrong path is an error instead of an empty list.
	*/
	public func filesRecursively() throws -> [URL] {
		guard isDirectory else {
			throw CocoaError(.fileReadNoSuchFile, userInfo: [NSFilePathErrorKey: path(percentEncoded: false), NSLocalizedDescriptionKey: "The directory “\(path(percentEncoded: false))” does not exist."])
		}

		return (FileManager.default.enumerator(at: self, includingPropertiesForKeys: nil)?.compactMap { $0 as? URL } ?? [])
			.filter(\.isFile)
			.sorted(using: KeyPathComparator(\.path))
	}

	/**
	Creates the directory and any missing parent directories.
	*/
	public func createDirectory() throws {
		try FileManager.default.createDirectory(at: self, withIntermediateDirectories: true)
	}

	/**
	Deletes the file or directory, if it exists.
	*/
	public func removeIfExists() throws {
		guard exists else {
			return
		}

		try FileManager.default.removeItem(at: self)
	}

	/**
	The path relative to the directory, like `apps/dato.html`. Symbolic links are resolved first, so `/tmp` and `/private/tmp` match. A file outside the directory gives its file name.
	*/
	public func path(relativeTo directory: URL) -> String {
		let path = resolvingSymlinksInPath().path(percentEncoded: false)
		var directoryPath = directory.resolvingSymlinksInPath().path(percentEncoded: false)

		if !directoryPath.hasSuffix("/") {
			directoryPath += "/"
		}

		guard path.hasPrefix(directoryPath) else {
			return lastPathComponent
		}

		return String(path.dropFirst(directoryPath.count))
	}

	/**
	The file that a static host like GitHub Pages serves for a URL path, with this URL as the site directory: the exact file, `<path>.html`, or `<path>/index.html`. A path that ends with `/` only serves `<path>/index.html`.

	The path is percent-decoded. Returns `nil` when there is no such file or when the path leaves the directory.

	```swift
	output.servedFile(forPath: "/apps") // …/dist/apps.html
	```
	*/
	public func servedFile(forPath urlPath: String) -> URL? {
		let urlPath = urlPath.removingPercentEncoding ?? urlPath
		let relative = String(urlPath.drop { $0 == "/" })
		let base = appending(path: relative)

		let candidates = relative.isEmpty || relative.hasSuffix("/")
			? [base.appending(path: "index.html")]
			: [base, base.deletingLastPathComponent().appending(path: "\(base.lastPathComponent).html"), base.appending(path: "index.html")]

		let directoryComponents = standardizedFileURL.pathComponents

		return candidates.lazy
			.map(\.standardizedFileURL)
			.first { $0.pathComponents.starts(with: directoryComponents) && $0.isFile }
	}
}

extension Date {
	/**
	The day in UTC, like `2026-10-05`, for machines, like a sitemap or a `datetime` attribute.
	*/
	public var isoDay: String {
		formatted(.iso8601.year().month().day())
	}
}
