import Elementary
import Foundation
import SiteKit

/**
Spider Solitaire, the game of Microsoft Plus! 98, on the desktop of my computer (``GeoCitiesPage/desktop``), with the real rules: two decks of 104 cards in ten columns, 54 of them dealt with only the top card of each column face up, and the other 50 in the stock, which deals one card on each column, five times, but not while a column is empty. Any card goes on a card one higher, but only a run of one suit moves together, and a run of one suit from the king to the ace flies off to the completed suits. Eight of them win. The difficulty is one suit, two suits, or four suits, picked in the Game menu, and the score starts at 500, goes down by one for each move and each undo, and up by 100 for each completed suit. Cards drag with the mouse or a finger, a click moves cards to the best place, and the keyboard picks a column and a card and moves them. Hint shows a possible move, Undo takes one back, and the statistics count the wins, the losses, the streaks, and the high score of each difficulty in the browser, with the game in progress, which is still there the next time. A win sets off fireworks over the felt, unless the visitor prefers reduced motion. My grandmother sits next to the table, watches, and gives bad advice when she is asked, and sometimes when she is not. It is the content of its window of the desktop, and its script, `WindowsSpider.js`, runs it.
*/
struct GeoCitiesWindowsSpider: ScriptedElement {
	static let script = ElementScript()

	/**
	The commands of the Game menu, with the key that also does them, like in Spider Solitaire.
	*/
	private static let gameCommands: [(command: String, title: String, key: String)?] = [
		("new", "New Game", "F2"),
		("restart", "Restart This Game", ""),
		nil,
		("undo", "Undo", "Ctrl+Z"),
		("deal", "Deal Next Row", "D"),
		("hint", "Show an Available Move", "M"),
		nil,
		("difficulty", "Difficulty…", ""),
		("statistics", "Statistics…", ""),
		nil,
		("exit", "Exit", ""),
	]

	private static let helpCommands: [(command: String, title: String, key: String)?] = [
		("rules", "How to Play", "F1"),
		nil,
		("about", "About Spider Solitaire", ""),
	]

	var content: some HTML {
		div(.role("group")) {
			menu("Game", button: .gameMenuButton, list: .gameMenu, id: "geocities-spider-game-menu", commands: Self.gameCommands)
			menu("Help", button: .helpMenuButton, list: .helpMenu, id: "geocities-spider-help-menu", commands: Self.helpCommands)
		}
		.accessibilityLabel("Menu bar")
		.style(Styles.menuBar, GeoCitiesPage.Styles.scriptingOnly)

		div(.part(Parts.table)) {
			div(.part(Parts.columns), .role("group")) {
				for index in 0..<10 {
					button(.type(.button), .hook(Hooks.column, value: "\(index)"), .tabindex(index == 0 ? 0 : -1)) {}
						.accessibilityLabel("Column \(index + 1)")
						.style(Styles.column)
				}
			}
			.accessibilityLabel("Columns. Left and Right pick a column, Up and Down pick a card, Enter moves the cards to the best place, Space picks them up and puts them down on another column, and Escape puts them back.")
			.style(Styles.columns)

			div {
				p(.part(Parts.foundation), .role("img")) {}
					.accessibilityLabel("No completed suits")
					.style(Styles.foundation)

				div {
					p(.part(Parts.balloon), .hidden) {}
						.style(Styles.balloon)

					p {
						"👵"
					}
					.accessibilityHidden()
					.style(Styles.mormorFace)
				}
				.style(Styles.mormor)

				button(.part(Parts.score), .type(.button)) {
					"Score: 500\nMoves: 0"
				}
				.help("Show an available move")
				.style(Styles.scoreBox)

				button(.part(Parts.stock), .type(.button)) {}
					.accessibilityLabel("Deal a new row")
					.help("Deal a new row")
					.style(Styles.stock)
			}
			.style(Styles.bottomRow)

			canvas(.part(Parts.fireworks), .hidden) {}
				.accessibilityHidden()
				.style(Styles.fireworks)
		}
		.style(Styles.table, GeoCitiesPage.Styles.scriptingOnly)

		template(.part(Parts.cardTemplate)) {
			span {
				span {}
					.style(Styles.corner)

				span {}
					.style(Styles.pip)
			}
			.accessibilityHidden()
			.style(Styles.card)
		}

		div {
			button(.part(Parts.undo), .type(.button), .disabled) {
				"↶ Undo"
			}
			.style(GeoCitiesPage.Styles.smallButton)

			button(.part(Parts.hint), .type(.button)) {
				"💡 Hint"
			}
			.style(GeoCitiesPage.Styles.smallButton)

			button(.part(Parts.newGame), .type(.button)) {
				"New Game"
			}
			.style(GeoCitiesPage.Styles.smallButton)

			button(.part(Parts.askMormor), .type(.button)) {
				"👵 Ask Mormor"
			}
			.help("Mormor knows best. She says.")
			.style(GeoCitiesPage.Styles.smallButton)

			button(.part(Parts.sound), .type(.button), .ariaPressed(false)) {
				"🔊 Sound"
			}
			.help("Plays sounds")
			.style(GeoCitiesPage.Styles.smallButton)
		}
		.style(GeoCitiesWindows.Styles.wrapRow, GeoCitiesPage.Styles.scriptingOnly)

		p(.part(Parts.status), .role("status")) {
			"Drag a card, or click it to move it to the best place."
		}
		.style(GeoCitiesPage.Styles.statusBar, GeoCitiesPage.Styles.scriptingOnly)

		p(.part(Parts.stats)) {}
			.style(GeoCitiesPage.Styles.caption, GeoCitiesPage.Styles.scriptingOnly)

		p {
			"Spider Solitaire needs JavaScript. The spider is hiding under the sofa."
		}
		.style(GeoCitiesPage.Styles.scriptingDisabledOnly)
	}

	/**
	A menu of the menu bar, like Game, with its commands under it while it is open. An empty command is a line between the groups. The list has an ID for the `aria-controls` of its button.
	*/
	private func menu(_ title: String, button buttonPart: Parts, list: Parts, id: String, commands: [(command: String, title: String, key: String)?]) -> some HTML {
		div {
			button(.part(buttonPart), .type(.button), .ariaExpanded(false), .ariaControls(id)) {
				title
			}
			.style(Styles.menuTitle)

			ul(.id(id), .part(list), .hidden) {
				for item in commands {
					if let item {
						li {
							button(.type(.button), .hook(Hooks.command, value: item.command)) {
								span {
									item.title
								}
								.style(Styles.menuLabel)

								span {
									item.key
								}
								.accessibilityHidden()
							}
							.style(GeoCitiesPage.Styles.startMenuItem)
						}
					} else {
						li {}
							.accessibilityHidden()
							.style(GeoCitiesWindows.Styles.menuSeparator)
					}
				}
			}
			.style(GeoCitiesWindows.Styles.contextMenu, Styles.menuList)
		}
		.style(Styles.menuHolder)
	}

	enum Parts: String, ElementPartSet {
		case gameMenuButton
		case gameMenu
		case helpMenuButton
		case helpMenu
		case table
		case columns
		case foundation
		case balloon
		case score
		case stock
		case fireworks
		case cardTemplate
		case undo
		case hint
		case newGame
		case askMormor
		case sound
		case status
		case stats
	}

	/**
	The columns and the commands of the menus, which carry a value, and the marks that the script sets on the cards and the columns.
	*/
	enum Hooks: String, ScriptHookSet {
		/**
		A column of cards, by its number from the left.
		*/
		case column = "data-spider-column"

		/**
		A command of a menu, like `new` for New Game.
		*/
		case command = "data-spider-command"

		/**
		On a red card, a heart or a diamond.
		*/
		case red = "data-spider-red"

		/**
		On a card that is face down.
		*/
		case faceDown = "data-spider-down"

		/**
		On the cards that the keyboard picked, which are dark, like the picked cards of Solitaire.
		*/
		case selected = "data-spider-selected"

		/**
		On the cards of a hint, and the card they can go on.
		*/
		case hinted = "data-spider-hint"

		/**
		On the cards that follow the pointer while they are dragged.
		*/
		case dragging = "data-spider-dragging"

		/**
		On the column that the dragged cards would drop on.
		*/
		case dropTarget = "data-spider-target"
	}

	enum Styles: ElementStyleSet {
		case root
		case menuBar
		case menuHolder
		case menuTitle
		case menuList
		case menuLabel
		case table
		case columns
		case column
		case card
		case corner
		case pip
		case bottomRow
		case foundation
		case mormor
		case mormorFace
		case balloon
		case scoreBox
		case stock
		case fireworks

		/**
		The dark green of the edges of the empty places on the felt.
		*/
		private static let darkFelt = Color("#004000")

		var style: Style {
			switch self {
			case .root:
				GeoCitiesWindows.Styles.stack.style
			case .menuBar:
				// The menu bar of a program of Windows 98, with Game and Help.
				Style()
					.hstack(alignment: .center)
					.margin(.top, .rootEm(-0.25))
			case .menuHolder:
				Style().position(.relative)
			case .menuTitle:
				// Blue while its menu is open, like the menus of Windows.
				Style()
					.padding(vertical: .rootEm(0.125), horizontal: .rootEm(0.5))
					.background(.transparent)
					.border(.transparent, width: 0)
					.fontFamily(.system)
					.textStyle(.body)
					.color(.black)
					.handCursor()
					.hover {
						$0
							.background(Color("#000080"))
							.color(.white)
					}
					.focusVisible {
						$0
							.background(Color("#000080"))
							.color(.white)
					}
					.when(.state, is: "open") {
						$0
							.background(Color("#000080"))
							.color(.white)
					}
			case .menuList:
				Style()
					.top(.percent(100))
					.leading(0)
					.margin(0)
					.frame(minWidth: .rootEm(14))
			case .menuLabel:
				Style()
					.flex(1)
					.textAlign(.leading)
					.textWrap(.nowrap)
			case .table:
				// The green felt of Spider Solitaire, with the columns at the top, and the completed suits, the score, and the stock at the bottom.
				Style()
					.position(.relative)
					.vstack(spacing: .rootEm(0.5))
					.padding(.rootEm(0.375))
					.background(Color("#008000"))
					.border(Color("#808080"), width: .pixels(2), style: .inset)
					.fontFamily(.system)
					.textSelection(.disabled)
			case .columns:
				Style()
					.grid(columns: 10)
					.alignItems(.start)
					.gap(.pixels(3))
			case .column:
				// A column of cards, which the script lays out, with the face-down cards closer together than the face-up ones. An empty column shows its place on the felt.
				Style()
					.position(.relative)
					.frame(minWidth: 0, minHeight: .rootEm(2.5))
					.padding(0)
					.background(.transparent)
					.border(.transparent, width: .pixels(1))
					.cornerRadius(.pixels(3))
					.handCursor()
					.focusVisible {
						$0.focusRing(Color("#ffff00"), width: .pixels(2), offset: .pixels(1))
					}
					.when(.state, is: "empty") {
						$0.border(Self.darkFelt, width: .pixels(1))
					}
					.when(Hooks.dropTarget) {
						$0
							.background(Color("#00b000"))
							.border(Color("#ffff00"), width: .pixels(1))
					}
			case .card:
				// A card, with its rank and suit in the corner and a big suit at the bottom, red for hearts and diamonds. The back is the blue of the cards of Windows. A finger on a face-up card drags it, and on a face-down card it scrolls the page.
				Style()
					.position(.absolute)
					.top(0)
					.leading(0)
					.padding(.pixels(2))
					.background(.white)
					.border(.black, width: .pixels(1))
					.cornerRadius(.pixels(3))
					.fontFamily(.system)
					.textStyle(.caption, weight: .bold)
					.lineHeight(1)
					.textAlign(.leading)
					.color(.black)
					.overflow(.hidden)
					.touchAction(.none)
					.when(Hooks.red) {
						$0.color(Color("#cc0000"))
					}
					.when(Hooks.faceDown) {
						$0
							.backgroundImage(.radialGradient("circle at 50% 40%", Color("#6d8ff0"), Color("#1a3a9e")))
							.shadow(Shadow(y: 0, spread: .pixels(2), color: .white, isInset: true))
							.touchAction(.auto)
					}
					.when(Hooks.selected) {
						$0.filter(.invert(1))
					}
					.when(Hooks.hinted) {
						$0
							.background(Color("#ffff99"))
							.border(Color("#0000cc"), width: .pixels(2))
					}
					.when(Hooks.dragging) {
						$0
							.zIndex(30)
							.shadow(Shadow(x: .pixels(3), y: .pixels(3), color: Color("#00000066")))
							.allowsHitTesting(false)
					}
			case .corner:
				// The letters are closer together on the narrow cards of a phone, so the 10 fits with its suit.
				Style()
					.display(.block)
					.textWrap(.nowrap)
					.below(.smallTablet) {
						$0.letterSpacing(.pixels(-1.5))
					}
			case .pip:
				Style()
					.position(.absolute)
					.trailing(.pixels(3))
					.bottom(.pixels(2))
					.font(.large)
					.lineHeight(1)
			case .bottomRow:
				Style()
					.hstack(alignment: .end, justification: .spaceBetween, spacing: .rootEm(0.375))
			case .foundation:
				// The completed suits, at the bottom left, each a little to the right of the one before, like in Spider Solitaire.
				Style()
					.position(.relative)
					.flexShrink(0)
					.margin(0)
					.when(.state, is: "empty") {
						$0
							.border(Self.darkFelt, width: .pixels(1))
							.cornerRadius(.pixels(3))
					}
			case .mormor:
				// My grandmother, who watches from the side of the table, and her speech balloon, which floats over the score and the stock, and lets clicks through to them.
				Style()
					.position(.relative)
					.alignSelf(.center)
			case .mormorFace:
				Style()
					.margin(0)
					.font(.extraLarge)
					.lineHeight(1)
			case .balloon:
				Style()
					.position(.absolute)
					.bottom(0)
					.leading(.percent(100))
					.zIndex(25)
					.frame(width: .rootEm(11))
					.margin(.leading, .rootEm(0.25))
					.padding(vertical: .rootEm(0.125), horizontal: .rootEm(0.375))
					.background(.white)
					.border(.black, width: .pixels(1))
					.cornerRadius(.rootEm(0.5))
					.fontFamily(GeoCitiesPage.comicSans)
					.textStyle(.caption)
					.color(.black)
					.overflowWrap(.anywhere)
					.allowsHitTesting(false)
			case .scoreBox:
				// The box in the middle of the bottom of Spider Solitaire, with the score and the moves. A click on it shows a move, like in the game.
				Style()
					.alignSelf(.center)
					.padding(vertical: .rootEm(0.25), horizontal: .rootEm(0.5))
					.background(Color("#006000"))
					.border(Self.darkFelt, width: .pixels(2))
					.fontFamily(.system)
					.textStyle(.caption, weight: .bold)
					.textAlign(.center)
					.preservesLineBreaks()
					.monospacedDigit()
					.color(.white)
					.handCursor()
					.focusVisible {
						$0.focusRing(Color("#ffff00"), width: .pixels(2), offset: .pixels(1))
					}
			case .stock:
				// The stock at the bottom right, one card back for each deal that is left.
				Style()
					.position(.relative)
					.flexShrink(0)
					.padding(0)
					.background(.transparent)
					.border(.transparent, width: .pixels(1))
					.cornerRadius(.pixels(3))
					.handCursor()
					.focusVisible {
						$0.focusRing(Color("#ffff00"), width: .pixels(2), offset: .pixels(1))
					}
					.when(.state, is: "empty") {
						$0.border(Self.darkFelt, width: .pixels(1))
					}
			case .fireworks:
				// The fireworks of a win, over the felt. A click goes through to the table, which stops them.
				Style()
					.position(.absolute)
					.inset(0)
					.zIndex(40)
					.frame(width: .percent(100), height: .percent(100))
					.allowsHitTesting(false)
			}
		}
	}
}
