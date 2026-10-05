// Bop It! on the 1999 page: the toy of Hasbro (1996) that yells commands, and Bop It Extreme (1998), drawn on a canvas. A voice of `speechSynthesis` yells “Bop it!”, “Twist it!”, or “Pull it!” over a drum loop made with the Web Audio API, and the visitor does it the right way before the next beat. The beat speeds up, a wrong or late move ends the round, and the best scores and the charge of the batteries are kept in the browser. Nothing makes a sound until the visitor presses Start or turns on the sound, and the canvas only animates while it is on the screen and the tab is visible. With reduced motion, the toy does not wiggle, and the parts only move while the visitor moves them.

const randomItem = items => items[Math.floor(Math.random() * items.length)];

const clamp = (value, minimum, maximum) => Math.min(Math.max(value, minimum), maximum);

// Shows a toggle button as pressed, for screen readers and for the style.
const setPressed = (button, isPressed) => {
	button.setAttribute('aria-pressed', String(isPressed));
	button.dataset.state = isPressed ? 'on' : '';
};

// What the toy yells, in English and in Norwegian. “Dunk den” is what we said for “bop it” in the schoolyard.
const languages = {
	english: {
		language: 'en-US',
		bop: 'Bop it!',
		twist: 'Twist it!',
		pull: 'Pull it!',
		flick: 'Flick it!',
		spin: 'Spin it!',
		shout: 'Shout it!',
		pass: 'Pass it!',
		fail: 'Ohhh!',
		dead: 'Bop iiiit…',
		score: score => `Your score is ${score}.`,
		best: 'New high score!',
		out: name => `${name} is out!`,
		win: name => `${name} wins!`,
		master: 'One hundred! You are a Bop It master!',
	},
	norwegian: {
		language: 'nb-NO',
		bop: 'Dunk den!',
		twist: 'Vri den!',
		pull: 'Dra den!',
		flick: 'Knips den!',
		spin: 'Snurr den!',
		shout: 'Rop den!',
		pass: 'Send den!',
		fail: 'Åååh nei!',
		dead: 'Dunk deeeen…',
		score: score => `Du fikk ${score} poeng.`,
		best: 'Ny rekord!',
		out: name => `${name} er ute!`,
		win: name => `${name} vant!`,
		master: 'Hundre! Du er en Bop It-mester!',
	},
};

const pastTense = {
	bop: 'bopped it',
	twist: 'twisted it',
	pull: 'pulled it',
	flick: 'flicked it',
	spin: 'spun it',
	shout: 'shouted',
};

// How to do each command, for a visitor who did not know when the toy asked for it.
const howTo = {
	bop: 'To bop it, press the purple button, or Space.',
	twist: 'To twist it, drag around the blue crank in a circle, or press ← or →.',
	pull: 'To pull it, drag the green handle down, or press Enter or ↓.',
	flick: 'To flick it, flick the orange stick to the side, or press ↑.',
	spin: 'To spin it, swipe across the red wheel, or press S.',
	shout: 'To shout it, press the speaker, or Y.',
};

const toyParts = {
	classic: ['bop', 'twist', 'pull'],
	extreme: ['bop', 'twist', 'pull', 'flick', 'spin'],
};

// The seconds between two commands, at the start and at the fastest. Extreme has more to think about, so it starts slower.
const tempos = {
	classic: {start: 1.5, step: 0.025, fastest: 0.72},
	extreme: {start: 1.75, step: 0.025, fastest: 0.85},
};

// The best scores of Trond, who owns the toy, and reminds me of them every day.
const rivals = {classic: 41, extreme: 33};

const toyNames = {classic: 'Bop It!', extreme: 'Bop It Extreme'};

const lowBattery = 30;

// A score or a count from the storage must be a whole number that is not negative, as the toy picks a line of text with it.
const toCount = value => Number.isSafeInteger(value) && value >= 0 ? value : 0;

// The voice. A high pitch and a fast rate make it peppy, like the real toy. Weak batteries make it slow and deep.
let voices = [];
const loadVoices = () => {
	voices = speechSynthesis.getVoices();
};

if ('speechSynthesis' in globalThis) {
	loadVoices();
	speechSynthesis.addEventListener('voiceschanged', loadVoices);
}

const voiceFor = language => {
	const prefixes = language === 'nb-NO' ? ['nb', 'no', 'nn'] : ['en-us', 'en'];
	for (const prefix of prefixes) {
		const voice = voices.find(candidate => candidate.lang.toLowerCase().replace('_', '-').startsWith(prefix));
		if (voice) {
			return voice;
		}
	}

	return undefined;
};

const hushVoice = () => {
	if ('speechSynthesis' in globalThis) {
		speechSynthesis.cancel();
	}
};

// Where the parts are on the canvas, for the drawing and for the hands of the visitor.
const layouts = {
	classic: {
		bop: {x: 240, y: 204, radius: 50},
		twist: {x: 92, y: 165, radius: 52},
		pull: {x: 388, top: 196, grip: 250, travel: 44},
		led: {x: 146, y: 198},
	},
	extreme: {
		hub: {x: 240, y: 178},
		bop: {x: 240, y: 176, radius: 46},
		twist: {x: 96, y: 108, radius: 46},
		flick: {x: 392, y: 126},
		spin: {x: 98, y: 282, width: 128, height: 50},
		pull: {x: 398, top: 236, grip: 276, travel: 40},
		shout: {x: 240, y: 300, radius: 30},
		led: {x: 286, y: 128},
	},
};

// The background of the canvas, like the wrapping paper of a birthday in 1999, drawn once.
const makeBackground = (width, height) => {
	const layer = document.createElement('canvas');
	layer.width = width;
	layer.height = height;
	const layerContext = layer.getContext('2d');
	const gradient = layerContext.createLinearGradient(0, 0, width, height);
	gradient.addColorStop(0, '#3b0a6e');
	gradient.addColorStop(1, '#0a4f6e');
	layerContext.fillStyle = gradient;
	layerContext.fillRect(0, 0, width, height);

	// A random generator with a seed, so the confetti is the same each time.
	let seed = 1999;
	const random = () => {
		seed = ((seed * 1_103_515_245) + 12_345) % 2_147_483_648;
		return seed / 2_147_483_648;
	};

	const colors = ['#ff3399', '#ffff33', '#33ffcc', '#ff9933', '#66ccff'];
	layerContext.globalAlpha = 0.35;
	layerContext.lineWidth = 3;
	for (let index = 0; index < 34; index++) {
		const x = random() * width;
		const y = random() * height;
		const size = 6 + (random() * 10);
		const color = colors[index % colors.length];
		layerContext.strokeStyle = color;
		layerContext.fillStyle = color;
		const shape = index % 3;
		if (shape === 0) {
			layerContext.beginPath();
			layerContext.moveTo(x, y - size);
			layerContext.lineTo(x + size, y + size);
			layerContext.lineTo(x - size, y + size);
			layerContext.closePath();
			layerContext.stroke();
		} else if (shape === 1) {
			layerContext.beginPath();
			layerContext.moveTo(x - (size * 1.5), y);
			for (let wave = 1; wave <= 4; wave++) {
				layerContext.lineTo(x - (size * 1.5) + (wave * size * 0.75), y + (wave % 2 === 0 ? 0 : size * 0.6));
			}

			layerContext.stroke();
		} else {
			layerContext.beginPath();
			layerContext.arc(x, y, size / 3, 0, Math.PI * 2);
			layerContext.fill();
		}
	}

	return layer;
};

const palette = {
	yellow: ['#fff58a', '#ffd400', '#b38300'],
	teal: ['#a8fff6', '#19d3c5', '#0a6f68'],
	purple: ['#e2b8ff', '#8a2be2', '#3d0a73'],
	blue: ['#a8d0ff', '#1e6fff', '#0b3a99'],
	green: ['#b0ffa6', '#19c219', '#0b6e0b'],
	orange: ['#ffd8a8', '#ff8c1a', '#994400'],
	red: ['#ffb3b3', '#ff2a2a', '#880000'],
	gray: ['#f2f2f2', '#a0a0a0', '#404040'],
};

const commandColors = {
	bop: '#c58cff',
	twist: '#66b3ff',
	pull: '#66ff66',
	flick: '#ffaa33',
	spin: '#ff5555',
	shout: '#ffffff',
};

const outline = '#1a0a2a';

const turnLength = () => 3 + Math.floor(Math.random() * 4);

// The messages of Lillesøster, who wants a turn more each time she does not get one.
const nags = [
	'Lillesøster: “Min tur! Min tur!” (My turn! My turn!)',
	'Lillesøster: “MIN TUR!” She stands in the door and does not go away.',
	'Mamma, from the kitchen: “Sindre, la henne prøve!” (Let her try!)',
	'Lillesøster went to tell Pappa too. Pappa says it is Trond’s toy anyway.',
];

// The batteries come from somewhere else in the house each time.
const batterySources = [
	'There are no new batteries in the kitchen drawer, so you take them from the TV remote. Pappa will not notice.',
	'You take the batteries from Lillesøster’s Walkman. She will notice.',
	'Mamma bought a pack of 4 at Rimi. Only 3 fit, so one goes in the drawer for next time.',
	'You take them from the smoke alarm. Mamma says absolutely not, so you take them from the kitchen clock instead.',
	'You borrow batteries from Trond. They were his batteries anyway.',
];

const keys = {
	' ': ['bop', 1],
	b: ['bop', 1],
	arrowleft: ['twist', -1],
	arrowright: ['twist', 1],
	t: ['twist', 1],
	enter: ['pull', 1],
	arrowdown: ['pull', 1],
	p: ['pull', 1],
	arrowup: ['flick', 1],
	f: ['flick', 1],
	s: ['spin', 1],
	y: ['shout', 1],
};

export default class extends GeoCitiesElement {
	#context;
	#background;
	#loop;
	#best;
	#battery;
	#sisterBest;
	#batteryChanges;
	#isLowWarned;

	#settings = {
		toy: 'classic',
		kind: 'solo',
		isNorwegian: false,
		hasShout: false,
	};

	// The sound, made in the browser once the visitor asks for it.
	#audio = {
		context: undefined,
		output: undefined,
		noise: undefined,
		isOn: false,
	};

	// The microphone, for a real “Shout it!”. The visitor wants it with “Really Shout”, but it is only open during a round with “Shout it!”, while the toy is on screen and the tab is visible. It hears the voice of the toy too, so it does not listen right after the toy speaks.
	#microphone = {
		isWanted: false,
		isOpening: false,
		stream: undefined,
		source: undefined,
		analyser: undefined,
		data: undefined,
		interval: undefined,
		loudSince: undefined,
		lastShout: 0,
		ignoreUntil: 0,
	};

	// How the parts are moved right now. The springs bring them back after the visitor lets go.
	#motion = {
		bop: 0,
		crank: 0,
		crankTarget: 0,
		pull: 0,
		flick: 0,
		flickVelocity: 0,
		wheel: 0,
		wheelVelocity: 0,
		shout: 0,
		wiggle: 0,
		wiggleTime: 1,
		flash: 0,
	};

	#view = 'front';
	#insertedBatteries = 0;
	#gesture;

	#game = {
		phase: 'idle',
		who: 'visitor',
		kind: 'solo',
		toy: 'classic',
		parts: toyParts.classic,
		command: undefined,
		answered: false,
		score: 0,
		period: tempos.classic.start,
		commandStart: 0,
		commandPeriod: 1,
		timer: undefined,
		sisterTimer: undefined,
		players: [],
		current: 0,
		turnLeft: 0,
		history: [],
		resumePhase: undefined,
	};

	#sister = {
		gamesSince: 0,
		nags: 0,
	};

	connected() {
		const {canvas, batteries, start, sister, norwegian, shout, sound, microphone, classic, extreme, solo, pass} = this.parts;
		const settings = this.#settings;
		this.#context = canvas.getContext('2d');
		this.#background = makeBackground(canvas.width, canvas.height);

		const storedBest = this.stored('best', {});
		this.#best = {
			classic: toCount(storedBest.classic),
			extreme: toCount(storedBest.extreme),
		};

		const storedBattery = this.stored('batteries', 100);
		this.#battery = Number.isFinite(storedBattery) ? clamp(storedBattery, 0, 100) : 100;
		this.#sisterBest = toCount(this.stored('sister-best', 0));
		this.#batteryChanges = toCount(this.stored('battery-changes', 0));
		this.#isLowWarned = this.#battery < lowBattery;

		this.#loop = this.loop(seconds => {
			this.#step(seconds);
		}, {while: () => this.#isAnimating()});

		this.on(batteries, 'click', () => {
			if (this.#isRunning()) {
				return;
			}

			if (this.#view === 'back') {
				this.#insertBattery();
				return;
			}

			this.#view = 'back';
			this.#insertedBatteries = 0;
			this.#setBattery(0);
			const source = batterySources[this.#batteryChanges % batterySources.length];
			this.#batteryChanges++;
			this.store('battery-changes', this.#batteryChanges);
			batteries.textContent = '🔋 Put In Battery 1 of 3';
			this.#updateControls();
			this.#showCommand('', 'dead');
			this.say(`You open the battery door with a coin, and take out the old ones. ${source}`);
			this.#requestDraw();
		});

		this.on(start, 'click', () => {
			if (this.#isRunning()) {
				this.#stop(this.#game.who === 'sister' ? 'sister' : 'visitor');
				return;
			}

			this.#start('visitor');
		});

		this.on(sister, 'click', () => {
			if (!this.#isRunning()) {
				this.#start('sister');
			}
		});

		// The name of the part of a toy button is the toy, like `extreme`, and the same for the game buttons.
		for (const button of [classic, extreme]) {
			this.on(button, 'click', () => {
				settings.toy = button.dataset.part;
				for (const other of [classic, extreme]) {
					setPressed(other, other === button);
				}

				this.#updateControls();
				this.#updateStats();
				this.#requestDraw();
				this.say(settings.toy === 'extreme' ? 'Bop It Extreme (1998): five things to do. Trond’s best is 33.' : 'The first Bop It (1996): bop it, twist it, pull it. Trond’s best is 41.');
			});
		}

		for (const button of [solo, pass]) {
			this.on(button, 'click', () => {
				settings.kind = button.dataset.part;
				for (const other of [solo, pass]) {
					setPressed(other, other === button);
				}

				this.#updateControls();
				this.say(settings.kind === 'pass' ? 'Pass It: write the names, and sit in a circle.' : 'Solo: just you and the toy.');
			});
		}

		this.on(norwegian, 'click', () => {
			settings.isNorwegian = !settings.isNorwegian;
			setPressed(norwegian, settings.isNorwegian);
			this.#speak(settings.isNorwegian ? 'Dunk den! Vri den! Dra den!' : 'Bop it! Twist it! Pull it!');
			this.say(settings.isNorwegian ? 'Nå roper den på norsk: “Dunk den! Vri den! Dra den!” (Now it yells in Norwegian.)' : 'The toy yells in English again.');
		});

		this.on(shout, 'click', () => {
			settings.hasShout = !settings.hasShout;
			setPressed(shout, settings.hasShout);
			if (!settings.hasShout) {
				this.#setMicrophoneWanted(false);
			}

			this.#updateControls();
			this.#requestDraw();
			this.say(settings.hasShout ? '“Shout it!” is in, like on the later Bop Its. Click the speaker, press Y, or turn on “Really Shout”.' : '“Shout it!” is out again. The neighbors say thank you.');
		});

		this.on(sound, 'click', () => {
			if (this.#audio.isOn) {
				this.#audio.isOn = false;
				hushVoice();
				setPressed(sound, false);
				sound.textContent = '🔈 Sound Off';
				return;
			}

			this.#turnOnSound();
			this.#partSounds.bop();
		});

		this.on(microphone, 'click', () => {
			if (this.#microphone.isWanted) {
				this.#setMicrophoneWanted(false);
				this.say('The microphone is off. Click the speaker to shout.');
				return;
			}

			if (!navigator.mediaDevices?.getUserMedia || !this.#turnOnSound()) {
				this.say('This computer has no microphone. Click the speaker to shout instead.');
				return;
			}

			this.#setMicrophoneWanted(true);

			// The browser asks for the microphone now, and not in the middle of a round. Outside a round, it closes again at once.
			if (!this.#microphone.stream && !this.#microphone.isOpening) {
				this.#openMicrophone();
			}

			this.say('The microphone listens during a round. When the toy says “Shout it!”, SHOUT! (Mamma is on the phone, so maybe not too loud.)');
		});

		this.on(canvas, 'pointerdown', event => {
			this.#pointerDown(event);
		});

		this.on(canvas, 'pointermove', event => {
			this.#pointerMove(event);
		});

		this.on(canvas, 'pointerup', event => {
			this.#endGesture(event);
		});

		this.on(canvas, 'pointercancel', event => {
			this.#endGesture(event);
		});

		// A finger on a part of the toy, or on the open battery door, uses it instead of scrolling the page. Beside the parts, it scrolls the page.
		this.on(canvas, 'touchstart', event => {
			if (this.#view === 'back' || this.#hitTest(this.#toCanvas(event.changedTouches[0]))) {
				event.preventDefault();
			}
		}, {passive: false});

		this.on(canvas, 'keydown', event => {
			this.#keyDown(event);
		});

		this.#updateControls();
		this.#updateStats();
		this.#draw();
	}

	// The toy follows the canvas, so a round does not go on while only the buttons are on the screen.
	get visibilityTarget() {
		return this.parts.canvas;
	}

	// The toy pauses while it is off the screen or the tab is hidden, and goes on when it is back. A removed toy is not on the screen either, so it pauses the same way, and closes the microphone.
	visibilityChanged(isVisible) {
		const game = this.#game;
		if (!isVisible && this.#isRunning() && game.phase !== 'paused') {
			this.#clearTimers();
			hushVoice();

			// A pause during “Pass it!”, or after a player went out, goes on with the next player.
			game.resumePhase = ['passing', 'over'].includes(game.phase) ? 'passing' : 'starting';
			game.phase = 'paused';
			this.#showCommand('PAUSED', '');
			this.say('Paused, as the Bop It is off the screen. Come back, and it goes on.');
		} else if (isVisible && game.phase === 'paused') {
			game.phase = game.resumePhase;
			this.#showCommand('READY?', '');
			this.say('Back! Get ready…');
			this.#later(1.5, () => {
				this.#tick();
			});
		}

		this.#updateMicrophone();
	}

	reducedMotionChanged() {
		this.#motion.wiggleTime = 1;
		this.#requestDraw();
	}

	musicStopped() {
		if (this.#isRunning()) {
			this.#stop('music');
		}
	}

	#words() {
		return this.#settings.isNorwegian ? languages.norwegian : languages.english;
	}

	// How strong the batteries still are, from 1 down to 0. Under 30%, the voice and the beat get slower and deeper.
	#power() {
		return this.#battery >= lowBattery ? 1 : clamp(this.#battery / lowBattery, 0, 1);
	}

	#turnOnAudio() {
		const audio = this.#audio;
		const sound = this.sound();
		if (!sound) {
			return false;
		}

		if (!audio.context) {
			audio.context = sound.context;
			audio.output = new GainNode(audio.context, {gain: 0.5});
			audio.output.connect(sound.output);
			const buffer = audio.context.createBuffer(1, audio.context.sampleRate, audio.context.sampleRate);
			const samples = buffer.getChannelData(0);
			for (let index = 0; index < samples.length; index++) {
				samples[index] = (Math.random() * 2) - 1;
			}

			audio.noise = buffer;
		}

		audio.context.resume();
		audio.isOn = true;
		return true;
	}

	// One note with a quick start and a fade, which can slide to another pitch.
	#tone(frequency, start, duration, {type = 'square', volume = 0.1, slide, attack = 0.005} = {}) {
		const audio = this.#audio;
		if (!audio.isOn) {
			return;
		}

		const time = audio.context.currentTime + start;
		const oscillator = new OscillatorNode(audio.context, {type, frequency});
		oscillator.frequency.setValueAtTime(frequency, time);
		if (slide) {
			oscillator.frequency.exponentialRampToValueAtTime(slide, time + duration);
		}

		const gain = new GainNode(audio.context, {gain: 0});
		gain.gain.setValueAtTime(0.0001, time);
		gain.gain.exponentialRampToValueAtTime(volume, time + attack);
		gain.gain.exponentialRampToValueAtTime(0.0001, time + duration);
		oscillator.connect(gain).connect(audio.output);
		oscillator.start(time);
		oscillator.stop(time + duration + 0.05);
	}

	// A burst of noise through a filter, for drums, clicks, and the whoosh of “Pass it!”.
	#noise(start, duration, {volume = 0.1, type = 'bandpass', frequency = 2000, q = 1, sweepTo} = {}) {
		const audio = this.#audio;
		if (!audio.isOn) {
			return;
		}

		const time = audio.context.currentTime + start;
		const source = new AudioBufferSourceNode(audio.context, {buffer: audio.noise, loop: true});
		const filter = new BiquadFilterNode(audio.context, {type, frequency, Q: q});
		if (sweepTo) {
			filter.frequency.setValueAtTime(frequency, time);
			filter.frequency.exponentialRampToValueAtTime(sweepTo, time + duration);
		}

		const gain = new GainNode(audio.context, {gain: 0});
		gain.gain.setValueAtTime(volume, time);
		gain.gain.exponentialRampToValueAtTime(0.0001, time + duration);
		source.connect(filter).connect(gain).connect(audio.output);
		source.start(time, Math.random() * 0.5);
		source.stop(time + duration + 0.05);
	}

	// The drum loop of the toy, a bar of eighth notes for each command. Weak batteries make it lower.
	#drums = {
		kick: start => {
			const strength = 0.55 + (0.45 * this.#power());
			this.#tone(150 * strength, start, 0.2, {type: 'sine', volume: 0.6, slide: 45 * strength});
		},
		snare: start => {
			const strength = 0.55 + (0.45 * this.#power());
			this.#noise(start, 0.14, {volume: 0.3, frequency: 1800 * strength, q: 0.8});
			this.#tone(190 * strength, start, 0.08, {type: 'triangle', volume: 0.15});
		},
		hat: (start, volume = 0.08) => {
			this.#noise(start, 0.035, {volume, type: 'highpass', frequency: 7000});
		},
	};

	#playBar(period, offset = 0) {
		const step = period / 8;
		for (let index = 0; index < 8; index++) {
			const start = offset + (index * step);
			if (index === 0 || index === 3) {
				this.#drums.kick(start);
			}

			if (index === 4) {
				this.#drums.snare(start);
			}

			if (index % 2 === 0) {
				this.#drums.hat(start);
			} else if (index === 7) {
				this.#drums.hat(start, 0.04);
			}
		}
	}

	// Each part of the toy makes its own sound, like on the real one.
	#partSounds = {
		bop: () => {
			this.#tone(330, 0, 0.14, {type: 'sine', volume: 0.45, slide: 130});
			this.#noise(0, 0.03, {volume: 0.15, type: 'highpass', frequency: 3000});
		},
		twist: () => {
			for (let index = 0; index < 6; index++) {
				this.#noise(index * 0.035, 0.02, {volume: 0.25, frequency: 3200, q: 4});
			}
		},
		pull: () => {
			this.#tone(260, 0, 0.22, {type: 'sine', volume: 0.3, slide: 1100});
		},
		flick: () => {
			for (let index = 0; index < 6; index++) {
				this.#tone(index % 2 === 0 ? 560 : 430, index * 0.045, 0.06, {type: 'triangle', volume: 0.2 - (index * 0.025)});
			}
		},
		spin: () => {
			this.#tone(180, 0, 0.35, {type: 'sawtooth', volume: 0.1, slide: 720});
			this.#noise(0, 0.3, {volume: 0.08, frequency: 1200, sweepTo: 4000});
		},
		shout: () => {
			this.#noise(0, 0.35, {volume: 0.25, frequency: 900, q: 0.6});
			this.#tone(220, 0, 0.3, {type: 'sawtooth', volume: 0.1, slide: 330});
		},
	};

	#effects = {
		// The famous sound of a mistake: a crash and a sad “wah wah wahhh”.
		fail: () => {
			this.#noise(0, 0.45, {volume: 0.35, type: 'lowpass', frequency: 3000, sweepTo: 200});
			this.#tone(392, 0.05, 0.22, {type: 'sawtooth', volume: 0.15, slide: 370});
			this.#tone(349, 0.3, 0.22, {type: 'sawtooth', volume: 0.15, slide: 330});
			this.#tone(311, 0.55, 0.7, {type: 'sawtooth', volume: 0.15, slide: 150});
		},
		pass: () => {
			this.#noise(0, 0.5, {volume: 0.3, frequency: 300, q: 2, sweepTo: 3500});
		},
		faster: () => {
			for (const [index, frequency] of [523, 659, 784, 1047].entries()) {
				this.#tone(frequency, index * 0.06, 0.09, {type: 'square', volume: 0.06});
			}
		},
		win: () => {
			for (const [index, frequency] of [523, 659, 784, 1047, 784, 1047, 1319].entries()) {
				this.#tone(frequency, index * 0.12, 0.18, {type: 'square', volume: 0.08});
			}
		},
		die: () => {
			this.#tone(300, 0, 1.6, {type: 'sawtooth', volume: 0.12, slide: 30});
		},
		click: () => {
			this.#noise(0, 0.05, {volume: 0.3, type: 'highpass', frequency: 2000});
			this.#tone(900, 0, 0.04, {volume: 0.05});
		},
		jingle: () => {
			for (const [index, frequency] of [392, 523, 659, 784].entries()) {
				this.#tone(frequency, index * 0.08, 0.12, {type: 'triangle', volume: 0.15});
			}
		},
	};

	#speak(text, {rate = 1.3, pitch = 1.6, isQueued = false} = {}) {
		if (!this.#audio.isOn || !('speechSynthesis' in globalThis)) {
			return;
		}

		if (!isQueued) {
			speechSynthesis.cancel();
		}

		const utterance = new SpeechSynthesisUtterance(text);
		const {language} = this.#words();
		utterance.lang = language;
		const voice = voiceFor(language);
		if (voice) {
			utterance.voice = voice;
		}

		const strength = this.#power();
		utterance.rate = clamp(rate * (0.4 + (0.6 * strength)), 0.1, 10);
		utterance.pitch = clamp(pitch * (0.05 + (0.95 * strength)), 0, 2);
		speechSynthesis.speak(utterance);
		this.#microphone.ignoreUntil = performance.now() + 700;
	}

	#isRunning() {
		return this.#game.phase !== 'idle';
	}

	#partsOf(toy) {
		return toy === 'extreme' && this.#settings.hasShout ? [...toyParts.extreme, 'shout'] : toyParts[toy];
	}

	#currentToy() {
		return this.#isRunning() ? this.#game.toy : this.#settings.toy;
	}

	#availableParts() {
		return this.#isRunning() ? this.#game.parts : this.#partsOf(this.#settings.toy);
	}

	#showCommand(text, state) {
		const {command} = this.parts;
		command.textContent = text;
		command.dataset.state = state;
	}

	#ball(x, y, radius, [light, base, dark]) {
		const context = this.#context;
		const gradient = context.createRadialGradient(x - (radius * 0.35), y - (radius * 0.4), radius * 0.1, x, y, radius);
		gradient.addColorStop(0, light);
		gradient.addColorStop(0.55, base);
		gradient.addColorStop(1, dark);
		context.beginPath();
		context.arc(x, y, radius, 0, Math.PI * 2);
		context.fillStyle = gradient;
		context.fill();
		context.lineWidth = 3;
		context.strokeStyle = outline;
		context.stroke();
	}

	// A thick plastic tube along a path, with an outline and a shine on top.
	#tube(path, thickness, [light, base, dark]) {
		const context = this.#context;
		context.save();
		context.lineCap = 'round';
		context.lineJoin = 'round';
		context.lineWidth = thickness + 6;
		context.strokeStyle = outline;
		path();
		context.stroke();
		context.lineWidth = thickness;
		context.strokeStyle = dark;
		path();
		context.stroke();
		context.lineWidth = thickness * 0.78;
		context.strokeStyle = base;
		path();
		context.stroke();
		context.translate(0, -thickness * 0.2);
		context.lineWidth = thickness * 0.2;
		context.strokeStyle = light;
		context.globalAlpha = 0.75;
		path();
		context.stroke();
		context.restore();
	}

	#label(text, x, y, {size = 16, color = '#ffffff'} = {}) {
		const context = this.#context;
		context.font = `bold ${size}px "Comic Sans MS", "Chalkboard SE", "Comic Neue", cursive`;
		context.textAlign = 'center';
		context.textBaseline = 'middle';
		context.lineJoin = 'round';
		context.lineWidth = 4;
		context.strokeStyle = outline;
		context.strokeText(text, x, y);
		context.fillStyle = color;
		context.fillText(text, x, y);
	}

	#drawLogo(text, x, size) {
		const context = this.#context;
		context.save();
		context.translate(x, 36);
		context.rotate(-0.05);
		context.font = `${size}px Impact, "Arial Black", sans-serif`;
		context.textAlign = 'center';
		context.textBaseline = 'middle';
		context.lineJoin = 'round';
		context.lineWidth = 9;
		context.strokeStyle = outline;
		context.strokeText(text, 0, 0);
		const gradient = context.createLinearGradient(0, -size / 2, 0, size / 2);
		gradient.addColorStop(0, '#ffff66');
		gradient.addColorStop(0.5, '#ffcc00');
		gradient.addColorStop(1, '#ff3399');
		context.fillStyle = gradient;
		context.fillText(text, 0, 0);
		context.restore();
	}

	#drawBop({x, y, radius}) {
		const context = this.#context;
		const press = this.#motion.bop;
		context.beginPath();
		context.arc(x, y + 6, radius + 9, 0, Math.PI * 2);
		context.fillStyle = '#2a0650';
		context.fill();
		context.lineWidth = 3;
		context.strokeStyle = outline;
		context.stroke();

		// The button goes down into its collar while it is pressed.
		const offset = press * 7;
		this.#ball(x, y - 3 + offset, radius * (1 - (press * 0.05)), palette.purple);
		context.beginPath();
		context.ellipse(x - (radius * 0.3), y - (radius * 0.45) + offset, radius * 0.32, radius * 0.15, -0.5, 0, Math.PI * 2);
		context.fillStyle = 'rgba(255, 255, 255, 0.55)';
		context.fill();
		this.#label('BOP', x, y + 4 + offset, {size: 17, color: '#f3e0ff'});
	}

	#drawCrank({x, y, radius}) {
		const context = this.#context;
		const motion = this.#motion;
		const [light, base, dark] = palette.blue;
		const gradient = context.createRadialGradient(x - (radius * 0.3), y - (radius * 0.3), radius * 0.1, x, y, radius);
		gradient.addColorStop(0, light);
		gradient.addColorStop(0.6, base);
		gradient.addColorStop(1, dark);
		context.beginPath();
		context.arc(x, y, radius, 0, Math.PI * 2);
		context.fillStyle = gradient;
		context.fill();
		context.lineWidth = 3;
		context.strokeStyle = outline;
		context.stroke();

		// The grips around the edge turn with the crank.
		context.lineCap = 'round';
		context.lineWidth = 5;
		context.strokeStyle = dark;
		for (let index = 0; index < 12; index++) {
			const angle = motion.crank + (index * Math.PI / 6);
			context.beginPath();
			context.moveTo(x + (Math.cos(angle) * radius * 0.66), y + (Math.sin(angle) * radius * 0.66));
			context.lineTo(x + (Math.cos(angle) * radius * 0.92), y + (Math.sin(angle) * radius * 0.92));
			context.stroke();
		}

		context.beginPath();
		context.arc(x, y, radius * 0.5, 0, Math.PI * 2);
		context.fillStyle = base;
		context.fill();
		context.lineWidth = 2;
		context.strokeStyle = dark;
		context.stroke();

		const pegAngle = motion.crank - (Math.PI / 2);
		this.#ball(x + (Math.cos(pegAngle) * radius * 0.32), y + (Math.sin(pegAngle) * radius * 0.32), radius * 0.2, palette.blue);

		// A round arrow outside the crank shows which way to turn it.
		const arrowRadius = radius + 12;
		const end = -0.75;
		for (const [color, lineWidth] of [[outline, 7], ['#ffffff', 3]]) {
			context.strokeStyle = color;
			context.fillStyle = color;
			context.lineWidth = lineWidth;
			context.beginPath();
			context.arc(x, y, arrowRadius, -2.6, end);
			context.stroke();
			const tipX = x + (Math.cos(end) * arrowRadius);
			const tipY = y + (Math.sin(end) * arrowRadius);
			const size = lineWidth + 5;
			context.beginPath();
			context.moveTo(tipX + (Math.cos(end + (Math.PI / 2)) * size * 1.4), tipY + (Math.sin(end + (Math.PI / 2)) * size * 1.4));
			context.lineTo(tipX + (Math.cos(end) * size), tipY + (Math.sin(end) * size));
			context.lineTo(tipX - (Math.cos(end) * size), tipY - (Math.sin(end) * size));
			context.closePath();
			context.fill();
		}
	}

	#drawPull({x, top, grip}) {
		const context = this.#context;
		const offset = this.#motion.pull;
		const shaft = context.createLinearGradient(x - 9, 0, x + 9, 0);
		shaft.addColorStop(0, '#606060');
		shaft.addColorStop(0.4, '#f0f0f0');
		shaft.addColorStop(1, '#707070');
		context.fillStyle = shaft;
		context.fillRect(x - 9, top, 18, grip - top + offset + 4);
		context.lineWidth = 2;
		context.strokeStyle = outline;
		context.strokeRect(x - 9, top, 18, grip - top + offset + 4);

		const [light, base, dark] = palette.green;
		const fill = context.createLinearGradient(0, grip + offset, 0, grip + offset + 30);
		fill.addColorStop(0, light);
		fill.addColorStop(0.45, base);
		fill.addColorStop(1, dark);
		context.beginPath();
		context.roundRect(x - 48, grip + offset, 96, 30, 15);
		context.fillStyle = fill;
		context.fill();
		context.lineWidth = 3;
		context.strokeStyle = outline;
		context.stroke();

		// The grooves for the fingers.
		context.lineWidth = 3;
		context.strokeStyle = dark;
		for (const groove of [-24, -8, 8, 24]) {
			context.beginPath();
			context.moveTo(x + groove, grip + offset + 8);
			context.lineTo(x + groove, grip + offset + 22);
			context.stroke();
		}
	}

	#drawFlick({x, y}) {
		const context = this.#context;
		const bend = this.#motion.flick;
		this.#ball(x, y, 22, palette.gray);
		this.#tube(() => {
			context.beginPath();
			context.moveTo(x, y);
			context.quadraticCurveTo(x + (bend * 0.2), y - 40, x + bend, y - 70);
		}, 14, palette.orange);
		this.#ball(x + bend, y - 74, 15, palette.orange);
	}

	// The spin wheel turns on an axis that stands up, so its ridges move across it when it is swiped.
	#drawWheel({x, y, width: wheelWidth, height: wheelHeight}) {
		const context = this.#context;
		const left = x - (wheelWidth / 2);
		const top = y - (wheelHeight / 2);
		const [light, base, dark] = palette.red;
		const fill = context.createLinearGradient(left, 0, left + wheelWidth, 0);
		fill.addColorStop(0, dark);
		fill.addColorStop(0.3, base);
		fill.addColorStop(0.45, light);
		fill.addColorStop(0.6, base);
		fill.addColorStop(1, dark);
		context.beginPath();
		context.roundRect(left, top, wheelWidth, wheelHeight, 12);
		context.fillStyle = fill;
		context.fill();

		context.save();
		context.clip();
		for (let index = 0; index < 16; index++) {
			const angle = this.#motion.wheel + (index * Math.PI * 2 / 16);
			const depth = Math.cos(angle);
			if (depth <= 0) {
				continue;
			}

			const ridgeX = x + (Math.sin(angle) * wheelWidth * 0.48);
			context.strokeStyle = `rgba(90, 0, 0, ${0.3 + (depth * 0.5)})`;
			context.lineWidth = 2 + (depth * 4);
			context.beginPath();
			context.moveTo(ridgeX, top + 6);
			context.lineTo(ridgeX, top + wheelHeight - 6);
			context.stroke();
		}

		context.fillStyle = '#c0c0c0';
		context.fillRect(left, top, wheelWidth, 6);
		context.fillRect(left, top + wheelHeight - 6, wheelWidth, 6);
		context.restore();

		context.beginPath();
		context.roundRect(left, top, wheelWidth, wheelHeight, 12);
		context.lineWidth = 3;
		context.strokeStyle = outline;
		context.stroke();
	}

	#drawSpeaker({x, y, radius}) {
		const context = this.#context;
		const pulse = this.#motion.shout;
		this.#ball(x, y, radius + 6 + (pulse * 5), palette.gray);
		context.beginPath();
		context.arc(x, y, radius, 0, Math.PI * 2);
		context.fillStyle = '#202020';
		context.fill();
		context.fillStyle = '#909090';
		for (let row = -3; row <= 3; row++) {
			for (let column = -3; column <= 3; column++) {
				const holeX = x + (column * 7);
				const holeY = y + (row * 7);
				if (Math.hypot(holeX - x, holeY - y) < radius * 0.8) {
					context.beginPath();
					context.arc(holeX, holeY, 2, 0, Math.PI * 2);
					context.fill();
				}
			}
		}

		if (pulse > 0.05) {
			context.lineWidth = 3;
			context.strokeStyle = `rgba(255, 255, 255, ${pulse})`;
			for (const ring of [1, 2]) {
				context.beginPath();
				context.arc(x, y, radius + 8 + (ring * 10 * (1.5 - pulse)), -0.7, 0.7);
				context.stroke();
				context.beginPath();
				context.arc(x, y, radius + 8 + (ring * 10 * (1.5 - pulse)), Math.PI - 0.7, Math.PI + 0.7);
				context.stroke();
			}
		}
	}

	// The power light is dim when the batteries are weak, and flashes with the beat.
	#drawLed({x, y}) {
		const glow = this.#battery <= 0 ? 0 : (0.3 + (0.7 * this.#power()));
		const brightness = clamp(glow + (this.#motion.flash * 0.5), 0, 1);
		this.#ball(x, y, 7, [`rgba(220, 255, 220, ${brightness})`, `rgba(40, ${Math.round(80 + (175 * brightness))}, 40, 1)`, '#0a300a']);
	}

	#drawClassic() {
		const context = this.#context;
		const layout = layouts.classic;
		this.#drawPull(layout.pull);
		this.#tube(() => {
			context.beginPath();
			context.moveTo(92, 165);
			context.quadraticCurveTo(240, 300, 388, 165);
		}, 88, palette.yellow);
		this.#ball(240, 212, 80, palette.yellow);
		this.#drawLed(layout.led);
		this.#drawCrank(layout.twist);
		this.#drawBop(layout.bop);
		this.#label('TWIST IT', 70, 250);
		this.#label('PULL IT ↓', 388, 342);
	}

	#drawExtreme() {
		const context = this.#context;
		const layout = layouts.extreme;
		const {hub} = layout;
		this.#drawPull(layout.pull);
		const ends = [layout.twist, layout.flick, {x: layout.pull.x, y: layout.pull.top}, layout.spin];
		if (this.#availableParts().includes('shout')) {
			ends.push(layout.shout);
		}

		for (const end of ends) {
			this.#tube(() => {
				context.beginPath();
				context.moveTo(hub.x, hub.y);
				context.lineTo(end.x, end.y);
			}, 56, palette.teal);
		}

		this.#ball(hub.x, hub.y, 74, palette.teal);
		this.#drawLed(layout.led);
		this.#drawCrank(layout.twist);
		this.#drawFlick(layout.flick);
		this.#drawWheel(layout.spin);
		if (ends.includes(layout.shout)) {
			this.#drawSpeaker(layout.shout);
			this.#label('SHOUT', 240, 346);
		}

		this.#drawBop(layout.bop);
		this.#label('TWIST', 50, 176);
		this.#label('FLICK ↔', 436, 158);
		this.#label('SPIN ↔', 98, 332);
		this.#label('PULL ↓', 318, 334);
	}

	// The back of the toy, with the battery door open.
	#drawBack() {
		const context = this.#context;
		const body = this.#settings.toy === 'extreme' ? palette.teal : palette.yellow;
		context.beginPath();
		context.roundRect(50, 70, 380, 240, 50);
		context.fillStyle = body[1];
		context.fill();
		context.lineWidth = 4;
		context.strokeStyle = outline;
		context.stroke();

		context.fillStyle = '#1a1a1a';
		context.fillRect(110, 104, 260, 150);
		context.strokeStyle = body[2];
		context.lineWidth = 4;
		context.strokeRect(110, 104, 260, 150);

		for (let index = 0; index < 3; index++) {
			const top = 116 + (index * 46);
			const isFlipped = index % 2 === 1;
			if (index < this.#insertedBatteries) {
				// An AA battery, which goes in the other way in every second slot, like it says on the toy.
				const fill = context.createLinearGradient(0, top, 0, top + 34);
				fill.addColorStop(0, '#5ad16a');
				fill.addColorStop(0.5, '#1f7a2e');
				fill.addColorStop(1, '#0d3d16');
				context.fillStyle = fill;
				context.fillRect(130, top, 212, 34);
				context.fillStyle = '#d9d9d9';
				context.fillRect(isFlipped ? 130 : 330, top + 9, 14, 16);
				this.#label(isFlipped ? '+ AA 1.5V −' : '− AA 1.5V +', 236, top + 17, {size: 13});
			} else {
				context.strokeStyle = '#555555';
				context.setLineDash([6, 4]);
				context.lineWidth = 2;
				context.strokeRect(130, top, 212, 34);
				context.setLineDash([]);
				this.#label(isFlipped ? '+' : '−', 142, top + 17, {size: 16, color: '#999999'});
				this.#label(isFlipped ? '−' : '+', 330, top + 17, {size: 16, color: '#999999'});
			}
		}

		this.#label(`${this.#insertedBatteries} of 3 AA batteries`, 240, 269, {size: 15, color: '#ffff66'});
		this.#label('Click here, or press Enter, to put one in', 240, 291, {size: 15});
	}

	#draw() {
		const context = this.#context;
		const motion = this.#motion;
		const game = this.#game;
		const {width, height} = this.parts.canvas;
		context.drawImage(this.#background, 0, 0);

		if (this.#view === 'back') {
			this.#drawBack();
			return;
		}

		const toy = this.#currentToy();
		this.#drawLogo(toy === 'extreme' ? 'BOP IT EXTREME' : 'BOP IT!', toy === 'extreme' ? 190 : 240, toy === 'extreme' ? 30 : 46);

		// The whole toy wiggles from its middle, a little less each moment.
		context.save();
		const angle = motion.wiggleTime < 0.9 ? motion.wiggle * Math.sin(motion.wiggleTime * 32) * Math.exp(-motion.wiggleTime * 6) : 0;
		context.translate(240, 200);
		context.rotate(angle);
		context.translate(-240, -200);
		if (toy === 'extreme') {
			this.#drawExtreme();
		} else {
			this.#drawClassic();
		}

		context.restore();

		// How much time is left for the command, as a bar along the top.
		if (game.phase === 'command' && !this.reducedMotion) {
			const left = clamp(1 - ((performance.now() - game.commandStart) / (game.commandPeriod * 1000)), 0, 1);
			context.fillStyle = commandColors[game.command];
			context.fillRect(0, 0, width * left, 6);
		}

		if (this.#battery <= 0) {
			context.fillStyle = 'rgba(0, 0, 0, 0.62)';
			context.fillRect(0, 0, width, height);
			this.#label('🔋 THE BATTERIES ARE DEAD', 240, 170, {size: 21, color: '#ff6666'});
			this.#label('Press “New Batteries”', 240, 205, {size: 15});
		}
	}

	#isAnimating() {
		const motion = this.#motion;
		return !this.reducedMotion && (
			this.#isRunning()
			|| this.#gesture !== undefined
			|| motion.bop > 0
			|| Math.abs(motion.crankTarget - motion.crank) > 0.001
			|| motion.pull > 0.2
			|| Math.abs(motion.flick) > 0.2
			|| Math.abs(motion.flickVelocity) > 1
			|| Math.abs(motion.wheelVelocity) > 0.02
			|| motion.shout > 0
			|| motion.flash > 0
			|| motion.wiggleTime < 0.9
		);
	}

	#step(seconds) {
		const motion = this.#motion;
		const gesture = this.#gesture;
		if (gesture?.part !== 'bop') {
			motion.bop = Math.max(0, motion.bop - (seconds * 6));
		}

		motion.crank += (motion.crankTarget - motion.crank) * Math.min(1, seconds * 14);
		if (gesture?.part !== 'pull') {
			motion.pull *= Math.exp(-seconds * 10);
		}

		// The flick stick swings back and forth on its spring before it stands still.
		if (gesture?.part !== 'flick') {
			motion.flickVelocity += ((-420 * motion.flick) - (9 * motion.flickVelocity)) * seconds;
			motion.flick += motion.flickVelocity * seconds;
		}

		if (gesture?.part !== 'spin') {
			motion.wheel += motion.wheelVelocity * seconds;
			motion.wheelVelocity *= Math.exp(-seconds * 2.5);
		}

		motion.shout = Math.max(0, motion.shout - (seconds * 2.5));
		motion.flash = Math.max(0, motion.flash - (seconds * 5));
		motion.wiggleTime += seconds;
		this.#draw();
	}

	// With reduced motion, a part that the visitor let go is back at once, and the canvas is drawn on each change instead of in a loop.
	#requestDraw() {
		this.#draw();
		if (!this.reducedMotion) {
			this.#loop.start();
		}
	}

	#releaseLater() {
		if (!this.reducedMotion) {
			return;
		}

		setTimeout(() => {
			if (this.#gesture === undefined) {
				const motion = this.#motion;
				motion.bop = 0;
				motion.pull = 0;
				motion.flick = 0;
				motion.shout = 0;
				this.#draw();
			}
		}, 180);
	}

	#wiggle(amount) {
		if (this.reducedMotion) {
			return;
		}

		this.#motion.wiggle = amount;
		this.#motion.wiggleTime = 0;
	}

	// Moves a part by itself, for the keys and for the hands of Lillesøster.
	#moveByItself(part, direction = 1) {
		const motion = this.#motion;
		const reduced = this.reducedMotion;
		switch (part) {
			case 'bop': {
				motion.bop = 1;
				break;
			}

			case 'twist': {
				motion.crankTarget += direction * Math.PI / 2;
				if (reduced) {
					motion.crank = motion.crankTarget;
				}

				break;
			}

			case 'pull': {
				motion.pull = layouts[this.#currentToy()].pull.travel;
				break;
			}

			case 'flick': {
				if (reduced) {
					motion.flick = direction * 30;
				} else {
					motion.flickVelocity += direction * 700;
				}

				break;
			}

			case 'spin': {
				if (reduced) {
					motion.wheel += direction * Math.PI / 3;
				} else {
					motion.wheelVelocity = direction * 14;
				}

				break;
			}

			case 'shout': {
				motion.shout = 1;
				break;
			}

			default:
		}

		this.#releaseLater();
	}

	#updateStats() {
		const {stats, batteries} = this.parts;
		const game = this.#game;
		const battery = this.#battery;
		const toy = this.#currentToy();
		const level = Math.max(0, Math.ceil(battery));
		const filled = Math.ceil(level / 25);
		const meter = '▮'.repeat(filled) + '▯'.repeat(4 - filled);
		const first = game.who === 'sister' && this.#isRunning() ? `Lillesøster ${game.score}` : `Score ${game.score}`;
		const text = `${first} ★ Best ${this.#best[toy]} ★ Trond ${rivals[toy]} ★ 🔋 ${meter} ${level}%`;
		if (stats.textContent !== text) {
			stats.textContent = text;
		}

		if (battery <= 0) {
			batteries.dataset.state = 'dead';
		} else if (battery < lowBattery) {
			batteries.dataset.state = 'low';
		} else {
			batteries.dataset.state = '';
		}
	}

	#renderScoreboard() {
		const {scoreboard} = this.parts;
		const game = this.#game;
		const items = game.players.map((player, index) => {
			const item = document.createElement('li');
			item.textContent = `${player.isWinner ? '🏆 ' : ''}${player.name}: ${player.score}`;
			if (player.isWinner) {
				item.dataset.state = 'winner';
			} else if (player.isOut) {
				item.dataset.state = 'out';
			} else if (index === game.current && this.#isRunning()) {
				item.dataset.state = 'current';
			}

			return item;
		});
		scoreboard.replaceChildren(...items);
		scoreboard.hidden = this.#settings.kind !== 'pass' || game.players.length === 0;
	}

	#updateControls() {
		const {start, sister, batteries, shout, microphone, players, scoreboard, classic, extreme, solo, pass} = this.parts;
		const settings = this.#settings;
		const running = this.#isRunning();
		if (!running) {
			start.textContent = '▶ Start (Sound!)';
		} else if (this.#game.who === 'sister') {
			start.textContent = '✋ Take It Back';
		} else {
			start.textContent = '■ Stop';
		}

		for (const button of [classic, extreme, solo, pass]) {
			button.disabled = running;
		}

		for (const input of players.querySelectorAll('input')) {
			input.disabled = running;
		}

		sister.disabled = running || this.#battery <= 0 || this.#view === 'back';
		batteries.disabled = running;
		shout.disabled = running || settings.toy !== 'extreme';
		microphone.disabled = settings.toy !== 'extreme' || !settings.hasShout;
		players.hidden = settings.kind !== 'pass';
		scoreboard.hidden = settings.kind !== 'pass' || this.#game.players.length === 0;
	}

	#setBattery(level) {
		this.#battery = clamp(level, 0, 100);
		this.store('batteries', this.#battery);
		if (this.#battery < lowBattery && this.#battery > 0 && !this.#isLowWarned) {
			this.#isLowWarned = true;
			this.toast('The Bop It sounds tired. The batteries are getting low!');
		}

		this.#updateStats();
	}

	#turnOnSound() {
		if (!this.#turnOnAudio()) {
			return false;
		}

		const {sound} = this.parts;
		setPressed(sound, true);
		sound.textContent = '🔊 Sound On';
		return true;
	}

	#clearTimers() {
		const game = this.#game;
		clearTimeout(game.timer);
		clearTimeout(game.sisterTimer);
		game.timer = undefined;
		game.sisterTimer = undefined;
	}

	#later(seconds, callback) {
		clearTimeout(this.#game.timer);
		this.#game.timer = setTimeout(callback, seconds * 1000);
	}

	#nextPlayerIndex() {
		const game = this.#game;
		for (let offset = 1; offset <= game.players.length; offset++) {
			const index = (game.current + offset) % game.players.length;
			if (!game.players[index].isOut) {
				return index;
			}
		}

		return game.current;
	}

	#nagLine() {
		const sister = this.#sister;
		const sisterButton = this.parts.sister;
		if (sister.gamesSince < 2) {
			sisterButton.dataset.state = '';
			return '';
		}

		sisterButton.dataset.state = 'nag';
		const line = nags[Math.min(sister.nags, nags.length - 1)];
		sister.nags++;
		return ` ${line}`;
	}

	#endGame(message) {
		this.#clearTimers();
		const {who} = this.#game;
		this.#game.phase = 'idle';
		this.music(false);
		if (who === 'visitor') {
			this.#sister.gamesSince++;
		}

		this.#updateControls();
		this.#updateStats();
		this.#renderScoreboard();
		this.#updateMicrophone();
		this.say(message + (who === 'visitor' ? this.#nagLine() : ''));
		this.#requestDraw();
	}

	#issueCommand() {
		const game = this.#game;
		this.#setBattery(this.#battery - 1);
		if (this.#battery <= 0) {
			this.#die();
			return;
		}

		// The toy picks at random, but never the same thing three times in a row.
		let part;
		do {
			part = randomItem(game.parts);
		} while (game.history.length >= 2 && game.history.every(previous => previous === part));

		game.history = [...game.history.slice(-1), part];
		game.command = part;
		game.answered = false;
		game.phase = 'command';
		const period = game.period * (1 + ((1 - this.#power()) * 0.6));
		game.commandStart = performance.now();
		game.commandPeriod = period;
		const text = this.#words()[part];
		this.#showCommand(text.toUpperCase(), part);
		this.#speak(text);
		this.#playBar(period);
		if (!this.reducedMotion) {
			this.#motion.flash = 1;
		}
		if (game.kind === 'pass') {
			this.say(`${game.players[game.current].name}: ${text}`);
		} else {
			this.say(text);
		}

		if (game.who === 'sister') {
			this.#planSister(part, period);
		}

		this.#later(period, () => {
			this.#tick();
		});
		this.#updateStats();
		this.#requestDraw();
	}

	#passIt() {
		const game = this.#game;
		game.phase = 'passing';
		const text = this.#words().pass;
		this.#showCommand(text.toUpperCase(), 'pass');
		this.#speak(text);
		this.#effects.pass();
		this.#wiggle(0.12);
		const next = game.players[this.#nextPlayerIndex()];
		this.say(`${text} Give the toy to ${next.name}!`);
		const bars = Math.max(1, Math.round(2.4 / game.period));
		for (let bar = 0; bar < bars; bar++) {
			this.#playBar(game.period, bar * game.period);
		}

		this.#later(bars * game.period, () => {
			this.#tick();
		});
		this.#requestDraw();
	}

	#tick() {
		const game = this.#game;
		game.timer = undefined;
		if (game.phase === 'command' && !game.answered) {
			this.#fail('late');
			return;
		}

		if (game.phase === 'passing') {
			game.current = this.#nextPlayerIndex();
			game.turnLeft = turnLength();
			this.#renderScoreboard();
		} else if (game.kind === 'pass' && game.phase === 'command' && game.turnLeft <= 0) {
			this.#passIt();
			return;
		}

		this.#issueCommand();
	}

	#start(who) {
		const {canvas, players} = this.parts;
		const game = this.#game;
		const settings = this.#settings;
		if (this.#battery <= 0) {
			this.say('Nothing happens. The batteries are dead. Press “New Batteries”.');
			return;
		}

		if (this.#view === 'back') {
			this.say('Put in the batteries first, and close the door.');
			return;
		}

		const kind = who === 'sister' ? 'solo' : settings.kind;
		const names = [...players.querySelectorAll('input')].map(input => input.value.trim().slice(0, 12)).filter(Boolean);
		if (kind === 'pass' && names.length < 2) {
			this.say('Pass It needs at least two players. Write two names.');
			return;
		}

		game.who = who;
		game.kind = kind;
		game.toy = settings.toy;
		game.parts = this.#partsOf(settings.toy);
		game.score = 0;
		game.period = tempos[settings.toy].start;
		game.history = [];
		game.players = kind === 'pass' ? names.map(name => ({name, score: 0, isOut: false, isWinner: false})) : [];
		game.current = 0;
		game.turnLeft = turnLength();

		this.#turnOnSound();
		this.music(true);
		game.phase = 'starting';
		this.#updateMicrophone();

		// The toy comes into view and gets the keys, so Space bops it right away.
		canvas.scrollIntoView({block: 'nearest'});
		canvas.focus({preventScroll: true});
		this.#showCommand('♪ ♪ ♪', '');
		this.#playBar(game.period);
		this.#updateControls();
		this.#updateStats();
		this.#renderScoreboard();
		if (who === 'sister') {
			this.say('Lillesøster grabs the toy with both hands. “Jeg kan selv!” (I can do it myself!) Hands off while she plays.');
			this.#sister.gamesSince = 0;
			this.#sister.nags = 0;
			this.parts.sister.dataset.state = '';
		} else if (game.kind === 'pass') {
			this.say(`Pass It! ${game.players[0].name} starts. When the toy says “Pass it!”, give it to the next one.`);
		} else {
			this.say('Here it comes! Do what the toy says, before the next beat.');
		}

		this.#later(game.period, () => {
			this.#tick();
		});
		this.#requestDraw();
	}

	#stop(reason) {
		this.#clearTimers();
		hushVoice();
		const messages = {
			visitor: 'You turned it off. Trond says that is cheating, and the score does not count.',
			sister: 'You took it back. Lillesøster: “MAMMAAA!” Mamma is coming up the stairs.',
			music: 'Somebody turned on other music, so the Bop It stops to listen.',
		};
		this.#showCommand('', '');
		this.#endGame(messages[reason]);
	}

	#die() {
		this.#clearTimers();
		const {score, who} = this.#game;
		this.#effects.die();
		this.#speak(this.#words().dead, {rate: 0.8, pitch: 0.4});
		this.#showCommand('', 'dead');
		this.#endGame(`The batteries died! The voice got slow and deep, and then nothing. ${score > 0 ? `${who === 'sister' ? 'Lillesøster' : 'You'} had ${score}, but Trond says it does not count when the batteries die.` : ''} Put in new batteries.`);
	}

	#recordBest(score) {
		const best = this.#best;
		const {toy} = this.#game;
		if (score <= best[toy]) {
			return `Your best on the ${toyNames[toy]} is ${best[toy]}.`;
		}

		const old = best[toy];
		best[toy] = score;
		this.store('best', best);
		this.#speak(this.#words().best, {isQueued: true});
		if (score > rivals[toy] && old <= rivals[toy]) {
			this.celebrate();
			this.toast(`You beat Trond’s ${rivals[toy]} on the ${toyNames[toy]}!`);
			return `A new high score, and you beat Trond’s ${rivals[toy]}! Call him (after 18:00, when it is cheaper).`;
		}

		this.toast(`New high score on the ${toyNames[toy]}: ${score}!`);
		return score > rivals[toy] ? 'A new high score! Trond does not want to talk about it.' : `A new high score! Trond’s best is ${rivals[toy]}, so keep going.`;
	}

	#fail(reason, wrongPart) {
		const game = this.#game;
		this.#clearTimers();
		game.phase = 'over';
		const said = this.#words()[game.command];
		const mistake = reason === 'late' ? `Too slow! It said “${said}”.` : `It said “${said}”, and you ${pastTense[wrongPart]}.`;
		// Early in a round, the mistake is often that the visitor did not know how, so the toy tells it. Later, the message stays short.
		const what = game.score < 10 ? `${mistake} ${howTo[game.command]}` : mistake;
		this.#effects.fail();
		this.#wiggle(0.3);
		this.#showCommand(this.#words().fail.toUpperCase(), 'fail');
		this.#speak(this.#words().fail, {rate: 0.9, pitch: 1.2});
		this.#requestDraw();

		if (game.who === 'sister') {
			this.#sisterDone();
			return;
		}

		if (game.kind === 'pass') {
			const player = game.players[game.current];
			player.isOut = true;
			this.#speak(this.#words().out(player.name), {isQueued: true});
			const left = game.players.filter(other => !other.isOut);
			this.#renderScoreboard();
			if (left.length >= 2) {
				this.say(`${what} ${player.name} is out, with ${player.score}. ${left.map(other => other.name).join(' and ')} are still in.`);
				this.#later(2.4, () => {
					this.#passIt();
				});
				return;
			}

			const [winner] = left;
			winner.isWinner = true;
			this.#speak(this.#words().win(winner.name), {isQueued: true});
			this.#effects.win();
			this.celebrate();
			this.toast(`${winner.name} wins Pass It!`);
			this.#endGame(`${what} ${player.name} is out, and ${winner.name} wins Pass It with ${winner.score}! Rematch?`);
			return;
		}

		this.#speak(this.#words().score(game.score), {isQueued: true, rate: 1.1, pitch: 1.4});
		this.#endGame(`${what} Your score is ${game.score}. ${this.#recordBest(game.score)}`);
	}

	#success() {
		const game = this.#game;
		game.answered = true;
		game.score++;
		if (game.kind === 'pass') {
			game.players[game.current].score++;
			game.turnLeft--;
			this.#renderScoreboard();
		}

		const {step: speedUp, fastest} = tempos[game.toy];
		game.period = Math.max(fastest, game.period - speedUp);
		if (game.score % 10 === 0) {
			this.#effects.faster();
		}

		if (game.score >= 100 && game.kind === 'solo' && game.who === 'visitor') {
			this.#clearTimers();
			this.#effects.win();
			hushVoice();
			this.#speak(this.#words().master);
			this.celebrate();
			this.#showCommand('100!', 'pass');
			this.#endGame(`100! The toy plays its winning tune, and nobody will believe it. ${this.#recordBest(100)}`);
			return;
		}

		this.#updateStats();
	}

	// Lillesøster plays by herself. She is quick at first, but makes more mistakes as it gets faster.
	#planSister(part, period) {
		const game = this.#game;
		const mistake = 0.05 + (game.score * 0.03);
		const roll = Math.random();
		if (roll < mistake / 2) {
			return;
		}

		const move = roll < mistake ? randomItem(game.parts.filter(other => other !== part)) : part;
		game.sisterTimer = setTimeout(() => {
			this.#moveByItself(move, Math.random() < 0.5 ? -1 : 1);
			this.#useToy(move, 'sister');
		}, period * 1000 * (0.3 + (Math.random() * 0.35)));
	}

	#sisterDone() {
		const {score, toy} = this.#game;
		this.#speak(this.#words().score(score), {isQueued: true, rate: 1.1, pitch: 1.4});
		const visitorBest = this.#best[toy];
		let line;
		if (score > visitorBest) {
			line = `Lillesøster got ${score}, and beat your best of ${visitorBest}! She runs to tell Mamma, Pappa, and the neighbors.`;
			this.celebrate();
		} else if (score === 0) {
			line = 'Lillesøster got 0. She says the toy is broken, and that it is your fault.';
		} else if (score > this.#sisterBest) {
			line = `Lillesøster got ${score}, her best ever! She wants it written on the fridge.`;
		} else {
			line = `Lillesøster got ${score}. She says the toy cheated, and that it is her turn again.`;
		}

		if (score > this.#sisterBest) {
			this.#sisterBest = score;
			this.store('sister-best', this.#sisterBest);
		}

		this.#endGame(`${line} (Her best: ${this.#sisterBest}.)`);
	}

	// What happens when somebody uses a part of the toy: it wiggles and makes its sound, and in a game, it is the right move or a mistake.
	#useToy(part, by = 'visitor') {
		const game = this.#game;
		if (this.#view === 'back' || !this.#availableParts().includes(part)) {
			return;
		}

		if (this.#battery <= 0) {
			this.say('Nothing happens. The batteries are dead.');
			return;
		}

		if (by === 'visitor' && game.who === 'sister' && this.#isRunning()) {
			this.say('Hands off! It is Lillesøster’s turn. (She bites.)');
			return;
		}

		const wiggles = {bop: 0.05, twist: -0.07, pull: 0.06, flick: 0.08, spin: -0.06, shout: 0.04};
		this.#wiggle(wiggles[part]);
		this.#partSounds[part]();
		this.#requestDraw();

		// A first visitor often bops it before it is on, so the toy tells how to start. After a game, the status keeps the score instead.
		if (by === 'visitor' && !this.#isRunning() && game.history.length === 0) {
			this.say(`${this.#words()[part]} That is the way. Now press “▶ Start (Sound!)”, and the toy yells what to do.`);
			return;
		}

		if (game.phase !== 'command') {
			return;
		}

		if (part === game.command) {
			if (!game.answered) {
				this.#success();
			}

			return;
		}

		this.#fail('wrong', part);
	}

	#insertBattery() {
		const {batteries} = this.parts;
		this.#insertedBatteries++;
		this.#effects.click();
		if (this.#insertedBatteries < 3) {
			batteries.textContent = `🔋 Put In Battery ${this.#insertedBatteries + 1} of 3`;
			this.say(`Click! ${this.#insertedBatteries} of 3 in.`);
			this.#requestDraw();
			return;
		}

		this.#view = 'front';
		this.#isLowWarned = false;
		this.#setBattery(100);
		batteries.textContent = '🔋 New Batteries';
		this.#effects.jingle();
		this.#speak(this.#words().bop);
		this.#showCommand('Press Start!', '');
		this.#updateControls();
		this.say('New batteries! The light is bright, and the voice is peppy again.');
		this.#wiggle(0.1);
		this.#requestDraw();
	}

	#listen() {
		const microphone = this.#microphone;
		microphone.analyser.getFloatTimeDomainData(microphone.data);
		let sum = 0;
		for (const sample of microphone.data) {
			sum += sample * sample;
		}

		const loudness = Math.sqrt(sum / microphone.data.length);
		const now = performance.now();
		if (loudness < 0.15 || now < microphone.ignoreUntil) {
			microphone.loudSince = undefined;
			return;
		}

		microphone.loudSince ??= now;
		if (now - microphone.loudSince > 120 && now - microphone.lastShout > 700) {
			microphone.lastShout = now;
			this.#moveByItself('shout');
			this.#useToy('shout');
		}
	}

	#shouldListen() {
		const game = this.#game;
		return this.#microphone.isWanted && this.isVisible && this.#isRunning() && game.phase !== 'paused' && game.parts.includes('shout');
	}

	#closeMicrophone() {
		const microphone = this.#microphone;
		clearInterval(microphone.interval);
		for (const track of microphone.stream?.getTracks() ?? []) {
			track.stop();
		}

		microphone.source?.disconnect();
		microphone.interval = undefined;
		microphone.stream = undefined;
		microphone.source = undefined;
		microphone.loudSince = undefined;
	}

	async #openMicrophone() {
		const microphone = this.#microphone;
		const audio = this.#audio;
		microphone.isOpening = true;
		try {
			microphone.stream = await navigator.mediaDevices.getUserMedia({audio: {echoCancellation: true}});
		} catch {
			this.#setMicrophoneWanted(false);
			this.say('No microphone, so no real shouting. Mamma is relieved. Click the speaker instead.');
			return;
		} finally {
			microphone.isOpening = false;
		}

		microphone.analyser ??= new AnalyserNode(audio.context, {fftSize: 1024});
		microphone.data ??= new Float32Array(microphone.analyser.fftSize);
		microphone.source = audio.context.createMediaStreamSource(microphone.stream);
		microphone.source.connect(microphone.analyser);
		microphone.interval = setInterval(() => {
			this.#listen();
		}, 50);

		// The round can be over, or the toy off the screen, by the time the visitor allows it.
		this.#updateMicrophone();
	}

	// Opens the microphone when it should listen, and closes it at once when not, so it is never on after a round or while the toy is away.
	#updateMicrophone() {
		const microphone = this.#microphone;
		if (!this.#shouldListen()) {
			this.#closeMicrophone();
		} else if (!microphone.stream && !microphone.isOpening) {
			this.#openMicrophone();
		}
	}

	#setMicrophoneWanted(isWanted) {
		this.#microphone.isWanted = isWanted;
		setPressed(this.parts.microphone, isWanted);
		this.#updateMicrophone();
	}

	// The hands of the visitor on the canvas.
	#toCanvas(event) {
		const {canvas} = this.parts;
		return {
			x: (event.clientX - canvas.getBoundingClientRect().left - canvas.clientLeft) * canvas.width / canvas.clientWidth,
			y: (event.clientY - canvas.getBoundingClientRect().top - canvas.clientTop) * canvas.height / canvas.clientHeight,
		};
	}

	#hitTest({x, y}) {
		const toy = this.#currentToy();
		const layout = layouts[toy];
		const available = this.#availableParts();
		const near = (point, radius) => Math.hypot(x - point.x, y - point.y) < radius;
		if (near(layout.bop, layout.bop.radius + 8)) {
			return 'bop';
		}

		if (available.includes('shout') && near(layout.shout, layout.shout.radius + 12)) {
			return 'shout';
		}

		if (near(layout.twist, layout.twist.radius + 22)) {
			return 'twist';
		}

		const {pull} = layout;
		if (Math.abs(x - pull.x) < 56 && y > pull.top - 6 && y < pull.grip + this.#motion.pull + 42) {
			return 'pull';
		}

		if (available.includes('flick') && near({x: layout.flick.x, y: layout.flick.y - 40}, 60)) {
			return 'flick';
		}

		if (available.includes('spin') && Math.abs(x - layout.spin.x) < (layout.spin.width / 2) + 12 && Math.abs(y - layout.spin.y) < (layout.spin.height / 2) + 14) {
			return 'spin';
		}

		return undefined;
	}

	#pointerDown(event) {
		const {canvas} = this.parts;
		if (event.button !== 0) {
			return;
		}

		if (this.#view === 'back') {
			this.#insertBattery();
			return;
		}

		const point = this.#toCanvas(event);
		const part = this.#hitTest(point);
		if (!part) {
			return;
		}

		event.preventDefault();
		canvas.focus({preventScroll: true});
		canvas.setPointerCapture(event.pointerId);
		const center = layouts[this.#currentToy()].twist;
		this.#gesture = {
			part,
			pointerId: event.pointerId,
			startX: point.x,
			startY: point.y,
			lastX: point.x,
			lastTime: performance.now(),
			lastAngle: Math.atan2(point.y - center.y, point.x - center.x),
			turned: 0,
			travel: 0,
			velocity: 0,
			isDone: false,
		};

		// The button and the speaker work at once, like a real press.
		if (part === 'bop' || part === 'shout') {
			this.#motion[part] = 1;
			this.#gesture.isDone = true;
			this.#useToy(part);
		}

		this.#requestDraw();
	}

	#pointerMove(event) {
		const gesture = this.#gesture;
		const motion = this.#motion;
		if (gesture?.pointerId !== event.pointerId) {
			return;
		}

		const point = this.#toCanvas(event);
		const layout = layouts[this.#currentToy()];
		switch (gesture.part) {
			case 'twist': {
				// The crank follows the angle of the finger around its middle, and half a turn counts as a twist.
				const {twist} = layout;
				const angle = Math.atan2(point.y - twist.y, point.x - twist.x);
				let delta = angle - gesture.lastAngle;
				if (delta > Math.PI) {
					delta -= Math.PI * 2;
				} else if (delta < -Math.PI) {
					delta += Math.PI * 2;
				}

				gesture.lastAngle = angle;
				motion.crank += delta;
				motion.crankTarget = motion.crank;
				gesture.turned += delta;
				if (Math.abs(gesture.turned) >= Math.PI) {
					gesture.turned = 0;
					this.#useToy('twist');
				}

				break;
			}

			case 'pull': {
				const {travel} = layout.pull;
				motion.pull = clamp(point.y - gesture.startY, 0, travel);
				if (!gesture.isDone && point.y - gesture.startY > travel * 0.75) {
					gesture.isDone = true;
					this.#useToy('pull');
				}

				break;
			}

			case 'flick': {
				const distance = point.x - gesture.startX;
				motion.flick = clamp(distance, -46, 46);
				if (!gesture.isDone && Math.abs(distance) > 22) {
					gesture.isDone = true;
					this.#useToy('flick');
				}

				break;
			}

			case 'spin': {
				const distance = point.x - gesture.lastX;
				const now = performance.now();
				motion.wheel += distance / (layout.spin.width / 2);
				gesture.velocity = distance / (layout.spin.width / 2) / Math.max((now - gesture.lastTime) / 1000, 0.008);
				gesture.lastTime = now;
				gesture.lastX = point.x;
				gesture.travel += Math.abs(distance);
				if (!gesture.isDone && gesture.travel > 60) {
					gesture.isDone = true;
					this.#useToy('spin');
				}

				break;
			}

			default:
		}

		this.#requestDraw();
	}

	#endGesture(event) {
		const motion = this.#motion;
		if (this.#gesture?.pointerId !== event.pointerId) {
			return;
		}

		// A swipe that lets go keeps the wheel spinning for a moment.
		if (this.#gesture.part === 'spin' && !this.reducedMotion) {
			motion.wheelVelocity = clamp(this.#gesture.velocity, -30, 30);
		}

		this.#gesture = undefined;
		if (this.reducedMotion) {
			motion.bop = 0;
			motion.pull = 0;
			motion.flick = 0;
			motion.shout = 0;
		}

		this.#requestDraw();
	}

	#keyDown(event) {
		if (event.altKey || event.ctrlKey || event.metaKey) {
			return;
		}

		const key = event.key.toLowerCase();
		if (this.#view === 'back' && (key === 'enter' || key === ' ')) {
			event.preventDefault();
			this.#insertBattery();
			return;
		}

		const entry = keys[key];
		if (!entry) {
			return;
		}

		event.preventDefault();
		if (event.repeat) {
			return;
		}

		const [part, direction] = entry;
		if (!this.#availableParts().includes(part) || this.#battery <= 0 || (this.#game.who === 'sister' && this.#isRunning())) {
			this.#useToy(part);
			return;
		}

		this.#moveByItself(part, direction);
		this.#useToy(part);
	}
}
