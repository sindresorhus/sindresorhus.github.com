import Elementary
import Foundation
import Testing
@testable import SiteKit

struct TypedStyleBoundaryTests {
	@Test
	func `combining physical edges preserves the meaning of each edge`() {
		let combined = Style().padding([.top, .bottom], .pixels(8)).writingMode(.verticalRightToLeft)
		let individual = Style().padding(.top, .pixels(8)).padding(.bottom, .pixels(8)).writingMode(.verticalRightToLeft)
		#expect(combined.declarations == individual.declarations)
	}

	@Test
	func `physical axes and logical axes remain explicit in box properties`() {
		#expect(Style().padding(.vertical, .pixels(8)).declarations.map(\.property.description) == ["padding-top", "padding-bottom"])
		#expect(Style().margin(.horizontal, .auto).declarations.map(\.property.description) == ["margin-right", "margin-left"])
		#expect(Style().padding(.block, .pixels(8)).declarations.map(\.property.description) == ["padding-block"])
		#expect(Style().margin(.inline, .auto).declarations.map(\.property.description) == ["margin-inline"])
		#expect(Style().border([.blockStart, .trailing], .black).declarations.map(\.property.description) == ["border-inline-end", "border-block-start"])
		#expect(Style().padding([.top, .trailing], .pixels(8)).declarations.map(\.property.description) == ["padding-top", "padding-inline-end"])
		#expect(Style().padding(.all, .pixels(8)).declarations.map(\.property.description) == ["padding"])
		#expect(Style().padding([.block, .inline], .pixels(8)).declarations.map(\.property.description) == ["padding-inline", "padding-block"])
	}

	@Test
	func `fonts distinguish named families generic families and explicit CSS stacks`() {
		#expect(FontFamily.named("A,B").description == #""A,B""#)
		#expect(FontFamily(raw: "A,B").description == "A,B")
		#expect(FontFamily.stack(.uiRounded, .named("A,B"), .systemUI, .genericSansSerif).description == #"ui-rounded, "A,B", system-ui, sans-serif"#)
		#expect([FontFamily.uiSansSerif, .uiSerif, .uiMonospace].map(\.description) == ["ui-sans-serif", "ui-serif", "ui-monospace"])
	}

	@Test
	func `generated content keywords remain different from literal text`() {
		let keywords: [ContentKeyword] = [.none, .normal, .openQuote, .closeQuote, .noOpenQuote, .noCloseQuote]
		#expect(keywords.map { Style().content($0).declarations.last?.value.description } == ["none", "normal", "open-quote", "close-quote", "no-open-quote", "no-close-quote"])
		#expect(Style().content("open-quote").declarations.last?.value.description == #""open-quote""#)
		#expect(Style().content("a\"b", alternativeText: "").declarations.last?.value.description == #""a\"b" / """#)
	}

	@Test
	func `animation delays retain time units and typed numeric expressions`() {
		#expect(Style().animationDelay(.zero).declarations.last?.value.description == "0s")
		#expect(Style().animationDelay(.milliseconds(-125)).declarations.last?.value.description == "-.125s")
		#expect(Style().animationDelay(.milliseconds(100), multipliedBy: .siblingIndex - 2).declarations.last?.value.description == "calc(calc(sibling-index() - 2) * .1s)")
		#expect(Style().animationDelay(.seconds(1), multipliedBy: StyleVariable<CSSNumber>("delay-index").value).declarations.last?.value.description == "calc(var(--delay-index) * 1s)")
		#expect((CSSNumber.siblingCount - .siblingIndex).description == "calc(sibling-count() - sibling-index())")

		let css = Stylesheet {
			Rule(".reveal", Style().animation(Animations.fade, .linear(duration: .seconds(1))).media(.allowsMotion) {
				$0.animationDelay(.milliseconds(100), multipliedBy: .siblingIndex - 2)
			})
		}.css
		#expect(css.contains("animation: typed-style-boundary-tests-fade 1s linear;\n\t\tanimation-delay: calc(calc(sibling-index() - 2) * .1s);"))
	}

	@Test
	func `a transition alone registers its custom property with complete metadata`() {
		let progress = RegisteredProperty<Percentage>("transition-only-progress", initialValue: .percent(25), inherits: false)
		let css = Stylesheet {
			Rule(".transition", Style().transition(TransitionProperty(progress), timing: .linear(duration: .seconds(1))))
		}.css

		#expect(css.contains("transition: --transition-only-progress 1s linear;"))
		#expect(css.ranges(of: "@property --transition-only-progress {").count == 1)
		#expect(css.contains("syntax: \"<percentage>\";\n\tinherits: false;\n\tinitial-value: 25%;"))
	}

	@Test
	func `registered transition definitions retain their metadata and deduplicate with settings`() {
		let progress = RegisteredProperty<Percentage>("transition-progress", initialValue: .percent(25), inherits: false)
		let css = Stylesheet {
			Rule(".transition", Style().transition(TransitionProperty(progress), timing: .linear(duration: .seconds(1))))
			Rule(".setting", Style().setting(progress, to: .percent(80)))
		}.css
		#expect(css.contains("transition: --transition-progress 1s linear;"))
		#expect(css.ranges(of: "@property --transition-progress {").count == 1)
		#expect(css.contains("syntax: \"<percentage>\";\n\tinherits: false;\n\tinitial-value: 25%;"))
	}

	@Test
	func `will change serializes property lists and resets an empty list`() {
		#expect(Style().willChange(.transform, .opacity).declarations.last?.value.description == "transform, opacity")
		#expect(Style().willChange().declarations.last?.value.description == "auto")
	}

	@Test
	func `rule names accept Unicode and apply context specific restrictions`() throws {
		for name in ["base", "_private", "-vendor", "--progress", "日本語", "café", "none", "base.components"] {
			#expect(try CascadeLayer(validating: name).name == name)
		}
		for name in ["fade", "_private", "-vendor", "--progress", "日本語", "café"] {
			let frames = try Keyframes(validating: name, .to(Style().opacity(1)))
			#expect(Stylesheet { frames }.css.contains("@keyframes \(name) {"))
		}
		let frames = try Keyframes(validating: "fade", [.to(Style().opacity(1))])
		#expect(Stylesheet { frames }.css.contains("@keyframes fade {"))
	}

	@Test(arguments: ["default", "DEFAULT", "framework.default"])
	func `layer names permit default without treating it as a CSS wide keyword`(name: String) throws {
		let layer = try CascadeLayer(validating: name)
		let css = Stylesheet {
			Layer(layer) {
				Rule(".x", Style().opacity(1))
			}
		}.css
		#expect(css.contains("@layer \(name) {"))
	}

	@Test
	func `dynamic CSS rule names reject malformed and reserved identifiers`() {
		for name in ["", "bad name", "1name", "-1name", "-", "a;b", "a\\62", "inherit", "INITIAL", "revert-rule"] {
			#expect(throws: ContentError.self) {
				try CascadeLayer(validating: name)
			}
			#expect(throws: ContentError.self) {
				try Keyframes(validating: name, [])
			}
		}
		for name in [".base", "base.", "base..child", "base.inherit"] {
			#expect(throws: ContentError.self) {
				try CascadeLayer(validating: name)
			}
		}
		for name in ["none", "NONE", "default", "DEFAULT", "base.child"] {
			#expect(throws: ContentError.self) {
				try Keyframes(validating: name, [])
			}
		}
	}

	@Test
	func `code owned CSS rule names fail immediately for malformed names`() async {
		await #expect(processExitsWith: .failure) {
			_ = CascadeLayer("bad layer")
		}
		await #expect(processExitsWith: .failure) {
			_ = Keyframes("none", [])
		}
	}

	enum Animations: String, KeyframeSet {
		case fade

		var keyframes: [Keyframe] {
			[.to(Style().opacity(1))]
		}
	}

	@Test
	func `raw grid tracks are explicit and retain their CSS`() {
		let grid = Style().grid(rawColumns: "subgrid [start] [end]")
		#expect(grid.declarations.map(\.property) == [.display, .gridTemplateColumns])
		#expect(grid.declarations.map(\.value.description) == ["grid", "subgrid [start] [end]"])

		let columns = Style().gridColumns(raw: "[start] 1fr [end]")
		#expect(columns.declarations.map(\.property) == [.gridTemplateColumns])
		#expect(columns.declarations.map(\.value.description) == ["[start] 1fr [end]"])
	}

	@Test
	func `maximum sizes retain intrinsic and measurable values without automatic sizing`() {
		let style = Style()
			.frame(width: .auto, maxWidth: .unlimited, maxHeight: .maximumContent)
			.frame(maxWidth: .length(.percent(100) - .rootEm(2)))
		#expect(style.declarations.map(\.property) == [.width, .maxWidth, .maxHeight, .maxWidth])
		#expect(style.declarations.map(\.value.description) == ["auto", "none", "max-content", "calc(100% - 2rem)"])
		#expect(MaximumBoxSize.fitContent.description == "fit-content")
		#expect(MaximumBoxSize.minimumContent.description == "min-content")
	}

	@Test
	func `named stacks reset the direction of a previously composed stack`() {
		let horizontal = Style().vstack().hstack()
		let vertical = Style().hstack().vstack()
		#expect(horizontal.declarations.filter { $0.property == .flexDirection }.map(\.value.description) == ["column", "row"])
		#expect(vertical.declarations.filter { $0.property == .flexDirection }.map(\.value.description) == ["row", "column"])
		#expect(Style().hstack(isInline: true).declarations.first?.value.description == "inline-flex")
	}

	@Test
	func `keyframes reject nested selectors and media conditions`() async {
		await #expect(processExitsWith: .failure) {
			_ = Keyframe.to(Style().hover { $0.opacity(0) })
		}
		await #expect(processExitsWith: .failure) {
			_ = Keyframe.from(Style().dark { $0.opacity(0) })
		}
	}

	@Test
	func `image sources preserve asset queries and reject fragment only destinations`() throws {
		#expect(try ImageSource(validating: "/image.svg?theme=dark#view").description == "/image.svg?theme=dark#view")
		#expect(try ImageSource(validating: "https://example.com/image.png").description == "https://example.com/image.png")
		#expect(ImageSource.path(#path("/image.png")).description == "/image.png")
		#expect(img(.src(.path(#path("/image.svg"), fragment: "view"))).render() == #"<img src="/image.svg#view">"#)
		#expect(ImageSource.path(#path("/image.svg"), query: [URLQueryItem(name: "theme", value: "dark")], fragment: "view").description == "/image.svg?theme=dark#view")
		#expect(throws: ContentError.self) {
			try ImageSource(validating: "#page-section")
		}
		#expect(throws: ContentError.self) {
			try ImageSource(validating: "image.png")
		}
		#expect(throws: (any Error).self) {
			try JSONDecoder().decode(ImageSource.self, from: Data("\"#page-section\"".utf8))
		}
	}

	@Test
	func `accessibility hiding can be reset by a later modifier on the same element`() {
		#expect(div().accessibilityHidden().accessibilityHidden(false).render() == #"<div aria-hidden="false"></div>"#)
		#expect(div().accessibilityHidden(false).accessibilityHidden().render() == #"<div aria-hidden="true"></div>"#)
		#expect(div().accessibilityHidden(false).render() == #"<div aria-hidden="false"></div>"#)
	}
}
