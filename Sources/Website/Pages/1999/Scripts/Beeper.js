// My Beeper on the 1999 page: a numeric pager in see-through purple plastic, on the kitchen table, and the red Telenor phone booth on the corner, where the visitor pages me and my friends. The beeper has its own clock, which runs fast through a day in November 1999 while the toy is on the screen, and the pages come at the times of that day. Each canvas runs only while it is on the screen, and the clock only while the toy is, and only while the tab is visible. Nothing makes a sound until the visitor turns on the sound. The beeper, the pocket, and the code book are kept in the browser.

const randomItem = items => items[Math.floor(Math.random() * items.length)];
const randomBetween = (minimum, maximum) => minimum + (Math.random() * (maximum - minimum));
const clamp = (value, minimum, maximum) => Math.min(Math.max(value, minimum), maximum);

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

// A tiny pixel font of 3 × 5 for the small letters of the LCD and the signs of the street, so the text is crisp at any size. Each letter is five rows of three bits.
const pixelFont = {
	A: [2, 5, 7, 5, 5], B: [6, 5, 6, 5, 6], C: [3, 4, 4, 4, 3], D: [6, 5, 5, 5, 6], E: [7, 4, 6, 4, 7], F: [7, 4, 6, 4, 4], G: [3, 4, 5, 5, 3], H: [5, 5, 7, 5, 5], I: [7, 2, 2, 2, 7], J: [1, 1, 1, 5, 2], K: [5, 5, 6, 5, 5], L: [4, 4, 4, 4, 7], M: [5, 7, 7, 5, 5], N: [6, 5, 5, 5, 5], O: [2, 5, 5, 5, 2], P: [6, 5, 6, 4, 4], Q: [2, 5, 5, 6, 3], R: [6, 5, 6, 5, 5], S: [3, 4, 2, 1, 6], T: [7, 2, 2, 2, 2], U: [5, 5, 5, 5, 7], V: [5, 5, 5, 5, 2], W: [5, 5, 7, 7, 5], X: [5, 5, 2, 5, 5], Y: [5, 5, 2, 2, 2], Z: [7, 1, 2, 4, 7],
	0: [7, 5, 5, 5, 7], 1: [2, 6, 2, 2, 7], 2: [6, 1, 2, 4, 7], 3: [6, 1, 2, 1, 6], 4: [5, 5, 7, 1, 1], 5: [7, 4, 6, 1, 6], 6: [3, 4, 7, 5, 7], 7: [7, 1, 2, 2, 2], 8: [7, 5, 7, 5, 7], 9: [7, 5, 7, 1, 6],
	' ': [0, 0, 0, 0, 0], '.': [0, 0, 0, 0, 2], ',': [0, 0, 0, 2, 4], '!': [2, 2, 2, 0, 2], '?': [6, 1, 2, 0, 2], ':': [0, 2, 0, 2, 0], '-': [0, 0, 7, 0, 0], '+': [0, 2, 7, 2, 0], '/': [1, 1, 2, 4, 4], '\'': [2, 2, 0, 0, 0], '(': [1, 2, 2, 2, 1], ')': [4, 2, 2, 2, 4], '×': [0, 5, 2, 5, 0], '*': [0, 5, 2, 5, 0], '#': [5, 7, 5, 7, 5], '_': [0, 0, 0, 0, 7], '…': [0, 0, 0, 0, 5],
	Æ: [3, 6, 7, 6, 7], Ø: [3, 5, 7, 5, 6], Å: [2, 0, 2, 5, 7],
};

const pixelTextWidth = (text, scale = 1) => (([...String(text)].length * 4) - 1) * scale;

// Draws text in the pixel font at a whole pixel. The alignment is `left`, `center`, or `right`.
const drawPixelText = (context, text, x, y, color, {scale = 1, align = 'left'} = {}) => {
	const characters = [...String(text).toUpperCase()];
	const width = pixelTextWidth(text, scale);
	const left = Math.round(align === 'center' ? x - (width / 2) : (align === 'right' ? x - width : x));
	context.fillStyle = color;
	let characterLeft = left;
	for (const character of characters) {
		const rows = pixelFont[character] ?? pixelFont['?'];
		for (const [row, bits] of rows.entries()) {
			for (let column = 0; column < 3; column++) {
				if (bits & (4 >> column)) {
					context.fillRect(characterLeft + (column * scale), Math.round(y) + (row * scale), scale, scale);
				}
			}
		}

		characterLeft += 4 * scale;
	}
};

// Small icons of the LCD, as rows of bits, like the pixel font.
const icons = {
	bell: {width: 5, rows: [4, 14, 14, 31, 4]},
	vibrate: {width: 5, rows: [17, 21, 21, 21, 17]},
	silent: {width: 5, rows: [5, 14, 22, 31, 20]},
	envelope: {width: 7, rows: [127, 99, 85, 73, 127]},
};

const drawIcon = (context, icon, x, y, color, scale = 1) => {
	context.fillStyle = color;
	for (const [row, bits] of icon.rows.entries()) {
		for (let column = 0; column < icon.width; column++) {
			if (bits & (1 << (icon.width - 1 - column))) {
				context.fillRect(x + (column * scale), y + (row * scale), scale, scale);
			}
		}
	}
};

// The segments of the big digits of the LCD, which turned upside down make letters, like hELLO.
const segmentsOf = {
	0: 'abcdef', 1: 'bc', 2: 'abged', 3: 'abgcd', 4: 'fgbc', 5: 'afgcd', 6: 'afgedc', 7: 'abc', 8: 'abcdefg', 9: 'abcdfg', '-': 'g', '*': 'g', '#': 'bcefg', ' ': '',
};

const drawDigit = (context, character, x, y, {width = 12, height = 24, thickness = 3, on, off}) => {
	const half = height / 2;
	const rectangles = {
		a: [thickness, 0, width - (2 * thickness), thickness],
		b: [width - thickness, thickness, thickness, half - thickness],
		c: [width - thickness, half, thickness, half - thickness],
		d: [thickness, height - thickness, width - (2 * thickness), thickness],
		e: [0, half, thickness, half - thickness],
		f: [0, thickness, thickness, half - thickness],
		g: [thickness, half - (thickness / 2), width - (2 * thickness), thickness],
	};
	const lit = segmentsOf[character] ?? '';
	for (const [name, [left, top, segmentWidth, segmentHeight]] of Object.entries(rectangles)) {
		context.fillStyle = lit.includes(name) ? on : off;
		context.fillRect(x + left, y + top, segmentWidth, segmentHeight);
	}
};

// MARK: The data

const myNumber = '96010143';

// The pager codes of my class, of my family, and why they mean what they mean. The visitor learns them in “Decode It!”.
const codes = [
	{code: '143', meaning: 'I love you', why: 'I = 1 letter, love = 4, you = 3', wrong: ['143 kroner, please', 'Meet me at bus 143']},
	{code: '07734', meaning: 'Hello', why: 'turn the beeper upside down: hELLO', wrong: ['Hell no', 'My locker code']},
	{code: '911', meaning: 'Call me now!', why: 'the emergency number on American TV', wrong: ['Meet at 9:11', 'I want a Porsche 911']},
	{code: '121', meaning: 'I need to talk to you', why: 'one to one', wrong: ['One, two, one: a dance step', 'Bus 121 is late']},
	{code: '88', meaning: 'Bye-bye', why: 'it sounds like “bye-bye” in Chinese, Trond says', wrong: ['Two snowmen', 'I got 88 points in Tetris']},
	{code: '404', meaning: 'I don’t get it', why: 'like “404 Not Found” on the Internet', wrong: ['Room 404', 'At 4:04']},
	{code: '411', meaning: 'What’s up?', why: '411 is the information number in America', wrong: ['Four elevens', 'It is 4:11']},
	{code: '104', meaning: 'OK!', why: '10-4, like the truck drivers on the CB radio', wrong: ['10 for 4 kroner', 'Room 104']},
	{code: '182', meaning: 'I hate you', why: 'Trond sends it every time I win at Tekken 3', wrong: ['I am 1.82 meters tall', 'Blink-182 is on MTV']},
	{code: '20', meaning: 'Where are you?', why: '2 0: to where? We just decided it', wrong: ['20 kroner', 'In 20 minutes']},
	{code: '831', meaning: 'I love you', why: '8 letters, 3 words, 1 meaning', wrong: ['At 8:31 in the morning', 'Bus 831']},
	{code: '1432', meaning: 'I love you too', why: '143, and 2 for “too”', wrong: ['14 + 32 = 46', 'The year of Columbus, almost']},
	{code: '0000', meaning: 'Come home for dinner!', why: 'Mamma’s only code', wrong: ['Zero points', 'The battery is empty']},
	{code: '55281403', meaning: 'Call Mormor', why: 'it is her phone number. She does not get codes, so she sends her number', wrong: ['A secret code of the CIA', 'The price of a game console']},
	{code: '55312000', meaning: 'Call Pappa at work', why: 'the number of Pappa’s office', wrong: ['The Y2K bug is coming', 'The number of the pizza place']},
	{code: 'lillesoster', label: 'Lots of random numbers', meaning: 'Lillesøster found Mamma’s phone', why: 'she presses every button and laughs', wrong: ['A very long secret', 'Trond’s math homework']},
];

// The ID that friends put at the end of a page, after a star, so I know who sent it.
const senderIds = {
	trond: '07',
	kristine: '22',
	stranger: '99',
};

const senderNames = {
	trond: 'Trond',
	kristine: 'Kristine',
	mamma: 'Mamma',
	mormor: 'Mormor',
	pappa: 'Pappa',
	lillesoster: 'Lillesøster',
	visitor: 'you',
	stranger: 'a stranger',
};

const dayNames = ['MA', 'TI', 'ON', 'TO', 'FR', 'LØ', 'SØ'];

// The pictures of the telekort, which kids collected.
const cardPictures = [
	{name: 'Håkon and Kristin of Lillehammer ’94', colors: ['#d8342c', '#f2c94c']},
	{name: 'the Geirangerfjord', colors: ['#5aa0e0', '#2f6a3a']},
	{name: 'Hurtigruten in the snow', colors: ['#1d3b6e', '#f4f4f4']},
	{name: 'a troll with a big nose', colors: ['#6b8e23', '#8b5a2b']},
	{name: 'Bryggen in Bergen', colors: ['#c0392b', '#e8c170']},
	{name: 'the northern lights', colors: ['#0b1d3a', '#39ff9c']},
];

// The things that the coin return sometimes has: the coins of someone who forgot them, and worse.
const foundThings = [
	{weight: 5, item: {kind: 'coin', value: 1}, text: 'Someone forgot a 1 krone in the coin return!'},
	{weight: 3, item: {kind: 'coin', value: 5}, text: 'A 5 kroner coin! Someone did not wait for the change.'},
	{weight: 1, item: {kind: 'coin', value: 10}, text: 'A 10 kroner coin! JACKPOT!'},
	{weight: 2, item: {kind: 'thing', name: 'a Danish krone'}, text: 'A Danish krone, from someone on the ferry. It has a hole like ours, but the phone does not take it.'},
	{weight: 1, item: {kind: 'thing', name: 'a Swedish krona'}, text: 'A Swedish krona. Useless, but shiny.'},
	{weight: 1, item: {kind: 'thing', name: 'a button from a jacket'}, text: 'A button from a jacket. Someone tried to call for free.'},
	{weight: 1, item: {kind: 'thing', name: 'a Hubba Bubba wrapper'}, text: 'A Hubba Bubba wrapper. Yuck. At least it is not the gum.'},
];

// The lines of the people who answer the phone, in Norwegian, with what they mean.
const mormorLines = [
	['Hallo? Hallo! Er det Sindre? Så hyggelig!', 'Hello? Is that Sindre? How nice!'],
	['Fikk du nummeret mitt på den personsøkeren?', 'Did you get my number on that beeper?'],
	['Hofta mi er bedre nå, men det regner jo hele tiden.', 'My hip is better now, but it rains all the time.'],
	['Jeg har bakt vafler. Med brunost!', 'I baked waffles. With brown cheese!'],
	['Og fru Olsen, naboen, hun har fått seg ny hund.', 'And Mrs. Olsen, the neighbor, got a new dog.'],
	['Den bjeffer hele natten, og så sa jeg til henne…', 'It barks all night, and then I said to her…'],
	['Er du kledd godt nok? Det er kaldt ute.', 'Are you dressed warmly enough? It is cold out.'],
	['Har jeg fortalt deg om da bestefar kjøpte bil i 1962?', 'Did I tell you about when Grandpa bought a car in 1962?'],
];

// MARK: The state

// The clock of the beeper counts minutes from Monday 8 November 1999 at midnight, and starts on Friday afternoon, after school.
const startClock = (4 * 1440) + (15 * 60) + 20;

const defaults = {
	clock: startClock,
	today: 4,
	nextId: 1,
	memory: [],
	known: ['07734', '143'],
	knownSenders: [],
	score: 0,
	streak: 0,
	bestStreak: 0,
	battery: 0.45,
	drawer: 1,
	hasRemoteBattery: true,
	mode: 'beep',
	coins: {1: 3, 5: 2, 10: 3},
	cardUnits: 12,
	cardPicture: 1,
	collection: 0,
	souvenirs: [],
	cup: [],
	allowanceCount: 0,
	foundToday: 0,
	mammaDay: -1,
	mormorDay: -1,
	kristineLoves: 0,
	knowsKristine: false,
	hasCrackedAll: false,
};

const modes = ['beep', 'vibrate', 'silent'];
const coinValues = [1, 5, 10];
const isObject = value => typeof value === 'object' && value !== null && !Array.isArray(value);

const clockParts = clock => {
	const dayIndex = Math.floor(clock / 1440);
	const minuteOfDay = clock % 1440;
	return {
		dayIndex,
		weekday: dayIndex % 7,
		hour: Math.floor(minuteOfDay / 60),
		minute: minuteOfDay % 60,
	};
};

const clockText = clock => {
	const {hour, minute} = clockParts(clock);
	return `${String(hour).padStart(2, '0')}:${String(minute).padStart(2, '0')}`;
};

const dayTimeText = clock => `${dayNames[clockParts(clock).weekday]} ${clockText(clock)}`;

const entryFor = page => codes.find(entry => entry.code === (page.sender === 'lillesoster' ? 'lillesoster' : page.code));

// MARK: Sound

const audio = {
	context: undefined,
	output: undefined,
	isOn: false,
	// Uses the audio of the element, which is `undefined` until the visitor clicks, as browsers only let audio play then.
	start(sound) {
		if (this.context || !sound) {
			return;
		}

		this.context = sound.context;
		this.output = this.context.createGain();
		this.output.gain.value = 0.6;
		this.output.connect(sound.output);
	},
	ensure() {
		if (this.context?.state === 'suspended') {
			this.context.resume();
		}

		return this.context;
	},
};

// The audio context, only while the visitor has the sound on.
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

// A short burst of noise, for the clicks of the card slot and the rattle of the coins.
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
	// The beep of the beeper: three short, shrill beeps, twice, from the little piezo speaker.
	beep() {
		for (const group of [0, 0.55]) {
			for (const index of [0, 1, 2]) {
				tone(2730, group + (index * 0.13), 0.08, {type: 'square', volume: 0.04});
			}
		}
	},
	chirp() {
		tone(3400, 0, 0.05, {type: 'square', volume: 0.035});
	},
	// The motor with the weight on it, rattling on the wood of the table.
	buzz() {
		for (const start of [0, 0.65]) {
			for (let index = 0; index < 22; index++) {
				tone(140 + (Math.random() * 30), start + (index * 0.02), 0.018, {type: 'sawtooth', volume: 0.07});
			}
		}
	},
	dtmf(key) {
		const pairs = {
			1: [697, 1209], 2: [697, 1336], 3: [697, 1477], 4: [770, 1209], 5: [770, 1336], 6: [770, 1477], 7: [852, 1209], 8: [852, 1336], 9: [852, 1477], '*': [941, 1209], 0: [941, 1336], '#': [941, 1477],
		};
		for (const frequency of pairs[key] ?? []) {
			tone(frequency, 0, 0.14, {volume: 0.06});
		}
	},
	coin() {
		tone(2600, 0, 0.06, {volume: 0.05});
		tone(4100, 0.01, 0.05, {volume: 0.03});
		tone(3300, 0.12, 0.05, {volume: 0.03});
		tone(180, 0.32, 0.1, {type: 'triangle', volume: 0.12});
	},
	clunk() {
		tone(120, 0, 0.12, {type: 'triangle', volume: 0.14});
		noise(0, 0.08, {volume: 0.12, frequency: 900});
	},
	card() {
		noise(0, 0.05, {volume: 0.15, frequency: 2500});
		noise(0.12, 0.04, {volume: 0.12, frequency: 1800});
	},
	notInUse() {
		for (const [index, frequency] of [950, 1400, 1800].entries()) {
			tone(frequency, index * 0.34, 0.33, {volume: 0.06});
		}
	},
	serviceTone() {
		tone(1000, 0, 0.6, {volume: 0.07});
	},
	sent() {
		for (const [index, frequency] of [600, 900, 1200].entries()) {
			tone(frequency, index * 0.15, 0.12, {volume: 0.06});
		}
	},
	warning() {
		tone(1400, 0, 0.12, {volume: 0.06});
		tone(1400, 0.25, 0.12, {volume: 0.06});
	},
	// The bell of the phone in the booth, a fast electric trill.
	ring() {
		for (let index = 0; index < 18; index++) {
			tone(index % 2 === 0 ? 1100 : 880, index * 0.05, 0.045, {type: 'square', volume: 0.03});
		}
	},
};

// The tones of the line: the Norwegian 425 Hz, steady for the dial tone, and in beats for ringing and busy.
let lineTone;

const stopLine = () => {
	lineTone?.stop();
	lineTone = undefined;
};

const playLine = kind => {
	stopLine();
	const context = soundContext();
	if (!context) {
		return;
	}

	const [on, off] = {dial: [1, 0], ringback: [1, 4], busy: [0.5, 0.5], waiting: [0.2, 2.8]}[kind];
	const oscillator = context.createOscillator();
	const gain = context.createGain();
	oscillator.frequency.value = 425;
	gain.gain.value = 0;
	oscillator.connect(gain).connect(audio.output);
	oscillator.start();
	const volume = 0.06;
	let interval;
	if (off === 0) {
		gain.gain.setValueAtTime(volume, context.currentTime);
	} else {
		const schedule = () => {
			const now = context.currentTime;
			gain.gain.setValueAtTime(volume, now);
			gain.gain.setValueAtTime(0, now + on);
		};

		schedule();
		interval = setInterval(schedule, (on + off) * 1000);
	}

	lineTone = {
		stop() {
			clearInterval(interval);
			gain.gain.cancelScheduledValues(context.currentTime);
			gain.gain.setValueAtTime(0, context.currentTime);
			oscillator.stop(context.currentTime + 0.05);
		},
	};
};

let voices = [];
const loadVoices = () => {
	voices = speechSynthesis.getVoices();
};

if ('speechSynthesis' in globalThis) {
	loadVoices();
	speechSynthesis.addEventListener('voiceschanged', loadVoices);
}

const speak = text => {
	if (!audio.isOn || !('speechSynthesis' in globalThis)) {
		return;
	}

	const utterance = new SpeechSynthesisUtterance(text);
	utterance.lang = 'nb-NO';
	const voice = voices.find(candidate => ['nb', 'no', 'nn'].some(prefix => candidate.lang.toLowerCase().startsWith(prefix)));
	if (voice) {
		utterance.voice = voice;
	}

	speechSynthesis.speak(utterance);
};

const hush = () => {
	if ('speechSynthesis' in globalThis) {
		speechSynthesis.cancel();
	}
};

// MARK: Drawing the table and the beeper

const tableWidth = 296;
const tableHeight = 198;

// The grain of the pine table, made once.
const grain = Array.from({length: 26}, (_, index) => ({
	y: (index * 7.7) + randomBetween(-2, 2),
	wave: randomBetween(1, 4),
	phase: randomBetween(0, 6),
	shade: randomBetween(0.05, 0.16),
}));

const roundedRectangle = (context, x, y, width, height, radius) => {
	context.beginPath();
	context.roundRect(x, y, width, height, radius);
};

const drawWaffle = context => {
	// A plate with a heart waffle and a slice of brown cheese.
	context.fillStyle = '#f6f6f2';
	context.beginPath();
	context.arc(48, 46, 36, 0, Math.PI * 2);
	context.fill();
	context.strokeStyle = '#c9c9c0';
	context.lineWidth = 2;
	context.beginPath();
	context.arc(48, 46, 30, 0, Math.PI * 2);
	context.stroke();
	context.fillStyle = '#e2a646';
	context.beginPath();
	context.arc(48, 46, 25, 0.5, (Math.PI * 2) - 0.75);
	context.lineTo(48, 46);
	context.fill();
	context.strokeStyle = '#b97a22';
	context.lineWidth = 1;
	for (let index = 0; index < 5; index++) {
		const angle = 0.5 + (index * 1.03);
		context.beginPath();
		context.moveTo(48, 46);
		context.lineTo(48 + (Math.cos(angle) * 25), 46 + (Math.sin(angle) * 25));
		context.stroke();
	}

	context.fillStyle = '#b5651d';
	context.save();
	context.translate(54, 40);
	context.rotate(0.3);
	context.fillRect(-9, -5, 18, 9);
	context.fillStyle = '#d18a45';
	context.fillRect(-9, -5, 18, 2);
	context.restore();
};

const drawMilk = context => {
	context.fillStyle = 'rgba(0, 0, 0, 0.18)';
	context.beginPath();
	context.arc(42, 168, 19, 0, Math.PI * 2);
	context.fill();
	context.fillStyle = 'rgba(230, 240, 255, 0.85)';
	context.beginPath();
	context.arc(38, 164, 18, 0, Math.PI * 2);
	context.fill();
	context.fillStyle = '#ffffff';
	context.beginPath();
	context.arc(38, 164, 14, 0, Math.PI * 2);
	context.fill();
	context.fillStyle = 'rgba(255, 255, 255, 0.9)';
	context.fillRect(30, 156, 4, 4);
};

const lcdColors = isLit => ({
	background: isLit ? '#8dff7a' : '#8f9f72',
	on: isLit ? '#0c2a08' : '#1c2614',
	off: isLit ? 'rgba(12, 42, 8, 0.1)' : 'rgba(28, 38, 20, 0.08)',
});

const drawBigText = (context, text, colors) => {
	const characters = [...text].slice(0, 11);
	for (const [index, character] of characters.entries()) {
		drawDigit(context, character, -84 + (index * 15.4), -30, {on: colors.on, off: colors.off});
	}
};

const pagerButtonPlaces = [
	{name: 'read', label: 'READ', x: -66},
	{name: 'mode', label: 'MODE', x: -22},
	{name: 'light', label: 'LIGHT', x: 22},
	{name: 'clear', label: 'CLEAR', x: 66},
];

const drawBack = context => {
	// The belt clip, the sticker with my number, and the door of the battery.
	context.fillStyle = '#18121f';
	roundedRectangle(context, -54, -48, 108, 70, 10);
	context.fill();
	context.fillStyle = '#2c2238';
	for (let index = 0; index < 6; index++) {
		context.fillRect(-44, -36 + (index * 9), 88, 3);
	}

	context.fillStyle = '#0c0910';
	context.fillRect(-30, -52, 60, 8);
	context.fillStyle = '#f4f1e4';
	context.fillRect(-82, 28, 120, 24);
	drawPixelText(context, 'TELENOR PERSONSØKER', -78, 31, '#1a1a1a');
	drawPixelText(context, '960 10 143', -78, 39, '#1a1a1a', {scale: 2});
	context.strokeStyle = 'rgba(255, 255, 255, 0.6)';
	context.setLineDash([3, 2]);
	context.strokeRect(46, 26, 46, 26);
	context.setLineDash([]);
	drawPixelText(context, '1×AAA', 69, 36, '#ffffff', {align: 'center'});
};

// MARK: The phone booth

const formatNumber = number => {
	if (number.length === 8) {
		return number.startsWith('9') ? `${number.slice(0, 3)} ${number.slice(3, 5)} ${number.slice(5)}` : `${number.slice(0, 2)} ${number.slice(2, 4)} ${number.slice(4, 6)} ${number.slice(6)}`;
	}

	return number;
};

const services = {
	[myNumber]: {kind: 'pager', who: 'me'},
	96_020_777: {kind: 'pager', who: 'trond'},
	96_030_520: {kind: 'pager', who: 'kristine'},
	96_040_911: {kind: 'pager', who: 'pappa'},
	55_161_999: {kind: 'home'},
	55_281_403: {kind: 'mormor'},
	55_312_000: {kind: 'office'},
	180: {kind: 'opplysningen', cost: 6},
	'07000': {kind: 'taxi'},
	55_906_060: {kind: 'pizza'},
};

const isComplete = number => {
	if (number.startsWith('1')) {
		return number.length === 3;
	}

	if (number.startsWith('0')) {
		return number.length === 5;
	}

	return number.length === 8;
};

// MARK: Drawing the booth

const rain = Array.from({length: 70}, () => ({
	x: Math.random() * 320,
	y: Math.random() * 240,
	speed: randomBetween(3, 6),
	length: randomBetween(5, 10),
}));

const glassDrops = Array.from({length: 22}, () => ({
	x: randomBetween(76, 244),
	y: randomBetween(34, 222),
	speed: randomBetween(0.1, 0.5),
	size: randomBetween(1, 2.4),
}));

const boothRegions = {
	handset: {x: 112, y: 54, width: 30, height: 74},
	phone: {x: 142, y: 56, width: 60, height: 88},
	phoneBook: {x: 116, y: 154, width: 66, height: 60},
};

const drawStreet = context => {
	const sky = context.createLinearGradient(0, 0, 0, 240);
	sky.addColorStop(0, '#0d1530');
	sky.addColorStop(1, '#2a3550');
	context.fillStyle = sky;
	context.fillRect(0, 0, 320, 240);
	// Fløyen in the dark, with the lights of the houses.
	context.fillStyle = '#141a2c';
	context.beginPath();
	context.moveTo(0, 120);
	context.quadraticCurveTo(80, 40, 170, 90);
	context.quadraticCurveTo(250, 60, 320, 110);
	context.lineTo(320, 240);
	context.lineTo(0, 240);
	context.fill();
	context.fillStyle = '#ffd27a';
	for (const [x, y] of [[20, 112], [34, 100], [50, 96], [268, 96], [290, 104], [300, 112], [280, 120]]) {
		context.fillRect(x, y, 2, 2);
	}

	// Narvesen across the street.
	context.fillStyle = '#3a2a1a';
	context.fillRect(2, 140, 56, 70);
	context.fillStyle = '#ffe14d';
	context.fillRect(2, 140, 56, 12);
	drawPixelText(context, 'NARVESEN', 30, 144, '#c0001a', {align: 'center'});
	context.fillStyle = '#ffeeaa';
	context.fillRect(8, 160, 44, 26);
	context.fillStyle = '#c86';
	context.fillRect(12, 176, 8, 10);
	context.fillRect(24, 172, 8, 14);
	context.fillRect(36, 178, 10, 8);

	// The street lamp.
	context.fillStyle = '#222';
	context.fillRect(290, 60, 3, 160);
	context.fillStyle = '#ffdd88';
	context.fillRect(282, 56, 18, 6);
	const glow = context.createRadialGradient(291, 62, 2, 291, 62, 50);
	glow.addColorStop(0, 'rgba(255, 220, 140, 0.5)');
	glow.addColorStop(1, 'rgba(255, 220, 140, 0)');
	context.fillStyle = glow;
	context.fillRect(240, 10, 100, 110);

	// The wet street, with a puddle.
	context.fillStyle = '#1b2233';
	context.fillRect(0, 214, 320, 26);
	context.fillStyle = 'rgba(200, 30, 50, 0.35)';
	context.fillRect(70, 226, 180, 6);
	context.fillStyle = 'rgba(255, 220, 140, 0.25)';
	context.fillRect(270, 228, 40, 4);
};

const canvasPoint = (canvas, event, width, height) => {
	const bounds = canvas.getBoundingClientRect();
	return {
		x: (event.clientX - bounds.left) * (width / bounds.width),
		y: (event.clientY - bounds.top) * (height / bounds.height),
	};
};

const isInside = (point, region) => point.x >= region.x && point.x <= region.x + region.width && point.y >= region.y && point.y <= region.y + region.height;

export default class extends GeoCitiesElement {
	#state;
	#tableContext;
	#boothContext;
	#keyButtons;
	#coinButtons;
	#coinCounts;
	#choiceButtons;
	#tableLoop;
	#boothLoop;
	#tickInterval;
	#hasWelcomed = false;
	#lastTableDraw = 0;
	#lastBoothDraw = 0;
	#phoneBookPage = 0;
	#pressedButtons = new Map();
	#laterQueue = [];

	// Where the beeper lies on the table, and how it moves when it vibrates.
	#pose = {x: 150, y: 104, angle: -0.06};

	#pager = {
		isOnFloor: false,
		vibration: undefined,
		fall: undefined,
		// What the LCD shows: the time, a page, a short notice, or the test of all segments after a new battery.
		view: 'idle',
		viewPage: undefined,
		viewIndex: 0,
		viewSince: 0,
		notice: '',
		lightUntil: 0,
		// Until when a second press of Clear deletes, and what it deletes: a page, or `all`.
		confirmUntil: 0,
		clearTarget: undefined,
		isUpsideDown: false,
		isOver: false,
		lowBatteryWarned: false,
	};

	#phone = {
		isOffHook: false,
		isCardIn: false,
		// The coins in the phone that it has not eaten yet, and what is left of the coins that it ate.
		inserted: [],
		remainder: 0,
		stage: 'idle',
		dialed: '',
		message: '',
		target: undefined,
		talker: undefined,
		isConnected: false,
		seconds: 0,
		hasWarned: false,
		timeouts: [],
		lineIndex: 0,
		// Who calls the booth, and for how many seconds it has rung.
		caller: undefined,
		ringSeconds: 0,
		flash: '',
	};

	#decoder = {pageId: undefined, choices: [], isLocked: false};

	connected() {
		const {table, booth, read, mode, light, clear, pickUp, sound, flip, over, bed, drawer, remote, handset, card, coinReturn, take, narvesen, allowance, phoneBookToggle, phoneBook, phoneBookPrevious, phoneBookNext} = this.parts;
		this.#tableContext = table.getContext('2d');
		this.#boothContext = booth.getContext('2d');
		this.#keyButtons = [...this.querySelectorAll('[data-beeper-key]')];
		this.#coinButtons = [...this.querySelectorAll('[data-beeper-coin]')];
		this.#coinCounts = [...this.querySelectorAll('[data-beeper-coin-count]')];
		this.#choiceButtons = [...this.querySelectorAll('[data-beeper-choice]')];

		// The stored state can be old or broken, so each value is only used when it has the type of its default.
		const saved = this.stored('state', {});
		const state = {...defaults};
		for (const [key, fallback] of Object.entries(defaults)) {
			const value = saved[key];
			const isValid = Array.isArray(fallback) ? Array.isArray(value) : (typeof value === typeof fallback && (typeof value !== 'number' || Number.isFinite(value)));
			if (isValid && !isObject(fallback)) {
				state[key] = value;
			}
		}

		state.coins = Object.fromEntries(coinValues.map(value => {
			const count = isObject(saved.coins) ? saved.coins[value] : undefined;
			return [value, Number.isInteger(count) && count >= 0 ? count : defaults.coins[value]];
		}));

		if (!modes.includes(state.mode)) {
			state.mode = defaults.mode;
		}

		state.memory = state.memory.filter(page => isObject(page) && Number.isFinite(page.id) && Number.isFinite(page.time) && typeof page.code === 'string' && typeof page.text === 'string' && Object.hasOwn(senderNames, page.sender)).slice(0, 10);
		state.known = state.known.filter(code => typeof code === 'string');
		state.knownSenders = state.knownSenders.filter(sender => Object.hasOwn(senderIds, sender));
		state.souvenirs = state.souvenirs.filter(name => typeof name === 'string');
		state.cup = state.cup.filter(item => isObject(item) && (item.kind === 'coin' ? coinValues.includes(item.value) : item.kind === 'thing' && typeof item.name === 'string'));
		state.nextId = Math.max(state.nextId, ...state.memory.map(page => page.id + 1));
		this.#state = state;
		this.#pager.lowBatteryWarned = state.battery < 0.2;

		this.#tableLoop = this.loop((seconds, time) => {
			this.#stepTable(time);
		}, {
			while: () => !this.reducedMotion || Boolean(this.#pager.vibration || this.#pager.fall) || performance.now() < this.#pager.lightUntil || this.#pager.view === 'boot',
			target: table,
		});

		this.#boothLoop = this.loop((seconds, time) => {
			this.#stepBooth(time);
		}, {
			while: () => !this.reducedMotion,
			target: booth,
		});

		// MARK: The controls

		this.on(read, 'click', () => {
			this.#pressRead();
		});

		this.on(mode, 'click', () => {
			this.#pressMode();
		});

		this.on(light, 'click', () => {
			this.#pressLight();
		});

		this.on(clear, 'click', () => {
			this.#pressClear();
		});

		this.on(pickUp, 'click', () => {
			this.#pickUp();
		});

		this.on(sound, 'click', () => {
			audio.isOn = !audio.isOn;
			setPressed(sound, audio.isOn);
			if (audio.isOn) {
				audio.start(this.sound());
				sounds.chirp();
				if (this.#phone.stage === 'dialing' && !this.#phone.dialed) {
					playLine('dial');
				}

				this.say('The sound is on. Beep!');
			} else {
				stopLine();
				hush();
				this.say('The sound is off.');
			}
		});

		this.on(flip, 'click', () => {
			const pager = this.#pager;
			pager.isUpsideDown = !pager.isUpsideDown;
			setPressed(flip, pager.isUpsideDown);
			const page = pager.viewPage;
			const isHello = page?.code === '07734' && (pager.view === 'message' || pager.view === 'alert');
			this.say(pager.isUpsideDown ? (isHello ? 'Upside down, 07734 says hELLO!' : 'Upside down. Like a calculator, the numbers turn into letters: 07734 says hELLO, and 0.7734 is how Trond says hi.') : 'Right side up again.');
			this.#drawTable();
		});

		this.on(over, 'click', () => {
			this.#pager.isOver = !this.#pager.isOver;
			setPressed(over, this.#pager.isOver);
			this.say(this.#pager.isOver ? 'The back: the belt clip for my jeans, the sticker with my number from Telenor, and the door of the one AAA battery. And you can see the inside, because it is see-through!' : 'Face up again.');
			this.#drawTable();
		});

		this.on(bed, 'click', () => {
			const {dayIndex, hour} = clockParts(state.clock);
			if (this.#isNight()) {
				state.clock = ((hour >= 22 ? dayIndex + 1 : dayIndex) * 1440) + (7 * 60) + 30;
				this.say(`Good morning! ${clockText(state.clock)}, ${['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][clockParts(state.clock).weekday]}. It is raining. Of course.`);
			} else {
				// Sleep until just before 3 in the morning, when weak batteries chirp.
				state.clock = ((dayIndex + 1) * 1440) + (2 * 60) + 58;
				this.#drainBattery(0.02);
				this.say(state.battery < 0.6 ? 'Good night! The beeper is on the night table. Zzz… Zzz…' : 'Good night! The beeper has a fresh battery, so maybe it lets me sleep. Zzz…');
			}

			this.#newDay(clockParts(state.clock).dayIndex);
			this.#persist();
			this.#renderBed();
			this.#drawTable();
		});

		this.on(drawer, 'click', () => {
			if (state.drawer === 0) {
				this.say('Pappa’s drawer has rubber bands, a screwdriver, and old keys. No batteries. He buys more tomorrow.');
				return;
			}

			state.drawer--;
			const extra = this.#newBattery();
			this.say(`A new AAA from Pappa’s drawer. The beeper tests all its segments and beeps.${extra}`);
		});

		this.on(remote, 'click', () => {
			if (!state.hasRemoteBattery) {
				this.say('The TV remote has no battery. It is in my beeper already.');
				return;
			}

			state.hasRemoteBattery = false;
			const extra = this.#newBattery();
			this.say(`I took the AAA from the TV remote.${extra} From the living room, Pappa: “Hvem har tatt batteriet fra fjernkontrollen?!” (Who took the battery from the TV remote?!)`);
			speak('Hvem har tatt batteriet fra fjernkontrollen?!');
		});

		this.on(handset, 'click', () => {
			this.#toggleHandset();
		});

		this.on(card, 'click', () => {
			this.#toggleCard();
		});

		this.on(coinReturn, 'click', () => {
			this.#pressCoinReturn();
		});

		this.on(take, 'click', () => {
			this.#takeCoins();
		});

		this.on(narvesen, 'click', () => {
			this.#buyCard();
		});

		this.on(allowance, 'click', () => {
			this.#askAllowance();
		});

		this.on(phoneBookToggle, 'click', () => {
			this.#togglePhoneBook();
		});

		// Escape closes the phone book, from inside it, from its button, or from the booth.
		for (const element of [phoneBook, phoneBookToggle, booth]) {
			this.on(element, 'keydown', event => {
				if (event.key !== 'Escape' || phoneBook.hidden) {
					return;
				}

				event.preventDefault();
				const hadFocus = phoneBook.contains(document.activeElement);
				this.#togglePhoneBook();
				if (hadFocus) {
					phoneBookToggle.focus();
				}
			});
		}

		this.on(phoneBookPrevious, 'click', () => {
			this.#phoneBookPage = Math.max(0, this.#phoneBookPage - 1);
			this.#renderPhoneBook();
		});

		this.on(phoneBookNext, 'click', () => {
			this.#phoneBookPage = Math.min(this.#phoneBookPages().length - 1, this.#phoneBookPage + 1);
			this.#renderPhoneBook();
		});

		for (const button of this.#keyButtons) {
			this.on(button, 'click', () => {
				this.#pressKey(button.dataset.beeperKey);
			});
		}

		for (const button of this.#coinButtons) {
			this.on(button, 'click', () => {
				this.#insertCoin(Number(button.dataset.beeperCoin));
			});
		}

		for (const [index, button] of this.#choiceButtons.entries()) {
			this.on(button, 'click', () => {
				this.#choose(index);
			});
		}

		// The canvas of the table: the keys, and a click on a button of the drawing.
		this.on(table, 'keydown', event => {
			const actions = {r: () => this.#pressRead(), m: () => this.#pressMode(), l: () => this.#pressLight(), c: () => this.#pressClear(), u: () => flip.click()};
			const action = actions[event.key.toLowerCase()];
			if (action && !event.metaKey && !event.ctrlKey && !event.altKey) {
				event.preventDefault();
				action();
			}
		});

		this.on(table, 'click', event => {
			const pager = this.#pager;
			const pose = this.#pose;
			if (pager.isOnFloor) {
				this.#pickUp();
				return;
			}

			const point = canvasPoint(table, event, 320, 220);
			const angle = -(pose.angle + (pager.isUpsideDown ? Math.PI : 0));
			const dx = point.x - pose.x;
			const dy = point.y - pose.y;
			const local = {x: (dx * Math.cos(angle)) - (dy * Math.sin(angle)), y: (dx * Math.sin(angle)) + (dy * Math.cos(angle))};
			if (Math.abs(local.x) > 104 || Math.abs(local.y) > 58) {
				return;
			}

			if (pager.isOver) {
				this.say('That is the back. Turn it over to use the buttons.');
				return;
			}

			if (local.y >= 12 && local.y <= 32) {
				const button = pagerButtonPlaces.find(place => Math.abs(local.x - place.x) <= 20);
				const actions = {read: () => this.#pressRead(), mode: () => this.#pressMode(), light: () => this.#pressLight(), clear: () => this.#pressClear()};
				actions[button?.name]?.();
			} else if (local.y < 10) {
				this.#pressLight();
			}
		});

		this.on(booth, 'keydown', event => {
			if (event.metaKey || event.ctrlKey || event.altKey) {
				return;
			}

			if (/^[\d*#]$/.test(event.key)) {
				event.preventDefault();
				this.#pressKey(event.key);
			} else if (event.key.toLowerCase() === 'h' || event.key === 'Enter') {
				event.preventDefault();
				this.#toggleHandset();
			} else if (event.key.toLowerCase() === 'b') {
				event.preventDefault();
				this.#togglePhoneBook();
			}
		});

		this.on(booth, 'click', event => {
			const point = canvasPoint(booth, event, 320, 240);
			if (isInside(point, boothRegions.handset) || (this.#phone.isOffHook && point.x >= 76 && point.x < 112 && point.y > 60 && point.y < 130)) {
				this.#toggleHandset();
			} else if (isInside(point, boothRegions.phoneBook)) {
				this.#togglePhoneBook();
			} else if (isInside(point, boothRegions.phone)) {
				if (point.y > boothRegions.phone.y + 78 && state.cup.length > 0) {
					this.#takeCoins();
				} else if (point.y > boothRegions.phone.y + 60) {
					this.#toggleCard();
				} else {
					this.say('Use the keypad under the booth to dial.', this.parts.phoneStatus);
				}
			} else if (point.x < 60 && point.y > 140 && point.y < 210) {
				this.#buyCard();
			}
		});

		setPressed(sound, false);
		setPressed(flip, false);
		setPressed(over, false);
		this.#renderBatteryButtons();
		this.#renderBed();
		this.#renderScore();
		this.#renderBook();
		this.#renderMemory();
		this.#renderDecoder();
		this.#renderPhone();
		this.#drawTable();
	}

	// The clock of the beeper runs only while the toy is on the screen and the tab is visible.
	visibilityChanged(isVisible) {
		this.#tickInterval?.cancel();
		if (isVisible) {
			this.#tickInterval = this.interval(1000, () => {
				this.#tick();
			});

			// The first time, Trond pages soon, so the visitor sees how it works.
			if (!this.#hasWelcomed && this.#state.memory.length === 0) {
				this.#hasWelcomed = true;
				this.#later(2, () => {
					this.#receivePage({sender: 'trond', code: '07734'});
				});
			}
		} else {
			this.#persist();
		}
	}

	// The tones of the line, the voices, and the timers of a call stop when the toy is removed.
	disconnected() {
		this.#clearPhoneTimers();
		stopLine();
		hush();
		this.#persist();
	}

	reducedMotionChanged() {
		this.#drawTable();
		this.#drawBooth();
	}

	// A control that hides or turns itself off gives the focus to the control that takes its place, so a keyboard visitor does not lose their place.
	focusReplacement(control) {
		const {pickUp, table, take, coinReturn, allowance, phoneBookPrevious, phoneBookNext, decoderWindow} = this.parts;
		if (control === pickUp) {
			return table;
		}

		if (control === take) {
			return coinReturn;
		}

		if (control.dataset.beeperCoin !== undefined) {
			return this.#coinButtons.find(button => !button.disabled) ?? allowance;
		}

		if (control === phoneBookPrevious) {
			return phoneBookNext;
		}

		if (control === phoneBookNext) {
			return phoneBookPrevious;
		}

		if (control.dataset.beeperChoice !== undefined) {
			return decoderWindow;
		}

		return super.focusReplacement(control);
	}

	#persist() {
		this.store('state', this.#state);
	}

	#isNight() {
		const {hour} = clockParts(this.#state.clock);
		return hour >= 22 || hour < 7;
	}

	// MARK: The beeper

	#showNotice(text, seconds = 1.6) {
		this.#pager.view = 'notice';
		this.#pager.notice = text;
		this.#pager.viewSince = performance.now();
		this.#pager.noticeUntil = performance.now() + (seconds * 1000);
		this.#drawTable();
	}

	#isDead() {
		return this.#state.battery <= 0;
	}

	#drainBattery(amount) {
		if (this.#isDead()) {
			return;
		}

		this.#state.battery = Math.max(0, this.#state.battery - amount);
		if (this.#isDead()) {
			this.#pager.view = 'idle';
			this.say('The beeper went blank. The battery is dead! Change it, with one from Pappa’s drawer or from the TV remote.');
		} else if (this.#state.battery < 0.2 && !this.#pager.lowBatteryWarned) {
			this.#pager.lowBatteryWarned = true;
			sounds.chirp();
			this.#showNotice('LO BATT', 2.5);
			this.say('Chirp! LO BATT. The battery is running low.');
		}
	}

	#startVibration() {
		if (this.reducedMotion || this.#pager.isOnFloor) {
			return;
		}

		// It walks on the table in a direction of its own, mostly toward the edge, like they always did.
		const angle = randomBetween(-0.9, 1.2);
		this.#pager.vibration = {start: performance.now(), duration: 1300, direction: {x: Math.cos(angle), y: Math.sin(angle)}, last: performance.now()};
		this.#tableLoop.start();
	}

	#alertFor(page) {
		this.#pager.view = 'alert';
		this.#pager.viewPage = page;
		this.#pager.viewSince = performance.now();
		this.#pager.confirmUntil = 0;

		const where = this.#pager.isOnFloor ? ' From behind the radiator!' : (this.#pager.isOver ? ' It is face down. Turn it over to read it.' : '');
		const isVisitor = page.sender === 'visitor';
		const what = isVisitor ? `My beeper got your page: ${page.text}.` : `A new page: ${page.text}.`;

		if (this.#state.mode === 'beep') {
			sounds.beep();
			this.say(`Beep beep beep! ${what}${where}${audio.isOn ? '' : ' (Turn on the sound to hear it.)'}`);
		} else if (this.#state.mode === 'vibrate') {
			sounds.buzz();
			this.#drainBattery(0.01);
			this.#startVibration();
			// The phone only vibrates after the visitor has tapped the page, and while the toy is on the screen.
			if (this.isVisible && navigator.userActivation?.hasBeenActive) {
				navigator.vibrate?.([450, 200, 450]);
			}

			this.say(`Bzzz bzzz! ${what}${where}`);
		} else {
			this.say(`The beeper got a page without a sound. ${what}${where}`);
		}
	}

	#receivePage({code, sender}) {
		if (this.#isDead()) {
			this.say('Somewhere, someone paged me, but the battery of my beeper is dead. I will never know who.');
			return;
		}

		const suffix = senderIds[sender] ? `*${senderIds[sender]}` : '';
		const page = {
			id: this.#state.nextId++,
			code,
			text: code + suffix,
			sender,
			time: this.#state.clock,
			isRead: false,
			// The pages of the visitor and the codes that are not in the code book have nothing to guess.
			isDecoded: sender === 'visitor' || !entryFor({code, sender}),
		};
		this.#state.memory = [page, ...this.#state.memory].slice(0, 10);
		this.#drainBattery(0.012);
		this.#alertFor(page);
		this.#persist();
		this.#renderDecoder();
		this.#renderMemory();
		this.#drawTable();
	}

	#pressRead() {
		this.#pressed('read');
		if (this.#isDead()) {
			this.say('Nothing. The battery is dead.');
			return;
		}

		if (this.#pager.isOver) {
			this.say('The beeper is face down. Turn it over to read it.');
			return;
		}

		this.#pager.confirmUntil = 0;
		if (this.#state.memory.length === 0) {
			this.#showNotice('INGEN MELDING');
			this.say('INGEN MELDING: no pages in the memory.');
			return;
		}

		if (this.#pager.view === 'alert') {
			this.#pager.viewIndex = Math.max(0, this.#state.memory.indexOf(this.#pager.viewPage));
		} else if (this.#pager.view === 'message') {
			this.#pager.viewIndex++;
		} else {
			// The first press shows the newest page that I have not read, or the newest of all.
			const unread = this.#state.memory.findIndex(page => !page.isRead);
			this.#pager.viewIndex = unread === -1 ? 0 : unread;
		}

		if (this.#pager.viewIndex >= this.#state.memory.length) {
			this.#pager.view = 'idle';
			this.say('Back to the clock.');
			this.#drawTable();
			return;
		}

		const page = this.#state.memory[this.#pager.viewIndex];
		page.isRead = true;
		this.#pager.view = 'message';
		this.#pager.viewPage = page;
		this.#pager.viewSince = performance.now();
		sounds.chirp();
		this.say(`Page ${this.#pager.viewIndex + 1} of ${this.#state.memory.length}, from ${dayTimeText(page.time)}: ${page.text}.${page.code === '07734' && !this.#pager.isUpsideDown ? ' Turn it upside down!' : ''}`);
		this.#persist();
		this.#renderMemory();
		this.#drawTable();
	}

	#pressMode() {
		this.#pressed('mode');
		if (this.#isDead()) {
			return;
		}

		this.#state.mode = modes[(modes.indexOf(this.#state.mode) + 1) % modes.length];
		this.#persist();
		const names = {beep: ['PIP', 'Beep: it beeps for a page.'], vibrate: ['VIBRA', 'Vibrate: it buzzes for a page, like in class, so the teacher does not hear it. Mostly.'], silent: ['STILLE', 'Silent: it only shows the envelope.']};
		const [text, description] = names[this.#state.mode];
		if (this.#state.mode === 'beep') {
			sounds.chirp();
		} else if (this.#state.mode === 'vibrate') {
			sounds.buzz();
			this.#startVibration();
		}

		this.#showNotice(text);
		this.say(`Mode: ${description}`);
	}

	#pressLight() {
		this.#pressed('light');
		if (this.#isDead()) {
			return;
		}

		this.#pager.lightUntil = performance.now() + 3500;
		this.#drainBattery(0.006);
		this.say(this.#isNight() ? 'The LCD glows green in the dark room. So cool.' : 'The light is on: the LCD glows green for 3 seconds.');
		this.#tableLoop.start();
		this.#drawTable();
		setTimeout(() => {
			this.#drawTable();
		}, 3600);
	}

	#pressClear() {
		this.#pressed('clear');
		if (this.#isDead() || this.#pager.isOver) {
			return;
		}

		const isMessage = this.#pager.view === 'message' && this.#state.memory.includes(this.#pager.viewPage);
		if (performance.now() >= this.#pager.confirmUntil) {
			if (!isMessage && this.#state.memory.length === 0) {
				this.#showNotice('INGEN MELDING');
				return;
			}

			this.#pager.confirmUntil = performance.now() + 3000;
			this.#pager.clearTarget = isMessage ? this.#pager.viewPage : 'all';
			this.#showNotice(isMessage ? 'SLETT? TRYKK IGJEN' : 'SLETT ALT?', 3);
			this.say(isMessage ? 'SLETT? Press Clear again to delete this page.' : 'SLETT ALT? Press Clear again to delete all the pages.');
			return;
		}

		this.#pager.confirmUntil = 0;
		if (this.#pager.clearTarget === 'all') {
			this.#state.memory = [];
			this.say('All the pages are deleted. Clean slate.');
		} else {
			this.#state.memory = this.#state.memory.filter(page => page !== this.#pager.clearTarget);
			this.say('The page is deleted.');
		}

		sounds.chirp();
		this.#pager.view = 'idle';
		this.#persist();
		this.#renderDecoder();
		this.#renderMemory();
		this.#showNotice('SLETTET');
	}

	// Lights a button of the drawing for a moment, like it is pressed.
	#pressed(name) {
		this.#pressedButtons.set(name, performance.now() + 180);
		this.#drawTable();
		setTimeout(() => {
			this.#drawTable();
		}, 200);
	}

	#newBattery() {
		const wasHalfFull = this.#state.battery > 0.4;
		this.#state.battery = 1;
		this.#pager.lowBatteryWarned = false;
		this.#pager.view = 'boot';
		this.#pager.viewSince = performance.now();
		sounds.chirp();
		setTimeout(() => {
			sounds.beep();
			// A page that came during the test stays on the LCD.
			if (this.#pager.view === 'boot') {
				this.#pager.view = 'idle';
			}

			this.#drawTable();
		}, 1400);
		this.#persist();
		this.#renderBatteryButtons();
		this.#drawTable();
		this.#tableLoop.start();
		return wasHalfFull ? ' It was still half full, but oh well.' : '';
	}

	// MARK: The clock of the beeper

	#later(seconds, callback) {
		this.#laterQueue.push({seconds, callback});
	}

	#newDay(dayIndex) {
		if (dayIndex === this.#state.today) {
			return;
		}

		this.#state.today = dayIndex;
		this.#state.foundToday = 0;
		this.#state.allowanceCount = 0;
		if (this.#state.drawer === 0) {
			this.#state.drawer = 2;
		}

		this.#state.hasRemoteBattery = true;
		this.#renderBatteryButtons();
	}

	#randomPage() {
		const {weekday, hour} = clockParts(this.#state.clock);
		const isSchool = weekday < 5 && hour >= 8 && hour < 14;
		const choices = [
			['trond', 6],
			['kristine', 1],
			['pappa', weekday < 5 && hour >= 9 && hour < 16 ? 2 : 0],
			['lillesoster', hour >= 14 && hour < 20 ? 1.5 : 0],
		];
		let total = 0;
		for (const [, weight] of choices) {
			total += weight;
		}

		let value = Math.random() * total;
		let sender = 'trond';
		for (const [choice, weight] of choices) {
			value -= weight;
			if (value < 0) {
				sender = choice;
				break;
			}
		}

		if (sender === 'trond') {
			this.#receivePage({sender, code: randomItem(isSchool ? ['121', '411', '20', '182'] : ['911', '121', '411', '104', '07734', '88', '182', '20'])});
		} else if (sender === 'kristine') {
			this.#receivePage({sender, code: randomItem(['07734', '411', '88'])});
		} else if (sender === 'pappa') {
			this.#receivePage({sender, code: '55312000'});
		} else {
			// Lillesøster presses the same button over and over, or all of them.
			const digits = randomItem(['1111111111', '1234567890', '4444444', '9876543210', '0000000000000']);
			this.#receivePage({sender, code: digits});
		}
	}

	#minuteTick() {
		this.#state.clock++;
		const {dayIndex, weekday, hour, minute} = clockParts(this.#state.clock);
		this.#newDay(dayIndex);

		this.#drainBattery(0.0002);

		// The battery has less power when the room gets cold at night, so a weak one always beeps at 3 in the morning.
		if (hour === 3 && minute % 5 === 0 && minute <= 30 && this.#state.battery > 0 && this.#state.battery < 0.6) {
			sounds.chirp();
			this.#showNotice('LO BATT', 2.5);
			this.say(minute === 0 ? 'Chirp! 03:00. LO BATT. Why does the battery always run low at 3 in the morning? Pappa says it is the cold: a battery has less power when the house gets cold at night. Change it, or it chirps every 5 minutes.' : `Chirp! ${clockText(this.#state.clock)}. LO BATT. Again.`);
		}

		if (hour >= 23 || hour < 7) {
			return;
		}

		if (this.#state.mammaDay !== dayIndex && ((hour === 16 && minute >= 45) || (hour === 17 && minute < 30)) && Math.random() < 0.12) {
			this.#state.mammaDay = dayIndex;
			this.#receivePage({sender: 'mamma', code: '0000'});
			return;
		}

		if (this.#state.mormorDay !== dayIndex && hour >= 11 && hour < 19 && Math.random() < 0.008) {
			this.#state.mormorDay = dayIndex;
			this.#receivePage({sender: 'mormor', code: '55281403'});
			// She sends it twice, in case the first one did not arrive.
			this.#later(4, () => {
				this.#receivePage({sender: 'mormor', code: '55281403'});
			});
			return;
		}

		const isSchool = weekday < 5 && hour >= 8 && hour < 14;
		if (Math.random() < (isSchool ? 0.012 : (hour < 8 ? 0.008 : 0.025))) {
			this.#randomPage();
			return;
		}

		// A beeper reminds about a page that nobody read, with a chirp every half hour.
		if (minute % 30 === 0 && this.#state.mode === 'beep' && !this.#isDead() && this.#state.memory.some(page => !page.isRead)) {
			sounds.chirp();
		}
	}

	#tick() {
		this.#minuteTick();

		for (const item of [...this.#laterQueue]) {
			item.seconds--;
			if (item.seconds <= 0) {
				this.#laterQueue.splice(this.#laterQueue.indexOf(item), 1);
				item.callback();
			}
		}

		this.#phoneTick();

		if (clockParts(this.#state.clock).minute % 10 === 0) {
			this.#persist();
		}

		this.#renderBed();
		this.#drawTable();
	}

	// MARK: Drawing the table and the beeper

	#drawInsides(context, now) {
		// Seen through the purple plastic: the green circuit board, the chips, the AAA battery, the speaker, and the motor with its weight.
		context.fillStyle = '#1f7a45';
		roundedRectangle(context, -94, -50, 188, 100, 10);
		context.fill();
		context.strokeStyle = '#d9b44a';
		context.lineWidth = 1;
		for (let index = 0; index < 6; index++) {
			context.beginPath();
			context.moveTo(-80 + (index * 12), 50);
			context.lineTo(-80 + (index * 12), 30);
			context.lineTo(-40 + (index * 18), 12);
			context.stroke();
		}

		context.fillStyle = '#111111';
		context.fillRect(24, 34, 22, 12);
		context.fillRect(-6, 36, 12, 8);
		const batteryColor = this.#state.battery > 0 ? '#3e64c8' : '#555555';
		context.fillStyle = batteryColor;
		roundedRectangle(context, -88, 33, 68, 16, 4);
		context.fill();
		context.fillStyle = '#c8c8c8';
		context.fillRect(-20, 37, 5, 8);
		context.fillStyle = '#e8e8e8';
		context.fillRect(-88, 33, 14, 16);
		context.fillStyle = '#d6b23c';
		context.beginPath();
		context.arc(70, -40, 8, 0, Math.PI * 2);
		context.fill();
		context.fillStyle = '#c0c0c0';
		roundedRectangle(context, 58, 36, 22, 10, 3);
		context.fill();
		// The weight on the motor spins when it vibrates.
		const spin = this.#pager.vibration ? now / 18 : 0.6;
		context.fillStyle = '#9a9a9a';
		context.beginPath();
		context.ellipse(84, 41, 3, Math.abs(Math.sin(spin)) * 5 + 1, 0, 0, Math.PI * 2);
		context.fill();
	}

	#drawLcd(context, now) {
		const isLit = now < this.#pager.lightUntil;
		const colors = lcdColors(isLit);
		context.fillStyle = '#2a2a33';
		roundedRectangle(context, -96, -54, 192, 66, 6);
		context.fill();
		context.fillStyle = colors.background;
		roundedRectangle(context, -90, -48, 180, 54, 3);
		context.fill();
		if (isLit) {
			context.save();
			context.shadowColor = '#8dff7a';
			context.shadowBlur = 18;
			context.fillRect(-90, -48, 180, 54);
			context.restore();
		}

		if (this.#isDead()) {
			return;
		}

		const blinkOn = this.reducedMotion || Math.floor(now / 400) % 2 === 0;

		if (this.#pager.view === 'notice' && now > this.#pager.noticeUntil) {
			this.#pager.view = 'idle';
		}

		// A page goes back to the clock after a while, like the real one.
		if ((this.#pager.view === 'message' || this.#pager.view === 'alert') && now - this.#pager.viewSince > 20_000) {
			this.#pager.view = 'idle';
		}

		if (this.#pager.view === 'boot') {
			drawPixelText(context, 'TELENOR', -84, -44, colors.on, {scale: 2});
			drawBigText(context, '88888888888', colors);
			return;
		}

		// The top row: the mode, the envelope with the number of unread pages, and the battery.
		const modeIcon = {beep: icons.bell, vibrate: icons.vibrate, silent: icons.silent}[this.#state.mode];
		drawIcon(context, modeIcon, 50, -44, colors.on, 2);
		const unread = this.#state.memory.filter(page => !page.isRead).length;
		if (unread > 0 && (this.#pager.view !== 'alert' || blinkOn)) {
			drawIcon(context, icons.envelope, 18, -44, colors.on, 2);
		}

		const isLow = this.#state.battery < 0.2;
		if (!isLow || blinkOn) {
			context.fillStyle = colors.on;
			context.fillRect(64, -44, 18, 10);
			context.fillRect(82, -41, 2, 4);
			context.fillStyle = colors.background;
			context.fillRect(66, -42, 14, 6);
			context.fillStyle = colors.on;
			context.fillRect(66, -42, Math.ceil(14 * clamp(this.#state.battery, 0, 1)), 6);
		}

		if (this.#pager.view === 'notice') {
			drawPixelText(context, this.#pager.notice, -84, -24, colors.on, {scale: 2});
			drawPixelText(context, dayTimeText(this.#state.clock), -84, -44, colors.on, {scale: 2});
			return;
		}

		if (this.#pager.view === 'message' || this.#pager.view === 'alert') {
			const page = this.#pager.viewPage;
			const index = this.#state.memory.indexOf(page);
			const label = this.#pager.view === 'alert' ? 'NY' : `${index + 1}/${this.#state.memory.length}`;
			drawPixelText(context, label, -84, -44, colors.on, {scale: 2});
			drawPixelText(context, clockText(page.time), -84 + pixelTextWidth(label, 2) + 6, -44, colors.on, {scale: 1});
			drawPixelText(context, dayNames[clockParts(page.time).weekday], -84 + pixelTextWidth(label, 2) + 6, -38, colors.on, {scale: 1});
			if (this.#pager.view === 'alert' && !blinkOn) {
				return;
			}

			// A long page shows in parts of 11 digits, one after the other.
			const parts = Math.ceil(page.text.length / 11);
			const part = parts > 1 ? Math.floor((now - this.#pager.viewSince) / 1500) % parts : 0;
			drawBigText(context, page.text.slice(part * 11, (part * 11) + 11), colors);
			return;
		}

		drawPixelText(context, dayNames[clockParts(this.#state.clock).weekday], -84, -44, colors.on, {scale: 2});
		if (isLow && blinkOn) {
			drawPixelText(context, 'LO', -58, -44, colors.on, {scale: 2});
		}

		const time = clockText(this.#state.clock);
		const showColon = this.reducedMotion || Math.floor(now / 1000) % 2 === 0;
		for (const [index, character] of [...time].entries()) {
			if (character === ':') {
				if (showColon) {
					context.fillStyle = colors.on;
					context.fillRect(-84 + (index * 15.4) + 4, -24, 3, 3);
					context.fillRect(-84 + (index * 15.4) + 4, -14, 3, 3);
				}
			} else {
				drawDigit(context, character, -84 + (index * 15.4), -30, {on: colors.on, off: colors.off});
			}
		}
	}

	#drawFront(context, now) {
		this.#drawLcd(context, now);
		for (const button of pagerButtonPlaces) {
			const isPressed = (this.#pressedButtons.get(button.name) ?? 0) > now;
			context.fillStyle = isPressed ? '#5a1f8f' : 'rgba(170, 110, 230, 0.95)';
			roundedRectangle(context, button.x - 19, 15 + (isPressed ? 1 : 0), 38, 13, 6.5);
			context.fill();
			context.strokeStyle = '#4a137a';
			context.lineWidth = 1;
			context.stroke();
			drawPixelText(context, button.label, button.x, 19 + (isPressed ? 1 : 0), '#ffffff', {align: 'center'});
		}

		drawPixelText(context, 'TELENOR', -30, 50, 'rgba(255, 255, 255, 0.85)', {align: 'center'});
	}

	#drawPager(context, now) {
		let {x, y, angle} = this.#pose;
		let scale = 1;
		let alpha = 1;
		if (this.#pager.vibration) {
			x += randomBetween(-1.6, 1.6);
			y += randomBetween(-1.6, 1.6);
			angle += randomBetween(-0.02, 0.02);
		}

		if (this.#pager.fall) {
			const progress = clamp((now - this.#pager.fall.start) / 650, 0, 1);
			x += this.#pager.fall.direction.x * progress * 60;
			y += this.#pager.fall.direction.y * progress * 60;
			angle += progress * 1.4;
			scale = 1 - (progress * 0.35);
			alpha = 1 - progress;
		}

		context.save();
		context.globalAlpha = alpha;
		context.translate(x, y);
		context.rotate(angle + (this.#pager.isUpsideDown ? Math.PI : 0));
		context.scale(scale, scale);

		context.fillStyle = 'rgba(40, 20, 0, 0.3)';
		roundedRectangle(context, -100, -54, 208, 118, 24);
		context.fill();

		context.save();
		if (this.#pager.isOver) {
			context.scale(-1, 1);
		}

		this.#drawInsides(context, now);
		context.restore();

		// The see-through purple plastic, with a shine on top.
		const plastic = context.createLinearGradient(0, -58, 0, 58);
		plastic.addColorStop(0, 'rgba(176, 102, 240, 0.62)');
		plastic.addColorStop(1, 'rgba(110, 40, 180, 0.7)');
		context.fillStyle = plastic;
		roundedRectangle(context, -104, -58, 208, 116, 22);
		context.fill();
		context.strokeStyle = '#4a137a';
		context.lineWidth = 3;
		context.stroke();
		context.fillStyle = 'rgba(255, 255, 255, 0.18)';
		roundedRectangle(context, -96, -55, 192, 10, 5);
		context.fill();

		if (this.#pager.isOver) {
			drawBack(context);
		} else {
			this.#drawFront(context, now);
		}

		context.restore();
	}

	#drawTable(now = performance.now()) {
		this.#lastTableDraw = now;
		const context = this.#tableContext;
		context.fillStyle = '#3b2a1e';
		context.fillRect(0, 0, 320, 220);
		// The floor boards under the table.
		context.fillStyle = '#4a3526';
		for (let index = 0; index < 8; index++) {
			context.fillRect(0, index * 28, 320, 2);
		}

		const wood = context.createLinearGradient(0, 0, tableWidth, tableHeight);
		wood.addColorStop(0, '#e2b57a');
		wood.addColorStop(1, '#cf9a5c');
		context.fillStyle = wood;
		context.fillRect(0, 0, tableWidth, tableHeight);
		for (const line of grain) {
			context.strokeStyle = `rgba(120, 70, 20, ${line.shade})`;
			context.lineWidth = 1;
			context.beginPath();
			for (let x = 0; x <= tableWidth; x += 8) {
				const y = line.y + (Math.sin((x / 40) + line.phase) * line.wave);
				if (x === 0) {
					context.moveTo(x, y);
				} else {
					context.lineTo(x, y);
				}
			}

			context.stroke();
		}

		context.fillStyle = 'rgba(120, 70, 20, 0.35)';
		context.fillRect(0, 98, tableWidth, 1);
		context.fillStyle = '#a8763f';
		context.fillRect(tableWidth, 0, 4, tableHeight + 4);
		context.fillRect(0, tableHeight, tableWidth + 4, 4);

		drawWaffle(context);
		drawMilk(context);

		if (!this.#pager.isOnFloor) {
			this.#drawPager(context, now);
		}

		if (this.#isNight()) {
			context.fillStyle = 'rgba(6, 10, 32, 0.78)';
			context.fillRect(0, 0, 320, 220);
			if (!this.#pager.isOnFloor && !this.#pager.isOver && now < this.#pager.lightUntil) {
				const glow = context.createRadialGradient(this.#pose.x, this.#pose.y - 20, 4, this.#pose.x, this.#pose.y - 20, 110);
				glow.addColorStop(0, 'rgba(141, 255, 122, 0.45)');
				glow.addColorStop(1, 'rgba(141, 255, 122, 0)');
				context.fillStyle = glow;
				context.fillRect(0, 0, 320, 220);
				context.save();
				context.translate(this.#pose.x, this.#pose.y);
				context.rotate(this.#pose.angle + (this.#pager.isUpsideDown ? Math.PI : 0));
				this.#drawLcd(context, now);
				context.restore();
			}

			drawPixelText(context, 'NATT', 312, 8, '#8899cc', {align: 'right', scale: 2});
		}

		if (this.#pager.isOnFloor) {
			drawPixelText(context, 'IT FELL OFF THE TABLE!', 160, 100, '#ffffff', {align: 'center', scale: 2});
			drawPixelText(context, '(BEHIND THE RADIATOR)', 160, 116, '#ffd27a', {align: 'center'});
		}
	}

	#stepTable(now) {
		if (this.#pager.vibration) {
			const elapsed = now - this.#pager.vibration.start;
			const delta = Math.min(50, now - this.#pager.vibration.last);
			this.#pager.vibration.last = now;
			// Two bursts of buzzing, with a pause between them, like the motor.
			const isBuzzing = elapsed < 550 || (elapsed > 700 && elapsed < 1300);
			if (isBuzzing) {
				this.#pose.x += this.#pager.vibration.direction.x * delta * 0.03;
				this.#pose.y += this.#pager.vibration.direction.y * delta * 0.03;
				this.#pose.angle += (Math.random() - 0.4) * 0.004 * delta;
			}

			if (elapsed > this.#pager.vibration.duration) {
				this.#pager.vibration = undefined;
			}

			// Off the edge of the table it goes.
			if (this.#pose.x > tableWidth - 20 || this.#pose.y > tableHeight - 14 || this.#pose.y < 20) {
				this.#pager.vibration = undefined;
				this.#pager.fall = {start: now, direction: {x: this.#pose.x > tableWidth - 20 ? 1 : 0, y: this.#pose.y > tableHeight - 14 ? 1 : (this.#pose.y < 20 ? -1 : 0)}};
				sounds.clunk();
				this.say('Bzzz… CLONK! It buzzed right off the table and fell behind the radiator. Pick it up!');
			}
		}

		if (this.#pager.fall && now - this.#pager.fall.start > 650) {
			this.#pager.fall = undefined;
			this.#pager.isOnFloor = true;
			this.parts.pickUp.hidden = false;
		}

		const isAnimating = this.#pager.vibration || this.#pager.fall;
		if (isAnimating || now - this.#lastTableDraw > 120) {
			this.#drawTable(now);
		}
	}

	#pickUp() {
		this.#pager.isOnFloor = false;
		this.#pose.x = 150;
		this.#pose.y = 104;
		this.#pose.angle = randomBetween(-0.08, 0.08);
		this.parts.pickUp.hidden = true;
		this.say('I fished it out from behind the radiator. Dusty, but it works.');
		this.#drawTable();
	}

	// MARK: The phone booth

	#coinCredit() {
		let total = this.#phone.remainder;
		for (const coin of this.#phone.inserted) {
			total += coin;
		}

		return total;
	}

	#credit() {
		return this.#phone.isCardIn ? this.#state.cardUnits : this.#coinCredit();
	}

	// Takes units from the card, or eats the next coin, like the real phone, which never gives change.
	#charge(units) {
		if (this.#phone.isCardIn) {
			if (this.#state.cardUnits >= units) {
				this.#state.cardUnits -= units;
				return true;
			}

			this.#state.cardUnits = 0;
			return false;
		}

		while (this.#phone.remainder < units && this.#phone.inserted.length > 0) {
			this.#phone.remainder += this.#phone.inserted.shift();
			sounds.clunk();
		}

		if (this.#phone.remainder >= units) {
			this.#phone.remainder -= units;
			return true;
		}

		this.#phone.remainder = 0;
		return false;
	}

	#phoneLater(seconds, callback) {
		this.#phone.timeouts.push(setTimeout(callback, seconds * 1000));
	}

	#clearPhoneTimers() {
		for (const timeout of this.#phone.timeouts) {
			clearTimeout(timeout);
		}

		this.#phone.timeouts = [];
	}

	#creditText() {
		return this.#phone.isCardIn ? `KORT ${this.#state.cardUnits}` : `KR ${this.#coinCredit()}`;
	}

	#displayText() {
		switch (this.#phone.stage) {
			case 'idle': {
				return this.#phone.flash || (this.#state.cup.length > 0 ? 'TELENOR\nSE MYNTRETUR' : 'TELENOR\nLØFT RØRET');
			}

			case 'pay': {
				return this.#phone.flash || 'SETT INN KORT\nELLER MYNT';
			}

			case 'dialing': {
				return `${this.#creditText()}\n${this.#phone.dialed ? formatNumber(this.#phone.dialed) : 'TAST NUMMER'}`;
			}

			case 'calling': {
				return `RINGER…\n${formatNumber(this.#phone.dialed)}`;
			}

			case 'paging-prompt': {
				return `${this.#creditText()}\nVENT PÅ TONEN`;
			}

			case 'paging': {
				return `${this.#creditText()}  AVSLUTT #\nMELDING: ${this.#phone.message}_`;
			}

			case 'sent': {
				return `SENDT: ${this.#phone.message}\nLEGG PÅ RØRET`;
			}

			case 'talking': {
				const minutes = Math.floor(this.#phone.seconds / 60);
				const seconds = String(this.#phone.seconds % 60).padStart(2, '0');
				return this.#phone.isConnected ? `${this.#creditText()}\nSAMTALE ${minutes}:${seconds}` : `SAMTALE\nGRATIS`;
			}

			case 'busy': {
				return 'OPPTATT\nLEGG PÅ RØRET';
			}

			case 'unknown': {
				return 'IKKE I BRUK\nLEGG PÅ RØRET';
			}

			case 'emergency': {
				return 'NØDNUMMER\nLEGG PÅ RØRET';
			}

			case 'empty': {
				return `${this.#phone.isCardIn ? 'KORTET ER TOMT' : 'TOM FOR PENGER'}\nLEGG PÅ RØRET`;
			}

			case 'ended': {
				return 'SAMTALEN ER SLUTT\nLEGG PÅ RØRET';
			}

			case 'ringing-in': {
				return 'INNKOMMENDE\nLØFT RØRET';
			}

			default: {
				return '';
			}
		}
	}

	#renderPhone() {
		this.parts.display.textContent = this.#displayText();
		this.parts.handset.textContent = this.#phone.stage === 'ringing-in' ? '📞 Answer the Phone!' : (this.#phone.isOffHook ? '📞 Hang Up' : '📞 Lift the Handset');
		if (this.#phone.isCardIn) {
			this.parts.cardLabel.textContent = 'Take Out Telekort';
		} else {
			this.parts.cardLabel.textContent = this.#state.cardUnits === 0 ? 'Insert Telekort (empty)' : `Insert Telekort (${this.#state.cardUnits})`;
		}

		this.parts.take.hidden = this.#state.cup.length === 0;
		this.#renderPocket();
		this.#drawBooth();
	}

	#pocketTotal() {
		return this.#state.coins[1] + (5 * this.#state.coins[5]) + (10 * this.#state.coins[10]);
	}

	#renderPocket() {
		for (const button of this.#coinButtons) {
			button.disabled = this.#state.coins[button.dataset.beeperCoin] === 0;
		}

		for (const label of this.#coinCounts) {
			const value = label.dataset.beeperCoinCount;
			label.textContent = `${value} kr × ${this.#state.coins[value]}`;
		}

		const picture = cardPictures[this.#state.cardPicture]?.name ?? 'a picture';
		const card = this.#state.cardUnits === 0 ? `Telekort: empty (${picture})` : `Telekort: ${this.#state.cardUnits} tellerskritt (${picture})`;
		const lines = [
			`In my pocket: ${this.#pocketTotal()} kr`,
			card,
			`Empty telekort in my collection: ${this.#state.collection}`,
		];
		if (this.#state.souvenirs.length > 0) {
			lines.push(`Also: ${this.#state.souvenirs.join(', ')}`);
		}

		this.parts.pocket.textContent = lines.join('\n');
	}

	#setStage(stage) {
		this.#phone.stage = stage;
		this.#renderPhone();
	}

	// A first-time visitor does not know what to dial, so the phone tells them while nothing is dialed.
	#dialHint() {
		return this.#phone.stage === 'dialing' && !this.#phone.dialed ? ' Now dial my beeper: 960 10 143.' : '';
	}

	#toDialing() {
		this.#phone.dialed = '';
		this.#phone.stage = 'dialing';
		playLine('dial');
		this.#renderPhone();
	}

	#line(speaker, norwegian, english) {
		this.say(`${speaker}: “${norwegian}” (${english})`, this.parts.phoneStatus);
		speak(norwegian);
	}

	// Plays the lines of a call one after the other, and then the other side hangs up.
	#playLines(speaker, lines, {gap = 3.2, thenHangUp = true} = {}) {
		for (const [index, [norwegian, english]] of lines.entries()) {
			this.#phoneLater(0.3 + (index * gap), () => {
				this.#line(speaker, norwegian, english);
			});
		}

		if (thenHangUp) {
			this.#phoneLater(0.3 + (lines.length * gap), () => {
				this.#otherSideHungUp();
			});
		}
	}

	#otherSideHungUp() {
		this.#phone.isConnected = false;
		this.#phone.stage = 'ended';
		playLine('busy');
		this.#renderPhone();
	}

	#outOfCredit() {
		const wasPaging = this.#phone.stage === 'paging';
		this.#phone.isConnected = false;
		this.#clearPhoneTimers();
		hush();
		sounds.warning();
		playLine('busy');
		this.#phone.stage = 'empty';
		if (wasPaging && this.#phone.message) {
			// The paging service sends what it got when the line drops.
			this.say(`${this.#phone.isCardIn ? 'The card ran out' : 'The money ran out'} in the middle of the message! The paging service sent what I had typed: ${this.#phone.message}. That is going to be confusing.`, this.parts.phoneStatus);
			this.#deliver(this.#phone.target, this.#phone.message);
		} else {
			this.say(this.#phone.isCardIn ? 'Beep beep: KORTET ER TOMT. The card is empty, and the call is over. A new telekort is 40 kr at Narvesen.' : 'Beep beep: the money is used up, and the call is over.', this.parts.phoneStatus);
		}

		this.#renderPhone();
	}

	#connect() {
		const number = this.#phone.dialed;
		if (['110', '112', '113'].includes(number)) {
			stopLine();
			this.#phone.stage = 'emergency';
			this.say('110, 112, and 113 are for real emergencies: fire, police, and ambulance. They are free from every phone, but only for emergencies, so I did not let it ring.', this.parts.phoneStatus);
			this.#renderPhone();
			return;
		}

		const service = services[number] ?? (number.startsWith('960') && number.length === 8 ? {kind: 'pager', who: 'stranger'} : undefined);
		if (!service) {
			this.#phone.stage = 'unknown';
			sounds.notInUse();
			this.#phoneLater(1.1, () => {
				speak('Nummeret du har ringt, er ikke i bruk.');
			});
			this.say('Doo doo DEE: “Nummeret du har ringt, er ikke i bruk.” (The number you called is not in use.) Look in the phone book.', this.parts.phoneStatus);
			this.#renderPhone();
			return;
		}

		const cost = service.cost ?? 2;
		if (this.#credit() < cost) {
			this.#phone.dialed = '';
			this.say(`Not enough money. The call costs at least ${cost} kr. Put in more coins, or a telekort with units.`, this.parts.phoneStatus);
			playLine('dial');
			this.#renderPhone();
			return;
		}

		this.#phone.stage = 'calling';
		playLine('ringback');
		this.#renderPhone();
		this.#phoneLater(service.kind === 'pager' ? 1.6 : randomBetween(2.2, 4.5), () => {
			this.#answer(service, cost);
		});
	}

	#answer(service, cost) {
		stopLine();
		const {hour, weekday} = clockParts(this.#state.clock);
		if (service.kind === 'home') {
			// Pappa is on the Internet in the evening, and the modem has the line.
			const isBusy = (hour >= 18 && hour < 23) ? Math.random() < 0.7 : Math.random() < 0.35;
			if (isBusy) {
				this.#phone.stage = 'busy';
				playLine('busy');
				this.say(randomItem(['OPPTATT. Busy! Pappa is on the Internet again, and the modem has the phone line.', 'OPPTATT. Busy! Lillesøster is talking to her friend Mia. For an hour.', 'OPPTATT. Busy! Pappa is downloading something with the modem. It takes all night.']), this.parts.phoneStatus);
				this.#renderPhone();
				return;
			}
		}

		if (!this.#charge(cost)) {
			this.#outOfCredit();
			return;
		}

		this.#phone.isConnected = true;
		this.#phone.seconds = 0;
		this.#phone.hasWarned = false;
		this.#phone.talker = service.kind;
		this.#phone.lineIndex = 0;

		switch (service.kind) {
			case 'pager': {
				this.#phone.stage = 'paging-prompt';
				this.#phone.target = service.who;
				this.#phone.message = '';
				speak('Personsøk. Tast inn meldingen, og avslutt med firkant.');
				this.say('A voice: “Personsøk. Tast inn meldingen, og avslutt med firkant.” (Pager. Type the message, and end with the pound key.) Wait for the tone…', this.parts.phoneStatus);
				this.#phoneLater(audio.isOn ? 3.8 : 1.6, () => {
					sounds.serviceTone();
					if (this.#phone.stage === 'paging-prompt') {
						this.#phone.stage = 'paging';
						this.say('Beeeep! Now type the code on the keypad, and press # to send it.', this.parts.phoneStatus);
						this.#renderPhone();
					}
				});
				break;
			}

			case 'home': {
				this.#phone.stage = 'talking';
				const lines = this.#isNight() ? [
					['Hallo? Sindre?! Det er midt på natten! Hvor er du?', 'Hello? Sindre?! It is the middle of the night! Where are you?'],
					['Kom hjem, NÅ!', 'Come home, NOW!'],
				] : (hour >= 16 && hour < 19 ? [
					['Hallo, hos Sorhus. Sindre? Kom hjem, middagen er klar!', 'Hello, the Sorhus home. Sindre? Come home, dinner is ready!'],
					['Det er fiskekaker. Og ikke bruk opp telekortet!', 'It is fish cakes. And do not use up the telekort!'],
				] : [
					['Hallo, hos Sorhus. Å, er det deg, Sindre?', 'Hello, the Sorhus home. Oh, is it you, Sindre?'],
					['Husk regntøyet! Og ikke bruk opp telekortet!', 'Remember the rain clothes! And do not use up the telekort!'],
				]);
				this.#playLines('Mamma', lines);
				break;
			}

			case 'mormor': {
				// Mormor talks, and talks, and the units count down, until I hang up.
				this.#phone.stage = 'talking';
				this.#line('Mormor', ...mormorLines[0]);
				this.#phone.lineIndex = 1;
				break;
			}

			case 'office': {
				this.#phone.stage = 'talking';
				if (weekday < 5 && hour >= 8 && hour < 16) {
					this.#playLines('Pappa', [
						['Sorhus. Å, er det deg, Sindre? Jeg sitter i et møte!', 'Sorhus. Oh, is it you, Sindre? I am in a meeting!'],
						[this.#state.hasRemoteBattery ? 'Er alt i orden? Bra. Ha det!' : 'Og hvem har tatt batteriet fra fjernkontrollen?!', this.#state.hasRemoteBattery ? 'Is everything OK? Good. Bye!' : 'And who took the battery from the TV remote?!'],
					]);
				} else {
					this.#playLines('The answering machine', [
						['Du har ringt Sorhus. Jeg er ikke på kontoret. Legg igjen en beskjed etter pipetonen.', 'You called Sorhus. I am not in the office. Leave a message after the beep.'],
					]);
					this.#phoneLater(4.5, () => {
						tone(1000, 0, 0.5, {volume: 0.07});
					});
				}

				break;
			}

			case 'opplysningen': {
				this.#phone.stage = 'talking';
				this.#playLines('Opplysningen', [
					['Opplysningen 180, god dag. Hvem søker du?', 'Directory 180, good day. Who are you looking for?'],
					['Kristine i 7B? Personsøker 960 30 520. Ha en fin dag!', 'Kristine in 7B? Beeper 960 30 520. Have a nice day!'],
				]);
				this.#phoneLater(4, () => {
					this.#state.knowsKristine = true;
					this.#persist();
					this.#renderPhoneBook();
				});
				break;
			}

			case 'taxi': {
				this.#phone.stage = 'talking';
				this.#line('Bergen Taxi', 'Bergen Taxi. Alle våre linjer er opptatt. Vennligst vent.', 'Bergen Taxi. All our lines are busy. Please wait.');
				playLine('waiting');
				break;
			}

			case 'pizza': {
				this.#phone.stage = 'talking';
				this.#playLines('Dolly Dimple’s', [
					['Dolly Dimple’s, hallo!', 'Dolly Dimple’s, hello!'],
					['En telefonkiosk? Nei, vi kjører ikke pizza til en telefonkiosk.', 'A phone booth? No, we do not deliver pizza to a phone booth.'],
				]);
				break;
			}

			default: {
				break;
			}
		}

		this.#renderPhone();
	}

	// What each friend pages back for a code. `call` means that they call the booth.
	#replyOf(who, message) {
		if (who === 'trond') {
			return {143: '404', 831: '404', 1432: '404', '07734': '07734', 88: '88', 411: '20', 20: '20', 121: 'call', 911: 'call', 104: '104', 182: '182', 404: '404404'}[message] ?? '404';
		}

		if (who === 'kristine') {
			if (['143', '831', '1432'].includes(message)) {
				this.#state.kristineLoves++;
				if (this.#state.kristineLoves === 1) {
					return '88';
				}

				return this.#state.kristineLoves === 2 ? '404' : '1432';
			}

			return {'07734': '07734', 411: '07734', 88: '88', 20: '104', 121: '20'}[message] ?? '404';
		}

		if (who === 'pappa') {
			return {911: '911', '0000': '0000'}[message] ?? '55312000';
		}

		return Math.random() < 0.4 ? '404' : undefined;
	}

	#deliver(who, message) {
		if (who === 'me') {
			this.#later(Math.round(randomBetween(2, 4)), () => {
				this.#receivePage({sender: 'visitor', code: message});
			});
			return;
		}

		const reply = this.#replyOf(who, message);
		if (!reply) {
			return;
		}

		this.#later(Math.round(randomBetween(6, 12)), () => {
			if (reply === 'call') {
				this.#ringBooth(who);
				return;
			}

			this.#receivePage({sender: who === 'stranger' ? 'stranger' : who, code: reply});
			if (who === 'kristine' && reply === '1432') {
				this.celebrate();
				this.toast('Kristine paged back 1432: I love you too!');
			}
		});
		this.#persist();
	}

	#sendPage() {
		if (!this.#phone.message) {
			this.say('“Ingen melding.” (No message.) Type the code first, and then press #.', this.parts.phoneStatus);
			speak('Ingen melding.');
			return;
		}

		this.#phone.isConnected = false;
		this.#phone.stage = 'sent';
		sounds.sent();
		speak('Takk. Meldingen er sendt.');
		const names = {me: 'my beeper', trond: 'Trond’s beeper', kristine: 'Kristine’s beeper', pappa: 'Pappa’s beeper', stranger: 'the beeper of someone I do not know'};
		this.say(`“Takk. Meldingen er sendt.” (Thanks, the message is sent.) ${this.#phone.message} is on its way to ${names[this.#phone.target]}. Hang up.`, this.parts.phoneStatus);
		this.#deliver(this.#phone.target, this.#phone.message);
		this.#renderPhone();
	}

	#ringBooth(who) {
		if (this.#phone.isOffHook || this.#phone.stage === 'ringing-in') {
			// The booth is busy, so Trond pages instead.
			this.#receivePage({sender: who, code: '911'});
			return;
		}

		this.#phone.stage = 'ringing-in';
		this.#phone.caller = who;
		this.#phone.ringSeconds = 0;
		sounds.ring();
		this.say('RIIING! The phone in the booth is ringing! Somebody calls the booth. Lift the handset!', this.parts.phoneStatus);
		this.#boothLoop.start();
		this.#renderPhone();
	}

	// The phone rings every 3 seconds of the clock, so it waits while the toy is off the screen, and gives up after 18 seconds.
	#ringTick() {
		this.#phone.ringSeconds++;
		if (this.#phone.ringSeconds < 18) {
			if (this.#phone.ringSeconds % 3 === 0) {
				sounds.ring();
			}

			return;
		}

		this.#phone.stage = 'idle';
		this.say('The phone stopped ringing.', this.parts.phoneStatus);
		this.#renderPhone();
		this.#receivePage({sender: this.#phone.caller, code: '88'});
	}

	#answerIncoming() {
		this.#phone.isOffHook = true;
		this.#phone.stage = 'talking';
		this.#phone.isConnected = false;
		this.#phone.talker = 'incoming';
		this.#playLines('Trond', [
			['Hallo? Sindre? Det er Trond! Jeg ringer fra mamma sin telefon.', 'Hello? Sindre? It is Trond! I am calling from my mom’s phone.'],
			['Du sendte meg en kode. Hva skjer?', 'You sent me a code. What’s up?'],
			['Kom over til meg! Jeg har fått Tekken 3. Ha det!', 'Come over to my place! I got Tekken 3. Bye!'],
		]);
		this.#renderPhone();
	}

	#lift() {
		if (this.#phone.stage === 'ringing-in') {
			this.#answerIncoming();
			return;
		}

		this.#phone.isOffHook = true;
		this.#phone.flash = '';
		if (this.#credit() > 0) {
			this.#toDialing();
			this.say('Tuuuuut: the dial tone. Dial my beeper, 960 10 143, or a number from the phone book.', this.parts.phoneStatus);
		} else {
			this.#setStage('pay');
			this.say('SETT INN KORT ELLER MYNT: put in the telekort or coins first.', this.parts.phoneStatus);
		}
	}

	#hangUp() {
		if (this.#phone.stage === 'paging' && this.#phone.message) {
			this.say(`I hung up before #, so the page ${this.#phone.message} was never sent.`, this.parts.phoneStatus);
		} else if (this.#phone.talker === 'mormor' && this.#phone.isConnected) {
			this.say('“Ha det, Mormor!” Click. She was still talking.', this.parts.phoneStatus);
		} else {
			this.say('Click. The handset is back on the hook.', this.parts.phoneStatus);
		}

		this.#clearPhoneTimers();
		stopLine();
		hush();
		this.#phone.isOffHook = false;
		this.#phone.isConnected = false;
		this.#phone.talker = undefined;
		this.#phone.dialed = '';
		this.#phone.message = '';
		// The coins that the phone did not eat come back in the coin return. What is left of an eaten coin, the phone keeps.
		if (this.#phone.inserted.length > 0) {
			for (const coin of this.#phone.inserted) {
				this.#state.cup.push({kind: 'coin', value: coin});
			}

			this.#phone.inserted = [];
			sounds.coin();
		}

		this.#phone.remainder = 0;
		if (this.#phone.isCardIn) {
			this.#phone.isCardIn = false;
			sounds.card();
		}

		this.#phone.stage = 'idle';
		this.#persist();
		this.#renderPhone();
	}

	#toggleHandset() {
		if (this.#phone.isOffHook) {
			this.#hangUp();
		} else {
			this.#lift();
		}
	}

	#pressKey(key) {
		if (!this.#phone.isOffHook) {
			this.say(this.#phone.stage === 'ringing-in' ? 'Answer the phone first: lift the handset!' : 'Lift the handset first.', this.parts.phoneStatus);
			return;
		}

		sounds.dtmf(key);
		switch (this.#phone.stage) {
			case 'pay': {
				this.say('Nothing happens: put in the telekort or coins first.', this.parts.phoneStatus);
				break;
			}

			case 'dialing': {
				if (key === '*' || key === '#') {
					break;
				}

				if (this.#phone.dialed === '') {
					stopLine();
				}

				this.#phone.dialed += key;
				if (isComplete(this.#phone.dialed)) {
					this.#connect();
					return;
				}

				break;
			}

			case 'paging-prompt': {
				this.say('Too early! Wait for the tone, or the paging service does not hear it.', this.parts.phoneStatus);
				break;
			}

			case 'paging': {
				if (key === '#') {
					this.#sendPage();
					return;
				}

				if (this.#phone.message.length < 16) {
					this.#phone.message += key;
				} else {
					this.say('A page can be 16 digits at most. Press # to send it.', this.parts.phoneStatus);
				}

				break;
			}

			default: {
				break;
			}
		}

		this.#renderPhone();
	}

	// The ringing of the booth, the charge of a call, every 5 seconds, and Mormor, who keeps talking.
	#phoneTick() {
		if (this.#phone.stage === 'ringing-in') {
			this.#ringTick();
			return;
		}

		if (!this.#phone.isConnected) {
			return;
		}

		this.#phone.seconds++;
		if (this.#phone.seconds % 5 === 0) {
			if (!this.#charge(1)) {
				this.#outOfCredit();
				return;
			}

			if (this.#credit() <= 1 && !this.#phone.hasWarned) {
				this.#phone.hasWarned = true;
				sounds.warning();
				this.say(this.#phone.isCardIn ? 'Beep beep! The card is almost empty!' : 'Beep beep! The money is almost used up. Put in more coins, quick!', this.parts.phoneStatus);
			}
		}

		// After her first lines, she goes around her stories again, from the hip.
		if (this.#phone.talker === 'mormor' && this.#phone.seconds % 4 === 0) {
			const index = this.#phone.lineIndex < mormorLines.length ? this.#phone.lineIndex : 2 + ((this.#phone.lineIndex - mormorLines.length) % (mormorLines.length - 2));
			this.#line('Mormor', ...mormorLines[index]);
			this.#phone.lineIndex++;
		}

		this.#renderPhone();
	}

	#insertCoin(value) {
		if (this.#state.coins[value] === 0) {
			return;
		}

		this.#state.coins[value]--;
		sounds.coin();
		if (!this.#phone.isOffHook || this.#phone.stage === 'ringing-in') {
			this.#state.cup.push({kind: 'coin', value});
			this.say('Clink… clunk. The coin fell right through to the coin return, as the handset is on the hook.', this.parts.phoneStatus);
		} else if (Math.random() < 0.15) {
			// The phone rejects some coins for no reason, like the real ones.
			this.#state.cup.push({kind: 'coin', value});
			this.say('Clink… clunk. The phone spat the coin out in the coin return. Rub it on your jeans and try again!', this.parts.phoneStatus);
		} else {
			this.#phone.inserted.push(value);
			if (this.#phone.stage === 'pay') {
				this.#toDialing();
			}

			this.say(`Clink! ${value} kr in. ${this.#phone.isCardIn ? 'The card pays first.' : `Credit: ${this.#coinCredit()} kr.`}${this.#dialHint()}`, this.parts.phoneStatus);
		}

		this.#persist();
		this.#renderPhone();
	}

	#pressCoinReturn() {
		sounds.clunk();
		let returned = 0;
		if (this.#phone.isOffHook && !this.#phone.isConnected && this.#phone.inserted.length > 0) {
			for (const coin of this.#phone.inserted) {
				this.#state.cup.push({kind: 'coin', value: coin});
			}

			returned = this.#phone.inserted.length;
			this.#phone.inserted = [];
			sounds.coin();
			if (this.#phone.stage === 'dialing' && this.#credit() === 0) {
				stopLine();
				this.#phone.stage = 'pay';
			}
		}

		// Kids always checked the coin return, because sometimes somebody forgot their coins.
		const chance = 0.45 / (1 + this.#state.foundToday);
		if (Math.random() < chance) {
			let total = 0;
			for (const thing of foundThings) {
				total += thing.weight;
			}

			let value = Math.random() * total;
			let found = foundThings[0];
			for (const thing of foundThings) {
				value -= thing.weight;
				if (value < 0) {
					found = thing;
					break;
				}
			}

			this.#state.cup.push({...found.item});
			this.#state.foundToday++;
			sounds.coin();
			this.say(`${returned > 0 ? 'My coins came back, and… ' : ''}${found.text}`, this.parts.phoneStatus);
		} else if (returned > 0) {
			this.say(`Clunk. My ${returned === 1 ? 'coin came' : 'coins came'} back in the coin return.`, this.parts.phoneStatus);
		} else {
			this.say('Clunk. Nothing in the coin return. I always check, because sometimes somebody forgot a coin.', this.parts.phoneStatus);
		}

		this.#persist();
		this.#renderPhone();
	}

	#takeCoins() {
		const names = [];
		for (const item of this.#state.cup) {
			if (item.kind === 'coin') {
				this.#state.coins[item.value]++;
				names.push(`${item.value} kr`);
			} else {
				names.push(item.name);
				if (!this.#state.souvenirs.includes(item.name)) {
					this.#state.souvenirs = [...this.#state.souvenirs, item.name].slice(-5);
				}
			}
		}

		this.#state.cup = [];
		sounds.coin();
		this.say(`I took ${names.join(', ')} from the coin return.`, this.parts.phoneStatus);
		this.#persist();
		this.#renderPhone();
	}

	#toggleCard() {
		if (this.#phone.isCardIn) {
			if (this.#phone.isConnected) {
				this.say('Not during a call! The phone holds on to the card.', this.parts.phoneStatus);
				return;
			}

			this.#phone.isCardIn = false;
			sounds.card();
			if (this.#phone.stage === 'dialing' && this.#credit() === 0) {
				stopLine();
				this.#phone.stage = 'pay';
			}

			this.say('I took the telekort out of the phone.', this.parts.phoneStatus);
			this.#renderPhone();
			return;
		}

		sounds.card();
		if (this.#state.cardUnits === 0) {
			this.#phone.flash = this.#phone.stage === 'pay' ? 'KORTET ER TOMT\nSETT INN MYNT' : 'KORTET ER TOMT\nTA UT KORTET';
			this.say('The phone spits the card back out: KORTET ER TOMT. 0 tellerskritt. I keep it for my collection, and buy a new one at Narvesen.', this.parts.phoneStatus);
			this.#renderPhone();
			setTimeout(() => {
				this.#phone.flash = '';
				this.#renderPhone();
			}, 2500);
			return;
		}

		this.#phone.isCardIn = true;
		if (this.#phone.stage === 'pay') {
			this.#toDialing();
		}

		this.say(`The card slides in with a click: ${this.#state.cardUnits} tellerskritt left.${this.#dialHint()}`, this.parts.phoneStatus);
		this.#renderPhone();
	}

	#buyCard() {
		if (this.#phone.isCardIn) {
			this.say('Take the telekort out of the phone first.', this.parts.phoneStatus);
			return;
		}

		if (this.#state.cardUnits > 0) {
			this.say(`My telekort still has ${this.#state.cardUnits} tellerskritt. Mamma says: use it up first!`, this.parts.phoneStatus);
			return;
		}

		const total = this.#pocketTotal();
		if (total < 40) {
			this.say(`A telekort is 40 kr, and I only have ${total} kr. Ask Mamma for lommepenger?`, this.parts.phoneStatus);
			return;
		}

		// The lady at Narvesen gives the change in the biggest coins she has.
		let change = total - 40;
		this.#state.coins = {10: Math.floor(change / 10), 5: 0, 1: 0};
		change %= 10;
		this.#state.coins[5] = Math.floor(change / 5);
		this.#state.coins[1] = change % 5;
		this.#state.collection++;

		let picture = Math.floor(Math.random() * cardPictures.length);
		if (picture === this.#state.cardPicture) {
			picture = (picture + 1) % cardPictures.length;
		}

		this.#state.cardPicture = picture;
		this.#state.cardUnits = 40;
		sounds.coin();
		this.say(`The lady at Narvesen gives me a new telekort with ${cardPictures[picture].name}: 40 tellerskritt. The empty one goes in my collection: ${this.#state.collection} ${this.#state.collection === 1 ? 'card' : 'cards'}!`, this.parts.phoneStatus);
		this.#persist();
		this.#renderPhone();
	}

	#askAllowance() {
		if (this.#state.allowanceCount >= 2) {
			this.#line('Mamma', 'Penger vokser ikke på trær!', 'Money does not grow on trees!');
			return;
		}

		this.#state.allowanceCount++;
		this.#state.coins[10] += 2;
		sounds.coin();
		this.#line('Mamma', 'Her er 20 kroner. Ikke bruk alt på telefonkiosken!', 'Here is 20 kroner. Do not spend it all on the phone booth!');
		this.#persist();
		this.#renderPocket();
	}

	// MARK: The phone book

	#phoneBookPages() {
		return [
			{
				title: 'Telefonkatalogen 1999 · Bergen · A–H',
				entries: [['Bergen Taxi', '07000'], ['Dolly Dimple’s Pizza', '55 90 60 60'], ['Hansen, Trond, personsøker (in pencil)', '960 20 777']],
				note: 'Someone drew a moustache on the man in the ad for Telenor Mobil.',
			},
			{
				title: 'I–M',
				entries: this.#state.knowsKristine ? [['Kristine, personsøker (written by me, with a heart)', '960 30 520']] : [['Jo… (torn)', '55 2…'], ['K…', '(torn out)']],
				note: this.#state.knowsKristine ? 'The page with K is still torn out, but now I wrote her number on the cover.' : 'The page with K is torn out! I bet somebody wanted the number of Kristine in my class. 180 Opplysningen knows every number.',
			},
			{
				title: 'N–S',
				entries: [['Opplysningen', '180'], ['Sorhus, hjemme', '55 16 19 99'], ['Sorhus, kontor (Pappa)', '55 31 20 00'], ['Sorhus, personsøker (Pappa)', '960 40 911'], ['Sindre, personsøker (by Lillesøster, with a heart)', '960 10 143']],
				note: 'This page is gray from all the fingers.',
			},
			{
				title: 'T–Å',
				entries: [['Øvregaard, Mormor', '55 28 14 03']],
				note: 'The rest of the page is gone. Someone wrote “Trond er en tulling” on the back cover.',
			},
		];
	}

	#renderPhoneBook() {
		const pages = this.#phoneBookPages();
		const page = pages[this.#phoneBookPage];
		this.parts.phoneBookTitle.textContent = `${page.title} (page ${this.#phoneBookPage + 1} of ${pages.length})`;
		this.parts.phoneBookEntries.replaceChildren(...page.entries.map(([name, number]) => {
			const item = document.createElement('li');
			const nameElement = document.createElement('span');
			nameElement.textContent = name;
			const numberElement = document.createElement('strong');
			numberElement.textContent = number;
			item.append(nameElement, numberElement);
			return item;
		}));
		this.parts.phoneBookNote.textContent = page.note;

		this.parts.phoneBookPrevious.disabled = this.#phoneBookPage === 0;
		this.parts.phoneBookNext.disabled = this.#phoneBookPage === pages.length - 1;
	}

	#togglePhoneBook() {
		this.parts.phoneBook.hidden = !this.parts.phoneBook.hidden;
		this.parts.phoneBookToggle.setAttribute('aria-expanded', String(!this.parts.phoneBook.hidden));
		if (!this.parts.phoneBook.hidden) {
			this.#renderPhoneBook();
		}

		this.#drawBooth();
	}

	// MARK: Drawing the booth

	#drawPhoneBox(context, now) {
		const shake = this.#phone.stage === 'ringing-in' && !this.reducedMotion ? Math.round(Math.sin(now / 30)) : 0;
		const {phone: box} = boothRegions;
		context.save();
		context.translate(shake, 0);
		context.fillStyle = '#9ea3ab';
		roundedRectangle(context, box.x, box.y, box.width, box.height, 4);
		context.fill();
		context.fillStyle = '#c7cbd1';
		context.fillRect(box.x + 2, box.y + 2, box.width - 4, 6);
		drawPixelText(context, 'TELENOR', box.x + (box.width / 2), box.y + 10, '#0033a0', {align: 'center'});
		// The little display shows the first line of the real one.
		context.fillStyle = '#b7c49a';
		context.fillRect(box.x + 6, box.y + 18, box.width - 12, 11);
		drawPixelText(context, this.#displayText().split('\n')[0].slice(0, 12), box.x + 8, box.y + 21, '#1b2410');
		for (let row = 0; row < 4; row++) {
			for (let column = 0; column < 3; column++) {
				context.fillStyle = '#e8e9ec';
				context.fillRect(box.x + 14 + (column * 12), box.y + 34 + (row * 9), 8, 6);
			}
		}

		// The card slot, with the card in it, and the coin slot.
		context.fillStyle = '#222';
		context.fillRect(box.x + 8, box.y + 72, 22, 3);
		if (this.#phone.isCardIn) {
			const colors = cardPictures[this.#state.cardPicture]?.colors ?? ['#5aa0e0', '#2f6a3a'];
			context.fillStyle = colors[0];
			context.fillRect(box.x + 9, box.y + 64, 20, 9);
			context.fillStyle = colors[1];
			context.fillRect(box.x + 9, box.y + 69, 20, 4);
		}

		context.fillRect(box.x + 42, box.y + 70, 3, 8);
		// The coin return cup, with what is in it.
		context.fillStyle = '#5a5f66';
		context.fillRect(box.x + 36, box.y + 80, 18, 7);
		for (const [index, item] of this.#state.cup.slice(0, 4).entries()) {
			context.fillStyle = item.kind === 'coin' ? (item.value === 10 ? '#d9b440' : '#d0d4d8') : '#c0392b';
			context.beginPath();
			context.arc(box.x + 40 + (index * 4), box.y + 84, 2.5, 0, Math.PI * 2);
			context.fill();
		}

		context.restore();

		// The handset, on the hook or hanging on its cord.
		const {handset} = boothRegions;
		context.strokeStyle = '#111';
		context.lineWidth = 2;
		context.beginPath();
		const cordStart = {x: box.x + 2, y: box.y + 60};
		const cordEnd = this.#phone.isOffHook ? {x: 98, y: 120} : {x: handset.x + 14, y: handset.y + 70};
		for (let step = 0; step <= 24; step++) {
			const progress = step / 24;
			const x = cordStart.x + ((cordEnd.x - cordStart.x) * progress) + (Math.sin(step * 2.2) * 2.5);
			const y = cordStart.y + ((cordEnd.y - cordStart.y) * progress) + ((this.#phone.isOffHook ? 30 : 6) * Math.sin(progress * Math.PI));
			if (step === 0) {
				context.moveTo(x, y);
			} else {
				context.lineTo(x, y);
			}
		}

		context.stroke();
		context.fillStyle = '#1a1a1a';
		if (this.#phone.isOffHook) {
			context.save();
			context.translate(92, 96);
			context.rotate(-0.5);
			roundedRectangle(context, -6, -26, 12, 52, 5);
			context.fill();
			context.fillRect(-9, -30, 18, 10);
			context.fillRect(-9, 20, 18, 10);
			context.restore();
		} else {
			context.save();
			context.translate(shake, 0);
			roundedRectangle(context, handset.x + 8, handset.y + 8, 12, 58, 5);
			context.fill();
			context.fillRect(handset.x + 4, handset.y + 4, 20, 12);
			context.fillRect(handset.x + 4, handset.y + 58, 20, 12);
			context.restore();
		}

		if (this.#phone.stage === 'ringing-in' && (this.reducedMotion || Math.floor(now / 300) % 2 === 0)) {
			drawPixelText(context, 'RIIING!', 172, 46, '#ffee55', {align: 'center', scale: 2});
		}
	}

	#drawPhoneBookOnChain(context) {
		const {phoneBook: book} = boothRegions;
		context.strokeStyle = '#c0c0c0';
		context.lineWidth = 1;
		for (let index = 0; index < 5; index++) {
			context.strokeRect(150 + (index % 2), 148 + (index * 3), 3, 3);
		}

		if (this.parts.phoneBook.hidden) {
			context.fillStyle = '#f4f1e4';
			context.fillRect(book.x + 10, book.y + 10, 46, 46);
			context.fillStyle = '#d9d2b0';
			context.fillRect(book.x + 10, book.y + 50, 46, 6);
			context.fillStyle = '#0033a0';
			context.fillRect(book.x + 10, book.y + 10, 46, 10);
			drawPixelText(context, 'KATALOG', book.x + 33, book.y + 13, '#ffffff', {align: 'center'});
			// The torn page sticks out.
			context.fillStyle = '#ffffff';
			context.beginPath();
			context.moveTo(book.x + 56, book.y + 28);
			context.lineTo(book.x + 62, book.y + 31);
			context.lineTo(book.x + 57, book.y + 35);
			context.lineTo(book.x + 61, book.y + 40);
			context.lineTo(book.x + 56, book.y + 42);
			context.fill();
		} else {
			context.fillStyle = '#f4f1e4';
			context.fillRect(book.x - 4, book.y + 10, 74, 42);
			context.fillStyle = '#bbb';
			context.fillRect(book.x + 32, book.y + 10, 2, 42);
			context.fillStyle = '#555';
			for (let row = 0; row < 7; row++) {
				context.fillRect(book.x, book.y + 16 + (row * 5), 28, 1);
				context.fillRect(book.x + 38, book.y + 16 + (row * 5), 28, 1);
			}
		}
	}

	#drawBooth(now = performance.now()) {
		this.#lastBoothDraw = now;
		const context = this.#boothContext;
		drawStreet(context);

		if (!this.reducedMotion) {
			context.strokeStyle = 'rgba(170, 190, 230, 0.5)';
			context.lineWidth = 1;
			for (const drop of rain) {
				context.beginPath();
				context.moveTo(drop.x, drop.y);
				context.lineTo(drop.x - 1.5, drop.y + drop.length);
				context.stroke();
			}
		}

		// The red booth, with the sign on top.
		context.fillStyle = '#b5121b';
		context.fillRect(64, 8, 192, 228);
		context.fillStyle = '#1a1a1a';
		context.fillRect(70, 12, 180, 16);
		drawPixelText(context, 'TELEFON', 160, 15, '#ffffff', {align: 'center', scale: 2});
		// Inside, through the glass.
		context.fillStyle = '#5c6a7a';
		context.fillRect(72, 32, 176, 196);
		context.fillStyle = '#4a5664';
		context.fillRect(72, 146, 176, 6);
		context.fillStyle = '#7a8796';
		context.fillRect(100, 144, 120, 4);
		this.#drawPhoneBox(context, now);
		this.#drawPhoneBookOnChain(context);

		// The glass, with the drops of the rain running down.
		context.fillStyle = 'rgba(180, 210, 240, 0.12)';
		context.fillRect(72, 32, 176, 196);
		context.fillStyle = 'rgba(255, 255, 255, 0.12)';
		context.beginPath();
		context.moveTo(80, 32);
		context.lineTo(110, 32);
		context.lineTo(80, 90);
		context.fill();
		context.fillStyle = 'rgba(220, 235, 255, 0.55)';
		for (const drop of glassDrops) {
			context.beginPath();
			context.arc(drop.x, drop.y, drop.size, 0, Math.PI * 2);
			context.fill();
		}

		// The frame of the glass panes.
		context.fillStyle = '#b5121b';
		context.fillRect(72, 150, 176, 3);
		context.fillRect(72, 196, 176, 3);
		context.fillStyle = '#7a0a10';
		context.fillRect(64, 8, 192, 2);
		context.fillRect(64, 232, 192, 4);
		context.fillStyle = '#d0d0d0';
		context.fillRect(240, 150, 3, 22);
	}

	#stepBooth(now) {
		if (!this.reducedMotion) {
			for (const drop of rain) {
				drop.y += drop.speed;
				drop.x -= drop.speed * 0.25;
				if (drop.y > 240) {
					drop.y = -10;
					drop.x = Math.random() * 340;
				}
			}

			for (const drop of glassDrops) {
				drop.y += drop.speed;
				if (drop.y > 226) {
					drop.y = 34;
					drop.x = randomBetween(76, 244);
				}
			}
		}

		if (now - this.#lastBoothDraw > 33) {
			this.#drawBooth(now);
		}
	}

	// MARK: The decoder, the code book, and the memory

	#isGuessable(page) {
		return !page.isDecoded && entryFor(page) !== undefined;
	}

	#decoderTarget() {
		return this.#state.memory.find(page => page.id === this.#decoder.pageId && this.#isGuessable(page)) ?? this.#state.memory.find(page => this.#isGuessable(page));
	}

	#renderDecoder() {
		if (this.#decoder.isLocked) {
			return;
		}

		const page = this.#decoderTarget();
		if (!page) {
			this.#decoder.pageId = undefined;
			this.parts.decodeCode.textContent = this.#state.memory.length > 0 ? 'All decoded! Wait for the next page.' : 'No pages yet. Wait for one, or page me from the booth!';
			for (const button of this.#choiceButtons) {
				button.hidden = true;
			}

			return;
		}

		const entry = entryFor(page);
		if (this.#decoder.pageId !== page.id) {
			this.#decoder.pageId = page.id;
			this.#decoder.choices = shuffle([entry.meaning, ...entry.wrong]);
		}

		this.parts.decodeCode.textContent = `${dayTimeText(page.time)} · ${page.text}`;
		for (const [index, button] of this.#choiceButtons.entries()) {
			button.hidden = false;
			button.dataset.state = '';
			button.textContent = this.#decoder.choices[index];
		}
	}

	#choose(index) {
		const page = this.#decoderTarget();
		if (!page || this.#decoder.isLocked) {
			return;
		}

		const entry = entryFor(page);
		const isRight = this.#decoder.choices[index] === entry.meaning;
		this.#decoder.isLocked = true;
		// The guesses stay enabled, so the focus stays on them, and the lock ignores more clicks.
		for (const [buttonIndex, button] of this.#choiceButtons.entries()) {
			if (this.#decoder.choices[buttonIndex] === entry.meaning) {
				button.dataset.state = 'right';
			} else if (buttonIndex === index) {
				button.dataset.state = 'wrong';
			}
		}

		page.isDecoded = true;
		const isNewCode = !this.#state.known.includes(entry.code);
		if (isNewCode) {
			this.#state.known.push(entry.code);
		}

		if (senderIds[page.sender] && !this.#state.knownSenders.includes(page.sender)) {
			this.#state.knownSenders.push(page.sender);
		}

		const from = senderNames[page.sender];
		const name = entry.code === 'lillesoster' ? 'all those numbers' : entry.code;
		if (isRight) {
			this.#state.streak++;
			this.#state.bestStreak = Math.max(this.#state.bestStreak, this.#state.streak);
			const points = 10 + ((this.#state.streak - 1) * 5);
			this.#state.score += points;
			this.say(`Right! ${name} means “${entry.meaning}”, from ${from}: ${entry.why}. +${points} points.`, this.parts.decodeStatus);
		} else {
			this.#state.streak = 0;
			this.say(`Wrong! ${name} means “${entry.meaning}”, from ${from}: ${entry.why}.${isNewCode ? ' It goes in my code book.' : ''}`, this.parts.decodeStatus);
		}

		if (!this.#state.hasCrackedAll && codes.every(candidate => this.#state.known.includes(candidate.code))) {
			this.#state.hasCrackedAll = true;
			this.celebrate();
			this.toast('I cracked every code of my class!');
		}

		this.#persist();
		this.#renderScore();
		this.#renderBook();
		this.#renderMemory();
		setTimeout(() => {
			this.#decoder.isLocked = false;
			this.#renderDecoder();
		}, 1800);
	}

	#renderScore() {
		this.parts.score.textContent = `Points: ${this.#state.score} · Streak: ${this.#state.streak} · Best streak: ${this.#state.bestStreak}`;
	}

	#renderBook() {
		const items = [];
		for (const entry of codes) {
			if (this.#state.known.includes(entry.code)) {
				const item = document.createElement('li');
				item.textContent = `${entry.label ?? entry.code} = ${entry.meaning} (${entry.why})`;
				items.push(item);
			}
		}

		for (const sender of this.#state.knownSenders) {
			const item = document.createElement('li');
			item.textContent = `*${senderIds[sender]} at the end = from ${senderNames[sender]}`;
			items.push(item);
		}

		this.parts.book.replaceChildren(...items);
		const count = codes.filter(entry => this.#state.known.includes(entry.code)).length;
		this.parts.bookCount.textContent = `${count} of ${codes.length} codes. In the back of my school planner, in pencil.`;
	}

	#renderMemory() {
		if (this.#state.memory.length === 0) {
			const item = document.createElement('li');
			item.textContent = 'Empty.';
			this.parts.memory.replaceChildren(item);
			return;
		}

		this.parts.memory.replaceChildren(...this.#state.memory.map(page => {
			const item = document.createElement('li');
			const entry = entryFor(page);
			let meaning = '?';
			if (page.sender === 'visitor') {
				meaning = entry ? `${entry.meaning}, from you` : 'from you';
			} else if (page.isDecoded && entry) {
				meaning = `${entry.meaning}, from ${senderNames[page.sender]}`;
			} else if (page.isDecoded) {
				meaning = `from ${senderNames[page.sender]}`;
			}

			item.textContent = `${dayTimeText(page.time)} ${page.isRead ? ' ' : '•'} ${page.text}: ${meaning}`;
			return item;
		}));
	}

	#renderBatteryButtons() {
		this.parts.drawer.textContent = this.#state.drawer > 0 ? `🔋 Battery from Pappa’s Drawer (${this.#state.drawer})` : '🔋 Pappa’s Drawer (empty)';
		this.parts.remote.textContent = this.#state.hasRemoteBattery ? '📺 Battery from the TV Remote' : '📺 The TV Remote (no battery)';
	}

	#renderBed() {
		this.parts.bed.textContent = this.#isNight() ? '☀️ Get Up' : '🛏 Go to Bed';
	}
}
