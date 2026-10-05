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
		template(.id(Hooks.saverCanvasTemplate)) {
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
		template(.id(Hooks.effectTemplate)) {
			canvas {}
				.accessibilityHidden()
				.style(Styles.effectCanvas)
		}

		// `geocities.js` adds a copy for each ball of the elastic trail and each number and dot of the clock that follow the mouse pointer.
		template(.id(Hooks.trailDotTemplate)) {
			span {}
				.accessibilityHidden()
				.style(Styles.trailDot)
		}

		// `geocities.js` shows a copy when the visitor clicks the skull: the blue screen of Windows 98, or the bomb of the Mac, until a key or a click.
		template(.id(Hooks.blueScreenTemplate)) {
			div(.role("alertdialog"), .ariaModal, .tabindex(-1), .ariaLabelledBy("geocities-blue-screen-title"), .ariaDescribedBy("geocities-blue-screen-text")) {
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

		template(.id(Hooks.bombTemplate)) {
			div {
				div(.role("alertdialog"), .ariaModal, .tabindex(-1), .ariaLabelledBy("geocities-bomb-title"), .ariaDescribedBy("geocities-bomb-text")) {
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
		template(.id(Hooks.shutDownTemplate)) {
			div(.role("dialog"), .ariaModal, .tabindex(-1), .ariaLabelledBy("geocities-shut-down-text")) {
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

			div(.id(Hooks.snakePhone)) {
				p {
					"PAPPA"
				}
				.accessibilityHidden()
				.style(Styles.phoneBrand)

				div {
					p(.id(Hooks.snakeScore)) {
						"Score: 0 ★ Best: 0"
					}
					.style(Styles.phoneScore)

					canvas(.id(Hooks.snakeScreen), .width(84), .height(48), .role("img")) {}
						.accessibilityLabel("The screen of the phone, with the snake")
						.style(Styles.phoneCanvas)

					p(.id(Hooks.snakeStatus), .role("status")) {
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

			div(.id(Hooks.desktop)) {
				ul {
					for app in Self.desktopApps {
						li {
							button(.type(.button), .hook(Hooks.desktopOpen, value: app.id)) {
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

				desktopWindow("paint", title: "untitled - Unicorn Paint") {
					Deferred(paint)
				}

				desktopWindow("sweeper", title: "Y2K Bugsweeper") {
					Deferred(sweeper)
				}

				desktopWindow("notepad", title: "SECRET.TXT - Notepad") {
					Deferred(notepad)
				}

				desktopWindow("solitaire", title: "Solitaire") {
					Deferred(solitaire)
				}

				desktopWindow("computer", title: "System Properties") {
					Deferred(systemProperties)
				}

				desktopWindow("recycle", title: "Recycle Bin") {
					Deferred(recycleBin)
				}

				Deferred(GeoCitiesWindows())

				div(.id(Hooks.startMenu), .hidden) {
					p {
						"Windows98"
					}
					.accessibilityHidden()
					.style(Styles.startMenuBanner)

					ul {
						GeoCitiesWindows.startMenuItems

						li {
							button(.id(Hooks.shutDown), .type(.button)) {
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
					button(.id(Hooks.startButton), .type(.button), .ariaExpanded(false), .ariaControls(Hooks.startMenu.rawValue)) {
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

					p(.id(Hooks.taskbarClock)) {
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
	A window of the desktop, with a title bar to drag it by and a close button. It is hidden until its icon opens it, and Escape closes it.
	*/
	func desktopWindow<Content: HTML>(_ app: String, title: String, @HTMLBuilder content: () -> Content) -> some HTML {
		section(.hook(Hooks.desktopWindow, value: app), .hidden, .tabindex(-1), .ariaLabelledBy("geocities-window-\(app)")) {
			div(.hook(Hooks.desktopTitleBar)) {
				h3(.id("geocities-window-\(app)")) {
					title
				}
				.style(Styles.desktopWindowTitle)

				button(.type(.button), .hook(Hooks.desktopClose)) {
					"×"
				}
				.accessibilityLabel("Close \(title)")
				.style(Styles.closeButton)
			}
			.style(Styles.titleBar, Styles.titleBarWithButton, Styles.desktopTitleBar)

			div {
				content()
			}
			.style(Styles.windowBody)
		}
		.style(Styles.window, Styles.desktopWindow)
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

				button(.id(Hooks.paintUndo), .type(.button)) {
					"Oops!"
				}
				.help("Undo")
				.style(Styles.paintButton)

				button(.id(Hooks.paintClear), .type(.button)) {
					gif(.dynamite)
					"Boom!"
				}
				.accessibilityLabel("Boom! Blow up the picture")
				.help("Blow up the picture")
				.style(Styles.paintButton)

				button(.id(Hooks.paintSave), .type(.button)) {
					"💾"
				}
				.accessibilityLabel("Save the picture")
				.help("Save the picture")
				.style(Styles.paintButton)
			}
			.accessibilityLabel("Tools")
			.style(Styles.paintTools)

			div(.id(Hooks.paintStamps), .role("group"), .hidden) {
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
				canvas(.id(Hooks.paintCanvas), .width(320), .height(200), .tabindex(0), .role("img")) {}
					.accessibilityLabel("Your picture. Draw with the mouse or a finger, or move the brush with the arrow keys and paint with Space.")
					.style(Styles.paintCanvas)

				span(.id(Hooks.paintCursor), .hidden) {}
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

			p(.id(Hooks.paintStatus), .role("status")) {
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
				p(.id(Hooks.sweeperBugs), .role("img")) {
					"010"
				}
				.accessibilityLabel("10 bugs left")
				.style(Styles.sweeperLED)

				button(.id(Hooks.sweeperFace), .type(.button)) {
					"🙂"
				}
				.accessibilityLabel("New game")
				.style(Styles.sweeperFace)

				p(.id(Hooks.sweeperTime)) {
					"000"
				}
				.accessibilityHidden()
				.style(Styles.sweeperLED)
			}
			.style(Styles.sweeperBar)

			div(.id(Hooks.sweeperGrid), .role("group")) {
				for index in 0..<(Self.sweeperSize * Self.sweeperSize) {
					button(.type(.button), .hook(Hooks.sweeperCell, value: "\(index)"), .tabindex(index == 0 ? 0 : -1)) {}
						.accessibilityLabel("Row \(index / Self.sweeperSize + 1), column \(index % Self.sweeperSize + 1)")
						.style(Styles.sweeperCell)
				}
			}
			.accessibilityLabel("Minefield of 9 by 9 squares")
			.style(Styles.sweeperGrid)

			button(.id(Hooks.sweeperFlag), .type(.button), .ariaPressed(false)) {
				"🚩 Flag Mode"
			}
			.style(Styles.smallButton)

			p(.id(Hooks.sweeperStatus), .role("status")) {
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
			form(.id(Hooks.diaryLock)) {
				p {
					gif(.diary)
				}
				.style(Styles.centeredText)

				p {
					"SECRET.TXT is protected. KEEP OUT!!! This means you, little sister."
				}

				div {
					label(.for(Hooks.diaryPassword.rawValue)) {
						"Password:"
					}

					input(.id(Hooks.diaryPassword), .type(.password), .autocomplete("off"), .required, .maxlength(30))
						.style(Styles.field, Styles.select)
				}
				.style(Styles.formRow)

				div {
					button(.type(.submit)) {
						"OK"
					}
					.style(Styles.retroButton)

					button(.id(Hooks.diaryHint), .type(.button)) {
						"Hint"
					}
					.style(Styles.retroButton)
				}
				.style(Styles.row)
			}
			.style(Styles.windowBody)

			p(.id(Hooks.diaryStatus), .role("status")) {}

			label(.for(Hooks.diaryText.rawValue)) {
				"My diary"
			}
			.style(VisuallyHidden.Styles.root)

			textarea(.id(Hooks.diaryText), .rows(12), .readonly, .hidden) {
				Self.diary
			}
			.style(Styles.field, Styles.notepad)
		}
	}

	/**
	Solitaire, where I already won: the four kings are on the piles. The button makes the cards jump off the piles and bounce down the window, like the win of Solitaire. `geocities.js` runs it.
	*/
	var solitaire: some HTML {
		div {
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

			button(.id(Hooks.solitaireWin), .type(.button)) {
				"Watch the Cards Jump!"
			}
			.style(Styles.retroButton)

			p(.id(Hooks.solitaireStatus), .role("status")) {}
		}
		.style(Styles.windowBody)
	}

	/**
	The System Properties of my computer, and a defragmenter that tidies up the hard drive, with the colored blocks of the one of Windows 98. `geocities.js` runs it.
	*/
	var systemProperties: some HTML {
		div {
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

			button(.id(Hooks.defragStart), .type(.button)) {
				"Defragment Drive C:"
			}
			.style(Styles.retroButton)

			div(.id(Hooks.defrag)) {
				for index in 0..<Self.defragBlockCount {
					span(.hook(Hooks.defragBlock, value: "\(index)")) {}
						.style(Styles.defragBlock)
				}
			}
			.accessibilityHidden()
			.style(Styles.defrag)

			p(.id(Hooks.defragStatus), .role("status")) {
				"Drive C: is 61% fragmented. Ouch."
			}
			.style(Styles.statusBar)
		}
		.style(Styles.windowBody)
	}

	/**
	The Recycle Bin, with the files I deleted. `geocities.js` empties it, after asking, like Windows.
	*/
	var recycleBin: some HTML {
		div {
			ul(.id(Hooks.recycleList)) {
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

			button(.id(Hooks.recycleEmpty), .type(.button)) {
				"Empty Recycle Bin"
			}
			.style(Styles.retroButton)

			p(.id(Hooks.recycleStatus), .role("status")) {}
		}
		.style(Styles.windowBody)
	}
}
