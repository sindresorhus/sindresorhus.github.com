import Foundation
import SiteKit

extension Site {
	/**
	What a build did: the published routes, the problems, and how long each step took.
	*/
	public struct BuildReport: Sendable {
		public struct Step: Sendable {
			public let name: String
			public let duration: Duration
		}

		public let routeCount: Int

		/**
		Problems that do not fail the build, like an App Store request that failed.
		*/
		public let warnings: [Warning]

		/**
		The broken internal links, each with where it is written, like `content/apps/dato/index.md:12: /missing`, or the page when it is not in the Markdown of the page. Empty when every link works.
		*/
		public let brokenLinks: [String]

		/**
		The steps of the build, in order, like loading the content.
		*/
		public let steps: [Step]

		/**
		The content the site was built from, like for `website check`.
		*/
		public let content: SiteContent
	}

	/**
	Loads the content and data, publishes every route to the output directory, and checks the internal links.

	Throws for content mistakes and publishing errors. Broken links do not throw, as the site is published, so they are in the report.

	- Parameter includesGallery: Publishes the component gallery too, for the preview server.
	- Parameter onPublished: Called after the files are written, before the links are checked, like for reloading the open pages.
	*/
	public static func build(project: Project, output: URL, externalData: ExternalData, includesGallery: Bool = false, onPublished: @Sendable () -> Void = {}) async throws -> BuildReport {
		var steps = [BuildReport.Step]()

		func measure<Value>(_ name: String, _ operation: () async throws -> Value) async rethrows -> Value {
			let clock = ContinuousClock()
			let start = clock.now
			let value = try await operation()
			steps.append(BuildReport.Step(name: name, duration: clock.now - start))
			return value
		}

		let hashes = try contentHashes(project: project)
		let importedScripts = try importedScripts(project: project)

		let site = try await measure("Load content and data") {
			try await Site(content: SiteContent.load(from: project, externalData: externalData))
		}

		let routes = site.routes(project: project, includesGallery: includesGallery)

		let publishedFiles = try await measure("Render and write \(routes.count) routes") {
			try await RoutePath.$contentHashes.withValue(hashes) {
				try await RoutePath.$importedScripts.withValue(importedScripts) {
					try await Publisher(site: url, project: project, output: output).publish(routes)
				}
			}
		}

		onPublished()

		let brokenLinks = try await measure("Check links") {
			try await LinkValidator(site: url, output: output).brokenLinks(in: routes, files: publishedFiles)
		}

		return BuildReport(
			routeCount: routes.count,
			warnings: site.content.warnings,
			brokenLinks: brokenLinks.flatMap { link in
				let locations = site.content.sourceLocations(ofLink: link.link, onPage: link.page)
				return locations.isEmpty ? [link.description] : locations.map(link.description(at:))
			},
			steps: steps,
			content: site.content
		)
	}
}

extension Site {
	/**
	The content hashes of the scripts that the pages load: the scripts in `public`, and the scripts of the elements. Their URLs include the hash, so browsers and Cloudflare can cache them for a year, and still get a changed file right after a deploy. The stylesheet and the icons are values, so they have their hashes without the project (``RoutePath/versioned(content:)``).

	A script imports another one without the hash, like `/scripts/geocities-element.js`, and the import map of each page adds it (``RoutePath/importMap``), so the hash of a script is the hash of its own text.
	*/
	static func contentHashes(project: Project) throws -> [RoutePath: String] {
		var hashes = [RoutePath: String]()

		for (path, source) in try scripts(project: project) {
			hashes[path] = try String(contentsOf: source, encoding: .utf8).contentHash
		}

		return hashes
	}

	/**
	The scripts that other scripts import, like `/scripts/geocities-element.js`: the imports at the start of a line, like `import X from '/scripts/x.js';`, and the dynamic imports, like `import('./nebula.js')`. A relative import is resolved from the path of the script that imports it. The import map of the pages has only these (``RoutePath/importMap``).
	*/
	static func importedScripts(project: Project) throws -> Set<RoutePath> {
		var imported = Set<RoutePath>()

		for (path, source) in try scripts(project: project) {
			let text = try String(contentsOf: source, encoding: .utf8)

			for match in text.matches(of: /^import\b[^;'\n]*?(?:\bfrom\s*)?'([^']+)'|\bimport\(\s*'([^']+)'\s*\)/.anchorsMatchLineEndings()) {
				let specifier = String(match.1 ?? match.2 ?? "")

				if let resolved = URL(string: specifier, relativeTo: URL(string: path.description, relativeTo: url))?.path() {
					imported.insert(RoutePath(resolved))
				}
			}
		}

		return imported
	}

	/**
	The scripts that the build publishes: the scripts in `public`, and the scripts of the elements.
	*/
	private static func scripts(project: Project) throws -> [(path: RoutePath, source: URL)] {
		let publicScripts = try project.publicFiles()
			.filter { $0.source.pathExtension == "js" }
			.map { (path: RoutePath("/" + $0.path), source: $0.source) }

		return publicScripts + project.elementScripts()
	}
}

extension RoutePath {
	/**
	The content hashes of the scripts from ``Site/contentHashes(project:)``, set while the site is published.
	*/
	@TaskLocal static var contentHashes = [RoutePath: String]()

	/**
	The path of a script with the content hash of its file, like `/scripts/site.js?v=1a2b3c4d`, or the path alone when it has no hash.

	The hash changes with the content, so a cached file is never used for new pages. A script that a script imports, like `nebula.js`, gets the hash from the import map of the page (``importMap``).
	*/
	var versioned: String {
		Self.contentHashes[self].map { "\(self)?v=\($0)" } ?? description
	}

	/**
	The scripts that other scripts import, from ``Site/importedScripts(project:)``, set while the site is published.
	*/
	@TaskLocal static var importedScripts = Set<RoutePath>()

	/**
	The import map of the pages, as JSON: each script that another script imports (``importedScripts``) to its path with the content hash, like `/scripts/geocities-element.js` to `/scripts/geocities-element.js?v=1a2b3c4d`, so an import of it, also a relative one, like `./nebula.js`, gets the file with the hash. `nil` without hashes or imports.

	Only the imported scripts, as the map is in every page.
	*/
	static var importMap: String? {
		let imports = importedScripts
			.filter { contentHashes[$0] != nil }
			.map { ($0.description, $0.versioned) }

		guard !imports.isEmpty else {
			return nil
		}

		return JSONEncoder.pageJSON(["imports": Dictionary(uniqueKeysWithValues: imports)])
	}

	/**
	The path with the hash of the content of its file, like `/assets/site.css?v=1a2b3c4d`, for a file that is a value, like the stylesheet. The hash is known without the project, so the URL is right wherever it is used, also in Markdown, which renders while the content loads.
	*/
	func versioned(content: String) -> String {
		"\(self)?v=\(content.contentHash)"
	}
}

extension String {
	/**
	The hash in the URL of a file with this content, like `1a2b3c4d`.
	*/
	fileprivate var contentHash: String {
		String(stableHash, radix: 16)
	}
}
