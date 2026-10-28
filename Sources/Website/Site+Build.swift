import Foundation
import SiteKit

extension Site {
	/**
	What a build did: the published routes, the problems, and how long each step took.
	*/
	public struct BuildReport: Sendable {
		/**
		The published routes, like for the checks of `website check` on the published pages.
		*/
		public let routes: [Route]

		/**
		What the build published, like for the checks of `website check` on the published pages.
		*/
		public let published: PublishedSite

		/**
		A broken internal link with where it is written (``SiteContent/sourceLocations(ofLink:onPage:)``).
		*/
		public struct BrokenLink: Hashable, Sendable, CustomStringConvertible {
			public let link: LinkValidator.BrokenLink
			public let location: SourceLocation

			/**
			The content file of the draft that the link goes to, relative to the project, like `content/guides/keep-mac-awake.md`, as a draft has no page (``SiteContent/draftFile(ofLink:)``).
			*/
			let draftFile: String?

			/**
			The identity of an authored diagnostic, independent of wording and the pages that repeat shared content.
			*/
			struct Identity: Hashable {
				let location: SourceLocation
				let problem: LinkValidator.BrokenLink.Problem
				let draftFile: String?
			}

			/**
			The values that distinguish this authored problem from other diagnostics.
			*/
			var identity: Identity {
				Identity(location: location, problem: link.problem, draftFile: draftFile)
			}

			/**
			The link and the problem after where it is, like `content/apps/dato/index.md:12: /missing`, or that it goes to a draft, as its file exists, so the author would otherwise look for a wrong path.
			*/
			public var description: String {
				guard let draftFile else {
					return link.description(at: location)
				}

				return "\(location): \(link.link) goes to `\(draftFile)`, which is a draft (`isDraft: true`), so it is not published."
			}
		}

		/**
		The broken internal links, each with where it is written, like `content/apps/dato/index.md:12: /missing`, or the content file of the page when it is not in the Markdown of the page, like a link in raw HTML. Empty when every link works.
		*/
		public let brokenLinks: [BrokenLink]

		/**
		How long each step of the build took, like loading the content.
		*/
		public let steps: StepTimes

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
		var steps = StepTimes()

		// Read while the content loads, as the scripts are about 5 MB.
		async let loadingScripts = Scripts(project: project)

		let site = try await steps.measure("Load content and data") {
			try await Site(content: SiteContent.load(from: project, externalData: externalData))
		}

		let routes = site.routes(includesGallery: includesGallery)
		let scripts = try await loadingScripts

		let published = try await steps.measure("Render and write \(routes.count) routes") {
			try await Scripts.$published.withValue(scripts) {
				try await Publisher(site: origin, project: project, output: output).publish(routes)
			}
		}

		onPublished()

		let brokenLinks = await steps.measure("Check links") {
			await LinkValidator(site: origin).brokenLinks(in: routes, published: published)
		}

		return BuildReport(
			routes: routes,
			published: published,
			brokenLinks: brokenLinks
				.flatMap { link in
					let draftFile: String?
					if case .missingFile(let destination) = link.problem {
						draftFile = site.content.draftFile(ofLink: destination)?.path(relativeTo: project.root)
					} else {
						draftFile = nil
					}

					let locations = link.destination.map { site.content.sourceLocations(ofLink: $0, onPage: link.page) } ?? [site.content.sourceLocation(ofPage: link.page)]
					return locations.map { BuildReport.BrokenLink(link: link, location: $0, draftFile: draftFile) }
				}
				// A link in a shared answer is on each page that shows the answer, but it is written once, so it is reported once.
				.uniqued(by: \.identity),
			steps: steps,
			content: site.content
		)
	}
}

/**
How long each step of a task took, in order, like the steps of the build and the checks of `website check`, which `--verbose` prints.
*/
public struct StepTimes: Sendable, CustomStringConvertible {
	public struct Step: Sendable {
		public let name: String
		public let duration: Duration
	}

	public private(set) var steps = [Step]()

	public init() {}

	/**
	The steps of tasks that ran at the same time, like the checks of `website check`, in the order of the tasks.
	*/
	init(_ steps: [Step]) {
		self.steps = steps
	}

	/**
	Runs the operation and adds how long it took as a step with the name.
	*/
	mutating func measure<Value>(_ name: String, _ operation: () async throws -> Value) async rethrows -> Value {
		let start = ContinuousClock.now
		defer {
			steps.append(Step(name: name, duration: .now - start))
		}

		return try await operation()
	}

	/**
	Runs the operation and adds how long it took as a step with the name, for synchronous work, like the checks of `website check`.
	*/
	mutating func measure<Value>(_ name: String, _ operation: () throws -> Value) rethrows -> Value {
		let start = ContinuousClock.now
		defer {
			steps.append(Step(name: name, duration: .now - start))
		}

		return try operation()
	}

	/**
	A line for each step, like `Check links: 1s 234ms`.
	*/
	public var description: String {
		steps
			.map { "\($0.name): \($0.duration.formatted(.units(allowed: [.seconds, .milliseconds], width: .narrow).locale(.site)))" }
			.joined(separator: "\n")
	}
}

extension Site {
	/**
	The scripts that the build publishes, the scripts in `public` and the scripts of the elements, read once for both of these:

	- The content hashes of the scripts that the pages load. Their URLs include the hash, so browsers and Cloudflare can cache them for a year, and still get a changed file right after a deploy. The stylesheet and the icons are values, so they have their hashes without the project (``RoutePath/versioned(content:)``). A script imports another one without the hash, like `/scripts/geocities-element.js`, and the import map of each page adds it (``importMap(loading:)``), so the hash of a script is the hash of its own text.
	- The scripts that other scripts import, like `/scripts/geocities-element.js`: the imports at the start of a line, like `import X from '/scripts/x.js';`, and the dynamic imports, like `import('./nebula.js')`, each on one line. A relative import is resolved from the path of the script that imports it. The import map of a page has only the ones that its scripts import (``importMap(loading:)``), and the page preloads the static ones (``modulePreloads(loading:)``).
	*/
	struct Scripts {
		/**
		The scripts of the site that is being published. Empty outside a build.
		*/
		@TaskLocal static var published = Self()

		/**
		One snapshot per published script, so its hash, imports, and retained text always describe the same read.
		*/
		private(set) var records = [RoutePath: Script]()

		/**
		The facts collected from one script file during a build.
		*/
		struct Script {
			let contentHash: String

			/**
			The text of each script of an element, which the build publishes from here (``elementScript(at:)``), so the file is the text that its hash is of, also when the script is saved during a build of `website serve`. The scripts in `public` are published from their files.
			*/
			let elementText: String?

			/**
			The scripts that each script imports, like `/scripts/geocities.js` to `/scripts/geocities-element.js`.
			*/
			let imports: Set<Import>
		}

		/**
		The import map of a page that loads the scripts, as JSON: each script that they import, also through another imported script, to its path with the content hash, like `/scripts/geocities-element.js` to `/scripts/geocities-element.js?v=1a2b3c4d`, so an import of it, also a relative one, like `./nebula.js`, gets the file with the hash. `nil` when they import nothing that has a hash.

		Only the scripts of the page, as the map is in the page, and most pages import none of the scripts of the 1999 page.
		*/
		func importMap(loading scripts: [RoutePath]) -> String? {
			// Import maps use strings on the wire; keep destinations typed until this JSON boundary.
			let entries = versionedImports(of: scripts, kinds: [.static, .dynamic]).map { ($0.path.description, $0.versioned.description) }

			guard !entries.isEmpty else {
				return nil
			}

			return JSONEncoder.pageJSON(ImportMap(imports: Dictionary(uniqueKeysWithValues: entries)))
		}

		/**
		The import-map envelope this site emits. An empty page omits the map entirely.
		*/
		struct ImportMap: Codable {
			let imports: [String: String]
		}

		/**
		The paths with the hash of the scripts that a page that loads the scripts must preload, like `/scripts/dom.js?v=1a2b3c4d`: the static imports, also through another static import, as the browser otherwise only finds them when the script that imports them has arrived. Not the dynamic imports, like `import('./nebula.js')`, which a script only loads when it needs them. Sorted, so the page does not change between builds.
		*/
		func modulePreloads(loading scripts: [RoutePath]) -> [LinkDestination] {
			versionedImports(of: scripts, kinds: [.static]).map(\.versioned).sorted(using: KeyPathComparator(\.description))
		}

		/**
		The scripts of these kinds that the scripts import, also through another import of these kinds, that have a hash, with the path with the hash.
		*/
		private func versionedImports(of scripts: [RoutePath], kinds: Set<Import.Kind>) -> [(path: RoutePath, versioned: LinkDestination)] {
			var needed = Set<RoutePath>()
			var pending = scripts

			// Visit each dependency once, including cycles; preloads follow only static edges.
			while let script = pending.popLast() {
				for imported in records[script]?.imports ?? [] where kinds.contains(imported.kind) && needed.insert(imported.path).inserted {
					pending.append(imported.path)
				}
			}

			return needed.compactMap { path in
				records[path].map { (path, path.versioned(hash: $0.contentHash)) }
			}
		}

		/**
		The script of an element, as it was read for its hash. It throws outside a build (``published``), which has no scripts.
		*/
		func elementScript(at path: RoutePath) throws -> Data {
			guard let text = records[path]?.elementText else {
				throw CocoaError(.fileReadNoSuchFile, userInfo: [NSFilePathErrorKey: path.description])
			}

			return Data(text.utf8)
		}

		/**
		A script that a script imports.
		*/
		struct Import: Hashable {
			enum Kind {
				/**
				An import at the start of the script, like `import X from '/scripts/x.js';`, which the browser loads before it runs the script.
				*/
				case `static`

				/**
				An import while the script runs, like `import('./nebula.js')`.
				*/
				case dynamic
			}

			let path: RoutePath
			let kind: Kind
		}
	}
}

extension Site.Scripts {
	nonisolated(unsafe) private static let importPattern = /^import\b[^;'\n]*?(?:\bfrom\s*)?'([^']+)'|\bimport\(\s*'([^']+)'\s*\)/

	init(project: Project) throws {
		let publicScripts = try project.publicFiles()
			.filter { $0.source.pathExtension == "js" }

		let elementScriptFiles = project.elementScripts()
		let elementScriptPaths = Set(elementScriptFiles.map(\.path))

		for asset in publicScripts + elementScriptFiles {
			let path = asset.path
			let text = try String(contentsOf: asset.source, encoding: .utf8)
			var imports = Set<Import>()

			// Only the lines with an import, as the word boundaries make the pattern slow on the whole text (about 1 s for all the scripts).
			for line in text.split(whereSeparator: \.isNewline) where line.contains("import") {
				for match in line.matches(of: Self.importPattern) {
					let (specifier, kind): (Substring, Import.Kind) = if let specifier = match.1 {
						(specifier, .static)
					} else {
						(match.2 ?? "", .dynamic)
					}

					// An import of a script of another site, or of a `data:` URL, can resolve to something that is not a path of the site, like the empty path of `https://example.com`.
					if
						let resolved = URL(string: String(specifier), relativeTo: URL(string: path.description, relativeTo: Site.url))?.path(),
						let importedPath = try? RoutePath(validating: resolved)
					{
						imports.insert(Import(path: importedPath, kind: kind))
					}
				}
			}

			records[path] = Script(contentHash: text.contentHash, elementText: elementScriptPaths.contains(path) ? text : nil, imports: imports)
		}
	}
}

extension RoutePath {
	/**
	The path of a script with the content hash of its file (``Site/Scripts/published``), like `/scripts/site.js?v=1a2b3c4d`, or the path alone when it has no hash.

	The hash changes with the content, so a cached file is never used for new pages. A script that a script imports, like `nebula.js`, gets the hash from the import map of the page (``Site/Scripts/importMap(loading:)``).
	*/
	var versioned: LinkDestination {
		Site.Scripts.published.records[self].map { versioned(hash: $0.contentHash) } ?? .path(self)
	}

	/**
	The path with the hash of the content of its file, like `/assets/site.css?v=1a2b3c4d`, for a file that is a value, like the stylesheet. The hash is known without the project, so the URL is right wherever it is used, also in Markdown, which renders while the content loads.
	*/
	func versioned(content: String) -> LinkDestination {
		versioned(hash: content.contentHash)
	}

	/**
	Adds the version through the common query encoder rather than assembling URL text.
	*/
	fileprivate func versioned(hash: String) -> LinkDestination {
		.path(self, query: [URLQueryItem(name: "v", value: hash)])
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
