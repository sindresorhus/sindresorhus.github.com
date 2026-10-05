// Sindre’s Wurms ’99 on the 1999 page, a game like Worms Armageddon (Team17, 1999): Team Sindre against Team Trond on a random island in the rain of Bergen, made of soil, a giant waffle, brown cheese, the houses of Bryggen, a waffle iron, and Rocky the pet rock, kept pixel by pixel, so explosions cut round holes in it. The worms take turns to walk, jump, aim, and fire nine weapons and tools against the wind, and Team Trond is the computer or a friend on the same keyboard. The game only runs while it is on screen and the tab is visible. Nothing makes a sound until the visitor turns on the sound. For visitors who prefer reduced motion, the rain and the sea stand still, and every shot and every turn of the computer happens at once, with its path drawn as dots.

const randomItem = items => items[Math.floor(Math.random() * items.length)];
const randomBetween = (minimum, maximum) => minimum + (Math.random() * (maximum - minimum));
const clamp = (value, minimum, maximum) => Math.min(Math.max(value, minimum), maximum);

// Shows a toggle button as pressed, for screen readers and for the style.
const setPressed = (button, isPressed) => {
	button.setAttribute('aria-pressed', String(isPressed));
	button.dataset.state = isPressed ? 'on' : '';
};

// The position of a pointer on a canvas, in the pixels of the canvas.
const canvasPoint = (canvas, event) => {
	const rectangle = canvas.getBoundingClientRect();
	return {
		x: (event.clientX - rectangle.left - canvas.clientLeft) * canvas.width / canvas.clientWidth,
		y: (event.clientY - rectangle.top - canvas.clientTop) * canvas.height / canvas.clientHeight,
	};
};

// MARK: The pixel font

// A tiny pixel font of 3 × 5, like the labels of Worms, so the text is crisp at any size. Each letter is five rows of three bits.
const pixelFont = {
	A: [2, 5, 7, 5, 5], B: [6, 5, 6, 5, 6], C: [3, 4, 4, 4, 3], D: [6, 5, 5, 5, 6], E: [7, 4, 6, 4, 7], F: [7, 4, 6, 4, 4], G: [3, 4, 5, 5, 3], H: [5, 5, 7, 5, 5], I: [7, 2, 2, 2, 7], J: [1, 1, 1, 5, 2], K: [5, 5, 6, 5, 5], L: [4, 4, 4, 4, 7], M: [5, 7, 7, 5, 5], N: [6, 5, 5, 5, 5], O: [2, 5, 5, 5, 2], P: [6, 5, 6, 4, 4], Q: [2, 5, 5, 6, 3], R: [6, 5, 6, 5, 5], S: [3, 4, 2, 1, 6], T: [7, 2, 2, 2, 2], U: [5, 5, 5, 5, 7], V: [5, 5, 5, 5, 2], W: [5, 5, 7, 7, 5], X: [5, 5, 2, 5, 5], Y: [5, 5, 2, 2, 2], Z: [7, 1, 2, 4, 7],
	0: [7, 5, 5, 5, 7], 1: [2, 6, 2, 2, 7], 2: [6, 1, 2, 4, 7], 3: [6, 1, 2, 1, 6], 4: [5, 5, 7, 1, 1], 5: [7, 4, 6, 1, 6], 6: [3, 4, 7, 5, 7], 7: [7, 1, 2, 2, 2], 8: [7, 5, 7, 5, 7], 9: [7, 5, 7, 1, 6],
	' ': [0, 0, 0, 0, 0], '.': [0, 0, 0, 0, 2], ',': [0, 0, 0, 2, 4], '!': [2, 2, 2, 0, 2], '?': [6, 1, 2, 0, 2], ':': [0, 2, 0, 2, 0], '-': [0, 0, 7, 0, 0], '+': [0, 2, 7, 2, 0], '/': [1, 1, 2, 4, 4], '\'': [2, 2, 0, 0, 0], '"': [5, 5, 0, 0, 0], '(': [1, 2, 2, 2, 1], ')': [4, 2, 2, 2, 4], '°': [2, 5, 2, 0, 0], '%': [5, 1, 2, 4, 5], '<': [1, 2, 4, 2, 1], '>': [4, 2, 1, 2, 4], '=': [0, 7, 0, 7, 0], '♥': [0, 5, 7, 7, 2], '*': [0, 5, 2, 5, 0],
	Æ: [3, 6, 7, 6, 7], Ø: [3, 5, 7, 5, 6], Å: [2, 0, 2, 5, 7],
};

// The font has capitals only, and plain quotes, so the text of the game is turned into what it has.
const pixelText = text => String(text).replaceAll('’', '\'').replaceAll('‘', '\'').replaceAll('“', '"').replaceAll('”', '"').replaceAll('…', '...').toUpperCase();

const textWidth = (text, scale = 1) => Math.max(0, (([...pixelText(text)].length * 4) - 1) * scale);

// MARK: The rules

const worldWidth = 960;
const worldHeight = 420;
const step = 1 / 60;
const gravity = 300;
const windForce = 110;
const wormRadius = 4;
const walkSpeed = 36;
const turnSeconds = 45;
const retreatSeconds = 3;
const suddenDeathRound = 6;
const startingWater = 388;

const teams = [
	{id: 'sindre', name: 'Team Sindre', color: '#6ab0ff', dark: '#1d3d8f', names: ['Sindre', 'Rocky', 'Glitter', 'Lillesøster']},
	{id: 'trond', name: 'Team Trond', color: '#ff6a6a', dark: '#8f1d1d', names: ['Trond', 'Kjetil', 'Bjørnar', 'Trond Jr.']},
];

const weapons = {
	bazooka: {name: 'Bazooka', ammo: Number.POSITIVE_INFINITY, isAimed: true, isCharged: true},
	grenade: {name: 'Grenade', ammo: Number.POSITIVE_INFINITY, isAimed: true, isCharged: true, hasFuse: true},
	shotgun: {name: 'Shotgun', ammo: Number.POSITIVE_INFINITY, isAimed: true},
	banana: {name: 'Banana Bomb', ammo: 1, isAimed: true, isCharged: true, hasFuse: true},
	sheep: {name: 'Sheep', ammo: 2},
	airstrike: {name: 'Air Strike', ammo: 1, isTargeted: true},
	holy: {name: 'Holy Hand Grenade', ammo: 1, isAimed: true, isCharged: true},
	girder: {name: 'Girder', ammo: 3, isTargeted: true},
	teleport: {name: 'Teleport', ammo: 2, isTargeted: true},
};

const weaponIds = Object.keys(weapons);
const girderAngles = [0, 45, 90, 135];

// What the worms say, in English and in Norwegian, like the speech banks of Worms.
const lines = {
	start: ['Min tur!', 'Watch this!', 'Here we go!', 'Vaffeltid!', 'Coming through!', 'Hold my brunost'],
	fire: ['Fire!', 'Ta den!', 'Incoming!', 'Eat this!'],
	hit: ['Oi, nutter!', 'Uff da!', 'Au!', 'Fy søren!', 'Mamma!', 'Ikke i fjeset!', 'Ouch!', 'Hey!', 'My waffle!', 'Typisk!', 'Not fair!'],
	bye: ['Bye bye', 'Ha det bra!', 'Adjø!', 'Tell Mormor…', 'I’ll be back'],
	drown: ['Blub blub!', 'I can’t swim!', 'Kaldt vann!'],
	fall: ['Au, foten!', 'My knees!', 'Oof!'],
	oops: ['Oops!', 'The wind did it!', 'Det var meningen!'],
	think: ['Hmm…', 'La meg se…', 'Easy…'],
	win: ['Hurra!', 'Flawless!', 'Ha ha!', 'Seier!'],
	timeout: ['Zzz…', 'Huh? My turn?'],
};

const norwegianLines = new Set(['Min tur!', 'Vaffeltid!', 'Ta den!', 'Uff da!', 'Au!', 'Fy søren!', 'Mamma!', 'Ikke i fjeset!', 'Typisk!', 'Ha det bra!', 'Adjø!', 'Kaldt vann!', 'Au, foten!', 'Det var meningen!', 'La meg se…', 'Seier!', 'Bææææ!']);

const vary = ([red, green, blue], amount) => {
	const change = randomBetween(-amount, amount);
	return [red + change, green + change, blue + change];
};

const soilColor = (x, y, depth) => {
	if (depth < 2) {
		return vary([92, 170, 60], 14);
	}

	if (depth < 4) {
		return vary([58, 118, 42], 8);
	}

	const band = Math.sin((y * 0.21) + (Math.sin(x * 0.03) * 3)) * 10;
	return vary([118 + band, 78 + band, 44 + (band / 2)], 9);
};

// MARK: Bodies

// The points of a circle that a body checks against the land: its middle, its edge, and halfway out.
const circlePoints = new Map();

const pointsOfCircle = radius => {
	if (!circlePoints.has(radius)) {
		const points = [[0, 0]];
		for (let index = 0; index < 12; index++) {
			const angle = (index * Math.PI * 2) / 12;
			points.push([Math.cos(angle) * radius, Math.sin(angle) * radius], [Math.cos(angle) * radius * 0.5, Math.sin(angle) * radius * 0.5]);
		}

		circlePoints.set(radius, points);
	}

	return circlePoints.get(radius);
};

// The damage of an explosion to a worm: all of it in the middle, and less out to the edge of its reach.
const blastDamage = (worm, x, y, radius, damage) => {
	const reach = radius + 6;
	const distance = Math.hypot(worm.x - x, worm.y - y);
	return distance < reach ? Math.round(damage * (1 - (0.6 * distance / reach))) : 0;
};

// MARK: Weapons

// The direction of an aim, at an angle in degrees above the line that the worm faces.
const aimDirection = (angle, facing) => {
	const radians = (angle * Math.PI) / 180;
	return {x: Math.cos(radians) * facing, y: -Math.sin(radians)};
};

// A shot of a weapon from a worm, at an angle in degrees above the line it faces, with a power from 0 to 1. The computer uses the same shot to try its aim first.
const makeProjectile = (weaponId, worm, angle, facing, power, fuse) => {
	const {x: directionX, y: directionY} = aimDirection(angle, facing);
	const x = worm.x + (directionX * 8);
	const y = worm.y - 2 + (directionY * 8);
	const shot = {weaponId, x, y, age: 0, team: worm.team, owner: worm};

	if (weaponId === 'bazooka') {
		const speed = 80 + (power * 440);
		return {...shot, kind: 'shell', look: 'shell', vx: directionX * speed, vy: directionY * speed, hasWind: true, explosion: {radius: 24, damage: 48}};
	}

	const speed = 60 + (power * 360);
	const bouncer = {...shot, kind: 'bouncer', vx: directionX * speed, vy: directionY * speed, radius: 2, bounce: 0.5, friction: 0.88, isResting: false, fuse};

	if (weaponId === 'banana') {
		return {...bouncer, look: 'banana', bounce: 0.6, explosion: {radius: 26, damage: 50}, isCluster: true};
	}

	if (weaponId === 'holy') {
		return {...bouncer, look: 'holy', bounce: 0.25, friction: 0.7, fuse: 3, explosion: {radius: 58, damage: 100}};
	}

	return {...bouncer, look: 'grenade', explosion: {radius: 24, damage: 48}};
};

// MARK: Drawing

const makeSprite = (rows, palette) => {
	const sprite = document.createElement('canvas');
	sprite.width = rows[0].length;
	sprite.height = rows.length;
	const spriteContext = sprite.getContext('2d');
	for (const [y, row] of rows.entries()) {
		for (const [x, character] of [...row].entries()) {
			if (palette[character]) {
				spriteContext.fillStyle = palette[character];
				spriteContext.fillRect(x, y, 1, 1);
			}
		}
	}

	return sprite;
};

// A pink worm, facing right, with the cap of its team.
const wormRows = [
	'...CCCC...',
	'..CccccCCC',
	'..opppppo.',
	'..oppwkpo.',
	'..oppwkpo.',
	'..opppppo.',
	'...oppmpo.',
	'...opppo..',
	'..oplppo..',
	'.oplpppo..',
	'oplppppo..',
	'oooooooo..',
];

const wormSprites = teams.map(team => makeSprite(wormRows, {o: '#8a2a4a', p: '#ff96b4', l: '#ffc8d8', w: '#ffffff', k: '#000000', m: '#c0406a', c: team.color, C: team.dark}));

const gravestoneSprite = makeSprite([
	'..ooo..',
	'.oGhGo.',
	'oGGkGGo',
	'oGkkkGo',
	'oGGkGGo',
	'oGGkGGo',
	'oGGGGGo',
	'oGGGGGo',
	'ooooooo',
], {o: '#3c3c44', G: '#9a9aa6', h: '#d0d0da', k: '#60606c'});

const sheepSprite = makeSprite([
	'..wwwww...',
	'.wwwwwwwkk',
	'wwwwwwwkek',
	'wwwwwwwkkk',
	'.gwwwwwg..',
	'.k.k..k.k.',
	'.k.k..k.k.',
], {w: '#f4f4ee', g: '#c8c8c0', k: '#202020', e: '#ffffff'});

const grenadeSprite = makeSprite([
	'.kk.',
	'oggo',
	'gggg',
	'gggg',
	'.gg.',
], {k: '#999999', o: '#2e5020', g: '#3e6b2e'});

const bananaSprite = makeSprite([
	'y....k',
	'yy..yy',
	'.yyyy.',
], {y: '#ffe030', k: '#6b4a10'});

const holySprite = makeSprite([
	'..d..',
	'.ddd.',
	'..d..',
	'.ggg.',
	'ggwgg',
	'ggggg',
	'.ggg.',
], {d: '#b08010', g: '#ffd23c', w: '#ffffff'});

const planeSprite = makeSprite([
	'.....w......',
	'k...www.....',
	'kkwwwwwwwwk.',
	'.wwwwwwwwwwk',
	'.....ww.....',
], {w: '#d0d4dc', k: '#4060a0'});

const mountainHeight = (x, layer) => (layer === 0 ? 62 + (24 * Math.sin((x * 0.011) + 1)) + (12 * Math.sin((x * 0.027) + 2)) + (5 * Math.sin(x * 0.07)) : 40 + (18 * Math.sin((x * 0.017) + 4)) + (8 * Math.sin((x * 0.041) + 1)));

// A phone has no Space bar, so it shoots with the big red button.
const coarsePointer = matchMedia('(pointer: coarse)');
const howToShoot = () => (coarsePointer.matches ? 'TAP TO AIM, HOLD FIRE TO SHOOT' : 'CLICK TO AIM, HOLD SPACE TO FIRE');

const keyControls = {ArrowLeft: 'left', ArrowRight: 'right', ArrowUp: 'up', ArrowDown: 'down'};


export default class extends GeoCitiesElement {
	#context;
	#loop;
	#accumulator = 0;
	#viewWidth;
	#viewHeight;
	#skyGradient;
	#wins;

	// A drag on the island looks around, and a tap aims at a spot, or places the air strike, the girder, or the teleport there.
	#drag;

	#audio = {
		context: undefined,
		output: undefined,
		noise: undefined,
		isOn: false,
	};

	#sounds = {
		explosion: size => {
			this.#noise(0, 0.5 + (size * 0.5), {frequency: 600 + (size * 1500), sweep: 60, volume: Math.min(0.5, 0.2 + (size * 0.25))});
			this.#tone(90, 0, 0.45, {type: 'sine', volume: 0.25, slide: 30});
		},
		launch: () => {
			this.#noise(0, 0.35, {filter: 'bandpass', frequency: 300, sweep: 2000, quality: 2, volume: 0.25});
		},
		throw: () => {
			this.#noise(0, 0.15, {filter: 'bandpass', frequency: 900, sweep: 400, quality: 3, volume: 0.15});
		},
		bounce: () => this.#tone(260, 0, 0.05, {type: 'triangle', volume: 0.12}),
		shotgun: () => {
			this.#noise(0, 0.25, {filter: 'highpass', frequency: 800, sweep: 300, volume: 0.35});
			this.#tone(120, 0, 0.2, {type: 'sine', volume: 0.2, slide: 50});
			this.#tone(1200, 0.4, 0.03, {volume: 0.05});
			this.#tone(900, 0.5, 0.03, {volume: 0.05});
		},
		splash: () => {
			this.#noise(0, 0.6, {filter: 'bandpass', frequency: 2500, sweep: 400, quality: 1.5, volume: 0.25});
		},
		jump: () => this.#tone(300, 0, 0.12, {slide: 700, volume: 0.04}),
		turn: () => {
			this.#tone(880, 0, 0.12, {type: 'triangle', volume: 0.08});
			this.#tone(1320, 0.12, 0.2, {type: 'triangle', volume: 0.08});
		},
		tick: () => this.#tone(1500, 0, 0.04, {volume: 0.04}),
		place: () => {
			this.#tone(200, 0, 0.08, {type: 'square', volume: 0.08});
			this.#tone(150, 0.08, 0.12, {type: 'square', volume: 0.08});
		},
		teleport: () => this.#tone(400, 0, 0.4, {type: 'sine', slide: 2400, volume: 0.1}),
		ouch: () => this.#tone(700, 0, 0.18, {type: 'square', volume: 0.04, slide: 260}),
		victory: () => {
			for (const [index, frequency] of [523, 659, 784, 1047, 784, 1047].entries()) {
				this.#tone(frequency, index * 0.13, 0.25, {type: 'triangle', volume: 0.1});
			}
		},
	};

	// The land, pixel by pixel: whether each pixel is land, and its color.
	#solid = new Uint8Array(worldWidth * worldHeight);
	#terrainPixels = new ImageData(worldWidth, worldHeight);
	#terrainCanvas = Object.assign(document.createElement('canvas'), {width: worldWidth, height: worldHeight});
	#terrainContext = this.#terrainCanvas.getContext('2d');
	#isTerrainChanged = true;

	// The surface of the island, which the props and the worms stand on.
	#surface = new Float32Array(worldWidth);

	#game = {
		phase: 'aim',
		isStarted: false,
		worms: [],
		objects: [],
		particles: [],
		texts: [],
		effects: [],
		gravestones: [],
		trails: [],
		teamIndex: 0,
		lastWorm: [-1, -1],
		active: undefined,
		wind: 0,
		waterLevel: startingWater,
		round: 1,
		isSuddenDeath: false,
		ammo: [{}, {}],
		weaponOf: ['bazooka', 'bazooka'],
		fuse: 3,
		girderAngle: 0,
		marker: {x: 0, y: 0},
		turn: {},
		settle: {},
		banner: undefined,
		time: 0,
	};

	#camera = {x: 0, y: 0, isManual: false, shake: 0};
	#held = {left: false, right: false, up: false, down: false};
	#rain = Array.from({length: 70}, () => ({x: Math.random() * 400, y: Math.random() * 300, speed: randomBetween(140, 200)}));
	#clouds = Array.from({length: 7}, (unused, index) => ({x: (index * 150) + randomBetween(0, 80), y: randomBetween(8, 50), width: randomBetween(40, 80)}));

	// The game only runs while the island is on screen, not while only its buttons are.
	get visibilityTarget() {
		return this.parts.screen;
	}

	connected() {
		const {screen, newGame: newGameButton, opponent: opponentSelect, count: countSelect, sound: soundButton, skip: skipButton, fire: fireButton} = this.parts;
		this.#context = screen.getContext('2d');
		this.#viewWidth = screen.width;
		this.#viewHeight = screen.height;
		const storedWins = this.stored('wins', {});
		this.#wins = {sindre: Number(storedWins.sindre) || 0, trond: Number(storedWins.trond) || 0};

		this.on(soundButton, 'click', () => {
			this.#audio.isOn = !this.#audio.isOn && this.#startSound();
			soundButton.setAttribute('aria-pressed', String(this.#audio.isOn));
			soundButton.textContent = this.#audio.isOn ? '🔊 Sound' : '🔈 Sound';

			if (this.#audio.isOn) {
				this.#audio.context.resume().then(() => {
					this.#sounds.turn();
				});
			} else if ('speechSynthesis' in globalThis) {
				speechSynthesis.cancel();
			}
		});

		this.on(screen, 'keydown', event => {
			if (event.metaKey || event.ctrlKey || event.altKey) {
				return;
			}

			const control = keyControls[event.key];
			if (control) {
				event.preventDefault();
				this.#start();
				if (this.#isHumanTurn()) {
					this.#held[control] = true;
				}

				this.#afterInput();
			} else if (event.key === ' ') {
				event.preventDefault();
				if (!event.repeat) {
					this.#pressFire();
				}
			} else if (event.key === 'Enter' || event.key === 'Backspace') {
				event.preventDefault();
				if (!event.repeat) {
					this.#jump(event.key === 'Backspace');
				}
			} else if (/^[1-5]$/v.test(event.key)) {
				this.#setFuse(Number(event.key));
			} else if (event.key === 'w' || event.key === 'W') {
				const index = weaponIds.indexOf(this.#currentWeapon());
				this.#pickWeapon(weaponIds[(index + (event.shiftKey ? weaponIds.length - 1 : 1)) % weaponIds.length]);
			}
		});

		this.on(screen, 'keyup', event => {
			const control = keyControls[event.key];
			if (control) {
				this.#held[control] = false;
				this.#afterInput();
			} else if (event.key === ' ') {
				this.#releaseFire();
			}
		});

		this.on(screen, 'blur', () => {
			this.#letGo();
		});

		this.on(screen, 'pointerdown', event => {
			screen.setPointerCapture(event.pointerId);
			this.#drag = {startX: event.clientX, startY: event.clientY, x: event.clientX, y: event.clientY, isPanning: false};
		});

		this.on(screen, 'pointermove', event => {
			if (!this.#drag) {
				return;
			}

			if (!this.#drag.isPanning && Math.hypot(event.clientX - this.#drag.startX, event.clientY - this.#drag.startY) > 8) {
				this.#drag.isPanning = true;
				this.#camera.isManual = true;
			}

			if (this.#drag.isPanning) {
				const scale = screen.width / screen.clientWidth;
				this.#camera.x -= (event.clientX - this.#drag.x) * scale;
				this.#camera.y -= (event.clientY - this.#drag.y) * scale;
				this.#clampCamera();
				if (this.reducedMotion || !this.isVisible) {
					this.#draw(0);
				}
			}

			this.#drag.x = event.clientX;
			this.#drag.y = event.clientY;
		});

		for (const type of ['pointerup', 'pointercancel']) {
			this.on(screen, type, event => {
				this.#endDrag(event);
			});
		}

		// The buttons for a thumb: walking and aiming last while they are held, and a press with the keyboard moves a little.
		for (const button of this.querySelectorAll('[data-worms-control]')) {
			const control = button.dataset.wormsControl;

			if (control === 'jump' || control === 'backflip') {
				this.on(button, 'click', () => {
					this.#jump(control === 'backflip');
				});
				continue;
			}

			this.on(button, 'pointerdown', event => {
				// The focus stays on the island, so the keys keep working next to the buttons.
				event.preventDefault();
				button.setPointerCapture(event.pointerId);
				this.#start();
				if (this.#isHumanTurn()) {
					this.#held[control] = true;
				}

				this.#afterInput();
			});

			const release = () => {
				if (this.#held[control]) {
					this.#held[control] = false;
					this.#afterInput();
				}
			};

			this.on(button, 'pointerup', release);
			this.on(button, 'pointercancel', release);
			this.on(button, 'lostpointercapture', release);

			this.on(button, 'click', event => {
				if (event.detail !== 0) {
					return;
				}

				this.#start();
				if (!this.#canControl()) {
					return;
				}

				this.#held[control] = true;
				for (let count = 0; count < 15; count++) {
					this.#simulate(step);
				}

				this.#held[control] = false;
				this.#afterInput();
				if (this.reducedMotion || !this.isVisible) {
					this.#draw(0);
				}
			});
		}

		// The fire button charges while it is held, with a finger, a mouse, or the keyboard.
		this.on(fireButton, 'pointerdown', event => {
			event.preventDefault();
			fireButton.setPointerCapture(event.pointerId);
			this.#pressFire();
		});

		for (const type of ['pointerup', 'pointercancel']) {
			this.on(fireButton, type, () => {
				this.#releaseFire();
			});
		}

		// A screen reader or a switch activates the button with a click only, so it fires at once, at three quarters of the power.
		this.on(fireButton, 'click', event => {
			if (event.detail !== 0) {
				return;
			}

			this.#pressFire();
			if (this.#game.turn.charge !== undefined) {
				this.#game.turn.charge = 0.75;
			}

			this.#releaseFire();
		});

		this.on(fireButton, 'keydown', event => {
			if (event.key === ' ' || event.key === 'Enter') {
				event.preventDefault();
				if (!event.repeat) {
					this.#pressFire();
				}
			}
		});

		this.on(fireButton, 'keyup', event => {
			if (event.key === ' ' || event.key === 'Enter') {
				event.preventDefault();
				this.#releaseFire();
			}
		});

		this.on(fireButton, 'blur', () => {
			this.#letGo();
		});

		for (const button of this.querySelectorAll('[data-worms-weapon]')) {
			this.on(button, 'click', event => {
				this.#pickWeapon(button.dataset.wormsWeapon);

				// With a mouse, the keys go back to the island, so the arrow keys aim right away.
				if (event.detail > 0 && matchMedia('(pointer: fine)').matches) {
					screen.focus({preventScroll: true});
				}
			});
		}

		for (const button of this.querySelectorAll('[data-worms-fuse]')) {
			this.on(button, 'click', () => {
				this.#setFuse(Number(button.dataset.wormsFuse));
			});
		}

		this.on(skipButton, 'click', () => {
			this.#skipTurn();
		});

		this.on(newGameButton, 'click', () => {
			this.#newGame();
			this.#game.isStarted = true;
			this.say(`A new island! ${this.#turnAnnouncement()}`);
			this.#afterInput();
			this.#draw(0);
		});

		this.on(opponentSelect, 'change', () => {
			this.store('opponent', opponentSelect.value);
			this.say(opponentSelect.value === 'friend' ? 'Team Trond is now played by a friend on the same keyboard. Take turns!' : 'Team Trond is now played by the computer.');
			this.#afterInput();
		});

		this.on(countSelect, 'change', () => {
			this.store('count', countSelect.value);
			this.say(`${countSelect.value} worms on each team from the next game. Press New Game.`);
		});

		// The names of the worms of Team Sindre, kept in the browser, and changed at once on the island.
		const savedNames = this.stored('names', []);
		for (const field of this.querySelectorAll('[data-worms-name]')) {
			const index = Number(field.dataset.wormsName);
			field.value = typeof savedNames[index] === 'string' ? savedNames[index].slice(0, 12) : '';
			this.on(field, 'input', () => {
				const names = this.stored('names', []);
				names[index] = field.value;
				this.store('names', names);
				const worm = this.#game.worms.filter(item => item.team === 0)[index];
				if (worm) {
					worm.name = this.#wormName(0, index);
					this.#draw(0);
				}
			});
		}

		for (const button of this.querySelectorAll('[data-worms-fuse]')) {
			setPressed(button, Number(button.dataset.wormsFuse) === this.#game.fuse);
		}

		opponentSelect.value = this.stored('opponent', 'computer') === 'friend' ? 'friend' : 'computer';
		const savedCount = this.stored('count', '3');
		if (['2', '3', '4'].includes(savedCount)) {
			countSelect.value = savedCount;
		}

		this.#loop = this.loop(seconds => {
			this.#accumulator = Math.min(this.#accumulator + seconds, 0.1);
			while (this.#accumulator >= step) {
				this.#simulate(step);
				this.#accumulator -= step;
			}

			this.#draw(seconds);
		}, {while: () => !this.reducedMotion || this.#isHolding()});

		this.#newGame();

		this.observe(new ResizeObserver(() => {
			this.#resize();
		})).observe(screen);

		this.#resize();

		if (this.reducedMotion) {
			this.#resolveNow();
		}
	}

	reducedMotionChanged() {
		this.#afterInput();
	}

	// MARK: The pixel font

	// Draws text in the pixel font, at a whole pixel. The alignment is `left`, `center`, or `right`.
	#drawText(text, x, y, color, {scale = 1, align = 'left', shadow} = {}) {
		const characters = [...pixelText(text)];
		const width = textWidth(text, scale);
		const start = Math.round(align === 'center' ? x - (width / 2) : (align === 'right' ? x - width : x));

		for (const [ink, offset] of shadow ? [[shadow, scale], [color, 0]] : [[color, 0]]) {
			let left = start + offset;
			this.#context.fillStyle = ink;

			for (const character of characters) {
				const rows = pixelFont[character] ?? pixelFont['?'];
				for (const [row, bits] of rows.entries()) {
					for (let column = 0; column < 3; column++) {
						if (bits & (4 >> column)) {
							this.#context.fillRect(left + (column * scale), Math.round(y) + (row * scale) + offset, scale, scale);
						}
					}
				}

				left += 4 * scale;
			}
		}
	}

	// A label in a black box, like the names and health of the worms of Worms.
	#drawLabel(text, x, y, color) {
		const width = textWidth(text);
		const left = Math.round(x - (width / 2)) - 1;
		this.#context.fillStyle = 'rgb(0 0 0 / 0.75)';
		this.#context.fillRect(left, Math.round(y) - 1, width + 2, 7);
		this.#drawText(text, left + 1, y, color);
	}

	// MARK: The sound

	#startSound() {
		const sound = this.sound();
		if (!sound) {
			return false;
		}

		const audio = this.#audio;
		if (!audio.output) {
			audio.context = sound.context;
			audio.output = new GainNode(audio.context, {gain: 0.5});
			audio.output.connect(sound.output);
			audio.noise = new AudioBuffer({length: audio.context.sampleRate, sampleRate: audio.context.sampleRate});
			const samples = audio.noise.getChannelData(0);
			for (let index = 0; index < samples.length; index++) {
				samples[index] = (Math.random() * 2) - 1;
			}
		}

		audio.context.resume();
		return true;
	}

	#canPlay() {
		return this.#audio.isOn && this.#audio.context?.state === 'running';
	}

	#tone(frequency, start, duration, {type = 'square', volume = 0.06, slide, destination} = {}) {
		if (!this.#canPlay()) {
			return;
		}

		const time = this.#audio.context.currentTime + start;
		const oscillator = new OscillatorNode(this.#audio.context, {type, frequency});
		const gain = new GainNode(this.#audio.context, {gain: 0});

		if (slide) {
			oscillator.frequency.exponentialRampToValueAtTime(slide, time + duration);
		}

		gain.gain.setValueAtTime(0.0001, time);
		gain.gain.exponentialRampToValueAtTime(volume, time + 0.01);
		gain.gain.exponentialRampToValueAtTime(0.0001, time + duration);
		oscillator.connect(gain).connect(destination ?? this.#audio.output);
		oscillator.start(time);
		oscillator.stop(time + duration + 0.05);
	}

	// A burst of noise through a filter that sweeps, for explosions, whooshes, and splashes.
	#noise(start, duration, {filter = 'lowpass', frequency = 1000, sweep = frequency, quality = 1, volume = 0.3} = {}) {
		if (!this.#canPlay()) {
			return;
		}

		const time = this.#audio.context.currentTime + start;
		const source = new AudioBufferSourceNode(this.#audio.context, {buffer: this.#audio.noise, loop: true});
		const filterNode = new BiquadFilterNode(this.#audio.context, {type: filter, frequency, Q: quality});
		const gain = new GainNode(this.#audio.context, {gain: 0});
		filterNode.frequency.setValueAtTime(frequency, time);
		filterNode.frequency.exponentialRampToValueAtTime(sweep, time + duration);
		gain.gain.setValueAtTime(0.0001, time);
		gain.gain.exponentialRampToValueAtTime(volume, time + 0.01);
		gain.gain.exponentialRampToValueAtTime(0.0001, time + duration);
		source.connect(filterNode).connect(gain).connect(this.#audio.output);
		source.start(time, Math.random() * 0.5);
		source.stop(time + duration + 0.05);
	}

	// The choir of the Holy Hand Grenade: four syllables, “Hal-le-lu-jah!”, each a chord of buzzing voices through the formants of its vowel.
	#singHallelujah() {
		if (!this.#canPlay()) {
			return;
		}

		const vowels = {
			a: [[800, 1], [1150, 0.5], [2900, 0.15]],
			e: [[450, 1], [1900, 0.4], [2600, 0.15]],
			u: [[350, 1], [700, 0.4], [2400, 0.1]],
		};
		const major = [146.83, 293.66, 369.99, 440, 587.33];
		const fourth = [146.83, 293.66, 392, 493.88, 587.33];
		const syllables = [
			{start: 0, duration: 0.3, chord: major, vowel: 'a'},
			{start: 0.32, duration: 0.22, chord: major, vowel: 'e'},
			{start: 0.56, duration: 0.45, chord: fourth, vowel: 'u'},
			{start: 1.03, duration: 1.4, chord: [...major, 739.99], vowel: 'a'},
		];

		for (const syllable of syllables) {
			const time = this.#audio.context.currentTime + syllable.start;
			const voices = new GainNode(this.#audio.context, {gain: 0});
			voices.gain.setValueAtTime(0.0001, time);
			voices.gain.exponentialRampToValueAtTime(0.05, time + 0.06);
			voices.gain.setValueAtTime(0.05, time + syllable.duration - 0.08);
			voices.gain.exponentialRampToValueAtTime(0.0001, time + syllable.duration + 0.12);

			for (const [frequency, level] of vowels[syllable.vowel]) {
				const formant = new BiquadFilterNode(this.#audio.context, {type: 'bandpass', frequency, Q: 7});
				const formantGain = new GainNode(this.#audio.context, {gain: level * 3});
				voices.connect(formant).connect(formantGain).connect(this.#audio.output);
			}

			for (const frequency of syllable.chord) {
				for (const detune of [-8, 7]) {
					const oscillator = new OscillatorNode(this.#audio.context, {type: 'sawtooth', frequency, detune});
					const vibrato = new OscillatorNode(this.#audio.context, {frequency: 5.5});
					const vibratoDepth = new GainNode(this.#audio.context, {gain: frequency * 0.006});
					vibrato.connect(vibratoDepth).connect(oscillator.frequency);
					oscillator.connect(voices);
					oscillator.start(time);
					vibrato.start(time);
					oscillator.stop(time + syllable.duration + 0.2);
					vibrato.stop(time + syllable.duration + 0.2);
				}
			}
		}
	}

	// The bleat of the sheep: a buzz that shakes, through a filter, like “Bææææ”.
	#bleat() {
		if (!this.#canPlay()) {
			return;
		}

		const time = this.#audio.context.currentTime;
		const oscillator = new OscillatorNode(this.#audio.context, {type: 'sawtooth', frequency: 330});
		const filter = new BiquadFilterNode(this.#audio.context, {type: 'bandpass', frequency: 1200, Q: 2});
		const gain = new GainNode(this.#audio.context, {gain: 0});
		const tremolo = new OscillatorNode(this.#audio.context, {frequency: 17});
		const tremoloDepth = new GainNode(this.#audio.context, {gain: 0.04});
		oscillator.frequency.exponentialRampToValueAtTime(280, time + 0.7);
		gain.gain.setValueAtTime(0.0001, time);
		gain.gain.exponentialRampToValueAtTime(0.08, time + 0.05);
		gain.gain.setValueAtTime(0.08, time + 0.55);
		gain.gain.exponentialRampToValueAtTime(0.0001, time + 0.75);
		tremolo.connect(tremoloDepth).connect(gain.gain);
		oscillator.connect(filter).connect(gain).connect(this.#audio.output);
		oscillator.start(time);
		tremolo.start(time);
		oscillator.stop(time + 0.8);
		tremolo.stop(time + 0.8);
	}

	// The worms say their lines with the speech of the computer, in a high and fast voice, and in Norwegian when the line is Norwegian.
	#speak(text) {
		if (!this.#canPlay() || !('speechSynthesis' in globalThis)) {
			return;
		}

		speechSynthesis.cancel();
		const utterance = new SpeechSynthesisUtterance(text.replaceAll('…', ''));
		utterance.lang = norwegianLines.has(text) ? 'nb-NO' : 'en-GB';
		utterance.pitch = 1.9;
		utterance.rate = 1.25;
		utterance.volume = 0.8;
		speechSynthesis.speak(utterance);
	}

	// MARK: The land

	#isSolid(x, y) {
		const column = Math.floor(x);
		const row = Math.floor(y);
		if (column < 0 || column >= worldWidth || row < 0 || row >= worldHeight) {
			return false;
		}

		return this.#solid[(row * worldWidth) + column] !== 0;
	}

	#paint(x, y, [red, green, blue]) {
		if (x < 0 || x >= worldWidth || y < 0 || y >= worldHeight) {
			return;
		}

		const index = (y * worldWidth) + x;
		this.#solid[index] = 1;
		this.#terrainPixels.data.set([clamp(Math.round(red), 0, 255), clamp(Math.round(green), 0, 255), clamp(Math.round(blue), 0, 255), 255], index * 4);
	}

	#erase(x, y) {
		const index = (y * worldWidth) + x;
		this.#solid[index] = 0;
		this.#terrainPixels.data[(index * 4) + 3] = 0;
	}

	// The edge of a hole is burnt dark, like the craters of Worms.
	#scorch(x, y, amount) {
		const index = (y * worldWidth) + x;
		if (this.#solid[index] === 0) {
			return;
		}

		for (let channel = 0; channel < 3; channel++) {
			this.#terrainPixels.data[(index * 4) + channel] = Math.max(20, this.#terrainPixels.data[(index * 4) + channel] * amount);
		}
	}

	// Takes away the land in a circle, and burns its edge.
	#carve(centerX, centerY, radius) {
		const reach = radius + 3;
		for (let y = Math.max(0, Math.floor(centerY - reach)); y <= Math.min(worldHeight - 1, Math.ceil(centerY + reach)); y++) {
			for (let x = Math.max(0, Math.floor(centerX - reach)); x <= Math.min(worldWidth - 1, Math.ceil(centerX + reach)); x++) {
				const distance = Math.hypot(x - centerX, y - centerY);
				if (distance < radius) {
					this.#erase(x, y);
				} else if (distance < reach) {
					this.#scorch(x, y, 0.55);
				}
			}
		}

		this.#isTerrainChanged = true;
	}

	// A Norwegian waffle, five hearts in a ring, with the squares of the waffle iron on it.
	#stampWaffle(centerX, baseY) {
		const radius = 13;
		const centerY = baseY - 14;
		for (let y = centerY - 30; y <= centerY + 30; y++) {
			for (let x = centerX - 30; x <= centerX + 30; x++) {
				const deltaX = x - centerX;
				const deltaY = y - centerY;
				let isInside = Math.hypot(deltaX, deltaY) < 8;

				for (let heart = 0; heart < 5 && !isInside; heart++) {
					const angle = ((heart * Math.PI * 2) / 5) - (Math.PI / 2);
					const outX = Math.cos(angle);
					const outY = Math.sin(angle);
					const localX = deltaX - (outX * 12);
					const localY = deltaY - (outY * 12);
					// The heart curve, (u² + v² − 1)³ − u²v³ ≤ 0, with its point to the middle of the waffle.
					const u = ((localX * -outY) + (localY * outX)) / radius;
					const v = ((localX * outX) + (localY * outY)) / radius;
					isInside = (((u * u) + (v * v) - 1) ** 3) - (u * u * (v ** 3)) <= 0;
				}

				if (isInside) {
					const isGroove = (x + y) % 5 === 0 || (x - y + 1000) % 5 === 0;
					this.#paint(x, y, vary(isGroove ? [170, 104, 36] : [226, 168, 74], 6));
				}
			}
		}
	}

	// A block of brown cheese in its red wrapper, cut flat on top, with a cheese slicer in it and a curl of cheese next to it.
	#stampBrownCheese(centerX, baseY) {
		const left = centerX - 16;
		const top = baseY - 22;
		for (let y = top; y < baseY + 8; y++) {
			for (let x = left; x < left + 32; x++) {
				const isSide = x >= left + 28;
				const isWrapper = y >= baseY - 9;
				const isLabel = isWrapper && y === baseY - 5 && x > left + 4 && x < left + 26 && x % 3 !== 0;
				let color = isSide ? [150, 84, 36] : [196, 118, 54];
				if (y < top + 3) {
					color = isSide ? [190, 120, 66] : [230, 156, 88];
				} else if (isLabel) {
					color = [250, 240, 220];
				} else if (isWrapper) {
					color = isSide ? [150, 20, 30] : [204, 34, 44];
				}

				this.#paint(x, y, vary(color, 4));
			}
		}

		// The blade of the slicer lies on the cheese, and its wooden handle points up and to the side.
		for (let x = left + 4; x < left + 16; x++) {
			this.#paint(x, top - 1, [206, 210, 220]);
			this.#paint(x, top - 2, [170, 176, 188]);
		}

		for (let index = 0; index < 9; index++) {
			this.#paint(left + 16 + index, top - 2 - index, [150, 98, 50]);
			this.#paint(left + 17 + index, top - 2 - index, [120, 76, 40]);
		}

		for (const [x, y] of [[20, -1], [21, -1], [22, -1], [23, -1], [24, -2], [25, -2], [25, -3], [24, -4], [23, -4]]) {
			this.#paint(left + x, top + y, [236, 166, 98]);
		}
	}

	// Three wooden houses of Bryggen in a row, red, yellow, and white, with their gables to the sea.
	#stampBryggen(centerX, baseY) {
		const colors = [[168, 50, 40], [222, 168, 46], [232, 226, 208], [196, 112, 48]];
		const first = Math.floor(Math.random() * colors.length);
		for (let house = 0; house < 3; house++) {
			const left = centerX - 24 + (house * 16);
			const color = colors[(first + house) % colors.length];
			const bodyTop = baseY - 22;

			for (let x = left; x < left + 16; x++) {
				// The gable: a triangle on top of the wall.
				const roofTop = bodyTop - 8 + Math.abs(x - (left + 7.5));
				for (let y = Math.round(roofTop); y < baseY; y++) {
					const isRoofEdge = y < roofTop + 1.5;
					const isPlank = (x - left) % 3 === 0;
					const isWindow = y > bodyTop + 3 && y < baseY - 4 && ((x - left) % 8 === 2 || (x - left) % 8 === 3 || (x - left) % 8 === 4) && ((y - bodyTop) % 8 === 4 || (y - bodyTop) % 8 === 5 || (y - bodyTop) % 8 === 6);
					if (isRoofEdge) {
						this.#paint(x, y, [70, 40, 30]);
					} else if (isWindow) {
						this.#paint(x, y, (y - bodyTop) % 8 === 4 ? [250, 250, 240] : [44, 52, 72]);
					} else {
						this.#paint(x, y, vary(isPlank ? color.map(value => value * 0.8) : color, 4));
					}
				}

				// Stones under the house, down to the ground.
				for (let y = baseY; y < baseY + 30 && !this.#isSolid(x, y); y++) {
					this.#paint(x, y, vary([120, 120, 126], 12));
				}
			}
		}
	}

	// Rocky the pet rock, giant, with his googly eyes.
	#stampRocky(centerX, baseY) {
		const centerY = baseY - 9;
		for (let y = centerY - 14; y <= centerY + 16; y++) {
			for (let x = centerX - 19; x <= centerX + 19; x++) {
				if ((((x - centerX) / 19) ** 2) + (((y - centerY) / 14) ** 2) <= 1 || (y > centerY && Math.abs(x - centerX) < 16)) {
					this.#paint(x, y, vary([132, 132, 138], Math.random() < 0.1 ? 26 : 8));
				}
			}
		}

		for (const eyeX of [centerX - 6, centerX + 6]) {
			for (let y = -4; y <= 4; y++) {
				for (let x = -4; x <= 4; x++) {
					const distance = Math.hypot(x, y);
					if (distance <= 4) {
						this.#paint(eyeX + x, centerY - 4 + y, distance > 3.3 ? [40, 40, 40] : [250, 250, 250]);
					}
				}
			}

			for (const [x, y] of [[1, 0], [2, 0], [1, 1], [2, 1]]) {
				this.#paint(eyeX + x, centerY - 4 + y, [10, 10, 10]);
			}
		}
	}

	// A closed waffle iron, with its handle and its red light that says it is hot.
	#stampWaffleIron(centerX, baseY) {
		const left = centerX - 17;
		for (let y = baseY - 14; y < baseY + 6; y++) {
			for (let x = left; x < left + 34; x++) {
				const isSeam = y === baseY - 6;
				const isCorner = (y === baseY - 14 && (x === left || x === left + 33));
				if (!isCorner) {
					this.#paint(x, y, vary(isSeam ? [20, 20, 22] : (y < baseY - 11 ? [96, 96, 104] : [64, 64, 70]), 4));
				}
			}
		}

		for (let x = left + 34; x < left + 44; x++) {
			this.#paint(x, baseY - 9, [24, 24, 24]);
			this.#paint(x, baseY - 8, [24, 24, 24]);
		}

		// A waffle squeezes out of the iron, golden at the seam.
		for (let x = left + 3; x < left + 31; x++) {
			this.#paint(x, baseY - 6, (x % 4) < 2 ? [226, 168, 74] : [196, 134, 52]);
			if (x % 6 === 0) {
				this.#paint(x, baseY - 5, [226, 168, 74]);
			}
		}

		this.#paint(left + 4, baseY - 2, [255, 40, 40]);
		this.#paint(left + 5, baseY - 2, [255, 40, 40]);
	}

	#generateIsland() {
		this.#solid.fill(0);
		this.#terrainPixels.data.fill(0);
		this.#surface = new Float32Array(worldWidth);
		const level = randomBetween(240, 272);
		const waves = [[42, 560], [26, 230], [11, 95], [4, 38]].map(([amplitude, length]) => ({amplitude, frequency: (Math.PI * 2) / length, phase: Math.random() * Math.PI * 2}));

		for (let x = 0; x < worldWidth; x++) {
			let y = level;
			for (const wave of waves) {
				y += wave.amplitude * Math.sin((x * wave.frequency) + wave.phase);
			}

			// The island slopes down into the sea at both ends.
			const edge = Math.min(x, worldWidth - 1 - x);
			if (edge < 130) {
				y += ((130 - edge) ** 2) / 55;
			}

			this.#surface[x] = y;
			const top = Math.max(0, Math.ceil(y));
			for (let row = top; row < worldHeight; row++) {
				this.#paint(x, row, soilColor(x, row, row - top));
			}
		}

		// Stones in the soil.
		for (let index = 0; index < 70; index++) {
			const x = Math.floor(randomBetween(0, worldWidth));
			const y = Math.floor(randomBetween(this.#surface[x] + 8, worldHeight));
			const radius = randomBetween(1, 3.5);
			const color = vary([128, 124, 120], 14);
			for (let deltaY = -4; deltaY <= 4; deltaY++) {
				for (let deltaX = -4; deltaX <= 4; deltaX++) {
					if (Math.hypot(deltaX, deltaY) <= radius && this.#isSolid(x + deltaX, y + deltaY) && y + deltaY > this.#surface[clamp(x + deltaX, 0, worldWidth - 1)] + 5) {
						this.#paint(x + deltaX, y + deltaY, vary(color, 6));
					}
				}
			}
		}

		// Caves, with dark edges.
		const caves = Math.floor(randomBetween(2, 4));
		for (let index = 0; index < caves; index++) {
			const centerX = Math.floor(randomBetween(180, worldWidth - 180));
			const centerY = this.#surface[centerX] + randomBetween(38, 70);
			const radiusX = randomBetween(18, 34);
			const radiusY = randomBetween(9, 15);
			for (let y = Math.floor(centerY - radiusY - 3); y <= centerY + radiusY + 3; y++) {
				for (let x = Math.floor(centerX - radiusX - 3); x <= centerX + radiusX + 3; x++) {
					if (x < 0 || x >= worldWidth || y < 0 || y >= worldHeight) {
						continue;
					}

					const distance = Math.hypot((x - centerX) / radiusX, (y - centerY) / radiusY);
					if (distance < 1) {
						this.#erase(x, y);
					} else if (distance < 1.15) {
						this.#scorch(x, y, 0.7);
					}
				}
			}
		}

		// Sometimes a small island floats in the air, like in Worms.
		if (Math.random() < 0.7) {
			const centerX = Math.floor(randomBetween(240, worldWidth - 240));
			const length = Math.floor(randomBetween(34, 50));
			let highest = worldHeight;
			for (let x = centerX - length; x <= centerX + length; x++) {
				highest = Math.min(highest, this.#surface[x]);
			}

			const centerY = Math.max(50, highest - randomBetween(70, 100));
			for (let deltaX = -length; deltaX <= length; deltaX++) {
				const top = Math.round(centerY - 3 + (Math.sin(deltaX * 0.3) * 1.5));
				const bottom = Math.round(centerY + ((1 - ((deltaX / length) ** 2)) * 16));
				for (let y = top; y <= bottom; y++) {
					this.#paint(centerX + deltaX, y, soilColor(centerX + deltaX, y, y - top));
				}
			}
		}

		// The props of Bergen stand on the island.
		const props = [this.#stampWaffle, this.#stampBrownCheese, this.#stampBryggen, this.#stampRocky, this.#stampWaffleIron];
		const shuffled = props.toSorted(() => Math.random() - 0.5);
		for (const [index, fraction] of [0.2, 0.4, 0.6, 0.8].entries()) {
			const x = Math.round((fraction * worldWidth) + randomBetween(-40, 40));
			shuffled[index].call(this, x, Math.round(this.#surface[x]) + 3);
		}

		this.#isTerrainChanged = true;
	}

	// The point where the land starts, from the sky down, or undefined over the sea.
	#groundBelowSky(x) {
		for (let y = 0; y < worldHeight; y++) {
			if (this.#isSolid(x, y)) {
				return y;
			}
		}

		return undefined;
	}

	// A girder of steel, put into the land at an angle.
	#stampGirder(centerX, centerY, angle) {
		const radians = (angle * Math.PI) / 180;
		const alongX = Math.cos(radians);
		const alongY = Math.sin(radians);
		for (let along = -20; along <= 20; along += 0.5) {
			for (let across = -2.5; across <= 2.5; across += 0.5) {
				const x = Math.round(centerX + (alongX * along) - (alongY * across));
				const y = Math.round(centerY + (alongY * along) + (alongX * across));
				const isEdge = Math.abs(across) > 1.9;
				const isHole = !isEdge && Math.abs(across) < 1 && Math.round(along + 20) % 6 < 2;
				this.#paint(x, y, isEdge ? [78, 82, 96] : (isHole ? [70, 74, 88] : [150, 158, 176]));
			}
		}

		this.#isTerrainChanged = true;
	}

	// MARK: Bodies

	#circleHits(x, y, radius) {
		return pointsOfCircle(radius).some(([deltaX, deltaY]) => this.#isSolid(x + deltaX, y + deltaY));
	}

	// The direction away from the land around a point, to bounce off it.
	#surfaceNormal(x, y, radius) {
		let normalX = 0;
		let normalY = 0;
		const reach = Math.ceil(radius + 2);
		for (let deltaY = -reach; deltaY <= reach; deltaY++) {
			for (let deltaX = -reach; deltaX <= reach; deltaX++) {
				if ((deltaX * deltaX) + (deltaY * deltaY) <= reach * reach && this.#isSolid(x + deltaX, y + deltaY)) {
					normalX -= deltaX;
					normalY -= deltaY;
				}
			}
		}

		const length = Math.hypot(normalX, normalY);
		return length === 0 ? {x: 0, y: -1} : {x: normalX / length, y: normalY / length};
	}

	// Moves a body that bounces for one step, a pixel at a time, so it cannot go through thin land. It tells where it hit the land.
	#moveBody(body, seconds) {
		const count = Math.min(24, Math.max(1, Math.ceil(Math.hypot(body.vx, body.vy) * seconds)));
		for (let index = 0; index < count; index++) {
			const x = body.x + (body.vx * seconds / count);
			const y = body.y + (body.vy * seconds / count);

			if (this.#circleHits(x, y, body.radius)) {
				const normal = this.#surfaceNormal(x, y, body.radius);
				const dot = (body.vx * normal.x) + (body.vy * normal.y);
				if (dot < 0) {
					body.vx = (body.vx - ((1 + body.bounce) * dot * normal.x)) * body.friction;
					body.vy = (body.vy - ((1 + body.bounce) * dot * normal.y)) * body.friction;
				}

				// A body that ends up inside the land, like after a girder, is pushed out.
				if (this.#circleHits(body.x, body.y, body.radius)) {
					body.x += normal.x;
					body.y += normal.y;
				}

				return {normal, speed: -dot};
			}

			body.x = x;
			body.y = y;
		}

		return undefined;
	}

	#isOnGround(body) {
		return this.#circleHits(body.x, body.y + 1, body.radius);
	}

	// Walks a body one pixel, up a step of up to `climb` pixels, and down the other side. It tells whether there was a wall.
	#stepAlong(body, direction, climb) {
		const x = body.x + direction;
		for (let up = 0; up <= climb; up++) {
			if (!this.#circleHits(x, body.y - up, body.radius)) {
				body.x = x;
				body.y -= up;
				for (let down = 0; down < climb && !this.#isOnGround(body); down++) {
					body.y += 1;
				}

				return true;
			}
		}

		return false;
	}

	// MARK: The game

	#isHumanTurn() {
		return this.#game.teamIndex === 0 || this.parts.opponent.value === 'friend';
	}

	#currentWeapon() {
		return this.#game.weaponOf[this.#game.teamIndex];
	}

	#aliveWorms() {
		return this.#game.worms.filter(worm => !worm.isDead);
	}

	#sheepOut() {
		return this.#game.objects.find(object => object.kind === 'sheep');
	}

	#isHolding() {
		return this.#held.left || this.#held.right || this.#held.up || this.#held.down || this.#game.turn.charge !== undefined;
	}

	// The names that the visitor gave the worms of Team Sindre are kept in the browser. The stored data is checked, as it may be broken.
	#wormName(team, index) {
		if (team === 0) {
			const names = this.stored('names', []);
			return String(names[index] ?? '').trim().slice(0, 12) || teams[0].names[index];
		}

		return teams[1].names[index];
	}

	#windText() {
		const percent = Math.round(Math.abs(this.#game.wind) * 100);
		if (percent < 5) {
			return 'no wind';
		}

		return `wind ${percent}% to the ${this.#game.wind < 0 ? 'left' : 'right'}`;
	}

	#talk(worm, text) {
		worm.bubble = {text, time: 2.4};
		this.#speak(text);
	}

	#floatText(x, y, text, color) {
		this.#game.texts.push({x, y, text, color, life: 1.6});
	}

	#addParticles(count, make) {
		if (this.reducedMotion) {
			return;
		}

		for (let index = 0; index < count; index++) {
			this.#game.particles.push(make(index));
		}
	}

	#hurt(worm, amount, cause) {
		if (worm.isDead || amount <= 0) {
			return;
		}

		worm.health = Math.max(0, worm.health - amount);
		this.#floatText(worm.x, worm.y - 14, String(amount), teams[worm.team].color);
		this.#game.turn.damage.set(worm, (this.#game.turn.damage.get(worm) ?? 0) + amount);

		if (worm === this.#game.active && this.#game.phase === 'aim') {
			this.#game.turn.isControlLost = true;
			this.#game.turn.charge = undefined;
		}

		if (worm.health > 0) {
			if (cause === 'fall') {
				this.#talk(worm, randomItem(lines.fall));
			} else if (Math.random() < 0.7) {
				this.#talk(worm, randomItem(lines.hit));
			}

			this.#sounds.ouch();
		}
	}

	#explode(x, y, radius, damage, {isQuiet = false} = {}) {
		this.#carve(x, y, radius);

		for (const worm of this.#aliveWorms()) {
			const amount = blastDamage(worm, x, y, radius, damage);
			if (amount === 0) {
				continue;
			}

			this.#hurt(worm, amount, 'explosion');

			// The blast throws the worm away from it, and up.
			const awayX = worm.x - x;
			const awayY = worm.y - y - (radius * 0.6);
			const length = Math.hypot(awayX, awayY) || 1;
			const speed = 50 + (amount * 4.2);
			worm.state = 'air';
			worm.vx = (awayX / length) * speed;
			worm.vy = (awayY / length) * speed;
			worm.peakY = worm.y;
			worm.airTime = 0;
		}

		for (const body of [...this.#game.gravestones, ...this.#game.objects.filter(object => object.kind !== 'shell' && !object.delay)]) {
			const distance = Math.hypot(body.x - x, body.y - y);
			if (distance < radius + 8) {
				const length = distance || 1;
				body.vx = ((body.x - x) / length) * 160;
				body.vy = (((body.y - y) / length) * 160) - 80;
				body.isResting = false;
				body.state = 'air';
			}
		}

		this.#camera.shake = this.reducedMotion ? 0 : Math.min(7, radius / 6);
		this.#sounds.explosion(radius / 30);
		this.#game.effects.push({kind: 'flash', x, y, radius, life: 0.3, maxLife: 0.3});

		if (!isQuiet && damage >= 40) {
			this.#floatText(x, y - radius - 6, randomItem(['POW!', 'BIFF!', 'PANG!', 'BOOM!', 'KABOOM!']), '#ffe040');
		}

		this.#addParticles(Math.round(radius * 0.8), () => {
			const angle = randomBetween(0, Math.PI * 2);
			const speed = randomBetween(30, 160);
			return {x, y, vx: Math.cos(angle) * speed, vy: (Math.sin(angle) * speed) - 60, life: randomBetween(0.4, 1), color: randomItem(['#ffd040', '#ff8020', '#ff4010', '#6b4423', '#8a5a30']), size: randomItem([1, 1, 2]), hasGravity: true};
		});
		this.#addParticles(Math.round(radius * 0.4), () => ({x: x + randomBetween(-radius / 2, radius / 2), y: y + randomBetween(-radius / 2, radius / 2), vx: randomBetween(-15, 15), vy: randomBetween(-30, -10), life: randomBetween(0.8, 1.6), color: randomItem(['#555', '#777', '#999']), size: 3, isSmoke: true}));
	}

	#splash(x, title) {
		this.#sounds.splash();
		this.#floatText(x, this.#game.waterLevel - 10, title, '#bfe4ff');
		this.#addParticles(14, () => ({x, y: this.#game.waterLevel, vx: randomBetween(-50, 50), vy: randomBetween(-150, -60), life: randomBetween(0.5, 0.9), color: '#cfe8ff', size: 1, hasGravity: true}));
	}

	// MARK: Weapons

	// Moves a shot for one step, without changing anything else, so the computer can try it in its head. It tells when the shot explodes or is gone.
	#advance(object, seconds) {
		object.age += seconds;

		if (object.kind === 'shell') {
			object.vy += gravity * seconds;
			if (object.hasWind) {
				object.vx += this.#game.wind * windForce * seconds;
			}

			const count = Math.min(24, Math.max(1, Math.ceil(Math.hypot(object.vx, object.vy) * seconds)));
			for (let index = 0; index < count; index++) {
				object.x += object.vx * seconds / count;
				object.y += object.vy * seconds / count;

				if (this.#isSolid(object.x, object.y)) {
					return 'explode';
				}

				if (object.age > 0.08 && this.#game.worms.some(worm => !worm.isDead && (worm !== object.owner || object.age > 0.3) && Math.hypot(worm.x - object.x, worm.y - 1 - object.y) < 5)) {
					return 'explode';
				}
			}
		} else if (object.kind === 'bouncer') {
			if (object.isResting) {
				if (!this.#isOnGround(object)) {
					object.isResting = false;
				}
			} else {
				object.vy += gravity * seconds;
				const hit = this.#moveBody(object, seconds);
				if (hit) {
					object.didBounce = hit.speed > 40;
					if (hit.normal.y < -0.6 && Math.hypot(object.vx, object.vy) < 20) {
						object.isResting = true;
						object.vx = 0;
						object.vy = 0;
					}
				}
			}

			object.fuse -= seconds;
			if (object.fuse <= 0) {
				return 'explode';
			}
		}

		if (object.y > this.#game.waterLevel) {
			return 'water';
		}

		if (object.x < -200 || object.x > worldWidth + 200) {
			return 'gone';
		}

		return undefined;
	}

	// Where a shot ends, or undefined when it ends in the sea, for the aim of the computer.
	#traceShot(shot) {
		const object = {...shot};
		for (let count = 0; count < 300; count++) {
			const result = this.#advance(object, step);
			if (result === 'explode') {
				return {x: object.x, y: object.y};
			}

			if (result) {
				return undefined;
			}
		}

		return {x: object.x, y: object.y};
	}

	// The shotgun hits the first land or worm along its line.
	#traceRay(worm, angle, facing) {
		const {x: directionX, y: directionY} = aimDirection(angle, facing);
		for (let distance = 6; distance < 360; distance++) {
			const x = worm.x + (directionX * distance);
			const y = worm.y - 2 + (directionY * distance);
			const target = this.#game.worms.find(other => other !== worm && !other.isDead && Math.hypot(other.x - x, other.y - 1 - y) < 5);
			if (target || this.#isSolid(x, y)) {
				return {x, y, target, directionX, directionY};
			}
		}

		return {x: worm.x + (directionX * 360), y: worm.y - 2 + (directionY * 360), directionX, directionY};
	}

	#fireShotgun(worm) {
		const hit = this.#traceRay(worm, worm.aim, worm.facing);
		this.#game.effects.push({kind: 'tracer', x: worm.x, y: worm.y - 2, toX: hit.x, toY: hit.y, life: 0.2, maxLife: 0.2});
		this.#sounds.shotgun();

		if (hit.target) {
			this.#hurt(hit.target, 25, 'shot');
			hit.target.state = 'air';
			hit.target.vx = hit.directionX * 150;
			hit.target.vy = (hit.directionY * 150) - 60;
			hit.target.peakY = hit.target.y;
			hit.target.airTime = 0;
		}

		if (hit.target || this.#isSolid(hit.x, hit.y)) {
			this.#carve(hit.x, hit.y, 6);
			this.#addParticles(8, () => ({x: hit.x, y: hit.y, vx: randomBetween(-60, 60), vy: randomBetween(-90, -20), life: 0.5, color: '#8a5a30', size: 1, hasGravity: true}));
		}
	}

	#callAirStrike(targetX, direction) {
		this.#game.effects.push({kind: 'plane', x: targetX - (direction * 260), y: this.#camera.y + 18, direction, life: 4, maxLife: 4});
		for (let index = 0; index < 5; index++) {
			this.#game.objects.push({kind: 'shell', look: 'shell', x: targetX + ((index - 2) * 14) - (direction * 55), y: -30, vx: direction * 50, vy: 60, age: 0, hasWind: true, delay: 0.6 + (index * 0.12), team: this.#game.teamIndex, explosion: {radius: 18, damage: 26}});
		}
	}

	#startTurnState() {
		return {time: turnSeconds, hasFired: false, retreat: 0, isControlLost: false, shotsLeft: 0, charge: undefined, damage: new Map(), drowned: [], computer: undefined, isOops: false, startTime: this.#game.time};
	}

	// For reduced motion, what the worms said and the damage stay on the island until the visitor plays again, as nothing moves in between.
	#clearNotes() {
		if (!this.reducedMotion || !this.#isHumanTurn()) {
			return;
		}

		for (const worm of this.#game.worms) {
			worm.bubble = undefined;
		}

		this.#game.texts = [];
	}

	// Fires the weapon of the worm in turn. The power is from 0 to 1.
	#fire(power) {
		const worm = this.#game.active;
		const weaponId = this.#currentWeapon();
		const weapon = weapons[weaponId];
		const turn = this.#game.turn;
		turn.charge = undefined;

		if (this.#game.ammo[this.#game.teamIndex][weaponId] <= 0) {
			this.say(`${teams[this.#game.teamIndex].name} has no ${weapon.name} left. Pick another weapon.`);
			return;
		}

		// The dotted paths of reduced motion show the last shot of each team.
		this.#game.trails = this.#game.trails.filter(trail => trail.team !== this.#game.teamIndex);
		this.#clearNotes();

		if (weaponId === 'shotgun') {
			if (turn.shotsLeft === 0) {
				turn.shotsLeft = 2;
			}

			turn.shotsLeft--;
			this.#fireShotgun(worm);

			if (turn.shotsLeft > 0) {
				return;
			}
		} else if (weaponId === 'sheep') {
			this.#game.objects.push({kind: 'sheep', look: 'sheep', x: worm.x + (worm.facing * 7), y: worm.y - 2, vx: worm.facing * 40, vy: -60, radius: 3, bounce: 0.2, friction: 0.7, state: 'air', direction: worm.facing, fuse: 5, hop: 0.5, progress: 0, hasJumped: false, age: 0, team: this.#game.teamIndex});
			this.#talk(worm, 'Bææææ!');
			this.#bleat();
		} else {
			// The computer plans its bombs with a fuse of 3 seconds.
			const shot = makeProjectile(weaponId, worm, worm.aim, worm.facing, power, this.#isHumanTurn() ? this.#game.fuse : 3);
			shot.trail = this.reducedMotion ? {team: this.#game.teamIndex, points: []} : undefined;
			this.#game.objects.push(shot);
			if (weaponId === 'bazooka') {
				this.#sounds.launch();
			} else {
				this.#sounds.throw();
			}

			if (weaponId === 'holy' || Math.random() < 0.25) {
				this.#talk(worm, weaponId === 'holy' ? 'One, two, five!' : randomItem(lines.fire));
			}
		}

		this.#game.ammo[this.#game.teamIndex][weaponId]--;
		turn.hasFired = true;
		turn.retreat = this.reducedMotion ? 0 : retreatSeconds;
		this.#showWeapons();
	}

	// Places the air strike, the girder, or the teleport at the marker.
	#placeTarget() {
		const worm = this.#game.active;
		const weaponId = this.#currentWeapon();
		const {x, y} = this.#game.marker;

		if (this.#game.ammo[this.#game.teamIndex][weaponId] <= 0) {
			this.say(`${teams[this.#game.teamIndex].name} has no ${weapons[weaponId].name} left.`);
			return;
		}

		this.#clearNotes();

		if (weaponId === 'airstrike') {
			this.#callAirStrike(x, worm.facing);
			this.#talk(worm, 'Air strike!');
		} else if (weaponId === 'girder') {
			const radians = (girderAngles[this.#game.girderAngle] * Math.PI) / 180;
			const isOnWorm = this.#aliveWorms().some(other => {
				const along = ((other.x - x) * Math.cos(radians)) + ((other.y - y) * Math.sin(radians));
				const across = (-(other.x - x) * Math.sin(radians)) + ((other.y - y) * Math.cos(radians));
				return Math.abs(along) < 25 && Math.abs(across) < 8;
			});

			if (isOnWorm) {
				this.say('The girder cannot go on top of a worm. Put it somewhere else.');
				return;
			}

			this.#stampGirder(x, y, girderAngles[this.#game.girderAngle]);
			this.#sounds.place();
		} else if (weaponId === 'teleport') {
			if (this.#circleHits(x, y, wormRadius + 1) || y > this.#game.waterLevel - 10 || x < 4 || x > worldWidth - 4) {
				this.say('The teleport cannot put a worm inside the land or in the sea. Pick a spot in the air.');
				return;
			}

			this.#addParticles(20, () => ({x: worm.x + randomBetween(-5, 5), y: worm.y + randomBetween(-8, 4), vx: 0, vy: randomBetween(-40, -10), life: 0.8, color: randomItem(['#ffffff', '#a0e0ff', '#ff80ff']), size: 1}));
			worm.x = x;
			worm.y = y;
			worm.state = 'air';
			worm.vx = 0;
			worm.vy = 0;
			worm.peakY = y;
			worm.isSafeLanding = true;
			this.#sounds.teleport();
			this.#game.turn.isControlLost = true;
		}

		this.#game.ammo[this.#game.teamIndex][weaponId]--;
		this.#game.turn.hasFired = true;
		this.#game.turn.retreat = this.reducedMotion ? 0 : retreatSeconds;
		this.#showWeapons();
	}

	// MARK: The computer

	// The damage that an explosion at a point would do, good for the enemies of the team and bad for the team itself.
	#expectedValue(point, radius, damage, team) {
		let value = 0;
		for (const worm of this.#aliveWorms()) {
			const amount = Math.min(worm.health, blastDamage(worm, point.x, point.y, radius, damage));
			if (amount === 0) {
				continue;
			}

			if (worm.team === team) {
				value -= amount * 1.6;
			} else {
				value += amount + (amount >= worm.health ? 20 : 0);
			}
		}

		return value;
	}

	// The computer tries the shots of its weapons in its head, and picks the one that would hurt Team Sindre the most. It thinks a little in each frame, so the rain does not stop while it thinks.
	* #planShot(worm) {
		const team = worm.team;
		const ammo = this.#game.ammo[team];
		let best;
		const consider = plan => {
			if (!best || plan.value > best.value) {
				best = plan;
			}
		};

		for (const facing of [-1, 1]) {
			for (let angle = -15; angle <= 80; angle += 5) {
				for (let power = 0.3; power <= 1.001; power += 0.07) {
					for (const weaponId of ['bazooka', 'grenade', 'banana', 'holy']) {
						const isRare = weaponId === 'banana' || weaponId === 'holy';
						if (ammo[weaponId] <= 0 || (isRare && angle % 10 !== 0)) {
							continue;
						}

						const shot = makeProjectile(weaponId, worm, angle, facing, power, 3);
						const end = this.#traceShot(shot);
						if (!end) {
							continue;
						}

						let value = this.#expectedValue(end, shot.explosion.radius, shot.explosion.damage, team);
						if (weaponId === 'banana') {
							value = (value * 1.4) - 20;
						} else if (weaponId === 'holy') {
							value -= 35;
						}

						consider({weaponId, facing, angle, power, value});
					}

					yield;
				}
			}
		}

		for (const enemy of this.#aliveWorms().filter(other => other.team !== team)) {
			const deltaX = enemy.x - worm.x;
			const deltaY = enemy.y - worm.y;
			const facing = Math.sign(deltaX) || 1;

			if (Math.abs(deltaX) < 220) {
				const angle = (Math.atan2(-deltaY, Math.abs(deltaX)) * 180) / Math.PI;
				if (Math.abs(angle) < 85 && this.#traceRay(worm, angle, facing).target === enemy) {
					consider({weaponId: 'shotgun', facing, angle, power: 1, value: (Math.min(50, enemy.health) * 0.9) + (enemy.health <= 50 ? 20 : 0)});
				}
			}

			// The air strike needs open sky over the worm.
			let isOpen = true;
			for (let y = enemy.y - 8; y > 0 && isOpen; y -= 2) {
				isOpen = !this.#isSolid(enemy.x, y);
			}

			if (isOpen && ammo.airstrike > 0) {
				consider({weaponId: 'airstrike', facing, target: enemy.x, value: Math.min(45, enemy.health) - 12});
			}
		}

		return best;
	}

	#thinkAgain(computer, worm, found) {
		let plan = found;

		if ((!plan || plan.value < 10) && !computer.hasWalked) {
			const enemy = this.#aliveWorms().filter(other => other.team !== worm.team).toSorted((first, second) => Math.abs(first.x - worm.x) - Math.abs(second.x - worm.x))[0];
			computer.phase = 'walk';
			computer.wait = 1.4;
			computer.direction = Math.sign((enemy?.x ?? worm.x) - worm.x) || 1;
			computer.hasWalked = true;
			return;
		}

		plan ??= {weaponId: 'bazooka', facing: worm.facing, angle: 45, power: 0.7, value: 0};

		// Trond is good, but not too good. Sometimes he aims badly on purpose, and blames the wind.
		if (Math.random() < 0.2) {
			plan.angle = (plan.angle ?? 0) + randomBetween(-30, 30);
			plan.power = clamp((plan.power ?? 1) * randomBetween(0.6, 1.25), 0.2, 1);
			plan.target = (plan.target ?? 0) + randomBetween(-60, 60);
			this.#game.turn.isOops = true;
		} else {
			plan.angle = (plan.angle ?? 0) + randomBetween(-5, 5);
			plan.power = clamp((plan.power ?? 1) + randomBetween(-0.06, 0.06), 0.2, 1);
			plan.target = (plan.target ?? 0) + randomBetween(-14, 14);
		}

		plan.angle = clamp(plan.angle, -85, 85);
		computer.plan = plan;
		computer.phase = 'aim';
		this.#game.weaponOf[worm.team] = plan.weaponId;
		worm.facing = plan.facing;
		this.#showWeapons();
	}

	#runComputer(seconds) {
		const worm = this.#game.active;
		const turn = this.#game.turn;
		turn.computer ??= {phase: 'think', wait: randomBetween(0.9, 1.6), hasWalked: false};
		const computer = turn.computer;

		if (turn.isControlLost || turn.hasFired || worm.state !== 'ground') {
			return;
		}

		computer.wait -= seconds;

		if (computer.phase === 'think') {
			if (!computer.hasSaidHmm && Math.random() < 0.5) {
				this.#talk(worm, randomItem(lines.think));
			}

			computer.hasSaidHmm = true;
			computer.planner ??= this.#planShot(worm);
			const deadline = performance.now() + 6;
			while (!computer.isPlanned && performance.now() < deadline) {
				const result = computer.planner.next();
				computer.isPlanned = result.done;
				computer.found = result.value;
			}

			if (computer.wait <= 0 && computer.isPlanned) {
				this.#thinkAgain(computer, worm, computer.found);
			}
		} else if (computer.phase === 'walk') {
			worm.facing = computer.direction;
			worm.walkProgress += walkSpeed * seconds;
			while (worm.walkProgress >= 1) {
				worm.walkProgress--;
				if (!this.#stepAlong(worm, computer.direction, 5)) {
					computer.wait = 0;
					break;
				}
			}

			if (computer.wait <= 0) {
				computer.phase = 'think';
				computer.wait = 0.3;
				computer.planner = undefined;
				computer.isPlanned = false;
			}
		} else if (computer.phase === 'aim') {
			const plan = computer.plan;
			if (plan.weaponId === 'airstrike') {
				this.#game.marker = {x: plan.target, y: 0};
				this.#placeTarget();
				computer.phase = 'done';
				return;
			}

			const change = 70 * seconds;
			worm.aim += clamp(plan.angle - worm.aim, -change, change);
			if (Math.abs(plan.angle - worm.aim) < 0.01) {
				computer.phase = 'charge';
				if (weapons[plan.weaponId].isCharged) {
					turn.charge = 0;
				}
			}
		} else if (computer.phase === 'charge') {
			const plan = computer.plan;
			if (plan.weaponId === 'shotgun') {
				if (computer.wait <= 0) {
					this.#fire(1);
					computer.wait = 0.7;
				}

				return;
			}

			turn.charge = Math.min(plan.power, (turn.charge ?? 0) + (seconds / 1.2));
			if (turn.charge >= plan.power) {
				this.#fire(plan.power);
				computer.phase = 'done';
			}
		}
	}

	// MARK: Turns

	#showWeapons() {
		const ammo = this.#game.ammo[this.#game.teamIndex];
		for (const button of this.querySelectorAll('[data-worms-weapon]')) {
			const weaponId = button.dataset.wormsWeapon;
			const count = ammo[weaponId] ?? 0;
			const isOn = weaponId === this.#currentWeapon();
			button.setAttribute('aria-pressed', String(isOn));
			button.dataset.state = isOn ? 'on' : (count <= 0 ? 'empty' : '');
			const label = this.querySelector(`[data-worms-ammo="${weaponId}"]`);
			const text = count === Number.POSITIVE_INFINITY ? '∞' : (weaponId === 'girder' && isOn ? `${count} ⟳${girderAngles[this.#game.girderAngle]}°` : String(count));
			if (label.textContent !== text) {
				label.textContent = text;
			}
		}

		this.parts.fire.textContent = this.#sheepOut() ? '💥 Boom!' : (weapons[this.#currentWeapon()].isTargeted ? '🎯 Place It' : '🔥 Hold to Fire');
	}

	#resetMarker() {
		const worm = this.#game.active;
		this.#game.marker = {x: clamp(worm.x + (worm.facing * 70), 10, worldWidth - 10), y: Math.max(10, worm.y - 40)};
	}

	#beginTurn() {
		const team = this.#game.teamIndex;
		const worms = this.#game.worms.filter(worm => worm.team === team);
		let index = this.#game.lastWorm[team];
		for (let count = 0; count < worms.length; count++) {
			index = (index + 1) % worms.length;
			if (!worms[index].isDead) {
				break;
			}
		}

		this.#game.lastWorm[team] = index;
		this.#game.active = worms[index];
		this.#game.wind = Math.round(randomBetween(-1, 1) * 20) / 20;
		this.#game.turn = this.#startTurnState();
		this.#game.phase = 'aim';
		this.#camera.isManual = false;
		this.#resetMarker();
		this.#showWeapons();
		this.#sounds.turn();

		if (Math.random() < 0.4) {
			this.#talk(this.#game.active, randomItem(lines.start));
		}
	}

	#turnAnnouncement() {
		const worm = this.#game.active;
		const who = this.#isHumanTurn() ? '' : ' (the computer)';
		const clock = this.reducedMotion ? 'Take your time.' : `${turnSeconds} seconds.`;
		return `${teams[worm.team].name}${who}: ${worm.name}’s turn, with ${worm.health} health. ${this.#windText()[0].toUpperCase()}${this.#windText().slice(1)}. ${clock}`;
	}

	#turnSummary() {
		const parts = [];
		// The health that is left is said too, as the labels over the worms are tiny on a phone.
		for (const [worm, amount] of this.#game.turn.damage) {
			parts.push(`${worm.name} took ${amount}${worm.health > 0 ? ` (${worm.health} left)` : ''}`);
		}

		for (const worm of this.#game.turn.drowned) {
			parts.push(`${worm.name} drowned`);
		}

		return parts.length > 0 ? `${parts.join(', ')}. ` : '';
	}

	#startSettle() {
		this.#game.phase = 'settle';
		this.#game.turn.charge = undefined;
		this.#game.settle = {wait: 0.5, riseTo: this.#game.isSuddenDeath ? this.#game.waterLevel - 10 : undefined, summary: ''};

		if (this.#game.turn.isOops && this.#game.active && !this.#game.active.isDead) {
			this.#talk(this.#game.active, randomItem(lines.oops));
		}
	}

	#endGame(winner) {
		this.#game.phase = 'over';

		if (winner === undefined) {
			this.#game.banner = {text: 'DRAW! UAVGJORT!', color: '#ffffff'};
			this.say('Draw! All the worms are gone. Press New Game for a new island.');
			return;
		}

		const team = teams[winner];
		this.#wins[team.id]++;
		this.store('wins', this.#wins);
		this.#game.banner = {text: `${team.name} wins!`, color: team.color};
		this.#sounds.victory();

		for (const worm of this.#aliveWorms()) {
			this.#talk(worm, randomItem(lines.win));
		}

		const score = `Team Sindre has won ${this.#wins.sindre} and Team Trond ${this.#wins.trond} ${this.#wins.sindre + this.#wins.trond === 1 ? 'game' : 'games'}.`;
		if (winner === 0) {
			this.celebrate();
			this.toast('🏆 Team Sindre won Wurms ’99!');
			this.say(`${this.#turnSummary()}${this.#game.settle.summary}Team Sindre wins! Flawless! ${score} Press New Game to play again.`);
		} else {
			this.toast(this.parts.opponent.value === 'friend' ? '🏆 Team Trond won Wurms ’99!' : '🏆 Trond’s computer won. Uff da!');
			this.say(`${this.#turnSummary()}${this.#game.settle.summary}Team Trond wins! ${score} Press New Game for a rematch.`);
		}
	}

	#isCalm() {
		return this.#game.objects.length === 0 && !this.#game.worms.some(worm => !worm.isDead && worm.state === 'air') && this.#game.gravestones.every(stone => stone.isResting);
	}

	#updateSettle(seconds) {
		if (!this.#isCalm()) {
			return;
		}

		const settle = this.#game.settle;
		settle.wait -= seconds;
		if (settle.wait > 0) {
			return;
		}

		// In sudden death, the sea rises at the end of each turn.
		if (settle.riseTo !== undefined && this.#game.waterLevel > settle.riseTo) {
			this.#game.waterLevel = this.reducedMotion ? settle.riseTo : Math.max(settle.riseTo, this.#game.waterLevel - (12 * seconds));
			return;
		}

		// The worms without health say goodbye and blow up, one at a time.
		const dying = this.#game.worms.find(worm => !worm.isDead && worm.health <= 0);
		if (dying) {
			if (dying.isDying) {
				dying.isDead = true;
				this.#game.gravestones.push({x: dying.x, y: dying.y - 2, vx: 0, vy: -80, radius: 3, bounce: 0.2, friction: 0.6, isResting: false, team: dying.team, airTime: 0});
				this.#explode(dying.x, dying.y, 14, 15, {isQuiet: true});
				settle.wait = 0.6;
				settle.summary += `${dying.name} is gone. `;
			} else {
				dying.isDying = true;
				this.#talk(dying, randomItem(lines.bye));
				settle.wait = 1.1;
			}

			return;
		}

		const teamsLeft = [0, 1].filter(team => this.#game.worms.some(worm => worm.team === team && !worm.isDead));
		if (teamsLeft.length < 2) {
			this.#endGame(teamsLeft[0]);
			return;
		}

		this.#game.teamIndex = 1 - this.#game.teamIndex;
		if (this.#game.teamIndex === 0) {
			this.#game.round++;
			if (this.#game.round > suddenDeathRound && !this.#game.isSuddenDeath) {
				this.#game.isSuddenDeath = true;
				this.#game.banner = {text: 'SUDDEN DEATH!', color: '#ff4040', time: 2.5};
				settle.summary += 'Sudden death! Mamma opened the tap of the bath, so the sea rises every turn. ';
			}
		}

		const summary = `${this.#turnSummary()}${settle.summary}`;
		this.#beginTurn();
		this.say(`${summary}${this.#turnAnnouncement()}`);
	}

	#updateTurn(seconds) {
		const turn = this.#game.turn;
		const worm = this.#game.active;
		const canMove = !turn.isControlLost && turn.charge === undefined && turn.shotsLeft !== 1 && (!turn.hasFired || (turn.retreat > 0 && !this.#sheepOut())) && worm.state === 'ground';

		if (this.#isHumanTurn()) {
			worm.isWalking = false;
			if (weapons[this.#currentWeapon()].isTargeted && !turn.hasFired) {
				const speed = 120 * seconds;
				this.#game.marker.x = clamp(this.#game.marker.x + ((Number(this.#held.right) - Number(this.#held.left)) * speed), 4, worldWidth - 4);
				this.#game.marker.y = clamp(this.#game.marker.y + ((Number(this.#held.down) - Number(this.#held.up)) * speed), -40, this.#game.waterLevel - 4);
			} else {
				const direction = Number(this.#held.right) - Number(this.#held.left);
				if (direction !== 0 && canMove) {
					worm.facing = direction;
					worm.isWalking = true;
					this.#camera.isManual = false;
					worm.walkProgress += walkSpeed * seconds;
					while (worm.walkProgress >= 1) {
						worm.walkProgress--;
						if (!this.#stepAlong(worm, direction, 5)) {
							worm.walkProgress = 0;
							break;
						}
					}
				}

				const aimDirection = Number(this.#held.up) - Number(this.#held.down);
				if (aimDirection !== 0 && !turn.hasFired && !turn.isControlLost) {
					worm.aim = clamp(worm.aim + (aimDirection * 55 * seconds), -85, 85);
				}
			}

			if (turn.charge !== undefined) {
				turn.charge = Math.min(1, turn.charge + (seconds / 1.2));
				if (turn.charge >= 1) {
					this.#fire(1);
				}
			}
		} else {
			this.#runComputer(seconds);
		}

		if (!turn.hasFired) {
			if (!this.reducedMotion && this.#game.isStarted) {
				const before = Math.ceil(turn.time);
				turn.time -= seconds;
				if (Math.ceil(turn.time) !== before && turn.time <= 5 && turn.time > 0) {
					this.#sounds.tick();
				}
			}

			if (turn.time <= 0 && !turn.isControlLost) {
				turn.isControlLost = true;
				turn.charge = undefined;
				this.#talk(worm, randomItem(lines.timeout));
			}
		} else if (!this.#sheepOut()) {
			turn.retreat -= seconds;
			if (turn.retreat <= 0) {
				turn.isControlLost = true;
			}
		}

		if (turn.isControlLost && this.#isCalm()) {
			this.#startSettle();
		}
	}

	// MARK: The world, a step at a time

	#land(worm) {
		worm.state = 'ground';
		worm.vx = 0;
		worm.vy = 0;
		worm.spin = 0;
		for (let count = 0; count < 6 && this.#circleHits(worm.x, worm.y, worm.radius); count++) {
			worm.y -= 1;
		}

		const fall = worm.y - worm.peakY;
		if (!worm.isSafeLanding && fall > 64) {
			this.#hurt(worm, Math.min(45, Math.round((fall - 64) / 2.5)), 'fall');
		}

		worm.isSafeLanding = false;
	}

	#drown(worm) {
		worm.isDead = true;
		worm.isDrowned = true;
		worm.health = 0;
		worm.sink = 0;
		this.#game.turn.drowned.push(worm);

		// At once, like a hurt worm, so the world that resolves at once for reduced motion does not stop at the drowned worm, as if it waited for the visitor.
		if (worm === this.#game.active && this.#game.phase === 'aim') {
			this.#game.turn.isControlLost = true;
		}

		this.#talk(worm, randomItem(lines.drown));
		this.#splash(worm.x, 'SPLASH!');
	}

	#updateWorms(seconds) {
		for (const worm of this.#game.worms) {
			if (worm.isDead) {
				if (worm.isDrowned && worm.sink < 3) {
					worm.sink += seconds;
					worm.y += 6 * seconds;
				}

				continue;
			}

			if (worm.shownHealth !== worm.health) {
				worm.shownHealth = this.reducedMotion ? worm.health : Math.max(worm.health, worm.shownHealth - (40 * seconds));
			}

			if (worm.state === 'air') {
				worm.airTime += seconds;
				worm.vy += gravity * seconds;
				worm.peakY = Math.min(worm.peakY, worm.y);
				if (worm.isFlipping) {
					worm.spin -= worm.facing * 13 * seconds;
				}

				const hit = this.#moveBody(worm, seconds);
				const speed = Math.hypot(worm.vx, worm.vy);
				// A worm that drops in or teleports lands where it touches the ground, as a bounce could roll it into the sea.
				if ((hit && ((hit.normal.y < -0.5 && (speed < 90 || worm.isSafeLanding)) || speed < 20)) || worm.airTime > 6) {
					this.#land(worm);
				}
			} else if (!this.#isOnGround(worm)) {
				worm.state = 'air';
				worm.vx = worm.isWalking ? worm.facing * 20 : 0;
				worm.vy = 0;
				worm.peakY = worm.y;
				worm.airTime = 0;
			}

			if (worm.y - 4 > this.#game.waterLevel) {
				this.#drown(worm);
			}
		}

		// In the end, the winners dance.
		if (this.#game.phase === 'over' && !this.reducedMotion) {
			for (const worm of this.#aliveWorms()) {
				if (worm.state === 'ground' && Math.random() < seconds * 1.5) {
					worm.state = 'air';
					worm.vy = -110;
					worm.vx = 0;
					worm.peakY = worm.y;
					worm.airTime = 0;
					worm.isSafeLanding = true;
					worm.isFlipping = Math.random() < 0.4;
					worm.facing = -worm.facing;
				}
			}
		}
	}

	#updateSheep(sheep, seconds) {
		sheep.fuse -= seconds;
		if (sheep.fuse <= 0) {
			return 'explode';
		}

		if (sheep.state === 'air') {
			sheep.vy += gravity * seconds;
			const hit = this.#moveBody(sheep, seconds);
			if (hit && hit.normal.y < -0.5) {
				sheep.state = 'ground';
				sheep.vx = 0;
				sheep.vy = 0;
			}
		} else {
			sheep.hop -= seconds;
			sheep.progress += 55 * seconds;
			while (sheep.progress >= 1) {
				sheep.progress--;
				if (!this.#stepAlong(sheep, sheep.direction, 6)) {
					// A wall: the sheep jumps once, and turns around if it is still in the way.
					if (sheep.hasJumped) {
						sheep.direction = -sheep.direction;
						sheep.hasJumped = false;
					} else {
						sheep.state = 'air';
						sheep.vx = sheep.direction * 60;
						sheep.vy = -170;
						sheep.hasJumped = true;
					}

					break;
				}
			}

			if (sheep.state === 'ground' && (!this.#isOnGround(sheep) || sheep.hop <= 0)) {
				sheep.state = 'air';
				sheep.vx = sheep.direction * 55;
				sheep.vy = sheep.hop <= 0 ? -80 : 0;
				sheep.hop = 0.6;
			}
		}

		if (sheep.y > this.#game.waterLevel) {
			return 'water';
		}

		return undefined;
	}

	#detonate(object) {
		this.#explode(object.x, object.y, object.explosion?.radius ?? 34, object.explosion?.damage ?? 70);

		if (object.isCluster) {
			for (let index = 0; index < 5; index++) {
				this.#game.objects.push({kind: 'shell', look: 'banana', x: object.x, y: object.y - 2, vx: randomBetween(-130, 130), vy: randomBetween(-280, -170), age: 0.1, team: object.team, explosion: {radius: 20, damage: 32}, trail: object.trail});
			}
		}
	}

	#keepTrail(object) {
		if (object.trail?.points.length > 1 && !this.#game.trails.includes(object.trail)) {
			this.#game.trails.push(object.trail);
		}
	}

	#updateObjects(seconds) {
		for (const object of [...this.#game.objects]) {
			if (object.delay > 0) {
				object.delay -= seconds;
				continue;
			}

			// The Holy Hand Grenade waits for its choir before it explodes.
			if (object.singing !== undefined) {
				object.singing -= seconds;
				if (object.singing <= 0) {
					this.#game.objects.splice(this.#game.objects.indexOf(object), 1);
					this.#keepTrail(object);
					this.#detonate(object);
				}

				continue;
			}

			const result = object.kind === 'sheep' ? this.#updateSheep(object, seconds) : this.#advance(object, seconds);

			if (object.didBounce) {
				object.didBounce = false;
				this.#sounds.bounce();
			}

			if (object.trail && Math.round(object.age * 60) % 3 === 0) {
				object.trail.points.push({x: object.x, y: object.y});
			}

			if (object.kind === 'shell' && Math.random() < 0.6) {
				this.#addParticles(1, () => ({x: object.x, y: object.y, vx: randomBetween(-8, 8), vy: randomBetween(-12, -2), life: 0.6, color: '#c8c8c8', size: 2, isSmoke: true}));
			}

			if (result === 'explode' && object.look === 'holy') {
				object.singing = this.reducedMotion ? 0.01 : 1.5;
				object.vx = 0;
				object.vy = 0;
				this.#floatText(object.x, object.y - 16, 'HALLELUJAH!', '#ffe680');
				this.#singHallelujah();
				continue;
			}

			if (result) {
				this.#game.objects.splice(this.#game.objects.indexOf(object), 1);
				this.#keepTrail(object);

				if (result === 'explode') {
					this.#detonate(object);
				} else if (result === 'water') {
					this.#splash(object.x, object.kind === 'sheep' ? 'BÆ...' : 'PLOP!');
				}

				if (object.kind === 'sheep') {
					this.#showWeapons();
				}
			}
		}
	}

	#updateGravestones(seconds) {
		for (const stone of [...this.#game.gravestones]) {
			if (stone.isResting) {
				if (!this.#isOnGround(stone)) {
					stone.isResting = false;
					stone.airTime = 0;
				}

				continue;
			}

			stone.airTime += seconds;
			stone.vy += gravity * seconds;
			const hit = this.#moveBody(stone, seconds);
			if ((hit && hit.normal.y < -0.5 && Math.hypot(stone.vx, stone.vy) < 40) || stone.airTime > 4) {
				stone.isResting = true;
				stone.vx = 0;
				stone.vy = 0;
			}

			if (stone.y > this.#game.waterLevel + 4) {
				this.#game.gravestones.splice(this.#game.gravestones.indexOf(stone), 1);
			}
		}
	}

	#updateEffects(seconds) {
		for (const particle of this.#game.particles) {
			particle.life -= seconds;
			particle.x += particle.vx * seconds;
			particle.y += particle.vy * seconds;
			if (particle.hasGravity) {
				particle.vy += gravity * seconds;
			}

			if (particle.isSmoke) {
				particle.x += this.#game.wind * 20 * seconds;
			}
		}

		this.#game.particles = this.#game.particles.filter(particle => particle.life > 0);

		// The texts and bubbles stay while the game resolves at once for reduced motion, so the visitor can read what happened.
		if (!this.reducedMotion) {
			for (const text of this.#game.texts) {
				text.life -= seconds;
				text.y -= 14 * seconds;
			}

			this.#game.texts = this.#game.texts.filter(text => text.life > 0);

			for (const worm of this.#game.worms) {
				if (worm.bubble) {
					worm.bubble.time -= seconds;
					if (worm.bubble.time <= 0) {
						worm.bubble = undefined;
					}
				}
			}
		}

		for (const effect of this.#game.effects) {
			effect.life -= seconds;
			if (effect.kind === 'plane') {
				effect.x += effect.direction * 140 * seconds;
			}
		}

		this.#game.effects = this.#game.effects.filter(effect => effect.life > 0);

		if (this.#game.banner?.time !== undefined) {
			this.#game.banner.time -= seconds;
			if (this.#game.banner.time <= 0) {
				this.#game.banner = undefined;
			}
		}
	}

	#simulate(seconds) {
		this.#game.time += seconds;

		if (this.#game.isStarted && this.#game.phase === 'aim') {
			this.#updateTurn(seconds);
		} else if (this.#game.phase === 'settle') {
			this.#updateSettle(seconds);
		}

		this.#updateWorms(seconds);
		this.#updateObjects(seconds);
		this.#updateGravestones(seconds);
		this.#updateEffects(seconds);
	}

	// For reduced motion, the world runs at once until it waits for the visitor again, with nothing to see in between.
	#isWaitingForVisitor() {
		return !this.#game.isStarted || this.#game.phase === 'over' || (this.#game.phase === 'aim' && this.#isHumanTurn() && !this.#game.turn.hasFired && !this.#game.turn.isControlLost && this.#isCalm());
	}

	#resolveNow() {
		for (let count = 0; count < 60 * 120 && !this.#isWaitingForVisitor(); count++) {
			this.#simulate(step);
		}

		this.#draw(0);
	}

	// MARK: Drawing

	// Draws a sprite with its bottom middle at a point, turned to face left when asked, and spun around its middle.
	#drawSprite(sprite, x, y, {isFlipped = false, spin = 0, alpha = 1} = {}) {
		this.#context.save();
		this.#context.globalAlpha = alpha;
		this.#context.translate(Math.round(x), Math.round(y - (sprite.height / 2)));
		if (spin !== 0) {
			this.#context.rotate(spin);
		}

		if (isFlipped) {
			this.#context.scale(-1, 1);
		}

		this.#context.drawImage(sprite, -Math.floor(sprite.width / 2), -Math.floor(sprite.height / 2));
		this.#context.restore();
	}

	#resize() {
		const {screen} = this.parts;
		const width = Math.round(clamp(screen.clientWidth / 2, 220, 400));
		const height = Math.max(200, Math.round(width * 0.6));
		if (width !== this.#viewWidth || height !== this.#viewHeight || !this.#skyGradient) {
			this.#viewWidth = width;
			this.#viewHeight = height;
			screen.width = width;
			screen.height = height;
			this.#skyGradient = this.#context.createLinearGradient(0, 0, 0, height);
			this.#skyGradient.addColorStop(0, '#6e7d90');
			this.#skyGradient.addColorStop(1, '#b9c3cd');
			this.#draw(0);
		}
	}

	// What the camera looks at: the shot in the air, a worm that flies, or the worm in turn.
	#cameraFocus() {
		if (this.#game.phase === 'over') {
			return this.#aliveWorms()[0] ?? this.#game.active;
		}

		const object = this.#game.objects.find(item => !(item.delay > 0));
		if (object) {
			return object;
		}

		if (this.#game.phase === 'settle') {
			const dying = this.#game.worms.find(worm => worm.isDying && !worm.isDead);
			if (dying) {
				return dying;
			}
		}

		const flying = this.#game.worms.find(worm => !worm.isDead && worm.state === 'air' && worm !== this.#game.active);
		if (flying) {
			return flying;
		}

		if (this.#game.active && this.#isHumanTurn() && this.#game.phase === 'aim' && weapons[this.#currentWeapon()].isTargeted && !this.#game.turn.hasFired) {
			return this.#game.marker;
		}

		return this.#game.active ?? {x: worldWidth / 2, y: 200};
	}

	#clampCamera() {
		this.#camera.x = clamp(this.#camera.x, 0, worldWidth - this.#viewWidth);
		this.#camera.y = clamp(this.#camera.y, -60, worldHeight - this.#viewHeight);
	}

	#updateCamera(seconds) {
		if (!this.#camera.isManual) {
			const focus = this.#cameraFocus();
			const targetX = focus.x - (this.#viewWidth / 2);
			const targetY = focus.y - (this.#viewHeight * 0.5);
			const amount = this.reducedMotion || seconds === 0 ? 1 : Math.min(1, seconds * 4);
			this.#camera.x += (targetX - this.#camera.x) * amount;
			this.#camera.y += (targetY - this.#camera.y) * amount;
		}

		this.#clampCamera();
		this.#camera.shake = Math.max(0, this.#camera.shake - (seconds * 12));
	}

	#drawBackground(left, top, seconds) {
		this.#context.fillStyle = this.#skyGradient;
		this.#context.fillRect(0, 0, this.#viewWidth, this.#viewHeight);

		// The seven mountains around Bergen, far away, and the TV mast on top of Ulriken.
		for (const [layer, parallax, color] of [[0, 0.15, '#7f8da0'], [1, 0.3, '#64748a']]) {
			const base = (this.#viewHeight * 0.92) - (top * 0.12) + (layer * 18);
			this.#context.fillStyle = color;
			for (let x = 0; x < this.#viewWidth; x++) {
				const height = Math.round(mountainHeight(x + (left * parallax), layer));
				this.#context.fillRect(x, Math.round(base - height), 1, this.#viewHeight);
			}

			if (layer === 0) {
				const mastX = Math.round(340 - (left * parallax));
				if (mastX > 0 && mastX < this.#viewWidth) {
					const mastTop = Math.round(base - mountainHeight(340, 0)) - 14;
					this.#context.fillStyle = '#4a5466';
					this.#context.fillRect(mastX, mastTop, 1, 14);
					this.#context.fillRect(mastX - 1, mastTop + 6, 3, 1);
					this.#context.fillStyle = this.reducedMotion || Math.floor(this.#game.time * 1.5) % 2 === 0 ? '#ff3030' : '#802020';
					this.#context.fillRect(mastX, mastTop - 1, 1, 1);
				}
			}
		}

		// The clouds drift with the wind.
		this.#context.fillStyle = 'rgb(90 100 115 / 0.55)';
		for (const cloud of this.#clouds) {
			if (!this.reducedMotion) {
				cloud.x += this.#game.wind * 14 * seconds;
			}

			const span = 1100;
			const x = ((((cloud.x - (left * 0.5)) % span) + span) % span) - 100;
			const y = cloud.y - (top * 0.3);
			this.#context.beginPath();
			this.#context.ellipse(x, y, cloud.width / 2, 9, 0, 0, Math.PI * 2);
			this.#context.ellipse(x + (cloud.width * 0.25), y - 5, cloud.width / 3, 8, 0, 0, Math.PI * 2);
			this.#context.fill();
		}
	}

	#drawRain(seconds) {
		if (this.reducedMotion) {
			return;
		}

		this.#context.fillStyle = 'rgb(210 225 240 / 0.55)';
		for (const drop of this.#rain) {
			drop.y += drop.speed * seconds;
			drop.x += this.#game.wind * 60 * seconds;
			if (drop.y > this.#viewHeight) {
				drop.y -= this.#viewHeight + 10;
				drop.x = Math.random() * this.#viewWidth;
			}

			drop.x = ((drop.x % this.#viewWidth) + this.#viewWidth) % this.#viewWidth;
			const lean = Math.round(this.#game.wind * 2);
			this.#context.fillRect(Math.round(drop.x), Math.round(drop.y), 1, 2);
			this.#context.fillRect(Math.round(drop.x) + lean, Math.round(drop.y) + 2, 1, 2);
		}
	}

	#drawWater(left, top) {
		const surfaceY = Math.round(this.#game.waterLevel - top);
		if (surfaceY >= this.#viewHeight) {
			return;
		}

		this.#context.fillStyle = 'rgb(28 62 110 / 0.88)';
		this.#context.fillRect(0, surfaceY, this.#viewWidth, this.#viewHeight - surfaceY);
		const time = this.reducedMotion ? 0 : this.#game.time;

		for (const [offset, color, speed] of [[0, '#7fb0e0', 2], [5, '#4a7fbf', -1.4], [11, '#3a6aa8', 1]]) {
			this.#context.fillStyle = color;
			for (let x = 0; x < this.#viewWidth; x += 2) {
				const wave = Math.round(Math.sin(((x + left) * 0.07) + (time * speed)) * 1.5);
				this.#context.fillRect(x, surfaceY + offset + wave, 2, 1);
			}
		}
	}

	#drawBubble(text, x, y) {
		const width = textWidth(text) + 6;
		const left = Math.round(clamp(x - (width / 2), 1, this.#viewWidth - width - 1));
		const top = Math.round(y - 11);
		this.#context.fillStyle = '#000000';
		this.#context.fillRect(left - 1, top - 1, width + 2, 11);
		this.#context.fillStyle = '#ffffff';
		this.#context.fillRect(left, top, width, 9);
		this.#context.fillStyle = '#000000';
		this.#context.fillRect(Math.round(x) - 1, top + 10, 3, 1);
		this.#context.fillRect(Math.round(x), top + 11, 1, 1);
		this.#context.fillStyle = '#ffffff';
		this.#context.fillRect(Math.round(x), top + 9, 1, 1);
		this.#drawText(text, left + 3, top + 2, '#000000');
	}

	#drawWorm(worm, left, top) {
		const x = worm.x - left;
		const y = worm.y - top;

		if (worm.isDead) {
			if (worm.isDrowned && worm.sink < 3) {
				this.#drawSprite(wormSprites[worm.team], x, y + 4, {isFlipped: worm.facing < 0, spin: Math.PI, alpha: 0.6});
			}

			return;
		}

		const bob = worm.isWalking && Math.floor(this.#game.time * 8) % 2 === 0 ? 1 : 0;
		this.#drawSprite(wormSprites[worm.team], x, y + 4 - bob, {isFlipped: worm.facing < 0, spin: worm.spin});

		// The worm in turn holds its weapon along its aim.
		const isActive = worm === this.#game.active && this.#game.phase === 'aim' && !this.#game.turn.isControlLost && !this.#game.turn.hasFired;
		if (isActive && worm.state === 'ground' && weapons[this.#currentWeapon()].isAimed) {
			const direction = aimDirection(worm.aim, worm.facing);
			this.#context.fillStyle = this.#currentWeapon() === 'holy' ? '#ffd23c' : '#3a3a3a';
			for (let distance = 2; distance < 7; distance++) {
				this.#context.fillRect(Math.round(x + (direction.x * distance)), Math.round(y - 2 + (direction.y * distance)), 2, 2);
			}
		}
	}

	// The name and the health over a worm.
	#drawWormLabels(worm, left, top) {
		if (worm.isDead) {
			return;
		}

		const x = worm.x - left;
		const y = worm.y - top;
		const {color} = teams[worm.team];
		this.#drawLabel(String(Math.round(worm.shownHealth)), x, y - 16, color);
		this.#drawLabel(worm.name, x, y - 24, color);
	}

	#drawCrosshair(x, y, color) {
		this.#context.fillStyle = color;
		this.#context.fillRect(Math.round(x) - 3, Math.round(y), 2, 1);
		this.#context.fillRect(Math.round(x) + 2, Math.round(y), 2, 1);
		this.#context.fillRect(Math.round(x), Math.round(y) - 3, 1, 2);
		this.#context.fillRect(Math.round(x), Math.round(y) + 2, 1, 2);
	}

	#drawAim(left, top) {
		const worm = this.#game.active;
		const turn = this.#game.turn;
		if (!worm || this.#game.phase !== 'aim' || turn.isControlLost || turn.hasFired || worm.isDead) {
			return;
		}

		const x = worm.x - left;
		const y = worm.y - top;

		// A bouncing arrow over the worm in turn, at the start of the turn.
		if (this.#game.time - turn.startTime < 2.5 || this.reducedMotion) {
			const bounce = this.reducedMotion ? 0 : Math.round(Math.abs(Math.sin(this.#game.time * 6)) * 4);
			this.#context.fillStyle = teams[worm.team].color;
			for (let row = 0; row < 4; row++) {
				this.#context.fillRect(Math.round(x) - 3 + row, Math.round(y) - 40 - bounce + row, 7 - (row * 2), 1);
			}
		}

		const weapon = weapons[this.#currentWeapon()];
		if (weapon.isTargeted && this.#isHumanTurn()) {
			const markerX = this.#game.marker.x - left;
			const markerY = this.#game.marker.y - top;
			if (this.#currentWeapon() === 'girder') {
				const radians = (girderAngles[this.#game.girderAngle] * Math.PI) / 180;
				this.#context.save();
				this.#context.translate(Math.round(markerX), Math.round(markerY));
				this.#context.rotate(radians);
				this.#context.fillStyle = 'rgb(150 158 176 / 0.6)';
				this.#context.fillRect(-20, -2.5, 40, 5);
				this.#context.restore();
			} else if (this.#currentWeapon() === 'teleport') {
				this.#drawSprite(wormSprites[worm.team], markerX, markerY + 4, {isFlipped: worm.facing < 0, alpha: 0.45});
			} else {
				this.#context.fillStyle = '#ff4040';
				this.#context.fillRect(Math.round(markerX), 0, 1, Math.max(0, Math.round(markerY) - 4));
			}

			this.#drawCrosshair(markerX, markerY, Math.floor(this.#game.time * 4) % 2 === 0 || this.reducedMotion ? '#ff2020' : '#ffffff');
			return;
		}

		if (!weapon.isAimed || worm.state !== 'ground') {
			return;
		}

		const {x: directionX, y: directionY} = aimDirection(worm.aim, worm.facing);
		this.#drawCrosshair(x + (directionX * 26), y - 2 + (directionY * 26), '#ff2020');

		// The power grows as a row of dots from yellow to red, like in Worms.
		if (turn.charge !== undefined) {
			const count = Math.ceil(turn.charge * 14);
			for (let index = 0; index < count; index++) {
				const distance = 6 + (index * 1.6);
				const size = 1 + Math.floor(index / 5);
				this.#context.fillStyle = `hsl(${60 - (index * 4)} 100% 50%)`;
				this.#context.fillRect(Math.round(x + (directionX * distance) - (size / 2)), Math.round(y - 2 + (directionY * distance) - (size / 2)), size, size);
			}
		}
	}

	#drawObjects(left, top) {
		for (const object of this.#game.objects) {
			if (object.delay > 0) {
				continue;
			}

			const x = object.x - left;
			const y = object.y - top;

			if (object.look === 'shell') {
				this.#context.save();
				this.#context.translate(Math.round(x), Math.round(y));
				this.#context.rotate(Math.atan2(object.vy, object.vx));
				this.#context.fillStyle = '#4a5a2a';
				this.#context.fillRect(-3, -1, 6, 2);
				this.#context.fillStyle = '#ffb020';
				this.#context.fillRect(-4, -1, 1, 2);
				this.#context.restore();
			} else if (object.look === 'grenade') {
				this.#drawSprite(grenadeSprite, x, y + 2);
			} else if (object.look === 'banana') {
				this.#drawSprite(bananaSprite, x, y + 2, {spin: this.reducedMotion ? 0 : object.age * 8});
			} else if (object.look === 'holy') {
				if (object.singing !== undefined && !this.reducedMotion) {
					// The light from heaven.
					this.#context.fillStyle = 'rgb(255 240 160 / 0.35)';
					this.#context.beginPath();
					this.#context.moveTo(x - 3, y - 4);
					this.#context.lineTo(x + 3, y - 4);
					this.#context.lineTo(x + 26, -10);
					this.#context.lineTo(x - 26, -10);
					this.#context.fill();
				}

				this.#drawSprite(holySprite, x, y + 3);
			} else if (object.look === 'sheep') {
				this.#drawSprite(sheepSprite, x, y + 3, {isFlipped: object.direction < 0});
			}

			// The fuse counts down over a bomb, like in Worms.
			if (object.kind === 'bouncer' && object.singing === undefined) {
				this.#drawText(String(Math.max(1, Math.ceil(object.fuse))), x, y - 11, '#ffffff', {align: 'center', shadow: '#000000'});
			}
		}

		for (const stone of this.#game.gravestones) {
			this.#drawSprite(gravestoneSprite, stone.x - left, stone.y - top + 3);
		}
	}

	#drawEffects(left, top) {
		for (const effect of this.#game.effects) {
			const amount = effect.life / effect.maxLife;
			if (effect.kind === 'flash') {
				this.#context.fillStyle = `rgb(255 ${Math.round(160 + (amount * 90))} 80 / ${amount})`;
				this.#context.beginPath();
				this.#context.arc(effect.x - left, effect.y - top, effect.radius * (1.2 - (amount * 0.4)), 0, Math.PI * 2);
				this.#context.fill();
			} else if (effect.kind === 'tracer') {
				this.#context.strokeStyle = `rgb(255 240 160 / ${amount})`;
				this.#context.lineWidth = 1;
				this.#context.beginPath();
				this.#context.moveTo(effect.x - left, effect.y - top);
				this.#context.lineTo(effect.toX - left, effect.toY - top);
				this.#context.stroke();
			} else if (effect.kind === 'plane') {
				this.#drawSprite(planeSprite, effect.x - left, effect.y - top, {isFlipped: effect.direction < 0});
			}
		}

		for (const particle of this.#game.particles) {
			this.#context.fillStyle = particle.color;
			this.#context.globalAlpha = particle.isSmoke ? Math.min(0.6, particle.life) : 1;
			this.#context.fillRect(Math.round(particle.x - left), Math.round(particle.y - top), particle.size, particle.size);
		}

		this.#context.globalAlpha = 1;
	}

	#drawTrails(left, top) {
		for (const trail of this.#game.trails) {
			this.#context.fillStyle = teams[trail.team].color;
			for (const point of trail.points) {
				this.#context.fillRect(Math.round(point.x - left), Math.round(point.y - top), 1, 1);
			}
		}
	}

	// The clock, the health of the teams, and the wind, at the bottom. They are drawn under the labels of the worms, so a worm low in a corner still shows its name and health.
	#drawGauges() {
		const turn = this.#game.turn;
		const bottom = this.#viewHeight - 4;

		// The clock of the turn, in the corner, in the color of the team.
		if (this.#game.active && this.#game.phase === 'aim' && this.#game.isStarted) {
			const isRetreat = turn.hasFired && turn.retreat > 0 && !this.reducedMotion;
			const seconds = isRetreat ? Math.ceil(turn.retreat) : Math.max(0, Math.ceil(turn.time));
			if (!this.reducedMotion) {
				this.#context.fillStyle = '#000000';
				this.#context.fillRect(3, bottom - 14, 19, 14);
				this.#context.fillStyle = teams[this.#game.teamIndex].color;
				this.#context.fillRect(3, bottom - 14, 19, 1);
				this.#context.fillRect(3, bottom - 1, 19, 1);
				this.#drawText(String(seconds), 13, bottom - 12, isRetreat ? '#ffe040' : (seconds <= 5 ? '#ff4040' : '#ffffff'), {scale: 2, align: 'center'});
			}
		}

		// The health of the teams, as bars. A worm that stands behind them would be hidden and its labels mixed up with the names of the teams, so then the bars are faint.
		const barMaximum = Math.min(100, this.#viewWidth - 120);
		const barsLeft = Math.round((this.#viewWidth / 2) - (barMaximum / 2)) - 4 - Math.max(...teams.map(team => textWidth(team.id)));
		const barsRight = Math.round((this.#viewWidth / 2) + (barMaximum / 2)) + 2;
		const isWormBehindBars = this.#game.worms.some(worm => {
			if (worm.isDead) {
				return false;
			}

			const x = worm.x - this.#camera.x;
			const y = worm.y - this.#camera.y;
			const labelHalfWidth = (textWidth(worm.name) / 2) + 1;
			return x + labelHalfWidth >= barsLeft && x - labelHalfWidth <= barsRight && y + wormRadius >= bottom - 14 && y - 25 <= bottom;
		});
		this.#context.globalAlpha = isWormBehindBars ? 0.35 : 1;
		for (const [index, team] of teams.entries()) {
			const worms = this.#game.worms.filter(worm => worm.team === index);
			let health = 0;
			for (const worm of worms) {
				health += worm.isDead ? 0 : worm.shownHealth;
			}

			const width = worms.length === 0 ? 0 : Math.round(barMaximum * health / (worms.length * 100));
			const y = bottom - 13 + (index * 7);
			const nameX = Math.round((this.#viewWidth / 2) - (barMaximum / 2)) - 2;
			this.#drawText(team.id, nameX, y, team.color, {align: 'right', shadow: '#000000'});
			this.#context.fillStyle = '#000000';
			this.#context.fillRect(nameX + 2, y - 1, barMaximum + 2, 7);
			this.#context.fillStyle = team.color;
			this.#context.fillRect(nameX + 3, y, width, 5);
		}

		this.#context.globalAlpha = 1;

		// The wind, with arrows that blow to its side.
		const windWidth = 44;
		const windX = this.#viewWidth - windWidth - 4;
		const windY = bottom - 7;
		this.#context.fillStyle = '#000000';
		this.#context.fillRect(windX, windY, windWidth, 7);
		const strength = Math.round(Math.abs(this.#game.wind) * ((windWidth / 2) - 1));
		const offset = this.reducedMotion ? 0 : Math.floor(this.#game.time * 12) % 4;
		for (let index = 0; index < strength; index++) {
			const x = this.#game.wind > 0 ? windX + (windWidth / 2) + index : windX + (windWidth / 2) - 1 - index;
			const isBright = ((index + (this.#game.wind > 0 ? -offset : offset)) % 4 + 4) % 4 < 2;
			this.#context.fillStyle = isBright ? '#80c0ff' : '#3070c0';
			this.#context.fillRect(x, windY + 1, 1, 5);
		}

		this.#context.fillStyle = '#ffffff';
		this.#context.fillRect(windX + (windWidth / 2), windY, 1, 7);
		this.#drawText('WIND', windX + (windWidth / 2), windY - 7, '#ffffff', {align: 'center', shadow: '#000000'});
	}

	// The weapon, the round, the hints, and the banners, over everything else.
	#drawInterface() {
		const turn = this.#game.turn;

		// The weapon, and the round, at the top.
		if (this.#game.active && this.#game.isStarted && this.#game.phase === 'aim') {
			const weaponId = this.#currentWeapon();
			let label = weapons[weaponId].name;
			if (weapons[weaponId].hasFuse) {
				label += ` ${this.#game.fuse} SEC`;
			} else if (weaponId === 'girder') {
				label += ` ${girderAngles[this.#game.girderAngle]}°`;
			} else if (weaponId === 'shotgun' && turn.shotsLeft === 1) {
				label += ' 1 MORE';
			}

			this.#drawText(label, 4, 4, '#ffffff', {shadow: '#000000'});
		}

		this.#drawText(this.#game.isSuddenDeath ? 'SUDDEN DEATH' : `ROUND ${this.#game.round}`, this.#viewWidth - 4, 4, this.#game.isSuddenDeath ? '#ff5050' : '#ffffff', {align: 'right', shadow: '#000000'});

		if (this.#game.phase === 'aim' && this.#game.isStarted && !turn.hasFired) {
			if (!this.#isHumanTurn()) {
				this.#drawText('TROND IS THINKING...', this.#viewWidth / 2, 14, '#ffd0d0', {align: 'center', shadow: '#000000'});
			} else if (this.#game.round === 1) {
				// The first round shows how to shoot, where the visitor looks.
				this.#drawText(howToShoot(), this.#viewWidth / 2, 14, '#ffe040', {align: 'center', shadow: '#000000'});
			}
		}

		const scale = this.#viewWidth >= 300 ? 2 : 1;

		if (this.#game.banner) {
			this.#context.fillStyle = 'rgb(0 0 40 / 0.5)';
			this.#context.fillRect(0, (this.#viewHeight / 2) - 34, this.#viewWidth, (scale * 5) + 8);
			this.#drawText(this.#game.banner.text, this.#viewWidth / 2, (this.#viewHeight / 2) - 30, this.#game.banner.color, {scale, align: 'center', shadow: '#000000'});
		}

		if (!this.#game.isStarted) {
			this.#context.fillStyle = 'rgb(0 0 40 / 0.75)';
			this.#context.fillRect(0, (this.#viewHeight / 2) - 40, this.#viewWidth, 64);
			this.#drawText('SINDRE\'S WURMS \'99', this.#viewWidth / 2, (this.#viewHeight / 2) - 32, '#ffe040', {scale: this.#viewWidth >= 300 ? 3 : 2, align: 'center', shadow: '#a02020'});
			this.#drawText(howToShoot(), this.#viewWidth / 2, (this.#viewHeight / 2) - 4, '#ffffff', {align: 'center'});
			this.#drawText(`WINS: SINDRE ${this.#wins.sindre}, TROND ${this.#wins.trond}`, this.#viewWidth / 2, (this.#viewHeight / 2) + 8, '#a0d0ff', {align: 'center'});
		}
	}

	#draw(seconds) {
		if (this.#isTerrainChanged) {
			this.#terrainContext.putImageData(this.#terrainPixels, 0, 0);
			this.#isTerrainChanged = false;
		}

		this.#updateCamera(seconds);
		const shakeX = this.#camera.shake > 0 ? Math.round(randomBetween(-this.#camera.shake, this.#camera.shake)) : 0;
		const shakeY = this.#camera.shake > 0 ? Math.round(randomBetween(-this.#camera.shake, this.#camera.shake)) : 0;
		const left = Math.round(this.#camera.x) + shakeX;
		const top = Math.round(this.#camera.y) + shakeY;

		this.#context.imageSmoothingEnabled = false;
		this.#drawBackground(left, top, seconds);
		this.#context.drawImage(this.#terrainCanvas, -left, -top);
		this.#drawTrails(left, top);
		this.#drawObjects(left, top);

		for (const worm of this.#game.worms) {
			this.#drawWorm(worm, left, top);
		}

		this.#drawAim(left, top);
		this.#drawEffects(left, top);
		this.#drawWater(left, top);
		this.#drawRain(seconds);
		this.#drawGauges();

		for (const worm of this.#game.worms) {
			this.#drawWormLabels(worm, left, top);
		}

		for (const text of this.#game.texts) {
			this.#drawText(text.text, text.x - left, text.y - top, text.color, {align: 'center', shadow: '#000000'});
		}

		for (const worm of this.#game.worms) {
			const isOnScreen = worm.x > left - 10 && worm.x < left + this.#viewWidth + 10;
			if (worm.bubble && isOnScreen && (!worm.isDead || worm.isDrowned)) {
				this.#drawBubble(worm.bubble.text, worm.x - left, Math.min(worm.y, this.#game.waterLevel) - top - 27);
			}
		}

		this.#drawInterface();
	}

	// MARK: A new game

	#newGame() {
		this.#generateIsland();
		const count = Number(this.parts.count.value) || 3;
		this.#game.worms = [];
		this.#game.objects = [];
		this.#game.particles = [];
		this.#game.texts = [];
		this.#game.effects = [];
		this.#game.gravestones = [];
		this.#game.trails = [];
		this.#game.waterLevel = startingWater;
		this.#game.round = 1;
		this.#game.isSuddenDeath = false;
		this.#game.teamIndex = 0;
		this.#game.lastWorm = [-1, -1];
		this.#game.ammo = [0, 1].map(() => Object.fromEntries(weaponIds.map(weaponId => [weaponId, weapons[weaponId].ammo])));
		this.#game.weaponOf = ['bazooka', 'bazooka'];
		this.#game.banner = undefined;

		// The worms fall from the sky onto the island, each on a spot of its own. The spot is fairly flat, as a worm that lands on a steep slope, like the shores at the ends, slides into the sea before the game starts.
		for (let index = 0; index < count * 2; index++) {
			const team = index % 2;
			for (let attempt = 0; attempt < 400; attempt++) {
				const x = Math.round(randomBetween(70, worldWidth - 70));
				const ground = this.#groundBelowSky(x);
				const slope = Math.abs((this.#groundBelowSky(x + 4) ?? worldHeight) - (this.#groundBelowSky(x - 4) ?? worldHeight));
				if (ground === undefined || ground > startingWater - 25 || slope > 6 || this.#game.worms.some(worm => Math.abs(worm.x - x) < (attempt < 300 ? 60 : 25))) {
					continue;
				}

				this.#game.worms.push({team, name: this.#wormName(team, Math.floor(index / 2)), x, y: ground - 5 - randomBetween(40, 90), vx: 0, vy: 0, radius: wormRadius, bounce: 0.3, friction: 0.8, state: 'air', airTime: 0, peakY: 0, isSafeLanding: true, health: 100, shownHealth: 100, facing: x < worldWidth / 2 ? 1 : -1, aim: 20, walkProgress: 0, spin: 0, isDead: false, isDying: false, isDrowned: false, isFlipping: false, isWalking: false, bubble: undefined});
				break;
			}
		}

		this.#beginTurn();
		this.#camera.isManual = false;

		// For reduced motion, the worms are already on the island.
		if (this.reducedMotion) {
			for (let count = 0; count < 900 && !this.#isCalm(); count++) {
				this.#simulate(step);
			}
		}

		this.#updateCamera(0);
	}

	#start() {
		if (this.#game.isStarted) {
			return;
		}

		this.#game.isStarted = true;
		this.#game.turn.startTime = this.#game.time;
		this.say(this.#turnAnnouncement());
	}

	// MARK: Input

	#afterInput() {
		if (this.reducedMotion) {
			if (this.#isHolding()) {
				this.#loop.start();
			} else {
				this.#resolveNow();
			}
		} else {
			this.#loop.start();
		}
	}

	#canControl() {
		if (this.#game.phase === 'over') {
			this.say('The game is over. Press New Game for a new island.');
			return false;
		}

		if (!this.#isHumanTurn()) {
			this.say('Wait! It is the turn of Trond’s computer.');
			return false;
		}

		return this.#game.phase === 'aim';
	}

	#jump(isBackflip) {
		this.#start();
		const worm = this.#game.active;
		const turn = this.#game.turn;
		if (!this.#canControl() || worm.state !== 'ground' || turn.isControlLost || turn.charge !== undefined || turn.shotsLeft === 1 || (turn.hasFired && (turn.retreat <= 0 || this.#sheepOut()))) {
			this.#afterInput();
			return;
		}

		worm.state = 'air';
		worm.vx = isBackflip ? -worm.facing * 35 : worm.facing * 75;
		worm.vy = isBackflip ? -205 : -130;
		worm.peakY = worm.y;
		worm.airTime = 0;
		worm.isFlipping = isBackflip;
		this.#camera.isManual = false;
		this.#sounds.jump();
		this.#afterInput();
	}

	#pressFire() {
		this.#start();
		if (!this.#canControl()) {
			return;
		}

		const turn = this.#game.turn;
		const sheep = this.#sheepOut();
		if (sheep) {
			sheep.fuse = 0;
			this.#afterInput();
			return;
		}

		if (turn.hasFired || turn.isControlLost) {
			return;
		}

		if (this.#game.active.state !== 'ground') {
			this.say(`Wait until ${this.#game.active.name} stands on the ground.`);
			return;
		}

		const weapon = weapons[this.#currentWeapon()];
		if (weapon.isTargeted) {
			this.#placeTarget();
		} else if (weapon.isCharged) {
			if (this.#game.ammo[this.#game.teamIndex][this.#currentWeapon()] <= 0) {
				this.#fire(0);
				return;
			}

			turn.charge = 0;
		} else {
			this.#fire(1);
		}

		this.#afterInput();
	}

	#releaseFire() {
		if (this.#game.turn.charge !== undefined && this.#isHumanTurn()) {
			this.#fire(this.#game.turn.charge);
		}

		this.#afterInput();
	}

	#pickWeapon(weaponId) {
		this.#start();
		if (!this.#canControl()) {
			return;
		}

		const turn = this.#game.turn;
		if (turn.hasFired || turn.shotsLeft === 1 || turn.charge !== undefined) {
			this.say('You can only pick a weapon before you fire.');
			return;
		}

		// The girder turns when it is picked again.
		if (weaponId === 'girder' && this.#currentWeapon() === 'girder') {
			this.#game.girderAngle = (this.#game.girderAngle + 1) % girderAngles.length;
		}

		if (weapons[weaponId].isTargeted && !weapons[this.#currentWeapon()].isTargeted) {
			this.#resetMarker();
		}

		this.#game.weaponOf[this.#game.teamIndex] = weaponId;
		this.#showWeapons();
		const count = this.#game.ammo[this.#game.teamIndex][weaponId];
		const hints = {
			bazooka: 'It flies with the wind.',
			grenade: `It bounces, and explodes after ${this.#game.fuse} seconds.`,
			shotgun: 'Two shots, straight ahead.',
			banana: 'It splits into five bananas!',
			sheep: 'It walks by itself. Press Fire again to blow it up.',
			airstrike: 'Tap the island where it should hit, or move the target with the arrow keys and press Fire.',
			holy: 'Count to three. Not five!',
			girder: `Tap the island where it should go, or move it with the arrow keys and press Fire. Pick Girder again to turn it (now ${girderAngles[this.#game.girderAngle]}°).`,
			teleport: 'Tap the spot in the air to go to, or move the target with the arrow keys and press Fire.',
		};
		this.say(`${weapons[weaponId].name}${count === Number.POSITIVE_INFINITY ? '' : ` (${count} left)`}. ${hints[weaponId]}`);
		this.#afterInput();
	}

	#setFuse(seconds) {
		this.#game.fuse = seconds;
		for (const button of this.querySelectorAll('[data-worms-fuse]')) {
			setPressed(button, Number(button.dataset.wormsFuse) === seconds);
		}

		this.say(`Fuse: ${seconds} ${seconds === 1 ? 'second' : 'seconds'}.`);
		this.#afterInput();
	}

	#skipTurn() {
		this.#start();
		if (!this.#canControl() || this.#game.turn.hasFired) {
			return;
		}

		this.#clearNotes();
		this.#game.turn.isControlLost = true;
		this.#game.turn.hasFired = true;
		this.#game.turn.charge = undefined;
		this.#talk(this.#game.active, 'Pass!');
		this.#afterInput();
	}

	// A key that is held when the focus leaves, like when the visitor switches windows, never gets its key-up, so it is let go here, and a charge stops without a shot.
	#letGo() {
		for (const control of Object.keys(this.#held)) {
			this.#held[control] = false;
		}

		if (this.#isHumanTurn()) {
			this.#game.turn.charge = undefined;
		}

		this.#afterInput();
	}

	#endDrag(event) {
		if (!this.#drag) {
			return;
		}

		const wasPanning = this.#drag.isPanning;
		this.#drag = undefined;
		if (wasPanning || event.type === 'pointercancel') {
			return;
		}

		this.#start();
		if (!this.#canControl()) {
			this.#afterInput();
			return;
		}

		const point = canvasPoint(this.parts.screen, event);
		const worldX = point.x + Math.round(this.#camera.x);
		const worldY = point.y + Math.round(this.#camera.y);
		const worm = this.#game.active;

		if (this.#sheepOut()) {
			this.#sheepOut().fuse = 0;
		} else if (weapons[this.#currentWeapon()].isTargeted && !this.#game.turn.hasFired && !this.#game.turn.isControlLost) {
			this.#game.marker = {x: clamp(worldX, 4, worldWidth - 4), y: clamp(worldY, -40, this.#game.waterLevel - 4)};
			this.#placeTarget();
		} else if (!this.#game.turn.hasFired && !this.#game.turn.isControlLost) {
			const deltaX = worldX - worm.x;
			const deltaY = worldY - (worm.y - 2);
			if (Math.abs(deltaX) > 2) {
				worm.facing = Math.sign(deltaX);
			}

			worm.aim = clamp((Math.atan2(-deltaY, Math.abs(deltaX)) * 180) / Math.PI, -85, 85);
			this.#camera.isManual = false;
			this.say(`Aimed at ${Math.round(worm.aim)}°. Now hold Space or 🔥 Fire, and let go at the power you want.`);
		}

		this.#afterInput();
	}
}
