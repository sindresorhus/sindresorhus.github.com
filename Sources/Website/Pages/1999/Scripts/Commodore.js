// My Old Commodore 64 on the 1999 page: Pappa’s C64 from 1984 on the old Tandberg TV. The screen is drawn pixel by pixel from the memory of the C64, with its own font, so POKE and PEEK work like on the real one. It runs a little BASIC V2 in the screen editor of the C64, loads from the 1541 floppy drive and the Datassette with their sounds, keeps the programs of the visitor on Pappa’s disk in the browser, and has the cracktro of TEAM WAFFLE and the game Waffle Raid with SID music. The joystick is broken to the left, the power brick gets warm, and Pappa’s notebook types the famous programs in. It runs only while it is on the screen and the tab is visible. For visitors who prefer reduced motion, nothing moves by itself: the cursor does not blink, a program pauses until a key is pressed, and the game moves only while the joystick is held. The sound is off until the visitor turns it on.

const clamp = (value, minimum, maximum) => Math.min(Math.max(value, minimum), maximum);

// Shows a toggle button as pressed, for screen readers and for the style.
const setPressed = (button, isPressed) => {
	button.setAttribute('aria-pressed', String(isPressed));
	button.dataset.state = isPressed ? 'on' : '';
};

// The 16 colors of the C64, as the VIC-II chip makes them on a PAL TV, as words for the pixels of the canvas.
const rgbWord = (red, green, blue) => ((255 << 24) | (blue << 16) | (green << 8) | red) >>> 0;
const palette = [
	[0, 0, 0], [255, 255, 255], [104, 55, 43], [112, 164, 178], [111, 61, 134], [88, 141, 67], [53, 40, 121], [184, 199, 111],
	[111, 79, 37], [67, 57, 0], [154, 103, 89], [68, 68, 68], [108, 108, 108], [154, 210, 132], [108, 94, 181], [149, 149, 149],
].map(([red, green, blue]) => rgbWord(red, green, blue));
const offScreen = rgbWord(16, 20, 16);
const colors = {black: 0, white: 1, red: 2, cyan: 3, purple: 4, green: 5, blue: 6, yellow: 7, orange: 8, brown: 9, lightRed: 10, darkGray: 11, gray: 12, lightGreen: 13, lightBlue: 14, lightGray: 15};
const colorNames = ['black', 'white', 'red', 'cyan', 'purple', 'green', 'blue', 'yellow', 'orange', 'brown', 'light red', 'dark gray', 'gray', 'light green', 'light blue', 'light gray'];

// The font of the C64, 8 × 8 pixels for each of the 128 screen codes: @, the capital letters, the digits and signs, and the graphic characters, like ╲ and ╱ of the maze. Each is 8 rows as hexadecimal bytes. A screen code from 128 is the same character, reversed.
const fontRows = [
	'3C666E6E60623C00', '183C667E66666600', '7C66667C66667C00', '3C66606060663C00', '786C6666666C7800', '7E60607860607E00', '7E60607860606000', '3C66606E66663C00',
	'6666667E66666600', '3C18181818183C00', '1E0C0C0C0C6C3800', '666C7870786C6600', '6060606060607E00', '63777F6B63636300', '66767E7E6E666600', '3C66666666663C00',
	'7C66667C60606000', '3C666666663C0E00', '7C66667C786C6600', '3C66603C06663C00', '7E18181818181800', '6666666666663C00', '66666666663C1800', '6363636B7F776300',
	'66663C183C666600', '6666663C18181800', '7E060C1830607E00', '3C30303030303C00', '0C12307C3062FC00', '3C0C0C0C0C0C3C00', '00183C7E18181818', '0010307F7F301000',
	'0000000000000000', '1818181800001800', '6666660000000000', '6666FF66FF666600', '183E603C067C1800', '62660C1830664600', '3C663C3867663F00', '060C180000000000',
	'0C18303030180C00', '30180C0C0C183000', '00663CFF3C660000', '0018187E18180000', '0000000000181830', '0000007E00000000', '0000000000181800', '0003060C18306000',
	'3C666E7666663C00', '1818381818187E00', '3C66060C30607E00', '3C66061C06663C00', '060E1E667F060600', '7E607C0606663C00', '3C66607C66663C00', '7E660C1818181800',
	'3C66663C66663C00', '3C66663E06663C00', '0000180000180000', '0000180000181830', '0E18306030180E00', '00007E007E000000', '70180C060C187000', '3C66060C18001800',
	'000000FFFF000000', '081C3E7F7F1C3E00', '1818181818181818', '000000FFFF000000', '0000FFFF00000000', '00FFFF0000000000', '00000000FFFF0000', '3030303030303030',
	'0C0C0C0C0C0C0C0C', '000000E0F0381818', '18181C0F07000000', '181838F0E0000000', 'C0C0C0C0C0C0FFFF', 'C0E070381C0E0703', '03070E1C3870E0C0', 'FFFFC0C0C0C0C0C0',
	'FFFF030303030303', '003C7E7E7E7E3C00', '0000000000FFFF00', '367F7F7F3E1C0800', '6060606060606060', '000000070F1C1818', 'C3E77E3C3C7EE7C3', '003C7E66667E3C00',
	'1818666618183C00', '0606060606060606', '081C3E7F3E1C0800', '181818FFFF181818', 'C0C03030C0C03030', '1818181818181818', '00033E7636360000', 'FF7F3F1F0F070301',
	'0000000000000000', 'F0F0F0F0F0F0F0F0', '00000000FFFFFFFF', 'FF00000000000000', '00000000000000FF', 'C0C0C0C0C0C0C0C0', 'CCCC3333CCCC3333', '0303030303030303',
	'00000000CCCC3333', 'FFFEFCF8F0E0C080', '0F0F0F0F0F0F0F0F', '1818181F1F181818', '000000000F0F0F0F', '1818181F1F000000', '000000F8F8181818', '000000000000FFFF',
	'0000001F1F181818', '181818FFFF000000', '000000FFFF181818', '181818F8F8181818', 'E0E0E0E0E0E0E0E0', 'F8F8F8F8F8F8F8F8', '0707070707070707', 'FFFF000000000000',
	'FFFFFF0000000000', '0000000000FFFFFF', '0103066C78706000', '00000000F0F0F0F0', '0F0F0F0F00000000', '181818F8F8000000', 'F0F0F0F000000000', 'F0F0F0F00F0F0F0F',
];
const glyphs = new Uint8Array(128 * 8);
for (const [code, rows] of fontRows.entries()) {
	for (let row = 0; row < 8; row++) {
		glyphs[(code * 8) + row] = Number.parseInt(rows.slice(row * 2, (row * 2) + 2), 16);
	}
}

// PETSCII, the character codes of the C64, and the screen codes that are in the memory of the screen. The control codes, like the colors, have no screen code.
const isControl = code => code < 32 || (code >= 128 && code < 160);

const petsciiToScreen = code => {
	if (isControl(code)) {
		return -1;
	}

	if (code < 64) {
		return code;
	}

	if (code < 96) {
		return code - 64;
	}

	if (code < 128) {
		return code - 32;
	}

	if (code < 192) {
		return code - 64;
	}

	if (code < 255) {
		return code - 128;
	}

	return 94;
};

const screenToPetscii = code => {
	const base = code & 127;
	if (base < 32) {
		return base + 64;
	}

	if (base < 64) {
		return base;
	}

	if (base < 96) {
		return base + 128;
	}

	return base + 64;
};

// In quotes, a control code is shown as a reversed character, like the red color in `PRINT "{RED}HI"`, and it does its job when the line is printed.
const controlToScreen = code => (code < 32 ? code : code - 64) | 128;

// The control codes of the colors, by color.
const colorCodes = new Map([[144, 0], [5, 1], [28, 2], [159, 3], [156, 4], [30, 5], [31, 6], [158, 7], [129, 8], [149, 9], [150, 10], [151, 11], [152, 12], [153, 13], [154, 14], [155, 15]]);

// The picture of the TV, 384 × 272 pixels: the 320 × 200 pixels of the C64 at 32, 36, and the border around them.
const width = 384;
const height = 272;
const left = 32;
const top = 36;

// A little picture of rows of letters, each a color, and a dot for nothing, like the sprites of the games.
const pictureColors = {k: 0, w: 1, r: 2, c: 3, p: 4, g: 5, b: 6, y: 7, o: 8, n: 9, s: 10, d: 11, m: 12, e: 13, l: 14, a: 15};
const screenStart = 1024;
const colorStart = 55296;
const borderRegister = 53280;
const backgroundRegister = 53281;
const textColorAddress = 646;
const keyCountAddress = 198;
const sidStart = 54272;

// The music of the game and the cracktro, for the three voices of the SID: a lead of pulse waves, a bass, and a third voice that plays the drums and, between them, the chords as a fast arpeggio, the trick of the C64 musicians.
const noteNames = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
const frequencyOf = note => {
	const octave = Number(note.at(-1));
	const semitone = noteNames.indexOf(note.slice(0, -1)) + ((octave + 1) * 12);
	return 440 * (2 ** ((semitone - 69) / 12));
};

const chords = {
	Am: ['A4', 'C5', 'E5'],
	F: ['F4', 'A4', 'C5'],
	C: ['C5', 'E5', 'G5'],
	G: ['G4', 'B4', 'D5'],
	Dm: ['D4', 'F4', 'A4'],
	Bb: ['A#4', 'D5', 'F5'],
	A: ['A4', 'C#5', 'E5'],
};

const pattern = (chord, lead, bass, drums) => ({chord, lead: lead.split(' '), bass: bass.split(' '), drums: drums.split(' ')});

const songs = {
	title: {
		rowDuration: 0.13,
		patterns: [
			pattern('Am', 'E5 -- A5 -- B5 -- C6 -- B5 -- A5 -- E5 -- -- --', 'A2 .. A3 .. A2 .. A3 .. A2 .. A3 .. A2 A2 A3 ..', 'k . h . s . h . k k h . s . h h'),
			pattern('F', 'F5 -- A5 -- C6 -- A5 -- F5 -- -- -- C5 -- -- --', 'F2 .. F3 .. F2 .. F3 .. F2 .. F3 .. F2 F2 F3 ..', 'k . h . s . h . k k h . s . h h'),
			pattern('C', 'E5 -- G5 -- C6 -- G5 -- E5 -- D5 -- C5 -- -- --', 'C3 .. C4 .. C3 .. C4 .. C3 .. C4 .. C3 C3 C4 ..', 'k . h . s . h . k k h . s . h h'),
			pattern('G', 'D5 -- G5 -- B5 -- D6 -- B5 -- G5 -- D5 -- B4 --', 'G2 .. G3 .. G2 .. G3 .. G2 .. G3 .. G2 G2 G3 ..', 'k . h . s . h . k . s . s s s s'),
			pattern('Am', 'A5 -- -- -- G5 -- E5 -- A5 -- C6 -- B5 -- A5 --', 'A2 .. A3 .. A2 .. A3 .. A2 .. A3 .. A2 A2 A3 ..', 'k . h . s . h . k k h . s . h h'),
			pattern('F', 'C6 -- -- -- A5 -- F5 -- A5 -- C6 -- F6 -- -- --', 'F2 .. F3 .. F2 .. F3 .. F2 .. F3 .. F2 F2 F3 ..', 'k . h . s . h . k k h . s . h h'),
			pattern('C', 'G5 -- -- -- E5 -- C5 -- E5 -- G5 -- C6 -- -- --', 'C3 .. C4 .. C3 .. C4 .. C3 .. C4 .. C3 C3 C4 ..', 'k . h . s . h . k k h . s . h h'),
			pattern('G', 'B5 -- -- -- D6 -- B5 -- G5 -- -- -- .. .. .. ..', 'G2 .. G3 .. G2 .. G3 .. G2 .. G3 .. G2 G2 G3 ..', 'k . h . s . h . k . s . s s s s'),
		],
	},
	cracktro: {
		rowDuration: 0.1,
		patterns: [
			pattern('Dm', 'D5 F5 A5 D6 A5 F5 D5 F5 A5 -- -- -- G5 -- F5 --', 'D2 .. D3 D2 .. D2 D3 .. D2 .. D3 D2 .. D2 D3 ..', 'k . h k s . h . k . h k s . h s'),
			pattern('Bb', 'D5 F5 A#5 D6 A#5 F5 D5 F5 A#5 -- -- -- A5 -- G5 --', 'A#1 .. A#2 A#1 .. A#1 A#2 .. A#1 .. A#2 A#1 .. A#1 A#2 ..', 'k . h k s . h . k . h k s . h s'),
			pattern('C', 'E5 G5 C6 E6 C6 G5 E5 G5 C6 -- -- -- A#5 -- A5 --', 'C2 .. C3 C2 .. C2 C3 .. C2 .. C3 C2 .. C2 C3 ..', 'k . h k s . h . k . h k s . h s'),
			pattern('A', 'C#5 E5 A5 C#6 A5 E5 C#5 E5 A5 -- -- -- -- -- .. ..', 'A1 .. A2 A1 .. A1 A2 .. A1 .. A2 A1 .. A1 A2 ..', 'k . h k s . s . k . s s s s s s'),
		],
	},
};

const isNote = token => token !== '--' && token !== '..';

// How many rows a note lasts: its row, and the rows of `--` after it.
const noteRows = (tokens, row) => {
	let count = 1;
	while (row + count < tokens.length && tokens[row + count] === '--') {
		count++;
	}

	return count;
};

// The times of the envelopes of the SID, from 2 milliseconds to 8 seconds.
const attackTimes = [0.002, 0.008, 0.016, 0.024, 0.038, 0.056, 0.068, 0.08, 0.1, 0.25, 0.5, 0.8, 1, 3, 5, 8];
const tapeLength = 450;
const tapeHeader = 8;
const tapeGameEnd = 74;
const tapeSpeeds = {play: 8, record: 8, forward: 45, rewind: -45};

// The BASIC V2 of the C64. A line is cut into tokens like on the real one: the keywords are found anywhere, also inside the names of variables, so SCORE is SC OR E.
class BasicError extends Error {
	constructor(message, lineNumber) {
		super(message);
		this.lineNumber = lineNumber;
	}
}

const fail = (message, lineNumber) => {
	throw new BasicError(message, lineNumber);
};

const keywords = ['END', 'FOR', 'NEXT', 'DATA', 'INPUT#', 'INPUT', 'DIM', 'READ', 'LET', 'GOTO', 'RUN', 'IF', 'RESTORE', 'GOSUB', 'RETURN', 'REM', 'STOP', 'ON', 'WAIT', 'LOAD', 'SAVE', 'VERIFY', 'DEF', 'POKE', 'PRINT#', 'PRINT', 'CONT', 'LIST', 'CLR', 'CMD', 'SYS', 'OPEN', 'CLOSE', 'GET', 'NEW', 'TAB(', 'TO', 'FN', 'SPC(', 'THEN', 'NOT', 'STEP', 'AND', 'OR', 'SGN', 'INT', 'ABS', 'USR', 'FRE', 'POS', 'SQR', 'RND', 'LOG', 'EXP', 'COS', 'SIN', 'TAN', 'ATN', 'PEEK', 'LEN', 'STR$', 'VAL', 'ASC', 'CHR$', 'LEFT$', 'RIGHT$', 'MID$', 'GO'];
const matchKeyword = (text, index) => keywords.find(keyword => text.startsWith(keyword, index));
const isLetter = character => character >= 'A' && character <= 'Z';
const isDigit = character => character >= '0' && character <= '9';

const tokenize = text => {
	const tokens = [];
	let index = 0;
	while (index < text.length) {
		const character = text[index];
		if (character === ' ') {
			index++;
			continue;
		}

		if (character === '"') {
			const end = text.indexOf('"', index + 1);
			tokens.push({type: 'string', value: text.slice(index + 1, end === -1 ? text.length : end)});
			index = end === -1 ? text.length : end + 1;
			continue;
		}

		if (isDigit(character) || character === '.') {
			let end = index;
			while (end < text.length && (isDigit(text[end]) || text[end] === '.')) {
				end++;
			}

			if (text[end] === 'E') {
				let probe = end + 1;
				if (text[probe] === '+' || text[probe] === '-') {
					probe++;
				}

				if (isDigit(text[probe])) {
					end = probe;
					while (end < text.length && isDigit(text[end])) {
						end++;
					}
				}
			}

			const value = Number(text.slice(index, end));
			tokens.push({type: 'number', value: Number.isNaN(value) ? Number.parseFloat(text.slice(index, end)) || 0 : value});
			index = end;
			continue;
		}

		if (character === '?') {
			tokens.push({type: 'keyword', value: 'PRINT'});
			index++;
			continue;
		}

		if (isLetter(character)) {
			const keyword = matchKeyword(text, index);
			if (keyword) {
				tokens.push({type: 'keyword', value: keyword});
				index += keyword.length;
				if (keyword === 'REM') {
					tokens.push({type: 'rest', value: text.slice(index)});
					index = text.length;
				} else if (keyword === 'DATA') {
					// The items of DATA are read later, as they are, up to a colon that is not in quotes.
					let end = index;
					let isInQuotes = false;
					while (end < text.length && (isInQuotes || text[end] !== ':')) {
						if (text[end] === '"') {
							isInQuotes = !isInQuotes;
						}

						end++;
					}

					tokens.push({type: 'data', value: text.slice(index, end)});
					index = end;
				}

				continue;
			}

			let name = character;
			index++;
			while (index < text.length && (isLetter(text[index]) || isDigit(text[index])) && !matchKeyword(text, index)) {
				name += text[index];
				index++;
			}

			if (text[index] === '$' || text[index] === '%') {
				name += text[index];
				index++;
			}

			tokens.push({type: 'name', value: name});
			continue;
		}

		tokens.push({type: 'symbol', value: character});
		index++;
	}

	return tokens;
};

// Numbers are printed like on the C64: a space for the sign, at most nine digits, no 0 before the point, and an exponent for the very big and the very small.
const formatNumber = number => {
	if (number === 0) {
		return ' 0';
	}

	const sign = number < 0 ? '-' : ' ';
	const magnitude = Math.abs(number);
	if (magnitude >= 1e9 || magnitude < 0.01) {
		const [mantissa, exponent] = magnitude.toExponential(8).split('e');
		let digits = mantissa;
		while (digits.endsWith('0')) {
			digits = digits.slice(0, -1);
		}

		if (digits.endsWith('.')) {
			digits = digits.slice(0, -1);
		}

		const power = Number(exponent);
		return `${sign}${digits}E${power < 0 ? '-' : '+'}${String(Math.abs(power)).padStart(2, '0')}`;
	}

	const text = String(Number(magnitude.toPrecision(9)));
	return sign + (text.startsWith('0.') ? text.slice(1) : text);
};

// A number as INPUT and READ accept it, or undefined.
const parseNumber = text => {
	const trimmed = text.trim();
	if (trimmed === '') {
		return 0;
	}

	const number = /^[+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:E[+-]?\d+)?$/.test(trimmed) ? Number(trimmed) : undefined;
	return number === undefined ? undefined : checkNumber(number);
};

// Splits the items of INPUT or DATA at the commas that are not in quotes.
const splitItems = text => {
	const items = [];
	let current = '';
	let isQuoted = false;
	let isInQuotes = false;
	for (const character of text) {
		if (character === '"') {
			isInQuotes = !isInQuotes;
			isQuoted = true;
		} else if (character === ',' && !isInQuotes) {
			items.push({text: isQuoted ? current : current.trim(), isQuoted});
			current = '';
			isQuoted = false;
		} else if (isInQuotes || current !== '' || character !== ' ') {
			current += character;
		}
	}

	items.push({text: isQuoted ? current : current.trim(), isQuoted});
	return items;
};

const isSymbol = (token, value) => token?.type === 'symbol' && token.value === value;
const isKeyword = (token, value) => token?.type === 'keyword' && token.value === value;

const toInteger = (value, minimum, maximum) => {
	const integer = Math.trunc(value);
	if (integer < minimum || integer > maximum) {
		fail('ILLEGAL QUANTITY');
	}

	return integer;
};

const toByte = value => toInteger(value, 0, 255);
const toAddress = value => toInteger(value, 0, 65535);
const toWord = value => toInteger(Math.floor(value), -32768, 32767);

// Only the first two letters of a name count, like on the C64, so SCORE and SC are the same. A $ is for text, and a % for whole numbers.
const variableKey = name => {
	const suffix = name.endsWith('$') || name.endsWith('%') ? name.at(-1) : '';
	return name.slice(0, suffix ? -1 : name.length).slice(0, 2) + suffix;
};

const isStringKey = key => key.endsWith('$');

const coerce = (key, value) => {
	if (isStringKey(key)) {
		if (typeof value !== 'string') {
			fail('TYPE MISMATCH');
		}

		return value;
	}

	if (typeof value !== 'number') {
		fail('TYPE MISMATCH');
	}

	return key.endsWith('%') ? toInteger(value, -32768, 32767) : value;
};

// The expressions, from the weakest operator to the strongest: OR, AND, NOT, the comparisons, + and −, * and /, the minus sign, and ↑ for the power.
const checkNumber = value => {
	if (typeof value !== 'number') {
		fail('TYPE MISMATCH');
	}

	if (!Number.isFinite(value)) {
		fail('OVERFLOW');
	}

	return value;
};

const isComparisonSymbol = token => isSymbol(token, '<') || isSymbol(token, '=') || isSymbol(token, '>');

const errorHints = {
	SYNTAX: 'The C64 did not understand that. It only speaks BASIC, not Norwegian. Try PRINT "HELLO".',
	'FILE NOT FOUND': 'That is not on Pappa’s disk. LOAD "$",8 and then LIST show what is on it.',
	'OUT OF DATA': 'READ wanted more DATA than there is.',
	'UNDEF\'D STATEMENT': 'There is no line with that number. LIST shows the lines.',
	'DEVICE NOT PRESENT': 'Only the tape (1) and the floppy drive (8) are plugged in.',
	'TYPE MISMATCH': 'Text and numbers do not mix. The names of text variables end with $, like A$.',
	'ILLEGAL QUANTITY': 'That number is too big or too small for it. POKE takes 0 to 255.',
	'DIVISION BY ZERO': 'Not even the C64 can divide by zero.',
	'NEXT WITHOUT FOR': 'NEXT needs a FOR first.',
	'ILLEGAL DIRECT': 'That only works in a program, in a line with a number, like 10 INPUT A$.',
	'CAN\'T CONTINUE': 'CONT goes on after RUN/STOP, but only if the program did not change.',
	'MISSING FILE NAME': 'The disk wants a name, like LOAD "BALLOON",8.',
};

// The C64 runs about 800 statements of BASIC in a second.
const statementsPerSecond = 800;

// The keys of the C64 and the PETSCII they type, with SHIFT for the graphic characters and the signs above the digits, CTRL for the colors, and the Commodore key for the graphic characters of the left side of the keys.
const specialKeys = {
	return: [13, 141],
	delete: [20, 148],
	insert: [148, 148],
	'clear-home': [19, 147],
	'cursor-down': [17, 145],
	'cursor-up': [145, 145],
	'cursor-right': [29, 157],
	'cursor-left': [157, 157],
	space: [32, 160],
	f1: [133, 137],
	f2: [137, 137],
	f3: [134, 138],
	f4: [138, 138],
	f5: [135, 139],
	f6: [139, 139],
	f7: [136, 140],
	f8: [140, 140],
	'left-arrow': [95, 95],
	'up-arrow': [94, 255],
	pound: [92, 169],
};
const shiftedSigns = {1: 33, 2: 34, 3: 35, 4: 36, 5: 37, 6: 38, 7: 39, 8: 40, 9: 41, ':': 91, ';': 93, ',': 60, '.': 62, '/': 63, '+': 219, '-': 221, '@': 186, '*': 192};
const controlKeys = {1: 144, 2: 5, 3: 28, 4: 159, 5: 156, 6: 30, 7: 31, 8: 158, 9: 18, 0: 146};
const commodoreKeys = {1: 129, 2: 149, 3: 150, 4: 151, 5: 152, 6: 153, 7: 154, 8: 155, A: 176, B: 191, C: 188, D: 172, E: 177, F: 187, G: 165, H: 180, I: 162, J: 181, K: 161, L: 182, M: 167, N: 170, O: 185, P: 175, Q: 171, R: 178, S: 174, T: 163, U: 184, V: 190, W: 179, X: 189, Y: 183, Z: 173};

const keyCode = (key, {shift = false, control = false, commodore = false} = {}) => {
	if (control && Object.hasOwn(controlKeys, key)) {
		return controlKeys[key];
	}

	if (commodore && Object.hasOwn(commodoreKeys, key)) {
		return commodoreKeys[key];
	}

	if (Object.hasOwn(specialKeys, key)) {
		return specialKeys[key][shift ? 1 : 0];
	}

	if (key.length !== 1) {
		return undefined;
	}

	const code = key.charCodeAt(0);
	if (code >= 65 && code <= 90) {
		return shift ? code + 128 : code;
	}

	if (shift && Object.hasOwn(shiftedSigns, key)) {
		return shiftedSigns[key];
	}

	return (code >= 32 && code <= 64) || code === 91 || code === 93 || code === 94 ? code : undefined;
};

// A character from the keyboard of the computer or the field, as a key of the C64. The curly quotes of the keyboards of phones are the straight ones of the C64.
const characterKey = character => {
	const replacements = {' ': 'space', '£': 'pound', '“': '"', '”': '"', '‘': '\'', '’': '\'', '^': 'up-arrow'};
	if (Object.hasOwn(replacements, character)) {
		return replacements[character];
	}

	if (character.length !== 1) {
		return undefined;
	}

	const upper = character.toUpperCase();
	return upper.length === 1 && keyCode(upper) !== undefined ? upper : undefined;
};

// The devices: the jobs of the drive and the tape take time, while the C64 waits, and RUN/STOP stops them.
class Cancelled extends Error {}

// Pappa’s disk. The programs of the visitor are saved after his, and kept in the browser.
const parseLines = lines => lines.map(line => {
	const space = line.indexOf(' ');
	return [Number(line.slice(0, space)), line.slice(space + 1)];
});

const blocksOf = lines => {
	let bytes = 2;
	for (const [, text] of lines) {
		bytes += text.length + 5;
	}

	return Math.max(1, Math.ceil(bytes / 254));
};

const builtInFiles = [
	{name: 'WAFFLE RAID', type: 'PRG', blocks: 48, isGame: true},
	{
		name: 'MAMMAS VAFLER',
		type: 'PRG',
		lines: parseLines([
			'10 PRINT CHR$(147);CHR$(158);"MAMMAS VAFLER";CHR$(154)',
			'20 PRINT "(MAMMA\'S WAFFLES, NORWAY 1984)":PRINT',
			'30 INPUT "HVOR MANGE ER DERE";N',
			'40 IF N<1 THEN PRINT "INGEN? MORMOR BLIR LEI SEG.":GOTO 30',
			'50 PRINT:PRINT "TIL";N;"PERSONER TRENGER DU:":PRINT',
			'60 FOR I=1 TO 6:READ A,U$,T$',
			'70 PRINT INT(A*N*10+.5)/10;U$;" ";T$',
			'80 NEXT',
			'90 PRINT:PRINT "STEK I VAFFELJERNET. SERVER MED"',
			'100 PRINT "BRUNOST OG SYLTETOY. VELBEKOMME!"',
			'200 DATA 1.25,"DL","MELK",1,"STK","EGG",1,"DL","HVETEMEL"',
			'210 DATA .5,"SS","SUKKER",15,"G","SMOR",.25,"TS","KARDEMOMME"',
		]),
	},
	{
		name: 'BALLOON',
		type: 'PRG',
		lines: parseLines([
			'1 REM UP, UP, AND AWAY',
			'5 PRINT CHR$(147)',
			'10 V=53248 : REM START OF DISPLAY CHIP',
			'11 POKE V+21,4 : REM ENABLE SPRITE 2',
			'12 POKE 2042,13 : REM SPRITE 2 DATA FROM 13TH BLK',
			'20 FOR N = 0 TO 62 : READ Q : POKE 832+N,Q : NEXT',
			'30 FOR X = 0 TO 200',
			'40 POKE V+4,X : REM UPDATE X COORDINATES',
			'50 POKE V+5,X : REM UPDATE Y COORDINATES',
			'60 NEXT X',
			'70 GOTO 30',
			'200 DATA 0,127,0,1,255,192,3,255,224,3,231,224',
			'210 DATA 7,217,240,7,223,240,7,217,240,3,231,224',
			'220 DATA 3,255,224,3,255,224,2,255,160,1,127,64',
			'230 DATA 1,62,64,0,156,128,0,156,128,0,73,0,0,73,0',
			'240 DATA 0,62,0,0,62,0,0,62,0,0,28,0',
		]),
	},
	{
		name: 'GJETT TALLET',
		type: 'PRG',
		lines: parseLines([
			'10 PRINT CHR$(147);"GJETT TALLET! (GUESS THE NUMBER)"',
			'20 T=INT(RND(1)*100)+1:F=0',
			'30 PRINT:INPUT "GJETT 1-100";G:F=F+1',
			'40 IF G<T THEN PRINT "FOR LITE! (TOO LOW)":GOTO 30',
			'50 IF G>T THEN PRINT "FOR MYE! (TOO HIGH)":GOTO 30',
			'60 PRINT "RIKTIG! DU BRUKTE";F;"FORSOK."',
			'70 IF F<7 THEN PRINT "DU ER LIKE FLINK SOM PAPPA!"',
			'80 INPUT "EN GANG TIL (J/N)";A$',
			'90 IF A$="J" THEN 10',
		]),
	},
	{name: 'MAZE', type: 'PRG', lines: parseLines(['10 PRINT CHR$(205.5+RND(1));:GOTO 10'])},
	{
		name: 'IKKE ROR!!!',
		type: 'PRG',
		lines: parseLines([
			'10 PRINT CHR$(147);CHR$(28);"IKKE ROR PAPPAS DATAMASKIN!"',
			'20 PRINT CHR$(5);"(DO NOT TOUCH PAPPA\'S COMPUTER!)"',
			'30 S=54272:POKE S+24,15:POKE S+5,0:POKE S+6,240:POKE S+4,33',
			'40 FOR I=0 TO 15:POKE 53280,I:POKE S+1,20+I*4:FOR D=1 TO 20:NEXT D:NEXT I',
			'50 FOR I=15 TO 0 STEP -1:POKE 53280,I:POKE S+1,20+I*4:FOR D=1 TO 20:NEXT D:NEXT I',
			'60 GOTO 40',
		]),
	},
	{name: 'PAPPAS SKATT 84', type: 'SEQ', blocks: 12},
	{name: '----------------', type: 'DEL', blocks: 0},
];

for (const file of builtInFiles) {
	if (file.lines) {
		file.blocks = blocksOf(file.lines);
	}
}

// A name of a file can end with * for any ending, and ? stands for any character.
const matchesName = (pattern, name) => {
	for (let index = 0; index < pattern.length; index++) {
		if (pattern[index] === '*') {
			return true;
		}

		if (pattern[index] !== '?' && pattern[index] !== name[index]) {
			return false;
		}
	}

	return pattern.length === name.length;
};

const stripDrive = name => (name.startsWith('0:') ? name.slice(2) : name);
const greetings = '     HELLO FROM TEAM WAFFLE! CRACKED IN BERGEN, NORWAY, WHERE IT RAINS 365 DAYS A YEAR...   GREETINGS TO TROND (THE OTHER HALF OF TEAM WAFFLE), MORMOR (BEST WAFFLES IN THE WORLD), LILLESOSTER (STAY AWAY FROM MY DISKS), ROCKY THE PET ROCK, GLITTER THE UNICORN, AND PAPPA (SORRY WE USED YOUR C64)...   NO GREETINGS TO THE SEAGULLS!     ';

// Waffle Raid: the seagulls of Bergen try to steal the waffles of Mormor from the table at Bryggen, and Sindre throws brunost at them.
const sindre = [
	['....yyyy....', '...yyyyyy...', '.yyyyyyyyyy.', '...ssssss...', '...skssks...', '...ssssss...', '....srrs....', '..yyyyyyyy..', '.yyyyyyyyyy.', 'yyyyyyyyyyyy', 'ss.yyyyyy.ss', '...yyyyyy...', '...yyyyyy...', '...bbbbbb...', '...bb..bb...', '...bb..bb...', '..kkk..kkk..', '..kkk..kkk..'],
	['....yyyy....', '...yyyyyy...', '.yyyyyyyyyy.', '...ssssss...', '...skssks...', '...ssssss...', '....srrs....', '..yyyyyyyy..', '.yyyyyyyyyy.', 'yyyyyyyyyyyy', 'ss.yyyyyy.ss', '...yyyyyy...', '...yyyyyy...', '...bbbbbb...', '..bb....bb..', '..bb....bb..', '.kkk....kkk.', '.kkk.....kk.'],
];
const seagull = [
	['d.............d', 'ww...........ww', '.www.......www.', '...www.w.www...', '.....wwwww.....', '......wow......'],
	['...............', '...............', '....wwwwwww....', '..wwwwwwwwwww..', '.ww...www...ww.', 'd.....wow.....d'],
];
const waffle = ['yoyoyoyoyoyo', 'oyoyoyoyoyoy', 'oooooooooooo'];
const brunost = ['ono', 'nnn', 'nnn', 'nnn'];

// The mountains behind Bryggen, with Ulriken as the highest.
const mountains = Array.from({length: 320}, (_, x) => Math.round(96 + (12 * Math.sin((x * 0.021) + 1)) + (6 * Math.sin(x * 0.067)) - (22 * Math.exp(-(((x - 236) / 38) ** 2)))));

const houseColors = [2, 7, 8, 1, 10, 7, 2, 9];

const pad = number => String(number).padStart(6, '0');

// The keys of the computer, on the screen.
const namedKeys = {Enter: 'return', Backspace: 'delete', Delete: 'delete', Insert: 'insert', Home: 'clear-home', Escape: 'run-stop', PageUp: 'restore', ArrowUp: 'cursor-up', ArrowDown: 'cursor-down', ArrowLeft: 'cursor-left', ArrowRight: 'cursor-right', F1: 'f1', F2: 'f2', F3: 'f3', F4: 'f4', F5: 'f5', F6: 'f6', F7: 'f7', F8: 'f8'};
const joystickKeys = {ArrowUp: 'up', ArrowDown: 'down', ArrowLeft: 'left', ArrowRight: 'right', ' ': 'fire', Control: 'fire'};
const modifierKeys = {shift: 'shift', 'shift-lock': 'shiftLock', control: 'control', commodore: 'commodore'};

// Pappa’s notebook types the lines in, at the speed of a quick finger, and waits for the C64 between them.
const notebook = {
	maze: {lines: ['NEW', '10 PRINT CHR$(205.5+RND(1));:GOTO 10', 'RUN'], note: 'The famous maze! It picks ╱ or ╲ at random, forever. Escape (RUN/STOP) stops it.'},
	cool: {lines: ['NEW', '10 PRINT "SINDRE ER KUL": GOTO 20', '20 GOTO 10', 'RUN'], note: 'Sindre er kul (Sindre is cool), forever. Escape (RUN/STOP) stops it, and the C64 says where.'},
	colors: {lines: [], note: 'POKE 53280 is the border, and 53281 is the background. Click again for other colors.'},
	directory: {lines: ['LOAD "$",8', 'LIST'], note: 'The list of the disk. The numbers are the sizes, in blocks of 254 bytes.'},
	disk: {lines: ['LOAD "*",8,1', 'RUN'], note: 'LOAD "*",8,1 loads the first program of the disk. Listen to the drive grind!'},
	tape: {lines: ['LOAD'], note: 'Loading from the tape: press ▶ PLAY on the Datassette below!'},
	balloon: {lines: ['LOAD "BALLOON",8', 'RUN'], note: 'The balloon from the user’s manual of the C64: a sprite, flying.'},
	waffles: {lines: ['LOAD "MAMMAS VAFLER",8', 'RUN'], note: 'Mamma’s waffle recipe. Type how many you are (hvor mange), and press RETURN.'},
	guess: {lines: ['LOAD "GJETT TALLET",8', 'RUN'], note: 'Guess the number between 1 and 100. Type a number, and press RETURN.'},
	siren: {lines: ['LOAD "IKKE ROR!!!",8', 'RUN'], note: 'Pappa’s alarm for little sisters. Turn on the sound! Escape stops it.'},
	free: {lines: ['PRINT FRE(0)'], note: ''},
	reset: {lines: ['SYS 64738'], note: ''},
};
const colorPairs = [[0, 0], [13, 5], [7, 2], [1, 12], [10, 4], [3, 11], [14, 6]];

export default class extends GeoCitiesElement {
	#context;
	#keyButtons;
	#tapeButtons;
	#joystickButtons;
	#notebookButtons;
	#image;
	#pixels;

	// The 64 kilobytes of the C64. The screen is at 1024, the colors of its characters at 55296, and the chips have their registers at 53248 (the VIC-II for the picture) and 54272 (the SID for the sound).
	#memory = new Uint8Array(65536);

	// The screen editor of the C64: the cursor, and which rows go on from the row above, as a line of BASIC can be 80 characters, two rows.
	#editor = {row: 0, column: 0, isReverse: false};
	#links = Array.from({length: 25}, () => false);
	#inputStart = {row: 0, column: 0};
	#blinkStart = 0;
	#outputLog = '';

	// The sound of the TV, made in the browser. It is off until the visitor turns it on. The sounds that last, like the music and the hum of the drive, play only while the C64 is on the screen and the tab is visible.
	#audio = {
		context: undefined,
		output: undefined,
		isOn: false,
		noiseBuffer: undefined,
		// Starts with the audio of the element, which is only there in the handler of a click.
		start(sound) {
			if (!sound) {
				return false;
			}

			this.context = sound.context;
			this.output = sound.output;
			return true;
		},
		get isReady() {
			return this.isOn && this.context?.state === 'running';
		},
		noise() {
			if (!this.noiseBuffer) {
				const {sampleRate} = this.context;
				this.noiseBuffer = new AudioBuffer({length: sampleRate, numberOfChannels: 1, sampleRate});
				const data = this.noiseBuffer.getChannelData(0);
				for (let index = 0; index < data.length; index++) {
					data[index] = (Math.random() * 2) - 1;
				}
			}

			return this.noiseBuffer;
		},
	};

	// The pulse waves of the SID, where the width of the pulse changes the sound, made from their harmonics.
	#pulseWaves = new Map();

	// The tune of the game or the cracktro that plays now.
	#tune;

	// The SID of the C64, for the POKEs of a BASIC program: three voices, each with a frequency, a wave, an envelope, and a gate bit that starts and stops the note.
	#sidMaster;
	#sidVoices = [undefined, undefined, undefined];

	// The 1541 floppy drive: its light, its motor that hums, and the head that clicks and grinds while it reads.
	#drive = {isActive: false, hum: undefined, nextClick: 0, blinkUntil: 0};

	// The Datassette: the tape, where the counter is, and which key is down. The game is at the start of the tape.
	#tape = {position: 0, motion: 'stop', crossings: 0, sound: undefined, gain: undefined};

	// The program, sorted by line number, and the state of a run.
	#program = [];
	#variables = new Map();
	#arrays = new Map();
	#functions = new Map();
	#stack = [];
	#dataItems;
	#dataIndex = 0;
	#tokens = [];
	#position = 0;
	#lineIndex = -1;
	#statementStart = 0;
	#isJumping = false;
	#isRunning = false;
	#shouldYield = false;
	#waiting;
	#continuePoint;
	#gameInMemory;
	#clockOffset = 0;
	#keyboardBuffer = [];

	#jiffies = 0;

	// The random numbers of RND, which a negative number seeds, so the same seed gives the same numbers.
	#randomState = Math.floor(Math.random() * 2_147_483_647);

	#lastRandom = 0.5;

	// The joystick in port 2.
	#joystick = {up: false, down: false, left: false, right: false, fire: false};
	#leftFixedUntil = 0;
	#fireTapUntil = 0;

	#statements = {
		LET: () => this.#assign(),
		PRINT: () => {
			let needsNewline = true;
			while (!this.#isStatementEnd()) {
				const token = this.#tokens[this.#position];
				if (isSymbol(token, ';')) {
					this.#position++;
					needsNewline = false;
					continue;
				}

				if (isSymbol(token, ',')) {
					this.#position++;
					const spaces = 10 - (this.#logicalColumn() % 10);
					for (let index = 0; index < spaces; index++) {
						this.#printCode(29);
					}

					needsNewline = false;
					continue;
				}

				if (isKeyword(token, 'TAB(') || isKeyword(token, 'SPC(')) {
					this.#position++;
					const count = toByte(this.#evaluateNumber());
					this.#expectSymbol(')');
					const moves = token.value === 'TAB(' ? Math.max(0, count - this.#logicalColumn()) : count;
					for (let index = 0; index < moves; index++) {
						this.#printCode(29);
					}

					needsNewline = false;
					continue;
				}

				const value = this.#evaluate();
				this.#printText(typeof value === 'number' ? `${formatNumber(value)} ` : value);
				needsNewline = true;
			}

			if (needsNewline) {
				this.#printText('\r');
			}
		},
		GOTO: () => {
			this.#goToLine(this.#readLineNumber());
		},
		GO: () => {
			this.#expectKeyword('TO');
			this.#goToLine(this.#readLineNumber());
		},
		GOSUB: () => {
			const target = this.#readLineNumber();
			if (this.#stack.length > 200) {
				fail('OUT OF MEMORY');
			}

			this.#stack.push({type: 'gosub', ...this.#pointer()});
			this.#goToLine(target);
		},
		RETURN: () => {
			while (this.#stack.length > 0 && this.#stack.at(-1).type !== 'gosub') {
				this.#stack.pop();
			}

			const frame = this.#stack.pop();
			if (!frame) {
				fail('RETURN WITHOUT GOSUB');
			}

			this.#restorePointer(frame);
		},
		IF: () => {
			const condition = this.#evaluate();
			const isTrue = typeof condition === 'string' ? condition.length > 0 : condition !== 0;
			if (isKeyword(this.#tokens[this.#position], 'GOTO')) {
				this.#position++;
				const target = this.#readLineNumber();
				if (isTrue) {
					this.#goToLine(target);
				} else {
					this.#skipLine();
				}

				return;
			}

			this.#expectKeyword('THEN');
			if (!isTrue) {
				this.#skipLine();
				return;
			}

			if (this.#tokens[this.#position]?.type === 'number') {
				this.#goToLine(this.#readLineNumber());
				return;
			}

			// The statement after THEN runs next.
			this.#isJumping = true;
		},
		FOR: () => {
			const token = this.#tokens[this.#position];
			if (token?.type !== 'name') {
				fail('SYNTAX');
			}

			this.#position++;
			const key = variableKey(token.value);
			if (isStringKey(key)) {
				fail('TYPE MISMATCH');
			}

			this.#expectSymbol('=');
			this.#setVariable(key, this.#evaluateNumber());
			this.#expectKeyword('TO');
			const limit = this.#evaluateNumber();
			let step = 1;
			if (isKeyword(this.#tokens[this.#position], 'STEP')) {
				this.#position++;
				step = this.#evaluateNumber();
			}

			// A FOR of the same variable replaces the old loop, and the loops inside it.
			for (let index = this.#stack.length - 1; index >= 0; index--) {
				if (this.#stack[index].type === 'gosub') {
					break;
				}

				if (this.#stack[index].key === key) {
					this.#stack.length = index;
					break;
				}
			}

			if (this.#stack.length > 200) {
				fail('OUT OF MEMORY');
			}

			this.#stack.push({type: 'for', key, limit, step, ...this.#pointer()});
		},
		NEXT: () => {
			const keys = [];
			if (this.#tokens[this.#position]?.type === 'name') {
				keys.push(variableKey(this.#tokens[this.#position].value));
				this.#position++;
				while (isSymbol(this.#tokens[this.#position], ',')) {
					this.#position++;
					const token = this.#tokens[this.#position];
					if (token?.type !== 'name') {
						fail('SYNTAX');
					}

					this.#position++;
					keys.push(variableKey(token.value));
				}
			} else {
				keys.push(undefined);
			}

			for (const key of keys) {
				let index = this.#stack.length - 1;
				while (index >= 0 && this.#stack[index].type === 'for' && key !== undefined && this.#stack[index].key !== key) {
					index--;
				}

				if (index < 0 || this.#stack[index].type !== 'for') {
					fail('NEXT WITHOUT FOR');
				}

				this.#stack.length = index + 1;
				const frame = this.#stack[index];
				const value = this.#getVariable(frame.key) + frame.step;
				this.#setVariable(frame.key, value);
				if (frame.step >= 0 ? value <= frame.limit : value >= frame.limit) {
					this.#restorePointer(frame);
					return;
				}

				this.#stack.pop();
			}
		},
		INPUT: () => {
			if (this.#lineIndex < 0) {
				fail('ILLEGAL DIRECT');
			}

			let prompt = '';
			if (this.#tokens[this.#position]?.type === 'string' && isSymbol(this.#tokens[this.#position + 1], ';')) {
				prompt = this.#tokens[this.#position].value;
				this.#position += 2;
			}

			const references = [this.#parseReference()];
			while (isSymbol(this.#tokens[this.#position], ',')) {
				this.#position++;
				references.push(this.#parseReference());
			}

			this.#waiting = {references, values: []};
			this.#printText(`${prompt}? `);
			this.#inputStart = {row: this.#editor.row, column: this.#editor.column};
		},
		GET: () => {
			if (this.#lineIndex < 0) {
				fail('ILLEGAL DIRECT');
			}

			const references = [this.#parseReference()];
			while (isSymbol(this.#tokens[this.#position], ',')) {
				this.#position++;
				references.push(this.#parseReference());
			}

			for (const reference of references) {
				const code = this.#keyboardBuffer.shift();
				if (isStringKey(reference.key)) {
					this.#writeReference(reference, code === undefined ? '' : String.fromCharCode(code));
				} else if (code === undefined) {
					this.#writeReference(reference, 0);
				} else if (code >= 48 && code <= 57) {
					this.#writeReference(reference, code - 48);
				} else {
					fail('SYNTAX');
				}
			}
		},
		END: () => {
			if (this.#lineIndex >= 0) {
				this.#continuePoint = this.#pointer();
			}

			this.#endProgram();
		},
		STOP: () => {
			this.#breakProgram();
		},
		REM: () => {
			this.#skipLine();
		},
		DATA: () => {
			if (this.#tokens[this.#position]?.type === 'data') {
				this.#position++;
			}
		},
		READ: () => {
			if (!this.#dataItems) {
				this.#collectData();
			}

			while (true) {
				const reference = this.#parseReference();
				if (this.#dataIndex >= this.#dataItems.length) {
					fail('OUT OF DATA');
				}

				const item = this.#dataItems[this.#dataIndex];
				this.#dataIndex++;
				if (isStringKey(reference.key)) {
					this.#writeReference(reference, item.text);
				} else {
					const number = item.isQuoted ? undefined : parseNumber(item.text);
					if (number === undefined) {
						fail('SYNTAX', item.lineNumber);
					}

					this.#writeReference(reference, number);
				}

				if (!isSymbol(this.#tokens[this.#position], ',')) {
					break;
				}

				this.#position++;
			}
		},
		RESTORE: () => {
			this.#dataIndex = 0;
		},
		DIM: () => {
			while (true) {
				const token = this.#tokens[this.#position];
				if (token?.type !== 'name') {
					fail('SYNTAX');
				}

				this.#position++;
				const key = variableKey(token.value);
				this.#expectSymbol('(');
				const sizes = [toInteger(this.#evaluateNumber(), 0, 32767)];
				while (isSymbol(this.#tokens[this.#position], ',')) {
					this.#position++;
					sizes.push(toInteger(this.#evaluateNumber(), 0, 32767));
				}

				this.#expectSymbol(')');
				if (this.#arrays.has(key)) {
					fail('REDIM\'D ARRAY');
				}

				this.#createArray(key, sizes);
				if (!isSymbol(this.#tokens[this.#position], ',')) {
					break;
				}

				this.#position++;
			}
		},
		ON: () => {
			const value = Math.trunc(this.#evaluateNumber());
			const isGosub = isKeyword(this.#tokens[this.#position], 'GOSUB');
			if (!isGosub && !isKeyword(this.#tokens[this.#position], 'GOTO')) {
				fail('SYNTAX');
			}

			this.#position++;
			const targets = [this.#readLineNumber()];
			while (isSymbol(this.#tokens[this.#position], ',')) {
				this.#position++;
				targets.push(this.#readLineNumber());
			}

			if (value < 0 || value > 255) {
				fail('ILLEGAL QUANTITY');
			}

			if (value < 1 || value > targets.length) {
				return;
			}

			if (isGosub) {
				this.#stack.push({type: 'gosub', ...this.#pointer()});
			}

			this.#goToLine(targets[value - 1]);
		},
		DEF: () => {
			if (this.#lineIndex < 0) {
				fail('ILLEGAL DIRECT');
			}

			this.#expectKeyword('FN');
			const nameToken = this.#tokens[this.#position];
			const parameterToken = this.#tokens[this.#position + 2];
			if (nameToken?.type !== 'name' || !isSymbol(this.#tokens[this.#position + 1], '(') || parameterToken?.type !== 'name') {
				fail('SYNTAX');
			}

			this.#position += 3;
			this.#expectSymbol(')');
			this.#expectSymbol('=');
			this.#functions.set(variableKey(nameToken.value), {parameter: variableKey(parameterToken.value), tokens: this.#tokens, position: this.#position});
			while (!this.#isStatementEnd()) {
				this.#position++;
			}
		},
		NEW: () => {
			this.#program.length = 0;
			this.#clearVariables();
			this.#continuePoint = undefined;
			if (this.#lineIndex >= 0) {
				this.#lineIndex = -1;
				this.#endProgram();
			}
		},
		CLR: () => {
			this.#clearVariables();
		},
		LIST: () => {
			let from = 0;
			let to = 63_999;
			if (this.#tokens[this.#position]?.type === 'number') {
				from = this.#readLineNumber();
				to = from;
			}

			if (isSymbol(this.#tokens[this.#position], '-')) {
				this.#position++;
				to = this.#tokens[this.#position]?.type === 'number' ? this.#readLineNumber() : 63_999;
			}

			this.#listProgram(from, to);
			if (this.#lineIndex >= 0) {
				this.#endProgram();
			}
		},
		RUN: () => {
			const target = this.#tokens[this.#position]?.type === 'number' ? this.#readLineNumber() : undefined;
			this.#clearVariables();
			this.#continuePoint = undefined;
			this.#lastActivity = this.#clock;
			if (this.#program.length === 0) {
				return;
			}

			if (target === undefined) {
				this.#goToIndex(0);
			} else {
				this.#goToLine(target);
			}
		},
		CONT: () => {
			if (!this.#continuePoint || this.#lineIndex >= 0) {
				fail('CAN\'T CONTINUE');
			}

			this.#restorePointer(this.#continuePoint);
			this.#continuePoint = undefined;
			this.#lastActivity = this.#clock;
		},
		POKE: () => {
			const address = toAddress(this.#evaluateNumber());
			this.#expectSymbol(',');
			this.#pokeMemory(address, toByte(this.#evaluateNumber()));
		},
		SYS: () => {
			this.#sys(toAddress(this.#evaluateNumber()));
		},
		WAIT: () => {
			const address = toAddress(this.#evaluateNumber());
			this.#expectSymbol(',');
			const mask = toByte(this.#evaluateNumber());
			let flip = 0;
			if (isSymbol(this.#tokens[this.#position], ',')) {
				this.#position++;
				flip = toByte(this.#evaluateNumber());
			}

			// WAIT runs again until the bits are right, but gives the screen a frame in between.
			if (((this.#peekMemory(address) ^ flip) & mask) === 0) {
				this.#position = this.#statementStart;
				this.#isJumping = true;
				this.#shouldYield = true;
			}
		},
		LOAD: () => {
			const {name, device, secondary} = this.#deviceArguments();
			if (device !== 1 && device !== 8) {
				fail('DEVICE NOT PRESENT');
			}

			this.#startOperation(device === 8 ? this.#loadFromDisk : this.#loadFromTape, name, secondary, device === 1);
		},
		SAVE: () => {
			const {name, device} = this.#deviceArguments();
			if (device !== 1 && device !== 8) {
				fail('DEVICE NOT PRESENT');
			}

			this.#startOperation(device === 8 ? this.#saveToDisk : this.#saveToTape, name, 0, device === 1);
		},
		VERIFY: () => {
			const {name, device} = this.#deviceArguments();
			if (device !== 8) {
				fail('DEVICE NOT PRESENT');
			}

			this.#startOperation(this.#verifyFromDisk, name, 0, false);
		},
		OPEN: () => {
			const values = [];
			while (!this.#isStatementEnd()) {
				values.push(this.#evaluate());
				if (!isSymbol(this.#tokens[this.#position], ',')) {
					break;
				}

				this.#position++;
			}

			const device = typeof values[1] === 'number' ? values[1] : 1;
			if (device === 4 || device === 5) {
				this.say('Pappa never had a printer. He wrote everything by hand, in his notebook.');
			}

			if (![0, 1, 3, 8].includes(device)) {
				fail('DEVICE NOT PRESENT');
			}
		},
		CLOSE: () => {
			this.#evaluate();
		},
		CMD: () => {
			fail('FILE NOT OPEN');
		},
		'PRINT#': () => {
			fail('FILE NOT OPEN');
		},
		'INPUT#': () => {
			fail('FILE NOT OPEN');
		},
	};

	#lastActivity = 0;
	#operation;
	#clock = 0;
	#waiters = new Set();

	#savedFiles;

	#loadingProgress = 0;

	// The cracktro of TEAM WAFFLE, before the cracked game from the tape, with raster bars, a logo, the trainer, and a scroller of greetings.
	#cracktro = {startClock: 0, hasUnlimitedWaffles: false, hasSlowSeagulls: false};

	#game = {
		screen: 'title',
		isCracked: false,
		score: 0,
		highScore: 0,
		wave: 1,
		waffles: 5,
		player: 154,
		walk: 0,
		cooldown: 0,
		timer: 0,
		toSpawn: 0,
		spawnTimer: 0,
		wasFiring: false,
		hasWarnedLeft: false,
		shots: [],
		gulls: [],
		feathers: [],
		popups: [],
	};
	#rain = Array.from({length: 40}, () => ({x: Math.random() * 320, y: 18 + (Math.random() * 182), speed: 140 + (Math.random() * 90)}));

	#screenMode = 'off';
	#bootClock = 0;
	#isPowered = false;
	#isPausedForMotion = false;
	#statementBudget = 0;

	// The power brick gets warm while the C64 is on, and too hot after a while, when the letters on the screen go strange.
	#brick = {temperature: 21, shownTemperature: 21, hasWarnedGlitch: false};

	#loop;

	// The keyboard of the C64 on the screen, with SHIFT, CTRL, and the Commodore key for the next key, and SHIFT LOCK that stays down.
	#modifiers = {shift: false, shiftLock: false, control: false, commodore: false};
	#colorPairIndex = 0;
	#typingOwner;

	connected() {
		const {screen, form, field, power, reset, sound, note, noteFront, noteBack, bang, brick: brickButton} = this.parts;
		this.#context = screen.getContext('2d');
		this.#keyButtons = this.querySelectorAll('[data-c64-key]');
		this.#tapeButtons = this.querySelectorAll('[data-c64-tape]');
		this.#joystickButtons = this.querySelectorAll('[data-c64-joystick]');
		this.#notebookButtons = this.querySelectorAll('[data-c64-type]');
		this.#image = this.#context.createImageData(width, height);
		this.#pixels = new Uint32Array(this.#image.data.buffer);
		this.#savedFiles = this.#loadSavedFiles();
		this.#game.highScore = this.stored('highScore', 0);
		// The loop also runs after the power is off, while the power brick cools down.
		this.#loop = this.loop(seconds => this.#step(seconds), {while: () => this.#isPowered || this.#brick.temperature >= 21.5});

		this.on(screen, 'keydown', event => {
			// The characters of AltGr and Option, like @ on a Norwegian keyboard, type, but the shortcuts of the browser stay the browser’s. While the C64 is off, the keys other than Enter and Space are the page’s.
			const isAltGraph = event.getModifierState('AltGraph');
			// While it is off, Enter and Space turn it on, like a click on the screen.
			if (!this.#isPowered && (event.key === 'Enter' || event.key === ' ')) {
				event.preventDefault();
				this.#powerOn();
				return;
			}

			if (!this.#isPowered || event.metaKey || (event.ctrlKey && !isAltGraph && event.key !== 'Control')) {
				return;
			}

			if ((this.#screenMode === 'game' || this.#screenMode === 'cracktro') && Object.hasOwn(joystickKeys, event.key)) {
				event.preventDefault();
				this.#joystick[joystickKeys[event.key]] = true;
				if (event.key === ' ' && this.#screenMode === 'cracktro') {
					this.#gameKey('space');
				}

				return;
			}

			const key = namedKeys[event.key] ?? characterKey(event.key);
			if (key === undefined) {
				return;
			}

			event.preventDefault();
			this.#pressKey(key, {shift: event.shiftKey && ['clear-home', 'delete', 'return'].includes(key)});
		});

		this.on(screen, 'keyup', event => {
			if (Object.hasOwn(joystickKeys, event.key)) {
				this.#joystick[joystickKeys[event.key]] = false;
			}
		});

		this.on(screen, 'blur', () => {
			this.#releaseJoystick();
		});

		this.on(screen, 'click', () => {
			if (!this.#isPowered) {
				this.#powerOn();
			}
		});

		for (const button of this.#keyButtons) {
			this.on(button, 'click', () => {
				// The typing goes on with the keyboard of the computer, on the screen, not on the key that was clicked.
				screen.focus({preventScroll: true});
				const key = button.dataset.c64Key;
				const modifier = modifierKeys[key];
				if (modifier) {
					this.#modifiers[modifier] = !this.#modifiers[modifier];
					this.#showModifiers();
					return;
				}

				this.#pressKey(key, {shift: this.#modifiers.shift || this.#modifiers.shiftLock, control: this.#modifiers.control, commodore: this.#modifiers.commodore});
				this.#modifiers.shift = false;
				this.#modifiers.control = false;
				this.#modifiers.commodore = false;
				this.#showModifiers();
			});
		}

		// The field types a whole line, for phones, which have no keys for the canvas.
		this.on(form, 'submit', event => {
			event.preventDefault();
			const text = field.value;
			field.value = '';
			// It was off, so the line waits until the C64 says READY.
			if (!this.#isPowered) {
				this.#typeLines([text]);
				return;
			}

			if (this.#screenMode === 'game' || this.#screenMode === 'cracktro') {
				this.say('A game is running. Use the joystick, or Pappa’s reset button to get out.');
				return;
			}

			if (this.#isBusy()) {
				this.say('The C64 is busy. RUN/STOP (Escape) stops it.');
				return;
			}

			for (const character of text) {
				const key = characterKey(character);
				if (key) {
					this.#pressKey(key);
				}
			}

			this.#pressKey('return');
		});

		for (const button of this.#notebookButtons) {
			this.on(button, 'click', async () => {
				const entry = notebook[button.dataset.c64Type];
				let {lines} = entry;
				if (button.dataset.c64Type === 'colors') {
					const [border, background] = colorPairs[this.#colorPairIndex];
					this.#colorPairIndex = (this.#colorPairIndex + 1) % colorPairs.length;
					lines = [`POKE 53280,${border}:POKE 53281,${background}`];
				}

				screen.scrollIntoView({behavior: this.reducedMotion ? 'auto' : 'smooth', block: 'nearest'});
				screen.focus({preventScroll: true});
				if (entry.note) {
					this.say(entry.note);
				}

				// The C64 says “Type RUN” or “Type LIST” while it loads, and the notebook types that after the load, so the note shows again when the typing is done. A game says its own.
				if (await this.#typeLines(lines) && lines.length > 1 && this.#screenMode === 'basic') {
					this.say(entry.note);
				}
			});
		}

		this.on(power, 'click', () => {
			this.#stopTyping();
			if (this.#isPowered) {
				this.#powerOff();
			} else {
				this.#powerOn();
			}
		});

		this.on(reset, 'click', () => {
			if (!this.#isPowered) {
				this.say('Nothing happens. It is off.');
				return;
			}

			this.#stopTyping();
			this.#coldStart();
			this.say('Pappa soldered this button on in 1986. It restarts the C64, also out of a game.');
		});

		this.on(sound, 'click', async () => {
			this.#audio.isOn = !this.#audio.isOn && this.#audio.start(this.sound());
			sound.setAttribute('aria-pressed', String(this.#audio.isOn));
			sound.textContent = this.#audio.isOn ? '🔊 Sound: On' : '🔈 Sound: Off';
			if (!this.#audio.isOn && !this.#audio.context) {
				this.say('This browser has no sound for the TV.');
			}

			if (this.#audio.isOn) {
				this.say('The sound of the TV is on: the drive, the tape, and the SID chip.');

				// The context starts a moment after the click, and then the sounds come in.
				await this.#audio.context.resume();
			}

			this.#updateSounds();
		});

		this.on(note, 'click', () => {
			const isTurned = noteFront.hidden;
			noteFront.hidden = !isTurned;
			noteBack.hidden = isTurned;
			note.setAttribute('aria-expanded', String(!isTurned));
		});

		// Escape turns the note back to its front.
		this.on(note, 'keydown', event => {
			if (event.key === 'Escape' && noteFront.hidden) {
				note.click();
			}
		});

		for (const button of this.#tapeButtons) {
			this.on(button, 'click', () => {
				const control = button.dataset.c64Tape;
				if (!this.#isPowered && control !== 'stop') {
					this.say('The Datassette gets its power from the C64, and it is off.');
					return;
				}

				this.#setTapeMotion(control === 'stop' ? 'stop' : control);
				if (control === 'play' && !this.#operation && this.#screenMode === 'basic') {
					this.say('The tape plays, but nobody listens. Type LOAD first, and then press PLAY.');
				}
			});
		}

		for (const button of this.#joystickButtons) {
			const direction = button.dataset.c64Joystick;
			const release = () => {
				this.#joystick[direction] = false;
			};

			this.on(button, 'pointerdown', event => {
				event.preventDefault();
				button.setPointerCapture(event.pointerId);
				this.#joystick[direction] = true;
				this.#lastActivity = this.#clock;
				if (direction === 'fire' && this.#screenMode === 'cracktro') {
					this.#gameKey('space');
				}
			});
			this.on(button, 'pointerup', release);
			this.on(button, 'pointercancel', release);
			this.on(button, 'lostpointercapture', release);
		}

		this.on(bang, 'click', () => {
			this.#leftFixedUntil = this.#clock + 30;
			this.#tone({frequency: 70, endFrequency: 40, duration: 0.2, volume: 0.25, type: 'triangle'});
			this.#noiseBurst({duration: 0.12, volume: 0.12, filter: 'lowpass', frequency: 500});
			this.#game.hasWarnedLeft = false;
			this.say('BONK! Left works again. For a while.');
		});

		this.on(brickButton, 'click', () => {
			const {temperature} = this.#brick;
			if (temperature < 26) {
				this.say(this.#isPowered ? 'Still cool. It just started.' : 'Cold, like a fjord. The C64 is off.');
			} else if (temperature < 34) {
				this.say('A little warm. Like a cat has been sleeping on it.');
			} else if (temperature < 44) {
				this.say('Warm, like a cup of cocoa. Pappa says that is normal.');
			} else if (temperature < 52) {
				this.say('Hot! Like Mormor’s waffle iron. Pappa says that is normal too.');
			} else {
				this.#brick.temperature -= 14;
				this.#brick.hasWarnedGlitch = false;
				this.say('AU! Too hot to touch! I put it in the open window, and the rain of Bergen cools it down.');
			}
		});

		this.#showCounter();
		this.#render();
	}

	// The sounds that last stop when the C64 is removed, as it is not visible then.
	disconnected() {
		this.#updateSounds();
	}

	// The C64 runs only while its screen is on screen, not while only its keyboard, its devices, or the notebook are.
	get visibilityTarget() {
		return this.parts.screen;
	}

	visibilityChanged() {
		this.#updateSounds();
	}

	musicStopped() {
		this.#stopMusic();
	}

	#fill(x, y, rectangleWidth, rectangleHeight, color) {
		const value = palette[color];
		const startX = Math.max(0, Math.round(x));
		const endX = Math.min(width, Math.round(x + rectangleWidth));
		const startY = Math.max(0, Math.round(y));
		const endY = Math.min(height, Math.round(y + rectangleHeight));
		if (startX >= endX) {
			return;
		}

		for (let row = startY; row < endY; row++) {
			this.#pixels.fill(value, (row * width) + startX, (row * width) + endX);
		}
	}

	#plot(x, y, color) {
		const column = Math.round(x);
		const row = Math.round(y);
		if (column >= 0 && column < width && row >= 0 && row < height) {
			this.#pixels[(row * width) + column] = palette[color];
		}
	}

	// Draws a character in screen code at a pixel of the canvas. The color can be a function of the row of the character, for the logos of the demos.
	#drawCharacter(screenCode, x, y, color, scale = 1) {
		const base = (screenCode & 127) * 8;
		const invert = screenCode & 128 ? 255 : 0;
		for (let row = 0; row < 8; row++) {
			const bits = glyphs[base + row] ^ invert;
			if (bits === 0) {
				continue;
			}

			const rowColor = typeof color === 'function' ? color(row) : color;
			for (let column = 0; column < 8; column++) {
				if (bits & (128 >> column)) {
					if (scale === 1) {
						this.#plot(x + column, y + row, rowColor);
					} else {
						this.#fill(x + (column * scale), y + (row * scale), scale, scale, rowColor);
					}
				}
			}
		}
	}

	#drawText(text, x, y, color, scale = 1) {
		let column = x;
		for (const character of text) {
			const code = petsciiToScreen(character.charCodeAt(0));
			if (code >= 0) {
				this.#drawCharacter(code, column, y, color, scale);
			}

			column += 8 * scale;
		}
	}

	#drawCenteredText(text, y, color, scale = 1) {
		this.#drawText(text, Math.round((width - (text.length * 8 * scale)) / 2), y, color, scale);
	}

	// Fills and plots in the pixels of the C64 inside the border, where the sprites of a game hide when they are outside, like on the real one.
	#fillDisplay(x, y, rectangleWidth, rectangleHeight, color) {
		const startX = clamp(x, 0, 320);
		const startY = clamp(y, 0, 200);
		this.#fill(left + startX, top + startY, clamp(x + rectangleWidth, 0, 320) - startX, clamp(y + rectangleHeight, 0, 200) - startY, color);
	}

	#plotDisplay(x, y, color) {
		const column = Math.round(x);
		const row = Math.round(y);
		if (column >= 0 && column < 320 && row >= 0 && row < 200) {
			this.#pixels[((top + row) * width) + left + column] = palette[color];
		}
	}

	#drawPicture(rows, x, y) {
		for (const [row, line] of rows.entries()) {
			for (let column = 0; column < line.length; column++) {
				const color = pictureColors[line[column]];
				if (color !== undefined) {
					this.#plotDisplay(x + column, y + row, color);
				}
			}
		}
	}

	#textColor() {
		return this.#memory[textColorAddress] & 15;
	}

	#clearScreen() {
		this.#memory.fill(32, screenStart, screenStart + 1000);
		this.#memory.fill(this.#textColor(), colorStart, colorStart + 1000);
		this.#links.fill(false);
		this.#editor.row = 0;
		this.#editor.column = 0;
	}

	#scrollUp() {
		this.#memory.copyWithin(screenStart, screenStart + 40, screenStart + 1000);
		this.#memory.fill(32, screenStart + 960, screenStart + 1000);
		this.#memory.copyWithin(colorStart, colorStart + 40, colorStart + 1000);
		this.#memory.fill(this.#textColor(), colorStart + 960, colorStart + 1000);
		this.#links.shift();
		this.#links.push(false);
		this.#inputStart.row = Math.max(0, this.#inputStart.row - 1);
	}

	#logicalStart(row) {
		let start = row;
		while (start > 0 && this.#links[start]) {
			start--;
		}

		return start;
	}

	#logicalLength(start) {
		return start < 24 && this.#links[start + 1] ? 80 : 40;
	}

	#logicalColumn() {
		return this.#editor.column + (this.#links[this.#editor.row] ? 40 : 0);
	}

	// The cursor goes one to the right. At the end of a row, the next row goes on from it, or starts a new line, if the line already has two rows.
	#advance() {
		this.#editor.column++;
		if (this.#editor.column < 40) {
			return;
		}

		this.#editor.column = 0;
		const continues = !this.#links[this.#editor.row];
		if (this.#editor.row === 24) {
			this.#scrollUp();
		} else {
			this.#editor.row++;
		}

		this.#links[this.#editor.row] = continues;
	}

	#newline() {
		this.#editor.isReverse = false;
		let row = this.#editor.row + 1;
		while (row < 25 && this.#links[row]) {
			row++;
		}

		if (row > 24) {
			this.#scrollUp();
			row = 24;
		}

		this.#editor.row = row;
		this.#editor.column = 0;
		this.#links[row] = false;
	}

	#putScreenCode(code) {
		const index = (this.#editor.row * 40) + this.#editor.column;
		this.#memory[screenStart + index] = code;
		this.#memory[colorStart + index] = this.#textColor();
		this.#advance();
	}

	#cursorDown() {
		if (this.#editor.row === 24) {
			this.#scrollUp();
		} else {
			this.#editor.row++;
		}
	}

	#cursorLeft() {
		if (this.#editor.column > 0) {
			this.#editor.column--;
		} else if (this.#editor.row > 0) {
			this.#editor.row--;
			this.#editor.column = 39;
		}
	}

	#cursorRight() {
		this.#editor.column++;
		if (this.#editor.column === 40) {
			this.#editor.column = 0;
			this.#cursorDown();
		}
	}

	// DEL takes away the character before the cursor and pulls the rest of the line, and INST makes room.
	#deleteCharacter() {
		const start = this.#logicalStart(this.#editor.row);
		const offset = ((this.#editor.row - start) * 40) + this.#editor.column;
		if (offset === 0) {
			return;
		}

		const base = start * 40;
		const length = this.#logicalLength(start);
		this.#memory.copyWithin(screenStart + base + offset - 1, screenStart + base + offset, screenStart + base + length);
		this.#memory.copyWithin(colorStart + base + offset - 1, colorStart + base + offset, colorStart + base + length);
		this.#memory[screenStart + base + length - 1] = 32;
		this.#editor.row = start + Math.floor((offset - 1) / 40);
		this.#editor.column = (offset - 1) % 40;
	}

	#insertCharacter() {
		const start = this.#logicalStart(this.#editor.row);
		const offset = ((this.#editor.row - start) * 40) + this.#editor.column;
		const base = start * 40;
		const length = this.#logicalLength(start);
		this.#memory.copyWithin(screenStart + base + offset + 1, screenStart + base + offset, screenStart + base + length - 1);
		this.#memory.copyWithin(colorStart + base + offset + 1, colorStart + base + offset, colorStart + base + length - 1);
		this.#memory[screenStart + base + offset] = 32;
	}

	// Prints a character in PETSCII, like the KERNAL of the C64: a control code does its job, and the rest goes on the screen.
	#printCode(code) {
		switch (code) {
			case 13:
			case 141: {
				this.#newline();
				return;
			}

			case 147: {
				this.#clearScreen();
				return;
			}

			case 19: {
				this.#editor.row = 0;
				this.#editor.column = 0;
				return;
			}

			case 17: {
				this.#cursorDown();
				return;
			}

			case 145: {
				this.#editor.row = Math.max(0, this.#editor.row - 1);
				return;
			}

			case 29: {
				this.#cursorRight();
				return;
			}

			case 157: {
				this.#cursorLeft();
				return;
			}

			case 18: {
				this.#editor.isReverse = true;
				return;
			}

			case 146: {
				this.#editor.isReverse = false;
				return;
			}

			case 20: {
				this.#deleteCharacter();
				return;
			}

			case 148: {
				this.#insertCharacter();
				return;
			}

			default: {
				break;
			}
		}

		if (colorCodes.has(code)) {
			this.#memory[textColorAddress] = colorCodes.get(code);
			return;
		}

		const screenCode = petsciiToScreen(code);
		if (screenCode >= 0) {
			this.#putScreenCode(screenCode | (this.#editor.isReverse ? 128 : 0));
		}
	}

	// Prints text, and keeps what is printed for screen readers.
	#printText(text) {
		for (const character of text) {
			const code = character.charCodeAt(0);
			this.#printCode(code);
			if (code >= 32 && code < 96) {
				this.#outputLog = (this.#outputLog + character).slice(-300);
			} else if (code === 13) {
				this.#outputLog += ' ';
			}
		}
	}

	// Reads the line that RETURN enters from the screen, from where it starts, with the control codes in quotes turned back into codes.
	#readLine(start, offset = 0) {
		const length = this.#logicalLength(start);
		let text = '';
		let isInQuotes = false;
		for (let index = 0; index < length; index++) {
			const code = this.#memory[screenStart + (start * 40) + index];
			const base = code & 127;
			let petscii;
			if (isInQuotes && (code & 128) && (base < 32 || (base >= 64 && base < 96))) {
				petscii = base < 32 ? base : base + 64;
			} else {
				petscii = screenToPetscii(code);
			}

			if (petscii === 34) {
				isInQuotes = !isInQuotes;
			}

			if (index >= offset) {
				text += String.fromCharCode(petscii);
			}
		}

		let end = text.length;
		while (end > 0 && text[end - 1] === ' ') {
			end--;
		}

		return text.slice(0, end);
	}

	// After an odd number of quotes, the colors and the clear screen are typed into the line, like the quote mode of the C64.
	#isQuoteMode() {
		const start = this.#logicalStart(this.#editor.row);
		const offset = ((this.#editor.row - start) * 40) + this.#editor.column;
		let quotes = 0;
		for (let index = 0; index < offset; index++) {
			if ((this.#memory[screenStart + (start * 40) + index] & 127) === 34) {
				quotes++;
			}
		}

		return quotes % 2 === 1;
	}

	#pulseWave(duty) {
		if (!this.#pulseWaves.has(duty)) {
			const count = 48;
			const real = new Float32Array(count);
			const imaginary = new Float32Array(count);
			for (let harmonic = 1; harmonic < count; harmonic++) {
				real[harmonic] = (2 / (harmonic * Math.PI)) * Math.sin(harmonic * Math.PI * duty);
			}

			this.#pulseWaves.set(duty, new PeriodicWave(this.#audio.context, {real, imag: imaginary}));
		}

		return this.#pulseWaves.get(duty);
	}

	#makeOscillator(frequency, {type = 'square', duty} = {}) {
		return duty === undefined
			? new OscillatorNode(this.#audio.context, {type, frequency})
			: new OscillatorNode(this.#audio.context, {periodicWave: this.#pulseWave(duty), frequency});
	}

	// A short tone, which can slide to another frequency.
	#tone({frequency, endFrequency, duration, volume = 0.06, when = 0, type, duty, destination}) {
		if (!this.#audio.isReady) {
			return;
		}

		const start = this.#audio.context.currentTime + when;
		const oscillator = this.#makeOscillator(frequency, {type, duty});
		if (endFrequency) {
			oscillator.frequency.setValueAtTime(frequency, start);
			oscillator.frequency.exponentialRampToValueAtTime(endFrequency, start + duration);
		}

		const gain = new GainNode(this.#audio.context, {gain: 0});
		gain.gain.setValueAtTime(0, start);
		gain.gain.linearRampToValueAtTime(volume, start + 0.005);
		gain.gain.exponentialRampToValueAtTime(0.0001, start + duration);
		oscillator.connect(gain).connect(destination ?? this.#audio.output);
		oscillator.start(start);
		oscillator.stop(start + duration + 0.02);
	}

	// A short burst of noise, for the drums, the shots, and the knocks of the drive.
	#noiseBurst({duration, volume = 0.08, when = 0, filter = 'highpass', frequency = 1000, destination}) {
		if (!this.#audio.isReady) {
			return;
		}

		const start = this.#audio.context.currentTime + when;
		const source = new AudioBufferSourceNode(this.#audio.context, {buffer: this.#audio.noise()});
		const shape = new BiquadFilterNode(this.#audio.context, {type: filter, frequency});
		const gain = new GainNode(this.#audio.context, {gain: volume});
		gain.gain.setValueAtTime(volume, start);
		gain.gain.exponentialRampToValueAtTime(0.0001, start + duration);
		source.connect(shape).connect(gain).connect(destination ?? this.#audio.output);
		source.start(start, Math.random() * 0.5);
		source.stop(start + duration + 0.02);
	}

	#playVoice(destination, frequency, time, duration, {duty, volume, hasVibrato = false}) {
		const oscillator = this.#makeOscillator(frequency, {duty});
		const gain = new GainNode(this.#audio.context, {gain: 0});
		gain.gain.setValueAtTime(0, time);
		gain.gain.linearRampToValueAtTime(volume, time + 0.006);
		gain.gain.setTargetAtTime(volume * 0.7, time + 0.006, 0.05);
		gain.gain.setValueAtTime(volume * 0.7, time + Math.max(0.02, duration - 0.04));
		gain.gain.linearRampToValueAtTime(0, time + duration);

		// The vibrato of the SID tunes, which starts a moment into a long note.
		if (hasVibrato) {
			const vibrato = new OscillatorNode(this.#audio.context, {frequency: 6});
			const depth = new GainNode(this.#audio.context, {gain: 0});
			depth.gain.setValueAtTime(0, time);
			depth.gain.setValueAtTime(frequency * 0.012, time + 0.18);
			vibrato.connect(depth).connect(oscillator.frequency);
			vibrato.start(time);
			vibrato.stop(time + duration + 0.02);
		}

		oscillator.connect(gain).connect(destination);
		oscillator.start(time);
		oscillator.stop(time + duration + 0.02);
	}

	#playArpeggio(destination, notes, time, duration) {
		const oscillator = this.#makeOscillator(frequencyOf(notes[0]), {duty: 0.5});
		for (let index = 0; index * 0.02 < duration; index++) {
			oscillator.frequency.setValueAtTime(frequencyOf(notes[index % notes.length]), time + (index * 0.02));
		}

		const gain = new GainNode(this.#audio.context, {gain: 0.03});
		gain.gain.setValueAtTime(0.03, time + duration - 0.01);
		gain.gain.linearRampToValueAtTime(0, time + duration);
		oscillator.connect(gain).connect(destination);
		oscillator.start(time);
		oscillator.stop(time + duration + 0.02);
	}

	#playDrum(destination, drum, time) {
		const when = time - this.#audio.context.currentTime;
		if (drum === 'k') {
			this.#tone({frequency: 170, endFrequency: 40, duration: 0.12, volume: 0.22, when, type: 'triangle', destination});
		} else if (drum === 's') {
			this.#noiseBurst({duration: 0.13, volume: 0.12, when, filter: 'bandpass', frequency: 1800, destination});
			this.#tone({frequency: 220, endFrequency: 120, duration: 0.05, volume: 0.06, when, type: 'triangle', destination});
		} else {
			this.#noiseBurst({duration: 0.04, volume: 0.05, when, filter: 'highpass', frequency: 7000, destination});
		}
	}

	#stopMusic() {
		if (!this.#tune) {
			return;
		}

		const current = this.#tune;
		this.#tune = undefined;
		clearInterval(current.interval);
		current.master.gain.setTargetAtTime(0, this.#audio.context.currentTime, 0.02);
		setTimeout(() => {
			current.master.disconnect();
		}, 300);

		// The page hears that the music stopped, like the screen saver, which waits while music plays.
		this.music(false);
	}

	// Plays a song in a loop. The notes are scheduled a little ahead, so the timers of the browser can be late without a hiccup.
	#playSong(song) {
		this.#stopMusic();
		if (!this.#audio.isReady || !this.isVisible) {
			return;
		}

		// One tune plays at a time on the page, so the other music stops when the C64 plays.
		this.music(true);

		const master = new GainNode(this.#audio.context, {gain: 0.5});
		master.connect(this.#audio.output);
		let patternIndex = 0;
		let row = 0;
		let nextTime = this.#audio.context.currentTime + 0.06;

		const schedule = () => {
			// After a late timer, the music goes on from now, instead of playing all the missed notes at once.
			nextTime = Math.max(nextTime, this.#audio.context.currentTime);
			while (nextTime < this.#audio.context.currentTime + 0.2) {
				const {chord, lead, bass, drums} = song.patterns[patternIndex];
				if (isNote(lead[row])) {
					const duration = noteRows(lead, row) * song.rowDuration;
					this.#playVoice(master, frequencyOf(lead[row]), nextTime, duration, {duty: 0.25, volume: 0.07, hasVibrato: duration > 0.3});
				}

				if (isNote(bass[row])) {
					this.#playVoice(master, frequencyOf(bass[row]), nextTime, song.rowDuration * 0.9, {duty: 0.5, volume: 0.09});
				}

				if (drums[row] === '.') {
					this.#playArpeggio(master, chords[chord], nextTime, song.rowDuration);
				} else {
					this.#playDrum(master, drums[row], nextTime);
				}

				row++;
				if (row === 16) {
					row = 0;
					patternIndex = (patternIndex + 1) % song.patterns.length;
				}

				nextTime += song.rowDuration;
			}
		};

		schedule();
		this.#tune = {master, interval: setInterval(schedule, 40)};
	}

	#sidVolume() {
		return ((this.#memory[sidStart + 24] & 15) / 15) * 0.12;
	}

	#sidFrequency(base) {
		return Math.max(1, (this.#memory[base] + (this.#memory[base + 1] * 256)) * 0.0596);
	}

	#writeSid(address) {
		const offset = address - sidStart;
		if (offset === 24) {
			this.#sidMaster?.gain.setTargetAtTime(this.#sidVolume(), this.#audio.context.currentTime, 0.01);
			return;
		}

		const index = Math.floor(offset / 7);
		if (index > 2) {
			return;
		}

		const register = offset % 7;
		if (register <= 1) {
			this.#sidVoices[index]?.setFrequency(this.#sidFrequency(sidStart + (index * 7)));
		}

		if (register === 4) {
			this.#updateSidVoice(index);
		}
	}

	// A voice plays while its gate bit is on, and while the sound is on and the C64 is on the screen. So a program that started a note before the sound was turned on, or before the C64 scrolled away, is heard again.
	#updateSidVoice(index) {
		const base = sidStart + (index * 7);
		const shouldPlay = this.#audio.isReady && this.isVisible && (this.#memory[base + 4] & 1) === 1;
		const voice = this.#sidVoices[index];
		if (shouldPlay && !voice) {
			if (!this.#sidMaster) {
				this.#sidMaster = new GainNode(this.#audio.context, {gain: this.#sidVolume()});
				this.#sidMaster.connect(this.#audio.output);
			}

			this.#sidVoices[index] = this.#startSidVoice(base, this.#sidFrequency(base));
		} else if (!shouldPlay && voice) {
			voice.release();
			this.#sidVoices[index] = undefined;
		}
	}

	#syncSid() {
		for (const index of this.#sidVoices.keys()) {
			this.#updateSidVoice(index);
		}
	}

	#startSidVoice(base, frequency) {
		const now = this.#audio.context.currentTime;
		const control = this.#memory[base + 4];
		const attack = attackTimes[this.#memory[base + 5] >> 4];
		const decay = attackTimes[this.#memory[base + 5] & 15] * 3;
		const sustain = (this.#memory[base + 6] >> 4) / 15;
		// The release is at most two seconds, so a program that plays many notes does not pile them up.
		const release = Math.min(2, attackTimes[this.#memory[base + 6] & 15] * 3);
		let source;
		let setFrequency;
		if (control & 128) {
			source = new AudioBufferSourceNode(this.#audio.context, {buffer: this.#audio.noise(), loop: true, playbackRate: clamp(frequency / 1000, 0.05, 4)});
			setFrequency = value => {
				source.playbackRate.setValueAtTime(clamp(value / 1000, 0.05, 4), this.#audio.context.currentTime);
			};
		} else {
			const type = control & 16 ? 'triangle' : (control & 32 ? 'sawtooth' : 'square');
			source = new OscillatorNode(this.#audio.context, {type, frequency});
			setFrequency = value => {
				source.frequency.setValueAtTime(value, this.#audio.context.currentTime);
			};
		}

		const gain = new GainNode(this.#audio.context, {gain: 0});
		gain.gain.setValueAtTime(0, now);
		gain.gain.linearRampToValueAtTime(1, now + attack);
		gain.gain.setTargetAtTime(sustain, now + attack, decay / 3);
		source.connect(gain).connect(this.#sidMaster);
		source.start(now);
		return {
			setFrequency,
			release: () => {
				const time = this.#audio.context.currentTime;
				gain.gain.cancelScheduledValues(time);
				gain.gain.setTargetAtTime(0, time, release / 3);
				source.stop(time + release + 0.1);
			},
		};
	}

	// The end of a program turns its notes off, so they do not play on.
	#silenceSid() {
		for (const index of this.#sidVoices.keys()) {
			this.#memory[sidStart + (index * 7) + 4] &= 254;
		}

		this.#syncSid();
	}

	// The motor hums while the drive works, and while the sound is on and the C64 is on the screen.
	#updateDriveHum() {
		const shouldHum = this.#drive.isActive && this.#audio.isReady && this.isVisible;
		if (shouldHum && !this.#drive.hum) {
			const source = new AudioBufferSourceNode(this.#audio.context, {buffer: this.#audio.noise(), loop: true});
			const shape = new BiquadFilterNode(this.#audio.context, {type: 'lowpass', frequency: 260});
			const gain = new GainNode(this.#audio.context, {gain: 0.09});
			source.connect(shape).connect(gain).connect(this.#audio.output);
			source.start();
			this.#drive.hum = source;
		} else if (!shouldHum && this.#drive.hum) {
			this.#drive.hum.stop();
			this.#drive.hum = undefined;
		}
	}

	#startDrive() {
		this.#drive.isActive = true;
		this.parts.driveLight.dataset.state = 'on';
		this.#updateDriveHum();
	}

	#stopDrive() {
		this.#drive.isActive = false;
		this.parts.driveLight.dataset.state = '';
		this.#updateDriveHum();
	}

	#updateDrive() {
		if (this.#drive.isActive && this.#audio.isReady && this.#clock >= this.#drive.nextClick) {
			this.#tone({frequency: 50 + (Math.random() * 50), duration: 0.035, volume: 0.09, type: 'square'});
			this.#drive.nextClick = this.#clock + 0.07 + (Math.random() * 0.22);
		}

		// The light blinks after an error, like the real one.
		if (!this.#drive.isActive && this.#drive.blinkUntil > 0) {
			const isOn = this.#clock < this.#drive.blinkUntil && (this.reducedMotion || Math.floor(this.#clock * 4) % 2 === 0);
			this.parts.driveLight.dataset.state = isOn ? 'on' : '';
			if (this.#clock >= this.#drive.blinkUntil) {
				this.#drive.blinkUntil = 0;
			}
		}
	}

	// The famous knocking of the 1541, when the head bangs against its stop because it cannot find something.
	#knockHead() {
		for (let index = 0; index < 14; index++) {
			this.#tone({frequency: 95, duration: 0.03, volume: 0.16, when: index * 0.065, type: 'square'});
		}
	}

	#showCounter() {
		this.parts.counter.textContent = String(Math.floor(this.#tape.position)).padStart(3, '0');
	}

	#updateTapeSound() {
		const isPlaying = this.#audio.isReady && this.isVisible && (this.#tape.motion === 'play' || this.#tape.motion === 'record');
		if (isPlaying && !this.#tape.sound) {
			this.#tape.sound = new OscillatorNode(this.#audio.context, {type: 'square', frequency: 1800});
			this.#tape.gain = new GainNode(this.#audio.context, {gain: 0});
			this.#tape.sound.connect(this.#tape.gain).connect(this.#audio.output);
			this.#tape.sound.start();
		} else if (!isPlaying && this.#tape.sound) {
			this.#tape.sound.stop();
			this.#tape.sound = undefined;
			this.#tape.gain = undefined;
		}
	}

	#setTapeMotion(motion) {
		this.#tape.motion = motion;
		for (const button of this.#tapeButtons) {
			const control = button.dataset.c64Tape;
			if (control !== 'stop') {
				setPressed(button, control === motion || (motion === 'record' && control === 'play'));
			}
		}

		this.#updateTapeSound();
	}

	#updateTape(seconds) {
		const speed = tapeSpeeds[this.#tape.motion] ?? 0;
		if (speed !== 0) {
			const previous = this.#tape.position;
			this.#tape.position = clamp(this.#tape.position + (speed * seconds), 0, tapeLength);
			if (this.#tape.motion === 'play' && previous < tapeHeader && this.#tape.position >= tapeHeader) {
				this.#tape.crossings++;
			}

			this.#showCounter();

			// The tape stops at the end it runs to, so PLAY at 000 goes on.
			if (this.#tape.position === (speed > 0 ? tapeLength : 0)) {
				if (speed > 0 && this.#operation?.isTape) {
					this.say('The end of the tape, and no game. Press RUN/STOP (Escape), rewind ◀◀ to 000, and LOAD again.');
				}

				this.#setTapeMotion('stop');
			}
		}

		// The data on the tape screeches, and the empty tape only hisses.
		if (this.#tape.sound) {
			const isOnData = this.#tape.position < tapeGameEnd;
			this.#tape.sound.frequency.setValueAtTime(isOnData ? [1100, 1500, 2100, 2700][Math.floor(Math.random() * 4)] : 60, this.#audio.context.currentTime);
			this.#tape.gain.gain.setValueAtTime(isOnData ? 0.022 : 0.004, this.#audio.context.currentTime);
		}
	}

	#clearVariables() {
		this.#variables = new Map();
		this.#arrays = new Map();
		this.#functions = new Map();
		this.#stack = [];
		this.#dataItems = undefined;
		this.#dataIndex = 0;
	}

	#currentLineNumber() {
		return this.#lineIndex >= 0 ? this.#program[this.#lineIndex]?.number : undefined;
	}

	#goToIndex(index) {
		this.#lineIndex = index;
		const line = this.#program[index];
		line.tokens ??= tokenize(line.text);
		this.#tokens = line.tokens;
		this.#position = 0;
		this.#isJumping = true;
	}

	#goToLine(number) {
		const index = this.#program.findIndex(line => line.number === number);
		if (index === -1) {
			fail('UNDEF\'D STATEMENT');
		}

		this.#goToIndex(index);
	}

	#pointer() {
		return {lineIndex: this.#lineIndex, tokens: this.#tokens, position: this.#position};
	}

	#restorePointer(saved) {
		this.#lineIndex = saved.lineIndex;
		this.#tokens = saved.tokens;
		this.#position = saved.position;
		this.#isJumping = true;
	}

	#storeLine(number, text) {
		const index = this.#program.findIndex(line => line.number >= number);
		const line = {number, text, tokens: undefined};
		if (index === -1) {
			if (text) {
				this.#program.push(line);
			}
		} else if (this.#program[index].number === number) {
			if (text) {
				this.#program[index] = line;
			} else {
				this.#program.splice(index, 1);
			}
		} else if (text) {
			this.#program.splice(index, 0, line);
		}

		// A new line goes where a loaded game was in the memory, and the variables are cleared, like on the C64.
		this.#clearVariables();
		this.#continuePoint = undefined;
		this.#gameInMemory = undefined;
	}

	#installProgram(lines) {
		this.#program.length = 0;
		for (const [number, text] of lines) {
			this.#program.push({number, text, tokens: undefined});
		}

		this.#clearVariables();
		this.#continuePoint = undefined;
	}

	#isStatementEnd() {
		return this.#position >= this.#tokens.length || isSymbol(this.#tokens[this.#position], ':');
	}

	#expectSymbol(value) {
		if (!isSymbol(this.#tokens[this.#position], value)) {
			fail('SYNTAX');
		}

		this.#position++;
	}

	#expectKeyword(value) {
		if (!isKeyword(this.#tokens[this.#position], value)) {
			fail('SYNTAX');
		}

		this.#position++;
	}

	#readLineNumber() {
		const token = this.#tokens[this.#position];
		if (token?.type !== 'number') {
			fail('SYNTAX');
		}

		this.#position++;
		return token.value;
	}

	// TI is the clock in sixtieths of a second, TI$ the time as HHMMSS, and ST the status of the last device.
	#getVariable(key) {
		if (key === 'TI') {
			return Math.floor(this.#jiffies + this.#clockOffset) % 5_184_000;
		}

		if (key === 'TI$') {
			const seconds = Math.floor((this.#jiffies + this.#clockOffset) / 60) % 86_400;
			return [Math.floor(seconds / 3600), Math.floor(seconds / 60) % 60, seconds % 60].map(part => String(part).padStart(2, '0')).join('');
		}

		if (key === 'ST') {
			return 0;
		}

		return this.#variables.get(key) ?? (isStringKey(key) ? '' : 0);
	}

	#setVariable(key, value) {
		if (key === 'TI' || key === 'ST') {
			fail('SYNTAX');
		}

		if (key === 'TI$') {
			if (typeof value !== 'string' || !/^\d{6}$/.test(value)) {
				fail('ILLEGAL QUANTITY');
			}

			const seconds = (Number(value.slice(0, 2)) * 3600) + (Number(value.slice(2, 4)) * 60) + Number(value.slice(4));
			this.#clockOffset = (seconds * 60) - this.#jiffies;
			return;
		}

		this.#variables.set(key, coerce(key, value));
	}

	#createArray(key, sizes) {
		let count = 1;
		for (const size of sizes) {
			count *= size + 1;
		}

		if (count > 20_000) {
			fail('OUT OF MEMORY');
		}

		const array = {sizes, values: Array.from({length: count}, () => (isStringKey(key) ? '' : 0))};
		this.#arrays.set(key, array);
		return array;
	}

	#arrayOffset(key, indexes) {
		const array = this.#arrays.get(key) ?? this.#createArray(key, indexes.map(() => 10));
		if (array.sizes.length !== indexes.length) {
			fail('BAD SUBSCRIPT');
		}

		let offset = 0;
		for (const [dimension, index] of indexes.entries()) {
			if (index > array.sizes[dimension]) {
				fail('BAD SUBSCRIPT');
			}

			offset = (offset * (array.sizes[dimension] + 1)) + index;
		}

		return {array, offset};
	}

	// A variable or an element of an array, which a statement reads or sets.
	#parseReference() {
		const token = this.#tokens[this.#position];
		if (token?.type !== 'name') {
			fail('SYNTAX');
		}

		this.#position++;
		const key = variableKey(token.value);
		if (!isSymbol(this.#tokens[this.#position], '(')) {
			return {key};
		}

		this.#position++;
		const indexes = [toInteger(this.#evaluateNumber(), 0, 32767)];
		while (isSymbol(this.#tokens[this.#position], ',')) {
			this.#position++;
			indexes.push(toInteger(this.#evaluateNumber(), 0, 32767));
		}

		this.#expectSymbol(')');
		return {key, indexes};
	}

	#readReference(reference) {
		if (!reference.indexes) {
			return this.#getVariable(reference.key);
		}

		const {array, offset} = this.#arrayOffset(reference.key, reference.indexes);
		return array.values[offset];
	}

	#writeReference(reference, value) {
		if (!reference.indexes) {
			this.#setVariable(reference.key, value);
			return;
		}

		const {array, offset} = this.#arrayOffset(reference.key, reference.indexes);
		array.values[offset] = coerce(reference.key, value);
	}

	#evaluateNumber() {
		return checkNumber(this.#evaluate());
	}

	#evaluateString() {
		const value = this.#evaluate();
		if (typeof value !== 'string') {
			fail('TYPE MISMATCH');
		}

		return value;
	}

	#parseOr() {
		let value = this.#parseAnd();
		while (isKeyword(this.#tokens[this.#position], 'OR')) {
			this.#position++;
			value = toWord(checkNumber(value)) | toWord(checkNumber(this.#parseAnd()));
		}

		return value;
	}

	#evaluate() {
		return this.#parseOr();
	}

	#parseAnd() {
		let value = this.#parseNot();
		while (isKeyword(this.#tokens[this.#position], 'AND')) {
			this.#position++;
			value = toWord(checkNumber(value)) & toWord(checkNumber(this.#parseNot()));
		}

		return value;
	}

	#parseNot() {
		if (isKeyword(this.#tokens[this.#position], 'NOT')) {
			this.#position++;
			return ~toWord(checkNumber(this.#parseNot()));
		}

		return this.#parseComparison();
	}

	#parseComparison() {
		let value = this.#parseSum();
		while (isComparisonSymbol(this.#tokens[this.#position])) {
			let operator = this.#tokens[this.#position].value;
			this.#position++;
			if (isComparisonSymbol(this.#tokens[this.#position]) && this.#tokens[this.#position].value !== operator) {
				operator += this.#tokens[this.#position].value;
				this.#position++;
			}

			const right = this.#parseSum();
			if (typeof value !== typeof right) {
				fail('TYPE MISMATCH');
			}

			const isLess = value < right;
			const isEqual = value === right;
			const results = {'<': isLess, '>': !isLess && !isEqual, '=': isEqual, '<>': !isEqual, '><': !isEqual, '<=': isLess || isEqual, '=<': isLess || isEqual, '>=': !isLess, '=>': !isLess};
			value = results[operator] ? -1 : 0;
		}

		return value;
	}

	#parseSum() {
		let value = this.#parseProduct();
		while (isSymbol(this.#tokens[this.#position], '+') || isSymbol(this.#tokens[this.#position], '-')) {
			const operator = this.#tokens[this.#position].value;
			this.#position++;
			const right = this.#parseProduct();
			if (operator === '+' && typeof value === 'string' && typeof right === 'string') {
				value += right;
				if (value.length > 255) {
					fail('STRING TOO LONG');
				}

				continue;
			}

			value = checkNumber(operator === '+' ? checkNumber(value) + checkNumber(right) : checkNumber(value) - checkNumber(right));
		}

		return value;
	}

	#parseProduct() {
		let value = this.#parseSign();
		while (isSymbol(this.#tokens[this.#position], '*') || isSymbol(this.#tokens[this.#position], '/')) {
			const operator = this.#tokens[this.#position].value;
			this.#position++;
			const right = checkNumber(this.#parseSign());
			if (operator === '/' && right === 0) {
				fail('DIVISION BY ZERO');
			}

			value = checkNumber(operator === '*' ? checkNumber(value) * right : checkNumber(value) / right);
		}

		return value;
	}

	#parseSign() {
		if (isSymbol(this.#tokens[this.#position], '-')) {
			this.#position++;
			return -checkNumber(this.#parseSign());
		}

		if (isSymbol(this.#tokens[this.#position], '+')) {
			this.#position++;
			return this.#parseSign();
		}

		return this.#parsePower();
	}

	#parsePower() {
		let value = this.#parsePrimary();
		while (isSymbol(this.#tokens[this.#position], '^')) {
			this.#position++;
			let isNegative = false;
			if (isSymbol(this.#tokens[this.#position], '-')) {
				this.#position++;
				isNegative = true;
			}

			const exponent = checkNumber(this.#parsePrimary());
			value = checkNumber(checkNumber(value) ** (isNegative ? -exponent : exponent));
		}

		return value;
	}

	#nextRandom() {
		this.#randomState = (this.#randomState * 16_807) % 2_147_483_647;
		return (this.#randomState - 1) / 2_147_483_646;
	}

	#random(argument) {
		if (argument < 0) {
			this.#randomState = (Math.floor(Math.abs(argument) * 1000) % 2_147_483_646) + 1;
		}

		if (argument !== 0) {
			this.#lastRandom = this.#nextRandom();
		}

		return this.#lastRandom;
	}

	#numberArgument() {
		this.#expectSymbol('(');
		const value = this.#evaluateNumber();
		this.#expectSymbol(')');
		return value;
	}

	#stringArgument() {
		this.#expectSymbol('(');
		const value = this.#evaluateString();
		this.#expectSymbol(')');
		return value;
	}

	// The memory that is free for BASIC. FRE counts with numbers up to 32767, so on a C64 it says a negative number.
	#freeMemory() {
		let used = 0;
		for (const line of this.#program) {
			used += line.text.length + 5;
		}

		const free = Math.max(0, 38_909 - used - (this.#variables.size * 7));
		return free > 32_767 ? free - 65_536 : free;
	}

	#callFunction(name) {
		switch (name) {
			case 'SGN': {
				return Math.sign(this.#numberArgument());
			}

			case 'INT': {
				return Math.floor(this.#numberArgument());
			}

			case 'ABS': {
				return Math.abs(this.#numberArgument());
			}

			case 'SQR': {
				const value = this.#numberArgument();
				if (value < 0) {
					fail('ILLEGAL QUANTITY');
				}

				return Math.sqrt(value);
			}

			case 'RND': {
				return this.#random(this.#numberArgument());
			}

			case 'LOG': {
				const value = this.#numberArgument();
				if (value <= 0) {
					fail('ILLEGAL QUANTITY');
				}

				return Math.log(value);
			}

			case 'EXP': {
				return checkNumber(Math.exp(this.#numberArgument()));
			}

			case 'COS': {
				return Math.cos(this.#numberArgument());
			}

			case 'SIN': {
				return Math.sin(this.#numberArgument());
			}

			case 'TAN': {
				return Math.tan(this.#numberArgument());
			}

			case 'ATN': {
				return Math.atan(this.#numberArgument());
			}

			case 'PEEK': {
				return this.#peekMemory(toAddress(this.#numberArgument()));
			}

			case 'FRE': {
				this.#expectSymbol('(');
				this.#evaluate();
				this.#expectSymbol(')');
				const free = this.#freeMemory();
				if (free < 0) {
					this.say(`${free} bytes free? The C64 counts with numbers up to 32767, and then it gets confused. ${free + 65_536} bytes are free, really.`);
				}

				return free;
			}

			case 'POS': {
				this.#expectSymbol('(');
				this.#evaluate();
				this.#expectSymbol(')');
				return this.#editor.column;
			}

			case 'USR': {
				this.#numberArgument();
				return fail('ILLEGAL QUANTITY');
			}

			case 'LEN': {
				return this.#stringArgument().length;
			}

			case 'STR$': {
				return formatNumber(this.#numberArgument());
			}

			case 'VAL': {
				const text = this.#stringArgument().trim();
				const match = /^[+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:E[+-]?\d+)?/.exec(text);
				return match ? checkNumber(Number(match[0])) : 0;
			}

			case 'ASC': {
				const text = this.#stringArgument();
				if (text === '') {
					fail('ILLEGAL QUANTITY');
				}

				return text.charCodeAt(0);
			}

			case 'CHR$': {
				return String.fromCharCode(toByte(this.#numberArgument()));
			}

			case 'LEFT$':
			case 'RIGHT$': {
				this.#expectSymbol('(');
				const text = this.#evaluateString();
				this.#expectSymbol(',');
				const count = toByte(this.#evaluateNumber());
				this.#expectSymbol(')');
				return name === 'LEFT$' ? text.slice(0, count) : text.slice(Math.max(0, text.length - count));
			}

			case 'MID$': {
				this.#expectSymbol('(');
				const text = this.#evaluateString();
				this.#expectSymbol(',');
				const start = toByte(this.#evaluateNumber());
				let count = 255;
				if (isSymbol(this.#tokens[this.#position], ',')) {
					this.#position++;
					count = toByte(this.#evaluateNumber());
				}

				this.#expectSymbol(')');
				if (start < 1) {
					fail('ILLEGAL QUANTITY');
				}

				return text.slice(start - 1, start - 1 + count);
			}

			case 'FN': {
				const nameToken = this.#tokens[this.#position];
				if (nameToken?.type !== 'name') {
					fail('SYNTAX');
				}

				this.#position++;
				const definition = this.#functions.get(variableKey(nameToken.value));
				if (!definition) {
					fail('UNDEF\'D FUNCTION');
				}

				const argument = this.#numberArgument();
				const savedTokens = this.#tokens;
				const savedPosition = this.#position;
				const hadParameter = this.#variables.has(definition.parameter);
				const oldValue = this.#variables.get(definition.parameter);
				this.#variables.set(definition.parameter, argument);
				this.#tokens = definition.tokens;
				this.#position = definition.position;
				try {
					return this.#evaluate();
				} finally {
					this.#tokens = savedTokens;
					this.#position = savedPosition;
					if (hadParameter) {
						this.#variables.set(definition.parameter, oldValue);
					} else {
						this.#variables.delete(definition.parameter);
					}
				}
			}

			case 'NOT': {
				return ~toWord(checkNumber(this.#parseNot()));
			}

			default: {
				return fail('SYNTAX');
			}
		}
	}

	#parsePrimary() {
		const token = this.#tokens[this.#position];
		if (!token) {
			return fail('SYNTAX');
		}

		if (token.type === 'number' || token.type === 'string') {
			this.#position++;
			return token.type === 'number' ? checkNumber(token.value) : token.value;
		}

		if (token.type === 'name') {
			return this.#readReference(this.#parseReference());
		}

		if (token.type === 'keyword') {
			this.#position++;
			return this.#callFunction(token.value);
		}

		if (isSymbol(token, '(')) {
			this.#position++;
			const value = this.#evaluate();
			this.#expectSymbol(')');
			return value;
		}

		// π, which is SHIFT and ↑ on the C64. On the screen it has the code of SHIFT and ↑ in the second set, 222.
		if (isSymbol(token, 'ÿ') || isSymbol(token, 'Þ')) {
			this.#position++;
			return Math.PI;
		}

		return fail('SYNTAX');
	}

	#isFiring() {
		return this.#joystick.fire || this.#clock < this.#fireTapUntil;
	}

	// The joystick is broken to the left: it only works now and then, until it is banged on the table.
	#isLeftWorking() {
		return this.#joystick.left && (this.#clock < this.#leftFixedUntil || Math.floor(this.#clock * 6) % 3 !== 0);
	}

	// PEEK and POKE, with the chips that answer at their addresses: the joystick, the keyboard, the clock, the raster line, and the colors, which read with the upper bits on, so PEEK(53280) is 254.
	#peekMemory(address) {
		if (address === 56_320) {
			return 127 - (this.#joystick.up ? 1 : 0) - (this.#joystick.down ? 2 : 0) - (this.#isLeftWorking() ? 4 : 0) - (this.#joystick.right ? 8 : 0) - (this.#isFiring() ? 16 : 0);
		}

		if (address === 53_266) {
			return Math.floor(Math.random() * 256);
		}

		if (address >= borderRegister && address <= 53_294) {
			return this.#memory[address] | 240;
		}

		if (address === 160 || address === 161 || address === 162) {
			return Math.floor((this.#jiffies + this.#clockOffset) / (256 ** (162 - address))) & 255;
		}

		if (address === keyCountAddress) {
			return this.#keyboardBuffer.length;
		}

		return this.#memory[address];
	}

	#pokeMemory(address, value) {
		this.#memory[address] = value;
		if (address >= sidStart && address <= sidStart + 24) {
			this.#writeSid(address);
		}

		if (this.#lineIndex < 0 && (address === borderRegister || address === backgroundRegister)) {
			this.say(`The ${address === borderRegister ? 'border' : 'background'} is ${colorNames[value & 15]} now. The C64 has 16 colors, 0 to 15. RESTORE makes them normal again.`);
		}
	}

	// RUN/STOP and RESTORE together: the program stops, and the screen and its colors are like after the start.
	#warmStart() {
		this.#isRunning = false;
		this.#waiting = undefined;
		this.#silenceSid();
		this.#memory[53_269] = 0;
		this.#memory[borderRegister] = colors.lightBlue;
		this.#memory[backgroundRegister] = colors.blue;
		this.#memory[textColorAddress] = colors.lightBlue;
		this.#screenMode = 'basic';
		this.#clearScreen();
		this.#printText('READY.');
		this.#newline();
	}

	#sys(address) {
		if (address === 64_738) {
			this.#isRunning = false;
			this.#coldStart();
			this.say('SYS 64738 jumps to the start of the computer: a reset, without the power switch.');
			return;
		}

		if ((address === 2061 || address === 2064) && this.#gameInMemory) {
			this.#isRunning = false;
			this.#startGame(this.#gameInMemory === 'tape');
			return;
		}

		// Where there is no program, the C64 finds a BRK, which stops like RUN/STOP and RESTORE.
		if (address < 40_960 && this.#memory[address] === 0) {
			this.#warmStart();
		}
	}

	#listProgram(from, to) {
		for (const line of this.#program) {
			if (line.number < from || line.number > to) {
				continue;
			}

			this.#printText(`${line.number} `);
			let isInQuotes = false;
			for (const character of line.text) {
				const code = character.charCodeAt(0);
				if (code === 34) {
					isInQuotes = !isInQuotes;
				}

				if (isInQuotes && isControl(code)) {
					this.#putScreenCode(controlToScreen(code));
				} else {
					this.#printText(character);
				}
			}

			this.#newline();
		}
	}

	#collectData() {
		this.#dataItems = [];
		for (const line of this.#program) {
			line.tokens ??= tokenize(line.text);
			for (const token of line.tokens) {
				if (token.type === 'data') {
					for (const item of splitItems(token.value)) {
						this.#dataItems.push({...item, lineNumber: line.number});
					}
				}
			}
		}
	}

	#deviceArguments() {
		let name = '';
		let device = 1;
		let secondary = 0;
		if (!this.#isStatementEnd()) {
			name = this.#evaluateString();
			if (isSymbol(this.#tokens[this.#position], ',')) {
				this.#position++;
				device = toByte(this.#evaluateNumber());
				if (isSymbol(this.#tokens[this.#position], ',')) {
					this.#position++;
					secondary = toByte(this.#evaluateNumber());
				}
			}
		}

		return {name, device, secondary};
	}

	#assign() {
		const reference = this.#parseReference();
		this.#expectSymbol('=');
		this.#writeReference(reference, this.#evaluate());
	}

	#skipLine() {
		this.#position = this.#tokens.length;
		this.#isJumping = true;
	}

	#executeStatement() {
		const token = this.#tokens[this.#position];
		if (token.type === 'name') {
			this.#assign();
			return;
		}

		if (token.type !== 'keyword' || !Object.hasOwn(this.#statements, token.value)) {
			fail('SYNTAX');
		}

		this.#position++;
		this.#statements[token.value]();
	}

	#executeStep() {
		if (this.#position >= this.#tokens.length) {
			if (this.#lineIndex < 0 || this.#lineIndex + 1 >= this.#program.length) {
				this.#endProgram();
				return;
			}

			this.#goToIndex(this.#lineIndex + 1);
			return;
		}

		if (isSymbol(this.#tokens[this.#position], ':')) {
			this.#position++;
			return;
		}

		this.#statementStart = this.#position;
		this.#isJumping = false;
		this.#executeStatement();
		if (!this.#isJumping && this.#isRunning && !this.#waiting && !this.#isStatementEnd()) {
			fail('SYNTAX');
		}
	}

	// What the C64 printed since the last READY, for screen readers.
	#reportOutput() {
		const text = this.#outputLog.replaceAll('\r', ' ').trim();
		this.#outputLog = '';
		if (text !== '') {
			this.say(text.slice(-300), this.parts.output);
		}
	}

	#ready() {
		if (this.#editor.column !== 0) {
			this.#newline();
		}

		// READY. is not news for screen readers.
		const output = this.#outputLog;
		this.#printText('READY.');
		this.#outputLog = output;
		this.#newline();
		this.#blinkStart = this.#clock;

		// The keys typed while the program ran come out now, like on the C64.
		const typed = this.#keyboardBuffer.splice(0);
		for (const code of typed) {
			if (!isControl(code)) {
				this.#typeCode(code);
			}
		}

		this.#reportOutput();
	}

	#endProgram() {
		this.#isRunning = false;
		this.#waiting = undefined;
		this.#silenceSid();
		this.#ready();
	}

	#reportError(message, lineNumber = this.#currentLineNumber()) {
		this.#isRunning = false;
		this.#continuePoint = undefined;
		this.#waiting = undefined;
		this.#silenceSid();
		if (this.#editor.column !== 0) {
			this.#newline();
		}

		this.#printText(`?${message}  ERROR${lineNumber === undefined ? '' : ` IN ${lineNumber}`}`);
		this.#newline();
		this.#ready();
		if (errorHints[message]) {
			this.say(errorHints[message]);
		}
	}

	#breakProgram() {
		const lineNumber = this.#currentLineNumber();
		if (this.#lineIndex >= 0) {
			// A break in INPUT asks again after CONT.
			this.#continuePoint = this.#waiting ? {...this.#pointer(), position: this.#statementStart} : this.#pointer();
		}

		this.#isRunning = false;
		this.#waiting = undefined;
		this.#silenceSid();
		this.#newline();
		this.#printText(`BREAK${lineNumber === undefined ? '' : ` IN ${lineNumber}`}`);
		this.#newline();
		this.#ready();
		this.say(lineNumber === undefined ? 'RUN/STOP stopped it.' : `RUN/STOP stopped the program, and the C64 says where: in line ${lineNumber}. CONT goes on.`);
	}

	#runStatements(count) {
		let remaining = count;
		this.#shouldYield = false;
		while (remaining > 0 && this.#isRunning && !this.#waiting && !this.#operation && !this.#shouldYield) {
			remaining--;
			try {
				this.#executeStep();
			} catch (error) {
				// A function that calls itself, like DEF FNA(X)=FNA(X), runs out of stack, like on the C64.
				if (error instanceof RangeError) {
					this.#reportError('OUT OF MEMORY');
					continue;
				}

				if (!(error instanceof BasicError)) {
					throw error;
				}

				this.#reportError(error.message, error.lineNumber ?? this.#currentLineNumber());
			}
		}
	}

	#enterLine(text) {
		this.#lineIndex = -1;
		let start = 0;
		while (text[start] === ' ') {
			start++;
		}

		if (start === text.length) {
			return;
		}

		if (isDigit(text[start])) {
			let end = start;
			while (isDigit(text[end])) {
				end++;
			}

			const number = Number(text.slice(start, end));
			if (number > 63_999) {
				this.#reportError('SYNTAX', undefined);
				return;
			}

			while (text[end] === ' ') {
				end++;
			}

			this.#storeLine(number, text.slice(end));
			return;
		}

		this.#tokens = tokenize(text.slice(start));
		this.#position = 0;
		this.#isRunning = true;
		this.#outputLog = '';
		this.#lastActivity = this.#clock;
		this.#runStatements(statementsPerSecond / 20);
	}

	// RETURN gives INPUT what was typed after its question mark, split at the commas.
	#finishInput(text) {
		const values = [...this.#waiting.values, ...(text === '' && this.#waiting.values.length === 0 ? [] : splitItems(text))];
		if (values.length === 0) {
			this.#waiting = undefined;
			return;
		}

		for (const [index, reference] of this.#waiting.references.entries()) {
			if (index < values.length && !isStringKey(reference.key) && parseNumber(values[index].text) === undefined) {
				this.#printText('?REDO FROM START');
				this.#newline();
				this.#printText('? ');
				this.#inputStart = {row: this.#editor.row, column: this.#editor.column};
				this.#waiting.values = [];
				return;
			}
		}

		if (values.length < this.#waiting.references.length) {
			this.#waiting.values = values;
			this.#printText('?? ');
			this.#inputStart = {row: this.#editor.row, column: this.#editor.column};
			return;
		}

		if (values.length > this.#waiting.references.length) {
			this.#printText('?EXTRA IGNORED');
			this.#newline();
		}

		try {
			for (const [index, reference] of this.#waiting.references.entries()) {
				this.#writeReference(reference, isStringKey(reference.key) ? values[index].text : parseNumber(values[index].text));
			}
		} catch (error) {
			if (!(error instanceof BasicError)) {
				throw error;
			}

			this.#reportError(error.message);
			return;
		}

		this.#waiting = undefined;
		this.#lastActivity = this.#clock;
	}

	// RETURN enters the line the cursor is on, wherever it is on the screen, like the screen editor of the C64.
	#submitLine() {
		const start = this.#logicalStart(this.#editor.row);
		let text;
		if (this.#waiting && start === this.#logicalStart(this.#inputStart.row)) {
			text = this.#readLine(start, ((this.#inputStart.row - start) * 40) + this.#inputStart.column);
		} else {
			text = this.#readLine(start);
		}

		this.#editor.row = start;
		this.#newline();
		if (this.#waiting) {
			this.#finishInput(text);
		} else {
			this.#enterLine(text);
		}
	}

	// A key typed in the screen editor, as PETSCII.
	#typeCode(code) {
		this.#blinkStart = this.#clock;
		if (code === 13) {
			this.#submitLine();
			return;
		}

		if (isControl(code) && ![17, 145, 29, 157, 20, 148, 13, 141].includes(code) && this.#isQuoteMode()) {
			this.#putScreenCode(controlToScreen(code));
			return;
		}

		this.#printCode(code);
	}

	#waitUntil(check, owner) {
		return new Promise((resolve, reject) => {
		this.#waiters.add({check, resolve, reject, owner});
	});
	}

	#pause(seconds, owner) {
		const time = this.#clock + seconds;
		return this.#waitUntil(() => this.#clock >= time, owner);
	}

	#updateWaiters() {
		for (const waiter of this.#waiters) {
			if (waiter.owner.isCancelled) {
				this.#waiters.delete(waiter);
				waiter.reject(new Cancelled());
			} else if (waiter.check()) {
				this.#waiters.delete(waiter);
				waiter.resolve();
			}
		}
	}

	#startOperation(job, name, secondary, isTape) {
		this.#isRunning = false;
		const current = {isCancelled: false, reason: undefined, isTape};
		this.#operation = current;
		(async () => {
			try {
				// The jobs are methods of the C64.
				await job.call(this, current, name, secondary);
			} catch (error) {
				if (!(error instanceof Cancelled)) {
					throw error;
				}

				if (current.reason === 'break') {
					this.#screenMode = 'basic';
					this.#newline();
					this.#printText('BREAK');
					this.#newline();
					this.#ready();
				}
			} finally {
				if (this.#operation === current) {
					this.#operation = undefined;
				}

				this.#stopDrive();
			}
		})();
	}

	#cancelOperation(reason) {
		if (!this.#operation) {
			return;
		}

		this.#operation.isCancelled = true;
		this.#operation.reason = reason;
		this.#updateWaiters();
	}

	#loadSavedFiles() {
		const stored = this.stored('disk', []);
		if (!Array.isArray(stored)) {
			return [];
		}

		return stored.filter(file => typeof file?.name === 'string' && file.name.length <= 16 && Array.isArray(file.lines) && file.lines.every(line => Array.isArray(line) && Number.isInteger(line[0]) && typeof line[1] === 'string')).slice(0, 40);
	}

	#diskFiles() {
		return [
		...builtInFiles,
		...this.#savedFiles.map(file => ({name: file.name, type: 'PRG', lines: file.lines, blocks: blocksOf(file.lines), isSaved: true})),
	];
	}

	// The directory of the disk is a program of BASIC lines: the number of a line is the size of a file in blocks.
	#directoryLines() {
		const lines = [[0, `\u0012"${'PAPPAS DISKETT'.padEnd(16)}" 84 2A`]];
		let used = 0;
		for (const file of this.#diskFiles()) {
			used += file.blocks;
			lines.push([file.blocks, `${' '.repeat(Math.max(1, 4 - String(file.blocks).length))}${`"${file.name}"`.padEnd(18)} ${file.type}`]);
		}

		lines.push([Math.max(0, 664 - used), 'BLOCKS FREE.']);
		return lines;
	}

	#blinkDriveLight() {
		this.#drive.blinkUntil = this.#clock + 3;
	}

	async #loadFromDisk(current, rawName) {
		const name = stripDrive(rawName);
		if (name === '') {
			this.#reportError('MISSING FILE NAME');
			return;
		}

		this.#printText(`SEARCHING FOR ${name}`);
		this.#newline();
		this.#startDrive();
		await this.#pause(1.4, current);
		if (name === '$') {
			this.#printText('LOADING');
			this.#newline();
			await this.#pause(0.8, current);
			this.#stopDrive();
			this.#installProgram(this.#directoryLines());
			this.#gameInMemory = undefined;
			this.#ready();
			this.say('The list of Pappa’s disk is loaded like a program. Type LIST and press RETURN to see it!');
			return;
		}

		const file = this.#diskFiles().find(candidate => matchesName(name, candidate.name));
		if (!file || file.type !== 'PRG') {
			this.#knockHead();
			await this.#pause(1, current);
			this.#stopDrive();
			this.#blinkDriveLight();
			this.#reportError('FILE NOT FOUND');
			return;
		}

		this.#printText('LOADING');
		this.#newline();
		await this.#pause(file.isGame ? 3.4 : 1, current);
		this.#stopDrive();
		if (file.isGame) {
			this.#installProgram([[1984, 'SYS2061']]);
			this.#gameInMemory = 'disk';
			this.say('WAFFLE RAID is in the memory. Type RUN and press RETURN to start it!');
		} else {
			this.#installProgram(file.lines);
			this.#gameInMemory = undefined;
			this.say(`${file.name} is loaded. Type RUN to start it, or LIST to read it.`);
		}

		this.#ready();
	}

	async #saveToDisk(current, rawName) {
		let name = rawName;
		const isReplacing = name.startsWith('@0:') || name.startsWith('@:');
		if (isReplacing) {
			name = name.slice(name.indexOf(':') + 1);
		}

		name = stripDrive(name).slice(0, 16);
		if (name === '' || name.includes('*') || name.includes('?') || name === '$') {
			this.#reportError('MISSING FILE NAME');
			return;
		}

		this.#printText(`SAVING ${name}`);
		this.#newline();
		this.#startDrive();
		await this.#pause(1.6, current);
		this.#stopDrive();
		const isBuiltIn = builtInFiles.some(file => file.name === name);
		const existing = this.#savedFiles.findIndex(file => file.name === name);
		if (isBuiltIn || (existing !== -1 && !isReplacing)) {
			// The 1541 does not tell the C64. Only its light blinks.
			this.#blinkDriveLight();
			this.#ready();
			this.say(isBuiltIn ? `The light blinks: FILE EXISTS. “${name}” is Pappa’s, and he would be angry. Pick another name.` : `The light blinks: FILE EXISTS. SAVE "@0:${name}",8 replaces it.`);
			return;
		}

		if (existing === -1 && (this.#savedFiles.length >= 40 || blocksOf(this.#program.map(line => [line.number, line.text])) > 200)) {
			this.#blinkDriveLight();
			this.#ready();
			this.say('The light blinks: DISK FULL. LOAD "$",8 shows what is on it.');
			return;
		}

		const file = {name, lines: this.#program.map(line => [line.number, line.text])};
		if (existing === -1) {
			this.#savedFiles.push(file);
		} else {
			this.#savedFiles[existing] = file;
		}

		this.store('disk', this.#savedFiles);
		this.#ready();
		this.say(`Saved on Pappa’s disk as “${name}”. It stays there, also after you close the page. LOAD "$",8 shows it.`);
	}

	async #verifyFromDisk(current, rawName) {
		const name = stripDrive(rawName);
		if (name === '') {
			this.#reportError('MISSING FILE NAME');
			return;
		}

		this.#printText(`SEARCHING FOR ${name}`);
		this.#newline();
		this.#startDrive();
		await this.#pause(1.2, current);
		const file = this.#diskFiles().find(candidate => matchesName(name, candidate.name));
		if (!file?.lines) {
			this.#stopDrive();
			this.#blinkDriveLight();
			this.#reportError('FILE NOT FOUND');
			return;
		}

		this.#printText('VERIFYING');
		this.#newline();
		await this.#pause(1, current);
		this.#stopDrive();
		if (JSON.stringify(file.lines) !== JSON.stringify(this.#program.map(line => [line.number, line.text]))) {
			this.#reportError('VERIFY');
			return;
		}

		this.#printText('OK');
		this.#newline();
		this.#ready();
	}

	// Loading from the tape: PRESS PLAY ON TAPE, the search with a blank screen, FOUND, and the turbo loader of the cracked game, with its stripes in the border.
	async #loadFromTape(current) {
		if (this.#tape.motion !== 'play') {
			this.#printText('PRESS PLAY ON TAPE');
			this.#newline();
			this.say('The C64 waits for the tape. Press ▶ PLAY on the Datassette! (Escape is RUN/STOP.)');
			await this.#waitUntil(() => this.#tape.motion === 'play', current);
		}

		this.#printText('OK');
		this.#newline();
		this.#newline();
		this.#printText('SEARCHING');
		this.#newline();
		this.#screenMode = 'blank';
		const crossings = this.#tape.crossings;
		if (this.#tape.position >= tapeHeader) {
			this.say('Searching… but the game is at the start of the tape, and the counter is past it. Press ■ STOP, rewind ◀◀ to 000, and press ▶ PLAY again.');
		} else {
			this.say('Searching the tape… The screen is blank while it looks.');
		}

		await this.#waitUntil(() => this.#tape.crossings > crossings, current);
		this.#screenMode = 'basic';
		this.#printText('FOUND WAFFLE RAID');
		this.#newline();
		this.say('FOUND WAFFLE RAID! It is Trond’s copy, with a turbo loader.');
		await this.#pause(1.6, current);
		this.#printText('LOADING');
		this.#newline();
		this.#screenMode = 'blank';
		await this.#waitUntil(() => this.#tape.position >= tapeHeader + 6, current);
		this.#screenMode = 'loading';
		this.say('The turbo loader makes the stripes in the border while it loads. On the real one, this takes five minutes.');
		await this.#waitUntil(() => {
			this.#loadingProgress = clamp((this.#tape.position - tapeHeader - 6) / (tapeGameEnd - tapeHeader - 6), 0, 1);
			return this.#tape.position >= tapeGameEnd;
		}, current);
		this.#setTapeMotion('stop');
		this.#installProgram([[1984, 'SYS2061']]);
		this.#gameInMemory = 'tape';
		this.#startCracktro();
	}

	async #saveToTape(current, name) {
		this.#printText('PRESS RECORD & PLAY ON TAPE');
		this.#newline();
		this.say('Press ● RECORD on the Datassette!');
		await this.#waitUntil(() => this.#tape.motion === 'record', current);
		this.#printText('OK');
		this.#newline();
		this.#screenMode = 'blank';
		await this.#pause(0.8, current);
		this.#screenMode = 'basic';
		this.#printText(`SAVING ${name}`);
		this.#newline();
		await this.#pause(2.5, current);
		this.#setTapeMotion('stop');
		this.#ready();
		this.say('Saved on the tape… right over Pappa’s a-ha tape from 1985. Do not tell him. (The disk is better: SAVE "NAME",8.)');
	}

	#startCracktro() {
		this.#screenMode = 'cracktro';
		this.#cracktro.startClock = this.#clock;
		this.#playSong(songs.cracktro);
		this.say('Cracked by TEAM WAFFLE! The trainer has cheats: F1 for unlimited waffles, F3 for slow seagulls. Space or FIRE starts the game.');
	}

	#renderCracktro() {
		const time = this.reducedMotion ? 1.2 : this.#clock - this.#cracktro.startClock;
		this.#fill(0, 0, width, height, colors.black);

		// Three raster bars that bounce over the border too, the trick of the cracktros.
		const bars = [[6, 14, 3, 1, 3, 14, 6], [2, 10, 7, 1, 7, 10, 2], [9, 8, 7, 1, 7, 8, 9]];
		for (const [index, bar] of bars.entries()) {
			const center = top + 14 + (Math.sin((time * 2.1) + (index * 0.9)) * 16);
			for (const [line, color] of bar.entries()) {
				this.#fill(0, center + ((line - 3) * 2), width, 2, color);
			}
		}

		const logoColors = [7, 7, 1, 1, 7, 8, 8, 2];
		const offset = this.reducedMotion ? 0 : Math.floor(time * 12);
		this.#drawCenteredText('TEAM WAFFLE', top + 50, row => logoColors[(row + offset) % logoColors.length], 2);
		this.#drawCenteredText('CRACKED IN BERGEN 1999', top + 74, colors.lightBlue);
		this.#drawCenteredText('+2 TRAINER', top + 88, colors.lightGreen);
		this.#drawText(`F1 UNLIMITED WAFFLES ... ${this.#cracktro.hasUnlimitedWaffles ? 'YES' : 'NO '}`, left + 36, top + 108, this.#cracktro.hasUnlimitedWaffles ? colors.yellow : colors.gray);
		this.#drawText(`F3 SLOW SEAGULLS ....... ${this.#cracktro.hasSlowSeagulls ? 'YES' : 'NO '}`, left + 36, top + 120, this.#cracktro.hasSlowSeagulls ? colors.yellow : colors.gray);
		const blinkColors = [1, 15, 12, 11, 12, 15];
		this.#drawCenteredText('PRESS SPACE OR FIRE', top + 142, this.reducedMotion ? colors.white : blinkColors[Math.floor(time * 8) % blinkColors.length]);

		// The scroller of greetings, which waves along the bottom.
		const scroll = this.reducedMotion ? 40 : time * 70;
		const first = Math.floor(scroll / 8);
		const shift = scroll % 8;
		for (let column = 0; column < 41; column++) {
			const x = left + (column * 8) - shift;
			const y = top + 172 + (this.reducedMotion ? 0 : Math.sin((x + (time * 90)) * 0.035) * 8);
			const code = petsciiToScreen(greetings.charCodeAt((first + column) % greetings.length));
			this.#drawCharacter(code, x, y, [3, 14, 1, 13, 7][(first + column) % 5]);
		}
	}

	#hasUnlimitedWaffles() {
		return this.#game.isCracked && this.#cracktro.hasUnlimitedWaffles;
	}

	#startGame(isCracked) {
		this.#screenMode = 'game';
		this.#game.isCracked = isCracked;
		this.#game.screen = 'title';
		this.#game.wasFiring = this.#isFiring();
		this.#playSong(songs.title);
		this.say('WAFFLE RAID! Stop the seagulls (måkene) from stealing Mormor’s waffles. Arrow keys or the joystick to walk, Space or FIRE to throw brunost. Only Pappa’s reset button gets you out.');
	}

	#startWave() {
		this.#game.toSpawn = 3 + (this.#game.wave * 2);
		this.#game.spawnTimer = 0.8;
		this.#game.screen = 'wave';
		this.#game.timer = 1.8;
		for (const [index, note] of ['C5', 'E5', 'G5', 'C6'].entries()) {
			this.#tone({frequency: frequencyOf(note), duration: 0.12, volume: 0.05, when: index * 0.09, duty: 0.25});
		}
	}

	#newGame() {
		this.#stopMusic();
		Object.assign(this.#game, {score: 0, wave: 1, waffles: 5, player: 154, shots: [], gulls: [], feathers: [], popups: [], hasWarnedLeft: false});
		this.#startWave();
	}

	#gameOver() {
		this.#game.screen = 'over';
		this.#game.timer = 4;
		for (const [index, note] of ['G4', 'E4', 'C4', 'G3'].entries()) {
			this.#tone({frequency: frequencyOf(note), duration: 0.25, volume: 0.06, when: index * 0.2, duty: 0.5});
		}

		if (this.#game.score > this.#game.highScore) {
			this.#game.highScore = this.#game.score;
			this.store('highScore', this.#game.score);
			this.celebrate();
			this.toast(`New high score in Waffle Raid on Pappa’s C64: ${this.#game.score}!`);
			this.say(`GAME OVER, but a new high score: ${this.#game.score}! Mormor is a little proud.`);
		} else {
			this.say(`GAME OVER. Mormor is disappointed (skuffet). ${this.#game.score} points.`);
		}
	}

	#addPopup(text, x, y) {
		this.#game.popups.push({text, x, y, life: 1});
	}

	#hitGull(gull) {
		this.#game.score += gull.isCarrying ? 250 : 100;
		this.#addPopup(gull.isCarrying ? 'SAVED!' : '100', gull.x, gull.y);
		if (gull.isCarrying && !this.#hasUnlimitedWaffles()) {
			this.#game.waffles = Math.min(5, this.#game.waffles + 1);
		}

		for (let index = 0; index < 8; index++) {
			this.#game.feathers.push({x: gull.x + 7, y: gull.y + 3, speedX: (Math.random() - 0.5) * 70, speedY: (Math.random() - 0.8) * 60, life: 0.8});
		}

		this.#noiseBurst({duration: 0.18, volume: 0.1, filter: 'bandpass', frequency: 1200});
		this.#tone({frequency: 1300, endFrequency: 450, duration: 0.16, volume: 0.04, type: 'sawtooth'});
	}

	#updateGulls(seconds) {
		const speed = this.#game.isCracked && this.#cracktro.hasSlowSeagulls ? 0.55 : 1;
		for (const gull of this.#game.gulls) {
			gull.age += seconds;
			if (gull.state === 'fly') {
				gull.x += gull.speedX * seconds * speed;
				gull.y = gull.baseY + (Math.sin(gull.age * 3) * 5);
				if (gull.x < -16) {
					gull.x = 320;
				} else if (gull.x > 321) {
					gull.x = -15;
				}

				gull.diveIn -= seconds;
				if (gull.diveIn <= 0 && gull.x > 10 && gull.x < 295) {
					gull.state = 'dive';
					this.#tone({frequency: 900, endFrequency: 1400, duration: 0.12, volume: 0.03, type: 'sawtooth'});
				}
			} else if (gull.state === 'dive') {
				const deltaX = 160 - (gull.x + 7);
				const deltaY = 170 - (gull.y + 5);
				const distance = Math.hypot(deltaX, deltaY);
				const step = (55 + (this.#game.wave * 7)) * seconds * speed;
				if (distance <= step + 1) {
					gull.state = 'escape';
					gull.speedX = (Math.random() < 0.5 ? -1 : 1) * 30;
					if (this.#game.waffles > 0) {
						gull.isCarrying = true;
						if (!this.#hasUnlimitedWaffles()) {
							this.#game.waffles--;
						}

						this.#addPopup('NAM!', gull.x, gull.y - 8);
						this.#tone({frequency: 700, endFrequency: 150, duration: 0.35, volume: 0.06, duty: 0.5});
					}
				} else {
					gull.x += (deltaX / distance) * step;
					gull.y += (deltaY / distance) * step;
				}
			} else {
				gull.y -= 45 * seconds * speed;
				gull.x += gull.speedX * seconds;
			}
		}

		this.#game.gulls = this.#game.gulls.filter(gull => gull.y > -12);
	}

	#updatePlay(seconds) {
		const isLeft = this.#isLeftWorking();
		if (this.#joystick.left && !isLeft && !this.#game.hasWarnedLeft) {
			this.#game.hasWarnedLeft = true;
			this.say('The joystick does not go left! It has been broken since 1987. Bang it on the table.');
		}

		const direction = (this.#joystick.right ? 1 : 0) - (isLeft ? 1 : 0);
		this.#game.player = clamp(this.#game.player + (direction * 110 * seconds), 2, 306);
		if (direction !== 0) {
			this.#game.walk += seconds;
		}

		this.#game.cooldown -= seconds;
		if ((this.#isFiring() || this.#joystick.up) && this.#game.cooldown <= 0 && this.#game.shots.length < 2) {
			this.#game.shots.push({x: this.#game.player + 4, y: 168});
			this.#game.cooldown = 0.28;
			this.#tone({frequency: 300, endFrequency: 1200, duration: 0.09, volume: 0.05, duty: 0.25});
		}

		for (const shot of this.#game.shots) {
			shot.y -= 210 * seconds;
		}

		this.#game.spawnTimer -= seconds;
		if (this.#game.spawnTimer <= 0 && this.#game.toSpawn > 0 && this.#game.gulls.length < 2 + this.#game.wave) {
			const isFromLeft = Math.random() < 0.5;
			const baseY = 28 + (Math.random() * 50);
			this.#game.gulls.push({x: isFromLeft ? -15 : 320, y: baseY, baseY, speedX: (isFromLeft ? 1 : -1) * (38 + (this.#game.wave * 5)), state: 'fly', diveIn: 1.5 + (Math.random() * 3.5), age: Math.random() * 3, isCarrying: false});
			this.#game.toSpawn--;
			this.#game.spawnTimer = Math.max(0.5, 1.6 - (this.#game.wave * 0.1));
		}

		this.#updateGulls(seconds);

		for (const shot of this.#game.shots) {
			for (const gull of this.#game.gulls) {
				if (!shot.isSpent && !gull.isHit && shot.x + 3 >= gull.x && shot.x <= gull.x + 15 && shot.y <= gull.y + 6 && shot.y + 4 >= gull.y) {
					shot.isSpent = true;
					gull.isHit = true;
					this.#hitGull(gull);
				}
			}
		}

		this.#game.shots = this.#game.shots.filter(shot => !shot.isSpent && shot.y > 14);
		this.#game.gulls = this.#game.gulls.filter(gull => !gull.isHit);

		if (this.#game.waffles === 0) {
			this.#gameOver();
			return;
		}

		if (this.#game.toSpawn === 0 && this.#game.gulls.length === 0) {
			this.#game.score += this.#game.waffles * 50;
			this.#game.wave++;
			this.#game.hasNewWaffle = this.#game.waffles < 5;
			this.#game.waffles = Math.min(5, this.#game.waffles + 1);
			this.#startWave();
		}
	}

	#updateGame(seconds) {
		const isMoving = !this.reducedMotion || Object.values(this.#joystick).some(Boolean) || this.#clock < this.#fireTapUntil;
		const firing = this.#isFiring();
		const isFireEdge = firing && !this.#game.wasFiring;
		this.#game.wasFiring = firing;
		if (!isMoving) {
			return;
		}

		for (const drop of this.#rain) {
			drop.y += drop.speed * seconds;
			if (drop.y > 200) {
				drop.y = 18;
				drop.x = Math.random() * 320;
			}
		}

		for (const feather of this.#game.feathers) {
			feather.x += feather.speedX * seconds;
			feather.y += feather.speedY * seconds;
			feather.speedY += 90 * seconds;
			feather.life -= seconds;
		}

		this.#game.feathers = this.#game.feathers.filter(feather => feather.life > 0);
		for (const popup of this.#game.popups) {
			popup.y -= 20 * seconds;
			popup.life -= seconds;
		}

		this.#game.popups = this.#game.popups.filter(popup => popup.life > 0);

		if (this.#game.screen === 'title') {
			if (isFireEdge) {
				this.#newGame();
			}
		} else if (this.#game.screen === 'wave') {
			this.#game.timer -= seconds;
			if (this.#game.timer <= 0) {
				this.#game.screen = 'play';
			}
		} else if (this.#game.screen === 'over') {
			this.#game.timer -= seconds;
			if (this.#game.timer <= 0 || (isFireEdge && this.#game.timer < 2.5)) {
				this.#game.screen = 'title';
				this.#playSong(songs.title);
			}
		} else {
			this.#updatePlay(seconds);
		}
	}

	// Bryggen in the rain at dusk, with the sky in bands, like the raster splits of the games of the C64.
	#drawScene() {
		this.#fill(0, 0, width, height, colors.black);
		const bands = [[0, 18, colors.black], [18, 56, colors.blue], [56, 82, colors.purple], [82, 130, colors.lightRed]];
		for (const [start, end, color] of bands) {
			this.#fillDisplay(0, start, 320, end - start, color);
		}

		// The lines between the bands are mixed, every other pixel.
		for (const [index, [start]] of bands.entries()) {
			if (index < 2) {
				continue;
			}

			for (let x = 0; x < 320; x += 2) {
				this.#plotDisplay(x, start - 1, bands[index - 1][2]);
				this.#plotDisplay(x + 1, start, bands[index - 1][2]);
			}
		}

		for (const [x, peak] of mountains.entries()) {
			this.#fillDisplay(x, peak, 1, 130 - peak, colors.darkGray);
		}

		for (const [index, color] of houseColors.entries()) {
			const x = (index * 40) + 2;
			const roof = 104 + ((index % 3) * 5);
			for (let row = 0; row < 14; row++) {
				const half = Math.round((row + 1) * 18 / 14);
				this.#fillDisplay(x + 18 - half, roof + row, half * 2, 1, colors.black);
			}

			this.#fillDisplay(x, roof + 14, 36, 166 - roof - 14, color);
			for (let row = 0; row < 2; row++) {
				for (let column = 0; column < 3; column++) {
					const windowX = x + 5 + (column * 11);
					const windowY = roof + 20 + (row * 14);
					this.#fillDisplay(windowX - 1, windowY - 1, 7, 9, colors.white);
					this.#fillDisplay(windowX, windowY, 5, 7, (index + column + row) % 4 === 0 ? colors.yellow : colors.black);
				}
			}
		}

		this.#fillDisplay(0, 166, 320, 34, colors.gray);
		this.#fillDisplay(0, 166, 320, 1, colors.darkGray);
		for (let y = 170; y < 200; y += 5) {
			for (let x = (y % 10 === 0 ? 0 : 3); x < 320; x += 6) {
				this.#plotDisplay(x, y, colors.darkGray);
			}
		}
	}

	#drawRain() {
		for (const drop of this.#rain) {
			for (let index = 0; index < 3; index++) {
				this.#plotDisplay(drop.x, drop.y + index, colors.lightBlue);
			}
		}
	}

	#drawLogo(y) {
		const shading = [1, 7, 7, 7, 8, 8, 9, 9];
		this.#drawCenteredText('WAFFLE RAID', top + y + 2, colors.brown, 2);
		this.#drawCenteredText('WAFFLE RAID', top + y, row => shading[row], 2);
	}

	#renderGame() {
		this.#drawScene();

		// The table with the waffles of Mormor.
		this.#fillDisplay(151, 182, 2, 14, colors.brown);
		this.#fillDisplay(167, 182, 2, 14, colors.brown);
		this.#fillDisplay(148, 180, 24, 3, colors.orange);
		const stack = this.#hasUnlimitedWaffles() ? 5 : this.#game.waffles;
		for (let index = 0; index < stack; index++) {
			this.#drawPicture(waffle, 154, 177 - (index * 3));
		}

		const isTitle = this.#game.screen === 'title';
		if (!isTitle) {
			this.#drawPicture(sindre[Math.floor(this.#game.walk * 8) % 2], Math.round(this.#game.player), 176);
		}

		for (const shot of this.#game.shots) {
			this.#drawPicture(brunost, shot.x, shot.y);
		}

		const flap = this.reducedMotion ? 0 : Math.floor(this.#clock * 6) % 2;
		for (const gull of this.#game.gulls) {
			this.#drawPicture(seagull[flap], gull.x, gull.y);
			if (gull.isCarrying) {
				this.#drawPicture(waffle, gull.x + 1, gull.y + 6);
			}
		}

		// On the title screen, two seagulls fly by and wait for the game.
		if (isTitle) {
			const time = this.reducedMotion ? 2 : this.#clock;
			this.#drawPicture(seagull[flap], ((time * 40) % 360) - 20, 96 + (Math.sin(time * 2) * 6));
			this.#drawPicture(seagull[1 - flap], 340 - ((time * 28) % 380), 116 + (Math.sin(time * 3) * 4));
		}

		for (const feather of this.#game.feathers) {
			this.#plotDisplay(feather.x, feather.y, colors.white);
		}

		this.#drawRain();

		if (isTitle) {
			this.#drawLogo(26);
			this.#drawCenteredText(this.#game.isCracked ? 'CRACKED BY TEAM WAFFLE' : '(C) 1984 BERGEN BYTES', top + 52, this.#game.isCracked ? colors.lightGreen : colors.white);
			this.#drawCenteredText(`HI SCORE ${pad(this.#game.highScore)}`, top + 66, colors.cyan);
			const isBlinkOn = this.reducedMotion || Math.floor(this.#clock * 2) % 2 === 0;
			if (isBlinkOn) {
				this.#drawCenteredText('PRESS FIRE TO START', top + 80, colors.white);
			}

			if (this.#hasUnlimitedWaffles() || (this.#game.isCracked && this.#cracktro.hasSlowSeagulls)) {
				this.#drawText('TRAINER ON', left + 4, top + 5, colors.yellow);
			}

			return;
		}

		this.#drawText(`SCORE ${pad(this.#game.score)}`, left + 4, top + 5, colors.white);
		this.#drawCenteredText(`WAVE ${this.#game.wave}`, top + 5, colors.cyan);
		this.#drawText(`HI ${pad(this.#game.highScore)}`, left + 320 - 76, top + 5, colors.yellow);

		for (const popup of this.#game.popups) {
			this.#drawText(popup.text, left + popup.x, top + popup.y, colors.white);
		}

		if (this.#game.screen === 'wave') {
			this.#drawCenteredText(`WAVE ${this.#game.wave}`, top + 56, colors.yellow, 2);
			if (this.#game.wave > 1 && this.#game.hasNewWaffle) {
				this.#drawCenteredText('MORMOR BAKTE EN NY VAFFEL!', top + 80, colors.white);
				this.#drawCenteredText('(GRANDMA BAKED A NEW WAFFLE)', top + 90, colors.lightGray);
			} else if (this.#game.wave === 1) {
				this.#drawCenteredText('SAVE MORMORS VAFLER!', top + 80, colors.white);
				this.#drawCenteredText('(SAVE GRANDMA\'S WAFFLES)', top + 90, colors.lightGray);
			}
		} else if (this.#game.screen === 'over') {
			this.#fillDisplay(36, 58, 248, 52, colors.black);
			this.#drawCenteredText('GAME OVER', top + 64, colors.red, 2);
			this.#drawCenteredText('MORMOR ER SKUFFET!', top + 86, colors.white);
			this.#drawCenteredText('(GRANDMA IS DISAPPOINTED)', top + 96, colors.lightGray);
		}
	}

	// The loading picture of the turbo loader, which comes in row by row, with the stripes in the border.
	#renderLoading() {
		let random = this.reducedMotion ? 7 : Math.floor(this.#clock * 60);
		const stripeColors = [0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 13, 14];
		let y = 0;
		while (y < height) {
			random = ((random * 9301) + 49_297) % 233_280;
			const bandHeight = 2 + (random % 5);
			this.#fill(0, y, width, bandHeight, stripeColors[random % stripeColors.length]);
			y += bandHeight;
		}

		const stripes = this.#pixels.slice();
		this.#drawScene();
		this.#drawLogo(40);
		this.#drawCenteredText('LOADING...', top + 70, colors.white);
		this.#drawRain();

		// The border keeps its stripes, and the rows of the picture that are not loaded yet are black.
		for (let row = 0; row < height; row++) {
			const isBorderRow = row < top || row >= top + 200;
			if (isBorderRow) {
				this.#pixels.set(stripes.subarray(row * width, (row + 1) * width), row * width);
			} else {
				this.#pixels.set(stripes.subarray(row * width, (row * width) + left), row * width);
				this.#pixels.set(stripes.subarray((row * width) + left + 320, (row + 1) * width), (row * width) + left + 320);
			}
		}

		const loadedRows = Math.floor(this.#loadingProgress * 25) * 8;
		this.#fillDisplay(0, loadedRows, 320, 200 - loadedRows, colors.black);
	}

	// The screen of BASIC: the border, the background, the 1000 characters with their colors from the memory, the cursor, and the sprites.
	#renderBasic() {
		this.#fill(0, 0, width, height, this.#memory[borderRegister] & 15);
		this.#fill(left, top, 320, 200, this.#memory[backgroundRegister] & 15);
		const isCursorShown = (!this.#isRunning || this.#waiting) && !this.#operation && (this.reducedMotion || Math.floor((this.#clock - this.#blinkStart) * 3) % 2 === 0);
		const cursorIndex = (this.#editor.row * 40) + this.#editor.column;
		for (let index = 0; index < 1000; index++) {
			let code = this.#memory[screenStart + index];
			let color = this.#memory[colorStart + index] & 15;
			if (isCursorShown && index === cursorIndex) {
				code ^= 128;
				color = this.#textColor();
			}

			if (code !== 32) {
				this.#drawCharacter(code, left + ((index % 40) * 8), top + (Math.floor(index / 40) * 8), color);
			}
		}

		const enabled = this.#memory[53_269];
		for (let sprite = 0; sprite < 8; sprite++) {
			if (!(enabled & (1 << sprite))) {
				continue;
			}

			const data = this.#memory[2040 + sprite] * 64;
			const color = this.#memory[53_287 + sprite] & 15;
			const x = this.#memory[53_248 + (sprite * 2)] + ((this.#memory[53_264] >> sprite) & 1 ? 256 : 0) - 24;
			const y = this.#memory[53_249 + (sprite * 2)] - 50;
			const scaleX = (this.#memory[53_277] >> sprite) & 1 ? 2 : 1;
			const scaleY = (this.#memory[53_271] >> sprite) & 1 ? 2 : 1;
			for (let row = 0; row < 21; row++) {
				for (let column = 0; column < 24; column++) {
					if (this.#memory[(data + (row * 3) + Math.floor(column / 8)) & 65_535] & (128 >> (column % 8))) {
						for (let partY = 0; partY < scaleY; partY++) {
							for (let partX = 0; partX < scaleX; partX++) {
								this.#plotDisplay(x + (column * scaleX) + partX, y + (row * scaleY) + partY, color);
							}
						}
					}
				}
			}
		}
	}

	#render() {
		// On a phone, the TV sticks to the top while the tape plays and while a game runs, so the Datassette or the joystick below it and the screen fit on the screen together, and the C64 keeps going.
		const televisionState = this.#operation?.isTape || this.#screenMode === 'game' || this.#screenMode === 'cracktro' ? 'game' : '';
		if (this.parts.television.dataset.state !== televisionState) {
			this.parts.television.dataset.state = televisionState;
		}

		switch (this.#screenMode) {
			case 'off': {
				this.#pixels.fill(offScreen);
				break;
			}

			case 'boot': {
				// The TV warms up: dark, then the light blue of the border, then the text.
				this.#fill(0, 0, width, height, this.#clock - this.#bootClock < 0.35 ? colors.black : colors.lightBlue);
				break;
			}

			case 'blank': {
				this.#fill(0, 0, width, height, this.#memory[borderRegister] & 15);
				break;
			}

			case 'loading': {
				this.#renderLoading();
				break;
			}

			case 'cracktro': {
				this.#renderCracktro();
				break;
			}

			case 'game': {
				this.#renderGame();
				break;
			}

			default: {
				this.#renderBasic();
			}
		}

		this.#context.putImageData(this.#image, 0, 0);
	}

	#printBootText() {
		this.#clearScreen();
		this.#newline();
		this.#printText('    **** COMMODORE 64 BASIC V2 ****');
		this.#newline();
		this.#newline();
		this.#printText(' 64K RAM SYSTEM  38911 BASIC BYTES FREE');
		this.#newline();
		this.#newline();
		this.#printText('READY.');
		this.#newline();
		this.#outputLog = '';
		this.#blinkStart = this.#clock;
		this.#screenMode = 'basic';
	}

	#updateBrick(seconds) {
		const target = this.#isPowered ? 58 : 21;
		this.#brick.temperature += (target - this.#brick.temperature) * Math.min(1, seconds * 0.006);
		const shown = Math.round(this.#brick.temperature);
		if (shown !== this.#brick.shownTemperature) {
			this.#brick.shownTemperature = shown;
			this.parts.brickReading.textContent = `${shown} °C`;
			this.parts.brick.dataset.state = shown >= 48 ? 'hot' : (shown >= 35 ? 'warm' : '');
		}

		if (this.#brick.temperature >= 54 && this.#screenMode === 'basic' && !this.reducedMotion && Math.random() < seconds * 0.4) {
			const index = Math.floor(Math.random() * 1000);
			this.#memory[screenStart + index] = 64 + Math.floor(Math.random() * 64);
			if (!this.#brick.hasWarnedGlitch) {
				this.#brick.hasWarnedGlitch = true;
				this.say('The letters on the screen go strange… The power brick is too hot! Feel it.');
			}
		}
	}

	#runBasic(seconds) {
		if (this.#screenMode === 'boot' && this.#clock - this.#bootClock >= (this.reducedMotion ? 0 : 0.7)) {
			this.#printBootText();
		}

		if (!this.#isRunning || this.#waiting || this.#operation) {
			this.#statementBudget = 0;
			return;
		}

		// For reduced motion, a running program stops by itself after a few seconds, until the visitor presses a key.
		if (this.reducedMotion && this.#clock - this.#lastActivity > 3) {
			if (!this.#isPausedForMotion) {
				this.#isPausedForMotion = true;
				this.say('The program is paused, so nothing moves by itself. Press a key to go on, or RUN/STOP (Escape) to stop it.');
			}

			return;
		}

		this.#isPausedForMotion = false;
		this.#statementBudget += seconds * statementsPerSecond;
		const count = Math.floor(this.#statementBudget);
		this.#statementBudget -= count;
		this.#runStatements(count);
	}

	#step(seconds) {
		this.#clock += seconds;
		this.#jiffies += seconds * 60;
		this.#updateTape(seconds);
		this.#updateDrive();
		this.#updateBrick(seconds);
		this.#updateWaiters();
		if (this.#screenMode === 'basic' || this.#screenMode === 'boot') {
			this.#runBasic(seconds);
		} else if (this.#screenMode === 'game') {
			this.#updateGame(seconds);
		}

		this.#render();
	}

	// The sounds that last play only while the sound is on and the C64 is visible: the music of a game, the notes of a program, the hum of the drive, and the tape. They come back when the C64 does.
	#updateSounds() {
		if (!this.#audio.isReady || !this.isVisible) {
			this.#stopMusic();
		} else if (!this.#tune && this.#screenMode === 'cracktro') {
			this.#playSong(songs.cracktro);
		} else if (!this.#tune && this.#screenMode === 'game' && this.#game.screen === 'title') {
			this.#playSong(songs.title);
		}

		this.#syncSid();
		this.#updateDriveHum();
		this.#updateTapeSound();
	}

	#coldStart() {
		this.#cancelOperation('power');
		this.#stopMusic();
		this.#silenceSid();
		this.#stopDrive();
		this.#memory.fill(0);
		this.#memory[borderRegister] = colors.lightBlue;
		this.#memory[backgroundRegister] = colors.blue;
		this.#memory[textColorAddress] = colors.lightBlue;
		for (const [index, color] of [1, 2, 3, 4, 5, 6, 7, 12].entries()) {
			this.#memory[53_287 + index] = color;
		}

		this.#program.length = 0;
		this.#clearVariables();
		this.#continuePoint = undefined;
		this.#isRunning = false;
		this.#waiting = undefined;
		this.#keyboardBuffer.length = 0;
		this.#gameInMemory = undefined;
		this.#lineIndex = -1;
		this.#tokens = [];
		this.#position = 0;
		this.#clearScreen();
		this.#screenMode = 'boot';
		this.#bootClock = this.#clock;
	}

	#powerOn() {
		this.#isPowered = true;
		this.parts.power.setAttribute('aria-pressed', 'true');
		this.parts.powerLight.dataset.state = 'on';
		this.#coldStart();
		// The loop starts here, and not in a cold start, which a program can do with SYS 64738 in a step of the loop, while the loop runs.
		this.#loop.start();
		this.say('It works! The blue screen of the Commodore 64. Click it and type, or let Pappa’s notebook type for you.');
	}

	#powerOff() {
		this.#cancelOperation('power');
		this.#isPowered = false;
		this.#isRunning = false;
		this.#waiting = undefined;
		this.#stopMusic();
		this.#silenceSid();
		this.#stopDrive();
		this.#setTapeMotion('stop');
		this.parts.power.setAttribute('aria-pressed', 'false');
		this.parts.powerLight.dataset.state = '';
		this.#screenMode = 'off';
		this.#render();
		this.say('Off. Everything that was not saved on the disk is gone, like in 1984.');
	}

	// What a key does in the cracktro and in the game, where the keyboard is the joystick too.
	#gameKey(key) {
		if (key === 'run-stop' || key === 'restore') {
			this.say('A game does not listen to RUN/STOP or RESTORE. Pappa’s reset button gets you out.');
			return;
		}

		if (this.#screenMode === 'cracktro') {
			if (key === 'f1') {
				this.#cracktro.hasUnlimitedWaffles = !this.#cracktro.hasUnlimitedWaffles;
				this.#tone({frequency: 880, duration: 0.08, volume: 0.05, duty: 0.25});
			} else if (key === 'f3') {
				this.#cracktro.hasSlowSeagulls = !this.#cracktro.hasSlowSeagulls;
				this.#tone({frequency: 660, duration: 0.08, volume: 0.05, duty: 0.25});
			} else if (key === 'space' || key === 'return') {
				this.#stopMusic();
				this.#startGame(true);
			}

			return;
		}

		if (key === 'space' || key === 'return') {
			this.#fireTapUntil = this.#clock + 0.15;
		}
	}

	#pressKey(key, modifiers = {}) {
		if (!this.#isPowered) {
			this.say('It is off. Flip the power switch!');
			return;
		}

		this.#lastActivity = this.#clock;
		if (this.#screenMode === 'cracktro' || this.#screenMode === 'game') {
			this.#gameKey(key);
			return;
		}

		if (key === 'restore') {
			this.#cancelOperation('restore');
			this.#warmStart();
			this.say('RUN/STOP and RESTORE: the panic button. It stops the program and makes the colors normal again.');
			return;
		}

		if (key === 'run-stop') {
			if (this.#operation) {
				this.#cancelOperation('break');
			} else if (this.#isRunning) {
				this.#breakProgram();
			}

			return;
		}

		if (this.#screenMode !== 'basic' || this.#operation) {
			return;
		}

		const code = keyCode(key, modifiers);
		if (code === undefined) {
			return;
		}

		if (this.#isRunning && !this.#waiting) {
			if (this.#keyboardBuffer.length < 10) {
				this.#keyboardBuffer.push(code);
			}

			return;
		}

		this.#typeCode(code);
	}

	#releaseJoystick() {
		for (const direction of Object.keys(this.#joystick)) {
			this.#joystick[direction] = false;
		}
	}

	#showModifiers() {
		for (const button of this.#keyButtons) {
			const modifier = modifierKeys[button.dataset.c64Key];
			if (modifier) {
				setPressed(button, this.#modifiers[modifier]);
			}
		}
	}

	// The power switch and the reset button stop Pappa’s notebook from typing on.
	#stopTyping() {
		if (this.#typingOwner) {
			this.#typingOwner.isCancelled = true;
			this.#updateWaiters();
		}
	}

	#isBusy() {
		return this.#screenMode !== 'basic' || this.#operation !== undefined || (this.#isRunning && !this.#waiting);
	}

	async #typeLines(lines) {
		this.#stopTyping();

		const owner = {isCancelled: false};
		this.#typingOwner = owner;
		try {
			if (!this.#isPowered) {
				this.#powerOn();
			} else if (this.#screenMode === 'game' || this.#screenMode === 'cracktro' || this.#screenMode === 'loading') {
				this.#coldStart();
			} else if (this.#operation) {
				this.#cancelOperation('break');
			} else if (this.#isRunning) {
				this.#breakProgram();
			}

			for (const line of lines) {
				await this.#waitUntil(() => !this.#isBusy(), owner);
				for (const character of line) {
					this.#pressKey(characterKey(character) ?? character);
					await this.#pause(this.reducedMotion ? 0 : 0.03, owner);
				}

				this.#pressKey('return');
			}

			return true;
		} catch (error) {
			if (!(error instanceof Cancelled)) {
				throw error;
			}

			return false;
		}
	}
}
