import Elementary
import Foundation
import SiteKit

/**
3D Pinball for Windows, Space Cadet, on the desktop of my computer (``GeoCitiesPage/desktop``), like the table that came with Microsoft Plus! for Windows 95 (Cinematronics, 1995): a table in space with a plunger, two flippers, three attack bumpers, slingshots, the re-entry lanes, drop targets, a launch ramp, and a hyperspace hole, with the panel of Space Cadet beside it, with the score, the ball, the rank from Cadet to Fleet Admiral, and the mission. It is the content of its window of the desktop, and its script, `WindowsPinball.js`, runs the table on the canvas and keeps the high score in the browser.
*/
struct GeoCitiesWindowsPinball: ScriptedElement {
	static let script = ElementScript()

	/**
	The buttons under the table for a finger, by the ID that the script knows them by.
	*/
	private static let controls: [(id: String, title: String)] = [
		("left", "◀ Flip"),
		("launch", "Launch"),
		("right", "Flip ▶"),
	]

	var content: some HTML {
		div {
			div {
				canvas(.part(Parts.table), .width(400), .height(640), .tabindex(0), .role("application")) {}
					.accessibilityLabel("The pinball table. Z or the left arrow flips the left flipper, slash or the right arrow flips the right one. Hold Space or the down arrow to pull the plunger, and let go to launch. X, period, or the up arrow nudges the table. F2 starts a new game, and P pauses.")
					.style(Styles.table)

				div {
					for control in Self.controls {
						button(.type(.button), .hook(Hooks.control, value: control.id)) {
							control.title
						}
						.style(Styles.control)
					}
				}
				.style(Styles.controls)
			}
			.style(Styles.tableColumn, GeoCitiesPage.Styles.scriptingOnly)

			div {
				p {
					"3D Pinball"
					br()
					span {
						"Space Cadet"
					}
					.style(Styles.logoSubtitle)
				}
				.style(Styles.logo)

				// The word only for screen readers, as the score speaks for itself on the screen.
				p {
					span {
						"Score: "
					}
					.style(VisuallyHidden.Styles.root)

					span(.part(Parts.score)) {
						"0"
					}
				}
				.style(Styles.score)

				div {
					p(.part(Parts.ball)) {
						"Ball 1"
					}

					p {
						"Player 1"
					}
				}
				.style(Styles.infoRow)

				p(.part(Parts.rank)) {
					"Rank: Cadet"
				}
				.style(Styles.info)

				p(.part(Parts.mission)) {
					"Press F2 or New Game to start."
				}
				.style(Styles.mission)

				p(.part(Parts.high)) {
					"High score: 0"
				}
				.style(Styles.info)

				div {
					button(.part(Parts.newGame), .type(.button)) {
						"New Game (F2)"
					}
					.style(GeoCitiesPage.Styles.smallButton)

					button(.part(Parts.sound), .type(.button), .ariaPressed(false)) {
						"🔊 Sound"
					}
					.help("Plays the sounds of the table")
					.style(GeoCitiesPage.Styles.smallButton)
				}
				.style(Styles.buttons)

				p {
					"Z and / flip. Hold Space to launch. X, period, or ↑ nudge, but not too much."
				}
				.style(Styles.help)
			}
			.style(Styles.panel, GeoCitiesPage.Styles.scriptingOnly)
		}
		.style(Styles.layout)

		p(.part(Parts.status), .role("status")) {}
			.style(GeoCitiesPage.Styles.statusBar, GeoCitiesPage.Styles.scriptingOnly)

		p {
			"3D Pinball needs JavaScript. Without it, the ball is stuck in the plunger."
		}
		.style(GeoCitiesPage.Styles.caption, GeoCitiesPage.Styles.scriptingDisabledOnly)
	}

	enum Parts: String, ElementPartSet {
		case table
		case score
		case ball
		case rank
		case mission
		case high
		case newGame
		case sound
		case status
	}

	enum Hooks: String, ScriptHookSet {
		/**
		A button under the table for a finger, with its ID: `left`, `launch`, or `right`.
		*/
		case control = "data-pinball-control"
	}

	enum Styles: ElementStyleSet {
		case root
		case layout
		case tableColumn
		case table
		case controls
		case control
		case panel
		case logo
		case logoSubtitle
		case score
		case infoRow
		case info
		case mission
		case buttons
		case help

		/**
		The dark blue of the panel of Space Cadet.
		*/
		private static let panelBlue = Color("#0a0a3a")

		var style: Style {
			switch self {
			case .root:
				// Like the body of its window, which puts the same space between the table, the status, and the text for a browser without JavaScript.
				Style()
					.display(.block)
					.flowSpacing(.rootEm(0.75))
			case .layout:
				// The panel is under the table on a phone, and beside it, like in Space Cadet, where the window is wide enough.
				Style()
					.vstack(alignment: .center, spacing: .rootEm(0.5))
					.from(.smallTablet) {
						$0
							.flexDirection(.row)
							.alignItems(.start)
					}
			case .tableColumn:
				// As large as the window of the desktop allows, so the ball is easy to follow.
				Style()
					.vstack(alignment: .center, spacing: .rootEm(0.375))
					.frame(width: .percent(100), maxWidth: .rootEm(15))
			case .table:
				// The table keeps its shape, and a finger on it flips instead of scrolling the page.
				Style()
					.display(.block)
					.frame(width: .percent(100), height: .auto)
					.aspectRatio(400.0 / 640.0)
					.background(Color("#05051a"))
					.border(Color("#808080"), width: .pixels(3), style: .inset)
					.touchAction(.none)
					.textSelection(.disabled)
			case .controls:
				Style()
					.grid(columns: 3)
					.gap(.rootEm(0.25))
					.frame(width: .percent(100))
			case .control:
				// Big buttons for thumbs, pressed in while a finger holds them.
				Style()
					.padding(vertical: .rootEm(0.5), horizontal: .rootEm(0.25))
					.background(GeoCitiesPage.windowGray)
					.border(Color("#dfdfdf"), width: .pixels(3), style: .outset)
					.fontFamily(.system)
					.textStyle(.caption, weight: .bold)
					.color(.black)
					.touchAction(.none)
					.textSelection(.disabled)
					.handCursor()
					.active {
						$0.border(Color("#dfdfdf"), width: .pixels(3), style: .inset)
					}
					.when(.state, is: "down") {
						$0
							.background(Color("#a0a0a0"))
							.border(Color("#dfdfdf"), width: .pixels(3), style: .inset)
					}
			case .panel:
				// The panel of Space Cadet: dark blue, with yellow and green letters.
				Style()
					.vstack(spacing: .rootEm(0.375))
					.flex(1)
					.frame(width: .percent(100), minWidth: 0)
					.padding(.rootEm(0.5))
					.background(Self.panelBlue)
					.border(Color("#808080"), width: .pixels(3), style: .inset)
					.fontFamily(GeoCitiesPage.courier)
					.textStyle(.caption, weight: .bold)
					.color(Color("#ffd23f"))
			case .logo:
				Style()
					.fontFamily(GeoCitiesPage.impact)
					.font(.large)
					.textAlign(.center)
					.lineHeight(1.1)
					.color(Color("#ff5a3c"))
					.textShadow(Shadow(x: .pixels(1), y: .pixels(1), color: Color("#ffd23f")))
			case .logoSubtitle:
				Style()
					.fontFamily(GeoCitiesPage.courier)
					.textStyle(.caption, weight: .bold)
					.color(Color("#7fd8ff"))
					.textShadow(Shadow(x: 0, y: 0, color: .transparent))
			case .score:
				// Big digits on a black screen.
				Style()
					.padding(vertical: .rootEm(0.25), horizontal: .rootEm(0.5))
					.background(.black)
					.border(Color("#3a3a8a"), width: .pixels(2), style: .inset)
					.font(.large, weight: .heavy)
					.textAlign(.trailing)
					.color(Color("#33ff66"))
			case .infoRow:
				Style().hstack(justification: .spaceBetween, spacing: .rootEm(0.5))
			case .info:
				Style().overflowWrap(.anywhere)
			case .mission:
				// Four lines high, so the panel does not jump when the mission changes.
				Style()
					.frame(minHeight: .lineHeight(4))
					.padding(.rootEm(0.25))
					.background(.black)
					.border(Color("#3a3a8a"), width: .pixels(2), style: .inset)
					.color(Color("#7fd8ff"))
					.overflowWrap(.anywhere)
			case .buttons:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.375))
					.flexWrap()
			case .help:
				Style()
					.fontFamily(.system)
					.textStyle(.caption)
					.color(Color("#c0c0ff"))
			}
		}
	}
}
