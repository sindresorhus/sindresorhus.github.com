import Elementary
import Testing
import SiteKit

@Suite
struct StyleTests {
	enum Styles: StyleSet {
		case root
		case iconLink

		var style: Style {
			switch self {
			case .root:
				Style()
					.padding(vertical: .rem(1), horizontal: .rem(1.5))
					.hover {
						$0.background(Color("red").opacity(0.5))
					}
			case .iconLink:
				Style()
					.frame(width: .rem(2), maxWidth: .percent(100))
			}
		}
	}

	@Test
	func `modifiers render in order, and conditions nest`() {
		let css = Stylesheet {
			Rule(".card", Style()
				.display(.flex)
				.padding(.horizontal, .rem(1))
				.border(.top, .currentColor)
				.important {
					$0.opacity(0.5)
				}
				.nested(".icon") {
					$0.font(size: .rem(1), lineHeight: 1.5)
				}
				.dark {
					$0
						.color("white")
						.hover {
							$0.noUnderline()
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
			Rule(".a", Style()
				.margin(top: 0, horizontal: .auto, bottom: .rem(5))
				.padding(top: .rem(1), bottom: .rem(2))
				.padding(.leading, .rem(1))
				.cornerRadius(.capsule)
				.scaleEffect(1.05)
				.offset(y: .px(-1))
				.blur(radius: .px(8))
				.brightness(1.1)
				.transition(.colors, duration: .milliseconds(150))
				.transition(.opacity, duration: .seconds(1), curve: .easeOut)
				.hidden(below: Breakpoint(minimumWidthInRem: 40))
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
			filter: blur(8px) brightness(1.1);
			transition: color .15s, background-color .15s, border-color .15s, opacity 1s ease-out;
			@media (width < 40rem) {
				display: none;
			}
		}

		""")
	}

	@Test
	func `lengths support arithmetic`() {
		#expect((Length.rem(1) * 2).description == "2rem")
		#expect((Length.rem(1) + .rem(0.5)).description == "1.5rem")
		#expect((Length.rem(1) + .px(2)).description == "calc(1rem + 2px)")
		#expect((Length.vh(100) - .rem(4) - .px(1)).description == "calc((100vh - 4rem) - 1px)")
		#expect((-Length.px(4)).description == "-4px")
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

	static let hue = RegisteredProperty("--hue", syntax: "<number>", initialValue: 0)

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
				Style().animation(HueAnimations.turnHue, duration: .seconds(6), repeats: true)
			case .slowRainbow:
				Style().animation(HueAnimations.turnHue, duration: .seconds(12), repeats: true)
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
	func `rules keep the keyframes of their animations`() {
		let css = Stylesheet {
			Rule("body", Style().animation(HueAnimations.turnHue, duration: .seconds(6)))
		}.css

		#expect(css.contains("@keyframes style-tests-turn-hue"))
		#expect(css.contains("@property --hue"))
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

@Suite
struct StyleListTests {
	@Test
	func `a transition after no transition replaces it`() {
		let css = Stylesheet {
			Rule(".a", Style().noTransition().transition(.color, duration: .milliseconds(150)))
		}.css

		#expect(css.contains("transition: color .15s;"))
		#expect(!css.contains("none,"))
	}

	@Test
	func `transitions add up with other modifiers between them`() {
		let css = Stylesheet {
			Rule(".a", Style()
				.transition(.color, duration: .milliseconds(150))
				.padding(.rem(1))
				.transition(.opacity, duration: .milliseconds(500))
			)
		}.css

		#expect(css.contains("transition: color .15s, opacity .5s;"))
	}

	@Test
	func `keyframes that several style sets use are written once`() {
		let css = Stylesheet {
			Rule(".a", Style().animation(StyleTests.HueAnimations.turnHue, duration: .seconds(1)))
			Rule(".b", Style().animation(StyleTests.HueAnimations.turnHue, duration: .seconds(2)))
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

@Suite
struct PageResourcesTests {
	@Test
	func `a page style set with the class name of a shared style set is a duplicate`() {
		let resources = PageResources(sharedStyleSets: [Card.Styles.self])

		_ = resources.collect {
			div {}
				.style(CardStyles.root)
				.render()
		}

		#expect(resources.duplicateClassNames == ["card"])
	}
}
