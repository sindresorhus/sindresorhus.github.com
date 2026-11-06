import AVFoundation
import CryptoKit
import Foundation
import ImageIO
import Subprocess
import Synchronization
import System

extension Sequence<UInt8> {
	/**
	The bytes as lowercase hexadecimal digits, two for each byte, like `0aff` for `[10, 255]`, like for a hash.
	*/
	public var hexString: String {
		map { ($0 < 16 ? "0" : "") + String($0, radix: 16) }.joined()
	}
}

extension UInt8 {
	/**
	Whether the byte is an ASCII letter, from `A` through `Z` or from `a` through `z`.
	*/
	var isASCIILetter: Bool {
		(65...90).contains(self) || (97...122).contains(self)
	}

	/**
	Whether the byte is an ASCII digit, from `0` through `9`.
	*/
	var isASCIIDigit: Bool {
		(48...57).contains(self)
	}
}

/**
Shared operations on collections, including strings and arrays.
*/
extension Collection {
	/**
	`nil` for an empty collection, like for leaving an empty list out of JSON.
	*/
	public var nilIfEmpty: Self? {
		isEmpty ? nil : self
	}
}

extension Sequence {
	/**
	The elements without the later ones with the same key, in their order, like one release of each project.

	```
	["ky", "got", "ky"].uniqued(by: \.self)
	//=> ["ky", "got"]
	```
	*/
	public func uniqued<Key: Hashable>(by key: (Element) -> Key) -> [Element] {
		var keys = Set<Key>()
		return filter { keys.insert(key($0)).inserted }
	}

	/**
	The elements by their keys, for a lookup by a key, like the apps by their slugs. The first element of a key wins.

	```
	["ky", "got", "np"].keyed(by: \.count)
	//=> [2: "ky", 3: "got"]
	```
	*/
	public func keyed<Key: Hashable>(by key: (Element) -> Key) -> [Key: Element] {
		Dictionary(map { (key($0), $0) }) { first, _ in first }
	}
}

/**
Text normalization shared by the Markdown and CSS readers.
*/
extension String {
	/**
	Replaces Windows CRLF line endings with LF, preserving lone CR characters and trailing newlines.
	*/
	public var normalizingWindowsLineEndings: String {
		replacing("\r\n", with: "\n")
	}
}

extension String {
	/**
	An error when authored content uses Windows CRLF line endings instead of LF.
	*/
	public func windowsLineEndingError(file: URL? = nil) -> ContentError? {
		guard contains("\r\n") else {
			return nil
		}

		return ContentError(file: file, reason: "CRLF line endings are not supported. Use LF line endings.")
	}

	/**
	An error when authored content has a git conflict marker, like `<<<<<<< Updated upstream` after `git stash pop`, at the line of the first marker. Without it, the page would show both versions and the markers, or the error would be about something else, like a key of the frontmatter.

	Limitation: A line of a code block that starts like a marker is an error too.
	*/
	public func conflictMarkerError(file: URL? = nil) -> ContentError? {
		let lines = split(separator: "\n", omittingEmptySubsequences: false)

		guard let index = lines.firstIndex(where: { $0.hasPrefix("<<<<<<< ") || $0.hasPrefix(">>>>>>> ") }) else {
			return nil
		}

		return ContentError(file: file, line: SourceLocation.Line(index + 1), reason: "The file has a git conflict marker (`\(lines[index])`), like after `git stash pop`. Keep one of the two versions, and remove the three marker lines.")
	}

	/**
	The candidate that is the closest to the string, for a “Did you mean …?” of a misspelled name, like `note` for `notes`. It differs in at most a third of the characters (at least one), ignoring case, so a name that is not a misspelling gets no suggestion. Of the candidates at the same distance, the one that comes first alphabetically is used, so the suggestion is the same on each run.

	```swift
	"notes".closest(in: ["note", "platform"])
	//=> "note"
	```
	*/
	public func closest(in candidates: some Sequence<String>) -> String? {
		let lowercased = Array(lowercased())
		let maximumDistance = max(1, count / 3)

		// A changed character is a removal and an insertion, so the distance is the larger number of the two.
		return candidates
			.filter { $0 != self }
			.map { candidate in
				let difference = lowercased.difference(from: Array(candidate.lowercased()))
				return (candidate: candidate, distance: max(difference.insertions.count, difference.removals.count))
			}
			.filter { $0.distance <= maximumDistance }
			.sorted(using: [KeyPathComparator(\.distance), KeyPathComparator(\.candidate)])
			.first?
			.candidate
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

	Throws if the directory or any of its contents cannot be read, so a wrong path or an unreadable subdirectory is an error instead of an incomplete list.
	*/
	public func filesRecursively() throws -> [URL] {
		try checkedContentsRecursively()
			.filter(\.isFile)
			.sorted(using: KeyPathComparator(\.path, comparator: String.StandardComparator.lexical))
	}

	/**
	The files and directories in the directory and its subdirectories, in no particular order. Throws the underlying file-system error when the directory or any of its contents cannot be read, instead of returning an incomplete list.

	- Parameter includesHiddenFiles: Whether hidden files and directories, like `.DS_Store`, are included.
	*/
	public func checkedContentsRecursively(includesHiddenFiles: Bool = true) throws -> [URL] {
		var enumerationError: (any Error)?
		guard let enumerator = FileManager.default.enumerator(
			at: self,
			includingPropertiesForKeys: [.isDirectoryKey, .isSymbolicLinkKey, .fileSizeKey, .contentModificationDateKey],
			options: includesHiddenFiles ? [] : .skipsHiddenFiles,
			errorHandler: { _, error in
				enumerationError = error
				return false
			}
		) else {
			throw CocoaError(.fileReadUnknown, userInfo: [NSFilePathErrorKey: path(percentEncoded: false)])
		}

		let contents = enumerator.compactMap { $0 as? URL }

		if let enumerationError {
			throw enumerationError
		}

		return contents
	}

	/**
	The files and directories in the directory and its subdirectories, in no particular order. Empty when the directory or any of its contents cannot be read.

	- Parameter includesHiddenFiles: Whether hidden files and directories, like `.DS_Store`, are included.
	*/
	public func contentsRecursively(includesHiddenFiles: Bool = true) -> [URL] {
		(try? checkedContentsRecursively(includesHiddenFiles: includesHiddenFiles)) ?? []
	}

	/**
	Whether the URL is an existing directory with nothing in it, not even hidden files.
	*/
	public var isEmptyDirectory: Bool {
		(try? FileManager.default.contentsOfDirectory(atPath: path(percentEncoded: false)))?.isEmpty == true
	}

	/**
	Copies the file to the destination, which must not exist yet, with its modification date.

	It writes the data, as FSEvents reports an APFS clone, like `FileManager` makes, also as a change of the source, and it keeps that flag on the later events of the source. So a watcher of the source (``DirectoryWatcher``) would rebuild again after each copy, and it could not leave out the clones without also leaving out the real edits.
	*/
	public func copy(to destination: URL) throws {
		guard copyfile(path(percentEncoded: false), destination.path(percentEncoded: false), nil, copyfile_flags_t(COPYFILE_ALL | COPYFILE_EXCL)) == 0 else {
			throw Errno(rawValue: errno)
		}
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
	Whether the URL is the same file as the other one, also when one of them is relative or has symbolic links of the directories, like `/tmp` and `/private/tmp`.
	*/
	public func isSameFile(as other: URL) -> Bool {
		pathWithResolvedParent == other.pathWithResolvedParent
	}

	/**
	Whether the URL is the file, or is in the directory or its subdirectories (``isInside(_:)``), like a file of the paths of `website check content/apps/dato`, which can be files or directories.
	*/
	public func isSameFileOrInside(_ fileOrDirectory: URL) -> Bool {
		isSameFile(as: fileOrDirectory) || isInside(fileOrDirectory)
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
			.map { $0.fileURL(in: self) }
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
	public var servedFileCandidates: [PublishedFilePath] {
		let urlPath = removingPercentEncoding ?? self
		let components = urlPath.split(separator: "/", omittingEmptySubsequences: true).filter { $0 != "." }

		guard
			!urlPath.contains("\0"),
			!components.contains("..")
		else {
			return []
		}

		let relative = components.joined(separator: "/")

		guard
			!relative.isEmpty,
			!urlPath.hasSuffix("/")
		else {
			return [PublishedFilePath(relative.isEmpty ? "index.html" : "\(relative)/index.html")]
		}

		return [relative, "\(relative).html", "\(relative)/index.html"].map { PublishedFilePath($0) }
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

	/**
	Creates a size with positive dimensions. Zero or negative dimensions are invalid.
	*/
	public init?(width: Int, height: Int) {
		guard
			width > 0,
			height > 0
		else {
			return nil
		}

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
	The display width constrained by a maximum height, without enlarging the source.
	*/
	public func displayWidth(maximumHeight: Double) -> Double {
		precondition(maximumHeight.isFinite && maximumHeight > 0, "The maximum display height must be finite and positive.")
		return min(Double(width), maximumHeight * aspectRatio)
	}

	/**
	The source width needed for two pixels per display pixel inside the given display bounds, rounded up so a fractional pixel never makes the image less sharp.
	*/
	public func retinaWidth(maximumHeight: Double, maximumWidth: Double) -> Int {
		precondition(maximumHeight.isFinite && maximumHeight > 0 && maximumWidth.isFinite && maximumWidth > 0, "The display bounds must be finite and positive.")
		return Int((2 * min(maximumHeight * aspectRatio, maximumWidth)).rounded(.up))
	}

	/**
	Whether the source has approximately two pixels per display pixel within the bounds. The tolerance allows a small shortfall that is not visibly less sharp.
	*/
	public func isSharpOnRetina(maximumHeight: Double, maximumWidth: Double, tolerance: Double = 0.95) -> Bool {
		precondition((0...1).contains(tolerance), "The Retina tolerance must be between zero and one.")
		return Double(width) >= tolerance * Double(retinaWidth(maximumHeight: maximumHeight, maximumWidth: maximumWidth))
	}

	/**
	Like `1280×800`.
	*/
	public var description: String {
		"\(width)×\(height)"
	}
}

/**
The header metadata of an image, decoded once at the ImageIO boundary instead of passing its untyped property dictionary to callers.
*/
public struct ImageMetadata: Sendable {
	public let size: PixelSize
	public let horizontalDPI: Double?
	public let bitDepth: Int?

	/**
	Reads the supported facts together. A header without valid dimensions cannot describe an image of the site.
	*/
	fileprivate init?(properties: [CFString: Any]) {
		guard let size = PixelSize(imageProperties: properties) else {
			return nil
		}

		self.size = size
		self.horizontalDPI = properties[kCGImagePropertyDPIWidth] as? Double
		self.bitDepth = properties[kCGImagePropertyDepth] as? Int
	}

	/**
	The size in CSS pixels. Only the 144 DPI convention identifies a Retina screenshot; a photo's arbitrary print DPI does not change its display size.
	*/
	public var displaySize: PixelSize {
		guard horizontalDPI == 144 else {
			return size
		}

		return PixelSize(width: max(1, size.width / 2), height: max(1, size.height / 2))!
	}
}

/**
The values that were read from files (``Foundation/URL/cachedValue(using:)``), by the file, its size and modification date, and the name and type of the value.
*/
private let fileValues = Mutex<[FileValueKey: any Sendable]>([:])

private struct FileValueKey: Hashable {
	let file: URL
	let stamp: FileStamp
	let name: String
	let valueType: ObjectIdentifier
}

/**
A file-reading operation with its cache identity, result type, and failure type. Define reusable operations once so callers cannot independently pair a name with another reader. Include any configuration that changes the result in the name.
*/
public struct FileRead<Value: Sendable, Failure: Error>: Sendable {
	fileprivate let name: String
	fileprivate let read: @Sendable (URL) async throws(Failure) -> Value

	/**
	Defines an operation. Reads with the same name and result type share cached values for a given version of a file.
	*/
	public init(_ name: String, read: @escaping @Sendable (URL) async throws(Failure) -> Value) {
		self.name = name
		self.read = read
	}
}

extension FileRead where Value == PixelSize?, Failure == Never {
	/**
	The pixel size of an image, or `nil` when the image cannot be read.
	*/
	public static var imageSize: Self {
		Self("imageSize") { $0.imageSize }
	}

	/**
	The pixel size of a video, or `nil` when the video cannot be read.
	*/
	public static var videoSize: Self {
		Self("videoSize") { await $0.videoSize }
	}
}

extension FileRead where Value == URL?, Failure == any Error {
	/**
	A smaller JPEG XL copy. The output directory is part of the operation identity, so another project never receives a cached path in the first project's directory.
	*/
	public static func jpegXLVersion(cacheDirectory: URL) -> Self {
		let directory = cacheDirectory.standardizedFileURL
		return Self("jpegXLVersion:\(directory.absoluteString)") { try await $0.jpegXLVersion(cacheDirectory: directory) }
	}
}

extension URL {
	/**
	A value that is read from the file, like the size of an image, read once per name and value type for each version of the file (its size and modification date) in the process. `website serve` loads the content again for each rebuild, so it only reads the images that changed. A read that throws is not kept.

	- Parameter operation: The operation that owns the cache identity and reader, like `.imageSize`.
	*/
	public func cachedValue<Value, Failure>(using operation: FileRead<Value, Failure>) async throws(Failure) -> Value {
		let key = FileValueKey(file: self, stamp: FileStamp(self), name: operation.name, valueType: ObjectIdentifier(Value.self))

		if
			let stored = fileValues.withLock({ $0[key] }),
			let value = stored as? Value
		{
			return value
		}

		let value = try await operation.read(self)
		fileValues.withLock { $0[key] = value as any Sendable }
		return value
	}

	/**
	A JPEG XL copy of a PNG or JPEG image, or `nil` when the copy is not smaller. A PNG, like an app icon, is encoded at quality 90, which looks the same as the image, and is about a sixth of a lossless copy (the icons of the apps are 1.6 MB instead of 9.5 MB). A JPEG is wrapped losslessly, so the JPEG can be restored bit for bit, as a lossy copy of a JPEG is only a little smaller.

	An image with the data of the other format, like a JPEG that is named `icon.png`, is a content error.

	It runs `cjxl` (`brew install jpeg-xl`), which throws when it is missing. The copy is cached in the directory by a hash of the bytes of the image and the options, so an image is only encoded again when it changes.
	*/
	public func jpegXLVersion(cacheDirectory: URL) async throws -> URL? {
		let data = try Data(contentsOf: self)
		let isJPEG = ["jpg", "jpeg"].contains(pathExtension.lowercased())

		// Before `cjxl`, whose error for a JPEG with the extension of a PNG is about its options, and which encodes a PNG with the extension of a JPEG without a word. A PNG starts with `89 50 4E 47`, and a JPEG with `FF D8 FF`.
		let otherSignature: [UInt8] = isJPEG ? [0x89, 0x50, 0x4E, 0x47] : [0xFF, 0xD8, 0xFF]

		if data.starts(with: otherSignature) {
			let name = nameWithoutExtension

			let reason = if isJPEG {
				"The image is a PNG, but its extension is `.\(pathExtension)`. Export it again as a JPEG, or rename it to `\(name).png`."
			} else {
				"The image is a JPEG, but its extension is `.\(pathExtension)`. Export it again as a PNG, or rename it to `\(name).jpg` where the page allows a JPEG."
			}

			throw ContentError(file: self, reason: reason)
		}

		// The options are part of the key, so a change of them encodes the images again.
		let options = isJPEG ? ["--lossless_jpeg=1"] : ["--quality=90"]
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

		defer {
			try? temporaryOutput.removeIfExists()
		}

		let result: ExecutionResult<Void, DiscardedOutput, StringOutput<UTF8>>

		do {
			result = try await run(
				.name("cjxl"),
				arguments: Arguments(["--quiet"] + options + [path(percentEncoded: false), temporaryOutput.path(percentEncoded: false)]),
				output: .discarded,
				error: .string(limit: 65_536)
			)
		} catch let error as SubprocessError where error.code == .executableNotFound {
			throw ContentError(file: self, reason: "`cjxl` is missing, which makes the JPEG XL copies of the images. Install it with `brew install jpeg-xl`.")
		}

		guard result.terminationStatus.isSuccess else {
			throw ContentError(file: self, reason: "`cjxl` could not make a JPEG XL copy of the image: \(result.standardError.trimmingCharacters(in: .whitespacesAndNewlines))")
		}

		let size = try temporaryOutput.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? .max

		guard size < data.count else {
			try Data().write(to: notSmallerMarker)
			return nil
		}

		// Another build can have made the same copy at the same time, which is the same file, so the move can find it there.
		do {
			try FileManager.default.moveItem(at: temporaryOutput, to: output)
		} catch {
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
		imageMetadata?.size
	}

	/**
	The size of an image on a page, in CSS pixels, or `nil` when it cannot be read. It is the pixel size, or half of it for an image with 144 DPI, like a screenshot of a Retina display on macOS, so the image is sharp. Each dimension is at least one pixel. Other DPI values, like 300 from a photo editor, say nothing about the screen, so those images keep their pixel size.
	*/
	public var displaySize: PixelSize? {
		imageMetadata?.displaySize
	}

	/**
	The bits per channel of an image, like 8 or 16, or `nil` when it cannot be read. Only the header of the image is read.
	*/
	public var imageBitDepth: Int? {
		imageMetadata?.bitDepth
	}

	/**
	The properties of an image, like its pixel size. Only the header of the image is read, and callers that need several facts can keep this value.
	*/
	public var imageMetadata: ImageMetadata? {
		CGImageSource.read(self)?.metadata
	}

	/**
	An image decoded at a bounded pixel size, with its orientation applied, for color sampling or previews without loading the full raster.
	*/
	public func imageThumbnail(maximumPixelSize: Int) -> CGImage? {
		CGImageSource.read(self, shouldCache: false)?.thumbnail(maximumPixelSize: maximumPixelSize)
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

/**
Image reads that keep ImageIO's untyped properties and creation options at the source boundary.
*/
extension CGImageSource {
	/**
	Reads an image source from a file, or `nil` when the file cannot be read. Keep the source to read its metadata and images together.

	- Parameter shouldCache: Pass `false` to disable ImageIO's caching of decoded pixels, like for a bounded thumbnail. The default preserves ImageIO's default options.
	*/
	public static func read(_ url: URL, shouldCache: Bool = true) -> CGImageSource? {
		let options = shouldCache ? nil : [kCGImageSourceShouldCache: false] as CFDictionary
		return CGImageSourceCreateWithURL(url as CFURL, options)
	}

	/**
	The first image's header metadata, without decoding the raster.
	*/
	public var metadata: ImageMetadata? {
		guard let properties = CGImageSourceCopyPropertiesAtIndex(self, 0, nil) as? [CFString: Any] else {
			return nil
		}

		return ImageMetadata(properties: properties)
	}

	/**
	The first decoded image, or `nil` when it cannot be read.
	*/
	public var firstImage: CGImage? {
		CGImageSourceCreateImageAtIndex(self, 0, nil)
	}

	/**
	The first image decoded at a bounded pixel size, with its orientation applied.
	*/
	public func thumbnail(maximumPixelSize: Int) -> CGImage? {
		precondition(maximumPixelSize > 0, "A thumbnail size must be positive.")

		return CGImageSourceCreateThumbnailAtIndex(
			self,
			0,
			[
				kCGImageSourceCreateThumbnailFromImageAlways: true,
				kCGImageSourceCreateThumbnailWithTransform: true,
				kCGImageSourceThumbnailMaxPixelSize: maximumPixelSize,
			] as CFDictionary
		)
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
	The text of an HTML attribute value or element, with the escapes that HTML writes decoded, like `&amp;` to `&`. `&amp;` is last, so `&amp;lt;` is `&lt;`, not `<`.
	*/
	public var decodingHTMLEscapes: String {
		guard contains("&") else {
			return self
		}

		return replacing("&lt;", with: "<")
			.replacing("&gt;", with: ">")
			.replacing("&quot;", with: "\"")
			.replacing("&#39;", with: "'")
			.replacing("&amp;", with: "&")
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

/**
A URL from a string literal, which is checked when the code compiles, so a typo is a compile error instead of a crash when it runs.

```swift
static let sourceURL = #URL("https://github.com/sindresorhus/sindresorhus.github.com")
```
*/
@freestanding(expression)
public macro URL(_ string: StaticString) -> URL = #externalMacro(module: "SiteKitMacros", type: "URLMacro")

/**
A route path from a string literal, which is checked when the code compiles, so a typo, like a missing `/` or one at the end, is a compile error instead of a crash when a page first uses it.

```swift
let faq = #path("/apps/faq")
```
*/
@freestanding(expression)
public macro path(_ string: StaticString) -> RoutePath = #externalMacro(module: "SiteKitMacros", type: "RoutePathMacro")

extension JSONEncoder {
	/**
	The value as JSON for a page, with sorted keys, so the output is the same in every build, and with slashes as they are. Encoding plain values only fails for a mistake, like a `Double.nan`, which stops the build, so a page never has a script without its data.
	*/
	public static func pageJSON(_ value: some Encodable) -> String {
		let encoder = JSONEncoder()
		encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]

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

extension Locale {
	/**
	English, the language of the site, so numbers, dates, and lists do not depend on the build machine.
	*/
	public static let site = Self(identifier: "en_US")
}

extension URL {
	/**
	The name of the file without its extension, like `screenshot2` for `screenshot2.jpg`.
	*/
	public var nameWithoutExtension: String {
		deletingPathExtension().lastPathComponent
	}
}

extension FormatStyle where Self == IntegerFormatStyle<Int> {
	/**
	A whole number in the language of the site, without a thousands separator, like “1234”, as the site writes no number with one.
	*/
	public static var siteNumber: Self {
		.number.grouping(.never).locale(.site)
	}
}

extension FormatStyle where Self == ByteCountFormatStyle {
	/**
	The size of a file in the language of the site, like “12.3 MB”.
	*/
	public static var siteFileSize: Self {
		.byteCount(style: .file).locale(.site)
	}
}

extension Sequence<String> {
	/**
	The strings as a list in the language of the site, like “a, b, and c” for `.and`, or “a, b, or c” for `.or`.
	*/
	public func formattedList(_ type: ListFormatStyle<StringStyle, [String]>.ListType) -> String {
		Array(self).formatted(.list(type: type).locale(.site))
	}
}

extension String {
	/**
	The noun for the count: as it is for 1, else in the plural, like “day” and “days”. The plural adds an “s”, unless it is given, like “repositories”.
	*/
	public func pluralized(for count: Int, plural: String? = nil) -> String {
		count == 1 ? self : plural ?? self + "s"
	}
}

extension Int {
	/**
	The count with the noun, in the plural when the count is not 1, like “1 day” or “1234 days”, without a thousands separator, as the site writes no count with one. The plural adds an “s”.
	*/
	public func formatted(counting noun: String) -> String {
		"\(formatted(.siteNumber)) \(noun.pluralized(for: self))"
	}
}

extension Sequence where Element: Sendable {
	/**
	The results of the transform of each element, in the order of the elements. The transforms run at the same time, like a request for each element, and the first error stops them.

	```
	let pages = try await urls.concurrentMap { try await download($0) }
	```

	- Parameter name: The name of the task of an element, like the path of a page, which a debugger, a crash report, and Instruments show, so a crash or a slow element shows which element it is.
	*/
	public func concurrentMap<Transformed: Sendable>(name: ((Element) -> String)? = nil, _ transform: @escaping @Sendable (Element) async throws -> Transformed) async throws -> [Transformed] {
		try await withThrowingTaskGroup { group in
			for (index, element) in enumerated() {
				group.addTask(name: name?(element)) {
					(index: index, value: try await transform(element))
				}
			}

			return try await group.reduce(into: []) { $0.append($1) }
				.sorted(using: KeyPathComparator(\.index))
				.map(\.value)
		}
	}

	/**
	The ordered results of concurrent transforms that cannot fail.
	*/
	public func concurrentMap<Transformed: Sendable>(name: ((Element) -> String)? = nil, _ transform: @escaping @Sendable (Element) async -> Transformed) async -> [Transformed] {
		await withTaskGroup { group in
			for (index, element) in enumerated() {
				group.addTask(name: name?(element)) {
					(index: index, value: await transform(element))
				}
			}

			return await group.reduce(into: []) { $0.append($1) }
				.sorted(using: KeyPathComparator(\.index))
				.map(\.value)
		}
	}
}
