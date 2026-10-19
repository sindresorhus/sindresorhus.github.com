import Foundation

/**
Writes a site to the output directory: the public assets, every route, and the sitemap.

Afterwards, the output directory has exactly these files. Files that did not change are not written again, so a rebuild only touches what changed.
*/
public struct Publisher: Sendable {
	/**
	The site URL without a trailing slash, like `https://sindresorhus.com`.
	*/
	public let site: URL
	public let project: Project
	public let output: URL

	public init(site: URL, project: Project, output: URL) {
		self.site = site
		self.project = project
		self.output = output.standardizedFileURL
	}

	/**
	Publishes the routes and a sitemap of the pages that are in it. Returns the published files, relative to the output directory, like `apps/dato.html`.

	Throws if two routes or a route and a public file are written to the same file, if a file answers the URL of a page before the page's own file, if the output directory is unsafe or a checkout, or if a route fails to render.
	*/
	@discardableResult
	public func publish(_ routes: [Route]) async throws(PublishingError) -> Set<String> {
		let routes = routes + Sitemap(site: site, pages: routes).routes
		try checkOutputLocation()
		// The files of a page bundle are published with its page, so a draft, which has no page, does not publish its images before its launch.
		let pagePaths = Set(routes.map(\.path))
		let publicFiles = try wrappingFileSystemErrors { try project.publicFiles() }
			.filter { file in
				guard file.source.isInside(project.contentDirectory) else {
					return true
				}

				return pagePaths.contains(file.path.parent)
			}
		try checkForCollisions(routes, publicFiles: publicFiles.map(\.path))
		try wrappingFileSystemErrors { try output.createDirectory() }

		// The old files are removed first. Otherwise, on a case-insensitive disk, a file renamed from `Logo.png` to `logo.png` would be seen as unchanged, and then removed as `Logo.png`.
		let publishedFiles = Set(publicFiles.map(\.path.relativePath) + routes.map(\.outputFile))
		try wrappingFileSystemErrors {
			try removeFiles(except: publishedFiles)
			try copy(publicFiles)
		}

		// The routes render in parallel, as many at a time as the cooperative thread pool runs. Files start first, as they are the slow ones, like the social cards.
		do {
			try await withThrowingTaskGroup(of: Void.self) { group in
				for route in routes.filter(\.isFile) + routes.filter({ !$0.isFile }) {
					group.addTask {
						try await write(route)
					}
				}

				try await group.waitForAll()
			}
		} catch let error as PublishingError {
			throw error
		} catch {
			throw .fileSystem(error)
		}

		return publishedFiles
	}

	/**
	Runs a file operation, and wraps its error.
	*/
	private func wrappingFileSystemErrors<Value>(_ operation: () throws -> Value) throws(PublishingError) -> Value {
		do {
			return try operation()
		} catch {
			throw .fileSystem(error)
		}
	}

	private func write(_ route: Route) async throws {
		let data: Data

		do {
			switch route.output {
			case .page(_, let render):
				data = try Data(render().utf8)
			case .redirect(let destination):
				data = Data(redirectHTML(to: destination).utf8)
			case .file(let render):
				data = try await render()
			}
		} catch {
			throw PublishingError.renderFailed(route.path, error)
		}

		let file = output.appending(path: route.outputFile)

		guard (try? Data(contentsOf: file)) != data else {
			return
		}

		// Atomic, so the preview server never serves a half-written page during a rebuild.
		try file.deletingLastPathComponent().createDirectory()
		try data.write(to: file, options: .atomic)
	}

	private func redirectHTML(to destination: LinkDestination) -> String {
		let canonicalURL = destination.absoluteURL(site: site)
		let href = destination.description.escapedForHTML
		return #"<!doctype html><meta charset="utf-8"><meta name="robots" content="noindex"><meta http-equiv="refresh" content="0;url=\#(href)"><link rel="canonical" href="\#(canonicalURL.absoluteString.escapedForHTML)"><title>Redirecting to: \#(href)</title><a href="\#(href)">Redirecting…</a>"#
	}

	/**
	Copies the public files that are missing or changed (by size and modification date). Copies keep the modification date, and APFS clones them, so this is fast.
	*/
	private func copy(_ publicFiles: [(path: RoutePath, source: URL)]) throws {
		for (path, source) in publicFiles {
			let destination = output.appending(path: path.relativePath)

			// The target of a symbolic link, as a copy of the link itself, like `../shared/font.woff2`, would not resolve from the output directory.
			let source = source.resolvingSymlinksInPath()

			guard
				!destination.isFile
					|| FileStamp(source) != FileStamp(destination)
			else {
				continue
			}

			try destination.removeIfExists()
			try destination.deletingLastPathComponent().createDirectory()
			try source.copy(to: destination)
		}
	}

	/**
	Removes the files from earlier builds that are no longer published, and the directories that become empty.
	*/
	private func removeFiles(except publishedFiles: Set<String>) throws {
		// Everything that is not a directory, also broken symbolic links, which are not files.
		// Output symlinks are replaced, so neither writes nor cleanup follow them outside the site.
		let contents = output.contentsRecursively()
		for file in contents where file.isSymbolicLink || (!file.isDirectory && !publishedFiles.contains(file.path(relativeTo: output))) {
			try file.removeIfExists()
		}

		let directories = contents
			.filter { !$0.isSymbolicLink && $0.isDirectory }
			.sorted(using: KeyPathComparator(\.path.count, order: .reverse))

		for directory in directories where directory.isEmptyDirectory {
			try directory.removeIfExists()
		}
	}

	/**
	The output directory is published into and files are removed from it, so it must not contain the project, be inside the public or content directory, or be a checkout.
	*/
	private func checkOutputLocation() throws(PublishingError) {
		// With symlinks resolved, so a link to the project is the project, and in lowercase, as the default disk of macOS ignores case, so the project in other case is the same directory.
		func components(_ url: URL) -> [String] {
			url.resolvingSymlinksInPath().pathComponents.map { $0.lowercased() }
		}

		let outputComponents = components(output)

		guard
			!components(project.root).starts(with: outputComponents),
			!outputComponents.starts(with: components(project.publicDirectory)),
			!outputComponents.starts(with: components(project.contentDirectory))
		else {
			throw PublishingError.unsafeOutput(output)
		}

		// The files of the checkout that did not change are removed, so the history and the other branches would be lost.
		guard !output.appending(path: ".git").exists else {
			throw PublishingError.repositoryOutput(output)
		}
	}

	/**
	Different paths can write the same file, like `/a` and `/a.html`, so collisions are checked on the output files. Case is ignored, as the files of `/About` and `/about` are the same file on a case-insensitive disk, and a name in another Unicode normalization is the same file on APFS. A file in the public directory and a file of a page bundle can also have the same path.

	A static host tries the file at the path itself before `<path>.html`, so a public file there answers the URL of a page.
	*/
	private func checkForCollisions(_ routes: [Route], publicFiles: [RoutePath]) throws(PublishingError) {
		func key(_ path: String) -> String {
			path.precomposedStringWithCanonicalMapping.lowercased()
		}

		// The paths by their key, so the message of a collision has the path as it is written.
		var filesByKey = [String: String]()

		for path in publicFiles {
			guard filesByKey.updateValue(path.relativePath, forKey: key(path.relativePath)) == nil else {
				throw PublishingError.collision(path, file: path.relativePath)
			}
		}

		for route in routes {
			guard filesByKey.updateValue(route.outputFile, forKey: key(route.outputFile)) == nil else {
				throw PublishingError.collision(route.path, file: route.outputFile)
			}
		}

		for route in routes {
			let exactFile = key(route.path.relativePath)

			// A page is written to `<path>.html`, which the host serves after the file at the path. A file route is written at its path, which the loop above already checks.
			guard
				exactFile != key(route.outputFile),
				let file = filesByKey[exactFile]
			else {
				continue
			}

			throw PublishingError.shadowed(route.path, file: file)
		}
	}
}

extension Route {
	fileprivate var isFile: Bool {
		guard case .file = output else {
			return false
		}

		return true
	}
}

/**
The size and modification date of a file, which tell whether a copy is out of date.
*/
private struct FileStamp: Equatable {
	let size: Int?
	let modificationDate: Date?

	init(_ file: URL) {
		let values = try? file.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey])
		self.size = values?.fileSize
		self.modificationDate = values?.contentModificationDate
	}
}

public enum PublishingError: Error, CustomStringConvertible {
	case collision(RoutePath, file: String)
	case shadowed(RoutePath, file: String)
	case renderFailed(RoutePath, any Error)
	case unsafeOutput(URL)
	case repositoryOutput(URL)

	/**
	Reading or writing a file failed, like when the public directory is missing.
	*/
	case fileSystem(any Error)

	public var description: String {
		switch self {
		case .collision(let path, let file):
			"The route \(path) writes \(file), which another route or a public file also writes."
		case .shadowed(let path, let file):
			"The URL \(path) is also served from \(file), so the host may serve that file instead."
		case .renderFailed(let path, let error):
			"Could not render \(path): \(error)"
		case .fileSystem(let error):
			// The localized description of a file error names the file, like `The folder “public” doesn’t exist.`, without the details of the error.
			"Could not read or write a file: \(error.localizedDescription)"
		case .unsafeOutput(let output):
			"Refusing to publish to \(output.path(percentEncoded: false)), because it would delete the project or write into the public or content directory."
		case .repositoryOutput(let output):
			"Refusing to publish to \(output.path(percentEncoded: false)), because it is a git checkout, and the files that are not part of the site would be removed."
		}
	}
}
