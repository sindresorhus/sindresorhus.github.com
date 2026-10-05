import Elementary
import Foundation
import SiteKit

/**
The fun stuff of Windows 95 and 98 on the desktop of my computer (``GeoCitiesPage/desktop``), and the software that came along: BonziBUDDY, the purple gorilla who will not leave, Microsoft Bob with Rover the dog, the Windows 95 CD-ROM with its Fun Stuff videos (Weezer, the launch with “Start Me Up”, the cyber sitcom with the cast of Friends, and the Clean Install that makes the desktop dance), the Happy99 fireworks, an antivirus program, the nag screen of WinZip, Phone Dialer, ScanDisk, and Disk Cleanup. Its script, `WindowsFunStuff.js`, runs them, and asks its questions with the message box of `geocities-windows.js`.

It is one element with the windows of all these programs, and BonziBUDDY on the desktop outside them, as the programs play together: Happy99 infects the computer that the antivirus program scans, the antivirus program finds BonziBUDDY, the CD-ROM plays its videos in ActiveMovie, and Microsoft Bob opens the other programs.
*/
struct GeoCitiesWindowsFunStuff: ScriptedElement {
	static let script = ElementScript()

	var content: some HTML {
		GeoCitiesPage.Deferred(programs)
		GeoCitiesPage.Deferred(tools)
		GeoCitiesPage.Deferred(bonzi)
	}

	@HTMLBuilder
	private var programs: some HTML {
		GeoCitiesWindows.window("bonzi", title: "BonziBUDDY Setup") {
			bonziSetup
		}

		GeoCitiesWindows.window("bob", title: "Microsoft Bob", size: .wide) {
			bob
		}

		GeoCitiesWindows.window("cdrom", title: "Windows 95 CD-ROM (D:)", size: .wide) {
			cdrom
		}

		GeoCitiesWindows.window("movie", title: "ActiveMovie Control") {
			movie
		}

		GeoCitiesWindows.window("happy", title: "Happy99") {
			happy
		}
	}

	@HTMLBuilder
	private var tools: some HTML {
		GeoCitiesWindows.window("antivirus", title: "Nordmann AntiVirus 99", size: .wide) {
			antivirus
		}

		GeoCitiesWindows.window("winzip", title: "WinZip (Unregistered Version)", size: .wide) {
			winZip
		}

		GeoCitiesWindows.window("dialer", title: "Phone Dialer") {
			dialer
		}

		GeoCitiesWindows.window("scandisk", title: "ScanDisk - (C:)") {
			scanDisk
		}

		GeoCitiesWindows.window("cleanup", title: "Disk Cleanup for (C:)") {
			diskCleanup
		}
	}

	/**
	The setup of BonziBUDDY, which installs the gorilla on the desktop, whether the visitor wants it or not.
	*/
	private var bonziSetup: some HTML {
		div {
			p {
				"BonziBUDDY is your best friend on the Internet! He talks, he walks, he tells jokes, he sings, and he is 100% free.*"
			}

			p {
				"*BonziBUDDY may also show you some special offers. And change your home page. And remember everything."
			}
			.style(GeoCitiesPage.Styles.caption)

			span {
				span(.part(Parts.bonziProgress)) {}
					.style(GeoCitiesWindows.Styles.progressFill)
			}
			.accessibilityHidden()
			.style(GeoCitiesWindows.Styles.progressTrack)

			div {
				button(.part(Parts.bonziInstall), .type(.button)) {
					"Install My Friend"
				}
				.style(GeoCitiesPage.Styles.retroButton)

				button(.part(Parts.bonziDecline), .type(.button)) {
					"No Thanks"
				}
				.style(GeoCitiesPage.Styles.retroButton)
			}
			.style(GeoCitiesPage.Styles.row)

			p(.part(Parts.bonziSetupStatus), .role("status")) {}
				.style(GeoCitiesPage.Styles.statusBar)
		}
		.style(GeoCitiesWindows.Styles.stack)
	}

	/**
	BonziBUDDY on the desktop, over the icons: a purple gorilla that walks around, talks in a balloon, and comes back when he is sent away. He is hidden until he is installed.
	*/
	private var bonzi: some HTML {
		div(.part(Parts.bonzi), .hidden) {
			div(.id("geocities-fun-bonzi-balloon"), .part(Parts.bonziBalloon), .hidden) {
				p(.part(Parts.bonziText), .role("status")) {}

				div {
					for (action, title) in [("joke", "Tell me a joke"), ("fact", "Tell me a fact"), ("sing", "Sing a song (with sound)"), ("search", "Search the Web"), ("leave", "Go away")] {
						button(.type(.button), .hook(Hooks.bonziAction, value: action)) {
							title
						}
						.style(GeoCitiesWindows.Styles.assistantChoice)
					}

					label {
						input(.part(Parts.bonziVoice), .type(.checkbox))
						" Talk out loud (with sound)"
					}
					.style(Styles.bonziVoice)
				}
				.style(GeoCitiesWindows.Styles.stack)
			}
			.style(GeoCitiesWindows.Styles.assistantBalloon, Styles.bonziBalloon)

			button(.part(Parts.bonziButton), .type(.button), .ariaExpanded(false), .ariaControls("geocities-fun-bonzi-balloon")) {
				canvas(.part(Parts.bonziCanvas), .width(48), .height(56)) {}
					.accessibilityHidden()
					.style(Styles.bonziCanvas)
			}
			.accessibilityLabel("BonziBUDDY, the purple gorilla")
			.style(Styles.bonziButton)
		}
		.style(Styles.bonzi)
	}

	/**
	Microsoft Bob, a house instead of a desktop. The script shows the rooms from the template of an item, and Rover the dog explains everything, many times.
	*/
	private var bob: some HTML {
		div {
			form(.part(Parts.bobLogin)) {
				p {
					"Welcome to Bob’s house! Who are you?"
				}
				.style(Styles.bobTitle)

				div {
					label(.for("geocities-fun-bob-password")) {
						"Password for Sindre:"
					}

					input(.id("geocities-fun-bob-password"), .part(Parts.bobPassword), .type(.password), .autocomplete("off"), .maxlength(20))
						.style(GeoCitiesPage.Styles.field)
				}
				.style(GeoCitiesWindows.Styles.nowrapRow)

				button(.type(.submit)) {
					"Knock on the Door"
				}
				.style(GeoCitiesPage.Styles.retroButton)

				p(.part(Parts.bobLoginStatus), .role("status")) {}
			}
			.style(GeoCitiesWindows.Styles.stack, Styles.bobLogin)

			div(.part(Parts.bobHouse), .hidden) {
				p(.part(Parts.bobRoomName)) {
					"Family Room"
				}
				.style(Styles.bobTitle)

				ul(.part(Parts.bobRoom)) {}
					.accessibilityLabel("Things in the room")
					.style(Styles.bobRoom)

				div {
					p {
						"🐕"
					}
					.accessibilityHidden()
					.style(Styles.bobRover)

					p(.part(Parts.bobRoverText), .role("status")) {}
						.style(GeoCitiesWindows.Styles.assistantBalloon)
				}
				.style(Styles.bobRoverRow)
			}

			template(.part(Parts.bobItemTemplate)) {
				li {
					button(.type(.button)) {
						span {}
							.accessibilityHidden()
							.style(Styles.bobItemPicture)

						span {}
					}
					.style(Styles.bobItem)
				}
			}
		}
	}

	/**
	The Windows 95 CD-ROM, which plays its Autorun screen, with the Fun Stuff: the music videos, the launch, the video guide, the Clean Install, and the games.
	*/
	private var cdrom: some HTML {
		div {
			p {
				"Windows"
				span {
					"95"
				}
				.style(Styles.cdNumber)
			}
			.style(Styles.cdBanner)

			p {
				"Fun Stuff from the Windows 95 CD, and a bonus from Windows 98. Double-click nothing, just click."
			}
			.style(GeoCitiesPage.Styles.caption)

			ul {
				for (video, title, icon) in Self.videos {
					li {
						button(.type(.button), .hook(Hooks.video, value: video)) {
							span {
								icon
							}
							.accessibilityHidden()
							.style(GeoCitiesPage.Styles.desktopIconPicture)

							span {
								title
							}
						}
						.style(GeoCitiesWindows.Styles.fileButton)
					}
				}

				for (program, title, icon) in [("hover", "HOVER.EXE", "🛸"), ("pinball", "PINBALL.EXE", "🚀")] {
					li {
						button(.type(.button), .hook(GeoCitiesPage.Hooks.desktopOpen, value: program)) {
							span {
								icon
							}
							.accessibilityHidden()
							.style(GeoCitiesPage.Styles.desktopIconPicture)

							span {
								title
							}
						}
						.style(GeoCitiesWindows.Styles.fileButton)
					}
				}
			}
			.accessibilityLabel("Fun Stuff")
			.style(GeoCitiesWindows.Styles.fileList)

			p(.part(Parts.cdromStatus), .role("status")) {
				"7 object(s). Disk free space: 0 bytes. It is a CD."
			}
			.style(GeoCitiesPage.Styles.statusBar)
		}
		.style(GeoCitiesWindows.Styles.stack)
	}

	/**
	The videos of the Fun Stuff folder, by their ID in the script, which draws them.
	*/
	static let videos: [(id: String, title: String, icon: String)] = [
		("buddy", "BUDDYHOL.AVI", "🎸"),
		("goodtime", "GOODTIME.AVI", "🎤"),
		("launch", "LAUNCH95.AVI", "🚀"),
		("friends", "FRIENDS.AVI", "🛋️"),
		("clean", "CLEAN.AVI", "🕺"),
	]

	/**
	ActiveMovie, which plays the videos of the CD in a tiny picture at 15 frames a second, with captions, as the songs would cost too much.
	*/
	private var movie: some HTML {
		div {
			div {
				canvas(.part(Parts.movieCanvas), .width(160), .height(120), .role("img")) {}
					.accessibilityLabel("The video")
					.style(Styles.movieCanvas)
			}
			.style(GeoCitiesWindows.Styles.mediaScreen)

			p(.part(Parts.movieCaption), .custom(name: "aria-live", value: "polite")) {}
				.style(Styles.movieCaption)

			div {
				button(.part(Parts.moviePlay), .type(.button)) {
					"▶"
				}
				.accessibilityLabel("Play")
				.style(GeoCitiesPage.Styles.smallButton)

				button(.part(Parts.movieStop), .type(.button)) {
					"⏹"
				}
				.accessibilityLabel("Stop")
				.style(GeoCitiesPage.Styles.smallButton)

				span {
					span(.part(Parts.movieProgress)) {}
						.style(GeoCitiesWindows.Styles.progressFill)
				}
				.accessibilityHidden()
				.style(GeoCitiesWindows.Styles.progressTrack, GeoCitiesWindows.Styles.grow)

				label {
					input(.part(Parts.movieSound), .type(.checkbox))
					" Sound"
				}
			}
			.style(GeoCitiesWindows.Styles.toolbar)
		}
		.style(GeoCitiesWindows.Styles.stack)
	}

	/**
	Happy99, the fireworks that a friend sends by mail, which send themselves on to everybody.
	*/
	private var happy: some HTML {
		div {
			canvas(.part(Parts.happyCanvas), .width(240), .height(160), .role("img")) {}
				.accessibilityLabel("Fireworks, and the words Happy New Year 1999 !!")
				.style(Styles.happyCanvas)

			p(.part(Parts.happyStatus), .role("status")) {}
				.style(GeoCitiesPage.Styles.statusBar)
		}
		.style(GeoCitiesWindows.Styles.stack)
	}

	/**
	Nordmann AntiVirus 99, which scans the hard drive for real, file by file, and finds the viruses of 1999 and some that only live on my computer.
	*/
	private var antivirus: some HTML {
		div {
			p {
				"🛡️ Nordmann AntiVirus 99"
			}
			.style(Styles.antivirusLogo)

			div {
				button(.part(Parts.antivirusScan), .type(.button)) {
					"Scan Drive C:"
				}
				.style(GeoCitiesPage.Styles.retroButton)

				button(.part(Parts.antivirusUpdate), .type(.button)) {
					"LiveUpdate"
				}
				.style(GeoCitiesPage.Styles.retroButton)
			}
			.style(GeoCitiesPage.Styles.row)

			p(.part(Parts.antivirusFile)) {
				"Virus definitions: November 1998. Probably fine."
			}
			.style(Styles.antivirusFile)

			span {
				span(.part(Parts.antivirusProgress)) {}
					.style(GeoCitiesWindows.Styles.progressFill)
			}
			.accessibilityHidden()
			.style(GeoCitiesWindows.Styles.progressTrack)

			ul(.part(Parts.antivirusResults)) {}
				.accessibilityLabel("Viruses found")
				.style(GeoCitiesWindows.Styles.stack)

			template(.part(Parts.antivirusTemplate)) {
				li {
					p {}

					div {
						for action in ["Repair", "Quarantine", "Delete"] {
							button(.type(.button), .hook(Hooks.antivirusAction, value: action.lowercased())) {
								action
							}
							.style(GeoCitiesPage.Styles.smallButton)
						}
					}
					.style(GeoCitiesWindows.Styles.wrapRow)
				}
				.style(Styles.finding)
			}

			p(.part(Parts.antivirusStatus), .role("status")) {}
				.style(GeoCitiesPage.Styles.statusBar)
		}
		.style(GeoCitiesWindows.Styles.stack)
	}

	/**
	WinZip, with its nag screen, where the buttons swap places, and GAMES.ZIP, which extracts for real, into the folder of the desktop.
	*/
	private var winZip: some HTML {
		div {
			div(.part(Parts.winzipNag)) {
				p {
					"🗜️ WinZip 7.0 (Unregistered Version)"
				}
				.style(Styles.antivirusLogo)

				p(.part(Parts.winzipDays)) {
					"Thank you for trying WinZip! You have been using WinZip for 1,999 days. Please register."
				}

				div(.part(Parts.winzipButtons)) {
					for (choice, title) in [("agree", "I Agree"), ("quit", "Quit"), ("order", "Ordering Information")] {
						button(.type(.button), .hook(Hooks.winzipChoice, value: choice)) {
							title
						}
						.style(GeoCitiesPage.Styles.retroButton)
					}
				}
				.style(GeoCitiesPage.Styles.row)
			}
			.style(GeoCitiesWindows.Styles.stack)

			div(.part(Parts.winzipArchive), .hidden) {
				div {
					button(.part(Parts.winzipExtract), .type(.button)) {
						"📂 Extract"
					}
					.style(GeoCitiesWindows.Styles.toolbarButton)

					p {
						"GAMES.ZIP"
					}
					.style(GeoCitiesWindows.Styles.addressField)
				}
				.style(GeoCitiesWindows.Styles.toolbar)

				ul {
					for (file, size) in [("KEEN4.EXE", "105,000"), ("DOOM1.WAD", "4,196,020"), ("SKIFREE.EXE", "118,784"), ("LEMMINGS.EXE", "79,872"), ("README.TXT", "1,999"), ("CHEATS.TXT", "666")] {
						li {
							span {
								file
							}

							span {
								size
							}
						}
						.style(GeoCitiesWindows.Styles.programRow)
					}
				}
				.style(GeoCitiesPage.Styles.facts)

				span {
					span(.part(Parts.winzipProgress)) {}
						.style(GeoCitiesWindows.Styles.progressFill)
				}
				.accessibilityHidden()
				.style(GeoCitiesWindows.Styles.progressTrack)
			}
			.style(GeoCitiesWindows.Styles.stack)

			p(.part(Parts.winzipStatus), .role("status")) {}
				.style(GeoCitiesPage.Styles.statusBar)
		}
		.style(GeoCitiesWindows.Styles.stack)
	}

	/**
	Phone Dialer, which calls the numbers of the family with the tones of the keypad, unless the modem has the line.
	*/
	private var dialer: some HTML {
		div {
			form(.part(Parts.dialerForm)) {
				label(.for("geocities-fun-dialer-number")) {
					"Number to dial:"
				}
				.style(GeoCitiesPage.Styles.label)

				div {
					input(.id("geocities-fun-dialer-number"), .part(Parts.dialerNumber), .type(.tel), .autocomplete("off"), .maxlength(16))
						.style(GeoCitiesPage.Styles.field)

					button(.type(.submit)) {
						"Dial"
					}
					.style(GeoCitiesPage.Styles.retroButton)
				}
				.style(GeoCitiesWindows.Styles.nowrapRow)
			}
			.style(GeoCitiesWindows.Styles.stack)

			div {
				div(.role("group")) {
					for key in ["1", "2", "3", "4", "5", "6", "7", "8", "9", "*", "0", "#"] {
						button(.type(.button), .hook(Hooks.dialerKey, value: key)) {
							key
						}
						.style(GeoCitiesPage.Styles.retroButton)
					}
				}
				.accessibilityLabel("Keypad")
				.style(Styles.keypad)

				div(.role("group")) {
					p {
						"Speed dial"
					}
					.style(GeoCitiesPage.Styles.label)

					for (contact, title) in [("mamma", "Mamma (work)"), ("mormor", "Mormor"), ("pizza", "Peppes Pizza"), ("ingrid", "Ingrid (sister’s friend)"), ("bill", "Bill Gates")] {
						button(.type(.button), .hook(Hooks.dialerSpeed, value: contact)) {
							title
						}
						.style(GeoCitiesPage.Styles.smallButton)
					}
				}
				.accessibilityLabel("Speed dial")
				.style(GeoCitiesWindows.Styles.stack)
			}
			.style(Styles.dialerColumns)

			div {
				button(.part(Parts.dialerHangUp), .type(.button), .disabled) {
					"Hang Up"
				}
				.style(GeoCitiesPage.Styles.retroButton)

				label {
					input(.part(Parts.dialerSound), .type(.checkbox))
					" Play the tones (with sound)"
				}
			}
			.style(GeoCitiesWindows.Styles.wrapRow)

			div(.part(Parts.dialerLog), .role("log")) {}
				.style(Styles.dialerLog)
		}
		.style(GeoCitiesWindows.Styles.stack)
	}

	/**
	ScanDisk, which checks every cluster of the hard drive, with the bad ones in red.
	*/
	private var scanDisk: some HTML {
		div {
			fieldset {
				legend {
					"Type of test"
				}

				for (test, title) in [("standard", "Standard (checks files and folders for errors)"), ("thorough", "Thorough (also scans the disk surface, takes until 2000)")] {
					label {
						input(.type(.radio), .name("geocities-fun-scandisk-test"), .value(test), .hook(Hooks.scandiskTest, value: test))
							.attributes(.checked, when: test == "thorough")
						" \(title)"
					}
					.style(GeoCitiesPage.Styles.label)
				}
			}
			.style(Styles.fieldset)

			label {
				input(.part(Parts.scandiskFix), .type(.checkbox), .checked)
				" Automatically fix errors"
			}

			div {
				for index in 0..<Self.clusterCount {
					span(.hook(Hooks.scandiskCluster, value: "\(index)")) {}
						.style(Styles.cluster)
				}
			}
			.accessibilityHidden()
			.style(Styles.clusters)

			div {
				button(.part(Parts.scandiskStart), .type(.button)) {
					"Start"
				}
				.style(GeoCitiesPage.Styles.retroButton)

				GeoCitiesWindows.closeButton("Close")
			}
			.style(GeoCitiesPage.Styles.row)

			p(.part(Parts.scandiskStatus), .role("status")) {
				"Select the drive(s) you want to check for errors: (C:)"
			}
			.style(GeoCitiesPage.Styles.statusBar)
		}
		.style(GeoCitiesWindows.Styles.stack)
	}

	/**
	The number of clusters that ScanDisk shows.
	*/
	static let clusterCount = 120

	/**
	Disk Cleanup, which finds files to delete, and frees 0 bytes.
	*/
	private var diskCleanup: some HTML {
		div {
			p {
				"You can use Disk Cleanup to free up to 0 bytes of disk space on (C:)."
			}

			ul {
				for (item, title, size, isChecked) in [("internet", "Temporary Internet Files", "0 KB", true), ("recycle", "Recycle Bin", "0 KB", true), ("temporary", "Temporary files", "0 KB", false), ("gifs", "GIFs I might need someday", "3,900,000 KB", false)] {
					li {
						label {
							input(.type(.checkbox), .hook(Hooks.cleanupItem, value: item))
								.attributes(.checked, when: isChecked)
							" \(title)"
						}

						span {
							size
						}
					}
					.style(GeoCitiesWindows.Styles.programRow)
				}
			}
			.style(GeoCitiesWindows.Styles.stack)

			div {
				button(.part(Parts.cleanupStart), .type(.button)) {
					"OK"
				}
				.style(GeoCitiesPage.Styles.retroButton)

				GeoCitiesWindows.closeButton()
			}
			.style(GeoCitiesPage.Styles.row)

			span {
				span(.part(Parts.cleanupProgress)) {}
					.style(GeoCitiesWindows.Styles.progressFill)
			}
			.accessibilityHidden()
			.style(GeoCitiesWindows.Styles.progressTrack)

			p(.part(Parts.cleanupStatus), .role("status")) {}
				.style(GeoCitiesPage.Styles.statusBar)
		}
		.style(GeoCitiesWindows.Styles.stack)
	}

	enum Parts: String, ElementPartSet {
		case bonzi
		case bonziBalloon
		case bonziText
		case bonziVoice
		case bonziButton
		case bonziCanvas
		case bonziInstall
		case bonziDecline
		case bonziProgress
		case bonziSetupStatus
		case bobLogin
		case bobPassword
		case bobLoginStatus
		case bobHouse
		case bobRoomName
		case bobRoom
		case bobRoverText
		case bobItemTemplate
		case cdromStatus
		case movieCanvas
		case movieCaption
		case moviePlay
		case movieStop
		case movieProgress
		case movieSound
		case happyCanvas
		case happyStatus
		case antivirusScan
		case antivirusUpdate
		case antivirusFile
		case antivirusProgress
		case antivirusResults
		case antivirusTemplate
		case antivirusStatus
		case winzipNag
		case winzipDays
		case winzipButtons
		case winzipArchive
		case winzipExtract
		case winzipProgress
		case winzipStatus
		case dialerForm
		case dialerNumber
		case dialerHangUp
		case dialerSound
		case dialerLog
		case scandiskFix
		case scandiskStart
		case scandiskStatus
		case cleanupStart
		case cleanupProgress
		case cleanupStatus
	}

	/**
	The lists of the same kind of element, with a value for the script.
	*/
	enum Hooks: String, ScriptHookSet {
		/**
		What a choice of the balloon of BonziBUDDY does, like `joke`.
		*/
		case bonziAction = "data-fun-bonzi-action"

		/**
		A video of the CD, by its ID, like `buddy`.
		*/
		case video = "data-fun-video"

		/**
		What a button of a virus that was found does, like `delete`.
		*/
		case antivirusAction = "data-fun-antivirus-action"

		/**
		A button of the nag screen of WinZip, like `agree`.
		*/
		case winzipChoice = "data-fun-winzip-choice"

		/**
		A key of the keypad of Phone Dialer, like `5`.
		*/
		case dialerKey = "data-fun-dialer-key"

		/**
		A speed dial button, by the person it calls, like `mamma`.
		*/
		case dialerSpeed = "data-fun-dialer-speed"

		/**
		A radio button of the type of test of ScanDisk.
		*/
		case scandiskTest = "data-fun-scandisk-test"

		/**
		A cluster of the hard drive in ScanDisk, by its number.
		*/
		case scandiskCluster = "data-fun-scandisk-cluster"

		/**
		A kind of files that Disk Cleanup can delete, like `gifs`.
		*/
		case cleanupItem = "data-fun-cleanup-item"
	}

	enum Styles: ElementStyleSet {
		case root
		case bonzi
		case bonziBalloon
		case bonziVoice
		case bonziButton
		case bonziCanvas
		case bobLogin
		case bobTitle
		case bobRoom
		case bobItem
		case bobItemPicture
		case bobRoverRow
		case bobRover
		case cdBanner
		case cdNumber
		case movieCanvas
		case movieCaption
		case happyCanvas
		case antivirusLogo
		case antivirusFile
		case finding
		case keypad
		case dialerColumns
		case dialerLog
		case fieldset
		case clusters
		case cluster

		var style: Style {
			switch self {
			case .root:
				// The windows and BonziBUDDY stay in the desktop, which places them and stacks them, as if the element was not there.
				Style().display(.contents)
			case .bonzi:
				// Over the icons and under the windows, where the script walks him, with his balloon above him. While he talks, he comes in front of the windows, under the Start menu and the taskbar, as he wants to be heard.
				Style()
					.position(.absolute)
					.top(0)
					.leading(0)
					.zIndex(0)
					.vstack(alignment: .center, spacing: .rootEm(0.25))
					.when(.state, is: "talking") {
						$0.zIndex(900)
					}
			case .bonziBalloon:
				// Only the balloon is wide, so the space next to the gorilla still takes clicks for the icons under it.
				Style().frame(width: .rootEm(13), maxWidth: .viewportWidth(80))
			case .bonziVoice:
				Style()
					.fontFamily(.system)
					.textStyle(.caption)
			case .bonziButton:
				// The gorilla himself, which drags and opens his balloon.
				Style()
					.padding(0)
					.background(.transparent)
					.border(.transparent, width: 0)
					.lineHeight(0)
					.handCursor()
					.touchAction(.none)
					.focusVisible {
						$0.focusRing(.white, width: .pixels(1), offset: .pixels(2), style: .dotted)
					}
			case .bonziCanvas:
				Style()
					.frame(width: .pixels(96), height: .pixels(112))
					.imageRendering(.pixelated)
			case .bobLogin:
				// The front door of the house of Bob, with the yellow of his smile.
				Style()
					.padding(.rootEm(0.75))
					.background(Color("#fff3a8"))
					.border(Color("#c08000"), width: .pixels(2))
					.fontFamily(GeoCitiesPage.comicSans)
			case .bobTitle:
				Style()
					.fontFamily(GeoCitiesPage.comicSans)
					.font(.large, weight: .bold)
					.color(Color("#7a3d00"))
			case .bobRoom:
				// A room of the house, with wallpaper above and a wooden floor below, and the things of the room on it.
				Style()
					.grid(columns: 4)
					.gap(.rootEm(0.25))
					.padding(.rootEm(0.5))
					.backgroundImage(.linearGradient("to bottom", Color("#f6d7a7"), Color("#f6d7a7"), Color("#b5793b"), Color("#8a5626")))
					.border(Color("#7a3d00"), width: .pixels(3), style: .ridge)
			case .bobItem:
				Style()
					.vstack(alignment: .center, spacing: 0)
					.frame(width: .percent(100))
					.padding(.rootEm(0.25))
					.background(.transparent)
					.border(.transparent, width: .pixels(2))
					.cornerRadius(.rootEm(0.5))
					.fontFamily(GeoCitiesPage.comicSans)
					.textStyle(.caption)
					.color(.black)
					.handCursor()
					.hover {
						$0.border(Color("#ffcc00"), width: .pixels(2))
					}
					.focusVisible {
						$0.border(Color("#ff6600"), width: .pixels(2))
					}
			case .bobItemPicture:
				Style()
					.fontFamily(.system)
					.font(size: .rootEm(2), lineHeight: 1.1)
			case .bobRoverRow:
				Style().hstack(alignment: .center, spacing: .rootEm(0.5))
			case .bobRover:
				Style()
					.fontFamily(.system)
					.font(size: .rootEm(2.5), lineHeight: 1)
					.media(.allowsMotion) {
						$0.animation(GeoCitiesPage.Animations.petWiggle, .easeInOut(duration: .seconds(0.6)).repeatForever())
					}
			case .cdBanner:
				// The Autorun screen of the CD, with the clouds of Windows 95.
				Style()
					.padding(.rootEm(0.5))
					.backgroundImage(.linearGradient("to bottom", Color("#2f63c9"), Color("#9fc4f2")))
					.fontFamily(GeoCitiesPage.impact)
					.font(.extraLarge2)
					.color(.white)
					.textShadow(Shadow(x: .pixels(2), y: .pixels(2), color: .black))
			case .cdNumber:
				Style().color(Color("#ffcc00"))
			case .movieCanvas:
				Style()
					.display(.block)
					.frame(width: .percent(100), height: .auto)
					.aspectRatio(4.0 / 3.0)
					.background(.black)
					.imageRendering(.pixelated)
			case .movieCaption:
				Style()
					.frame(minHeight: .rootEm(2.5))
					.fontFamily(GeoCitiesPage.courier)
					.textStyle(.caption)
			case .happyCanvas:
				Style()
					.display(.block)
					.frame(width: .percent(100), height: .auto)
					.aspectRatio(3.0 / 2.0)
					.background(.black)
					.imageRendering(.pixelated)
			case .antivirusLogo:
				Style()
					.padding(.rootEm(0.375))
					.backgroundImage(.linearGradient("to right", Color("#ffcc00"), Color("#ffee88")))
					.fontFamily(.system)
					.font(.large, weight: .bold)
					.color(.black)
			case .antivirusFile:
				Style()
					.overflowWrap(.anywhere)
					.fontFamily(GeoCitiesPage.courier)
					.textStyle(.caption)
			case .finding:
				Style()
					.vstack(spacing: .rootEm(0.25))
					.padding(.rootEm(0.375))
					.background(Color("#ffe0e0"))
					.border(Color("#cc0000"), width: .pixels(1))
			case .keypad:
				Style()
					.grid(columns: 3)
					.gap(.rootEm(0.25))
			case .dialerColumns:
				Style()
					.grid(minimumColumnWidth: .rootEm(9))
					.gap(.rootEm(0.5))
			case .dialerLog:
				// The conversation, like a transcript, as Phone Dialer cannot play voices.
				Style()
					.frame(minHeight: .rootEm(4), maxHeight: .rootEm(10))
					.overflow(.auto)
					.padding(.rootEm(0.375))
					.background(.white)
					.border(Color("#808080"), width: .pixels(2), style: .inset)
					.fontFamily(GeoCitiesPage.courier)
					.textStyle(.caption)
					.preservesLineBreaks()
			case .fieldset:
				Style()
					.vstack(spacing: .rootEm(0.25))
					.padding(.rootEm(0.375))
					.border(Color("#808080"), width: .pixels(2), style: .groove)
			case .clusters:
				// The clusters of the hard drive, like the surface scan of ScanDisk.
				Style()
					.grid(columns: 20)
					.gap(.pixels(1))
					.padding(.pixels(2))
					.background(.black)
			case .cluster:
				// Gray until it is checked, then blue, and red with a B when it is bad.
				Style()
					.frame(height: .rootEm(0.6))
					.background(Color("#808080"))
					.fontFamily(GeoCitiesPage.courier)
					.font(size: .rootEm(0.5), lineHeight: 1.2)
					.textAlign(.center)
					.color(.white)
					.when(.state, is: "checked") {
						$0.background(Color("#0000aa"))
					}
					.when(.state, is: "bad") {
						$0.background(Color("#cc0000"))
					}
					.when(.state, is: "reading") {
						$0.background(Color("#ffff00"))
					}
			}
		}
	}
}
