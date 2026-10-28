import Foundation

/**
Where a problem is, like a content error, a warning, or a broken link: a file, or a line of it, or a published page.

It is printed before the problem, like `content/apps/dato/index.md:12: …`.
*/
public enum SourceLocation: Hashable, Sendable, CustomStringConvertible {
	/**
	A file or a directory, or a line of a file, like `content/apps/dato/index.md:12`.
	*/
	case file(URL, line: Int? = nil)

	/**
	A published page, by its path, like `/apps`, for a problem that is in the page, not in a file.
	*/
	case page(RoutePath)

	/**
	The location as it is printed, like `content/apps/dato/index.md:12`. The site is built in its project root, so the paths are relative to the project (``description(relativeTo:)``).
	*/
	public var description: String {
		description(relativeTo: .currentDirectory())
	}

	/**
	The location with the path of a file relative to the directory when the file is in it, else the full path, so a file outside the directory is not mistaken for one in it.
	*/
	public func description(relativeTo directory: URL) -> String {
		switch self {
		case .file(let url, let line):
			let path = url.isInside(directory) ? url.path(relativeTo: directory) : url.path(percentEncoded: false)
			return line.map { "\(path):\($0)" } ?? path
		case .page(let path):
			return path.description
		}
	}

	/**
	The file of the location. `nil` for a page.
	*/
	public var file: URL? {
		guard case .file(let url, _) = self else {
			return nil
		}

		return url
	}
}
