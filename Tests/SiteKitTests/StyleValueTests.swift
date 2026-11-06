import Elementary
import Foundation
import Synchronization
import Testing
@testable import SiteKit

struct StyleValueTests {
	@Test
	func `counter and animation names use raw identity rather than display descriptions`() {
		#expect(DescribedCounters.step.description == "Display counter")
		#expect(DescribedCounters.step.name == "described-stable-step")
		#expect(DescribedAnimations.fade.description == "Display animation")
		#expect(DescribedAnimations.fade.name == "described-stable-fade")
		let css = Stylesheet {
			Rule(".identity", Style().counterIncrement(DescribedCounters.step).animation(DescribedAnimations.fade, .linear(duration: .seconds(1)), isEssential: true))
		}.css
		#expect(css.contains("counter-increment: described-stable-step;"))
		#expect(css.contains("animation: described-stable-fade 1s linear;"))
		#expect(css.contains("@keyframes described-stable-fade"))
	}

	@Test
	func `aspect ratios retain dimensions automatic fallback and typed number expressions`() {
		let width = StyleVariable<CSSNumber>("ratio-width").value
		let style = Style()
			.aspectRatio(.ratio(width: 16, height: 9))
			.aspectRatio(.auto)
			.aspectRatio(.automatic(width: 4, height: 3))
			.aspectRatio(.ratio(width: width, height: 2))
			.aspectRatio(.ratio(width: 0, height: 0))
			.aspectRatio(1)
			.aspectRatio(320.0 / 260.0)
		#expect(style.declarations.map(\.value.description) == ["16 / 9", "auto", "auto 4 / 3", "var(--ratio-width) / 2", "0 / 0", "1", "1.2308"])
	}

	@Test
	func `number division and negation compose without losing numeric expressions`() {
		let progress = StyleVariable<CSSNumber>("progress").value
		#expect((CSSNumber.siblingIndex / .siblingCount).description == "calc(sibling-index() / sibling-count())")
		#expect((-progress).description == "calc(var(--progress) * -1)")
		#expect((-(progress + 1) / (2 * progress)).description == "calc(calc(calc(var(--progress) + 1) * -1) / calc(2 * var(--progress)))")
		#expect(Style().opacity(progress / 2).declarations.last?.value.description == "calc(var(--progress) / 2)")
	}

	@Test
	func `easing functions are reused independently of animation duration`() {
		let curve = EasingFunction.cubicBezier(0.22, 1, 0.36, 1)
		let quick = AnimationTiming(duration: .milliseconds(150), curve: curve)
		let slow = AnimationTiming(duration: .seconds(2), curve: curve)
		#expect(quick.description == ".15s cubic-bezier(.22, 1, .36, 1)")
		#expect(slow.description == "2s cubic-bezier(.22, 1, .36, 1)")
		#expect(AnimationTiming(duration: .seconds(1), curve: .ease).description == "1s")
		#expect(AnimationTiming(duration: .seconds(1), curve: .steps(4, position: .jumpBoth)).description == "1s steps(4, jump-both)")
	}

	@Test
	func `easing functions reject invalid step counts and bezier coordinates`() async {
		await #expect(processExitsWith: .failure) {
			_ = EasingFunction.steps(0)
		}
		await #expect(processExitsWith: .failure) {
			_ = EasingFunction.steps(1, position: .jumpNone)
		}
		await #expect(processExitsWith: .failure) {
			_ = EasingFunction.cubicBezier(-0.1, 0, 1, 1)
		}
	}

	@Test
	func `image sizes express fit keywords and automatic dimensions`() {
		let style = Style()
			.backgroundSize(.cover)
			.backgroundSize(.contain)
			.backgroundSize(.dimensions(width: .auto, height: .percent(50)))
			.maskSize(.dimensions(width: .pixels(12), height: .auto))
			.maskSize(.cover)
		#expect(style.declarations.map(\.value.description) == ["cover", "contain", "auto 50%", "12px auto", "cover"])
		#expect(Style().backgroundSize(width: .pixels(8), height: .pixels(16)).declarations.last?.value.description == "8px 16px")
	}

	@Test
	func `line heights distinguish normal multipliers lengths and percentages`() {
		let style = Style()
			.lineHeight(.normal)
			.lineHeight(.multiple(1.5))
			.lineHeight(.length(.pixels(24)))
			.lineHeight(.length(.percent(150)))
			.font(size: .rootEm(1), lineHeight: .normal)
		#expect(style.declarations.map(\.value.description) == ["normal", "1.5", "24px", "150%", "1rem", "normal"])
		#expect(Style().lineHeight(1.5).declarations.last?.value.description == "1.5")
	}

	@Test
	func `color components retain their numeric percentage and angle domains`() {
		let hue = StyleVariable<Angle>("typed-hue").value
		let lightness = StyleVariable<Percentage>("typed-lightness").value
		let chroma = StyleVariable<CSSNumber>("typed-chroma").value
		#expect(Color.hsl(hue: .degrees(120), saturation: .percent(100), lightness: .percent(50)).description == "hsl(120deg 100% 50%)")
		#expect(Color.hsl(hue: hue, saturation: .percent(100), lightness: lightness).description == "hsl(var(--typed-hue) 100% var(--typed-lightness))")
		#expect(Color.hsl(hue: 120, saturation: .percent(100), lightness: .percent(50)).description == "hsl(120 100% 50%)")
		#expect(Color.oklch(lightness: .percent(62.3), chroma: 0.214, hue: .degrees(259.815)).description == "oklch(62.3% .214 259.815deg)")
		#expect(Color.oklch(lightness: lightness, chroma: chroma, hue: hue).description == "oklch(var(--typed-lightness) var(--typed-chroma) var(--typed-hue))")
		#expect(Color.rgb(red: 0, green: 128, blue: 255).description == "rgb(0 128 255)")
	}

	@Test
	func `registered initial constants infer syntax and keep unchecked syntax explicit`() {
		let length = RegisteredProperty<Length>("independent-length", initialValue: .pixels(8))
		let color = RegisteredProperty<Color>("independent-color", initialValue: .oklch(lightness: 62.3, chroma: 0.214, hue: 259.815))
		let number = RegisteredProperty<CSSNumber>("independent-number", initialValue: 0.5)
		let custom = RegisteredProperty<BoxSize>("custom-size", syntax: .init(raw: "<length> | auto"), uncheckedInitialValue: .auto)
		let css = Stylesheet {
			Rule(".constants", Style().setting(length, to: .rootEm(2)).setting(color, to: .white).setting(number, to: 1).setting(custom, to: .auto))
		}.css
		#expect(css.contains("syntax: \"<length>\";"))
		#expect(css.contains("initial-value: 8px;"))
		#expect(css.contains("initial-value: oklch(62.3% .214 259.815deg);"))
		#expect(css.contains("initial-value: .5;"))
		#expect(css.contains("syntax: \"<length> | auto\";"))
		#expect(length.value.description == "var(--independent-length)")
	}

	@Test
	func `feature conditions reuse typed modifiers and preserve boolean grouping`() {
		let display = BrowserFeature.declaration { $0.display(.grid) }
		let selector = BrowserFeature.selector(":has(> img)")
		#expect(display.description == "(display: grid)")
		#expect(BrowserFeature.interpolateSize.description == "(interpolate-size: allow-keywords)")
		#expect(selector.description == "selector(:has(> img))")
		#expect((display && (selector || !.webKitScrollbar)).description == "((display: grid)) and ((selector(:has(> img))) or (not (selector(::-webkit-scrollbar))))")
		#expect(BrowserFeature(raw: "font-tech(color-COLRv1)").description == "font-tech(color-COLRv1)")
	}

	@Test
	func `feature declaration checks reject style rules and multiple declarations`() async {
		await #expect(processExitsWith: .failure) {
			_ = BrowserFeature.declaration { $0.padding(.pixels(2)).opacity(1) }
		}
		await #expect(processExitsWith: .failure) {
			_ = BrowserFeature.declaration { $0.opacity(1).hover { $0.opacity(0) } }
		}
	}

	private enum Counters: String, CounterSet {
		case step
	}

	@Test
	func `track lists compose a leading column with repetitions and share row output`() {
		let tracks = GridTrackList(.fixed(.characterWidth(3)), repeating: .flexible(), count: 4)
		let style = Style().grid(columns: tracks).gridRows(7, size: .auto)
		#expect(style.declarations.map(\.value.description) == ["grid", "3ch repeat(4, minmax(0, 1fr))", "repeat(7, auto)"])
		#expect(GridTrackList.adaptive(minimum: .rootEm(9)).description == "repeat(auto-fill, minmax(min(100%, 9rem), 1fr))")
		#expect(Style().grid(minimumColumnWidth: .rootEm(9), maximumColumns: 3, spacing: .rootEm(0.5)).declarations.last?.value.description == ".5rem")
	}

	@Test
	func `track lists reject empty lists and zero repetitions`() async {
		await #expect(processExitsWith: .failure) {
			_ = GridTrackList([])
		}
		await #expect(processExitsWith: .failure) {
			_ = GridTrackList.repeating(.auto, count: 0)
		}
	}

	@Test
	func `numeric filter expressions preserve their dimensional type and ordering`() {
		let amount = StyleVariable<CSSNumber>("amount").value(default: 0.5)
		let filters: [Filter] = [.brightness(amount), .saturation(amount * 2), .grayscale(amount), .contrast(amount), .invert(amount), .sepia(amount), .opacity(amount)]
		let style = Style().filter(filters)
		#expect(style.declarations.last?.value.description == "brightness(var(--amount, .5)) saturate(calc(var(--amount, .5) * 2)) grayscale(var(--amount, .5)) contrast(var(--amount, .5)) invert(var(--amount, .5)) sepia(var(--amount, .5)) opacity(var(--amount, .5))")
	}

	@Test
	func `automatic lengths and box sizes preserve the same measurable expressions`() {
		let value = LengthPercentage.percent(100) - .rootEm(2)
		#expect(AutoLength(value).description == "calc(100% - 2rem)")
		#expect(BoxSize(value).description == "calc(100% - 2rem)")
		#expect(Style().margin(AutoLength(value)).frame(width: BoxSize(value)).declarations.map(\.value.description) == ["calc(100% - 2rem)", "calc(100% - 2rem)"])
	}

	@Test
	func `animation repetition changes do not accumulate stale direction tokens`() {
		let once = Animation.linear(duration: .seconds(2))
		let alternating = once.repeatForever()
		let forward = alternating.repeatForever(autoreverses: false)
		#expect(once.cssValue(name: "pulse", fillMode: .both).description == "pulse 2s linear both")
		#expect(alternating.cssValue(name: "pulse", fillMode: nil).description == "pulse 2s linear infinite alternate")
		#expect(forward.cssValue(name: "pulse", fillMode: .forwards).description == "pulse 2s linear infinite forwards")
	}

	@Test
	func `box edge modifiers retain separate property families and logical axes`() {
		let styles = [Style().padding(.inline, .pixels(2)), Style().margin(.block, .auto), Style().border(.leading, .black)]
		#expect(styles.flatMap(\.declarations).map(\.property.description) == ["padding-inline", "margin-block", "border-inline-start"])
		#expect(styles.flatMap(\.declarations).map(\.value.description) == ["2px", "auto", "1px solid #000"])
	}

	@Test
	func `inheritance applies only to whole properties alongside composable typed values`() {
		let style = Style().inherits(.color).inherits(.fontFamily).inherits(.letterSpacing).padding(.pixels(2) + .rootEm(1))
		#expect(style.declarations.map(\.property) == [.color, .fontFamily, .letterSpacing, .padding])
		#expect(style.declarations.map(\.value.description) == ["inherit", "inherit", "inherit", "calc(2px + 1rem)"])
	}

	@Test
	func `named fonts escape their names while generic fallback families stay unquoted`() {
		let font = FontFamily.stack(.named("A \"quoted\" font"), .named("Back\\slash"), .genericSansSerif)
		#expect(font.description == #""A \"quoted\" font", "Back\\slash", sans-serif"#)
		#expect(FontFamily.stack(.genericMonospace).description == "monospace")
	}

	@Test
	func `repeating gradients retain double positions and color spaces`() {
		let stripe = CSSImage.repeatingLinearGradient(.angle(.degrees(45)), Color.black.at(.zero, through: .pixels(12)), Color(raw: "#ffd700").at(.pixels(12), through: .pixels(24)))
		#expect(stripe.description == "repeating-linear-gradient(45deg, #000 0 12px, #ffd700 12px 24px)")
		#expect(CSSImage.repeatingLinearGradient(.toRight, Color.black.at(.percent(0)), Color.white.at(.percent(100)), in: .oklab).description == "repeating-linear-gradient(to right in oklab, #000 0%, #fff 100%)")
	}

	@Test
	func `individual two-axis scaling preserves negative reflection and CSS numeric expressions`() {
		let style = Style().scaleEffect(x: -1, y: 1).scaleEffect(x: CSSNumber(raw: "var(--width-scale)"), y: 0.5)
		#expect(style.declarations.map(\.value.description) == ["-1 1", "var(--width-scale) .5"])
	}

	@Test
	func `typed transform lists retain order reset emptiness and allow an explicit raw escape`() {
		let transforms: [Transform] = [.perspective(.pixels(700)), .translateY(.percent(50)), .rotateX(.degrees(22)), .translateY(.percent(-50))]
		#expect(Style().transform(transforms).declarations.last?.value.description == "perspective(700px) translateY(50%) rotateX(22deg) translateY(-50%)")
		#expect(Style().transform(.rotateY(.degrees(90)), .scale(1.5)).declarations.last?.value.description == "rotateY(90deg) scale(1.5)")
		#expect(Style().transform().declarations.last?.value == CSSValue.none)
		#expect(Style().transform([]).declarations.last?.value == CSSValue.none)
		#expect(Style().transform(raw: "matrix(1, 0, 0, 1, 4, 5)").declarations.last?.value.description == "matrix(1, 0, 0, 1, 4, 5)")
	}

	@Test
	func `scalar math composes custom properties without erasing length angle and percentage types`() {
		let strength = StyleVariable<CSSNumber>("strength").value(default: 0)
		#expect((strength * 0.8).description == "calc(var(--strength, 0) * .8)")
		#expect((1 + strength * 0.8).description == "calc(1 + calc(var(--strength, 0) * .8))")
		#expect(Length.pixels(55).scaled(by: strength).description == "calc(55px * var(--strength, 0))")
		#expect(LengthPercentage.pixels(-22).scaled(by: strength).description == "calc(-22px * var(--strength, 0))")
		#expect(Length.zero.scaled(by: strength).description == "calc(0px * var(--strength, 0))")
		#expect(LengthPercentage.zero.scaled(by: strength).description == "calc(0px * var(--strength, 0))")
		#expect((LengthPercentage.percent(100) - .pixels(2)).scaled(by: strength).description == "calc((100% - 2px) * var(--strength, 0))")
		#expect(Angle.degrees(1).scaled(by: strength).description == "calc(1deg * var(--strength, 0))")
		let saturation = StyleVariable<Percentage>("saturation")
		#expect(Color.hsl(hue: 200, saturation: saturation.value(default: .percent(100)), lightness: .percent(65)).description == "hsl(200 var(--saturation, 100%) 65%)")
	}

	@Test
	func `custom property references retain validated names and the list initializer owns empty effect resets`() {
		let identifier = DashedIdentifier("size")
		let variable = StyleVariable<Length>(identifier)
		#expect(variable.name == identifier)
		#expect(CSSValue.variable(identifier, fallback: .pixels(2)).description == "var(--size, 2px)")
		#expect(CSSValue([String](), separator: ", ", emptyValue: .none) == .none)
		#expect(CSSValue(["a", "b"], separator: ", ", emptyValue: .none).description == "a, b")
		#expect(Style().textShadow().declarations.last?.value == CSSValue.none)
	}

	@Test(arguments: ["site-header", "1", "3d-offset", "_value", "a--b"])
	func `dashed identifiers validate supported names including leading digits`(name: String) throws {
		#expect(try DashedIdentifier(validating: name).description == "--\(name)")
		#expect(DashedIdentifier(name).description == "--\(name)")
	}

	@Test(arguments: ["", "a b", "a\nb", "value;", "a{b", "a.b", "café", "\\61"])
	func `dashed identifiers reject unsupported dynamic spellings`(name: String) {
		#expect(throws: ContentError.self) {
			try DashedIdentifier(validating: name)
		}
	}

	@Test
	func `numeric font styles combine independently and an empty set restores normal`() {
		let style = Style()
			.fontVariantNumeric([.tabularNumbers, .oldstyleNumbers])
			.fontVariantNumeric([])
		#expect(style.declarations.map(\.value.description) == ["tabular-nums oldstyle-nums", "normal"])
		#expect(Style().monospacedDigit().declarations.last?.value.description == "tabular-nums")
		#expect(FontVariantNumeric.oldstyleNumbers.description == "oldstyle-nums")
	}

	@Test
	func `named keyframes retain their frames and the registered properties those frames use`() {
		let progress = RegisteredProperty<Percentage>("progress", initialValue: .percent(0))
		let frames: [Keyframe] = [
			.from(Style().setting(progress, to: .percent(0))),
			.at(50, Style().setting(progress, to: .percent(25))),
			.to(Style().setting(progress, to: .percent(100)))
		]
		let css = Stylesheet { Keyframes("progress", frames) }.css
		#expect(css.contains("@keyframes progress {\n\tfrom {\n\t\t--progress: 0%;\n\t}\n\t50% {\n\t\t--progress: 25%;\n\t}\n\tto {\n\t\t--progress: 100%;\n\t}\n}"))
		#expect(css.ranges(of: "@property --progress {").count == 1)
		#expect(Stylesheet { Keyframes("progress", frames[0], frames[1], frames[2]) }.css == css)
	}

	@Test
	func `box sizes and automatic margins preserve typed lengths and calculations`() {
		let calculation = LengthPercentage.percent(100) - .pixels(8)
		let style = Style()
			.frame(width: .auto, height: .fitContent, maxWidth: .length(calculation))
			.margin(top: .pixels(4), horizontal: .auto, bottom: .length(-calculation))
			.top(.auto)
			.padding(.pixels(2))
		#expect(style.declarations.map(\.value.description) == ["auto", "fit-content", "calc(100% - 8px)", "4px auto calc((100% - 8px) * -1)", "auto", "2px"])
		#expect(BoxSize.containerWidth(50).description == LengthPercentage.containerWidth(50).description)
		#expect(AutoLength.clamp(.pixels(1), .percent(2), .pixels(3)).description == LengthPercentage.clamp(.pixels(1), .percent(2), .pixels(3)).description)
	}

	/**
	A quote or a line break in a CSS string ends the string, so the browser drops the declaration. A line break is written as the escape `\A`.
	*/
	@Test
	func `CSS strings escape controls and combining quotes without ending the value`() {
		let text = "\"\u{301}\\\u{c}\t\n\0a"
		#expect(CSSValue.string(text).description == "\"\\\"\u{301}\\\\\\c \\9 \\A \u{FFFD}a\"")
		#expect(CSSValue.url(RoutePath("/a\"b\\c.png")).description == #"url("/a%22b%5Cc.png")"#)
		#expect(Style().content("a\r\nb", alternativeText: "").declarations.last?.value.description == #""a\A b" / """#)
		#expect(CSSValue.string("a\r\nb\rc").description == #""a\A b\A c""#)
	}

	@Test
	func `numbers are rounded to 4 decimals, so arithmetic adds no noise`() {
		#expect((LengthPercentage.rootEm(0.1) + .rootEm(0.2)).description == ".3rem")
		#expect(LengthPercentage.viewportWidth(106.24999999999999).description == "106.25vw")
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
		let property = RegisteredProperty<Length>("progress", initialValue: .zero)
		let css = Stylesheet {
			Keyframes("--progress", .to(Style().opacity(1)))
			Rule(".a", Style().setting(property, to: .pixels(2)))
			Rule(".b", Style().setting(property, to: .pixels(3)))
		}.css
		#expect(css.ranges(of: "@keyframes --progress").count == 1)
		#expect(css.ranges(of: "@property --progress").count == 1)
	}

	@Test
	func `registered property syntax matches its value type and preserves raw syntax`() {
		let colorSyntax: PropertySyntax<Color> = .color
		let angle = RegisteredProperty<Angle>("angle", initialValue: .degrees(0))
		let color = RegisteredProperty<Color>("color", syntax: colorSyntax, uncheckedInitialValue: .black)
		let length = RegisteredProperty<Length>("length", initialValue: .pixels(1))
		let percentage = RegisteredProperty<Percentage>("percentage", initialValue: .percent(0))
		let number = RegisteredProperty<CSSNumber>("number", initialValue: 0)
		let custom = RegisteredProperty<BoxSize>("custom", syntax: .init(raw: "<length> | auto"), uncheckedInitialValue: .auto, inherits: false)
		let css = Stylesheet {
			Rule(".a", Style()
				.setting(angle, to: .degrees(45))
				.setting(color, to: .white)
				.setting(length, to: .pixels(2))
				.setting(percentage, to: .percent(50))
				.setting(number, to: 1)
				.setting(custom, to: .pixels(3)))
		}.css

		for (name, syntax, initialValue) in [("angle", "<angle>", "0deg"), ("color", "<color>", "#000"), ("length", "<length>", "1px"), ("percentage", "<percentage>", "0%"), ("number", "<number>", "0"), ("custom", "<length> | auto", "auto")] {
			#expect(css.contains("@property --\(name) {\n\tsyntax: \"\(syntax)\";\n\tinherits: \(name == "custom" ? "false" : "true");\n\tinitial-value: \(initialValue);\n}"))
		}
		#expect(Style().rotationEffect(angle.value).declarations.last?.value.description == "var(--angle)")
	}

	@Test
	func `box shadows retain spread and inset while text and drop shadows use only their supported values`() {
		let shadow = Shadow(x: .pixels(1), y: .pixels(2), blur: .pixels(3), color: .black)
		#expect(Style().textShadow(shadow).declarations.last?.value.description == "1px 2px 3px #000")
		#expect(Filter.dropShadow(shadow).description == "drop-shadow(1px 2px 3px #000)")

		let boxShadow = BoxShadow(x: .pixels(1), y: .pixels(2), blur: .pixels(3), spread: .pixels(-4), color: .black, isInset: true)
		let edge = BoxShadow(y: .zero, spread: .pixels(1), color: .white)
		#expect(Style().shadow(boxShadow, edge).declarations.last?.value.description == "inset 1px 2px 3px -4px #000, 0 0 0 1px #fff")
		#expect(Style().shadow([boxShadow, edge]).declarations.last?.value == Style().shadow(boxShadow, edge).declarations.last?.value)
		#expect(Style().shadow().declarations.last?.value == CSSValue.none)
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
				document.require(script: #path("/script.js"))
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
		#expect(page.scripts == [#path("/script.js")])
	}

	@Test
	func `typed style values and keywords share the declaration boundary`() {
		let style = Style()
			.declaration(raw: .width, LengthPercentage.rootEm(2))
			.declaration(raw: .color, Color.white)
			.declaration(raw: .display, Display.grid)
			.declaration(raw: .rotate, Angle.degrees(45))
			.declaration(raw: .gridAutoColumns, GridTrack.fraction(1))
			.declaration(raw: .fontFamily, FontFamily(raw: "system-ui"))
		#expect(style.declarations.map(\.value.description) == ["2rem", "#fff", "grid", "45deg", "1fr", "system-ui"])
		#expect(div(.ariaCurrent(.step)) { "Step" }.render().contains(#"aria-current="step""#))
	}

	@Test
	func `radial shapes keep their radii and position separate from color stops`() {
		let position = CSSPosition(x: .percent(20), y: .percent(40))
		#expect(RadialGradientShape.circle.description == "circle")
		#expect(RadialGradientShape.circle(radius: .em(2.5), at: position).description == "circle 2.5em at 20% 40%")
		#expect(RadialGradientShape.ellipse(radiusX: .percent(30), radiusY: .percent(12), at: position).description == "ellipse 30% 12% at 20% 40%")
		#expect(RadialGradientShape.ellipse(extent: .closestSide).description == "ellipse closest-side")
		#expect(RadialGradientShape.circle(extent: .farthestSide, at: position).description == "circle farthest-side at 20% 40%")
		#expect(CSSImage.radialGradient(.init(raw: "farthest-corner at left top"), .black, .white).description == "radial-gradient(farthest-corner at left top, #000, #fff)")

		let first = Color.black.at(.percent(0))
		let second = Color.white.at(.percent(50))
		let third = Color.transparent.at(.percent(100))
		#expect(CSSImage.linearGradient(.toRight, first, second, third, in: .oklch).description == "linear-gradient(to right in oklch, #000 0%, #fff 50%, transparent 100%)")
		#expect(CSSImage.radialGradient(.circle(at: position), first, second, third).description == "radial-gradient(circle at 20% 40%, #000 0%, #fff 50%, transparent 100%)")
		#expect(CSSImage.conicGradient(.black, .white, .transparent, from: .degrees(90), in: .oklab).description == "conic-gradient(from 90deg in oklab, #000, #fff, transparent)")
	}

	@Test
	func `counter declarations share a generated name and unrelated counters remain separate`() {
		#expect(Counters.step.name == "style-value-tests-step")
		#expect(OtherCounters.step.name == "other-step")
		let style = Style()
			.counterReset(Counters.step)
			.counterIncrement(Counters.step)
			.content(counter: Counters.step, style: .decimalLeadingZero, alternativeText: "")
		#expect(style.declarations.map(\.value.description) == ["style-value-tests-step", "style-value-tests-step", "counter(style-value-tests-step, decimal-leading-zero) / \"\""])
	}

	@Test
	func `length math requires operands and gives zero its length type inside functions`() {
		#expect(Length.min(.zero).description == "min(0px)")
		#expect(Length.max(.pixels(2), .pixels(3), .pixels(4)).description == "max(2px, 3px, 4px)")
		#expect(LengthPercentage.min(.zero, .percent(100) - .pixels(8)).description == "min(0px, 100% - 8px)")
		#expect(LengthPercentage.clamp(.zero, .viewportWidth(5), .rootEm(2)).description == "clamp(0px, 5vw, 2rem)")
		#expect(LengthPercentage(Length.pixels(2) + .rootEm(1)).description == "calc(2px + 1rem)")
		#expect((Length.pixels(2) + .pixels(3)).description == "5px")
		#expect((Length.rootEm(3) / 2).description == "1.5rem")
		#expect((-Length.pixels(4)).description == "-4px")
		#expect(Length.clamp(.rootEm(1), .pixels(2), .rootEm(3)).description == "clamp(1rem, 2px, 3rem)")
		#expect(CSSValue.inherit.description == "inherit")
		#expect(Length.zero.description == "0")
	}

	@Test
	func `a repeating animation alternates by default and every timing curve writes its function`() {
		let repeating = Stylesheet {
			Rule(".a", Style().animation(FadeAnimations.fade, .easeInOut(duration: .seconds(2)).repeatForever()))
		}.css
		#expect(repeating.contains("animation: fade-fade 2s ease-in-out infinite alternate;"))

		let timings = [
			AnimationTiming.`default`(duration: .seconds(1)),
			AnimationTiming.linear(duration: .seconds(1)),
			AnimationTiming.easeIn(duration: .seconds(1)),
			AnimationTiming.easeOut(duration: .seconds(1)),
			AnimationTiming.easeInOut(duration: .seconds(1)),
			AnimationTiming.timingCurve(0.22, 1, 0.36, 1, duration: .seconds(1)),
			AnimationTiming.steps(1, duration: .seconds(1)),
		]
		#expect(timings.map(\.description) == [
			"1s",
			"1s linear",
			"1s ease-in",
			"1s ease-out",
			"1s ease-in-out",
			"1s cubic-bezier(.22, 1, .36, 1)",
			"1s steps(1, end)",
		])
	}

	@Test
	func `number percentage and mixed length registrations preserve their distinct syntax`() {
		let number = RegisteredProperty<CSSNumber>("number", initialValue: 0)
		let percentage = RegisteredProperty<Percentage>("percentage", initialValue: .percent(0))
		let offset = RegisteredProperty<LengthPercentage>("offset", initialValue: .pixels(0))
		let css = Stylesheet {
			Rule(".x", Style()
				.setting(number, to: 2.5)
				.setting(percentage, to: .percent(35))
				.setting(offset, to: .percent(100) - .pixels(8)))
		}.css

		#expect(css.contains("--number: 2.5;"))
		#expect(css.contains("--percentage: 35%;"))
		#expect(css.contains("--offset: calc(100% - 8px);"))
		#expect(css.contains("syntax: \"<number>\";"))
		#expect(css.contains("syntax: \"<percentage>\";"))
		#expect(css.contains("syntax: \"<length-percentage>\";"))
		#expect(number.variable.value(default: 3).description == "var(--number, 3)")
		#expect(LengthPercentage(percentage.value).description == "var(--percentage)")
		#expect((LengthPercentage(Percentage.percent(35)) - .pixels(2)).description == "calc(35% - 2px)")
	}

	@Test
	func `images positions and flexible tracks use their own typed modifiers`() {
		let image = CSSImage.linearGradient(.toRight, .black, .white)
		let position = CSSPosition(x: .percent(20), y: .pixels(3))
		let style = Style()
			.backgroundImage(image, .url(#path("/image.png")))
			.maskImage(.none)
			.backgroundPosition(position)
			.transformOrigin(.center, depth: .pixels(5))
			.gridColumns(.fixed(.rootEm(5.5)), .flexible(), .flexible(minimum: .percent(20), fraction: 3))

		#expect(style.declarations.map(\.value.description) == ["linear-gradient(to right, #000, #fff), url(\"/image.png\")", "none", "20% 3px", "50% 50% 5px", "5.5rem minmax(0, 1fr) minmax(20%, 3fr)"])
		#expect(CSSImage(raw: "image-set(url(a.png) 1x)").description == "image-set(url(a.png) 1x)")
		#expect(Length(raw: "var(--width)").description == "var(--width)")
	}

	@Test
	func `one run timing composes with animations and typed scroll offsets preserve raw ranges`() {
		let timing = AnimationTiming.easeOut(duration: .milliseconds(250))
		let transition = Style().transition(.opacity, timing: timing)
		#expect(transition.declarations.last?.value.description == "opacity .25s ease-out")
		let animation = Animation(timing: timing).repeatForever(autoreverses: false)
		let css = Stylesheet {
			Rule(".animated", Style().animation(FadeAnimations.fade, animation))
			Rule(".scroll", Style().animation(FadeAnimations.fade, timeline: .scroll, from: .zero, to: .rootEm(2)))
			Rule(".named", Style().animation(FadeAnimations.fade, viewTimeline: ViewTimeline("section"), from: .entry(.percent(10)), to: .exit(.percent(90))))
		}.css
		#expect(css.contains("animation: fade-fade .25s ease-out infinite;"))
		#expect(css.contains("animation-range: 0 2rem;"))
		#expect(css.contains("animation-range: entry 10% exit 90%;"))
		#expect(css.ranges(of: "@keyframes fade-fade").count == 1)
	}

	@Test
	func `color mixing retains percentage custom properties and fallbacks`() {
		let amount = StyleVariable<Percentage>("mix")
		let registeredAmount = RegisteredProperty<Percentage>("registered-mix", initialValue: .percent(0))
		#expect(Color.white.mix(with: .black, amount: amount.value(default: .percent(30))).description == "color-mix(in oklch, #fff, #000 var(--mix, 30%))")
		#expect(Color.white.mix(with: .black, amount: registeredAmount.value).description == "color-mix(in oklch, #fff, #000 var(--registered-mix))")
	}

	@Test
	func `numeric modifiers accept typed custom properties without erasing their values`() {
		let number = StyleVariable<CSSNumber>("number").value(default: 0.5)
		let style = Style()
			.opacity(number)
			.scaleEffect(number)
			.lineHeight(number)
			.font(size: .rootEm(1), lineHeight: number)
			.flex(number)
			.flexShrink(number)
		#expect(style.declarations.map(\.value.description) == ["var(--number, .5)", "var(--number, .5)", "var(--number, .5)", "1rem", "var(--number, .5)", "var(--number, .5)", "var(--number, .5)"])
	}

	@Test
	func `empty filter lists reset effects and nonempty lists preserve their order`() {
		let filters: [Filter] = [.blur(radius: .pixels(2)), .brightness(1.2)]
		#expect(Style().filter().declarations.last?.value == CSSValue.none)
		#expect(Style().filter([]).declarations.last?.value == CSSValue.none)
		#expect(Style().backdropFilter().declarations.last?.value == CSSValue.none)
		#expect(Style().backdropFilter([]).declarations.last?.value == CSSValue.none)
		#expect(Style().filter(filters).declarations.last?.value.description == "blur(2px) brightness(1.2)")
		#expect(Style().backdropFilter(filters).declarations.last?.value.description == "blur(2px) brightness(1.2)")
	}

	@Test
	func `step timing functions retain typed positions and explicit raw curves`() {
		let positions: [StepPosition] = [.start, .end, .jumpStart, .jumpEnd, .jumpNone, .jumpBoth]
		#expect(positions.map { AnimationTiming.steps(2, position: $0, duration: .seconds(1)).description } == ["1s steps(2, start)", "1s steps(2, end)", "1s steps(2, jump-start)", "1s steps(2, jump-end)", "1s steps(2, jump-none)", "1s steps(2, jump-both)"])
		#expect(AnimationTiming.timingCurve(raw: "linear(0, .5 10%, 1)", duration: .seconds(1)).description == "1s linear(0, .5 10%, 1)")
		let css = Stylesheet {
			Rule(".steps", Style().animation(FadeAnimations.fade, .steps(12, duration: .seconds(6)).repeatForever(autoreverses: false)))
			Rule(".raw", Style().animation(FadeAnimations.fade, .timingCurve(raw: "linear(0, 1)", duration: .seconds(1))))
		}.css
		#expect(css.contains("animation: fade-fade 6s steps(12, end) infinite;"))
		#expect(css.contains("animation: fade-fade 1s linear(0, 1);"))
	}

	@Test
	func `named animation boundaries compose with plain offsets and retain raw escapes`() {
		let boundaries: [AnimationRangeBoundary] = [.offset(.pixels(2)), .entry(.percent(10)), .exit(.percent(90)), .cover(.percent(20)), .contain(.percent(30)), .entryCrossing(.percent(40)), .exitCrossing(.percent(50))]
		#expect(boundaries.map(\.description) == ["2px", "entry 10%", "exit 90%", "cover 20%", "contain 30%", "entry-crossing 40%", "exit-crossing 50%"])
		let css = Stylesheet {
			Rule(".mixed", Style().animation(FadeAnimations.fade, viewTimeline: ViewTimeline("section"), from: .offset(.zero), to: .cover(.percent(90))))
			Rule(".raw", Style().animation(FadeAnimations.fade, timeline: .scroll, rawRange: "normal exit 50%"))
		}.css
		#expect(css.contains("animation-range: 0 cover 90%;"))
		#expect(css.contains("animation-range: normal exit 50%;"))
	}

	@Test
	func `a leading grid track composes with a typed repeated track`() {
		#expect(Style().grid(columns: .fixed(.rootEm(1.25)), repeating: .fraction(1), count: 8).declarations.map(\.value.description) == ["grid", "1.25rem repeat(8, 1fr)"])
		#expect(Style().grid(columns: .fixed(.characterWidth(2.5)), repeating: .fraction(1), count: 4).declarations.last?.value.description == "2.5ch repeat(4, 1fr)")
		#expect(Style().grid(columns: .auto, repeating: .flexible(), count: 1).declarations.last?.value.description == "auto repeat(1, minmax(0, 1fr))")
		#expect(Length.characterWidth(2).description == "2ch")
	}
}

private enum OtherCounters: String, CounterSet {
	case step
}

private enum FadingStyles: String, StyleSet {
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

private enum CountedStyles: String, StyleSet {
	case first
	case second

	static let computations = Mutex(0)

	var style: Style {
		Self.computations.withLock { $0 += 1 }
		return Style().opacity(0.5)
	}
}

private enum CountedAnimations: String, KeyframeSet {
	case fade

	static let computations = Mutex(0)

	var keyframes: [Keyframe] {
		Self.computations.withLock { $0 += 1 }
		return [.to(Style().opacity(0))]
	}
}

private enum ReplayStyles: String, StyleSet {
	case first
	case second

	var style: Style {
		Style().opacity(0.5)
	}
}

private enum DescribedCounters: String, CounterSet, CustomStringConvertible {
	case step = "stableStep"

	var description: String {
		"Display counter"
	}
}

private enum DescribedAnimations: String, KeyframeSet, CustomStringConvertible {
	case fade = "stableFade"

	var description: String {
		"Display animation"
	}

	var keyframes: [Keyframe] {
		[.to(Style().opacity(0))]
	}
}
