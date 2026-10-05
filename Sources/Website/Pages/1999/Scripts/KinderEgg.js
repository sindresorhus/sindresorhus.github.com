// What’s in My Pocket on the 1999 page: a Kinderegg from the Narvesen kiosk to peel, break, eat, open, and build, the shelf of its toys with Trond’s trades, and my light-up yo-yo on a real string. The canvases run only while they are on the screen and the tab is visible. For visitors who prefer reduced motion, nothing moves by itself: each step shows as a still picture. Nothing makes a sound until the visitor turns on the sound. The week, the shelf, and the tricks are kept in the browser.
const randomItem = items => items[Math.floor(Math.random() * items.length)];
const randomBetween = (minimum, maximum) => minimum + (Math.random() * (maximum - minimum));
const clamp = (value, minimum, maximum) => Math.min(Math.max(value, minimum), maximum);
const lerp = (from, to, amount) => from + ((to - from) * amount);
const easeOut = amount => 1 - ((1 - amount) ** 2);
const easeInOut = amount => (amount < 0.5 ? 2 * amount * amount : 1 - (((-2 * amount) + 2) ** 2 / 2));
const distance = (first, second) => Math.hypot(first.x - second.x, first.y - second.y);

const shuffle = items => {
	const result = [...items];
	for (let index = result.length - 1; index > 0; index--) {
		const other = Math.floor(Math.random() * (index + 1));
		[result[index], result[other]] = [result[other], result[index]];
	}

	return result;
};

// Shows a toggle button as pressed, for screen readers and for the style.
const setPressed = (button, isPressed) => {
	button.setAttribute('aria-pressed', String(isPressed));
	button.dataset.state = isPressed ? 'on' : '';
};

// The canvases draw at twice their size, so the round shapes stay sharp on all screens.
const setUpCanvas = (canvas, width, height) => {
	canvas.width = width * 2;
	canvas.height = height * 2;
	const context = canvas.getContext('2d');
	context.setTransform(2, 0, 0, 2, 0, 0);
	return context;
};

const canvasPoint = (canvas, event, width, height) => {
	const bounds = canvas.getBoundingClientRect();
	return {
		x: (event.clientX - bounds.left) * (width / bounds.width),
		y: (event.clientY - bounds.top) * (height / bounds.height),
	};
};

const comicFont = size => `bold ${size}px "Comic Sans MS", "Comic Sans", "Chalkboard SE", "Comic Neue", cursive`;

// MARK: Sound

const audio = {
	context: undefined,
	output: undefined,
	isOn: false,
	// Starts the audio of the element (`sound()`), which is `undefined` when the browser does not allow it yet.
	start(sound) {
		if (!sound) {
			return false;
		}

		if (!this.context) {
			this.context = sound.context;
			this.output = this.context.createGain();
			this.output.gain.value = 0.6;
			this.output.connect(sound.output);
		}

		return true;
	},
	ensure() {
		if (this.context.state === 'suspended') {
			this.context.resume();
		}

		return this.context;
	},
};

// The audio context, only while the visitor has turned on the sound.
const soundContext = () => (audio.isOn ? audio.ensure() : undefined);

const tone = (frequency, delay, duration, {type = 'sine', volume = 0.1, attack = 0.004} = {}) => {
	const context = soundContext();
	if (!context) {
		return;
	}

	const start = context.currentTime + delay;
	const oscillator = context.createOscillator();
	const gain = context.createGain();
	oscillator.type = type;
	oscillator.frequency.value = frequency;
	gain.gain.setValueAtTime(0, start);
	gain.gain.linearRampToValueAtTime(volume, start + attack);
	gain.gain.setValueAtTime(volume, start + Math.max(attack, duration - 0.015));
	gain.gain.linearRampToValueAtTime(0, start + duration);
	oscillator.connect(gain).connect(audio.output);
	oscillator.start(start);
	oscillator.stop(start + duration + 0.05);
};

// A tone that slides from one pitch to another, for zips, pops, and engines.
const slide = (from, to, delay, duration, {type = 'sine', volume = 0.1} = {}) => {
	const context = soundContext();
	if (!context) {
		return;
	}

	const start = context.currentTime + delay;
	const oscillator = context.createOscillator();
	const gain = context.createGain();
	oscillator.type = type;
	oscillator.frequency.setValueAtTime(from, start);
	oscillator.frequency.exponentialRampToValueAtTime(to, start + duration);
	gain.gain.setValueAtTime(0, start);
	gain.gain.linearRampToValueAtTime(volume, start + 0.01);
	gain.gain.setValueAtTime(volume, start + Math.max(0.01, duration - 0.03));
	gain.gain.linearRampToValueAtTime(0, start + duration);
	oscillator.connect(gain).connect(audio.output);
	oscillator.start(start);
	oscillator.stop(start + duration + 0.05);
};

// A short burst of noise, for the foil, the cracks, and the bites.
const noise = (delay, duration, {volume = 0.1, frequency = 3000} = {}) => {
	const context = soundContext();
	if (!context) {
		return;
	}

	const buffer = context.createBuffer(1, Math.ceil(context.sampleRate * duration), context.sampleRate);
	const data = buffer.getChannelData(0);
	for (let index = 0; index < data.length; index++) {
		data[index] = ((Math.random() * 2) - 1) * (1 - (index / data.length));
	}

	const source = context.createBufferSource();
	source.buffer = buffer;
	const filter = context.createBiquadFilter();
	filter.type = 'bandpass';
	filter.frequency.value = frequency;
	const gain = context.createGain();
	gain.gain.value = volume;
	source.connect(filter).connect(gain).connect(audio.output);
	source.start(context.currentTime + delay);
};

const sounds = {
	// Thin foil, which crinkles in many tiny bursts.
	crinkle() {
		for (let index = 0; index < 6; index++) {
			noise(Math.random() * 0.14, randomBetween(0.015, 0.04), {volume: 0.09, frequency: randomBetween(4000, 9000)});
		}
	},
	crack() {
		noise(0, 0.05, {volume: 0.35, frequency: 1800});
		noise(0.03, 0.04, {volume: 0.2, frequency: 2600});
		tone(240, 0, 0.04, {type: 'triangle', volume: 0.1});
	},
	crunch() {
		for (const delay of [0, 0.08, 0.17]) {
			noise(delay, 0.06, {volume: 0.2, frequency: randomBetween(700, 1500)});
		}
	},
	ratchet(delay = 0) {
		noise(delay, 0.012, {volume: 0.18, frequency: 3200});
	},
	pop() {
		slide(260, 900, 0, 0.12, {type: 'triangle', volume: 0.15});
		noise(0, 0.03, {volume: 0.25, frequency: 2500});
	},
	click() {
		tone(1900, 0, 0.025, {type: 'square', volume: 0.04});
		noise(0, 0.02, {volume: 0.15, frequency: 3500});
	},
	wrong() {
		tone(220, 0, 0.12, {type: 'square', volume: 0.04});
		tone(165, 0.13, 0.2, {type: 'square', volume: 0.04});
	},
	paper() {
		noise(0, 0.12, {volume: 0.08, frequency: 6000});
	},
	yay() {
		for (const [index, frequency] of [523, 659, 784, 1047].entries()) {
			tone(frequency, index * 0.09, 0.14, {type: 'square', volume: 0.035});
		}
	},
	vroom() {
		slide(90, 520, 0, 0.8, {type: 'sawtooth', volume: 0.05});
	},
	whirr() {
		slide(900, 260, 0, 3.2, {type: 'triangle', volume: 0.03});
	},
	propeller() {
		for (let index = 0; index < 30; index++) {
			noise(index * 0.09, 0.05, {volume: 0.06, frequency: 300});
		}
	},
	boing() {
		slide(220, 660, 0, 0.14, {type: 'triangle', volume: 0.08});
		slide(660, 260, 0.14, 0.16, {type: 'triangle', volume: 0.08});
	},
	cry() {
		slide(520, 820, 0, 0.45, {type: 'triangle', volume: 0.06});
		slide(820, 420, 0.45, 0.7, {type: 'triangle', volume: 0.06});
	},
	no() {
		tone(196, 0, 0.18, {type: 'triangle', volume: 0.08});
		tone(147, 0.2, 0.3, {type: 'triangle', volume: 0.08});
	},
	zip() {
		slide(240, 900, 0, 0.25, {type: 'triangle', volume: 0.05});
	},
	smack() {
		noise(0, 0.04, {volume: 0.3, frequency: 1200});
		tone(90, 0, 0.07, {volume: 0.2});
	},
	thud() {
		tone(70, 0, 0.1, {volume: 0.2});
		noise(0, 0.05, {volume: 0.12, frequency: 400});
	},
	pick() {
		noise(0, 0.03, {volume: 0.12, frequency: 2200});
	},
	twang() {
		slide(900, 70, 0, 0.4, {type: 'sawtooth', volume: 0.07});
		noise(0, 0.06, {volume: 0.25, frequency: 3000});
	},
};

// The hum of the spinning yo-yo, one tone that follows the spin.
const hum = {
	oscillator: undefined,
	gain: undefined,
};

const setHum = level => {
	if (!audio.isOn || level < 0.05) {
		if (hum.gain) {
			hum.gain.gain.setTargetAtTime(0, audio.context.currentTime, 0.04);
		}

		return;
	}

	const context = audio.ensure();
	if (!context) {
		return;
	}

	if (!hum.oscillator) {
		hum.oscillator = context.createOscillator();
		hum.oscillator.type = 'sawtooth';
		const filter = context.createBiquadFilter();
		filter.type = 'lowpass';
		filter.frequency.value = 700;
		hum.gain = context.createGain();
		hum.gain.gain.value = 0;
		hum.oscillator.connect(filter).connect(hum.gain).connect(audio.output);
		hum.oscillator.start();
	}

	hum.oscillator.frequency.setTargetAtTime(60 + (level * 240), context.currentTime, 0.05);
	hum.gain.gain.setTargetAtTime(level * 0.03, context.currentTime, 0.05);
};

// With reduced motion, the loop does not run, so a short hum tells the spin of a still picture instead.
const blipHum = level => {
	if (level > 0.05) {
		slide(60 + (level * 240), 50 + (level * 120), 0, 0.5, {type: 'triangle', volume: level * 0.05});
	}
};

// MARK: The toys

const series = {
	hippos: {name: 'Happy Hippos', one: 'Happy Hippo', size: 6},
	crocodiles: {name: 'Crocodiles', one: 'crocodile', size: 4},
};

// The toys that can be in an egg. The weight is how often each one comes, so the puzzle comes all the time, and the golden hippo almost never.
const toys = [
	{id: 'puzzle', kind: 'puzzle', short: 'Beach puzzle', name: 'the puzzle of the hippos on the beach', isOrdered: false, weight: 17},
	{id: 'car', kind: 'car', short: 'Race car', name: 'a red race car with stickers', color: '#e8202a', isOrdered: true, weight: 11},
	{id: 'top', kind: 'top', short: 'Spinning top', name: 'a spinning top', isOrdered: true, weight: 10},
	{id: 'plane', kind: 'plane', short: 'Biplane', name: 'a little biplane', color: '#2a6fdb', isOrdered: true, weight: 9},
	{id: 'hippo-surfer', kind: 'figure', animal: 'hippo', series: 'hippos', short: 'Surfer Hippo', color: '#9aa7e0', outfit: 'shorts', accessory: 'surfboard', line: 'Cowabunga!', isOrdered: true, weight: 6},
	{id: 'hippo-waffle', kind: 'figure', animal: 'hippo', series: 'hippos', short: 'Waffle Hippo', color: '#c9a0dc', outfit: 'chef', accessory: 'waffle', line: 'Vafler med brunost!', isOrdered: true, weight: 6},
	{id: 'hippo-rocker', kind: 'figure', animal: 'hippo', series: 'hippos', short: 'Rocker Hippo', color: '#8fc7c0', outfit: 'shades', accessory: 'guitar', line: 'Rock’n’roll!', isOrdered: true, weight: 6},
	{id: 'hippo-skier', kind: 'figure', animal: 'hippo', series: 'hippos', short: 'Ski Hippo', color: '#a8b8d8', outfit: 'lue', accessory: 'skis', line: 'Ut på tur, aldri sur!', isOrdered: true, weight: 6},
	{id: 'hippo-ballerina', kind: 'figure', animal: 'hippo', series: 'hippos', short: 'Ballerina Hippo', color: '#f0a8c8', outfit: 'tutu', accessory: 'wand', line: 'Pirouette!', isOrdered: true, weight: 6},
	{id: 'hippo-golden', kind: 'figure', animal: 'hippo', series: 'hippos', short: 'Golden Hippo', color: '#e8b923', outfit: 'crown', accessory: 'trophy', line: 'I am RARE.', isOrdered: true, isRare: true, weight: 0.8},
	{id: 'croc-pirate', kind: 'figure', animal: 'croc', series: 'crocodiles', short: 'Pirate Croc', color: '#3f9b3a', outfit: 'pirate', accessory: 'sword', line: 'Arrr!', isOrdered: true, weight: 5},
	{id: 'croc-tennis', kind: 'figure', animal: 'croc', series: 'crocodiles', short: 'Tennis Croc', color: '#55b04a', outfit: 'headband', accessory: 'racket', line: 'Game, set, match!', isOrdered: true, weight: 5},
	{id: 'croc-singer', kind: 'figure', animal: 'croc', series: 'crocodiles', short: 'Singer Croc', color: '#2f8a5a', outfit: 'bowtie', accessory: 'microphone', line: 'La la laaa!', isOrdered: true, weight: 5},
	{id: 'croc-skater', kind: 'figure', animal: 'croc', series: 'crocodiles', short: 'Skater Croc', color: '#6bb23a', outfit: 'cap', accessory: 'skateboard', line: 'Rad!', isOrdered: true, weight: 5},
];

const toyById = id => toys.find(toy => toy.id === id);

const pickToy = () => {
	let total = 0;
	for (const toy of toys) {
		total += toy.weight;
	}

	let roll = Math.random() * total;
	for (const toy of toys) {
		roll -= toy.weight;
		if (roll <= 0) {
			return toy;
		}
	}

	return toys[0];
};

// MARK: Drawing helpers

const outline = 'rgba(40, 20, 10, 0.55)';

const fillEllipse = (context, x, y, radiusX, radiusY, color, rotation = 0) => {
	context.beginPath();
	context.ellipse(x, y, radiusX, radiusY, rotation, 0, Math.PI * 2);
	context.fillStyle = color;
	context.fill();
};

const fillRound = (context, x, y, width, height, radius, color) => {
	context.beginPath();
	context.roundRect(x, y, width, height, radius);
	context.fillStyle = color;
	context.fill();
};

const strokeCurrent = (context, color = outline, width = 1) => {
	context.strokeStyle = color;
	context.lineWidth = width;
	context.stroke();
};

const fillStar = (context, x, y, outer, inner, color, points = 5) => {
	context.beginPath();
	for (let index = 0; index < points * 2; index++) {
		const radius = index % 2 === 0 ? outer : inner;
		const angle = (-Math.PI / 2) + ((index * Math.PI) / points);
		context.lineTo(x + (Math.cos(angle) * radius), y + (Math.sin(angle) * radius));
	}

	context.closePath();
	context.fillStyle = color;
	context.fill();
};

const drawLine = (context, points, color, width = 1) => {
	context.beginPath();
	for (const point of points) {
		context.lineTo(point.x, point.y);
	}

	context.strokeStyle = color;
	context.lineWidth = width;
	context.stroke();
};

const drawLabel = (context, text, x, y, {size = 11, color = '#000000', align = 'center', baseline = 'middle'} = {}) => {
	context.font = comicFont(size);
	context.textAlign = align;
	context.textBaseline = baseline;
	context.fillStyle = color;
	context.fillText(text, x, y);
};

// MARK: Drawing the toys

// Each part draws itself in the coordinates of the finished toy, where the middle of the toy is 0, 0, so the finished toy is all its parts at their places.

const drawWheel = (context, x, y, turn = 0) => {
	fillEllipse(context, x, y, 8, 8, '#1a1a1a');
	fillEllipse(context, x, y, 4, 4, '#c8c8c8');
	context.beginPath();
	for (let index = 0; index < 3; index++) {
		const angle = turn + ((index * Math.PI * 2) / 3);
		context.moveTo(x, y);
		context.lineTo(x + (Math.cos(angle) * 4), y + (Math.sin(angle) * 4));
	}

	strokeCurrent(context, '#555555', 1.2);
};

const drawCarBody = (context, toy) => {
	context.beginPath();
	context.moveTo(-34, 4);
	context.lineTo(-34, -6);
	context.quadraticCurveTo(-30, -9, -20, -9);
	context.lineTo(-12, -21);
	context.lineTo(8, -21);
	context.lineTo(18, -9);
	context.quadraticCurveTo(32, -8, 35, -2);
	context.lineTo(35, 4);
	context.closePath();
	context.fillStyle = toy.color;
	context.fill();
	strokeCurrent(context);
	context.beginPath();
	context.moveTo(-9, -18);
	context.lineTo(-2, -18);
	context.lineTo(-2, -10);
	context.lineTo(-16, -10);
	context.closePath();
	context.moveTo(1, -18);
	context.lineTo(7, -18);
	context.lineTo(14, -10);
	context.lineTo(1, -10);
	context.closePath();
	context.fillStyle = '#bfe6ff';
	context.fill();
	fillEllipse(context, 33, -3, 2, 2, '#fff7a0');
};

const drawCarStickers = context => {
	fillEllipse(context, -22, -2, 6, 6, '#ffffff');
	drawLabel(context, '7', -22, -1.5, {size: 9});
	context.beginPath();
	context.moveTo(-8, 3);
	context.lineTo(3, -4);
	context.lineTo(7, 0);
	context.lineTo(15, -6);
	context.lineTo(19, -1);
	context.lineTo(27, -5);
	context.lineTo(31, 3);
	context.closePath();
	context.fillStyle = '#ffd21f';
	context.fill();
};

// The stickers come on a little sheet of paper, until they are on the car.
const drawStickerSheet = context => {
	fillRound(context, -15, -14, 30, 20, 2, '#ffffff');
	context.beginPath();
	context.roundRect(-15, -14, 30, 20, 2);
	strokeCurrent(context, '#999999');
	fillEllipse(context, -7, -4, 5, 5, '#ffffff');
	context.beginPath();
	context.arc(-7, -4, 5, 0, Math.PI * 2);
	strokeCurrent(context, '#cccccc');
	drawLabel(context, '7', -7, -3.5, {size: 8});
	fillStar(context, 7, -4, 6, 3, '#ffd21f');
};

const topColors = ['#e8202a', '#ffd21f', '#2a6fdb', '#33a852'];

const drawTopDisc = (context, toy, {spin = 0} = {}) => {
	fillEllipse(context, 0, 8, 26, 8, '#7a5a2a');
	for (let index = 0; index < 8; index++) {
		const start = spin + ((index * Math.PI) / 4);
		context.beginPath();
		context.moveTo(0, 5);
		context.ellipse(0, 5, 26, 8, 0, start, start + (Math.PI / 4));
		context.closePath();
		context.fillStyle = topColors[index % 4];
		context.fill();
	}

	context.beginPath();
	context.ellipse(0, 5, 26, 8, 0, 0, Math.PI * 2);
	strokeCurrent(context);
};

const drawTopTip = context => {
	context.beginPath();
	context.moveTo(-5, 10);
	context.lineTo(5, 10);
	context.lineTo(0, 22);
	context.closePath();
	context.fillStyle = '#e0e0e0';
	context.fill();
	strokeCurrent(context);
};

const drawTopKnob = context => {
	fillRound(context, -2.5, -16, 5, 20, 2, '#8a5a2b');
	fillEllipse(context, 0, -17, 5, 5, '#e8202a');
	fillEllipse(context, -1.5, -18.5, 1.5, 1.5, '#ffffff');
};

const drawPlaneBody = (context, toy) => {
	fillEllipse(context, -4, -8, 3.5, 3.5, '#f2c29b');
	fillRound(context, -8, -11, 8, 2.5, 1, '#5a3a1a');
	fillEllipse(context, 0, 0, 32, 8, toy.color);
	context.beginPath();
	context.ellipse(0, 0, 32, 8, 0, 0, Math.PI * 2);
	strokeCurrent(context);
	fillRound(context, -22, -1, 42, 2, 1, '#ffffff');
	fillEllipse(context, -4, -5, 6, 2.5, '#bfe6ff');
};

const drawPlaneWings = context => {
	fillRound(context, -16, 3, 34, 5, 2.5, '#ffd21f');
	fillRound(context, -16, -15, 34, 5, 2.5, '#ffd21f');
	drawLine(context, [{x: -10, y: -10}, {x: -10, y: 3}], '#5a3a1a', 1.2);
	drawLine(context, [{x: 12, y: -10}, {x: 12, y: 3}], '#5a3a1a', 1.2);
};

const drawPlaneTail = context => {
	context.beginPath();
	context.moveTo(22, -3);
	context.lineTo(37, -3);
	context.lineTo(37, -19);
	context.closePath();
	context.fillStyle = '#e8202a';
	context.fill();
	strokeCurrent(context);
	fillRound(context, 25, -2, 14, 3, 1.5, '#e8202a');
};

const drawPropeller = (context, toy, {spin = 0} = {}) => {
	const length = (13 * Math.abs(Math.cos(spin))) + 2;
	fillRound(context, -38.5, -length, 3, length * 2, 1.5, '#5a3a1a');
	fillEllipse(context, -37, 0, 3.5, 3.5, '#e8202a');
};

// The picture of the puzzle: two hippos on holiday on a beach, under a parasol.
const drawPuzzlePicture = context => {
	context.fillStyle = '#8fd8ff';
	context.fillRect(-40, -30, 80, 22);
	fillEllipse(context, 27, -21, 6, 6, '#ffe14d');
	context.fillStyle = '#2a8fd8';
	context.fillRect(-40, -8, 80, 10);
	drawLine(context, [{x: -30, y: -4}, {x: -26, y: -6}, {x: -22, y: -4}], '#ffffff', 1);
	drawLine(context, [{x: 6, y: -3}, {x: 10, y: -5}, {x: 14, y: -3}], '#ffffff', 1);
	context.fillStyle = '#f4d58a';
	context.fillRect(-40, 2, 80, 28);
	drawLine(context, [{x: -22, y: -12}, {x: -22, y: 18}], '#6b4a1a', 1.5);
	context.beginPath();
	context.ellipse(-22, -12, 15, 8, 0, Math.PI, Math.PI * 2);
	context.fillStyle = '#e8202a';
	context.fill();
	context.beginPath();
	context.moveTo(-22, -12);
	context.lineTo(-26, -19);
	context.lineTo(-18, -19);
	context.closePath();
	context.fillStyle = '#ffffff';
	context.fill();
	fillRound(context, -12, 14, 26, 8, 2, '#ff77aa');
	fillEllipse(context, -2, 15, 10, 6, '#9aa7e0');
	fillEllipse(context, 8, 11, 6, 5, '#9aa7e0');
	fillRound(context, 5, 9, 9, 2.5, 1, '#000000');
	fillEllipse(context, 26, 20, 8, 6, '#c9a0dc');
	fillEllipse(context, 32, 15, 5, 4, '#c9a0dc');
	fillEllipse(context, 33, 13, 1, 1, '#000000');
};

const puzzleCorner = index => ({x: index % 2 === 0 ? -40 : 0, y: index < 2 ? -30 : 0});

const drawPuzzlePiece = (context, index) => {
	const corner = puzzleCorner(index);
	context.save();
	context.beginPath();
	context.rect(corner.x, corner.y, 40, 30);
	context.clip();
	drawPuzzlePicture(context);
	context.restore();
	context.strokeStyle = '#6b4a1a';
	context.lineWidth = 1.2;
	context.strokeRect(corner.x + 0.5, corner.y + 0.5, 39, 29);
};

const drawHippo = (context, toy) => {
	const light = 'rgba(255, 255, 255, 0.35)';
	fillRound(context, -12, 15, 9, 9, 3, toy.color);
	fillRound(context, 3, 15, 9, 9, 3, toy.color);
	fillEllipse(context, -15, 4, 4, 7, toy.color, 0.3);
	fillEllipse(context, 15, 4, 4, 7, toy.color, -0.3);
	fillEllipse(context, 0, 6, 16, 14, toy.color);
	context.beginPath();
	context.ellipse(0, 6, 16, 14, 0, 0, Math.PI * 2);
	strokeCurrent(context);
	fillEllipse(context, 0, 8, 10, 9, light);
	fillEllipse(context, -9, -22, 3.5, 3.5, toy.color);
	fillEllipse(context, 9, -22, 3.5, 3.5, toy.color);
	fillEllipse(context, 0, -13, 14, 11, toy.color);
	context.beginPath();
	context.ellipse(0, -13, 14, 11, 0, 0, Math.PI * 2);
	strokeCurrent(context);
	fillEllipse(context, 0, -6, 12, 7, toy.color);
	fillEllipse(context, 0, -6, 12, 7, light);
	fillEllipse(context, -4, -7, 1.3, 1.6, '#333333');
	fillEllipse(context, 4, -7, 1.3, 1.6, '#333333');
	fillEllipse(context, -5, -16, 3, 3, '#ffffff');
	fillEllipse(context, 5, -16, 3, 3, '#ffffff');
	fillEllipse(context, -4.5, -16, 1.5, 1.5, '#000000');
	fillEllipse(context, 5.5, -16, 1.5, 1.5, '#000000');
	drawLine(context, [{x: -4, y: -2}, {x: 0, y: 0}, {x: 4, y: -2}], '#333333', 1);
	drawOutfit(context, toy);
};

const drawCrocodile = (context, toy) => {
	const light = 'rgba(255, 255, 160, 0.4)';
	context.beginPath();
	context.moveTo(-8, 14);
	context.lineTo(-28, 22);
	context.lineTo(-6, 22);
	context.closePath();
	context.fillStyle = toy.color;
	context.fill();
	fillRound(context, -11, 17, 9, 8, 3, toy.color);
	fillRound(context, 2, 17, 9, 8, 3, toy.color);
	fillEllipse(context, -13, 2, 3.5, 7, toy.color, 0.3);
	fillEllipse(context, 13, 2, 3.5, 7, toy.color, -0.3);
	fillEllipse(context, 0, 6, 13, 16, toy.color);
	context.beginPath();
	context.ellipse(0, 6, 13, 16, 0, 0, Math.PI * 2);
	strokeCurrent(context);
	fillEllipse(context, 0, 8, 8, 12, light);
	for (const y of [2, 7, 12]) {
		drawLine(context, [{x: -6, y}, {x: 6, y}], 'rgba(0, 60, 0, 0.3)', 1);
	}

	fillRound(context, -11, -26, 36, 14, 6, toy.color);
	context.beginPath();
	context.roundRect(-11, -26, 36, 14, 6);
	strokeCurrent(context);
	drawLine(context, [{x: -4, y: -17}, {x: 24, y: -17}], '#1f4a1a', 1);
	context.beginPath();
	for (let x = 0; x < 22; x += 4) {
		context.moveTo(x, -17);
		context.lineTo(x + 2, -14.5);
		context.lineTo(x + 4, -17);
	}

	context.fillStyle = '#ffffff';
	context.fill();
	fillEllipse(context, 22, -23, 1, 1, '#1f4a1a');
	fillEllipse(context, -3, -28, 4, 4, toy.color);
	fillEllipse(context, 5, -28, 4, 4, toy.color);
	fillEllipse(context, -3, -28.5, 2.5, 2.5, '#ffffff');
	fillEllipse(context, 5, -28.5, 2.5, 2.5, '#ffffff');
	fillEllipse(context, -2.5, -28.5, 1.2, 1.4, '#000000');
	fillEllipse(context, 5.5, -28.5, 1.2, 1.4, '#000000');
	drawOutfit(context, toy);
};

// The clothes and hats of the figures, which are painted on, not parts.
const drawOutfit = (context, toy) => {
	switch (toy.outfit) {
		case 'shorts': {
			fillRound(context, -15, 10, 30, 9, 3, '#ff8a1f');
			for (const x of [-9, 0, 9]) {
				fillStar(context, x, 14, 2.5, 1, '#ffffff');
			}

			break;
		}

		case 'chef': {
			fillRound(context, -8, -32, 16, 9, 2, '#ffffff');
			for (const x of [-5, 0, 5]) {
				fillEllipse(context, x, -33, 4.5, 4.5, '#ffffff');
			}

			context.beginPath();
			context.roundRect(-8, -32, 16, 9, 2);
			strokeCurrent(context, '#bbbbbb');
			break;
		}

		case 'shades': {
			fillRound(context, -9, -19, 8, 5, 2, '#111111');
			fillRound(context, 1, -19, 8, 5, 2, '#111111');
			drawLine(context, [{x: -1, y: -17}, {x: 1, y: -17}], '#111111', 1.2);
			drawLine(context, [{x: -5, y: -24}, {x: -2, y: -29}, {x: 0, y: -24}, {x: 3, y: -30}, {x: 5, y: -24}], '#222222', 2);
			break;
		}

		case 'lue': {
			context.beginPath();
			context.ellipse(0, -21, 13, 9, 0, Math.PI, Math.PI * 2);
			context.fillStyle = '#d4001a';
			context.fill();
			fillRound(context, -13, -23, 26, 4, 2, '#ffffff');
			fillEllipse(context, 0, -31, 4, 4, '#ffffff');
			break;
		}

		case 'tutu': {
			context.beginPath();
			for (let index = 0; index <= 16; index++) {
				const angle = (index / 16) * Math.PI * 2;
				const radius = index % 2 === 0 ? 23 : 18;
				context.lineTo(Math.cos(angle) * radius, 11 + (Math.sin(angle) * radius * 0.25));
			}

			context.fillStyle = 'rgba(255, 150, 200, 0.85)';
			context.fill();
			break;
		}

		case 'crown': {
			context.beginPath();
			context.moveTo(-9, -22);
			context.lineTo(-9, -31);
			context.lineTo(-4, -26);
			context.lineTo(0, -33);
			context.lineTo(4, -26);
			context.lineTo(9, -31);
			context.lineTo(9, -22);
			context.closePath();
			context.fillStyle = '#ffd700';
			context.fill();
			strokeCurrent(context, '#a07800');
			fillEllipse(context, 0, -26, 1.5, 1.5, '#e8202a');
			fillRound(context, -9, -19, 8, 5, 2, '#111111');
			fillRound(context, 1, -19, 8, 5, 2, '#111111');
			for (const [x, y] of [[-18, -10], [18, 0], [-14, 18]]) {
				fillStar(context, x, y, 3, 1, '#ffffff', 4);
			}

			break;
		}

		case 'pirate': {
			context.beginPath();
			context.ellipse(1, -30, 12, 6, 0, Math.PI, Math.PI * 2);
			context.fillStyle = '#d4001a';
			context.fill();
			for (const [x, y] of [[-4, -33], [4, -33]]) {
				fillEllipse(context, x, y, 1, 1, '#ffffff');
			}

			fillEllipse(context, 5, -28.5, 3, 3, '#111111');
			drawLine(context, [{x: -8, y: -32}, {x: 12, y: -25}], '#111111', 1);
			break;
		}

		case 'headband': {
			fillRound(context, -9, -32, 20, 3.5, 1.5, '#ffffff');
			fillRound(context, -9, -32, 20, 1.2, 0.6, '#d4001a');
			break;
		}

		case 'bowtie': {
			context.beginPath();
			context.moveTo(0, -9);
			context.lineTo(-7, -13);
			context.lineTo(-7, -5);
			context.closePath();
			context.moveTo(0, -9);
			context.lineTo(7, -13);
			context.lineTo(7, -5);
			context.closePath();
			context.fillStyle = '#d4001a';
			context.fill();
			fillEllipse(context, 0, -9, 2, 2, '#a00010');
			break;
		}

		case 'cap': {
			context.beginPath();
			context.ellipse(1, -30, 11, 6, 0, Math.PI, Math.PI * 2);
			context.fillStyle = '#2a4fa0';
			context.fill();
			fillRound(context, -18, -32, 10, 3, 1.5, '#2a4fa0');
			break;
		}

		default: {
			break;
		}
	}
};

// The little things that the figures hold, which come as a separate part.
const accessories = {
	surfboard: {
		name: 'the surfboard',
		center: {x: 25, y: 2},
		draw(context) {
			fillEllipse(context, 25, 2, 5, 22, '#ffd21f', 0.15);
			fillEllipse(context, 25, 2, 1.5, 20, '#e8202a', 0.15);
		},
	},
	waffle: {
		name: 'the waffle with brunost',
		center: {x: -25, y: 6},
		draw(context) {
			for (let index = 0; index < 5; index++) {
				const angle = (index / 5) * Math.PI * 2;
				fillEllipse(context, -25 + (Math.cos(angle) * 5), 6 + (Math.sin(angle) * 5), 5, 5, '#e6b35a');
			}

			fillRound(context, -29, 2, 8, 6, 1, '#b5651d');
			drawLine(context, [{x: -31, y: 6}, {x: -19, y: 6}], 'rgba(120, 70, 20, 0.5)', 0.8);
		},
	},
	guitar: {
		name: 'the guitar',
		center: {x: 17, y: 6},
		draw(context) {
			drawLine(context, [{x: 14, y: 8}, {x: 30, y: -12}], '#5a3a1a', 3);
			fillEllipse(context, 12, 10, 7, 6, '#e8202a', -0.8);
			fillEllipse(context, 16, 5, 5, 4, '#e8202a', -0.8);
			fillEllipse(context, 13, 9, 1.8, 1.8, '#111111');
		},
	},
	skis: {
		name: 'the skis',
		center: {x: 0, y: 26},
		draw(context) {
			fillRound(context, -28, 23, 50, 3, 1.5, '#d4001a');
			fillRound(context, -22, 27, 50, 3, 1.5, '#2a4fa0');
			drawLine(context, [{x: 23, y: 22}, {x: 26, y: 29}], '#d4001a', 2);
		},
	},
	wand: {
		name: 'the magic wand',
		center: {x: 21, y: -6},
		draw(context) {
			drawLine(context, [{x: 16, y: 4}, {x: 23, y: -10}], '#ffffff', 2);
			fillStar(context, 24, -13, 7, 3, '#ffe14d');
		},
	},
	trophy: {
		name: 'the golden trophy',
		center: {x: 23, y: 0},
		draw(context) {
			context.beginPath();
			context.moveTo(16, -8);
			context.lineTo(30, -8);
			context.lineTo(27, 2);
			context.lineTo(19, 2);
			context.closePath();
			context.fillStyle = '#ffd700';
			context.fill();
			strokeCurrent(context, '#a07800');
			fillRound(context, 21, 2, 4, 5, 1, '#ffd700');
			fillRound(context, 17, 7, 12, 3, 1, '#a07800');
		},
	},
	sword: {
		name: 'the sword',
		center: {x: 19, y: 2},
		draw(context) {
			fillRound(context, 18, -16, 3, 20, 1, '#d8d8e0');
			fillRound(context, 14, 4, 11, 2.5, 1, '#a07800');
			fillRound(context, 18, 6, 3, 6, 1, '#5a3a1a');
		},
	},
	racket: {
		name: 'the tennis racket',
		center: {x: 21, y: -2},
		draw(context) {
			drawLine(context, [{x: 16, y: 8}, {x: 21, y: -2}], '#5a3a1a', 2.5);
			context.beginPath();
			context.ellipse(24, -9, 6, 8, 0.4, 0, Math.PI * 2);
			context.fillStyle = 'rgba(255, 255, 255, 0.6)';
			context.fill();
			strokeCurrent(context, '#e8202a', 2);
		},
	},
	microphone: {
		name: 'the microphone',
		center: {x: 17, y: -4},
		draw(context) {
			fillRound(context, 15, -4, 3.5, 12, 1.5, '#333333');
			fillEllipse(context, 16.75, -7, 4.5, 4.5, '#aaaaaa');
			context.beginPath();
			context.arc(16.75, -7, 4.5, 0, Math.PI * 2);
			strokeCurrent(context, '#555555');
		},
	},
	skateboard: {
		name: 'the skateboard',
		center: {x: 0, y: 27},
		draw(context) {
			fillRound(context, -22, 24, 44, 4, 2, '#e8202a');
			fillEllipse(context, -14, 30, 2.5, 2.5, '#ffd21f');
			fillEllipse(context, 14, 30, 2.5, 2.5, '#ffd21f');
		},
	},
};

const partCache = new Map();

// The parts of a toy, in the order of the paper.
const partsOf = toy => {
	if (partCache.has(toy.id)) {
		return partCache.get(toy.id);
	}

	let parts;
	switch (toy.kind) {
		case 'car': {
			parts = [
				{name: 'the chassis', center: {x: 0, y: 7}, radius: 22, draw(context) {
					fillRound(context, -34, 3, 68, 8, 3, '#3a3a3a');
				}},
				{name: 'the back wheels', center: {x: -22, y: 13}, radius: 12, draw(context, _toy, {turn = 0} = {}) {
					drawWheel(context, -22, 13, turn);
				}},
				{name: 'the front wheels', center: {x: 22, y: 13}, radius: 12, draw(context, _toy, {turn = 0} = {}) {
					drawWheel(context, 22, 13, turn);
				}},
				{name: 'the body', center: {x: 0, y: -8}, radius: 22, draw: drawCarBody},
				{name: 'the stickers', center: {x: 0, y: -4}, radius: 16, draw: drawCarStickers, drawLoose: drawStickerSheet},
			];
			break;
		}

		case 'top': {
			parts = [
				{name: 'the disc', center: {x: 0, y: 5}, radius: 22, draw: drawTopDisc},
				{name: 'the tip', center: {x: 0, y: 16}, radius: 12, draw: drawTopTip},
				{name: 'the knob', center: {x: 0, y: -8}, radius: 14, draw: drawTopKnob},
			];
			break;
		}

		case 'plane': {
			parts = [
				{name: 'the body', center: {x: 0, y: 0}, radius: 24, draw: drawPlaneBody},
				{name: 'the wings', center: {x: 1, y: -4}, radius: 18, draw: drawPlaneWings},
				{name: 'the tail', center: {x: 31, y: -9}, radius: 12, draw: drawPlaneTail},
				{name: 'the propeller', center: {x: -37, y: 0}, radius: 12, draw: drawPropeller},
			];
			break;
		}

		case 'puzzle': {
			parts = [0, 1, 2, 3].map(index => {
				const corner = puzzleCorner(index);
				return {
					name: `piece ${index + 1}`,
					center: {x: corner.x + 20, y: corner.y + 15},
					radius: 18,
					draw(context) {
						drawPuzzlePiece(context, index);
					},
				};
			});
			break;
		}

		default: {
			const accessory = accessories[toy.accessory];
			parts = [
				{name: toy.animal === 'hippo' ? 'the hippo' : 'the crocodile', center: {x: 0, y: 0}, radius: 22, draw: toy.animal === 'hippo' ? drawHippo : drawCrocodile},
				{name: accessory.name, center: accessory.center, radius: 14, draw: accessory.draw},
			];
			break;
		}
	}

	partCache.set(toy.id, parts);
	return parts;
};

// Draws one part with its middle at a point, like on the table before it is put on.
const drawPart = (context, toy, part, x, y, {isLoose = false, scale = 1, ...options} = {}) => {
	context.save();
	context.translate(x, y);
	context.scale(scale, scale);
	context.translate(-part.center.x, -part.center.y);
	(isLoose && part.drawLoose ? part.drawLoose : part.draw)(context, toy, options);
	context.restore();
};

const drawToy = (context, toy, x, y, {scale = 1, ...options} = {}) => {
	context.save();
	context.translate(x, y);
	context.scale(scale, scale);
	for (const part of partsOf(toy)) {
		part.draw(context, toy, options);
	}

	context.restore();
};

// MARK: The element

export default class extends GeoCitiesElement {
	#state;
	#redrawEgg;
	#redrawYoyo;

	connected() {
		this.#state = this.#loadState();

		const {sound: soundButton} = this.parts;
		this.on(soundButton, 'click', () => {
			audio.isOn = !audio.isOn && audio.start(this.sound());
			setPressed(soundButton, audio.isOn);
			if (audio.isOn) {
				audio.ensure();
				sounds.crinkle();
			} else {
				setHum(0);
			}
		});
		setPressed(soundButton, audio.isOn);

		const renderShelf = this.#setUpShelf();
		this.#setUpEgg(renderShelf);
		this.#setUpYoyo();
	}

	// With reduced motion, the pieces in the air are gone, and both canvases show a still picture. The base class starts the loops again.
	reducedMotionChanged() {
		this.#redrawEgg();
		this.#redrawYoyo();
	}

	// A button that hides while it has the focus gives it to the button that takes its place: the next step of the egg, Tug! for the knot, and after a trade the doubles, or the shelf when no double is left.
	focusReplacement(control) {
		const {extra, sister, eggAction, untangle, tug, offer, doubles, shelf} = this.parts;
		if (control === extra || sister.contains(control)) {
			return eggAction;
		}

		if (control === untangle) {
			return tug;
		}

		if (offer.contains(control)) {
			return doubles.querySelector('button') ?? shelf.closest('section');
		}

		return super.focusReplacement(control);
	}

	#loadState() {
		const state = {
			week: 14,
			year: 1999,
			eggsLeft: 1,
			begs: 0,
			hasExtraThisWeek: false,
			eggsOpened: 0,
			pending: undefined,
			collection: {},
			sisterToys: [],
			junk: [],
			tricks: [],
			throws: 0,
			wear: 0,
			bestRow: 0,
			...this.stored('state', {}),
		};

		if (typeof state.collection !== 'object' || state.collection === null || Array.isArray(state.collection)) {
			state.collection = {};
		}

		// A broken number in the storage would, for example, give endless eggs, so it starts over.
		for (const [key, fallback] of Object.entries({week: 14, year: 1999, eggsLeft: 1, begs: 0, eggsOpened: 0, throws: 0, wear: 0, bestRow: 0})) {
			if (!Number.isFinite(state[key])) {
				state[key] = fallback;
			}
		}

		for (const key of ['sisterToys', 'junk', 'tricks']) {
			if (!Array.isArray(state[key])) {
				state[key] = [];
			}
		}

		return state;
	}

	#save() {
		this.store('state', this.#state);
	}

	// A broken count in the storage would add up to text, so it counts as none.
	#countOf(id) {
		const count = this.#state.collection[id];
		return Number.isInteger(count) && count > 0 ? count : 0;
	}

	#seriesProgress(name) {
		return toys.filter(toy => toy.series === name && this.#countOf(toy.id) > 0).length;
	}

	// MARK: The egg

	#setUpEgg(renderShelf) {
		const {egg: eggCanvas, eggAction: actionButton, extra: extraButton, beg: begButton, saturday: saturdayButton, sister: sisterBox, sisterText, sisterGive: sisterGiveButton, sisterKeep: sisterKeepButton, eggStatus, week: weekLine} = this.parts;
		const state = this.#state;

		const eggWidth = 320;
		const eggHeight = 260;
		const eggContext = setUpCanvas(eggCanvas, eggWidth, eggHeight);
		const layer = document.createElement('canvas');
		const layerContext = setUpCanvas(layer, eggWidth, eggHeight);

		const eggCenter = {x: 160, y: 126};
		const eggRadius = {x: 58, y: 74};
		const halfPlaces = [{x: 82, y: 146}, {x: 238, y: 146}];
		const smallCapsule = {x: 160, y: 150};
		const buildSpot = {x: 165, y: 104};

		// The parts are small in the capsule, but the toy is built bigger, so it is easy to see.
		const buildScale = 1.5;
		const paperSpot = {x: 34, y: 34};
		const shellSpot = {x: 286, y: 34};
		const looseSpots = [{x: 42, y: 214}, {x: 100, y: 224}, {x: 160, y: 214}, {x: 220, y: 224}, {x: 278, y: 214}];

		const egg = {
			stage: 'kiosk',
			toy: undefined,
			isNew: true,
			cells: [],
			cracks: 0,
			bites: [0, 0],
			twist: 0,
			paper: {folds: 3, isOpen: false},
			items: [],
			dragging: undefined,
			animation: undefined,
			play: undefined,
			pieces: [],
			lastCrinkle: 0,
			lastRatchet: 0,
			saidHalf: false,
			shelvedAt: 0,
		};

		// The grain of the pine of the kitchen table, made once, so it stays the same.
		const grain = Array.from({length: 18}, () => ({
			y: randomBetween(0, eggHeight),
			wave: randomBetween(2, 6),
			phase: randomBetween(0, Math.PI * 2),
			alpha: randomBetween(0.06, 0.16),
		}));

		const drawTable = context => {
			const gradient = context.createLinearGradient(0, 0, 0, eggHeight);
			gradient.addColorStop(0, '#e2bd86');
			gradient.addColorStop(1, '#c99a5c');
			context.fillStyle = gradient;
			context.fillRect(0, 0, eggWidth, eggHeight);
			for (const line of grain) {
				context.beginPath();
				for (let x = 0; x <= eggWidth; x += 16) {
					context.lineTo(x, line.y + (Math.sin((x / 40) + line.phase) * line.wave));
				}

				strokeCurrent(context, `rgba(110, 60, 20, ${line.alpha})`, 1.2);
			}

			for (const y of [86, 173]) {
				drawLine(context, [{x: 0, y}, {x: eggWidth, y}], 'rgba(90, 50, 15, 0.35)', 1.5);
			}
		};

		const progressOf = (name, now) => {
			const animation = egg.animation;
			if (this.reducedMotion || !animation || animation.name !== name) {
				return 1;
			}

			return clamp((now - animation.start) / animation.duration, 0, 1);
		};

		const startAnimation = (name, duration) => {
			egg.animation = {name, start: performance.now(), duration};
			eggLoop.start();
		};

		// The note from Mamma on the table, and the money for the egg of the week.
		const drawKiosk = context => {
			context.save();
			context.translate(160, 92);
			context.rotate(-0.05);
			context.shadowColor = 'rgba(0, 0, 0, 0.25)';
			context.shadowOffsetY = 3;
			context.shadowBlur = 4;
			fillRound(context, -88, -46, 176, 92, 2, '#fff59a');
			context.shadowColor = 'transparent';
			drawLabel(context, 'Ett Kinderegg i uka!', 0, -22, {size: 15, color: '#1a2a8a'});
			drawLabel(context, '(One a week!)', 0, -2, {size: 10, color: '#1a2a8a'});
			drawLabel(context, 'Klem, Mamma ♥', 0, 22, {size: 13, color: '#c0002a'});
			context.restore();

			if (state.eggsLeft > 0) {
				// A 5 kroner coin and four of 1 krone, for the 9 kroner of an egg.
				const coins = [{x: 120, y: 196, radius: 13}, {x: 152, y: 204, radius: 10}, {x: 176, y: 194, radius: 10}, {x: 198, y: 207, radius: 10}, {x: 220, y: 196, radius: 10}];
				for (const coin of coins) {
					const gradient = context.createRadialGradient(coin.x - 3, coin.y - 3, 1, coin.x, coin.y, coin.radius);
					gradient.addColorStop(0, '#ffffff');
					gradient.addColorStop(1, '#8d939a');
					fillEllipse(context, coin.x, coin.y, coin.radius, coin.radius, gradient);
					fillEllipse(context, coin.x, coin.y, coin.radius * 0.28, coin.radius * 0.28, '#c99a5c');
				}

				drawLabel(context, '9 kr', 260, 200, {size: 12, color: '#5a3a1a'});
			} else {
				// The empty foil of the egg of the week, crumpled in a ball.
				context.beginPath();
				for (let index = 0; index < 14; index++) {
					const angle = (index / 14) * Math.PI * 2;
					const radius = index % 2 === 0 ? 16 : 11;
					context.lineTo(160 + (Math.cos(angle) * radius), 200 + (Math.sin(angle) * radius));
				}

				context.closePath();
				context.fillStyle = '#f07a1a';
				context.fill();
				fillEllipse(context, 155, 195, 7, 5, '#f4f4f6');
				drawLabel(context, 'No more eggs this week…', 160, 240, {size: 11, color: '#5a3a1a'});
			}
		};

		const drawChocolateEgg = (context, x, y, radiusX, radiusY) => {
			const gradient = context.createRadialGradient(x - (radiusX * 0.35), y - (radiusY * 0.4), 4, x, y, radiusY * 1.1);
			gradient.addColorStop(0, '#b0714a');
			gradient.addColorStop(0.6, '#7a4324');
			gradient.addColorStop(1, '#4a2410');
			fillEllipse(context, x, y, radiusX, radiusY, gradient);
			fillEllipse(context, x - (radiusX * 0.35), y - (radiusY * 0.45), radiusX * 0.22, radiusY * 0.15, 'rgba(255, 230, 200, 0.3)', -0.5);
		};

		const makeFoil = () => {
			const cells = [];
			const columns = 8;
			const rows = 10;
			const width = (eggRadius.x * 2) / columns;
			const height = (eggRadius.y * 2) / rows;
			for (let row = 0; row < rows; row++) {
				for (let column = 0; column < columns; column++) {
					const x = eggCenter.x - eggRadius.x + (column * width);
					const y = eggCenter.y - eggRadius.y + (row * height);
					const centerX = (x + (width / 2) - eggCenter.x) / eggRadius.x;
					const centerY = (y + (height / 2) - eggCenter.y) / eggRadius.y;
					if (Math.hypot(centerX, centerY) < 1.12) {
						cells.push({x, y, width, height, column, row, isOn: true});
					}
				}
			}

			return cells;
		};

		// The foil of the egg: white on top with the name written plainly, and orange with white stars at the bottom.
		const drawFoilDesign = context => {
			const {x, y} = eggCenter;
			const top = y - eggRadius.y;
			context.fillStyle = '#f4f4f6';
			context.fillRect(x - 60, top, 120, 150);
			const orange = context.createLinearGradient(0, y + 8, 0, y + 74);
			orange.addColorStop(0, '#ff8a1f');
			orange.addColorStop(1, '#d9500a');
			context.fillStyle = orange;
			context.fillRect(x - 60, y + 10, 120, 70);
			context.fillStyle = '#ff8a1f';
			context.fillRect(x - 60, y - 38, 120, 3);
			drawLabel(context, 'Kinderegg', x, y - 14, {size: 18, color: '#1a2a8a'});
			drawLabel(context, 'med overraskelse!', x, y + 1, {size: 8, color: '#1a2a8a'});
			for (const [starX, starY] of [[-28, 26], [6, 22], [30, 34], [-12, 44], [18, 54], [-34, 52], [0, 64]]) {
				fillStar(context, x + starX, y + starY, 4, 1.7, '#ffffff');
			}

			const shine = context.createRadialGradient(x - 24, y - 40, 2, x - 24, y - 40, 44);
			shine.addColorStop(0, 'rgba(255, 255, 255, 0.85)');
			shine.addColorStop(1, 'rgba(255, 255, 255, 0)');
			context.fillStyle = shine;
			context.fillRect(x - 60, top, 120, 150);
			for (const [fromX, fromY, toX, toY] of [[-40, -30, -10, -24], [10, -50, 34, -40], [-30, 30, 0, 40], [20, 10, 44, 20]]) {
				drawLine(context, [{x: x + fromX, y: y + fromY}, {x: x + toX, y: y + toY}], 'rgba(0, 0, 0, 0.12)', 0.8);
			}
		};

		const drawFoil = context => {
			context.save();
			context.beginPath();
			context.ellipse(eggCenter.x, eggCenter.y, eggRadius.x + 1, eggRadius.y + 1, 0, 0, Math.PI * 2);
			context.clip();
			context.beginPath();
			for (const cell of egg.cells) {
				if (cell.isOn) {
					context.rect(cell.x - 0.4, cell.y - 0.4, cell.width + 0.8, cell.height + 0.8);
				}
			}

			context.clip();
			drawFoilDesign(context);
			context.restore();
		};

		const foilColorAt = y => (y > eggCenter.y + 10 ? '#f07a1a' : '#f4f4f6');

		const spawnPiece = (x, y, color, kind) => {
			if (this.reducedMotion) {
				return;
			}

			egg.pieces.push({
				x,
				y,
				velocityX: randomBetween(-70, 70),
				velocityY: kind === 'foil' ? randomBetween(-140, -30) : randomBetween(-90, 10),
				rotation: randomBetween(0, Math.PI * 2),
				spin: randomBetween(-9, 9),
				size: kind === 'foil' ? randomBetween(5, 9) : randomBetween(1.5, 3.5),
				corners: Array.from({length: 6}, () => randomBetween(0.55, 1)),
				color,
				kind,
				age: 0,
			});
		};

		const spawnCrumbs = (x, y, count) => {
			for (let index = 0; index < count; index++) {
				spawnPiece(x + randomBetween(-10, 10), y + randomBetween(-8, 8), randomItem(['#5a2e14', '#7a4324', '#f6ecd6']), 'crumb');
			}
		};

		const drawPieces = context => {
			for (const piece of egg.pieces) {
				context.save();
				context.translate(piece.x, piece.y);
				context.rotate(piece.rotation);
				context.beginPath();
				for (const [index, corner] of piece.corners.entries()) {
					const angle = (index / piece.corners.length) * Math.PI * 2;
					context.lineTo(Math.cos(angle) * piece.size * corner, Math.sin(angle) * piece.size * corner);
				}

				context.closePath();
				context.fillStyle = piece.color;
				context.fill();
				if (piece.kind === 'foil') {
					strokeCurrent(context, 'rgba(150, 150, 160, 0.8)', 0.6);
				}

				context.restore();
			}
		};

		const tearCell = cell => {
			if (!cell.isOn) {
				return;
			}

			cell.isOn = false;
			spawnPiece(cell.x + (cell.width / 2), cell.y + (cell.height / 2), foilColorAt(cell.y + (cell.height / 2)), 'foil');
		};

		const crinkle = () => {
			const now = performance.now();
			if (now - egg.lastCrinkle > 110) {
				egg.lastCrinkle = now;
				sounds.crinkle();
			}
		};

		const checkFoil = () => {
			const left = egg.cells.filter(cell => cell.isOn);
			if (left.length > egg.cells.length * 0.12) {
				if (left.length < egg.cells.length * 0.5 && !egg.saidHalf) {
					egg.saidHalf = true;
					this.say('Halfway! It smells of chocolate already.', eggStatus);
				}

				return;
			}

			for (const cell of left) {
				tearCell(cell);
			}

			egg.stage = 'chocolate';
			egg.cracks = 0;
			sounds.crinkle();
			this.say('The last bits of foil fall off. A shiny chocolate egg! Click it to crack it.', eggStatus);
			renderEgg();
		};

		const distanceToSegment = (point, from, to) => {
			const lengthSquared = ((to.x - from.x) ** 2) + ((to.y - from.y) ** 2);
			if (lengthSquared === 0) {
				return distance(point, from);
			}

			const amount = clamp((((point.x - from.x) * (to.x - from.x)) + ((point.y - from.y) * (to.y - from.y))) / lengthSquared, 0, 1);
			return distance(point, {x: from.x + (amount * (to.x - from.x)), y: from.y + (amount * (to.y - from.y))});
		};

		// A drag over the foil tears off the cells under the finger, and the foil tears on downward in strips, like real foil.
		const peelAlong = (from, to) => {
			let count = 0;
			for (const cell of egg.cells) {
				const middle = {x: cell.x + (cell.width / 2), y: cell.y + (cell.height / 2)};
				if (cell.isOn && distanceToSegment(middle, from, to) < 11) {
					tearCell(cell);
					count++;
					let below = egg.cells.find(other => other.column === cell.column && other.row === cell.row + 1);
					while (below?.isOn && Math.random() < 0.5) {
						tearCell(below);
						below = egg.cells.find(other => other.column === below.column && other.row === below.row + 1);
					}
				}
			}

			if (count > 0) {
				crinkle();
				eggLoop.start();
				checkFoil();
				drawEgg();
			}
		};

		// The button tears two columns at a time, so the egg is peeled in a few clicks, about as fast as with a drag.
		const peelStrip = () => {
			const columns = [...new Set(egg.cells.filter(cell => cell.isOn).map(cell => cell.column))];
			const column = randomItem(columns);
			const neighbor = columns.includes(column + 1) ? column + 1 : column - 1;
			for (const cell of egg.cells) {
				if (cell.column === column || cell.column === neighbor) {
					tearCell(cell);
				}
			}

			sounds.crinkle();
			eggLoop.start();
			this.say(randomItem(['Rrrip! A strip of foil comes off.', 'Krrsj! The foil tears in a long strip.', 'Another strip. The foil sticks to my fingers.']), eggStatus);
			checkFoil();
			drawEgg();
		};

		const crackEgg = () => {
			sounds.crack();
			if (egg.cracks === 0) {
				egg.cracks = 1;
				spawnCrumbs(eggCenter.x, eggCenter.y, 6);
				this.say('Krakk! A crack along the middle. One more!', eggStatus);
			} else {
				egg.stage = 'halves';
				egg.bites = [0, 0];
				spawnCrumbs(eggCenter.x, eggCenter.y - 30, 10);
				spawnCrumbs(eggCenter.x, eggCenter.y + 30, 10);
				startAnimation('split', 500);
				this.say('It breaks in two! White milk cream inside, and the yellow capsule. Eat the chocolate, or take out the capsule.', eggStatus);
			}

			eggLoop.start();
			renderEgg();
		};

		const drawCrack = context => {
			const points = [];
			for (let y = eggCenter.y - eggRadius.y + 4; y <= eggCenter.y + eggRadius.y - 4; y += 8) {
				points.push({x: eggCenter.x + ((points.length % 2 === 0 ? -1 : 1) * 3), y});
			}

			drawLine(context, points, '#2a1206', 2);
			drawLine(context, points.map(point => ({x: point.x + 1, y: point.y + 1})), 'rgba(255, 220, 180, 0.35)', 0.8);
		};

		// A half of the chocolate egg, lying open on the table, with the white milk cream inside and bites out of it from the top.
		const drawHalf = (context, index) => {
			const place = halfPlaces[index];
			const bites = egg.bites[index];
			if (bites >= 5) {
				return;
			}

			layerContext.clearRect(0, 0, eggWidth, eggHeight);
			drawChocolateEgg(layerContext, place.x, place.y, 44, 56);
			const cream = layerContext.createRadialGradient(place.x, place.y + 10, 4, place.x, place.y, 50);
			cream.addColorStop(0, '#fffaf0');
			cream.addColorStop(1, '#e9d9b9');
			fillEllipse(layerContext, place.x, place.y + 2, 35, 46, cream);
			layerContext.beginPath();
			layerContext.ellipse(place.x, place.y + 2, 35, 46, 0, 0, Math.PI * 2);
			strokeCurrent(layerContext, '#3a1a08', 2.5);
			layerContext.globalCompositeOperation = 'destination-out';
			for (let row = 0; row < bites; row++) {
				for (const offset of [-26, -9, 9, 26]) {
					fillEllipse(layerContext, place.x + offset, place.y - 50 + (row * 24) + (Math.abs(offset) * 0.2), 13, 16, '#000000');
				}
			}

			layerContext.globalCompositeOperation = 'source-over';
			context.drawImage(layer, 0, 0, eggWidth, eggHeight);
		};

		const drawHalves = (context, now) => {
			const progress = easeOut(progressOf('split', now));
			if (progress < 1) {
				for (const [index, side] of [-1, 1].entries()) {
					const place = halfPlaces[index];
					context.save();
					context.translate((place.x - eggCenter.x) * progress, (place.y - eggCenter.y) * progress);
					context.beginPath();
					context.rect(side < 0 ? 0 : eggCenter.x, 0, eggCenter.x, eggHeight);
					context.clip();
					drawChocolateEgg(context, eggCenter.x, eggCenter.y, eggRadius.x, eggRadius.y);
					context.restore();
				}

				return;
			}

			drawHalf(context, 0);
			drawHalf(context, 1);
		};

		const capsuleYellow = (context, x, y, radius) => {
			const gradient = context.createRadialGradient(x - (radius * 0.4), y - (radius * 0.5), 2, x, y, radius * 1.4);
			gradient.addColorStop(0, '#fff6a8');
			gradient.addColorStop(0.5, '#ffd21f');
			gradient.addColorStop(1, '#d99a00');
			return gradient;
		};

		// The yellow plastic capsule, with ridges on its top half that turn while it is twisted, and a gap that opens.
		const drawCapsule = (context, x, y, radiusX, radiusY, {twist = 0, lift = 0} = {}) => {
			const fill = capsuleYellow(context, x, y, radiusY);
			context.save();
			context.beginPath();
			context.rect(x - radiusX - 2, y, (radiusX * 2) + 4, radiusY + 2);
			context.clip();
			fillEllipse(context, x, y, radiusX, radiusY, fill);
			context.restore();
			context.save();
			context.translate(0, -lift);
			context.beginPath();
			context.rect(x - radiusX - 2, y - radiusY - 2, (radiusX * 2) + 4, radiusY + 2);
			context.clip();
			fillEllipse(context, x, y, radiusX, radiusY, fill);
			context.restore();
			fillRound(context, x - radiusX, y - lift - 1.5, radiusX * 2, 3, 1.5, '#c48a00');
			context.beginPath();
			for (let index = 0; index < 14; index++) {
				const angle = twist + ((index * Math.PI * 2) / 14);
				if (Math.cos(angle) > 0.1) {
					const ridgeX = x + (Math.sin(angle) * radiusX * 0.95);
					context.moveTo(ridgeX, y - lift - 3);
					context.lineTo(ridgeX, y - lift - (radiusY * 0.25));
				}
			}

			strokeCurrent(context, 'rgba(160, 100, 0, 0.7)', 1.2);
		};

		const drawShells = (context, now) => {
			const progress = easeOut(progressOf('pop', now));
			const from = {x: 160, y: 118};
			const x = lerp(from.x, shellSpot.x, progress);
			const y = lerp(from.y, shellSpot.y, progress);
			const scale = lerp(1, 0.38, progress);
			context.save();
			context.translate(x, y);
			context.scale(scale, scale);
			// The two halves of the open capsule, lying on their sides, so their insides show.
			for (const side of [-1, 1]) {
				context.save();
				context.translate(side * lerp(0, 34, progress), side * lerp(-30, 6, progress));
				context.rotate(side * lerp(0, 0.5, progress));
				const fill = capsuleYellow(context, 0, 0, 52);
				context.beginPath();
				context.ellipse(0, 0, 40, 46, 0, side < 0 ? Math.PI : 0, side < 0 ? Math.PI * 2 : Math.PI);
				context.closePath();
				context.fillStyle = fill;
				context.fill();
				strokeCurrent(context, '#c48a00', 2);
				fillEllipse(context, 0, 0, 38, 9, '#c48a00');
				fillEllipse(context, 0, side * -1, 34, 6, '#e8b400');
				context.restore();
			}

			context.restore();
		};

		const drawBuildSpot = context => {
			context.save();
			context.setLineDash([4, 4]);
			context.beginPath();
			context.ellipse(buildSpot.x, buildSpot.y + 6, 74, 54, 0, 0, Math.PI * 2);
			strokeCurrent(context, 'rgba(90, 50, 15, 0.45)', 1.5);
			context.restore();
			drawLabel(context, 'build here', buildSpot.x, buildSpot.y + 68, {size: 10, color: 'rgba(90, 50, 15, 0.6)'});
		};

		const itemPosition = (item, now) => {
			const progress = easeOut(progressOf('pop', now));
			if (progress >= 1 || item.isAttached) {
				return {x: item.x, y: item.y};
			}

			return {x: lerp(160, item.x, progress), y: lerp(118, item.y, progress)};
		};

		const drawItems = (context, now) => {
			for (const item of egg.items) {
				if (item.isAttached) {
					drawPart(context, egg.toy, item.part, buildSpot.x + (item.part.center.x * buildScale), buildSpot.y + (item.part.center.y * buildScale), {scale: buildScale});
				}
			}

			for (const item of egg.items) {
				if (!item.isAttached && item !== egg.dragging) {
					const position = itemPosition(item, now);
					drawPart(context, egg.toy, item.part, position.x, position.y, {isLoose: true});
					const badge = {x: position.x + (item.part.radius * 0.8), y: position.y + (item.part.radius * 0.6)};
					fillEllipse(context, badge.x, badge.y, 8, 8, '#ffffff');
					context.beginPath();
					context.arc(badge.x, badge.y, 8, 0, Math.PI * 2);
					strokeCurrent(context, '#000080', 1.2);
					drawLabel(context, String(item.label), badge.x, badge.y + 0.5, {size: 11, color: '#000080'});
				}
			}

			if (egg.dragging) {
				context.save();
				context.shadowColor = 'rgba(0, 0, 0, 0.35)';
				context.shadowOffsetY = 5;
				context.shadowBlur = 6;
				drawPart(context, egg.toy, egg.dragging.part, egg.dragging.x, egg.dragging.y, {isLoose: true});
				context.restore();
			}
		};

		// The tiny paper of the egg, folded many times, with the steps in pictures and the warning for children under 3.
		const drawFoldedPaper = (context, x, y, width, height, folds) => {
			context.save();
			context.shadowColor = 'rgba(0, 0, 0, 0.25)';
			context.shadowOffsetY = 2;
			context.shadowBlur = 3;
			context.fillStyle = '#fbfbf6';
			context.fillRect(x - (width / 2), y - (height / 2), width, height);
			context.restore();
			for (let index = 1; index <= folds; index++) {
				const amount = index / (folds + 1);
				drawLine(context, [{x: x - (width / 2) + (width * amount), y: y - (height / 2)}, {x: x - (width / 2) + (width * amount), y: y + (height / 2)}], 'rgba(0, 0, 0, 0.15)', 1);
			}

			for (let row = 0; row < Math.max(2, height / 7); row++) {
				const lineY = y - (height / 2) + 5 + (row * 6);
				if (lineY < y + (height / 2) - 3) {
					drawLine(context, [{x: x - (width / 2) + 4, y: lineY}, {x: x + (width / 2) - 4, y: lineY}], 'rgba(0, 0, 0, 0.2)', 0.8);
				}
			}
		};

		const drawUnderThree = (context, x, y) => {
			fillEllipse(context, x, y, 15, 15, '#ffffff');
			fillEllipse(context, x, y - 3, 5, 5, '#f2c29b');
			drawLabel(context, '0-3', x, y + 7, {size: 8});
			context.beginPath();
			context.arc(x, y, 15, 0, Math.PI * 2);
			strokeCurrent(context, '#d4001a', 2.5);
			drawLine(context, [{x: x - 10.5, y: y - 10.5}, {x: x + 10.5, y: y + 10.5}], '#d4001a', 2.5);
		};

		const drawOpenPaper = context => {
			const left = 18;
			const top = 14;
			const width = 284;
			const height = 228;
			context.save();
			context.shadowColor = 'rgba(0, 0, 0, 0.3)';
			context.shadowOffsetY = 4;
			context.shadowBlur = 8;
			context.fillStyle = '#fbfbf6';
			context.fillRect(left, top, width, height);
			context.restore();
			for (const x of [left + (width / 4), left + (width / 2), left + (width * 0.75)]) {
				drawLine(context, [{x, y: top}, {x, y: top + height}], 'rgba(0, 0, 0, 0.08)', 1);
			}

			drawLine(context, [{x: left, y: top + (height / 2)}, {x: left + width, y: top + (height / 2)}], 'rgba(0, 0, 0, 0.08)', 1);
			drawLabel(context, 'ADVARSEL · ACHTUNG · ATTENTION', left + 12, top + 16, {size: 9, align: 'left', color: '#d4001a'});
			drawUnderThree(context, left + width - 24, top + 24);

			const toy = egg.toy;
			const parts = partsOf(toy);
			if (toy.kind === 'puzzle') {
				context.save();
				context.translate(160, top + 98);
				context.scale(1.4, 1.4);
				drawPuzzlePicture(context);
				context.restore();
				for (const [index, part] of parts.entries()) {
					drawLabel(context, String(index + 1), 160 + (part.center.x * 1.4), top + 98 + (part.center.y * 1.4), {size: 14, color: '#000080'});
				}

				context.strokeStyle = '#6b4a1a';
				context.strokeRect(160 - 56, top + 98 - 42, 112, 84);
			} else {
				const boxWidth = Math.min(54, (width - 30) / parts.length - 6);
				for (const [index, part] of parts.entries()) {
					const boxX = left + 15 + (index * (boxWidth + 6));
					const boxY = top + 52;
					context.strokeStyle = '#999999';
					context.lineWidth = 1;
					context.strokeRect(boxX, boxY, boxWidth, 70);
					fillEllipse(context, boxX + 9, boxY + 9, 7, 7, '#000080');
					drawLabel(context, String(index + 1), boxX + 9, boxY + 9.5, {size: 9, color: '#ffffff'});
					context.save();
					context.translate(boxX + (boxWidth / 2), boxY + 42);
					context.scale(0.65, 0.65);
					context.translate(-part.center.x, -part.center.y);
					(part.drawLoose ?? part.draw)(context, toy, {});
					context.restore();
					if (index < parts.length - 1) {
						drawLabel(context, '+', boxX + boxWidth + 3, boxY + 35, {size: 12});
					}
				}

				drawLabel(context, '=', 160, top + 136, {size: 14});
				drawToy(context, toy, 160, top + 160, {scale: 0.7});
			}

			const codes = 'D · F · I · NL · N · S · DK · SF · GB · E · P · GR';
			drawLabel(context, codes, 160, top + height - 30, {size: 8, color: '#666666'});
			for (const row of [0, 1]) {
				const lineY = top + height - 18 + (row * 6);
				for (let x = left + 14; x < left + width - 20; x += 22) {
					drawLine(context, [{x, y: lineY}, {x: x + 10 + ((x + (row * 5)) % 9), y: lineY}], 'rgba(0, 0, 0, 0.25)', 0.8);
				}
			}
		};

		const drawPaper = context => {
			const paper = egg.paper;
			if (paper.isOpen) {
				drawOpenPaper(context);
			} else if (paper.folds === 3) {
				drawFoldedPaper(context, paperSpot.x, paperSpot.y, 26, 18, 2);
			} else if (paper.folds === 2) {
				drawFoldedPaper(context, 160, 110, 70, 55, 1);
			} else if (paper.folds === 1) {
				drawFoldedPaper(context, 160, 110, 140, 110, 1);
			} else {
				drawFoldedPaper(context, paperSpot.x, paperSpot.y, 30, 24, 0);
				drawLabel(context, '?', paperSpot.x, paperSpot.y + 1, {size: 12, color: '#000080'});
			}
		};

		// Where the toy is while it plays, and how far its wheels, top, or propeller have turned.
		const playPose = now => {
			const play = egg.play;
			if (!play) {
				return {x: buildSpot.x, y: buildSpot.y, rotation: 0, options: {}};
			}

			// With reduced motion, the toy shows one still moment of its play.
			const stillTimes = {car: 1.05, top: 1.4, plane: 0.9, figure: 0.25, puzzle: 0};
			const seconds = this.reducedMotion ? stillTimes[egg.toy.kind] : (now - play.start) / 1000;
			switch (egg.toy.kind) {
				case 'car': {
					let x = 0;
					if (seconds < 0.6) {
						x = -28 * (seconds / 0.6);
					} else if (seconds < 1.5) {
						x = -28 + (230 * (((seconds - 0.6) / 0.9) ** 2));
					} else if (seconds < 2.6) {
						x = -240 * ((1 - easeOut((seconds - 1.5) / 1.1)));
					}

					return {x: buildSpot.x + x, y: buildSpot.y, rotation: 0, options: {turn: x / 8}, speed: seconds >= 0.6 && seconds < 2.6};
				}

				case 'top': {
					const spinning = seconds < 3.5;
					const wobble = spinning ? Math.sin(seconds * 9) * 0.12 * (seconds / 3.5) : Math.min(1.2, (seconds - 3.5) * 5);
					return {x: buildSpot.x, y: buildSpot.y, rotation: wobble, options: {spin: seconds * (spinning ? 30 * (1 - (seconds / 5)) : 0)}, speed: spinning};
				}

				case 'plane': {
					const amount = clamp(seconds / 3, 0, 1);
					const angle = amount * Math.PI * 2;
					return {x: buildSpot.x - (Math.sin(angle) * 110), y: buildSpot.y - (Math.sin(angle / 2) * 60), rotation: Math.sin(angle) * 0.25, options: {spin: seconds * 40}, speed: amount < 1};
				}

				case 'figure': {
					const hop = seconds < 1.2 ? Math.abs(Math.sin((seconds * Math.PI) / 0.6)) * 18 : 0;
					return {x: buildSpot.x, y: buildSpot.y - hop, rotation: 0, options: {}, speech: seconds < 3};
				}

				default: {
					return {x: buildSpot.x, y: buildSpot.y, rotation: 0, options: {}};
				}
			}
		};

		const drawDone = (context, now) => {
			const pose = playPose(now);
			const kind = egg.toy.kind;
			if (pose.speed && this.reducedMotion) {
				// Lines of speed, since a still picture cannot move.
				for (const offset of [-10, 0, 10]) {
					drawLine(context, [{x: pose.x - 70, y: pose.y + offset}, {x: pose.x - 44, y: pose.y + offset}], 'rgba(90, 50, 15, 0.5)', 1.5);
				}
			}

			context.save();
			const pivotY = kind === 'top' ? pose.y + (22 * buildScale) : pose.y;
			context.translate(pose.x, pivotY);
			context.rotate(pose.rotation);
			context.translate(-pose.x, -pivotY);
			drawToy(context, egg.toy, pose.x, pose.y, {...pose.options, scale: buildScale});
			context.restore();

			if (pose.speech && egg.toy.line) {
				context.font = comicFont(11);
				const width = context.measureText(egg.toy.line).width + 14;
				const bubbleX = clamp(pose.x + 20, 4, eggWidth - width - 4);
				fillRound(context, bubbleX, pose.y - 84, width, 22, 8, '#ffffff');
				context.beginPath();
				context.roundRect(bubbleX, pose.y - 84, width, 22, 8);
				strokeCurrent(context, '#000000');
				drawLabel(context, egg.toy.line, bubbleX + 7, pose.y - 72, {size: 11, align: 'left'});
			}

			if (pose.speed && kind === 'top' && this.reducedMotion) {
				drawLabel(context, 'WHIRRR!', pose.x + 48, pose.y - 10, {size: 12, color: '#c0002a'});
			}

			if (kind === 'car' && pose.speed && this.reducedMotion) {
				drawLabel(context, 'VROOM!', pose.x, pose.y - 36, {size: 13, color: '#c0002a'});
			}

			fillStar(context, 48, 218, 36, 25, egg.isNew ? '#ffe14d' : '#ff99aa', 12);
			drawLabel(context, egg.isNew ? 'NEW!' : 'AGAIN?!', 48, 219, {size: 11, color: '#c0002a'});
		};

		// The foil, the capsule, and the parts take drags, so a finger on them does not scroll the page. The other steps only take taps.
		const isDragStage = () => ['foil', 'capsule', 'parts'].includes(egg.stage);

		const drawEgg = () => {
			const context = eggContext;
			const now = performance.now();
			eggCanvas.dataset.state = isDragStage() ? 'drag' : '';
			drawTable(context);
			switch (egg.stage) {
				case 'kiosk': {
					drawKiosk(context);
					break;
				}

				case 'foil': {
					drawChocolateEgg(context, eggCenter.x, eggCenter.y, eggRadius.x, eggRadius.y);
					drawFoil(context);
					break;
				}

				case 'chocolate': {
					drawChocolateEgg(context, eggCenter.x, eggCenter.y, eggRadius.x, eggRadius.y);
					if (egg.cracks > 0) {
						drawCrack(context);
					}

					break;
				}

				case 'halves': {
					drawHalves(context, now);
					if (progressOf('split', now) >= 1) {
						drawCapsule(context, smallCapsule.x, smallCapsule.y, 18, 24);
					}

					break;
				}

				case 'capsule': {
					drawHalves(context, now);
					drawCapsule(context, 160, 118, 40, 52, {twist: egg.twist, lift: Math.min(4, Math.abs(egg.twist))});
					context.save();
					context.setLineDash([3, 5]);
					context.beginPath();
					context.arc(160, 118, 68, -2.6, -0.5);
					strokeCurrent(context, 'rgba(0, 0, 128, 0.5)', 2);
					context.restore();
					fillStar(context, 160 + (Math.cos(-0.5) * 68), 118 + (Math.sin(-0.5) * 68), 6, 3, 'rgba(0, 0, 128, 0.6)', 3);
					drawLabel(context, 'twist!', 160, 34, {size: 11, color: 'rgba(0, 0, 128, 0.8)'});
					break;
				}

				case 'parts': {
					drawShells(context, now);
					drawBuildSpot(context);
					drawItems(context, now);
					drawPaper(context);
					break;
				}

				case 'done': {
					drawShells(context, now);
					drawDone(context, now);
					break;
				}

				default: {
					break;
				}
			}

			drawPieces(context);
		};

		const eggIsBusy = () => {
			const now = performance.now();
			return egg.pieces.length > 0
				|| (egg.animation && now - egg.animation.start < egg.animation.duration + 50)
				|| (egg.play && now - egg.play.start < 4500);
		};

		const stepEgg = seconds => {
			for (const piece of egg.pieces) {
				piece.age += seconds;
				piece.velocityY += 620 * seconds;
				piece.x += piece.velocityX * seconds;
				piece.y += piece.velocityY * seconds;
				piece.rotation += piece.spin * seconds;
			}

			egg.pieces = egg.pieces.filter(piece => piece.y < eggHeight + 20 && piece.age < 2.5);
			drawEgg();
		};

		// The last frame is drawn when the loop stops, as a late frame can end the split before the capsule shows.
		const eggLoop = this.loop(stepEgg, {while: () => !this.reducedMotion && eggIsBusy(), target: eggCanvas, maximumStep: 0.05, stopped: drawEgg});

		// MARK: The egg, step by step

		const renderWeek = () => {
			const eggs = `${state.eggsLeft} EGG${state.eggsLeft === 1 ? '' : 'S'} LEFT THIS WEEK`;
			weekLine.textContent = `UKE ${state.week} · ${state.year} · ${eggs}`;
		};

		const nextItem = () => egg.items.find(item => !item.isAttached);

		// The paper is out while it is open or half unfolded, and then it covers the table.
		const isPaperOut = paper => paper.isOpen || (paper.folds > 0 && paper.folds < 3);

		const renderEgg = () => {
			const labels = {
				// The price stays on one line on a phone.
				kiosk: '🏪 Buy a Kinderegg at Narvesen (9\u00A0kr)',
				foil: '✋ Peel a Strip of Foil',
				chocolate: egg.cracks === 0 ? '👊 Crack the Egg' : '👐 Break It in Two',
				halves: '🟡 Take Out the Capsule',
				capsule: '🔄 Twist the Capsule',
				done: '📚 Put It on My Shelf',
			};
			let label = labels[egg.stage];
			let extraLabel;
			if (egg.stage === 'parts') {
				// The parts come first, so the toy is built at once. The paper is the extra button, until it is in my hands.
				const paper = egg.paper;
				if (paper.isOpen) {
					label = '📄 Fold Away the Paper';
				} else if (isPaperOut(paper)) {
					label = '📄 Unfold It More';
				} else {
					label = `🔧 Add the Next Part (${nextItem()?.part.name ?? ''})`;
					extraLabel = paper.folds === 3 ? '📄 Unfold the Tiny Paper' : '📄 Look at the Paper Again';
				}
			} else if (['halves', 'capsule'].includes(egg.stage) && egg.bites.some(bites => bites < 5)) {
				extraLabel = '🍫 Take a Bite';
			} else if (egg.stage === 'done') {
				extraLabel = '▶ Play with It';
			}

			actionButton.textContent = label;
			if (extraLabel) {
				extraButton.hidden = false;
				extraButton.textContent = extraLabel;
			} else {
				extraButton.hidden = true;
			}

			renderWeek();
			drawEgg();
		};

		const startEgg = toy => {
			egg.toy = toy;
			egg.stage = 'foil';
			egg.cells = makeFoil();
			egg.saidHalf = false;
			egg.cracks = 0;
			egg.bites = [0, 0];
			egg.twist = 0;
			egg.play = undefined;
			egg.items = [];
			egg.paper = {folds: 3, isOpen: false};
			egg.isNew = this.#countOf(toy.id) === 0;
			sisterBox.hidden = true;
		};

		const buyEgg = () => {
			// A double click on “Put It on My Shelf” would buy the next egg right away.
			if (performance.now() - egg.shelvedAt < 700) {
				return;
			}

			if (state.eggsLeft <= 0) {
				sounds.no();
				this.say('Mamma: “Nei! Ett Kinderegg i uka. Det er regelen.” (One a week. That is the rule.) Wait for Saturday, or beg.', eggStatus);
				return;
			}

			state.eggsLeft--;
			const toy = pickToy();
			state.pending = toy.id;
			this.#save();
			startEgg(toy);
			this.say(randomItem([
				'I ran to Narvesen in the rain. The lady says: “Ni kroner, takk.” I shake the egg next to my ear. It rattles!',
				'Narvesen had ONE Kinderegg left, behind the VG newspapers. Mine! Drag over the foil to peel it.',
				'I bought it at Narvesen and ran home with it in my jacket pocket. Peel the foil: drag over it!',
			]), eggStatus);
			renderEgg();
		};

		const takeCapsule = () => {
			egg.stage = 'capsule';
			egg.twist = 0;
			sounds.click();
			this.say('The capsule is stuck tight. Twist it open: drag around it in a circle.', eggStatus);
			renderEgg();
		};

		const setUpItems = () => {
			const parts = partsOf(egg.toy);
			const spots = shuffle(looseSpots).slice(0, parts.length);
			egg.items = parts.map((part, index) => ({part, isAttached: false, x: spots[index].x, y: spots[index].y, home: spots[index]}));
			const byPlace = [...egg.items].sort((first, second) => first.x - second.x);
			for (const [index, item] of byPlace.entries()) {
				item.label = index + 1;
			}
		};

		const openCapsule = () => {
			sounds.pop();
			egg.stage = 'parts';
			setUpItems();
			startAnimation('pop', 600);
			const toy = egg.toy;
			const count = this.#countOf(toy.id);
			let text;
			if (toy.isRare) {
				text = 'POP! It is… gold?! THE GOLDEN HIPPO! The rare one! Nobody at school has it!';
				this.toast('🦛✨ THE GOLDEN HIPPO!!!');
				this.celebrate();
			} else if (toy.kind === 'puzzle' && count > 0) {
				text = count === 1 ? 'POP! Oh no. It is the puzzle. AGAIN.' : `POP! The puzzle. That is ${count + 1} of them now. Is there only one puzzle in all of Norway?`;
			} else if (count > 0) {
				text = `POP! ${toy.short}… I already have that one. A double for trading with Trond.`;
			} else if (toy.series) {
				text = `POP! A ${series[toy.series].one}: ${toy.short}! I do not have this one!`;
			} else {
				text = `POP! It is ${toy.name}! Out come the parts and the tiny paper.`;
			}

			this.say(`${text} Drag the parts together on the dashed circle, in the order of the paper.`, eggStatus);
			renderEgg();
		};

		const twistBy = amount => {
			egg.twist += amount;
			const now = performance.now();
			if (now - egg.lastRatchet > 70) {
				egg.lastRatchet = now;
				sounds.ratchet();
			}

			if (Math.abs(egg.twist) >= 4) {
				openCapsule();
			} else {
				drawEgg();
			}
		};

		const bite = index => {
			const half = index ?? (egg.bites[0] <= egg.bites[1] && egg.bites[0] < 5 ? 0 : 1);
			if (egg.bites[half] >= 5) {
				return;
			}

			egg.bites[half]++;
			sounds.crunch();
			const place = halfPlaces[half];
			spawnCrumbs(place.x, place.y - 40 + (egg.bites[half] * 20), 8);
			eggLoop.start();
			if (egg.bites.every(bites => bites >= 5)) {
				this.say('All the chocolate is gone. Mamma: “Har du spist ALT? Før middag?!” (Before dinner?!)', eggStatus);
			} else {
				this.say(randomItem(['Nam! Milk chocolate and milk cream.', 'Crunch. Mmm.', 'Nam nam nam.', 'A big bite. Chocolate on my fingers.', 'Mmm. Better than brown cheese. Do not tell Mormor.']), eggStatus);
			}

			renderEgg();
		};

		const finishToy = () => {
			egg.stage = 'done';
			egg.play = undefined;
			sounds.yay();
			const toy = egg.toy;
			this.say(`Done! ${toy.short}! Play with it, or put it on the shelf.`, eggStatus);
			renderEgg();
			const wantsIt = toy.isRare || (state.eggsOpened > 0 && Math.random() < 0.3);
			if (wantsIt) {
				sisterText.textContent = toy.isRare
					? 'Lillesøster comes in: “Ooo, GULL! Kan jeg få den? Vær så snill?” (Gold! Can I have it? Please?)'
					: 'Lillesøster comes in: “Å, så søt! Kan jeg få den? Vær så snill?” (So cute! Can I have it? Please?)';
				sisterBox.hidden = false;
			}
		};

		const attach = item => {
			const next = nextItem();
			if (egg.toy.isOrdered && item !== next) {
				sounds.wrong();
				item.x = item.home.x;
				item.y = item.home.y;
				const hint = egg.paper.folds > 0 ? ' Read the tiny paper!' : '';
				this.say(`That does not fit yet. First ${next.part.name}.${hint}`, eggStatus);
				drawEgg();
				return;
			}

			item.isAttached = true;
			sounds.click();
			if (egg.items.every(other => other.isAttached)) {
				finishToy();
				return;
			}

			this.say(`Klikk! ${item.part.name[0].toUpperCase()}${item.part.name.slice(1)} is on.`, eggStatus);
			renderEgg();
		};

		const unfoldPaper = () => {
			const paper = egg.paper;
			sounds.paper();
			if (paper.isOpen) {
				paper.isOpen = false;
				this.say('I fold the paper away. Now drag the parts together, in the order of the pictures.', eggStatus);
			} else if (paper.folds > 0) {
				paper.folds--;
				if (paper.folds === 0) {
					paper.isOpen = true;
					this.say('The paper is open: the steps in pictures, the warning for children under 3, and tiny text in 12 languages. Click to fold it away.', eggStatus);
				} else {
					this.say('I unfold the paper. It is folded SO small. Again!', eggStatus);
				}
			} else {
				paper.isOpen = true;
				this.say('I look at the paper again.', eggStatus);
			}

			renderEgg();
		};

		const playToy = () => {
			if (egg.stage !== 'done') {
				return;
			}

			egg.play = {start: performance.now()};
			const lines = {
				car: 'I pull it back… rrrrr… and let go. VROOOM! Across the whole table!',
				top: 'I spin the top. Whirrr! It wobbles, and wobbles, and falls over.',
				plane: 'Nnneeeooowww! The plane flies a loop over the table.',
				puzzle: 'It is a puzzle of 4 pieces. I look at it. Hippos. On a beach. That is it.',
				figure: `${egg.toy.short} hops on the table: “${egg.toy.line}”`,
			};
			const sound = {car: 'vroom', top: 'whirr', plane: 'propeller', figure: 'boing'}[egg.toy.kind];
			if (egg.toy.kind === 'car') {
				for (let index = 0; index < 5; index++) {
					sounds.ratchet(index * 0.07);
				}
			}

			if (sound) {
				sounds[sound]();
			}

			this.say(lines[egg.toy.kind], eggStatus);
			eggLoop.start();
			drawEgg();
		};

		const shelveToy = () => {
			const toy = egg.toy;
			const count = this.#countOf(toy.id);
			const before = toy.series ? this.#seriesProgress(toy.series) : 0;
			state.collection[toy.id] = count + 1;
			state.pending = undefined;
			state.eggsOpened++;
			this.#save();
			egg.stage = 'kiosk';
			egg.shelvedAt = performance.now();
			sisterBox.hidden = true;
			let text;
			if (count === 0) {
				text = `${toy.short} goes on my shelf. NEW!`;
				if (toy.series) {
					const now = this.#seriesProgress(toy.series);
					text += ` ${now} of ${series[toy.series].size} ${series[toy.series].name}.`;
					if (now === series[toy.series].size && before < now) {
						text += ' THE WHOLE SERIES!!!';
						this.toast(`🏆 All the ${series[toy.series].name}!`);
						this.celebrate();
					}
				}
			} else if (toy.kind === 'puzzle') {
				text = `On the shelf with the other ${count === 1 ? 'one' : count}. I could make a puzzle of puzzles.`;
			} else {
				text = 'On the shelf, next to the other one. A double for trading with Trond!';
			}

			this.say(text, eggStatus);
			renderEgg();
			renderShelf();
		};

		const giveToSister = () => {
			const toy = egg.toy;
			state.sisterToys.push(toy.id);
			state.pending = undefined;
			state.eggsOpened++;
			egg.stage = 'kiosk';
			egg.shelvedAt = performance.now();
			sisterBox.hidden = true;
			sounds.yay();
			let text = `Lillesøster hugs ${toy.short} and runs to show Mamma.`;
			if (state.hasExtraThisWeek) {
				text += ' Mamma gives me a big hug. (But no more eggs this week.)';
			} else {
				state.hasExtraThisWeek = true;
				state.eggsLeft++;
				text += ' Mamma saw everything: “Så snill du er!” (How kind you are!) I get an extra egg this week!';
			}

			this.#save();
			this.say(text, eggStatus);
			renderEgg();
			renderShelf();
		};

		const keepFromSister = () => {
			sisterBox.hidden = true;
			sounds.cry();
			this.say('“MAMMAAAA!” Lillesøster cries. Mamma: “Kan du ikke dele med søsteren din?” (Can you not share with your sister?) It is still mine. I feel a bit bad.', eggStatus);
		};

		const eggAction = () => {
			switch (egg.stage) {
				case 'kiosk': {
					buyEgg();
					break;
				}

				case 'foil': {
					peelStrip();
					break;
				}

				case 'chocolate': {
					crackEgg();
					break;
				}

				case 'halves': {
					takeCapsule();
					break;
				}

				case 'capsule': {
					twistBy(1.4);
					if (egg.stage === 'capsule') {
						this.say('Krrk krrk. It turns a bit. Again!', eggStatus);
					}

					break;
				}

				case 'parts': {
					if (isPaperOut(egg.paper)) {
						unfoldPaper();
					} else {
						attach(nextItem());
					}

					break;
				}

				case 'done': {
					shelveToy();
					break;
				}

				default: {
					break;
				}
			}
		};

		// MARK: Mamma and the week

		const mammaLines = [
			'Mamma: “Nei. Ett i uka. Det er regelen.” (One a week. That is the rule.)',
			'Mamma: “Nei, sa jeg!” (I said no!)',
			'Mamma: “Du får hull i tennene!” (You will get holes in your teeth!)',
			'Mamma: “Vi skal spise middag snart.” (We eat dinner soon.)',
			'Mamma: “Spør Pappa.” (Ask Pappa.)',
			'Pappa, behind Bergens Tidende: “Spør Mamma.” (Ask Mamma.)',
		];

		const beg = () => {
			state.begs++;
			if (state.eggsLeft > 0) {
				this.say('Mamma: “Du har jo ett egg igjen denne uka!” (You still have one this week!)', eggStatus);
			} else if (state.begs >= 3 && !state.hasExtraThisWeek && Math.random() < 0.22) {
				state.hasExtraThisWeek = true;
				state.eggsLeft++;
				sounds.yay();
				this.say('Mamma sighs: “Ok, da. Men bare denne gangen!” (OK. But only this time!) YES!', eggStatus);
			} else {
				sounds.no();
				this.say(mammaLines[(state.begs - 1) % mammaLines.length], eggStatus);
			}

			this.#save();
			renderWeek();
			drawEgg();
		};

		const waitForSaturday = () => {
			const unused = state.eggsLeft;
			state.week++;
			let text = `Lørdag! Week ${state.week}. Mamma gives me 9 kroner for this week’s egg.`;
			if (state.week > 52) {
				state.week = 1;
				state.year++;
				text = state.year === 2000
					? 'Godt nytt år! It is the year 2000, the computers did not explode, and Narvesen still sells Kinderegg.'
					: `Godt nytt år! Week 1 of ${state.year}.`;
			}

			state.eggsLeft = 1;
			state.begs = 0;
			state.hasExtraThisWeek = false;
			if (unused > 0) {
				text += ' (The egg of last week does not add up. Mamma’s rule.)';
			}

			if (Math.random() < 0.25) {
				state.eggsLeft++;
				text += ' And Mormor comes for Sunday dinner with a Kinderegg in her handbag!';
			}

			this.#save();
			this.say(text, eggStatus);
			renderWeek();
			drawEgg();
		};

		// MARK: The egg, by hand

		let eggPointer;

		// A tap on the halves takes out the capsule or takes a bite. While the capsule is in the middle, only the halves at the sides are bitten.
		const pressHalves = point => {
			if (egg.stage === 'halves' && distance(point, smallCapsule) < 28) {
				takeCapsule();
				return;
			}

			const half = halfPlaces.findIndex(place => distance(point, place) < 50 && (egg.stage === 'halves' || Math.abs(point.x - 160) > 44));
			if (half >= 0 && egg.bites[half] < 5) {
				bite(half);
			}
		};

		// A tap step acts on the click, which a finger that scrolls the page over the table does not make. A drag step acts on the press.
		let isEggTap = false;

		this.on(eggCanvas, 'click', event => {
			if (!isEggTap) {
				return;
			}

			isEggTap = false;
			const point = canvasPoint(eggCanvas, event, eggWidth, eggHeight);
			switch (egg.stage) {
				case 'kiosk': {
					buyEgg();
					break;
				}

				case 'chocolate': {
					if (((point.x - eggCenter.x) / eggRadius.x) ** 2 + ((point.y - eggCenter.y) / eggRadius.y) ** 2 <= 1.2) {
						crackEgg();
					}

					break;
				}

				case 'halves': {
					pressHalves(point);
					break;
				}

				case 'done': {
					playToy();
					break;
				}

				default: {
					break;
				}
			}
		});

		this.on(eggCanvas, 'pointerdown', event => {
			if (!event.isPrimary || event.button > 0) {
				return;
			}

			isEggTap = !isDragStage();
			if (isEggTap) {
				return;
			}

			const point = canvasPoint(eggCanvas, event, eggWidth, eggHeight);
			eggPointer = {last: point, angle: Math.atan2(point.y - 118, point.x - 160), id: event.pointerId};
			eggCanvas.setPointerCapture?.(event.pointerId);
			switch (egg.stage) {
				case 'foil': {
					peelAlong(point, point);
					break;
				}

				case 'capsule': {
					pressHalves(point);
					break;
				}

				case 'parts': {
					const paper = egg.paper;
					if (isPaperOut(paper) || distance(point, paperSpot) < 22) {
						unfoldPaper();
						eggPointer = undefined;
						break;
					}

					const item = [...egg.items].reverse().find(other => !other.isAttached && distance(point, other) < other.part.radius + 8);
					if (item) {
						egg.dragging = item;
						item.offset = {x: item.x - point.x, y: item.y - point.y};
						drawEgg();
					}

					break;
				}

				default: {
					break;
				}
			}
		});

		this.on(eggCanvas, 'pointermove', event => {
			if (!eggPointer || eggPointer.id !== event.pointerId) {
				return;
			}

			const point = canvasPoint(eggCanvas, event, eggWidth, eggHeight);
			if (egg.stage === 'foil') {
				peelAlong(eggPointer.last, point);
			} else if (egg.stage === 'capsule') {
				const angle = Math.atan2(point.y - 118, point.x - 160);
				let change = angle - eggPointer.angle;
				if (change > Math.PI) {
					change -= Math.PI * 2;
				} else if (change < -Math.PI) {
					change += Math.PI * 2;
				}

				eggPointer.angle = angle;
				if (distance(point, {x: 160, y: 118}) > 12) {
					twistBy(change);
				}
			} else if (egg.dragging) {
				egg.dragging.x = clamp(point.x + egg.dragging.offset.x, 10, eggWidth - 10);
				egg.dragging.y = clamp(point.y + egg.dragging.offset.y, 10, eggHeight - 10);
				drawEgg();
			}

			eggPointer.last = point;
		});

		const endEggPointer = event => {
			if (eggPointer && eggPointer.id !== event.pointerId) {
				return;
			}

			const item = egg.dragging;
			eggPointer = undefined;
			if (!item) {
				return;
			}

			egg.dragging = undefined;
			const target = {x: buildSpot.x + (item.part.center.x * buildScale), y: buildSpot.y + (item.part.center.y * buildScale)};
			if (distance(item, target) < 34 || (distance(item, buildSpot) < 60 && egg.toy.kind !== 'puzzle')) {
				attach(item);
			} else if (distance(item, buildSpot) < 60) {
				// A puzzle piece needs its own place in the picture.
				sounds.wrong();
				item.x = item.home.x;
				item.y = item.home.y;
				this.say('That piece goes in another corner of the picture.', eggStatus);
				drawEgg();
			} else {
				item.home = {x: item.x, y: item.y};
				drawEgg();
			}
		};

		this.on(eggCanvas, 'pointerup', endEggPointer);
		this.on(eggCanvas, 'pointercancel', endEggPointer);

		this.on(eggCanvas, 'keydown', event => {
			// A held key would run through all the steps, and buy the next egg too.
			if (event.metaKey || event.ctrlKey || event.altKey || event.repeat) {
				return;
			}

			const key = event.key.toLowerCase();
			if (key === 'enter' || key === ' ') {
				event.preventDefault();
				eggAction();
			} else if (key === 'b' && ['halves', 'capsule'].includes(egg.stage)) {
				event.preventDefault();
				bite();
			} else if (key === 'p' && egg.stage === 'done') {
				event.preventDefault();
				playToy();
			} else if (key === 'escape' && egg.stage === 'parts' && egg.paper.isOpen) {
				event.preventDefault();
				unfoldPaper();
			} else if (/^[1-5]$/.test(key) && egg.stage === 'parts') {
				event.preventDefault();
				const item = egg.items.find(other => other.label === Number(key) && !other.isAttached);
				if (egg.paper.isOpen) {
					unfoldPaper();
				} else if (item) {
					attach(item);
				}
			}
		});

		this.on(actionButton, 'click', eggAction);
		this.on(extraButton, 'click', () => {
			if (egg.stage === 'done') {
				playToy();
			} else if (egg.stage === 'parts') {
				unfoldPaper();
			} else {
				bite();
			}
		});
		this.on(begButton, 'click', beg);
		this.on(saturdayButton, 'click', waitForSaturday);
		this.on(sisterGiveButton, 'click', giveToSister);
		this.on(sisterKeepButton, 'click', keepFromSister);
		this.on(sisterBox, 'keydown', event => {
			if (event.key === 'Escape') {
				event.preventDefault();
				keepFromSister();
			}
		});

		this.#redrawEgg = () => {
			egg.pieces = [];
			drawEgg();
		};

		const pendingToy = state.pending && toyById(state.pending);
		if (pendingToy) {
			startEgg(pendingToy);
			eggStatus.textContent = 'There is still an egg in my jacket pocket from Narvesen! Drag over the foil to peel it.';
		} else {
			state.pending = undefined;
		}

		renderEgg();
	}

	// MARK: The shelf

	// Draws the shelf and lists the doubles, and returns the function that draws them again.
	#setUpShelf() {
		const {shelf: shelfCanvas, shelfCount, doubles: doublesList, offer: offerBox, offerText, accept: acceptButton, decline: declineButton, shelfStatus} = this.parts;
		const state = this.#state;

		const shelfWidth = 320;
		const shelfHeight = 250;
		const shelfContext = setUpCanvas(shelfCanvas, shelfWidth, shelfHeight);

		const shelfRows = [
			{label: 'HAPPY HIPPOS', series: 'hippos', y: 74, scale: 0.6},
			{label: 'CROCODILES', series: 'crocodiles', y: 154, scale: 0.6},
			{label: 'OTHER TOYS', y: 234, scale: 0.6},
		];

		const drawShelf = () => {
			const context = shelfContext;
			context.fillStyle = '#cfe3f2';
			context.fillRect(0, 0, shelfWidth, shelfHeight);
			for (let x = 8; x < shelfWidth; x += 24) {
				drawLine(context, [{x, y: 0}, {x, y: shelfHeight}], 'rgba(255, 255, 255, 0.45)', 6);
			}

			for (const row of shelfRows) {
				const rowToys = toys.filter(toy => (row.series ? toy.series === row.series : !toy.series));
				const gap = shelfWidth / rowToys.length;
				for (const [index, toy] of rowToys.entries()) {
					const x = (gap * index) + (gap / 2);
					const count = this.#countOf(toy.id);
					const y = row.y - 22;
					if (count > 0) {
						const scale = toy.kind === 'puzzle' ? 0.55 : row.scale;
						drawToy(context, toy, x, toy.kind === 'puzzle' ? y + 2 : y - 2, {scale});
						if (count > 1) {
							fillEllipse(context, x + 18, y - 22, 10, 8, '#ffff66');
							drawLabel(context, `×${count}`, x + 18, y - 21, {size: 10, color: '#c0002a'});
						}
					} else {
						context.save();
						context.setLineDash([3, 3]);
						context.beginPath();
						context.roundRect(x - 17, y - 26, 34, 44, 4);
						strokeCurrent(context, toy.isRare ? '#c99a00' : 'rgba(0, 0, 80, 0.35)', 1.2);
						context.restore();
						drawLabel(context, '?', x, y - 4, {size: 16, color: toy.isRare ? '#c99a00' : 'rgba(0, 0, 80, 0.4)'});
						if (toy.isRare) {
							drawLabel(context, 'RARE', x, y + 11, {size: 9, color: '#c99a00'});
						}
					}
				}

				const plank = context.createLinearGradient(0, row.y, 0, row.y + 12);
				plank.addColorStop(0, '#b07a45');
				plank.addColorStop(1, '#7a4f25');
				context.fillStyle = plank;
				context.fillRect(0, row.y, shelfWidth, 12);
				const owned = row.series ? `${this.#seriesProgress(row.series)}/${series[row.series].size}` : '';
				drawLabel(context, `${row.label} ${owned}`.trim(), 6, row.y + 6.5, {size: 10, color: '#fff3d6', align: 'left'});
			}
		};

		const toyEmoji = toy => {
			if (toy.animal === 'hippo') {
				return toy.isRare ? '🦛✨' : '🦛';
			}

			if (toy.animal === 'croc') {
				return '🐊';
			}

			return {car: '🏎', top: '🌀', plane: '🛩', puzzle: '🧩'}[toy.kind];
		};

		const renderShelf = () => {
			drawShelf();
			let total = 0;
			for (const toy of toys) {
				total += this.#countOf(toy.id);
			}

			const parts = [`${total} TOY${total === 1 ? '' : 'S'} ON THE SHELF`];
			if (state.sisterToys.length > 0) {
				parts.push(`LILLESØSTER HAS ${state.sisterToys.length}`);
			}

			if (state.junk.length > 0) {
				parts.push(`JUNK FROM TROND: ${state.junk.length}`);
			}

			shelfCount.textContent = parts.join(' · ');

			doublesList.replaceChildren();
			const doubles = toys.filter(toy => this.#countOf(toy.id) > 1);
			if (doubles.length === 0) {
				const item = document.createElement('li');
				item.textContent = 'No doubles yet. Buy more eggs! (One a week.)';
				doublesList.append(item);
				return;
			}

			for (const toy of doubles) {
				const item = document.createElement('li');
				const name = document.createElement('span');
				name.textContent = `${toyEmoji(toy)} ${toy.short} ×${this.#countOf(toy.id)}`;
				const button = document.createElement('button');
				button.type = 'button';
				button.dataset.kinderEggTrade = toy.id;
				button.textContent = 'Trade with Trond';
				item.append(name, button);
				doublesList.append(item);
			}
		};

		// MARK: Trond’s trades

		const junk = [
			'half a trading card (the half without the monster)',
			'a chewed pencil with a Smurf on it',
			'a Tamagotchi with a dead battery',
			'three wheels from a Kinderegg car',
			'a marble with a crack',
			'a used bus ticket from Gaia Trafikk',
			'a sticker of Bamse, half stuck to itself',
		];

		let offer;

		const closeOffer = () => {
			offer = undefined;
			offerBox.hidden = true;
		};

		const showOffer = id => {
			const toy = toyById(id);
			if (!toy || this.#countOf(id) < 2) {
				return;
			}

			if (toy.kind === 'puzzle') {
				offer = undefined;
				offerBox.hidden = true;
				this.say('Trond: “The puzzle? I have FIVE of those. Everybody has that puzzle. Nei takk.”', shelfStatus);
				return;
			}

			const common = toys.filter(other => !other.isRare && other.id !== id);
			const missing = common.filter(other => this.#countOf(other.id) === 0);
			const roll = Math.random();
			if (toy.isRare) {
				const items = [randomItem(common), randomItem(common), randomItem(common)];
				offer = {id, items};
				offerText.textContent = `Trond’s eyes get BIG: “THE GOLDEN HIPPO?! I give you THREE for it: ${items.map(item => item.short).join(', ')}! Byttes?”`;
			} else if (missing.length > 0 && roll < 0.45) {
				const item = randomItem(missing);
				offer = {id, items: [item]};
				offerText.textContent = `Trond: “Byttes? I give you ${item.short} for your ${toy.short}.” (I do not have that one!)`;
			} else if (roll < 0.7) {
				const item = randomItem(common);
				offer = {id, items: [item]};
				offerText.textContent = `Trond: “I give you ${item.short} for your ${toy.short}. Fair, ikke sant?”`;
			} else {
				const thing = randomItem(junk);
				offer = {id, items: [], junk: thing};
				offerText.textContent = `Trond: “I give you ${thing} for your ${toy.short}. It is worth a LOT.”`;
			}

			offerBox.hidden = false;
			this.say(`Trond looks at my ${toy.short}…`, shelfStatus);
		};

		const acceptOffer = () => {
			if (!offer || this.#countOf(offer.id) < 2) {
				closeOffer();
				return;
			}

			const toy = toyById(offer.id);
			const before = Object.fromEntries(Object.keys(series).map(name => [name, this.#seriesProgress(name)]));
			state.collection[offer.id]--;
			for (const item of offer.items) {
				state.collection[item.id] = this.#countOf(item.id) + 1;
			}

			let text;
			if (offer.junk) {
				state.junk.push(offer.junk);
				text = `I got ${offer.junk}. Hmm. Trond runs away laughing with my ${toy.short}.`;
			} else {
				sounds.yay();
				text = `Byttes! I got ${offer.items.map(item => item.short).join(', ')} for my ${toy.short}.`;
				for (const name of Object.keys(series)) {
					if (this.#seriesProgress(name) === series[name].size && before[name] < series[name].size) {
						text += ` That completes the ${series[name].name}!`;
						this.celebrate();
					}
				}
			}

			this.#save();
			renderShelf();
			closeOffer();
			this.say(text, shelfStatus);
		};

		this.on(doublesList, 'click', event => {
			const button = event.target.closest('[data-kinder-egg-trade]');
			if (button) {
				showOffer(button.dataset.kinderEggTrade);
			}
		});

		const declineOffer = () => {
			closeOffer();
			this.say(randomItem(['Trond: “Du er kjip!” (You are mean!)', 'Trond: “Ok, ok. Maybe tomorrow.”', 'Trond: “Your loss. I am trading it with Kristine then.”']), shelfStatus);
		};

		this.on(acceptButton, 'click', acceptOffer);
		this.on(declineButton, 'click', declineOffer);
		this.on(offerBox, 'keydown', event => {
			if (event.key === 'Escape') {
				event.preventDefault();
				declineOffer();
			}
		});

		renderShelf();
		return renderShelf;
	}

	// MARK: The yo-yo

	#setUpYoyo() {
		const {yoyo: yoyoCanvas, string: stringLine, throwDown: throwButton, tug: tugButton, walkDog: walkDogButton, aroundWorld: aroundWorldButton, rockBaby: rockBabyButton, untangle: untangleButton, newString: newStringButton, swap: swapButton, yoyoStatus} = this.parts;
		const trickItems = [...this.querySelectorAll('[data-kinder-egg-trick]')];
		const state = this.#state;

		const yoyoSize = 320;
		const yoyoContext = setUpCanvas(yoyoCanvas, yoyoSize, yoyoSize);
		const restHand = {x: 160, y: 34};
		const stringLength = 140;
		const yoyoRadius = 15;
		const floorY = 300;
		const fallTime = 0.5;
		const returnTime = 0.4;
		const deadSpin = 0.1;

		const tricks = {
			throw: {name: 'Throw Down'},
			sleeper: {name: 'The Sleeper'},
			long: {name: 'Long Sleeper', needs: 'sleeper'},
			dog: {name: 'Walk the Dog', needs: 'sleeper', spin: 0.3, duration: 1.75},
			world: {name: 'Around the World', needs: 'sleeper', spin: 0.4, duration: 1.7},
			baby: {name: 'Rock the Baby', needs: 'world', spin: 0.5, duration: 2.95},
			ten: {name: 'Ten in a Row'},
		};

		const yoyo = {
			mode: 'hand',
			modeStart: 0,
			spin: {value: 0, time: 0, life: 7},
			sleepStart: 0,
			angle: 0,
			pendingTrick: undefined,
			returnTrick: undefined,
			from: {x: 0, y: 0},
			knot: 0,
			row: 0,
			still: undefined,
			isBrain: false,
			brainThrows: 0,
			caughtAt: 0,
		};

		// The spin slows down by itself, so it is a function of the time, which also works for the still pictures of reduced motion.
		const spinAt = now => yoyo.spin.value * Math.exp(-((now - yoyo.spin.time) / 1000) / yoyo.spin.life);

		const setSpin = (value, life, now = performance.now()) => {
			yoyo.spin = {value, time: now, life};
		};

		const setMode = (mode, now = performance.now()) => {
			yoyo.mode = mode;
			yoyo.still = undefined;
			yoyo.modeStart = now;
			yoyoLoop.start();
		};

		const secondsIn = now => (now - yoyo.modeStart) / 1000;
		const finger = hand => ({x: hand.x - 1, y: hand.y + 16});
		const sleepPosition = {x: finger(restHand).x, y: finger(restHand).y + stringLength};

		const isLearned = id => state.tricks.includes(id);

		const renderTricks = () => {
			for (const item of trickItems) {
				const id = item.dataset.kinderEggTrick;
				const trick = tricks[id];
				const isLocked = trick.needs && !isLearned(trick.needs);
				item.dataset.state = isLearned(id) ? 'learned' : (isLocked ? 'locked' : '');
				const prefix = isLearned(id) ? '✓' : (isLocked ? '🔒' : '☐');
				item.querySelector('strong').textContent = `${prefix} ${trick.name}`;
			}
		};

		const wearLabel = () => {
			if (state.wear < 20) {
				return 'NEW';
			}

			if (state.wear < 40) {
				return 'GOOD';
			}

			if (state.wear < 55) {
				return 'GRAY';
			}

			return 'FRAYED!';
		};

		const renderYoyo = () => {
			const string = ['snapped', 'gone'].includes(yoyo.mode) ? 'SNAPPED!' : wearLabel();
			stringLine.textContent = `STRING: ${string} · THROWS: ${state.throws} · IN A ROW: ${yoyo.row} (BEST ${state.bestRow})`;
			if (yoyo.mode === 'tangled') {
				untangleButton.hidden = false;
			} else {
				untangleButton.hidden = true;
			}
			setPressed(swapButton, yoyo.isBrain);
			renderTricks();
		};

		const sayYoyo = text => {
			this.say(text, yoyoStatus);
		};

		const learn = id => {
			if (isLearned(id)) {
				return false;
			}

			state.tricks.push(id);
			this.#save();
			this.toast(`🪀 New trick: ${tricks[id].name}!`);
			return true;
		};

		const die = (text, now) => {
			setMode('dead', now);
			setSpin(0, 1, now);
			yoyo.pendingTrick = undefined;
			yoyo.row = 0;
			sounds.thud();
			sayYoyo(text);
			renderYoyo();
		};

		const catchYoyo = now => {
			const trick = yoyo.returnTrick;
			setMode('hand', now);
			setSpin(0, 1, now);
			yoyo.caughtAt = now;
			yoyo.returnTrick = undefined;
			sounds.smack();
			let text = 'Smack! Back in my hand. (It came back before it got to the bottom, so no trick.)';
			if (trick) {
				yoyo.row++;
				state.bestRow = Math.max(state.bestRow, yoyo.row);
				const cheers = ['Smack! Right in my hand.', 'Yesss!', 'Trond would be so jealous.', 'Like a pro!', 'Smack! Kul!'];
				text = learn(trick) ? `${tricks[trick].name}! I learned a new trick!` : `${tricks[trick].name}! ${randomItem(cheers)}`;
				if (yoyo.row >= 10 && learn('ten')) {
					text += ' And that is TEN IN A ROW!';
					this.celebrate();
				}

				this.#save();
			}

			// Trond wants his Brain back after a while, but the trick of the last throw still counts.
			if (yoyo.isBrain && yoyo.brainThrows >= 8) {
				yoyo.isBrain = false;
				yoyo.brainThrows = 0;
				text += ' Trond: “Kan jeg få den tilbake nå?” (Can I have it back now?) He takes his Yomega Brain back. My light-up one again!';
			}

			sayYoyo(text);
			renderYoyo();
		};

		const currentPose = now => yoyoPose(now).yoyo;

		const startReturn = (trick, now) => {
			yoyo.from = currentPose(now);
			yoyo.returnTrick = trick;
			yoyo.pendingTrick = undefined;
			setMode('up', now);
			sounds.zip();
			if (this.reducedMotion) {
				catchYoyo(now);
			}
		};

		// The yo-yo arrives at the bottom of the string, where it sleeps, or where a worn string snaps.
		const arrive = now => {
			if (state.wear >= 50 && Math.random() < (state.wear - 45) / 45) {
				setMode('snapped', now);
				sounds.twang();
				yoyo.row = 0;
				sayYoyo('SNAP! The string broke! The yo-yo rolls across the floor and under the bed. Put on a new string.');
				renderYoyo();
				if (this.reducedMotion) {
					setMode('gone', now);
					renderYoyo();
				}

				return;
			}

			setMode('sleep', now);
			yoyo.sleepStart = now;
			setSpin(yoyo.throwPower, yoyo.isBrain ? 4 : 7, now);
			sounds.thud();
			sayYoyo(yoyo.isBrain ? 'It sleeps… the Brain will come back by itself when it slows down.' : 'It sleeps at the bottom, spinning and blinking! Tug to get it back, or do a trick.');
		};

		// Moves the yo-yo on in time: the fall ends, tricks end, and the spin runs out. The loop calls it every frame, and with reduced motion, each action calls it first.
		const advance = now => {
			const seconds = secondsIn(now);
			switch (yoyo.mode) {
				case 'down': {
					if (seconds >= fallTime) {
						arrive(now);
					}

					break;
				}

				case 'sleep':
				case 'dog': {
					const spin = spinAt(now);
					if (yoyo.isBrain && spin < 0.45) {
						const trick = yoyo.mode === 'dog' ? 'dog' : (yoyo.pendingTrick ?? 'throw');
						sayYoyo('Click! The clutch of the Brain grabs, and it comes back by itself.');
						startReturn(trick, now);
					} else if (spin < deadSpin) {
						die(yoyo.mode === 'dog'
							? 'It ran out of spin on the floor. Dead. Mamma: “Ikke på parketten!” (Not on the parquet!) Tug to wind it up.'
							: 'It stopped spinning. A dead yo-yo. Tug to wind it up by hand.', now);
					}

					break;
				}

				case 'world':
				case 'baby': {
					if (seconds >= tricks[yoyo.mode].duration) {
						const trick = yoyo.mode;
						setMode('sleep', now);
						yoyo.pendingTrick = trick;
						sayYoyo(`${tricks[trick].name}… and back at the bottom. Now tug!`);
					}

					break;
				}

				case 'up': {
					if (seconds >= returnTime) {
						catchYoyo(now);
					}

					break;
				}

				case 'weak': {
					if (seconds >= 0.8) {
						die('Too late! It climbs halfway, gives up, and hangs dead. Tug to wind it up.', now);
					}

					break;
				}

				case 'snapped': {
					if (seconds >= 1.4) {
						setMode('gone', now);
						renderYoyo();
					}

					break;
				}

				default: {
					break;
				}
			}
		};

		const throwYoyo = (power = 1) => {
			const now = performance.now();
			advance(now);
			if (yoyo.mode !== 'hand') {
				const texts = {
					dead: 'It is dead on the string. Tug to wind it up first.',
					tangled: 'The string is in a knot! Pick at the knot first.',
					snapped: 'The string is broken. Put on a new string.',
					gone: 'The yo-yo is under the bed. Put on a new string.',
				};
				sayYoyo(texts[yoyo.mode] ?? 'It is already out! Tug it back.');
				return;
			}

			state.throws++;
			state.wear++;
			if (yoyo.isBrain) {
				yoyo.brainThrows++;
			}

			this.#save();
			yoyo.throwPower = clamp(power, 0.35, 1);
			yoyo.pendingTrick = undefined;
			setMode('down', now);
			sounds.zip();
			sayYoyo(power < 0.6 ? 'A soft throw. Drag further down for more spin!' : 'Zzzip! Down it goes!');
			if (this.reducedMotion) {
				arrive(now);
				blipHum(spinAt(now));
			}

			renderYoyo();
			drawYoyo(now);
		};

		const tug = () => {
			const now = performance.now();
			advance(now);
			switch (yoyo.mode) {
				case 'hand': {
					// The Brain can come back by itself right now, in `advance`, which already says so.
					if (yoyo.caughtAt !== now) {
						sayYoyo('It is in my hand. Throw it first!');
					}

					break;
				}

				case 'down': {
					startReturn(undefined, now);
					break;
				}

				case 'sleep':
				case 'dog': {
					const spin = spinAt(now);
					const slept = (now - yoyo.sleepStart) / 1000;
					if (spin < 0.22 && !yoyo.isBrain) {
						setMode('weak', now);
						yoyo.from = currentPose(now);
						sounds.zip();
						if (this.reducedMotion) {
							die('Too late! It climbs halfway, gives up, and hangs dead. Tug to wind it up.', now);
						}

						break;
					}

					let trick = yoyo.pendingTrick ?? 'throw';
					if (yoyo.mode === 'dog') {
						trick = 'dog';
					} else if (!yoyo.pendingTrick && slept >= 8) {
						trick = 'long';
					} else if (!yoyo.pendingTrick && slept >= 3) {
						trick = 'sleeper';
					}

					if (trick === 'long' && !isLearned('sleeper')) {
						trick = 'sleeper';
					}

					startReturn(trick, now);
					break;
				}

				case 'dead': {
					setMode('hand', now);
					sounds.pick();
					sayYoyo('I wind it up by hand. Round and round and round. Ready!');
					break;
				}

				case 'tangled': {
					sayYoyo('It is stuck in a knot! Pick at the knot first.');
					break;
				}

				case 'snapped':
				case 'gone': {
					sayYoyo('There is nothing to tug. The yo-yo is under the bed!');
					break;
				}

				default: {
					sayYoyo('Wait for it…');
					break;
				}
			}

			renderYoyo();
			drawYoyo(now);
		};

		const tangleTexts = {
			dog: 'Not enough spin! It just lies on the floor, and the string tangles in a knot.',
			world: 'Not enough spin! It flops over my hand and the string wraps around my fingers in a big knot.',
			baby: 'Not enough spin. The cradle collapses into a knot of string.',
		};

		const startTrick = id => {
			const now = performance.now();
			advance(now);
			const trick = tricks[id];
			if (trick.needs && !isLearned(trick.needs)) {
				sayYoyo(`Trond: “Learn ${tricks[trick.needs].name} first, newbie.”`);
				return;
			}

			if (yoyo.mode !== 'sleep') {
				sayYoyo(yoyo.mode === 'hand' ? `Throw it first, and do ${trick.name} while it sleeps at the bottom!` : 'It has to sleep at the bottom first.');
				return;
			}

			const spin = spinAt(now);
			if (spin < trick.spin) {
				setMode('tangled', now);
				yoyo.knot = 3 + Math.floor(Math.random() * 3);
				yoyo.pendingTrick = undefined;
				yoyo.row = 0;
				sounds.wrong();
				sayYoyo(tangleTexts[id]);
				renderYoyo();
				drawYoyo(now);
				return;
			}

			yoyo.pendingTrick = id;
			setSpin(spin, id === 'dog' ? 2.5 : 4, now);
			if (id === 'dog') {
				sounds.thud();
			}

			if (this.reducedMotion) {
				setMode(id === 'dog' ? 'dog' : 'sleep', now);
				yoyo.still = id;
				yoyo.modeStart = now - (id === 'dog' ? 2000 : 0);
				blipHum(spin);
				sayYoyo(id === 'dog' ? 'Walk the Dog! It rolls along the floor. Now tug!' : `${trick.name}! Now tug!`);
			} else {
				setMode(id, now);
				sayYoyo({dog: 'Walk the Dog! It rolls along the floor…', world: 'Around the World! A big loop…', baby: 'Rock the Baby! The cradle of string…'}[id]);
			}

			renderYoyo();
			drawYoyo(now);
		};

		const untangle = () => {
			if (yoyo.mode !== 'tangled') {
				return;
			}

			yoyo.knot--;
			sounds.pick();
			if (yoyo.knot <= 0) {
				setMode('hand');
				sayYoyo('The knot is open! I wind the string back up. Ready!');
			} else {
				sayYoyo(randomItem(['I pick at the knot with my nails…', 'I pull a loop. It gets worse. No, better!', 'Almost… one more loop.', 'I use my teeth. Do not tell Mamma.']));
			}

			renderYoyo();
			drawYoyo(performance.now());
		};

		const newString = () => {
			const now = performance.now();
			advance(now);
			if (['snapped', 'gone'].includes(yoyo.mode)) {
				state.wear = 0;
				setMode('hand', now);
				sayYoyo('I find the yo-yo under the bed (with a Lego brick and a sock) and tie on a new white string. Ready!');
			} else if (yoyo.mode !== 'hand') {
				sayYoyo('Catch it first, then change the string.');
				return;
			} else if (state.wear < 20) {
				sayYoyo('The string is still new and white. Save the strings: there are only 5 in the packet.');
				return;
			} else {
				state.wear = 0;
				sayYoyo('A new white string from the packet. The old gray one goes in the trash.');
			}

			this.#save();
			renderYoyo();
			drawYoyo(now);
		};

		const swapYoyo = () => {
			const now = performance.now();
			advance(now);
			if (yoyo.mode !== 'hand') {
				sayYoyo('Catch it first!');
				return;
			}

			yoyo.isBrain = !yoyo.isBrain;
			yoyo.brainThrows = 0;
			sayYoyo(yoyo.isBrain
				? 'Trond lends me his Yomega Brain. It has a clutch inside that brings it back by itself! No lights, though.'
				: 'I give Trond his Brain back. My light-up one again!');
			renderYoyo();
			drawYoyo(now);
		};

		// Where the hand, the yo-yo, and the string are at a moment, for each mode.
		const yoyoPose = now => {
			const seconds = secondsIn(now);
			let hand = {...restHand};
			let position = {...sleepPosition};
			let cradle;
			switch (yoyo.mode) {
				case 'hand': {
					// The hand jerks up as it catches, but not in the still picture of reduced motion, where it would stay up.
					const jerk = this.reducedMotion ? 0 : Math.max(0, 1 - ((now - yoyo.caughtAt) / 250));
					hand.y -= jerk * 8;
					position = {x: finger(hand).x, y: finger(hand).y + 4};
					break;
				}

				case 'down': {
					const amount = clamp(seconds / fallTime, 0, 1) ** 2;
					position = {x: sleepPosition.x, y: lerp(finger(restHand).y + 4, sleepPosition.y, amount)};
					break;
				}

				case 'dog': {
					const floor = floorY - yoyoRadius;
					if (seconds < 0.35) {
						const amount = easeInOut(seconds / 0.35);
						position = {x: sleepPosition.x, y: lerp(sleepPosition.y, floor, amount)};
						hand = {x: lerp(restHand.x, 90, amount), y: lerp(restHand.y, 148, amount)};
					} else {
						const amount = easeOut(clamp((seconds - 0.35) / 1.4, 0, 1));
						position = {x: lerp(sleepPosition.x, 262, amount), y: floor};
						hand = {x: position.x - 70, y: 148};
					}

					break;
				}

				case 'world': {
					const center = {x: 160, y: 160};
					const radius = 120;
					if (seconds < 0.25) {
						const amount = easeInOut(seconds / 0.25);
						hand = {x: lerp(restHand.x, center.x, amount), y: lerp(restHand.y, center.y - 16, amount)};
						position = {x: lerp(sleepPosition.x, center.x, amount), y: lerp(sleepPosition.y, center.y + radius, amount)};
					} else if (seconds < 1.45) {
						const angle = (Math.PI / 2) - (easeInOut((seconds - 0.25) / 1.2) * Math.PI * 2);
						hand = {x: center.x, y: center.y - 16};
						position = {x: center.x + (Math.cos(angle) * radius), y: center.y + (Math.sin(angle) * radius)};
					} else {
						const amount = easeInOut(clamp((seconds - 1.45) / 0.25, 0, 1));
						hand = {x: lerp(center.x, restHand.x, amount), y: lerp(center.y - 16, restHand.y, amount)};
						position = {x: lerp(center.x, sleepPosition.x, amount), y: lerp(center.y + radius, sleepPosition.y, amount)};
					}

					break;
				}

				case 'baby': {
					const pivot = {x: 160, y: 96};
					const swingLength = 76;
					let angle = 0;
					if (seconds >= 0.3 && seconds < 2.7) {
						angle = 0.5 * Math.sin(((seconds - 0.3) / 0.8) * Math.PI * 2);
					}

					const fade = seconds < 0.3 ? seconds / 0.3 : (seconds > 2.7 ? Math.max(0, 1 - ((seconds - 2.7) / 0.25)) : 1);
					const swing = {x: pivot.x + (Math.sin(angle) * swingLength), y: pivot.y + (Math.cos(angle) * swingLength)};
					position = {x: lerp(sleepPosition.x, swing.x, fade), y: lerp(sleepPosition.y, swing.y, fade)};
					cradle = {pivot, fade};
					break;
				}

				case 'up': {
					const amount = clamp(seconds / returnTime, 0, 1) ** 1.6;
					const target = {x: finger(restHand).x, y: finger(restHand).y + 4};
					position = {x: lerp(yoyo.from.x, target.x, amount), y: lerp(yoyo.from.y, target.y, amount)};
					break;
				}

				case 'weak': {
					const climb = Math.sin(clamp(seconds / 0.8, 0, 1) * Math.PI);
					position = {x: sleepPosition.x, y: sleepPosition.y - (climb * stringLength * 0.5)};
					break;
				}

				case 'tangled': {
					position = {x: sleepPosition.x + 6, y: finger(restHand).y + 70};
					break;
				}

				case 'snapped': {
					const fall = clamp(seconds / 0.4, 0, 1);
					const roll = Math.max(0, seconds - 0.4);
					position = {x: sleepPosition.x + (roll * 260), y: lerp(sleepPosition.y, floorY - yoyoRadius, fall ** 2)};
					break;
				}

				case 'gone': {
					position = undefined;
					break;
				}

				default: {
					break;
				}
			}

			return {hand, yoyo: position, cradle};
		};

		const drawRoom = context => {
			context.fillStyle = '#cfe3f2';
			context.fillRect(0, 0, yoyoSize, floorY);
			for (let x = 10; x < yoyoSize; x += 26) {
				drawLine(context, [{x, y: 0}, {x, y: floorY}], 'rgba(255, 255, 255, 0.5)', 7);
			}

			// The window, with the Bergen rain.
			fillRound(context, 228, 40, 76, 92, 2, '#ffffff');
			context.fillStyle = '#8fa3b5';
			context.fillRect(234, 46, 64, 80);
			for (const [x, y] of [[240, 52], [252, 70], [266, 58], [280, 84], [244, 96], [290, 104], [260, 110], [272, 50]]) {
				drawLine(context, [{x, y}, {x: x - 3, y: y + 9}], 'rgba(255, 255, 255, 0.7)', 1);
			}

			drawLine(context, [{x: 266, y: 46}, {x: 266, y: 126}], '#ffffff', 3);
			drawLine(context, [{x: 234, y: 86}, {x: 298, y: 86}], '#ffffff', 3);

			// The poster on the wall.
			context.save();
			context.translate(44, 100);
			context.rotate(-0.06);
			fillRound(context, -30, -40, 60, 80, 2, '#1a1a3a');
			drawLabel(context, 'BSB', 0, -14, {size: 18, color: '#ffe14d'});
			drawLabel(context, 'LIVE!', 0, 8, {size: 10, color: '#ff77aa'});
			fillStar(context, 0, 26, 7, 3, '#ffe14d');
			context.restore();

			// The parquet that Mamma is so careful with.
			context.fillStyle = '#b07a45';
			context.fillRect(0, floorY, yoyoSize, yoyoSize - floorY);
			for (let x = 0; x < yoyoSize; x += 40) {
				drawLine(context, [{x, y: floorY}, {x: x - 10, y: yoyoSize}], 'rgba(80, 40, 10, 0.4)', 1);
			}

			drawLine(context, [{x: 0, y: floorY}, {x: yoyoSize, y: floorY}], '#7a4f25', 2);

			// Rocky, my pet rock, watches from the floor.
			fillEllipse(context, 30, floorY - 4, 16, 11, '#8d8d8d');
			fillEllipse(context, 24, floorY - 8, 4, 4, '#ffffff');
			fillEllipse(context, 35, floorY - 8, 4, 4, '#ffffff');
			fillEllipse(context, 25, floorY - 7, 2, 2, '#000000');
			fillEllipse(context, 36, floorY - 9, 2, 2, '#000000');
		};

		const drawHand = (context, hand, {isLower = false} = {}) => {
			if (!isLower) {
				fillRound(context, hand.x - 15, -10, 30, hand.y + 2, 6, '#2a4fa0');
				fillRound(context, hand.x - 16, hand.y - 18, 32, 8, 3, '#1d3a7a');
			}

			fillRound(context, hand.x - 13, hand.y - 12, 26, 18, 7, '#f2c29b');
			for (const offset of [-10, -4.5, 1, 6.5]) {
				fillRound(context, hand.x + offset, hand.y + 2, 5, offset === -4.5 ? 14 : 11, 2.5, '#f2c29b');
			}

			drawLine(context, [{x: hand.x - 13, y: hand.y - 2}, {x: hand.x - 18, y: hand.y + 6}], '#e2ad85', 5);
		};

		const ledColors = ['#ff3030', '#30ff60', '#3080ff'];

		const drawYoyoBody = (context, position, angle, spin, now) => {
			const isLit = !yoyo.isBrain && spin > 0.15;
			if (isLit) {
				const glow = context.createRadialGradient(position.x, position.y, 4, position.x, position.y, 42);
				const color = this.reducedMotion ? '255, 80, 80' : ['255, 60, 60', '60, 255, 100', '80, 140, 255'][Math.floor(now / 90) % 3];
				glow.addColorStop(0, `rgba(${color}, ${0.6 * Math.min(1, spin * 1.5)})`);
				glow.addColorStop(1, `rgba(${color}, 0)`);
				context.fillStyle = glow;
				context.fillRect(position.x - 42, position.y - 42, 84, 84);
			}

			const body = context.createRadialGradient(position.x - 5, position.y - 5, 2, position.x, position.y, yoyoRadius);
			if (yoyo.isBrain) {
				body.addColorStop(0, 'rgba(160, 230, 255, 0.95)');
				body.addColorStop(1, 'rgba(20, 110, 190, 0.95)');
			} else {
				body.addColorStop(0, 'rgba(255, 170, 170, 0.95)');
				body.addColorStop(1, 'rgba(190, 0, 30, 0.95)');
			}

			fillEllipse(context, position.x, position.y, yoyoRadius, yoyoRadius, body);
			context.beginPath();
			context.arc(position.x, position.y, yoyoRadius, 0, Math.PI * 2);
			strokeCurrent(context, 'rgba(0, 0, 0, 0.5)', 1.2);
			fillEllipse(context, position.x, position.y, 5, 5, 'rgba(255, 255, 255, 0.6)');
			if (yoyo.isBrain) {
				// The clutch inside the Brain, two little arms with springs.
				for (const side of [0, Math.PI]) {
					const armAngle = angle + side;
					drawLine(context, [{x: position.x, y: position.y}, {x: position.x + (Math.cos(armAngle) * 10), y: position.y + (Math.sin(armAngle) * 10)}], '#e0e0e0', 2);
				}
			} else {
				for (let index = 0; index < 3; index++) {
					const ledAngle = angle + ((index * Math.PI * 2) / 3);
					const x = position.x + (Math.cos(ledAngle) * 9);
					const y = position.y + (Math.sin(ledAngle) * 9);
					const isOn = isLit && (this.reducedMotion || Math.floor(now / 90) % 3 === index || spin > 0.6);
					fillEllipse(context, x, y, 2.5, 2.5, isOn ? ledColors[index] : '#550010');
					if (isOn) {
						fillEllipse(context, x, y, 1, 1, '#ffffff');
					}
				}
			}

			if (spin > 0.3 && !this.reducedMotion) {
				// The blur of the spin.
				context.beginPath();
				context.arc(position.x, position.y, yoyoRadius - 3, angle, angle + 1.2);
				strokeCurrent(context, 'rgba(255, 255, 255, 0.5)', 2);
			}
		};

		// The white string, with a faint shadow, so it shows on the light wallpaper.
		const drawString = (context, points, color, width = 1.2) => {
			drawLine(context, points, 'rgba(40, 40, 70, 0.35)', width + 1.4);
			drawLine(context, points, color, width);
		};

		const drawKnot = (context, point) => {
			context.beginPath();
			for (let index = 0; index < 40; index++) {
				const angle = index * 0.9;
				const radius = 4 + ((index % 7) * 1.1);
				context.lineTo(point.x + (Math.cos(angle) * radius), point.y + (Math.sin(angle) * radius * 0.8));
			}

			strokeCurrent(context, '#f6f6f0', 1.2);
			drawLabel(context, `knot ×${yoyo.knot}`, point.x + 34, point.y, {size: 10, color: '#c0002a'});
		};

		// With reduced motion, the picture of a trick shows its whole path at once, like a photo with a long shutter.
		const drawStill = context => {
			context.save();
			context.globalAlpha = 0.35;
			if (yoyo.still === 'world') {
				context.setLineDash([4, 5]);
				context.beginPath();
				context.arc(160, 160, 120, 0, Math.PI * 2);
				strokeCurrent(context, '#000080', 1.5);
				context.setLineDash([]);
				for (let index = 0; index < 8; index++) {
					const angle = (index / 8) * Math.PI * 2;
					fillEllipse(context, 160 + (Math.cos(angle) * 120), 160 + (Math.sin(angle) * 120), yoyoRadius, yoyoRadius, '#d4001a');
				}
			} else if (yoyo.still === 'baby') {
				drawLine(context, [{x: 159, y: 50}, {x: 96, y: 214}, {x: 224, y: 214}, {x: 159, y: 50}], '#ffffff', 1.5);
				for (const angle of [-0.5, -0.25, 0, 0.25, 0.5]) {
					fillEllipse(context, 160 + (Math.sin(angle) * 76), 96 + (Math.cos(angle) * 76), yoyoRadius, yoyoRadius, '#d4001a');
				}
			} else if (yoyo.still === 'dog') {
				for (const x of [170, 200, 230]) {
					fillEllipse(context, x, floorY - yoyoRadius, yoyoRadius, yoyoRadius, '#d4001a');
				}
			}

			context.restore();
			const labels = {world: 'AROUND THE WORLD!', baby: 'ROCK THE BABY!', dog: 'WOOF!'};
			if (labels[yoyo.still]) {
				drawLabel(context, labels[yoyo.still], 12, 160, {size: 13, color: '#c0002a', align: 'left'});
			}
		};

		const drawYoyo = now => {
			const context = yoyoContext;
			drawRoom(context);
			if (this.reducedMotion && yoyo.still) {
				drawStill(context);
			}

			const pose = yoyoPose(now);
			const fingerTip = finger(pose.hand);
			const spin = ['hand', 'dead', 'tangled', 'gone'].includes(yoyo.mode) ? 0 : spinAt(now);
			const string = '#f6f6f0';
			const worn = state.wear >= 40 ? '#b8b4a8' : string;
			if (pose.cradle) {
				// The cradle: the other hand pulls the string into a triangle, and the yo-yo swings in it.
				const fade = pose.cradle.fade;
				const left = {x: lerp(fingerTip.x, 96, fade), y: lerp(fingerTip.y, 214, fade)};
				const right = {x: lerp(fingerTip.x, 224, fade), y: lerp(fingerTip.y, 214, fade)};
				const pivot = {x: lerp(fingerTip.x, pose.cradle.pivot.x, fade), y: lerp(fingerTip.y, pose.cradle.pivot.y, fade)};
				drawString(context, [fingerTip, left, right, pivot, pose.yoyo], worn, 1.2);
				drawHand(context, {x: left.x + 4, y: left.y + 8}, {isLower: true});
			} else if (yoyo.mode === 'snapped' || yoyo.mode === 'gone') {
				drawString(context, [fingerTip, {x: fingerTip.x + 3, y: fingerTip.y + 20}, {x: fingerTip.x - 2, y: fingerTip.y + 34}], worn, 1.2);
				drawString(context, [{x: fingerTip.x - 2, y: fingerTip.y + 34}, {x: fingerTip.x - 5, y: fingerTip.y + 38}], worn, 0.6);
				drawString(context, [{x: fingerTip.x - 2, y: fingerTip.y + 34}, {x: fingerTip.x + 1, y: fingerTip.y + 39}], worn, 0.6);
			} else if (pose.yoyo) {
				drawString(context, [fingerTip, pose.yoyo], worn, 1.2);
			}

			if (yoyo.mode === 'tangled') {
				drawKnot(context, {x: fingerTip.x + 3, y: fingerTip.y + 36});
			}

			if (pose.yoyo) {
				drawYoyoBody(context, pose.yoyo, yoyo.angle, spin, now);
			}

			drawHand(context, pose.hand);
			if (yoyo.mode === 'dog' && !this.reducedMotion && secondsIn(now) > 0.35) {
				for (let index = 0; index < 3; index++) {
					fillEllipse(context, pose.yoyo.x - 18 - (index * 9), floorY - 3 - (index * 2), 3 + index, 2 + index, `rgba(200, 170, 130, ${0.5 - (index * 0.15)})`);
				}
			}

			if (yoyo.mode === 'sleep' && this.reducedMotion) {
				drawLabel(context, spin > 0.15 ? 'zzz… whirrr' : 'zzz…', pose.yoyo.x + 34, pose.yoyo.y, {size: 10, color: '#000080'});
			}
		};

		const yoyoIsBusy = () => {
			const now = performance.now();
			return !['hand', 'dead', 'tangled', 'gone'].includes(yoyo.mode) || now - yoyo.caughtAt < 300;
		};

		const stepYoyo = (seconds, time) => {
			advance(time);
			const spinning = ['down', 'sleep', 'dog', 'world', 'baby', 'up', 'weak', 'snapped'].includes(yoyo.mode);
			const spin = spinning ? (yoyo.mode === 'down' ? yoyo.throwPower * (secondsIn(time) / fallTime) : spinAt(time)) : 0;
			yoyo.angle += (spinning ? Math.max(spin, 0.15) : 0) * 30 * seconds;
			setHum(spin);
			drawYoyo(time);
		};

		// The hum stops when the loop stops: the yo-yo is still, it left the screen, or the tab is hidden.
		const yoyoLoop = this.loop(stepYoyo, {
			while: () => !this.reducedMotion && yoyoIsBusy(),
			target: yoyoCanvas,
			maximumStep: 0.05,
			stopped() {
				setHum(0);
				drawYoyo(performance.now());
			},
		});

		let yoyoPointer;

		this.on(yoyoCanvas, 'pointerdown', event => {
			if (!event.isPrimary || event.button > 0) {
				return;
			}

			const now = performance.now();
			advance(now);
			if (yoyo.mode === 'hand') {
				yoyoPointer = {id: event.pointerId, start: canvasPoint(yoyoCanvas, event, yoyoSize, yoyoSize)};
				yoyoCanvas.setPointerCapture?.(event.pointerId);
			} else if (yoyo.mode === 'tangled') {
				untangle();
			} else {
				tug();
			}
		});

		const endYoyoPointer = event => {
			if (!yoyoPointer || yoyoPointer.id !== event.pointerId) {
				return;
			}

			const point = canvasPoint(yoyoCanvas, event, yoyoSize, yoyoSize);
			const pull = point.y - yoyoPointer.start.y;
			yoyoPointer = undefined;
			throwYoyo(pull > 8 ? 0.4 + (pull / 150) : 0.5);
		};

		this.on(yoyoCanvas, 'pointerup', endYoyoPointer);
		this.on(yoyoCanvas, 'pointercancel', () => {
			yoyoPointer = undefined;
		});

		this.on(yoyoCanvas, 'keydown', event => {
			if (event.metaKey || event.ctrlKey || event.altKey || event.repeat) {
				return;
			}

			const key = event.key.toLowerCase();
			const actions = {
				arrowdown() {
					throwYoyo(1);
				},
				s() {
					throwYoyo(1);
				},
				arrowup: tug,
				enter: tug,
				' '() {
					if (yoyo.mode === 'hand') {
						throwYoyo(1);
					} else {
						tug();
					}
				},
				d() {
					startTrick('dog');
				},
				w() {
					startTrick('world');
				},
				b() {
					startTrick('baby');
				},
				u: untangle,
			};
			if (actions[key]) {
				event.preventDefault();
				actions[key]();
			}
		});

		this.on(throwButton, 'click', () => {
			throwYoyo(1);
		});
		this.on(tugButton, 'click', tug);
		this.on(walkDogButton, 'click', () => {
			startTrick('dog');
		});
		this.on(aroundWorldButton, 'click', () => {
			startTrick('world');
		});
		this.on(rockBabyButton, 'click', () => {
			startTrick('baby');
		});
		this.on(untangleButton, 'click', untangle);
		this.on(newStringButton, 'click', newString);
		this.on(swapButton, 'click', swapYoyo);

		this.#redrawYoyo = () => {
			drawYoyo(performance.now());
		};

		renderYoyo();
		drawYoyo(performance.now());
	}
}
