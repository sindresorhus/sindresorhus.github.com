// Rodent’s Revenge on the desktop of the 1999 page, like the one of the Microsoft Entertainment Pack (Christopher Lee Fraley, 1991): the mouse pushes rows of movable blocks to box in the cats, which chase it along the shortest way. A cat that cannot move sits, and when all the cats of a wave sit, they turn into cheese, which the mouse eats for points. Sink holes hold the mouse for a while, mouse traps snap, and balls of yarn roll around and squash it. With reduced motion, the cats move only when the mouse moves. Nothing makes a sound until the visitor turns on the sound.

// The field is 23 × 23 squares of 32 pixels, with the wall around it, under a panel with the spare mice, the clock, and the score.
const size = 23;
const cell = 32;
const top = 64;
const center = 11;
const levelTime = 120;
const emojiFont = '"Apple Color Emoji", "Segoe UI Emoji", "Noto Color Emoji", sans-serif';
const comicFont = '"Comic Sans MS", "Comic Sans", cursive';

// What a square of the field holds. The cats, the balls of yarn, and the mouse walk on top.
const empty = 0;
const wall = 1;
const block = 2;
const trap = 3;
const hole = 4;
const cheese = 5;
const brunost = 6;
const rocky = 7;

// The seconds between two steps of a cat, like the Speed of the Options of the original.
const speeds = {
	snail: 1,
	slow: 0.7,
	medium: 0.48,
	fast: 0.32,
	cheetah: 0.2,
};

const neighbors = [[-1, -1], [0, -1], [1, -1], [-1, 0], [1, 0], [-1, 1], [0, 1], [1, 1]];

const randomItem = items => items[Math.floor(Math.random() * items.length)];

const distanceBetween = (first, second) => Math.max(Math.abs(first.x - second.x), Math.abs(first.y - second.y));

// The same level gets the same layout every time, from a small random generator with the level as the seed.
const seededRandom = seed => () => {
	seed = (seed + 0x6D_2B_79_F5) | 0;
	let value = Math.imul(seed ^ (seed >>> 15), 1 | seed);
	value = (value + Math.imul(value ^ (value >>> 7), 61 | value)) ^ value;
	return ((value ^ (value >>> 14)) >>> 0) / 4_294_967_296;
};

const chebyshevFromCenter = (x, y) => Math.max(Math.abs(x - center), Math.abs(y - center));

// The ten layouts. After the tenth, they come again with more cats and yarn.
const layouts = [
	{
		name: 'Mormor’s Pantry',
		build({fill}) {
			fill(4, 18, block);
		},
	},
	{
		name: 'Stones in the Garden',
		build({fill, scatter}) {
			fill(4, 18, block);
			scatter(14, wall);
		},
	},
	{
		name: 'Rocky’s Room',
		build({fill, set}) {
			fill(3, 19, block);
			fill(3, 19, wall, (x, y) => x % 4 === 3 && y % 4 === 3);
			set(15, 7, rocky);
		},
	},
	{
		name: 'The Leaky Basement',
		build({fill, scatter}) {
			fill(4, 18, block);
			scatter(6, hole, 4, 18);
			scatter(5, hole, 1, 21);
		},
	},
	{
		name: 'Pappa’s Workshop',
		build({fill, scatter}) {
			fill(3, 19, block);
			scatter(6, wall, 3, 19);
			scatter(7, trap, 1, 21);
		},
	},
	{
		name: 'The Norwegian Flag',
		build({fill}) {
			// A Nordic cross of open paths, a bit to the left, like on the flag.
			fill(2, 20, block, (x, y) => x !== 8 && y !== center);
		},
	},
	{
		name: 'Mormor’s Knitting',
		hasYarn: true,
		build({fill, set}) {
			fill(2, 20, block, (x, y) => chebyshevFromCenter(x, y) >= 2 && chebyshevFromCenter(x, y) % 3 !== 1);

			for (const [x, y] of [[7, 7], [15, 7], [7, 15], [15, 15]]) {
				set(x, y, wall);
			}
		},
	},
	{
		name: 'Lillesøster’s Room',
		hasYarn: true,
		build({fill, scatter}) {
			fill(2, 20, block, (x, y) => (x + y) % 4 !== 0);
			scatter(8, wall);
		},
	},
	{
		name: 'Bryggen',
		hasYarn: true,
		build({fill, scatter}) {
			fill(3, 19, block);
			fill(3, 19, wall, (x, y) => chebyshevFromCenter(x, y) === 6 && (x + y) % 3 !== 0);
			scatter(4, hole, 1, 21);
			scatter(4, trap, 1, 21);
		},
	},
	{
		name: 'Everything at Once',
		hasYarn: true,
		build({fill, scatter, random}) {
			fill(2, 20, block, () => random() < 0.62);
			scatter(10, wall);
			scatter(5, hole, 1, 21);
			scatter(5, trap, 1, 21);
		},
	},
];

const layoutOf = level => layouts[(level - 1) % layouts.length];

// Each wave has one cat more than the one before, and later levels have more waves and bigger ones.
const wavesOf = level => Array.from({length: Math.min(2 + Math.floor((level - 1) / 3), 5)}, (_, wave) => Math.min(1 + wave + Math.floor((level - 1) / 4), 7));

const indexOf = (x, y) => (y * size) + x;

// The arrows, the number pad (also without Num Lock), and Q, E, Z, and C for the diagonals on a laptop.
const keySteps = {
	ArrowLeft: [-1, 0],
	ArrowRight: [1, 0],
	ArrowUp: [0, -1],
	ArrowDown: [0, 1],
	Home: [-1, -1],
	PageUp: [1, -1],
	End: [-1, 1],
	PageDown: [1, 1],
	Clear: [0, 0],
	q: [-1, -1],
	e: [1, -1],
	z: [-1, 1],
	c: [1, 1],
};

const codeSteps = {
	Numpad1: [-1, 1],
	Numpad2: [0, 1],
	Numpad3: [1, 1],
	Numpad4: [-1, 0],
	Numpad5: [0, 0],
	Numpad6: [1, 0],
	Numpad7: [-1, -1],
	Numpad8: [0, -1],
	Numpad9: [1, -1],
};

const parseStep = button => button.dataset.rodentMove.split(' ').map(Number);

export default class extends GeoCitiesElement {
	#context;
	#loop;
	#best;
	#speed;
	#repeatTimer;
	#pointerCell;

	#game = {
		id: 0,
		level: 1,
		score: 0,
		mice: 3,
		nextExtraMouse: 10_000,
		grid: new Uint8Array(size * size),
		mouse: {x: center, y: center, facing: -1},
		cats: [],
		yarns: [],
		waves: [],
		wave: 0,
		time: levelTime,
		mode: 'ready',
		stuck: 0,
		death: undefined,
		squeak: 0,
		catTimer: 0,
		yarnTimer: 0,
		yarnSpawnTimer: 0,
	};

	connected() {
		const {screen, newGame, pause, sound: soundButton, level: levelPicker, speed: speedPicker} = this.parts;
		this.#context = screen.getContext('2d');
		const storedBest = this.stored('best', 0);
		const storedSpeed = this.stored('speed', 'medium');
		this.#best = Number.isSafeInteger(storedBest) && storedBest > 0 ? storedBest : 0;
		this.#speed = Object.hasOwn(speeds, storedSpeed) ? storedSpeed : 'medium';
		speedPicker.value = this.#speed;

		// The game runs only while its field is on the screen, in its open window, and the tab is visible. With reduced motion, the cats move only when the mouse moves, and only the wait after a lost mouse runs by itself.
		this.#loop = this.loop(seconds => {
			this.#update(seconds);
			this.#draw();
		}, {while: () => this.#game.mode === 'dying' || (this.#game.mode === 'playing' && !this.reducedMotion)});

		this.on(soundButton, 'click', () => {
			const isOn = !this.#isSoundOn;
			soundButton.setAttribute('aria-pressed', String(isOn));
			soundButton.textContent = isOn ? '🔊 Sound' : '🔈 Sound';

			if (isOn) {
				this.#sounds.squeak();
			}
		});

		// Holding a button of the arrow pad, or a finger on the field, keeps the mouse running.
		for (const button of this.querySelectorAll('[data-rodent-move]')) {
			this.on(button, 'pointerdown', event => {
				if (event.button !== 0) {
					return;
				}

				const [dx, dy] = parseStep(button);
				this.#moveMouse(dx, dy);

				if (dx !== 0 || dy !== 0) {
					this.#startRepeat(() => this.#moveMouse(dx, dy));
				}
			});

			for (const type of ['pointerup', 'pointerleave', 'pointercancel']) {
				this.on(button, type, () => {
					this.#stopRepeat();
				});
			}

			// The keyboard clicks without a pointer.
			this.on(button, 'click', event => {
				if (event.detail === 0) {
					this.#moveMouse(...parseStep(button));
				}
			});

			this.on(button, 'contextmenu', event => {
				event.preventDefault();
			});

			// A click on the arrow pad leaves the focus on the field, so the arrow keys still work after it.
			this.on(button, 'mousedown', event => {
				event.preventDefault();
				screen.focus({preventScroll: true});
			});
		}

		this.on(screen, 'pointerdown', event => {
			if (event.button !== 0) {
				return;
			}

			event.preventDefault();
			screen.focus({preventScroll: true});
			screen.setPointerCapture(event.pointerId);
			this.#pointerCell = this.#cellAt(event);
			const {mode} = this.#game;
			this.#stepTowardPointer();

			if (mode === 'playing' || mode === 'ready') {
				this.#startRepeat(() => this.#stepTowardPointer());
			}
		});

		this.on(screen, 'pointermove', event => {
			if (this.#repeatTimer) {
				this.#pointerCell = this.#cellAt(event);
			}
		});

		for (const type of ['pointerup', 'pointercancel', 'lostpointercapture']) {
			this.on(screen, type, () => {
				this.#stopRepeat();
			});
		}

		this.on(screen, 'keydown', event => {
			this.#keyDown(event);
		});

		this.on(pause, 'click', () => {
			this.#setPaused(this.#game.mode === 'playing');
		});

		this.on(newGame, 'click', () => {
			this.#newGame();
			screen.focus();
		});

		this.on(levelPicker, 'change', () => {
			this.#newGame();
		});

		this.on(speedPicker, 'change', () => {
			this.#speed = Object.hasOwn(speeds, speedPicker.value) ? speedPicker.value : 'medium';
			this.store('speed', this.#speed);
			this.#game.catTimer = 0;
			this.say(`Speed: ${speedPicker.selectedOptions[0].textContent}.${this.#speed === 'cheetah' ? ' Good luck!' : ''}${this.#speed === 'snail' ? ' The cats are very full of fish today.' : ''}`);
		});

		// A click elsewhere pauses the game, as the keys no longer reach it, so nobody loses a mouse while reading the page. The message box of the desktop is not elsewhere.
		this.on(document, 'pointerdown', event => {
			if (!this.desktopWindow.contains(event.target) && !event.target.closest('[data-desktop-window="message"]')) {
				this.#setPaused(true, 'Paused, as you clicked somewhere else. Press P, or tap the field, to go on.');
			}
		});

		this.#newGame(1);
	}

	get visibilityTarget() {
		return this.parts.screen;
	}

	visibilityChanged(isVisible) {
		if (isVisible) {
			this.#draw();
			return;
		}

		this.#stopRepeat();

		if (document.hidden) {
			this.#setPaused(true, 'Paused, as you left the page. Press P, or tap the field, to go on.');
		} else if (this.desktopWindow.hidden) {
			this.#setPaused(true);
		} else {
			this.#setPaused(true, 'Paused, as the field scrolled away. Press P, or tap the field, to go on.');
		}
	}

	#hasYarn() {
		return layoutOf(this.#game.level).hasYarn || this.#game.level > layouts.length;
	}

	#showStats() {
		const game = this.#game;
		const wave = Math.min(game.wave + 1, game.waves.length);
		const text = `Level ${game.level} ★ Wave ${wave} of ${game.waves.length} ★ Cats ${game.cats.length} ★ Score ${game.score.toLocaleString('en-US')} ★ Best ${Math.max(this.#best, game.score).toLocaleString('en-US')}`;
		const {stats} = this.parts;

		if (stats.textContent !== text) {
			stats.textContent = text;
		}
	}

	get #isSoundOn() {
		return this.parts.sound.getAttribute('aria-pressed') === 'true';
	}

	// The sounds, made with tones and noise through the volume of the tray, once the visitor turns them on.
	get #audio() {
		return this.#isSoundOn ? this.sound() : undefined;
	}

	#envelope(gain, time, duration, volume) {
		gain.gain.setValueAtTime(0.0001, time);
		gain.gain.exponentialRampToValueAtTime(volume, time + 0.01);
		gain.gain.exponentialRampToValueAtTime(0.0001, time + duration);
	}

	#tone(frequency, start, duration, {type = 'square', volume = 0.05, slide} = {}) {
		const audio = this.#audio;

		if (!audio) {
			return;
		}

		const {context, output} = audio;
		const oscillator = context.createOscillator();
		const gain = context.createGain();
		const time = context.currentTime + start;
		oscillator.type = type;
		oscillator.frequency.setValueAtTime(frequency, time);

		if (slide) {
			oscillator.frequency.exponentialRampToValueAtTime(slide, time + duration);
		}

		this.#envelope(gain, time, duration, volume);
		oscillator.connect(gain).connect(output);
		oscillator.start(time);
		oscillator.stop(time + duration + 0.05);
	}

	#noise(start, duration, {volume = 0.12, frequency = 1500} = {}) {
		const audio = this.#audio;

		if (!audio) {
			return;
		}

		const {context, output} = audio;
		const length = Math.ceil(context.sampleRate * duration);
		const buffer = context.createBuffer(1, length, context.sampleRate);
		const samples = buffer.getChannelData(0);

		for (let index = 0; index < length; index++) {
			samples[index] = (Math.random() * 2) - 1;
		}

		const source = context.createBufferSource();
		const filter = context.createBiquadFilter();
		const gain = context.createGain();
		const time = context.currentTime + start;
		source.buffer = buffer;
		filter.type = 'lowpass';
		filter.frequency.value = frequency;
		this.#envelope(gain, time, duration, volume);
		source.connect(filter).connect(gain).connect(output);
		source.start(time);
	}

	#sounds = {
		push: () => this.#tone(110, 0, 0.07, {type: 'triangle', volume: 0.12}),
		bump: () => this.#tone(70, 0, 0.06, {type: 'triangle', volume: 0.1}),
		eat: () => {
			this.#tone(330, 0, 0.05);
			this.#tone(250, 0.07, 0.05);
		},
		brunost: () => {
			for (const [index, frequency] of [523, 659, 784, 1047, 1319].entries()) {
				this.#tone(frequency, index * 0.06, 0.12, {type: 'triangle', volume: 0.08});
			}
		},
		sit: () => this.#tone(440, 0, 0.12, {type: 'triangle', volume: 0.06, slide: 220}),
		cheese: () => {
			for (const [index, frequency] of [392, 523, 659, 784].entries()) {
				this.#tone(frequency, index * 0.08, 0.15, {type: 'square', volume: 0.04});
			}
		},
		wave: () => {
			this.#tone(196, 0, 0.12, {type: 'sawtooth', volume: 0.04});
			this.#tone(185, 0.15, 0.2, {type: 'sawtooth', volume: 0.04});
		},
		meow: () => {
			const audio = this.#audio;

			if (!audio) {
				return;
			}

			// A sawtooth through a filter, which goes up and down like a cat.
			const {context, output} = audio;
			const oscillator = context.createOscillator();
			const filter = context.createBiquadFilter();
			const gain = context.createGain();
			const time = context.currentTime;
			oscillator.type = 'sawtooth';
			oscillator.frequency.setValueAtTime(500, time);
			oscillator.frequency.linearRampToValueAtTime(880, time + 0.15);
			oscillator.frequency.linearRampToValueAtTime(420, time + 0.5);
			filter.type = 'bandpass';
			filter.frequency.setValueAtTime(900, time);
			filter.frequency.linearRampToValueAtTime(2000, time + 0.15);
			filter.frequency.linearRampToValueAtTime(700, time + 0.5);
			filter.Q.value = 3;
			this.#envelope(gain, time, 0.55, 0.25);
			oscillator.connect(filter).connect(gain).connect(output);
			oscillator.start(time);
			oscillator.stop(time + 0.6);
		},
		squish: () => {
			this.#noise(0, 0.3, {frequency: 500, volume: 0.25});
			this.#tone(300, 0, 0.3, {type: 'sawtooth', volume: 0.06, slide: 50});
		},
		snap: () => {
			this.#noise(0, 0.08, {frequency: 6000, volume: 0.3});
			this.#tone(90, 0.02, 0.15, {type: 'square', volume: 0.08});
		},
		hole: () => this.#tone(500, 0, 0.4, {type: 'sine', volume: 0.15, slide: 80}),
		yarn: () => this.#tone(880, 0, 0.1, {type: 'sine', volume: 0.06, slide: 1320}),
		ring: () => {
			for (let index = 0; index < 6; index++) {
				this.#tone(1568, index * 0.08, 0.06, {type: 'square', volume: 0.03});
			}
		},
		squeak: () => this.#tone(2400, 0, 0.08, {type: 'sine', volume: 0.06, slide: 3200}),
		extraMouse: () => {
			for (const [index, frequency] of [784, 988, 1175].entries()) {
				this.#tone(frequency, index * 0.08, 0.1, {type: 'square', volume: 0.04});
			}
		},
		won: () => {
			for (const [index, frequency] of [523, 659, 784, 1047, 784, 1047].entries()) {
				this.#tone(frequency, index * 0.11, 0.18, {type: 'triangle', volume: 0.1});
			}
		},
		over: () => {
			for (const [index, frequency] of [392, 330, 262, 196].entries()) {
				this.#tone(frequency, index * 0.2, 0.28, {type: 'triangle', volume: 0.1});
			}
		},
	};

	// A question with the message box of the desktop.
	ask(options) {
		return super.ask({title: 'Rodent’s Revenge', icon: '🐁', opener: this.parts.screen, ...options});
	}

	#tileAt(x, y) {
		return (x < 0 || y < 0 || x >= size || y >= size) ? wall : this.#game.grid[indexOf(x, y)];
	}

	#catAt(x, y) {
		return this.#game.cats.find(cat => cat.x === x && cat.y === y);
	}

	#yarnAt(x, y) {
		return this.#game.yarns.find(yarn => yarn.x === x && yarn.y === y);
	}

	#isMouseAt(x, y) {
		return this.#game.mouse.x === x && this.#game.mouse.y === y;
	}

	// A square where a cat or a ball of yarn can go: open, and nobody there.
	#isFree(x, y) {
		return this.#tileAt(x, y) === empty && !this.#catAt(x, y) && !this.#yarnAt(x, y) && !this.#isMouseAt(x, y);
	}

	#buildLevel() {
		const {grid} = this.#game;
		const random = seededRandom(this.#game.level * 7919);
		grid.fill(empty);

		const set = (x, y, tile) => {
			grid[indexOf(x, y)] = tile;
		};

		const builder = {
			random,
			set,
			fill(from, to, tile, isIncluded = () => true) {
				for (let y = from; y <= to; y++) {
					for (let x = from; x <= to; x++) {
						if (isIncluded(x, y)) {
							set(x, y, tile);
						}
					}
				}
			},
			// Things on random squares, away from the start of the mouse in the middle.
			scatter(count, tile, from = 2, to = 20) {
				let placed = 0;

				for (let attempt = 0; attempt < count * 30 && placed < count; attempt++) {
					const x = from + Math.floor(random() * (to - from + 1));
					const y = from + Math.floor(random() * (to - from + 1));

					if (chebyshevFromCenter(x, y) > 1 && [empty, block].includes(grid[indexOf(x, y)])) {
						set(x, y, tile);
						placed++;
					}
				}
			},
		};

		layoutOf(this.#game.level).build(builder);

		for (let index = 0; index < size; index++) {
			set(index, 0, wall);
			set(index, size - 1, wall);
			set(0, index, wall);
			set(size - 1, index, wall);
		}

		set(center, center, empty);
	}

	#spawnCats(count) {
		const game = this.#game;
		let spawned = 0;

		for (const minimum of [7, 4, 2]) {
			const places = [];

			for (let y = 1; y < size - 1; y++) {
				for (let x = 1; x < size - 1; x++) {
					if (this.#isFree(x, y) && distanceBetween({x, y}, game.mouse) >= minimum) {
						places.push({x, y});
					}
				}
			}

			while (spawned < count && places.length > 0) {
				const [place] = places.splice(Math.floor(Math.random() * places.length), 1);
				game.cats.push({...place, isSitting: false, facing: place.x < game.mouse.x ? 1 : -1});
				spawned++;
			}

			if (spawned === count) {
				break;
			}
		}

		return spawned;
	}

	#startWave() {
		const count = this.#game.waves[this.#game.wave];

		// A field without room for the cats skips the wave, so the level can still end.
		if (this.#spawnCats(count) === 0) {
			this.#nextWave();
			return false;
		}

		return true;
	}

	#startLevel() {
		const game = this.#game;
		game.id++;
		this.#buildLevel();
		game.mouse = {x: center, y: center, facing: -1};
		game.cats = [];
		game.yarns = [];
		game.waves = wavesOf(game.level);
		game.wave = 0;
		game.time = levelTime;
		game.stuck = 0;
		game.death = undefined;
		game.squeak = 0;
		game.catTimer = 0;
		game.yarnTimer = 0;
		game.yarnSpawnTimer = 0;
		game.mode = 'ready';
		this.parts.level.value = String(((game.level - 1) % layouts.length) + 1);
		this.#startWave();
		this.parts.pause.setAttribute('aria-pressed', 'false');
		const layout = layoutOf(game.level);
		const extras = [];

		if (layout.name === 'Rocky’s Room') {
			extras.push('Look, there is Rocky, my pet rock! He does not move. He never does.');
		}

		if (this.#hasYarn()) {
			extras.push('Watch out for Mormor’s balls of yarn.');
		}

		if (this.reducedMotion) {
			extras.push('The cats move only when you move, as your computer prefers less motion.');
		}

		this.say([`Level ${game.level}: ${layout.name}. Push the blocks to box in ${game.waves.length} waves of cats.`, ...extras, 'Press an arrow key or tap the field to start.'].join(' '));
		this.#showStats();
		this.#draw();
	}

	#newGame(level = Number(this.parts.level.value)) {
		const game = this.#game;
		game.level = level;
		game.score = 0;
		game.mice = 3;
		game.nextExtraMouse = 10_000;
		this.#startLevel();
	}

	#updateBest() {
		if (this.#game.score > this.#best) {
			this.#best = this.#game.score;
			this.store('best', this.#best);
		}
	}

	#addScore(points) {
		const game = this.#game;
		game.score += points;

		// An extra mouse for every 10,000 points, like a free life.
		if (game.score >= game.nextExtraMouse) {
			game.nextExtraMouse += 10_000;
			game.mice = Math.min(game.mice + 1, 6);
			this.#sounds.extraMouse();
			this.say('An extra mouse for 10,000 points! Squeak!');
		}

		this.#showStats();
	}

	// A cat can move when an open square or the mouse is next to it. A cat that cannot sits down.
	#canMove(cat) {
		return neighbors.some(([dx, dy]) => this.#isMouseAt(cat.x + dx, cat.y + dy) || this.#isFree(cat.x + dx, cat.y + dy));
	}

	#checkTrapped() {
		const {cats} = this.#game;

		for (const cat of cats) {
			const wasSitting = cat.isSitting;
			cat.isSitting = !this.#canMove(cat);

			if (cat.isSitting && !wasSitting) {
				this.#sounds.sit();
			}
		}

		if (cats.length > 0 && cats.every(cat => cat.isSitting)) {
			this.#turnIntoCheese();
		}
	}

	#turnIntoCheese() {
		const game = this.#game;
		let brunostCount = 0;

		for (const cat of game.cats) {
			// Now and then, a cat turns into brunost, the brown cheese of Norway, which is worth more.
			const isBrunost = Math.random() < 0.15;
			brunostCount += isBrunost ? 1 : 0;
			game.grid[indexOf(cat.x, cat.y)] = isBrunost ? brunost : cheese;
		}

		const count = game.cats.length;
		game.cats = [];
		this.#sounds.cheese();
		this.#nextWave(`${count === 1 ? 'The cat is' : `All ${count} cats are`} trapped, and turned into cheese${brunostCount > 0 ? ', and some of it is brunost' : ''}!`);
	}

	#nextWave(message = '') {
		const game = this.#game;
		game.wave++;

		if (game.wave >= game.waves.length) {
			this.#levelDone(message);
			return;
		}

		if (this.#startWave()) {
			this.#sounds.wave();
			const count = game.cats.length;
			this.say(`${message} Wave ${game.wave + 1} of ${game.waves.length}: here ${count === 1 ? 'comes a cat' : `come ${count} cats`}!`.trim());
		}

		this.#showStats();
	}

	async #levelDone(message) {
		const game = this.#game;
		game.mode = 'won';
		const seconds = Math.max(Math.ceil(game.time), 0);
		const timeBonus = seconds * 10;
		let cheeses = 0;
		let brunosts = 0;

		for (const tile of game.grid) {
			cheeses += tile === cheese ? 1 : 0;
			brunosts += tile === brunost ? 1 : 0;
		}

		// The cheese that is left on the field goes in the doggy bag.
		const cheeseBonus = (cheeses * 100) + (brunosts * 500);
		this.#addScore(timeBonus + cheeseBonus);
		this.#updateBest();
		this.#sounds.won();
		this.#draw();
		const {id} = game;
		const nextName = layoutOf(game.level + 1).name;
		const text = `${message} Level ${game.level} done: ${layoutOf(game.level).name}!\n\nTime bonus: ${timeBonus.toLocaleString('en-US')} points for the ${seconds} seconds left on the clock.${cheeseBonus > 0 ? `\nCheese in the doggy bag: ${cheeseBonus.toLocaleString('en-US')} points.` : ''}\n\nNext: level ${game.level + 1}, ${nextName}.`.trim();
		this.say(text.replaceAll(/\n+/g, ' '));
		await this.ask({icon: '🧀', text});

		// New Game while the message box was open already started over.
		if (game.id !== id || game.mode !== 'won') {
			return;
		}

		game.level++;
		this.#startLevel();
	}

	async #gameOver() {
		const game = this.#game;
		game.mode = 'over';
		const isRecord = game.score > this.#best;
		this.#updateBest();
		this.#sounds.over();
		this.#draw();
		const {id} = game;
		const text = `The cats won!\n\nYou got ${game.score.toLocaleString('en-US')} points and reached level ${game.level}.${isRecord ? ' A new high score!' : ''}\n\nMamma says it is dinner time anyway.`;
		this.say(text.replaceAll(/\n+/g, ' '));
		await this.ask({icon: '🐈', text});

		if (game.id === id) {
			this.say('Game over. Press New Game, an arrow key, or tap the field, for a new game.');
		}
	}

	#die(kind, details = {}) {
		const game = this.#game;
		game.mode = 'dying';
		game.death = {kind, timer: 2, word: Math.random() < 0.7 ? 'Meow!' : 'Mjau!', ...details};
		game.squeak = 0;
		game.stuck = 0;
		const left = game.mice === 0 ? 'That was the last mouse.' : `${game.mice} ${game.mice === 1 ? 'mouse' : 'mice'} left.`;

		if (kind === 'caught') {
			this.#sounds.meow();
			this.say(`“${game.death.word}” The cat caught the mouse! ${left}`);
		} else if (kind === 'squished') {
			this.#sounds.squish();
			this.say(`Splat! A ball of yarn squashed the mouse flat, as flat as a lefse. ${left}`);
		} else {
			this.#sounds.snap();
			this.say(`SNAP! That was a mouse trap. Ouch. ${left}`);
		}

		this.#draw();
		this.#loop.start();
	}

	// The new mouse starts in the middle, or on the open square farthest from the cats and the yarn.
	#placeNewMouse() {
		const dangers = [...this.#game.cats, ...this.#game.yarns];
		const safety = place => Math.min(99, ...dangers.map(danger => distanceBetween(place, danger)));
		const start = {x: center, y: center};

		if (this.#isFree(center, center) && safety(start) >= 5) {
			return start;
		}

		let bestPlace = start;
		let bestSafety = -1;

		for (let y = 1; y < size - 1; y++) {
			for (let x = 1; x < size - 1; x++) {
				const placeSafety = this.#isFree(x, y) ? safety({x, y}) : -1;

				if (placeSafety > bestSafety) {
					bestPlace = {x, y};
					bestSafety = placeSafety;
				}
			}
		}

		return bestPlace;
	}

	#finishDeath() {
		const game = this.#game;
		const {death} = game;
		game.death = undefined;

		if (death.kind === 'trapped') {
			// The trap snapped, so it is used up.
			game.grid[indexOf(death.x, death.y)] = empty;
		}

		if (game.mice === 0) {
			this.#gameOver();
			return;
		}

		game.mice--;
		const place = this.#placeNewMouse();
		game.mouse = {...place, facing: -1};
		game.mode = 'playing';
		game.catTimer = 0;
		this.say(`A new mouse! ${game.mice === 0 ? 'It is the last one.' : `${game.mice} more in the hole.`}`);
		this.#checkTrapped();
		this.#draw();
		this.#loop.start();
	}

	// The cats go the shortest way to the mouse, over open squares and in eight directions. A cat that has no way to the mouse wanders toward it.
	#stepCats() {
		const game = this.#game;
		const distances = new Int16Array(size * size).fill(-1);
		const queue = [indexOf(game.mouse.x, game.mouse.y)];
		distances[queue[0]] = 0;

		for (let head = 0; head < queue.length; head++) {
			const index = queue[head];
			const x = index % size;
			const y = Math.floor(index / size);

			for (const [dx, dy] of neighbors) {
				const next = indexOf(x + dx, y + dy);

				if (this.#tileAt(x + dx, y + dy) === empty && distances[next] === -1) {
					distances[next] = distances[index] + 1;
					queue.push(next);
				}
			}
		}

		const distanceOf = (x, y) => {
			const distance = distances[indexOf(x, y)];
			return distance === -1 ? 999 : distance;
		};

		const cats = game.cats.toSorted((first, second) => distanceOf(first.x, first.y) - distanceOf(second.x, second.y));

		for (const cat of cats) {
			const options = neighbors.map(([dx, dy]) => ({x: cat.x + dx, y: cat.y + dy})).filter(place => this.#isMouseAt(place.x, place.y) || this.#isFree(place.x, place.y));

			if (options.length === 0) {
				continue;
			}

			if (game.mouse.x !== cat.x) {
				cat.facing = Math.sign(game.mouse.x - cat.x);
			}

			const caught = options.find(place => this.#isMouseAt(place.x, place.y));

			if (caught) {
				cat.x = caught.x;
				cat.y = caught.y;
				this.#die('caught', {cat});
				return;
			}

			const here = distanceOf(cat.x, cat.y);
			const straight = place => Math.hypot(place.x - game.mouse.x, place.y - game.mouse.y);
			let choice;

			if (here < 999) {
				// The cat takes a step that gets it closer along the way, and waits behind another cat that is in the way.
				const closer = options.filter(place => distanceOf(place.x, place.y) < here);
				closer.sort((first, second) => (distanceOf(first.x, first.y) - distanceOf(second.x, second.y)) || (straight(first) - straight(second)));
				choice = closer[0];
			} else {
				const scored = options.map(place => ({place, score: straight(place) + (Math.random() * 2.5)}));
				scored.sort((first, second) => first.score - second.score);
				choice = scored[0].place;
			}

			if (choice) {
				cat.x = choice.x;
				cat.y = choice.y;
			}
		}

		this.#checkTrapped();
	}

	// A ball of yarn rolls on the diagonal, and bounces off what is in its way. It unravels after a while, or when it is boxed in.
	#stepYarns() {
		const game = this.#game;

		for (const yarn of [...game.yarns]) {
			yarn.life--;
			let hasMoved = false;

			for (const [dx, dy] of [[yarn.dx, yarn.dy], [-yarn.dx, yarn.dy], [yarn.dx, -yarn.dy], [-yarn.dx, -yarn.dy]]) {
				const x = yarn.x + dx;
				const y = yarn.y + dy;

				if (this.#isMouseAt(x, y) && game.mode === 'playing') {
					yarn.dx = -dx;
					yarn.dy = -dy;
					this.#die('squished', {yarn});
					return;
				}

				if (this.#isFree(x, y)) {
					yarn.x = x;
					yarn.y = y;
					yarn.dx = dx;
					yarn.dy = dy;
					yarn.spin += 1.2 * dx;
					hasMoved = true;
					break;
				}
			}

			if (!hasMoved || yarn.life <= 0) {
				game.yarns.splice(game.yarns.indexOf(yarn), 1);
			}
		}

		// The yarn can box in the last free cat.
		this.#checkTrapped();
	}

	#spawnYarn() {
		const game = this.#game;

		if (game.yarns.length >= Math.min(1 + Math.floor((game.level - 1) / layouts.length), 3)) {
			return;
		}

		const places = [];

		for (let index = 1; index < size - 1; index++) {
			for (const [x, y] of [[index, 1], [index, size - 2], [1, index], [size - 2, index]]) {
				if (this.#isFree(x, y) && distanceBetween({x, y}, game.mouse) >= 6) {
					places.push({x, y});
				}
			}
		}

		if (places.length === 0) {
			return;
		}

		const {x, y} = randomItem(places);
		game.yarns.push({x, y, dx: x < center ? 1 : -1, dy: y < center ? 1 : -1, life: 40, spin: 0});
		this.#sounds.yarn();
		this.say(randomItem(['A ball of yarn rolls in! Mormor will want that back.', 'Yarn! Do not get squashed.', 'Another ball of yarn. Mormor is knitting a sweater for the cat.']));
	}

	// The time that goes by: the clock gives the bonus for the time that is left, and when it runs out, it rings, and another cat comes in through the cat flap. The squeak fades, and the mouse climbs out of the sink hole.
	#passTime(seconds) {
		const game = this.#game;
		game.time -= seconds;
		game.squeak = Math.max(game.squeak - seconds, 0);

		if (game.stuck > 0) {
			game.stuck = Math.max(game.stuck - seconds, 0);

			if (game.stuck === 0) {
				this.say('Free! The mouse climbed out of the sink hole.');
			}
		}

		if (game.time <= 0) {
			game.time = levelTime;

			if (this.#spawnCats(1) > 0) {
				this.#sounds.ring();
				this.say('Brrring! The clock ran out, and another cat came in through the cat flap.');
				this.#showStats();
			}
		}

		if (this.#hasYarn()) {
			game.yarnSpawnTimer += seconds;

			if (game.yarnSpawnTimer >= 9) {
				game.yarnSpawnTimer = 0;
				this.#spawnYarn();
			}
		}
	}

	#update(delta) {
		const game = this.#game;

		if (game.mode === 'dying') {
			game.death.timer -= delta;

			if (game.death.timer <= 0) {
				this.#finishDeath();
			}

			return;
		}

		this.#passTime(delta);
		const catInterval = speeds[this.#speed];
		game.catTimer += delta;

		while (game.catTimer >= catInterval && game.mode === 'playing') {
			game.catTimer -= catInterval;
			this.#stepCats();
		}

		if (game.mode !== 'playing') {
			return;
		}

		game.yarnTimer += delta;

		while (game.yarnTimer >= catInterval * 0.6 && game.mode === 'playing') {
			game.yarnTimer -= catInterval * 0.6;
			this.#stepYarns();
		}
	}

	// With reduced motion, the world takes one turn of half a second after each step of the mouse, so nothing moves by itself.
	#takeTurn() {
		if (!this.reducedMotion || this.#game.mode !== 'playing') {
			return;
		}

		this.#passTime(0.5);
		this.#stepCats();

		if (this.#game.mode === 'playing') {
			this.#stepYarns();
		}
	}

	#moveMouse(dx, dy) {
		const game = this.#game;

		if (game.mode === 'won' || game.mode === 'dying') {
			return;
		}

		if (game.mode === 'over') {
			this.#newGame();
			return;
		}

		if (game.mode === 'paused') {
			this.#setPaused(false);
			return;
		}

		if (game.mode === 'ready') {
			game.mode = 'playing';
			this.say(this.reducedMotion ? 'Go! The cats take a step each time you do.' : 'Go! Push the blocks, and trap the cats.');
			this.#loop.start();
		}

		const {mouse} = game;

		if (dx === 0 && dy === 0) {
			game.squeak = 1;
			this.#sounds.squeak();
			this.#takeTurn();
			this.#draw();
			return;
		}

		if (dx !== 0) {
			mouse.facing = dx;
		}

		if (game.stuck > 0) {
			this.say('Stuck in the sink hole! Wiggle, wiggle…');
			this.#takeTurn();
			this.#draw();
			return;
		}

		const x = mouse.x + dx;
		const y = mouse.y + dy;
		const tile = this.#tileAt(x, y);

		if (tile === wall || tile === rocky) {
			this.#sounds.bump();

			if (tile === rocky) {
				this.say(randomItem(['That is Rocky, my pet rock. He does not move. He never moves.', 'Rocky says nothing. Rocky is a good boy.', 'You cannot push Rocky. He is very stubborn, for a rock.']));
			}

			this.#draw();
			return;
		}

		if (this.#catAt(x, y)) {
			mouse.x = x;
			mouse.y = y;
			this.#die('caught', {cat: this.#catAt(x, y)});
			return;
		}

		if (this.#yarnAt(x, y)) {
			this.#die('squished', {yarn: this.#yarnAt(x, y)});
			return;
		}

		if (tile === block) {
			// The whole row of blocks moves one square, when the square after the last block is open.
			let endX = x;
			let endY = y;

			while (this.#tileAt(endX, endY) === block) {
				endX += dx;
				endY += dy;
			}

			if (!this.#isFree(endX, endY)) {
				this.#sounds.bump();
				this.#draw();
				return;
			}

			game.grid[indexOf(endX, endY)] = block;
			game.grid[indexOf(x, y)] = empty;
			this.#sounds.push();
		}

		mouse.x = x;
		mouse.y = y;

		if (tile === cheese || tile === brunost) {
			game.grid[indexOf(x, y)] = empty;

			if (tile === brunost) {
				this.#sounds.brunost();
				this.say('Brunost! The brown cheese of Norway, 500 points. Mormor would be proud.');
				this.#addScore(500);
			} else {
				this.#sounds.eat();
				this.#addScore(100);
			}
		} else if (tile === trap) {
			this.#die('trapped', {x, y});
			return;
		} else if (tile === hole) {
			game.stuck = 3;
			this.#sounds.hole();
			this.say('Oops, a sink hole! The mouse is stuck for a while.');
		}

		this.#checkTrapped();
		this.#takeTurn();
		this.#draw();
	}

	#roundedBox(x, y, width, height, radius) {
		this.#context.beginPath();
		this.#context.roundRect(x, y, width, height, radius);
	}

	#bevel(x, y, face, light, dark) {
		const context = this.#context;
		context.fillStyle = face;
		context.fillRect(x, y, cell, cell);
		context.fillStyle = light;
		context.fillRect(x, y, cell, 3);
		context.fillRect(x, y, 3, cell);
		context.fillStyle = dark;
		context.fillRect(x, y + cell - 3, cell, 3);
		context.fillRect(x + cell - 3, y, 3, cell);
	}

	#drawEmoji(emoji, x, y, {fontSize = 31, flip = false, scaleX = 1, scaleY = 1, rotation = 0} = {}) {
		const context = this.#context;
		context.save();
		context.translate(x, y);
		context.rotate(rotation);
		context.scale((flip ? -1 : 1) * scaleX, scaleY);
		context.font = `${fontSize}px ${emojiFont}`;
		context.textAlign = 'center';
		context.textBaseline = 'middle';
		context.fillText(emoji, 0, 2);
		context.restore();
	}

	// Rocky, my pet rock, with googly eyes that watch the mouse.
	#drawRocky(x, y) {
		const context = this.#context;
		const {mouse} = this.#game;
		const middleX = x + (cell / 2);
		const middleY = y + (cell / 2);
		context.fillStyle = '#8d8478';
		context.strokeStyle = '#4a443c';
		context.lineWidth = 2;
		context.beginPath();
		context.ellipse(middleX, middleY + 2, 14, 11, 0, 0, Math.PI * 2);
		context.fill();
		context.stroke();
		context.fillStyle = '#b3aa9c';
		context.beginPath();
		context.ellipse(middleX - 5, middleY - 3, 5, 3, -0.4, 0, Math.PI * 2);
		context.fill();
		const lookX = Math.sign(mouse.x - (x / cell)) * 1.5;
		const lookY = Math.sign(mouse.y - ((y - top) / cell)) * 1.5;

		for (const eyeX of [middleX - 5, middleX + 5]) {
			context.fillStyle = '#ffffff';
			context.beginPath();
			context.arc(eyeX, middleY, 4.5, 0, Math.PI * 2);
			context.fill();
			context.strokeStyle = '#000000';
			context.lineWidth = 1;
			context.stroke();
			context.fillStyle = '#000000';
			context.beginPath();
			context.arc(eyeX + lookX, middleY + lookY, 2, 0, Math.PI * 2);
			context.fill();
		}
	}

	#drawTrap(x, y) {
		const context = this.#context;
		context.fillStyle = '#c8873e';
		context.fillRect(x + 4, y + 9, cell - 8, cell - 16);
		context.fillStyle = '#8a5520';
		context.fillRect(x + 4, y + cell - 9, cell - 8, 2);
		context.strokeStyle = '#a0a0a0';
		context.lineWidth = 2;
		context.strokeRect(x + 7, y + 11, cell - 14, cell - 21);
		context.fillStyle = '#ffd800';
		context.beginPath();
		context.moveTo(x + 13, y + 20);
		context.lineTo(x + 20, y + 20);
		context.lineTo(x + 20, y + 15);
		context.closePath();
		context.fill();
	}

	#drawHole(x, y) {
		const context = this.#context;
		context.fillStyle = '#6b4a2b';
		context.beginPath();
		context.ellipse(x + (cell / 2), y + (cell / 2), 14, 11, 0, 0, Math.PI * 2);
		context.fill();
		context.fillStyle = '#1a1006';
		context.beginPath();
		context.ellipse(x + (cell / 2), y + (cell / 2) + 1, 11, 8, 0, 0, Math.PI * 2);
		context.fill();
	}

	// A block of brunost, brown, with a curl on top from the cheese slicer.
	#drawBrunost(x, y) {
		const context = this.#context;
		context.fillStyle = '#8a4b1c';
		context.fillRect(x + 6, y + 12, 20, 14);
		context.fillStyle = '#c27a3a';
		context.beginPath();
		context.moveTo(x + 6, y + 12);
		context.lineTo(x + 11, y + 7);
		context.lineTo(x + 31, y + 7);
		context.lineTo(x + 26, y + 12);
		context.closePath();
		context.fill();
		context.fillStyle = '#6a3510';
		context.beginPath();
		context.moveTo(x + 26, y + 12);
		context.lineTo(x + 31, y + 7);
		context.lineTo(x + 31, y + 21);
		context.lineTo(x + 26, y + 26);
		context.closePath();
		context.fill();
		context.strokeStyle = '#e8a060';
		context.lineWidth = 2;
		context.beginPath();
		context.arc(x + 18, y + 7, 4, Math.PI, Math.PI * 1.9);
		context.stroke();
	}

	#drawBubble(text, cellX, cellY) {
		const context = this.#context;
		const {screen} = this.parts;
		context.font = `bold 20px ${comicFont}`;
		const width = context.measureText(text).width + 18;
		const height = 32;
		const pointX = (cellX * cell) + (cell / 2);
		const pointY = top + (cellY * cell);
		const isBelow = pointY - height - 12 < top;
		const boxX = Math.min(Math.max(pointX - (width / 2), 4), screen.width - width - 4);
		const boxY = isBelow ? pointY + cell + 12 : pointY - height - 10;
		context.fillStyle = '#ffffff';
		context.strokeStyle = '#000000';
		context.lineWidth = 2;
		this.#roundedBox(boxX, boxY, width, height, 10);
		context.fill();
		context.stroke();

		// The tail of the balloon points at who talks.
		context.beginPath();
		const tailY = isBelow ? boxY : boxY + height;
		const tipY = isBelow ? pointY + cell - 2 : pointY + 2;
		const tailX = Math.min(Math.max(pointX, boxX + 12), boxX + width - 12);
		context.moveTo(tailX - 7, tailY);
		context.lineTo(pointX, tipY);
		context.lineTo(tailX + 7, tailY);
		context.fill();
		context.stroke();
		context.fillRect(tailX - 6, tailY - (isBelow ? -1 : 2), 12, 3);
		context.fillStyle = '#000000';
		context.textAlign = 'center';
		context.textBaseline = 'middle';
		context.fillText(text, boxX + (width / 2), boxY + (height / 2) + 1);
	}

	#drawPanel() {
		const context = this.#context;
		const game = this.#game;
		const {screen} = this.parts;
		context.fillStyle = '#c0c0c0';
		context.fillRect(0, 0, screen.width, top);
		context.fillStyle = '#ffffff';
		context.fillRect(0, 0, screen.width, 2);
		context.fillStyle = '#808080';
		context.fillRect(0, top - 3, screen.width, 3);

		// The spare mice, on the left.
		for (let index = 0; index < Math.min(game.mice, 6); index++) {
			this.#drawEmoji('🐁', 26 + (index * 36), top / 2, {fontSize: 28});
		}

		// The clock in the middle, with the time that has gone in red.
		const clockX = screen.width / 2;
		const clockY = top / 2;
		const radius = 25;
		const gone = 1 - (Math.max(game.time, 0) / levelTime);
		const handAngle = (-Math.PI / 2) + (gone * Math.PI * 2);
		context.fillStyle = '#ffffff';
		context.beginPath();
		context.arc(clockX, clockY, radius, 0, Math.PI * 2);
		context.fill();

		if (gone > 0) {
			context.fillStyle = '#ff9090';
			context.beginPath();
			context.moveTo(clockX, clockY);
			context.arc(clockX, clockY, radius, -Math.PI / 2, handAngle);
			context.closePath();
			context.fill();
		}

		context.strokeStyle = '#000000';
		context.lineWidth = 2;
		context.beginPath();
		context.arc(clockX, clockY, radius, 0, Math.PI * 2);
		context.stroke();

		for (let hour = 0; hour < 12; hour++) {
			const angle = (hour / 12) * Math.PI * 2;
			context.beginPath();
			context.moveTo(clockX + (Math.cos(angle) * (radius - 5)), clockY + (Math.sin(angle) * (radius - 5)));
			context.lineTo(clockX + (Math.cos(angle) * (radius - 1)), clockY + (Math.sin(angle) * (radius - 1)));
			context.stroke();
		}

		context.lineWidth = 3;
		context.beginPath();
		context.moveTo(clockX, clockY);
		context.lineTo(clockX + (Math.cos(handAngle) * (radius - 6)), clockY + (Math.sin(handAngle) * (radius - 6)));
		context.stroke();

		// The score, in red digits, on the right.
		context.fillStyle = '#000000';
		context.fillRect(screen.width - 178, 12, 166, 40);
		context.fillStyle = '#ff2a2a';
		context.font = 'bold 32px "Courier New", monospace';
		context.textAlign = 'right';
		context.textBaseline = 'middle';
		context.fillText(String(Math.min(game.score, 999_999)).padStart(6, '0'), screen.width - 20, 33);
	}

	#drawBanner(title, ...lines) {
		const context = this.#context;
		const {screen} = this.parts;
		const width = 640;
		const height = 80 + (lines.length * 32);
		const x = (screen.width - width) / 2;
		const y = top + ((screen.height - top - height) / 2);
		context.fillStyle = 'rgb(0 0 64 / 88%)';
		context.fillRect(x, y, width, height);
		context.strokeStyle = '#ffffff';
		context.lineWidth = 3;
		context.strokeRect(x, y, width, height);
		context.textAlign = 'center';
		context.textBaseline = 'alphabetic';
		context.fillStyle = '#ffff00';
		context.font = `bold 36px ${comicFont}`;
		context.fillText(title, screen.width / 2, y + 52);
		context.fillStyle = '#ffffff';
		context.font = '26px system-ui, sans-serif';

		for (const [index, line] of lines.entries()) {
			context.fillText(line, screen.width / 2, y + 92 + (index * 32));
		}
	}

	#draw() {
		const context = this.#context;
		const game = this.#game;
		const {screen} = this.parts;
		this.#drawPanel();
		context.fillStyle = '#c8c88a';
		context.fillRect(0, top, screen.width, screen.height - top);

		for (let y = 0; y < size; y++) {
			for (let x = 0; x < size; x++) {
				const tile = game.grid[indexOf(x, y)];
				const left = x * cell;
				const upper = top + (y * cell);

				if (tile === block) {
					this.#bevel(left, upper, '#c0c0c0', '#ffffff', '#808080');
				} else if (tile === wall) {
					this.#bevel(left, upper, '#505050', '#7a7a7a', '#202020');
				} else if (tile === rocky) {
					this.#drawRocky(left, upper);
				} else if (tile === trap && !(game.death?.kind === 'trapped' && game.death.x === x && game.death.y === y)) {
					this.#drawTrap(left, upper);
				} else if (tile === hole) {
					this.#drawHole(left, upper);
				} else if (tile === cheese) {
					this.#drawEmoji('🧀', left + (cell / 2), upper + (cell / 2), {fontSize: 28});
				} else if (tile === brunost) {
					this.#drawBrunost(left, upper);
				}
			}
		}

		const {mouse, death} = game;
		const mouseX = (mouse.x * cell) + (cell / 2);
		const mouseY = top + (mouse.y * cell) + (cell / 2);

		if (death?.kind === 'squished') {
			// Flattened, like in the cartoons.
			this.#drawEmoji('🐁', mouseX, mouseY + 9, {fontSize: 30, scaleX: 1.5, scaleY: 0.3, flip: mouse.facing > 0});
		} else if (death?.kind === 'trapped') {
			this.#drawTrap(mouse.x * cell, top + (mouse.y * cell));
			this.#drawEmoji('🐁', mouseX, mouseY + 4, {fontSize: 26, scaleX: 1.2, scaleY: 0.5, flip: mouse.facing > 0});
			context.fillStyle = '#a0a0a0';
			context.fillRect(mouseX - 12, mouseY - 1, 24, 3);
		} else if (death?.kind !== 'caught') {
			if (game.stuck > 0) {
				// Half in the sink hole.
				context.save();
				context.beginPath();
				context.rect(mouseX - cell, mouseY - cell, cell * 2, cell);
				context.clip();
				this.#drawEmoji('🐁', mouseX, mouseY + 6, {flip: mouse.facing > 0});
				context.restore();
			} else {
				this.#drawEmoji('🐁', mouseX, mouseY, {flip: mouse.facing > 0});
			}
		}

		for (const cat of game.cats) {
			const catX = (cat.x * cell) + (cell / 2);
			const catY = top + (cat.y * cell) + (cell / 2);

			if (cat.isSitting) {
				this.#drawEmoji('😿', catX, catY, {fontSize: 28});
			} else {
				this.#drawEmoji('🐈', catX, catY, {flip: cat.facing > 0});
			}
		}

		for (const yarn of game.yarns) {
			this.#drawEmoji('🧶', (yarn.x * cell) + (cell / 2), top + (yarn.y * cell) + (cell / 2), {fontSize: 28, rotation: this.reducedMotion ? 0 : yarn.spin});
		}

		if (death?.kind === 'caught') {
			this.#drawBubble(death.word, death.cat.x, death.cat.y);
		} else if (death?.kind === 'squished') {
			this.#drawBubble('Squish!', mouse.x, mouse.y);
		} else if (death?.kind === 'trapped') {
			this.#drawBubble('SNAP!', mouse.x, mouse.y);
		} else if (game.squeak > 0) {
			this.#drawBubble('Squeak!', mouse.x, mouse.y);
		}

		const layout = layoutOf(game.level);

		if (game.mode === 'ready') {
			this.#drawBanner(`Level ${game.level}: ${layout.name}`, 'Push the blocks to box in the cats.', 'Press an arrow key or tap the field to start.');
		} else if (game.mode === 'paused') {
			this.#drawBanner('Paused', 'Press P, or tap the field, to go on.');
		} else if (game.mode === 'won') {
			this.#drawBanner('Level done!', 'All the cats are cheese.');
		} else if (game.mode === 'over') {
			this.#drawBanner('Game Over', 'The cats won. Press a key or tap for a new game.');
		}
	}

	#setPaused(isPaused, reason = 'Paused. Press P, or tap the field, to go on.') {
		const game = this.#game;

		if (isPaused && game.mode === 'playing') {
			game.mode = 'paused';
			this.say(reason);
		} else if (!isPaused && game.mode === 'paused') {
			game.mode = 'playing';
			this.say('Go!');
		} else {
			return;
		}

		this.parts.pause.setAttribute('aria-pressed', String(game.mode === 'paused'));
		this.#draw();
		this.#loop.start();
	}

	#stopRepeat() {
		this.#repeatTimer?.cancel();
		this.#repeatTimer = undefined;
	}

	#startRepeat(step) {
		this.#stopRepeat();

		const next = delay => {
			this.#repeatTimer = this.timeout(delay, () => {
				if (this.#game.mode !== 'playing') {
					this.#stopRepeat();
					return;
				}

				step();
				next(140);
			});
		};

		next(280);
	}

	#cellAt(event) {
		const {screen} = this.parts;
		const box = screen.getBoundingClientRect();
		const x = ((event.clientX - box.left - screen.clientLeft) / screen.clientWidth) * screen.width;
		const y = ((event.clientY - box.top - screen.clientTop) / screen.clientHeight) * screen.height;
		return {x: Math.floor(x / cell), y: Math.floor((y - top) / cell)};
	}

	#stepTowardPointer() {
		const {mouse, mode} = this.#game;
		const dx = Math.sign(this.#pointerCell.x - mouse.x);
		const dy = Math.sign(this.#pointerCell.y - mouse.y);

		if (dx !== 0 || dy !== 0 || mode !== 'playing') {
			this.#moveMouse(dx, dy);
		}
	}

	#keyDown(event) {
		if (event.ctrlKey || event.altKey || event.metaKey) {
			return;
		}

		const key = event.key.length === 1 ? event.key.toLowerCase() : event.key;
		const step = codeSteps[event.code] ?? keySteps[key];
		const {mode} = this.#game;

		if (step) {
			event.preventDefault();
			this.#moveMouse(...step);
		} else if (key === 'p') {
			event.preventDefault();
			this.#setPaused(mode === 'playing');
		} else if (key === 'F2') {
			event.preventDefault();
			this.#newGame();
		} else if ((key === ' ' || key === 'Enter') && !event.repeat) {
			event.preventDefault();

			if (mode === 'ready' || mode === 'over' || mode === 'paused') {
				this.#moveMouse(0, 0);
			}
		}
	}
}
