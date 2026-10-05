// My camera cartridge and the little printer on the 1999 page. The screen of the game console is a canvas of 160 × 144 pixels in 4 shades, and everything on it is drawn into a buffer of shades first, so it is always the 4 shades of the palette. The camera looks at drawn scenes, or at the webcam after the visitor asks for it, and makes photos of 128 × 112 pixels with ordered dithering. The album, the stickers, the song, and the best time are kept in the browser. The loop runs only while the window of the game console is on the screen and the tab is visible. Nothing makes a sound until the visitor turns on the sound or plays the song.
const clamp = (value, minimum, maximum) => Math.min(Math.max(value, minimum), maximum);
const randomItem = items => items[Math.floor(Math.random() * items.length)];

// Shows a toggle button as pressed, for screen readers and for the style.
const setPressed = (button, isPressed) => {
	button.setAttribute('aria-pressed', String(isPressed));
	button.dataset.state = isPressed ? 'on' : '';
};

// The position of a pointer on a canvas, in the pixels of the canvas.
const canvasPoint = (canvas, event) => {
	const rectangle = canvas.getBoundingClientRect();
	return {
		x: (event.clientX - rectangle.left) * canvas.width / rectangle.width,
		y: (event.clientY - rectangle.top) * canvas.height / rectangle.height,
	};
};

// A random number generator with a seed, so the same sheet of paper always has the same streaks.
const seededRandom = seed => {
	let value = seed | 0;
	return () => {
		value = (value + 0x6D_2B_79_F5) | 0;
		let mixed = Math.imul(value ^ (value >>> 15), 1 | value);
		mixed = (mixed + Math.imul(mixed ^ (mixed >>> 7), 61 | mixed)) ^ mixed;
		return ((mixed ^ (mixed >>> 14)) >>> 0) / 4_294_967_296;
	};
};

// The screen of the game console, and the photo in the middle of it, like on the real camera.
const width = 160;
const height = 144;
const photoWidth = 128;
const photoHeight = 112;
const photoX = 16;
const photoY = 16;
const albumSize = 30;
const stickerLimit = 12;
const rollSize = 10;

// The palettes. The first is the green-gray of the first handhelds, and the rest are the ones that a color handheld gives an old game when you hold buttons while the logo comes down.
const palettes = [
	{name: 'Classic Green', colors: ['#c4cfa1', '#8b956d', '#4d533c', '#1f1f1f'], note: 'Classic Green, the 4 shades of the camera.'},
	{name: 'Pea Soup', colors: ['#9bbc0f', '#8bac0f', '#306230', '#0f380f'], note: 'Pea Soup, the green of the old handhelds of 1989.'},
	{name: 'Brown', colors: ['#ffffff', '#ffad63', '#843100', '#000000'], combo: '▲'},
	{name: 'Red', colors: ['#ffffff', '#ff8484', '#943a3a', '#000000'], combo: '▲ and A'},
	{name: 'Dark Brown', colors: ['#ffe6c5', '#ce9c84', '#846b29', '#5a3108'], combo: '▲ and B'},
	{name: 'Blue', colors: ['#ffffff', '#65a49b', '#0000fe', '#000000'], combo: '◀'},
	{name: 'Dark Blue', colors: ['#ffffff', '#8b8cde', '#53528c', '#000000'], combo: '◀ and A'},
	{name: 'Gray', colors: ['#ffffff', '#a5a5a5', '#525252', '#000000'], combo: '◀ and B'},
	{name: 'Pastel', colors: ['#ffffa5', '#fe9494', '#9494fe', '#000000'], combo: '▼'},
	{name: 'Orange', colors: ['#ffffff', '#ffff00', '#fe0000', '#000000'], combo: '▼ and A'},
	{name: 'Yellow', colors: ['#ffffff', '#ffff00', '#7d4900', '#000000'], combo: '▼ and B'},
	{name: 'Green', colors: ['#ffffff', '#52ff00', '#ff4200', '#000000'], combo: '▶'},
	{name: 'Dark Green', colors: ['#ffffff', '#7bff31', '#0063c5', '#000000'], combo: '▶ and A'},
	{name: 'Inverted', colors: ['#000000', '#008486', '#ffde00', '#ffffff'], combo: '▶ and B'},
].map(palette => ({...palette, rgb: palette.colors.map(color => [1, 3, 5].map(index => Number.parseInt(color.slice(index, index + 2), 16)))}));

// A tiny pixel font of 3 × 5, like on the screens of the other toys. Each letter is five rows of three bits.
const pixelFont = {
	A: [2, 5, 7, 5, 5], B: [6, 5, 6, 5, 6], C: [3, 4, 4, 4, 3], D: [6, 5, 5, 5, 6], E: [7, 4, 6, 4, 7], F: [7, 4, 6, 4, 4], G: [3, 4, 5, 5, 3], H: [5, 5, 7, 5, 5], I: [7, 2, 2, 2, 7], J: [1, 1, 1, 5, 2], K: [5, 5, 6, 5, 5], L: [4, 4, 4, 4, 7], M: [5, 7, 7, 5, 5], N: [6, 5, 5, 5, 5], O: [2, 5, 5, 5, 2], P: [6, 5, 6, 4, 4], Q: [2, 5, 5, 6, 3], R: [6, 5, 6, 5, 5], S: [3, 4, 2, 1, 6], T: [7, 2, 2, 2, 2], U: [5, 5, 5, 5, 7], V: [5, 5, 5, 5, 2], W: [5, 5, 7, 7, 5], X: [5, 5, 2, 5, 5], Y: [5, 5, 2, 2, 2], Z: [7, 1, 2, 4, 7],
	0: [7, 5, 5, 5, 7], 1: [2, 6, 2, 2, 7], 2: [6, 1, 2, 4, 7], 3: [6, 1, 2, 1, 6], 4: [5, 5, 7, 1, 1], 5: [7, 4, 6, 1, 6], 6: [3, 4, 7, 5, 7], 7: [7, 1, 2, 2, 2], 8: [7, 5, 7, 5, 7], 9: [7, 5, 7, 1, 6],
	' ': [0, 0, 0, 0, 0], '.': [0, 0, 0, 0, 2], ',': [0, 0, 0, 2, 4], '!': [2, 2, 2, 0, 2], '?': [6, 1, 2, 0, 2], ':': [0, 2, 0, 2, 0], '-': [0, 0, 7, 0, 0], '+': [0, 2, 7, 2, 0], '/': [1, 1, 2, 4, 4], '\'': [2, 2, 0, 0, 0], '(': [1, 2, 2, 2, 1], ')': [4, 2, 2, 2, 4], '×': [0, 5, 2, 5, 0], '%': [5, 1, 2, 4, 5], '<': [1, 2, 4, 2, 1], '>': [4, 2, 1, 2, 4], '=': [0, 7, 0, 7, 0], '♥': [0, 5, 7, 7, 2], '*': [0, 5, 2, 5, 0], '▶': [4, 6, 7, 6, 4], '■': [0, 7, 7, 7, 0],
	Æ: [3, 6, 7, 6, 7], Ø: [3, 5, 7, 5, 6], Å: [2, 0, 2, 5, 7],
};

const textWidth = (text, scale = 1) => ((([...text].length * 4) - 1) * scale);

/*
A picture in the 4 shades: 0 is the lightest and 3 the darkest. Everything on the screen, the photos, and the prints is drawn into one, so the colors come from the palette only at the end.
*/
class Surface {
	constructor(surfaceWidth, surfaceHeight, pixels) {
		this.width = surfaceWidth;
		this.height = surfaceHeight;
		this.pixels = pixels ?? new Uint8Array(surfaceWidth * surfaceHeight);
	}

	clear(shade) {
		this.pixels.fill(shade);
	}

	set(x, y, shade) {
		if (x >= 0 && y >= 0 && x < this.width && y < this.height) {
			this.pixels[(y * this.width) + x] = shade;
		}
	}

	get(x, y) {
		return this.pixels[(y * this.width) + x];
	}

	fill(x, y, rectangleWidth, rectangleHeight, shade) {
		const left = Math.max(Math.round(x), 0);
		const top = Math.max(Math.round(y), 0);
		const right = Math.min(Math.round(x + rectangleWidth), this.width);
		const bottom = Math.min(Math.round(y + rectangleHeight), this.height);
		for (let row = top; row < bottom; row++) {
			this.pixels.fill(shade, (row * this.width) + left, (row * this.width) + Math.max(right, left));
		}
	}

	outline(x, y, rectangleWidth, rectangleHeight, shade) {
		this.fill(x, y, rectangleWidth, 1, shade);
		this.fill(x, y + rectangleHeight - 1, rectangleWidth, 1, shade);
		this.fill(x, y, 1, rectangleHeight, shade);
		this.fill(x + rectangleWidth - 1, y, 1, rectangleHeight, shade);
	}

	// A box with an edge, like the message boxes of the camera.
	box(x, y, rectangleWidth, rectangleHeight) {
		this.fill(x, y, rectangleWidth, rectangleHeight, 0);
		this.outline(x, y, rectangleWidth, rectangleHeight, 3);
		this.outline(x + 1, y + 1, rectangleWidth - 2, rectangleHeight - 2, 1);
	}

	line(fromX, fromY, toX, toY, shade) {
		let x = Math.round(fromX);
		let y = Math.round(fromY);
		const endX = Math.round(toX);
		const endY = Math.round(toY);
		const distanceX = Math.abs(endX - x);
		const distanceY = -Math.abs(endY - y);
		const stepX = x < endX ? 1 : -1;
		const stepY = y < endY ? 1 : -1;
		let error = distanceX + distanceY;
		for (;;) {
			this.set(x, y, shade);
			if (x === endX && y === endY) {
				break;
			}

			const doubled = 2 * error;
			if (doubled >= distanceY) {
				error += distanceY;
				x += stepX;
			}

			if (doubled <= distanceX) {
				error += distanceX;
				y += stepY;
			}
		}
	}

	disc(centerX, centerY, radius, shade) {
		for (let y = -radius; y <= radius; y++) {
			for (let x = -radius; x <= radius; x++) {
				if ((x * x) + (y * y) <= (radius * radius) + radius) {
					this.set(Math.round(centerX + x), Math.round(centerY + y), shade);
				}
			}
		}
	}

	text(text, x, y, shade, scale = 1) {
		let left = Math.round(x);
		for (const character of String(text).toUpperCase()) {
			const rows = pixelFont[character] ?? pixelFont['?'];
			for (const [row, bits] of rows.entries()) {
				for (let column = 0; column < 3; column++) {
					if (bits & (4 >> column)) {
						this.fill(left + (column * scale), Math.round(y) + (row * scale), scale, scale, shade);
					}
				}
			}

			left += 4 * scale;
		}
	}

	centeredText(text, y, shade, scale = 1) {
		this.text(text, Math.round((this.width - textWidth(String(text), scale)) / 2), y, shade, scale);
	}

	// Copies a picture of shades, where 4 is see-through.
	blit(pixels, pictureWidth, pictureHeight, x, y) {
		for (let row = 0; row < pictureHeight; row++) {
			for (let column = 0; column < pictureWidth; column++) {
				const shade = pixels[(row * pictureWidth) + column];
				if (shade < 4) {
					this.set(x + column, y + row, shade);
				}
			}
		}
	}

	// Draws a stamp of rows of text, where `.` is see-through, with a light edge around it, so it shows on dark photos too. Only the pixels inside `clip` change.
	sprite(rows, x, y, clip = {left: 0, top: 0, right: this.width, bottom: this.height}) {
		const left = Math.round(x);
		const top = Math.round(y);
		const isInside = (column, row) => column >= clip.left && row >= clip.top && column < clip.right && row < clip.bottom;
		const isSolid = (column, row) => rows[row]?.[column] !== undefined && rows[row][column] !== '.';
		for (let row = -1; row <= rows.length; row++) {
			for (let column = -1; column <= rows[0].length; column++) {
				if (!isSolid(column, row) && (isSolid(column - 1, row) || isSolid(column + 1, row) || isSolid(column, row - 1) || isSolid(column, row + 1)) && isInside(left + column, top + row)) {
					this.set(left + column, top + row, 0);
				}
			}
		}

		for (const [row, line] of rows.entries()) {
			for (const [column, character] of [...line].entries()) {
				if (character !== '.' && isInside(left + column, top + row)) {
					this.set(left + column, top + row, Number(character));
				}
			}
		}
	}
}

// A photo is kept as 2 bits for each pixel, as text, so 30 of them fit in the browser.
const encodePhoto = shades => {
	let binary = '';
	for (let index = 0; index < shades.length; index += 4) {
		binary += String.fromCodePoint(shades[index] | (shades[index + 1] << 2) | (shades[index + 2] << 4) | (shades[index + 3] << 6));
	}

	return btoa(binary);
};

const decodePhoto = text => {
	const shades = new Uint8Array(photoWidth * photoHeight);
	try {
		const binary = atob(text);
		for (let index = 0; index < binary.length && (index * 4) < shades.length; index++) {
			const byte = binary.codePointAt(index);
			shades[index * 4] = byte & 3;
			shades[(index * 4) + 1] = (byte >> 2) & 3;
			shades[(index * 4) + 2] = (byte >> 4) & 3;
			shades[(index * 4) + 3] = (byte >> 6) & 3;
		}
	} catch {}

	return shades;
};

// The frames around a photo, drawn in the border of 16 pixels, like the frames of the real camera.
const frames = [
	{
		name: 'Plain',
		draw(target) {
			target.clear(1);
			target.outline(photoX - 2, photoY - 2, photoWidth + 4, photoHeight + 4, 3);
			target.outline(photoX - 4, photoY - 4, photoWidth + 8, photoHeight + 8, 2);
		},
	},
	{
		name: 'Film',
		draw(target, number) {
			target.clear(3);
			for (let x = 3; x < width; x += 12) {
				target.fill(x, 4, 6, 6, 0);
				target.fill(x, height - 10, 6, 6, 0);
			}

			target.text(`${String(number).padStart(2, '0')}A`, 4, 132 - 3, 1);
			target.text('SINDRE 400', width - 4 - textWidth('SINDRE 400'), 11, 1);
		},
	},
	{
		name: 'Hearts',
		draw(target) {
			target.clear(0);
			for (let row = 0; row * 14 < height; row++) {
				for (let x = (row % 2) * 8; x < width; x += 16) {
					target.text('♥', x + 2, (row * 14) + 3, 2);
				}
			}

			target.outline(photoX - 1, photoY - 1, photoWidth + 2, photoHeight + 2, 3);
		},
	},
	{
		name: 'Stars',
		draw(target) {
			target.clear(3);
			const random = seededRandom(1999);
			for (let index = 0; index < 70; index++) {
				const x = Math.floor(random() * width);
				const y = Math.floor(random() * height);
				if (random() < 0.3) {
					target.text('*', x, y, 0);
				} else {
					target.set(x, y, random() < 0.5 ? 0 : 1);
				}
			}

			target.outline(photoX - 1, photoY - 1, photoWidth + 2, photoHeight + 2, 1);
		},
	},
	{
		name: 'Bricks',
		draw(target) {
			target.clear(1);
			for (let y = 0; y < height; y += 6) {
				target.fill(0, y, width, 1, 3);
				const offset = (y / 6) % 2 === 0 ? 0 : 6;
				for (let x = offset; x < width; x += 12) {
					target.fill(x, y, 1, 6, 3);
				}

				for (let x = offset + 2; x < width; x += 12) {
					target.fill(x, y + 2, 8, 1, 2);
				}
			}

			target.outline(photoX - 1, photoY - 1, photoWidth + 2, photoHeight + 2, 3);
		},
	},
	{
		name: 'Rain in Bergen',
		draw(target) {
			target.clear(1);
			for (let x = -height; x < width; x += 7) {
				target.line(x, 0, x + 12, 24, 2);
				target.line(x + 40, 100, x + 60, 144, 2);
			}

			for (const [x, radius] of [[12, 9], [28, 11], [46, 8], [70, 10], [92, 9], [114, 11], [136, 9], [152, 8]]) {
				target.disc(x, 4, radius, 0);
			}

			target.fill(0, photoY + photoHeight + 1, width, height, 1);
			target.centeredText('BERGEN 1999', 133, 3);
			target.outline(photoX - 1, photoY - 1, photoWidth + 2, photoHeight + 2, 3);
		},
	},
	{
		name: 'Checkers',
		draw(target) {
			for (let y = 0; y < height; y += 8) {
				for (let x = 0; x < width; x += 8) {
					target.fill(x, y, 8, 8, ((x + y) / 8) % 2 === 0 ? 0 : 2);
				}
			}

			target.outline(photoX - 1, photoY - 1, photoWidth + 2, photoHeight + 2, 3);
		},
	},
	{
		name: 'Postcard',
		draw(target) {
			target.clear(0);
			for (let x = 3; x < width - 3; x += 4) {
				target.fill(x, 3, 2, 1, 2);
				target.fill(x, height - 4, 2, 1, 2);
			}

			for (let y = 3; y < height - 3; y += 4) {
				target.fill(3, y, 1, 2, 2);
				target.fill(width - 4, y, 1, 2, 2);
			}

			target.centeredText('HILSEN FRA BERGEN!', 7, 3);
			target.centeredText('PS: DET REGNER.', 132, 2);
			target.outline(photoX - 1, photoY - 1, photoWidth + 2, photoHeight + 2, 3);
		},
	},
	{
		name: 'Wanted',
		draw(target) {
			target.clear(1);
			for (let y = 0; y < height; y += 3) {
				target.fill(0, y, width, 1, y % 9 === 0 ? 2 : 1);
			}

			target.centeredText('WANTED', 3, 3, 2);
			target.centeredText('100 KR REWARD', 133, 3);
			for (const [x, y] of [[5, 5], [width - 6, 5], [5, height - 6], [width - 6, height - 6]]) {
				target.disc(x, y, 1, 3);
			}

			target.outline(photoX - 1, photoY - 1, photoWidth + 2, photoHeight + 2, 3);
		},
	},
];

// A photo in its frame, at the size of the screen and of a print.
const compose = (photo, number = 1) => {
	const target = new Surface(width, height);
	frames[photo.frame].draw(target, number);
	target.blit(photo.shades, photoWidth, photoHeight, photoX, photoY);
	return target;
};

// The stamps, as rows of shades, where `.` is see-through.
const makeBubble = () => {
	const bubbleWidth = 23;
	const grid = Array.from({length: 13}, () => Array.from({length: bubbleWidth}, () => '.'));
	for (let row = 0; row < 9; row++) {
		for (let column = 0; column < bubbleWidth; column++) {
			const isCorner = (row === 0 || row === 8) && (column === 0 || column === bubbleWidth - 1);
			if (!isCorner) {
				grid[row][column] = row === 0 || row === 8 || column === 0 || column === bubbleWidth - 1 ? '3' : '0';
			}
		}
	}

	for (const [row, columns] of [[9, [3, 4, 5]], [10, [3, 4]], [11, [3]]]) {
		for (const column of columns) {
			grid[row][column] = column === columns.at(-1) || row === 11 ? '3' : '0';
		}
	}

	grid[9][3] = '3';
	let left = 4;
	for (const character of 'HEI!') {
		for (const [row, bits] of pixelFont[character].entries()) {
			for (let column = 0; column < 3; column++) {
				if (bits & (4 >> column)) {
					grid[row + 2][left + column] = '3';
				}
			}
		}

		left += 4;
	}

	return grid.map(row => row.join(''));
};

const stamps = {
	hat: {
		name: 'hat',
		rows: [
			'....33333333....',
			'....32222223....',
			'....32222223....',
			'....32222223....',
			'....32222223....',
			'....31111113....',
			'....31111113....',
			'....33333333....',
			'3333333333333333',
			'.33333333333333.',
		],
	},
	mustache: {
		name: 'mustache',
		rows: [
			'3..............3',
			'33...33..33...33',
			'.33333333333333.',
			'..333333333333..',
			'....333..333....',
		],
	},
	glasses: {
		name: 'sunglasses',
		rows: [
			'3333333333333333333333',
			'3303333333..3303333333',
			'.333333333..333333333.',
			'.3333333......3333333.',
			'..33333........33333..',
		],
	},
	heart: {
		name: 'heart',
		rows: [
			'.333.333.',
			'330333333',
			'303333333',
			'333333333',
			'.3333333.',
			'..33333..',
			'...333...',
			'....3....',
		],
	},
	star: {
		name: 'star',
		rows: [
			'.....3.....',
			'....303....',
			'....303....',
			'3333303333.',
			'.300000003.',
			'..3000003..',
			'..3000003..',
			'.300333003.',
			'.3033.3303.',
			'333.....333',
		],
	},
	crown: {
		name: 'crown',
		rows: [
			'3.....3.....3',
			'33...303...33',
			'303.30003.303',
			'3003000003003',
			'3000000000003',
			'3202302032023',
			'3333333333333',
		],
	},
	hei: {
		name: '“HEI!”',
		rows: makeBubble(),
	},
};

// The scenes to photograph without a webcam, drawn in grays on wide canvases that the camera pans over. Each one has the things that move, drawn on top for each frame.
const gray = value => `rgb(${value}, ${value}, ${value})`;

const fillGray = (target, value, x, y, rectangleWidth, rectangleHeight) => {
	target.fillStyle = gray(value);
	target.fillRect(x, y, rectangleWidth, rectangleHeight);
};

const ellipseGray = (target, value, x, y, radiusX, radiusY, rotation = 0) => {
	target.fillStyle = gray(value);
	target.beginPath();
	target.ellipse(x, y, radiusX, radiusY, rotation, 0, Math.PI * 2);
	target.fill();
};

const polygonGray = (target, value, points) => {
	target.fillStyle = gray(value);
	target.beginPath();
	for (const [index, [x, y]] of points.entries()) {
		if (index === 0) {
			target.moveTo(x, y);
		} else {
			target.lineTo(x, y);
		}
	}

	target.closePath();
	target.fill();
};

const gradientGray = (target, x, y, rectangleWidth, rectangleHeight, from, to) => {
	const gradient = target.createLinearGradient(0, y, 0, y + rectangleHeight);
	gradient.addColorStop(0, gray(from));
	gradient.addColorStop(1, gray(to));
	target.fillStyle = gradient;
	target.fillRect(x, y, rectangleWidth, rectangleHeight);
};

const textGray = (target, value, text, x, y, scale = 1) => {
	target.fillStyle = gray(value);
	let left = x;
	for (const character of text) {
		for (const [row, bits] of (pixelFont[character] ?? pixelFont['?']).entries()) {
			for (let column = 0; column < 3; column++) {
				if (bits & (4 >> column)) {
					target.fillRect(left + (column * scale), y + (row * scale), scale, scale);
				}
			}
		}

		left += 4 * scale;
	}
};

const rain = (target, time, {x, y, rectangleWidth, rectangleHeight, count, value = 245, speed = 110}) => {
	target.save();
	target.beginPath();
	target.rect(x, y, rectangleWidth, rectangleHeight);
	target.clip();
	target.strokeStyle = gray(value);
	target.lineWidth = 1;
	target.beginPath();
	for (let index = 0; index < count; index++) {
		const dropX = x + ((index * 37.3) % rectangleWidth);
		const dropY = y + ((((index * 53.7) + (time * speed * (0.8 + ((index % 5) * 0.1)))) % (rectangleHeight + 16)) - 8);
		target.moveTo(dropX, dropY);
		target.lineTo(dropX - 2, dropY + 6);
	}

	target.stroke();
	target.restore();
};

const scenes = {
	room: {
		width: 320,
		caption: [
			'Click! My room. Mamma says it looks better in 4 shades of green than in real life.',
			'Click! My room, with the rain in the window. It is always raining in the window.',
		],
		draw(target) {
			gradientGray(target, 0, 0, 320, 84, 214, 172);
			target.globalAlpha = 0.18;
			for (let x = 0; x < 320; x += 16) {
				fillGray(target, 255, x, 0, 6, 84);
			}

			target.globalAlpha = 1;
			gradientGray(target, 0, 84, 320, 28, 132, 80);
			for (const y of [90, 97, 106]) {
				fillGray(target, 92, 0, y, 320, 1);
			}

			fillGray(target, 236, 0, 81, 320, 3);

			// The window, with Fløyen outside, and the curtains.
			fillGray(target, 60, 14, 10, 74, 54);
			gradientGray(target, 18, 14, 66, 46, 236, 196);
			polygonGray(target, 150, [[18, 60], [18, 44], [32, 38], [50, 42], [66, 33], [84, 39], [84, 60]]);
			fillGray(target, 60, 49, 14, 4, 46);
			fillGray(target, 60, 18, 35, 66, 3);
			fillGray(target, 70, 0, 5, 104, 2);
			for (const left of [3, 82]) {
				fillGray(target, 150, left, 6, 16, 62);
				for (let x = left + 3; x < left + 16; x += 4) {
					fillGray(target, 118, x, 6, 1, 62);
				}
			}

			// The radiator under the window.
			fillGray(target, 222, 22, 66, 58, 15);
			for (let x = 24; x < 78; x += 4) {
				fillGray(target, 186, x, 67, 2, 13);
			}

			// The poster of the Spice Girls over the bed.
			fillGray(target, 245, 118, 6, 54, 42);
			fillGray(target, 70, 120, 8, 50, 38);
			for (const [index, x] of [126, 134, 142, 150, 158, 166].slice(0, 5).entries()) {
				ellipseGray(target, [40, 160, 30, 210, 120][index], x + 2, 22, 5, 6);
				ellipseGray(target, 205, x + 2, 24, 3, 4);
				fillGray(target, [200, 150, 230, 110, 180][index], x - 1, 29, 7, 9);
			}

			textGray(target, 240, 'SPICE', 135, 39);

			// My bed, with the striped duvet.
			fillGray(target, 88, 98, 40, 8, 46);
			fillGray(target, 228, 104, 58, 96, 20);
			fillGray(target, 160, 122, 55, 78, 25);
			target.save();
			target.beginPath();
			target.rect(122, 55, 78, 25);
			target.clip();
			for (let x = 110; x < 210; x += 8) {
				polygonGray(target, 132, [[x, 55], [x + 4, 55], [x + 16, 80], [x + 12, 80]]);
			}

			target.restore();
			ellipseGray(target, 244, 116, 58, 12, 6);
			fillGray(target, 70, 104, 78, 4, 8);
			fillGray(target, 70, 194, 78, 4, 8);

			// The desk with my computer, the beige monitor, and the lava lamp.
			fillGray(target, 108, 212, 60, 104, 5);
			fillGray(target, 96, 216, 65, 5, 19);
			fillGray(target, 96, 306, 65, 5, 19);
			fillGray(target, 128, 280, 65, 24, 14);
			fillGray(target, 216, 226, 24, 46, 34);
			fillGray(target, 64, 231, 28, 36, 24);
			fillGray(target, 150, 235, 32, 18, 12);
			fillGray(target, 110, 235, 32, 18, 3);
			fillGray(target, 200, 238, 58, 20, 3);
			fillGray(target, 206, 276, 28, 20, 32);
			for (const y of [33, 39, 45]) {
				fillGray(target, 160, 279, y, 14, 2);
			}

			fillGray(target, 228, 230, 59, 34, 1);
			fillGray(target, 80, 302, 52, 10, 8);
			ellipseGray(target, 230, 307, 42, 4, 11);

			// The glow-in-the-dark stars on the wall.
			for (const [x, y] of [[100, 8], [190, 14], [205, 6], [296, 12], [10, 76]]) {
				textGray(target, 238, '*', x, y);
			}
		},
		animate(target, time) {
			rain(target, time, {x: 18, y: 14, rectangleWidth: 66, rectangleHeight: 46, count: 26});
			for (let index = 0; index < 3; index++) {
				ellipseGray(target, 120, 307 + (Math.sin((time * 0.7) + index) * 1.5), 34 + (((time * 4) + (index * 7)) % 18), 2, 2.5);
			}
		},
	},
	rocky: {
		width: 288,
		start: 96,
		caption: [
			'Click! Rocky did not blink. He never does.',
			'Click! Rocky, my pet rock, on my desk. He is a good model: he sits still.',
		],
		draw(target) {
			gradientGray(target, 0, 0, 288, 40, 206, 180);
			gradientGray(target, 0, 40, 288, 72, 160, 112);
			target.strokeStyle = gray(132);
			for (let y = 46; y < 112; y += 6) {
				target.beginPath();
				for (let x = 0; x <= 288; x += 8) {
					target.lineTo(x, y + (Math.sin((x / 23) + y) * 1.5));
				}

				target.stroke();
			}

			// A cup of pencils.
			fillGray(target, 96, 20, 44, 26, 40);
			fillGray(target, 130, 22, 46, 6, 36);
			for (const [x, top, value] of [[24, 18, 230], [30, 12, 70], [36, 22, 180], [41, 16, 120]]) {
				fillGray(target, value, x, top, 3, 30);
				polygonGray(target, 40, [[x, top], [x + 3, top], [x + 1.5, top - 4]]);
			}

			// Rocky’s bed, a matchbox with cotton.
			fillGray(target, 160, 62, 80, 42, 16);
			fillGray(target, 226, 64, 76, 38, 8);
			ellipseGray(target, 250, 72, 78, 6, 3);
			ellipseGray(target, 250, 86, 77, 7, 3);

			// Rocky.
			ellipseGray(target, 82, 158, 96, 40, 7);
			const shine = target.createRadialGradient(146, 56, 4, 156, 70, 40);
			shine.addColorStop(0, gray(200));
			shine.addColorStop(0.6, gray(140));
			shine.addColorStop(1, gray(70));
			target.fillStyle = shine;
			target.beginPath();
			target.moveTo(120, 88);
			target.bezierCurveTo(112, 62, 132, 40, 158, 42);
			target.bezierCurveTo(186, 42, 200, 64, 196, 88);
			target.bezierCurveTo(186, 98, 130, 98, 120, 88);
			target.fill();
			const random = seededRandom(42);
			for (let index = 0; index < 60; index++) {
				fillGray(target, random() < 0.5 ? 110 : 175, 126 + (random() * 64), 50 + (random() * 40), 1, 1);
			}

			// The name card.
			polygonGray(target, 236, [[204, 92], [212, 74], [244, 74], [236, 92]]);
			fillGray(target, 214, 204, 92, 32, 3);
			textGray(target, 50, 'ROCKY', 213, 79);

			// A can of Solo.
			gradientGray(target, 252, 36, 24, 56, 222, 150);
			fillGray(target, 118, 252, 52, 24, 18);
			textGray(target, 236, 'SOLO', 256, 58);
			ellipseGray(target, 196, 264, 36, 12, 3);
		},
		animate(target, time) {
			for (const [x, y] of [[146, 62], [170, 60]]) {
				ellipseGray(target, 250, x, y, 9, 9);
				target.strokeStyle = gray(40);
				target.stroke();
				ellipseGray(target, 20, x + (Math.sin(time * 5.3) * 3), y + 2 + (Math.cos(time * 6.1) * 2.5), 4, 4);
			}
		},
	},
	glitter: {
		width: 256,
		start: 64,
		caption: [
			'Click! Glitter on the monitor. The black stripe is because you film a screen.',
			'Click! A photo of Glitter, my virtual unicorn. She is the first unicorn on a handheld game console.',
		],
		draw(target) {
			gradientGray(target, 0, 0, 256, 92, 180, 160);
			fillGray(target, 108, 0, 92, 256, 20);
			fillGray(target, 212, 44, 2, 168, 92);
			fillGray(target, 180, 44, 90, 168, 4);
			fillGray(target, 30, 58, 10, 140, 74);

			// The rainbow and the stars on the screen.
			for (const [index, value] of [236, 190, 140, 96].entries()) {
				target.strokeStyle = gray(value);
				target.lineWidth = 3;
				target.beginPath();
				target.arc(128, 84, 58 - (index * 3), Math.PI, Math.PI * 2);
				target.stroke();
			}

			target.lineWidth = 1;
			const random = seededRandom(7);
			for (let index = 0; index < 40; index++) {
				fillGray(target, 200, 60 + (random() * 136), 12 + (random() * 30), 1, 1);
			}

			// Glitter the unicorn.
			ellipseGray(target, 246, 124, 58, 22, 11);
			ellipseGray(target, 246, 148, 44, 9, 8, -0.4);
			polygonGray(target, 252, [[150, 38], [156, 37], [160, 18]]);
			for (const x of [108, 116, 130, 138]) {
				fillGray(target, 240, x, 64, 4, 16);
			}

			ellipseGray(target, 150, 140, 40, 4, 10, 0.6);
			ellipseGray(target, 120, 134, 46, 3, 8, 0.5);
			ellipseGray(target, 150, 101, 56, 4, 11, -0.6);
			ellipseGray(target, 20, 150, 42, 1.5, 1.5);
			textGray(target, 236, 'GLITTER ♥♥♥', 64, 14);

			// The stand and the keyboard.
			fillGray(target, 196, 104, 94, 48, 8);
			fillGray(target, 226, 62, 102, 132, 9);
			for (let x = 66; x < 190; x += 6) {
				fillGray(target, 178, x, 104, 4, 2);
				fillGray(target, 178, x + 2, 107, 4, 2);
			}

			ellipseGray(target, 220, 214, 106, 7, 4);
		},
		animate(target, time) {
			// The dark stripe that rolls down a filmed screen, as the camera and the screen do not draw at the same time.
			target.fillStyle = 'rgba(0, 0, 0, 0.45)';
			target.fillRect(58, 10 + ((time * 26) % 74), 140, 9);
			for (const [index, [x, y]] of [[72, 30], [180, 24], [168, 60], [86, 52]].entries()) {
				if (Math.sin((time * 4) + (index * 2)) > 0.3) {
					textGray(target, 250, '*', x, y);
				}
			}
		},
	},
	bryggen: {
		width: 352,
		caption: [
			'Click! Bryggen in the rain. Like every postcard of Bergen, but in 4 shades of green.',
			'Click! Bryggen. The tourists from the boats take this photo too, but with color.',
		],
		draw(target) {
			gradientGray(target, 0, 0, 352, 70, 150, 205);
			for (const [x, y, radius] of [[30, 6, 22], [80, 2, 26], [150, 8, 20], [210, 0, 28], [280, 6, 24], [336, 2, 22]]) {
				ellipseGray(target, 128, x, y, radius * 1.4, radius * 0.6);
			}

			// Fløyen, with the line of the funicular.
			polygonGray(target, 112, [[0, 60], [0, 40], [60, 30], [120, 20], [190, 16], [250, 26], [352, 34], [352, 60]]);
			target.strokeStyle = gray(80);
			target.beginPath();
			target.moveTo(120, 60);
			target.lineTo(200, 18);
			target.stroke();
			const random = seededRandom(1070);
			for (let index = 0; index < 140; index++) {
				fillGray(target, 92, random() * 352, 26 + (random() * 34), 2, 2);
			}

			// The old wooden houses, with their pointed gables and the doors for the hoists.
			const houses = [[12, 34, 92, 30], [46, 30, 214, 38], [76, 36, 132, 28], [112, 32, 196, 34], [144, 38, 100, 26], [182, 30, 228, 36], [212, 36, 120, 30], [248, 32, 184, 34], [280, 34, 96, 28], [314, 30, 206, 36]];
			for (const [x, houseWidth, value, gable] of houses) {
				const wallTop = 84 - gable;
				fillGray(target, value, x, wallTop, houseWidth, gable);
				polygonGray(target, value, [[x - 1, wallTop], [x + (houseWidth / 2), wallTop - 18], [x + houseWidth + 1, wallTop]]);
				target.strokeStyle = gray(Math.max(value - 30, 30));
				target.beginPath();
				target.moveTo(x - 2, wallTop + 1);
				target.lineTo(x + (houseWidth / 2), wallTop - 19);
				target.lineTo(x + houseWidth + 2, wallTop + 1);
				target.stroke();
				for (let plank = x + 3; plank < x + houseWidth; plank += 4) {
					fillGray(target, value - 14, plank, wallTop, 1, gable);
				}

				for (let row = 0; row < 2; row++) {
					for (let column = 0; column < 3; column++) {
						const windowX = x + 4 + (column * ((houseWidth - 12) / 2.2));
						fillGray(target, 250, windowX, wallTop + 4 + (row * 11), 6, 7);
						fillGray(target, 54, windowX + 1, wallTop + 5 + (row * 11), 4, 5);
					}
				}

				fillGray(target, 60, x + (houseWidth / 2) - 3, wallTop - 10, 6, 8);
				fillGray(target, 40, x + (houseWidth / 2) - 4, 74, 8, 10);
			}

			// The quay and the harbor.
			fillGray(target, 70, 0, 84, 352, 6);
			for (let x = 4; x < 352; x += 22) {
				fillGray(target, 50, x, 84, 3, 12);
			}

			gradientGray(target, 0, 90, 352, 22, 118, 76);

			// Me with an umbrella, and a seagull on a post.
			ellipseGray(target, 40, 232, 72, 9, 4);
			fillGray(target, 40, 231, 72, 1, 8);
			fillGray(target, 90, 228, 76, 6, 8);
			ellipseGray(target, 236, 72, 80, 4, 2.5);
			fillGray(target, 236, 75, 77, 2, 2);
			fillGray(target, 40, 76, 77, 1, 1);
		},
		animate(target, time) {
			target.globalAlpha = 0.5;
			for (let index = 0; index < 12; index++) {
				const y = 92 + ((index * 7) % 20);
				const x = ((index * 61) + (Math.sin(time + index) * 6)) % 352;
				fillGray(target, 170, x, y, 10, 1);
			}

			target.globalAlpha = 1;
			rain(target, time, {x: 0, y: 0, rectangleWidth: 352, rectangleHeight: 112, count: 120, value: 232, speed: 130});
		},
	},
	me: {
		width: 192,
		caption: [
			'Click! A photo of me, by me. Trond says that is weird. I say it is the future.',
			'Click! Me, with the hair that Mamma cuts with a bowl.',
		],
		draw(target) {
			gradientGray(target, 0, 0, 192, 112, 190, 160);
			fillGray(target, 150, 140, 0, 40, 60);
			fillGray(target, 90, 144, 4, 32, 52);

			// My shirt.
			polygonGray(target, 92, [[40, 112], [52, 96], [140, 96], [152, 112]]);
			textGray(target, 220, '1999', 88, 102);

			// My face, with the ears, the freckles, and the bowl cut.
			ellipseGray(target, 200, 61, 64, 6, 10);
			ellipseGray(target, 200, 131, 64, 6, 10);
			ellipseGray(target, 214, 96, 64, 34, 40);
			ellipseGray(target, 52, 96, 40, 38, 24);
			fillGray(target, 52, 58, 40, 76, 10);
			fillGray(target, 214, 64, 50, 64, 2);
			for (let x = 64; x < 128; x += 5) {
				polygonGray(target, 52, [[x, 48], [x + 5, 48], [x + 2.5, 54]]);
			}

			fillGray(target, 52, 76, 58, 14, 3);
			fillGray(target, 52, 102, 58, 14, 3);
			polygonGray(target, 180, [[96, 66], [92, 80], [100, 80]]);
			const random = seededRandom(3);
			for (let index = 0; index < 16; index++) {
				fillGray(target, 168, 76 + (random() * 14) + (index % 2 === 0 ? 0 : 26), 76 + (random() * 6), 2, 1);
			}

			ellipseGray(target, 50, 96, 88, 18, 9);
			fillGray(target, 214, 76, 79, 40, 8);
			fillGray(target, 250, 82, 87, 32, 3);
			fillGray(target, 50, 95, 87, 2, 3);
		},
		animate(target, time) {
			const isBlinking = (time % 3.7) < 0.15;
			for (const x of [83, 109]) {
				if (isBlinking) {
					fillGray(target, 60, x - 6, 67, 12, 2);
				} else {
					ellipseGray(target, 250, x, 67, 6, 5);
					ellipseGray(target, 30, x + 1, 68, 3, 3);
				}
			}
		},
	},
};

const sceneCanvases = new Map();

const sceneCanvas = id => {
	if (!sceneCanvases.has(id)) {
		const canvas = document.createElement('canvas');
		canvas.width = scenes[id].width;
		canvas.height = photoHeight;
		scenes[id].draw(canvas.getContext('2d'));
		sceneCanvases.set(id, canvas);
	}

	return sceneCanvases.get(id);
};

// What the lens sees, at the size of a photo, before it is dithered.
const lensCanvas = document.createElement('canvas');
lensCanvas.width = photoWidth;
lensCanvas.height = photoHeight;
const lens = lensCanvas.getContext('2d', {willReadFrequently: true});

// The ordered dithering of the camera: a 4 × 4 Bayer matrix of thresholds, so the 4 shades make gradients.
const bayer = [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5].map(value => (value + 0.5) / 16);
const lightness = new Float32Array(photoWidth * photoHeight);
const dithered = new Uint8Array(photoWidth * photoHeight);
const view = new Uint8Array(photoWidth * photoHeight);

const tricks = [
	{id: 'normal', name: 'Normal'},
	{id: 'mirror-left', name: 'Mirror Left'},
	{id: 'mirror-right', name: 'Mirror Right'},
	{id: 'mirror-top', name: 'Mirror Top'},
	{id: 'panorama', name: 'Panorama'},
];

export default class extends GeoCitiesElement {
	#refresh;
	#stopWebcam;
	#stopMusic;

	connected() {
		const {screen, power: powerButton, led, eye, sound: soundButton, colors: colorsButton, webcam: webcamButton, shutter: shutterButton, turnEye: turnEyeButton, trick: trickButton, timer: timerButton, darker: darkerButton, brighter: brighterButton, lessContrast: lessContrastButton, moreContrast: moreContrastButton, panLeft: panLeftButton, panRight: panRightButton, framePrevious: framePreviousButton, frameNext: frameNextButton, printButton, toStamps: toStampsButton, png: pngButton, erase: eraseButton, undo: undoButton, stampsDone: stampsDoneButton, musicPlay: musicPlayButton, slower: slowerButton, faster: fasterButton, demo: demoButton, random: randomButton, clear: clearButton, runStart: runStartButton, runBest, printer, paperHolder, paperClip, print: printCanvas, printerLight, paperLeft: paperLeftDisplay, tear: tearButton, roll: rollButton, wall, wallEmpty, peel: peelButton, stickerTemplate} = this.parts;
		const context = screen.getContext('2d');
		const printContext = printCanvas.getContext('2d');
		const modeButtons = [...this.querySelectorAll('[data-gb-camera-mode]')];
		const panels = [...this.querySelectorAll('[data-gb-camera-panel]')];
		const sceneButtons = [...this.querySelectorAll('[data-gb-camera-scene]')];
		const stampButtons = [...this.querySelectorAll('[data-gb-camera-stamp]')];
		const paperButtons = [...this.querySelectorAll('[data-gb-camera-paper-color]')];
		const slots = [...this.querySelectorAll('[data-gb-camera-slot]')];

		const storedSettings = this.stored('settings', {});
		const settings = {
			palette: clamp(Math.trunc(Number(storedSettings.palette)) || 0, 0, palettes.length - 1),
			brightness: clamp(Math.trunc(Number(storedSettings.brightness)) || 0, -4, 4),
			contrast: clamp(Math.trunc(Number(storedSettings.contrast)) || 0, -3, 4),
			paper: ['white', 'yellow', 'blue'].includes(storedSettings.paper) ? storedSettings.paper : 'white',
			paperLeft: clamp(Number.isFinite(storedSettings.paperLeft) ? Math.trunc(storedSettings.paperLeft) : rollSize, 0, rollSize),
			rolls: Math.max(Math.trunc(Number(storedSettings.rolls)) || 0, 0),
			bestRun: Number.isFinite(storedSettings.bestRun) && storedSettings.bestRun > 0 ? storedSettings.bestRun : undefined,
			runWins: clamp(Math.trunc(Number(storedSettings.runWins)) || 0, 0, 999),
		};

		const saveSettings = () => {
			this.store('settings', settings);
		};

		const surface = new Surface(width, height);
		const screenImage = context.createImageData(width, height);

		const palette = () => palettes[settings.palette];

		// Paints shades with the palette into an image of the same size.
		const paintShades = (targetContext, pixels, pictureWidth, pictureHeight, image = targetContext.createImageData(pictureWidth, pictureHeight)) => {
			const colors = palette().rgb;
			const {data} = image;
			for (let index = 0; index < pixels.length; index++) {
				const color = colors[pixels[index]];
				data[index * 4] = color[0];
				data[(index * 4) + 1] = color[1];
				data[(index * 4) + 2] = color[2];
				data[(index * 4) + 3] = 255;
			}

			targetContext.putImageData(image, 0, 0);
		};

		const state = {
			isOn: false,
			mode: 'off',
			modeTime: 0,
			time: 0,
			menuIndex: 0,
			scene: 'room',
			pan: 0,
			panDirection: 1,
			autoPanPause: 0,
			isEyeTurned: false,
			trick: 0,
			panorama: {count: 0, parts: new Uint8Array(photoWidth * photoHeight)},
			timer: undefined,
			flash: 0,
			message: undefined,
			selected: 0,
			stamp: 'hat',
			cursor: {x: 64, y: 40},
			undo: [],
			isDingPlayed: false,
			drag: undefined,
			infoTime: 0,
		};

		const webcam = {
			stream: undefined,
			video: undefined,
			isAsking: false,
		};

		const storedAlbum = this.stored('album', []);
		const album = (Array.isArray(storedAlbum) ? storedAlbum : [])
			.filter(entry => typeof entry?.data === 'string')
			.slice(0, albumSize)
			.map(entry => ({shades: decodePhoto(entry.data), frame: clamp(Math.trunc(Number(entry.frame)) || 0, 0, frames.length - 1)}));

		state.selected = Math.max(album.length - 1, 0);

		// A toast, as the action that saved says its own text in the status line right after.
		const saveAlbum = () => {
			if (!this.store('album', album.map(photo => ({data: encodePhoto(photo.shades), frame: photo.frame})))) {
				this.toast('The browser has no room to keep the photos, so they are gone when you leave. Like a real game console with dead batteries.');
			}
		};

		// The sound, made in the browser once the visitor asks for it, with the audio of the element, which it only has in the handler of a click.
		const audio = {
			context: undefined,
			output: undefined,
			noise: undefined,
			pulse: undefined,
			isOn: false,
			start(sound) {
				if (!this.context) {
					if (!sound) {
						return false;
					}

					this.context = sound.context;
					this.output = new GainNode(this.context, {gain: 0.5});
					this.output.connect(sound.output);
					const buffer = this.context.createBuffer(1, this.context.sampleRate, this.context.sampleRate);
					const samples = buffer.getChannelData(0);
					for (let index = 0; index < samples.length; index++) {
						samples[index] = (Math.random() * 2) - 1;
					}

					this.noise = buffer;

					// The square wave of the game console with a duty of 25%, the thin sound of its melodies.
					const harmonics = 32;
					const real = new Float32Array(harmonics);
					const imaginary = new Float32Array(harmonics);
					for (let harmonic = 1; harmonic < harmonics; harmonic++) {
						real[harmonic] = (2 / (harmonic * Math.PI)) * Math.sin(2 * Math.PI * harmonic * 0.25);
						imaginary[harmonic] = (2 / (harmonic * Math.PI)) * (1 - Math.cos(2 * Math.PI * harmonic * 0.25));
					}

					this.pulse = this.context.createPeriodicWave(real, imaginary);
				}

				this.context.resume();
				return true;
			},
			get isRunning() {
				return this.isOn && this.context !== undefined;
			},
		};

		const tone = (frequency, start, duration, {type = 'square', volume = 0.06, slide, isPulse = false} = {}) => {
			if (!audio.isRunning) {
				return;
			}

			const time = audio.context.currentTime + Math.max(start, 0);
			const oscillator = new OscillatorNode(audio.context, {type: isPulse ? 'sine' : type, frequency});
			if (isPulse) {
				oscillator.setPeriodicWave(audio.pulse);
			}

			if (slide) {
				oscillator.frequency.setValueAtTime(frequency, time);
				oscillator.frequency.exponentialRampToValueAtTime(slide, time + duration);
			}

			const gain = new GainNode(audio.context, {gain: 0});
			gain.gain.setValueAtTime(0.0001, time);
			gain.gain.exponentialRampToValueAtTime(volume, time + 0.004);
			gain.gain.exponentialRampToValueAtTime(0.0001, time + duration);
			oscillator.connect(gain).connect(audio.output);
			oscillator.start(time);
			oscillator.stop(time + duration + 0.05);
		};

		const noise = (start, duration, {volume = 0.2, frequency = 2000, type = 'bandpass', slide} = {}) => {
			if (!audio.isRunning) {
				return;
			}

			const time = audio.context.currentTime + Math.max(start, 0);
			const source = new AudioBufferSourceNode(audio.context, {buffer: audio.noise});
			const filter = new BiquadFilterNode(audio.context, {type, frequency, Q: 1.2});
			if (slide) {
				filter.frequency.setValueAtTime(frequency, time);
				filter.frequency.exponentialRampToValueAtTime(slide, time + duration);
			}

			const gain = new GainNode(audio.context, {gain: 0});
			gain.gain.setValueAtTime(volume, time);
			gain.gain.exponentialRampToValueAtTime(0.0001, time + duration);
			source.connect(filter).connect(gain).connect(audio.output);
			source.start(time, Math.random() * 0.5);
			source.stop(time + duration + 0.05);
		};

		const sounds = {
			blip: () => tone(1046, 0, 0.04, {volume: 0.04}),
			select() {
				tone(1568, 0, 0.05, {volume: 0.05});
				tone(2093, 0.05, 0.07, {volume: 0.05});
			},
			back: () => tone(523, 0, 0.07, {volume: 0.05}),
			ding() {
				tone(1046.5, 0, 0.08, {volume: 0.07});
				tone(2093, 0.08, 0.6, {volume: 0.07});
			},
			// The shutter: a click, the whir of the camera, and a second click.
			shutter() {
				noise(0, 0.03, {volume: 0.5, frequency: 4000, type: 'highpass'});
				tone(1800, 0, 0.04, {volume: 0.05, slide: 700});
				tone(440, 0.04, 0.06, {volume: 0.03, type: 'sawtooth'});
				noise(0.1, 0.04, {volume: 0.35, frequency: 2600});
			},
			error: () => tone(110, 0, 0.25, {volume: 0.06}),
			stamp: () => tone(240, 0, 0.14, {type: 'triangle', volume: 0.14, slide: 820}),
			tick: () => tone(1568, 0, 0.05, {volume: 0.05}),
			footstep: () => noise(0, 0.035, {volume: 0.18, frequency: 700}),
			stumble: () => tone(300, 0, 0.18, {type: 'triangle', volume: 0.12, slide: 90}),
			// One band of the thermal printer: the motor and the head, buzzing in quick steps.
			buzz() {
				for (let index = 0; index < 11; index++) {
					tone(index % 2 === 0 ? 74 : 82, index * 0.03, 0.026, {type: 'sawtooth', volume: 0.06});
				}

				noise(0, 0.33, {volume: 0.05, frequency: 1400});
			},
			rip: () => noise(0, 0.4, {volume: 0.35, frequency: 3200, slide: 600}),
			peel: () => noise(0, 0.18, {volume: 0.25, frequency: 1800, slide: 4000}),
			win() {
				for (const [index, frequency] of [523, 659, 784, 1047, 784, 1047].entries()) {
					tone(frequency, index * 0.1, 0.16, {volume: 0.07, isPulse: true});
				}
			},
			lose() {
				for (const [index, frequency] of [392, 370, 349, 262].entries()) {
					tone(frequency, index * 0.18, 0.22, {volume: 0.07, isPulse: true});
				}
			},
		};

		const setSound = isOn => {
			audio.isOn = isOn;
			setPressed(soundButton, isOn);
			soundButton.textContent = isOn ? '🔊 Sound On' : '🔈 Sound Off';
		};

		this.on(soundButton, 'click', () => {
			const isOn = soundButton.getAttribute('aria-pressed') !== 'true';
			if (isOn && !audio.start(this.sound())) {
				this.say('This browser has no sound. The game console is quiet, like in class.');
				return;
			}

			setSound(isOn);
			if (isOn) {
				sounds.select();
			} else {
				stopMusic();
			}
		});

		// The music maker: 16 steps of a melody on 8 notes, a bass, and three drums.
		const melodyNotes = [523.25, 587.33, 659.25, 783.99, 880, 1046.5, 1174.66, 1318.51];
		const bassNotes = [130.81, 110, 87.31, 98];
		const drumNames = ['kick', 'snare', 'hat'];

		const demoSong = () => ({
			tempo: 132,
			melody: [4, -1, 2, 4, 5, -1, 4, 2, 3, -1, 1, 3, 4, 2, 0, -1],
			bass: [1, 0, 0, 1, 1, 0, 1, 0, 1, 0, 0, 1, 1, 0, 1, 0],
			kick: [1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1, 0],
			snare: [0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1],
			hat: [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 1, 1, 0],
		});

		const isSong = value => Array.isArray(value?.melody) && value.melody.length === 16 && ['bass', ...drumNames].every(name => Array.isArray(value[name]) && value[name].length === 16);

		const storedSong = this.stored('song', undefined);
		const song = isSong(storedSong) ? {
			tempo: clamp(Number(storedSong.tempo) || 132, 80, 220),
			melody: storedSong.melody.map(note => clamp(Math.round(Number(note)), -1, 7)),
			bass: storedSong.bass.map(Number),
			kick: storedSong.kick.map(Number),
			snare: storedSong.snare.map(Number),
			hat: storedSong.hat.map(Number),
		} : demoSong();

		const saveSong = () => {
			this.store('song', song);
		};

		const music = {
			isPlaying: false,
			step: 0,
			nextTime: 0,
			interval: undefined,
			queue: [],
			cursor: {row: 3, column: 0},
		};

		const stepLength = () => 60 / song.tempo / 4;

		const playStep = (step, time) => {
			const offset = time - audio.context.currentTime;
			const length = stepLength();
			const note = song.melody[step];
			if (note >= 0) {
				tone(melodyNotes[note], offset, length * 0.9, {isPulse: true, volume: 0.06});
			}

			if (song.bass[step]) {
				tone(bassNotes[Math.floor(step / 4)], offset, length * 0.95, {type: 'triangle', volume: 0.18});
			}

			if (song.kick[step]) {
				tone(150, offset, 0.14, {type: 'sine', volume: 0.35, slide: 42});
			}

			if (song.snare[step]) {
				noise(offset, 0.11, {volume: 0.22, frequency: 1800, type: 'highpass'});
			}

			if (song.hat[step]) {
				noise(offset, 0.03, {volume: 0.12, frequency: 7500, type: 'highpass'});
			}
		};

		const stopMusic = () => {
			if (!music.isPlaying) {
				return;
			}

			music.isPlaying = false;
			clearInterval(music.interval);
			music.interval = undefined;
			music.queue = [];
			setPressed(musicPlayButton, false);
			musicPlayButton.textContent = '▶ Play (Sound!)';
			this.music(false);
		};

		const startMusic = () => {
			if (!audio.start(this.sound())) {
				this.say('This browser has no sound, so the music plays only in your head.');
				return;
			}

			setSound(true);
			music.isPlaying = true;
			music.step = 0;
			music.nextTime = audio.context.currentTime + 0.06;
			music.queue = [];
			music.interval = setInterval(() => {
				// A late timer skips the missed steps instead of playing them all at once.
				music.nextTime = Math.max(music.nextTime, audio.context.currentTime + 0.02);
				while (music.nextTime < audio.context.currentTime + 0.12) {
					playStep(music.step, music.nextTime);
					music.queue.push({step: music.step, time: music.nextTime});
					music.nextTime += stepLength();
					music.step = (music.step + 1) % 16;
				}

				music.queue = music.queue.filter(item => item.time > audio.context.currentTime - 1);
			}, 25);
			setPressed(musicPlayButton, true);
			musicPlayButton.textContent = '⏹ Stop';
			this.music(true);
			loop.start();
		};

		// The step that is heard now, for the line that moves over the grid.
		const currentStep = () => {
			if (!music.isPlaying || !audio.context) {
				return -1;
			}

			const now = audio.context.currentTime;
			let step = -1;
			for (const item of music.queue) {
				if (item.time <= now) {
					step = item.step;
				}
			}

			return step;
		};

		const toggleCell = (row, column) => {
			if (row < 8) {
				const note = 7 - row;
				song.melody[column] = song.melody[column] === note ? -1 : note;
				if (song.melody[column] >= 0 && !music.isPlaying) {
					tone(melodyNotes[note], 0, 0.15, {isPulse: true, volume: 0.06});
				}
			} else if (row === 8) {
				song.bass[column] = song.bass[column] ? 0 : 1;
			} else {
				const name = drumNames[row - 9];
				song[name][column] = song[name][column] ? 0 : 1;
			}

			saveSong();
		};

		// The race: 100 meters against Trond.
		const race = {
			phase: 'ready',
			countdown: 0,
			time: 0,
			lastPress: undefined,
			player: {distance: 0, speed: 0, lastButton: undefined, stride: 0},
			rival: {distance: 0, speed: 0, finishTime: undefined},
			stumbleTime: 0,
		};

		const rivalSpeed = () => Math.min(5.8 + (settings.runWins * 0.45), 9.6);

		const formatTime = seconds => seconds === undefined ? '--.--' : seconds.toFixed(2).padStart(5, '0');

		const showRunBest = () => {
			runBest.textContent = `BEST ${formatTime(settings.bestRun)} ★ WINS ${settings.runWins}`;
		};

		const startRace = () => {
			race.phase = this.reducedMotion ? 'running' : 'countdown';
			race.countdown = 3;
			race.time = 0;
			race.lastPress = undefined;
			race.player = {distance: 0, speed: 0, lastButton: undefined, stride: 0};
			race.rival = {distance: 0, speed: rivalSpeed(), finishTime: undefined};
			race.stumbleTime = 0;
			if (race.phase === 'countdown') {
				sounds.tick();
			}

			this.say(this.reducedMotion ? 'Go! Press A and B, one after the other. Trond only moves when you do.' : 'On your marks… 3, 2, 1, and then A and B, one after the other!');
		};

		const finishRace = () => {
			race.phase = 'finished';
			race.finishedAt = performance.now();
			const time = race.time;
			race.hasWon = race.player.distance >= 100 && (race.rival.finishTime === undefined || time < race.rival.finishTime);
			if (race.player.distance >= 100 && (settings.bestRun === undefined || time < settings.bestRun)) {
				settings.bestRun = time;
			}

			if (race.hasWon) {
				settings.runWins++;
				sounds.win();
				this.celebrate();
				this.say(`You beat Trond in ${time.toFixed(2)} seconds! He says the A button on my game console is sticky. Next time, he runs faster.`);
			} else if (race.player.distance >= 100) {
				sounds.lose();
				this.say(`Trond won in ${race.rival.finishTime.toFixed(2)} seconds, and you came in ${time.toFixed(2)}. He says he trains on his own game console every day after school.`);
			} else {
				sounds.lose();
				this.say('Trond won, and you stopped on the way. Press Start to try again!');
			}

			saveSettings();
			showRunBest();
		};

		const stepRace = seconds => {
			if (race.phase === 'countdown') {
				const before = Math.ceil(race.countdown);
				race.countdown -= seconds;
				if (Math.ceil(race.countdown) !== before) {
					if (race.countdown <= 0) {
						race.phase = 'running';
						tone(2093, 0, 0.25, {volume: 0.06});
					} else {
						sounds.tick();
					}
				}

				return;
			}

			if (race.phase !== 'running') {
				return;
			}

			race.time += seconds;
			race.player.speed *= Math.exp(-1.1 * seconds);
			race.player.distance += race.player.speed * seconds;
			race.rival.distance += (race.rival.speed + (Math.sin(race.time * 2.7) * 0.4)) * seconds;
			race.stumbleTime = Math.max(race.stumbleTime - seconds, 0);
			if (race.rival.distance >= 100 && race.rival.finishTime === undefined) {
				race.rival.finishTime = race.time - ((race.rival.distance - 100) / race.rival.speed);
			}

			if (race.player.distance >= 100) {
				race.time -= (race.player.distance - 100) / Math.max(race.player.speed, 0.1);
				race.player.distance = 100;
				finishRace();
			} else if (race.rival.finishTime !== undefined && race.time > race.rival.finishTime + 8) {
				finishRace();
			}
		};

		const runPress = name => {
			if (race.phase !== 'running') {
				return;
			}

			// With reduced motion, the race only goes on when a button is pressed, so it moves forward by the time since the last press.
			if (this.reducedMotion) {
				const now = performance.now();
				const seconds = race.lastPress === undefined ? 0 : Math.min((now - race.lastPress) / 1000, 1);
				race.lastPress = now;
				stepRace(seconds);
				if (race.phase !== 'running') {
					return;
				}
			}

			if (name === race.player.lastButton) {
				race.player.speed *= 0.4;
				race.stumbleTime = 0.5;
				sounds.stumble();
			} else {
				race.player.speed = Math.min(race.player.speed + 1.05, 11);
				race.player.stride++;
				sounds.footstep();
			}

			race.player.lastButton = name;
		};

		// The little printer and its paper.
		const paperColors = {white: [243, 241, 231], yellow: [246, 226, 122], blue: [159, 203, 238]};
		const ink = [36, 36, 48];
		const inkAmounts = [0, 0.3, 0.62, 0.93];
		const printSize = 176;
		const printTop = 16;
		const printLeft = 8;

		let sheet;
		let printJob;

		// Paints a sheet of thermal paper: the photo in its frame in the grays of the ink, with the faint stripes of the print head, and the torn edge at the bottom once it is torn off.
		const renderPrint = (targetContext, printed, isTorn) => {
			const composed = compose({shades: printed.shades, frame: printed.frame}, printed.number);
			const image = targetContext.createImageData(printSize, printSize);
			const paper = paperColors[printed.paper] ?? paperColors.white;
			const random = seededRandom(printed.seed);
			const stripes = Array.from({length: width}, () => 0.88 + (random() * 0.12));
			const tear = Array.from({length: printSize}, (_, x) => 2 + ((x * 7) % 5) + Math.floor(random() * 3));
			for (let y = 0; y < printSize; y++) {
				for (let x = 0; x < printSize; x++) {
					const imageX = x - printLeft;
					const imageY = y - printTop;
					let amount = 0;
					if (imageX >= 0 && imageY >= 0 && imageX < width && imageY < height) {
						amount = inkAmounts[composed.get(imageX, imageY)] * stripes[imageX];
						if (amount > 0 && random() < 0.04) {
							amount *= 0.65;
						}
					}

					const index = ((y * printSize) + x) * 4;
					for (let channel = 0; channel < 3; channel++) {
						image.data[index + channel] = Math.round((paper[channel] * (1 - amount)) + (ink[channel] * amount));
					}

					image.data[index + 3] = isTorn && y >= printSize - tear[x] ? 0 : 255;
				}
			}

			targetContext.putImageData(image, 0, 0);
		};

		const setPaperOut = fraction => {
			paperClip.style.setProperty('--gb-camera-paper', `${(clamp(fraction, 0, 1) * 100).toFixed(2)}%`);
			// On a phone, the room for the paper above the printer is only there while a sheet is in the printer.
			paperHolder.dataset.state = sheet ? 'open' : '';
		};

		const showPaperLeft = () => {
			paperLeftDisplay.textContent = settings.paperLeft === 0 ? 'NO PAPER!' : `PAPER ${'▮'.repeat(settings.paperLeft)}${'▯'.repeat(rollSize - settings.paperLeft)}`;
		};

		// On a phone, the printer is below the buttons of the album and the sound, so it comes into view to show the paper come out, or that it has no paper.
		const showPrinter = () => {
			printer.scrollIntoView({behavior: this.reducedMotion ? 'instant' : 'smooth', block: 'nearest'});
		};

		const startPrint = () => {
			const photo = album[state.selected];
			if (!photo) {
				sounds.error();
				this.say('There is no photo to print. Shoot one first!');
				return;
			}

			if (printJob) {
				this.say('Wait, it is still printing! Bzzzt.');
				return;
			}

			if (settings.paperLeft <= 0) {
				sounds.error();
				state.message = {text: 'NO PAPER!', time: 1.5};
				this.say('Out of paper! The rolls cost a lot of money, so ask Mamma for a new one.');
				showPrinter();
				refresh();
				return;
			}

			const hadSheet = Boolean(sheet);
			if (hadSheet) {
				tearOff(true);
			}

			sheet = {shades: photo.shades.slice(), frame: photo.frame, paper: settings.paper, seed: Math.floor(Math.random() * 1_000_000), number: state.selected + 1};
			renderPrint(printContext, sheet, false);
			settings.paperLeft--;
			saveSettings();
			showPaperLeft();
			printJob = {elapsed: 0, band: -1};
			setPaperOut(0);
			printerLight.dataset.state = 'busy';
			tearButton.disabled = true;
			this.say(`${hadSheet ? 'You tore off the last print first, and it is inside my wardrobe door now. ' : ''}Bzzzt… bzzzt… The little printer prints photo ${state.selected + 1} on ${settings.paper} sticker paper.`);
			showPrinter();
			refresh();
		};

		// The printer prints in 9 bands of 16 lines, with a buzz and a small stop between them, and then feeds the paper out.
		const bandTime = 0.45;
		const bands = height / 16;

		const stepPrint = seconds => {
			if (!printJob) {
				return;
			}

			printJob.elapsed += seconds;
			const band = Math.floor(printJob.elapsed / bandTime);
			if (band !== printJob.band && band < bands) {
				printJob.band = band;
				sounds.buzz();
			}

			const inBand = this.reducedMotion ? 0 : clamp((printJob.elapsed % bandTime) / (bandTime * 0.75), 0, 1);
			const feed = this.reducedMotion ? printSize : (printJob.elapsed - (bands * bandTime)) * 60;
			const rows = band >= bands ? height + feed : (band * 16) + (inBand * 16);
			setPaperOut((printTop + rows) / printSize);
			if (printTop + rows >= printSize) {
				printJob = undefined;
				setPaperOut(1);
				if (state.isOn) {
					printerLight.dataset.state = 'on';
				} else {
					printerLight.dataset.state = '';
				}

				tearButton.disabled = false;
				this.say('Done! Tear it off, and it is a sticker.');
			}
		};

		for (const button of paperButtons) {
			setPressed(button, button.dataset.gbCameraPaperColor === settings.paper);
			this.on(button, 'click', () => {
				settings.paper = button.dataset.gbCameraPaperColor;
				saveSettings();
				for (const other of paperButtons) {
					setPressed(other, other === button);
				}

				this.say(settings.paper === 'white' ? 'White sticker paper, the one that came with the printer. It fades in the sun, so not on the window.' : `The ${settings.paper} sticker paper. Mamma bought it at Elkjøp, and it was not cheap.`);
			});
		}

		const rollMessages = [
			'Mamma: “Igjen? Again? OK, but this is the last roll this month.”',
			'Mamma: “Nei! OK then, one more. Next time, ask Pappa.”',
			'Pappa: “Here you go. Do not tell Mamma.”',
			'Mormor sent a roll in the mail from Ålesund, with 50 kroner and a letter. Takk, Mormor!',
		];

		this.on(rollButton, 'click', () => {
			if (settings.paperLeft === rollSize) {
				this.say('The roll is still full. Mamma says paper does not grow on trees. (It does, Mamma.)');
				return;
			}

			this.say(rollMessages[settings.rolls % rollMessages.length]);
			settings.rolls++;
			settings.paperLeft = rollSize;
			saveSettings();
			showPaperLeft();
			sounds.peel();
		});

		// The stickers inside the wardrobe door.
		const storedStickers = this.stored('stickers', []);
		const stickers = (Array.isArray(storedStickers) ? storedStickers : [])
			.filter(entry => typeof entry?.data === 'string')
			.slice(-stickerLimit)
			.map((entry, index) => ({
				// The number in the label of the sticker, which stays the same while the stickers go on top of each other.
				stickerNumber: clamp(Math.trunc(Number(entry.stickerNumber)) || index + 1, 1, 999),
				shades: decodePhoto(entry.data),
				frame: clamp(Math.trunc(Number(entry.frame)) || 0, 0, frames.length - 1),
				paper: Object.hasOwn(paperColors, entry.paper) ? entry.paper : 'white',
				seed: Number(entry.seed) || 1,
				number: clamp(Math.trunc(Number(entry.number)) || 1, 1, albumSize),
				x: clamp(Number(entry.x) || 50, 5, 95),
				y: clamp(Number(entry.y) || 50, 5, 95),
				tilt: ['left', 'right', ''].includes(entry.tilt) ? entry.tilt : '',
			}));

		let touchedSticker;

		const saveStickers = () => {
			this.store('stickers', stickers.map(sticker => ({stickerNumber: sticker.stickerNumber, data: encodePhoto(sticker.shades), frame: sticker.frame, paper: sticker.paper, seed: sticker.seed, number: sticker.number, x: sticker.x, y: sticker.y, tilt: sticker.tilt})));
		};

		const placeSticker = sticker => {
			sticker.element.style.setProperty('--gb-camera-sticker-x', `${sticker.x.toFixed(2)}%`);
			sticker.element.style.setProperty('--gb-camera-sticker-y', `${sticker.y.toFixed(2)}%`);
		};

		const updateWall = () => {
			wallEmpty.hidden = stickers.length > 0;
			peelButton.disabled = stickers.length === 0;
		};

		const peel = sticker => {
			const index = stickers.indexOf(sticker);
			if (index === -1) {
				return;
			}

			stickers.splice(index, 1);
			sticker.element.remove();
			if (touchedSticker === sticker) {
				touchedSticker = undefined;
			}

			saveStickers();
			updateWall();
			sounds.peel();
		};

		// Puts the sticker on top of the others, as the last one touched.
		const raise = sticker => {
			touchedSticker = sticker;
			const index = stickers.indexOf(sticker);
			if (index !== stickers.length - 1) {
				stickers.splice(index, 1);
				stickers.push(sticker);
				const hadFocus = document.activeElement === sticker.element;
				wall.append(sticker.element);
				if (hadFocus) {
					sticker.element.focus({preventScroll: true});
				}
			}
		};

		const addStickerElement = sticker => {
			const element = stickerTemplate.content.firstElementChild.cloneNode(true);
			sticker.element = element;
			element.dataset.gbCameraSticker = String(sticker.stickerNumber);
			element.setAttribute('aria-label', `Sticker ${sticker.stickerNumber}: photo ${sticker.number} in the frame ${frames[sticker.frame].name}. Drag it, or use the arrow keys. Delete peels it off.`);
			if (sticker.tilt === 'left') {
				element.dataset.state = 'left';
			} else if (sticker.tilt === 'right') {
				element.dataset.state = 'right';
			}

			renderPrint(element.querySelector('canvas').getContext('2d'), sticker, true);
			placeSticker(sticker);
			wall.append(element);

			// The listeners of a sticker go away with the sticker when it is peeled off, so they are not kept until the toy is removed.
			element.addEventListener('pointerdown', event => {
				event.preventDefault();
				raise(sticker);
				element.focus({preventScroll: true});
				element.setPointerCapture(event.pointerId);
				const rectangle = wall.getBoundingClientRect();
				const grab = {
					x: ((event.clientX - rectangle.left) / rectangle.width * 100) - sticker.x,
					y: ((event.clientY - rectangle.top) / rectangle.height * 100) - sticker.y,
				};

				const move = moveEvent => {
					const area = wall.getBoundingClientRect();
					sticker.x = clamp(((moveEvent.clientX - area.left) / area.width * 100) - grab.x, 4, 96);
					sticker.y = clamp(((moveEvent.clientY - area.top) / area.height * 100) - grab.y, 6, 94);
					placeSticker(sticker);
				};

				const drop = () => {
					element.removeEventListener('pointermove', move);
					element.removeEventListener('pointerup', drop);
					element.removeEventListener('pointercancel', drop);
					element.removeEventListener('lostpointercapture', drop);
					saveStickers();
				};

				element.addEventListener('pointermove', move);
				element.addEventListener('pointerup', drop);
				element.addEventListener('pointercancel', drop);
				element.addEventListener('lostpointercapture', drop);
			});

			element.addEventListener('keydown', event => {
				const moves = {ArrowLeft: [-3, 0], ArrowRight: [3, 0], ArrowUp: [0, -4], ArrowDown: [0, 4]};
				if (moves[event.key]) {
					event.preventDefault();
					touchedSticker = sticker;
					sticker.x = clamp(sticker.x + moves[event.key][0], 4, 96);
					sticker.y = clamp(sticker.y + moves[event.key][1], 6, 94);
					placeSticker(sticker);
					saveStickers();
				} else if (event.key === 'Delete' || event.key === 'Backspace') {
					event.preventDefault();
					const index = stickers.indexOf(sticker);
					const next = stickers[index === 0 ? 1 : index - 1];
					peel(sticker);
					next?.element.focus();
					this.say('You peeled it off. It does not stick so well anymore, so it goes in the bin.');
				}
			});

			element.addEventListener('click', event => {
				// A click from a keyboard or a screen reader picks the sticker, like a touch.
				if (event.detail === 0) {
					raise(sticker);
					this.say('Move it with the arrow keys. Delete peels it off.');
				}
			});
		};

		const tearOff = isAutomatic => {
			if (!sheet || printJob) {
				return;
			}

			const tilts = ['left', 'right', ''];
			const sticker = {...sheet, stickerNumber: Math.max(0, ...stickers.map(other => other.stickerNumber)) + 1, x: 15 + (Math.random() * 70), y: 20 + (Math.random() * 60), tilt: randomItem(tilts)};
			sheet = undefined;
			setPaperOut(0);
			printContext.clearRect(0, 0, printSize, printSize);
			tearButton.disabled = true;
			sounds.rip();
			stickers.push(sticker);
			let lostOne = false;
			if (stickers.length > stickerLimit) {
				const oldest = stickers.shift();
				oldest.element.remove();
				lostOne = true;
			}

			addStickerElement(sticker);
			touchedSticker = sticker;
			saveStickers();
			updateWall();
			if (stickers.length === 1 && !lostOne) {
				this.toast('Your first sticker! It is inside my wardrobe door, under the camera.');
			}

			if (!isAutomatic) {
				const extra = lostOne ? ' The oldest sticker lost its glue and fell behind the radiator.' : '';
				this.say(`Rrritsj! You tore it off and stuck it inside my wardrobe door, below. Drag it, or move it with the arrow keys.${extra}`);
				sticker.element.focus({preventScroll: true});
			}
		};

		this.on(tearButton, 'click', () => {
			tearOff(false);
		});

		this.on(peelButton, 'click', () => {
			const sticker = touchedSticker ?? stickers.at(-1);
			if (sticker) {
				peel(sticker);
				this.say('You peeled it off. It leaves a sticky mark, and Mamma will find it in 2005.');
			}
		});

		// The album in the page, with a small picture for each photo.
		const slotImage = new ImageData(photoWidth, photoHeight);

		const updateAlbum = () => {
			for (const [index, slot] of slots.entries()) {
				const photo = album[index];
				const canvas = slot.querySelector('canvas');
				const slotContext = canvas.getContext('2d');
				slot.disabled = !photo;
				const isSelected = Boolean(photo) && index === state.selected;
				slot.dataset.state = isSelected ? 'selected' : '';
				slot.setAttribute('aria-pressed', String(isSelected));
				slot.setAttribute('aria-label', photo ? `Photo ${index + 1}, in the frame ${frames[photo.frame].name}` : `Photo ${index + 1}, empty`);
				if (photo) {
					paintShades(slotContext, photo.shades, photoWidth, photoHeight, slotImage);
				} else {
					slotContext.fillStyle = palette().colors[0];
					slotContext.fillRect(0, 0, photoWidth, photoHeight);
				}
			}
		};

		for (const slot of slots) {
			this.on(slot, 'click', () => {
				const index = Number(slot.dataset.gbCameraSlot);
				if (!album[index]) {
					return;
				}

				state.selected = index;
				state.undo = [];
				if (!state.isOn) {
					turnOn('album');
				} else if (state.mode !== 'stamps') {
					setMode('album');
				}

				state.infoTime = 2;
				updateAlbum();
				this.say(`Photo ${index + 1} of ${album.length}, in the frame ${frames[album[index].frame].name}.`);
				refresh();
			});
		}

		// What the lens sees now: the webcam, or a scene.
		const sceneId = () => state.isEyeTurned ? 'me' : state.scene;

		const look = () => {
			if (webcam.stream && !(webcam.video?.readyState >= 2 && webcam.video.videoWidth > 0)) {
				// The webcam takes a moment to start, and the lens is gray until then.
				lens.fillStyle = gray(128);
				lens.fillRect(0, 0, photoWidth, photoHeight);
			} else if (webcam.stream) {
				const {video} = webcam;
				const scale = Math.max(photoWidth / video.videoWidth, photoHeight / video.videoHeight);
				const sourceWidth = photoWidth / scale;
				const sourceHeight = photoHeight / scale;
				lens.save();
				// The webcam looks at the visitor, so with the eye turned, it is a mirror, like when you look at yourself.
				if (state.isEyeTurned) {
					lens.translate(photoWidth, 0);
					lens.scale(-1, 1);
				}

				lens.drawImage(video, (video.videoWidth - sourceWidth) / 2, (video.videoHeight - sourceHeight) / 2, sourceWidth, sourceHeight, 0, 0, photoWidth, photoHeight);
				lens.restore();
			} else {
				const id = sceneId();
				const scene = scenes[id];
				const maximum = scene.width - photoWidth;
				state.pan = clamp(state.pan, 0, maximum);
				const pan = Math.round(state.pan);
				lens.drawImage(sceneCanvas(id), -pan, 0);
				lens.save();
				lens.translate(-pan, 0);
				scene.animate(lens, this.reducedMotion ? 0 : state.time);
				lens.restore();
			}

			const {data} = lens.getImageData(0, 0, photoWidth, photoHeight);
			for (let index = 0; index < lightness.length; index++) {
				lightness[index] = ((data[index * 4] * 0.299) + (data[(index * 4) + 1] * 0.587) + (data[(index * 4) + 2] * 0.114)) / 255;
			}
		};

		// The dithering, with the brightness and the contrast of the camera, and then the trick lens.
		const develop = () => {
			look();
			const contrast = 1.22 ** settings.contrast;
			const brightness = settings.brightness * 0.07;
			for (let y = 0; y < photoHeight; y++) {
				for (let x = 0; x < photoWidth; x++) {
					const index = (y * photoWidth) + x;
					const value = ((lightness[index] - 0.5) * contrast) + 0.5 + brightness;
					const level = clamp(Math.floor((value * 3) + bayer[((y & 3) << 2) | (x & 3)]), 0, 3);
					dithered[index] = 3 - level;
				}
			}

			const trick = tricks[state.trick].id;
			for (let y = 0; y < photoHeight; y++) {
				for (let x = 0; x < photoWidth; x++) {
					let sourceX = x;
					let sourceY = y;
					if (trick === 'mirror-left' && x >= photoWidth / 2) {
						sourceX = photoWidth - 1 - x;
					} else if (trick === 'mirror-right' && x < photoWidth / 2) {
						sourceX = photoWidth - 1 - x;
					} else if (trick === 'mirror-top' && y >= photoHeight / 2) {
						sourceY = photoHeight - 1 - y;
					}

					const index = (y * photoWidth) + x;
					view[index] = trick === 'panorama' && x < state.panorama.count * 32 ? state.panorama.parts[index] : dithered[(sourceY * photoWidth) + sourceX];
				}
			}
		};

		const addPhoto = shades => {
			album.push({shades, frame: 0});
			state.selected = album.length - 1;
			saveAlbum();
			updateAlbum();
		};

		const takePhoto = () => {
			if (album.length >= albumSize) {
				sounds.error();
				state.message = {text: 'ALBUM FULL!', time: 1.6};
				this.say('The album is full: 30 photos, like the real one. Erase one in the Album first.');
				refresh();
				return;
			}

			develop();
			sounds.shutter();
			state.flash = 0.12;
			const trick = tricks[state.trick].id;
			if (trick === 'panorama') {
				const start = state.panorama.count * 32;
				for (let y = 0; y < photoHeight; y++) {
					for (let x = start; x < start + 32; x++) {
						state.panorama.parts[(y * photoWidth) + x] = dithered[(y * photoWidth) + x];
					}
				}

				state.panorama.count++;
				if (state.panorama.count < 4) {
					state.message = {text: `PART ${state.panorama.count}/4`, time: 1};
					this.say(`Part ${state.panorama.count} of 4. Point the camera a bit to the right, and shoot the next part.`);
					refresh();
					return;
				}

				addPhoto(state.panorama.parts.slice());
				state.panorama.count = 0;
				state.message = {text: `SAVED ${album.length}/30`, time: 1.2};
				this.say(`The panorama is done, from 4 shots. It is photo ${album.length} in the album.`);
				refresh();
				return;
			}

			addPhoto(view.slice());
			state.message = {text: `SAVED ${album.length}/30`, time: 1.2};
			const caption = webcam.stream ? (state.isEyeTurned ? 'Click! That is you, in 128 × 112 pixels and 4 shades.' : 'Click! What your webcam sees, in 128 × 112 pixels and 4 shades.') : randomItem(scenes[sceneId()].caption);
			// The first photo shows the next step, as printing is the best part.
			this.say(`${caption} (${album.length} of 30)${album.length === 1 ? ' Now print it: 🖼️ Album, then 🖨️ Print!' : ''}`);
			refresh();
		};

		const startTimer = () => {
			if (state.timer !== undefined) {
				state.timer = undefined;
				this.say('The self-timer is stopped. The balloon flew away.');
				refresh();
				return;
			}

			state.timer = 5;
			sounds.tick();
			this.say('The self-timer! When the hot-air balloon is at the top, click! Get in the picture.');
			refresh();
		};

		const stepTimer = seconds => {
			if (state.timer === undefined) {
				return;
			}

			const before = Math.ceil(state.timer);
			state.timer -= seconds;
			if (state.timer <= 0) {
				state.timer = undefined;
				takePhoto();
			} else if (Math.ceil(state.timer) !== before) {
				tone(state.timer < 1 ? 2093 : 1568, 0, 0.06, {volume: 0.05});
			}
		};

		const adjust = (setting, change) => {
			const limits = {brightness: [-4, 4], contrast: [-3, 4]};
			const value = clamp(settings[setting] + change, ...limits[setting]);
			if (value === settings[setting]) {
				sounds.error();
				this.say(`The ${setting} cannot go further.`);
				return;
			}

			settings[setting] = value;
			saveSettings();
			sounds.blip();
			this.say(`${setting === 'brightness' ? 'Brightness' : 'Contrast'} ${value > 0 ? '+' : ''}${value}.`);
			refresh();
		};

		const panBy = change => {
			if (webcam.stream) {
				this.say('With the webcam, you point the camera with your head!');
				return;
			}

			state.pan += change;
			state.autoPanPause = 4;
			refresh();
		};

		// The webcam, only after the visitor clicks for it, and off again when the game console leaves the screen or the page closes.
		const stopWebcam = message => {
			if (!webcam.stream) {
				return;
			}

			for (const track of webcam.stream.getTracks()) {
				track.stop();
			}

			webcam.stream = undefined;
			if (webcam.video) {
				webcam.video.srcObject = undefined;
			}

			setPressed(webcamButton, false);
			webcamButton.textContent = '🎥 Use My Webcam';
			updateSceneButtons();
			if (message) {
				this.say(message);
			}

			refresh();
		};

		const updateSceneButtons = () => {
			for (const button of sceneButtons) {
				setPressed(button, !webcam.stream && button.dataset.gbCameraScene === state.scene);
			}
		};

		this.on(webcamButton, 'click', async () => {
			if (webcam.stream) {
				stopWebcam('The webcam is off. The camera looks at my drawings again.');
				return;
			}

			if (webcam.isAsking) {
				return;
			}

			if (!navigator.mediaDevices?.getUserMedia) {
				this.say('This browser does not let the page use a webcam. Point the camera at my drawings instead!');
				return;
			}

			webcam.isAsking = true;
			this.say('The browser asks if the page may use your camera. The picture stays on your computer.');
			let stream;
			try {
				stream = await navigator.mediaDevices.getUserMedia({video: {width: {ideal: 320}, height: {ideal: 240}, facingMode: 'user'}, audio: false});
			} catch (error) {
				webcam.isAsking = false;
				const messages = {
					NotAllowedError: 'You said no, and that is OK! Mamma does not like cameras either. Point the camera at my drawings instead.',
					SecurityError: 'The browser does not let the page use a webcam. Point the camera at my drawings instead.',
					NotFoundError: 'No webcam found. In 1999, nobody had one either! Point the camera at my drawings instead.',
					OverconstrainedError: 'No webcam found. In 1999, nobody had one either! Point the camera at my drawings instead.',
					NotReadableError: 'The webcam is busy in another program. Close it, and try again. Or point the camera at my drawings.',
				};
				this.say(messages[error?.name] ?? 'The webcam did not start. Point the camera at my drawings instead!');
				return;
			}

			webcam.isAsking = false;

			// The visitor can scroll away while the browser asks, and then the camera is not needed.
			if (!this.isVisible) {
				for (const track of stream.getTracks()) {
					track.stop();
				}

				return;
			}

			webcam.stream = stream;
			webcam.video ??= Object.assign(document.createElement('video'), {muted: true, playsInline: true});
			webcam.video.srcObject = stream;
			webcam.video.play().catch(() => {});
			for (const track of stream.getTracks()) {
				track.addEventListener('ended', () => {
					stopWebcam('The webcam stopped. The camera looks at my drawings again.');
				});
			}

			setPressed(webcamButton, true);
			webcamButton.textContent = '⏹️ Stop My Webcam';
			updateSceneButtons();
			if (state.isOn) {
				setMode('shoot');
			} else {
				turnOn('shoot');
			}

			this.say('Your webcam is a camera cartridge now! 128 × 112 pixels, 4 shades. Press A to shoot, and turn the eye to see yourself like in a mirror.');
		});

		this.on(window, 'pagehide', () => {
			stopWebcam();
			stopMusic();
		});

		// The modes, the screen, and the buttons.
		const menuItems = [
			{mode: 'shoot', name: 'SHOOT'},
			{mode: 'album', name: 'VIEW'},
			{mode: 'stamps', name: 'EDIT'},
			{mode: 'music', name: 'MUSIC'},
			{mode: 'run', name: 'RACE'},
		];

		const modeMessages = {
			menu: () => 'The menu. ▲ ▼ pick, and A opens.',
			shoot: () => webcam.stream ? 'Shoot! A takes a photo with your webcam.' : 'Shoot! A takes a photo. ▲ ▼ change the brightness, and ◀ ▶ the contrast. Drag the screen to point the camera.',
			album: () => album.length === 0 ? 'The album is empty. Go to Shoot, and take some photos!' : `The album: ${album.length} of 30 photos. ◀ ▶ flip through them, ▲ ▼ pick a frame, and A prints.`,
			stamps: () => 'Stamps! Tap the photo, or move the stamp with the D-pad and press A. B takes the last one away.',
			music: () => 'Music! Tap the grid on the screen, or move with the D-pad and press A. Start plays the song.',
			run: () => 'Race! Press Start, and then A and B, one after the other, as fast as you can.',
		};

		const setMode = mode => {
			let isStampsWithoutPhotos = false;
			if (mode === 'stamps' && album.length === 0) {
				sounds.error();
				isStampsWithoutPhotos = true;
				mode = 'shoot';
			}

			if (state.mode === 'music' && mode !== 'music') {
				stopMusic();
			}

			if (state.mode === 'shoot' && mode !== 'shoot') {
				state.timer = undefined;
				state.panorama.count = 0;
				stopWebcam();
			}

			if (mode === 'run' && state.mode !== 'run') {
				race.phase = 'ready';
			}

			state.mode = mode;
			state.modeTime = 0;
			state.message = undefined;
			state.undo = [];
			state.infoTime = mode === 'album' ? 2 : 0;
			const menuIndex = menuItems.findIndex(item => item.mode === mode);
			if (menuIndex >= 0) {
				state.menuIndex = menuIndex;
			}
			for (const button of modeButtons) {
				setPressed(button, button.dataset.gbCameraMode === mode);
			}

			for (const panel of panels) {
				panel.hidden = panel.dataset.gbCameraPanel !== mode;
			}

			if (isStampsWithoutPhotos) {
				this.say('There are no photos to put stamps on. Shoot one first!');
			} else if (modeMessages[mode]) {
				this.say(modeMessages[mode]());
			}

			refresh();
		};

		const turnOn = mode => {
			state.isOn = true;
			powerButton.setAttribute('aria-pressed', 'true');
			powerButton.dataset.state = 'on';
			led.dataset.state = 'on';
			if (!printJob) {
				printerLight.dataset.state = 'on';
			}

			state.isDingPlayed = false;
			if (mode) {
				setMode(mode);
			} else if (this.reducedMotion) {
				setMode('title');
				this.say('It is on! Press Start.');
			} else {
				setMode('boot');
				this.say('It is on! The logo comes down…');
			}
		};

		const turnOff = () => {
			stopMusic();
			stopWebcam();
			state.isOn = false;
			state.timer = undefined;
			setMode('off');
			powerButton.setAttribute('aria-pressed', 'false');
			powerButton.dataset.state = '';
			led.dataset.state = '';
			if (!printJob) {
				printerLight.dataset.state = '';
			}

			for (const button of modeButtons) {
				setPressed(button, false);
			}

			this.say('It is off. The photos are still in the album, as the cartridge has a battery.');
		};

		this.on(powerButton, 'click', () => {
			if (state.isOn) {
				turnOff();
			} else {
				turnOn();
			}
		});

		// The buttons under the game console turn it on in their mode, or go to their mode, first. The buttons of the album also work while the stamps are on.
		const control = (mode, action) => () => {
			if (!state.isOn) {
				turnOn(mode);
			} else if (state.mode !== mode && !(mode === 'album' && state.mode === 'stamps')) {
				setMode(mode);
			}

			action();
			refresh();
		};

		for (const button of modeButtons) {
			this.on(button, 'click', () => {
				sounds.select();
				if (state.isOn) {
					setMode(button.dataset.gbCameraMode);
				} else {
					turnOn(button.dataset.gbCameraMode);
				}
			});
		}

		for (const button of sceneButtons) {
			this.on(button, 'click', () => {
				state.scene = button.dataset.gbCameraScene;
				state.pan = scenes[state.scene].start ?? 0;
				state.panDirection = 1;
				if (state.isEyeTurned) {
					state.isEyeTurned = false;
					eye.dataset.state = '';
					setPressed(turnEyeButton, false);
				}

				stopWebcam();
				updateSceneButtons();
				sounds.blip();
				if (state.isOn) {
					setMode('shoot');
				} else {
					turnOn('shoot');
				}

				const names = {room: 'my room', rocky: 'Rocky', glitter: 'Glitter on my monitor', bryggen: 'Bryggen, in the rain'};
				this.say(`The camera looks at ${names[state.scene]}. Press A to shoot!`);
			});
		}

		const turnEye = () => {
			state.isEyeTurned = !state.isEyeTurned;
			eye.dataset.state = state.isEyeTurned ? 'turned' : '';
			setPressed(turnEyeButton, state.isEyeTurned);
			state.pan = 32;
			sounds.blip();
			if (webcam.stream) {
				this.say(state.isEyeTurned ? 'The eye looks at you, like a mirror.' : 'The eye looks away from you, like a camera.');
			} else {
				this.say(state.isEyeTurned ? 'The eye looks at me now. I smile! Press A.' : 'The eye looks forward again.');
			}

			refresh();
		};

		this.on(turnEyeButton, 'click', control('shoot', turnEye));

		const nextTrick = () => {
			state.trick = (state.trick + 1) % tricks.length;
			state.panorama.count = 0;
			trickButton.textContent = `🪞 Trick Lens: ${tricks[state.trick].name}`;
			sounds.blip();
			const messages = {
				normal: 'The normal lens.',
				'mirror-left': 'The mirror: the left half, and the left half again, the other way. Everybody has two left ears!',
				'mirror-right': 'The mirror: the right half, twice.',
				'mirror-top': 'The mirror of the top and the bottom, like a lake on a day without wind (so not in Bergen).',
				panorama: 'Panorama: 4 shots, one for each part of the photo. Point the camera a bit to the right after each one.',
			};
			this.say(messages[tricks[state.trick].id]);
			refresh();
		};

		this.on(shutterButton, 'click', control('shoot', () => {
			if (state.timer === undefined) {
				takePhoto();
			}
		}));
		this.on(trickButton, 'click', control('shoot', nextTrick));
		this.on(timerButton, 'click', control('shoot', startTimer));
		this.on(darkerButton, 'click', control('shoot', () => adjust('brightness', -1)));
		this.on(brighterButton, 'click', control('shoot', () => adjust('brightness', 1)));
		this.on(lessContrastButton, 'click', control('shoot', () => adjust('contrast', -1)));
		this.on(moreContrastButton, 'click', control('shoot', () => adjust('contrast', 1)));
		this.on(panLeftButton, 'click', control('shoot', () => panBy(-24)));
		this.on(panRightButton, 'click', control('shoot', () => panBy(24)));

		this.on(colorsButton, 'click', () => {
			settings.palette = (settings.palette + 1) % palettes.length;
			saveSettings();
			const current = palette();
			colorsButton.textContent = `🎨 Colors: ${current.name}`;
			updateAlbum();
			refresh();
			sounds.blip();
			this.say(current.note ?? `${current.name}. On the real console, you hold ${current.combo} while the logo comes down.`);
		});

		const changeFrame = change => {
			const photo = album[state.selected];
			if (!photo) {
				sounds.error();
				this.say('There is no photo to put in a frame. Shoot one first!');
				return;
			}

			photo.frame = (photo.frame + change + frames.length) % frames.length;
			state.infoTime = 2;
			saveAlbum();
			updateAlbum();
			sounds.blip();
			this.say(`The frame: ${frames[photo.frame].name}.`);
			refresh();
		};

		const flip = change => {
			if (album.length === 0) {
				sounds.error();
				return;
			}

			state.selected = (state.selected + change + album.length) % album.length;
			state.infoTime = 2;
			state.undo = [];
			updateAlbum();
			sounds.blip();
			this.say(`Photo ${state.selected + 1} of ${album.length}.`);
			refresh();
		};

		this.on(framePreviousButton, 'click', control('album', () => changeFrame(-1)));
		this.on(frameNextButton, 'click', control('album', () => changeFrame(1)));
		this.on(printButton, 'click', control('album', startPrint));
		// The button hides its own panel, so the focus goes on to the button of the mode (`focusReplacement()`).
		this.on(toStampsButton, 'click', control('stamps', () => {}));

		let eraseTimer;
		let eraseIndex;

		const stopAskingToErase = () => {
			clearTimeout(eraseTimer);
			eraseIndex = undefined;
			eraseButton.textContent = '🗑️ Erase';
		};

		this.on(eraseButton, 'click', control('album', () => {
			if (!album[state.selected]) {
				sounds.error();
				this.say('There is no photo to erase.');
				return;
			}

			// The real camera asks first, so the button asks too.
			if (eraseIndex !== state.selected) {
				stopAskingToErase();
				eraseIndex = state.selected;
				eraseButton.textContent = '🗑️ Really Erase?';
				this.say(`Erase photo ${state.selected + 1}? Press Erase again.`);
				eraseTimer = setTimeout(stopAskingToErase, 3000);
				return;
			}

			stopAskingToErase();
			album.splice(state.selected, 1);
			state.undo = [];
			state.selected = clamp(state.selected, 0, Math.max(album.length - 1, 0));
			saveAlbum();
			updateAlbum();
			sounds.back();
			this.say(album.length === 0 ? 'Erased. The album is empty now.' : `Erased. ${album.length} photos are left.`);
			if (album.length === 0 && state.mode === 'stamps') {
				setMode('album');
			}

			refresh();
		}));

		this.on(pngButton, 'click', () => {
			const photo = album[state.selected];
			if (!photo) {
				sounds.error();
				this.say('There is no photo to save. Shoot one first!');
				return;
			}

			const small = document.createElement('canvas');
			small.width = width;
			small.height = height;
			paintShades(small.getContext('2d'), compose(photo, state.selected + 1).pixels, width, height);
			const big = document.createElement('canvas');
			big.width = width * 4;
			big.height = height * 4;
			const bigContext = big.getContext('2d');
			bigContext.imageSmoothingEnabled = false;
			bigContext.drawImage(small, 0, 0, big.width, big.height);
			big.toBlob(blob => {
				if (!blob) {
					this.say('The PNG did not work. Try again.');
					return;
				}

				const url = URL.createObjectURL(blob);
				const link = document.createElement('a');
				link.href = url;
				link.download = `camera-photo-${String(state.selected + 1).padStart(2, '0')}.png`;
				link.click();
				setTimeout(() => {
					URL.revokeObjectURL(url);
				}, 10_000);
				this.say('Saved as a PNG, 4 times as big, for your own home page. In 1999, it took 2 minutes to upload.');
			}, 'image/png');
		});

		// The stamps on a photo, at twice the size of their pixels, so a hat fits a head.
		const doubled = rows => rows.flatMap(row => {
			const wide = [...row].map(character => character + character).join('');
			return [wide, wide];
		});

		const stampRows = () => doubled(stamps[state.stamp].rows);

		const putStamp = () => {
			const photo = album[state.selected];
			if (!photo) {
				return;
			}

			state.undo.push(photo.shades.slice());
			if (state.undo.length > 12) {
				state.undo.shift();
			}

			const rows = stampRows();
			new Surface(photoWidth, photoHeight, photo.shades).sprite(rows, state.cursor.x - Math.floor(rows[0].length / 2), state.cursor.y - Math.floor(rows.length / 2));
			saveAlbum();
			updateAlbum();
			sounds.stamp();
			this.say(`A ${stamps[state.stamp].name} on photo ${state.selected + 1}!`);
			refresh();
		};

		const undoStamp = () => {
			const photo = album[state.selected];
			const previous = state.undo.pop();
			if (!photo || !previous) {
				sounds.error();
				this.say('There is nothing to take away.');
				return;
			}

			photo.shades.set(previous);
			saveAlbum();
			updateAlbum();
			sounds.back();
			this.say('The last stamp is gone.');
			refresh();
		};

		const setStamp = id => {
			state.stamp = id;
			for (const button of stampButtons) {
				setPressed(button, button.dataset.gbCameraStamp === id);
			}
		};

		for (const button of stampButtons) {
			this.on(button, 'click', control('stamps', () => {
				setStamp(button.dataset.gbCameraStamp);
				sounds.blip();
				if (state.mode === 'stamps') {
					this.say(`The ${stamps[state.stamp].name}. Tap the photo where it goes, or press A.`);
				}
			}));
		}

		this.on(undoButton, 'click', undoStamp);
		this.on(stampsDoneButton, 'click', () => {
			setMode('album');
		});

		// The buttons of the music maker.
		const togglePlay = () => {
			if (music.isPlaying) {
				stopMusic();
				this.say('Stop. Mamma says thank you.');
			} else {
				startMusic();
				if (music.isPlaying) {
					this.say(`The song plays at ${song.tempo} beats a minute.`);
				}
			}
		};

		this.on(musicPlayButton, 'click', control('music', togglePlay));
		this.on(slowerButton, 'click', control('music', () => {
			song.tempo = clamp(song.tempo - 12, 80, 220);
			saveSong();
			this.say(`${song.tempo} beats a minute.`);
		}));
		this.on(fasterButton, 'click', control('music', () => {
			song.tempo = clamp(song.tempo + 12, 80, 220);
			saveSong();
			this.say(song.tempo >= 220 ? '220 beats a minute! That is happy hardcore, Lillesøster is dancing.' : `${song.tempo} beats a minute.`);
		}));
		this.on(demoButton, 'click', control('music', () => {
			Object.assign(song, demoSong());
			saveSong();
			this.say('The demo song. I made it on the bus to school.');
		}));

		const randomSong = () => {
			const notes = [0, 2, 4, 5, 7, 4, 2];
			let note = Math.floor(Math.random() * 8);
			for (let step = 0; step < 16; step++) {
				note = clamp(note + randomItem([-2, -1, 0, 1, 2, 3]), 0, 7);
				song.melody[step] = Math.random() < 0.7 ? note : -1;
				song.bass[step] = step % 4 === 0 || Math.random() < 0.25 ? 1 : 0;
				song.kick[step] = step % 4 === 0 || Math.random() < 0.12 ? 1 : 0;
				song.snare[step] = step % 8 === 4 || Math.random() < 0.08 ? 1 : 0;
				song.hat[step] = step % 2 === 0 || Math.random() < 0.3 ? 1 : 0;
			}

			song.melody[0] = randomItem(notes);
			saveSong();
		};

		this.on(randomButton, 'click', control('music', () => {
			randomSong();
			this.say('A trippy song, made by chance. Like on the real camera, it sounds better than it should.');
		}));
		this.on(clearButton, 'click', control('music', () => {
			song.melody.fill(-1);
			for (const name of ['bass', ...drumNames]) {
				song[name].fill(0);
			}

			saveSong();
			this.say('Empty. Now make your own!');
		}));

		this.on(runStartButton, 'click', control('run', startRace));

		// What the buttons of the game console do in each mode.
		const press = name => {
			// Any button turns it on, so a first press is never a dead end.
			if (!state.isOn) {
				turnOn();
				return;
			}

			switch (state.mode) {
				case 'boot': {
					setMode('title');
					break;
				}

				case 'title': {
					if (name === 'start' || name === 'a') {
						sounds.select();
						setMode('menu');
					}

					break;
				}

				case 'menu': {
					if (name === 'up' || name === 'down') {
						state.menuIndex = (state.menuIndex + (name === 'up' ? -1 : 1) + menuItems.length) % menuItems.length;
						sounds.blip();
						this.say(menuItems[state.menuIndex].name);
					} else if (name === 'a' || name === 'start') {
						sounds.select();
						setMode(menuItems[state.menuIndex].mode);
					}

					break;
				}

				case 'shoot': {
					const actions = {
						a() {
							if (state.timer === undefined) {
								takePhoto();
							} else {
								startTimer();
							}
						},
						b() {
							sounds.back();
							setMode('menu');
						},
						up: () => adjust('brightness', 1),
						down: () => adjust('brightness', -1),
						left: () => adjust('contrast', -1),
						right: () => adjust('contrast', 1),
						select: nextTrick,
						start: startTimer,
					};
					actions[name]?.();
					break;
				}

				case 'album': {
					const actions = {
						left: () => flip(-1),
						right: () => flip(1),
						up: () => changeFrame(-1),
						down: () => changeFrame(1),
						a: startPrint,
						select() {
							setMode('stamps');
						},
						start() {
							setMode('stamps');
						},
						b() {
							sounds.back();
							setMode('menu');
						},
					};
					actions[name]?.();
					break;
				}

				case 'stamps': {
					const moves = {left: [-4, 0], right: [4, 0], up: [0, -4], down: [0, 4]};
					if (moves[name]) {
						state.cursor.x = clamp(state.cursor.x + moves[name][0], 0, photoWidth - 1);
						state.cursor.y = clamp(state.cursor.y + moves[name][1], 0, photoHeight - 1);
					} else if (name === 'a') {
						putStamp();
					} else if (name === 'b') {
						undoStamp();
					} else if (name === 'select') {
						const ids = Object.keys(stamps);
						setStamp(ids[(ids.indexOf(state.stamp) + 1) % ids.length]);
						sounds.blip();
						this.say(`The ${stamps[state.stamp].name}.`);
					} else if (name === 'start') {
						setMode('album');
					}

					break;
				}

				case 'music': {
					const moves = {left: [0, -1], right: [0, 1], up: [-1, 0], down: [1, 0]};
					if (moves[name]) {
						music.cursor.row = (music.cursor.row + moves[name][0] + 12) % 12;
						music.cursor.column = (music.cursor.column + moves[name][1] + 16) % 16;
					} else if (name === 'a') {
						toggleCell(music.cursor.row, music.cursor.column);
					} else if (name === 'start') {
						togglePlay();
					} else if (name === 'select') {
						randomSong();
						this.say('A trippy song, made by chance.');
					} else if (name === 'b') {
						sounds.back();
						setMode('menu');
					}

					break;
				}

				case 'run': {
					if (name === 'start') {
						startRace();
					} else if ((name === 'a' || name === 'b') && race.phase === 'running') {
						runPress(name);
					} else if (name === 'select' || (name === 'b' && race.phase === 'ready')) {
						sounds.back();
						setMode('menu');
					} else if (name === 'a' && race.phase === 'ready') {
						startRace();
					}

					break;
				}

				default: {
					break;
				}
			}

			refresh();
		};

		// Drawing the screen for each mode.
		const drawEye = (centerX, centerY, radius, lookX, lookY) => {
			surface.disc(centerX, centerY, radius, 3);
			surface.disc(centerX, centerY, radius - 2, 0);
			surface.disc(centerX + lookX, centerY + lookY, Math.round(radius * 0.48), 3);
			surface.disc(centerX + lookX, centerY + lookY, Math.round(radius * 0.4), 2);
			surface.disc(centerX + lookX, centerY + lookY, Math.round(radius * 0.2), 3);
			surface.fill(centerX + lookX - 4, centerY + lookY - 4, 2, 2, 0);
		};

		const drawBoot = () => {
			surface.clear(0);
			// The eye of the camera comes down, like a logo.
			const y = Math.min(-14 + ((state.modeTime / 1.2) * 86), 72);
			drawEye(80, Math.round(y), 14, 0, 0);
		};

		const drawTitle = () => {
			surface.clear(0);
			const isStill = this.reducedMotion;
			const lookX = isStill ? 0 : Math.round(Math.sin(state.modeTime * 1.3) * 5);
			const lookY = isStill ? 0 : Math.round(Math.cos(state.modeTime * 0.9) * 3);
			drawEye(80, 46, 26, lookX, lookY);
			surface.centeredText('CAMERA', 86, 3, 3);
			if (isStill || Math.floor(state.modeTime * 2) % 2 === 0) {
				surface.centeredText('PRESS START', 120, 2);
			}

			surface.centeredText('1998', 134, 1);
		};

		const drawMenu = () => {
			surface.clear(0);
			drawEye(12, 10, 8, 2, 0);
			surface.text('CAMERA', 26, 8, 3);
			for (const [index, item] of menuItems.entries()) {
				const y = 24 + (index * 21);
				const isSelected = index === state.menuIndex;
				surface.fill(18, y, 132, 17, isSelected ? 1 : 0);
				surface.outline(18, y, 132, 17, 3);
				surface.text(item.name, 24, y + 4, 3, 2);
				if (isSelected) {
					surface.text('▶', 8, y + 4, 3, 2);
				}
			}

			surface.centeredText('A: OPEN', 134, 2);
		};

		const drawMeter = (label, value, minimum, maximum, x, y) => {
			surface.text(label, x, y, 3);
			for (let step = minimum; step <= maximum; step++) {
				const left = x + 14 + ((step - minimum) * 5);
				if (step <= value) {
					surface.fill(left, y, 4, 5, 3);
				} else {
					surface.outline(left, y, 4, 5, 2);
				}
			}
		};

		const drawMessage = () => {
			if (!state.message) {
				return;
			}

			const boxWidth = textWidth(state.message.text, 2) + 12;
			surface.box(Math.round((width - boxWidth) / 2), 62, boxWidth, 20);
			surface.centeredText(state.message.text, 67, 3, 2);
		};

		const drawBalloon = () => {
			if (state.timer === undefined) {
				return;
			}

			// The hot-air balloon goes up while the self-timer counts, and the photo is taken when it is at the top.
			const progress = this.reducedMotion ? Math.floor(5 - state.timer) / 5 : (5 - state.timer) / 5;
			const centerX = 120;
			const centerY = Math.round(photoY + photoHeight - 22 - (progress * 74));
			for (let y = -8; y <= 8; y++) {
				for (let x = -7; x <= 7; x++) {
					const distance = ((x * x) / 49) + ((y * y) / 64);
					if (distance <= 1) {
						surface.set(centerX + x, centerY + y, distance > 0.72 ? 3 : (Math.floor((x + 8) / 3) % 2 === 0 ? 0 : 2));
					}
				}
			}

			surface.line(centerX - 5, centerY + 6, centerX - 2, centerY + 12, 3);
			surface.line(centerX + 5, centerY + 6, centerX + 2, centerY + 12, 3);
			surface.fill(centerX - 2, centerY + 12, 5, 4, 3);
			surface.box(centerX - 24, centerY - 4, 12, 11);
			surface.text(String(Math.ceil(state.timer)), centerX - 20, centerY - 1, 3);
		};

		const drawShoot = () => {
			develop();
			surface.clear(0);
			surface.outline(photoX - 1, photoY - 1, photoWidth + 2, photoHeight + 2, 3);
			surface.blit(view, photoWidth, photoHeight, photoX, photoY);
			const trick = tricks[state.trick];
			surface.text(webcam.stream ? 'SHOOT: WEBCAM' : 'SHOOT', photoX, 5, 3);
			const count = `${album.length}/30`;
			surface.text(count, photoX + photoWidth - textWidth(count), 5, 3);
			if (trick.id === 'panorama') {
				surface.text(`PANO ${state.panorama.count + 1}/4`, 66, 5, 2);
				const left = photoX + (state.panorama.count * 32);
				surface.outline(left, photoY, 32, photoHeight, Math.floor(state.time * 3) % 2 === 0 || this.reducedMotion ? 3 : 0);
			} else if (trick.id !== 'normal') {
				surface.text('MIRROR', 66, 5, 2);
				if (trick.id === 'mirror-top') {
					surface.fill(photoX, photoY + (photoHeight / 2), photoWidth, 1, 2);
				} else {
					surface.fill(photoX + (photoWidth / 2), photoY, 1, photoHeight, 2);
				}
			}

			drawMeter('BR', settings.brightness, -4, 4, photoX, 134);
			drawMeter('CO', settings.contrast, -3, 4, photoX + 66, 134);
			drawBalloon();
			if (state.flash > 0) {
				surface.fill(photoX, photoY, photoWidth, photoHeight, 0);
			}

			drawMessage();
		};

		const drawView = () => {
			const photo = album[state.selected];
			if (!photo) {
				surface.clear(0);
				surface.centeredText('NO PHOTOS YET!', 58, 3, 2);
				surface.centeredText('PRESS B, AND SHOOT', 76, 2);
				return;
			}

			surface.pixels.set(compose(photo, state.selected + 1).pixels);
			if (printJob) {
				surface.box(30, 56, 100, 30);
				surface.centeredText('PRINTING', 61, 3, 2);
				const progress = clamp(printJob.elapsed / (bands * bandTime), 0, 1);
				surface.outline(38, 76, 84, 6, 3);
				surface.fill(39, 77, Math.round(82 * progress), 4, 2);
			} else if (state.infoTime > 0) {
				const text = `${state.selected + 1}/${album.length} ${frames[photo.frame].name}`;
				surface.box(2, height - 12, textWidth(text) + 8, 11);
				surface.text(text, 6, height - 9, 3);
			}

			drawMessage();
		};

		const drawStamps = () => {
			const photo = album[state.selected];
			if (!photo) {
				drawView();
				return;
			}

			surface.pixels.set(compose(photo, state.selected + 1).pixels);
			const rows = stampRows();
			const isShown = this.reducedMotion || Math.floor(state.time * 3) % 3 !== 0;
			if (isShown) {
				surface.sprite(rows, photoX + state.cursor.x - Math.floor(rows[0].length / 2), photoY + state.cursor.y - Math.floor(rows.length / 2), {left: photoX, top: photoY, right: photoX + photoWidth, bottom: photoY + photoHeight});
			}

			const text = `EDIT: ${stamps[state.stamp].name.replaceAll(/[“”]/g, '')}`;
			surface.box(2, 2, textWidth(text) + 8, 11);
			surface.text(text, 6, 5, 3);
		};

		// The grid of the music maker: 8 rows of notes, then the bass and 3 drums, and 16 steps.
		const gridLeft = 20;
		const cellWidth = 8;
		const rowTop = row => row < 8 ? 14 + (row * 6) : 66 + ((row - 8) * 8);
		const rowHeight = row => row < 8 ? 6 : 7;

		const thumbnail = (photo, size) => {
			const pixels = new Uint8Array(size.width * size.height);
			const scaleX = (photoWidth * size.crop) / size.width;
			const scaleY = (photoHeight * size.crop) / size.height;
			const left = (photoWidth * (1 - size.crop)) / 2;
			const top = (photoHeight * (1 - size.crop)) / 2;
			for (let y = 0; y < size.height; y++) {
				for (let x = 0; x < size.width; x++) {
					let total = 0;
					let samples = 0;
					for (let sampleY = Math.floor(top + (y * scaleY)); sampleY < Math.floor(top + ((y + 1) * scaleY)); sampleY++) {
						for (let sampleX = Math.floor(left + (x * scaleX)); sampleX < Math.floor(left + ((x + 1) * scaleX)); sampleX++) {
							total += photo.shades[(sampleY * photoWidth) + sampleX];
							samples++;
						}
					}

					pixels[(y * size.width) + x] = Math.round(total / Math.max(samples, 1));
				}
			}

			return pixels;
		};

		const drawMusic = () => {
			surface.clear(0);
			surface.text('MUSIC', 2, 3, 3);
			surface.text(music.isPlaying ? '▶ PLAY' : '■ STOP', 50, 3, music.isPlaying ? 3 : 2);
			const tempo = `${song.tempo} BPM`;
			surface.text(tempo, width - 2 - textWidth(tempo), 3, 3);
			const playing = currentStep();
			if (playing >= 0) {
				surface.fill(gridLeft + (playing * cellWidth), 12, cellWidth, 89, 1);
			}

			for (let column = 0; column < 16; column++) {
				const x = gridLeft + (column * cellWidth);
				for (let row = 0; row < 12; row++) {
					const top = rowTop(row);
					let isOn;
					if (row < 8) {
						isOn = song.melody[column] === 7 - row;
					} else if (row === 8) {
						isOn = song.bass[column] === 1;
					} else {
						isOn = song[drumNames[row - 9]][column] === 1;
					}

					if (isOn) {
						surface.fill(x + 1, top + 1, cellWidth - 2, rowHeight(row) - 2, 3);
					} else {
						surface.set(x + 3, top + Math.floor(rowHeight(row) / 2), column % 4 === 0 ? 3 : 2);
					}
				}
			}

			for (const [label, row] of [['LD', 3], ['BS', 8], ['BD', 9], ['SN', 10], ['HH', 11]]) {
				surface.text(label, 2, rowTop(row) + 1, 2);
			}

			surface.fill(gridLeft, 63, 128, 1, 2);
			const isCursorShown = this.reducedMotion || Math.floor(state.time * 3) % 3 !== 0;
			if (isCursorShown) {
				const {row, column} = music.cursor;
				surface.outline(gridLeft + (column * cellWidth) - 1, rowTop(row) - 1, cellWidth + 2, rowHeight(row) + 2, 3);
			}

			// A little dancer: the head is the last photo, and it jumps on the beat.
			const photo = album.at(-1);
			const isBeat = playing >= 0 && playing % 2 === 0 && !this.reducedMotion;
			const dancerY = isBeat ? 104 : 106;
			if (photo) {
				surface.blit(thumbnail(photo, {width: 24, height: 21, crop: 0.8}), 24, 21, 68, dancerY);
				surface.outline(67, dancerY - 1, 26, 23, 3);
			} else {
				drawEye(80, dancerY + 10, 10, isBeat ? 3 : -3, 0);
			}

			surface.line(64, dancerY + 14, isBeat ? 56 : 58, dancerY + (isBeat ? 4 : 20), 3);
			surface.line(96, dancerY + 14, isBeat ? 104 : 102, dancerY + (isBeat ? 4 : 20), 3);
			for (let bar = 0; bar < 6; bar++) {
				const level = playing >= 0 ? 2 + ((bar * 7) + (playing * 3)) % 9 : 1;
				surface.fill(114 + (bar * 6), 128 - (level * 2), 4, level * 2, 2);
				surface.fill(14 + (bar * 6), 128 - (level * 2), 4, level * 2, 2);
			}

			surface.centeredText('A:NOTE START:PLAY B:MENU', 134, 2);
		};

		// The heads of the runners: Trond with his blond spikes, and me, if there is no photo yet.
		const makeHead = hair => {
			const pixels = new Uint8Array(16 * 14).fill(4);
			const head = new Surface(16, 14, pixels);
			head.disc(8, 8, 6, 3);
			head.disc(8, 8, 5, 0);
			if (hair === 'spikes') {
				for (let x = 2; x < 15; x += 3) {
					head.line(x, 0, x + 1, 5, 1);
					head.line(x + 1, 0, x + 2, 5, 1);
				}

				head.fill(3, 3, 11, 3, 1);
			} else {
				head.fill(2, 1, 13, 5, 3);
			}

			head.set(6, 8, 3);
			head.set(10, 8, 3);
			head.line(6, 11, 10, 11, 3);
			return pixels;
		};

		const trondHead = makeHead('spikes');
		const sindreHead = makeHead('bowl');

		const drawRunner = (x, feetY, head, stride, isStumbling) => {
			const phase = stride % 2;
			const hipY = feetY - 10;
			surface.fill(x - 1, feetY - 20, 3, 11, 3);
			if (isStumbling) {
				surface.line(x, hipY, x - 6, feetY, 3);
				surface.line(x, hipY, x + 6, feetY - 2, 3);
				surface.line(x, feetY - 18, x - 7, feetY - 12, 3);
				surface.line(x, feetY - 18, x + 7, feetY - 24, 3);
			} else {
				surface.line(x, hipY, x + (phase === 0 ? 5 : -4), feetY, 3);
				surface.line(x, hipY, x + (phase === 0 ? -4 : 5), feetY - (phase === 0 ? 2 : 0), 3);
				surface.line(x, feetY - 18, x + (phase === 0 ? -5 : 5), feetY - 13, 3);
				surface.line(x, feetY - 18, x + (phase === 0 ? 5 : -5), feetY - 23, 3);
			}

			surface.blit(head, 16, 14, x - 8, feetY - 34);
		};

		const drawRun = () => {
			surface.clear(0);
			const camera = (race.player.distance * 8) - 44;
			for (let x = 0; x < width; x++) {
				const world = x + (camera * 0.2);
				const hill = Math.round(42 + (Math.sin(world / 23) * 7) + (Math.sin(world / 9) * 3));
				surface.fill(x, hill, 1, 74 - hill, 1);
			}

			surface.fill(0, 74, width, 56, 2);
			for (const y of [74, 96, 118, 129]) {
				surface.fill(0, y, width, 1, 0);
			}

			for (let meter = 0; meter <= 100; meter += 10) {
				const x = Math.round((meter * 8) - camera);
				if (x > -20 && x < width + 20) {
					if (meter === 100) {
						for (let y = 75; y < 129; y += 3) {
							surface.fill(x, y, 3, 3, (y / 3) % 2 === 0 ? 0 : 3);
							surface.fill(x + 3, y, 3, 3, (y / 3) % 2 === 0 ? 3 : 0);
						}

						surface.text('MÅL', x - 5, 66, 3);
					} else {
						surface.fill(x, 75, 1, 54, 1);
						surface.text(`${meter}`, x - 3, 66, 3);
					}
				}
			}

			const rivalX = Math.round((race.rival.distance * 8) - camera);
			const rivalStride = Math.floor(race.rival.distance * 1.6);
			if (rivalX > -10 && rivalX < width + 10) {
				drawRunner(rivalX, 106, trondHead, rivalStride, false);
				surface.text('TROND', rivalX - 9, 108, 0);
			} else if (rivalX >= width + 10) {
				surface.text('TROND >', width - 30, 100, 0);
			}

			const photo = album.at(-1);
			const head = photo ? thumbnail(photo, {width: 16, height: 14, crop: 0.75}) : sindreHead;
			drawRunner(Math.round((race.player.distance * 8) - camera), 126, head, race.player.stride, race.stumbleTime > 0);
			surface.fill(0, 0, width, 11, 0);
			surface.text(`TIME ${formatTime(race.time)}`, 2, 3, 3);
			const distance = `${Math.floor(race.player.distance)}M`;
			surface.text(distance, width - 2 - textWidth(distance), 3, 3);
			if (race.phase === 'ready') {
				surface.box(14, 18, 132, 44);
				surface.centeredText('RACE', 24, 3, 2);
				surface.centeredText('A, B, A, B... FAST!', 40, 2);
				surface.centeredText(`START: GO  BEST ${formatTime(settings.bestRun)}`, 50, 3);
			} else if (race.phase === 'countdown') {
				const text = String(Math.ceil(race.countdown));
				surface.box(64, 22, 32, 30);
				surface.centeredText(text, 27, 3, 4);
			} else if (race.phase === 'running' && race.time < 0.6 && !this.reducedMotion) {
				surface.centeredText('GO!', 26, 3, 4);
			} else if (race.phase === 'running' && race.stumbleTime > 0) {
				surface.centeredText('OOPS!', 26, 3, 3);
			} else if (race.phase === 'finished') {
				surface.box(14, 18, 132, 44);
				surface.centeredText(race.hasWon ? 'YOU WIN!' : 'TROND WINS!', 24, 3, 2);
				surface.centeredText(race.player.distance >= 100 ? `YOU ${formatTime(race.time)}` : 'YOU STOPPED?', 40, 3);
				surface.centeredText('START: AGAIN', 50, 2);
			}
		};

		const draw = () => {
			if (!state.isOn) {
				context.fillStyle = '#2a2f22';
				context.fillRect(0, 0, width, height);
				return;
			}

			switch (state.mode) {
				case 'boot': {
					drawBoot();
					break;
				}

				case 'title': {
					drawTitle();
					break;
				}

				case 'menu': {
					drawMenu();
					break;
				}

				case 'shoot': {
					drawShoot();
					break;
				}

				case 'album': {
					drawView();
					break;
				}

				case 'stamps': {
					drawStamps();
					break;
				}

				case 'music': {
					drawMusic();
					break;
				}

				case 'run': {
					drawRun();
					break;
				}

				default: {
					surface.clear(0);
				}
			}

			paintShades(context, surface.pixels, width, height, screenImage);
		};

		// Whether something on the screen moves by itself now, so the loop runs only then.
		const isMoving = () => {
			if (printJob) {
				return true;
			}

			if (!state.isOn) {
				return false;
			}

			const isStill = this.reducedMotion;
			switch (state.mode) {
				case 'boot': {
					return true;
				}

				case 'title': {
					return !isStill;
				}

				case 'shoot': {
					return Boolean(webcam.stream) || !isStill || state.timer !== undefined || state.flash > 0 || state.message !== undefined;
				}

				case 'music': {
					return music.isPlaying || !isStill;
				}

				case 'run': {
					return !isStill && (race.phase === 'countdown' || race.phase === 'running');
				}

				case 'album':
				case 'stamps':
				case 'menu': {
					return state.message !== undefined || state.infoTime > 0 || (state.mode === 'stamps' && !isStill);
				}

				default: {
					return false;
				}
			}
		};

		const step = seconds => {
			state.time += seconds;
			state.modeTime += seconds;
			stepPrint(seconds);
			if (state.mode === 'boot') {
				if (state.modeTime >= 1.2 && !state.isDingPlayed) {
					state.isDingPlayed = true;
					sounds.ding();
				}

				if (state.modeTime >= 2) {
					setMode('title');
					this.say('The camera is on! Press Start.');
				}
			}

			if (state.mode === 'shoot') {
				stepTimer(seconds);
				state.flash = Math.max(state.flash - seconds, 0);
				state.autoPanPause = Math.max(state.autoPanPause - seconds, 0);
				// The camera pans slowly over the scene by itself, like a hand that holds it, unless the visitor prefers reduced motion.
				if (!this.reducedMotion && !webcam.stream && state.autoPanPause === 0 && !state.drag) {
					const maximum = scenes[sceneId()].width - photoWidth;
					state.pan += state.panDirection * seconds * 7;
					if (state.pan >= maximum || state.pan <= 0) {
						state.panDirection *= -1;
						state.pan = clamp(state.pan, 0, maximum);
					}
				}
			}

			// With reduced motion, the race only goes on when a button is pressed, also when the loop runs for something else, like the printer.
			if (state.mode === 'run' && !this.reducedMotion) {
				stepRace(seconds);
			}

			if (state.message) {
				state.message.time -= seconds;
				if (state.message.time <= 0) {
					state.message = undefined;
				}
			}

			state.infoTime = Math.max(state.infoTime - seconds, 0);
			draw();
		};

		const loop = this.loop(step, {while: isMoving});

		const refresh = () => {
			loop.start();
			draw();
		};

		// A touch only lets the sound start when the finger lifts, and a browser can pause the sound (like iOS after a call), so the sound is woken up again after each touch or key in the toy, also after a press on pointerdown played a sound. The audio of the element is made then too, as the buttons of the game console press on pointerdown, where a touch cannot make it, like START, which plays the song in the music maker.
		const wakeSound = () => {
			this.sound();
			if (audio.isOn) {
				audio.context?.resume();
			}
		};

		this.on(this, 'pointerup', wakeSound);
		this.on(this, 'keydown', wakeSound);

		// The buttons are pressed by the pointer, and a click from a keyboard or a screen reader presses them too.
		for (const button of this.querySelectorAll('[data-gb-camera-button]')) {
			const name = button.dataset.gbCameraButton;
			this.on(button, 'pointerdown', event => {
				event.preventDefault();
				press(name);
			});
			this.on(button, 'click', event => {
				if (event.detail === 0) {
					press(name);
				}
			});
		}

		const keyButtons = {ArrowLeft: 'left', ArrowRight: 'right', ArrowUp: 'up', ArrowDown: 'down', x: 'a', X: 'a', ' ': 'a', z: 'b', Z: 'b', Enter: 'start', Backspace: 'select'};

		this.on(screen, 'keydown', event => {
			const name = keyButtons[event.key];
			if (!name || event.metaKey || event.ctrlKey || event.altKey) {
				return;
			}

			event.preventDefault();

			// Holding a button down does not run in the race.
			if (event.repeat && (state.mode === 'run' || name === 'a' || name === 'b')) {
				return;
			}

			press(name);
		});

		// The screen itself: a drag points the camera, and a tap picks, stamps, or plays.
		const musicCell = point => {
			const column = Math.floor((point.x - gridLeft) / cellWidth);
			if (column < 0 || column > 15) {
				return undefined;
			}

			for (let row = 0; row < 12; row++) {
				if (point.y >= rowTop(row) && point.y < rowTop(row) + rowHeight(row) + (row < 8 ? 0 : 1)) {
					return {row, column};
				}
			}

			return undefined;
		};

		this.on(screen, 'pointerdown', event => {
			const point = canvasPoint(screen, event);
			if (!state.isOn) {
				turnOn();
				return;
			}

			switch (state.mode) {
				case 'boot':
				case 'title': {
					press('start');
					break;
				}

				case 'menu': {
					const index = Math.floor((point.y - 24) / 21);
					if (index >= 0 && index < menuItems.length) {
						state.menuIndex = index;
						press('a');
					}

					break;
				}

				case 'shoot': {
					screen.setPointerCapture(event.pointerId);
					state.drag = {x: point.x, pan: state.pan};
					break;
				}

				case 'album': {
					if (point.x < width / 3) {
						flip(-1);
					} else if (point.x > (width * 2) / 3) {
						flip(1);
					} else {
						state.infoTime = 2;
						refresh();
					}

					break;
				}

				case 'stamps': {
					state.cursor.x = clamp(Math.round(point.x - photoX), 0, photoWidth - 1);
					state.cursor.y = clamp(Math.round(point.y - photoY), 0, photoHeight - 1);
					putStamp();
					break;
				}

				case 'music': {
					const cell = musicCell(point);
					if (cell) {
						music.cursor = cell;
						toggleCell(cell.row, cell.column);
					} else if (point.y < 12) {
						togglePlay();
					}

					refresh();
					break;
				}

				case 'run': {
					if (race.phase === 'running') {
						press(point.x < width / 2 ? 'b' : 'a');
					} else if (race.phase === 'ready' || (race.phase === 'finished' && performance.now() - race.finishedAt > 1500)) {
						// A tap right after the finish is the last of the mashing, so it does not start a new race before the result is seen.
						press('start');
					}

					break;
				}

				default: {
					break;
				}
			}
		});

		this.on(screen, 'pointermove', event => {
			const point = canvasPoint(screen, event);
			if (state.mode === 'shoot' && state.drag) {
				state.pan = state.drag.pan - (point.x - state.drag.x);
				state.autoPanPause = 3;
				refresh();
			} else if (state.mode === 'stamps' && event.pointerType === 'mouse') {
				state.cursor.x = clamp(Math.round(point.x - photoX), 0, photoWidth - 1);
				state.cursor.y = clamp(Math.round(point.y - photoY), 0, photoHeight - 1);
				refresh();
			}
		});

		const endDrag = () => {
			state.drag = undefined;
		};

		this.on(screen, 'pointerup', endDrag);
		this.on(screen, 'pointercancel', endDrag);

		colorsButton.textContent = `🎨 Colors: ${palette().name}`;
		setStamp(state.stamp);
		showPaperLeft();
		showRunBest();
		updateSceneButtons();
		updateAlbum();
		for (const sticker of stickers) {
			addStickerElement(sticker);
		}

		updateWall();
		setPaperOut(0);
		draw();

		// The overrides of the element use these.
		this.#refresh = refresh;
		this.#stopWebcam = stopWebcam;
		this.#stopMusic = stopMusic;
	}

	disconnected() {
		this.#stopWebcam();
		this.#stopMusic();
	}

	// The toy runs only while the window of the game console is on the screen, and not while only the wardrobe door below it is.
	get visibilityTarget() {
		return this.parts.handheld;
	}

	// The webcam and the song stop when the game console leaves the screen, also while the wardrobe door below it is still on the screen.
	visibilityChanged(isVisible) {
		if (!isVisible) {
			this.#stopWebcam('The webcam turned off, as the game console left the screen. Press “Use My Webcam” to turn it on again.');
			this.#stopMusic();
		}
	}

	reducedMotionChanged() {
		this.#refresh();
	}

	musicStopped() {
		this.#stopMusic();
		this.#refresh();
	}

	// A button that hides its own panel, like “⭐ Stamps” of the album, gives the focus to the button of the mode that is shown now, so the keyboard goes on from there.
	focusReplacement(control) {
		const modeButton = this.querySelector('[data-gb-camera-mode][aria-pressed="true"]');
		return control.closest('[data-gb-camera-panel]') && modeButton ? modeButton : super.focusReplacement(control);
	}
}
