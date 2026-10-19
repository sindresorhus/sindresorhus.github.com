import Elementary
import SiteKit

/**
The starting grid of a shared sudoku puzzle, which its script reads from the `puzzle` query item of the page, like Pipoku shares it: the 81 cells in reading order, each a digit from 1 to 9, or `.` for an empty cell. Without a valid puzzle, it shows a message instead.
*/
struct SudokuBoard: ScriptedElement {
	static let script = ElementScript(inline: #"""
	export default class extends HTMLElement {
		connectedCallback() {
			const board = this.querySelector('[data-part="board"]');

			// The element can be connected again, like when it moves, and the board already has its cells then.
			if (board.childElementCount > 0) {
				return;
			}

			const puzzle = new URLSearchParams(location.search).get('puzzle') ?? '';

			if (!/^[1-9.]{81}$/.test(puzzle)) {
				this.querySelector('[data-part="invalid"]').hidden = false;
				return;
			}

			const copy = name => this.querySelector(`[data-part="${name}"]`).content.firstElementChild.cloneNode(true);

			// Box by box, as the lines between the boxes are the gaps of the board, and the lines between the cells are the gaps of a box.
			for (let box = 0; box < 9; box++) {
				const boxElement = copy('boxTemplate');

				for (let cell = 0; cell < 9; cell++) {
					const row = (Math.floor(box / 3) * 3) + Math.floor(cell / 3);
					const column = ((box % 3) * 3) + (cell % 3);
					const cellElement = copy('cellTemplate');
					cellElement.textContent = puzzle[(row * 9) + column].replace('.', '');
					boxElement.append(cellElement);
				}

				board.append(boxElement);
			}

			board.hidden = false;
		}
	}
	"""#)

	var content: some HTML {
		div(.part(Parts.board), .role("group"), .hidden) {}
			.accessibilityLabel("Starting grid")
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

	enum Parts: String, ElementPartSet {
		case board
		case invalid
		case boxTemplate
		case cellTemplate
	}

	enum Styles: ElementStyleSet {
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
