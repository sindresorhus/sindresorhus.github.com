// My TI-83 on the 1999 page: the graphing calculator of Texas Instruments (1996), drawn pixel by pixel on a canvas of 96 × 64 pixels with the pixel fonts of the real one. It calculates with the order of operations of a TI, draws graphs slowly, runs the games of the PRGM menu, gets new games over the link cable from Trond’s calculator, and runs down its four AAA batteries. The state is kept in the browser. The screen only animates while it is on the screen and the tab is visible. With reduced motion, the cursor does not blink, the graph draws at once, the LCD has no shadow, and the games only go on while the visitor presses keys. The TI-83 has no speaker, so it makes no sound.
//
// The calculator is set up by one function, with the element (for its helpers, like `say()`, `on()`, and `loop()`) and its parts, as its screens, its games, and the buttons around it share the state of the calculator.
const randomItem = items => items[Math.floor(Math.random() * items.length)];

const randomInteger = (minimum, maximum) => minimum + Math.floor(Math.random() * (maximum - minimum + 1));

const clamp = (value, minimum, maximum) => Math.min(Math.max(value, minimum), maximum);

// Shows a toggle button as pressed, for screen readers and for the style.
const setPressed = (button, isPressed) => {
	button.setAttribute('aria-pressed', String(isPressed));
	button.dataset.state = isPressed ? 'on' : '';
};

const width = 96;
const height = 64;
const columns = 16;
const rows = 8;

// MARK: Fonts

// The big font of the home screen and the menus: 5 × 7 pixels in a cell of 6 × 8, so 16 characters fit on a line and 8 lines on the screen. Each glyph is its rows, from the top.
const largeGlyphRows = {
	' ': '00000 00000 00000 00000 00000 00000 00000',
	0: '01110 10001 10011 10101 11001 10001 01110',
	1: '00100 01100 00100 00100 00100 00100 01110',
	2: '01110 10001 00001 00010 00100 01000 11111',
	3: '11111 00010 00100 00010 00001 10001 01110',
	4: '00010 00110 01010 10010 11111 00010 00010',
	5: '11111 10000 11110 00001 00001 10001 01110',
	6: '00110 01000 10000 11110 10001 10001 01110',
	7: '11111 00001 00010 00100 01000 01000 01000',
	8: '01110 10001 10001 01110 10001 10001 01110',
	9: '01110 10001 10001 01111 00001 00010 01100',
	A: '01110 10001 10001 10001 11111 10001 10001',
	B: '11110 10001 10001 11110 10001 10001 11110',
	C: '01110 10001 10000 10000 10000 10001 01110',
	D: '11100 10010 10001 10001 10001 10010 11100',
	E: '11111 10000 10000 11110 10000 10000 11111',
	F: '11111 10000 10000 11110 10000 10000 10000',
	G: '01110 10001 10000 10111 10001 10001 01111',
	H: '10001 10001 10001 11111 10001 10001 10001',
	I: '01110 00100 00100 00100 00100 00100 01110',
	J: '00111 00010 00010 00010 00010 10010 01100',
	K: '10001 10010 10100 11000 10100 10010 10001',
	L: '10000 10000 10000 10000 10000 10000 11111',
	M: '10001 11011 10101 10101 10001 10001 10001',
	N: '10001 10001 11001 10101 10011 10001 10001',
	O: '01110 10001 10001 10001 10001 10001 01110',
	P: '11110 10001 10001 11110 10000 10000 10000',
	Q: '01110 10001 10001 10001 10101 10010 01101',
	R: '11110 10001 10001 11110 10100 10010 10001',
	S: '01111 10000 10000 01110 00001 00001 11110',
	T: '11111 00100 00100 00100 00100 00100 00100',
	U: '10001 10001 10001 10001 10001 10001 01110',
	V: '10001 10001 10001 10001 10001 01010 00100',
	W: '10001 10001 10001 10101 10101 10101 01010',
	X: '10001 10001 01010 00100 01010 10001 10001',
	Y: '10001 10001 10001 01010 00100 00100 00100',
	Z: '11111 00001 00010 00100 01000 10000 11111',
	a: '00000 00000 01110 00001 01111 10001 01111',
	b: '10000 10000 10110 11001 10001 10001 11110',
	c: '00000 00000 01110 10000 10000 10001 01110',
	d: '00001 00001 01101 10011 10001 10001 01111',
	e: '00000 00000 01110 10001 11111 10000 01110',
	f: '00110 01001 01000 11100 01000 01000 01000',
	g: '00000 01111 10001 10001 01111 00001 01110',
	h: '10000 10000 10110 11001 10001 10001 10001',
	i: '00100 00000 01100 00100 00100 00100 01110',
	j: '00010 00000 00110 00010 00010 10010 01100',
	k: '10000 10000 10010 10100 11000 10100 10010',
	l: '01100 00100 00100 00100 00100 00100 01110',
	m: '00000 00000 11010 10101 10101 10001 10001',
	n: '00000 00000 10110 11001 10001 10001 10001',
	o: '00000 00000 01110 10001 10001 10001 01110',
	p: '00000 00000 11110 10001 11110 10000 10000',
	q: '00000 00000 01101 10011 01111 00001 00001',
	r: '00000 00000 10110 11001 10000 10000 10000',
	s: '00000 00000 01110 10000 01110 00001 11110',
	t: '01000 01000 11100 01000 01000 01001 00110',
	u: '00000 00000 10001 10001 10001 10011 01101',
	v: '00000 00000 10001 10001 10001 01010 00100',
	w: '00000 00000 10001 10001 10101 10101 01010',
	x: '00000 00000 10001 01010 00100 01010 10001',
	y: '00000 00000 10001 10001 01111 00001 01110',
	z: '00000 00000 11111 00010 00100 01000 11111',
	'.': '00000 00000 00000 00000 00000 01100 01100',
	',': '00000 00000 00000 00000 01100 00100 01000',
	'(': '00010 00100 01000 01000 01000 00100 00010',
	')': '01000 00100 00010 00010 00010 00100 01000',
	'{': '00010 00100 00100 01000 00100 00100 00010',
	'}': '01000 00100 00100 00010 00100 00100 01000',
	'[': '01110 01000 01000 01000 01000 01000 01110',
	']': '01110 00010 00010 00010 00010 00010 01110',
	'+': '00000 00100 00100 11111 00100 00100 00000',
	'-': '00000 00000 00000 11111 00000 00000 00000',
	'*': '00000 10001 01010 00100 01010 10001 00000',
	'/': '00000 00001 00010 00100 01000 10000 00000',
	'\\': '00000 10000 01000 00100 00010 00001 00000',
	'^': '00100 01010 10001 00000 00000 00000 00000',
	'=': '00000 00000 11111 00000 11111 00000 00000',
	'<': '00010 00100 01000 10000 01000 00100 00010',
	'>': '01000 00100 00010 00001 00010 00100 01000',
	':': '00000 01100 01100 00000 01100 01100 00000',
	'?': '01110 10001 00001 00010 00100 00000 00100',
	'!': '00100 00100 00100 00100 00100 00000 00100',
	'"': '01010 01010 01010 00000 00000 00000 00000',
	'\'': '00100 00100 01000 00000 00000 00000 00000',
	'_': '00000 00000 00000 00000 00000 00000 11111',
	'|': '00100 00100 00100 00100 00100 00100 00100',
	'#': '01010 01010 11111 01010 11111 01010 01010',
	'%': '11000 11001 00010 00100 01000 10011 00011',
	'θ': '01110 10001 10001 11111 10001 10001 01110',
	'π': '00000 00000 11111 01010 01010 01010 10011',
	'√': '00111 00100 00100 00100 10100 01100 00100',
	'²': '01100 10010 00100 01000 11110 00000 00000',
	'³': '11100 00010 01100 00010 11100 00000 00000',
	'¹': '00001 11011 00001 00001 00001 00000 00000',
	'⁻': '00000 00000 01110 00000 00000 00000 00000',
	'ᴇ': '00000 00000 01110 01000 01100 01000 01110',
	'→': '00000 00100 00010 11111 00010 00100 00000',
	'▸': '10000 11000 11100 11110 11100 11000 10000',
	'▪': '00000 00000 01110 01110 01110 00000 00000',
	'↓': '00100 00100 00100 00100 10101 01110 00100',
	'↑': '00100 01110 10101 00100 00100 00100 00100',
	'Δ': '00000 00100 00100 01010 01010 10001 11111',
	'…': '00000 00000 00000 00000 00000 00000 10101',
	'█': '11111 11111 11111 11111 11111 11111 11111',
	'·': '00000 00000 00000 00100 00000 00000 00000',
	'≠': '00000 00001 11111 00100 11111 10000 00000',
	'≥': '01000 00100 00010 00100 01000 00000 11111',
	'≤': '00010 00100 01000 00100 00010 00000 11111',
	'°': '01100 10010 10010 01100 00000 00000 00000',
	'χ': '00000 00000 10001 01010 00100 01010 10001',
};

// The small font of the graph screen: 3 pixels wide for most characters, and 5 tall.
const smallGlyphRows = {
	' ': '0 0 0 0 0',
	0: '010 101 101 101 010',
	1: '010 110 010 010 111',
	2: '110 001 010 100 111',
	3: '110 001 010 001 110',
	4: '101 101 111 001 001',
	5: '111 100 110 001 110',
	6: '011 100 110 101 010',
	7: '111 001 010 100 100',
	8: '010 101 010 101 010',
	9: '010 101 011 001 110',
	A: '010 101 111 101 101',
	B: '110 101 110 101 110',
	C: '011 100 100 100 011',
	D: '110 101 101 101 110',
	E: '111 100 110 100 111',
	F: '111 100 110 100 100',
	G: '011 100 101 101 011',
	H: '101 101 111 101 101',
	I: '111 010 010 010 111',
	J: '001 001 001 101 010',
	K: '101 101 110 101 101',
	L: '100 100 100 100 111',
	M: '10001 11011 10101 10001 10001',
	N: '1001 1101 1011 1001 1001',
	O: '010 101 101 101 010',
	P: '110 101 110 100 100',
	Q: '010 101 101 110 011',
	R: '110 101 110 101 101',
	S: '011 100 010 001 110',
	T: '111 010 010 010 010',
	U: '101 101 101 101 111',
	V: '101 101 101 101 010',
	W: '10001 10001 10101 10101 01010',
	X: '101 101 010 101 101',
	Y: '101 101 010 010 010',
	Z: '111 001 010 100 111',
	'.': '0 0 0 0 1',
	',': '00 00 00 01 10',
	':': '0 1 0 1 0',
	'!': '1 1 1 0 1',
	'?': '110 001 010 000 010',
	'-': '000 000 111 000 000',
	'⁻': '00 00 11 00 00',
	'=': '000 111 000 111 000',
	'+': '000 010 111 010 000',
	'*': '000 101 010 101 000',
	'/': '001 001 010 100 100',
	'^': '010 101 000 000 000',
	'(': '01 10 10 10 01',
	')': '10 01 01 01 10',
	'²': '110 001 010 111 000',
	'³': '110 011 001 110 000',
	'¹': '0001 1101 0001 0001 0000',
	'√': '0011 0010 1010 0110 0010',
	'π': '1111 0110 0110 0110 0110',
	'θ': '010 101 111 101 010',
	'ᴇ': '000 111 110 100 111',
	'→': '0010 1111 0010 0000 0000',
	'"': '101 101 000 000 000',
	'\'': '1 1 0 0 0',
	'▸': '100 110 111 110 100',
	'<': '001 010 100 010 001',
	'>': '100 010 001 010 100',
};

const parseGlyph = rowsText => {
	const glyphRows = rowsText.split(' ');
	return {
		width: glyphRows[0].length,
		rows: glyphRows.map(row => [...row].map(bit => bit === '1')),
	};
};

const largeGlyphs = new Map(Object.entries(largeGlyphRows).map(([character, rowsText]) => [character, parseGlyph(rowsText)]));
const smallGlyphs = new Map(Object.entries(smallGlyphRows).map(([character, rowsText]) => [character, parseGlyph(rowsText)]));

// The small font draws everything in capitals, and the capitals of θ and π are other characters.
smallGlyphs.set('Θ', smallGlyphs.get('θ'));
smallGlyphs.set('Π', smallGlyphs.get('π'));

// The subscript digits of “Y₁”, made from the small digits at the bottom of a big cell.
for (const [index, subscript] of [...'₀₁₂₃₄₅₆₇₈₉'].entries()) {
	const digit = smallGlyphs.get(String(index));
	largeGlyphs.set(subscript, {
		width: 5,
		rows: [[], [], ...digit.rows.map(row => [false, ...row])],
	});
}

const unknownGlyph = largeGlyphs.get('?');

// MARK: The display

// A screen of 96 × 64 pixels, which the screens draw on. The calculator has one, and Trond’s has one.
class Display {
	constructor() {
		this.pixels = new Uint8Array(width * height);
	}

	clear() {
		this.pixels.fill(0);
	}

	set(x, y, isOn = true) {
		x = Math.round(x);
		y = Math.round(y);
		if (x >= 0 && x < width && y >= 0 && y < height) {
			this.pixels[(y * width) + x] = isOn ? 1 : 0;
		}
	}

	invert(x, y) {
		if (x >= 0 && x < width && y >= 0 && y < height) {
			this.pixels[(y * width) + x] ^= 1;
		}
	}

	fill(x, y, fillWidth, fillHeight, isOn = true) {
		for (let row = y; row < y + fillHeight; row++) {
			for (let column = x; column < x + fillWidth; column++) {
				this.set(column, row, isOn);
			}
		}
	}

	invertRectangle(x, y, rectangleWidth, rectangleHeight) {
		for (let row = y; row < y + rectangleHeight; row++) {
			for (let column = x; column < x + rectangleWidth; column++) {
				this.invert(column, row);
			}
		}
	}

	line(fromX, fromY, toX, toY, isOn = true) {
		fromX = Math.round(fromX);
		fromY = Math.round(fromY);
		toX = Math.round(toX);
		toY = Math.round(toY);
		const deltaX = Math.abs(toX - fromX);
		const deltaY = -Math.abs(toY - fromY);
		const stepX = fromX < toX ? 1 : -1;
		const stepY = fromY < toY ? 1 : -1;
		let error = deltaX + deltaY;
		for (let guard = 0; guard < 500; guard++) {
			this.set(fromX, fromY, isOn);
			if (fromX === toX && fromY === toY) {
				break;
			}

			const doubled = 2 * error;
			if (doubled >= deltaY) {
				error += deltaY;
				fromX += stepX;
			}

			if (doubled <= deltaX) {
				error += deltaX;
				fromY += stepY;
			}
		}
	}

	rectangle(x, y, rectangleWidth, rectangleHeight) {
		this.line(x, y, x + rectangleWidth - 1, y);
		this.line(x, y + rectangleHeight - 1, x + rectangleWidth - 1, y + rectangleHeight - 1);
		this.line(x, y, x, y + rectangleHeight - 1);
		this.line(x + rectangleWidth - 1, y, x + rectangleWidth - 1, y + rectangleHeight - 1);
	}

	circle(centerX, centerY, radius) {
		const steps = Math.max(12, Math.round(radius * 8));
		for (let step = 0; step < steps; step++) {
			const angle = (step / steps) * Math.PI * 2;
			this.set(centerX + (Math.cos(angle) * radius), centerY + (Math.sin(angle) * radius));
		}
	}

	// A sprite of rows like `'.##.'`, where `#` is a dark pixel.
	sprite(x, y, spriteRows) {
		for (const [row, text] of spriteRows.entries()) {
			for (const [column, character] of [...text].entries()) {
				if (character === '#') {
					this.set(x + column, y + row);
				}
			}
		}
	}

	// A character of the big font in its cell, by column and row, which is inverted for highlights, like the “1:” of the chosen menu item.
	character(column, row, character, isInverted = false) {
		const x = column * 6;
		const y = row * 8;
		const glyph = largeGlyphs.get(character) ?? unknownGlyph;
		this.fill(x, y, 6, 8, false);
		for (const [glyphRow, bits] of glyph.rows.entries()) {
			for (const [glyphColumn, isOn] of bits.entries()) {
				if (isOn) {
					this.set(x + glyphColumn, y + glyphRow);
				}
			}
		}

		if (isInverted) {
			this.invertRectangle(x, y, 6, 8);
		}
	}

	text(column, row, text, isInverted = false) {
		for (const [index, character] of [...text].entries()) {
			if (column + index < columns) {
				this.character(column + index, row, character, isInverted);
			}
		}
	}

	// Text in the small font at a pixel position, with the pixels behind it cleared, like the TI does. Returns the width.
	smallText(x, y, text, {isErasing = true} = {}) {
		let cursor = x;
		for (const character of String(text).toUpperCase()) {
			const glyph = smallGlyphs.get(character) ?? smallGlyphs.get('?');
			if (isErasing) {
				this.fill(cursor, y - 1, glyph.width + 1, 7, false);
			}

			for (const [glyphRow, bits] of glyph.rows.entries()) {
				for (const [glyphColumn, isOn] of bits.entries()) {
					if (isOn) {
						this.set(cursor + glyphColumn, y + glyphRow);
					}
				}
			}

			cursor += glyph.width + 1;
		}

		return cursor - x;
	}
}

const smallTextWidth = text => {
	let total = 0;
	for (const character of String(text).toUpperCase()) {
		total += (smallGlyphs.get(character) ?? smallGlyphs.get('?')).width + 1;
	}

	return total;
};

// Paints a display on a canvas, at four canvas pixels for each pixel of the LCD: a dark square with a lighter gap, and a faint grid of the pixels that are off, like a real LCD. The intensity of each pixel follows the display slowly, so a moving thing leaves a shadow, like on the slow LCD of the TI.
const makePainter = targetCanvas => {
	const targetContext = targetCanvas.getContext('2d');
	const image = targetContext.createImageData(targetCanvas.width, targetCanvas.height);
	const words = new Uint32Array(image.data.buffer);
	const intensity = new Float32Array(width * height);
	const scale = targetCanvas.width / width;
	const background = [169, 181, 151];
	const ink = [24, 32, 28];
	const levels = 64;

	const color = alpha => {
		const [red, green, blue] = background.map((channel, index) => Math.round(channel + ((ink[index] - channel) * alpha)));
		// The canvas stores the bytes as red, green, blue, and alpha, which is the reverse order in a little-endian word.
		return ((255 << 24) | (blue << 16) | (green << 8) | red) >>> 0;
	};

	return {
		// Paints the display and returns whether the pixels are still fading, so the caller paints again on the next frame.
		paint(display, {onAlpha, offAlpha, isGhosting}) {
			const dotColors = [];
			const gapColors = [];
			for (let level = 0; level <= levels; level++) {
				const alpha = offAlpha + ((onAlpha - offAlpha) * (level / levels));
				dotColors.push(color(alpha));
				gapColors.push(color((alpha * 0.28) + (offAlpha * 0.2)));
			}

			let isFading = false;
			for (let index = 0; index < intensity.length; index++) {
				const target = display.pixels[index];
				if (isGhosting) {
					const difference = target - intensity[index];
					if (Math.abs(difference) > 0.02) {
						intensity[index] += difference * 0.42;
						isFading = true;
					} else {
						intensity[index] = target;
					}
				} else {
					intensity[index] = target;
				}
			}

			const rowWidth = targetCanvas.width;
			for (let y = 0; y < height; y++) {
				for (let x = 0; x < width; x++) {
					const level = Math.round(intensity[(y * width) + x] * levels);
					const dot = dotColors[level];
					const gap = gapColors[level];
					const start = (y * scale * rowWidth) + (x * scale);
					for (let subRow = 0; subRow < scale; subRow++) {
						const rowStart = start + (subRow * rowWidth);
						for (let subColumn = 0; subColumn < scale; subColumn++) {
							words[rowStart + subColumn] = subRow === scale - 1 || subColumn === scale - 1 ? gap : dot;
						}
					}
				}
			}

			targetContext.putImageData(image, 0, 0);
			return isFading;
		},
	};
};

// MARK: Memory

// My games, as they are on my calculator when the visitor comes.
const myPrograms = ['PHOENIX', 'WAFFLRUN', 'SNAKE', 'QUIZ'];

// The free memory after a reset, in bytes, like on the real one.
const totalMemory = 27_000;

const emptyFunctions = () => Array.from({length: 7}, () => ({tokens: [], isEnabled: true}));

const standardWindow = () => ({xMinimum: -10, xMaximum: 10, xScale: 1, yMinimum: -10, yMaximum: 10, yScale: 1});

const defaultSettings = () => ({notation: 'normal', digits: 'float', angle: 'radian', graphType: 'func', drawStyle: 'connected', order: 'sequential', numbers: 'real', split: 'full'});

const defaultMemory = () => {
	const functions = emptyFunctions();
	functions[0].tokens = ['X', '²', '-', '4'];
	functions[1].tokens = ['3', 'sin(', 'X', ')'];
	return {
		programs: [...myPrograms],
		functions,
		window: standardWindow(),
		table: {start: 0, step: 1},
		variables: {},
		answer: 0,
		settings: defaultSettings(),
		history: [
			{text: '7*8', align: 'left'},
			{text: '56', align: 'right'},
			{text: '√(2', align: 'left'},
			{text: '1.414213562', align: 'right'},
		],
		entries: [['7', '*', '8'], ['√(', '2']],
	};
};

const setUpCalculator = (ti83, {calculator: calculatorElement, screen: canvas, flip: flipButton, teacher: teacherButton, link: linkButton, batteries: batteriesButton, upsideDown: upsideDownLine, trond: trondPanel, trondScreen: trondCanvas, receive: receiveButton, batteryDoor, backup: backupButton, closeDoor: closeDoorButton}) => {
	const keyButtons = [...ti83.querySelectorAll('[data-ti83-key]')];
	const numberButtons = [...ti83.querySelectorAll('[data-ti83-number]')];
	const sendButtons = [...ti83.querySelectorAll('[data-ti83-send]')];
	const batteryButtons = [...ti83.querySelectorAll('[data-ti83-battery]')];

	// The memory of the calculator is lost with a reset, but the contrast, the batteries, and the high scores are not.
	const savedState = ti83.stored('state', {});
	let memory = {...defaultMemory(), ...savedState.memory};
	const hardware = {
		contrast: 5,
		batteries: [64, 61, 66, 59],
		isBackupIn: true,
		highScores: {},
		...savedState.hardware,
	};

	const isObject = value => typeof value === 'object' && value !== null && !Array.isArray(value);
	const isTokenList = value => Array.isArray(value) && value.every(token => typeof token === 'string');

	// Old saved state can be from an older version of the calculator, so anything that does not look right starts over.
	const isValidMemory = Array.isArray(memory.programs)
		&& Array.isArray(memory.functions)
		&& memory.functions.length === 7
		&& memory.functions.every(entry => isTokenList(entry?.tokens))
		&& Array.isArray(memory.history)
		&& memory.history.every(entry => typeof entry?.text === 'string')
		&& Array.isArray(memory.entries)
		&& memory.entries.every(entry => isTokenList(entry))
		&& Object.keys(standardWindow()).every(key => Number.isFinite(memory.window?.[key]))
		&& Number.isFinite(memory.table?.start)
		&& Number.isFinite(memory.table?.step)
		&& Number.isFinite(memory.answer)
		&& isObject(memory.variables)
		&& Object.values(memory.variables).every(value => Number.isFinite(value));
	if (!isValidMemory) {
		memory = defaultMemory();
	}

	memory.settings = {...defaultSettings(), ...(isObject(memory.settings) ? memory.settings : {})};
	if (!Array.isArray(hardware.batteries) || hardware.batteries.length !== 4 || !hardware.batteries.every(charge => charge === null || Number.isFinite(charge))) {
		hardware.batteries = [64, 61, 66, 59];
	}

	hardware.contrast = Number.isInteger(hardware.contrast) ? clamp(hardware.contrast, 0, 9) : 5;
	hardware.isBackupIn = hardware.isBackupIn !== false;
	if (!isObject(hardware.highScores)) {
		hardware.highScores = {};
	}

	let saveTimer;
	const saveSoon = () => {
		clearTimeout(saveTimer);
		saveTimer = setTimeout(() => {
			ti83.store('state', {memory, hardware});
		}, 400);
	};

	// MARK: Numbers

	class CalculatorError extends Error {
		constructor(kind, position) {
			super(kind);
			this.kind = kind;
			this.position = position;
		}
	}

	// The errors where the TI offers “2:Goto”, which puts the cursor where the problem is.
	const errorsWithGoto = new Set(['SYNTAX', 'DIVIDE BY 0', 'DOMAIN', 'NONREAL ANS', 'OVERFLOW', 'ARGUMENT', 'BREAK']);

	const checked = (value, position) => {
		if (Number.isNaN(value)) {
			throw new CalculatorError('DOMAIN', position);
		}

		if (!Number.isFinite(value) || Math.abs(value) >= 1e100) {
			throw new CalculatorError('OVERFLOW', position);
		}

		return value;
	};

	// Formats a number like the TI: at most 10 digits, no zero before the point (“.5”), the small raised minus of negative numbers, and the small E of scientific notation for very large and very small numbers.
	const formatNumber = (value, {significantDigits = 10, settings = memory.settings} = {}) => {
		if (Object.is(value, -0)) {
			value = 0;
		}

		const rounded = Number(value.toPrecision(significantDigits));
		const absolute = Math.abs(rounded);
		const isFixed = settings.digits !== 'float';
		const isScientific = settings.notation !== 'normal' || (absolute !== 0 && (absolute >= 10 ** significantDigits || absolute < 0.001));
		let text;
		if (isScientific && rounded !== 0) {
			let exponent = Math.floor(Math.log10(absolute));
			if (settings.notation === 'eng') {
				exponent = Math.floor(exponent / 3) * 3;
			}

			let mantissa = Number((rounded / (10 ** exponent)).toPrecision(significantDigits));
			if (Math.abs(mantissa) >= (settings.notation === 'eng' ? 1000 : 10)) {
				exponent += settings.notation === 'eng' ? 3 : 1;
				mantissa /= settings.notation === 'eng' ? 1000 : 10;
			}

			let mantissaText = isFixed ? mantissa.toFixed(settings.digits) : String(Number(mantissa.toPrecision(significantDigits)));
			// Fix can round 9.999 up to 10.00, which is 1.00 with the next exponent.
			if (isFixed && Math.abs(Number(mantissaText)) >= (settings.notation === 'eng' ? 1000 : 10)) {
				exponent += settings.notation === 'eng' ? 3 : 1;
				mantissaText = (mantissa / (settings.notation === 'eng' ? 1000 : 10)).toFixed(settings.digits);
			}

			text = `${mantissaText}ᴇ${exponent < 0 ? '⁻' : ''}${Math.abs(exponent)}`;
		} else if (isScientific) {
			text = isFixed ? `${(0).toFixed(settings.digits)}ᴇ0` : '0';
		} else {
			text = isFixed ? rounded.toFixed(settings.digits) : String(rounded);
		}

		if (text.startsWith('0.')) {
			text = text.slice(1);
		} else if (text.startsWith('-0.')) {
			text = `-${text.slice(2)}`;
		}

		return text.replaceAll('-', '⁻');
	};

	// A short number for the graph screen and the table, which has less room.
	const formatShort = (value, maximumLength) => {
		if (!Number.isFinite(value)) {
			return 'ERROR';
		}

		for (let digits = 8; digits >= 1; digits--) {
			const text = formatNumber(value, {significantDigits: digits, settings: defaultSettings()});
			if ([...text].length <= maximumLength) {
				return text;
			}
		}

		return formatNumber(value, {significantDigits: 1, settings: {...defaultSettings(), notation: 'sci'}});
	};

	// ▸Frac: the fraction of a decimal, with a denominator of at most 9999, or the decimal when there is none. Kids used it for the fraction homework.
	const formatFraction = value => {
		const absolute = Math.abs(value);
		if (Number.isInteger(value)) {
			return formatNumber(value);
		}

		let [previousNumerator, numerator, previousDenominator, denominator] = [0, 1, 1, 0];
		let rest = absolute;
		for (let step = 0; step < 24; step++) {
			const whole = Math.floor(rest);
			[previousNumerator, numerator] = [numerator, (whole * numerator) + previousNumerator];
			[previousDenominator, denominator] = [denominator, (whole * denominator) + previousDenominator];
			if (Math.abs((numerator / denominator) - absolute) < 1e-11 * Math.max(1, absolute) || rest === whole) {
				break;
			}

			rest = 1 / (rest - whole);
		}

		if (numerator === 0 || denominator > 9999 || Math.abs((numerator / denominator) - absolute) > 1e-9 * Math.max(1, absolute)) {
			return formatNumber(value);
		}

		return `${value < 0 ? '⁻' : ''}${numerator}/${denominator}`;
	};

	// What a line of the screen says, for screen readers.
	const speakable = text => text
		.replaceAll('⁻', '−')
		.replaceAll('²', ' squared')
		.replaceAll('³', ' cubed')
		.replaceAll('¹', ' inverse')
		.replaceAll('ᴇ', ' times 10 to the ')
		.replaceAll('√(', 'square root of (')
		.replaceAll('*', ' × ')
		.replaceAll('/', ' ÷ ')
		.replaceAll('→', ' store in ');

	// MARK: The parser

	const isDigitToken = token => token !== undefined && token.length === 1 && token >= '0' && token <= '9';

	const variableTokens = new Set('ABCDEFGHIJKLMNOPQRSTUVWXYZθ');

	// The functions, which open their parenthesis with the name, like on the TI.
	const functionTokens = new Map([
		['sin(', 'sin'],
		['cos(', 'cos'],
		['tan(', 'tan'],
		['sin¹(', 'asin'],
		['cos¹(', 'acos'],
		['tan¹(', 'atan'],
		['√(', 'sqrt'],
		['³√(', 'cbrt'],
		['log(', 'log'],
		['ln(', 'ln'],
		['10^(', 'exp10'],
		['e^(', 'exp'],
		['abs(', 'abs'],
		['round(', 'round'],
		['iPart(', 'iPart'],
		['fPart(', 'fPart'],
		['int(', 'int'],
		['randInt(', 'randInt'],
	]);

	const startsValue = token => token !== undefined && (
		isDigitToken(token)
		|| token === '.'
		|| token === 'ᴇ'
		|| token === 'π'
		|| token === 'e'
		|| token === 'Ans'
		|| token === 'rand'
		|| token === '('
		|| token === '⁻'
		|| variableTokens.has(token)
		|| functionTokens.has(token)
	);

	// The longest line that the parser takes. The parser and the calculation go down one level for each parenthesis and each operator, so a very long line would run out of stack, and the TI says ERR:MEMORY for it too.
	const maximumTokens = 300;

	// Parses tokens with the order of operations of the TI-83: first the functions after a value (x², x⁻¹, !), then ^ from left to right, then the negation, so −2² is −4, then × and ÷ with implied multiplication at the same level, like 2π, and last + and −. Closing parentheses at the end can be left out.
	const parse = tokens => {
		if (tokens.length > maximumTokens) {
			throw new CalculatorError('MEMORY', 0);
		}

		let position = 0;
		const peek = () => tokens[position];
		const fail = () => {
			throw new CalculatorError('SYNTAX', Math.min(position, tokens.length));
		};

		const parseNumber = () => {
			const start = position;
			let text = '';
			let hasPoint = false;
			let hasDigits = false;
			while (isDigitToken(peek()) || peek() === '.') {
				if (peek() === '.') {
					if (hasPoint) {
						fail();
					}

					hasPoint = true;
				} else {
					hasDigits = true;
				}

				text += peek();
				position++;
			}

			if (peek() === 'ᴇ') {
				position++;
				let exponent = '';
				if (peek() === '⁻') {
					exponent = '-';
					position++;
				}

				let hasExponentDigits = false;
				while (isDigitToken(peek())) {
					exponent += peek();
					hasExponentDigits = true;
					position++;
				}

				if (!hasExponentDigits) {
					fail();
				}

				text = `${hasDigits ? text : '1'}e${exponent}`;
				hasDigits = true;
			}

			if (!hasDigits) {
				fail();
			}

			return {type: 'number', value: Number(text), position: start};
		};

		const parseArguments = () => {
			const list = [parseSum()];
			while (peek() === ',') {
				position++;
				list.push(parseSum());
			}

			return list;
		};

		// The closing parenthesis can be left out at the end, and before STO▶ and ▸Frac, like on the TI.
		const closeParenthesis = () => {
			if (peek() === ')') {
				position++;
			} else if (peek() !== undefined && !['→', '▸Frac', '▸Dec'].includes(peek())) {
				fail();
			}
		};

		const parsePrimary = () => {
			const token = peek();
			const start = position;
			if (token === undefined) {
				fail();
			}

			if (isDigitToken(token) || token === '.' || token === 'ᴇ') {
				return parseNumber();
			}

			position++;
			if (token === 'π') {
				return {type: 'number', value: Math.PI, position: start};
			}

			if (token === 'e') {
				return {type: 'number', value: Math.E, position: start};
			}

			if (token === 'Ans') {
				return {type: 'answer', position: start};
			}

			if (token === 'rand') {
				return {type: 'random', position: start};
			}

			if (variableTokens.has(token)) {
				return {type: 'variable', name: token, position: start};
			}

			if (token === '(') {
				const inner = parseSum();
				closeParenthesis();
				return inner;
			}

			if (functionTokens.has(token)) {
				const list = parseArguments();
				closeParenthesis();
				return {type: 'call', name: functionTokens.get(token), arguments: list, position: start};
			}

			position = start;
			fail();
		};

		const parsePostfix = () => {
			let node = parsePrimary();
			while (['²', '¹', '³', '!'].includes(peek())) {
				node = {type: 'postfix', operator: peek(), operand: node, position};
				position++;
			}

			return node;
		};

		const parsePowerOperand = () => {
			if (peek() === '⁻') {
				const start = position;
				position++;
				return {type: 'negate', operand: parsePowerOperand(), position: start};
			}

			return parsePostfix();
		};

		const parsePower = () => {
			let node = parsePostfix();
			while (peek() === '^') {
				const start = position;
				position++;
				node = {type: 'binary', operator: '^', left: node, right: parsePowerOperand(), position: start};
			}

			return node;
		};

		const parseNegation = () => {
			if (peek() === '⁻') {
				const start = position;
				position++;
				return {type: 'negate', operand: parseNegation(), position: start};
			}

			return parsePower();
		};

		const parseProduct = () => {
			let node = parseNegation();
			while (true) {
				const token = peek();
				const start = position;
				if (token === '*' || token === '/' || token === ' nPr ' || token === ' nCr ') {
					position++;
					node = {type: 'binary', operator: token, left: node, right: parseNegation(), position: start};
				} else if (startsValue(token)) {
					node = {type: 'binary', operator: '*', left: node, right: parseNegation(), position: start};
				} else {
					return node;
				}
			}
		};

		const parseSum = () => {
			let node = parseProduct();
			while (peek() === '+' || peek() === '-') {
				const start = position;
				const operator = peek();
				position++;
				node = {type: 'binary', operator, left: node, right: parseProduct(), position: start};
			}

			return node;
		};

		const expression = parseSum();
		let conversion;
		if (peek() === '▸Frac' || peek() === '▸Dec') {
			conversion = peek();
			position++;
		}

		let store;
		if (peek() === '→') {
			position++;
			if (!variableTokens.has(peek())) {
				fail();
			}

			store = peek();
			position++;
		}

		if (position < tokens.length) {
			fail();
		}

		return {expression, conversion, store};
	};

	const toRadians = angle => memory.settings.angle === 'degree' ? angle * Math.PI / 180 : angle;
	const fromRadians = angle => memory.settings.angle === 'degree' ? angle * 180 / Math.PI : angle;

	// Trigonometry in binary has tiny errors, like sin(π) = 1.2ᴇ⁻16, which the TI shows as 0.
	const tidy = value => Math.abs(value) < 1e-13 ? 0 : value;

	const factorial = value => {
		let result = 1;
		for (let factor = 2; factor <= value; factor++) {
			result *= factor;
		}

		return result;
	};

	const callFunction = (name, values, position) => {
		const [value, second] = values;
		const expectedCount = name === 'randInt' ? 2 : (name === 'round' ? values.length : 1);
		if (values.length !== expectedCount || (name === 'round' && values.length > 2)) {
			throw new CalculatorError('ARGUMENT', position);
		}

		switch (name) {
			case 'sin': {
				return tidy(Math.sin(toRadians(value)));
			}

			case 'cos': {
				return tidy(Math.cos(toRadians(value)));
			}

			case 'tan': {
				if (Math.abs(Math.cos(toRadians(value))) < 1e-12) {
					throw new CalculatorError('DOMAIN', position);
				}

				return tidy(Math.tan(toRadians(value)));
			}

			case 'asin':
			case 'acos': {
				if (Math.abs(value) > 1) {
					throw new CalculatorError('DOMAIN', position);
				}

				return fromRadians(name === 'asin' ? Math.asin(value) : Math.acos(value));
			}

			case 'atan': {
				return fromRadians(Math.atan(value));
			}

			case 'sqrt': {
				if (value < 0) {
					throw new CalculatorError('NONREAL ANS', position);
				}

				return Math.sqrt(value);
			}

			case 'cbrt': {
				return Math.cbrt(value);
			}

			case 'log':
			case 'ln': {
				if (value === 0) {
					throw new CalculatorError('DOMAIN', position);
				}

				if (value < 0) {
					throw new CalculatorError('NONREAL ANS', position);
				}

				return name === 'log' ? Math.log10(value) : Math.log(value);
			}

			case 'exp10': {
				return 10 ** value;
			}

			case 'exp': {
				return Math.exp(value);
			}

			case 'abs': {
				return Math.abs(value);
			}

			case 'round': {
				const digits = second ?? 9;
				if (!Number.isInteger(digits) || digits < 0 || digits > 9) {
					throw new CalculatorError('DOMAIN', position);
				}

				return Number(value.toFixed(digits));
			}

			case 'iPart': {
				return Math.trunc(value);
			}

			case 'fPart': {
				return value - Math.trunc(value);
			}

			case 'int': {
				return Math.floor(value);
			}

			case 'randInt': {
				if (!Number.isInteger(value) || !Number.isInteger(second)) {
					throw new CalculatorError('DOMAIN', position);
				}

				return randomInteger(Math.min(value, second), Math.max(value, second));
			}

			default: {
				throw new CalculatorError('SYNTAX', position);
			}
		}
	};

	const power = (base, exponent, position) => {
		if (base === 0 && exponent === 0) {
			throw new CalculatorError('DOMAIN', position);
		}

		if (base === 0 && exponent < 0) {
			throw new CalculatorError('DIVIDE BY 0', position);
		}

		if (base < 0 && !Number.isInteger(exponent)) {
			// Like the TI-83, odd roots of negative numbers work, like (⁻8)^(1/3).
			const denominator = Math.round(1 / exponent);
			if (Math.abs((1 / exponent) - denominator) < 1e-9 && Math.abs(denominator) % 2 === 1) {
				return -((-base) ** exponent);
			}

			throw new CalculatorError('NONREAL ANS', position);
		}

		return base ** exponent;
	};

	const evaluate = (node, x) => {
		switch (node.type) {
			case 'number': {
				return node.value;
			}

			case 'answer': {
				return memory.answer;
			}

			case 'random': {
				return Math.random();
			}

			case 'variable': {
				if (node.name === 'X' && x !== undefined) {
					return x;
				}

				return memory.variables[node.name] ?? 0;
			}

			case 'negate': {
				return -evaluate(node.operand, x);
			}

			case 'postfix': {
				const value = evaluate(node.operand, x);
				switch (node.operator) {
					case '²': {
						return checked(value * value, node.position);
					}

					case '³': {
						return checked(value * value * value, node.position);
					}

					case '¹': {
						if (value === 0) {
							throw new CalculatorError('DIVIDE BY 0', node.position);
						}

						return 1 / value;
					}

					default: {
						if (!Number.isInteger(value) || value < 0) {
							throw new CalculatorError('DOMAIN', node.position);
						}

						// 70! is more than 1ᴇ100 already, so there is no need to count to a huge number.
						if (value > 69) {
							throw new CalculatorError('OVERFLOW', node.position);
						}

						return checked(factorial(value), node.position);
					}
				}
			}

			case 'binary': {
				const left = evaluate(node.left, x);
				const right = evaluate(node.right, x);
				switch (node.operator) {
					case '+': {
						return checked(left + right, node.position);
					}

					case '-': {
						return checked(left - right, node.position);
					}

					case '*': {
						return checked(left * right, node.position);
					}

					case '/': {
						if (right === 0) {
							throw new CalculatorError('DIVIDE BY 0', node.position);
						}

						return checked(left / right, node.position);
					}

					case ' nPr ':
					case ' nCr ': {
						if (!Number.isInteger(left) || !Number.isInteger(right) || left < 0 || right < 0) {
							throw new CalculatorError('DOMAIN', node.position);
						}

						if (right > left) {
							return 0;
						}

						// C(n, k) is C(n, n − k), and the smaller one takes fewer steps, so 1ᴇ15 nCr 1ᴇ15 is 1 and not an overflow on the way.
						const count = node.operator === ' nCr ' ? Math.min(right, left - right) : right;
						let result = 1;
						for (let step = 0; step < count && Number.isFinite(result); step++) {
							result *= left - step;
							if (node.operator === ' nCr ') {
								result /= step + 1;
							}
						}

						return checked(Math.round(result), node.position);
					}

					default: {
						return checked(power(left, right, node.position), node.position);
					}
				}
			}

			case 'call': {
				const values = node.arguments.map(argument => evaluate(argument, x));
				return checked(callFunction(node.name, values, node.position), node.position);
			}

			default: {
				throw new CalculatorError('SYNTAX', node.position);
			}
		}
	};

	// Calculates a line of the home screen, stores Ans and the variable of STO▶, and returns the text of the result.
	const calculate = tokens => {
		const statement = parse(tokens);
		const value = checked(evaluate(statement.expression), 0);
		memory.answer = value;
		if (statement.store) {
			memory.variables[statement.store] = value;
		}

		return statement.conversion === '▸Frac' ? formatFraction(value) : formatNumber(value);
	};

	// MARK: The runtime

	const display = new Display();
	const painter = makePainter(canvas);
	const trondDisplay = new Display();
	const trondPainter = makePainter(trondCanvas);

	let isOn = true;
	let modifier = '';
	let screen;
	let isBlinkOn = true;
	let blinkSeconds = 0;
	let busyPhase = 0;
	let busySeconds = 0;
	let contrastShownUntil = 0;
	let isDoorOpen = false;
	let isLinked = false;
	let isTeacherHere = false;
	let screenBeforeTeacher;
	let lastKeyTime = performance.now();
	let isDirty = true;
	let isFading = false;
	let isTrondDirty = true;

	const batteryCharge = () => {
		const present = hardware.batteries.filter(charge => charge !== null);
		return present.length < 4 ? 0 : Math.min(...present);
	};

	// The contrast that the visitor sees: the contrast setting, minus what the tired batteries take away.
	const effectiveContrast = () => {
		const charge = batteryCharge();
		const fade = charge < 40 ? (40 - charge) / 5 : 0;
		return hardware.contrast - fade;
	};

	const isCursorVisible = () => ti83.reducedMotion || isBlinkOn;

	const requestRender = () => {
		isDirty = true;
		wake();
	};

	const go = nextScreen => {
		screen?.leave?.();
		screen = nextScreen;
		screen.enter?.();
		isBlinkOn = true;
		blinkSeconds = 0;
		requestRender();
	};

	// Draws the cursor in a cell: a block, an underline while inserting, and with an arrow or an “A” in it while 2nd or ALPHA waits for the next key. It blinks with the character under it.
	const drawCursor = (target, column, row, underCharacter = ' ', isInserting = false) => {
		if (!isCursorVisible()) {
			target.character(column, row, underCharacter);
			return;
		}

		const cutout = modifier === '2nd' ? '↑' : (modifier === '' ? undefined : 'A');
		if (cutout) {
			target.character(column, row, '█');
			const glyph = largeGlyphs.get(cutout);
			for (const [glyphRow, bits] of glyph.rows.entries()) {
				for (const [glyphColumn, isSet] of bits.entries()) {
					if (isSet) {
						target.set((column * 6) + glyphColumn, (row * 8) + glyphRow, false);
					}
				}
			}
		} else if (isInserting) {
			target.character(column, row, underCharacter);
			target.fill(column * 6, (row * 8) + 6, 5, 1);
		} else {
			target.character(column, row, '█');
		}
	};

	// The busy indicator of the TI: a short dashed line in the top right corner, which moves while it works and stands still while it is paused.
	const drawBusyIndicator = (target, isPaused = false) => {
		for (let y = 0; y < 8; y++) {
			const isSet = isPaused ? y % 2 === 0 : (y + busyPhase) % 4 < 2;
			target.set(94, y, isSet);
			target.set(95, y, isSet);
		}
	};

	const render = () => {
		display.clear();
		if (isOn) {
			screen.draw(display);
			if (screen.isBusy?.()) {
				drawBusyIndicator(display, screen.isPaused?.());
			}

			if (performance.now() < contrastShownUntil) {
				display.character(15, 0, String(clamp(hardware.contrast, 0, 9)));
			}
		}

		const level = isOn ? clamp(effectiveContrast() / 9, 0, 1) : 0;
		isFading = painter.paint(display, {
			onAlpha: isOn ? clamp(0.08 + (level * 1.2), 0, 1) : 0,
			offAlpha: 0.035 + (Math.max(0, level - 0.6) * 0.5),
			isGhosting: !ti83.reducedMotion,
		});
	};

	const renderTrond = () => {
		trondDisplay.clear();
		drawTrond(trondDisplay);
		trondPainter.paint(trondDisplay, {onAlpha: 0.85, offAlpha: 0.035, isGhosting: false});
	};

	const needsFrames = () => isOn && !isDoorOpen && !ti83.reducedMotion;

	// The screen draws only when something changed, and runs while it blinks, draws a graph, runs a game, or fades.
	const screenLoop = ti83.loop(seconds => {
		if (isOn && !ti83.reducedMotion) {
			blinkSeconds += seconds;
			if (blinkSeconds >= 0.5) {
				blinkSeconds = 0;
				isBlinkOn = !isBlinkOn;
				isDirty = true;
			}

			busySeconds += seconds;
			if (busySeconds >= 0.1) {
				busySeconds = 0;
				busyPhase = (busyPhase + 1) % 4;
				if (screen.isBusy?.()) {
					isDirty = true;
				}

				if (trond.mode === 'transmitting') {
					isTrondDirty = true;
				}
			}
		}

		if (isOn && !isTeacherHere && screen.update?.(seconds)) {
			isDirty = true;
		}

		if (contrastShownUntil !== 0 && performance.now() >= contrastShownUntil) {
			contrastShownUntil = 0;
			isDirty = true;
		}

		if (isDirty || isFading) {
			isDirty = false;
			render();
		}

		if (isTrondDirty && isLinked) {
			isTrondDirty = false;
			renderTrond();
		}
	}, {while: () => needsFrames() || isFading || isDirty || contrastShownUntil !== 0});

	const wake = () => {
		screenLoop.start();

		// Trond’s screen draws once more, also while mine needs no frames, like when mine is off.
		if (isTrondDirty && isLinked) {
			screenLoop.requestStep();
		}
	};

	// MARK: Editing

	// A line that the visitor types into, as tokens, like the TI, where “sin(” is one token that DEL deletes at once. The TI types over what is under the cursor, until 2nd INS.
	const makeEditor = (tokens = []) => ({
		tokens,
		cursor: tokens.length,
		isInserting: false,
		type(token) {
			if (this.cursor < this.tokens.length && !this.isInserting) {
				this.tokens[this.cursor] = token;
			} else {
				this.tokens.splice(this.cursor, 0, token);
			}

			this.cursor++;
		},
		set(tokens, cursor = tokens.length) {
			this.tokens = tokens;
			this.cursor = clamp(cursor, 0, tokens.length);
			this.isInserting = false;
		},
		clear() {
			this.set([]);
		},
		// The shared keys of a line. Returns whether it used the key.
		handle(name) {
			if (name.startsWith('token:')) {
				this.type(name.slice('token:'.length));
				return true;
			}

			switch (name) {
				case 'del': {
					if (this.cursor < this.tokens.length) {
						this.tokens.splice(this.cursor, 1);
					} else if (this.tokens.length > 0) {
						this.tokens.pop();
						this.cursor = this.tokens.length;
					}

					return true;
				}

				case 'ins': {
					this.isInserting = !this.isInserting;
					return true;
				}

				case 'left': {
					this.cursor = Math.max(0, this.cursor - 1);
					this.isInserting = false;
					return true;
				}

				case 'right': {
					this.cursor = Math.min(this.tokens.length, this.cursor + 1);
					this.isInserting = false;
					return true;
				}

				case 'lineStart': {
					this.cursor = 0;
					return true;
				}

				case 'lineEnd': {
					this.cursor = this.tokens.length;
					return true;
				}

				default: {
					return false;
				}
			}
		},
		// The characters of the line, and the index of the character under the cursor.
		layout() {
			const characters = [];
			let cursorIndex;
			for (const [index, token] of this.tokens.entries()) {
				if (index === this.cursor) {
					cursorIndex = characters.length;
				}

				characters.push(...token);
			}

			return {characters, cursorIndex: cursorIndex ?? characters.length};
		},
	});

	const tokensText = tokens => tokens.join('');

	const wrap = characters => {
		const chunks = [];
		for (let index = 0; index < characters.length; index += columns) {
			chunks.push(characters.slice(index, index + columns));
		}

		return chunks.length === 0 ? [[]] : chunks;
	};

	// MARK: Home screen

	// The operators that start with Ans on an empty line, like on the TI, so 5 ENTER + 3 ENTER makes 8.
	const answerOperators = new Set(['+', '-', '*', '/', '^', '²', '¹', '³', '!', '→', '▸Frac', '▸Dec', ' nPr ', ' nCr ']);

	const pushHistory = (text, align = 'left') => {
		memory.history.push({text, align});
		memory.history = memory.history.slice(-24);
		saveSoon();
	};

	const addEntry = tokens => {
		memory.entries.push([...tokens]);
		memory.entries = memory.entries.slice(-10);
	};

	const home = {
		editor: makeEditor(),
		entryIndex: 0,
		insert(token) {
			if (this.editor.tokens.length === 0 && answerOperators.has(token)) {
				this.editor.type('Ans');
			}

			this.editor.type(token);
		},
		draw(target) {
			const lines = [];
			for (const entry of memory.history) {
				for (const chunk of wrap([...entry.text])) {
					lines.push({cells: entry.align === 'right' ? [...Array.from({length: columns - chunk.length}, () => ' '), ...chunk] : chunk});
				}
			}

			const {characters, cursorIndex} = this.editor.layout();
			const inputRows = Math.max(Math.ceil(characters.length / columns), Math.floor(cursorIndex / columns) + 1);
			for (let row = 0; row < inputRows; row++) {
				lines.push({cells: characters.slice(row * columns, (row + 1) * columns), inputRow: row});
			}

			for (const [row, line] of lines.slice(-rows).entries()) {
				for (const [column, character] of line.cells.entries()) {
					target.character(column, row, character);
				}

				if (line.inputRow === Math.floor(cursorIndex / columns)) {
					const column = cursorIndex % columns;
					drawCursor(target, column, row, line.cells[column] ?? ' ', this.editor.isInserting);
				}
			}
		},
		key(name) {
			if (name.startsWith('token:')) {
				this.insert(name.slice('token:'.length));
				this.entryIndex = 0;
				return true;
			}

			switch (name) {
				case 'enter': {
					this.run();
					return true;
				}

				case 'clear': {
					if (this.editor.tokens.length > 0) {
						this.editor.clear();
					} else {
						memory.history = [];
						saveSoon();
					}

					return true;
				}

				case 'entry': {
					// 2nd ENTRY brings back the last lines, one older line for each press.
					if (memory.entries.length > 0) {
						this.entryIndex = (this.entryIndex % memory.entries.length) + 1;
						this.editor.set([...memory.entries.at(-this.entryIndex)]);
					}

					return true;
				}

				case 'up':
				case 'down':
				case 'quit': {
					return true;
				}

				default: {
					return this.editor.handle(name);
				}
			}
		},
		run() {
			this.entryIndex = 0;
			let tokens = this.editor.tokens;
			if (tokens.length === 0) {
				// ENTER on an empty line does the last line again, like the TI.
				const last = memory.entries.at(-1);
				if (!last) {
					return;
				}

				tokens = [...last];
			}

			addEntry(tokens);
			if (tokens.length === 1 && tokens[0].startsWith('prgm')) {
				pushHistory(tokens[0]);
				this.editor.clear();
				runProgram(tokens[0].slice('prgm'.length));
				return;
			}

			try {
				const result = calculate(tokens);
				pushHistory(tokensText(tokens));
				pushHistory(result, 'right');
				this.editor.clear();
				ti83.say(upsideDownTip(result) ?? `${speakable(tokensText(tokens))} = ${speakable(result)}`);
			} catch (error) {
				if (!(error instanceof CalculatorError)) {
					throw error;
				}

				showError(error.kind, {
					onQuit: () => {
						this.editor.clear();
						go(home);
					},
					onGoto: () => {
						this.editor.set([...tokens], error.position);
						go(home);
					},
				});
			}
		},
	};

	// A tip instead of the answer when it makes a word upside down, like 7718.
	const upsideDownTip = result => {
		const reading = [...result].reverse().map(character => upsideDownLetters[character] ?? '?').join('').replaceAll('.', '');
		return /^[OIZEhSgLBG]{3,}$/u.test(reading) && !isFlipped ? `${speakable(result)}. Psst: turn it over! 🙃` : undefined;
	};

	// MARK: Error screens

	const errorHints = {
		SYNTAX: 'ERR:SYNTAX. Something is typed wrong. 2:Goto shows where.',
		'DIVIDE BY 0': 'ERR:DIVIDE BY 0. Herr Olsen says the world ends if you do that.',
		DOMAIN: 'ERR:DOMAIN. That number is not allowed there.',
		'NONREAL ANS': 'ERR:NONREAL ANS. The answer is not a real number. Chapter 9, nobody is there yet.',
		OVERFLOW: 'ERR:OVERFLOW. The number is too big, even for a TI. It stops at 9.999999999ᴇ99.',
		ARGUMENT: 'ERR:ARGUMENT. Wrong number of numbers in the parentheses.',
		BREAK: 'ERR:BREAK. The ON key stops a program.',
		MEMORY: 'ERR:MEMORY. My calculator is full! Delete a program in 2nd MEM, or type a shorter line.',
		'WINDOW RANGE': 'ERR:WINDOW RANGE. Xmin must be less than Xmax, and Ymin less than Ymax.',
		LINK: 'ERR:LINK. The other calculator is not ready.',
		STAT: 'ERR:STAT. There are no statistics in it. There are games.',
		UNDEFINED: 'ERR:UNDEFINED. That program is not on my calculator (anymore).',
	};

	// The hint in the status line can be one for the place of the error, like the size of a program that does not fit.
	const showError = (kind, {onQuit, onGoto, hint = errorHints[kind] ?? `ERR:${kind}`}) => {
		const options = [{label: 'Quit', action: onQuit}];
		if (onGoto && errorsWithGoto.has(kind)) {
			options.push({label: 'Goto', action: onGoto});
		}

		go({
			selection: 0,
			draw(target) {
				target.text(0, 0, `ERR:${kind}`);
				for (const [index, option] of options.entries()) {
					target.text(0, index + 1, `${index + 1}:`, index === this.selection);
					target.text(2, index + 1, option.label);
				}
			},
			key(name) {
				if (name === 'up' || name === 'down') {
					this.selection = (this.selection + (name === 'up' ? options.length - 1 : 1)) % options.length;
				} else if (name === 'enter') {
					options[this.selection].action();
				} else if (name === 'token:1' || name === 'clear' || name === 'quit') {
					onQuit();
				} else if (name === 'token:2' && options[1]) {
					options[1].action();
				}

				return true;
			},
		});
		ti83.say(hint);
	};

	// MARK: Menus

	// A menu of the TI, with its tabs at the top, numbered items, the chosen number inverted, and a ↓ when there are more items below.
	const makeMenu = (tabs, {onBack = () => go(home), tab = 0} = {}) => ({
		tab,
		selection: 0,
		top: 0,
		draw(target) {
			let column = 0;
			for (const [index, menuTab] of tabs.entries()) {
				target.text(column, 0, menuTab.title, index === this.tab);
				column += [...menuTab.title].length + 1;
			}

			const items = tabs[this.tab].items;
			for (let row = 0; row < rows - 1; row++) {
				const index = this.top + row;
				const item = items[index];
				if (!item) {
					break;
				}

				const number = index < 9 ? String(index + 1) : (index === 9 ? '0' : String.fromCodePoint(65 + index - 10));
				const isMoreBelow = row === rows - 2 && index < items.length - 1;
				const isMoreAbove = row === 0 && this.top > 0;
				const separator = isMoreBelow ? '↓' : (isMoreAbove ? '↑' : ':');
				target.character(0, row + 1, number, index === this.selection);
				target.character(1, row + 1, separator, index === this.selection);
				target.text(2, row + 1, item.label);
			}
		},
		key(name) {
			const items = tabs[this.tab].items;
			switch (name) {
				case 'left':
				case 'right': {
					this.tab = (this.tab + (name === 'left' ? tabs.length - 1 : 1)) % tabs.length;
					this.selection = 0;
					this.top = 0;
					return true;
				}

				case 'up':
				case 'down': {
					if (items.length === 0) {
						return true;
					}

					this.selection = (this.selection + (name === 'up' ? items.length - 1 : 1)) % items.length;
					this.top = clamp(this.top, this.selection - (rows - 2), this.selection);
					return true;
				}

				case 'enter': {
					items[this.selection]?.action();
					return true;
				}

				case 'clear':
				case 'quit': {
					onBack();
					return true;
				}

				default: {
					if (name.startsWith('token:')) {
						const token = name.slice('token:'.length);
						let index = -1;
						if (isDigitToken(token)) {
							index = token === '0' ? 9 : Number(token) - 1;
						} else if (token >= 'A' && token <= 'Z' && token.length === 1) {
							index = token.codePointAt(0) - 65 + 10;
						}

						if (items[index]) {
							this.selection = index;
							items[index].action();
						}

						return true;
					}

					return false;
				}
			}
		},
	});

	// The screen that a menu pastes into: the line that the visitor was typing, or the home screen.
	const pasteTarget = () => screen?.insert ? screen : home;

	const pasteInto = (target, token) => {
		go(target);
		target.insert(token);
		requestRender();
	};

	const tokenMenuItem = (label, token, target) => ({
		label,
		action() {
			pasteInto(target, token);
		},
	});

	// The menus that are real on the TI, but that nobody in my class ever used.
	const nobodyKnowsMenu = (tabs, origin) => makeMenu(tabs.map(([title, labels]) => ({
		title,
		items: labels.map(label => ({
			label,
			action() {
				go(origin);
				ti83.say(randomItem([
					`Nobody in 8B knows what “${label}” does. Not even Herr Olsen.`,
					`“${label}”? Trond says it is for the university.`,
					`I pressed “${label}”, and nothing happened. Like always.`,
				]));
			},
		})),
	})), {onBack: () => go(origin)});

	// MARK: MODE

	const modeRows = [
		{key: 'notation', options: [['normal', 'Normal'], ['sci', 'Sci'], ['eng', 'Eng']]},
		{key: 'digits', options: [['float', 'Float'], ...Array.from({length: 10}, (_, digit) => [digit, String(digit)])], isCompact: true},
		{key: 'angle', options: [['radian', 'Radian'], ['degree', 'Degree']]},
		{key: 'graphType', options: [['func', 'Func'], ['par', 'Par'], ['pol', 'Pol'], ['seq', 'Seq']]},
		{key: 'drawStyle', options: [['connected', 'Connected'], ['dot', 'Dot']]},
		{key: 'order', options: [['sequential', 'Sequential'], ['simul', 'Simul']]},
		{key: 'numbers', options: [['real', 'Real'], ['a+bi', 'a+bi'], ['re^θi', 're^θi']]},
		{key: 'split', options: [['full', 'Full'], ['horiz', 'Horiz'], ['g-t', 'G-T']]},
	];

	// A saved setting that is not an option of MODE, like from an older version, goes back to the default, because Fix with a wrong number of digits throws.
	for (const modeRow of modeRows) {
		if (!modeRow.options.some(([value]) => value === memory.settings[modeRow.key])) {
			memory.settings[modeRow.key] = defaultSettings()[modeRow.key];
		}
	}

	// The column of each option on its line: the digits of Float stand together, the others have a space between them.
	const optionColumns = modeRow => {
		const result = [];
		let column = 0;
		for (const [index, [, label]] of modeRow.options.entries()) {
			result.push(column);
			column += [...label].length + (modeRow.isCompact && index > 0 ? 0 : 1);
		}

		return result;
	};

	// What I say about the modes that my calculator only pretends to have.
	const modeComments = {
		par: 'Par is for parametric graphs. My graphs stay Func.',
		pol: 'Pol is for polar graphs, which look like flowers. Mine stay Func.',
		seq: 'Seq is for sequences. Mine stay Func.',
		'a+bi': 'a+bi is for complex numbers, chapter 9. √(⁻1) still says NONREAL ANS.',
		're^θi': 're^θi is even more complex. Nobody is there yet.',
		horiz: 'Horiz splits the screen. Mine stays Full.',
		'g-t': 'G-T shows the graph and the table. Mine stays Full.',
		simul: 'Simul draws all graphs at once. Mine draws them one by one, like a TI.',
		degree: 'Degree mode: sin(90) is 1 now. Herr Olsen likes degrees.',
		radian: 'Radian mode: sin(π/2) is 1.',
	};

	const modeScreen = {
		row: 0,
		option: 0,
		draw(target) {
			for (const [rowIndex, modeRow] of modeRows.entries()) {
				const positions = optionColumns(modeRow);
				for (const [index, [value, label]] of modeRow.options.entries()) {
					const isSelected = memory.settings[modeRow.key] === value;
					const isCursor = rowIndex === this.row && index === this.option && isCursorVisible();
					target.text(positions[index], rowIndex, label, isSelected !== isCursor);
				}
			}
		},
		key(name) {
			const options = modeRows[this.row].options;
			switch (name) {
				case 'up':
				case 'down': {
					this.row = (this.row + (name === 'up' ? modeRows.length - 1 : 1)) % modeRows.length;
					this.option = 0;
					return true;
				}

				case 'left':
				case 'right': {
					this.option = (this.option + (name === 'left' ? options.length - 1 : 1)) % options.length;
					return true;
				}

				case 'enter': {
					const [value] = options[this.option];
					memory.settings[modeRows[this.row].key] = value;
					markGraphDirty();
					saveSoon();
					if (modeComments[value]) {
						ti83.say(modeComments[value]);
					}

					return true;
				}

				case 'clear':
				case 'quit': {
					go(home);
					return true;
				}

				default: {
					return false;
				}
			}
		},
	};

	// MARK: Y=

	const subscripts = '₀₁₂₃₄₅₆₇₈₉';

	const yEditor = {
		index: 0,
		// The cursor is on the “=” at −1, where ENTER turns the function on and off.
		cursor: 0,
		isInserting: false,
		editor() {
			const editor = makeEditor(memory.functions[this.index].tokens);
			editor.cursor = this.cursor;
			editor.isInserting = this.isInserting;
			return editor;
		},
		insert(token) {
			if (this.cursor < 0) {
				this.cursor = 0;
			}

			const editor = this.editor();
			editor.type(token);
			this.cursor = editor.cursor;
			markGraphDirty();
			saveSoon();
		},
		draw(target) {
			const lines = [];
			let cursorLine = 0;
			let cursorColumn = 0;
			for (const [index, entry] of memory.functions.entries()) {
				const editor = makeEditor(entry.tokens);
				editor.cursor = index === this.index ? Math.max(this.cursor, 0) : 0;
				const {characters, cursorIndex} = editor.layout();
				const cells = ['\\', 'Y', subscripts[index + 1], '=', ...characters];
				const lineCount = Math.max(Math.ceil(cells.length / columns), index === this.index ? Math.floor((cursorIndex + 4) / columns) + 1 : 1);
				if (index === this.index) {
					const cellIndex = this.cursor < 0 ? 3 : cursorIndex + 4;
					cursorLine = lines.length + Math.floor(cellIndex / columns);
					cursorColumn = cellIndex % columns;
				}

				for (let line = 0; line < lineCount; line++) {
					lines.push({cells: cells.slice(line * columns, (line + 1) * columns), equalsColumn: line === 0 && entry.isEnabled ? 3 : -1});
				}
			}

			const visibleCount = rows - 1;
			this.top = clamp(this.top ?? 0, cursorLine - visibleCount + 1, cursorLine);
			target.smallText(4, 1, 'PLOT1  PLOT2  PLOT3');
			for (let row = 0; row < visibleCount; row++) {
				const line = lines[this.top + row];
				if (!line) {
					break;
				}

				for (const [column, character] of line.cells.entries()) {
					target.character(column, row + 1, character, column === line.equalsColumn);
				}

				if (this.top + row === cursorLine) {
					drawCursor(target, cursorColumn, row + 1, line.cells[cursorColumn] ?? ' ', this.isInserting);
				}
			}
		},
		key(name) {
			const entry = memory.functions[this.index];
			switch (name) {
				case 'up':
				case 'down': {
					this.index = clamp(this.index + (name === 'up' ? -1 : 1), 0, memory.functions.length - 1);
					this.cursor = memory.functions[this.index].tokens.length;
					this.isInserting = false;
					return true;
				}

				case 'enter': {
					if (this.cursor < 0) {
						entry.isEnabled = !entry.isEnabled;
						markGraphDirty();
						saveSoon();
					} else {
						return this.key('down');
					}

					return true;
				}

				case 'clear': {
					entry.tokens = [];
					this.cursor = 0;
					markGraphDirty();
					saveSoon();
					return true;
				}

				case 'left': {
					this.cursor = Math.max(-1, this.cursor - 1);
					return true;
				}

				case 'quit': {
					go(home);
					return true;
				}

				default: {
					if (name.startsWith('token:')) {
						this.insert(name.slice('token:'.length));
						return true;
					}

					if (this.cursor < 0) {
						this.cursor = 0;
						if (name === 'right') {
							return true;
						}
					}

					const editor = this.editor();
					if (editor.handle(name)) {
						entry.tokens = editor.tokens;
						this.cursor = editor.cursor;
						this.isInserting = editor.isInserting;
						markGraphDirty();
						saveSoon();
						return true;
					}

					return false;
				}
			}
		},
	};

	// MARK: WINDOW and TBLSET

	// A screen of numbers to set, like WINDOW. Typing replaces the number under the cursor, and the line is calculated when the cursor leaves it, so “2π” works.
	const makeForm = (title, fields, {footer = []} = {}) => ({
		selection: 0,
		editing: undefined,
		insert(token) {
			this.editing ??= [];
			this.editing.push(token);
		},
		commit() {
			if (this.editing === undefined) {
				return true;
			}

			const tokens = this.editing;
			if (tokens.length === 0) {
				this.editing = undefined;
				return true;
			}

			try {
				const statement = parse(tokens);
				const value = checked(evaluate(statement.expression), 0);
				fields[this.selection].set(value);
				this.editing = undefined;
				markGraphDirty();
				saveSoon();
				return true;
			} catch (error) {
				if (!(error instanceof CalculatorError)) {
					throw error;
				}

				showError(error.kind, {
					onQuit: () => {
						this.editing = undefined;
						go(this);
					},
					onGoto: () => {
						go(this);
						this.editing = tokens;
					},
				});
				return false;
			}
		},
		leave() {
			if (this.editing !== undefined) {
				try {
					const value = checked(evaluate(parse(this.editing).expression), 0);
					fields[this.selection].set(value);
					markGraphDirty();
					saveSoon();
				} catch {}

				this.editing = undefined;
			}
		},
		draw(target) {
			target.text(0, 0, title);
			for (const [index, field] of fields.entries()) {
				const row = index + 1;
				target.text(0, row, field.label);
				const start = [...field.label].length;
				const valueCharacters = index === this.selection && this.editing !== undefined ? [...tokensText(this.editing)] : [...formatNumber(field.get())];
				target.text(start, row, valueCharacters.join('').slice(0, columns - start));
				if (index === this.selection) {
					const cursorColumn = this.editing === undefined ? start : Math.min(start + valueCharacters.length, columns - 1);
					drawCursor(target, cursorColumn, row, this.editing === undefined ? valueCharacters[0] : ' ');
				}
			}

			for (const [index, line] of footer.entries()) {
				target.text(0, fields.length + 1 + index, line.text);
				if (line.highlight) {
					target.text(line.highlight.column, fields.length + 1 + index, line.highlight.text, true);
				}
			}
		},
		key(name) {
			switch (name) {
				case 'up':
				case 'down':
				case 'enter': {
					if (this.commit()) {
						this.selection = clamp(this.selection + (name === 'up' ? -1 : 1), 0, fields.length - 1);
					}

					return true;
				}

				case 'del': {
					if (this.editing === undefined) {
						this.editing = [];
					} else {
						this.editing.pop();
					}

					return true;
				}

				case 'clear': {
					this.editing = [];
					return true;
				}

				case 'quit': {
					if (this.commit()) {
						go(home);
					}

					return true;
				}

				case 'left':
				case 'right': {
					return true;
				}

				default: {
					if (name.startsWith('token:')) {
						this.insert(name.slice('token:'.length));
						return true;
					}

					return false;
				}
			}
		},
	});

	const windowForm = makeForm('WINDOW', [
		{label: 'Xmin=', get: () => memory.window.xMinimum, set: value => {
			memory.window.xMinimum = value;
		}},
		{label: 'Xmax=', get: () => memory.window.xMaximum, set: value => {
			memory.window.xMaximum = value;
		}},
		{label: 'Xscl=', get: () => memory.window.xScale, set: value => {
			memory.window.xScale = Math.abs(value);
		}},
		{label: 'Ymin=', get: () => memory.window.yMinimum, set: value => {
			memory.window.yMinimum = value;
		}},
		{label: 'Ymax=', get: () => memory.window.yMaximum, set: value => {
			memory.window.yMaximum = value;
		}},
		{label: 'Yscl=', get: () => memory.window.yScale, set: value => {
			memory.window.yScale = Math.abs(value);
		}},
	]);

	const tableForm = makeForm('TABLE SETUP', [
		{label: 'TblStart=', get: () => memory.table.start, set: value => {
			memory.table.start = value;
		}},
		{label: 'ΔTbl=', get: () => memory.table.step, set: value => {
			memory.table.step = value === 0 ? 1 : value;
		}},
	], {
		footer: [
			{text: 'Indpnt: Auto Ask', highlight: {column: 8, text: 'Auto'}},
			{text: 'Depend: Auto Ask', highlight: {column: 8, text: 'Auto'}},
		],
	});

	// MARK: GRAPH and TRACE

	// The graph area of the TI-83 is 95 × 63 pixels, so the middle pixel is exactly at the middle of the window.
	const graphColumns = 95;
	const graphRows = 63;

	const pixelWidth = () => (memory.window.xMaximum - memory.window.xMinimum) / (graphColumns - 1);
	const pixelHeight = () => (memory.window.yMaximum - memory.window.yMinimum) / (graphRows - 1);
	const columnToX = column => memory.window.xMinimum + (column * pixelWidth());
	const yToRow = y => (memory.window.yMaximum - y) / pixelHeight();
	const rowToY = row => memory.window.yMaximum - (row * pixelHeight());

	const drawAxes = (target, window = memory.window) => {
		const columnWidth = (window.xMaximum - window.xMinimum) / (graphColumns - 1);
		const rowHeight = (window.yMaximum - window.yMinimum) / (graphRows - 1);
		const axisRow = Math.round(window.yMaximum / rowHeight);
		const axisColumn = Math.round(-window.xMinimum / columnWidth);
		if (axisRow >= 0 && axisRow < graphRows) {
			target.line(0, axisRow, graphColumns - 1, axisRow);
			if (window.xScale > 0 && (window.xMaximum - window.xMinimum) / window.xScale <= 100) {
				for (let tick = Math.ceil(window.xMinimum / window.xScale); tick * window.xScale <= window.xMaximum; tick++) {
					const column = Math.round(((tick * window.xScale) - window.xMinimum) / columnWidth);
					target.set(column, axisRow - 1);
					target.set(column, axisRow + 1);
				}
			}
		}

		if (axisColumn >= 0 && axisColumn < graphColumns) {
			target.line(axisColumn, 0, axisColumn, graphRows - 1);
			if (window.yScale > 0 && (window.yMaximum - window.yMinimum) / window.yScale <= 100) {
				for (let tick = Math.ceil(window.yMinimum / window.yScale); tick * window.yScale <= window.yMaximum; tick++) {
					const row = Math.round((window.yMaximum - (tick * window.yScale)) / rowHeight);
					target.set(axisColumn - 1, row);
					target.set(axisColumn + 1, row);
				}
			}
		}
	};

	const safeEvaluate = (ast, x) => {
		try {
			return evaluate(ast, x);
		} catch {
			return Number.NaN;
		}
	};

	// A cross that blinks over the graph, drawn by inverting the pixels, so it shows on the lines too.
	const drawCross = (target, x, y) => {
		if (!isCursorVisible()) {
			return;
		}

		x = Math.round(x);
		y = Math.round(y);
		target.invert(x, y);
		for (const offset of [-2, -1, 1, 2]) {
			target.invert(x + offset, y);
			target.invert(x, y + offset);
		}
	};

	const graphScreen = {
		buffer: new Display(),
		isValid: false,
		isDrawing: false,
		isPausedNow: false,
		queue: [],
		compiled: [],
		column: 0,
		previousRow: undefined,
		columnSeconds: 0,
		mode: 'graph',
		cursorX: 47,
		cursorY: 31,
		traceIndex: 0,
		traceColumn: 47,
		isBusy() {
			return this.isDrawing;
		},
		isPaused() {
			return this.isPausedNow;
		},
		update(seconds) {
			if (!this.isDrawing || this.isPausedNow) {
				return false;
			}

			// About 50 columns a second, which is how slowly a real TI-83 draws Y=X².
			this.columnSeconds += seconds;
			while (this.columnSeconds >= 0.02 && this.isDrawing) {
				this.columnSeconds -= 0.02;
				this.drawColumn();
			}

			drainBatteries(seconds * 0.15);
			return true;
		},
		drawColumn() {
			const entry = this.queue[0];
			const value = safeEvaluate(entry.ast, columnToX(this.column));
			if (Number.isFinite(value)) {
				const row = clamp(yToRow(value), -8, graphRows + 8);
				if (memory.settings.drawStyle === 'connected' && this.previousRow !== undefined) {
					this.buffer.line(this.column - 1, this.previousRow, this.column, row);
				} else {
					this.buffer.set(this.column, row);
				}

				this.previousRow = row;
			} else {
				this.previousRow = undefined;
			}

			this.column++;
			if (this.column >= graphColumns) {
				this.queue.shift();
				this.column = 0;
				this.previousRow = undefined;
				if (this.queue.length === 0) {
					this.isDrawing = false;
					this.isValid = true;
					ti83.say(this.compiled.length === 0 ? 'The graph is empty. Type a function in Y= first, like X².' : 'The graph is done. TRACE walks along it.');
				}
			}
		},
		finishDrawing() {
			while (this.isDrawing) {
				this.drawColumn();
			}
		},
		start(mode = 'graph') {
			// A WINDOW value that is still being typed counts before the graph is drawn.
			screen?.leave?.();
			const window = memory.window;
			if (!(window.xMinimum < window.xMaximum) || !(window.yMinimum < window.yMaximum)) {
				showError('WINDOW RANGE', {onQuit: () => go(windowForm)});
				return;
			}

			const compiled = [];
			for (const [index, entry] of memory.functions.entries()) {
				if (!entry.isEnabled || entry.tokens.length === 0) {
					continue;
				}

				try {
					const statement = parse(entry.tokens);
					if (statement.store || statement.conversion) {
						throw new CalculatorError('SYNTAX', entry.tokens.length - 1);
					}

					compiled.push({index, ast: statement.expression, tokens: entry.tokens});
				} catch (error) {
					if (!(error instanceof CalculatorError)) {
						throw error;
					}

					showError(error.kind, {
						onQuit: () => go(home),
						onGoto: () => {
							yEditor.index = index;
							yEditor.cursor = error.position;
							go(yEditor);
						},
					});
					return;
				}
			}

			this.compiled = compiled;
			this.mode = mode;
			this.traceIndex = clamp(this.traceIndex, 0, Math.max(0, compiled.length - 1));
			if (mode === 'trace' && compiled.length === 0) {
				this.mode = 'free';
			}

			if (!this.isValid && !this.isDrawing) {
				this.buffer.clear();
				drawAxes(this.buffer);
				this.queue = [...compiled];
				this.column = 0;
				this.previousRow = undefined;
				this.isDrawing = true;
				this.isPausedNow = false;
				if (compiled.length === 0) {
					this.isDrawing = false;
					this.isValid = true;
				} else if (ti83.reducedMotion) {
					this.finishDrawing();
				}
			}

			go(this);
		},
		draw(target) {
			target.pixels.set(this.buffer.pixels);
			if (this.isDrawing) {
				return;
			}

			if (this.mode === 'free') {
				drawCross(target, this.cursorX, this.cursorY);
				target.smallText(1, 57, `X=${formatShort(columnToX(this.cursorX), 8)}`);
				target.smallText(48, 57, `Y=${formatShort(rowToY(this.cursorY), 8)}`);
			} else if (this.mode === 'trace') {
				const entry = this.compiled[this.traceIndex];
				const x = columnToX(this.traceColumn);
				const y = safeEvaluate(entry.ast, x);
				const row = yToRow(y);
				if (Number.isFinite(y) && row >= 0 && row < graphRows) {
					drawCross(target, this.traceColumn, row);
				}

				let label = `Y${entry.index + 1}=${tokensText(entry.tokens)}`;
				while (smallTextWidth(label) > 88 && label.length > 4) {
					label = label.slice(0, -1);
				}

				target.smallText(1, 1, label);
				target.smallText(1, 57, `X=${formatShort(x, 8)}`);
				target.smallText(48, 57, `Y=${Number.isFinite(y) ? formatShort(y, 8) : ''}`);
			}
		},
		key(name) {
			if (this.isDrawing) {
				if (name === 'enter') {
					// ENTER pauses the drawing, like on the TI, and the busy indicator stands still.
					this.isPausedNow = !this.isPausedNow;
					return true;
				}

				if (name === 'graph') {
					return true;
				}

				if (name === 'on') {
					this.isDrawing = false;
					this.queue = [];
					ti83.say('Stopped. ON stops the graph, like on the real one.');
					return true;
				}

				this.isDrawing = false;
				this.queue = [];
			}

			switch (name) {
				case 'left':
				case 'right':
				case 'up':
				case 'down': {
					if (this.mode === 'trace') {
						if (name === 'left' || name === 'right') {
							this.traceColumn = clamp(this.traceColumn + (name === 'left' ? -1 : 1), 0, graphColumns - 1);
						} else {
							this.traceIndex = (this.traceIndex + (name === 'up' ? this.compiled.length - 1 : 1)) % this.compiled.length;
						}
					} else {
						this.mode = 'free';
						this.cursorX = clamp(this.cursorX + (name === 'left' ? -1 : (name === 'right' ? 1 : 0)), 0, graphColumns - 1);
						this.cursorY = clamp(this.cursorY + (name === 'up' ? -1 : (name === 'down' ? 1 : 0)), 0, graphRows - 1);
					}

					return true;
				}

				case 'enter': {
					if (this.mode === 'trace') {
						// ENTER in TRACE moves the window, so the cursor is in the middle.
						const entry = this.compiled[this.traceIndex];
						const x = columnToX(this.traceColumn);
						const y = safeEvaluate(entry.ast, x);
						const window = memory.window;
						const halfWidth = (window.xMaximum - window.xMinimum) / 2;
						window.xMinimum = x - halfWidth;
						window.xMaximum = x + halfWidth;
						if (Number.isFinite(y)) {
							const halfHeight = (window.yMaximum - window.yMinimum) / 2;
							window.yMinimum = y - halfHeight;
							window.yMaximum = y + halfHeight;
						}

						this.traceColumn = 47;
						markGraphDirty();
						saveSoon();
						this.start('trace');
					}

					return true;
				}

				case 'clear': {
					if (this.mode === 'graph') {
						go(home);
					} else {
						this.mode = 'graph';
					}

					return true;
				}

				case 'quit': {
					go(home);
					return true;
				}

				default: {
					return false;
				}
			}
		},
	};

	function markGraphDirty() {
		graphScreen.isValid = false;
		graphScreen.isDrawing = false;
	}

	// MARK: TABLE

	const tableScreen = {
		row: 0,
		column: 1,
		draw(target) {
			const functions = memory.functions
				.map((entry, index) => ({entry, index}))
				.filter(({entry}) => entry.isEnabled && entry.tokens.length > 0)
				.slice(0, 2);
			const compiled = functions.map(({entry, index}) => {
				try {
					return {index, ast: parse(entry.tokens).expression};
				} catch {
					return {index};
				}
			});
			this.columnCount = 1 + compiled.length;
			this.column = clamp(this.column, 0, this.columnCount - 1);

			const headers = ['X', ...compiled.map(({index}) => `Y${subscripts[index + 1]}`)];
			for (const [index, header] of headers.entries()) {
				target.text((index * 5) + 2, 0, header);
			}

			let selectedText = '';
			for (let row = 0; row < 6; row++) {
				const x = memory.table.start + (row * memory.table.step);
				const values = [x, ...compiled.map(({ast}) => ast ? safeEvaluate(ast, x) : Number.NaN)];
				for (const [index, value] of values.entries()) {
					const text = formatShort(value, 5);
					const isSelected = row === this.row && index === this.column;
					const startColumn = (index * 5) + (5 - [...text].length);
					target.text(startColumn, row + 1, text);
					if (isSelected) {
						target.invertRectangle(index * 30, (row + 1) * 8, 29, 8);
						selectedText = `${index === 0 ? 'X' : `Y${compiled[index - 1].index + 1}`}=${Number.isFinite(value) ? formatNumber(value) : 'ERROR'}`;
					}
				}
			}

			// The grid goes on top of the numbers, in the empty column at the right of each cell.
			target.line(0, 7, 88, 7);
			target.line(29, 0, 29, 55);
			target.line(59, 0, 59, 55);
			target.text(0, 7, selectedText.slice(0, columns));
		},
		key(name) {
			switch (name) {
				case 'up': {
					if (this.row === 0) {
						memory.table.start -= memory.table.step;
					} else {
						this.row--;
					}

					return true;
				}

				case 'down': {
					if (this.row === 5) {
						memory.table.start += memory.table.step;
					} else {
						this.row++;
					}

					return true;
				}

				case 'left':
				case 'right': {
					this.column = clamp(this.column + (name === 'left' ? -1 : 1), 0, (this.columnCount ?? 1) - 1);
					return true;
				}

				case 'clear':
				case 'quit': {
					saveSoon();
					go(home);
					return true;
				}

				default: {
					return false;
				}
			}
		},
	};

	// MARK: ZOOM and MATH

	let previousWindow = standardWindow();
	let storedWindow = standardWindow();

	const setWindow = window => {
		previousWindow = {...memory.window};
		memory.window = window;
		markGraphDirty();
		saveSoon();
		graphScreen.start();
	};

	const zoomBy = factor => {
		const window = memory.window;
		const centerX = (window.xMinimum + window.xMaximum) / 2;
		const centerY = (window.yMinimum + window.yMaximum) / 2;
		const halfWidth = (window.xMaximum - window.xMinimum) * factor / 2;
		const halfHeight = (window.yMaximum - window.yMinimum) * factor / 2;
		setWindow({...window, xMinimum: centerX - halfWidth, xMaximum: centerX + halfWidth, yMinimum: centerY - halfHeight, yMaximum: centerY + halfHeight});
	};

	const zoomFit = () => {
		let minimum = Number.POSITIVE_INFINITY;
		let maximum = Number.NEGATIVE_INFINITY;
		for (const entry of memory.functions) {
			if (!entry.isEnabled || entry.tokens.length === 0) {
				continue;
			}

			let ast;
			try {
				ast = parse(entry.tokens).expression;
			} catch {
				continue;
			}

			for (let column = 0; column < graphColumns; column++) {
				const value = safeEvaluate(ast, columnToX(column));
				if (Number.isFinite(value)) {
					minimum = Math.min(minimum, value);
					maximum = Math.max(maximum, value);
				}
			}
		}

		if (!Number.isFinite(minimum)) {
			graphScreen.start();
			return;
		}

		if (minimum === maximum) {
			minimum -= 1;
			maximum += 1;
		}

		setWindow({...memory.window, yMinimum: minimum, yMaximum: maximum});
	};

	const openZoomMenu = () => {
		go(makeMenu([
			{
				title: 'ZOOM',
				items: [
					{label: 'ZBox', action() {
						ti83.say('ZBox needs a box drawn with the cursor. Mine zooms in instead.');
						zoomBy(1 / 4);
					}},
					{label: 'Zoom In', action: () => zoomBy(1 / 4)},
					{label: 'Zoom Out', action: () => zoomBy(4)},
					{label: 'ZDecimal', action: () => setWindow({xMinimum: -4.7, xMaximum: 4.7, xScale: 1, yMinimum: -3.1, yMaximum: 3.1, yScale: 1})},
					{label: 'ZSquare', action() {
						const window = memory.window;
						const centerX = (window.xMinimum + window.xMaximum) / 2;
						const halfWidth = pixelHeight() * (graphColumns - 1) / 2;
						setWindow({...window, xMinimum: centerX - halfWidth, xMaximum: centerX + halfWidth});
					}},
					{label: 'ZStandard', action: () => setWindow(standardWindow())},
					{label: 'ZTrig', action() {
						const isDegree = memory.settings.angle === 'degree';
						setWindow({xMinimum: isDegree ? -352.5 : -6.152285613, xMaximum: isDegree ? 352.5 : 6.152285613, xScale: isDegree ? 90 : Math.PI / 2, yMinimum: -4, yMaximum: 4, yScale: 1});
					}},
					{label: 'ZInteger', action() {
						const window = memory.window;
						const centerX = Math.round((window.xMinimum + window.xMaximum) / 2);
						const centerY = Math.round((window.yMinimum + window.yMaximum) / 2);
						setWindow({xMinimum: centerX - 47, xMaximum: centerX + 47, xScale: 10, yMinimum: centerY - 31, yMaximum: centerY + 31, yScale: 10});
					}},
					{label: 'ZoomStat', action: () => showError('STAT', {onQuit: () => go(home)})},
					{label: 'ZoomFit', action: zoomFit},
				],
			},
			{
				title: 'MEMORY',
				items: [
					{label: 'ZPrevious', action: () => setWindow({...previousWindow})},
					{label: 'ZoomSto', action() {
						storedWindow = {...memory.window};
						ti83.say('ZoomSto: the window is stored.');
						go(home);
					}},
					{label: 'ZoomRcl', action: () => setWindow({...storedWindow})},
					{label: 'SetFactors…', action() {
						ti83.say('The zoom factors are 4, like they came from the factory.');
						go(home);
					}},
				],
			},
		]));
	};

	const openMathMenu = () => {
		const target = pasteTarget();
		go(makeMenu([
			{
				title: 'MATH',
				items: [
					tokenMenuItem('▸Frac', '▸Frac', target),
					tokenMenuItem('▸Dec', '▸Dec', target),
					tokenMenuItem('³', '³', target),
					tokenMenuItem('³√(', '³√(', target),
				],
			},
			{
				title: 'NUM',
				items: [
					tokenMenuItem('abs(', 'abs(', target),
					tokenMenuItem('round(', 'round(', target),
					tokenMenuItem('iPart(', 'iPart(', target),
					tokenMenuItem('fPart(', 'fPart(', target),
					tokenMenuItem('int(', 'int(', target),
				],
			},
			{
				title: 'PRB',
				items: [
					tokenMenuItem('rand', 'rand', target),
					tokenMenuItem('nPr', ' nPr ', target),
					tokenMenuItem('nCr', ' nCr ', target),
					tokenMenuItem('!', '!', target),
					tokenMenuItem('randInt(', 'randInt(', target),
				],
			},
		], {onBack: () => go(target)}));
	};

	// MARK: Programs

	// The keys that are held down now, so games can move while a key is held.
	const heldKeys = new Set();

	const recordScore = (name, score) => {
		const best = hardware.highScores[name] ?? 0;
		if (score > best) {
			hardware.highScores[name] = score;
			saveSoon();
			if (best > 0) {
				ti83.toast(`🏆 New high score in ${name}: ${score}!`);
			}

			return true;
		}

		return false;
	};

	// Draws lines of text in the big font, wrapped at 16 characters, like Disp on the TI.
	const drawLines = (target, lines, startRow = 0) => {
		let row = startRow;
		for (const line of lines) {
			for (const chunk of wrap([...line])) {
				if (row < rows) {
					target.text(0, row, chunk.join(''));
				}

				row++;
			}
		}

		return row;
	};

	// The end of a game: the score in a box in the middle, until ENTER.
	const drawGameOver = (target, title, score, best) => {
		target.fill(8, 14, 80, 36, false);
		target.rectangle(8, 14, 80, 36);
		const centered = (text, row) => {
			target.text(Math.floor((columns - [...text].length) / 2), row, text);
		};

		centered(title, 2);
		centered(`SCORE ${score}`, 3);
		centered(`HIGH ${best}`, 4);
		target.fill(9, 47, 78, 1, false);
		target.smallText(25, 43, 'PRESS ENTER');
	};

	const makePhoenix = () => {
		const birdFrames = [
			['#.....#', '##.#.##', '.#####.', '..###..', '...#...'],
			['...#...', '..###..', '.#####.', '##.#.##', '#.....#'],
		];
		const ship = ['...#...', '..###..', '#.###.#', '#######', '##...##'];
		const sparks = [['#.#.#', '.###.', '##.##', '.###.', '#.#.#'], ['..#..', '#.#.#', '.#.#.', '#.#.#', '..#..']];
		let shipX = 44;
		let bullets = [];
		let shots = [];
		let birds = [];
		let explosions = [];
		let score = 0;
		let lives = 3;
		let wave = 0;
		let time = 0;
		let shield = 0;
		let shieldCooldown = 0;
		let safeTicks = 0;
		let banner = 0;

		const spawnWave = () => {
			wave++;
			banner = 30;
			birds = [];
			const rowCount = Math.min(2 + Math.floor(wave / 2), 4);
			for (let row = 0; row < rowCount; row++) {
				for (let column = 0; column < 6; column++) {
					birds.push({homeX: 7 + (column * 14), homeY: 9 + (row * 7), x: 7 + (column * 14), y: 9 + (row * 7), state: 'home', velocityX: 0, velocityY: 0});
				}
			}

			if (wave === 4) {
				ti83.celebrate();
				ti83.toast('🔥 PHOENIX wave 4! Trond only got to wave 3.');
			}
		};

		const hit = () => {
			if (shield > 0 || safeTicks > 0) {
				return;
			}

			lives--;
			explosions.push({x: shipX + 1, y: 57, time: 12});
			safeTicks = 40;
			if (lives <= 0) {
				game.isOver = true;
				recordScore('PHOENIX', score);
			}
		};

		const game = {
			rate: 20,
			isOver: false,
			isFinished: false,
			tick() {
				if (game.isOver) {
					return;
				}

				time++;
				banner = Math.max(0, banner - 1);
				shield = Math.max(0, shield - 1);
				shieldCooldown = Math.max(0, shieldCooldown - 1);
				safeTicks = Math.max(0, safeTicks - 1);
				if (heldKeys.has('left')) {
					shipX = Math.max(0, shipX - 2);
				}

				if (heldKeys.has('right')) {
					shipX = Math.min(width - 7, shipX + 2);
				}

				const sway = Math.round(Math.sin(time / 15) * 5);
				for (const bird of birds) {
					if (bird.state === 'home') {
						bird.x = bird.homeX + sway;
						bird.y = bird.homeY + (Math.floor((time + bird.homeX) / 8) % 2);
						if (Math.random() < 0.003 + (wave * 0.0015)) {
							bird.state = 'dive';
							bird.velocityX = (shipX - bird.x) / 35;
							bird.velocityY = 1.1 + (wave * 0.1);
						}
					} else if (bird.state === 'dive') {
						bird.x += bird.velocityX + (Math.sin(time / 4) * 0.9);
						bird.y += bird.velocityY;
						if (bird.y > height) {
							bird.state = 'return';
							bird.y = -6;
						}
					} else {
						bird.x += Math.sign(bird.homeX + sway - bird.x);
						bird.y += 1;
						if (bird.y >= bird.homeY) {
							bird.state = 'home';
						}
					}

					if (Math.random() < 0.004 + (wave * 0.002) && shots.length < 2 + wave && bird.y > 0) {
						shots.push({x: bird.x + 3, y: bird.y + 5});
					}

					if (bird.state === 'dive' && bird.x + 6 >= shipX && bird.x <= shipX + 6 && bird.y + 4 >= 58 && bird.y <= 62) {
						bird.isHit = true;
						explosions.push({x: bird.x + 1, y: bird.y, time: 6});
						hit();
					}
				}

				for (const bullet of bullets) {
					bullet.y -= 3;
					for (const bird of birds) {
						if (!bird.isHit && bullet.x >= bird.x && bullet.x <= bird.x + 6 && bullet.y <= bird.y + 4 && bullet.y + 2 >= bird.y) {
							bird.isHit = true;
							bullet.isUsed = true;
							score += bird.state === 'dive' ? 30 : 10;
							explosions.push({x: bird.x + 1, y: bird.y, time: 6});
							break;
						}
					}
				}

				for (const shot of shots) {
					shot.y += 1.5;
					if (shot.x >= shipX && shot.x <= shipX + 6 && shot.y >= 58 && shot.y <= 62) {
						shot.isUsed = true;
						hit();
					}
				}

				birds = birds.filter(bird => !bird.isHit);
				bullets = bullets.filter(bullet => !bullet.isUsed && bullet.y > 6);
				shots = shots.filter(shot => !shot.isUsed && shot.y < height);
				explosions = explosions.filter(explosion => --explosion.time > 0);
				if (birds.length === 0 && !game.isOver) {
					spawnWave();
				}
			},
			key(id) {
				if (id === 'clear') {
					game.isFinished = true;
					return;
				}

				if ((id === '2nd' || id === 'up' || id === 'enter') && bullets.length < 2) {
					bullets.push({x: shipX + 3, y: 55});
				}

				if (id === 'down' && shieldCooldown === 0) {
					// The shield of Phoenix: it stops everything for a moment, and then it needs time to charge again.
					shield = 25;
					shieldCooldown = 90;
				}
			},
			draw(target) {
				for (const [index, bird] of birds.entries()) {
					target.sprite(Math.round(bird.x), Math.round(bird.y), birdFrames[Math.floor((time + index) / 5) % 2]);
				}

				if (safeTicks % 4 < 2) {
					target.sprite(shipX, 58, ship);
				}

				if (shield > 0) {
					target.circle(shipX + 3, 60, 6);
				}

				for (const bullet of bullets) {
					target.line(bullet.x, bullet.y, bullet.x, bullet.y + 2);
				}

				for (const shot of shots) {
					target.set(shot.x, shot.y);
					target.set(shot.x, shot.y + 1);
				}

				for (const explosion of explosions) {
					target.sprite(explosion.x, explosion.y, sparks[explosion.time % 2]);
				}

				target.smallText(1, 1, `${score}`);
				for (let life = 0; life < lives; life++) {
					target.sprite(80 - (life * 5), 1, ['.#.', '###', '#.#']);
				}

				if (banner > 0 && !game.isOver) {
					target.text(5, 3, `WAVE ${wave}`);
				}

				if (game.isOver) {
					drawGameOver(target, 'GAME OVER', score, hardware.highScores.PHOENIX ?? score);
				}
			},
		};
		spawnWave();
		return game;
	};

	const makeWaffleRun = () => {
		const runFrames = [
			['.##..', '.##..', '..#..', '.###.', '#.#.#', '..#..', '.#.#.', '#...#'],
			['.##..', '.##..', '..#..', '.###.', '#.#.#', '..#..', '..#..', '.##..'],
		];
		const jumpFrame = ['.##..', '.##..', '#.#.#', '.###.', '..#..', '..#..', '.#.#.', '.#.#.'];
		const duckFrame = ['.##..', '.##.#', '.####', '##.##', '#...#'];
		const rocky = ['..###..', '.#.#.#.', '#######', '#######'];
		const gullFrames = [['#.....#', '.##.##.', '...#...'], ['.......', '###.###', '...#...']];
		const waffle = ['.#.#.', '#####', '#.#.#', '#####', '.###.'];
		const ground = 55;
		const playerX = 12;
		let feet = ground;
		let velocity = 0;
		let distance = 0;
		let waffles = 0;
		let time = 0;
		let nextSpawn = 60;
		let things = [];
		let yum = 0;
		let title = 'AU! ROCKY!';
		const rain = Array.from({length: 14}, () => ({x: randomInteger(0, width + 20), y: randomInteger(0, height)}));

		const score = () => Math.floor(distance / 5) + (waffles * 20);
		const isDucking = () => heldKeys.has('down') && feet === ground;

		const end = text => {
			title = text;
			game.isOver = true;
			recordScore('WAFFLRUN', score());
		};

		const game = {
			rate: 20,
			isOver: false,
			isFinished: false,
			tick() {
				if (game.isOver) {
					return;
				}

				time++;
				const speed = 1.5 + Math.min(distance / 1500, 2);
				distance += speed;
				yum = Math.max(0, yum - 1);
				velocity += 0.32;
				feet = Math.min(ground, feet + velocity);
				if (feet === ground) {
					velocity = 0;
				}

				for (const drop of rain) {
					drop.y += 2;
					drop.x -= 1;
					if (drop.y > height) {
						drop.y = 0;
						drop.x = randomInteger(0, width + 20);
					}
				}

				nextSpawn -= speed;
				if (nextSpawn <= 0) {
					const roll = Math.random();
					const kind = roll < 0.45 ? 'rock' : (roll < 0.7 ? 'puddle' : (distance > 400 ? 'gull' : 'rock'));
					things.push({kind, x: width + 2});
					if (Math.random() < 0.5) {
						things.push({kind: 'waffle', x: width + 30, y: randomInteger(32, 40)});
					}

					nextSpawn = randomInteger(45, 90);
				}

				const top = isDucking() ? feet - 4 : feet - 7;
				for (const thing of things) {
					thing.x -= speed;
					const overlaps = (left, right) => playerX + 4 >= left && playerX <= right;
					if (thing.kind === 'rock' && overlaps(thing.x + 1, thing.x + 5) && feet >= ground - 3) {
						end('AU! ROCKY!');
					} else if (thing.kind === 'puddle' && overlaps(thing.x + 2, thing.x + 6) && feet === ground) {
						end('PLASK!');
					} else if (thing.kind === 'gull' && overlaps(thing.x, thing.x + 6) && top <= 48 && feet >= 46) {
						end('A SEAGULL!');
					} else if (thing.kind === 'waffle' && !thing.isEaten && overlaps(thing.x, thing.x + 4) && top <= thing.y + 4 && feet >= thing.y) {
						thing.isEaten = true;
						waffles++;
						yum = 15;
					}
				}

				things = things.filter(thing => thing.x > -10 && !thing.isEaten);
			},
			key(id) {
				if (id === 'clear') {
					game.isFinished = true;
					return;
				}

				if ((id === '2nd' || id === 'up' || id === 'enter') && feet === ground) {
					velocity = -3.6;
					feet -= 0.1;
				}
			},
			draw(target) {
				for (const drop of rain) {
					target.set(drop.x, drop.y);
					target.set(drop.x + 1, drop.y - 1);
				}

				target.line(0, ground + 1, width - 1, ground + 1);
				for (const thing of things) {
					const x = Math.round(thing.x);
					if (thing.kind === 'rock') {
						target.sprite(x, ground - 3, rocky);
					} else if (thing.kind === 'puddle') {
						target.line(x, ground + 1, x + 8, ground + 1, false);
						target.line(x + 1, ground + 2, x + 7, ground + 2);
						target.set(x + 3, ground + 3);
						target.set(x + 5, ground + 3);
					} else if (thing.kind === 'gull') {
						target.sprite(x, 46, gullFrames[Math.floor(time / 4) % 2]);
					} else {
						target.sprite(x, thing.y, waffle);
					}
				}

				const frameRows = isDucking() ? duckFrame : (feet < ground ? jumpFrame : runFrames[Math.floor(time / 3) % 2]);
				target.sprite(playerX, Math.round(feet) - frameRows.length + 1, frameRows);
				target.smallText(1, 1, `${score()}`);
				target.sprite(70, 1, waffle);
				target.smallText(77, 1, `${waffles}`);
				if (yum > 0) {
					target.smallText(playerX - 2, Math.round(feet) - 16, 'NAM!');
				}

				if (game.isOver) {
					drawGameOver(target, title, score(), hardware.highScores.WAFFLRUN ?? score());
				}
			},
		};
		return game;
	};

	const makeSnake = () => {
		const columnCount = 31;
		const rowCount = 18;
		let snake = [{x: 8, y: 9}, {x: 7, y: 9}, {x: 6, y: 9}];
		let direction = {x: 1, y: 0};
		const turns = [];
		let food;
		let score = 0;
		let time = 0;
		let tickCount = 0;

		const placeFood = () => {
			do {
				food = {x: randomInteger(0, columnCount - 1), y: randomInteger(0, rowCount - 1)};
			} while (snake.some(part => part.x === food.x && part.y === food.y));
		};

		placeFood();
		const directions = {up: {x: 0, y: -1}, down: {x: 0, y: 1}, left: {x: -1, y: 0}, right: {x: 1, y: 0}};

		const game = {
			rate: 20,
			isOver: false,
			isFinished: false,
			tick() {
				if (game.isOver) {
					return;
				}

				time++;
				// The snake moves on fewer ticks than the screen, and faster when it is longer. It is a BASIC program, so it is never fast.
				const ticksPerStep = ti83.reducedMotion ? 1 : Math.max(2, 5 - Math.floor(score / 4));
				tickCount++;
				if (tickCount < ticksPerStep) {
					return;
				}

				tickCount = 0;
				const turn = turns.shift();
				if (turn && (turn.x !== -direction.x || turn.y !== -direction.y)) {
					direction = turn;
				}

				const head = {x: snake[0].x + direction.x, y: snake[0].y + direction.y};
				if (head.x < 0 || head.y < 0 || head.x >= columnCount || head.y >= rowCount || snake.some(part => part.x === head.x && part.y === head.y)) {
					game.isOver = true;
					recordScore('SNAKE', score);
					return;
				}

				snake.unshift(head);
				if (head.x === food.x && head.y === food.y) {
					score++;
					placeFood();
				} else {
					snake.pop();
				}
			},
			key(id) {
				if (id === 'clear') {
					game.isFinished = true;
					return;
				}

				if (directions[id] && turns.length < 3) {
					turns.push(directions[id]);
				}
			},
			draw(target) {
				target.rectangle(0, 7, 95, 57);
				target.smallText(1, 1, `SNAKE  ${score}`);
				for (const part of snake) {
					target.fill(1 + (part.x * 3), 8 + (part.y * 3), 3, 3);
				}

				if (ti83.reducedMotion || Math.floor(time / 4) % 2 === 0) {
					target.set(2 + (food.x * 3), 8 + (food.y * 3));
					target.set(1 + (food.x * 3), 9 + (food.y * 3));
					target.set(3 + (food.x * 3), 9 + (food.y * 3));
					target.set(2 + (food.x * 3), 10 + (food.y * 3));
				}

				if (game.isOver) {
					drawGameOver(target, 'CRASH!', score, hardware.highScores.SNAKE ?? score);
				}
			},
		};
		return game;
	};

	const makeFallDown = () => {
		let ball = {x: 46, y: 10};
		let floors = [];
		let score = 0;
		let speed = 0.25;
		for (let y = 24; y < height + 16; y += 16) {
			floors.push({y, gap: randomInteger(4, 78)});
		}

		const game = {
			rate: 20,
			isOver: false,
			isFinished: false,
			tick() {
				if (game.isOver) {
					return;
				}

				speed = Math.min(1.2, speed + 0.0006);
				for (const floor of floors) {
					floor.y -= speed;
					if (!floor.isCounted && floor.y < ball.y) {
						floor.isCounted = true;
						score++;
					}
				}

				floors = floors.filter(floor => floor.y > -2);
				if (floors.at(-1).y < height) {
					floors.push({y: floors.at(-1).y + 16, gap: randomInteger(4, 78)});
				}

				if (heldKeys.has('left')) {
					ball.x = Math.max(0, ball.x - 2);
				}

				if (heldKeys.has('right')) {
					ball.x = Math.min(width - 3, ball.x + 2);
				}

				ball.y += 1.5;
				for (const floor of floors) {
					const isOverGap = ball.x >= floor.gap && ball.x + 2 <= floor.gap + 12;
					if (!isOverGap && ball.y + 3 >= floor.y && ball.y + 3 <= floor.y + 3) {
						ball.y = floor.y - 3;
					}
				}

				ball.y = Math.min(ball.y, height - 3);
				if (ball.y < 0) {
					game.isOver = true;
					recordScore('FALLDOWN', score);
				}
			},
			key(id) {
				if (id === 'clear') {
					game.isFinished = true;
				}
			},
			draw(target) {
				for (const floor of floors) {
					const y = Math.round(floor.y);
					target.line(0, y, floor.gap - 1, y);
					target.line(floor.gap + 12, y, width - 1, y);
				}

				target.fill(Math.round(ball.x), Math.round(ball.y), 3, 3);
				target.smallText(1, 1, `${score}`);
				if (game.isOver) {
					drawGameOver(target, 'SQUISHED!', score, hardware.highScores.FALLDOWN ?? score);
				}
			},
		};
		return game;
	};

	// Trond’s picture of his cat, Pus, which is most of the bytes of the program.
	const makeCatPicture = () => ({
		rate: 1,
		isPausing: true,
		isOver: false,
		isFinished: false,
		tick() {},
		key(id) {
			this.isFinished = id === 'enter' || id === 'clear';
		},
		draw(target) {
			target.circle(48, 32, 14);
			target.circle(48, 32, 13.5);
			target.line(36, 25, 38, 12);
			target.line(38, 12, 45, 19);
			target.line(51, 19, 58, 12);
			target.line(58, 12, 60, 25);
			target.fill(42, 28, 3, 4);
			target.fill(52, 28, 3, 4);
			target.set(43, 29, false);
			target.set(53, 29, false);
			target.line(47, 35, 49, 35);
			target.set(48, 36);
			target.line(48, 37, 45, 39);
			target.line(48, 37, 51, 39);
			target.line(40, 35, 24, 32);
			target.line(40, 37, 24, 38);
			target.line(56, 35, 72, 32);
			target.line(56, 37, 72, 38);
			target.line(40, 46, 34, 56);
			target.line(56, 46, 62, 56);
			target.line(34, 56, 62, 56);
			target.smallText(1, 58, 'PUS, TRONDS CAT');
		},
	});

	// A program in TI-BASIC with Disp and Menu(, like Trond’s RPG, which shows a page of text or a menu at a time.
	const makeStory = pages => {
		let page = pages.start;
		let selection = 0;
		return {
			rate: 1,
			isOver: false,
			isFinished: false,
			get isPausing() {
				return !page.options;
			},
			tick() {},
			key(id) {
				if (id === 'clear') {
					this.isFinished = true;
					return;
				}

				if (page.options) {
					if (id === 'up' || id === 'down') {
						selection = (selection + (id === 'up' ? page.options.length - 1 : 1)) % page.options.length;
						return;
					}

					const number = Number(id);
					if (Number.isInteger(number) && number >= 1 && number <= page.options.length) {
						selection = number - 1;
					} else if (id !== 'enter') {
						return;
					}

					page = pages[page.options[selection][1]];
					selection = 0;
					return;
				}

				if (id === 'enter') {
					if (page.next) {
						page = pages[page.next];
					} else {
						this.isFinished = true;
					}
				}
			},
			draw(target) {
				if (page.options) {
					target.text(0, 0, ` ${page.title}`.padEnd(columns, ' '), true);
					for (const [index, [label]] of page.options.entries()) {
						target.text(0, index + 1, `${index + 1}:`, index === selection);
						target.text(2, index + 1, label);
					}
				} else {
					drawLines(target, page.lines);
				}
			},
		};
	};

	const makeRpgQuest = () => makeStory({
		start: {lines: ['RPG QUEST V0.3', 'BY TROND', '', 'LEVEL 1 OF 47', '', 'YOU WAKE UP IN', 'ROOM 8B.'], next: 'menu'},
		menu: {title: 'A WILD TEACHER!', options: [['FIGHT', 'fight'], ['RUN', 'run'], ['ASK FOR HELP', 'help'], ['EAT WAFFLE', 'waffle']]},
		fight: {lines: ['YOU USE MATH.', 'IT IS NOT VERY', 'EFFECTIVE.', '', 'TEACHER USES', 'HOMEWORK!', 'YOU LOSE 5 HP.'], next: 'end'},
		run: {lines: ['YOU RUN TO THE', 'SCHOOL YARD.', '', 'IT IS RAINING.', 'IT IS BERGEN.', 'YOU GO BACK IN.'], next: 'menu'},
		help: {lines: ['TROND SAYS:', '"JUST PRESS', 'FIGHT LOL"'], next: 'menu'},
		waffle: {lines: ['YOU EAT A WAFFLE', 'WITH BRUNOST.', '', '+10 HP', 'THE TEACHER', 'WANTS ONE TOO.'], next: 'end'},
		end: {lines: ['TO BE CONTINUED', 'IN V0.4', '', 'LEVELS 2-47', 'COMING SOON', '(TROND, 1998)'], next: undefined},
	});

	// QUIZ, Trond’s homework helper, which calculates the answer for real, and then says something else.
	const makeQuiz = () => {
		const editor = makeEditor();
		let state = 'intro';
		let answerLines = [];
		let problemCount = 0;

		const badAnswer = value => {
			const show = number => formatNumber(number);
			return randomItem([
				() => [`ANSWER: ${show(value + 1)}`, '(I THINK)'],
				() => [`ANSWER: ${show(value * 10)}`, 'OOPS. THE DOT', 'MOVED.'],
				() => ['ANSWER: 42', 'IT IS ALWAYS 42'],
				() => [`ANSWER: ABOUT ${show((Math.round(value / 10) * 10) || 7)}`, 'CLOSE ENOUGH.'],
				() => ['ANSWER: SAME AS', 'TRONDS. JUST', 'COPY IT.'],
				() => [`ANSWER: ${show(value)}`, 'BUT SHOW YOUR', 'WORK? NO.'],
				() => ['ANSWER: BLUE'],
				() => [`ANSWER: ${show(-value)}`, 'OR MINUS THAT.', 'ONE OF THEM.'],
			])();
		};

		const quiz = {
			rate: 1,
			isOver: false,
			isFinished: false,
			get isPausing() {
				return state !== 'thinking';
			},
			tick() {},
			key(id) {
				if (id === 'clear' && state !== 'input') {
					this.isFinished = true;
					return;
				}

				if (state === 'intro' || state === 'answer') {
					if (problemCount >= 3) {
						if (id === 'enter') {
							state = 'grade';
						}

						return;
					}

					// Any key goes on to the next problem, and a key that types also starts it, so the first digit is not lost.
					state = 'input';
					editor.clear();
					if (id === 'enter') {
						return;
					}
				}

				if (state === 'grade') {
					this.isFinished = id === 'enter';
					return;
				}

				if (state !== 'input') {
					return;
				}

				// The program asks with Input, so the keys type like on the home screen, with 2nd and ALPHA.
				const name = resolveKey(id, false);
				if (name === 'enter') {
					let value;
					try {
						value = checked(evaluate(parse(editor.tokens).expression), 0);
					} catch (error) {
						if (!(error instanceof CalculatorError)) {
							throw error;
						}
					}

					problemCount++;
					answerLines = value === undefined ? ['EVEN I CANT DO', 'THAT ONE. ASK', 'PAPPA.'] : badAnswer(value);
					state = 'thinking';
					setTimeout(() => {
						state = 'answer';
						requestRender();
					}, 1600);
				} else if (name === 'clear') {
					editor.clear();
				} else if (name) {
					editor.handle(name);
				}
			},
			draw(target) {
				if (state === 'intro') {
					drawLines(target, ['HOMEWORK HELPER', 'V1.3 BY TROND', '', 'TYPE YOUR MATH', 'HOMEWORK. IT IS', 'ALWAYS RIGHT', '(99%)']);
				} else if (state === 'input') {
					drawLines(target, ['PROBLEM?']);
					const {characters, cursorIndex} = editor.layout();
					for (const [index, chunk] of wrap(characters).entries()) {
						target.text(0, index + 1, chunk.join(''));
					}

					drawCursor(target, cursorIndex % columns, 1 + Math.floor(cursorIndex / columns), characters[cursorIndex] ?? ' ');
				} else if (state === 'thinking') {
					drawLines(target, ['PROBLEM?', tokensText(editor.tokens), '', 'THINKING...']);
				} else if (state === 'answer') {
					const row = drawLines(target, ['PROBLEM?', tokensText(editor.tokens), '', ...answerLines]);
					target.text(0, Math.min(row + 1, rows - 1), problemCount >= 3 ? 'ENTER' : 'ENTER=NEXT');
				} else {
					drawLines(target, ['GRADE: D-', '', 'HERR OLSEN:', '"SEE ME AFTER', 'CLASS, SINDRE."']);
				}
			},
		};
		return quiz;
	};

	// The programs that exist, mine and Trond’s, with their size in bytes, whether they are in TI-BASIC (which shows the busy indicator) or assembly, and their code for PRGM EDIT.
	const programCatalog = {
		PHOENIX: {
			size: 8977,
			isBasic: false,
			make: makePhoenix,
			source: ['3E01CD7C47CD4C40', '210000227F86CD9A', '45C9FD7E0EE60228', '0BCD5848AF32C186', 'C3C247F5C5D5E5CD', 'B248E1D1C1F1C9DB', '00E6033E00D30021', 'End', '0000', 'End'],
		},
		WAFFLRUN: {
			size: 3312,
			isBasic: true,
			make: makeWaffleRun,
			source: ['ClrHome', 'Disp "WAFFLE RUN"', 'Disp "BY SINDRE 1999"', '0→S:55→F:0→V', 'Lbl A', 'getKey→K', 'If K=21 and F=55', '⁻3.6→V', 'V+.32→V', 'F+V→F', 'If F>55:55→F', 'S+1→S', 'Pt-On(12,F)', 'If pxl-Test(F,X)', 'Goto B', 'Goto A', 'Lbl B', 'Disp "AU! ROCKY!"', 'Disp S'],
		},
		SNAKE: {
			size: 1560,
			isBasic: true,
			make: makeSnake,
			source: ['ClrDraw', 'AxesOff', '8→X:9→Y:1→D', '0→S', 'Lbl 1', 'getKey→K', 'If K=24:3→D', 'If K=26:1→D', 'If K=25:4→D', 'If K=34:2→D', 'X+(D=1)-(D=3)→X', 'Y+(D=2)-(D=4)→Y', 'Pt-On(X,Y)', 'Goto 1'],
		},
		QUIZ: {
			size: 921,
			isBasic: true,
			make: makeQuiz,
			source: ['ClrHome', 'Disp "HOMEWORK HELPER"', 'Input "PROBLEM?",A', 'randInt(1,8)→R', 'If R=1:Disp A+1', 'If R=2:Disp 10A', 'If R=3:Disp 42', 'If R=7', 'Disp "BLUE"', 'Disp "(I THINK)"'],
		},
		FALLDOWN: {
			size: 2348,
			isBasic: true,
			make: makeFallDown,
			source: ['ClrDraw', 'AxesOff', '46→X:10→Y', 'Lbl A', 'getKey→K', 'X-2(K=24)+2(K=26)→X', 'Y+1→Y', 'Pt-On(X,Y)', 'If Y<0:Goto B', 'Goto A', 'Lbl B', 'Disp "SQUISHED!"'],
		},
		CATPIC: {
			size: 4116,
			isBasic: true,
			make: makeCatPicture,
			source: ['ClrDraw', 'AxesOff', 'RecallPic 1', 'Text(57,1,"PUS")', 'Pause', 'ClrDraw', 'AxesOn'],
		},
		RPGQUEST: {
			size: 18_400,
			isBasic: true,
			make: makeRpgQuest,
			source: ['ClrHome', 'Disp "RPG QUEST V0.3"', 'Disp "BY TROND"', '100→H', 'Lbl M', 'Menu("A WILD TEACHER!","FIGHT",F,"RUN",R)', 'Lbl F', 'H-5→H', 'Goto E', 'Lbl R', 'Goto M', 'Lbl E', 'Disp "TO BE CONTINUED"'],
		},
	};

	// The bytes that the programs use, and a little for the variables and the functions of Y=.
	const usedMemory = () => {
		let total = 230;
		for (const name of memory.programs) {
			total += programCatalog[name]?.size ?? 0;
		}

		return total;
	};

	const freeMemory = () => totalMemory - usedMemory();

	// MARK: Running programs

	const finishProgram = () => {
		modifier = '';
		pushHistory('Done', 'right');
		go(home);
		ti83.say('Done. PRGM for another game.');
	};

	// How long the score box ignores ENTER, so an ENTER that was meant as a shot or a jump when the game ended does not close it before the visitor sees it.
	const gameOverPause = 1000;

	const makeProgramScreen = (name, program) => {
		const game = program.make();
		let tickSeconds = 0;
		let overTime;
		const step = () => {
			game.tick();
			if (game.isOver) {
				overTime ??= performance.now();
			}
		};

		return {
			// A program gets the keys as they are, before 2nd and ALPHA, so 2nd can be the fire button of a game.
			isRaw: true,
			isBusy: () => program.isBasic && !game.isOver,
			isPaused: () => Boolean(game.isPausing),
			update(seconds) {
				drainBatteries(seconds * 0.25);
				if (ti83.reducedMotion || game.isPausing) {
					return false;
				}

				tickSeconds += seconds;
				let isChanged = false;
				while (tickSeconds >= 1 / game.rate) {
					tickSeconds -= 1 / game.rate;
					step();
					isChanged = true;
				}

				return isChanged;
			},
			draw(target) {
				game.draw(target);
			},
			key(id) {
				if (id === 'on') {
					showError('BREAK', {
						onQuit: () => go(home),
						onGoto: () => go(makeProgramViewer(name)),
					});
					return true;
				}

				// The score box of a game that is over closes with ENTER or CLEAR.
				if (game.isOver) {
					if (id === 'clear' || (id === 'enter' && performance.now() - overTime >= gameOverPause)) {
						finishProgram();
					}

					return true;
				}

				game.key(id);
				// With reduced motion, the game goes on one step for each key, so nothing moves by itself.
				if (ti83.reducedMotion && !game.isPausing) {
					step();
				}

				if (game.isFinished) {
					finishProgram();
				}

				return true;
			},
		};
	};

	const gameTips = {
		PHOENIX: 'PHOENIX! ◀ ▶ to fly, 2nd or ▲ to shoot, ▼ for the shield. CLEAR quits.',
		WAFFLRUN: 'WAFFLE RUN! 2nd or ▲ jumps over Rocky and the puddles, ▼ ducks under the seagulls. Catch the waffles!',
		SNAKE: 'SNAKE! The arrows turn. Do not hit the wall.',
		QUIZ: 'QUIZ, Trond’s homework helper. Type a math problem and ENTER.',
		FALLDOWN: 'FALLDOWN, from Trond! ◀ ▶ to roll through the gaps, before the floors push you out the top.',
		CATPIC: 'CATPIC: Trond’s picture of his cat. That is why it is so big.',
		RPGQUEST: 'RPGQUEST, Trond’s RPG, 47 levels (one is done). ▲ ▼ and ENTER.',
	};

	const runProgram = name => {
		const program = programCatalog[name];
		if (!program || !memory.programs.includes(name)) {
			showError('UNDEFINED', {onQuit: () => go(home)});
			return;
		}

		modifier = '';
		go(makeProgramScreen(name, program));
		ti83.say(gameTips[name]);
	};

	const makeProgramViewer = name => ({
		top: 0,
		draw(target) {
			target.text(0, 0, `PROGRAM:${name}`);
			const lines = programCatalog[name].source.flatMap(line => wrap([...`:${line}`]));
			this.lineCount = lines.length;
			for (let row = 1; row < rows; row++) {
				const line = lines[this.top + row - 1];
				if (line) {
					target.text(0, row, line.join(''));
				}
			}

			drawCursor(target, 1, 1, lines[this.top]?.[1] ?? ' ');
		},
		key(name) {
			if (name === 'up' || name === 'down') {
				this.top = clamp(this.top + (name === 'up' ? -1 : 1), 0, Math.max(0, (this.lineCount ?? 1) - 1));
				return true;
			}

			if (name === 'quit' || name === 'clear') {
				go(home);
				return true;
			}

			// The code can be read, but I do not let anybody change it.
			return name.startsWith('token:') || name === 'del' || name === 'enter' || name === 'left' || name === 'right';
		},
	});

	const openProgramMenu = () => {
		const names = [...memory.programs].sort();
		go(makeMenu([
			{title: 'EXEC', items: names.map(name => ({label: name, action() {
				// Like on the real one, EXEC only types the name, and ENTER runs it, so the visitor gets told.
				pasteInto(home, `prgm${name}`);
				ti83.say(`prgm${name} is typed. Press ENTER to run it!`);
			}}))},
			{title: 'EDIT', items: names.map(name => ({label: name, action: () => go(makeProgramViewer(name))}))},
			{title: 'NEW', items: [{label: 'Create New', action() {
				go(home);
				ti83.say('A new game takes all of math class to type. I copy one from Trond instead.');
			}}]},
		]));
		if (names.length === 0) {
			ti83.say('No programs. 😢 Get some from Trond with the link cable!');
		}
	};

	// MARK: MEM

	const resetMemory = () => {
		memory = {
			...defaultMemory(),
			programs: [],
			functions: emptyFunctions(),
			history: [{text: 'Mem cleared', align: 'left'}],
			entries: [],
		};
		home.editor.clear();
		yEditor.index = 0;
		yEditor.cursor = 0;
		markGraphDirty();
		saveSoon();
	};

	const makeMessage = (lines, onKey = () => go(home)) => ({
		draw(target) {
			drawLines(target, lines);
		},
		key() {
			onKey();
			return true;
		},
	});

	const memoryLine = (label, value) => `${label}${String(value).padStart(columns - label.length, ' ')}`;

	const openDeleteScreen = () => {
		go({
			selection: 0,
			draw(target) {
				const names = [...memory.programs].sort();
				target.text(0, 0, 'DELETE:Prgm');
				if (names.length === 0) {
					target.text(0, 2, 'Nothing left.');
					return;
				}

				this.selection = clamp(this.selection, 0, names.length - 1);
				const top = clamp(this.selection - 6, 0, names.length);
				for (const [index, name] of names.slice(top, top + 7).entries()) {
					const isSelected = top + index === this.selection;
					target.text(0, index + 1, `${isSelected ? '▸' : ' '}${name.padEnd(9, ' ')}${String(programCatalog[name]?.size ?? 0).padStart(6, ' ')}`);
				}
			},
			key(name) {
				const names = [...memory.programs].sort();
				if (name === 'up' || name === 'down') {
					this.selection = clamp(this.selection + (name === 'up' ? -1 : 1), 0, Math.max(0, names.length - 1));
				} else if (name === 'enter' && names[this.selection]) {
					// Like the real one, it deletes at once, without asking.
					const deleted = names[this.selection];
					memory.programs = memory.programs.filter(program => program !== deleted);
					saveSoon();
					ti83.say(`${deleted} is deleted. Now there are ${freeMemory()} bytes free.`);
				} else if (name === 'clear' || name === 'quit') {
					go(home);
				}

				return true;
			},
		});
	};

	const openMemoryMenu = () => {
		go(makeMenu([{
			title: 'MEMORY',
			items: [
				{label: 'Check RAM…', action() {
					go(makeMessage([
						memoryLine('MEM FREE', freeMemory()),
						memoryLine('Real', 15 + Object.keys(memory.variables).length * 15),
						memoryLine('List', 0),
						memoryLine('Matrix', 0),
						memoryLine('Y-Vars', 215),
						memoryLine('Prgm', usedMemory() - 230),
						memoryLine('Pic', 0),
						memoryLine('GDB', 0),
					]));
				}},
				{label: 'Delete…', action: () => go(makeMenu([{title: 'DELETE FROM…', items: [
					...['All…', 'Real…', 'List…', 'Matrix…', 'Y-Vars…'].map(label => ({label, action() {
						go(home);
						ti83.say('There is nothing in there to delete. Only programs.');
					}})),
					{label: 'Prgm…', action: openDeleteScreen},
					{label: 'Pic…', action() {
						go(home);
						ti83.say('No pictures. Trond’s cat is in CATPIC.');
					}},
				]}]))},
				{label: 'Clear Entries', action() {
					memory.entries = [];
					pushHistory('Clear Entries');
					pushHistory('Done', 'right');
					go(home);
				}},
				{label: 'ClrAllLists', action() {
					pushHistory('ClrAllLists');
					pushHistory('Done', 'right');
					go(home);
				}},
				{label: 'Reset…', action() {
					const menu = makeMenu([{title: 'RESET MEMORY', items: [
						{label: 'No', action: () => go(home)},
						{label: 'Reset', action() {
							resetMemory();
							go(home);
							ti83.say('Mem cleared. 😢 All my games are gone: PHOENIX, WAFFLRUN, SNAKE, QUIZ, everything. Trond has copies, if the link cable is in.');
							ti83.toast('😢 Mem cleared. All my games are gone!');
						}},
					]}]);
					const drawMenu = menu.draw.bind(menu);
					menu.draw = target => {
						drawMenu(target);
						drawLines(target, ['Resetting memory', 'erases all data', 'and programs.'], 4);
					};

					go(menu);
					ti83.say('Are you sure? 2:Reset erases all the games.');
				}},
			],
		}]));
	};

	// MARK: LINK

	const trond = {mode: 'select', program: undefined};

	// The programs on Trond’s calculator, in the order of his link menu.
	const trondPrograms = ['FALLDOWN', 'CATPIC', 'RPGQUEST', 'PHOENIX', 'WAFFLRUN', 'SNAKE', 'QUIZ'];

	const drawTrond = target => {
		if (trond.mode === 'transmitting') {
			target.text(0, 0, 'Transmitting...');
			target.text(0, 2, `▪${trond.program}`);
			target.text(12, 2, 'PRGM');
			drawBusyIndicator(target);
		} else if (trond.mode === 'error') {
			target.text(0, 0, 'ERR:LINK');
			target.text(0, 1, '1:', true);
			target.text(2, 1, 'Quit');
		} else {
			target.text(0, 0, 'SELECT', true);
			target.text(7, 0, 'TRANSMIT');
			for (const [index, name] of trondPrograms.entries()) {
				target.text(0, index + 1, `${trond.program === name ? '▪' : ' '}${name}`);
				target.text(12, index + 1, 'PRGM');
			}
		}
	};

	const receiveScreen = {
		received: [],
		receiving: undefined,
		isBusy: () => true,
		enter() {
			this.received = [];
			this.receiving = undefined;
		},
		draw(target) {
			target.text(0, 0, this.receiving ? 'Receiving...' : 'Waiting...');
			for (const [index, name] of this.received.slice(-6).entries()) {
				target.text(0, index + 2, `▪${name}`);
				target.text(12, index + 2, 'PRGM');
			}
		},
		key(name) {
			if (name === 'on' || name === 'quit' || name === 'clear') {
				this.receiving = undefined;
				go(home);
			}

			return true;
		},
	};

	const getReadyToReceive = () => {
		if (!isOn && !turnOn()) {
			return;
		}

		if (isTeacherHere) {
			sendTeacherAway();
		}

		receiveScreen.receiving = undefined;
		go(receiveScreen);
		ti83.say('Waiting… Now press a Send button on Trond’s TI-83.');
	};

	const finishTransfer = name => {
		// The cable can be pulled out during a transfer, which ends it.
		if (trond.mode !== 'transmitting' || trond.program !== name) {
			return;
		}

		trond.mode = 'select';
		isTrondDirty = true;
		wake();
		receiveScreen.receiving = undefined;
		if (screen !== receiveScreen) {
			return;
		}

		const {size} = programCatalog[name];
		if (memory.programs.includes(name)) {
			go(makeMenu([{title: 'DuplicateName', items: [
				{label: 'Rename', action() {
					go(receiveScreen);
					ti83.say(`Renaming needs a new name, and I like ${name}. Omitted.`);
				}},
				{label: 'Overwrite', action() {
					go(receiveScreen);
					receiveScreen.received.push(name);
					ti83.say(`${name} is overwritten with Trond’s copy. Same game.`);
				}},
				{label: 'Omit', action: () => go(receiveScreen)},
				{label: 'Quit', action: () => go(home)},
			]}]));
			ti83.say(`I already have ${name}!`);
			return;
		}

		if (size > freeMemory()) {
			showError('MEMORY', {onQuit: () => go(home), hint: `ERR:MEMORY. ${name} is ${size} bytes, and I have ${freeMemory()} free. Trond: “Delete something in 2nd MEM, or reset it, lol.”`});
			return;
		}

		memory.programs.push(name);
		saveSoon();
		receiveScreen.received.push(name);
		requestRender();
		ti83.say(`Got ${name}! It is in PRGM now, and ${freeMemory()} bytes are free.`);
		ti83.toast(`📥 ${name} copied from Trond’s TI-83!`);
	};

	const sendFromTrond = name => {
		if (trond.mode === 'transmitting') {
			return;
		}

		if (!isOn || screen !== receiveScreen) {
			trond.mode = 'error';
			isTrondDirty = true;
			wake();
			ti83.say('ERR:LINK on Trond’s. Trond: “Yours is not waiting! 2nd LINK, ▶ RECEIVE, ENTER.” Or press Get My TI-83 Ready to Receive.');
			setTimeout(() => {
				if (trond.mode === 'error') {
					trond.mode = 'select';
					isTrondDirty = true;
					wake();
				}
			}, 2500);
			return;
		}

		trond.mode = 'transmitting';
		trond.program = name;
		receiveScreen.receiving = name;
		isTrondDirty = true;
		requestRender();
		ti83.say(`Transmitting ${name}… The link cable is slow.`);
		setTimeout(() => {
			finishTransfer(name);
		}, 1200 + (programCatalog[name].size / 5));
	};

	const openLinkMenu = () => {
		const transmittingScreen = {
			isBusy: () => true,
			draw(target) {
				target.text(0, 0, 'Transmitting...');
			},
			key() {
				go(home);
				return true;
			},
		};
		const sendAll = {label: 'All+…', action() {
			go(transmittingScreen);
			setTimeout(() => {
				if (screen !== transmittingScreen) {
					return;
				}

				go(home);
				ti83.say(isLinked ? 'Trond: “I have all of yours already. Mine are better.”' : 'ERR:LINK would come, but there is no cable. Press 🔌 Link Cable to Trond.');
			}, 2000);
		}};
		go(makeMenu([
			{title: 'SEND', items: [sendAll, {...sendAll, label: 'AllK…'}, {...sendAll, label: 'Prgm…'}, {...sendAll, label: 'List…'}]},
			{title: 'RECEIVE', items: [{label: 'Receive', action() {
				go(receiveScreen);
				ti83.say(isLinked ? 'Waiting… Now press a Send button on Trond’s TI-83.' : 'Waiting… for a cable. Press 🔌 Link Cable to Trond.');
			}}]},
		]));
	};

	// MARK: Power and batteries

	const updateBatteryButton = () => {
		const charge = batteryCharge();
		batteriesButton.setAttribute('aria-pressed', String(isDoorOpen));
		batteriesButton.dataset.state = isDoorOpen ? 'on' : (charge <= 0 ? 'dead' : (charge < 25 ? 'low' : ''));
	};

	const lowBatteryScreen = makeMessage(['Your batteries', 'are low.', '', 'Recommend', 'change of', 'batteries.']);

	function turnOn() {
		if (isDoorOpen) {
			ti83.say('The battery door is open. Close it first.');
			return false;
		}

		if (batteryCharge() <= 0) {
			ti83.say(hardware.batteries.includes(null) ? 'Nothing. It needs all four AAA batteries.' : 'Nothing happens. The batteries are dead. Press 🔋 Change the Batteries.');
			return false;
		}

		isOn = true;
		modifier = '';
		lastKeyTime = performance.now();
		if (hardware.isMemoryLost) {
			// Without the AAA batteries and the backup battery, the memory has no power, and the TI says so when it wakes up.
			hardware.isMemoryLost = false;
			resetMemory();
			ti83.toast('😢 Mem cleared. The memory had no power, and all my games are gone!');
		}

		go(batteryCharge() < 25 ? lowBatteryScreen : home);
		updateBatteryButton();
		return true;
	}

	const turnOff = () => {
		if (isTeacherHere) {
			sendTeacherAway();
		}

		if (screen?.isRaw) {
			go(home);
		}

		isOn = false;
		modifier = '';
		updateModifierKeys();
		requestRender();
	};

	function drainBatteries(amount) {
		if (!isOn || isDoorOpen) {
			return;
		}

		const before = batteryCharge();
		hardware.batteries = hardware.batteries.map(charge => charge === null ? null : Math.max(0, charge - amount));
		const after = batteryCharge();
		if (before >= 25 && after < 25) {
			ti83.say('The screen gets faint. The batteries are low! 2nd and ▲ turns up the contrast, for a while.');
		}

		if (after <= 0) {
			turnOff();
			ti83.say('It died. The four AAA batteries are empty. Press 🔋 Change the Batteries.');
		}

		if (Math.floor(before) !== Math.floor(after)) {
			isDirty = true;
			updateBatteryButton();
			saveSoon();
		}
	}

	const adjustContrast = change => {
		hardware.contrast = clamp(hardware.contrast + change, 0, 9);
		contrastShownUntil = performance.now() + 1500;
		saveSoon();
		if (hardware.contrast === 9 && batteryCharge() < 25) {
			ti83.say('Contrast 9, and it is still faint. Time for new batteries.');
		}
	};

	const updateDoor = () => {
		for (const [index, button] of batteryButtons.entries()) {
			const charge = hardware.batteries[index];
			if (charge === null) {
				button.dataset.state = 'out';
				button.textContent = 'Empty: put in a new AAA';
			} else if (charge >= 99.5) {
				button.dataset.state = 'new';
				button.textContent = 'AAA, new ✨';
			} else {
				button.dataset.state = 'old';
				button.textContent = `AAA, ${Math.round(charge)}% (take out)`;
			}
		}

		backupButton.dataset.state = hardware.isBackupIn ? '' : 'out';
		backupButton.textContent = hardware.isBackupIn ? '🪙 Backup Battery (CR1616)' : '🪙 Empty: put the backup battery back';
		updateBatteryButton();
	};

	const checkMemoryPower = () => {
		if (!hardware.isBackupIn && hardware.batteries.every(charge => charge === null)) {
			hardware.isMemoryLost = true;
		}
	};

	const openDoor = () => {
		isDoorOpen = true;
		if (isTeacherHere) {
			sendTeacherAway();
		}

		turnOff();
		batteryDoor.hidden = false;
		updateDoor();
		ti83.say('The battery door is open, so it is off. Take out the old AAA batteries, and put in new ones.');
	};

	const closeDoor = () => {
		isDoorOpen = false;
		batteryDoor.hidden = true;
		updateDoor();
		const present = hardware.batteries.filter(charge => charge !== null);
		const isAnyNew = present.some(charge => charge >= 99.5);
		const isMixed = isAnyNew && present.some(charge => charge < 99.5);
		saveSoon();
		if (turnOn() && isMixed) {
			ti83.say('Pappa: “Never mix old and new batteries!” It works anyway, until the old ones die.');
		} else if (isOn) {
			ti83.say(isAnyNew ? 'New batteries! The screen is dark and sharp again.' : 'The battery door is closed, with the same old batteries.');
		}
	};

	// MARK: The teacher

	const homework = new Display();
	drawAxes(homework, standardWindow());
	homework.line(0, Math.round(31 - (((2 * -10) + 1) * 31 / 10)), 94, Math.round(31 - (((2 * 10) + 1) * 31 / 10)));

	const teacherScreen = {
		draw(target) {
			target.pixels.set(homework.pixels);
			const row = Math.round(31 - (5 * 31 / 10));
			const column = Math.round(47 + (2 * 47 / 10));
			target.invert(column, row);
			for (const offset of [-2, -1, 1, 2]) {
				target.invert(column + offset, row);
				target.invert(column, row + offset);
			}

			target.smallText(1, 1, 'Y1=2X+1');
			target.smallText(1, 57, 'X=2');
			target.smallText(48, 57, 'Y=5');
		},
		key: () => true,
	};

	const teacherLines = [
		'Herr Olsen: “Very good, Sindre. Linear functions, page 112.”',
		'Herr Olsen: “Y=2X+1. Excellent. The whole class should be like Sindre.”',
		'Herr Olsen looks at the screen, nods, and walks on. He smells of coffee.',
		'Herr Olsen: “And what is the slope?” Me: “Two!” Him: “Good!”',
	];

	function sendTeacherAway() {
		isTeacherHere = false;
		teacherButton.textContent = '👨‍🏫 The Teacher Is Coming!';
		teacherButton.dataset.state = '';
		if (screenBeforeTeacher) {
			go(screenBeforeTeacher);
		}
	}

	ti83.on(teacherButton, 'click', () => {
		if (isTeacherHere) {
			sendTeacherAway();
			ti83.say('Phew. He is gone. Back to the game.');
			return;
		}

		if (!isOn && !turnOn()) {
			ti83.say('Herr Olsen: “Why is your calculator off? Exercise 4b, please.”');
			return;
		}

		// The screen switches at once, without any animation, because there is no time.
		isTeacherHere = true;
		screenBeforeTeacher = screen;
		modifier = '';
		updateModifierKeys();
		go(teacherScreen);
		teacherButton.textContent = '😌 He Is Gone';
		teacherButton.dataset.state = 'on';
		ti83.say(randomItem(teacherLines));
	});

	// MARK: Turn it over

	let isFlipped = false;

	// The letters that the digits look like upside down.
	const upsideDownLetters = {0: 'O', 1: 'I', 2: 'Z', 3: 'E', 4: 'h', 5: 'S', 6: 'g', 7: 'L', 8: 'B', 9: 'G', '.': '.'};

	const shownNumber = () => {
		const typed = tokensText(home.editor.tokens);
		if (screen === home && /^[\d.]+$/.test(typed)) {
			return typed;
		}

		const last = memory.history.at(-1);
		if (screen === home && typed === '' && last && /^⁻?[\d.]+$/.test(last.text)) {
			return last.text.replace('⁻', '');
		}

		return undefined;
	};

	const describeUpsideDown = () => {
		const number = shownNumber();
		if (!isOn || number === undefined) {
			return {line: '…', text: 'Upside down, the screen says nothing. Type a number first, like 0.7734 from the sticky note, and turn it over before ENTER.'};
		}

		const reading = [...number].reverse().map(character => upsideDownLetters[character] ?? '').join('');
		if (reading.toUpperCase().includes('BOOB')) {
			return {line: '🙈', text: 'Mamma walks in, right then. Turn it back, quick!'};
		}

		const word = reading.replaceAll('.', '');
		if (word === 'hELL') {
			return {line: '“hELL”', text: number.startsWith('.') ? 'It says “hELL”! The TI drops the 0 of 0.7734 after ENTER, so the O is gone. Mamma does not like that word. Type it again, and turn it over before ENTER.' : 'It says “hELL”. Mamma does not like that word. Try 0.7734.'};
		}

		return {line: `“${word}”`, text: `It says “${word}”! Trond laughs so loud that Herr Olsen looks.`};
	};

	ti83.on(flipButton, 'click', () => {
		isFlipped = !isFlipped;
		calculatorElement.dataset.state = isFlipped ? 'flipped' : '';
		setPressed(flipButton, isFlipped);
		upsideDownLine.hidden = !isFlipped;
		if (isFlipped) {
			const {line, text} = describeUpsideDown();
			upsideDownLine.textContent = line;
			ti83.say(text);
		} else {
			ti83.say('Right side up again.');
		}
	});

	for (const button of numberButtons) {
		ti83.on(button, 'click', () => {
			if (!isOn && !turnOn()) {
				return;
			}

			if (isTeacherHere) {
				sendTeacherAway();
			}

			go(home);
			home.editor.set([...button.dataset.ti83Number]);
			requestRender();
			if (isFlipped) {
				const {line, text} = describeUpsideDown();
				upsideDownLine.textContent = line;
				ti83.say(text);
			} else {
				ti83.say(`${button.dataset.ti83Number} is typed. Now press 🙃 Turn It Over!`);
			}
		});
	}

	// MARK: Keys

	const keyTokens = {
		0: '0',
		1: '1',
		2: '2',
		3: '3',
		4: '4',
		5: '5',
		6: '6',
		7: '7',
		8: '8',
		9: '9',
		'.': '.',
		add: '+',
		subtract: '-',
		multiply: '*',
		divide: '/',
		power: '^',
		square: '²',
		inverse: '¹',
		negate: '⁻',
		open: '(',
		close: ')',
		comma: ',',
		sin: 'sin(',
		cos: 'cos(',
		tan: 'tan(',
		log: 'log(',
		ln: 'ln(',
		store: '→',
		xt: 'X',
	};

	// The yellow functions of 2nd.
	const secondNames = {
		'y=': 'statplot',
		window: 'tblset',
		zoom: 'format',
		trace: 'calc',
		graph: 'table',
		mode: 'quit',
		del: 'ins',
		alpha: 'alphaLock',
		xt: 'link',
		stat: 'list',
		math: 'test',
		matrx: 'angle',
		prgm: 'draw',
		vars: 'distr',
		sin: 'token:sin¹(',
		cos: 'token:cos¹(',
		tan: 'token:tan¹(',
		power: 'token:π',
		square: 'token:√(',
		comma: 'token:ᴇ',
		open: 'token:{',
		close: 'token:}',
		divide: 'token:e',
		log: 'token:10^(',
		ln: 'token:e^(',
		multiply: 'token:[',
		subtract: 'token:]',
		store: 'rcl',
		add: 'mem',
		on: 'off',
		0: 'catalog',
		'.': 'token:i',
		negate: 'token:Ans',
		enter: 'entry',
		up: 'contrastUp',
		down: 'contrastDown',
		left: 'lineStart',
		right: 'lineEnd',
		7: 'token:u',
		8: 'token:v',
		9: 'token:w',
		1: 'token:L1',
		2: 'token:L2',
		3: 'token:L3',
		4: 'token:L4',
		5: 'token:L5',
		6: 'token:L6',
	};

	// The green letters of ALPHA.
	const alphaLetters = {
		math: 'A',
		matrx: 'B',
		prgm: 'C',
		vars: 'D',
		inverse: 'E',
		sin: 'F',
		cos: 'G',
		tan: 'H',
		power: 'I',
		square: 'J',
		comma: 'K',
		open: 'L',
		close: 'M',
		divide: 'N',
		log: 'O',
		7: 'P',
		8: 'Q',
		9: 'R',
		multiply: 'S',
		ln: 'T',
		4: 'U',
		5: 'V',
		6: 'W',
		subtract: 'X',
		store: 'Y',
		1: 'Z',
		2: 'θ',
		add: '"',
		0: ' ',
		'.': ':',
		negate: '?',
	};

	const keyForLetter = Object.fromEntries(Object.entries(alphaLetters).map(([key, letter]) => [letter, key]));

	const keyName = id => keyTokens[id] ? `token:${keyTokens[id]}` : id;

	let lastSecondName;

	// Turns a key into what it does, with 2nd and ALPHA, or undefined when the key only sets 2nd or ALPHA.
	function resolveKey(id, isRepeat) {
		// A held arrow after 2nd goes on with the contrast, like holding the key on the real one.
		if (isRepeat && lastSecondName && (id === 'up' || id === 'down')) {
			return lastSecondName;
		}

		lastSecondName = undefined;
		if (modifier === '2nd') {
			modifier = '';
			if (id === '2nd') {
				return undefined;
			}

			const name = secondNames[id] ?? keyName(id);
			if (name === 'alphaLock') {
				modifier = 'alphaLock';
				return undefined;
			}

			if (name === 'contrastUp' || name === 'contrastDown') {
				lastSecondName = name;
			}

			return name;
		}

		if (modifier === 'alpha' || modifier === 'alphaLock') {
			if (id === 'alpha' || id === '2nd') {
				modifier = id === '2nd' ? '2nd' : '';
				return undefined;
			}

			const letter = alphaLetters[id];
			if (modifier === 'alpha' || (!letter && !['left', 'right', 'up', 'down', 'del'].includes(id))) {
				modifier = '';
			}

			return letter ? `token:${letter}` : keyName(id);
		}

		if (id === '2nd' || id === 'alpha') {
			modifier = id;
			return undefined;
		}

		return keyName(id);
	}

	const nobodyKnowsTabs = {
		stat: [['EDIT', ['Edit…', 'SortA(', 'SortD(', 'ClrList', 'SetUpEditor']], ['CALC', ['1-Var Stats', '2-Var Stats', 'Med-Med', 'LinReg(ax+b)', 'QuadReg', 'CubicReg', 'QuartReg', 'LinReg(a+bx)']], ['TESTS', ['Z-Test…', 'T-Test…', '2-SampZTest…', '2-SampTTest…']]],
		matrx: [['NAMES', ['[A]', '[B]', '[C]', '[D]', '[E]']], ['MATH', ['det(', 'T', 'dim(', 'Fill(', 'identity(']], ['EDIT', ['[A]', '[B]', '[C]']]],
		vars: [['VARS', ['Window…', 'Zoom…', 'GDB…', 'Picture…', 'Statistics…', 'Table…', 'String…']], ['Y-VARS', ['Function…', 'Parametric…', 'Polar…', 'On/Off…']]],
		statplot: [['STAT PLOTS', ['Plot1…Off', 'Plot2…Off', 'Plot3…Off', 'PlotsOff', 'PlotsOn']]],
		format: [['FORMAT', ['RectGC', 'CoordOn', 'GridOff', 'AxesOn', 'LabelOff']]],
		calc: [['CALCULATE', ['value', 'zero', 'minimum', 'maximum', 'intersect', 'dy/dx', 'f(x)dx']]],
		list: [['NAMES', ['L1', 'L2', 'L3', 'L4', 'L5', 'L6']], ['OPS', ['SortA(', 'SortD(', 'dim(', 'Fill(', 'seq(']], ['MATH', ['min(', 'max(', 'mean(', 'median(', 'sum(']]],
		test: [['TEST', ['=', '≠', '>', '≥', '<', '≤']], ['LOGIC', ['and', 'or', 'xor', 'not(']]],
		angle: [['ANGLE', ['°', '\'', 'r', '▸DMS', 'R▸Pr(', 'R▸Pθ(']]],
		draw: [['DRAW', ['ClrDraw', 'Line(', 'Horizontal', 'Vertical', 'Tangent(', 'DrawF', 'Shade(', 'DrawInv', 'Circle(']], ['POINTS', ['Pt-On(', 'Pt-Off(', 'Pt-Change(']], ['STO', ['StorePic', 'RecallPic', 'StoreGDB', 'RecallGDB']]],
		distr: [['DISTR', ['normalpdf(', 'normalcdf(', 'invNorm(', 'tpdf(', 'tcdf(', 'χ²pdf(']], ['DRAW', ['ShadeNorm(', 'Shade_t(']]],
		catalog: [['CATALOG', ['abs(', 'and', 'angle(', 'ANOVA(', 'Ans', 'augment(', 'AxesOff', 'AxesOn', 'a+bi']]],
		rcl: [['RCL', ['Rcl']]],
	};

	const globalKey = name => {
		switch (name) {
			case 'off': {
				turnOff();
				ti83.say('Off. Press ON to turn it on again. It remembers everything.');
				break;
			}

			case 'contrastUp':
			case 'contrastDown': {
				adjustContrast(name === 'contrastUp' ? 1 : -1);
				break;
			}

			case 'quit': {
				go(home);
				break;
			}

			case 'mode': {
				go(modeScreen);
				break;
			}

			case 'y=': {
				go(yEditor);
				break;
			}

			case 'window': {
				go(windowForm);
				break;
			}

			case 'tblset': {
				go(tableForm);
				break;
			}

			case 'zoom': {
				openZoomMenu();
				break;
			}

			case 'graph':
			case 'trace': {
				graphScreen.start(name);
				break;
			}

			case 'table': {
				tableScreen.row = 0;
				go(tableScreen);
				break;
			}

			case 'prgm': {
				openProgramMenu();
				break;
			}

			case 'math': {
				openMathMenu();
				break;
			}

			case 'mem': {
				openMemoryMenu();
				break;
			}

			case 'link': {
				openLinkMenu();
				break;
			}

			case 'entry': {
				go(home);
				home.key('entry');
				break;
			}

			case 'clear': {
				go(home);
				break;
			}

			default: {
				if (nobodyKnowsTabs[name]) {
					go(nobodyKnowsMenu(nobodyKnowsTabs[name], pasteTarget()));
				} else if (name.startsWith('token:')) {
					go(home);
					home.insert(name.slice('token:'.length));
				}
			}
		}
	};

	const keyButtonsById = new Map(keyButtons.map(button => [button.dataset.ti83Key, button]));

	function updateModifierKeys() {
		for (const [id, isArmed] of [['2nd', modifier === '2nd'], ['alpha', modifier === 'alpha' || modifier === 'alphaLock']]) {
			const button = keyButtonsById.get(id);
			button.setAttribute('aria-pressed', String(isArmed));
			if (button.dataset.state !== 'down') {
				button.dataset.state = isArmed ? 'on' : '';
			}
		}
	}

	const pressKey = (id, {isRepeat = false} = {}) => {
		if (isDoorOpen) {
			ti83.say('The battery door is open. Close it first.');
			return;
		}

		lastKeyTime = performance.now();
		if (!isOn) {
			if (id === 'on') {
				turnOn();
			} else if (!isRepeat) {
				ti83.say(batteryCharge() <= 0 ? 'Nothing. The batteries are dead.' : 'It is off. Press ON, at the bottom left.');
			}

			return;
		}

		if (isTeacherHere) {
			ti83.say('Herr Olsen is still looking. Act normal. (Press 😌 He Is Gone.)');
			return;
		}

		drainBatteries(0.03);
		isBlinkOn = true;
		blinkSeconds = 0;
		if (screen.isRaw) {
			screen.key(id);
		} else {
			const name = resolveKey(id, isRepeat);
			if (name !== undefined && !screen.key(name)) {
				globalKey(name);
			}
		}

		updateModifierKeys();
		requestRender();
	};

	// The keys that repeat while they are held, like on the real one.
	const repeatingKeys = new Set(['up', 'down', 'left', 'right', 'del']);

	const flashKey = id => {
		const button = keyButtonsById.get(id);
		if (!button) {
			return;
		}

		button.dataset.state = 'down';
		setTimeout(() => {
			button.dataset.state = '';
			updateModifierKeys();
		}, 120);
	};

	for (const button of keyButtons) {
		const id = button.dataset.ti83Key;
		let repeatTimer;
		const release = () => {
			clearTimeout(repeatTimer);
			heldKeys.delete(id);
			if (button.dataset.state === 'down') {
				button.dataset.state = '';
			}

			updateModifierKeys();
		};

		ti83.on(button, 'pointerdown', event => {
			if (event.button !== 0) {
				return;
			}

			// The screen keeps the focus, so the keys of the computer go on working after a click.
			event.preventDefault();
			canvas.focus({preventScroll: true});
			button.setPointerCapture?.(event.pointerId);
			heldKeys.add(id);
			button.dataset.state = 'down';
			pressKey(id);
			if (repeatingKeys.has(id)) {
				const repeat = () => {
					pressKey(id, {isRepeat: true});
					repeatTimer = setTimeout(repeat, 70);
				};

				repeatTimer = setTimeout(repeat, 400);
			}
		});
		ti83.on(button, 'pointerup', release);
		ti83.on(button, 'pointercancel', release);
		ti83.on(button, 'lostpointercapture', release);
		ti83.on(button, 'click', event => {
			// A click without a pointer, like from a screen reader or the keyboard.
			if (event.detail === 0) {
				// The games read the held keys, so the key counts as held for a moment.
				heldKeys.add(id);
				pressKey(id);
				setTimeout(() => {
					heldKeys.delete(id);
				}, 150);
			}
		});
	}

	const keyboardKeys = {
		0: '0',
		1: '1',
		2: '2',
		3: '3',
		4: '4',
		5: '5',
		6: '6',
		7: '7',
		8: '8',
		9: '9',
		'.': '.',
		'+': 'add',
		'-': 'subtract',
		'*': 'multiply',
		'/': 'divide',
		'^': 'power',
		'(': 'open',
		')': 'close',
		',': 'comma',
		'~': 'negate',
		Enter: 'enter',
		Backspace: 'del',
		Delete: 'del',
		Escape: 'clear',
		ArrowUp: 'up',
		ArrowDown: 'down',
		ArrowLeft: 'left',
		ArrowRight: 'right',
		F1: 'y=',
		F2: 'window',
		F3: 'zoom',
		F4: 'trace',
		F5: 'graph',
		F6: 'mode',
		F7: 'prgm',
		F8: 'math',
		Home: 'on',
	};

	let isShiftAlone = false;

	ti83.on(calculatorElement, 'keydown', event => {
		if (event.ctrlKey || event.metaKey || event.altKey) {
			return;
		}

		if (event.key === 'Shift') {
			isShiftAlone = !event.repeat;
			return;
		}

		isShiftAlone = false;
		// A key of the calculator that has the focus, from Tab, is a button, so Enter and Space press it instead of ENTER and 2nd.
		if (event.target !== canvas && (event.key === 'Enter' || event.key === ' ')) {
			return;
		}

		let id = keyboardKeys[event.key];
		if (!id && event.key === ' ' && screen.isRaw) {
			id = '2nd';
		}

		const letter = event.key.length === 1 ? event.key.toUpperCase() : '';
		if (!id && letter >= 'A' && letter <= 'Z') {
			if (letter === 'X') {
				id = 'xt';
			} else if (!screen.isRaw && keyForLetter[letter]) {
				// A letter of the computer types the letter, like ALPHA and the key.
				event.preventDefault();
				if (isOn && !isTeacherHere && modifier !== 'alphaLock') {
					modifier = 'alpha';
				}

				flashKey(keyForLetter[letter]);
				pressKey(keyForLetter[letter]);
				return;
			}
		}

		if (!id) {
			return;
		}

		event.preventDefault();
		if (event.repeat && !repeatingKeys.has(id)) {
			return;
		}

		heldKeys.add(id);
		flashKey(id);
		pressKey(id, {isRepeat: event.repeat});
	});

	ti83.on(calculatorElement, 'keyup', event => {
		if (event.key === 'Shift' && isShiftAlone) {
			isShiftAlone = false;
			flashKey('2nd');
			pressKey('2nd');
			return;
		}

		const id = keyboardKeys[event.key] ?? (event.key === ' ' ? '2nd' : undefined);
		if (id) {
			heldKeys.delete(id);
		}
	});

	ti83.on(calculatorElement, 'focusout', () => {
		heldKeys.clear();
	});

	ti83.on(canvas, 'pointerdown', () => {
		canvas.focus({preventScroll: true});
	});

	// MARK: The buttons around it

	ti83.on(linkButton, 'click', () => {
		isLinked = !isLinked;
		trondPanel.hidden = !isLinked;
		setPressed(linkButton, isLinked);
		trond.mode = 'select';
		isTrondDirty = true;
		wake();
		if (isLinked) {
			ti83.say('The link cable is in, and Trond’s TI-83 is at the other end. On mine: 2nd LINK, ▶ RECEIVE, ENTER. Then press Send on his.');
		} else {
			if (screen === receiveScreen) {
				go(home);
			}

			ti83.say('The link cable is out. Trond takes his calculator back.');
		}
	});

	ti83.on(receiveButton, 'click', getReadyToReceive);

	for (const button of sendButtons) {
		ti83.on(button, 'click', () => {
			sendFromTrond(button.dataset.ti83Send);
		});
	}

	ti83.on(batteriesButton, 'click', () => {
		if (isDoorOpen) {
			closeDoor();
		} else {
			openDoor();
			// The door is above the buttons in the page, so the focus goes into it, for the keyboard, and on a phone the door scrolls into view.
			batteryButtons[0].focus();
		}
	});

	const closeDoorAndReturn = () => {
		closeDoor();
		batteriesButton.focus();
	};

	ti83.on(closeDoorButton, 'click', closeDoorAndReturn);

	ti83.on(batteryDoor, 'keydown', event => {
		if (event.key === 'Escape') {
			event.preventDefault();
			closeDoorAndReturn();
		}
	});

	for (const [index, button] of batteryButtons.entries()) {
		ti83.on(button, 'click', () => {
			if (hardware.batteries[index] === null) {
				hardware.batteries[index] = 100;
				ti83.say('A new AAA battery from Pappa’s drawer.');
			} else {
				hardware.batteries[index] = null;
				checkMemoryPower();
				ti83.say(hardware.isMemoryLost ? 'Uh oh. No AAA batteries and no backup battery: the memory has no power now!' : 'Out it comes.');
			}

			updateDoor();
			saveSoon();
		});
	}

	ti83.on(backupButton, 'click', () => {
		hardware.isBackupIn = !hardware.isBackupIn;
		if (hardware.isBackupIn) {
			ti83.say('The round one is back. Trond can breathe again.');
		} else {
			checkMemoryPower();
			ti83.say(hardware.isMemoryLost ? 'Trond: “NOOOO! Not the round one with the AAA ones out! The memory is gone!”' : 'Trond: “NEVER take out the round one!” Phew: the AAA batteries still keep the memory.');
		}

		updateDoor();
		saveSoon();
	});

	// MARK: Start

	let secondTimer;

	// Once a second: the batteries run down while it is on, and it turns itself off after 4 minutes without a key, like the real one.
	const everySecond = () => {
		if (!isOn || isDoorOpen) {
			return;
		}

		drainBatteries(0.12);
		if (isOn && !screen.isRaw && !screen.isBusy?.() && performance.now() - lastKeyTime > 4 * 60 * 1000) {
			turnOff();
			ti83.say('It turned itself off after 4 minutes without a key, to save the batteries. Press ON.');
		}
	};

	if (batteryCharge() <= 0) {
		isOn = false;
	}

	go(home);
	updateDoor();
	updateModifierKeys();

	return {
		requestRender,
		visibilityChanged(isVisible) {
			secondTimer?.cancel();
			if (isVisible) {
				lastKeyTime = Math.max(lastKeyTime, performance.now() - (3 * 60 * 1000));
				secondTimer = ti83.interval(1000, everySecond);
				isDirty = true;
				isTrondDirty = true;
				wake();
			}
		},
	};
};

export default class extends GeoCitiesElement {
	#calculator;

	connected() {
		this.#calculator = setUpCalculator(this, this.parts);
	}

	// The whole element counts, so Trond’s screen also updates while the calculator itself is above it on a phone.
	visibilityChanged(isVisible) {
		this.#calculator.visibilityChanged(isVisible);
	}

	reducedMotionChanged() {
		this.#calculator.requestRender();
	}
}
