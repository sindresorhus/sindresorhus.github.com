import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacrosTestSupport
import Testing

#if canImport(SiteKitMacros)
import SiteKitMacros

@Suite
struct FrontmatterMacroTests {
	private let macros = [
		"Frontmatter": MacroSpec(type: FrontmatterMacro.self, conformances: ["Frontmatter"]),
		"Key": MacroSpec(type: KeyMacro.self),
	]

	@Test
	func `generates strict decoding with defaults and renamed keys`() {
		assertMacroExpansion(
			"""
			@Frontmatter
			public struct Post {
				public var title: String
				public var description: String?
				public var tags = [String]()
				public var counts = [String: Int]()
				public var links = OrderedMapping<URL>()
				@Key("pubDate") public var publicationDate: Date
				public var isPinned: Bool? = false

				public var slug: String {
					title.lowercased()
				}

				static let directory = "posts"
			}
			""",
			expandedSource: """
			public struct Post {
				public var title: String
				public var description: String?
				public var tags = [String]()
				public var counts = [String: Int]()
				public var links = OrderedMapping<URL>()
				public var publicationDate: Date
				public var isPinned: Bool? = false

				public var slug: String {
					title.lowercased()
				}

				static let directory = "posts"

				enum CodingKeys: Swift.String, Swift.CodingKey, Swift.CaseIterable {
					case title
					case description
					case tags
					case counts
					case links
					case publicationDate = "pubDate"
					case isPinned
				}

				public init(from decoder: any Swift.Decoder) throws {
					try decoder.rejectUnknownKeys(CodingKeys.self)
					let container = try decoder.container(keyedBy: CodingKeys.self)
					self.title = try container.decode(String.self, forKey: .title)
					self.description = try container.decodeIfPresent(String.self, forKey: .description)
					self.tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? [String]()
					self.counts = try container.decodeIfPresent([String: Int].self, forKey: .counts) ?? [String: Int]()
					self.links = try container.decodeIfPresent(OrderedMapping<URL>.self, forKey: .links) ?? OrderedMapping<URL>()
					self.publicationDate = try container.decode(Date.self, forKey: .publicationDate)
					self.isPinned = try container.decodeIfPresent(Bool.self, forKey: .isPinned) ?? false
				}
			}

			extension Post: SiteKit.Frontmatter {
			}
			""",
			macroSpecs: macros,
			indentationWidth: .tab
		)
	}

	@Test
	func `rejects properties it cannot decode`() {
		assertMacroExpansion(
			"""
			@Frontmatter
			struct Post {
				let title = "Untitled"
				var count = 0
			}
			""",
			expandedSource: """
			struct Post {
				let title = "Untitled"
				var count = 0
			}

			extension Post: SiteKit.Frontmatter {
			}
			""",
			diagnostics: [
				DiagnosticSpec(message: "A property with a default value must be a 'var', so it can be decoded", line: 3, column: 6),
				DiagnosticSpec(message: "'@Frontmatter' requires a type annotation, or an empty initializer like '[String]()', because macros cannot infer types", line: 4, column: 6),
			],
			macroSpecs: macros,
			indentationWidth: .tab
		)
	}

	@Test
	func `only applies to structs`() {
		assertMacroExpansion(
			"""
			@Frontmatter
			class Post {}
			""",
			expandedSource: """
			class Post {}
			""",
			diagnostics: [
				DiagnosticSpec(message: "'@Frontmatter' can only be applied to a struct", line: 1, column: 1),
			],
			macroSpecs: macros,
			indentationWidth: .tab
		)
	}
}
#endif
