import Elementary
import Foundation
import SiteKit

/**
A logo maker like Cool Text and FlamingText of 1999: the visitor types a word and picks a style, like fire, neon, chrome, or letters that wave, and its script, `CoolText.js`, shows the word in it, letter by letter. The visitor can put the logo at the top of the page, as its title, until the page reloads. Without motion, the letters stand still in their colors, and the typewriter shows the whole word.
*/
struct GeoCitiesCoolText: ScriptedElement {
	static let script = ElementScript()

	/**
	The ID of the field of the text, for its label.
	*/
	private static let inputID = "geocities-cool-text-input"

	let project: Project

	/**
	The styles of the logos, with their names.
	*/
	private static let effects: [(id: String, title: String)] = [
		("fire", "Fire"),
		("neon", "Neon"),
		("chrome", "Chrome"),
		("rainbow", "Rainbow"),
		("wavy", "Wavy"),
		("earthquake", "Earthquake"),
		("typewriter", "Typewriter"),
		("blink", "Blink"),
	]

	var content: some HTML {
		h2 {
			"Cool Text Generator 2.0"
		}
		.style(GeoCitiesPage.Styles.titleBar)

		div {
			p {
				GeoCitiesPage.GIFImage(gif: .skullFlaming, alt: "", style: .floating, project: project)
				"Make your own logo for your home page! No Photoshop needed. (Flaming skull not included.)"
			}

			form(.part(Parts.form)) {
				div {
					label(.for(Self.inputID)) {
						"Your text:"
					}
					.style(GeoCitiesPage.Styles.label)

					input(.id(Self.inputID), .part(Parts.input), .type(.text), .value("Sindre"), .autocomplete("off"), .maxlength(20), .custom(name: "spellcheck", value: "false"))
						.style(GeoCitiesPage.Styles.field)
				}

				fieldset {
					legend {
						"Style:"
					}
					.style(GeoCitiesPage.Styles.label)

					effectChoices
				}
				.style(Styles.fieldset)
			}
			.style(GeoCitiesPage.Styles.form, GeoCitiesPage.Styles.scriptingOnly)

			// The word in the picked style. The letters are only for the eyes, and screen readers read the word.
			div {
				p {
					span(.part(Parts.label)) {}
						.style(VisuallyHidden.Styles.root)

					span(.part(Parts.letters), .hook(ScriptAttribute.state, value: "fire")) {}
						.accessibilityHidden()
						.style(Styles.letters)
				}
			}
			.style(Styles.preview, GeoCitiesPage.Styles.scriptingOnly)

			GeoCitiesPage.GIFImage(gif: .dividerLaser, alt: "", style: .centered, project: project)

			div {
				button(.part(Parts.title), .type(.button)) {
					"Put it at the top of my page!"
				}
				.style(GeoCitiesPage.Styles.retroButton)
			}
			.style(GeoCitiesPage.Styles.buttonRow, GeoCitiesPage.Styles.scriptingOnly)

			p(.part(Parts.status), .role("status")) {}
				.style(GeoCitiesPage.Styles.centeredText)

			p {
				"The generator needs JavaScript. Here is a logo I made earlier: "
				strong {
					"SINDRE"
				}
				.style(GeoCitiesPage.Styles.rainbowText)
			}
			.style(GeoCitiesPage.Styles.scriptingDisabledOnly)

			p {
				for (gif, text) in [(GeoCitiesPage.GIF.buttonFlamingText, "FlamingText"), (.buttonCoolText, "Cool Text"), (.buttonJavaScript, "JavaScript Now!"), (.buttonDHTML, "Free DHTML scripts at 24fun.com")] {
					GeoCitiesPage.GIFImage(gif: gif, alt: text, style: .gif, project: project)
					" "
				}
			}
			.style(GeoCitiesPage.Styles.centeredText)
		}
		.style(GeoCitiesPage.Styles.windowBody)

		// `geocities-effects.js` adds copies that twinkle over the title of the page, like the sparkle scripts of 1999, also over a logo that the visitor put there.
		template(.id(Hooks.sparkleTemplate)) {
			img(.src(GeoCitiesPage.GIF.sparkle.path), .alt(""), .width(60), .height(56))
				.style(Styles.sparkle)
		}
	}

	/**
	A raised button for each style, as a radio button with its name.
	*/
	private var effectChoices: some HTML {
		div {
			for (index, effect) in Self.effects.enumerated() {
				label {
					input(.type(.radio), .name("geocities-cool-text-effect"), .value(effect.id))
						.attributes(.checked, when: index == 0)
						.style(Styles.radio)

					effect.title
				}
				.style(Styles.effect)
			}
		}
		.style(Styles.effects)
	}

	enum Parts: String, ElementPartSet {
		case form
		case input
		case label
		case letters
		case title
		case status
	}

	enum Hooks: String, ScriptHookSet {
		/**
		The sparkle that `geocities-effects.js` copies over the title of the page.
		*/
		case sparkleTemplate = "geocities-cool-text-sparkle"

		/**
		On the letters of a logo while they are in view, also on the copy at the top of the page, which is outside the element.
		*/
		case onScreen = "data-cool-text-on-screen"
	}

	enum Styles: ElementStyleSet {
		case root
		case fieldset
		case effects
		case effect
		case radio
		case preview
		case letters
		case sparkle

		var style: Style {
			switch self {
			case .root:
				GeoCitiesPage.Styles.window.style.display(.block)
			case .fieldset:
				Style()
					.frame(width: .percent(100))
					.margin(0)
					.padding(0)
					.border(.transparent, width: 0)
			case .effects:
				Style()
					.grid(minimumColumnWidth: .rootEm(7))
					.gap(.rootEm(0.25))
			case .effect:
				// A raised button for each style, which is pressed in while it is picked.
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.375))
					.padding(vertical: .rootEm(0.25), horizontal: .rootEm(0.5))
					.background(GeoCitiesPage.windowGray)
					.border(Color("#dfdfdf"), width: .pixels(2), style: .outset)
					.fontFamily(.system)
					.textStyle(.caption, weight: .bold)
					.handCursor()
					.focusWithin {
						$0.focusRing(.black, width: .pixels(1), offset: .pixels(-4), style: .dotted)
					}
			case .radio:
				Style()
					.margin(0)
					.handCursor()
			case .sparkle:
				// A sparkle that grows, turns, and shrinks away, once. `geocities-effects.js` puts it on a letter of the title and removes it when the animation ends.
				Style()
					.position(.absolute)
					.frame(width: .rootEm(1.75), height: .auto)
					.allowsHitTesting(false)
					.offset(x: .percent(-50), y: .percent(-50))
					.scaleEffect(0)
					.animation(Animations.twinkle, .easeInOut(duration: .milliseconds(1400)))
					.reducedMotion {
						$0.hidden()
					}
					.when(ancestorHas: GeoCitiesBestViewed.Hooks.view, is: "lynx") {
						$0.hidden()
					}
			case .preview:
				// A black box, so the glowing styles shine.
				Style()
					.hstack(alignment: .center, justification: .center)
					.frame(minHeight: .rootEm(6))
					.padding(.rootEm(0.75))
					.background(.black)
					.border(Color("#808080"), width: .pixels(3), style: .inset)
					.textAlign(.center)
					.fluidFontSize(fromRem: 2, toRem: 3.25, between: .phone, and: .tablet)
					.lineHeight(1.2)
					.overflowWrap(.anywhere)
			case .letters:
				// The letters of the logo. They take the size of where they are, so the logo fits in the box and in the title of the page.
				Style()
					.fontFamily(GeoCitiesPage.impact)
					.fontWeight(.regular)
					.letterSpacing(.em(0.04))
					.textShadow()
					.children("span") {
						$0.display(.inlineBlock)
					}
					.when(.state, is: "fire") {
						$0
							.color(Color("#ffee66"))
							.textShadow(Shadow(y: .pixels(-2), blur: .pixels(4), color: Color("#ffcc00")), Shadow(y: .pixels(-6), blur: .pixels(10), color: Color("#ff6600")), Shadow(y: .pixels(-12), blur: .pixels(18), color: Color("#cc0000")))
							// The flames move only while the script sees them in view, as an animated shadow costs the whole page a layout on each frame.
							.when(Hooks.onScreen) {
								$0.media(.allowsMotion) {
									$0.animation(Animations.fire, .easeInOut(duration: .milliseconds(180)).repeatForever())
								}
							}
					}
					.when(.state, is: "neon") {
						$0
							.fontFamily(GeoCitiesPage.comicSans)
							.color(Color("#ffe0ff"))
							.textShadow(Shadow(y: 0, blur: .pixels(4), color: Color("#ff66ff")), Shadow(y: 0, blur: .pixels(12), color: Color("#ff00cc")), Shadow(y: 0, blur: .pixels(24), color: Color("#ff00cc")))
							.media(.allowsMotion) {
								$0.animation(Animations.neon, .linear(duration: .seconds(3)).repeatForever(autoreverses: false))
							}
					}
					// Shiny metal, with a light top, a dark line in the middle, and a blue shadow, like the chrome logos of 1999. Each letter clips the metal to itself, as Safari does not paint the letters of its children through the clip of the parent. The metal is bright, so it shows on the black box.
					.when(.state, is: "chrome") {
						$0.children("*") {
							$0
								.backgroundImage(.linearGradient("to bottom", Color("#ffffff"), Color("#dde3ee"), Color("#8f9bb0"), Color("#ffffff"), Color("#b8c2d4")))
								.backgroundClip(.text)
								.color(.transparent)
								.filter(.dropShadow(Shadow(x: .pixels(2), y: .pixels(2), color: Color("#3366ff"))))
						}
					}
					.when(.state, is: "rainbow") {
						$0.media(.allowsMotion) {
							$0.animation(GeoCitiesPage.Animations.rainbow, .linear(duration: .seconds(2)).repeatForever(autoreverses: false))
						}
					}
					.when(.state, is: "wavy") {
						$0
							.color(Color("#66ffff"))
							.textShadow(Shadow(x: .pixels(3), y: .pixels(3), color: Color("#0000cc")))
							.media(.allowsMotion) {
								$0.children("span") {
									$0.animation(Animations.wave, .easeInOut(duration: .milliseconds(600)).repeatForever())
								}
							}
					}
					.when(.state, is: "earthquake") {
						$0
							.color(Color("#ff9933"))
							.textShadow(Shadow(x: .pixels(2), y: .pixels(2), color: Color("#663300")))
							.media(.allowsMotion) {
								$0.children("span") {
									$0.animation(Animations.quake, .linear(duration: .milliseconds(120)).repeatForever())
								}
							}
					}
					.when(.state, is: "typewriter") {
						$0
							.fontFamily(GeoCitiesPage.courier)
							.fontWeight(.bold)
							.color(Color("#33ff66"))
							.after {
								$0.content("_")
							}
							.media(.allowsMotion) {
								$0.after {
									$0.animation(GeoCitiesPage.Animations.blink, .timingCurve("steps(1, end)", duration: .seconds(1)).repeatForever(autoreverses: false))
								}
							}
					}
					.when(.state, is: "blink") {
						$0
							.fontFamily(GeoCitiesPage.times)
							.fontWeight(.bold)
							.color(Color("#ffff00"))
							.media(.allowsMotion) {
								$0.animation(GeoCitiesPage.Animations.blink, .timingCurve("steps(1, end)", duration: .seconds(1)).repeatForever(autoreverses: false))
							}
					}
			}
		}
	}

	enum Animations: KeyframeSet {
		case fire
		case neon
		case wave
		case quake
		case twinkle

		var keyframes: [Keyframe] {
			switch self {
			case .fire:
				// The flames get taller and shorter.
				[.to(Style().textShadow(Shadow(y: .pixels(-3), blur: .pixels(5), color: Color("#ffdd00")), Shadow(y: .pixels(-9), blur: .pixels(14), color: Color("#ff7700")), Shadow(y: .pixels(-16), blur: .pixels(24), color: Color("#dd0000"))))]
			case .neon:
				// Mostly on, with a quick stutter now and then, like an old tube. Never more than two flashes a second.
				[
					.at(90, Style().opacity(1)),
					.at(92, Style().opacity(0.3)),
					.at(95, Style().opacity(1)),
					.at(97, Style().opacity(0.4)),
				]
			case .wave:
				[.from(Style().offset(y: .em(0.15))), .to(Style().offset(y: .em(-0.15)))]
			case .twinkle:
				[
					.at(50, Style().scaleEffect(1).rotationEffect(.degrees(90))),
					.to(Style().scaleEffect(0).rotationEffect(.degrees(180))),
				]
			case .quake:
				[.from(Style().offset(x: .pixels(-2), y: .pixels(1)).rotationEffect(.degrees(-4))), .to(Style().offset(x: .pixels(2), y: .pixels(-1)).rotationEffect(.degrees(4)))]
			}
		}
	}
}
