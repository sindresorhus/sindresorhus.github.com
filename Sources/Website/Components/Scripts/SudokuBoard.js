import {cloneTemplate, parts} from '/scripts/dom.js';

/**
The configuration encoded by SudokuBoard.Config in Swift. ScriptTypeTests checks the encoded values against this type.
@typedef {Readonly<{queryName: string}>} SudokuBoardConfig
*/

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

class SudokuBoard extends HTMLElement {
	connectedCallback() {
		const {board, invalid, boxTemplate, cellTemplate} = parts(this);

		// The element can be connected again, like when it moves, and the board already has its cells then.
		if (board.childElementCount > 0) {
			return;
		}

		const {queryName} = /** @type {SudokuBoardConfig} */ (JSON.parse(this.dataset.config));
		const cells = decode(new URLSearchParams(location.search).get(queryName) ?? '');

		if (!cells) {
			invalid.hidden = false;
			return;
		}

		// Box by box, as the lines between the boxes are the gaps of the board, and the lines between the cells are the gaps of a box.
		for (let box = 0; box < 9; box++) {
			const boxElement = cloneTemplate(boxTemplate);

			for (let cell = 0; cell < 9; cell++) {
				const row = (Math.floor(box / 3) * 3) + Math.floor(cell / 3);
				const column = ((box % 3) * 3) + (cell % 3);
				const cellElement = cloneTemplate(cellTemplate);
				cellElement.textContent = cells[(row * 9) + column] || '';
				boxElement.append(cellElement);
			}

			board.append(boxElement);
		}

		board.hidden = false;
	}
}

customElements.define('sudoku-board', SudokuBoard);
