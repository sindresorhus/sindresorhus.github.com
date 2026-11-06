import Elementary
import Synchronization
import Testing
import SiteKit

struct ElementStyleTests {
	@Test
	func `requesting inline scripts does not generate unrelated CSS rules`() throws {
		let resources = PageResources()
		_ = try resources.collect {
			div {}
				.style(ScriptQueryStyles.root)
				.render()
		}

		#expect(ScriptQueryStyles.evaluations.withLock { $0 } == 0)
		#expect(resources.inlineScriptElements.isEmpty)
		#expect(ScriptQueryStyles.evaluations.withLock { $0 } == 0)
		#expect(!resources.styleNodes.isEmpty)
		#expect(ScriptQueryStyles.evaluations.withLock { $0 } == 1)
	}

	@Test
	func `rendered fragments replay frozen styles and scripts into another collector once`() throws {
		let sharedStylesheet = Stylesheet {
			StableIdentityStyles.self
		}
		let fragment = try RenderedHTML(sharedStylesheet: sharedStylesheet) {
			div {
				span {
					"Fragment"
				}.style(StableIdentityStyles.detail)
				ModuleScript(#path("/fragment.js"))
			}
			.style {
				$0.opacity(0.5)
			}
		}

		#expect(fragment.resources.styleNodes.isEmpty)
		let resources = PageResources()
		let html = try resources.collect {
			div {
				fragment
				fragment
			}.render()
		}

		#expect(html.ranges(of: "Fragment").count == 2)
		#expect(resources.scripts == [#path("/fragment.js")])
		let styles = Stylesheet {
			resources.styleNodes
		}.css
		let elementStyles = Stylesheet {
			resources.elementStyleNodes
		}.css
		#expect(styles.contains(".stable-identity-detail"))
		#expect(elementStyles.ranges(of: "opacity: .5;").count == 1)
	}

	@Test
	func `a resource snapshot does not change when its collector is reused`() throws {
		let resources = PageResources()
		_ = try resources.collect {
			ModuleScript(#path("/first.js")).render()
		}
		let snapshot = resources.snapshot
		_ = try resources.collect {
			ModuleScript(#path("/second.js")).render()
		}
		#expect(snapshot.scripts == [#path("/first.js")])
		#expect(resources.scripts == [#path("/first.js"), #path("/second.js")])
	}

	@Test
	func `style class identity comes from raw values instead of display descriptions`() {
		#expect(StableIdentityStyles.root.className == "stable-identity")
		#expect(StableIdentityStyles.detail.className == "stable-identity-detail")
	}

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
		try #require(classNames.count == 3)
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

private enum StableIdentityStyles: String, StyleSet, CustomStringConvertible {
	case root
	case detail

	var description: String {
		"display-only"
	}

	var style: Style {
		Style().opacity(1)
	}
}

/**
A style whose evaluation is observable, so a script-only query can be checked without timing assumptions.
*/
private enum ScriptQueryStyles: String, StyleSet {
	case root

	static let evaluations = Mutex(0)

	var style: Style {
		Self.evaluations.withLock {
			$0 += 1
		}
		return Style().opacity(1)
	}
}
