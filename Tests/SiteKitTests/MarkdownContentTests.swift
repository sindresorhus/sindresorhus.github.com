import Elementary
import Testing
import SiteKit

struct MarkdownContentTests {
	/**
	A `@Box` directive with the style of a box.
	*/
	private static let options = MarkdownDocument.Options(blockDirectives: [
		"Box": .init { html in
			div {
				HTMLRaw(html)
			}
			.style(BoxStyles.box)
			.render()
		},
	])

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
