import Elementary
import Foundation
import SiteKit

/**
JezzBall, like the one of the Microsoft Entertainment Pack (Dima Pavlovsky, 1992), on the desktop of my computer (``GeoCitiesPage/desktop``): atoms bounce in a room, and the visitor builds walls to box them in. A click starts a wall that grows both ways from the spot, across or up and down. An atom that hits a wall while it grows breaks that half and takes a life. A finished wall closes off the parts without atoms, and 75% of the room cleared wins the level. Level n has n + 1 atoms and n + 1 lives, and a clock. It is the content of its window of the desktop, and its script, `WindowsJezzBall.js`, runs it on the canvas and keeps the best score in the browser.
*/
struct GeoCitiesWindowsJezzBall: ScriptedElement {
	static let script = ElementScript()
	let config = Config()

	var content: some HTML {
		div {
			button(.part(Parts.newGame), .type(.button)) {
				"New Game"
			}
			.style(GeoCitiesPage.Styles.smallButton)

			button(.part(Parts.pause), .type(.button), .ariaPressed(false)) {
				"Pause"
			}
			.style(GeoCitiesPage.Styles.smallButton)

			button(.part(Parts.sound), .type(.button), .ariaPressed(false)) {
				"🔈 Sound"
			}
			.help("Plays sound")
			.style(GeoCitiesPage.Styles.smallButton)
		}
		.style(GeoCitiesWindows.Styles.wrapRow, GeoCitiesPage.Styles.scriptingOnly)

		canvas(.part(Parts.screen), .width(480), .height(300), .tabindex(0), .role("application")) {}
			.accessibilityLabel("JezzBall. The arrow keys move the crosshair, Space or Enter builds a wall, R turns the wall, and P pauses.")
			.style(Styles.screen, GeoCitiesPage.Styles.scriptingOnly)

		div {
			button(.part(Parts.turn), .type(.button)) {
				"↔ Across"
			}
			.accessibilityLabel("Wall direction: across. Click to turn it.")
			.style(GeoCitiesPage.Styles.retroButton, Styles.turn)

			p(.part(Parts.stats)) {
				"Level 1 ★ Lives 2 ★ Cleared 0% ★ Time 65 ★ Score 0 ★ Best 0"
			}
			.style(GeoCitiesPage.Styles.lcd, Styles.stats)
		}
		.style(GeoCitiesWindows.Styles.wrapRow, GeoCitiesPage.Styles.scriptingOnly)

		p(.part(Parts.status), .role("status")) {
			"Click in the room to build a wall. Box in the atoms, and clear \(config.goal)% of the room!"
		}
		.style(GeoCitiesPage.Styles.statusBar, GeoCitiesPage.Styles.scriptingOnly)

		p {
			"JezzBall needs JavaScript. The atoms are bouncing somewhere else."
		}
		.style(GeoCitiesPage.Styles.scriptingDisabledOnly)
	}

	struct Config: Encodable {
		/**
		The part of the room, in percent, that wins a level.
		*/
		var goal = 75
	}

	enum Parts: String, ElementPartSet {
		case screen
		case newGame
		case pause
		case sound
		case turn
		case stats
		case status
	}

	enum Styles: ElementStyleSet {
		case root
		case screen
		case turn
		case stats

		var style: Style {
			switch self {
			case .root:
				GeoCitiesWindows.Styles.stack.style
			case .screen:
				// The room, in big pixels. A tap builds a wall, so a finger on it does not zoom the page.
				Style()
					.display(.block)
					.frame(width: .percent(100), height: .auto)
					.aspectRatio(480.0 / 300.0)
					.background(.black)
					.border(Color("#808080"), width: .pixels(3), style: .inset)
					.imageRendering(.pixelated)
					.touchAction(.manipulation)
					.cursor(.crosshair)
			case .turn:
				// Big enough for a thumb, as touch has no right mouse button to turn the wall.
				Style().frame(minWidth: .rootEm(8), minHeight: .rootEm(2.75))
			case .stats:
				Style()
					.flex(1)
					.textStyle(.caption)
			}
		}
	}
}
