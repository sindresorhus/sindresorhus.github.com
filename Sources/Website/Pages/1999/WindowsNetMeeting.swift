import Elementary
import Foundation
import SiteKit

/**
Microsoft NetMeeting 2.1 (1996 to 1999, it came with Windows 98) on the desktop of my computer (``GeoCitiesPage/desktop``), for a video call with my grandmother in Ålesund, who just got a computer. It has the look of NetMeeting: the gray toolbar with Call, Hang Up, Share, Collaborate, Chat, Whiteboard, and Send File, the audio bar with the microphone and the speaker and their level meters, and the dark bar on the left with Directory, SpeedDial, Current Call, and History. The Directory logs on to the ILS server “ils.microsoft.com”, which is busy the first time, like it always was, and lists the strangers of 1999 who were logged on. A call rings, and Mormor ignores the first one, because she thought it was a virus, and then calls back. Her video is a tiny picture of 160 × 120 at 2 frames per second, drawn on a canvas in big blocks: her face too close to the camera, then only her forehead, then the ceiling, the cat, and her empty chair, and it freezes in a funny moment, with her mouth open. The slider of Faster video and Better quality changes the frames and the blocks. Her sound comes seconds after her lips move, so we talk over each other, and the subtitles say what she says, read aloud in an old voice once the sound is on. My own video is a drawn Sindre, or the real webcam of the visitor after an explicit button, made blocky at 160 × 120. In the Chat, Mormor types with caps lock on and one finger, letter by letter, with typos. On the Whiteboard, we both draw, and she draws a cat that looks like a potato. She sends a photo of the cat that takes forever over the modem, faster with the video paused, and it appears from the bottom up, like a BMP. When I share my desktop and let her collaborate, she clicks everything, until Escape takes the control back. When I say goodbye, she cannot find Hang Up, and in the end she pulls the plug. And Mamma picks up the phone, so the modem line drops. It is the content of its window of the desktop, and its script, `WindowsNetMeeting.js`, runs it and keeps the history of the calls in the browser.
*/
struct GeoCitiesWindowsNetMeeting: ScriptedElement {
	static let script = ElementScript()

	/**
	The views of the bar on the left, by the value the script knows them by.
	*/
	private static let views: [(value: String, title: String, icon: String)] = [
		("directory", "Directory", "📖"),
		("speeddial", "SpeedDial", "⚡"),
		("call", "Current Call", "📞"),
		("history", "History", "🕘"),
	]

	/**
	The buttons of the toolbar, by the part the script knows them by.
	*/
	private static let toolbar: [(part: Parts, title: String, icon: String)] = [
		(.call, "Call", "📞"),
		(.hangUp, "Hang Up", "📴"),
		(.share, "Share", "🖥️"),
		(.collaborate, "Collaborate", "🤝"),
		(.chat, "Chat", "💬"),
		(.whiteboard, "Whiteboard", "✏️"),
		(.sendFile, "Send File", "📁"),
	]

	/**
	What I can say to Mormor in a call, by the value the script knows it by.
	*/
	private static let lines: [(value: String, title: String)] = [
		("hello", "Hei, Mormor!"),
		("hear", "Can you hear me?"),
		("camera", "Move the camera down"),
		("cat", "Where is Pusen?"),
		("draw", "Draw something!"),
		("love", "Jeg er glad i deg"),
		("bye", "Ha det, Mormor!"),
	]

	/**
	The colors of the pen of the Whiteboard, by the name the script knows them by.
	*/
	private static let colors: [(name: String, hex: String)] = [
		("black", "#000000"),
		("red", "#ff0000"),
		("blue", "#0000ff"),
		("green", "#008000"),
		("orange", "#ff8000"),
	]

	/**
	The servers of the Directory, which the visitor can pick.
	*/
	private static let servers = ["ils.microsoft.com", "ils1.microsoft.com", "ils2.microsoft.com", "ils3.microsoft.com", "ils4.microsoft.com", "ils5.microsoft.com"]

	var content: some HTML {
		Toolbar()
		AudioBar()

		div {
			div(.role("group")) {
				for (index, view) in GeoCitiesWindowsNetMeeting.views.enumerated() {
					button(.type(.button), .hook(Hooks.view, value: view.value), .ariaPressed(index == 0)) {
						span {
							view.icon
						}
						.accessibilityHidden()
						.style(Styles.navIcon)

						span {
							view.title
						}
					}
					.style(Styles.navButton)
				}
			}
			.accessibilityLabel("Views")
			.style(Styles.nav)

			div {
				Directory()
				SpeedDial()
				CurrentCall()
				History()
			}
			.style(Styles.content)
		}
		.style(Styles.main, GeoCitiesPage.Styles.scriptingOnly)

		div {
			p(.part(Parts.status), .role("status")) {
				"Logging on to ils.microsoft.com…"
			}
			.style(GeoCitiesPage.Styles.statusBar, Styles.statusLine)

			p(.part(Parts.callInfo)) {
				"Not in a call"
			}
			.style(GeoCitiesPage.Styles.statusBar)
		}
		.style(GeoCitiesWindows.Styles.wrapRow, GeoCitiesPage.Styles.scriptingOnly)

		p {
			"NetMeeting needs JavaScript. Mormor is still looking for the On button."
		}
		.style(GeoCitiesPage.Styles.scriptingDisabledOnly)
	}

	private struct Toolbar: HTML {
		var body: some HTML {
			div(.role("group")) {
				for item in GeoCitiesWindowsNetMeeting.toolbar {
					button(.part(item.part), .type(.button)) {
						span {
							item.icon
						}
						.accessibilityHidden()

						span {
							item.title
						}
						.style(GeoCitiesWindows.Styles.toolbarLabel)
					}
					.accessibilityLabel(item.title)
					.help(item.title)
					.attributes(.ariaPressed(false), when: [Parts.share, .collaborate, .chat, .whiteboard, .sendFile].contains(item.part))
					.style(GeoCitiesWindows.Styles.toolbarButton)
				}

				button(.part(Parts.sound), .type(.button), .ariaPressed(false)) {
					span {
						"🔈"
					}
					.accessibilityHidden()

					span {
						"Sound"
					}
					.style(GeoCitiesWindows.Styles.toolbarLabel)
				}
				.accessibilityLabel("Sound")
				.help("Plays the ringing, the modem, and Mormor’s voice")
				.style(GeoCitiesWindows.Styles.toolbarButton)
			}
			.accessibilityLabel("Toolbar")
			.style(GeoCitiesWindows.Styles.toolbar, Styles.toolbar, GeoCitiesPage.Styles.scriptingOnly)
		}
	}

	/**
	The audio bar of NetMeeting 2: the microphone and the speaker, each with a check box that turns it on and a meter of how loud it is.
	*/
	private struct AudioBar: HTML {
		var body: some HTML {
			div {
				label {
					input(.part(Parts.microphone), .type(.checkbox), .checked)
					"🎤 Microphone"
				}
				.style(Styles.audioToggle)

				span {
					span(.part(Parts.microphoneLevel)) {}
						.style(Styles.meterFill)
				}
				.accessibilityHidden()
				.style(Styles.meter)

				label {
					input(.part(Parts.speaker), .type(.checkbox), .checked)
					"🔈 Speaker"
				}
				.style(Styles.audioToggle)

				span {
					span(.part(Parts.speakerLevel)) {}
						.style(Styles.meterFill)
				}
				.accessibilityHidden()
				.style(Styles.meter)

				span(.part(Parts.delay)) {
					"Delay –"
				}
				.help("How late the sound arrives over the modem")
				.style(GeoCitiesPage.Styles.lcd, Styles.delay)
			}
			.style(GeoCitiesWindows.Styles.wrapRow, Styles.audioBar, GeoCitiesPage.Styles.scriptingOnly)
		}
	}

	private struct Directory: HTML {
		var body: some HTML {
			div(.hook(Hooks.panel, value: "directory")) {
				div {
					label(.for("geocities-netmeeting-server")) {
						"Server:"
					}

					select(.id("geocities-netmeeting-server"), .part(Parts.server)) {
						for server in GeoCitiesWindowsNetMeeting.servers {
							option(.value(server)) {
								server
							}
						}
					}
					.style(GeoCitiesWindows.Styles.toolbarSelect)

					button(.part(Parts.refresh), .type(.button)) {
						"🔄 Refresh"
					}
					.style(GeoCitiesPage.Styles.smallButton)
				}
				.style(GeoCitiesWindows.Styles.wrapRow)

				p {
					"Category: Personal (suitable for all ages)"
				}
				.style(GeoCitiesPage.Styles.caption)

				div {
					table {
						caption {
							"People logged on to the directory"
						}
						.style(VisuallyHidden.Styles.root)

						thead {
							tr {
								th(.scope(.col)) {
									span {
										"🔊📹"
									}
									.accessibilityHidden()

									span {
										"Audio and video"
									}
									.style(VisuallyHidden.Styles.root)
								}
								.style(Styles.headerCell)

								for title in ["Name", "E-mail", "City", "Comments"] {
									th(.scope(.col)) {
										title
									}
									.style(Styles.headerCell)
								}
							}
						}

						tbody(.part(Parts.directoryRows)) {}
					}
					.style(Styles.directoryTable)
				}
				.style(Styles.directoryBox)

				template(.part(Parts.rowTemplate)) {
					tr {
						td {}
							.style(Styles.cell)

						td {
							button(.type(.button)) {}
								.style(Styles.rowButton)
						}
						.style(Styles.cell)

						td {}
							.style(Styles.cell)

						td {}
							.style(Styles.cell)

						td {}
							.style(Styles.cell)
					}
					.style(Styles.directoryRow)
				}

				p {
					"Click a name, then 📞 Call. Or double-click it."
				}
				.style(GeoCitiesPage.Styles.caption)
			}
			.style(Styles.panel)
		}
	}

	private struct SpeedDial: HTML {
		var body: some HTML {
			div(.hook(Hooks.panel, value: "speeddial"), .hidden) {
				p {
					strong {
						"SpeedDial"
					}
					" calls without the directory."
				}

				div {
					for (value, title) in [("mormor", "👵 Mormor (mormor.alesund@online.no)"), ("trond", "🧢 Trond (trond99@online.no)"), ("pappa", "👔 Pappa’s office")] {
						button(.type(.button), .hook(Hooks.dial, value: value)) {
							title
						}
						.style(GeoCitiesPage.Styles.retroButton)
					}
				}
				.style(GeoCitiesWindows.Styles.stack)
			}
			.style(Styles.panel)
		}
	}

	/**
	Mormor’s video and mine, side by side, each with its button.
	*/
	private struct Videos: HTML {
		var body: some HTML {
			div {
				figure {
					canvas(.part(Parts.remoteVideo), .width(160), .height(120), .role("img")) {}
						.accessibilityLabel("Mormor’s video")
						.style(Styles.video)

					figcaption {
						span(.part(Parts.remoteLabel)) {
							"Mormor"
						}
						.style(GeoCitiesWindows.Styles.grow)

						button(.part(Parts.remotePause), .type(.button), .ariaPressed(false)) {
							"❚❚"
						}
						.accessibilityLabel("Pause Mormor’s video")
						.help("Pause the video, so files go faster")
						.style(GeoCitiesPage.Styles.smallButton)
					}
					.style(Styles.videoCaption)
				}
				.style(Styles.videoFigure)

				figure {
					canvas(.part(Parts.localVideo), .width(160), .height(120), .role("img")) {}
						.accessibilityLabel("My video: a drawing of Sindre")
						.style(Styles.video)

					figcaption {
						span {
							"My Video"
						}
						.style(GeoCitiesWindows.Styles.grow)

						button(.part(Parts.webcam), .type(.button), .ariaPressed(false)) {
							"📷"
						}
						.accessibilityLabel("Use my real webcam")
						.help("Use my real webcam")
						.style(GeoCitiesPage.Styles.smallButton)
					}
					.style(Styles.videoCaption)
				}
				.style(Styles.videoFigure)
			}
			.style(Styles.videos)
		}
	}

	private struct CurrentCall: HTML {
		var body: some HTML {
			div(.hook(Hooks.panel, value: "call"), .hidden) {
				p(.part(Parts.notInCall)) {
					"You are not in a call. Press 📞 Call to call Mormor."
				}

				div(.part(Parts.callArea), .hidden) {
					Videos()

					div(.role("group")) {
						p(.part(Parts.subtitleMormor)) {}
						p(.part(Parts.subtitleYou)) {}
					}
					.accessibilityLabel("What we say")
					.style(Styles.subtitles)

					div(.role("group")) {
						for (value, title) in GeoCitiesWindowsNetMeeting.lines {
							button(.type(.button), .hook(Hooks.say, value: value)) {
								title
							}
							.style(GeoCitiesPage.Styles.smallButton, Styles.sayButton)
						}
					}
					.accessibilityLabel("Say")
					.style(GeoCitiesWindows.Styles.wrapRow)

					div {
						label(.for("geocities-netmeeting-quality")) {
							"Faster video"
						}

						input(.id("geocities-netmeeting-quality"), .part(Parts.quality), .type(.range), .min(1), .max(3), .step(1), .value("2"))
							.style(Styles.quality)

						span {
							"Better quality"
						}
						.accessibilityHidden()
					}
					.style(GeoCitiesWindows.Styles.wrapRow, Styles.qualityRow)

					ChatPanel()
					WhiteboardPanel()
					SharePanel()
					TransferPanel()
				}
				.style(GeoCitiesWindows.Styles.stack)
			}
			.style(Styles.panel)
		}
	}

	private struct ChatPanel: HTML {
		var body: some HTML {
			GeoCitiesWindowsNetMeeting.toolPanel("chat", title: "Chat - 2 people") {
				div(.part(Parts.chatLog), .role("log"), .tabindex(0)) {}
					.accessibilityLabel("Chat")
					.style(Styles.chatLog)

				form(.part(Parts.chatForm)) {
					label(.for("geocities-netmeeting-chat-input")) {
						"Message"
					}
					.style(VisuallyHidden.Styles.root)

					input(.id("geocities-netmeeting-chat-input"), .part(Parts.chatInput), .type(.text), .autocomplete("off"), .maxlength(80))
						.style(GeoCitiesPage.Styles.field, GeoCitiesWindows.Styles.grow)

					button(.type(.submit)) {
						"Send"
					}
					.style(GeoCitiesPage.Styles.smallButton)
				}
				.style(GeoCitiesWindows.Styles.nowrapRow)

				p {
					"Send To: Everyone In Chat"
				}
				.style(GeoCitiesPage.Styles.caption)
			}
		}
	}

	private struct WhiteboardPanel: HTML {
		var body: some HTML {
			GeoCitiesWindowsNetMeeting.toolPanel("whiteboard", title: "Untitled - Whiteboard") {
				div(.role("group")) {
					for (index, color) in GeoCitiesWindowsNetMeeting.colors.enumerated() {
						button(.type(.button), .hook(Hooks.color, value: color.name), .ariaPressed(index == 0)) {}
							.accessibilityLabel(color.name.capitalized)
							.help(color.name.capitalized)
							.style(Styles.swatch)
					}

					button(.part(Parts.clearBoard), .type(.button)) {
						"Clear Page"
					}
					.style(GeoCitiesPage.Styles.smallButton)
				}
				.accessibilityLabel("Pen")
				.style(GeoCitiesWindows.Styles.wrapRow)

				canvas(.part(Parts.board), .width(320), .height(200), .tabindex(0), .role("application")) {}
					.accessibilityLabel("Whiteboard. Draw with the mouse or a finger, or move the pen with the arrow keys. Space lifts the pen and puts it down.")
					.style(Styles.board)
			}
		}
	}

	private struct SharePanel: HTML {
		var body: some HTML {
			GeoCitiesWindowsNetMeeting.toolPanel("share", title: "Sharing: Desktop") {
				canvas(.part(Parts.shareScreen), .width(320), .height(200), .tabindex(0), .role("application")) {}
					.accessibilityLabel("My shared desktop, as Mormor sees it. While Mormor has the control, Escape, Enter, or a click takes it back. Otherwise, Enter or a click on the Recycle Bin gets back what she threw away.")
					.style(Styles.shareScreen)

				p {
					"Mormor sees my desktop. With Collaborate, she can click too. Escape takes the control back."
				}
				.style(GeoCitiesPage.Styles.caption)
			}
		}
	}

	private struct TransferPanel: HTML {
		var body: some HTML {
			GeoCitiesWindowsNetMeeting.toolPanel("transfer", title: "File Transfer") {
				div {
					canvas(.part(Parts.photo), .width(80), .height(60), .role("img")) {}
						.accessibilityLabel("The photo, not received yet")
						.style(Styles.photo)

					div {
						p(.part(Parts.transferName)) {
							"No file"
						}
						.style(GeoCitiesWindows.Styles.paneTitle)

						span {
							span(.part(Parts.transferProgress)) {}
								.style(GeoCitiesWindows.Styles.progressFill)
						}
						.style(GeoCitiesWindows.Styles.progressTrack, Styles.transferTrack)

						p(.part(Parts.transferInfo)) {}
							.style(GeoCitiesPage.Styles.caption)

						button(.part(Parts.transferCancel), .type(.button), .disabled) {
							"Cancel"
						}
						.style(GeoCitiesPage.Styles.smallButton)
					}
					.style(GeoCitiesWindows.Styles.stack, GeoCitiesWindows.Styles.grow)
				}
				.style(GeoCitiesWindows.Styles.wrapRow)
			}
		}
	}

	private struct History: HTML {
		var body: some HTML {
			div(.hook(Hooks.panel, value: "history"), .hidden) {
				ul(.part(Parts.history)) {}
					.accessibilityLabel("Calls")
					.style(Styles.historyList)
			}
			.style(Styles.panel)
		}
	}

	/**
	A window of a tool of the call, like the Chat, with a small title bar, which the toolbar opens and closes.
	*/
	private static func toolPanel<Content: HTML>(_ value: String, title: String, @HTMLBuilder content: () -> Content) -> some HTML {
		section(.hook(Hooks.tool, value: value), .hidden) {
			p {
				title
			}
			.style(GeoCitiesPage.Styles.titleBar)

			div {
				content()
			}
			.style(GeoCitiesWindows.Styles.stack, Styles.toolBody)
		}
		.accessibilityLabel(title)
		.style(Styles.tool)
	}

	enum Parts: String, ElementPartSet {
		case call
		case hangUp
		case share
		case collaborate
		case chat
		case whiteboard
		case sendFile
		case sound
		case microphone
		case microphoneLevel
		case speaker
		case speakerLevel
		case delay
		case status
		case callInfo
		case server
		case refresh
		case directoryRows
		case notInCall
		case callArea
		case remoteVideo
		case remoteLabel
		case remotePause
		case localVideo
		case webcam
		case quality
		case subtitleMormor
		case subtitleYou
		case chatLog
		case chatForm
		case chatInput
		case clearBoard
		case board
		case shareScreen
		case photo
		case transferName
		case transferProgress
		case transferInfo
		case transferCancel
		case history
		case rowTemplate
	}

	/**
	The lists of the same kind of element, with a value for the script.
	*/
	enum Hooks: String, ScriptHookSet {
		/**
		A button of the bar on the left, by the view it shows.
		*/
		case view = "data-netmeeting-view"

		/**
		A view of the window, by its name.
		*/
		case panel = "data-netmeeting-panel"

		/**
		A button of SpeedDial, by who it calls.
		*/
		case dial = "data-netmeeting-dial"

		/**
		A button of what I can say in the call, by what it says.
		*/
		case say = "data-netmeeting-say"

		/**
		A window of a tool of the call, like the Chat, by its name.
		*/
		case tool = "data-netmeeting-tool"

		/**
		A color of the pen of the Whiteboard, by its name.
		*/
		case color = "data-netmeeting-color"
	}

	enum Styles: ElementStyleSet {
		case root
		case toolbar
		case audioBar
		case audioToggle
		case meter
		case meterFill
		case delay
		case main
		case nav
		case navButton
		case navIcon
		case content
		case panel
		case directoryBox
		case directoryTable
		case headerCell
		case directoryRow
		case cell
		case rowButton
		case videos
		case videoFigure
		case video
		case videoCaption
		case qualityRow
		case quality
		case subtitles
		case sayButton
		case tool
		case toolBody
		case chatLog
		case swatch
		case board
		case shareScreen
		case photo
		case transferTrack
		case historyList
		case statusLine

		private static let sunken = Color("#808080")

		var style: Style {
			switch self {
			case .root:
				GeoCitiesWindows.Styles.stack.style
			case .toolbar:
				// The gray toolbar of NetMeeting, with a line under it.
				Style()
					.padding(.bottom, .rootEm(0.25))
					.border(.bottom, Self.sunken, width: .pixels(1))
			case .audioBar:
				Style()
					.fontFamily(.system)
					.textStyle(.caption)
			case .audioToggle:
				// The whole label turns the microphone or the speaker on and off, and it is tall enough for a finger. On a touch screen, the check box is bigger too.
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.25))
					.frame(minHeight: .rootEm(1.5))
					.handCursor()
					.children("input") {
						$0
							.flexShrink(0)
							.margin(0)
							.media(.coarsePointer) {
								$0.frame(width: .rootEm(1.25), height: .rootEm(1.25))
							}
					}
			case .meter:
				// The level meter of the microphone or the speaker: green blocks on black, as long as the sound is loud.
				Style()
					.display(.inlineBlock)
					.frame(width: .rootEm(3.5), height: .rootEm(0.75))
					.background(.black)
					.border(Self.sunken, width: .pixels(1), style: .inset)
			case .meterFill:
				// `WindowsNetMeeting.js` sets how loud.
				Style()
					.display(.block)
					.frame(width: 0, height: .percent(100))
					.backgroundImage("repeating-linear-gradient(to right, #00ff00 0 4px, transparent 4px 6px)")
			case .delay:
				Style()
					.padding(vertical: 0, horizontal: .rootEm(0.375))
					.textStyle(.caption)
					.monospacedDigit()
			case .main:
				// The bar of the views is on top on a phone, and on the left on a wider screen, like NetMeeting.
				Style()
					.grid(columns: 1)
					.gap(.rootEm(0.375))
					.from(.smallTablet) {
						$0.gridColumns("5.5rem minmax(0, 1fr)")
					}
			case .nav:
				Style()
					.hstack(spacing: .rootEm(0.125))
					.padding(.rootEm(0.25))
					.background(Color("#404040"))
					.border(Self.sunken, width: .pixels(2), style: .inset)
					.from(.smallTablet) {
						$0.vstack(spacing: .rootEm(0.25))
					}
			case .navButton:
				// A big icon with its name under it, white on the dark bar. The view on the screen is pressed in.
				Style()
					.vstack(alignment: .center, spacing: .rootEm(0.125))
					.frame(minHeight: .rootEm(2.75))
					.below(.smallTablet) {
						$0.flex(1)
					}
					.padding(.rootEm(0.25))
					.background(.transparent)
					.border(.transparent, width: .pixels(2))
					.fontFamily(.system)
					.textStyle(.caption, weight: .bold)
					.lineHeight(1.1)
					.color(.white)
					.handCursor()
					.focusVisible {
						$0.focusRing(Color("#ffff00"), width: .pixels(2))
					}
					.when(.state, is: "on") {
						$0
							.background(Color("#606060"))
							.border(Color("#202020"), width: .pixels(2), style: .inset)
					}
			case .navIcon:
				Style()
					.font(.large)
					.lineHeight(1)
			case .content:
				Style().frame(minWidth: 0)
			case .panel:
				Style()
					.vstack(spacing: .rootEm(0.375))
					.frame(minHeight: .rootEm(14))
			case .directoryBox:
				// The list of the directory scrolls by itself, so a long row does not make the page scroll on a phone.
				Style()
					.frame(maxHeight: .rootEm(12))
					.overflow(.auto)
					.background(.white)
					.border(Self.sunken, width: .pixels(2), style: .inset)
			case .directoryTable:
				Style()
					.frame(width: .percent(100))
					.fontFamily(.system)
					.textStyle(.caption)
					.color(.black)
			case .headerCell:
				Style()
					.padding(vertical: .rootEm(0.125), horizontal: .rootEm(0.25))
					.background(GeoCitiesPage.windowGray)
					.border(Color("#dfdfdf"), width: .pixels(1), style: .outset)
					.textAlign(.leading)
					.textWrap(.nowrap)
			case .directoryRow:
				// A person of the directory. The person picked to call is blue, like a selection of Windows.
				Style().when(.state, is: "selected") {
					$0
						.background(Color("#000080"))
						.color(.white)
				}
			case .cell:
				Style()
					.padding(vertical: .rootEm(0.125), horizontal: .rootEm(0.25))
					.textWrap(.nowrap)
			case .rowButton:
				// The name, which picks the person, and a double click calls them.
				Style()
					.padding(0)
					.background(.transparent)
					.border(.transparent, width: 0)
					.fontFamily(.system)
					.textStyle(.caption, weight: .bold)
					.color(.currentColor)
					.underline()
					.handCursor()
					.frame(minHeight: .rootEm(1.5))
			case .videos:
				// Mormor’s video is bigger than mine, side by side, also on a phone, where mine is still wide enough for “My Video” and its button on one line. They stay small, like in NetMeeting, so what to say to her fits below them in the window.
				Style()
					.frame(maxWidth: .rootEm(20))
					.grid(columns: "minmax(0, 3fr) minmax(0, 2fr)")
					.alignItems(.start)
					.gap(.rootEm(0.5))
			case .videoFigure:
				Style()
					.vstack(spacing: .rootEm(0.25))
					.margin(0)
			case .video:
				// A video of 160 × 120 in big pixels, on black, like the video window of NetMeeting.
				Style()
					.display(.block)
					.frame(width: .percent(100), height: .auto)
					.aspectRatio(4.0 / 3.0)
					.background(.black)
					.border(Self.sunken, width: .pixels(2), style: .inset)
					.imageRendering(.pixelated)
			case .videoCaption:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.25))
					.fontFamily(.system)
					.textStyle(.caption, weight: .bold)
			case .qualityRow:
				Style()
					.fontFamily(.system)
					.textStyle(.caption)
			case .quality:
				// Tall enough for a finger on a phone.
				Style()
					.flex(1)
					.frame(minWidth: .rootEm(5), maxWidth: .rootEm(10), minHeight: .rootEm(1.5))
			case .subtitles:
				// The subtitles of the call, white on black like on TV: what Mormor says, when her sound arrives, and what I say.
				Style()
					.vstack(spacing: .rootEm(0.125))
					.frame(minHeight: .rootEm(3.5))
					.padding(vertical: .rootEm(0.25), horizontal: .rootEm(0.5))
					.background(.black)
					.border(Self.sunken, width: .pixels(2), style: .inset)
					.fontFamily(.system)
					.textStyle(.caption, weight: .bold)
					.color(.white)
					.children("p") {
						$0.margin(0)
					}
					.children("p:first-child") {
						$0.color(Color("#ffff66"))
					}
			case .sayButton:
				Style().frame(minHeight: .rootEm(2))
			case .tool:
				// A small window of NetMeeting inside the call, like the Chat or the Whiteboard.
				Style()
					.background(GeoCitiesPage.windowGray)
					.border(Color("#dfdfdf"), width: .pixels(2), style: .outset)
			case .toolBody:
				Style().padding(.rootEm(0.375))
			case .chatLog:
				// The text of the chat, with the name of who wrote it in bold.
				Style()
					.frame(height: .rootEm(8))
					.overflow(.auto)
					.padding(.rootEm(0.25))
					.background(.white)
					.border(Self.sunken, width: .pixels(2), style: .inset)
					.fontFamily(.system)
					.textStyle(.caption)
					.color(.black)
					.overflowWrap(.anywhere)
					.children("p") {
						$0.margin(0)
					}
			case .swatch:
				Self.swatchStyle
			case .board:
				// The page of the Whiteboard. A finger on it draws, so it does not scroll the page.
				Style()
					.display(.block)
					.frame(width: .percent(100), height: .auto)
					.aspectRatio(320.0 / 200.0)
					.background(.white)
					.border(Self.sunken, width: .pixels(2), style: .inset)
					.touchAction(.none)
					.cursor(.crosshair)
					.focusVisible {
						$0.focusRing(Color("#000080"), width: .pixels(2), offset: .pixels(1))
					}
			case .shareScreen:
				Style()
					.display(.block)
					.frame(width: .percent(100), height: .auto)
					.aspectRatio(320.0 / 200.0)
					.background(Color("#008080"))
					.border(Self.sunken, width: .pixels(2), style: .inset)
					.imageRendering(.pixelated)
					.touchAction(.manipulation)
					.focusVisible {
						$0.focusRing(Color("#000080"), width: .pixels(2), offset: .pixels(1))
					}
			case .photo:
				// The photo that arrives, in big pixels, black until its lines come in.
				Style()
					.display(.block)
					.frame(width: .rootEm(8), height: .auto)
					.aspectRatio(4.0 / 3.0)
					.flexShrink(0)
					.background(.black)
					.border(Self.sunken, width: .pixels(2), style: .inset)
					.imageRendering(.pixelated)
			case .transferTrack:
				Style().frame(width: .percent(100))
			case .historyList:
				Style()
					.frame(minHeight: .rootEm(12))
					.margin(0)
					.padding(vertical: .rootEm(0.25), horizontal: .rootEm(1.25))
					.background(.white)
					.border(Self.sunken, width: .pixels(2), style: .inset)
					.fontFamily(.system)
					.textStyle(.caption)
					.color(.black)
			case .statusLine:
				// The status takes the rest of the row next to the time of the call, and a line of its own on a phone, so a long message does not become a narrow column.
				Style()
					.flex(1)
					.frame(minWidth: .rootEm(12))
			}
		}

		/**
		A color of the pen, as a square of its color. The color in use has a black edge.
		*/
		private static var swatchStyle: Style {
			var style = Style()
				.frame(width: .rootEm(2), height: .rootEm(2))
				.padding(0)
				.border(Self.sunken, width: .pixels(2), style: .inset)
				.handCursor()
				.when(.state, is: "on") {
					$0.border(.black, width: .pixels(3))
				}

			for color in GeoCitiesWindowsNetMeeting.colors {
				style = style.when(Hooks.color, is: color.name) {
					$0.background(Color(color.hex))
				}
			}

			return style
		}
	}
}
