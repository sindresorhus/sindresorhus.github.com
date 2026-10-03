import Foundation
import SiteKit
import Testing
@testable import Website

/**
Checks the real content files in `content/`.
*/
@Suite
struct ContentGuardTests {
	private static let contentDirectory = URL(filePath: #filePath)
		.deletingLastPathComponent()
		.deletingLastPathComponent()
		.deletingLastPathComponent()
		.appending(path: "content")

	/**
	Styles and scripts belong to components, not content. Astro attributes like `is:inline` do nothing in the Swift build and publish invalid HTML.

	These files are older than this rule, and keep the listed patterns: the structured data and a hidden note on the about page, and the logo positions and the tweet widget on the supporters page.
	*/
	private static let allowed: [String: Set<Pattern>] = [
		"pages/about.md": [.script, .styleAttribute],
		"pages/supporters.md": [.script, .styleAttribute],
	]

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
	private static let sourceDirectory = URL(filePath: #filePath)
		.deletingLastPathComponent()
		.deletingLastPathComponent()
		.deletingLastPathComponent()
		.appending(path: "Sources/Website")

	/**
	Components style their own markup with style sets, so a style cannot drift from its markup. Selector rules are only for markup that components do not own.
	*/
	private static let filesWithSelectorRules: Set = [
		// The element defaults.
		"Styles/SiteStylesheet.swift",
		// The classes in the raw HTML of the content.
		"Styles/ContentStyles.swift",
		// The `html` and `body` elements, which the document renders without classes.
		"Layout/SiteLayout.swift",
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

	@Test
	func `every script hook is used by a script`() throws {
		let scriptsDirectory = Self.sourceDirectory
			.deletingLastPathComponent()
			.deletingLastPathComponent()
			.appending(path: "public/scripts")

		let scripts = try scriptsDirectory.filesRecursively()
			.filter { $0.pathExtension == "js" }
			.map { try String(contentsOf: $0, encoding: .utf8) }
			.joined(separator: "\n")

		#expect(!scripts.isEmpty)

		for hook in ScriptHook.allCases {
			let isUsed = if let datasetName = hook.datasetName {
				scripts.contains("[\(hook.rawValue)") || scripts.contains("dataset.\(datasetName)")
			} else {
				scripts.contains("#\(hook.rawValue)") || scripts.contains("'\(hook.rawValue)'")
			}

			#expect(isUsed, "No script uses the hook \(hook.rawValue). Remove it, or fix the script.")
		}
	}
}
