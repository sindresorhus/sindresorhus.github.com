import Foundation

/**
Writes a site to the output directory: the public assets, every route, and the sitemap.

Afterwards, the output directory has exactly these files. Files that did not change are not written again, so a rebuild only touches what changed.
*/
public struct Publisher: Sendable {
	/**
	The site URL without a trailing slash, like `https://sindresorhus.com`.
	*/
	public let site: SiteOrigin
	public let project: Project
	public let output: URL

	public init(site: SiteOrigin, project: Project, output: URL) {
		self.site = site
		self.project = project
		self.output = output.standardizedFileURL
	}

	/**
	Publishes the routes and a sitemap of the pages that are in it. Returns what it published, for the checks of the site (``PublishedSite``).

	Throws if two routes or a route and a public file are written to the same file, if a file answers the URL of a page before the page's own file, if the output directory is unsafe or a checkout, or if a route fails to render.
	*/
	@discardableResult
	public func publish(_ routes: [Route]) async throws(PublishingError) -> PublishedSite {
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
		try checkForCollisions(routes, publicFiles: publicFiles)
		try wrappingFileSystemErrors { try output.createDirectory() }

		// The old files are removed first. Otherwise, on a case-insensitive disk, a file renamed from `Logo.png` to `logo.png` would be seen as unchanged, and then removed as `Logo.png`.
		let publicFilePaths = Set(publicFiles.map(\.outputFile))
		let publishedFiles = publicFilePaths.union(routes.map(\.outputFile))
		try wrappingFileSystemErrors {
			try removeFiles(except: publishedFiles)
			try copy(publicFiles)
		}

		// The routes render in parallel, as many at a time as the cooperative thread pool runs. Files start first, as they are the slow ones, like the social cards.
		do {
			let routesInWriteOrder = routes.filter(\.isFile) + routes.filter { !$0.isFile }
			let routeFiles = try await routesInWriteOrder.concurrentMap { route in
				(route.outputFile, try await write(route))
			}

			return PublishedSite(routeFiles: Dictionary(uniqueKeysWithValues: routeFiles), publicFiles: publicFilePaths)
		} catch let error as PublishingError {
			throw error
		} catch {
			throw .fileSystem(error)
		}
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

	/**
	Writes the file of the route, when it changed, and returns its content.
	*/
	private func write(_ route: Route) async throws -> Data {
		let data: Data

		do {
			data = try await route.output.render(site: site)
		} catch {
			throw PublishingError.renderFailed(route.path, error)
		}

		let file = route.outputFile.fileURL(in: output)

		guard (try? Data(contentsOf: file)) != data else {
			return data
		}

		// Atomic, so the preview server never serves a half-written page during a rebuild.
		try file.deletingLastPathComponent().createDirectory()
		try data.write(to: file, options: .atomic)
		return data
	}

	/**
	Copies the public files that are missing or changed (by size and modification date). Copies keep the modification date, and APFS clones them, so this is fast.
	*/
	private func copy(_ publicFiles: [PublishedAsset]) throws {
		for asset in publicFiles {
			let destination = asset.outputFile.fileURL(in: output)

			// The target of a symbolic link, as a copy of the link itself, like `../shared/font.woff2`, would not resolve from the output directory.
			let source = asset.source.resolvingSymlinksInPath()

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
	private func removeFiles(except publishedFiles: Set<PublishedFilePath>) throws {
		// Everything that is not a directory, also broken symbolic links, which are not files.
		// Output symlinks are replaced, so neither writes nor cleanup follow them outside the site.
		let contents = output.contentsRecursively()
		for file in contents where file.isSymbolicLink || (!file.isDirectory && !publishedFiles.contains(PublishedFilePath(file.path(relativeTo: output)))) {
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
	private func checkForCollisions(_ routes: [Route], publicFiles: [PublishedAsset]) throws(PublishingError) {
		func key(_ path: String) -> String {
			path.precomposedStringWithCanonicalMapping.lowercased()
		}

		// The files by their key, so the message of a collision has the path as it is written, and where each file comes from.
		var filesByKey = [String: (file: PublishedFilePath, source: Route.Source)]()

		func add(_ file: PublishedFilePath, source: Route.Source) throws(PublishingError) {
			if let other = filesByKey.updateValue((file, source), forKey: key(file.description)) {
				throw PublishingError.collision(file: file, firstSource: other.source, secondSource: source, root: project.root)
			}
		}

		for asset in publicFiles {
			try add(asset.outputFile, source: Route.Source(role: "the file", location: .file(asset.source)))
		}

		func source(of route: Route) -> Route.Source {
			route.source ?? Route.Source(role: "the route", location: .page(route.path))
		}

		for route in routes {
			try add(route.outputFile, source: source(of: route))
		}

		for route in routes {
			let exactFile = key(route.path.relativePath)

			// A page is written to `<path>.html`, which the host serves after the file at the path. A file route is written at its path, which the loop above already checks.
			guard
				exactFile != key(route.outputFile.description),
				let other = filesByKey[exactFile]
			else {
				continue
			}

			throw PublishingError.shadowed(route.path, source: source(of: route), file: other.file, fileSource: other.source, root: project.root)
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
struct FileStamp: Equatable, Sendable {
	let size: Int?
	let modificationDate: Date?

	/**
	From resource values that the caller already read, so a scan of many files reads them once.
	*/
	init(_ values: URLResourceValues?) {
		self.size = values?.fileSize
		self.modificationDate = values?.contentModificationDate
	}

	init(_ file: URL) {
		self.init(try? file.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey]))
	}
}

/**
What ``Publisher/publish(_:)`` published, so the checks of the site, like the links, check what the build wrote, without reading the output directory again.
*/
public struct PublishedSite: Sendable {
	/**
	Every published file, relative to the output directory, like `apps/dato.html`: the files of the routes, and the public files.
	*/
	public let files: Set<PublishedFilePath>

	/**
	The content of the file of each route, by the file, like `apps/dato.html`. The public files are not in it, as they are copied as they are, so a check reads them from the project.
	*/
	public let routeFiles: [PublishedFilePath: Data]

	/**
	- Parameter publicFiles: The published public files, and the files of page bundles, relative to the output directory, like `robots.txt`.
	*/
	public init(routeFiles: [PublishedFilePath: Data], publicFiles: Set<PublishedFilePath>) {
		self.files = publicFiles.union(routeFiles.keys)
		self.routeFiles = routeFiles
	}

	/**
	The text of the file of the route, like the HTML of a page, or `nil` when it was not published.
	*/
	public func text(of route: Route) -> String? {
		routeFiles[route.outputFile].map { String(decoding: $0, as: UTF8.self) }
	}
}

public enum PublishingError: Error, CustomStringConvertible {
	/**
	Two sources write the same file, like a redirect and a page, by where they come from (``Route/source``).
	*/
	case collision(file: PublishedFilePath, firstSource: Route.Source, secondSource: Route.Source, root: URL)

	/**
	The host serves a file at the path of a route, like `dato.html` for a redirect from `/dato.html`, instead of the route, by where the route and the file come from (``Route/source``).
	*/
	case shadowed(RoutePath, source: Route.Source, file: PublishedFilePath, fileSource: Route.Source, root: URL)
	case renderFailed(RoutePath, any Error)
	case unsafeOutput(URL)
	case repositoryOutput(URL)

	/**
	Reading or writing a file failed, like when the public directory is missing.
	*/
	case fileSystem(any Error)

	public var description: String {
		switch self {
		case .collision(let file, let firstSource, let secondSource, let root):
			"Two sources write \(file): \([firstSource, secondSource].map { $0.description(relativeTo: root) }.formatted(.list(type: .and).locale(.site))). Change one of them."
		case .shadowed(let path, let source, let file, let fileSource, let root):
			"The URL \(path) of \(source.description(relativeTo: root)) is also served from \(file), \(fileSource.description(relativeTo: root)), so the host may serve that file instead. Change one of them."
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
