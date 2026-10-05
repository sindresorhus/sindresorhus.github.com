import Elementary
import Foundation
import SiteKit

/**
The windows of the desktop of my iMac (``GeoCitiesMacOS``): the Finder windows, the control panels, the desk accessories, the applications, and the game. Each is hidden until `geocities-mac.js` opens it, and moves by its striped title bar, with the close box at the left, and the zoom box and the collapse box of WindowShade at the right.
*/
struct GeoCitiesMacOSWindows: HTML {
	typealias Hooks = GeoCitiesMacOS.Hooks
	typealias Styles = GeoCitiesMacOS.Styles

	var body: some HTML {
		GeoCitiesPage.Deferred(finderWindows)
		GeoCitiesPage.Deferred(controlPanels)
		GeoCitiesPage.Deferred(accessories)
		GeoCitiesPage.Deferred(applications)
	}

	/**
	The width of a window.
	*/
	enum WindowWidth {
		case small
		case medium
		case large
	}

	/**
	A window of the desktop, with the hooks that the window manager of `geocities-mac.js` finds: the title bar that drags it, the close box, the collapse box of WindowShade, and the zoom box.
	*/
	static func window<Content: HTML>(_ name: String, title: String, width: WindowWidth = .medium, @HTMLBuilder content: () -> Content) -> some HTML {
		section(.hook(Hooks.window, value: name), .hidden, .tabindex(-1), .ariaLabelledBy("geocities-mac-title-\(name)")) {
			div(.hook(Hooks.titleBar)) {
				button(.type(.button), .hook(Hooks.close), .hook(Hooks.balloonText, value: "The close box. Click it to close the window. When the last window of a program closes, the program quits.")) {}
					.accessibilityLabel("Close \(title)")
					.style(Styles.titleBox)

				h3(.id("geocities-mac-title-\(name)")) {
					title
				}
				.style(Styles.windowTitle)

				button(.type(.button), .hook(Hooks.zoom), .ariaPressed(false), .hook(Hooks.balloonText, value: "The zoom box. Click it to make the window as big as the screen, and again to make it small.")) {}
					.accessibilityLabel("Zoom \(title)")
					.style(Styles.titleBox, Styles.zoomBox)

				button(.type(.button), .hook(Hooks.collapse), .ariaPressed(false), .hook(Hooks.balloonText, value: "The collapse box of WindowShade. It rolls the window up like a blind, so only the title bar is left. Double-clicking the title bar does it too.")) {}
					.accessibilityLabel("Collapse \(title)")
					.style(Styles.titleBox, Styles.collapseBox)
			}
			.style(Styles.titleBar)

			div {
				content()
			}
			.style(Styles.windowBody)
		}
		.style(Styles.window, width == .small ? Styles.smallWindow : width == .large ? Styles.largeWindow : Styles.mediumWindow)
	}

	/**
	A button of a window, with the name of the part that the script finds it by.
	*/
	static func pushButton(_ title: String, part: String) -> some HTML {
		button(.type(.button), .hook(Hooks.part, value: part)) {
			title
		}
		.style(Styles.button)
	}

	/**
	The list of icons of a Finder window, and its status bar.
	*/
	@HTMLBuilder
	static func iconGrid() -> some HTML {
		div(.hook(Hooks.part, value: "grid"), .role("group")) {}
			.accessibilityLabel("Items")
			.style(Styles.grid)

		p(.hook(Hooks.part, value: "status")) {}
			.style(Styles.windowStatus)
	}

	@HTMLBuilder
	private var finderWindows: some HTML {
		GeoCitiesPage.Deferred(Self.window("about", title: "About This Computer", width: .large) {
			div {
				canvas(.width(48), .height(48), .hook(Hooks.part, value: "face")) {}
					.accessibilityHidden()
					.style(Styles.aboutFace)

				div {
					p {
						"Mac OS 8.6"
					}
					.style(Styles.aboutVersion)

					p {
						"Built-in Memory: "
						strong(.hook(Hooks.part, value: "built-in")) {}
						" ★ Virtual Memory: "
						strong(.hook(Hooks.part, value: "virtual")) {}
					}

					p {
						"Largest Unused Block: "
						strong(.hook(Hooks.part, value: "largest")) {}
					}
				}
			}
			.style(Styles.aboutHeader)

			ul(.hook(Hooks.part, value: "memory")) {}
				.accessibilityLabel("Memory used by each program")
				.style(Styles.memoryList)

			template(.hook(Hooks.part, value: "memory-template")) {
				li {
					img(.alt(""), .width(16), .height(16))
						.style(Styles.menuIcon)
					span {}
						.style(Styles.memoryName)
					span {}
						.style(Styles.memorySize)
					span {
						span {}
							.style(Styles.memoryFill)
					}
					.accessibilityHidden()
					.style(Styles.memoryBar)
				}
				.style(Styles.memoryRow)
			}

			div {
				Self.pushButton("Add Memory…", part: "add-ram")
			}
			.style(Styles.buttons)

			p {
				"© Apple Computer, Inc. 1983–1999"
			}
			.style(Styles.fine)
		})

		GeoCitiesPage.Deferred(Self.window("info", title: "Get Info") {
			div {
				img(.alt(""), .width(32), .height(32), .hook(Hooks.part, value: "icon"))
					.style(Styles.iconImage)
				p(.hook(Hooks.part, value: "name")) {}
					.style(Styles.infoName)
			}
			.style(Styles.infoHeader)

			p {
				"Kind: "
				span(.hook(Hooks.part, value: "kind")) {}
			}

			p {
				"Size: "
				span(.hook(Hooks.part, value: "size")) {}
			}

			p {
				"Comments: "
				span(.hook(Hooks.part, value: "comments")) {}
			}

			fieldset(.hook(Hooks.part, value: "memory")) {
				legend {
					"Memory Requirements"
				}

				p {
					"Suggested Size: "
					span(.hook(Hooks.part, value: "suggested")) {}
					"K"
				}

				label {
					"Minimum Size: "
					input(.type(.number), .min("100"), .max("60000"), .step(100), .hook(Hooks.part, value: "minimum"))
						.style(Styles.numberField)
					"K"
				}
				.style(Styles.field)

				label {
					"Preferred Size: "
					input(.type(.number), .min("100"), .max("60000"), .step(100), .hook(Hooks.part, value: "preferred"))
						.style(Styles.numberField)
					"K"
				}
				.style(Styles.field)
			}
			.style(Styles.fieldset)

			p(.hook(Hooks.part, value: "note"), .role("status")) {}
				.style(Styles.windowStatus)
		})

		GeoCitiesPage.Deferred(Self.window("hd", title: "Macintosh HD", width: .large) {
			Self.iconGrid()
		})

		GeoCitiesPage.Deferred(Self.window("apps", title: "Applications", width: .large) {
			Self.iconGrid()
		})

		GeoCitiesPage.Deferred(Self.window("trash", title: "Trash") {
			Self.iconGrid()
		})

		GeoCitiesPage.Deferred(Self.window("clipboard", title: "Clipboard", width: .small) {
			p(.hook(Hooks.part, value: "kind")) {}
				.style(Styles.windowStatus)

			canvas(.width(160), .height(100), .hook(Hooks.part, value: "clip")) {}
				.accessibilityLabel("The picture on the clipboard")
				.style(Styles.clipCanvas)

			p(.hook(Hooks.part, value: "text")) {}
				.style(Styles.clipText)
		})

		GeoCitiesPage.Deferred(Self.window("switcher", title: "Application Switcher", width: .small) {
			div(.hook(Hooks.part, value: "apps"), .role("group")) {}
				.accessibilityLabel("Running programs")
				.style(Styles.switcherApps)
		})

		GeoCitiesPage.Deferred(Self.window("installer", title: "Mac OS 8.6 Install") {
			p {
				"Click Start to install Mac OS 8.6 on “Macintosh HD”. It puts back the System Folder, and everything on the desktop that went in the Trash. It takes about 40 minutes. (On this iMac, a little less.)"
			}

			div {
				div(.hook(Hooks.part, value: "fill")) {}
					.style(Styles.meterFill)
			}
			.accessibilityHidden()
			.style(Styles.meter)

			p(.hook(Hooks.part, value: "status"), .role("status")) {}
				.style(Styles.windowStatus)

			div {
				Self.pushButton("Start", part: "start")
			}
			.style(Styles.buttons)
		})
	}

	@HTMLBuilder
	private var controlPanels: some HTML {
		GeoCitiesPage.Deferred(Self.window("extensions", title: "Extensions Manager", width: .large) {
			label {
				"Selected Set: "
				select(.hook(Hooks.part, value: "set")) {
					for (value, title) in [("mine", "My Settings"), ("all", "Mac OS 8.6 All"), ("base", "Mac OS 8.6 Base")] {
						option(.value(value)) {
							title
						}
					}
				}
			}
			.style(Styles.field)

			ul(.hook(Hooks.part, value: "list")) {}
				.accessibilityLabel("Extensions and control panels")
				.style(Styles.extensionList)

			p(.hook(Hooks.part, value: "info"), .role("status")) {
				"Turn extensions off, then restart. One of them crashes my iMac at startup sometimes. Which one? That is the game."
			}
			.style(Styles.windowStatus)

			div {
				Self.pushButton("All Off", part: "all-off")
				Self.pushButton("All On", part: "all-on")
				Self.pushButton("Restart", part: "restart")
			}
			.style(Styles.buttons)
		})

		GeoCitiesPage.Deferred(Self.window("appearance", title: "Appearance", width: .large) {
			div(.role("group")) {
				for (part, title) in [("themes", "Themes"), ("desktop", "Desktop"), ("sound", "Sound")] {
					Elementary.button(.type(.button), .hook(Hooks.part, value: "tab-\(part)"), .ariaPressed(part == "themes")) {
						title
					}
					.style(Styles.tab)
				}
			}
			.accessibilityLabel("Appearance tabs")
			.style(Styles.tabs)

			div(.hook(Hooks.part, value: "panel-themes")) {
				fieldset {
					legend {
						"Theme"
					}

					for (value, title) in Self.themes {
						label {
							input(.type(.radio), .name("geocities-mac-theme"), .value(value), .hook(Hooks.part, value: "theme"))
							" \(title)"
						}
						.style(Styles.choice)
					}
				}
				.style(Styles.fieldset)

				p {
					"The themes after Platinum are Kaleidoscope schemes I downloaded. They need the Kaleidoscope extension. Copland is the Mac OS that Apple never finished, so I finished it."
				}
				.style(Styles.fine)
			}
			.style(Styles.panel)

			div(.hook(Hooks.part, value: "panel-desktop"), .hidden) {
				fieldset {
					legend {
						"Desktop Picture"
					}

					for (value, title) in Self.desktopPictures {
						label {
							input(.type(.radio), .name("geocities-mac-desktop"), .value(value), .hook(Hooks.part, value: "picture"))
							" \(title)"
						}
						.style(Styles.choice)
					}
				}
				.style(Styles.fieldset)
			}
			.style(Styles.panel)

			div(.hook(Hooks.part, value: "panel-sound"), .hidden) {
				label {
					"Sound track: "
					select(.hook(Hooks.part, value: "soundtrack")) {
						option(.value("none")) {
							"None"
						}
						option(.value("platinum")) {
							"Platinum Sounds (menus and windows make sounds)"
						}
					}
				}
				.style(Styles.field)

				label {
					"Alert sound: "
					select(.hook(Hooks.part, value: "alert-sound")) {
						for sound in ["Simple Beep", "Droplet", "Sosumi", "Wild Eep", "Quack"] {
							option(.value(sound)) {
								sound
							}
						}
					}
				}
				.style(Styles.field)

				div {
					Self.pushButton("🔊 Play the alert sound", part: "try-alert")
				}
				.style(Styles.buttons)

				p {
					"The sounds play when the speakers below the iMac are on."
				}
				.style(Styles.fine)
			}
			.style(Styles.panel)
		})

		GeoCitiesPage.Deferred(Self.window("speech", title: "Speech") {
			label {
				"Voice: "
				select(.hook(Hooks.part, value: "voice")) {
					for voice in Self.voices {
						option(.value(voice)) {
							voice
						}
					}
				}
			}
			.style(Styles.field)

			label {
				"Rate: "
				input(.type(.range), .min("0.5"), .max("2"), .step(0.1), .value("1"), .hook(Hooks.part, value: "rate"))
			}
			.style(Styles.field)

			div {
				Self.pushButton("🔊 Try the voice", part: "try")
			}
			.style(Styles.buttons)

			label {
				input(.type(.checkbox), .hook(Hooks.part, value: "talking"))
				" Talking Alerts: read the alerts out loud"
			}
			.style(Styles.choice)

			label {
				"Speak the phrase first: "
				select(.hook(Hooks.part, value: "phrase")) {
					for phrase in ["Alert!", "Excuse me!", "Wake up!", "Hey, Sindre!", "Moof!"] {
						option(.value(phrase)) {
							phrase
						}
					}
				}
			}
			.style(Styles.field)

			p(.hook(Hooks.part, value: "status"), .role("status")) {
				"Cellos, Good News, and Bad News sing. Zarvox is a robot from space."
			}
			.style(Styles.windowStatus)
		})
	}

	@HTMLBuilder
	private var accessories: some HTML {
		GeoCitiesPage.Deferred(Self.window("puzzle", title: "Puzzle", width: .small) {
			canvas(.width(160), .height(160), .tabindex(0), .role("application"), .hook(Hooks.part, value: "board")) {}
				.accessibilityLabel("The Puzzle. Use the arrow keys to slide a piece into the empty place, or click a piece next to it.")
				.style(Styles.puzzleBoard)

			div {
				Self.pushButton("Shuffle", part: "shuffle")
				Self.pushButton("Numbers", part: "numbers")
				Self.pushButton("Paste", part: "paste")
			}
			.style(Styles.buttons)

			p(.hook(Hooks.part, value: "status"), .role("status")) {
				"Copied from Dad’s old System 7.5. Paste a picture from the Scrapbook to make your own puzzle."
			}
			.style(Styles.windowStatus)
		})

		GeoCitiesPage.Deferred(Self.window("notepad", title: "Note Pad", width: .small) {
			textarea(.rows(9), .maxlength(1200), .autocomplete("off"), .hook(Hooks.part, value: "text")) {}
				.accessibilityLabel("Page of the Note Pad")
				.style(Styles.notePage)

			div {
				Elementary.button(.type(.button), .hook(Hooks.part, value: "previous")) {
					"◀"
				}
				.accessibilityLabel("Previous page")
				.style(Styles.smallButton)

				span(.hook(Hooks.part, value: "page"), .role("status")) {}
					.style(Styles.pageNumber)

				Elementary.button(.type(.button), .hook(Hooks.part, value: "next")) {
					"▶"
				}
				.accessibilityLabel("Next page")
				.style(Styles.smallButton)
			}
			.style(Styles.notePadFooter)
		})

		GeoCitiesPage.Deferred(Self.window("scrapbook", title: "Scrapbook") {
			canvas(.width(240), .height(150), .hook(Hooks.part, value: "clip")) {}
				.accessibilityLabel("The picture of the clipping")
				.style(Styles.clipCanvas)

			p(.hook(Hooks.part, value: "text"), .hidden) {}
				.style(Styles.clipText)

			label {
				span {
					"Clipping"
				}
				.style(VisuallyHidden.Styles.root)
				input(.type(.range), .min("0"), .max("1"), .value("0"), .hook(Hooks.part, value: "scroll"))
					.style(Styles.scroll)
			}

			p(.hook(Hooks.part, value: "info"), .role("status")) {}
				.style(Styles.windowStatus)

			div {
				Self.pushButton("Copy", part: "copy")
				Self.pushButton("Paste", part: "paste")
				Self.pushButton("Clear", part: "clear")
			}
			.style(Styles.buttons)
		})

		GeoCitiesPage.Deferred(Self.window("keycaps", title: "Key Caps", width: .large) {
			p(.hook(Hooks.part, value: "display"), .role("status")) {}
				.accessibilityLabel("What you typed")
				.style(Styles.keyCapsDisplay)

			div(.hook(Hooks.part, value: "keyboard"), .role("group")) {}
				.accessibilityLabel("Keyboard")
				.style(Styles.keyboard)

			div {
				Elementary.button(.type(.button), .hook(Hooks.part, value: "shift"), .ariaPressed(false)) {
					"⇧ Shift"
				}
				.style(Styles.button)

				Elementary.button(.type(.button), .hook(Hooks.part, value: "option"), .ariaPressed(false)) {
					"⌥ Option"
				}
				.style(Styles.button)

				Self.pushButton("Clear", part: "clear")
			}
			.style(Styles.buttons)

			p {
				"Hold Option (or press the button) to see the secret letters. Shift and Option and K is the Apple logo, but only on a Mac. On other computers it is a box."
			}
			.style(Styles.fine)
		})

		GeoCitiesPage.Deferred(Self.window("chooser", title: "Chooser", width: .large) {
			div {
				ul {
					for (driver, title) in [("stylewriter", "🖨️ StyleWriter II"), ("laserwriter", "🖨️ LaserWriter 8"), ("appleshare", "🗄️ AppleShare")] {
						li {
							Elementary.button(.type(.button), .hook(Hooks.part, value: "driver-\(driver)"), .ariaPressed(false)) {
								title
							}
							.style(Styles.listButton)
						}
					}
				}
				.accessibilityLabel("Drivers")
				.style(Styles.chooserList)

				div {
					p(.hook(Hooks.part, value: "prompt")) {
						"Select a driver at the left."
					}

					ul(.hook(Hooks.part, value: "printers")) {}
						.accessibilityLabel("Printers")
						.style(Styles.chooserList)
				}
			}
			.style(Styles.chooserColumns)

			fieldset {
				legend {
					"AppleTalk"
				}

				label {
					input(.type(.radio), .name("geocities-mac-appletalk"), .value("on"), .hook(Hooks.part, value: "appletalk"))
					" Active"
				}
				.style(Styles.choice)

				label {
					input(.type(.radio), .name("geocities-mac-appletalk"), .value("off"), .hook(Hooks.part, value: "appletalk"))
					" Inactive"
				}
				.style(Styles.choice)
			}
			.style(Styles.fieldset)

			p(.hook(Hooks.part, value: "status"), .role("status")) {}
				.style(Styles.windowStatus)
		})

		GeoCitiesPage.Deferred(Self.window("pagesetup", title: "Page Setup Options", width: .small) {
			canvas(.width(160), .height(120), .hook(Hooks.part, value: "dogcow")) {}
				.accessibilityLabel("Clarus the dogcow, on the page")
				.style(Styles.clipCanvas)

			for (part, title) in [("flip-h", "Flip Horizontal"), ("flip-v", "Flip Vertical"), ("invert", "Invert Image"), ("precision", "Precision Bitmap Alignment (4% reduction)")] {
				label {
					input(.type(.checkbox), .hook(Hooks.part, value: part))
					" \(title)"
				}
				.style(Styles.choice)
			}

			div {
				Self.pushButton("🔊 Moof!", part: "moof")
				Self.pushButton("OK", part: "ok")
			}
			.style(Styles.buttons)

			p(.hook(Hooks.part, value: "status"), .role("status")) {
				"This is Clarus. She is a dog and a cow. She shows how the page will print."
			}
			.style(Styles.windowStatus)
		})

		GeoCitiesPage.Deferred(Self.window("stickies", title: "Stickies", width: .small) {
			p {
				"Stickies keeps my notes on the screen, even after a restart. Drag them by the top."
			}

			div {
				Self.pushButton("+ New Note", part: "new")
			}
			.style(Styles.buttons)
		})
	}

	@HTMLBuilder
	private var applications: some HTML {
		GeoCitiesPage.Deferred(Self.window("sherlock", title: "Sherlock", width: .large) {
			div(.role("group")) {
				for (part, title) in [("internet", "🌐 Search Internet"), ("content", "📄 Find by Content")] {
					Elementary.button(.type(.button), .hook(Hooks.part, value: "tab-\(part)"), .ariaPressed(part == "internet")) {
						title
					}
					.style(Styles.tab)
				}
			}
			.accessibilityLabel("Kind of search")
			.style(Styles.tabs)

			form(.hook(Hooks.part, value: "form")) {
				label {
					"Words: "
					input(.type(.search), .maxlength(40), .autocomplete("off"), .hook(Hooks.part, value: "query"))
						.style(Styles.textField)
				}
				.style(Styles.field)

				Elementary.button(.type(.submit)) {
					"🔍 Search"
				}
				.style(Styles.button)
			}
			.style(Styles.searchForm)

			div(.hook(Hooks.part, value: "sites")) {
				for site in ["AltaVista", "Excite", "Infoseek", "Lycos", "Amazon.com", "Apple Tech Info Library"] {
					label {
						input(.type(.checkbox), .checked, .value(site), .hook(Hooks.part, value: "site"))
						" \(site)"
					}
					.style(Styles.choice)
				}
			}
			.style(Styles.sites)

			div(.hook(Hooks.part, value: "indexing"), .hidden) {
				Self.pushButton("Index Volumes…", part: "index")
			}
			.style(Styles.buttons)

			div {
				div(.hook(Hooks.part, value: "fill")) {}
					.style(Styles.meterFill)
			}
			.accessibilityHidden()
			.style(Styles.meter)

			ul(.hook(Hooks.part, value: "results")) {}
				.accessibilityLabel("Results")
				.style(Styles.results)

			p(.hook(Hooks.part, value: "summary"), .role("status")) {}
				.style(Styles.windowStatus)
		})

		GeoCitiesPage.Deferred(Self.window("graphing", title: "Graphing Calculator", width: .large) {
			form(.hook(Hooks.part, value: "form")) {
				label {
					span {
						"Equation"
					}
					.style(VisuallyHidden.Styles.root)
					input(.type(.text), .value("y = sin(x) * x"), .maxlength(60), .autocomplete("off"), .custom(name: "spellcheck", value: "false"), .hook(Hooks.part, value: "equation"))
						.style(Styles.equation)
				}

				Elementary.button(.type(.submit)) {
					"Graph"
				}
				.style(Styles.button)

				Self.pushButton("Demo", part: "demo")
			}
			.style(Styles.searchForm)

			canvas(.width(320), .height(220), .hook(Hooks.part, value: "plot")) {}
				.accessibilityLabel("The graph")
				.style(Styles.plot)

			p(.hook(Hooks.part, value: "status"), .role("status")) {
				"Type an equation with x, like y = x^2 or y = cos(x) / x, and press Graph. Try sqrt, abs, tan, and pi too."
			}
			.style(Styles.windowStatus)
		})

		GeoCitiesPage.Deferred(Self.window("bugdom", title: "Bugdom Jr.", width: .large) {
			canvas(.width(320), .height(240), .tabindex(0), .role("application"), .hook(Hooks.part, value: "game")) {}
				.accessibilityLabel("Bugdom Jr. Use the arrow keys to walk, and the space bar to roll up into a ball.")
				.style(Styles.game)

			div {
				div {
					for (control, symbol, label) in [("left", "◀", "Left"), ("up", "▲", "Up"), ("down", "▼", "Down"), ("right", "▶", "Right")] {
						Elementary.button(.type(.button), .tabindex(-1), .hook(Hooks.part, value: "pad-\(control)")) {
							symbol
						}
						.accessibilityLabel(label)
						.style(Styles.padButton)
					}
				}
				.style(Styles.pad)

				Elementary.button(.type(.button), .tabindex(-1), .hook(Hooks.part, value: "pad-roll")) {
					"🐞 Roll"
				}
				.style(Styles.padButton, Styles.rollButton)
			}
			.style(Styles.gamePad)

			div {
				Self.pushButton("New Game", part: "start")
			}
			.style(Styles.buttons)

			p(.hook(Hooks.part, value: "status"), .role("status")) {
				"Rollie McFly must free the 5 ladybugs from the cages of the fire ants. Only a rolling pill bug breaks a cage. While you roll, ants bounce off, but rolling makes you dizzy."
			}
			.style(Styles.windowStatus)
		})

		GeoCitiesPage.Deferred(Self.window("netscape", title: "Netscape: Sindre’s Home Page", width: .large) {
			div {
				for title in ["Back", "Forward", "Reload", "Home", "Search", "Stop"] {
					span {
						title
					}
					.style(Styles.browserButton)
				}

				span(.hook(Hooks.part, value: "throbber")) {
					"N"
				}
				.accessibilityHidden()
				.style(Styles.throbber)
			}
			.accessibilityHidden()
			.style(Styles.browserToolbar)

			p {
				"Location: http://www.geocities.com/sindre1999/"
			}
			.style(Styles.location)

			div(.hook(Hooks.part, value: "page")) {}
				.style(Styles.browserPage)

			p(.hook(Hooks.part, value: "status"), .role("status")) {}
				.style(Styles.windowStatus)
		})

		GeoCitiesPage.Deferred(Self.window("simpletext", title: "Read Me!", width: .large) {
			div(.hook(Hooks.part, value: "text"), .tabindex(0)) {
				for paragraph in Self.readMe {
					p {
						paragraph
					}
				}
			}
			.accessibilityLabel("Read Me")
			.style(Styles.document)

			div {
				Self.pushButton("🔊 Speak All", part: "speak")
				Self.pushButton("Stop Speaking", part: "stop")
			}
			.style(Styles.buttons)
		})
	}

	/**
	The themes of the Appearance control panel: Platinum, and the Kaleidoscope schemes.
	*/
	static let themes = [
		("platinum", "Platinum (Apple)"),
		("bondi", "Bondi (to match my iMac)"),
		("waffle", "Hot Waffle"),
		("copland", "Copland"),
		("windows", "Windoze 95"),
	]

	/**
	The desktop pictures and patterns of the Appearance control panel.
	*/
	static let desktopPictures = [
		("default", "Mac OS Default"),
		("bondi", "Bondi Blue"),
		("waffle", "Waffle Iron"),
		("gray", "Classic Gray"),
		("clouds", "Clouds"),
		("fjord", "Bergen at Night"),
		("think", "Think Different"),
	]

	/**
	The voices of PlainTalk in the Speech control panel. `geocities-mac.js` makes each with the pitch and the speed of the voice of the browser, and the singing voices sing their tune one word at a time.
	*/
	static let voices = ["Fred", "Victoria", "Junior", "Princess", "Ralph", "Whisper", "Zarvox", "Trinoids", "Bubbles", "Good News", "Bad News", "Cellos"]

	/**
	The Read Me of the desktop, which SimpleText opens.
	*/
	static let readMe = [
		"READ ME FIRST!!! (Really. Read it.)",
		"Hi, this is my iMac. It is Bondi Blue. It is the best computer in Norway, and probably in Europe.",
		"Rules of my iMac: 1. Do NOT drag the System Folder to the Trash. If you do, the iMac shows a flashing question mark, and you must start up from the CD (hold C) to put it back. 2. Do not download RAM. I did. It was bad. 3. If it bombs, restart and hold Shift. Then use the Extensions Manager to find the extension that did it.",
		"Some icons are blank. That is because the desktop file is a mess. Hold Command and Option at startup to rebuild the desktop. Sometimes it gets messy again when it crashes. That is normal.",
		"Bugdom Jr. needs a lot of memory. If it does not open, quit other programs (look in the Application menu at the top right), or give it less memory with Get Info. Not too little, or it crashes.",
		"My printer is a StyleWriter II. It is out of ink. Mom says ink costs more than gold.",
		"Netscape crashes. Every time. I think it does not like me.",
		"Talking Alerts are the best thing in the world. Turn them on in Speech in the Control Panels. Then make something crash.",
		"Think different. (But not too different.)",
	]
}
