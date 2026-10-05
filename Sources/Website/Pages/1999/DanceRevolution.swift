import Elementary
import Foundation
import SiteKit

/**
Dans Dans Revolusjon, my own Dance Dance Revolution, after the machine from Japan that I saw in the arcade of the ferry to Denmark in the summer of 1999. The cabinet has a big screen, and the dance pad is on the floor under it, next to the menu of the machine. On the screen, which its script, `DanceRevolution.js`, draws on a canvas, the arrows scroll up to the four target arrows in time with three Eurodance songs of my own that the browser plays: “Plastikk-Prinsesse” (126 BPM), “Sommerfugl” (138 BPM), and “Regnværs-Rave” (155 BPM), each with a key change at the last chorus. The step charts are made from the beat and the tune of each song, for three difficulties (Basic, Trick, and Maniac, with a rating in feet), with the colors of the real arrows (red on the beat, blue between, yellow for the fast ones), jumps of two arrows, and green freeze arrows to hold. Each step gets a judgment by the audio clock (Perfect, Great, Good, Boo, or Miss), the combo counts up in big numbers, the Dance Gauge fills and drains and fails the song when it is empty, and the end shows the grade from AAA to E, with the announcer of the arcade saying “Here we go!”, “Woo!”, and “Boo!”. A pixel dancer (me, Mormor, or Rocky the pet rock) dances next to the arrows, better with a bigger combo. The pad under the screen lights up on each step, and on a phone, it is the four big buttons to dance on. The visitor plays with the arrow keys or WASD, picks the speed of the arrows, calibrates the delay of the sound by stepping to a beat, watches Trond play for a demonstration, and pays 10 kroner for three stages, which the page counts. The best score of each song and difficulty is kept in the browser. With reduced motion, the background does not pulse, and the still mode, which is on, lights the arrows up in place at their time instead of scrolling them. Without scripts, the cabinet is left out, as nothing in it works without them.
*/
struct GeoCitiesDanceRevolution: ScriptedElement {
	static let script = ElementScript()

	/**
	The songs of the machine. `DanceRevolution.js` has the tunes, with the same IDs.
	*/
	private static let songs: [(id: String, title: String, artist: String, bpm: Int)] = [
		("prinsesse", "Plastikk-Prinsesse", "Vannmelon", 126),
		("sommerfugl", "Sommerfugl", "Smilefjes", 138),
		("regn", "Regnværs-Rave", "DJ Paraply", 155),
	]

	private static let difficulties: [(id: String, name: String)] = [
		("basic", "Basic"),
		("trick", "Trick"),
		("maniac", "Maniac"),
	]

	private static let dancers: [(id: String, emoji: String, name: String)] = [
		("sindre", "🧢", "Me"),
		("mormor", "👵", "Mormor"),
		("rocky", "🪨", "Rocky"),
	]

	/**
	A click on the text or the steel of the machine gives it the focus, so the keys still step while a song plays.
	*/
	var rootAttributes: [HTMLAttribute<ElementTag<Self>>] {
		[.tabindex(-1)]
	}

	var content: some HTML {
		h2 {
			"Dans Dans Revolusjon"
		}
		.style(GeoCitiesPage.Styles.heading, GeoCitiesPage.Styles.centeredText)

		p {
			"This summer, on the ferry to Denmark, the arcade had a machine from Japan called Dance Dance Revolution. You dance on arrows on the floor! Nobody in Bergen has one, so Trond and I spent all our ferry money on it, and Pappa had to buy the waffles. Now I made my own. Step on the arrows when they reach the top: the arrow keys or WASD, or the pads on a phone."
		}

		div {
			GeoCitiesPage.Deferred(cabinet)

			div {
				GeoCitiesPage.Deferred(platform)

				GeoCitiesPage.Deferred(controls)
			}
			.style(Styles.console)
		}
		.style(Styles.machine, GeoCitiesPage.Styles.scriptingOnly)

		p {
			"The dance machine needs JavaScript. And 10 kroner."
		}
		.style(GeoCitiesPage.Styles.scriptingDisabledOnly)
	}

	private var cabinet: some HTML {
		div {
			p {
				"Dans Dans Revolusjon"
			}
			.accessibilityHidden()
			.style(Styles.marquee)

			canvas(.part(Parts.screen), .width(320), .height(240), .tabindex(0), .role("application")) {}
				.accessibilityLabel("The screen of the dance machine. Press Enter to start. Step with the arrow keys or with W, A, S, and D when the arrows reach the target arrows at the top.")
				.style(Styles.screen)
		}
		.style(Styles.cabinet)
	}

	private var platform: some HTML {
		div {
			pad

			p {
				"Step on the arrows with a finger or the mouse, or with the keys. Two at once is a jump."
			}
			.style(GeoCitiesPage.Styles.caption, GeoCitiesPage.Styles.centeredText)
		}
		.style(Styles.platform)
	}

	private var pad: some HTML {
		div(.role("group")) {
			plate
			arrow("▲", lane: 2, name: "Up")
			plate
			arrow("◀", lane: 0, name: "Left")
			plate
			arrow("▶", lane: 3, name: "Right")
			plate
			arrow("▼", lane: 1, name: "Down")
			plate
		}
		.accessibilityLabel("The dance pad")
		.style(Styles.pad)
	}

	private var plate: some HTML {
		span {}
			.accessibilityHidden()
			.style(Styles.plate)
	}

	private func arrow(_ symbol: String, lane: Int, name: String) -> some HTML {
		button(.type(.button), .hook(Hooks.lane, value: "\(lane)")) {
			symbol
		}
		.accessibilityLabel(name)
		.style(Styles.padArrow)
	}

	private var controls: some HTML {
		section(.tabindex(-1)) {
			h3 {
				"Select Music"
			}
			.style(GeoCitiesPage.Styles.titleBar)

			div {
				songChoices
				difficultyChoices
				dancerChoices
				buttons
				calibration

				p(.part(Parts.status), .role("status")) {
					"Pick a song, and insert a coin."
				}
				.style(Styles.status)

				p(.part(Parts.coins)) {
					"Spent: 0 kr"
				}
				.style(GeoCitiesPage.Styles.lcd, Styles.coins)
			}
			.style(GeoCitiesPage.Styles.windowBody, Styles.stack)
		}
		.style(GeoCitiesPage.Styles.window, Styles.window)
	}

	private var songChoices: some HTML {
		fieldset {
			legend {
				"Song:"
			}
			.style(GeoCitiesPage.Styles.label)

			div {
				for song in Self.songs {
					button(.type(.button), .hook(Hooks.song, value: song.id), .ariaPressed(false)) {
						span {
							song.title
						}
						.style(Styles.choiceTitle)

						span {
							"\(song.artist) · \(song.bpm) BPM"
						}
						.style(Styles.choiceDetail)

						span(.hook(Hooks.best, value: song.id)) {
							"No record yet"
						}
						.style(Styles.choiceDetail)
					}
					.style(Styles.choice)
				}
			}
			.style(Styles.songs)
		}
		.style(Styles.fieldset)
	}

	private var difficultyChoices: some HTML {
		fieldset {
			legend {
				"Difficulty:"
			}
			.style(GeoCitiesPage.Styles.label)

			div {
				for difficulty in Self.difficulties {
					button(.type(.button), .hook(Hooks.difficulty, value: difficulty.id), .ariaPressed(false)) {
						span {
							difficulty.name
						}
						.style(Styles.choiceTitle)

						span(.hook(Hooks.feet, value: difficulty.id)) {}
							.style(Styles.choiceDetail)
					}
					.style(Styles.choice)
				}
			}
			.style(Styles.triple)
		}
		.style(Styles.fieldset)
	}

	private var dancerChoices: some HTML {
		fieldset {
			legend {
				"Dancer:"
			}
			.style(GeoCitiesPage.Styles.label)

			div {
				for dancer in Self.dancers {
					button(.type(.button), .hook(Hooks.dancer, value: dancer.id), .ariaPressed(false)) {
						span {
							dancer.emoji
						}
						.accessibilityHidden()

						span {
							dancer.name
						}
						.style(Styles.choiceTitle)
					}
					.style(Styles.choice, Styles.dancerChoice)
				}
			}
			.style(Styles.triple)
		}
		.style(Styles.fieldset)
	}

	private var buttons: some HTML {
		div {
			button(.part(Parts.start), .type(.button)) {
				"🪙 Insert 10 kr and Dance (Sound!)"
			}
			.style(GeoCitiesPage.Styles.retroButton)

			button(.part(Parts.demo), .type(.button)) {
				"👀 Watch Trond Play (Sound!)"
			}
			.style(GeoCitiesPage.Styles.smallButton)

			button(.part(Parts.speed), .type(.button)) {
				"Speed: ×1.5"
			}
			.style(GeoCitiesPage.Styles.smallButton)

			button(.part(Parts.still), .type(.button), .ariaPressed(false)) {
				"Still Mode"
			}
			.style(GeoCitiesPage.Styles.smallButton, Styles.toggle)

			button(.part(Parts.announcer), .type(.button), .ariaPressed(true)) {
				"🗣 Announcer"
			}
			.style(GeoCitiesPage.Styles.smallButton, Styles.toggle)
		}
		.style(GeoCitiesPage.Styles.buttonRow)
	}

	private var calibration: some HTML {
		div {
			button(.part(Parts.calibrate), .type(.button)) {
				"⏱ Calibrate the Delay (Sound!)"
			}
			.style(GeoCitiesPage.Styles.smallButton)

			// The delay is between its two buttons, and they wrap as one, so −10 ms and +10 ms stay on each side of it.
			div {
				button(.part(Parts.earlier), .type(.button)) {
					"−10 ms"
				}
				.accessibilityLabel("Make the delay 10 milliseconds shorter")
				.style(GeoCitiesPage.Styles.smallButton)

				output(.part(Parts.delay)) {
					"Delay: 0 ms"
				}
				.style(GeoCitiesPage.Styles.lcd, Styles.delay)

				button(.part(Parts.later), .type(.button)) {
					"+10 ms"
				}
				.accessibilityLabel("Make the delay 10 milliseconds longer")
				.style(GeoCitiesPage.Styles.smallButton)
			}
			.style(GeoCitiesPage.Styles.buttonRow)
		}
		.style(GeoCitiesPage.Styles.buttonRow, Styles.calibration)
	}

	enum Parts: String, ElementPartSet {
		case screen
		case start
		case demo
		case speed
		case still
		case announcer
		case calibrate
		case earlier
		case later
		case delay
		case status
		case coins
	}

	enum Hooks: String, ScriptHookSet {
		/**
		An arrow of the dance pad, with its lane: `0` for left, `1` for down, `2` for up, and `3` for right, like on the screen.
		*/
		case lane = "data-ddr-lane"

		/**
		A button that picks a song, with the ID of the song.
		*/
		case song = "data-ddr-song"

		/**
		The best grade and score of a song, which the script writes, with the ID of the song.
		*/
		case best = "data-ddr-best"

		/**
		A button that picks a difficulty: `basic`, `trick`, or `maniac`.
		*/
		case difficulty = "data-ddr-difficulty"

		/**
		The rating in feet of a difficulty for the picked song, which the script writes.
		*/
		case feet = "data-ddr-feet"

		/**
		A button that picks the dancer: `sindre`, `mormor`, or `rocky`.
		*/
		case dancer = "data-ddr-dancer"
	}

	enum Styles: ElementStyleSet {
		case root
		case machine
		case console
		case platform
		case cabinet
		case marquee
		case screen
		case pad
		case plate
		case padArrow
		case window
		case stack
		case fieldset
		case songs
		case triple
		case choice
		case dancerChoice
		case choiceTitle
		case choiceDetail
		case toggle
		case calibration
		case delay
		case status
		case coins

		/**
		The steel of the dance pad.
		*/
		private static let steel = Color("#8a8f98")

		var style: Style {
			switch self {
			case .root:
				GeoCitiesPage.Styles.section.style
			case .machine:
				Style().vstack(spacing: .rootEm(1.25))
			case .console:
				// The pad and the menu side by side under the screen on a wide screen, and the menu under the pad on a phone.
				Style()
					.grid(columns: 1)
					.gap(.rootEm(1.25))
					.alignItems(.start)
					.children("*") {
						$0.frame(minWidth: 0)
					}
					.from(.tablet) {
						$0.grid(columns: "minmax(0, 2fr) minmax(0, 3fr)")
					}
			case .platform:
				// The floor in front of the machine, with the pad on it.
				Style()
					.vstack(spacing: .rootEm(0.5))
					.padding(.rootEm(0.625))
					.backgroundImage(.linearGradient("to bottom", Color("#3a3a44"), Color("#15151c")))
					.border(Color("#c0c0c0"), width: .pixels(4), style: .ridge)
					.color(.white)
			case .cabinet:
				// The cabinet of the arcade: black plastic with a lit marquee on top of the screen. The screen is big, so the pixels read.
				Style()
					.vstack(spacing: .rootEm(0.625))
					.frame(width: .percent(100), maxWidth: .rootEm(44))
					.margin(.horizontal, .auto)
					.padding(.rootEm(0.625))
					.backgroundImage(.linearGradient("to bottom", Color("#2a1a3a"), Color("#0a0a12")))
					.border(Color("#c0c0c0"), width: .pixels(4), style: .ridge)
			case .marquee:
				// The backlit sign on top of the machine.
				Style()
					.margin(0)
					.padding(vertical: .rootEm(0.375), horizontal: .rootEm(0.5))
					.backgroundImage(.linearGradient("to right", Color("#ff2fa8"), Color("#ffcc00"), Color("#33ccff")))
					.border(Color("#ffffff"), width: .pixels(2), style: .outset)
					.fontFamily(GeoCitiesPage.impact)
					.textStyle(.headline)
					.textCase(.uppercase)
					.letterSpacing(.pixels(2))
					.textAlign(.center)
					.color(.white)
					.textShadow(Shadow(x: .pixels(2), y: .pixels(2), color: Color("#330044")), Shadow(y: 0, blur: .pixels(6), color: Color("#ff00cc")))
			case .screen:
				// Big pixels, like the monitor of the arcade, and a tap on it starts the song.
				Style()
					.display(.block)
					.frame(width: .percent(100), height: .auto)
					.aspectRatio(320.0 / 240.0)
					.imageRendering(.pixelated)
					.border(Color("#444444"), width: .pixels(3), style: .inset)
					.background(.black)
					.touchAction(.manipulation)
					.focusVisible {
						$0.focusRing(Color("#ffcc00"), width: .pixels(2), offset: .pixels(2))
					}
			case .pad:
				// The dance pad on the floor: the four arrows in a cross of steel plates. A finger on an arrow steps instead of scrolling the page, and a finger on a steel plate still scrolls the page, so the big pad does not trap the scroll on a phone. A double tap does not zoom.
				Style()
					.grid(columns: 3)
					.gap(.pixels(5))
					.frame(width: .percent(100), maxWidth: .rootEm(20))
					.margin(.horizontal, .auto)
					.padding(.pixels(6))
					.backgroundImage(.linearGradient("to bottom", Color("#b8bcc4"), Color("#5a5e66")))
					.border(Color("#d8d8d8"), width: .pixels(3), style: .outset)
					.touchAction(.manipulation)
					.textSelection(.disabled)
			case .plate:
				Style()
					.aspectRatio(1)
					.backgroundImage(.linearGradient("to bottom right", Color("#c8ccd4"), Styles.steel))
					.border(Color("#6a6e76"), width: .pixels(2), style: .inset)
			case .padArrow:
				// A panel of the pad, which lights up from inside on a step, like the real one.
				Style()
					.aspectRatio(1)
					.frame(width: .percent(100), minHeight: .rootEm(3))
					.padding(0)
					.background(Color("#1a2140"))
					.border(Color("#3a4a7a"), width: .pixels(3), style: .outset)
					.fontFamily(.system)
					.textStyle(.largeTitle)
					.color(Color("#55aaff"))
					.handCursor()
					.touchAction(.none)
					.focusVisible {
						$0.focusRing(Color("#ffcc00"), width: .pixels(2), offset: .pixels(1))
					}
					.when(.state, is: "on") {
						$0
							.backgroundImage(.radialGradient("circle", Color("#ffffff"), Color("#ff66cc")))
							.border(Color("#ffccee"), width: .pixels(3), style: .inset)
							.color(Color("#660044"))
							.shadow(Shadow(y: 0, blur: .pixels(12), color: Color("#ff66cc")))
					}
			case .window:
				Style().frame(minWidth: 0)
			case .stack:
				Style().vstack(spacing: .rootEm(0.625))
			case .fieldset:
				Style()
					.margin(0)
					.padding(0)
					.border(.transparent, width: 0)
					.flowSpacing(.rootEm(0.375))
					.frame(minWidth: 0)
			case .songs:
				Style().vstack(spacing: .rootEm(0.375))
			case .triple:
				Style()
					.grid(columns: 3)
					.gap(.rootEm(0.375))
			case .choice:
				// A chunky toggle, which lights up like the song wheel of the machine when it is picked.
				Style()
					.vstack(alignment: .start, spacing: 0)
					.frame(width: .percent(100), minHeight: .rootEm(2.75))
					.padding(vertical: .rootEm(0.25), horizontal: .rootEm(0.5))
					.background(GeoCitiesPage.windowGray)
					.border(Color("#dfdfdf"), width: .pixels(3), style: .outset)
					.fontFamily(.system)
					.textStyle(.caption)
					.textAlign(.leading)
					.color(.black)
					.handCursor()
					.active {
						$0.border(Color("#dfdfdf"), width: .pixels(3), style: .inset)
					}
					.when(.state, is: "on") {
						$0
							.backgroundImage(.linearGradient("to right", Color("#ff66cc"), Color("#9933ff")))
							.border(Color("#ffccee"), width: .pixels(3), style: .inset)
							.color(.white)
					}
			case .dancerChoice:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.375))
			case .choiceTitle:
				Style()
					.fontWeight(.bold)
					.overflowWrap(.anywhere)
			case .choiceDetail:
				Style()
					.fontFamily(GeoCitiesPage.courier)
					.overflowWrap(.anywhere)
			case .toggle:
				Style()
					.frame(minHeight: .rootEm(2.25))
					.when(.state, is: "on") {
						$0
							.background(Color("#ffff99"))
							.border(Color("#dfdfdf"), width: .pixels(2), style: .inset)
					}
			case .calibration:
				Style().alignItems(.center)
			case .delay:
				Style()
					.frame(minWidth: .rootEm(7))
					.textAlign(.center)
			case .status:
				Style()
					.frame(minHeight: .lineHeight(3))
					.margin(0)
					.fontFamily(GeoCitiesPage.comicSans)
					.textStyle(.caption, weight: .bold)
			case .coins:
				Style()
					.margin(0)
					.textStyle(.caption, weight: .bold)
			}
		}
	}
}
