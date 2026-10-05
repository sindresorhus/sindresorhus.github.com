import Elementary
import Testing
import SiteKit

@Suite
struct MarkdownContentTests {
	@Test
	func `a page that shows a document gets the styles of its block directives`() throws {
		let options = MarkdownDocument.Options(blockDirectives: [
			"Box": .init { html in
				div {
					HTMLRaw(html)
				}
				.style(BoxStyles.box)
				.render()
			},
		])

		// The document renders before the page, like the content of the site.
		let document = MarkdownDocument(parsing: "@Box {\nHello\n}", options: options)

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
		let options = MarkdownDocument.Options(blockDirectives: [
			"Box": .init { html in
				div {
					HTMLRaw(html)
				}
				.style(BoxStyles.box)
				.render()
			},
		])

		_ = MarkdownDocument(parsing: "@Box {\nHello\n}", options: options)

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
