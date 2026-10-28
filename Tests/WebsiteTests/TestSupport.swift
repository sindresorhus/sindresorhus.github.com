import Foundation
@testable import SiteKit
import SwiftParser
import SwiftSyntax
import TestSupport
import Testing
@testable import Website

extension Project {
	/**
	The project of the website, with the real content.
	*/
	static let website = Project.site(root: URL(filePath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent())

	/**
	A project in a directory that does not exist, for content that a test makes without files.
	*/
	static let empty = Project.site(root: URL.temporaryDirectory.appending(path: "website-tests-empty-project"))
}

/**
A Swift source file of the site (`Sources/Website`), for the tests that check the sources.
*/
struct SwiftSourceFile: Sendable {
	/**
	The directory of the Swift sources of the site.
	*/
	static let directory = Project.website.root.appending(path: "Sources/Website")

	/**
	Every Swift file of the site, in the order of their paths. They are read and parsed once, in parallel, and the tests share them, as parsing is slow.
	*/
	static let all = Task {
		let files = try directory.filesRecursively()
			.filter { $0.pathExtension == "swift" }
			.sorted(using: KeyPathComparator(\.path))

		return try await files.concurrentMap { url in
			let text = try String(contentsOf: url, encoding: .utf8)
			return Self(url: url, text: text, syntax: Parser.parse(source: text))
		}
	}

	let url: URL
	let text: String

	/**
	The syntax tree, for the tests that find declarations and calls (``SwiftSyntax/SourceFileSyntax/enums(conformingTo:)``, ``SwiftSyntax/SourceFileSyntax/typeNames(conformingTo:)``, and ``SwiftSyntax/SourceFileSyntax/calls(named:)``), so the layout of the source does not matter, and a code example in a comment is not code.
	*/
	let syntax: SourceFileSyntax
}

extension SiteContent {
	/**
	The real content of the website, without the network: there is no App Store or GitHub data. The build date is fixed, so the tests do not change from day to day.

	It is loaded once, and the tests share it, as loading the content is slow. The content is immutable, so the tests cannot change it for each other. A test that checks loading itself loads its own.
	*/
	static var website: Self {
		get async throws {
			try await loadingWebsite.value
		}
	}

	private static let loadingWebsite = Task {
		try await load(from: .website, externalData: .none, buildDate: Date(timeIntervalSince1970: 1_790_000_000))
	}

	/**
	The text of the content warnings, with the paths relative to the project (``SiteKit/SourceLocation/description(relativeTo:)``), like in a build, which runs in the project root. A file outside the project keeps its full path, so the test shows it.

	- Parameter kinds: Only the warnings of these kinds. Default: all the warnings.
	- Parameter published: The published site. Default: nothing.
	*/
	func warningTexts(of kinds: Warning.Kind..., published: PublishedSite = PublishedSite(routeFiles: [:], publicFiles: [])) async -> [String] {
		await warnings(published: published, routes: Site(content: self).routes())
			.warnings
			.filter { kinds.isEmpty || kinds.contains($0.kind) }
			.map { warning in
				warning.location.map { "\($0.description(relativeTo: project.root)): \(warning.message)" } ?? warning.message
			}
	}
}

extension PublishedSite {
	/**
	A published site with the text of the files of the routes, by their file, like `apps.html`, and the published public files.
	*/
	init(routeTexts: [PublishedFilePath: String], publicFiles: Set<PublishedFilePath> = []) {
		self.init(routeFiles: routeTexts.mapValues { Data($0.utf8) }, publicFiles: publicFiles)
	}
}

/**
A page of the site with its HTML, and the custom elements (``ScriptedElement``) that it shows.
*/
struct RenderedPage: CustomTestStringConvertible {
	let route: Route
	let html: String
	let elements: [any ScriptedElement.Type]

	var testDescription: String {
		route.path.description
	}
}

extension RenderedPage {
	/**
	Every page of the site from the real content (``SiteContent/website``), with the component gallery, which shows the components that the pages only show with data.

	They are rendered once, in parallel like in a build, and the tests share them, as rendering every page is slow. Each page renders in a collector of its own, like in a build, so a test can check the scripts against the elements that the pages show, as types, without a list of the elements.
	*/
	static var website: [Self] {
		get async throws {
			try await renderingWebsite.value
		}
	}

	private static let renderingWebsite = Task {
		let pages = try await Site(content: .website).routes(includesGallery: true)
			.compactMap { route -> (route: Route, render: @Sendable () throws -> String)? in
				guard case .page(_, let render) = route.output else {
					return nil
				}

				return (route, render)
			}

		return try await pages.concurrentMap { page in
			let resources = PageResources(sharedStylesheet: .site)
			let html = try resources.collect {
				try page.render()
			}

			return Self(route: page.route, html: html, elements: resources.elements)
		}
	}
}

extension ContributionYear.Totals {
	/**
	No contributions by kind, for a test that only needs the calendar of a year.
	*/
	static let zero = Self(
		commitCount: 0,
		pullRequestCount: 0,
		reviewCount: 0,
		repositoryCount: 0,
		committedRepositoryCount: 0,
		repositoryCommits: []
	)
}

extension ContentEntry {
	/**
	An entry from the Markdown of a file in the directory of its type, like `content/apps/test.md`, or in a subdirectory of it, like `content/pages/apps/faq.md` for the slug `apps/faq`. The file is not written to disk.
	*/
	init(markdown: String, slug: String = "test", project: Project = .empty) async throws {
		let directory = project.root.appending(path: Self.directory)
		let file = try MarkdownFile(contents: markdown, url: directory.appending(path: "\(slug).md"), relativeTo: directory)
		try await self.init(file: file, frontmatter: file.decodeFrontmatter(), project: project)
	}
}

extension App {
	/**
	The Markdown of an app file with the frontmatter that every app needs, then the other lines of the frontmatter, like `isMenuBarApp: true`, and the body. The required keys are on lines 2 to 5, so the other lines start at line 6, and the body two lines after the end of the frontmatter.
	*/
	static func testMarkdown(
		title: String = "Test",
		publicationDate: String = "2026-01-01",
		platforms: [Platform] = [.macOS],
		frontmatter: String = "",
		body: String = "Text."
	) -> String {
		let platformList = platforms.map { "'\($0.rawValue)'" }.joined(separator: ", ")
		let lines = ["title: '\(title)'", "subtitle: 'Test app'", "publicationDate: \(publicationDate)", "platforms: [\(platformList)]"] + (frontmatter.isEmpty ? [] : [frontmatter])
		return "---\n\(lines.joined(separator: "\n"))\n---\n\n\(body)"
	}

	/**
	An app from the Markdown of ``testMarkdown(title:publicationDate:platforms:frontmatter:body:)``, in `content/apps/<slug>.md`. The file is not written to disk.
	*/
	init(
		title: String = "Test",
		publicationDate: String = "2026-01-01",
		platforms: [Platform] = [.macOS],
		frontmatter: String = "",
		body: String = "Text.",
		slug: String = "test",
		project: Project = .empty
	) async throws {
		try await self.init(
			markdown: Self.testMarkdown(
				title: title,
				publicationDate: publicationDate,
				platforms: platforms,
				frontmatter: frontmatter,
				body: body
			),
			slug: slug,
			project: project
		)
	}
}

extension SiteSettings {
	/**
	A `content/site.soml` with the required values, for a project of a test.
	*/
	static let testSOML = "appUserCount: 1\nsupportEmailCount: 1\n"
}

extension Guide {
	/**
	The body of a guide about the app `test`, with the shape that every guide needs.
	*/
	static let testBody = "@QuickAnswer {\n\tUse [Test](/test).\n}\n\n@Steps {\n1. Open Test.\n}\n\n## Without an app\n\nText."
}

extension Decodable {
	/**
	The value of the JSON, decoded like a response of ``ResponseCache``, with ISO 8601 dates.
	*/
	init(json: String) throws {
		let decoder = JSONDecoder()
		decoder.dateDecodingStrategy = .iso8601
		self = try decoder.decode(Self.self, from: Data(json.utf8))
	}
}

extension ResponseCache {
	/**
	A cache with a fresh response for each URL, so the test does not use the network. The requests must not have a body, as the body is part of the cache key. It is in a new directory of the `.temporaryDirectory` trait, unless a directory is given.
	*/
	init(responses: [String: String], directory: URL? = nil) throws {
		let directory = try directory ?? URL.temporaryDirectory()

		for (url, body) in responses {
			let responseURL = try #require(URL(string: url), "An invalid fixture URL: \(url)")
			try Self.writeFixture(for: URLRequest(url: responseURL), body: Data(body.utf8), directory: directory)
		}

		self.init(directory: directory, maximumAge: .seconds(60 * 60))
	}

	/**
	Writes a cached response for the exact request, including its method and body, with optional stale-date and revalidation metadata.
	*/
	static func writeFixture(for request: URLRequest, body: Data, date: Date = .now, etag: String? = nil, directory: URL) throws {
		try JSONEncoder().encode(ResponseCacheFixture(etag: etag, date: date, body: body)).write(to: directory.appending(path: "\(request.responseCacheKey).json"))
	}

	/**
	A cache with the responses of npm for ``NPMStatistics/load(cache:warnings:)``: the search pages, the downloads of all of npm, and the most-downloaded packages, so the test does not use the network.
	*/
	static func npm(search: String, searchPages: [Int: String] = [:], registryDownloads: String = #"{"downloads": 0}"#, mostDownloaded: String = "export const topDownload = [\n  'semver',\n]") throws -> Self {
		var responses = [
			"https://registry.npmjs.org/-/v1/search?text=maintainer:sindresorhus&size=250&from=0": search,
			"https://api.npmjs.org/downloads/point/last-week": registryDownloads,
			"https://unpkg.com/npm-high-impact/lib/top-download.js": mostDownloaded,
		]

		for (offset, page) in searchPages {
			responses["https://registry.npmjs.org/-/v1/search?text=maintainer:sindresorhus&size=250&from=\(offset)"] = page
		}

		return try Self(responses: responses)
	}
}

/**
The on-disk envelope of a cached test response, shared by GET and POST fixtures.
*/
private struct ResponseCacheFixture: Codable {
	let etag: String?
	let date: Date
	let body: Data
}

/**
The error when a route is not the kind of output that the test renders, like a redirect instead of a page.
*/
private struct UnexpectedOutputError: Error {}

extension Route {
	/**
	The HTML of the page of the route. It throws when the route is not a page.
	*/
	func renderedHTML() throws -> String {
		guard case .page(_, let render) = output else {
			throw UnexpectedOutputError()
		}

		return try render()
	}

	/**
	The contents of the file of the route, like a feed. It throws when the route is not a file.
	*/
	func renderedFile() async throws -> Data {
		guard case .file(let render) = output else {
			throw UnexpectedOutputError()
		}

		return try await render()
	}
}

extension Page {
	/**
	The HTML of the page. It throws when the route is not a page.
	*/
	func renderedHTML() throws -> String {
		try route.renderedHTML()
	}
}

/**
An enum of a Swift source that declares a conformance to a protocol, like `enum IDs: String, ScriptIDSet`, found with the parser of Swift (``SwiftSyntax/SourceFileSyntax/enums(conformingTo:)``).
*/
struct DeclaredEnum {
	/**
	The name with the names of the types around it, like `CopyButton.States`, also of an extension, like `GeoCitiesPage.States` for an enum in `extension GeoCitiesPage`.
	*/
	let name: String

	/**
	The name of each case, without backticks, and its raw value, which is the name for a case without one.
	*/
	let cases: [(name: String, rawValue: String)]
}

extension SourceFileSyntax {
	/**
	The enums that declare a conformance to the protocol, like `ScriptIDSet`. Limitation: A conformance in an extension is not found, as the components declare it on the enum.
	*/
	func enums(conformingTo protocolName: String) -> [DeclaredEnum] {
		declaredTypes.compactMap { type in
			guard
				let cases = type.cases,
				type.inheritedTypes.contains(protocolName)
			else {
				return nil
			}

			return DeclaredEnum(name: type.qualifiedName, cases: cases)
		}
	}

	/**
	The names of the structs, classes, enums, and extensions that declare a conformance to the protocol, like `CopyButton` for `struct CopyButton: ScriptedElement`, without the names of the types around them.
	*/
	func typeNames(conformingTo protocolName: String) -> [String] {
		declaredTypes
			.filter { $0.inheritedTypes.contains(protocolName) }
			.map(\.name)
	}

	/**
	The calls of a function, an initializer, or a method with the name, like `HTMLRaw` for `HTMLRaw(…)` and `declaration` for `.declaration(…)`.
	*/
	func calls(named name: String) -> [FunctionCallExprSyntax] {
		let collector = CallCollector(name: name)
		collector.walk(self)
		return collector.calls
	}

	private var declaredTypes: [DeclaredType] {
		let collector = DeclaredTypeCollector()
		collector.walk(self)
		return collector.types
	}
}

extension FunctionCallExprSyntax {
	/**
	The name of the function, like `HTMLRaw` for `HTMLRaw(…)`, or of the method, like `declaration` for `.declaration(…)` and `style.declaration(…)`.
	*/
	var calledName: String? {
		calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text
			?? calledExpression.as(MemberAccessExprSyntax.self)?.declName.baseName.text
	}

	/**
	Whether it calls a method or a static member, like `.declaration(…)`, not a function or an initializer, like `LengthPercentage(…)`.
	*/
	var isMemberCall: Bool {
		calledExpression.is(MemberAccessExprSyntax.self)
	}

	/**
	The first argument when it is a string literal, like the CSS of `.nested("…")`.
	*/
	var firstStringLiteral: StringLiteralExprSyntax? {
		arguments.first?.expression.as(StringLiteralExprSyntax.self)
	}

	/**
	The name of the closest call that this call is inside, like `script` for the `HTMLRaw(…)` in `script { HTMLRaw(…) }`.
	*/
	var enclosingCallName: String? {
		var node = parent

		while let current = node {
			if let call = current.as(FunctionCallExprSyntax.self) {
				return call.calledName
			}

			node = current.parent
		}

		return nil
	}
}

extension StringLiteralExprSyntax {
	/**
	The text between the quotes as it is in the source, with interpolations like `\#(IDs.restart.id)` as they are written.
	*/
	var sourceContent: String {
		segments.description
	}
}

/**
A struct, class, enum, or extension of a Swift source (``DeclaredTypeCollector``).
*/
private struct DeclaredType {
	let name: String

	/**
	The name with the names of the types around it, like `CopyButton.States`.
	*/
	let qualifiedName: String

	/**
	The types after the colon, like `String` and `ScriptIDSet`.
	*/
	let inheritedTypes: [String]

	/**
	The cases of an enum, each with its raw value, which is the name for a case without one. `nil` for other types.
	*/
	let cases: [(name: String, rawValue: String)]?
}

/**
Finds the structs, classes, enums, and extensions of a source, with the names of the types around each one.
*/
private final class DeclaredTypeCollector: SyntaxVisitor {
	private var typeNames = [String]()
	var types = [DeclaredType]()

	init() {
		super.init(viewMode: .sourceAccurate)
	}

	private func enter(_ name: String, inheritanceClause: InheritanceClauseSyntax?, cases: [(name: String, rawValue: String)]? = nil) -> SyntaxVisitorContinueKind {
		typeNames.append(name)

		types.append(
			DeclaredType(
				name: name,
				qualifiedName: typeNames.joined(separator: "."),
				inheritedTypes: inheritanceClause?.inheritedTypes.map(\.type.trimmedDescription) ?? [],
				cases: cases
			)
		)

		return .visitChildren
	}

	override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
		enter(node.name.text, inheritanceClause: node.inheritanceClause)
	}

	override func visitPost(_ node: StructDeclSyntax) {
		typeNames.removeLast()
	}

	override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
		enter(node.name.text, inheritanceClause: node.inheritanceClause)
	}

	override func visitPost(_ node: ClassDeclSyntax) {
		typeNames.removeLast()
	}

	override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
		enter(node.extendedType.trimmedDescription, inheritanceClause: node.inheritanceClause)
	}

	override func visitPost(_ node: ExtensionDeclSyntax) {
		typeNames.removeLast()
	}

	override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
		let cases = node.memberBlock.members.compactMap { $0.decl.as(EnumCaseDeclSyntax.self) }.flatMap(\.elements).map { element in
			let name = element.name.identifier?.name ?? element.name.text
			return (name: name, rawValue: element.rawValue?.value.as(StringLiteralExprSyntax.self)?.representedLiteralValue ?? name)
		}

		return enter(node.name.text, inheritanceClause: node.inheritanceClause, cases: cases)
	}

	override func visitPost(_ node: EnumDeclSyntax) {
		typeNames.removeLast()
	}
}

/**
Finds the calls with a name (``SwiftSyntax/SourceFileSyntax/calls(named:)``).
*/
private final class CallCollector: SyntaxVisitor {
	private let name: String
	var calls = [FunctionCallExprSyntax]()

	init(name: String) {
		self.name = name
		super.init(viewMode: .sourceAccurate)
	}

	override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
		if node.calledName == name {
			calls.append(node)
		}

		return .visitChildren
	}
}

/**
A generated script tag, retaining source order for import-map checks.
*/
struct ScriptTag {
	let source: String?
	let type: String?
	let id: String?
	let body: Substring
	let range: Range<String.Index>
}

/**
Readers for the bounded HTML emitted by this website, shared by offline and rendered-page tests.
*/
extension String {
	nonisolated(unsafe) private static let stylePattern = /<style\b[^>]*>(.*?)<\/style>/.dotMatchesNewlines()
	nonisolated(unsafe) private static let scriptTagPattern = /<script\b([^>]*)>(.*?)<\/script>/.dotMatchesNewlines()
	nonisolated(unsafe) private static let scriptAttributePattern = /(?:^|\s)(src|type|id)="([^"]*)"/

	/**
	The raw embedded stylesheet bodies in document order.
	*/
	var embeddedStyles: [Substring] {
		matches(of: Self.stylePattern).map(\.1)
	}

	/**
	Script metadata and raw bodies in document order. Attribute order is insignificant.
	*/
	var scriptTags: [ScriptTag] {
		matches(of: Self.scriptTagPattern).map { match in
			let attributes = Dictionary(match.1.matches(of: Self.scriptAttributePattern).map { (String($0.1), String($0.2)) }, uniquingKeysWith: { first, _ in first })
			return ScriptTag(source: attributes["src"], type: attributes["type"], id: attributes["id"], body: match.2, range: match.range)
		}
	}
}

extension RenderedPage {
	/**
	The raw bodies of this page's embedded stylesheets, in document order.
	*/
	var embeddedStyles: [Substring] {
		html.embeddedStyles
	}
}
