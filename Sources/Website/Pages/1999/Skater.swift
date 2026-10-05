import Elementary
import Foundation
import SiteKit

/**
Sindre Hawk’s Pro Skater, a skateboarding game like Tony Hawk’s Pro Skater by Neversoft (September 1999), seen from the side, in a level of Bergen: a half-pipe in the parking garage Bygarasjen with a ramp down to the street, a rail and a granite ledge along Bryggen, a gap over the water of Vågen, the stair set and the handrail of the fish market, Mormor on her bench, the rain puddles, and a quarter pipe at the end. The visitor pushes, ollies higher the longer the button is held, spins 180s, 360s, and 540s, does flip tricks and grab tricks by a direction and a button like on the PlayStation, grinds rails and ledges and manuals with a balance meter, and links it all in combos with a multiplier and the string of the tricks. A landing that is not straight, or still in a trick, is a bail, with a ragdoll fall, a crunch, and a plaster from Mamma. The special meter fills with tricks and unlocks the special tricks, like The 900 and The Brunost Flip. A run lasts two minutes, with the letters S, K, A, T, and E to collect, a secret tape, and nine named gaps with their message, and the high score, the best combo, and the gaps found are kept in the browser. A punk rock soundtrack of distorted power chords, bass, and drums plays after the visitor turns the music on, and buttons below the screen play it on a phone. With reduced motion, the run only moves while a button is held. Its script, `Skater.js`, runs it on one canvas, only while it is on the screen and the tab is visible.
*/
struct GeoCitiesSkater: ScriptedElement {
	static let script = ElementScript()

	let project: Project

	/**
	A named gap of the level, with the ID that `Skater.js` knows it by.
	*/
	struct Gap {
		let id: String
		let name: String
		let points: Int

		/**
		Where the gap is and how to get it, so the visitor knows what to try.
		*/
		let hint: String
	}

	/**
	The gaps of the level, from the garage to the fish market.
	*/
	static let gaps = [
		Gap(id: "transfer", name: "Plan 2 Transfer", points: 250, hint: "Air out of the half-pipe and land on a deck, by holding ▲ in a vert air."),
		Gap(id: "big-air", name: "Bygarasjen Big Air", points: 300, hint: "Fly higher than two of me above the coping of the half-pipe."),
		Gap(id: "garage-ramp", name: "Garage Ramp Gap", points: 200, hint: "Ollie off the deck and clear the whole ramp down to the street."),
		Gap(id: "bryggen-rail", name: "Hanseatic Rail", points: 200, hint: "Grind the rail along Bryggen from one end to the other."),
		Gap(id: "bryggen", name: "Bryggen Gap", points: 500, hint: "Jump the fish crates and clear the water of Vågen."),
		Gap(id: "stairs", name: "Fish Market Stair Set", points: 300, hint: "Ollie the whole stair set down to the fish market."),
		Gap(id: "handrail", name: "Fish Market Handrail", points: 400, hint: "Grind the handrail of the stairs all the way down."),
		Gap(id: "mormor", name: "Over Mormor", points: 350, hint: "Jump over Mormor on her bench. She knits, so do not hit her."),
		Gap(id: "puddle", name: "Bergen Puddle Gap", points: 100, hint: "Ollie over a rain puddle without a splash. It always rains in Bergen."),
	]

	var content: some HTML {
		h2 {
			GeoCitiesPage.GIFImage(gif: .cool, alt: "", style: .gif, project: project)
			" Sindre Hawk’s Pro Skater "
			GeoCitiesPage.GIFImage(gif: .cool, alt: "", style: .gif, project: project)
		}
		.style(GeoCitiesPage.Styles.heading, GeoCitiesPage.Styles.centeredText)

		p {
			"Tony Hawk’s Pro Skater came out in September, and Trond and I have played nothing else since (Mamma says the PlayStation will melt). So I made my own, in Bergen! Drop into the half-pipe in the parking garage, grind along Bryggen, jump the water, and ollie over Mormor at the fish market. You have two minutes. Find the S‑K‑A‑T‑E letters, the secret tape, and all the gaps. In real life I can only ollie a curb, but here I can do The 900."
		}
		.style(GeoCitiesPage.Styles.centeredText)

		div {
			div {
				"SHPS.EXE"
			}
			.style(GeoCitiesPage.Styles.titleBar)

			div {
				console
				GeoCitiesPage.Deferred(info)
				GeoCitiesPage.Deferred(howTo)
			}
			.style(Styles.body)
		}
		.style(GeoCitiesPage.Styles.window, GeoCitiesPage.Styles.scriptingOnly)

		p {
			"Sindre Hawk’s Pro Skater needs JavaScript. Grab a real board and go outside (bring a raincoat)."
		}
		.style(GeoCitiesPage.Styles.scriptingDisabledOnly)
	}

	/**
	The screen in a dark frame, the line of the tricks below it, the buttons for touch screens, and the buttons of the run.
	*/
	private var console: some HTML {
		div {
			div {
				// The screen is 400 × 240 pixels, made bigger with sharp pixels, like a game of the PlayStation on a TV.
				canvas(.part(Parts.screen), .width(400), .height(240), .tabindex(0), .role("application")) {}
					.accessibilityLabel("The screen of Sindre Hawk’s Pro Skater. The left and right arrows push and spin, Space ollies (hold it to jump higher), Z flips, X grabs, C grinds, and V does a special trick when the meter is full. Up and then down starts a manual. Enter or a click starts a run.")
					.style(Styles.screen)
			}
			.style(Styles.bezel)

			p(.part(Parts.status), .role("status")) {
				"Click the screen or ▶ Start for a 2‑minute run. Free Skate has no clock."
			}
			.style(Styles.status)

			GeoCitiesPage.Deferred(pad)

			div {
				button(.part(Parts.start), .type(.button)) {
					"▶ Start 2-Minute Run"
				}
				.style(GeoCitiesPage.Styles.retroButton)

				button(.part(Parts.freeSkate), .type(.button)) {
					"Free Skate"
				}
				.style(GeoCitiesPage.Styles.smallButton)
			}
			.style(GeoCitiesPage.Styles.buttonRow)

			div {
				button(.part(Parts.sound), .type(.button), .ariaPressed(false)) {
					"🔇 Sound Off"
				}
				.style(GeoCitiesPage.Styles.smallButton)

				button(.part(Parts.music), .type(.button), .ariaPressed(false)) {
					"🎸 Music Off"
				}
				.style(GeoCitiesPage.Styles.smallButton)

				button(.part(Parts.track), .type(.button)) {
					"⏭ Next Song"
				}
				.style(GeoCitiesPage.Styles.smallButton)

				button(.part(Parts.step), .type(.button), .ariaPressed(false)) {
					"Step Mode Off"
				}
				.help("The run only moves while you hold a button")
				.style(GeoCitiesPage.Styles.smallButton)
			}
			.style(GeoCitiesPage.Styles.buttonRow)

			p(.part(Parts.nowPlaying)) {
				"♪ STEREO: OFF"
			}
			.style(GeoCitiesPage.Styles.lcd, Styles.nowPlaying)
		}
		.style(Styles.console)
	}

	/**
	The buttons for touch screens: the arrows on the left and the trick buttons on the right, like the controller of the PlayStation. The keyboard uses the keys on the screen instead, so the buttons are not in the order of the Tab key.
	*/
	private var pad: some HTML {
		div {
			div {
				for row in [[("up", "Up", "▲")], [("left", "Left", "◀"), ("right", "Right", "▶")], [("down", "Down", "▼")]] {
					div {
						for (control, label, symbol) in row {
							button(.type(.button), .tabindex(-1), .hook(Hooks.control, value: control)) {
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

			// The four buttons of the PlayStation, in a diamond: Grind on top, Flip on the left, Grab on the right, and Ollie at the bottom.
			div {
				div {
					trickButton("grind", label: "Grind", symbol: "▲", style: .grindButton)
				}
				.style(Styles.trickRow)

				div {
					trickButton("flip", label: "Flip", symbol: "■", style: .flipButton)
					trickButton("grab", label: "Grab", symbol: "●", style: .grabButton)
				}
				.style(Styles.trickRow)

				div {
					trickButton("ollie", label: "Ollie", symbol: "✕", style: .ollieButton)
				}
				.style(Styles.trickRow)
			}
			.style(Styles.trickButtons)

			button(.type(.button), .tabindex(-1), .hook(Hooks.control, value: "special")) {
				"★ Special"
			}
			.style(Styles.specialButton)
		}
		.style(Styles.controls)
	}

	private func trickButton(_ control: String, label: String, symbol: String, style: Styles) -> some HTML {
		button(.type(.button), .tabindex(-1), .hook(Hooks.control, value: control)) {
			span {
				symbol
			}
			.style(Styles.trickSymbol)

			span {
				label
			}
			.style(Styles.trickLabel)
		}
		.style(Styles.trickButton, style)
	}

	/**
	The records and the gap checklist, side by side when they fit. How to play is below them with the whole width, as its long descriptions need it.
	*/
	private var info: some HTML {
		div {
			records
			checklist
		}
		.style(Styles.info)
	}

	private var records: some HTML {
		div {
			h3 {
				"My Records"
			}
			.style(GeoCitiesPage.Styles.subheading)

			dl {
				dt {
					"High score"
				}
				.style(Styles.recordLabel)

				dd(.part(Parts.highScore)) {
					"0"
				}
				.style(Styles.recordValue)

				dt {
					"Best combo"
				}
				.style(Styles.recordLabel)

				dd(.part(Parts.bestCombo)) {
					"None yet"
				}
				.style(Styles.recordValue)

				dt {
					"Last run"
				}
				.style(Styles.recordLabel)

				dd(.part(Parts.lastRun)) {
					"Not yet"
				}
				.style(Styles.recordValue)
			}
			.style(Styles.recordList)

			div {
				button(.part(Parts.clear), .type(.button)) {
					"Clear My Records"
				}
				.style(GeoCitiesPage.Styles.smallButton)
			}
			.style(GeoCitiesPage.Styles.buttonRow)
		}
		.style(Styles.panel)
	}

	private var checklist: some HTML {
		div {
			h3 {
				"Gap Checklist "
				span(.part(Parts.gapCount)) {
					"0/\(Self.gaps.count)"
				}
			}
			.style(GeoCitiesPage.Styles.subheading)

			ul {
				for gap in Self.gaps {
					li(.hook(Hooks.gap, value: gap.id)) {
						// The box is checked when the gap is found, which screen readers also say.
						span {
							"☐"
						}
						.style(Styles.gapMark)

						span {
							strong {
								"\(gap.name) (\(gap.points))"
							}

							" \(gap.hint)"
						}
					}
					.style(Styles.gap)
				}
			}
			.style(Styles.gapList)
		}
		.style(Styles.panel)
	}

	private var howTo: some HTML {
		div {
			h3 {
				"How to Skate"
			}
			.style(GeoCitiesPage.Styles.subheading)

			dl {
				for (keys, action) in Self.controls {
					dt {
						keys
					}
					.style(Styles.key)

					dd {
						action
					}
					.style(Styles.keyAction)
				}
			}
			.style(Styles.keys)
		}
		.style(Styles.panel)
	}

	/**
	The keys and what they do. The touch buttons below the screen do the same.
	*/
	private static let controls: [(keys: String, action: String)] = [
		("◀ ▶ arrows", "Push, brake, and turn on the ground. Spin in the air (hold for a 360 or a 540)."),
		("Space (Ollie)", "Ollie. Hold it longer to jump higher."),
		("Z (Flip) + arrow", "Flip trick: Kickflip, Heelflip (◀), Pop Shove-It (▶), Impossible (▲), or Varial Kickflip (▼)."),
		("X (Grab) + arrow", "Grab trick: Indy, Melon (◀), Method (▶), Nosegrab (▲), or Tailgrab (▼). Hold it for more points."),
		("C (Grind) + arrow", "Grind a rail or a ledge below you: 50-50, Boardslide (◀), Crooked (▶), Nosegrind (▲), or 5-0 (▼). Keep the balance with the left and right arrows."),
		("▲ arrow in a vert air", "Air out of the half-pipe onto the deck."),
		("▲ then ▼ arrows", "Manual (down, then up for a nose manual), also just before you land, to link the combo. Keep the balance with the up and down arrows."),
		("V (★ Special)", "A special trick when the meter is full: The 900 in a big air, The Brunost Flip in a small one, the Vaffel Grind on a rail, and the Rocky Manual on the ground."),
	]

	enum Parts: String, ElementPartSet {
		case screen
		case status
		case start
		case freeSkate
		case sound
		case music
		case track
		case step
		case nowPlaying
		case highScore
		case bestCombo
		case lastRun
		case clear
		case gapCount
	}

	enum Hooks: String, ScriptHookSet {
		/**
		The control of a touch button, like `left` or `ollie`.
		*/
		case control = "data-skater-control"

		/**
		The gap of an item of the checklist, like `mormor`.
		*/
		case gap = "data-skater-gap"
	}

	enum Styles: ElementStyleSet {
		case root
		case body
		case console
		case bezel
		case screen
		case status
		case controls
		case pad
		case padRow
		case padButton
		case trickButtons
		case trickRow
		case trickButton
		case trickSymbol
		case trickLabel
		case ollieButton
		case flipButton
		case grabButton
		case grindButton
		case specialButton
		case nowPlaying
		case info
		case panel
		case recordList
		case recordLabel
		case recordValue
		case gapList
		case gap
		case gapMark
		case keys
		case key
		case keyAction

		var style: Style {
			switch self {
			case .root:
				GeoCitiesPage.Styles.section.style
			case .body:
				Style()
					.vstack(spacing: .rootEm(0.75))
					.padding(.rootEm(0.75))
					.below(.smallTablet) {
						$0.padding(.rootEm(0.375))
					}
			case .console:
				// A gray PlayStation under a TV.
				Style()
					.vstack(alignment: .center, spacing: .rootEm(0.5))
					.padding(.rootEm(0.75))
					.below(.smallTablet) {
						$0.padding(.rootEm(0.375))
					}
					.background(Color("#2b2b33"))
					.border(Color("#5a5a66"), width: .pixels(3), style: .outset)
					.cornerRadius(.rootEm(0.5))
			case .bezel:
				Style()
					.frame(width: .percent(100), maxWidth: .pixels(800))
					.padding(.rootEm(0.5))
					.below(.smallTablet) {
						$0.padding(.rootEm(0.25))
					}
					.background(.black)
					.border(Color("#444444"), width: .pixels(3), style: .inset)
					.cornerRadius(.rootEm(0.75))
			case .screen:
				// A finger on the screen does not zoom or scroll by a double tap, as the game is played with the buttons below it.
				Style()
					.display(.block)
					.frame(width: .percent(100), height: .auto)
					.aspectRatio(400.0 / 240.0)
					.imageRendering(.pixelated)
					.background(.black)
					.touchAction(.manipulation)
					.focusVisible {
						$0.focusRing(Color("#ffdd00"), width: .pixels(2), offset: .pixels(2))
					}
			case .status:
				// Two lines high, so the console does not grow when a combo is longer.
				Style()
					.frame(width: .percent(100), minHeight: .lineHeight(2))
					.margin(0)
					.fontFamily(GeoCitiesPage.courier)
					.textStyle(.caption, weight: .bold)
					.lineHeight(1.2)
					.textAlign(.center)
					.color(Color("#ffdd00"))
			case .controls:
				Style()
					.hstack(alignment: .center, justification: .center, spacing: .rootEm(1.5))
					.flexWrap()
					.textSelection(.disabled)
					.below(.smallTablet) {
						$0.gap(.rootEm(0.75))
					}
			case .pad:
				Style().vstack(alignment: .center, spacing: .rootEm(0.25))
			case .padRow:
				// Left and right have the width of a button between them.
				Style().hstack(alignment: .center, justification: .center, spacing: .rootEm(3))
			case .padButton:
				Style()
					.frame(width: .rootEm(3), height: .rootEm(3))
					.background(Color("#6a6a74"))
					.border(Color("#9a9aa4"), width: .pixels(3), style: .outset)
					.cornerRadius(.rootEm(0.5))
					.fontFamily(.system)
					.font(.large, weight: .bold)
					.color(.white)
					.touchAction(.none)
					.handCursor()
					.active {
						$0.border(Color("#9a9aa4"), width: .pixels(3), style: .inset)
					}
			case .trickButtons:
				Style().vstack(alignment: .center, spacing: 0)
			case .trickRow:
				// Flip and Grab have the width of a button between them.
				Style().hstack(alignment: .center, justification: .center, spacing: .rootEm(3.25))
			case .trickButton:
				Style()
					.vstack(alignment: .center, justification: .center, spacing: 0)
					.frame(width: .rootEm(3.25), height: .rootEm(3.25))
					.background(Color("#3a3a44"))
					.border(Color("#77778a"), width: .pixels(3), style: .outset)
					.cornerRadius(.percent(50))
					.fontFamily(.system)
					.color(.white)
					.touchAction(.none)
					.handCursor()
					.active {
						$0.border(Color("#77778a"), width: .pixels(3), style: .inset)
					}
			case .trickSymbol:
				Style()
					.font(.large, weight: .bold)
					.lineHeight(1)
			case .trickLabel:
				Style()
					.textStyle(.caption, weight: .bold)
					.lineHeight(1)
			case .ollieButton:
				Style().color(Color("#9ab8ff"))
			case .flipButton:
				Style().color(Color("#ff9ad8"))
			case .grabButton:
				Style().color(Color("#ff7a6a"))
			case .grindButton:
				Style().color(Color("#7aee9a"))
			case .specialButton:
				Style()
					.frame(minHeight: .rootEm(3))
					.padding(.horizontal, .rootEm(0.75))
					.background(Color("#cc8800"))
					.border(Color("#ffcc55"), width: .pixels(3), style: .outset)
					.cornerRadius(.rootEm(1.5))
					.fontFamily(GeoCitiesPage.impact)
					.textStyle(.body)
					.color(.white)
					.touchAction(.none)
					.handCursor()
					.active {
						$0.border(Color("#ffcc55"), width: .pixels(3), style: .inset)
					}
			case .nowPlaying:
				Style()
					.frame(width: .percent(100))
					.margin(0)
					.textStyle(.caption, weight: .bold)
					.textAlign(.center)
			case .info:
				Style()
					.grid(minimumColumnWidth: .rootEm(16))
					.gap(.rootEm(0.75))
			case .panel:
				Style()
					.flowSpacing(.rootEm(0.5))
					.padding(.rootEm(0.5))
					.background(Color("#ffffff"))
					.border(Color("#808080"), width: .pixels(2), style: .inset)
			case .recordList:
				Style()
					.grid(columns: "auto 1fr")
					.gap(row: .rootEm(0.25), column: .rootEm(0.75))
					.margin(0)
			case .recordLabel:
				Style().fontWeight(.bold)
			case .recordValue:
				Style()
					.margin(0)
					.fontFamily(GeoCitiesPage.courier)
			case .gapList:
				Style()
					.vstack(spacing: .rootEm(0.25))
					.margin(0)
					.padding(0)
					.textStyle(.caption)
			case .gap:
				Style()
					.hstack(alignment: .start, spacing: .rootEm(0.375))
					.color(Color("#666666"))
					.when(.state, is: "found") {
						$0.color(Color("#006600"))
					}
			case .gapMark:
				Style()
					.fontWeight(.bold)
					.color(.black)
			case .keys:
				// On a phone, each key is above what it does, so the descriptions get the whole width instead of a narrow column.
				Style()
					.grid(columns: "auto 1fr")
					.gap(row: .rootEm(0.25), column: .rootEm(0.75))
					.margin(0)
					.textStyle(.caption)
					.below(.smallTablet) {
						$0
							.gridColumns(1)
							.gap(row: 0)
					}
			case .key:
				Style()
					.fontFamily(GeoCitiesPage.courier)
					.fontWeight(.bold)
			case .keyAction:
				Style()
					.margin(0)
					.below(.smallTablet) {
						$0.margin(.bottom, .rootEm(0.5))
					}
			}
		}
	}
}
