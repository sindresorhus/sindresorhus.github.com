// My room on the 1999 page, as a QuickTime VR panorama with a Polaroid camera. The shared toys of `geocities.js`, like Glitter, are used through events on the document.
const randomItem = items => items[Math.floor(Math.random() * items.length)];
const clamp = (value, minimum, maximum) => Math.min(Math.max(value, minimum), maximum);
const plural = (count, word) => `${count.toLocaleString('en-US')} ${word}${count === 1 ? '' : 's'}`;

// Shows a toggle button as pressed, for screen readers and for the style.
const setPressed = (button, isPressed) => {
	button.setAttribute('aria-pressed', String(isPressed));
	button.dataset.state = isPressed ? 'on' : '';
};

// Scrolls to a section and focuses it, like a link to it, so the keyboard goes on from there.
const goTo = (element, isReduced) => {
	element.scrollIntoView({behavior: isReduced ? 'auto' : 'smooth', block: 'start'});
	element.focus({preventScroll: true});
};

// The position of a pointer on a canvas, in the pixels of the canvas.
const canvasPoint = (canvas, event) => {
	const rectangle = canvas.getBoundingClientRect();
	return {
		x: (event.clientX - rectangle.left) * canvas.width / rectangle.width,
		y: (event.clientY - rectangle.top) * canvas.height / rectangle.height,
	};
};

// A tiny pixel font of 3 × 5 for the labels of the room, so the text is crisp at any size. Each letter is five rows of three bits.
const pixelFont = {
	A: [2, 5, 7, 5, 5], B: [6, 5, 6, 5, 6], C: [3, 4, 4, 4, 3], D: [6, 5, 5, 5, 6], E: [7, 4, 6, 4, 7], F: [7, 4, 6, 4, 4], G: [3, 4, 5, 5, 3], H: [5, 5, 7, 5, 5], I: [7, 2, 2, 2, 7], J: [1, 1, 1, 5, 2], K: [5, 5, 6, 5, 5], L: [4, 4, 4, 4, 7], M: [5, 7, 7, 5, 5], N: [6, 5, 5, 5, 5], O: [2, 5, 5, 5, 2], P: [6, 5, 6, 4, 4], Q: [2, 5, 5, 6, 3], R: [6, 5, 6, 5, 5], S: [3, 4, 2, 1, 6], T: [7, 2, 2, 2, 2], U: [5, 5, 5, 5, 7], V: [5, 5, 5, 5, 2], W: [5, 5, 7, 7, 5], X: [5, 5, 2, 5, 5], Y: [5, 5, 2, 2, 2], Z: [7, 1, 2, 4, 7],
	0: [7, 5, 5, 5, 7], 1: [2, 6, 2, 2, 7], 2: [6, 1, 2, 4, 7], 3: [6, 1, 2, 1, 6], 4: [5, 5, 7, 1, 1], 5: [7, 4, 6, 1, 6], 6: [3, 4, 7, 5, 7], 7: [7, 1, 2, 2, 2], 8: [7, 5, 7, 5, 7], 9: [7, 5, 7, 1, 6],
	' ': [0, 0, 0, 0, 0], '.': [0, 0, 0, 0, 2], ',': [0, 0, 0, 2, 4], '!': [2, 2, 2, 0, 2], '?': [6, 1, 2, 0, 2], ':': [0, 2, 0, 2, 0], '-': [0, 0, 7, 0, 0], '+': [0, 2, 7, 2, 0], '/': [1, 1, 2, 4, 4], '\'': [2, 2, 0, 0, 0], '(': [1, 2, 2, 2, 1], ')': [4, 2, 2, 2, 4], '×': [0, 5, 2, 5, 0], '°': [2, 5, 2, 0, 0], '%': [5, 1, 2, 4, 5], '<': [1, 2, 4, 2, 1], '>': [4, 2, 1, 2, 4], '=': [0, 7, 0, 7, 0], '♥': [0, 5, 7, 7, 2], '*': [0, 5, 2, 5, 0],
	Æ: [3, 6, 7, 6, 7], Ø: [3, 5, 7, 5, 6], Å: [2, 0, 2, 5, 7],
};

// Draws text in the pixel font, at a whole pixel, with a scale for bigger letters. The alignment is `left`, `center`, or `right`.
const drawPixelText = (context, text, x, y, color, {scale = 1, align = 'left'} = {}) => {
	const characters = [...String(text).toUpperCase()];
	const width = ((characters.length * 4) - 1) * scale;
	let left = Math.round(align === 'center' ? x - (width / 2) : (align === 'right' ? x - width : x));
	context.fillStyle = color;

	for (const character of characters) {
		const rows = pixelFont[character] ?? pixelFont['?'];
		for (const [row, bits] of rows.entries()) {
			for (let column = 0; column < 3; column++) {
				if (bits & (4 >> column)) {
					context.fillRect(left + (column * scale), Math.round(y) + (row * scale), scale, scale);
				}
			}
		}

		left += 4 * scale;
	}
};

const pixelTextWidth = (text, scale = 1) => (([...String(text)].length * 4) - 1) * scale;

// A canvas that is not on the page, for drawing in layers.
const makeCanvas = (width, height) => {
	const canvas = document.createElement('canvas');
	canvas.width = width;
	canvas.height = height;
	return canvas;
};

// My room as a QuickTime VR panorama: a picture of the whole room, 360° around, which is bent for each column of the view like a cylinder, so the walls look straight, like the panoramas of QuickTime VR (1995). The mouse turns the room the way QuickTime VR did: hold it down, and the further it moves from where it was pressed, the faster the room turns. A finger drags the room instead, as it would on a phone. The things in the room are hot spots: some do something in the room, and the rest lead to the toys further down the page. The Polaroid camera takes a picture of what the view shows.
const setUpPanorama = (room, {view, flash, status}) => {
	const viewContext = view.getContext('2d');

	// The picture of the room is 1,200 × 240 pixels, so each wall is 300 pixels wide: the desk, the window, the bunk bed, and the door.
	const width = 1200;
	const height = 240;
	const base = makeCanvas(width, height);
	const texture = makeCanvas(width, height);
	const textureContext = texture.getContext('2d');

	const state = {
		yaw: 150,
		pitch: 120,
		zoom: 1.25,
		isLightOn: true,
		isHelloScreen: false,
		isLavaOn: true,
		showsHotspots: false,
		sunUntil: 0,
		doorUntil: 0,
		hopUntil: 0,
		momLine: '',
		rainDays: 47,
	};

	// The things in the room, in the pixels of the picture.
	const hotspots = {
		imac: {x: 108, y: 66, width: 82, height: 70},
		poster: {x: 34, y: 38, width: 64, height: 72},
		lava: {x: 212, y: 88, width: 22, height: 46},
		music: {x: 66, y: 114, width: 40, height: 20},
		polaroid: {x: 240, y: 112, width: 30, height: 22},
		raincoat: {x: 310, y: 46, width: 42, height: 150},
		window: {x: 368, y: 34, width: 166, height: 116},
		calendar: {x: 548, y: 56, width: 40, height: 56},
		stars: {x: 616, y: 14, width: 250, height: 40},
		plush: {x: 676, y: 52, width: 50, height: 32},
		handheld: {x: 696, y: 134, width: 26, height: 22},
		bed: {x: 630, y: 170, width: 190, height: 24},
		bucket: {x: 866, y: 166, width: 30, height: 32},
		door: {x: 928, y: 44, width: 86, height: 150},
		lights: {x: 1016, y: 106, width: 18, height: 24},
		backpack: {x: 1026, y: 156, width: 40, height: 42},
		lego: {x: 1044, y: 56, width: 136, height: 100},
		skis: {x: 1176, y: 24, width: 24, height: 170},
	};

	const names = Object.fromEntries([...room.querySelectorAll('[data-room-hotspot]')].map(button => [button.dataset.roomHotspot, button.textContent.trim()]));

	const fill = (context, color, x, y, width, height) => {
		context.fillStyle = color;
		context.fillRect(x, y, width, height);
	};

	const ellipse = (context, color, x, y, radiusX, radiusY) => {
		context.fillStyle = color;
		context.beginPath();
		context.ellipse(x, y, radiusX, radiusY, 0, 0, Math.PI * 2);
		context.fill();
	};

	const polygon = (context, color, points) => {
		context.fillStyle = color;
		context.beginPath();
		for (const [x, y] of points) {
			context.lineTo(x, y);
		}

		context.closePath();
		context.fill();
	};

	const star = (context, color, x, y, radius) => {
		const points = [];
		for (let index = 0; index < 10; index++) {
			const angle = (index * Math.PI / 5) - (Math.PI / 2);
			const length = index % 2 === 0 ? radius : radius * 0.45;
			points.push([x + (Math.cos(angle) * length), y + (Math.sin(angle) * length)]);
		}

		polygon(context, color, points);
	};

	// The stars on the wall over the bunk bed, which glow in the dark.
	const glowStars = Array.from({length: 22}, (_, index) => ({
		x: 624 + ((index * 113) % 236),
		y: 18 + ((index * 37) % 32),
		radius: 2 + (index % 3),
	}));

	// The parts of the room that never change. The things that move or change are drawn on top for each frame.
	const drawRoom = context => {
		// The ceiling, the wallpaper with its border of stars, the baseboard, and the wooden floor.
		fill(context, '#e8e4dc', 0, 0, width, 14);
		fill(context, '#bcd4ea', 0, 14, width, 174);
		fill(context, '#1d3a78', 0, 22, width, 10);
		for (let x = 4; x < width; x += 12) {
			star(context, '#ffd84a', x, 27, 3);
		}

		fill(context, '#f4f1ea', 0, 184, width, 8);
		fill(context, '#a8723f', 0, 192, width, 48);
		for (let y = 196; y < height; y += 8) {
			fill(context, '#8f5f31', 0, y, width, 1);
		}

		for (let x = 0; x < width; x += 37) {
			fill(context, '#8f5f31', x, 192 + ((x * 7) % 40), 1, 8);
		}

		// The corners of the room are darker, like in the light of a ceiling lamp.
		for (const corner of [0, 300, 600, 900, 1200]) {
			const gradient = context.createLinearGradient(corner - 40, 0, corner + 40, 0);
			gradient.addColorStop(0, 'rgba(0, 0, 40, 0)');
			gradient.addColorStop(0.5, 'rgba(0, 0, 40, 0.22)');
			gradient.addColorStop(1, 'rgba(0, 0, 40, 0)');
			context.fillStyle = gradient;
			context.fillRect(corner - 40, 14, 80, 226);
			fill(context, 'rgba(0, 0, 40, 0.25)', corner - 1, 14, 2, 178);
		}

		// The desk wall: the unicorn poster, the desk, the lamp, the drawers, and the waste basket.
		fill(context, '#ffffff', 34, 38, 64, 72);
		fill(context, '#5b2a86', 38, 42, 56, 52);
		star(context, '#ffffff', 46, 50, 2);
		star(context, '#ffffff', 58, 46, 1.5);
		star(context, '#ffe066', 86, 80, 1.5);
		for (const [index, color] of ['#ff4444', '#ffaa33', '#ffee44', '#44dd66', '#4499ff'].entries()) {
			fill(context, color, 38, 86 + (index * 1.6), 56, 1.6);
		}

		// The unicorn of the poster, jumping over the rainbow.
		ellipse(context, '#ffffff', 60, 72, 12, 6);
		polygon(context, '#ffffff', [[66, 69], [74, 58], [79, 61], [72, 72]]);
		ellipse(context, '#ffffff', 79, 59, 5, 4);
		polygon(context, '#ffd700', [[80, 55], [87, 45], [82, 56]]);
		polygon(context, '#ff7ac8', [[70, 60], [75, 56], [72, 68], [67, 70]]);
		polygon(context, '#ff7ac8', [[48, 70], [41, 66], [44, 76]]);
		ellipse(context, '#222222', 80, 58, 0.8, 0.8);
		fill(context, '#ffffff', 52, 76, 3, 7);
		fill(context, '#ffffff', 66, 76, 3, 7);
		polygon(context, '#ffffff', [[48, 75], [44, 80], [47, 81], [51, 76]]);
		polygon(context, '#ffffff', [[70, 74], [76, 78], [74, 80], [68, 76]]);
		drawPixelText(context, 'UNICORNS', 66, 99, '#5b2a86', {align: 'center'});

		fill(context, '#d4a86a', 18, 132, 264, 6);
		fill(context, '#b88a50', 18, 138, 264, 3);
		fill(context, '#a87a44', 24, 141, 6, 46);
		fill(context, '#c49660', 214, 141, 64, 46);
		for (const y of [146, 160, 174]) {
			fill(context, '#b4864f', 218, y, 56, 11);
			fill(context, '#e8d4a8', 243, y + 4, 6, 3);
		}

		fill(context, '#555b66', 166, 168, 26, 22);
		fill(context, '#6b7380', 164, 166, 30, 4);

		// The desk lamp, red, bent over the desk.
		fill(context, '#cc2222', 34, 126, 22, 6);
		fill(context, '#888888', 43, 112, 3, 14);
		fill(context, '#888888', 44, 110, 14, 3);
		polygon(context, '#cc2222', [[54, 108], [68, 108], [74, 120], [48, 120]]);
		ellipse(context, '#fff6c0', 61, 120, 9, 1.5);

		// The iMac in Bondi Blue, see-through, with the white front, the keyboard, and the round mouse.
		const imac = context.createLinearGradient(108, 66, 190, 136);
		imac.addColorStop(0, '#5fd0de');
		imac.addColorStop(0.5, '#1a9fb3');
		imac.addColorStop(1, '#127a8a');
		context.fillStyle = imac;
		context.beginPath();
		context.roundRect(110, 68, 78, 62, [14, 14, 8, 8]);
		context.fill();
		fill(context, '#e6f2f2', 116, 72, 66, 50);
		fill(context, '#22303a', 120, 76, 58, 42);
		fill(context, '#0e6f7e', 134, 124, 30, 2);
		fill(context, '#127a8a', 140, 130, 18, 3);
		fill(context, '#77d6e2', 120, 128, 58, 4);
		for (let x = 122; x < 176; x += 4) {
			fill(context, '#c8eef3', x, 129, 2, 1);
		}

		ellipse(context, '#1a9fb3', 192, 131, 5, 2.5);

		// The Discman with the headphones, and the Polaroid camera.
		ellipse(context, '#bfc4cc', 80, 128, 13, 4);
		ellipse(context, '#8f96a3', 80, 128, 5, 1.6);
		context.strokeStyle = '#333333';
		context.lineWidth = 2;
		context.beginPath();
		context.arc(99, 126, 6, Math.PI, 0);
		context.stroke();
		fill(context, '#333333', 92, 124, 3, 5);
		fill(context, '#333333', 103, 124, 3, 5);

		fill(context, '#1e1e1e', 242, 116, 26, 16);
		fill(context, '#2a2a2a', 244, 112, 22, 4);
		for (const [index, color] of ['#e8313a', '#f7941d', '#ffde17', '#3ab54a', '#1b75bc'].entries()) {
			fill(context, color, 242, 118 + index, 26, 1);
		}

		ellipse(context, '#556688', 255, 126, 4, 4);
		ellipse(context, '#99aadd', 254, 125, 1.5, 1.5);

		// The lava lamp: the silver base and the cap. The glass is drawn for each frame.
		polygon(context, '#b8bcc4', [[212, 132], [234, 132], [228, 120], [218, 120]]);
		polygon(context, '#9ca0a8', [[218, 92], [228, 92], [226, 86], [220, 86]]);

		// The window wall: the rain gear on a hook, the curtains, the radiator, and the calendar.
		fill(context, '#6b4a2a', 318, 48, 30, 4);
		polygon(context, '#ffd21f', [[322, 56], [344, 56], [352, 136], [314, 136]]);
		fill(context, '#e6b800', 332, 56, 2, 80);
		fill(context, '#e6b800', 314, 132, 38, 4);
		ellipse(context, '#ffd21f', 333, 52, 12, 5);
		ellipse(context, '#e6b800', 333, 48, 7, 4);
		fill(context, '#2a7a3a', 316, 170, 12, 22);
		fill(context, '#2a7a3a', 334, 170, 12, 22);
		fill(context, '#1d5a2a', 314, 188, 16, 5);
		fill(context, '#1d5a2a', 332, 188, 16, 5);

		fill(context, '#f4f4f4', 380, 38, 140, 104);
		fill(context, '#e2ddd0', 376, 140, 148, 6);
		for (const [left, right] of [[364, 386], [514, 536]]) {
			for (let x = left; x < right; x += 4) {
				fill(context, (x / 4) % 2 === 0 ? '#e0533a' : '#f6d7a8', x, 32, 4, 118);
			}
		}

		fill(context, '#8a5a2a', 360, 30, 180, 4);
		fill(context, '#2f8f3f', 492, 128, 3, 12);
		ellipse(context, '#2f8f3f', 494, 128, 4, 6);
		fill(context, '#c0522a', 488, 134, 12, 6);

		fill(context, '#f0f0f0', 398, 152, 104, 30);
		for (let x = 400; x < 500; x += 6) {
			fill(context, '#d4d4d4', x, 154, 3, 26);
		}

		fill(context, '#ffffff', 550, 58, 36, 52);
		fill(context, '#cc2222', 550, 58, 36, 12);
		drawPixelText(context, 'MAI 1999', 568, 62, '#ffffff', {align: 'center'});
		for (let day = 0; day < 31; day++) {
			fill(context, '#999999', 553 + ((day % 7) * 4.6), 74 + (Math.floor(day / 7) * 7), 3, 3);
		}

		context.strokeStyle = '#dd0000';
		context.lineWidth = 1.5;
		context.beginPath();
		context.ellipse(570, 88, 4, 3.5, 0, 0, Math.PI * 2);
		context.stroke();

		// The bunk bed, with the ladder, the duvets, and the dark space under it.
		fill(context, '#1e1610', 630, 170, 190, 22);
		ellipse(context, '#4a3a2a', 700, 186, 10, 4);
		fill(context, '#8b5a2b', 620, 44, 8, 148);
		fill(context, '#8b5a2b', 852, 44, 8, 148);
		fill(context, '#8b5a2b', 628, 60, 224, 5);
		fill(context, '#8b5a2b', 628, 96, 224, 6);
		fill(context, '#8b5a2b', 628, 166, 224, 6);
		for (let x = 628; x < 852; x += 12) {
			for (let y = 80; y < 96; y += 8) {
				fill(context, (((x - 628) / 12) + ((y - 80) / 8)) % 2 === 0 ? '#3a6fd0' : '#ffffff', x, y, 12, 8);
			}
		}

		fill(context, '#ffffff', 630, 72, 34, 8);
		for (let x = 628; x < 852; x += 12) {
			for (let y = 146; y < 166; y += 10) {
				fill(context, (((x - 628) / 12) + ((y - 146) / 10)) % 2 === 0 ? '#e04848' : '#ffe8c8', x, y, 12, 10);
			}
		}

		fill(context, '#ffffff', 630, 138, 36, 10);
		fill(context, '#a06a35', 818, 64, 4, 128);
		fill(context, '#a06a35', 842, 64, 4, 128);
		for (let y = 76; y < 190; y += 18) {
			fill(context, '#a06a35', 818, y, 28, 3);
		}

		// My handheld game console on the bed.
		fill(context, '#6a4fa3', 702, 138, 14, 18);
		fill(context, '#2b2b38', 704, 140, 10, 8);
		fill(context, '#9bd06a', 705, 141, 8, 6);
		fill(context, '#2b2b38', 704, 151, 3, 2);
		ellipse(context, '#c8c8d8', 712, 152, 1.5, 1.5);

		// The rug, the comics, and the bucket for crabs.
		ellipse(context, '#c03848', 740, 220, 90, 14);
		ellipse(context, '#f2c84b', 740, 220, 70, 10);
		ellipse(context, '#3a6fd0', 740, 220, 50, 6);
		fill(context, '#8b5a2b', 866, 120, 30, 3);
		for (const [index, color] of ['#e33', '#fd3', '#3c3', '#36f', '#f80', '#e33', '#93f'].entries()) {
			fill(context, color, 867 + (index * 4), 104, 3, 16);
		}

		polygon(context, '#d42a2a', [[868, 172], [894, 172], [890, 196], [872, 196]]);
		fill(context, '#ff5a5a', 868, 172, 26, 3);
		context.strokeStyle = '#555555';
		context.lineWidth = 1;
		context.beginPath();
		context.arc(881, 174, 10, Math.PI, 0);
		context.stroke();
		ellipse(context, '#e0602a', 880, 168, 5, 3);

		// The door wall: the door with its sign, the school bag, the LEGO shelf, the flag, and the skis.
		fill(context, '#c99a5e', 930, 46, 80, 146);
		fill(context, '#b8894f', 938, 56, 64, 54);
		fill(context, '#b8894f', 938, 120, 64, 64);
		fill(context, '#f4f1ea', 926, 42, 88, 4);
		fill(context, '#f4f1ea', 926, 42, 4, 150);
		fill(context, '#f4f1ea', 1010, 42, 4, 150);
		ellipse(context, '#d8c070', 1000, 122, 3, 3);
		fill(context, '#ffffff', 946, 66, 48, 26);
		drawPixelText(context, 'INGEN', 970, 68, '#d00000', {align: 'center'});
		drawPixelText(context, 'ADGANG!', 970, 75, '#d00000', {align: 'center'});
		drawPixelText(context, '(MAMMA OK)', 970, 83, '#333333', {align: 'center'});

		fill(context, '#c81e2e', 1030, 162, 32, 30);
		fill(context, '#a01020', 1030, 160, 32, 6);
		fill(context, '#e8e8e8', 1030, 176, 32, 3);
		fill(context, '#ffd21f', 1038, 168, 16, 6);

		for (const y of [84, 116, 148]) {
			fill(context, '#e6d2a8', 1046, y, 132, 4);
		}

		// The LEGO on the shelf: a spaceship, a castle, a pirate ship, and the boxes.
		fill(context, '#9aa0a8', 1056, 74, 40, 10);
		fill(context, '#0055bf', 1062, 70, 28, 4);
		polygon(context, '#f2cd37', [[1070, 70], [1082, 70], [1080, 64], [1072, 64]]);
		fill(context, '#c91a09', 1050, 78, 6, 4);
		fill(context, '#c91a09', 1096, 78, 6, 4);
		fill(context, '#2a2a2a', 1110, 74, 10, 10);
		fill(context, '#a0a5a9', 1124, 66, 10, 18);
		fill(context, '#a0a5a9', 1138, 66, 10, 18);
		fill(context, '#a0a5a9', 1124, 74, 24, 10);
		fill(context, '#c91a09', 1152, 78, 22, 6);
		fill(context, '#6b4a2a', 1056, 106, 50, 10);
		polygon(context, '#6b4a2a', [[1052, 104], [1110, 104], [1104, 110], [1058, 110]]);
		fill(context, '#3a2a1a', 1080, 88, 2, 18);
		fill(context, '#f4f4f4', 1072, 90, 18, 10);
		fill(context, '#2a2a2a', 1080, 86, 8, 4);
		for (const [index, color] of ['#0055bf', '#c91a09', '#f2cd37', '#237841'].entries()) {
			fill(context, color, 1116 + (index * 15), 98 + (index % 2), 13, 18 - (index % 2));
			fill(context, '#ffffff', 1118 + (index * 15), 102, 9, 4);
		}

		for (const [index, color] of ['#c91a09', '#f2cd37', '#0055bf', '#237841', '#ffffff', '#2a2a2a', '#c91a09', '#f2cd37', '#0055bf'].entries()) {
			fill(context, color, 1050 + ((index % 5) * 12) + (index > 4 ? 6 : 0), 140 - (index > 4 ? 6 : 0), 10, 6);
		}

		fill(context, '#8a5a2a', 1128, 140, 2, 8);
		fill(context, '#ba0c2f', 1130, 126, 14, 10);
		fill(context, '#ffffff', 1133, 126, 3, 10);
		fill(context, '#ffffff', 1130, 130, 14, 2);
		fill(context, '#00205b', 1134, 126, 1, 10);
		fill(context, '#00205b', 1130, 131, 14, 1);
		fill(context, '#ffd21f', 1150, 134, 18, 14);
		drawPixelText(context, 'LEGO', 1159, 138, '#c91a09', {align: 'center'});

		// The skis and the poles in the corner, by the wall of the desk.
		polygon(context, '#d42a2a', [[1182, 24], [1186, 24], [1194, 192], [1190, 192]]);
		polygon(context, '#2a5ad4', [[1188, 22], [1192, 22], [1199, 190], [1195, 190]]);
		fill(context, '#444444', 1178, 60, 2, 132);
		fill(context, '#444444', 1183, 60, 2, 132);
	};

	drawRoom(base.getContext('2d'));

	// The window: the view of Bergen, with the mountain, the wooden houses of Bryggen, and the rain, or the sun for a moment, or the night.
	const drawWindow = (context, time) => {
		const isSunny = time < state.sunUntil;
		const isNight = !state.isLightOn;
		const left = 384;
		const top = 42;
		const right = 516;
		const bottom = 138;
		context.save();
		context.beginPath();
		context.rect(left, top, right - left, bottom - top);
		context.clip();
		fill(context, isNight ? '#0b1430' : (isSunny ? '#7ec8ff' : '#8e9aa6'), left, top, right - left, bottom - top);
		if (isSunny) {
			ellipse(context, '#ffe066', 492, 58, 9, 9);
		}

		polygon(context, isNight ? '#0a1a14' : '#2d5a3a', [[left, 96], [410, 70], [440, 62], [470, 74], [500, 66], [right, 80], [right, bottom], [left, bottom]]);
		const houses = ['#b8312f', '#f2c14e', '#efe9df', '#d9792b', '#b8312f', '#f2c14e', '#efe9df'];
		for (const [index, color] of houses.entries()) {
			const x = left + 2 + (index * 19);
			polygon(context, isNight ? '#2a2018' : color, [[x, 112], [x + 8, 100], [x + 17, 112], [x + 17, 130], [x, 130]]);
			for (const [windowX, windowY] of [[x + 3, 115], [x + 10, 115], [x + 3, 122], [x + 10, 122]]) {
				fill(context, isNight ? ((index + windowX) % 3 === 0 ? '#2a2018' : '#ffd86a') : '#3a3a4a', windowX, windowY, 3, 4);
			}
		}

		fill(context, isNight ? '#05101e' : '#3a5a72', left, 130, right - left, 8);

		// The rain falls in streaks, unless the sun is out for a moment. It stands still for visitors who prefer reduced motion.
		if (!isSunny) {
			context.fillStyle = isNight ? 'rgba(160, 180, 255, 0.45)' : 'rgba(230, 240, 255, 0.7)';
			const offset = room.reducedMotion ? 0 : time * 0.12;
			for (let index = 0; index < 46; index++) {
				const x = left + ((index * 53) % (right - left));
				const y = top + ((((index * 29) + offset) % (bottom - top + 20)) - 10);
				context.fillRect(x, y, 1, 6);
				context.fillRect(x - 1, y + 6, 1, 3);
			}
		}

		context.restore();
		fill(context, '#f4f4f4', 448, 38, 4, 104);
		fill(context, '#f4f4f4', 380, 88, 140, 4);
	};

	// The screen of the iMac, which shows the desktop of Mac OS 8, or “hello (again)”, like on the ads for the iMac.
	const drawScreen = context => {
		if (state.isHelloScreen) {
			fill(context, '#ffffff', 120, 76, 58, 42);
			context.fillStyle = '#1a1a1a';
			context.font = 'italic 11px Georgia, serif';
			context.textAlign = 'center';
			context.fillText('hello', 149, 95);
			context.fillText('(again)', 149, 107);
		} else {
			fill(context, '#6b72b8', 120, 76, 58, 42);
			fill(context, '#e8e8e8', 120, 76, 58, 4);
			fill(context, '#f0f0f0', 166, 84, 8, 7);
			fill(context, '#f0f0f0', 166, 96, 8, 7);
			fill(context, '#ffffff', 126, 88, 30, 22);
			fill(context, '#9999cc', 126, 88, 30, 3);
			fill(context, '#1084d0', 129, 94, 10, 2);
			fill(context, '#c8c8c8', 129, 98, 22, 1);
			fill(context, '#c8c8c8', 129, 101, 18, 1);
		}
	};

	// The glass of the lava lamp, with the wax that rises and falls while it is on. It stands still for visitors who prefer reduced motion.
	const drawLavaLamp = (context, time) => {
		polygon(context, state.isLavaOn ? '#ffcf3a' : '#9a8a5a', [[218, 92], [228, 92], [234, 120], [212, 120]]);
		if (!state.isLavaOn) {
			ellipse(context, '#8a3a2a', 223, 117, 9, 4);
			return;
		}

		const seconds = room.reducedMotion ? 2 : time / 1000;
		for (let index = 0; index < 3; index++) {
			const phase = (Math.sin((seconds * 0.4) + (index * 2.1)) + 1) / 2;
			const y = 116 - (phase * 22);
			const x = 223 + (Math.sin((seconds * 0.7) + index) * 2);
			ellipse(context, '#e8352a', x, y, 2.5 + (index % 2), 3 + (index % 2));
		}

		ellipse(context, '#e8352a', 223, 119, 9, 2);
	};

	// The unicorn plush on the top bunk. It hops when it is clicked, unless the visitor prefers reduced motion.
	const drawPlush = (context, time) => {
		const hop = time < state.hopUntil && !room.reducedMotion ? Math.abs(Math.sin((state.hopUntil - time) / 90)) * 8 : 0;
		const y = 70 - hop;
		ellipse(context, '#ffffff', 700, y, 16, 9);
		ellipse(context, '#ffffff', 714, y - 9, 7, 7);
		polygon(context, '#ffd700', [[716, y - 15], [722, y - 27], [719, y - 14]]);
		fill(context, '#ff7ac8', 706, y - 16, 4, 12);
		fill(context, '#ff7ac8', 684, y - 4, 4, 8);
		ellipse(context, '#222222', 716, y - 10, 1.2, 1.2);
		ellipse(context, '#ffb0d0', 718, y - 6, 2, 1.2);
		fill(context, '#ffffff', 690, y + 6, 4, 6);
		fill(context, '#ffffff', 706, y + 6, 4, 6);
	};

	// The door, which Mom opens, with the light of the hall behind her.
	const drawDoor = (context, time) => {
		if (time >= state.doorUntil) {
			return;
		}

		fill(context, state.isLightOn ? '#3a2a1a' : '#fff1b8', 930, 46, 30, 146);
		polygon(context, '#b8894f', [[960, 46], [1010, 40], [1010, 198], [960, 192]]);
		ellipse(context, '#d8c070', 1004, 122, 3, 3);
		fill(context, '#3a6fd0', 934, 104, 24, 88);
		ellipse(context, '#7a4a2a', 944, 88, 12, 14);
		ellipse(context, '#f3c9a0', 946, 92, 9, 11);
		fill(context, '#222222', 942, 89, 2, 2);
		fill(context, '#222222', 950, 89, 2, 2);
		fill(context, '#b04040', 944, 97, 6, 2);
	};

	// The light switch, up when the light is on.
	const drawSwitch = context => {
		fill(context, '#f8f8f8', 1018, 110, 12, 18);
		fill(context, '#cccccc', 1018, 110, 12, 1);
		fill(context, '#c8c8c8', 1021, state.isLightOn ? 112 : 120, 6, 6);
	};

	// The glow of the things that give light in the dark.
	const glow = (context, x, y, radius, color) => {
		const gradient = context.createRadialGradient(x, y, 0, x, y, radius);
		gradient.addColorStop(0, color);
		gradient.addColorStop(1, 'rgba(0, 0, 0, 0)');
		context.fillStyle = gradient;
		context.fillRect(x - radius, y - radius, radius * 2, radius * 2);
	};

	// Draws the room for a moment: the parts that never change, the parts that change, and the dark when the light is off, with the glow stars, the screen, and the lava lamp, which give light.
	const updateTexture = time => {
		textureContext.drawImage(base, 0, 0);
		drawPlush(textureContext, time);
		drawSwitch(textureContext);

		if (state.isLightOn) {
			for (const glowStar of glowStars) {
				star(textureContext, '#f4f0c8', glowStar.x, glowStar.y, glowStar.radius);
			}
		} else {
			textureContext.globalCompositeOperation = 'multiply';
			fill(textureContext, '#2b3264', 0, 0, width, height);
			textureContext.globalCompositeOperation = 'source-over';
			glow(textureContext, 149, 97, 60, 'rgba(120, 140, 255, 0.35)');
			if (state.isLavaOn) {
				glow(textureContext, 223, 106, 34, 'rgba(255, 90, 40, 0.4)');
			}

			for (const glowStar of glowStars) {
				glow(textureContext, glowStar.x, glowStar.y, glowStar.radius * 3, 'rgba(170, 255, 140, 0.5)');
				star(textureContext, '#d8ffb0', glowStar.x, glowStar.y, glowStar.radius);
			}
		}

		drawWindow(textureContext, time);
		drawScreen(textureContext);
		drawLavaLamp(textureContext, time);
		drawDoor(textureContext, time);
	};

	// The view: the columns of the room around the direction it looks in, each scaled like on the inside of a cylinder.
	const focal = () => state.zoom * width / (Math.PI * 2);
	const halfAngle = () => Math.atan((view.width / 2) / focal());
	const wrap = x => ((x % width) + width) % width;

	// The limits, so the view never shows past the ceiling or the floor.
	const clampView = () => {
		state.zoom = clamp(state.zoom, 1.15, 2.6);
		const half = view.height / 2 / state.zoom;
		state.pitch = clamp(state.pitch, half, height - half);
		state.yaw = wrap(state.yaw);
	};

	// Where a point of the room is in the view, or nothing when it is out of view.
	const project = (x, y) => {
		const delta = wrap(x - state.yaw + (width / 2)) - (width / 2);
		const angle = delta * Math.PI * 2 / width;
		if (Math.abs(angle) >= halfAngle() + 0.2) {
			return undefined;
		}

		return {
			x: (view.width / 2) + (focal() * Math.tan(angle)),
			y: (view.height / 2) + ((y - state.pitch) * state.zoom / Math.cos(angle)),
		};
	};

	// The point of the room at a point of the view.
	const unproject = (x, y) => {
		const angle = Math.atan((x - (view.width / 2)) / focal());
		return {
			x: wrap(state.yaw + (angle * width / (Math.PI * 2))),
			y: state.pitch + ((y - (view.height / 2)) * Math.cos(angle) / state.zoom),
		};
	};

	const hotspotAt = (x, y) => {
		const point = unproject(x, y);
		return Object.entries(hotspots).find(([, spot]) => wrap(point.x - spot.x) < spot.width && point.y >= spot.y && point.y < spot.y + spot.height)?.[0];
	};

	// Draws the view, and the hot spots as blue boxes when they are shown, like the hot spot button of QuickTime VR.
	const render = (time = performance.now()) => {
		clampView();
		updateTexture(time);
		viewContext.imageSmoothingEnabled = false;
		fill(viewContext, '#000000', 0, 0, view.width, view.height);
		const focalLength = focal();
		for (let column = 0; column < view.width; column++) {
			const angle = Math.atan((column + 0.5 - (view.width / 2)) / focalLength);
			const sourceX = Math.floor(wrap(state.yaw + (angle * width / (Math.PI * 2))));
			const scale = state.zoom / Math.cos(angle);
			const top = (view.height / 2) - (state.pitch * scale);
			viewContext.drawImage(texture, sourceX, 0, 1, height, column, top, 1, height * scale);
		}

		if (state.showsHotspots) {
			viewContext.strokeStyle = 'rgba(80, 120, 255, 0.95)';
			viewContext.fillStyle = 'rgba(80, 120, 255, 0.25)';
			viewContext.lineWidth = 2;
			for (const [id, spot] of Object.entries(hotspots)) {
				const topLeft = project(spot.x, spot.y);
				const bottomRight = project(spot.x + spot.width, spot.y + spot.height);
				if (topLeft && bottomRight && bottomRight.x > topLeft.x) {
					viewContext.fillStyle = 'rgba(80, 120, 255, 0.25)';
					viewContext.fillRect(topLeft.x, topLeft.y, bottomRight.x - topLeft.x, bottomRight.y - topLeft.y);
					viewContext.strokeRect(topLeft.x, topLeft.y, bottomRight.x - topLeft.x, bottomRight.y - topLeft.y);
					const label = names[id] ?? id;
					fill(viewContext, 'rgba(0, 0, 80, 0.8)', topLeft.x + 1, topLeft.y + 1, pixelTextWidth(label) + 4, 9);
					drawPixelText(viewContext, label, topLeft.x + 3, topLeft.y + 3, '#ffffff');
				}
			}
		}
	};

	// What moves the view: the mouse held down, a finger, the keys held down, and the turn to a thing.
	const input = {
		pointer: undefined,
		keys: new Set(),
		turn: undefined,
	};

	const isMoving = () => input.pointer !== undefined || input.keys.size > 0 || input.turn !== undefined;

	const step = seconds => {
		if (input.pointer?.type === 'mouse' && input.pointer.hasMoved) {
			// Like QuickTime VR: the further the mouse is from where it was pressed, the faster the room turns.
			state.yaw += (input.pointer.x - input.pointer.startX) / (view.width / 2) * 420 * seconds;
			state.pitch += (input.pointer.y - input.pointer.startY) / (view.height / 2) * 110 * seconds;
		}

		const keySpeed = 260 * seconds;
		for (const key of input.keys) {
			if (key === 'ArrowLeft') {
				state.yaw -= keySpeed;
			} else if (key === 'ArrowRight') {
				state.yaw += keySpeed;
			} else if (key === 'ArrowUp') {
				state.pitch -= keySpeed / 3;
			} else if (key === 'ArrowDown') {
				state.pitch += keySpeed / 3;
			}
		}

		if (input.turn) {
			input.turn.progress = Math.min(input.turn.progress + (seconds / 0.6), 1);
			const eased = 1 - ((1 - input.turn.progress) ** 3);
			state.yaw = input.turn.fromYaw + (input.turn.deltaYaw * eased);
			state.pitch = input.turn.fromPitch + ((input.turn.toPitch - input.turn.fromPitch) * eased);
			if (input.turn.progress === 1) {
				const {done} = input.turn;
				input.turn = undefined;
				done();
			}
		}

		render();
	};

	// The room moves by itself only for the rain and the lava lamp, so with reduced motion, it only draws while the visitor turns it. A finger moves the room between frames, so it draws once more when it stops.
	const loop = room.loop(step, {while: () => !room.reducedMotion || isMoving(), target: view, stopped: render});

	const update = () => {
		loop.start();
		render();
	};

	// The name of the hot spot under the pointer, like in the controller of QuickTime VR. The status changes only when the hot spot does, so screen readers are not flooded.
	let hoveredHotspot;
	const showHover = id => {
		if (id === hoveredHotspot) {
			return;
		}

		hoveredHotspot = id;
		view.dataset.state = id ? 'hotspot' : '';
		status.textContent = id ? `Hot spot: ${names[id]}` : 'Drag to look around.';
	};

	const momLines = [
		'Mom: “Are you still on the Internet? I need to call Mormor!”',
		'Mom: “Dinner in five minutes! Fish balls!”',
		'Mom: “Tidy your room! And pick up the LEGO, I stepped on a brick!”',
		'Mom: “Did you eat your matpakke today? It is still in your bag.”',
		'Mom: “It is a school night. Lights out at nine!”',
		'Mom: “Who put the waffle iron in the bathroom?”',
	];

	const weatherLines = [
		'Bergen: rain. Again. It has rained {days} days in a row.',
		'Bergen: rain, with a chance of more rain. Day {days}.',
		'Kids in Bergen are born with rubber boots on. Day {days} of rain.',
		'It is not raining sideways today. It is raining up. Day {days}.',
	];

	// What each thing in the room does. The rest lead to their toys further down the page.
	const actions = {
		imac() {
			state.isHelloScreen = !state.isHelloScreen;
			room.say(state.isHelloScreen ? 'My iMac says “hello (again)”, like on the ads. 233 MHz, 32 MB of RAM, and no floppy drive!' : 'Back to the desktop of Mac OS 8.6. The PC of Dad, with Windows 98, is further up.');
		},
		poster() {
			room.cheer();
			room.say('My poster: “UNICORNS”. Glitter, my virtual unicorn, cheers for it.');
		},
		window() {
			state.rainDays++;
			if (Math.random() < 0.2) {
				state.sunUntil = performance.now() + 3000;
				room.say('The sun! In Bergen! Quick, run outside! …Too late, it is gone.');
				room.timeout(3100, update);
			} else {
				room.say(randomItem(weatherLines).replace('{days}', state.rainDays));
			}
		},
		plush() {
			state.hopUntil = performance.now() + 700;
			room.cheer();
			room.say('Squeak! That is Glitter Jr., my plush unicorn. Glitter cheers.');
			room.timeout(800, update);
		},
		door() {
			state.doorUntil = performance.now() + 3500;
			state.momLine = randomItem(momLines.filter(line => line !== state.momLine));
			room.say(state.momLine);
			room.timeout(3600, update);
		},
		lava() {
			state.isLavaOn = !state.isLavaOn;
			room.say(state.isLavaOn ? 'The lava lamp is on. Groovy. The wax goes up, the wax goes down.' : 'The lava lamp is off. The wax sinks to the bottom and goes to sleep.');
		},
		lights() {
			state.isLightOn = !state.isLightOn;
			room.say(state.isLightOn ? 'Click! The light is on.' : 'Click! The light is off, and the glow stars glow. Spooky.');
		},
		calendar() {
			room.say('My calendar: May 1999, with the 17th circled in red. The national day! Hipp hipp hurra!');
		},
	};

	const activate = id => {
		const button = room.querySelector(`[data-room-hotspot="${id}"]`);
		if (actions[id]) {
			actions[id]();
			update();
		} else if (button?.dataset.roomTarget) {
			room.say(`${names[id]}: let us go there!`);
			goTo(document.getElementById(button.dataset.roomTarget), room.reducedMotion);
		}
	};

	// Turns the view to a thing, then does what it does. With reduced motion, or while the room is off the screen, the view jumps to it.
	const turnTo = id => {
		const spot = hotspots[id];
		const centerX = spot.x + (spot.width / 2);
		const centerY = spot.y + (spot.height / 2);
		if (room.reducedMotion || !loop.isVisible) {
			state.yaw = centerX;
			state.pitch = centerY;
			render();
			activate(id);
			return;
		}

		const deltaYaw = wrap(centerX - state.yaw + (width / 2)) - (width / 2);
		input.turn = {fromYaw: state.yaw, deltaYaw, fromPitch: state.pitch, toPitch: centerY, progress: 0, done: () => activate(id)};
		loop.start();
	};

	room.on(view, 'pointerdown', event => {
		if (event.button !== 0) {
			return;
		}

		const point = canvasPoint(view, event);
		view.setPointerCapture(event.pointerId);
		input.pointer = {type: event.pointerType, startX: point.x, startY: point.y, x: point.x, y: point.y, hasMoved: false, time: event.timeStamp};
		loop.start();
	});

	room.on(view, 'pointermove', event => {
		const point = canvasPoint(view, event);
		const {pointer} = input;
		if (!pointer) {
			showHover(hotspotAt(point.x, point.y));
			return;
		}

		if (Math.hypot(point.x - pointer.startX, point.y - pointer.startY) > 6) {
			pointer.hasMoved = true;
		}

		// A finger drags the room along, as a finger expects on a touch screen. The loop draws it.
		if (pointer.type !== 'mouse') {
			state.yaw -= (point.x - pointer.x) * width / (Math.PI * 2) / focal();
			state.pitch -= (point.y - pointer.y) / state.zoom;
		}

		pointer.x = point.x;
		pointer.y = point.y;
	});

	const endPointer = event => {
		const {pointer} = input;
		input.pointer = undefined;
		if (pointer && !pointer.hasMoved && event.type === 'pointerup' && event.timeStamp - pointer.time < 700) {
			const id = hotspotAt(pointer.x, pointer.y);
			if (id) {
				activate(id);
			}
		}
	};

	room.on(view, 'pointerup', endPointer);
	room.on(view, 'pointercancel', endPointer);
	room.on(view, 'pointerleave', () => {
		if (!input.pointer) {
			showHover(undefined);
		}
	});

	const movementKeys = new Set(['ArrowLeft', 'ArrowRight', 'ArrowUp', 'ArrowDown']);

	room.on(view, 'keydown', event => {
		if (event.metaKey || event.altKey) {
			return;
		}

		if (movementKeys.has(event.key)) {
			event.preventDefault();
			input.keys.add(event.key);
			loop.start();
			// Without a running loop, a key still turns the room a step.
			if (!loop.isVisible) {
				step(0.1);
			}

			if (!event.repeat) {
				const id = hotspotAt(view.width / 2, view.height / 2);
				status.textContent = id ? `In the middle: ${names[id]}. Press Enter to click it.` : 'Use the arrow keys to look around.';
			}
		} else if (event.key === '+' || event.key === '=') {
			event.preventDefault();
			state.zoom *= 1.15;
			update();
		} else if (event.key === '-') {
			event.preventDefault();
			state.zoom /= 1.15;
			update();
		} else if (event.key === 'Enter' || event.key === ' ') {
			event.preventDefault();
			const id = hotspotAt(view.width / 2, view.height / 2);
			if (id) {
				activate(id);
			} else {
				room.say('There is nothing to click in the middle. Turn to something with the arrow keys.');
			}
		}
	});

	room.on(view, 'keyup', event => {
		input.keys.delete(event.key);
		// The status says what is in the middle once the turn stops.
		if (movementKeys.has(event.key) && input.keys.size === 0) {
			const id = hotspotAt(view.width / 2, view.height / 2);
			status.textContent = id ? `In the middle: ${names[id]}. Press Enter to click it.` : 'Use the arrow keys to look around.';
		}
	});

	room.on(view, 'blur', () => {
		input.keys.clear();
	});

	for (const button of room.querySelectorAll('[data-room-action]')) {
		room.on(button, 'click', () => {
			const {roomAction} = button.dataset;
			if (roomAction === 'zoom-in') {
				state.zoom *= 1.2;
			} else if (roomAction === 'zoom-out') {
				state.zoom /= 1.2;
			} else if (roomAction === 'hotspots') {
				state.showsHotspots = !state.showsHotspots;
				setPressed(button, state.showsHotspots);
			}

			update();
		});
	}

	for (const button of room.querySelectorAll('[data-room-hotspot]')) {
		room.on(button, 'click', () => {
			turnTo(button.dataset.roomHotspot);
		});
	}

	render();

	// The Polaroid camera takes the picture that the view shows, as a square from the middle. In the dark, the flash lights up the middle of the room, and the edges stay dark.
	const takePicture = size => {
		const picture = makeCanvas(size, size);
		const context = picture.getContext('2d');
		const wasLightOn = state.isLightOn;
		const wasShowingHotspots = state.showsHotspots;
		state.isLightOn = true;
		state.showsHotspots = false;
		render();
		const side = view.height;
		context.drawImage(view, (view.width - side) / 2, 0, side, side, 0, 0, size, size);
		state.isLightOn = wasLightOn;
		state.showsHotspots = wasShowingHotspots;
		render();

		const vignette = context.createRadialGradient(size / 2, size / 2, size * 0.2, size / 2, size / 2, size * 0.75);
		vignette.addColorStop(0, 'rgba(0, 0, 0, 0)');
		vignette.addColorStop(1, wasLightOn ? 'rgba(20, 10, 0, 0.45)' : 'rgba(0, 0, 10, 0.92)');
		context.fillStyle = vignette;
		context.fillRect(0, 0, size, size);
		// The colors of Polaroid film are a little warm and soft.
		context.globalCompositeOperation = 'soft-light';
		fill(context, 'rgba(255, 190, 120, 0.35)', 0, 0, size, size);
		context.globalCompositeOperation = 'source-over';
		return picture;
	};

	const takeFlash = () => {
		flash.dataset.state = '';
		// Reading the size restarts the animation of the flash.
		void flash.offsetWidth;
		flash.dataset.state = 'flash';
	};

	return {takePicture, flash: takeFlash, render};
};

// The Polaroid camera: a film pack of 10 pictures, which develop slowly on the cork board, from a dark green to the colors of the room in about a minute, like Polaroid 600 film. The visitor writes on the white edge. The pictures are kept in the browser.
const setUpPolaroid = (room, {film: filmCounter, shutter, newFilm, cameraStatus: status, photos: board, photoTemplate: template}, panorama) => {
	const developTime = 60_000;
	const maximumPhotos = 12;

	const stored = room.stored('photos', []);
	const photos = (Array.isArray(stored) ? stored : [])
		.filter(photo => typeof photo?.source === 'string' && photo.source.startsWith('data:image/jpeg') && Number.isFinite(photo.takenAt))
		.slice(0, maximumPhotos)
		.map(photo => ({source: photo.source, takenAt: photo.takenAt, caption: typeof photo.caption === 'string' ? photo.caption.slice(0, 30) : ''}));
	let film = clamp(Math.round(Number(room.stored('film', 10)) || 0), 0, 10);
	let packs = 0;

	const say = text => {
		room.say(text, status);
	};

	const saveAll = () => {
		room.store('photos', photos);
		room.store('film', film);
	};

	const showFilm = () => {
		filmCounter.textContent = String(film);
		shutter.disabled = film === 0;
		newFilm.hidden = film > 0;
	};

	// Draws a picture as far as it has developed: first a dark blue green, then the shapes, and the colors last.
	const drawDeveloping = (canvas, image, takenAt) => {
		const context = canvas.getContext('2d');
		const progress = clamp((Date.now() - takenAt) / developTime, 0, 1);
		context.fillStyle = '#1d2b2e';
		context.fillRect(0, 0, canvas.width, canvas.height);
		if (image.complete && image.naturalWidth > 0) {
			context.globalAlpha = clamp(progress * 1.4, 0, 1);
			context.drawImage(image, 0, 0, canvas.width, canvas.height);
			context.globalAlpha = 1 - progress;
			context.globalCompositeOperation = 'color';
			context.fillStyle = '#2a4a50';
			context.fillRect(0, 0, canvas.width, canvas.height);
			context.globalCompositeOperation = 'source-over';
			context.globalAlpha = 1;
		}

		return progress < 1;
	};

	const developing = new Set();

	const labelOf = photo => `A Polaroid picture of my room${photo.caption ? `: ${photo.caption}` : ''}`;

	const showPhotos = () => {
		developing.clear();
		// Each picture is made again on each change, and its listeners go with it when it is replaced, so they are not listeners of the element.
		const items = photos.map((photo, index) => {
			const item = template.content.firstElementChild.cloneNode(true);
			const frame = item.firstElementChild;
			const canvas = item.querySelector('canvas');
			const caption = item.querySelector('input');
			const remove = item.querySelector('button');
			frame.dataset.state = index % 2 === 0 ? '' : 'right';
			canvas.setAttribute('role', 'img');
			canvas.setAttribute('aria-label', labelOf(photo));
			caption.value = photo.caption ?? '';
			const image = new Image();
			image.addEventListener('load', () => {
				if (drawDeveloping(canvas, image, photo.takenAt)) {
					developing.add({canvas, image, photo});
				}
			});
			image.src = photo.source;
			drawDeveloping(canvas, image, photo.takenAt);

			caption.addEventListener('change', () => {
				photo.caption = caption.value.trim();
				canvas.setAttribute('aria-label', labelOf(photo));
				saveAll();
			});

			remove.addEventListener('click', () => {
				photos.splice(photos.indexOf(photo), 1);
				saveAll();
				showPhotos();
				say('Taken down. It is in the shoe box under the bed now.');
				// The button is gone, so the focus goes to the camera.
				(shutter.disabled ? newFilm : shutter).focus();
			});

			return item;
		});
		board.replaceChildren(...items);
	};

	// The pictures develop with a timer, only while the board is on the screen. A picture that is off the screen still develops, as the time it was taken is kept.
	let timer;
	room.watchVisibility(board, isVisible => {
		timer?.cancel();
		if (isVisible) {
			timer = room.interval(250, () => {
				for (const entry of developing) {
					if (!drawDeveloping(entry.canvas, entry.image, entry.photo.takenAt)) {
						developing.delete(entry);
					}
				}
			});
		}
	});

	room.on(shutter, 'click', () => {
		if (film === 0) {
			return;
		}

		film--;
		panorama.flash();
		const picture = panorama.takePicture(160);
		photos.unshift({source: picture.toDataURL('image/jpeg', 0.75), caption: '', takenAt: Date.now()});
		photos.splice(maximumPhotos);
		saveAll();
		showFilm();
		showPhotos();
		say(film === 0 ? 'Click, whirr! That was the last picture of the pack.' : `Click, whirr! The picture comes out. Wait for it to develop. ${plural(film, 'picture')} left.`);
		if (film === 0) {
			newFilm.focus();
		}
	});

	room.on(newFilm, 'click', () => {
		film = 10;
		packs++;
		saveAll();
		showFilm();
		say(packs > 2 ? 'Another pack? Dad says Polaroid film does not grow on trees.' : 'A new film pack! That was a whole week of pocket money.');
		shutter.focus();
	});

	showFilm();
	showPhotos();
};

export default class extends GeoCitiesElement {
	#panorama;

	connected() {
		this.#panorama = setUpPanorama(this, this.parts);
		setUpPolaroid(this, this.parts, this.#panorama);
	}

	reducedMotionChanged() {
		this.#panorama.render();
	}
}
