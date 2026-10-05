// Sindre’s Winter Games ’99 on the 1999 page: a game of winter sports in eight events, like Winter Games by Epyx (1985), Track & Field by Konami (1983), and Nagano Winter Olympics ’98. The visitor signs up, carries the torch in the opening ceremony, and competes against five rivals for the medals of a country, with a commentator, the weather of the day, a podium with the anthem of the winner, an interview, world records with three initials, a medal table, and a closing ceremony. Everything is drawn on one canvas of 320 × 200 pixels, which runs only while it is on the screen and the tab is visible. The athlete, the records, the medals, the ghost of the best skating race, and the replay of the best jump are kept in the browser.

const randomItem = items => items[Math.floor(Math.random() * items.length)];
const randomBetween = (minimum, maximum) => minimum + (Math.random() * (maximum - minimum));
const clamp = (value, minimum, maximum) => Math.min(Math.max(value, minimum), maximum);
const shuffle = items => {
	const copy = [...items];
	for (let index = copy.length - 1; index > 0; index--) {
		const other = Math.floor(Math.random() * (index + 1));
		[copy[index], copy[other]] = [copy[other], copy[index]];
	}

	return copy;
};

// A random number around 0, mostly between -1 and 1, like the luck of the day.
const randomNormal = () => (Math.random() + Math.random() + Math.random() - 1.5) / 0.75;

// A tiny pixel font of 3 × 5 for the screen, so the text is crisp at any size. Each letter is five rows of three bits.
const pixelFont = {
	A: [2, 5, 7, 5, 5], B: [6, 5, 6, 5, 6], C: [3, 4, 4, 4, 3], D: [6, 5, 5, 5, 6], E: [7, 4, 6, 4, 7], F: [7, 4, 6, 4, 4], G: [3, 4, 5, 5, 3], H: [5, 5, 7, 5, 5], I: [7, 2, 2, 2, 7], J: [1, 1, 1, 5, 2], K: [5, 5, 6, 5, 5], L: [4, 4, 4, 4, 7], M: [5, 7, 7, 5, 5], N: [6, 5, 5, 5, 5], O: [2, 5, 5, 5, 2], P: [6, 5, 6, 4, 4], Q: [2, 5, 5, 6, 3], R: [6, 5, 6, 5, 5], S: [3, 4, 2, 1, 6], T: [7, 2, 2, 2, 2], U: [5, 5, 5, 5, 7], V: [5, 5, 5, 5, 2], W: [5, 5, 7, 7, 5], X: [5, 5, 2, 5, 5], Y: [5, 5, 2, 2, 2], Z: [7, 1, 2, 4, 7],
	0: [7, 5, 5, 5, 7], 1: [2, 6, 2, 2, 7], 2: [6, 1, 2, 4, 7], 3: [6, 1, 2, 1, 6], 4: [5, 5, 7, 1, 1], 5: [7, 4, 6, 1, 6], 6: [3, 4, 7, 5, 7], 7: [7, 1, 2, 2, 2], 8: [7, 5, 7, 5, 7], 9: [7, 5, 7, 1, 6],
	' ': [0, 0, 0, 0, 0], '.': [0, 0, 0, 0, 2], ',': [0, 0, 0, 2, 4], '!': [2, 2, 2, 0, 2], '?': [6, 1, 2, 0, 2], ':': [0, 2, 0, 2, 0], '-': [0, 0, 7, 0, 0], '+': [0, 2, 7, 2, 0], '/': [1, 1, 2, 4, 4], '\'': [2, 2, 0, 0, 0], '’': [2, 2, 0, 0, 0], '(': [1, 2, 2, 2, 1], ')': [4, 2, 2, 2, 4], '×': [0, 5, 2, 5, 0], '°': [2, 5, 2, 0, 0], '%': [5, 1, 2, 4, 5], '<': [1, 2, 4, 2, 1], '>': [4, 2, 1, 2, 4], '=': [0, 7, 0, 7, 0], '♥': [0, 5, 7, 7, 2], '*': [0, 5, 2, 5, 0], '#': [5, 7, 5, 7, 5],
	Æ: [3, 6, 7, 6, 7], Ø: [3, 5, 7, 5, 6], Å: [2, 0, 2, 5, 7], Ö: [5, 2, 5, 5, 2], Ä: [5, 2, 5, 7, 5], Ü: [5, 0, 5, 5, 7], É: [1, 2, 7, 6, 7],
};

// Draws text in the pixel font, at a whole pixel, with a scale for bigger letters, and a dark shadow so it shows on the snow. The alignment is `left`, `center`, or `right`.
const drawText = (context, text, x, y, color, {scale = 1, align = 'left', shadow = 'rgba(0, 0, 0, 0.6)'} = {}) => {
	const characters = [...String(text).toUpperCase()];
	const width = ((characters.length * 4) - 1) * scale;
	const left = Math.round(align === 'center' ? x - (width / 2) : (align === 'right' ? x - width : x));
	const passes = shadow ? [[shadow, 1], [color, 0]] : [[color, 0]];
	for (const [fill, offset] of passes) {
		context.fillStyle = fill;
		let characterLeft = left;
		for (const character of characters) {
			const rows = pixelFont[character] ?? pixelFont['?'];
			for (const [row, bits] of rows.entries()) {
				for (let column = 0; column < 3; column++) {
					if (bits & (4 >> column)) {
						context.fillRect(characterLeft + (column * scale) + offset, Math.round(y) + (row * scale) + offset, scale, scale);
					}
				}
			}

			characterLeft += 4 * scale;
		}
	}
};

const fillShape = (context, color, x, y, width, height) => {
	context.fillStyle = color;
	context.fillRect(Math.round(x), Math.round(y), Math.round(width), Math.round(height));
};

const fillEllipse = (context, color, x, y, radiusX, radiusY) => {
	context.fillStyle = color;
	context.beginPath();
	context.ellipse(x, y, Math.max(radiusX, 0.1), Math.max(radiusY, 0.1), 0, 0, Math.PI * 2);
	context.fill();
};

const fillPolygon = (context, color, points) => {
	context.fillStyle = color;
	context.beginPath();
	for (const [x, y] of points) {
		context.lineTo(x, y);
	}

	context.closePath();
	context.fill();
};

const strokeLine = (context, color, width, points) => {
	context.strokeStyle = color;
	context.lineWidth = width;
	context.beginPath();
	for (const [x, y] of points) {
		context.lineTo(x, y);
	}

	context.stroke();
};

const formatSeconds = seconds => {
	const minutes = Math.floor(seconds / 60);
	const rest = (seconds - (minutes * 60)).toFixed(2);
	return minutes > 0 ? `${minutes}:${rest.padStart(5, '0')}` : rest;
};

// The countries of the Games, with the colors of their athletes, a rival with a made-up name, and the melody of their anthem, as notes and beats (one beat when it has none). The melodies are the first part of each anthem, from public domain scores.
const countries = {
	NOR: {name: 'Norway', suit: '#ba0c2f', trim: '#00205b', rival: 'Ola Nordmann', tempo: 84, anthem: 'B4:1.5 A4:.5 G#4 F#4 E4 F#4 G#4 A4 B4:1.5 C#5:.5 B4 A4 G#4:2 R:2 C#5:1.5 B4:.5 A4 G#4 F#4 G#4 A4 B4 B4:1.5 C#5:.5 C#5 D#5 E5:2 R:2 E5:1.5 E5:.5 D#5:.75 D#5:.25 C#5:.75 C#5:.25 B4:2 G#4:2 A4:1.5 A4:.5 G#4 G#4 F#4:2 R B4:.75 B4:.25 B4 C#5 C#5 D#5 D#5:2 E5:2 E5:1.5 E5:.5 D#5 E5 F#5:2 R F#5:.75 F#5:.25 F#5 G#5 A5 G#5 F#5:2 E5 D#5:.75 C#5:.25 B4:1.75 C#5:.25 C#5 D#5 E5:3'},
	SWE: {name: 'Sweden', suit: '#006aa7', trim: '#fecc00', rival: 'Sven Snöberg', tempo: 76, anthem: 'D5:.5 D5 Bb4:.5 Bb4:.5 Bb4 C5:.5 D5:.5 D5 C5:.5 Bb4:.5 A4 R:.5 C5:.5 C5 A4:.5 Bb4:.5 C5:.5 A4:.5 D5:.75 Bb4:.25 G4:2 F4 R:.5 F4:.5 Bb4 Bb4:.5 C5:.5 A4 A4:.5 Bb4:.5 G4:.75 F4:.25 G4:.5 A4:.5 F4 R:.5 F4:.5 Bb4:.75 A4:.25 Bb4:.5 C5:.5 D5:.5 Bb4:.5 Eb5:.5 D5:.5 C5:2 Bb4:2'},
	FIN: {name: 'Finland', suit: '#ffffff', trim: '#003580', rival: 'Mika Pakkanen', tempo: 84, anthem: 'E4:.5 C#4:.5 D4:.5 E4:1.5 A4:.5 B4:.75 E4:.25 C#5:2 A4 F#4:.75 B4:.25 A4 G#4 A4:2 E4 B4:.75 A4:.25 G#4:.5 F#4:.5 E4:.5 D4:.5 C#4:.5 F#4:.5 E4 E4 B4:.75 A4:.25 G#4:.5 F#4:.5 E4:.5 D4:.5 C#4:.5 F#4:.5 E4:1.5 E4:.5 A4:.75 E4:.25 C#4:.5 E4:.5 A4:.5 B4:.5 C#5:2 A4 F#4:.75 B4:.25 A4 G#4 A4:2'},
	GER: {name: 'Germany', suit: '#222222', trim: '#ffce00', rival: 'Hans Schneemann', tempo: 80, anthem: 'Eb4:1.5 F4:.5 G4 F4 Ab4 G4 F4:.5 D4:.5 Eb4 C5 Bb4 Ab4 G4 F4 G4:.5 Eb4:.5 Bb4:2 F4 G4 F4:.5 D4:.5 Bb3 Ab4 G4 F4:.5 D4:.5 Bb3 Bb4 Ab4 G4:1.5 G4:.5 A4 A4:.5 Bb4:.5 Bb4:2 Eb5:1.5 D5:.5 D5:.5 C5:.5 Bb4 C5:1.5 Bb4:.5 Bb4:.5 Ab4:.5 G4 F4:1.5 G4:.25 Ab4:.25 Bb4:.5 C5:.5 Ab4:.5 F4:.5 Eb4 G4:.5 F4:.5 Eb4:2'},
	USA: {name: 'USA', suit: '#002868', trim: '#bf0a30', rival: 'Chuck Blizzard', tempo: 84, anthem: 'F4:.75 D4:.25 Bb3 D4 F4 Bb4:2 D5:.75 C5:.25 Bb4 D4 E4 F4:2 F4:.5 F4:.5 D5:1.5 C5:.5 Bb4 A4:2 G4:.5 A4:.5 Bb4 Bb4 F4 D4 Bb3:2'},
	CAN: {name: 'Canada', suit: '#d80621', trim: '#ffffff', rival: 'Pierre Poutine', tempo: 80, anthem: 'A4:2 C5:1.5 C5:.5 F4:3 G4 A4 Bb4 C5 D5 G4:4 A4:2 B4:1.5 B4:.5 C5:3 D5 E5 E5 D5 D5 C5:3 R C5:2 F5:1.5 F5:.5 D5 Bb4 A4 G4 C5:2 E4:2 F4:4'},
	JPN: {name: 'Japan', suit: '#ffffff', trim: '#bc002d', rival: 'Kenji Yukimura', tempo: 60, anthem: 'D4 C4 D4 E4 G4 E4 D4:2 E4 G4 A4 G4:.5 A4:.5 D5 B4 A4 G4 E4 G4 A4:2 D5 C5 D5 R E4 G4 A4 G4 E4:1.5 G4:.5 D4 R A4 C5 D5:2 C5 D5 A4 G4 A4 G4:.5 E4:.5 D4:2'},
	GBR: {name: 'Great Britain', suit: '#012169', trim: '#c8102e', rival: 'Nigel Drizzle', tempo: 80, anthem: 'G4 G4 A4 F#4:1.5 G4:.5 A4 B4 B4 C5 B4:1.5 A4:.5 G4 A4 G4 F#4 G4:3 D5 D5 D5 D5:1.5 C5:.5 B4 C5 C5 C5 C5:1.5 B4:.5 A4 B4 C5:.5 B4:.5 A4:.5 G4:.5 B4:1.5 C5:.5 D5 E5:.5 C5:.5 B4 A4 G4:3'},
};

// Draws the flag of a country in a box, in pixels, as simple as the flags of the games of the time.
const drawFlag = (context, code, x, y, width, height) => {
	const box = (color, left, top, right, bottom) => {
		fillShape(context, color, x + (left * width), y + (top * height), (right - left) * width, (bottom - top) * height);
	};

	const nordic = (background, outer, inner) => {
		box(background, 0, 0, 1, 1);
		box(outer, 6 / 22, 0, 10 / 22, 1);
		box(outer, 0, 6 / 16, 1, 10 / 16);
		if (inner) {
			box(inner, 7 / 22, 0, 9 / 22, 1);
			box(inner, 0, 7 / 16, 1, 9 / 16);
		}
	};

	context.save();
	context.beginPath();
	context.rect(x, y, width, height);
	context.clip();
	switch (code) {
		case 'NOR': {
			nordic('#ba0c2f', '#ffffff', '#00205b');
			break;
		}

		case 'SWE': {
			nordic('#006aa7', '#fecc00');
			break;
		}

		case 'FIN': {
			nordic('#ffffff', '#003580');
			break;
		}

		case 'GER': {
			box('#000000', 0, 0, 1, 1 / 3);
			box('#dd0000', 0, 1 / 3, 1, 2 / 3);
			box('#ffce00', 0, 2 / 3, 1, 1);
			break;
		}

		case 'USA': {
			for (let stripe = 0; stripe < 7; stripe++) {
				box(stripe % 2 === 0 ? '#bf0a30' : '#ffffff', 0, stripe / 7, 1, (stripe + 1) / 7);
			}

			box('#002868', 0, 0, 0.45, 4 / 7);
			for (let row = 0; row < 3; row++) {
				for (let column = 0; column < 4; column++) {
					fillShape(context, '#ffffff', x + (width * 0.45 * (column + 0.5) / 4), y + (height * (4 / 7) * (row + 0.5) / 3), Math.max(1, width / 22), Math.max(1, width / 22));
				}
			}

			break;
		}

		case 'CAN': {
			box('#d80621', 0, 0, 1, 1);
			box('#ffffff', 0.25, 0, 0.75, 1);
			const middle = x + (width / 2);
			const top = y + (height * 0.2);
			const size = height * 0.6;
			fillPolygon(context, '#d80621', [[middle, top], [middle + (size * 0.18), top + (size * 0.3)], [middle + (size * 0.45), top + (size * 0.22)], [middle + (size * 0.3), top + (size * 0.65)], [middle + (size * 0.05), top + (size * 0.65)], [middle + (size * 0.05), top + size], [middle - (size * 0.05), top + size], [middle - (size * 0.05), top + (size * 0.65)], [middle - (size * 0.3), top + (size * 0.65)], [middle - (size * 0.45), top + (size * 0.22)], [middle - (size * 0.18), top + (size * 0.3)]]);
			break;
		}

		case 'JPN': {
			box('#ffffff', 0, 0, 1, 1);
			fillEllipse(context, '#bc002d', x + (width / 2), y + (height / 2), height * 0.3, height * 0.3);
			break;
		}

		case 'GBR': {
			box('#012169', 0, 0, 1, 1);
			strokeLine(context, '#ffffff', height * 0.2, [[x, y], [x + width, y + height]]);
			strokeLine(context, '#ffffff', height * 0.2, [[x + width, y], [x, y + height]]);
			strokeLine(context, '#c8102e', height * 0.07, [[x, y], [x + width, y + height]]);
			strokeLine(context, '#c8102e', height * 0.07, [[x + width, y], [x, y + height]]);
			box('#ffffff', 0.42, 0, 0.58, 1);
			box('#ffffff', 0, 0.36, 1, 0.64);
			box('#c8102e', 0.46, 0, 0.54, 1);
			box('#c8102e', 0, 0.42, 1, 0.58);
			break;
		}

		default: {
			box('#888888', 0, 0, 1, 1);
		}
	}

	context.restore();
};

// The mascots, drawn in pixels of `size`, standing with their feet at the point. Each is a few blocks of color, like a sprite of the time.
const drawMascot = (context, mascot, x, y, size = 1, {hop = 0, torch = false} = {}) => {
	const block = (color, left, top, width, height) => {
		fillShape(context, color, x + (left * size), y - hop - ((12 - top) * size), width * size, height * size);
	};

	switch (mascot) {
		case 'troll': {
			block('#6a8a3a', -3, 2, 7, 8);
			block('#d84a2a', -4, 0, 9, 3);
			block('#8aa85a', -2, 4, 2, 2);
			block('#8aa85a', 2, 4, 2, 2);
			block('#000000', -1, 5, 1, 1);
			block('#000000', 2, 5, 1, 1);
			block('#a07a4a', 0, 6, 2, 3);
			block('#4a3a2a', -2, 10, 2, 2);
			block('#4a3a2a', 2, 10, 2, 2);
			break;
		}

		case 'moose': {
			block('#7a4a2a', -4, 4, 8, 6);
			block('#c8a060', -6, 0, 3, 3);
			block('#c8a060', 4, 0, 3, 3);
			block('#c8a060', -3, 2, 1, 2);
			block('#c8a060', 3, 2, 1, 2);
			block('#000000', -2, 6, 1, 1);
			block('#000000', 2, 6, 1, 1);
			block('#5a3a1a', -1, 8, 3, 2);
			block('#5a3a1a', -3, 10, 2, 2);
			block('#5a3a1a', 2, 10, 2, 2);
			break;
		}

		case 'lemming': {
			block('#e8a050', -3, 3, 7, 7);
			block('#3a2a1a', -3, 1, 7, 3);
			block('#000000', -2, 5, 1, 1);
			block('#000000', 2, 5, 1, 1);
			block('#ffffff', -1, 7, 3, 1);
			block('#3a2a1a', -3, 10, 2, 2);
			block('#3a2a1a', 2, 10, 2, 2);
			break;
		}

		default: {
			// Glitter the unicorn, white with a rainbow mane and a golden horn.
			block('#ffffff', -4, 4, 8, 6);
			block('#ffffff', 1, 1, 4, 4);
			block('#ffd700', 4, -2, 1, 3);
			block('#ff66cc', -1, 1, 2, 2);
			block('#66ccff', -2, 3, 2, 2);
			block('#cc66ff', -3, 5, 2, 2);
			block('#000000', 3, 2, 1, 1);
			block('#dddddd', -3, 10, 2, 2);
			block('#dddddd', 2, 10, 2, 2);
		}
	}

	if (torch) {
		block('#8a6a3a', 5, 3, 1, 5);
		block('#ffcc00', 4, 1, 3, 2);
		block('#ff6600', 5, 0, 1, 2);
	}
};

// An athlete in the colors of a country, standing, from the side, with the feet at the point.
const drawAthlete = (context, code, x, y, {pose = 0, size = 1} = {}) => {
	const {suit, trim} = countries[code] ?? countries.NOR;
	const block = (color, left, top, width, height) => {
		fillShape(context, color, x + (left * size), y + (top * size), width * size, height * size);
	};

	const legSwing = Math.round(Math.sin(pose) * 2);
	block(trim, -2 + legSwing, -6, 2, 6);
	block(trim, 1 - legSwing, -6, 2, 6);
	block(suit, -2, -13, 5, 7);
	block('#f3c9a0', -1, -17, 3, 4);
	block(trim, -2, -18, 5, 2);
};

// The frequency of a note like `C#5` or `Bb3`.
const noteFrequency = note => {
	const [, letter, accidental, octave] = /^([A-G])([#b]?)(\d)$/.exec(note);
	const semitone = {C: 0, D: 2, E: 4, F: 5, G: 7, A: 9, B: 11}[letter] + (accidental === '#' ? 1 : (accidental === 'b' ? -1 : 0));
	return 440 * (2 ** ((((Number(octave) + 1) * 12) + semitone - 69) / 12));
};

// A melody written as notes with their beats, like `B4:1.5 A4:.5 R:2`, as a list of notes with a start and a length in beats. `R` is a rest.
const parseMelody = text => {
	let beat = 0;
	const notes = [];
	for (const token of text.trim().split(/\s+/)) {
		const [note, length = '1'] = token.split(':');
		const beats = Number(length);
		if (note !== 'R') {
			notes.push({note, beat, beats});
		}

		beat += beats;
	}

	return {notes, beats: beat};
};

// The events, with the label of the big button, how a result is told, and whether a lower result is better (a time). The rivals get a result between `beginner` and `expert`, the results of bots that played each event many times like a first-timer and like an expert, and `weatherEffect` changes their results for the weather of the day, as it changes the result of the athlete. The first world records are by the best rival of Norway.
const eventInfo = {
	skijump: {title: 'Ski Jump', short: 'SKI JUMP', place: 'Holmenkollen', action: 'JUMP', isOutdoor: true, format: value => `${value.toFixed(1)} points`, beginner: 130, expert: 290, record: 306.4, weatherEffect: weather => weather.wind * 9},
	biathlon: {title: 'Biathlon', short: 'BIATHLON', place: 'Birkebeineren', action: 'FIRE', isOutdoor: true, isTime: true, beginner: 80, expert: 47, record: 45.2, weatherEffect: weather => (weather.snow === 'heavy' ? 3 : (weather.snow === 'light' ? 1 : 0)) + (Math.abs(weather.wind) * 0.8)},
	skating: {title: 'Speed Skating 500 m', short: 'SKATING 500 M', place: 'Vikingskipet', action: 'GO', isTime: true, beginner: 48, expert: 38.4, record: 37.2, weatherEffect: weather => (weather.ice === 'keen' ? -0.4 : (weather.ice === 'heavy' ? 0.4 : 0))},
	slalom: {title: 'Slalom', short: 'SLALOM', place: 'Hafjell', action: 'GO', isOutdoor: true, isTime: true, beginner: 42, expert: 26.5, record: 25.6, weatherEffect: weather => (weather.fog * 4) + (weather.snow === 'heavy' ? 2.5 : (weather.snow === 'light' ? 1 : 0))},
	bobsleigh: {title: 'Bobsleigh', short: 'BOBSLEIGH', place: 'Hunderfossen', action: 'JUMP IN', isOutdoor: true, isTime: true, beginner: 55, expert: 41.5, record: 40.6, weatherEffect: weather => ((weather.temperature + 18) / 19 * 2.5) - 1.25},
	curling: {title: 'Curling', short: 'CURLING', place: 'Hamar', action: 'THROW', format: value => `${value} points`, isWhole: true, beginner: 5, expert: 14, record: 18},
	hockey: {title: 'Ice Hockey Shootout', short: 'HOCKEY', place: 'Håkons Hall', action: 'SHOOT', format: value => `${value} of 10`, isWhole: true, beginner: 4, expert: 8.4, record: 10},
	figure: {title: 'Figure Skating', short: 'FIGURE SKATING', place: 'Nordlyshallen', action: 'JUMP', format: value => `${value.toFixed(1)} of 12.0`, beginner: 8.6, expert: 11.4, record: 11.8},
};

const eventIds = Object.keys(eventInfo);

const formatResult = (id, value) => {
	if (value === undefined) {
		return 'Did not finish';
	}

	const info = eventInfo[id];
	return info.isTime ? `${formatSeconds(value)} s` : info.format(value);
};

const isBetter = (id, value, other) => {
	if (value === undefined) {
		return false;
	}

	if (other === undefined) {
		return true;
	}

	return eventInfo[id].isTime ? value < other : value > other;
};

const setUpGames = (element, {screen: canvas, commentary, sound: soundButton, quit: quitButton, wear: wearLine, register: registerForm, name: nameField, initials: initialsField, ceremony: ceremonyPanel, skip: skipButton, menu: menuPanel, athlete: athleteLine, all: allButton, showRecords: showRecordsButton, showMedals: showMedalsButton, newAthlete: newAthleteButton, howTo: howToPanel, howToTitle, weather: weatherLine, start: startButton, playing: playingPanel, tip: tipLine, results: resultsPanel, resultsTitle, resultsBody, resultsNote, recordForm, recordInitials, interview: interviewPanel, question: questionLine, reply: replyLine, next: nextButton, anthem: anthemButton, replay: replayButton, records: recordsPanel, recordsBody, recordsReplay: recordsReplayButton, clear: clearButton, medals: medalsPanel, medalsNote, medalsBody, closing: closingButton, newGames: newGamesButton}) => {
	// The sound of the Games, made in the browser. It is off until the visitor presses a button that says it plays sound. Long tunes, like the anthems and the music of the figure skating, follow the rule of the page that one tune plays at a time.
	const sound = {
		isOn: false,
		context: undefined,
		output: undefined,
		// Takes the audio of the element, which `sound()` only makes in the handler of a click.
		start() {
			const audio = element.sound();
			if (audio) {
				this.context = audio.context;
				this.output = audio.output;
				this.context.resume();
			}
		},
		get isReady() {
			// A context that still starts, like in Safari right after the click, plays the sounds when it has started.
			return this.isOn && this.context !== undefined && this.context.state !== 'closed';
		},
		beep(frequency, duration = 0.1, {type = 'square', volume = 0.05, when = 0, destination} = {}) {
			if (!this.isReady) {
				return;
			}

			const start = this.context.currentTime + Math.max(0, when);
			const oscillator = new OscillatorNode(this.context, {type, frequency});
			const gain = new GainNode(this.context, {gain: 0});
			gain.gain.setValueAtTime(0, start);
			gain.gain.linearRampToValueAtTime(volume, start + 0.008);
			gain.gain.exponentialRampToValueAtTime(0.0001, start + duration);
			oscillator.connect(gain).connect(destination ?? this.output);
			oscillator.start(start);
			oscillator.stop(start + duration + 0.02);
		},
		// A burst of noise, for the gun, the crowd, a crash, and the scrape of the skis.
		noise(duration = 0.3, {volume = 0.08, frequency = 1200, rise = 0.01} = {}) {
			if (!this.isReady) {
				return;
			}

			const length = Math.ceil(this.context.sampleRate * duration);
			const buffer = new AudioBuffer({length, sampleRate: this.context.sampleRate});
			const data = buffer.getChannelData(0);
			for (let index = 0; index < length; index++) {
				data[index] = (Math.random() * 2) - 1;
			}

			const start = this.context.currentTime;
			const source = new AudioBufferSourceNode(this.context, {buffer});
			const filter = new BiquadFilterNode(this.context, {type: 'bandpass', frequency, Q: 0.7});
			const gain = new GainNode(this.context, {gain: 0});
			gain.gain.setValueAtTime(0, start);
			gain.gain.linearRampToValueAtTime(volume, start + rise);
			gain.gain.exponentialRampToValueAtTime(0.0001, start + duration);
			source.connect(filter).connect(gain).connect(this.output);
			source.start(start);
		},
		gun() {
			this.noise(0.35, {volume: 0.25, frequency: 900, rise: 0.002});
		},
		crowd() {
			this.noise(1.6, {volume: 0.06, frequency: 700, rise: 0.4});
		},
		// The start clock of the TV: three low beeps and a high one.
		countdown() {
			for (const [index, frequency] of [440, 440, 440, 880].entries()) {
				this.beep(frequency, index === 3 ? 0.4 : 0.15, {when: index * 0.5});
			}
		},
		fanfare() {
			for (const [index, note] of ['C5', 'E5', 'G5', 'C6'].entries()) {
				this.beep(noteFrequency(note), index === 3 ? 0.5 : 0.15, {type: 'square', when: index * 0.12});
			}
		},
	};

	// The tune that plays now: an anthem, or the music of the figure skating. It tells the rest of the page when it starts and stops, so one tune plays at a time, and the element stops it when another tune of the page starts.
	const tune = {
		gain: undefined,
		timer: undefined,
		onStop: undefined,
		get isPlaying() {
			return this.gain !== undefined;
		},
		begin(onStop) {
			this.stop();
			if (!sound.isReady) {
				return false;
			}

			this.gain = new GainNode(sound.context, {gain: 1});
			this.gain.connect(sound.output);
			this.onStop = onStop;
			element.music(true);
			return true;
		},
		// Plays a whole melody now, like an anthem, and stops by itself at the end.
		play(text, tempo, onStop) {
			if (!this.begin(onStop)) {
				return false;
			}

			const {notes, beats} = parseMelody(text);
			const secondsPerBeat = 60 / tempo;
			for (const {note, beat, beats: length} of notes) {
				sound.beep(noteFrequency(note), Math.max(0.12, length * secondsPerBeat * 0.92), {type: 'triangle', volume: 0.12, when: 0.1 + (beat * secondsPerBeat), destination: this.gain});
				// A second voice an octave lower, like a brass band.
				sound.beep(noteFrequency(note) / 2, Math.max(0.12, length * secondsPerBeat * 0.9), {type: 'square', volume: 0.025, when: 0.1 + (beat * secondsPerBeat), destination: this.gain});
			}

			this.timer = element.timeout(((beats * secondsPerBeat) + 0.6) * 1000, () => {
				this.stop();
			});
			return true;
		},
		stop() {
			this.timer?.cancel();
			if (!this.gain) {
				return;
			}

			const {gain, onStop} = this;
			this.gain = undefined;
			this.onStop = undefined;
			try {
				gain.gain.setTargetAtTime(0, sound.context.currentTime, 0.05);
				element.timeout(400, () => {
					gain.disconnect();
				});
			} catch {}

			element.music(false);
			onStop?.();
		},
	};

	const actionButton = element.querySelector('[data-winter-control="action"]');

	const context = canvas.getContext('2d');
	const {width, height} = canvas;
	const panels = [registerForm, ceremonyPanel, menuPanel, howToPanel, playingPanel, resultsPanel, recordsPanel, medalsPanel];

	const isValidAthlete = athlete => typeof athlete?.name === 'string' && typeof athlete.initials === 'string' && Object.hasOwn(countries, athlete.country) && typeof athlete.mascot === 'string';
	const isObject = value => typeof value === 'object' && value !== null && !Array.isArray(value);
	const isValidGames = games => Array.isArray(games?.rivals)
		&& games.rivals.length === 5
		&& games.rivals.every(rival => Object.hasOwn(countries, rival?.code) && Number.isFinite(rival.skill))
		&& isObject(games.medals)
		&& Object.entries(games.medals).every(([code, counts]) => Object.hasOwn(countries, code) && Array.isArray(counts) && counts.length === 3 && counts.every(Number.isInteger))
		&& isObject(games.best)
		&& Object.values(games.best).every(Number.isInteger)
		&& (games.podiums === undefined || (isObject(games.podiums) && Object.values(games.podiums).every(podium => Array.isArray(podium) && podium.every(code => Object.hasOwn(countries, code)))));
	const storedAthlete = element.stored('athlete');
	const storedGames = element.stored('games');
	const storedRecords = element.stored('records', {});

	const state = {
		scene: 'title',
		time: 0,
		sceneTime: 0,
		athlete: isValidAthlete(storedAthlete) ? storedAthlete : undefined,
		games: isValidGames(storedGames) ? storedGames : undefined,
		records: storedRecords && typeof storedRecords === 'object' ? storedRecords : {},
		eventId: undefined,
		weather: undefined,
		run: undefined,
		queue: [],
		results: undefined,
		lastInput: -10,
		mashes: Math.max(0, Math.floor(Number(element.stored('mashes', 0)) || 0)),
		held: {left: false, right: false, up: false, down: false, action: false},
	};

	// The five rivals of the Games, each from another country than the athlete, from the best to the worst.
	const makeGames = () => {
		const others = shuffle(Object.keys(countries).filter(code => code !== state.athlete.country)).slice(0, 5);
		return {
			rivals: others.map((code, index) => ({code, skill: [0.96, 0.82, 0.68, 0.52, 0.36][index]})),
			medals: {},
			best: {},
			podiums: {},
		};
	};

	const saveGames = () => {
		element.store('games', state.games);
	};

	// The weather of an event outdoors: the temperature, the wind (a head wind is plus), new snow, and fog. The events indoors have the ice of the hall, which can be fast (keen) or slow (heavy).
	const makeWeather = id => {
		const info = eventInfo[id];
		let weather;
		if (info.isOutdoor) {
			const temperature = Math.round(randomBetween(-18, 1));
			const wind = Math.round(randomBetween(-3, 3) * 10) / 10;
			const snow = randomItem(['none', 'none', 'none', 'light', 'heavy']);
			const fog = id === 'slalom' && Math.random() < 0.3 ? randomBetween(0.4, 0.75) : 0;
			const parts = [`${temperature > 0 ? '+' : ''}${temperature} °C`, Math.abs(wind) < 0.3 ? 'no wind' : `${wind > 0 ? 'head' : 'tail'} wind ${Math.abs(wind).toFixed(1)} m/s`, snow === 'none' ? (temperature < -12 ? 'clear and bitter cold' : 'clear') : `${snow} snow`];
			if (fog > 0) {
				parts.push('fog');
			}

			weather = {temperature, wind, snow, fog, description: parts.join(', ')};
		} else {
			// Keen or heavy ice changes the curling stones and the skates, and the other halls have perfect ice.
			const ice = id === 'curling' || id === 'skating' ? randomItem(['keen', 'normal', 'normal', 'heavy']) : 'normal';
			weather = {ice, description: `indoors, no weather! The ice is ${ice === 'keen' ? 'keen (fast)' : (ice === 'heavy' ? 'heavy (slow)' : 'perfect')}`};
		}

		// The text for the green screen, in capitals, and the words of the commentator.
		return {...weather, text: `${info.place}: ${weather.description}.`.toUpperCase(), spoken: `${info.title} at ${info.place}: ${weather.description}.`};
	};

	// The commentator, who talks in Norwegian and English, like the Norwegian TV of the time, a little too excited.
	const lines = {
		start: [['Og der går han!', 'And there he goes!'], ['Nå gjelder det!', 'This is it!'], ['Hele Norge ser på!', 'All of Norway is watching!'], ['Dette blir spennende!', 'This will be exciting!']],
		great: [['Helt fantastisk!', 'Absolutely fantastic!'], ['For en prestasjon!', 'What a performance!'], ['Dette er verdensklasse!', 'This is world class!'], ['Jeg har gåsehud!', 'I have goose bumps!']],
		good: [['Det var bra!', 'That was good!'], ['Solid gjennomført.', 'A solid effort.'], ['Godkjent!', 'Approved!']],
		bad: [['Å nei, å nei!', 'Oh no, oh no!'], ['Det var ikke helt bra.', 'That was not quite good.'], ['Au, det gjorde vondt.', 'Ouch, that hurt.'], ['Nå er det tungt.', 'Now it is heavy going.']],
		fall: [['Han faller! Han faller!', 'He falls! He falls!'], ['Huff, der gikk det galt.', 'Oops, that went wrong.'], ['Rett i snøen!', 'Straight into the snow!']],
		gold: [['Gull! Gull! Gull!', 'Gold! Gold! Gold!'], ['Vi har en olympisk mester!', 'We have an Olympic champion!'], ['Dette er større enn Lillehammer!', 'This is bigger than Lillehammer!']],
		medal: [['En medalje! Fantastisk!', 'A medal! Fantastic!'], ['Pallplass! Pallplass!', 'On the podium! On the podium!']],
		none: [['Det holder ikke til medalje i dag.', 'Not enough for a medal today.'], ['Det er ingen skam å bli nummer fire.', 'There is no shame in fourth place.'], ['Neste gang, kanskje!', 'Next time, maybe!']],
		record: [['Verdensrekord! Verdensrekord!', 'World record! World record!'], ['Rekorden er knust!', 'The record is smashed!']],
	};

	let lastLine = '';
	const comment = (kind, extra = '') => {
		const choices = lines[kind].filter(([norwegian]) => norwegian !== lastLine);
		const [norwegian, english] = randomItem(choices.length > 0 ? choices : lines[kind]);
		lastLine = norwegian;
		element.say(`🎙️ «${norwegian}» ${english}${extra ? ` ${extra}` : ''}`, commentary);
	};

	const say = text => {
		element.say(text, commentary);
	};

	// Shows one part below the screen, and hides the others. The focus goes to the new part, so it is never lost on a hidden part, unless the focus target is `false`, like when the page opens.
	const showPanel = (panel, focusTarget) => {
		for (const other of panels) {
			other.hidden = other !== panel;
		}

		if (focusTarget !== false) {
			(focusTarget ?? panel.querySelector('h3')).focus({preventScroll: true});
		}
	};

	// Scrolls the screen into view when an event starts, as the Start button can be below it on a phone, and the screen only runs while it is on the screen.
	const showScreen = () => {
		canvas.scrollIntoView({block: 'nearest', behavior: element.reducedMotion ? 'auto' : 'smooth'});
	};

	const setActionLabel = label => {
		actionButton.textContent = label;
	};

	// The wear of the keyboard, from all the button mashing. The Track & Field machines of the arcades got trackballs instead of buttons, as the buttons broke.
	const wearStages = [
		[0, 'ALL KEYS OK.'],
		[300, 'THE ARROW KEYS ARE WARM.'],
		[800, 'THE ARROW KEYS ARE SHINY.'],
		[1500, 'MOM ASKS WHAT THAT NOISE IS.'],
		[2500, 'THE LEFT ARROW KEY WOBBLES.'],
		[4000, 'DAD SAYS NO NEW KEYBOARD.'],
		[6000, 'THE TRACK & FIELD MACHINES GOT TRACKBALLS FOR THIS!'],
		[10_000, 'THE KEYBOARD HAS LEFT THE BUILDING.'],
	];

	const showWear = () => {
		const [, text] = wearStages.findLast(([minimum]) => state.mashes >= minimum);
		wearLine.textContent = `KEYBOARD WEAR: ${state.mashes.toLocaleString('en-US')} MASHES. ${text}`;
	};

	// Falling snow, which is in front of many scenes. It stands still for visitors who prefer reduced motion.
	const snowflakes = Array.from({length: 70}, () => ({x: Math.random() * 320, y: Math.random() * 200, speed: randomBetween(8, 24), size: Math.random() < 0.2 ? 2 : 1}));

	const drawSnowfall = (amount = 1, drift = 0) => {
		const count = Math.round(snowflakes.length * amount);
		for (const flake of snowflakes.slice(0, count)) {
			const x = element.reducedMotion ? flake.x : (((flake.x + (state.time * drift * flake.speed * 0.5)) % width) + width) % width;
			const y = element.reducedMotion ? flake.y : (flake.y + (state.time * flake.speed)) % height;
			fillShape(context, '#ffffff', x, y, flake.size, flake.size);
		}
	};

	const drawSky = (top, bottom, bottomY = height) => {
		const sky = context.createLinearGradient(0, 0, 0, bottomY);
		sky.addColorStop(0, top);
		sky.addColorStop(1, bottom);
		context.fillStyle = sky;
		context.fillRect(0, 0, width, height);
	};

	// Mountains far away, which move slowly with the camera.
	const drawMountains = (offset, horizon, color = '#c8d4e8', peak = 40) => {
		context.fillStyle = color;
		context.beginPath();
		context.moveTo(0, height);
		for (let x = 0; x <= width; x += 8) {
			const position = x + offset;
			context.lineTo(x, horizon - (Math.abs(Math.sin(position / 61)) * peak) - (Math.sin(position / 23) * 6));
		}

		context.lineTo(width, height);
		context.fill();
	};

	// A box with a dark background for the numbers of the TV on the screen.
	const drawPanel = (x, y, boxWidth, boxHeight, color = 'rgba(0, 0, 40, 0.75)') => {
		fillShape(context, color, x, y, boxWidth, boxHeight);
		fillShape(context, 'rgba(255, 255, 255, 0.5)', x, y, boxWidth, 1);
	};

	// The five waffles of the Games, in rings, like a certain logo, but tastier.
	const drawWaffleRings = (x, y, size = 1) => {
		const colors = ['#0085c7', '#f4c300', '#000000', '#009f3d', '#df0024'];
		for (const [index, color] of colors.entries()) {
			const ringX = x + ((index - 2) * 11 * size);
			const ringY = y + (index % 2 === 0 ? 0 : 5 * size);
			fillEllipse(context, 'rgba(232, 176, 80, 0.9)', ringX, ringY, 4.5 * size, 4.5 * size);
			context.strokeStyle = 'rgba(150, 90, 30, 0.9)';
			context.lineWidth = 1;
			context.beginPath();
			context.moveTo(ringX - (4 * size), ringY);
			context.lineTo(ringX + (4 * size), ringY);
			context.moveTo(ringX, ringY - (4 * size));
			context.lineTo(ringX, ringY + (4 * size));
			context.stroke();
			context.strokeStyle = color;
			context.lineWidth = 2 * size;
			context.beginPath();
			context.arc(ringX, ringY, 6 * size, 0, Math.PI * 2);
			context.stroke();
		}
	};

	// A crowd in the stands: rows of heads and jackets in the colors of the flags, scattered the same way every frame. With `wave`, some of them jump.
	const drawCrowd = (left, top, crowdWidth, crowdHeight, {offset = 0, wave = false} = {}) => {
		const colors = ['#ba0c2f', '#ffffff', '#00205b', '#ffd21f', '#3a8a4a', '#e08040'];
		fillShape(context, '#22222e', left, top, crowdWidth, crowdHeight);
		for (let row = 0; row * 5 < crowdHeight - 3; row++) {
			for (let column = 0; column * 4 < crowdWidth + 8; column++) {
				const seat = (row * 131) + column + Math.floor(offset / 4);
				const hash = Math.imul(seat, 2_654_435_761) >>> 0;
				if (hash % 7 === 0) {
					continue;
				}

				const x = left + (column * 4) - (((offset % 4) + 4) % 4) + ((row % 2) * 2);
				if (x < left - 2 || x > left + crowdWidth) {
					continue;
				}

				const jump = wave && !element.reducedMotion && (hash + Math.floor(state.time * 6)) % 5 === 0 ? 1 : 0;
				const y = top + (row * 5) - jump;
				fillShape(context, colors[hash % colors.length], x, y + 2, 3, 3);
				fillShape(context, '#f3c9a0', x + 1, y, 1, 2);
			}
		}
	};

	const isBlinkOn = (period = 0.5) => element.reducedMotion || Math.floor(state.time / period) % 2 === 0;

	// A meter on the screen: a bar with a zone that is good, and a needle.
	const drawMeter = (x, y, meterWidth, value, {label, good = [0.4, 0.6], color = '#ffee55'} = {}) => {
		drawPanel(x - 2, y - (label ? 9 : 2), meterWidth + 4, label ? 17 : 10);
		if (label) {
			drawText(context, label, x, y - 7, '#ffffff');
		}

		fillShape(context, '#552222', x, y, meterWidth, 6);
		fillShape(context, '#22aa44', x + (good[0] * meterWidth), y, (good[1] - good[0]) * meterWidth, 6);
		fillShape(context, color, x + (clamp(value, 0, 1) * meterWidth) - 1, y - 1, 3, 8);
	};

	// The events. Each one is made with the weather of the day, and has a `step` with the seconds since the last frame, a `draw`, a `press` and a `release` of a control (`left`, `right`, `up`, `down`, or `action`), a `tip` for the part below the screen, and `isWaiting` while it waits for something to happen by itself, like the gun, so it goes on with reduced motion too. When it ends, it calls `finishEvent` with the result and a summary.
	const events = {};

	const degrees = Math.PI / 180;

	// The ski jump of Holmenkollen, K110. The hill is measured in meters: the edge of the table is at 0, and the landing hill falls away below it, steepest at the K-point. A jump flies with a little physics: gravity, lift from the air (more with a head wind, and with a good body position), and drag.
	const jumpHill = (() => {
		const angleAt = x => {
			if (x < 30) {
				return (5 + (x)) * degrees;
			}

			if (x < 100) {
				return 35 * degrees;
			}

			if (x < 150) {
				return 35 * degrees * (1 - ((x - 100) / 50));
			}

			return 0;
		};

		const points = [];
		let y = -3;
		let distance = 0;
		for (let x = 0; x <= 260; x += 0.5) {
			points.push({x, y, distance, angle: angleAt(x)});
			y -= Math.tan(angleAt(x)) * 0.5;
			distance += 0.5 / Math.cos(angleAt(x));
		}

		const at = x => points[clamp(Math.round(x * 2), 0, points.length - 1)];
		return {
			at,
			xAtDistance: distance => points.find(point => point.distance >= distance)?.x ?? 0,
		};
	})();

	// The inrun: 60 meters at 38°, then the table of 7 meters at 11°, which ends at the edge.
	const inrunLength = 60;
	const tableLength = 7;
	const tableStart = {x: -tableLength * Math.cos(11 * degrees), y: tableLength * Math.sin(11 * degrees)};
	const inrunPoint = position => {
		if (position < inrunLength) {
			const back = inrunLength - position;
			return {x: tableStart.x - (back * Math.cos(38 * degrees)), y: tableStart.y + (back * Math.sin(38 * degrees)), angle: 38 * degrees};
		}

		const along = position - inrunLength;
		return {x: tableStart.x + (along * Math.cos(11 * degrees)), y: tableStart.y - (along * Math.sin(11 * degrees)), angle: 11 * degrees};
	};

	const kPoint = 110;

	// Draws the hill of Holmenkollen, with the jumper, from a camera at a point of the hill, in meters. The same drawing shows the replay.
	const drawJumpScene = ({x, y, alpha = 0, phase, crouch = false, telemark = false, fallen = false, wind = 0}) => {
		const scale = 2.2;
		const cameraX = clamp(x + 18, -60, 170);
		const cameraY = y - 8;
		const screenX = worldX => 160 + ((worldX - cameraX) * scale);
		const screenY = worldY => 100 - ((worldY - cameraY) * scale);
		drawSky('#3a6ab8', '#cfe2f6');
		// The Oslofjord and the city far below, with the islands, which move slowly.
		const fjordY = 150 - (cameraY * 0.2);
		fillShape(context, '#5a7aa0', 0, fjordY, width, height);
		drawMountains(cameraX * 0.6, fjordY + 2, '#7a94b4', 18);
		for (let index = 0; index < 12; index++) {
			fillShape(context, '#e8eef6', ((index * 37) - (cameraX * 0.4)) % 340, fjordY + 14 + ((index * 7) % 12), 6, 3);
		}

		// The landing hill and the outrun, with the distance lines.
		context.fillStyle = '#f4f8fc';
		context.beginPath();
		context.moveTo(screenX(-80), height + 10);
		context.lineTo(screenX(-80), screenY(-3));
		for (let worldX = cameraX - 80; worldX <= cameraX + 80; worldX += 2) {
			if (worldX >= 0) {
				context.lineTo(screenX(worldX), screenY(jumpHill.at(worldX).y));
			}
		}

		context.lineTo(width + 10, height + 10);
		context.fill();
		for (let meters = 60; meters <= 140; meters += 10) {
			const lineX = jumpHill.xAtDistance(meters);
			const point = jumpHill.at(lineX);
			const isK = meters === kPoint;
			strokeLine(context, isK ? '#dd2222' : '#9ab0d0', isK ? 2 : 1, [[screenX(lineX) - 4, screenY(point.y) - 1], [screenX(lineX) + 4, screenY(point.y) + 3]]);
			drawText(context, isK ? 'K110' : String(meters), screenX(lineX) + 6, screenY(point.y) + 4, isK ? '#dd2222' : '#6a80a0', {shadow: ''});
		}

		// The crowd at the bottom of the hill, with flags and the smoke of their bonfires.
		const crowdX = jumpHill.xAtDistance(150);
		for (let index = 0; index < 40; index++) {
			const personX = crowdX + (index * 1.4);
			const ground = jumpHill.at(personX).y;
			const color = ['#ba0c2f', '#00205b', '#ffffff', '#ffd21f', '#2a8a3a'][index % 5];
			const bounce = !element.reducedMotion && phase === 'landed' && (index + Math.floor(state.time * 8)) % 3 === 0 ? 1 : 0;
			fillShape(context, color, screenX(personX), screenY(ground) - 6 - bounce, 2, 4);
			fillShape(context, '#f3c9a0', screenX(personX), screenY(ground) - 8 - bounce, 2, 2);
			if (index % 6 === 0) {
				drawFlag(context, 'NOR', screenX(personX) - 1, screenY(ground) - 14 - bounce, 6, 4);
			}
		}

		// The inrun tower and the table.
		const top = inrunPoint(0);
		fillPolygon(context, '#8a96a8', [[screenX(top.x) - 3, screenY(top.y) - 4], [screenX(top.x) + 3, screenY(top.y) - 4], [screenX(0), screenY(-3) + 2], [screenX(-10), screenY(-3) + 40], [screenX(top.x) - 3, screenY(top.y) + 40]]);
		strokeLine(context, '#ffffff', 3, [[screenX(top.x), screenY(top.y)], [screenX(tableStart.x), screenY(tableStart.y)], [screenX(0), screenY(0)]]);
		strokeLine(context, '#5a6a80', 1, [[screenX(top.x), screenY(top.y) + 2], [screenX(tableStart.x), screenY(tableStart.y) + 2], [screenX(0), screenY(0) + 2]]);
		// The edge of the table blinks red while the jumper is on the inrun, so it is easy to see when to jump.
		if (phase === 'inrun' && isBlinkOn(0.15)) {
			fillShape(context, '#ff2222', screenX(0) - 2, screenY(0) - 1, 3, 3);
		}

		// The jumper: crouched on the inrun, in a V in the air, and in a telemark or on the back after landing.
		const jumperX = screenX(x);
		const jumperY = screenY(y);
		context.save();
		context.translate(jumperX, jumperY);
		if (fallen) {
			context.rotate(0.3);
			fillShape(context, '#ba0c2f', -6, -3, 9, 3);
			fillShape(context, '#ffd21f', 3, -3, 3, 3);
			strokeLine(context, '#222222', 1, [[-9, 0], [3, -6]]);
			strokeLine(context, '#222222', 1, [[-4, 1], [8, 3]]);
		} else if (phase === 'flight') {
			// Leaning forward over the skis, which point up in a V. Alpha leans the jumper back (plus) or forward (minus).
			const tilt = (-24 + (alpha * 22)) * degrees;
			context.rotate(tilt);
			strokeLine(context, '#222222', 1, [[-6, 3], [10, 0]]);
			strokeLine(context, '#555555', 1, [[-6, 3], [9, 5]]);
			context.rotate(-0.15);
			fillShape(context, '#ba0c2f', -4, -2, 11, 3);
			fillShape(context, '#00205b', -4, -2, 4, 3);
			fillShape(context, '#f3c9a0', 7, -2, 2, 3);
			fillShape(context, '#ffd21f', 8, -3, 2, 2);
		} else {
			const slope = phase === 'inrun' || phase === 'gate' ? (x < tableStart.x ? 38 : 11) * degrees : jumpHill.at(x).angle;
			context.rotate(phase === 'landed' && x > 160 ? 0 : slope);
			strokeLine(context, '#222222', 1, [[-8, 0], [9, 0]]);
			if (crouch) {
				fillShape(context, '#00205b', -2, -4, 4, 4);
				fillShape(context, '#ba0c2f', -3, -7, 7, 3);
				fillShape(context, '#ffd21f', 3, -9, 3, 3);
			} else {
				fillShape(context, '#00205b', -1 - (telemark ? 2 : 0), -5, 2, 5);
				fillShape(context, '#00205b', 1 + (telemark ? 1 : 0), -5, 2, 5);
				fillShape(context, '#ba0c2f', -2, -11, 5, 6);
				fillShape(context, '#ffd21f', -1, -14, 3, 3);
				if (telemark) {
					strokeLine(context, '#555555', 1, [[-3, -9], [-8, -12]]);
					strokeLine(context, '#555555', 1, [[3, -9], [8, -12]]);
				}
			}
		}

		context.restore();
		// The wind flag at the top: it blows to the left for a head wind.
		drawPanel(4, 4, 74, 20);
		drawText(context, `WIND ${wind >= 0 ? '+' : '-'}${Math.abs(wind).toFixed(1)}`, 8, 7, Math.abs(wind) < 0.3 ? '#ffffff' : (wind > 0 ? '#66ff88' : '#ff7766'));
		const flutter = element.reducedMotion ? 0 : Math.sin(state.time * 12) * 1.5;
		strokeLine(context, '#dddddd', 1, [[60, 22], [60, 8]]);
		const direction = wind >= 0 ? -1 : 1;
		fillPolygon(context, wind > 0 ? '#66ff88' : '#ff7766', [[60, 8], [60 + (direction * Math.min(14, 4 + (Math.abs(wind) * 3.5))), 10 + flutter], [60, 13]]);
		drawSnowfall(state.weather?.snow === 'heavy' ? 1 : (state.weather?.snow === 'light' ? 0.4 : 0), -wind);
	};

	events.skijump = weather => {
		const run = {
			jump: 1,
			phase: 'gate',
			position: 0,
			speed: 0,
			x: inrunPoint(0).x,
			y: inrunPoint(0).y,
			vx: 0,
			vy: 0,
			alpha: 0,
			alphaSum: 0,
			flightTime: 0,
			quality: 0,
			takeoffText: '',
			telemarkHeight: undefined,
			landing: undefined,
			phaseTime: 0,
			gustPhase: Math.random() * 10,
			frames: [],
			jumps: [],
			isWaiting: true,
			tip: 'Press JUMP to start down the inrun.',
		};

		const wind = weather.wind ?? 0;

		const resetJump = () => {
			const start = inrunPoint(0);
			Object.assign(run, {phase: 'gate', position: 0, speed: 0, x: start.x, y: start.y, vx: 0, vy: 0, alpha: 0, alphaSum: 0, flightTime: 0, quality: 0, telemarkHeight: undefined, landing: undefined, phaseTime: 0, frames: [], isWaiting: true, tip: `Jump ${run.jump} of 2. Press JUMP to start down the inrun.`});
			setActionLabel('GO');
		};

		const takeOff = (quality, text) => {
			run.quality = quality;
			run.takeoffText = text;
			run.phase = 'flight';
			run.phaseTime = 0;
			run.isWaiting = false;
			const direction = -11 * degrees;
			run.vx = run.speed * Math.cos(direction);
			run.vy = (run.speed * Math.sin(direction)) + (2.8 * quality);
			run.tip = 'Keep the needle in the green with ▲ and ▼. Press JUMP when the ground is close!';
			setActionLabel('LAND');
			sound.beep(660, 0.08);
		};

		// The marks of the five judges: 20 at most, less for a wobbly flight and a bad landing. The highest and the lowest do not count.
		const judge = deduction => {
			const marks = Array.from({length: 5}, () => clamp(Math.round((20 - deduction + (randomNormal() * 0.4)) * 2) / 2, 0, 20));
			const sorted = [...marks].sort((first, second) => first - second);
			return {marks, style: sorted[1] + sorted[2] + sorted[3], lowest: sorted[0], highest: sorted[4]};
		};

		const land = () => {
			const point = jumpHill.at(run.x);
			const normalX = Math.sin(point.angle);
			const normalY = Math.cos(point.angle);
			const impact = -((run.vx * normalX) + (run.vy * normalY));
			const distance = Math.round(point.distance * 2) / 2;
			let deduction = clamp((run.alphaSum / Math.max(run.flightTime, 0.1)) * 5, 0, 4);
			let landingText;
			let isFallen = false;
			if (Math.abs(run.alpha) >= 1 || impact > 15) {
				isFallen = true;
				deduction += 9;
				landingText = Math.abs(run.alpha) >= 1 ? 'You lost your balance in the air and fell.' : 'You flew so far that you landed in the flat, and fell.';
			} else if (run.telemarkHeight === undefined) {
				deduction += 2.5;
				landingText = 'You landed on two feet, without a telemark.';
			} else if (run.telemarkHeight > 4) {
				deduction += 1.5;
				landingText = 'You set the telemark too early, and landed stiff.';
			} else {
				landingText = 'A beautiful telemark landing!';
			}

			if (!isFallen && (impact > 12.5 || Math.abs(run.alpha) > 0.6)) {
				deduction += 2;
				landingText += ' It was shaky, with a hand close to the snow.';
			}

			const judges = judge(deduction);
			const points = Math.max(0, 60 + ((distance - kPoint) * 1.8)) + judges.style;
			run.landing = {distance, isFallen, landingText, judges, points: Math.round(points * 10) / 10};
			run.phase = 'landed';
			run.phaseTime = 0;
			run.isWaiting = true;
			run.vx = Math.max(run.vx, 18);
			run.vy = 0;
			run.tip = landingText;
			setActionLabel('NEXT');
			run.jumps.push({...run.landing, frames: run.frames});
			if (isFallen) {
				comment('fall', `${distance} meters.`);
				sound.noise(0.6, {volume: 0.12, frequency: 400});
			} else {
				comment(distance >= 125 ? 'great' : (distance >= 105 ? 'good' : 'bad'), `${distance} meters! ${landingText}`);
				if (distance >= 115) {
					sound.crowd();
				}
			}
		};

		run.step = seconds => {
			run.phaseTime += seconds;
			if (run.phase === 'inrun') {
				// Crouched, the jumper is faster, like in a tuck. Upright, the air brakes.
				const isTable = run.position >= inrunLength;
				const push = isTable ? 9.81 * Math.sin(11 * degrees) : 7;
				const drag = state.held.down ? 0.0028 : 0.006;
				run.speed = Math.max(0, run.speed + ((push - (drag * run.speed * run.speed) - (isTable ? 0.6 : 0)) * seconds));
				run.position += run.speed * seconds;
				const point = inrunPoint(Math.min(run.position, inrunLength + tableLength));
				run.x = point.x;
				run.y = point.y;
				if (run.position >= inrunLength + tableLength) {
					// Past the edge without a jump: a little late still helps a little, but it is a weak jump.
					takeOff(0, 'Too late! You rolled off the edge without a jump.');
				}
			} else if (run.phase === 'flight') {
				run.flightTime += seconds;
				// The balance: leaning drifts more the more you already lean, and the gusts of the wind push. The arrows lean forward and back.
				const gust = (0.45 + (Math.abs(wind) * 0.12)) * (Math.sin((run.flightTime * 1.3) + run.gustPhase) + (0.6 * Math.sin((run.flightTime * 3.1) + (run.gustPhase * 2))));
				const control = (state.held.down ? 1.8 : 0) - (state.held.up ? 1.8 : 0);
				run.alpha += ((1.1 * run.alpha) + gust + control) * seconds;
				run.alphaSum += Math.abs(run.alpha) * seconds;
				const form = Math.abs(run.alpha) >= 1 ? 0 : clamp(1 - (1.3 * run.alpha * run.alpha), 0.1, 1);
				const airX = run.vx + wind;
				const speedSquared = (airX * airX) + (run.vy * run.vy);
				const speed = Math.sqrt(speedSquared);
				const lift = 0.0074 * speedSquared * form * (1 + (wind * 0.02));
				const drag = 0.0032 * speedSquared * (1.6 - (0.6 * form));
				run.vx += (-drag * airX / speed) * seconds;
				run.vy += (-9.81 + lift - (drag * run.vy / speed)) * seconds;
				run.x += run.vx * seconds;
				run.y += run.vy * seconds;
				if (run.y <= jumpHill.at(run.x).y) {
					run.y = jumpHill.at(run.x).y;
					land();
				}
			} else if (run.phase === 'landed') {
				// Sliding down the outrun, slowing down.
				run.vx = Math.max(0, run.vx - (12 * seconds));
				run.x += run.vx * seconds;
				run.y = jumpHill.at(run.x).y;
			}

			if (run.phase !== 'gate' && run.frames.length < 1200 && (run.phase !== 'landed' || run.phaseTime < 1)) {
				run.frames.push([Math.round(run.x * 10) / 10, Math.round(run.y * 10) / 10, Math.round(run.alpha * 100) / 100, run.phase === 'inrun' ? (state.held.down ? 1 : 0) : (run.phase === 'flight' ? 2 : (run.landing?.isFallen ? 4 : 3))]);
			}
		};

		run.draw = () => {
			drawJumpScene({x: run.x, y: run.y, alpha: run.alpha, phase: run.phase, crouch: run.phase === 'inrun' && state.held.down, telemark: run.phase === 'landed' && run.telemarkHeight !== undefined && run.telemarkHeight <= 4 && !run.landing?.isFallen, fallen: run.landing?.isFallen, wind});
			drawPanel(222, 4, 94, 20);
			drawText(context, `JUMP ${run.jump}/2`, 226, 7, '#ffffff');
			drawText(context, `${Math.round(run.speed * 3.6)} KM/H`, 312, 7, '#ffee55', {align: 'right'});
			if (run.phase === 'flight') {
				drawText(context, `${Math.max(0, Math.round(jumpHill.at(run.x).distance))} M`, 312, 15, '#ffffff', {align: 'right'});
				drawMeter(110, 186, 100, (run.alpha + 1) / 2, {label: 'BALANCE', good: [0.35, 0.65]});
				const heightAbove = run.y - jumpHill.at(run.x).y;
				if (heightAbove < 4 && run.telemarkHeight === undefined && isBlinkOn(0.12)) {
					drawText(context, 'LAND!', 160, 60, '#ffee55', {scale: 3, align: 'center'});
				}
			}

			if (run.phase === 'gate') {
				drawText(context, `JUMP ${run.jump}`, 160, 44, '#ffffff', {scale: 3, align: 'center'});
				if (isBlinkOn()) {
					drawText(context, 'PRESS GO', 160, 64, '#ffee55', {scale: 2, align: 'center'});
				}
			}

			if (run.phase === 'inrun') {
				drawText(context, state.held.down ? 'TUCK!' : 'HOLD DOWN TO CROUCH', 160, 186, state.held.down ? '#66ff88' : '#ffee55', {align: 'center'});
			}

			if (run.phase === 'landed' && run.landing && run.phaseTime > 0.6) {
				const {distance, judges, points} = run.landing;
				drawPanel(60, 40, 200, 74);
				drawText(context, `${distance.toFixed(1)} M`, 160, 46, '#ffffff', {scale: 3, align: 'center'});
				let lowestShown = false;
				let highestShown = false;
				for (const [index, mark] of judges.marks.entries()) {
					// The highest and the lowest marks are gray, as they do not count.
					let isStruck = false;
					if (!lowestShown && mark === judges.lowest) {
						lowestShown = true;
						isStruck = true;
					} else if (!highestShown && mark === judges.highest) {
						highestShown = true;
						isStruck = true;
					}

					drawText(context, mark.toFixed(1), 82 + (index * 40), 70, isStruck ? '#7a8aa0' : '#ffee55', {align: 'center'});
				}

				drawText(context, `STYLE ${judges.style.toFixed(1)}`, 160, 82, '#ffffff', {align: 'center'});
				drawText(context, `${points.toFixed(1)} POINTS`, 160, 94, '#66ff88', {scale: 2, align: 'center'});
				if (isBlinkOn()) {
					drawText(context, run.jump === 1 ? 'PRESS NEXT FOR JUMP 2' : 'PRESS NEXT', 160, 106, '#ffffff', {align: 'center'});
				}
			}
		};

		run.press = control => {
			if (control !== 'action') {
				return;
			}

			if (run.phase === 'gate') {
				run.phase = 'inrun';
				run.phaseTime = 0;
				run.isWaiting = false;
				run.tip = 'Hold ▼ to crouch, and press JUMP at the red light at the edge!';
				setActionLabel('JUMP');
				comment('start');
			} else if (run.phase === 'inrun') {
				const toEdge = inrunLength + tableLength - run.position;
				if (toEdge > tableLength) {
					takeOff(0.25, 'Far too early! You jumped before the table.');
				} else {
					takeOff(toEdge <= 2.5 ? 1 : clamp(1 - ((toEdge - 2.5) / 4.5 * 0.55), 0.45, 1), toEdge <= 2.5 ? 'A perfect takeoff!' : 'A little early.');
				}
			} else if (run.phase === 'flight') {
				if (run.phaseTime < 0.18 && run.quality === 0) {
					// A press just after rolling off the edge is a late jump, which still helps a little.
					run.quality = 0.55;
					run.vy += 2.8 * 0.55;
					run.takeoffText = 'A little late.';
					return;
				}

				run.telemarkHeight ??= run.y - jumpHill.at(run.x).y;
			} else if (run.phase === 'landed' && run.phaseTime > 0.6) {
				if (run.jump === 1) {
					run.jump = 2;
					resetJump();
					return;
				}

				const total = Math.round((run.jumps[0].points + run.jumps[1].points) * 10) / 10;
				const best = run.jumps.toSorted((first, second) => second.points - first.points)[0];
				const stored = element.stored('replay');
				if (!stored || !(stored.points >= best.points)) {
					element.store('replay', {points: best.points, distance: best.distance, wind, frames: best.frames});
				}

				finishEvent(total, `Jump 1: ${run.jumps[0].distance.toFixed(1)} m (${run.jumps[0].points.toFixed(1)} points). Jump 2: ${run.jumps[1].distance.toFixed(1)} m (${run.jumps[1].points.toFixed(1)} points).`, run.jumps.some(jump => jump.isFallen));
			}
		};

		resetJump();
		return run;
	};

	// Counts the presses of the last second, for the events where the visitor mashes the buttons, like the run of Track & Field.
	const makeMashCounter = () => {
		const presses = [];
		return {
			add(time) {
				presses.push(time);
			},
			rate(time) {
				while (presses.length > 0 && presses[0] < time - 1) {
					presses.shift();
				}

				return presses.length;
			},
		};
	};

	// A skier from the side, with skis and poles that swing with the stride, with the feet at the point.
	const drawSkier = (left, bottom, code, stride, {lean = 0, size = 1} = {}) => {
		const {suit, trim} = countries[code] ?? countries.NOR;
		const swing = Math.round(Math.sin(stride) * 3);
		const x = 0;
		const y = 0;
		context.save();
		context.translate(left, bottom);
		context.scale(size, size);
		strokeLine(context, '#333333', 1, [[x - 9 + swing, y], [x + 7 + swing, y]]);
		strokeLine(context, '#333333', 1, [[x - 7 - swing, y + 1], [x + 9 - swing, y + 1]]);
		fillShape(context, trim, x - 1 + swing, y - 6, 2, 6);
		fillShape(context, trim, x + 1 - swing, y - 6, 2, 6);
		fillShape(context, suit, x - 2 + lean, y - 13, 5, 7);
		fillShape(context, '#f3c9a0', x - 1 + lean, y - 17, 3, 4);
		fillShape(context, trim, x - 2 + lean, y - 18, 5, 2);
		strokeLine(context, '#777777', 1, [[x + 2 + lean, y - 11], [x + 6 - swing, y]]);
		strokeLine(context, '#777777', 1, [[x - 1 + lean, y - 11], [x - 5 + swing, y]]);
		context.restore();
	};

	// Biathlon: ski to the range by mashing ◀ and ▶, shoot five targets with a sight that shakes with the heart rate and a wind that moves the bullets, ski a penalty loop for each miss, and ski to the finish.
	events.biathlon = weather => {
		const legLength = 170;
		const loopLength = 35;
		const wind = weather.wind ?? 0;
		const snowFactor = weather.snow === 'heavy' ? 0.9 : (weather.snow === 'light' ? 0.96 : 1);
		const targetXs = [104, 132, 160, 188, 216];
		const targetY = 96;
		const mash = makeMashCounter();
		const run = {
			phase: 'start',
			distance: 0,
			speed: 0,
			heartRate: 72,
			time: 0,
			stride: 0,
			lastSide: undefined,
			hits: [false, false, false, false, false],
			shots: 0,
			aimX: 104 + randomBetween(-18, 18),
			aimY: targetY + randomBetween(-14, 14),
			recoil: 0,
			penalty: 0,
			flash: undefined,
			isWaiting: true,
			tip: 'Press ◀ and ▶ one after the other to ski!',
		};

		const ski = side => {
			if (side === run.lastSide) {
				return;
			}

			run.lastSide = side;
			mash.add(run.time);
			// Very tired skiers get less out of each push.
			const push = run.heartRate >= 190 ? 0.25 : 0.5;
			run.speed = Math.min(11 * snowFactor, run.speed + push);
			run.stride += Math.PI / 2;
		};

		const shoot = () => {
			if (run.shots >= 5) {
				return;
			}

			run.shots++;
			const {x, y} = sightPosition();
			const impactX = x + (wind * 2.4);
			const impactY = y;
			const target = targetXs.findIndex((targetX, index) => !run.hits[index] && Math.hypot(impactX - targetX, impactY - targetY) <= 5);
			if (target === -1) {
				run.flash = {text: 'MISS', color: '#ff5544', until: run.time + 0.6, x: impactX, y: impactY};
				sound.beep(140, 0.15, {type: 'sawtooth'});
			} else {
				run.hits[target] = true;
				run.flash = {text: 'HIT', color: '#66ff88', until: run.time + 0.6, x: impactX, y: impactY};
				sound.beep(880, 0.06);
			}

			sound.noise(0.08, {volume: 0.12, frequency: 2000, rise: 0.001});
			run.recoil = 1;
			if (run.shots === 5) {
				const misses = run.hits.filter(hit => !hit).length;
				run.penalty = misses * loopLength;
				run.phase = misses > 0 ? 'penalty' : 'leg2';
				run.isWaiting = false;
				run.speed = 2;
				run.tip = misses > 0 ? `${misses} ${misses === 1 ? 'miss' : 'misses'}: ski the penalty loop with ◀ ▶ ◀ ▶!` : 'Clean shooting! Ski to the finish with ◀ ▶ ◀ ▶!';
				setActionLabel('GO');
				if (misses === 0) {
					comment('great', 'Five of five!');
				} else {
					comment(misses >= 3 ? 'bad' : 'good', `${5 - misses} of 5. ${misses} penalty ${misses === 1 ? 'loop' : 'loops'}.`);
				}
			}
		};

		// The sight shakes in a figure of eight, more with a higher heart rate, and kicks up after each shot.
		const sightPosition = () => {
			const amount = 1 + ((run.heartRate - 70) / 130 * 13);
			return {
				x: run.aimX + (Math.sin(run.time * 1.9) * amount) + (Math.sin(run.time * 4.3) * amount * 0.25),
				y: run.aimY + (Math.sin(run.time * 3.1) * amount * 0.7) - (run.recoil * 10),
			};
		};

		run.step = seconds => {
			if (run.phase === 'start') {
				return;
			}

			run.time += seconds;
			const rate = mash.rate(run.time);
			if (run.phase === 'range') {
				// At the range, the heart calms down, and the arrows move the sight.
				run.heartRate = Math.max(70, run.heartRate - (14 * seconds));
				run.recoil = Math.max(0, run.recoil - (seconds * 4));
				const move = 40 * seconds;
				run.aimX = clamp(run.aimX + ((state.held.right ? move : 0) - (state.held.left ? move : 0)), 80, 240);
				run.aimY = clamp(run.aimY + ((state.held.down ? move : 0) - (state.held.up ? move : 0)), 60, 132);
				return;
			}

			// Skiing: the heart beats faster the faster the visitor mashes, and slows down when the visitor eases off.
			const targetRate = clamp(72 + (rate * 17), 72, 200);
			run.heartRate += clamp(targetRate - run.heartRate, -12 * seconds, 18 * seconds);
			run.speed = Math.max(0, run.speed - ((0.5 + (0.25 * run.speed)) * seconds));
			const step = run.speed * seconds;
			if (run.phase === 'leg1') {
				run.distance += step;
				if (run.distance >= legLength) {
					run.distance = legLength;
					run.phase = 'range';
					run.speed = 0;

					run.tip = 'At the range! Move the sight with the arrow keys, and press FIRE. The calmer your heart, the steadier the sight.';
					setActionLabel('FIRE');
					say(`🎙️ «Inn på standplass!» Into the range, with a heart rate of ${Math.round(run.heartRate)}.`);
				}
			} else if (run.phase === 'penalty') {
				run.penalty -= step;
				if (run.penalty <= 0) {
					run.phase = 'leg2';
					run.tip = 'Out of the penalty loop! Ski to the finish with ◀ ▶ ◀ ▶!';
				}
			} else if (run.phase === 'leg2') {
				run.distance += step;
				if (run.distance >= legLength * 2) {
					run.phase = 'done';
					const misses = run.hits.filter(hit => !hit).length;
					const time = Math.round(run.time * 100) / 100;
					finishEvent(time, `${5 - misses} of 5 targets hit, ${misses} penalty ${misses === 1 ? 'loop' : 'loops'}. Time: ${formatSeconds(time)} seconds.`);
				}
			}
		};

		const drawCourse = () => {
			const camera = run.distance * 8;
			drawSky('#5a8ad8', '#e0ecf8');
			drawMountains(camera * 0.15, 120, '#c8d4e8', 45);
			// Forest far away, then the trees by the track.
			for (let index = 0; index < 30; index++) {
				const x = (((index * 23) - (camera * 0.4)) % 340 + 340) % 340 - 10;
				fillPolygon(context, '#4a6a5a', [[x, 112], [x + 6, 130], [x - 6, 130]]);
			}

			fillShape(context, '#f4f8fc', 0, 130, width, 70);
			strokeLine(context, '#b8c8dc', 1, [[0, 160], [width, 160]]);
			strokeLine(context, '#b8c8dc', 1, [[0, 164], [width, 164]]);
			for (let index = 0; index < 12; index++) {
				const x = (((index * 61) - camera) % 360 + 360) % 360 - 20;
				fillPolygon(context, '#2d5a3a', [[x, 120], [x + 9, 150], [x - 9, 150]]);
				fillShape(context, '#5a3a20', x - 1, 150, 2, 4);
			}

			// Signs that count down to the range and the finish.
			const goal = run.phase === 'leg1' ? legLength : legLength * 2;
			const left = Math.max(0, goal - run.distance);
			// Fans along the track with flags and cowbells.
			for (let index = 0; index < 6; index++) {
				const x = (((index * 97) - (camera * 1.2)) % 600 + 600) % 600 - 20;
				drawAthlete(context, ['NOR', 'SWE', 'GER', 'FIN', 'NOR', 'USA'][index], x, 150);
				drawFlag(context, ['NOR', 'SWE', 'GER', 'FIN', 'NOR', 'USA'][index], x + 4, 126, 12, 8);
				strokeLine(context, '#888888', 1, [[x + 3.5, 126], [x + 3.5, 140]]);
			}

			drawSkier(140, 163, state.athlete.country, run.stride, {lean: run.speed > 6 ? 1 : 0, size: 2});
			drawPanel(4, 4, 150, 28);
			drawText(context, run.phase === 'penalty' ? `PENALTY LOOP ${Math.ceil(run.penalty)} M` : `${run.phase === 'leg1' ? 'RANGE' : 'FINISH'} IN ${Math.ceil(left)} M`, 8, 7, '#ffffff');
			drawText(context, `TIME ${formatSeconds(run.time)}`, 8, 15, '#ffee55');
			drawText(context, `SPEED ${Math.round(run.speed * 3.6)} KM/H`, 8, 23, '#ffffff');
		};

		const drawHeart = () => {
			drawPanel(232, 4, 84, 20);
			const beat = !element.reducedMotion && Math.sin(run.time * run.heartRate / 60 * Math.PI * 2) > 0.6;
			const color = run.heartRate >= 175 ? '#ff4444' : (run.heartRate >= 140 ? '#ffaa44' : '#66ff88');
			drawText(context, '♥', 238, 10, color, {scale: beat ? 2 : 1});
			drawText(context, `${Math.round(run.heartRate)} BPM`, 312, 10, color, {align: 'right'});
		};

		const drawRange = () => {
			drawSky('#5a8ad8', '#e0ecf8');
			drawMountains(40, 70, '#c8d4e8', 30);
			fillShape(context, '#f4f8fc', 0, 70, width, 130);
			// The targets on their white plate, black until they are hit.
			fillShape(context, '#ffffff', 86, 82, 148, 28);
			fillShape(context, '#c8d0dc', 86, 108, 148, 2);
			for (const [index, x] of targetXs.entries()) {
				fillEllipse(context, run.hits[index] ? '#ffffff' : '#111111', x, targetY, 5, 5);
				context.strokeStyle = '#333333';
				context.lineWidth = 1;
				context.beginPath();
				context.arc(x, targetY, 5.5, 0, Math.PI * 2);
				context.stroke();
			}

			// The wind flag by the range.
			const flutter = element.reducedMotion ? 0 : Math.sin(run.time * 10) * 1.5;
			strokeLine(context, '#555555', 1, [[60, 120], [60, 70]]);
			const direction = Math.sign(wind) || 1;
			fillPolygon(context, '#ff6633', [[60, 70], [60 + (direction * (4 + (Math.abs(wind) * 4))), 73 + flutter], [60, 77]]);
			drawText(context, `WIND ${Math.abs(wind).toFixed(1)} M/S ${Math.abs(wind) < 0.3 ? '' : (wind > 0 ? '>' : '<')}`, 36, 124, '#334455', {shadow: ''});
			// The shots left.
			drawPanel(4, 176, 100, 20);
			drawText(context, 'SHOTS', 8, 183, '#ffffff');
			for (let index = 0; index < 5; index++) {
				fillShape(context, index < run.shots ? '#555555' : '#ffd21f', 36 + (index * 10), 181, 6, 9);
			}

			// The sight.
			const {x, y} = sightPosition();
			context.strokeStyle = '#000000';
			context.lineWidth = 1;
			context.beginPath();
			context.arc(x, y, 14, 0, Math.PI * 2);
			context.stroke();
			strokeLine(context, '#000000', 1, [[x - 18, y], [x - 4, y]]);
			strokeLine(context, '#000000', 1, [[x + 4, y], [x + 18, y]]);
			strokeLine(context, '#000000', 1, [[x, y - 18], [x, y - 4]]);
			strokeLine(context, '#000000', 1, [[x, y + 4], [x, y + 18]]);
			fillShape(context, '#ff0000', x, y, 1, 1);
			if (run.flash && run.time < run.flash.until) {
				fillShape(context, run.flash.color, run.flash.x - 1, run.flash.y - 1, 3, 3);
				drawText(context, run.flash.text, 160, 140, run.flash.color, {scale: 2, align: 'center'});
			}

			drawText(context, `TIME ${formatSeconds(run.time)}`, 312, 186, '#334455', {align: 'right', shadow: ''});
		};

		run.draw = () => {
			if (run.phase === 'range') {
				drawRange();
			} else {
				drawCourse();
				drawSnowfall(weather.snow === 'heavy' ? 1 : (weather.snow === 'light' ? 0.4 : 0), wind * -0.5);
			}

			drawHeart();
			if (run.phase === 'start') {
				drawText(context, 'BIATHLON', 160, 50, '#ffffff', {scale: 3, align: 'center'});
				if (isBlinkOn()) {
					drawText(context, 'PRESS < AND > TO SKI', 160, 74, '#ffee55', {scale: 2, align: 'center'});
				}
			}
		};

		run.press = control => {
			if (run.phase === 'start' && (control === 'left' || control === 'right')) {
				run.phase = 'leg1';
				run.isWaiting = false;
				comment('start');
			}

			if ((run.phase === 'leg1' || run.phase === 'leg2' || run.phase === 'penalty') && (control === 'left' || control === 'right')) {
				ski(control);
			} else if (run.phase === 'range' && control === 'action') {
				shoot();
			}
		};

		setActionLabel('FIRE');
		return run;
	};

	// The pace of the record of the 500 meters, as the ghost of the first race: fast out of the start, then steady.
	const recordGhost = () => {
		const positions = [];
		for (let time = 0; time <= 40; time += 0.1) {
			positions.push(Math.round(14.05 * (time - (2.3 * (1 - Math.exp(-time / 2.3)))) * 10) / 10);
		}

		return positions;
	};

	// Speed skating, 500 meters, against the ghost of the best race. The gun fires after a wait, and a press before it is a false start. Then each stroke is a press of ◀ or ▶ when the marker of the stride meter swings to that end, and the meter swings faster as the skater goes faster. The ends are smaller in the curves.
	events.skating = weather => {
		const iceFactor = weather.ice === 'keen' ? 0.95 : (weather.ice === 'heavy' ? 1.05 : 1);
		const storedGhost = element.stored('ghost');
		const isOwnGhost = Array.isArray(storedGhost?.positions) && storedGhost.positions.length > 10 && storedGhost.positions.every(Number.isFinite);
		const ghost = isOwnGhost ? storedGhost.positions : recordGhost();
		const run = {
			phase: 'ready',
			phaseTime: 0,
			gunAt: randomBetween(1.6, 3),
			falseStarts: 0,
			time: 0,
			distance: 0,
			speed: 0,
			swing: 0,
			strokedSide: undefined,
			strokes: 0,
			misses: 0,
			reaction: undefined,
			positions: [],
			sampleTime: 0,
			message: undefined,
			isWaiting: true,
			tip: 'Wait for the gun, and press GO when it fires!',
		};

		const isCurve = () => (run.distance >= 100 && run.distance < 200) || (run.distance >= 300 && run.distance < 400);
		const zone = () => (isCurve() ? 0.8 : 0.6);
		const marker = () => Math.sin(run.swing);
		const ghostAt = time => {
			const index = time * 10;
			const before = ghost[Math.floor(index)] ?? ghost.at(-1) + ((index - ghost.length + 1) * 14 / 10);
			const after = ghost[Math.ceil(index)] ?? before;
			return Math.min(500, before + ((after - before) * (index - Math.floor(index))));
		};

		const ghostTime = () => {
			const index = ghost.findIndex(position => position >= 500);
			return index === -1 ? undefined : index / 10;
		};

		const show = (text, color) => {
			run.message = {text, color, until: run.time + 0.5};
		};

		const stroke = side => {
			const value = marker();
			const isInZone = side === 'left' ? value <= -zone() : value >= zone();
			// One stroke for each swing, with the foot of its side.
			if (!isInZone || run.strokedSide === side) {
				run.misses++;
				run.speed *= 0.97;
				show('WOBBLE!', '#ff7766');
				return;
			}

			run.strokedSide = side;
			run.strokes++;
			const quality = clamp((Math.abs(value) - zone()) / (1 - zone()), 0, 1);
			run.speed += (16.5 - run.speed) * (0.09 + (0.08 * quality));
			show(quality > 0.6 ? 'PERFECT' : 'GOOD', quality > 0.6 ? '#66ff88' : '#ffee55');
			sound.beep(side === 'left' ? 330 : 392, 0.04, {type: 'triangle'});
		};

		run.step = seconds => {
			run.phaseTime += seconds;
			if (run.phase === 'ready') {
				if (run.phaseTime >= run.gunAt) {
					run.phase = 'race';
					run.phaseTime = 0;
					run.isWaiting = false;
					run.tip = 'Skate! ◀ at the left end of the stride meter, ▶ at the right end.';
					sound.gun();
					setActionLabel('GO');
				}

				return;
			}

			if (run.phase !== 'race') {
				return;
			}

			run.time += seconds;
			// The ghost is sampled from the gun, like the clock, also while the skater still waits to react.
			run.sampleTime += seconds;
			while (run.sampleTime >= 0.1) {
				run.sampleTime -= 0.1;
				run.positions.push(Math.round(Math.min(run.distance, 500) * 10) / 10);
			}

			// The skater who has not reacted to the gun yet stands still.
			if (run.reaction === undefined) {
				if (run.time > 1.5) {
					run.reaction = 1.5;
					run.speed = 2;
				}

				return;
			}

			const previousMarker = marker();
			run.swing += Math.PI * 2 * (0.75 + (run.speed * 0.05)) * seconds;
			// A new swing to a side can have a new stroke.
			if (Math.sign(marker()) !== Math.sign(previousMarker)) {
				run.strokedSide = undefined;
			}

			run.speed = Math.max(0, run.speed - (0.0058 * iceFactor * run.speed * run.speed * seconds) - (0.15 * seconds));
			run.distance += run.speed * seconds;
			if (run.distance >= 500) {
				run.phase = 'done';
				const time = Math.round(run.time * 100) / 100;
				const recordTime = ghostTime();
				if (!isOwnGhost || recordTime === undefined || time < recordTime) {
					run.positions.push(500);
					element.store('ghost', {positions: run.positions});
				}

				const ghostText = recordTime === undefined ? '' : (time < recordTime ? ` You beat the ghost by ${(recordTime - time).toFixed(2)} seconds!` : ` The ghost was ${(time - recordTime).toFixed(2)} seconds faster.`);
				finishEvent(time, `Reaction at the start: ${run.reaction.toFixed(3)} seconds. ${run.strokes} strokes, ${run.misses} ${run.misses === 1 ? 'wobble' : 'wobbles'}.${ghostText}`);
			}
		};

		// Vikingskipet, the hall of Hamar, shaped like a Viking ship upside down, with the skaters from the side.
		const drawHall = () => {
			const camera = run.distance * 10;
			drawSky('#2a2018', '#5a4a3a', 60);
			// The wooden beams of the roof, like the ribs of a ship.
			for (let index = 0; index < 14; index++) {
				const x = (((index * 30) - (camera * 0.3)) % 420 + 420) % 420 - 50;
				strokeLine(context, '#8a6a4a', 3, [[x, 0], [x + 40, 60]]);
			}

			// The crowd, which goes by as the skater goes.
			drawCrowd(0, 60, width, 50, {offset: camera * 0.6});

			// The ice, with the lanes and the distance boards.
			fillShape(context, '#dceaf6', 0, 110, width, 90);
			strokeLine(context, '#ff4444', 1, [[0, 140], [width, 140]]);
			strokeLine(context, '#4466ff', 1, [[0, 170], [width, 170]]);
			for (let meter = Math.floor((run.distance - 20) / 50) * 50; meter < run.distance + 20; meter += 50) {
				const x = 120 + ((meter - run.distance) * 10);
				if (meter > 0 && meter <= 500) {
					fillShape(context, '#ffffff', x - 12, 112, 24, 10);
					drawText(context, String(meter), x, 115, meter === 500 ? '#dd2222' : '#2a3a5a', {align: 'center', shadow: ''});
				}

				if (meter === 500) {
					fillShape(context, '#dd2222', x, 122, 2, 78);
				}
			}

			// The ghost in the outer lane, see-through, and the skater in the inner lane.
			const ghostDistance = ghostAt(run.time);
			const ghostX = 120 + ((ghostDistance - run.distance) * 10);
			context.globalAlpha = 0.45;
			drawSkater(ghostX, 160, run.time * 9, '#aabbff');
			context.globalAlpha = 1;
			drawSkater(120, 190, run.swing, countries[state.athlete.country].suit);
		};

		// A skater from the side, bigger than the pixels of the rest, leaning forward, with the legs that push to the sides.
		const drawSkater = (left, bottom, swing, color) => {
			const push = Math.round(Math.sin(swing) * 5);
			const x = 0;
			const y = 0;
			context.save();
			context.translate(left, bottom);
			context.scale(1.6, 1.6);
			strokeLine(context, '#333333', 2, [[x - 4 + push, y - 1], [x + 4 + push, y - 1]]);
			strokeLine(context, color, 2, [[x, y - 12], [x + push, y - 2]]);
			strokeLine(context, color, 2, [[x, y - 12], [x - push, y - 3]]);
			fillPolygon(context, color, [[x - 6, y - 13], [x + 6, y - 18], [x + 7, y - 14], [x - 5, y - 10]]);
			fillEllipse(context, '#f3c9a0', x + 9, y - 17, 2.5, 2.5);
			fillShape(context, color, x + 7, y - 21, 4, 2);
			context.restore();
		};

		// The oval of the rink, seen from above, with dots for the skater and the ghost.
		const drawOval = () => {
			drawPanel(232, 4, 84, 44);
			context.strokeStyle = '#ffffff';
			context.lineWidth = 1;
			context.beginPath();
			context.roundRect(242, 14, 64, 26, 13);
			context.stroke();
			const point = distance => {
				// 500 meters are one and a quarter laps of 400 meters, from the start on the back straight.
				const lap = ((distance + 100) % 400) / 400;
				const perimeter = [[255, 14], [293, 14], [306, 27], [293, 40], [255, 40], [242, 27]];
				const segment = lap * perimeter.length;
				const [x1, y1] = perimeter[Math.floor(segment) % perimeter.length];
				const [x2, y2] = perimeter[(Math.floor(segment) + 1) % perimeter.length];
				const fraction = segment - Math.floor(segment);
				return [x1 + ((x2 - x1) * fraction), y1 + ((y2 - y1) * fraction)];
			};

			const [ghostX, ghostY] = point(ghostAt(run.time));
			fillShape(context, '#aabbff', ghostX - 1, ghostY - 1, 3, 3);
			const [x, y] = point(run.distance);
			fillShape(context, '#ff4444', x - 1, y - 1, 3, 3);
		};

		run.draw = () => {
			drawHall();
			drawOval();
			drawPanel(4, 4, 130, 28);
			drawText(context, `${Math.min(500, Math.floor(run.distance))} M  ${formatSeconds(run.time)}`, 8, 7, '#ffffff');
			drawText(context, `${(run.speed * 3.6).toFixed(1)} KM/H`, 8, 15, '#ffee55');
			const difference = run.time > 0 ? (run.distance - ghostAt(run.time)) / Math.max(run.speed, 8) : 0;
			drawText(context, `GHOST ${difference >= 0 ? '-' : '+'}${Math.abs(difference).toFixed(2)} S`, 8, 23, difference >= 0 ? '#66ff88' : '#ff7766');
			if (run.phase === 'ready') {
				const word = run.phaseTime < 0.8 ? 'GÅ PÅ PLASS' : 'KLAR...';
				drawText(context, word, 160, 50, '#ffffff', {scale: 3, align: 'center'});
				drawText(context, run.falseStarts > 0 ? 'ONE FALSE START!' : 'PRESS GO AT THE GUN', 160, 74, run.falseStarts > 0 ? '#ff7766' : '#ffee55', {align: 'center'});
			} else if (run.phase === 'race') {
				if (run.reaction === undefined) {
					drawText(context, 'GO GO GO!', 160, 50, '#ffee55', {scale: 3, align: 'center'});
				}

				drawMeter(90, 92, 140, (marker() + 1) / 2, {label: isCurve() ? 'STRIDE - CURVE!' : 'STRIDE', good: [0, (1 - zone()) / 2]});
				// The right end is good too.
				fillShape(context, '#22aa44', 90 + (140 * (1 + zone()) / 2), 92, 140 * (1 - zone()) / 2, 6);
				fillShape(context, '#ffee55', 90 + (((marker() + 1) / 2) * 140) - 1, 91, 3, 8);
				drawText(context, '<', 82, 92, '#ffffff');
				drawText(context, '>', 234, 92, '#ffffff');
				if (run.message && run.time < run.message.until) {
					drawText(context, run.message.text, 160, 60, run.message.color, {scale: 2, align: 'center'});
				}
			}
		};

		run.press = control => {
			if (run.phase === 'ready') {
				if (control === 'action' || control === 'left' || control === 'right') {
					run.falseStarts++;
					sound.gun();
					if (run.falseStarts >= 2) {
						run.phase = 'done';
						say('🎙️ «Tjuvstart igjen! Diskvalifisert!» A false start again! Disqualified!');
						finishEvent(undefined, 'Disqualified after two false starts.');
						return;
					}

					run.phaseTime = 0;
					run.gunAt = randomBetween(1.6, 3);
					say('🎙️ «Tjuvstart!» A false start! One more, and you are out. Wait for the gun.');
				}

				return;
			}

			if (run.phase !== 'race') {
				return;
			}

			if (run.reaction === undefined) {
				if (control === 'action') {
					run.reaction = run.time;
					run.speed = clamp(4.5 - (run.reaction * 4), 1.5, 4);
					comment(run.reaction < 0.2 ? 'great' : 'start', `Reaction: ${run.reaction.toFixed(3)} seconds.`);
				}

				return;
			}

			if (control === 'left' || control === 'right') {
				stroke(control);
			}
		};

		setActionLabel('GO');
		return run;
	};

	// Slalom, seen from above: the skier goes down the screen, and the arrows turn the skis. The course is in the pixels of the screen, and the camera follows the skier down.
	events.slalom = weather => {
		const gateCount = 20;
		const gates = Array.from({length: gateCount}, (_, index) => ({
			y: 150 + (index * 82),
			x: 160 + ((index % 2 === 0 ? -1 : 1) * randomBetween(24, 50)),
			isRed: index % 2 === 0,
			result: undefined,
			wobble: 0,
		}));
		const finishY = gates.at(-1).y + 110;
		const snowFactor = weather.snow === 'heavy' ? 0.9 : (weather.snow === 'light' ? 0.96 : 1);
		const run = {
			phase: 'start',
			x: 160,
			y: 40,
			heading: 0,
			speed: 0,
			time: 0,
			penalty: 0,
			missed: 0,
			gates,
			trail: [],
			message: undefined,
			isWaiting: true,
			tip: 'Press GO to push out of the start gate!',
		};

		const show = (text, color) => {
			run.message = {text, color, until: run.time + 0.8};
		};

		run.step = seconds => {
			if (run.phase !== 'race') {
				return;
			}

			run.time += seconds;
			const isTuck = state.held.down;
			const turn = (state.held.right ? 1 : 0) - (state.held.left ? 1 : 0);
			// A turn is slower in a tuck, and each turn scrubs a little speed.
			run.heading = clamp(run.heading + (turn * (isTuck ? 1.5 : 2.6) * seconds), -1.35, 1.35);
			const gravity = 150 * Math.cos(run.heading) * snowFactor;
			const drag = (isTuck ? 0.6 : 0.85) + (turn === 0 ? 0 : 0.3) + (state.held.up ? 2.5 : 0) + (Math.abs(run.heading) * 0.4);
			run.speed = clamp(run.speed + ((gravity - (drag * run.speed)) * seconds), 0, 170);
			const previousY = run.y;
			run.x += Math.sin(run.heading) * run.speed * seconds;
			run.y += Math.cos(run.heading) * run.speed * seconds;
			// The fences at the sides slow the skier down.
			if (run.x < 10 || run.x > 310) {
				run.x = clamp(run.x, 10, 310);
				run.speed *= 0.9;
				run.heading *= 0.5;
			}

			if (run.trail.length === 0 || Math.hypot(run.x - run.trail.at(-1)[0], run.y - run.trail.at(-1)[1]) > 3) {
				run.trail.push([run.x, run.y]);
				if (run.trail.length > 120) {
					run.trail.shift();
				}
			}

			for (const gate of gates) {
				gate.wobble = Math.max(0, gate.wobble - seconds);
				if (gate.result === undefined && previousY < gate.y && run.y >= gate.y) {
					const distance = Math.abs(run.x - gate.x);
					if (distance > 14 + 4) {
						gate.result = 'missed';
						run.missed++;
						run.penalty += 5;
						show('MISSED GATE! +5 S', '#ff5544');
						sound.beep(150, 0.2, {type: 'sawtooth'});
					} else if (distance > 11) {
						// Through the gate, but over a pole, which bends and slows the skier down, like the modern poles that fold.
						gate.result = 'pole';
						gate.wobble = 0.5;
						run.speed *= 0.82;
						show('POLE!', '#ffee55');
						sound.beep(400, 0.05);
					} else {
						gate.result = 'clean';
						sound.beep(700, 0.03, {type: 'triangle'});
					}
				}
			}

			if (run.y >= finishY) {
				run.phase = 'done';
				const time = Math.round((run.time + run.penalty) * 100) / 100;
				finishEvent(time, `${gateCount - run.missed} of ${gateCount} gates${run.missed > 0 ? `, ${run.missed} missed (+${run.penalty} seconds)` : ', none missed'}. Time: ${formatSeconds(time)} seconds.`);
			}
		};

		run.draw = () => {
			const cameraY = run.y - 60;
			const screenY = y => y - cameraY;
			fillShape(context, '#f4f8fc', 0, 0, width, height);
			// Bumps in the snow, and the blue lines of the course.
			for (let index = 0; index < 40; index++) {
				const y = (((index * 37) - cameraY) % 420 + 420) % 420 - 10;
				fillShape(context, '#e2eaf4', (index * 53) % 300, y, 14, 3);
			}

			for (const side of [6, 314]) {
				for (let y = -(cameraY % 12); y < height; y += 12) {
					fillShape(context, '#3a6ad8', side - 1, y, 2, 6);
				}
			}

			// The trees outside the fences.
			for (let index = 0; index < 16; index++) {
				const y = (((index * 61) - cameraY) % 520 + 520) % 520 - 20;
				const x = index % 2 === 0 ? -2 : 312;
				fillPolygon(context, '#2d5a3a', [[x + 5, y], [x + 12, y + 18], [x - 2, y + 18]]);
			}

			// The tracks of the skis.
			context.strokeStyle = '#c8d4e4';
			context.lineWidth = 1;
			context.beginPath();
			for (const [x, y] of run.trail) {
				context.lineTo(x, screenY(y));
			}

			context.stroke();
			for (const gate of gates) {
				const y = screenY(gate.y);
				if (y < -20 || y > height + 20) {
					continue;
				}

				const color = gate.isRed ? '#dd2222' : '#2244dd';
				const bend = gate.wobble > 0 && !element.reducedMotion ? Math.sin(gate.wobble * 30) * 3 : 0;
				for (const poleX of [gate.x - 14, gate.x + 14]) {
					strokeLine(context, color, 2, [[poleX, y + 2], [poleX + bend, y - 12]]);
					fillShape(context, color, poleX + (poleX < gate.x ? -7 : 1) + bend, y - 12, 6, 5);
				}

				if (gate.result === 'missed') {
					drawText(context, 'X', gate.x, y - 4, '#ff3333', {scale: 2, align: 'center'});
				}
			}

			const finish = screenY(finishY);
			if (finish < height + 10) {
				fillShape(context, '#dd2222', 0, finish, width, 3);
				drawText(context, 'FINISH', 160, finish + 6, '#dd2222', {scale: 2, align: 'center', shadow: ''});
			}

			// The skier from above: skis in the direction of the heading, and a body in the colors of the country.
			const {suit, trim} = countries[state.athlete.country];
			context.save();
			context.translate(run.x, screenY(run.y));
			context.rotate(-run.heading);
			strokeLine(context, '#222222', 1, [[-3, -7], [-3, 7]]);
			strokeLine(context, '#222222', 1, [[3, -7], [3, 7]]);
			fillShape(context, suit, -3, -3, 6, 5);
			fillEllipse(context, trim, 0, 2, 2.5, 2.5);
			context.restore();
			// The fog hides the course further down.
			if (weather.fog > 0) {
				const fog = context.createLinearGradient(0, 70, 0, 70 + ((1 - weather.fog) * 220));
				fog.addColorStop(0, 'rgba(225, 230, 238, 0)');
				fog.addColorStop(1, 'rgba(225, 230, 238, 1)');
				context.fillStyle = fog;
				context.fillRect(0, 70, width, height);
			}

			drawSnowfall(weather.snow === 'heavy' ? 1 : (weather.snow === 'light' ? 0.4 : 0), 0.3);
			drawPanel(4, 4, 112, 20);
			drawText(context, `TIME ${formatSeconds(run.time + run.penalty)}`, 8, 7, '#ffffff');
			drawText(context, `GATES ${gates.filter(gate => gate.result !== undefined).length}/${gateCount}`, 8, 15, '#ffee55');
			if (run.message && run.time < run.message.until) {
				drawText(context, run.message.text, 160, 100, run.message.color, {scale: 2, align: 'center'});
			}

			if (run.phase === 'start') {
				drawText(context, 'SLALOM', 160, 90, '#2244dd', {scale: 3, align: 'center', shadow: ''});
				if (isBlinkOn()) {
					drawText(context, 'PRESS GO', 160, 114, '#dd2222', {scale: 2, align: 'center', shadow: ''});
				}
			}
		};

		run.press = control => {
			if (run.phase === 'start' && control === 'action') {
				run.phase = 'race';
				run.isWaiting = false;
				run.speed = 30;
				run.tip = 'Steer with ◀ and ▶ between the poles of each gate. Hold ▼ to crouch, ▲ to brake.';
				comment('start');
			}
		};

		setActionLabel('GO');
		return run;
	};

	// The bobsleigh track of Hunderfossen as a list of parts: straights, and curves to the left (minus) and the right (plus), with how sharp they are and how long: thirteen curves, a few less than the sixteen of the real track.

	const bobTrack = (() => {
		const parts = [
			[0, 70], [-0.022, 50], [0, 40], [0.026, 55], [0, 30], [-0.03, 45], [0.018, 40], [0, 60],
			[-0.035, 60], [0, 25], [0.032, 50], [-0.02, 40], [0, 50], [0.04, 70], [0, 30], [-0.028, 45],
			[0.024, 45], [0, 45], [-0.045, 70], [0, 40], [0.03, 50], [-0.025, 40], [0, 80],
		];
		let start = 0;
		let curve = 0;
		return {
			parts: parts.map(([sharpness, length]) => {
				const part = {sharpness, start, length, curve: sharpness === 0 ? undefined : ++curve};
				start += length;
				return part;
			}),
			length: start,
		};
	})();

	const bobPartAt = distance => bobTrack.parts.find(part => distance >= part.start && distance < part.start + part.length) ?? bobTrack.parts.at(-1);

	// Bobsleigh: mash ◀ and ▶ to push the sled for 40 meters, and press JUMP IN in the green zone. Then the sled races down, and climbs the wall of each curve, more the faster it goes. The visitor steers to keep it on the green line: off the line, it scrapes and loses speed, and over the top of the wall, it tips over.
	events.bobsleigh = weather => {
		const pushLength = 40;
		const zoneStart = 28;
		// Cold ice is fast ice.
		const friction = 0.18 + (clamp((weather.temperature ?? -8) + 18, 0, 19) / 19 * 0.25);
		const mash = makeMashCounter();
		const run = {
			phase: 'start',
			time: 0,
			distance: 0,
			speed: 0,
			lastSide: undefined,
			lateral: 0,
			lateralSpeed: 0,
			crashes: 0,
			scrape: 0,
			pushSpeed: 0,
			message: undefined,
			stripes: 0,
			isWaiting: true,
			tip: 'Press ◀ and ▶ one after the other to push the sled!',
		};

		const show = (text, color) => {
			run.message = {text, color, until: run.time + 0.9};
		};

		const jumpIn = quality => {
			run.phase = 'ride';
			run.pushSpeed = run.speed;
			run.speed *= quality;
			run.tip = 'Steer with ◀ and ▶ to keep the sled on the green line of the curves!';
			setActionLabel('GO');
			show(quality >= 1 ? 'PERFECT START!' : (quality > 0.9 ? 'GOOD START' : 'SLOPPY START'), quality >= 1 ? '#66ff88' : '#ffee55');
		};

		// The height up the wall where the sled wants to be in a curve, from 0 at the bottom to 1 at the top. Plus is the wall on the right.
		const idealLine = () => {
			const part = bobPartAt(run.distance);
			if (part.sharpness === 0) {
				return 0;
			}

			// The sled climbs the outer wall of a curve: the right wall in a curve to the left.
			return clamp(run.speed * run.speed * Math.abs(part.sharpness) / 45, 0.15, 1.05) * -Math.sign(part.sharpness);
		};

		run.step = seconds => {
			if (run.phase === 'start' || run.phase === 'done') {
				return;
			}

			run.time += seconds;
			run.stripes += run.speed * seconds;
			if (run.phase === 'push') {
				run.speed = Math.max(0, run.speed - ((0.3 + (0.12 * run.speed)) * seconds));
				run.distance += run.speed * seconds;
				if (run.distance >= pushLength) {
					jumpIn(0.85);
					show('LATE! THE CREW TUMBLES IN', '#ff7766');
				}

				return;
			}

			// Down the ice: the slope pulls, the air and the ice brake, and scraping the wall brakes more.
			const ideal = idealLine();
			const offLine = Math.abs(run.lateral - ideal);
			run.scrape = offLine > 0.2 ? offLine - 0.1 : 0;
			run.speed = Math.max(5, run.speed + ((3.4 - friction - (0.0024 * run.speed * run.speed) - (run.scrape * 4)) * seconds));
			// The sled swings toward its line like a pendulum, and the arrows push it. It overshoots without steering.
			const steer = (state.held.right ? 1 : 0) - (state.held.left ? 1 : 0);
			const bump = Math.sin(run.distance * 0.37) * 0.6;
			run.lateralSpeed += (((ideal - run.lateral) * 7) - (run.lateralSpeed * 1.1) + (steer * 5.5) + bump) * seconds;
			run.lateral += run.lateralSpeed * seconds;
			if (Math.abs(run.lateral) > 1.25) {
				run.crashes++;
				run.lateral = 0;
				run.lateralSpeed = 0;
				run.speed *= 0.45;
				show('VELT! IT TIPPED OVER!', '#ff5544');
				comment('fall');
				sound.noise(0.8, {volume: 0.15, frequency: 300});
			}

			run.distance += run.speed * seconds;
			if (run.distance >= bobTrack.length) {
				run.phase = 'done';
				const time = Math.round(run.time * 100) / 100;
				finishEvent(time, `Push speed ${(run.pushSpeed * 3.6).toFixed(1)} km/h, top of the run ${(run.speed * 3.6).toFixed(0)} km/h.${run.crashes > 0 ? ` Tipped over ${run.crashes} ${run.crashes === 1 ? 'time' : 'times'}.` : ''} Time: ${formatSeconds(time)} seconds.`, run.crashes > 0);
			}
		};

		// The track from behind the sled: the ice channel as a U, and the parts further ahead smaller and higher, bending with the curves ahead.
		const channel = (center, y, scale, x) => [center + (x * 90 * scale), y - (x * x * 50 * scale)];

		const drawRide = () => {
			drawSky('#1a3a6a', '#a8c0e0', 90);
			drawMountains(run.distance * 0.3, 90, '#d8e2f0', 30);
			fillShape(context, '#e8eef6', 0, 90, width, 110);
			// The forest by the track.
			for (let index = 0; index < 20; index++) {
				const x = (((index * 37) - (run.distance * 2)) % 360 + 360) % 360 - 20;
				fillPolygon(context, '#2d5a3a', [[x, 70], [x + 7, 92], [x - 7, 92]]);
			}

			// The middle of the channel ahead moves to the side with the curves between the sled and there.
			const offsetAt = ahead => {
				let center = 160;
				let bend = 0;
				for (let along = 0; along < ahead; along += 3) {
					bend += bobPartAt(run.distance + along).sharpness * 3;
					center += bend * 22 / 3;
				}

				return center;
			};

			const nearCenter = offsetAt(0);
			const slice = ahead => {
				const scale = 1 / (1 + (ahead / 9 * 0.35));
				const y = 96 + (90 * scale);
				const center = offsetAt(ahead) - ((nearCenter - 160) * (1 - scale));
				const points = [];
				for (let x = -1.3; x <= 1.31; x += 0.1) {
					points.push(channel(center, y, scale, x));
				}

				return {center, y, scale, points};
			};

			// The bands of ice between slices at every 9 meters of the track, from far to near, so they come closer as the sled goes.
			const first = 9 - (run.distance % 9);
			const aheads = [0];
			for (let ahead = first; ahead < 110; ahead += 9) {
				aheads.push(ahead);
			}

			const slices = aheads.map(ahead => slice(ahead));
			for (let index = slices.length - 2; index >= 0; index--) {
				const isStripe = Math.floor((run.distance + aheads[index + 1]) / 9) % 2 === 0;
				fillPolygon(context, isStripe ? '#b8d4ee' : '#dceaf8', [...slices[index].points, ...slices[index + 1].points.toReversed()]);
			}

			// The tops of the walls.
			strokeLine(context, '#5a80b0', 1, slices.map(item => item.points[0]));
			strokeLine(context, '#5a80b0', 1, slices.map(item => item.points.at(-1)));
			// The green line where the sled should be.
			const [lineX, lineY] = channel(slices[0].center, slices[0].y, 1, idealLine());
			fillShape(context, '#22cc55', lineX - 3, lineY - 3, 6, 6);

			// The sled, on the wall at its place, tilted with the wall.
			const [sledX, sledY] = channel(nearCenter, 186, 1, run.lateral);
			context.save();
			context.translate(sledX, sledY - 8);
			context.rotate(Math.atan(run.lateral * 1.1) * 0.9);
			const {suit, trim} = countries[state.athlete.country];
			fillPolygon(context, suit, [[-16, 6], [16, 6], [12, -6], [-12, -6]]);
			fillShape(context, trim, -12, -2, 24, 3);
			for (const helmet of [-8, -2, 4, 10]) {
				fillEllipse(context, trim, helmet - 1, -8, 3, 3);
			}

			fillShape(context, '#333333', -15, 6, 30, 2);
			context.restore();
			if (run.scrape > 0 && isBlinkOn(0.1)) {
				fillShape(context, '#ffffff', sledX - 18, sledY - 2, 4, 2);
				fillShape(context, '#ffffff', sledX + 14, sledY - 2, 4, 2);
			}

			// The sign of the next curve, and a map of the whole track.
			const part = bobPartAt(run.distance);
			const next = bobTrack.parts.find(candidate => candidate.start > run.distance && candidate.sharpness !== 0);
			drawPanel(110, 4, 100, 18);
			if (part.sharpness === 0) {
				drawText(context, next ? `NEXT: ${next.sharpness < 0 ? '<< LEFT' : 'RIGHT >>'} ${next.curve}` : 'FINISH!', 160, 10, '#ffee55', {align: 'center'});
			} else {
				drawText(context, `CURVE ${part.curve}: ${part.sharpness < 0 ? '<< LEFT' : 'RIGHT >>'}`, 160, 10, '#ffffff', {align: 'center'});
			}

			drawTrackMap();
		};

		const drawTrackMap = () => {
			drawPanel(244, 4, 72, 60);
			let x = 0;
			let y = 0;
			let direction = Math.PI / 2;
			const points = [];
			let sledPoint;
			for (let distance = 0; distance <= bobTrack.length; distance += 10) {
				direction += bobPartAt(distance).sharpness * 10;
				x += Math.cos(direction) * 10;
				y += Math.sin(direction) * 10;
				points.push([x, y]);
				if (sledPoint === undefined && distance >= run.distance) {
					sledPoint = [x, y];
				}
			}

			const xs = points.map(point => point[0]);
			const ys = points.map(point => point[1]);
			const left = Math.min(...xs);
			const top = Math.min(...ys);
			const scale = Math.min(64 / (Math.max(...xs) - left), 52 / (Math.max(...ys) - top));
			strokeLine(context, '#a8c8e8', 1, points.map(([pointX, pointY]) => [248 + ((pointX - left) * scale), 8 + ((pointY - top) * scale)]));
			const [sledX, sledY] = sledPoint ?? points.at(-1);
			fillShape(context, '#ff4444', 247 + ((sledX - left) * scale), 7 + ((sledY - top) * scale), 3, 3);
		};

		const drawPush = () => {
			drawSky('#1a3a6a', '#a8c0e0', 90);
			drawMountains(0, 90, '#d8e2f0', 30);
			fillShape(context, '#e8eef6', 0, 90, width, 110);
			// The start ramp from the side, with the line where the crew must be in.
			const toScreen = distance => 40 + (distance * 6.5);
			fillShape(context, '#b8d0ea', 0, 150, width, 8);
			fillShape(context, 'rgba(34, 204, 85, 0.5)', toScreen(zoneStart), 148, (pushLength - zoneStart) * 6.5, 12);
			fillShape(context, '#dd2222', toScreen(pushLength), 140, 2, 22);
			const sledX = toScreen(run.distance);
			const {suit, trim} = countries[state.athlete.country];
			fillPolygon(context, suit, [[sledX - 18, 150], [sledX + 14, 150], [sledX + 20, 142], [sledX - 14, 142]]);
			fillShape(context, trim, sledX - 14, 145, 28, 2);
			const stride = run.distance * 2;
			for (const [index, offset] of [-24, -32, -40, -48].entries()) {
				const legs = Math.round(Math.sin(stride + index) * 2);
				fillShape(context, trim, sledX + offset + legs, 136, 3, 6);
				fillShape(context, suit, sledX + offset + 2, 128, 4, 9);
				fillEllipse(context, trim, sledX + offset + 4, 126, 2.5, 2.5);
			}

			const isZone = run.distance >= zoneStart && run.distance < pushLength;
			drawPanel(4, 4, 130, 20);
			drawText(context, `PUSH ${(run.speed * 3.6).toFixed(1)} KM/H`, 8, 7, '#ffffff');
			drawText(context, `${Math.max(0, Math.ceil(pushLength - run.distance))} M TO THE LINE`, 8, 15, '#ffee55');
			fillEllipse(context, isZone ? '#22ee55' : '#552222', 160, 40, 10, 10);
			drawText(context, isZone ? 'JUMP IN!' : 'PUSH!', 160, 56, isZone ? '#22ee55' : '#ffffff', {scale: 2, align: 'center'});
		};

		run.draw = () => {
			if (run.phase === 'start' || run.phase === 'push') {
				drawPush();
				if (run.phase === 'start' && isBlinkOn()) {
					drawText(context, 'PRESS < AND > TO PUSH', 160, 76, '#ffee55', {scale: 2, align: 'center'});
				}
			} else {
				drawRide();
			}

			drawPanel(4, 176, 120, 20);
			drawText(context, `TIME ${formatSeconds(run.time)}`, 8, 179, '#ffffff');
			drawText(context, `${Math.round(run.speed * 3.6)} KM/H`, 8, 187, '#ffee55');
			if (run.message && run.time < run.message.until) {
				drawText(context, run.message.text, 160, 70, run.message.color, {scale: 2, align: 'center'});
			}
		};

		run.press = control => {
			if ((control === 'left' || control === 'right') && (run.phase === 'start' || run.phase === 'push')) {
				if (run.phase === 'start') {
					run.phase = 'push';
					run.isWaiting = false;
					comment('start');
				}

				if (control !== run.lastSide) {
					run.lastSide = control;
					mash.add(run.time);
					run.speed = Math.min(11.5, run.speed + 0.42);
				}

				return;
			}

			if (control === 'action' && run.phase === 'push') {
				if (run.distance < zoneStart) {
					jumpIn(0.9 - ((zoneStart - run.distance) / zoneStart * 0.3));
					show('TOO EARLY!', '#ff7766');
				} else {
					jumpIn(1);
				}

				setActionLabel('GO');
			}
		};

		setActionLabel('JUMP IN');
		return run;
	};

	// Curling, seen from above, on a sheet that is shorter than a real one, so a stone slides for a few seconds instead of half a minute. Four yellow stones against three red ones in and around the house. The stones curl to the side of their turn as they slow down, sweeping makes them go further and straighter, and they knock each other away.
	events.curling = weather => {
		const stoneRadius = 0.28;
		const houseRadius = 1.83;
		const tee = 18;
		const hogLine = 12.5;
		const backLine = tee + houseRadius;
		const sideWall = 2.2;
		const iceFactor = weather.ice === 'keen' ? 0.92 : (weather.ice === 'heavy' ? 1.08 : 1);
		const makeStone = (team, x, d) => ({team, x, d, vx: 0, vd: 0, isOut: false});
		const stones = [makeStone('red', -0.45, 14.6), makeStone('red', 0.55, 18.4), makeStone('red', -0.95, 19.4)];
		const distanceToTee = stone => Math.hypot(stone.x, stone.d - tee);
		const isInHouse = stone => !stone.isOut && distanceToTee(stone) <= houseRadius + stoneRadius;
		const redInHouseAtStart = new Set(stones.filter(stone => isInHouse(stone)));
		const run = {
			phase: 'aim',
			thrown: 0,
			aimX: 0,
			turn: 1,
			weight: 0,
			meterTime: 0,
			stone: undefined,
			sweep: 0,
			lastSide: undefined,
			camera: 9,
			time: 0,
			message: undefined,
			score: undefined,
			isWaiting: true,
			tip: 'Aim with ◀ and ▶, pick the turn with ▲ and ▼, and press THROW.',
		};

		const show = (text, color, seconds = 1) => {
			run.message = {text, color, until: run.time + seconds};
		};

		const isMoving = () => stones.some(stone => !stone.isOut && Math.hypot(stone.vx, stone.vd) > 0.01);

		const score = () => {
			const yellow = stones.filter(stone => stone.team === 'yellow' && isInHouse(stone));
			let points = 0;
			for (const stone of yellow) {
				const distance = distanceToTee(stone);
				points += distance < 0.4 ? 4 : (distance < 0.9 ? 3 : (distance < 1.4 ? 2 : 1));
			}

			const knockedOut = [...redInHouseAtStart].filter(stone => !isInHouse(stone)).length;
			points += knockedOut * 2;
			const closest = stones.filter(stone => isInHouse(stone)).toSorted((first, second) => distanceToTee(first) - distanceToTee(second))[0];
			const hasShot = closest?.team === 'yellow';
			if (hasShot) {
				points += 2;
			}

			return {points, inHouse: yellow.length, knockedOut, hasShot};
		};

		const throwStone = () => {
			// The meter goes up and down; where it is now is the weight.
			const weight = run.weight;
			const speed = 4.6 + (weight * 4);
			const length = Math.hypot(run.aimX, tee);
			run.stone = makeStone('yellow', 0, 0);
			run.stone.vx = speed * run.aimX / length;
			run.stone.vd = speed * tee / length;
			stones.push(run.stone);
			run.thrown++;
			run.phase = 'slide';
			run.sweep = 0;
			run.tip = 'Sweep with ◀ ▶ ◀ ▶ to make the stone go further and straighter. Hurry hard!';
			setActionLabel('THROW');
			sound.noise(0.6, {volume: 0.05, frequency: 300, rise: 0.05});
		};

		const collide = () => {
			const active = stones.filter(stone => !stone.isOut);
			for (const [index, first] of active.entries()) {
				for (const second of active.slice(index + 1)) {
					const dx = second.x - first.x;
					const dd = second.d - first.d;
					const distance = Math.hypot(dx, dd);
					if (distance === 0 || distance >= stoneRadius * 2) {
						continue;
					}

					const normalX = dx / distance;
					const normalD = dd / distance;
					const approach = ((first.vx - second.vx) * normalX) + ((first.vd - second.vd) * normalD);
					if (approach > 0) {
						// Stones of the same weight swap their speed along the line between them, like billiard balls, with a little lost.
						const impulse = approach * 0.95;
						first.vx -= impulse * normalX;
						first.vd -= impulse * normalD;
						second.vx += impulse * normalX;
						second.vd += impulse * normalD;
						sound.beep(220, 0.06, {type: 'square', volume: 0.08});
					}

					const overlap = (stoneRadius * 2) - distance;
					first.x -= normalX * overlap / 2;
					first.d -= normalD * overlap / 2;
					second.x += normalX * overlap / 2;
					second.d += normalD * overlap / 2;
				}
			}
		};

		const physics = seconds => {
			for (const stone of stones) {
				if (stone.isOut) {
					continue;
				}

				const speed = Math.hypot(stone.vx, stone.vd);
				if (speed <= 0.01) {
					stone.vx = 0;
					stone.vd = 0;
					continue;
				}

				const isThrown = stone === run.stone;
				const sweep = isThrown ? run.sweep : 0;
				const slowdown = Math.min(speed, 1.15 * iceFactor * (1 - (0.22 * sweep)) * seconds);
				// The curl pushes sideways to the direction of the stone, more as it slows down, and less while it is swept.
				const curl = isThrown ? run.turn * 0.42 / (speed + 0.8) * (1 - (0.5 * sweep)) * seconds : 0;
				const directionX = stone.vx / speed;
				const directionD = stone.vd / speed;
				stone.vx -= directionX * slowdown;
				stone.vd -= directionD * slowdown;
				stone.vx += directionD * curl;
				stone.vd -= directionX * curl;
				stone.x += stone.vx * seconds;
				stone.d += stone.vd * seconds;
				if (Math.abs(stone.x) > sideWall - stoneRadius || stone.d > backLine + stoneRadius + 0.3 || stone.d < -1) {
					stone.isOut = true;
					if (isThrown) {
						show('OUT OF PLAY!', '#ff7766');
					}
				}
			}

			collide();
		};

		run.step = seconds => {
			run.time += seconds;
			if (run.phase === 'aim') {
				const move = 1.6 * seconds;
				run.aimX = clamp(run.aimX + ((state.held.right ? move : 0) - (state.held.left ? move : 0)), -1.9, 1.9);
				run.camera += (9 - run.camera) * Math.min(1, seconds * 3);
			} else if (run.phase === 'weight') {
				run.meterTime += seconds;
				// Up and down, once every 1.8 seconds.
				const position = (run.meterTime / 0.9) % 2;
				run.weight = position < 1 ? position : 2 - position;
			} else if (run.phase === 'slide') {
				run.sweep = Math.max(0, run.sweep - (seconds * 1.2));
				for (let index = 0; index < 4; index++) {
					physics(seconds / 4);
				}

				if (run.stone && !run.stone.isOut) {
					run.camera = clamp(run.stone.d - 3, 0, 9);
				}

				if (!isMoving()) {
					if (run.stone && !run.stone.isOut && run.stone.d < hogLine) {
						run.stone.isOut = true;
						show('HOGGED! TOO LIGHT.', '#ff7766');
					} else if (run.stone && !run.stone.isOut) {
						const result = isInHouse(run.stone) ? (distanceToTee(run.stone) < 0.4 ? 'ON THE BUTTON!' : 'IN THE HOUSE!') : 'SHORT OF THE HOUSE.';
						show(result, isInHouse(run.stone) ? '#66ff88' : '#ffee55');
					}

					run.stone = undefined;
					if (run.thrown >= 4) {
						run.phase = 'count';
						run.score = score();
						run.countTime = run.time;
						run.isWaiting = true;
					} else {
						run.phase = 'aim';
						run.isWaiting = true;
						run.tip = `Stone ${run.thrown + 1} of 4. Aim with ◀ and ▶, turn with ▲ and ▼, and press THROW.`;
					}
				}
			} else if (run.phase === 'count' && run.time - run.countTime > 2.5) {
				run.phase = 'done';
				const {points, inHouse, knockedOut, hasShot} = run.score;
				finishEvent(points, `${inHouse} of your stones in the house, ${knockedOut} red ${knockedOut === 1 ? 'stone' : 'stones'} knocked out${hasShot ? ', and you have the stone closest to the middle' : ''}.`);
			}
		};

		run.draw = () => {
			const toX = x => 160 + (x * 16);
			const toY = d => 188 - ((d - run.camera) * 16);
			// The hall: stands with the crowd on both sides of the sheet.
			drawCrowd(0, 0, toX(-sideWall) - 4, height, {offset: run.camera * 16});
			drawCrowd(toX(sideWall) + 4, 0, width - toX(sideWall) - 4, height, {offset: (run.camera * 16) + 2});
			fillShape(context, '#8a6a4a', toX(-sideWall) - 4, 0, 4, height);
			fillShape(context, '#8a6a4a', toX(sideWall), 0, 4, height);

			fillShape(context, '#eef6ff', toX(-sideWall), 0, sideWall * 32, height);
			// The lines and the house.
			fillShape(context, '#cc2222', toX(-sideWall), toY(hogLine), sideWall * 32, 2);
			for (const [radius, color] of [[houseRadius, '#3a6ad8'], [1.22, '#eef6ff'], [0.61, '#dd3333'], [0.15, '#eef6ff']]) {
				fillEllipse(context, color, toX(0), toY(tee), radius * 16, radius * 16);
			}

			fillShape(context, '#333333', toX(-sideWall), toY(tee), sideWall * 32, 1);
			fillShape(context, '#333333', toX(-sideWall), toY(backLine), sideWall * 32, 1);
			fillShape(context, '#333333', toX(0), 0, 1, height);
			// The aim of the skip, with the broom, and the turn of the stone.
			if (run.phase === 'aim' || run.phase === 'weight') {
				context.setLineDash([2, 3]);
				strokeLine(context, '#555555', 1, [[toX(0), toY(run.camera)], [toX(run.aimX), toY(tee)]]);
				context.setLineDash([]);
				fillShape(context, '#ffd21f', toX(run.aimX) - 4, toY(tee) - 1, 8, 3);
				strokeLine(context, '#8a5a2a', 1, [[toX(run.aimX), toY(tee)], [toX(run.aimX) + 4, toY(tee) - 12]]);
				drawText(context, run.turn > 0 ? 'TURN >' : '< TURN', toX(run.aimX), toY(tee) - 22, '#ba0c2f', {align: 'center', shadow: ''});
			}

			for (const stone of stones) {
				if (stone.isOut) {
					continue;
				}

				const x = toX(stone.x);
				const y = toY(stone.d);
				fillEllipse(context, '#8a8a92', x, y, stoneRadius * 16, stoneRadius * 16);
				fillEllipse(context, stone.team === 'yellow' ? '#ffd21f' : '#dd2222', x, y, stoneRadius * 10, stoneRadius * 10);
				fillShape(context, '#222222', x - 1, y - 2, 2, 3);
			}

			// The sweepers by the stone, and their shouts.
			if (run.stone && !run.stone.isOut && run.sweep > 0.1) {
				const x = toX(run.stone.x);
				const y = toY(run.stone.d) - 9;
				const brush = element.reducedMotion ? 0 : Math.sin(run.time * 30) * 3;
				fillShape(context, '#8a5a2a', x - 6 + brush, y, 4, 2);
				fillShape(context, '#8a5a2a', x + 2 - brush, y, 4, 2);
				drawText(context, 'HURRY HARD!', x + 14, y - 4, '#ba0c2f', {shadow: ''});
			}

			drawPanel(4, 4, 92, 36);
			drawText(context, `STONE ${Math.min(run.thrown + (run.phase === 'aim' || run.phase === 'weight' ? 1 : 0), 4)}/4`, 8, 7, '#ffffff');
			drawText(context, `POINTS ${score().points}`, 8, 15, '#ffee55');
			drawText(context, `ICE: ${weather.ice.toUpperCase()}`, 8, 23, '#aaccff');
			if (run.phase === 'weight' || run.phase === 'aim') {
				drawPanel(4, 60, 30, 104);
				drawText(context, 'WEIGHT', 6, 62, '#ffffff', {shadow: ''});
				fillShape(context, '#552222', 12, 72, 14, 88);
				// The weights that reach the house, without sweeping.
				const houseBottom = (Math.sqrt(2 * 1.15 * iceFactor * (tee - houseRadius)) - 4.6) / 4;
				const houseTop = (Math.sqrt(2 * 1.15 * iceFactor * backLine) - 4.6) / 4;
				fillShape(context, '#22aa44', 12, 160 - (houseTop * 88), 14, (houseTop - houseBottom) * 88);
				if (run.phase === 'weight') {
					fillShape(context, '#ffee55', 10, 159 - (run.weight * 88), 18, 3);
				}
			}

			if (run.phase === 'slide' && run.sweep > 0) {
				drawMeter(230, 186, 80, run.sweep, {label: 'SWEEP', good: [0.5, 1]});
			}

			if (run.message && run.time < run.message.until) {
				drawText(context, run.message.text, 160, 70, run.message.color, {scale: 2, align: 'center'});
			}

			if (run.phase === 'count' || run.phase === 'done') {
				const {points, inHouse, knockedOut, hasShot} = run.score;
				drawPanel(70, 60, 180, 70);
				drawText(context, `${points} POINTS`, 160, 66, '#66ff88', {scale: 3, align: 'center'});
				drawText(context, `${inHouse} IN THE HOUSE`, 160, 92, '#ffffff', {align: 'center'});
				drawText(context, `${knockedOut} RED KNOCKED OUT`, 160, 102, '#ffffff', {align: 'center'});
				drawText(context, hasShot ? 'SHOT STONE: YELLOW +2' : 'SHOT STONE: RED', 160, 112, hasShot ? '#ffee55' : '#ff7766', {align: 'center'});
			}
		};

		run.press = control => {
			if (run.phase === 'aim') {
				if (control === 'up') {
					run.turn = 1;
				} else if (control === 'down') {
					run.turn = -1;
				} else if (control === 'action') {
					run.phase = 'weight';
					run.isWaiting = false;
					run.meterTime = 0;
					run.weight = 0;
					run.tip = 'Press THROW again to let go, when the weight meter is in the green.';
					setActionLabel('LET GO');
				}
			} else if (run.phase === 'weight' && control === 'action') {
				throwStone();

			} else if (run.phase === 'slide' && (control === 'left' || control === 'right') && control !== run.lastSide) {
				run.lastSide = control;
				run.sweep = Math.min(1, run.sweep + 0.16);
				sound.noise(0.05, {volume: 0.03, frequency: 3000});
			}
		};

		setActionLabel('THROW');
		return run;
	};

	// The ice hockey shootout, with the goal seen from the front: five shots by the visitor, and five shots at the visitor as the goalie. The goal is 120 × 78 pixels, and the goalie covers more of it high with the glove up, and more of it low when down on the ice.
	events.hockey = () => {
		const goal = {left: 100, right: 220, top: 62, bottom: 140};
		const spots = [[112, 72], [208, 72], [113, 128], [207, 128], [160, 133], [136, 92], [184, 92]];
		const run = {
			round: 0,
			turn: 'attack',
			phase: 'approach',
			phaseTime: 0,
			goals: 0,
			saves: 0,
			goalieX: 160,
			goalieTarget: 160,
			stance: 'stand',
			dekeUntil: -1,
			dekeX: 0,
			hasDeked: false,
			crossPhase: [Math.random() * 6, Math.random() * 6],
			shot: undefined,
			tell: 0,
			results: [],
			message: undefined,
			time: 0,
			isWaiting: true,
			tip: 'Your shot! Press SHOOT when the crosshair is where the goalie is not.',
		};

		const crosshair = () => ({
			x: 160 + (80 * Math.sin((run.phaseTime * 1.6) + run.crossPhase[0])),
			y: 101 + (43 * Math.sin((run.phaseTime * 2.4) + run.crossPhase[1])),
		});

		// Whether the goalie at a place, in a stance, stops a puck at a point of the goal.
		const covers = (goalieX, stance, x, y) => {
			const distance = Math.abs(x - goalieX);
			if (stance === 'high') {
				return y < 100 ? distance <= 26 : (y < 125 ? distance <= 18 : distance <= 10);
			}

			if (stance === 'down') {
				return y > 108 ? distance <= 30 : (y > 86 ? distance <= 18 : false);
			}

			return y >= 76 ? distance <= 20 : distance <= 12;
		};

		const show = (text, color) => {
			run.message = {text, color, until: run.time + 1.1};
		};

		const nextPhase = (phase, tip) => {
			run.phase = phase;
			run.phaseTime = 0;
			if (tip) {
				run.tip = tip;
			}
		};

		const startTurn = () => {
			run.goalieX = 160;
			run.goalieTarget = 160;
			run.stance = 'stand';
			run.hasDeked = false;
			run.dekeUntil = -1;
			run.shot = undefined;
			run.crossPhase = [Math.random() * 6, Math.random() * 6];
			run.isWaiting = true;
			if (run.turn === 'attack') {
				setActionLabel('SHOOT');
				nextPhase('approach', `Shot ${run.round + 1} of 5. Press SHOOT when the crosshair is where the goalie is not. ◀ or ▶ fakes a shot.`);
			} else {
				// Where the shooter aims, and the side the stick shows before the shot, which is true three times out of four.
				const [x, y] = randomItem(spots);
				run.shot = {x: x + randomBetween(-4, 4), y: y + randomBetween(-4, 4), progress: 0, isCpu: true};
				run.tell = Math.random() < 0.75 ? Math.sign(run.shot.x - 160) : -Math.sign(run.shot.x - 160);
				setActionLabel('SAVE');
				nextPhase('approach', `Save ${run.round + 1} of 5! Move with ◀ and ▶, hold ▲ for a high save and ▼ to go down. Watch the stick of the shooter.`);
			}
		};

		const shoot = () => {
			const {x, y} = crosshair();
			run.shot = {x, y, progress: 0};
			nextPhase('shot');
			run.isWaiting = true;
			sound.noise(0.1, {volume: 0.1, frequency: 1500, rise: 0.002});
		};

		const resolve = () => {
			const {x, y, isCpu} = run.shot;
			const isWide = x < goal.left + 3 || x > goal.right - 3 || y < goal.top + 3;
			const isPost = isWide && (Math.abs(x - goal.left) < 7 || Math.abs(x - goal.right) < 7 || Math.abs(y - goal.top) < 6);
			const isSaved = !isWide && covers(run.goalieX, run.stance, x, y);
			let result;
			if (isWide) {
				result = isCpu ? 'save' : 'miss';
				show(isPost ? 'PING! THE POST!' : 'WIDE!', isCpu ? '#66ff88' : '#ff7766');
				sound.beep(isPost ? 1600 : 200, isPost ? 0.3 : 0.1, {type: isPost ? 'triangle' : 'square'});
			} else if (isSaved) {
				result = isCpu ? 'save' : 'miss';
				show(isCpu ? 'WHAT A SAVE!' : 'SAVED!', isCpu ? '#66ff88' : '#ff7766');
				sound.beep(300, 0.08);
			} else {
				result = isCpu ? 'goal-against' : 'goal';
				show(isCpu ? 'GOAL AGAINST...' : 'GOAL!!!', isCpu ? '#ff7766' : '#66ff88');
				sound.beep(isCpu ? 180 : 880, 0.3, {type: 'sawtooth'});
				if (!isCpu) {
					sound.crowd();
				}
			}

			if (result === 'goal') {
				run.goals++;
			} else if (result === 'save' && isCpu) {
				run.saves++;
			}

			run.results.push(result);
			nextPhase('result');
			run.isWaiting = true;
		};

		run.step = seconds => {
			run.time += seconds;
			run.phaseTime += seconds;
			const goalieSpeed = run.turn === 'attack' ? 150 : 210;
			if (run.turn === 'attack') {
				// The goalie watches the puck, sways a little, and goes for a fake.
				if (run.phase !== 'shot' || run.phaseTime < 0.2) {
					run.goalieTarget = 160 + (Math.sin(run.time * 1.3) * 8) + (run.time < run.dekeUntil ? run.dekeX : 0);
				} else {
					run.goalieTarget = run.shot.x;
					run.stance = run.shot.y < 96 ? 'high' : (run.shot.y > 114 ? 'down' : 'stand');
				}

				const step = goalieSpeed * seconds;
				run.goalieX += clamp(run.goalieTarget - run.goalieX, -step, step);
			} else if (run.phase !== 'result') {
				const move = (state.held.right ? 1 : 0) - (state.held.left ? 1 : 0);
				run.goalieX = clamp(run.goalieX + (move * goalieSpeed * seconds), goal.left + 10, goal.right - 10);
				run.stance = state.held.up ? 'high' : (state.held.down ? 'down' : 'stand');
			}

			if (run.phase === 'approach' && run.phaseTime > (run.turn === 'attack' ? 0.9 : 1.6)) {
				if (run.turn === 'attack') {
					nextPhase('aim');
					run.isWaiting = false;
				} else {
					nextPhase('shot');
					sound.noise(0.1, {volume: 0.1, frequency: 1500, rise: 0.002});
				}
			} else if (run.phase === 'aim' && run.phaseTime > 3.5) {
				shoot();
			} else if (run.phase === 'shot') {
				run.shot.progress = Math.min(1, run.phaseTime / (run.shot.isCpu ? 0.4 : 0.32));
				if (run.shot.progress >= 1) {
					resolve();
				}
			} else if (run.phase === 'result' && run.phaseTime > 1.3) {
				if (run.turn === 'attack') {
					run.turn = 'defend';
					startTurn();
				} else if (run.round < 4) {
					run.round++;
					run.turn = 'attack';
					startTurn();
				} else {
					run.phase = 'done';
					const total = run.goals + run.saves;
					finishEvent(total, `${run.goals} of 5 shots in the goal, and ${run.saves} of 5 shots saved.`);
				}
			}
		};

		const drawGoalie = (x, stance, color) => {
			const top = stance === 'down' ? 108 : 82;
			// The pads, the body, the mask, and the glove and the blocker.
			if (stance === 'down') {
				fillShape(context, '#ffffff', x - 36, 128, 30, 12);
				fillShape(context, '#ffffff', x + 6, 128, 30, 12);
			} else {
				fillShape(context, '#ffffff', x - 16, 112, 12, 28);
				fillShape(context, '#ffffff', x + 4, 112, 12, 28);
			}

			fillShape(context, color, x - 14, top, 28, stance === 'down' ? 22 : 32);
			fillEllipse(context, '#dddddd', x, top - 7, 7, 8);
			fillShape(context, '#333333', x - 4, top - 9, 8, 6);
			const armY = stance === 'high' ? top - 14 : top + 8;
			const reach = stance === 'high' ? 30 : 22;
			fillEllipse(context, '#8a5a2a', x - reach, armY, 6, 6);
			fillShape(context, '#ffffff', x + reach - 5, armY - 6, 10, 12);
		};

		run.draw = () => {
			// The rink: the crowd behind the glass, the boards, and the ice.
			drawCrowd(0, 0, width, 46, {wave: run.phase === 'result' && run.results.at(-1) === 'goal'});

			fillShape(context, '#ffffff', 0, 46, width, 6);
			fillShape(context, '#dceaf6', 0, 52, width, 148);
			strokeLine(context, '#dd2222', 2, [[0, goal.bottom + 1], [width, goal.bottom + 1]]);
			// The crease and the net.
			fillPolygon(context, '#9ac0ee', [[goal.left, goal.bottom], [goal.right, goal.bottom], [goal.right + 12, goal.bottom + 14], [goal.left - 12, goal.bottom + 14]]);
			fillShape(context, '#f4f8fc', goal.left, goal.top, goal.right - goal.left, goal.bottom - goal.top);
			context.strokeStyle = '#c8d0dc';
			context.lineWidth = 1;
			for (let x = goal.left; x <= goal.right; x += 8) {
				strokeLine(context, '#c8d0dc', 1, [[x, goal.top], [x, goal.bottom]]);
			}

			for (let y = goal.top; y <= goal.bottom; y += 8) {
				strokeLine(context, '#c8d0dc', 1, [[goal.left, y], [goal.right, y]]);
			}

			const isAttack = run.turn === 'attack';
			drawGoalie(run.goalieX, run.stance, isAttack ? '#444444' : countries[state.athlete.country].suit);
			// The posts and the crossbar, in red.
			fillShape(context, '#dd2222', goal.left - 3, goal.top - 3, 3, goal.bottom - goal.top + 3);
			fillShape(context, '#dd2222', goal.right, goal.top - 3, 3, goal.bottom - goal.top + 3);
			fillShape(context, '#dd2222', goal.left - 3, goal.top - 3, goal.right - goal.left + 6, 3);
			// The shooter of the other team, who skates in, and shows a side with the stick before the shot.
			if (!isAttack && run.phase === 'approach') {
				const size = 0.5 + (run.phaseTime / 1.6 * 0.5);
				const x = 160;
				const y = 196;
				fillShape(context, '#444444', x - (8 * size), y - (40 * size), 16 * size, 26 * size);
				fillEllipse(context, '#222222', x, y - (46 * size), 6 * size, 6 * size);
				if (run.phaseTime > 1) {
					strokeLine(context, '#8a5a2a', 3, [[x, y - (24 * size)], [x + (run.tell * 30), y - 6]]);
				}
			}

			if (isAttack && run.phase === 'aim') {
				const {x, y} = crosshair();
				context.strokeStyle = '#ff2222';
				context.lineWidth = 1;
				context.beginPath();
				context.arc(x, y, 6, 0, Math.PI * 2);
				context.stroke();
				strokeLine(context, '#ff2222', 1, [[x - 9, y], [x + 9, y]]);
				strokeLine(context, '#ff2222', 1, [[x, y - 9], [x, y + 9]]);
			}

			// The puck, from the stick to the goal, growing as it comes closer on a save.
			if (run.shot && (run.phase === 'shot' || run.phase === 'result')) {
				const progress = run.phase === 'result' ? 1 : run.shot.progress;
				const startX = 160;
				const startY = isAttack ? 196 : 186;
				const x = startX + ((run.shot.x - startX) * progress);
				const y = startY + ((run.shot.y - startY) * progress) - (Math.sin(progress * Math.PI) * 12);
				const size = isAttack ? 3 - progress : 1.5 + (progress * 2.5);
				fillEllipse(context, '#111111', x, y, size * 1.4, size);
			}

			// Your stick at the bottom, when you shoot.
			if (isAttack) {
				strokeLine(context, '#8a5a2a', 3, [[150, 200], [158, 186]]);
				fillShape(context, '#111111', 156, 186, 8, 3);
			}

			drawPanel(4, 160, 80, 36);
			drawText(context, isAttack ? `SHOT ${run.round + 1}/5` : `SAVE ${run.round + 1}/5`, 8, 163, '#ffffff');
			drawText(context, `GOALS ${run.goals}`, 8, 172, '#66ff88');
			drawText(context, `SAVES ${run.saves}`, 8, 181, '#66ccff');
			for (const [index, result] of run.results.entries()) {
				fillShape(context, result === 'goal' || result === 'save' ? '#66ff88' : '#ff5544', 236 + ((index % 10) * 8), 186, 6, 6);
			}

			if (run.message && run.time < run.message.until) {
				drawText(context, run.message.text, 160, 26, run.message.color, {scale: 2, align: 'center'});
			} else if (run.phase === 'approach') {
				drawText(context, isAttack ? 'YOUR SHOT' : 'YOU ARE THE GOALIE', 160, 26, '#ffee55', {scale: 2, align: 'center'});
			}
		};

		run.press = control => {
			if (run.turn !== 'attack' || run.phase !== 'aim') {
				return;
			}

			if (control === 'action') {
				shoot();
			} else if ((control === 'left' || control === 'right') && !run.hasDeked) {
				// A fake to one side: the goalie goes there for a moment.
				run.hasDeked = true;
				run.dekeX = control === 'left' ? -34 : 34;
				run.dekeUntil = run.time + 0.7;
				show('DEKE!', '#ffee55');
			}
		};

		startTurn();
		return run;
	};

	// The music of the figure skating: In the Hall of the Mountain King by Edvard Grieg (1875), the theme four times, faster each time. The notes on a whole beat are the steps, and the long note at the end of each theme is a jump.
	const mountainKing = parseMelody('B3:.5 C#4:.5 D4:.5 E4:.5 F#4:.5 D4:.5 F#4 F4:.5 C#4:.5 F4 E4:.5 C4:.5 E4 B3:.5 C#4:.5 D4:.5 E4:.5 F#4:.5 D4:.5 F#4:.5 B4:.5 A4:.5 F#4:.5 D4:.5 F#4:.5 A4:2');
	const skatingLanes = ['left', 'down', 'up', 'right'];

	const laneOfNote = note => {
		const letter = note.charAt(0);
		if ((letter === 'B' && note.endsWith('3')) || letter === 'C') {
			return 0;
		}

		if (letter === 'D' || letter === 'E') {
			return 1;
		}

		if (letter === 'F') {
			return 2;
		}

		return 3;
	};

	// Figure skating, a rhythm game: arrows slide to the line, and each is a step to press on time. A star is a jump. Five judges give marks of up to 6.0 for the technical merit and the artistic impression, as in 1999.
	events.figure = () => {
		const tempos = [100, 118, 138, 160];
		const leadIn = 2.2;
		const travel = 1.8;
		const notes = [];
		const steps = [];
		let start = leadIn;
		for (const [repeat, tempo] of tempos.entries()) {
			const secondsPerBeat = 60 / tempo;
			for (const {note, beat, beats} of mountainKing.notes) {
				const time = start + (beat * secondsPerBeat);
				notes.push({note, time, length: beats * secondsPerBeat, isScheduled: false});
				if (Number.isInteger(beat)) {
					const isJump = beats >= 2;
					// Every other theme has the arrows the other way around, so it does not get boring.
					const lane = isJump ? 4 : (repeat % 2 === 0 ? laneOfNote(note) : 3 - laneOfNote(note));
					steps.push({time, lane, isJump, result: undefined});
				}
			}

			start += mountainKing.beats * secondsPerBeat;
		}

		const endTime = start + 1;
		const run = {
			phase: 'ready',
			time: 0,
			combo: 0,
			maxCombo: 0,
			perfect: 0,
			good: 0,
			jumpsLanded: 0,
			stumbles: 0,
			move: undefined,
			marks: undefined,
			message: undefined,
			steps,
			hasMusic: false,
			isWaiting: true,
			tip: 'Press JUMP to start the music.',
		};

		const jumps = steps.filter(item => item.isJump).length;
		const jumpNames = ['TRIPLE AXEL', 'DOUBLE LUTZ', 'TRIPLE SALCHOW', 'THE SINDRE TOE LOOP'];

		const show = (text, color) => {
			run.message = {text, color, until: run.time + 0.6};
		};

		const judge = (item, offset) => {
			const isPerfect = Math.abs(offset) <= 0.07;
			item.result = isPerfect ? 'perfect' : 'good';
			run[item.result]++;
			run.combo++;
			run.maxCombo = Math.max(run.maxCombo, run.combo);
			if (item.isJump) {
				run.jumpsLanded++;
				run.move = {type: 'jump', until: run.time + 0.6};
				show(jumpNames[(run.jumpsLanded - 1) % jumpNames.length], '#66ff88');
				sound.crowd();
			} else {
				run.move = {type: 'step', until: run.time + 0.25};
				show(isPerfect ? 'PERFECT' : 'GOOD', isPerfect ? '#66ff88' : '#ffee55');
			}
		};

		const miss = item => {
			item.result = 'miss';
			run.combo = 0;
			if (item.isJump) {
				run.move = {type: 'fall', until: run.time + 0.9};
				show('FALL!', '#ff5544');
				sound.noise(0.3, {volume: 0.1, frequency: 300});
			} else {
				show('MISS', '#ff7766');
			}
		};

		const finish = () => {
			run.phase = 'marks';
			run.isWaiting = true;
			const accuracy = ((2 * run.perfect) + run.good) / (2 * steps.length);
			const penalty = Math.min(1.5, run.stumbles * 0.06);
			const technical = 3 + (2.95 * ((0.55 * run.jumpsLanded / jumps) + (0.45 * accuracy))) - penalty;
			const artistic = 3 + (2.95 * ((0.5 * accuracy) + (0.5 * run.maxCombo / steps.length))) - (penalty / 2);
			const marks = base => Array.from({length: 5}, () => clamp(Math.round((base + (randomNormal() * 0.08)) * 10) / 10, 0, 6));
			const average = values => {
				let sum = 0;
				for (const value of values) {
					sum += value;
				}

				return sum / values.length;
			};
			run.marks = {technical: marks(technical), artistic: marks(artistic)};
			run.total = Math.round((average(run.marks.technical) + average(run.marks.artistic)) * 10) / 10;
			run.marksTime = run.time;
			tune.stop();
			sound.crowd();
		};

		run.step = seconds => {
			if (run.phase === 'ready') {
				return;
			}

			run.time += seconds;
			if (run.phase === 'skate') {
				// The notes of the music are played just before their time, so the music pauses with the game.
				for (const note of notes) {
					if (!note.isScheduled && note.time < run.time + 0.1) {
						note.isScheduled = true;
						if (run.hasMusic && tune.isPlaying && note.time >= run.time - 0.05) {
							sound.beep(noteFrequency(note.note), Math.max(0.08, note.length * 0.85), {type: 'square', volume: 0.06, when: note.time - run.time, destination: tune.gain});
							sound.beep(noteFrequency(note.note) / 2, Math.max(0.08, note.length * 0.85), {type: 'triangle', volume: 0.08, when: note.time - run.time, destination: tune.gain});
						}
					}
				}

				for (const item of steps) {
					if (item.result === undefined && run.time - item.time > 0.15) {
						miss(item);
					}
				}

				if (run.time >= endTime) {
					finish();
				}
			} else if (run.phase === 'marks' && run.time - run.marksTime > 4) {
				run.phase = 'done';
				finishEvent(run.total, `${run.perfect} perfect and ${run.good} good steps of ${steps.length}, ${run.jumpsLanded} of ${jumps} jumps landed, and a run of ${run.maxCombo} without a miss. Technical merit: ${run.marks.technical.map(mark => mark.toFixed(1)).join(', ')}. Artistic impression: ${run.marks.artistic.map(mark => mark.toFixed(1)).join(', ')}.`, run.jumpsLanded < jumps);
			}
		};

		const laneY = lane => 16 + (lane * 19);
		const hitX = 40;

		const drawArrow = (x, y, lane, color) => {
			if (lane === 4) {
				fillEllipse(context, color, x, y, 8, 8);
				drawText(context, 'J', x, y - 2, '#000000', {align: 'center', shadow: ''});
				return;
			}

			const shapes = [
				[[-6, 0], [2, -6], [2, -2], [6, -2], [6, 2], [2, 2], [2, 6]],
				[[0, 6], [-6, -2], [-2, -2], [-2, -6], [2, -6], [2, -2], [6, -2]],
				[[0, -6], [6, 2], [2, 2], [2, 6], [-2, 6], [-2, 2], [-6, 2]],
				[[6, 0], [-2, 6], [-2, 2], [-6, 2], [-6, -2], [-2, -2], [-2, -6]],
			];
			fillPolygon(context, color, shapes[lane].map(([pointX, pointY]) => [x + (pointX * 1.3), y + (pointY * 1.3)]));
		};

		run.draw = () => {
			// The hall of Hamar at night, with the spotlight on the ice.
			drawSky('#0a0a2a', '#2a1a4a', 110);
			const laneColors = ['#ff66cc', '#66ccff', '#66ff88', '#ffaa44', '#ffee55'];
			for (let lane = 0; lane < 5; lane++) {
				fillShape(context, 'rgba(255, 255, 255, 0.06)', 0, laneY(lane) - 8, width, 16);
				drawArrow(hitX, laneY(lane), lane, 'rgba(255, 255, 255, 0.3)');
			}

			strokeLine(context, '#ffffff', 1, [[hitX, 6], [hitX, 102]]);
			for (const item of steps) {
				if (item.result !== undefined && item.result !== 'miss') {
					continue;
				}

				const x = hitX + ((item.time - run.time) / travel * (width - hitX));
				if (x < -10 || x > width + 10) {
					continue;
				}

				drawArrow(x, laneY(item.lane), item.lane, item.result === 'miss' ? '#555566' : laneColors[item.lane]);
			}

			// The ice and the crowd, with the skater in the spotlight.
			drawCrowd(0, 106, width, 16, {wave: run.phase === 'marks'});

			fillShape(context, '#dceaf6', 0, 122, width, 78);
			fillEllipse(context, 'rgba(255, 255, 220, 0.5)', 160, 172, 60, 14);
			const move = run.move && run.time < run.move.until ? run.move.type : 'glide';
			const glide = element.reducedMotion ? 0 : Math.sin(run.time * 0.8) * 50;
			const {suit, trim} = countries[state.athlete.country];
			// The skater is drawn twice as big, around the feet.
			context.save();
			context.translate(160 + glide, 186);
			context.scale(2, 2);
			context.translate(0, -180);
			const x = 0;
			if (move === 'fall') {
				fillShape(context, suit, x - 8, 176, 14, 5);
				fillEllipse(context, '#f3c9a0', x + 8, 177, 3, 3);
			} else {
				const lift = move === 'jump' ? Math.sin((run.move.until - run.time) / 0.6 * Math.PI) * 18 : 0;
				const spin = move === 'jump' || move === 'step' ? Math.cos(run.time * 40) : 1;
				const y = 180 - lift;
				strokeLine(context, trim, 2, [[x, y - 10], [x - 2, y]]);
				strokeLine(context, trim, 2, [[x, y - 10], [x + (move === 'step' ? 6 : 2), y - 1]]);
				fillShape(context, suit, x - 4, y - 20, 8, 10);
				strokeLine(context, suit, 2, [[x - 4, y - 18], [x - (10 * spin), y - 22]]);
				strokeLine(context, suit, 2, [[x + 4, y - 18], [x + (10 * spin), y - 22]]);
				fillEllipse(context, '#f3c9a0', x, y - 24, 3, 3);
				fillShape(context, '#ffd21f', x - 3, y - 28, 6, 2);
			}

			context.restore();

			drawPanel(4, 182, 120, 14);
			drawText(context, `COMBO ${run.combo}  JUMPS ${run.jumpsLanded}/${jumps}`, 8, 186, '#ffffff');
			if (run.message && run.time < run.message.until) {
				drawText(context, run.message.text, 200, 132, run.message.color, {scale: 2, align: 'center', shadow: '#000000'});
			}

			if (run.phase === 'ready') {
				drawText(context, 'FIGURE SKATING', 160, 130, '#2a1a4a', {scale: 2, align: 'center', shadow: ''});
				if (isBlinkOn()) {
					drawText(context, 'PRESS JUMP TO START THE MUSIC', 160, 150, '#ba0c2f', {align: 'center', shadow: ''});
				}
			}

			if (run.phase === 'marks' || run.phase === 'done') {
				// Flowers and teddy bears on the ice, and the marks of the judges.
				for (let index = 0; index < 14; index++) {
					fillShape(context, index % 3 === 0 ? '#8a5a2a' : '#ff66aa', 20 + ((index * 41) % 280), 130 + ((index * 23) % 60), 4, 4);
				}

				drawPanel(30, 18, 260, 86);
				drawText(context, 'TECHNICAL MERIT', 160, 24, '#ffffff', {align: 'center'});
				drawText(context, run.marks.technical.map(mark => mark.toFixed(1)).join('  '), 160, 34, '#ffee55', {scale: 2, align: 'center'});
				drawText(context, 'ARTISTIC IMPRESSION', 160, 52, '#ffffff', {align: 'center'});
				drawText(context, run.marks.artistic.map(mark => mark.toFixed(1)).join('  '), 160, 62, '#ffee55', {scale: 2, align: 'center'});
				drawText(context, `TOTAL ${run.total.toFixed(1)}`, 160, 84, '#66ff88', {scale: 2, align: 'center'});
			}
		};

		run.press = control => {
			if (run.phase === 'ready') {
				if (control === 'action') {
					run.phase = 'skate';
					run.isWaiting = false;
					run.hasMusic = tune.begin();
					run.tip = 'Press the arrow when it reaches the line on the left, and JUMP at a star.';
					comment('start', run.hasMusic ? '' : 'Turn on the sound to hear Grieg.');
				}

				return;
			}

			if (run.phase !== 'skate') {
				return;
			}

			const lane = control === 'action' ? 4 : skatingLanes.indexOf(control);
			const candidates = steps.filter(item => item.lane === lane && item.result === undefined && Math.abs(item.time - run.time) <= 0.15);
			if (candidates.length === 0) {
				run.stumbles++;
				run.combo = 0;
				show('STUMBLE', '#ff7766');
				return;
			}

			const item = candidates.toSorted((first, second) => Math.abs(first.time - run.time) - Math.abs(second.time - run.time))[0];
			judge(item, run.time - item.time);
		};

		setActionLabel('JUMP');
		return run;
	};

	// The interview after an event, with three answers for the visitor and the reply of the reporter, in Norwegian and English.
	const interviews = {
		gold: {
			question: ['Gratulerer! Hvordan føles det?', 'Congratulations! How does it feel?'],
			answers: [
				[['Det var en god dag på jobben.', 'It was a good day at the office.'], ['En god dag på jobben! Typisk norsk beskjedenhet.', 'A good day at the office! Typical Norwegian modesty.']],
				[['Jeg vil takke smøreteamet!', 'I want to thank the wax team!'], ['Smøreteamet jubler i bua!', 'The wax team cheers in their hut!']],
				[['Hei mamma! Jeg er på TV!', 'Hi Mom! I am on TV!'], ['Mamma, hvis du ser på: han har spist opp maten sin.', 'Mom, if you are watching: he ate all his food.']],
			],
		},
		medal: {
			question: ['En medalje! Er du fornøyd?', 'A medal! Are you happy?'],
			answers: [
				[['Jeg tar gull neste gang.', 'I will take gold next time.'], ['Det liker vi å høre!', 'We like to hear that!']],
				[['Sølv er også et metall.', 'Silver is a metal too.'], ['Og bronse er nesten gull, i mørket.', 'And bronze is almost gold, in the dark.']],
				[['Jeg tenker bare på vafler nå.', 'I only think of waffles now.'], ['Vaffelbua er rett bak deg!', 'The waffle stand is right behind you!']],
			],
		},
		none: {
			question: ['Hva skjedde der ute?', 'What happened out there?'],
			answers: [
				[['Det var feil smøring.', 'It was the wrong wax.'], ['Smøringen, ja. Det er alltid smøringen.', 'The wax, yes. It is always the wax.']],
				[['Jeg hadde motvind hele veien.', 'I had head wind all the way.'], ['Hele veien? Også innendørs?', 'All the way? Even indoors?']],
				[['Det er ingen skam å snu.', 'There is no shame in turning back.'], ['Fjellvettreglene! Du har lest baksiden av Kvikk Lunsj.', 'The mountain code! You read the back of a Kvikk Lunsj.']],
			],
		},
		fall: {
			question: ['Gikk det bra med deg?', 'Are you OK?'],
			answers: [
				[['Snøen var myk.', 'The snow was soft.'], ['Det var den ikke. Vi så det i reprisen.', 'It was not. We saw it in the replay.']],
				[['Jeg gjorde det med vilje.', 'I did it on purpose.'], ['Selvfølgelig. For publikum.', 'Of course. For the crowd.']],
				[['Hvem er jeg?', 'Who am I?'], ['Kan vi få en lege hit?', 'Can we get a doctor here?']],
			],
		},
	};

	// The rivals have good days and bad days. Their skill sets where their result is between the result of a first try and the result of an expert, and now and then one of them has a disaster.
	const rivalResult = (id, skill) => {
		const info = eventInfo[id];
		let luck = skill + (randomNormal() * 0.07);
		if (Math.random() < 0.06) {
			luck -= 0.5;
		}

		const value = info.beginner + ((info.expert - info.beginner) * clamp(luck, -0.3, 1.06)) + (info.weatherEffect?.(state.weather) ?? 0);
		if (info.isWhole) {
			return clamp(Math.round(value), 0, id === 'hockey' ? 10 : 22);
		}

		return Math.round(value * (info.isTime ? 100 : 10)) / (info.isTime ? 100 : 10);
	};

	const currentRecord = id => {
		const stored = state.records[id];
		if (typeof stored?.value === 'number' && typeof stored.initials === 'string' && Object.hasOwn(countries, stored.country)) {
			return stored;
		}

		return {value: eventInfo[id].record, initials: 'OLA', country: 'NOR', isRival: true};
	};

	const medalNames = ['gold', 'silver', 'bronze'];
	const medalEmoji = ['🥇', '🥈', '🥉'];

	// A row of a table of results, in bold for the athlete.
	const tableRow = (texts, isAthlete = false) => {
		const row = document.createElement('tr');
		for (const text of texts) {
			const cell = document.createElement('td');
			if (isAthlete) {
				const strong = document.createElement('strong');
				strong.textContent = String(text);
				cell.append(strong);
			} else {
				cell.textContent = String(text);
			}

			row.append(cell);
		}

		return row;
	};

	const finishEvent = (value, summary, hadFall = false) => {
		const id = state.eventId;
		const info = eventInfo[id];
		const competitors = [
			{name: state.athlete.name, code: state.athlete.country, value, isPlayer: true},
			...state.games.rivals.map(rival => ({name: countries[rival.code].rival, code: rival.code, value: rivalResult(id, rival.skill)})),
		];

		// The best first. On a tie, the athlete is first, for the home crowd.
		const ranked = competitors.toSorted((first, second) => {
			if (first.value === second.value) {
				return first.isPlayer ? -1 : (second.isPlayer ? 1 : 0);
			}

			return isBetter(id, first.value, second.value) ? -1 : 1;
		});

		const place = ranked.findIndex(competitor => competitor.isPlayer);
		// Each event gives its medals once in the Games: the podium of the best try of the athlete, so a try again can win a better medal, but not more medals.
		const best = state.games.best[id];
		if (value !== undefined && (best === undefined || place <= best)) {
			state.games.podiums ??= {};
			for (const [index, code] of (state.games.podiums[id] ?? []).entries()) {
				if (state.games.medals[code]?.[index] > 0) {
					state.games.medals[code][index]--;
				}
			}

			const podium = ranked.slice(0, 3).filter(competitor => competitor.value !== undefined).map(competitor => competitor.code);
			for (const [index, code] of podium.entries()) {
				state.games.medals[code] ??= [0, 0, 0];
				state.games.medals[code][index]++;
			}

			state.games.podiums[id] = podium;
			state.games.best[id] = place;
		}

		saveGames();
		element.store('mashes', state.mashes);
		const record = currentRecord(id);
		const isRecord = value !== undefined && isBetter(id, value, record.value);
		state.results = {id, ranked, place, value, summary, isRecord, hadFall, isMedal: place < 3 && value !== undefined};
		state.podiumStart = undefined;
		tune.stop();
		showResults();
		setScene('results');
		if (isRecord) {
			comment('record', `${formatResult(id, value)}!`);
			element.toast(`🏆 New world record in ${info.title}: ${formatResult(id, value)}!`);
		} else if (place === 0 && value !== undefined) {
			comment('gold', `${state.athlete.name} wins ${info.title}!`);
		} else if (state.results.isMedal) {
			comment('medal', `${medalNames[place]} for ${state.athlete.name}!`);
		} else {
			comment('none', `Place ${place + 1}.`);
		}

		if (place === 0 && value !== undefined) {
			element.celebrate();
			sound.crowd();
		}

		if (state.results.isMedal) {
			element.cheer();
		}
	};

	const showResults = () => {
		const {id, ranked, place, value, summary, isRecord, hadFall, isMedal} = state.results;
		const info = eventInfo[id];
		resultsTitle.textContent = `Results: ${info.title}`;
		resultsBody.replaceChildren(...ranked.map((competitor, index) => tableRow([index < 3 && competitor.value !== undefined ? medalEmoji[index] : `${index + 1}.`, `${competitor.name} (${competitor.code})${competitor.isPlayer ? ' ★ you' : ''}`, formatResult(id, competitor.value)], competitor.isPlayer)));

		let medalText = value === undefined ? 'You did not finish.' : `You are number ${place + 1} of 6.`;
		if (isMedal) {
			medalText = `You win ${medalNames[place]} ${medalEmoji[place]} for ${countries[state.athlete.country].name}!`;
		}

		// After a gold, the doping control. It always finds the same thing.
		const control = place === 0 && value !== undefined ? ' The doping control found traces of brown cheese. That is allowed.' : '';
		resultsNote.textContent = `${medalText} ${summary}${control}`;
		recordForm.hidden = !isRecord;
		recordInitials.value = state.athlete.initials;
		const interview = hadFall ? interviews.fall : (place === 0 && value !== undefined ? interviews.gold : (isMedal ? interviews.medal : interviews.none));
		state.interview = interview;
		questionLine.textContent = `🎤 «${interview.question[0]}» (${interview.question[1]})`;
		for (const button of interviewPanel.querySelectorAll('[data-winter-answer]')) {
			const [norwegian, english] = interview.answers[Number(button.dataset.winterAnswer)][0];
			button.textContent = `«${norwegian}» (${english})`;
			button.disabled = false;
		}

		replyLine.textContent = '';
		const nextId = state.queue[0];
		nextButton.textContent = nextId ? `Next: ${eventInfo[nextId].title}` : (state.isAll ? '🎆 To the Medal Table' : 'Try Again');
		replayButton.hidden = id !== 'skijump' || !element.stored('replay');
		anthemButton.textContent = '🔊 Play the Anthem';
		showPanel(resultsPanel, resultsTitle);
	};

	// The podium: the three best on their steps, and their flags, which go up during the anthem of the winner.
	const podiumDuration = () => {
		const winner = state.results?.ranked[0];
		if (!winner || !tune.isPlaying) {
			return 4;
		}

		const {anthem, tempo} = countries[winner.code];
		return parseMelody(anthem).beats * 60 / tempo;
	};

	const playAnthem = () => {
		const winner = state.results?.ranked[0];
		if (!winner) {
			return;
		}

		if (tune.isPlaying) {
			tune.stop();
			return;
		}

		setSound(true);
		const {anthem, tempo, name} = countries[winner.code];
		const isPlaying = tune.play(anthem, tempo, () => {
			anthemButton.textContent = '🔊 Play the Anthem';
		});
		if (isPlaying) {
			state.podiumStart = state.time;
			anthemButton.textContent = '⏹ Stop the Anthem';
			say(`🎺 The anthem of ${name}. Everybody stands up. ${winner.isPlayer ? 'You have tears in your eyes.' : `${winner.name} has tears in the eyes.`}`);
		}
	};

	const drawPodium = () => {
		drawSky('#0a1a3a', '#3a5a8a');
		drawMountains(0, 120, '#2a3a5a', 30);
		fillShape(context, '#e8eef6', 0, 150, width, 50);
		const {ranked} = state.results;
		const elapsed = state.podiumStart === undefined ? state.sceneTime - 2 : state.time - state.podiumStart;
		const rise = element.reducedMotion ? 1 : clamp(elapsed / podiumDuration(), 0, 1);
		const steps = [{index: 1, x: 105, height: 26}, {index: 0, x: 160, height: 38}, {index: 2, x: 215, height: 18}];
		for (const {index, x, height: stepHeight} of steps) {
			const competitor = ranked[index];
			// The flagpole and the flag, which rises.
			const poleX = x;
			strokeLine(context, '#cccccc', 1, [[poleX + 0.5, 40], [poleX + 0.5, 110]]);
			const flagY = 100 - ((index === 0 ? 58 : 46) * rise);
			drawFlag(context, competitor.code, poleX + 1, flagY, 22, 15);
			fillShape(context, '#f0f0f0', x - 26, 150 - stepHeight, 52, stepHeight);
			fillShape(context, '#c0c8d8', x - 26, 150 - stepHeight, 52, 2);
			drawText(context, String(index + 1), x, 150 - stepHeight + 6, ['#d4a017', '#9aa4b0', '#b06a30'][index], {scale: 3, align: 'center', shadow: ''});
			drawAthlete(context, competitor.code, x - 4, 150 - stepHeight, {size: 1.5});
			drawText(context, competitor.name.split(' ')[0], x, 156, competitor.isPlayer ? '#ba0c2f' : '#2a3a5a', {align: 'center', shadow: ''});
			drawText(context, competitor.code, x, 164, '#5a6a8a', {align: 'center', shadow: ''});
		}

		// The mascot of the athlete hops next to the podium on a medal.
		if (state.results.isMedal) {
			const hop = element.reducedMotion ? 0 : Math.abs(Math.sin(state.time * 6)) * 6;
			drawMascot(context, state.athlete.mascot, 270, 150, 2, {hop});
		}

		drawText(context, eventInfo[state.results.id].short, 160, 8, '#ffffff', {scale: 2, align: 'center'});
		drawText(context, 'VICTORY CEREMONY', 160, 24, '#ffee55', {align: 'center'});
		drawSnowfall(0.5);
	};

	// The scoreboard of the TV after an event, before the podium.
	const drawScoreboard = () => {
		drawSky('#00103a', '#002a6a');
		const {id, ranked} = state.results;
		drawText(context, eventInfo[id].short, 160, 10, '#ffee55', {scale: 2, align: 'center'});
		drawText(context, 'OFFICIAL RESULTS', 160, 26, '#ffffff', {align: 'center'});
		const shown = element.reducedMotion ? 6 : clamp(Math.floor(state.sceneTime * 4), 0, 6);
		for (const [index, competitor] of ranked.slice(0, shown).entries()) {
			const y = 40 + (index * 20);
			drawPanel(30, y - 2, 260, 17, competitor.isPlayer ? 'rgba(186, 12, 47, 0.8)' : 'rgba(255, 255, 255, 0.12)');
			drawText(context, String(index + 1), 40, y + 2, index < 3 && competitor.value !== undefined ? ['#ffd700', '#d0d8e0', '#e09050'][index] : '#ffffff', {scale: 2});
			drawFlag(context, competitor.code, 56, y + 1, 16, 11);
			drawText(context, competitor.name, 78, y + 4, '#ffffff');
			drawText(context, formatResult(id, competitor.value).replace(' points', ' P').replace(' of ', '/'), 284, y + 4, '#ffee55', {align: 'right'});
		}

		if (state.results.isRecord && isBlinkOn()) {
			drawText(context, 'WORLD RECORD!', 160, 168, '#ff4444', {scale: 3, align: 'center'});
		}
	};

	// Fireworks for the ceremonies: rockets that burst into sparks. With reduced motion, a few bursts stand still in the sky.
	const fireworks = [];
	const updateFireworks = seconds => {
		if (element.reducedMotion) {
			return;
		}

		if (Math.random() < seconds * 2.5) {
			const color = randomItem(['#ff4444', '#ffee55', '#66ccff', '#ff66cc', '#66ff88', '#ffffff']);
			const x = randomBetween(40, 280);
			const y = randomBetween(25, 80);
			for (let index = 0; index < 28; index++) {
				const angle = (index / 28) * Math.PI * 2;
				const speed = randomBetween(20, 45);
				fireworks.push({x, y, vx: Math.cos(angle) * speed, vy: Math.sin(angle) * speed, life: randomBetween(0.8, 1.4), color});
			}
		}

		for (const spark of fireworks) {
			spark.vy += 30 * seconds;
			spark.x += spark.vx * seconds;
			spark.y += spark.vy * seconds;
			spark.life -= seconds;
		}

		for (let index = fireworks.length - 1; index >= 0; index--) {
			if (fireworks[index].life <= 0) {
				fireworks.splice(index, 1);
			}
		}
	};

	const drawFireworks = () => {
		if (element.reducedMotion) {
			for (const [index, color] of ['#ff4444', '#ffee55', '#66ccff', '#ff66cc'].entries()) {
				const x = 60 + (index * 66);
				const y = 40 + ((index % 2) * 22);
				for (let ray = 0; ray < 12; ray++) {
					const angle = (ray / 12) * Math.PI * 2;
					fillShape(context, color, x + (Math.cos(angle) * 14), y + (Math.sin(angle) * 14), 2, 2);
				}
			}

			return;
		}

		for (const spark of fireworks) {
			context.globalAlpha = clamp(spark.life, 0, 1);
			fillShape(context, spark.color, spark.x, spark.y, 2, 2);
		}

		context.globalAlpha = 1;
	};

	// The stadium of the ceremonies, at the bottom of the ski jump of Lysgårdsbakken, at night, with the crowd and the cauldron.
	const drawStadium = ({flame = 0} = {}) => {
		drawSky('#050a1e', '#1a2a5a');
		for (let index = 0; index < 40; index++) {
			fillShape(context, '#ffffff', (index * 47) % width, (index * 23) % 70, 1, 1);
		}

		// The ski jump in the background.
		fillPolygon(context, '#2a3a5a', [[40, 120], [120, 30], [128, 30], [70, 120]]);
		strokeLine(context, '#e8eef6', 2, [[122, 30], [60, 110], [30, 140]]);
		// The stands, full of people.
		drawCrowd(0, 110, width, 40, {wave: flame > 0});

		fillShape(context, '#e8eef6', 0, 150, width, 50);
		// The cauldron on its tower, at the top of the stairs.
		fillShape(context, '#5a6a80', 268, 62, 6, 88);
		fillPolygon(context, '#8a96a8', [[256, 58], [286, 58], [280, 66], [262, 66]]);
		if (flame > 0) {
			const flicker = element.reducedMotion ? 0 : Math.sin(state.time * 20) * 2;
			fillPolygon(context, '#ff6600', [[258, 58], [284, 58], [271 + flicker, 58 - (22 * flame)]]);
			fillPolygon(context, '#ffcc00', [[263, 58], [279, 58], [271 - flicker, 58 - (13 * flame)]]);
		}

		// The stairs up to the cauldron.
		for (let step = 0; step < 20; step++) {
			fillShape(context, '#c0c8d8', 160 + (step * 5), 148 - (step * 4.5), 6, 3);
		}
	};

	const ceremonySteps = 20;

	const startCeremony = () => {
		state.ceremony = {phase: 'parade', step: 0, lastSide: undefined, flame: 0, runTime: 0};
		setActionLabel('GO');
		setScene('ceremony');
		showPanel(ceremonyPanel, canvas);
		showScreen();
		say('🎙️ «Velkommen til åpningsseremonien!» Welcome to the opening ceremony! Here come the nations.');
	};

	const finishCeremony = () => {
		state.ceremony = undefined;
		showMenu();
		comment('start', 'The Games are open! Pick an event.');
	};

	const drawCeremony = () => {
		const ceremony = state.ceremony;
		drawStadium({flame: ceremony.flame});
		if (ceremony.phase === 'parade') {
			// The nations march in, each behind its flag, the host nation last, as it should be.
			const order = Object.keys(countries).filter(code => code !== 'NOR');
			order.push('NOR');
			for (const [index, code] of order.entries()) {
				const x = element.reducedMotion ? 24 + (index * 34) : -30 + ((state.sceneTime * 40) - (index * 34));
				if (x < -30 || x > width + 10) {
					continue;
				}

				const pose = element.reducedMotion ? 0 : state.time * 8;
				drawAthlete(context, code, x, 170, {pose});
				strokeLine(context, '#dddddd', 1, [[x + 4.5, 152], [x + 4.5, 170]]);
				drawFlag(context, code, x + 5, 152, 14, 10);
			}

			drawText(context, 'THE PARADE OF NATIONS', 160, 182, '#00205b', {align: 'center', shadow: ''});
			if (isBlinkOn()) {
				drawText(context, 'PRESS GO TO CARRY THE TORCH', 160, 190, '#ba0c2f', {align: 'center', shadow: ''});
			}
		}

		if (ceremony.phase === 'torch' || ceremony.phase === 'light' || ceremony.phase === 'open') {
			const step = Math.min(ceremony.step, ceremonySteps - 1);
			const x = ceremony.phase === 'torch' && ceremony.step === 0 ? 150 : 160 + (step * 5) + 3;
			const y = ceremony.phase === 'torch' && ceremony.step === 0 ? 150 : 148 - (step * 4.5);
			const hop = !element.reducedMotion && ceremony.phase === 'open' ? Math.abs(Math.sin(state.time * 6)) * 4 : 0;
			drawMascot(context, state.athlete.mascot, x, y, 1.5, {torch: ceremony.phase !== 'open', hop});
			if (ceremony.phase === 'torch') {
				drawPanel(6, 6, 120, 20);
				drawText(context, `STEP ${ceremony.step}/${ceremonySteps}`, 10, 9, '#ffffff');
				drawText(context, `${ceremony.runTime.toFixed(1)} S`, 120, 9, '#ffee55', {align: 'right'});
				drawText(context, '< > < > FAST!', 10, 17, '#ffee55');
			}

			if (ceremony.phase === 'light' && isBlinkOn()) {
				drawText(context, 'PRESS GO TO LIGHT THE FLAME!', 160, 182, '#ba0c2f', {align: 'center', shadow: ''});
			}

			if (ceremony.phase === 'open') {
				drawFireworks();
				drawText(context, 'THE GAMES ARE OPEN!', 160, 84, '#ffee55', {scale: 2, align: 'center'});
				drawText(context, `TORCH RUN: ${ceremony.runTime.toFixed(1)} S`, 160, 102, '#ffffff', {align: 'center'});
			}
		}
	};

	const stepCeremony = seconds => {
		const ceremony = state.ceremony;
		if (ceremony.phase === 'parade' && !element.reducedMotion && state.sceneTime > 9.5) {
			ceremony.phase = 'torch';
		}

		if (ceremony.phase === 'torch' && ceremony.step > 0) {
			ceremony.runTime += seconds;
		}

		if (ceremony.phase === 'open') {
			ceremony.flame = element.reducedMotion ? 1 : Math.min(1, ceremony.flame + seconds);
			updateFireworks(seconds);
		}
	};

	const pressCeremony = control => {
		const ceremony = state.ceremony;
		if (ceremony.phase === 'parade' && control === 'action') {
			ceremony.phase = 'torch';
			say('🎙️ «Her kommer fakkelen!» Here comes the torch! Run up the stairs with ◀ ▶ ◀ ▶.');
			return;
		}

		if (ceremony.phase === 'torch' && (control === 'left' || control === 'right') && control !== ceremony.lastSide) {
			ceremony.lastSide = control;
			ceremony.step++;
			sound.beep(300 + (ceremony.step * 30), 0.04);
			if (ceremony.step >= ceremonySteps) {
				ceremony.phase = 'light';
				setActionLabel('LIGHT');
				say(`🎙️ «Opp på toppen!» At the top in ${ceremony.runTime.toFixed(1)} seconds! Now light the flame.`);
			}

			return;
		}

		if (ceremony.phase === 'light' && control === 'action') {
			ceremony.phase = 'open';
			ceremony.openTime = state.sceneTime;
			ceremony.flame = 0.1;
			sound.fanfare();
			sound.crowd();
			say('🎙️ «Flammen er tent! Lekene er åpnet!» The flame is lit! The Games are open! Press GO to go to the events.');
			// Glitter cheers, but there is no card cascade of Solitaire, as it would take the next press of the visitor.
			element.cheer();
			return;
		}

		if (ceremony.phase === 'open' && control === 'action' && state.sceneTime - ceremony.openTime > 1) {
			finishCeremony();
		}
	};

	// The closing ceremony: fireworks, all the flags, and the medals of the athlete.
	const drawClosing = () => {
		drawStadium({flame: 1});
		drawFireworks();
		for (const [index, code] of Object.keys(countries).entries()) {
			drawFlag(context, code, 18 + (index * 37), 166, 22, 15);
		}

		const medals = state.games.medals[state.athlete.country] ?? [0, 0, 0];
		drawText(context, 'HA DET BRA!', 160, 70, '#ffee55', {scale: 3, align: 'center'});
		drawText(context, 'SEE YOU IN SALT LAKE CITY 2002', 160, 92, '#ffffff', {align: 'center'});
		drawText(context, `${countries[state.athlete.country].name}: ${medals[0]} GOLD, ${medals[1]} SILVER, ${medals[2]} BRONZE`, 160, 104, '#66ff88', {align: 'center'});
	};

	// The title screen, before the visitor signs up.
	const drawTitle = () => {
		drawSky('#0a1a4a', '#6a8ac8');
		drawMountains(state.time * (element.reducedMotion ? 0 : 4), 140, '#c8d4e8', 50);
		drawMountains(state.time * (element.reducedMotion ? 0 : 9) + 100, 165, '#e8eef6', 26);
		fillShape(context, '#ffffff', 0, 170, width, 30);
		drawText(context, 'SINDRE’S', 160, 22, '#ffee55', {scale: 2, align: 'center'});
		drawText(context, 'WINTER', 160, 40, '#ffffff', {scale: 5, align: 'center'});
		drawText(context, 'GAMES ’99', 160, 70, '#ffffff', {scale: 5, align: 'center'});
		drawWaffleRings(160, 112, 1.4);
		if (isBlinkOn(0.6)) {
			drawText(context, state.athlete ? 'PICK AN EVENT BELOW' : 'SIGN UP BELOW TO START', 160, 182, '#ba0c2f', {scale: 1, align: 'center', shadow: ''});
		}

		drawSnowfall(0.7, 0.3);
	};

	// The board of the events, with the best medal of each.
	const drawMenu = () => {
		drawSky('#00103a', '#002a6a');
		drawText(context, 'WINTER GAMES ’99', 160, 8, '#ffee55', {scale: 2, align: 'center'});
		drawFlag(context, state.athlete.country, 12, 6, 22, 15);
		drawMascot(context, state.athlete.mascot, 296, 22, 1.2);
		for (const [index, id] of eventIds.entries()) {
			const y = 32 + (index * 19);
			const best = state.games.best[id];
			drawPanel(30, y - 2, 260, 16, state.queue[0] === id ? 'rgba(186, 12, 47, 0.8)' : 'rgba(255, 255, 255, 0.12)');
			drawText(context, eventInfo[id].short, 40, y + 3, '#ffffff');
			drawText(context, eventInfo[id].place.toUpperCase(), 180, y + 3, '#8aa0c8');
			if (best !== undefined && best < 3) {
				fillEllipse(context, ['#ffd700', '#d0d8e0', '#e09050'][best], 278, y + 5, 5, 5);
				drawText(context, String(best + 1), 278, y + 3, '#000000', {align: 'center', shadow: ''});
			}
		}

		drawSnowfall(0.3);
	};

	const showMenu = (focus = true) => {
		const athlete = state.athlete;
		const medals = state.games.medals[athlete.country] ?? [0, 0, 0];
		athleteLine.textContent = `${athlete.name} (${athlete.initials}) for ${countries[athlete.country].name}, with ${[...registerForm.querySelectorAll('input[type="radio"]')].find(input => input.value === athlete.mascot)?.parentElement.textContent.trim() ?? 'a mascot'}. Medals so far: ${medals[0]} gold, ${medals[1]} silver, ${medals[2]} bronze.`;
		for (const id of eventIds) {
			const best = state.games.best[id];
			menuPanel.querySelector(`[data-winter-medal="${id}"]`).textContent = best === undefined ? '' : (best < 3 ? `${medalEmoji[best]} ${medalNames[best]}` : `Best place: ${best + 1}`);
		}

		state.isAll = false;
		state.queue = [];
		tune.stop();
		setActionLabel('GO');
		setScene('menu');
		showPanel(menuPanel, focus ? undefined : false);
	};

	// How to play an event: the text below the screen, and the event on the screen, ready to start.
	const showHowTo = id => {
		tune.stop();
		state.eventId = id;
		state.weather = makeWeather(id);
		state.run = events[id](state.weather);
		howToTitle.textContent = `${eventInfo[id].title}: How to Play`;
		for (const text of howToPanel.querySelectorAll('[data-winter-howto]')) {
			text.hidden = text.dataset.winterHowto !== id;
		}

		weatherLine.textContent = `${state.weather.text}${element.reducedMotion ? ' AS YOUR COMPUTER PREFERS LESS MOTION, THE EVENT ONLY MOVES WHILE YOU PRESS THE CONTROLS.' : ''}`;
		setActionLabel(eventInfo[id].action);
		setScene('howto');
		showPanel(howToPanel, howToTitle);
		say(`🎙️ ${state.weather.spoken}`);
	};

	const startEvent = () => {
		if (state.scene !== 'howto') {
			return;
		}

		state.lastInput = state.time;
		tipLine.textContent = state.run.tip;
		setScene('event');
		showPanel(playingPanel, canvas);
		showScreen();
		sound.countdown();
	};

	const quitEvent = () => {
		if (state.scene !== 'event') {
			return;
		}

		showHowTo(state.eventId);
		say(`🎙️ «Brutt!» Did not finish. Try again? ${state.weather.spoken}`);
	};

	const startNextEvent = () => {
		const nextId = state.queue.shift();
		if (nextId) {
			showHowTo(nextId);
		} else if (state.isAll) {
			state.isAll = false;
			showMedals();
		} else {
			showHowTo(state.eventId);
		}
	};

	const showRecords = () => {
		recordsBody.replaceChildren(...eventIds.map(id => {
			const record = currentRecord(id);
			return tableRow([eventInfo[id].title, formatResult(id, record.value), `${record.initials} (${record.country})${record.isRival ? '' : ' ★'}`], !record.isRival);
		}));
		recordsReplayButton.hidden = !element.stored('replay');
		setScene('records');
		showPanel(recordsPanel);
	};

	const drawRecords = () => {
		drawSky('#1a0a3a', '#3a1a6a');
		drawText(context, 'WORLD RECORDS', 160, 8, '#ffee55', {scale: 2, align: 'center'});
		for (const [index, id] of eventIds.entries()) {
			const record = currentRecord(id);
			const y = 30 + (index * 20);
			drawText(context, eventInfo[id].short, 20, y, '#ffffff');
			drawText(context, formatResult(id, record.value).replace(' points', ' P').replace(' of ', '/'), 210, y, '#66ff88', {align: 'right'});
			drawText(context, record.initials, 250, y, record.isRival ? '#ffffff' : '#ffee55', {scale: 1});
			drawFlag(context, record.country, 280, y - 2, 13, 9);
		}

		drawSnowfall(0.3);
	};

	const medalRows = () => {
		const codes = new Set([state.athlete.country, ...state.games.rivals.map(rival => rival.code), ...Object.keys(state.games.medals)]);
		return [...codes]
			.map(code => {
				const [gold, silver, bronze] = state.games.medals[code] ?? [0, 0, 0];
				return {code, gold, silver, bronze, total: gold + silver + bronze};
			})
			.toSorted((first, second) => (second.gold - first.gold) || (second.silver - first.silver) || (second.bronze - first.bronze) || (second.total - first.total));
	};

	const showMedals = () => {
		const done = Object.keys(state.games.best).length;
		medalsNote.textContent = `${done} of ${eventIds.length} events done in these Games. Each event gives its medals once, for your best try. Countries are ordered by gold, then silver, then bronze.`;
		medalsBody.replaceChildren(...medalRows().map(row => tableRow([`${countries[row.code].name}${row.code === state.athlete.country ? ' ★' : ''}`, row.gold, row.silver, row.bronze, row.total], row.code === state.athlete.country)));
		setScene('medals');
		showPanel(medalsPanel);
	};

	const drawMedalTable = () => {
		drawSky('#00103a', '#002a6a');
		drawText(context, 'MEDAL TABLE', 160, 8, '#ffee55', {scale: 2, align: 'center'});
		for (const [index, medal] of ['#ffd700', '#d0d8e0', '#e09050'].entries()) {
			fillEllipse(context, medal, 200 + (index * 30), 34, 5, 5);
		}

		drawText(context, 'TOTAL', 290, 32, '#ffffff', {align: 'center'});
		for (const [index, row] of medalRows().slice(0, 7).entries()) {
			const y = 46 + (index * 20);
			drawPanel(14, y - 3, 292, 16, row.code === state.athlete.country ? 'rgba(186, 12, 47, 0.8)' : 'rgba(255, 255, 255, 0.12)');
			drawText(context, String(index + 1), 22, y + 2, '#ffffff');
			drawFlag(context, row.code, 34, y, 16, 11);
			drawText(context, countries[row.code].name, 56, y + 2, '#ffffff');
			for (const [column, count] of [row.gold, row.silver, row.bronze].entries()) {
				drawText(context, String(count), 200 + (column * 30), y + 2, '#ffee55', {align: 'center'});
			}

			drawText(context, String(row.total), 290, y + 2, '#66ff88', {align: 'center'});
		}
	};

	// The replay of the best jump, in slow motion, like on TV.
	const startReplay = () => {
		const replay = element.stored('replay');
		if (state.scene === 'replay') {
			return;
		}

		if (!Array.isArray(replay?.frames) || replay.frames.length === 0 || !replay.frames.every(frame => Array.isArray(frame) && frame.length === 4 && frame.every(Number.isFinite))) {
			return;
		}

		// The replay starts a second before the takeoff, as the inrun is the same every time.
		const takeoff = replay.frames.findIndex(frame => frame[3] >= 2);
		state.replay = {...replay, frames: replay.frames.slice(Math.max(0, takeoff - 60)), returnScene: state.scene};
		setScene('replay');
		showScreen();
		say(`📼 The replay of your best jump: ${replay.distance} meters, ${replay.points} points. In slow motion, like on TV.`);
	};

	const drawReplay = () => {
		const {frames, distance, points, wind} = state.replay;
		const index = element.reducedMotion ? frames.length - 1 : clamp(Math.floor(state.sceneTime * 40), 0, frames.length - 1);
		const [x, y, alpha, code] = frames[index];
		drawJumpScene({x, y, alpha, phase: code <= 1 ? 'inrun' : (code === 2 ? 'flight' : 'landed'), crouch: code === 1, telemark: code === 3, fallen: code === 4, wind: Number(wind) || 0});
		drawPanel(222, 4, 94, 20);
		drawText(context, 'REPLAY', 226, 7, isBlinkOn() ? '#ff4444' : '#ffffff');
		drawText(context, `${distance} M`, 312, 15, '#ffffff', {align: 'right'});
		if (index === frames.length - 1) {
			drawText(context, `${points} POINTS`, 160, 60, '#66ff88', {scale: 2, align: 'center'});
			drawText(context, 'PRESS GO', 160, 78, '#ffffff', {align: 'center'});
		}
	};

	const endReplay = () => {
		const scene = state.replay.returnScene;
		state.replay = undefined;
		setScene(scene);
	};

	const scenes = {
		title: {draw: drawTitle},
		ceremony: {draw: drawCeremony, step: stepCeremony},
		menu: {draw: drawMenu},
		howto: {draw: () => state.run.draw()},
		event: {draw: () => state.run.draw()},
		results: {
			draw() {
				if (state.sceneTime < 3 && !element.reducedMotion) {
					drawScoreboard();
				} else {
					drawPodium();
				}
			},
			step() {
				// The anthem plays by itself at the podium when the visitor has turned on the sound.
				if (state.sceneTime >= 3 && state.podiumStart === undefined && sound.isOn && !tune.isPlaying && !state.results.hasPlayedAnthem) {
					state.results.hasPlayedAnthem = true;
					playAnthem();
				}
			},
		},
		records: {draw: drawRecords},
		medals: {draw: drawMedalTable},
		replay: {draw: drawReplay},
		closing: {draw: drawClosing, step: updateFireworks},
	};

	const draw = () => {
		context.save();
		scenes[state.scene].draw();
		context.restore();
		if (state.scene === 'event' && isPaused()) {
			drawPanel(80, 92, 160, 16);
			drawText(context, 'PRESS A CONTROL TO GO ON', 160, 97, '#ffffff', {align: 'center'});
		}
	};

	// With reduced motion, an event only moves while the visitor presses the controls, unless it waits for something that happens by itself, like the gun.
	const isPaused = () => element.reducedMotion && state.scene === 'event' && !state.run.isWaiting && !Object.values(state.held).some(Boolean) && state.time - state.lastInput > 0.8;

	const step = seconds => {
		state.time += seconds;
		state.sceneTime += seconds;
		if (state.scene === 'event') {
			if (!isPaused()) {
				state.run.step(seconds);
				if (tipLine.textContent !== state.run.tip) {
					tipLine.textContent = state.run.tip;
				}
			}
		} else {
			scenes[state.scene].step?.(seconds);
		}

		if (state.scene === 'replay' && state.sceneTime * 40 > state.replay.frames.length + 80 && !element.reducedMotion) {
			endReplay();
		}

		draw();
	};

	// The loop runs while the screen is on the screen and the tab is visible. With reduced motion, it only runs during an event and the ceremony, and the other scenes are drawn once, standing still.
	const loop = element.loop(step, {
		while: () => !element.reducedMotion || (state.scene === 'event' && !isPaused()) || state.scene === 'ceremony',
		maximumStep: 0.05,
	});

	const setScene = scene => {
		state.scene = scene;
		state.sceneTime = 0;
		quitButton.hidden = scene !== 'event';
		loop.start();
		draw();
	};

	const setSound = isOn => {
		sound.isOn = isOn;
		if (isOn) {
			sound.start();
		} else {
			tune.stop();
		}

		soundButton.textContent = isOn ? '🔊 Sound On' : '🔇 Sound Off';
		soundButton.setAttribute('aria-pressed', String(isOn));
	};

	// The controls: the arrow keys and Space or Enter on the screen, and the buttons below it for touch.
	const press = control => {
		if (state.held[control]) {
			return;
		}

		state.held[control] = true;
		state.lastInput = state.time;
		if (state.scene === 'event') {
			state.mashes++;
			if (state.mashes % 25 === 0) {
				showWear();
			}

			state.run.press?.(control);
		} else if (state.scene === 'ceremony') {
			state.mashes++;
			pressCeremony(control);
		} else if (state.scene === 'howto' && control === 'action') {
			startEvent();
		} else if (state.scene === 'replay' && control === 'action') {
			endReplay();
		} else if (state.scene === 'closing' && control === 'action') {
			showMedals();
		}

		loop.start();
		if (element.reducedMotion) {
			draw();
		}
	};

	const release = control => {
		if (!state.held[control]) {
			return;
		}

		state.held[control] = false;
		state.lastInput = state.time;
		if (state.scene === 'event') {
			state.run.release?.(control);
		}
	};

	const releaseAll = () => {
		for (const control of Object.keys(state.held)) {
			release(control);
		}
	};

	const keyControls = {ArrowLeft: 'left', ArrowRight: 'right', ArrowUp: 'up', ArrowDown: 'down', ' ': 'action', Enter: 'action'};

	element.on(canvas, 'keydown', event => {
		if (event.ctrlKey || event.metaKey || event.altKey) {
			return;
		}

		if (event.key === 'Escape' && state.scene === 'event') {
			event.preventDefault();
			quitEvent();
			return;
		}

		const control = keyControls[event.key];
		if (!control) {
			return;
		}

		event.preventDefault();
		if (!event.repeat) {
			press(control);
		}
	});

	element.on(canvas, 'keyup', event => {
		const control = keyControls[event.key];
		if (control) {
			release(control);
		}
	});

	element.on(canvas, 'blur', releaseAll);

	for (const button of element.querySelectorAll('[data-winter-control]')) {
		const control = button.dataset.winterControl;
		element.on(button, 'pointerdown', event => {
			if (event.button !== 0) {
				return;
			}

			event.preventDefault();
			button.setPointerCapture(event.pointerId);
			press(control);
		});

		for (const type of ['pointerup', 'pointercancel', 'lostpointercapture']) {
			element.on(button, type, () => {
				release(control);
			});
		}

		// A click without a pointer, like from a screen reader, is a press and a release.
		element.on(button, 'click', event => {
			if (event.detail === 0) {
				press(control);
				release(control);
			}
		});

		// A press of the button keeps the focus where it is, so the keys still work on the screen.
		element.on(button, 'mousedown', event => {
			event.preventDefault();
		});

		element.on(button, 'contextmenu', event => {
			event.preventDefault();
		});
	}

	element.on(soundButton, 'click', () => {
		setSound(!sound.isOn);
		if (sound.isOn) {
			sound.fanfare();
		}
	});

	element.on(quitButton, 'click', quitEvent);

	element.on(registerForm, 'submit', event => {
		event.preventDefault();
		const name = nameField.value.trim().slice(0, 14) || 'Sindre';
		const initials = (initialsField.value.trim().toUpperCase().replaceAll(/[^A-ZÆØÅ]/g, '') || name.toUpperCase().replaceAll(/[^A-ZÆØÅ]/g, '') || 'AAA').padEnd(3, 'A').slice(0, 3);
		const form = new FormData(registerForm);
		const country = Object.hasOwn(countries, form.get('geocities-winter-country')) ? form.get('geocities-winter-country') : 'NOR';
		const mascot = String(form.get('geocities-winter-mascot') ?? 'unicorn');
		state.athlete = {name, initials, country, mascot};
		element.store('athlete', state.athlete);
		state.games = makeGames();
		saveGames();
		startCeremony();
	});

	element.on(skipButton, 'click', finishCeremony);

	for (const button of menuPanel.querySelectorAll('[data-winter-event]')) {
		element.on(button, 'click', () => {
			state.isAll = false;
			state.queue = [];
			showHowTo(button.dataset.winterEvent);
		});
	}

	element.on(allButton, 'click', () => {
		state.isAll = true;
		state.queue = [...eventIds];
		showHowTo(state.queue.shift());
	});

	element.on(startButton, 'click', startEvent);

	for (const button of element.querySelectorAll('[data-part="back"]')) {
		element.on(button, 'click', () => {
			showMenu();
		});
	}

	element.on(nextButton, 'click', startNextEvent);
	element.on(anthemButton, 'click', playAnthem);
	element.on(replayButton, 'click', startReplay);
	element.on(recordsReplayButton, 'click', startReplay);
	element.on(showRecordsButton, 'click', showRecords);
	element.on(showMedalsButton, 'click', showMedals);

	element.on(newAthleteButton, 'click', () => {
		nameField.value = state.athlete.name;
		initialsField.value = state.athlete.initials;
		setScene('title');
		showPanel(registerForm, nameField);
		say('Sign up again for new Games. The medal table starts over, but the world records stay.');
	});

	element.on(recordForm, 'submit', event => {
		event.preventDefault();
		const {id, value} = state.results;
		const initials = (recordInitials.value.trim().toUpperCase().replaceAll(/[^A-ZÆØÅ]/g, '') || state.athlete.initials).padEnd(3, 'A').slice(0, 3);
		state.records[id] = {value, initials, country: state.athlete.country};
		element.store('records', state.records);
		recordForm.hidden = true;
		nextButton.focus();
		say(`🏆 The record is saved: ${initials}, ${formatResult(id, value)}. It stays on this computer forever.`);
	});

	for (const button of interviewPanel.querySelectorAll('[data-winter-answer]')) {
		element.on(button, 'click', () => {
			const [, reply] = state.interview.answers[Number(button.dataset.winterAnswer)];
			element.say(`🎤 «${reply[0]}» (${reply[1]})`, replyLine);
		});
	}

	element.on(clearButton, 'click', () => {
		state.records = {};
		element.store('records', state.records);
		element.store('replay', undefined);
		element.store('ghost', undefined);

		showRecords();
		say('Your records, the ghost, and the replay are gone. The rivals hold all the records again.');
	});

	element.on(closingButton, 'click', () => {
		setScene('closing');
		showScreen();
		sound.fanfare();
		element.celebrate();
		say('🎆 «Takk for nå, og ha det bra!» Thank you, and goodbye! See you in Salt Lake City in 2002.');
	});

	element.on(newGamesButton, 'click', () => {
		state.games = makeGames();
		saveGames();
		showMenu();
		say('New Games! The medal table is empty, and there are new rivals. The world records stay.');
	});

	// The flags of the countries in the sign-up form.
	for (const flag of registerForm.querySelectorAll('[data-winter-flag]')) {
		drawFlag(flag.getContext('2d'), flag.dataset.winterFlag, 0, 0, flag.width, flag.height);
	}

	showWear();
	if (state.athlete) {
		nameField.value = state.athlete.name;
		initialsField.value = state.athlete.initials;
		for (const input of registerForm.querySelectorAll('input[type="radio"]')) {
			if (input.value === state.athlete.country || input.value === state.athlete.mascot) {
				input.checked = true;
			}
		}
	}

	if (state.athlete && state.games) {
		showMenu(false);
		say(`Welcome back, ${state.athlete.name}! Pick an event, or compete in all of them.`);
	} else {
		setScene('title');
	}

	return {draw, tune};
};

export default class extends GeoCitiesElement {
	#games;

	// The Games run only while the screen is on the screen, not while only the parts below it are.
	get visibilityTarget() {
		return this.parts.screen;
	}

	connected() {
		this.#games = setUpGames(this, this.parts);
	}

	// A tune plays on while the Games are off the screen, so it stops when they are removed.
	disconnected() {
		this.#games.tune.stop();
	}

	reducedMotionChanged() {
		this.#games.draw();
	}

	musicStopped() {
		this.#games.tune.stop();
	}
}
