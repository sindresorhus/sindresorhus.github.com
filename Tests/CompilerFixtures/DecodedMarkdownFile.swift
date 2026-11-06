import Foundation
import Markdown
import SiteKit

// Type-check against the built SiteKit module. Each INVALID_* flag selects an API misuse that must fail; the default checks the typed diagnostic API.
struct Article: Frontmatter {
	let title: String

	enum CodingKeys: String, CodingKey, CaseIterable {
		case title
	}
}

struct Other: Frontmatter {
	let name: String

	enum CodingKeys: String, CodingKey, CaseIterable {
		case name
	}
}

/**
A directive whose decoded argument model must remain `Article`.
*/
enum ArticleDirective: BlockDirectiveDefinition {
	typealias Arguments = Article
	static let name = "Article"

	static func render(arguments: Article, contentHTML: String, context: MarkdownDocument.Options.BlockDirectiveRenderer.Context) -> String {
		contentHTML
	}
}

enum CustomizationFailure: Error {
	case unrelated
}

let source = try MarkdownFile(contents: "---\ntitle: 'Article'\n---\nBody", url: URL(filePath: "/article.md"))
let file = try source.decoded(as: Article.self)

#if INVALID_FRONTMATTER_KEY
let error = file.error(at: Other.CodingKeys.name, "Wrong model")
#elseif INVALID_DECODED_LINE_KEY
let line = file.line(of: Other.CodingKeys.name)
#elseif INVALID_SOML_LINE_KEY
func wrongKey(_ file: SOMLFile<Article>) -> SiteKit.SourceLocation.Line? {
	file.line(of: Other.CodingKeys.name)
}
#elseif INVALID_ERASED_LINE_KEY
func wrongKey(_ file: some SOMLValueFile) -> SiteKit.SourceLocation.Line? {
	file.line(of: Other.CodingKeys.name)
}
#elseif INVALID_FRONTMATTER_SCHEMA
struct MissingEnumerableKeys: Frontmatter {
	let title: String
	enum CodingKeys: String, CodingKey {
		case title
	}
}
#elseif INVALID_HEADING_ID
let heading = Markdown.Heading(level: .h2, "Title", id: "title")
#elseif INVALID_DIRECTIVE_ERROR
enum Failure: Error {
	case unrelated
}
struct DirectiveValue: Sendable {}
enum Directive: HeadingDirective {
	static let name: HeadingDirectiveName = "directive"
	typealias Value = DirectiveValue
	static func decode(values: [String]) throws(Failure) -> DirectiveValue {
		throw Failure.unrelated
	}
}
#elseif INVALID_MARKDOWN_LINK_ERROR
let invalid = MarkdownDocument.Options(resolveLink: { (_: String) throws(CustomizationFailure) -> String in
	throw .unrelated
})
#elseif INVALID_RELEASE_LINK_ERROR
let invalid = MarkdownDocument.ReleaseNotesOptions(resolveLink: { (_: String) throws(CustomizationFailure) -> String in
	throw .unrelated
})
#elseif INVALID_MARKDOWN_RENDER_ERROR
let invalid = MarkdownDocument.Options.BlockDirectiveRenderer { (_: String) throws(CustomizationFailure) -> String in
	throw .unrelated
}
#elseif INVALID_MARKDOWN_ARGUMENT_RENDER_ERROR
let invalid = MarkdownDocument.Options.BlockDirectiveRenderer { (_: Article, _: String) throws(CustomizationFailure) -> String in
	throw .unrelated
}
#elseif INVALID_MARKDOWN_CONTEXT_RENDER_ERROR
let invalid = MarkdownDocument.Options.BlockDirectiveRenderer { (_: Article, _: String, _: MarkdownDocument.Options.BlockDirectiveRenderer.Context) throws(CustomizationFailure) -> String in
	throw .unrelated
}
#elseif INVALID_MARKDOWN_REWRITE_ERROR
let invalid = MarkdownDocument.Options.BlockDirectiveRenderer(
	rewriteContent: { (_: [any BlockMarkup]) throws(CustomizationFailure) -> [any BlockMarkup] in
		throw .unrelated
	},
	render: { $0 }
)
#elseif INVALID_MARKDOWN_INLINE_ERROR
let invalid = MarkdownDocument.Options.InlineAttributesRenderer { (_: Article, _: String) throws(CustomizationFailure) -> String in
	throw .unrelated
}
#elseif INVALID_BLOCK_DEFINITION_ERROR
enum InvalidDefinition: BlockDirectiveDefinition {
	typealias Arguments = Article
	static let name = "Invalid"

	static func render(arguments: Article, contentHTML: String, context: MarkdownDocument.Options.BlockDirectiveRenderer.Context) throws(CustomizationFailure) -> String {
		throw .unrelated
	}
}
#elseif INVALID_HEADING_DIRECTIVE_NAME
enum InvalidHeadingDirective: HeadingDirective {
	static let name: String = "invalid name"
	typealias Value = [String]
}
#elseif INVALID_DIRECTIVE_ARGUMENT_MODEL
func wrongDirectiveArguments(_ directive: BlockDirective) throws -> Other {
	try directive.arguments(for: ArticleDirective.self)
}
#elseif INVALID_MAPPING_SENDABILITY
final class MutableValue {
	var text = "Value"
}
func requireSendable<Value: Sendable>(_ value: Value) {}
requireSendable(OrderedMapping([("entry", MutableValue())]))
#elseif INVALID_SOURCE_LINE_OFFSET
let offset = 0
let location = SourceLocation.file(URL(filePath: "/article.md"), line: offset)
#elseif INVALID_PLAIN_VALIDATED_VALUE
struct MismatchedPlainValue: PlainValidatedValue {
	let value: Int

	init(validating value: String) throws(ContentError) {
		self.value = value.count
	}
}
#elseif INVALID_CONTENT_DRAFT_WITNESS
struct MissingDraftWitness: ContentEntry {
	typealias Frontmatter = Article
	static let directory: Project.ContentDirectory = "content/articles"
	static let sortOrder = [KeyPathComparator<MissingDraftWitness>]()

	init(file: DecodedMarkdownFile<Article>, project: Project) {}
}
#elseif INVALID_DECODED_FILE
let mismatched = DecodedMarkdownFile(source: source, frontmatter: Other(name: "Other"))
#elseif INVALID_MARKDOWN_SOURCE
let mismatched = MarkdownDocument(rendering: Document(parsing: "First"), source: "Second")
#elseif INVALID_REFINED_URL
var destination = AbsoluteURL(#URL("https://example.com"))
destination = #URL("https://example.com/other")
#elseif INVALID_SLUG
let slug: ContentSlug = String("article")
#elseif INVALID_CONTENT_DIRECTORY
let directory: Project.ContentDirectory = String("content/articles")
#elseif INVALID_RELEASE_NOTES_OPTIONS
let notes = MarkdownDocument(releaseNotes: "Notes", options: MarkdownDocument.Options())
#elseif INVALID_FILE_READ_RESULT
func wrongFileRead(_ url: URL) async -> String {
	await url.cachedValue(using: FileRead<Int, Never>("number") { _ in
		1
	})
}
#else
let line = file.line(of: .title)
let rawLine = source.line(of: Other.CodingKeys.name)
let dynamicLine = file.line(ofValueAt: [Other.CodingKeys.name])
func somlLine(_ file: SOMLFile<Article>) -> SiteKit.SourceLocation.Line? {
	file.line(of: .title)
}
let error = file.error(at: .title, "Title error")
let warning = file.warning(.failedRequest, at: .title, "Title warning")
let rendered = try source.parsedMarkdown(options: .init()).rendered()
let destination = AbsoluteURL(#URL("https://example.com"))
let slug: ContentSlug = "article"
let directory: Project.ContentDirectory = "content/articles"
let notes = MarkdownDocument(releaseNotes: "Notes", options: MarkdownDocument.ReleaseNotesOptions(resolveLink: { $0 }))
let options = MarkdownDocument.Options(
	inlineAttributes: .init { (_: Article, contentHTML) in
		contentHTML
	},
	blockDirectives: ["Article": ArticleDirective.renderer],
	resolveLink: { $0 }
)
enum ValidHeadingDirective: HeadingDirective {
	static let name: HeadingDirectiveName = "article.words"
	typealias Value = [String]
}
func articleArguments(_ directive: BlockDirective) throws -> Article {
	try directive.arguments(for: ArticleDirective.self)
}
func validFileRead(_ url: URL) async -> Int {
	await url.cachedValue(using: FileRead<Int, Never>("number") { _ in
		1
	})
}
#endif
