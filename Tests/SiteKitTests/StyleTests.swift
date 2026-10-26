import Elementary
import Testing
import SiteKit

struct StyleTests {
	/**
	A number that is not finite, like from a division by zero, is a mistake in the code, so the build stops and names it, instead of writing CSS that the browser ignores.
	*/
	@Test
	func `a length that is not finite stops the build with a message`() async throws {
		let result = try #require(await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
			_ = Length.pixels(.nan).description
		})
		#expect(String(decoding: result.standardErrorContent, as: UTF8.self).contains("must be finite"))

		await #expect(processExitsWith: .failure) {
			let breakpoint = Breakpoint(minimumWidthInRem: 40)
			_ = Style().fluidFontSize(fromRem: 1, toRem: 2, between: breakpoint, and: breakpoint)
		}
	}

	/**
	A length like `1` without a unit is invalid CSS, which the browser ignores, so a literal other than `0` stops the build, like `.padding(1)` for `.padding(.pixels(1))`.
	*/
	@Test
	func `a length literal other than 0 stops the build with a message`() async throws {
		#expect(ruleCSS(Style().padding(0)) == ".x {\n\tpadding: 0;\n}\n")

		let result = try #require(await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
			_ = Style().padding(1)
		})
		#expect(String(decoding: result.standardErrorContent, as: UTF8.self).contains("must be 0"))
	}

	@Test
	func `a condition that sets nothing writes no block`() {
		let css = Stylesheet {
			Rule(".card", Style().padding(.rootEm(1)).dark { $0 })
		}.css

		#expect(!css.contains("@media"))
		#expect(css.contains("padding: 1rem;"))
	}

	@Test
	func `a combined style keeps the scope of the other style`() {
		let css = Stylesheet {
			Rule(".prose", Style().combined(with: Style().padding(.rootEm(1)).scoped()))
		}.css

		#expect(css.contains("@scope (.prose)"))
	}

	/**
	In a nested rule, `& > p, label` would match a `label` at any depth.
	*/
	@Test
	func `a list of child selectors only matches direct children`() {
		let css = Stylesheet {
			Rule(
				".form",
				Style()
				.children("p, label") {
					$0.padding(.rootEm(1))
				}
				.children("li") {
					$0.padding(.rootEm(1))
				}
			)
		}.css

		#expect(css.contains("& > :is(p, label) {"))
		#expect(css.contains("& > li {"))
	}

	/**
	Safari only supports the prefixed property.
	*/
	@Test
	func `text selection is set for Safari too`() {
		let css = Stylesheet {
			Rule(".button", Style().textSelection(.disabled))
		}.css

		#expect(css.contains("-webkit-user-select: none;\n\tuser-select: none;"))
	}

	@Test
	func `a huge length is written as a CSS number with an exponent`() {
		#expect(Length.pixels(1e19).description == "1e+19px")
		#expect(Length.pixels(-1e19).description == "-1e+19px")
	}

	/**
	A page with its own look, like a page from 1999, can have image pointers, 3D borders, a canvas of big pixels to draw on with a finger, a toy that a finger steers sideways while the page scrolls over it, text down the side of a menu, a dotted focus ring for all its controls, and the scroll bars of the page in Chrome and Safari, with colors for the other browsers.
	*/
	@Test
	func `image cursors, border styles, and the scroll bars of the page`() {
		let css = Stylesheet {
			Rule(
				".page",
				Style()
				.cursor("/arrow.png", x: 1, y: 2, fallback: .default)
				.border(Color("#ccc"), width: .pixels(2), style: .outset)
				.children("canvas") {
					$0
						.cursor(.crosshair)
						.touchAction(.none)
						.imageRendering(.pixelated)
				}
				.children("p") {
					$0.writingMode(.verticalRightToLeft)
				}
				.children("output") {
					$0.touchAction(.panY)
				}
				.children("progress") {
					$0.cursor("/hourglass.gif", x: 14, y: 16, fallback: .wait)
				}
				.focusVisibleInside {
					$0.focusRing(.currentColor, width: .pixels(1), offset: .pixels(2), style: .dotted)
				}
				.onPageRoot {
					$0
						.scrollbar(.thumb) {
							$0.background(Color("#c0c0c0"))
						}
						.scrollbar(.upButton) {
							$0.backgroundImage(.url("/up.png"))
						}
						.supports(!.webKitScrollbar) {
							$0.scrollbarColor(thumb: Color("#c0c0c0"), track: .white)
						}
				}
			)
		}.css

		#expect(css.contains(#"cursor: url("/arrow.png") 1 2, default"#))
		#expect(css.contains("border: 2px outset #ccc"))
		#expect(css.contains("cursor: crosshair;\n\t\ttouch-action: none;\n\t\timage-rendering: pixelated;"))
		#expect(css.contains("writing-mode: vertical-rl"))
		#expect(css.contains("touch-action: pan-y"))
		#expect(css.contains(#"cursor: url("/hourglass.gif") 14 16, wait"#))
		#expect(css.contains("& :focus-visible {\n\t\toutline: 1px dotted currentColor;\n\t\toutline-offset: 2px;"))
		#expect(css.contains(":root:has(&) {"))
		#expect(css.contains("&::-webkit-scrollbar-thumb {"))
		#expect(css.contains(#"&::-webkit-scrollbar-button:vertical:start:decrement {"#))
		#expect(css.contains(#"background-image: url("/up.png")"#))
		#expect(css.contains("@supports not (selector(::-webkit-scrollbar)) {"))
		#expect(css.contains("scrollbar-color: #c0c0c0 #fff"))
	}

	enum Styles: StyleSet {
		case root
		case iconLink

		var style: Style {
			switch self {
			case .root:
				Style()
					.padding(vertical: .rootEm(1), horizontal: .rootEm(1.5))
					.hover {
						$0.background(Color("red").opacity(0.5))
					}
			case .iconLink:
				Style()
					.frame(width: .rootEm(2), maxWidth: .percent(100))
			}
		}
	}

	@Test
	func `colors can be made from a hue and mixed, and text shadows have no spread`() {
		let hue = StyleVariable<CSSValue>("--hue")
		let color = Color.hsl(hue: hue.value, saturation: 1, lightness: 0.65)
		#expect(color.description == "hsl(var(--hue) 100% 65%)")
		#expect(Color.hsl(hue: 200, saturation: 0.07, lightness: 0.57).description == "hsl(200 7% 57%)")
		#expect(Color.white.mix(with: .black, amount: .percent(30)).description == "color-mix(in oklch, #fff, #000 30%)")

		let css = Stylesheet {
			Rule(".glow", Style().textShadow(Shadow(y: 0, blur: .pixels(20), spread: .pixels(4), color: .black)))
		}.css

		#expect(css.contains("text-shadow: 0 0 20px #000"))
	}

	@Test
	func `modifiers render in order, and conditions nest`() {
		let css = Stylesheet {
			Rule(
				".card",
				Style()
				.display(.flex)
				.padding(.horizontal, .rootEm(1))
				.border(.top, .currentColor)
				.important {
					$0.opacity(0.5)
				}
				.nested(".icon") {
					$0.font(size: .rootEm(1), lineHeight: 1.5)
				}
				.dark {
					$0
						.color("white")
						.hover {
							$0.underline(false)
						}
				}
			)
		}.css

		#expect(css == """
		.card {
			display: flex;
			padding-inline: 1rem;
			border-top: 1px solid currentColor;
			opacity: .5 !important;
			.icon {
				font-size: 1rem;
				line-height: 1.5;
			}
			@media (prefers-color-scheme: dark) {
				color: white;
				@media (hover: hover) {
					&:hover {
						text-decoration: none;
					}
				}
			}
		}

		""")
	}

	@Test
	func `typed modifiers render CSS`() {
		let css = Stylesheet {
			Rule(
				".a",
				Style()
				.margin(top: 0, horizontal: .auto, bottom: .rootEm(5))
				.padding(top: .rootEm(1), bottom: .rootEm(2))
				.padding(.leading, .rootEm(1))
				.cornerRadius(.capsule)
				.scaleEffect(1.05)
				.offset(y: .pixels(-1))
				.filter(.blur(radius: .pixels(8)), .brightness(1.1), .hueRotation(.degrees(90)), .grayscale(1), .contrast(1.5))
				.transition(.colors, animation: .default(duration: .milliseconds(150)))
				.transition(.opacity, animation: .easeOut(duration: .seconds(1)))
				.hidden(below: Breakpoint(minimumWidthInRem: 40))
				.media(.print) {
					$0.hidden()
				}
			)
		}.css

		#expect(css == """
		.a {
			margin: 0 auto 5rem;
			padding-top: 1rem;
			padding-bottom: 2rem;
			padding-inline-start: 1rem;
			border-radius: 9999px;
			scale: 1.05;
			translate: 0 -1px;
			filter: blur(8px) brightness(1.1) hue-rotate(90deg) grayscale(1) contrast(1.5);
			transition: color .15s, background-color .15s, border-color .15s, opacity 1s ease-out;
			@media (width < 40rem) {
				display: none;
			}
			@media print {
				display: none;
			}
		}

		""")
	}

	@Test
	func `grid items can span rows, and columns can have sizes without a grid`() {
		#expect(ruleCSS(Style().gridRowSpan(2)) == ".x {\n\tgrid-row: span 2 / span 2;\n}\n")
		#expect(ruleCSS(Style().gridColumns(.auto, .fraction(1))) == ".x {\n\tgrid-template-columns: auto 1fr;\n}\n")
	}

	@Test
	func `text can be italic, or upright again`() {
		#expect(ruleCSS(Style().italic()) == ".x {\n\tfont-style: italic;\n}\n")
		#expect(ruleCSS(Style().italic(false)) == ".x {\n\tfont-style: normal;\n}\n")
	}

	@Test
	func `inline elements can be raised by a length, like an icon in the middle of the capital letters`() {
		#expect(ruleCSS(Style().verticalAlign(.capitalHeight(0.5) - Length.rootEm(1) * 0.5)) == ".x {\n\tvertical-align: calc(.5cap - .5rem);\n}\n")
		#expect(ruleCSS(Style().verticalAlign(.middle)) == ".x {\n\tvertical-align: middle;\n}\n")
	}

	@Test
	func `lengths support arithmetic`() {
		#expect((Length.rootEm(1) * 2).description == "2rem")
		#expect((Length.rootEm(1) + .rootEm(0.5)).description == "1.5rem")
		#expect((Length.rootEm(1) + .pixels(2)).description == "calc(1rem + 2px)")
		#expect((Length.viewportHeight(100) - .rootEm(4) - .pixels(1)).description == "calc(100vh - 4rem - 1px)")
		#expect((Length.viewportHeight(100) - (.rootEm(4) + .pixels(1))).description == "calc(100vh - (4rem + 1px))")
		#expect(((Length.viewportHeight(100) - .rootEm(4)) * 2).description == "calc((100vh - 4rem) * 2)")
		#expect((Length.rootEm(1) + 0).description == "1rem")
		#expect((0 - Length.rootEm(1)).description == "-1rem")
		#expect((Length("calc(1px + 2px)") - .rootEm(1)).description == "calc(calc(1px + 2px) - 1rem)")
		#expect((-Length.pixels(4)).description == "-4px")
	}

	@Test
	func `lengths support CSS math functions`() {
		#expect(Length.clamp(.rootEm(2), .viewportWidth(5.8), .rootEm(100)).description == "clamp(2rem, 5.8vw, 100rem)")
		#expect(Length.min(.rootEm(24), .viewportWidth(100) - .rootEm(2)).description == "min(24rem, 100vw - 2rem)")
		#expect(Length.max(.percent(100), .rootEm(2.75), .pixels(44)).description == "max(100%, 2.75rem, 44px)")
		#expect((Length.min(.percent(100), .rootEm(40)) - .rootEm(1)).description == "calc(min(100%, 40rem) - 1rem)")
		#expect(Length.clamp(.rootEm(1), (.rootEm(0.5) + .viewportWidth(2)) * 2, .rootEm(3)).description == "clamp(1rem, (.5rem + 2vw) * 2, 3rem)")
	}

	@Test
	func `a fluid font size is a clamp of rem and vw without noise`() {
		#expect(ruleCSS(Style().fluidFontSize(fromRem: 3, toRem: 3.5, between: Breakpoint(minimumWidthInRem: 40), and: Breakpoint(minimumWidthInRem: 48))) == ".x {\n\tfont-size: clamp(3rem, .5rem + 6.25vw, 3.5rem);\n}\n")
		#expect(ruleCSS(Style().fluidFontSize(fromRem: 0.875, toRem: 1.125, between: Breakpoint(minimumWidthInRem: 24), and: Breakpoint(minimumWidthInRem: 48))) == ".x {\n\tfont-size: clamp(.875rem, .625rem + 1.0417vw, 1.125rem);\n}\n")
		#expect(ruleCSS(Style().fluidFontSize(fromRem: 2, toRem: 1, between: Breakpoint(minimumWidthInRem: 20), and: Breakpoint(minimumWidthInRem: 40))) == ".x {\n\tfont-size: clamp(2rem, 3rem + -5vw, 1rem);\n}\n")
	}

	@Test
	func `lists can have no marker, bullets, or numbers`() {
		#expect(ruleCSS(Style().listStyle(.none)) == ".x {\n\tlist-style: none;\n}\n")
		#expect(ruleCSS(Style().listStyle(.disc)) == ".x {\n\tlist-style: disc;\n}\n")
		#expect(ruleCSS(Style().listStyle(.decimal)) == ".x {\n\tlist-style: decimal;\n}\n")
	}

	@Test
	func `hyphenation can be turned on and off`() {
		#expect(ruleCSS(Style().hyphenation(true)) == ".x {\n\thyphens: auto;\n}\n")
		#expect(ruleCSS(Style().hyphenation(false)) == ".x {\n\thyphens: none;\n}\n")
	}

	@Test
	func `an element can be styled while a control around it is disabled`() {
		let css = Stylesheet {
			Rule(".icon", Style().ancestorDisabled { $0.opacity(0.5) })
		}.css

		#expect(css == ".icon {\n\t:disabled & {\n\t\topacity: .5;\n\t}\n}\n")
	}

	@Test
	func `descendants are styled without the specificity of their selector`() {
		let css = Stylesheet {
			Rule(".prose", Style().descendants("ul, ol") { $0.padding(.leading, .rootEm(1)).before { $0.content("") } })
		}.css

		#expect(css == ".prose {\n\t& :where(ul, ol) {\n\t\tpadding-inline-start: 1rem;\n\t\t&::before {\n\t\t\tcontent: \"\";\n\t\t}\n\t}\n}\n")
	}

	@Test
	func `container units are percentages of the size of a container`() {
		#expect([Length.containerInlineSize(50), .containerBlockSize(50), .containerWidth(50), .containerHeight(50), .containerMinimum(50), .containerMaximum(50)].map(\.description) == ["50cqi", "50cqb", "50cqw", "50cqh", "50cqmin", "50cqmax"])
		#expect((Length.containerInlineSize(75) + .rootEm(0.75)).description == "calc(75cqi + .75rem)")
		#expect(ruleCSS(Style().containerType(.inlineSize)) == ".x {\n\tcontainer-type: inline-size;\n}\n")
		#expect(ruleCSS(Style().containerType(.size)) == ".x {\n\tcontainer-type: size;\n}\n")
	}

	@Test
	func `trimmed text grows the vertical padding by the trimmed space`() {
		#expect(Length.capitalHeight(1).description == "1cap")
		#expect(ruleCSS(Style().trimmedText()) == ".x {\n\ttext-box: trim-both cap alphabetic;\n\tpadding-block: calc(.5lh - .5cap);\n}\n")
		#expect(ruleCSS(Style().trimmedText(verticalPadding: .rootEm(0.25))) == ".x {\n\ttext-box: trim-both cap alphabetic;\n\tpadding-block: calc(.25rem + .5lh - .5cap);\n}\n")
	}

	@Test
	func `outlines can be dashed inside the element, or removed`() {
		#expect(ruleCSS(Style().outline(.currentColor, offset: .pixels(-6), style: .dashed)) == ".x {\n\toutline: 1px dashed currentColor;\n\toutline-offset: -6px;\n}\n")
		#expect(ruleCSS(Style().noOutline()) == ".x {\n\toutline: none;\n}\n")
	}

	@Test
	func `gradients can have color stops, go around a center, and be masks`() {
		#expect(CSSValue.linearGradient("to right", Color("red"), Color("blue"), in: .oklch).description == "linear-gradient(to right in oklch, red, blue)")
		#expect(CSSValue.linearGradient("175deg", Color.white.at(.percent(0)), Color.transparent.at(.percent(70))).description == "linear-gradient(175deg, #fff 0%, transparent 70%)")
		#expect(CSSValue.radialGradient("circle", Color.black.at(.percent(80)), Color.transparent.at(.percent(100))).description == "radial-gradient(circle, #000 80%, transparent 100%)")
		#expect(CSSValue.conicGradient(Color("red"), Color("blue")).description == "conic-gradient(red, blue)")
		#expect(CSSValue.conicGradient(Color("red"), Color("blue"), in: .oklab).description == "conic-gradient(in oklab, red, blue)")
		#expect(CSSValue.conicGradient(Color("red"), Color("blue"), from: .degrees(90)).description == "conic-gradient(from 90deg, red, blue)")
		#expect(CSSValue.conicGradient(Color("red"), Color("blue"), from: .degrees(90), in: .oklch).description == "conic-gradient(from 90deg in oklch, red, blue)")
		#expect(ruleCSS(Style().maskImage(.radialGradient("circle", .black, .transparent), .url("/mask.png"))) == ".x {\n\tmask-image: radial-gradient(circle, #000, transparent), url(\"/mask.png\");\n}\n")
	}

	@Test
	func `conditions for ARIA states, checked controls, and the states that a script sets`() {
		let css = Stylesheet {
			Rule(
				".x",
				Style()
				.current {
					$0.opacity(0.95)
				}
				.pressed {
					$0.opacity(1)
				}
				.ancestorPressed {
					$0.opacity(0.9)
				}
				.descendantPressed {
					$0.opacity(0.85)
				}
				.descendantChecked {
					$0.opacity(0.82)
				}
				.ancestorCurrent {
					$0.opacity(0.81)
				}
				.expanded {
					$0.opacity(0.8)
				}
				.when(CopyStates.copied) {
					$0.opacity(0.7)
				}
				.when(ancestorHas: CopyStates.copied) {
					$0.opacity(0.6)
				}
			)
		}.css

		#expect(css == """
		.x {
			&[aria-current] {
				opacity: .95;
			}
			&[aria-pressed="true"] {
				opacity: 1;
			}
			[aria-pressed="true"] & {
				opacity: .9;
			}
			&:has([aria-pressed="true"]) {
				opacity: .85;
			}
			&:has(input:checked) {
				opacity: .82;
			}
			[aria-current] & {
				opacity: .81;
			}
			&[aria-expanded="true"] {
				opacity: .8;
			}
			&[data-state="copied"] {
				opacity: .7;
			}
			[data-state="copied"] & {
				opacity: .6;
			}
		}

		""")
		#expect(CopyStates.copied.selector == #"[data-state="copied"]"#)
	}

	@Test
	func `conditions for focus, open details, backdrops, custom states, and empty elements`() {
		let css = Stylesheet {
			Rule(
				".x",
				Style()
				.focus {
					$0.opacity(1)
				}
				.open {
					$0.detailsContent {
						$0.frame(height: .auto)
					}
				}
				.backdrop {
					$0.background(.black.opacity(0.3))
				}
				.state("playing") {
					$0.opacity(0.5)
				}
				.empty {
					$0.frame(minHeight: .rootEm(2))
				}
			)
		}.css

		#expect(css == """
		.x {
			&:focus {
				opacity: 1;
			}
			&:open {
				&::details-content {
					height: auto;
				}
			}
			&::backdrop {
				background-color: rgb(0 0 0 / 30%);
			}
			&:state(playing) {
				opacity: .5;
			}
			&:empty {
				min-height: 2rem;
			}
		}

		""")
	}

	@Test
	func `elements can be positioned next to an anchor`() {
		let header = Anchor("--header")
		#expect(Length.anchor(header, .bottom).description == "anchor(--header bottom)")
		#expect(Length.anchor(.start).description == "anchor(start)")
		#expect(ruleCSS(Style().anchorName(header)) == ".x {\n\tanchor-name: --header;\n}\n")
		#expect(ruleCSS(Style().inset(0).top(.anchor(header, .bottom))) == ".x {\n\tinset: 0;\n\ttop: anchor(--header bottom);\n}\n")
		#expect(ruleCSS(Style().positionAnchor(header).positionArea(.top).positionTryFallbacks(.flipBlock, .flipInline)) == ".x {\n\tposition-anchor: --header;\n\tposition-area: top;\n\tposition-try-fallbacks: flip-block, flip-inline;\n}\n")
	}

	@Test
	func `an anchor name without two hyphens stops the build with a message`() async {
		await #expect(processExitsWith: .failure) {
			_ = Anchor("header")
		}
	}

	enum Animations: KeyframeSet {
		case fadeIn

		var keyframes: [Keyframe] {
			[.from(Style().opacity(0))]
		}
	}

	@Test
	func `keyframe sets name their animations after the enclosing type and the case`() {
		#expect(Animations.fadeIn.name == "style-tests-fade-in")
		#expect(Stylesheet { Animations.self }.css == "@keyframes style-tests-fade-in {\n\tfrom {\n\t\topacity: 0;\n\t}\n}\n")
	}

	/**
	A site without focus rings shows the look of the pointer for the focus of the keyboard. Only devices that can hover get the hover look.
	*/
	@Test
	func `hover or focus visible writes both states`() {
		let css = Stylesheet {
			Rule(".link", Style().hoverOrFocusVisible { $0.underline() })
		}.css

		#expect(css.contains("@media (hover: hover) {\n\t\t&:hover {\n\t\t\ttext-decoration: underline;"))
		#expect(css.contains("\t&:focus-visible {\n\t\ttext-decoration: underline;"))
	}

	@Test
	func `an underline can have a style, which a state can change alone`() {
		let css = Stylesheet {
			Rule(".term", Style().underline(style: .dotted, thickness: .pixels(1)).hoverOrFocusVisible { $0.underlineStyle(.solid) })
		}.css

		#expect(css.contains("text-decoration: underline;\n\ttext-decoration-style: dotted;\n\ttext-decoration-thickness: 1px;"))
		#expect(css.contains("\t&:focus-visible {\n\t\ttext-decoration-style: solid;"))
	}

	@Test
	func `a square frame sets the width and the height`() {
		let css = Stylesheet {
			Rule(".icon", Style().frame(size: .rootEm(2)))
		}.css

		#expect(css.contains("width: 2rem;"))
		#expect(css.contains("height: 2rem;"))
	}

	@Test
	func `a list of filters is one declaration`() {
		let css = Stylesheet {
			Rule(".badge", Style().filter([.blur(radius: .pixels(2)), .brightness(0.5)]))
		}.css

		#expect(css.contains("filter: blur(2px) brightness(.5);"))
	}

	@Test
	func `hidden without scripting only hides when scripting is off`() {
		let css = Stylesheet {
			Rule(".button", Style().hiddenWithoutScripting())
		}.css

		#expect(css.contains("@media (scripting: none) {\n\t\tdisplay: none;"))
	}

	@Test
	func `a registered property can transition`() {
		let css = Stylesheet {
			Rule(".light", Style().transition(TransitionProperty(Self.hue), animation: .linear(duration: .milliseconds(300))))
		}.css

		#expect(css.contains("transition: --hue .3s linear;"))
	}

	static let hue = RegisteredProperty<CSSValue>("--hue", syntax: .number, initialValue: 0)

	enum HueAnimations: KeyframeSet {
		case turnHue

		var keyframes: [Keyframe] {
			[.to(Style().setting(StyleTests.hue, to: 360))]
		}
	}

	enum HueStyles: StyleSet {
		case rainbow
		case slowRainbow

		var style: Style {
			switch self {
			case .rainbow:
				Style().animation(HueAnimations.turnHue, .default(duration: .seconds(6)).repeatForever(autoreverses: false))
			case .slowRainbow:
				Style().animation(HueAnimations.turnHue, .default(duration: .seconds(12)).repeatForever(autoreverses: false))
			}
		}
	}

	@Test
	func `animated registered properties are registered once with their keyframes`() {
		let css = Stylesheet {
			HueStyles.self
		}.css

		#expect(css.contains("@property --hue {\n\tsyntax: \"<number>\";\n\tinherits: true;\n\tinitial-value: 0;\n}"))
		#expect(css.contains("@keyframes style-tests-turn-hue {\n\tto {\n\t\t--hue: 360;\n\t}\n}"))
		#expect(css.matches(of: /@property/).count == 1)
		#expect(css.matches(of: /@keyframes/).count == 1)
	}

	@Test
	func `stylesheets write the order of their layers from the blocks`() {
		let base = CascadeLayer("base")
		let components = CascadeLayer("components")

		let css = Stylesheet {
			Layer(base) {
				Rule("a", Style().color(.inherit))
			}

			Layer(components) {
				Rule(".card", Style().padding(0))
			}

			Layer(base) {
				Rule("p", Style().margin(0))
			}
		}.css

		#expect(css.hasPrefix("@layer base, components;\n@layer base {"))
		#expect(Stylesheet { Layer(components) {} }.css == "@layer components {\n}\n")
	}

	@Test
	func `transitions list the property of the effect, and discrete properties allow discrete transitions`() {
		let style = Style()
			.transition(.scaleEffect, .display, animation: .easeOut(duration: .milliseconds(200)))
			.animation(HueAnimations.turnHue, .linear(duration: .seconds(6)).repeatForever(autoreverses: false))

		let css = Stylesheet { Rule("a", style) }.css

		#expect(css.contains("transition: scale .2s ease-out, display .2s ease-out allow-discrete, overlay .2s ease-out allow-discrete;"))
		#expect(css.contains("animation: style-tests-turn-hue 6s linear infinite;"))
	}

	@Test
	func `typed modifiers take typed variables`() {
		let size = StyleVariable<Length>("--size")
		let accent = StyleVariable<Color>("--accent")

		let style = Style()
			.setting(size, to: .rootEm(2))
			.frame(width: size.value * 2)
			.color(accent.value(default: .white))

		#expect(Stylesheet { Rule("a", style) }.css == "a {\n\t--size: 2rem;\n\twidth: calc(var(--size) * 2);\n\tcolor: var(--accent, #fff);\n}\n")
	}

	@Test
	func `animations only run for visitors who allow motion, unless they are essential`() {
		let css = Stylesheet {
			Rule("a", Style().opacity(0.5).animation(HueAnimations.turnHue, .linear(duration: .seconds(6))))
			Rule("b", Style().animation(HueAnimations.turnHue, .linear(duration: .seconds(6)), isEssential: true))
		}.css

		#expect(css.contains("a {\n\topacity: .5;\n\t@media (prefers-reduced-motion: no-preference) {\n\t\tanimation: style-tests-turn-hue 6s linear;\n\t}\n}"))
		#expect(css.contains("b {\n\tanimation: style-tests-turn-hue 6s linear;\n}"))
		#expect(css.matches(of: /@keyframes/).count == 1)
	}

	@Test
	func `style sets name their classes after the enclosing type and the case`() {
		#expect(Styles.root.className == "style-tests")
		#expect(Styles.iconLink.className == "style-tests-icon-link")
		#expect(Styles.iconLink.selector == ".style-tests-icon-link")

		let css = Stylesheet {
			Styles.self
		}.css

		#expect(css.contains(".style-tests {\n\tpadding: 1rem 1.5rem;\n\t@media (hover: hover) {\n\t\t&:hover {\n\t\t\tbackground-color: color-mix(in oklab, red 50%, transparent);\n\t\t}\n\t}\n}"))
		#expect(css.contains(".style-tests-icon-link {\n\twidth: 2rem;\n\tmax-width: 100%;\n}"))
	}

	/**
	The name of a private type has the private context in it, like `(unknown context at $1088071a4)`, which is not part of a class name.
	*/
	@Test
	func `a style set in a private type gets the name of the type`() {
		#expect(PrivateCard.Styles.root.className == "private-card")
	}

	/**
	Media Queries 4 does not allow `not` or `or` next to `and` without parentheses, so the browser would skip the block.
	*/
	@Test
	func `combining media queries keeps the meaning of not and or`() {
		#expect((MediaQuery("not (hover: hover)") && .dark).description == "(not (hover: hover)) and (prefers-color-scheme: dark)")
		#expect((MediaQuery("(hover: none) or (pointer: coarse)") && .dark).description == "((hover: none) or (pointer: coarse)) and (prefers-color-scheme: dark)")
		#expect((MediaQuery.from(Breakpoint(minimumWidthInRem: 40)) && .dark).description == "(width >= 40rem) and (prefers-color-scheme: dark)")
	}

	@Test
	func `style sets in generic types are named without the generic arguments`() {
		#expect(GenericWrapper<Int>.Styles.title.className == "generic-wrapper-title")
		#expect(GenericWrapper<[String: Int]>.Styles.title.className == "generic-wrapper-title")
	}

	@Test
	func `no text shadows is none, like no box shadows`() {
		#expect(ruleCSS(Style().textShadow()) == ".x {\n\ttext-shadow: none;\n}\n")
	}

	@Test
	func `filters can invert the colors and tint them sepia`() {
		#expect(ruleCSS(Style().filter(.invert(1), .sepia(0.5))) == ".x {\n\tfilter: invert(1) sepia(.5);\n}\n")
	}

	@Test
	func `flex lines can wrap upward and be packed at the start`() {
		#expect(ruleCSS(Style().flexWrap(isReversed: true).alignContent(.start)) == ".x {\n\tflex-wrap: wrap-reverse;\n\talign-content: flex-start;\n}\n")
	}

	@Test
	func `the scroll padding keeps links below a sticky bar`() {
		#expect(ruleCSS(Style().scrollPadding(top: .rootEm(4) + .rootEm(0.5))) == ".x {\n\tscroll-padding-top: 4.5rem;\n}\n")
		#expect(ruleCSS(Style().scrollPadding(bottom: .rootEm(2.5))) == ".x {\n\tscroll-padding-bottom: 2.5rem;\n}\n")
	}

	@Test
	func `scrolling can snap, keep the space of the scroll bar, and be smooth`() {
		#expect(ruleCSS(Style().scrollSnapType(.horizontal, isMandatory: true).scrollSnapAlign(.center)) == ".x {\n\tscroll-snap-type: x mandatory;\n\tscroll-snap-align: center;\n}\n")
		#expect(ruleCSS(Style().scrollSnapType(.vertical)) == ".x {\n\tscroll-snap-type: y;\n}\n")
		#expect(ruleCSS(Style().overscrollBehavior(horizontal: .contain).scrollbarGutter(.stable).scrollBehavior(.smooth)) == ".x {\n\toverscroll-behavior-x: contain;\n\tscrollbar-gutter: stable;\n\tscroll-behavior: smooth;\n}\n")
	}

	@Test
	func `color schemes, accent colors, field sizing, and floats at a logical edge`() {
		#expect(ruleCSS(Style().colorScheme(.lightDark).accentColor(Color("blue")).fieldSizing(.content)) == ".x {\n\tcolor-scheme: light dark;\n\taccent-color: blue;\n\tfield-sizing: content;\n}\n")
		#expect(ruleCSS(Style().float(.trailing)) == ".x {\n\tfloat: inline-end;\n}\n")
	}

	@Test
	func `grids can fill columns with rows and track sizes`() {
		#expect(ruleCSS(Style().gridRows(7, size: .auto).gridAutoFlow(.column).gridAutoColumns(.fraction(1))) == ".x {\n\tgrid-template-rows: repeat(7, auto);\n\tgrid-auto-flow: column;\n\tgrid-auto-columns: 1fr;\n}\n")
		#expect(ruleCSS(Style().gridAutoColumns(.fixed(.rootEm(0.625)))) == ".x {\n\tgrid-auto-columns: .625rem;\n}\n")
	}

	@Test
	func `keyframes that style sets in two layers use are written once`() {
		let css = Stylesheet {
			Layer(CascadeLayer("first")) {
				FirstFadeStyles.self
			}

			Layer(CascadeLayer("second")) {
				SecondFadeStyles.self
			}
		}.css

		#expect(css.ranges(of: "@keyframes fade-fade").count == 1)
	}

	@Test
	func `a transition after an important one is a declaration of its own`() {
		let css = Stylesheet {
			Rule(".a", Style().important { $0.noTransition() }.transition(.opacity, animation: .linear(duration: .milliseconds(100))))
		}.css

		#expect(!css.contains("!important,"))
		#expect(css.contains("transition: none !important;"))
	}

	@Test
	func `a digit before an uppercase letter starts a new word in a class name`() {
		#expect("Heading2Large".kebabCased == "heading2-large")
		#expect("H2Title".kebabCased == "h2-title")
		#expect("Base64".kebabCased == "base64")
	}

	@Test
	func `an acronym in a class name is one word that ends at its last capital`() {
		#expect("URLField".kebabCased == "url-field")
		#expect("HTMLElement".kebabCased == "html-element")
		#expect("FAQSuggestions".kebabCased == "faq-suggestions")
		#expect("URL".kebabCased == "url")
		#expect("feedCard".kebabCased == "feed-card")
	}

	@Test
	func `only the suffix at the end is removed from the name of a top-level style set`() {
		#expect(StylesheetPreviewStyles.root.className == "stylesheet-preview")
	}

	@Test
	func `the style modifier merges classes`() {
		let html = div {
			"Text"
		}
		.style(Styles.root)
		.style(Styles.iconLink)
		.render()

		#expect(html == #"<div class="style-tests style-tests-icon-link">Text</div>"#)
	}
}

struct StyleListTests {
	@Test
	func `a transition after no transition replaces it`() {
		let css = Stylesheet {
			Rule(".a", Style().noTransition().transition(.color, animation: .default(duration: .milliseconds(150))))
		}.css

		#expect(css.contains("transition: color .15s;"))
		#expect(!css.contains("none,"))
	}

	@Test
	func `transitions add up with other modifiers between them`() {
		let css = Stylesheet {
			Rule(
				".a",
				Style()
				.transition(.color, animation: .default(duration: .milliseconds(150)))
				.padding(.rootEm(1))
				.transition(.opacity, animation: .default(duration: .milliseconds(500)))
			)
		}.css

		#expect(css.contains("transition: color .15s, opacity .5s;"))
	}

	@Test
	func `rules keep the keyframes and the registered property of their animation, once for several rules`() {
		let css = Stylesheet {
			Rule(".a", Style().animation(StyleTests.HueAnimations.turnHue, .default(duration: .seconds(1))))
			Rule(".b", Style().animation(StyleTests.HueAnimations.turnHue, .default(duration: .seconds(2))))
		}.css

		#expect(css.matches(of: /@keyframes/).count == 1)
		#expect(css.matches(of: /@property/).count == 1)
	}
}

enum Card {
	enum Styles: StyleSet {
		case root

		var style: Style {
			Style()
		}
	}
}

enum CardStyles: StyleSet {
	case root

	var style: Style {
		Style()
	}
}

enum PanelStyles: StyleSet {
	case title
	case footer

	var style: Style {
		Style().padding(.rootEm(1))
	}
}

struct PageResourcesTests {
	@Test
	func `a page style set with the class name of a shared style set is a duplicate`() throws {
		let resources = PageResources(sharedStylesheet: Stylesheet {
			Layer(CascadeLayer("components")) {
				Card.Styles.self
			}
		})

		let error = try #require(throws: StyleError.self) {
			try resources.collect {
				div {}
					.style(CardStyles.root)
					.render()
			}
		}

		#expect(error.description.contains("class names card."))
	}

	@Test
	func `a page has only the rules of the styles it applies`() throws {
		let resources = PageResources()

		_ = try resources.collect {
			div {}
				.style(PanelStyles.title)
				.render()
		}

		let css = Stylesheet {
			resources.styleNodes
		}.css

		#expect(css.contains(".panel-title {"))
		#expect(!css.contains(".panel-footer"))
	}
}

/**
A private component, for the class names of style sets in private types.
*/
private enum PrivateCard {
	enum Styles: StyleSet {
		case root

		var style: Style {
			Style()
		}
	}
}

/**
A top-level style set whose name has its suffix, “Styles”, also at the start.
*/
enum StylesheetPreviewStyles: StyleSet {
	case root

	var style: Style {
		Style()
	}
}

/**
An animation that two style sets in different layers use.
*/
enum FadeAnimations: KeyframeSet {
	case fade

	var keyframes: [Keyframe] {
		[.to(Style().opacity(0))]
	}
}

enum FirstFadeStyles: StyleSet {
	case root

	var style: Style {
		Style().animation(FadeAnimations.fade, .default(duration: .seconds(1)))
	}
}

enum SecondFadeStyles: StyleSet {
	case root

	var style: Style {
		Style().animation(FadeAnimations.fade, .default(duration: .seconds(2)))
	}
}

/**
A component with a type parameter, like a list of any content.
*/
enum GenericWrapper<Value> {
	enum Styles: StyleSet {
		case title

		var style: Style {
			Style().opacity(0.5)
		}
	}
}

private enum CopyStates: String, ElementStateSet {
	case copied
}

/**
The CSS of a rule for `.x` with the style.
*/
private func ruleCSS(_ style: Style) -> String {
	Stylesheet {
		Rule(".x", style)
	}.css
}
