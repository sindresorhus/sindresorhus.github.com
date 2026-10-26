import AVFoundation
import CryptoKit
import Foundation
import ImageIO

extension Sequence<UInt8> {
	/**
	The bytes as lowercase hexadecimal digits, two for each byte, like `0aff` for `[10, 255]`, like for a hash.
	*/
	public var hexString: String {
		map { ($0 < 16 ? "0" : "") + String($0, radix: 16) }.joined()
	}
}

extension Error {
	/**
	The localized message of a Foundation error or `LocalizedError`, or the description of another Swift error, so diagnostics keep the details that a generic localized description would discard.
	*/
	public var descriptiveMessage: String {
		if let description = (self as? any LocalizedError)?.errorDescription {
			return description
		}

		// Boxing the error as `any Error` bridges a Foundation error struct, like `CocoaError` or `URLError`, to its `NSError`, so it is also found when it is called on the struct itself.
		return type(of: self as any Error) is NSError.Type ? localizedDescription : String(describing: self)
	}
}

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
	Whether the URL itself is a symbolic link, including a broken one.
	*/
	public var isSymbolicLink: Bool {
		(try? resourceValues(forKeys: [.isSymbolicLinkKey]))?.isSymbolicLink == true
	}

	/**
	The files directly in the directory, without the files in subdirectories. Empty when the directory does not exist.
	*/
	public var files: [URL] {
		((try? FileManager.default.contentsOfDirectory(at: self, includingPropertiesForKeys: [.isDirectoryKey, .isSymbolicLinkKey])) ?? []).filter(\.isFile)
	}

	/**
	The files in the directory and its subdirectories, sorted by path, by the characters, so the order does not depend on the file system or the language of the machine.

	Throws if the directory does not exist, so a wrong path is an error instead of an empty list.
	*/
	public func filesRecursively() throws -> [URL] {
		guard isDirectory else {
			throw CocoaError(.fileReadNoSuchFile, userInfo: [NSFilePathErrorKey: path(percentEncoded: false), NSLocalizedDescriptionKey: "The directory “\(path(percentEncoded: false))” does not exist."])
		}

		return contentsRecursively()
			.filter(\.isFile)
			.sorted(using: KeyPathComparator(\.path, comparator: String.StandardComparator.lexical))
	}

	/**
	The files and directories in the directory and its subdirectories, in no particular order. Empty when the directory does not exist.

	- Parameter includesHiddenFiles: Whether hidden files and directories, like `.DS_Store`, are included.
	*/
	public func contentsRecursively(includesHiddenFiles: Bool = true) -> [URL] {
		FileManager.default.enumerator(at: self, includingPropertiesForKeys: [.isDirectoryKey, .isSymbolicLinkKey, .fileSizeKey, .contentModificationDateKey], options: includesHiddenFiles ? [] : .skipsHiddenFiles)?.compactMap { $0 as? URL } ?? []
	}

	/**
	Whether the URL is an existing directory with nothing in it, not even hidden files.
	*/
	public var isEmptyDirectory: Bool {
		(try? FileManager.default.contentsOfDirectory(atPath: path(percentEncoded: false)))?.isEmpty == true
	}

	/**
	Copies the file or directory to the destination, which must not exist yet.
	*/
	public func copy(to destination: URL) throws {
		try FileManager.default.copyItem(at: self, to: destination)
	}

	/**
	Creates the directory and any missing parent directories.
	*/
	public func createDirectory() throws {
		try FileManager.default.createDirectory(at: self, withIntermediateDirectories: true)
	}

	/**
	Deletes the file or directory, if it exists, or the symbolic link, also when its target does not exist.
	*/
	public func removeIfExists() throws {
		guard
			exists
				|| isSymbolicLink
		else {
			return
		}

		try FileManager.default.removeItem(at: self)
	}

	/**
	Whether the URL is in the directory or its subdirectories. Symbolic links of the directories are resolved first, like in ``path(relativeTo:)``, so a symbolic link to a file is where the link is.
	*/
	public func isInside(_ directory: URL) -> Bool {
		pathWithResolvedParent.hasPrefix(directory.resolvedDirectoryPath)
	}

	/**
	The path relative to the directory, like `apps/dato.html`. Symbolic links of the directories are resolved first, so `/tmp` and `/private/tmp` match. A symbolic link to a file keeps its own name and place, as its target can be anywhere. A file outside the directory gives its file name.
	*/
	public func path(relativeTo directory: URL) -> String {
		let path = pathWithResolvedParent
		let directoryPath = directory.resolvedDirectoryPath

		guard path.hasPrefix(directoryPath) else {
			return lastPathComponent
		}

		return String(path.dropFirst(directoryPath.count))
	}

	/**
	The path with symbolic links of the directories resolved, but not of the file itself, so a symbolic link to a file keeps its own name and place.
	*/
	private var pathWithResolvedParent: String {
		deletingLastPathComponent().resolvingSymlinksInPath().appending(path: lastPathComponent).path(percentEncoded: false)
	}

	/**
	The path of the directory with symbolic links resolved and a trailing `/`, so a prefix check does not match a sibling, like `/dist` for `/dist-old`.
	*/
	private var resolvedDirectoryPath: String {
		let path = resolvingSymlinksInPath().path(percentEncoded: false)
		return path.hasSuffix("/") ? path : path + "/"
	}

	/**
	The file that a static host like GitHub Pages serves for a URL path, with this URL as the site directory, or `nil` when there is none. See ``Swift/String/servedFileCandidates``.

	```swift
	output.servedFile(forPath: "/apps") // …/dist/apps.html
	```
	*/
	public func servedFile(forPath urlPath: String) -> URL? {
		urlPath.servedFileCandidates.lazy
			.map { self.appending(path: $0) }
			.first { $0.resolvingSymlinksInPath().isInside(self) && $0.isFile }
	}
}

extension String {
	/**
	The files that a static host like GitHub Pages tries for this URL path, in order, relative to the site directory: the exact file, `<path>.html`, and `<path>/index.html`. A path that ends with `/` only tries `<path>/index.html`.

	The path is percent-decoded. Empty when the path has a `..` component, which could leave the site directory.

	```swift
	"/apps".servedFileCandidates // ["apps", "apps.html", "apps/index.html"]
	```
	*/
	public var servedFileCandidates: [String] {
		let urlPath = removingPercentEncoding ?? self
		let components = urlPath.split(separator: "/", omittingEmptySubsequences: true).filter { $0 != "." }

		guard !components.contains("..") else {
			return []
		}

		let relative = components.joined(separator: "/")

		guard
			!relative.isEmpty,
			!urlPath.hasSuffix("/")
		else {
			return [relative.isEmpty ? "index.html" : "\(relative)/index.html"]
		}

		return [relative, "\(relative).html", "\(relative)/index.html"]
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

/**
The size of an image or a video in pixels, like 1280×800.
*/
public struct PixelSize: Hashable, Sendable, CustomStringConvertible {
	public let width: Int
	public let height: Int

	public init(width: Int, height: Int) {
		self.width = width
		self.height = height
	}

	/**
	The pixel size in the properties of an image.
	*/
	fileprivate init?(imageProperties: [CFString: Any]) {
		guard
			let width = imageProperties[kCGImagePropertyPixelWidth] as? Int,
			let height = imageProperties[kCGImagePropertyPixelHeight] as? Int
		else {
			return nil
		}

		self.init(width: width, height: height)
	}

	/**
	The width divided by the height, like 1.6 for 1280×800.
	*/
	public var aspectRatio: Double {
		Double(width) / Double(height)
	}

	/**
	Like `1280×800`.
	*/
	public var description: String {
		"\(width)×\(height)"
	}
}

extension URL {
	/**
	A JPEG XL copy of a PNG or JPEG image, or `nil` when the copy is not smaller. A PNG is encoded losslessly, and a JPEG is wrapped losslessly, so the JPEG can be restored bit for bit. So the copy looks exactly like the image.

	It runs `cjxl` (`brew install jpeg-xl`), which throws when it is missing. The copy is cached in the directory by a hash of the bytes of the image and the options, so an image is only encoded again when it changes.
	*/
	public func jpegXLVersion(cacheDirectory: URL) async throws -> URL? {
		let data = try Data(contentsOf: self)
		let isJPEG = ["jpg", "jpeg"].contains(pathExtension.lowercased())
		// The options are part of the key, so a change of them encodes the images again.
		let options = isJPEG ? ["--lossless_jpeg=1"] : ["--distance=0"]
		let key = SHA256.hash(data: data + Data(options.joined(separator: " ").utf8)).hexString
		let output = cacheDirectory.appending(path: "\(key).jxl")

		// An image whose copy is not smaller is remembered too, so it is not encoded in every build.
		let notSmallerMarker = cacheDirectory.appending(path: "\(key).not-smaller")

		if output.isFile {
			return output
		}

		if notSmallerMarker.isFile {
			return nil
		}

		try cacheDirectory.createDirectory()

		// To a temporary file first, so an encode that stops halfway does not leave a broken copy in the cache.
		let temporaryOutput = cacheDirectory.appending(path: "\(key)-\(UUID().uuidString).jxl")
		let process = Process()
		process.executableURL = URL(filePath: "/usr/bin/env")
		process.arguments = ["cjxl", "--quiet"] + options + [path(percentEncoded: false), temporaryOutput.path(percentEncoded: false)]
		process.standardOutput = FileHandle.nullDevice
		let errorPipe = Pipe()
		process.standardError = errorPipe
		var errorOutput = Data()

		let status = try await process.runUntilExit {
			for try await byte in errorPipe.fileHandleForReading.bytes {
				errorOutput.append(byte)
			}
		}

		// `env` exits with 127 when it cannot find the command.
		guard status != 127 else {
			throw ContentError(file: self, reason: "`cjxl` is missing, which makes the JPEG XL copies of the images. Install it with `brew install jpeg-xl`.")
		}

		guard status == 0 else {
			try? temporaryOutput.removeIfExists()
			throw ContentError(file: self, reason: "`cjxl` could not make a JPEG XL copy of the image: \(String(decoding: errorOutput, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines))")
		}

		let size = try temporaryOutput.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? .max

		guard size < data.count else {
			try? temporaryOutput.removeIfExists()
			try Data().write(to: notSmallerMarker)
			return nil
		}

		// Another build can have made the same copy at the same time, which is the same file, so the move can find it there.
		do {
			try FileManager.default.moveItem(at: temporaryOutput, to: output)
		} catch {
			try? temporaryOutput.removeIfExists()

			guard output.isFile else {
				throw error
			}
		}

		return output
	}

	/**
	The pixel size of an image, or `nil` when it cannot be read, like for the `width` and `height` of an image, so the layout does not move while it loads. Only the header of the image is read. For a video, use ``videoSize``.
	*/
	public var imageSize: PixelSize? {
		imageProperties.flatMap(PixelSize.init(imageProperties:))
	}

	/**
	The size of an image on a page, in CSS pixels, or `nil` when it cannot be read. It is the pixel size, or half of it for an image with 144 DPI, like a screenshot of a Retina display on macOS, so the image is sharp. Other DPI values, like 300 from a photo editor, say nothing about the screen, so those images keep their pixel size.
	*/
	public var displaySize: PixelSize? {
		guard
			let properties = imageProperties,
			let size = PixelSize(imageProperties: properties)
		else {
			return nil
		}

		guard properties[kCGImagePropertyDPIWidth] as? Double == 144 else {
			return size
		}

		return PixelSize(width: size.width / 2, height: size.height / 2)
	}

	/**
	The bits per channel of an image, like 8 or 16, or `nil` when it cannot be read. Only the header of the image is read.
	*/
	public var imageBitDepth: Int? {
		imageProperties?[kCGImagePropertyDepth] as? Int
	}

	/**
	The properties of an image, like its pixel size. Only the header of the image is read.
	*/
	private var imageProperties: [CFString: Any]? {
		guard let source = CGImageSourceCreateWithURL(self as CFURL, nil) else {
			return nil
		}

		return CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
	}

	/**
	An image decoded at a bounded pixel size, with its orientation applied, for color sampling or previews without loading the full raster.
	*/
	public func imageThumbnail(maximumPixelSize: Int) -> CGImage? {
		precondition(maximumPixelSize > 0, "A thumbnail size must be positive.")

		guard let source = CGImageSourceCreateWithURL(self as CFURL, [kCGImageSourceShouldCache: false] as CFDictionary) else {
			return nil
		}

		return CGImageSourceCreateThumbnailAtIndex(source, 0, [
			kCGImageSourceCreateThumbnailFromImageAlways: true,
			kCGImageSourceCreateThumbnailWithTransform: true,
			kCGImageSourceThumbnailMaxPixelSize: maximumPixelSize,
		] as CFDictionary)
	}

	/**
	The pixel size of a video, like an MP4, or `nil` when it cannot be read, so the layout does not move while it loads. It is the size of the first video track, without its rotation.
	*/
	public var videoSize: PixelSize? {
		get async {
			guard
				let track = try? await AVURLAsset(url: self).loadTracks(withMediaType: .video).first,
				let size = try? await track.load(.naturalSize)
			else {
				return nil
			}

			return PixelSize(width: Int(size.width.rounded()), height: Int(size.height.rounded()))
		}
	}
}

extension String {
	/**
	The text with `&`, `<`, `>`, and `"` escaped, for HTML and XML text and attribute values.

	It works on Unicode scalars, as a combining mark after a quote makes them one character, which would not equal the quote.
	*/
	public var escapedForHTML: String {
		// Most text has nothing to escape, so it is returned as it is. The four characters are single bytes in UTF-8, which are never part of another character. The bytes are read with `withUTF8`, which is much faster than the `utf8` view in a debug build.
		var text = self

		let needsEscaping = text.withUTF8 { bytes in
			for byte in bytes {
				switch byte {
				case UInt8(ascii: "&"), UInt8(ascii: "<"), UInt8(ascii: ">"), UInt8(ascii: "\""):
					return true
				default:
					continue
				}
			}

			return false
		}

		guard needsEscaping else {
			return self
		}

		var result = ""
		result.reserveCapacity(utf8.count)

		for scalar in unicodeScalars {
			switch scalar {
			case "&":
				result += "&amp;"
			case "<":
				result += "&lt;"
			case ">":
				result += "&gt;"
			case "\"":
				result += "&quot;"
			default:
				result.unicodeScalars.append(scalar)
			}
		}

		return result
	}

	/**
	The text with typographic quotes and apostrophes instead of straight ones, like “it’s” for "it's", for text from others that is not Markdown, like an App Store review. A quote at the start or after a space or an opening bracket opens, and any other closes, so an apostrophe in a word is ’.

	```swift
	#"She said "it's fine""#.typographicQuotes
	//=> "She said “it’s fine”"
	```
	*/
	public var typographicQuotes: String {
		var result = ""

		for character in self {
			// The character before it in the result, so a quote right after an opening quote opens too, like in `"'Hi'"`.
			let isOpening = result.last.map { $0.isWhitespace || "([{“‘—–-".contains($0) } ?? true

			switch character {
			case "\"":
				result.append(isOpening ? "“" : "”")
			case "'":
				result.append(isOpening ? "‘" : "’")
			default:
				result.append(character)
			}
		}

		return result
	}

	/**
	A hash that is the same in every process (FNV-1a), unlike `hashValue`.
	*/
	public var stableHash: UInt64 {
		// The bytes are read with `withUTF8`, which is much faster than the `utf8` view in a debug build.
		var text = self

		return text.withUTF8 { bytes in
			var hash: UInt64 = 0xCBF2_9CE4_8422_2325

			for byte in bytes {
				hash = (hash ^ UInt64(byte)) &* 0x100_0000_01B3
			}

			return hash
		}
	}
}

extension Process {
	/**
	Runs the process, and returns its exit status when it exits. Waiting does not block a thread of the concurrency pool.

	`whileRunning` runs after the process started, like reading its output from a pipe, which must be read while it runs, as a full pipe stops the process.

	```swift
	let status = try await process.runUntilExit {
		for try await line in pipe.fileHandleForReading.bytes.lines {
			print(line)
		}
	}
	```

	Throws when the process cannot start, when `whileRunning` throws, or with `CancellationError` when the task is cancelled before the process exits. The process keeps running in the last two cases.
	*/
	public func runUntilExit(whileRunning: () async throws -> Void = {}) async throws -> Int32 {
		let (exitStatus, exitStatusContinuation) = AsyncStream.makeStream(of: Int32.self)

		terminationHandler = { process in
			exitStatusContinuation.yield(process.terminationStatus)
			exitStatusContinuation.finish()
		}

		try run()
		try await whileRunning()

		for await status in exitStatus {
			return status
		}

		throw CancellationError()
	}
}

/**
A URL from a string literal, which is checked when the code compiles, so a typo is a compile error instead of a crash when it runs.

```swift
static let sourceURL = #URL("https://github.com/sindresorhus/sindresorhus.github.com")
```
*/
@freestanding(expression)
public macro URL(_ string: StaticString) -> URL = #externalMacro(module: "SiteKitMacros", type: "URLMacro")

extension JSONEncoder {
	/**
	The value as JSON for a page, with sorted keys, so the output is the same in every build, and with slashes as they are. Encoding plain values only fails for a mistake, like a `Double.nan`, which stops the build, so a page never has a script without its data.
	*/
	public static func pageJSON(_ value: some Encodable, keyEncodingStrategy: KeyEncodingStrategy = .useDefaultKeys) -> String {
		let encoder = JSONEncoder()
		encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
		encoder.keyEncodingStrategy = keyEncodingStrategy

		do {
			return String(decoding: try encoder.encode(value), as: UTF8.self)
		} catch {
			preconditionFailure("Could not encode \(type(of: value)) as JSON: \(error)")
		}
	}
}

extension [URLQueryItem] {
	/**
	The query without `?`, encoding literal plus signs so form-style decoders preserve them. An empty list has an empty query.
	*/
	public var formEncodedQuery: String {
		var components = URLComponents()
		components.queryItems = self
		return (components.percentEncodedQuery ?? "").replacing("+", with: "%2B")
	}
}

extension URL {
	/**
	Appends query values with literal plus signs escaped for servers that decode queries like forms. A query that the URL already has is kept as it is.
	*/
	public func appending(formQueryItems queryItems: [URLQueryItem]) -> Self {
		guard !queryItems.isEmpty else {
			return self
		}

		guard var components = URLComponents(url: self, resolvingAgainstBaseURL: true) else {
			preconditionFailure("The URL cannot have query items: \(self)")
		}

		let query = queryItems.formEncodedQuery

		components.percentEncodedQuery = if
			let existingQuery = components.percentEncodedQuery,
			!existingQuery.isEmpty
		{
			"\(existingQuery)&\(query)"
		} else {
			query
		}

		guard let url = components.url else {
			preconditionFailure("The URL cannot have query items: \(self)")
		}

		return url
	}
}
