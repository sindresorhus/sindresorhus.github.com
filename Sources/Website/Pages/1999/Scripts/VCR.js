// The VCR under the TV in our living room on the 1999 page: the TV with the rabbit ears, the channels, and the Degauss button, and the VCR with the blinking clock, the tapes, the tracking, the recordings, the ShowView timer, and the tape that it eats. The picture is drawn on a canvas, which runs only while the toy is on the screen and the tab is visible. With reduced motion, nothing moves by itself: the picture is a still frame, which changes with each press. Nothing makes a sound until the visitor turns on the sound. The clock, the tapes, and the fees are kept in the browser.

const clamp = (value, minimum, maximum) => Math.min(Math.max(value, minimum), maximum);

const now = () => performance.now() / 1000;

// The position of a pointer on a canvas, in the pixels of the canvas.
const canvasPoint = (canvas, event) => {
	const rectangle = canvas.getBoundingClientRect();
	return {
		x: (event.clientX - rectangle.left) * canvas.width / rectangle.width,
		y: (event.clientY - rectangle.top) * canvas.height / rectangle.height,
	};
};

// A number between 0 and 1 that is always the same for the same seed, for the things that must not flicker, like the places of the rain drops.
const hash = seed => {
	const value = Math.sin(seed * 127.1 + 311.7) * 43_758.5453;
	return value - Math.floor(value);
};

// A tiny pixel font of 3 × 5, for the menus on the screen of the TV, which were blocky like this. Each letter is five rows of three bits.
const pixelFont = {
	A: [2, 5, 7, 5, 5], B: [6, 5, 6, 5, 6], C: [3, 4, 4, 4, 3], D: [6, 5, 5, 5, 6], E: [7, 4, 6, 4, 7], F: [7, 4, 6, 4, 4], G: [3, 4, 5, 5, 3], H: [5, 5, 7, 5, 5], I: [7, 2, 2, 2, 7], J: [1, 1, 1, 5, 2], K: [5, 5, 6, 5, 5], L: [4, 4, 4, 4, 7], M: [5, 7, 7, 5, 5], N: [6, 5, 5, 5, 5], O: [2, 5, 5, 5, 2], P: [6, 5, 6, 4, 4], Q: [2, 5, 5, 6, 3], R: [6, 5, 6, 5, 5], S: [3, 4, 2, 1, 6], T: [7, 2, 2, 2, 2], U: [5, 5, 5, 5, 7], V: [5, 5, 5, 5, 2], W: [5, 5, 7, 7, 5], X: [5, 5, 2, 5, 5], Y: [5, 5, 2, 2, 2], Z: [7, 1, 2, 4, 7],
	0: [7, 5, 5, 5, 7], 1: [2, 6, 2, 2, 7], 2: [6, 1, 2, 4, 7], 3: [6, 1, 2, 1, 6], 4: [5, 5, 7, 1, 1], 5: [7, 4, 6, 1, 6], 6: [3, 4, 7, 5, 7], 7: [7, 1, 2, 2, 2], 8: [7, 5, 7, 5, 7], 9: [7, 5, 7, 1, 6],
	' ': [0, 0, 0, 0, 0], '.': [0, 0, 0, 0, 2], ',': [0, 0, 0, 2, 4], '!': [2, 2, 2, 0, 2], '?': [6, 1, 2, 0, 2], ':': [0, 2, 0, 2, 0], '-': [0, 0, 7, 0, 0], '+': [0, 2, 7, 2, 0], '/': [1, 1, 2, 4, 4], '\'': [2, 2, 0, 0, 0], '(': [1, 2, 2, 2, 1], ')': [4, 2, 2, 2, 4], '°': [2, 5, 2, 0, 0], '<': [1, 2, 4, 2, 1], '>': [4, 2, 1, 2, 4], '=': [0, 7, 0, 7, 0], '%': [5, 1, 2, 4, 5], '♥': [0, 5, 7, 7, 2], '*': [0, 5, 2, 5, 0],
	Æ: [3, 6, 7, 6, 7], Ø: [3, 5, 7, 5, 6], Å: [2, 0, 2, 5, 7],
};

// Draws text in the pixel font, at whole pixels, with a scale for bigger letters. The alignment is `left`, `center`, or `right`.
const drawPixelText = (context, text, x, y, color, {scale = 1, align = 'left', shadow} = {}) => {
	const characters = [...String(text).toUpperCase()];
	const width = ((characters.length * 4) - 1) * scale;
	const start = Math.round(align === 'center' ? x - (width / 2) : (align === 'right' ? x - width : x));

	for (const [layer, fill] of [[1, shadow], [0, color]]) {
		if (!fill) {
			continue;
		}

		let left = start + (layer * scale);
		context.fillStyle = fill;

		for (const character of characters) {
			const rows = pixelFont[character] ?? pixelFont['?'];
			for (const [row, bits] of rows.entries()) {
				for (let column = 0; column < 3; column++) {
					if (bits & (4 >> column)) {
						context.fillRect(left + (column * scale), Math.round(y) + (row * scale) + (layer * scale), scale, scale);
					}
				}
			}

			left += 4 * scale;
		}
	}
};

const channelNames = ['AV', 'NRK1', 'TV 2', 'TVNorge'];
const channelName = channel => channelNames[channel] ?? `channel ${channel}`;

// Each live program runs for this many seconds before the next program of the channel, so a visitor sees them all.
const programLength = 24;
const tapeLength = 240;

// How fast the tape runs in each mode of the VCR. Picture search runs at 7 times, and winding without a picture at 40 times.
const speeds = {
	play: 1,
	record: 1,
	cue: 7,
	review: -7,
	forward: 40,
	rewind: -40,
};

// The tapes on the shelf. A part is what was on the tape from the start, and the tracking is where its picture is clear, as each camera and VCR wrote the tape a bit differently. A caption is a line of the status, which comes when the tape plays past it.
const tapes = {
	may: {
		title: '17. mai 1998',
		isProtected: true,
		parts: [{from: 0, to: 75, scene: 'may', tracking: 28}],
		captions: [
			[1, 'Pappa, on the tape: «Er den på nå? Lyser det rødt?» (Is it on? Is the red light on?)'],
			[18, 'Pappa’s thumb is over the lens. For ten seconds.'],
			[28, 'Pappa: «Hvorfor filmer den asfalten?» (Why is it filming the road?)'],
			[40, 'Lillesøster drops her ice cream on her bunad. Mormor waves at the camera.'],
			[58, 'Everybody: «Hurra! Hurra! Hurra!»'],
			[75, 'The end of the 17th of May. The rest of the tape is snow.'],
		],
	},
	wedding: {
		title: 'the Simpsons tape',
		isProtected: false,
		parts: [{from: 0, to: 90, scene: 'simpsonsTape', tracking: 50}, {from: 90, to: 150, scene: 'wedding', tracking: 20}],
		captions: [
			[1, 'The Simpsons, which I taped from TV 2 last week. The best episode!'],
			[40, 'An ad for Freia chocolate. TV 2 has ads, NRK does not.'],
			[90, 'Wait. The Simpsons stopped. Is that … Mamma and Pappa’s wedding? The tracking is all wrong.'],
			[100, 'Mamma, from the kitchen: «SINDRE! Er det bryllupskassetten vår?!» (Is that our wedding tape?!)'],
			[150, 'And that is all that is left of the wedding.'],
		],
	},
	rental: {
		title: 'Titanic',
		isProtected: true,
		parts: [{from: 0, to: 8, scene: 'warning'}, {from: 8, to: 30, scene: 'trailer'}, {from: 30, to: 170, scene: 'titanic'}, {from: 170, to: 186, scene: 'tapeTwo'}],
		tracking: 78,
		captions: [
			[1, 'The warning that nobody reads.'],
			[9, 'Trailers! Fast forward, quick.'],
			[31, 'TITANIC. Finally. Lillesøster has the tissues ready.'],
			[71, '«I’m flying!» Lillesøster sings along to the whole thing.'],
			[101, 'Oh no. An iceberg.'],
			[131, 'It sinks. Mamma pretends that she has something in her eye.'],
			[170, 'Tape 2? We only rented tape 1! Lillesøster cries. The video store is closed.'],
		],
	},
	blank: {
		title: 'the blank tape',
		isProtected: false,
		parts: [],
		captions: [],
	},
};

// The drawings of the programs and the tapes, at 320 × 240, the size of the picture before the TV makes it bigger. Each gets the seconds since the program started, and whether the visitor prefers reduced motion.
const width = 320;
const height = 240;

const fillRectangle = (context, x, y, rectangleWidth, rectangleHeight, color) => {
	context.fillStyle = color;
	context.fillRect(x, y, rectangleWidth, rectangleHeight);
};

const fillEllipse = (context, x, y, radiusX, radiusY, color) => {
	context.fillStyle = color;
	context.beginPath();
	context.ellipse(x, y, Math.max(radiusX, 0.1), Math.max(radiusY, 0.1), 0, 0, Math.PI * 2);
	context.fill();
};

const fillCircle = (context, x, y, radius, color) => {
	fillEllipse(context, x, y, radius, radius, color);
};

const fillPolygon = (context, points, color) => {
	context.fillStyle = color;
	context.beginPath();
	for (const [index, [x, y]] of points.entries()) {
		if (index === 0) {
			context.moveTo(x, y);
		} else {
			context.lineTo(x, y);
		}
	}

	context.closePath();
	context.fill();
};

const verticalGradient = (context, top, bottom, colors) => {
	const gradient = context.createLinearGradient(0, top, 0, bottom);
	for (const [index, color] of colors.entries()) {
		gradient.addColorStop(index / (colors.length - 1), color);
	}

	return gradient;
};

const drawText = (context, text, x, y, {size = 14, color = '#ffffff', font = 'Arial, Helvetica, sans-serif', weight = 'bold', align = 'center', outline} = {}) => {
	context.font = `${weight} ${size}px ${font}`;
	context.textAlign = align;
	context.textBaseline = 'middle';
	if (outline) {
		context.lineWidth = Math.max(2, size / 5);
		context.lineJoin = 'round';
		context.strokeStyle = outline;
		context.strokeText(text, x, y);
	}

	context.fillStyle = color;
	context.fillText(text, x, y);
};

// The logo of a channel in the top corner, which the channels put there so that nobody could tape them without it.
const drawLogo = (context, text, {side = 'right', color = '#ffffffcc'} = {}) => {
	drawText(context, text, side === 'right' ? width - 12 : 12, 16, {size: 12, color, align: side === 'right' ? 'right' : 'left', outline: '#00000055'});
};

// A person, drawn simply, standing with the feet at `y`.
const drawPerson = (context, x, y, {size = 60, skin = '#f0c8a0', hair = '#6a4a2a', top = '#3355aa', bottom = '#333344', armsUp = 0, hairStyle = 'short'} = {}) => {
	const unit = size / 60;
	fillRectangle(context, x - (7 * unit), y - (22 * unit), 5 * unit, 22 * unit, bottom);
	fillRectangle(context, x + (2 * unit), y - (22 * unit), 5 * unit, 22 * unit, bottom);
	fillRectangle(context, x - (9 * unit), y - (44 * unit), 18 * unit, 24 * unit, top);
	context.strokeStyle = top;
	context.lineWidth = 4 * unit;
	context.lineCap = 'round';
	for (const side of [-1, 1]) {
		const lift = side === 1 ? armsUp : armsUp * 0.6;
		context.beginPath();
		context.moveTo(x + (side * 8 * unit), y - (41 * unit));
		context.lineTo(x + (side * (12 + (lift * 4)) * unit), y - ((26 + (lift * 30)) * unit));
		context.stroke();
	}

	fillCircle(context, x, y - (51 * unit), 8 * unit, skin);
	if (hairStyle === 'long') {
		fillEllipse(context, x, y - (50 * unit), 10 * unit, 11 * unit, hair);
		fillCircle(context, x, y - (50 * unit), 7 * unit, skin);
		fillRectangle(context, x - (7 * unit), y - (60 * unit), 14 * unit, 5 * unit, hair);
	} else if (hairStyle === 'short') {
		fillEllipse(context, x, y - (57 * unit), 8 * unit, 4 * unit, hair);
	}

	fillRectangle(context, x - (3 * unit), y - (53 * unit), 1.5 * unit, 1.5 * unit, '#222222');
	fillRectangle(context, x + (1.5 * unit), y - (53 * unit), 1.5 * unit, 1.5 * unit, '#222222');
};

// The flag of Norway: red, with a blue cross with a white edge.
const drawFlag = (context, x, y, size, wave = 0) => {
	context.save();
	context.translate(x, y);
	context.transform(1, wave * 0.15, 0, 1, 0, 0);
	const unit = size / 22;
	fillRectangle(context, 0, 0, 22 * unit, 16 * unit, '#ba0c2f');
	fillRectangle(context, 6 * unit, 0, 4 * unit, 16 * unit, '#ffffff');
	fillRectangle(context, 0, 6 * unit, 22 * unit, 4 * unit, '#ffffff');
	fillRectangle(context, 7 * unit, 0, 2 * unit, 16 * unit, '#00205b');
	fillRectangle(context, 0, 7 * unit, 22 * unit, 2 * unit, '#00205b');
	context.restore();
	fillRectangle(context, x - 1, y, 1.5, size * 1.4, '#8a6a3a');
};

// The family of the Simpsons on their couch, for the TV and for the tape I recorded.
const drawSimpsons = (context, time, isReducedMotion) => {
	context.fillStyle = verticalGradient(context, 0, 180, ['#e8a8d8', '#d890c8']);
	context.fillRect(0, 0, width, 180);
	fillRectangle(context, 0, 180, width, 60, '#7a8a4a');
	fillRectangle(context, 120, 30, 80, 50, '#7a4a2a');
	fillRectangle(context, 124, 34, 72, 42, '#88c8f0');
	fillPolygon(context, [[150, 70], [160, 40], [172, 70]], '#ffffff');
	fillRectangle(context, 140, 70, 40, 4, '#7a4a2a');
	fillRectangle(context, 30, 60, 6, 120, '#444444');
	fillPolygon(context, [[18, 60], [48, 60], [40, 40], [26, 40]], '#f0e090');
	fillRectangle(context, 60, 120, 200, 60, '#9a6a3a');
	fillRectangle(context, 50, 110, 18, 75, '#8a5a2a');
	fillRectangle(context, 252, 110, 18, 75, '#8a5a2a');
	fillRectangle(context, 60, 100, 200, 30, '#8a5a2a');

	// They run in from the side and jump on the couch.
	// With reduced motion, they sit there already.
	const run = isReducedMotion ? 0 : Math.max(0, 1 - (time / 3));
	const offset = run * 260;
	const yellow = '#ffd521';
	const seats = [
		{x: 95, draw: x => {
			fillRectangle(context, x - 14, 120, 28, 40, '#ffffff');
			fillRectangle(context, x - 14, 150, 28, 22, '#4a6ad0');
			fillCircle(context, x, 106, 14, yellow);
			fillEllipse(context, x, 116, 10, 6, '#c8a070');
		}},
		{x: 140, draw: x => {
			fillEllipse(context, x, 70, 12, 32, '#2a5cff');
			fillRectangle(context, x - 12, 118, 24, 52, '#7ac83a');
			fillCircle(context, x, 106, 11, yellow);
		}},
		{x: 178, draw: x => {
			fillRectangle(context, x - 10, 128, 20, 22, '#ff7a1a');
			fillRectangle(context, x - 10, 150, 20, 18, '#3a5ac8');
			fillPolygon(context, [[x - 11, 112], [x - 9, 100], [x - 5, 106], [x - 1, 98], [x + 3, 106], [x + 7, 99], [x + 11, 112]], yellow);
			fillCircle(context, x, 116, 11, yellow);
		}},
		{x: 214, draw: x => {
			fillRectangle(context, x - 10, 130, 20, 36, '#e8402a');
			fillCircle(context, x, 120, 10, yellow);
			fillPolygon(context, [[x - 13, 116], [x - 6, 112], [x, 104], [x + 6, 112], [x + 13, 116], [x, 118]], yellow);
		}},
	];

	for (const [index, seat] of seats.entries()) {
		const hop = run > 0 ? Math.abs(Math.sin((time * 9) + index)) * 6 : 0;
		context.save();
		context.translate(offset + (index * run * 30), -hop);
		seat.draw(seat.x);
		const eyeY = [104, 104, 114, 118][index];
		for (const eyeX of [seat.x - 4, seat.x + 4]) {
			fillCircle(context, eyeX, eyeY, 4, '#ffffff');
			fillCircle(context, eyeX + 1, eyeY, 1.2, '#111111');
		}
		context.restore();
	}
};

const scenes = {
	blue(context) {
		fillRectangle(context, 0, 0, width, height, '#1636c4');
	},
	black(context) {
		fillRectangle(context, 0, 0, width, height, '#050505');
	},
	// Barne-TV: green hills, a sun with the face of a baby, and a purple creature with a screen on its belly.
	children(context, time) {
		context.fillStyle = verticalGradient(context, 0, 170, ['#4aa8ff', '#bfe6ff']);
		context.fillRect(0, 0, width, height);
		const sunY = 130 - (Math.min(time / 5, 1) * 75) + (Math.sin(time * 1.3) * 3);
		const glow = context.createRadialGradient(240, sunY, 10, 240, sunY, 50);
		glow.addColorStop(0, '#fff4a0');
		glow.addColorStop(1, '#fff4a000');
		context.fillStyle = glow;
		context.fillRect(180, sunY - 60, 120, 120);
		fillCircle(context, 240, sunY, 24, '#ffd23a');
		fillCircle(context, 240, sunY, 15, '#f4c8a0');
		const isGiggling = Math.sin(time * 2.4) > 0.3;
		context.strokeStyle = '#5a3a2a';
		context.lineWidth = 1.5;
		for (const eye of [-5, 5]) {
			context.beginPath();
			if (isGiggling) {
				context.arc(240 + eye, sunY - 3, 2.5, Math.PI, 0);
			} else {
				context.arc(240 + eye, sunY - 3, 1.5, 0, Math.PI * 2);
			}

			context.stroke();
		}

		context.beginPath();
		context.arc(240, sunY + 3, isGiggling ? 6 : 4, 0, Math.PI);
		context.stroke();
		fillEllipse(context, 70, 250, 190, 90, '#5ac83a');
		fillEllipse(context, 270, 260, 170, 95, '#4ab030');
		for (let index = 0; index < 14; index++) {
			fillCircle(context, hash(index) * width, 200 + (hash(index + 50) * 38), 2.5, ['#ff5a8a', '#ffffff', '#ffe03a'][index % 3]);
		}

		const x = 140 + (Math.sin(time * 0.5) * 70);
		const bob = Math.abs(Math.sin(time * 3)) * 4;
		fillEllipse(context, x, 175 - bob, 22, 30, '#8d4fc8');
		fillRectangle(context, x - 7, 168 - bob, 14, 11, '#c8c8d0');
		fillRectangle(context, x - 5, 170 - bob, 10, 7, '#7ad0ff');
		fillCircle(context, x, 135 - bob, 14, '#8d4fc8');
		fillCircle(context, x, 137 - bob, 9, '#f4c8a0');
		fillPolygon(context, [[x - 4, 122 - bob], [x, 108 - bob], [x + 4, 122 - bob]], '#8d4fc8');
		fillRectangle(context, x - 4, 135 - bob, 2, 2, '#222222');
		fillRectangle(context, x + 2, 135 - bob, 2, 2, '#222222');
		context.strokeStyle = '#8d4fc8';
		context.lineWidth = 7;
		context.lineCap = 'round';
		context.beginPath();
		context.moveTo(x + 18, 165 - bob);
		context.lineTo(x + 30, 145 - bob - (Math.abs(Math.sin(time * 4)) * 12));
		context.stroke();

		for (let index = 0; index < 3; index++) {
			const rabbitX = (index * 110) + 40 + ((time * 6) % 30);
			const hop = Math.abs(Math.sin((time * 4) + index)) * 8;
			fillEllipse(context, rabbitX, 215 - hop, 7, 5, '#f0e8e0');
			fillEllipse(context, rabbitX + 5, 210 - hop, 2, 6, '#f0e8e0');
		}

		drawLogo(context, 'NRK', {side: 'left'});
		drawText(context, 'Barne-TV', 270, 226, {size: 13, color: '#ffffff', outline: '#00000066'});
	},
	// The NRK clock before Dagsrevyen, and then the news.
	news(context, time) {
		if (time < 10) {
			const background = context.createRadialGradient(160, 110, 20, 160, 120, 200);
			background.addColorStop(0, '#1a3a9a');
			background.addColorStop(1, '#020a2a');
			context.fillStyle = background;
			context.fillRect(0, 0, width, height);
			fillCircle(context, 160, 108, 82, '#c8c8d0');
			fillCircle(context, 160, 108, 78, '#f6f6f6');
			for (let index = 0; index < 60; index++) {
				const angle = (index / 60) * Math.PI * 2;
				const isHour = index % 5 === 0;
				context.strokeStyle = '#111111';
				context.lineWidth = isHour ? 4 : 1;
				context.beginPath();
				context.moveTo(160 + (Math.sin(angle) * (isHour ? 60 : 68)), 108 - (Math.cos(angle) * (isHour ? 60 : 68)));
				context.lineTo(160 + (Math.sin(angle) * 74), 108 - (Math.cos(angle) * 74));
				context.stroke();
			}

			const seconds = Math.floor(50 + time);
			const minutes = seconds >= 60 ? 0 : 59;
			const hours = seconds >= 60 ? 19 : 18;
			const hands = [
				[((hours % 12) + (minutes / 60)) / 12, 40, 6, '#111111'],
				[minutes / 60, 62, 4, '#111111'],
				[(seconds % 60) / 60, 66, 1.5, '#d01010'],
			];
			for (const [turn, length, lineWidth, color] of hands) {
				const angle = turn * Math.PI * 2;
				context.strokeStyle = color;
				context.lineWidth = lineWidth;
				context.lineCap = 'butt';
				context.beginPath();
				context.moveTo(160, 108);
				context.lineTo(160 + (Math.sin(angle) * length), 108 - (Math.cos(angle) * length));
				context.stroke();
			}

			fillCircle(context, 160, 108, 4, '#d01010');
			drawText(context, 'NRK', 160, 214, {size: 20, color: '#ffffff'});
			return;
		}

		context.fillStyle = verticalGradient(context, 0, height, ['#1c4aa8', '#0a1e5e']);
		context.fillRect(0, 0, width, height);
		context.strokeStyle = '#ffffff22';
		context.lineWidth = 1;
		for (let index = 0; index < 6; index++) {
			context.beginPath();
			context.ellipse(60, 90, 30 + (index * 22), 80, 0, 0, Math.PI * 2);
			context.stroke();
		}

		// The picture over the shoulder: is the computer ready for the year 2000?
		fillRectangle(context, 186, 36, 112, 78, '#ffffff');
		fillRectangle(context, 189, 39, 106, 72, '#0a0a3a');
		fillRectangle(context, 214, 50, 56, 40, '#d8d0b8');
		fillRectangle(context, 219, 54, 46, 30, Math.floor(time * 2) % 2 === 0 ? '#003a8a' : '#000000');
		drawPixelText(context, 'Y2K?', 242, 64, '#ffff55', {scale: 2, align: 'center'});
		fillRectangle(context, 230, 90, 24, 8, '#b8b0a0');
		drawText(context, 'ÅR 2000', 242, 104, {size: 10, color: '#ffffff'});

		fillRectangle(context, 0, 186, width, 54, '#b8c4dc');
		fillEllipse(context, 110, 196, 52, 34, '#1c2433');
		fillPolygon(context, [[98, 164], [122, 164], [110, 192]], '#ffffff');
		fillPolygon(context, [[106, 168], [114, 168], [112, 190], [108, 190]], '#b01c2c');
		fillRectangle(context, 102, 150, 16, 16, '#e0b088');
		fillEllipse(context, 110, 128, 24, 28, '#6a3a1a');
		fillEllipse(context, 110, 132, 18, 22, '#ecc098');
		fillRectangle(context, 101, 126, 4, 2, '#222222');
		fillRectangle(context, 115, 126, 4, 2, '#222222');
		fillEllipse(context, 110, 143, 5, 1 + (Math.abs(Math.sin(time * 9)) * 3), '#8a2a2a');
		fillRectangle(context, 0, 200, width, 24, '#ffffffe6');
		fillRectangle(context, 0, 200, 46, 24, '#c8102e');
		drawText(context, 'NRK', 23, 212, {size: 13});
		drawText(context, 'Dagsrevyen', 56, 212, {size: 13, color: '#0a1e5e', align: 'left'});
		drawLogo(context, 'NRK');
		if (time < 13) {
			fillRectangle(context, 0, 0, width, height, '#0a1e5ecc');
			drawText(context, 'DAGSREVYEN', 160, 120, {size: 30, color: '#ffffff', font: 'Georgia, serif', outline: '#c8102e'});
		}
	},
	// The weather map: rain in Bergen, sun in Oslo, like always.
	weather(context, time) {
		fillRectangle(context, 0, 0, width, height, '#2a5cae');
		fillPolygon(context, [[138, 0], [120, 18], [134, 30], [108, 52], [122, 66], [96, 90], [112, 104], [88, 124], [104, 140], [84, 160], [98, 178], [118, 196], [150, 212], [190, 222], [236, 228], [320, 230], [320, 0]], '#4a9a50');
		fillPolygon(context, [[210, 20], [250, 60], [230, 110], [270, 120], [300, 70], [320, 60], [320, 0], [220, 0]], '#5aaa5a');
		const cities = [['BERGEN', 100, 146], ['OSLO', 262, 182], ['TRONDHEIM', 196, 40]];
		for (const [name, x, y] of cities) {
			fillCircle(context, x, y, 3, '#ffffff');
			drawPixelText(context, name, x + 6, y - 2, '#ffffff', {scale: 1, shadow: '#00000088'});
		}

		for (const [x, y, radiusX, radiusY] of [[92, 120, 26, 14], [116, 116, 22, 12], [104, 108, 18, 12], [196, 30, 18, 9]]) {
			fillEllipse(context, x, y, radiusX, radiusY, '#8a8f9a');
			fillEllipse(context, x - 3, y - 3, radiusX * 0.8, radiusY * 0.7, '#b8bcc4');
		}

		context.strokeStyle = '#cfe8ff';
		context.lineWidth = 1.5;
		for (let index = 0; index < 34; index++) {
			const x = 74 + (hash(index) * 64);
			const y = 124 + ((hash(index + 9) * 50) + (time * 70)) % 50;
			context.beginPath();
			context.moveTo(x, y);
			context.lineTo(x - 3, y + 8);
			context.stroke();
		}

		const sunX = 262;
		const sunY = 156;
		context.strokeStyle = '#ffe03a';
		context.lineWidth = 2;
		for (let index = 0; index < 8; index++) {
			const angle = (index / 8) * Math.PI * 2 + (time * 0.5);
			context.beginPath();
			context.moveTo(sunX + (Math.cos(angle) * 14), sunY + (Math.sin(angle) * 14));
			context.lineTo(sunX + (Math.cos(angle) * 20), sunY + (Math.sin(angle) * 20));
			context.stroke();
		}

		fillCircle(context, sunX, sunY, 10, '#ffe03a');
		for (const [text, x, y] of [['9°', 60, 150], ['21°', 284, 196], ['12°', 226, 54]]) {
			fillRectangle(context, x - 14, y - 9, 28, 18, '#ffffff');
			drawText(context, text, x, y, {size: 13, color: '#c8102e'});
		}

		fillRectangle(context, 0, 212, width, 28, '#0a1e5ee6');
		drawText(context, 'VÆRET', 16, 226, {size: 15, align: 'left'});
		drawText(context, 'Regn på Vestlandet. Igjen.', 304, 226, {size: 11, align: 'right', weight: 'normal'});
		drawLogo(context, 'NRK');
	},
	// Derrick, the German detective with the big glasses, with Norwegian subtitles, which NRK showed for years.
	derrick(context, time) {
		const zoom = time > 22 ? Math.min((time - 22) / 3, 1) : 0;
		context.save();
		context.translate(120, 92);
		context.scale(1 + (zoom * 1.4), 1 + (zoom * 1.4));
		context.translate(-120, -92);
		fillRectangle(context, 0, 0, width, height, '#7a5a3a');
		for (let x = 0; x < width; x += 16) {
			fillRectangle(context, x, 0, 6, 200, '#6a4a2c');
		}

		fillRectangle(context, 0, 200, width, 40, '#4a3424');
		fillRectangle(context, 216, 26, 76, 92, '#d8d0b8');
		fillRectangle(context, 222, 32, 64, 80, '#8a9ab0');
		fillRectangle(context, 252, 32, 4, 80, '#d8d0b8');
		drawPerson(context, 254, 200, {size: 92, hair: '#3a2a1a', top: '#5a6070', bottom: '#2a2a30'});
		fillPolygon(context, [[86, 120], [154, 120], [168, 240], [72, 240]], '#c8b48a');
		fillPolygon(context, [[110, 120], [130, 120], [124, 160], [116, 160]], '#e8e0d0');
		fillPolygon(context, [[117, 124], [123, 124], [122, 156], [118, 156]], '#5a3a2a');
		fillRectangle(context, 112, 106, 16, 16, '#e0b090');
		fillEllipse(context, 120, 92, 20, 24, '#e6bc98');
		fillEllipse(context, 120, 72, 22, 10, '#c8c8c8');
		fillEllipse(context, 101, 86, 5, 12, '#c8c8c8');
		fillEllipse(context, 139, 86, 5, 12, '#c8c8c8');
		context.strokeStyle = '#2a2a2a';
		context.lineWidth = 2;
		context.strokeRect(105, 84, 13, 10);
		context.strokeRect(122, 84, 13, 10);
		fillRectangle(context, 110, 88, 3, 2, '#222222');
		fillRectangle(context, 127, 88, 3, 2, '#222222');
		fillRectangle(context, 113, 104, 14, 2, '#8a4a3a');
		context.restore();
		drawLogo(context, 'NRK');

		const subtitles = [[4, 9, 'Harry, hent bilen.'], [10, 16, 'Hvor var De i går kveld, klokken ni?'], [17, 22, 'Jeg tror jeg vet hvem morderen er.'], [23, Infinity, 'Morderen er …']];
		for (const [start, end, text] of subtitles) {
			if (time >= start && time < end) {
				drawText(context, text, 160, 220, {size: 15, outline: '#000000'});
			}
		}
	},
	simpsons(context, time, isReducedMotion) {
		drawSimpsons(context, time, isReducedMotion);
		drawLogo(context, 'TV 2', {side: 'left'});
	},
	// Hotel Cæsar, the soap of TV 2: the reception, and a slow zoom in on a face that just heard the truth.
	soap(context, time) {
		const zoom = clamp((time - 10) / 8, 0, 1);
		context.save();
		context.translate(100, 110);
		context.scale(1 + (zoom * 1.6), 1 + (zoom * 1.6));
		context.translate(-100, -110);
		fillRectangle(context, 0, 0, width, height, '#e2d2a8');
		fillRectangle(context, 0, 120, width, 120, '#8a5a30');
		for (let x = 0; x < width; x += 40) {
			fillRectangle(context, x, 120, 2, 120, '#6a4220');
		}

		fillRectangle(context, 200, 30, 90, 60, '#6a4220');
		for (let row = 0; row < 3; row++) {
			for (let column = 0; column < 5; column++) {
				fillCircle(context, 212 + (column * 17), 44 + (row * 18), 2.5, '#d8b040');
			}
		}

		drawPerson(context, 100, 210, {size: 120, hair: '#f0d070', top: '#c01c3c', bottom: '#c01c3c', hairStyle: 'long'});
		drawPerson(context, 236, 210, {size: 116, hair: '#2a1a10', top: '#22262e', bottom: '#22262e'});
		fillRectangle(context, 150, 150, 170, 90, '#5a3218');
		fillRectangle(context, 150, 146, 170, 6, '#d8b040');
		context.restore();
		drawLogo(context, 'TV 2', {side: 'left'});
		if (time < 4) {
			drawText(context, 'Hotel Cæsar', 160, 120, {size: 28, color: '#f0d070', font: 'Georgia, serif', outline: '#3a2a10'});
		}
	},
	// TV-Shop on TVNorge: a machine for the belly, and a phone number that blinks.
	shop(context, time) {
		const background = context.createRadialGradient(160, 110, 10, 160, 120, 220);
		background.addColorStop(0, '#fff8a0');
		background.addColorStop(1, '#ff9a1a');
		context.fillStyle = background;
		context.fillRect(0, 0, width, height);
		context.save();
		context.translate(120, 110);
		context.rotate(time * 0.4);
		const points = [];
		for (let index = 0; index < 32; index++) {
			const radius = index % 2 === 0 ? 90 : 70;
			const angle = (index / 32) * Math.PI * 2;
			points.push([Math.cos(angle) * radius, Math.sin(angle) * radius]);
		}

		fillPolygon(context, points, '#ffffff88');
		context.restore();
		fillCircle(context, 120, 128, 30, '#1a1a1a');
		fillCircle(context, 120, 128, 9, '#aaaaaa');
		context.strokeStyle = '#555555';
		context.lineWidth = 2;
		for (let index = 0; index < 6; index++) {
			const angle = (index / 6) * Math.PI * 2 + (time * 3);
			context.beginPath();
			context.moveTo(120, 128);
			context.lineTo(120 + (Math.cos(angle) * 26), 128 + (Math.sin(angle) * 26));
			context.stroke();
		}

		context.strokeStyle = '#d01010';
		context.lineWidth = 6;
		context.beginPath();
		context.moveTo(70, 70);
		context.quadraticCurveTo(120, 40, 170, 70);
		context.lineTo(130, 128);
		context.moveTo(70, 70);
		context.lineTo(110, 128);
		context.stroke();
		drawText(context, 'AB-ROLLER 2000', 120, 186, {size: 16, color: '#d01010', font: 'Impact, Arial Black, sans-serif', weight: 'normal'});
		context.save();
		context.translate(250, 90);
		context.rotate(-0.2);
		const burst = [];
		for (let index = 0; index < 24; index++) {
			const radius = index % 2 === 0 ? 50 : 38;
			const angle = (index / 24) * Math.PI * 2;
			burst.push([Math.cos(angle) * radius, Math.sin(angle) * radius]);
		}

		fillPolygon(context, burst, '#d01010');
		drawText(context, 'KUN', 0, -14, {size: 11});
		drawText(context, 'KR 399,-', 0, 4, {size: 16});
		context.restore();
		fillRectangle(context, 0, 206, width, 34, '#1a1a6a');
		if (Math.floor(time * 2) % 2 === 0) {
			drawText(context, 'RING NÅ! 820 44 444', 160, 223, {size: 17, color: '#ffff55'});
		}

		drawText(context, 'TV-SHOP', 12, 20, {size: 16, color: '#d01010', align: 'left', outline: '#ffffff'});
		drawLogo(context, 'TVNORGE');
	},
	// Baywatch on TVNorge: the run on the beach, in slow motion.
	beach(context, time) {
		context.fillStyle = verticalGradient(context, 0, 110, ['#58b0f0', '#bfe4ff']);
		context.fillRect(0, 0, width, 110);
		context.fillStyle = verticalGradient(context, 100, 150, ['#1a7ac8', '#3aa0d8']);
		context.fillRect(0, 100, width, 50);
		context.strokeStyle = '#ffffffaa';
		context.lineWidth = 2;
		for (let index = 0; index < 5; index++) {
			const y = 110 + (index * 9);
			context.beginPath();
			for (let x = 0; x <= width; x += 8) {
				context.lineTo(x, y + (Math.sin((x * 0.06) + (time * 1.5) + index) * 2));
			}

			context.stroke();
		}

		fillRectangle(context, 0, 148, width, 92, '#f2d79a');
		fillRectangle(context, 252, 70, 4, 80, '#8a6a4a');
		fillRectangle(context, 282, 70, 4, 80, '#8a6a4a');
		fillRectangle(context, 244, 50, 50, 26, '#ffd23a');
		fillPolygon(context, [[240, 50], [298, 50], [269, 34]], '#d01010');
		const progress = (time % 12) / 12;
		const scale = 0.7 + (progress * 1.3);
		const bounce = Math.abs(Math.sin(time * 2.2)) * 6 * scale;
		context.save();
		context.translate(140, 150 + (progress * 70) - bounce);
		context.scale(scale, scale);
		drawPerson(context, 0, 0, {size: 70, hair: '#f6d860', top: '#e0202a', bottom: '#e8b890', hairStyle: 'long'});
		fillRectangle(context, 12, -40, 8, 34, '#e0202a');
		context.restore();
		drawLogo(context, 'TVNORGE');
	},
	// The 17th of May on Pappa’s camcorder: the children’s parade, Pappa’s thumb, the road, the ice cream, and Hurra!
	may(context, time) {
		const shakeX = (Math.sin(time * 7.1) * 4) + (Math.sin(time * 13.3) * 2);
		const shakeY = (Math.sin(time * 5.7) * 3) + (Math.sin(time * 17.9) * 1.5);
		context.save();
		context.translate(shakeX, shakeY);
		if (time >= 28 && time < 40) {
			fillRectangle(context, -10, -10, width + 20, height + 20, '#6a6a6e');
			for (let index = 0; index < 60; index++) {
				fillCircle(context, hash(index) * width, ((hash(index + 3) * height) - (time * 40)) % height + height, 1.5, '#55555a');
			}

			for (const [index, x] of [100, 190].entries()) {
				const step = Math.sin((time * 6) + (index * Math.PI)) * 14;
				fillEllipse(context, x, 150 + step, 26, 44, '#5a3a1a');
				fillEllipse(context, x, 130 + step, 18, 18, '#6a4a2a');
			}
		} else {
			context.fillStyle = verticalGradient(context, 0, 120, ['#9ac8f0', '#dceaf4']);
			context.fillRect(-10, -10, width + 20, 140);
			const houses = ['#f0e0b0', '#e04a3a', '#ffffff', '#f2c040', '#7ab0d0', '#f0e0b0'];
			for (const [index, color] of houses.entries()) {
				const x = (index * 58) - 10;
				fillRectangle(context, x, 40, 54, 100, color);
				fillPolygon(context, [[x - 4, 42], [x + 27, 14], [x + 58, 42]], '#5a4a4a');
				for (let window = 0; window < 2; window++) {
					fillRectangle(context, x + 10 + (window * 22), 60, 12, 16, '#ffffff');
					fillRectangle(context, x + 12 + (window * 22), 62, 8, 12, '#4a6a8a');
				}
			}

			fillRectangle(context, -10, 140, width + 20, 110, '#8a8a8a');
			if (time < 40) {
				// The children’s parade, with flags, in rows that go by.
				for (let index = 0; index < 9; index++) {
					const x = ((index * 46) + (time * 22)) % 400 - 40;
					const y = 200 + ((index % 2) * 8);
					const tops = ['#c01c2c', '#1a3a8a', '#ffffff'];
					drawPerson(context, x, y, {size: 60, hair: ['#f0d070', '#6a4a2a', '#2a1a10'][index % 3], top: tops[index % 3], bottom: '#1a1a2a', armsUp: 1});
					drawFlag(context, x + 12, y - 92, 24, Math.sin((time * 5) + index));
				}
			} else {
				// Lillesøster in her bunad with an ice cream, and Mormor who waves.
				drawPerson(context, 120, 214, {size: 110, hair: '#f0d070', top: '#c01c2c', bottom: '#1a1a2a', hairStyle: 'long'});
				fillRectangle(context, 104, 150, 32, 6, '#ffffff');
				const drip = time >= 46 ? 0 : 1;
				fillPolygon(context, [[138, 130], [148, 130], [143, 150]], '#d8a050');
				if (drip) {
					fillCircle(context, 143, 126, 7, '#ffe8f0');
				} else {
					fillCircle(context, 128, 168, 7, '#ffe8f0');
				}

				drawPerson(context, 240, 220, {size: 120, hair: '#e8e8e8', top: '#2a5a3a', bottom: '#2a5a3a', armsUp: Math.abs(Math.sin(time * 4))});
				if (time >= 58) {
					for (let index = 0; index < 6; index++) {
						const x = 20 + (index * 56);
						const raise = Math.abs(Math.sin((time * 5) + index)) * 16;
						drawFlag(context, x, 60 - raise, 28, Math.sin((time * 6) + index));
					}
				}
			}
		}

		context.restore();
		if (time >= 18 && time < 28) {
			// Pappa’s thumb, pink and out of focus, over half the lens.
			const thumb = context.createRadialGradient(40, 200, 10, 60, 190, 170);
			thumb.addColorStop(0, '#e89a8a');
			thumb.addColorStop(0.75, '#d88070ee');
			thumb.addColorStop(1, '#d8807000');
			context.fillStyle = thumb;
			context.fillRect(0, 0, width, height);
			context.strokeStyle = '#c0706055';
			context.lineWidth = 3;
			for (let index = 0; index < 5; index++) {
				context.beginPath();
				context.arc(50, 200, 40 + (index * 14), -1.4, -0.1);
				context.stroke();
			}
		}

		drawPixelText(context, `17.5.98 ${String(11 + Math.floor(time / 60)).padStart(2, '0')}:${String(42 + Math.floor((time % 60) / 4)).padStart(2, '0')}`, 304, 220, '#ffcc33', {scale: 2, align: 'right', shadow: '#000000'});
	},
	// The Simpsons, which I taped from TV 2, with an ad for chocolate in the middle.
	simpsonsTape(context, time, isReducedMotion) {
		if (time >= 40 && time < 52) {
			context.fillStyle = verticalGradient(context, 0, height, ['#3a1a6a', '#1a0a3a']);
			context.fillRect(0, 0, width, height);
			context.save();
			context.translate(160, 110);
			context.rotate(-0.15 + ((time - 40) * 0.02));
			fillRectangle(context, -90, -26, 180, 52, '#e0b040');
			fillRectangle(context, -84, -20, 168, 40, '#2a1a8a');
			drawText(context, 'FREIA', 0, -4, {size: 22, color: '#ffffff', font: 'Georgia, serif'});
			drawText(context, 'Melkesjokolade', 0, 13, {size: 10, color: '#e0b040'});
			context.restore();
			drawText(context, 'Et lite stykke Norge', 160, 196, {size: 18, color: '#ffffff', font: 'Georgia, serif', weight: 'italic bold'});
			return;
		}

		drawSimpsons(context, time % 40, isReducedMotion);
		drawLogo(context, 'TV 2', {side: 'left'});
	},
	// The wedding of Mamma and Pappa in 1985, on an old tape: the church, the rice, the puffy sleeves, and the moustache.
	wedding(context, time) {
		context.fillStyle = verticalGradient(context, 0, 150, ['#b8c0c8', '#e0d8c8']);
		context.fillRect(0, 0, width, height);
		fillRectangle(context, 0, 170, width, 70, '#7a8a5a');
		fillRectangle(context, 60, 70, 200, 110, '#f4f0e8');
		fillPolygon(context, [[50, 72], [160, 30], [270, 72]], '#5a3a3a');
		fillRectangle(context, 140, 0, 40, 50, '#f4f0e8');
		fillPolygon(context, [[134, 4], [160, -30], [186, 4]], '#5a3a3a');
		fillRectangle(context, 145, 120, 30, 60, '#6a4a2a');
		drawPerson(context, 130, 200, {size: 100, hair: '#4a2a1a', top: '#1a1a1a', bottom: '#1a1a1a'});
		fillRectangle(context, 125, 145, 10, 3, '#3a2010');
		fillPolygon(context, [[170, 200], [196, 200], [190, 132], [176, 132]], '#ffffff');
		drawPerson(context, 184, 200, {size: 100, hair: '#6a3a1a', top: '#ffffff', bottom: '#ffffff', hairStyle: 'long'});
		fillCircle(context, 172, 135, 7, '#ffffff');
		fillCircle(context, 196, 135, 7, '#ffffff');
		fillEllipse(context, 184, 140, 22, 18, '#6a3a1a');
		fillCircle(context, 184, 147, 7, '#f0c8a0');
		for (let index = 0; index < 40; index++) {
			const x = (hash(index) * width) + (Math.sin(time + index) * 8);
			const y = ((hash(index + 20) * 200) + (time * 60)) % 200;
			fillRectangle(context, x, y, 2, 2, '#ffffff');
		}

		if (time < 6) {
			fillRectangle(context, 0, 90, width, 50, '#00000088');
			drawPixelText(context, 'MAMMA ♥ PAPPA', 160, 104, '#ffffff', {scale: 3, align: 'center', shadow: '#aa2244'});
		}

		// The old tape has faded, so the colors are like sepia.
		context.fillStyle = '#a0784026';
		context.fillRect(0, 0, width, height);
		drawPixelText(context, '6.7.85', 304, 220, '#ffcc33', {scale: 2, align: 'right', shadow: '#000000'});
	},
	warning(context) {
		fillRectangle(context, 0, 0, width, height, '#000000');
		drawPixelText(context, 'ADVARSEL', 160, 40, '#ffffff', {scale: 4, align: 'center'});
		const lines = ['DENNE VIDEOKASSETTEN', 'ER KUN FOR PRIVAT', 'BRUK I HJEMMET.', '', 'KOPIERING, UTLEIE OG', 'OFFENTLIG VISNING ER', 'FORBUDT.'];
		for (const [index, line] of lines.entries()) {
			drawPixelText(context, line, 160, 86 + (index * 18), '#ffffff', {scale: 2, align: 'center'});
		}
	},
	// The trailers at the start of a rented film, which everybody winds past.
	trailer(context, time) {
		if (time < 5) {
			fillRectangle(context, 0, 0, width, height, '#000000');
			drawText(context, 'KOMMER SNART', 160, 100, {size: 22, color: '#ffffff', font: 'Georgia, serif'});
			drawText(context, 'PÅ VIDEO', 160, 132, {size: 22, color: '#ffffff', font: 'Georgia, serif'});
			return;
		}

		context.fillStyle = verticalGradient(context, 0, height, ['#2a3a2a', '#0a1a0a']);
		context.fillRect(0, 0, width, height);
		for (let index = 0; index < 8; index++) {
			fillRectangle(context, index * 42, 100 + (hash(index) * 60), 34, 140, '#1a221a');
			for (let row = 0; row < 8; row++) {
				if (hash((index * 10) + row) > 0.5) {
					fillRectangle(context, (index * 42) + 8, 110 + (hash(index) * 60) + (row * 14), 6, 6, '#c8c060');
				}
			}
		}

		const step = (time - 5) * 18;
		context.save();
		context.translate(40 + step, 0);
		fillEllipse(context, 0, 150, 40, 70, '#3a5a3a');
		fillEllipse(context, 26, 70, 22, 18, '#3a5a3a');
		fillPolygon(context, [[-10, 90], [-30, 60], [-14, 100], [-36, 80], [-20, 120]], '#4a6a4a');
		fillRectangle(context, 34, 64, 5, 4, '#ffee55');
		context.restore();
		drawText(context, 'GODZILLA', 160, 34, {size: 30, color: '#ffffff', font: 'Impact, Arial Black, sans-serif', weight: 'normal', outline: '#000000'});
		drawText(context, 'Størrelsen betyr noe.', 160, 216, {size: 14, color: '#ffffff'});
	},
	// Titanic: the title, the ship at sea, «I’m flying», the iceberg, and the sinking.
	titanic(context, time) {
		if (time < 8) {
			fillRectangle(context, 0, 0, width, height, '#000000');
			drawText(context, 'TITANIC', 160, 110, {size: 40, color: '#d8c890', font: 'Georgia, serif', outline: '#3a2a10'});
			return;
		}

		const isNight = time >= 70;
		context.fillStyle = verticalGradient(context, 0, 150, isNight ? ['#020818', '#0a1a3a'] : ['#f0a050', '#ffd890', '#f08060']);
		context.fillRect(0, 0, width, 150);
		context.fillStyle = verticalGradient(context, 140, height, isNight ? ['#0a1a3a', '#000814'] : ['#3a5a8a', '#1a2a4a']);
		context.fillRect(0, 140, width, 100);
		if (isNight) {
			for (let index = 0; index < 40; index++) {
				fillRectangle(context, hash(index) * width, hash(index + 7) * 120, 1, 1, '#ffffff');
			}
		} else {
			fillCircle(context, 250, 140, 26, '#ffc860');
		}

		if (time >= 40 && time < 70) {
			// The bow, with the two of them, arms out.
			fillPolygon(context, [[0, 240], [0, 150], [260, 180], [320, 240]], '#1a1a1a');
			fillPolygon(context, [[0, 160], [260, 186], [256, 192], [0, 170]], '#ffffff');
			context.strokeStyle = '#d8d8d8';
			context.lineWidth = 2;
			context.beginPath();
			context.moveTo(0, 140);
			context.lineTo(250, 176);
			context.stroke();
			const lift = Math.sin(time * 0.8) * 2;
			drawPerson(context, 180, 180, {size: 80, hair: '#c86a3a', top: '#e8d8c8', bottom: '#e8d8c8', hairStyle: 'long', armsUp: 0.6 + (lift * 0.05)});
			context.strokeStyle = '#e8d8c8';
			context.lineWidth = 4;
			context.beginPath();
			context.moveTo(160, 112);
			context.lineTo(200, 112);
			context.stroke();
			drawPerson(context, 166, 182, {size: 82, hair: '#e0c070', top: '#ffffff', bottom: '#3a3a3a'});
			return;
		}

		const sinking = clamp((time - 100) / 40, 0, 1);
		const shipX = isNight ? 120 : 10 + ((time - 8) * 3.5);
		context.save();
		context.translate(shipX, 150 + (sinking * 60));
		context.rotate(-sinking * 0.7);
		fillPolygon(context, [[-80, -6], [90, -6], [80, 16], [-70, 16]], '#141414');
		fillRectangle(context, -70, -8, 160, 4, '#ffffff');
		fillRectangle(context, -60, -26, 130, 20, '#f4f0e8');
		for (let index = 0; index < 4; index++) {
			fillRectangle(context, -44 + (index * 30), -50, 12, 26, '#e0a020');
			fillRectangle(context, -44 + (index * 30), -50, 12, 6, '#141414');
		}

		if (isNight) {
			for (let index = 0; index < 12; index++) {
				fillRectangle(context, -56 + (index * 10), -18, 3, 3, '#ffe890');
			}
		}

		context.restore();
		if (isNight && time < 100) {
			const approach = clamp((time - 70) / 28, 0, 1);
			fillPolygon(context, [[320 - (approach * 110), 170], [340 - (approach * 110), 80], [380 - (approach * 110), 60], [420 - (approach * 110), 170]], '#d8e8f8');
		}
	},
	tapeTwo(context) {
		fillRectangle(context, 0, 0, width, height, '#000000');
		drawPixelText(context, 'SLUTT PÅ KASSETT 1', 160, 90, '#ffffff', {scale: 2, align: 'center'});
		drawPixelText(context, 'SETT INN KASSETT 2', 160, 120, '#ffffff', {scale: 2, align: 'center'});
	},
};

// The picture is drawn small first, like the signal, and the TV makes it bigger, with the scan lines and the round glass on top.
const makeCanvas = (canvasWidth, canvasHeight) => {
	const canvas = document.createElement('canvas');
	canvas.width = canvasWidth;
	canvas.height = canvasHeight;
	return canvas;
};

// A few frames of snow, made once, which the TV picks from at random, as making new snow for every frame would be slow.
const noiseFrames = Array.from({length: 4}, () => {
	const canvas = makeCanvas(width, height);
	const context = canvas.getContext('2d');
	const image = context.createImageData(width, height);
	for (let index = 0; index < image.data.length; index += 4) {
		const value = Math.random() < 0.5 ? Math.random() * 90 : 120 + (Math.random() * 135);
		image.data[index] = value;
		image.data[index + 1] = value;
		image.data[index + 2] = value;
		image.data[index + 3] = 255;
	}

	context.putImageData(image, 0, 0);
	return canvas;
});

const drawNoise = (context, x, y, noiseWidth, noiseHeight) => {
	const sourceWidth = Math.min(Math.round(noiseWidth), width);
	const sourceHeight = Math.max(1, Math.min(Math.round(noiseHeight), height));
	const frame = noiseFrames[Math.floor(Math.random() * noiseFrames.length)];
	context.drawImage(frame, Math.floor(Math.random() * (width - sourceWidth + 1)), Math.floor(Math.random() * (height - sourceHeight + 1)), sourceWidth, sourceHeight, x, y, noiseWidth, noiseHeight);
};

// The scan lines, the dark corners, and the shine of the curved glass of the screen, drawn once.
const makeGlass = (glassWidth, glassHeight) => {
	const glass = makeCanvas(glassWidth, glassHeight);
	const context = glass.getContext('2d');
	context.fillStyle = '#00000038';
	for (let y = 1; y < glass.height; y += 2) {
		context.fillRect(0, y, glass.width, 1);
	}

	const vignette = context.createRadialGradient(320, 240, 160, 320, 240, 420);
	vignette.addColorStop(0, '#00000000');
	vignette.addColorStop(1, '#0000008c');
	context.fillStyle = vignette;
	context.fillRect(0, 0, glass.width, glass.height);
	const shine = context.createRadialGradient(180, 90, 10, 200, 110, 260);
	shine.addColorStop(0, '#ffffff1f');
	shine.addColorStop(1, '#ffffff00');
	context.fillStyle = shine;
	context.fillRect(0, 0, glass.width, glass.height);
	return glass;
};

const liveClock = channel => (Date.now() / 1000) + (channel * 7);

// Where the rabbit ears must point for each channel, and how good the picture can get. TVNorge comes from far away, so it is always a bit snowy in Bergen.
const reception = {
	1: {left: -0.85, right: 0.35, best: 1},
	2: {left: -0.2, right: 1.1, best: 0.95},
	3: {left: -1.25, right: 0.7, best: 0.8},
};

const snowOf = signal => clamp((1 - signal) ** 1.2, 0, 0.97);
const ghostOf = signal => clamp((0.9 - signal) * 0.7, 0, 0.45);

const vcrLabels = {
	play: 'PLAY',
	pause: 'STILL',
	cue: '>> SEARCH',
	review: '<< SEARCH',
	forward: 'FF >>',
	rewind: '<< REW',
	record: 'REC',
	stop: 'STOP',
	eaten: 'ERROR',
};

const channelLabel = channel => channel === 0 ? 'AV' : `P${String(channel).padStart(2, '0')} ${channelNames[channel] ?? ''}`.trim();

const rodLength = 116;
const rodBase = side => ({x: 200 + (side === 'left' ? -5 : 5), y: 110});

const localMinutes = () => {
	const date = new Date();
	return (date.getHours() * 60) + date.getMinutes();
};

const formatTime = minutes => `${String(Math.floor(minutes / 60)).padStart(2, '0')}:${String(minutes % 60).padStart(2, '0')}`;

const setText = (element, text) => {
	if (element.textContent !== text) {
		element.textContent = text;
	}
};

const setState = (element, state) => {
	if ((element.dataset.state ?? '') !== state) {
		element.dataset.state = state;
	}
};

const modeSymbols = {
	play: '▶',
	pause: '❚❚',
	cue: '▶▶',
	forward: '▶▶',
	review: '◀◀',
	rewind: '◀◀',
	record: '●',
	eaten: '⚠',
};

// Joins the sentences of a status, without the empty ones.
const sentences = (...texts) => texts.filter(Boolean).join(' ');

const reelCenter = {x: 86, y: 70};

// Three turns of the pencil wind the tape back in: six presses of the button, or a few circles with a finger.
const rescueTurns = 3;

export default class extends GeoCitiesElement {
	#programs;
	#memory;
	#screenContext;
	#antennaContext;
	#rescueContext;
	#picture = makeCanvas(width, height);
	#pictureContext = this.#picture.getContext('2d');
	#ghost = makeCanvas(width, height);
	#ghostContext = this.#ghost.getContext('2d');
	#composite;
	#compositeContext;
	#glass;
	#vcrButtons;
	#tapeButtons;
	#programButtons;
	#loop;
	#lastAdvance;
	#lastTick;
	#clockTimer;
	#holdTimer;
	#suppressClickUntil = 0;

	#tv = {
		isOn: false,
		channel: 1,
		power: undefined,
		degauss: undefined,
		lastDegauss: -Infinity,
		magnet: 0,
		osd: undefined,
	};

	#vcr = {
		tape: undefined,
		mode: 'stop',
		tuner: 1,
		counterZero: 0,
		isShowingClock: false,
		setting: undefined,
		entry: undefined,
		program: undefined,
		isTimerArmed: false,
		timerRun: undefined,
		recording: undefined,
		pausedFor: 0,
		osdUntil: 0,
		flash: undefined,
		didHold: false,
		weddingBefore: 0,
	};

	#antennaState = {
		held: undefined,
		heldUntil: 0,
		selected: 'left',
	};

	// The VCR ate the tape: it hangs out of the slot, and the visitor winds it back with a pencil.
	#rescue = {wound: 0, angle: 0, lastAngle: undefined, lastHint: 0};

	// The sounds, made in the browser once the visitor turns them on: the hum and the high whine of the CRT, the hiss of the snow, the motor of the VCR, and the clunks.
	#sounds = {
		context: undefined,
		output: undefined,
		isOn: false,
		noise: undefined,
		hum: undefined,
		hiss: undefined,
		motor: undefined,
		motorOscillator: undefined,
		// Starts the sounds with the audio of the element, which is only there in the handler of a click.
		start(audio) {
			if (!audio) {
				return false;
			}

			this.context = audio.context;
			this.output = audio.output;
			this.context.resume();

			if (!this.noise) {
				const {context, output} = this;
				this.noise = new AudioBuffer({length: context.sampleRate * 2, sampleRate: context.sampleRate});
				const samples = this.noise.getChannelData(0);
				for (let index = 0; index < samples.length; index++) {
					samples[index] = (Math.random() * 2) - 1;
				}

				// The hum of the mains at 50 Hz in Norway, and the whine of 15 625 Hz, the line frequency of a PAL TV, which children hear and grown-ups do not.
				this.hum = new GainNode(context, {gain: 0});
				this.hum.connect(output);
				for (const [frequency, volume] of [[50, 0.5], [100, 0.25], [15_625, 0.04]]) {
					const oscillator = new OscillatorNode(context, {type: 'sine', frequency});
					oscillator.connect(new GainNode(context, {gain: volume})).connect(this.hum);
					oscillator.start();
				}

				const hissSource = new AudioBufferSourceNode(context, {buffer: this.noise, loop: true});
				this.hiss = new GainNode(context, {gain: 0});
				hissSource.connect(new BiquadFilterNode(context, {type: 'highpass', frequency: 1200})).connect(this.hiss).connect(output);
				hissSource.start();

				this.motorOscillator = new OscillatorNode(context, {type: 'sawtooth', frequency: 200});
				this.motor = new GainNode(context, {gain: 0});
				this.motorOscillator.connect(new BiquadFilterNode(context, {type: 'lowpass', frequency: 1800})).connect(this.motor).connect(output);
				this.motorOscillator.start();
			}

			return true;
		},
		get isRunning() {
			return this.isOn && this.context?.state === 'running';
		},
		level(node, value) {
			if (node && this.context) {
				node.gain.setTargetAtTime(this.isOn ? value : 0, this.context.currentTime, 0.05);
			}
		},
		tone(frequency, duration, {type = 'square', volume = 0.06, when = 0, slide} = {}) {
			if (!this.isRunning) {
				return;
			}

			const start = this.context.currentTime + when;
			const oscillator = new OscillatorNode(this.context, {type, frequency});
			const gain = new GainNode(this.context, {gain: 0});
			if (slide) {
				oscillator.frequency.exponentialRampToValueAtTime(slide, start + duration);
			}

			gain.gain.setValueAtTime(0, start);
			gain.gain.linearRampToValueAtTime(volume, start + 0.005);
			gain.gain.exponentialRampToValueAtTime(0.0001, start + duration);
			oscillator.connect(gain).connect(this.output);
			oscillator.start(start);
			oscillator.stop(start + duration + 0.02);
		},
		burst(duration, {volume = 0.2, frequency = 800, type = 'lowpass', when = 0} = {}) {
			if (!this.isRunning) {
				return;
			}

			const start = this.context.currentTime + when;
			const source = new AudioBufferSourceNode(this.context, {buffer: this.noise});
			const gain = new GainNode(this.context, {gain: volume});
			gain.gain.setValueAtTime(volume, start);
			gain.gain.exponentialRampToValueAtTime(0.0001, start + duration);
			source.connect(new BiquadFilterNode(this.context, {type, frequency})).connect(gain).connect(this.output);
			source.start(start, Math.random());
			source.stop(start + duration + 0.02);
		},
		click() {
			this.burst(0.03, {volume: 0.15, frequency: 3000, type: 'bandpass'});
		},
		// The tape goes in or out with a clunk of the motor and the mechanism.
		clunk() {
			this.burst(0.12, {volume: 0.5, frequency: 300});
			this.tone(70, 0.15, {type: 'sine', volume: 0.25});
			this.burst(0.08, {volume: 0.3, frequency: 500, when: 0.35});
			this.tone(90, 0.1, {type: 'sine', volume: 0.15, when: 0.35});
		},
		// The degauss coil: a deep thunk, and a hum that dies away.
		thunk() {
			this.tone(55, 1.4, {type: 'sawtooth', volume: 0.16});
			this.tone(110, 0.9, {type: 'sine', volume: 0.12});
			this.burst(0.1, {volume: 0.4, frequency: 200});
		},
		// The snap of the CRT, and the high whine that falls as it turns off.
		snap() {
			this.burst(0.05, {volume: 0.35, frequency: 2500, type: 'bandpass'});
			this.tone(9000, 0.6, {type: 'sine', volume: 0.02, slide: 2000});
		},
		// The static crackle when the CRT turns on.
		crackle() {
			for (let index = 0; index < 6; index++) {
				this.burst(0.03, {volume: 0.2, frequency: 4000, type: 'highpass', when: index * 0.07 * Math.random()});
			}
		},
		// The grinding of a tape in the wrong place.
		crunch() {
			for (let index = 0; index < 10; index++) {
				this.burst(0.08, {volume: 0.35, frequency: 400 + (index * 90), type: 'bandpass', when: index * 0.09});
			}

			this.tone(160, 0.9, {type: 'sawtooth', volume: 0.05, slide: 40});
		},
		tick() {
			this.burst(0.015, {volume: 0.12, frequency: 2500, type: 'bandpass'});
		},
		kaching() {
			this.tone(1568, 0.12, {volume: 0.05});
			this.tone(2093, 0.3, {volume: 0.05, when: 0.08});
		},
	};

	connected() {
		const {screen, antenna, rescueCanvas, sound, power, channelUp, channelDown, degauss, magnet, returnTape, tonight, flapToggle, flap, tracking, slot, pencil} = this.parts;
		this.#programs = this.config.programs;
		this.#screenContext = screen.getContext('2d');
		this.#antennaContext = antenna.getContext('2d');
		this.#rescueContext = rescueCanvas.getContext('2d');
		this.#composite = makeCanvas(screen.width, screen.height);
		this.#compositeContext = this.#composite.getContext('2d');
		this.#glass = makeGlass(screen.width, screen.height);
		this.#vcrButtons = new Map([...this.querySelectorAll('[data-vcr-button]')].map(button => [button.dataset.vcrButton, button]));
		this.#tapeButtons = new Map([...this.querySelectorAll('[data-vcr-tape]')].map(button => [button.dataset.vcrTape, button]));
		this.#programButtons = [...this.querySelectorAll('[data-vcr-program]')];

		// What the visitor did with the VCR, kept in the browser: the clock, where each tape is, what was taped on it, and the fees of the video store. The last renter did not rewind Titanic.
		const saved = this.stored('memory', {});
		const angleOf = (value, fallback) => Number.isFinite(value) ? clamp(value, -1.5, 1.5) : fallback;
		this.#memory = {
			clockOffset: typeof saved.clockOffset === 'number' ? saved.clockOffset : undefined,
			fees: Number(saved.fees) || 0,
			hasEaten: Boolean(saved.hasEaten),
			// The rabbit ears start a bit off for every channel: the picture is there under the snow, and a small turn makes it better.
			antenna: {left: angleOf(saved.antenna?.left, -0.55), right: angleOf(saved.antenna?.right, 0.75)},
			tapes: Object.fromEntries(Object.keys(tapes).map(id => {
				const tape = saved.tapes?.[id];
				return [id, {
					position: clamp(Number(tape?.position ?? (id === 'rental' ? 112 : 0)) || 0, 0, tapeLength),
					recordings: Array.isArray(tape?.recordings) ? tape.recordings.filter(recording => typeof recording?.from === 'number' && typeof recording?.to === 'number') : [],
					crinkle: typeof tape?.crinkle === 'number' ? tape.crinkle : undefined,
				}];
			})),
		};

		// The loop watches the whole toy, not only the screen, so a tape or the timer goes on while the visitor reads the status, the shelf, or the newspaper under the TV.
		this.#lastAdvance = now();
		this.#loop = this.loop(() => {
			this.#advance();
			this.#render();
		}, {while: () => this.#needsFrames()});

		this.on(sound, 'click', () => {
			const sounds = this.#sounds;
			sounds.isOn = !sounds.isOn && sounds.start(this.sound());
			if (!sounds.isOn) {
				sounds.context?.suspend();
			}

			sound.setAttribute('aria-pressed', String(sounds.isOn));
			sound.textContent = sounds.isOn ? '🔊 Sound' : '🔈 Sound';
			this.say(sounds.isOn ? 'The sound is on: the hum of the TV, the hiss of the snow, and the whine of the VCR.' : 'The sound is off.');
			sounds.click();
			this.#refresh();
		});

		// The buttons of the TV and under it change the VCR at the time of the press.
		for (const [button, action] of [
			[power, () => this.#togglePower()],
			[channelUp, () => this.#changeChannel(1)],
			[channelDown, () => this.#changeChannel(-1)],
			[degauss, () => this.#degauss()],
			[magnet, () => this.#useMagnet()],
			[returnTape, () => this.#returnRental()],
			[tonight, () => this.#waitUntilTonight()],
		]) {
			this.on(button, 'click', () => {
				this.#advance();
				action();
				this.#refresh();
			});
		}

		for (const [name, button] of this.#vcrButtons) {
			this.on(button, 'click', () => {
				this.#advance();
				this.#sounds.click();
				this.#actions[name]();
				this.#refresh();
			});
		}

		for (const button of this.querySelectorAll('[data-vcr-digit]')) {
			this.on(button, 'click', () => {
				const vcr = this.#vcr;
				this.#advance();
				this.#sounds.click();
				const digit = button.dataset.vcrDigit;
				if (vcr.entry !== undefined) {
					vcr.entry = `${vcr.entry}${digit}`.slice(-8);
				} else if (vcr.setting) {
					this.say('The number keys do not set the clock. Use Ch + and Ch −. Nobody knows why.');
				} else if (digit >= '1' && digit <= '6') {
					this.#changeVcrChannel(Number(digit) - vcr.tuner);
				} else {
					this.say(`There is nothing on P${digit}. Press ShowView first to type a code.`);
				}

				this.#refresh();
			});
		}

		// The Clock button sets the clock when it is held down, like on a real VCR, which nobody in the family knew.
		const clockButton = this.#vcrButtons.get('clock');
		const startHold = () => {
			this.#holdTimer?.cancel();
			this.#vcr.didHold = false;
			this.#holdTimer = this.timeout(1200, () => {
				this.#vcr.didHold = true;
				this.#sounds.tone(1200, 0.1, {volume: 0.05});
				this.#startClockSetting();
				this.#refresh();
			});
		};

		const cancelHold = () => {
			this.#holdTimer?.cancel();
		};

		this.on(clockButton, 'pointerdown', startHold);
		for (const type of ['pointerup', 'pointerleave', 'pointercancel']) {
			this.on(clockButton, type, cancelHold);
		}

		this.on(clockButton, 'keydown', event => {
			if (event.key !== ' ' && event.key !== 'Enter') {
				return;
			}

			// A held Enter would click again and again, and step through the clock that it just started to set.
			if (event.repeat) {
				event.preventDefault();
				return;
			}

			startHold();
		});

		this.on(clockButton, 'keyup', event => {
			cancelHold();

			// Enter clicks when it goes down, before the hold, so no click comes after the hold to use up `didHold`, and the next press of Clock must still count.
			if (event.key === 'Enter') {
				this.#vcr.didHold = false;
			}
		});

		// A long press on a phone would open a menu.
		this.on(clockButton, 'contextmenu', event => {
			event.preventDefault();
		});

		this.on(flapToggle, 'click', () => {
			this.#setFlap(flap.hidden);
		});

		// Escape closes the flap again, from its toggle or from a button under it.
		for (const element of [flapToggle, flap]) {
			this.on(element, 'keydown', event => {
				if (event.key !== 'Escape' || flap.hidden) {
					return;
				}

				event.preventDefault();
				this.#setFlap(false);
				flapToggle.focus();
			});
		}

		this.on(tracking, 'input', () => {
			this.#refresh();
		});

		this.on(tracking, 'change', () => {
			this.#sayTracking();
		});

		this.on(slot, 'click', () => {
			this.#advance();
			if (this.#vcr.tape) {
				this.#actions.eject();
			} else {
				this.say('The slot is empty. Drag a tape from the shelf into it, or press a tape.');
			}

			this.#refresh();
		});

		for (const [id, button] of this.#tapeButtons) {
			this.#makeDraggable(id, button);
		}

		for (const button of this.#programButtons) {
			this.on(button, 'click', () => {
				const vcr = this.#vcr;
				const program = this.#programs.find(item => item.code === button.dataset.vcrProgram);
				this.#circle(program.code);
				if (vcr.entry === undefined) {
					this.say(`Pappa circles ${program.title} (${channelNames[program.channel]}, kl. ${program.time}) with a red pen. To tape it: open the flap of the VCR, press ShowView, type ${program.code}, and press ShowView again. The clock must be set first.`);
				} else {
					vcr.entry = program.code;
					this.say(`Pappa reads the code out loud while you type: ${[...program.code].join(' ')}. Now press ShowView again.`);
					this.#refresh();
				}
			});
		}

		this.#listenToAntenna();

		this.on(screen, 'keydown', event => {
			const direction = {ArrowUp: 1, ArrowDown: -1}[event.key];
			if (direction) {
				event.preventDefault();
				this.#advance();
				this.#changeChannel(direction);
				this.#refresh();
			} else if (event.key === ' ') {
				event.preventDefault();
				this.#refresh();
			}
		});

		this.on(screen, 'click', () => {
			this.#refresh();
		});

		this.#listenToRescue();

		this.on(pencil, 'click', () => {
			this.#wind(Math.PI);
		});

		this.on(window, 'pagehide', () => {
			this.#remember();
		});

		this.#refresh();
	}

	disconnected() {
		this.#sounds.context?.suspend();
	}

	// The clock of the display goes on while nothing else draws. The hum, the hiss, and the motor stop while the toy is off the screen or the tab is hidden.
	visibilityChanged(isVisible) {
		this.#clockTimer?.cancel();
		if (isVisible) {
			this.#clockTimer = this.interval(5000, () => {
				this.#updateDisplay();
			});
		}

		if (this.#sounds.isOn) {
			if (isVisible) {
				this.#sounds.context.resume();
			} else {
				this.#sounds.context.suspend();
			}
		}
	}

	reducedMotionChanged() {
		this.#refresh();
	}

	// The focus goes to the TV when the focused button goes away, like Wait Until Tonight while the VCR tapes.
	get focusFallback() {
		return this.parts.screen;
	}

	// The texts of one press are joined, so a later one does not hide an earlier one, like the wedding that was taped over before the Stop, or a line of the tape that came as the press moved the tape on.
	say(text) {
		super.say(text, this.parts.status, {join: true});
	}

	#remember() {
		this.store('memory', this.#memory);
	}

	#tapeMemory() {
		return this.#memory.tapes[this.#vcr.tape];
	}

	#isWinding() {
		return ['forward', 'rewind', 'cue', 'review'].includes(this.#vcr.mode);
	}

	#isMoving() {
		return this.#vcr.mode in speeds;
	}

	// The live programs of a channel take turns. Each channel is a bit ahead of the others, so they do not change at the same time.
	#channelPrograms(channel) {
		return this.#programs.filter(program => program.channel === channel);
	}

	#programAt(channel, worldTime) {
		const list = this.#channelPrograms(channel);
		if (list.length === 0) {
			return undefined;
		}

		const index = Math.floor(worldTime / programLength) % list.length;
		return {program: list[index], time: worldTime % programLength};
	}

	#isAntennaHeld() {
		return this.#antennaState.held !== undefined || performance.now() < this.#antennaState.heldUntil;
	}

	// The signal is between 0 for only snow and 1 for a clear picture. A person who holds the rod is part of the antenna, so the picture is better while somebody holds it.
	#signalOf(channel, {isHeld = this.#isAntennaHeld()} = {}) {
		const ideal = reception[channel];
		if (!ideal) {
			return 0;
		}

		const {antenna} = this.#memory;
		const distance = Math.abs(antenna.left - ideal.left) + Math.abs(antenna.right - ideal.right);
		const signal = clamp(1.05 - (distance / 1.3), 0.08, 1) + (isHeld ? 0.25 : 0);
		return Math.min(signal, ideal.best);
	}

	// What is on the tape at a place: a recording that was made last wins over the ones under it, and over what was on the tape from the start.
	#contentAt(id, position) {
		const tape = this.#memory.tapes[id];
		for (const recording of tape.recordings.toReversed()) {
			if (position >= recording.from && position < recording.to) {
				if (recording.channel !== undefined) {
					const live = this.#programAt(recording.channel, recording.offset + position);
					return {scene: live?.program.scene, time: live?.time ?? 0, signal: Math.max(recording.signal ?? 1, 0.45), tracking: 50, recording};
				}

				return {scene: recording.scene, time: recording.start + position - recording.from, signal: Math.max(recording.signal ?? 1, 0.45), tracking: 50, recording};
			}
		}

		for (const part of tapes[id].parts) {
			if (position >= part.from && position < part.to) {
				return {scene: part.scene, time: position - part.from, signal: 1, tracking: part.tracking ?? tapes[id].tracking ?? 50, part};
			}
		}

		return undefined;
	}

	#trackingErrorOf(content) {
		return content ? Math.abs(Number(this.parts.tracking.value) - content.tracking) : 0;
	}

	// What the TV shows now: the scene, and how much snow, ghosts, and noise are on it.
	#describePicture() {
		const tv = this.#tv;
		const vcr = this.#vcr;
		if (tv.channel === 0) {
			if (vcr.mode === 'record' || vcr.timerRun) {
				const tuner = vcr.timerRun ? vcr.program.channel : vcr.tuner;
				const live = this.#programAt(tuner, liveClock(tuner));
				const signal = this.#signalOf(tuner);
				return {scene: live?.program.scene, time: live?.time ?? 0, snow: live ? snowOf(signal) : 1, ghost: ghostOf(signal), isRecording: true};
			}

			if (vcr.tape && ['play', 'pause', 'cue', 'review'].includes(vcr.mode)) {
				const position = this.#tapeMemory().position;
				const content = this.#contentAt(vcr.tape, position);
				if (!content?.scene) {
					return {snow: 1, isPaused: vcr.mode === 'pause', isSearching: this.#isWinding(), isTape: true};
				}

				const crinkle = this.#tapeMemory().crinkle;
				const isCrinkled = crinkle !== undefined && Math.abs(position - crinkle) < 2.5;
				return {
					scene: content.scene,
					time: content.time,
					snow: Math.max(snowOf(content.signal), isCrinkled ? 0.3 : 0),
					ghost: ghostOf(content.signal),
					trackingError: this.#trackingErrorOf(content),
					isPaused: vcr.mode === 'pause',
					isSearching: this.#isWinding(),
					isCrinkled,
					isTape: true,
				};
			}

			return {scene: 'blue', snow: 0, ghost: 0};
		}

		const live = this.#programAt(tv.channel, liveClock(tv.channel));
		if (!live) {
			return {snow: 1, ghost: 0};
		}

		const signal = this.#signalOf(tv.channel);
		return {scene: live.program.scene, time: live.time, snow: snowOf(signal), ghost: ghostOf(signal)};
	}

	#drawPicture(description, time) {
		const context = this.#pictureContext;
		const picture = this.#picture;
		const ghost = this.#ghost;
		const ghostContext = this.#ghostContext;
		context.save();
		if (description.isPaused && !this.reducedMotion) {
			context.translate(0, Math.random() < 0.4 ? 1 : 0);
		}

		if (scenes[description.scene]) {
			scenes[description.scene](context, description.time, this.reducedMotion);
		} else {
			fillRectangle(context, 0, 0, width, height, '#101010');
		}

		context.restore();

		// A ghost is the same picture a bit to the right, which came the long way, off a mountain.
		if (description.ghost > 0.02) {
			ghostContext.clearRect(0, 0, width, height);
			ghostContext.drawImage(picture, 0, 0);
			context.globalAlpha = description.ghost;
			context.drawImage(ghost, 9, 0);
			context.globalAlpha = description.ghost / 2;
			context.drawImage(ghost, 19, 1);
			context.globalAlpha = 1;
		}

		if (description.snow > 0.01) {
			context.globalAlpha = description.snow;
			drawNoise(context, 0, 0, width, height);
			context.globalAlpha = 1;
		}

		// Bad tracking: bands of noise that roll through the picture and tear it to the side.
		const error = description.trackingError ?? 0;
		if (error > 5) {
			const bands = 1 + Math.floor(error / 20);
			const thickness = 4 + (error * 0.35);
			for (let index = 0; index < bands; index++) {
				const y = (((index * 97) + (time * (18 + error))) % (height + 40)) - 20;
				context.drawImage(picture, 0, y, width, thickness * 2, (Math.random() * error * 0.4) - 4, y, width, thickness * 2);
				context.globalAlpha = 0.9;
				drawNoise(context, 0, y, width, thickness);
				context.globalAlpha = 1;
			}
		}

		if (description.isPaused) {
			const y = 206 + (this.reducedMotion ? 0 : Math.random() * 3);
			drawNoise(context, 0, y, width, 5);
			fillRectangle(context, 0, y + 2, width, 1, '#ffffffaa');
		}

		if (description.isSearching) {
			for (let index = 0; index < 3; index++) {
				const y = (((time * 260) + (index * 95)) % (height + 30)) - 15;
				context.drawImage(picture, 0, y, width, 14, 6, y, width, 14);
				drawNoise(context, 0, y, width, 8);
			}
		}

		// The crinkle in the tape, where the VCR chewed on it, makes the picture wave.
		if (description.isCrinkled) {
			ghostContext.clearRect(0, 0, width, height);
			ghostContext.drawImage(picture, 0, 0);
			for (let y = 0; y < height; y += 6) {
				context.drawImage(ghost, 0, y, width, 6, Math.sin((y * 0.08) + (time * 12)) * 8, y, width, 6);
			}
		}
	}

	#degaussAmount(time) {
		if (this.#tv.degauss === undefined) {
			return 0;
		}

		const elapsed = time - this.#tv.degauss;
		if (elapsed > 1.6) {
			return 0;
		}

		return this.reducedMotion ? 0.6 : 1 - (elapsed / 1.6);
	}

	#counterText() {
		if (!this.#vcr.tape) {
			return '0:00:00';
		}

		const counter = Math.round(this.#tapeMemory().position - this.#vcr.counterZero);
		const seconds = Math.abs(counter);
		return `${counter < 0 ? '-' : ''}${Math.floor(seconds / 3600)}:${String(Math.floor(seconds / 60) % 60).padStart(2, '0')}:${String(seconds % 60).padStart(2, '0')}`;
	}

	#compose(description, time) {
		const tv = this.#tv;
		const vcr = this.#vcr;
		const context = this.#compositeContext;
		const composite = this.#composite;
		const picture = this.#picture;
		context.fillStyle = '#000000';
		context.fillRect(0, 0, composite.width, composite.height);
		const degauss = this.#degaussAmount(time);
		if (degauss > 0) {
			// The degauss coil shakes the picture in waves and colors, with a thunk.
			for (let y = 0; y < height; y += 4) {
				const offset = Math.sin((y * 0.05) + (time * 22)) * 16 * degauss;
				context.drawImage(picture, 0, y, width, 4, offset * 2, y * 2, composite.width, 8);
			}

			const rainbow = context.createLinearGradient(0, 0, composite.width, composite.height);
			for (const [index, color] of ['#ff0000', '#ffff00', '#00ff00', '#00ffff', '#0000ff', '#ff00ff'].entries()) {
				rainbow.addColorStop(((index / 6) + (time * 0.8)) % 1, color);
			}

			context.globalCompositeOperation = 'overlay';
			context.globalAlpha = degauss * 0.7;
			context.fillStyle = rainbow;
			context.fillRect(0, 0, composite.width, composite.height);
			context.globalAlpha = 1;
			context.globalCompositeOperation = 'source-over';
		} else {
			context.drawImage(picture, 0, 0, composite.width, composite.height);
		}

		// The magnet bent the beams in the corner, so the colors are wrong there until the degauss.
		if (tv.magnet > 0) {
			const stain = context.createRadialGradient(540, 380, 10, 540, 380, 300);
			stain.addColorStop(0, '#ff00ff');
			stain.addColorStop(0.45, '#00ff88');
			stain.addColorStop(0.75, '#ffee00');
			stain.addColorStop(1, '#ffee0000');
			context.globalCompositeOperation = 'color';
			context.globalAlpha = tv.magnet * 0.85;
			context.fillStyle = stain;
			context.fillRect(0, 0, composite.width, composite.height);
			context.globalAlpha = 1;
			context.globalCompositeOperation = 'source-over';
		}

		if (tv.osd && time < tv.osd.until) {
			drawPixelText(context, tv.osd.text, 48, 40, '#33ff66', {scale: 5, shadow: '#003311'});
		}

		if (tv.channel === 0) {
			const isLasting = ['forward', 'rewind', 'eaten'].includes(vcr.mode);
			if (vcr.tape && (isLasting || time < vcr.osdUntil)) {
				drawPixelText(context, vcrLabels[vcr.mode] ?? '', 48, 400, '#ffffff', {scale: 5, shadow: '#000000'});
			}

			if (vcr.tape && ['forward', 'rewind'].includes(vcr.mode)) {
				drawPixelText(context, this.#counterText(), 320, 220, '#ffffff', {scale: 6, align: 'center', shadow: '#000000'});
			}
		}

		if (description.isRecording) {
			fillCircle(context, 560, 52, 12, Math.floor(time * 2) % 2 === 0 || this.reducedMotion ? '#ff2020' : '#661010');
			drawPixelText(context, 'REC', 536, 44, '#ff2020', {scale: 4, align: 'right', shadow: '#000000'});
		}

		context.drawImage(this.#glass, 0, 0);
	}

	// The glass of a TV that is off: dark green-gray, with the window of the living room in it.
	#drawOffScreen() {
		const {screen} = this.parts;
		const context = this.#screenContext;
		context.fillStyle = '#18201c';
		context.fillRect(0, 0, screen.width, screen.height);
		context.fillStyle = '#ffffff0d';
		context.fillRect(70, 50, 150, 190);
		context.fillStyle = '#18201c';
		context.fillRect(140, 50, 8, 190);
		context.fillRect(70, 140, 150, 8);
		const shine = context.createRadialGradient(200, 110, 10, 220, 130, 360);
		shine.addColorStop(0, '#ffffff14');
		shine.addColorStop(1, '#ffffff00');
		context.fillStyle = shine;
		context.fillRect(0, 0, screen.width, screen.height);
	}

	// Shows the picture on the screen, or the CRT that turns on from a line, or shrinks to a line and a dot that glows when it turns off.
	#present(time) {
		const tv = this.#tv;
		const {screen} = this.parts;
		const context = this.#screenContext;
		const composite = this.#composite;
		if (!tv.power) {
			if (tv.isOn) {
				context.drawImage(composite, 0, 0);
			} else {
				this.#drawOffScreen();
			}

			return;
		}

		const elapsed = time - tv.power.start;
		if (tv.power.isOn) {
			const progress = clamp(elapsed / 0.45, 0, 1);
			context.fillStyle = '#000000';
			context.fillRect(0, 0, screen.width, screen.height);
			const pictureHeight = Math.max(3, screen.height * (1 - ((1 - progress) ** 3)));
			context.drawImage(composite, 0, (screen.height - pictureHeight) / 2, screen.width, pictureHeight);
			context.fillStyle = `rgb(255 255 255 / ${(1 - progress) * 0.8})`;
			context.fillRect(0, (screen.height - pictureHeight) / 2, screen.width, pictureHeight);
			if (progress >= 1) {
				tv.power = undefined;
			}

			return;
		}

		if (elapsed >= 1.6) {
			tv.power = undefined;
			this.#drawOffScreen();
			return;
		}

		context.fillStyle = '#000000';
		context.fillRect(0, 0, screen.width, screen.height);
		const centerX = screen.width / 2;
		const centerY = screen.height / 2;
		if (elapsed < 0.12) {
			const lineHeight = Math.max(3, screen.height * (1 - (elapsed / 0.12)));
			context.drawImage(composite, 0, centerY - (lineHeight / 2), screen.width, lineHeight);
			context.fillStyle = `rgb(255 255 255 / ${elapsed / 0.12})`;
			context.fillRect(0, centerY - (lineHeight / 2), screen.width, lineHeight);
		} else if (elapsed < 0.24) {
			const lineWidth = Math.max(6, screen.width * (1 - ((elapsed - 0.12) / 0.12)));
			context.fillStyle = '#ffffff';
			context.fillRect(centerX - (lineWidth / 2), centerY - 2, lineWidth, 4);
		} else {
			const fade = 1 - ((elapsed - 0.24) / 1.36);
			const glow = context.createRadialGradient(centerX, centerY, 0, centerX, centerY, 18);
			glow.addColorStop(0, `rgb(255 255 255 / ${fade})`);
			glow.addColorStop(0.3, `rgb(200 230 255 / ${fade * 0.6})`);
			glow.addColorStop(1, 'rgb(200 230 255 / 0)');
			context.fillStyle = glow;
			context.fillRect(centerX - 20, centerY - 20, 40, 40);
		}
	}

	#rodTip(side) {
		const base = rodBase(side);
		const angle = this.#memory.antenna[side];
		return {x: base.x + (Math.sin(angle) * rodLength), y: base.y - (Math.cos(angle) * rodLength)};
	}

	// The rabbit ears: two rods that pull out, on a round foot on top of the TV.
	#drawAntenna() {
		const {antenna} = this.parts;
		const antennaState = this.#antennaState;
		const context = this.#antennaContext;
		context.clearRect(0, 0, antenna.width, antenna.height);
		for (const side of ['left', 'right']) {
			const base = rodBase(side);
			const tip = this.#rodTip(side);
			context.lineCap = 'round';
			for (const [index, lineWidth] of [4.5, 3.5, 2.5].entries()) {
				const from = index / 3;
				const to = (index + 1) / 3;
				context.strokeStyle = '#8a8a94';
				context.lineWidth = lineWidth + 1;
				context.beginPath();
				context.moveTo(base.x + ((tip.x - base.x) * from), base.y + ((tip.y - base.y) * from));
				context.lineTo(base.x + ((tip.x - base.x) * to), base.y + ((tip.y - base.y) * to));
				context.stroke();
				context.strokeStyle = '#e4e4ec';
				context.lineWidth = lineWidth - 1.5;
				context.stroke();
			}

			const isSelected = document.activeElement === antenna && antennaState.selected === side;
			if (isSelected) {
				context.strokeStyle = '#ffcc00';
				context.lineWidth = 2;
				context.beginPath();
				context.arc(tip.x, tip.y, 9, 0, Math.PI * 2);
				context.stroke();
			}

			fillCircle(context, tip.x, tip.y, 5, '#6a6a74');
			fillCircle(context, tip.x - 1, tip.y - 1, 3.5, '#f0f0f6');
			if (antennaState.held === side || (performance.now() < antennaState.heldUntil && antennaState.selected === side)) {
				context.font = '24px serif';
				context.textAlign = 'center';
				context.textBaseline = 'middle';
				context.fillText('✋', tip.x, tip.y);
			}
		}

		fillEllipse(context, 200, 132, 50, 26, '#2a2a2e');
		fillEllipse(context, 192, 120, 22, 7, '#4a4a52');
		fillCircle(context, 200, 110, 6, '#1a1a1e');
	}

	// The clock of the VCR is the time of the visitor’s computer, plus the minutes that the visitor set it off by.
	#clockMinutes() {
		const {clockOffset} = this.#memory;
		return clockOffset === undefined ? undefined : (((localMinutes() + clockOffset) % 1440) + 1440) % 1440;
	}

	// The display of the VCR: the blinking 12:00, the counter, the clock being set, a ShowView code being typed, or a short word like Err.
	#updateDisplay() {
		const vcr = this.#vcr;
		const {first: firstText, second: secondText, mode: modeText, info: infoText, recordLamp, slot} = this.parts;
		const time = now();
		let first;
		let second = '';
		let blink = '';

		// The flash is cleared after it is gone from the display, so the loop draws that frame too.
		if (vcr.flash && time >= vcr.flash.until) {
			vcr.flash = undefined;
		}

		if (vcr.flash) {
			first = vcr.flash.text;
		} else if (vcr.setting) {
			first = String(vcr.setting.hours).padStart(2, '0');
			second = `:${String(vcr.setting.minutes).padStart(2, '0')}`;
			blink = vcr.setting.field;
		} else if (vcr.entry !== undefined) {
			first = vcr.entry.padEnd(5, '-');
		} else if (vcr.timerRun) {
			const start = Number.parseInt(vcr.program.time, 10) * 60 + Number.parseInt(vcr.program.time.slice(3), 10);
			const minutes = start - 5 + Math.floor((vcr.timerRun.elapsed / Math.max(vcr.timerRun.duration, 0.1)) * 45);
			[first, second] = formatTime(minutes).split(/(?=:)/);
		} else if (vcr.tape && !vcr.isShowingClock) {
			[first, second] = this.#counterText().split(/(?=:\d\d$)/);
		} else {
			const minutes = this.#clockMinutes();
			if (minutes === undefined) {
				first = '12';
				second = ':00';
				blink = 'both';
			} else {
				[first, second] = formatTime(minutes).split(/(?=:)/);
			}
		}

		setText(firstText, first);
		setText(secondText, second);
		setState(firstText, ['hours', 'both'].includes(blink) ? 'blink' : '');
		setState(secondText, ['minutes', 'both'].includes(blink) ? 'blink' : '');
		setText(modeText, vcr.setting ? 'SET' : (vcr.entry === undefined ? (modeSymbols[vcr.mode] ?? '') : 'SV'));
		setText(infoText, `${vcr.isTimerArmed ? '⏲ ' : ''}P${vcr.tuner}`);
		setState(recordLamp, vcr.mode === 'record' || vcr.timerRun ? 'on' : '');
		setState(slot, vcr.mode === 'eaten' ? 'eaten' : (vcr.tape ? 'loaded' : (slot.dataset.state === 'target' ? 'target' : '')));

		const activeButtons = {
			play: ['play', 'record'].includes(vcr.mode),
			pause: vcr.mode === 'pause',
			forward: ['cue', 'forward'].includes(vcr.mode),
			rewind: ['review', 'rewind'].includes(vcr.mode),
			record: vcr.mode === 'record',
			clock: vcr.setting !== undefined,
			showview: vcr.entry !== undefined,
			timer: vcr.isTimerArmed,
		};
		for (const [name, button] of this.#vcrButtons) {
			setState(button, activeButtons[name] ? 'on' : '');
		}
	}

	#updateSound(description) {
		const tv = this.#tv;
		const vcr = this.#vcr;
		const sounds = this.#sounds;
		sounds.level(sounds.hum, tv.isOn ? 0.035 : 0);
		sounds.level(sounds.hiss, tv.isOn ? ((description?.snow ?? 0) * 0.05) + ((description?.trackingError ?? 0) > 5 ? 0.015 : 0) : 0);
		const speed = Math.abs(speeds[vcr.mode] ?? 0);
		if (sounds.motorOscillator && speed > 1) {
			const progress = vcr.tape ? this.#tapeMemory().position / tapeLength : 0;
			sounds.motorOscillator.frequency.setTargetAtTime(speed > 10 ? 380 + (progress * 500) : 160, sounds.context.currentTime, 0.1);
		}

		sounds.level(sounds.motor, speed > 1 ? (speed > 10 ? 0.035 : 0.02) : (vcr.timerRun ? 0.01 : 0));

		// The NRK clock ticks each second before the news.
		if (tv.isOn && description?.scene === 'news' && description.time < 10 && description.snow < 0.9) {
			const second = Math.floor(description.time);
			if (second !== this.#lastTick) {
				this.#lastTick = second;
				sounds.tick();
			}
		}
	}

	#render() {
		const time = now();
		this.#updateDisplay();
		if (!this.#tv.isOn && !this.#tv.power) {
			this.#updateSound();
			this.#present(time);
			return;
		}

		const description = this.#describePicture();
		this.#updateSound(description);
		this.#drawPicture(description, time);
		this.#compose(description, time);
		this.#present(time);
	}

	// The lines on a tape, which come in the status as the tape plays past them, and the end of a timer recording, which stops too early.
	#sayCaptions(before, after) {
		const id = this.#vcr.tape;
		for (const [at, text] of tapes[id].captions) {
			if (before < at && after >= at && this.#contentAt(id, at + 0.01)?.part) {
				this.say(text);
			}
		}

		for (const recording of this.#memory.tapes[id].recordings) {
			const program = this.#programs.find(item => item.code === recording.cut);
			if (program && before < recording.to && after >= recording.to) {
				const list = this.#channelPrograms(program.channel);
				const previous = list.at(list.indexOf(program) - 1);
				this.say(`Klikk. The tape stops before the end. ${previous.title} ran over, so ${program.title} started late, and the VCR stopped at the time in the newspaper.${program.scene === 'derrick' ? ' Now we never find out who the murderer was.' : ''}`);
			}
		}
	}

	#setMode(mode) {
		this.#vcr.mode = mode;
		this.#vcr.osdUntil = now() + 3;
		this.#vcr.pausedFor = 0;
	}

	#tick(seconds) {
		const vcr = this.#vcr;
		if (vcr.timerRun) {
			vcr.timerRun.elapsed += seconds;
			if (vcr.timerRun.elapsed >= vcr.timerRun.duration) {
				this.#finishTimer();
			}
		}

		if (!vcr.tape) {
			return;
		}

		if (vcr.mode === 'pause') {
			vcr.pausedFor += seconds;
			if (vcr.pausedFor > 300) {
				this.#setMode('stop');
				this.say('The VCR stopped by itself after five minutes of pause, so the heads do not wear out the tape.');
			}

			return;
		}

		if (!this.#isMoving()) {
			return;
		}

		const tape = this.#tapeMemory();
		const before = tape.position;
		tape.position = clamp(before + (speeds[vcr.mode] * seconds), 0, tapeLength);
		if (vcr.recording) {
			vcr.recording.to = Math.max(vcr.recording.to, tape.position);
		}

		if (vcr.mode === 'play') {
			this.#sayCaptions(before, tape.position);
		}

		if (tape.position <= 0 && speeds[vcr.mode] < 0) {
			this.#setMode('stop');
			this.#sounds.clunk();
			this.say(vcr.tape === 'rental' ? 'Clunk. Titanic is rewound. Be kind, please rewind: done!' : 'Clunk. The tape is rewound to the start.');
			this.#remember();
		} else if (tape.position >= tapeLength && speeds[vcr.mode] > 0) {
			this.#stopRecording();
			this.#setMode('rewind');
			this.say('The end of the tape. The VCR rewinds it by itself.');
		}
	}

	// Moves the time of the VCR on to now. With reduced motion, it runs only on each press, so the tape goes on by the time since the last press.
	#advance() {
		const time = now();
		const seconds = Math.min(time - this.#lastAdvance, this.reducedMotion ? 30 : 0.1);
		this.#lastAdvance = time;
		if (seconds > 0) {
			this.#tick(seconds);
		}
	}

	#needsFrames() {
		const tv = this.#tv;
		const vcr = this.#vcr;
		return !this.reducedMotion && (tv.isOn || tv.power !== undefined || this.#isMoving() || vcr.timerRun !== undefined || vcr.mode === 'pause' || vcr.flash !== undefined);
	}

	#refresh() {
		this.#advance();
		this.#render();
		this.#drawAntenna();
		this.#loop.start();
	}

	#flash(text) {
		this.#vcr.flash = {text, until: now() + 2};
	}

	#showOsd(text) {
		this.#tv.osd = {text, until: now() + 3};
	}

	// Turns the TV on with the crackle and the picture that grows from a line, or off with the snap to a dot.
	#setPower(isOn) {
		const {power, led} = this.parts;
		this.#tv.isOn = isOn;
		this.#tv.power = this.reducedMotion ? undefined : {isOn, start: now()};
		power.setAttribute('aria-pressed', String(isOn));
		setState(led, isOn ? 'on' : '');
		if (isOn) {
			this.#sounds.crackle();
		} else {
			this.#sounds.snap();
		}
	}

	// The TV jumps to AV when the VCR plays, through the SCART cable, and wakes up from standby for it.
	#switchToAv() {
		const tv = this.#tv;
		if (tv.isOn && tv.channel === 0) {
			return '';
		}

		const wasOn = tv.isOn;
		if (!wasOn) {
			this.#setPower(true);
		}

		tv.channel = 0;
		this.#showOsd('AV');
		return wasOn ? 'The TV jumps to AV through the SCART cable.' : 'The TV wakes up and jumps to AV through the SCART cable.';
	}

	#describeSignal(channel, {wasHeld = false} = {}) {
		if (channel === 0) {
			return 'The TV is on AV, so the rabbit ears only matter for what the VCR tapes.';
		}

		if (!reception[channel]) {
			return `Only snow on channel ${channel}. With the rabbit ears, Bergen gets three channels.`;
		}

		const signal = this.#signalOf(channel, {isHeld: false});
		const best = reception[channel].best;
		let text;
		if (signal >= best - 0.02) {
			text = channel === 3 ? 'That is as good as TVNorge gets in Bergen: a little snow, always.' : `A perfect picture on ${channelName(channel)}! Nobody move.`;
		} else if (signal > 0.7) {
			text = 'Almost clear. There is a little ghost to the right.';
		} else if (signal > 0.4) {
			text = 'Snow and ghosts. Pappa, from the sofa: «Litt til venstre!» (A bit to the left!)';
		} else {
			text = 'Mostly snow. Pappa: «Nei, den andre veien!» (No, the other way!)';
		}

		if (wasHeld && this.#signalOf(channel, {isHeld: true}) > signal + 0.05) {
			text += ' It was better while you held the rod: the best antenna is a person. Lillesøster has to stand there until Derrick is over.';
		}

		return text;
	}

	#describeChannel() {
		const tv = this.#tv;
		const vcr = this.#vcr;
		if (tv.channel === 0) {
			return `AV: the picture from the VCR.${vcr.tape && vcr.mode !== 'stop' ? '' : ' Blue, until the VCR plays.'}`;
		}

		const live = this.#programAt(tv.channel, liveClock(tv.channel));
		if (!live) {
			return this.#describeSignal(tv.channel);
		}

		const hint = this.#signalOf(tv.channel, {isHeld: false}) <= 0.7 ? 'Drag the rabbit ears on top of the TV.' : '';
		return sentences(`${channelName(tv.channel)}: ${live.program.title}.`, this.#describeSignal(tv.channel), hint);
	}

	#togglePower() {
		const tv = this.#tv;
		const vcr = this.#vcr;
		this.#setPower(!tv.isOn);
		if (!tv.isOn) {
			this.say('Snap! The picture shrinks to a line, then to a dot, which glows for a moment.');
			return;
		}

		// A VCR that already plays switches the TV to AV through the SCART cable, like when it starts to play.
		if (vcr.tape && ['play', 'pause', 'cue', 'review'].includes(vcr.mode)) {
			tv.channel = 0;
		}

		this.#showOsd(channelLabel(tv.channel));
		this.say(`The TV warms up with a hum and a crackle. ${this.#describeChannel()}`);
	}

	#changeChannel(direction) {
		const tv = this.#tv;
		if (!tv.isOn) {
			this.say('The TV is off. Press Power first.');
			return;
		}

		const order = [1, 2, 3, 4, 5, 6, 0];
		tv.channel = order.at((order.indexOf(tv.channel) + direction) % order.length);
		this.#showOsd(channelLabel(tv.channel));
		this.#sounds.burst(0.15, {volume: 0.08, frequency: 3000, type: 'highpass'});
		this.say(this.#describeChannel());
	}

	#degauss() {
		const tv = this.#tv;
		if (!tv.isOn) {
			this.say('The TV is off, so nothing happens.');
			return;
		}

		const time = now();
		if (time - tv.lastDegauss < 12) {
			this.say('Nothing happens. The degauss coil has to cool down for a while first, like on a real TV.');
			return;
		}

		const hadMagnet = tv.magnet > 0;
		tv.degauss = time;
		tv.lastDegauss = time;
		tv.magnet = 0;
		this.#sounds.thunk();
		this.say(hadMagnet ? 'BWOOONG! The picture wobbles in all the colors, and the rainbow of Lillesøster’s magnet is gone.' : 'BWOOONG! The picture wobbles in all the colors. It is the best button on the TV.');
	}

	#useMagnet() {
		const tv = this.#tv;
		tv.magnet = Math.min(1, tv.magnet + 0.5);
		this.say(tv.magnet >= 1 ? 'Lillesøster holds the magnet there even longer. The whole corner is purple and green now. Press Degauss!' : 'Lillesøster held the magnet from the fridge to the screen. Now there is a rainbow in the corner of the picture. Press Degauss on the TV!');
	}

	#blockedReason() {
		const vcr = this.#vcr;
		if (vcr.mode === 'eaten') {
			return 'The VCR is chewing on the tape. Wind it back with the pencil first.';
		}

		if (vcr.timerRun) {
			return 'Shh, the VCR is taping.';
		}

		if (vcr.isTimerArmed) {
			return 'The VCR is asleep and waits for the timer. Press Timer to wake it up.';
		}

		if (!vcr.tape) {
			return 'There is no tape in the VCR. Drag a tape from the shelf into the slot.';
		}

		return undefined;
	}

	#requireTape() {
		const reason = this.#blockedReason();
		if (reason) {
			this.say(reason);
			return false;
		}

		return true;
	}

	// How much of the wedding is left under the recordings, in seconds.
	#weddingLeft() {
		let seconds = 0;
		for (let position = 90; position < 150; position++) {
			if (this.#contentAt('wedding', position + 0.5)?.part?.scene === 'wedding') {
				seconds++;
			}
		}

		return seconds;
	}

	#sayAboutWedding(before) {
		if (this.#vcr.tape !== 'wedding') {
			return;
		}

		const after = this.#weddingLeft();
		if (after < before) {
			if (after === 0) {
				this.toast('💔 Mamma: «Nå er hele bryllupet vårt borte!»');
				this.say('The whole wedding of Mamma and Pappa is gone now. Taped over. Do not tell Mamma. Too late, she knows.');
			} else {
				this.say('You taped over even more of the wedding of Mamma and Pappa. Hide the tape.');
			}
		}
	}

	#stopRecording() {
		const vcr = this.#vcr;
		if (!vcr.recording) {
			return;
		}

		const recording = vcr.recording;
		vcr.recording = undefined;
		const tape = this.#tapeMemory();
		if (recording.to - recording.from < 0.5) {
			tape.recordings = tape.recordings.filter(other => other !== recording);
		} else {
			// A recording hides the ones under it, so those that it covers are gone.
			tape.recordings = tape.recordings.filter(other => other === recording || other.from < recording.from || other.to > recording.to).slice(-40);
		}

		this.#sayAboutWedding(vcr.weddingBefore);
		this.#remember();
	}

	#describeTapeAt() {
		const content = this.#contentAt(this.#vcr.tape, this.#tapeMemory().position);
		if (!content?.scene) {
			return 'Only snow: nothing is taped here.';
		}

		if (this.#trackingErrorOf(content) > 8) {
			return 'Bands of noise roll through the picture: turn the Tracking slider.';
		}

		return '';
	}

	#actions = {
		play: () => {
			if (!this.#requireTape()) {
				return;
			}

			if (this.#vcr.mode === 'play') {
				this.say('It plays already.');
				return;
			}

			this.#stopRecording();
			this.#setMode('play');
			this.say(sentences('Play.', this.#switchToAv(), this.#describeTapeAt()));
		},
		pause: () => {
			if (!this.#requireTape()) {
				return;
			}

			const {mode} = this.#vcr;
			if (mode === 'pause') {
				this.#setMode('play');
				this.say('Play again.');
			} else if (mode === 'record') {
				this.#stopRecording();
				this.#setMode('stop');
				this.say('The recording stops.');
			} else if (['play', 'cue', 'review'].includes(mode)) {
				this.#setMode('pause');
				this.say('Pause. The picture shakes, with a line of noise at the bottom. After five minutes, the VCR stops by itself.');
			} else {
				this.say('Pause only works while the tape plays.');
			}
		},
		forward: () => {
			if (!this.#requireTape()) {
				return;
			}

			const {mode} = this.#vcr;
			if (mode === 'record') {
				this.say('Not while it records. Press Stop first.');
			} else if (['play', 'review'].includes(mode)) {
				this.#setMode('cue');
				this.say('Picture search: the picture runs seven times as fast, with bars of noise.');
			} else if (mode === 'cue') {
				this.#setMode('play');
				this.say('Play again.');
			} else if (mode !== 'forward') {
				this.#setMode('forward');
				this.say('Fast forward, with a whine.');
			}
		},
		rewind: () => {
			if (!this.#requireTape()) {
				return;
			}

			const {mode} = this.#vcr;
			if (this.#tapeMemory().position <= 0) {
				this.say('The tape is already at the start.');
			} else if (mode === 'record') {
				this.say('Not while it records. Press Stop first.');
			} else if (['play', 'cue'].includes(mode)) {
				this.#setMode('review');
				this.say('Picture search backwards: everybody walks backwards.');
			} else if (mode === 'review') {
				this.#setMode('play');
				this.say('Play again.');
			} else if (mode !== 'rewind') {
				this.#setMode('rewind');
				this.say('Rewind, with a whine that gets higher.');
			}
		},
		stop: () => {
			if (!this.#requireTape()) {
				return;
			}

			if (this.#vcr.mode === 'stop') {
				this.say('It is stopped already.');
				return;
			}

			if (this.#isWinding()) {
				this.#sounds.clunk();
			}

			this.#stopRecording();
			this.#setMode('stop');
			this.#remember();
			this.say('Stop.');
		},
		record: () => {
			if (!this.#requireTape()) {
				return;
			}

			const vcr = this.#vcr;
			const tape = tapes[vcr.tape];
			if (tape.isProtected) {
				this.#flash('Prot');
				const title = tape.title;
				this.#takeOut();
				this.say(`The VCR spits ${title} out again: the tab on the back of it is broken off, so nobody can tape over it.`);
				return;
			}

			if (vcr.mode === 'record') {
				this.say('It records already.');
				return;
			}

			const position = this.#tapeMemory().position;
			vcr.weddingBefore = vcr.tape === 'wedding' ? this.#weddingLeft() : 0;
			this.#setMode('record');
			vcr.recording = {from: position, to: position, channel: vcr.tuner, offset: liveClock(vcr.tuner) - position, signal: Math.round(this.#signalOf(vcr.tuner) * 100) / 100};
			this.#tapeMemory().recordings.push(vcr.recording);
			const what = reception[vcr.tuner] ? channelName(vcr.tuner) : 'nothing but snow';
			this.say(`Recording P${vcr.tuner} (${what}) from the tuner of the VCR. It records its own channel, not the one on the TV: change it with Ch + and Ch − under the flap. Press Stop to end.`);
		},
		eject: () => {
			const vcr = this.#vcr;
			if (vcr.mode === 'eaten') {
				this.say('The tape is stuck. Wind it back with the pencil first.');
				return;
			}

			if (vcr.timerRun) {
				this.say('Shh, the VCR is taping.');
				return;
			}

			if (!vcr.tape) {
				this.say('There is no tape in the VCR.');
				return;
			}

			this.#stopRecording();

			// The VCR eats a tape now and then. The worn rental tape goes first.
			if ((vcr.tape === 'rental' && !this.#memory.hasEaten) || Math.random() < 0.06) {
				this.#eatTape();
				return;
			}

			const id = vcr.tape;
			const isUnwound = id === 'rental' && this.#tapeMemory().position > 2;
			this.#takeOut();
			this.say(`Clunk. Out comes ${tapes[id].title}${isUnwound ? ', not rewound. The video store will not like that.' : '.'}`);
		},
		clock: () => {
			const vcr = this.#vcr;
			if (vcr.didHold) {
				vcr.didHold = false;
				return;
			}

			if (vcr.setting) {
				this.#nextClockField();
			} else if (vcr.tape) {
				vcr.isShowingClock = !vcr.isShowingClock;
				this.say(vcr.isShowingClock ? 'The display shows the clock. Hold Clock to set it.' : 'The display shows the tape counter.');
			} else if (this.#memory.clockOffset === undefined) {
				this.say('The clock blinks 12:00, like it has since 1994. Hold the Clock button to set it. Pappa never found that out.');
			} else {
				this.say('Hold the Clock button to set the clock again.');
			}
		},
		'channel-up': () => {
			this.#changeVcrChannel(1);
		},
		'channel-down': () => {
			this.#changeVcrChannel(-1);
		},
		showview: () => {
			const vcr = this.#vcr;
			if (vcr.setting) {
				this.say('Finish setting the clock first: press Clock.');
				return;
			}

			if (this.#memory.clockOffset === undefined) {
				this.#flash('Err');
				this.say('The display says Err. The clock must be set first: hold Clock, then Ch + and Ch −. This is why Pappa has not taped anything since 1994.');
				return;
			}

			if (vcr.entry === undefined) {
				vcr.entry = '';
				this.say('ShowView: type the code from the newspaper with the number keys, and press ShowView again.');
				return;
			}

			const code = vcr.entry;
			vcr.entry = undefined;
			const program = this.#programs.find(item => item.code === code);
			if (!program) {
				this.#flash('Err');
				this.say('Err. That code is not in the newspaper. Pappa reads it out loud again, slowly.');
				return;
			}

			vcr.program = program;
			this.#flash('OK');
			this.#circle(program.code);
			this.say(`OK! The timer tapes ${program.title} on ${channelNames[program.channel]} at ${program.time}. Put in a tape that can be taped on, and press Timer to put the VCR to sleep.`);
		},
		timer: () => {
			const vcr = this.#vcr;
			const {tonight} = this.parts;
			if (vcr.timerRun) {
				this.say('Shh, the VCR is taping.');
				return;
			}

			if (vcr.isTimerArmed) {
				vcr.isTimerArmed = false;
				tonight.hidden = true;
				this.say('The VCR wakes up. The timer is off.');
				return;
			}

			if (!vcr.program) {
				this.#flash('Err');
				this.say('Err. Nothing is programmed. Press ShowView and type a code from the newspaper first.');
				return;
			}

			if (!vcr.tape || vcr.mode === 'eaten') {
				this.#flash('Err');
				this.say('Err. There is no tape in the VCR to tape on.');
				return;
			}

			if (tapes[vcr.tape].isProtected) {
				this.#flash('Prot');
				this.say('That tape is protected, so the timer cannot tape on it. Use the blank tape, or the Simpsons tape (I put tape over the hole of the tab).');
				return;
			}

			this.#stopRecording();
			this.#setMode('stop');
			vcr.isTimerArmed = true;
			tonight.hidden = false;
			this.say(`Zzz. The VCR is asleep and waits for ${vcr.program.time}, when ${vcr.program.title} starts on ${channelNames[vcr.program.channel]}. Now we wait until tonight.`);
		},
		reset: () => {
			const vcr = this.#vcr;
			if (!vcr.tape) {
				this.say('The counter needs a tape.');
				return;
			}

			vcr.counterZero = this.#tapeMemory().position;
			vcr.isShowingClock = false;
			this.say('The counter is 0:00:00 now. It counts from here, not from the start of the tape, which confuses everybody.');
		},
	};

	#changeVcrChannel(direction) {
		const vcr = this.#vcr;
		if (vcr.setting) {
			const field = vcr.setting.field;
			const limit = field === 'hours' ? 24 : 60;
			vcr.setting[field] = (vcr.setting[field] + direction + limit) % limit;
			return;
		}

		vcr.tuner = (((vcr.tuner - 1 + direction) % 6) + 6) % 6 + 1;
		this.say(`The tuner of the VCR is on P${vcr.tuner}: ${reception[vcr.tuner] ? channelName(vcr.tuner) : 'nothing but snow'}. The VCR records this channel, whatever the TV shows.`);
	}

	#startClockSetting() {
		const minutes = this.#clockMinutes() ?? 720;
		this.#vcr.entry = undefined;
		this.#vcr.setting = {field: 'hours', hours: Math.floor(minutes / 60), minutes: minutes % 60};
		this.say('Beep! Setting the clock: the hours blink. Press Ch + and Ch − to change them, and Clock to go on to the minutes.');
	}

	#nextClockField() {
		const vcr = this.#vcr;
		const memory = this.#memory;
		if (vcr.setting.field === 'hours') {
			vcr.setting.field = 'minutes';
			this.say('Now the minutes blink. Ch + and Ch −, then Clock.');
			return;
		}

		const minutes = (vcr.setting.hours * 60) + vcr.setting.minutes;
		vcr.setting = undefined;
		memory.clockOffset = minutes - localMinutes();
		this.#remember();
		const difference = Math.abs((((memory.clockOffset % 1440) + 1440 + 720) % 1440) - 720);
		if (difference <= 2) {
			this.celebrate();
			this.say(`The clock is set to ${formatTime(minutes)}, and that is right! It has not shown the right time since 1994. Pappa cannot believe it.`);
		} else {
			this.say(`The clock is set to ${formatTime(minutes)}. Not the right time, but at least it does not blink any more. Mamma: «Endelig!» (Finally!)`);
		}
	}

	#insert(id) {
		const vcr = this.#vcr;
		if (vcr.tape === id) {
			this.say('That tape is in the VCR. Press Eject to take it out.');
			return;
		}

		if (vcr.mode === 'eaten') {
			this.say('The VCR is still chewing on the last tape.');
			return;
		}

		if (vcr.tape) {
			this.say(`There is already a tape in the VCR: ${tapes[vcr.tape].title}. Press Eject first.`);
			return;
		}

		vcr.tape = id;
		vcr.counterZero = this.#tapeMemory().position;
		vcr.isShowingClock = false;
		this.#setMode('stop');
		setState(this.#tapeButtons.get(id), 'inserted');
		this.#sounds.clunk();
		const tape = tapes[id];
		if (tape.isProtected) {
			// A tape without the tab plays by itself, like a rented film.
			this.#setMode('play');
			const unwound = id === 'rental' && this.#tapeMemory().position > 5 ? 'The last renter did not rewind it, so it starts in the middle. Typical.' : '';
			this.say(sentences(`Clunk. ${tape.title} goes in and plays by itself, as the tab on the back is broken off.`, this.#switchToAv(), unwound, this.#describeTapeAt()));
		} else {
			this.say(`Clunk. ${tape.title[0].toUpperCase()}${tape.title.slice(1)} goes in. Press Play, or Record. The counter starts at 0:00:00, wherever the tape is.`);
		}
	}

	#takeOut() {
		const vcr = this.#vcr;
		const id = vcr.tape;
		this.#stopRecording();
		vcr.tape = undefined;
		this.#setMode('stop');
		setState(this.#tapeButtons.get(id), '');
		this.#sounds.clunk();
		if (vcr.isTimerArmed) {
			vcr.isTimerArmed = false;
			this.parts.tonight.hidden = true;
		}

		this.#remember();
	}

	#finishTimer() {
		const vcr = this.#vcr;
		const program = vcr.program;
		vcr.timerRun = undefined;
		vcr.isTimerArmed = false;
		vcr.program = undefined;
		this.parts.tonight.hidden = true;
		const tape = this.#tapeMemory();
		const list = this.#channelPrograms(program.channel);
		const previous = list.at(list.indexOf(program) - 1);
		const signal = Math.round(this.#signalOf(program.channel, {isHeld: false}) * 100) / 100;
		const start = tape.position;
		const startCounter = this.#counterText();
		const before = vcr.tape === 'wedding' ? this.#weddingLeft() : 0;

		// The program before ran over, so the tape starts with its end, and the program starts late. The VCR stops at the time in the newspaper, before the end.
		const recordings = [
			{from: start, to: start + 10, scene: previous.scene, start: programLength - 10, signal},
			{from: start + 10, to: start + 38, scene: program.scene, start: 0, signal, cut: program.code},
		].filter(recording => recording.from < tapeLength).map(recording => ({...recording, to: Math.min(recording.to, tapeLength)}));
		tape.recordings = [...tape.recordings.filter(other => other.from < start || other.to > start + 38), ...recordings].slice(-40);
		tape.position = Math.min(start + 38, tapeLength);
		this.#setMode('stop');
		this.#sayAboutWedding(before);
		this.#remember();
		this.#sounds.clunk();
		this.say(`Klikk. The VCR woke up by itself, taped, and stopped. Rewind to ${startCounter} on the counter, and play the tape to see if it got ${program.title}.${signal < 0.5 ? ' (The rabbit ears were not good for that channel, so it will be snowy.)' : ''}`);
	}

	#waitUntilTonight() {
		const vcr = this.#vcr;
		if (!vcr.isTimerArmed || vcr.timerRun || !vcr.tape) {
			return;
		}

		this.parts.tonight.hidden = true;
		vcr.timerRun = {elapsed: 0, duration: this.reducedMotion ? 0 : 5};
		this.say(`Hours later, at ${vcr.program.time}… Click! The VCR wakes up by itself and tapes. The REC light glows.`);
		if (this.reducedMotion) {
			this.#finishTimer();
		}
	}

	#circle(code) {
		for (const button of this.#programButtons) {
			if (button.dataset.vcrProgram === code) {
				button.dataset.state = 'circled';
			} else {
				setState(button, '');
			}
		}
	}

	#returnRental() {
		const memory = this.#memory;
		if (this.#vcr.tape === 'rental') {
			this.say('Titanic is in the VCR. Press Eject first.');
			return;
		}

		const tape = memory.tapes.rental;
		if (tape.position > 2) {
			memory.fees += 10;
			this.#sounds.kaching();
			this.say(`The man at the video store puts Titanic in his rewinder. «Spolegebyr: 10 kroner.» (Rewind fee.) I have paid ${memory.fees} kroner in rewind fees from my allowance. The next day, Lillesøster rents it again. The last renter did not rewind it either.`);
			tape.position = 60 + Math.round(Math.random() * 100);
		} else {
			this.celebrate();
			this.say(`Rewound! The man at the video store says «Takk!» and gives me a Twist from the jar. No fee. ${memory.fees > 0 ? `(I still paid ${memory.fees} kroner in fees before.)` : ''} Lillesøster rents it again right away.`.trim());
			tape.position = 0;
		}

		this.#remember();
	}

	#setFlap(isOpen) {
		const {flap, flapToggle} = this.parts;
		flap.hidden = !isOpen;
		flapToggle.setAttribute('aria-expanded', String(isOpen));
		flapToggle.textContent = isOpen ? '▲ Close the flap' : '▼ Open the flap';
		this.#sounds.click();
	}

	#sayTracking() {
		const vcr = this.#vcr;
		const {tracking} = this.parts;
		if (!vcr.tape || !['play', 'pause', 'cue', 'review'].includes(vcr.mode)) {
			this.say(`Tracking: ${tracking.value}. It only matters while a tape plays.`);
			return;
		}

		const content = this.#contentAt(vcr.tape, this.#tapeMemory().position);
		const error = this.#trackingErrorOf(content);
		if (!content?.scene) {
			this.say('Tracking does not help on snow. Nothing is taped here.');
		} else if (error <= 5) {
			this.say(`There! The picture is clear, at tracking ${tracking.value}. Every tape needs its own.`);
		} else if (error < 20) {
			this.say('Better, but a band of noise still rolls through.');
		} else {
			this.say('The noise bands roll over the whole picture. Try the other way.');
		}
	}

	#isOverSlot(event) {
		const rectangle = this.parts.slot.getBoundingClientRect();
		return event.clientX > rectangle.left - 24 && event.clientX < rectangle.right + 24 && event.clientY > rectangle.top - 24 && event.clientY < rectangle.bottom + 24;
	}

	// A tape is dragged to the slot, or pressed to go in.
	#makeDraggable(id, button) {
		const {slot} = this.parts;
		let drag;
		const endDrag = (event, shouldInsert) => {
			if (!drag) {
				return;
			}

			const wasDragging = drag.isDragging;
			drag = undefined;
			if (!wasDragging) {
				return;
			}

			this.#suppressClickUntil = performance.now() + 400;
			setState(button, this.#vcr.tape === id ? 'inserted' : '');
			setState(slot, '');
			this.#advance();
			if (shouldInsert && this.#isOverSlot(event)) {
				this.#insert(id);
			} else if (shouldInsert) {
				this.say('The tape goes back on the shelf. Drop it on the slot of the VCR.');
			}

			this.#refresh();
		};

		this.on(button, 'pointerdown', event => {
			if (button.dataset.state === 'inserted' || event.button !== 0) {
				return;
			}

			drag = {x: event.clientX, y: event.clientY, pointerId: event.pointerId, isDragging: false};
			button.setPointerCapture(event.pointerId);
		});

		this.on(button, 'pointermove', event => {
			if (!drag || event.pointerId !== drag.pointerId) {
				return;
			}

			const x = event.clientX - drag.x;
			const y = event.clientY - drag.y;
			if (!drag.isDragging && Math.hypot(x, y) > 8) {
				drag.isDragging = true;
				button.dataset.state = 'dragging';
			}

			if (drag.isDragging) {
				button.style.setProperty('--vcr-drag-x', `${x}px`);
				button.style.setProperty('--vcr-drag-y', `${y}px`);
				if (!this.#vcr.tape) {
					if (this.#isOverSlot(event)) {
						slot.dataset.state = 'target';
					} else {
						setState(slot, '');
					}
				}
			}
		});

		this.on(button, 'pointerup', event => {
			endDrag(event, true);
		});

		this.on(button, 'pointercancel', event => {
			endDrag(event, false);
		});

		this.on(button, 'click', () => {
			if (performance.now() < this.#suppressClickUntil) {
				return;
			}

			this.#advance();
			this.#insert(id);
			this.#refresh();
		});
	}

	// The rabbit ears turn with a drag on the end of a rod, or with the arrow keys.
	#listenToAntenna() {
		const {antenna} = this.parts;
		const antennaState = this.#antennaState;
		const memory = this.#memory;

		this.on(antenna, 'pointerdown', event => {
			const point = canvasPoint(antenna, event);
			const distances = ['left', 'right'].map(side => {
				const tip = this.#rodTip(side);
				const base = rodBase(side);
				// The rod can be taken anywhere along it, not only at the end.
				let best = Infinity;
				for (let step = 0.3; step <= 1; step += 0.1) {
					best = Math.min(best, Math.hypot(point.x - (base.x + ((tip.x - base.x) * step)), point.y - (base.y + ((tip.y - base.y) * step))));
				}

				return [side, best];
			});
			const [side, distance] = distances[0][1] <= distances[1][1] ? distances[0] : distances[1];
			if (distance > 40) {
				return;
			}

			antennaState.held = side;
			antennaState.selected = side;
			antenna.setPointerCapture(event.pointerId);
			this.#refresh();
		});

		this.on(antenna, 'pointermove', event => {
			if (!antennaState.held) {
				return;
			}

			const point = canvasPoint(antenna, event);
			const base = rodBase(antennaState.held);
			memory.antenna[antennaState.held] = clamp(Math.atan2(point.x - base.x, base.y - point.y), -1.5, 1.5);
			this.#refresh();
		});

		const releaseAntenna = () => {
			if (!antennaState.held) {
				return;
			}

			antennaState.held = undefined;
			this.#remember();
			this.#advance();
			this.say(this.#tv.isOn ? this.#describeSignal(this.#tv.channel, {wasHeld: true}) : 'The TV is off, so you cannot see if it helps. But it looks good.');
			this.#refresh();
		};

		this.on(antenna, 'pointerup', releaseAntenna);
		this.on(antenna, 'pointercancel', releaseAntenna);

		this.on(antenna, 'keydown', event => {
			if (event.key === ' ') {
				event.preventDefault();
				antennaState.selected = antennaState.selected === 'left' ? 'right' : 'left';
				this.say(`The ${antennaState.selected} rod.`);
				this.#refresh();
				return;
			}

			const direction = {ArrowLeft: -1, ArrowRight: 1}[event.key];
			if (!direction) {
				return;
			}

			event.preventDefault();
			const side = antennaState.selected;
			memory.antenna[side] = clamp(memory.antenna[side] + (direction * 0.06), -1.5, 1.5);
			antennaState.heldUntil = performance.now() + 1500;
			this.#refresh();
		});

		this.on(antenna, 'keyup', event => {
			if (['ArrowLeft', 'ArrowRight'].includes(event.key)) {
				antennaState.heldUntil = 0;
				this.#remember();
				this.say(this.#tv.isOn ? this.#describeSignal(this.#tv.channel) : 'The TV is off, so you cannot see if it helps.');
				this.#refresh();
			}
		});

		for (const type of ['focus', 'blur']) {
			this.on(antenna, type, () => {
				this.#drawAntenna();
			});
		}
	}

	#drawRescue() {
		const {rescueCanvas} = this.parts;
		const rescue = this.#rescue;
		const context = this.#rescueContext;
		fillRectangle(context, 0, 0, rescueCanvas.width, rescueCanvas.height, '#d8c8a8');
		for (let y = 8; y < rescueCanvas.height; y += 14) {
			fillRectangle(context, 0, y, rescueCanvas.width, 1, '#c8b494');
		}

		context.fillStyle = '#161618';
		context.beginPath();
		context.roundRect(36, 28, 168, 86, 6);
		context.fill();
		fillRectangle(context, 60, 34, 120, 14, '#fdfbf0');
		drawPixelText(context, tapes[this.#vcr.tape].title, 120, 38, '#222222', {align: 'center'});
		for (const x of [86, 154]) {
			fillCircle(context, x, 70, 21, '#2a2a30');
		}

		fillCircle(context, 154, 70, 10 + ((1 - rescue.wound) * 9), '#5a3010');
		fillCircle(context, 86, 70, 10 + (rescue.wound * 9), '#5a3010');
		for (const x of [86, 154]) {
			fillCircle(context, x, 70, 7, '#f0f0f0');
			fillCircle(context, x, 70, 3, '#2a2a30');
		}

		// The tape hangs out in loops. The more the visitor winds, the shorter they get.
		if (rescue.wound < 1) {
			const hang = (1 - rescue.wound) * 34;
			context.strokeStyle = '#5a3010';
			context.lineWidth = 3;
			context.lineCap = 'round';
			context.beginPath();
			context.moveTo(96, 114);
			context.bezierCurveTo(70, 114 + hang, 120, 120 + hang, 110, 114 + (hang * 0.6));
			context.bezierCurveTo(100, 108 + hang, 160, 124 + hang, 144, 114);
			context.stroke();
		}

		// The pencil, in the hole of the left reel.
		context.save();
		context.translate(reelCenter.x, reelCenter.y);
		context.rotate(rescue.angle);
		fillRectangle(context, -4, -64, 8, 54, '#f2c230');
		fillRectangle(context, -4, -70, 8, 7, '#e88aa0');
		fillRectangle(context, -4, -63, 8, 3, '#c0c0c0');
		fillPolygon(context, [[-4, -10], [4, -10], [0, 0]], '#e8c8a0');
		fillPolygon(context, [[-1.5, -4], [1.5, -4], [0, 0]], '#333333');
		context.restore();
		drawPixelText(context, `${Math.round(rescue.wound * 100)}%`, 232, 6, '#5a3010', {scale: 2, align: 'right'});
	}

	#eatTape() {
		const rescue = this.#rescue;
		this.#setMode('eaten');
		this.#vcr.isTimerArmed = false;
		this.parts.tonight.hidden = true;
		rescue.wound = 0;
		rescue.angle = 0;
		this.#memory.hasEaten = true;
		this.#remember();
		this.parts.rescue.hidden = false;
		this.#drawRescue();
		this.#sounds.crunch();
		this.#flash('Err');
		this.toast('📼 The VCR ate the tape!');
		this.say('Krrrsj! The VCR ate the tape. Pappa pulled it out, but the tape hangs out like spaghetti. Wind it back with the pencil.');
	}

	#wind(delta) {
		const rescue = this.#rescue;
		if (this.#vcr.mode !== 'eaten') {
			return;
		}

		rescue.angle += delta;
		rescue.wound = clamp(rescue.wound + (delta / (Math.PI * 2 * rescueTurns)), 0, 1);
		if (delta < 0 && performance.now() - rescue.lastHint > 3000) {
			rescue.lastHint = performance.now();
			this.say('The wrong way! Now even more tape hangs out. Turn it clockwise.');
		}

		this.#sounds.tick();
		this.#drawRescue();
		// A tiny rounding error of the sum must not ask for one more press.
		if (rescue.wound > 0.999) {
			this.#finishRescue();
		}
	}

	#finishRescue() {
		const vcr = this.#vcr;
		const id = vcr.tape;
		const tape = this.#tapeMemory();
		tape.crinkle = tape.position;
		const crinkleAt = `${Math.floor(tape.position / 60)}:${String(Math.floor(tape.position % 60)).padStart(2, '0')}`;
		vcr.tape = undefined;
		this.#setMode('stop');
		setState(this.#tapeButtons.get(id), '');
		this.parts.rescue.hidden = true;
		this.#remember();
		this.celebrate();
		this.say(`Phew! ${tapes[id].title[0].toUpperCase()}${tapes[id].title.slice(1)} is back in its cassette, with a crinkle at ${crinkleAt} from the start of the tape. The picture will always wave there now. Pappa: «Det var nære på.» (That was close.)`);
		this.#tapeButtons.get(id).focus();
		this.#refresh();
	}

	// The pencil turns with a drag in circles around the reel, with the arrow keys, or with the button.
	#listenToRescue() {
		const {rescueCanvas} = this.parts;
		const rescue = this.#rescue;

		this.on(rescueCanvas, 'pointerdown', event => {
			const point = canvasPoint(rescueCanvas, event);
			rescue.lastAngle = Math.atan2(point.y - reelCenter.y, point.x - reelCenter.x);
			rescueCanvas.setPointerCapture(event.pointerId);
		});

		this.on(rescueCanvas, 'pointermove', event => {
			if (rescue.lastAngle === undefined) {
				return;
			}

			const point = canvasPoint(rescueCanvas, event);
			const angle = Math.atan2(point.y - reelCenter.y, point.x - reelCenter.x);
			let delta = angle - rescue.lastAngle;
			if (delta > Math.PI) {
				delta -= Math.PI * 2;
			} else if (delta < -Math.PI) {
				delta += Math.PI * 2;
			}

			rescue.lastAngle = angle;
			this.#wind(delta);
		});

		for (const type of ['pointerup', 'pointercancel']) {
			this.on(rescueCanvas, type, () => {
				rescue.lastAngle = undefined;
			});
		}

		this.on(rescueCanvas, 'keydown', event => {
			const direction = {ArrowRight: 1, ArrowDown: 1, ArrowLeft: -1, ArrowUp: -1}[event.key];
			if (direction) {
				event.preventDefault();
				this.#wind(direction * Math.PI / 3);
			}
		});
	}
}
