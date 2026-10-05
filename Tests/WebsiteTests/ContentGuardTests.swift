import Foundation
import SiteKit
import Testing
@testable import Website

/**
Checks the real content files in `content/`.
*/
@Suite
struct ContentGuardTests {
	private static let contentDirectory = Project.website.contentDirectory

	/**
	Styles and scripts belong to components, not content. Astro attributes like `is:inline` do nothing in the Swift build and publish invalid HTML.

	A file that is older than this rule can be listed here with the patterns it keeps. No file needs it now.
	*/
	private static let allowed: [String: Set<Pattern>] = [:]

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
		let files = try Self.contentDirectory.filesRecursively().filter { $0.pathExtension == "md" }
		#expect(!files.isEmpty)

		for file in files {
			let contents = try String(contentsOf: file, encoding: .utf8)
			let path = file.path(relativeTo: Self.contentDirectory)
			let found = Set(Pattern.allCases.filter { contents.contains($0.regex) })
			let allowed = Self.allowed[path] ?? []

			#expect(found.isSubset(of: allowed), "Move the styles or scripts of \(path) into a component: \(found.subtracting(allowed))")
			#expect(allowed.isSubset(of: found), "Remove the cleaned-up patterns of \(path) from the allowlist: \(allowed.subtracting(found))")
		}
	}
}

/**
Checks the source of the site.
*/
@Suite
struct SourceGuardTests {
	private static let sourceDirectory = Project.website.root.appending(path: "Sources/Website")

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
	func `selector rules are only where components do not own the markup`() throws {
		let files = try Self.sourceDirectory.filesRecursively().filter { $0.pathExtension == "swift" }
		#expect(!files.isEmpty)

		let filesWithRules = try Set(files
			.filter { try String(contentsOf: $0, encoding: .utf8).contains(/\bRule\(/) }
			.map { $0.path(relativeTo: Self.sourceDirectory) })

		#expect(filesWithRules.subtracting(Self.filesWithSelectorRules).isEmpty, "Use a style set instead of a selector rule in: \(filesWithRules.subtracting(Self.filesWithSelectorRules).sorted())")
		#expect(Self.filesWithSelectorRules.subtracting(filesWithRules).isEmpty, "Remove the files without selector rules from the allowlist.")
	}

	/**
	The escape hatches that write CSS as a string, with the number of uses that the source may have. Typed modifiers and values catch mistakes when the code compiles, so the counts must not grow. Lower a budget when uses are removed.
	*/
	private static let escapeHatchBudgets = [
		".declaration(": 61,
		"Length(\"": 0,
		"CSSValue(\"": 5,
		".nested(\"": 72,
	]

	@Test
	func `escape hatches stay within their budgets`() throws {
		let source = try Self.swiftSources().joined(separator: "\n")
		#expect(!source.isEmpty)

		for (escapeHatch, budget) in Self.escapeHatchBudgets {
			let count = source.ranges(of: escapeHatch).count
			#expect(count <= budget, "`\(escapeHatch)` is used \(count) times, which is more than its budget of \(budget). Use a typed modifier or value instead, like `.frame(maxWidth:)` or `Length.clamp()`, or add one to SiteKit. If a string is the only way, raise the budget in `escapeHatchBudgets` with a comment that tells why.")
		}
	}

	/**
	The text of each Swift source file.
	*/
	private static func swiftSources() throws -> [String] {
		try sourceDirectory.filesRecursively()
			.filter { $0.pathExtension == "swift" }
			.map { try String(contentsOf: $0, encoding: .utf8) }
	}

	/**
	The hooks that a Swift source declares in its `ScriptHookSet` enums, like the nested `Hooks` of a component, by the name of the case. Doc comments are left out, so a code example is not a declaration.
	*/
	private static func declaredHooks(in source: String) -> [String: String] {
		let enums = source.replacing(/\/\*\*.*?\*\//.dotMatchesNewlines(), with: "").matches(of: /enum \w+:[^{\n]*\bScriptHookSet\b[^{\n]*\{(.*?)\n\t*\}\n/.dotMatchesNewlines()).map(\.1)
		let cases = enums.flatMap { $0.matches(of: /case (\w+) = "([^"]+)"/) }
		return Dictionary(cases.map { (String($0.1), String($0.2)) }, uniquingKeysWith: { first, _ in first })
	}

	/**
	The text of every script: the files in `public/scripts`, the scripts of content files, like the script of an app page, the scripts of elements next to their Swift files, and the inline scripts in the Swift sources. Inline scripts refer to hooks with `Hooks` or `ScriptAttribute`, which is replaced with the hook. Comment lines are left out, so an example in a comment, like `#id`, is not a hook.
	*/
	private static func scripts() throws -> String {
		let files = try (Project.website.publicDirectory.appending(path: "scripts").filesRecursively() + Project.website.contentDirectory.filesRecursively() + sourceDirectory.filesRecursively())
			.filter { $0.pathExtension == "js" }
			.map { try String(contentsOf: $0, encoding: .utf8) }

		let sources = try swiftSources()
		let sharedHooks = declaredHooks(in: sources.first { $0.contains("protocol ScriptHookSet") } ?? "")
		let inlineScripts = sources.flatMap { source in
			let hooks = declaredHooks(in: source).merging(sharedHooks) { local, _ in local }
			return source.matches(of: /(?:script \{\s*HTMLRaw|ElementScript)\((?:inline: )?#\"\"\"(.*?)\"\"\"#\)/.dotMatchesNewlines()).map { match in
				String(match.1).replacing(/\\#\((?:Hooks|ScriptAttribute)\.(\w+)\.rawValue\)/) { reference in
					hooks[String(reference.1)] ?? String(reference.0)
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
	The hooks of all the `ScriptHookSet` enums in the Swift sources.
	*/
	private static func allDeclaredHooks() throws -> Set<String> {
		Set(try swiftSources().flatMap { declaredHooks(in: $0).values })
	}

	@Test
	func `every script hook is used by a script`() throws {
		let scripts = try Self.scripts()
		#expect(!scripts.isEmpty)

		let hooks = try Self.allDeclaredHooks()
		#expect(hooks.count > 50)

		for hook in hooks {
			if hook.hasPrefix("data-") {
				let parts = hook.dropFirst("data-".count).split(separator: "-")
				let datasetName = String(parts.first ?? "") + parts.dropFirst().map(\.capitalized).joined()
				let isUsed = scripts.contains("[\(hook)") || scripts.contains("dataset.\(datasetName)") || scripts.contains("'\(hook)'")
				#expect(isUsed, "No script uses the attribute \(hook). Remove it, or fix the script.")
			} else {
				let isUsed = scripts.contains("#\(hook)") || scripts.contains("'\(hook)'")
				#expect(isUsed, "No script uses the ID \(hook). Remove it, or fix the script.")
			}
		}
	}

	/**
	The other direction: a script that finds an element by an ID or a data attribute that the Swift code no longer sets would silently do nothing. Custom properties that scripts set must be declared as a `StyleVariable` or `RegisteredProperty`, and states that scripts set must be styled with `when(.state, is:)`.
	*/
	@Test
	func `every hook that a script uses is declared in Swift`() throws {
		let scripts = try Self.scripts()
		let swift = try Self.swiftSources().joined(separator: "\n")
		let hooks = try Self.allDeclaredHooks()

		let ids = Set(scripts.matches(of: /getElementById\('([\w-]+)'\)|['"`]#([a-zA-Z][\w-]*)/).compactMap { match -> String? in (match.1 ?? match.2).map { String($0) } })
			// Hex colors, like `'#ec4899'`, look like IDs.
			.filter { $0.wholeMatch(of: /[0-9a-fA-F]{3,8}/) == nil }
		#expect(ids.subtracting(hooks).sorted() == [], "Scripts use these IDs, but no `Hooks` of a component has them.")

		let attributes = Set(scripts.matches(of: /\[(data-[\w-]+)/).map { String($0.1) })
		let undeclaredAttributes = attributes.subtracting(hooks).subtracting(Self.markdownHooks).subtracting(Self.elementHooks)
		#expect(undeclaredAttributes.sorted() == [], "Scripts use these data attributes, but no `Hooks` of a component, or `ScriptAttribute`, has them.")

		let variables = Set(scripts.matches(of: /setProperty\('(--[\w-]+)'/).map { String($0.1) })
		let undeclaredVariables = variables.filter { !swift.contains(try! Regex(#"(StyleVariable|RegisteredProperty)<[^>]+>\("\#($0)""#)) }
		#expect(undeclaredVariables.sorted() == [], "Scripts set these custom properties, but no `StyleVariable` declares them.")

		let states = Set(scripts.matches(of: /dataset\.state = '([\w-]+)'/).map { String($0.1) })
		#expect(states.filter { !swift.contains(".when(.state, is: \"\($0)\")") }.sorted() == [], "Scripts set these states, but no style uses them.")
	}
}
