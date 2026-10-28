import Elementary
import Foundation
import SiteKit
import SwiftParser
import SwiftSyntax
import Testing
@testable import Website

/**
Checks the real content files in `content/`.
*/
struct ContentGuardTests {
	private static let contentDirectory = Project.website.contentDirectory

	/**
	Styles and scripts belong to components, not content. Astro attributes like `is:inline` do nothing in the Swift build and publish invalid HTML.

	A file that is older than this rule can be listed here with the patterns it keeps. No file needs it now.
	*/
	private static let allowed = [String: Set<Pattern>]()

	private enum Pattern: CaseIterable {
		case script
		case styleElement
		case styleAttribute
		case astroAttribute

		var regex: Regex<Substring> {
			switch self {
			case .script:
				/(?i)<script\b/
			case .styleElement:
				/(?i)<style\b/
			case .styleAttribute:
				/\sstyle="/
			case .astroAttribute:
				/\sis:[a-z]/
			}
		}
	}

	@Test
	func `content has no raw scripts, styles, or Astro attributes`() throws {
		let files = try Self.markdownFiles()
		#expect(!files.isEmpty)

		for (path, contents) in files {
			let found = Set(Pattern.allCases.filter { contents.contains($0.regex) })
			let allowed = Self.allowed[path] ?? []

			#expect(found.isSubset(of: allowed), "Move the styles or scripts of \(path) into a component: \(found.subtracting(allowed))")
			#expect(allowed.isSubset(of: found), "Remove the cleaned-up patterns of \(path) from the allowlist: \(allowed.subtracting(found))")
		}
	}

	/**
	Links to Apple’s support pages and the App Store have no locale or storefront in the path, like `https://support.apple.com/102426` and `https://apps.apple.com/app/…`, so Apple shows the page in the language of the visitor and their storefront.
	*/
	@Test
	func `Apple links have no locale or storefront`() throws {
		let files = try Self.markdownFiles()
		#expect(!files.isEmpty)

		for (path, contents) in files {
			let links = Self.localizedAppleLinks(in: contents)
			#expect(links.isEmpty, "Use an Apple link without the locale or storefront: \(links.joined(separator: ", ")) in \(path)")
		}
	}

	@Test(arguments: [
		("https://support.apple.com/en-us/HT203129", ["https://support.apple.com/en-us/HT203129"]),
		("https://apps.apple.com/us/app/example/id123", ["https://apps.apple.com/us/app/example/id123"]),
		("https://support.apple.com/HT203129", []),
		("https://apps.apple.com/app/example/id123", []),
		("https://web.archive.org/web/20180711015728/https://support.apple.com/en-us/HT203129", []),
	])
	func `Apple link guard checks the destination`(destination: String, expected: [String]) {
		#expect(Self.localizedAppleLinks(in: "[Help](\(destination))") == expected)
	}

	// `support.apple.com/en-us/102426` and `apps.apple.com/us/app/…`. The whole link is matched, so the message shows it.
	nonisolated(unsafe) private static let localizedAppleLinkPattern = /https?:\/\/(?:support|apps)\.apple\.com\/(?:[a-z]{2}-[a-z]{2}|[a-z]{2})\/[^\s)\]"'>]*/
	nonisolated(unsafe) private static let linkPattern = /https?:\/\/[^\s)\]"'>]*/

	/**
	Apple links whose locale or storefront prevents Apple from choosing it for the visitor.
	*/
	private static func localizedAppleLinks(in contents: String) -> [String] {
		contents.matches(of: linkPattern)
			.map(\.output)
			.filter { $0.wholeMatch(of: localizedAppleLinkPattern) != nil }
			.map(String.init)
	}

	/**
	The path and text of each content file, without its code, which is shown as text, so a URL in a code block is not a link, and `style="long"` in a guide is not a style.
	*/
	private static func markdownFiles() throws -> [(path: String, contents: String)] {
		try contentDirectory.filesRecursively()
			.filter { $0.pathExtension == "md" }
			.map { file in
				(
					path: file.path(relativeTo: contentDirectory),
					contents: try String(contentsOf: file, encoding: .utf8)
						.replacing(/(?s)```.*?```/, with: "")
						.replacing(/`[^`\n]*`/, with: "")
				)
			}
	}
}

/**
Checks the source of the site.
*/
struct SourceGuardTests {
	/**
	Components style their own markup with style sets, so a style cannot drift from its markup. Selector rules are only for markup that components do not own.
	*/
	private static let filesWithSelectorRules: Set = [
		// The element defaults.
		"Styles/SiteStylesheet.swift",
		// The `html` and `body` elements, which the document renders without classes.
		"Layout/SiteLayout.swift",
		// The root element of the 1999 page, as a `:root:has()` style of the page made every change of the page lay out all of it.
		"Pages/1999/Page1999+Styles.swift",
	]

	@Test
	func `selector rules are only where components do not own the markup`() async throws {
		let files = try await SwiftSourceFile.all.value
		#expect(!files.isEmpty)

		let filesWithRules = Set(
			files
				.filter { !$0.syntax.calls(named: "Rule").isEmpty }
				.map { $0.url.path(relativeTo: SwiftSourceFile.directory) }
		)

		#expect(filesWithRules.subtracting(Self.filesWithSelectorRules).isEmpty, "Use a style set instead of a selector rule in: \(filesWithRules.subtracting(Self.filesWithSelectorRules).sorted())")
		#expect(Self.filesWithSelectorRules.subtracting(filesWithRules).isEmpty, "Remove the files without selector rules from the allowlist.")
	}

	/**
	A call that writes CSS as a string (``escapeHatchBudgets``), found with the parser of Swift, so a call in a doc comment, like an example, does not count.
	*/
	private struct EscapeHatch: Hashable, CustomStringConvertible {
		let name: String

		/**
		A method or a static member, like `.declaration(…)`, not an initializer, like `LengthPercentage(…)`.
		*/
		let isMember: Bool

		/**
		Only a call with a string literal as its first argument counts, like `.nested("…")`, as a call with a typed value is not an escape hatch.
		*/
		let takesString: Bool

		static func member(_ name: String, takesString: Bool = false) -> Self {
			Self(name: name, isMember: true, takesString: takesString)
		}

		/**
		An initializer with a string, like `LengthPercentage(raw: "…")`.
		*/
		static func initializer(_ name: String) -> Self {
			Self(name: name, isMember: false, takesString: true)
		}

		/**
		The call as it starts in the source, like `.nested("`.
		*/
		var description: String {
			"\(isMember ? "." : "")\(name)(\(takesString ? "\"" : "")"
		}

		func count(in syntax: SourceFileSyntax) -> Int {
			syntax.calls(named: name).count { call in
				call.isMemberCall == isMember
					&& (!takesString || call.firstStringLiteral != nil)
			}
		}
	}

	/**
	The escape hatches that write CSS as a string, with the number of uses that the source may have. Typed modifiers and values catch mistakes when the code compiles, so the counts must not grow. Lower a budget when uses are removed.
	*/
	private static let escapeHatchBudgets: [EscapeHatch: Int] = [
		.member("declaration"): 22,
		.initializer("Length"): 0,
		.initializer("LengthPercentage"): 0,
		.initializer("CSSValue"): 2,
		// The contact page computes each letter’s hue from its index and custom properties.
		.initializer("CSSNumber"): 1,
		// The card light uses a registered strength in color-mix(), and the NetMeeting meter has a repeating gradient.
		.initializer("CSSImage"): 2,
		// The prose styles need selectors for the Markdown markup that no component owns, like the introduction below the title of a Markdown page, the space above a bold label, the column of the shortcuts in a table, and the copy link of a closed question, which depends on the state of the `<details>` next to it.
		.member("nested", takesString: true): 33,
	]

	@Test
	func `escape hatches stay within their budgets`() async throws {
		let files = try await SwiftSourceFile.all.value
		#expect(!files.isEmpty)

		for (escapeHatch, budget) in Self.escapeHatchBudgets {
			let count = files.map { escapeHatch.count(in: $0.syntax) }.sum
			#expect(count <= budget, "`\(escapeHatch)` is used \(count) times, which is more than its budget of \(budget). Use a typed modifier or value instead, like `.frame(maxWidth:)` or `LengthPercentage.clamp()`, or add one to SiteKit. If a string is the only way, raise the budget in `escapeHatchBudgets` with a comment that tells why.")
		}
	}

	/**
	The text of each Swift source file.
	*/
	private static func swiftSources() async throws -> [String] {
		try await SwiftSourceFile.all.value.map(\.text)
	}

	/**
	The syntax of each Swift source file, with the IDs that it declares in its `ScriptIDSet` enums and the data attributes that it declares in its `ScriptDataAttributeSet` enums, like the nested `IDs` and `Hooks` of a component, by the name of the case, and the states that it declares in its `ElementStateSet` enums, like the nested `States` of a component, by their raw values.
	*/
	private static let declarations = Task {
		try await SwiftSourceFile.all.value.map { file in
			(
				syntax: file.syntax,
				ids: declaredHooks(in: file.syntax, conformingTo: "ScriptIDSet"),
				// The raw value of a data attribute is the name after `data-` (`attributeName`).
				attributes: declaredHooks(in: file.syntax, conformingTo: "ScriptDataAttributeSet").mapValues { "data-\($0)" },
				states: declaredStates(in: file.syntax)
			)
		}
	}

	/**
	The inline scripts of a source, as they are written: the string literals of `ElementScript(inline:)`, and of `HTMLRaw(…)` in `script { … }`.
	*/
	private static func inlineScripts(in syntax: SourceFileSyntax) -> [String] {
		let elementScripts = syntax.calls(named: "ElementScript").filter { $0.arguments.first?.label?.text == "inline" }
		let pageScripts = syntax.calls(named: "HTMLRaw").filter { $0.enclosingCallName == "script" }
		return (elementScripts + pageScripts).compactMap(\.firstStringLiteral?.sourceContent)
	}

	private static func declaredHooks(in syntax: SourceFileSyntax, conformingTo protocolName: String) -> [String: String] {
		Dictionary(syntax.enums(conformingTo: protocolName).flatMap(\.cases), uniquingKeysWith: { first, _ in first })
	}

	private static func declaredStates(in syntax: SourceFileSyntax) -> Set<String> {
		Set(syntax.enums(conformingTo: "ElementStateSet").flatMap(\.cases).map(\.rawValue))
	}

	/**
	The text of every script: the files in `public/scripts`, the scripts of content files, like the script of an app page, the scripts of elements next to their Swift files, and the inline scripts in the Swift sources. Inline scripts refer to hooks with `IDs.x.id` and `Hooks.x.attributeName`, which are replaced with the ID and the data attribute. Comment lines are left out, so an example in a comment, like `#id`, is not a hook.
	*/
	private static func scripts() async throws -> String {
		let files = try (Project.website.publicDirectory.appending(path: "scripts").filesRecursively() + Project.website.contentDirectory.filesRecursively() + SwiftSourceFile.directory.filesRecursively())
			.filter { $0.pathExtension == "js" }
			.map { try String(contentsOf: $0, encoding: .utf8) }

		let inlineScripts = try await declarations.value.flatMap { syntax, ids, attributes, _ in
			Self.inlineScripts(in: syntax).map { script in
				script
					.replacing(/\\#\(IDs\.(\w+)\.id\)/) { reference in
						ids[String(reference.1)] ?? String(reference.0)
					}
					.replacing(/\\#\(Hooks\.(\w+)\.attributeName\)/) { reference in
						attributes[String(reference.1)] ?? String(reference.0)
					}
			}
		}

		return (files + inlineScripts)
			.joined(separator: "\n")
			.split(separator: "\n")
			.filter { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("//") }
			.joined(separator: "\n")
	}

	/**
	The data attributes that the Markdown renderer of SiteKit adds, which `site.js` uses.
	*/
	private static let markdownHooks: Set = ["data-copy-link"]

	/**
	The data attribute of the parts of elements (`ElementPartSet` in SiteKit), which `scripted-element.js` uses. The `ScriptedElementTests` check the parts.
	*/
	private static let elementHooks: Set = ["data-part"]

	/**
	The IDs of all the `ScriptIDSet` enums in the Swift sources.
	*/
	private static func allDeclaredIDs() async throws -> Set<String> {
		Set(try await declarations.value.flatMap(\.ids.values))
	}

	/**
	The data attributes of all the `ScriptDataAttributeSet` enums in the Swift sources.
	*/
	private static func allDeclaredAttributes() async throws -> Set<String> {
		Set(try await declarations.value.flatMap(\.attributes.values))
	}

	@Test
	func `every script hook is used by a script`() async throws {
		let scripts = try await Self.scripts()
		#expect(!scripts.isEmpty)

		let ids = try await Self.allDeclaredIDs()
		let attributes = try await Self.allDeclaredAttributes()
		#expect(ids.count > 50)
		#expect(attributes.count > 50)

		// The whole names that the scripts use, found once, so a longer name, like `#geocities-defrag-start` for `geocities-defrag`, is not a use of the shorter one.
		let usedNames = Set(scripts.matches(of: /[#'"`\[]([a-zA-Z][\w-]*)/).map { String($0.1) })
		let usedDatasetNames = Set(scripts.matches(of: /dataset\.(\w+)/).map { String($0.1) })

		for id in ids {
			#expect(usedNames.contains(id), "No script uses the ID \(id). Remove it, or fix the script.")
		}

		for attribute in attributes {
			let parts = attribute.dropFirst("data-".count).split(separator: "-")
			let datasetName = String(parts.first ?? "") + parts.dropFirst().map(\.capitalized).joined()
			let isUsed = usedNames.contains(attribute) || usedDatasetNames.contains(datasetName)
			#expect(isUsed, "No script uses the attribute \(attribute). Remove it, or fix the script.")
		}
	}

	/**
	The other direction: a script that finds an element by an ID or a data attribute that the Swift code no longer sets would silently do nothing. Custom properties that scripts set must be declared as a `StyleVariable` or `RegisteredProperty`, and states that scripts set, also the page scripts, must be a case of the `States` of a component (`ElementStateSet`). Limitation: A page script is not tied to a component, so its states only need to be a case of any `States`. The `ScriptedElementTests` check the states of each element against its own `States`, and that they are styled.
	*/
	@Test
	func `every hook that a script uses is declared in Swift`() async throws {
		let scripts = try await Self.scripts()
		let swift = try await Self.swiftSources().joined(separator: "\n")
		let declaredIDs = try await Self.allDeclaredIDs()
		let declaredAttributes = try await Self.allDeclaredAttributes()

		let ids = Set(scripts.matches(of: /getElementById\('([\w-]+)'\)|['"`]#([a-zA-Z][\w-]*)/).compactMap { match -> String? in (match.1 ?? match.2).map { String($0) } })
			// Hex colors, like `'#ec4899'`, look like IDs.
			.filter { $0.wholeMatch(of: /[0-9a-fA-F]{3,8}/) == nil }
		#expect(ids.subtracting(declaredIDs).sorted() == [], "Scripts use these IDs, but no `IDs` of a component has them.")

		let attributes = Set(scripts.matches(of: /\[(data-[\w-]+)/).map { String($0.1) })
		let undeclaredAttributes = attributes.subtracting(declaredAttributes).subtracting(Self.markdownHooks).subtracting(Self.elementHooks)
		#expect(undeclaredAttributes.sorted() == [], "Scripts use these data attributes, but no `Hooks` of a component has them.")

		let variables = Set(scripts.matches(of: /setProperty\('(--[\w-]+)'/).map { String($0.1) })
		let declaredVariables = Set(swift.matches(of: /(?:StyleVariable|RegisteredProperty)<[^>]+>\("([\w-]+)"/).map { "--\($0.1)" })
		#expect(variables.count > 10)
		#expect(variables.subtracting(declaredVariables).sorted() == [], "Scripts set these custom properties, but no `StyleVariable` declares them.")

		let states = try await Set(Self.declarations.value.flatMap(\.states))
		#expect(states.count > 100)
		#expect(scripts.assignedDataStates.count > 50)
		#expect(scripts.assignedDataStates.subtracting(states).sorted() == [], "Scripts set these states, but no `States` of a component has them.")
	}

	/**
	An ID must not start with `data-`, so it does not look like a data attribute. A data attribute gets its `data-` from `attributeName`, so its raw value does not repeat it.
	*/
	@Test
	func `the IDs and the raw values of the data attributes do not start with data-`() async throws {
		let ids = try await Self.allDeclaredIDs()
		let attributes = try await Self.allDeclaredAttributes()
		#expect(ids.filter { $0.hasPrefix("data-") }.sorted() == [], "These IDs start with `data-`. Move them to the `Hooks` of the component.")
		#expect(attributes.filter { $0.hasPrefix("data-data-") }.sorted() == [], "The raw values of these data attributes start with `data-`, which `attributeName` already adds.")
	}

	/**
	A code example in a doc comment is not a declaration, and the layout of the cases does not matter.
	*/
	@Test
	func `the declared states are the cases of the state enums, by their raw values`() {
		let source = """
		/**
		enum Example: String, ElementStateSet {
			case example
		}
		*/
		struct BuddyList {
			enum Parts: String, ElementPartSet {
				case screen
			}

			enum States: String, ElementStateSet {
				case on
				case signingOn = "signing-on"
				case `default`
				case away, idle = "is-idle"
			}
		}
		"""

		#expect(Self.declaredStates(in: Parser.parse(source: source)) == ["on", "signing-on", "default", "away", "is-idle"])
		let hooks = Parser.parse(source: "enum IDs: String, ScriptIDSet { case menu = \"site-menu\" }; enum Hooks: String, ScriptDataAttributeSet { case theme = \"mac-theme\" }")
		#expect(Self.declaredHooks(in: hooks, conformingTo: "ScriptIDSet") == ["menu": "site-menu"])
		#expect(Self.declaredHooks(in: hooks, conformingTo: "ScriptDataAttributeSet") == ["theme": "mac-theme"])
	}
}
