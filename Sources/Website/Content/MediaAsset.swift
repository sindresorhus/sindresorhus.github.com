import Foundation
import SiteKit

/**
A screenshot or video of an app, with its pixel size so the page does not shift while loading.
*/
struct MediaAsset: Hashable, Sendable {
	enum Kind: Sendable {
		case image
		case video
	}

	let kind: Kind
	let path: RoutePath
	let width: Int
	let height: Int

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
			let size = kind == .video ? await file.videoSize : file.mediaSize

			guard let size else {
				throw ContentError(file: file, reason: "Could not read the size of the media file.")
			}

			assets.append(Self(kind: kind, path: directory.appending(file.lastPathComponent), width: size.width, height: size.height))
		}

		return assets
	}
}
