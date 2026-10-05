import Elementary
import SiteKit

/**
A Casio keyboard like the SA series of the 1990s, with mini keys that play with the mouse, a finger, or the keys of the computer, a printed list of tones (from Piano to Moo Cow), rhythms with a tempo, the demo song with keys that light up, “Casio Chord”, where one key plays a whole chord with the rhythm, and a memory that records what the visitor plays and plays it back. Its script plays through the sound card of the Music Room.
*/
struct GeoCitiesCasio: ScriptedElement {
	static let script = ElementScript()

	let project: Project

	/**
	The lowest key, as a MIDI note (C4), and the number of keys, two octaves and the top C.
	*/
	static let lowestNote = 60
	static let keyCount = 25

	/**
	The keys of the computer that play the keys, from the lowest, by `KeyboardEvent.code`, with the letter printed on the key. The keys under the white keys play white keys, and the keys of the row above play black keys, like on the keyboards of tracker programs.
	*/
	static let computerKeys = ["A", "W", "S", "E", "D", "F", "T", "G", "Y", "H", "U", "J", "K", "O", "L", "P", ";", "'"]

	/**
	The tones, by their ID in the script, with their number, like on the printed list of a Casio.
	*/
	static let tones: [(id: String, number: String, title: String)] = [
		("piano", "00", "Piano"),
		("vibes", "12", "Vibraphone"),
		("organ", "21", "Organ"),
		("trumpet", "47", "Trumpet"),
		("synth", "63", "Synth Lead"),
		("musicBox", "77", "Music Box"),
		("cow", "99", "Moo Cow"),
	]

	/**
	The rhythms, by their ID in the script.
	*/
	static let rhythms: [(id: String, title: String)] = [
		("rock", "Rock"),
		("disco", "Disco"),
		("samba", "Samba"),
		("waltz", "Waltz"),
		("techno", "Techno"),
		("polka", "Polka"),
	]

	/**
	The white keys, by their index from the lowest key, and whether a black key follows each.
	*/
	private static let whiteKeys: [(index: Int, hasBlackKey: Bool)] = {
		let blackKeyOffsets: Set = [1, 3, 6, 8, 10]
		return (0..<keyCount)
			.filter { !blackKeyOffsets.contains($0 % 12) }
			.map { ($0, blackKeyOffsets.contains(($0 + 1) % 12) && $0 + 1 < keyCount) }
	}()

	var content: some HTML {
		h2 {
			GeoCitiesPage.GIFImage(gif: .crazyPianist, alt: "", style: .floating, project: project)
			"My Casio Keyboard"
		}
		.style(GeoCitiesPage.Styles.heading)

		p {
			"I got it for Christmas! Play it with the mouse, your finger, or the keys A to ’ of your computer (click the keys first). Turn on Casio Chord, and the lowest octave plays a whole chord with one finger, in the rhythm. Or press Demo and pretend you play it."
		}

		div {
			div {
				p {
					"CASIO"
				}
				.style(Styles.brand)

				p {
					"SA-1999 TONE BANK"
				}
				.style(Styles.model)
			}
			.style(Styles.top)

			p(.part(Parts.display)) {
				"00 PIANO"
			}
			.accessibilityHidden()
			.style(GeoCitiesPage.Styles.lcd, Styles.display)

			div {
				div {
					p {
						"TONE"
					}
					.style(Styles.panelTitle)

					for (index, tone) in Self.tones.enumerated() {
						button(.type(.button), .hook(Hooks.tone, value: tone.id), .ariaPressed(index == 0)) {
							"\(tone.number) \(tone.title)"
						}
						.attributes(.hook(.state, value: "on"), when: index == 0)
						.style(Styles.panelButton)
					}
				}
				.style(Styles.panel)

				div {
					p {
						"RHYTHM"
					}
					.style(Styles.panelTitle)

					for (index, rhythm) in Self.rhythms.enumerated() {
						button(.type(.button), .hook(Hooks.rhythm, value: rhythm.id), .ariaPressed(index == 0)) {
							rhythm.title
						}
						.attributes(.hook(.state, value: "on"), when: index == 0)
						.style(Styles.panelButton)
					}
				}
				.style(Styles.panel)
			}
			.style(Styles.panels)

			div {
				button(.part(Parts.start), .type(.button), .ariaPressed(false)) {
					"▶ Start/Stop"
				}
				.style(Styles.control)

				button(.part(Parts.slower), .type(.button)) {
					"Tempo −"
				}
				.style(Styles.control)

				button(.part(Parts.faster), .type(.button)) {
					"Tempo +"
				}
				.style(Styles.control)

				button(.part(Parts.chord), .type(.button), .ariaPressed(false)) {
					"Casio Chord"
				}
				.style(Styles.control)

				button(.part(Parts.demo), .type(.button), .ariaPressed(false)) {
					"♫ Demo"
				}
				.style(Styles.control, Styles.demo)

				button(.part(Parts.record), .type(.button), .ariaPressed(false)) {
					"● Rec"
				}
				.style(Styles.control, Styles.record)

				button(.part(Parts.playback), .type(.button), .disabled) {
					"▶ Play Memory"
				}
				.style(Styles.control)
			}
			.style(Styles.controls)

			keyboard

			div {
				GeoCitiesMusicVolume()
			}
			.style(Styles.volume)

			p(.part(Parts.status), .role("status")) {}
				.style(Styles.status)
		}
		.style(Styles.body, GeoCitiesPage.Styles.scriptingOnly)
	}

	private var keyboard: some HTML {
		div(.part(Parts.keyboard), .tabindex(0), .role("application")) {
			for whiteKey in Self.whiteKeys {
				div {
					Key(index: whiteKey.index, isBlack: false)

					if whiteKey.hasBlackKey {
						Key(index: whiteKey.index + 1, isBlack: true)
					}
				}
				.style(Styles.whiteKeySlot)
			}
		}
		.accessibilityLabel("Keys. Play with the keys A to ’ of the computer.")
		.style(Styles.keyboard)
	}

	enum Parts: String, ElementPartSet {
		case display
		case start
		case slower
		case faster
		case chord
		case demo
		case record
		case playback
		case keyboard
		case status
	}

	enum Hooks: String, ScriptHookSet {
		/**
		A key, by its MIDI note.
		*/
		case note = "data-casio-note"

		/**
		A button of a tone, by its ID.
		*/
		case tone = "data-casio-tone"

		/**
		A button of a rhythm, by its ID.
		*/
		case rhythm = "data-casio-rhythm"
	}

	enum Styles: ElementStyleSet {
		case root
		case body
		case top
		case brand
		case model
		case display
		case panels
		case panel
		case panelTitle
		case panelButton
		case controls
		case control
		case demo
		case record
		case keyboard
		case whiteKeySlot
		case whiteKey
		case blackKey
		case keyLetter
		case volume
		case status

		var style: Style {
			switch self {
			case .root:
				GeoCitiesPage.Styles.section.style
			case .body:
				// The dark gray plastic of a cheap keyboard, with rounded corners.
				Style()
					.vstack(spacing: .rootEm(0.75))
					.padding(.rootEm(1))
					.backgroundImage(.linearGradient("to bottom", Color("#4a4a4f"), Color("#2a2a2e")))
					.border(Color("#18181a"), width: .pixels(3))
					.cornerRadius(.rootEm(1))
					.shadow(Shadow(x: .pixels(4), y: .pixels(6), color: Color("#00000066")))
					.color(.white)
			case .top:
				Style()
					.hstack(alignment: .baseline, spacing: .rootEm(0.75))
					.flexWrap()
			case .brand:
				Style()
					.fontFamily(.system)
					.font(.extraLarge2, weight: .heavy)
					.letterSpacing(.em(0.15))
					.color(Color("#e8e8e8"))
			case .model:
				Style()
					.fontFamily(.system)
					.textStyle(.caption, weight: .bold)
					.color(Color("#ff9933"))
			case .display:
				Style()
					.frame(minHeight: .lineHeight(1))
					.textCase(.uppercase)
			case .panels:
				Style()
					.grid(minimumColumnWidth: .rootEm(14))
					.gap(.rootEm(0.75))
			case .panel:
				// The printed list of a Casio, with white text on the dark plastic.
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.25))
					.flexWrap()
					.padding(.rootEm(0.5))
					.border(Color("#88888c"), width: .pixels(1))
			case .panelTitle:
				Style()
					.frame(width: .percent(100))
					.fontFamily(.system)
					.textStyle(.caption, weight: .heavy)
					.color(Color("#ff9933"))
			case .panelButton:
				// A small rubber button that lights up orange while it is chosen.
				Style()
					.padding(vertical: .rootEm(0.125), horizontal: .rootEm(0.375))
					.background(Color("#1a1a1c"))
					.border(Color("#666"), width: .pixels(1))
					.cornerRadius(.rootEm(0.25))
					.fontFamily(.system)
					.textStyle(.caption)
					.color(.white)
					.handCursor()
					.when(.state, is: "on") {
						$0
							.background(Color("#ff9933"))
							.color(.black)
					}
			case .controls:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.375))
					.flexWrap()
			case .control:
				Style()
					.padding(vertical: .rootEm(0.25), horizontal: .rootEm(0.625))
					.background(Color("#d8d8d8"))
					.border(Color("#555"), width: .pixels(2), style: .outset)
					.cornerRadius(.rootEm(0.375))
					.fontFamily(.system)
					.textStyle(.caption, weight: .bold)
					.color(.black)
					.handCursor()
					.active {
						$0.border(Color("#555"), width: .pixels(2), style: .inset)
					}
					.when(.state, is: "on") {
						$0.background(Color("#ffcc33"))
					}
					.disabled {
						$0
							.color(Color("#808080"))
							.cursor(GeoCitiesPage.arrowCursor, fallback: .default)
					}
			case .demo:
				Style().background(Color("#66ccff"))
			case .record:
				Style()
					.color(Color("#cc0000"))
					.when(.state, is: "on") {
						$0
							.background(Color("#ff3333"))
							.color(.white)
					}
			case .keyboard:
				// The mini keys in a row. The keyboard keeps a focus ring, as the keys of the computer only play while it has the focus.
				Style()
					.hstack()
					.frame(height: .rootEm(8))
					.padding(.pixels(4))
					.background(.black)
					.cornerRadius(.rootEm(0.25))
					.touchAction(.none)
					.focusVisible {
						$0.focusRing(Color("#ff9933"), width: .pixels(3), offset: .pixels(2))
					}
			case .whiteKeySlot:
				// A white key, with the black key to its right on top of it.
				Style()
					.position(.relative)
					.flex(1)
					.frame(minWidth: 0)
			case .whiteKey:
				Style()
					.vstack(alignment: .center, justification: .end)
					.frame(width: .percent(100), height: .percent(100))
					.padding(.bottom, .rootEm(0.25))
					.background(Color("#fafafa"))
					.border(Color("#999"), width: .pixels(1))
					.cornerRadius(.pixels(3))
					.color(Color("#999"))
					.handCursor()
					.when(.state, is: "lit") {
						$0.background(Color("#ffcc66"))
					}
			case .blackKey:
				// Narrower and shorter, between this white key and the next.
				Style()
					.position(.absolute)
					.top(0)
					.trailing(.percent(-30))
					.zIndex(1)
					.vstack(alignment: .center, justification: .end)
					.frame(width: .percent(60), height: .percent(60))
					.padding(.bottom, .rootEm(0.125))
					.background(Color("#111"))
					.border(Color("#000"), width: .pixels(1))
					.cornerRadius(.pixels(2))
					.color(Color("#bbb"))
					.handCursor()
					.when(.state, is: "lit") {
						$0.background(Color("#ff9933"))
					}
			case .keyLetter:
				Style()
					.fontFamily(.system)
					.font(size: .rootEm(0.625))
					.allowsHitTesting(false)
			case .volume:
				Style().hstack(alignment: .center, justification: .end)
			case .status:
				Style()
					.frame(minHeight: .lineHeight(1))
					.fontFamily(.system)
					.textStyle(.caption)
			}
		}
	}
}

extension GeoCitiesCasio {
	/**
	A key of the keyboard, with the letter of the computer key that plays it.
	*/
	private struct Key: HTML {
		let index: Int
		let isBlack: Bool

		var body: some HTML {
			let note = GeoCitiesCasio.lowestNote + index
			let names = ["C", "C♯", "D", "D♯", "E", "F", "F♯", "G", "G♯", "A", "A♯", "B"]
			let letter = index < GeoCitiesCasio.computerKeys.count ? GeoCitiesCasio.computerKeys[index] : ""

			return button(.type(.button), .tabindex(-1), .hook(Hooks.note, value: "\(note)")) {
				span {
					letter
				}
				.accessibilityHidden()
				.style(Styles.keyLetter)
			}
			.accessibilityLabel("\(names[note % 12])\(note / 12 - 1)")
			.style(isBlack ? Styles.blackKey : Styles.whiteKey)
		}
	}
}
