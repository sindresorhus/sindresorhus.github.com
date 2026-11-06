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
		GeoCitiesPage.Deferred(Self.window(.pinball, title: "3D Pinball for Windows - Space Cadet", size: .wide) {
			GeoCitiesWindowsPinball()
		})
		GeoCitiesPage.Deferred(Self.window(.hearts, title: "The Microsoft Hearts Network", size: .wide) {
			GeoCitiesWindowsHearts()
		})
		GeoCitiesPage.Deferred(Self.window(.hover, size: .wide) {
			GeoCitiesWindowsHover()
		})
		GeoCitiesPage.Deferred(Self.window(.jezzball, size: .wide) {
			GeoCitiesWindowsJezzBall()
		})
		GeoCitiesPage.Deferred(Self.window(.chips, size: .wide) {
			GeoCitiesWindowsChips()
		})
		GeoCitiesPage.Deferred(Self.window(.terminal, size: .wide) {
			GeoCitiesWindowsTerminal()
		})
		GeoCitiesPage.Deferred(Self.window(.goo, size: .wide) {
			GeoCitiesWindowsGoo()
		})
		GeoCitiesPage.Deferred(GeoCitiesWindowsFunStuff())
		GeoCitiesPage.Deferred(Self.window(.rodent, size: .wide) {
			GeoCitiesWindowsRodent()
		})
		GeoCitiesPage.Deferred(Self.window(.spider, size: .wide) {
			GeoCitiesWindowsSpider()
		})
		GeoCitiesPage.Deferred(Self.window(.taipei, size: .wide) {
			GeoCitiesWindowsTaipei()
		})
		GeoCitiesPage.Deferred(Self.window(.netMeeting, title: "Microsoft NetMeeting", size: .wide) {
			GeoCitiesWindowsNetMeeting()
		})
		GeoCitiesPage.Deferred(Self.window(.encarta, title: "Microsoft Encarta Encyclopedia Deluxe 99", size: .wide) {
			GeoCitiesWindowsEncarta()
		})
		GeoCitiesPage.Deferred(Self.window(.movieMaker, size: .wide) {
			GeoCitiesWindowsMovieMaker()
		})
		ModuleScript(#path("/scripts/geocities-windows.js"))
	}

	@HTMLBuilder
	private var programs: some HTML {
		Self.window(.calculator) {
			calculator
		}

		Self.window(.msDosPrompt, size: .wide) {
			dosPrompt
		}

		Self.window(.wordPad, title: "LETTER TO SANTA 2000.DOC - WordPad", size: .wide) {
			wordPad
		}

		Self.window(.internetExplorer, title: "Where do you want to go today? - Microsoft Internet Explorer", size: .wide) {
			internetExplorer
		}

		Self.window(.dialUp, title: "Connect To") {
			dialUp
		}

		Self.window(.documents) {
			folder(list: IDs.documentsList, status: IDs.documentsStatus)
		}

		Self.window(.network) {
			networkNeighborhood
		}

		Self.window(.newFolder) {
			folder(list: IDs.folderList, status: IDs.folderStatus)
		}

		Self.window(.textViewer, size: .wide) {
			textViewer
		}
	}

	@HTMLBuilder
	private var morePrograms: some HTML {
		Self.window(.mediaPlayer, title: "DANCING BABY.AVI - Media Player") {
			mediaPlayer
		}

		Self.window(.soundRecorder, title: "Sound - Sound Recorder") {
			soundRecorder
		}

		Self.window(.freeCell, size: .wide) {
			freeCell
		}

		Self.window(.controlPanel, size: .wide) {
			controlPanel
		}

		Self.window(.fixer, title: "Y2K Fixer 2000 Deluxe") {
			y2kFixer
		}

		Self.window(.find, title: "Find: All Files") {
			findFiles
		}
	}

	@HTMLBuilder
	private var systemWindows: some HTML {
		Self.window(.run, title: "Run") {
			runDialog
		}

		Self.window(.tasks) {
			closeProgram
		}

		Self.window(.welcome, title: "Welcome to Windows 98", size: .wide) {
			welcome
		}

		Self.window(.logon) {
			logOn
		}

		Self.window(.shutdown) {
			shutDownDialog
		}

		Self.window(.message, describedBy: .messageText) {
			messageBox
		}
	}

	/**
	The programs whose stable IDs connect windows, desktop icons, and launchers.
	*/
	struct Program: Hashable, Sendable {
		/**
		The stable ID that connects the window, the desktop icon, and the launchers.
		*/
		let rawValue: String

		/**
		The title shared by the launchers, which a contextual document title can replace.
		*/
		let title: String

		/**
		The picture in the Start menu and on the desktop, which a contextual document icon can replace.
		*/
		let icon: String

		/**
		Creates one code-owned catalog entry; callers select an existing program instead of constructing an arbitrary ID.
		*/
		private init(_ rawValue: String, title: String, icon: String) {
			self.rawValue = rawValue
			self.title = title
			self.icon = icon
		}

		static let antivirus = Self("antivirus", title: "Nordmann AntiVirus 99", icon: "🛡️")
		static let bob = Self("bob", title: "Microsoft Bob", icon: "🤓")
		static let bonzi = Self("bonzi", title: "BonziBUDDY", icon: "🦍")
		static let calculator = Self("calc", title: "Calculator", icon: "🧮")
		static let cdRom = Self("cdrom", title: "Windows 95 CD (D:)", icon: "💿")
		static let chips = Self("chips", title: "Chip’s Challenge", icon: "💾")
		static let diskCleanup = Self("cleanup", title: "Disk Cleanup", icon: "🧹")
		static let computer = Self("computer", title: "Disk Defragmenter", icon: "🧩")
		static let controlPanel = Self("control", title: "Control Panel", icon: "🎛️")
		static let dialer = Self("dialer", title: "Phone Dialer", icon: "☎️")
		static let dialUp = Self("dialup", title: "Dial-Up Networking", icon: "📞")
		static let documents = Self("documents", title: "My Documents", icon: "📁")
		static let msDosPrompt = Self("dos", title: "MS-DOS Prompt", icon: "⬛")
		static let encarta = Self("encarta", title: "Encarta 99", icon: "📚")
		static let find = Self("find", title: "Files or Folders…", icon: "🔍")
		static let fixer = Self("fixer", title: "Y2K Fixer 2000", icon: "🩹")
		static let newFolder = Self("folder", title: "New Folder", icon: "🪟")
		static let freeCell = Self("freecell", title: "FreeCell", icon: "♠️")
		static let goo = Self("goo", title: "Kai’s Power Goo", icon: "🫠")
		static let happy = Self("happy", title: "Happy99.exe", icon: "🎆")
		static let hearts = Self("hearts", title: "Hearts", icon: "♥️")
		static let hover = Self("hover", title: "Hover!", icon: "🛸")
		static let internetExplorer = Self("ie", title: "Internet Explorer", icon: "🌐")
		static let jezzball = Self("jezzball", title: "JezzBall", icon: "⚛️")
		static let logon = Self("logon", title: "Welcome to Windows", icon: "🪟")
		static let mediaPlayer = Self("media", title: "Media Player", icon: "📼")
		static let message = Self("message", title: "Windows", icon: "🪟")
		static let movie = Self("movie", title: "ActiveMovie Control", icon: "🪟")
		static let movieMaker = Self("moviemaker", title: "3D Movie Maker", icon: "🎬")
		static let netMeeting = Self("netmeeting", title: "NetMeeting", icon: "📹")
		static let network = Self("network", title: "Network Neighborhood", icon: "🏘️")
		static let notepad = Self("notepad", title: "SECRET.TXT", icon: "📝")
		static let paint = Self("paint", title: "Unicorn Paint", icon: "🎨")
		static let pinball = Self("pinball", title: "3D Pinball", icon: "🚀")
		static let recycle = Self("recycle", title: "Recycle Bin", icon: "🗑️")
		static let rodent = Self("rodent", title: "Rodent’s Revenge", icon: "🐭")
		static let run = Self("run", title: "Run…", icon: "🏃")
		static let scanDisk = Self("scandisk", title: "ScanDisk", icon: "🩺")
		static let shutdown = Self("shutdown", title: "Shut Down Windows", icon: "🪟")
		static let solitaire = Self("solitaire", title: "Solitaire", icon: "🃏")
		static let soundRecorder = Self("sound", title: "Sound Recorder", icon: "🎙️")
		static let spider = Self("spider", title: "Spider Solitaire", icon: "🕷️")
		static let sweeper = Self("sweeper", title: "Y2K Bugsweeper", icon: "🐛")
		static let taipei = Self("taipei", title: "Taipei", icon: "🀄")
		static let tasks = Self("tasks", title: "Close Program", icon: "⛔")
		static let terminal = Self("terminal", title: "HyperTerminal", icon: "📟")
		static let textViewer = Self("viewer", title: "README.TXT - Notepad", icon: "🪟")
		static let welcome = Self("welcome", title: "Help", icon: "❓")
		static let winZip = Self("winzip", title: "WinZip", icon: "🗜️")
		static let wordPad = Self("wordpad", title: "WordPad", icon: "📄")

		/**
		The ID of the heading that names the window of this program.
		*/
		var windowTitleID: ElementID {
			ElementID("geocities-window-\(rawValue)")
		}
	}

	/**
	A window of the desktop, like Paint or Notepad, with a title bar to drag it by and a close button. It is hidden until its icon opens it. The window manager of `geocities.js` opens, drags, and closes it, also with Escape. Some programs need a wider window. A message box is an alert dialog, described by its message, so a screen reader reads the message with the button that gets the focus.
	*/
	static func window(
		_ program: Program,
		title: String? = nil,
		size: WindowSize = .normal,
		describedBy message: IDs? = nil,
		@HTMLBuilder content: () -> some HTML
	) -> some HTML {
		let title = title ?? program.title

		return section(
			.hook(GeoCitiesPage.Hooks.desktopWindow, value: program.rawValue),
			.hidden,
			.tabindex(-1),
			.ariaLabelledBy(program.windowTitleID)
		) {
			div(.hook(GeoCitiesPage.Hooks.desktopTitleBar)) {
				h3(.id(program.windowTitleID)) {
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
		.attributes(contentsOf: message.map { [.role(.alertDialog), .ariaDescribedBy($0.id)] } ?? [])
		.style(GeoCitiesPage.Styles.window)
		.style(GeoCitiesPage.Styles.desktopWindow, when: size == .normal)
		.style(Styles.wideWindow, when: size == .wide)
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
	private func folder(list: IDs, status: IDs) -> some HTML {
		div {
			ul(.id(list)) {}
				.accessibilityLabel("Files")
				.style(Styles.fileList)

			p(.id(status), .role(.status)) {}
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
	static func hiddenLabel(_ text: String, for control: IDs) -> some HTML {
		label(.for(control.id)) {
			text
		}
		.style(VisuallyHidden.Styles.root)
	}
}

extension GeoCitiesWindows {
	/**
	A desktop launcher for a program, with optional contextual presentation.
	*/
	struct DesktopItem {
		let program: Program
		private let titleOverride: String?
		private let iconOverride: String?

		/**
		Creates a launcher using the catalog presentation unless a document-specific title or icon is supplied.
		*/
		init(program: Program, title: String? = nil, icon: String? = nil) {
			self.program = program
			self.titleOverride = title
			self.iconOverride = icon
		}

		var title: String {
			titleOverride ?? program.title
		}

		var icon: String {
			iconOverride ?? program.icon
		}
	}

	/**
	An item of the Start menu: a program that opens its window, a command of `geocities-windows.js`, or a submenu.
	*/
	indirect enum MenuItem: Sendable {
		case program(Program, title: String? = nil, icon: String? = nil)
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
		.submenu(
			id: "programs",
			title: "Programs",
			icon: "📂",
			items: [
				.submenu(
					id: "accessories",
					title: "Accessories",
					icon: "📂",
					items: [
						.program(.calculator),
						.program(.paint),
						.program(.wordPad),
						.program(.soundRecorder),
						.program(.mediaPlayer),
						.program(.computer),
						.program(.tasks),
						.program(.terminal),
						.program(.netMeeting),
						.program(.dialer),
						.program(.scanDisk),
						.program(.diskCleanup),
					]
				),
				.submenu(
					id: "games",
					title: "Games",
					icon: "📂",
					items: [
						.program(.pinball),
						.program(.chips),
						.program(.freeCell),
						.program(.hearts),
						.program(.hover),
						.program(.jezzball),
						.program(.rodent),
						.program(.solitaire),
						.program(.spider),
						.program(.taipei),
						.program(.sweeper),
					]
				),
				.program(.movieMaker),
				.program(.encarta),
				.program(.goo),
				.program(.bob),
				.program(.antivirus),
				.program(.winZip),
				.program(.internetExplorer),
				.program(.dialUp),
				.program(.msDosPrompt),
				.program(.fixer),
			]
		),
		.submenu(
			id: "documents",
			title: "Documents",
			icon: "📄",
			items: [
				.program(.notepad),
				.command(id: "readme", title: "README.TXT", icon: "📄"),
				.program(.wordPad, title: "LETTER TO SANTA 2000.DOC"),
				.program(.documents),
			]
		),
		.submenu(
			id: "settings",
			title: "Settings",
			icon: "⚙️",
			items: [
				.program(.controlPanel),
				.command(id: "web", title: "Active Desktop", icon: "🌐"),
				.command(id: "maze", title: "3D Maze Screen Saver", icon: "🧱"),
			]
		),
		.submenu(
			id: "find",
			title: "Find",
			icon: "🔍",
			items: [
				.program(.find),
			]
		),
		.program(.welcome),
		.program(.run),
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
				if case .program(let program, let name, let icon) = item {
					li {
						button(.type(.button), .hook(GeoCitiesPage.Hooks.desktopOpen, value: program.rawValue)) {
							MenuIcon(icon: icon ?? program.icon)
							name ?? program.title
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
				} else if case .submenu(
					let id,
					let name,
					let icon,
					let items
				) = item {
					li {
						button(
							.type(.button),
							.hook(Hooks.submenu, value: id),
							.ariaExpanded(false),
							.ariaControls(ElementID("geocities-win-menu-\(id)"))
						) {
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
			div(.id(IDs.tasks), .role(.group)) {}
				.accessibilityLabel("Open windows")
				.style(Styles.tasks)

			template(.id(IDs.taskTemplate)) {
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
			div(.role(.group)) {
				button(.id(IDs.showDesktop), .type(.button), .ariaPressed(false)) {
					"🖥️"
				}
				.accessibilityLabel("Show Desktop")
				.help("Show Desktop")
				.style(Styles.trayButton)

				button(.type(.button), .hook(GeoCitiesPage.Hooks.desktopOpen, value: Program.internetExplorer.rawValue)) {
					"🌐"
				}
				.accessibilityLabel("Launch Internet Explorer Browser")
				.help("Launch Internet Explorer Browser")
				.style(Styles.trayButton)
			}
			.accessibilityLabel("Quick Launch")
			.style(Styles.quickLaunch)

			p(.id(IDs.beginHint), .hidden) {
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
			div(.id(IDs.tray)) {
				button(.id(IDs.onlineButton), .type(.button), .hidden) {
					"📶"
				}
				.accessibilityLabel("Connected to the Internet at 28,800 bps")
				.help("Connected at 28,800 bps")
				.style(Styles.trayButton)

				button(.id(IDs.mailButton), .type(.button), .hidden) {
					"✉️"
				}
				.accessibilityLabel("You have new mail")
				.help("You have new mail")
				.style(Styles.trayButton)

				button(
					.id(IDs.volumeButton),
					.type(.button),
					.ariaExpanded(false),
					.ariaControls(IDs.volume.id)
				) {
					"🔊"
				}
				.accessibilityLabel("Volume")
				.help("Volume")
				.style(Styles.trayButton)

				div(.id(IDs.volume), .hidden, .role(.group)) {
					GeoCitiesWindows.hiddenLabel("Volume", for: .volumeLevel)

					input(
						.id(IDs.volumeLevel),
						.type(.range),
						.min("0"),
						.max("100"),
						.value("70")
					)
						.style(Styles.volumeSlider)

					label {
						input(.id(IDs.mute), .type(.checkbox))
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
