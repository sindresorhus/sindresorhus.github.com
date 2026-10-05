import Elementary
import Foundation
import SiteKit

/**
Rodent’s Revenge, like the one of the Microsoft Entertainment Pack (Christopher Lee Fraley, 1991), on the desktop of my computer (``GeoCitiesPage/desktop``). The field is 23 × 23 squares with a wall around it. I am the mouse, and I push rows of movable blocks to box in the cats, which chase me along the shortest way. A cat that cannot move sits down, and when all the cats of a wave sit, they turn into cheese, which I eat for 100 points (or 500, when it turns out to be brunost). Then the next wave comes, with more cats. Ten levels have their own layouts, like Mormor’s pantry, Rocky’s room with my pet rock as a block that never moves, the Norwegian flag, and Bryggen, with immovable blocks, sink holes that hold the mouse for a while, mouse traps that snap, and balls of yarn that roll around and squash the mouse flat. A clock gives a bonus for the time that is left, and rings in an extra cat when it runs out. The cat says “Meow!” in a speech balloon when it catches me. The speed goes from Snail to Cheetah, like the Options of the original. The keyboard, the number pad, a tap on the field, and the arrow pad move the mouse. With reduced motion, the cats move only when the mouse moves. It is the content of its window of the desktop, and its script, `WindowsRodent.js`, runs it on the canvas and keeps the best score and the speed in the browser.
*/
struct GeoCitiesWindowsRodent: ScriptedElement {
	static let script = ElementScript()

	/**
	The speeds of the cats, like the Options menu of the original.
	*/
	private static let speeds = [("Snail", "🐌"), ("Slow", "🐢"), ("Medium", "🐈"), ("Fast", "🐇"), ("Cheetah", "🐆")]

	/**
	The arrow pad, in rows, as the step of each button and its arrow and name.
	*/
	private static let pad: [(step: String, arrow: String, name: String)] = [
		("-1 -1", "↖", "Up and left"),
		("0 -1", "↑", "Up"),
		("1 -1", "↗", "Up and right"),
		("-1 0", "←", "Left"),
		("0 0", "🐁", "Wait"),
		("1 0", "→", "Right"),
		("-1 1", "↙", "Down and left"),
		("0 1", "↓", "Down"),
		("1 1", "↘", "Down and right"),
	]

	var content: some HTML {
		GeoCitiesPage.Deferred(toolbar)
		GeoCitiesPage.Deferred(play)

		p {
			"Rodent’s Revenge needs JavaScript. The cats are napping until then."
		}
		.style(GeoCitiesPage.Styles.scriptingDisabledOnly)
	}

	/**
	The buttons, and the pickers of the level and the speed, like the menus of the original.
	*/
	private var toolbar: some HTML {
		div {
			button(.part(Parts.newGame), .type(.button)) {
				"New Game"
			}
			.help("Starts over on the level of the picker (F2)")
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

			GeoCitiesPage.Deferred(pickers)
		}
		.style(GeoCitiesWindows.Styles.wrapRow, GeoCitiesPage.Styles.scriptingOnly)
	}

	/**
	The pickers of the level and of the speed of the cats. Their labels are for screen readers, as the options say what they are.
	*/
	@HTMLBuilder
	private var pickers: some HTML {
		label(.for("geocities-rodent-level")) {
			"Level"
		}
		.style(VisuallyHidden.Styles.root)

		select(.id("geocities-rodent-level"), .part(Parts.level)) {
			// The script has the names and the layouts of the ten levels.
			for level in 1...10 {
				option(.value("\(level)")) {
					"Level \(level)"
				}
			}
		}
		.help("Level")
		.style(GeoCitiesWindows.Styles.toolbarSelect)

		label(.for("geocities-rodent-speed")) {
			"Speed of the cats"
		}
		.style(VisuallyHidden.Styles.root)

		select(.id("geocities-rodent-speed"), .part(Parts.speed)) {
			for (speed, icon) in Self.speeds {
				option(.value(speed.lowercased())) {
					"\(icon) \(speed)"
				}
				.attributes(.selected, when: speed == "Medium")
			}
		}
		.help("Speed of the cats")
		.style(GeoCitiesWindows.Styles.toolbarSelect)
	}

	/**
	The field, with the arrow pad, the status, and the scores beside it. The status comes right after the arrow pad, so a phone shows it beside the pad, where the visitor sees what happens while they play.
	*/
	private var play: some HTML {
		div {
			canvas(.part(Parts.screen), .width(736), .height(800), .tabindex(0), .role("application")) {}
				.accessibilityLabel("Rodent’s Revenge. The arrow keys move the mouse. The number pad, or Q, E, Z, and C, move it on the diagonals. P pauses, and F2 starts a new game. A tap on the field moves the mouse toward it.")
				.style(Styles.screen)

			div {
				GeoCitiesPage.Deferred(pad)

				p(.part(Parts.status), .role("status")) {
					"Push the blocks to trap the cats. Press an arrow key or tap the field to start."
				}
				.style(GeoCitiesPage.Styles.statusBar, Styles.status)

				p(.part(Parts.stats)) {
					"Level 1 ★ Wave 1 of 2 ★ Score 0 ★ Best 0"
				}
				.style(GeoCitiesPage.Styles.lcd, Styles.stats)
			}
			.style(Styles.side)
		}
		.style(Styles.play, GeoCitiesPage.Styles.scriptingOnly)
	}

	/**
	The arrow pad, for touch, with a button for each of the eight directions, and the mouse in the middle, which waits a turn.
	*/
	private var pad: some HTML {
		div(.role("group")) {
			for button in Self.pad {
				Elementary.button(.type(.button), .hook(Hooks.move, value: button.step)) {
					button.arrow
				}
				.accessibilityLabel(button.name)
				.style(GeoCitiesPage.Styles.retroButton, Styles.padButton)
			}
		}
		.accessibilityLabel("Move the mouse")
		.style(Styles.pad)
	}

	enum Parts: String, ElementPartSet {
		case screen
		case newGame
		case pause
		case sound
		case level
		case speed
		case stats
		case status
	}

	enum Hooks: String, ScriptHookSet {
		/**
		A button of the arrow pad, by the step it moves the mouse across and down, like `"-1 1"`. `"0 0"` waits a turn.
		*/
		case move = "data-rodent-move"
	}

	enum Styles: ElementStyleSet {
		case root
		case play
		case screen
		case side
		case pad
		case padButton
		case stats
		case status

		var style: Style {
			switch self {
			case .root:
				GeoCitiesWindows.Styles.stack.style
			case .play:
				// The field, with the arrow pad and the scores beside it, or below it on a phone.
				Style()
					.hstack(alignment: .start, spacing: .rootEm(0.5))
					.flexWrap()
			case .screen:
				// The field keeps its shape, and a finger on it moves the mouse instead of scrolling the page.
				Style()
					.display(.block)
					.flex(3)
					.frame(width: .percent(100), height: .auto, minWidth: .rootEm(15), maxWidth: .rootEm(21))
					.aspectRatio(736.0 / 800.0)
					.background(Color("#c8c88a"))
					.border(Color("#808080"), width: .pixels(3), style: .inset)
					.touchAction(.none)
					.handCursor()
			case .side:
				// The status wraps under the arrow pad beside the field, and sits beside the pad under the field on a phone. The pad stays at the top of its row, so it does not move under a thumb when the status gets longer. Wide enough beside the field that the status and the scores wrap to fewer lines, so the window shows all of them when it opens.
				Style()
					.hstack(alignment: .start, justification: .center, spacing: .rootEm(0.5))
					.flexWrap()
					.flex(1)
					.frame(minWidth: .rootEm(10.5))
			case .pad:
				Style()
					.flexShrink(0)
					.grid(columns: 3)
					.gap(.rootEm(0.25))
			case .padButton:
				// Big enough for a thumb, which holds it down to keep running, so it does not select the arrow.
				Style()
					.frame(width: .rootEm(2.75), height: .rootEm(2.75))
					.padding(0)
					.lineHeight(1)
					.touchAction(.manipulation)
					.textSelection(.disabled)
			case .stats:
				Style()
					.frame(width: .percent(100))
					.textStyle(.caption)
			case .status:
				// Too wide to share a row with the arrow pad beside the field, but not under it.
				Style()
					.flex(1)
					.frame(minWidth: .rootEm(7))
			}
		}
	}
}
