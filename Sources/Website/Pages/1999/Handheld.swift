import Elementary
import Foundation
import SiteKit

/**
My handheld game console in see-through purple, with a game of my own on its screen of 160 × 144 pixels: Super Sindre Land, a platform game through rainy Bergen, where the seagulls steal waffles and the goal is the flag at the top of Fløyen. The cartridge does not always start, like the real ones, so the visitor blows on it. Its script, `Handheld.js`, runs it, only while it is on the screen and the tab is visible. With reduced motion, the game only goes on while the visitor holds a button, so nothing moves by itself, and the logo does not scroll.
*/
struct GeoCitiesHandheld: ScriptedElement {
	static let script = ElementScript()

	/**
	The ID of the element, which the game console on the bed in my room leads to.
	*/
	static let rootID = "geocities-handheld"

	var rootAttributes: [HTMLAttribute<ElementTag<Self>>] {
		[.id(Self.rootID), .tabindex(-1)]
	}

	var content: some HTML {
		h2 {
			"My Handheld Game Console"
		}
		.style(GeoCitiesPage.Styles.heading, GeoCitiesPage.Styles.centeredText)

		p {
			"I got it for Christmas in 1998, in see-through purple. I made my own game for it (OK, in my head). Turn it on! Arrow keys or the D-pad to run, Up, X, or A to jump, Z or B to run faster, and Enter to start."
		}
		.style(GeoCitiesPage.Styles.centeredText)

		div {
			div {
				button(.part(Parts.power), .type(.button), .ariaPressed(false)) {
					"OFF ◂ ▸ ON"
				}
				.accessibilityLabel("Power")
				.style(Styles.power)

				span(.part(Parts.led)) {}
					.accessibilityHidden()
					.style(Styles.led)
			}
			.style(Styles.top)

			div {
				// The screen is drawn at 160 × 144 pixels, the size of the real screen.
				canvas(.part(Parts.screen), .width(160), .height(144), .tabindex(0), .role("application")) {}
					.accessibilityLabel("The screen of the game console. Use the arrow keys to run, the up arrow or X to jump, Z to run faster, and Enter to start or pause.")
					.style(Styles.screen)

				p {
					span {
						"C"
					}
					.style(Styles.red)
					span {
						"O"
					}
					.style(Styles.purple)
					span {
						"L"
					}
					.style(Styles.green)
					span {
						"O"
					}
					.style(Styles.yellow)
					span {
						"R"
					}
					.style(Styles.blue)
				}
				.accessibilityHidden()
				.style(Styles.brand)
			}
			.style(Styles.bezel)

			div {
				// The D-pad, as four buttons around a cross. The keyboard plays with the arrow keys on the screen instead, so the buttons are not in the order of the Tab key.
				div {
					for row in [[("up", "Up", "▲")], [("left", "Left", "◀"), ("right", "Right", "▶")], [("down", "Down", "▼")]] {
						div {
							for (control, label, symbol) in row {
								button(.type(.button), .tabindex(-1), .hook(Hooks.button, value: control)) {
									symbol
								}
								.accessibilityLabel(label)
								.style(Styles.padButton)
							}
						}
						.style(Styles.padRow)
					}
				}
				.style(Styles.pad)

				div {
					button(.type(.button), .tabindex(-1), .hook(Hooks.button, value: "b")) {
						"B"
					}
					.accessibilityLabel("B, run")
					.style(Styles.roundButton, Styles.buttonB)

					button(.type(.button), .tabindex(-1), .hook(Hooks.button, value: "a")) {
						"A"
					}
					.accessibilityLabel("A, jump")
					.style(Styles.roundButton, Styles.buttonA)
				}
				.style(Styles.ab)
			}
			.style(Styles.controls)

			div {
				button(.type(.button), .tabindex(-1), .hook(Hooks.button, value: "select")) {
					"SELECT"
				}
				.style(Styles.pill)

				button(.type(.button), .tabindex(-1), .hook(Hooks.button, value: "start")) {
					"START"
				}
				.style(Styles.pill)
			}
			.style(Styles.pills)
		}
		.style(Styles.body, GeoCitiesPage.Styles.scriptingOnly)

		div {
			button(.part(Parts.blow), .type(.button)) {
				"💨 Blow on the Cartridge"
			}
			.style(GeoCitiesPage.Styles.retroButton)

			p(.part(Parts.status), .role("status")) {
				"It is off. Slide the power switch!"
			}
			.style(Styles.status)
		}
		.style(Styles.below, GeoCitiesPage.Styles.scriptingOnly)

		p {
			"My game console needs JavaScript. And four AA batteries."
		}
		.style(GeoCitiesPage.Styles.scriptingDisabledOnly)
	}

	enum Parts: String, ElementPartSet {
		case power
		case led
		case screen
		case blow
		case status
	}

	enum Hooks: String, ScriptHookSet {
		/**
		The button of the game console, like `a` or `left`.
		*/
		case button = "data-handheld-button"
	}

	/**
	The styles of the game console, which ``GeoCitiesHandheldCamera`` uses for its game console too.
	*/
	enum Styles: ElementStyleSet {
		case root
		case body
		case top
		case power
		case led
		case bezel
		case screen
		case brand
		case red
		case purple
		case green
		case yellow
		case blue
		case controls
		case pad
		case padButton
		case padRow
		case ab
		case roundButton
		case buttonA
		case buttonB
		case pills
		case pill
		case below
		case status

		var style: Style {
			switch self {
			case .root:
				GeoCitiesPage.Styles.section.style
			case .body:
				// The game console in see-through purple, which shows the board inside.
				Style()
					.vstack(spacing: .rootEm(0.75))
					.frame(width: .rootEm(19), maxWidth: .percent(100))
					.margin(.horizontal, .auto)
					.padding(top: .rootEm(0.75), horizontal: .rootEm(1), bottom: .rootEm(1.25))
					.backgroundImage(.radialGradient("ellipse at 30% 20%", Color("#a48ad6e6"), Color("#6a4fa3e6"), Color("#45307ae6")))
					.border(Color("#3a2866"), width: .pixels(2))
					.cornerRadius(.rootEm(1))
					.shadow(Shadow(x: .pixels(4), y: .pixels(6), color: Color("#00000066")), Shadow(x: .pixels(-3), y: .pixels(-3), blur: .pixels(6), color: Color("#00000040"), isInset: true))
			case .top:
				Style().hstack(alignment: .center, justification: .spaceBetween, spacing: .rootEm(0.5))
			case .power:
				// The power switch on the top edge.
				Style()
					.padding(vertical: .rootEm(0.125), horizontal: .rootEm(0.5))
					.background(Color("#4a3580"))
					.border(Color("#2a1a55"), width: .pixels(2), style: .inset)
					.cornerRadius(.rootEm(0.25))
					.fontFamily(.system)
					.textStyle(.caption, weight: .bold)
					.color(Color("#e8dcff"))
					.handCursor()
					.buttonFocusRing(Color("#ffcc00"))
					.when(.state, is: "on") {
						$0.background(Color("#6a50b0"))
					}
			case .led:
				// The power light, red while it is on.
				Style()
					.frame(width: .rootEm(0.625), height: .rootEm(0.625))
					.background(Color("#441111"))
					.cornerRadius(.circle)
					.when(.state, is: "on") {
						$0
							.background(Color("#ff2222"))
							.shadow(Shadow(y: 0, blur: .pixels(6), color: Color("#ff3333")))
					}
			case .bezel:
				// The dark glass around the screen.
				Style()
					.vstack(alignment: .center, spacing: .rootEm(0.375))
					.padding(top: .rootEm(0.75), horizontal: .rootEm(1), bottom: .rootEm(0.5))
					.background(Color("#2b2b38"))
					.cornerRadius(.rootEm(0.5))
			case .screen:
				Style()
					.display(.block)
					.frame(width: .percent(100), height: .auto)
					.aspectRatio(160.0 / 144.0)
					.background(Color("#1a1a10"))
					.imageRendering(.pixelated)
					.focusVisible {
						$0.focusRing(Color("#ffcc00"), width: .pixels(2), offset: .pixels(2))
					}
			case .brand:
				Style()
					.margin(0)
					.fontFamily(.system)
					.textStyle(.caption, weight: .heavy)
					.italic()
					.letterSpacing(.em(0.05))
					.color(Color("#ccccdd"))
			case .red:
				Style().color(Color("#ff4444"))
			case .purple:
				Style().color(Color("#cc66ff"))
			case .green:
				Style().color(Color("#44dd66"))
			case .yellow:
				Style().color(Color("#ffdd33"))
			case .blue:
				Style().color(Color("#4499ff"))
			case .controls:
				Style().hstack(alignment: .center, justification: .spaceBetween, spacing: .rootEm(1))
			case .pad:
				Style().vstack(alignment: .center, spacing: 0)
			case .padRow:
				// The cross of the D-pad: left and right have the width of a button between them, where the middle of the cross is.
				Style()
					.hstack(alignment: .center, justification: .center, spacing: .rootEm(2.5))
					.background(Color("#222222"))
			case .padButton:
				// Big enough for a thumb, and pressed in while it is held down.
				Style()
					.frame(width: .rootEm(2.5), height: .rootEm(2.5))
					.background(Color("#222222"))
					.border(Color("#111111"), width: .pixels(1))
					.fontFamily(.system)
					.textStyle(.caption)
					.color(Color("#888888"))
					.touchAction(.none)
					.textSelection(.disabled)
					.handCursor()
					.active {
						$0.background(Color("#000000"))
					}
			case .ab:
				// The A and B buttons, at a slant.
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.75))
					.rotationEffect(.degrees(-20))
			case .roundButton:
				Style()
					.frame(width: .rootEm(3.25), height: .rootEm(3.25))
					.background(Color("#c8c8d8"))
					.border(Color("#555566"), width: .pixels(2))
					.cornerRadius(.circle)
					.shadow(Shadow(y: .pixels(3), color: Color("#2a1a55")))
					.fontFamily(.system)
					.textStyle(.body, weight: .bold)
					.color(Color("#333344"))
					.touchAction(.none)
					.textSelection(.disabled)
					.handCursor()
					.active {
						$0
							.offset(y: .pixels(2))
							.shadow(Shadow(y: .pixels(1), color: Color("#2a1a55")))
					}
			case .buttonA:
				Style().margin(.bottom, .rootEm(1.25))
			case .buttonB:
				Style().margin(.top, .rootEm(1.25))
			case .pills:
				Style().hstack(alignment: .center, justification: .center, spacing: .rootEm(1))
			case .pill:
				// The small slanted Select and Start buttons.
				Style()
					.padding(vertical: .rootEm(0.25), horizontal: .rootEm(0.75))
					.background(Color("#3a2a66"))
					.border(Color("#22184a"), width: .pixels(1))
					.cornerRadius(.capsule)
					.fontFamily(.system)
					.textStyle(.caption, weight: .bold)
					.color(Color("#d8ccff"))
					.rotationEffect(.degrees(-20))
					.touchAction(.none)
					.textSelection(.disabled)
					.handCursor()
			case .below:
				Style()
					.vstack(alignment: .center, spacing: .rootEm(0.5))
					.margin(top: .rootEm(1))
			case .status:
				Style()
					.frame(minHeight: .lineHeight(2))
					.margin(0)
					.fontFamily(GeoCitiesPage.comicSans)
					.textStyle(.caption, weight: .bold)
					.textAlign(.center)
			}
		}
	}
}
