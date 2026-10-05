import Elementary
import Foundation
import SiteKit

extension GeoCitiesWindows {
	/**
	The keys of Calculator, in its rows, with what a screen reader says for the ones with a symbol.
	*/
	static let calculatorKeys: [(key: String, name: String?)] = [
		("MC", "Memory clear"), ("7", nil), ("8", nil), ("9", nil), ("/", "Divide"), ("sqrt", "Square root"),
		("MR", "Memory recall"), ("4", nil), ("5", nil), ("6", nil), ("*", "Multiply"), ("%", "Percent"),
		("MS", "Memory store"), ("1", nil), ("2", nil), ("3", nil), ("-", "Minus"), ("1/x", "Reciprocal"),
		("M+", "Memory add"), ("0", nil), ("+/-", "Change sign"), (".", "Decimal point"), ("+", "Plus"), ("=", "Equals"),
	]

	/**
	Calculator, which calculates for real, except for the famous bugs of the time: the subtraction of the Calculator of Windows 3.1, the division of the first Pentium, the year after 1999, and dividing by zero. The upside-down button turns it over, like the calculators at school, where 0.7734 says hELLO. `geocities-windows.js` runs it, also with the keys of the keyboard.
	*/
	var calculator: some HTML {
		div {
			div {
				output(.id(Hooks.calcDisplay)) {
					"0."
				}
				.accessibilityLabel("Display")
				.style(Styles.calcDisplay)
			}
			.style(Styles.calcScreen)

			div {
				p(.id(Hooks.calcMemory)) {}
					.accessibilityHidden()
					.style(Styles.calcMemory)

				for (key, name) in [("Backspace", "Backspace"), ("CE", "Clear entry"), ("C", "Clear")] {
					button(.type(.button), .hook(Hooks.calcKey, value: key)) {
						key
					}
					.accessibilityLabel(name)
					.style(Styles.calcRedKey)
				}
			}
			.style(Styles.calcTopRow)

			div(.role("group")) {
				for (key, name) in Self.calculatorKeys {
					button(.type(.button), .hook(Hooks.calcKey, value: key)) {
						key
					}
					.attributes(.custom(name: "aria-label", value: name ?? key), when: name != nil)
					.style(key.first?.isNumber == true || key == "." ? Styles.calcBlueKey : Styles.calcRedKey)
				}
			}
			.accessibilityLabel("Keys")
			.style(Styles.calcKeys)

			button(.id(Hooks.calcFlip), .type(.button), .ariaPressed(false)) {
				"🙃 Turn Upside Down"
			}
			.style(GeoCitiesPage.Styles.smallButton)

			p(.id(Hooks.calcStatus), .role("status")) {
				"Click the keys, or type. Try 2 + 2, or 1999 + 1."
			}
			.style(GeoCitiesPage.Styles.statusBar)
		}
		.style(Styles.stack)
	}

	/**
	The MS-DOS Prompt, a black window with a prompt that understands the commands of DOS, like `dir`, `cd`, `ver`, `mem`, `type`, and `format`, and the floppy drive that is never ready. `geocities-windows.js` runs the commands.
	*/
	var dosPrompt: some HTML {
		div {
			div(.id(Hooks.dosOutput), .role("log")) {
				"Microsoft(R) Windows 98\n   (C)Copyright Microsoft Corp 1981-1999.\n\nType HELP for a list of commands.\n"
			}
			.style(Styles.dosOutput)

			form(.id(Hooks.dosForm)) {
				label(.id(Hooks.dosPrompt), .for(Hooks.dosInput.rawValue)) {
					"C:\\WINDOWS>"
				}

				input(.id(Hooks.dosInput), .type(.text), .autocomplete("off"), .maxlength(80), .custom(name: "autocapitalize", value: "off"), .custom(name: "autocorrect", value: "off"), .custom(name: "spellcheck", value: "false"))
					.style(Styles.dosInput)
			}
			.style(Styles.dosLine)
		}
		.style(Styles.dos)
	}

	/**
	My letter to Santa for the year 2000 in WordPad, as the letter for 1999 is in the Recycle Bin. The fonts include Wingdings, which turns the letter into symbols. An Office Assistant pops up to help, whether I want it or not. `geocities-windows.js` runs it.
	*/
	var wordPad: some HTML {
		div {
			div {
				GeoCitiesWindows.hiddenLabel("Font", for: .wordpadFont)

				select(.id(Hooks.wordpadFont)) {
					for font in ["Times New Roman", "Arial", "Comic Sans MS", "Courier New", "Wingdings"] {
						option(.value(font)) {
							font
						}
					}
				}
				.style(Styles.toolbarSelect)

				GeoCitiesWindows.hiddenLabel("Font size", for: .wordpadSize)

				select(.id(Hooks.wordpadSize)) {
					for size in ["10", "12", "18", "24", "36", "72"] {
						option(.value(size)) {
							size
						}
						.attributes(.selected, when: size == "12")
					}
				}
				.style(Styles.toolbarSelect)

				for (format, title, name) in [("bold", "B", "Bold"), ("italic", "I", "Italic"), ("underline", "U", "Underline")] {
					button(.type(.button), .hook(Hooks.wordpadFormat, value: format), .ariaPressed(false)) {
						title
					}
					.accessibilityLabel(name)
					.style(Styles.toolbarButton)
				}
			}
			.style(Styles.toolbar)

			div {
				GeoCitiesWindows.hiddenLabel("My letter to Santa", for: .wordpadText)

				textarea(.id(Hooks.wordpadText), .rows(12)) {
					Self.letterToSanta
				}
				.style(Styles.wordpadText)

				p(.id(Hooks.wordpadWingdings), .hidden, .role("img")) {}
					.accessibilityLabel("My letter to Santa, in Wingdings")
					.style(Styles.wordpadText, Styles.wingdings)

				div(.id(Hooks.assistant), .hidden) {
					p {
						"📎"
						span {
							"👀"
						}
						.style(Styles.assistantEyes)
					}
					.accessibilityHidden()
					.style(Styles.assistantClip)

					div {
						p(.id(Hooks.assistantText), .role("status")) {}

						div {
							for (choice, title) in [("help", "Get help with writing the letter"), ("alone", "Just type the letter without help"), ("never", "Don’t show me this tip again")] {
								button(.type(.button), .hook(Hooks.assistantChoice, value: choice)) {
									title
								}
								.style(Styles.assistantChoice)
							}
						}
						.style(Styles.stack)
					}
					.style(Styles.assistantBalloon)
				}
				.style(Styles.assistant)
			}
			.style(Styles.wordpadPage)

			p(.id(Hooks.wordpadStatus), .role("status")) {
				"For Help, press F1. (F1 does nothing.)"
			}
			.style(GeoCitiesPage.Styles.statusBar)
		}
		.style(Styles.stack)
	}

	/**
	Internet Explorer 5, with a start page that asks “Where do you want to go today?”, Dial-Up Networking that connects first, and “The page cannot be displayed” for most of the web. `geocities-windows.js` shows the pages from the templates.
	*/
	var internetExplorer: some HTML {
		div {
			div {
				for (action, title, icon) in [("back", "Back", "⬅️"), ("forward", "Forward", "➡️"), ("stop", "Stop", "⛔"), ("refresh", "Refresh", "🔄"), ("home", "Home", "🏠")] {
					button(.type(.button), .hook(Hooks.ieAction, value: action)) {
						span {
							icon
						}
						.accessibilityHidden()

						span {
							title
						}
						.style(Styles.toolbarLabel)
					}
					.accessibilityLabel(title)
					.style(Styles.toolbarButton)
				}

				span {
					"e"
				}
				.accessibilityHidden()
				.style(Styles.ieThrobber)
			}
			.style(Styles.toolbar)

			form(.id(Hooks.ieForm)) {
				label(.for(Hooks.ieAddress.rawValue)) {
					"Address"
				}

				input(.id(Hooks.ieAddress), .type(.text), .value("about:home"), .autocomplete("off"), .custom(name: "autocapitalize", value: "off"), .custom(name: "spellcheck", value: "false"))
					.style(GeoCitiesPage.Styles.field)

				button(.type(.submit)) {
					"Go"
				}
				.style(GeoCitiesPage.Styles.retroButton)
			}
			.style(Styles.ieAddressBar)

			div(.id(Hooks.iePage), .role("region"), .tabindex(-1), .custom(name: "aria-live", value: "polite")) {}
				.accessibilityLabel("Web page")
				.style(Styles.iePage)

			div {
				p(.id(Hooks.ieStatus)) {
					"Done"
				}

				span {
					span(.id(Hooks.ieProgress)) {}
						.style(Styles.progressFill)
				}
				.accessibilityHidden()
				.style(Styles.progressTrack)
			}
			.style(GeoCitiesPage.Styles.statusBar, Styles.ieStatusBar)

			ieTemplates
		}
		.style(Styles.stack)
	}

	/**
	The pages of Internet Explorer. `geocities-windows.js` copies one into the window, and fills in the address where a page shows it.
	*/
	@HTMLBuilder
	private var ieTemplates: some HTML {
		template(.hook(Hooks.iePageTemplate, value: "home")) {
			div {
				h4 {
					"Where do you want to go today?"
				}
				.style(Styles.ieHeadline)

				p {
					"Welcome to the World Wide Web! There are almost 4 million web sites now. Here are the best ones:"
				}

				ul {
					for (address, title) in [("sindresorhus.com/1999", "Sindre’s Home Page (the best one)"), ("www.download-more-ram.com", "Download More RAM for FREE"), ("windowsupdate.microsoft.com", "Windows Update"), ("www.y2k-survival.com", "Y2K Survival Guide"), ("www.unicorns.no", "Unicorns of Norway")] {
						li {
							button(.type(.button), .hook(Hooks.ieGo, value: address)) {
								title
							}
							.style(Styles.ieLink)
						}
					}
				}
				.style(Styles.ieLinks)
			}
			.style(Styles.iePageContent)
		}

		template(.hook(Hooks.iePageTemplate, value: "error")) {
			div {
				h4 {
					"The page cannot be displayed"
				}
				.style(Styles.ieErrorTitle)

				p {
					"The page you are looking for is currently unavailable. The Web site might be experiencing technical difficulties, or you may need to adjust your browser settings."
				}

				hr()

				p {
					"Please try the following:"
				}

				ul {
					li {
						"Click the Refresh button, or try again later."
					}

					li {
						"If you typed the page address in the Address bar, make sure that it is spelled correctly: "
						strong(.hook(Hooks.ieSlot)) {}
					}

					li {
						"Ask your big brother. He knows computers."
					}
				}

				p {
					"Cannot find server or DNS Error"
					br()
					"Internet Explorer"
				}
				.style(GeoCitiesPage.Styles.caption)
			}
			.style(Styles.iePageContent)
		}

		template(.hook(Hooks.iePageTemplate, value: "offline")) {
			div {
				h4 {
					"Web page unavailable while offline"
				}
				.style(Styles.ieErrorTitle)

				p {
					"The Web page you requested is not available offline. To view this page, click Connect."
				}

				button(.type(.button), .hook(Hooks.ieAction, value: "connect")) {
					"Connect"
				}
				.style(GeoCitiesPage.Styles.retroButton)
			}
			.style(Styles.iePageContent)
		}

		template(.hook(Hooks.iePageTemplate, value: "here")) {
			div {
				h4 {
					"Sindre’s Home Page"
				}
				.style(Styles.ieHeadline)

				p {
					"You are already here. This is my computer, on my page, in my computer, on my page…"
				}

				div {
					div {
						div {
							div {
								"🦄"
							}
							.style(Styles.ieDroste)
						}
						.style(Styles.ieDroste)
					}
					.style(Styles.ieDroste)
				}
				.accessibilityHidden()
				.style(Styles.ieDroste)
			}
			.style(Styles.iePageContent)
		}

		template(.hook(Hooks.iePageTemplate, value: "unicorns")) {
			div {
				h4 {
					"🦄 Unicorns of Norway 🦄"
				}
				.style(Styles.ieHeadline)

				p {
					"Velkommen! This is the official list of all the unicorns in Norway:"
				}

				ol {
					li {
						"Glitter (Bergen)"
					}

					li {
						"Glitter Jr. (Bergen, stuffed)"
					}

					li {
						"A horse with an ice cream cone on its head (Bergen, not confirmed)"
					}
				}

				p {
					"Seen a unicorn? Mail us! Last updated: 12.03.1997"
				}
				.style(GeoCitiesPage.Styles.caption)
			}
			.style(Styles.iePageContent)
		}

		template(.hook(Hooks.iePageTemplate, value: "y2k")) {
			div {
				h4 {
					"Y2K Survival Guide"
				}
				.style(Styles.ieHeadline)

				p {
					"The year 2000 is coming! Be ready when the computers stop:"
				}

				ul {
					li {
						"Fill the bathtub with water."
					}

					li {
						"Buy 500 candles and 50 kg of brunost."
					}

					li {
						"Print out the whole Internet, in case it goes away."
					}

					li {
						"Take your money out of the bank, and put it under the mattress."
					}
				}

				p {
					"This page is Y2K compliant. Probably."
				}
				.style(GeoCitiesPage.Styles.caption)
			}
			.style(Styles.iePageContent)
		}

		template(.hook(Hooks.iePageTemplate, value: "ram")) {
			div {
				h4 {
					"Download More RAM for FREE!!!"
				}
				.style(Styles.ieHeadline)

				p {
					"Is your computer slow? Download 32 MB of RAM in seconds! 100% legal. Works with any modem."
				}

				button(.type(.button), .hook(Hooks.ieAction, value: "ram")) {
					"Download RAM Now"
				}
				.style(GeoCitiesPage.Styles.retroButton)
			}
			.style(Styles.iePageContent)
		}

		template(.hook(Hooks.iePageTemplate, value: "update")) {
			div {
				h4 {
					"Windows Update"
				}
				.style(Styles.ieHeadline)

				p {
					"Windows Update has scanned your computer. There are 1,999 critical updates for you, about 2 GB."
				}

				p {
					"Estimated download time at 28.8 Kbps: 6 days, 21 hours."
				}

				button(.type(.button), .hook(Hooks.ieAction, value: "update")) {
					"Install Now"
				}
				.style(GeoCitiesPage.Styles.retroButton)
			}
			.style(Styles.iePageContent)
		}
	}

	/**
	Dial-Up Networking, which calls the Internet over the phone line, if nobody in the family is on the phone. `geocities-windows.js` runs it.
	*/
	var dialUp: some HTML {
		div {
			p {
				span {
					"📞"
				}
				.accessibilityHidden()

				strong {
					" Telenor Internett"
				}
			}

			dl {
				for (label, value) in [("User name", "sindre"), ("Password", "••••••••"), ("Phone number", "815 00 999"), ("Dialing from", "Home (Bergen)")] {
					div {
						dt {
							"\(label):"
						}
						.style(GeoCitiesPage.Styles.factLabel)

						dd {
							value
						}
						.style(GeoCitiesPage.Styles.factValue)
					}
				}
			}
			.style(GeoCitiesPage.Styles.facts)

			div {
				button(.id(Hooks.dialUpConnect), .type(.button)) {
					"Connect"
				}
				.style(GeoCitiesPage.Styles.retroButton)

				button(.id(Hooks.dialUpDisconnect), .type(.button), .hidden) {
					"Disconnect"
				}
				.style(GeoCitiesPage.Styles.retroButton)
			}
			.style(GeoCitiesPage.Styles.row)

			p(.id(Hooks.dialUpStatus), .role("status")) {
				"Not connected."
			}
			.style(GeoCitiesPage.Styles.statusBar)
		}
		.style(Styles.stack)
	}

	/**
	Network Neighborhood: the computers of the house, on a cable to the living room. Mamma shares her shopping list, Pappa shares nothing, and my little sister shares more than she thinks.
	*/
	var networkNeighborhood: some HTML {
		div {
			div {
				button(.id(Hooks.networkUp), .type(.button), .disabled) {
					"⬆️ Up"
				}
				.style(GeoCitiesPage.Styles.smallButton)

				p(.id(Hooks.networkPath)) {
					"Network Neighborhood"
				}
				.style(Styles.addressField)
			}
			.style(Styles.toolbar)

			ul(.id(Hooks.networkList)) {}
				.accessibilityLabel("Computers")
				.style(Styles.fileList)

			p(.id(Hooks.networkStatus), .role("status")) {}
				.style(GeoCitiesPage.Styles.statusBar)
		}
		.style(Styles.stack)
	}

	/**
	Notepad, for the text files of My Documents, the network, and the mail.
	*/
	var textViewer: some HTML {
		div {
			GeoCitiesWindows.hiddenLabel("The text of the file", for: .viewerText)

			textarea(.id(Hooks.viewerText), .rows(12), .readonly) {}
				.style(GeoCitiesPage.Styles.field, GeoCitiesPage.Styles.notepad)
		}
	}

	/**
	Media Player, which plays DANCING BABY.AVI, after buffering. The video is the GIF of the dancing baby, and the still frame while it is stopped.
	*/
	var mediaPlayer: some HTML {
		div {
			div {
				img(.id(Hooks.mediaVideo), .src(GeoCitiesPage.GIF.dancingBaby.stillPath), .alt("The dancing baby"), .width(160), .height(120), .hook(Hooks.mediaAnimated, value: GeoCitiesPage.GIF.dancingBaby.path.description))
					.style(Styles.mediaVideo)

				p(.id(Hooks.mediaBuffering), .hidden) {}
					.style(Styles.mediaBuffering)
			}
			.style(Styles.mediaScreen)

			div {
				for (action, title, icon) in [("play", "Play", "▶"), ("pause", "Pause", "⏸"), ("stop", "Stop", "⏹")] {
					button(.type(.button), .hook(Hooks.mediaAction, value: action)) {
						icon
					}
					.accessibilityLabel(title)
					.style(GeoCitiesPage.Styles.smallButton)
				}

				span {
					span(.id(Hooks.mediaProgress)) {}
						.style(Styles.progressFill)
				}
				.accessibilityHidden()
				.style(Styles.progressTrack, Styles.grow)

				span(.id(Hooks.mediaTime)) {
					"00:00 / 00:15"
				}
				.style(Styles.lcdSmall)
			}
			.style(Styles.toolbar)

			p(.id(Hooks.mediaStatus), .role("status")) {
				"Stopped"
			}
			.style(GeoCitiesPage.Styles.statusBar)
		}
		.style(Styles.stack)
	}

	/**
	Sound Recorder, with the green line of the sound, which records from the microphone for up to 60 seconds, like the one of Windows, or plays TADA.WAV. Its Effects menu makes the sound faster, slower, louder, backwards, or adds an echo. `geocities-windows.js` runs it with Web Audio.
	*/
	var soundRecorder: some HTML {
		div {
			div {
				p {
					"Position:"
					br()
					span(.id(Hooks.soundPosition)) {
						"0.00 sec."
					}
				}
				.style(Styles.soundLabel)

				canvas(.id(Hooks.soundWave), .width(160), .height(48), .role("img")) {}
					.accessibilityLabel("The green line of the sound")
					.style(Styles.soundWave)

				p {
					"Length:"
					br()
					span(.id(Hooks.soundLength)) {
						"0.00 sec."
					}
				}
				.style(Styles.soundLabel)
			}
			.style(Styles.soundTop)

			div(.role("group")) {
				for (action, title, icon) in [("start", "Seek to Start", "⏮"), ("end", "Seek to End", "⏭"), ("play", "Play", "▶"), ("stop", "Stop", "⏹"), ("record", "Record", "⏺")] {
					button(.type(.button), .hook(Hooks.soundAction, value: action)) {
						icon
					}
					.accessibilityLabel(title)
					.help(title)
					.style(action == "record" ? Styles.recordButton : Styles.soundButton)
				}
			}
			.accessibilityLabel("Controls")
			.style(Styles.soundControls)

			div(.role("group")) {
				for (effect, title) in [("louder", "Louder"), ("faster", "Faster"), ("slower", "Slower"), ("echo", "Echo"), ("reverse", "Reverse"), ("tada", "TADA.WAV")] {
					button(.type(.button), .hook(Hooks.soundEffect, value: effect)) {
						title
					}
					.style(GeoCitiesPage.Styles.smallButton)
				}
			}
			.accessibilityLabel("Effects")
			.style(Styles.wrapRow)

			p(.id(Hooks.soundStatus), .role("status")) {
				"Press ⏺ to record your voice with the microphone, or ▶ to play TADA.WAV (with sound)."
			}
			.style(GeoCitiesPage.Styles.statusBar)
		}
		.style(Styles.stack)
	}

	/**
	FreeCell, with the deals of the FreeCell of Windows: each game number deals the same cards, and game #11982 is the one that nobody can win. A click picks up the cards, and another click puts them down. `geocities-windows.js` runs it.
	*/
	var freeCell: some HTML {
		div {
			div {
				div {
					div(.role("group")) {
						for index in 0..<4 {
							button(.type(.button), .hook(Hooks.freecellCell, value: "\(index)")) {}
								.accessibilityLabel("Free cell \(index + 1), empty")
								.style(Styles.cardSlot)
						}
					}
					.accessibilityLabel("Free cells")
					.style(Styles.cardSlots)

					span(.id(Hooks.freecellKing)) {
						"🤴"
					}
					.accessibilityHidden()
					.style(Styles.freecellKing)

					div(.role("group")) {
						for (index, suit) in ["♣", "♦", "♥", "♠"].enumerated() {
							button(.type(.button), .hook(Hooks.freecellHome, value: "\(index)")) {
								span {
									suit
								}
								.style(Styles.slotSuit)
							}
							.accessibilityLabel("Home cell \(index + 1), empty")
							.style(Styles.cardSlot)
						}
					}
					.accessibilityLabel("Home cells")
					.style(Styles.cardSlots)
				}
				.style(Styles.freecellTop)

				div(.role("group")) {
					for index in 0..<8 {
						button(.type(.button), .hook(Hooks.freecellColumn, value: "\(index)")) {}
							.style(Styles.freecellColumn)
					}
				}
				.accessibilityLabel("Columns")
				.style(Styles.freecellColumns)
			}
			.style(Styles.freecellTable)

			template(.id(Hooks.cardTemplate)) {
				span {}
					.accessibilityHidden()
					.style(Styles.card)
			}

			form(.id(Hooks.freecellForm)) {
				button(.id(Hooks.freecellUndo), .type(.button), .disabled) {
					"Undo"
				}
				.style(GeoCitiesPage.Styles.smallButton)

				label(.for(Hooks.freecellNumber.rawValue)) {
					"Game #"
				}

				input(.id(Hooks.freecellNumber), .type(.number), .min(1), .max(32000), .value("1"))
					.style(Styles.numberField)

				button(.type(.submit)) {
					"Deal"
				}
				.style(GeoCitiesPage.Styles.smallButton)

				button(.id(Hooks.freecellRandom), .type(.button)) {
					"New Game"
				}
				.style(GeoCitiesPage.Styles.smallButton)
			}
			.style(Styles.wrapRow)

			p(.id(Hooks.freecellStatus), .role("status")) {}
				.style(GeoCitiesPage.Styles.statusBar)
		}
		.style(Styles.stack)
	}

	/**
	The Control Panel, whose settings really change the desktop: the wallpaper, the colors of the windows, the screen saver, large icons, the Active Desktop, the desktop themes of Microsoft Plus! with their icons and sounds, the date (with the year 2000 at your own risk), the mouse, new hardware, and programs to remove. `geocities-windows.js` runs it.
	*/
	var controlPanel: some HTML {
		div {
			ul(.id(Hooks.controlHome)) {
				for (pane, title, icon) in [("display", "Display", "🖥️"), ("themes", "Desktop Themes", "🎭"), ("date", "Date/Time", "📅"), ("mouse", "Mouse", "🖱️"), ("hardware", "Add New Hardware", "🔌"), ("programs", "Add/Remove Programs", "📦")] {
					li {
						button(.type(.button), .hook(Hooks.controlOpen, value: pane)) {
							span {
								icon
							}
							.accessibilityHidden()
							.style(GeoCitiesPage.Styles.desktopIconPicture)

							span {
								title
							}
						}
						.style(Styles.fileButton)
					}
				}
			}
			.accessibilityLabel("Settings")
			.style(Styles.fileList)

			controlPane("display", title: "Display Properties") {
				label(.for(Hooks.wallpaperPicker.rawValue)) {
					"Wallpaper:"
				}
				.style(GeoCitiesPage.Styles.label)

				select(.id(Hooks.wallpaperPicker)) {
					for (value, title) in Self.wallpapers {
						option(.value(value)) {
							title
						}
					}
				}
				.style(GeoCitiesPage.Styles.field)

				label(.for(Hooks.scheme.rawValue)) {
					"Appearance:"
				}
				.style(GeoCitiesPage.Styles.label)

				select(.id(Hooks.scheme)) {
					for scheme in Self.schemes {
						option(.value(scheme)) {
							scheme
						}
					}
				}
				.style(GeoCitiesPage.Styles.field)

				div {
					label(.for(Hooks.saver.rawValue)) {
						"Screen Saver:"
					}

					select(.id(Hooks.saver)) {
						for (saver, title) in [("maze", "3D Maze"), ("flying", "Flying Windows"), ("marquee", "Scrolling Marquee")] {
							option(.value(saver)) {
								title
							}
						}
					}

					button(.id(Hooks.saverPreview), .type(.button)) {
						"Preview"
					}
					.style(GeoCitiesPage.Styles.smallButton)
				}
				.style(Styles.wrapRow)

				label(.for(Hooks.marqueeText.rawValue)) {
					"Text of the Scrolling Marquee:"
				}
				.style(GeoCitiesPage.Styles.label)

				input(.id(Hooks.marqueeText), .type(.text), .value("Sindre’s computer. Hands off, little sister!"), .maxlength(60), .autocomplete("off"))
					.style(GeoCitiesPage.Styles.field)

				label {
					input(.id(Hooks.largeIconsToggle), .type(.checkbox))
					" Use large icons"
				}
				.style(GeoCitiesPage.Styles.label)

				label {
					input(.id(Hooks.webToggle), .type(.checkbox))
					" View my Active Desktop as a web page"
				}
				.style(GeoCitiesPage.Styles.label)
			}

			controlPane("themes", title: "Desktop Themes (Microsoft Plus! 98)") {
				label(.for(Hooks.theme.rawValue)) {
					"Theme:"
				}
				.style(GeoCitiesPage.Styles.label)

				select(.id(Hooks.theme)) {
					for (value, title) in Self.themes {
						option(.value(value)) {
							title
						}
					}
				}
				.style(GeoCitiesPage.Styles.field)

				p {
					"A theme changes the wallpaper, the colors, the icons, and the sounds of the desktop."
				}
				.style(GeoCitiesPage.Styles.caption)

				label {
					input(.id(Hooks.themeSounds), .type(.checkbox))
					" Sound events (plays a sound when a window opens)"
				}
				.style(GeoCitiesPage.Styles.label)
			}

			controlPane("date", title: "Date/Time Properties") {
				div {
					GeoCitiesWindows.hiddenLabel("Month", for: .dateMonth)

					select(.id(Hooks.dateMonth)) {
						for (index, month) in ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"].enumerated() {
							option(.value("\(index)")) {
								month
							}
							.attributes(.selected, when: index == 11)
						}
					}

					GeoCitiesWindows.hiddenLabel("Year", for: .dateYear)

					input(.id(Hooks.dateYear), .type(.number), .min(1980), .max(2099), .value("1999"))
						.style(Styles.numberField)
				}
				.style(Styles.wrapRow)

				div {
					for day in ["S", "M", "T", "W", "T", "F", "S"] {
						span {
							day
						}
						.style(Styles.calendarHead)
					}

					for index in 0..<42 {
						span(.hook(Hooks.dateDay, value: "\(index)")) {}
							.style(Styles.calendarDay)
					}
				}
				.accessibilityHidden()
				.style(Styles.calendar)

				button(.id(Hooks.dateApply), .type(.button)) {
					"Apply"
				}
				.style(GeoCitiesPage.Styles.retroButton)
			}

			controlPane("mouse", title: "Mouse Properties") {
				p {
					"Double-click speed: double-click the box to test it."
				}

				button(.id(Hooks.jackBox), .type(.button)) {
					"🎁"
				}
				.accessibilityLabel("Test area: double-click the box, or press Enter twice")
				.style(Styles.jackBox)

				label(.for(Hooks.doubleClickSpeed.rawValue)) {
					"Double-click speed: Slow to Fast"
				}
				.style(GeoCitiesPage.Styles.label)

				input(.id(Hooks.doubleClickSpeed), .type(.range), .min(0), .max(4), .value("2"))
					.style(Styles.volumeSlider)

				label {
					input(.id(Hooks.shyIcons), .type(.checkbox))
					" Shy icons: the icons run away from the pointer (the keyboard still catches them)"
				}
				.style(GeoCitiesPage.Styles.label)
			}

			controlPane("hardware", title: "Add New Hardware Wizard") {
				p(.id(Hooks.hardwareText)) {
					"This wizard installs the software for a new hardware device. Plug in your new scanner now, then click Next."
				}

				span {
					span(.id(Hooks.hardwareProgress)) {}
						.style(Styles.progressFill)
				}
				.accessibilityHidden()
				.style(Styles.progressTrack)

				button(.id(Hooks.hardwareNext), .type(.button)) {
					"Next >"
				}
				.style(GeoCitiesPage.Styles.retroButton)
			}

			controlPane("programs", title: "Add/Remove Programs Properties") {
				p {
					"To remove a program, select it and click Remove."
				}

				ul {
					for (program, title) in [("ie", "Microsoft Internet Explorer 5"), ("bonzi", "BonziBUDDY"), ("y2k", "Y2K Bug"), ("furby", "Furby Translator 1.0"), ("windows", "Windows 98")] {
						li {
							span {
								title
							}

							button(.type(.button), .hook(Hooks.removeProgram, value: program)) {
								"Remove"
							}
							.style(GeoCitiesPage.Styles.smallButton)
						}
						.style(Styles.programRow)
					}
				}
				.style(Styles.stack)
			}

			p(.id(Hooks.controlStatus), .role("status")) {}
				.style(GeoCitiesPage.Styles.statusBar)
		}
		.style(Styles.stack)
	}

	/**
	A part of the Control Panel, like the Display Properties, with a button back to the icons.
	*/
	private func controlPane<Content: HTML>(_ pane: String, title: String, @HTMLBuilder content: () -> Content) -> some HTML {
		div(.hook(Hooks.controlPane, value: pane), .hidden) {
			div {
				button(.type(.button), .hook(Hooks.controlBack)) {
					"◀ Control Panel"
				}
				.style(GeoCitiesPage.Styles.smallButton)

				h4 {
					title
				}
				.style(Styles.paneTitle)
			}
			.style(Styles.toolbar)

			content()
		}
		.style(Styles.stack)
	}

	/**
	The wallpapers of the Display Properties, by their value in `geocities-windows.js`.
	*/
	static let wallpapers: [(value: String, title: String)] = [
		("none", "(None)"),
		("clouds", "Clouds"),
		("thatch", "Black Thatch"),
		("waffle", "Waffle"),
		("unicorns", "Unicorns"),
		("circuit", "Circuit Board"),
		("jungle", "Jungle"),
		("cat", "Kit-Cat Klock"),
		("mustard", "Ketchup and Mustard"),
	]

	/**
	The color schemes of the windows, like those of Windows 95. Hot Dog Stand came with Windows 3.1, and it was not a joke.
	*/
	static let schemes = ["Windows Standard", "Hot Dog Stand", "High Contrast Black", "Rainy Day", "Eggplant", "Unicorn"]

	/**
	The desktop themes of Microsoft Plus! 98, by their value in `geocities-windows.js`, which has their wallpapers, colors, icons, and sounds.
	*/
	static let themes: [(value: String, title: String)] = [
		("standard", "Windows Default"),
		("unicorns", "Unicorns 1999"),
		("creatures", "Dangerous Creatures"),
		("computer", "Inside Your Computer"),
		("hotdog", "Hot Dog Stand"),
	]

	/**
	Y2K Fixer 2000 Deluxe, a program that makes the computer ready for the year 2000, until it stops responding at 99%. Then the window leaves copies of itself where it is dragged, like when Windows hung, and it ends with “This program has performed an illegal operation”.
	*/
	var y2kFixer: some HTML {
		div {
			p {
				"Y2K FIXER 2000"
				br()
				"DELUXE"
			}
			.style(Styles.fixerLogo)

			p(.id(Hooks.fixerText)) {
				"Is your computer ready for the year 2000? 99% of computers are not! Y2K Fixer 2000 fixes all your dates in minutes."
			}

			span {
				span(.id(Hooks.fixerProgress)) {}
					.style(Styles.progressFill)
			}
			.accessibilityHidden()
			.style(Styles.progressTrack)

			button(.id(Hooks.fixerStart), .type(.button)) {
				"Fix My Computer!"
			}
			.style(GeoCitiesPage.Styles.retroButton)
		}
		.style(Styles.stack, Styles.fixerBody)
	}

	/**
	Find, which searches the hard drive for files with the magnifying glass going around a folder, and finds them.
	*/
	var findFiles: some HTML {
		div {
			form(.id(Hooks.findForm)) {
				label(.for(Hooks.findName.rawValue)) {
					"Named:"
				}
				.style(GeoCitiesPage.Styles.label)

				input(.id(Hooks.findName), .type(.text), .autocomplete("off"), .maxlength(40), .custom(name: "spellcheck", value: "false"))
					.style(GeoCitiesPage.Styles.field)

				div {
					button(.type(.submit)) {
						"Find Now"
					}
					.style(GeoCitiesPage.Styles.retroButton)

					p(.id(Hooks.findAnimation), .hidden) {
						span {
							"📁"
						}

						span {
							"🔍"
						}
						.style(Styles.findGlass)
					}
					.accessibilityHidden()
					.style(Styles.findAnimation)
				}
				.style(GeoCitiesPage.Styles.row)
			}
			.style(Styles.stack)

			ul(.id(Hooks.findResults)) {}
				.accessibilityLabel("Files found")
				.style(Styles.fileList)

			p(.id(Hooks.findStatus), .role("status")) {
				"Type a name, like homework, unicorn, or *."
			}
			.style(GeoCitiesPage.Styles.statusBar)
		}
		.style(Styles.stack)
	}

	/**
	The Run dialog, which runs programs and commands by their names, like `calc`, `winver`, and `format c:`, and says what all others say: “Cannot find the file”.
	*/
	var runDialog: some HTML {
		form(.id(Hooks.runForm)) {
			p {
				"Type the name of a program, folder, or document, and Windows will open it for you."
			}

			div {
				label(.for(Hooks.runInput.rawValue)) {
					"Open:"
				}

				input(.id(Hooks.runInput), .type(.text), .autocomplete("off"), .maxlength(60), .custom(name: "autocapitalize", value: "off"), .custom(name: "spellcheck", value: "false"))
					.style(GeoCitiesPage.Styles.field)
			}
			.style(Styles.nowrapRow)

			p {
				"Try calc, command, winver, freecell, scandisk, regedit, or format c:."
			}
			.style(GeoCitiesPage.Styles.caption)

			div {
				button(.type(.submit)) {
					"OK"
				}
				.style(GeoCitiesPage.Styles.retroButton)

				GeoCitiesWindows.closeButton()

				button(.id(Hooks.runBrowse), .type(.button)) {
					"Browse…"
				}
				.style(GeoCitiesPage.Styles.retroButton)
			}
			.style(GeoCitiesPage.Styles.row)
		}
		.style(Styles.stack)
	}

	/**
	Close Program, the list of the running programs that Ctrl+Alt+Del opens. Ending a task really ends it, like Explorer, which takes the icons and the taskbar with it until Windows starts it again.
	*/
	var closeProgram: some HTML {
		div {
			GeoCitiesWindows.hiddenLabel("Programs that are running", for: .tasksList)

			select(.id(Hooks.tasksList), .size(7)) {}
				.style(GeoCitiesPage.Styles.field, Styles.taskList)

			p {
				"WARNING: Pressing CTRL+ALT+DEL again will restart your computer. You will lose unsaved information in all programs that are running."
			}
			.style(GeoCitiesPage.Styles.caption)

			div {
				button(.id(Hooks.tasksEnd), .type(.button)) {
					"End Task"
				}
				.style(GeoCitiesPage.Styles.retroButton)

				button(.id(Hooks.tasksShutDown), .type(.button)) {
					"Shut Down"
				}
				.style(GeoCitiesPage.Styles.retroButton)

				GeoCitiesWindows.closeButton()
			}
			.style(GeoCitiesPage.Styles.row)

			p(.id(Hooks.tasksStatus), .role("status")) {}
				.style(GeoCitiesPage.Styles.statusBar)
		}
		.style(Styles.stack)
	}

	/**
	Welcome to Windows 98, with the tour of Windows, the registration, and a box that wants to be shown every time.
	*/
	var welcome: some HTML {
		div {
			p {
				"Welcome to "
				span {
					"Windows98"
				}
				.style(Styles.welcomeLogo)
			}
			.style(Styles.welcomeTitle)

			div {
				ul {
					for (topic, title) in [("register", "Register Now"), ("connect", "Connect to the Internet"), ("discover", "Discover Windows 98"), ("maintain", "Maintain Your Computer")] {
						li {
							button(.type(.button), .hook(Hooks.welcomeTopic, value: topic)) {
								title
							}
							.style(Styles.welcomeTopic)
						}
					}
				}
				.style(Styles.stack)

				div {
					p(.id(Hooks.welcomeText), .role("status")) {
						"Click a topic to start. Discover Windows 98 takes 4 hours, or 1 minute if you click fast."
					}

					button(.id(Hooks.welcomeNext), .type(.button), .hidden) {
						"Next >"
					}
					.style(GeoCitiesPage.Styles.retroButton)
				}
				.style(Styles.stack, Styles.welcomePane)
			}
			.style(Styles.welcomeColumns)

			label {
				input(.id(Hooks.welcomeShow), .type(.checkbox), .checked)
				" Show this screen each time Windows 98 starts."
			}
		}
		.style(Styles.stack)
	}

	/**
	The log on of Windows 98, where Cancel logs on too.
	*/
	var logOn: some HTML {
		form(.id(Hooks.logOnForm)) {
			p {
				"🔑 Type a user name and password to log on to Windows."
			}

			div {
				label(.for(Hooks.logOnUser.rawValue)) {
					"User name:"
				}

				input(.id(Hooks.logOnUser), .type(.text), .value("Sindre"), .autocomplete("off"), .maxlength(20))
					.style(GeoCitiesPage.Styles.field)
			}
			.style(Styles.nowrapRow)

			div {
				label(.for(Hooks.logOnPassword.rawValue)) {
					"Password:"
				}

				input(.id(Hooks.logOnPassword), .type(.password), .autocomplete("off"), .maxlength(20))
					.style(GeoCitiesPage.Styles.field)
			}
			.style(Styles.nowrapRow)

			div {
				button(.type(.submit)) {
					"OK"
				}
				.style(GeoCitiesPage.Styles.retroButton)

				button(.id(Hooks.logOnCancel), .type(.button)) {
					"Cancel"
				}
				.style(GeoCitiesPage.Styles.retroButton)
			}
			.style(GeoCitiesPage.Styles.row)

			p {
				"Tip: If you don’t enter a password, you won’t see this prompt again at startup."
			}
			.style(GeoCitiesPage.Styles.caption)
		}
		.style(Styles.stack)
	}

	/**
	Shut Down Windows, with the choices of Windows 98. Stand by never wakes up properly, and MS-DOS mode is a black screen with a prompt, until `win`.
	*/
	var shutDownDialog: some HTML {
		form(.id(Hooks.shutDownForm)) {
			p {
				"💻 What do you want the computer to do?"
			}

			fieldset {
				legend {
					"Shut down options"
				}
				.style(VisuallyHidden.Styles.root)

				for (choice, title) in [("standby", "Stand by"), ("shutdown", "Shut down"), ("restart", "Restart"), ("dos", "Restart in MS-DOS mode")] {
					label {
						input(.type(.radio), .name("geocities-win-shut-down"), .value(choice), .hook(Hooks.shutDownChoice, value: choice))
							.attributes(.checked, when: choice == "shutdown")
						" \(title)"
					}
					.style(GeoCitiesPage.Styles.label)
				}
			}
			.style(Styles.stack, Styles.plainFieldset)

			div {
				button(.type(.submit)) {
					"OK"
				}
				.style(GeoCitiesPage.Styles.retroButton)

				GeoCitiesWindows.closeButton()
			}
			.style(GeoCitiesPage.Styles.row)
		}
		.style(Styles.stack)
	}

	/**
	The message box of Windows, with an icon, a message, details for the illegal operations, and up to three buttons. `geocities-windows.js` fills it in for each question.
	*/
	var messageBox: some HTML {
		div {
			div {
				p(.id(Hooks.messageIcon)) {
					"⚠️"
				}
				.accessibilityHidden()
				.style(Styles.messageIcon)

				p(.id(Hooks.messageText)) {}
					.style(Styles.messageText)
			}
			.style(Styles.messageRow)

			pre(.id(Hooks.messageDetails), .hidden) {}
				.style(Styles.messageDetails)

			div {
				for index in 0..<3 {
					button(.type(.button), .hook(Hooks.messageButton, value: "\(index)"), .hidden) {}
						.style(GeoCitiesPage.Styles.retroButton)
				}
			}
			.style(Styles.messageButtons)
		}
		.style(Styles.stack)
	}

	/**
	The parts that cover the desktop: the startup screen of Windows 98, the blue screen of the launch, the 3D Maze screen saver, the Active Desktop, the menu of the right mouse button, and the templates of the icons.
	*/
	@HTMLBuilder
	var overlays: some HTML {
		// The wallpaper and the web page of the Active Desktop, behind the icons.
		div(.id(Hooks.layer)) {
			div(.id(Hooks.webPage), .hidden) {
				p {
					"My Active Desktop™"
				}
				.style(Styles.webBanner)

				p {
					"Your desktop is now a web page! Why? Because it is 1999."
				}
			}
			.style(Styles.webPage)

			canvas(.id(Hooks.cat), .width(48), .height(112), .hidden) {}
				.style(Styles.cat)

			div(.id(Hooks.recoveryPage), .hidden) {
				p {
					"Active Desktop Recovery"
				}
				.style(Styles.recoveryTitle)

				p {
					"Microsoft Internet Explorer has encountered an error and your Active Desktop has been turned off."
				}
			}
			.style(Styles.recoveryPage)
		}
		.accessibilityHidden()
		.style(Styles.layer)

		div(.id(Hooks.channels), .hidden) {
			p {
				"Channels"
			}
			.style(Styles.channelTitle)

			for (channel, title) in [("unicorn", "🦄 Unicorn TV"), ("waffle", "🧇 Waffle Weather"), ("y2k", "🐛 Y2K News"), ("cheese", "🧀 Brunost Today")] {
				button(.type(.button), .hook(Hooks.channel, value: channel)) {
					title
				}
				.style(Styles.channelButton)
			}
		}
		.style(Styles.channels)

		div(.id(Hooks.ticker), .hidden) {
			p(.id(Hooks.tickerText)) {
				"BREAKING: Y2K is 0 days away ★ Brunost up 3% ★ Unicorns spotted in Bergen ★ Your Active Desktop is using 98% of your memory ★ "
			}
			.style(Styles.tickerText)

			div(.id(Hooks.recovery), .hidden) {
				p {
					"Your Active Desktop has crashed."
				}

				button(.id(Hooks.recoveryRestore), .type(.button)) {
					"Restore my Active Desktop"
				}
				.style(GeoCitiesPage.Styles.smallButton)

				button(.type(.button), .hook(Hooks.command, value: "web")) {
					"Turn Off Active Desktop"
				}
				.style(GeoCitiesPage.Styles.smallButton)
			}
			.style(Styles.wrapRow)
		}
		.style(Styles.ticker)

		div(.id(Hooks.contextMenu), .role("menu"), .hidden) {
			for (command, title, target) in [("open", "Open", "icon"), ("delete", "Delete", "icon"), ("arrange", "Arrange Icons", "desktop"), ("refresh", "Refresh", "desktop"), ("new-folder", "New Folder", "desktop"), ("web", "Active Desktop: View as Web Page", "desktop"), ("properties", "Properties", "desktop")] {
				button(.type(.button), .role("menuitem"), .hook(Hooks.contextCommand, value: command), .hook(Hooks.contextTarget, value: target)) {
					title
				}
				.style(GeoCitiesPage.Styles.startMenuItem)
			}
		}
		.style(Styles.contextMenu)

		div(.id(Hooks.boot), .hidden, .role("dialog"), .tabindex(-1)) {
			p(.id(Hooks.bootText)) {
				"Starting Windows 98…"
			}
			.style(Styles.bootText)

			div(.id(Hooks.bootLogo), .hidden) {
				p {
					"Microsoft®"
				}
				.style(Styles.bootMicrosoft)

				p {
					"Windows98"
				}
				.style(Styles.bootWindows)

				span {}
					.style(Styles.bootBar)
			}
			.style(Styles.bootLogo)
		}
		.accessibilityLabel("Windows 98 is starting")
		.style(Styles.boot)

		div(.id(Hooks.bsod), .hidden, .role("alertdialog"), .tabindex(-1), .ariaLabelledBy("geocities-win-bsod-title")) {
			p(.id("geocities-win-bsod-title")) {
				"Windows"
			}
			.style(GeoCitiesPage.Styles.blueScreenTitle)

			p {
				"An exception 0E has occurred at 0028:C0034B23 in VxD USBSCAN(01) + 00001A4B. This was called from 0028:C001D8B4 in VxD PLUGNPLAY(01). It may be possible to continue normally."
			}

			p {
				"Press any key to continue "
				span {
					"_"
				}
				.accessibilityHidden()
				.style(GeoCitiesPage.Styles.blinkingCursor)
			}
			.style(GeoCitiesPage.Styles.centeredText)

			p(.id(Hooks.bsodQuote), .hidden) {
				"“That must be why we’re not shipping Windows 98 yet.” Bill Gates, on stage at COMDEX in Chicago, April 20, 1998, when Windows 98 crashed like this as he plugged in a scanner."
			}
			.style(Styles.bsodQuote)
		}
		.style(Styles.bsod)

		div(.id(Hooks.maze), .hidden, .role("dialog"), .tabindex(-1)) {
			canvas(.id(Hooks.mazeCanvas), .width(320), .height(200)) {}
				.accessibilityHidden()
				.style(Styles.mazeCanvas)

			p(.id(Hooks.mazeText)) {
				"Press any key or tap to stop the screen saver."
			}
			.style(Styles.mazeText)
		}
		.accessibilityLabel("The 3D Maze screen saver")
		.style(Styles.maze)

		template(.id(Hooks.fileTemplate)) {
			li {
				button(.type(.button)) {
					span {}
						.accessibilityHidden()
						.style(GeoCitiesPage.Styles.desktopIconPicture)

					span {}
				}
				.style(Styles.fileButton)
			}
		}

		// The trash that spills out of the Recycle Bin when it is too full: a pile under its icon, with a sheet of paper to copy.
		template(.id(Hooks.paperTemplate)) {
			div {
				span {
					"📄"
				}
				.style(Styles.paper)
			}
			.accessibilityHidden()
			.style(Styles.paperPile)
		}

		template(.id(Hooks.restoreTemplate)) {
			li {
				strong {}
				" "
				button(.type(.button)) {
					"Restore"
				}
				.style(GeoCitiesPage.Styles.smallButton)
			}
		}

		template(.id(Hooks.iconTemplate)) {
			li {
				button(.type(.button)) {
					span {}
						.accessibilityHidden()
						.style(GeoCitiesPage.Styles.desktopIconPicture)

					span {}
						.style(GeoCitiesPage.Styles.desktopIconTitle)
				}
				.style(GeoCitiesPage.Styles.desktopIcon)
			}
		}
	}

	/**
	My letter to Santa for Christmas 2000.
	*/
	static let letterToSanta = """
	Dear Santa,

	How are you? I am fine. I know it is early, but I want to be first in the line this year.

	Thank you for the Furby. Can I give it back? It talks all night.

	This is what I want for Christmas 2000:
	1. An iMac in Tangerine (you can never have too many iMacs)
	2. A 56K modem, so Napster goes faster
	3. A phone line of my own, so my little sister cannot pick up
	4. A real unicorn (a small one is fine)
	5. World peace (Mamma said I had to write that)

	PS: I will leave waffles with brown cheese by the fireplace again. Last year Rudolph ate them. I saw the hoof prints.

	Love,
	Sindre
	"""
}
