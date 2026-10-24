import Elementary
import SiteKit

/**
The starting grid of a shared sudoku puzzle, which its script reads from the `p` query item of the page, like Pipoku shares it: a code that people cannot read or edit by hand. Without a valid code, it shows a message instead.

The code is base64url without padding of 11 bytes with a bit for each cell in reading order (from the high bit, 1 for a digit), then each digit in 4 bits (from the high bits, with 4 zero bits after an odd count), then the CRC-8 of the bytes before it. A grid has only one code. The readme of Pipoku has the details. The script must accept exactly the codes that the app accepts, so change both together.
*/
struct SudokuBoard: ScriptedElement {
	static let script = ElementScript(inline: #"""
	const maskByteCount = 11;

	// The CRC-8 with the polynomial `0x07` and the initial value `0`.
	const crc8 = bytes => {
		let crc = 0;

		for (const byte of bytes) {
			crc ^= byte;

			for (let bit = 0; bit < 8; bit++) {
				crc = ((crc << 1) ^ (crc & 0x80 ? 0x07 : 0)) & 0xFF;
			}
		}

		return crc;
	};

	// The 81 cells in reading order, each a digit, or 0 for an empty cell.
	const encode = cells => {
		const givens = cells.filter(digit => digit > 0);
		const bytes = new Uint8Array(maskByteCount + Math.ceil(givens.length / 2) + 1);

		for (const [index, digit] of cells.entries()) {
			if (digit > 0) {
				bytes[Math.floor(index / 8)] |= 0x80 >> (index % 8);
			}
		}

		for (const [index, digit] of givens.entries()) {
			bytes[maskByteCount + Math.floor(index / 2)] |= index % 2 === 0 ? digit << 4 : digit;
		}

		bytes[bytes.length - 1] = crc8(bytes.subarray(0, -1));
		return bytes.toBase64({alphabet: 'base64url', omitPadding: true});
	};

	// The cells of the code, or `undefined` when it is not exactly the code of a grid.
	const decode = code => {
		let bytes;

		try {
			bytes = Uint8Array.fromBase64(code, {alphabet: 'base64url'});
		} catch {
			return;
		}

		// A missing byte reads as 0 and a missing digit as `undefined`, which become empty cells.
		const nibbles = [...bytes.subarray(maskByteCount, -1)].flatMap(byte => [byte >> 4, byte & 0x0F]).values();
		const cells = Array.from({length: 81}, (_, index) => {
			const digit = bytes[Math.floor(index / 8)] & (0x80 >> (index % 8)) ? nibbles.next().value : 0;
			return digit <= 9 ? digit : 0;
		});

		// A grid has only one code, so this rejects every other text: a wrong check byte, too few or too many digits, a digit that is not from 1 to 9, unused bits that are not 0, and padding or other characters.
		return encode(cells) === code ? cells : undefined;
	};

	export default class extends HTMLElement {
		connectedCallback() {
			const board = this.querySelector('[data-part="board"]');

			// The element can be connected again, like when it moves, and the board already has its cells then.
			if (board.childElementCount > 0) {
				return;
			}

			const cells = decode(new URLSearchParams(location.search).get('p') ?? '');

			if (!cells) {
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
					cellElement.textContent = cells[(row * 9) + column] || '';
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
