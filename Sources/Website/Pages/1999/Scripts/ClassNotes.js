// Passing Notes in Class on the 1999 page, a game of red light, green light in my classroom in 6B: the visitor writes a note on lined paper, doodles on it, folds it, and passes it from desk to desk to Ingrid or Trond while the teacher writes on the blackboard. A note that moves while she looks is caught, and she reads it out loud. Each kid has a personality, the teacher has tells, and the bell ends the lesson. The notes are kept in a pencil case in the browser. The classroom runs only while it is on the screen and the tab is visible. With reduced motion, the teacher turns at once, the notes fold at once, and nothing moves by itself. Nothing makes a sound until the visitor turns on the sound.
const nextFrame = () => new Promise(resolve => {
	requestAnimationFrame(() => {
		resolve();
	});
});

const randomItem = items => items[Math.floor(Math.random() * items.length)];
const randomBetween = (minimum, maximum) => minimum + (Math.random() * (maximum - minimum));
const clamp = (value, minimum, maximum) => Math.min(Math.max(value, minimum), maximum);
const lerp = (from, to, amount) => from + ((to - from) * amount);
const plural = (count, word) => `${count} ${word}${count === 1 ? '' : 's'}`;

// The position of a pointer on a canvas, in the pixels of the canvas.
const canvasPoint = (canvas, event) => {
	const rectangle = canvas.getBoundingClientRect();
	return {
		x: (event.clientX - rectangle.left) * canvas.width / rectangle.width,
		y: (event.clientY - rectangle.top) * canvas.height / rectangle.height,
	};
};

const handwriting = '"Comic Sans MS", "Comic Sans", "Chalkboard SE", "Comic Neue", cursive';
const lessonSeconds = 80;
const classicText = 'Liker du meg?';

// The sounds, made in the browser once the visitor turns them on: the chalk, the teacher who clears her throat, the paper, the giggles, the laughter of the class, and the bell.
const sound = {
	context: undefined,
	output: undefined,
	isOn: false,
	noise: undefined,
	// Starts the audio of the element, which is `undefined` when the browser does not allow it yet.
	start(audio) {
		if (!audio) {
			return false;
		}

		try {
			this.context = audio.context;
			this.output = audio.output;
			this.context.resume();
		} catch {
			return false;
		}

		if (!this.noise) {
			this.noise = new AudioBuffer({length: this.context.sampleRate * 2, sampleRate: this.context.sampleRate});
			const samples = this.noise.getChannelData(0);
			for (let index = 0; index < samples.length; index++) {
				samples[index] = (Math.random() * 2) - 1;
			}
		}

		return true;
	},
	get isRunning() {
		return this.isOn && this.context?.state === 'running';
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
	burst(duration, {volume = 0.2, frequency = 800, type = 'lowpass', when = 0, quality = 1, slide} = {}) {
		if (!this.isRunning) {
			return;
		}

		const start = this.context.currentTime + when;
		const source = new AudioBufferSourceNode(this.context, {buffer: this.noise});
		const filter = new BiquadFilterNode(this.context, {type, frequency, Q: quality});
		if (slide) {
			filter.frequency.exponentialRampToValueAtTime(slide, start + duration);
		}

		const gain = new GainNode(this.context, {gain: 0});
		gain.gain.setValueAtTime(0, start);
		gain.gain.linearRampToValueAtTime(volume, start + 0.01);
		gain.gain.exponentialRampToValueAtTime(0.0001, start + duration);
		source.connect(filter).connect(gain).connect(this.output);
		source.start(start, Math.random());
		source.stop(start + duration + 0.02);
	},
	// The scratch of the chalk for a letter, and now and then the squeak that goes through the teeth.
	chalk() {
		this.burst(0.04, {volume: 0.05, frequency: 3000, type: 'bandpass', quality: 2});
		if (Math.random() < 0.12) {
			const pitch = randomBetween(2400, 3400);
			this.tone(pitch, 0.16, {type: 'sine', volume: 0.025, slide: pitch * 1.15});
		}
	},
	throat() {
		this.burst(0.18, {volume: 0.25, frequency: 500, quality: 3});
		this.tone(160, 0.18, {type: 'sawtooth', volume: 0.04, slide: 120});
		this.burst(0.22, {volume: 0.25, frequency: 420, quality: 3, when: 0.25});
		this.tone(150, 0.2, {type: 'sawtooth', volume: 0.04, slide: 100, when: 0.25});
	},
	paper() {
		for (let index = 0; index < 4; index++) {
			this.burst(0.05, {volume: 0.12, frequency: 4000, type: 'highpass', when: index * 0.07});
		}
	},
	slide() {
		this.burst(0.3, {volume: 0.06, frequency: 1800, type: 'bandpass', quality: 0.7});
	},
	whoosh(duration = 0.9) {
		this.burst(duration, {volume: 0.12, frequency: 400, type: 'bandpass', quality: 1.5, slide: 2200});
	},
	giggle() {
		for (let index = 0; index < 5; index++) {
			this.tone(900 + (index * 60), 0.07, {type: 'triangle', volume: 0.05, when: index * 0.1, slide: 1300});
		}
	},
	snort() {
		this.tone(80, 0.35, {type: 'sawtooth', volume: 0.08, slide: 60});
		this.burst(0.35, {volume: 0.3, frequency: 300, quality: 4});
	},
	// The whole class laughs, each kid with a voice of its own.
	laugh() {
		for (let voice = 0; voice < 6; voice++) {
			const pitch = randomBetween(180, 420);
			const delay = randomBetween(0, 0.3);
			for (let index = 0; index < 6; index++) {
				const when = delay + (index * randomBetween(0.16, 0.22));
				this.tone(pitch * randomBetween(0.95, 1.05), 0.12, {type: 'sawtooth', volume: 0.02, when, slide: pitch * 0.8});
				this.burst(0.1, {volume: 0.05, frequency: randomBetween(700, 1100), type: 'bandpass', quality: 4, when});
			}
		}
	},
	caught() {
		this.tone(196, 0.25, {type: 'square', volume: 0.07});
		this.tone(147, 0.5, {type: 'square', volume: 0.07, when: 0.28});
	},
	// The electric school bell: a hammer on a bell, many times a second.
	bell() {
		if (!this.isRunning) {
			return;
		}

		const start = this.context.currentTime;
		const duration = 2.2;
		const oscillator = new OscillatorNode(this.context, {type: 'square', frequency: 880});
		const ring = new OscillatorNode(this.context, {type: 'sine', frequency: 2637});
		const hammer = new OscillatorNode(this.context, {type: 'square', frequency: 22});
		const depth = new GainNode(this.context, {gain: 0.5});
		const tremolo = new GainNode(this.context, {gain: 0.5});
		const gain = new GainNode(this.context, {gain: 0});
		gain.gain.setValueAtTime(0, start);
		gain.gain.linearRampToValueAtTime(0.06, start + 0.02);
		gain.gain.setValueAtTime(0.06, start + duration - 0.1);
		gain.gain.linearRampToValueAtTime(0, start + duration);
		hammer.connect(depth).connect(tremolo.gain);
		oscillator.connect(tremolo);
		ring.connect(new GainNode(this.context, {gain: 0.3})).connect(tremolo);
		tremolo.connect(gain).connect(this.output);
		for (const node of [oscillator, ring, hammer]) {
			node.start(start);
			node.stop(start + duration + 0.05);
		}
	},
	sweet() {
		for (const [index, frequency] of [523, 659, 784, 1047].entries()) {
			this.tone(frequency, 0.25, {type: 'triangle', volume: 0.08, when: index * 0.11});
		}
	},
	sad() {
		this.tone(392, 0.3, {type: 'triangle', volume: 0.08});
		this.tone(370, 0.3, {type: 'triangle', volume: 0.08, when: 0.3});
		this.tone(349, 0.6, {type: 'triangle', volume: 0.08, when: 0.6});
	},
};

const canSpeak = 'speechSynthesis' in globalThis;

// Stops the voice of the teacher. Without the sound on, she does not speak, so the voices of other toys are left alone.
const hush = () => {
	if (canSpeak && sound.isOn) {
		speechSynthesis.cancel();
	}
};

// The teacher reads with a Norwegian voice when the computer has one, like a teacher in Bergen who reads English with an accent.
const speak = (text, {pitch = 1, onEnd}) => {
	if (!sound.isOn || !canSpeak) {
		return false;
	}

	hush();
	const utterance = new SpeechSynthesisUtterance(text);
	const voice = speechSynthesis.getVoices().find(voice => /^(nb|no|nn)\b/i.test(voice.lang));
	if (voice) {
		utterance.voice = voice;
		utterance.lang = voice.lang;
	}

	utterance.pitch = pitch;
	utterance.rate = 0.9;
	utterance.addEventListener('end', onEnd);
	utterance.addEventListener('error', onEnd);
	speechSynthesis.speak(utterance);
	return true;
};

// The kids of 6B, row by row from the blackboard. Each kind does something of its own with a note.
const kids = [
	{name: 'Mette', kind: 'snitch', hair: '#e8c46a', shirt: '#e05a8a', isLongHair: true},
	{name: 'Lars', kind: 'nice', hair: '#6b4423', shirt: '#3a7bd5'},
	{name: 'Silje', kind: 'giggler', hair: '#a0522d', shirt: '#f2a541', isLongHair: true},
	{name: 'Espen', kind: 'nice', hair: '#2b2b2b', shirt: '#5aa469'},
	{name: 'Marius', kind: 'nice', hair: '#d9b36c', shirt: '#8e5ea2'},
	{name: 'Kevin', kind: 'reader', hair: '#c0392b', shirt: '#222222'},
	{name: 'Ingrid', kind: 'crush', hair: '#f0d58a', shirt: '#ff7eb6', isLongHair: true},
	{name: 'Øyvind', kind: 'sleeper', hair: '#7a5230', shirt: '#9aa5b1'},
	{name: 'Stian', kind: 'thrower', hair: '#3d2b1f', shirt: '#d62828'},
	{name: 'Lise', kind: 'giggler', hair: '#2e1d12', shirt: '#7bd389', isLongHair: true},
	{name: 'Kristian', kind: 'nice', hair: '#b5835a', shirt: '#277da1'},
	{name: 'Trond', kind: 'friend', hair: '#e2b04a', shirt: '#2a9d8f'},
	{name: 'Sindre', kind: 'you', hair: '#8b5a2b', shirt: '#264653'},
	{name: 'Hanne', kind: 'nice', hair: '#5c3b28', shirt: '#e9c46a', isLongHair: true},
	{name: 'Mona', kind: 'snitch', hair: '#111111', shirt: '#b5179e', isLongHair: true},
	{name: 'Kjetil', kind: 'sleeper', hair: '#9c6b3c', shirt: '#6c757d'},
].map((kid, index) => ({
	...kid,
	index,
	column: index % 4,
	row: Math.floor(index / 4),
	x: 75 + ((index % 4) * 110),
	y: 160 + (Math.floor(index / 4) * 66),
}));

const sindre = kids.find(kid => kid.kind === 'you');
const kidNamed = name => kids.find(kid => kid.name.toLowerCase() === name);

const traits = {
	snitch: {icon: '✋', text: 'tells the teacher'},
	reader: {icon: '👀', text: 'reads every note'},
	sleeper: {icon: '💤', text: 'asleep'},
	giggler: {icon: '😆', text: 'giggles at everything'},
	thrower: {icon: '⚽', text: 'throws it like Solskjær'},
	nice: {icon: '', text: 'nice, passes it on'},
	crush: {icon: '♥', text: 'my crush'},
	friend: {icon: '★', text: 'my best friend'},
	you: {icon: '', text: 'me!'},
};

const teacherDesk = {x: 404, y: 96, width: 70, height: 30};

// The board of Norwegian class: a bit of nynorsk, which every kid in Bergen has to learn too.
const norwegianBoards = [
	['Nynorsk og bokmål:', 'eg = jeg, ikkje = ikke', 'kva = hva, kvifor = hvorfor', 'korleis = hvordan', 'Lekse: skriv 10 setningar!'],
	['Verb i fortid:', 'å vere: er, var, har vore', 'å gå: går, gjekk, har gått', 'å regne: regnar, regna', 'Det regnar i Bergen.'],
	['Diktat i morgon!', 'Kvar dag regnar det.', 'Eg et vaflar med brunost.', 'Ikkje send lappar i timen.', 'Det ser eg!'],
];

const principalRules = ['ORDENSREGLAR', '1. Ingen lappar i timen.', '2. Ingen tyggis.', '3. Ingen Tamagotchi.', '4. Ingen samlekort.'];

// A long division, as Norwegian kids write it, with the steps under it like a staircase. The digits are kept in columns, so each step lines up under the digits it belongs to. A quotient of two digits takes two steps, so it fits on the board.
const makeDivision = () => {
	const divisor = 3 + Math.floor(Math.random() * 7);
	const quotient = 12 + Math.floor(Math.random() * 88);
	const dividend = divisor * quotient;
	const digits = [...String(dividend)].map(Number);
	const lines = [{text: `${dividend} : ${divisor} = ${quotient}`, column: 0}];
	let current = 0;
	let hasStarted = false;
	for (const [index, digit] of digits.entries()) {
		current = (current * 10) + digit;
		if (!hasStarted && current < divisor) {
			continue;
		}

		hasStarted = true;
		const product = Math.floor(current / divisor) * divisor;
		const productText = String(product);
		lines.push({text: `-${productText}`, column: index - productText.length});
		current -= product;
		if (index < digits.length - 1) {
			const next = `${current}${digits[index + 1]}`;
			lines.push({text: next, column: index + 2 - next.length});
		} else {
			lines.push({text: String(current), column: index});
		}
	}

	return lines;
};

// The lessons of the day. A teacher writes for a while, gives a tell, and turns around to look. `fake` is how often the tell is a trick, and `chalkSpeed` is how many letters she writes in a second.
const lessons = {
	norsk: {
		name: 'Norwegian',
		teacher: 'Fru Hansen',
		callName: 'Fru Hansen',
		pronoun: 'She',
		chalkSpeed: 7,
		isWoman: true,
		write: [3.5, 7],
		tell: 1.1,
		look: [1.8, 3],
		fake: 0,
		risk: 1,
		pitch: 1.1,
		board: () => randomItem(norwegianBoards).map(text => ({text, column: 0})),
	},
	matte: {
		name: 'math',
		teacher: 'Fru Hansen',
		callName: 'Fru Hansen',
		pronoun: 'She',
		chalkSpeed: 3.5,
		isWoman: true,
		write: [3, 6],
		tell: 0.9,
		look: [2, 3.2],
		fake: 0,
		risk: 1.1,
		pitch: 1.1,
		board: makeDivision,
	},
	vikar: {
		name: 'the substitute’s',
		teacher: 'Vikaren',
		callName: 'Vikar',
		pronoun: 'He',
		chalkSpeed: 0,
		isWoman: false,
		neverTurns: true,
		write: [5, 8],
		tell: 0.6,
		look: [3, 4],
		fake: 0,
		risk: 0.7,
		pitch: 0.8,
		board: () => ['VIKAR I DAG', 'Les side 34 til 40', 'i stillheit.', 'IKKJE SNAKK!'].map(text => ({text, column: 0})),
	},
	rektor: {
		name: 'the principal’s',
		teacher: 'Rektor Berg',
		callName: 'Rektor',
		pronoun: 'He',
		chalkSpeed: 5,
		isWoman: false,
		write: [1.8, 4],
		tell: 0.45,
		look: [2.5, 4.2],
		fake: 0.35,
		risk: 1.5,
		pitch: 0.7,
		board: () => principalRules.map(text => ({text, column: 0})),
	},
};

// Only notes that the pencil case can show are kept, in case the stored data is broken.
const isPoint = point => Array.isArray(point) && Number.isFinite(point[0]) && Number.isFinite(point[1]);
const isValidEntry = entry => typeof entry?.text === 'string'
	&& ['ingrid', 'trond'].includes(entry.to)
	&& Array.isArray(entry.doodles)
	&& entry.doodles.every(doodle => typeof doodle?.kind === 'string' && isPoint([doodle.x, doodle.y]))
	&& Array.isArray(entry.strokes)
	&& entry.strokes.every(stroke => Array.isArray(stroke) && stroke.every(point => isPoint(point)))
	&& (entry.reply === undefined || typeof entry.reply?.text === 'string');

const neighbors = kid => kids.filter(other => Math.abs(other.column - kid.column) + Math.abs(other.row - kid.row) === 1);

// The paper canvas: a page torn out of a school notebook, with blue lines, a red margin, and three holes.
const paperLeft = 16;
const paperTop = 8;
const paperRight = 304;
const paperBottom = 232;
const lineHeight = 20;
const firstLine = 52;
const textLeft = 60;
const textRight = 296;

const wrapText = (context, text, width) => {
	const lines = [];
	for (const paragraph of text.split('\n')) {
		let line = '';
		for (const word of paragraph.split(' ')) {
			const candidate = line ? `${line} ${word}` : word;
			if (context.measureText(candidate).width <= width) {
				line = candidate;
				continue;
			}

			if (line) {
				lines.push(line);
			}

			// A word longer than the line is broken by letters.
			line = '';
			for (const character of word) {
				if (context.measureText(line + character).width > width) {
					lines.push(line);
					line = '';
				}

				line += character;
			}
		}

		lines.push(line);
	}

	return lines;
};

const drawHeart = (context, x, y, size, color) => {
	context.fillStyle = color;
	context.beginPath();
	context.moveTo(x, y + (size * 0.35));
	context.bezierCurveTo(x - size, y - (size * 0.3), x - (size * 0.4), y - size, x, y - (size * 0.35));
	context.bezierCurveTo(x + (size * 0.4), y - size, x + size, y - (size * 0.3), x, y + (size * 0.35));
	context.fill();
};

const drawStar = (context, x, y, size) => {
	context.beginPath();
	for (let index = 0; index < 10; index++) {
		const angle = (index * Math.PI / 5) - (Math.PI / 2);
		const radius = index % 2 === 0 ? size : size * 0.45;
		context.lineTo(x + (Math.cos(angle) * radius), y + (Math.sin(angle) * radius));
	}

	context.closePath();
	context.stroke();
};

// The doodles, drawn with a pencil like in the back of every notebook.
const drawDoodle = (context, doodle, color = '#4a4a5a') => {
	const {x, y} = doodle;
	context.save();
	context.strokeStyle = color;
	context.fillStyle = color;
	context.lineWidth = 1.8;
	context.lineCap = 'round';
	switch (doodle.kind) {
		case 'heart': {
			context.beginPath();
			context.moveTo(x, y + 9);
			context.bezierCurveTo(x - 16, y - 3, x - 7, y - 15, x, y - 6);
			context.bezierCurveTo(x + 7, y - 15, x + 16, y - 3, x, y + 9);
			context.stroke();
			break;
		}

		case 'filledHeart': {
			drawHeart(context, x, y, 16, '#e0457b');
			break;
		}

		case 'smiley': {
			context.beginPath();
			context.arc(x, y, 12, 0, Math.PI * 2);
			context.stroke();
			context.fillRect(x - 5, y - 5, 2.5, 3.5);
			context.fillRect(x + 3, y - 5, 2.5, 3.5);
			context.beginPath();
			context.arc(x, y + 1, 6.5, 0.2, Math.PI - 0.2);
			context.stroke();
			break;
		}

		case 'star': {
			drawStar(context, x, y, 13);
			break;
		}

		case 'unicorn': {
			// Glitter, my virtual unicorn: a head with a horn and a mane.
			context.beginPath();
			context.ellipse(x, y + 2, 11, 8, -0.3, 0, Math.PI * 2);
			context.stroke();
			context.beginPath();
			context.moveTo(x + 3, y - 5);
			context.lineTo(x + 10, y - 18);
			context.lineTo(x + 7, y - 4);
			context.stroke();
			context.beginPath();
			context.moveTo(x - 6, y - 4);
			context.quadraticCurveTo(x - 14, y - 2, x - 12, y + 8);
			context.moveTo(x - 2, y - 6);
			context.quadraticCurveTo(x - 10, y - 8, x - 16, y + 2);
			context.stroke();
			context.fillRect(x + 3, y - 1, 2, 2);
			context.font = `8px ${handwriting}`;
			context.fillText('Glitter', x - 12, y + 19);
			break;
		}

		case 'rock': {
			// Rocky the pet rock, with googly eyes.
			context.beginPath();
			context.moveTo(x - 13, y + 8);
			context.quadraticCurveTo(x - 15, y - 6, x - 2, y - 9);
			context.quadraticCurveTo(x + 14, y - 10, x + 13, y + 3);
			context.quadraticCurveTo(x + 12, y + 10, x - 13, y + 8);
			context.stroke();
			for (const offset of [-5, 4]) {
				context.beginPath();
				context.arc(x + offset, y - 2, 3.5, 0, Math.PI * 2);
				context.stroke();
				context.fillRect(x + offset - 0.5, y - 1.5, 2, 2);
			}

			context.font = `8px ${handwriting}`;
			context.fillText('Rocky', x - 11, y + 19);
			break;
		}

		case 'teacher': {
			// The teacher with horns, which every class has drawn at least once.
			context.beginPath();
			context.arc(x, y - 4, 8, 0, Math.PI * 2);
			context.stroke();
			context.beginPath();
			context.arc(x, y - 14, 4, 0, Math.PI * 2);
			context.stroke();
			context.beginPath();
			context.moveTo(x - 6, y - 9);
			context.lineTo(x - 10, y - 17);
			context.lineTo(x - 3, y - 11);
			context.moveTo(x + 6, y - 9);
			context.lineTo(x + 10, y - 17);
			context.lineTo(x + 3, y - 11);
			context.stroke();
			for (const offset of [-3.5, 3.5]) {
				context.beginPath();
				context.arc(x + offset, y - 5, 2.5, 0, Math.PI * 2);
				context.stroke();
			}

			context.beginPath();
			context.moveTo(x - 3, y);
			context.lineTo(x + 3, y);
			context.moveTo(x, y + 4);
			context.lineTo(x, y + 14);
			context.moveTo(x - 8, y + 8);
			context.lineTo(x + 8, y + 8);
			context.stroke();
			context.font = `7px ${handwriting}`;
			context.fillText('FRU HANSEN', x - 20, y + 22);
			break;
		}

		case 'horse': {
			// Ingrid draws horses on everything.
			context.beginPath();
			context.ellipse(x, y + 2, 14, 7, 0, 0, Math.PI * 2);
			context.moveTo(x + 11, y - 2);
			context.lineTo(x + 17, y - 14);
			context.lineTo(x + 23, y - 11);
			context.lineTo(x + 15, y + 1);
			context.moveTo(x - 9, y + 7);
			context.lineTo(x - 10, y + 17);
			context.moveTo(x - 3, y + 8);
			context.lineTo(x - 3, y + 17);
			context.moveTo(x + 5, y + 8);
			context.lineTo(x + 5, y + 17);
			context.moveTo(x + 10, y + 7);
			context.lineTo(x + 11, y + 17);
			context.moveTo(x - 14, y);
			context.quadraticCurveTo(x - 22, y + 4, x - 20, y + 13);
			context.stroke();
			break;
		}

		default: {
			break;
		}
	}

	context.restore();
};

const boxLabels = ['Ja', 'Nei', 'Kanskje'];

// Draws the checkboxes on a line of the paper, with one checked in the pen of whoever answered.
const drawBoxes = (context, baseline, checked, penColor) => {
	context.font = `16px ${handwriting}`;
	let x = textLeft;
	const labels = checked === 'Venner' ? [...boxLabels, 'Bare venner'] : boxLabels;
	for (const label of labels) {
		context.strokeStyle = label === 'Bare venner' ? penColor : '#3a3a4a';
		context.fillStyle = context.strokeStyle;
		context.lineWidth = 1.5;
		context.strokeRect(x, baseline - 12, 12, 12);
		context.fillText(label, x + 17, baseline);
		if (label === checked || (checked === 'Venner' && label === 'Bare venner')) {
			context.strokeStyle = penColor;
			context.lineWidth = 2.5;
			context.beginPath();
			context.moveTo(x - 1, baseline - 7);
			context.lineTo(x + 5, baseline + 1);
			context.lineTo(x + 16, baseline - 17);
			context.stroke();
		}

		x += 17 + context.measureText(label).width + 16;
		if (x > textRight - 40 && label !== labels.at(-1)) {
			x = textLeft;
			baseline += lineHeight;
		}
	}

	return baseline;
};

const penColors = {ingrid: '#c2185b', trond: '#1e4fd8'};

// The shapes of each fold, from the flat page to the folded note, as polygons with the same number of corners, so one shape can turn into the next.
const flat = [[16, 8], [304, 8], [304, 120], [304, 232], [160, 232], [16, 232], [16, 120]];
const foldShapes = {
	football: [
		flat,
		[[16, 96], [304, 96], [304, 120], [304, 144], [160, 144], [16, 144], [16, 120]],
		[[16, 96], [256, 96], [280, 120], [304, 144], [160, 144], [16, 144], [16, 120]],
		[[80, 96], [208, 96], [232, 120], [256, 144], [160, 144], [104, 144], [92, 120]],
		[[160, 80], [160, 80], [196, 112], [222, 144], [160, 144], [98, 144], [124, 112]],
	],
	square: [
		flat,
		[[16, 8], [304, 8], [304, 55], [304, 64], [304, 73], [304, 120], [16, 120]],
		[[16, 52], [304, 52], [304, 70], [304, 76], [304, 82], [304, 100], [16, 100]],
		[[70, 46], [250, 46], [250, 66], [262, 76], [250, 86], [250, 106], [70, 106]],
		[[122, 40], [198, 40], [198, 64], [224, 76], [198, 88], [198, 116], [122, 116]],
	],
	airplane: [
		flat,
		[[160, 8], [160, 8], [304, 90], [304, 232], [160, 232], [16, 232], [16, 90]],
		[[160, 8], [160, 8], [240, 150], [200, 190], [160, 232], [120, 190], [80, 150]],
		[[160, 20], [160, 20], [262, 196], [172, 178], [160, 214], [148, 178], [58, 196]],
	],
};

const foldNames = {
	football: 'a paper football',
	square: 'a square with a pull tab',
	airplane: 'a paper airplane',
};

// The answers, with a box checked, sometimes sweet, sometimes “Nei”, and sometimes a doodle. `english` says what they mean.
const answers = {
	ingrid: {
		boxes: [
			{box: 'Ja', text: '♥ Ingrid', english: 'she checked “Ja” (yes)! And signed it with a heart.', isSweet: true},
			{box: 'Ja', text: 'Men ikkje sei det til nokon!', english: 'she checked “Ja” (yes), “but don’t tell anyone!”', isSweet: true},
			{box: 'Nei', text: 'Sorry.', english: 'she checked “Nei” (no). Sorry.', isSad: true},
			{box: 'Nei', text: 'Eg liker Trond.', english: 'she checked “Nei” (no), because she likes Trond. TROND!', isSad: true},
			{box: 'Kanskje', text: 'Om du gir meg det glitrande kortet ditt.', english: 'she checked “Kanskje” (maybe), if you give her your shiny trading card.'},
			{box: 'Kanskje', text: 'Spør meg etter jul.', english: 'she checked “Kanskje” (maybe). Ask again after Christmas.'},
			{box: 'Venner', text: '', english: 'she drew a fourth box, “Bare venner” (just friends), and checked it.', isSad: true},
			{doodle: 'horse', text: 'Her er ein hest.', english: 'she checked nothing, and drew a horse instead. Is that good?'},
		],
		free: [
			{text: 'Kven er dette frå??', english: '“Who is this from??”'},
			{text: 'Du skriv stygt :)', english: '“Your handwriting is ugly :)”'},
			{text: 'Ok :) Vil du låne viskelæret mitt?', english: '“Ok :) Do you want to borrow my eraser?”', isSweet: true},
			{doodle: 'filledHeart', text: '', english: 'just a heart. A HEART!', isSweet: true},
			{text: 'Nei.', english: 'just “Nei.” (No.)', isSad: true},
		],
	},
	trond: {
		boxes: [
			{box: 'Ja', text: 'Sjølvsagt, idiot. Du er bestevennen min!', english: 'he checked “Ja”: “Of course, idiot. You are my best friend!”', isSweet: true},
			{box: 'Kanskje', text: 'Om eg får låne spelemaskinen din.', english: 'he checked “Kanskje” (maybe), if he can borrow your handheld game console.'},
			{box: 'Nei', text: 'Haha. Kom over etter skulen? Eg har nytt TV-spel!', english: 'he checked “Nei” as a joke, and asks you over after school to play his new game console.'},
			{doodle: 'teacher', text: 'Sjå, Fru Hansen!', english: 'he drew Fru Hansen with horns. Hide it!'},
		],
		free: [
			{text: 'Kom over etter skulen? Eg har fått nytt TV-spel!', english: '“Come over after school? I got a new game console!”', isSweet: true},
			{text: 'Bytte matpakke? Eg har brunost.', english: '“Swap lunch? I have brown cheese.”'},
			{text: 'Fru Hansen har bart. Ikkje sjå no!', english: '“Fru Hansen has a mustache. Don’t look now!”'},
			{text: 'Hæ? Eg sov.', english: '“Huh? I was asleep.”'},
			{doodle: 'smiley', text: 'Kul lapp!', english: '“Cool note!” and a smiley.', isSweet: true},
		],
	},
};

const makeReply = sent => randomItem(answers[sent.to][sent.boxes ? 'boxes' : 'free']);

export default class extends GeoCitiesElement {
	#redraw;

	connected() {
		const {sound: soundButton, start: startButton, paper, recipient: recipientSelect, text: textField, classic: classicButton, boxes: boxesCheckbox, room, bubble, stats, pencilCase: pencilCaseList, empty: emptyButton} = this.parts;
		const paperContext = paper.getContext('2d');
		const context = room.getContext('2d');
		const lessonButtons = [...this.querySelectorAll('[data-class-notes-lesson]')];
		const doodleButtons = [...this.querySelectorAll('[data-class-notes-doodle]')];
		const foldButtons = [...this.querySelectorAll('[data-class-notes-fold]')];

		// Scrolls to the classroom, with the status line below it, when it is not all on the screen, like on a phone, where the paper is above it. The lesson pauses while the classroom is off the screen, so this also goes on with the lesson. After a fold, the focus goes to the classroom, so the arrow keys pass the note right away, but only when it is still where the fold started, so a visitor who went somewhere else during the fold keeps their focus. It scrolls a frame later, once `say` has put the new message in the status line, as a longer message makes it taller.
		const showClassroom = async () => {
			if (document.activeElement === foldFocus) {
				room.focus({preventScroll: true});
			}

			await nextFrame();
			room.parentElement.scrollIntoView({behavior: this.reducedMotion ? 'auto' : 'smooth', block: 'nearest'});
		};

		this.on(soundButton, 'click', () => {
			hush();
			sound.isOn = !sound.isOn && sound.start(this.sound());
			soundButton.setAttribute('aria-pressed', String(sound.isOn));
			soundButton.dataset.state = sound.isOn ? 'on' : '';
			soundButton.textContent = sound.isOn ? '🔊 Sound' : '🔈 Sound';
			this.say(sound.isOn ? 'Sound on. Listen for the chalk: when it stops squeaking, she is about to turn around. And if she catches a note, she reads it out loud.' : 'Sound off.');
		});

		let lessonId = 'norsk';
		const lesson = () => lessons[lessonId];

		const game = {
			// `ready` before the lesson, `playing` during it, and `over` after the bell.
			state: 'ready',
			time: 0,
			suspicion: 0,
			blush: 0,
			laughUntil: 0,
			answered: 0,
			caught: 0,
		};

		const teacher = {
			// `writing`, `tell`, `turning`, `looking`, `back`, or `reading` a caught note. `wipe` is the time left to wipe a full board.
			state: 'writing',
			timer: 0,
			face: 0,
			x: 120,
			isFake: false,
			hasCleared: false,
			readTime: 0,
			readTarget: 0,
			hasLaughed: false,
			board: [],
			written: 0,
			wipe: 0,
		};

		const storedTotals = this.stored('totals', {});
		const totals = {answered: Number(storedTotals.answered) || 0, caught: Number(storedTotals.caught) || 0};
		const storedCase = this.stored('case', []);
		// Only notes that the pencil case can show are kept, in case the stored data is broken.
		let pencilCase = storedCase.filter(entry => isValidEntry(entry));

		// The note on the paper canvas, which the visitor writes. A copy of it goes into the classroom when it is folded.
		const draft = {
			doodles: [],
			strokes: [],
		};

		// The note in the classroom: who has it, whether it flies, and which kid is busy with it.
		let note;
		let holder;
		let flight;
		let busy;
		let reply;
		let bubbles = [];
		let hovered;

		// What the paper canvas shows: `draft`, `folding`, `folded`, or `saved` for a note of the pencil case or an answer.
		let paperView = 'draft';
		let foldProgress = 0;
		let foldKind;
		let shownNote;
		// The empty paper says so in red after a fold of it, until the visitor writes or draws on it.
		let isPaperEmptyWarning = false;
		// Where the focus was when the visitor folded the note.
		let foldFocus;

		const target = () => kidNamed(note.to);

		const addBubble = (x, y, text, seconds = 1.6) => {
			bubbles.push({x, y, text, time: seconds});
		};

		const updateStats = () => {
			const minutes = Math.min(45, Math.floor(game.time / lessonSeconds * 45));
			const clock = `${String(8 + Math.floor((15 + minutes) / 60)).padStart(2, '0')}:${String((15 + minutes) % 60).padStart(2, '0')}`;
			const text = `Clock ${clock} ★ Risk ${Math.round(game.suspicion)}% ★ Answered ${totals.answered} ★ Caught ${totals.caught}`;
			if (stats.textContent !== text) {
				stats.textContent = text;
			}
		};

		const drawLinedPaper = context => {
			context.fillStyle = '#b89b72';
			context.fillRect(0, 0, paper.width, paper.height);

			// The torn edge at the top, where it was ripped out of the notebook.
			context.fillStyle = '#fdfdf6';
			context.beginPath();
			context.moveTo(paperLeft, paperTop + 4);
			for (let x = paperLeft; x <= paperRight; x += 8) {
				context.lineTo(x + 4, paperTop + ((x / 8) % 2 === 0 ? 0 : 5));
			}

			context.lineTo(paperRight, paperBottom);
			context.lineTo(paperLeft, paperBottom);
			context.closePath();
			context.fill();

			context.strokeStyle = '#9ec3e6';
			context.lineWidth = 1;
			for (let y = firstLine + 4; y < paperBottom; y += lineHeight) {
				context.beginPath();
				context.moveTo(paperLeft, y);
				context.lineTo(paperRight, y);
				context.stroke();
			}

			context.strokeStyle = '#e88a8a';
			context.beginPath();
			context.moveTo(52, paperTop + 4);
			context.lineTo(52, paperBottom);
			context.stroke();

			context.fillStyle = '#b89b72';
			for (const y of [50, 120, 190]) {
				context.beginPath();
				context.arc(32, y, 6, 0, Math.PI * 2);
				context.fill();
			}
		};

		// Draws a whole note: the text in pencil, the boxes, the doodles, Kevin’s scribble, and the answer if it has one.
		const drawNote = (context, shown, {isDraft = false} = {}) => {
			drawLinedPaper(context);
			context.save();
			context.beginPath();
			context.rect(paperLeft, paperTop, paperRight - paperLeft, paperBottom - paperTop);
			context.clip();

			context.fillStyle = '#3a3a4a';
			context.font = `16px ${handwriting}`;
			const text = shown.text.trim() || (isDraft ? '' : '…');
			const lines = wrapText(context, text, textRight - textLeft);
			let baseline = firstLine;
			for (const line of lines) {
				context.fillText(line, textLeft, baseline);
				baseline += lineHeight;
			}

			if (!text && isDraft) {
				context.fillStyle = isPaperEmptyWarning ? '#cc1111' : '#a8a8b8';
				context.fillText(isPaperEmptyWarning ? 'The paper is empty!' : 'Write your note here…', textLeft, firstLine);
			}

			const answer = shown.reply;
			const penColor = penColors[shown.to] ?? penColors.ingrid;
			if (shown.boxes) {
				baseline = drawBoxes(context, baseline, answer?.box, penColor) + lineHeight;
			}

			for (const stroke of shown.strokes) {
				context.strokeStyle = '#55556a';
				context.lineWidth = 1.8;
				context.lineCap = 'round';
				context.lineJoin = 'round';
				context.beginPath();
				for (const [index, point] of stroke.entries()) {
					if (index === 0) {
						context.moveTo(point[0], point[1]);
					} else {
						context.lineTo(point[0], point[1]);
					}
				}

				if (stroke.length === 1) {
					context.lineTo(stroke[0][0] + 0.5, stroke[0][1] + 0.5);
				}

				context.stroke();
			}

			for (const doodle of shown.doodles) {
				drawDoodle(context, doodle);
			}

			if (shown.kevin) {
				context.save();
				context.translate(150, 218);
				context.rotate(-0.1);
				context.fillStyle = '#2e8b2e';
				context.font = `bold 15px ${handwriting}`;
				context.fillText('KEVIN VAR HER!!', 0, 0);
				context.restore();
			}

			if (answer) {
				context.fillStyle = penColor;
				context.font = `16px ${handwriting}`;
				for (const line of wrapText(context, answer.text, textRight - textLeft)) {
					context.fillText(line, textLeft, baseline);
					baseline += lineHeight;
				}

				if (answer.doodle) {
					drawDoodle(context, {kind: answer.doodle, x: 250, y: Math.min(baseline - 4, 200)}, penColor);
				}
			}

			context.restore();

			if (shown.stamp) {
				// A note that was caught gets the red stamp of the teacher’s desk drawer.
				context.save();
				context.translate(225, 160);
				context.rotate(-0.25);
				context.strokeStyle = '#cc1111';
				context.fillStyle = '#cc1111';
				context.lineWidth = 3;
				context.strokeRect(-62, -18, 124, 30);
				context.font = 'bold 15px "Courier New", monospace';
				context.textAlign = 'center';
				context.fillText(shown.stamp, 0, 3);
				context.restore();
			}
		};

		const drawFolding = (context, kind, progress) => {
			context.fillStyle = '#b89b72';
			context.fillRect(0, 0, paper.width, paper.height);
			const shapes = foldShapes[kind];
			const position = progress * (shapes.length - 1);
			const step = Math.min(Math.floor(position), shapes.length - 2);
			const amount = position - step;
			const points = shapes[step].map((point, index) => [lerp(point[0], shapes[step + 1][index][0], amount), lerp(point[1], shapes[step + 1][index][1], amount)]);

			context.save();
			context.shadowColor = '#00000040';
			context.shadowOffsetX = 3;
			context.shadowOffsetY = 3;
			context.beginPath();
			for (const point of points) {
				context.lineTo(point[0], point[1]);
			}

			context.closePath();
			// The back of the paper shows between the folds, a bit darker.
			context.fillStyle = (step % 2 === 1) && amount < 0.5 ? '#ecece4' : '#fdfdf6';
			context.fill();
			context.restore();

			context.save();
			context.clip();
			context.strokeStyle = '#9ec3e6';
			context.lineWidth = 1;
			for (let y = 0; y < paper.height; y += 10) {
				context.beginPath();
				context.moveTo(0, y);
				context.lineTo(paper.width, y);
				context.stroke();
			}

			// The creases of the folds.
			context.strokeStyle = '#c8c8bc';
			context.lineWidth = 1.2;
			const xs = points.map(point => point[0]);
			const ys = points.map(point => point[1]);
			const middle = (Math.min(...xs) + Math.max(...xs)) / 2;
			const middleY = (Math.min(...ys) + Math.max(...ys)) / 2;
			for (const point of points) {
				context.beginPath();
				context.moveTo(middle, middleY);
				context.lineTo(point[0], point[1]);
				context.stroke();
			}

			context.restore();

			context.strokeStyle = '#8a8a7a';
			context.lineWidth = 1;
			context.beginPath();
			for (const point of points) {
				context.lineTo(point[0], point[1]);
			}

			context.closePath();
			context.stroke();

			if (progress >= 1) {
				context.fillStyle = '#3a2a10';
				context.font = `bold 14px ${handwriting}`;
				context.textAlign = 'center';
				if (kind === 'square') {
					context.fillStyle = '#c2185b';
					context.font = `bold 9px ${handwriting}`;
					context.fillText('PULL', 207, 79);
					context.fillStyle = '#3a3a4a';
					context.font = `13px ${handwriting}`;
					context.fillText(`Til ${note ? kidNamed(note.to).name : ''}`, 160, 82);
				}

				context.fillStyle = '#fff8d0';
				context.font = `bold 14px ${handwriting}`;
				context.fillText(holder === sindre.index && !flight ? (game.state === 'playing' ? 'Ready! It is on my desk.' : 'Ready! Now start the lesson.') : 'It is on its way…', 160, 228);
				context.textAlign = 'left';
			}
		};

		const drawPaper = () => {
			if (paperView === 'folding' || paperView === 'folded') {
				drawFolding(paperContext, foldKind, paperView === 'folded' ? 1 : foldProgress);
			} else if (paperView === 'saved' && shownNote) {
				drawNote(paperContext, shownNote);
			} else {
				drawNote(paperContext, draft, {isDraft: true});
			}
		};

		const readDraft = () => {
			draft.text = textField.value;
			draft.boxes = boxesCheckbox.checked;
			draft.to = recipientSelect.value;
		};

		// Going back to the draft unfolds a note that is still on my desk, as it has not gone anywhere yet.
		const showDraft = () => {
			if (note && holder === sindre.index && !flight && paperView !== 'draft') {
				note = undefined;
				holder = undefined;
				this.say('You unfold the note again to change it.');
				requestDraw();
			}

			paperView = 'draft';
			isPaperEmptyWarning = false;
			readDraft();
			drawPaper();
		};

		this.on(textField, 'input', showDraft);
		this.on(boxesCheckbox, 'change', showDraft);
		this.on(recipientSelect, 'change', () => {
			showDraft();
			this.say(recipientSelect.value === 'trond' ? 'To Trond, my best friend. He sits by the window, two desks away.' : 'To Ingrid, two rows in front of me. My heart is beating.');
		});

		this.on(classicButton, 'click', () => {
			textField.value = classicText;
			boxesCheckbox.checked = true;
			showDraft();
			sound.paper();
			this.say('The classic: “Liker du meg?” (Do you like me?) with three boxes, Ja, Nei, and Kanskje (Yes, No, Maybe).');
		});

		// A doodle goes on a free spot of the paper, away from the text, and a new doodle does not land on an old one.
		const freeSpot = () => {
			let best;
			for (let attempt = 0; attempt < 30; attempt++) {
				const spot = {x: randomBetween(78, 284), y: randomBetween(120, 205)};
				const distance = Math.min(999, ...draft.doodles.map(doodle => Math.hypot(doodle.x - spot.x, doodle.y - spot.y)));
				if (!best || distance > best.distance) {
					best = {...spot, distance};
				}
			}

			return {x: Math.round(best.x), y: Math.round(best.y)};
		};

		const doodleNames = {
			heart: 'a heart',
			smiley: 'a smiley',
			star: 'a star',
			unicorn: 'Glitter the unicorn',
			rock: 'Rocky the pet rock',
			teacher: 'Fru Hansen with horns. Do not get caught with this one',
		};

		for (const button of doodleButtons) {
			this.on(button, 'click', () => {
				const kind = button.dataset.classNotesDoodle;
				if (kind === 'erase') {
					draft.doodles = [];
					draft.strokes = [];
					this.say('You rub out all the doodles with the eraser that smells of strawberries.');
				} else {
					if (draft.doodles.length >= 10) {
						draft.doodles.shift();
					}

					draft.doodles.push({kind, ...freeSpot()});
					this.say(`You draw ${doodleNames[kind]}.`);
				}

				sound.burst(0.15, {volume: 0.06, frequency: 2500, type: 'bandpass'});
				showDraft();
			});
		}

		// The pencil: a drag on the paper draws. The points are kept small, so the notes fit in the pencil case.
		const maxPoints = 600;
		let stroke;
		let pencil = {x: 160, y: 150};

		const pointCount = () => draft.strokes.flat().length;

		this.on(paper, 'pointerdown', event => {
			if (paperView !== 'draft') {
				showDraft();
			}

			if (pointCount() >= maxPoints) {
				this.say('The paper is full of doodles. Erase them first.');
				return;
			}

			paper.setPointerCapture(event.pointerId);
			const point = canvasPoint(paper, event);
			stroke = [[Math.round(point.x), Math.round(point.y)]];
			draft.strokes.push(stroke);
			isPaperEmptyWarning = false;
			drawPaper();
		});

		this.on(paper, 'pointermove', event => {
			if (!stroke || pointCount() >= maxPoints) {
				return;
			}

			const point = canvasPoint(paper, event);
			const last = stroke.at(-1);
			if (Math.hypot(point.x - last[0], point.y - last[1]) >= 2) {
				stroke.push([Math.round(point.x), Math.round(point.y)]);
				drawPaper();
			}
		});

		const endStroke = () => {
			stroke = undefined;
		};

		this.on(paper, 'pointerup', endStroke);
		this.on(paper, 'pointercancel', endStroke);

		// The arrow keys draw with the pencil, a short line at a time.
		this.on(paper, 'keydown', event => {
			const moves = {ArrowLeft: [-6, 0], ArrowRight: [6, 0], ArrowUp: [0, -6], ArrowDown: [0, 6]};
			const move = moves[event.key];
			if (!move || event.altKey || event.ctrlKey || event.metaKey) {
				return;
			}

			event.preventDefault();
			if (paperView !== 'draft') {
				showDraft();
			}

			if (pointCount() >= maxPoints) {
				this.say('The paper is full of doodles. Erase them first.');
				return;
			}

			const from = [Math.round(pencil.x), Math.round(pencil.y)];
			pencil = {x: clamp(pencil.x + move[0], paperLeft + 4, paperRight - 4), y: clamp(pencil.y + move[1], paperTop + 8, paperBottom - 4)};
			if (Math.round(pencil.x) === from[0] && Math.round(pencil.y) === from[1]) {
				return;
			}
			const lastStroke = draft.strokes.at(-1);
			if (lastStroke?.isKeyboard && lastStroke.at(-1)[0] === from[0] && lastStroke.at(-1)[1] === from[1]) {
				lastStroke.push([Math.round(pencil.x), Math.round(pencil.y)]);
			} else {
				const line = [from, [Math.round(pencil.x), Math.round(pencil.y)]];
				line.isKeyboard = true;
				draft.strokes.push(line);
			}

			isPaperEmptyWarning = false;
			drawPaper();
		});

		// Folds the note, and puts it on my desk.
		const fold = kind => {
			readDraft();
			if (note && (holder !== sindre.index || flight || busy)) {
				this.say('One note at a time! The other one is still on its way.');
				return;
			}

			if (!draft.text.trim() && !draft.boxes && draft.doodles.length === 0 && draft.strokes.length === 0) {
				// The paper says it too, as the status line can be below the screen.
				showDraft();
				isPaperEmptyWarning = true;
				drawPaper();
				this.say('The paper is empty! Write something first, or use the classic.');
				textField.focus();
				return;
			}

			note = {
				text: draft.text.trim(),
				to: draft.to,
				boxes: draft.boxes,
				doodles: draft.doodles.map(doodle => ({...doodle})),
				strokes: draft.strokes.map(line => line.map(point => [...point])),
				fold: kind,
				kevin: false,
			};
			holder = sindre.index;
			foldKind = kind;
			foldFocus = document.activeElement;
			foldProgress = this.reducedMotion ? 1 : 0;
			paperView = this.reducedMotion ? 'folded' : 'folding';
			sound.paper();
			const advice = {
				football: 'It slides fast from desk to desk.',
				square: 'It is slow to pass, but Kevin can never find out how the pull tab works.',
				airplane: 'Click a desk to throw it there, over everyone. Fast, but the wind decides where it lands.',
			};
			this.say(`You fold it into ${foldNames[kind]}. ${advice[kind]}${game.state === 'playing' ? '' : ' Now start the lesson.'}`);
			drawPaper();
			if (paperView === 'folded' && game.state === 'playing') {
				showClassroom();
			}

			requestDraw();
			loop.start();
			foldLoop.start();
		};

		for (const button of foldButtons) {
			this.on(button, 'click', () => {
				fold(button.dataset.classNotesFold);
			});
		}

		// The pencil case, where every note ends up, answered, caught, or saved by the bell.
		const outcomeLabels = {
			answered: entry => `✉️ ${kidNamed(entry.to).name}: ${entry.reply?.box ? (entry.reply.box === 'Venner' ? '☑ Bare venner' : `☑ ${entry.reply.box}`) : (entry.reply?.text ? `“${entry.reply.text.length > 24 ? `${entry.reply.text.slice(0, 22)}…` : entry.reply.text}”` : 'a doodle')}`,
			caught: entry => `🚨 Caught by ${entry.teacher}`,
			bell: entry => `🔔 To ${kidNamed(entry.to).name}: saved by the bell`,
		};

		const showPencilCase = () => {
			pencilCaseList.replaceChildren();
			if (pencilCase.length === 0) {
				const item = document.createElement('li');
				item.textContent = 'Empty, except for a chewed pencil and an eraser that smells of strawberries.';
				pencilCaseList.append(item);
				emptyButton.disabled = true;
				return;
			}

			emptyButton.disabled = false;
			for (const entry of pencilCase) {
				const item = document.createElement('li');
				const button = document.createElement('button');
				button.type = 'button';
				button.textContent = (outcomeLabels[entry.outcome] ?? outcomeLabels.answered)(entry);
				// The buttons are made again each time the pencil case changes, so their listeners go away with them.
				button.addEventListener('click', () => {
					shownNote = entry;
					paperView = 'saved';
					drawPaper();
					this.say(`A note from the pencil case: “${entry.text || 'just doodles'}”${entry.reply?.english ? `. The answer: ${entry.reply.english}` : ''}`);
					paper.scrollIntoView({behavior: this.reducedMotion ? 'auto' : 'smooth', block: 'nearest'});
				});
				item.append(button);
				pencilCaseList.append(item);
			}
		};

		const keep = (entry, outcome) => {
			pencilCase.unshift({...entry, outcome, teacher: lesson().teacher});
			pencilCase = pencilCase.slice(0, 12);
			this.store('case', pencilCase);
			showPencilCase();
		};

		this.on(emptyButton, 'click', () => {
			pencilCase = [];
			this.store('case', pencilCase);
			showPencilCase();
			this.say('You empty the pencil case into the trash can. Mamma would never read them anyway.');
		});

		// Shows how a note ended on the paper, unless the visitor is writing the next note there. It is in the pencil case either way.
		const showAnswer = entry => {
			if (paperView === 'draft') {
				return;
			}

			shownNote = entry;
			paperView = 'saved';
			drawPaper();
		};

		// The classroom canvas.
		const mixColor = (from, to, amount) => {
			const first = Number.parseInt(from.slice(1), 16);
			const second = Number.parseInt(to.slice(1), 16);
			const channel = shift => Math.round(lerp((first >> shift) & 255, (second >> shift) & 255, amount));
			return `rgb(${channel(16)} ${channel(8)} ${channel(0)})`;
		};

		let clock = 0;

		const drawRoom = () => {
			const width = room.width;
			const height = room.height;

			// The linoleum floor, in tiles.
			context.fillStyle = '#d9d0b8';
			context.fillRect(0, 0, width, height);
			context.strokeStyle = '#cbc1a6';
			context.lineWidth = 1;
			for (let x = 0; x < width; x += 40) {
				context.beginPath();
				context.moveTo(x, 90);
				context.lineTo(x, height);
				context.stroke();
			}

			for (let y = 90; y < height; y += 40) {
				context.beginPath();
				context.moveTo(0, y);
				context.lineTo(width, y);
				context.stroke();
			}

			// The windows on the left wall, with the rain of Bergen running down them.
			context.fillStyle = '#7e8f9e';
			context.fillRect(0, 100, 12, 290);
			context.strokeStyle = '#d8e3ec';
			context.lineWidth = 1;
			for (let index = 0; index < 14; index++) {
				const y = 100 + ((index * 41 + (this.reducedMotion ? 0 : clock * 60)) % 290);
				context.beginPath();
				context.moveTo(3 + ((index * 5) % 8), y);
				context.lineTo(3 + ((index * 5) % 8), y + 6);
				context.stroke();
			}

			context.fillStyle = '#ffffff';
			for (const y of [100, 197, 294, 390]) {
				context.fillRect(0, y - 2, 12, 3);
			}

			drawBoard();
			drawClock();
			drawTeacherDesk();

			for (const kid of kids) {
				drawKid(kid);
			}

			drawTeacher();
			drawFlight();
			drawReply();

			for (const item of bubbles) {
				drawBubble(item.x, item.y, item.text);
			}

			drawHover();

			if (game.state === 'ready') {
				drawBanner(note ? 'Now press Start the Lesson!' : 'Write a note, fold it, and start the lesson!');
			} else if (game.state === 'over') {
				drawBanner('RIIIIING! FRIMINUTT! (Break time!)');
			}
		};

		// The banner hangs on the lower half of the blackboard, like a note taped to it, so it does not cover the names of the kids or the teacher.
		const drawBanner = text => {
			context.save();
			context.font = `bold 15px ${handwriting}`;
			const textWidth = context.measureText(text).width;
			const centerX = (boardLeft + boardRight) / 2;
			context.fillStyle = '#fff68fee';
			context.strokeStyle = '#000000';
			context.lineWidth = 2;
			context.beginPath();
			context.roundRect(centerX - (textWidth / 2) - 12, 48, textWidth + 24, 30, 6);
			context.fill();
			context.stroke();
			context.fillStyle = '#000000';
			context.textAlign = 'center';
			context.fillText(text, centerX, 68);
			context.restore();
		};

		const boardLeft = 10;
		const boardRight = 396;
		const boardTop = 6;
		const boardBottom = 82;

		const chalkFont = `13px ${handwriting}`;
		const boardLineHeight = 13.5;

		const boardLinePosition = (line, index) => {
			context.font = chalkFont;
			const digit = context.measureText('0').width;
			return {x: boardLeft + 18 + (line.column * digit), y: boardTop + 17 + (index * boardLineHeight)};
		};

		// Where the chalk is now, so the teacher stands there.
		const chalkPoint = () => {
			let remaining = Math.floor(teacher.written);
			context.font = chalkFont;
			for (const [index, line] of teacher.board.entries()) {
				const position = boardLinePosition(line, index);
				if (remaining <= line.text.length) {
					return {x: position.x + context.measureText(line.text.slice(0, remaining)).width, y: position.y - 4};
				}

				remaining -= line.text.length;
			}

			const last = teacher.board.length - 1;
			return last < 0 ? {x: 120, y: 30} : {x: boardLinePosition(teacher.board[last], last).x + 40, y: boardLinePosition(teacher.board[last], last).y};
		};

		const boardLength = () => teacher.board.map(line => line.text).join('').length;

		const drawBoard = () => {
			context.fillStyle = '#8b5a2b';
			context.fillRect(boardLeft - 6, boardTop - 4, boardRight - boardLeft + 12, boardBottom - boardTop + 14);
			context.fillStyle = '#2f4f3a';
			context.fillRect(boardLeft, boardTop, boardRight - boardLeft, boardBottom - boardTop);

			// The smudges of chalk that never wipe off.
			context.fillStyle = '#ffffff0a';
			for (const [x, y, radiusX, radiusY] of [[110, 30, 70, 22], [290, 52, 60, 18]]) {
				context.beginPath();
				context.ellipse(x, y, radiusX, radiusY, 0.1, 0, Math.PI * 2);
				context.fill();
			}

			context.save();
			context.beginPath();
			context.rect(boardLeft, boardTop, boardRight - boardLeft, boardBottom - boardTop);
			context.clip();
			context.font = chalkFont;
			context.fillStyle = '#f2f2e6';
			let remaining = Math.floor(teacher.written);
			for (const [index, line] of teacher.board.entries()) {
				// With reduced motion, a line shows when it is done, instead of letter by letter.
				if (remaining <= 0 || (this.reducedMotion && remaining < line.text.length)) {
					break;
				}

				const position = boardLinePosition(line, index);
				context.fillText(line.text.slice(0, remaining), position.x, position.y);
				remaining -= line.text.length;
			}

			if (teacher.wipe > 0) {
				// The sponge wipes the board from the left.
				const wiped = boardLeft + ((boardRight - boardLeft) * (1 - (teacher.wipe / wipeTime)));
				context.fillStyle = '#2f4f3a';
				context.fillRect(boardLeft, boardTop, wiped - boardLeft, boardBottom - boardTop);
				context.fillStyle = '#e8c547';
				context.fillRect(wiped - 10, boardTop + 30, 18, 12);
			}

			context.restore();

			// The chalk ledge is the risk meter: the more the teacher suspects, the redder it gets.
			context.fillStyle = '#6b4423';
			context.fillRect(boardLeft - 6, boardBottom, boardRight - boardLeft + 12, 8);
			const risk = game.suspicion / 100;
			context.fillStyle = risk > 0.75 ? '#ff2a2a' : (risk > 0.4 ? '#ffaa00' : '#5fd35f');
			context.fillRect(boardLeft + 32, boardBottom + 2, (boardRight - boardLeft - 34) * risk, 4);
			context.fillStyle = '#ffffff';
			context.font = 'bold 7px sans-serif';
			context.fillText('RISK', boardLeft + 6, boardBottom + 7);
		};

		const drawClock = () => {
			const x = 442;
			const y = 46;
			context.fillStyle = '#ffffff';
			context.strokeStyle = '#333333';
			context.lineWidth = 3;
			context.beginPath();
			context.arc(x, y, 26, 0, Math.PI * 2);
			context.fill();
			context.stroke();
			context.lineWidth = 1;
			for (let index = 0; index < 12; index++) {
				const angle = index * Math.PI / 6;
				context.beginPath();
				context.moveTo(x + (Math.cos(angle) * 21), y + (Math.sin(angle) * 21));
				context.lineTo(x + (Math.cos(angle) * 24), y + (Math.sin(angle) * 24));
				context.stroke();
			}

			// The lesson goes from 08:15 to 09:00.
			const minutes = 15 + Math.min(45, game.time / lessonSeconds * 45);
			const minuteAngle = (minutes / 60 * Math.PI * 2) - (Math.PI / 2);
			const hourAngle = ((8 + (minutes / 60)) / 12 * Math.PI * 2) - (Math.PI / 2);
			context.lineCap = 'round';
			context.lineWidth = 3;
			context.beginPath();
			context.moveTo(x, y);
			context.lineTo(x + (Math.cos(hourAngle) * 12), y + (Math.sin(hourAngle) * 12));
			context.stroke();
			context.lineWidth = 2;
			context.beginPath();
			context.moveTo(x, y);
			context.lineTo(x + (Math.cos(minuteAngle) * 19), y + (Math.sin(minuteAngle) * 19));
			context.stroke();
			context.lineCap = 'butt';
		};

		const drawTeacherDesk = () => {
			context.fillStyle = '#9a6a3a';
			context.strokeStyle = '#5a3a1a';
			context.lineWidth = 2;
			context.beginPath();
			context.roundRect(teacherDesk.x, teacherDesk.y, teacherDesk.width, teacherDesk.height, 3);
			context.fill();
			context.stroke();

			// The red pen, the stack of homework, and the apple.
			context.fillStyle = '#f5f5f0';
			context.fillRect(teacherDesk.x + 6, teacherDesk.y + 5, 22, 16);
			context.fillStyle = '#cc2222';
			context.fillRect(teacherDesk.x + 32, teacherDesk.y + 10, 18, 3);
			context.beginPath();
			context.arc(teacherDesk.x + 60, teacherDesk.y + 12, 5, 0, Math.PI * 2);
			context.fill();
		};

		const isLaughing = () => game.laughUntil > clock;

		const drawKid = kid => {
			const {x, y} = kid;
			const isBusy = busy?.kid === kid.index;
			const isHolder = holder === kid.index && !flight;
			const bob = this.reducedMotion || !isLaughing() ? 0 : Math.sin((clock * 18) + kid.index) * 1.5;

			// The desk, with a pencil and an eraser on it.
			context.fillStyle = kid.kind === 'you' ? '#d8aa70' : '#c89a62';
			context.strokeStyle = '#7a5530';
			context.lineWidth = 1.5;
			context.beginPath();
			context.roundRect(x - 40, y - 30, 80, 18, 3);
			context.fill();
			context.stroke();
			context.fillStyle = '#f2c94c';
			context.fillRect(x + 14, y - 25, 16, 2.5);
			context.fillStyle = '#ff9eb5';
			context.fillRect(x - 32, y - 26, 8, 5);

			// The note on the desk.
			if (isHolder && note) {
				drawFoldedNote(x - 8, y - 22, note.fold, 1);
			}

			// The shoulders and the shirt.
			context.fillStyle = kid.shirt;
			context.beginPath();
			context.ellipse(x, y + 10 + bob, 16, 8, 0, 0, Math.PI * 2);
			context.fill();

			// The hand up of a snitch who tells.
			if (isBusy && busy.kind === 'snitch') {
				context.strokeStyle = kid.shirt;
				context.lineWidth = 5;
				context.lineCap = 'round';
				context.beginPath();
				context.moveTo(x + 12, y + 6);
				context.lineTo(x + 16, y - 26);
				context.stroke();
				context.lineCap = 'butt';
				context.fillStyle = '#f2c9a0';
				context.beginPath();
				context.arc(x + 16, y - 29, 4.5, 0, Math.PI * 2);
				context.fill();
			}

			// The long hair, behind the head.
			if (kid.isLongHair) {
				context.fillStyle = kid.hair;
				context.beginPath();
				context.roundRect(x - 12, y - 10 + bob, 24, 20, 6);
				context.fill();
			}

			// The face, which turns red when Sindre is embarrassed.
			const skin = kid.kind === 'you' ? mixColor('#f2c9a0', '#ff3b30', game.blush) : '#f2c9a0';
			context.fillStyle = skin;
			context.beginPath();
			context.arc(x, y - 1 + bob, 10, 0, Math.PI * 2);
			context.fill();
			context.fillStyle = kid.hair;
			context.beginPath();
			context.arc(x, y - 3 + bob, 10.5, Math.PI * 1.05, Math.PI * 1.95);
			context.fill();

			const eyeY = y - 2 + bob;
			context.fillStyle = '#222222';
			context.strokeStyle = '#222222';
			context.lineWidth = 1.3;
			const isAsleep = kid.kind === 'sleeper' && !(isBusy && busy.kind === 'waking');
			if (isAsleep) {
				context.beginPath();
				context.moveTo(x - 6, eyeY);
				context.lineTo(x - 2, eyeY);
				context.moveTo(x + 2, eyeY);
				context.lineTo(x + 6, eyeY);
				context.stroke();
			} else if (isLaughing() && kid.kind !== 'you') {
				context.beginPath();
				context.moveTo(x - 6, eyeY + 1);
				context.lineTo(x - 4, eyeY - 1);
				context.lineTo(x - 2, eyeY + 1);
				context.moveTo(x + 2, eyeY + 1);
				context.lineTo(x + 4, eyeY - 1);
				context.lineTo(x + 6, eyeY + 1);
				context.stroke();
				context.beginPath();
				context.arc(x, y + 3 + bob, 3.5, 0, Math.PI);
				context.fill();
			} else {
				const look = isBusy && busy.kind === 'reading' ? 1.5 : 0;
				context.fillRect(x - 5, eyeY + look, 2.2, 2.2);
				context.fillRect(x + 3, eyeY + look, 2.2, 2.2);
				context.beginPath();
				if (kid.kind === 'you' && game.blush > 0.3) {
					context.moveTo(x - 3, y + 5);
					context.lineTo(x + 3, y + 4);
				} else {
					context.arc(x, y + 2 + bob, 3, 0.3, Math.PI - 0.3);
				}

				context.stroke();
			}

			// Kevin holds the note open in front of him while he reads it.
			if (isBusy && (busy.kind === 'reading' || busy.kind === 'fumbling' || busy.kind === 'replying')) {
				context.fillStyle = '#fdfdf6';
				context.strokeStyle = '#9ec3e6';
				context.lineWidth = 1;
				context.fillRect(x - 9, y + 6, 18, 12);
				context.strokeRect(x - 9, y + 6, 18, 12);
			}

			if (isAsleep && !this.reducedMotion) {
				context.fillStyle = '#3355aa';
				context.font = `bold ${9 + ((clock * 2) % 1) * 3}px ${handwriting}`;
				context.fillText('z', x + 10 + ((clock * 8) % 8), y - 12 - ((clock * 10) % 10));
			} else if (isAsleep) {
				context.fillStyle = '#3355aa';
				context.font = `bold 10px ${handwriting}`;
				context.fillText('z z', x + 11, y - 12);
			}

			// The name, and what the kid is like. On a small screen, like a phone, the name is drawn bigger, so it stays readable, but it still fits under the desk.
			const trait = traits[kid.kind];
			context.font = `bold ${clamp(9 * room.width / room.clientWidth, 9, 13)}px sans-serif`;
			context.textAlign = 'center';
			context.fillStyle = kid.kind === 'you' ? '#003399' : '#2a2a2a';
			context.fillText(`${kid.name}${trait.icon ? ` ${trait.icon}` : ''}`, x, y + 28);
			context.textAlign = 'left';

			// The desks the note can go to next have a dashed line around them.
			if (canPass() && note && note.fold !== 'airplane' && neighbors(kids[holder]).includes(kid)) {
				context.strokeStyle = hovered === kid.index ? '#ff6600' : '#cc8800';
				context.lineWidth = hovered === kid.index ? 3 : 2;
				context.setLineDash([5, 4]);
				context.beginPath();
				context.roundRect(x - 45, y - 34, 90, 66, 8);
				context.stroke();
				context.setLineDash([]);
			}
		};

		const drawFoldedNote = (x, y, kind, scale, angle = 0) => {
			context.save();
			context.translate(x, y);
			context.rotate(angle);
			context.scale(scale, scale);
			context.fillStyle = '#fdfdf6';
			context.strokeStyle = '#777777';
			context.lineWidth = 1;
			context.beginPath();
			if (kind === 'football') {
				context.moveTo(0, -7);
				context.lineTo(9, 6);
				context.lineTo(-9, 6);
			} else if (kind === 'square') {
				context.rect(-7, -7, 14, 14);
				context.moveTo(7, -2);
				context.lineTo(11, 0);
				context.lineTo(7, 2);
			} else {
				context.moveTo(0, -10);
				context.lineTo(9, 8);
				context.lineTo(0, 5);
				context.lineTo(-9, 8);
			}

			context.closePath();
			context.fill();
			context.stroke();
			context.restore();
		};

		// A note on its way: it slides across the desks, or flies in an arc with its shadow on the floor.
		const flightPosition = () => {
			const amount = this.reducedMotion ? 0.5 : clamp(flight.time / flight.duration, 0, 1);
			const x = lerp(flight.from.x, flight.to.x, amount);
			const y = lerp(flight.from.y, flight.to.y, amount);
			const height = flight.isThrown ? Math.sin(amount * Math.PI) * flight.height : 0;
			const wobble = flight.isThrown && !this.reducedMotion ? Math.sin(flight.time * 14) * 4 : 0;
			return {x: x + wobble, y, height};
		};

		const drawFlight = () => {
			if (!flight) {
				return;
			}

			const {x, y, height} = flightPosition();
			if (flight.isThrown) {
				context.fillStyle = '#00000030';
				context.beginPath();
				context.ellipse(x, y, 9, 4, 0, 0, Math.PI * 2);
				context.fill();
			}

			// The airplane points where it flies.
			const angle = flight.kind === 'airplane' ? Math.atan2(flight.to.y - flight.from.y, flight.to.x - flight.from.x) + (Math.PI / 2) : 0;
			drawFoldedNote(x, y - height, flight.kind, 1 + (height / 60), angle);
		};

		// The answer slides back to my desk along the floor.
		const drawReply = () => {
			if (!reply || reply.duration === 0) {
				return;
			}

			const amount = clamp(reply.time / reply.duration, 0, 1);
			drawFoldedNote(lerp(reply.from.x, sindre.x, amount), lerp(reply.from.y, sindre.y - 20, amount), 'square', 0.8);
		};

		const drawBubble = (x, y, text) => {
			context.save();
			context.font = `bold 11px ${handwriting}`;
			const textWidth = context.measureText(text).width;
			const left = clamp(x - (textWidth / 2) - 6, 2, room.width - textWidth - 14);
			const top = clamp(y - 22, 2, room.height - 22);
			context.fillStyle = '#ffffff';
			context.strokeStyle = '#000000';
			context.lineWidth = 1.5;
			context.beginPath();
			context.roundRect(left, top, textWidth + 12, 18, 8);
			context.fill();
			context.stroke();
			context.fillStyle = '#000000';
			context.fillText(text, left + 6, top + 13);
			context.restore();
		};

		const drawHover = () => {
			if (hovered === undefined) {
				return;
			}

			const kid = kids[hovered];
			const text = `${kid.name}: ${traits[kid.kind].text}`;
			context.save();
			context.font = 'bold 10px sans-serif';
			const textWidth = context.measureText(text).width;
			const left = clamp(kid.x - (textWidth / 2) - 5, 2, room.width - textWidth - 12);
			context.fillStyle = '#ffffe1';
			context.strokeStyle = '#000000';
			context.lineWidth = 1;
			context.fillRect(left, kid.y + 32, textWidth + 10, 15);
			context.strokeRect(left, kid.y + 32, textWidth + 10, 15);
			context.fillStyle = '#000000';
			context.fillText(text, left + 5, kid.y + 43);
			context.restore();
		};

		const drawTeacher = () => {
			const current = lesson();
			if (current.neverTurns) {
				drawSubstitute();
				return;
			}

			const x = teacher.x;
			const y = 104;
			const face = teacher.face;
			// The turn squeezes her sideways, like a turn seen from above.
			const squeeze = Math.max(0.25, Math.abs(Math.cos(face * Math.PI)));
			const isFront = face >= 0.5;
			const dress = current.isWoman ? '#7a3b69' : '#2d3142';

			context.save();
			context.translate(x, y);
			context.scale(squeeze, 1);
			context.fillStyle = dress;
			context.beginPath();
			context.ellipse(0, 12, 20, 10, 0, 0, Math.PI * 2);
			context.fill();

			// The arm up to the chalk while she writes.
			if (!isFront && teacher.state === 'writing') {
				const point = chalkPoint();
				context.restore();
				context.strokeStyle = dress;
				context.lineWidth = 6;
				context.lineCap = 'round';
				context.beginPath();
				context.moveTo(x + 10, y + 6);
				context.lineTo(clamp(point.x, x - 30, x + 40), Math.max(point.y + 6, y - 30));
				context.stroke();
				context.lineCap = 'butt';
				context.save();
				context.translate(x, y);
				context.scale(squeeze, 1);
			}

			const skin = '#f0c4a0';
			if (current.isWoman) {
				context.fillStyle = '#8a7a6a';
				context.beginPath();
				context.arc(0, 0, 13, 0, Math.PI * 2);
				context.fill();
			} else {
				context.fillStyle = skin;
				context.beginPath();
				context.arc(0, 0, 13, 0, Math.PI * 2);
				context.fill();
			}

			if (isFront) {
				context.fillStyle = skin;
				context.beginPath();
				context.arc(0, 2, current.isWoman ? 10 : 12, 0, Math.PI * 2);
				context.fill();
				if (!current.isWoman) {
					context.fillStyle = '#bbbbbb';
					context.fillRect(-13, -2, 4, 8);
					context.fillRect(9, -2, 4, 8);
				}

				// The glasses and the look that sees everything.
				context.strokeStyle = '#222222';
				context.lineWidth = 1.3;
				for (const offset of [-4.5, 4.5]) {
					context.beginPath();
					context.arc(offset, 0, 3.5, 0, Math.PI * 2);
					context.stroke();
				}

				context.fillStyle = '#222222';
				context.fillRect(-5, -0.5, 1.8, 1.8);
				context.fillRect(4, -0.5, 1.8, 1.8);
				context.beginPath();
				context.moveTo(-8, -6);
				context.lineTo(-2, -4);
				context.moveTo(8, -6);
				context.lineTo(2, -4);
				context.moveTo(-3, 7);
				context.lineTo(3, 7);
				context.stroke();
			} else if (current.isWoman) {
				// The bun of Fru Hansen, from behind.
				context.fillStyle = '#6e5e50';
				context.beginPath();
				context.arc(0, 4, 6, 0, Math.PI * 2);
				context.fill();
			} else {
				// The bald spot of the principal, from behind.
				context.fillStyle = '#bbbbbb';
				context.beginPath();
				context.arc(0, 2, 13, Math.PI * 0.1, Math.PI * 0.9);
				context.fill();
			}

			context.restore();

			// The note she holds while she reads it out loud.
			if (teacher.state === 'reading') {
				context.fillStyle = '#fdfdf6';
				context.strokeStyle = '#9ec3e6';
				context.fillRect(x - 12, y + 12, 24, 16);
				context.strokeRect(x - 12, y + 12, 24, 16);
			}
		};

		// The substitute sits at the teacher’s desk behind the newspaper, and only lowers it when the class gets too loud.
		const drawSubstitute = () => {
			const x = teacherDesk.x + 35;
			const y = teacherDesk.y + 4;
			const isLooking = teacher.state === 'looking' || teacher.state === 'reading';
			context.fillStyle = '#556b2f';
			context.beginPath();
			context.ellipse(x, y + 4, 18, 9, 0, 0, Math.PI * 2);
			context.fill();
			context.fillStyle = '#f0c4a0';
			context.beginPath();
			context.arc(x, y - 6, 11, 0, Math.PI * 2);
			context.fill();
			context.fillStyle = '#444444';
			context.fillRect(x - 6, y - 4, 12, 3);
			if (isLooking) {
				context.fillStyle = '#222222';
				context.fillRect(x - 5, y - 9, 2, 2);
				context.fillRect(x + 3, y - 9, 2, 2);
			}

			// The newspaper of Bergen, Bergens Tidende, held up in front of his face.
			const paperY = isLooking ? y + 8 : y - 16;
			context.fillStyle = '#ecebe4';
			context.strokeStyle = '#888888';
			context.lineWidth = 1;
			context.fillRect(x - 32, paperY, 64, 26);
			context.strokeRect(x - 32, paperY, 64, 26);
			context.fillStyle = '#222222';
			context.font = 'bold 7px serif';
			context.textAlign = 'center';
			context.fillText('BERGENS TIDENDE', x, paperY + 9);
			context.textAlign = 'left';
			context.fillStyle = '#999999';
			for (let line = 0; line < 3; line++) {
				context.fillRect(x - 28, paperY + 13 + (line * 4), 56, 1.5);
			}
		};

		let isDrawQueued = false;

		// Draws again on the next frame when the loop does not run, like after a click before the lesson.
		const requestDraw = () => {
			if (loop.isRunning || isDrawQueued) {
				return;
			}

			isDrawQueued = true;
			requestAnimationFrame(() => {
				isDrawQueued = false;
				drawRoom();
				updateStats();
			});
		};

		const canPass = () => game.state === 'playing' && note && holder !== undefined && !flight && !busy && teacher.state !== 'reading';

		// Starts a note on its way to a kid, sliding or thrown.
		const send = (to, {isThrown = false, duration, height = 40, lands} = {}) => {
			const from = kids[holder];
			flight = {
				from: {x: from.x, y: from.y - 20},
				to: lands ?? {x: to.x, y: to.y - 20},
				toKid: to?.index,
				landsOnDesk: !to,
				kind: note.fold,
				isThrown,
				time: 0,
				duration,
				height,
			};
			drawPaper();
			loop.start();
		};

		const pass = kid => {
			if (game.state === 'ready') {
				this.say('Start the lesson first. Passing notes in the break is no fun.');
				return;
			}

			if (game.state === 'over') {
				this.say('The bell has rung. Start the next lesson.');
				return;
			}

			if (!note) {
				this.say('Write a note and fold it first!');
				return;
			}

			if (teacher.state === 'reading') {
				this.say(`Not now! ${lesson().pronoun} is still reading your last note out loud.`);
				return;
			}

			if (flight) {
				this.say('Wait, it is still on its way!');
				return;
			}

			if (busy) {
				const waits = {
					snitch: `${kids[busy.kid].name} has her hand up!`,
					reading: 'Wait! Kevin is still reading it.',
					fumbling: 'Wait! Kevin is still trying to open it.',
					sleeping: `${kids[busy.kid].name} is asleep on the note.`,
					waking: `${kids[busy.kid].name} is waking up.`,
					aiming: 'Stian is aiming…',
					replying: `${kids[busy.kid].name} is writing back!`,
				};
				this.say(waits[busy.kind] ?? 'Wait a moment.');
				return;
			}

			if (holder === kid.index) {
				return;
			}

			if (note.fold === 'airplane') {
				throwAirplane(kid);
				return;
			}

			if (!neighbors(kids[holder]).includes(kid)) {
				this.say(`${kids[holder].name} can only pass it to the desk next to them, in front, or behind.`);
				return;
			}

			send(kid, {duration: note.fold === 'square' ? 0.75 : 0.45});
			game.suspicion = clamp(game.suspicion + (5 * lesson().risk), 0, 100);
			sound.slide();
		};

		// The paper airplane goes over the whole class at once, but the wind and the aim decide where it lands.
		const throwAirplane = kid => {
			const angle = Math.random() * Math.PI * 2;
			const miss = Math.random() < 0.3 ? randomBetween(45, 90) : randomBetween(0, 25);
			const lands = {x: clamp(kid.x + (Math.cos(angle) * miss), 20, 470), y: clamp(kid.y - 20 + (Math.sin(angle) * miss), 92, 380)};
			// It lands on the nearest other desk, or at the front of the class when it flies too far.
			const nearest = kids.filter(other => other.index !== holder).sort((first, second) => Math.hypot(first.x - lands.x, first.y - 20 - lands.y) - Math.hypot(second.x - lands.x, second.y - 20 - lands.y))[0];
			const isAtTheFront = lands.y < 112 || (lands.y < 128 && lands.x > teacherDesk.x - 20);
			send(isAtTheFront ? undefined : nearest, {isThrown: true, duration: 1.1, height: 70, lands});
			game.suspicion = clamp(game.suspicion + (22 * lesson().risk), 0, 100);
			sound.whoosh(1.1);
			this.say(`Whoosh! The airplane flies over the class toward ${kid.name}…`);
		};

		// What happens when the note lands on a desk: each kid does what that kid does.
		const arrive = kid => {
			holder = kid.index;
			flight = undefined;
			drawPaper();
			sound.burst(0.06, {volume: 0.1, frequency: 2000, type: 'bandpass'});

			if (kid.name.toLowerCase() === note.to) {
				deliver(kid);
				return;
			}

			switch (kid.kind) {
				case 'snitch': {
					busy = {kid: kid.index, kind: 'snitch', time: 0.8};
					addBubble(kid.x, kid.y - 8, `${lesson().callName}!`, 1.4);
					this.say(`Oh no! ${kid.name} puts up her hand: “${lesson().callName}! Sindre sender lappar!” (Sindre is passing notes!)`);
					break;
				}

				case 'reader': {
					if (note.fold === 'square') {
						busy = {kid: kid.index, kind: 'fumbling', time: 1.2};
						addBubble(kid.x, kid.y - 8, 'Hæ? Korleis?', 1.2);
						this.say('Kevin tries to open it, but he can’t find out how the pull tab works. He gives up. Ha!');
					} else {
						busy = {kid: kid.index, kind: 'reading', time: 3};
						addBubble(kid.x, kid.y - 8, 'Hehehe…', 1.6);
						this.say('Kevin opens it and READS it. Then he writes something on it. Hurry, Kevin!');
						sound.paper();
					}

					break;
				}

				case 'sleeper': {
					busy = {kid: kid.index, kind: 'sleeping', time: randomBetween(2, 3.5)};
					this.say(`${kid.name} is asleep. The note lies on his desk, next to his drool.`);
					break;
				}

				case 'giggler': {
					game.suspicion = clamp(game.suspicion + (16 * lesson().risk), 0, 100);
					addBubble(kid.x, kid.y - 8, 'Hihihi!', 1.4);
					sound.giggle();
					this.say(`${kid.name} giggles. Shhh! The teacher heard that.`);
					break;
				}

				case 'thrower': {
					busy = {kid: kid.index, kind: 'aiming', time: 0.6};
					this.say('Stian aims like Ole Gunnar Solskjær in the final of the Champions League…');
					break;
				}

				case 'you': {
					this.say('The note is back on your desk.');
					break;
				}

				default: {
					this.say(`${kid.name} takes it and holds it under the desk. Who next?`);
					break;
				}
			}
		};

		// Stian throws it straight to the one it is for. A football flies best, and a miss can land on the teacher’s desk.
		const stianThrows = () => {
			const goal = target();
			const missChance = note.fold === 'football' ? 0.12 : 0.35;
			if (Math.random() < missChance) {
				if (Math.random() < 0.4) {
					send(undefined, {isThrown: true, duration: 0.9, height: 50, lands: {x: teacherDesk.x + 30, y: teacherDesk.y + 12}});
					this.say('Stian throws… and it lands on the teacher’s desk. Nooo!');
				} else {
					const other = randomItem(neighbors(goal));
					send(other, {isThrown: true, duration: 0.9, height: 50});
					this.say(`Stian throws… and misses. It lands on ${other.name}’s desk.`);
				}
			} else {
				send(goal, {isThrown: true, duration: 0.9, height: 50});
				this.say(`Stian throws… straight to ${goal.name}! What a shot!`);
			}

			game.suspicion = clamp(game.suspicion + (10 * lesson().risk), 0, 100);
			sound.whoosh(0.9);
		};

		const deliver = kid => {
			busy = {kid: kid.index, kind: 'replying', time: 2.5};
			addBubble(kid.x, kid.y - 8, kid.kind === 'crush' ? '♥?' : 'Hehe', 2);
			this.say(`It arrived! ${kid.name} unfolds it, reads it, and writes back…`);
			sound.paper();
		};

		// The answer comes back to my desk, under the desks, where no teacher looks.
		const answerComes = kid => {
			const sent = note;
			const answer = makeReply(sent);
			reply = {from: kid, time: 0, duration: this.reducedMotion ? 0 : 0.8};
			const entry = {...sent, reply: answer};
			note = undefined;
			holder = undefined;
			totals.answered++;
			game.answered++;
			this.store('totals', totals);
			keep(entry, 'answered');
			showAnswer(entry);
			this.say(`${kid.name} wrote back: ${answer.english}`);
			if (answer.isSweet) {
				sound.sweet();
				addBubble(sindre.x, sindre.y - 8, '♥ ♥ ♥', 2);
				if (kid.kind === 'crush') {
					this.celebrate();
				}
			} else if (answer.isSad) {
				sound.sad();
				addBubble(sindre.x, sindre.y - 8, ':(', 2);
			}
		};

		// What the teacher says after she reads a note out loud.
		const readingLine = sent => {
			const current = lesson();
			const parts = [];
			if (sent.boxes) {
				parts.push('Ja, nei, eller kanskje.');
			}

			if (sent.kevin) {
				parts.push('“Kevin var her.” Takk, Kevin.');
			}

			if (sent.doodles.some(doodle => doodle.kind === 'teacher')) {
				parts.push(current.isWoman ? 'Og er dette meg? Med horn?' : 'Og kven har teikna Fru Hansen med horn?');
			}

			parts.push(sent.to === 'ingrid' ? 'Til Ingrid. Så søtt!' : 'Til Trond. Ja vel.');
			if (current.teacher === 'Rektor Berg') {
				parts.push('Dette får foreldra dine høyre om.');
			}

			return parts.join(' ');
		};

		const catchNote = reason => {
			const sent = note;
			const current = lesson();
			flight = undefined;
			busy = undefined;
			note = undefined;
			holder = undefined;
			teacher.state = 'reading';
			teacher.face = 1;
			teacher.readTime = 0;
			totals.caught++;
			game.caught++;
			this.store('totals', totals);
			const confiscated = {...sent, stamp: 'CONFISCATED'};
			keep(confiscated, 'caught');
			showAnswer(confiscated);
			game.blush = 1;
			game.suspicion = 30;

			const text = sent.text || '…';
			const line = readingLine(sent);
			const speaker = document.createElement('strong');
			speaker.textContent = `${current.teacher} reads it out loud to the whole class:`;
			bubble.replaceChildren(speaker, `“${text}” ${line}`);
			bubble.dataset.state = 'shown';
			const isSpeaking = speak(`${text}. ${line}`, {
				pitch: current.pitch,
				// When the voice is done, she stops reading, after at least 3 seconds.
				onEnd() {
					teacher.readTarget = 3;
				},
			});
			// Without the voice, she reads about as fast as a teacher who wants everyone to hear it. With the voice, she reads until it is done, at most 15 seconds.
			teacher.readTarget = isSpeaking ? 15 : clamp(2.5 + ((text.length + line.length) * 0.045), 3, 8);
			sound.caught();
			this.say(`${reason} Caught! ${current.teacher} reads your note OUT LOUD to the whole class: “${text}”. Everyone laughs, and Sindre goes as red as a tomato.`);
			loop.start();
		};

		const finishReading = () => {
			game.laughUntil = clock + 2.6;
			sound.laugh();
			addBubble(kidNamed('kevin').x, kidNamed('kevin').y - 8, 'HAHAHA', 2.4);
			addBubble(kidNamed('lise').x, kidNamed('lise').y - 8, 'HIHIHI', 2.4);
			addBubble(kidNamed('trond').x, kidNamed('trond').y - 8, 'Hahaha!', 2.4);
			addBubble(sindre.x, sindre.y - 8, '😳', 3);
		};

		// The teacher: writes, gives a tell, turns around, looks, and turns back. A full risk meter makes her turn at once.
		const turnTime = 0.25;
		const wipeTime = 1.2;

		const startWriting = () => {
			const current = lesson();
			teacher.state = 'writing';
			const [minimum, maximum] = current.write;
			// The more she suspects, the sooner she turns again.
			teacher.timer = randomBetween(minimum, maximum) * (1 - (game.suspicion / 250));
		};

		const turnAround = ({isSudden = false} = {}) => {
			const current = lesson();
			if (isSudden) {
				addBubble(current.neverTurns ? teacherDesk.x + 35 : teacher.x, 80, current.neverTurns ? 'KVA SKJER HER?!' : 'Kva skjer her?!', 1.6);
				this.say(current.neverTurns ? 'The class is too loud! The substitute lowers the newspaper. Freeze!' : `${current.pronoun} turns around all at once, with no warning! Freeze!`);
			} else if (note) {
				this.say(`${current.pronoun} turns around! Freeze!`);
			}

			teacher.state = 'turning';
			teacher.timer = this.reducedMotion ? 0 : turnTime;
			if (this.reducedMotion) {
				teacher.face = 1;
			}
		};

		const updateTeacher = seconds => {
			const current = lesson();

			if (teacher.state === 'reading') {
				teacher.readTime += seconds;
				if (!teacher.hasLaughed && teacher.readTime >= teacher.readTarget) {
					teacher.hasLaughed = true;
					finishReading();
				}

				if (teacher.hasLaughed && clock > game.laughUntil) {
					teacher.hasLaughed = false;
					hush();
					bubble.dataset.state = '';
					bubble.textContent = '';
					this.say(`${current.teacher} puts your note in the desk drawer. Write a new one, if you dare.`);
					teacher.state = 'back';
					teacher.timer = this.reducedMotion ? 0 : turnTime;
				}

				return;
			}

			teacher.timer -= seconds;

			// Things that are too loud make even the substitute look up.
			if (game.suspicion >= 100 && (teacher.state === 'writing' || teacher.state === 'tell')) {
				turnAround({isSudden: true});
				return;
			}

			switch (teacher.state) {
				case 'writing': {
					// A full board is wiped with the sponge, and she starts on a new one.
					if (teacher.wipe > 0) {
						teacher.wipe -= seconds;
						if (teacher.wipe <= 0) {
							teacher.wipe = 0;
							teacher.board = current.board();
							teacher.written = 0;
						}
					} else if (!current.neverTurns) {
						const before = Math.floor(teacher.written);
						teacher.written = Math.min(boardLength(), teacher.written + (seconds * current.chalkSpeed));
						if (Math.floor(teacher.written) > before) {
							sound.chalk();
						}

						if (teacher.written >= boardLength()) {
							if (this.reducedMotion) {
								teacher.board = current.board();
								teacher.written = 0;
							} else {
								teacher.wipe = wipeTime;
							}
						}
					}

					if (teacher.timer <= 0) {
						if (current.neverTurns) {
							startWriting();
							break;
						}

						teacher.state = 'tell';
						teacher.timer = current.tell;
						teacher.isFake = Math.random() < current.fake;
						teacher.hasCleared = false;
					}

					break;
				}

				case 'tell': {
					// The chalk stops, and halfway through, she clears her throat.
					if (!teacher.hasCleared && teacher.timer <= current.tell / 2) {
						teacher.hasCleared = true;
						addBubble(teacher.x, 80, current.isWoman ? 'Hm-hm!' : 'HRRM!', 1);
						sound.throat();
					}

					if (teacher.timer <= 0) {
						if (teacher.isFake) {
							this.say(`${current.teacher} clears his throat… and keeps writing. A trick!`);
							startWriting();
						} else {
							turnAround();
						}
					}

					break;
				}

				case 'turning': {
					teacher.face = this.reducedMotion ? 1 : clamp(1 - (teacher.timer / turnTime), 0, 1);
					if (teacher.timer <= 0) {
						teacher.face = 1;
						teacher.state = 'looking';
						const [minimum, maximum] = current.look;
						teacher.timer = randomBetween(minimum, maximum);
					}

					break;
				}

				case 'looking': {
					if (teacher.timer <= 0) {
						teacher.state = 'back';
						teacher.timer = this.reducedMotion ? 0 : turnTime;
					}

					break;
				}

				case 'back': {
					teacher.face = this.reducedMotion ? 0 : clamp(teacher.timer / turnTime, 0, 1);
					if (teacher.timer <= 0) {
						teacher.face = 0;
						startWriting();
						if (game.state === 'playing' && note) {
							this.say(`${current.pronoun} writes on the board again. Go!`);
						}
					}

					break;
				}

				default: {
					break;
				}
			}

			// She walks along the board to where the chalk is.
			if (!current.neverTurns && teacher.state === 'writing') {
				const goal = teacher.wipe > 0 ? lerp(370, 40, teacher.wipe / wipeTime) : clamp(chalkPoint().x - 10, 40, 370);
				// With reduced motion, she stays in the middle of the board.
				teacher.x = this.reducedMotion ? 200 : lerp(teacher.x, goal, clamp(seconds * 4, 0, 1));
			}
		};

		// Whether she can see the note now: a note that moves, or Kevin who reads it, is caught.
		const isWatching = () => teacher.state === 'looking' || (teacher.state === 'turning' && teacher.face > 0.8);

		const checkCaught = () => {
			if (!note || !isWatching()) {
				return;
			}

			if (flight) {
				catchNote(`${lesson().pronoun} saw it ${flight.isThrown ? 'fly' : 'move'}!`);
			} else if (busy?.kind === 'reading') {
				catchNote('“Kevin! Kva er det du les?” (What are you reading?)');
			}
		};

		const updateBusy = seconds => {
			if (!busy) {
				return;
			}

			busy.time -= seconds;
			if (busy.time > 0) {
				if (busy.kind === 'reading') {
					game.suspicion = clamp(game.suspicion + (seconds * 6 * lesson().risk), 0, 100);
				}

				return;
			}

			const kid = kids[busy.kid];
			const kind = busy.kind;
			busy = undefined;
			switch (kind) {
				case 'snitch': {
					if (lesson().neverTurns) {
						game.suspicion = clamp(game.suspicion + 40, 0, 100);
						addBubble(teacherDesk.x + 35, 80, 'Mm, fint.', 1.4);
						this.say(`The substitute says “Mm, fint” without looking up from the newspaper. ${kid.name} is furious. The note is still on her desk.`);
					} else {
						teacher.face = 1;
						teacher.state = 'looking';
						teacher.timer = 2;
						catchNote(`${kid.name} told on you.`);
					}

					break;
				}

				case 'reading': {
					note.kevin = true;
					this.say('Kevin wrote “KEVIN VAR HER!!” (Kevin was here) on it. He is done. Pass it on!');
					break;
				}

				case 'fumbling': {
					this.say('Kevin gives it back, still folded. Pass it on!');
					break;
				}

				case 'sleeping': {
					busy = {kid: kid.index, kind: 'waking', time: 0.6};
					addBubble(kid.x, kid.y - 8, 'HÆ?! Eg sov ikkje!', 1.6);
					game.suspicion = clamp(game.suspicion + (15 * lesson().risk), 0, 100);
					sound.snort();
					this.say(`${kid.name} wakes up with a snort: “Hæ?! Eg sov ikkje!” (Huh? I was not asleep!)`);
					break;
				}

				case 'waking': {
					this.say(`${kid.name} is awake. Pass it on!`);
					break;
				}

				case 'aiming': {
					stianThrows();
					break;
				}

				case 'replying': {
					answerComes(kid);
					break;
				}

				default: {
					break;
				}
			}
		};

		const updateFlight = seconds => {
			if (!flight) {
				return;
			}

			flight.time += seconds;
			if (flight.time < flight.duration) {
				return;
			}

			if (flight.landsOnDesk) {
				flight = undefined;
				teacher.face = 1;
				teacher.state = 'looking';
				teacher.timer = 2;
				catchNote(`It landed ${lesson().neverTurns ? 'right on the newspaper of the substitute' : 'at the front of the class'}.`);
				return;
			}

			arrive(kids[flight.toKid]);
		};

		// The bell ends the lesson. A note that is still on its way is saved by the bell.
		const ringBell = () => {
			game.state = 'over';
			sound.bell();
			hush();

			bubble.dataset.state = '';
			bubble.textContent = '';
			teacher.state = 'writing';
			teacher.face = 0;
			teacher.hasLaughed = false;
			let message = 'RIIIIING! The bell! Friminutt (break time)!';
			if (note && (holder !== sindre.index || flight)) {
				keep({...note}, 'bell');
				message += ' Saved by the bell: you get the note back in the break.';
			}

			reply = undefined;

			note = undefined;
			holder = undefined;
			flight = undefined;
			busy = undefined;
			if (paperView === 'folding' || paperView === 'folded') {
				paperView = 'draft';
				drawPaper();
			}

			startButton.disabled = false;
			startButton.textContent = '🔔 Start the Next Lesson';
			this.say(`${message} This lesson: ${plural(game.answered, 'note')} answered, and ${plural(game.caught, 'note')} read out loud.`);
			requestDraw();
		};

		const startLesson = () => {
			const current = lesson();
			game.state = 'playing';
			game.time = 0;
			game.answered = 0;
			game.caught = 0;
			game.suspicion = 0;
			game.blush = 0;
			game.laughUntil = 0;
			bubbles = [];
			busy = undefined;
			flight = undefined;
			teacher.board = current.board();
			teacher.written = current.neverTurns ? boardLength() : 0;
			teacher.wipe = 0;
			teacher.face = 0;
			teacher.hasLaughed = false;
			startWriting();
			startButton.disabled = true;
			startButton.textContent = 'The lesson is on…';
			const intros = {
				norsk: 'Norwegian class with Fru Hansen. She writes nynorsk on the board. Pass the note while her back is turned!',
				matte: 'Math with Fru Hansen. Long division! She turns around a bit more often.',
				vikar: 'A substitute! He reads Bergens Tidende and never turns around. Only the snitches and a lot of noise can get you.',
				rektor: 'The principal, Rektor Berg, takes the class today. He turns around often, and he fakes his tells!',
			};
			const hint = note?.fold === 'airplane' ? 'Click any desk to throw the airplane there.' : (note ? 'Click a desk next to yours to pass the note.' : 'Write a note above and fold it.');
			this.say(`${intros[lessonId]} ${hint}`);
			loop.start();
			room.focus({preventScroll: true});
			if (note) {
				showClassroom();
			}
		};

		this.on(startButton, 'click', () => {
			if (game.state !== 'playing') {
				startLesson();
			}
		});

		for (const button of lessonButtons) {
			this.on(button, 'click', () => {
				if (game.state === 'playing') {
					this.say('You can’t leave in the middle of the lesson! Wait for the bell.');
					return;
				}

				lessonId = button.dataset.classNotesLesson;
				for (const other of lessonButtons) {
					const isOn = other === button;
					other.setAttribute('aria-pressed', String(isOn));
					other.dataset.state = isOn ? 'on' : '';
				}

				teacher.board = lesson().board();
				teacher.written = lesson().neverTurns ? boardLength() : Math.min(boardLength(), 12);
				teacher.wipe = 0;
				this.say(`Next lesson: ${lesson().name} lesson with ${lesson().teacher}. Press Start when you are ready.`);
				requestDraw();
			});
		}

		// The loop of the classroom: the lesson clock, the teacher, the note, and the bubbles.
		const advanceFold = seconds => {
			if (paperView !== 'folding') {
				return;
			}

			foldProgress = Math.min(1, foldProgress + (seconds / 1.4));
			if (foldProgress >= 1) {
				paperView = 'folded';
				if (game.state === 'playing') {
					showClassroom();
				}
			}

			drawPaper();
		};

		const step = seconds => {
			clock += seconds;
			advanceFold(seconds);

			if (game.state === 'playing') {
				game.time += seconds;
				updateTeacher(seconds);
				updateFlight(seconds);
				checkCaught();
				updateBusy(seconds);
				checkCaught();
				if (teacher.state === 'writing') {
					game.suspicion = clamp(game.suspicion - (seconds * 2.5), 0, 100);
				}

				if (teacher.state !== 'reading' && !isLaughing()) {
					game.blush = this.reducedMotion ? 0 : Math.max(0, game.blush - (seconds * 0.15));
				}

				if (game.time >= lessonSeconds && teacher.state !== 'reading') {
					ringBell();
				}
			}

			if (reply) {
				reply.time += seconds;
				if (reply.time >= reply.duration) {
					reply = undefined;
				}
			}

			for (const item of bubbles) {
				item.time -= seconds;
			}

			bubbles = bubbles.filter(item => item.time > 0);

			drawRoom();
			updateStats();
		};

		// It runs only while the classroom is on the screen and the tab is visible, so the lesson pauses while the classroom is away.
		const loop = this.loop(step, {while: () => game.state === 'playing' || paperView === 'folding' || bubbles.length > 0});

		// The paper also folds while the classroom is off the screen, like on a phone, where the classroom is further down.
		const foldLoop = this.loop(seconds => {
			if (!loop.isRunning) {
				advanceFold(seconds);
			}
		}, {while: () => paperView === 'folding', target: paper});

		const kidAt = point => kids.find(kid => Math.abs(kid.x - point.x) < 46 && point.y > kid.y - 34 && point.y < kid.y + 32);

		this.on(room, 'click', event => {
			const kid = kidAt(canvasPoint(room, event));
			if (kid) {
				pass(kid);
			} else if (game.state === 'ready') {
				this.say(note ? 'Press Start the Lesson, then click a desk next to yours to pass the note.' : 'First write a note and fold it, then start the lesson.');
			}

			requestDraw();
		});

		this.on(room, 'pointermove', event => {
			const kid = kidAt(canvasPoint(room, event));
			const index = kid?.index;
			if (index !== hovered) {
				hovered = index;
				requestDraw();
			}
		});

		this.on(room, 'pointerleave', () => {
			hovered = undefined;
			requestDraw();
		});

		// The arrow keys pass the note that way. Enter starts the lesson, or throws the airplane to the one it is for.
		this.on(room, 'keydown', event => {
			if (event.altKey || event.ctrlKey || event.metaKey) {
				return;
			}

			const directions = {ArrowLeft: [-1, 0], ArrowRight: [1, 0], ArrowUp: [0, -1], ArrowDown: [0, 1]};
			const direction = directions[event.key];
			if (direction) {
				event.preventDefault();
				if (holder === undefined) {
					pass(sindre);
					return;
				}

				const from = kids[holder];
				const kid = kids.find(other => other.column === from.column + direction[0] && other.row === from.row + direction[1]);
				if (kid) {
					pass(kid);
				} else {
					this.say('There is only the wall that way.');
				}

				requestDraw();
				return;
			}

			if (event.key === 'Enter' || event.key === ' ') {
				event.preventDefault();
				if (game.state !== 'playing') {
					startLesson();
				} else if (note?.fold === 'airplane') {
					pass(target());
				} else if (note) {
					this.say('Use the arrow keys to pass the note to the next desk.');
				}
			}
		});

		this.#redraw = () => {
			requestDraw();
			drawPaper();
		};

		teacher.board = lesson().board();
		teacher.written = 12;
		readDraft();
		drawPaper();
		showPencilCase();
		drawRoom();
		updateStats();

		// The fonts of the handwriting can load after the first drawing.
		document.fonts?.ready.then(() => {
			drawPaper();
			requestDraw();
		});

	}

	// The game runs only while the classroom is on the screen, and not while only the paper is.
	get visibilityTarget() {
		return this.parts.room;
	}

	reducedMotionChanged() {
		this.#redraw();
	}
}
