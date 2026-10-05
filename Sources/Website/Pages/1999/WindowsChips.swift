import Elementary
import Foundation
import SiteKit

/**
Chip’s Challenge, like the one of the Microsoft Entertainment Pack 4 (Chuck Sommerville, 1989), on the desktop of my computer (``GeoCitiesPage/desktop``): Chip collects the computer chips of each level, goes through the chip socket, and finds the exit, past keys and doors, water and fire with flippers and fire boots, ice, force floors, blocks to push into the water, bouncing balls, teeth that chase him, and a thief who takes his boots. Each level shows its four-letter password, which jumps back to it. It is the content of its window of the desktop, and its script, `WindowsChips.js`, runs it on the canvas, with a 9 × 9 view of the level and the panel of the level, the time, the chips left, and the keys and boots, and keeps the last level in the browser.
*/
struct GeoCitiesWindowsChips: ScriptedElement {
	static let script = ElementScript()

	/**
	The buttons of the direction pad in a grid of 3 × 3, by the direction that the script knows them by, with what a screen reader says. The corners and the middle are empty.
	*/
	private static let directions: [(id: String, name: String, symbol: String)?] = [
		nil, ("up", "Up", "▲"), nil,
		("left", "Left", "◀"), nil, ("right", "Right", "▶"),
		nil, ("down", "Down", "▼"), nil,
	]

	var content: some HTML {
		div {
			button(.part(Parts.restart), .type(.button)) {
				"Restart Level"
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

		// The board and the panel are one canvas, like the window of Chip’s Challenge, so they fit on a phone above the direction pad.
		div {
			canvas(.part(Parts.screen), .width(416), .height(288), .tabindex(0), .role("application")) {}
				.accessibilityLabel("Chip’s Challenge. The arrow keys move Chip one tile, and P pauses. A swipe or a tap on the board moves him too.")
				.style(Styles.screen)

			// The empty corners of the grid make the shape of a plus.
			div(.role("group")) {
				for direction in Self.directions {
					if let direction {
						button(.type(.button), .hook(Hooks.move, value: direction.id)) {
							direction.symbol
						}
						.accessibilityLabel(direction.name)
						.style(Styles.padButton)
					} else {
						span {}
							.accessibilityHidden()
					}
				}
			}
			.accessibilityLabel("Move Chip")
			.style(Styles.pad)
		}
		.style(Styles.board, GeoCitiesPage.Styles.scriptingOnly)

		p(.part(Parts.counters)) {}
			.style(VisuallyHidden.Styles.root)

		p(.part(Parts.status), .role("status")) {
			"Collect all the chips, go through the chip socket, and find the exit!"
		}
		.style(GeoCitiesPage.Styles.statusBar, Styles.status, GeoCitiesPage.Styles.scriptingOnly)

		form(.part(Parts.passwordForm)) {
			label(.for("geocities-chips-password")) {
				"Password:"
			}

			input(.id("geocities-chips-password"), .part(Parts.password), .type(.text), .autocomplete("off"), .maxlength(4), .custom(name: "autocapitalize", value: "characters"), .custom(name: "spellcheck", value: "false"))
				.style(Styles.password)

			button(.type(.submit)) {
				"Go to Level"
			}
			.style(GeoCitiesPage.Styles.smallButton)
		}
		.style(GeoCitiesWindows.Styles.wrapRow, GeoCitiesPage.Styles.scriptingOnly)

		p {
			"Chip’s Challenge needs JavaScript. Chip is waiting at the entrance."
		}
		.style(GeoCitiesPage.Styles.scriptingDisabledOnly)
	}

	enum Parts: String, ElementPartSet {
		case screen
		case restart
		case pause
		case sound
		case passwordForm
		case password
		case counters
		case status
	}

	enum Hooks: String, ScriptHookSet {
		/**
		A button of the direction pad, with its direction, like `up`.
		*/
		case move = "data-chips-move"
	}

	enum Styles: ElementStyleSet {
		case root
		case board
		case screen
		case pad
		case padButton
		case password
		case status

		var style: Style {
			switch self {
			case .root:
				GeoCitiesWindows.Styles.stack.style
			case .board:
				// The direction pad goes next to the board on a wide window, and under it on a phone.
				Style()
					.hstack(alignment: .center, justification: .center, spacing: .rootEm(0.5))
					.flexWrap()
			case .screen:
				Style()
					.display(.block)
					.flex(1)
					.frame(width: .rootEm(20), height: .auto, minWidth: .rootEm(15), maxWidth: .rootEm(26))
					.aspectRatio(416.0 / 288.0)
					.background(.black)
					.border(Color("#808080"), width: .pixels(3), style: .inset)
					.imageRendering(.pixelated)
					.touchAction(.none)
			case .pad:
				// Big buttons for a thumb, in the shape of a plus.
				Style()
					.grid(columns: 3)
					.gap(.pixels(2))
			case .padButton:
				Style()
					.frame(width: .rootEm(2.75), height: .rootEm(2.75))
					.background(GeoCitiesPage.windowGray)
					.border(Color("#dfdfdf"), width: .pixels(3), style: .outset)
					.fontFamily(.system)
					.textStyle(.body, weight: .bold)
					.color(.black)
					.handCursor()
					.touchAction(.manipulation)
					.active {
						$0.border(Color("#dfdfdf"), width: .pixels(3), style: .inset)
					}
			case .password:
				// A short white field with a sunken edge, for four letters.
				Style()
					.frame(width: .rootEm(4.5))
					.padding(vertical: .rootEm(0.125), horizontal: .rootEm(0.375))
					.background(.white)
					.border(Color("#808080"), width: .pixels(2), style: .inset)
					.fontFamily(GeoCitiesPage.courier)
					.textStyle(.body, weight: .bold)
					.color(.black)
					.textCase(.uppercase)
			case .status:
				// Hints are longer than the other messages.
				Style().frame(minHeight: .lineHeight(2))
			}
		}
	}
}
