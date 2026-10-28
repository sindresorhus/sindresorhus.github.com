import Elementary
import Foundation
import SiteKit

extension GeoCitiesPage {
	/**
	The templates of the effects and the screens that cover the window: the canvas screen savers, the cards of the Solitaire win and the fireworks, the mouse trails, the blue screen and the bomb of the skull, and the screen of Shut Down.
	*/
	@HTMLBuilder
	var effectTemplates: some HTML {
		// `geocities.js` shows a copy for the screen savers that are drawn on a canvas, like 3D Pipes.
		template(.id(IDs.saverCanvasTemplate)) {
			div {
				canvas {}
					.style(Styles.saverCanvas)

				p {
					"Move the mouse or tap to come back"
				}
				.style(Styles.saverText)
			}
			.accessibilityHidden()
			.style(Styles.saver)
		}

		// `geocities.js` adds a copy for the cards of the Solitaire win and for the fireworks of the year 2000, unless the visitor prefers reduced motion.
		template(.id(IDs.effectTemplate)) {
			canvas {}
				.accessibilityHidden()
				.style(Styles.effectCanvas)
		}

		// `geocities.js` adds a copy for each ball of the elastic trail and each number and dot of the clock that follow the mouse pointer.
		template(.id(IDs.trailDotTemplate)) {
			span {}
				.accessibilityHidden()
				.style(Styles.trailDot)
		}

		// `geocities.js` shows a copy when the visitor clicks the skull: the blue screen of Windows 98, or the bomb of the Mac, until a key or a click.
		template(.id(IDs.blueScreenTemplate)) {
			div(
				.role("alertdialog"),
				.ariaModal,
				.tabindex(-1),
				.ariaLabelledBy(ElementID("geocities-blue-screen-title")),
				.ariaDescribedBy(ElementID("geocities-blue-screen-text"))
			) {
				div {
					p(.id("geocities-blue-screen-title")) {
						"Windows"
					}
					.style(Styles.blueScreenTitle)

					p(.id("geocities-blue-screen-text")) {
						"A fatal exception 0E has occurred at 0028:C0011E36 in VXD UNICORN(01) + 00010E36. The current application will be terminated."
					}

					ul {
						li {
							"Press any key to terminate the current application."
						}

						li {
							"Press CTRL+ALT+DEL again to restart your computer. You will lose any unsaved information in all applications."
						}
					}
					.style(Styles.blueScreenList)

					p {
						"Press any key to continue "
						span {
							"_"
						}
						.accessibilityHidden()
						.style(Styles.blinkingCursor)
					}
					.style(Styles.centeredText)
				}
				.style(Styles.blueScreenText)
			}
			.style(Styles.blueScreen)
		}

		template(.id(IDs.bombTemplate)) {
			div {
				div(
					.role("alertdialog"),
					.ariaModal,
					.tabindex(-1),
					.ariaLabelledBy(ElementID("geocities-bomb-title")),
					.ariaDescribedBy(ElementID("geocities-bomb-text"))
				) {
					gif(.bomb)

					div {
						p(.id("geocities-bomb-title")) {
							strong {
								"Sorry, a system error occurred."
							}
						}

						p(.id("geocities-bomb-text")) {
							"“Glitter” Unimplemented trap. An error of type 1999 occurred."
						}

						p {
							"To temporarily turn off extensions, restart and hold down the Shift key."
						}
						.style(Styles.caption)
					}

					button(.type(.button)) {
						"Restart"
					}
					.style(Styles.macButton)
				}
				.style(Styles.bombDialog)
			}
			.style(Styles.bombScreen)
		}

		// `geocities.js` shows a copy when the visitor shuts down the computer of the desktop, until a key or a click turns it on again.
		template(.id(IDs.shutDownTemplate)) {
			div(
				.role("dialog"),
				.ariaModal,
				.tabindex(-1),
				.ariaLabelledBy(ElementID("geocities-shut-down-text"))
			) {
				p(.id("geocities-shut-down-text")) {
					"It’s now safe to turn off your computer."
				}
				.style(Styles.shutDownText)

				p {
					"Press any key, or tap, to turn it on again."
				}
				.style(Styles.caption)
			}
			.style(Styles.shutDown)
		}
	}

	/**
	Snake on the mobile phone of my dad, like the Snake of 1997 on a screen of 84 × 48 pixels. The keys 2, 4, 6, and 8 of the keypad steer, and 5 starts and pauses. `geocities.js` runs it on the canvas, where the arrow keys and swipes on the screen steer too. With reduced motion, the snake moves one step for each key press, so nothing moves by itself.
	*/
	var snake: some HTML {
		section(.id("geocities-snake")) {
			h2 {
				gif(.mobilePhone)
				" Snake on My Dad’s Mobile Phone"
			}
			.style(Styles.heading, Styles.centeredText)

			p {
				"My dad got a mobile phone, and it has a game! Eat the waffles, but do not bite your own tail. Do not call anybody. It costs 5 kroner a minute."
			}
			.style(Styles.centeredText)

			div(.id(IDs.snakePhone)) {
				p {
					"PAPPA"
				}
				.accessibilityHidden()
				.style(Styles.phoneBrand)

				div {
					p(.id(IDs.snakeScore)) {
						"Score: 0 ★ Best: 0"
					}
					.style(Styles.phoneScore)

					canvas(
						.id(IDs.snakeScreen),
						.width(84),
						.height(48),
						.role("img")
					) {}
						.accessibilityLabel("The screen of the phone, with the snake")
						.style(Styles.phoneCanvas)

					p(.id(IDs.snakeStatus), .role("status")) {
						"Press 5 to play!"
					}
					.style(Styles.phoneStatus)
				}
				.style(Styles.phoneScreen)

				div {
					for (key, name, symbol) in Self.phoneKeys {
						button(.type(.button), .hook(Hooks.snakeKey, value: key)) {
							key

							if let symbol {
								span {
									symbol
								}
								.accessibilityHidden()
								.style(Styles.phoneKeySymbol)
							}
						}
						.accessibilityLabel(name)
						.style(Styles.phoneKey)
					}
				}
				.style(Styles.phoneKeys)
			}
			.style(Styles.phone, Styles.scriptingOnly)

			p {
				"Steer with 2, 4, 6, and 8, or with the arrow keys, or swipe on the screen."
			}
			.style(Styles.caption, Styles.centeredText, Styles.scriptingOnly)

			p {
				"Snake needs JavaScript. And batteries."
			}
			.style(Styles.scriptingDisabledOnly)
		}
		.style(Styles.section)
	}

	/**
	My computer, a desktop of Windows 98 with icons, a Start menu with submenus, and a taskbar with buttons for the open windows, a tray, and a clock. Each icon opens a window with a program: Unicorn Paint, Y2K Bugsweeper, my secret diary in Notepad, Solitaire, the System Properties, the Recycle Bin, and the programs of ``GeoCitiesWindows``. `geocities.js` opens, closes, and drags the windows, and runs its programs. Shut Down leaves the visitor with the black screen of Windows 95, until any key turns the computer on again.
	*/
	var desktop: some HTML {
		section(.id("geocities-pc")) {
			h2 {
				gif(.computerGame)
				" My Computer"
			}
			.style(Styles.heading, Styles.centeredText)

			p {
				"I put Windows 98 on my iMac. Do not ask how. Click an icon to open a program, drag the windows by their title bars, and right-click the desktop (or hold a finger on it). The Start menu has even more programs, and Ctrl+Alt+Del does what it always did. NEW: 3D Pinball, the Windows 95 CD with its videos, and BonziBUDDY, who will never leave."
			}
			.style(Styles.centeredText)

			div(.id(IDs.desktop)) {
				ul {
					for app in Self.desktopApps {
						li {
							button(.type(.button), .hook(Hooks.desktopOpen, value: app.program.rawValue)) {
								span {
									app.icon
								}
								.accessibilityHidden()
								.style(Styles.desktopIconPicture)

								span {
									app.title
								}
								.style(Styles.desktopIconTitle)
							}
							.style(Styles.desktopIcon)
						}
					}
				}
				.accessibilityLabel("Desktop")
				.style(Styles.desktopIcons)

				GeoCitiesWindows.window(.paint, title: "untitled - Unicorn Paint") {
					Deferred(paint)
				}

				GeoCitiesWindows.window(.sweeper, title: "Y2K Bugsweeper") {
					Deferred(sweeper)
				}

				GeoCitiesWindows.window(.notepad, title: "SECRET.TXT - Notepad") {
					Deferred(notepad)
				}

				GeoCitiesWindows.window(.solitaire, title: "Solitaire") {
					Deferred(solitaire)
				}

				GeoCitiesWindows.window(.computer, title: "System Properties") {
					Deferred(systemProperties)
				}

				GeoCitiesWindows.window(.recycle, title: "Recycle Bin") {
					Deferred(recycleBin)
				}

				Deferred(GeoCitiesWindows())

				div(.id(IDs.startMenu), .hidden) {
					p {
						"Windows98"
					}
					.accessibilityHidden()
					.style(Styles.startMenuBanner)

					ul {
						GeoCitiesWindows.startMenuItems

						li {
							button(.id(IDs.shutDown), .type(.button)) {
								span {
									"⏻"
								}
								.accessibilityHidden()
								.style(Styles.desktopIconPicture)

								"Shut Down…"
							}
							.style(Styles.startMenuItem)
						}
						.style(Styles.startMenuSeparator)
					}
					.style(Styles.startMenuList)
				}
				.style(Styles.startMenu)

				div {
					button(
						.id(IDs.startButton),
						.type(.button),
						.ariaExpanded(false),
						.ariaControls(IDs.startMenu.id)
					) {
						span {
							"⊞"
						}
						.accessibilityHidden()

						" Start"
					}
					.style(Styles.startButton)

					GeoCitiesWindows.QuickLaunch()

					GeoCitiesWindows.TaskButtons()

					GeoCitiesWindows.Tray()

					p(.id(IDs.taskbarClock)) {
						"11:59 PM"
					}
					.style(Styles.taskbarClock)
				}
				.style(Styles.taskbar)
			}
			.style(Styles.desktop, Styles.scriptingOnly, GeoCitiesWindows.Styles.desktopState)

			p {
				"My computer needs JavaScript to boot."
			}
			.style(Styles.scriptingDisabledOnly)
		}
		.style(Styles.section)
	}

	/**
	Unicorn Paint, like MS Paint with the tools of Kid Pix: a pencil, a brush, a spray can, a fill bucket, a rainbow brush, stamps of the GIFs of the page, an eraser, “Oops!” to undo, dynamite to blow up the picture, and a button that saves it. `geocities.js` draws on the canvas. The arrow keys move the brush, and Space paints, so the keyboard draws too.
	*/
	var paint: some HTML {
		div {
			div(.role("group")) {
				for tool in Self.paintTools {
					button(.type(.button), .hook(Hooks.paintTool, value: tool.id), .ariaPressed(tool.id == "pencil")) {
						tool.icon
					}
					.accessibilityLabel(tool.name)
					.help(tool.name)
					.style(Styles.paintButton)
				}

				button(.id(IDs.paintUndo), .type(.button)) {
					"Oops!"
				}
				.help("Undo")
				.style(Styles.paintButton)

				button(.id(IDs.paintClear), .type(.button)) {
					gif(.dynamite)
					"Boom!"
				}
				.accessibilityLabel("Boom! Blow up the picture")
				.help("Blow up the picture")
				.style(Styles.paintButton)

				button(.id(IDs.paintSave), .type(.button)) {
					"💾"
				}
				.accessibilityLabel("Save the picture")
				.help("Save the picture")
				.style(Styles.paintButton)
			}
			.accessibilityLabel("Tools")
			.style(Styles.paintTools)

			div(.id(IDs.paintStamps), .role("group"), .hidden) {
				for (index, stamp) in Self.paintStamps.enumerated() {
					button(.type(.button), .hook(Hooks.paintStamp, value: stamp.gif.stillPath.description), .ariaPressed(index == 0)) {
						gif(stamp.gif, style: .paintStampPicture)
					}
					.accessibilityLabel(stamp.name)
					.style(Styles.paintButton)
				}
			}
			.accessibilityLabel("Stamps")
			.style(Styles.paintTools)

			div {
				canvas(
					.id(IDs.paintCanvas),
					.width(320),
					.height(200),
					.tabindex(0),
					.role("img")
				) {}
					.accessibilityLabel("Your picture. Draw with the mouse or a finger, or move the brush with the arrow keys and paint with Space.")
					.style(Styles.paintCanvas)

				span(.id(IDs.paintCursor), .hidden) {}
					.accessibilityHidden()
					.style(Styles.paintCursor)
			}
			.style(Styles.paintCanvasFrame)

			div(.role("group")) {
				for color in Self.paintColors {
					button(.type(.button), .hook(Hooks.paintColor, value: color.hex), .ariaPressed(color.hex == "#000000")) {}
						.accessibilityLabel(color.name)
						.help(color.name)
						.style(Styles.paintSwatch)
				}
			}
			.accessibilityLabel("Colors")
			.style(Styles.paintPalette)

			p(.id(IDs.paintStatus), .role("status")) {
				"Pick a tool and draw a unicorn!"
			}
			.style(Styles.statusBar)
		}
		.style(Styles.paint)
	}

	/**
	Y2K Bugsweeper, like Minesweeper, with 10 bugs of the year 2000 hidden among 81 squares. A number says how many bugs touch the square. The face starts a new game. `geocities.js` runs it: a click opens a square, a click on a number with all its bugs flagged opens the squares around it, and a right-click, the F key, a long press of a finger, or Flag mode flags a bug. The arrow keys move between the squares.
	*/
	var sweeper: some HTML {
		div {
			div {
				p(.id(IDs.sweeperBugs), .role("img")) {
					"010"
				}
				.accessibilityLabel("10 bugs left")
				.style(Styles.sweeperLED)

				button(.id(IDs.sweeperFace), .type(.button)) {
					"🙂"
				}
				.accessibilityLabel("New game")
				.style(Styles.sweeperFace)

				p(.id(IDs.sweeperTime)) {
					"000"
				}
				.accessibilityHidden()
				.style(Styles.sweeperLED)
			}
			.style(Styles.sweeperBar)

			div(.id(IDs.sweeperGrid), .role("group")) {
				for index in 0..<(Self.sweeperSize * Self.sweeperSize) {
					button(.type(.button), .hook(Hooks.sweeperCell, value: "\(index)"), .tabindex(index == 0 ? 0 : -1)) {}
						.accessibilityLabel("Row \(index / Self.sweeperSize + 1), column \(index % Self.sweeperSize + 1)")
						.style(Styles.sweeperCell)
				}
			}
			.accessibilityLabel("Minefield of 9 by 9 squares")
			.style(Styles.sweeperGrid)

			button(.id(IDs.sweeperFlag), .type(.button), .ariaPressed(false)) {
				"🚩 Flag Mode"
			}
			.style(Styles.smallButton)

			p(.id(IDs.sweeperStatus), .role("status")) {
				"Find the 10 Y2K bugs before midnight! Right-click, press F, hold a finger on a square, or use Flag Mode to flag a bug."
			}
			.style(Styles.statusBar)
		}
		.style(Styles.sweeper)
	}

	/**
	My secret diary in Notepad, behind a password, which is my favorite food. `geocities.js` checks the password and shows the diary.
	*/
	var notepad: some HTML {
		div {
			form(.id(IDs.diaryLock)) {
				p {
					gif(.diary)
				}
				.style(Styles.centeredText)

				p {
					"SECRET.TXT is protected. KEEP OUT!!! This means you, little sister."
				}

				div {
					label(.for(IDs.diaryPassword.id)) {
						"Password:"
					}

					input(
						.id(IDs.diaryPassword),
						.type(.password),
						.autocomplete("off"),
						.required,
						.maxlength(30)
					)
						.style(Styles.field, Styles.select)
				}
				.style(Styles.formRow)

				div {
					button(.type(.submit)) {
						"OK"
					}
					.style(Styles.retroButton)

					button(.id(IDs.diaryHint), .type(.button)) {
						"Hint"
					}
					.style(Styles.retroButton)
				}
				.style(Styles.row)
			}
			// The window already has the padding.
			.style {
				$0.flowSpacing(.rootEm(0.75))
			}

			p(.id(IDs.diaryStatus), .role("status")) {}

			label(.for(IDs.diaryText.id)) {
				"My diary"
			}
			.style(VisuallyHidden.Styles.root)

			textarea(
				.id(IDs.diaryText),
				.rows(12),
				.readonly,
				.hidden
			) {
				Self.diary
			}
			.style(Styles.field, Styles.notepad)
		}
	}

	/**
	Solitaire, where I already won: the four kings are on the piles. The button makes the cards jump off the piles and bounce down the window, like the win of Solitaire. `geocities.js` runs it.
	*/
	@HTMLBuilder
	var solitaire: some HTML {
		div {
			for suit in [(symbol: "♠", name: "spades", isRed: false), (symbol: "♥", name: "hearts", isRed: true), (symbol: "♣", name: "clubs", isRed: false), (symbol: "♦", name: "diamonds", isRed: true)] {
				p(.hook(Hooks.solitairePile), .role("img")) {
					"K\(suit.symbol)"
				}
				.accessibilityLabel("King of \(suit.name)")
				.style(suit.isRed ? Styles.redCard : Styles.card)
			}
		}
		.style(Styles.felt)

		p {
			"I already won! It took me 4 hours. The best part is the end, so here it is."
		}

		button(.id(IDs.solitaireWin), .type(.button)) {
			"Watch the Cards Jump!"
		}
		.style(Styles.retroButton)

		p(.id(IDs.solitaireStatus), .role("status")) {}
	}

	/**
	The System Properties of my computer, and a defragmenter that tidies up the hard drive, with the colored blocks of the one of Windows 98. `geocities.js` runs it.
	*/
	@HTMLBuilder
	var systemProperties: some HTML {
		dl {
			for (label, value) in [("System", "Microsoft Windows 98, Second Edition"), ("Registered to", "Sindre, Norway"), ("Computer", "iMac in Bondi Blue (yes, really)"), ("Memory", "32.0 MB RAM"), ("Hard drive", "4 GB, 3.9 GB full of GIFs")] {
				div {
					dt {
						"\(label):"
					}
					.style(Styles.factLabel)

					dd {
						value
					}
					.style(Styles.factValue)
				}
			}
		}
		.style(Styles.facts)

		button(.id(IDs.defragStart), .type(.button)) {
			"Defragment Drive C:"
		}
		.style(Styles.retroButton)

		div {
			for index in 0..<Self.defragBlockCount {
				span(.hook(Hooks.defragBlock, value: "\(index)")) {}
					.style(Styles.defragBlock)
			}
		}
		.accessibilityHidden()
		.style(Styles.defrag)

		p(.id(IDs.defragStatus), .role("status")) {
			"Drive C: is 61% fragmented. Ouch."
		}
		.style(Styles.statusBar)
	}

	/**
	The Recycle Bin, with the files I deleted. `geocities.js` empties it, after asking, like Windows.
	*/
	@HTMLBuilder
	var recycleBin: some HTML {
		ul(.id(IDs.recycleList)) {
			for (file, note) in Self.recycledFiles {
				li {
					strong {
						file
					}
					" "
					span {
						"(\(note))"
					}
					.style(Styles.caption)
				}
			}
		}
		.style(Styles.facts)

		button(.id(IDs.recycleEmpty), .type(.button)) {
			"Empty Recycle Bin"
		}
		.style(Styles.retroButton)

		p(.id(IDs.recycleStatus), .role("status")) {}
	}
}
