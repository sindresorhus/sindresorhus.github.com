import Elementary
import Foundation
import Markdown
import Testing
import SiteKit

struct MarkdownContentTests {
	/**
	A `@Box` directive with the style of a box.
	*/
	private static let options = MarkdownDocument.Options(
		blockDirectives: [
			"Box": .init { html in
				div {
					HTMLRaw(html)
				}
				.style(BoxStyles.box)
				.render()
			},
		]
	)

	@Test
	func `a page that shows a document gets the styles of its block directives`() throws {
		// The document renders before the page, like the content of the site.
		let document = MarkdownDocument(parsing: "@Box {\nHello\n}", options: Self.options)

		let resources = PageResources()
		let html = try resources.collect {
			div {
				document.content
			}
			.render()
		}

		#expect(html.contains(#"<div class="box-box"><p>Hello</p>"#))

		let css = Stylesheet {
			resources.styleNodes
		}.css

		#expect(css.contains(".box-box {"))
	}

	@Test
	func `a page that does not show the document does not get its styles`() throws {
		_ = MarkdownDocument(parsing: "@Box {\nHello\n}", options: Self.options)

		let resources = PageResources()
		_ = try resources.collect {
			div {}.render()
		}

		#expect(resources.styleNodes.isEmpty)
	}
}

private enum BoxStyles: String, StyleSet {
	case box

	var style: Style {
		Style().padding(.rootEm(1))
	}
}

extension MarkdownContentTests {
	@Test
	func `source lines validate positivity and keep offsets explicit`() throws {
		#expect(SiteKit.SourceLocation.Line(rawValue: 0) == nil)
		#expect(SiteKit.SourceLocation.Line(rawValue: -1) == nil)
		let first = try #require(SiteKit.SourceLocation.Line(rawValue: 1))
		#expect(first.offset(by: 4) == 5)
		#expect(first.offset(by: 4).offset(by: -4) == first)
		#expect([SiteKit.SourceLocation.Line(9), first, 3].sorted() == [1, 3, 9])
		#expect(SourceLocation.file(URL(filePath: "/site/article.md"), line: first).description(relativeTo: URL(filePath: "/site")) == "article.md:1")
	}

	@Test
	func `code owned source lines reject nonpositive numbers`() async {
		await #expect(processExitsWith: .failure) {
			_ = SiteKit.SourceLocation.Line(0)
		}
	}

	@Test
	func `first body lines stay one based with and without frontmatter`() throws {
		let url = URL(filePath: "/content/article.md")
		let plain = try MarkdownFile(contents: "## First\n[Link](/page)", url: url)
		let fenced = try MarkdownFile(contents: "---\ntitle: 'Article'\n---\n\n## First\n[Link](/page)", url: url)
		#expect(plain.bodyStartLine == 1)
		#expect(fenced.bodyStartLine == 5)
		#expect(try plain.parsedMarkdown(options: .init()).rendered().headings.first?.line == 1)
		#expect(try fenced.parsedMarkdown(options: .init()).rendered().headings.first?.line == 5)
		#expect(try fenced.parsedMarkdown(options: .init()).rendered().links.first?.line == 6)
	}

	@Test
	func `parsed link rewriting leaves code examples alone`() throws {
		let source = "[Page](folder/page(1).md) and ![Image](picture.png).\n\n`[Example](example.md)`\n\n```markdown\n[Code](code.md)\n```\n"
		var rewriter = PlainMarkdownRewriter(linkDestination: { "https://example.com/" + $0 }, blockDirective: { Array($0.blockChildren) })
		let rewritten = rewriter.visit(Document(parsing: source))
		let result = try #require(rewritten)
		let markdown = result.format()
		#expect(markdown.contains("https://example.com/folder/page(1).md"))
		#expect(markdown.contains("https://example.com/picture.png"))
		#expect(markdown.contains("`[Example](example.md)`"))
		#expect(markdown.contains("[Code](code.md)"))
		#expect(!markdown.contains("https://example.com/code.md"))
	}

	@Test
	func `an already parsed file keeps its own diagnostic lines`() throws {
		let source = "---\ntitle: 'Questions'\n---\n\n## Heading\n\n[Page](/missing)\n"
		let url = URL(filePath: "/content/questions.md")
		let file = try MarkdownFile(contents: source, url: url)
		let parsed = file.parsedMarkdown(options: .init())
		let document = try parsed.rendered()
		#expect(parsed.document.descendants(of: Markdown.Heading.self).count == 1)
		#expect(document.headings.first?.line == 5)
		#expect(document.links.first?.line == 7)
		#expect(document.links.first?.otherFile == nil)
	}

	@Test
	func `a parsed file reports source checks at the original file and line`() throws {
		let url = URL(filePath: "/content/questions.md")
		let file = try MarkdownFile(contents: "---\ntitle: 'Questions'\n---\n\nText.\n\n```swift\nlet value = 1\n", url: url)
		let parsed = file.parsedMarkdown(options: .init())
		let errors = try #require(throws: ContentErrors.self) {
			try parsed.rendered()
		}

		#expect(errors.errors.map(\.file) == [url])
		#expect(errors.errors.map(\.line) == [7])
		#expect(errors.errors.first?.reason.contains("no closing ```") == true)
	}

	@Test
	func `parsed Markdown retains the parsing and rendering options and source punctuation`() throws {
		let sharedFile = URL(filePath: "/content/shared.md")
		let options = MarkdownDocument.Options(
			rewrite: { document in
				let shared = Document(parsing: "See [shared](/shared).", source: sharedFile)
				return Document(Array(document.blockChildren) + Array(shared.blockChildren))
			},
			blockDirectives: [
				"Box": .init { html in
					"<section>\(html)</section>"
				},
			],
			resolveLink: {
				"/resolved" + $0
			}
		)
		let parsed = ParsedMarkdown(parsing: "A \"quoted\" introduction...\n\n@Box {\nSee [page](/page).\n}", options: options)
		let document = try parsed.rendered()

		#expect(parsed.document.blockDirectives.count == 1)
		#expect(document.introduction == "A \"quoted\" introduction...")
		#expect(document.html.contains("<section><p>See <a href=\"/resolved/page\">page</a>.</p>"))
		#expect(document.links.map(\.destination) == ["/resolved/page", "/resolved/shared"])
		#expect(document.links.last?.otherFile == sharedFile)
		#expect(document.links.last?.line == 1)
	}

	@Test
	func `constructed Markdown has no claimed source and preserves literal punctuation`() throws {
		let parsed = ParsedMarkdown(blocks: [Paragraph(Markdown.Text("A “quoted” introduction...")), Markdown.Heading(level: 2, Markdown.Text("Section"))])
		let document = try parsed.rendered()

		#expect(document.introduction == "A “quoted” introduction...")
		#expect(document.headings.map(\.line) == [nil])
	}

	@Test
	func `inline notes inserted from another source retain unknown diagnostic lines`() throws {
		let otherFile = URL(filePath: "/content/other.md")
		let options = MarkdownDocument.Options(rewrite: { _ in
			Document(Array(Document(parsing: #"^[Term](note: "See [page](/page).\n\n![](image.png)")."#, source: otherFile).blockChildren))
		})
		let document = MarkdownDocument(parsing: "Original.", options: options)

		#expect(document.html.contains("user-content-note-0-1"))
		#expect(document.html.contains(#"<a href="/page">page</a>"#))
		#expect(document.links.map(\.destination) == ["/page", "image.png"])
		#expect(document.links.map(\.line) == [nil, nil])
		#expect(document.problems.map(\.line) == [nil])
		#expect(document.problems.first?.reason.contains("has no description") == true)
	}
}
