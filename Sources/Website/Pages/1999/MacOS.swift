import Elementary
import Foundation
import SiteKit

/**
My real computer: the iMac in Bondi Blue with Mac OS 8.6, as it was, with its own look (the Platinum appearance with the striped title bars, the menu bar with the Apple menu and the Application menu, the Finder, and the Trash). It starts up with the chime, the Happy Mac, “Welcome to Mac OS”, and the icons of the extensions along the bottom, and the keys to hold while it starts (Shift for Extensions Off, Command and Option to rebuild the desktop, Command, Option, P, and R to zap the PRAM, and C for the CD). The things of Mac OS 8 that go wrong go wrong: an extension that conflicts and bombs at startup until the visitor finds it with the Extensions Manager, applications that unexpectedly quit with an error of a type, not enough memory for Bugdom Jr., blank icons until the desktop is rebuilt, the flashing question mark when the System Folder is in the Trash, and the Sad Mac with the Chimes of Death for RAM from the Internet. The desk accessories and the applications work: Puzzle, Stickies, Note Pad, the Scrapbook, Key Caps, the Chooser with a StyleWriter that is out of ink, Page Setup with Clarus the dogcow, Sherlock, the Graphing Calculator, SimpleText with the voices of PlainTalk, Netscape, the Appearance with its themes, desktop pictures, and sounds, the Control Strip, Balloon Help, and a game like Bugdom. `geocities-mac.js` runs all of it, and only makes a sound after the visitor turns on the speakers.
*/
struct GeoCitiesMacOS: HTML {
	let project: Project

	var body: some HTML {
		section(.id(Hooks.root), .tabindex(-1)) {
			h2 {
				"My iMac (the Real One)"
			}
			.style(GeoCitiesPage.Styles.heading, GeoCitiesPage.Styles.centeredText)

			p {
				GeoCitiesPage.GIFImage(gif: .buttonMacVsWindows, alt: "The Apple logo with a water pistol aimed at the Windows logo", style: .gif, project: project)
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
						div(.id(Hooks.tray), .hidden) {
							button(.id(Hooks.trayCD), .type(.button)) {
								"💿 Mac OS 8.6 CD (push the tray in)"
							}
							.style(Styles.trayCD)
						}
						.style(Styles.tray)

						button(.id(Hooks.power), .type(.button), .ariaPressed(false)) {
							span(.id(Hooks.led)) {}
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
				div(.id(Hooks.printer), .hidden) {
					canvas(.id(Hooks.printout), .width(240), .height(300)) {}
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
				button(.id(Hooks.speakers), .type(.button), .ariaPressed(false)) {
					"🔈 Turn on the speakers (the chime, beeps, sounds, and Talking Alerts)"
				}
				.style(GeoCitiesPage.Styles.retroButton)

				p {
					"Keys to hold down while it starts up (press one, then Restart from the Special menu, or the power button):"
				}
				.style(GeoCitiesPage.Styles.caption)

				div(.role("group")) {
					for (key, title) in Self.startupKeys {
						button(.type(.button), .hook(Hooks.startupKey, value: key), .ariaPressed(false)) {
							title
						}
						.style(Styles.keyCap)
					}
				}
				.accessibilityLabel("Keys to hold at startup")
				.style(Styles.keyRow)

				p(.id(Hooks.status), .role("status")) {}
					.style(Styles.status)
			}
			.style(Styles.below, GeoCitiesPage.Styles.scriptingOnly)

			p {
				"My iMac needs JavaScript. And more RAM."
			}
			.style(GeoCitiesPage.Styles.scriptingDisabledOnly)
		}
		.style(GeoCitiesPage.Styles.section)

		ModuleScript("/scripts/geocities-mac.js")
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
		div(.id(Hooks.screen)) {
			div(.id(Hooks.off)) {
				p(.id(Hooks.offText)) {
					"Press the power button below the screen."
				}
			}
			.style(Styles.off)

			div(.id(Hooks.boot), .hidden) {
				canvas(.id(Hooks.bootIcon), .width(96), .height(108)) {}
					.accessibilityHidden()
					.style(Styles.bootIcon)

				div(.id(Hooks.welcome), .hidden) {
					canvas(.id(Hooks.face), .width(64), .height(64)) {}
						.accessibilityHidden()
						.style(Styles.face)

					p {
						"Welcome to Mac OS"
					}
					.style(Styles.welcomeText)

					div {
						div(.id(Hooks.progress)) {}
							.style(Styles.progressBar)
					}
					.accessibilityHidden()
					.style(Styles.progressTrack)

					p(.id(Hooks.bootNote)) {}
						.style(Styles.bootNote)
				}
				.style(Styles.welcome)

				p(.id(Hooks.bootMessage), .role("status")) {}
					.style(Styles.bootMessage)

				div(.id(Hooks.extensionRow)) {}
					.accessibilityHidden()
					.style(Styles.extensionRow)
			}
			.style(Styles.boot)

			div(.id(Hooks.desktop), .hidden) {
				canvas(.id(Hooks.picture)) {}
					.accessibilityHidden()
					.style(Styles.picture)

				GeoCitiesPage.Deferred(menuBar)

				div(.id(Hooks.icons), .role("group")) {}
					.accessibilityLabel("Desktop")
					.style(Styles.icons)

				GeoCitiesPage.Deferred(GeoCitiesMacOSWindows())

				GeoCitiesPage.Deferred(controlStrip)

				p(.id(Hooks.balloon), .hidden, .role("tooltip")) {}
					.style(Styles.balloon)

				// The Flying Toasters of After Dark, when the desktop is left alone.
				canvas(.id(Hooks.saver), .hidden) {}
					.accessibilityHidden()
					.style(Styles.saver)
			}
			.style(Styles.desktop)

			div(.id(Hooks.alert), .hidden, .role("alertdialog"), .ariaModal, .tabindex(-1), .ariaDescribedBy(Hooks.alertText.rawValue)) {
				div {
					canvas(.id(Hooks.alertIcon), .width(32), .height(32)) {}
						.accessibilityHidden()
						.style(Styles.alertIcon)

					div {
						p(.id(Hooks.alertText)) {}
							.style(Styles.alertText)

						p(.id(Hooks.alertDetail)) {}
							.style(Styles.alertDetail)
					}
				}
				.style(Styles.alertMessage)

				div(.id(Hooks.alertButtons)) {}
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
		template(.id(Hooks.iconTemplate)) {
			button(.type(.button)) {
				img(.alt(""), .width(32), .height(32))
					.style(Styles.iconImage)
				span {}
					.style(Styles.iconLabel)
			}
			.style(Styles.icon)
		}

		template(.id(Hooks.buttonTemplate)) {
			button(.type(.button)) {}
				.style(Styles.button)
		}

		template(.id(Hooks.menuItemTemplate)) {
			li {
				button(.type(.button)) {}
					.style(Styles.menuItem)
			}
		}

		template(.id(Hooks.rowTemplate)) {
			li {
				label {
					input(.type(.checkbox))
					span {}
				}
				.style(Styles.row)
			}
		}

		template(.id(Hooks.resultTemplate)) {
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

		template(.id(Hooks.keyTemplate)) {
			button(.type(.button), .tabindex(-1)) {}
				.style(Styles.keyCapsKey)
		}

		template(.id(Hooks.stickyTemplate)) {
			GeoCitiesMacOSWindows.window("sticky", title: "Stickies", width: .small) {
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

				textarea(.rows(5), .maxlength(500), .autocomplete("off"), .hook(Hooks.part, value: "text")) {}
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
						button(.type(.button), .hook(Hooks.menu, value: menu.id), .ariaExpanded(false), .ariaControls("geocities-mac-menu-\(menu.id)")) {
							if menu.id == "apple" {
								img(.alt("Apple menu"), .width(16), .height(16), .hook(Hooks.part, value: "apple-logo"))
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
				button(.id(Hooks.clock), .type(.button)) {}
					.accessibilityLabel("Clock")
					.style(Styles.menuTitle)

				div {
					button(.id(Hooks.appMenuButton), .type(.button), .ariaExpanded(false), .ariaControls(Hooks.appMenu.rawValue)) {
						img(.alt(""), .width(16), .height(16))
							.style(Styles.menuIcon)
						span {
							"Finder"
						}
					}
					.accessibilityLabel("Application menu")
					.style(Styles.menuTitle)

					ul(.id(Hooks.appMenu), .hidden) {}
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
		div(.id(Hooks.strip)) {
			div(.id(Hooks.stripModules)) {
				for (module, icon, label) in [("volume", "🔊", "Volume"), ("depth", "🖥️", "Monitor colors"), ("appletalk", "🔗", "AppleTalk"), ("sharing", "📂", "File Sharing"), ("speech", "🗣️", "Talking Alerts")] {
					button(.type(.button), .hook(Hooks.stripModule, value: module), .hook(Hooks.balloonText, value: Self.stripBalloons[module] ?? "")) {
						icon
					}
					.accessibilityLabel(label)
					.style(Styles.stripModule)
				}
			}
			.style(Styles.stripModules)

			button(.id(Hooks.stripTab), .type(.button), .ariaExpanded(true), .ariaControls(Hooks.stripModules.rawValue)) {
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
	static let stripBalloons = [
		"volume": "Changes the volume of the speakers. Click it to go up a step. After 7 comes 0, like on my stereo.",
		"depth": "Changes the colors of the monitor, from Millions down to Black & White. Black & White is how my dad says computers looked when he was young.",
		"appletalk": "Turns AppleTalk on or off. The LaserWriter at Dad’s office needs it. Dad’s office is 40 km away, so it does not help.",
		"sharing": "Shares my iMac with the network. There is no network. It is me and my iMac.",
		"speech": "Turns Talking Alerts on or off, so the iMac reads the alerts out loud.",
	]

	enum Hooks: String, ScriptHookSet {
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

		/**
		A key to hold at startup, like `shift`.
		*/
		case startupKey = "data-mac-startup-key"

		/**
		A window, by its name, like `puzzle`.
		*/
		case window = "data-mac-window"

		case titleBar = "data-mac-title-bar"
		case close = "data-mac-close"
		case collapse = "data-mac-collapse"
		case zoom = "data-mac-zoom"

		/**
		On a window while it is rolled up to its title bar, with WindowShade.
		*/
		case collapsed = "data-mac-collapsed"

		/**
		On a window while it fills the screen.
		*/
		case zoomed = "data-mac-zoomed"

		/**
		On the window in front.
		*/
		case front = "data-mac-front"

		/**
		An icon of the desktop or a Finder window, by the item it shows, like `trash`. `geocities-mac.js` makes the icons.
		*/
		case icon = "data-mac-icon"

		/**
		A command of a menu or a button, like `empty-trash`.
		*/
		case action = "data-mac-action"

		/**
		A part of a window that the script finds by its name, like the canvas of the Puzzle.
		*/
		case part = "data-mac-part"

		/**
		The title of a menu of the menu bar, by its name, like `apple`.
		*/
		case menu = "data-mac-menu"

		/**
		The list of a menu, by its name.
		*/
		case menuList = "data-mac-menu-list"

		/**
		A module of the Control Strip, like `volume`.
		*/
		case stripModule = "data-mac-strip-module"

		/**
		What Balloon Help says about the element.
		*/
		case balloonText = "data-mac-balloon"

		/**
		The theme of the Appearance, on the screen, like `bondi`.
		*/
		case theme = "data-mac-theme"

		/**
		The colors of the monitor, on the screen, like `gray`.
		*/
		case depth = "data-mac-depth"

		/**
		On the Trash icon while something is in the Trash, so it bulges.
		*/
		case full = "data-mac-full"

		/**
		On an icon while it is selected, or while something is dragged over it.
		*/
		case selected = "data-mac-selected"

		/**
		On a desktop icon while the desktop file has forgotten its icon, until the desktop is rebuilt.
		*/
		case generic = "data-mac-generic"

		/**
		On the alert while it shows at the bottom of the screen, so the screen behind it shows, like the Sad Mac.
		*/
		case low = "data-mac-low"

		/**
		On the power light while the iMac sleeps.
		*/
		case sleeping = "data-mac-sleeping"
	}
}

extension GeoCitiesMacOS {
	/**
	An item of a menu of the menu bar: a command, a submenu, like Control Panels in the Apple menu, or a line.
	*/
	indirect enum MenuItem: Sendable {
		case command(String, action: String, icon: String? = nil)
		case submenu(String, id: String, icon: String? = nil, items: [MenuItem])
		case separator
	}

	/**
	A menu of the menu bar.
	*/
	struct MenuBarMenu: Sendable {
		let id: String
		let title: String
		let items: [MenuItem]

		static let all = [
			Self(id: "apple", title: "Apple", items: [
				.command("About This Computer", action: "open-about"),
				.separator,
				.command("Bugdom Jr.", action: "launch-bugdom", icon: "bugdom"),
				.command("Chooser", action: "launch-chooser", icon: "chooser"),
				.submenu("Control Panels", id: "control-panels", icon: "folder", items: [
					.command("Appearance", action: "launch-appearance", icon: "appearance"),
					.command("Extensions Manager", action: "launch-extensions", icon: "extension"),
					.command("Speech", action: "launch-speech", icon: "speech"),
				]),
				.command("Graphing Calculator", action: "launch-graphing", icon: "graphing"),
				.command("Key Caps", action: "launch-keycaps", icon: "keycaps"),
				.command("Note Pad", action: "launch-notepad", icon: "notepad"),
				.command("Puzzle", action: "launch-puzzle", icon: "puzzle"),
				.command("Scrapbook", action: "launch-scrapbook", icon: "scrapbook"),
				.command("Sherlock", action: "launch-sherlock", icon: "sherlock"),
				.command("SimpleText", action: "launch-simpletext", icon: "simpletext"),
				.command("Stickies", action: "launch-stickies", icon: "stickies"),
			]),
			Self(id: "file", title: "File", items: [
				.command("New Folder", action: "new-folder"),
				.command("Open", action: "open-selected"),
				.command("Close Window", action: "close-window"),
				.command("Get Info", action: "get-info"),
				.command("Move To Trash", action: "move-to-trash"),
				.command("Put Away", action: "put-away"),
				.separator,
				.command("Find…", action: "launch-sherlock"),
				.separator,
				.command("Page Setup…", action: "page-setup"),
				.command("Print…", action: "print"),
				.separator,
				.command("Quit", action: "quit"),
			]),
			Self(id: "edit", title: "Edit", items: [
				.command("Undo", action: "undo"),
				.separator,
				.command("Copy", action: "copy"),
				.command("Paste", action: "paste"),
				.command("Clear", action: "clear"),
				.separator,
				.command("Show Clipboard", action: "show-clipboard"),
			]),
			Self(id: "view", title: "View", items: [
				.command("Clean Up", action: "clean-up"),
				.command("Arrange by Name", action: "arrange"),
			]),
			Self(id: "special", title: "Special", items: [
				.command("Empty Trash…", action: "empty-trash"),
				.separator,
				.command("Eject", action: "eject"),
				.separator,
				.command("Sleep", action: "sleep"),
				.command("Restart", action: "restart"),
				.command("Shut Down", action: "shut-down"),
			]),
			Self(id: "help", title: "Help", items: [
				.command("Show Balloons", action: "balloons"),
				.command("Mac OS Help (Read Me!)", action: "launch-simpletext"),
			]),
		]
	}

	/**
	An item of a menu, as a button, a line, or a submenu that opens beside its item, or under it on a phone.
	*/
	struct MenuBarItem: HTML {
		let item: MenuItem

		var body: some HTML {
			if case .command(let title, let action, let icon) = item {
				li {
					button(.type(.button), .hook(Hooks.action, value: action)) {
						if let icon {
							img(.alt(""), .width(16), .height(16), .hook(Hooks.part, value: "icon-\(icon)"))
								.style(Styles.menuIcon)
						}
						title
					}
					.style(Styles.menuItem)
				}
			} else if case .submenu(let title, let id, let icon, let items) = item {
				li {
					button(.type(.button), .hook(Hooks.action, value: "submenu"), .ariaExpanded(false), .ariaControls("geocities-mac-menu-\(id)")) {
						if let icon {
							img(.alt(""), .width(16), .height(16), .hook(Hooks.part, value: "icon-\(icon)"))
								.style(Styles.menuIcon)
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
						for item in items {
							if case .command(let title, let action, let icon) = item {
								li {
									button(.type(.button), .hook(Hooks.action, value: action)) {
										if let icon {
											img(.alt(""), .width(16), .height(16), .hook(Hooks.part, value: "icon-\(icon)"))
												.style(Styles.menuIcon)
										}
										title
									}
									.style(Styles.menuItem)
								}
							}
						}
					}
					.style(Styles.submenu)
				}
				.style(Styles.submenuSlot)
			} else {
				li {}
					.accessibilityHidden()
					.style(Styles.menuSeparator)
			}
		}
	}
}
