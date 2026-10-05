// Taipei on the desktop of the 1999 page, the mahjong solitaire of the Microsoft Entertainment Pack (Dave Norris, 1990): the tiles of a mahjong set lie in layers, and the visitor takes them off in matching pairs. A tile is free when no tile lies on it, and its left or right side is open. Every deal is built backwards from an empty table, so it always has a solution. Nothing makes a sound until the visitor turns on the sound, and with reduced motion, nothing moves by itself.

const randomItem = items => items[Math.floor(Math.random() * items.length)];

// A place of a tile is in half tiles, so tiles can sit half a tile apart, like the ends of the turtle. The tile covers two half tiles both ways from its place.
const block = (z, columns, rows) => {
	const places = [];

	for (const y of rows) {
		for (const x of columns) {
			places.push({x, y, z});
		}
	}

	return places;
};

const range = (from, to) => {
	const values = [];

	for (let value = from; value <= to; value += 2) {
		values.push(value);
	}

	return values;
};

// The layouts of the Layout menu of Taipei. The turtle is the classic one, with all 144 tiles. The others are smaller and use fewer pairs of the set.
const layouts = {
	standard: {
		name: 'Turtle',
		places: () => [
			...block(0, range(2, 24), [0, 6, 8, 14]),
			...block(0, range(6, 20), [2, 12]),
			...block(0, range(4, 22), [4, 10]),
			{x: 0, y: 7, z: 0},
			{x: 26, y: 7, z: 0},
			{x: 28, y: 7, z: 0},
			...block(1, range(8, 18), range(2, 12)),
			...block(2, range(10, 16), range(4, 10)),
			...block(3, range(12, 14), range(6, 8)),
			{x: 13, y: 7, z: 4},
		],
	},
	bridge: {
		name: 'Bridge',
		places: () => [
			...block(0, [0, 2, 4, 24, 26, 28], range(0, 14)),
			...block(0, range(6, 22), [6, 8]),
			...block(1, [0, 2, 4, 24, 26, 28], range(2, 12)),
			...block(1, range(8, 20), [6, 8]),
			...block(2, [1, 3, 25, 27], range(3, 11)),
			...block(3, [2, 26], [5, 7, 9]),
		],
	},
	castle: {
		name: 'Castle',
		places: () => [
			...block(0, range(2, 26), [0, 14]),
			...block(0, [2, 26], range(2, 12)),
			...block(0, [4, 24], [2, 12]),
			...block(0, range(10, 18), range(4, 10)),
			...block(1, [2, 4, 24, 26], [0, 2, 12, 14]),
			...block(2, [3, 25], [1, 13]),
			...block(1, [14], [0, 14]),
			...block(1, [2, 26], [7]),
			...block(1, [11, 13, 15, 17], [5, 7, 9]),
			...block(2, [12, 14, 16], [6, 8]),
			...block(3, [13, 15], [7]),
		],
	},
	pyramid: {
		name: 'Pyramid',
		places: () => [
			...block(0, range(6, 22), range(1, 13)),
			...block(1, range(8, 20), range(3, 11)),
			...block(2, range(10, 18), range(5, 9)),
			...block(3, range(12, 16), [7]),
		],
	},
	cube: {
		name: 'Cube',
		places: () => [0, 1, 2].flatMap(z => block(z, range(7, 21), range(2, 12))),
	},
};

// The kinds of tiles: 0 to 8 are the characters, 9 to 17 the bamboos, 18 to 26 the circles, 27 to 30 the winds, 31 to 33 the dragons, 34 to 37 the flowers, and 38 to 41 the seasons. There are four tiles of each kind, and one of each flower and season.
const matchGroup = kind => (kind < 34 ? kind : (kind < 38 ? 34 : 35));

// The 72 pairs of the full set. Any flower matches any flower, and any season any season.
const allPairs = () => {
	const pairs = [];

	for (let kind = 0; kind < 34; kind++) {
		pairs.push([kind, kind], [kind, kind]);
	}

	pairs.push([34, 35], [36, 37], [38, 39], [40, 41]);
	return pairs;
};

// A small random generator with a seed, so a game number deals the same game again.
const seededRandom = seed => {
	let state = seed >>> 0;

	return () => {
		state = (state + 0x6D_2B_79_F5) >>> 0;
		let value = state;
		value = Math.imul(value ^ (value >>> 15), value | 1);
		value ^= value + Math.imul(value ^ (value >>> 7), value | 61);
		return ((value ^ (value >>> 14)) >>> 0) / 4_294_967_296;
	};
};

const shuffle = (items, random = Math.random) => {
	for (let index = items.length - 1; index > 0; index--) {
		const other = Math.floor(random() * (index + 1));
		[items[index], items[other]] = [items[other], items[index]];
	}

	return items;
};

// The neighbors of each place: the tiles that touch it on the left and the right in its layer, and the tiles that lie on it, or under it, in other layers.
const neighborsOf = places => places.map(place => {
	const neighbors = {left: [], right: [], above: [], below: []};

	for (const [index, other] of places.entries()) {
		const overlapsRows = Math.abs(other.y - place.y) < 2;

		if (other.z === place.z && overlapsRows && other.x === place.x - 2) {
			neighbors.left.push(index);
		} else if (other.z === place.z && overlapsRows && other.x === place.x + 2) {
			neighbors.right.push(index);
		} else if (other.z !== place.z && overlapsRows && Math.abs(other.x - place.x) < 2) {
			neighbors[other.z > place.z ? 'above' : 'below'].push(index);
		}
	}

	return neighbors;
});

// A tile is free when nothing lies on it, and nothing touches it on the left or on the right.
const isFreeIn = (neighbors, index, isThere) => {
	const {left, right, above} = neighbors[index];
	return !above.some(other => isThere[other]) && (!left.some(other => isThere[other]) || !right.some(other => isThere[other]));
};

// A deal is built backwards, from an empty table: pairs are put down where both tiles would be free, so taking them off in the opposite order always solves the game. A place is used only when the tiles under it are there, and never where it would shut in an empty place between two tiles, which could then never be filled. The order of the pairs is the build that Watch Builds shows. A place that is undefined is not part of the build, for a shuffle of the tiles that are left.
const buildOrder = (neighbors, places, random) => {
	for (let attempt = 0; attempt < 40; attempt++) {
		const isThere = places.map(() => false);
		const order = [];
		let left = places.filter(place => place !== undefined).length;

		// An empty place can still be filled later while a row of empty places leads from it to an end of the row, on one side.
		const isOpen = (index, side) => neighbors[index][side].every(other => places[other] === undefined || (!isThere[other] && isOpen(other, side)));

		// The empty places in the rows next to a tile, which the tile could shut in.
		const emptyRowsNextTo = index => {
			const found = new Set();
			const stack = [...neighbors[index].left, ...neighbors[index].right];

			while (stack.length > 0) {
				const other = stack.pop();

				if (places[other] !== undefined && !isThere[other] && !found.has(other)) {
					found.add(other);
					stack.push(...neighbors[other].left, ...neighbors[other].right);
				}
			}

			return found;
		};

		const canPut = index => {
			if (isThere[index] || places[index] === undefined || neighbors[index].below.some(other => places[other] !== undefined && !isThere[other])) {
				return false;
			}

			isThere[index] = true;
			const isGood = isFreeIn(neighbors, index, isThere) && [...emptyRowsNextTo(index)].every(other => isOpen(other, 'left') || isOpen(other, 'right'));
			isThere[index] = false;
			return isGood;
		};

		const puttable = () => shuffle(places.flatMap((_, index) => (canPut(index) ? [index] : [])), random);

		while (left > 0) {
			let pair;

			for (const first of puttable()) {
				isThere[first] = true;
				const second = puttable().find(index => {
					isThere[index] = true;
					const isGood = isFreeIn(neighbors, first, isThere);
					isThere[index] = false;
					return isGood;
				});
				isThere[first] = false;

				if (second !== undefined) {
					pair = [first, second];
					break;
				}
			}

			if (!pair) {
				break;
			}

			for (const index of pair) {
				isThere[index] = true;
			}

			order.push(pair);
			left -= 2;
		}

		if (left === 0) {
			return order;
		}
	}

	return undefined;
};

// The canvas has two pixels for each pixel of the table. The size of a tile on the table, and how far each layer sits up and to the left of the one under it, which is also the thickness of a tile.
const pixelRatio = 2;
const tileWidth = 36;
const tileHeight = 46;
const depth = 6;

const facePosition = place => ({
	x: (place.x * tileWidth / 2) - (place.z * depth),
	y: (place.y * tileHeight / 2) - (place.z * depth),
});

// The names of the tiles, for the status line.
const suitNames = ['Characters', 'Bamboo', 'Circles'];
const windNames = ['East', 'South', 'West', 'North'];
const dragonNames = ['Red', 'Green', 'White'];
const flowerNames = ['Plum', 'Orchid', 'Chrysanthemum', 'Bamboo'];
const seasonNames = ['Spring', 'Summer', 'Autumn', 'Winter'];

const tileName = kind => {
	if (kind < 27) {
		return `${(kind % 9) + 1} of ${suitNames[Math.floor(kind / 9)]}`;
	}

	if (kind < 31) {
		return `${windNames[kind - 27]} Wind`;
	}

	if (kind < 34) {
		return `${dragonNames[kind - 31]} Dragon`;
	}

	if (kind < 38) {
		return `${flowerNames[kind - 34]} (a flower)`;
	}

	return `${seasonNames[kind - 38]} (a season)`;
};

const groupName = kind => {
	if (matchGroup(kind) === 34) {
		return 'flowers';
	}

	if (matchGroup(kind) === 35) {
		return 'seasons';
	}

	return `${tileName(kind)} tiles`;
};

// What the family says while I play, once in each game, as the tiles go.
const milestones = [
	{share: 0.75, lines: ['A quarter done! Mormor asks if this is Chinese checkers. It is not, Mormor.', 'A quarter done! Rocky the pet rock watches. He believes in you.']},
	{share: 0.5, lines: ['Halfway! Lillesøster wants the computer now. Not yet!', 'Halfway! Mamma calls that the waffles are ready. Two more pairs…']},
	{share: 0.15, lines: ['Almost there! Trond says that he once did it in two minutes. Trond lies.', 'Almost there! Pappa stopped reading Bergens Tidende to watch.']},
];

const winLines = [
	'Mamma says: “Flink gutt!” (Good boy!) Now go to bed.',
	'Lillesøster says that she could do it faster. She cannot.',
	'Mormor says that this calls for waffles with brunost.',
	'Trond is calling on the phone to hear about it. Which means no Internet tonight.',
];

const walkBys = [
	'Mamma walks by: “Så flink du er! (How clever you are!) Are you helping Pappa with the budget?”',
	'Pappa walks by and stops at row 4. “SINDRE. Two thousand eight hundred and seventy kroner?!”',
	'Lillesøster walks by: “I KNOW you were playing the tile game. I am telling.”',
	'Mormor walks by with waffles. She does not ask any questions.',
	'Trond walks by and whispers: “Nice boss key.”',
	'Rocky the pet rock sees everything. He says nothing.',
];

// A stored record that is broken counts as none.
const isCount = value => Number.isInteger(value) && value >= 0;

const clockText = seconds => `${Math.floor(seconds / 60)}:${String(seconds % 60).padStart(2, '0')}`;

// The tunes use the five notes of the pentatonic scale, which sound like the Far East to a kid in Bergen.
const pentatonic = [523, 587, 659, 784, 880, 1047, 1175, 1319];

// The faces of the tiles, drawn in the space of a tile, from its top left corner.
const cjkFont = size => `bold ${size}px "MS Mincho", SimSun, "Songti SC", STSong, "Hiragino Mincho ProN", "Noto Serif CJK SC", "Noto Sans CJK SC", serif`;
const latinFont = size => `bold ${size}px Arial, Helvetica, sans-serif`;
const emojiFont = size => `${size}px "Apple Color Emoji", "Segoe UI Emoji", "Noto Color Emoji", sans-serif`;

const blue = '#1d4fb8';
const green = '#1f7a3a';
const red = '#c8102e';

const glyph = (context, text, x, y, size, color, font = cjkFont) => {
	context.font = font(size);
	context.fillStyle = color;
	context.textAlign = 'center';
	context.textBaseline = 'middle';
	context.fillText(text, x, y);
};

const corner = (context, text, color) => {
	glyph(context, text, 5.5, 6.5, 7, color, latinFont);
};

// The usable part of a face, inside its edge.
const faceInset = 3;
const facePoint = (u, v) => [faceInset + (u * (tileWidth - (faceInset * 2))), faceInset + (v * (tileHeight - (faceInset * 2)))];

const circlePatterns = [
	{radius: 11.5, colors: [red], points: [[0.5, 0.5]]},
	{radius: 7.5, colors: [green, blue], points: [[0.5, 0.27], [0.5, 0.73]]},
	{radius: 6, colors: [blue, red, green], points: [[0.24, 0.2], [0.5, 0.5], [0.76, 0.8]]},
	{radius: 6, colors: [blue, green, green, blue], points: [[0.29, 0.27], [0.71, 0.27], [0.29, 0.73], [0.71, 0.73]]},
	{radius: 5.4, colors: [blue, green, red, green, blue], points: [[0.27, 0.22], [0.73, 0.22], [0.5, 0.5], [0.27, 0.78], [0.73, 0.78]]},
	{radius: 5.2, colors: [green, green, red, red, red, red], points: [[0.3, 0.17], [0.7, 0.17], [0.3, 0.5], [0.7, 0.5], [0.3, 0.83], [0.7, 0.83]]},
	{radius: 4.4, colors: [green, green, green, red, red, red, red], points: [[0.2, 0.13], [0.5, 0.25], [0.8, 0.37], [0.3, 0.62], [0.7, 0.62], [0.3, 0.87], [0.7, 0.87]]},
	{radius: 4.5, colors: Array.from({length: 8}, () => blue), points: [[0.3, 0.13], [0.7, 0.13], [0.3, 0.38], [0.7, 0.38], [0.3, 0.62], [0.7, 0.62], [0.3, 0.87], [0.7, 0.87]]},
	{radius: 4.2, colors: [blue, blue, blue, red, red, red, green, green, green], points: [[0.2, 0.18], [0.5, 0.18], [0.8, 0.18], [0.2, 0.5], [0.5, 0.5], [0.8, 0.5], [0.2, 0.82], [0.5, 0.82], [0.8, 0.82]]},
];

const drawCircle = (context, x, y, radius, color) => {
	context.fillStyle = color;
	context.beginPath();
	context.arc(x, y, radius, 0, Math.PI * 2);
	context.fill();
	context.fillStyle = '#fffaf0';
	context.beginPath();
	context.arc(x, y, radius * 0.62, 0, Math.PI * 2);
	context.fill();
	context.fillStyle = color;
	context.beginPath();
	context.arc(x, y, radius * 0.32, 0, Math.PI * 2);
	context.fill();
};

const drawCircles = (context, count) => {
	const pattern = circlePatterns[count - 1];

	for (const [index, [u, v]] of pattern.points.entries()) {
		const [x, y] = facePoint(u, v);
		drawCircle(context, x, y, pattern.radius, pattern.colors[index]);
	}

	// The one of circles is the big flower of the set, with a green ring.
	if (count === 1) {
		context.strokeStyle = green;
		context.lineWidth = 1.5;
		context.beginPath();
		context.arc(18, 23, 14, 0, Math.PI * 2);
		context.stroke();
	}
};

const bambooPatterns = [
	undefined,
	{length: 15, points: [[0.5, 0.27], [0.5, 0.73]]},
	{length: 15, points: [[0.5, 0.27], [0.29, 0.73], [0.71, 0.73]]},
	{length: 15, points: [[0.3, 0.27], [0.7, 0.27], [0.3, 0.73], [0.7, 0.73]]},
	{length: 15, red: [2], points: [[0.25, 0.27], [0.75, 0.27], [0.5, 0.5], [0.25, 0.73], [0.75, 0.73]]},
	{length: 15, points: [[0.2, 0.27], [0.5, 0.27], [0.8, 0.27], [0.2, 0.73], [0.5, 0.73], [0.8, 0.73]]},
	{length: 11, red: [0], points: [[0.5, 0.17], [0.2, 0.5], [0.5, 0.5], [0.8, 0.5], [0.2, 0.83], [0.5, 0.83], [0.8, 0.83]]},
	{length: 15, points: [[0.17, 0.27], [0.39, 0.27], [0.61, 0.27], [0.83, 0.27], [0.17, 0.73], [0.39, 0.73], [0.61, 0.73], [0.83, 0.73]]},
	{length: 11, red: [1, 4, 7], points: [[0.2, 0.17], [0.5, 0.17], [0.8, 0.17], [0.2, 0.5], [0.5, 0.5], [0.8, 0.5], [0.2, 0.83], [0.5, 0.83], [0.8, 0.83]]},
];

const drawStick = (context, x, y, length, color) => {
	const width = 4.4;
	context.fillStyle = color;
	context.beginPath();
	context.roundRect(x - (width / 2), y - (length / 2), width, length, 2);
	context.fill();

	// The joints of the bamboo, at the ends and in the middle.
	context.fillStyle = 'rgb(255 255 255 / 55%)';

	for (const joint of [-0.5, 0, 0.5]) {
		context.fillRect(x - (width / 2), y + (joint * length) - (joint * 2) - 0.5, width, 1);
	}
};

// The one of bamboo is a bird, like in every mahjong set.
const drawBird = context => {
	context.lineWidth = 1.6;

	for (const [index, angle] of [-1, -0.55, -0.1, 0.35].entries()) {
		context.strokeStyle = index % 2 === 0 ? blue : green;
		context.beginPath();
		context.moveTo(15, 29);
		context.lineTo(15 + (Math.cos(Math.PI - 0.6 + angle) * 13), 29 + (Math.sin(Math.PI - 0.6 + angle) * 13));
		context.stroke();
	}

	context.fillStyle = green;
	context.beginPath();
	context.ellipse(19, 26, 7, 9, -0.3, 0, Math.PI * 2);
	context.fill();
	context.fillStyle = red;
	context.beginPath();
	context.ellipse(20, 28, 3.5, 5, -0.3, 0, Math.PI * 2);
	context.fill();
	context.fillStyle = green;
	context.beginPath();
	context.arc(23, 14, 4.5, 0, Math.PI * 2);
	context.fill();
	context.fillStyle = '#e8a33d';
	context.beginPath();
	context.moveTo(27, 13);
	context.lineTo(31.5, 15);
	context.lineTo(27, 16);
	context.fill();
	context.fillStyle = '#ffffff';
	context.beginPath();
	context.arc(24.5, 13, 1.3, 0, Math.PI * 2);
	context.fill();
	context.fillStyle = red;
	context.beginPath();
	context.moveTo(21, 10);
	context.lineTo(22, 5.5);
	context.lineTo(24.5, 9.5);
	context.fill();
	context.strokeStyle = '#7a4a1a';
	context.lineWidth = 1.2;
	context.beginPath();
	context.moveTo(18, 34);
	context.lineTo(17, 40);
	context.moveTo(21, 34);
	context.lineTo(22, 40);
	context.stroke();
};

const drawBamboo = (context, count) => {
	if (count === 1) {
		drawBird(context);
		return;
	}

	const pattern = bambooPatterns[count - 1];

	for (const [index, [u, v]] of pattern.points.entries()) {
		const [x, y] = facePoint(u, v);
		drawStick(context, x, y, pattern.length, pattern.red?.includes(index) ? red : green);
	}
};

const drawFlower = (context, color, centerColor = '#f2c200') => {
	context.fillStyle = color;

	for (let petal = 0; petal < 5; petal++) {
		const angle = (petal * Math.PI * 2 / 5) - (Math.PI / 2);
		context.beginPath();
		context.arc(18 + (Math.cos(angle) * 5), 15 + (Math.sin(angle) * 5), 3.6, 0, Math.PI * 2);
		context.fill();
	}

	context.fillStyle = centerColor;
	context.beginPath();
	context.arc(18, 15, 2.6, 0, Math.PI * 2);
	context.fill();
};

const numerals = ['一', '二', '三', '四', '五', '六', '七', '八', '九'];
const winds = ['東', '南', '西', '北'];
const windLetters = ['E', 'S', 'W', 'N'];
const flowers = [{text: '梅', color: '#e0457b'}, {text: '蘭', color: '#8e44ad'}, {text: '菊', color: '#e67e22'}, {text: '竹', color: green}];
const seasons = [{text: '春', emoji: '🌸', color: green}, {text: '夏', emoji: '☀️', color: red}, {text: '秋', emoji: '🍁', color: '#d35400'}, {text: '冬', emoji: '❄️', color: blue}];

const drawFace = (context, kind) => {
	if (kind < 9) {
		corner(context, String(kind + 1), blue);
		glyph(context, numerals[kind], 18, 14, 15, '#14206e');
		glyph(context, '萬', 18, 32.5, 17, red);
	} else if (kind < 18) {
		drawBamboo(context, kind - 8);
	} else if (kind < 27) {
		drawCircles(context, kind - 17);
	} else if (kind < 31) {
		corner(context, windLetters[kind - 27], blue);
		glyph(context, winds[kind - 27], 18, 25, 24, '#111111');
	} else if (kind === 31) {
		glyph(context, '中', 18, 24, 27, red);
	} else if (kind === 32) {
		glyph(context, '發', 18, 24, 24, green);
	} else if (kind === 33) {
		// The white dragon is an empty blue frame.
		context.strokeStyle = blue;
		context.lineWidth = 2.5;
		context.strokeRect(6.5, 6.5, 23, 33);
		context.lineWidth = 1;
		context.strokeRect(10, 10, 16, 26);
	} else if (kind < 38) {
		const flower = flowers[kind - 34];
		corner(context, String(kind - 33), red);
		drawFlower(context, flower.color);
		glyph(context, flower.text, 18, 34.5, 14, '#3a2a1a');
	} else {
		const season = seasons[kind - 38];
		corner(context, String(kind - 37), red);
		glyph(context, season.emoji, 18, 14, 12, '#000000', emojiFont);
		glyph(context, season.text, 18, 33, 17, season.color);
	}
};

const drawBanner = (context, title, subtitle) => {
	context.fillStyle = 'rgb(80 0 0 / 88%)';
	context.fillRect(110, 160, 380, 92);
	context.strokeStyle = '#ffd23f';
	context.lineWidth = 3;
	context.strokeRect(110, 160, 380, 92);
	context.fillStyle = '#ffd23f';
	context.textAlign = 'center';
	context.textBaseline = 'middle';
	context.font = 'bold 30px "Comic Sans MS", "Comic Sans", cursive';
	context.fillText(title, 300, 196);
	context.fillStyle = '#ffffff';
	context.font = '15px system-ui, sans-serif';
	context.fillText(subtitle, 300, 232);
};

const setToggle = (button, isOn, label) => {
	button.setAttribute('aria-pressed', String(isOn));
	button.textContent = `${isOn ? '☑' : '☐'} ${label}`;
};

export default class extends GeoCitiesElement {
	#context;
	#title;
	#viewWidth;
	#viewHeight;
	#bestTimes;
	#loop;
	#ticker;
	#peekPointer;

	// The kind of pointer of the last press, as not every browser tells it on a click.
	#lastPointerType;

	#keyPeek = false;
	#selectedCell;

	// Each layout is worked out once: its places, the neighbors of each place, the order to draw them in, and the scale that fills the table.
	#layouts = new Map();

	#effects = {poofs: [], sparks: [], fireworksLeft: 0, fireworkTimer: 0};

	#game = {
		layout: undefined,
		number: 1,
		kinds: [],
		isThere: [],
		history: [],
		selected: undefined,
		hint: undefined,
		hintIndex: 0,
		cursor: undefined,
		isCursorShown: false,
		lifted: new Set(),
		phase: 'new',
		build: undefined,
		isStarted: false,
		elapsed: 0,
		runningSince: undefined,
		helps: {hints: 0, shuffles: 0, peeks: 0},
		saidMilestones: new Set(),
	};

	// The game runs while its table is on screen: not while the window is closed, the table scrolled away, the boss key hides it, or the tab is hidden.
	get visibilityTarget() {
		return this.parts.screen;
	}

	connected() {
		const {screen, newGame: newGameButton, undo: undoButton, hint: hintButton, shuffle: shuffleButton, peek: peekButton, watch: watchButton, sound: soundButton, boss: bossButton, layout: layoutSelect, number: numberField, play: playButton, sheet} = this.parts;
		this.#context = screen.getContext('2d');
		this.#title = this.desktopWindow.querySelector('h3');
		this.#viewWidth = screen.width / pixelRatio;
		this.#viewHeight = screen.height / pixelRatio;
		this.#selectedCell = sheet.querySelector('[data-taipei-cell="A1"]');

		const options = this.stored('options', {});
		this.#game.layout = this.#layoutOf(Object.hasOwn(layouts, options.layout) ? options.layout : 'standard');

		// The best time and the number of wins of each layout.
		const storedBest = this.stored('best', {});

		this.#bestTimes = Object.fromEntries(Object.keys(layouts).map(id => {
			const record = storedBest[id];
			return [id, {time: isCount(record?.time) ? record.time : undefined, wins: isCount(record?.wins) ? record.wins : 0}];
		}));

		// The animations run only while the table is on screen, and never with reduced motion.
		this.#loop = this.loop(seconds => {
			this.#update(seconds);
			this.#draw();
			this.#showStats();
		}, {while: () => !this.reducedMotion && this.#isAnimating(), maximumStep: 0.05});

		this.on(soundButton, 'click', () => {
			const isOn = !this.#isSoundOn;
			soundButton.setAttribute('aria-pressed', String(isOn));
			soundButton.textContent = isOn ? '🔊 Sound' : '🔈 Sound';

			if (isOn) {
				this.#sounds.match();
			}
		});

		// The right mouse button peeks, like in Taipei, and so does every press while Peek is on, for touch.
		this.on(screen, 'pointerdown', event => {
			this.#lastPointerType = event.pointerType;

			// The pointer hides the cursor of the keyboard.
			if (this.#game.isCursorShown) {
				this.#game.isCursorShown = false;
				this.#draw();
			}

			if (this.#game.phase !== 'playing' || !(event.button === 2 || (event.button === 0 && this.#isPeekOn))) {
				return;
			}

			if (!this.#isPeekOn) {
				this.say('Turn on Peek to look under a tile with the right mouse button.');
				return;
			}

			const index = this.#tileAt(event, event.pointerType);

			if (index !== undefined) {
				this.#peekPointer = event.pointerId;
				screen.setPointerCapture(event.pointerId);
				this.#peek(index);
			}
		});

		// A tile is picked on a click, not on a press, so a finger that scrolls the page across the table picks nothing.
		this.on(screen, 'click', event => {
			if (this.#game.phase === 'building') {
				this.#finishBuild();
				return;
			}

			if (this.#game.phase === 'won') {
				this.say('You won this one! Press New for another.');
				return;
			}

			if (this.#isPeekOn) {
				return;
			}

			const index = this.#tileAt(event, this.#lastPointerType);

			if (index === undefined) {
				return;
			}

			this.#game.cursor = index;
			this.#pick(index);
		});

		for (const type of ['pointerup', 'pointercancel', 'lostpointercapture']) {
			this.on(screen, type, event => {
				if (event.pointerId === this.#peekPointer) {
					this.#peekPointer = undefined;
					this.#stopPeek();
				}
			});
		}

		// The right mouse button peeks instead of opening the menu of the browser, and a long press on a phone does not open one either.
		this.on(screen, 'contextmenu', event => {
			event.preventDefault();
		});

		this.on(screen, 'keydown', event => {
			this.#keyDown(event);
		});

		this.on(screen, 'keyup', event => {
			if (event.key.toLowerCase() === 'p' && this.#keyPeek) {
				this.#keyPeek = false;
				this.#stopPeek();
			}
		});

		// The Tab key shows the cursor right away, so the keyboard sees where it starts. A click shows none.
		this.on(screen, 'focus', () => {
			if (this.#game.phase !== 'playing' || !screen.matches(':focus-visible')) {
				return;
			}

			if (this.#game.cursor === undefined || !this.#game.isThere[this.#game.cursor]) {
				this.#moveCursor(0, 0);
			}

			this.#game.isCursorShown = true;
			this.#draw();
		});

		this.on(screen, 'blur', () => {
			this.#keyPeek = false;
			this.#stopPeek();
		});

		this.on(bossButton, 'click', () => {
			this.#showBoss();
		});

		this.on(sheet, 'focusin', event => {
			const cell = event.target.closest('[data-taipei-cell]');

			if (cell) {
				this.#selectCell(cell);
			}
		});

		for (const tab of sheet.querySelectorAll('[data-taipei-tab]')) {
			this.on(tab, 'click', () => {
				if (tab.dataset.taipeiTab === 'taipei') {
					this.#hideBoss();
				} else if (tab.dataset.taipeiTab === 'ark2') {
					this.say('Ark2 is empty. Pappa never got that far.', this.parts.sheetStatus);
				} else {
					this.say('Klar', this.parts.sheetStatus);
				}
			});
		}

		this.on(sheet, 'keydown', event => {
			this.#sheetKeyDown(event);
		});

		this.on(newGameButton, 'click', () => {
			this.#newGame();
			screen.focus();
		});

		this.on(undoButton, 'click', () => {
			this.#undo();
		});

		this.on(hintButton, 'click', () => {
			this.#hint();
		});

		this.on(shuffleButton, 'click', () => {
			this.#shuffleTiles();
		});

		this.on(peekButton, 'click', () => {
			setToggle(peekButton, !this.#isPeekOn, 'Peek');
			this.#saveOptions();
			this.say(this.#isPeekOn ? 'Peek is on: press and hold a tile, or hold P on it, to see what is under it.' : 'Peek is off. A press picks a tile again.');
		});

		this.on(watchButton, 'click', () => {
			setToggle(watchButton, !this.#isWatchOn, 'Watch Builds');
			this.#saveOptions();

			if (this.#isWatchOn && this.reducedMotion) {
				this.say('Watch Builds is on, but as your computer prefers less motion, the next layout shows up all at once.');
			} else {
				this.say(this.#isWatchOn ? 'Watch Builds is on: the next game shows how its layout is built.' : 'Watch Builds is off.');
			}
		});

		this.on(layoutSelect, 'change', () => {
			this.#deal(layoutSelect.value, this.#game.number);
			this.#saveOptions();
		});

		this.on(playButton, 'click', () => {
			this.#selectGame();
		});

		this.on(numberField, 'keydown', event => {
			if (event.key === 'Enter') {
				event.preventDefault();
				this.#selectGame();
			}
		});

		setToggle(peekButton, options.peek === true, 'Peek');
		setToggle(watchButton, options.watch !== false, 'Watch Builds');
	}

	// The first game is dealt when the window opens. A closed window stops the clock and lets go of a peek.
	visibilityChanged() {
		if (!this.desktopWindow.hidden && this.#game.phase === 'new') {
			this.#newGame();
		}

		if (this.desktopWindow.hidden) {
			this.#stopPeek();
		}

		this.#syncClock();
		this.#draw();
	}

	reducedMotionChanged(isReduced) {
		// A build that was halfway when reduced motion turned on shows up at once, as it would not go on by itself.
		if (isReduced) {
			this.#finishBuild();
		}

		this.#syncClock();
	}

	#layoutOf(id) {
		if (this.#layouts.has(id)) {
			return this.#layouts.get(id);
		}

		const viewWidth = this.#viewWidth;
		const viewHeight = this.#viewHeight;
		const places = layouts[id].places();
		let minimumX = Number.POSITIVE_INFINITY;
		let minimumY = Number.POSITIVE_INFINITY;
		let maximumX = Number.NEGATIVE_INFINITY;
		let maximumY = Number.NEGATIVE_INFINITY;

		for (const place of places) {
			const {x, y} = facePosition(place);
			minimumX = Math.min(minimumX, x);
			minimumY = Math.min(minimumY, y);
			maximumX = Math.max(maximumX, x + tileWidth + depth + 2);
			maximumY = Math.max(maximumY, y + tileHeight + depth + 2);
		}

		const margin = 12;
		const scale = Math.min((viewWidth - (margin * 2)) / (maximumX - minimumX), (viewHeight - (margin * 2)) / (maximumY - minimumY), 1.5);

		// The lower layers are drawn first, and in a layer, from the left and the top, so each tile hides the edges of the tiles behind it.
		const drawOrder = places.map((_, index) => index).sort((first, second) => (places[first].z - places[second].z) || (places[first].x - places[second].x) || (places[first].y - places[second].y));

		const layout = {
			id,
			places,
			neighbors: neighborsOf(places),
			drawOrder,
			scale,
			offsetX: ((viewWidth - ((maximumX - minimumX) * scale)) / 2) - (minimumX * scale),
			offsetY: ((viewHeight - ((maximumY - minimumY) * scale)) / 2) - (minimumY * scale),
		};

		this.#layouts.set(id, layout);
		return layout;
	}

	#isFree(index) {
		return isFreeIn(this.#game.layout.neighbors, index, this.#game.isThere);
	}

	#tilesLeft() {
		return this.#game.isThere.filter(Boolean).length;
	}

	// The free pairs, as pairs of tiles. Three free tiles of a kind make three pairs.
	#freePairs() {
		const game = this.#game;
		const groups = new Map();

		for (const [index, isThere] of game.isThere.entries()) {
			if (isThere && this.#isFree(index)) {
				const group = matchGroup(game.kinds[index]);
				groups.set(group, [...(groups.get(group) ?? []), index]);
			}
		}

		const pairs = [];

		for (const indices of groups.values()) {
			for (const [position, first] of indices.entries()) {
				for (const second of indices.slice(position + 1)) {
					pairs.push([first, second]);
				}
			}
		}

		return pairs;
	}

	// The clock runs while the game is played and seen: not before the first tile, not behind the boss key, and not while the window is closed, scrolled away, or the tab is hidden. The boss key is checked too, as the visibility of the table changes a moment later.
	get #isClockRunning() {
		return this.#game.phase === 'playing' && this.#game.isStarted && this.parts.sheet.hidden && this.isVisible;
	}

	#elapsedSeconds() {
		const game = this.#game;
		return Math.floor((game.elapsed + (game.runningSince === undefined ? 0 : performance.now() - game.runningSince)) / 1000);
	}

	#showStats() {
		const game = this.#game;
		const {stats} = this.parts;
		const best = this.#bestTimes[game.layout.id].time;
		const text = `Tiles ${this.#tilesLeft()} ★ Moves ${game.phase === 'building' ? '…' : this.#freePairs().length}\nTime ${clockText(this.#elapsedSeconds())} ★ Best ${best === undefined ? '–' : clockText(best)}`;

		if (stats.textContent !== text) {
			stats.textContent = text;
		}
	}

	// With reduced motion, the clock is shown after each move instead of every second, so nothing changes by itself.
	#syncClock() {
		const game = this.#game;
		const now = performance.now();

		if (this.#isClockRunning) {
			game.runningSince ??= now;
		} else if (game.runningSince !== undefined) {
			game.elapsed += now - game.runningSince;
			game.runningSince = undefined;
		}

		const shouldTick = this.#isClockRunning && !this.reducedMotion;

		if (shouldTick && !this.#ticker) {
			this.#ticker = this.interval(1000, () => {
				this.#showStats();
			});
		} else if (!shouldTick && this.#ticker) {
			this.#ticker.cancel();
			this.#ticker = undefined;
		}

		this.#showStats();
	}

	get #isSoundOn() {
		return this.parts.sound.getAttribute('aria-pressed') === 'true';
	}

	// The sounds, made with tones through the volume of the tray, once the visitor turns them on.
	#tone(frequency, start, duration, {type = 'triangle', volume = 0.1, slide} = {}) {
		const sound = this.#isSoundOn && this.sound();

		if (!sound) {
			return;
		}

		const {context, output} = sound;
		const oscillator = context.createOscillator();
		const gain = context.createGain();
		const time = context.currentTime + start;
		oscillator.type = type;
		oscillator.frequency.setValueAtTime(frequency, time);

		if (slide) {
			oscillator.frequency.exponentialRampToValueAtTime(slide, time + duration);
		}

		gain.gain.setValueAtTime(0.0001, time);
		gain.gain.exponentialRampToValueAtTime(volume, time + 0.005);
		gain.gain.exponentialRampToValueAtTime(0.0001, time + duration);
		oscillator.connect(gain).connect(output);
		oscillator.start(time);
		oscillator.stop(time + duration + 0.05);
	}

	// The clack of a tile is a short, high square wave, like two tiles that touch.
	#clack(start = 0, pitch = 1) {
		this.#tone(1900 * pitch, start, 0.03, {type: 'square', volume: 0.05});
		this.#tone(950 * pitch, start, 0.05, {volume: 0.06});
	}

	#sounds = {
		pick: () => this.#clack(),
		match: () => {
			this.#clack(0, 1.1);
			this.#tone(1319, 0.06, 0.18, {volume: 0.07});
			this.#tone(1760, 0.12, 0.25, {volume: 0.05});
		},
		wrong: () => this.#tone(180, 0, 0.18, {type: 'sawtooth', volume: 0.06}),
		blocked: () => this.#tone(140, 0, 0.12, {type: 'square', volume: 0.05}),
		undo: () => this.#tone(700, 0, 0.15, {slide: 300, volume: 0.07}),
		build: () => this.#clack(0, 0.8 + (Math.random() * 0.4)),
		shuffle: () => {
			for (let index = 0; index < 10; index++) {
				this.#clack(index * 0.045, 0.7 + (Math.random() * 0.6));
			}
		},
		stuck: () => {
			for (const [index, frequency] of [440, 392, 330].entries()) {
				this.#tone(frequency, index * 0.18, 0.25, {volume: 0.08});
			}
		},
		won: () => {
			for (const [index, step] of [0, 1, 2, 4, 3, 4, 5, 7].entries()) {
				this.#tone(pentatonic[step], index * 0.13, index === 7 ? 0.7 : 0.2, {volume: 0.09});
			}
		},
	};

	// A question with the message box of the desktop.
	ask(options) {
		return super.ask({title: 'Taipei', icon: '🀄', opener: this.parts.screen, ...options});
	}

	// A tile in the 3D look of Taipei: a shadow on the table, the green back, the ivory middle, and the face, each a little up and to the left.
	#drawTile(index, {lift = 0, alpha = 1} = {}) {
		const context = this.#context;
		const game = this.#game;
		const {x, y} = facePosition(game.layout.places[index]);
		const top = y - lift;
		context.save();
		context.globalAlpha = alpha;
		context.fillStyle = 'rgb(0 0 0 / 28%)';
		context.beginPath();
		context.roundRect(x + depth + 2, y + depth + 2, tileWidth, tileHeight, 4);
		context.fill();
		context.lineWidth = 0.8;

		for (const [offset, fill, stroke] of [[depth, '#2f7d4f', '#0b3320'], [depth * 0.5, '#e6d9b0', '#7d7150']]) {
			context.fillStyle = fill;
			context.strokeStyle = stroke;
			context.beginPath();
			context.roundRect(x + offset, top + offset, tileWidth, tileHeight, 4);
			context.fill();
			context.stroke();
		}

		let face = '#fffaf0';

		if (game.selected === index) {
			face = '#ffd23f';
		} else if (game.hint?.includes(index)) {
			face = '#9de6ff';
		}

		context.fillStyle = face;
		context.strokeStyle = '#5c543c';
		context.beginPath();
		context.roundRect(x, top, tileWidth, tileHeight, 4);
		context.fill();
		context.stroke();
		context.strokeStyle = 'rgb(255 255 255 / 90%)';
		context.beginPath();
		context.moveTo(x + 2, top + tileHeight - 3);
		context.lineTo(x + 2, top + 2);
		context.lineTo(x + tileWidth - 3, top + 2);
		context.stroke();
		context.translate(x, top);
		drawFace(context, game.kinds[index]);
		context.restore();
	}

	#draw() {
		const context = this.#context;
		const game = this.#game;
		const effects = this.#effects;
		const viewWidth = this.#viewWidth;
		const viewHeight = this.#viewHeight;
		context.setTransform(pixelRatio, 0, 0, pixelRatio, 0, 0);
		const background = context.createRadialGradient(viewWidth / 2, viewHeight / 2, 40, viewWidth / 2, viewHeight / 2, viewWidth * 0.7);
		background.addColorStop(0, '#1d6b40');
		background.addColorStop(1, '#0a3a22');
		context.fillStyle = background;
		context.fillRect(0, 0, viewWidth, viewHeight);

		const {layout} = game;
		context.setTransform(pixelRatio * layout.scale, 0, 0, pixelRatio * layout.scale, pixelRatio * layout.offsetX, pixelRatio * layout.offsetY);

		if (game.phase === 'building') {
			// The build puts the pairs down in order, and the newest tiles drop onto the table.
			const shown = game.build.shown;

			for (const index of layout.drawOrder) {
				const position = game.build.positions[index];

				if (position < shown) {
					const progress = Math.min((shown - position) / 6, 1);
					this.#drawTile(index, {lift: (1 - progress) * 24, alpha: progress});
				}
			}
		} else {
			for (const index of layout.drawOrder) {
				if (game.isThere[index] && !game.lifted.has(index)) {
					this.#drawTile(index);
				}
			}
		}

		// The tiles that Peek lifts are only outlines, so the tiles under them show.
		context.setLineDash([3, 3]);
		context.strokeStyle = '#ffd23f';
		context.lineWidth = 1.5;

		for (const index of game.lifted) {
			const {x, y} = facePosition(layout.places[index]);
			context.strokeRect(x, y, tileWidth, tileHeight);
		}

		context.setLineDash([]);

		if (game.isCursorShown && game.cursor !== undefined && game.isThere[game.cursor] && game.phase === 'playing') {
			const {x, y} = facePosition(layout.places[game.cursor]);
			context.strokeStyle = '#ff2020';
			context.lineWidth = 2.5;
			context.strokeRect(x - 1.5, y - 1.5, tileWidth + 3, tileHeight + 3);
		}

		// A pair that goes away leaves a puff of stars for a moment.
		for (const poof of effects.poofs) {
			const progress = poof.age / 0.35;
			context.fillStyle = `rgb(255 240 150 / ${Math.round((1 - progress) * 100)}%)`;

			for (let ray = 0; ray < 8; ray++) {
				const angle = ray * Math.PI / 4;
				const distance = 6 + (progress * 22);
				context.beginPath();
				context.arc(poof.x + (Math.cos(angle) * distance), poof.y + (Math.sin(angle) * distance), 2.4 * (1 - progress) + 0.5, 0, Math.PI * 2);
				context.fill();
			}
		}

		context.setTransform(pixelRatio, 0, 0, pixelRatio, 0, 0);

		for (const spark of effects.sparks) {
			context.fillStyle = `hsl(${spark.hue} 100% 65% / ${Math.round(Math.max(spark.life, 0) * 100)}%)`;
			context.fillRect(spark.x - 2, spark.y - 2, 4, 4);
		}

		if (game.phase === 'won') {
			drawBanner(context, 'You won! 🎆', `${layouts[layout.id].name}, game #${game.number}, in ${clockText(this.#elapsedSeconds())}.`);
		} else if (game.phase === 'building') {
			context.fillStyle = 'rgb(0 0 0 / 55%)';
			context.fillRect(0, 0, viewWidth, 24);
			context.fillStyle = '#ffffff';
			context.font = 'bold 13px system-ui, sans-serif';
			context.textAlign = 'left';
			context.textBaseline = 'top';
			context.fillText(`Building the ${layouts[layout.id].name}… pair ${Math.min(Math.ceil(game.build.shown / 2), game.build.total / 2)} of ${game.build.total / 2}. Click to skip.`, 10, 8);
		}
	}

	#isAnimating() {
		const effects = this.#effects;
		return this.#game.phase === 'building' || effects.poofs.length > 0 || effects.sparks.length > 0 || effects.fireworksLeft > 0;
	}

	#launchFirework() {
		const x = 80 + (Math.random() * (this.#viewWidth - 160));
		const y = 60 + (Math.random() * (this.#viewHeight / 2));
		const hue = Math.floor(Math.random() * 360);

		for (let spark = 0; spark < 40; spark++) {
			const angle = Math.random() * Math.PI * 2;
			const speed = 40 + (Math.random() * 90);
			this.#effects.sparks.push({x, y, vx: Math.cos(angle) * speed, vy: Math.sin(angle) * speed, life: 1, hue: hue + (Math.random() * 40)});
		}

		this.#sounds.build();
	}

	#update(delta) {
		const game = this.#game;
		const effects = this.#effects;

		if (game.phase === 'building') {
			const before = game.build.shown;
			game.build.shown = Math.min(game.build.shown + (delta / 0.01), game.build.total + 6);

			if (Math.floor(game.build.shown / 2) > Math.floor(before / 2) && game.build.shown <= game.build.total) {
				this.#sounds.build();
			}

			if (game.build.shown >= game.build.total + 6) {
				this.#finishBuild();
			}
		}

		for (const poof of effects.poofs) {
			poof.age += delta;
		}

		effects.poofs = effects.poofs.filter(poof => poof.age < 0.35);

		if (effects.fireworksLeft > 0) {
			effects.fireworkTimer -= delta;

			if (effects.fireworkTimer <= 0) {
				this.#launchFirework();
				effects.fireworksLeft--;
				effects.fireworkTimer = 0.45;
			}
		}

		for (const spark of effects.sparks) {
			spark.x += spark.vx * delta;
			spark.y += spark.vy * delta;
			spark.vy += 90 * delta;
			spark.life -= delta * 0.8;
		}

		effects.sparks = effects.sparks.filter(spark => spark.life > 0);
	}

	get #isPeekOn() {
		return this.parts.peek.getAttribute('aria-pressed') === 'true';
	}

	get #isWatchOn() {
		return this.parts.watch.getAttribute('aria-pressed') === 'true';
	}

	#saveOptions() {
		this.store('options', {layout: this.#game.layout.id, peek: this.#isPeekOn, watch: this.#isWatchOn});
	}

	// An action that skips the rest of the build, like Undo, says its own text instead.
	#finishBuild({isQuiet = false} = {}) {
		const game = this.#game;

		if (game.phase !== 'building') {
			return;
		}

		game.phase = 'playing';
		game.build = undefined;

		if (!isQuiet) {
			this.say('Built! Pick two free tiles that match. Try the ends of the rows, or Hint.');
		}

		this.#draw();
		this.#showStats();
	}

	// A new deal: the build order of the layout with this number, and a pair of the set for each pair of places.
	#deal(layoutId, number) {
		const game = this.#game;
		game.layout = this.#layoutOf(layoutId);
		game.number = number;
		const {places, neighbors} = game.layout;
		const random = seededRandom((number * 7919) + Object.keys(layouts).indexOf(layoutId));
		const order = buildOrder(neighbors, places, random);

		// The build has always worked for every layout, but a number that cannot be built deals the next one instead of no game.
		if (!order) {
			this.#deal(layoutId, (number % 99_999) + 1);
			return;
		}

		const pairs = shuffle(allPairs(), random).slice(0, places.length / 2);
		game.kinds = [];

		for (const [position, [first, second]] of order.entries()) {
			[game.kinds[first], game.kinds[second]] = pairs[position];
		}

		game.isThere = places.map(() => true);
		game.history = [];
		game.selected = undefined;
		game.hint = undefined;
		game.hintIndex = 0;
		game.cursor = undefined;
		game.lifted.clear();
		game.isStarted = false;
		game.elapsed = 0;
		game.runningSince = undefined;
		game.helps = {hints: 0, shuffles: 0, peeks: 0};
		game.saidMilestones = new Set();
		this.#effects.sparks = [];
		this.#effects.fireworksLeft = 0;
		this.parts.number.value = String(number);
		this.parts.layout.value = layoutId;

		// Watch Builds puts the tiles down in the order of the build. With reduced motion, the layout is there at once.
		if (this.#isWatchOn && !this.reducedMotion) {
			const positions = [];

			for (const [position, pair] of order.entries()) {
				positions[pair[0]] = position * 2;
				positions[pair[1]] = (position * 2) + 1;
			}

			game.phase = 'building';
			game.build = {positions, shown: 0, total: places.length};
			this.say(`Watch the ${layouts[layoutId].name} #${number} go up, pair by pair. Click to skip.`);
		} else {
			game.phase = 'playing';
			this.say(`${layouts[layoutId].name} #${number}: pick two free tiles that match. Try the ends of the rows.`);
		}

		this.#syncClock();
		this.#draw();
		this.#loop.start();
	}

	#newGame(layoutId = this.#game.layout.id) {
		this.#deal(layoutId, 1 + Math.floor(Math.random() * 99_999));
	}

	#startClock() {
		if (!this.#game.isStarted) {
			this.#game.isStarted = true;
			this.#syncClock();
		}
	}

	// What the family says while I play, once in each game, as the tiles go.
	#milestoneText() {
		const game = this.#game;
		const share = this.#tilesLeft() / game.layout.places.length;

		for (const [index, milestone] of milestones.entries()) {
			if (share <= milestone.share && !game.saidMilestones.has(index)) {
				game.saidMilestones.add(index);
				return ` ${randomItem(milestone.lines)}`;
			}
		}

		return '';
	}

	#helpText() {
		const parts = [];
		const {helps} = this.#game;

		for (const [name, count] of [['hint', helps.hints], ['shuffle', helps.shuffles], ['peek', helps.peeks]]) {
			if (count > 0) {
				parts.push(`${count} ${name}${count === 1 ? '' : 's'}`);
			}
		}

		return parts.length === 0 ? 'without any help' : `with ${new Intl.ListFormat('en', {type: 'conjunction'}).format(parts)}`;
	}

	async #win() {
		const game = this.#game;
		const effects = this.#effects;
		game.phase = 'won';
		this.#syncClock();
		const seconds = this.#elapsedSeconds();
		const record = this.#bestTimes[game.layout.id];
		const isBest = record.time === undefined || seconds < record.time;
		record.wins++;

		if (isBest) {
			record.time = seconds;
		}

		this.store('best', this.#bestTimes);
		this.#sounds.won();
		this.celebrate();
		effects.fireworksLeft = 8;
		effects.fireworkTimer = 0;

		// With reduced motion, the fireworks are a still picture.
		if (this.reducedMotion) {
			effects.fireworksLeft = 0;

			for (let burst = 0; burst < 5; burst++) {
				this.#launchFirework();

				for (const spark of effects.sparks.slice(-40)) {
					spark.x += spark.vx * 0.4;
					spark.y += spark.vy * 0.4;
				}
			}

			this.#draw();
			effects.sparks = [];
		} else {
			this.#draw();
			this.#loop.start();
		}

		this.#showStats();
		const name = layouts[game.layout.id].name;
		const text = `You cleared the ${name} in ${clockText(seconds)}, ${this.#helpText()}!${isBest ? ' That is your best time on it!' : ` Your best on it is ${clockText(record.time)}.`} You have cleared it ${record.wins} ${record.wins === 1 ? 'time' : 'times'}.\n\n${randomItem(winLines)}`;
		// The message box reads out the whole text, so the status line only keeps the result, short enough to fit.
		this.say(`You cleared the ${name} in ${clockText(seconds)}!${isBest ? ' Your best time on it!' : ''}`);
		const answer = await this.ask({icon: '🎆', text, buttons: ['New Game', 'OK']});

		if (answer === 'New Game' && game.phase === 'won') {
			this.#newGame();
			this.parts.screen.focus();
		}
	}

	async #offerShuffle() {
		this.#sounds.stuck();
		const text = `No more moves! None of the free tiles match.\n\nShuffle the ${this.#tilesLeft()} tiles that are left? Mormor always shuffles. Or undo, or start over.`;
		this.say('No more moves! None of the free tiles match.');
		const answer = await this.ask({icon: '🀄', text, buttons: ['Shuffle', 'Undo', 'New Game']});

		// The answer only counts while there are still no moves, so a box that was left open does nothing to a game that went on, or to a new one.
		if (this.#game.phase !== 'playing' || this.#freePairs().length > 0) {
			return;
		}

		if (answer === undefined) {
			this.say('No more moves. Press Shuffle, Undo, or New.');
			return;
		}

		if (answer === 'Shuffle') {
			this.#shuffleTiles();
		} else if (answer === 'Undo') {
			this.#undo();
		} else {
			this.#newGame();
		}

		this.parts.screen.focus();
	}

	// Ends the game when no tiles are left, or offers a shuffle when no moves are left. It returns whether it did, as it then says its own text.
	#checkEnd() {
		if (this.#tilesLeft() === 0) {
			this.#win();
			return true;
		}

		if (this.#freePairs().length === 0) {
			this.#offerShuffle();
			return true;
		}

		return false;
	}

	#removePair(first, second) {
		const game = this.#game;
		game.isThere[first] = false;
		game.isThere[second] = false;
		game.history.push({pair: [first, second]});
		game.selected = undefined;
		game.hint = undefined;
		this.#sounds.match();

		if (!this.reducedMotion) {
			for (const index of [first, second]) {
				const {x, y} = facePosition(game.layout.places[index]);
				this.#effects.poofs.push({x: x + (tileWidth / 2), y: y + (tileHeight / 2), age: 0});
			}
		}

		const message = `A pair of ${groupName(game.kinds[first])}! ${this.#tilesLeft()} tiles left.${this.#milestoneText()}`;
		this.#draw();
		this.#showStats();
		this.#loop.start();

		if (!this.#checkEnd()) {
			this.say(message);
		}
	}

	#whyNotFree(index) {
		const game = this.#game;
		const {above} = game.layout.neighbors[index];
		const name = tileName(game.kinds[index]);

		if (above.some(other => game.isThere[other])) {
			return `The ${name} is not free: a tile lies on it.`;
		}

		return `The ${name} is not free: tiles touch it on both sides. One side must be open.`;
	}

	#pick(index, {byKeyboard = false} = {}) {
		const game = this.#game;

		if (game.phase !== 'playing' || !game.isThere[index]) {
			return;
		}

		this.#startClock();
		const name = tileName(game.kinds[index]);

		if (!this.#isFree(index)) {
			this.#sounds.blocked();
			this.say(this.#whyNotFree(index));
			return;
		}

		let message;

		if (game.selected === index) {
			game.selected = undefined;
			this.#sounds.pick();
			message = `Let go of the ${name}.`;
		} else if (game.selected !== undefined && matchGroup(game.kinds[game.selected]) === matchGroup(game.kinds[index])) {
			this.#removePair(game.selected, index);
			return;
		} else if (game.selected === undefined) {
			game.selected = index;
			this.#sounds.pick();
			message = `Picked the ${name}. Now pick its match.`;
		} else {
			const other = tileName(game.kinds[game.selected]);
			game.selected = index;
			this.#sounds.wrong();
			message = `No match for the ${other}. Picked the ${name} instead.`;
		}

		// After the first tile of a hint, the cursor goes to the other one, so the keyboard does not have to look for it across the table.
		if (byKeyboard && game.selected === index && game.hint?.includes(index)) {
			game.cursor = game.hint.find(other => other !== index);
			message = `Picked the ${name}. The cursor is on its match: press Space.`;
		}

		this.say(message);
		this.#draw();
		this.#showStats();
	}

	#undo() {
		const game = this.#game;
		this.#finishBuild({isQuiet: true});

		if (game.phase !== 'playing') {
			this.say(game.phase === 'won' ? 'The game is won. There is nothing to undo, only to celebrate.' : 'Nothing to undo.');
			return;
		}

		const step = game.history.pop();

		if (!step) {
			this.say('Nothing to undo. Not a single tile is gone yet.');
			return;
		}

		game.selected = undefined;
		game.hint = undefined;
		this.#sounds.undo();

		if (step.kinds) {
			game.kinds = step.kinds;
			this.say('The shuffle is undone. The tiles are back where they were.');
		} else {
			for (const index of step.pair) {
				game.isThere[index] = true;
			}

			this.say(`Put the pair of ${groupName(game.kinds[step.pair[0]])} back. ${this.#tilesLeft()} tiles left.`);
		}

		this.#draw();
		this.#showStats();
	}

	#hint() {
		const game = this.#game;
		this.#finishBuild({isQuiet: true});

		if (game.phase !== 'playing') {
			return;
		}

		const pairs = this.#freePairs();

		if (pairs.length === 0) {
			this.#offerShuffle();
			return;
		}

		this.#startClock();
		const position = game.hintIndex % pairs.length;
		game.hint = pairs[position];
		game.hintIndex++;
		game.helps.hints++;
		game.selected = undefined;
		game.cursor = game.hint[0];
		this.#sounds.pick();
		this.say(`Hint: the two blue ${groupName(game.kinds[game.hint[0]])}. ${pairs.length > 1 ? `Free pair ${position + 1} of ${pairs.length}.` : 'The only free pair!'}`);
		this.#draw();
	}

	// A shuffle deals the tiles that are left onto the places that are left, built backwards like a new deal, so it has a way out again. Some leftovers have none, like a tile that lies on its own match, and then the shuffle is only random.
	#shuffleTiles() {
		const game = this.#game;
		this.#finishBuild({isQuiet: true});

		if (game.phase !== 'playing') {
			return;
		}

		const left = game.isThere.flatMap((isThere, index) => (isThere ? [index] : []));

		if (left.length === 0) {
			return;
		}

		const groups = new Map();

		for (const index of left) {
			const kind = game.kinds[index];
			groups.set(matchGroup(kind), [...(groups.get(matchGroup(kind)) ?? []), kind]);
		}

		const pairs = [];

		for (const kinds of groups.values()) {
			shuffle(kinds);

			for (let index = 0; index < kinds.length; index += 2) {
				pairs.push([kinds[index], kinds[index + 1]]);
			}
		}

		shuffle(pairs);
		const order = buildOrder(game.layout.neighbors, game.layout.places.map((place, index) => (game.isThere[index] ? place : undefined)), Math.random);
		game.history.push({kinds: [...game.kinds]});
		game.kinds = [...game.kinds];

		if (order) {
			for (const [position, [first, second]] of order.entries()) {
				[game.kinds[first], game.kinds[second]] = pairs[position];
			}
		} else {
			const kinds = shuffle(pairs.flat());

			for (const [position, index] of left.entries()) {
				game.kinds[index] = kinds[position];
			}
		}

		this.#startClock();
		game.helps.shuffles++;
		game.selected = undefined;
		game.hint = undefined;
		this.#sounds.shuffle();
		this.#draw();
		this.#showStats();

		// A random shuffle can leave no moves, and then the end of the game says its own text instead.
		if (order || !this.#checkEnd()) {
			this.say(order ? `Shuffled the ${left.length} tiles that are left, so there is a way out again.` : `Shuffled the ${left.length} tiles that are left. Not even Mormor could shuffle these into a sure win. Good luck!`);
		}
	}

	// Peek lifts a tile, and the tiles that lie on it, while the visitor holds it, to see what is under it.
	#peek(index) {
		const game = this.#game;

		if (game.phase !== 'playing' || !game.isThere[index]) {
			return;
		}

		const lift = tile => {
			if (game.isThere[tile] && !game.lifted.has(tile)) {
				game.lifted.add(tile);

				for (const other of game.layout.neighbors[tile].above) {
					lift(other);
				}
			}
		};

		lift(index);
		game.helps.peeks++;
		// Only the tiles right under it show, not the ones deeper down.
		const under = game.layout.neighbors[index].below.filter(other => game.isThere[other] && !game.lifted.has(other));
		const topLayer = Math.max(...under.map(other => game.layout.places[other].z));
		const names = [...new Set(under.filter(other => game.layout.places[other].z === topLayer).map(other => tileName(game.kinds[other])))];
		this.say(names.length === 0 ? `Under the ${tileName(game.kinds[index])} is only the table.` : `Under the ${tileName(game.kinds[index])}: ${names.join(', ')}. Let go to put it back.`);
		this.#draw();
	}

	#stopPeek() {
		if (this.#game.lifted.size > 0) {
			this.#game.lifted.clear();
			this.#draw();
		}
	}

	// The tile under a point of the table: the last one drawn there, with its edge, which is the one the visitor sees. The border of the canvas is not part of the table.
	#tileAt(event, pointerType) {
		const {screen} = this.parts;
		const box = screen.getBoundingClientRect();
		const {layout} = this.#game;
		const x = (((((event.clientX - box.left - screen.clientLeft) / screen.clientWidth) * this.#viewWidth) - layout.offsetX) / layout.scale);
		const y = (((((event.clientY - box.top - screen.clientTop) / screen.clientHeight) * this.#viewHeight) - layout.offsetY) / layout.scale);
		const shown = layout.drawOrder.filter(index => this.#game.isThere[index] && !this.#game.lifted.has(index));

		const isNear = (index, reach) => {
			const face = facePosition(layout.places[index]);
			return x >= face.x - reach && x <= face.x + tileWidth + depth + reach && y >= face.y - reach && y <= face.y + tileHeight + depth + reach;
		};

		const tile = shown.findLast(index => isNear(index, 0));

		if (pointerType !== 'touch' || (tile !== undefined && this.#isFree(tile))) {
			return tile;
		}

		// The tiles are small on a phone, and a finger is not as exact as a mouse, so a tap that lands just off a free tile, on the table or the edge of a tile that is not free, picks the nearest free tile within a few pixels.
		const reach = 4 * this.#viewWidth / screen.clientWidth / layout.scale;
		const distance = index => {
			const face = facePosition(layout.places[index]);
			return Math.hypot(face.x + (tileWidth / 2) - x, face.y + (tileHeight / 2) - y);
		};

		const near = shown.filter(index => this.#isFree(index) && isNear(index, reach)).sort((first, second) => distance(first) - distance(second));
		return near[0] ?? tile;
	}

	// The keyboard moves a cursor between the tiles that nothing lies on, to the nearest one in the direction of the arrow.
	#moveCursor(dx, dy) {
		const game = this.#game;
		const {places, neighbors} = game.layout;
		const tops = places.flatMap((_, index) => (game.isThere[index] && !neighbors[index].above.some(other => game.isThere[other]) ? [index] : []));

		if (tops.length === 0) {
			return;
		}

		if (game.cursor === undefined) {
			game.cursor = tops.find(index => this.#isFree(index)) ?? tops[0];
			return;
		}

		// The cursor moves on from the place of a pair that was just taken off, so it stays where the visitor plays.
		const from = facePosition(places[game.cursor]);
		let best;
		let bestScore = Number.POSITIVE_INFINITY;
		let nearest;
		let nearestDistance = Number.POSITIVE_INFINITY;

		for (const index of tops) {
			const to = facePosition(places[index]);
			const along = ((to.x - from.x) * dx) + ((to.y - from.y) * dy);
			const across = Math.abs(((to.x - from.x) * dy) - ((to.y - from.y) * dx));
			const distance = Math.hypot(to.x - from.x, to.y - from.y);

			if (along > 4) {
				const score = along + (across * 2);

				if (score < bestScore) {
					bestScore = score;
					best = index;
				}
			}

			if (distance < nearestDistance) {
				nearestDistance = distance;
				nearest = index;
			}
		}

		if (best !== undefined) {
			game.cursor = best;
		} else if (!game.isThere[game.cursor]) {
			game.cursor = nearest;
		}
	}

	#describeCursor() {
		const game = this.#game;

		if (game.cursor === undefined) {
			return;
		}

		const index = game.cursor;
		this.say(`${tileName(game.kinds[index])}, ${this.#isFree(index) ? 'free' : 'not free'}${game.selected === index ? ', picked' : ''}.`);
	}

	#keyDown(event) {
		const game = this.#game;

		if (event.altKey || event.metaKey) {
			return;
		}

		const key = event.key.toLowerCase();

		if (event.ctrlKey) {
			if (key === 'z') {
				event.preventDefault();
				this.#undo();
			}

			return;
		}

		const move = {arrowleft: [-1, 0], arrowright: [1, 0], arrowup: [0, -1], arrowdown: [0, 1]}[key];

		if (move) {
			event.preventDefault();

			if (game.phase === 'playing') {
				this.#moveCursor(...move);
				game.isCursorShown = true;
				this.#describeCursor();
				this.#draw();
			}
		} else if (key === ' ' || key === 'enter') {
			event.preventDefault();

			if (event.repeat) {
				return;
			}

			if (game.phase === 'building') {
				this.#finishBuild();
			} else if (game.phase !== 'playing') {
				this.say('You won this one! Press New for another.');
			} else if (game.cursor === undefined || !game.isThere[game.cursor]) {
				this.#moveCursor(0, 0);
				game.isCursorShown = true;
				this.#describeCursor();
				this.#draw();
			} else {
				game.isCursorShown = true;
				this.#pick(game.cursor, {byKeyboard: true});
			}
		} else if (key === 'h') {
			event.preventDefault();
			game.isCursorShown = true;
			this.#hint();
		} else if (key === 'u' || key === 'backspace') {
			event.preventDefault();
			this.#undo();
		} else if (key === 'p') {
			event.preventDefault();

			if (event.repeat || game.cursor === undefined || game.phase !== 'playing') {
				return;
			}

			if (this.#isPeekOn) {
				this.#keyPeek = true;
				this.#peek(game.cursor);
			} else {
				this.say('Turn on Peek to look under a tile with P.');
			}
		} else if (key === 'escape') {
			// Escape lets go of a picked tile. Without one, it closes the window, like in the other programs.
			if (game.selected !== undefined) {
				event.preventDefault();
				event.stopPropagation();
				game.selected = undefined;
				this.say('Let go of the tile.');
				this.#draw();
			}
		} else if (key === 'b') {
			event.preventDefault();
			this.#showBoss();
		}
	}

	#selectCell(cell) {
		const {nameBox, formula} = this.parts;
		delete this.#selectedCell.dataset.state;
		this.#selectedCell.tabIndex = -1;
		this.#selectedCell = cell;
		cell.dataset.state = 'selected';
		cell.tabIndex = 0;
		nameBox.textContent = cell.dataset.taipeiCell;
		formula.textContent = cell.dataset.taipeiFormula ?? cell.textContent;
	}

	// The Boss Key hides the game behind the budget of Pappa, stops the clock, and names the window after the workbook, in case somebody walks by.
	#showBoss() {
		const {game, sheet, sheetStatus} = this.parts;

		if (!sheet.hidden) {
			return;
		}

		this.#stopPeek();
		game.hidden = true;
		sheet.hidden = false;
		this.#title.textContent = 'Microsoft Excel - PAPPA BUDSJETT 99.XLS';
		this.#syncClock();
		this.#selectCell(sheet.querySelector('[data-taipei-cell="C4"]'));
		this.#selectedCell.focus();
		this.say(`Klar. ${randomItem(walkBys)}`, sheetStatus);
	}

	#hideBoss() {
		const {game, sheet, screen} = this.parts;
		sheet.hidden = true;
		game.hidden = false;
		this.#title.textContent = 'Taipei';
		this.#syncClock();
		this.#draw();
		this.#loop.start();
		screen.focus();
		this.say('Phew. Back to Taipei. The clock stood still while the budget was up.');
	}

	#sheetKeyDown(event) {
		const cell = event.target.closest('[data-taipei-cell]');

		if (!cell) {
			return;
		}

		// The arrow keys move between the cells, like in Excel.
		const move = {ArrowLeft: [-1, 0], ArrowRight: [1, 0], ArrowUp: [0, -1], ArrowDown: [0, 1]}[event.key];

		if (!move) {
			return;
		}

		const row = cell.parentElement;
		const rows = [...row.parentElement.parentElement.querySelectorAll('tr')].filter(tableRow => tableRow.querySelector('[data-taipei-cell]'));
		const rowIndex = rows.indexOf(row);
		const cells = [...row.querySelectorAll('[data-taipei-cell]')];
		const columnIndex = cells.indexOf(cell);
		const nextRow = rows[Math.min(Math.max(rowIndex + move[1], 0), rows.length - 1)];
		const nextCells = [...nextRow.querySelectorAll('[data-taipei-cell]')];
		const next = nextCells[Math.min(Math.max(columnIndex + move[0], 0), nextCells.length - 1)];
		event.preventDefault();
		next.focus();
	}

	#selectGame() {
		const {number: numberField, screen} = this.parts;
		const number = Number(numberField.value);

		if (!Number.isInteger(number) || number < 1 || number > 99_999) {
			this.say('Type a game number from 1 to 99999.');
			numberField.focus();
			return;
		}

		this.#deal(this.#game.layout.id, number);
		screen.focus();
	}
}
