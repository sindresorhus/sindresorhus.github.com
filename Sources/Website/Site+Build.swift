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

		// Markdown renders while the content loads, so the hashes are set before it, for the URLs in it, like of the icons of the copy button of a code block.
		let hashes = try contentHashes(project: project)

		let site = try await measure("Load content and data") {
			try await RoutePath.$contentHashes.withValue(hashes) {
				try await Site(content: SiteContent.load(from: project, externalData: externalData))
			}
		}

		let routes = site.routes(project: project, includesGallery: includesGallery)

		let publishedFiles = try await measure("Render and write \(routes.count) routes") {
			try await RoutePath.$contentHashes.withValue(hashes) {
				try await Publisher(site: url, project: project, output: output).publish(routes)
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
	The content hashes of the files that every page loads: the stylesheet, the icons, and the scripts. Their URLs include the hash, so browsers and Cloudflare can cache them for a year, and still get a changed file right after a deploy.

	The scripts of the elements import their base class with its hash, so they are hashed after the other scripts. An inline script is in the page, so it has no hash, but its script is generated here too, so a mistake in it fails the build.
	*/
	static func contentHashes(project: Project) throws -> [RoutePath: String] {
		var contents = [
			Stylesheet.sitePath: Stylesheet.site.css,
			Icon.spritePath: Icon.sprite,
		]

		for (path, source) in try project.publicFiles() where source.pathExtension == "js" {
			contents[RoutePath("/" + path)] = try String(contentsOf: source, encoding: .utf8)
		}

		var hashes = contents.mapValues { String($0.stableHash, radix: 16) }

		try RoutePath.$contentHashes.withValue(hashes) {
			for element in scriptedElements {
				let script = try element.generatedScript()

				if !element.script.isInline {
					hashes[element.scriptPath] = String(script.stableHash, radix: 16)
				}
			}
		}

		return hashes
	}
}

extension ScriptedElement {
	/**
	The script that the build writes for the element, which imports its base class from `public/scripts` with the content hash of the module.
	*/
	static func generatedScript() throws -> String {
		try generatedScript(baseClasses: Site.elementBaseClasses.mapValues(\.versioned))
	}
}

extension Site {
	/**
	The base classes that the scripts of elements extend, and their modules. `ScriptedElement` has the helpers of every element, and `GeoCitiesElement` adds the helpers of the 1999 page.
	*/
	static let elementBaseClasses: [String: RoutePath] = [
		"ScriptedElement": "/scripts/scripted-element.js",
		"GeoCitiesElement": "/scripts/geocities-element.js",
	]
}

extension RoutePath {
	/**
	The content hashes from ``Site/contentHashes(project:)``, set while the site is published.
	*/
	@TaskLocal static var contentHashes = [RoutePath: String]()

	/**
	The path with the content hash of its file, like `/assets/site.css?v=1a2b3c4d`, or the path alone when it has no hash.

	The hash changes with the content, so a cached file is never used for new pages. A script that a script imports, like `nebula.js`, has no hash, so it is cached like other files.
	*/
	var versioned: String {
		Self.contentHashes[self].map { "\(self)?v=\($0)" } ?? description
	}
}
