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
	Publishes the routes and a sitemap of the pages that are in it.

	Throws if two routes or a route and a public file are written to the same file, or if a route fails to render.
	*/
	public func publish(_ routes: [Route]) async throws(PublishingError) {
		let routes = routes + Sitemap(site: site, pages: routes.filter(\.isInSitemap)).routes
		try checkOutputLocation()
		let publicFiles = try fileSystem { try self.publicFiles() }
		try checkForCollisions(routes, publicFiles: publicFiles)
		try fileSystem { try output.createDirectory() }

		// The old files are removed first. Otherwise, on a case-insensitive disk, a file renamed from `Logo.png` to `logo.png` would be seen as unchanged, and then removed as `Logo.png`.
		try fileSystem { try removeFiles(except: Set(publicFiles + routes.map(\.outputFile))) }
		try fileSystem { try copy(publicFiles) }

		// Rendering some files runs command-line tools, so only a few routes render at a time. Files render first, as they are the slow ones, like the social cards.
		let concurrency = ProcessInfo.processInfo.activeProcessorCount

		do {
			try await withThrowingTaskGroup(of: Void.self) { group in
				for (index, route) in (routes.filter(\.isFile) + routes.filter { !$0.isFile }).enumerated() {
					if index >= concurrency {
						try await group.next()
					}

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
	}

	/**
	Runs a file operation, and wraps its error.
	*/
	private func fileSystem<Value>(_ operation: () throws -> Value) throws(PublishingError) -> Value {
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
		let canonicalURL = switch destination {
		case .path(let path):
			path.absoluteURL(site: site)
		case .url(let url):
			url
		case .fragment:
			preconditionFailure("A redirect cannot go to a fragment of itself.")
		}

		let href = destination.description.escapedForHTML
		return #"<!doctype html><meta charset="utf-8"><meta name="robots" content="noindex"><meta http-equiv="refresh" content="0;url=\#(href)"><link rel="canonical" href="\#(canonicalURL.absoluteString.escapedForHTML)"><title>Redirecting to: \#(href)</title><a href="\#(href)">Redirecting…</a>"#
	}

	/**
	Copies the public files that are missing or changed (by size and modification date). Copies keep the modification date, and APFS clones them, so this is fast.
	*/
	private func copy(_ publicFiles: [String]) throws {
		for file in publicFiles {
			let source = project.publicDirectory.appending(path: file)
			let destination = output.appending(path: file)

			guard
				!destination.isFile
					|| FileStamp(source) != FileStamp(destination)
			else {
				continue
			}

			try destination.removeIfExists()
			try destination.deletingLastPathComponent().createDirectory()
			try FileManager.default.copyItem(at: source, to: destination)
		}
	}

	/**
	Removes the files from earlier builds that are no longer published, and the directories that become empty.
	*/
	private func removeFiles(except publishedFiles: Set<String>) throws {
		for file in try output.filesRecursively() where !publishedFiles.contains(file.path(relativeTo: output)) {
			try file.removeIfExists()
		}

		let directories = (FileManager.default.enumerator(at: output, includingPropertiesForKeys: nil)?.compactMap { $0 as? URL } ?? [])
			.filter(\.isDirectory)
			.sorted(using: KeyPathComparator(\.path.count, order: .reverse))

		for directory in directories where (try? FileManager.default.contentsOfDirectory(atPath: directory.path(percentEncoded: false)))?.isEmpty == true {
			try directory.removeIfExists()
		}
	}

	/**
	The output directory is published into and files are removed from it, so it must not contain the project or be inside the public directory.
	*/
	private func checkOutputLocation() throws(PublishingError) {
		let outputComponents = output.pathComponents

		guard
			!project.root.pathComponents.starts(with: outputComponents),
			!outputComponents.starts(with: project.publicDirectory.pathComponents)
		else {
			throw PublishingError.unsafeOutput(output)
		}
	}

	/**
	Different paths can write the same file, like `/a` and `/a.html`, so collisions are checked on the output files. Case is ignored, as the files of `/About` and `/about` are the same file on a case-insensitive disk.
	*/
	private func checkForCollisions(_ routes: [Route], publicFiles: [String]) throws(PublishingError) {
		var files = Set(publicFiles.map { $0.lowercased() })

		for route in routes where !files.insert(route.outputFile.lowercased()).inserted {
			throw PublishingError.collision(route.path, file: route.outputFile)
		}
	}

	/**
	The files in the public directory, relative to it. `.DS_Store` files are left out.
	*/
	private func publicFiles() throws -> [String] {
		try project.publicDirectory.filesRecursively()
			.filter { $0.lastPathComponent != ".DS_Store" }
			.map { $0.path(relativeTo: project.publicDirectory) }
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
	case renderFailed(RoutePath, any Error)
	case unsafeOutput(URL)

	/**
	Reading or writing a file failed, like when the public directory is missing.
	*/
	case fileSystem(any Error)

	public var description: String {
		switch self {
		case .collision(let path, let file):
			"The route \(path) writes \(file), which another route or a public file also writes."
		case .renderFailed(let path, let error):
			"Could not render \(path): \(error)"
		case .fileSystem(let error):
			"Could not read or write a file: \(error)"
		case .unsafeOutput(let output):
			"Refusing to publish to \(output.path(percentEncoded: false)), because it would delete the project or write into the public directory."
		}
	}
}
