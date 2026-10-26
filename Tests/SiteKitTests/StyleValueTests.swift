import Elementary
import Foundation
import Synchronization
import Testing
@testable import SiteKit

struct StyleValueTests {
	/**
	A quote or a line break in a CSS string ends the string, so the browser drops the declaration. A line break is written as the escape `\A`.
	*/
	@Test
	func `CSS strings escape controls and combining quotes without ending the value`() {
		let text = "\"\u{301}\\\u{c}\t\n\0a"
		#expect(CSSValue.string(text).description == "\"\\\"\u{301}\\\\\\c \\9 \\A \u{FFFD}a\"")
		#expect(CSSValue.url(RoutePath("/a\"b\\c.png")).description == #"url("/a\"b\\c.png")"#)
		#expect(Style().content("a\r\nb", alternativeText: "").declarations.last?.value.description == #""a\A b" / """#)
		#expect(CSSValue.string("a\r\nb\rc").description == #""a\A b\A c""#)
	}

	@Test
	func `numbers are rounded to 4 decimals, so arithmetic adds no noise`() {
		#expect((Length.rootEm(0.1) + .rootEm(0.2)).description == ".3rem")
		#expect(Length.viewportWidth(106.24999999999999).description == "106.25vw")
		#expect(CSSValue(2.0 / 3).description == ".6667")
		#expect(CSSValue(-2.0 / 3).description == "-.6667")
		#expect(CSSValue(1.99999).description == "2")
		#expect(CSSValue(-0.0).description == "0")
		#expect(CSSValue(-0.00001).description == "0")
		#expect(CSSValue(1e19).description == "1e+19")
		#expect(CSSValue(12_345_678.5).description == "12345678.5")
		#expect(CSSValue(700).description == "700")
		#expect(CSSValue(-3).description == "-3")
		#expect(CSSValue(-3.0).description == "-3")
		#expect(CSSValue(-0.25).description == "-.25")
		#expect(Color.white.opacity(0.123456).description == "rgb(255 255 255 / 12.3456%)")
	}

	@Test
	func `CSS definitions with the same name occupy separate namespaces`() {
		let property = RegisteredProperty<Length>("--progress", syntax: .length, initialValue: 0)
		let css = Stylesheet {
			Keyframes("--progress") {
				Rule("to", Style().opacity(1))
			}
			Rule(".a", Style().setting(property, to: .pixels(2)))
			Rule(".b", Style().setting(property, to: .pixels(3)))
		}.css
		#expect(css.ranges(of: "@keyframes --progress").count == 1)
		#expect(css.ranges(of: "@property --progress").count == 1)
	}

	@Test
	func `each cached style case is constructed once`() {
		_ = CountedStyles.first.nodes
		_ = CountedStyles.second.nodes
		_ = CountedStyles.nodes
		#expect(CountedStyles.computations.withLock(\.self) == 2)
	}

	@Test
	func `a stylesheet has the rules of the cases of a style set, and then the keyframes that they share, once`() {
		#expect(Stylesheet { FadingStyles.self }.nodes.map(\.definition) == [nil, nil, nil, .keyframes("fade-fade")])
	}

	@Test
	func `an animation constructs its frames once`() {
		_ = Style().animation(CountedAnimations.fade, .linear(duration: .seconds(1)))
		#expect(CountedAnimations.computations.withLock(\.self) == 1)
	}

	@Test
	func `resource replay retains distinct shared cases and deduplicates repeat inclusions`() throws {
		let document = PageResources(sharedStylesheet: Stylesheet { ReplayStyles.self })
		try document.collect {
			for _ in 0..<100 {
				document.use(ReplayStyles.first)
				document.use(ReplayStyles.second)
				document.require(script: "/script.js")
			}
		}
		#expect(document.styleNodes.isEmpty)

		let page = PageResources()
		try page.collect {
			page.include(document)
			page.include(document)
			page.include(page)
		}
		let css = Stylesheet { page.styleNodes }.css
		#expect(css.ranges(of: ".replay-first {").count == 1)
		#expect(css.ranges(of: ".replay-second {").count == 1)
		#expect(page.scripts == ["/script.js"])
	}

	@Test
	func `typed style values and keywords share the declaration boundary`() {
		let style = Style()
			.declaration(.width, Length.rootEm(2))
			.declaration(.color, Color.white)
			.declaration(.display, Display.grid)
			.declaration(.rotate, Angle.degrees(45))
			.declaration(.gridAutoColumns, GridTrack.fraction(1))
			.declaration(.fontFamily, FontFamily("system-ui"))
		#expect(style.declarations.map(\.value.description) == ["2rem", "#fff", "grid", "45deg", "1fr", "system-ui"])
		#expect(div(.ariaCurrent(.step)) { "Step" }.render().contains(#"aria-current="step""#))
	}
}

private enum FadingStyles: StyleSet {
	case slow
	case fast

	var style: Style {
		switch self {
		case .slow:
			Style().animation(FadeAnimations.fade, .default(duration: .seconds(2)))
		case .fast:
			Style().animation(FadeAnimations.fade, .default(duration: .seconds(1)))
		}
	}
}

private enum CountedStyles: StyleSet {
	case first
	case second

	static let computations = Mutex(0)

	var style: Style {
		Self.computations.withLock { $0 += 1 }
		return Style().opacity(0.5)
	}
}

private enum CountedAnimations: KeyframeSet {
	case fade

	static let computations = Mutex(0)

	var keyframes: [Keyframe] {
		Self.computations.withLock { $0 += 1 }
		return [.to(Style().opacity(0))]
	}
}

private enum ReplayStyles: StyleSet {
	case first
	case second

	var style: Style {
		Style().opacity(0.5)
	}
}
