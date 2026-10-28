import Elementary
import Foundation
import Testing
@testable import SiteKit
@testable import Website

struct ComponentReuseTests {
	@Test
	func `form fields own their base control style while preserving custom control styling`() throws {
		let resources = PageResources()
		let html = try resources.collect {
			FormField(label: "Message", controlID: ElementID("message"), hint: "A hint") {
				textarea(.name("message")) {}
					.style { $0.frame(minHeight: .rootEm(8)) }
			}
			.render()
		}
		let css = Stylesheet {
			resources.styleNodes
			resources.elementStyleNodes
		}.css
		#expect(html.contains("form-field-control"))
		#expect(html.contains(#"id="message" aria-describedby="message-hint""#))
		#expect(css.contains(".form-field-control {"))
		#expect(css.contains("min-height: 8rem;"))
	}

	@Test
	func `grouped menu links retain encoded destinations and escaped labels`() {
		let link = LabeledLink("Read & Go", destination: .path(.apps, query: [URLQueryItem(name: "source", value: "a&b")], fragment: "faq"))
		let html = OverflowMenu(label: "Pages", groups: [LinkGroup(title: "More", links: [link])], variant: .chip).render()
		#expect(html.contains(#"<optgroup label="More"><option value="/apps?source=a%26b#faq">Read &amp; Go</option></optgroup>"#))
		#expect(!html.contains("data-menu-popover"))
	}

	@Test
	func `plain facts and rich content remain separate escaped items`() {
		let html = FactLine(facts: ["A & B", "<C>"]) {
			a(.href(RoutePath.apps)) {
				"More"
			}
		}
		.render()
		#expect(html == #"<span class="fact-line"><span>A &amp; B</span><span>&lt;C&gt;</span><a href="/apps">More</a></span>"#)
		#expect(FactLine(facts: ["Only"]) {}.render() == #"<span class="fact-line"><span>Only</span></span>"#)
	}

	@Test
	func `semantic color composition preserves ordinary contrast and page metadata colors`() {
		let css = Stylesheet { Rule(":root", SemanticColor.customProperties) }.css
		#expect(css.contains("--primary-text: light-dark(var(--gray-900), #fff);"))
		#expect(css.contains("--secondary-text: light-dark(var(--gray-500), var(--gray-400));"))
		#expect(css.contains("--secondary-text: light-dark(var(--gray-700), var(--gray-300));"))
		#expect(css.contains("--page-background: light-dark(#fff, oklch(14% .012 264));"))
		#expect(SemanticColor.pageBackgroundColors.light.resolved.description == "#fff")
		#expect(SemanticColor.pageBackgroundColors.dark.resolved.description == "oklch(14% .012 264)")
	}

	@Test
	func `typography metadata preserves semantic roles inherited traits and explicit overrides`() {
		let headline = Style().textStyle(.headline)
		#expect(headline.declarations.map(\.value.description) == ["1.1875rem", "1.3", "600", "-.01em"])
		#expect(Style().textStyle(.body).declarations.map(\.property) == [.fontSize, .lineHeight])
		#expect(Style().textStyle(.caption, weight: .bold).declarations.map(\.value.description) == [".875rem", "1.5", "700"])
		#expect(Style().font(.extraLarge3).declarations.map(\.value.description) == ["1.875rem", "1.2"])
		#expect(Style().font(.extraLarge9).declarations.map(\.value.description) == ["8rem", "1"])
	}

	@Test
	func `hover fills retain the same background and optional text color for pointer and keyboard`() {
		let plain = Stylesheet { Rule(".plain", Style().hoverFill(.white)) }.css
		let colored = Stylesheet { Rule(".colored", Style().hoverFill(.white, color: .black)) }.css
		#expect(plain.contains("transition: background-color .15s;"))
		#expect(!plain.contains("color: #000;"))
		#expect(colored.contains("transition: background-color .15s, color .15s;"))
		#expect(colored.ranges(of: "background-color: #fff;").count == 2)
		#expect(colored.ranges(of: "color: #000;").count == 2)
		#expect(colored.contains("&:focus-visible"))
		#expect(colored.contains("&:hover"))
	}
}
