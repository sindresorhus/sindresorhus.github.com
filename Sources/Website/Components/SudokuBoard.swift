import Elementary
import SiteKit

/**
The starting grid of a shared sudoku puzzle, which its script reads from the `p` query item of the page, like Pipoku shares it: a code that people cannot read or edit by hand. Without a valid code, it shows a message instead.

The code is base64url without padding of 11 bytes with a bit for each cell in reading order (from the high bit, 1 for a digit), then each digit in 4 bits (from the high bits, with 4 zero bits after an odd count), then the CRC-8 of the bytes before it. A grid has only one code. The readme of Pipoku has the details. The script must accept exactly the codes that the app accepts, so change both together.
*/
struct SudokuBoard: ScriptedElement {
	/**
	The shared puzzle query item used by Pipoku and the universal-link association.
	*/
	static let queryName = "p"

	static let script = ElementScript()

	var config: Config? {
		Config()
	}

	var content: some HTML {
		div(.part(Parts.board), .hidden) {}
			.accessibilityLabel("Starting grid", role: .group)
			.style(Styles.board)

		p(.part(Parts.invalid), .hidden) {
			"The link does not have a valid puzzle."
		}

		p {
			"JavaScript is required to show the puzzle."
		}
		.style(Styles.scriptingDisabledOnly)

		template(.part(Parts.boxTemplate)) {
			div {}
				.style(Styles.box)
		}

		template(.part(Parts.cellTemplate)) {
			span {}
				.style(Styles.cell)
		}
	}

	struct Config: Encodable {
		/**
		The query item of the code (``queryName``).
		*/
		let queryName = SudokuBoard.queryName
	}

	enum Parts: String, ElementPartSet {
		case board
		case invalid
		case boxTemplate
		case cellTemplate
	}

	enum Styles: String, ElementStyleSet {
		case root
		case board
		case box
		case cell
		case scriptingDisabledOnly

		var style: Style {
			switch self {
			case .root:
				Style().display(.block)
			case .board:
				// The lines are the gaps, which show the background: thick ones around and between the boxes, and thin ones between the cells of a box. The digits scale with the board, which is never wider than the column.
				Style()
					.grid(columns: 3)
					.gap(.pixels(2))
					.frame(maxWidth: .rootEm(24))
					.containerType(.inlineSize)
					.border(.primaryText, width: .pixels(2))
					.background(.primaryText)
			case .box:
				Style()
					.grid(columns: 3)
					.gap(.pixels(1))
					.background(.separator)
			case .cell:
				Style()
					.hstack(alignment: .center, justification: .center)
					.aspectRatio(1)
					.font(size: .containerInlineSize(6))
					.fontWeight(.medium)
					.monospacedDigit()
					.color(.primaryText)
					.background(.pageBackground)
			case .scriptingDisabledOnly:
				Style().shownOnlyWithoutScripting()
			}
		}
	}
}
