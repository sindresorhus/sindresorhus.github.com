// Sindre Hawk’s Pro Skater on the 1999 page: a skateboarding game like Tony Hawk’s Pro Skater (Neversoft, 1999), seen from the side, in a level of Bergen. The visitor pushes, ollies, spins, flips, grabs, grinds, and manuals, links the tricks in combos with a multiplier, fills the special meter for the special tricks, collects the letters S, K, A, T, and E and a secret tape, and finds the named gaps, in a run of two minutes. A bail drops the skater in a ragdoll fall. Everything is drawn on one canvas of 400 × 240 pixels, which runs only while it is on the screen and the tab is visible. The high score, the best combo, and the gaps found are kept in the browser.
const randomItem = items => items[Math.floor(Math.random() * items.length)];
const randomBetween = (minimum, maximum) => minimum + (Math.random() * (maximum - minimum));
const clamp = (value, minimum, maximum) => Math.min(Math.max(value, minimum), maximum);
const formatNumber = value => Math.round(value).toLocaleString('en-US');

const width = 400;
const height = 240;

// The ground of the screen: a world height of the camera is drawn at this row.
const horizon = 200;

// The physics of the game, in pixels and seconds.
const gravity = 400;
const pushTopSpeed = 260;
const topSpeed = 380;
const spinSpeed = 620;
const runSeconds = 120;

// A tiny pixel font of 3 × 5 for the screen, so the text is crisp at any size. Each letter is five rows of three bits.
const pixelFont = {
	A: [2, 5, 7, 5, 5], B: [6, 5, 6, 5, 6], C: [3, 4, 4, 4, 3], D: [6, 5, 5, 5, 6], E: [7, 4, 6, 4, 7], F: [7, 4, 6, 4, 4], G: [3, 4, 5, 5, 3], H: [5, 5, 7, 5, 5], I: [7, 2, 2, 2, 7], J: [1, 1, 1, 5, 2], K: [5, 5, 6, 5, 5], L: [4, 4, 4, 4, 7], M: [5, 7, 7, 5, 5], N: [6, 5, 5, 5, 5], O: [2, 5, 5, 5, 2], P: [6, 5, 6, 4, 4], Q: [2, 5, 5, 6, 3], R: [6, 5, 6, 5, 5], S: [3, 4, 2, 1, 6], T: [7, 2, 2, 2, 2], U: [5, 5, 5, 5, 7], V: [5, 5, 5, 5, 2], W: [5, 5, 7, 7, 5], X: [5, 5, 2, 5, 5], Y: [5, 5, 2, 2, 2], Z: [7, 1, 2, 4, 7],
	0: [7, 5, 5, 5, 7], 1: [2, 6, 2, 2, 7], 2: [6, 1, 2, 4, 7], 3: [6, 1, 2, 1, 6], 4: [5, 5, 7, 1, 1], 5: [7, 4, 6, 1, 6], 6: [3, 4, 7, 5, 7], 7: [7, 1, 2, 2, 2], 8: [7, 5, 7, 5, 7], 9: [7, 5, 7, 1, 6],
	' ': [0, 0, 0, 0, 0], '.': [0, 0, 0, 0, 2], ',': [0, 0, 0, 2, 4], '!': [2, 2, 2, 0, 2], '?': [6, 1, 2, 0, 2], ':': [0, 2, 0, 2, 0], '-': [0, 0, 7, 0, 0], '+': [0, 2, 7, 2, 0], '/': [1, 1, 2, 4, 4], '\'': [2, 2, 0, 0, 0], '’': [2, 2, 0, 0, 0], '(': [1, 2, 2, 2, 1], ')': [4, 2, 2, 2, 4], '×': [0, 5, 2, 5, 0], '%': [5, 1, 2, 4, 5], '<': [1, 2, 4, 2, 1], '>': [4, 2, 1, 2, 4], '=': [0, 7, 0, 7, 0], '♥': [0, 5, 7, 7, 2], '*': [0, 5, 2, 5, 0], '#': [5, 7, 5, 7, 5], '★': [2, 7, 2, 5, 0],
	Æ: [3, 6, 7, 6, 7], Ø: [3, 5, 7, 5, 6], Å: [2, 0, 2, 5, 7],
};

const textWidth = (text, scale = 1) => ((([...String(text)].length * 4) - 1) * scale);

// Splits a combo into lines that fit the screen, between its tricks.
const wrapTricks = (names, maximumCharacters) => {
	const lines = [];
	let line = '';
	for (const [index, name] of names.entries()) {
		const part = index === 0 ? name : ` + ${name}`;
		if (line.length > 0 && line.length + part.length > maximumCharacters) {
			lines.push(line);
			line = name;
		} else {
			line += part;
		}
	}

	if (line.length > 0) {
		lines.push(line);
	}

	return lines;
};

// The level, from left to right: the half-pipe in the parking garage Bygarasjen with a deck on each side and the ramp down to the street, Bryggen with a rail, a ledge, and the gap over the water of Vågen, the stairs down to the fish market, Mormor on her bench, and a quarter pipe at the station of Fløibanen. World heights go up, and the street is at 0.
const quarterRising = (start, radius, base) => x => base + radius - Math.sqrt(Math.max(0, (radius ** 2) - ((x - start) ** 2)));
const quarterFalling = (start, radius, base) => x => base + radius - Math.sqrt(Math.max(0, (radius ** 2) - ((start + radius - x) ** 2)));
const flatAt = level => () => level;

const terrain = [
	{from: 0, to: 40, kind: 'deck', height: flatAt(80)},
	{from: 40, to: 120, kind: 'quarter', height: quarterFalling(40, 80, 0), outward: -1, isGarage: true},
	{from: 120, to: 240, kind: 'floor', height: flatAt(0)},
	{from: 240, to: 320, kind: 'quarter', height: quarterRising(240, 80, 0), outward: 1, isGarage: true},
	{from: 320, to: 380, kind: 'deck', height: flatAt(80)},
	{from: 380, to: 540, kind: 'ramp', height: x => 80 - ((x - 380) * 0.5)},
	{from: 540, to: 850, kind: 'street', height: flatAt(0)},
	{from: 850, to: 930, kind: 'ledge', height: flatAt(14)},
	{from: 930, to: 1060, kind: 'street', height: flatAt(0)},
	{from: 1060, to: 1090, kind: 'kicker', height: x => (x - 1060) * 0.6},
	{from: 1090, to: 1170, kind: 'water', height: flatAt(-60)},
	{from: 1170, to: 1240, kind: 'street', height: flatAt(0)},
	{from: 1240, to: 1300, kind: 'stairs', height: x => -6 * (Math.floor((x - 1240) / 10) + 1)},
	{from: 1300, to: 1480, kind: 'market', height: flatAt(-36)},
	{from: 1480, to: 1508, kind: 'kicker', height: x => -36 + ((x - 1480) * 0.57)},
	{from: 1508, to: 1680, kind: 'market', height: flatAt(-36)},
	{from: 1680, to: 1780, kind: 'ledge', height: flatAt(-22)},
	{from: 1780, to: 1980, kind: 'market', height: flatAt(-36)},
	{from: 1980, to: 2060, kind: 'quarter', height: quarterRising(1980, 80, -36), outward: 1},
	{from: 2060, to: 2100, kind: 'deck', height: flatAt(44)},
];

const levelWidth = 2100;
const waterSurface = -8;
const garageEnd = 560;
const ceiling = 232;

const pieceAt = x => {
	const clamped = clamp(x, 0, levelWidth - 0.001);
	return terrain.find(piece => clamped >= piece.from && clamped < piece.to) ?? terrain.at(-1);
};

const groundAt = x => pieceAt(x).height(clamp(x, 0, levelWidth));

// The slope is measured inside one piece, so the edge of a ledge or a step is not a wall for the skater on top of it.
const slopeAt = x => {
	const piece = pieceAt(x);
	const left = Math.max(piece.from, x - 0.25);
	const right = Math.min(piece.to - 0.001, x + 0.25);
	return right > left ? (piece.height(right) - piece.height(left)) / (right - left) : 0;
};

// The rails and the tops of the ledges, which the skater can grind.
const rails = [
	{id: 'bryggen', x1: 640, y1: 20, x2: 780, y2: 20, kind: 'rail'},
	{id: 'kai', x1: 850, y1: 14, x2: 930, y2: 14, kind: 'ledge'},
	{id: 'handrail', x1: 1232, y1: 22.8, x2: 1304, y2: -20.4, kind: 'rail'},
	{id: 'counter', x1: 1680, y1: -22, x2: 1780, y2: -22, kind: 'ledge'},
];

const railAt = (rail, x) => rail.y1 + ((rail.y2 - rail.y1) * ((x - rail.x1) / (rail.x2 - rail.x1)));

const railDirection = rail => {
	const length = Math.hypot(rail.x2 - rail.x1, rail.y2 - rail.y1);
	return {x: (rail.x2 - rail.x1) / length, y: (rail.y2 - rail.y1) / length, length};
};

const puddles = [
	{from: 980, to: 1010, level: 0},
	{from: 1370, to: 1410, level: -36},
	{from: 1830, to: 1880, level: -36},
];

const mormor = {from: 1552, to: 1588, level: -36, top: -36 + 26};

const letterSpots = [
	{letter: 'S', x: 180, y: 64},
	{letter: 'K', x: 317, y: 136},
	{letter: 'A', x: 712, y: 42},
	{letter: 'T', x: 1130, y: 36},
	{letter: 'E', x: 1570, y: 10},
];

const tapeSpot = {x: 2057, y: 108};

// The named gaps, with the zones to jump from and to. A gap counts both ways, unless it has a direction.
const gaps = {
	transfer: {name: 'Plan 2 Transfer', points: 250},
	'big-air': {name: 'Bygarasjen Big Air', points: 300},
	'garage-ramp': {name: 'Garage Ramp Gap', points: 200},
	'bryggen-rail': {name: 'Hanseatic Rail', points: 200},
	bryggen: {name: 'Bryggen Gap', points: 500},
	stairs: {name: 'Fish Market Stair Set', points: 300},
	handrail: {name: 'Fish Market Handrail', points: 400},
	mormor: {name: 'Over Mormor', points: 350},
	puddle: {name: 'Bergen Puddle Gap', points: 100},
};

const jumpGaps = [
	{id: 'garage-ramp', from: [318, 392], to: [541, 760], direction: 1},
	{id: 'bryggen', from: [960, 1091], to: [1169, 1240]},
	{id: 'stairs', from: [1150, 1239], to: [1300, 1470], direction: 1},
	{id: 'mormor', from: [1420, 1551], to: [1589, 1720]},
	...puddles.map(puddle => ({id: 'puddle', from: [puddle.from - 90, puddle.from], to: [puddle.to, puddle.to + 90]})),
];

const railGaps = {bryggen: 'bryggen-rail', handrail: 'handrail'};

// The tricks: a button and the arrow held when it is pressed, like on the PlayStation.
const flipTricks = {
	none: {name: 'Kickflip', points: 100, roll: 1},
	left: {name: 'Heelflip', points: 100, roll: -1},
	right: {name: 'Pop Shove-It', points: 100, yaw: 1},
	up: {name: 'Impossible', points: 150, pitch: 1},
	down: {name: 'Varial Kickflip', points: 200, roll: 1, yaw: 1},
};

const grabTricks = {
	none: {name: 'Indy', points: 150, hand: 'middle'},
	left: {name: 'Melon', points: 150, hand: 'heel'},
	right: {name: 'Method', points: 200, hand: 'heel', arch: true},
	up: {name: 'Nosegrab', points: 150, hand: 'nose'},
	down: {name: 'Tailgrab', points: 150, hand: 'tail'},
};

const grindTricks = {
	none: {name: '50-50 Grind', points: 100, board: 'flat'},
	left: {name: 'Boardslide', points: 200, board: 'across'},
	right: {name: 'Crooked Grind', points: 200, board: 'nose'},
	up: {name: 'Nosegrind', points: 150, board: 'nose'},
	down: {name: '5-0 Grind', points: 150, board: 'tail'},
};

const spinPoints = [0, 100, 250, 450, 700, 1000];

// Repeating a trick in a run gives less and less, like in the real game, so a run needs many different tricks.
const repeatFactors = [1, 0.75, 0.5, 0.25, 0.1];

const bailLines = ['AU!', 'MAMMA!', 'DET GJORDE VONDT!', 'OOF!', 'NEI NEI NEI!', 'MY KNEE!', 'UFF DA!'];

// The soundtrack: punk rock songs of made-up Bergen bands, with distorted power chords, a bass, and a fast drum beat, made in the browser. Each song is a loop of bars, each bar one chord, as the lowest note of the guitar in MIDI numbers.
const songs = [
	{band: 'Regnfrakk', title: 'Det regner i Bergen', tempo: 176, chords: [40, 40, 48, 50, 40, 40, 48, 50, 45, 45, 48, 50, 40, 43, 45, 47]},
	{band: 'Trond & the Brunost Boys', title: 'Vaffel Thrash', tempo: 196, chords: [45, 45, 41, 43, 45, 45, 41, 43, 38, 38, 41, 43, 45, 41, 43, 40]},
	{band: 'Mormor Strikker', title: 'Pass deg!', tempo: 160, chords: [38, 41, 43, 38, 38, 41, 43, 46, 43, 43, 46, 48, 38, 41, 43, 45]},
];

const midiFrequency = note => 440 * (2 ** ((note - 69) / 12));

// The records from the storage, only when they look right, so an old or broken record does not show “undefined”.
const validBestCombo = value => (Number.isFinite(value?.score) && typeof value.text === 'string' ? value : undefined);
const validLastRun = value => (Number.isFinite(value?.score) && Number.isFinite(value.gaps) && Number.isFinite(value.plasters) && typeof value.letters === 'string' ? value : undefined);

// The combo: the tricks since the skater last stood on the ground, with their points. The multiplier is the number of tricks.
const sumPoints = entries => {
	let total = 0;
	for (const entry of entries) {
		total += entry.points;
	}

	return total;
};

const ragdollStep = 1 / 120;

const houseColors = ['#b8432f', '#e2b33c', '#f1ead8', '#c96e2c', '#8b2f24', '#e8d27a', '#a33a2a'];

const pieceColors = {
	deck: ['#c89a5a', '#8a6236'],
	quarter: ['#d4a868', '#9a7040'],
	floor: ['#a4a4a4', '#7c7c7c'],
	ramp: ['#a4a4a4', '#7c7c7c'],
	street: ['#8c8478', '#6a6258'],
	ledge: ['#d4d4d4', '#9a9a9a'],
	kicker: ['#3d7bd6', '#2a5aa8'],
	stairs: ['#b4ada2', '#8a847a'],
	market: ['#9a948a', '#757068'],
};

// A phone has no mouse and no Space key, but a tap on the screen also starts a run.
const hasNoMouse = matchMedia('(hover: none)').matches;
const startHint = hasNoMouse ? 'TAP HERE' : 'CLICK OR PRESS SPACE';

const keyControls = {ArrowLeft: 'left', ArrowRight: 'right', ArrowUp: 'up', ArrowDown: 'down', ' ': 'ollie', z: 'flip', Z: 'flip', x: 'grab', X: 'grab', c: 'grind', C: 'grind', v: 'special', V: 'special'};

// The distortion of a guitar amplifier, as a curve that squashes the loud parts.
const distortionCurve = amount => {
	const curve = new Float32Array(1024);
	for (let index = 0; index < curve.length; index++) {
		const x = ((index * 2) / curve.length) - 1;
		curve[index] = ((3 + amount) * x * 20 * (Math.PI / 180)) / (Math.PI + (amount * Math.abs(x)));
	}

	return curve;
};

export default class extends GeoCitiesElement {
	#context;
	#loop;
	#state;

	// The skater, set by `resetSkater` at the start and for each run.
	#skater = {};

	// The rain of Bergen, which falls everywhere except in the garage.
	#rain = Array.from({length: 90}, () => ({x: Math.random() * width, y: Math.random() * height, speed: randomBetween(180, 260)}));

	#lastDrawTime = 0;

	// The audio of the element (`sound()`), from the first click on the sound or the music button.
	#audio;
	#isSoundOn = false;
	#roll;
	#noiseCache;

	#songIndex = 0;
	#musicTimer;
	#musicNodes;
	#musicStep = 0;
	#nextNoteTime = 0;

	connected() {
		const {screen, status, sound, music, track, step, start, freeSkate, clear} = this.parts;
		this.#context = screen.getContext('2d');

		this.#state = {
			mode: 'title',
			resultsAt: 0,
			time: 0,
			clock: 0,
			runTime: runSeconds,
			isTimeUp: false,
			timeUpAt: 0,
			score: 0,
			combo: undefined,
			special: 0,
			uses: new Map(),
			letters: new Set(),
			hasTape: false,
			runGaps: new Set(),
			plasters: 0,
			bestRunCombo: 0,
			held: {},
			pressedAt: {},
			lastInputAt: 0,
			presses: [],
			messages: [],
			particles: [],
			ripples: [],
			stepMode: this.reducedMotion,
			camera: {x: 0, y: 0},
			cheer: undefined,
			mormorMood: {mood: 'knit', until: 0},
			highScore: this.stored('highScore', 0),
			bestCombo: validBestCombo(this.stored('bestCombo')),
			foundGaps: new Set(this.stored('gaps', []).filter(id => Object.hasOwn(gaps, id))),
			foundTape: this.stored('tape', false),
			lastRun: validLastRun(this.stored('lastRun')),
		};

		// The loop runs while the screen is on the screen and the tab is visible. In step mode it stops while no button is held, and with reduced motion the title and the results are drawn once, standing still. When it stops, it draws the frame where it stands, with the notice that step mode waits, and the wheels stop rolling, also for a screen that scrolled away or a hidden tab.
		this.#loop = this.loop(seconds => {
			this.#step(seconds);
		}, {
			while: () => (this.#isPlaying() ? !this.#isPaused() : !this.reducedMotion),
			stopped: () => {
				this.#draw();
				this.#quiet();
			},
		});

		// The music only plays when the music button is on, and it does not need to play the missed notes of a hidden tab.
		this.on(document, 'visibilitychange', () => {
			const context = this.#audio?.context;
			if (!context) {
				return;
			}

			if (document.visibilityState === 'hidden') {
				context.suspend();
			} else if (this.#isSoundOn || this.#isMusicPlaying) {
				context.resume();
			}
		});

		this.on(screen, 'keydown', event => {
			if (event.ctrlKey || event.metaKey || event.altKey) {
				return;
			}

			if (event.key === 'Enter' && !this.#isPlaying()) {
				event.preventDefault();
				this.#startFromScreen();
				return;
			}

			const control = keyControls[event.key];
			if (!control) {
				return;
			}

			event.preventDefault();
			if (!event.repeat) {
				this.#press(control);
			}
		});

		this.on(screen, 'keyup', event => {
			const control = keyControls[event.key];
			if (control) {
				this.#release(control);
			}
		});

		// A click or a tap on the title or the results starts a run, so the first try does not need the button below the controls.
		this.on(screen, 'click', () => {
			if (!this.#isPlaying()) {
				this.#startFromScreen();
			}
		});

		// Leaving the screen lets go of every key, without the ollie that letting go of Space would pop.
		this.on(screen, 'blur', () => {
			this.#skater.crouchStart = undefined;
			this.#releaseAll();
		});

		// The buttons of the sound, the music, and the step mode keep the keys on the screen during a run.
		for (const button of [sound, music, track, step]) {
			this.on(button, 'click', () => {
				if (this.#isPlaying()) {
					screen.focus({preventScroll: true});
				}
			});
		}

		for (const button of this.querySelectorAll('[data-skater-control]')) {
			const control = button.dataset.skaterControl;
			this.on(button, 'pointerdown', event => {
				if (event.button !== 0) {
					return;
				}

				event.preventDefault();
				button.setPointerCapture(event.pointerId);
				this.#press(control);
			});

			for (const type of ['pointerup', 'pointercancel', 'lostpointercapture']) {
				this.on(button, type, () => {
					this.#release(control);
				});
			}

			// A click without a pointer, like from a screen reader, is a press and a release.
			this.on(button, 'click', event => {
				if (event.detail === 0) {
					this.#press(control);
					this.#release(control);
				}
			});

			// A press of the button keeps the focus where it is, so the keys still work on the screen.
			this.on(button, 'mousedown', event => {
				event.preventDefault();
			});

			this.on(button, 'contextmenu', event => {
				event.preventDefault();
			});
		}

		this.on(sound, 'click', () => {
			this.#setSound(!this.#isSoundOn);
			if (this.#isSoundOn) {
				this.#effects.pop();
			}
		});

		this.on(music, 'click', () => {
			if (this.#isMusicPlaying) {
				this.#stopMusic();
			} else {
				this.#startMusic();
			}

			this.#showMusic();
		});

		this.on(track, 'click', () => {
			this.#songIndex = (this.#songIndex + 1) % songs.length;
			if (this.#isMusicPlaying) {
				this.#startMusic();
			}

			this.#showMusic();
		});

		this.on(step, 'click', () => {
			this.#setStepMode(!this.#state.stepMode);
			this.say(this.#state.stepMode ? 'Step mode: the run only moves while you hold a button.' : 'Step mode off: the run moves by itself.');
		});

		this.on(start, 'click', () => {
			this.#startRun(true);
		});

		this.on(freeSkate, 'click', () => {
			this.#startRun(false);
		});

		this.on(clear, 'click', () => {
			if (!confirm('Clear the high score, the best combo, the last run, the secret tape, and all the gaps found?')) {
				return;
			}

			const state = this.#state;
			state.highScore = 0;
			state.bestCombo = undefined;
			state.lastRun = undefined;
			state.foundGaps = new Set();
			state.foundTape = false;
			for (const key of ['highScore', 'bestCombo', 'lastRun', 'gaps', 'tape']) {
				this.store(key, undefined);
			}

			this.#showRecords();
			this.#showGaps();
			this.say('The records are cleared, like a fresh memory card.');
			this.#draw();
		});

		// The first line of the status says tap on a phone, like the screen does.
		if (hasNoMouse) {
			status.textContent = 'Tap the screen or ▶ Start for a 2‑minute run. Free Skate has no clock.';
		}

		this.#showRecords();
		this.#showGaps();
		this.#showMusic();
		this.#showStepMode();
		this.#resetSkater();
		this.#updateCamera(0);
		this.#draw();
	}

	disconnected() {
		this.#stopMusic();
		this.#quiet();
	}

	// The game runs only while its screen is on the screen, not while only its buttons or its records are.
	get visibilityTarget() {
		return this.parts.screen;
	}

	// A change of the reduced motion setting while the page is open also turns step mode on or off.
	reducedMotionChanged(isReduced) {
		this.#setStepMode(isReduced);
	}

	// Another toy of the page started a tune, so the soundtrack stops, and it tells the page, so the screen saver and the Furby know.
	musicStopped() {
		if (this.#isMusicPlaying) {
			this.#stopMusic();
			this.#showMusic();
		}
	}

	// The sound of the game, made in the browser. It is off until the visitor presses the sound button. The rolling of the wheels and the grind are one noise that changes with the speed.
	#startAudio() {
		this.#audio ??= this.sound();
		this.#audio?.context.resume().catch(() => {});
		return this.#audio !== undefined;
	}

	get #isSoundReady() {
		return this.#isSoundOn && this.#audio !== undefined && this.#audio.context.state !== 'closed';
	}

	// The effects play only while the sound is on. The music plays into its own nodes, and has its own button.
	#canPlay(destination) {
		return destination ? this.#audio !== undefined : this.#isSoundReady;
	}

	// One second of noise, made once, which every noise plays a part of.
	get #whiteNoise() {
		if (!this.#noiseCache) {
			const {sampleRate} = this.#audio.context;
			this.#noiseCache = new AudioBuffer({length: sampleRate, sampleRate});
			const data = this.#noiseCache.getChannelData(0);
			for (let index = 0; index < data.length; index++) {
				data[index] = (Math.random() * 2) - 1;
			}
		}

		return this.#noiseCache;
	}

	#tone(frequency, duration = 0.1, {type = 'square', volume = 0.05, when = 0, slideTo, detune = 0, destination} = {}) {
		if (!this.#canPlay(destination)) {
			return;
		}

		const {context, output} = this.#audio;
		const start = context.currentTime + Math.max(0, when);
		const oscillator = new OscillatorNode(context, {type, frequency, detune});
		if (slideTo) {
			// The slide starts with the note, also for a note that is planned ahead, like a kick of the drums.
			oscillator.frequency.setValueAtTime(frequency, start);
			oscillator.frequency.exponentialRampToValueAtTime(slideTo, start + duration);
		}

		const gain = new GainNode(context, {gain: 0});
		gain.gain.setValueAtTime(0, start);
		gain.gain.linearRampToValueAtTime(volume, start + 0.006);
		gain.gain.exponentialRampToValueAtTime(0.0001, start + duration);
		oscillator.connect(gain).connect(destination ?? output);
		oscillator.start(start);
		oscillator.stop(start + duration + 0.02);
	}

	#noise(duration = 0.2, {volume = 0.08, frequency = 1200, type = 'bandpass', q = 0.7, when = 0, destination} = {}) {
		if (!this.#canPlay(destination)) {
			return;
		}

		const {context, output} = this.#audio;
		const start = context.currentTime + Math.max(0, when);
		const source = new AudioBufferSourceNode(context, {buffer: this.#whiteNoise});
		const filter = new BiquadFilterNode(context, {type, frequency, Q: q});
		const gain = new GainNode(context, {gain: 0});
		gain.gain.setValueAtTime(0, start);
		gain.gain.linearRampToValueAtTime(volume, start + 0.004);
		gain.gain.exponentialRampToValueAtTime(0.0001, start + duration);
		source.connect(filter).connect(gain).connect(destination ?? output);
		source.start(start, Math.random() * (1 - Math.min(duration, 0.9)), duration + 0.02);
	}

	#effects = {
		// The pop of the tail on the street.
		pop: () => {
			this.#noise(0.05, {volume: 0.25, frequency: 2500, q: 1.5});
			this.#tone(180, 0.08, {type: 'triangle', volume: 0.12, slideTo: 70});
		},
		land: () => {
			this.#noise(0.09, {volume: 0.3, frequency: 400, q: 0.8});
			this.#tone(110, 0.1, {type: 'triangle', volume: 0.15, slideTo: 50});
		},
		push: () => {
			this.#noise(0.14, {volume: 0.06, frequency: 700, q: 0.6});
		},
		clack: () => {
			this.#noise(0.04, {volume: 0.18, frequency: 1800, q: 2});
		},
		grind: () => {
			this.#tone(1400, 0.12, {type: 'square', volume: 0.03, slideTo: 1100});
			this.#noise(0.08, {volume: 0.15, frequency: 3200, q: 4});
		},
		// The bail of the real game: a thud, a crunch, and a sad little voice.
		bail: () => {
			this.#tone(90, 0.3, {type: 'sine', volume: 0.35, slideTo: 35});
			this.#noise(0.35, {volume: 0.3, frequency: 600, q: 0.6, when: 0.02});
			this.#noise(0.15, {volume: 0.15, frequency: 2600, q: 1, when: 0.12});
			this.#tone(330, 0.45, {type: 'sawtooth', volume: 0.05, slideTo: 140, when: 0.05});
		},
		splash: () => {
			this.#noise(0.6, {volume: 0.25, frequency: 700, type: 'lowpass', q: 0.5});
			this.#noise(0.3, {volume: 0.1, frequency: 3000, q: 0.8, when: 0.05});
		},
		puddle: () => {
			this.#noise(0.25, {volume: 0.1, frequency: 1500, q: 0.7});
		},
		gap: () => {
			this.#tone(880, 0.1, {volume: 0.06});
			this.#tone(1320, 0.18, {volume: 0.06, when: 0.08});
		},
		bank: () => {
			for (const [index, frequency] of [523, 659, 784].entries()) {
				this.#tone(frequency, 0.12, {type: 'triangle', volume: 0.1, when: index * 0.05});
			}
		},
		letter: () => {
			for (const [index, frequency] of [784, 988, 1175, 1568].entries()) {
				this.#tone(frequency, 0.1, {type: 'square', volume: 0.05, when: index * 0.05});
			}
		},
		special: () => {
			this.#tone(300, 0.5, {type: 'sawtooth', volume: 0.06, slideTo: 1500});
			this.#tone(450, 0.5, {type: 'square', volume: 0.04, slideTo: 2200, when: 0.05});
		},
		buzz: () => {
			this.#tone(120, 0.18, {type: 'square', volume: 0.06});
		},
		tick: () => {
			this.#tone(1000, 0.05, {type: 'square', volume: 0.04});
		},
		horn: () => {
			this.#tone(220, 0.6, {type: 'sawtooth', volume: 0.08});
			this.#tone(277, 0.6, {type: 'sawtooth', volume: 0.06});
		},
	};

	// The wheels on the street, and the scrape of a grind, as one looping noise.
	#setRolling(volume, frequency, q = 0.8) {
		if (!this.#isSoundReady) {
			return;
		}

		const {context, output} = this.#audio;
		if (!this.#roll) {
			const source = new AudioBufferSourceNode(context, {buffer: this.#whiteNoise, loop: true});
			const filter = new BiquadFilterNode(context, {type: 'bandpass', frequency: 400, Q: 0.8});
			const gain = new GainNode(context, {gain: 0});
			source.connect(filter).connect(gain).connect(output);
			source.start();
			this.#roll = {source, filter, gain};
		}

		const now = context.currentTime;
		this.#roll.gain.gain.setTargetAtTime(volume, now, 0.04);
		this.#roll.filter.frequency.setTargetAtTime(frequency, now, 0.04);
		this.#roll.filter.Q.setTargetAtTime(q, now, 0.04);
	}

	#quiet() {
		if (this.#roll && this.#audio) {
			this.#roll.gain.gain.setTargetAtTime(0, this.#audio.context.currentTime, 0.03);
		}
	}

	get #isMusicPlaying() {
		return this.#musicTimer !== undefined;
	}

	get #song() {
		return songs[this.#songIndex];
	}

	#startMusic() {
		if (!this.#startAudio()) {
			return;
		}

		this.#stopMusic({isQuiet: true});
		const {context: audio, output} = this.#audio;
		const master = new GainNode(audio, {gain: 0.2});
		master.connect(output);
		const guitar = new GainNode(audio, {gain: 0.5});
		const shaper = new WaveShaperNode(audio, {curve: distortionCurve(300), oversample: '4x'});
		const cabinet = new BiquadFilterNode(audio, {type: 'lowpass', frequency: 3200, Q: 0.7});
		const body = new BiquadFilterNode(audio, {type: 'peaking', frequency: 700, Q: 1, gain: 4});
		guitar.connect(shaper).connect(cabinet).connect(body).connect(master);
		const bass = new BiquadFilterNode(audio, {type: 'lowpass', frequency: 700, Q: 0.8});
		bass.connect(master);
		this.#musicNodes = {master, guitar, bass};
		this.#musicStep = 0;
		this.#nextNoteTime = audio.currentTime + 0.1;
		this.#musicTimer = setInterval(() => {
			this.#scheduleMusic();
		}, 40);
		this.#scheduleMusic();
		this.music(true);
	}

	#scheduleMusic() {
		const audio = this.#audio?.context;
		if (!audio || !this.#musicNodes) {
			return;
		}

		// A tab that was hidden for a while does not play the missed notes all at once.
		if (this.#nextNoteTime < audio.currentTime - 0.2) {
			this.#nextNoteTime = audio.currentTime + 0.05;
		}

		const sixteenth = 60 / this.#song.tempo / 4;
		while (this.#nextNoteTime < audio.currentTime + 0.15) {
			this.#playMusicStep(this.#musicStep, this.#nextNoteTime, sixteenth);
			this.#nextNoteTime += sixteenth;
			this.#musicStep++;
		}
	}

	#playMusicStep(step, time, sixteenth) {
		const {chords} = this.#song;
		const bar = Math.floor(step / 16) % chords.length;
		const beat = step % 16;
		const isIntro = Math.floor(step / 16) < 2;
		const isFill = bar === chords.length - 1 && beat >= 8;
		const root = chords[bar];
		const when = time - this.#audio.context.currentTime;

		// The drums: a kick on the beats and a snare between them, the beat of every skate punk song, with a fill at the end of the loop and a crash at the start.
		if (isFill) {
			this.#snare(when, 0.9);
		} else {
			if (beat % 4 === 0) {
				this.#kick(when);
			}

			if (beat % 4 === 2 && !isIntro) {
				this.#snare(when, 1);
			}

			if (beat % 2 === 0) {
				this.#hat(when);
			}
		}

		if (beat === 0 && (bar === 0 || bar === 8) && !isIntro) {
			this.#crash(when);
		}

		// The guitar and the bass on every eighth, muted in the intro.
		if (beat % 2 === 0) {
			const length = isIntro ? sixteenth * 0.9 : sixteenth * 1.9;
			for (const note of [root, root + 7, root + 12]) {
				for (const detune of [-7, 7]) {
					this.#tone(midiFrequency(note), length, {type: 'sawtooth', volume: 0.06, when, destination: this.#musicNodes.guitar, detune});
				}
			}

			this.#tone(midiFrequency(root - 12), sixteenth * 1.8, {type: 'sawtooth', volume: 0.35, when, destination: this.#musicNodes.bass});
		}
	}

	#kick(when) {
		this.#tone(150, 0.14, {type: 'sine', volume: 0.9, slideTo: 40, when, destination: this.#musicNodes.master});
	}

	#snare(when, volume) {
		this.#noise(0.12, {volume: 0.5 * volume, frequency: 1900, q: 0.6, when, destination: this.#musicNodes.master});
		this.#tone(190, 0.06, {type: 'triangle', volume: 0.3 * volume, when, destination: this.#musicNodes.master});
	}

	#hat(when) {
		this.#noise(0.03, {volume: 0.18, frequency: 8000, type: 'highpass', q: 0.5, when, destination: this.#musicNodes.master});
	}

	#crash(when) {
		this.#noise(0.9, {volume: 0.2, frequency: 6000, type: 'highpass', q: 0.4, when, destination: this.#musicNodes.master});
	}

	#stopMusic({isQuiet = false} = {}) {
		if (this.#musicTimer === undefined) {
			return;
		}

		clearInterval(this.#musicTimer);
		this.#musicTimer = undefined;
		const {master} = this.#musicNodes;
		this.#musicNodes = undefined;
		try {
			master.gain.setTargetAtTime(0, this.#audio.context.currentTime, 0.05);
			setTimeout(() => {
				master.disconnect();
			}, 500);
		} catch {}

		if (!isQuiet) {
			this.music(false);
		}
	}

	// Draws text in the pixel font, at a whole pixel, with a scale for bigger letters, and a dark shadow so it shows on any background. The alignment is `left`, `center`, or `right`.
	#drawText(text, x, y, color, {scale = 1, align = 'left', shadow = 'rgba(0, 0, 0, 0.75)'} = {}) {
		const characters = [...String(text).toUpperCase()];
		const textSize = textWidth(text, scale);
		const left = Math.round(align === 'center' ? x - (textSize / 2) : (align === 'right' ? x - textSize : x));
		const passes = shadow ? [[shadow, scale > 1 ? 2 : 1], [color, 0]] : [[color, 0]];
		for (const [fill, offset] of passes) {
			this.#context.fillStyle = fill;
			let characterLeft = left;
			for (const character of characters) {
				const rows = pixelFont[character] ?? pixelFont['?'];
				for (const [row, bits] of rows.entries()) {
					for (let column = 0; column < 3; column++) {
						if (bits & (4 >> column)) {
							this.#context.fillRect(characterLeft + (column * scale) + offset, Math.round(y) + (row * scale) + offset, scale, scale);
						}
					}
				}

				characterLeft += 4 * scale;
			}
		}
	}

	#fillShape(color, x, y, shapeWidth, shapeHeight) {
		this.#context.fillStyle = color;
		this.#context.fillRect(Math.round(x), Math.round(y), Math.round(shapeWidth), Math.round(shapeHeight));
	}

	#fillCircle(color, x, y, radius) {
		this.#context.fillStyle = color;
		this.#context.beginPath();
		this.#context.arc(x, y, Math.max(radius, 0.1), 0, Math.PI * 2);
		this.#context.fill();
	}

	#fillPolygon(color, points) {
		this.#context.fillStyle = color;
		this.#context.beginPath();
		for (const [x, y] of points) {
			this.#context.lineTo(x, y);
		}

		this.#context.closePath();
		this.#context.fill();
	}

	#strokeLine(color, lineWidth, points) {
		this.#context.strokeStyle = color;
		this.#context.lineWidth = lineWidth;
		this.#context.lineCap = 'round';
		this.#context.lineJoin = 'round';
		this.#context.beginPath();
		for (const [x, y] of points) {
			this.#context.lineTo(x, y);
		}

		this.#context.stroke();
	}

	#showMusic() {
		const song = this.#song;
		this.parts.music.textContent = this.#isMusicPlaying ? '🎸 Music On' : '🎸 Music Off';
		this.parts.music.setAttribute('aria-pressed', String(this.#isMusicPlaying));
		this.parts.nowPlaying.textContent = this.#isMusicPlaying ? `♪ ${song.band}: “${song.title}” (${this.#songIndex + 1}/${songs.length})` : `♪ STEREO: OFF. NEXT UP: ${song.band.toUpperCase()}`;
	}

	#isPlaying() {
		return this.#state.mode === 'run' || this.#state.mode === 'free';
	}

	#isHeld(control) {
		return Boolean(this.#state.held[control]);
	}

	// The arrow held for a trick. Up and down win over left and right.
	#heldDirection() {
		return ['up', 'down', 'left', 'right'].find(control => this.#isHeld(control)) ?? 'none';
	}

	// The messages in the middle of the screen, like the name of a gap or “BAIL!”.
	#showMessage(text, color = '#ffdd00', {duration = 1.6, scale = 2} = {}) {
		this.#state.messages.push({text, color, until: this.#state.time + duration, scale});
		if (this.#state.messages.length > 4) {
			this.#state.messages.shift();
		}
	}

	#addParticles(x, y, count, {color = '#ffffff', speed = 60, up = 40, life = 0.6, size = 1, gravity: fall = gravity * 0.6} = {}) {
		if (this.reducedMotion) {
			return;
		}

		for (let index = 0; index < count; index++) {
			this.#state.particles.push({x, y, vx: randomBetween(-speed, speed), vy: randomBetween(0, up) + (up * 0.3), life, age: 0, color: typeof color === 'string' ? color : randomItem(color), size, fall});
		}

		if (this.#state.particles.length > 300) {
			this.#state.particles.splice(0, this.#state.particles.length - 300);
		}
	}

	#addToCombo(name, points, key = name) {
		const uses = this.#state.uses.get(key) ?? 0;
		this.#state.uses.set(key, uses + 1);
		const factor = repeatFactors[Math.min(uses, repeatFactors.length - 1)];
		this.#state.combo ??= {entries: []};
		const entry = {name, points: points * factor, factor};
		this.#state.combo.entries.push(entry);
		this.#addSpecial(points * factor);
		return entry;
	}

	#addSpecial(points) {
		const wasFull = this.#state.special >= 1;
		this.#state.special = Math.min(1, this.#state.special + (points / 1800));
		if (!wasFull && this.#state.special >= 1) {
			this.#showMessage('SPECIAL!', '#ff66ff');
			this.#effects.special();
		}
	}

	// Points that grow while a trick lasts, like a grind, a manual, or a held grab.
	#growEntry(entry, pointsPerSecond, seconds) {
		const points = pointsPerSecond * seconds * entry.factor;
		entry.points += points;
		this.#addSpecial(points);
	}

	#bankCombo() {
		const combo = this.#state.combo;
		this.#state.combo = undefined;
		if (!combo || combo.entries.length === 0) {
			return;
		}

		const base = sumPoints(combo.entries);
		const multiplier = combo.entries.length;
		const total = Math.round(base) * multiplier;
		if (total <= 0) {
			return;
		}

		this.#state.score += total;
		this.#state.bestRunCombo = Math.max(this.#state.bestRunCombo, total);
		this.#effects.bank();
		this.#showMessage(`+${formatNumber(total)}`, '#66ff66');
		const names = combo.entries.map(entry => entry.name);
		this.say(`${names.join(' + ')}: ${formatNumber(base)} × ${multiplier} = ${formatNumber(total)} points!`);
		if (total >= 3000) {
			this.#state.cheer = {text: randomItem(['TROND: SINNSYKT!', 'TROND: RÅTT!', 'TROND: DID YOU SEE THAT?!', 'TROND: LEGENDARISK!']), until: this.#state.time + 2.2};
		}

		if (!this.#state.bestCombo || total > this.#state.bestCombo.score) {
			this.#state.bestCombo = {score: total, text: names.join(' + ')};
			this.store('bestCombo', this.#state.bestCombo);
			this.#showRecords();
			if (total >= 1000) {
				this.#showMessage('NEW BEST COMBO!', '#66ffff');
			}
		}
	}

	#awardGap(id) {
		const gap = gaps[id];
		if (!gap) {
			return;
		}

		this.#addToCombo(gap.name, gap.points, `gap-${id}`);
		this.#state.runGaps.add(id);
		this.#showMessage(`${gap.name}!`, '#ffdd00', {duration: 2});
		this.#effects.gap();
		if (!this.#state.foundGaps.has(id)) {
			this.#state.foundGaps.add(id);
			this.store('gaps', [...this.#state.foundGaps]);
			this.#showGaps();
			this.toast(`🛹 New gap found: ${gap.name}!`);
			if (this.#state.foundGaps.size === Object.keys(gaps).length) {
				this.toast('🛹 All the gaps of Bergen! You are a pro this.#skater now.');
				this.celebrate();
			}
		}

		if (id === 'mormor') {
			this.#state.mormorMood = {mood: 'cheer', until: this.#state.time + 2.5};
		}
	}

	// The skater leaves the ground, for an ollie, a ramp, or the edge of something.
	#newAir({isVert = false, outward = 0, fromRail = false} = {}) {
		return {
			isVert,
			outward,
			fromRail,
			startedAt: this.#state.clock,
			spinsFrom: this.#skater.crouchStart ?? this.#state.clock,
			startY: this.#skater.y,
			peak: this.#skater.y,
			tricks: [],
			flip: undefined,
			grab: undefined,
			spinDirection: 0,
			spinTarget: undefined,
			special900: undefined,
			manualQueued: undefined,
			hasOllied: false,
			isGarage: false,
		};
	}

	#leaveGround(vx, vy, options = {}) {
		if (this.#skater.mode === 'ground' || this.#skater.mode === 'manual') {
			this.#skater.takeoffX = this.#skater.x;
		}

		this.#skater.mode = 'air';
		this.#skater.manual = undefined;
		this.#skater.grind = undefined;
		this.#skater.vx = vx;
		this.#skater.vy = vy;
		this.#skater.air = this.#newAir(options);
		this.#skater.crouchStart = undefined;
	}

	#popOllie(power) {
		const slope = slopeAt(this.#skater.x);
		const length = Math.hypot(1, slope);
		const tangentX = 1 / length;
		const tangentY = slope / length;
		const speed = this.#skater.speed;
		this.#leaveGround((speed * tangentX) - (power * tangentY * 0.5), (speed * tangentY) + (power * tangentX));
		this.#skater.air.hasOllied = true;
		this.#effects.pop();
		this.#addParticles(this.#skater.x, this.#skater.y, 4, {color: '#cccccc', speed: 30, up: 10, life: 0.3});
	}

	#ollieFromCrouch() {
		const held = clamp((this.#state.clock - this.#skater.crouchStart) / 0.45, 0, 1);
		this.#popOllie(140 + (100 * held));
	}

	#launchVert(piece) {
		this.#skater.takeoffX = this.#skater.x;
		const speed = Math.abs(this.#skater.speed);
		this.#skater.mode = 'air';
		this.#skater.vx = 0;
		this.#skater.vy = speed;
		this.#skater.air = this.#newAir({isVert: true, outward: piece.outward});
		this.#skater.air.isGarage = Boolean(piece.isGarage);
		this.#skater.manual = undefined;
	}

	#bail(reason) {
		if (this.#skater.mode === 'bail') {
			return;
		}

		let vx = this.#skater.vx;
		let vy = this.#skater.vy;
		if (this.#skater.mode === 'ground' || this.#skater.mode === 'manual') {
			const slope = slopeAt(this.#skater.x);
			const length = Math.hypot(1, slope);
			vx = this.#skater.speed / length;
			vy = (this.#skater.speed * slope) / length;
		} else if (this.#skater.mode === 'grind') {
			const direction = railDirection(this.#skater.grind.rail);
			vx = this.#skater.grind.speed * direction.x;
			vy = this.#skater.grind.speed * direction.y;
		}

		this.#skater.mode = 'bail';
		this.#skater.air = undefined;
		this.#skater.grind = undefined;
		this.#skater.manual = undefined;
		this.#skater.crouchStart = undefined;
		this.#skater.ragdoll = this.#makeRagdoll(vx, vy);
		this.#state.combo = undefined;
		this.#state.special = 0;
		this.#state.plasters++;
		this.#effects.bail();
		const line = randomItem(bailLines);
		this.#showMessage('BAIL!', '#ff3333', {duration: 1.8, scale: 3});
		this.#showMessage(line, '#ffffff', {duration: 1.8});
		this.say(`Bail! ${reason} ${line[0] + line.slice(1).toLowerCase()} That is plaster number ${this.#state.plasters} from Mamma.`);
	}

	// The ragdoll of a bail: a few points joined by sticks that fall and bounce on the ground, and the board flies away by itself.
	#makeRagdoll(vx, vy) {
		const angle = this.#skater.angle;
		const cosine = Math.cos(angle);
		const sine = Math.sin(angle);
		const place = (localX, localY) => {
			const x = this.#skater.x + (localX * cosine) - (localY * sine);
			const y = this.#skater.y + (localX * sine) + (localY * cosine);
			const kick = randomBetween(-30, 30);
			return {x, y, oldX: x - ((vx + kick) / 120), oldY: y - ((vy + 60 + randomBetween(0, 60)) / 120)};
		};

		const points = {
			head: place(0, 24),
			chest: place(0, 17),
			hip: place(0, 11),
			handFront: place(5, 14),
			handBack: place(-5, 14),
			footFront: place(3, 2),
			footBack: place(-3, 2),
		};

		const sticks = [['head', 'chest', 6], ['chest', 'hip', 6], ['chest', 'handFront', 8], ['chest', 'handBack', 8], ['hip', 'footFront', 10], ['hip', 'footBack', 10], ['head', 'hip', 12]];
		return {
			points,
			sticks,
			board: {x: this.#skater.x, y: this.#skater.y + 2, vx: vx * 1.2, vy: Math.max(vy, 0) + 120, angle: 0, turn: randomBetween(8, 14) * (Math.random() < 0.5 ? -1 : 1)},
			startedAt: this.#state.clock,
			inWater: false,
			pending: 0,
		};
	}

	#updateRagdoll(seconds) {
		const ragdoll = this.#skater.ragdoll;
		for (const point of Object.values(ragdoll.points)) {
			const velocityX = (point.x - point.oldX) * 0.995;
			const velocityY = (point.y - point.oldY) * 0.995;
			point.oldX = point.x;
			point.oldY = point.y;
			point.x += velocityX;
			point.y += velocityY - (gravity * seconds * seconds);
			point.x = clamp(point.x, 2, levelWidth - 2);
			const ground = pieceAt(point.x).kind === 'water' ? waterSurface - 20 : groundAt(point.x);
			if (point.y < ground) {
				point.y = ground;
				// The ground stops the fall, and rubs the skater to a stop.
				point.oldY = point.y + ((velocityY) * 0.35);
				point.oldX = point.x - (velocityX * 0.6);
			}
		}

		for (let iteration = 0; iteration < 4; iteration++) {
			for (const [first, second, length] of ragdoll.sticks) {
				const pointA = ragdoll.points[first];
				const pointB = ragdoll.points[second];
				const distanceX = pointB.x - pointA.x;
				const distanceY = pointB.y - pointA.y;
				const distance = Math.hypot(distanceX, distanceY) || 0.001;
				const difference = (distance - length) / distance / 2;
				pointA.x += distanceX * difference;
				pointA.y += distanceY * difference;
				pointB.x -= distanceX * difference;
				pointB.y -= distanceY * difference;
			}
		}

		const {board} = ragdoll;
		board.vy -= gravity * seconds;
		board.x = clamp(board.x + (board.vx * seconds), 2, levelWidth - 2);
		board.y += board.vy * seconds;
		board.angle += board.turn * seconds;
		const boardGround = pieceAt(board.x).kind === 'water' ? waterSurface - 4 : groundAt(board.x);
		if (board.y < boardGround) {
			board.y = boardGround;
			board.vy = Math.abs(board.vy) * 0.35;
			board.vx *= 0.7;
			board.turn *= 0.6;
			if (Math.abs(board.vy) > 40) {
				this.#effects.clack();
			}
		}

		const hip = ragdoll.points.hip;
		if (!ragdoll.inWater && pieceAt(hip.x).kind === 'water' && hip.y < waterSurface) {
			ragdoll.inWater = true;
			this.#effects.splash();
			this.#addParticles(hip.x, waterSurface, 24, {color: ['#cfe8ff', '#8fc0ef', '#ffffff'], speed: 70, up: 120, life: 0.9});
		}

		if (this.#state.clock - ragdoll.startedAt > 1.7) {
			this.#getUp();
		}
	}

	// After a bail the skater gets up where he fell, or at a safe spot near it, like out of the water or off the stairs.
	#getUp() {
		let x = clamp(this.#skater.ragdoll.points.hip.x, 8, levelWidth - 8);
		const piece = pieceAt(x);
		if (piece.kind === 'water') {
			x = x > 1130 ? 1180 : 1045;
		} else if (piece.kind === 'stairs') {
			x = 1310;
		} else if (piece.kind === 'quarter') {
			x = piece.outward < 0 ? piece.to + 6 : piece.from - 6;
		} else if (piece.kind === 'kicker') {
			x = piece.from - 6;
		}

		if (x > mormor.from - 8 && x < mormor.to + 8) {
			x = mormor.to + 10;
		}

		this.#skater.ragdoll = undefined;
		this.#skater.mode = 'ground';
		this.#skater.x = x;
		this.#skater.y = groundAt(x);
		this.#skater.speed = 0;
		this.#skater.vx = 0;
		this.#skater.vy = 0;
		this.#skater.spin = 0;
		this.#skater.angle = 0;
		this.#skater.takeoffX = undefined;
	}

	#finishSpin() {
		const air = this.#skater.air;
		const halves = Math.round(Math.abs(this.#skater.spin) / 180);
		if (halves > 0) {
			const degrees = halves * 180;
			const side = Math.sign(this.#skater.spin) === this.#skater.facing ? 'FS' : 'BS';
			const points = spinPoints[Math.min(halves, spinPoints.length - 1)] + (Math.max(0, halves - spinPoints.length + 1) * 300);
			const [first] = air.tricks;
			if (air.special900) {
				// The 900 says its spin in its name.
			} else if (first) {
				first.name = `${side} ${degrees} ${first.name}`;
				first.points += points * first.factor;
				this.#addSpecial(points * first.factor);
			} else {
				this.#addToCombo(`${side} ${degrees}${air.isVert ? ' Air' : ''}`, points, `spin-${degrees}`);
			}
		}

		// A half turn means the skater now rides the other way round.
		if (halves % 2 === 1) {
			this.#skater.facing *= -1;
		}

		this.#skater.spin = 0;
	}

	// Whether the skater lands well: straight, and not in the middle of a flip or The 900.
	#landingProblem() {
		const air = this.#skater.air;
		const remainder = ((this.#skater.spin % 180) + 180) % 180;
		const crooked = Math.min(remainder, 180 - remainder);
		if (air.special900 && !air.special900.isDone) {
			return 'The 900 needs more air.';
		}

		if (air.flip && this.#state.clock - air.flip.startedAt < air.flip.duration * 0.85) {
			return `Landed in the middle of the ${air.flip.name}.`;
		}

		if (crooked > 32) {
			return 'Landed sideways.';
		}

		return undefined;
	}

	#checkJumpGaps(landingX) {
		const takeoffX = this.#skater.takeoffX;
		if (takeoffX === undefined) {
			return;
		}

		const isIn = (x, [from, to]) => x >= from && x <= to;
		const awarded = new Set();
		for (const gap of jumpGaps) {
			if (awarded.has(gap.id)) {
				continue;
			}

			const forward = isIn(takeoffX, gap.from) && isIn(landingX, gap.to);
			const backward = gap.direction === undefined && isIn(takeoffX, gap.to) && isIn(landingX, gap.from);
			if (forward || backward) {
				awarded.add(gap.id);
				this.#awardGap(gap.id);
			}
		}
	}

	#land(x, ground) {
		const air = this.#skater.air;
		const problem = this.#landingProblem();
		this.#skater.x = x;
		this.#skater.y = ground;
		if (problem) {
			this.#bail(problem);
			return;
		}

		const slope = slopeAt(x);
		const length = Math.hypot(1, slope);
		const along = ((this.#skater.vx) + (this.#skater.vy * slope)) / length;
		if (air.grab) {
			air.grab.releasedAt ??= this.#state.clock;
		}

		this.#finishSpin();
		if (air.isVert && air.isGarage && air.peak > 80 + 48) {
			this.#awardGap('big-air');
		}

		// Out of the half-pipe, onto a deck or the ramp down.
		if (air.isVert && air.isGarage && pieceAt(x).kind !== 'quarter') {
			this.#awardGap('transfer');
		}

		this.#checkJumpGaps(x);
		this.#skater.takeoffX = undefined;
		this.#skater.mode = 'ground';
		this.#skater.speed = clamp(along, -topSpeed, topSpeed);
		this.#skater.angle = Math.atan(slope);
		this.#skater.air = undefined;
		this.#effects.land();
		this.#addParticles(x, ground, 5, {color: '#bbbbbb', speed: 40, up: 15, life: 0.35});
		const queued = air.manualQueued;
		if (queued && this.#state.clock - queued.at < 0.6 && this.#state.combo) {
			this.#startManual(queued.isNose);
			return;
		}

		this.#bankCombo();
		// Holding the button of the ollie through the landing crouches for the next one.
		if (this.#isHeld('ollie')) {
			this.#skater.crouchStart = this.#state.clock;
		}
	}

	#startGrind(rail, x, fromGround = false) {
		const direction = railDirection(rail);
		let speed = fromGround ? this.#skater.speed : (this.#skater.vx * direction.x) + (this.#skater.vy * direction.y);
		const travel = Math.sign(speed || this.#skater.vx || this.#skater.facing);
		speed = travel * Math.max(Math.abs(speed), 90);
		if (this.#skater.air) {
			// A spin or a flip that is not done yet snaps to the rail, like in the real game.
			this.#skater.spin = Math.round(this.#skater.spin / 180) * 180;
			this.#finishSpin();
			if (this.#skater.air.grab) {
				this.#skater.air.grab.releasedAt ??= this.#state.clock;
			}
		}

		const isSpecial = this.#isHeld('special') && this.#state.special >= 1;
		const trick = grindTricks[this.#heldDirection()];
		const name = isSpecial ? 'Vaffel Grind' : trick.name;
		const entry = this.#addToCombo(name, isSpecial ? 1500 : trick.points);
		if (isSpecial) {
			this.#showMessage('VAFFEL GRIND!', '#ff66ff');
			this.#effects.special();
		}

		this.#skater.mode = 'grind';
		this.#skater.air = undefined;
		this.#skater.manual = undefined;
		this.#skater.crouchStart = undefined;
		this.#skater.grind = {rail, speed, balance: randomBetween(-0.1, 0.1), drift: randomBetween(-0.4, 0.4), time: 0, from: x, minX: x, maxX: x, entry, board: isSpecial ? 'flat' : trick.board, isSpecial};
		this.#skater.x = x;
		this.#skater.y = railAt(rail, x);
		this.#skater.angle = Math.atan2(direction.y, direction.x);
		this.#effects.grind();
		this.#addParticles(x, this.#skater.y, 8, {color: ['#ffee88', '#ffaa33', '#ffffff'], speed: 50, up: 30, life: 0.3});
	}

	#leaveRail(vx, vy, {isOllie = false} = {}) {
		const grind = this.#skater.grind;
		const rail = grind.rail;
		const gapId = railGaps[rail.id];
		const covered = (grind.maxX - grind.minX) / (rail.x2 - rail.x1);
		if (gapId && covered >= 0.85) {
			this.#awardGap(gapId);
		}

		this.#skater.mode = 'air';
		this.#skater.grind = undefined;
		this.#skater.vx = vx;
		this.#skater.vy = vy;
		this.#skater.air = this.#newAir({fromRail: true});
		this.#skater.air.hasOllied = isOllie;
		// The skater leaves the rail just above it, so he does not catch it again at once.
		this.#skater.y += 1;
		this.#skater.air.leftRail = rail;
		this.#skater.air.leftRailAt = this.#state.clock;
	}

	#startManual(isNose, isRocky = false) {
		const name = isRocky ? 'The Rocky Manual' : (isNose ? 'Nose Manual' : 'Manual');
		const entry = this.#addToCombo(name, isRocky ? 1500 : 100);
		this.#skater.mode = 'manual';
		this.#skater.manual = {isNose, isRocky, balance: randomBetween(-0.1, 0.1), drift: randomBetween(-0.4, 0.4), time: 0, entry};
		if (isRocky) {
			this.#showMessage('THE ROCKY MANUAL!', '#ff66ff');
			this.#effects.special();
		}
	}

	// The balance of a grind or a manual tips more and more the longer it lasts. The visitor presses the opposite way of the needle.
	#updateBalance(balance, seconds, negativeControl, positiveControl, steadiness = 1) {
		balance.drift = clamp(balance.drift + (randomBetween(-1, 1) * seconds * 4), -1, 1);
		const tipping = (1.4 + (balance.time * 0.35)) * steadiness;
		balance.balance += ((balance.balance * tipping) + (balance.drift * 0.5 * steadiness)) * seconds;
		if (this.#isHeld(negativeControl)) {
			balance.balance -= 2.8 * seconds;
		}

		if (this.#isHeld(positiveControl)) {
			balance.balance += 2.8 * seconds;
		}

		balance.time += seconds;
		return Math.abs(balance.balance) >= 1;
	}

	#updateGround(seconds) {
		const piece = pieceAt(this.#skater.x);
		const slope = slopeAt(this.#skater.x);
		const length = Math.hypot(1, slope);
		const tangentX = 1 / length;
		const tangentY = slope / length;

		// The ramps pull the skater down.
		this.#skater.speed -= gravity * tangentY * seconds;

		const puddle = puddles.find(item => this.#skater.x >= item.from && this.#skater.x <= item.to);
		if (puddle && !this.#skater.inPuddle) {
			this.#skater.inPuddle = true;
			this.#effects.puddle();
			this.#showMessage('SPLASH!', '#88ccff', {duration: 0.8});
		} else if (!puddle) {
			this.#skater.inPuddle = false;
		}

		if (puddle && Math.abs(this.#skater.speed) > 20 && this.#state.clock - this.#skater.lastPuddleSplash > 0.05) {
			this.#skater.lastPuddleSplash = this.#state.clock;
			this.#addParticles(this.#skater.x, this.#skater.y, 3, {color: ['#9fc8ee', '#d8ecff'], speed: 30, up: 50, life: 0.4});
		}

		const friction = (puddle ? 140 : 7) * seconds;
		this.#skater.speed = Math.sign(this.#skater.speed) * Math.max(0, Math.abs(this.#skater.speed) - friction);

		if (this.#skater.mode === 'ground' && this.#skater.crouchStart === undefined) {
			const direction = this.#isHeld('right') ? 1 : (this.#isHeld('left') ? -1 : 0);
			if (direction !== 0) {
				const moving = Math.sign(this.#skater.speed);
				if (moving !== 0 && direction !== moving && Math.abs(tangentY) < 0.2) {
					// The foot brake, and the turn when the skater stands still.
					this.#skater.speed -= moving * 320 * seconds;
					if (Math.sign(this.#skater.speed) !== moving || Math.abs(this.#skater.speed) < 12) {
						this.#skater.speed = 0;
						this.#skater.facing = direction;
					}
				} else if (Math.abs(tangentY) > 0.15) {
					// Pumping down the ramps gives speed, like in a real half-pipe.
					if (tangentY * direction < 0) {
						this.#skater.speed += direction * 160 * seconds;
					}
				} else if (moving === 0 || moving === direction) {
					if (moving === 0) {
						this.#skater.facing = direction;
					}

					if (this.#state.clock - this.#skater.pushAt > 0.42 && Math.abs(this.#skater.speed) < pushTopSpeed) {
						this.#skater.pushAt = this.#state.clock;
						this.#skater.speed = direction * Math.min(pushTopSpeed, Math.abs(this.#skater.speed) + (Math.abs(this.#skater.speed) < 40 ? 90 : 55));
						this.#effects.push();
					}
				}
			}
		}

		this.#skater.speed = clamp(this.#skater.speed, -topSpeed, topSpeed);

		// The top of a quarter pipe is straight up: the skater flies up out of it, and falls back in.
		if (piece.kind === 'quarter' && Math.abs(slope) > 3.7 && this.#skater.speed * slope > 0) {
			if (this.#skater.mode === 'manual') {
				this.#skater.manual = undefined;
			}

			this.#launchVert(piece);
			return;
		}

		const step = this.#skater.speed * tangentX * seconds;
		const newX = this.#skater.x + step;
		if (newX < 6 || newX > levelWidth - 6) {
			this.#skater.x = clamp(newX, 6, levelWidth - 6);
			if (Math.abs(this.#skater.speed) > 60) {
				this.#effects.clack();
			}

			this.#skater.speed = 0;
			return;
		}

		const predictedY = this.#skater.y + (this.#skater.speed * tangentY * seconds);
		const ground = groundAt(newX);
		if (ground > predictedY + 6) {
			// A wall, like the side of a ledge.
			if (Math.abs(this.#skater.speed) > 230) {
				this.#bail('Bonk! Right into the ledge.');
				return;
			}

			this.#effects.clack();
			this.#skater.speed = -this.#skater.speed * 0.25;
			return;
		}

		if (ground < predictedY - (1.5 + (Math.abs(step) * 0.6))) {
			// The ground falls away, like at the end of a kicker, a ledge, or a step.
			this.#skater.x = newX;
			this.#skater.y = predictedY;
			this.#leaveGround(this.#skater.speed * tangentX, this.#skater.speed * tangentY);
			return;
		}

		this.#skater.x = newX;
		this.#skater.y = ground;
		this.#skater.angle = Math.atan(slopeAt(newX));
		if (this.#skater.mode === 'manual' && Math.abs(this.#skater.speed) < 25) {
			this.#skater.mode = 'ground';
			this.#skater.manual = undefined;
			this.#bankCombo();
		}

		// A grind can also start from the top of a ledge.
		if (this.#skater.mode === 'ground' && this.#state.clock - (this.#state.pressedAt.grind ?? -9) < 0.25) {
			const rail = rails.find(item => item.kind === 'ledge' && newX > item.x1 + 2 && newX < item.x2 - 2 && Math.abs(railAt(item, newX) - this.#skater.y) < 2);
			if (rail && Math.abs(this.#skater.speed) > 30) {
				this.#state.pressedAt.grind = -9;
				this.#startGrind(rail, newX, true);
			}
		}
	}

	#updateSpin(seconds) {
		const air = this.#skater.air;
		if (air.special900) {
			const remaining = air.special900.target - this.#skater.spin;
			const turn = Math.sign(remaining) * 860 * seconds;
			if (Math.abs(turn) >= Math.abs(remaining)) {
				this.#skater.spin = air.special900.target;
				air.special900.isDone = true;
			} else {
				this.#skater.spin += turn;
			}

			return;
		}

		// An arrow spins when it is pressed in the air or while crouching for the ollie, so an arrow held to push does not spin.
		const isSpinning = control => this.#isHeld(control) && (this.#state.pressedAt[control] ?? -9) >= air.spinsFrom;
		const input = (isSpinning('right') ? 1 : 0) - (isSpinning('left') ? 1 : 0);
		if (input !== 0) {
			air.spinDirection = input;
			air.spinTarget = undefined;
			this.#skater.spin += input * spinSpeed * seconds;
			return;
		}

		if (air.spinDirection === 0) {
			return;
		}

		// A spin that is let go turns on to the next half turn, or back when it only just passed one.
		if (air.spinTarget === undefined) {
			const previous = air.spinDirection > 0 ? Math.floor(this.#skater.spin / 180) * 180 : Math.ceil(this.#skater.spin / 180) * 180;
			const past = Math.abs(this.#skater.spin - previous);
			air.spinTarget = past < 30 ? previous : previous + (air.spinDirection * 180);
		}

		const remaining = air.spinTarget - this.#skater.spin;
		const turn = Math.sign(remaining) * spinSpeed * seconds;
		if (Math.abs(turn) >= Math.abs(remaining)) {
			this.#skater.spin = air.spinTarget;
			air.spinDirection = 0;
			air.spinTarget = undefined;
		} else {
			this.#skater.spin += turn;
		}
	}

	#tryGrind(x, y) {
		const air = this.#skater.air;
		if (this.#skater.vy > 120) {
			return false;
		}

		for (const rail of rails) {
			if (x < rail.x1 + 1 || x > rail.x2 - 1) {
				continue;
			}

			if (air.leftRail === rail && this.#state.clock - air.leftRailAt < 0.3) {
				continue;
			}

			const distance = y - railAt(rail, x);
			if (distance >= -8 && distance <= 24) {
				this.#state.pressedAt.grind = -9;
				this.#startGrind(rail, x);
				return true;
			}
		}

		return false;
	}

	#updateAir(seconds) {
		const air = this.#skater.air;
		this.#updateSpin(seconds);

		if (air.grab && air.grab.releasedAt === undefined) {
			this.#growEntry(air.grab.entry, 100, seconds);
		}

		// In a vert air, ▲ flies out of the half-pipe onto the deck.
		if (air.isVert) {
			this.#skater.vx = this.#isHeld('up') ? air.outward * 50 : 0;
		}

		this.#skater.vy -= gravity * seconds;
		const oldX = this.#skater.x;
		const oldY = this.#skater.y;
		let newX = this.#skater.x + (this.#skater.vx * seconds);
		const newY = this.#skater.y + (this.#skater.vy * seconds);
		if (newX < 6 || newX > levelWidth - 6) {
			newX = clamp(newX, 6, levelWidth - 6);
			this.#skater.vx = -this.#skater.vx * 0.3;
		}

		air.peak = Math.max(air.peak, newY);

		if (newY + 26 > ceiling && newX < garageEnd) {
			// The ceiling of the garage.
			this.#skater.vy = Math.min(this.#skater.vy, 0);
		}

		const wantsGrind = this.#isHeld('grind') || this.#state.clock - (this.#state.pressedAt.grind ?? -9) < 0.25;
		if (wantsGrind && this.#tryGrind(newX, newY)) {
			return;
		}

		const piece = pieceAt(newX);
		if (piece.kind === 'water' && newY < waterSurface) {
			this.#skater.x = newX;
			this.#skater.y = newY;
			this.#bail('Plask! Into the water of Vågen.');
			return;
		}

		const ground = groundAt(newX);
		if (newY <= ground) {
			if (ground > oldY + 4) {
				// The side of something, like a ledge or the wall of a quarter pipe.
				this.#skater.vx = -this.#skater.vx * 0.3;
				this.#skater.x = oldX;
				this.#skater.y = Math.max(newY, groundAt(oldX));
				if (this.#skater.y <= groundAt(oldX)) {
					this.#land(oldX, groundAt(oldX));
				}

				return;
			}

			this.#land(newX, ground);
			return;
		}

		this.#skater.x = newX;
		this.#skater.y = newY;

		// The body leans to the ground it is about to land on.
		if (!air.isVert) {
			const height = newY - ground;
			const target = this.#skater.vy < 0 && height < 40 ? Math.atan(slopeAt(newX + (this.#skater.vx * 0.08))) : 0;
			this.#skater.angle += (target - this.#skater.angle) * Math.min(1, seconds * 8);
		}
	}

	#updateGrind(seconds) {
		const grind = this.#skater.grind;
		const rail = grind.rail;
		const direction = railDirection(rail);
		grind.speed -= gravity * direction.y * seconds;
		grind.speed *= 1 - (0.08 * seconds);
		this.#growEntry(grind.entry, grind.isSpecial ? 300 : 80, seconds);
		if (!grind.isSpecial && this.#updateBalance(grind, seconds, 'left', 'right')) {
			this.#bail('Lost the balance on the rail.');
			return;
		}

		if (grind.isSpecial) {
			grind.time += seconds;
			grind.balance *= 0.9;
		}

		if (Math.abs(grind.speed) < 25) {
			this.#leaveRail(grind.speed * direction.x, -10);
			return;
		}

		const newX = this.#skater.x + (grind.speed * direction.x * seconds);
		grind.minX = Math.min(grind.minX, newX);
		grind.maxX = Math.max(grind.maxX, newX);
		if (newX >= rail.x2 || newX <= rail.x1) {
			this.#skater.x = clamp(newX, rail.x1, rail.x2);
			this.#skater.y = railAt(rail, this.#skater.x);
			grind.maxX = Math.max(grind.maxX, this.#skater.x);
			grind.minX = Math.min(grind.minX, this.#skater.x);
			this.#leaveRail(grind.speed * direction.x, (grind.speed * direction.y) + 20);
			return;
		}

		this.#skater.x = newX;
		this.#skater.y = railAt(rail, newX);
		if (Math.random() < seconds * 30) {
			const sparkColors = grind.isSpecial ? ['#d9a35a', '#a86a2a', '#fff2c0'] : ['#ffee88', '#ffaa33', '#ffffff'];
			this.#addParticles(this.#skater.x, this.#skater.y, 2, {color: sparkColors, speed: 40, up: 30, life: 0.3, size: grind.isSpecial ? 2 : 1});
		}
	}

	#updateManual(seconds) {
		const manual = this.#skater.manual;
		this.#growEntry(manual.entry, manual.isRocky ? 200 : 80, seconds);
		if (this.#updateBalance(manual, seconds, 'down', 'up', manual.isRocky ? 0.5 : 1)) {
			this.#bail(manual.isRocky ? 'Rocky fell off the nose.' : 'The board tipped over.');
			return;
		}

		this.#updateGround(seconds);
	}

	#checkPickups() {
		if (this.#skater.mode === 'bail') {
			return;
		}

		for (const spot of letterSpots) {
			if (this.#state.letters.has(spot.letter)) {
				continue;
			}

			if (Math.abs(this.#skater.x - spot.x) < 10 && spot.y > this.#skater.y - 8 && spot.y < this.#skater.y + 32) {
				this.#state.letters.add(spot.letter);
				this.#effects.letter();
				this.#showMessage(`${spot.letter}!`, '#ffdd00', {scale: 3, duration: 1.2});
				this.#addParticles(spot.x, spot.y, 14, {color: ['#ffdd00', '#ffffff', '#ff66ff'], speed: 60, up: 60, life: 0.7});
				if (this.#state.letters.size === letterSpots.length) {
					this.#addToCombo('S-K-A-T-E', 1000);
					this.#showMessage('S-K-A-T-E!', '#66ffff', {scale: 3, duration: 2.4});
					this.say('You found all the letters: S, K, A, T, E!');
					this.toast('🛹 S-K-A-T-E! All five letters!');
					this.celebrate();
				}
			}
		}

		if (!this.#state.hasTape && Math.abs(this.#skater.x - tapeSpot.x) < 10 && tapeSpot.y > this.#skater.y - 8 && tapeSpot.y < this.#skater.y + 32) {
			this.#state.hasTape = true;
			this.#effects.letter();
			this.#addToCombo('Secret Tape', 1500);
			this.#showMessage('SECRET TAPE!', '#66ffff', {scale: 3, duration: 2.4});
			this.say('You got the secret tape: Trond’s skate video, with the best bails of 1999!');
			if (!this.#state.foundTape) {
				this.#state.foundTape = true;
				this.store('tape', true);
				this.toast('📼 The secret tape! Trond’s skate video of the best bails of 1999.');
				this.#showRecords();
			}
		}

		// Mormor knits on her bench: a skater who rides into her bails.
		const isOverMormor = this.#skater.x > mormor.from && this.#skater.x < mormor.to;
		if (isOverMormor && this.#skater.y < mormor.top - 2 && this.#skater.mode !== 'grind') {
			this.#state.mormorMood = {mood: 'angry', until: this.#state.time + 2.5};
			this.#bail('Ran into Mormor! “Pass deg!”');
		}
	}

	// The tricks of the buttons.
	#pressFlip() {
		const air = this.#skater.air;
		if (this.#skater.mode !== 'air' || (air.flip && this.#state.clock - air.flip.startedAt < air.flip.duration) || (air.grab && air.grab.releasedAt === undefined) || air.special900) {
			return;
		}

		const trick = flipTricks[this.#heldDirection()];
		const last = air.tricks.at(-1);
		if (last && last.flipBase === trick.name) {
			// The same flip again in one air is a double, or a triple.
			last.count++;
			last.name = `${last.count === 2 ? 'Double' : (last.count === 3 ? 'Triple' : `${last.count}×`)} ${trick.name}`;
			last.points += trick.points * last.factor;
			this.#addSpecial(trick.points * last.factor);
			air.flip = {...trick, startedAt: this.#state.clock, duration: 0.4};
			return;
		}

		const entry = this.#addToCombo(trick.name, trick.points);
		entry.flipBase = trick.name;
		entry.count = 1;
		air.tricks.push(entry);
		air.flip = {...trick, startedAt: this.#state.clock, duration: trick.yaw && trick.roll ? 0.5 : 0.4};
	}

	#pressGrab() {
		const air = this.#skater.air;
		if (this.#skater.mode !== 'air' || (air.flip && this.#state.clock - air.flip.startedAt < air.flip.duration) || (air.grab && air.grab.releasedAt === undefined) || air.special900) {
			return;
		}

		const trick = grabTricks[this.#heldDirection()];
		const entry = this.#addToCombo(trick.name, trick.points);
		air.tricks.push(entry);
		air.grab = {...trick, entry, startedAt: this.#state.clock, releasedAt: undefined};
	}

	#pressSpecial() {
		if (this.#state.special < 1) {
			this.#effects.buzz();
			this.#showMessage('FILL THE SPECIAL METER FIRST', '#ff9999', {duration: 1.2, scale: 1});
			this.say('Fill the special meter with tricks first. It is the bar under the score.');
			return;
		}

		if (this.#skater.mode === 'air') {
			const air = this.#skater.air;
			if (air.special900 || (air.flip && this.#state.clock - air.flip.startedAt < air.flip.duration)) {
				return;
			}

			if (air.grab) {
				air.grab.releasedAt ??= this.#state.clock;
			}

			if (air.isVert && this.#skater.vy > 60) {
				// The 900: two and a half turns, the trick that Tony Hawk landed at the X Games in June.
				const direction = this.#skater.facing;
				air.special900 = {target: this.#skater.spin + (direction * 900), isDone: false};
				const entry = this.#addToCombo('The 900', 3500);
				air.tricks.push(entry);
				this.#showMessage('THE 900!', '#ff66ff', {scale: 3});
			} else {
				const entry = this.#addToCombo('The Brunost Flip', 2500);
				air.tricks.push(entry);
				air.flip = {name: 'Brunost Flip', isBrunost: true, roll: 2, startedAt: this.#state.clock, duration: 0.6};
				this.#showMessage('THE BRUNOST FLIP!', '#ff66ff');
			}

			this.#effects.special();
			return;
		}

		if (this.#skater.mode === 'grind' && !this.#skater.grind.isSpecial) {
			const grind = this.#skater.grind;
			grind.isSpecial = true;
			grind.entry.name = 'Vaffel Grind';
			grind.entry.points += 1500 * grind.entry.factor;
			grind.board = 'flat';
			this.#showMessage('VAFFEL GRIND!', '#ff66ff');
			this.#effects.special();
			return;
		}

		if (this.#skater.mode === 'ground' && Math.abs(this.#skater.speed) > 30) {
			this.#startManual(false, true);
		}
	}

	#pressOllie() {
		if (this.#skater.mode === 'ground') {
			this.#skater.crouchStart = this.#state.clock;
			return;
		}

		if (this.#skater.mode === 'manual') {
			this.#skater.manual = undefined;
			this.#skater.mode = 'ground';
			this.#popOllie(190);
			return;
		}

		if (this.#skater.mode === 'grind') {
			const direction = railDirection(this.#skater.grind.rail);
			const speed = this.#skater.grind.speed;
			this.#leaveRail(speed * direction.x, (speed * direction.y) + 170, {isOllie: true});
			this.#effects.pop();
			return;
		}

		// A late ollie, just after rolling off an edge, still pops.
		if (this.#skater.mode === 'air' && !this.#skater.air.hasOllied && !this.#skater.air.isVert && !this.#skater.air.fromRail && this.#state.clock - this.#skater.air.startedAt < 0.12) {
			this.#skater.vy = Math.max(this.#skater.vy, 0) + 180;
			this.#skater.air.hasOllied = true;
			this.#effects.pop();
		}
	}

	#releaseOllie() {
		if (this.#skater.mode === 'ground' && this.#skater.crouchStart !== undefined) {
			this.#ollieFromCrouch();
		}

		this.#skater.crouchStart = undefined;
	}

	// Up and then down is a manual, and down and then up a nose manual, on the ground or just before landing.
	#checkManualPress(control) {
		if (control !== 'up' && control !== 'down') {
			return;
		}

		const previous = this.#state.presses.at(-2);
		if (!previous || previous.control === control || this.#state.clock - previous.at > 0.35 || !['up', 'down'].includes(previous.control)) {
			return;
		}

		const isNose = previous.control === 'down';
		if (this.#skater.mode === 'ground' && Math.abs(this.#skater.speed) > 30 && this.#skater.crouchStart === undefined) {
			this.#state.presses.length = 0;
			this.#startManual(isNose);
		} else if (this.#skater.mode === 'air') {
			this.#state.presses.length = 0;
			this.#skater.air.manualQueued = {isNose, at: this.#state.clock};
		}
	}

	// The run: two minutes, or free skating without the clock.
	#resetSkater() {
		Object.assign(this.#skater, {x: 20, y: 80, vx: 0, vy: 0, speed: 0, mode: 'ground', facing: 1, angle: 0, spin: 0, crouchStart: undefined, pushAt: -1, air: undefined, grind: undefined, manual: undefined, ragdoll: undefined, takeoffX: undefined, inPuddle: false, lastPuddleSplash: -1});
		this.#state.camera.x = 0;
		this.#state.camera.y = 70;
	}

	#startRun(isTimed) {
		this.#resetSkater();
		Object.assign(this.#state, {
			mode: isTimed ? 'run' : 'free',
			clock: 0,
			runTime: runSeconds,
			isTimeUp: false,
			score: 0,
			combo: undefined,
			special: 0,
			uses: new Map(),
			letters: new Set(),
			hasTape: false,
			runGaps: new Set(),
			plasters: 0,
			bestRunCombo: 0,
			messages: [],
			particles: [],
			presses: [],
			pressedAt: {},
			cheer: undefined,
		});
		this.#showMessage('DROP IN!', '#ffdd00', {scale: 3});
		this.say(`${isTimed ? 'Two minutes!' : 'Free skate!'} Hold ▶ to drop in. ✕ (Space) ollies, ■ (Z) flips.`);
		this.parts.screen.focus({preventScroll: true});
		this.parts.screen.scrollIntoView({block: 'nearest', behavior: this.reducedMotion ? 'auto' : 'smooth'});
		this.#loop.start();
		this.#draw();
	}

	#endRun() {
		if (this.#state.mode !== 'run') {
			return;
		}

		this.#bankCombo();
		this.#state.mode = 'results';
		this.#state.resultsAt = performance.now();
		const isHighScore = this.#state.score > this.#state.highScore;
		if (isHighScore) {
			this.#state.highScore = this.#state.score;
			this.store('highScore', this.#state.highScore);
		}

		const letters = letterSpots.map(spot => (this.#state.letters.has(spot.letter) ? spot.letter : '_')).join('');
		this.#state.lastRun = {score: this.#state.score, gaps: this.#state.runGaps.size, letters, plasters: this.#state.plasters, hasTape: this.#state.hasTape};
		this.store('lastRun', this.#state.lastRun);
		this.#state.isNewHighScore = isHighScore;
		this.#showRecords();
		this.#effects.horn();
		this.#quiet();
		this.say(`Time! ${formatNumber(this.#state.score)} points${isHighScore ? ', a new high score' : ''}. ${this.#state.runGaps.size} ${this.#state.runGaps.size === 1 ? 'gap' : 'gaps'}, letters ${letters.replaceAll('_', '·')}, and ${this.#state.plasters} ${this.#state.plasters === 1 ? 'plaster' : 'plasters'} from Mamma.`);
		if (isHighScore && this.#state.score > 0) {
			this.celebrate();
			this.toast(`🛹 New high score: ${formatNumber(this.#state.score)}!`);
		}

		this.#loop.start();
		this.#draw();
	}

	#simulate(seconds) {
		this.#state.clock += seconds;
		if (this.#state.mode === 'run' && !this.#state.isTimeUp) {
			const before = Math.ceil(this.#state.runTime);
			this.#state.runTime = Math.max(0, this.#state.runTime - seconds);
			if (Math.ceil(this.#state.runTime) !== before && this.#state.runTime <= 10 && this.#state.runTime > 0) {
				this.#effects.tick();
			}

			if (this.#state.runTime <= 0) {
				this.#state.isTimeUp = true;
				this.#state.timeUpAt = this.#state.clock;
				this.#showMessage('TIME!', '#ff3333', {scale: 3, duration: 3});
			}
		}

		switch (this.#skater.mode) {
			case 'ground': {
				this.#updateGround(seconds);
				break;
			}

			case 'manual': {
				this.#updateManual(seconds);
				break;
			}

			case 'air': {
				this.#updateAir(seconds);
				break;
			}

			case 'grind': {
				this.#updateGrind(seconds);
				break;
			}

			case 'bail': {
				// The ragdoll keeps its speed as a distance per step, so it moves in steps of a fixed length.
				this.#skater.ragdoll.pending += seconds;
				while (this.#skater.mode === 'bail' && this.#skater.ragdoll.pending >= ragdollStep) {
					this.#skater.ragdoll.pending -= ragdollStep;
					this.#updateRagdoll(ragdollStep);
				}

				break;
			}

			default: {
				break;
			}
		}

		this.#checkPickups();

		// Points on the ground, like a letter on the way, go to the score at once.
		if (this.#skater.mode === 'ground' && this.#state.combo) {
			this.#bankCombo();
		}

		// The special meter slowly empties while the skater does nothing.
		if (!this.#state.combo && this.#skater.mode === 'ground' && this.#state.special < 1) {
			this.#state.special = Math.max(0, this.#state.special - (seconds * 0.015));
		}

		// When the time is up, the trick in progress may still land, like in the real game.
		if (this.#state.isTimeUp && ((this.#skater.mode === 'ground' && !this.#state.combo) || this.#state.clock - this.#state.timeUpAt > 6)) {
			this.#endRun();
		}
	}

	#updateRolling() {
		// The wheels are also quiet while step mode waits for a button.
		if (!this.#isPlaying() || this.#isPaused()) {
			this.#quiet();
			return;
		}

		if (this.#skater.mode === 'grind') {
			this.#setRolling(0.07, this.#skater.grind.isSpecial ? 900 : 2600, 5);
		} else if (this.#skater.mode === 'ground' || this.#skater.mode === 'manual') {
			const speed = Math.abs(this.#skater.speed);
			this.#setRolling(Math.min(0.05, speed / 260 * 0.05), 250 + speed, 0.9);
		} else {
			this.#quiet();
		}
	}

	#updateCamera(seconds) {
		const camera = this.#state.camera;
		const lookAhead = clamp((this.#skater.mode === 'ground' ? this.#skater.speed : this.#skater.vx) * 0.25, -60, 60);
		const focusX = this.#skater.mode === 'bail' ? this.#skater.ragdoll.points.hip.x : this.#skater.x;
		const focusY = this.#skater.mode === 'bail' ? this.#skater.ragdoll.points.hip.y : this.#skater.y;
		const targetX = clamp(focusX - (width / 2) + lookAhead, 0, levelWidth - width);
		const ground = Math.max(groundAt(focusX), waterSurface - 30);
		const targetY = Math.max(ground - 10, focusY - 140);
		const ease = seconds === 0 ? 1 : Math.min(1, seconds * 5);
		camera.x += (targetX - camera.x) * ease;
		camera.y += (targetY - camera.y) * ease;
	}

	#updateEffects(seconds) {
		for (const particle of this.#state.particles) {
			particle.age += seconds;
			particle.vy -= particle.fall * seconds;
			particle.x += particle.vx * seconds;
			particle.y += particle.vy * seconds;
		}

		this.#state.particles = this.#state.particles.filter(particle => particle.age < particle.life);
		this.#state.messages = this.#state.messages.filter(message => message.until > this.#state.time);
	}

	// With step mode, the run only moves while the visitor holds a button, and a moment after a press.
	#isPaused() {
		return this.#state.stepMode && this.#isPlaying() && !Object.values(this.#state.held).some(Boolean) && performance.now() - this.#state.lastInputAt > 500;
	}

	#step(seconds) {
		this.#state.time += seconds;
		if (this.#isPlaying() && !this.#isPaused()) {
			const substeps = Math.max(1, Math.ceil(seconds * 120));
			for (let index = 0; index < substeps; index++) {
				if (!this.#isPlaying()) {
					break;
				}

				this.#simulate(seconds / substeps);
			}

			this.#updateCamera(seconds);
		}

		this.#updateRolling();
		this.#updateEffects(seconds);
		this.#draw();
	}

	// Drawing. A world point is drawn at a screen point by the camera.
	#screenX(x) {
		return Math.round(x - this.#state.camera.x);
	}

	#screenY(y) {
		return Math.round(horizon - (y - this.#state.camera.y));
	}

	#isBlinkOn(period = 0.5) {
		return this.reducedMotion || Math.floor(this.#state.time / period) % 2 === 0;
	}

	#drawSky() {
		const gradient = this.#context.createLinearGradient(0, 0, 0, height);
		gradient.addColorStop(0, '#6f7c8c');
		gradient.addColorStop(1, '#aeb8c4');
		this.#context.fillStyle = gradient;
		this.#context.fillRect(0, 0, width, height);

		// The seven mountains of Bergen, far away, with the mast on top of Ulriken.
		const far = this.#state.camera.x * 0.15;
		const farY = this.#state.camera.y * 0.15;
		this.#context.fillStyle = '#56645c';
		this.#context.beginPath();
		this.#context.moveTo(0, height);
		for (let column = 0; column <= width; column += 4) {
			const x = column + far;
			const ridge = 70 + (Math.sin(x * 0.012) * 22) + (Math.sin((x * 0.031) + 1.3) * 9) + (Math.sin((x * 0.005) + 2) * 14);
			this.#context.lineTo(column, horizon - ridge - 30 + farY);
		}

		this.#context.lineTo(width, height);
		this.#context.closePath();
		this.#context.fill();
		const mastX = 260 - far;
		if (mastX > -10 && mastX < width + 10) {
			const top = horizon - 140 + farY;
			this.#strokeLine('#c9c9c9', 1, [[mastX, top + 20], [mastX, top]]);
			this.#fillShape(this.#isBlinkOn(0.8) ? '#ff3333' : '#882222', mastX - 1, top - 1, 2, 2);
		}
	}

	// The wooden houses of Bryggen, with their pointed gables, and the stone houses behind the fish market, a little nearer than the mountains.
	#drawTown() {
		const offset = this.#state.camera.x * 0.5;
		const baseY = this.#screenY(0) - 10 + Math.round(this.#state.camera.y * -0.5);
		for (let index = 0; index < 40; index++) {
			const houseX = 240 + (index * 30);
			const x = Math.round(houseX - offset);
			if (x < -40 || x > width + 10) {
				continue;
			}

			const isBryggen = index < 18;
			const houseHeight = isBryggen ? 46 + ((index * 7) % 13) : 54 + ((index * 11) % 20);
			const color = isBryggen ? houseColors[index % houseColors.length] : ['#9c9a94', '#b5aea2', '#8f8b84'][index % 3];
			const top = baseY - houseHeight;
			this.#fillShape(color, x, top, 28, houseHeight + 40);
			if (isBryggen) {
				this.#fillPolygon(color, [[x - 1, top], [x + 14, top - 18], [x + 29, top]]);
				this.#strokeLine('#3a2a20', 1, [[x - 1, top], [x + 14, top - 18], [x + 29, top]]);
				for (let plank = 3; plank < 28; plank += 4) {
					this.#fillShape('rgba(0, 0, 0, 0.12)', x + plank, top, 1, houseHeight + 40);
				}

				this.#fillShape('#f6f2e4', x + 11, top - 9, 6, 6);
			} else {
				this.#fillShape('#5a5652', x - 1, top - 3, 30, 3);
			}

			for (let row = 0; row < 3; row++) {
				for (let column = 0; column < 2; column++) {
					const windowColor = (index + row + column) % 5 === 0 ? '#ffe88a' : '#2f3a44';
					this.#fillShape(windowColor, x + 5 + (column * 12), top + 8 + (row * 13), 6, 7);
				}
			}
		}
	}

	// The parking garage: a back wall of concrete, pillars, signs, lights in the ceiling, and Trond with his video camera at the exit.
	#drawGarage() {
		const left = this.#screenX(0);
		const right = this.#screenX(garageEnd);
		if (right < 0) {
			return;
		}

		const floor = this.#screenY(-60);
		const roof = this.#screenY(ceiling);
		this.#fillShape('#6f6f6f', left, roof, right - left, floor - roof);
		for (let row = ceiling - 12; row > -60; row -= 12) {
			this.#fillShape('#666666', left, this.#screenY(row), right - left, 1);
		}

		for (const pillar of [100, 220, 360, 480]) {
			const x = this.#screenX(pillar);
			this.#fillShape('#858585', x - 7, roof, 14, floor - roof);
			for (let stripe = 0; stripe < 4; stripe++) {
				this.#fillShape(stripe % 2 === 0 ? '#e8c000' : '#222222', x - 7, this.#screenY(14 - (stripe * 4)), 14, 4);
			}
		}

		const sign = (text, worldX, worldY, background, color = '#ffffff') => {
			const x = this.#screenX(worldX);
			const y = this.#screenY(worldY);
			const signWidth = textWidth(text) + 6;
			this.#fillShape(background, x - (signWidth / 2), y, signWidth, 9);
			this.#drawText(text, x, y + 2, color, {align: 'center', shadow: undefined});
		};

		sign('PLAN 2', 100, 150, '#1f4fa8');
		sign('P', 220, 160, '#1f4fa8');
		sign('BYGARASJEN', 360, 170, '#1f4fa8');
		sign('UTKJØRSEL', 480, 130, '#1f8a3a');
		sign('MAKS 2,1 M', 480, 110, '#ffffff', '#cc0000');
		this.#drawText('SINDRE ♥ SHPS 99', this.#screenX(180), this.#screenY(110), '#ff66cc', {align: 'center', shadow: 'rgba(0, 0, 0, 0.4)'});

		for (let light = 40; light < garageEnd; light += 80) {
			const x = this.#screenX(light);
			this.#fillShape(light % 160 === 120 && this.#isBlinkOn(0.15) && Math.sin(this.#state.time * 3) > 0.7 ? '#9a9a9a' : '#f4f8ff', x - 12, roof + 1, 24, 3);
			this.#fillShape('rgba(244, 248, 255, 0.12)', x - 20, roof + 4, 40, 10);
		}

		// The ceiling, as thick as a floor of the building, up to the top of the screen.
		this.#fillShape('#4f4f4f', left, 0, right - left, roof);
		this.#fillShape('#3a3a3a', left, roof - 3, right - left, 3);
		this.#fillShape('#3a3a3a', right - 8, 0, 8, roof + 16);
	}

	#drawTrond() {
		const x = this.#screenX(600);
		if (x < -20 || x > width + 20) {
			return;
		}

		const y = this.#screenY(0);
		this.#strokeLine('#22324a', 2, [[x - 2, y], [x - 1, y - 10]]);
		this.#strokeLine('#22324a', 2, [[x + 2, y], [x + 1, y - 10]]);
		this.#fillShape('#2b7a3a', x - 4, y - 19, 8, 10);
		this.#fillCircle('#f0c8a0', x, y - 22, 3);
		this.#fillShape('#6a3a1a', x - 3, y - 26, 7, 3);
		// The video camera, filming a skate video like everyone did in 1999.
		this.#fillShape('#222222', x - 10, y - 21, 7, 5);
		this.#fillShape('#555555', x - 12, y - 20, 2, 3);
		if (this.#isBlinkOn(0.6)) {
			this.#fillShape('#ff2222', x - 5, y - 23, 2, 2);
		}

		this.#drawText('TROND', x, y + 4, '#ffffff', {align: 'center'});
	}

	#drawStalls() {
		const stalls = [
			{x: 1340, sign: 'FERSK FISK'},
			{x: 1440, sign: 'REKER'},
			{x: 1640, sign: 'LAKS 89,-'},
			{x: 1840, sign: 'KAVIAR'},
		];
		for (const stall of stalls) {
			const x = this.#screenX(stall.x);
			if (x < -50 || x > width + 50) {
				continue;
			}

			const ground = this.#screenY(-36);
			this.#strokeLine('#5a4030', 2, [[x - 28, ground], [x - 28, ground - 40]]);
			this.#strokeLine('#5a4030', 2, [[x + 28, ground], [x + 28, ground - 40]]);
			for (let stripe = 0; stripe < 8; stripe++) {
				this.#fillShape(stripe % 2 === 0 ? '#cc2222' : '#f4f4f4', x - 32 + (stripe * 8), ground - 48, 8, 9);
			}

			this.#fillPolygon('#cc2222', [[x - 32, ground - 39], [x + 32, ground - 39], [x + 28, ground - 35], [x - 28, ground - 35]]);
			this.#fillShape('#d8e8f0', x - 24, ground - 20, 48, 6);
			for (let fish = 0; fish < 5; fish++) {
				const fishX = x - 20 + (fish * 9);
				this.#fillPolygon(fish % 2 === 0 ? '#7a8a9a' : '#e88a6a', [[fishX, ground - 21], [fishX + 6, ground - 23], [fishX + 6, ground - 19]]);
			}

			this.#fillShape('#6a4a30', x - 24, ground - 14, 48, 14);
			const signWidth = textWidth(stall.sign) + 6;
			this.#fillShape('#ffffff', x - (signWidth / 2), ground - 60, signWidth, 9);
			this.#drawText(stall.sign, x, ground - 58, '#1a3a8a', {align: 'center', shadow: undefined});
		}

		// The station of Fløibanen at the end of the level.
		const stationX = this.#screenX(1990);
		if (stationX < width + 10) {
			const ground = this.#screenY(-36);
			this.#fillShape('#8a3a2a', stationX, ground - 140, 130, 140);
			for (let row = 0; row < 140; row += 6) {
				this.#fillShape('#7a3022', stationX, ground - 140 + row, 130, 1);
			}

			this.#fillShape('#ffffff', stationX + 14, ground - 132, 74, 11);
			this.#drawText('FLØIBANEN', stationX + 51, ground - 129, '#aa2222', {align: 'center', shadow: undefined});
		}
	}

	#drawTerrain() {
		for (let column = 0; column < width; column += 2) {
			const worldX = this.#state.camera.x + column + 1;
			if (worldX < 0 || worldX > levelWidth) {
				continue;
			}

			const piece = pieceAt(worldX);
			if (piece.kind === 'water') {
				const surface = this.#screenY(waterSurface);
				const wave = this.reducedMotion ? 0 : Math.round(Math.sin((worldX * 0.2) + (this.#state.time * 3)));
				this.#fillShape('#2a5a7a', column, surface + wave, 2, height - surface);
				this.#fillShape('#7ab0d0', column, surface + wave, 2, 1);
				continue;
			}

			const top = this.#screenY(piece.height(worldX));
			const [surface, body] = pieceColors[piece.kind];
			this.#fillShape(body, column, top, 2, height - top);
			this.#fillShape(surface, column, top, 2, 2);
			// The cobblestones of Bryggen and the tiles of the fish market.
			if ((piece.kind === 'street' || piece.kind === 'market') && Math.floor(worldX / 6) % 2 === 0) {
				this.#fillShape('rgba(0, 0, 0, 0.12)', column, top + 3, 2, 2);
			}
		}

		this.#drawRampDetails();
	}

	#drawRampDetails() {
		// The frames under the ramps, the metal coping on top, and the edges of the steps and the crates.
		for (const piece of terrain) {
			const left = this.#screenX(piece.from);
			const right = this.#screenX(piece.to);
			if (right < -2 || left > width + 2) {
				continue;
			}

			if (piece.kind === 'quarter') {
				for (let beam = piece.from + 8; beam < piece.to; beam += 16) {
					const top = this.#screenY(piece.height(beam)) + 3;
					this.#fillShape('#7a5530', this.#screenX(beam), top, 2, height - top);
				}

				const copingX = piece.outward < 0 ? piece.from : piece.to;
				this.#fillCircle('#d8d8e0', this.#screenX(copingX), this.#screenY(piece.height(copingX - (piece.outward * 0.5))), 2);
			}

			if (piece.kind === 'deck') {
				const top = this.#screenY(piece.height(piece.from));
				for (let post = piece.from + 6; post < piece.to; post += 14) {
					this.#fillShape('#6a4a28', this.#screenX(post), top + 3, 2, height - top);
				}
			}

			if (piece.kind === 'stairs') {
				for (let stair = piece.from; stair < piece.to; stair += 10) {
					const top = this.#screenY(piece.height(stair));
					this.#fillShape('#6a655e', this.#screenX(stair), top, 1, height - top);
					this.#fillShape('#d6d0c6', this.#screenX(stair), top, 10, 1);
				}
			}

			if (piece.kind === 'kicker') {
				// The ramp is a plank on blue fish crates.
				const bottom = this.#screenY(piece.height(piece.from));
				for (let crate = piece.from; crate < piece.to - 6; crate += 10) {
					const crateTop = this.#screenY(piece.height(crate + 10)) + 2;
					this.#context.strokeStyle = '#1a3a78';
					this.#context.lineWidth = 1;
					this.#context.strokeRect(this.#screenX(crate) + 0.5, crateTop + 0.5, 9, bottom - crateTop);
				}

				this.#strokeLine('#a8824a', 2, [[left, bottom], [right, this.#screenY(piece.height(piece.to - 0.01))]]);
			}

			if (piece.kind === 'ledge') {
				// A ledge of granite blocks, with a shiny edge from all the grinding.
				const top = this.#screenY(piece.height(piece.from));
				const bottom = this.#screenY(groundAt(piece.from - 1));
				for (let row = top + 5; row < bottom; row += 5) {
					this.#fillShape('#777777', left, row, right - left, 1);
				}

				for (let block = piece.from + 20; block < piece.to; block += 20) {
					this.#fillShape('#777777', this.#screenX(block), top + 2, 1, bottom - top - 2);
				}

				this.#fillShape('#ffffff', left, top, right - left, 1);
				this.#fillShape('#6a6a6a', left, top, 1, height - top);
				this.#fillShape('#6a6a6a', right - 1, top, 1, height - top);
				const label = piece.from < 1000 ? 'KAI' : 'TORGET';
				this.#drawText(label, (left + right) / 2, top + 4, '#6a6a6a', {align: 'center', shadow: undefined});
			}
		}
	}

	#drawRails() {
		for (const rail of rails) {
			if (rail.kind !== 'rail') {
				continue;
			}

			const x1 = this.#screenX(rail.x1);
			const x2 = this.#screenX(rail.x2);
			if (x2 < -2 || x1 > width + 2) {
				continue;
			}

			for (let post = rail.x1 + 4; post <= rail.x2 - 4; post += rail.id === 'handrail' ? 30 : 34) {
				this.#strokeLine('#55555f', 2, [[this.#screenX(post), this.#screenY(railAt(rail, post))], [this.#screenX(post), this.#screenY(groundAt(post))]]);
			}

			this.#strokeLine('#dcdce6', 2, [[x1, this.#screenY(rail.y1)], [x2, this.#screenY(rail.y2)]]);
		}
	}

	#drawPuddles() {
		for (const puddle of puddles) {
			const x = this.#screenX(puddle.from);
			const right = this.#screenX(puddle.to);
			if (right < 0 || x > width) {
				continue;
			}

			const y = this.#screenY(puddle.level);
			this.#fillShape('#4a6a8a', x, y - 1, right - x, 3);
			this.#fillShape('#9ac0e0', x + 3, y - 1, right - x - 10, 1);
		}

		// The rain makes rings in the puddles and on the water.
		for (const ripple of this.#state.ripples) {
			const size = ripple.age * 10;
			this.#context.strokeStyle = `rgba(220, 240, 255, ${0.8 - (ripple.age * 1.6)})`;
			this.#context.lineWidth = 1;
			this.#context.beginPath();
			this.#context.ellipse(this.#screenX(ripple.x), this.#screenY(ripple.y), size + 0.5, (size / 3) + 0.5, 0, 0, Math.PI * 2);
			this.#context.stroke();
		}
	}

	#drawMormor() {
		const x = this.#screenX((mormor.from + mormor.to) / 2);
		if (x < -40 || x > width + 40) {
			return;
		}

		const y = this.#screenY(mormor.level);
		const mood = this.#state.mormorMood.until > this.#state.time ? this.#state.mormorMood.mood : 'knit';
		// The bench.
		this.#fillShape('#6a4424', x - 18, y - 10, 36, 3);
		this.#fillShape('#6a4424', x - 18, y - 17, 36, 2);
		this.#fillShape('#3a3a3a', x - 16, y - 10, 2, 10);
		this.#fillShape('#3a3a3a', x + 14, y - 10, 2, 10);
		// Mormor, in her red cardigan, with gray hair in a bun and glasses.
		this.#fillShape('#3a3a6a', x - 4, y - 10, 9, 3);
		this.#fillShape('#3a3a6a', x + 3, y - 10, 3, 9);
		this.#fillShape('#b02a3a', x - 5, y - 22, 9, 12);
		this.#fillCircle('#f2d0b0', x, y - 25, 3.5);
		this.#fillCircle('#d8d8d8', x - 1, y - 29, 3);
		this.#fillCircle('#d8d8d8', x - 4, y - 28, 2);
		this.#fillShape('#333333', x, y - 26, 3, 1);
		const hands = mood === 'cheer' ? [[x - 6, y - 32], [x + 6, y - 32]] : (mood === 'angry' ? [[x + 8, y - 26], [x + 6, y - 18]] : [[x + 4, y - 16], [x + 6, y - 15]]);
		this.#strokeLine('#b02a3a', 2, [[x - 3, y - 20], hands[0]]);
		this.#strokeLine('#b02a3a', 2, [[x + 3, y - 20], hands[1]]);
		if (mood === 'knit') {
			// The knitting, and the ball of yarn on the ground.
			const needle = this.reducedMotion ? 0 : Math.round(Math.sin(this.#state.time * 8));
			this.#strokeLine('#cccccc', 1, [[x + 2, y - 14 + needle], [x + 9, y - 18]]);
			this.#fillShape('#4a8ae8', x + 4, y - 15, 5, 3);
			this.#fillCircle('#4a8ae8', x + 14, y - 2, 2.5);
		}

		const bubble = mood === 'cheer' ? 'FLINK GUTT!' : (mood === 'angry' ? 'PASS DEG!' : '');
		if (bubble) {
			const bubbleWidth = textWidth(bubble) + 6;
			this.#fillShape('#ffffff', x - (bubbleWidth / 2), y - 48, bubbleWidth, 10);
			this.#fillPolygon('#ffffff', [[x - 2, y - 38], [x + 2, y - 38], [x, y - 34]]);
			this.#drawText(bubble, x, y - 46, mood === 'cheer' ? '#1a7a2a' : '#cc0000', {align: 'center', shadow: undefined});
		}

		this.#drawText('MORMOR', x, y + 4, '#ffffff', {align: 'center'});
	}

	#drawPickups() {
		for (const spot of letterSpots) {
			if (this.#state.letters.has(spot.letter) || !this.#isPlaying()) {
				continue;
			}

			const x = this.#screenX(spot.x);
			const y = this.#screenY(spot.y);
			if (x < -10 || x > width + 10) {
				continue;
			}

			const turn = this.reducedMotion ? 1 : Math.cos(this.#state.time * 3);
			this.#context.save();
			this.#context.translate(x, y);
			this.#context.scale(Math.abs(turn) < 0.25 ? 0.25 : turn, 1);
			this.#fillCircle('rgba(255, 221, 0, 0.35)', 0, 0, 8);
			this.#drawText(spot.letter, 0, -5, '#ffdd00', {align: 'center', scale: 2, shadow: '#7a4a00'});
			this.#context.restore();
		}

		if (!this.#state.hasTape && this.#isPlaying()) {
			const x = this.#screenX(tapeSpot.x);
			const y = this.#screenY(tapeSpot.y) + (this.reducedMotion ? 0 : Math.round(Math.sin(this.#state.time * 4) * 2));
			if (x > -10 && x < width + 10) {
				this.#fillCircle('rgba(102, 255, 255, 0.3)', x, y, 9);
				this.#fillShape('#111111', x - 7, y - 4, 14, 9);
				this.#fillShape('#f4f4f4', x - 5, y - 3, 10, 3);
				this.#fillShape('#444444', x - 4, y + 1, 3, 2);
				this.#fillShape('#444444', x + 1, y + 1, 3, 2);
			}
		}
	}

	// The board, seen from the side, turned by a flip: a roll around its long side (a kickflip shows the bottom), a yaw around up (a shove-it makes it short), and a pitch end over end (an impossible).
	#drawBoard({roll = 0, yaw = 0, pitch = 0, x = 0, y = -2, isCheese = false} = {}) {
		this.#context.save();
		this.#context.translate(x, y);
		this.#context.rotate(pitch);
		const length = Math.max(0.15, Math.abs(Math.cos(yaw)));
		const face = Math.sin(roll);
		const thickness = 2 + (Math.abs(face) * 5);
		if (isCheese) {
			// The Brunost Flip: the board turns into a cheese slicer for a moment, with a slice of brown cheese on top.
			this.#fillShape('#c8c8d0', -7 * length, -1, 12 * length, 2);
			this.#fillShape('#2a2a2a', 5 * length, -1, 5 * length, 2);
			this.#fillShape('#a8642a', -8, -7 - (Math.abs(face) * 5), 15, 4);
			this.#fillShape('#c8843a', -8, -7 - (Math.abs(face) * 5), 15, 1);
			this.#context.restore();
			return;
		}

		const deckColor = face > 0.2 ? '#222222' : (face < -0.2 ? '#cc2222' : '#3a2a1a');
		this.#fillShape(deckColor, -9 * length, -thickness / 2, 18 * length, thickness);
		if (face < -0.2) {
			this.#fillShape('#ffdd00', -2 * length, -1, 4 * length, 2);
		}

		if (Math.abs(face) < 0.6) {
			const side = Math.cos(roll) >= 0 ? 1 : -1;
			this.#fillShape('#888888', -6 * length, (thickness / 2) * side, 2, side);
			this.#fillShape('#888888', 4 * length, (thickness / 2) * side, 2, side);
			this.#fillCircle('#f2f2e8', -5 * length, ((thickness / 2) + 1.5) * side, 1.3);
			this.#fillCircle('#f2f2e8', 5 * length, ((thickness / 2) + 1.5) * side, 1.3);
		}

		// The kicktails.
		if (length > 0.5 && Math.abs(face) < 0.4) {
			this.#fillShape(deckColor, 9 * length, (-thickness / 2) - 1, 2, 2);
			this.#fillShape(deckColor, -11 * length, (-thickness / 2) - 1, 2, 2);
		}

		this.#context.restore();
	}

	#drawSkaterBody() {
		const air = this.#skater.air;
		const grind = this.#skater.grind;
		const manual = this.#skater.manual;
		let crouch = 0.15;
		let feetY = -5;
		let board = {};
		let hands = [[-6, -17], [6, -18]];
		let boardTilt = 0;
		let lean = 0;
		let isRocky = false;

		if (this.#skater.mode === 'ground' && this.#skater.crouchStart !== undefined) {
			crouch = 0.85;
		} else if (this.#skater.mode === 'ground' && this.#state.clock - this.#skater.pushAt < 0.35) {
			crouch = 0.35;
		} else if (this.#skater.mode === 'air') {
			crouch = 0.5;
			hands = [[-7, -20], [7, -21]];
			const flipAge = air.flip ? (this.#state.clock - air.flip.startedAt) / air.flip.duration : 1;
			if (air.flip && flipAge < 1) {
				const turn = flipAge * Math.PI * 2;
				feetY = -10;
				crouch = 0.8;
				board = {roll: (air.flip.roll ?? 0) * turn, yaw: (air.flip.yaw ?? 0) * turn / 2, pitch: (air.flip.pitch ?? 0) * turn, y: -5, isCheese: air.flip.isBrunost};
			} else if (air.grab && (air.grab.releasedAt === undefined || this.#state.clock - air.grab.releasedAt < 0.12)) {
				crouch = 1;
				feetY = -7;
				const handX = {nose: 8, tail: -8, middle: 1, heel: -1}[air.grab.hand];
				hands = [[handX, -6], [air.grab.arch ? -9 : 7, -20]];
				lean = air.grab.arch ? -0.25 : 0;
				board = {y: -7};
			}
		} else if (this.#skater.mode === 'grind') {
			crouch = 0.4;
			hands = [[-9, -16], [9, -17]];
			if (grind.board === 'across') {
				board = {yaw: Math.PI / 2.4};
			} else if (grind.board === 'nose') {
				boardTilt = -0.25;
			} else if (grind.board === 'tail') {
				boardTilt = 0.25;
			}
		} else if (this.#skater.mode === 'manual') {
			crouch = 0.3;
			boardTilt = manual.isNose ? -0.22 : 0.22;
			lean = (manual.isNose ? 0.15 : -0.15) + (manual.balance * 0.25);
			hands = [[-8, -15], [8, -16]];
			isRocky = manual.isRocky;
		}

		const hipY = -13 + (crouch * 5);
		const shoulderY = hipY - 8;
		this.#context.save();
		this.#context.rotate(lean);
		this.#context.save();
		this.#context.rotate(-boardTilt);
		this.#drawBoard(board);
		if (isRocky) {
			// Rocky the pet rock rides on the nose.
			this.#fillCircle('#8a8a8a', 9, -6, 3);
			this.#fillShape('#222222', 9, -7, 1, 1);
			this.#fillShape('#222222', 11, -7, 1, 1);
		}

		this.#context.restore();

		// The push: the back foot kicks the street.
		const isPushing = this.#skater.mode === 'ground' && this.#state.clock - this.#skater.pushAt < 0.35 && this.#skater.crouchStart === undefined;
		const pushPhase = isPushing ? (this.#state.clock - this.#skater.pushAt) / 0.35 : 0;
		const backFoot = isPushing ? [-6 - (pushPhase * 6), 1] : [-4, feetY];
		const frontFoot = [4, feetY];
		const knee = foot => [(foot[0] / 2) + (crouch * 3), ((foot[1] + hipY) / 2) - crouch];
		this.#strokeLine('#2f4f8a', 2.5, [backFoot, knee(backFoot), [0, hipY]]);
		this.#strokeLine('#2f4f8a', 2.5, [frontFoot, knee(frontFoot), [0, hipY]]);
		this.#fillShape('#222222', backFoot[0] - 2, backFoot[1] - 1, 4, 2);
		this.#fillShape('#222222', frontFoot[0] - 2, frontFoot[1] - 1, 4, 2);
		// The yellow rain jacket of Bergen, the arms, and the head with a red beanie.
		this.#fillShape('#f2c200', -3, shoulderY, 7, hipY - shoulderY + 1);
		this.#fillShape('#c89a00', -3, hipY - 1, 7, 1);
		this.#strokeLine('#f2c200', 2, [[-1, shoulderY + 1], hands[0]]);
		this.#strokeLine('#f2c200', 2, [[2, shoulderY + 1], hands[1]]);
		this.#fillCircle('#f3c9a0', hands[0][0], hands[0][1], 1.2);
		this.#fillCircle('#f3c9a0', hands[1][0], hands[1][1], 1.2);
		this.#fillCircle('#f3c9a0', 1, shoulderY - 4, 3.5);
		this.#fillShape('#f0d060', -3, shoulderY - 5, 2, 3);
		this.#fillShape('#cc2222', -2, shoulderY - 9, 7, 3);
		this.#fillShape('#ffffff', 1, shoulderY - 11, 2, 2);
		this.#fillShape('#222222', 3, shoulderY - 5, 1, 1);
		this.#context.restore();
	}

	#drawSkater() {
		if (this.#skater.mode === 'bail') {
			this.#drawRagdoll();
			return;
		}

		this.#context.save();
		this.#context.translate(this.#screenX(this.#skater.x), this.#screenY(this.#skater.y));
		this.#context.rotate(-this.#skater.angle);
		const turn = Math.cos(this.#skater.spin * Math.PI / 180);
		const squash = Math.abs(turn) < 0.2 ? (turn < 0 ? -0.2 : 0.2) : turn;
		this.#context.scale(this.#skater.facing * squash, 1);
		this.#drawSkaterBody();
		this.#context.restore();
	}

	#drawRagdoll() {
		const {points, board} = this.#skater.ragdoll;
		const at = point => [this.#screenX(point.x), this.#screenY(point.y)];
		this.#context.save();
		this.#context.translate(this.#screenX(board.x), this.#screenY(board.y));
		this.#context.rotate(board.angle);
		this.#drawBoard({y: 0, roll: board.angle * 0.5});
		this.#context.restore();
		this.#strokeLine('#2f4f8a', 2.5, [at(points.footBack), at(points.hip), at(points.footFront)]);
		this.#strokeLine('#f2c200', 5, [at(points.hip), at(points.chest)]);
		this.#strokeLine('#f2c200', 2, [at(points.handBack), at(points.chest), at(points.handFront)]);
		const [headX, headY] = at(points.head);
		this.#fillCircle('#f3c9a0', headX, headY, 3.5);
		this.#fillShape('#cc2222', headX - 3, headY - 5, 7, 3);
		// Stars around the head.
		if (this.#state.clock - this.#skater.ragdoll.startedAt > 0.6) {
			for (let star = 0; star < 3; star++) {
				const angle = (this.reducedMotion ? 0 : this.#state.time * 5) + (star * Math.PI * 2 / 3);
				this.#drawText('*', headX + (Math.cos(angle) * 7), headY - 9 + (Math.sin(angle) * 2), '#ffee44', {shadow: undefined});
			}
		}
	}

	#drawParticles() {
		for (const particle of this.#state.particles) {
			this.#context.globalAlpha = clamp(1 - (particle.age / particle.life), 0, 1);
			this.#fillShape(particle.color, this.#screenX(particle.x), this.#screenY(particle.y), particle.size, particle.size);
		}

		this.#context.globalAlpha = 1;
	}

	#drawRain(seconds) {
		this.#context.strokeStyle = 'rgba(210, 225, 245, 0.55)';
		this.#context.lineWidth = 1;
		this.#context.beginPath();
		for (const drop of this.#rain) {
			if (!this.reducedMotion) {
				drop.y += drop.speed * seconds;
				drop.x -= drop.speed * 0.2 * seconds;
				if (drop.y > height) {
					drop.y -= height + 10;
					drop.x = Math.random() * (width + 40);
				}

				if (drop.x < -5) {
					drop.x += width + 10;
				}
			}

			const worldX = drop.x + this.#state.camera.x;
			if (worldX < garageEnd) {
				continue;
			}

			this.#context.moveTo(Math.round(drop.x) + 0.5, Math.round(drop.y));
			this.#context.lineTo(Math.round(drop.x) - 1.5, Math.round(drop.y) + 5);
		}

		this.#context.stroke();
		if (!this.reducedMotion && seconds > 0) {
			for (const ripple of this.#state.ripples) {
				ripple.age += seconds;
			}

			this.#state.ripples = this.#state.ripples.filter(ripple => ripple.age < 0.5);
			if (Math.random() < seconds * 14) {
				const puddle = randomItem([...puddles, {from: 1092, to: 1168, level: waterSurface}]);
				this.#state.ripples.push({x: randomBetween(puddle.from + 2, puddle.to - 2), y: puddle.level, age: 0});
			}
		}
	}

	#drawMeter(x, y, value, isVertical) {
		if (isVertical) {
			this.#fillShape('rgba(0, 0, 0, 0.6)', x - 2, y - 20, 5, 40);
			this.#fillShape('#66ff66', x - 2, y - 6, 5, 12);
			this.#fillShape('#ff3333', x - 2, y - 20, 5, 4);
			this.#fillShape('#ff3333', x - 2, y + 16, 5, 4);
			this.#fillShape('#ffffff', x - 4, y - Math.round(value * 18), 9, 2);
			return;
		}

		this.#fillShape('rgba(0, 0, 0, 0.6)', x - 20, y - 2, 40, 5);
		this.#fillShape('#66ff66', x - 6, y - 2, 12, 5);
		this.#fillShape('#ff3333', x - 20, y - 2, 4, 5);
		this.#fillShape('#ff3333', x + 16, y - 2, 4, 5);
		this.#fillShape('#ffffff', x + Math.round(value * 18) - 1, y - 4, 2, 9);
	}

	#drawHud() {
		this.#drawText(formatNumber(this.#state.score), 6, 6, '#ffffff', {scale: 2});
		// The special meter.
		this.#fillShape('rgba(0, 0, 0, 0.6)', 6, 20, 82, 6);
		const isFull = this.#state.special >= 1;
		const specialColor = isFull ? (this.#isBlinkOn(0.15) ? '#ff66ff' : '#66ffff') : '#ffdd00';
		this.#fillShape(specialColor, 7, 21, Math.round(80 * this.#state.special), 4);
		if (isFull) {
			this.#drawText('SPECIAL', 92, 21, specialColor);
		}

		if (this.#state.mode === 'run') {
			const seconds = Math.ceil(this.#state.runTime);
			const text = `${Math.floor(seconds / 60)}:${String(seconds % 60).padStart(2, '0')}`;
			this.#drawText(text, width - 6, 6, this.#state.runTime <= 10 && this.#isBlinkOn(0.25) ? '#ff3333' : '#ffffff', {scale: 2, align: 'right'});
		} else {
			this.#drawText('FREE SKATE', width - 6, 6, '#ffffff', {align: 'right'});
		}

		// The letters of the run, and the tape.
		for (const [index, spot] of letterSpots.entries()) {
			const isFound = this.#state.letters.has(spot.letter);
			this.#drawText(spot.letter, 168 + (index * 13), 6, isFound ? '#ffdd00' : '#8a8a96', {scale: 2, shadow: isFound ? 'rgba(0, 0, 0, 0.75)' : '#2a2a30'});
		}

		if (this.#state.hasTape) {
			this.#fillShape('#111111', 236, 7, 12, 8);
			this.#fillShape('#f4f4f4', 238, 8, 8, 3);
		}

		if (this.#state.plasters > 0) {
			this.#drawText(`PLASTERS: ${this.#state.plasters}`, width - 6, 22, '#ffcc99', {align: 'right'});
		}

		// The combo: the tricks, and the points times the multiplier.
		if (this.#state.combo) {
			const lines = wrapTricks(this.#state.combo.entries.map(entry => entry.name), 46).slice(-2);
			const base = Math.round(sumPoints(this.#state.combo.entries));
			const total = `${formatNumber(base)} × ${this.#state.combo.entries.length}`;
			const top = height - 12 - (lines.length * 12);
			this.#fillShape('rgba(0, 0, 0, 0.45)', 0, top - 4, width, height - top + 4);
			for (const [index, line] of lines.entries()) {
				this.#drawText(line, width / 2, top + (index * 12), '#ffffff', {scale: 2, align: 'center'});
			}

			this.#drawText(total, width / 2, height - 11, '#ffdd00', {scale: 2, align: 'center'});
		}

		// The balance of a grind or a manual.
		if (this.#skater.mode === 'grind') {
			this.#drawMeter(this.#screenX(this.#skater.x), this.#screenY(this.#skater.y) - 40, this.#skater.grind.balance, false);
		} else if (this.#skater.mode === 'manual') {
			this.#drawMeter(this.#screenX(this.#skater.x) + 18 * this.#skater.facing, this.#screenY(this.#skater.y) - 16, this.#skater.manual.balance, true);
		}

		for (const [index, message] of this.#state.messages.entries()) {
			this.#drawText(message.text, width / 2, 62 + (index * 18), message.color, {scale: message.scale, align: 'center'});
		}

		if (this.#state.cheer && this.#state.cheer.until > this.#state.time) {
			this.#drawText(this.#state.cheer.text, 6, 32, '#66ff66');
		}
	}

	#drawTitle() {
		this.#fillShape('rgba(0, 0, 0, 0.55)', 0, 24, width, 110);
		this.#drawText('SINDRE HAWK’S', width / 2, 34, '#ffffff', {scale: 3, align: 'center'});
		this.#drawText('PRO SKATER', width / 2, 58, this.#isBlinkOn(0.3) ? '#ffdd00' : '#ff8800', {scale: 5, align: 'center', shadow: '#aa2200'});
		this.#drawText('BERGEN 1999. IT RAINS. WE SKATE.', width / 2, 92, '#ffffff', {align: 'center'});
		if (this.#isBlinkOn(0.6)) {
			this.#drawText(startHint, width / 2, 106, '#66ffff', {scale: 2, align: 'center'});
		}

		this.#drawText(`HIGH SCORE ${formatNumber(this.#state.highScore)}`, width / 2, 122, '#ffdd00', {align: 'center'});
	}

	#drawResults() {
		this.#fillShape('rgba(0, 0, 0, 0.7)', 30, 22, width - 60, 170);
		this.#drawText('RUN OVER', width / 2, 30, '#ffdd00', {scale: 3, align: 'center'});
		const lines = [
			[`SCORE: ${formatNumber(this.#state.score)}`, this.#state.isNewHighScore ? '#66ff66' : '#ffffff'],
			[this.#state.isNewHighScore ? 'NEW HIGH SCORE!' : `HIGH SCORE: ${formatNumber(this.#state.highScore)}`, this.#state.isNewHighScore ? '#66ff66' : '#aaaaaa'],
			[`BEST COMBO: ${formatNumber(this.#state.bestRunCombo)}`, '#ffffff'],
			[`GAPS: ${this.#state.runGaps.size}  LETTERS: ${letterSpots.map(spot => (this.#state.letters.has(spot.letter) ? spot.letter : '-')).join('')}`, '#ffffff'],
			[`PLASTERS FROM MAMMA: ${this.#state.plasters}${this.#state.hasTape ? '  TAPE: YES!' : ''}`, '#ffcc99'],
		];
		for (const [index, [text, color]] of lines.entries()) {
			this.#drawText(text, width / 2, 60 + (index * 18), color, {scale: 2, align: 'center'});
		}

		if (this.#isBlinkOn(0.6)) {
			this.#drawText(`${startHint} TO SKATE AGAIN`, width / 2, 160, '#66ffff', {align: 'center'});
		}
	}

	#draw() {
		const seconds = clamp(this.#state.time - this.#lastDrawTime, 0, 0.05);
		this.#lastDrawTime = this.#state.time;
		this.#context.imageSmoothingEnabled = false;
		this.#drawSky();
		this.#drawTown();
		this.#drawGarage();
		this.#drawStalls();
		this.#drawTrond();
		this.#drawTerrain();
		this.#drawPuddles();
		this.#drawRails();
		this.#drawMormor();
		this.#drawPickups();
		this.#drawSkater();
		this.#drawParticles();
		this.#drawRain(seconds);
		if (this.#isPlaying()) {
			this.#drawHud();
		}

		if (this.#state.mode === 'title') {
			this.#drawTitle();
		} else if (this.#state.mode === 'results') {
			this.#drawResults();
		}

		// The loop stops while step mode waits for a button, and draws this when it stops.
		if (this.#isPaused()) {
			this.#fillShape('rgba(0, 0, 0, 0.6)', 80, 100, 240, 26);
			this.#drawText('STEP MODE', width / 2, 104, '#ffdd00', {align: 'center'});
			this.#drawText('HOLD A BUTTON TO SKATE', width / 2, 114, '#ffffff', {align: 'center'});
		}
	}

	// A moment on the results first, so a visitor who mashes Space or the screen at the end of the time sees the score.
	#startFromScreen() {
		if (performance.now() - this.#state.resultsAt > 800) {
			this.#startRun(true);
		}
	}

	// The controls: the keys on the screen, and the buttons below it for touch.
	#press(control) {
		if (this.#state.held[control]) {
			return;
		}

		this.#state.held[control] = true;
		this.#state.pressedAt[control] = this.#state.clock;
		this.#state.lastInputAt = performance.now();
		this.#state.presses.push({control, at: this.#state.clock});
		if (this.#state.presses.length > 6) {
			this.#state.presses.shift();
		}

		if (!this.#isPlaying()) {
			if (control === 'ollie') {
				this.#startFromScreen();
			}

			return;
		}

		if (this.#skater.mode !== 'bail') {
			switch (control) {
				case 'ollie': {
					this.#pressOllie();
					break;
				}

				case 'flip': {
					this.#pressFlip();
					break;
				}

				case 'grab': {
					this.#pressGrab();
					break;
				}

				case 'special': {
					this.#pressSpecial();
					break;
				}

				default: {
					this.#checkManualPress(control);
					break;
				}
			}
		}

		this.#loop.start();
	}

	#release(control) {
		if (!this.#state.held[control]) {
			return;
		}

		this.#state.held[control] = false;
		this.#state.lastInputAt = performance.now();
		if (!this.#isPlaying()) {
			return;
		}

		if (control === 'ollie') {
			this.#releaseOllie();
		}

		if (control === 'grab' && this.#skater.mode === 'air' && this.#skater.air.grab) {
			this.#skater.air.grab.releasedAt ??= this.#state.clock;
		}
	}

	#releaseAll() {
		for (const control of Object.keys(this.#state.held)) {
			this.#release(control);
		}
	}

	#setSound(isOn) {
		this.#isSoundOn = isOn && this.#startAudio();
		if (!this.#isSoundOn) {
			this.#quiet();
		}

		this.parts.sound.textContent = this.#isSoundOn ? '🔊 Sound On' : '🔇 Sound Off';
		this.parts.sound.setAttribute('aria-pressed', String(this.#isSoundOn));
	}

	#showStepMode() {
		this.parts.step.textContent = this.#state.stepMode ? 'Step Mode On' : 'Step Mode Off';
		this.parts.step.setAttribute('aria-pressed', String(this.#state.stepMode));
	}

	#setStepMode(isOn) {
		this.#state.stepMode = isOn;
		this.#showStepMode();
		this.#loop.start();
		this.#draw();
	}

	#showRecords() {
		this.parts.highScore.textContent = formatNumber(this.#state.highScore);
		this.parts.bestCombo.textContent = this.#state.bestCombo ? `${formatNumber(this.#state.bestCombo.score)}: ${this.#state.bestCombo.text}` : 'None yet';
		const run = this.#state.lastRun;
		const tape = this.#state.foundTape ? ' 📼 You found the secret tape once.' : '';
		this.parts.lastRun.textContent = run ? `${formatNumber(run.score)} points, ${run.gaps} ${run.gaps === 1 ? 'gap' : 'gaps'}, letters ${run.letters}, ${run.plasters} ${run.plasters === 1 ? 'plaster' : 'plasters'}.${tape}` : `Not yet.${tape}`;
	}

	#showGaps() {
		const items = this.querySelectorAll('[data-skater-gap]');
		for (const item of items) {
			const isFound = this.#state.foundGaps.has(item.dataset.skaterGap);
			if (isFound) {
				item.dataset.state = 'found';
			} else {
				delete item.dataset.state;
			}

			item.querySelector('span').textContent = isFound ? '☑' : '☐';
		}

		this.parts.gapCount.textContent = `${this.#state.foundGaps.size}/${items.length}`;
	}
}
