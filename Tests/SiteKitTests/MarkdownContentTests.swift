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

private enum BoxStyles: StyleSet {
	case box

	var style: Style {
		Style().padding(.rootEm(1))
	}
}

extension MarkdownContentTests {
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
	func `an already parsed document keeps its own diagnostic lines`() {
		let source = "## Heading\n\n[Page](/missing)\n"
		let url = URL(filePath: "/content/questions.md")
		let parsed = Document(parsing: source, source: url)
		let document = MarkdownDocument(rendering: parsed, source: source, firstLine: 8)
		#expect(document.headings.first?.line == 8)
		#expect(document.links.first?.line == 10)
		#expect(document.links.first?.otherFile == nil)
	}
}
