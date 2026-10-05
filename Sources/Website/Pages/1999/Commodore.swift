import Elementary
import Foundation
import SiteKit

/**
My Old Commodore 64: Pappa’s C64 from 1984, which I found in the closet and plugged into the old Tandberg TV in the basement, with the 1541 floppy drive, the Datassette, the joystick, and the power brick. The screen is a canvas of 384 × 272 pixels, the blue screen with the light blue border of a C64 on a PAL TV, with its own 8 × 8 font of capital letters and the graphic characters of PETSCII, drawn from the memory of the computer, so POKE and PEEK work like on the real one. It boots with “**** COMMODORE 64 BASIC V2 ****” and runs a real little BASIC V2 in the screen editor of the C64, where RETURN enters the line the cursor is on: line numbers, LIST, RUN, NEW, PRINT and `?`, GOTO, GOSUB, IF…THEN, FOR…NEXT, INPUT, GET, READ and DATA, DIM, DEF FN, the string and number functions, the real error messages like “?SYNTAX  ERROR”, RUN/STOP that says “BREAK IN 10”, and the keywords that hide in the names of variables, like on the real one. POKE 53280 and 53281 change the border and the background, the sprites show the balloon of the user’s manual, POKEs into the SID play sound, and the keyboard has SHIFT for the graphic characters and CTRL for the colors. The floppy drive grinds while it loads, `LOAD "$",8` and LIST show Pappa’s disk, `LOAD "*",8,1` loads the game Waffle Raid, and SAVE keeps the programs of the visitor on the disk, in the browser. The Datassette says “PRESS PLAY ON TAPE”, has a counter, rewind, and fast forward, and loads the cracked version of the game with stripes that flicker in the border, and the cracktro of TEAM WAFFLE with a trainer. Waffle Raid is a game of one screen, where the seagulls steal the waffles of Mormor over Bryggen, with SID music on the title screen. The joystick is broken to the left until the visitor bangs it on the table, the power brick gets warm and then too hot, Pappa’s note on the side has his cheat sheet on the back, and his notebook types the famous programs in, like the maze of `10 PRINT CHR$(205.5+RND(1));: GOTO 10`. Its script, `Commodore.js`, runs it only while it is on the screen and the tab is visible. For visitors who prefer reduced motion, the cursor does not blink, the stripes do not flicker, a program pauses after a few seconds until a key is pressed, and the game moves only while the joystick is held. There is no sound until the visitor turns on the sound of the TV.
*/
struct GeoCitiesCommodore: ScriptedElement {
	static let script = ElementScript()

	/**
	A key of the keyboard of the C64, with the value that `Commodore.js` knows it by, the text on it, and its width.
	*/
	struct Key {
		enum Width {
			case normal
			case wide
			case space
			case function

			var style: Styles {
				switch self {
				case .normal:
					.key
				case .wide:
					.wideKey
				case .space:
					.spaceKey
				case .function:
					.functionKey
				}
			}
		}

		let value: String
		let label: String
		var accessibilityLabel: String?
		var width = Width.normal
	}

	/**
	The keys of the C64, row by row, like on the real one, with the function keys at the end of the rows.
	*/
	private static let keyboardRows: [[Key]] = [
		[Key(value: "left-arrow", label: "←", accessibilityLabel: "Left arrow")]
			+ "1234567890+-".map { Key(value: String($0), label: String($0)) }
			+ [
				Key(value: "pound", label: "£", accessibilityLabel: "Pound"),
				Key(value: "clear-home", label: "CLR HOME", accessibilityLabel: "CLR/HOME", width: .wide),
				Key(value: "delete", label: "INST DEL", accessibilityLabel: "INST/DEL", width: .wide),
				Key(value: "f1", label: "f1", accessibilityLabel: "F1", width: .function),
			],
		[Key(value: "control", label: "CTRL", width: .wide)]
			+ "QWERTYUIOP@*".map { Key(value: String($0), label: String($0)) }
			+ [
				Key(value: "up-arrow", label: "↑", accessibilityLabel: "Up arrow"),
				// A soft hyphen breaks it on a phone, where the key is narrow.
				Key(value: "restore", label: "RE\u{00AD}STORE", accessibilityLabel: "RESTORE", width: .wide),
				Key(value: "f3", label: "f3", accessibilityLabel: "F3", width: .function),
			],
		[
			Key(value: "run-stop", label: "RUN STOP", accessibilityLabel: "RUN/STOP", width: .wide),
			Key(value: "shift-lock", label: "SHIFT LOCK", width: .wide),
		]
			+ "ASDFGHJKL:;=".map { Key(value: String($0), label: String($0)) }
			+ [
				Key(value: "return", label: "RETURN", width: .wide),
				Key(value: "f5", label: "f5", accessibilityLabel: "F5", width: .function),
			],
		[
			Key(value: "commodore", label: "C=", accessibilityLabel: "Commodore key"),
			Key(value: "shift", label: "SHIFT", width: .wide),
		]
			+ "ZXCVBNM,./".map { Key(value: String($0), label: String($0)) }
			+ [
				Key(value: "shift", label: "SHIFT", width: .wide),
				Key(value: "cursor-down", label: "CRSR ⇕", accessibilityLabel: "Cursor down"),
				Key(value: "cursor-right", label: "CRSR ⇔", accessibilityLabel: "Cursor right"),
				Key(value: "f7", label: "f7", accessibilityLabel: "F7", width: .function),
			],
		[
			Key(value: "space", label: "", accessibilityLabel: "Space", width: .space),
		],
	]

	/**
	A line of Pappa’s notebook, which `Commodore.js` types into the C64 by its ID.
	*/
	struct NotebookLine {
		let id: String
		let code: String
		let note: String
	}

	/**
	The lines of Pappa’s notebook, from the first thing to try to the last.
	*/
	private static let notebook = [
		NotebookLine(id: "maze", code: "10 PRINT CHR$(205.5+RND(1));: GOTO 10", note: "The famous maze, in one line."),
		NotebookLine(id: "cool", code: "10 PRINT \"SINDRE ER KUL\": GOTO 20", note: "Says that I am cool (kul). Forever."),
		NotebookLine(id: "colors", code: "POKE 53280,…: POKE 53281,…", note: "New colors for the border and the background."),
		NotebookLine(id: "directory", code: "LOAD \"$\",8", note: "What is on Pappa’s disk? Then LIST."),
		NotebookLine(id: "disk", code: "LOAD \"*\",8,1", note: "Loads the first program on the disk: a game!"),
		NotebookLine(id: "tape", code: "LOAD", note: "Loads the cracked game from the tape. Press PLAY!"),
		NotebookLine(id: "balloon", code: "LOAD \"BALLOON\",8", note: "The balloon sprite from the user’s manual."),
		NotebookLine(id: "waffles", code: "LOAD \"MAMMAS VAFLER\",8", note: "Mamma’s waffle recipe for any number of people."),
		NotebookLine(id: "guess", code: "LOAD \"GJETT TALLET\",8", note: "Guess the number (gjett tallet)."),
		NotebookLine(id: "siren", code: "LOAD \"IKKE ROR!!!\",8", note: "Pappa’s “do not touch” alarm, with SID sound."),
		NotebookLine(id: "free", code: "PRINT FRE(0)", note: "How much memory is free? It gets confused."),
		NotebookLine(id: "reset", code: "SYS 64738", note: "The magic number that restarts it."),
	]

	/**
	The tabindex of the section that the toy was, so a click on the toy outside its controls focuses the toy, and not the page.
	*/
	var rootAttributes: [HTMLAttribute<ElementTag<Self>>] {
		[.tabindex(-1)]
	}

	var content: some HTML {
		h2 {
			"💾 My Old Commodore 64"
		}
		.style(GeoCitiesPage.Styles.heading, GeoCitiesPage.Styles.centeredText)

		p {
			"Pappa’s Commodore 64 from 1984! I found it in the closet behind the vacuum cleaner, with the floppy drive, the tape player, the joystick, and a box of disks. I plugged it into the old Tandberg TV in the basement, and it still works. Turn it on, click the screen, and type on it with your keyboard. You do not know what to type? Pappa wrote the good stuff in his notebook."
		}
		.style(GeoCitiesPage.Styles.centeredText)

		div {
			television
			computer
			typing
			peripherals
			notebookView

			p(.part(Parts.status), .role("status")) {
				"It is off. Click the screen, or flip the power switch!"
			}
			.style(Styles.status)

			// What the C64 prints, for screen readers, as the canvas cannot say it.
			p(.part(Parts.output), .role("status")) {}
				.style(Styles.output)
		}
		.style(Styles.layout, GeoCitiesPage.Styles.scriptingOnly)

		p {
			"Pappa’s C64 needs JavaScript. And a lot of patience."
		}
		.style(GeoCitiesPage.Styles.scriptingDisabledOnly)
	}

	private var television: some HTML {
		div(.part(Parts.television)) {
			div {
				// The screen is drawn at 384 × 272 pixels: the 320 × 200 pixels of the C64 and its border, like on a PAL TV.
				canvas(.part(Parts.screen), .width(384), .height(272), .tabindex(0), .role("application")) {}
					.accessibilityLabel("The screen of the Commodore 64. Click it and type. Enter is RETURN, Backspace is DEL, Escape is RUN/STOP, Page Up is RESTORE, and the arrow keys move the cursor. In a game, the arrow keys are the joystick, and Space fires.")
					.style(Styles.screen, Styles.aboveStatus)
			}
			.style(Styles.tube)

			div {
				p {
					"TANDBERG"
				}
				.style(Styles.tvBrand)

				span {}
					.accessibilityHidden()
					.style(Styles.knob)

				span {}
					.accessibilityHidden()
					.style(Styles.knob)

				button(.part(Parts.sound), .type(.button), .ariaPressed(false)) {
					"🔈 Sound: Off"
				}
				.style(GeoCitiesPage.Styles.smallButton, Styles.aboveStatus)
			}
			.style(Styles.tvPanel)
		}
		.style(Styles.television)
	}

	private var computer: some HTML {
		div {
			div {
				div {
					div {
						p {
							"commodore"
						}
						.style(Styles.badgeName)

						span {
							"64"
						}
						.style(Styles.badgeModel)

						span {}
							.accessibilityHidden()
							.style(Styles.rainbow)
					}
					.style(Styles.badge)

					p {
						span(.part(Parts.powerLight)) {}
							.accessibilityHidden()
							.style(Styles.powerLight)

						"POWER"
					}
					.style(Styles.powerLabel)
				}
				.style(Styles.computerTop)

				div {
					for row in Self.keyboardRows {
						div {
							for key in row {
								// The keyboard of the computer types on the canvas, so the keys are not in the order of the Tab key.
								button(.type(.button), .tabindex(-1), .hook(Hooks.key, value: key.value)) {
									key.label
								}
								.accessibilityLabel(key.accessibilityLabel ?? key.label)
								.attributes(.ariaPressed(false), when: ["shift", "shift-lock", "control", "commodore"].contains(key.value))
								.style(Styles.keyBase, key.width.style)
							}
						}
						.style(Styles.keyRow)
					}
				}
				.style(Styles.keyboard)
			}
			.style(Styles.computer)

			div {
				button(.part(Parts.power), .type(.button), .ariaPressed(false)) {
					"⏻ Power Switch"
				}
				.style(GeoCitiesPage.Styles.retroButton, Styles.betweenStickyParts)

				button(.part(Parts.reset), .type(.button)) {
					"🔴 Pappa’s Reset Button"
				}
				.style(GeoCitiesPage.Styles.retroButton, Styles.betweenStickyParts)

				// Pappa’s note, taped to the side. Its back has his cheat sheet.
				button(.part(Parts.note), .type(.button), .ariaExpanded(false)) {
					span(.part(Parts.noteFront)) {
						"IKKE KAST! (Do not throw away!) It still works. Pappa, 1984"
					}

					span(.part(Parts.noteBack), .hidden) {
						"LOAD\"*\",8,1 = games. LOAD\"$\",8 + LIST = what is on the disk. POKE 53280,0 = black border. RUN/STOP = stop! SYS 64738 = start again."
					}
				}
				.style(Styles.note, Styles.betweenStickyParts)
			}
			.style(Styles.side)
		}
		.style(Styles.computerArea)
	}

	private var typing: some HTML {
		form(.part(Parts.form)) {
			label(.for("geocities-c64-field")) {
				"Type a line:"
			}
			.style(Styles.formLabel)

			input(.id("geocities-c64-field"), .part(Parts.field), .type(.text), .autocomplete("off"), .maxlength(80), .custom(name: "spellcheck", value: "false"), .custom(name: "autocapitalize", value: "characters"), .placeholder("PRINT \"HELLO\""))
				.style(GeoCitiesPage.Styles.field, Styles.field, Styles.betweenStickyParts)

			button(.type(.submit)) {
				"RETURN"
			}
			.style(GeoCitiesPage.Styles.retroButton, Styles.betweenStickyParts)
		}
		.style(Styles.typing)
	}

	private var peripherals: some HTML {
		div {
			div {
				p {
					"commodore 1541"
				}
				.style(Styles.deviceTitle)

				div {
					span {
						"PAPPAS DISKETT"
					}
					.style(Styles.disk)
				}
				.style(Styles.driveSlot)

				p {
					span(.part(Parts.driveLight)) {}
						.accessibilityHidden()
						.style(Styles.driveLight)

					"DRIVE"
				}
				.style(Styles.lightLabel)
			}
			.style(Styles.device, Styles.drive)

			div {
				p {
					"Datassette C2N"
				}
				.style(Styles.deviceTitle)

				div {
					span {
						"◉ ◉"
					}
					.accessibilityHidden()
					.style(Styles.reels)

					p(.part(Parts.counter)) {
						"000"
					}
					.accessibilityLabel("Tape counter")
					.style(GeoCitiesPage.Styles.lcd, Styles.counter)
				}
				.style(Styles.tapeWindow)

				div {
					for (control, label, title) in [("record", "●", "Record"), ("play", "▶", "Play"), ("rewind", "◀◀", "Rewind"), ("forward", "▶▶", "Fast forward"), ("stop", "■", "Stop")] {
						button(.type(.button), .hook(Hooks.tape, value: control)) {
							label
						}
						.accessibilityLabel(title)
						.attributes(.ariaPressed(false), when: control != "stop")
						.style(Styles.tapeButton, Styles.betweenStickyParts)
					}
				}
				.style(Styles.tapeButtons)

				p {
					"Tape: WAFFLE RAID, cracked (Trond copied it)"
				}
				.style(GeoCitiesPage.Styles.caption, Styles.deviceNote)
			}
			.style(Styles.device, Styles.datassette)

			div {
				p {
					"Joystick (port 2)"
				}
				.style(Styles.deviceTitle)

				div {
					for row in [[("up", "Up", "▲")], [("left", "Left (broken)", "◀"), ("fire", "Fire", "FIRE"), ("right", "Right", "▶")], [("down", "Down", "▼")]] {
						div {
							for (control, label, symbol) in row {
								// Held down like a real joystick, so they are not in the order of the Tab key. The keyboard plays with the arrow keys on the screen.
								button(.type(.button), .tabindex(-1), .hook(Hooks.joystick, value: control)) {
									symbol
								}
								.accessibilityLabel(label)
								.style(control == "fire" ? Styles.fireButton : Styles.stickButton)
							}
						}
						.style(Styles.stickRow)
					}
				}
				.style(Styles.stick)

				button(.part(Parts.bang), .type(.button)) {
					"🔨 Bang It on the Table"
				}
				.style(GeoCitiesPage.Styles.smallButton, Styles.betweenStickyParts)

				p {
					"Left has been broken since 1987."
				}
				.style(GeoCitiesPage.Styles.caption, Styles.deviceNote)
			}
			.style(Styles.device, Styles.joystick)

			div {
				p {
					"The Power Brick"
				}
				.style(Styles.deviceTitle)

				button(.part(Parts.brick), .type(.button)) {
					"🔌 Feel It"
					span(.part(Parts.brickReading)) {
						"21 °C"
					}
					.style(Styles.brickReading)
				}
				.style(Styles.brick, Styles.betweenStickyParts)

				p {
					"It weighs as much as a brick of brunost."
				}
				.style(GeoCitiesPage.Styles.caption, Styles.deviceNote)
			}
			.style(Styles.device, Styles.brickBox)
		}
		.style(Styles.peripherals)
	}

	private var notebookView: some HTML {
		div {
			h3 {
				"📒 Pappa’s Notebook"
			}
			.style(Styles.notebookTitle)

			p {
				"Click a line, and I type it in for you."
			}
			.style(GeoCitiesPage.Styles.caption)

			ul {
				for line in Self.notebook {
					li {
						button(.type(.button), .hook(Hooks.type, value: line.id)) {
							span {
								line.code
							}
							.style(Styles.notebookCode)

							span {
								line.note
							}
						}
						.style(Styles.notebookButton, Styles.betweenStickyParts)
					}
				}
			}
			.style(Styles.notebookList)
		}
		.style(Styles.notebook)
	}

	/**
	The elements that the script uses.
	*/
	enum Parts: String, ElementPartSet {
		case television
		case screen
		case sound
		case power
		case powerLight
		case reset
		case note
		case noteFront
		case noteBack
		case form
		case field
		case driveLight
		case counter
		case bang
		case brick
		case brickReading
		case status
		case output
	}

	/**
	The lists of the same kind of element, with a value for the script.
	*/
	enum Hooks: String, ScriptHookSet {
		/**
		A key of the keyboard of the C64, like `A` or `run-stop`.
		*/
		case key = "data-c64-key"

		/**
		A button of the Datassette, like `play`.
		*/
		case tape = "data-c64-tape"

		/**
		A direction of the joystick, or `fire`.
		*/
		case joystick = "data-c64-joystick"

		/**
		A line of Pappa’s notebook, which the script types in.
		*/
		case type = "data-c64-type"
	}

	enum Styles: ElementStyleSet {
		case root
		case layout
		case television
		case tube
		case screen
		case tvPanel
		case tvBrand
		case knob
		case computerArea
		case computer
		case computerTop
		case badge
		case badgeName
		case badgeModel
		case rainbow
		case powerLabel
		case powerLight
		case keyboard
		case keyRow
		case keyBase
		case key
		case wideKey
		case spaceKey
		case functionKey
		case side
		case note
		case typing
		case formLabel
		case field
		case peripherals
		case device
		case deviceTitle
		case deviceNote
		case drive
		case driveSlot
		case disk
		case lightLabel
		case driveLight
		case datassette
		case tapeWindow
		case reels
		case counter
		case tapeButtons
		case tapeButton
		case joystick
		case stick
		case stickRow
		case stickButton
		case fireButton
		case brickBox
		case brick
		case brickReading
		case notebook
		case notebookTitle
		case notebookList
		case notebookButton
		case notebookCode
		case status
		case aboveStatus
		case betweenStickyParts
		case output

		/**
		The brown beige of the plastic of the C64, the breadbin.
		*/
		private static let breadbin = Color("#9a8c76")

		var style: Style {
			switch self {
			case .root:
				GeoCitiesPage.Styles.section.style
			case .layout:
				Style()
					.vstack(alignment: .center, spacing: .rootEm(1))
					.margin(.top, .rootEm(1))
			case .television:
				// The wooden TV of the basement, with the panel of knobs below the screen.
				Style()
					.vstack(alignment: .center, spacing: .rootEm(0.5))
					.frame(width: .rootEm(40), maxWidth: .percent(100))
					.padding(.rootEm(0.875))
					.backgroundImage(.linearGradient("to bottom", Color("#7a4e2a"), Color("#5a361b"), Color("#4a2b14")))
					.border(Color("#2e1a0b"), width: .pixels(3))
					.cornerRadius(.rootEm(0.75))
					.shadow(Shadow(x: .pixels(4), y: .pixels(6), color: Color("#00000066")))
					// On a phone, the TV sticks under the header of the site while the tape plays and while a game runs, so the screen and the Datassette or the joystick far below it fit on the screen together.
					.below(.tablet) {
						$0.when(.state, is: "game") {
							$0
								.position(.sticky)
								.top(SiteHeader.height)
								.zIndex(1)
						}
					}
			case .tube:
				// The dark glass around the picture tube.
				Style()
					.frame(width: .percent(100))
					.padding(.rootEm(0.625))
					.background(Color("#151515"))
					.border(Color("#3a3a3a"), width: .pixels(3), style: .inset)
					.cornerRadius(.rootEm(1.25))
			case .screen:
				Style()
					.display(.block)
					.frame(width: .percent(100), height: .auto)
					.aspectRatio(384.0 / 272.0)
					.background(Color("#0d100d"))
					.cornerRadius(.rootEm(0.875))
					.imageRendering(.pixelated)
					.touchAction(.manipulation)
					.focusVisible {
						$0.focusRing(Color("#ffcc00"), width: .pixels(3), offset: .pixels(2))
					}
			case .tvPanel:
				Style()
					.hstack(alignment: .center, justification: .spaceBetween, spacing: .rootEm(0.75))
					.frame(width: .percent(100))
					.flexWrap()
			case .tvBrand:
				Style()
					.margin(0)
					.fontFamily(.system)
					.textStyle(.caption, weight: .heavy)
					.letterSpacing(.em(0.25))
					.color(Color("#e8d8b8"))
			case .knob:
				Style()
					.frame(width: .rootEm(1.5), height: .rootEm(1.5))
					.backgroundImage(.radialGradient("circle at 35% 35%", Color("#d0d0d0"), Color("#555555")))
					.border(Color("#222222"), width: .pixels(2))
					.cornerRadius(.circle)
			case .computerArea:
				Style()
					.vstack(alignment: .center, spacing: .rootEm(0.75))
					.frame(width: .rootEm(40), maxWidth: .percent(100))
			case .computer:
				// The breadbin: the brown beige case of the C64, with the keyboard.
				Style()
					.vstack(spacing: .rootEm(0.5))
					.frame(width: .percent(100))
					.padding(top: .rootEm(0.625), horizontal: .rootEm(0.625), bottom: .rootEm(0.875))
					.backgroundImage(.linearGradient("to bottom", Color("#a89a83"), Self.breadbin, Color("#857761")))
					.border(Color("#5e5241"), width: .pixels(2))
					.cornerRadius(.rootEm(0.875))
					.shadow(Shadow(x: .pixels(3), y: .pixels(5), color: Color("#00000055")))
			case .computerTop:
				Style().hstack(alignment: .center, justification: .spaceBetween, spacing: .rootEm(0.5))
			case .badge:
				// The badge of the C64, with the rainbow stripes.
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.375))
					.padding(vertical: .rootEm(0.125), horizontal: .rootEm(0.5))
					.background(Color("#2b2620"))
					.cornerRadius(.rootEm(0.25))
			case .badgeName:
				Style()
					.margin(0)
					.fontFamily(.system)
					.textStyle(.caption, weight: .bold)
					.color(Color("#e8e0d0"))
			case .badgeModel:
				Style()
					.fontFamily(.system)
					.textStyle(.caption, weight: .heavy)
					.color(Color("#e8e0d0"))
			case .rainbow:
				Style()
					.frame(width: .rootEm(2), height: .rootEm(0.75))
					.backgroundImage(.linearGradient("to bottom", Color("#e33b2e"), Color("#e33b2e"), Color("#f08a24"), Color("#f08a24"), Color("#f2d22e"), Color("#f2d22e"), Color("#4caf50"), Color("#4caf50"), Color("#2f7dd1"), Color("#2f7dd1")))
					.rotationEffect(.degrees(-20))
			case .powerLabel:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.375))
					.margin(0)
					.fontFamily(.system)
					.textStyle(.caption, weight: .bold)
					.color(Color("#3a3226"))
			case .powerLight:
				// The red light, on while the C64 is on.
				Style()
					.frame(width: .rootEm(0.75), height: .rootEm(0.375))
					.background(Color("#4a1612"))
					.cornerRadius(.rootEm(0.125))
					.when(.state, is: "on") {
						$0
							.background(Color("#ff3322"))
							.shadow(Shadow(y: 0, blur: .pixels(6), color: Color("#ff4433")))
					}
			case .keyboard:
				Style()
					.vstack(spacing: .pixels(3))
					.padding(.rootEm(0.375))
					.background(Color("#3d342a"))
					.cornerRadius(.rootEm(0.25))
			case .keyRow:
				Style().hstack(spacing: .pixels(3))
			case .keyBase:
				// A brown key, with the letters on the top, pressed in while it is held down.
				Style()
					.frame(minWidth: 0, minHeight: .rootEm(1.75))
					.padding(.pixels(1))
					.background(Color("#4e4237"))
					.border(Color("#2a221b"), width: .pixels(1))
					.cornerRadius(.pixels(3))
					.shadow(Shadow(y: .pixels(2), color: Color("#1e1813")))
					.fontFamily(.system)
					.font(size: .rootEm(0.5625), lineHeight: 1.05)
					.fontWeight(.bold)
					.color(Color("#efe6d6"))
					.textAlign(.center)
					// The labels get smaller on a phone, where the keys are narrow.
					.overflow(.hidden)
					.below(.tablet) {
						$0
							.font(size: .rootEm(0.375), lineHeight: 1.05)
							.letterSpacing(.em(-0.1))
					}
					.touchAction(.manipulation)
					.textSelection(.disabled)
					.handCursor()
					.active {
						$0
							.offset(y: .pixels(2))
							.shadow(Shadow(y: 0, color: Color("#1e1813")))
					}
					.when(.state, is: "on") {
						$0.background(Color("#8a6d3b"))
					}
			case .key:
				Style().flex(1)
			case .wideKey:
				Style().flex(2.2)
			case .spaceKey:
				Style()
					.flex(1)
					.margin(.horizontal, .percent(18))
			case .functionKey:
				// The function keys of the C64 are light, in a column to the right.
				Style()
					.flex(1.3)
					.margin(.leading, .rootEm(0.5))
					.below(.tablet) {
						$0
							.flex(1)
							.margin(.leading, .pixels(2))
					}
					.background(Color("#c9bda6"))
					.color(Color("#3a3226"))
			case .side:
				Style()
					.hstack(alignment: .center, justification: .center, spacing: .rootEm(0.75))
					.flexWrap()
			case .note:
				// The yellow note that Pappa taped to the side, a bit crooked.
				Style()
					.frame(maxWidth: .rootEm(14))
					.padding(vertical: .rootEm(0.5), horizontal: .rootEm(0.75))
					.background(Color("#fff27a"))
					.border(.top, Color("#e8d860"), width: .rootEm(0.5))
					.shadow(Shadow(x: .pixels(2), y: .pixels(3), color: Color("#00000040")))
					.fontFamily(GeoCitiesPage.comicSans)
					.textStyle(.caption, weight: .bold)
					.color(Color("#1a2a8a"))
					.textAlign(.leading)
					.rotationEffect(.degrees(-3))
					.handCursor()
			case .typing:
				Style()
					.hstack(alignment: .center, justification: .center, spacing: .rootEm(0.5))
					.frame(width: .rootEm(40), maxWidth: .percent(100))
			case .formLabel:
				Style()
					.fontFamily(GeoCitiesPage.comicSans)
					.textStyle(.caption, weight: .bold)
			case .field:
				Style()
					.flex(1)
					.frame(minWidth: 0)
					.fontFamily(GeoCitiesPage.courier)
					.textCase(.uppercase)
			case .peripherals:
				Style()
					.grid(minimumColumnWidth: .rootEm(9))
					.gap(.rootEm(0.75))
					.frame(width: .rootEm(40), maxWidth: .percent(100))
			case .device:
				Style()
					.vstack(alignment: .center, spacing: .rootEm(0.5))
					.padding(.rootEm(0.625))
					.border(Color("#5e5241"), width: .pixels(2))
					.cornerRadius(.rootEm(0.5))
					.shadow(Shadow(x: .pixels(2), y: .pixels(3), color: Color("#00000040")))
			case .deviceTitle:
				Style()
					.margin(0)
					.fontFamily(.system)
					.textStyle(.caption, weight: .heavy)
					.textAlign(.center)
			case .deviceNote:
				Style()
					.margin(0)
					.textAlign(.center)
			case .drive:
				// The 1541 floppy drive, in its light beige.
				Style()
					.background(Color("#d6ccb4"))
					.color(Color("#3a3226"))
			case .driveSlot:
				// The slot, with the disk half in it.
				Style()
					.frame(width: .percent(100))
					.padding(top: .rootEm(0.375), horizontal: .rootEm(0.5), bottom: .rootEm(0.125))
					.background(Color("#1d1a16"))
					.cornerRadius(.rootEm(0.25))
					.textAlign(.center)
			case .disk:
				Style()
					.display(.inlineBlock)
					.padding(vertical: .pixels(1), horizontal: .rootEm(0.5))
					.background(Color("#f4f0e6"))
					.border(.top, Color("#2a2a2a"), width: .rootEm(0.375))
					.fontFamily(GeoCitiesPage.comicSans)
					.font(size: .rootEm(0.625))
					.fontWeight(.bold)
					.color(Color("#c0261c"))
			case .lightLabel:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.375))
					.margin(0)
					.fontFamily(.system)
					.textStyle(.caption, weight: .bold)
			case .driveLight:
				// The red light of the drive, on while it reads or writes.
				Style()
					.frame(width: .rootEm(0.75), height: .rootEm(0.375))
					.background(Color("#4a1612"))
					.cornerRadius(.rootEm(0.125))
					.when(.state, is: "on") {
						$0
							.background(Color("#ff3322"))
							.shadow(Shadow(y: 0, blur: .pixels(6), color: Color("#ff4433")))
					}
			case .datassette:
				Style()
					.background(Self.breadbin)
					.color(Color("#1e1a14"))
			case .tapeWindow:
				Style()
					.hstack(alignment: .center, justification: .spaceBetween, spacing: .rootEm(0.5))
					.frame(width: .percent(100))
					.padding(vertical: .rootEm(0.25), horizontal: .rootEm(0.5))
					.background(Color("#2b2620"))
					.cornerRadius(.rootEm(0.25))
			case .reels:
				Style()
					.fontFamily(.system)
					.textStyle(.body, weight: .bold)
					.letterSpacing(.em(0.5))
					.color(Color("#bbbbbb"))
			case .counter:
				Style()
					.margin(0)
					.padding(vertical: 0, horizontal: .rootEm(0.375))
					.monospacedDigit()
			case .tapeButtons:
				Style().hstack(alignment: .center, justification: .center, spacing: .pixels(3))
			case .tapeButton:
				// The piano keys of the Datassette, which stay down while they play.
				Style()
					.frame(minWidth: .rootEm(1.875), minHeight: .rootEm(2))
					.background(Color("#3a3128"))
					.border(Color("#1d1813"), width: .pixels(1))
					.cornerRadius(.pixels(3))
					.shadow(Shadow(y: .pixels(3), color: Color("#1d1813")))
					.fontFamily(.system)
					.textStyle(.caption, weight: .bold)
					.color(Color("#efe6d6"))
					.handCursor()
					.when(.state, is: "on") {
						$0
							.offset(y: .pixels(3))
							.shadow(Shadow(y: 0, color: Color("#1d1813")))
							.background(Color("#5a4a3a"))
					}
			case .joystick:
				Style()
					.background(Color("#2a2a2a"))
					.color(Color("#eeeeee"))
			case .stick:
				Style().vstack(alignment: .center, spacing: .pixels(3))
			case .stickRow:
				Style().hstack(alignment: .center, justification: .center, spacing: .pixels(3))
			case .stickButton:
				Style()
					.frame(width: .rootEm(2.5), height: .rootEm(2.5))
					.background(Color("#111111"))
					.border(Color("#555555"), width: .pixels(1))
					.cornerRadius(.rootEm(0.375))
					.fontFamily(.system)
					.textStyle(.caption)
					.color(Color("#bbbbbb"))
					.touchAction(.none)
					.textSelection(.disabled)
					.handCursor()
					.active {
						$0.background(Color("#444444"))
					}
			case .fireButton:
				// The red fire button.
				Style()
					.frame(width: .rootEm(2.75), height: .rootEm(2.75))
					.background(Color("#d42a1e"))
					.border(Color("#7a120c"), width: .pixels(2))
					.cornerRadius(.circle)
					.shadow(Shadow(y: .pixels(3), color: Color("#7a120c")))
					.fontFamily(.system)
					.font(size: .rootEm(0.625))
					.fontWeight(.heavy)
					.color(.white)
					.touchAction(.none)
					.textSelection(.disabled)
					.handCursor()
					.active {
						$0
							.offset(y: .pixels(2))
							.shadow(Shadow(y: .pixels(1), color: Color("#7a120c")))
					}
			case .brickBox:
				Style()
					.background(Color("#4a4038"))
					.color(Color("#eeeeee"))
			case .brick:
				// The black power brick, which gets warm and then hot.
				Style()
					.vstack(alignment: .center, spacing: .rootEm(0.25))
					.frame(width: .percent(100), minHeight: .rootEm(4))
					.padding(.rootEm(0.5))
					.background(Color("#1e1b18"))
					.border(Color("#000000"), width: .pixels(2))
					.cornerRadius(.rootEm(0.375))
					.fontFamily(.system)
					.textStyle(.caption, weight: .bold)
					.color(Color("#dddddd"))
					.handCursor()
					.when(.state, is: "warm") {
						$0
							.background(Color("#4a2a18"))
							.shadow(Shadow(y: 0, blur: .pixels(10), color: Color("#ff8a3380")))
					}
					.when(.state, is: "hot") {
						$0
							.background(Color("#7a2010"))
							.shadow(Shadow(y: 0, blur: .pixels(16), color: Color("#ff3311cc")))
					}
			case .brickReading:
				Style()
					.fontFamily(GeoCitiesPage.courier)
					.monospacedDigit()
			case .notebook:
				// A page of Pappa’s notebook, with a red line in the margin.
				Style()
					.frame(width: .rootEm(40), maxWidth: .percent(100))
					.padding(vertical: .rootEm(0.75), horizontal: .rootEm(1))
					.padding(.leading, .rootEm(1.75))
					.background(Color("#fffdf0"))
					.border(.leading, Color("#e05050"), width: .pixels(3))
					.shadow(Shadow(x: .pixels(2), y: .pixels(3), color: Color("#00000033")))
					.color(Color("#1a2a6a"))
			case .notebookTitle:
				Style()
					.margin(0)
					.fontFamily(GeoCitiesPage.comicSans)
					.textStyle(.body, weight: .bold)
			case .notebookList:
				Style()
					.vstack(spacing: .rootEm(0.25))
					.margin(top: .rootEm(0.5), horizontal: 0, bottom: 0)
					.padding(0)
			case .notebookButton:
				// A line of the notebook, in Pappa’s handwriting next to the code.
				Style()
					.vstack(alignment: .start, spacing: 0)
					.frame(width: .percent(100), minHeight: .rootEm(2.75))
					.padding(vertical: .rootEm(0.25), horizontal: .rootEm(0.5))
					.background(.transparent)
					.border(.bottom, Color("#b8c8e8"), width: .pixels(1))
					.fontFamily(GeoCitiesPage.comicSans)
					.textStyle(.caption)
					.color(Color("#1a2a6a"))
					.textAlign(.leading)
					.handCursor()
					.hover {
						$0.background(Color("#fff6b0"))
					}
			case .notebookCode:
				Style()
					.fontFamily(GeoCitiesPage.courier)
					.fontWeight(.bold)
					.color(Color("#000000"))
					.overflowWrap(.anywhere)
			case .status:
				// It sticks above the status bar of the page while the C64 is on the screen, so what the computer, the drive, or the joystick says shows next to the thing that was clicked, even on a phone.
				Style()
					.position(.sticky)
					.bottom(.rootEm(2.5))
					.zIndex(1)
					.frame(width: .rootEm(40), maxWidth: .percent(100), minHeight: .lineHeight(2))
					.margin(0)
					.padding(.rootEm(0.375))
					.background(.white)
					.border(Color("#808080"), width: .pixels(2), style: .inset)
					.fontFamily(GeoCitiesPage.comicSans)
					.textStyle(.caption, weight: .bold)
					.textAlign(.center)
			case .aboveStatus:
				// The status line sticks above the status bar of the page, which is already in the scroll padding of the page, so a control that gets focus scrolls into view above the status line, also when it has 4 lines on a phone.
				Style().scrollMargin(bottom: .rootEm(6.5))
			case .betweenStickyParts:
				// Like `aboveStatus`, and on a phone, where the TV sticks under the header of the site while the tape plays or a game runs, a control below it that gets focus also scrolls into view below the TV. The TV is about 71 % of the width of the screen tall, and at most 32rem when it is 40rem wide.
				Style()
					.scrollMargin(bottom: .rootEm(6.5))
					.below(.tablet) {
						$0.scrollMargin(top: .min(.viewportWidth(71) + .rootEm(2.5), .rootEm(32)))
					}
			case .output:
				Style().visuallyHidden()
			}
		}
	}
}
