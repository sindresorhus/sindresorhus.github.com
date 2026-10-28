import Foundation
import JavaScriptCore
import SiteKit
import TestSupport
import Testing
@testable import Website

/**
The components that are custom elements (``ScriptedElement``) and their scripts next to their Swift files.
*/
struct ScriptedElementTests {
	/**
	The scripts of the elements, found in the `Scripts` folders like the build finds them, with their text.
	*/
	private static let scripts: [(path: RoutePath, source: URL, text: String)] = Project.website.elementScripts().map { script in
		(script.path, script.source, (try? String(contentsOf: script.source, encoding: .utf8)) ?? "")
	}

	/**
	Every page of the site (``RenderedPage/website``), and the custom elements (``ScriptedElement``) that they show, each once, as types, so the tests can check the scripts against them without a list of the elements.
	*/
	private static let site = Task {
		let pages = try await RenderedPage.website
		var elements = [any ScriptedElement.Type]()

		for element in pages.flatMap(\.elements) where !elements.contains(where: { $0 == element }) {
			elements.append(element)
		}

		return (pages: pages.map { (path: $0.route.path, html: $0.html) }, elements: elements)
	}

	/**
	The tests below check the elements that the pages show, so every element must be shown by a page or the gallery. The names are compared without their parent type, like `Turntable` for `GeoCitiesDJBooth.Turntable`.
	*/
	@Test
	func `shared script records preserve attributes multiline bodies and document order`() throws {
		let html = """
		<script id="data" type="application/json">{
		"value": 1
		}</script><script src="/scripts/app.js?v=abc" type="module"></script>
		"""
		let scripts = html.scriptTags
		try #require(scripts.count == 2)
		#expect(scripts[0].id == "data")
		#expect(scripts[0].type == "application/json")
		#expect(scripts[0].source == nil)
		#expect(scripts[0].body.contains("\n"))
		#expect(scripts[1].source == "/scripts/app.js?v=abc")
		#expect(scripts[1].type == "module")
		#expect(scripts[0].range.upperBound <= scripts[1].range.lowerBound)
		#expect(String(html[scripts[1].range]).hasPrefix("<script src="))
	}

	@Test
	func `shared stylesheet reader retains ordered raw bodies with attributes`() {
		let page = RenderedPage(route: Route.page(.root) { "" }, html: "<style media=\"screen\">a {\n color: red;\n}</style><style>b {color: blue}</style>", elements: [])
		let styles = page.embeddedStyles.map(String.init)
		let expected = ["a {\n color: red;\n}", "b {color: blue}"]
		#expect(styles == expected)
	}

	@Test
	func `the site import-map envelope requires its imports field`() throws {
		#expect(throws: DecodingError.self) {
			try JSONDecoder().decode(Site.Scripts.ImportMap.self, from: Data("{}".utf8))
		}
		let map = Site.Scripts.ImportMap(imports: ["/base.js": "/base.js?v=abc"])
		let decoded = try JSONDecoder().decode(Site.Scripts.ImportMap.self, from: JSONEncoder().encode(map))
		#expect(decoded.imports == map.imports)
	}

	@Test
	func `every element in the sources is shown by a page`() async throws {
		var declared = Set<String>()

		for file in try await SwiftSourceFile.all.value {
			declared.formUnion(file.syntax.typeNames(conformingTo: "ScriptedElement"))
		}

		let shown = try await Set(Self.site.value.elements.map { String(describing: $0) })

		#expect(declared.count > 80)
		#expect(declared.subtracting(shown).sorted() == [], "No page shows these elements. Show them in the gallery (`GalleryPage`).")
	}

	@Test
	func `every script of an element is excluded from the target in Package.swift`() throws {
		let package = try String(contentsOf: Project.website.root.appending(path: "Package.swift"), encoding: .utf8)

		#expect(Self.scripts.count > 50)

		for script in Self.scripts {
			let folder = script.source.deletingLastPathComponent().path(relativeTo: SwiftSourceFile.directory)
			#expect(package.contains("\"\(folder)\""), "The folder of \(script.path), \(folder), is not in the `exclude` of the Website target in Package.swift.")
		}
	}

	/**
	The build publishes a script file as it is, so the file must define the element of its type itself: with the tag name of the type, and with a class named like the type, so stack traces name it. The tag name is written by hand, so a typo, or a renamed type, which changes the tag name, is found here. A script file that is not the script of an element is dead code.
	*/
	@Test
	func `every script file defines the element of its type and imports its base class`() async throws {
		let elements = try await Self.site.value.elements
		var scriptsOfElements = Set<RoutePath>()

		for element in elements {
			guard let path = element.script.path else {
				continue
			}

			scriptsOfElements.insert(path)

			guard let script = Self.scripts.first(where: { $0.path == path }) else {
				Issue.record("\(element) has no script file at \(path).")
				continue
			}

			let className = String(describing: element)
			let definitions = script.text.matches(of: /^customElements\.define\(.*$/.anchorsMatchLineEndings()).map { String($0.output) }
			#expect(definitions == ["customElements.define('\(element.tagName)', \(className));"], "\(path) must end with `customElements.define('\(element.tagName)', \(className));`, the tag name and the name of \(element).")

			// A script can have other classes too, like an error type.
			let declarations = script.text.matches(of: /^class (\w+) extends (\w+) \{$/.anchorsMatchLineEndings()).filter { $0.1 == className }
			try #require(declarations.count == 1, "\(path) must declare `class \(className) extends Base {`.")

			let baseClass = String(declarations[0].2)

			if baseClass != "HTMLElement" {
				// The import can have named imports too, like `import GeoCitiesElement, {cloneTemplate} from …`.
				let importsBaseClass = script.text.contains(try Regex("^import \(baseClass)(?:, \\{[^}]*\\})? from '/scripts/[^']+\\.js';$").anchorsMatchLineEndings())
				#expect(importsBaseClass, "\(path) must import its base class, \(baseClass).")
			}
		}

		let scriptsOfNoElement = Self.scripts.map(\.path).filter { !scriptsOfElements.contains($0) }
		#expect(scriptsOfNoElement.isEmpty, "These scripts are not the script of an element that a page shows.")
	}

	/**
	A script imports another one without its hash, and the import map of the page adds it, so each import must be a script in `public/scripts`, which the build publishes in `/scripts`, and no import may have a hash written by hand, which the next change of the file would make stale.
	*/
	@Test
	func `every import of a script is a published script, without a hash`() throws {
		let imported = Set(try Site.Scripts(project: .website).records.values.flatMap(\.imports).map(\.path))
		let publicScripts = Set(try Project.website.publicFiles().map(\.path))

		// Like the base class of the 1999 page, and the relative import of the nebula of the home page.
		#expect(imported.isSuperset(of: [#path("/scripts/geocities-element.js"), #path("/scripts/scripted-element.js"), #path("/scripts/nebula.js")]))

		for path in imported {
			#expect(path.starts(with: #path("/scripts")) && publicScripts.contains(path), "A script imports \(path), which is not a script in `public/scripts`.")
		}

		for script in Self.scripts {
			#expect(!script.text.contains(/^import .*\?v=/.anchorsMatchLineEndings()), "\(script.path) imports a script with its hash. The import map adds it.")
		}
	}

	/**
	The imports are found at the start of a line, and the dynamic imports anywhere, so an import in a comment is not one. An import of another site without a path is not a script of the site. A relative import is resolved from the path that the build publishes the script at, also for the script of an element, in `/scripts/elements`. The import map of a page has only the scripts that its scripts import, also through another script, that have a hash, and there is none outside a build, where a script also has no hash in its path.
	*/
	@Test(.temporaryDirectory)
	func `the import map has the scripts that other scripts import, with their hashes, and the page preloads the static ones`() throws {
		let root = try URL.temporaryDirectory(
			files: [
				"public/scripts/base.js": "export default class Base {}",
				"public/scripts/nebula.js": "export const draw = () => {};",
				"public/scripts/home.js": "import Base from '/scripts/base.js';\nimport '/scripts/missing.js';\n// import '/scripts/comment.js';\nconst {draw} = await import('./nebula.js');\nconst external = await import('https://example.com');",
				"public/scripts/game.js": "import Board from '/scripts/board.js';",
				"public/scripts/board.js": "import Base from '/scripts/base.js';\nexport default class Board extends Base {}",
				"Sources/Website/Scripts/Clock.js": "import Base from '../base.js';",
			]
		)
		let project = Project(root: root)

		let scripts = try Site.Scripts(project: project)
		#expect(Set(scripts.records.values.flatMap(\.imports)) == [.init(path: #path("/scripts/base.js"), kind: .static), .init(path: #path("/scripts/board.js"), kind: .static), .init(path: #path("/scripts/nebula.js"), kind: .dynamic), .init(path: #path("/scripts/missing.js"), kind: .static)])

		let hashes = scripts.records.mapValues(\.contentHash)
		#expect(hashes.keys.sorted(using: KeyPathComparator(\.description)) == [#path("/scripts/base.js"), #path("/scripts/board.js"), #path("/scripts/elements/Clock.js"), #path("/scripts/game.js"), #path("/scripts/home.js"), #path("/scripts/nebula.js")])

		// A script without a hash, like one of another site, is left out.
		let importMap = try #require(scripts.importMap(loading: [#path("/scripts/home.js")]))

		let imports = try JSONDecoder().decode(Site.Scripts.ImportMap.self, from: Data(importMap.utf8)).imports
		let baseHash = try #require(hashes[#path("/scripts/base.js")])
		let nebulaHash = try #require(hashes[#path("/scripts/nebula.js")])
		let expectedImports: [String: String] = ["/scripts/base.js": "/scripts/base.js?v=\(baseHash)", "/scripts/nebula.js": "/scripts/nebula.js?v=\(nebulaHash)"]
		#expect(imports == expectedImports)
		// A page whose scripts import nothing has no import map, and an element script that imports the base class gets only that.
		#expect(scripts.importMap(loading: [#path("/scripts/nebula.js")]) == nil)

		// A script that an imported script imports is in the map too.
		let gameImports = try JSONDecoder().decode(Site.Scripts.ImportMap.self, from: Data(try #require(scripts.importMap(loading: [#path("/scripts/game.js")])).utf8)).imports
		#expect(gameImports.keys.sorted() == ["/scripts/base.js", "/scripts/board.js"])
		#expect(try #require(scripts.importMap(loading: [#path("/scripts/elements/Clock.js")])).contains("/scripts/base.js?v=\(baseHash)"))
		#expect(Site.Scripts.published.importMap(loading: [#path("/scripts/home.js")]) == nil)

		// The page preloads the static imports, also through another script, but not the dynamic ones, which load only when needed.
		#expect(scripts.modulePreloads(loading: [#path("/scripts/home.js")]).map(\.description) == ["/scripts/base.js?v=\(baseHash)"])
		let boardHash = try #require(hashes[#path("/scripts/board.js")])
		#expect(scripts.modulePreloads(loading: [#path("/scripts/game.js")]).map(\.description) == ["/scripts/base.js?v=\(baseHash)", "/scripts/board.js?v=\(boardHash)"])

		// The pages load a script with its hash while the site is published.
		#expect(Site.Scripts.$published.withValue(scripts) { RoutePath("/scripts/base.js").versioned.description } == "/scripts/base.js?v=\(baseHash)")
		#expect(RoutePath("/scripts/base.js").versioned.description == "/scripts/base.js")
	}

	@Test(.temporaryDirectory)
	func `element publication keeps the text and imports that its hash describes`() throws {
		let original = "import Base from '/scripts/base.js';"
		let root = try URL.temporaryDirectory(files: [
			"public/scripts/base.js": "export default class Base {}",
			"Sources/Website/Scripts/Clock.js": original,
		])
		let path = #path("/scripts/elements/Clock.js")
		let project = Project(root: root)
		let scripts = try Site.Scripts(project: project)
		let hash = try #require(scripts.records[path]?.contentHash)

		// A preview save must not publish new text under the old content hash.
		try Data("import Other from '/scripts/other.js';".utf8).write(to: root.appending(path: "Sources/Website/Scripts/Clock.js"))
		#expect(try scripts.elementScript(at: path) == Data(original.utf8))
		#expect(scripts.records[path]?.imports == [.init(path: #path("/scripts/base.js"), kind: .static)])
		#expect(try Site.Scripts(project: project).records[path]?.contentHash != hash)
		#expect(throws: CocoaError.self) {
			try scripts.elementScript(at: #path("/scripts/base.js"))
		}
	}

	@Test
	func `versioned assets keep their destination and use the shared query encoder`() {
		let destination: LinkDestination = RoutePath("/assets/site.css").versioned(content: "body {}")
		guard case .path(let path, let query, let fragment) = destination else {
			Issue.record("A versioned asset must stay a site destination.")
			return
		}

		#expect(path == RoutePath("/assets/site.css"))
		#expect(query.count == 1)
		#expect(query.first?.name == "v")
		#expect(query.first?.value?.isEmpty == false)
		#expect(fragment == nil)
		#expect(destination.description.hasPrefix("/assets/site.css?v="))
	}

	/**
	A state that the script of an element sets must be a case of the `States` of the element (`ElementStateSet`), so a typo in the script, or a state that the Swift code no longer has, is found. Only the states that the script sets as a literal are checked (``String/assignedDataStates``), not a state from a variable.
	*/
	@Test
	func `every state that the script of an element sets is one of its states`() async throws {
		for element in try await Self.site.value.elements {
			let assignedStates = Self.code(of: try element.script.source).assignedDataStates
			#expect(assignedStates.subtracting(element.declaredStates).sorted() == [], "The script of \(element) sets states that `\(element).States` does not have.")
		}
	}

	/**
	The other direction: a state that nothing sets or styles is dead code. Each state of an element must be set, by its script, where it is a string literal somewhere, also in a choice, like `isDone ? 'done' : 'failed'`, or by Swift in the markup of the element, as the first state (`.state(…)`) or as a value that the script copies, like the value of a radio button or a string in its runtime configuration, and it must be styled, so the CSS of a page that shows the element has `[data-state="…"]`. Limitation: The checks look for the name, so a state with a common name, like `open`, also counts as set when the script uses the name for something else, and as styled when another component on the same page styles it.
	*/
	@Test
	func `every state of an element is set and styled`() async throws {
		// Configuration can hold states in nested records or arrays, which the script selects at runtime.
		func stringValues(in value: Any) -> [String] {
			switch value {
			case let string as String:
				[string]
			case let array as [Any]:
				array.flatMap { stringValues(in: $0) }
			case let object as [String: Any]:
				object.values.flatMap { stringValues(in: $0) }
			default:
				[]
			}
		}

		let site = try await Self.site.value
		var checkedElementCount = 0

		// The elements and the styles of each page, found once, as a search of every page for each element is slow.
		let pages = site.pages.map { page in
			(elements: Self.customElementMarkup(in: page.html), styles: page.html.embeddedStyles)
		}

		for element in site.elements where !element.declaredStates.isEmpty {
			checkedElementCount += 1

			let script = Self.code(of: try element.script.source)
			let pagesWithElement = pages.compactMap { page in
				page.elements[element.tagName].map { (markup: $0, styles: page.styles) }
			}
			let markup = pagesWithElement.flatMap(\.markup)
			let styles = pagesWithElement.flatMap(\.styles)

			let configuredValues = try markup.flatMap { $0.matches(of: /data-config="([^"]+)"/) }.flatMap { match in
				let json = String(match.1).decodingHTMLEscapes
				return stringValues(in: try JSONSerialization.jsonObject(with: Data(json.utf8)))
			}

			for state in element.declaredStates {
				let isSetByScript = ["'\(state)'", "\"\(state)\"", "`\(state)`"].contains { script.contains($0) }
				let isRendered = markup.contains { $0.contains("data-state=\"\(state)\"") || $0.contains("value=\"\(state)\"") }
				#expect(isSetByScript || isRendered || configuredValues.contains(state), "Neither the script of \(element) nor its markup or configuration sets its state `\(state)`. Remove it from `\(element).States`.")

				let isStyled = styles.contains { $0.contains("[data-state=\"\(state)\"]") }
				#expect(isStyled, "No style of the pages that show \(element) uses its state `\(state)`.")
			}
		}

		#expect(checkedElementCount > 50)
	}

	/**
	The states of the components that are not custom elements, which page scripts set, like `site.js` on the links to sections, and `geocities.js` on the 1999 page: the cases of the `ElementStateSet` enums in the sources that are not the `States` of an element, found with the parser of Swift, so the states of a new component like that are checked too.
	*/
	private static func pageScriptStates(elements: [any ScriptedElement.Type]) async throws -> (componentCount: Int, states: Set<String>) {
		let elementStates = Set(elements.map { $0.statesName })

		let enums: [DeclaredEnum] = try await SwiftSourceFile.all.value
			.flatMap { $0.syntax.enums(conformingTo: "ElementStateSet") }
			.filter { !elementStates.contains($0.name) }

		return (enums.count, Set(enums.flatMap(\.cases).map(\.rawValue)))
	}

	/**
	Like `every state of an element is set and styled`, for the states that page scripts set. A page script is not tied to one component, so a state counts as set when any page script sets it, or a page renders it, and as styled when the site stylesheet or a page styles it.
	*/
	@Test
	func `every state of the components of page scripts is set and styled`() async throws {
		let site = try await Self.site.value
		let pageScripts = try Project.website.publicDirectory.appending(path: "scripts").filesRecursively()
			.filter { $0.pathExtension == "js" }
			.map { Self.code(of: try String(contentsOf: $0, encoding: .utf8)) }
		let assignedStates = Set(pageScripts.flatMap(\.assignedDataStates))
		let styles = [Stylesheet.site.css] + site.pages.flatMap { $0.html.embeddedStyles.map(String.init) }
		let (componentCount, states) = try await Self.pageScriptStates(elements: site.elements)

		// Like the prose, the apps page, and the desktops of the 1999 page.
		#expect(componentCount >= 8)
		#expect(states.count > 30)

		for state in states.sorted() {
			let isRendered = site.pages.contains { $0.html.contains("data-state=\"\(state)\"") }
			#expect(assignedStates.contains(state) || isRendered, "No page script sets the state `\(state)`, and no page renders it. Remove it from its `States`.")

			let isStyled = styles.contains { $0.contains("[data-state=\"\(state)\"]") }
			#expect(isStyled, "No style uses the state `\(state)`.")
		}
	}

	@Test
	func `only the assigned states count`() {
		let script = """
		button.dataset.state = 'copied';
		toggle.dataset.state = isOn ? 'on' : '';
		goOn.dataset.state = match.phase === 'waiting' ? 'urgent' : '';
		if (card.dataset.state === 'back') {}
		element.dataset.state = state;
		slot.dataset.state = result === 'winner' ? 'winner' : 'played';
		box.dataset.state = steps[step];
		"""

		#expect(script.assignedDataStates == ["copied", "on", "urgent", "winner", "played"])
	}

	/**
	A script that uses a part that the component does not have would find nothing. The base class throws for it when it runs (`this.parts`), and this test finds it without running it, for the direct forms of ``usedParts(in:)``. A part that the markup has but no script uses is only a leftover attribute, so it is not checked.
	*/
	@Test
	func `every part that a script uses is declared`() async throws {
		for element in try await Self.site.value.elements {
			let usedParts = Self.usedParts(in: Self.code(of: try element.script.source))
			#expect(usedParts.subtracting(element.declaredParts).sorted() == [], "The script of \(element) uses parts that `\(element).Parts` does not have.")
		}
	}

	/**
	A script reads the attributes of its element by name, like `this.getAttribute('share-url')`, and the Swift component writes them with `.custom(name:value:)`, so a typo or a renamed attribute is `null` in the script, which no compiler sees. Each attribute that a script reads must be on its element on a page, or set by a page script, like `app`, which `feedback.js` sets. And each attribute of an element on a page must be read by its script, or it is markup that nothing uses. Global attributes, like `id`, `hidden`, `aria-*`, and `data-*`, are not checked. Limitation: A page script sets an attribute by an ID, not by the tag, so an attribute that any page script sets counts as set for every element, and only the direct reads, like `this.getAttribute('text')`, count.
	*/
	@Test
	func `every attribute of an element is read by its script, and every attribute that a script reads is set`() async throws {
		let site = try await Self.site.value
		let globalAttributes: Set = ["class", "id", "role", "tabindex", "hidden", "title", "lang", "dir", "inert", "popover", "slot"]
		var renderedAttributesByTagName = [String: Set<String>]()

		for page in site.pages {
			for match in page.html.matches(of: /<([a-z][a-z0-9]*(?:-[a-z0-9]+)+)((?:\s+[^\s=>]+(?:="[^"]*")?)*)\s*>/) {
				let names = match.2.matches(of: /\s([^\s=>]+)(?:="[^"]*")?/).map { String($0.1) }.filter { !globalAttributes.contains($0) && !$0.hasPrefix("aria-") && !$0.hasPrefix("data-") }
				renderedAttributesByTagName[String(match.1), default: []].formUnion(names)
			}
		}

		let pageScripts = try Project.website.publicFiles().filter { $0.source.pathExtension == "js" }.lazy.map { try String(contentsOf: $0.source, encoding: .utf8) }.joined(separator: "\n")
		let attributesSetByPageScripts = Set(pageScripts.matches(of: /\.setAttribute\('([\w-]+)'/).map { String($0.1) })

		// `sharedPage(this)` of `dom.js` reads the attributes of the page that the element shares (`SharedPage`).
		let domScript = try String(contentsOf: Project.website.publicFile(#path("/scripts/dom.js")), encoding: .utf8)
		let sharedPageAttributes = Set(domScript.matches(of: /\belement\.getAttribute\('(share-[\w-]+)'\)/).map { String($0.1) })
		#expect(!sharedPageAttributes.isEmpty)

		var checkedElementCount = 0

		for element in site.elements {
			let code = Self.code(of: try element.script.source)
			let readAttributes = Set(code.matches(of: /\bthis\.(?:get|has)Attribute\('([\w-]+)'\)/).map { String($0.1) }).filter { !$0.hasPrefix("aria-") && !$0.hasPrefix("data-") }.union(code.contains("sharedPage(this)") ? sharedPageAttributes : [])
			let renderedAttributes = renderedAttributesByTagName[element.tagName] ?? []

			guard !(readAttributes.isEmpty && renderedAttributes.isEmpty) else {
				continue
			}

			checkedElementCount += 1
			let missingAttributes = readAttributes.subtracting(renderedAttributes).subtracting(attributesSetByPageScripts).sorted()
			#expect(missingAttributes == [], "The script of \(element) reads attributes that its element does not have on any page.")
			#expect(renderedAttributes.subtracting(readAttributes).sorted() == [], "The script of \(element) does not read these attributes of its element. Remove them, or rename them in both places.")
		}

		#expect(checkedElementCount >= 4)
	}

	/**
	The scripts of the 1999 page open the windows of the desktops by name, like `openWindow('dialup')`, and the Swift components name them with `data-desktop-window` (Windows) and `data-mac-window` (Mac OS), so a window that is renamed or removed in Swift would make the script throw when it opens. Only the names that are written in the scripts are checked, not the names from variables.
	*/
	@Test
	func `every window that a script opens by name is on the 1999 page`() async throws {
		let html = try #require(try await Self.site.value.pages.first { $0.path == #path("/1999") }?.html)

		func renderedNames(_ attribute: String) -> Set<String> {
			Set(html.matches(of: /\s(data-[a-z-]+)="([\w-]+)"/).filter { $0.1 == attribute }.map { String($0.2) })
		}

		let windowsNames = renderedNames(GeoCitiesPage.Hooks.desktopWindow.attributeName)
		let macNames = renderedNames(GeoCitiesMacOS.Hooks.window.attributeName)
		#expect(windowsNames.count > 20)
		#expect(macNames.count > 5)

		let pageScripts = try Project.website.publicFiles().filter { $0.source.lastPathComponent.hasPrefix("geocities") && $0.source.pathExtension == "js" }.map { (name: $0.path.description, text: try String(contentsOf: $0.source, encoding: .utf8)) }
		let elementScripts = Self.scripts.map { (name: $0.path.description, text: $0.text) }
		var checkedNameCount = 0

		for script in pageScripts + elementScripts {
			let code = Self.code(of: script.text)
			let openedNames = Set(code.matches(of: /\bopenWindow\('([\w-]+)'/).map { String($0.1) })
			let selectedWindowsNames = Set(code.matches(of: /\[data-desktop-window="([\w-]+)"\]/).map { String($0.1) })
			let selectedMacNames = Set(code.matches(of: /\[data-mac-window="([\w-]+)"\]/).map { String($0.1) })

			// The Mac OS desktop has its own `openWindow`, for its own windows.
			let isMac = script.name.hasSuffix("geocities-mac.js")
			let usedWindowsNames = isMac ? selectedWindowsNames : openedNames.union(selectedWindowsNames)
			let usedMacNames = isMac ? openedNames.union(selectedMacNames) : selectedMacNames
			checkedNameCount += usedWindowsNames.count + usedMacNames.count

			#expect(usedWindowsNames.subtracting(windowsNames).sorted() == [], "\(script.name) uses Windows windows that the 1999 page does not have.")
			#expect(usedMacNames.subtracting(macNames).sorted() == [], "\(script.name) uses Mac OS windows that the 1999 page does not have.")
		}

		#expect(checkedNameCount > 20)
	}

	/**
	The content of a template is not in the element, so `this.parts` throws for a part that is only inside a template, and `clone()` of `scripted-element.js` copies a template part, so it throws for another part. The parts are checked against the markup that the pages render, for the direct forms of ``usedParts(in:)``. A part that a script finds itself with `data-part="name"`, like in a copy in a script that extends `HTMLElement`, is not read through `this.parts`.
	*/
	@Test
	func `every clone copies a template part, and no script reads a part of a template through this.parts`() async throws {
		let site = try await Self.site.value
		let markup = Self.templateParts(in: site.pages.map(\.html), tagNames: Set(site.elements.map { $0.tagName }))
		var cloneCount = 0
		var templateOnlyPartCount = 0

		for element in site.elements {
			let script = Self.code(of: try element.script.source)
			let clonedTemplates = Set(script.matches(of: /\.clone\('(\w+)'\)/).map { String($0.1) })
			let templates = markup.templates[element.tagName] ?? []
			let templateOnlyParts = markup.onlyInTemplates[element.tagName] ?? []
			// The used parts without the lines of the copies and the parts that the script finds itself are the parts that it reads in `this.parts`.
			let partsReadThroughThisParts = Self.usedParts(in: script.replacing(/^.*\.clone\('\w+'\).*$|data-part="\w+"/.anchorsMatchLineEndings(), with: ""))
			cloneCount += clonedTemplates.count
			templateOnlyPartCount += templateOnlyParts.count

			#expect(clonedTemplates.subtracting(templates).sorted() == [], "The script of \(element) clones parts that are not a `template` in its markup.")
			#expect(partsReadThroughThisParts.intersection(templateOnlyParts).sorted() == [], "The script of \(element) reads parts of a template through `this.parts`, which throws. Read them in a copy, with `clone()`.")
		}

		#expect(cloneCount >= 15)
		#expect(templateOnlyPartCount >= 40)
	}

	/**
	The markup of each custom element on the page, by tag name. The markup of an element is from its start tag to its first end tag, so it also has the elements inside it.
	*/
	private static func customElementMarkup(in html: String) -> [String: [Substring]] {
		var markup = [String: [Substring]]()

		for start in html.matches(of: /<([a-z][a-z0-9]*(?:-[a-z0-9]+)+)[\s>]/) {
			let tagName = String(start.1)

			guard let end = html[start.range.upperBound...].firstRange(of: "</\(tagName)>") else {
				continue
			}

			markup[tagName, default: []].append(html[start.range.lowerBound..<end.upperBound])
		}

		return markup
	}

	/**
	The template parts of each element in the pages, by tag name, and the parts that are only inside its templates. The markup of an element (``customElementMarkup(in:)``) also has the parts of the elements inside it, which can only hide a mistake, not report one that is not there.
	*/
	private static func templateParts(in pages: [String], tagNames: Set<String>) -> (templates: [String: Set<String>], onlyInTemplates: [String: Set<String>]) {
		var templates = [String: Set<String>]()
		var insideTemplates = [String: Set<String>]()
		var outsideTemplates = [String: Set<String>]()
		// Before the loops, as Swift parses a regex literal each time the code runs.
		let part = /data-part="(\w+)"/
		let template = /<template\b([^>]*)>(.*?)<\/template>/.dotMatchesNewlines()

		func partNames(in markup: Substring) -> [String] {
			markup.matches(of: part).map { String($0.1) }
		}

		for html in pages {
			for (tagName, markups) in customElementMarkup(in: html) where tagNames.contains(tagName) {
				for markup in markups {
					for match in markup.matches(of: template) {
						templates[tagName, default: []].formUnion(partNames(in: match.1))
						insideTemplates[tagName, default: []].formUnion(partNames(in: match.2))
					}

					let outside = markup.replacing(template, with: "")
					outsideTemplates[tagName, default: []].formUnion(partNames(in: outside))
				}
			}
		}

		var onlyInTemplates = insideTemplates

		for (tagName, parts) in outsideTemplates {
			onlyInTemplates[tagName]?.subtract(parts)
		}

		return (templates, onlyInTemplates)
	}

	/**
	A script reads the config of its element (``ScriptedElement/config``) by the names of the Swift properties, so a renamed property would be `undefined` in the script, which no compiler sees. Each key that a script reads must be in the config that the pages render, and each key of the config must be read, or it is data that nothing uses. Only the keys at the top of the config are checked, in the direct forms of ``readConfigKeys(in:)``. Limitation: An optional property that is `nil` on every page is not in the rendered JSON, so a script that reads it would fail here.
	*/
	@Test
	func `every key of a config is read by its script, and every key that a script reads is in the config`() async throws {
		let site = try await Self.site.value

		// The keys of the configs of each tag on the pages, in one pass.
		var renderedKeysByTagName = [String: Set<String>]()

		for page in site.pages {
			for match in page.html.matches(of: /<([a-z][a-z0-9]*(?:-[a-z0-9]+)+)\b[^>]*\bdata-config="([^"]*)"/) {
				let json = String(match.2)
					// Elementary escapes only these two in attribute values.
					.replacing("&quot;", with: "\"")
					.replacing("&amp;", with: "&")
				let config = try #require(try JSONSerialization.jsonObject(with: Data(json.utf8)) as? [String: Any], "The config of \(match.1) on \(page.path) is not a JSON object.")
				renderedKeysByTagName[String(match.1), default: []].formUnion(config.keys)
			}
		}

		var checkedElementCount = 0

		for element in site.elements {
			let readKeys = Self.readConfigKeys(in: Self.code(of: try element.script.source))
			let renderedKeys = renderedKeysByTagName[element.tagName] ?? []

			guard !(readKeys.isEmpty && renderedKeys.isEmpty) else {
				continue
			}

			checkedElementCount += 1
			#expect(readKeys.subtracting(renderedKeys).sorted() == [], "The script of \(element) reads keys that its `Config` does not have.")
			#expect(renderedKeys.subtracting(readKeys).sorted() == [], "The script of \(element) does not read these keys of its `Config`. Remove them, or rename them in both places.")
		}

		#expect(checkedElementCount >= 5)
	}

	/**
	A page script reads the data of its page (`JSONScript`) by the names of the Swift properties, like the config of an element, so a renamed property would be `undefined` in the script. Each key that a script of the page reads must be in the data, and each key of the data must be read. Data that is not an object, like a list, has no keys to check.
	*/
	@Test
	func `every key of the data of a page is read by its scripts, and every key that they read is in the data`() async throws {
		var checkedDataCount = 0

		for page in try await Self.site.value.pages {
			let scripts = try page.html.scriptTags.compactMap(\.source).filter { $0.hasPrefix("/") }.lazy.map { source in
				let path = RoutePath(String(source.prefix { $0 != "?" }))
				return try String(contentsOf: Self.scripts.first { $0.path == path }?.source ?? Project.website.publicFile(path), encoding: .utf8)
			}
			.joined(separator: "\n")

			// The questions of the FAQ suggestions go to their matcher whole, so a test of `ContentTests` checks their keys, also the nested ones.
			for script in page.html.scriptTags where script.type == "application/json" && script.id != FAQSuggestions.questionsID.rawValue {
				guard
					let id = script.id,
					let data = try JSONSerialization.jsonObject(with: Data(script.body.utf8)) as? [String: Any]
				else {
					continue
				}

				let readKeys = Self.readDataKeys(in: Self.code(of: scripts), id: id)
				checkedDataCount += 1
				#expect(readKeys.subtracting(data.keys).sorted() == [], "The scripts of \(page.path) read keys that the data `\(id)` does not have.")
				#expect(Set(data.keys).subtracting(readKeys).sorted() == [], "The scripts of \(page.path) do not read these keys of the data `\(id)`. Remove them, or rename them in both places.")
			}
		}

		#expect(checkedDataCount >= 3)
	}

	/**
	The keys of the data of a page that a script reads: `const {facts, tunes} = JSON.parse(document.querySelector('#geocities-data').textContent);` and `JSON.parse(…).facts`.
	*/
	private static func readDataKeys(in script: String, id: String) -> Set<String> {
		let source = "JSON.parse(document.querySelector('#\(id)').textContent)"
		var keys = Set<String>()

		for line in script.split(separator: "\n") where line.contains(source) {
			if let match = line.firstMatch(of: /\{([\w\s,:]+)\}\s*=\s*JSON\.parse/) {
				keys.formUnion(names(in: match.1))
			}

			keys.formUnion(line.matches(of: /textContent\)\.(\w+)/).map { String($0.1) })
		}

		return keys
	}

	@Test
	func `only the direct reads of the config count as keys`() {
		let script = """
		this.#goal = this.config.goal;
		const {games: gameTitles, prizes} = arcade.config;
		const {listPath, randomTitle} = JSON.parse(this.dataset.config);
		const perMillisecond = JSON.parse(this.dataset.config).perSecond / 1000;
		const width = this.config.size.width;
		"""

		#expect(Self.readConfigKeys(in: script) == ["goal", "games", "prizes", "listPath", "randomTitle", "perSecond", "size"])
	}

	@Test
	func `only the parts of the element itself count as used`() {
		let script = """
		const {screen, sound} = this.parts;
		const {
			start,
			stop: stopButton,
		} = this.parts;
		this.parts.odds.textContent = '';
		const {width, height} = this.parts.canvas;
		const marbles = game.parts.filter(part => part.isMarble);
		const keys = this.querySelectorAll('[data-part="key"]');
		const setUpNapster = (napster, {search: searchForm,
			query}) => {};
		const drawShareWindow = (context, {title, lines}) => {};
		this.#napster = setUpNapster(this, this.parts);
		"""

		#expect(Self.usedParts(in: script) == ["screen", "sound", "start", "stop", "odds", "canvas", "key", "search", "query"])
	}

	@Test
	func `the parts of a copy of a template count as used, in the block of the copy`() {
		let script = """
		const renderRow = name => {
			const {element: row, parts} = this.clone('rowTemplate');
			parts.name.textContent = name;

			if (isNew) {
				parts.badge.hidden = false;
			}

			return row;
		};
		const parts = text.split(' ');
		const count = parts.length;
		const {element: item, parts: {fileName, details: detailsText}} = napster.clone('resultTemplate');
		const {element, parts: songParts} = this.clone('songTemplate');
		songParts.checkbox.checked = this.parts.burn.disabled;
		"""

		#expect(Self.usedParts(in: script) == ["rowTemplate", "name", "badge", "resultTemplate", "fileName", "details", "songTemplate", "checkbox", "burn"])
	}

	/**
	An inline script is for a small element, so it extends `HTMLElement`, and the page writes it in a `<script>` element as it is, so `</script` in it would end the element early.
	*/
	@Test
	func `every inline script extends HTMLElement and fits in a script element`() async throws {
		let inlineElements = try await Self.site.value.elements.filter { $0.script.path == nil }

		#expect(inlineElements.count >= 5)

		for element in inlineElements {
			#expect(throws: Never.self, "The inline script of \(element) must have one `export default class extends HTMLElement {` line. A script that needs a base class of the site is a script file.") {
				try element.generatedScript()
			}

			#expect(try !element.script.source.localizedCaseInsensitiveContains("</script"), "The inline script of \(element) has `</script`, which ends the script element of the page.")
		}
	}

	/**
	A syntax error stops the whole script, like every element of a script file, and only a browser would show it. JavaScriptCore checks the syntax without Node.js: the scripts of the elements, the published script files, like the page scripts and the scripts of the page bundles, and the inline scripts of the pages.
	*/
	@Test
	func `every script is valid JavaScript`() async throws {
		let site = try await Self.site.value
		let inlineElementScripts = try site.elements
			.filter { $0.script.path == nil }
			.map { (name: "The inline script of \($0)", text: try $0.generatedScript()) }
		let publishedScripts = try Project.website.publicFiles()
			.filter { $0.source.pathExtension == "js" }
			.map { (name: $0.path.description, text: try String(contentsOf: $0.source, encoding: .utf8)) }
		let pageScripts = site.pages.flatMap { page in
			page.html.matches(of: /<script(?: type="module")?>(.*?)<\/script>/.dotMatchesNewlines()).map { (name: "An inline script of \(page.path)", text: String($0.1)) }
		}

		#expect(publishedScripts.count > 20)
		#expect(!pageScripts.isEmpty)

		for script in Self.scripts.map({ (name: $0.path.description, text: $0.text) }) + inlineElementScripts + publishedScripts + pageScripts {
			let error = script.text.javaScriptSyntaxError
			#expect(error == nil, "\(script.name) has a syntax error at line \(error ?? "")")
		}
	}

	@Test
	func `the syntax check finds an error at its line, also in a module`() {
		#expect("import Base from '/scripts/base.js';\nexport {cloneTemplate} from '/scripts/scripted-element.js';\nexport default class Clock extends Base {\n\tasync tick() {\n\t\tawait this.update();\n\t}\n}\nexport const second = 1000;\nawait import('./nebula.js');".javaScriptSyntaxError == nil)
		#expect("import {\n\tcloneTemplate,\n} from '/scripts/scripted-element.js';\nconst a = 1;\nreturn 1 + ;".javaScriptSyntaxError == "5: SyntaxError: Unexpected token ';'")
		#expect("import Base from '/scripts/base.js'\nconst a = ;".javaScriptSyntaxError == "2: SyntaxError: Unexpected token ';'")
		// Modules are strict.
		#expect("with (Math) {\n\tmax(1, 2);\n}".javaScriptSyntaxError?.hasPrefix("1: SyntaxError") == true)
	}

	/**
	The board decodes the codes of Pipoku, which are the same as in the tests of the app, and rejects every other code, so it shows the puzzles that the app opens. It runs the script of the element in `node`, with only the parts of the DOM that it uses.
	*/
	@Test(.enabled(if: Self.checksScripts, "Install Node.js to run the script of the sudoku board."))
	func `the sudoku board shows the puzzle of a Pipoku code`() throws {
		let validCodes = [
			"KkpNhsgJsNkpKgAyaTURhkgSl4Z4ImlYI5UTYQ": "003020600900305001001806400008102900700000008006708200002609500800203009005010300",
			"_____________4BIOSFleWc0WCElGHZJNUgTKXZylWQTgTZ5gkU3JolRSBQlN2lpVBc4IAU": "483921657967345821251876493548132976729564138136798245372689514814253769695417382",
			"AUAQAVIhQkigFAAUJUeDGTQlGGAU": "000000010400000000020000000000050407008000300001090000300400200050100000000806000",
			"gBgSiIDgiIZiQgCDZ5JXRXExaIUZQD0": "800000000003600000070090200050007000000045700000100030001000068008500010090000400",
			"AAAAAAAAAAAAAAAA": String(repeating: "0", count: 81),
			"gAAAAAAAAAAAAABQ_Q": "5" + String(repeating: "0", count: 80),
			"AAAAAAAAAAAAAICQTw": String(repeating: "0", count: 80) + "9"
		]

		let invalidCodes = [
			"",
			"A",
			"AAAAAAAAAAAAAAA",
			"AAAAAAAAAAAAAAAAA",
			// Other forms of base64 of the same bytes: unused bits that are not 0, padding, a line break, and the standard alphabet.
			"KkpNhsgJsNkpKgAyaTURhkgSl4Z4ImlYI5UTYR",
			"KkpNhsgJsNkpKgAyaTURhkgSl4Z4ImlYI5UTYQ==",
			"KkpNhsgJsN\nkpKgAyaTURhkgSl4Z4ImlYI5UTYQ",
			"/////////////4BIOSFleWc0WCElGHZJNUgTKXZylWQTgTZ5gkU3JolRSBQlN2lpVBc4IAU",
			// The text of the grid, like in the first format.
			"..3.2.6..9..3.5..1..18.64....81.29..7.......8..67.82....26.95..8..2.3..9..5.1.3..",
			// Bytes with their check byte that are not a grid: a bit after the cells, the digit 0, a digit over 9, the 4 bits after an odd count of digits that are not 0, and too few or too many digits.
			"AAAAAAAAAAAAAAEH",
			"gAAAAAAAAAAAAAAASg",
			"gAAAAAAAAAAAAACgIw",
			"gAAAAAAAAAAAAABR-g",
			"wAAAAAAAAAAAAAB4",
			"gAAAAAAAAAAAAABQAP0"
		]

		let harness = """
		globalThis.HTMLElement = class {};
		globalThis.customElements = {define() {}};

		const element = () => ({
			hidden: true,
			textContent: '',
			children: [],
			get childElementCount() {
				return this.children.length;
			},
			append(child) {
				this.children.push(child);
			},
			cloneNode() {
				return element();
			},
		});

		const {default: SudokuBoard} = await import('data:text/javascript,' + encodeURIComponent(\(JSONEncoder.pageJSON(try SudokuBoard.generatedScript()))));

		// The cells in reading order, with 0 for an empty cell, or `undefined` when the board shows that the link is invalid.
		const show = code => {
			globalThis.location = {search: '?' + new URLSearchParams({p: code})};
			const parts = {board: element(), invalid: element()};
			const template = {content: {firstElementChild: element()}};
			const board = new SudokuBoard();
			board.querySelector = selector => parts[selector.match(/data-part="(\\w+)"/)[1]] ?? template;
			board.connectedCallback();

			if (!parts.invalid.hidden) {
				return parts.board.hidden && parts.board.childElementCount === 0 ? undefined : 'both';
			}

			const cells = Array.from({length: 81});

			for (const [box, boxElement] of parts.board.children.entries()) {
				for (const [cell, cellElement] of boxElement.children.entries()) {
					const row = (Math.floor(box / 3) * 3) + Math.floor(cell / 3);
					const column = ((box % 3) * 3) + (cell % 3);
					cells[(row * 9) + column] = cellElement.textContent === '' ? '0' : String(cellElement.textContent);
				}
			}

			return parts.board.hidden ? 'hidden' : cells.join('');
		};

		const failures = [];

		for (const [code, cells] of Object.entries(\(JSONEncoder.pageJSON(validCodes)))) {
			if (show(code) !== cells) {
				failures.push(`${code} shows ${show(code)}, not ${cells}`);
			}

			// Every change of one character, which the check byte detects.
			for (let index = 0; index < code.length; index++) {
				for (const character of 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_+/=. ') {
					const changed = code.slice(0, index) + character + code.slice(index + 1);

					if (changed !== code && show(changed) !== undefined) {
						failures.push(`${changed} is not rejected`);
					}
				}
			}
		}

		for (const code of \(JSONEncoder.pageJSON(invalidCodes))) {
			if (show(code) !== undefined) {
				failures.push(`${JSON.stringify(code)} is not rejected`);
			}
		}

		if (failures.length > 0) {
			console.error(failures.join('\\n'));
			process.exit(1);
		}
		"""

		// Node.js 24 has `Uint8Array.fromBase64` only with the flag. Later versions have it by default, and still accept the flag.
		let error = try Self.syntaxError(checking: ["--js-base-64", "--input-type=module"], input: harness)
		#expect(error == nil, "\(error ?? "")")
	}

	/**
	The 404 page suggests the page that a mistyped or guessed path meant, also when a word is added or left out, and nothing for a path that is not close to a page. It runs the page script in `node` with the paths of the page, and only the parts of the DOM that it uses.
	*/
	@Test(.enabled(if: Self.checksScripts, "Install Node.js to run the script of the 404 page."))
	func `the 404 page suggests the closest page`() async throws {
		let page = try #require(try await Self.site.value.pages.first { $0.path == .notFound })
		let paths = try #require(page.html.firstMatch(of: /<script[^>]*id="not-found-data"[^>]*>(.*?)<\/script>/)?.1)
		// Without its import, which a function body cannot have, so the harness imports the module and passes its functions.
		let script = try String(contentsOf: Project.website.publicFile(#path("/scripts/not-found.js")), encoding: .utf8)
			.split(separator: "\n", omittingEmptySubsequences: false)
			.filter { !$0.hasPrefix("import ") }
			.joined(separator: "\n")
		let editDistanceModule = try String(contentsOf: Project.website.publicFile(#path("/scripts/edit-distance.js")), encoding: .utf8)

		let suggestions = [
			"/daot": "/dato",
			"/apps/dato": "/dato",
			"/apps/mac": "/apps/macos",
			"/privacy-policy": "/privacy",
			// The privacy policies of the apps are not indexed, but the 404 page suggests them, as visitors guess their paths from the links of the App Store.
			"/dato/privacy": "/dato/privacy-policy",
			"/velja/index.html": "/velja",
			"/blog/buffer": "/blog/goodbye-nodejs-buffer",
			"/about-me": "/about",
			"/apps/macos-apps": "/apps/macos",
			// A page in a folder, from its last part.
			"/faq": "/apps/faq",
			"/terms": "/apps/terms",
			// Help words lead to the feedback form, not to the closest path, like `/supporters`.
			"/support": "/feedback",
			"/dato/support": "/feedback?product=Dato",
			"/dato/feedback": "/feedback?product=Dato",
			"/datoo/support": "/feedback",
			// A last part of several pages says nothing about the page, so the page of the app.
			"/dato/release-notes": "/dato",
			"/dato/faq": "/dato#faq",
			"/how": "",
			"/x": "",
		]

		let harness = """
		const editDistanceModule = await import(`data:text/javascript,${encodeURIComponent(\(JSONEncoder.pageJSON(editDistanceModule)))}`);
		const failures = [];

		for (const [path, expected] of Object.entries(\(JSONEncoder.pageJSON(suggestions)))) {
			const elements = {
				'#not-found-data': {textContent: \(JSONEncoder.pageJSON(String(paths)))},
				'#closest-page': {hidden: true},
				'#closest-page-link': {},
			};

			new Function('document', 'location', ...Object.keys(editDistanceModule), \(JSONEncoder.pageJSON(script)))({querySelector: selector => elements[selector]}, {pathname: path}, ...Object.values(editDistanceModule));
			const suggestion = elements['#closest-page'].hidden ? '' : elements['#closest-page-link'].href;

			if (suggestion !== expected) {
				failures.push(`${path} suggests ${JSON.stringify(suggestion)}, not ${JSON.stringify(expected)}`);
			}
		}

		if (failures.length > 0) {
			console.error(failures.join('\\n'));
			process.exit(1);
		}
		"""

		let error = try Self.syntaxError(checking: ["--input-type=module"], input: harness)
		#expect(error == nil, "\(error ?? "")")
	}

	/**
	The email check of the feedback form suggests the common domain that a typo meant, and leaves a real domain that is close to a common one as it is. It runs the module in `node`, with its import of the edit distance as a `data:` URL.
	*/
	@Test(.enabled(if: Self.checksScripts, "Install Node.js to run the email check of the feedback form."))
	func `the email check of the feedback form finds the domain that the visitor meant`() throws {
		let editDistanceModule = try String(contentsOf: Project.website.publicFile(#path("/scripts/edit-distance.js")), encoding: .utf8)
		let emailTyposModule = try String(contentsOf: Project.website.publicFile(#path("/scripts/email-typos.js")), encoding: .utf8)

		// The domain that the check suggests, or the domain itself when it looks right, or `""` for a domain that no reply can reach.
		let domains = [
			"gmial.com": "gmail.com",
			"gmail.co": "gmail.com",
			"gmail.con": "gmail.com",
			// An ending that stops early.
			"gmail.c": "gmail.com",
			// A typo of the ending of another provider, which is not one of the common domains.
			"hotmail.ney": "hotmail.net",
			"gmail": "gmail.com",
			"gmailcom": "gmail.com",
			"icluod.com": "icloud.com",
			"protonmial.com": "protonmail.com",
			"hotmail.ca": "hotmail.ca",
			"protonmail.ch": "protonmail.ch",
			"gmail.co.uk": "gmail.co.uk",
			"mail.com": "mail.com",
			"me.com": "me.com",
			"ymail.com": "ymail.com",
			"fastmail.com": "fastmail.com",
			"fastm": "",
		]

		let harness = """
		const editDistanceURL = `data:text/javascript,${encodeURIComponent(\(JSONEncoder.pageJSON(editDistanceModule)))}`;
		const emailTypos = \(JSONEncoder.pageJSON(emailTyposModule)).replace("'/scripts/edit-distance.js'", JSON.stringify(editDistanceURL));
		const {intendedDomain} = await import(`data:text/javascript,${encodeURIComponent(emailTypos)}`);
		const failures = [];

		for (const [domain, expected] of Object.entries(\(JSONEncoder.pageJSON(domains)))) {
			const intended = intendedDomain(domain) ?? '';

			if (intended !== expected) {
				failures.push(`${domain} gives ${JSON.stringify(intended)}, not ${JSON.stringify(expected)}`);
			}
		}

		if (failures.length > 0) {
			console.error(failures.join('\\n'));
			process.exit(1);
		}
		"""

		let error = try Self.syntaxError(checking: ["--input-type=module"], input: harness)
		#expect(error == nil, "\(error ?? "")")
	}

	/**
	The app picker of the feedback page and Appdle compare names without case, accents, spaces, and punctuation, and find the closest name for a typo, with at most one edit for each 5 characters.
	*/
	@Test(.enabled(if: Self.checksScripts, "Install Node.js to run the name matcher."))
	func `the name matcher finds a name without its spaces and punctuation, and with a typo`() throws {
		let editDistanceModule = try String(contentsOf: Project.website.publicFile(#path("/scripts/edit-distance.js")), encoding: .utf8)

		let harness = """
		const {searchKey, closest} = await import(`data:text/javascript,${encodeURIComponent(\(JSONEncoder.pageJSON(editDistanceModule)))}`);
		const names = ['DS_Store Inspector', 'Gifski', 'System Color Picker', 'Dato', 'Café Cup'];
		const closestName = query => closest(searchKey(query), names, {key: searchKey}) ?? '';

		const cases = {
			'dsstore inspector': 'DS_Store Inspector',
			'ds store inspector': 'DS_Store Inspector',
			'system color-picker': 'System Color Picker',
			'cafe cup': 'Café Cup',
			gifksi: 'Gifski',
			gifsky: 'Gifski',
			daot: '',
			xyz: '',
		};

		const failures = Object.entries(cases)
			.filter(([query, expected]) => closestName(query) !== expected)
			.map(([query, expected]) => `${query} finds ${JSON.stringify(closestName(query))}, not ${JSON.stringify(expected)}`);

		if (failures.length > 0) {
			console.error(failures.join('\\n'));
			process.exit(1);
		}
		"""

		let error = try Self.syntaxError(checking: ["--input-type=module"], input: harness)
		#expect(error == nil, "\(error ?? "")")
	}

	/**
	Runs `node` with the arguments, like `--check`, and the input, and returns what it writes to the standard error when it fails, or `nil` when the script is valid.
	*/
	private static func syntaxError(checking arguments: [String], input: String = "") throws -> String? {
		let process = Process()
		process.executableURL = URL(filePath: "/usr/bin/env")
		process.arguments = ["node"] + arguments
		let inputPipe = Pipe()
		let errors = Pipe()
		process.standardInput = inputPipe
		process.standardError = errors
		try process.run()
		try inputPipe.fileHandleForWriting.write(contentsOf: Data(input.utf8))
		try inputPipe.fileHandleForWriting.close()
		process.waitUntilExit()

		guard process.terminationStatus != 0 else {
			return nil
		}

		return String(decoding: errors.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
	}

	/**
	The tags that the scripts of the page define: the scripts that it loads, and its inline scripts.
	*/
	private static func definedTagNames(in html: String) throws -> [String] {
		// The scripts of the site, not the counter of another site.
		let scriptTags = html.scriptTags
		let loaded = try scriptTags.compactMap(\.source).filter { $0.hasPrefix("/") }.map { source in
			let path = RoutePath(String(source.prefix { $0 != "?" }))
			let file = scripts.first { $0.path == path }?.source ?? Project.website.publicFile(path)
			return try String(contentsOf: file, encoding: .utf8)
		}

		let inline = scriptTags.filter { $0.source == nil && $0.type == "module" }.map { String($0.body) }

		return (loaded + inline).flatMap { $0.matches(of: /customElements\.define\('([^']+)'/).map { String($0.1) } }
	}

	/**
	An element without its script does nothing, so each custom element on a page must be defined by a script that the page loads, once, as a second definition throws.
	*/
	@Test
	func `every custom element on a page is defined by a script of the page, once`() async throws {
		for page in try await Self.site.value.pages {
			// Without the scripts, the comments, and the values of attributes, as their text is not markup, like the code that the copy button of a code block copies, which can have `<app-name>`.
			let markup = page.html.replacing(/<script\b.*?<\/script>|<!--.*?-->|="[^"]*"/.dotMatchesNewlines(), with: "")
			let usedTagNames = Set(markup.matches(of: /<([a-z][a-z0-9]*(?:-[a-z0-9]+)+)[\s\/>]/).map { String($0.1) })
			let definedTagNames = try Self.definedTagNames(in: page.html)

			#expect(usedTagNames.subtracting(definedTagNames).sorted() == [], "\(page.path) has custom elements that no script of the page defines.")
			#expect(Set(definedTagNames).count == definedTagNames.count, "\(page.path) defines a tag more than once, which throws: \(definedTagNames.sorted())")
		}
	}

	/**
	Whether to check the scripts with `node`. Without Node.js, the checks are skipped, except on CI, where they fail, so they cannot stop running without notice.
	*/
	private static var checksScripts: Bool {
		ProcessInfo.processInfo.environment["CI"] != nil || isNodeAvailable
	}

	private static var isNodeAvailable: Bool {
		let process = Process()
		process.executableURL = URL(filePath: "/usr/bin/env")
		process.arguments = ["node", "--version"]
		process.standardOutput = FileHandle.nullDevice
		process.standardError = FileHandle.nullDevice

		guard (try? process.run()) != nil else {
			return false
		}

		process.waitUntilExit()
		return process.terminationStatus == 0
	}

	/**
	The script without its comment lines, so a part in a comment is not a use.
	*/
	private static func code(of script: String) -> String {
		script
			.split(separator: "\n")
			.filter { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("//") }
			.joined(separator: "\n")
	}

	/**
	The parts that a script uses directly: `this.parts.screen`, `const {screen, status} = this.parts;` (also with `screen: name`), and `data-part="key"`, like in `querySelectorAll('[data-part="key"]')` for a list of the same part. Not `game.parts.filter` or `const {width} = this.parts.canvas`, which are not parts. A function that gets `this.parts`, like `setUpNapster(this, this.parts)`, counts when it destructures them in its parameters, like `const setUpNapster = (napster, {search: searchForm, query}) =>`. When it reads them in its body, they are only checked when it runs.

	The word boundaries are simple, as the default Unicode ones treat `this.parts.odds` as one word. A pattern starts with `(?:^|\W)` instead of a word boundary, which is about three times as slow, as it is checked at every character of the scripts.
	*/
	private static func usedParts(in script: String) -> Set<String> {
		let members = script.matches(of: /(?:^|\W)this\.parts\.(\w+)/).map { String($0.1) }

		let destructured = script.matches(of: /\{([\w\s,:]+)\}\s*=\s*this\.parts\b(?![.\[])/.wordBoundaryKind(.simple)).flatMap { names(in: $0.1) }

		let selected = script.matches(of: /data-part="(\w+)"/).map { String($0.1) }

		let setUpFunctions = Set(script.matches(of: /(?:^|\W)(\w+)\(this,\s*this\.parts\)/).map { String($0.1) })
		let parameters = script.matches(of: /(?:^|\W)const (\w+) = \(\s*\w+\s*,\s*\{([\w\s,:]+)\}\s*\)\s*=>/)
			.filter { setUpFunctions.contains(String($0.1)) }
			.flatMap { names(in: $0.2) }

		let cloned = clonedParts(in: script)

		return Set(members + destructured + selected + parameters).union(cloned)
	}

	/**
	The parts that a script uses through a copy of a template (`clone()` of `scripted-element.js`): the template, like `rowTemplate` in `this.clone('rowTemplate')` or `napster.clone('resultTemplate')`, the parts that it destructures from the copy, like `name` and `size` in `const {element: row, parts: {name, size}} = this.clone('rowTemplate');`, and for `const {element: row, parts} = this.clone('rowTemplate');` (also with `parts: rowParts`), the members of the parts, like `parts.name`, in the rest of the block of the copy, which ends at the first line that is indented less, so another `parts`, like a list, is not read as parts.
	*/
	private static func clonedParts(in script: String) -> Set<String> {
		var used = Set(script.matches(of: /\.clone\('(\w+)'\)/).map { String($0.1) })
		let lines = script.split(separator: "\n", omittingEmptySubsequences: false)

		func indentation(of line: Substring) -> Int {
			line.prefix { $0 == "\t" || $0 == " " }.count
		}

		for (index, line) in lines.enumerated() {
			// The plain search first, as the pattern is slow on long lines with many braces.
			guard
				line.contains(".clone('"),
				let copy = line.firstMatch(of: /\{(.*)\}\s*=\s*[\w.#]+\.clone\('\w+'\)/)
			else {
				continue
			}

			if let destructured = copy.1.firstMatch(of: /\bparts\s*:\s*\{([\w\s,:]+)\}/.wordBoundaryKind(.simple)) {
				used.formUnion(names(in: destructured.1))
				continue
			}

			guard let variable = copy.1.firstMatch(of: /\bparts(?:\s*:\s*(\w+))?\s*(?:,|$)/.wordBoundaryKind(.simple)) else {
				continue
			}

			let name = variable.1.map(String.init) ?? "parts"
			let block = lines[(index + 1)...].prefix { $0.allSatisfy(\.isWhitespace) || indentation(of: $0) >= indentation(of: line) }

			for blockLine in block {
				used.formUnion(blockLine.matches(of: /(?:^|[^\w.#])(\w+)\.(\w+)/).filter { $0.1 == name }.map { String($0.2) })
			}
		}

		return used
	}

	/**
	The keys of the config that a script reads directly: `this.config.goal`, `arcade.config.games`, `JSON.parse(this.dataset.config).perSecond`, and the destructurings of them, like `const {games: titles, prizes} = arcade.config;`. Not the keys of a value in the config, like `width` in `this.config.size.width`.
	*/
	private static func readConfigKeys(in script: String) -> Set<String> {
		let members = script.matches(of: /(?:\.config|JSON\.parse\(this\.dataset\.config\))\.(\w+)/).map { String($0.1) }

		let destructured = script.matches(of: /\{([\w\s,:]+)\}\s*=\s*(?:[\w.#]+\.config|JSON\.parse\(this\.dataset\.config\))(?![.\w])/).flatMap { names(in: $0.1) }

		return Set(members + destructured)
	}

	/**
	The names of a destructuring, like `screen` and `flip` for `screen, flip: button`.
	*/
	private static func names(in destructuring: Substring) -> [String] {
		destructuring.split(separator: ",").compactMap { $0.split(separator: ":").first?.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
	}
}

extension ScriptedElement {
	/**
	The names of the parts of the element.
	*/
	fileprivate static var declaredParts: [String] {
		Parts.allCases.map(\.rawValue)
	}

	/**
	The names of the states of the element.
	*/
	fileprivate static var declaredStates: Set<String> {
		States.rawValues
	}

	/**
	The name of the type of the states of the element, without the name of the module, like `CopyButton.States`.
	*/
	fileprivate static var statesName: String {
		String(reflecting: States.self).split(separator: ".").dropFirst().joined(separator: ".")
	}
}

extension ElementStateSet {
	/**
	The names of the states.
	*/
	fileprivate static var rawValues: Set<String> {
		Set(allCases.map(\.rawValue))
	}
}

extension String {
	// To the end of the path, so an import without a semicolon does not hide the code after it.
	nonisolated(unsafe) private static let importStatement = /(?m)^import\s[^;'"]*['"][^'"]*['"];?/
	nonisolated(unsafe) private static let exportList = /(?m)^export\s*\{[^}]*\}[^;\n]*;/
	nonisolated(unsafe) private static let exportDefault = /(?m)^export\s+default\s+/
	nonisolated(unsafe) private static let exportDeclaration = /(?m)^export\s+(?=const|let|var|function|class|async)/

	/**
	The syntax error of the script with its line, like `5: SyntaxError: Unexpected token ';'`, or `nil` when the script is valid. JavaScriptCore checks classic scripts, so the imports and exports of a module are removed first, with their line breaks, so the lines stay the same, and the code is in an async function, so it can `await` at the top, like a module, in strict mode, like a module. A classic script is checked in strict mode too. Limitation: It only checks the syntax, so it does not find an import of a name that the other script does not export, and as the code is in a function, it accepts a `return` at the top, and `await` at the top of a classic script.
	*/
	fileprivate var javaScriptSyntaxError: String? {
		func lineBreaks(_ match: Substring) -> String {
			String(repeating: "\n", count: match.count { $0 == "\n" })
		}

		let code = self
			.replacing(Self.importStatement) { lineBreaks($0.output) }
			.replacing(Self.exportList) { lineBreaks($0.output) }
			.replacing(Self.exportDefault, with: "void ")
			.replacing(Self.exportDeclaration, with: "")

		// The start of the function is on the first line of the code, so the lines stay the same.
		let script = JSStringCreateWithCFString("(async () => {'use strict';\(code)\n})" as CFString)

		defer {
			JSStringRelease(script)
		}

		let context = JSContext()
		var exception: JSValueRef?

		guard let context else {
			return "0: JavaScriptCore could not make a context."
		}

		guard !JSCheckScriptSyntax(context.jsGlobalContextRef, script, nil, 1, &exception) else {
			return nil
		}

		let error = JSValue(jsValueRef: exception, in: context)
		return "\(error?.forProperty("line")?.toString() ?? "?"): \(error?.toString() ?? "")"
	}

	/**
	The values that the script sets as the state of an element, like `copied` in `button.dataset.state = 'copied'`, also in a choice, like `isOn ? 'on' : ''`, but not the values that it compares, like `'over'` in `phase === 'over' ? 'urgent' : ''`. Not a state from a variable, which a test cannot read.
	*/
	var assignedDataStates: Set<String> {
		Set(matches(of: /dataset\.state\s*=(?!=)\s*([^;\n]+)/).flatMap { match in
			match.1
				.replacing(/[=!]==?\s*'[^']*'/, with: "")
				.matches(of: /'([\w-]+)'/)
				.map { String($0.1) }
		})
	}
}
