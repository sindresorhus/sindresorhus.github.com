import Foundation
import SiteKit
import Testing
@testable import Website

/**
The components that are custom elements (``ScriptedElement``) and their scripts next to their Swift files.
*/
@Suite
struct ScriptedElementTests {
	private static let sourceDirectory = Project.website.root.appending(path: "Sources/Website")

	/**
	The scripts of the elements, found in the `Scripts` folders like the build finds them, with their text.
	*/
	private static let scripts: [(path: RoutePath, source: URL, text: String)] = Project.website.elementScripts().map { script in
		(script.path, script.source, (try? String(contentsOf: script.source, encoding: .utf8)) ?? "")
	}

	/**
	Every page of the site, rendered once for the tests below, with the component gallery, which shows the components that the pages only show with data. They render in one collector, so it has the custom elements (``ScriptedElement``) of all the pages, as types, so the tests can check the scripts against them without a list of the elements.
	*/
	private static let site = Task {
		let routes = try await Site(content: .website).routes(project: .website, includesGallery: true)
		let resources = PageResources()
		var pages = [(path: RoutePath, html: String)]()

		do {
			try resources.collect {
				pages = try routes.compactMap { route -> (path: RoutePath, html: String)? in
					guard case .page(_, let render) = route.output else {
						return nil
					}

					return (route.path, try render())
				}
			}
		} catch is StyleError where !pages.isEmpty {
			// Two pages may use style sets with the same class names, as each page only has its own, so the collector of all the pages can throw for them after the pages are set. A duplicate in one page throws inside its render, before the pages are set, so it still fails.
		}

		return (pages: pages, elements: resources.elements)
	}

	/**
	The tests below check the elements that the pages show, so every element must be shown by a page or the gallery. The names are compared without their parent type, like `Turntable` for `GeoCitiesDJBooth.Turntable`.
	*/
	@Test
	func `every element in the sources is shown by a page`() async throws {
		var declared = Set<String>()

		for file in try Self.sourceDirectory.filesRecursively() where file.pathExtension == "swift" {
			let source = try String(contentsOf: file, encoding: .utf8)

			for match in source.matches(of: /(?:struct|class|enum|extension)\s+(\w+)\s*:[^{]*\bScriptedElement\b/) {
				declared.insert(String(match.output.1))
			}
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
			let folder = script.source.deletingLastPathComponent().path(relativeTo: Self.sourceDirectory)
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

		#expect(Self.scripts.map(\.path).filter { !scriptsOfElements.contains($0) } == [], "These scripts are not the script of an element that a page shows.")
	}

	/**
	A script imports another one without its hash, and the import map of the page adds it, so each import must be a script in `public/scripts`, which the build publishes in `/scripts`, and no import may have a hash written by hand, which the next change of the file would make stale.
	*/
	@Test
	func `every import of a script is a published script, without a hash`() throws {
		let imported = try Site.importedScripts(project: .website)
		let publicScripts = Set(try Project.website.publicFiles().map { RoutePath("/" + $0.path) })

		// Like the base class of the 1999 page, and the relative import of the nebula of the home page.
		#expect(imported.isSuperset(of: ["/scripts/geocities-element.js", "/scripts/scripted-element.js", "/scripts/nebula.js"]))

		for path in imported {
			#expect(path.starts(with: "/scripts") && publicScripts.contains(path), "A script imports \(path), which is not a script in `public/scripts`.")
		}

		for script in Self.scripts {
			#expect(!script.text.contains(/^import .*\?v=/.anchorsMatchLineEndings()), "\(script.path) imports a script with its hash. The import map adds it.")
		}
	}

	/**
	The imports are found at the start of a line, and the dynamic imports anywhere, so an import in a comment is not one. A relative import is resolved from the path that the build publishes the script at, also for the script of an element, in `/scripts/elements`. The import map has only the imported scripts that have a hash, and there is none outside a build.
	*/
	@Test(.temporaryDirectory)
	func `the import map has the scripts that other scripts import, with their hashes`() throws {
		let root = try URL.temporaryDirectory(files: [
			"public/scripts/base.js": "export default class Base {}",
			"public/scripts/nebula.js": "export const draw = () => {};",
			"public/scripts/home.js": "import Base from '/scripts/base.js';\n// import '/scripts/comment.js';\nconst {draw} = await import('./nebula.js');",
			"Sources/Website/Scripts/Clock.js": "import Base from '../base.js';",
		])
		let project = Project(root: root)

		let imported = try Site.importedScripts(project: project)
		#expect(imported == ["/scripts/base.js", "/scripts/nebula.js"])

		let hashes = try Site.contentHashes(project: project)
		#expect(hashes.keys.sorted(using: KeyPathComparator(\.description)) == ["/scripts/base.js", "/scripts/elements/Clock.js", "/scripts/home.js", "/scripts/nebula.js"])

		// A script without a hash, like one of another site, is left out.
		let importMap = try RoutePath.$contentHashes.withValue(hashes) {
			try RoutePath.$importedScripts.withValue(imported.union(["/scripts/missing.js"])) {
				try #require(RoutePath.importMap)
			}
		}

		let imports = try JSONDecoder().decode([String: [String: String]].self, from: Data(importMap.utf8))
		let baseHash = hashes["/scripts/base.js"] ?? ""
		let nebulaHash = hashes["/scripts/nebula.js"] ?? ""
		let expectedImports: [String: String] = ["/scripts/base.js": "/scripts/base.js?v=\(baseHash)", "/scripts/nebula.js": "/scripts/nebula.js?v=\(nebulaHash)"]
		#expect(imports == ["imports": expectedImports])
		#expect(RoutePath.importMap == nil)
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
	The other direction: a state that nothing sets or styles is dead code. Each state of an element must be set, by its script, where it is a string literal somewhere, also in a choice, like `isDone ? 'done' : 'failed'`, or by Swift in the markup of the element, as the first state (`.state(…)`) or as a value that the script copies, like the value of a radio button, and it must be styled, so the CSS of a page that shows the element has `[data-state="…"]`. Limitation: The checks look for the name, so a state with a common name, like `open`, also counts as set when the script uses the name for something else, and as styled when another component on the same page styles it.
	*/
	@Test
	func `every state of an element is set and styled`() async throws {
		let site = try await Self.site.value
		var checkedElementCount = 0

		for element in site.elements where !element.declaredStates.isEmpty {
			checkedElementCount += 1

			let script = Self.code(of: try element.script.source)
			let elementPattern = try Regex("<\(element.tagName)[\\s>].*?</\(element.tagName)>").dotMatchesNewlines()
			let pages = site.pages.filter { $0.html.contains(elementPattern) }
			let markup = pages.flatMap { page in page.html.ranges(of: elementPattern).map { page.html[$0] } }
			let styles = pages.flatMap { $0.html.matches(of: /<style\b[^>]*>(.*?)<\/style>/.dotMatchesNewlines()).map(\.1) }

			for state in element.declaredStates {
				let isSetByScript = ["'\(state)'", "\"\(state)\"", "`\(state)`"].contains { script.contains($0) }
				let isRendered = markup.contains { $0.contains("data-state=\"\(state)\"") || $0.contains("value=\"\(state)\"") }
				#expect(isSetByScript || isRendered, "Neither the script of \(element) nor its markup sets its state `\(state)`. Remove it from `\(element).States`.")

				let isStyled = styles.contains { $0.contains("[data-state=\"\(state)\"]") }
				#expect(isStyled, "No style of the pages that show \(element) uses its state `\(state)`.")
			}
		}

		#expect(checkedElementCount > 50)
	}

	/**
	The states of the components that are not custom elements, which page scripts set, like `site.js` on the links to sections, and `geocities.js` on the 1999 page. Limitation: The list is kept by hand, so add the `States` of a new component like that here.
	*/
	private static let pageScriptStates = [
		ProseStyles.States.rawValues,
		AppdlePage.States.rawValues,
		AppsPage.States.rawValues,
		GeoCitiesPage.States.rawValues,
		GeoCitiesMacOS.States.rawValues,
		GeoCitiesWindows.States.rawValues,
		GeoCitiesNavigator.States.rawValues,
		GeoCitiesPets.States.rawValues,
	]

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
		let styles = [Stylesheet.site.css] + site.pages.flatMap { $0.html.matches(of: /<style\b[^>]*>(.*?)<\/style>/.dotMatchesNewlines()).map { String($0.1) } }
		let states = Set(Self.pageScriptStates.joined())

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

		let pageScripts = try Project.website.publicFiles().filter { $0.source.pathExtension == "js" }.map { try String(contentsOf: $0.source, encoding: .utf8) }.joined(separator: "\n")
		let attributesSetByPageScripts = Set(pageScripts.matches(of: /\.setAttribute\('([\w-]+)'/).map { String($0.1) })

		var checkedElementCount = 0

		for element in site.elements {
			let readAttributes = Set(Self.code(of: try element.script.source).matches(of: /\bthis\.(?:get|has)Attribute\('([\w-]+)'\)/).map { String($0.1) }).filter { !$0.hasPrefix("aria-") && !$0.hasPrefix("data-") }
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
		let html = try #require(try await Self.site.value.pages.first { $0.path == "/1999" }?.html)

		func renderedNames(_ attribute: String) -> Set<String> {
			Set(html.matches(of: /\s(data-[a-z-]+)="([\w-]+)"/).filter { $0.1 == attribute }.map { String($0.2) })
		}

		let windowsNames = renderedNames(GeoCitiesPage.Hooks.desktopWindow.rawValue)
		let macNames = renderedNames(GeoCitiesMacOS.Hooks.window.rawValue)
		#expect(windowsNames.count > 20)
		#expect(macNames.count > 5)

		let pageScripts = try Project.website.publicFiles().filter { $0.source.lastPathComponent.hasPrefix("geocities") && $0.source.pathExtension == "js" }.map { (name: $0.path, text: try String(contentsOf: $0.source, encoding: .utf8)) }
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
	The template parts of each element in the pages, by tag name, and the parts that are only inside its templates. The markup of an element is from its start tag to its first end tag, so it also has the parts of the elements inside it, which can only hide a mistake, not report one that is not there.
	*/
	private static func templateParts(in pages: [String], tagNames: Set<String>) -> (templates: [String: Set<String>], onlyInTemplates: [String: Set<String>]) {
		var templates = [String: Set<String>]()
		var insideTemplates = [String: Set<String>]()
		var outsideTemplates = [String: Set<String>]()

		func partNames(in markup: Substring) -> [String] {
			markup.matches(of: /data-part="(\w+)"/).map { String($0.1) }
		}

		for html in pages {
			for start in html.matches(of: /<([a-z][a-z0-9]*(?:-[a-z0-9]+)+)[\s>]/) {
				let tagName = String(start.1)

				guard
					tagNames.contains(tagName),
					let end = html[start.range.upperBound...].firstRange(of: "</\(tagName)>")
				else {
					continue
				}

				let markup = html[start.range.lowerBound..<end.upperBound]

				for template in markup.matches(of: /<template\b([^>]*)>(.*?)<\/template>/.dotMatchesNewlines()) {
					templates[tagName, default: []].formUnion(partNames(in: template.1))
					insideTemplates[tagName, default: []].formUnion(partNames(in: template.2))
				}

				let outside = markup.replacing(/<template\b[^>]*>.*?<\/template>/.dotMatchesNewlines(), with: "")
				outsideTemplates[tagName, default: []].formUnion(partNames(in: outside))
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
			let scripts = try page.html.matches(of: /<script\b[^>]*\bsrc="(\/[^"?]+)[^"]*"/).map { match in
				let path = RoutePath(String(match.1))
				return try String(contentsOf: Self.scripts.first { $0.path == path }?.source ?? Project.website.publicFile(path), encoding: .utf8)
			}
			.joined(separator: "\n")

			for match in page.html.matches(of: /<script type="application\/json" id="([\w-]+)">(.*?)<\/script>/.dotMatchesNewlines()) {
				guard let data = try JSONSerialization.jsonObject(with: Data(match.2.utf8)) as? [String: Any] else {
					continue
				}

				let readKeys = Self.readDataKeys(in: Self.code(of: scripts), id: String(match.1))
				checkedDataCount += 1
				#expect(readKeys.subtracting(data.keys).sorted() == [], "The scripts of \(page.path) read keys that the data `\(match.1)` does not have.")
				#expect(Set(data.keys).subtracting(readKeys).sorted() == [], "The scripts of \(page.path) do not read these keys of the data `\(match.1)`. Remove them, or rename them in both places.")
			}
		}

		#expect(checkedDataCount >= 4)
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

	@Test(.enabled(if: Self.isNodeAvailable, "Install Node.js to check the syntax of the scripts of the elements."))
	func `every script of an element is valid JavaScript`() async throws {
		let inlineScripts = try await Self.site.value.elements
			.filter { $0.script.path == nil }
			.map { (name: "The inline script of \($0)", text: try $0.generatedScript()) }

		for script in Self.scripts.map({ (name: $0.path.description, text: $0.text) }) + inlineScripts {
			let process = Process()
			process.executableURL = URL(filePath: "/usr/bin/env")
			process.arguments = ["node", "--input-type=module", "--check"]
			let input = Pipe()
			let errors = Pipe()
			process.standardInput = input
			process.standardError = errors
			try process.run()
			try input.fileHandleForWriting.write(contentsOf: Data(script.text.utf8))
			try input.fileHandleForWriting.close()
			process.waitUntilExit()

			let message = String(decoding: errors.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
			#expect(process.terminationStatus == 0, "\(script.name) has a syntax error: \(message)")
		}
	}

	/**
	The tags that the scripts of the page define: the scripts that it loads, and its inline scripts.
	*/
	private static func definedTagNames(in html: String) throws -> [String] {
		// The scripts of the site, not the counter of another site.
		let loaded = try html.matches(of: /<script\b[^>]*\bsrc="(\/[^"?]+)[^"]*"/).map { match in
			let path = RoutePath(String(match.1))
			let file = scripts.first { $0.path == path }?.source ?? Project.website.publicFile(path)
			return try String(contentsOf: file, encoding: .utf8)
		}

		let inline = html.matches(of: /<script type="module">(.*?)<\/script>/.dotMatchesNewlines()).map { String($0.1) }

		return (loaded + inline).flatMap { $0.matches(of: /customElements\.define\('([^']+)'/).map { String($0.1) } }
	}

	/**
	An element without its script does nothing, so each custom element on a page must be defined by a script that the page loads, once, as a second definition throws.
	*/
	@Test
	func `every custom element on a page is defined by a script of the page, once`() async throws {
		for page in try await Self.site.value.pages {
			// Without the scripts and comments, as their text is not markup.
			let markup = page.html.replacing(/<script\b.*?<\/script>|<!--.*?-->/.dotMatchesNewlines(), with: "")
			let usedTagNames = Set(markup.matches(of: /<([a-z][a-z0-9]*(?:-[a-z0-9]+)+)[\s\/>]/).map { String($0.1) })
			let definedTagNames = try Self.definedTagNames(in: page.html)

			#expect(usedTagNames.subtracting(definedTagNames).sorted() == [], "\(page.path) has custom elements that no script of the page defines.")
			#expect(Set(definedTagNames).count == definedTagNames.count, "\(page.path) defines a tag more than once, which throws: \(definedTagNames.sorted())")
		}
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

	The word boundaries are simple, as the default Unicode ones treat `this.parts.odds` as one word.
	*/
	private static func usedParts(in script: String) -> Set<String> {
		let members = script.matches(of: /\bthis\.parts\.(\w+)/.wordBoundaryKind(.simple)).map { String($0.1) }

		let destructured = script.matches(of: /\{([\w\s,:]+)\}\s*=\s*this\.parts\b(?![.\[])/.wordBoundaryKind(.simple)).flatMap { names(in: $0.1) }

		let selected = script.matches(of: /data-part="(\w+)"/).map { String($0.1) }

		let setUpFunctions = Set(script.matches(of: /\b(\w+)\(this,\s*this\.parts\)/.wordBoundaryKind(.simple)).map { String($0.1) })
		let parameters = script.matches(of: /\bconst (\w+) = \(\s*\w+\s*,\s*\{([\w\s,:]+)\}\s*\)\s*=>/.wordBoundaryKind(.simple))
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
			guard let copy = line.firstMatch(of: /\{(.*)\}\s*=\s*[\w.#]+\.clone\('\w+'\)/) else {
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
