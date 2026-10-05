import Elementary
import Testing
import SiteKit

@Suite
struct ElementStyleTests {
	@Test
	func `a style on an element gets a class from the file and the rules, and the page gets the rule once`() throws {
		let resources = PageResources()
		let html = try resources.collect {
			div {
				p {
					"A"
				}
				.style {
					$0.opacity(0.5)
				}

				p {
					"B"
				}
				.style {
					$0.opacity(0.5)
				}

				p {
					"C"
				}
				.style {
					$0.opacity(0.25)
				}
			}
			.render()
		}

		let classNames = html.matches(of: /class="([\w-]+)"/).map { String($0.1) }
		#expect(classNames.count == 3)
		#expect(classNames[0] == classNames[1])
		#expect(classNames[0] != classNames[2])
		#expect(classNames.allSatisfy { $0.hasPrefix("element-style-tests-") })

		let css = Stylesheet {
			resources.elementStyleNodes
		}.css

		#expect(css == ".\(classNames[0]) {\n\topacity: .5;\n}\n.\(classNames[2]) {\n\topacity: .25;\n}\n")
		#expect(resources.styleNodes.isEmpty)
	}

	@Test
	func `a stack on an element is a style on the element`() throws {
		let resources = PageResources()
		_ = try resources.collect {
			div {}
				.vstack(spacing: .rootEm(1))
				.render()
		}

		let css = Stylesheet {
			resources.elementStyleNodes
		}.css

		#expect(css.contains("flex-direction: column;"))
		#expect(css.contains("gap: 1rem;"))
	}
}
