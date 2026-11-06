import Foundation
import SiteKit

/**
A screenshot or video of an app, with its pixel size so the page does not shift while loading.
*/
enum MediaAsset: Hashable {
	/**
	A screenshot, with its JPEG XL copy when it is smaller.
	*/
	case image(ScreenshotAsset)

	/**
	A video, with a frame of it as the poster, usually the first, which shows until it plays, and while it does not play, like when the visitor prefers reduced motion. It is a JPEG next to the video, like `video1-poster.jpg` for `video1.mp4`, made once with the video, so the build needs no video tools.
	*/
	case video(VideoAsset)

	var path: RoutePath {
		switch self {
		case .image(let screenshot):
			screenshot.path
		case .video(let video):
			video.path
		}
	}

	var size: PixelSize {
		switch self {
		case .image(let screenshot):
			screenshot.size
		case .video(let video):
			video.size
		}
	}

	/**
	The video payload, or `nil` for a screenshot, for places that only accept a video.
	*/
	var video: VideoAsset? {
		if case .video(let video) = self {
			video
		} else {
			nil
		}
	}

	/**
	The screenshot payload, or `nil` for a video, for places that only accept an image.
	*/
	var screenshot: ScreenshotAsset? {
		if case .image(let screenshot) = self {
			screenshot
		} else {
			nil
		}
	}

	var isImage: Bool {
		if case .image = self {
			true
		} else {
			false
		}
	}

	var isVideo: Bool {
		if case .video = self {
			true
		} else {
			false
		}
	}

	/**
	The largest height that the page shows an item at, in CSS pixels, on wider screens.
	*/
	static let maximumDisplayHeight = 640.0

	/**
	The largest width of the carousel, in CSS pixels (``Style/ColumnWidth/wide``, 64rem).
	*/
	static let maximumCarouselWidth = 1024.0

	/**
	The largest width that the page shows the item at, in CSS pixels: its width in pixels, but not wider than at the largest height (``maximumDisplayHeight``), like 1024 for a screenshot of 16:10.
	*/
	var maximumDisplayWidth: Double {
		size.displayWidth(maximumHeight: Self.maximumDisplayHeight)
	}

	/**
	The JPEG XL copy of a screenshot, when it is smaller. Videos have none.
	*/
	var jpegXL: JPEGXLCopy? {
		screenshot?.jpegXL
	}

	/**
	The videos (`video1.mp4`) and then the screenshots (`screenshot1.png/jpg`) in the directory, each in natural order. A video without its poster, two screenshots with the same name in other formats, like `screenshot6.png` and `screenshot6.jpg`, another name, like `screenshot1 copy.jpg` from a copy in Finder or `Screenshot7.jpg` with a capital letter, and another format, like `screenshot7.heic` or `video1.mov`, are content errors, as the page would silently show one item less.
	*/
	static func discover(in directory: RoutePath, project: Project) async throws -> [Self] {
		let directoryFiles = project.publicFile(directory).files

		// The name is the prefix and a number, like `screenshot7`, or only the prefix, like the one screenshot of an old app. Another name with the prefix would be one more item, like a copy in Finder, and it would move the numbers that the guides use.
		// Each file whose name starts with the prefix, in any case, is meant as an item, so one in another format, like `screenshot7.heic` or the `video1.mov` of a screen recording, or with a capital letter, like `Screenshot7.jpg`, is an error, not a file that the page leaves out. The poster of a video is not an item.
		func files(prefix: String, extensions: Set<String>, formatFix: (_ name: String) -> String) throws -> [URL] {
			let files = directoryFiles.filter { $0.lastPathComponent.lowercased().hasPrefix(prefix) && $0.lastPathComponent.wholeMatch(of: videoPosterName) == nil }

			if let file = files.first(where: { !extensions.contains($0.pathExtension.lowercased()) }) {
				throw ContentError(file: file, reason: formatFix(file.lastPathComponent))
			}

			if let file = files.first(where: { !$0.nameWithoutExtension.hasPrefix(prefix) || !$0.nameWithoutExtension.dropFirst(prefix.count).allSatisfy({ $0.isASCII && $0.isNumber }) }) {
				throw ContentError(file: file, reason: "Name the file like “\(prefix)7.\(file.pathExtension)”, in lowercase. The page shows each file whose name starts with “\(prefix)”, in the order of their numbers.")
			}

			return files.sorted(using: KeyPathComparator(\.lastPathComponent, comparator: .localizedStandard))
		}

		/**
		The size of a media file, or a content error when it could not be read.
		*/
		func checkedSize(_ size: PixelSize?, of file: URL) throws -> PixelSize {
			guard let size else {
				throw ContentError(file: file, reason: "Could not read the size of the media file.")
			}

			return size
		}

		var assets = [Self]()

		let videos = try files(prefix: "video", extensions: ["mp4"]) { name in
			"The page shows only MP4 videos. Encode \(name) as MP4, like the other videos (`~/dev/project-extras/Website`)."
		}

		for file in videos {
			let posterName = "\(file.nameWithoutExtension)-poster.jpg"

			guard directoryFiles.contains(where: { $0.lastPathComponent == posterName }) else {
				throw ContentError(file: file, reason: "The video has no poster. Add its first frame next to it as “\(posterName)”.")
			}

			assets.append(.video(VideoAsset(
				path: directory.appending(file.lastPathComponent),
				size: try checkedSize(await file.cachedValue(using: .videoSize), of: file),
				poster: directory.appending(posterName)
			)))
		}

		let screenshots = try files(prefix: "screenshot", extensions: ["png", "jpg", "jpeg"]) { name in
			"The page shows only PNG and JPEG screenshots. Convert \(name) to JPEG."
		}

		// Both would have the same number on the page, and the same JPEG XL copy, like `screenshot6.jxl`. In the order of the files, so the error is the same on each build.
		let screenshotsByName = Dictionary(grouping: screenshots) { $0.nameWithoutExtension }

		if let sameName = screenshots.map({ screenshotsByName[$0.nameWithoutExtension] ?? [] }).first(where: { $0.count > 1 }) {
			let names = sameName.map(\.lastPathComponent).formattedList(.and)
			throw ContentError(file: project.publicFile(directory), reason: "The screenshots \(names) have the same name. Keep one.")
		}

		for file in screenshots {
			let jpegXL = try await JPEGXLCopy(of: directory.appending(file.lastPathComponent), project: project)
			let size = await file.cachedValue(using: .imageSize)
			assets.append(.image(ScreenshotAsset(
				path: directory.appending(file.lastPathComponent),
				// The name is `screenshot` and then only digits, which `files(prefix:extensions:formatFix:)` checked.
				number: Int(file.nameWithoutExtension.dropFirst("screenshot".count)),
				size: try checkedSize(size, of: file),
				jpegXL: jpegXL
			)))
		}

		return assets
	}
}

/**
A screenshot with its path, pixel size, and optional smaller JPEG XL copy. Screenshot-only consumers cannot receive a video.
*/
struct ScreenshotAsset: Hashable {
	let path: RoutePath

	/**
	The number in the name of the file, like 2 for `screenshot2.jpg`, which a guide names. `nil` for `screenshot.jpg`.
	*/
	let number: Int?

	let size: PixelSize
	let jpegXL: JPEGXLCopy?

	/**
	The largest width at which the carousel shows this screenshot, in CSS pixels. See ``MediaAsset/maximumDisplayWidth``.
	*/
	var maximumDisplayWidth: Double {
		size.displayWidth(maximumHeight: MediaAsset.maximumDisplayHeight)
	}

	/**
	The width in pixels that this screenshot needs to be sharp on Retina screens at its largest size: two pixels for each CSS pixel, like 2048 for a screenshot of 16:10. The carousel is at most 1024 CSS pixels wide (``MediaAsset/maximumCarouselWidth``), so a wider screenshot is smaller.
	*/
	var retinaWidth: Int {
		size.retinaWidth(maximumHeight: MediaAsset.maximumDisplayHeight, maximumWidth: MediaAsset.maximumCarouselWidth)
	}

	/**
	Whether this screenshot has about two pixels for each CSS pixel at its largest size, so its text is as sharp as the text of the page on Retina screens. A few percent less does not show, like 2000 pixels for 1024 CSS pixels.
	*/
	var isSharpOnRetina: Bool {
		size.isSharpOnRetina(maximumHeight: MediaAsset.maximumDisplayHeight, maximumWidth: MediaAsset.maximumCarouselWidth)
	}
}

/**
A video with its path, pixel size, and poster. Link preview metadata accepts this type so a screenshot cannot become a video preview.
*/
struct VideoAsset: Hashable {
	let path: RoutePath
	let size: PixelSize
	let poster: RoutePath
}

/**
A JPEG XL copy of a PNG or JPEG image of the site, published next to the image, like `/dato/screenshot1.jxl` for `/dato/screenshot1.jpg`. It looks like the image, but is smaller (`URL.jpegXLVersion(cacheDirectory:)`), so the pages offer it in a `<picture>`, with the image for browsers without JPEG XL. The places that need a common format keep the image, like the favicon, the social card, and the sitemap.
*/
struct JPEGXLCopy: Hashable {
	let path: RoutePath

	/**
	The copy in the cache of the build.
	*/
	let file: URL

	/**
	The copy of an image in `public` or a page bundle, or `nil` when the image cannot be read, or the copy is not smaller.
	*/
	init?(of imagePath: RoutePath, project: Project) async throws {
		try await self.init(ofFile: project.publicFile(imagePath), publishedAt: imagePath, project: project)
	}

	/**
	The copy of an image file that the site publishes at the path, like an icon that the build downloads, or `nil` when the image cannot be read, or the copy is not smaller.
	*/
	init?(ofFile image: URL, publishedAt imagePath: RoutePath, project: Project) async throws {
		// The size and the copy are read once for each version of the image, as `website serve` loads the content for each rebuild. Limitation: a copy that is removed from the cache while `website serve` runs is not made again until it restarts.
		guard
			await image.cachedValue(using: .imageSize) != nil,
			let file = try await image.cachedValue(using: .jpegXLVersion(cacheDirectory: project.root.appending(path: ".cache/jpeg-xl")))
		else {
			return nil
		}

		self.path = imagePath.replacingPathExtension("jxl")
		self.file = file
	}

	var route: Route {
		.file(path) { [file] in
			try Data(contentsOf: file)
		}
	}
}

/**
The file name of the poster of a video, like `video1-poster.jpg`. Stored, as it runs for each file of each app.
*/
private nonisolated(unsafe) let videoPosterName = /video\d*-poster\.jpg/
