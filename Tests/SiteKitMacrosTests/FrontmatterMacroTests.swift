import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacrosGenericTestSupport
import SwiftSyntaxMacrosTestSupport
import Testing

#if canImport(SiteKitMacros)
import SiteKitMacros

struct FrontmatterMacroTests {
	private let macros = [
		"Frontmatter": MacroSpec(type: FrontmatterMacro.self, conformances: ["Frontmatter"]),
		"Key": MacroSpec(type: KeyMacro.self),
	]

	@Test
	func `a renamed key and validation wrapper are parsed together`() {
		assertMacroExpansion(
			"""
			@Frontmatter
			struct Metadata {
				@Key("name") @NonEmpty var title: String?
			}
			""",
			expandedSource: """
			struct Metadata {
				@NonEmpty var title: String?

				enum CodingKeys: Swift.String, Swift.CodingKey, Swift.CaseIterable {
					case title = "name"
				}

				init(from decoder: any Swift.Decoder) throws {
					let container = try decoder.container(keyedBy: CodingKeys.self)
					self.title = try container.decodeIfPresent(NonEmpty<String>.self, forKey: .title)?.wrappedValue
				}
			}

			extension Metadata: SiteKit.Frontmatter {
			}
			""",
			macroSpecs: macros,
			indentationWidth: .tab
		)
	}

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

				public enum CodingKeys: Swift.String, Swift.CodingKey, Swift.CaseIterable {
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
					self.tags = container.contains(.tags) ? try container.decode([String].self, forKey: .tags) : [String]()
					self.counts = container.contains(.counts) ? try container.decode([String: Int].self, forKey: .counts) : [String: Int]()
					self.links = container.contains(.links) ? try container.decode(OrderedMapping<URL>.self, forKey: .links) : OrderedMapping<URL>()
					self.publicationDate = try container.decode(Date.self, forKey: .publicationDate)
					self.isPinned = container.contains(.isPinned) ? try container.decodeIfPresent(Bool.self, forKey: .isPinned) : false
				}
			}

			extension Post: SiteKit.Frontmatter {
			}
			""",
			macroSpecs: macros,
			indentationWidth: .tab
		)
	}

	@Test(arguments: ["", "public ", "package "])
	func `diagnostic keys have the access of their frontmatter type`(access: String) {
		assertMacroExpansion(
			"""
			@Frontmatter
			\(access)struct Metadata {
				@Key("name") var title: String
			}
			""",
			expandedSource: """
			\(access)struct Metadata {
				var title: String

				\(access)enum CodingKeys: Swift.String, Swift.CodingKey, Swift.CaseIterable {
					case title = "name"
				}

				\(access)init(from decoder: any Swift.Decoder) throws {
					let container = try decoder.container(keyedBy: CodingKeys.self)
					self.title = try container.decode(String.self, forKey: .title)
				}
			}

			extension Metadata: SiteKit.Frontmatter {
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

				enum CodingKeys: Swift.String, Swift.CodingKey, Swift.CaseIterable {
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
					self.isDraft = container.contains(.isDraft) ? try container.decode(Bool.self, forKey: .isDraft) : false
					self.isPinned = container.contains(.isPinned) ? try container.decode(Bool.self, forKey: .isPinned) : true
					self.title = container.contains(.title) ? try container.decode(String.self, forKey: .title) : "Untitled"
					self.subtitle = container.contains(.subtitle) ? try container.decode(String.self, forKey: .subtitle) : #"A "quoted" title"#
					self.count = container.contains(.count) ? try container.decode(Int.self, forKey: .count) : 3
					self.offset = container.contains(.offset) ? try container.decode(Int.self, forKey: .offset) : -2
					self.scale = container.contains(.scale) ? try container.decode(Double.self, forKey: .scale) : 1.5
					self.adjustment = container.contains(.adjustment) ? try container.decode(Double.self, forKey: .adjustment) : -0.5
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
				var publicationDate: SOML.Date
			}
			""",
			expandedSource: """
			struct Post {
				@NonEmpty var title: String
				@NonEmpty var description: String?
				@Absolute var url: Optional<URL>
				@NonEmpty var category = "General"
				var publicationDate: SOML.Date

				enum CodingKeys: Swift.String, Swift.CodingKey, Swift.CaseIterable {
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
					self.category = container.contains(.category) ? try container.decode(NonEmpty<String>.self, forKey: .category).wrappedValue : "General"
					self.publicationDate = try container.decode(SOML.Date.self, forKey: .publicationDate)
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
	func `renamed keys preserve string literal escapes`() {
		assertMacroExpansion(
			#"""
			@Frontmatter
			struct Post {
				@Key("d\u{61}te") var publicationDate: Date
			}
			"""#,
			expandedSource: #"""
			struct Post {
				var publicationDate: Date

				enum CodingKeys: Swift.String, Swift.CodingKey, Swift.CaseIterable {
					case publicationDate = "d\u{61}te"
				}

				init(from decoder: any Swift.Decoder) throws {
					let container = try decoder.container(keyedBy: CodingKeys.self)
					self.publicationDate = try container.decode(Date.self, forKey: .publicationDate)
				}
			}

			extension Post: SiteKit.Frontmatter {
			}
			"""#,
			macroSpecs: macros,
			indentationWidth: .tab
		)
	}

	@Test(arguments: ["@Key", "@Key()", #"@Key("date", "other")"#, #"@Key(name: "date")"#, "@Key(name)", #"@Key("date\(suffix)")"#])
	func `renamed keys require one string literal without interpolation`(attribute: String) {
		assertMacroExpansion(
			"""
			@Frontmatter
			struct Post {
				\(attribute) var publicationDate: Date
			}
			""",
			expandedSource: """
			struct Post {
				var publicationDate: Date
			}

			extension Post: SiteKit.Frontmatter {
			}
			""",
			diagnostics: [
				DiagnosticSpec(message: "'@Key' requires one string literal without interpolation.", line: 3, column: 2),
			],
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
	func `rejects a struct without stored properties`() {
		assertMacroExpansion(
			"""
			@Frontmatter
			struct Post {
				static let directory = "posts"
			}
			""",
			expandedSource: """
			struct Post {
				static let directory = "posts"
			}

			extension Post: SiteKit.Frontmatter {
			}
			""",
			diagnostics: [
				DiagnosticSpec(message: "'@Frontmatter' requires at least one stored property", line: 1, column: 1),
			],
			macroSpecs: macros,
			indentationWidth: .tab
		)
	}

	@Test
	func `rejects a property in a conditional block`() {
		assertMacroExpansion(
			"""
			@Frontmatter
			struct Post {
				var title: String
				#if os(macOS)
				var windowSize: Int
				#if DEBUG
				var debugName: String
				#endif
				#endif
			}
			""",
			expandedSource: """
			struct Post {
				var title: String
				#if os(macOS)
				var windowSize: Int
				#if DEBUG
				var debugName: String
				#endif
				#endif
			}

			extension Post: SiteKit.Frontmatter {
			}
			""",
			diagnostics: [
				DiagnosticSpec(message: "A property in an '#if' block cannot be decoded, so '@Frontmatter' does not support it. Move it out of the conditional block.", line: 5, column: 2),
				DiagnosticSpec(message: "A property in an '#if' block cannot be decoded, so '@Frontmatter' does not support it. Move it out of the conditional block.", line: 7, column: 2),
			],
			macroSpecs: macros,
			indentationWidth: .tab
		)
	}

	@Test
	func `rejects stacked validation wrappers instead of ignoring one`() {
		assertMacroExpansion(
			"""
			@Frontmatter
			struct Metadata {
				@Key("name")
				@First
				@Second
				var title: String
			}
			""",
			expandedSource: """
			struct Metadata {
				@First
				@Second
				var title: String
			}

			extension Metadata: SiteKit.Frontmatter {
			}
			""",
			diagnostics: [DiagnosticSpec(message: "'@Frontmatter' supports only one validation property wrapper per property.", line: 5, column: 2)],
			macroSpecs: macros,
			indentationWidth: .tab
		)
	}

	@Test
	func `rejects an attribute with arguments`() {
		assertMacroExpansion(
			"""
			@Frontmatter
			struct Post {
				var title: String
				@Environment(\\.locale) var locale: String
			}
			""",
			expandedSource: """
			struct Post {
				var title: String
				@Environment(\\.locale) var locale: String
			}

			extension Post: SiteKit.Frontmatter {
			}
			""",
			diagnostics: [
				DiagnosticSpec(message: "'@Frontmatter' supports only '@Key' and a property wrapper without arguments, like '@NonEmpty', got '@Environment(\\.locale)'.", line: 4, column: 2),
			],
			macroSpecs: macros,
			indentationWidth: .tab
		)
	}

	@Test(arguments: ["static var title: String", "var title: String { \"Text\" }", "func title() {}"])
	func `a key rejects declarations that are not stored instance properties`(declaration: String) {
		assertMacroExpansion(
			"""
			struct Metadata {
				@Key("title")
				\(declaration)
			}
			""",
			expandedSource: """
			struct Metadata {
				\(declaration)
			}
			""",
			diagnostics: [DiagnosticSpec(message: "'@Key' can only be applied to a stored instance property.", line: 2, column: 2)],
			macroSpecs: macros,
			indentationWidth: .tab
		)
	}

	@Test
	func `a property can only declare one wire key`() {
		assertMacroExpansion(
			"""
			@Frontmatter
			struct Metadata {
				@Key("first")
				@Key("second")
				var title: String
			}
			""",
			expandedSource: """
			struct Metadata {
				var title: String
			}

			extension Metadata: SiteKit.Frontmatter {
			}
			""",
			diagnostics: [DiagnosticSpec(message: "'@Key' can only appear once per property.", line: 4, column: 2)],
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
