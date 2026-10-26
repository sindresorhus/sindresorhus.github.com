import Foundation
import SiteKit

/**
A screenshot or video of an app, with its pixel size so the page does not shift while loading.
*/
struct MediaAsset: Hashable {
	enum Kind {
		case image
		case video
	}

	let kind: Kind
	let path: RoutePath
	let size: PixelSize

	/**
	The JPEG XL copy of a screenshot, when it is smaller. Videos have none.
	*/
	var jpegXL: JPEGXLCopy?

	/**
	The videos (`video*.mp4`) and then the screenshots (`screenshot*.png/jpg`) in the directory, each in natural order.
	*/
	static func discover(in directory: RoutePath, project: Project) async throws -> [Self] {
		let directoryFiles = project.publicFile(directory).files

		func files(prefix: String, extensions: Set<String>) -> [URL] {
			directoryFiles
				.filter { $0.lastPathComponent.hasPrefix(prefix) && extensions.contains($0.pathExtension.lowercased()) }
				.sorted(using: KeyPathComparator(\.lastPathComponent, comparator: .localizedStandard))
		}

		let videos = files(prefix: "video", extensions: ["mp4"]).map { (Kind.video, $0) }
		let screenshots = files(prefix: "screenshot", extensions: ["png", "jpg", "jpeg"]).map { (Kind.image, $0) }

		var assets = [Self]()

		for (kind, file) in videos + screenshots {
			let size = kind == .video ? await file.videoSize : file.imageSize

			guard let size else {
				throw ContentError(file: file, reason: "Could not read the size of the media file.")
			}

			let path = directory.appending(file.lastPathComponent)
			let jpegXL = kind == .image ? try await JPEGXLCopy(of: path, project: project) : nil
			assets.append(Self(kind: kind, path: path, size: size, jpegXL: jpegXL))
		}

		return assets
	}
}

/**
A JPEG XL copy of a PNG or JPEG image of the site, published next to the image, like `/dato/screenshot1.jxl` for `/dato/screenshot1.jpg`. It looks exactly like the image, but is smaller, so the pages offer it in a `<picture>`, with the image for browsers without JPEG XL. The places that need a common format keep the image, like the favicon, the social card, and the sitemap.
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

		let imagePathText = imagePath.description
		let pathWithoutExtension = imagePathText.lastIndex(of: ".").map { imagePathText[..<$0] } ?? imagePathText[...]
		self.path = RoutePath(pathWithoutExtension + ".jxl")
		self.file = file
	}

	var route: Route {
		.file(path) { [file] in
			try Data(contentsOf: file)
		}
	}
}
