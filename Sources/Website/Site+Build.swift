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

		/**
		Problems that do not fail the build, like an App Store request that failed.
		*/
		public var warnings: [Warning] {
			content.warnings
		}
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

		// Read while the content loads, as the scripts are about 5 MB.
		async let loadingScripts = Scripts(project: project)

		let site = try await measure("Load content and data") {
			try await Site(content: SiteContent.load(from: project, externalData: externalData))
		}

		let routes = site.routes(includesGallery: includesGallery)
		let scripts = try await loadingScripts

		let publishedFiles = try await measure("Render and write \(routes.count) routes") {
			try await Scripts.$published.withValue(scripts) {
				try await Publisher(site: url, project: project, output: output).publish(routes)
			}
		}

		onPublished()

		let brokenLinks = try await measure("Check links") {
			try await LinkValidator(site: url, output: output).brokenLinks(in: routes, files: publishedFiles)
		}

		return BuildReport(
			routeCount: routes.count,
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
	The scripts that the build publishes, the scripts in `public` and the scripts of the elements, read once for both of these:

	- The content hashes of the scripts that the pages load. Their URLs include the hash, so browsers and Cloudflare can cache them for a year, and still get a changed file right after a deploy. The stylesheet and the icons are values, so they have their hashes without the project (``RoutePath/versioned(content:)``). A script imports another one without the hash, like `/scripts/geocities-element.js`, and the import map of each page adds it (``importMap``), so the hash of a script is the hash of its own text.
	- The scripts that other scripts import, like `/scripts/geocities-element.js`: the imports at the start of a line, like `import X from '/scripts/x.js';`, and the dynamic imports, like `import('./nebula.js')`, each on one line. A relative import is resolved from the path of the script that imports it. The import map of the pages has only these (``importMap``).
	*/
	struct Scripts: Sendable {
		/**
		The scripts of the site that is being published. Empty outside a build.
		*/
		@TaskLocal static var published = Self()

		var contentHashes = [RoutePath: String]()
		var importedScripts = Set<RoutePath>()

		/**
		The import map of the pages, as JSON: each script that another script imports (``importedScripts``) to its path with the content hash, like `/scripts/geocities-element.js` to `/scripts/geocities-element.js?v=1a2b3c4d`, so an import of it, also a relative one, like `./nebula.js`, gets the file with the hash. `nil` without hashes or imports.

		Only the imported scripts, as the map is in every page.
		*/
		var importMap: String? {
			let imports = importedScripts.compactMap { path in
				contentHashes[path].map { (path.description, path.versioned(hash: $0)) }
			}

			guard !imports.isEmpty else {
				return nil
			}

			return JSONEncoder.pageJSON(["imports": Dictionary(uniqueKeysWithValues: imports)])
		}
	}
}

extension Site.Scripts {
	nonisolated(unsafe) private static let importPattern = /^import\b[^;'\n]*?(?:\bfrom\s*)?'([^']+)'|\bimport\(\s*'([^']+)'\s*\)/

	init(project: Project) throws {
		let publicScripts = try project.publicFiles()
			.filter { $0.source.pathExtension == "js" }

		for (path, source) in publicScripts + project.elementScripts() {
			let text = try String(contentsOf: source, encoding: .utf8)
			contentHashes[path] = text.contentHash

			// Only the lines with an import, as the word boundaries make the pattern slow on the whole text (about 1 s for all the scripts).
			for line in text.split(whereSeparator: \.isNewline) where line.contains("import") {
				for match in line.matches(of: Self.importPattern) {
					let specifier = String(match.1 ?? match.2 ?? "")

					// An import of a script of another site, or of a `data:` URL, can resolve to something that is not a path of the site, like the empty path of `https://example.com`.
					if
						let resolved = URL(string: specifier, relativeTo: URL(string: path.description, relativeTo: Site.url))?.path(),
						let importedPath = try? RoutePath(validating: resolved)
					{
						importedScripts.insert(importedPath)
					}
				}
			}
		}
	}
}

extension RoutePath {
	/**
	The path of a script with the content hash of its file (``Site/Scripts/published``), like `/scripts/site.js?v=1a2b3c4d`, or the path alone when it has no hash.

	The hash changes with the content, so a cached file is never used for new pages. A script that a script imports, like `nebula.js`, gets the hash from the import map of the page (``Site/Scripts/importMap``).
	*/
	var versioned: String {
		Site.Scripts.published.contentHashes[self].map(versioned(hash:)) ?? description
	}

	/**
	The path with the hash of the content of its file, like `/assets/site.css?v=1a2b3c4d`, for a file that is a value, like the stylesheet. The hash is known without the project, so the URL is right wherever it is used, also in Markdown, which renders while the content loads.
	*/
	func versioned(content: String) -> String {
		versioned(hash: content.contentHash)
	}

	fileprivate func versioned(hash: String) -> String {
		"\(self)?v=\(hash)"
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
