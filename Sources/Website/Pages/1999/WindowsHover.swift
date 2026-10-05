import Elementary
import Foundation
import SiteKit

/**
Hover!, the game of the “Fun Stuff” folder of the Windows 95 CD, on the desktop of my computer (``GeoCitiesPage/desktop``): a hovercraft that slides like a bumper car through a 3D arena, to collect the blue flags before the red hovercraft of the computer collect the red ones. Springs on the floor jump over walls, speed pads push, and power-ups drop a wall behind the hovercraft or make it invisible to the robot that chases it. Three arenas: the castle, the ice rink, and the sewer. It is the content of its window of the desktop, and its script, `WindowsHover.js`, draws the arena on the canvas with a raycaster, like the 3D Maze screen saver, and keeps the best times in the browser.
*/
struct GeoCitiesWindowsHover: ScriptedElement {
	static let script = ElementScript()

	/**
	The buttons for touch, by the control the script knows them by, with their names and symbols.
	*/
	private static let controls: [(id: String, name: String, symbol: String)] = [
		("left", "Turn left", "↺"),
		("forward", "Forward", "▲"),
		("right", "Turn right", "↻"),
		("back", "Back", "▼"),
		("use", "Use power-up", "★"),
	]

	/**
	The arenas, by the ID the script knows them by.
	*/
	private static let levels: [(id: String, name: String)] = [
		("castle", "Castle"),
		("ice", "Ice Rink"),
		("sewer", "Sewer"),
	]

	var content: some HTML {
		canvas(.part(Parts.screen), .width(320), .height(200), .tabindex(0), .role("application")) {}
			.accessibilityLabel("Hover! The arrow keys or W, A, S, and D steer the hovercraft, Space uses a power-up, and Enter starts.")
			.style(Styles.screen, GeoCitiesPage.Styles.scriptingOnly)

		div(.role("group")) {
			for control in Self.controls {
				button(.type(.button), .hook(Hooks.control, value: control.id)) {
					control.symbol
				}
				.accessibilityLabel(control.name)
				.help(control.name)
				.style(Styles.control)
			}
		}
		.accessibilityLabel("Controls")
		.style(Styles.controls, GeoCitiesPage.Styles.scriptingOnly)

		div {
			button(.part(Parts.start), .type(.button)) {
				"Start"
			}
			.style(GeoCitiesPage.Styles.retroButton)

			label {
				"Arena: "

				select(.part(Parts.level)) {
					for level in Self.levels {
						option(.value(level.id)) {
							level.name
						}
					}
				}
			}

			button(.part(Parts.sound), .type(.button), .ariaPressed(false)) {
				"🔊 Sound"
			}
			.help("Plays sounds")
			.style(GeoCitiesPage.Styles.smallButton)
		}
		.style(GeoCitiesWindows.Styles.wrapRow, GeoCitiesPage.Styles.scriptingOnly)

		p(.part(Parts.status), .role("status")) {
			"Collect your 3 blue flags before the red hovercraft get their red ones. Bump the red one to make it spin!"
		}
		.style(GeoCitiesPage.Styles.statusBar, GeoCitiesPage.Styles.scriptingOnly)

		p(.part(Parts.best)) {}
			.style(GeoCitiesPage.Styles.caption, GeoCitiesPage.Styles.scriptingOnly)

		p {
			"Hover! needs JavaScript. The hovercraft is out of gas."
		}
		.style(GeoCitiesPage.Styles.scriptingDisabledOnly)
	}

	enum Parts: String, ElementPartSet {
		case screen
		case start
		case level
		case sound
		case status
		case best
	}

	/**
	The buttons for touch, which carry their control.
	*/
	enum Hooks: String, ScriptHookSet {
		/**
		A button for touch, by the control, like `forward`.
		*/
		case control = "data-hover-control"
	}

	enum Styles: ElementStyleSet {
		case root
		case screen
		case controls
		case control

		var style: Style {
			switch self {
			case .root:
				GeoCitiesWindows.Styles.stack.style
			case .screen:
				// The arena in big pixels, as wide as the window.
				Style()
					.display(.block)
					.frame(width: .percent(100), height: .auto)
					.aspectRatio(16.0 / 10.0)
					.background(.black)
					.border(Color("#808080"), width: .pixels(3), style: .inset)
					.imageRendering(.pixelated)
					.touchAction(.manipulation)
			case .controls:
				// Five big buttons in a row, which a thumb holds down to steer.
				Style()
					.grid(columns: 5)
					.gap(.rootEm(0.25))
			case .control:
				// Pressed in while it is held down, like with a finger.
				GeoCitiesPage.Styles.retroButton.style
					.padding(vertical: .rootEm(0.375), horizontal: 0)
					.font(.large)
					.touchAction(.none)
					.textSelection(.disabled)
					.when(.state, is: "held") {
						$0.border(Color("#dfdfdf"), width: .pixels(3), style: .inset)
					}
			}
		}
	}
}
