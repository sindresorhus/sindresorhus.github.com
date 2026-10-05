// My Furby on the 1999 page: a Furby of 1998, drawn on a canvas, that blinks, wiggles its ears, talks Furbish, learns English as the visitor plays with it, gets hungry, sleepy, and sick, dances to music, chatters with Lillesøster’s Furby, and wakes the house at 3 in the morning until its batteries come out. What it learns is kept in the browser. The canvas runs only while it is on screen and the tab is visible. Nothing makes a sound until the visitor turns on the sound or plays music.
const randomItem = items => items[Math.floor(Math.random() * items.length)];
const clamp = (value, minimum, maximum) => Math.min(Math.max(value, minimum), maximum);
const now = () => performance.now() / 1000;

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

// The Furbish words of the real Furby of 1998, with what they mean. The dictionary card fills in as the Furby says them.
const dictionary = {
	'a-loh': 'light',
	'a-tay': 'hungry',
	'ay-ay': 'look',
	'boh-bay': 'worry',
	boo: 'no',
	dah: 'big',
	doo: 'what',
	'doo-ay': 'fun',
	'doo-moh': 'please',
	'e-day': 'good',
	'e-tah': 'yes',
	kah: 'me',
	'koh-koh': 'again',
	'loo-lay': 'play',
	'may-lah': 'hug',
	'may-may': 'love',
	'may-tah': 'kiss',
	'mee-mee': 'very',
	'nah-bah': 'down',
	'noh-lah': 'dance',
	'o-kay': 'okay',
	'toh-loo': 'like',
	'u-nye': 'you',
	'u-tye': 'up',
	wah: 'yeah',
	'way-loh': 'sleep',
	'wee-tee': 'sing',
};

// A Furbish word of a phrase, which the Furby says in English once it has learned enough.
const word = furbish => [furbish, dictionary[furbish]];

// Builds a phrase from text, where the Furbish words are written in braces, like `{kah} {a-tay}!`, and the rest is said as it is.
const phrase = text => text.split(/(\{[a-z-]+\})/).filter(Boolean).map(part => (part.startsWith('{') ? word(part.slice(1, -1)) : part));

const phrases = {
	hello: ['Hee hee! {dah} {a-loh} {u-tye}!', '{u-nye} {loo-lay} {doo}?', '{kah} {e-day}! {wah}!'],
	idle: ['{u-nye} {loo-lay} {doo}?', '{ay-ay}! {ay-ay}!', '{kah} {toh-loo} {u-nye}.', '{wah}!', '{kah} {may-may} {u-nye}.', 'Hee hee! {dah} {doo-ay}!', '{u-nye} {e-day}?', 'Doo-dah-doo-dah… {wee-tee}?'],
	hungry: ['{kah} {a-tay}!', '{kah} {mee-mee} {a-tay}! {doo-moh}!', '{a-tay}! {a-tay}!'],
	sleepy: ['Yaaawn… {kah} {way-loh}.', 'Yaaawn… {dah} {way-loh}…'],
	sick: ['Ah… ah… AH-CHOO! {kah} {boh-bay}…', '*cough* *cough* {kah} {boh-bay}…'],
	bored: ['{u-nye} {loo-lay} {doo}?', '{doo}? {doo}? {loo-lay}?', 'Hey! {ay-ay} {kah}!'],
	fed: ['Yum! {kah} {toh-loo}!', '{e-day}! {doo-moh} {koh-koh}!', 'Mmm, {dah} {e-day}!'],
	full: ['{boo} {koh-koh}!', '{boo}! {kah} {dah}!'],
	tickled: ['Hee hee hee! {koh-koh}!', 'Hee hee! {dah} {doo-ay}!', 'Hee hee hee hee!'],
	tickledTooMuch: ['Hee… {boo}! {boo} {koh-koh}!'],
	petted: ['Mmmmm… {e-day}.', '{kah} {may-may} {u-nye}.', 'Ooooh… {mee-mee} {e-day}.'],
	hugged: ['{kah} {may-may} {u-nye}… {kah} {way-loh}.'],
	upsideDown: ['Hey! {kah} {dah} {boh-bay}! Me scared!', 'Whoa! {boh-bay}! {boh-bay}!'],
	stillUpsideDown: ['Hey! Hey!', 'HEY! {u-tye}! {u-tye}!', '{doo-moh}! {u-tye}!'],
	rightSideUp: ['Wheee! {koh-koh}!', 'Wheee! {dah} {doo-ay}!'],
	shaken: ['Whoa! {dah} {boh-bay}!', 'Whoaaa! {boo}!'],
	dizzy: ['{kah}… {boh-bay}… Me dizzy.'],
	clapped: ['{dah}! {doo}?', '{doo}? {ay-ay}!'],
	woken: ['{doo}? {dah} {a-loh} {u-tye}?', 'Yaaawn… {doo}?'],
	dark: ['{dah} {a-loh} {nah-bah}… Me scared. {may-lah} me?'],
	coveredEyes: ['{doo}? {dah} {a-loh} {nah-bah}?'],
	peekaboo: ['{a-loh}! Hee hee!'],
	lightOn: ['{dah} {a-loh} {u-tye}! {e-day}!'],
	medicine: ['Bleh! Fish! … {kah} {e-day}! Me better!'],
	noMedicine: ['{boo}! {boo}! Bleh!'],
	refuses: ['{boo}… {kah} {boh-bay}…'],
	dancing: ['{wee-tee}! {noh-lah}!', '♪ {wee-tee} {wee-tee} {kah} {noh-lah} ♪', '♪ La la la! {dah} {doo-ay}! ♪'],
	night: ['{dah} {a-loh} {nah-bah}… {kah} {way-loh}.'],
	alarm: ['{dah} {a-loh} {u-tye}!!!', '{wee-tee}! {wee-tee}! {wee-tee}!', '{u-nye} {loo-lay} {doo}?!', '{kah} {a-tay}!!!', 'HEE HEE HEE HEE!', '{koh-koh}! {koh-koh}! {koh-koh}!', '{doo}? {doo}? {doo}?', '♪ {kah} {noh-lah} {kah} {noh-lah} ♪'],
	louder: ['{wah}! {koh-koh}!!!', 'HEE HEE! {dah} {doo-ay}!!!', '{u-nye} {loo-lay}!!!'],
	booted: ['Hee hee! {dah} {a-loh} {u-tye}! {kah} {e-day}!'],
	name: name => [word('kah'), ` ${name}!`],
	nsa: ['{kah}… {ay-ay}.', '{ay-ay}… {ay-ay}…', '{kah} {toh-loo} {u-nye}. Hee hee.'],
	sisterPoked: ['Hee hee!', '{doo}?', '{kah} {e-day}!', '{wah}!'],
	sisterWorried: ['{u-nye}? … {boh-bay}…', '{doo}? {u-nye} {way-loh}?'],
};

// The conversations of the two Furbies, which they have by infrared, as the real ones did. A line is the Furby that says it (0 is mine, 1 is Lillesøster’s) and what it says. `sing` makes both sing, and `kiss` sends a heart between them.
const conversations = [
	[[0, '{u-nye} {e-day}?'], [1, '{e-tah}! {kah} {e-day}!'], [0, 'Hee hee! {dah} {doo-ay}!']],
	[[0, '{wee-tee}?'], [1, '{wah}!'], ['sing']],
	[[0, 'Ah… ah… AH-CHOO!'], [1, '{boh-bay}! … Ah… AH-CHOO!'], [0, 'Hee hee! {koh-koh}!'], [1, 'AH-CHOO!'], [0, 'AH-CHOO!']],
	[[1, '{kah} {a-tay}!'], [0, '{kah} {mee-mee} {a-tay}!'], [1, '{ay-ay}! Waffle?'], [0, 'Hee hee!']],
	[[0, '{kah} {may-may} {u-nye}.'], [1, '{may-tah}?'], [0, '{e-tah}!'], ['kiss']],
	[[1, '{kah} {way-loh}…'], [0, '{boo}! {u-nye} {loo-lay} {doo}?'], [1, '{o-kay}! Hee hee!']],
	[[0, '{ay-ay}! Sindre!'], [1, 'Hee hee hee!'], [0, 'Hee hee hee hee!'], [1, '{dah} {doo-ay}!']],
];

// What Mamma shouts from the bedroom while the Furby wakes the house, with what it means.
const mammaLines = [
	['Sindre? Er det Furbyen?', 'Sindre? Is that the Furby?'],
	['SINDRE! Klokka er tre om natta!', 'SINDRE! It is three in the night!'],
	['Pappa skal på jobb klokka sju!', 'Pappa goes to work at seven!'],
	['Ta ut batteriene, Sindre!', 'Take out the batteries, Sindre!'],
	['Jeg skulle aldri stått i den køen.', 'I should never have stood in that queue.'],
	['SINDRE!!!', 'SINDRE!!!'],
];

const furs = {
	owl: {fur: '#a87d52', dark: '#5f4126', face: '#f1e2c6', belly: '#f3e6cf', inner: '#e9a3b8', iris: '#2f74d0', beak: '#f5a623', feet: '#e8901c'},
	snow: {fur: '#f2f1ea', dark: '#b9b8ad', face: '#ffffff', belly: '#ffffff', inner: '#f5b5c8', iris: '#2f9e5b', beak: '#f7b733', feet: '#ec9a24'},
	leopard: {fur: '#e5bb68', dark: '#7d5216', face: '#fff1cf', belly: '#fff2cc', inner: '#eea6ba', iris: '#7a4fc4', beak: '#f5a623', feet: '#e8901c', spots: '#5a3a12'},
	bat: {fur: '#34343e', dark: '#121218', face: '#8b8b98', belly: '#9a9aa8', inner: '#d982a3', iris: '#d84a3b', beak: '#f2b233', feet: '#e08a18'},
	wolf: {fur: '#9c9ca8', dark: '#55555f', face: '#e3e3ea', belly: '#e6e6ee', inner: '#eea6ba', iris: '#2a84c9', beak: '#f5a623', feet: '#e8901c'},
	sister: {fur: '#f6bfd8', dark: '#cf7fa7', face: '#ffffff', belly: '#ffffff', inner: '#ff8fbf', iris: '#3a9be0', beak: '#f7b733', feet: '#ec9a24'},
};

const defaultName = 'Tee-Loo';
const sisterName = 'Noo-Noo';

// A random number generator with a seed, so the fur of a Furby is the same on each frame.
const seededRandom = seed => () => {
	seed = (seed + 0x6D_2B_79_F5) | 0;
	let value = Math.imul(seed ^ (seed >>> 15), 1 | seed);
	value = (value + Math.imul(value ^ (value >>> 7), 61 | value)) ^ value;
	return ((value ^ (value >>> 14)) >>> 0) / 4_294_967_296;
};

const makeFur = seed => {
	const random = seededRandom(seed);
	const strands = Array.from({length: 240}, (_, index) => ({
		angle: (index / 240 * Math.PI * 2) + (random() * 0.03),
		length: 6 + (random() * 8),
		curl: (random() - 0.5) * 0.9,
		isDark: random() < 0.22,
	}));
	const texture = Array.from({length: 70}, () => {
		const angle = random() * Math.PI * 2;
		const distance = Math.sqrt(random()) * 0.85;
		return {x: Math.cos(angle) * distance * 92, y: Math.sin(angle) * distance * 100, angle: (random() - 0.5) * 1.2};
	}).filter(point => !(Math.abs(point.x) < 70 && point.y > -62 && point.y < 40));
	const spots = Array.from({length: 14}, () => {
		const angle = random() * Math.PI * 2;
		const distance = 0.55 + (random() * 0.35);
		return {x: Math.cos(angle) * distance * 92, y: Math.sin(angle) * distance * 100, size: 5 + (random() * 6)};
	});
	return {strands, texture, spots};
};

// A Furby on the canvas: where it stands, and how its face moves. The values ease toward their targets, so it moves like it has motors.
const makeCreature = ({seed, isSister, x, y, scale}) => ({
	isSister,
	fur: makeFur(seed),
	x,
	y,
	scale,
	lid: 0,
	mouth: 0,
	ear: 0,
	look: 0,
	lookTarget: 0,
	flip: 0,
	tilt: 0,
	isSleeping: false,
	isSick: false,
	talkUntil: 0,
	bubble: undefined,
	bubbleUntil: 0,
	isThought: false,
	nextBlink: 2,
	blinkUntil: 0,
	nextLook: 1,
	earTwitchUntil: 0,
	perkUntil: 0,
	contentUntil: 0,
	yuckUntil: 0,
	shakeUntil: 0,
	munchUntil: 0,
	food: undefined,
});

const canSpeak = 'speechSynthesis' in globalThis;

// Writes a phrase as the Furby says it: each Furbish word in English with a chance that grows as it learns. It returns the text, what it means, and the Furbish words that were heard.
const render = (parts, englishLevel) => {
	let text = '';
	let meaning = '';
	const heard = [];
	for (const part of parts) {
		if (typeof part === 'string') {
			text += part;
			meaning += part;
			continue;
		}

		const [furbish, inEnglish] = part;
		heard.push(furbish);
		text += Math.random() < englishLevel ? inEnglish : furbish;
		meaning += inEnglish;
	}

	// Each sentence starts with a capital letter.
	const capitalize = value => value.replaceAll(/(^|[.!?…] )(\p{Ll})/gu, (_, before, letter) => before + letter.toUpperCase());
	return {text: capitalize(text.trim()), meaning: capitalize(meaning.trim()), heard};
};

const clockText = minutes => {
	const hours = Math.floor(minutes / 60) % 24;
	return `${String(hours).padStart(2, '0')}:${String(Math.floor(minutes % 60)).padStart(2, '0')}`;
};

// “Blinke, blinke, lille stjerne”, the Norwegian Twinkle, Twinkle, Little Star, which the Furby dances to.
const song = [[0, 1], [0, 1], [7, 1], [7, 1], [9, 1], [9, 1], [7, 2], [5, 1], [5, 1], [4, 1], [4, 1], [2, 1], [2, 1], [0, 2], [7, 1], [7, 1], [5, 1], [5, 1], [4, 1], [4, 1], [2, 2], [7, 1], [7, 1], [5, 1], [5, 1], [4, 1], [4, 1], [2, 2]];

// The bottom of the Furby, turned over on the desk, with the battery hatch and its tiny screw.
const screw = {x: 240, y: 104};
const batteryRectangle = index => ({x: 176 + (index * 34), y: 126, width: 28, height: 100});

const localPoint = (creature, point) => {
	let x = (point.x - creature.x) / creature.scale;
	let y = (point.y - creature.y) / creature.scale;
	if (creature.flip > 0.5) {
		x = -x;
		y = -y;
	}

	return {x, y};
};

const keyActions = {f: 'feed', t: 'tickle', p: 'pet', u: 'flip', s: 'shake', c: 'clap', l: 'light', m: 'music'};

export default class extends GeoCitiesElement {
	#context;
	#furby;
	#hoursAway = 0;
	#mine;
	#sister;
	#hasSister = false;
	#isDark = false;
	#isUpsideDown = false;
	#upsideDownSince = 0;
	#isMusicPlaying = false;
	#otherMusic = new Set();
	#isSoundOn = false;
	#isNsa = false;
	#night;
	#puzzle;
	#mammaBubble;
	#mammaUntil = 0;
	#irUntil = 0;
	#lastInteraction = 0;
	#nextIdle = 0;
	#feedTimes = [];
	#tickleTimes = [];
	#shakeTimes = [];
	#chatId = 0;
	#hasGreeted = false;
	#particles = [];
	#noiseBuffer;
	#musicGain;
	#musicTimer;
	#lastLcd = '';
	#saveTimer = 0;
	#snoreTimer = 0;
	#lcdTimer = 0;
	#drag;

	connected() {
		const {canvas, name, fur} = this.parts;
		this.#context = canvas.getContext('2d');
		const saved = this.stored('state', {});

		// What the Furby is and has learned, which is kept between visits. Hunger, energy, and happiness go from 0 to 100.
		this.#furby = {
			name: typeof saved.name === 'string' && saved.name.trim() ? saved.name.trim().slice(0, 16) : defaultName,
			fur: Object.hasOwn(furs, saved.fur) && saved.fur !== 'sister' ? saved.fur : 'owl',
			born: Number.isFinite(saved.born) ? saved.born : Date.now(),
			points: Number.isFinite(saved.points) ? saved.points : 0,
			heard: new Set(Array.isArray(saved.heard) ? saved.heard.filter(item => Object.hasOwn(dictionary, item)) : []),
			hunger: clamp(Number(saved.hunger ?? 35) || 0, 0, 100),
			energy: clamp(Number(saved.energy ?? 80) || 0, 0, 100),
			happiness: clamp(Number(saved.happiness ?? 60) || 0, 0, 100),
			isSick: saved.isSick === true,
			hasBatteries: saved.hasBatteries !== false,
			milestone: Number.isFinite(saved.milestone) ? saved.milestone : 0,
			lastSeen: Number.isFinite(saved.lastSeen) ? saved.lastSeen : Date.now(),
		};

		const furby = this.#furby;

		// The time away makes it hungry, like a Furby left alone on a shelf, but not sick.
		this.#hoursAway = (Date.now() - furby.lastSeen) / 3_600_000;
		if (furby.hasBatteries && this.#hoursAway > 0.5) {
			furby.hunger = clamp(furby.hunger + Math.min(this.#hoursAway * 8, 60), 0, 99);
			furby.happiness = clamp(furby.happiness - Math.min(this.#hoursAway * 4, 30), 0, 100);
		}

		this.#mine = makeCreature({seed: 1998, isSister: false, x: 190, y: 212, scale: 0.9});
		this.#sister = makeCreature({seed: 1225, isSister: true, x: 560, y: 240, scale: 0.66});
		this.#lastInteraction = now();
		this.#nextIdle = now() + 15;

		this.loop(seconds => {
			const time = now();
			const mine = this.#mine;
			this.#updateNeeds(seconds);
			this.#updateNight(seconds);
			this.#updatePose(mine, seconds, time);
			this.#updatePose(this.#sister, seconds, time);
			if (this.#isDancing && this.#isMotion && Math.random() < seconds * 1.5 && furby.hasBatteries && !mine.isSleeping) {
				this.#addParticle('note', mine.x + ((Math.random() - 0.5) * 120 * mine.scale), mine.y - (100 * mine.scale));
			}

			this.#drawScene(time);
		});

		// One tune plays at a time on the page, and a tune of another toy stops the song (`musicStopped()`). The Furby also hears the music of the other toys, and dances to it.
		this.on(document, 'geocities-music', event => {
			const {isPlaying, source} = event.detail ?? {};
			if (source === this.localName) {
				return;
			}

			if (isPlaying) {
				const isNew = !this.#otherMusic.has(source);
				this.#otherMusic.add(source);
				if (isNew && this.isVisible && furby.hasBatteries && !this.#mine.isSleeping && !this.#isAlarm) {
					this.#talk(this.#mine, randomItem(phrases.dancing), {note: 'It hears music on the page, and dances.'});
				}
			} else {
				this.#otherMusic.delete(source);
			}
		});

		// The canvas: a press on the tongue feeds it, on the tummy tickles it, and on the eyes covers its light sensor. A stroke pets it, and fast strokes from side to side shake it.
		this.on(canvas, 'pointerdown', event => {
			this.#pointerDown(event);
		});

		this.on(canvas, 'pointermove', event => {
			this.#pointerMove(event);
		});

		// A finger on the Furby, or on its open battery hatch, strokes it instead of scrolling the page. Anywhere else on the canvas, it scrolls the page.
		this.on(canvas, 'touchstart', event => {
			if (this.#puzzle || this.#hitTest(canvasPoint(canvas, event.changedTouches[0]))) {
				event.preventDefault();
			}
		}, {passive: false});

		this.on(canvas, 'pointerup', event => {
			this.#endDrag(event);
		});

		this.on(canvas, 'pointercancel', event => {
			this.#endDrag(event);
		});

		this.on(canvas, 'keydown', event => {
			this.#keyDown(event);
		});

		// Each button is the part with the name of its action, like `parts.feed`.
		const {feed, tickle, pet, flip, shake, clap, light, medicine, music, sister, chat, bed, batteries, nsa, sound} = this.parts;

		for (const button of [feed, tickle, pet, flip, shake, clap, light, medicine, music, sister, chat, bed, batteries, nsa, sound]) {
			this.on(button, 'click', () => {
				this.#runAction(button.dataset.part);
			});
		}

		name.value = furby.name === defaultName ? '' : furby.name;
		fur.value = furby.fur;

		this.on(name, 'input', () => {
			furby.name = name.value.trim().slice(0, 16) || defaultName;
			this.#persist();
			this.#updateLcd();
		});

		this.on(name, 'change', () => {
			if (furby.hasBatteries && !this.#mine.isSleeping) {
				this.#talk(this.#mine, phrases.name(furby.name), {note: 'It likes its name.'});
				this.#interact(1);
			}
		});

		this.on(fur, 'change', () => {
			if (Object.hasOwn(furs, fur.value) && fur.value !== 'sister') {
				furby.fur = fur.value;
				this.#persist();
				if (furby.hasBatteries && !this.#mine.isSleeping) {
					this.#talk(this.#mine, 'Hee hee! {e-day}!', {note: 'It likes its new fur.'});
				}
			}
		});

		this.#mine.isSick = furby.isSick;
		this.#updateButtons();
		this.#updateDictionary();
		this.#updateLcd();
		this.#drawScene(now());
	}

	disconnected() {
		this.#stopMusic();
	}

	// The Furby lives only while its canvas is on screen, not while only its buttons or its dictionary are.
	get visibilityTarget() {
		return this.parts.canvas;
	}

	visibilityChanged(isVisible) {
		const furby = this.#furby;
		if (isVisible && !this.#hasGreeted) {
			this.#hasGreeted = true;
			const hoursAway = this.#hoursAway;
			if (!furby.hasBatteries) {
				this.say(`${furby.name} still has no batteries. Put them back, if you dare.`);
			} else if (hoursAway > 0.5 && furby.hunger > 50) {
				this.#talk(this.#mine, phrases.hungry[0], {note: `You were away for ${hoursAway >= 48 ? `${Math.floor(hoursAway / 24)} days` : `${Math.max(1, Math.round(hoursAway))} hours`}. It missed you, and it is hungry.`});
			} else {
				this.#talk(this.#mine, phrases.hello[0], {note: `Hi! I am ${furby.name}. Tickle my tummy!${this.#isSoundOn ? '' : ' Press “Sound: Off” to hear me squeak.'}`});
			}
		}

		// The song stops when the visitor scrolls away or hides the tab, as its timer would run on unseen.
		if (!isVisible) {
			this.#stopMusic();
			this.#persist();
		}
	}

	musicStopped() {
		this.#stopMusic();
	}

	#persist() {
		this.#furby.lastSeen = Date.now();
		this.store('state', {...this.#furby, heard: [...this.#furby.heard]});
	}

	get #english() {
		return clamp(this.#furby.points / 400, 0, 1);
	}

	get #isDancing() {
		return this.#isMusicPlaying || this.#otherMusic.size > 0;
	}

	get #isAlarm() {
		return this.#night?.phase === 'alarm';
	}

	get #isMotion() {
		return !this.reducedMotion;
	}

	// The sound, made in the browser, once the visitor clicked something that makes sound. The effects play only while the sound is on, and the music only when the visitor plays it.
	#startAudio() {
		const sound = this.sound();
		sound?.context.resume();
		return sound;
	}

	get #runningAudio() {
		const sound = this.sound();
		return sound?.context.state === 'running' ? sound : undefined;
	}

	#beep(frequency, duration = 0.1, {type = 'square', volume = 0.05, when = 0, slideTo, destination} = {}) {
		const sound = this.#runningAudio;
		if (!sound) {
			return;
		}

		const {context, output} = sound;
		const start = context.currentTime + when;
		const oscillator = new OscillatorNode(context, {type, frequency});
		if (slideTo) {
			oscillator.frequency.exponentialRampToValueAtTime(slideTo, start + duration);
		}

		const gain = new GainNode(context, {gain: 0});
		gain.gain.setValueAtTime(0, start);
		gain.gain.linearRampToValueAtTime(volume, start + 0.01);
		gain.gain.exponentialRampToValueAtTime(0.0001, start + duration);
		oscillator.connect(gain).connect(destination ?? output);
		oscillator.start(start);
		oscillator.stop(start + duration + 0.02);
	}

	#noise(duration, {volume = 0.1, frequency = 1000, type = 'bandpass', when = 0} = {}) {
		const sound = this.#runningAudio;
		if (!sound) {
			return;
		}

		const {context, output} = sound;
		if (!this.#noiseBuffer) {
			this.#noiseBuffer = new AudioBuffer({length: context.sampleRate, sampleRate: context.sampleRate});
			const data = this.#noiseBuffer.getChannelData(0);
			for (let index = 0; index < data.length; index++) {
				data[index] = (Math.random() * 2) - 1;
			}
		}

		const start = context.currentTime + when;
		const source = new AudioBufferSourceNode(context, {buffer: this.#noiseBuffer});
		const filter = new BiquadFilterNode(context, {type, frequency});
		const gain = new GainNode(context, {gain: volume});
		gain.gain.setValueAtTime(volume, start);
		gain.gain.exponentialRampToValueAtTime(0.0001, start + duration);
		source.connect(filter).connect(gain).connect(output);
		source.start(start);
		source.stop(start + duration + 0.02);
	}

	// The sound effects of the Furby. The motor whirr is the grinding of the one motor inside, which moved everything.
	#effects = {
		whirr: () => {
			if (this.#isSoundOn) {
				this.#beep(70, 0.28, {type: 'sawtooth', volume: 0.03, slideTo: 110});
			}
		},
		giggle: () => {
			if (this.#isSoundOn) {
				for (let index = 0; index < 5; index++) {
					this.#beep(900 + (index * 140), 0.07, {type: 'triangle', volume: 0.05, when: index * 0.08});
				}
			}
		},
		purr: () => {
			if (this.#isSoundOn) {
				for (let index = 0; index < 6; index++) {
					this.#beep(55, 0.12, {type: 'sawtooth', volume: 0.04, when: index * 0.16});
				}
			}
		},
		munch: () => {
			if (this.#isSoundOn) {
				for (let index = 0; index < 3; index++) {
					this.#noise(0.06, {volume: 0.15, frequency: 2500, when: 0.3 + (index * 0.14)});
				}
			}
		},
		burp: () => {
			if (this.#isSoundOn) {
				this.#beep(130, 0.45, {type: 'sawtooth', volume: 0.08, slideTo: 60});
			}
		},
		sneeze: () => {
			if (this.#isSoundOn) {
				this.#beep(500, 0.4, {type: 'sine', volume: 0.04, slideTo: 900});
				this.#noise(0.3, {volume: 0.3, frequency: 3000, type: 'highpass', when: 0.4});
			}
		},
		yuck: () => {
			if (this.#isSoundOn) {
				this.#beep(320, 0.3, {type: 'square', volume: 0.04, slideTo: 180});
			}
		},
		clap: () => {
			this.#noise(0.08, {volume: 0.4, frequency: 1500});
		},
		snore: () => {
			if (this.#isSoundOn) {
				this.#noise(1.2, {volume: 0.06, frequency: 280, type: 'lowpass'});
			}
		},
		squeak: () => {
			if (this.#isSoundOn) {
				this.#beep(2400, 0.04, {type: 'triangle', volume: 0.03});
			}
		},
		clunk: () => {
			if (this.#isSoundOn) {
				this.#noise(0.08, {volume: 0.3, frequency: 400, type: 'lowpass'});
			}
		},
	};

	// The voice of a Furby: the computer voice, as high as it goes. Lillesøster’s Furby talks faster.
	#speak(text, creature, {isLoud = false} = {}) {
		if (!this.#isSoundOn || !canSpeak) {
			return;
		}

		const words = text.replaceAll('-', ' ').replaceAll(/[^\p{L}\s.,!?']/gu, ' ').trim();
		if (!words) {
			return;
		}

		speechSynthesis.cancel();
		const utterance = new SpeechSynthesisUtterance(words);
		utterance.lang = 'en-US';
		utterance.pitch = 2;
		utterance.rate = creature.isSister ? 1.35 : (isLoud ? 1.3 : 1.15);
		utterance.volume = 1;
		speechSynthesis.speak(utterance);
		this.#beep(1700, 0.05, {type: 'sine', volume: 0.03});
	}

	#nameOf(creature) {
		return creature.isSister ? `Lillesøster’s ${sisterName}` : this.#furby.name;
	}

	// The Furby says something: in a speech bubble, in the status line, in its voice, and in the dictionary.
	#talk(creature, parts, {note = '', isLoud = false, seconds} = {}) {
		if (typeof parts === 'string') {
			parts = phrase(parts);
		}

		const {text, meaning, heard} = render(parts, creature.isSister ? 0.05 : this.#english);
		const shown = isLoud ? text.toUpperCase() : text;
		const duration = seconds ?? clamp(1.6 + (text.length * 0.06), 2, 5);
		creature.bubble = shown;
		creature.isThought = false;
		// For reduced motion, a bubble stays until the next one, so the canvas does not change by itself.
		creature.bubbleUntil = this.#isMotion ? now() + duration : Infinity;
		creature.talkUntil = now() + Math.min(duration - 0.4, 0.6 + (text.length * 0.05));
		this.#effects.whirr();
		this.#speak(text, creature, {isLoud});

		let isNewWord = false;
		for (const furbish of heard) {
			if (!this.#furby.heard.has(furbish)) {
				this.#furby.heard.add(furbish);
				isNewWord = true;
			}
		}

		if (isNewWord) {
			this.#updateDictionary();
		}

		const translation = meaning === text ? '' : ` (${meaning})`;
		this.say(`${this.#nameOf(creature)}: “${shown}”${translation}${note ? ` ${note}` : ''}`);

		if (this.#isNsa && !creature.isSister) {
			this.#logNsa(`Agent ${this.#furby.name} said “${text}”. The NSA thinks it means “${meaning}”. Recorded: 0 seconds.`);
		}
	}

	// A small gray thought, for a Furby without batteries, which says nothing.
	#think(creature, text) {
		creature.bubble = text;
		creature.isThought = true;
		creature.bubbleUntil = this.#isMotion ? now() + 2.5 : Infinity;
	}

	// Playing teaches it English, like the real one, which spoke more English the longer it was played with.
	#addPoints(points) {
		const furby = this.#furby;
		const before = this.#english;
		furby.points += points;
		const after = this.#english;
		if (furby.milestone < 1 && after >= 0.25) {
			furby.milestone = 1;
			this.toast(`${furby.name} said its first words in English! Mamma says it is smarter than Sindre.`);
		} else if (furby.milestone < 2 && after >= 0.5) {
			furby.milestone = 2;
			this.toast(`${furby.name} speaks half English now. Lillesøster cannot understand it any more.`);
		} else if (furby.milestone < 3 && after >= 1) {
			furby.milestone = 3;
			this.toast(`${furby.name} speaks English! It still says “a-tay” when it is hungry, though.`);
			this.celebrate();
		}

		if (Math.floor(before * 100) !== Math.floor(after * 100)) {
			this.#updateLcd();
		}
	}

	#interact(points = 1) {
		this.#lastInteraction = now();
		this.#nextIdle = this.#lastInteraction + 15 + (Math.random() * 10);
		this.#addPoints(points);
	}

	// A heart, a note, or a star that floats up from a point. For reduced motion, it stays where it starts.
	#addParticle(kind, x, y) {
		this.#particles.push({kind, x, y, startX: x, startY: y, start: now(), velocityX: (Math.random() - 0.5) * 30, life: 1.6});
	}

	#wake(creature) {
		if (creature.isSleeping) {
			creature.isSleeping = false;
			creature.perkUntil = now() + 1;
			this.#effects.whirr();
		}
	}

	#fallAsleep(creature) {
		creature.isSleeping = true;
		creature.talkUntil = 0;
		// For reduced motion, a bubble stays until the next one, so it goes away here, or it would stay over the sleeping Furby all night.
		if (!this.#isMotion) {
			creature.bubble = undefined;
		}
	}

	// Without batteries, the Furby does nothing at all, however much it is poked.
	#checkBatteries() {
		if (this.#furby.hasBatteries) {
			return true;
		}

		this.#think(this.#mine, '(me sleep)');
		this.say(`${this.#furby.name} has no batteries. It says nothing. It thinks “me sleep”.`);
		return false;
	}

	#setUpsideDown(isOn) {
		this.#isUpsideDown = isOn;
		this.#upsideDownSince = now();
		const {flip} = this.parts;
		setPressed(flip, isOn);
		flip.textContent = isOn ? 'Turn It Right Side Up' : 'Turn It Upside Down';
	}

	// While it wakes the house at night, everything the visitor tries only makes it louder.
	#louder() {
		this.#night.attempts++;

		// Lillesøster’s Furby goes first, so the status line ends with the hint.
		if (this.#hasSister) {
			this.#talk(this.#sister, randomItem(phrases.louder), {isLoud: true});
		}

		this.#talk(this.#mine, randomItem(phrases.louder), {isLoud: true, note: this.#night.attempts >= 2 ? 'Nothing stops it. Only Pappa’s tiny screwdriver can help now: take out the batteries!' : 'That made it louder.'});
		this.#mine.perkUntil = now() + 1;
	}

	#actions = {
		feed: () => {
			const furby = this.#furby;
			const mine = this.#mine;
			this.#wake(mine);
			if (this.#isAlarm) {
				mine.food = {kind: 'waffle', start: now()};
				this.#louder();
				return;
			}

			if (mine.isSick) {
				this.#talk(mine, randomItem(phrases.refuses), {note: 'It is sick and will not eat. Give it a spoon of tran.'});
				return;
			}

			const time = now();
			this.#feedTimes = [...this.#feedTimes.filter(feedTime => time - feedTime < 30), time];
			mine.food = {kind: 'waffle', start: time};
			mine.munchUntil = time + 1.1;
			this.#effects.munch();

			if (furby.hunger < 12) {
				const overfed = this.#feedTimes.length;
				if (overfed >= 4) {
					mine.isSick = true;
					furby.isSick = true;
					furby.happiness = clamp(furby.happiness - 15, 0, 100);
					this.#effects.burp();
					this.#talk(mine, randomItem(phrases.sick), {note: 'Too many waffles! Now it is sick.'});
				} else if (overfed >= 3) {
					this.#effects.burp();
					this.#talk(mine, 'BURP! Hee hee!', {note: 'It burped. One more waffle is a bad idea.'});
				} else {
					this.#talk(mine, randomItem(phrases.full), {note: 'It is full.'});
				}

				this.#interact(1);
				return;
			}

			furby.hunger = clamp(furby.hunger - 30, 0, 100);
			furby.happiness = clamp(furby.happiness + 5, 0, 100);
			this.#talk(mine, randomItem(phrases.fed), {note: 'It eats a heart of a waffle with brown cheese.'});
			this.#interact(2);
		},
		tickle: () => {
			const furby = this.#furby;
			const mine = this.#mine;
			const wasSleeping = mine.isSleeping;
			this.#wake(mine);
			if (this.#isAlarm) {
				this.#louder();
				return;
			}

			const time = now();
			this.#tickleTimes = [...this.#tickleTimes.filter(tickleTime => time - tickleTime < 10), time];
			mine.perkUntil = time + 1.2;
			mine.contentUntil = time + 1.2;
			this.#effects.giggle();
			if (this.#tickleTimes.length >= 5) {
				furby.happiness = clamp(furby.happiness - 4, 0, 100);
				this.#talk(mine, randomItem(phrases.tickledTooMuch), {note: 'Too much tickling.'});
			} else {
				furby.happiness = clamp(furby.happiness + 6, 0, 100);
				this.#talk(mine, randomItem(phrases.tickled), {note: wasSleeping ? 'It woke up giggling.' : ''});
			}

			if (this.#hasSister && !this.#sister.isSleeping) {
				setTimeout(() => {
					if (this.#hasSister && !this.#sister.isSleeping && furby.hasBatteries) {
						this.#talk(this.#sister, 'Hee hee hee!', {note: 'Giggles are catching.'});
					}
				}, 900);
			}

			this.#interact(2);
		},
		pet: () => {
			const furby = this.#furby;
			const mine = this.#mine;
			if (this.#isAlarm) {
				this.#louder();
				return;
			}

			if (mine.isSleeping) {
				this.#think(mine, 'Mmm… zzz…');
				this.say(`${furby.name} purrs in its sleep.`);
				this.#effects.purr();
				this.#interact(1);
				return;
			}

			const time = now();
			mine.contentUntil = time + 1.6;
			this.#effects.purr();
			this.#addParticle('heart', mine.x + (40 * mine.scale), mine.y - (90 * mine.scale));
			furby.happiness = clamp(furby.happiness + 8, 0, 100);
			if (this.#isDark) {
				this.#talk(mine, randomItem(phrases.hugged), {note: 'A hug in the dark. It falls asleep.'});
				setTimeout(() => {
					if (this.#isDark && !this.#isAlarm && furby.hasBatteries) {
						this.#fallAsleep(mine);
						this.#fallAsleep(this.#sister);
					}
				}, 2500);
			} else {
				this.#talk(mine, randomItem(phrases.petted));
			}

			this.#interact(2);
		},
		flip: () => {
			this.#setUpsideDown(!this.#isUpsideDown);
			this.#effects.whirr();
			if (!this.#furby.hasBatteries) {
				this.say(this.#isUpsideDown ? 'It is upside down. It does not care. It has no batteries.' : 'It is right side up again.');
				return;
			}

			this.#wake(this.#mine);
			if (this.#isAlarm) {
				this.#louder();
				return;
			}

			this.#mine.perkUntil = now() + 1.5;
			this.#talk(this.#mine, randomItem(this.#isUpsideDown ? phrases.upsideDown : phrases.rightSideUp));
			this.#interact(1);
		},
		shake: () => {
			const furby = this.#furby;
			const mine = this.#mine;
			const time = now();
			mine.shakeUntil = time + 0.8;
			this.#effects.whirr();
			if (!furby.hasBatteries) {
				this.say('Something rattles inside. No batteries, though.');
				return;
			}

			this.#wake(mine);
			if (this.#isAlarm) {
				this.#louder();
				return;
			}

			this.#shakeTimes = [...this.#shakeTimes.filter(shakeTime => time - shakeTime < 10), time];
			if (this.#shakeTimes.length >= 3) {
				furby.happiness = clamp(furby.happiness - 5, 0, 100);
				this.#talk(mine, randomItem(phrases.dizzy), {note: 'Its eyes go round and round.'});
				this.#addParticle('star', mine.x, mine.y - (110 * mine.scale));
			} else {
				this.#talk(mine, randomItem(phrases.shaken));
			}

			this.#interact(1);
		},
		clap: () => {
			const mine = this.#mine;
			const sister = this.#sister;

			// The audio can still be waking up after the click.
			this.#startAudio()?.context.resume().then(() => {
				this.#effects.clap();
			}, () => {});

			if (!this.#furby.hasBatteries) {
				this.say('Clap! Nothing. It has no batteries.');
				return;
			}

			mine.perkUntil = now() + 1.2;
			sister.perkUntil = now() + 1.2;
			if (this.#night?.phase === 'asleep') {
				this.#startAlarm('The clap woke it. Now it will never sleep again.');
				return;
			}

			if (this.#isAlarm) {
				this.#louder();
				return;
			}

			const wasSleeping = mine.isSleeping;
			this.#wake(mine);
			this.#wake(sister);
			this.#talk(mine, randomItem(wasSleeping ? phrases.woken : phrases.clapped), {note: wasSleeping ? 'The clap woke it up.' : 'Its ears go up.'});
			this.#interact(1);
		},
		light: () => {
			const mine = this.#mine;
			this.#isDark = !this.#isDark;
			this.#updateButtons();
			if (!this.#furby.hasBatteries) {
				this.say(this.#isDark ? 'The light is off. Silence.' : 'The light is on.');
				return;
			}

			if (this.#night?.phase === 'asleep' && !this.#isDark) {
				this.#startAlarm('The light woke it. It thinks it is morning.');
				return;
			}

			if (this.#isAlarm) {
				this.#louder();
				return;
			}

			if (this.#isDark) {
				if (mine.isSleeping) {
					this.say('The light is off. It sleeps on.');
					return;
				}

				// The worst time to say it is hungry is right after the light goes off.
				if (this.#furby.hunger > 65) {
					this.#talk(mine, randomItem(phrases.hungry), {note: 'It will not sleep hungry. Of course it says so now.'});
				} else {
					this.#talk(mine, randomItem(phrases.dark), {note: 'Its light sensor says it is night. Pet it to give it a hug.'});
				}
			} else {
				const wasSleeping = mine.isSleeping;
				this.#wake(mine);
				this.#wake(this.#sister);
				this.#talk(mine, randomItem(phrases.lightOn), {note: wasSleeping ? 'The light woke it up.' : ''});
			}

			this.#interact(1);
		},
		medicine: () => {
			const furby = this.#furby;
			const mine = this.#mine;
			mine.food = {kind: 'tran', start: now()};
			if (!this.#checkBatteries()) {
				return;
			}

			this.#wake(mine);
			if (this.#isAlarm) {
				this.#louder();
				return;
			}

			mine.yuckUntil = now() + 1.5;
			this.#effects.yuck();
			if (mine.isSick) {
				mine.isSick = false;
				this.#sister.isSick = false;
				furby.isSick = false;
				furby.hunger = Math.min(furby.hunger, 70);
				furby.happiness = clamp(furby.happiness + 10, 0, 100);
				this.#talk(mine, randomItem(phrases.medicine), {note: 'Tran fixes everything, says Mormor.'});
				this.#interact(3);
			} else {
				furby.happiness = clamp(furby.happiness - 3, 0, 100);
				this.#talk(mine, randomItem(phrases.noMedicine), {note: 'Tran is for when it is sick.'});
				this.#interact(1);
			}
		},
		music: () => {
			if (this.#isMusicPlaying) {
				this.#stopMusic();
				this.say('The music stops.');
				return;
			}

			this.#startMusic();
			if (!this.#isMusicPlaying) {
				this.say('This computer has no sound card. Pappa says it is coming for Christmas.');
				return;
			}

			if (!this.#furby.hasBatteries) {
				this.say('The music plays. The Furby has no batteries, so it does not dance.');
				return;
			}

			this.#wake(this.#mine);
			this.#wake(this.#sister);
			if (this.#isAlarm) {
				this.#louder();
				return;
			}

			// The worst time to say it is hungry is when the music starts.
			if (this.#furby.hunger > 65) {
				this.#talk(this.#mine, randomItem(phrases.hungry), {note: 'It is too hungry to dance. It says so right as the song starts.'});
			} else {
				this.#talk(this.#mine, randomItem(phrases.dancing), {note: 'It dances!'});
			}

			this.#interact(2);
		},
		sister: () => {
			this.#hasSister = !this.#hasSister;
			this.#chatId++;
			this.#updateButtons();
			if (this.#hasSister) {
				this.#sister.isSleeping = this.#isDark && this.#mine.isSleeping;
				this.#sister.isSick = this.#mine.isSick;
				setTimeout(() => {
					if (this.#hasSister) {
						this.#talk(this.#sister, 'Hee hee! {kah} {may-may}!', {note: 'Lillesøster lent you her pink Furby. Do not lose it.'});
						if (this.#furby.hasBatteries && !this.#mine.isSleeping) {
							setTimeout(() => {
								this.#chat();
							}, 2500);
						}
					}
				}, 400);
			} else {
				this.say(`Lillesøster wants ${sisterName} back. She takes it to her room.`);
			}
		},
		chat: () => {
			this.#chat();
		},
		bed: () => {
			// Nothing but the batteries stops the party at 3 in the morning, not even skipping to the morning.
			if (this.#isAlarm) {
				this.#louder();
				return;
			}

			if (this.#night) {
				this.#endNight('You skip to the morning.');
				return;
			}

			if (!this.#checkBatteries()) {
				return;
			}

			this.#stopMusic();
			this.#isDark = true;
			this.#night = {minutes: 22 * 60, phase: 'asleep', attempts: 0, nextLine: 0, mammaIndex: 0};
			this.#updateButtons();
			this.#wake(this.#mine);
			if (this.#furby.hunger > 65) {
				this.#talk(this.#mine, randomItem(phrases.hungry), {note: 'It is 22:00, bedtime. It is hungry right now, of course. Then it falls asleep anyway.'});
			} else {
				this.#talk(this.#mine, randomItem(phrases.night), {note: 'It is 22:00, bedtime. Good night!'});
			}

			setTimeout(() => {
				if (this.#night?.phase === 'asleep') {
					this.#fallAsleep(this.#mine);
					this.#fallAsleep(this.#sister);
				}
			}, 2500);
			this.#interact(1);
		},
		batteries: () => {
			if (this.#puzzle) {
				this.#puzzle = undefined;
				this.#updateButtons();
				this.say('You close the battery hatch again.');
				return;
			}

			if (!this.#furby.hasBatteries) {
				this.#putBatteriesBack();
				return;
			}

			this.#puzzle = {step: 'screw', turned: 0, tightened: 0, batteries: [true, true, true, true], hasWarned: false};
			this.#updateButtons();
			this.say('You turn it over. The batteries are under a hatch with a tiny screw. Turn the screw to the left: drag around it in circles, or press the left arrow key.');
			this.parts.canvas.focus({preventScroll: true});
		},
		nsa: () => {
			const furby = this.#furby;
			this.#isNsa = !this.#isNsa;
			this.#updateButtons();
			this.parts.nsaBox.hidden = !this.#isNsa;
			if (this.#isNsa) {
				this.toast('In January 1999, the NSA banned Furbies from its offices, as it was afraid that they could record secrets. They could not. They could not even record “hello”.');
				this.#logNsa(`Agent ${furby.name} reports for duty from Bergen, Norway. Microphone: none. Memory for recordings: none.`);
				if (furby.hasBatteries && !this.#mine.isSleeping) {
					this.#talk(this.#mine, randomItem(phrases.nsa), {note: 'It puts on sunglasses. It looks very secret.'});
				}
			} else {
				this.say(`${furby.name} takes off the sunglasses. The NSA learned nothing.`);
			}
		},
		sound: () => {
			this.#isSoundOn = !this.#isSoundOn;
			if (this.#isSoundOn) {
				this.#startAudio();
			} else if (canSpeak) {
				speechSynthesis.cancel();
			}

			this.#updateButtons();
			this.say(this.#isSoundOn ? `Sound on. ${this.#furby.name} talks with its squeaky voice now.` : 'Sound off.');
			if (this.#isSoundOn && this.#furby.hasBatteries && !this.#mine.isSleeping) {
				this.#talk(this.#mine, randomItem(phrases.hello));
			}
		},
	};

	#logNsa(text) {
		const {nsaLog} = this.parts;
		const item = document.createElement('li');
		const time = new Date().toLocaleTimeString('en-GB', {hour: '2-digit', minute: '2-digit'});
		item.textContent = `${time}: ${text}`;
		nsaLog.append(item);
		while (nsaLog.children.length > 6) {
			nsaLog.firstElementChild.remove();
		}
	}

	// The two Furbies talk by infrared, line by line. A new conversation, or Lillesøster taking hers back, ends the old one.
	async #chat() {
		const mine = this.#mine;
		const sister = this.#sister;
		if (!this.#hasSister) {
			return;
		}

		if (!this.#furby.hasBatteries) {
			this.#talk(sister, randomItem(phrases.sisterWorried), {note: `${sisterName} pokes ${this.#furby.name}, but it has no batteries.`});
			return;
		}

		if (mine.isSleeping || sister.isSleeping) {
			this.say('They are asleep. Wake them first.');
			return;
		}

		this.#chatId++;
		const id = this.#chatId;
		const conversation = mine.isSick ? conversations[2] : randomItem(conversations);
		for (const line of conversation) {
			if (id !== this.#chatId || !this.#hasSister || !this.#furby.hasBatteries || mine.isSleeping || this.#isAlarm || this.#puzzle || !this.isVisible) {
				return;
			}

			this.#irUntil = now() + 2;
			if (line[0] === 'sing') {
				for (const creature of [mine, sister]) {
					this.#talk(creature, '♪ {wee-tee} {wee-tee}! La la la! ♪', {note: 'They sing together.'});
					this.#addParticle('note', creature.x, creature.y - (100 * creature.scale));
				}

				this.#jingle();
			} else if (line[0] === 'kiss') {
				this.#addParticle('heart', (mine.x + sister.x) / 2, mine.y - 60);
				this.say('A kiss! Lillesøster says “Æsj!”');
			} else {
				const creature = line[0] === 0 ? mine : sister;
				if (line[1].includes('CHOO')) {
					this.#effects.sneeze();
					creature.shakeUntil = now() + 0.4;
				}

				this.#talk(creature, line[1]);
			}

			await this.wait(2300);
		}

		if (id === this.#chatId && this.#hasSister) {
			this.#interact(2);
		}
	}

	// A short tune of both Furbies singing, in harmony.
	#jingle() {
		if (!this.#isSoundOn) {
			return;
		}

		for (const [index, note] of [523, 587, 659, 784, 659, 784].entries()) {
			this.#beep(note, 0.18, {type: 'triangle', volume: 0.04, when: index * 0.2});
			this.#beep(note * 1.25, 0.18, {type: 'triangle', volume: 0.03, when: index * 0.2});
		}
	}

	// The song plays into its own gain, so a song of an earlier Play stops with its gain.
	#playSong(gain) {
		if (!this.#isMusicPlaying || gain !== this.#musicGain || !this.#runningAudio) {
			return;
		}

		let when = 0.05;
		for (const [semitone, beats] of song) {
			const frequency = 523.25 * (2 ** (semitone / 12));
			this.#beep(frequency, (beats * 0.3) - 0.04, {type: 'square', volume: 0.05, when, destination: gain});
			if (this.#hasSister) {
				this.#beep(frequency * 1.26, (beats * 0.3) - 0.04, {type: 'triangle', volume: 0.03, when, destination: gain});
			}

			when += beats * 0.3;
		}

		this.#musicTimer = setTimeout(() => {
			this.#playSong(gain);
		}, when * 1000);
	}

	#startMusic() {
		const sound = this.#startAudio();
		if (!sound) {
			return;
		}

		this.#isMusicPlaying = true;
		this.#musicGain = new GainNode(sound.context, {gain: 1});
		this.#musicGain.connect(sound.output);
		this.#updateButtons();
		this.music(true);

		// The audio can still be waking up after the click.
		const gain = this.#musicGain;
		sound.context.resume().then(() => {
			this.#playSong(gain);
		}, () => {});
	}

	#stopMusic() {
		if (!this.#isMusicPlaying) {
			return;
		}

		this.#isMusicPlaying = false;
		clearTimeout(this.#musicTimer);
		this.#musicGain?.disconnect();
		this.#musicGain = undefined;
		this.#updateButtons();
		this.music(false);
	}

	// At 3 in the morning, the Furby wakes up, as the real ones did, and wakes the whole house.
	#startAlarm(note) {
		const night = this.#night;
		night.phase = 'alarm';
		night.minutes = Math.max(night.minutes, 27 * 60);
		night.nextLine = now() + 2.4;
		this.#wake(this.#mine);
		this.#wake(this.#sister);
		this.#updateButtons();
		this.#talk(this.#mine, phrases.alarm[0], {isLoud: true, note});
	}

	#endNight(note) {
		const furby = this.#furby;
		this.#night = undefined;
		this.#isDark = false;
		this.#mammaBubble = undefined;
		this.#wake(this.#mine);
		this.#wake(this.#sister);
		this.#updateButtons();
		this.say(`${note} God morgen! It is 07:00, and the sun is up (well, it rains, this is Bergen).${furby.hasBatteries ? '' : ` Put the batteries back to wake ${furby.name}, if you dare.`}`);
		if (furby.hasBatteries) {
			this.#talk(this.#mine, phrases.lightOn[0]);
		}
	}

	#mammaSays() {
		const night = this.#night;
		const [norwegian, meaning] = mammaLines[Math.min(night.mammaIndex, mammaLines.length - 1)];
		night.mammaIndex++;
		this.#mammaBubble = norwegian;
		this.#mammaUntil = now() + 3.5;
		this.say(`Mamma, from the bedroom: “${norwegian}” (${meaning})`);
	}

	#putBatteriesBack() {
		this.#furby.hasBatteries = true;
		this.#effects.clunk();
		this.#updateButtons();
		this.#persist();
		this.#mine.perkUntil = now() + 1.5;
		if (this.#night) {
			this.#startAlarm(`It is ${clockText(Math.max(this.#night.minutes, 27 * 60))}, and it is still night. It starts again.`);
			return;
		}

		this.#talk(this.#mine, phrases.booted[0], {note: 'The batteries are back in. It remembers everything.'});
	}

	#removeBatteries() {
		const wasAlarm = this.#isAlarm;
		this.#furby.hasBatteries = false;
		this.#puzzle = undefined;
		this.#stopMusic();
		this.#mine.isSleeping = false;
		this.#mine.bubble = undefined;
		this.#sister.bubble = undefined;
		if (canSpeak) {
			speechSynthesis.cancel();
		}

		this.#updateButtons();
		this.#persist();
		if (this.#night) {
			this.#night.phase = 'quiet';
		}

		if (wasAlarm) {
			this.#mammaBubble = 'Takk. God natt, Sindre.';
			this.#mammaUntil = now() + 4;
			this.say('Silence. Pure, beautiful silence. Mamma, from the bedroom: “Takk. God natt, Sindre.” (Thanks. Good night, Sindre.)');
		} else {
			this.say(`The batteries are out. ${this.#furby.name} stops in the middle of a blink. It says nothing at all now.`);
		}
	}

	// The bubbles of the speakers, at fixed places, so they do not cover the Furbies.
	#bubblePlace(creature) {
		if (!this.#hasSister) {
			return {x: 300, y: 14, width: 170};
		}

		return creature.isSister ? {x: 248, y: 8, width: 224, alignRight: true} : {x: 8, y: 8, width: 224};
	}

	#updateButtons() {
		const {light, music, sister, chat, bed, batteries, nsa, sound} = this.parts;
		light.textContent = this.#isDark ? 'Turn On the Light' : 'Turn Off the Light';
		setPressed(light, this.#isDark);

		music.textContent = this.#isMusicPlaying ? 'Stop the Music' : 'Play Music';
		setPressed(music, this.#isMusicPlaying);

		sister.textContent = this.#hasSister ? 'Give Lillesøster’s Furby Back' : 'Borrow Lillesøster’s Furby';
		setPressed(sister, this.#hasSister);
		chat.hidden = !this.#hasSister;

		bed.textContent = this.#night ? 'Skip to the Morning' : 'Go to Bed';

		batteries.textContent = this.#puzzle ? 'Close the Hatch Again' : (this.#furby.hasBatteries ? 'Take Out the Batteries' : 'Put the Batteries Back');
		batteries.dataset.state = this.#isAlarm && !this.#puzzle ? 'urgent' : '';

		setPressed(nsa, this.#isNsa);

		sound.textContent = this.#isSoundOn ? 'Sound: On' : 'Sound: Off';
		setPressed(sound, this.#isSoundOn);
	}

	get #moodText() {
		const furby = this.#furby;
		if (!furby.hasBatteries) {
			return 'NO BATTERIES';
		}

		if (this.#isAlarm) {
			return 'PARTY AT 3 AM';
		}

		if (this.#mine.isSleeping) {
			return 'ASLEEP';
		}

		if (this.#mine.isSick) {
			return 'SICK';
		}

		if (this.#isDancing) {
			return 'DANCING';
		}

		if (furby.hunger > 65) {
			return 'HUNGRY';
		}

		if (furby.energy < 25) {
			return 'SLEEPY';
		}

		if (furby.happiness < 30) {
			return 'BORED';
		}

		return furby.happiness > 75 ? 'VERY HAPPY' : 'HAPPY';
	}

	// The screen of the Furby, with its needs as bars. The bars are hidden from screen readers, which read the percentages.
	#updateLcd() {
		const furby = this.#furby;
		const {lcd} = this.parts;
		const age = Math.max(0, Math.floor((Date.now() - furby.born) / 86_400_000));
		const meters = [['TUMMY', 100 - furby.hunger], ['ENERGY', furby.energy], ['HAPPY', furby.happiness]].map(([label, value]) => [label, Math.round(clamp(value, 0, 100))]);
		const lines = [
			`${furby.name.toUpperCase()}, ${age} ${age === 1 ? 'DAY' : 'DAYS'} OLD`,
			`MOOD: ${this.#moodText}`,
		];
		const key = JSON.stringify([lines, meters.map(([label, value]) => [label, Math.round(value / 12.5), Math.round(value / 10)]), Math.floor(this.#english * 100)]);
		if (key === this.#lastLcd) {
			return;
		}

		this.#lastLcd = key;
		lcd.replaceChildren();
		for (const line of lines) {
			lcd.append(line, '\n');
		}

		for (const [label, value] of meters) {
			const filled = Math.round(value / 12.5);
			const bars = document.createElement('span');
			bars.setAttribute('aria-hidden', 'true');
			bars.textContent = `${'█'.repeat(filled)}${'░'.repeat(8 - filled)} `;
			// The labels are padded with spaces that do not collapse, so the bars line up.
			lcd.append(`${label}:`.padEnd(8, ' '), bars, `${Math.round(value / 10) * 10}%`, '\n');
		}

		lcd.append(`ENGLISH: ${Math.floor(this.#english * 100)}%`);
	}

	#updateDictionary() {
		const {dictionaryList, dictionaryCount} = this.parts;
		dictionaryCount.textContent = `${this.#furby.heard.size} of ${Object.keys(dictionary).length}`;
		dictionaryList.replaceChildren();
		for (const [furbish, meaning] of Object.entries(dictionary)) {
			const term = document.createElement('dt');
			const definition = document.createElement('dd');
			const isHeard = this.#furby.heard.has(furbish);
			term.textContent = isHeard ? furbish : '? ? ?';
			definition.textContent = isHeard ? meaning : 'not heard yet';
			dictionaryList.append(term, definition);
		}
	}

	// The needs of the Furby change by the second while it is on screen, and it complains about them now and then.
	#updateNeeds(seconds) {
		const furby = this.#furby;
		const mine = this.#mine;
		this.#saveTimer += seconds;
		this.#lcdTimer += seconds;
		if (this.#saveTimer > 5) {
			this.#saveTimer = 0;
			this.#persist();
		}

		if (this.#lcdTimer > 1) {
			this.#lcdTimer = 0;
			this.#updateLcd();
		}

		if (!furby.hasBatteries || this.#puzzle) {
			return;
		}

		const time = now();
		if (mine.isSleeping) {
			furby.energy = clamp(furby.energy + (seconds * 2), 0, 100);
			furby.hunger = clamp(furby.hunger + (seconds * 0.08), 0, 100);
			this.#snoreTimer += seconds;
			if (this.#snoreTimer > 2.6) {
				this.#snoreTimer = 0;
				this.#effects.snore();
			}

			if (!this.#isDark && furby.energy >= 100) {
				this.#wake(mine);
				this.#wake(this.#sister);
				this.#talk(mine, phrases.lightOn[0], {note: 'It slept enough, and woke up by itself.'});
			}

			return;
		}

		furby.energy = clamp(furby.energy - (seconds * (this.#isDancing ? 0.4 : 0.12)), 0, 100);
		furby.hunger = clamp(furby.hunger + (seconds * 0.22), 0, 100);
		furby.happiness = clamp(furby.happiness - (seconds * (mine.isSick ? 0.3 : 0.08)), 0, 100);

		if (furby.hunger >= 100 && !mine.isSick) {
			mine.isSick = true;
			furby.isSick = true;
			this.#effects.sneeze();
			this.#talk(mine, phrases.sick[0], {note: 'It got sick from hunger. Give it a spoon of tran, then feed it.'});
			return;
		}

		if (this.#isAlarm) {
			return;
		}

		// It falls asleep in the dark when nobody plays with it, or anywhere when it is worn out.
		const isIdle = time - this.#lastInteraction > 7;
		if ((this.#isDark && isIdle) || (furby.energy <= 0 && !this.#isDancing)) {
			this.#talk(mine, phrases.sleepy[0], {note: 'It falls asleep.'});
			this.#fallAsleep(mine);
			this.#fallAsleep(this.#sister);
			return;
		}

		if (this.#isMotion && this.#isUpsideDown && time - this.#upsideDownSince > 5) {
			this.#upsideDownSince = time;
			mine.perkUntil = time + 1;
			this.#talk(mine, randomItem(phrases.stillUpsideDown), {note: 'It does not like being upside down.'});
			return;
		}

		if (this.#isMotion && time > this.#nextIdle && this.isVisible) {
			this.#nextIdle = time + 14 + (Math.random() * 12);
			if (this.#hasSister && Math.random() < 0.5) {
				this.#chat();
			} else if (mine.isSick) {
				this.#effects.sneeze();
				this.#talk(mine, randomItem(phrases.sick));
			} else if (furby.hunger > 65) {
				this.#talk(mine, randomItem(phrases.hungry), {note: 'It is hungry. Press its tongue.'});
			} else if (furby.energy < 25) {
				this.#talk(mine, randomItem(phrases.sleepy), {note: 'It is sleepy. Turn off the light.'});
			} else if (this.#isDancing) {
				this.#talk(mine, randomItem(phrases.dancing));
			} else if (this.#isNsa) {
				this.#talk(mine, randomItem(phrases.nsa));
			} else if (furby.happiness < 30) {
				this.#talk(mine, randomItem(phrases.bored), {note: 'It is bored.'});
			} else {
				this.#talk(mine, randomItem(phrases.idle));
			}
		}
	}

	// The night runs fast, from 22:00 to 03:00 in a few seconds, slower while the Furby parties, and fast again to 07:00 once it is quiet.
	#updateNight(seconds) {
		const night = this.#night;
		if (!night) {
			return;
		}

		const speed = night.phase === 'alarm' ? 1 : (this.#isMotion ? 40 : 60);
		night.minutes += seconds * speed;
		if (night.phase === 'asleep' && night.minutes >= 27 * 60) {
			if (this.#furby.hasBatteries) {
				this.#startAlarm('It is 03:00. It is wide awake, and it wants to play. Loudly.');
			} else {
				night.phase = 'quiet';
			}

			return;
		}

		// While the visitor works on the battery hatch, the Furby only squirms, so the status can say what to do.
		if (night.phase === 'alarm' && !this.#puzzle && now() > night.nextLine) {
			night.nextLine = now() + 2.8;
			if (night.mammaIndex <= night.attempts || Math.random() < 0.35) {
				this.#mammaSays();
			} else {
				this.#mine.perkUntil = now() + 0.8;
				this.#talk(this.#mine, randomItem(phrases.alarm), {isLoud: true});
				if (this.#hasSister && Math.random() < 0.5) {
					setTimeout(() => {
						if (this.#hasSister && this.#isAlarm) {
							this.#talk(this.#sister, randomItem(phrases.alarm), {isLoud: true, note: 'Lillesøster cries: “Mammaaa! Furbyen vekket meg!” (The Furby woke me!)'});
						}
					}, 1100);
				}
			}
		}

		if (night.phase === 'quiet' && night.minutes >= 31 * 60) {
			this.#endNight('Everybody slept.');
		}
	}

	// Drawing

	#fillEllipse(color, x, y, radiusX, radiusY, rotation = 0) {
		const context = this.#context;
		context.fillStyle = color;
		context.beginPath();
		context.ellipse(x, y, Math.max(radiusX, 0.1), Math.max(radiusY, 0.1), rotation, 0, Math.PI * 2);
		context.fill();
	}

	#drawRoom(time) {
		const context = this.#context;
		const {canvas} = context;
		const isNight = this.#night || this.#isDark;

		// The wallpaper of my room, light blue with stripes.
		context.fillStyle = '#bfe0ee';
		context.fillRect(0, 0, canvas.width, canvas.height);
		context.fillStyle = '#afd4e4';
		for (let x = 0; x < canvas.width; x += 32) {
			context.fillRect(x, 0, 12, 300);
		}

		// The window, with the rain of Bergen, or the moon at night.
		context.fillStyle = '#ffffff';
		context.fillRect(14, 20, 104, 92);
		context.fillStyle = isNight ? '#141c3c' : '#8e9aa8';
		context.fillRect(20, 26, 92, 80);
		if (isNight) {
			this.#fillEllipse('#fff6c0', 88, 48, 10, 10);
			this.#fillEllipse('#141c3c', 93, 45, 9, 9);
		} else {
			context.strokeStyle = 'rgba(255, 255, 255, 0.7)';
			context.lineWidth = 1.5;
			context.beginPath();
			for (let index = 0; index < 14; index++) {
				const x = 22 + ((index * 23) % 90);
				const y = 26 + ((((index * 37) + (this.#isMotion ? time * 160 : 0)) % 80));
				context.moveTo(x, y);
				context.lineTo(x - 3, Math.min(y + 9, 106));
			}

			context.stroke();
		}

		context.fillStyle = '#ffffff';
		context.fillRect(64, 26, 4, 80);
		context.fillRect(20, 64, 92, 4);

		// The wooden floor.
		context.fillStyle = '#b8814a';
		context.fillRect(0, 300, canvas.width, 60);
		context.fillStyle = '#a06f3c';
		for (let y = 312; y < 360; y += 14) {
			context.fillRect(0, y, canvas.width, 2);
		}
	}

	// The clock radio on the floor, which shows the time of the night, or the time of the visitor.
	#drawClock() {
		const context = this.#context;
		context.fillStyle = '#26262b';
		context.beginPath();
		context.roundRect(14, 312, 92, 38, 6);
		context.fill();
		context.fillStyle = '#120404';
		context.fillRect(22, 318, 76, 26);
		const date = new Date();
		const text = this.#night ? clockText(this.#night.minutes) : clockText((date.getHours() * 60) + date.getMinutes());
		context.fillStyle = '#ff3a1e';
		context.font = 'bold 22px "Courier New", monospace';
		context.textAlign = 'center';
		context.textBaseline = 'middle';
		context.fillText(text, 60, 332);
	}

	#drawEar(palette, side, angle) {
		const context = this.#context;
		context.save();
		context.translate(side * 60, -62);
		context.rotate(side * angle);
		context.fillStyle = palette.fur;
		context.beginPath();
		context.moveTo(-side * 24, 10);
		context.quadraticCurveTo(side * 10, -60, side * 30, -98);
		context.quadraticCurveTo(side * 38, -40, side * 24, 12);
		context.closePath();
		context.fill();
		context.strokeStyle = palette.dark;
		context.lineWidth = 2;
		context.stroke();
		context.fillStyle = palette.inner;
		context.beginPath();
		context.moveTo(-side * 10, 4);
		context.quadraticCurveTo(side * 12, -50, side * 27, -82);
		context.quadraticCurveTo(side * 28, -36, side * 16, 6);
		context.closePath();
		context.fill();
		context.restore();
	}

	#drawEye(palette, creature, side, isDizzy, time) {
		const context = this.#context;
		const x = side * 34;
		const y = -28;
		context.save();
		context.beginPath();
		context.ellipse(x, y, 27, 31, 0, 0, Math.PI * 2);
		context.fillStyle = '#ffffff';
		context.fill();
		context.clip();

		let lookX = creature.look * 9;
		let lookY = 3;
		if (isDizzy) {
			lookX = Math.cos((time * 12) + side) * 8;
			lookY = Math.sin((time * 12) + side) * 8;
		}

		this.#fillEllipse(palette.iris, x + lookX, y + lookY, 17, 18);
		this.#fillEllipse('#000000', x + lookX, y + lookY, 9, 10);
		this.#fillEllipse('#ffffff', x + lookX - 6, y + lookY - 8, 4.5, 4.5);

		// The eyelid comes down from the top, in the color of the fur.
		const lidBottom = y - 31 + (62 * creature.lid);
		if (creature.lid > 0.02) {
			context.fillStyle = palette.fur;
			context.fillRect(x - 30, y - 34, 60, lidBottom - (y - 34));
			context.strokeStyle = palette.dark;
			context.lineWidth = 3;
			context.beginPath();
			context.moveTo(x - 28, lidBottom);
			context.lineTo(x + 28, lidBottom);
			context.stroke();
		}

		context.restore();
		context.strokeStyle = palette.dark;
		context.lineWidth = 2.5;
		context.beginPath();
		context.ellipse(x, y, 27, 31, 0, 0, Math.PI * 2);
		context.stroke();

		// The eyelashes of the real one, which show when the eyes are closed.
		if (creature.lid > 0.85) {
			context.strokeStyle = '#000000';
			context.lineWidth = 2;
			context.beginPath();
			for (const offset of [-14, 0, 14]) {
				context.moveTo(x + offset, lidBottom);
				context.lineTo(x + (offset * 1.3), lidBottom + 8);
			}

			context.stroke();
		}
	}

	#drawBeak(palette, creature) {
		const context = this.#context;
		const open = creature.mouth;
		this.#fillEllipse('#3a0d14', 0, 22 + (open * 6), 14, 3 + (open * 10));
		this.#fillEllipse('#ff7d9c', 0, 26 + (open * 9), 9, 2 + (open * 5));
		context.fillStyle = palette.beak;
		context.strokeStyle = '#a0600c';
		context.lineWidth = 2;
		context.beginPath();
		context.moveTo(-15, 22 + (open * 12));
		context.quadraticCurveTo(0, 30 + (open * 14), 15, 22 + (open * 12));
		context.quadraticCurveTo(0, 38 + (open * 14), -15, 22 + (open * 12));
		context.fill();
		context.stroke();
		context.beginPath();
		context.moveTo(-20, 8);
		context.quadraticCurveTo(0, 2, 20, 8);
		context.quadraticCurveTo(10, 24, 0, 30);
		context.quadraticCurveTo(-10, 24, -20, 8);
		context.fill();
		context.stroke();
	}

	// A heart of a Norwegian waffle, or a spoon of tran, on its way to the beak.
	#drawFood(creature, time) {
		const context = this.#context;
		if (!creature.food) {
			return;
		}

		const progress = this.#isMotion ? (time - creature.food.start) / 0.5 : 1;
		if (time - creature.food.start > 0.9) {
			creature.food = undefined;
			return;
		}

		const amount = clamp(progress, 0, 1);
		const x = 130 * (1 - amount);
		const y = -40 + (62 * amount);
		if (creature.food.kind === 'waffle') {
			context.save();
			context.translate(x, y);
			context.fillStyle = '#e3a54a';
			context.beginPath();
			context.moveTo(0, 10);
			context.bezierCurveTo(-22, -4, -12, -22, 0, -10);
			context.bezierCurveTo(12, -22, 22, -4, 0, 10);
			context.fill();
			context.strokeStyle = '#b97a26';
			context.lineWidth = 1.5;
			context.beginPath();
			for (let offset = -12; offset <= 12; offset += 6) {
				context.moveTo(offset, -14);
				context.lineTo(offset, 8);
				context.moveTo(-14, offset * 0.6);
				context.lineTo(14, offset * 0.6);
			}

			context.stroke();
			context.fillStyle = '#c8783a';
			context.fillRect(-6, -8, 12, 5);
			context.restore();
		} else {
			context.strokeStyle = '#9a9aa6';
			context.lineWidth = 4;
			context.beginPath();
			context.moveTo(x + 14, y + 4);
			context.lineTo(x + 60, y - 20);
			context.stroke();
			this.#fillEllipse('#c9c9d4', x, y + 8, 14, 8);
			this.#fillEllipse('#e8d040', x, y + 7, 9, 4);
		}
	}

	#drawFurby(creature, time) {
		const context = this.#context;
		const furby = this.#furby;
		const palette = creature.isSister ? furs.sister : furs[furby.fur];
		const isDead = !creature.isSister && !furby.hasBatteries;
		const dancing = this.#isDancing && !creature.isSleeping && furby.hasBatteries && this.#isMotion;
		let offsetX = 0;
		let bob = 0;
		if (this.#isMotion && time < creature.shakeUntil) {
			offsetX = Math.sin(time * 60) * 10;
		}

		if (dancing) {
			bob = -Math.abs(Math.sin(time * 6)) * 12;
		} else if (this.#isMotion && !isDead && !creature.isSleeping) {
			bob = Math.sin(time * 2) * 1.5;
		}

		context.save();
		context.translate(creature.x + offsetX, creature.y + bob);
		context.rotate((creature.flip * Math.PI) + creature.tilt);
		context.scale(creature.scale, creature.scale);

		const earAngle = 0.45 - (creature.ear * 0.38);
		this.#drawEar(palette, -1, earAngle);
		this.#drawEar(palette, 1, earAngle);

		// The body, with fluffy fur around the edge.
		this.#fillEllipse(palette.fur, 0, 0, 92, 100);
		context.lineCap = 'round';
		context.lineWidth = 3;
		for (const isShade of [true, false]) {
			context.strokeStyle = isShade ? palette.dark : palette.fur;
			context.beginPath();
			for (const strand of creature.fur.strands) {
				if (strand.isDark !== isShade) {
					continue;
				}

				const cosine = Math.cos(strand.angle);
				const sine = Math.sin(strand.angle);
				const baseX = cosine * 86;
				const baseY = sine * 94;
				context.moveTo(baseX, baseY);
				context.lineTo(baseX + (Math.cos(strand.angle + strand.curl) * strand.length), baseY + (Math.sin(strand.angle + strand.curl) * strand.length));
			}

			context.stroke();
		}

		if (palette.spots) {
			for (const spot of creature.fur.spots) {
				this.#fillEllipse(palette.spots, spot.x, spot.y, spot.size, spot.size * 0.8);
			}
		}

		context.strokeStyle = palette.dark;
		context.globalAlpha = 0.4;
		context.lineWidth = 2;
		context.beginPath();
		for (const point of creature.fur.texture) {
			context.moveTo(point.x, point.y);
			context.lineTo(point.x + (Math.sin(point.angle) * 6), point.y + (Math.cos(point.angle) * 8));
		}

		context.stroke();
		context.globalAlpha = 1;

		// The feet.
		for (const side of [-1, 1]) {
			this.#fillEllipse(palette.feet, side * 38, 102, 26, 12);
			context.strokeStyle = '#a0600c';
			context.lineWidth = 2;
			context.beginPath();
			for (const toe of [-8, 8]) {
				context.moveTo((side * 38) + toe, 96);
				context.lineTo((side * 38) + toe, 108);
			}

			context.stroke();
		}

		// The tummy, the face, and the tuft on top.
		this.#fillEllipse(palette.belly, 0, 58, 52, 38);
		context.globalAlpha = 0.55;
		this.#fillEllipse(palette.face, 0, -14, 74, 52);
		context.globalAlpha = 1;
		context.strokeStyle = palette.dark;
		context.lineWidth = 4;
		context.beginPath();
		const tuftWave = this.#isMotion && !isDead ? Math.sin(time * 3) * 4 : 0;
		for (const offset of [-12, -5, 2, 9]) {
			context.moveTo(offset, -92);
			context.quadraticCurveTo(offset + tuftWave, -112, offset + 8 + tuftWave, -120);
		}

		context.stroke();

		if (creature.isSick) {
			context.globalAlpha = 0.25;
			this.#fillEllipse('#5fbf3a', 0, -14, 76, 54);
			context.globalAlpha = 1;
		}

		const isDizzy = this.#isMotion && !creature.isSister && this.#shakeTimes.length >= 3 && time - this.#shakeTimes.at(-1) < 3;
		this.#drawEye(palette, creature, -1, isDizzy, time);
		this.#drawEye(palette, creature, 1, isDizzy, time);

		// The eyebrows go up when it is surprised.
		const brow = time < creature.perkUntil ? -8 : 0;
		context.strokeStyle = palette.dark;
		context.lineWidth = 4;
		context.beginPath();
		context.moveTo(-54, -66 + brow);
		context.quadraticCurveTo(-36, -76 + brow, -16, -66 + brow);
		context.moveTo(54, -66 + brow);
		context.quadraticCurveTo(36, -76 + brow, 16, -66 + brow);
		context.stroke();

		this.#drawBeak(palette, creature);

		if (creature.isSick) {
			// A thermometer in the beak.
			context.strokeStyle = '#ffffff';
			context.lineWidth = 5;
			context.beginPath();
			context.moveTo(8, 26);
			context.lineTo(56, 42);
			context.stroke();
			context.strokeStyle = '#e02020';
			context.lineWidth = 2;
			context.beginPath();
			context.moveTo(14, 28);
			context.lineTo(40, 37);
			context.stroke();
		}

		if (!creature.isSister && this.#isNsa) {
			this.#drawSpyGear();
		}

		this.#drawFood(creature, time);
		context.restore();
	}

	// The sunglasses and the earpiece of an NSA agent.
	#drawSpyGear() {
		const context = this.#context;
		context.fillStyle = '#0a0a0a';
		for (const side of [-1, 1]) {
			context.beginPath();
			context.roundRect((side * 34) - 33, -54, 66, 50, 12);
			context.fill();
		}

		context.fillRect(-6, -40, 12, 6);
		context.strokeStyle = 'rgba(255, 255, 255, 0.6)';
		context.lineWidth = 3;
		context.beginPath();
		context.moveTo(-54, -42);
		context.lineTo(-40, -30);
		context.moveTo(14, -42);
		context.lineTo(28, -30);
		context.stroke();
		context.strokeStyle = '#d8d8d8';
		context.lineWidth = 2;
		context.beginPath();
		context.moveTo(78, -48);
		for (let index = 0; index < 8; index++) {
			context.arc(82, -40 + (index * 7), 4, Math.PI, Math.PI * 2.6);
		}

		context.stroke();
	}

	// Wraps the text of a bubble into lines that fit its width.
	#wrap(text, width) {
		const lines = [];
		let line = '';
		for (const part of text.split(' ')) {
			const candidate = line ? `${line} ${part}` : part;
			if (this.#context.measureText(candidate).width > width && line) {
				lines.push(line);
				line = part;
			} else {
				line = candidate;
			}
		}

		if (line) {
			lines.push(line);
		}

		return lines;
	}

	#drawBubble(text, {x, y, width, bottom, tailX, tailY, isThought = false, alignRight = false, title}) {
		const context = this.#context;
		context.font = 'bold 16px "Comic Sans MS", "Comic Neue", "Chalkboard SE", cursive';
		context.textAlign = 'left';
		context.textBaseline = 'top';
		const lines = this.#wrap(text, width - 20);
		if (title) {
			lines.unshift(title);
		}

		const boxWidth = Math.min(width, Math.max(...lines.map(line => context.measureText(line).width)) + 22);
		const boxHeight = (lines.length * 20) + 14;
		const top = bottom === undefined ? y : bottom - boxHeight;
		const left = alignRight ? x + width - boxWidth : x;
		context.fillStyle = isThought ? '#eeeeee' : '#ffffff';
		context.strokeStyle = '#000000';
		context.lineWidth = 2.5;

		// The tail points at the speaker.
		const tailBaseX = clamp(tailX, left + 18, left + boxWidth - 18);
		const tailBaseY = tailY > top ? top + boxHeight : top;
		if (isThought) {
			for (const [index, size] of [6, 4].entries()) {
				const amount = (index + 1) / 3;
				this.#fillEllipse('#eeeeee', tailBaseX + ((tailX - tailBaseX) * amount), tailBaseY + ((tailY - tailBaseY) * amount), size, size);
			}
		} else {
			context.beginPath();
			context.moveTo(tailBaseX - 9, tailBaseY);
			context.lineTo(tailX, tailY);
			context.lineTo(tailBaseX + 9, tailBaseY);
			context.closePath();
			context.fill();
			context.stroke();
		}

		context.beginPath();
		context.roundRect(left, top, boxWidth, boxHeight, 14);
		context.fill();
		context.stroke();
		if (!isThought) {
			context.fillRect(tailBaseX - 7, tailBaseY - 2, 14, 4);
		}

		for (const [index, line] of lines.entries()) {
			context.fillStyle = title && index === 0 ? '#cc0000' : (isThought ? '#666666' : '#000000');
			context.fillText(line, left + 11, top + 8 + (index * 20));
		}
	}

	#drawParticles(time) {
		const context = this.#context;
		const particles = this.#particles;
		for (const particle of [...particles]) {
			const age = time - particle.start;
			if (age > particle.life) {
				particles.splice(particles.indexOf(particle), 1);
				continue;
			}

			const x = this.#isMotion ? particle.startX + (particle.velocityX * age) : particle.startX;
			const y = this.#isMotion ? particle.startY - (age * 40) : particle.startY;
			context.globalAlpha = clamp(1 - (age / particle.life), 0, 1);
			context.font = 'bold 26px sans-serif';
			context.textAlign = 'center';
			context.textBaseline = 'middle';
			context.fillStyle = particle.kind === 'heart' ? '#ff3a7a' : (particle.kind === 'note' ? '#5a2ad0' : '#ffd200');
			context.fillText(particle.kind === 'heart' ? '♥' : (particle.kind === 'note' ? '♪' : '★'), x, y);
			context.globalAlpha = 1;
		}
	}

	// The infrared beam between the two Furbies while they talk, which a real one could not see either, but here it shows.
	#drawInfrared(time) {
		if (!this.#hasSister || time > this.#irUntil || !this.#furby.hasBatteries) {
			return;
		}

		const context = this.#context;
		const mine = this.#mine;
		const sister = this.#sister;
		context.save();
		context.strokeStyle = 'rgba(255, 40, 40, 0.75)';
		context.lineWidth = 3;
		context.setLineDash([6, 8]);
		context.lineDashOffset = this.#isMotion ? -time * 40 : 0;
		context.beginPath();
		const startX = mine.x + (20 * mine.scale);
		const endX = sister.x - (20 * sister.scale);
		const y = mine.y - (70 * mine.scale);
		context.moveTo(startX, y);
		context.quadraticCurveTo((startX + endX) / 2, y - 40, endX, y);
		context.stroke();
		context.restore();
	}

	#drawSleep(creature, time) {
		if (!creature.isSleeping) {
			return;
		}

		const context = this.#context;
		context.font = 'bold 22px "Comic Sans MS", cursive';
		context.textAlign = 'center';
		context.textBaseline = 'middle';
		context.fillStyle = this.#isDark ? '#ffffff' : '#2a2a7a';
		for (let index = 0; index < 3; index++) {
			const phase = this.#isMotion ? ((time * 0.5) + (index / 3)) % 1 : index / 3;
			context.globalAlpha = this.#isMotion ? 1 - phase : 1;
			context.fillText('z', creature.x + ((50 + (phase * 40)) * creature.scale), creature.y - ((90 + (phase * 70)) * creature.scale));
		}

		context.globalAlpha = 1;
	}

	#drawPuzzle() {
		const context = this.#context;
		const {canvas} = context;
		const puzzle = this.#puzzle;
		context.fillStyle = '#8a5a32';
		context.fillRect(0, 0, canvas.width, canvas.height);
		const palette = furs[this.#furby.fur];
		this.#fillEllipse(palette.fur, 240, 180, 200, 168);
		this.#fillEllipse(palette.dark, 240, 180, 200, 168);
		this.#fillEllipse(palette.fur, 240, 178, 194, 162);
		context.fillStyle = '#d9d4c8';
		context.beginPath();
		context.roundRect(130, 70, 220, 220, 30);
		context.fill();
		context.strokeStyle = '#a8a294';
		context.lineWidth = 3;
		context.stroke();

		context.fillStyle = '#7a776e';
		context.font = 'bold 10px Arial, sans-serif';
		context.textAlign = 'center';
		context.textBaseline = 'middle';
		context.fillText('© 1998 TIGER ELECTRONICS', 240, 266);
		context.fillText('MADE IN CHINA', 240, 278);
		this.#fillEllipse('#c03030', 320, 250, 7, 7);
		context.fillText('RESET', 320, 238);

		context.fillStyle = '#2a2a2a';
		context.fillRect(166, 118, 148, 116);
		if (puzzle.step === 'screw') {
			context.fillStyle = '#cfcabd';
			context.fillRect(166, 118, 148, 116);
			context.strokeStyle = '#9a9486';
			context.strokeRect(166, 118, 148, 116);
			context.fillStyle = '#8f8a7c';
			context.font = 'bold 20px Arial, sans-serif';
			context.fillText('4 × AA', 240, 168);
			context.font = 'bold 12px Arial, sans-serif';
			context.fillText('1.5 V', 240, 190);

			// The screw rises a little as it turns out.
			const progress = puzzle.turned / (Math.PI * 4);
			this.#fillEllipse('rgba(0, 0, 0, 0.3)', screw.x + (progress * 4), screw.y + (progress * 4), 14, 14);
			this.#fillEllipse('#b8b8c0', screw.x, screw.y, 13, 13);
			context.save();
			context.translate(screw.x, screw.y);
			context.rotate(-puzzle.turned);
			context.fillStyle = '#55555f';
			context.fillRect(-10, -2, 20, 4);
			context.fillRect(-2, -10, 4, 20);
			context.restore();

			// Pappa’s tiny screwdriver, in the screw.
			context.save();
			context.translate(screw.x, screw.y);
			context.rotate(-0.7);
			context.fillStyle = '#9a9aa6';
			context.fillRect(-2, -70, 4, 66);
			context.fillStyle = '#e8c020';
			context.beginPath();
			context.roundRect(-8, -120, 16, 52, 6);
			context.fill();
			context.fillStyle = '#d02020';
			context.fillRect(-8, -104, 16, 6);
			context.restore();

			context.fillStyle = '#ffffff';
			context.font = 'bold 26px sans-serif';
			context.fillText('↺', screw.x - 40, screw.y);
		} else {
			for (const [index, isIn] of puzzle.batteries.entries()) {
				if (!isIn) {
					continue;
				}

				const {x, y, width, height} = batteryRectangle(index);
				context.fillStyle = '#2b58c8';
				context.fillRect(x, y + 6, width, height - 6);
				context.fillStyle = '#c0c0c8';
				context.fillRect(x + 8, y, width - 16, 6);
				context.fillStyle = '#ffffff';
				context.font = 'bold 11px Arial, sans-serif';
				context.fillText('AA', x + (width / 2), y + 50);
			}

			// The hatch and the screw, beside it on the desk.
			context.save();
			context.translate(400, 320);
			context.rotate(0.3);
			context.fillStyle = '#cfcabd';
			context.fillRect(-50, -28, 100, 56);
			context.restore();
			this.#fillEllipse('#b8b8c0', 450, 250, 6, 6);
		}

		// The batteries that are out lie on the desk.
		const outCount = puzzle.batteries.filter(isIn => !isIn).length;
		for (let index = 0; index < outCount; index++) {
			context.fillStyle = '#2b58c8';
			context.fillRect(14, 300 - (index * 18), 70, 14);
			context.fillStyle = '#c0c0c8';
			context.fillRect(84, 304 - (index * 18), 5, 6);
		}
	}

	#drawScene(time) {
		if (this.#puzzle) {
			this.#drawPuzzle();
			return;
		}

		const context = this.#context;
		const {canvas} = context;
		const mine = this.#mine;
		const sister = this.#sister;
		this.#drawRoom(time);
		this.#drawClock();
		if (this.#hasSister || sister.x < canvas.width + 60) {
			this.#drawFurby(sister, time);
		}

		this.#drawFurby(mine, time);
		this.#drawInfrared(time);
		if (this.#isDark) {
			context.fillStyle = 'rgba(4, 6, 28, 0.78)';
			context.fillRect(0, 0, canvas.width, canvas.height);
			this.#drawClock();
		}

		this.#drawSleep(mine, time);
		if (this.#hasSister) {
			this.#drawSleep(sister, time);
		}

		this.#drawParticles(time);

		for (const creature of this.#hasSister ? [mine, sister] : [mine]) {
			if (creature.bubble && time < creature.bubbleUntil) {
				const place = this.#bubblePlace(creature);
				const tailY = creature.y - ((creature.flip > 0.5 ? -40 : 70) * creature.scale);
				this.#drawBubble(creature.bubble, {...place, tailX: creature.x + ((creature.isSister ? -20 : (this.#hasSister ? 20 : 60)) * creature.scale), tailY, isThought: creature.isThought});
			}
		}

		if (this.#mammaBubble && time < this.#mammaUntil) {
			this.#drawBubble(this.#mammaBubble, {x: 290, width: 182, bottom: 352, tailX: 478, tailY: 300, title: 'Mamma:'});
		}

		if (this.#isNsa) {
			context.fillStyle = '#ff2020';
			context.font = 'bold 14px "Courier New", monospace';
			context.textAlign = 'left';
			context.textBaseline = 'top';
			context.fillText('NSA ● REC 0:00', 130, 6);
		}
	}

	// Moves the face toward what it should show now. For reduced motion, it shows it at once, and does not blink or look around by itself.
	#updatePose(creature, seconds, time) {
		const motion = this.#isMotion;
		const isDead = !this.#furby.hasBatteries && !creature.isSister;
		const isDancing = this.#isDancing;
		const isNsa = this.#isNsa;
		const hasSister = this.#hasSister;
		const ease = (value, target, speed = 12) => (motion ? value + ((target - value) * (1 - Math.exp(-seconds * speed))) : target);

		if (motion && !isDead && time > creature.nextBlink) {
			creature.blinkUntil = time + 0.14;
			creature.nextBlink = time + 2 + (Math.random() * 4);
		}

		if (motion && !isDead && time > creature.nextLook) {
			creature.nextLook = time + (isNsa ? 0.6 : 1.5 + (Math.random() * 3));
			creature.lookTarget = isNsa && !creature.isSister ? (creature.lookTarget > 0 ? -1 : 1) : (Math.random() * 2) - 1;
			if (Math.random() < 0.3) {
				creature.earTwitchUntil = time + 0.3;
			}
		}

		let lid = 0;
		if (isDead) {
			lid = 0.55;
		} else if (creature.isSleeping || time < creature.blinkUntil) {
			lid = 1;
		} else if (time < creature.yuckUntil) {
			lid = 0.7;
		} else if (time < creature.contentUntil) {
			lid = 0.6;
		} else if (creature.isSick || (!creature.isSister && this.#furby.energy < 25)) {
			lid = 0.45;
		}

		let ear = 0;
		if (isDead) {
			ear = -1;
		} else if (creature.isSleeping || creature.isSick) {
			ear = -0.8;
		} else if (time < creature.perkUntil) {
			ear = 1;
		} else if (isDancing && motion) {
			ear = Math.sin(time * 10);
		} else if (this.#isUpsideDown && !creature.isSister && motion) {
			ear = Math.sin(time * 14);
		} else if (time < creature.earTwitchUntil) {
			ear = 0.7;
		}

		let mouth = 0;
		if (motion && time < creature.talkUntil) {
			mouth = Math.sin(time * 22) > 0 ? 1 : 0.15;
		} else if (time < creature.munchUntil) {
			mouth = motion ? (Math.sin(time * 16) > 0 ? 0.8 : 0) : 0.5;
		} else if (creature.isSleeping && motion) {
			mouth = 0.15 + (Math.sin(time * 2) * 0.1);
		}

		creature.lid = ease(creature.lid, lid, 18);
		creature.ear = ease(creature.ear, ear, 10);
		creature.mouth = ease(creature.mouth, mouth, 30);
		creature.look = ease(creature.look, isDead ? 0 : creature.lookTarget, 6);
		creature.flip = ease(creature.flip, this.#isUpsideDown && !creature.isSister ? 1 : 0, 6);
		creature.tilt = isDancing && motion && !creature.isSleeping && !isDead ? Math.sin((time * 3) + (creature.isSister ? 1 : 0)) * 0.12 : ease(creature.tilt, 0);

		const place = creature.isSister ? {x: hasSister ? 352 : 560, y: 240, scale: 0.66} : (hasSister ? {x: 128, y: 240, scale: 0.66} : {x: 190, y: 212, scale: 0.9});
		creature.x = ease(creature.x, place.x, 5);
		creature.y = ease(creature.y, place.y, 5);
		creature.scale = ease(creature.scale, place.scale, 5);
	}

	#hitTest(point) {
		for (const creature of this.#hasSister ? [this.#sister, this.#mine] : [this.#mine]) {
			const {x, y} = localPoint(creature, point);
			const isOnBody = ((x / 104) ** 2) + ((y / 112) ** 2) <= 1;
			const isOnEars = y < -50 && y > -170 && Math.abs(x) < 120;
			if (!isOnBody && !isOnEars) {
				continue;
			}

			let part = 'back';
			if (Math.hypot(x, y - 20) < 26) {
				part = 'beak';
			} else if (((x / 58) ** 2) + (((y - 58) / 40) ** 2) <= 1) {
				part = 'tummy';
			} else if (Math.abs(x) < 64 && y > -62 && y < 2) {
				part = 'eyes';
			}

			return {creature, part};
		}

		return undefined;
	}

	#pokeSister(part) {
		const sister = this.#sister;
		if (!sister.isSleeping) {
			sister.perkUntil = now() + 1;
			if (part === 'tummy') {
				this.#effects.giggle();
			}

			this.#talk(sister, randomItem(phrases.sisterPoked), {note: part === 'tummy' ? `${sisterName} giggles.` : ''});
		} else {
			this.#wake(sister);
			this.#talk(sister, phrases.woken[1]);
		}
	}

	#coverEyes() {
		const mine = this.#mine;
		if (!this.#drag) {
			return;
		}

		if (!this.#checkBatteries() || this.#isAlarm) {
			if (this.#isAlarm) {
				this.#louder();
			}

			return;
		}

		this.#drag.hasCovered = true;
		if (mine.isSleeping) {
			return;
		}

		this.#talk(mine, phrases.coveredEyes[0], {note: 'You cover its light sensor. Keep it covered, and it falls asleep.'});
		this.#drag.sleepTimer = setTimeout(() => {
			if (this.#drag?.hasCovered && !this.#isAlarm) {
				this.#talk(mine, phrases.sleepy[0], {note: 'In the dark of your hand, it falls asleep.'});
				this.#fallAsleep(mine);
			}
		}, 2500);
	}

	#turnScrew(delta) {
		const puzzle = this.#puzzle;
		if (delta > 0) {
			// A little jitter of the pointer is not a turn to the right.
			puzzle.tightened += delta;
			if (puzzle.tightened >= Math.PI / 2 && !puzzle.hasWarned) {
				puzzle.hasWarned = true;
				this.say('Righty tighty! It is already tight. Lefty loosey: turn it the other way.');
			}

			return;
		}

		const before = Math.floor(puzzle.turned / (Math.PI / 2));
		puzzle.turned -= delta;
		puzzle.tightened = 0;
		const quarters = Math.floor(puzzle.turned / (Math.PI / 2));
		if (quarters > before) {
			this.#effects.squeak();
			if (quarters === 4) {
				this.say('Squeak! One whole turn. One more!');
			}
		}

		if (puzzle.turned >= Math.PI * 4) {
			puzzle.step = 'batteries';
			this.#effects.clunk();
			this.say('The screw is out, and the hatch comes off! Now take out the four batteries: click them, or press Enter.');
		}
	}

	#takeBattery(index) {
		const puzzle = this.#puzzle;
		if (!puzzle?.batteries[index]) {
			return;
		}

		puzzle.batteries[index] = false;
		this.#effects.clunk();
		const left = puzzle.batteries.filter(Boolean).length;
		if (left === 0) {
			this.#removeBatteries();
		} else {
			this.say(`${left} ${left === 1 ? 'battery' : 'batteries'} left.`);
		}
	}

	// A second finger is ignored, so it does not take over the drag of the first one.
	#clearDrag() {
		clearTimeout(this.#drag?.holdTimer);
		clearTimeout(this.#drag?.sleepTimer);
		this.#drag = undefined;
	}

	#pointerDown(event) {
		if (!event.isPrimary) {
			return;
		}

		const {canvas} = this.parts;
		const puzzle = this.#puzzle;
		this.#clearDrag();
		const point = canvasPoint(canvas, event);
		if (puzzle) {
			if (puzzle.step === 'screw' && Math.hypot(point.x - screw.x, point.y - screw.y) < 90) {
				this.#drag = {isScrew: true, angle: Math.atan2(point.y - screw.y, point.x - screw.x)};
				canvas.setPointerCapture(event.pointerId);
			} else if (puzzle.step === 'batteries') {
				for (const index of puzzle.batteries.keys()) {
					const {x, y, width, height} = batteryRectangle(index);
					if (point.x >= x - 3 && point.x <= x + width + 3 && point.y >= y && point.y <= y + height) {
						this.#takeBattery(index);
						break;
					}
				}
			}

			return;
		}

		const hit = this.#hitTest(point);
		if (!hit) {
			return;
		}

		event.preventDefault();
		if (hit.creature === this.#sister) {
			this.#pokeSister(hit.part);
			return;
		}

		canvas.setPointerCapture(event.pointerId);
		this.#drag = {x: point.x, y: point.y, distance: 0, direction: 0, reversals: []};

		if (!this.#furby.hasBatteries) {
			this.#checkBatteries();
			return;
		}

		if (hit.part === 'beak') {
			this.#runAction('feed');
		} else if (hit.part === 'tummy') {
			this.#runAction('tickle');
		} else if (hit.part === 'eyes') {
			this.#drag.holdTimer = setTimeout(() => {
				this.#coverEyes();
			}, 700);
		}
	}

	#pointerMove(event) {
		const drag = this.#drag;
		if (!drag) {
			return;
		}

		const point = canvasPoint(this.parts.canvas, event);
		if (drag.isScrew) {
			const angle = Math.atan2(point.y - screw.y, point.x - screw.x);
			let delta = angle - drag.angle;
			if (delta > Math.PI) {
				delta -= Math.PI * 2;
			} else if (delta < -Math.PI) {
				delta += Math.PI * 2;
			}

			drag.angle = angle;
			if (this.#puzzle?.step === 'screw') {
				this.#turnScrew(delta);
			}

			return;
		}

		const deltaX = point.x - drag.x;
		const distance = Math.hypot(deltaX, point.y - drag.y);
		drag.distance += distance;
		drag.x = point.x;
		drag.y = point.y;
		if (drag.holdTimer && drag.distance > 20) {
			clearTimeout(drag.holdTimer);
			drag.holdTimer = undefined;
		}

		if (!this.#furby.hasBatteries || drag.hasCovered) {
			return;
		}

		// Fast strokes from side to side shake it.
		if (Math.abs(deltaX) > 6) {
			const direction = Math.sign(deltaX);
			const time = now();
			if (drag.direction !== 0 && direction !== drag.direction) {
				drag.reversals = [...drag.reversals.filter(reversal => time - reversal < 1), time];
			}

			drag.direction = direction;
			if (drag.reversals.length >= 4) {
				drag.reversals = [];
				drag.distance = 0;
				this.#runAction('shake');
				return;
			}
		}

		// A slow stroke pets it, but not the strokes of a shake.
		const isShaking = drag.reversals.length > 0 && now() - drag.reversals.at(-1) < 0.6;
		if (drag.distance > 90 && !isShaking) {
			drag.distance = 0;
			this.#runAction('pet');
		}
	}

	#endDrag(event) {
		if (!this.#drag || !event.isPrimary) {
			return;
		}

		clearTimeout(this.#drag.holdTimer);
		if (this.#drag.hasCovered && !this.#mine.isSleeping && this.#furby.hasBatteries) {
			this.#talk(this.#mine, phrases.peekaboo[0], {note: 'Peekaboo!'});
			this.#interact(1);
		}

		this.#clearDrag();
	}

	#keyDown(event) {
		if (event.altKey || event.ctrlKey || event.metaKey) {
			return;
		}

		const puzzle = this.#puzzle;
		if (puzzle) {
			if (event.key === 'Escape') {
				this.#actions.batteries();
			} else if (puzzle.step === 'screw' && (event.key === 'ArrowLeft' || event.key === 'ArrowRight')) {
				this.#turnScrew(event.key === 'ArrowLeft' ? -Math.PI / 2 : Math.PI / 2);
			} else if (puzzle.step === 'batteries' && (event.key === 'Enter' || event.key === ' ')) {
				this.#takeBattery(puzzle.batteries.indexOf(true));
			} else {
				return;
			}

			event.preventDefault();
			return;
		}

		const action = keyActions[event.key.toLowerCase()];
		if (!action) {
			return;
		}

		event.preventDefault();
		this.#runAction(action);
	}

	#runAction(action) {
		// Anything but the batteries puts the Furby back on its feet.
		if (this.#puzzle && action !== 'batteries' && action !== 'sound' && action !== 'nsa') {
			this.#puzzle = undefined;
			this.#updateButtons();
		}

		const needsBatteries = ['feed', 'tickle', 'pet'];
		if (needsBatteries.includes(action) && !this.#checkBatteries()) {
			return;
		}

		// Poking it in its sleep at night wakes it for good.
		if (this.#night?.phase === 'asleep' && this.#furby.hasBatteries && ['feed', 'tickle', 'flip', 'shake', 'music'].includes(action)) {
			if (action === 'flip') {
				this.#setUpsideDown(!this.#isUpsideDown);
			}

			this.#startAlarm('You woke it. Now it will not sleep again tonight.');
			return;
		}

		this.#actions[action]();
		this.#updateLcd();
	}
}
