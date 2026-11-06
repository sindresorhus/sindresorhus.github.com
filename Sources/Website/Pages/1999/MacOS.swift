import Elementary
import Foundation
import SiteKit

/**
My real computer: the iMac in Bondi Blue with Mac OS 8.6, as it was, with its own look (the Platinum appearance with the striped title bars, the menu bar with the Apple menu and the Application menu, the Finder, and the Trash). It starts up with the chime, the Happy Mac, “Welcome to Mac OS”, and the icons of the extensions along the bottom, and the keys to hold while it starts (Shift for Extensions Off, Command and Option to rebuild the desktop, Command, Option, P, and R to zap the PRAM, and C for the CD). The things of Mac OS 8 that go wrong go wrong: an extension that conflicts and bombs at startup until the visitor finds it with the Extensions Manager, applications that unexpectedly quit with an error of a type, not enough memory for Bugdom Jr., blank icons until the desktop is rebuilt, the flashing question mark when the System Folder is in the Trash, and the Sad Mac with the Chimes of Death for RAM from the Internet. The desk accessories and the applications work: Puzzle, Stickies, Note Pad, the Scrapbook, Key Caps, the Chooser with a StyleWriter that is out of ink, Page Setup with Clarus the dogcow, Sherlock, the Graphing Calculator, SimpleText with the voices of PlainTalk, Netscape, the Appearance with its themes, desktop pictures, and sounds, the Control Strip, Balloon Help, and a game like Bugdom. `geocities-mac.js` runs all of it, and only makes a sound after the visitor turns on the speakers.
*/
struct GeoCitiesMacOS: HTML {
	let project: Project

	var body: some HTML {
		section(.id(IDs.root), .tabindex(-1)) {
			h2 {
				"My iMac (the Real One)"
			}
			.style(GeoCitiesPage.Styles.heading, GeoCitiesPage.Styles.centeredText)

			p {
				GeoCitiesPage.GIFImage(
					gif: .buttonMacVsWindows,
					alt: "The Apple logo with a water pistol aimed at the Windows logo",
					style: .gif,
					project: project
				)
			}
			.style(GeoCitiesPage.Styles.centeredText)

			p {
				"Further down, I put Windows 98 on my iMac. Do not ask how. This is how it really looks: Mac OS 8.6, on my iMac in Bondi Blue, with 32 MB of RAM and no floppy drive. Press the power button. Double-click the icons (or tap them twice), drag the windows by their striped title bars, and look in the Apple menu. If it bombs, that is normal. It is a Mac in 1999."
			}
			.style(GeoCitiesPage.Styles.centeredText)

			div {
				div {
					div {
						GeoCitiesPage.Deferred(Self.screen)
					}
					.style(Styles.bezel)

					div {
						span {
							"iMac"
						}
						.accessibilityHidden()
						.style(Styles.badge)

						// The tray of the CD drive, under the screen, which slides out with the CD in it.
						div(.id(IDs.tray), .hidden) {
							button(.id(IDs.trayCD), .type(.button)) {
								"💿 Mac OS 8.6 CD (push the tray in)"
							}
							.style(Styles.trayCD)
						}
						.style(Styles.tray)

						button(.id(IDs.power), .type(.button), .ariaPressed(false)) {
							span(.id(IDs.led)) {}
								.accessibilityHidden()
								.style(Styles.led)
							"⏻ Power"
						}
						.style(Styles.power)
					}
					.style(Styles.chin)
				}
				.style(Styles.imac)

				// The StyleWriter II on the desk, next to the iMac, which prints what the visitor prints, when it has ink.
				div(.id(IDs.printer), .hidden) {
					canvas(.id(IDs.printout), .width(240), .height(300)) {}
						.accessibilityLabel("The printed page")
						.style(Styles.printout)

					p {
						"StyleWriter II"
					}
					.accessibilityHidden()
					.style(Styles.printerBody)
				}
				.style(Styles.printer)
			}
			.style(Styles.desk, GeoCitiesPage.Styles.scriptingOnly)

			div {
				button(.id(IDs.speakers), .type(.button), .ariaPressed(false)) {
					"🔈 Turn on the speakers (the chime, beeps, sounds, and Talking Alerts)"
				}
				.style(GeoCitiesPage.Styles.retroButton)

				p {
					"Keys to hold down while it starts up (press one, then Restart from the Special menu, or the power button):"
				}
				.style(GeoCitiesPage.Styles.caption)

				div(.role(.group)) {
					for (key, title) in Self.startupKeys {
						button(.type(.button), .hook(Hooks.startupKey, value: key), .ariaPressed(false)) {
							title
						}
						.style(Styles.keyCap)
					}
				}
				.accessibilityLabel("Keys to hold at startup")
				.style(Styles.keyRow)

				p(.id(IDs.status), .role(.status)) {}
					.style(Styles.status)
			}
			.style(Styles.below, GeoCitiesPage.Styles.scriptingOnly)

			p {
				"My iMac needs JavaScript. And more RAM."
			}
			.style(GeoCitiesPage.Styles.scriptingDisabledOnly)
		}
		.style(GeoCitiesPage.Styles.section)

		ModuleScript(#path("/scripts/geocities-mac.js"))
	}

	/**
	The keys that can be held while the iMac starts up, with what they do.
	*/
	static let startupKeys = [
		("shift", "⇧ Shift: Extensions Off"),
		("rebuild", "⌘ ⌥: Rebuild the Desktop"),
		("pram", "⌘ ⌥ P R: Zap the PRAM"),
		("cd", "C: Start up from the CD"),
	]

	/**
	The screen of the iMac: black while it is off, gray while it starts up, then the desktop, with a dialog over all of it for the alerts.
	*/
	@HTMLBuilder
	static var screen: some HTML {
		div(.id(IDs.screen)) {
			div(.id(IDs.off)) {
				p(.id(IDs.offText)) {
					"Press the power button below the screen."
				}
			}
			.style(Styles.off)

			div(.id(IDs.boot), .hidden) {
				canvas(.id(IDs.bootIcon), .width(96), .height(108)) {}
					.accessibilityHidden()
					.style(Styles.bootIcon)

				div(.id(IDs.welcome), .hidden) {
					canvas(.id(IDs.face), .width(64), .height(64)) {}
						.accessibilityHidden()
						.style(Styles.face)

					p {
						"Welcome to Mac OS"
					}
					.style(Styles.welcomeText)

					div {
						div(.id(IDs.progress)) {}
							.style(Styles.progressBar)
					}
					.accessibilityHidden()
					.style(Styles.progressTrack)

					p(.id(IDs.bootNote)) {}
						.style(Styles.bootNote)
				}
				.style(Styles.welcome)

				p(.id(IDs.bootMessage), .role(.status)) {}
					.style(Styles.bootMessage)

				div(.id(IDs.extensionRow)) {}
					.accessibilityHidden()
					.style(Styles.extensionRow)
			}
			.style(Styles.boot)

			div(.id(IDs.desktop), .hidden) {
				canvas(.id(IDs.picture)) {}
					.accessibilityHidden()
					.style(Styles.picture)

				GeoCitiesPage.Deferred(menuBar)

				div(.id(IDs.icons), .role(.group)) {}
					.accessibilityLabel("Desktop")
					.style(Styles.icons)

				GeoCitiesPage.Deferred(GeoCitiesMacOSWindows())

				GeoCitiesPage.Deferred(controlStrip)

				p(.id(IDs.balloon), .hidden, .role(.tooltip)) {}
					.style(Styles.balloon)

				// The Flying Toasters of After Dark, when the desktop is left alone.
				canvas(.id(IDs.saver), .hidden) {}
					.accessibilityHidden()
					.style(Styles.saver)
			}
			.style(Styles.desktop)

			div(
				.id(IDs.alert),
				.hidden,
				.role(.alertDialog),
				.ariaModal,
				.tabindex(-1),
				.ariaDescribedBy(IDs.alertText.id)
			) {
				div {
					canvas(.id(IDs.alertIcon), .width(32), .height(32)) {}
						.accessibilityHidden()
						.style(Styles.alertIcon)

					div {
						p(.id(IDs.alertText)) {}
							.style(Styles.alertText)

						p(.id(IDs.alertDetail)) {}
							.style(Styles.alertDetail)
					}
				}
				.style(Styles.alertMessage)

				div(.id(IDs.alertButtons)) {}
					.style(Styles.alertButtons)
			}
			.accessibilityLabel("Alert")
			.style(Styles.alert)

			GeoCitiesPage.Deferred(templates)
		}
		.style(Styles.screen)
	}

	/**
	The templates that `geocities-mac.js` copies: an icon of the desktop or a folder, a button of an alert, an item of a menu that changes, like the Application menu, a row of a list, like the extensions, a result of Sherlock, a key of Key Caps, and a note of Stickies.
	*/
	@HTMLBuilder
	static var templates: some HTML {
		template(.id(IDs.iconTemplate)) {
			button(.type(.button)) {
				img(.alt(""), .width(32), .height(32))
					.style(Styles.iconImage)
				span {}
					.style(Styles.iconLabel)
			}
			.style(Styles.icon)
		}

		template(.id(IDs.buttonTemplate)) {
			button(.type(.button)) {}
				.style(Styles.button)
		}

		template(.id(IDs.menuItemTemplate)) {
			li {
				button(.type(.button)) {}
					.style(Styles.menuItem)
			}
		}

		template(.id(IDs.rowTemplate)) {
			li {
				label {
					input(.type(.checkbox))
					span {}
				}
				.style(Styles.row)
			}
		}

		template(.id(IDs.resultTemplate)) {
			li {
				button(.type(.button)) {
					span {}
						.style(Styles.resultTitle)
					span {}
						.accessibilityHidden()
						.style(Styles.relevance)
				}
				.style(Styles.result)
			}
		}

		template(.id(IDs.keyTemplate)) {
			button(.type(.button), .tabindex(-1)) {}
				.style(Styles.keyCapsKey)
		}

		template(.id(IDs.stickyTemplate)) {
			GeoCitiesMacOSWindows.window(.sticky, width: .small) {
				div {
					button(.type(.button), .hook(Hooks.part, value: "new")) {
						"+ New Note"
					}
					.style(Styles.smallButton)

					button(.type(.button), .hook(Hooks.part, value: "color")) {
						"Color"
					}
					.style(Styles.smallButton)
				}
				.style(Styles.toolbar)

				textarea(
					.rows(5),
					.maxlength(500),
					.autocomplete("off"),
					.hook(Hooks.part, value: "text")
				) {}
					.accessibilityLabel("Sticky note")
					.style(Styles.stickyText)
			}
		}
	}

	/**
	The menu bar at the top of the screen, with the Apple menu, the menus of the Finder, the clock, and the Application menu at the right.
	*/
	@HTMLBuilder
	static var menuBar: some HTML {
		div {
			ul {
				for menu in MenuBarMenu.all {
					li {
						button(
							.type(.button),
							.hook(Hooks.menu, value: menu.id),
							.ariaExpanded(false),
							.ariaControls(ElementID("geocities-mac-menu-\(menu.id)"))
						) {
							if menu.id == "apple" {
								img(
									.alt("Apple menu"),
									.width(16),
									.height(16),
									.hook(Hooks.part, value: "apple-logo")
								)
									.style(Styles.menuIcon)
							} else {
								menu.title
							}
						}
						.style(Styles.menuTitle)

						ul(.id("geocities-mac-menu-\(menu.id)"), .hidden, .hook(Hooks.menuList, value: menu.id)) {
							for item in menu.items {
								MenuBarItem(item: item)
							}
						}
						.style(Styles.menu)
					}
					.style(Styles.menuSlot)
				}
			}
			.accessibilityLabel("Menu bar")
			.style(Styles.menus)

			div {
				button(.id(IDs.clock), .type(.button)) {}
					.accessibilityLabel("Clock")
					.style(Styles.menuTitle)

				div {
					button(
						.id(IDs.appMenuButton),
						.type(.button),
						.ariaExpanded(false),
						.ariaControls(IDs.appMenu.id)
					) {
						img(.alt(""), .width(16), .height(16))
							.style(Styles.menuIcon)
						span {
							"Finder"
						}
					}
					.accessibilityLabel("Application menu")
					.style(Styles.menuTitle)

					ul(.id(IDs.appMenu), .hidden) {}
						.style(Styles.menu, Styles.menuAtRight)
				}
				.style(Styles.menuSlot)
			}
			.style(Styles.menuRight)
		}
		.style(Styles.menuBar)
	}

	/**
	The Control Strip at the bottom of the screen, which collapses to its tab, with modules for the volume, the colors of the monitor, AppleTalk, and File Sharing.
	*/
	@HTMLBuilder
	static var controlStrip: some HTML {
		div(.id(IDs.strip)) {
			div(.id(IDs.stripModules)) {
				for module in ControlStripModule.all {
					button(.type(.button), .hook(Hooks.stripModule, value: module.id), .hook(Hooks.balloonText, value: module.help)) {
						module.icon
					}
					.accessibilityLabel(module.label)
					.style(Styles.stripModule)
				}
			}
			.style(Styles.stripModules)

			button(
				.id(IDs.stripTab),
				.type(.button),
				.ariaExpanded(true),
				.ariaControls(IDs.stripModules.id)
			) {
				"▸"
			}
			.accessibilityLabel("Control Strip")
			.style(Styles.stripTab)
		}
		.style(Styles.strip)
	}

	/**
	What Balloon Help says about each module of the Control Strip.
	*/
	struct ControlStripModule {
		let id: String
		let icon: String
		let label: String
		let help: String

		// Help is required beside its label; there is no second ID-keyed table to keep in sync.
		static let all = [
			Self(id: "volume", icon: "🔊", label: "Volume", help: "Changes the volume of the speakers. Click it to go up a step. After 7 comes 0, like on my stereo."),
			Self(id: "depth", icon: "🖥️", label: "Monitor colors", help: "Changes the colors of the monitor, from Millions down to Black & White. Black & White is how my dad says computers looked when he was young."),
			Self(id: "appletalk", icon: "🔗", label: "AppleTalk", help: "Turns AppleTalk on or off. The LaserWriter at Dad’s office needs it. Dad’s office is 40 km away, so it does not help."),
			Self(id: "sharing", icon: "📂", label: "File Sharing", help: "Shares my iMac with the network. There is no network. It is me and my iMac."),
			Self(id: "speech", icon: "🗣️", label: "Talking Alerts", help: "Turns Talking Alerts on or off, so the iMac reads the alerts out loud."),
		]
	}

	enum IDs: String, ScriptIDSet {
		case root = "geocities-mac"
		case screen = "geocities-mac-screen"
		case power = "geocities-mac-power"
		case led = "geocities-mac-led"
		case speakers = "geocities-mac-speakers"
		case tray = "geocities-mac-tray"
		case trayCD = "geocities-mac-tray-cd"
		case printer = "geocities-mac-printer"
		case printout = "geocities-mac-printout"
		case status = "geocities-mac-status"
		case off = "geocities-mac-off"
		case offText = "geocities-mac-off-text"
		case boot = "geocities-mac-boot"
		case bootIcon = "geocities-mac-boot-icon"
		case welcome = "geocities-mac-welcome"
		case face = "geocities-mac-face"
		case progress = "geocities-mac-progress"
		case bootNote = "geocities-mac-boot-note"
		case bootMessage = "geocities-mac-boot-message"
		case extensionRow = "geocities-mac-extension-row"
		case desktop = "geocities-mac-desktop"
		case picture = "geocities-mac-picture"
		case icons = "geocities-mac-icons"
		case clock = "geocities-mac-clock"
		case appMenuButton = "geocities-mac-app-menu-button"
		case appMenu = "geocities-mac-app-menu"
		case strip = "geocities-mac-strip"
		case stripModules = "geocities-mac-strip-modules"
		case stripTab = "geocities-mac-strip-tab"
		case balloon = "geocities-mac-balloon"
		case saver = "geocities-mac-saver"
		case alert = "geocities-mac-alert"
		case alertIcon = "geocities-mac-alert-icon"
		case alertText = "geocities-mac-alert-text"
		case alertDetail = "geocities-mac-alert-detail"
		case alertButtons = "geocities-mac-alert-buttons"
		case iconTemplate = "geocities-mac-icon-template"
		case buttonTemplate = "geocities-mac-button-template"
		case menuItemTemplate = "geocities-mac-menu-item-template"
		case rowTemplate = "geocities-mac-row-template"
		case resultTemplate = "geocities-mac-result-template"
		case keyTemplate = "geocities-mac-key-template"
		case stickyTemplate = "geocities-mac-sticky-template"
	}

	enum Hooks: String, ScriptDataAttributeSet {
		/**
		A key to hold at startup, like `shift`.
		*/
		case startupKey = "mac-startup-key"

		/**
		A window, by its name, like `puzzle`.
		*/
		case window = "mac-window"

		case titleBar = "mac-title-bar"
		case close = "mac-close"
		case collapse = "mac-collapse"
		case zoom = "mac-zoom"

		/**
		On a window while it is rolled up to its title bar, with WindowShade.
		*/
		case collapsed = "mac-collapsed"

		/**
		On a window while it fills the screen.
		*/
		case zoomed = "mac-zoomed"

		/**
		On the window in front.
		*/
		case front = "mac-front"

		/**
		An icon of the desktop or a Finder window, by the item it shows, like `trash`. `geocities-mac.js` makes the icons.
		*/
		case icon = "mac-icon"

		/**
		A command of a menu or a button, like `empty-trash`.
		*/
		case action = "mac-action"

		/**
		A part of a window that the script finds by its name, like the canvas of the Puzzle.
		*/
		case part = "mac-part"

		/**
		The title of a menu of the menu bar, by its name, like `apple`.
		*/
		case menu = "mac-menu"

		/**
		The list of a menu, by its name.
		*/
		case menuList = "mac-menu-list"

		/**
		A module of the Control Strip, like `volume`.
		*/
		case stripModule = "mac-strip-module"

		/**
		What Balloon Help says about the element.
		*/
		case balloonText = "mac-balloon"

		/**
		The theme of the Appearance, on the screen, like `bondi`.
		*/
		case theme = "mac-theme"

		/**
		The colors of the monitor, on the screen, like `gray`.
		*/
		case depth = "mac-depth"

		/**
		On an icon while it is selected, or while something is dragged over it.
		*/
		case selected = "mac-selected"

		/**
		On a desktop icon while the desktop file has forgotten its icon, until the desktop is rebuilt.
		*/
		case generic = "mac-generic"

		/**
		On the alert while it shows at the bottom of the screen, so the screen behind it shows, like the Sad Mac.
		*/
		case low = "mac-low"

		/**
		On the power light while the iMac sleeps.
		*/
		case sleeping = "mac-sleeping"
	}
}

extension GeoCitiesMacOS {
	/**
	The code-owned window catalog. Launchers and windows select the same entry rather than spelling IDs independently.
	*/
	struct Program: Hashable, Sendable {
		let rawValue: String
		let title: String
		let icon: String?

		private init(_ rawValue: String, title: String, icon: String? = nil) {
			self.rawValue = rawValue
			self.title = title
			self.icon = icon
		}

		static let about = Self("about", title: "About This Computer")
		static let info = Self("info", title: "Get Info")
		static let hardDrive = Self("hd", title: "Macintosh HD")
		static let applications = Self("apps", title: "Applications")
		static let trash = Self("trash", title: "Trash")
		static let clipboard = Self("clipboard", title: "Clipboard")
		static let switcher = Self("switcher", title: "Application Switcher")
		static let installer = Self("installer", title: "Mac OS 8.6 Install")
		static let extensions = Self("extensions", title: "Extensions Manager", icon: "extension")
		static let appearance = Self("appearance", title: "Appearance", icon: "appearance")
		static let speech = Self("speech", title: "Speech", icon: "speech")
		static let puzzle = Self("puzzle", title: "Puzzle", icon: "puzzle")
		static let notePad = Self("notepad", title: "Note Pad", icon: "notepad")
		static let scrapbook = Self("scrapbook", title: "Scrapbook", icon: "scrapbook")
		static let keyCaps = Self("keycaps", title: "Key Caps", icon: "keycaps")
		static let chooser = Self("chooser", title: "Chooser", icon: "chooser")
		static let pageSetup = Self("pagesetup", title: "Page Setup Options")
		static let stickies = Self("stickies", title: "Stickies", icon: "stickies")
		static let sherlock = Self("sherlock", title: "Sherlock", icon: "sherlock")
		static let graphing = Self("graphing", title: "Graphing Calculator", icon: "graphing")
		static let bugdom = Self("bugdom", title: "Bugdom Jr.", icon: "bugdom")
		static let netscape = Self("netscape", title: "Netscape: Sindre’s Home Page")
		static let simpleText = Self("simpletext", title: "SimpleText", icon: "simpletext")
		static let sticky = Self("sticky", title: "Stickies")

		/**
		The heading ID shared by the window and its accessible name.
		*/
		var windowTitleID: ElementID {
			ElementID("geocities-mac-title-\(rawValue)")
		}
	}

	/**
	The supported script commands. Only program actions accept an argument, and it must come from the catalog.
	*/
	struct Action: Sendable {
		let value: String

		private init(_ value: String) {
			self.value = value
		}

		/**
		Launches a catalog program using the script's existing wire format.
		*/
		static func launch(_ program: Program) -> Self {
			Self("launch-\(program.rawValue)")
		}

		/**
		Opens a catalog window without launching a separate application.
		*/
		static func open(_ program: Program) -> Self {
			Self("open-\(program.rawValue)")
		}

		static let newFolder = Self("new-folder")
		static let openSelected = Self("open-selected")
		static let closeWindow = Self("close-window")
		static let getInfo = Self("get-info")
		static let moveToTrash = Self("move-to-trash")
		static let putAway = Self("put-away")
		static let pageSetup = Self("page-setup")
		static let print = Self("print")
		static let quit = Self("quit")
		static let undo = Self("undo")
		static let copy = Self("copy")
		static let paste = Self("paste")
		static let clear = Self("clear")
		static let showClipboard = Self("show-clipboard")
		static let cleanUp = Self("clean-up")
		static let arrange = Self("arrange")
		static let emptyTrash = Self("empty-trash")
		static let eject = Self("eject")
		static let sleep = Self("sleep")
		static let restart = Self("restart")
		static let shutDown = Self("shut-down")
		static let balloons = Self("balloons")
	}

	/**
	A leaf command, also used directly by submenus: deeper submenu nesting is not supported.
	*/
	struct Command {
		let title: String
		let action: Action
		var icon: String?

		/**
		Uses the catalog's label and icon. A contextual title uses explicit Command construction.
		*/
		static func launch(_ program: Program) -> Self {
			Self(title: program.title, action: .launch(program), icon: program.icon)
		}
	}

	/**
	An item of a menu of the menu bar: a command, a submenu, like Control Panels in the Apple menu, or a line.
	*/
	enum MenuItem {
		case command(Command)
		case submenu(String, id: String, icon: String? = nil, commands: [Command])
		case separator
	}

	/**
	A menu of the menu bar.
	*/
	struct MenuBarMenu {
		let id: String
		let title: String
		let items: [MenuItem]

		static let all = [
			Self(
				id: "apple",
				title: "Apple",
				items: [
					.command(.init(title: Program.about.title, action: .open(.about))),
					.separator,
					.command(.launch(.bugdom)),
					.command(.launch(.chooser)),
					.submenu(
						"Control Panels",
						id: "control-panels",
						icon: "folder",
						commands: [
							.launch(.appearance),
							.launch(.extensions),
							.launch(.speech),
						]
					),
					.command(.launch(.graphing)),
					.command(.launch(.keyCaps)),
					.command(.launch(.notePad)),
					.command(.launch(.puzzle)),
					.command(.launch(.scrapbook)),
					.command(.launch(.sherlock)),
					.command(.launch(.simpleText)),
					.command(.launch(.stickies)),
				]
			),
			Self(
				id: "file",
				title: "File",
				items: [
					.command(.init(title: "New Folder", action: .newFolder)),
					.command(.init(title: "Open", action: .openSelected)),
					.command(.init(title: "Close Window", action: .closeWindow)),
					.command(.init(title: "Get Info", action: .getInfo)),
					.command(.init(title: "Move To Trash", action: .moveToTrash)),
					.command(.init(title: "Put Away", action: .putAway)),
					.separator,
					.command(.init(title: "Find…", action: .launch(.sherlock))),
					.separator,
					.command(.init(title: "Page Setup…", action: .pageSetup)),
					.command(.init(title: "Print…", action: .print)),
					.separator,
					.command(.init(title: "Quit", action: .quit)),
				]
			),
			Self(
				id: "edit",
				title: "Edit",
				items: [
					.command(.init(title: "Undo", action: .undo)),
					.separator,
					.command(.init(title: "Copy", action: .copy)),
					.command(.init(title: "Paste", action: .paste)),
					.command(.init(title: "Clear", action: .clear)),
					.separator,
					.command(.init(title: "Show Clipboard", action: .showClipboard)),
				]
			),
			Self(
				id: "view",
				title: "View",
				items: [
					.command(.init(title: "Clean Up", action: .cleanUp)),
					.command(.init(title: "Arrange by Name", action: .arrange)),
				]
			),
			Self(
				id: "special",
				title: "Special",
				items: [
					.command(.init(title: "Empty Trash…", action: .emptyTrash)),
					.separator,
					.command(.init(title: "Eject", action: .eject)),
					.separator,
					.command(.init(title: "Sleep", action: .sleep)),
					.command(.init(title: "Restart", action: .restart)),
					.command(.init(title: "Shut Down", action: .shutDown)),
				]
			),
			Self(
				id: "help",
				title: "Help",
				items: [
					.command(.init(title: "Show Balloons", action: .balloons)),
					.command(.init(title: "Mac OS Help (Read Me!)", action: .launch(.simpleText))),
				]
			),
		]
	}

	/**
	An item of a menu, as a button, a line, or a submenu that opens beside its item, or under it on a phone.
	*/
	struct MenuBarItem: HTML {
		let item: MenuItem

		var body: some HTML {
			switch item {
			case .command(let command):
				CommandItem(command: command)
			case .submenu(let title, let id, let icon, let commands):
				li {
					button(
						.type(.button),
						.hook(Hooks.action, value: "submenu"),
						.ariaExpanded(false),
						.ariaControls(ElementID("geocities-mac-menu-\(id)"))
					) {
						if let icon {
							MenuIcon(name: icon)
						}
						title
						span {
							"▶"
						}
						.accessibilityHidden()
						.style(Styles.submenuArrow)
					}
					.style(Styles.menuItem)

					ul(.id("geocities-mac-menu-\(id)"), .hidden) {
						for command in commands {
							CommandItem(command: command)
						}
					}
					.style(Styles.submenu)
				}
				.style(Styles.submenuSlot)
			case .separator:
				li {}
					.accessibilityHidden()
					.style(Styles.menuSeparator)
			}
		}
	}

	/**
	The same leaf markup at both menu levels, so script actions and accessible labels cannot drift.
	*/
	private struct CommandItem: HTML {
		let command: Command

		var body: some HTML<HTMLTag.li> {
			li {
				button(.type(.button), .hook(Hooks.action, value: command.action.value)) {
					if let icon = command.icon {
						MenuIcon(name: icon)
					}
					command.title
				}
				.style(Styles.menuItem)
			}
		}
	}

	/**
	A menu icon filled by the desktop script, with the same dimensions for commands and submenus.
	*/
	private struct MenuIcon: HTML {
		let name: String

		var body: some HTML<HTMLTag.img> {
			img(.alt(""), .width(16), .height(16), .hook(Hooks.part, value: "icon-\(name)"))
				.style(Styles.menuIcon)
		}
	}
}
