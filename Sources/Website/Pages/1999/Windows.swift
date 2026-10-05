import Elementary
import Foundation
import SiteKit

/**
More of Windows 98 on the desktop of my computer (``GeoCitiesPage/desktop``): the programs that came with it, like Calculator, the MS-DOS Prompt, WordPad with an Office Assistant, Internet Explorer with Dial-Up Networking, Network Neighborhood, My Documents, Media Player, Sound Recorder, FreeCell, and the Control Panel, and the jokes of the time: a program that stops responding and smears the screen, the illegal operation, Close Program with Ctrl+Alt+Del, the startup screen, a log on that Cancel gets past, the Welcome tour, the 3D Maze screen saver, the blue screen of the launch of Windows 98, the Active Desktop, Shut Down Windows with Stand by and MS-DOS mode, and the Quick Launch bar. The games and the fun stuff are components of their own, like ``GeoCitiesWindowsPinball`` and ``GeoCitiesWindowsFunStuff``. The windows open, drag, and close like the others of the desktop, with the window manager of `geocities.js`. `geocities-windows.js` runs the programs, the Start menu with its submenus, the menu of the right mouse button, the taskbar buttons, and the tray.
*/
struct GeoCitiesWindows: HTML {
	var body: some HTML {
		GeoCitiesPage.Deferred(programs)
		GeoCitiesPage.Deferred(morePrograms)
		GeoCitiesPage.Deferred(systemWindows)
		GeoCitiesPage.Deferred(overlays)
		GeoCitiesPage.Deferred(Self.window("pinball", title: "3D Pinball for Windows - Space Cadet", size: .wide) {
			GeoCitiesWindowsPinball()
		})
		GeoCitiesPage.Deferred(Self.window("hearts", title: "The Microsoft Hearts Network", size: .wide) {
			GeoCitiesWindowsHearts()
		})
		GeoCitiesPage.Deferred(Self.window("hover", title: "Hover!", size: .wide) {
			GeoCitiesWindowsHover()
		})
		GeoCitiesPage.Deferred(Self.window("jezzball", title: "JezzBall", size: .wide) {
			GeoCitiesWindowsJezzBall()
		})
		GeoCitiesPage.Deferred(Self.window("chips", title: "Chip’s Challenge", size: .wide) {
			GeoCitiesWindowsChips()
		})
		GeoCitiesPage.Deferred(Self.window("terminal", title: "HyperTerminal", size: .wide) {
			GeoCitiesWindowsTerminal()
		})
		GeoCitiesPage.Deferred(Self.window("goo", title: "Kai’s Power Goo", size: .wide) {
			GeoCitiesWindowsGoo()
		})
		GeoCitiesPage.Deferred(GeoCitiesWindowsFunStuff())
		GeoCitiesPage.Deferred(Self.window("rodent", title: "Rodent’s Revenge", size: .wide) {
			GeoCitiesWindowsRodent()
		})
		GeoCitiesPage.Deferred(Self.window("spider", title: "Spider Solitaire", size: .wide) {
			GeoCitiesWindowsSpider()
		})
		GeoCitiesPage.Deferred(Self.window("taipei", title: "Taipei", size: .wide) {
			GeoCitiesWindowsTaipei()
		})
		GeoCitiesPage.Deferred(Self.window("netmeeting", title: "Microsoft NetMeeting", size: .wide) {
			GeoCitiesWindowsNetMeeting()
		})
		GeoCitiesPage.Deferred(Self.window("encarta", title: "Microsoft Encarta Encyclopedia Deluxe 99", size: .wide) {
			GeoCitiesWindowsEncarta()
		})
		GeoCitiesPage.Deferred(Self.window("moviemaker", title: "3D Movie Maker", size: .wide) {
			GeoCitiesWindowsMovieMaker()
		})
		ModuleScript("/scripts/geocities-windows.js")
	}

	@HTMLBuilder
	private var programs: some HTML {
		Self.window("calc", title: "Calculator") {
			calculator
		}

		Self.window("dos", title: "MS-DOS Prompt", size: .wide) {
			dosPrompt
		}

		Self.window("wordpad", title: "LETTER TO SANTA 2000.DOC - WordPad", size: .wide) {
			wordPad
		}

		Self.window("ie", title: "Where do you want to go today? - Microsoft Internet Explorer", size: .wide) {
			internetExplorer
		}

		Self.window("dialup", title: "Connect To") {
			dialUp
		}

		Self.window("documents", title: "My Documents") {
			folder(list: Hooks.documentsList, status: Hooks.documentsStatus)
		}

		Self.window("network", title: "Network Neighborhood") {
			networkNeighborhood
		}

		Self.window("folder", title: "New Folder") {
			folder(list: Hooks.folderList, status: Hooks.folderStatus)
		}

		Self.window("viewer", title: "README.TXT - Notepad", size: .wide) {
			textViewer
		}
	}

	@HTMLBuilder
	private var morePrograms: some HTML {
		Self.window("media", title: "DANCING BABY.AVI - Media Player") {
			mediaPlayer
		}

		Self.window("sound", title: "Sound - Sound Recorder") {
			soundRecorder
		}

		Self.window("freecell", title: "FreeCell", size: .wide) {
			freeCell
		}

		Self.window("control", title: "Control Panel", size: .wide) {
			controlPanel
		}

		Self.window("fixer", title: "Y2K Fixer 2000 Deluxe") {
			y2kFixer
		}

		Self.window("find", title: "Find: All Files") {
			findFiles
		}
	}

	@HTMLBuilder
	private var systemWindows: some HTML {
		Self.window("run", title: "Run") {
			runDialog
		}

		Self.window("tasks", title: "Close Program") {
			closeProgram
		}

		Self.window("welcome", title: "Welcome to Windows 98", size: .wide) {
			welcome
		}

		Self.window("logon", title: "Welcome to Windows") {
			logOn
		}

		Self.window("shutdown", title: "Shut Down Windows") {
			shutDownDialog
		}

		Self.window("message", title: "Windows", describedBy: .messageText) {
			messageBox
		}
	}

	/**
	A window of the desktop, like those of ``GeoCitiesPage/desktopWindow(_:title:content:)``, with the same hooks, so the window manager of `geocities.js` opens, drags, and closes it. Some programs need a wider window. A message box is an alert dialog, described by its message, so a screen reader reads the message with the button that gets the focus.
	*/
	static func window<Content: HTML>(_ app: String, title: String, size: WindowSize = .normal, describedBy message: Hooks? = nil, @HTMLBuilder content: () -> Content) -> some HTML {
		section(.hook(GeoCitiesPage.Hooks.desktopWindow, value: app), .hidden, .tabindex(-1), .ariaLabelledBy("geocities-window-\(app)")) {
			div(.hook(GeoCitiesPage.Hooks.desktopTitleBar)) {
				h3(.id("geocities-window-\(app)")) {
					title
				}
				.style(GeoCitiesPage.Styles.desktopWindowTitle)

				button(.type(.button), .hook(GeoCitiesPage.Hooks.desktopClose)) {
					"×"
				}
				.accessibilityLabel("Close \(title)")
				.style(GeoCitiesPage.Styles.closeButton)
			}
			.style(GeoCitiesPage.Styles.titleBar, GeoCitiesPage.Styles.titleBarWithButton, GeoCitiesPage.Styles.desktopTitleBar)

			div {
				content()
			}
			.style(GeoCitiesPage.Styles.windowBody)
		}
		.attributes(.role("alertdialog"), .ariaDescribedBy(message?.rawValue ?? ""), when: message != nil)
		.style(GeoCitiesPage.Styles.window, size == .wide ? Styles.wideWindow : Styles.normalWindow)
	}

	/**
	The width of a window of the desktop.
	*/
	enum WindowSize {
		case normal
		case wide
	}

	/**
	A list of files and folders, like My Documents. `geocities-windows.js` adds the files with the file template.
	*/
	private func folder(list: Hooks, status: Hooks) -> some HTML {
		div {
			ul(.id(list)) {}
				.accessibilityLabel("Files")
				.style(Styles.fileList)

			p(.id(status), .role("status")) {}
				.style(GeoCitiesPage.Styles.statusBar)
		}
		.style(Styles.stack)
	}

	/**
	A button that closes its window, like Cancel.
	*/
	static func closeButton(_ title: String = "Cancel") -> some HTML {
		button(.type(.button), .hook(Hooks.close)) {
			title
		}
		.style(GeoCitiesPage.Styles.retroButton)
	}

	/**
	A label that only screen readers read, for a control whose purpose the window shows.
	*/
	static func hiddenLabel(_ text: String, for id: Hooks) -> some HTML {
		label(.for(id.rawValue)) {
			text
		}
		.style(VisuallyHidden.Styles.root)
	}
}

extension GeoCitiesWindows {
	/**
	An item of the Start menu: a program that opens its window, a command of `geocities-windows.js`, or a submenu.
	*/
	indirect enum MenuItem: Sendable {
		case program(id: String, title: String, icon: String)
		case command(id: String, title: String, icon: String)
		case submenu(id: String, title: String, icon: String, items: [MenuItem])
		case separator
	}

	/**
	The Start menu of Windows 98, with Programs, Documents, Settings, and Find as submenus. Shut Down is added by the desktop, as `geocities.js` runs it.
	*/
	static let startMenu: [MenuItem] = [
		.command(id: "update", title: "Windows Update", icon: "🌐"),
		.separator,
		.submenu(id: "programs", title: "Programs", icon: "📂", items: [
			.submenu(id: "accessories", title: "Accessories", icon: "📂", items: [
				.program(id: "calc", title: "Calculator", icon: "🧮"),
				.program(id: "paint", title: "Unicorn Paint", icon: "🎨"),
				.program(id: "wordpad", title: "WordPad", icon: "📄"),
				.program(id: "sound", title: "Sound Recorder", icon: "🎙️"),
				.program(id: "media", title: "Media Player", icon: "📼"),
				.program(id: "computer", title: "Disk Defragmenter", icon: "🧩"),
				.program(id: "tasks", title: "Close Program", icon: "⛔"),
				.program(id: "terminal", title: "HyperTerminal", icon: "📟"),
				.program(id: "netmeeting", title: "NetMeeting", icon: "📹"),
				.program(id: "dialer", title: "Phone Dialer", icon: "☎️"),
				.program(id: "scandisk", title: "ScanDisk", icon: "🩺"),
				.program(id: "cleanup", title: "Disk Cleanup", icon: "🧹"),
			]),
			.submenu(id: "games", title: "Games", icon: "📂", items: [
				.program(id: "pinball", title: "3D Pinball", icon: "🚀"),
				.program(id: "chips", title: "Chip’s Challenge", icon: "💾"),
				.program(id: "freecell", title: "FreeCell", icon: "♠️"),
				.program(id: "hearts", title: "Hearts", icon: "♥️"),
				.program(id: "hover", title: "Hover!", icon: "🛸"),
				.program(id: "jezzball", title: "JezzBall", icon: "⚛️"),
				.program(id: "rodent", title: "Rodent’s Revenge", icon: "🐭"),
				.program(id: "solitaire", title: "Solitaire", icon: "🃏"),
				.program(id: "spider", title: "Spider Solitaire", icon: "🕷️"),
				.program(id: "taipei", title: "Taipei", icon: "🀄"),
				.program(id: "sweeper", title: "Y2K Bugsweeper", icon: "🐛"),
			]),
			.program(id: "moviemaker", title: "3D Movie Maker", icon: "🎬"),
			.program(id: "encarta", title: "Encarta 99", icon: "📚"),
			.program(id: "goo", title: "Kai’s Power Goo", icon: "🫠"),
			.program(id: "bob", title: "Microsoft Bob", icon: "🤓"),
			.program(id: "antivirus", title: "Nordmann AntiVirus 99", icon: "🛡️"),
			.program(id: "winzip", title: "WinZip", icon: "🗜️"),
			.program(id: "ie", title: "Internet Explorer", icon: "🌐"),
			.program(id: "dialup", title: "Dial-Up Networking", icon: "📞"),
			.program(id: "dos", title: "MS-DOS Prompt", icon: "⬛"),
			.program(id: "fixer", title: "Y2K Fixer 2000", icon: "🩹"),
		]),
		.submenu(id: "documents", title: "Documents", icon: "📄", items: [
			.program(id: "notepad", title: "SECRET.TXT", icon: "📝"),
			.command(id: "readme", title: "README.TXT", icon: "📄"),
			.program(id: "wordpad", title: "LETTER TO SANTA 2000.DOC", icon: "📄"),
			.program(id: "documents", title: "My Documents", icon: "📁"),
		]),
		.submenu(id: "settings", title: "Settings", icon: "⚙️", items: [
			.program(id: "control", title: "Control Panel", icon: "🎛️"),
			.command(id: "web", title: "Active Desktop", icon: "🌐"),
			.command(id: "maze", title: "3D Maze Screen Saver", icon: "🧱"),
		]),
		.submenu(id: "find", title: "Find", icon: "🔍", items: [
			.program(id: "find", title: "Files or Folders…", icon: "🔍"),
		]),
		.program(id: "welcome", title: "Help", icon: "❓"),
		.program(id: "run", title: "Run…", icon: "🏃"),
		.separator,
		.command(id: "logoff", title: "Log Off Sindre…", icon: "🔑"),
	]

	/**
	The items of the Start menu, with submenus two levels deep, like Programs and Accessories.
	*/
	static var startMenuItems: some HTML {
		StartMenuItems<StartMenuItems<StartMenuItems<EmptyHTML>>>(items: startMenu) {
			StartMenuItems<StartMenuItems<EmptyHTML>>(items: $0) {
				StartMenuItems<EmptyHTML>(items: $0) { _ in
					EmptyHTML()
				}
			}
		}
	}

	/**
	The items of the Start menu, with a list for each submenu. A submenu opens to the side on a wide desktop, and under its item on a narrow one, like a phone. Each level of submenus makes the items of the next level with `submenu`, as a type cannot contain itself.
	*/
	struct StartMenuItems<Submenu: HTML>: HTML {
		let items: [MenuItem]
		let submenu: @Sendable ([MenuItem]) -> Submenu

		var body: some HTML {
			for item in items {
				if case .program(let id, let name, let icon) = item {
					li {
						button(.type(.button), .hook(GeoCitiesPage.Hooks.desktopOpen, value: id)) {
							MenuIcon(icon: icon)
							name
						}
						.style(GeoCitiesPage.Styles.startMenuItem)
					}
				} else if case .command(let id, let name, let icon) = item {
					li {
						button(.type(.button), .hook(Hooks.command, value: id)) {
							MenuIcon(icon: icon)
							name
						}
						.style(GeoCitiesPage.Styles.startMenuItem)
					}
				} else if case .submenu(let id, let name, let icon, let items) = item {
					li {
						button(.type(.button), .hook(Hooks.submenu, value: id), .ariaExpanded(false), .ariaControls("geocities-win-menu-\(id)")) {
							MenuIcon(icon: icon)
							name

							span {
								"▶"
							}
							.accessibilityHidden()
							.style(Styles.submenuArrow)
						}
						.style(GeoCitiesPage.Styles.startMenuItem)

						ul(.id("geocities-win-menu-\(id)"), .hidden) {
							submenu(items)
						}
						.style(Styles.submenu)
					}
					.style(Styles.submenuItem)
				} else {
					li {}
						.accessibilityHidden()
						.style(Styles.menuSeparator)
				}
			}
		}
	}

	/**
	The small picture of an item of the Start menu.
	*/
	struct MenuIcon: HTML {
		let icon: String

		var body: some HTML {
			span {
				icon
			}
			.accessibilityHidden()
			.style(Styles.menuIcon)
		}
	}

	/**
	The buttons of the taskbar for the open windows. `geocities-windows.js` adds a button for each window while it is open, which brings it to the front.
	*/
	struct TaskButtons: HTML {
		var body: some HTML {
			div(.id(Hooks.tasks), .role("group")) {}
				.accessibilityLabel("Open windows")
				.style(Styles.tasks)

			template(.id(Hooks.taskTemplate)) {
				button(.type(.button)) {}
					.style(Styles.taskButton)
			}
		}
	}

	/**
	The Quick Launch bar of Windows 98 next to the Start button, with Show Desktop, which hides all the windows until it is pressed again, and the arrow of Windows 95 that says where to begin, until the visitor clicks Start.
	*/
	struct QuickLaunch: HTML {
		var body: some HTML {
			div(.role("group")) {
				button(.id(Hooks.showDesktop), .type(.button), .ariaPressed(false)) {
					"🖥️"
				}
				.accessibilityLabel("Show Desktop")
				.help("Show Desktop")
				.style(Styles.trayButton)

				button(.type(.button), .hook(GeoCitiesPage.Hooks.desktopOpen, value: "ie")) {
					"🌐"
				}
				.accessibilityLabel("Launch Internet Explorer Browser")
				.help("Launch Internet Explorer Browser")
				.style(Styles.trayButton)
			}
			.accessibilityLabel("Quick Launch")
			.style(Styles.quickLaunch)

			p(.id(Hooks.beginHint), .hidden) {
				span {
					"◀"
				}
				.accessibilityHidden()
				.style(Styles.beginArrow)

				" Click here to begin."
			}
			.style(Styles.beginHint)
		}
	}

	/**
	The tray next to the clock: the volume, the mail that comes in, and the two computers of Dial-Up Networking while it is connected.
	*/
	struct Tray: HTML {
		var body: some HTML {
			div(.id(Hooks.tray)) {
				button(.id(Hooks.onlineButton), .type(.button), .hidden) {
					"📶"
				}
				.accessibilityLabel("Connected to the Internet at 28,800 bps")
				.help("Connected at 28,800 bps")
				.style(Styles.trayButton)

				button(.id(Hooks.mailButton), .type(.button), .hidden) {
					"✉️"
				}
				.accessibilityLabel("You have new mail")
				.help("You have new mail")
				.style(Styles.trayButton)

				button(.id(Hooks.volumeButton), .type(.button), .ariaExpanded(false), .ariaControls(Hooks.volume.rawValue)) {
					"🔊"
				}
				.accessibilityLabel("Volume")
				.help("Volume")
				.style(Styles.trayButton)

				div(.id(Hooks.volume), .hidden, .role("group")) {
					GeoCitiesWindows.hiddenLabel("Volume", for: .volumeLevel)

					input(.id(Hooks.volumeLevel), .type(.range), .min("0"), .max("100"), .value("70"))
						.style(Styles.volumeSlider)

					label {
						input(.id(Hooks.mute), .type(.checkbox))
						" Mute"
					}
				}
				.accessibilityLabel("Volume")
				.style(Styles.volumePopup)
			}
			.style(Styles.tray)
		}
	}
}
