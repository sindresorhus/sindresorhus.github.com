import Foundation

/**
A screenshot or video of an app, with its pixel size so the page does not shift while loading.
*/
public struct MediaAsset: Hashable, Sendable {
	public enum Kind: Sendable {
		case image
		case video
	}

	public let path: String
	public let width: Int
	public let height: Int

	public var kind: Kind {
		path.hasSuffix(".mp4") ? .video : .image
	}

	/**
	The videos (`video*.mp4`) and then the screenshots (`screenshot*.png/jpg`) in the directory, each in natural order.
	*/
	static func discover(in directory: URL, publicPath: String) throws -> [Self] {
		let directoryFiles = directory.files

		func files(prefix: String, extensions: Set<String>) -> [URL] {
			directoryFiles
				.filter { $0.lastPathComponent.hasPrefix(prefix) && extensions.contains($0.pathExtension.lowercased()) }
				.sorted(using: KeyPathComparator(\.lastPathComponent, comparator: .localizedStandard))
		}

		return try (files(prefix: "video", extensions: ["mp4"]) + files(prefix: "screenshot", extensions: ["png", "jpg", "jpeg"])).map { file in
			guard let size = file.mediaSize else {
				throw MediaError.unreadableSize(file)
			}

			return Self(path: "\(publicPath)/\(file.lastPathComponent)", width: size.width, height: size.height)
		}
	}
}

enum MediaError: Error, CustomStringConvertible {
	case unreadableSize(URL)

	var description: String {
		switch self {
		case .unreadableSize(let file):
			"Could not read the size of \(file.path)"
		}
	}
}
