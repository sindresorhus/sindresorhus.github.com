// The helpers of the canvases of the toys of the 1999 page, so they are written once: the position of a pointer, the shapes, a canvas that is not on the page, the sprites of big pixels, and the tiny pixel font of the screens of the toys.

// The position of a pointer on a canvas, in the pixels of the canvas.
export const canvasPoint = (canvas, event) => {
	const rectangle = canvas.getBoundingClientRect();
	return {
		x: (event.clientX - rectangle.left) * canvas.width / rectangle.width,
		y: (event.clientY - rectangle.top) * canvas.height / rectangle.height,
	};
};

// Shapes for the canvases of the toys.
export const fillShape = (context, color, x, y, width, height) => {
	context.fillStyle = color;
	context.fillRect(Math.round(x), Math.round(y), Math.round(width), Math.round(height));
};

export const fillEllipse = (context, color, x, y, radiusX, radiusY) => {
	context.fillStyle = color;
	context.beginPath();
	context.ellipse(x, y, Math.max(radiusX, 0.1), Math.max(radiusY, 0.1), 0, 0, Math.PI * 2);
	context.fill();
};

export const fillPolygon = (context, color, points) => {
	context.fillStyle = color;
	context.beginPath();
	for (const [x, y] of points) {
		context.lineTo(x, y);
	}

	context.closePath();
	context.fill();
};

// A canvas that is not on the page, like for drawing in layers, or for picking.
export const makeCanvas = (width, height) => {
	const canvas = document.createElement('canvas');
	canvas.width = width;
	canvas.height = height;
	return canvas;
};

// Makes a canvas with a sprite of big pixels, from rows of letters where each letter is a color of the palette, and any other letter, like a dot, is clear. Short rows are clear at the end.
export const makeSprite = (rows, palette, scale = 1) => {
	const width = Math.max(...rows.map(row => row.length));
	const canvas = makeCanvas(width * scale, rows.length * scale);
	const context = canvas.getContext('2d');

	for (const [y, row] of rows.entries()) {
		for (const [x, letter] of [...row].entries()) {
			if (palette[letter]) {
				context.fillStyle = palette[letter];
				context.fillRect(x * scale, y * scale, scale, scale);
			}
		}
	}

	return canvas;
};

// The same sprite, facing the other way.
export const mirrorSprite = sprite => {
	const canvas = makeCanvas(sprite.width, sprite.height);
	const context = canvas.getContext('2d');
	context.translate(sprite.width, 0);
	context.scale(-1, 1);
	context.drawImage(sprite, 0, 0);
	return canvas;
};

// A sprite that faces right, and its mirror, which faces left.
export const makeFacingSprite = (rows, palette, scale) => {
	const right = makeSprite(rows, palette, scale);
	return {right, left: mirrorSprite(right)};
};

// A tiny pixel font of 3 × 5 for the screens of the toys, so the text is crisp at any size. Each letter is five rows of three bits. A letter that is not in the font is drawn as `?`. A toy with its own shape for a letter makes its own font from this one, like `{...pixelFont, '°': [7, 5, 7, 0, 0]}`.
export const pixelFont = {
	A: [2, 5, 7, 5, 5], B: [6, 5, 6, 5, 6], C: [3, 4, 4, 4, 3], D: [6, 5, 5, 5, 6], E: [7, 4, 6, 4, 7], F: [7, 4, 6, 4, 4], G: [3, 4, 5, 5, 3], H: [5, 5, 7, 5, 5], I: [7, 2, 2, 2, 7], J: [1, 1, 1, 5, 2], K: [5, 5, 6, 5, 5], L: [4, 4, 4, 4, 7], M: [5, 7, 7, 5, 5], N: [6, 5, 5, 5, 5], O: [2, 5, 5, 5, 2], P: [6, 5, 6, 4, 4], Q: [2, 5, 5, 6, 3], R: [6, 5, 6, 5, 5], S: [3, 4, 2, 1, 6], T: [7, 2, 2, 2, 2], U: [5, 5, 5, 5, 7], V: [5, 5, 5, 5, 2], W: [5, 5, 7, 7, 5], X: [5, 5, 2, 5, 5], Y: [5, 5, 2, 2, 2], Z: [7, 1, 2, 4, 7],
	0: [7, 5, 5, 5, 7], 1: [2, 6, 2, 2, 7], 2: [6, 1, 2, 4, 7], 3: [6, 1, 2, 1, 6], 4: [5, 5, 7, 1, 1], 5: [7, 4, 6, 1, 6], 6: [3, 4, 7, 5, 7], 7: [7, 1, 2, 2, 2], 8: [7, 5, 7, 5, 7], 9: [7, 5, 7, 1, 6],
	' ': [0, 0, 0, 0, 0], '.': [0, 0, 0, 0, 2], ',': [0, 0, 0, 2, 4], '!': [2, 2, 2, 0, 2], '?': [6, 1, 2, 0, 2], ':': [0, 2, 0, 2, 0], '-': [0, 0, 7, 0, 0], '+': [0, 2, 7, 2, 0], '/': [1, 1, 2, 4, 4], '\'': [2, 2, 0, 0, 0], '’': [2, 2, 0, 0, 0], '′': [2, 2, 0, 0, 0], '"': [5, 5, 0, 0, 0], '“': [5, 5, 0, 0, 0], '”': [5, 5, 0, 0, 0], '(': [1, 2, 2, 2, 1], ')': [4, 2, 2, 2, 4], '×': [0, 5, 2, 5, 0], '°': [2, 5, 2, 0, 0], '%': [5, 1, 2, 4, 5], '<': [1, 2, 4, 2, 1], '>': [4, 2, 1, 2, 4], '=': [0, 7, 0, 7, 0], '♥': [0, 5, 7, 7, 2], '*': [0, 5, 2, 5, 0], '#': [5, 7, 5, 7, 5], '_': [0, 0, 0, 0, 7], '…': [0, 0, 0, 0, 5], '▶': [4, 6, 7, 6, 4], '■': [0, 7, 7, 7, 0], '★': [2, 7, 2, 5, 0],
	Æ: [3, 6, 7, 6, 7], Ø: [3, 5, 7, 5, 6], Å: [2, 0, 2, 5, 7], Ä: [5, 2, 5, 7, 5], Ö: [5, 2, 5, 5, 2], Ü: [5, 0, 5, 5, 7], É: [1, 2, 7, 6, 7],
};

// The width of a text in the pixel font, in pixels.
export const pixelTextWidth = (text, scale = 1) => (([...String(text)].length * 4) - 1) * scale;

// Draws text in the pixel font, at a whole pixel, with a scale for bigger letters. The alignment is `left`, `center`, or `right`. A shadow is the text in the color of the shadow, drawn first, and moved right and down by the offset of the shadow, which is the scale when the toy does not give it. A toy with its own font, made from `pixelFont`, gives it as `font`.
export const drawPixelText = (context, text, x, y, color, {scale = 1, align = 'left', shadow, shadowOffset = scale, font = pixelFont} = {}) => {
	const characters = [...String(text).toUpperCase()];
	const width = ((characters.length * 4) - 1) * scale;
	const start = Math.round(align === 'center' ? x - (width / 2) : (align === 'right' ? x - width : x));

	for (const [fill, offset] of shadow ? [[shadow, shadowOffset], [color, 0]] : [[color, 0]]) {
		context.fillStyle = fill;
		let left = start;

		for (const character of characters) {
			const rows = font[character] ?? font['?'];
			for (const [row, bits] of rows.entries()) {
				for (let column = 0; column < 3; column++) {
					if (bits & (4 >> column)) {
						context.fillRect(left + (column * scale) + offset, Math.round(y) + (row * scale) + offset, scale, scale);
					}
				}
			}

			left += 4 * scale;
		}
	}
};
