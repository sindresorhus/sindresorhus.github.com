import Elementary
import Foundation
import SiteKit

/**
Pappa’s Desk Toys, the executive toys on the desk of Pappa at his office in Bergen, which I was allowed to play with on Take Your Kid to Work Day, all drawn on canvases on a desk of dark wood, each with a brass nameplate. A Newton’s cradle with five steel balls, where the visitor drags one, two, or three balls out on either side (or both sides at once, with two fingers or the button) and lets go, and the same number of balls swings out on the other side, with real momentum transfer, a bit of loss at each click-clack, and a click that is louder for a harder hit. A plasma ball with lightning tendrils that crawl from the center to the glass, all of which go to the pointer or finger when it touches the glass, with the buzz, and a fluorescent tube that lights up without a cable when the visitor drags it close. A pin art pinscreen, where the visitor presses with the pointer or with a stamp (a hand, a fist, a face, and Rocky the pet rock) and the shape comes out in the pins in 3D, until it is flipped. A drinking bird that dips its beak into a glass of water by itself, in a slow cycle, and stops when the glass is empty, until the visitor refills it, or that types Y on the keyboard of Pappa, like Homer Simpson. A Zen garden with a rake of four tines, stones to drag, circles around the stones, and smooth sand. A magnetic desk sculpture with colored paper clips that point out from the magnet, stick to each other, and fall off when the chain gets too long. A stress ball from a course about the year 2000 problem, which squashes and squeaks, the Executive Decision Maker that answers Yes, No, Ask your mother, or Lunch, and a perpetual motion machine that runs forever, as long as it is plugged in. Its script, `DeskToys.js`, runs them, only while they are on the screen and the tab is visible, and keeps the counts in the browser. Nothing makes a sound until the visitor turns on the sound, and with reduced motion, nothing moves by itself: the cradle and the bird move one step for each press, and the wheel stops at once. Without scripts, it is left out, as it has nothing to show.
*/
struct GeoCitiesDeskToys: ScriptedElement {
	static let script = ElementScript()

	/**
	A toy on the desk, with its canvas, its nameplate, and its buttons.
	*/
	private struct Toy: HTML {
		let canvas: Parts
		let name: String
		let caption: String
		let accessibilityLabel: String
		let buttons: [(id: String, label: String)]

		/**
		How a finger plays with the canvas, which decides whether a swipe over it scrolls the page.
		*/
		var touch = Styles.drags

		var body: some HTML {
			div {
				Elementary.canvas(.part(canvas), .width(480), .height(360), .tabindex(0), .role("application")) {}
					.accessibilityLabel(accessibilityLabel)
					.style(Styles.canvas, touch)

				p {
					name
				}
				.style(Styles.nameplate)

				p {
					caption
				}
				.style(Styles.caption)

				div {
					for button in buttons {
						Elementary.button(.type(.button), .hook(Hooks.button, value: button.id)) {
							button.label
						}
						.style(GeoCitiesPage.Styles.smallButton, Styles.button)
					}
				}
				.style(GeoCitiesPage.Styles.buttonRow)
			}
			.style(Styles.card)
		}
	}

	private static let toys = [
		Toy(
			canvas: .cradle,
			name: "Newton’s Cradle",
			caption: "Drag one, two, or three balls out and let go. Pappa says it is physics. Mamma says it is why he does not hear the phone.",
			accessibilityLabel: "Newton’s cradle with five steel balls. Drag a ball out to the side and let go, with one finger on each side to lift both sides. With the keyboard, 1, 2, or 3 lifts that many balls on the left, B lifts one ball on each side, and Space stops the balls (or, with reduced motion, takes the next step).",
			buttons: [
				("cradle-one", "Lift One"),
				("cradle-two", "Lift Two"),
				("cradle-three", "Lift Three"),
				("cradle-both", "Both Sides"),
				("cradle-stop", "✋ Stop"),
			],
			touch: .sideDrags
		),
		Toy(
			canvas: .plasma,
			name: "Plasma Ball",
			caption: "Touch the glass, and all the lightning comes to your finger. Drag the tube close to the ball, and it lights up with no cable. Pappa says it is not magic, it is 2 000 volts.",
			accessibilityLabel: "A plasma ball, with a fluorescent tube next to it. Touch or click the glass, and the lightning follows the pointer. Drag the tube near the ball to light it. With the keyboard, Space touches the glass, the arrow keys move the finger, and T moves the tube.",
			buttons: [
				("plasma-touch", "☝️ Touch the Glass"),
				("plasma-tube", "💡 Move the Tube"),
				("plasma-power", "⏻ Off"),
			]
		),
		Toy(
			canvas: .pins,
			name: "Pin Art",
			caption: "Press into the pins from behind, and the shape comes out on the front. Draw with the pointer or use a stamp. Flip it to start over.",
			accessibilityLabel: "A pin art pinscreen of steel pins. Drag over it to press the pins out. With the keyboard, the arrow keys move a finger that presses the pins, and F flips it.",
			buttons: [
				("pins-hand", "✋ Hand"),
				("pins-fist", "✊ Fist"),
				("pins-face", "🙂 Face"),
				("pins-rocky", "🪨 Rocky"),
				("pins-flip", "🔄 Flip"),
			]
		),
		Toy(
			canvas: .bird,
			name: "Drinking Bird",
			caption: "It drinks from the glass by itself, all day, like Pappa with his coffee. When the glass is empty, it stops. Or put it over the keyboard, so it answers Y to everything, like Homer Simpson.",
			accessibilityLabel: "A drinking bird with a top hat, next to a glass of water. Press it, or press Space, to tip it.",
			buttons: [
				("bird-tip", "👆 Tip It"),
				("bird-refill", "💧 Refill"),
				("bird-keyboard", "⌨️ Over the Keyboard"),
			],
			touch: .taps
		),
		Toy(
			canvas: .sand,
			name: "Zen Garden",
			caption: "Drag the rake through the sand, and drag the stones. Pappa rakes it after meetings about the year 2000.",
			accessibilityLabel: "A Zen sand garden with a rake of four tines and stones. Drag in the sand to rake lines, and drag a stone to move it. With the keyboard, the arrow keys rake lines.",
			buttons: [
				("sand-stone", "🪨 Add a Stone"),
				("sand-circles", "◎ Rake Circles"),
				("sand-smooth", "Smooth the Sand"),
			]
		),
		Toy(
			canvas: .magnet,
			name: "Magnet Sculpture",
			caption: "Drag the paper clips onto the magnet and build something spiky. Too far from the magnet, and they fall off.",
			accessibilityLabel: "A magnetic desk sculpture with paper clips. Drag a paper clip and drop it on the magnet or on other clips. With the keyboard, Space throws a paper clip on the magnet.",
			buttons: [
				("magnet-throw", "📎 Throw One On"),
				("magnet-off", "Pull Them Off"),
				("magnet-shake", "Shake the Desk"),
			]
		),
		Toy(
			canvas: .stress,
			name: "Stress Ball",
			caption: "Squeeze it. Press and hold harder for more. Pappa got it at a course about the year 2000 problem.",
			accessibilityLabel: "Pappa’s stress ball. Press and hold to squeeze it. With the keyboard, hold Space.",
			buttons: [
				("stress-squeeze", "✊ Squeeze"),
			]
		),
		Toy(
			canvas: .spinner,
			name: "Executive Decision Maker",
			caption: "For the big decisions at the office. Think of a question, and spin. Flick the wheel, or press the button.",
			accessibilityLabel: "The Executive Decision Maker, a wheel of answers. Drag to flick it, or press Space to spin it.",
			buttons: [
				("spinner-spin", "🎡 Spin"),
			]
		),
		Toy(
			canvas: .perpetual,
			name: "Perpetual Motion Machine",
			caption: "It runs forever, with no power at all. Do not look behind it.",
			accessibilityLabel: "A perpetual motion machine, a wheel with weights that turns, with a cable that goes behind the desk. Press the wheel to stop it or push it. With the keyboard, Space looks behind it.",
			buttons: [
				("perpetual-plug", "🔌 Look Behind It"),
			],
			touch: .taps
		),
	]

	var content: some HTML {
		h2 {
			"Pappa’s Desk Toys"
		}
		.style(GeoCitiesPage.Styles.heading, GeoCitiesPage.Styles.centeredText)

		p {
			"On Take Your Kid to Work Day, I went with Pappa to his office in Bergen sentrum. He has a computer, a fax, and a phone with eight buttons, but the best thing is his desk. It is full of executive toys, which help him think, he says. Mamma says they are why he comes home late. I played with them all day. Here they are, so you can play too."
		}

		desk

		p {
			"Pappa’s desk toys need JavaScript. And Pappa to look the other way."
		}
		.style(GeoCitiesPage.Styles.scriptingDisabledOnly)
	}

	private var desk: some HTML {
		div {
			div {
				button(.part(Parts.sound), .type(.button), .ariaPressed(false)) {
					"🔈 Sound"
				}
				.style(GeoCitiesPage.Styles.smallButton, Styles.button)
			}
			.style(GeoCitiesPage.Styles.buttonRow)

			div {
				for toy in Self.toys {
					toy
				}
			}
			.style(Styles.toys)

			div {
				p(.part(Parts.status), .role("status")) {
					"Pappa is in a meeting. Play with anything you like, but do not touch the fax."
				}
				.style(Styles.status)
			}
			.style(Styles.blotter)
		}
		.style(Styles.desk, GeoCitiesPage.Styles.scriptingOnly)
	}

	enum Parts: String, ElementPartSet {
		case sound
		case status

		// The canvases of the toys.
		case cradle
		case plasma
		case pins
		case bird
		case sand
		case magnet
		case stress
		case spinner
		case perpetual
	}

	enum Hooks: String, ScriptHookSet {
		/**
		A button of a toy, with its ID, like `cradle-one`.
		*/
		case button = "data-desk-button"
	}

	enum Styles: ElementStyleSet {
		case root
		case desk
		case blotter
		case status
		case toys
		case card
		case canvas
		case drags
		case sideDrags
		case taps
		case nameplate
		case caption
		case button

		/**
		A control that gets focus scrolls into view above Pappa’s note, not under it. The status bar of the page is already in the scroll padding of the page, and the note is a bit less than this tall with the longest message on a small phone, where it has 5 lines.
		*/
		private var aboveNote: Length {
			.rootEm(9)
		}

		var style: Style {
			switch self {
			case .root:
				GeoCitiesPage.Styles.section.style
			case .desk:
				// The desk of dark wood at the office, with the grain of the wood across it.
				Style()
					.vstack(spacing: .rootEm(1))
					.padding(.rootEm(0.75))
					.backgroundImage(.linearGradient("100deg", Color("#5a3418"), Color("#6e4220"), Color("#5d361a"), Color("#7a4a26"), Color("#603a1c"), Color("#6a3f1f"), Color("#553117")))
					.border(Color("#3a210e"), width: .pixels(6), style: .ridge)
					.cornerRadius(.rootEm(0.5))
					.shadow(Shadow(x: .pixels(4), y: .pixels(6), color: Color("#00000066")))
					.color(.black)
			case .blotter:
				// The green desk blotter, where the note from Pappa lies. It sticks above the status bar of the page while the desk is on the screen, so the note shows what the toy in use does, even on a phone, where the desk is long. The sound button is not on it, so the note has the whole width and fewer lines on a phone.
				Style()
					.position(.sticky)
					.bottom(.rootEm(2.5))
					.zIndex(1)
					.padding(.rootEm(0.5))
					.background(Color("#2e5a3a"))
					.border(Color("#1a3322"), width: .pixels(3), style: .ridge)
			case .status:
				// A yellow sticky note from Pappa, where the toys say what they do.
				Style()
					.frame(minHeight: .lineHeight(2))
					.margin(0)
					.padding(vertical: .rootEm(0.25), horizontal: .rootEm(0.5))
					.background(Color("#fff68f"))
					.shadow(Shadow(x: .pixels(2), y: .pixels(2), color: Color("#00000059")))
					.fontFamily(GeoCitiesPage.comicSans)
					.textStyle(.caption, weight: .bold)
					.color(.black)
			case .toys:
				Style()
					.grid(minimumColumnWidth: .rootEm(18))
					.gap(.rootEm(1))
			case .card:
				// Each toy stands on its own spot of the desk, with a bit of shadow under it.
				Style()
					.vstack(alignment: .center, spacing: .rootEm(0.5))
					.padding(.rootEm(0.5))
					.background(Color("#00000026"))
					.cornerRadius(.rootEm(0.375))
			case .canvas:
				Style()
					.scrollMargin(bottom: aboveNote)
					.display(.block)
					.frame(width: .percent(100), height: .auto)
					.aspectRatio(4.0 / 3.0)
					.cornerRadius(.rootEm(0.25))
					.textSelection(.disabled)
					.handCursor()
					.focusVisible {
						$0.focusRing(Color("#ffcc00"), width: .pixels(3), offset: .pixels(2))
					}
			case .drags:
				// A drag on a toy plays with it and does not scroll the page.
				Style().touchAction(.none)
			case .sideDrags:
				// The balls of the cradle swing to the sides, so a finger that goes up or down scrolls the page.
				Style().touchAction(.panY)
			case .taps:
				// A toy that only takes taps lets a finger scroll the page over it.
				Style().touchAction(.manipulation)
			case .nameplate:
				// A brass nameplate, engraved, like the one on the door of Pappa. The small size keeps the long names, like Executive Decision Maker, on one short line.
				Style()
					.margin(0)
					.padding(vertical: .rootEm(0.125), horizontal: .rootEm(0.75))
					.backgroundImage(.linearGradient("to bottom", Color("#f6e08a"), Color("#c9a13a"), Color("#a67c1e")))
					.border(Color("#6b4e10"), width: .pixels(2), style: .outset)
					.cornerRadius(.rootEm(0.125))
					.fontFamily(GeoCitiesPage.times)
					.font(.small, weight: .bold)
					.textCase(.uppercase)
					.letterSpacing(.em(0.08))
					.textAlign(.center)
					.color(Color("#3a2a06"))
					.textShadow(Shadow(x: 0, y: .pixels(1), color: Color("#ffffff80")))
			case .caption:
				Style()
					.margin(0)
					.textStyle(.caption)
					.italic()
					.textAlign(.center)
					.color(Color("#f3e6d0"))
			case .button:
				// Big enough for a finger.
				Style()
					.scrollMargin(bottom: aboveNote)
					.frame(minHeight: .rootEm(2.5))
					.touchAction(.manipulation)
			}
		}
	}
}
