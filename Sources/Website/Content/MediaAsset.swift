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
	The width in pixels that the item needs to be sharp on Retina screens at its largest size: two pixels for each CSS pixel, like 2048 for a screenshot of 16:10. The carousel is at most 1024 CSS pixels wide (``maximumCarouselWidth``), so a wider item is smaller.
	*/
	var retinaWidth: Int {
		size.retinaWidth(maximumHeight: Self.maximumDisplayHeight, maximumWidth: Self.maximumCarouselWidth)
	}

	/**
	Whether the item has about two pixels for each CSS pixel at its largest size, so its text is as sharp as the text of the page on Retina screens. A few percent less does not show, like 2000 pixels for 1024 CSS pixels.
	*/
	var isSharpOnRetina: Bool {
		size.isSharpOnRetina(maximumHeight: Self.maximumDisplayHeight, maximumWidth: Self.maximumCarouselWidth)
	}

	/**
	The JPEG XL copy of a screenshot, when it is smaller. Videos have none.
	*/
	var jpegXL: JPEGXLCopy? {
		screenshot?.jpegXL
	}

	/**
	The videos (`video*.mp4`) and then the screenshots (`screenshot*.png/jpg`) in the directory, each in natural order. A video without its poster is a content error.
	*/
	static func discover(in directory: RoutePath, project: Project) async throws -> [Self] {
		let directoryFiles = project.publicFile(directory).files

		func files(prefix: String, extensions: Set<String>) -> [URL] {
			directoryFiles
				.filter { $0.lastPathComponent.hasPrefix(prefix) && extensions.contains($0.pathExtension.lowercased()) }
				.sorted(using: KeyPathComparator(\.lastPathComponent, comparator: .localizedStandard))
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

		for file in files(prefix: "video", extensions: ["mp4"]) {
			let posterName = "\(file.deletingPathExtension().lastPathComponent)-poster.jpg"

			guard directoryFiles.contains(where: { $0.lastPathComponent == posterName }) else {
				throw ContentError(file: file, reason: "The video has no poster. Add its first frame next to it as “\(posterName)”.")
			}

			assets.append(.video(VideoAsset(
				path: directory.appending(file.lastPathComponent),
				size: try checkedSize(await file.videoSize, of: file),
				poster: directory.appending(posterName)
			)))
		}

		for file in files(prefix: "screenshot", extensions: ["png", "jpg", "jpeg"]) {
			let jpegXL = try await JPEGXLCopy(of: directory.appending(file.lastPathComponent), project: project)
			assets.append(.image(ScreenshotAsset(path: directory.appending(file.lastPathComponent), size: try checkedSize(file.imageSize, of: file), jpegXL: jpegXL)))
		}

		return assets
	}
}

/**
A screenshot with its path, pixel size, and optional smaller JPEG XL copy. Screenshot-only consumers cannot receive a video.
*/
struct ScreenshotAsset: Hashable {
	let path: RoutePath
	let size: PixelSize
	let jpegXL: JPEGXLCopy?

	/**
	The largest width at which the carousel shows this screenshot, in CSS pixels. See ``MediaAsset/maximumDisplayWidth``.
	*/
	var maximumDisplayWidth: Double {
		size.displayWidth(maximumHeight: MediaAsset.maximumDisplayHeight)
	}

	/**
	The width in pixels that this screenshot needs to be sharp on Retina screens at its largest size. See ``MediaAsset/retinaWidth``.
	*/
	var retinaWidth: Int {
		size.retinaWidth(maximumHeight: MediaAsset.maximumDisplayHeight, maximumWidth: MediaAsset.maximumCarouselWidth)
	}

	/**
	Whether this screenshot has about two pixels for each CSS pixel at its largest size. See ``MediaAsset/isSharpOnRetina``.
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
		let image = project.publicFile(imagePath)

		guard
			image.imageSize != nil,
			let file = try await image.jpegXLVersion(cacheDirectory: project.root.appending(path: ".cache/jpeg-xl"))
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
