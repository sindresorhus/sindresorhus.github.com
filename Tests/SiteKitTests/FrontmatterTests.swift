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

	@Frontmatter
	struct Article {
		@Key("name")
		var title: String
		var tags: [String]
	}

	@Frontmatter
	struct Refined {
		var repositoryURL: AbsoluteURL? = AbsoluteURL(#URL("https://example.com"))
		var version: NonEmptyString?
		var downloadCount: SafeInteger?
	}

	@Test
	func `refined frontmatter retains validated values through decoding and reassignment`() throws {
		var model = try JSONDecoder().decode(Refined.self, from: Data(#"{"repositoryURL":"https://example.com/repo","version":"1.2.0","downloadCount":7000}"#.utf8))
		#expect(model.repositoryURL?.value == #URL("https://example.com/repo"))
		#expect(model.version?.value == "1.2.0")
		#expect(model.downloadCount?.value == 7000)

		#expect(throws: ContentError.self) {
			model.repositoryURL = try AbsoluteURL(validating: #require(URL(string: "relative")))
		}
		#expect(throws: ContentError.self) {
			model.version = try NonEmptyString(validating: " ")
		}
		#expect(throws: ContentError.self) {
			model.downloadCount = try SafeInteger(validating: 0)
		}
		#expect(model.repositoryURL?.value == #URL("https://example.com/repo"))
		#expect(model.version?.value == "1.2.0")
		#expect(model.downloadCount?.value == 7000)

		model.repositoryURL = try AbsoluteURL(validating: #URL("https://example.com/next"))
		#expect(model.repositoryURL?.value == #URL("https://example.com/next"))
	}

	@Test
	func `refined optional frontmatter supports missing values defaults and explicit null`() throws {
		let missing = try JSONDecoder().decode(Refined.self, from: Data("{}".utf8))
		#expect(missing.repositoryURL?.value == #URL("https://example.com"))
		#expect(missing.version == nil)
		#expect(missing.downloadCount == nil)

		let explicit = try JSONDecoder().decode(Refined.self, from: Data(#"{"repositoryURL":null,"version":null,"downloadCount":null}"#.utf8))
		#expect(explicit.repositoryURL == nil)
		#expect(explicit.version == nil)
		#expect(explicit.downloadCount == nil)
	}

	@Test(arguments: [#"{"repositoryURL":"relative"}"#, #"{"version":" "}"#, #"{"downloadCount":0}"#])
	func `refined frontmatter rejects invalid values before exposing a model`(json: String) {
		#expect(throws: DecodingError.self) {
			try JSONDecoder().decode(Refined.self, from: Data(json.utf8))
		}
	}

	@Test
	func `refined values encode as their underlying JSON scalars`() throws {
		let encoder = JSONEncoder()
		encoder.outputFormatting = .withoutEscapingSlashes
		let url = AbsoluteURL(#URL("https://example.com/repository"))
		let text = try NonEmptyString(validating: "Version 2")
		let integer = try SafeInteger(validating: 9_007_199_254_740_991)

		#expect(String(decoding: try encoder.encode(url), as: UTF8.self) == #""https://example.com/repository""#)
		#expect(String(decoding: try encoder.encode(text), as: UTF8.self) == #""Version 2""#)
		#expect(String(decoding: try encoder.encode(integer), as: UTF8.self) == "9007199254740991")
		#expect(try JSONDecoder().decode(AbsoluteURL.self, from: encoder.encode(url)) == url)
		#expect(try JSONDecoder().decode(NonEmptyString.self, from: encoder.encode(text)) == text)
		#expect(try JSONDecoder().decode(SafeInteger.self, from: encoder.encode(integer)) == integer)
		#expect(String(decoding: try encoder.encode(nil as AbsoluteURL?), as: UTF8.self) == "null")
	}

	@Test
	func `plain validators expose the same underlying type while general validators may transform it`() throws {
		struct WordCount: ValidatedValue {
			let count: Int

			init(validating value: String) throws(ContentError) {
				self.count = value.split(whereSeparator: \.isWhitespace).count
			}
		}

		func plainValue<Validation: PlainValidatedValue>(_ value: Validation) -> Validation.RawValue {
			value.value
		}

		#expect(plainValue(try NonEmptyString(validating: "Title")) == "Title")
		#expect(try JSONDecoder().decode(WordCount.self, from: Data(#""two words""#.utf8)).count == 2)
	}

	@Test
	func `generic frontmatter code can enumerate renamed keys in declaration order`() {
		func keys<Value: Frontmatter>(of type: Value.Type) -> [String] {
			Value.CodingKeys.allCases.map(\.stringValue)
		}

		#expect(keys(of: Article.self) == ["name", "tags"])
	}

	@Test
	func `decoded files retain their source and locate diagnostics with their own renamed keys and list items`() throws {
		let url = URL(filePath: "/content/article.md")
		var source = try MarkdownFile(contents: "---\nname: 'Article'\ntags: [\n\t'first'\n\t'second'\n]\n---\nBody", url: url)
		source.lastCommitDate = Date(timeIntervalSince1970: 1234)
		let file = try source.decoded(as: Article.self)

		#expect(file.line(of: .title) == 2)
		#expect(file.line(of: .tags, index: 1) == 5)
		#expect(file.line(ofValueAt: [Article.CodingKeys.tags, AnyCodingKey(intValue: 1)]) == 5)
		#expect(file.frontmatter.title == "Article")
		#expect(file.frontmatter.tags == ["first", "second"])
		#expect(file.source.body == "Body")
		#expect(file.source.lastCommitDate == source.lastCommitDate)
		#expect(file.error(at: .title, "Title error").file == url)
		#expect(file.error(at: .title, "Title error").line == 2)
		#expect(file.warning(.failedRequest, at: .tags, index: 1, "Tag warning").location == .file(url, line: 5))
	}

	@Test
	func `decoded files validate frontmatter before exposing its values`() throws {
		let url = URL(filePath: "/content/defaults.md")
		let source = try MarkdownFile(contents: "---\ncategory: ''\n---\nBody", url: url)
		let errors = try #require(throws: ContentErrors.self) {
			try source.decoded(as: Defaults.self)
		}

		#expect(errors.errors.count == 1)
		#expect(errors.errors.first?.file == url)
		#expect(errors.errors.first?.line == 2)
		#expect(errors.errors.first?.reason.contains("Must not be empty.") == true)
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
