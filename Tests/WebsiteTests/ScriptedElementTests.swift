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
			let path = element.script.path
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

		// The page preloads the static imports, also through another script, but not the dynamic ones, which load only when needed.
		#expect(scripts.modulePreloads(loading: [#path("/scripts/home.js")]).map(\.description) == ["/scripts/base.js?v=\(baseHash)"])
		let boardHash = try #require(hashes[#path("/scripts/board.js")])
		#expect(scripts.modulePreloads(loading: [#path("/scripts/game.js")]).map(\.description) == ["/scripts/base.js?v=\(baseHash)", "/scripts/board.js?v=\(boardHash)"])

		// The pages load a script with its hash, and a script without one, like of another site, with its path.
		#expect(scripts.versioned(#path("/scripts/base.js")).description == "/scripts/base.js?v=\(baseHash)")
		#expect(scripts.versioned(#path("/scripts/other.js")).description == "/scripts/other.js")
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
	Like `every state of an element is set and styled`, for the states that page scripts set. A page script is not tied to one component, so a state counts as set when any page script sets it, also an inline script in a Swift source, like the one of the wall of love, or a page renders it, and as styled when the site stylesheet or a page styles it.
	*/
	@Test
	func `every state of the components of page scripts is set and styled`() async throws {
		let site = try await Self.site.value
		let pageScripts = try Project.website.publicDirectory.appending(path: "scripts").filesRecursively()
			.filter { $0.pathExtension == "js" }
			.map { Self.code(of: try String(contentsOf: $0, encoding: .utf8)) }
		let inlineScriptStates = try await SwiftSourceFile.all.value.flatMap { Self.code(of: $0.text).assignedDataStates }
		let assignedStates = Set(pageScripts.flatMap(\.assignedDataStates)).union(inlineScriptStates)
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
	The content of a template is not in the element, so `this.parts` (and `parts(this)` of `dom.js`) throws for a part that is only inside a template, and `clone()` of `scripted-element.js` copies a template part, so it throws for another part. The parts are checked against the markup that the pages render, for the direct forms of ``usedParts(in:)``. A part that a script finds itself with `data-part="name"` or `partList()` of `dom.js`, or in a copy with `parts(item)`, like in a script that extends `HTMLElement`, is not read through `this.parts`.
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
			let partsReadThroughThisParts = Self.usedParts(in: script.replacing(/^.*\.clone\('\w+'\).*$|data-part="\w+"|partList\([^,()]+,\s*'\w+'\)/.anchorsMatchLineEndings(), with: "").replacing(Self.copiedPartReads, with: ""))
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
	The keys of the data of a page that a script reads: `const {pages, feedback} = scriptData('not-found-data');` and `scriptData(…).pages` (`scriptData` of `dom.js`), or the same with `JSON.parse(document.querySelector('#geocities-data').textContent)`.
	*/
	private static func readDataKeys(in script: String, id: String) -> Set<String> {
		let sources = ["scriptData('\(id)')", "JSON.parse(document.querySelector('#\(id)').textContent)"]
		var keys = Set<String>()

		for line in script.split(separator: "\n") where sources.contains(where: line.contains) {
			if let match = line.firstMatch(of: /\{([\w\s,:]+)\}\s*=\s*(?:JSON\.parse|scriptData)\(/) {
				keys.formUnion(names(in: match.1))
			}

			keys.formUnion(line.matches(of: /(?:textContent|scriptData\('[\w-]+')\)\.(\w+)/).map { String($0.1) })
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
	func `type annotations preserve direct config reads`() {
		let script = """
		/** @example const {notAKey} = this.config; */
		const {statuses, utcOffsetMinutes} = /** @type {AwakeStatusConfig} */ (JSON.parse(/** @type {string} */ (this.dataset.config)));
		const perSecond = (JSON.parse((this.dataset.config))).perSecond;
		const {height} = (JSON.parse((this.dataset.config))).size;
		"""
		#expect(Self.readConfigKeys(in: script) == ["statuses", "utcOffsetMinutes", "perSecond", "size"])
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
	A syntax error stops the whole script, like every element of a script file, and only a browser would show it. JavaScriptCore checks the syntax without Node.js: the scripts of the elements, the published script files, like the page scripts and the scripts of the page bundles, and the inline scripts of the pages.
	*/
	@Test
	func `every script is valid JavaScript`() async throws {
		let site = try await Self.site.value
		let publishedScripts = try Project.website.publicFiles()
			.filter { $0.source.pathExtension == "js" }
			.map { (name: $0.path.description, text: try String(contentsOf: $0.source, encoding: .utf8)) }
		let pageScripts = site.pages.flatMap { page in
			page.html.matches(of: /<script(?: type="module")?>(.*?)<\/script>/.dotMatchesNewlines()).map { (name: "An inline script of \(page.path)", text: String($0.1)) }
		}

		#expect(publishedScripts.count > 20)
		#expect(!pageScripts.isEmpty)

		for script in Self.scripts.map({ (name: $0.path.description, text: $0.text) }) + publishedScripts + pageScripts {
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
	The board decodes the codes of Pipoku, which are the same as in the tests of the app, and rejects every other code, so it shows the puzzles that the app opens. It runs the script of the element in `node`, with only the parts of the DOM that it uses, and stand-ins for the helpers of `dom.js` that it imports.
	*/
	@Test(.enabled(if: Self.checksScripts, "Install Node.js to run the script of the sudoku board."))
	func `the sudoku board shows the puzzle of a Pipoku code`() throws {
		// Without its imports, which a function body cannot have, so the harness passes stand-ins for them.
		let script = try SudokuBoard.script.source
			.split(separator: "\n", omittingEmptySubsequences: false)
			.filter { !$0.hasPrefix("import ") }
			.joined(separator: "\n")

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

		// The stand-ins for `cloneTemplate` and `parts` of `dom.js`, and the definition of the element, which gives the harness its class.
		let SudokuBoard;
		new Function('cloneTemplate', 'parts', 'customElements', \(JSONEncoder.pageJSON(script)))(
			template => template.content.firstElementChild.cloneNode(true),
			board => board.parts,
			{
				define(name, constructor) {
					SudokuBoard = constructor;
				},
			},
		);

		const queryName = \(JSONEncoder.pageJSON(SudokuBoard.queryName));

		// The cells in reading order, with 0 for an empty cell, or `undefined` when the board shows that the link is invalid.
		const show = code => {
			globalThis.location = {search: '?' + new URLSearchParams({[queryName]: code})};
			const template = {content: {firstElementChild: element()}};
			const parts = {board: element(), invalid: element(), boxTemplate: template, cellTemplate: template};
			const board = new SudokuBoard();
			board.parts = parts;
			board.dataset = {config: JSON.stringify({queryName})};
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
	The 404 page suggests the page that a mistyped or guessed path meant, also when a word is added or left out, and nothing for a path that is not close to a page. It runs the page script in `node` with the paths of the page, a stand-in for `scriptData` of `dom.js`, and only the parts of the DOM that it uses.
	*/
	@Test(.enabled(if: Self.checksScripts, "Install Node.js to run the script of the 404 page."))
	func `the 404 page suggests the closest page`() async throws {
		let page = try #require(try await Self.site.value.pages.first { $0.path == .notFound })
		let paths = try #require(page.html.firstMatch(of: /<script[^>]*id="not-found-data"[^>]*>(.*?)<\/script>/)?.1)
		// Without its imports, which a function body cannot have, so the harness imports the module of the edit distance and passes its functions.
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
			// Some words of a long last part, in any order.
			"/guides/flush-dns": "/guides/flush-dns-cache-mac",
			"/guides/video-to-gif": "/guides/convert-video-to-gif-mac",
			"/about-me": "/about",
			"/apps/macos-apps": "/apps/macos",
			// A page in a folder, from its last part.
			"/faq": "/apps/faq",
			"/terms": "/apps/terms",
			// The page with the requested last part, not a page that is only close, like `/shortcutie` and `/menu-bar-spacing`.
			"/shortcuts": "/apps/shortcuts",
			"/menu-bar": "/apps/menu-bar",
			// Help words lead to the feedback form, not to the closest path, like `/supporters`.
			"/support": "/feedback",
			"/dato/support": "/feedback?product=Dato",
			"/dato/feedback": "/feedback?product=Dato",
			"/feedback/dato": "/feedback?product=Dato",
			"/apps/dato/feedback": "/feedback?product=Dato",
			"/dato/suport": "/feedback?product=Dato",
			"/suport/dato": "/feedback?product=Dato",
			"/datoo/support": "/feedback",
			// A last part of several pages says nothing about the page, so the page of the app.
			"/dato/release-notes": "/dato",
			"/dato/faq": "/dato#faq",
			"/apps/faq/dato": "/dato#faq",
			// A help word alone requires an exact match, so the contact page keeps its spelling correction.
			"/contacts": "/contact",
			// The query and the fragment of the request stay, when the suggestion has none.
			"/dato/#faq": "/dato#faq",
			"/velja/?ref=newsletter#browser-profiles": "/velja?ref=newsletter#browser-profiles",
			"/dato/support?metadata=1": "/feedback?product=Dato",
			"/support?product=Dato": "/feedback?product=Dato",
			// A name of a device finds the page of its platform, not a path that is only close, like `/apps/paid` for `/apps/ipad`.
			"/apps/ipad": "/apps/ios",
			"/iphone": "/apps/ios",
			"/mac": "/apps/macos",
			"/apps/apple-watch": "/apps/watchos",
			"/how": "",
			"/x": "",
		]

		let harness = """
		const editDistanceModule = await import(`data:text/javascript,${encodeURIComponent(\(JSONEncoder.pageJSON(editDistanceModule)))}`);
		const failures = [];

		for (const [path, expected] of Object.entries(\(JSONEncoder.pageJSON(suggestions)))) {
			const elements = {
				'#closest-page-link': {hidden: true},
				'#home-link': {},
			};

			new Function('document', 'location', 'scriptData', ...Object.keys(editDistanceModule), \(JSONEncoder.pageJSON(script)))({querySelector: selector => elements[selector]}, new URL(path, 'https://sindresorhus.com'), () => JSON.parse(\(JSONEncoder.pageJSON(String(paths)))), ...Object.values(editDistanceModule));
			const suggestion = elements['#closest-page-link'].hidden ? '' : elements['#closest-page-link'].href;

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
	The app picker of the feedback page compares names without case, accents, spaces, and punctuation, and finds the closest name for a typo, with at most one edit for each 4 characters.
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
			// A name of 4 letters accepts one typo.
			daot: 'Dato',
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

	@Test(.enabled(if: Self.checksScripts, "Install Node.js to check package pagination."))
	func `npm packages show in batches and filtering searches the full list`() throws {
		let harness = #"""
		import assert from 'node:assert/strict';
		import fs from 'node:fs';
		import test from 'node:test';
		import vm from 'node:vm';

		const {searchKey, filterByWords} = await import('data:text/javascript,' + encodeURIComponent(fs.readFileSync('public/scripts/edit-distance.js', 'utf8')));
		const script = fs.readFileSync('Sources/Website/Components/Scripts/NPMPackageList.js', 'utf8').replaceAll(/^import .*\n/gm, '');

		test('pagination, full-list search, and resetting the filter', () => {
			const history = {
				state: null,
				replaceState(state) {
					this.state = state;
				},
			};
			let Component;
			let focused;
			let opened;
			let highlights;
			vm.runInNewContext(script, {
				HTMLElement: class {},
				customElements: {
					define(name, component) {
						Component = component;
					},
				},
				parts: element => element.parts,
				partList: (element, name) => element.partLists[name],
				searchKey,
				filterByWords,
				history,
				URL,
				document: {
					createTreeWalker(node) {
						let visited = false;
						return {
							currentNode: node,
							nextNode() {
								const hasNext = !visited;
								visited = true;
								return hasNext;
							},
						};
					},
				},
				NodeFilter: {SHOW_TEXT: 4},
				CSS: {
					highlights: {
						set() {},
					},
				},
				Highlight: class {
					constructor(...ranges) {
						highlights = ranges.map(range => range.node.data.slice(range.start, range.end));
					}
				},
				Range: class {
					setStart(node, offset) {
						assert.ok(offset >= 0 && offset <= node.data.length);
						this.node = node;
						this.start = offset;
					}
					setEnd(node, offset) {
						assert.equal(node, this.node);
						assert.ok(offset >= this.start && offset <= node.data.length);
						this.end = offset;
					}
				},
			});
			const control = () => ({
				hidden: false,
				value: '',
				listeners: {},
				addEventListener(type, listener) {
					this.listeners[type] = listener;
				},
			});
			const filter = control();
			const showMore = control();
			const npmSearch = {hidden: true, href: 'https://www.npmjs.com/search?q=maintainer%3Asindresorhus'};
			const rows = Array.from({length: 45}, (_, index) => ({
				hidden: false,
				parts: {
					text: {
						textContent: `package-${index} ${index >= 40 ? 'unique description' : 'common description'}`,
						get data() {
							return this.textContent;
						},
					},
					link: {
						textContent: `package-${index}`,
						focus() {
							focused = index;
						},
						click() {
							opened = index;
						},
					},
				},
			}));
			// A description match must follow the package whose name matches, even when it has more downloads.
			rows[0].parts.text.textContent += ' package-42 İ MATCH MATCH a+b';
			const orderedRows = [];
			const element = new Component();
			element.parts = {
				filter,
				showMore,
				status: {textContent: ''},
				npmSearch,
				list: {
					append(...appendedRows) {
						orderedRows.splice(0, orderedRows.length, ...appendedRows);
					},
				},
			};
			element.getAttribute = name => name === 'page-size' ? '20' : null;
			element.partLists = {row: rows};
			element.connectedCallback();
			const visible = () => orderedRows.filter(row => !row.hidden);
			assert.equal(visible().length, 20);
			assert.equal(rows[20].hidden, 'until-found');
			assert.equal(showMore.hidden, false);
			assert.equal(showMore.textContent, 'Show 20 more');
			showMore.listeners.click();
			assert.equal(visible().length, 40);
			assert.equal(focused, 20);
			// A reload shows as many rows again.
			assert.equal(history.state.npmVisibleCount, 40);
			const restoredElement = new Component();
			restoredElement.parts = {filter: control(), showMore: control(), status: {textContent: ''}, npmSearch, list: element.parts.list};
			restoredElement.getAttribute = element.getAttribute;
			restoredElement.partLists = {row: rows};
			restoredElement.connectedCallback();
			assert.equal(visible().length, 40);
			assert.equal(restoredElement.parts.showMore.textContent, 'Show 5 more');
			assert.equal(showMore.textContent, 'Show 5 more');
			showMore.listeners.click();
			assert.equal(visible().length, 45);
			assert.equal(showMore.hidden, true);
			assert.equal(focused, 40);
			filter.value = 'package-42';
			filter.listeners.input();
			assert.deepEqual(visible(), [rows[42], rows[0]]);
			filter.listeners.keydown({key: 'Enter', isComposing: false});
			assert.equal(opened, 42);
			filter.value = 'common description';
			filter.listeners.input();
			assert.equal(visible().length, 20);
			assert.equal(showMore.hidden, false);
			showMore.listeners.click();
			assert.equal(visible().length, 40);
			assert.equal(showMore.hidden, true);
			filter.value = 'unique description';
			filter.listeners.input();
			assert.equal(visible().length, 5);
			assert.equal(visible()[0], rows[40]);
			assert.equal(showMore.hidden, true);
			filter.value = 'no match';
			filter.listeners.input();
			assert.equal(visible().length, 0);
			assert.match(element.parts.status.textContent, /No package of the list matches/);
			// The search on npm keeps the maintainer and adds the words of the filter.
			assert.equal(npmSearch.hidden, false);
			assert.equal(npmSearch.href, 'https://www.npmjs.com/search?q=maintainer%3Asindresorhus+no+match');
			// A typo shows the package with the closest name, and Enter opens the first package that shows.
			filter.value = 'pakcage-42';
			filter.listeners.input();
			assert.deepEqual(visible(), [rows[42]]);
			assert.equal(showMore.hidden, true);
			filter.listeners.keydown({key: 'Enter', isComposing: false});
			assert.equal(opened, 42);
			assert.deepEqual(highlights, []);
			// Case conversion can change UTF-16 length, so ranges must use the original text offsets.
			filter.value = 'a+b';
			filter.listeners.input();
			assert.deepEqual(highlights, ['a+b']);
			filter.value = 'match';
			filter.listeners.input();
			assert.deepEqual(highlights, ['MATCH', 'MATCH']);
			filter.value = '';
			filter.listeners.input();
			assert.equal(visible().length, 20);
			assert.equal(showMore.hidden, false);
			assert.deepEqual(highlights, []);
		});
		"""#
		let error = try Self.syntaxError(checking: ["--input-type=module"], input: harness)
		#expect(error == nil, "\(error ?? "")")
	}

	@Test(.enabled(if: Self.checksScripts, "Install Node.js to check reduced-motion behavior."))
	func `the apps glass skips WebGL with reduced motion and keeps its fallback without a renderer`() throws {
		let script = try String(contentsOf: Project.website.publicFile(#path("/scripts/apps-glass.js")), encoding: .utf8)
			.split(separator: "\n", omittingEmptySubsequences: false)
			.filter { !$0.hasPrefix("import ") }
			.joined(separator: "\n")
		let harness = """
		import assert from 'node:assert/strict';
		import test from 'node:test';

		for (const prefersReducedMotion of [true, false]) {
			test(`WebGL fallback with reduced motion ${prefersReducedMotion}`, () => {
				let contextRequests = 0;
				const canvas = {
					getContext() {
						contextRequests++;
					},
				};
				const document = {querySelector: () => canvas};
				const startShader = () => assert.fail('No shader should start without a rendering context.');
				new Function('document', 'prefersReducedMotion', 'startShader', \(JSONEncoder.pageJSON(script)))(document, prefersReducedMotion, startShader);
				assert.equal(contextRequests, prefersReducedMotion ? 0 : 1);
			});
		}
		"""
		let error = try Self.syntaxError(checking: ["--input-type=module"], input: harness)
		#expect(error == nil, "\(error ?? "")")
	}

	@Test(.enabled(if: Self.checksScripts, "Install Node.js to check audio playback."))
	func `restarting audio stays on the page and blocked playback opens the clip`() throws {
		let script = try String(contentsOf: Project.website.publicFile(#path("/scripts/site.js")), encoding: .utf8)
			.split(separator: "\n", omittingEmptySubsequences: false)
			.filter { !$0.hasPrefix("import ") }
			.joined(separator: "\n")
		let harness = """
		import assert from 'node:assert/strict';
		import test from 'node:test';
		import vm from 'node:vm';

		async function playClip(isBlocked) {
			const listeners = [];
			const navigations = [];
			let pending;
			class Audio {
				set src(value) {
					pending?.reject(new DOMException('New load request', 'AbortError'));
				}
				play() {
					if (isBlocked) {
						return Promise.reject(new DOMException('Playback blocked', 'NotAllowedError'));
					}
					pending = Promise.withResolvers();
					return pending.promise;
				}
			}
			vm.runInNewContext(\(JSONEncoder.pageJSON(script)), {
				Audio,
				HTMLDetailsElement: class {},
				console: {log() {}},
				history: {state: null, replaceState() {}},
				document: {
					querySelector() {},
					addEventListener(type, callback) {
						if (type === 'click') {
							listeners.push(callback);
						}
					},
				},
				window: {addEventListener() {}},
				// A Mac, so the links to System Settings stay links.
				isMac: true,
				matchMedia: () => ({matches: false}),
				finePointer: {matches: false},
				elementForFragment() {},
				location: {
					set href(value) {
						navigations.push(value);
					},
				},
			});
			const event = {
				target: {
					closest(selector) {
						return selector === 'a[href$=".m4a"]' ? {href: '/name.m4a'} : undefined;
					},
				},
				button: 0,
				preventDefault() {},
			};
			for (let index = 0; index < (isBlocked ? 1 : 2); index++) {
				for (const listener of listeners) {
					listener(event);
				}
			}
			pending?.resolve();
			await new Promise(resolve => setImmediate(resolve));
			return navigations;
		}
		test('restarting pending playback does not navigate', async () => {
			assert.deepEqual(await playClip(false), []);
		});
		test('blocked playback opens the clip', async () => {
			assert.deepEqual(await playClip(true), ['/name.m4a']);
		});
		"""
		let error = try Self.syntaxError(checking: ["--input-type=module"], input: harness)
		#expect(error == nil, "\(error ?? "")")
	}

	/**
	Checks the actual music implementations with controlled timers and audio resume promises.
	*/
	@Test(.enabled(if: Self.checksScripts, "Install Node.js to check music ownership."))
	func `music scheduling and delayed audio belong to their current playback`() throws {
		let harness = #"""
		import assert from 'node:assert/strict';
		import fs from 'node:fs';
		import test from 'node:test';
		import vm from 'node:vm';

		function timers() {
			let nextId = 0;
			const intervals = new Map();
			const timeouts = new Map();
			return {
				intervals,
				timeouts,
				setInterval(callback) {
					intervals.set(++nextId, callback);
					return nextId;
				},
				clearInterval(id) {
					intervals.delete(id);
				},
				setTimeout(callback) {
					timeouts.set(++nextId, callback);
					return nextId;
				},
				clearTimeout(id) {
					timeouts.delete(id);
				},
				fire(id) {
					const callback = timeouts.get(id);
					timeouts.delete(id);
					callback();
				},
			};
		}

		function clockEnvironment() {
			const scheduled = timers();
			const context = {currentTime: 0};
			const source = fs.readFileSync('public/scripts/geocities-sound-card.js', 'utf8');
			const start = source.indexOf('export class Clock {');
			const end = source.indexOf('\n// Saves a MIDI file', start);
			assert.ok(start >= 0 && end > start);
			const Clock = vm.runInNewContext(`${source.slice(start, end).replace('export class Clock', 'class Clock')}\nClock`, {context, ...scheduled});
			return {Clock, context, scheduled};
		}

		test('finishing Clock scheduling releases its interval and drains queued work', () => {
			const {Clock, scheduled} = clockEnvironment();
			const clock = new Clock({stepLength: () => 1, onStep() {}});
			let calls = 0;
			assert.equal(clock.isRunning, false);
			clock.start();
			clock.atTime(1, () => {
				calls++;
			});
			clock.finishScheduling();
			assert.equal(clock.isRunning, false);
			assert.equal(scheduled.intervals.size, 0);
			assert.equal(scheduled.timeouts.size, 1);
			scheduled.fire(scheduled.timeouts.keys().next().value);
			assert.equal(calls, 1);
		});

		test('Clock stop cancels scheduling and queued work, including after normal finish', () => {
			for (const shouldFinish of [false, true]) {
				const {Clock, scheduled} = clockEnvironment();
				const clock = new Clock({stepLength: () => 1, onStep() {}});
				clock.start();
				clock.atTime(1, () => assert.fail('Canceled work must not run.'));
				if (shouldFinish) {
					clock.finishScheduling();
				}
				clock.stop();
				clock.stop();
				assert.equal(clock.isRunning, false);
				assert.equal(scheduled.intervals.size, 0);
				assert.equal(scheduled.timeouts.size, 0);
			}
		});

		test('restarting Clock cancels old callbacks and owns one scheduler', () => {
			const {Clock, scheduled} = clockEnvironment();
			const steps = [];
			const clock = new Clock({stepLength: () => 1, onStep: step => steps.push(step)});
			clock.start();
			clock.atTime(1, () => assert.fail('Previous playback must be canceled.'));
			clock.start();
			assert.equal(clock.isRunning, true);
			assert.equal(scheduled.intervals.size, 1);
			assert.equal(scheduled.timeouts.size, 0);
			assert.deepEqual(steps, [0, 0]);
		});

		test('finishing from onStep immediately ends the Clock lookahead loop', () => {
			const {Clock, scheduled} = clockEnvironment();
			const steps = [];
			const clock = new Clock({stepLength: () => 0.01, onStep(step) {
				steps.push(step);
				clock.finishScheduling();
			}});
			clock.start();
			assert.deepEqual(steps, [0]);
			assert.equal(scheduled.intervals.size, 0);
		});

		test('StampComposer releases scheduling while its final beat rings out', () => {
			const {Clock, context, scheduled} = clockEnvironment();
			const source = fs.readFileSync('Sources/Website/Pages/1999/Scripts/StampComposer.js', 'utf8');
			const start = source.indexOf('const clock = new Clock({');
			const end = source.indexOf('\n\t\tconst player =', start);
			assert.ok(start >= 0 && end > start);
			let stops = 0;
			const announcements = [];
			const columns = [];
			const bus = {};
			const playedNotes = [];
			const player = {stop() {
				stops++;
				clock.stop();
			}};
			const clock = vm.runInNewContext(`${source.slice(start, end)}\nclock`, {
				Clock,
				tempoInput: {value: '120'},
				lastColumn: 3,
				song: [[{stamp: 'star', position: 4}], [], [], []],
				bus,
				playStamp: (stamp, position, time, destination) => playedNotes.push({stamp, position, time, destination}),
				playingColumn: -1,
				columnX: column => column * 10,
				runner: {style: {}},
				draw() {},
				scrollTo: column => columns.push(column),
				reducedMotion: true,
				player,
				say: message => announcements.push(message),
			});
			clock.start();
			assert.equal(clock.isRunning, true);
			context.currentTime = 2;
			for (const callback of scheduled.intervals.values()) {
				callback();
			}
			assert.equal(clock.isRunning, false);
			assert.equal(scheduled.intervals.size, 0);
			assert.equal(stops, 0);
			assert.deepEqual(playedNotes, [{stamp: 'star', position: 4, time: 0.08, destination: bus}]);
			assert.equal(scheduled.timeouts.size, 5);
			for (const id of scheduled.timeouts.keys()) {
				scheduled.fire(id);
			}
			assert.deepEqual(columns, [0, 1, 2, 3]);
			assert.equal(stops, 1);
			assert.deepEqual(announcements, ['Bravo! 👏']);
		});

		function musicEnvironment(kind, {hasAudio = true} = {}) {
			const scheduled = timers();
			const resumeRequests = [];
			const notes = [];
			const gains = [];
			const context = {
				state: 'running',
				currentTime: 0,
				sampleRate: 4,
				resume() {
					const request = Promise.withResolvers();
					resumeRequests.push(request);
					return request.promise;
				},
			};
			const audio = {context, output: {}};
			const makeControl = () => ({dataset: {}, attributes: {}, setAttribute(name, value) {
				this.attributes[name] = value;
			}});
			const buttons = ['bjelleklang', 'glade-jul'].map(id => ({...makeControl(), dataset: {christmasMusic: id}}));
			class GeoCitiesElement {
				parts = Object.fromEntries(['light', 'music', 'sister', 'chat', 'bed', 'batteries', 'flip', 'nsa', 'sound'].map(name => [name, makeControl()]));
				musicEvents = [];
				sound() {
					return hasAudio ? audio : undefined;
				}
				music(isPlaying) {
					this.musicEvents.push(isPlaying);
				}
				querySelectorAll() {
					return buttons;
				}
			}
			class GainNode {
				constructor() {
					gains.push(this);
				}
				gain = {setValueAtTime() {}, linearRampToValueAtTime() {}, exponentialRampToValueAtTime() {}, setTargetAtTime() {}};
				connect(destination) {
					return destination;
				}
				disconnect() {
					this.isDisconnected = true;
				}
			}
			class OscillatorNode {
				frequency = {setValueAtTime() {}, exponentialRampToValueAtTime() {}};
				connect(destination) {
					return destination;
				}
				start() {
					notes.push(this);
				}
				stop() {}
			}
			const path = `Sources/Website/Pages/1999/Scripts/${kind}.js`;
			const source = fs.readFileSync(path, 'utf8').replace(/^import .*\n/gm, '');
			// Add entry points only inside the evaluated test copy; the real music methods and private fields run unchanged.
			const bridge = kind === 'Furby' ? `
				startMusicForTest() {
					this.#furby = {hasBatteries: true};
					this.#startMusic();
				}
				get isDancingForTest() {
					return this.#isDancing;
				}
				otherMusicForTest() {
					this.#otherMusic.add('another-toy');
				}
			` : `
				startMusicForTest(id) {
					this.#playSong(id);
				}
			`;
			const end = source.lastIndexOf('\n}\n\ncustomElements.define(');
			assert.ok(end > 0);
			let Element;
			vm.runInNewContext(source.slice(0, end) + bridge + source.slice(end), {
				GeoCitiesElement,
				GainNode,
				OscillatorNode,
				AudioBufferSourceNode: OscillatorNode,
				BiquadFilterNode: OscillatorNode,
				AudioBuffer: class {
					getChannelData() {
						return new Float32Array(8);
					}
				},
				customElements: {define(name, value) {
					Element = value;
				}},
				midiFrequency: note => 440 * (2 ** ((note - 69) / 12)),
				randomBetween: (minimum, maximum) => (minimum + maximum) / 2,
				...scheduled,
			});
			return {element: new Element(), scheduled, resumeRequests, notes, gains, buttons};
		}

		async function resume(requests) {
			for (const request of requests.splice(0)) {
				request.resolve();
			}
			await Promise.resolve();
		}

		for (const kind of ['Furby', 'Christmas']) {
			test(`${kind} stopped before audio resumes cannot schedule notes`, async () => {
				const {element, scheduled, resumeRequests, notes} = musicEnvironment(kind);
				element.startMusicForTest('bjelleklang');
				element.musicStopped();
				await resume(resumeRequests);
				assert.equal(notes.length, 0);
				assert.equal(scheduled.timeouts.size, 0);
				assert.deepEqual(element.musicEvents, [true, false]);
			});

			test(`${kind} replaced playback ignores the previous pending resume`, async () => {
				const {element, scheduled, resumeRequests, notes} = musicEnvironment(kind);
				element.startMusicForTest('bjelleklang');
				const previousResume = resumeRequests.splice(0);
				if (kind === 'Furby') {
					element.musicStopped();
				}
				element.startMusicForTest('glade-jul');
				await resume(previousResume);
				assert.equal(notes.length, 0);
				assert.equal(scheduled.timeouts.size, 0);
				await resume(resumeRequests);
				assert.ok(notes.length > 0);
				assert.equal(scheduled.timeouts.size, 1);
				element.musicStopped();
				assert.equal(scheduled.timeouts.size, 0);
			});

			test(`${kind} unavailable audio leaves music idle`, () => {
				const {element, scheduled} = musicEnvironment(kind, {hasAudio: false});
				element.startMusicForTest('bjelleklang');
				element.musicStopped();
				assert.deepEqual(element.musicEvents, []);
				assert.equal(scheduled.timeouts.size, 0);
			});
		}

		test('Furby music controls and dancing follow its gain ownership', async () => {
			const {element, gains, resumeRequests} = musicEnvironment('Furby');
			element.startMusicForTest();
			assert.equal(element.parts.music.attributes['aria-pressed'], 'true');
			assert.equal(element.parts.music.textContent, 'Stop the Music');
			assert.equal(element.isDancingForTest, true);
			await resume(resumeRequests);
			element.musicStopped();
			assert.equal(gains[0].isDisconnected, true);
			assert.equal(element.parts.music.attributes['aria-pressed'], 'false');
			assert.equal(element.parts.music.textContent, 'Play Music');
			assert.equal(element.isDancingForTest, false);
			element.otherMusicForTest();
			assert.equal(element.isDancingForTest, true);
		});

		test('Christmas replacement keeps one music event and stale completion cannot stop it', async () => {
			const {element, scheduled, resumeRequests, buttons} = musicEnvironment('Christmas');
			element.startMusicForTest('bjelleklang');
			await resume(resumeRequests);
			const staleCompletion = scheduled.timeouts.values().next().value;
			element.startMusicForTest('glade-jul');
			assert.deepEqual(element.musicEvents, [true, true]);
			assert.equal(buttons[0].attributes['aria-pressed'], 'false');
			assert.equal(buttons[1].attributes['aria-pressed'], 'true');
			staleCompletion();
			assert.equal(buttons[1].attributes['aria-pressed'], 'true');
			await resume(resumeRequests);
			assert.equal(scheduled.timeouts.size, 1);
			scheduled.fire(scheduled.timeouts.keys().next().value);
			assert.equal(buttons[1].attributes['aria-pressed'], 'false');
			assert.deepEqual(element.musicEvents, [true, true, false]);
		});
		"""#
		let error = try Self.syntaxError(checking: ["--input-type=module"], input: harness)
		#expect(error == nil, "\(error ?? "")")
	}

	/**
	Runs `node` with the arguments, like `--check`, and the input, and returns what it writes to the standard error when it fails, or `nil` when the script is valid.
	*/
	private static func syntaxError(checking arguments: [String], input: String = "") throws -> String? {
		let process = Process()
		process.currentDirectoryURL = Project.website.root
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
	The parts that a script uses directly: `this.parts.screen`, `const {screen, status} = this.parts;` (also with `screen: name`), the same with `parts(this)` of `dom.js`, like `const {panel, list} = parts(this);`, the parts of a copy with `parts()` (``copiedPartReads``), like `parts(item).link`, `data-part="key"`, like in `querySelectorAll('[data-part="key"]')`, and `partList()` of `dom.js`, like `partList(this, 'row')`, for a list of the same part. Not `game.parts.filter` or `const {width} = this.parts.canvas`, which are not parts. A function that gets `this.parts`, like `setUpNapster(this, this.parts)`, counts when it destructures them in its parameters, like `const setUpNapster = (napster, {search: searchForm, query}) =>`. When it reads them in its body, they are only checked when it runs.

	The word boundaries are simple, as the default Unicode ones treat `this.parts.odds` as one word. A pattern starts with `(?:^|\W)` instead of a word boundary, which is about three times as slow, as it is checked at every character of the scripts.
	*/
	private static func usedParts(in script: String) -> Set<String> {
		let members = script.matches(of: /(?:^|\W)(?:this\.parts|parts\(this\))\.(\w+)/).map { String($0.1) }

		let destructured = script.matches(of: /\{([\w\s,:]+)\}\s*=\s*(?:this\.parts\b|parts\(this\))(?![.\[])/.wordBoundaryKind(.simple)).flatMap { names(in: $0.1) }

		let copied = script.matches(of: copiedPartReads).flatMap { match in
			match.1.map { names(in: $0) } ?? match.2.map { [String($0)] } ?? []
		}

		let selected = script.matches(of: /data-part="(\w+)"|(?:^|\W)partList\([^,()]+,\s*'(\w+)'\)/).compactMap { match in
			(match.1 ?? match.2).map(String.init)
		}

		let setUpFunctions = Set(script.matches(of: /(?:^|\W)(\w+)\(this,\s*this\.parts\)/).map { String($0.1) })
		let parameters = script.matches(of: /(?:^|\W)const (\w+) = \(\s*\w+\s*,\s*\{([\w\s,:]+)\}\s*\)\s*=>/)
			.filter { setUpFunctions.contains(String($0.1)) }
			.flatMap { names(in: $0.2) }

		let cloned = clonedParts(in: script)

		return Set(members + destructured + selected + parameters + copied).union(cloned)
	}

	/**
	The parts of a copy of a template that a script that extends `HTMLElement` reads with `parts()` of `dom.js`, like `const {link, question} = parts(item);` or `parts(item).link`, but not `parts(this)`. The member is the last one of the statement, like `tooLargeNotice` in `parts(cloneTemplate(parts(this).template)).tooLargeNotice`.
	*/
	nonisolated(unsafe) private static let copiedPartReads = /\{([\w\s,:]+)\}\s*=\s*parts\((?!this\))[^;]*?\)|(?:^|\W)parts\((?!this\))[^;]*\)\.(\w+)/

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

	JSDoc casts can group the config expression and the JSON argument in parentheses. Their comments do not contain reads.
	*/
	private static func readConfigKeys(in script: String) -> Set<String> {
		let script = script.replacing(configTypeComments, with: " ")
		let members = script.matches(of: /(?:\.config|JSON\.parse\(\s*\(?\s*this\.dataset\.config\s*\)?\s*\))\s*\)?\s*\.(\w+)/).map { String($0.1) }

		let destructured = script.matches(of: /\{([\w\s,:]+)\}\s*=\s*\(?\s*(?:[\w.#]+\.config|JSON\.parse\(\s*\(?\s*this\.dataset\.config\s*\)?\s*\))(?!\w|[\s)]*[.\[])/).flatMap { names(in: $0.1) }

		return Set(members + destructured)
	}

	// Stored once, as the config check reads every component script.
	nonisolated(unsafe) private static let configTypeComments = /\/\*\*.*?\*\//.dotMatchesNewlines()

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

extension ScriptedElementTests {
	@Test(.enabled(if: Self.checksScripts, "Install Node.js to check state transitions."))
	func `WebGL backgrounds own their animation frames and restored uniforms`() throws {
		let harness = #"""
		import assert from 'node:assert/strict';
		import fs from 'node:fs';
		import test from 'node:test';
		import vm from 'node:vm';

		for (const name of ['apps-glass', 'nebula']) {
			test(`${name} owns one animation and rebuilds its uniforms after context loss`, () => {
				const canvas = new EventTarget();
				const document = new EventTarget();
				const frames = new Map();
				let nextFrame = 0;
				let generation = 0;
				let links = true;
				let draws = 0;
				let resized;
				let intersected;
				canvas.dataset = {};
				canvas.clientWidth = 800;
				canvas.clientHeight = 600;
				canvas.parentElement = new EventTarget();
				document.querySelector = () => canvas;
				document.hidden = false;
				const gl = new Proxy({
					canvas,
					getProgramParameter: () => links,
					getUniformLocation: (_, name) => ({generation, name}),
					uniform1f(location) {
						assert.equal(location.generation, generation);
					},
					uniform2f(location) {
						assert.equal(location.generation, generation);
					},
					uniform3f(location) {
						assert.equal(location.generation, generation);
					},
					drawArrays() {
						draws++;
					},
				}, {
					get: (target, key) => target[key] ?? (() => ({})),
				});
				canvas.getContext = () => gl;
				const context = vm.createContext({
					document, prefersReducedMotion: false,
					window: {devicePixelRatio: 1},
					performance: {now: () => 1000},
					matchMedia: () => new EventTarget(),
					getComputedStyle: () => ({getPropertyValue: () => ''}),
					OffscreenCanvas: class {
						getContext() {
							return {clearRect() {}, fillRect() {}, getImageData: () => ({data: [0, 0, 0, 0]})};
						}
					},
					IntersectionObserver: class {
						constructor(callback) {
							intersected = callback;
						}
						observe() {}
					},
					ResizeObserver: class {
						constructor(callback) {
							resized = callback;
						}
						observe() {}
					},
					requestAnimationFrame(callback) {
						const frame = nextFrame++;
						frames.set(frame, callback);
						return frame;
					},
					cancelAnimationFrame(frame) {
						frames.delete(frame);
					},
				});
				vm.runInContext(fs.readFileSync('public/scripts/webgl.js', 'utf8').replaceAll('export function', 'function'), context);
				vm.runInContext(fs.readFileSync(`public/scripts/${name}.js`, 'utf8').replace(/^import .*\n/gm, ''), context);
				resized();
				intersected([{isIntersecting: true}]);
				assert.equal(frames.size, 1);
				intersected([{isIntersecting: true}]);
				assert.equal(frames.size, 1);
				const [frame, callback] = frames.entries().next().value;
				frames.delete(frame);
				callback(2000);
				assert.equal(frames.size, 1);
				assert.ok(draws > 0);
				document.hidden = true;
				document.dispatchEvent(new Event('visibilitychange'));
				assert.equal(frames.size, 0);
				document.hidden = false;
				document.dispatchEvent(new Event('visibilitychange'));
				assert.equal(frames.size, 1);
				canvas.dispatchEvent(new Event('webglcontextlost', {cancelable: true}));
				assert.equal(frames.size, 0);
				const previousDraws = draws;
				resized();
				assert.equal(draws, previousDraws);
				links = false;
				canvas.dispatchEvent(new Event('webglcontextrestored'));
				intersected([{isIntersecting: true}]);
				assert.equal(frames.size, 0);
				links = true;
				generation++;
				canvas.dispatchEvent(new Event('webglcontextrestored'));
				assert.equal(frames.size, 1);
				intersected([{isIntersecting: false}]);
				assert.equal(frames.size, 0);
			});
		}
		"""#
		let error = try Self.syntaxError(checking: ["--input-type=module"], input: harness)
		#expect(error == nil, "\(error ?? "")")
	}
}

extension ScriptedElementTests {
	@Test(.enabled(if: Self.checksScripts, "Install Node.js to check state transitions."))
	func `jukebox playback owns pending wakeups and repeat timers`() throws {
		let harness = #"""
		import assert from 'node:assert/strict';
		import fs from 'node:fs';
		import test from 'node:test';
		import vm from 'node:vm';

		const source = fs.readFileSync('public/scripts/geocities.js', 'utf8');
		// Run the whole jukebox, including its DOM listeners and modem, without the unrelated toys of the page.
		const script = source.slice(source.indexOf('// The jukebox plays'), source.indexOf('// The pop-up:'));
		const setUp = () => {
			const document = new EventTarget();
			const parts = new Map();
			const resumes = [];
			const timers = new Map();
			let nextTimer = 0;
			let suspensions = 0;
			let outputs = 0;
			class AudioContext {
				currentTime = 0;
				resume() {
					const pending = Promise.withResolvers();
					resumes.push(pending);
					return pending.promise;
				}
				suspend() {
					suspensions++;
				}
			}
			class GainNode {
				gain = {setValueAtTime() {}, linearRampToValueAtTime() {}};
				constructor(_, {gain}) {
					if (gain === 0.05) {
						outputs++;
					}
				}
				connect() {
					return this;
				}
				disconnect() {}
			}
			document.querySelector = selector => {
				if (!parts.has(selector)) {
					parts.set(selector, new EventTarget());
				}
				return parts.get(selector);
			};
			const context = vm.createContext({
				document, AudioContext, GainNode, BiquadFilterNode: class {}, CustomEvent,
				tunes: [{file: 'test', title: 'Test', tempo: 60, speedUp: 1, notes: [[0, 1]]}],
				setTimeout(callback) {
					const timer = nextTimer++;
					timers.set(timer, callback);
					return timer;
				},
				clearTimeout(timer) {
					timers.delete(timer);
				},
			});
			vm.runInContext(script, context);
			return {
				play: () => vm.runInContext('playMusic()', context),
				stop: () => parts.get('#geocities-midi-stop').dispatchEvent(new Event('click')),
				otherMusic: () => document.dispatchEvent(new CustomEvent('geocities-music', {detail: {isPlaying: true, source: 'other'}})),
				resumes, timers,
				get outputs() {
					return outputs;
				},
				get suspensions() {
					return suspensions;
				},
			};
		};

		test('an older wakeup cannot hide a newer pending Play from other music', async () => {
			const player = setUp();
			const first = player.play();
			const second = player.play();
			player.resumes[0].resolve();
			await first;
			player.otherMusic();
			player.resumes[1].resolve();
			await second;
			assert.equal(player.outputs, 0);
			assert.equal(player.timers.size, 0);
		});

		test('Stop during wakeup frees the device when the wakeup finishes', async () => {
			const player = setUp();
			const pending = player.play();
			player.stop();
			const suspensions = player.suspensions;
			player.resumes[0].resolve();
			await pending;
			assert.equal(player.outputs, 0);
			assert.ok(player.suspensions > suspensions);
		});

		test('replacing and stopping playback cancels its repeat timer', async () => {
			const player = setUp();
			const first = player.play();
			player.resumes[0].resolve();
			await first;
			assert.equal(player.outputs, 1);
			assert.equal(player.timers.size, 1);
			const second = player.play();
			assert.equal(player.timers.size, 0);
			player.resumes[1].resolve();
			await second;
			assert.equal(player.outputs, 2);
			assert.equal(player.timers.size, 1);
			player.stop();
			assert.equal(player.timers.size, 0);
		});


		test('a failed startup allows a retry and cannot stop a newer Play', async () => {
			const player = setUp();
			const first = player.play();
			const rejection = assert.rejects(first, /cannot resume/);
			const second = player.play();
			player.resumes[0].reject(new Error('cannot resume'));
			await rejection;
			player.resumes[1].resolve();
			await second;
			assert.equal(player.outputs, 1);
			assert.equal(player.timers.size, 1);
			player.stop();
			const third = player.play();
			const failed = assert.rejects(third, /cannot resume/);
			player.resumes[2].reject(new Error('cannot resume'));
			await failed;
			const fourth = player.play();
			player.resumes[3].resolve();
			await fourth;
			assert.equal(player.outputs, 2);
			assert.equal(player.timers.size, 1);
		});
		"""#
		let error = try Self.syntaxError(checking: ["--input-type=module"], input: harness)
		#expect(error == nil, "\(error ?? "")")
	}
}

extension ScriptedElementTests {
	@Test(.enabled(if: Self.checksScripts, "Install Node.js to check state transitions."))
	func `Simon keeps idle showing and input phases exclusive`() throws {
		let harness = #"""
		import assert from 'node:assert/strict';
		import fs from 'node:fs';
		import test from 'node:test';
		import vm from 'node:vm';

		test('Simon locks input while showing and between rounds, and restarts after a wrong answer', async () => {
			const handlers = new Map();
			const waits = [];
			const timers = [];
			const tones = [];
			const node = () => ({dataset: {}, children: [], parentElement: {}, focus() {}, setAttribute() {}, replaceChildren() {}});
			const parts = new Proxy({}, {
				get(target, key) {
					return target[key] ??= node();
				},
			});
			const pads = Array.from({length: 4}, node);
			const room = {
				parts,
				querySelectorAll: selector => selector === '[data-part="simonPad"]' ? pads : [],
				stored: (_, fallback) => fallback,
				store() {},
				on(target, type, handler) {
					if (!handlers.has(target)) {
						handlers.set(target, {});
					}
					handlers.get(target)[type] = handler;
				},
				wait() {
					const pending = Promise.withResolvers();
					waits.push(pending);
					return pending.promise;
				},
				timeout(_, callback) {
					timers.push(callback);
				},
				say(text, target) {
					target.textContent = text;
				},
			};
			class GeoCitiesElement {}
			let Element;
			vm.runInNewContext(fs.readFileSync('Sources/Website/Pages/1999/Scripts/GameRoom.js', 'utf8').replace(/^import .*\n/gm, ''), {
				GeoCitiesElement,
				customElements: {define: (_, value) => {
						Element = value;
					}},
				document: {
					querySelector: () => ({beep: frequency => tones.push(frequency), addTickets: value => value}),
					createElement: node,
				},
				randomItem: items => items[0], randomInteger: () => 0, shuffled: items => items,
				plural: (amount, noun) => `${amount} ${noun}`,
			});
			Element.prototype.connected.call(room);
			const press = index => handlers.get(pads[index]).click();
			const start = () => handlers.get(parts.simonStart).click();
			const finishShowing = async () => {
				while (!parts.simonStatus.textContent.startsWith('Your turn')) {
					assert.ok(waits.length > 0);
					waits.shift().resolve();
					await new Promise(resolve => setImmediate(resolve));
				}
			};
			press(1);
			assert.equal(tones.length, 1);
			start();
			press(1);
			assert.equal(tones.length, 1);
			assert.equal(parts.simonStart.disabled, true);
			await finishShowing();
			press(0);
			assert.equal(timers.length, 1);
			press(0);
			assert.equal(timers.length, 1);
			timers.shift()();
			await finishShowing();
			press(1);
			assert.equal(parts.simonStart.disabled, false);
			assert.match(parts.simonStatus.textContent, /^Wrong!/);
			start();
			assert.equal(parts.simonStart.disabled, true);
			await finishShowing();
			press(0);
			assert.equal(timers.length, 1);
		});
		"""#
		let error = try Self.syntaxError(checking: ["--input-type=module"], input: harness)
		#expect(error == nil, "\(error ?? "")")
	}
}

extension ScriptedElementTests {
	@Test(.enabled(if: Self.checksScripts, "Install Node.js to check state transitions."))
	func `animation loops cancel pending steps when stopped or disconnected`() throws {
		let harness = #"""
		import assert from 'node:assert/strict';
		import fs from 'node:fs';
		import test from 'node:test';
		import vm from 'node:vm';

		const setUp = async () => {
			const document = new EventTarget();
			document.visibilityState = 'visible';
			const frames = new Map();
			const observers = [];
			let nextFrame = 0;
			let steps = 0;
			let stops = 0;
			let shouldRun = false;
			const reducedMotion = new EventTarget();
			reducedMotion.matches = true;
			const context = vm.createContext({
				HTMLElement: class extends EventTarget {
					isConnected = true;
				},
				document, AbortController, AbortSignal,
				prerendered: Promise.resolve(),
				matchMedia: () => reducedMotion,
				IntersectionObserver: class {
					constructor(callback) {
						observers.push(callback);
					}
					observe() {}
					disconnect() {}
				},
				requestAnimationFrame(callback) {
					const identifier = nextFrame++;
					frames.set(identifier, callback);
					return identifier;
				},
				cancelAnimationFrame(identifier) {
					frames.delete(identifier);
				},
			});
			const source = fs.readFileSync('public/scripts/scripted-element.js', 'utf8')
				.replace(/^import .*\n/gm, '')
				.replace(/^export \{.*\};\n/gm, '')
				.replace('export default class', 'globalThis.Component = class');
			vm.runInContext(source, context);
			class Demo extends context.Component {
				connected() {
					this.animation = this.loop(() => {
						steps++;
					}, {while: () => shouldRun, stopped: () => {
						stops++;
					}});
				}
			}
			const element = new Demo();
			const connect = async () => {
				element.isConnected = true;
				await element.connectedCallback();
				observers.at(-1)([{target: element, isIntersecting: true}]);
			};
			await connect();
			return {
				element, frames, connect,
				get steps() {
					return steps;
				},
				get stops() {
					return stops;
				},
				runFrame() {
					const pending = [...frames.values()];
					frames.clear();
					for (const callback of pending) {
						callback(1000);
					}
				},
				start() {
					shouldRun = true;
					element.animation.start();
				},
			};
		};

		test('one-shot drawing works without continuous animation and stop cancels only pending work', async () => {
			const view = await setUp();
			view.element.animation.requestStep();
			view.element.animation.requestStep();
			assert.equal(view.frames.size, 1);
			view.runFrame();
			assert.equal(view.steps, 1);
			assert.equal(view.frames.size, 0);
			view.element.animation.requestStep();
			view.element.animation.stop();
			assert.equal(view.frames.size, 0);
			assert.equal(view.stops, 0);
			view.element.animation.requestStep();
			view.runFrame();
			assert.equal(view.steps, 2);
			view.start();
			view.runFrame();
			assert.equal(view.steps, 3);
			assert.equal(view.frames.size, 1);
			view.element.animation.stop();
			view.element.animation.stop();
			assert.equal(view.frames.size, 0);
			assert.equal(view.stops, 1);
		});

		test('a removed connection cannot draw a pending one-shot after reconnecting', async () => {
			const view = await setUp();
			const previous = view.element.animation;
			previous.requestStep();
			view.element.isConnected = false;
			view.element.disconnectedCallback();
			assert.equal(view.frames.size, 0);
			await view.connect();
			view.runFrame();
			assert.equal(view.steps, 0);
			view.element.animation.requestStep();
			view.runFrame();
			assert.equal(view.steps, 1);
			assert.equal(view.stops, 0);
		});
		"""#
		let error = try Self.syntaxError(checking: ["--input-type=module"], input: harness)
		#expect(error == nil, "\(error ?? "")")
	}
}

extension ScriptedElementTests {
	@Test(.enabled(if: Self.checksScripts, "Install Node.js to check state transitions."))
	func `turntable preparation belongs to the current drag and connection`() throws {
		let harness = #"""
		import assert from 'node:assert/strict';
		import fs from 'node:fs';
		import test from 'node:test';
		import vm from 'node:vm';

		const setUp = () => {
			const rendering = Promise.withResolvers();
			const sources = [];
			const listeners = new Map();
			const controller = new AbortController();
			const control = () => ({
				style: {}, attributes: {},
				setAttribute(name, value) {
					this.attributes[name] = value;
				},
				focus() {}, setPointerCapture() {},
				getBoundingClientRect: () => ({left: 0, top: 0, width: 100, height: 100}),
			});
			const parts = {record: control(), play: control(), airHorn: control(), rewind: control()};
			class Buffer {
				length = 8;
				sampleRate = 44_100;
				getChannelData() {
					return new Float32Array(this.length);
				}
			}
			class Source {
				constructor(_, options) {
					this.buffer = options.buffer;
					sources.push(this);
				}
				connect() {
					return this;
				}
				start() {
					this.started = true;
				}
				stop() {
					this.stopped = true;
				}
			}
			const audioContext = {currentTime: 0};
			const context = vm.createContext({
				GeoCitiesElement: class {},
				customElements: {define: (_, component) => {
					context.Component = component;
				}},
				context: audioContext,
				OfflineAudioContext: class {
					destination = {};
					startRendering() {
						return rendering.promise;
					}
				},
				AudioBuffer: Buffer, AudioBufferSourceNode: Source,
				GainNode: class {
					gain = {setValueAtTime() {}, linearRampToValueAtTime() {}};
					connect() {
						return this;
					}
				},
				performance: {now: () => 1000},
				connectVolume() {}, startAudio: () => true,
				makeBus: () => ({gain: {value: 0}}),
				startPlaying() {}, stopPlaying() {}, addStopHandler() {},
				drums: {kick() {}, snare() {}, hat() {}},
				pluck() {}, voice() {}, midiFrequency: () => 1,
				clamp: (value, minimum, maximum) => Math.min(Math.max(value, minimum), maximum),
			});
			vm.runInContext(fs.readFileSync('Sources/Website/Pages/1999/Scripts/DJBooth.js', 'utf8').replace(/^import .*\n/gm, ''), context);
			const element = {
				parts, signal: controller.signal, isConnected: true,
				querySelectorAll: () => [],
				loop: () => ({start() {}, stop() {}}),
				say() {},
				on(target, type, callback) {
					if (!listeners.has(target)) {
						listeners.set(target, new Map());
					}
					listeners.get(target).set(type, callback);
				},
			};
			context.Component.prototype.connected.call(element);
			return {
				element, sources, parts, controller,
				finishRendering() {
					rendering.resolve(new Buffer());
				},
				play: () => listeners.get(parts.play).get('click')(),
				pointer(type, pointerId = 1, clientX = 100, clientY = 50) {
					return listeners.get(parts.record).get(type)({pointerId, pointerType: 'mouse', button: 0, clientX, clientY, preventDefault() {}});
				},
			};
		};

		test('releasing a drag during rendering cannot pause the beat that Play starts', async () => {
			const deck = setUp();
			const playing = deck.play();
			const holding = deck.pointer('pointerdown');
			deck.pointer('pointerup');
			deck.finishRendering();
			await Promise.all([playing, holding]);
			assert.equal(deck.sources.length, 1);
			assert.equal(deck.sources[0].started, true);
			assert.equal(deck.sources[0].stopped, undefined);
			assert.equal(deck.parts.play.attributes['aria-pressed'], 'true');
		});

		test('an active drag scratches and only its pointer can release and resume the beat', async () => {
			const deck = setUp();
			const playing = deck.play();
			deck.finishRendering();
			await playing;
			await deck.pointer('pointerdown');
			assert.equal(deck.sources[0].stopped, true);
			deck.pointer('pointermove', 2, 50, 100);
			deck.pointer('pointerup', 2);
			assert.equal(deck.sources.length, 1);
			deck.pointer('pointermove', 1, 50, 100);
			assert.equal(deck.sources.length, 2);
			assert.equal(deck.sources[1].started, true);
			assert.equal(deck.sources[1].stopped, true);
			assert.equal(deck.parts.record.style.rotate, '90deg');
			deck.pointer('pointerup');
			assert.equal(deck.sources.length, 3);
			assert.equal(deck.sources[2].started, true);
			assert.equal(deck.sources[2].stopped, undefined);
			deck.pointer('pointermove', 1, 0, 50);
			assert.equal(deck.sources.length, 3);
		});

		test('rendering from a removed connection cannot start playback after reconnection', async () => {
			const deck = setUp();
			const playing = deck.play();
			deck.controller.abort();
			deck.element.signal = new AbortController().signal;
			deck.element.isConnected = true;
			deck.finishRendering();
			await playing;
			assert.equal(deck.sources.length, 0);
			assert.equal(deck.parts.play.attributes['aria-pressed'], undefined);
		});
		"""#
		let error = try Self.syntaxError(checking: ["--input-type=module"], input: harness)
		#expect(error == nil, "\(error ?? "")")
	}
}

extension ScriptedElementTests {
	@Test(.enabled(if: Self.checksScripts, "Install Node.js to check sharing controls."))
	func `sharing controls preserve native selection and fallback behavior`() throws {
		let harness = #"""
		import assert from 'node:assert/strict';
		import fs from 'node:fs';
		import vm from 'node:vm';

		const events = [];
		const failures = [];
		const elements = new Map();
		const constructors = new Map();
		const page = {title: 'Example', url: 'https://example.com/app'};
		const navigator = {};
		const location = {href: ''};
		const context = vm.createContext({
			navigator, location,
			matchMedia: () => ({matches: false}),
			document: {
				prerendering: false,
				getElementById: identifier => elements.get(identifier),
			},
			console: {error: (...arguments_) => failures.push(arguments_)},
			HTMLElement: class {
				listeners = new Map();
				getAttribute(name) {
					return page[name.slice('share-'.length)];
				}
				// The share option, as the only part of the menu (`partList(this, 'share')`).
				querySelectorAll() {
					return this.shareOption ? [Object.assign(this.shareOption, {parentElement: this, getAttribute: () => 'share'})] : [];
				}
				closest() {
					return this.popover;
				}
				addEventListener(name, listener) {
					this.listeners.set(name, listener);
				}
			},
			customElements: {
				define: (name, constructor) => constructors.set(name, constructor),
			},
		});
		vm.runInContext(fs.readFileSync('public/scripts/dom.js', 'utf8').replace(/^export /gm, ''), context);
		for (const name of ['OverflowMenu', 'ShareButton']) {
			vm.runInContext(fs.readFileSync(`Sources/Website/Components/Scripts/${name}.js`, 'utf8').replace(/^import .*\n/gm, ''), context);
		}
		const {copy, sharedPage, cloneTemplate, scriptData, clockTime, untilNextMinute, elementForFragment} = vm.runInContext('({copy, sharedPage, cloneTemplate, scriptData, clockTime, untilNextMinute, elementForFragment})', context);

		const OverflowMenu = constructors.get('overflow-menu');
		const absent = new OverflowMenu();
		navigator.canShare = () => {
			assert.fail('A menu without sharing must not query its capability.');
		};
		absent.connectedCallback();
		const element = new OverflowMenu();
		element.shareOption = {hidden: true, disabled: true};
		delete navigator.canShare;
		element.connectedCallback();
		assert.equal(element.shareOption.hidden, true);
		assert.equal(element.shareOption.disabled, true);
		navigator.canShare = data => {
			assert.equal(data.title, page.title);
			assert.equal(data.url, page.url);
			return false;
		};
		element.connectedCallback();
		assert.equal(element.shareOption.hidden, true);
		assert.equal(element.shareOption.disabled, true);
		navigator.canShare = () => true;
		element.connectedCallback();
		assert.equal(element.shareOption.hidden, false);
		assert.equal(element.shareOption.disabled, false);

		const fallback = {
			popover: 'auto',
			showPopover({source}) {
				assert.equal(source, menu);
				events.push('open');
			},
			focus() {
				events.push('popover-focus');
			},
		};
		elements.set('share', fallback);
		const option = {dataset: {part: 'share'}, hasAttribute: name => name === 'data-menu-popover'};
		const menu = {value: '', selectedOptions: [option], focus: () => events.push('menu-focus')};
		const choose = element.listeners.get('change');
		await choose({target: menu});
		assert.deepEqual(events, []);
		let finishSharing;
		navigator.share = data => {
			assert.equal(data.title, page.title);
			assert.equal(data.url, page.url);
			assert.equal(menu.value, '');
			assert.deepEqual(events, ['menu-focus']);
			return new Promise(resolve => {
				finishSharing = resolve;
			});
		};
		menu.value = '#share';
		const pending = choose({target: menu});
		assert.equal(menu.value, '');
		assert.deepEqual(events, ['menu-focus']);
		finishSharing();
		await pending;
		assert.deepEqual(events, ['menu-focus']);

		for (const name of ['AbortError', 'NotAllowedError', 'DataError']) {
			events.length = 0;
			navigator.share = async () => {
				throw Object.assign(new Error(name), {name});
			};
			menu.value = '#share';
			await choose({target: menu});
			assert.equal(menu.value, '');
			assert.deepEqual(events, name === 'NotAllowedError' ? ['menu-focus', 'open', 'popover-focus'] : ['menu-focus']);
		}
		assert.equal(failures.length, 1);
		assert.deepEqual(failures[0], ['Share failed:', 'DataError']);
		assert.equal(location.href, '');

		const ShareButton = constructors.get('share-button');
		const button = new ShareButton();
		button.popover = {hidePopover: () => events.push('hide')};
		navigator.share = async data => {
			assert.equal(events.at(-1), 'hide');
			assert.equal(data.url, page.url);
			events.push('share');
		};
		button.connectedCallback();
		button.listeners.get('click')();
		assert.deepEqual(events.slice(-2), ['hide', 'share']);
		assert.equal(sharedPage(button).title, page.title);

		const announcements = [];
		const copied = [];
		navigator.clipboard = {writeText: async text => copied.push(text)};
		assert.equal(await copy('Example', {ariaNotify: message => announcements.push(message)}), true);
		assert.deepEqual(copied, ['Example']);
		assert.deepEqual(announcements, ['Copied']);
		assert.equal(await copy('Without announcement', {}), true);
		navigator.clipboard.writeText = async () => {
			throw new Error('Denied');
		};
		assert.equal(await copy('Unavailable', {ariaNotify: () => assert.fail('A failed copy must not announce success.')}), false);

		const child = {cloneNode: deep => ({deep})};
		assert.equal(cloneTemplate({content: {firstElementChild: child}}).deep, true);
		elements.set('data', {text: '{"count":2}'});
		assert.equal(scriptData('data').count, 2);
		elements.set('scalar', {text: 'false'});
		assert.equal(scriptData('scalar'), false);
		assert.throws(() => scriptData('missing'));
		elements.set('broken', {text: '{'});
		assert.throws(() => scriptData('broken'));
		elements.set('with space', fallback);
		assert.equal(elementForFragment('#with%20space'), fallback);
		assert.equal(elementForFragment('#missing'), undefined);
		assert.equal(elementForFragment('#%E0'), undefined);
		const date = new Date('2026-11-15T04:12:30.250Z');
		assert.equal(clockTime(date, 'UTC'), '04:12');
		assert.equal(untilNextMinute(date), 29_750);
		assert.equal(untilNextMinute(new Date('2026-11-15T04:12:00.000Z')), 60_000);
		"""#
		let error = try Self.syntaxError(checking: ["--input-type=module"], input: harness)
		#expect(error == nil, "\(error ?? "")")
	}
}

extension ScriptedElementTests {
	@Test(.enabled(if: Self.checksScripts, "Install Node.js to check DOM part ownership."))
	func `DOM parts preserve ownership element identity and valid property names`() throws {
		let harness = #"""
		import assert from 'node:assert/strict';
		import fs from 'node:fs';
		import vm from 'node:vm';

		const context = vm.createContext({matchMedia: () => ({matches: false}), navigator: {platform: 'MacIntel', maxTouchPoints: 0}, document: {prerendering: false}});
		vm.runInContext(fs.readFileSync('public/scripts/dom.js', 'utf8').replace(/^export /gm, ''), context);
		const parts = vm.runInContext('parts', context);
		const descendants = [];
		const root = {
			localName: 'article',
			querySelectorAll(selector) {
				assert.equal(selector, '[data-part]');
				return descendants;
			},
		};
		const part = (name, parentElement = root, localName = 'span') => {
			const element = {
				parentElement, localName,
				getAttribute(attribute) {
					assert.equal(attribute, 'data-part');
					return name;
				},
			};
			descendants.push(element);
			return element;
		};
		const nested = part('nested', root, 'child-element');
		part('private', nested);
		const wrapper = {localName: 'div', parentElement: root};
		const first = part('label', wrapper);
		part('label');
		const icon = part('icon', root, 'svg');
		icon.namespaceURI = 'http://www.w3.org/2000/svg';
		const inheritedNames = ['constructor', 'toString', '__proto__'].map(name => [name, part(name)]);
		const found = parts(root);
		assert.equal(found.nested, nested);
		assert.equal(found.label, first);
		assert.equal(found.icon, icon);
		assert.throws(() => found.private, /<article> has no part “private”/);
		assert.throws(() => found.missing, /<article> has no part “missing”/);
		assert.throws(() => parts(root, 'Example card').missing, /Example card has no part “missing”/);
		assert.equal(found.then, undefined);
		assert.equal(found.toJSON, undefined);
		assert.equal(found[Symbol('unrecognized')], undefined);
		assert.equal(found[Symbol.toStringTag], undefined);
		assert.equal(await found, found);
		for (const [name, element] of inheritedNames) {
			assert.equal(found[name], element, `The valid part name ${name} must keep its element.`);
		}
		const empty = parts({localName: 'section', querySelectorAll: () => []});
		assert.equal(JSON.stringify(empty), '{}');
		assert.equal(await empty, empty);
		"""#
		let error = try Self.syntaxError(checking: ["--input-type=module"], input: harness)
		#expect(error == nil, "\(error ?? "")")
	}
}


extension ScriptedElementTests {
	@Test(.enabled(if: Self.checksScripts, "Install Node.js to check linking book transitions."))
	func `returning from the linking book completes only its active transition`() throws {
		let harness = #"""
		import assert from 'node:assert/strict';
		import fs from 'node:fs';
		import vm from 'node:vm';

		const drawing = {
			createLinearGradient: () => ({addColorStop() {}}),
			fillRect() {}, beginPath() {}, moveTo() {}, lineTo() {}, arc() {},
			fill() {}, stroke() {}, save() {}, restore() {}, translate() {}, rotate() {}, drawImage() {},
		};
		const control = () => ({
			hidden: false, textContent: '', dataset: {},
			focus() {
				document.activeElement = this;
			},
		});
		const document = {activeElement: undefined, body: {}};
		const canvas = Object.assign(control(), {width: 480, height: 300, getContext: () => drawing});
		const panel = control();
		const parts = {
			pages: control(), panel, canvas,
			panelCanvas: {width: 160, height: 110, getContext: () => drawing},
			view: Object.assign(control(), {hidden: true, contains: () => false}),
			flash: control(),
		};
		const moveButtons = ['left', 'forward', 'back', 'right'].map(direction => Object.assign(control(), {dataset: {ageMove: direction}}));
		const spotButtons = Array.from({length: 3}, control);
		const listeners = new Map();
		const waits = [];
		const messages = [];
		const celebrations = [];
		let cheers = 0;
		let Component;
		vm.runInNewContext(fs.readFileSync('Sources/Website/Pages/1999/Scripts/LinkingBook.js', 'utf8').replace(/^import .*\n/gm, ''), {
			document,
			fillEllipse() {}, fillPolygon() {},
			makeCanvas: () => ({getContext: () => drawing}),
			GeoCitiesElement: class {
				parts = parts;
				reducedMotion = false;
				querySelectorAll(selector) {
					return selector === '[data-age-move]' ? moveButtons : spotButtons;
				}
				on(target, name, callback) {
					if (!listeners.has(target)) {
						listeners.set(target, new Map());
					}
					listeners.get(target).set(name, callback);
				}
				wait(milliseconds) {
					assert.equal(milliseconds, 650);
					return new Promise(resolve => waits.push(resolve));
				}
				loop() {
					return {start() {}, requestStep() {}};
				}
				say(message) {
					messages.push(message);
				}
				toast(message) {
					celebrations.push(message);
				}
				cheer() {
					cheers++;
				}
			},
			customElements: {define: (name, constructor) => {
				Component = constructor;
			}},
		});
		const element = new Component();
		element.connected();
		const click = button => listeners.get(button).get('click')();
		const move = key => listeners.get(canvas).get('keydown')({key, preventDefault() {}});
		const spot = name => {
			const button = spotButtons.find(button => !button.hidden && button.textContent === `✋ ${name}`);
			assert.ok(button, `The current view must offer ${name}.`);
			click(button);
		};
		const settle = async () => {
			for (let turn = 0; turn < 6; turn++) {
				await Promise.resolve();
			}
		};
		const finishLink = async () => {
			assert.equal(waits.length, 1);
			waits.shift()();
			await settle();
		};

		// An unfinished visit resets the switches when the visitor returns home.
		click(panel);
		await finishLink();
		spot('Marker switch');
		move('ArrowUp');
		move('ArrowUp');
		spot('Linking book home');
		assert.equal(parts.view.hidden, false);
		await finishLink();
		assert.equal(parts.view.hidden, true);
		assert.equal(parts.pages.hidden, false);
		assert.equal(cheers, 0);

		// Complete the puzzle through its real keyboard and button callbacks.
		click(panel);
		await finishLink();
		spot('Marker switch');
		assert.match(messages.at(-1), /1 of 3/);
		move('ArrowUp');
		spot('Marker switch');
		move('ArrowLeft');
		spot('Marker switch');
		assert.match(messages.at(-1), /3 of 3/);
		spot('Red page');
		move('ArrowDown');
		move('ArrowRight');
		move('ArrowUp');
		spot('Blue page');
		move('ArrowDown');
		move('ArrowDown');
		move('ArrowUp');
		spot('Red book');
		spot('Blue book');
		assert.match(messages.at(-1), /Time to touch the linking book and go home/);

		// The second activation cannot finish or reset the first transition.
		spot('Linking book home');
		spot('Linking book home');
		await settle();
		assert.equal(waits.length, 1);
		assert.equal(parts.view.hidden, false);
		assert.equal(cheers, 0);
		assert.equal(celebrations.length, 0);
		await finishLink();
		assert.equal(parts.view.hidden, true);
		assert.equal(parts.pages.hidden, false);
		assert.equal(cheers, 1);
		assert.equal(celebrations.length, 1);

		click(panel);
		await finishLink();
		spot('Marker switch');
		assert.match(messages.at(-1), /1 of 3/);
		move('ArrowUp');
		move('ArrowLeft');
		assert.match(messages.at(-1), /A red page lies on a tree stump/);
		assert.equal(cheers, 1);
		"""#
		let error = try Self.syntaxError(checking: ["--input-type=module"], input: harness)
		#expect(error == nil, "\(error ?? "")")
	}
}


extension ScriptedElementTests {
	@Test(.enabled(if: Self.checksScripts, "Install Node.js to check Casio recording sessions."))
	func `Casio recording sessions retain note timing and completed memory`() throws {
		let harness = #"""
		import assert from 'node:assert/strict';
		import fs from 'node:fs';
		import vm from 'node:vm';
		import test from 'node:test';

		await test('recording sessions retain note timing and completed memory', () => {

			const context = {currentTime: 0};
			const listeners = new Map();
			const timers = [];
			const voices = [];
			const stopHandlers = [];
			let canStart = true;
			let Component;
			const control = () => ({dataset: {}, attributes: {}, disabled: false, textContent: '', setAttribute(name, value) {this.attributes[name] = value;}});
			const parts = Object.fromEntries(['keyboard', 'display', 'start', 'slower', 'faster', 'chord', 'demo', 'record', 'playback'].map(name => [name, control()]));
			const keys = [60, 61].map(note => Object.assign(control(), {dataset: {casioNote: String(note)}}));
			const toneButton = Object.assign(control(), {textContent: 'Piano', dataset: {casioTone: 'piano'}});
			class GainNode {
				gain = {setValueAtTime() {}, linearRampToValueAtTime() {}, setTargetAtTime() {}, cancelScheduledValues() {}};
				connect() {return this;}
				disconnect() {}
			}
			class OscillatorNode {
				constructor() {voices.push(this);}
				connect() {return this;}
				start(time) {this.started = time;}
				stop(time) {this.stopped = time;}
			}
			vm.runInNewContext(fs.readFileSync('Sources/Website/Pages/1999/Scripts/Casio.js', 'utf8').replace(/^import .*\n/gm, ''), {
				context, GainNode, OscillatorNode, master: {}, document: {},
				setTimeout() {},
				connectVolume() {}, startAudio: () => canStart,
				midiFrequency: note => note,
				isTypingTarget: () => false, hasModifier: () => false,
				addStopHandler: handler => stopHandlers.push(handler),
				Clock: class {isRunning = false;},
				startPlaying() {}, stopPlaying() {}, makeBus: () => ({}), fadeOut() {},
				GeoCitiesElement: class {
					parts = parts;
					config = {lowestNote: 60, computerKeys: [{code: 'KeyA'}, {code: 'KeyS'}]};
					querySelectorAll(selector) {
						return selector === '[data-casio-note]' ? keys : selector === '[data-casio-tone]' ? [toneButton] : [];
					}
					on(target, type, callback) {
						if (!listeners.has(target)) {listeners.set(target, new Map());}
						listeners.get(target).set(type, callback);
					}
					timeout(milliseconds, callback) {
						const timer = {milliseconds, callback, cancelled: false, cancel() {this.cancelled = true;}};
						timers.push(timer);
						return timer;
					}
					contains() {return false;}
					say() {}
				},
				customElements: {define: (_, constructor) => {Component = constructor;}},
			});
			const element = new Component();
			element.connected();
			const click = name => listeners.get(parts[name]).get('click')();
			const key = (type, code = 'KeyA') => listeners.get(element).get(type)({code, repeat: false, preventDefault() {}});
			const memoryVoices = () => {
				const first = voices.length;
				click('playback');
				return voices.slice(first);
			};
			const nearlyEqual = (actual, expected) => assert.ok(Math.abs(actual - expected) < 1e-9, `${actual} must equal ${expected}`);

			// A recording can start at audio time zero, and stopping it closes a held note once.
			click('record');
			assert.match(parts.display.textContent, /REC/);
			assert.equal(parts.record.attributes['aria-pressed'], 'true');
			key('keydown');
			context.currentTime = 2;
			click('record');
			key('keyup');
			assert.equal(timers[0].cancelled, true);
			assert.equal(parts.record.attributes['aria-pressed'], 'false');
			assert.equal(parts.playback.disabled, false);
			context.currentTime = 10;
			let played = memoryVoices();
			assert.equal(played.length, 2);
			nearlyEqual(played[0].started, 10.1);
			nearlyEqual(played[0].stopped, 12.35);

			// Focus and sound-card stops close keys without ending the new recording session.
			context.currentTime = 20;
			click('record');
			assert.equal(parts.playback.disabled, true);
			const recordingTimer = timers.at(-1);
			assert.equal(recordingTimer.milliseconds, 60_000);
			key('keydown');
			context.currentTime = 21;
			listeners.get(element).get('focusout')({relatedTarget: undefined});
			assert.match(parts.display.textContent, /REC/);
			context.currentTime = 22;
			key('keydown', 'KeyS');
			context.currentTime = 23;
			stopHandlers[0]();
			assert.match(parts.display.textContent, /REC/);
			context.currentTime = 24;
			key('keydown');
			context.currentTime = 80;
			recordingTimer.callback();
			assert.equal(recordingTimer.cancelled, true);
			assert.doesNotMatch(parts.display.textContent, /REC/);
			assert.equal(parts.playback.disabled, false);
			context.currentTime = 100;
			played = memoryVoices();
			assert.equal(played.length, 6);
			for (const [index, start, end] of [[0, 100.1, 101.35], [2, 102.1, 103.35], [4, 104.1, 160.35]]) {
				nearlyEqual(played[index].started, start);
				nearlyEqual(played[index].stopped, end);
			}

			// A new empty recording replaces the saved notes; a failed audio start opens no session.
			click('record');
			click('record');
			assert.equal(parts.playback.disabled, true);
			assert.equal(memoryVoices().length, 0);
			const timerCount = timers.length;
			canStart = false;
			click('record');
			assert.equal(timers.length, timerCount);
			assert.doesNotMatch(parts.display.textContent, /REC/);
		});
		"""#
		let error = try Self.syntaxError(checking: ["--input-type=module"], input: harness)
		#expect(error == nil, "\(error ?? "")")
	}
}
