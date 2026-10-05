import Elementary
import Foundation
import SiteKit

/**
The video recorder under the TV in our living room in Bergen, with the TV on top of it and the rabbit ears on top of the TV, all drawn: the picture on a canvas, and the boxes and the buttons in HTML. The TV turns on with a hum and turns off with the snap to a dot, gets NRK1, TV 2, and TVNorge through the rabbit ears, which the visitor drags for less snow and fewer ghosts (the picture is best while somebody holds them), and has a Degauss button that wobbles the picture with a thunk and takes away the rainbow that Lillesøster made with the magnet from the fridge. A tape that plays wakes the TV from standby and switches it to AV, through the SCART cable. The VCR has the clock that blinks 12:00 until the visitor sets it like on a real VCR (hold Clock, then Ch+ and Ch−), four tapes to drag into the slot (the 17th of May with Pappa’s thumb over the lens, the Simpsons that I taped over the wedding of Mamma and Pappa, a rented Titanic that costs a fee if it goes back to the video store without being rewound, and a blank tape), Play, Pause with the jittery line, picture search, winding with a whine, the tape counter, the Tracking slider against the rolling bands, recording from the tuner of the VCR, and timer recordings with the ShowView codes of the TV guide in the newspaper, which start late and miss the end. Sometimes it eats the tape, and the visitor winds it back with a pencil. Its script, `VCR.js`, runs it, only while it is on the screen and the tab is visible, and keeps the clock, the tapes, and the fees in the browser. Nothing makes a sound until the visitor turns on the sound, and with reduced motion, the picture is a still frame that changes with each press. Without scripts, it is left out, as it has nothing to show.
*/
struct GeoCitiesVCR: ScriptedElement {
	static let script = ElementScript()
	let config = Config()

	/**
	A program in the TV guide of the newspaper. The script shows the programs of a channel live, one after the other, and records one with its ShowView code.
	*/
	struct Program: Encodable {
		let channel: Int
		let time: String
		let title: String
		let code: String

		/**
		The drawing of the program in the script.
		*/
		let scene: String

		let blurb: String
	}

	/**
	A tape on the shelf, with the label that Pappa, Mamma, or I wrote on it.
	*/
	private struct Tape {
		let id: String
		let label: String
		let note: String
		let accessibilityLabel: String
	}

	static let channels = ["NRK1", "TV 2", "TVNorge"]

	static let programs: [Program] = [
		Program(channel: 1, time: "18.00", title: "Barne-TV", code: "18342", scene: "children", blurb: "Solbabyen smiler igjen."),
		Program(channel: 1, time: "19.00", title: "Dagsrevyen", code: "40931", scene: "news", blurb: "Nyheter. Er datamaskinene klare for år 2000?"),
		Program(channel: 1, time: "19.25", title: "Været", code: "2264", scene: "weather", blurb: "Regn på Vestlandet."),
		Program(channel: 1, time: "19.30", title: "Derrick", code: "51226", scene: "derrick", blurb: "Tysk krim. Derrick og Harry finner morderen."),
		Program(channel: 2, time: "18.30", title: "The Simpsons", code: "7740", scene: "simpsons", blurb: "Amerikansk tegnefilm."),
		Program(channel: 2, time: "19.00", title: "Hotel Cæsar", code: "31909", scene: "soap", blurb: "Hvem er faren til barnet?"),
		Program(channel: 3, time: "18.00", title: "TV-Shop", code: "6021", scene: "shop", blurb: "Ring nå!"),
		Program(channel: 3, time: "19.00", title: "Baywatch", code: "66410", scene: "beach", blurb: "Livredderne på stranden."),
	]

	private static let tapes = [
		Tape(id: "may", label: "17. MAI 1998", note: "VHS-C · Pappa’s camcorder", accessibilityLabel: "Tape: the 17th of May 1998, our home video"),
		Tape(id: "wedding", label: "SIMPSONS!!! (Sindre)", note: "Bryllupet 1985 · IKKE TA OPP OVER", accessibilityLabel: "Tape: the Simpsons, which I recorded over the wedding of Mamma and Pappa"),
		Tape(id: "rental", label: "TITANIC · Kassett 1 av 2", note: "Vær snill og spol tilbake! Be kind, please rewind", accessibilityLabel: "Tape: Titanic, tape 1 of 2, rented from the video store"),
		Tape(id: "blank", label: "TOM · E-180", note: "Blank tape, for taping", accessibilityLabel: "Tape: a blank tape"),
	]

	private static let transport: [(id: String, symbol: String, label: String)] = [
		("eject", "⏏", "Eject"),
		("rewind", "◀◀", "Rewind"),
		("play", "▶", "Play"),
		("forward", "▶▶", "Fast forward"),
		("stop", "■", "Stop"),
		("pause", "❚❚", "Pause"),
		("record", "●", "Record"),
	]

	private static let flapButtons: [(id: String, label: String)] = [
		("clock", "Clock"),
		("channel-down", "Ch −"),
		("channel-up", "Ch +"),
		("showview", "ShowView"),
		("timer", "Timer ⏲"),
		("reset", "Counter 0000"),
	]

	var content: some HTML {
		h2 {
			"Our VCR (and the TV)"
		}
		.style(GeoCitiesPage.Styles.heading, GeoCitiesPage.Styles.centeredText)

		p {
			"The video recorder under the TV in our living room. The clock has blinked 12:00 since 1994, when Pappa gave up. Turn on the TV, drag the rabbit ears until the snow goes away, put a tape in the slot, and fight with the tracking. Or tape Derrick with the code from the newspaper, if you can set the clock."
		}

		div {
			div {
				canvas(.part(Parts.antenna), .width(400), .height(130), .tabindex(0), .role("application")) {}
					.accessibilityLabel("The rabbit ears on top of the TV. Drag the end of a rod to turn it for a better picture. With the keyboard, the left and right arrows turn a rod, and Space changes the rod.")
					.style(Styles.antenna)

				television

				recorder
			}
			.style(Styles.stack)

			// The status is right under the VCR, so it is on the screen with the buttons that it answers.
			p(.part(Parts.status), .role("status")) {
				"The TV is in standby. The VCR blinks 12:00, like always. Press Power, or press a tape."
			}
			.style(Styles.status)

			rescuePanel

			shelf

			extraButtons

			newspaper
		}
		.style(Styles.player, GeoCitiesPage.Styles.scriptingOnly)

		p {
			"The VCR needs JavaScript. And Pappa to find the remote."
		}
		.style(GeoCitiesPage.Styles.scriptingDisabledOnly)
	}

	struct Config: Encodable {
		/**
		The programs of the TV guide, which the script shows live and records with their ShowView codes.
		*/
		var programs = GeoCitiesVCR.programs
	}

	/**
	The TV, with the round glass of the screen and the buttons under it.
	*/
	private var television: some HTML {
		div {
			div {
				canvas(.part(Parts.screen), .width(640), .height(480), .tabindex(0), .role("application")) {}
					.accessibilityLabel("The screen of the TV. The up and down arrows change the channel, and Space shows the next picture.")
					.style(Styles.screen)
			}
			.style(Styles.bezel)

			div {
				p {
					"TANDBERG"
				}
				.accessibilityHidden()
				.style(Styles.brand)

				div {
					button(.part(Parts.power), .type(.button), .ariaPressed(false)) {
						span(.part(Parts.led)) {}
							.accessibilityHidden()
							.style(Styles.led)
						"Power"
					}
					.style(Styles.tvButton)

					button(.part(Parts.channelDown), .type(.button)) {
						"P −"
					}
					.accessibilityLabel("Channel down")
					.style(Styles.tvButton)

					button(.part(Parts.channelUp), .type(.button)) {
						"P +"
					}
					.accessibilityLabel("Channel up")
					.style(Styles.tvButton)

					button(.part(Parts.degauss), .type(.button)) {
						"Degauss"
					}
					.style(Styles.tvButton)
				}
				.style(Styles.tvButtons)
			}
			.style(Styles.tvPanel)
		}
		.style(Styles.television)
	}

	/**
	The silver VCR, with the slot, the glowing display, the buttons, the tracking, and the flap with the buttons that nobody in the family understands.
	*/
	private var recorder: some HTML {
		div {
			div {
				button(.part(Parts.slot), .type(.button)) {
					span {
						"VHS"
					}
					.accessibilityHidden()
					.style(Styles.slotFlap)
				}
				.accessibilityLabel("The tape slot. Drop a tape here, or press it to take the tape out.")
				.style(Styles.slot)

				div {
					span(.part(Parts.mode)) {}
						.style(Styles.displayMode)
					span {
						span(.part(Parts.first)) {
							"12"
						}
						.style(Styles.displayDigits)
						span(.part(Parts.second)) {
							":00"
						}
						.style(Styles.displayDigits)
					}
					.style(Styles.displayTime)
					span(.part(Parts.info)) {}
						.style(Styles.displayInfo)
					span(.part(Parts.recordLamp)) {
						"REC"
					}
					.style(Styles.recordLamp)
				}
				.accessibilityHidden()
				.style(Styles.display)
			}
			.style(Styles.vcrTop)

			div {
				for button in Self.transport {
					Elementary.button(.type(.button), .hook(Hooks.button, value: button.id)) {
						button.symbol
					}
					.accessibilityLabel(button.label)
					.style(Styles.vcrButton)
					.style(Styles.recordButton, when: button.id == "record")
				}
			}
			.accessibilityLabel("Buttons of the VCR")
			.style(Styles.transport)

			div {
				label {
					"Tracking "
					input(.part(Parts.tracking), .type(.range), .min(0), .max(100), .step(1), .value("50"))
						.style(Styles.trackingSlider)
				}
				.style(Styles.tracking)

				button(.part(Parts.flapToggle), .type(.button), .ariaExpanded(false), .ariaControls(Self.flapID)) {
					"▼ Open the flap"
				}
				.style(Styles.flapToggle)
			}
			.style(Styles.vcrBottom)

			div(.id(Self.flapID), .part(Parts.flap), .hidden) {
				div {
					for button in Self.flapButtons {
						Elementary.button(.type(.button), .hook(Hooks.button, value: button.id)) {
							button.label
						}
						.style(Styles.flapKey)
					}
				}
				.style(Styles.flapRow)

				div {
					for digit in [1, 2, 3, 4, 5, 6, 7, 8, 9, 0] {
						button(.type(.button), .hook(Hooks.digit, value: "\(digit)")) {
							"\(digit)"
						}
						.style(Styles.flapKey, Styles.digitKey)
					}
				}
				.accessibilityLabel("Number keys")
				.style(Styles.flapRow)
			}
			.style(Styles.flap)

			p {
				"VIDEO CASSETTE RECORDER · VHS · HQ · SHOWVIEW"
			}
			.accessibilityHidden()
			.style(Styles.vcrBrand)
		}
		.style(Styles.vcr)
	}

	/**
	Where the visitor winds the tape back with a pencil, after the VCR ate it.
	*/
	private var rescuePanel: some HTML {
		div(.part(Parts.rescue), .hidden) {
			p {
				"Put a pencil in the hole of the reel and turn it clockwise to wind the tape back in: drag around in circles, or press the button."
			}
			.style(GeoCitiesPage.Styles.caption)

			canvas(.part(Parts.rescueCanvas), .width(240), .height(150), .tabindex(0), .role("application")) {}
				.accessibilityLabel("The tape that the VCR ate, with a pencil in the reel. Drag around in circles to turn the pencil, or press the right arrow.")
				.style(Styles.rescueCanvas)

			button(.part(Parts.pencil), .type(.button)) {
				"✏️ Turn the Pencil"
			}
			.style(GeoCitiesPage.Styles.retroButton)
		}
		.style(Styles.rescue)
	}

	/**
	The tapes on the shelf, which the visitor drags into the slot.
	*/
	private var shelf: some HTML {
		div {
			for tape in Self.tapes {
				button(.type(.button), .hook(Hooks.tape, value: tape.id)) {
					span {
						tape.label
					}
					.style(Styles.tapeLabel)
					span {
						tape.note
					}
					.style(Styles.tapeNote)
					span {
						"◉ ▭ ◉"
					}
					.accessibilityHidden()
					.style(Styles.tapeReels)
				}
				.accessibilityLabel(tape.accessibilityLabel)
				.style(Styles.tape)
				.style(Styles.rentalTape, when: tape.id == "rental")
			}
		}
		.accessibilityLabel("The shelf with the tapes. Drag a tape into the slot of the VCR, or press it.")
		.style(Styles.shelf)
	}

	/**
	The sound, the magnet of Lillesøster, the video store, and the wait for the timer.
	*/
	private var extraButtons: some HTML {
		div {
			button(.part(Parts.sound), .type(.button), .ariaPressed(false)) {
				"🔈 Sound"
			}
			.style(GeoCitiesPage.Styles.retroButton)

			button(.part(Parts.magnet), .type(.button)) {
				"🧲 Lillesøster’s Magnet"
			}
			.style(GeoCitiesPage.Styles.retroButton)

			button(.part(Parts.returnTape), .type(.button)) {
				"🏪 Return Titanic"
			}
			.style(GeoCitiesPage.Styles.retroButton)

			button(.part(Parts.tonight), .type(.button), .hidden) {
				"🌙 Wait Until Tonight"
			}
			.style(GeoCitiesPage.Styles.retroButton)
		}
		.style(GeoCitiesPage.Styles.buttonRow)
	}

	/**
	The TV guide of tonight in the newspaper, with a ShowView code under each program, which Pappa circles with a pen.
	*/
	private var newspaper: some HTML {
		aside {
			p {
				"Bergens Tidende · TV i kveld"
			}
			.style(Styles.paperTitle)

			div {
				for (index, channel) in Self.channels.enumerated() {
					div {
						p {
							channel
						}
						.style(Styles.paperChannel)

						for program in Self.programs where program.channel == index + 1 {
							button(.type(.button), .hook(Hooks.program, value: program.code)) {
								span {
									"\(program.time) \(program.title)"
								}
								.style(Styles.programTitle)
								" "
								program.blurb
								span {
									"ShowView \(program.code)"
								}
								.style(Styles.programCode)
							}
							.style(Styles.program)
						}
					}
					.style(Styles.paperColumn)
				}
			}
			.style(Styles.paperColumns)
		}
		.accessibilityLabel("The TV guide in the newspaper")
		.style(Styles.paper)
	}

	/**
	How far the tape is dragged from its place on the shelf, which the script sets while the visitor drags it to the slot.
	*/
	static let dragX = StyleVariable<Length>("--vcr-drag-x")

	static let dragY = StyleVariable<Length>("--vcr-drag-y")

	/**
	The ID of the flap, for the `aria-controls` of its toggle.
	*/
	private static let flapID = "geocities-vcr-flap"

	enum Parts: String, ElementPartSet {
		case antenna
		case screen
		case power
		case led
		case channelDown
		case channelUp
		case degauss
		case slot
		case mode
		case first
		case second
		case info
		case recordLamp
		case tracking
		case flapToggle
		case flap
		case rescue
		case rescueCanvas
		case pencil
		case sound
		case magnet
		case returnTape
		case tonight
		case status
	}

	/**
	The lists of the same kind of element, with a value for the script.
	*/
	enum Hooks: String, ScriptHookSet {
		/**
		A button of the VCR, like `play` or `clock`.
		*/
		case button = "data-vcr-button"

		/**
		A number key under the flap of the VCR, with its digit.
		*/
		case digit = "data-vcr-digit"

		/**
		A tape on the shelf, with its ID, like `rental`.
		*/
		case tape = "data-vcr-tape"

		/**
		A program in the TV guide of the newspaper, with its ShowView code.
		*/
		case program = "data-vcr-program"
	}

	enum Styles: ElementStyleSet {
		case root
		case player
		case stack
		case antenna
		case television
		case bezel
		case screen
		case tvPanel
		case brand
		case tvButtons
		case tvButton
		case led
		case vcr
		case vcrTop
		case slot
		case slotFlap
		case display
		case displayMode
		case displayTime
		case displayDigits
		case displayInfo
		case recordLamp
		case transport
		case vcrButton
		case recordButton
		case vcrBottom
		case tracking
		case trackingSlider
		case flapToggle
		case flap
		case flapRow
		case flapKey
		case digitKey
		case vcrBrand
		case rescue
		case rescueCanvas
		case shelf
		case tape
		case rentalTape
		case tapeLabel
		case tapeNote
		case tapeReels
		case status
		case paper
		case paperTitle
		case paperColumns
		case paperColumn
		case paperChannel
		case program
		case programTitle
		case programCode

		var style: Style {
			switch self {
			case .root:
				GeoCitiesPage.Styles.section.style
			case .player:
				Style().vstack(alignment: .center, spacing: .rootEm(1))
			case .stack:
				// The rabbit ears, the TV, and the VCR stand on top of each other, like in our living room.
				Style()
					.vstack(alignment: .center, spacing: 0)
					.frame(width: .rootEm(32), maxWidth: .percent(100))
			case .antenna:
				// The rods reach out over the TV, and a drag on them does not scroll the page.
				Style()
					.display(.block)
					.frame(width: .percent(80), height: .auto)
					.aspectRatio(400.0 / 130.0)
					.margin(.bottom, .pixels(-4))
					.touchAction(.none)
					.handCursor()
					.focusVisible {
						$0.focusRing(Color("#ffcc00"), width: .pixels(2), offset: .pixels(2))
					}
			case .television:
				// A black TV of the 1990s, with a thick frame around the round glass and the buttons under it.
				Style()
					.vstack(spacing: .rootEm(0.5))
					.frame(width: .percent(100))
					.padding(top: .rootEm(0.875), horizontal: .rootEm(0.875), bottom: .rootEm(0.5))
					.backgroundImage(.linearGradient("to bottom", Color("#4a4a4f"), Color("#26262a")))
					.border(Color("#141416"), width: .pixels(3))
					.cornerRadius(.rootEm(1.25))
					.shadow(Shadow(x: .pixels(4), y: .pixels(6), color: Color("#00000066")), Shadow(y: .pixels(2), blur: .pixels(2), color: Color("#ffffff33"), isInset: true))
			case .bezel:
				Style()
					.padding(.rootEm(0.5))
					.background(Color("#121214"))
					.border(Color("#000000"), width: .pixels(2), style: .inset)
					.cornerRadius(.rootEm(1.25))
			case .screen:
				// The glass of the CRT is rounded at the corners and bulges a bit, so it has a shine at the top.
				Style()
					.display(.block)
					.frame(width: .percent(100), height: .auto)
					.aspectRatio(4.0 / 3.0)
					.background(Color("#0d120f"))
					.cornerRadius(.rootEm(1.5))
					.focusVisible {
						$0.focusRing(Color("#ffcc00"), width: .pixels(2), offset: .pixels(2))
					}
			case .tvPanel:
				Style()
					.hstack(alignment: .center, justification: .spaceBetween, spacing: .rootEm(0.5))
					.flexWrap()
			case .brand:
				Style()
					.margin(0)
					.fontFamily(.system)
					.textStyle(.caption, weight: .heavy)
					.letterSpacing(.em(0.3))
					.color(Color("#c8c8c8"))
			case .tvButtons:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.375))
					.flexWrap()
			case .tvButton:
				// The small black buttons of the TV, big enough for a finger.
				Style()
					.hstack(alignment: .center, justification: .center, spacing: .rootEm(0.375))
					.frame(minWidth: .rootEm(2.75), minHeight: .rootEm(2.5))
					.padding(.horizontal, .rootEm(0.5))
					.background(Color("#1b1b1d"))
					.border(Color("#5a5a60"), width: .pixels(2), style: .outset)
					.cornerRadius(.rootEm(0.375))
					.fontFamily(.system)
					.textStyle(.caption, weight: .bold)
					.color(Color("#dddddd"))
					.handCursor()
					.active {
						$0.border(Color("#5a5a60"), width: .pixels(2), style: .inset)
					}
			case .led:
				// Red in standby, and green while the TV is on.
				Style()
					.frame(width: .rootEm(0.5), height: .rootEm(0.5))
					.background(Color("#aa1111"))
					.cornerRadius(.circle)
					.when(.state, is: "on") {
						$0
							.background(Color("#33ff55"))
							.shadow(Shadow(y: 0, blur: .pixels(5), color: Color("#33ff55")))
					}
			case .vcr:
				// A silver VCR, a bit narrower than the TV on top of it.
				Style()
					.vstack(spacing: .rootEm(0.5))
					.frame(width: .percent(96))
					.padding(vertical: .rootEm(0.625), horizontal: .rootEm(0.75))
					.backgroundImage(.linearGradient("to bottom", Color("#e4e4e8"), Color("#b4b4bc"), Color("#9a9aa2")))
					.border(Color("#77777f"), width: .pixels(2))
					.cornerRadius(.rootEm(0.375))
					.shadow(Shadow(x: .pixels(3), y: .pixels(5), color: Color("#00000059")))
					.color(.black)
			case .vcrTop:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.5))
					.flexWrap()
			case .slot:
				// The slot for the tape, with a flap that is pushed in while a tape is inside.
				Style()
					.flex(1)
					.frame(minWidth: .rootEm(9), minHeight: .rootEm(2.75))
					.padding(.rootEm(0.25))
					.background(Color("#1a1a1c"))
					.border(Color("#555555"), width: .pixels(3), style: .inset)
					.cornerRadius(.rootEm(0.25))
					.handCursor()
					.when(.state, is: "target") {
						$0
							.background(Color("#34446a"))
							.shadow(Shadow(y: 0, blur: .pixels(8), color: Color("#66aaff")))
					}
					.when(.state, is: "loaded") {
						$0.border(Color("#333333"), width: .pixels(3), style: .inset)
					}
					.when(.state, is: "eaten") {
						$0.background(Color("#5a3010"))
					}
			case .slotFlap:
				Style()
					.display(.block)
					.padding(.vertical, .rootEm(0.25))
					.backgroundImage(.linearGradient("to bottom", Color("#3b3b40"), Color("#222225")))
					.fontFamily(.system)
					.textStyle(.caption, weight: .heavy)
					.italic()
					.letterSpacing(.em(0.2))
					.color(Color("#77777f"))
					.when(ancestorHas: ScriptAttribute.state, is: "loaded") {
						$0
							.backgroundImage(.linearGradient("to bottom", Color("#111111"), Color("#000000")))
							.color(Color("#444444"))
					}
			case .display:
				// The blue-green glowing display of the VCR, like a vacuum fluorescent display.
				Style()
					.hstack(alignment: .center, justification: .spaceBetween, spacing: .rootEm(0.5))
					.frame(minWidth: .rootEm(13), minHeight: .rootEm(2.75))
					.flex(1)
					.padding(vertical: .rootEm(0.25), horizontal: .rootEm(0.5))
					.background(Color("#071410"))
					.border(Color("#444448"), width: .pixels(2), style: .inset)
					.cornerRadius(.rootEm(0.25))
					.fontFamily(GeoCitiesPage.courier)
					.fontWeight(.bold)
					.color(Color("#5ff5d2"))
					.textShadow(Shadow(y: 0, blur: .pixels(4), color: Color("#2fe0b0")))
			case .displayMode:
				Style()
					.frame(minWidth: .rootEm(2.5))
					.textStyle(.body, weight: .bold)
			case .displayTime:
				Style()
					.font(.extraLarge, weight: .bold)
					.monospacedDigit()
			case .displayDigits:
				Style()
					.when(.state, is: "blink") {
						$0.media(.allowsMotion) {
							$0.animation(GeoCitiesPage.Animations.blink, .timingCurve("steps(1, end)", duration: .seconds(1)).repeatForever(autoreverses: false))
						}
					}
			case .displayInfo:
				Style()
					.frame(minWidth: .rootEm(3))
					.textStyle(.caption, weight: .bold)
					.textAlign(.trailing)
			case .recordLamp:
				Style()
					.textStyle(.caption, weight: .heavy)
					.color(Color("#3a1010"))
					.textShadow(Shadow(y: 0, color: .transparent))
					.when(.state, is: "on") {
						$0
							.color(Color("#ff3b3b"))
							.textShadow(Shadow(y: 0, blur: .pixels(5), color: Color("#ff0000")))
					}
			case .transport:
				Style()
					.hstack(alignment: .center, justification: .center, spacing: .rootEm(0.25))
					.flexWrap()
			case .vcrButton:
				// The silver buttons of the VCR, which glow green under the one that runs. All seven fit in one row on a phone.
				Style()
					.frame(minWidth: .rootEm(2.5), minHeight: .rootEm(2.5))
					.padding(.horizontal, .rootEm(0.375))
					.backgroundImage(.linearGradient("to bottom", Color("#f4f4f6"), Color("#c4c4ca")))
					.border(Color("#7a7a82"), width: .pixels(2), style: .outset)
					.cornerRadius(.rootEm(0.25))
					.fontFamily(.system)
					.textStyle(.body, weight: .bold)
					.color(Color("#222222"))
					.handCursor()
					.active {
						$0.border(Color("#7a7a82"), width: .pixels(2), style: .inset)
					}
					.when(.state, is: "on") {
						$0
							.border(Color("#2bbf8f"), width: .pixels(2), style: .inset)
							.shadow(Shadow(y: 0, blur: .pixels(6), color: Color("#33ffaa")))
					}
			case .recordButton:
				Style().color(Color("#cc0000"))
			case .vcrBottom:
				Style()
					.hstack(alignment: .center, justification: .spaceBetween, spacing: .rootEm(0.5))
					.flexWrap()
			case .tracking:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.375))
					.fontFamily(.system)
					.textStyle(.caption, weight: .bold)
					.color(Color("#333333"))
			case .trackingSlider:
				// Tall enough for a finger on a phone.
				Style()
					.frame(width: .rootEm(8), minHeight: .pixels(24))
					.handCursor()
			case .flapToggle:
				Style()
					.frame(minHeight: .rootEm(2.25))
					.padding(.horizontal, .rootEm(0.5))
					.background(Color("#a8a8b0"))
					.border(Color("#77777f"), width: .pixels(2), style: .outset)
					.cornerRadius(.rootEm(0.25))
					.fontFamily(.system)
					.textStyle(.caption, weight: .bold)
					.color(Color("#222222"))
					.handCursor()
			case .flap:
				// The panel under the flap, with the buttons that nobody in the family understands.
				Style()
					.vstack(spacing: .rootEm(0.375))
					.padding(.rootEm(0.5))
					.background(Color("#8a8a92"))
					.border(Color("#66666e"), width: .pixels(2), style: .inset)
					.cornerRadius(.rootEm(0.25))
			case .flapRow:
				Style()
					.hstack(alignment: .center, justification: .center, spacing: .rootEm(0.375))
					.flexWrap()
			case .flapKey:
				Style()
					.frame(minWidth: .rootEm(2.75), minHeight: .rootEm(2.5))
					.padding(.horizontal, .rootEm(0.375))
					.background(Color("#2a2a2e"))
					.border(Color("#111111"), width: .pixels(2))
					.cornerRadius(.rootEm(0.375))
					.fontFamily(.system)
					.textStyle(.caption, weight: .bold)
					.color(.white)
					.touchAction(.manipulation)
					.textSelection(.disabled)
					.handCursor()
					.active {
						$0.scaleEffect(0.94)
					}
					.when(.state, is: "on") {
						$0
							.background(Color("#2bbf8f"))
							.color(.black)
					}
			case .digitKey:
				Style()
					.frame(minWidth: .rootEm(2.5))
					.cornerRadius(.circle)
			case .vcrBrand:
				Style()
					.margin(0)
					.fontFamily(.system)
					.textStyle(.caption, weight: .heavy)
					.letterSpacing(.em(0.12))
					.textAlign(.center)
					.color(Color("#55555c"))
			case .rescue:
				// A note from Pappa about the rescue, on a brown piece of paper, like the tape.
				Style()
					.vstack(alignment: .center, spacing: .rootEm(0.5))
					.frame(maxWidth: .rootEm(24))
					.padding(.rootEm(0.75))
					.background(Color("#fff3d6"))
					.border(Color("#8a5a2a"), width: .pixels(3), style: .dashed)
					.color(.black)
			case .rescueCanvas:
				Style()
					.display(.block)
					.frame(width: .percent(100), height: .auto, maxWidth: .rootEm(18))
					.aspectRatio(240.0 / 150.0)
					.background(Color("#d8c8a8"))
					.border(Color("#8a5a2a"), width: .pixels(2))
					.touchAction(.none)
					.handCursor()
					.focusVisible {
						$0.focusRing(Color("#cc6600"), width: .pixels(2), offset: .pixels(2))
					}
			case .shelf:
				// The shelf under the VCR, of wood, with the tapes standing on it.
				Style()
					.hstack(alignment: .end, justification: .center, spacing: .rootEm(0.5))
					.flexWrap()
					.frame(width: .rootEm(32), maxWidth: .percent(100))
					.padding(top: .rootEm(0.5), horizontal: .rootEm(0.5), bottom: .rootEm(0.75))
					.backgroundImage(.linearGradient("to bottom", Color("#00000000"), Color("#00000000"), Color("#8b5a2b")))
					.border(.bottom, Color("#5a3a1a"), width: .rootEm(0.5))
					// On a phone, the tapes stand in two rows, so the shelf is a cabinet of wood behind both rows, and the top row does not float in the air.
					.below(.smallTablet) {
						$0
							.backgroundImage(.linearGradient("to bottom", Color("#6b4423"), Color("#8b5a2b")))
							.border(Color("#5a3a1a"), width: .rootEm(0.375))
							.border(.bottom, Color("#5a3a1a"), width: .rootEm(0.5))
					}
			case .tape:
				// A black VHS cassette with a paper label, which the visitor drags to the slot.
				Style()
					.position(.relative)
					.vstack(alignment: .center, spacing: .rootEm(0.125))
					.frame(width: .rootEm(7), minHeight: .rootEm(4.5))
					.padding(.rootEm(0.25))
					.background(Color("#161618"))
					.border(Color("#000000"), width: .pixels(2))
					.cornerRadius(.rootEm(0.25))
					.shadow(Shadow(x: .pixels(2), y: .pixels(3), color: Color("#00000066")))
					.fontFamily(GeoCitiesPage.comicSans)
					.color(.black)
					.touchAction(.none)
					.textSelection(.disabled)
					.handCursor()
					.focusVisible {
						$0.focusRing(Color("#ffcc00"), width: .pixels(2), offset: .pixels(2))
					}
					.when(.state, is: "dragging") {
						$0
							.offset(x: GeoCitiesVCR.dragX.value(default: 0), y: GeoCitiesVCR.dragY.value(default: 0))
							.zIndex(2)
							.shadow(Shadow(x: .pixels(6), y: .pixels(10), blur: .pixels(6), color: Color("#00000080")))
					}
					.when(.state, is: "inserted") {
						$0
							.opacity(0.25)
							.border(Color("#000000"), width: .pixels(2), style: .dashed)
					}
			case .rentalTape:
				Style()
					.background(Color("#20304a"))
			case .tapeLabel:
				Style()
					.frame(width: .percent(100))
					.padding(.horizontal, .rootEm(0.125))
					.background(Color("#fdfbf0"))
					.textStyle(.caption, weight: .bold)
					.lineHeight(1.15)
					.rotationEffect(.degrees(-1.5))
			case .tapeNote:
				Style()
					.frame(width: .percent(100))
					.padding(.horizontal, .rootEm(0.125))
					.background(Color("#ffe14a"))
					.fontFamily(.system)
					.font(.extraSmall)
					.lineHeight(1.1)
			case .tapeReels:
				Style()
					.fontFamily(.system)
					.textStyle(.caption)
					.color(Color("#77777f"))
			case .status:
				Style()
					.frame(maxWidth: .rootEm(32), minHeight: .lineHeight(3))
					.margin(0)
					.fontFamily(GeoCitiesPage.comicSans)
					.textStyle(.caption, weight: .bold)
					.textAlign(.center)
			case .paper:
				// The TV guide of the newspaper, on gray newsprint, a bit crooked on the table.
				Style()
					.frame(width: .rootEm(32), maxWidth: .percent(100))
					.padding(.rootEm(0.75))
					.background(Color("#efece2"))
					.border(Color("#b8b4a8"), width: .pixels(1))
					.shadow(Shadow(x: .pixels(3), y: .pixels(4), color: Color("#00000040")))
					.rotationEffect(.degrees(-0.6))
					.fontFamily(GeoCitiesPage.times)
					.color(Color("#1a1a1a"))
			case .paperTitle:
				Style()
					.margin(top: 0, bottom: .rootEm(0.5))
					.padding(.bottom, .rootEm(0.25))
					.border(.bottom, Color("#1a1a1a"), width: .pixels(3), style: .double)
					.font(.large, weight: .heavy)
					.textAlign(.center)
			case .paperColumns:
				Style()
					.grid(minimumColumnWidth: .rootEm(9))
					.gap(.rootEm(0.75))
			case .paperColumn:
				Style().vstack(spacing: .rootEm(0.25))
			case .paperChannel:
				Style()
					.margin(0)
					.padding(.horizontal, .rootEm(0.375))
					.background(Color("#1a1a1a"))
					.fontFamily(.system)
					.textStyle(.caption, weight: .heavy)
					.color(Color("#efece2"))
			case .program:
				// A program, which Pappa circles with a red pen.
				Style()
					.display(.block)
					.padding(vertical: .rootEm(0.125), horizontal: .rootEm(0.375))
					.border(Color("#00000000"), width: .pixels(2))
					.cornerRadius(.rootEm(0.75))
					.inheritsFont()
					.textStyle(.caption)
					.textAlign(.leading)
					.color(Color("#1a1a1a"))
					.handCursor()
					.hover {
						$0.background(Color("#e2ddcc"))
					}
					.when(.state, is: "circled") {
						$0
							.border(Color("#d01010"), width: .pixels(2))
							.rotationEffect(.degrees(-1))
					}
			case .programTitle:
				Style().fontWeight(.bold)
			case .programCode:
				Style()
					.display(.block)
					.fontFamily(GeoCitiesPage.courier)
					.font(.extraSmall, weight: .bold)
					.color(Color("#555555"))
			}
		}
	}
}
