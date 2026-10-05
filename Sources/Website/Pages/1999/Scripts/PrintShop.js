// The Print Shop on the 1999 page: the blocky menus of the program on the screen of the school computer, where the visitor makes a greeting card, a sign, letterhead, or a banner from a border, a graphic, a layout, a font, and the words, and the dot matrix printer next to it, which prints the design line by line, with a fading ribbon, a box of paper that runs out, paper jams, and the paper that the visitor tears off, peels the strips off, folds into a card, or hangs over the page. The printer is drawn on a canvas, which runs only while it is on the screen and the tab is visible. With reduced motion, the printout appears a page at a time, without the moving head. Nothing makes a sound until the visitor turns on the sound. The design, the ribbon, the paper, and the hanging banner are kept in the browser.
const nextFrame = () => new Promise(resolve => {
	requestAnimationFrame(() => {
		resolve();
	});
});

const clamp = (value, minimum, maximum) => Math.min(Math.max(value, minimum), maximum);
const randomItem = items => items[Math.floor(Math.random() * items.length)];

// Shows a toggle button as pressed, for screen readers and for the style.
const setPressed = (button, isPressed) => {
	button.setAttribute('aria-pressed', String(isPressed));
};

// The position of a pointer on a canvas, in the pixels of the canvas.
const canvasPoint = (canvas, event) => {
	const rectangle = canvas.getBoundingClientRect();
	return {
		x: (event.clientX - rectangle.left) * canvas.width / rectangle.width,
		y: (event.clientY - rectangle.top) * canvas.height / rectangle.height,
	};
};

// A number between 0 and 1 that is always the same for the same seed, for the things that must not flicker, like the folds of the pile.
const hash = seed => {
	const value = Math.sin((seed * 127.1) + 311.7) * 43_758.5453;
	return value - Math.floor(value);
};

// The fonts: one blocky font of 5 × 7, which the styles of The Print Shop draw in different ways. Each letter is seven rows of five bits.
const glyphs = {
	A: [14, 17, 17, 31, 17, 17, 17], B: [30, 17, 17, 30, 17, 17, 30], C: [14, 17, 16, 16, 16, 17, 14], D: [30, 17, 17, 17, 17, 17, 30], E: [31, 16, 16, 30, 16, 16, 31], F: [31, 16, 16, 30, 16, 16, 16], G: [14, 17, 16, 23, 17, 17, 15], H: [17, 17, 17, 31, 17, 17, 17], I: [14, 4, 4, 4, 4, 4, 14], J: [7, 2, 2, 2, 2, 18, 12], K: [17, 18, 20, 24, 20, 18, 17], L: [16, 16, 16, 16, 16, 16, 31], M: [17, 27, 21, 21, 17, 17, 17],
	N: [17, 17, 25, 21, 19, 17, 17], O: [14, 17, 17, 17, 17, 17, 14], P: [30, 17, 17, 30, 16, 16, 16], Q: [14, 17, 17, 17, 21, 18, 13], R: [30, 17, 17, 30, 20, 18, 17], S: [15, 16, 16, 14, 1, 1, 30], T: [31, 4, 4, 4, 4, 4, 4], U: [17, 17, 17, 17, 17, 17, 14], V: [17, 17, 17, 17, 17, 10, 4], W: [17, 17, 17, 21, 21, 21, 10], X: [17, 17, 10, 4, 10, 17, 17], Y: [17, 17, 10, 4, 4, 4, 4], Z: [31, 1, 2, 4, 8, 16, 31],
	Æ: [15, 20, 20, 31, 20, 20, 23], Ø: [14, 19, 21, 21, 21, 25, 14], Å: [4, 10, 4, 14, 17, 31, 17],
	0: [14, 17, 19, 21, 25, 17, 14], 1: [4, 12, 4, 4, 4, 4, 14], 2: [14, 17, 1, 2, 4, 8, 31], 3: [30, 1, 1, 14, 1, 1, 30], 4: [2, 6, 10, 18, 31, 2, 2], 5: [31, 16, 30, 1, 1, 17, 14], 6: [6, 8, 16, 30, 17, 17, 14], 7: [31, 1, 2, 4, 8, 8, 8], 8: [14, 17, 17, 14, 17, 17, 14], 9: [14, 17, 17, 15, 1, 2, 12],
	' ': [0, 0, 0, 0, 0, 0, 0], '!': [4, 4, 4, 4, 4, 0, 4], '?': [14, 17, 1, 2, 4, 0, 4], '.': [0, 0, 0, 0, 0, 12, 12], ',': [0, 0, 0, 0, 12, 4, 8], '\'': [4, 4, 8, 0, 0, 0, 0], '-': [0, 0, 0, 31, 0, 0, 0], ':': [0, 12, 12, 0, 12, 12, 0], '&': [12, 18, 20, 8, 21, 18, 13], '♥': [0, 10, 31, 31, 14, 4, 0], '*': [0, 21, 14, 31, 14, 21, 0], '+': [0, 4, 4, 31, 4, 4, 0], '/': [1, 1, 2, 4, 8, 16, 16], '(': [2, 4, 8, 8, 8, 4, 2], ')': [8, 4, 2, 2, 2, 4, 8], '#': [10, 10, 31, 10, 31, 10, 10], '=': [0, 0, 31, 0, 31, 0, 0],
};

const heart = [
	'................',
	'................',
	'..####....####..',
	'.######..######.',
	'################',
	'#..#############',
	'#..#############',
	'################',
	'.##############.',
	'..############..',
	'...##########...',
	'....########....',
	'.....######.....',
	'......####......',
	'.......##.......',
	'................',
];

// The waffle is a heart of a Norwegian waffle iron, with the grid pressed into it and golden brown between the lines.
const waffle = heart.map((row, y) => [...row].map((character, x) => {
	if (character === '.' && !(y === 5 || y === 6)) {
		return '.';
	}

	const isEdge = [[-1, 0], [1, 0], [0, -1], [0, 1]].some(([deltaX, deltaY]) => (heart[y + deltaY]?.[x + deltaX] ?? '.') === '.' && !(y + deltaY === 5 || y + deltaY === 6));
	return isEdge || x % 3 === 1 || y % 3 === 1 ? '#' : ':';
}).join(''));

// The clip art library, 16 × 16 each: `#` is ink, `:` is half ink (every other dot), and `.` is paper.
const graphics = {
	unicorn: [
		'#...............',
		'.##.............',
		'..###...........',
		'...###.#........',
		'....######......',
		'.....#######....',
		'....#########...',
		'...##.#######:..',
		'..##########::::',
		'.###########:::.',
		'####..######::::',
		'###....######::.',
		'.......######:::',
		'........######:.',
		'........#######.',
		'.........######.',
	],
	waffle,
	heart,
	flag: [
		'................',
		'................',
		'::::.##.::::::::',
		'::::.##.::::::::',
		'::::.##.::::::::',
		'::::.##.::::::::',
		'.....##.........',
		'################',
		'################',
		'.....##.........',
		'::::.##.::::::::',
		'::::.##.::::::::',
		'::::.##.::::::::',
		'::::.##.::::::::',
		'................',
		'................',
	],
	computer: [
		'................',
		'.##############.',
		'.#............#.',
		'.#.##########.#.',
		'.#.#::::::::#.#.',
		'.#.#:##:::::#.#.',
		'.#.#::::::::#.#.',
		'.#.#:####:::#.#.',
		'.#.##########.#.',
		'.#........##..#.',
		'.##############.',
		'......####......',
		'..############..',
		'.#.#.#.#.#.#.#.#',
		'################',
		'................',
	],
	cake: [
		'...#....#....#..',
		'..#:#..#:#..#:#.',
		'...#....#....#..',
		'...#....#....#..',
		'...#....#....#..',
		'.##############.',
		'#..............#',
		'#.#.##.##.##.#.#',
		'################',
		'#::::::::::::::#',
		'#::::::::::::::#',
		'################',
		'#..#..#..#..#..#',
		'#..............#',
		'################',
		'................',
	],
	rocky: [
		'................',
		'................',
		'................',
		'.....######.....',
		'...##::::::##...',
		'..#::::::::::#..',
		'.#:.##.::.##.:#.',
		'.#:#..#::#..#:#.',
		'#::#.##::#.##::#',
		'#::.##.::.##.::#',
		'#::::::::::::::#',
		'#:::#::::::#:::#',
		'.#:::######:::#.',
		'..############..',
		'................',
		'................',
	],
	umbrella: [
		'.#.........#....',
		'.......#.....#..',
		'.....######.....',
		'...##########...',
		'..############..',
		'.##############.',
		'################',
		'#.##.##.##.##.##',
		'.......#........',
		'.#.....#.....#..',
		'.......#........',
		'...#...#.....#..',
		'.......#........',
		'.......#..#.....',
		'....#..#........',
		'......#.........',
	],
};

// The borders, as tiles of 8 × 8 that go around the edge.
const borderTiles = {
	hearts: [
		'........',
		'.##.##..',
		'#######.',
		'#######.',
		'.#####..',
		'..###...',
		'...#....',
		'........',
	],
	stars: [
		'...#....',
		'...#....',
		'#######.',
		'.#####..',
		'..###...',
		'.##.##..',
		'.#...#..',
		'........',
	],
	flags: [
		'........',
		'::.#.:::',
		'::.#.:::',
		'.......:',
		'#######.',
		'.......:',
		'::.#.:::',
		'::.#.:::',
	],
	zigzag: [
		'#......#',
		'##....##',
		'.##..##.',
		'..####..',
		'...##...',
		'........',
		'........',
		'........',
	],
	checkers: [
		'####....',
		'####....',
		'####....',
		'####....',
		'....####',
		'....####',
		'....####',
		'....####',
	],
};

const fonts = ['block', 'outline', 'party', 'stencil', 'bubble'];
const modeNames = {card: 'Greeting Card', sign: 'Sign', letterhead: 'Letterhead', banner: 'Banner'};

// The steps of the program for each kind of printout, like in The Print Shop.
const flows = {
	card: ['border', 'graphic', 'font', 'text', 'preview'],
	sign: ['border', 'graphic', 'layout', 'font', 'text', 'preview'],
	letterhead: ['graphic', 'font', 'text', 'preview'],
	banner: ['font', 'graphic', 'text', 'preview'],
};

const stepTitles = {menu: 'Main Menu', border: 'Border Menu', graphic: 'Graphics Menu', layout: 'Layout', font: 'Font Menu', text: 'Message', preview: 'Preview', printing: 'Printing'};

// What the visitor types for each kind of printout, with the limits that fit on the paper.
const textFields = {
	banner: {prompt: 'Type the banner message', first: 'Message:', firstLength: 40, defaults: ['HURRA!', '']},
	sign: {prompt: 'Type the words of the sign', first: 'Headline:', firstLength: 24, second: 'Small line:', secondLength: 40, defaults: ['HOLD DEG UTE!', 'GJELDER DEG, LILLESØSTER']},
	card: {prompt: 'Type the front and the inside', first: 'Front:', firstLength: 24, second: 'Inside:', secondLength: 48, defaults: ['TIL MORMOR', 'DU ER VERDENS BESTE MORMOR ♥']},
	letterhead: {prompt: 'Type your name and address', first: 'Name:', firstLength: 20, second: 'Address:', secondLength: 32, defaults: ['SINDRE', '5000 BERGEN, NORGE']},
};

// Only the letters that the font has, in capitals, like the program.
const cleanText = text => [...String(text).toUpperCase().replaceAll('’', '\'').replaceAll('‘', '\'')]
	.filter(character => Object.hasOwn(glyphs, character))
	.join('')
	.replaceAll(/ {2,}/g, ' ')
	.trim();

// A stored choice, if it is still one of the choices.
const choose = (value, choices, fallback) => choices.includes(value) ? value : fallback;

// MARK: Bitmaps

// A picture of dots, one byte for each dot, like the memory of the printer.
const makeBitmap = (width, height) => ({width, height, dots: new Uint8Array(Math.max(0, width * height))});

const isSet = (bitmap, x, y) => x >= 0 && y >= 0 && x < bitmap.width && y < bitmap.height && bitmap.dots[(y * bitmap.width) + x] === 1;

const plot = (bitmap, x, y) => {
	if (x >= 0 && y >= 0 && x < bitmap.width && y < bitmap.height) {
		bitmap.dots[(y * bitmap.width) + x] = 1;
	}
};

const fillBlock = (bitmap, left, top, width, height) => {
	for (let y = top; y < top + height; y++) {
		for (let x = left; x < left + width; x++) {
			plot(bitmap, x, y);
		}
	}
};

const blit = (target, source, left, top) => {
	for (let y = 0; y < source.height; y++) {
		for (let x = 0; x < source.width; x++) {
			if (source.dots[(y * source.width) + x] === 1) {
				plot(target, left + x, top + y);
			}
		}
	}
};

// Turns a banner, which is made lying down, to the paper, where it runs down the pages with the tops of the letters to the right.
const turnToPaper = landscape => {
	const paper = makeBitmap(landscape.height, landscape.width);
	for (let row = 0; row < paper.height; row++) {
		for (let column = 0; column < paper.width; column++) {
			if (landscape.dots[((landscape.height - 1 - column) * landscape.width) + row] === 1) {
				paper.dots[(row * paper.width) + column] = 1;
			}
		}
	}

	return paper;
};

const turnUpsideDown = bitmap => {
	const turned = makeBitmap(bitmap.width, bitmap.height);
	const count = bitmap.dots.length;
	for (let index = 0; index < count; index++) {
		turned.dots[count - 1 - index] = bitmap.dots[index];
	}

	return turned;
};

// Draws the words in one of the fonts. The fonts are the same letters drawn in different ways, like the fonts of The Print Shop.
const renderText = (text, scale, font) => {
	const characters = [...text];
	const pixelWidth = Math.max(1, (characters.length * 6) - 1);
	const shadow = font === 'party' ? Math.max(1, Math.round(scale / 3)) : 0;
	const bitmap = makeBitmap((pixelWidth * scale) + shadow, (7 * scale) + shadow);
	const pixels = makeBitmap(pixelWidth, 7);

	for (const [index, character] of characters.entries()) {
		for (const [row, bits] of (glyphs[character] ?? glyphs['?']).entries()) {
			for (let column = 0; column < 5; column++) {
				if (bits & (16 >> column)) {
					plot(pixels, (index * 6) + column, row);
				}
			}
		}
	}

	const style = scale < 3 && font !== 'party' && font !== 'bubble' ? 'block' : font;
	const thickness = Math.max(1, Math.round(scale / 4));
	const gap = Math.max(1, Math.round(scale / 5));
	const radius = scale / 2;

	for (let row = 0; row < 7; row++) {
		for (let column = 0; column < pixelWidth; column++) {
			if (!isSet(pixels, column, row)) {
				continue;
			}

			const left = column * scale;
			const top = row * scale;

			if (style === 'outline') {
				// Only the edges of the letters, with the inside left as paper.
				const isOff = (deltaX, deltaY) => !isSet(pixels, column + deltaX, row + deltaY);
				if (isOff(-1, 0)) {
					fillBlock(bitmap, left, top, thickness, scale);
				}

				if (isOff(1, 0)) {
					fillBlock(bitmap, left + scale - thickness, top, thickness, scale);
				}

				if (isOff(0, -1)) {
					fillBlock(bitmap, left, top, scale, thickness);
				}

				if (isOff(0, 1)) {
					fillBlock(bitmap, left, top + scale - thickness, scale, thickness);
				}

				for (const [deltaX, deltaY] of [[-1, -1], [1, -1], [-1, 1], [1, 1]]) {
					if (isOff(deltaX, deltaY)) {
						fillBlock(bitmap, deltaX < 0 ? left : left + scale - thickness, deltaY < 0 ? top : top + scale - thickness, thickness, thickness);
					}
				}
			} else if (style === 'stencil') {
				// Every square of the letter on its own, with paper between them.
				fillBlock(bitmap, left, top, scale - gap, scale - gap);
			} else if (style === 'bubble') {
				for (let y = 0; y < scale; y++) {
					for (let x = 0; x < scale; x++) {
						if (((x + 0.5 - radius) ** 2) + ((y + 0.5 - radius) ** 2) <= radius * radius) {
							plot(bitmap, left + x, top + y);
						}
					}
				}
			} else {
				fillBlock(bitmap, left, top, scale, scale);
			}
		}
	}

	if (shadow > 0) {
		// The party font has a shadow in half ink down and to the right, like it is 3D.
		const letters = makeBitmap(bitmap.width, bitmap.height);
		letters.dots.set(bitmap.dots);
		for (let y = 0; y < bitmap.height; y++) {
			for (let x = 0; x < bitmap.width; x++) {
				if (!isSet(letters, x, y) && isSet(letters, x - shadow, y - shadow) && (x + y) % 2 === 0) {
					plot(bitmap, x, y);
				}
			}
		}
	}

	return bitmap;
};

const renderGraphic = (id, scale) => {
	const art = graphics[id];
	const bitmap = makeBitmap(16 * scale, 16 * scale);
	if (!art) {
		return bitmap;
	}

	for (const [row, line] of art.entries()) {
		for (const [column, character] of [...line].entries()) {
			if (character === '#') {
				fillBlock(bitmap, column * scale, row * scale, scale, scale);
			} else if (character === ':') {
				for (let y = row * scale; y < (row + 1) * scale; y++) {
					for (let x = column * scale; x < (column + 1) * scale; x++) {
						if (scale === 1 ? (row + column) % 2 === 0 : (x + y) % 2 === 0) {
							plot(bitmap, x, y);
						}
					}
				}
			}
		}
	}

	return bitmap;
};

const drawBorder = (bitmap, id, top = 0, height = bitmap.height) => {
	const margin = 2;
	if (id === 'none') {
		return;
	}

	if (id === 'lines') {
		for (const [inset, thickness] of [[margin, 2], [margin + 5, 1]]) {
			fillBlock(bitmap, inset, top + inset, bitmap.width - (inset * 2), thickness);
			fillBlock(bitmap, inset, top + height - inset - thickness, bitmap.width - (inset * 2), thickness);
			fillBlock(bitmap, inset, top + inset, thickness, height - (inset * 2));
			fillBlock(bitmap, bitmap.width - inset - thickness, top + inset, thickness, height - (inset * 2));
		}

		return;
	}

	const tile = makeBitmap(8, 8);
	for (const [row, line] of borderTiles[id].entries()) {
		for (const [column, character] of [...line].entries()) {
			if (character === '#' || (character === ':' && (row + column) % 2 === 0)) {
				plot(tile, column, row);
			}
		}
	}

	const across = Math.floor((bitmap.width - (margin * 2)) / 8);
	const down = Math.floor((height - (margin * 2)) / 8);
	const left = Math.floor((bitmap.width - (across * 8)) / 2);
	const first = top + Math.floor((height - (down * 8)) / 2);
	for (let index = 0; index < across; index++) {
		blit(bitmap, tile, left + (index * 8), first);
		blit(bitmap, tile, left + (index * 8), first + ((down - 1) * 8));
	}

	for (let index = 1; index < down - 1; index++) {
		blit(bitmap, tile, left, first + (index * 8));
		blit(bitmap, tile, left + ((across - 1) * 8), first + (index * 8));
	}
};

// Breaks the words into lines that fit the width at the scale.
const wrapWords = (text, maximumCharacters) => {
	const lines = [];
	for (const word of text.split(' ')) {
		const last = lines.at(-1);
		if (last !== undefined && (last.length + 1 + word.length) <= maximumCharacters) {
			lines[lines.length - 1] = `${last} ${word}`;
		} else {
			lines.push(word);
		}
	}

	return lines;
};

// Puts the words in a box, as big as they fit, centered, on more lines if needed.
const drawTextBox = (bitmap, text, font, {left, top, width, height, maximumScale}) => {
	if (!text) {
		return;
	}

	for (let scale = maximumScale; scale >= 1; scale--) {
		const lineHeight = (7 * scale) + Math.max(2, Math.round(scale * 1.5));
		const maximumCharacters = Math.floor((width + scale) / (6 * scale));
		const lines = wrapWords(text, maximumCharacters);
		const totalHeight = (lines.length * lineHeight) - (lineHeight - (7 * scale));
		const fits = lines.every(line => line.length <= maximumCharacters) && totalHeight <= height;
		if (!fits && scale > 1) {
			continue;
		}

		let y = top + Math.max(0, Math.floor((height - totalHeight) / 2));
		for (const line of lines) {
			const rendered = renderText(line.slice(0, Math.max(1, maximumCharacters)), scale, font);
			blit(bitmap, rendered, left + Math.floor((width - rendered.width) / 2), y);
			y += lineHeight;
		}

		return;
	}
};

const pageWidth = 160;
const pageRows = 208;
const passRows = 8;

const renderSign = spec => {
	const page = makeBitmap(pageWidth, pageRows);
	const [headline, smallLine] = spec.texts;
	drawBorder(page, spec.border);
	const hasGraphic = spec.graphic !== 'none';
	const layout = hasGraphic ? spec.layout : 'none';

	if (layout === 'large') {
		drawTextBox(page, headline, spec.font, {left: 14, top: 14, width: 132, height: 50, maximumScale: 5});
		blit(page, renderGraphic(spec.graphic, 6), 32, 68);
		drawTextBox(page, smallLine, 'block', {left: 14, top: 168, width: 132, height: 26, maximumScale: 2});
	} else if (layout === 'tiled') {
		drawTextBox(page, headline, spec.font, {left: 14, top: 14, width: 132, height: 50, maximumScale: 5});
		const small = renderGraphic(spec.graphic, 2);
		for (const row of [0, 1]) {
			for (const column of [0, 1, 2]) {
				blit(page, small, 20 + (column * 44), 70 + (row * 48));
			}
		}

		drawTextBox(page, smallLine, 'block', {left: 14, top: 168, width: 132, height: 26, maximumScale: 2});
	} else if (layout === 'corners') {
		const small = renderGraphic(spec.graphic, 2);
		for (const [x, y] of [[14, 14], [114, 14], [14, 162], [114, 162]]) {
			blit(page, small, x, y);
		}

		drawTextBox(page, headline, spec.font, {left: 14, top: 50, width: 132, height: 86, maximumScale: 6});
		drawTextBox(page, smallLine, 'block', {left: 14, top: 138, width: 132, height: 22, maximumScale: 2});
	} else {
		drawTextBox(page, headline, spec.font, {left: 14, top: 16, width: 132, height: 110, maximumScale: 6});
		drawTextBox(page, smallLine, 'block', {left: 14, top: 132, width: 132, height: 60, maximumScale: 3});
	}

	return page;
};

// A card is one page, folded in half: the front on the top half, and the inside on the bottom half, upside down, so it reads the right way when the card stands.
const renderCard = spec => {
	const page = makeBitmap(pageWidth, pageRows);
	const half = pageRows / 2;
	const [front, inside] = spec.texts;
	const frontHalf = makeBitmap(pageWidth, half);
	drawBorder(frontHalf, spec.border);
	if (spec.graphic === 'none') {
		drawTextBox(frontHalf, front, spec.font, {left: 14, top: 14, width: 132, height: 76, maximumScale: 5});
	} else {
		blit(frontHalf, renderGraphic(spec.graphic, 3), 56, 13);
		drawTextBox(frontHalf, front, spec.font, {left: 14, top: 64, width: 132, height: 28, maximumScale: 3});
	}

	const insideHalf = makeBitmap(pageWidth, half);
	drawTextBox(insideHalf, inside, spec.font, {left: 12, top: 10, width: 136, height: 70, maximumScale: 3});
	if (spec.graphic !== 'none') {
		blit(insideHalf, renderGraphic(spec.graphic, 1), 72, 82);
	}

	blit(page, frontHalf, 0, 0);
	blit(page, turnUpsideDown(insideHalf), 0, half);
	return page;
};

const renderLetterhead = spec => {
	const page = makeBitmap(pageWidth, pageRows);
	const [name, address] = spec.texts;
	if (spec.graphic !== 'none') {
		const small = renderGraphic(spec.graphic, 2);
		blit(page, small, 4, 4);
		blit(page, small, 124, 4);
		const tiny = renderGraphic(spec.graphic, 1);
		for (let x = 8; x <= 136; x += 32) {
			blit(page, tiny, x, 190);
		}
	}

	drawTextBox(page, name, spec.font, {left: 38, top: 4, width: 84, height: 32, maximumScale: 4});
	drawTextBox(page, address, 'block', {left: 4, top: 39, width: 152, height: 7, maximumScale: 1});
	fillBlock(page, 4, 48, 152, 2);
	fillBlock(page, 4, 51, 152, 1);
	fillBlock(page, 4, 186, 152, 1);
	return page;
};

// A banner is made lying down, as long as it needs to be, and turned to run down the paper.
const renderBannerLandscape = spec => {
	const [message] = spec.texts;
	const parts = [];
	const graphic = spec.graphic === 'none' ? undefined : renderGraphic(spec.graphic, 8);
	const text = message ? renderText(message, 20, spec.font) : undefined;
	if (graphic) {
		parts.push({bitmap: graphic, top: 16});
	}

	if (text) {
		parts.push({bitmap: text, top: 10});
	}

	if (graphic && text) {
		parts.push({bitmap: graphic, top: 16});
	}

	let length = 16;
	for (const part of parts) {
		length += part.bitmap.width + 24;
	}

	length = Math.max(64, Math.ceil((length - 8) / passRows) * passRows);
	const landscape = makeBitmap(length, pageWidth);
	let x = 16;
	for (const part of parts) {
		blit(landscape, part.bitmap, x, part.top);
		x += part.bitmap.width + 24;
	}

	return landscape;
};

const renderDesign = spec => {
	if (spec.mode === 'banner') {
		return turnToPaper(renderBannerLandscape(spec));
	}

	if (spec.mode === 'card') {
		return renderCard(spec);
	}

	if (spec.mode === 'letterhead') {
		return renderLetterhead(spec);
	}

	return renderSign(spec);
};

// A canvas of the dots, in ink on paper or in the colors of the screen.
const bitmapToCanvas = (bitmap, {ink = [24, 24, 40, 255], paper = [255, 255, 255, 255]} = {}) => {
	const canvas = document.createElement('canvas');
	canvas.width = Math.max(1, bitmap.width);
	canvas.height = Math.max(1, bitmap.height);
	const context = canvas.getContext('2d');
	const image = context.createImageData(canvas.width, canvas.height);
	for (let index = 0; index < bitmap.dots.length; index++) {
		const color = bitmap.dots[index] === 1 ? ink : paper;
		image.data.set(color, index * 4);
	}

	context.putImageData(image, 0, 0);
	return canvas;
};

// MARK: The printer

const dot = 2;
const strip = 18;
const paperLeft = 52;
const paperWidth = (pageWidth * dot) + (strip * 2);
const headY = 290;
const barY = 274;
const paperTop = 40;
const deskY = 440;
const floorY = 548;
const boxSize = 40;
const visibleRows = Math.floor((headY - paperTop) / dot);

// The printout is drawn in dots: a page stands up, and a banner lies down, so it reads from left to right.
const margin = 14;
const stripDots = strip / dot;
const paperDots = pageWidth + (stripDots * 2);

const pagesOf = rows => Math.ceil(rows / pageRows);

// The color of the dots, lighter as the ribbon wears out.
const inkColor = (ink, wobble = 0) => `rgba(22, 22, 44, ${clamp(0.12 + (ink * 0.85) + wobble, 0.08, 1)})`;

// An almost dry ribbon prints in patches, so some dots are missing, always the same ones.
const isDotMissing = (ink, seed) => ink < 0.3 && hash(seed) > ink * 3.3;

// The dots of a row, with each dot `size` pixels, from the left edge of the paper with the strip.
const drawDots = (target, paperRow, row, y, {from = 0, to = pageWidth, size = dot} = {}) => {
	target.fillStyle = inkColor(paperRow.ink, Math.sin(row * 0.7) * 0.04);
	for (let column = from; column < to; column++) {
		if (paperRow.dots[column] === 1 && !isDotMissing(paperRow.ink, (row * 160) + column)) {
			target.fillRect(((strip / dot) + column) * size, y, size, size);
		}
	}
};

const countDots = dots => {
	let count = 0;
	for (const value of dots) {
		count += value;
	}

	return count;
};

const drawCardHalf = (canvas, bitmap, ink) => {
	const target = canvas.getContext('2d');
	target.fillStyle = '#fbfaf3';
	target.fillRect(0, 0, canvas.width, canvas.height);
	target.fillStyle = inkColor(ink);
	for (let y = 0; y < bitmap.height; y++) {
		for (let x = 0; x < bitmap.width; x++) {
			if (bitmap.dots[(y * bitmap.width) + x] === 1 && !isDotMissing(ink, (y * 160) + x)) {
				target.fillRect(x * 2, y * 2, 2, 2);
			}
		}
	}
};

// MARK: Sound

const envelope = (gain, start, duration, volume, attack = 0.005) => {
	gain.gain.setValueAtTime(0, start);
	gain.gain.linearRampToValueAtTime(volume, start + attack);
	gain.gain.setValueAtTime(volume, Math.max(start + attack, start + duration - 0.02));
	gain.gain.linearRampToValueAtTime(0, start + duration);
};

// A second of white noise, for the hiss of the needles, the paper, and the motor.
const makeNoise = context => {
	const noise = new AudioBuffer({length: context.sampleRate, sampleRate: context.sampleRate});
	const data = noise.getChannelData(0);
	for (let index = 0; index < data.length; index++) {
		data[index] = (Math.random() * 2) - 1;
	}

	return noise;
};

export default class extends GeoCitiesElement {
	#design;
	#steps;
	#currentStep = 'menu';
	#copies = 1;
	#context;
	#printer;
	#loop;
	#printout;
	#tearPointer;
	#peelPointer;
	#cardTimer;
	#hung;
	#resizeFrame;
	#isSoundOn = false;
	#noise;

	connected() {
		const {screen, form, firstLine, secondLine, textPrompt, back, mainMenu, fewerCopies, moreCopies, print, printerCanvas, online, formFeed, lineFeed, lid, unjam, ribbon, paper, sound, tear, printoutCanvas, peel, throwAway, fold, turn, hang, takeDown} = this.parts;

		const savedDesign = this.stored('design', {});
		this.#design = {
			mode: choose(savedDesign.mode, Object.keys(modeNames), 'banner'),
			font: choose(savedDesign.font, fonts, 'block'),
			graphic: choose(savedDesign.graphic, [...Object.keys(graphics), 'none'], 'unicorn'),
			border: choose(savedDesign.border, [...Object.keys(borderTiles), 'lines', 'none'], 'hearts'),
			layout: choose(savedDesign.layout, ['large', 'tiled', 'corners'], 'large'),
			texts: {},
		};

		for (const [mode, field] of Object.entries(textFields)) {
			const saved = savedDesign.texts?.[mode];
			this.#design.texts[mode] = Array.isArray(saved) ? [cleanText(saved[0] ?? '').slice(0, field.firstLength), cleanText(saved[1] ?? '').slice(0, field.secondLength ?? 0)] : [...field.defaults];
		}

		this.#steps = new Map([...screen.querySelectorAll('[data-print-shop-step]')].map(element => [element.dataset.printShopStep, element]));
		this.#context = printerCanvas.getContext('2d');

		const savedPrinter = this.stored('printer', {});
		this.#printer = {
			ink: clamp(Number(savedPrinter.ink) || 1, 0.04, 1),
			paperLeft: Number.isFinite(savedPrinter.paperLeft) ? clamp(Math.round(savedPrinter.paperLeft), 0, boxSize) : 20,
			isOnline: true,
			isLidOpen: false,
			isJammed: false,
			isOutOfPaper: false,
			// The rows of paper since the last tear, each with its dots and the ink of the ribbon when it was printed.
			feed: [],
			// The row of the page where the paper since the last tear starts, so the perforations stay in their places.
			feedOffset: 0,
			isRaggedTop: false,
			// The designs printed since the last tear, so a printout of different kinds is not folded or hung as the last one.
			feedSpecs: [],
			scroll: 0,
			job: undefined,
			pass: undefined,
			budget: 0,
			direction: 1,
			headX: -12,
			crumple: 0,
			tear: 0,
			tearFly: 0,
			chunks: new Map(),
			jobsPrinted: 0,
			pageTimer: 0,
		};

		// The printer runs only while it is on the screen, not while only the computer is.
		this.#loop = this.loop(seconds => {
			this.#step(seconds);
		}, {while: () => this.#needsFrames(), target: printerCanvas});

		// MARK: The screen

		this.on(screen, 'click', event => {
			const button = event.target.closest('button');
			if (!button) {
				return;
			}

			const choices = [
				['printShopMode', 'mode'],
				['printShopBorder', 'border'],
				['printShopGraphic', 'graphic'],
				['printShopLayout', 'layout'],
				['printShopFont', 'font'],
			];

			for (const [key, property] of choices) {
				if (button.dataset[key] !== undefined) {
					this.#design[property] = button.dataset[key];
					this.#saveDesign();
					this.#markSelections();
					this.#sounds.click();
					if (property === 'mode') {
						this.#showStep(flows[this.#design.mode][0]);
					} else {
						this.#nextStep();
					}

					return;
				}
			}
		});

		this.on(form, 'submit', event => {
			event.preventDefault();
			const field = textFields[this.#design.mode];
			const first = cleanText(firstLine.value).slice(0, field.firstLength);
			const second = field.second ? cleanText(secondLine.value).slice(0, field.secondLength) : '';
			if (!first && !second) {
				this.say('Type something first! Even The Print Shop cannot print nothing.');
				// The status can be out of view under the printer, on a phone, so the screen says it too, until the step shows again.
				textPrompt.textContent = 'Type something first!';
				firstLine.focus();
				return;
			}

			this.#design.texts[this.#design.mode] = [first, second];
			this.#saveDesign();
			this.#sounds.click();
			this.#nextStep();
		});

		this.on(back, 'click', () => {
			this.#previousStep();
		});

		this.on(mainMenu, 'click', () => {
			this.#showStep('menu');
		});

		this.on(fewerCopies, 'click', () => {
			this.#copies = Math.max(1, this.#copies - 1);
			this.#updateCopies();
			this.say(this.#copies === 1 ? 'One copy. The teacher nods.' : `${this.#copies} copies.`);
		});

		this.on(moreCopies, 'click', () => {
			this.#copies = Math.min(3, this.#copies + 1);
			this.#updateCopies();
			if (this.#copies === 3) {
				this.say('Læreren (the teacher) looks at you over her glasses. “Three copies? The paper costs money!”');
			} else {
				this.say('“Only one copy each!” says the teacher. Nobody listens.');
			}
		});

		// The arrow keys move between the choices, like in the real program, and Escape goes back.
		this.on(screen, 'keydown', event => {
			if (event.key === 'Escape' && this.#currentStep !== 'menu') {
				event.preventDefault();
				this.#previousStep();
				return;
			}

			const isField = event.target instanceof HTMLInputElement;
			const forward = event.key === 'ArrowDown' || (!isField && event.key === 'ArrowRight');
			const backward = event.key === 'ArrowUp' || (!isField && event.key === 'ArrowLeft');
			if (!forward && !backward) {
				return;
			}

			const buttons = this.#optionButtons(this.#currentStep);
			const index = buttons.indexOf(event.target);
			if (buttons.length === 0) {
				return;
			}

			event.preventDefault();
			const next = index === -1 ? 0 : (index + (forward ? 1 : -1) + buttons.length) % buttons.length;
			buttons[next].focus();
		});

		// MARK: The panel of the printer

		this.on(online, 'click', () => {
			const printer = this.#printer;
			if (printer.isJammed) {
				this.say('The light blinks. Pull out the crumpled paper first. (Open the lid.)');
				this.#sounds.beep(1);
				return;
			}

			if (printer.isLidOpen && !printer.isOnline) {
				this.say('It will not go on line with the lid open. Close the lid.');
				this.#sounds.beep(1);
				return;
			}

			if (printer.isOutOfPaper) {
				this.say('Paper Out. Put in a new box of paper first.');
				this.#sounds.beep(1);
				return;
			}

			printer.isOnline = !printer.isOnline;
			this.#sounds.click();
			this.#updatePanel();
			if (printer.isOnline) {
				this.say(printer.job ? 'On line. It goes on printing.' : 'On line. The printer waits for the computer.');
				this.#loop.start();
			} else {
				this.say(printer.job ? 'Off line. The printer stops in the middle of the line. Now Form Feed and Line Feed work.' : 'Off line. Now Form Feed and Line Feed work.');
			}
		});

		this.on(formFeed, 'click', () => {
			this.#feed(pageRows - this.#pageRowOf(this.#printer.feed.length), 'Form Feed');
		});

		this.on(lineFeed, 'click', () => {
			this.#feed(passRows, 'Line Feed');
		});

		this.on(lid, 'click', () => {
			const printer = this.#printer;
			printer.isLidOpen = !printer.isLidOpen;
			this.#sounds.click();
			this.#updatePanel();
			this.#drawPrinter();
			if (printer.isLidOpen) {
				this.say(printer.isJammed ? 'The lid is open. There is the crumpled paper. Pull it out!' : 'The lid is open. You can see the head and the ribbon. It stops while the lid is open.');
			} else {
				this.say(printer.job ? (printer.isOnline ? 'The lid is closed. It goes on printing.' : 'The lid is closed. Press On Line to go on.') : 'The lid is closed.');
				this.#loop.start();
			}
		});

		this.on(unjam, 'click', () => {
			const printer = this.#printer;
			// The crumpled page is lost, and the printer prints it again from its top.
			const rowsOnPage = Math.min(this.#pageRowOf(printer.feed.length), printer.feed.length);
			printer.feed.length -= rowsOnPage;
			printer.chunks.clear();
			printer.scroll = printer.feed.length;
			printer.isJammed = false;
			printer.crumple = 0;
			if (printer.job) {
				const index = printer.feed.length - printer.job.feedStart;
				if (index < 0) {
					printer.job.feedStart = printer.feed.length;
					printer.job.index = 0;
				} else {
					printer.job.index = index;
				}
			}

			this.#sounds.rip(0.4, 0.08);
			this.#updatePanel();
			this.#drawPrinter();
			unjam.hidden = true;
			lid.focus();
			this.say('You pull out a crumpled ball of paper and throw it in the bin. Close the lid and press On Line, and it prints the page again.');
		});

		this.on(ribbon, 'click', () => {
			this.#printer.ink = 1;
			this.#savePrinter();
			this.#updatePanel();
			this.#sounds.click();
			this.say('A fresh ribbon! Your fingers are black now, but the print is dark again.');
		});

		this.on(paper, 'click', () => {
			const printer = this.#printer;
			printer.paperLeft = boxSize;
			const wasOut = printer.isOutOfPaper;
			printer.isOutOfPaper = false;
			this.#savePrinter();
			this.#updatePanel();
			this.#drawPrinter();
			this.#sounds.whir(0.4);
			this.say(wasOut ? 'A new box of 40 sheets from the storage room. Press On Line to go on.' : `A new box of ${boxSize} sheets. The teacher counts them.`);
		});

		this.on(sound, 'click', () => {
			// Browsers only let audio play after a click, so the audio is made here.
			const audio = this.#isSoundOn ? undefined : this.sound();
			this.#isSoundOn = Boolean(audio);
			audio?.context.resume();
			setPressed(sound, this.#isSoundOn);
			sound.textContent = this.#isSoundOn ? '🔊 Sound' : '🔈 Sound';
			if (this.#isSoundOn) {
				this.#sounds.lineFeed();
			}
		});

		// MARK: Tearing it off

		this.on(printerCanvas, 'pointerdown', event => {
			const point = canvasPoint(printerCanvas, event);
			if (this.#printer.tearFly > 0 || Math.abs(point.y - barY) > 40 || point.x < paperLeft - 20 || point.x > paperLeft + paperWidth + 20) {
				return;
			}

			if (this.#printer.job || !this.#hasPrint() || this.#printer.isJammed) {
				this.#tearOff();
				return;
			}

			this.#tearPointer = {id: event.pointerId, start: point.x, furthest: point.x};
			printerCanvas.setPointerCapture(event.pointerId);
		});

		this.on(printerCanvas, 'pointermove', event => {
			const tearPointer = this.#tearPointer;
			if (tearPointer?.id !== event.pointerId) {
				return;
			}

			const point = canvasPoint(printerCanvas, event);
			const distance = Math.abs(point.x - tearPointer.start);
			if (distance > (tearPointer.furthest ?? 0) + 12) {
				tearPointer.furthest = distance;
				this.#sounds.rip(0.05, 0.05);
			}

			this.#printer.tear = clamp(distance / (paperWidth * 0.8), 0, 1);
			this.#drawPrinter();
			if (this.#printer.tear >= 1) {
				this.#tearPointer = undefined;
				this.#tearOff();
			}
		});

		const endTear = event => {
			if (this.#tearPointer?.id !== event.pointerId) {
				return;
			}

			this.#tearPointer = undefined;
			if (this.#printer.tear > 0 && this.#printer.tear < 1) {
				this.#printer.tear = 0;
				this.#drawPrinter();
				this.say('Pull it all the way across the printer to tear it off.');
			}
		};

		this.on(printerCanvas, 'pointerup', endTear);
		this.on(printerCanvas, 'pointercancel', endTear);

		this.on(printerCanvas, 'keydown', event => {
			if (event.key === 't' || event.key === 'T') {
				event.preventDefault();
				this.#tearOff();
			}
		});

		this.on(tear, 'click', () => {
			this.#tearOff();
		});

		// MARK: The printout

		this.on(printoutCanvas, 'pointerdown', event => {
			const printout = this.#printout;
			if (!printout) {
				return;
			}

			const across = this.#printoutAcross(event);
			let side;
			if (across < stripDots + 4 && across > -10) {
				side = 0;
			} else if (across > paperDots - stripDots - 4 && across < paperDots + 10) {
				side = 1;
			}

			if (side !== undefined && printout.peeled[side] >= 1) {
				side = undefined;
			}

			// The rest of a banner drags it sideways in its box, as the canvas lets a finger only scroll the page up and down.
			if (side === undefined && !printout.isBanner) {
				return;
			}

			this.#peelPointer = {id: event.pointerId, side, last: event.clientX, lastY: event.clientY};
			printoutCanvas.setPointerCapture(event.pointerId);
		});

		this.on(printoutCanvas, 'pointermove', event => {
			const peelPointer = this.#peelPointer;
			if (peelPointer?.id !== event.pointerId) {
				return;
			}

			if (peelPointer.side === undefined) {
				printoutCanvas.parentElement.scrollLeft -= event.clientX - peelPointer.last;
				peelPointer.last = event.clientX;
				return;
			}

			const distance = Math.hypot(event.clientX - peelPointer.last, event.clientY - peelPointer.lastY);
			if (distance < 6) {
				return;
			}

			peelPointer.last = event.clientX;
			peelPointer.lastY = event.clientY;
			this.#peel(peelPointer.side, distance / 320);
		});

		const endPeel = event => {
			if (this.#peelPointer?.id === event.pointerId) {
				this.#peelPointer = undefined;
			}
		};

		this.on(printoutCanvas, 'pointerup', endPeel);
		this.on(printoutCanvas, 'pointercancel', endPeel);

		this.on(printoutCanvas, 'keydown', event => {
			if (event.key === 'p' || event.key === 'P') {
				event.preventDefault();
				this.#peelNext();
			}
		});

		this.on(peel, 'click', () => {
			this.#peelNext();
		});

		this.on(throwAway, 'click', () => {
			const {printoutBox, card} = this.parts;
			this.#printout = undefined;
			printoutBox.hidden = true;
			card.hidden = true;
			this.#sounds.rip(0.2, 0.05);
			this.say(randomItem(['Into the bin. The bin of the computer room is full of banners.', 'Crumpled up and thrown at Trond. Two points!']));
			printerCanvas.focus({preventScroll: true});
		});

		// MARK: The card

		this.on(fold, 'click', async () => {
			const printout = this.#printout;
			if (!printout) {
				return;
			}

			const {card, cardFront, cardInside, printoutNote, printoutBox} = this.parts;
			if (printout.peeled.some(progress => progress < 1)) {
				this.say('Peel off the strips first, or the card has holes down both sides.');
				// The status is up under the printer, out of view on a phone, so the note over the printout says it too, and the printout comes into view with the strips.
				printoutNote.textContent = 'Peel off the strips with the holes first, or the card has holes down both sides.';
				printoutBox.scrollIntoView({behavior: this.reducedMotion ? 'auto' : 'smooth', block: 'nearest'});
				return;
			}

			const page = renderCard(printout.spec);
			const half = pageRows / 2;
			const front = makeBitmap(pageWidth, half);
			front.dots.set(page.dots.subarray(0, pageWidth * half));
			const inside = makeBitmap(pageWidth, half);
			inside.dots.set(page.dots.subarray(pageWidth * half));
			const ink = this.#averageInk();
			drawCardHalf(cardFront, front, ink);
			drawCardHalf(cardInside, inside, ink);
			clearTimeout(this.#cardTimer);
			card.hidden = false;
			this.#sounds.rip(0.15, 0.03);
			if (this.reducedMotion) {
				this.#setCardState('standing');
			} else {
				// The card starts flat, so the fold animates from there.
				this.#setCardState('');
				await nextFrame();
				await nextFrame();
				this.#setCardState('folding');
				clearTimeout(this.#cardTimer);
				this.#cardTimer = setTimeout(() => {
					this.#setCardState('standing');
				}, 750);
			}

			card.scrollIntoView({behavior: this.reducedMotion ? 'auto' : 'smooth', block: 'nearest'});
			this.say('Fold, crease with your thumbnail, and it stands on the desk! The inside was upside down on the page, so it reads the right way on the back.');
			this.celebrate();
		});

		this.on(turn, 'click', () => {
			const {card} = this.parts;
			clearTimeout(this.#cardTimer);
			if (card.dataset.state === 'back') {
				this.#setCardState('standing');
				return;
			}

			if (this.reducedMotion) {
				this.#setCardState('back');
				return;
			}

			this.#setCardState('turning');
			this.#cardTimer = setTimeout(() => {
				this.#setCardState('back');
			}, 450);
		});

		// MARK: The banner over the page

		this.on(hang, 'click', () => {
			const printout = this.#printout;
			if (printout?.spec?.mode !== 'banner') {
				return;
			}

			const inked = printout.rows.filter(row => row.dots);
			this.#hung = {
				spec: printout.spec,
				inkStart: inked[0]?.ink ?? 1,
				inkEnd: inked.at(-1)?.ink ?? 1,
				peeled: printout.peeled.map(progress => progress >= 1),
			};
			this.store('hanging', this.#hung);
			this.#hangBanner(this.#hung);
			this.#sounds.rip(0.1, 0.03);
			this.celebrate();
			this.say('Taped up across the top of my home page! It stays there, also when you come back.');
			this.toast('🎉 Your banner hangs over the top of the page. Scroll up and look!');
		});

		this.on(takeDown, 'click', () => {
			const {hanging} = this.parts;
			hanging.hidden = true;
			this.#hung = undefined;
			this.store('hanging', undefined);
			this.toast('The banner is down. Mamma is relieved.');
			this.focus({preventScroll: true});
		});

		this.on(window, 'resize', () => {
			if (!this.#hung) {
				return;
			}

			cancelAnimationFrame(this.#resizeFrame);
			this.#resizeFrame = requestAnimationFrame(() => {
				this.#drawHanging(this.#hung);
			});
		});

		// MARK: Start

		this.on(print, 'click', () => {
			this.#startJob();
		});

		// The banner that was hung on an earlier visit goes up again, after the button to take it down works.
		const savedHanging = this.stored('hanging', undefined);
		if (fonts.includes(savedHanging?.spec?.font)) {
			this.#hung = {
				spec: {
					mode: 'banner',
					font: savedHanging.spec.font,
					graphic: choose(savedHanging.spec.graphic, Object.keys(graphics), 'none'),
					texts: [cleanText(savedHanging.spec.texts?.[0] ?? '').slice(0, 40), ''],
				},
				inkStart: clamp(Number(savedHanging.inkStart) || 1, 0.04, 1),
				inkEnd: clamp(Number(savedHanging.inkEnd) || 1, 0.04, 1),
				peeled: [Boolean(savedHanging.peeled?.[0]), Boolean(savedHanging.peeled?.[1])],
			};
			this.#hangBanner(this.#hung);
		}

		this.#markSelections();
		this.#showStep('menu', {focus: false});
		this.#drawSamples();
		this.#updateCopies();
		this.#updatePanel();
		this.#drawPrinter();
	}

	disconnected() {
		clearTimeout(this.#cardTimer);
		cancelAnimationFrame(this.#resizeFrame);
	}

	reducedMotionChanged() {
		// The pass of the moving head is not printed yet, so it prints again from its start.
		const printer = this.#printer;
		printer.pass = undefined;
		printer.headX = -12;
		printer.scroll = printer.feed.length;
		this.#drawPrinter();
	}

	// MARK: Sound

	// The audio, while the sound is on and the browser lets it play.
	get #audio() {
		const audio = this.#isSoundOn ? this.sound() : undefined;
		return audio?.context.state === 'running' ? audio : undefined;
	}

	#tone(frequency, duration, {type = 'square', volume = 0.05, when = 0, endFrequency} = {}) {
		const audio = this.#audio;
		if (!audio) {
			return;
		}

		const {context, output} = audio;
		const start = context.currentTime + when;
		const oscillator = new OscillatorNode(context, {type, frequency});
		if (endFrequency) {
			oscillator.frequency.linearRampToValueAtTime(endFrequency, start + duration);
		}

		const gain = new GainNode(context, {gain: 0});
		envelope(gain, start, duration, volume);
		oscillator.connect(gain).connect(output);
		oscillator.start(start);
		oscillator.stop(start + duration + 0.05);
	}

	#hiss(duration, {frequency = 3000, q = 1.5, volume = 0.05, when = 0, type = 'bandpass'} = {}) {
		const audio = this.#audio;
		if (!audio) {
			return;
		}

		const {context, output} = audio;
		this.#noise ??= makeNoise(context);
		const start = context.currentTime + when;
		const source = new AudioBufferSourceNode(context, {buffer: this.#noise, loop: true});
		const filter = new BiquadFilterNode(context, {type, frequency, Q: q});
		const gain = new GainNode(context, {gain: 0});
		envelope(gain, start, duration, volume, 0.002);
		source.connect(filter).connect(gain).connect(output);
		source.start(start, Math.random() * 0.5);
		source.stop(start + duration + 0.05);
	}

	// The sound of the printer, made in the browser: the screech of the needles, the line feed, the motor, the beeper, the crunch of a jam, and the paper that tears. It is off until the visitor turns it on.
	#sounds = {
		// The needles hammer the ribbon hundreds of times a second, which makes the famous screech, higher on the way back.
		screech: (duration, density, direction) => {
			const audio = this.#audio;
			if (!audio) {
				return;
			}

			const {context, output} = audio;
			const start = context.currentTime;
			const pitch = (direction > 0 ? 1180 : 1010) * (0.97 + (Math.random() * 0.06));
			const volume = 0.025 + (density * 0.05);
			const gain = new GainNode(context, {gain: 0});
			envelope(gain, start, duration, volume, 0.008);

			const buzz = new OscillatorNode(context, {type: 'square', frequency: pitch});
			buzz.frequency.linearRampToValueAtTime(pitch * (direction > 0 ? 1.04 : 0.96), start + duration);
			const rasp = new OscillatorNode(context, {type: 'sawtooth', frequency: pitch * 0.502});
			// The needles fire in bursts, so the buzz stutters.
			const stutter = new OscillatorNode(context, {type: 'square', frequency: 74});
			const stutterDepth = new GainNode(context, {gain: 0.5});
			const chopper = new GainNode(context, {gain: 0.5});
			stutter.connect(stutterDepth).connect(chopper.gain);
			const filter = new BiquadFilterNode(context, {type: 'bandpass', frequency: 2600, Q: 0.9});
			buzz.connect(chopper);
			rasp.connect(chopper);
			chopper.connect(filter).connect(gain).connect(output);

			for (const node of [buzz, rasp, stutter]) {
				node.start(start);
				node.stop(start + duration + 0.05);
			}

			this.#hiss(duration, {frequency: 4200, q: 1.2, volume: 0.02 + (density * 0.03)});
			// The motor of the carriage under it all.
			this.#tone(160, duration, {type: 'triangle', volume: 0.03});
		},
		lineFeed: () => {
			this.#tone(90, 0.04, {type: 'square', volume: 0.04});
			this.#hiss(0.03, {frequency: 900, q: 1, volume: 0.03});
		},
		whir: duration => {
			this.#tone(120, duration, {type: 'sawtooth', volume: 0.04, endFrequency: 150});
			this.#hiss(duration, {frequency: 700, q: 0.8, volume: 0.025});
		},
		beep: (count = 3) => {
			for (let index = 0; index < count; index++) {
				this.#tone(2300, 0.12, {volume: 0.04, when: index * 0.22});
			}
		},
		crunch: () => {
			for (let index = 0; index < 9; index++) {
				this.#hiss(0.05 + (Math.random() * 0.05), {frequency: 600 + (Math.random() * 1400), q: 0.7, volume: 0.09, when: index * 0.07});
			}

			this.#tone(70, 0.6, {type: 'sawtooth', volume: 0.05, endFrequency: 40});
		},
		rip: (duration = 0.08, volume = 0.06) => {
			this.#hiss(duration, {frequency: 2200 + (Math.random() * 1500), q: 0.6, volume});
		},
		click: () => {
			this.#tone(1400, 0.02, {volume: 0.03});
		},
	};

	// MARK: The screen

	#saveDesign() {
		this.store('design', this.#design);
	}

	#optionButtons(step) {
		return [...(this.#steps.get(step)?.querySelectorAll('button, input') ?? [])].filter(element => !element.closest('[hidden]') && !element.disabled);
	}

	#selectButtons(attribute, value) {
		const {screen} = this.parts;
		for (const button of screen.querySelectorAll(`[${attribute}]`)) {
			const isSelected = button.getAttribute(attribute) === value;
			setPressed(button, isSelected);
			button.dataset.state = isSelected ? 'selected' : '';
		}
	}

	#markSelections() {
		const design = this.#design;
		this.#selectButtons('data-print-shop-mode', design.mode);
		this.#selectButtons('data-print-shop-border', design.border);
		this.#selectButtons('data-print-shop-graphic', design.graphic);
		this.#selectButtons('data-print-shop-layout', design.layout);
		this.#selectButtons('data-print-shop-font', design.font);
	}

	#showStep(step, {focus = true} = {}) {
		const {title, back} = this.parts;
		this.#currentStep = step;
		for (const [name, element] of this.#steps) {
			element.hidden = name !== step;
		}

		const titleParts = ['The Print Shop'];
		if (step !== 'menu') {
			titleParts.push(modeNames[this.#design.mode]);
		}

		titleParts.push(stepTitles[step]);
		title.textContent = titleParts.join(' · ');
		back.hidden = step === 'menu';

		if (step === 'text') {
			this.#setUpTextStep();
		}

		if (step === 'preview') {
			this.#drawPreview();
		}

		if (focus) {
			const buttons = this.#optionButtons(step);
			const selected = buttons.find(button => button.dataset.state === 'selected');
			(selected ?? buttons[0])?.focus({preventScroll: true});
		}
	}

	#nextStep() {
		const flow = flows[this.#design.mode];
		let index = flow.indexOf(this.#currentStep) + 1;
		// The layout only matters with a graphic.
		if (flow[index] === 'layout' && this.#design.graphic === 'none') {
			index++;
		}

		this.#showStep(flow[index] ?? 'preview');
	}

	#previousStep() {
		if (this.#currentStep === 'printing') {
			this.#showStep('preview');
			return;
		}

		const flow = flows[this.#design.mode];
		let index = flow.indexOf(this.#currentStep) - 1;
		if (flow[index] === 'layout' && this.#design.graphic === 'none') {
			index--;
		}

		this.#showStep(index < 0 ? 'menu' : flow[index]);
	}

	#setUpTextStep() {
		const {textPrompt, firstLabel, firstLine, secondRow, secondLabel, secondLine} = this.parts;
		const field = textFields[this.#design.mode];
		textPrompt.textContent = field.prompt;
		firstLabel.textContent = field.first;
		firstLine.maxLength = field.firstLength;
		firstLine.value = this.#design.texts[this.#design.mode][0];
		secondRow.hidden = !field.second;
		if (field.second) {
			secondLabel.textContent = field.second;
			secondLine.maxLength = field.secondLength;
			secondLine.value = this.#design.texts[this.#design.mode][1];
		}
	}

	// The samples in the choices, drawn in the colors of the screen.
	#drawSamples() {
		const {screen} = this.parts;
		const draw = (button, bitmap) => {
			const canvas = button.querySelector('canvas');
			const context = canvas.getContext('2d');
			context.fillStyle = '#000';
			context.fillRect(0, 0, canvas.width, canvas.height);
			const scale = Math.min(1, (canvas.width - 4) / bitmap.width, (canvas.height - 4) / bitmap.height);
			const image = bitmapToCanvas(bitmap, {ink: [255, 255, 255, 255], paper: [0, 0, 0, 255]});
			context.imageSmoothingEnabled = scale < 1;
			const width = bitmap.width * scale;
			const height = bitmap.height * scale;
			context.drawImage(image, Math.round((canvas.width - width) / 2), Math.round((canvas.height - height) / 2), width, height);
		};

		for (const button of screen.querySelectorAll('[data-print-shop-font]')) {
			draw(button, renderText('ABC', 4, button.dataset.printShopFont));
		}

		for (const button of screen.querySelectorAll('[data-print-shop-graphic]')) {
			const id = button.dataset.printShopGraphic;
			if (id === 'none') {
				draw(button, renderText('NONE', 1, 'block'));
			} else {
				draw(button, renderGraphic(id, 2));
			}
		}

		for (const button of screen.querySelectorAll('[data-print-shop-border]')) {
			const sample = makeBitmap(60, 44);
			drawBorder(sample, button.dataset.printShopBorder);
			draw(button, sample);
		}
	}

	// The preview of the design on the screen: a page, the two halves of a card, or a banner in rows, like it lies on the floor.
	#drawPreview() {
		const {preview, previewNote} = this.parts;
		const design = this.#design;
		const screenContext = preview.getContext('2d');
		screenContext.fillStyle = '#000';
		screenContext.fillRect(0, 0, preview.width, preview.height);
		screenContext.imageSmoothingEnabled = true;
		screenContext.font = 'bold 9px "Courier New", monospace';
		screenContext.textAlign = 'center';

		if (design.mode === 'banner') {
			const landscape = bitmapToCanvas(renderBannerLandscape(this.#spec()));
			let scale = 0.25;
			const rowWidth = 300;
			let rows = Math.ceil((landscape.width * scale) / rowWidth);
			while (rows * ((pageWidth * scale) + 10) > 190) {
				scale *= 0.9;
				rows = Math.ceil((landscape.width * scale) / rowWidth);
			}

			const sliceLength = rowWidth / scale;
			const height = pageWidth * scale;
			const top = Math.max(6, Math.round((200 - (rows * (height + 10))) / 2));
			for (let row = 0; row < rows; row++) {
				const sourceX = row * sliceLength;
				const sourceWidth = Math.min(sliceLength, landscape.width - sourceX);
				screenContext.drawImage(landscape, sourceX, 0, sourceWidth, pageWidth, 10, top + (row * (height + 10)), sourceWidth * scale, height);
			}

			// The banner lies down on the screen, so its width is its length on the paper.
			const pages = pagesOf(landscape.width);
			const meters = (pages * 0.2794).toLocaleString('en-US', {maximumFractionDigits: 1});
			previewNote.textContent = `${pages} ${pages === 1 ? 'page' : 'pages'} long. That is ${meters} meters of banner!`;
			return;
		}

		const page = renderDesign(this.#spec());
		if (design.mode === 'card') {
			const half = pageRows / 2;
			const front = makeBitmap(pageWidth, half);
			front.dots.set(page.dots.subarray(0, pageWidth * half));
			const inside = makeBitmap(pageWidth, half);
			inside.dots.set(page.dots.subarray(pageWidth * half));
			screenContext.drawImage(bitmapToCanvas(front), 0, 60, 158, 103);
			screenContext.drawImage(bitmapToCanvas(turnUpsideDown(inside)), 162, 60, 158, 103);
			screenContext.fillStyle = '#55ffff';
			screenContext.fillText('FRONT', 79, 52);
			screenContext.fillText('INSIDE', 241, 52);
			previewNote.textContent = 'One page, folded in half. The inside prints upside down, on purpose.';
			return;
		}

		screenContext.drawImage(bitmapToCanvas(page), 86, 4, 148, 192);
		previewNote.textContent = design.mode === 'sign' ? 'One page. Tape it to the door.' : 'One page, ready for a letter to Mormor.';
	}

	#spec() {
		const design = this.#design;
		return {
			mode: design.mode,
			font: design.font,
			graphic: design.graphic,
			border: design.border,
			layout: design.layout,
			texts: design.texts[design.mode].map(text => cleanText(text)),
		};
	}

	#updateCopies() {
		const {copies} = this.parts;
		copies.textContent = String(this.#copies);
	}

	// MARK: The printer

	#savePrinter() {
		this.store('printer', {ink: Math.round(this.#printer.ink * 1000) / 1000, paperLeft: this.#printer.paperLeft});
	}

	#pageRowOf(index) {
		return (this.#printer.feedOffset + index) % pageRows;
	}

	#isAtPageStart() {
		return this.#pageRowOf(this.#printer.feed.length) === 0;
	}

	#hasPrint() {
		return this.#printer.feed.some(row => row.dots);
	}

	#updatePanel() {
		const {onlineLight, paperLight, online, lid, unjam, tear, print, supplies} = this.parts;
		const printer = this.#printer;
		onlineLight.dataset.state = printer.isOnline ? 'on' : '';
		paperLight.dataset.state = printer.isOutOfPaper || printer.isJammed ? 'blink' : (printer.paperLeft <= 3 ? 'warning' : '');
		setPressed(online, printer.isOnline);
		setPressed(lid, printer.isLidOpen);
		lid.textContent = printer.isLidOpen ? 'Close the Lid' : 'Open the Lid';
		unjam.hidden = !(printer.isJammed && printer.isLidOpen);
		tear.disabled = Boolean(printer.job) || !this.#hasPrint();
		print.disabled = Boolean(printer.job);
		const ribbon = Math.round(printer.ink * 100);
		const bars = Math.round(printer.ink * 8);
		supplies.textContent = `Ribbon ${'█'.repeat(bars)}${'░'.repeat(8 - bars)} ${ribbon}% · Paper: ${printer.paperLeft} ${printer.paperLeft === 1 ? 'sheet' : 'sheets'} · ${printer.isOnline ? 'On line' : 'Off line'}`;
	}

	// A pass of the head, 8 rows of dots, drawn once on its own canvas, so the paper scrolls without drawing every dot again.
	#chunkCanvas(index) {
		const {chunks} = this.#printer;
		if (chunks.has(index)) {
			return chunks.get(index);
		}

		const canvas = document.createElement('canvas');
		canvas.width = paperWidth;
		canvas.height = passRows * dot;
		const chunk = canvas.getContext('2d');
		this.#drawPaperBand(chunk, index * passRows, passRows, 0);
		chunks.set(index, canvas);
		return canvas;
	}

	// Paper with the strips and their holes, the perforations, and the printed dots, for rows of the feed from the first row, with the top of the drawing at `top`.
	#drawPaperBand(target, firstRow, count, top) {
		target.fillStyle = '#fbfaf3';
		target.fillRect(0, top, paperWidth, count * dot);
		target.fillStyle = '#d4d2c4';
		for (let row = firstRow; row < firstRow + count; row++) {
			const y = top + ((row - firstRow) * dot);
			// The perforations next to the strips, which tear when the strips are peeled off.
			if (row % 2 === 0) {
				target.fillRect(strip - 1, y, 1, dot);
				target.fillRect(paperWidth - strip, y, 1, dot);
			}

			const pageRow = this.#pageRowOf(row);
			if (pageRow === 0) {
				for (let x = 0; x < paperWidth; x += 6) {
					target.fillRect(x, y, 3, 1);
				}
			}

			// A tractor hole every half inch, through which the wheels pull the paper.
			if (pageRow % 16 === 8) {
				target.save();
				target.globalCompositeOperation = 'destination-out';
				target.beginPath();
				target.arc(strip / 2, y, 4, 0, Math.PI * 2);
				target.arc(paperWidth - (strip / 2), y, 4, 0, Math.PI * 2);
				target.fill();
				target.restore();
			}

			const paperRow = this.#printer.feed[row];
			if (paperRow?.dots) {
				drawDots(target, paperRow, row, y);
			}
		}
	}

	#addRow(dots) {
		const printer = this.#printer;
		if (this.#isAtPageStart()) {
			printer.paperLeft = Math.max(0, printer.paperLeft - 1);
		}

		printer.feed.push({dots, ink: printer.ink});
	}

	#drawWall() {
		const context = this.#context;
		const {canvas} = context;
		context.fillStyle = '#e9e4cf';
		context.fillRect(0, 0, canvas.width, floorY);
		// A poster of the computer room on the wall.
		context.fillStyle = '#f7f3e0';
		context.fillRect(446, 130, 100, 86);
		context.strokeStyle = '#b8b098';
		context.strokeRect(446.5, 130.5, 99, 85);
		context.fillStyle = '#1a3a8a';
		context.font = 'bold 11px "Comic Sans MS", "Chalkboard SE", cursive';
		context.textAlign = 'center';
		context.fillText('HUSK Å', 496, 152);
		context.fillText('LAGRE PÅ', 496, 168);
		context.fillText('DISKETT!', 496, 184);
		context.fillText('💾', 496, 206);

		context.fillStyle = '#8f9aa0';
		context.fillRect(0, floorY, canvas.width, canvas.height - floorY);
		context.fillStyle = '#7f8a90';
		for (let x = 0; x < canvas.width; x += 40) {
			context.fillRect(x, floorY, 1, canvas.height - floorY);
		}

		// The desk.
		context.fillStyle = '#b07c48';
		context.fillRect(0, deskY, 450, 12);
		context.fillStyle = '#8a5c30';
		context.fillRect(0, deskY + 12, 450, 4);
		context.fillRect(14, deskY + 16, 10, floorY - deskY - 16);
		context.fillRect(426, deskY + 16, 10, floorY - deskY - 16);
	}

	#drawBox() {
		const context = this.#context;
		const printer = this.#printer;
		// The box of continuous paper under the desk, which the paper comes from.
		const height = Math.round(52 * printer.paperLeft / boxSize);
		context.fillStyle = '#fbfaf3';
		context.fillRect(70, 488 - height + 50, 150, height);
		context.fillStyle = '#d4d2c4';
		for (let y = 538 - height; y < 538; y += 3) {
			context.fillRect(70, y, 150, 1);
		}

		context.fillStyle = '#b8955c';
		context.fillRect(60, 500, 170, 48);
		context.fillStyle = '#9c7a44';
		context.fillRect(60, 500, 170, 4);
		context.fillStyle = '#3a2a10';
		context.font = 'bold 12px "Courier New", monospace';
		context.textAlign = 'center';
		context.fillText('LISTEPAPIR', 145, 524);
		context.font = 'bold 9px "Courier New", monospace';
		context.fillText(printer.paperLeft === 0 ? 'TOM!' : `${printer.paperLeft} ARK`, 145, 538);
		if (printer.paperLeft > 0) {
			// The paper goes up behind the desk to the printer.
			context.fillStyle = '#efeee6';
			context.fillRect(130, deskY + 16, 30, 488 - height + 50 - deskY - 16);
		}
	}

	// The printed pages that piled up on the floor in folds, like a long banner always does.
	#drawPile(pages) {
		if (pages <= 0) {
			return;
		}

		const context = this.#context;
		const shown = Math.min(pages, 60);
		for (let index = 0; index < shown; index++) {
			const y = floorY - 6 - (index * 5);
			const shift = Math.round((hash(index + 3) - 0.5) * 14) + (index % 2 === 0 ? -4 : 4);
			const left = 462 + shift;
			context.fillStyle = index % 2 === 0 ? '#f4f2e8' : '#dddbcf';
			context.beginPath();
			context.moveTo(left, y + 5);
			context.lineTo(left + 112, y + 5);
			context.lineTo(left + 116, y);
			context.lineTo(left + 4, y);
			context.closePath();
			context.fill();
			context.fillStyle = 'rgba(22, 22, 44, 0.35)';
			for (let mark = 0; mark < 6; mark++) {
				if (hash((index * 13) + mark) > 0.45) {
					context.fillRect(left + 10 + (mark * 17), y + 2, 9, 1);
				}
			}
		}
	}

	#drawPrinterBody() {
		const context = this.#context;
		// The beige body of the printer, with the vents and the knob of the platen.
		context.fillStyle = 'rgba(0, 0, 0, 0.18)';
		context.fillRect(28, deskY - 4, 412, 6);
		context.fillStyle = '#d8d0b8';
		context.beginPath();
		context.roundRect(24, 312, 412, deskY - 312, [10, 10, 4, 4]);
		context.fill();
		context.fillStyle = '#c4bb9f';
		context.fillRect(24, 400, 412, 36);
		context.fillStyle = '#a99f82';
		for (let x = 50; x < 250; x += 10) {
			context.fillRect(x, 410, 5, 18);
		}

		context.fillStyle = '#1a3a8a';
		context.font = 'italic bold 14px Arial, sans-serif';
		context.textAlign = 'left';
		context.fillText('EPSON', 300, 424);
		context.fillStyle = '#555';
		context.font = 'bold 9px Arial, sans-serif';
		context.fillText('LX-800', 356, 424);
		context.fillStyle = '#6e6650';
		context.beginPath();
		context.arc(444, 336, 13, 0, Math.PI * 2);
		context.fill();
		context.fillStyle = '#8c8672';
		context.beginPath();
		context.arc(444, 336, 8, 0, Math.PI * 2);
		context.fill();
	}

	#drawHead(time) {
		const context = this.#context;
		const printer = this.#printer;
		// The ribbon, in front of the paper, and the head, which goes left and right.
		context.fillStyle = 'rgba(20, 20, 30, 0.5)';
		context.fillRect(paperLeft + 6, headY + 15, paperWidth - 12, 3);
		const x = paperLeft + strip + (printer.headX * dot);
		const shake = printer.pass && !this.reducedMotion ? Math.sin(time * 0.09) * 0.6 : 0;
		context.fillStyle = '#3c3c44';
		context.fillRect(x - 14, headY - 6 + shake, 28, 26);
		context.fillStyle = '#5a5a66';
		context.fillRect(x - 14, headY - 6 + shake, 28, 6);
		context.fillStyle = '#26262c';
		context.fillRect(x - 3, headY + 2 + shake, 6, 16);
		// The rail that the head runs on.
		context.fillStyle = '#9a9a9e';
		context.fillRect(paperLeft - 10, headY + 22, paperWidth + 20, 3);
	}

	#drawLid() {
		const context = this.#context;
		if (this.#printer.isLidOpen) {
			// The lid is up, tipped back behind the paper.
			context.fillStyle = 'rgba(70, 50, 40, 0.45)';
			context.beginPath();
			context.moveTo(40, barY + 2);
			context.lineTo(420, barY + 2);
			context.lineTo(400, barY - 54);
			context.lineTo(60, barY - 54);
			context.closePath();
			context.fill();
			context.strokeStyle = 'rgba(40, 30, 20, 0.6)';
			context.stroke();
			return;
		}

		// The smoked plastic lid, which the head shows through.
		context.fillStyle = 'rgba(80, 56, 44, 0.42)';
		context.beginPath();
		context.moveTo(40, 314);
		context.lineTo(420, 314);
		context.lineTo(404, barY);
		context.lineTo(56, barY);
		context.closePath();
		context.fill();
		context.fillStyle = 'rgba(255, 255, 255, 0.22)';
		context.fillRect(64, barY + 4, 330, 3);
		// The tear bar along the top of the lid, with the tear so far.
		context.fillStyle = '#6a6a70';
		context.fillRect(52, barY - 2, 356, 3);
	}

	#drawPaper(time) {
		const context = this.#context;
		const printer = this.#printer;
		const rows = printer.feed.length;
		const scroll = printer.scroll;
		const flyOffset = printer.tearFly * 260;
		context.save();
		context.beginPath();
		context.rect(paperLeft - 2, paperTop, paperWidth + 4, headY + 18 - paperTop);
		context.clip();

		// The paper from the last tear, or the short end that sticks out of the printer.
		const topY = headY - (scroll * dot);
		const stubY = Math.min(topY, barY - 12);
		context.fillStyle = '#fbfaf3';
		context.fillRect(paperLeft, Math.max(paperTop, stubY), paperWidth, headY + 18 - Math.max(paperTop, stubY));
		if (stubY > paperTop) {
			this.#drawTopEdge(stubY);
		}

		const firstChunk = Math.max(0, Math.floor((scroll - visibleRows - passRows) / passRows));
		const lastChunk = Math.ceil(rows / passRows);
		// The passes that went over the top are not kept, so a long banner does not keep a canvas for each of them.
		for (const index of printer.chunks.keys()) {
			if (index < firstChunk) {
				printer.chunks.delete(index);
			}
		}

		for (let index = firstChunk; index < lastChunk; index++) {
			const y = headY - ((scroll - (index * passRows)) * dot) - flyOffset;
			if (y + (passRows * dot) < paperTop - 30 || y > headY + 18) {
				continue;
			}

			context.drawImage(this.#chunkCanvas(index), paperLeft, y);
		}

		// The pass that the head prints now, up to where the head has come.
		if (printer.pass) {
			const pass = printer.pass;
			const from = pass.direction > 0 ? 0 : Math.floor(printer.headX);
			const to = pass.direction > 0 ? Math.ceil(printer.headX) : pageWidth;
			context.save();
			context.translate(paperLeft, 0);
			for (const [offset, dots] of pass.rows.entries()) {
				if (dots) {
					drawDots(context, {dots, ink: printer.ink}, rows + offset, headY + ((rows + offset - scroll) * dot), {from: clamp(from, 0, pageWidth), to: clamp(to, 0, pageWidth)});
				}
			}

			context.restore();
		}

		context.restore();

		if (printer.isJammed) {
			this.#drawCrumple(time);
		}

		if (printer.tear > 0 && printer.tearFly === 0) {
			// The tear along the bar so far, jagged.
			context.strokeStyle = '#555';
			context.lineWidth = 1.5;
			context.beginPath();
			const end = paperLeft + (paperWidth * printer.tear);
			for (let x = paperLeft; x <= end; x += 4) {
				context.lineTo(x, barY - 3 + (hash(x) * 3));
			}

			context.stroke();
			context.lineWidth = 1;
		}

		// When the paper is long, it curls over at the top and goes down behind the desk to the floor.
		if (scroll > visibleRows - 4 && printer.tearFly === 0) {
			context.fillStyle = '#eceadf';
			context.beginPath();
			context.ellipse(paperLeft + (paperWidth / 2), paperTop, paperWidth / 2, 12, 0, Math.PI, 0);
			context.fill();
			context.fillStyle = '#d8d6ca';
			context.beginPath();
			context.moveTo(paperLeft + paperWidth, paperTop);
			context.bezierCurveTo(paperLeft + paperWidth + 60, paperTop - 14, 578, paperTop + 10, 578, paperTop + 90);
			context.lineTo(578, floorY - 8);
			context.lineTo(564, floorY - 8);
			context.lineTo(564, paperTop + 96);
			context.bezierCurveTo(564, paperTop + 34, paperLeft + paperWidth + 30, paperTop + 8, paperLeft + paperWidth - 6, paperTop + 8);
			context.closePath();
			context.fill();
		}
	}

	#drawTopEdge(y) {
		if (!this.#printer.isRaggedTop) {
			return;
		}

		const context = this.#context;
		// A ragged edge, from a tear that was not on the perforation.
		context.fillStyle = '#e9e4cf';
		context.beginPath();
		context.moveTo(paperLeft, y - 2);
		for (let x = paperLeft; x <= paperLeft + paperWidth; x += 5) {
			context.lineTo(x, y + (hash(x * 0.37) * 6));
		}

		context.lineTo(paperLeft + paperWidth, y - 2);
		context.closePath();
		context.fill();
	}

	// The paper that jammed crumples up over the tear bar like an accordion.
	#drawCrumple(time) {
		const context = this.#context;
		const {crumple} = this.#printer;
		const height = 46 * crumple;
		if (height <= 1) {
			return;
		}

		const bottom = barY + 2;
		const folds = 9;
		for (let index = 0; index < folds; index++) {
			const y0 = bottom - (index * height / folds);
			const y1 = bottom - ((index + 1) * height / folds);
			const lean = (hash(index + Math.floor(time / 900)) - 0.5) * 10 * crumple;
			context.fillStyle = index % 2 === 0 ? '#f2f0e4' : '#cfccbe';
			context.beginPath();
			context.moveTo(paperLeft - 6 + lean, y0);
			context.lineTo(paperLeft + paperWidth + 6 + lean, y0 + ((index % 2 === 0 ? 1 : -1) * 4));
			context.lineTo(paperLeft + paperWidth + 4 - lean, y1);
			context.lineTo(paperLeft - 4 - lean, y1 + ((index % 2 === 0 ? -1 : 1) * 4));
			context.closePath();
			context.fill();
			context.strokeStyle = 'rgba(0, 0, 0, 0.18)';
			context.stroke();
		}
	}

	#drawPrinter(time = performance.now()) {
		const printer = this.#printer;
		this.#drawWall();
		this.#drawBox();
		const overTheTop = Math.max(0, printer.scroll - visibleRows);
		this.#drawPile(printer.tearFly > 0 ? 0 : Math.ceil(overTheTop / pageRows));
		this.#drawPrinterBody();
		this.#drawPaper(time);
		this.#drawHead(time);
		this.#drawLid();
	}

	// MARK: Printing

	#isPrinterReady() {
		const printer = this.#printer;
		return printer.isOnline && !printer.isJammed && !printer.isLidOpen && !printer.isOutOfPaper && printer.tearFly === 0;
	}

	#needsFrames() {
		const printer = this.#printer;
		return (printer.job && this.#isPrinterReady()) || Math.abs(printer.scroll - printer.feed.length) > 0.01 || (printer.isJammed && printer.crumple < 1) || printer.tearFly > 0;
	}

	#startJob() {
		const printer = this.#printer;
		if (printer.job || printer.tearFly > 0) {
			return;
		}

		const jobSpec = this.#spec();
		const bitmap = renderDesign(jobSpec);
		const rows = [];
		// The printer always starts at the top of a page, so a page prints between the perforations.
		const lead = this.#isAtPageStart() ? 0 : pageRows - this.#pageRowOf(printer.feed.length);
		for (let index = 0; index < lead; index++) {
			rows.push(undefined);
		}

		for (let copy = 0; copy < this.#copies; copy++) {
			for (let row = 0; row < bitmap.height; row++) {
				const dots = bitmap.dots.subarray(row * pageWidth, (row + 1) * pageWidth);
				rows.push(dots.includes(1) ? dots : undefined);
			}

			while (copy < this.#copies - 1 && this.#pageRowOf(printer.feed.length + rows.length) !== 0) {
				rows.push(undefined);
			}
		}

		while (rows.length % passRows !== 0) {
			rows.push(undefined);
		}

		const passesWithInk = [];
		for (let index = 0; index < rows.length; index += passRows) {
			if (rows.slice(index, index + passRows).some(Boolean)) {
				passesWithInk.push(index);
			}
		}

		// After the first printout, a paper jam can happen, somewhere in the middle, like always.
		const willJam = printer.jobsPrinted > 0 && passesWithInk.length > 8 && Math.random() < 0.3;
		printer.job = {
			rows,
			index: 0,
			feedStart: printer.feed.length,
			spec: jobSpec,
			jamAt: willJam ? passesWithInk[Math.floor(passesWithInk.length * (0.3 + (Math.random() * 0.5)))] : undefined,
			pages: pagesOf(rows.length),
			hasComplained: false,
		};
		printer.jobsPrinted++;
		printer.feedSpecs.push(jobSpec);
		const {mainMenu, status} = this.parts;
		this.#showStep('printing', {focus: false});
		mainMenu.focus({preventScroll: true});
		this.#updatePrintingNote();
		this.#updatePanel();

		if (!printer.isOnline) {
			this.say('The printer is off line. Press On Line, so it can print.');
		} else if (printer.isOutOfPaper || printer.paperLeft === 0) {
			this.#outOfPaper();
		} else {
			this.say(jobSpec.mode === 'banner' ? 'The printer screams to life. The banner comes out sideways, one line at a time.' : 'Hiiii-iiiii-iiiii! The printer starts.');
		}

		// The status is right under the printer, so this brings both into view, also on a phone, where the visitor reads what to do next.
		status.scrollIntoView({behavior: this.reducedMotion ? 'auto' : 'smooth', block: 'nearest'});
		this.#loop.start();
	}

	#updatePrintingNote() {
		const {printingNote} = this.parts;
		const job = this.#printer.job;
		if (!job) {
			printingNote.textContent = 'Done! Tear it off the printer.';
			return;
		}

		const page = Math.min(job.pages, Math.floor(job.index / pageRows) + 1);
		printingNote.textContent = `Page ${page} of ${job.pages}. Look at the printer!`;
	}

	#finishJob() {
		const printer = this.#printer;
		const job = printer.job;
		printer.job = undefined;
		printer.pass = undefined;
		printer.headX = -12;
		this.#savePrinter();
		this.#updatePanel();
		this.#updatePrintingNote();
		if (job.spec.mode === 'banner' && !this.#isAtPageStart()) {
			this.say('Done! Now it needs a Form Feed (press On Line first, so it goes off line), and then tear it off along the perforation.');
		} else {
			this.say('Done! Drag along the top of the printer to tear it off along the perforation.');
		}

		if (printer.ink < 0.25) {
			this.toast(`Trond: “Why is your ${modeNames[job.spec.mode].toLowerCase()} so pale? Change the ribbon!”`);
		} else if (job.spec.mode === 'banner' && job.pages >= 8) {
			this.toast('Trond: “Kult! Can you make one for me too?”');
		}
	}

	#outOfPaper() {
		this.#printer.isOutOfPaper = true;
		this.#printer.isOnline = false;
		this.#sounds.beep(3);
		this.#updatePanel();
		this.say('Beep beep beep! Paper Out. The box of listepapir is empty. Get a new box from the storage room.');
	}

	#jam() {
		const printer = this.#printer;
		printer.isJammed = true;
		printer.isOnline = false;
		printer.pass = undefined;
		printer.job.jamAt = undefined;
		this.#sounds.crunch();
		this.#updatePanel();
		this.say('KRRRRK! Paper jam! The paper crumples up over the printer. Open the lid and pull it out.');
		if (this.reducedMotion) {
			printer.crumple = 1;
		}
	}

	// Prints for some seconds: one pass of the head at a time, quick over blank lines, like the real printer, which skips them.
	#printFor(seconds) {
		const printer = this.#printer;
		printer.budget += seconds;
		while (printer.budget > 0 && printer.job && this.#isPrinterReady()) {
			const job = printer.job;
			if (!printer.pass) {
				if (job.index >= job.rows.length) {
					this.#finishJob();
					return;
				}

				if (this.#isAtPageStart() && printer.paperLeft <= 0) {
					this.#outOfPaper();
					return;
				}

				if (job.jamAt === job.index) {
					this.#jam();
					return;
				}

				const rows = job.rows.slice(job.index, job.index + passRows);
				let first = pageWidth;
				let last = -1;
				let count = 0;
				for (const dots of rows) {
					if (!dots) {
						continue;
					}

					for (let column = 0; column < pageWidth; column++) {
						if (dots[column] === 1) {
							count++;
							first = Math.min(first, column);
							last = Math.max(last, column);
						}
					}
				}

				if (count === 0) {
					for (const dots of rows) {
						this.#addRow(dots);
					}

					job.index += passRows;
					printer.budget -= 0.03;
					this.#sounds.lineFeed();
					continue;
				}

				const direction = printer.direction;
				const duration = 0.04 + (0.06 * ((last - first + 1) / pageWidth));
				printer.pass = {rows, direction, first, last: last + 1, time: 0, duration, count};
				printer.headX = direction > 0 ? first : last + 1;
				this.#sounds.screech(duration, count / (passRows * pageWidth) * 3, direction);
			}

			const pass = printer.pass;
			const step = Math.min(printer.budget, pass.duration - pass.time);
			pass.time += step;
			printer.budget -= step;
			const progress = pass.time / pass.duration;
			printer.headX = pass.direction > 0 ? pass.first + ((pass.last - pass.first) * progress) : pass.last - ((pass.last - pass.first) * progress);

			if (pass.time >= pass.duration - 0.0001) {
				this.#finishPass();
			}
		}

		if (printer.budget > 0) {
			printer.budget = 0;
		}
	}

	#finishPass() {
		const printer = this.#printer;
		const pass = printer.pass;
		const job = printer.job;
		for (const dots of pass.rows) {
			this.#addRow(dots);
		}

		job.index += passRows;
		printer.pass = undefined;
		printer.direction = -pass.direction;
		// The ribbon gives a bit of its ink for every dot.
		printer.ink = Math.max(0.04, printer.ink - (pass.count / 260_000));
		this.#sounds.lineFeed();
		this.#updatePrintingNote();

		if (!job.hasComplained && job.index > pageRows * 6) {
			job.hasComplained = true;
			this.toast(randomItem(['Mamma: “Sindre, what is screeching like that?!”', 'The class next door knocks on the wall.', 'Mormor: “Is that the modem again?”']));
		}

		if (job.index % (pageRows * 2) === 0) {
			this.#updatePanel();
		}
	}

	// With reduced motion, the printer prints a whole page at a time, without the moving head.
	#printPage() {
		const printer = this.#printer;
		const job = printer.job;
		if (!job || !this.#isPrinterReady()) {
			return;
		}

		do {
			if (this.#isAtPageStart() && printer.paperLeft <= 0) {
				this.#outOfPaper();
				break;
			}

			if (job.jamAt !== undefined && job.jamAt <= job.index) {
				this.#jam();
				break;
			}

			const rows = job.rows.slice(job.index, job.index + passRows);
			let count = 0;
			for (const dots of rows) {
				this.#addRow(dots);
				count += dots ? countDots(dots) : 0;
			}

			job.index += passRows;
			printer.ink = Math.max(0.04, printer.ink - (count / 260_000));
		} while (job.index < job.rows.length && !this.#isAtPageStart());

		printer.scroll = printer.feed.length;
		this.#sounds.screech(0.25, 0.5, 1);
		this.#updatePrintingNote();
		this.#updatePanel();
		if (printer.job && job.index >= job.rows.length) {
			this.#finishJob();
		}
	}

	#step(seconds) {
		const printer = this.#printer;
		const time = performance.now();
		if (this.reducedMotion) {
			printer.pageTimer += seconds;
			if (printer.job && this.#isPrinterReady() && printer.pageTimer > 0.7) {
				printer.pageTimer = 0;
				this.#printPage();
			}

			printer.scroll = printer.feed.length;
		} else {
			this.#printFor(seconds);
			// The paper moves up smoothly after each line feed.
			printer.scroll += (printer.feed.length - printer.scroll) * Math.min(1, seconds * 18);
			if (Math.abs(printer.feed.length - printer.scroll) < 0.05) {
				printer.scroll = printer.feed.length;
			}
		}

		if (printer.isJammed && printer.crumple < 1) {
			printer.crumple = Math.min(1, printer.crumple + (seconds * 1.5));
		}

		if (printer.tearFly > 0) {
			printer.tearFly += seconds * 2.5;
			if (printer.tearFly >= 1) {
				this.#completeTear();
			}
		}

		this.#drawPrinter(time);
	}

	// MARK: The panel of the printer

	#feed(rows, name) {
		const printer = this.#printer;
		if (printer.isOnline) {
			// The classic mistake: the feed buttons only work while the printer is off line.
			this.say(`Nothing happens. ${name} only works off line, so press On Line first. Everybody forgets.`);
			this.#sounds.beep(1);
			return;
		}

		if (printer.isJammed || printer.isLidOpen) {
			this.say(printer.isJammed ? 'The paper is jammed. Pull it out first.' : 'Close the lid first.');
			return;
		}

		// In the middle of a printout, a feed would leave a gap in it.
		if (printer.job) {
			this.say('Not in the middle of a printout! Press On Line, and it goes on printing.');
			this.#sounds.beep(1);
			return;
		}

		if (printer.isOutOfPaper) {
			this.say('There is no paper to feed. Put in a new box.');
			return;
		}

		// The rows are fed at once, and the paper rolls up to them on the screen.
		let isOut = false;
		for (let index = 0; index < rows && !isOut; index++) {
			isOut = this.#isAtPageStart() && printer.paperLeft <= 0;
			if (!isOut) {
				this.#addRow(undefined);
			}
		}

		this.#savePrinter();
		if (isOut) {
			this.#outOfPaper();
		} else {
			this.#sounds.whir(this.reducedMotion ? 0.3 : Math.max(0.12, rows / 900));
			this.#updatePanel();
			this.say(name === 'Form Feed' ? 'Brrrrrt! The paper rolls up to the next perforation.' : 'Brt. One line up.');
		}

		this.#loop.start();
		if (!this.#loop.isVisible) {
			printer.scroll = printer.feed.length;
			this.#drawPrinter();
		}
	}

	// MARK: Tearing it off

	#tearOff() {
		const printer = this.#printer;
		if (printer.tearFly > 0) {
			return;
		}

		if (printer.job) {
			this.say('Wait until it is done! Or the banner gets a hole in the middle.');
			return;
		}

		if (printer.isJammed) {
			this.say('Pull out the crumpled paper first.');
			return;
		}

		if (!this.#hasPrint()) {
			this.say('There is nothing on the paper yet. Print something first.');
			return;
		}

		this.#sounds.rip(0.35, 0.09);
		if (this.reducedMotion || !this.#loop.isVisible) {
			this.#completeTear();
		} else {
			printer.tearFly = 0.01;
			this.#loop.start();
		}
	}

	#completeTear() {
		const printer = this.#printer;
		const rows = printer.feed;
		const isRagged = !this.#isAtPageStart();
		const specs = printer.feedSpecs;
		this.#printout = {
			rows,
			feedOffset: printer.feedOffset,
			isRaggedTop: printer.isRaggedTop,
			isRaggedEnd: isRagged,
			// Only a printout of one kind is folded into a card or hung as a banner, and then as its last design.
			spec: specs.every(item => item.mode === specs[0].mode) ? specs.at(-1) : undefined,
			peeled: [0, 0],
			// Anything with a banner in it lies down, as it is long.
			isBanner: specs.some(item => item.mode === 'banner'),
		};
		printer.feedOffset = this.#pageRowOf(rows.length);
		printer.isRaggedTop = isRagged;
		printer.feed = [];
		printer.feedSpecs = [];
		printer.scroll = 0;
		printer.tear = 0;
		printer.tearFly = 0;
		printer.chunks.clear();
		this.#updatePanel();
		this.#drawPrinter();
		const {printoutCanvas} = this.parts;
		this.#showPrintout();
		printoutCanvas.focus({preventScroll: true});
		this.say(isRagged ? 'Rrrrip! It tore crooked across a page, as it was not at the perforation. (A Form Feed first, next time.)' : 'Rrrrip! A clean tear along the perforation.');
	}

	// MARK: The printout

	#printoutScale() {
		return this.#printout.isBanner ? 2 : 4;
	}

	#drawPrintout() {
		const printout = this.#printout;
		if (!printout) {
			return;
		}

		const {printoutCanvas} = this.parts;
		const scale = this.#printoutScale();
		const length = printout.rows.length;
		const across = paperDots + (margin * 2);
		const along = length + (margin * 2);
		printoutCanvas.width = (printout.isBanner ? along : across) * scale;
		printoutCanvas.height = (printout.isBanner ? across : along) * scale;
		printoutCanvas.dataset.state = printout.isBanner ? 'banner' : 'page';
		const target = printoutCanvas.getContext('2d');
		target.save();
		target.scale(scale, scale);
		if (printout.isBanner) {
			target.translate(0, across);
			target.rotate(-Math.PI / 2);
		}

		target.translate(margin, margin);
		this.#drawPrintoutPaper(target, length);
		target.restore();
	}

	#drawPrintoutPaper(target, length) {
		const printout = this.#printout;
		const peeled = printout.peeled;
		target.fillStyle = '#fbfaf3';
		const left = peeled[0] >= 1 ? stripDots : 0;
		const right = peeled[1] >= 1 ? paperDots - stripDots : paperDots;
		target.fillRect(left, 0, right - left, length);

		for (let row = 0; row < length; row++) {
			const pageRow = (printout.feedOffset + row) % pageRows;
			if (pageRow === 0 && row > 0) {
				target.fillStyle = '#c8c6b8';
				for (let x = left; x < right; x += 3) {
					target.fillRect(x, row, 1.5, 0.5);
				}
			}

			const paperRow = printout.rows[row];
			if (paperRow?.dots) {
				drawDots(target, paperRow, row, row, {size: 1});
			}
		}

		// The strips with the holes, peeled off from the top as far as the visitor has pulled them.
		for (const side of [0, 1]) {
			const progress = peeled[side];
			if (progress >= 1) {
				continue;
			}

			const x = side === 0 ? 0 : paperDots - stripDots;
			const torn = length * progress;
			this.#drawStrip(target, x, torn, length - torn, length);
			if (progress > 0) {
				// The part that is peeled off bends away from the paper, from where it is still attached.
				target.save();
				const outward = side === 0 ? -1 : 1;
				const angle = Math.min(0.5, (4 + (progress * 10)) / Math.max(torn, 1));
				target.translate(x + (side === 0 ? 0 : stripDots), torn);
				target.rotate(outward * angle);
				target.translate(side === 0 ? 0 : -stripDots, -torn);
				target.shadowColor = 'rgba(0, 0, 0, 0.25)';
				target.shadowBlur = 2;
				this.#drawStrip(target, 0, 0, torn, length);
				target.restore();
			}
		}

		target.fillStyle = '#d4d2c4';
		if (peeled[0] < 1) {
			target.fillRect(stripDots - 0.5, length * peeled[0], 0.5, length * (1 - peeled[0]));
		}

		if (peeled[1] < 1) {
			target.fillRect(paperDots - stripDots, length * peeled[1], 0.5, length * (1 - peeled[1]));
		}

		if (printout.isRaggedEnd) {
			target.fillStyle = '#7a6a55';
			target.beginPath();
			target.moveTo(-margin, length + margin);
			for (let x = -1; x <= paperDots + 1; x += 2.5) {
				target.lineTo(x, length - (hash(x * 1.7) * 4));
			}

			target.lineTo(paperDots + margin, length + margin);
			target.closePath();
			target.fill();
		}

		if (printout.isRaggedTop) {
			target.fillStyle = '#7a6a55';
			target.beginPath();
			target.moveTo(-margin, -margin);
			for (let x = -1; x <= paperDots + 1; x += 2.5) {
				target.lineTo(x, hash(x * 0.37) * 4);
			}

			target.lineTo(paperDots + margin, -margin);
			target.closePath();
			target.fill();
		}
	}

	#drawStrip(target, x, from, count, length) {
		if (count <= 0) {
			return;
		}

		target.fillStyle = '#f6f4ea';
		target.fillRect(x, from, stripDots, count);
		target.fillStyle = '#7a6a55';
		for (let row = 0; row < length; row++) {
			const pageRow = (this.#printout.feedOffset + row) % pageRows;
			if (pageRow % 16 === 8 && row >= from && row < from + count) {
				target.beginPath();
				target.arc(x + (stripDots / 2), row, 2, 0, Math.PI * 2);
				target.fill();
			}
		}
	}

	#showPrintout() {
		const {printoutBox, card, fold, hang, peel, printoutNote} = this.parts;
		const printout = this.#printout;
		printoutBox.hidden = false;
		card.hidden = true;
		fold.hidden = printout.spec?.mode !== 'card';
		hang.hidden = printout.spec?.mode !== 'banner';
		peel.disabled = false;
		printoutNote.textContent = `${printout.spec?.mode === 'banner' ? 'Your banner!' : 'Your printout!'} Drag the strips with the holes sideways to peel them off. So satisfying.`;
		this.#drawPrintout();
		if (!this.reducedMotion) {
			printoutBox.scrollIntoView({behavior: 'smooth', block: 'nearest'});
		}
	}

	#peel(side, amount) {
		const printout = this.#printout;
		if (!printout || printout.peeled[side] >= 1) {
			return;
		}

		printout.peeled[side] = Math.min(1, printout.peeled[side] + amount);
		this.#sounds.rip(0.05 + (amount * 0.3), 0.05);
		if (printout.peeled[side] >= 1) {
			const isDone = printout.peeled.every(progress => progress >= 1);
			this.say(isDone ? 'Aaah. Both strips are off. The most satisfying thing in the whole computer room.' : 'One strip off! It curls up like a paper snake. Now the other one.');
			if (isDone) {
				const {peel, printoutCanvas} = this.parts;
				if (document.activeElement === peel) {
					printoutCanvas.focus({preventScroll: true});
				}

				peel.disabled = true;
			}
		}

		this.#drawPrintout();
	}

	// How far across the paper a pointer is, in dots from the left edge of the paper, which is the bottom edge of a banner.
	#printoutAcross(event) {
		const {printoutCanvas} = this.parts;
		const point = canvasPoint(printoutCanvas, event);
		const scale = this.#printoutScale();
		return this.#printout.isBanner ? paperDots + margin - (point.y / scale) : (point.x / scale) - margin;
	}

	#peelNext() {
		if (!this.#printout) {
			return;
		}

		const side = this.#printout.peeled[0] < 1 ? 0 : 1;
		this.#peel(side, 0.34);
	}

	// MARK: The card

	#averageInk() {
		const inked = this.#printout.rows.filter(row => row.dots);
		if (inked.length === 0) {
			return this.#printer.ink;
		}

		let total = 0;
		for (const row of inked) {
			total += row.ink;
		}

		return total / inked.length;
	}

	#setCardState(state) {
		const {card} = this.parts;
		card.dataset.state = state;
	}

	// MARK: The banner over the page

	// Draws the banner across the top of the page, taped at the ends and sagging a bit in the middle.
	#drawHanging(hung) {
		const {hanging, hangingCanvas} = this.parts;
		const spec = hung.spec;
		const landscape = renderBannerLandscape(spec);
		const width = Math.max(320, Math.round(hanging.parentElement.clientWidth || 680)) * Math.min(2, devicePixelRatio || 1);
		const showStrips = !hung.peeled.every(Boolean);
		const paperHeight = pageWidth + (showStrips ? stripDots * 2 : 0);
		const scale = Math.min((width * 0.94) / landscape.width, (width * 0.16) / paperHeight);
		const bannerWidth = landscape.width * scale;
		const bannerHeight = paperHeight * scale;
		const sag = Math.min(24, bannerWidth * 0.03);
		hangingCanvas.width = Math.round(width);
		hangingCanvas.height = Math.round(bannerHeight + sag + 16);

		const source = document.createElement('canvas');
		source.width = landscape.width;
		source.height = paperHeight;
		const sourceContext = source.getContext('2d');
		sourceContext.fillStyle = '#fbfaf3';
		sourceContext.fillRect(0, 0, source.width, source.height);
		const top = showStrips ? stripDots : 0;
		for (let x = 0; x < landscape.width; x++) {
			const ink = hung.inkStart + ((hung.inkEnd - hung.inkStart) * (x / landscape.width));
			sourceContext.fillStyle = inkColor(ink);
			for (let y = 0; y < landscape.height; y++) {
				if (landscape.dots[(y * landscape.width) + x] === 1 && !isDotMissing(ink, (x * 160) + y)) {
					sourceContext.fillRect(x, top + y, 1, 1);
				}
			}
		}

		if (showStrips) {
			sourceContext.fillStyle = '#7a6a55';
			for (let x = 8; x < landscape.width; x += 16) {
				for (const [index, y] of [paperHeight - (stripDots / 2), stripDots / 2].entries()) {
					if (!hung.peeled[index]) {
						sourceContext.beginPath();
						sourceContext.arc(x, y, 2, 0, Math.PI * 2);
						sourceContext.fill();
					}
				}
			}
		}

		const target = hangingCanvas.getContext('2d');
		target.clearRect(0, 0, hangingCanvas.width, hangingCanvas.height);
		target.imageSmoothingEnabled = true;
		const left = (hangingCanvas.width - bannerWidth) / 2;
		const slices = Math.ceil(bannerWidth / 2);
		for (let index = 0; index < slices; index++) {
			const x = index * 2;
			const progress = x / bannerWidth;
			const y = 8 + (Math.sin(progress * Math.PI) * sag);
			target.drawImage(source, progress * landscape.width, 0, (2 / bannerWidth) * landscape.width, paperHeight, left + x, y, 2.5, bannerHeight);
		}

		// Pieces of tape at the ends.
		target.fillStyle = 'rgba(255, 240, 160, 0.75)';
		for (const x of [left - 6, left + bannerWidth - 18]) {
			target.save();
			target.translate(x + 12, 14);
			target.rotate(x < hangingCanvas.width / 2 ? -0.5 : 0.5);
			target.fillRect(-14, -6, 28, 12);
			target.restore();
		}
	}

	#hangBanner(hung) {
		const {hanging} = this.parts;
		// The banner goes at the very top of the panel of the page, above everything else. It stays a part of the toy there, as the toy found its parts before.
		const panel = this.parentElement;
		if (panel && hanging.parentElement !== panel) {
			panel.prepend(hanging);
		}

		hanging.hidden = false;
		this.#drawHanging(hung);
	}
}
