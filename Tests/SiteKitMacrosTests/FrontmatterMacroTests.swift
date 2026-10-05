import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacrosGenericTestSupport
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
				@Key("date") public var publicationDate: Date
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

				enum CodingKeys: Swift.String, Swift.CodingKey {
					case title
					case description
					case tags
					case counts
					case links
					case publicationDate = "date"
					case isPinned
				}

				public init(from decoder: any Swift.Decoder) throws {
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
	func `infers the type of literal default values`() {
		assertMacroExpansion(
			#"""
			@Frontmatter
			struct Post {
				var isDraft = false
				var isPinned = true
				var title = "Untitled"
				var subtitle = #"A "quoted" title"#
				var count = 3
				var offset = -2
				var scale = 1.5
				var adjustment = -0.5
			}
			"""#,
			expandedSource: #"""
			struct Post {
				var isDraft = false
				var isPinned = true
				var title = "Untitled"
				var subtitle = #"A "quoted" title"#
				var count = 3
				var offset = -2
				var scale = 1.5
				var adjustment = -0.5

				enum CodingKeys: Swift.String, Swift.CodingKey {
					case isDraft
					case isPinned
					case title
					case subtitle
					case count
					case offset
					case scale
					case adjustment
				}

				init(from decoder: any Swift.Decoder) throws {
					let container = try decoder.container(keyedBy: CodingKeys.self)
					self.isDraft = try container.decodeIfPresent(Bool.self, forKey: .isDraft) ?? false
					self.isPinned = try container.decodeIfPresent(Bool.self, forKey: .isPinned) ?? true
					self.title = try container.decodeIfPresent(String.self, forKey: .title) ?? "Untitled"
					self.subtitle = try container.decodeIfPresent(String.self, forKey: .subtitle) ?? #"A "quoted" title"#
					self.count = try container.decodeIfPresent(Int.self, forKey: .count) ?? 3
					self.offset = try container.decodeIfPresent(Int.self, forKey: .offset) ?? -2
					self.scale = try container.decodeIfPresent(Double.self, forKey: .scale) ?? 1.5
					self.adjustment = try container.decodeIfPresent(Double.self, forKey: .adjustment) ?? -0.5
				}
			}

			extension Post: SiteKit.Frontmatter {
			}
			"""#,
			macroSpecs: macros,
			indentationWidth: .tab
		)
	}

	@Test
	func `decodes property wrappers by their wrapped value`() {
		assertMacroExpansion(
			"""
			@Frontmatter
			struct Post {
				@NonEmpty var title: String
				@NonEmpty var description: String?
				@Absolute var url: Optional<URL>
				@NonEmpty var category = "General"

				@Key("date")
				@CalendarDay var publicationDate: Date
			}
			""",
			expandedSource: """
			struct Post {
				@NonEmpty var title: String
				@NonEmpty var description: String?
				@Absolute var url: Optional<URL>
				@NonEmpty var category = "General"
				@CalendarDay var publicationDate: Date

				enum CodingKeys: Swift.String, Swift.CodingKey {
					case title
					case description
					case url
					case category
					case publicationDate = "date"
				}

				init(from decoder: any Swift.Decoder) throws {
					let container = try decoder.container(keyedBy: CodingKeys.self)
					self.title = try container.decode(NonEmpty<String>.self, forKey: .title).wrappedValue
					self.description = try container.decodeIfPresent(NonEmpty<String>.self, forKey: .description)?.wrappedValue
					self.url = try container.decodeIfPresent(Absolute<URL>.self, forKey: .url)?.wrappedValue
					self.category = try container.decodeIfPresent(NonEmpty<String>.self, forKey: .category)?.wrappedValue ?? "General"
					self.publicationDate = try container.decode(CalendarDay<Date>.self, forKey: .publicationDate).wrappedValue
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
			#"""
			@Frontmatter
			struct Post {
				let title = "Untitled"
				var greeting = "Hello \(name)"
				var limit = Int.max
				var negated = -true
			}
			"""#,
			expandedSource: #"""
			struct Post {
				let title = "Untitled"
				var greeting = "Hello \(name)"
				var limit = Int.max
				var negated = -true
			}

			extension Post: SiteKit.Frontmatter {
			}
			"""#,
			diagnostics: [
				DiagnosticSpec(message: "A property with a default value must be a 'var', so it can be decoded", line: 3, column: 6),
				DiagnosticSpec(message: "'@Frontmatter' requires a type annotation, a literal default value like 'false', or an empty initializer like '[String]()', because macros cannot infer other types", line: 4, column: 6),
				DiagnosticSpec(message: "'@Frontmatter' requires a type annotation, a literal default value like 'false', or an empty initializer like '[String]()', because macros cannot infer other types", line: 5, column: 6),
				DiagnosticSpec(message: "'@Frontmatter' requires a type annotation, a literal default value like 'false', or an empty initializer like '[String]()', because macros cannot infer other types", line: 6, column: 6),
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
