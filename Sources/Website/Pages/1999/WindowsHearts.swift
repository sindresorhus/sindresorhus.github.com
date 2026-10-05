import Elementary
import Foundation
import SiteKit

/**
The Microsoft Hearts Network on the desktop of my computer (``GeoCitiesPage/desktop``), like Hearts of Windows 95 and 98, with the real rules: three cards passed to the left, to the right, across, and then kept; the two of clubs leads; no points on the first trick; hearts must be broken; the queen of spades is 13 points; taking all 26 points shoots the moon; and the game ends at 100 points, where the lowest score wins. My three opponents talk while they play: my little sister, my grandmother, and the paperclip of Office. It is the content of its window of the desktop, and its script, `WindowsHearts.js`, deals, plays the opponents, and keeps the games I won in the browser.
*/
struct GeoCitiesWindowsHearts: ScriptedElement {
	static let script = ElementScript()

	/**
	The three opponents, by their seat around the table: the left, across, and the right, with a face and the name the script also knows them by.
	*/
	private static let opponents: [(seat: Int, name: String, face: String)] = [
		(1, "Lillesøster", "👧"),
		(2, "Mormor", "👵"),
		(3, "Clippy", "📎"),
	]

	/**
	The ID of the score sheet, for the `aria-controls` of its button.
	*/
	private static let sheetID = "geocities-hearts-sheet"

	var content: some HTML {
		div {
			div {}
			seat(Self.opponents[1])
			div {}
			seat(Self.opponents[0])
			trick
			seat(Self.opponents[2])
			div {}

			p {
				strong {
					"You"
				}
				" "
				span(.hook(Hooks.score, value: "0")) {
					"0"
				}
			}
			.style(Styles.yourName)

			div {}
		}
		.style(Styles.table, GeoCitiesPage.Styles.scriptingOnly)

		div(.part(Parts.hand), .role("group")) {}
			.accessibilityLabel("Your cards")
			.style(Styles.hand, GeoCitiesPage.Styles.scriptingOnly)

		template(.part(Parts.cardTemplate)) {
			button(.type(.button)) {
				span {}
				span {}
			}
			.style(Styles.card)
		}

		div {
			button(.part(Parts.action), .type(.button), .disabled) {
				"Pass Left"
			}
			.style(GeoCitiesPage.Styles.retroButton)

			button(.part(Parts.sheetToggle), .type(.button), .ariaExpanded(false), .ariaControls(Self.sheetID)) {
				"Score Sheet"
			}
			.style(GeoCitiesPage.Styles.smallButton)

			button(.part(Parts.newGame), .type(.button)) {
				"New Game"
			}
			.style(GeoCitiesPage.Styles.smallButton)

			button(.part(Parts.sound), .type(.button), .ariaPressed(false)) {
				"🔊 Sound"
			}
			.help("Plays sounds")
			.style(GeoCitiesPage.Styles.smallButton)
		}
		.style(GeoCitiesWindows.Styles.wrapRow, GeoCitiesPage.Styles.scriptingOnly)

		div(.id(Self.sheetID), .part(Parts.sheet), .hidden) {
			table {
				caption {
					"Score sheet"
				}
				.style(VisuallyHidden.Styles.root)

				thead {
					tr {
						th(.scope(.col)) {
							"Hand"
						}

						th(.scope(.col)) {
							"You"
						}

						for opponent in Self.opponents {
							th(.scope(.col)) {
								opponent.name
							}
						}
					}
				}

				tbody(.part(Parts.sheetRows)) {}

				tfoot {
					tr {
						th(.scope(.row)) {
							"Total"
						}

						for seat in 0..<4 {
							td(.hook(Hooks.total, value: "\(seat)")) {
								"0"
							}
						}
					}
				}
			}
			.style(Styles.sheetTable)
		}
		.style(Styles.sheet, GeoCitiesPage.Styles.scriptingOnly)

		p(.part(Parts.status), .role("status")) {
			"Pick three cards to pass to Lillesøster, then press Pass Left."
		}
		.style(GeoCitiesPage.Styles.statusBar, GeoCitiesPage.Styles.scriptingOnly)

		p(.part(Parts.wins)) {}
			.style(GeoCitiesPage.Styles.caption, GeoCitiesPage.Styles.scriptingOnly)

		p {
			"Hearts needs JavaScript. Mormor is still shuffling."
		}
		.style(GeoCitiesPage.Styles.scriptingDisabledOnly)
	}

	/**
	An opponent at the table, with a face, a name, a score, and a speech balloon for what they say.
	*/
	private func seat(_ opponent: (seat: Int, name: String, face: String)) -> some HTML {
		div {
			p {
				opponent.face
			}
			.accessibilityHidden()
			.style(Styles.face)

			p {
				strong {
					opponent.name
				}
				" "
				span(.hook(Hooks.score, value: "\(opponent.seat)")) {
					"0"
				}
			}

			// The balloon of the opponent across is beside them, over the empty corner of the table, so it does not cover their card.
			p(.hook(Hooks.balloon, value: "\(opponent.seat)"), .hidden) {}
				.style(Styles.balloon, opponent.seat == 2 ? Styles.balloonBeside : Styles.balloonBelow)
		}
		.style(Styles.seat)
	}

	/**
	The cards of the trick, each in front of the player who played it: across at the top, the left and the right at the sides, and mine at the bottom.
	*/
	private var trick: some HTML {
		div(.role("group")) {
			div {}
			trickSlot(2)
			div {}
			trickSlot(1)
			div {}
			trickSlot(3)
			div {}
			trickSlot(0)
			div {}
		}
		.accessibilityLabel("Cards on the table")
		.style(Styles.trick)
	}

	private func trickSlot(_ seat: Int) -> some HTML {
		p(.hook(Hooks.trickSlot, value: "\(seat)"), .role("img")) {}
			.accessibilityLabel("No card")
			.style(Styles.trickSlot)
	}

	enum Parts: String, ElementPartSet {
		case hand
		case cardTemplate
		case action
		case sheetToggle
		case newGame
		case sound
		case sheet
		case sheetRows
		case status
		case wins
	}

	/**
	The places of each player, which carry the seat, and the mark that the script sets on the red cards.
	*/
	enum Hooks: String, ScriptHookSet {
		/**
		The score of a player, by the seat, where 0 is me.
		*/
		case score = "data-hearts-score"

		/**
		The speech balloon of an opponent, by the seat.
		*/
		case balloon = "data-hearts-balloon"

		/**
		The place of the card that a player played in the trick, by the seat.
		*/
		case trickSlot = "data-hearts-trick"

		/**
		The total of a player on the score sheet, by the seat.
		*/
		case total = "data-hearts-total"

		/**
		On a red card, a heart or a diamond.
		*/
		case red = "data-hearts-red"
	}

	enum Styles: ElementStyleSet {
		case root
		case table
		case seat
		case face
		case balloon
		case balloonBelow
		case balloonBeside
		case yourName
		case trick
		case trickSlot
		case hand
		case card
		case sheet
		case sheetTable

		/**
		The size of a card, in my hand and on the table.
		*/
		private static let cardWidth = Length.rootEm(2)
		private static let cardHeight = Length.rootEm(2.875)

		var style: Style {
			switch self {
			case .root:
				GeoCitiesWindows.Styles.stack.style
			case .table:
				// The green felt of Hearts, with the opponents around the trick, and me at the bottom.
				Style()
					.grid(columns: "1fr auto 1fr")
					.alignItems(.center)
					.gap(.rootEm(0.25))
					.padding(.rootEm(0.375))
					.background(Color("#008000"))
					.border(Color("#808080"), width: .pixels(2), style: .inset)
					.color(.white)
					.textAlign(.center)
					.fontFamily(.system)
					.textStyle(.caption)
			case .seat:
				Style()
					.vstack(alignment: .center, spacing: .rootEm(0.125))
					.position(.relative)
					.frame(minWidth: 0)
			case .face:
				Style()
					.font(.extraLarge)
					.lineHeight(1)
			case .balloon:
				// A white speech balloon of a comic, for what the opponent says. It floats over the felt, so the table does not grow when somebody talks.
				Style()
					.position(.absolute)
					.zIndex(1)
					.frame(width: .max(.percent(100), .rootEm(7)), maxWidth: .rootEm(9))
					.margin(0)
					.padding(vertical: .rootEm(0.125), horizontal: .rootEm(0.375))
					.background(.white)
					.border(.black, width: .pixels(1))
					.cornerRadius(.rootEm(0.5))
					.fontFamily(GeoCitiesPage.comicSans)
					.textStyle(.caption)
					.color(.black)
					.overflowWrap(.anywhere)
			case .balloonBelow:
				Style()
					.top(.percent(100))
					.leading(.percent(50))
					.offset(x: .percent(-50))
			case .balloonBeside:
				Style()
					.top(0)
					.leading(.percent(100))
					.margin(.leading, .rootEm(0.25))
			case .yourName:
				Style().textAlign(.center)
			case .trick:
				Style()
					.grid(columns: 3)
					.gap(.rootEm(0.125))
					.padding(.rootEm(0.25))
			case .trickSlot:
				// An empty place on the felt, until a card is played on it. The card that takes the trick is outlined in yellow.
				Style()
					.vstack(alignment: .center, justification: .center)
					.frame(width: Self.cardWidth, height: Self.cardHeight)
					.border(Color("#004000"), width: .pixels(1))
					.cornerRadius(.pixels(3))
					.fontFamily(.system)
					.textStyle(.body, weight: .bold)
					.lineHeight(1)
					.color(.black)
					.when(.state, is: "played") {
						$0
							.background(.white)
							.border(.black, width: .pixels(1))
					}
					.when(.state, is: "winner") {
						$0
							.background(.white)
							.border(Color("#ffff00"), width: .pixels(3))
					}
					.when(Hooks.red) {
						$0.color(Color("#cc0000"))
					}
			case .hand:
				// My cards, in as many rows as they need on a phone.
				Style()
					.hstack(alignment: .end, justification: .center, spacing: .rootEm(0.125))
					.flexWrap()
					.frame(minHeight: .rootEm(4))
					.padding(.rootEm(0.375))
					.background(Color("#006000"))
					.border(Color("#808080"), width: .pixels(2), style: .inset)
			case .card:
				// A card of my hand, with the rank above the suit. A card picked to pass sticks up, a card that cannot be played now is gray, and the cards that I got passed are yellow for a moment.
				Style()
					.vstack(alignment: .center, justification: .center, spacing: .rootEm(0.125))
					.frame(width: Self.cardWidth, height: Self.cardHeight)
					.flexShrink(0)
					.padding(0)
					.background(.white)
					.border(.black, width: .pixels(1))
					.cornerRadius(.pixels(3))
					.fontFamily(.system)
					.textStyle(.body, weight: .bold)
					.lineHeight(1)
					.color(.black)
					.handCursor()
					.focusVisible {
						$0.focusRing(Color("#ffff00"), width: .pixels(3), offset: .pixels(1))
					}
					.when(Hooks.red) {
						$0.color(Color("#cc0000"))
					}
					.when(.state, is: "picked") {
						$0
							.offset(y: .rootEm(-0.5))
							.background(Color("#c0d8ff"))
					}
					.when(.state, is: "illegal") {
						$0
							.background(Color("#b0b0b0"))
							.opacity(0.75)
					}
					.when(.state, is: "received") {
						$0.background(Color("#ffff99"))
					}
			case .sheet:
				// The score sheet scrolls when the game has many hands.
				Style()
					.frame(maxHeight: .rootEm(10))
					.overflow(.auto)
					.background(.white)
					.border(Color("#808080"), width: .pixels(2), style: .inset)
			case .sheetTable:
				Style()
					.frame(width: .percent(100))
					.fontFamily(.system)
					.textStyle(.caption)
					.textAlign(.center)
					.monospacedDigit()
			}
		}
	}
}
