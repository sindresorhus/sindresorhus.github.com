import Foundation
import Testing
@testable import SiteKit

struct FrontmatterTests {
	@Frontmatter
	struct Defaults {
		var enabled = true
		@NonEmpty var category = "General"
		var optional: Bool?
	}

	@Frontmatter
	struct OptionalDefaults {
		var enabled: Bool? = true
		@NonEmpty var category: String? = "General"
	}

	@Test
	func `explicit null clears optional defaults instead of restoring them`() throws {
		let file = try MarkdownFile(contents: "---\nenabled: null\ncategory: null\n---\nBody", url: URL(filePath: "/content/optional-defaults.md"))
		let explicit = try file.decodeFrontmatter(as: OptionalDefaults.self)

		#expect(explicit.enabled == nil)
		#expect(explicit.category == nil)

		let missing = try JSONDecoder().decode(OptionalDefaults.self, from: Data("{}".utf8))
		#expect(missing.enabled == true)
		#expect(missing.category == "General")
	}

	@Test
	func `missing nonoptional values use defaults while explicit values are decoded`() throws {
		let decoder = JSONDecoder()
		let missing = try decoder.decode(Defaults.self, from: Data("{}".utf8))
		#expect(missing.enabled)
		#expect(missing.category == "General")
		#expect(missing.optional == nil)

		let explicit = try decoder.decode(Defaults.self, from: Data(#"{"enabled":false,"category":"Other","optional":null}"#.utf8))
		#expect(!explicit.enabled)
		#expect(explicit.category == "Other")
		#expect(explicit.optional == nil)
	}

	@Test(arguments: ["enabled", "category"])
	func `explicit null does not use a nonoptional default`(key: String) throws {
		#expect(throws: DecodingError.self) {
			try JSONDecoder().decode(Defaults.self, from: Data("{\"\(key)\":null}".utf8))
		}

		let url = URL(filePath: "/content/defaults.md")
		let file = try MarkdownFile(contents: "---\n\(key): null\n---\nBody", url: url)
		let error = try #require(throws: ContentErrors.self) {
			try file.decodeFrontmatter(as: Defaults.self)
		}.errors[0]
		#expect(error.file == url)
		#expect(error.line == 2)
		#expect(error.reason.contains(key))
	}
}
