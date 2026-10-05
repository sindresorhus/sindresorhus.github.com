// Hover! on the desktop of the 1999 page, like the game of the “Fun Stuff” folder of the Windows 95 CD: a hovercraft that slides through a 3D arena, to collect the blue flags before the red hovercraft of the computer collect the red ones. The arena is drawn with a raycaster, like the 3D Maze screen saver, into the pixels of a canvas of 320 × 200: the sky, the floor, the walls with their tops while the hovercraft jumps, and the flags and the robots as sprites. Nothing makes a sound until the visitor presses the Sound button.

const clamp = (value, minimum, maximum) => Math.min(Math.max(value, minimum), maximum);
const randomItem = items => items[Math.floor(Math.random() * items.length)];

// The camera plane, for a field of view of about 66 degrees.
const planeLength = 0.66;
const mapSize = 20;
const craftRadius = 0.28;
const flagsToWin = 3;

// The arenas, a line of text for each row of cells: `#` and `=` are walls, `S` is a spring, `Z` a speed pad, `B` and `R` the blue and red flags, `W` and `I` the power-ups, and `P`, `G`, and `C` where the player, the robot that grabs flags, and the robot that chases start.
const levels = {
	castle: {
		name: 'Castle',
		wall: 'brick',
		floor: ['#727272', '#5f5f5f', '#474747'],
		sky: ['#16245c', '#a9c4f5'],
		friction: 1.8,
		grip: 4,
		robotSpeed: 1.3,
		map: `
####################
#P....#.......#...R#
#.##..#.#####.#.#..#
#.#B..Z.....#...#..#
#.#.....#...#.###..#
#.####..#.R.#......#
#.......#####..W...#
#..............##.R#
###.##.#####.#..#..#
#....#.#...#.#..#..#
#.I...S#.BS#.......#
#....#.#...#.####..#
#.##.#.#####.......#
#..#.........#..Z..#
#..#..####...#..#..#
#..#.....#...#..#.B#
#..####..#.###..#..#
#.....Z..#......#..#
#G...#...#.....C#..#
####################
`,
	},
	ice: {
		name: 'Ice Rink',
		wall: 'metal',
		floor: ['#e2f4ff', '#c4e2f7', '#9cc4dc'],
		sky: ['#070b2a', '#5d7bc4'],
		friction: 0.8,
		grip: 2,
		robotSpeed: 1.3,
		map: `
====================
=P.........=......R=
=.=====.==.=.====..=
=.=...=..=...=..=..=
=.=.BS=S.=.Z.=..=..=
=.=...=..=====..I..=
=.=====.........=..=
=.......====.====..=
=..==......=.....=.=
=..=R..==..=..B..=.=
=..=...==..=.....=.=
=..====....=====.=.=
=.........Z........=
=.====.=====.=====.=
=.=..=.=...=.=.....=
=.=W.=.=SB.=S...R..=
=.=..=.=...=.=.....=
=.==.=.=====.=..====
=G.......Z......C..=
====================
`,
	},
	sewer: {
		name: 'Sewer',
		wall: 'slime',
		floor: ['#3d4d2b', '#323f23', '#1f2a16'],
		sky: ['#000000', '#26361c'],
		friction: 1.6,
		grip: 3.5,
		robotSpeed: 1.5,
		map: `
####################
#P.......#........R#
#.######.#.######..#
#.#...#..#.#....#..#
#S#.B.#S...#..R.#..#
#.#..S#.####.####..#
#.#####.....Z......#
#.....W..####.####.#
####.#####.....#...#
#....#...#.###.#.I.#
#....#.B.S.#R..#...#
#....#...#.#...###.#
##.#.#####.#.......#
#..#.......####.####
#.####.###.....Z...#
#.#..#...#.#####...#
#.#B.#...#.#...#...#
#.#S.##.##.#.B.S...#
#G...........#....C#
####################
`,
	},
};

// Colors are packed into the pixels of the canvas, with red in the lowest byte, like `Uint32Array` reads `ImageData` on all computers of today.
const pack = hex => {
	const value = Number.parseInt(hex.slice(1), 16);
	return ((0xFF << 24) | ((value & 0xFF) << 16) | (value & 0xFF_00) | (value >> 16)) >>> 0;
};

// Darker by the factor, for the fog and the shaded sides of the walls.
const shade = (color, factor) => ((0xFF << 24) | ((((color >> 16) & 0xFF) * factor) << 16) | ((((color >> 8) & 0xFF) * factor) << 8) | ((color & 0xFF) * factor)) >>> 0;

// A picture drawn on a small canvas, as its pixels.
const pixelsOf = (size, draw) => {
	const offscreen = document.createElement('canvas');
	offscreen.width = size;
	offscreen.height = size;
	const offscreenContext = offscreen.getContext('2d');
	draw(offscreenContext, size);
	return new Uint32Array(offscreenContext.getImageData(0, 0, size, size).data.buffer);
};

const brickTexture = hue => pixelsOf(64, (texture, size) => {
	texture.fillStyle = `hsl(${hue} 10% 42%)`;
	texture.fillRect(0, 0, size, size);

	for (let row = 0; row < 8; row++) {
		for (let column = -1; column < 4; column++) {
			const x = (column * 16) + (row % 2 === 0 ? 0 : 8);
			texture.fillStyle = `hsl(${hue + ((row * 7 + column * 13) % 10)} 50% ${30 + ((row * 3 + column * 5) % 9)}%)`;
			texture.fillRect(x + 1, (row * 8) + 1, 14, 6);
		}
	}
});

const textures = {
	brick: brickTexture(8),
	slime: brickTexture(95),
	metal: pixelsOf(64, (texture, size) => {
		texture.fillStyle = '#7d93b0';
		texture.fillRect(0, 0, size, size);

		for (const [x, y] of [[0, 0], [32, 0], [0, 32], [32, 32]]) {
			const gradient = texture.createLinearGradient(x, y, x + 32, y + 32);
			gradient.addColorStop(0, '#c9d8ea');
			gradient.addColorStop(1, '#6f86a6');
			texture.fillStyle = gradient;
			texture.fillRect(x + 2, y + 2, 28, 28);
			texture.fillStyle = '#3a4a60';

			for (const [rivetX, rivetY] of [[5, 5], [26, 5], [5, 26], [26, 26]]) {
				texture.fillRect(x + rivetX, y + rivetY, 2, 2);
			}
		}
	}),
	// The wall of the power-up, striped like the barriers of road works.
	barrier: pixelsOf(64, (texture, size) => {
		texture.fillStyle = '#ffd400';
		texture.fillRect(0, 0, size, size);
		texture.fillStyle = '#1a1a1a';

		for (let x = -64; x < 64; x += 16) {
			texture.beginPath();
			texture.moveTo(x, 64);
			texture.lineTo(x + 8, 64);
			texture.lineTo(x + 72, 0);
			texture.lineTo(x + 64, 0);
			texture.fill();
		}
	}),
};

const capColors = {brick: pack('#8a8a80'), slime: pack('#5a6b40'), metal: pack('#dfe8f2'), barrier: pack('#ffe866')};

const flagSprite = color => pixelsOf(32, sprite => {
	sprite.fillStyle = '#d0d0d0';
	sprite.fillRect(7, 1, 2, 31);
	sprite.fillStyle = color;
	sprite.beginPath();
	sprite.moveTo(9, 2);
	sprite.lineTo(30, 9);
	sprite.lineTo(9, 16);
	sprite.fill();
	sprite.fillStyle = 'rgb(255 255 255 / 0.5)';
	sprite.fillRect(9, 7, 12, 3);
});

const craftSprite = (body, isAngry) => pixelsOf(32, sprite => {
	// The skirt of the hovercraft, the body, and the dome, with eyes, as everything in 1995 had eyes.
	sprite.fillStyle = '#202020';
	sprite.fillRect(3, 25, 26, 4);
	sprite.fillStyle = body;
	sprite.beginPath();
	sprite.ellipse(16, 21, 14, 6, 0, 0, Math.PI * 2);
	sprite.fill();
	sprite.fillStyle = '#9fe3ff';
	sprite.beginPath();
	sprite.ellipse(16, 15, 8, 7, 0, Math.PI, 0);
	sprite.fill();
	sprite.fillStyle = '#ffffff';
	sprite.fillRect(10, 18, 5, 5);
	sprite.fillRect(17, 18, 5, 5);
	sprite.fillStyle = '#000000';
	sprite.fillRect(12, 20, 2, 2);
	sprite.fillRect(19, 20, 2, 2);

	if (isAngry) {
		sprite.fillRect(9, 16, 6, 1);
		sprite.fillRect(17, 16, 6, 1);
		sprite.fillStyle = '#ffcc00';
		sprite.fillRect(4, 13, 2, 6);
		sprite.fillRect(26, 13, 2, 6);
	}
});

const sprites = {
	blue: flagSprite('#1e5bff'),
	red: flagSprite('#ff2020'),
	grabber: craftSprite('#e02020', false),
	chaser: craftSprite('#8a2be2', true),
	wall: pixelsOf(32, sprite => {
		sprite.fillStyle = '#ffd400';
		sprite.fillRect(4, 8, 24, 18);
		sprite.fillStyle = '#1a1a1a';

		for (let x = 4; x < 28; x += 8) {
			sprite.fillRect(x, 8, 4, 18);
		}

		sprite.strokeStyle = '#ffffff';
		sprite.strokeRect(4.5, 8.5, 23, 17);
	}),
	ghost: pixelsOf(32, sprite => {
		sprite.fillStyle = 'rgb(240 240 255 / 0.9)';
		sprite.beginPath();
		sprite.arc(16, 13, 10, Math.PI, 0);
		sprite.lineTo(26, 28);
		sprite.lineTo(21, 24);
		sprite.lineTo(16, 28);
		sprite.lineTo(11, 24);
		sprite.lineTo(6, 28);
		sprite.fill();
		sprite.fillStyle = '#000000';
		sprite.fillRect(11, 11, 3, 4);
		sprite.fillRect(18, 11, 3, 4);
	}),
};

const angleDifference = (from, to) => Math.atan2(Math.sin(to - from), Math.cos(to - from));
const formatTime = seconds => `${Math.floor(seconds / 60)}:${String(Math.floor(seconds % 60)).padStart(2, '0')}`;
const keyControls = {ArrowUp: 'forward', w: 'forward', ArrowDown: 'back', s: 'back', ArrowLeft: 'left', a: 'left', ArrowRight: 'right', d: 'right'};

export default class extends GeoCitiesElement {
	#context;
	#loop;
	#controlButtons;

	// The game.
	#state = 'title';
	#levelName = 'castle';
	#level;
	#grid;
	#player;
	#robots;
	#flags;
	#powerUps;
	#droppedWalls;
	#elapsedTime;
	#message;
	#motionBudget = 0;

	#keys = {forward: false, back: false, left: false, right: false};
	// The buttons for touch hold the controls too, apart from the keys, so letting go of one does not let go of the other.
	#held = {forward: false, back: false, left: false, right: false};

	// Drawing. Each frame is drawn into these pixels, then put on the canvas, with the text and the map drawn over them.
	#image;
	#pixels;
	#depths;
	#hits = [];

	connected() {
		const {screen, start, level: levelPicker, sound: soundButton} = this.parts;
		this.#context = screen.getContext('2d');
		this.#image = this.#context.createImageData(screen.width, screen.height);
		this.#pixels = new Uint32Array(this.#image.data.buffer);
		this.#depths = new Float32Array(screen.width);
		this.#controlButtons = [...this.querySelectorAll('[data-hover-control]')];

		// The loop runs only while a round is on, the window is open, the arena is on the screen, and the tab is visible. For visitors who prefer reduced motion, it runs a moment after each key press or tap.
		this.#loop = this.loop(seconds => {
			let step = seconds;

			if (this.reducedMotion) {
				step = Math.min(step, this.#motionBudget);
				this.#motionBudget -= step;
			}

			// Small steps, so a fast hovercraft never passes through a wall.
			while (step > 0 && this.#state === 'playing') {
				const part = Math.min(step, 1 / 120);
				this.#update(part);
				step -= part;
			}

			this.#render();
		}, {while: () => this.#state === 'playing' && (!this.reducedMotion || this.#motionBudget > 0), maximumStep: 0.05});

		this.on(soundButton, 'click', () => {
			const isOn = !this.#isSoundOn;
			soundButton.setAttribute('aria-pressed', String(isOn));

			// The desktop starts its audio in the handler of this click, as browsers only allow sound after one.
			if (isOn) {
				this.#sounds.flag();
			}
		});

		// The keys only steer while the arena has the focus, so they do not steer while the visitor types or plays something else.
		this.on(screen, 'keydown', event => {
			if (event.ctrlKey || event.metaKey || event.altKey) {
				return;
			}

			const control = keyControls[event.key.length === 1 ? event.key.toLowerCase() : event.key];

			if (control) {
				event.preventDefault();
				this.#keys[control] = true;
				this.#nudge();
			} else if (event.key === ' ') {
				event.preventDefault();

				if (!event.repeat) {
					this.#usePowerUp();
				}

				this.#nudge();
			} else if (event.key === 'Enter' && this.#state !== 'playing') {
				event.preventDefault();
				this.#startGame();
			}
		});

		this.on(document, 'keyup', event => {
			const control = keyControls[event.key.length === 1 ? event.key.toLowerCase() : event.key];

			if (control) {
				this.#keys[control] = false;
			}
		});

		this.on(screen, 'blur', () => {
			for (const control of Object.keys(this.#keys)) {
				this.#keys[control] = false;
			}
		});

		this.on(screen, 'pointerdown', () => {
			if (this.#state === 'title') {
				this.#startGame();
			}

			this.#nudge();
		});

		// The buttons for touch steer while a finger holds them. A press of Enter on one steers a moment, for a keyboard.
		for (const button of this.#controlButtons) {
			const control = button.dataset.hoverControl;

			const release = () => {
				if (control !== 'use') {
					this.#held[control] = false;
				}

				delete button.dataset.state;
			};

			this.on(button, 'pointerdown', event => {
				event.preventDefault();
				button.setPointerCapture(event.pointerId);
				button.dataset.state = 'held';

				if (this.#state === 'title') {
					this.#startGame();
				}

				if (control === 'use') {
					this.#usePowerUp();
				} else {
					this.#held[control] = true;
				}

				this.#nudge();
			});

			for (const type of ['pointerup', 'pointercancel', 'lostpointercapture']) {
				this.on(button, type, release);
			}

			this.on(button, 'click', event => {
				if (event.detail !== 0) {
					return;
				}

				if (this.#state === 'title') {
					this.#startGame();
				}

				if (control === 'use') {
					this.#usePowerUp();
				} else {
					this.#held[control] = true;

					this.timeout(300, () => {
						this.#held[control] = false;
					});
				}

				this.#nudge();
			});
		}

		this.on(start, 'click', () => {
			this.#startGame();
			screen.focus();
		});

		this.on(levelPicker, 'change', () => {
			this.#state = 'title';
			this.#level = undefined;
			start.textContent = 'Start';
			this.#render();
			this.say(`${levels[levelPicker.value].name}. Press Start to play.`);
		});

		this.#renderBest();
	}

	// The game only runs while the arena is on the screen.
	get visibilityTarget() {
		return this.parts.screen;
	}

	windowChanged(isOpen) {
		if (isOpen) {
			this.#render();
		} else {
			this.#releaseAll();
		}
	}

	get #isSoundOn() {
		return this.parts.sound.getAttribute('aria-pressed') === 'true';
	}

	// The sounds, made with tones. The audio comes from the desktop, which plays it through the volume of the tray.
	#tone(frequency, start, duration, {type = 'triangle', volume = 0.12, slide} = {}) {
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
		gain.gain.exponentialRampToValueAtTime(volume, time + 0.01);
		gain.gain.exponentialRampToValueAtTime(0.0001, time + duration);
		oscillator.connect(gain).connect(output);
		oscillator.start(time);
		oscillator.stop(time + duration + 0.05);
	}

	#sounds = {
		flag: () => {
			for (const [index, frequency] of [784, 988, 1175, 1568].entries()) {
				this.#tone(frequency, index * 0.07, 0.2, {type: 'square', volume: 0.06});
			}
		},
		stolen: () => {
			this.#tone(440, 0, 0.15, {type: 'square', volume: 0.06});
			this.#tone(330, 0.15, 0.3, {type: 'square', volume: 0.06});
		},
		bump: () => {
			this.#tone(90, 0, 0.18, {type: 'sawtooth', volume: 0.12, slide: 50});
		},
		boing: () => {
			this.#tone(180, 0, 0.45, {type: 'square', volume: 0.06, slide: 720});
		},
		whoosh: () => {
			this.#tone(300, 0, 0.4, {type: 'sawtooth', volume: 0.05, slide: 1400});
		},
		clunk: () => {
			this.#tone(140, 0, 0.12, {type: 'square', volume: 0.1});
			this.#tone(110, 0.08, 0.12, {type: 'square', volume: 0.1});
		},
		spin: () => {
			this.#tone(600, 0, 0.5, {type: 'triangle', volume: 0.08, slide: 150});
		},
		win: () => {
			for (const [index, frequency] of [523.25, 659.25, 783.99, 1046.5].entries()) {
				this.#tone(frequency, index * 0.15, index === 3 ? 0.8 : 0.2, {type: 'square', volume: 0.06});
			}
		},
		lose: () => {
			for (const [index, frequency] of [392, 369.99, 349.23, 329.63].entries()) {
				this.#tone(frequency, index * 0.3, index === 3 ? 0.9 : 0.28, {type: 'sawtooth', volume: 0.06});
			}
		},
	};

	#isHeld(control) {
		return this.#keys[control] || this.#held[control];
	}

	#cellAt(x, y) {
		return this.#grid[Math.floor(y)]?.[Math.floor(x)] ?? '#';
	}

	#isWallCell(x, y) {
		return this.#cellAt(x, y) === '#' || this.#cellAt(x, y) === '=';
	}

	#droppedWallAt(x, y) {
		return this.#droppedWalls.find(wall => wall.x === x && wall.y === y);
	}

	// A cell blocks a hovercraft when it is a wall, a dropped wall, or the edge of the arena. A jumping hovercraft flies over all but the edge.
	#isSolid(x, y, isAirborne = false) {
		if (x <= 0 || y <= 0 || x >= mapSize - 1 || y >= mapSize - 1) {
			return true;
		}

		return !isAirborne && (this.#isWallCell(x, y) || Boolean(this.#droppedWallAt(x, y)));
	}

	#collides(x, y, isAirborne) {
		for (let cellY = Math.floor(y - craftRadius); cellY <= Math.floor(y + craftRadius); cellY++) {
			for (let cellX = Math.floor(x - craftRadius); cellX <= Math.floor(x + craftRadius); cellX++) {
				if (this.#isSolid(cellX, cellY, isAirborne)) {
					const nearestX = clamp(x, cellX, cellX + 1);
					const nearestY = clamp(y, cellY, cellY + 1);

					if (Math.hypot(x - nearestX, y - nearestY) < craftRadius) {
						return true;
					}
				}
			}
		}

		return false;
	}

	#findCells(character) {
		const cells = [];

		for (const [y, row] of this.#grid.entries()) {
			for (const [x, cell] of row.entries()) {
				if (cell === character) {
					cells.push({x, y});
				}
			}
		}

		return cells;
	}

	// A hovercraft faces the first open way from where it starts.
	#startAngle({x, y}) {
		for (const [angle, dx, dy] of [[0, 1, 0], [Math.PI / 2, 0, 1], [Math.PI, -1, 0], [-Math.PI / 2, 0, -1]]) {
			if (!this.#isWallCell(x + dx, y + dy)) {
				return angle;
			}
		}

		return 0;
	}

	#makeCraft(cell) {
		return {x: cell.x + 0.5, y: cell.y + 0.5, angle: this.#startAngle(cell), vx: 0, vy: 0, z: 0, vz: 0, boost: 0, springTime: 0, padCell: ''};
	}

	#startGame() {
		this.#levelName = this.parts.level.value;
		this.#level = levels[this.#levelName];
		this.#grid = this.#level.map.trim().split('\n').map(row => [...row]);
		this.#droppedWalls = [];
		this.#player = {...this.#makeCraft(this.#findCells('P')[0]), powerUp: undefined, invisible: 0};
		this.#robots = [
			{...this.#makeCraft(this.#findCells('G')[0]), kind: 'grabber', stun: 0, path: [], pathTime: 0, bumpTime: 0},
			{...this.#makeCraft(this.#findCells('C')[0]), kind: 'chaser', stun: 0, path: [], pathTime: 0, bumpTime: 0},
		];
		this.#flags = [
			...this.#findCells('B').map(cell => ({...cell, color: 'blue', isTaken: false})),
			...this.#findCells('R').map(cell => ({...cell, color: 'red', isTaken: false})),
		];
		this.#powerUps = [
			...this.#findCells('W').map(cell => ({...cell, kind: 'wall', respawn: 0})),
			...this.#findCells('I').map(cell => ({...cell, kind: 'ghost', respawn: 0})),
		];
		this.#elapsedTime = 0;
		this.#message = {text: 'GO!', time: 1.2};
		this.#state = 'playing';
		this.parts.start.textContent = 'Restart';
		this.say(`${this.#level.name}! Collect ${flagsToWin} blue flags before the red hovercraft gets ${flagsToWin} red ones. The purple one bumps you.${this.reducedMotion ? ' The game moves a moment for each key or tap, as your computer prefers less motion.' : ''}`);
		this.#motionBudget = 0.6;
		this.#loop.start();
		this.#render();
	}

	#flagCount(color) {
		return this.#flags.filter(flag => flag.color === color && flag.isTaken).length;
	}

	#showMessage(text, time = 1) {
		this.#message = {text, time};
	}

	// The way through the arena from a cell to the nearest cell that the test accepts, around the walls, for the robots. The robots cannot jump.
	#findPath(from, isTarget) {
		const start = `${Math.floor(from.x)},${Math.floor(from.y)}`;
		const previous = new Map([[start, undefined]]);
		const queue = [[Math.floor(from.x), Math.floor(from.y)]];

		for (let index = 0; index < queue.length; index++) {
			const [x, y] = queue[index];

			if (isTarget(x, y)) {
				const path = [];
				let key = `${x},${y}`;

				while (key) {
					const [pathX, pathY] = key.split(',').map(Number);
					path.unshift({x: pathX, y: pathY});
					key = previous.get(key);
				}

				return path;
			}

			for (const [dx, dy] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) {
				const key = `${x + dx},${y + dy}`;

				if (!previous.has(key) && !this.#isSolid(x + dx, y + dy)) {
					previous.set(key, `${x},${y}`);
					queue.push([x + dx, y + dy]);
				}
			}
		}

		return [];
	}

	#robotTarget(robot) {
		const player = this.#player;

		if (robot.kind === 'grabber') {
			return (x, y) => this.#flags.some(flag => flag.color === 'red' && !flag.isTaken && flag.x === x && flag.y === y);
		}

		// The bully chases the player, unless the player is invisible. Then it drives to a random place.
		if (player.invisible > 0) {
			robot.wander ??= randomItem(this.#findCells('.'));
			return (x, y) => x === robot.wander.x && y === robot.wander.y;
		}

		robot.wander = undefined;
		return (x, y) => x === Math.floor(player.x) && y === Math.floor(player.y);
	}

	// Moves a hovercraft by its speed, one axis at a time, so it slides along a wall, and bounces off it like a bumper car.
	#moveCraft(craft, step) {
		const isAirborne = craft.z > 0.3;
		let impact = 0;
		const nextX = craft.x + (craft.vx * step);

		if (this.#collides(nextX, craft.y, isAirborne)) {
			impact = Math.max(impact, Math.abs(craft.vx));
			craft.vx *= -0.5;
		} else {
			craft.x = nextX;
		}

		const nextY = craft.y + (craft.vy * step);

		if (this.#collides(craft.x, nextY, isAirborne)) {
			impact = Math.max(impact, Math.abs(craft.vy));
			craft.vy *= -0.5;
		} else {
			craft.y = nextY;
		}

		// The jump: up from a spring, and down again, but a hovercraft that would land on a wall floats until it is past it.
		if (craft.z > 0 || craft.vz > 0) {
			craft.vz -= 9 * step;
			craft.z += craft.vz * step;

			if (craft.z < 0.31 && craft.vz < 0 && this.#collides(craft.x, craft.y, false)) {
				craft.z = 0.31;
				craft.vz = 0;
			} else if (craft.z <= 0) {
				craft.z = 0;
				craft.vz = 0;
			}
		}

		return impact;
	}

	// Thrust, turning, and the slide of a hovercraft: the part of its speed to the side fades slowly, slower still on ice.
	#driveCraft(craft, {thrust, turn}, step, maximumSpeed, acceleration) {
		const isAirborne = craft.z > 0.3;
		craft.angle += turn * 2.8 * step;
		const cosine = Math.cos(craft.angle);
		const sine = Math.sin(craft.angle);
		const push = acceleration * thrust * (isAirborne ? 0.2 : 1);
		craft.vx += cosine * push * step;
		craft.vy += sine * push * step;

		if (!isAirborne) {
			const forward = (craft.vx * cosine) + (craft.vy * sine);
			const side = (craft.vy * cosine) - (craft.vx * sine);
			const forwardAfter = forward * Math.exp(-this.#level.friction * step);
			const sideAfter = side * Math.exp(-this.#level.grip * step);
			craft.vx = (cosine * forwardAfter) - (sine * sideAfter);
			craft.vy = (sine * forwardAfter) + (cosine * sideAfter);
		}

		const speed = Math.hypot(craft.vx, craft.vy);
		const limit = craft.boost > 0 ? maximumSpeed * 1.6 : maximumSpeed;

		if (speed > limit) {
			craft.vx *= limit / speed;
			craft.vy *= limit / speed;
		}

		craft.boost = Math.max(craft.boost - step, 0);
		craft.springTime = Math.max(craft.springTime - step, 0);
	}

	// The pads on the floor: a spring throws my hovercraft up and forward, the way it faces, and a speed pad pushes it. The robots drive over them, as a jump would leave them behind a wall, and a push past a turn would send them back and forth.
	#usePads(craft) {
		const key = `${Math.floor(craft.x)},${Math.floor(craft.y)}`;
		const cell = this.#cellAt(craft.x, craft.y);
		const isNewCell = craft.padCell !== key;
		craft.padCell = key;

		if (craft.z > 0) {
			return;
		}

		if (cell === 'S' && craft.springTime === 0) {
			const speed = Math.max(Math.hypot(craft.vx, craft.vy), 3.4);
			craft.vx = Math.cos(craft.angle) * speed;
			craft.vy = Math.sin(craft.angle) * speed;
			craft.vz = 4.6;
			craft.z = 0.01;
			craft.springTime = 0.6;

			this.#sounds.boing();
			this.#showMessage('BOING!', 0.8);
		} else if (cell === 'Z' && isNewCell) {
			const speed = Math.max(Math.hypot(craft.vx, craft.vy), 5);
			craft.vx = Math.cos(craft.angle) * speed;
			craft.vy = Math.sin(craft.angle) * speed;
			craft.boost = 2.5;

			this.#sounds.whoosh();
			this.#showMessage('ZOOM!', 0.8);
		}
	}

	#steerRobot(robot, step) {
		const player = this.#player;
		robot.pathTime -= step;
		robot.bumpTime = Math.max(robot.bumpTime - step, 0);

		if (robot.pathTime <= 0) {
			robot.pathTime = 0.4;
			robot.path = this.#findPath(robot, this.#robotTarget(robot));
			robot.pathIndex = 1;

			// The bully cannot reach a player behind walls, so it drives around until the player comes out.
			if (robot.kind === 'chaser' && robot.path.length === 0 && Math.hypot(player.x - robot.x, player.y - robot.y) > 1) {
				robot.wander = randomItem(this.#findCells('.'));
				robot.path = this.#findPath(robot, (x, y) => x === robot.wander.x && y === robot.wander.y);
				robot.pathTime = 4;
			}
		}

		if (robot.stun > 0) {
			robot.stun -= step;
			robot.angle += 9 * step;
			return {thrust: 0, turn: 0};
		}

		// After a flag, the flag robot does a little victory dance before it goes for the next one.
		if (robot.rest > 0) {
			robot.rest -= step;
			return {thrust: 0, turn: Math.sin(robot.rest * 12)};
		}

		let waypoint = robot.path[robot.pathIndex];

		while (waypoint && Math.hypot(waypoint.x + 0.5 - robot.x, waypoint.y + 0.5 - robot.y) < 0.4) {
			robot.pathIndex++;
			waypoint = robot.path[robot.pathIndex];
		}

		// At the end of the path, the bully drives right at the player.
		const target = waypoint ? {x: waypoint.x + 0.5, y: waypoint.y + 0.5} : (robot.kind === 'chaser' && player.invisible <= 0 ? player : undefined);

		if (!target) {
			robot.wander = undefined;
			return {thrust: 0, turn: 0};
		}

		const difference = angleDifference(robot.angle, Math.atan2(target.y - robot.y, target.x - robot.x));
		return {thrust: Math.abs(difference) < 0.8 ? 1 : 0.15, turn: clamp(difference * 3, -1, 1)};
	}

	// Two hovercraft that touch bump apart. The bully bumps the player away on purpose, and the player who rams the flag robot fast makes it spin.
	#bumpCrafts() {
		const player = this.#player;

		for (const robot of this.#robots) {
			const dx = player.x - robot.x;
			const dy = player.y - robot.y;
			const distance = Math.hypot(dx, dy);

			if (distance >= 0.6 || distance === 0 || Math.abs(player.z - robot.z) > 0.5) {
				continue;
			}

			const normalX = dx / distance;
			const normalY = dy / distance;
			const playerSpeed = Math.hypot(player.vx, player.vy);

			if (robot.kind === 'chaser' && robot.bumpTime === 0) {
				// The push is faster than the hovercraft can drive, for a moment.
				player.vx += normalX * 4.5;
				player.vy += normalY * 4.5;
				player.boost = Math.max(player.boost, 0.4);
				robot.vx -= normalX * 1.5;
				robot.vy -= normalY * 1.5;
				robot.bumpTime = 1.2;
				this.#sounds.bump();
				this.#showMessage('BUMP!', 0.7);
			} else if (robot.kind === 'grabber' && robot.stun <= 0 && playerSpeed > 1.6) {
				robot.stun = 2.5;
				robot.vx -= normalX * 3;
				robot.vy -= normalY * 3;
				player.vx = (player.vx * 0.3) + (normalX * 1.5);
				player.vy = (player.vy * 0.3) + (normalY * 1.5);
				this.#sounds.spin();
				this.#showMessage('SPIN!', 0.9);
				this.say('You rammed the red hovercraft! It spins for a moment.');
			}

			// They never stay inside each other.
			const overlap = 0.6 - distance;

			if (!this.#collides(player.x + (normalX * overlap), player.y + (normalY * overlap), player.z > 0.3)) {
				player.x += normalX * overlap;
				player.y += normalY * overlap;
			}
		}
	}

	#takeFlags() {
		const player = this.#player;

		for (const flag of this.#flags) {
			if (flag.isTaken) {
				continue;
			}

			if (flag.color === 'blue' && Math.hypot(flag.x + 0.5 - player.x, flag.y + 0.5 - player.y) < 0.55) {
				flag.isTaken = true;
				this.#sounds.flag();
				const count = this.#flagCount('blue');
				const left = flagsToWin - count;
				this.#showMessage(left > 0 ? `FLAG! ${left} TO GO` : 'ALL FLAGS!', 1.2);

				if (left > 0) {
					this.say(`You got a blue flag! ${left} to go.`);
				}
			}

			const grabber = this.#robots[0];

			if (flag.color === 'red' && grabber.stun <= 0 && Math.hypot(flag.x + 0.5 - grabber.x, flag.y + 0.5 - grabber.y) < 0.55) {
				flag.isTaken = true;
				grabber.pathTime = 0;
				grabber.rest = 3;
				this.#sounds.stolen();
				const count = this.#flagCount('red');

				if (count < flagsToWin) {
					this.say(`The red hovercraft got a red flag! That is ${count} of ${flagsToWin}.`);
				}
			}
		}

		if (this.#flagCount('blue') >= flagsToWin) {
			this.#endGame(true);
		} else if (this.#flagCount('red') >= flagsToWin) {
			this.#endGame(false);
		}
	}

	#takePowerUps(step) {
		const player = this.#player;

		for (const powerUp of this.#powerUps) {
			powerUp.respawn = Math.max(powerUp.respawn - step, 0);

			if (powerUp.respawn === 0 && !player.powerUp && Math.hypot(powerUp.x + 0.5 - player.x, powerUp.y + 0.5 - player.y) < 0.5) {
				player.powerUp = powerUp.kind;
				powerUp.respawn = 20;
				this.#sounds.clunk();
				this.say(powerUp.kind === 'wall' ? 'You got a wall! Press Space or ★ to drop it behind you, in the way of the robots.' : 'You got invisibility! Press Space or ★, and the purple bully cannot see you.');
			}
		}

		for (const wall of this.#droppedWalls) {
			wall.time -= step;
		}

		if (this.#droppedWalls.some(wall => wall.time <= 0)) {
			this.#droppedWalls = this.#droppedWalls.filter(wall => wall.time > 0);
		}

		player.invisible = Math.max(player.invisible - step, 0);
	}

	#usePowerUp() {
		const player = this.#player;

		if (this.#state !== 'playing' || !player.powerUp) {
			return;
		}

		if (player.powerUp === 'ghost') {
			player.invisible = 8;
			player.powerUp = undefined;
			this.#robots[1].pathTime = 0;
			this.#showMessage('INVISIBLE!', 1);
			this.#sounds.whoosh();
			return;
		}

		// The wall goes in the cell behind the hovercraft, if nothing is there.
		const x = Math.floor(player.x - Math.cos(player.angle));
		const y = Math.floor(player.y - Math.sin(player.angle));
		const isTaken = [player, ...this.#robots].some(craft => Math.hypot(craft.x - (x + 0.5), craft.y - (y + 0.5)) < 0.8);

		if (this.#isSolid(x, y) || isTaken || this.#flags.some(flag => flag.x === x && flag.y === y && !flag.isTaken)) {
			this.say('No room for a wall behind you here.');
			return;
		}

		this.#droppedWalls.push({x, y, time: 12});
		player.powerUp = undefined;

		for (const robot of this.#robots) {
			robot.pathTime = 0;
		}

		this.#sounds.clunk();
		this.#showMessage('WALL!', 0.8);
	}

	#update(step) {
		const player = this.#player;
		this.#elapsedTime += step;
		const thrust = (this.#isHeld('forward') ? 1 : 0) - (this.#isHeld('back') ? 0.6 : 0);
		const turn = (this.#isHeld('right') ? 1 : 0) - (this.#isHeld('left') ? 1 : 0);
		this.#driveCraft(player, {thrust, turn}, step, 3.2, 7);

		if (this.#moveCraft(player, step) > 1.5) {
			this.#sounds.bump();
		}

		this.#usePads(player);

		for (const robot of this.#robots) {
			this.#driveCraft(robot, this.#steerRobot(robot, step), step, this.#level.robotSpeed, 6);
			this.#moveCraft(robot, step);
		}

		this.#bumpCrafts();
		this.#takePowerUps(step);
		this.#takeFlags();

		if (this.#message) {
			this.#message.time -= step;

			if (this.#message.time <= 0) {
				this.#message = undefined;
			}
		}
	}

	#endGame(isWin) {
		const elapsedTime = this.#elapsedTime;
		this.#state = isWin ? 'won' : 'lost';
		this.#message = undefined;
		this.parts.start.textContent = 'Play Again';

		if (isWin) {
			const best = this.stored('best', {});
			const isRecord = best[this.#levelName] === undefined || elapsedTime < best[this.#levelName];

			if (isRecord) {
				best[this.#levelName] = Math.round(elapsedTime * 10) / 10;
				this.store('best', best);
			}

			this.#sounds.win();
			this.celebrate();
			this.say(`You win! All ${flagsToWin} flags in ${formatTime(elapsedTime)}.${isRecord ? ' A new best time!' : ''} Press Enter or Play Again for another round.`);
			this.#renderBest();
		} else {
			this.#sounds.lose();
			this.say(`The red hovercraft got ${flagsToWin} red flags first. You had ${this.#flagCount('blue')}. Press Enter or Play Again to try again.`);
		}

		this.#render();
	}

	#drawWorld() {
		const context = this.#context;
		const pixels = this.#pixels;
		const depths = this.#depths;
		const hits = this.#hits;
		const player = this.#player;
		const level = this.#level;
		const grid = this.#grid;
		const flags = this.#flags;
		const robots = this.#robots;
		const powerUps = this.#powerUps;
		const elapsedTime = this.#elapsedTime;
		const {width, height} = this.#image;
		const horizon = height / 2;
		// The height in pixels of a wall of height 1 at a distance of 1.
		const projection = width / 2 / planeLength;
		const cameraHeight = 0.5 + player.z;
		const directionX = Math.cos(player.angle);
		const directionY = Math.sin(player.angle);
		const planeX = -directionY * planeLength;
		const planeY = directionX * planeLength;
		const [skyTop, skyBottom] = level.sky.map(color => pack(color));
		const [floorLight, floorDark, floorLine] = level.floor.map(color => pack(color));
		const springColors = [pack('#ffcc00'), pack('#ff6a00')];
		const speedColors = [pack('#22cc44'), pack('#bbffbb')];

		// The sky, from dark at the top to light at the horizon.
		for (let y = 0; y < horizon; y++) {
			const mix = y / horizon;
			const color = ((0xFF << 24)
				| ((((skyTop >> 16) & 0xFF) * (1 - mix)) + (((skyBottom >> 16) & 0xFF) * mix)) << 16
				| ((((skyTop >> 8) & 0xFF) * (1 - mix)) + (((skyBottom >> 8) & 0xFF) * mix)) << 8
				| (((skyTop & 0xFF) * (1 - mix)) + ((skyBottom & 0xFF) * mix))) >>> 0;
			pixels.fill(color, y * width, (y + 1) * width);
		}

		// The floor, one row at a time: each row is at one distance, like the floors of the games of the time.
		for (let y = horizon; y < height; y++) {
			const rowDistance = cameraHeight * projection / (y - horizon + 0.5);
			const fog = Math.max(1 - (rowDistance / 14), 0.25);
			let floorX = player.x + (rowDistance * (directionX - planeX));
			let floorY = player.y + (rowDistance * (directionY - planeY));
			const stepX = rowDistance * 2 * planeX / width;
			const stepY = rowDistance * 2 * planeY / width;

			for (let x = 0; x < width; x++) {
				const cellX = Math.floor(floorX);
				const cellY = Math.floor(floorY);
				const fractionX = floorX - cellX;
				const fractionY = floorY - cellY;
				const cell = grid[cellY]?.[cellX];
				let color;

				// Past the edge of the arena, the floor is the color of the horizon, so it meets the sky.
				if (cell === undefined) {
					pixels[(y * width) + x] = skyBottom;
					floorX += stepX;
					floorY += stepY;
					continue;
				}

				if (cell === 'S') {
					color = springColors[((fractionX - 0.5) ** 2) + ((fractionY - 0.5) ** 2) < 0.1 ? 1 : 0];
				} else if (cell === 'Z') {
					color = speedColors[((fractionX + fractionY) * 3) % 1 < 0.5 ? 0 : 1];
				} else if (fractionX < 0.05 || fractionY < 0.05) {
					color = floorLine;
				} else {
					color = (cellX + cellY) % 2 === 0 ? floorLight : floorDark;
				}

				pixels[(y * width) + x] = shade(color, fog);
				floorX += stepX;
				floorY += stepY;
			}
		}

		// The walls, one column at a time. While the hovercraft jumps above the walls, the walls behind them and their tops show too.
		for (let x = 0; x < width; x++) {
			const cameraX = ((2 * x) / width) - 1;
			const rayX = directionX + (planeX * cameraX);
			const rayY = directionY + (planeY * cameraX);
			let mapX = Math.floor(player.x);
			let mapY = Math.floor(player.y);
			const deltaX = rayX === 0 ? 1e9 : Math.abs(1 / rayX);
			const deltaY = rayY === 0 ? 1e9 : Math.abs(1 / rayY);
			const stepX = rayX < 0 ? -1 : 1;
			const stepY = rayY < 0 ? -1 : 1;
			let sideX = (rayX < 0 ? player.x - mapX : mapX + 1 - player.x) * deltaX;
			let sideY = (rayY < 0 ? player.y - mapY : mapY + 1 - player.y) * deltaY;
			let current;
			hits.length = 0;

			for (let index = 0; index < 64; index++) {
				let side;

				if (sideX < sideY) {
					sideX += deltaX;
					mapX += stepX;
					side = 0;
				} else {
					sideY += deltaY;
					mapY += stepY;
					side = 1;
				}

				if (mapX < 0 || mapY < 0 || mapX >= mapSize || mapY >= mapSize) {
					break;
				}

				const dropped = this.#droppedWallAt(mapX, mapY);
				const texture = dropped ? 'barrier' : (this.#isWallCell(mapX, mapY) ? level.wall : undefined);

				if (!texture) {
					current = undefined;
					continue;
				}

				// A wall of several cells is one hit, with its top to where the ray leaves the last cell.
				if (current?.texture === texture) {
					current.exit = Math.min(sideX, sideY);
					continue;
				}

				const distance = side === 0 ? sideX - deltaX : sideY - deltaY;
				const along = side === 0 ? player.y + (distance * rayY) : player.x + (distance * rayX);
				current = {distance, exit: Math.min(sideX, sideY), side, u: along - Math.floor(along), texture};
				hits.push(current);

				if (cameraHeight <= 1 || hits.length >= 4) {
					break;
				}
			}

			depths[x] = hits[0]?.distance ?? 1e9;

			for (let index = hits.length - 1; index >= 0; index--) {
				const hit = hits[index];
				const distance = Math.max(hit.distance, 0.05);
				const lineHeight = projection / distance;
				const top = horizon - ((1 - cameraHeight) * lineHeight);
				const bottom = horizon + (cameraHeight * lineHeight);
				const texture = textures[hit.texture];
				const textureX = Math.floor(hit.u * 64) & 63;
				const fog = Math.max(1 - (distance / 14), 0.25) * (hit.side === 1 ? 0.78 : 1);

				for (let y = Math.max(Math.ceil(top), 0); y <= Math.min(Math.floor(bottom), height - 1); y++) {
					const textureY = Math.floor((y - top) / (bottom - top) * 64) & 63;
					pixels[(y * width) + x] = shade(texture[(textureY * 64) + textureX], fog);
				}

				// The top of the wall, seen from above.
				if (cameraHeight > 1) {
					const farTop = horizon - ((1 - cameraHeight) * projection / Math.max(hit.exit, 0.05));
					const capColor = shade(capColors[hit.texture], fog);

					for (let y = Math.max(Math.ceil(farTop), 0); y < Math.min(top, height); y++) {
						pixels[(y * width) + x] = capColor;
					}
				}
			}
		}

		// The flags, the robots, and the power-ups, far ones first, only where no wall is in front of them.
		const things = [
			...flags.filter(flag => !flag.isTaken).map(flag => ({x: flag.x + 0.5, y: flag.y + 0.5, sprite: sprites[flag.color], size: 0.9, base: 0})),
			...robots.map(robot => ({x: robot.x, y: robot.y, sprite: sprites[robot.kind], size: 0.75, base: 0.05 + robot.z + (Math.sin((elapsedTime * 6) + robot.x) * 0.02)})),
			...powerUps.filter(powerUp => powerUp.respawn === 0).map(powerUp => ({x: powerUp.x + 0.5, y: powerUp.y + 0.5, sprite: sprites[powerUp.kind], size: 0.45, base: 0.2 + (Math.sin(elapsedTime * 3) * 0.05)})),
		];
		const inverse = 1 / ((planeX * directionY) - (directionX * planeY));
		const projected = things.map(thing => {
			const dx = thing.x - player.x;
			const dy = thing.y - player.y;
			return {...thing, sideways: inverse * ((directionY * dx) - (directionX * dy)), depth: inverse * ((-planeY * dx) + (planeX * dy))};
		}).filter(thing => thing.depth > 0.15).sort((first, second) => second.depth - first.depth);

		for (const thing of projected) {
			const screenX = (width / 2) * (1 + (thing.sideways / thing.depth));
			const scale = projection / thing.depth;
			const bottom = horizon + ((cameraHeight - thing.base) * scale);
			const top = bottom - (thing.size * scale);
			const spriteWidth = thing.size * scale;
			const fog = Math.max(1 - (thing.depth / 14), 0.3);
			const left = screenX - (spriteWidth / 2);

			for (let x = Math.max(Math.floor(left), 0); x < Math.min(Math.ceil(left + spriteWidth), width); x++) {
				if (thing.depth >= depths[x]) {
					continue;
				}

				const textureX = Math.floor((x - left) / spriteWidth * 32);

				if (textureX < 0 || textureX > 31) {
					continue;
				}

				for (let y = Math.max(Math.ceil(top), 0); y < Math.min(bottom, height); y++) {
					const texel = thing.sprite[(Math.floor((y - top) / (bottom - top) * 32) * 32) + textureX];

					if (texel >>> 24 > 127) {
						pixels[(y * width) + x] = shade(texel, fog);
					}
				}
			}
		}

		context.putImageData(this.#image, 0, 0);
	}

	#drawText(text, x, y, {size = 10, color = '#ffffff', align = 'left'} = {}) {
		const context = this.#context;
		context.font = `bold ${size}px system-ui, sans-serif`;
		context.textAlign = align;
		context.textBaseline = 'top';
		context.fillStyle = '#000000';
		context.fillText(text, x + 1, y + 1);
		context.fillStyle = color;
		context.fillText(text, x, y);
	}

	#drawHud() {
		const context = this.#context;
		const player = this.#player;
		const {width, height} = this.#image;

		// The nose of my hovercraft, at the bottom of the view.
		context.fillStyle = player.invisible > 0 ? 'rgb(30 91 255 / 0.4)' : '#1e5bff';
		context.beginPath();
		context.moveTo(110, height);
		context.lineTo(150, height - 14);
		context.lineTo(170, height - 14);
		context.lineTo(210, height);
		context.fill();
		context.fillStyle = '#9fe3ff';
		context.fillRect(152, height - 12, 16, 4);

		// The flags of both teams, as squares that fill in.
		for (const [row, color, fill] of [[0, 'blue', '#3d7bff'], [1, 'red', '#ff3b3b']]) {
			this.#drawText(row === 0 ? 'YOU' : 'BOTS', 4, 4 + (row * 12), {size: 9, color: fill});
			const count = this.#flagCount(color);

			for (let index = 0; index < flagsToWin; index++) {
				context.fillStyle = index < count ? fill : 'rgb(0 0 0 / 0.5)';
				context.fillRect(32 + (index * 10), 5 + (row * 12), 8, 8);
				context.strokeStyle = fill;
				context.strokeRect(32.5 + (index * 10), 5.5 + (row * 12), 7, 7);
			}
		}

		this.#drawText(formatTime(this.#elapsedTime), width / 2, 4, {align: 'center'});

		if (player.powerUp) {
			this.#drawText(`★ ${player.powerUp === 'wall' ? 'WALL' : 'GHOST'} (Space)`, 4, height - 14, {size: 9, color: '#ffd400'});
		}

		if (player.invisible > 0) {
			this.#drawText(`INVISIBLE ${Math.ceil(player.invisible)}`, 4, height - 26, {size: 9, color: '#e0d0ff'});
		}

		// The map, in the corner.
		const cell = 3;
		const mapLeft = width - (mapSize * cell) - 3;
		const mapTop = 3;
		context.fillStyle = 'rgb(0 0 0 / 0.55)';
		context.fillRect(mapLeft - 1, mapTop - 1, (mapSize * cell) + 2, (mapSize * cell) + 2);

		for (const [y, row] of this.#grid.entries()) {
			for (const [x, character] of row.entries()) {
				if (character === '#' || character === '=') {
					context.fillStyle = '#9a9a9a';
					context.fillRect(mapLeft + (x * cell), mapTop + (y * cell), cell, cell);
				}
			}
		}

		context.fillStyle = '#ffd400';

		for (const wall of this.#droppedWalls) {
			context.fillRect(mapLeft + (wall.x * cell), mapTop + (wall.y * cell), cell, cell);
		}

		for (const flag of this.#flags.filter(flag => !flag.isTaken)) {
			context.fillStyle = flag.color === 'blue' ? '#3d7bff' : '#ff3b3b';
			context.fillRect(mapLeft + (flag.x * cell), mapTop + (flag.y * cell), cell, cell);
		}

		for (const robot of this.#robots) {
			context.fillStyle = robot.kind === 'grabber' ? '#ff8080' : '#d080ff';
			context.fillRect(mapLeft + (robot.x * cell) - 1.5, mapTop + (robot.y * cell) - 1.5, 3, 3);
		}

		context.fillStyle = '#ffffff';
		context.fillRect(mapLeft + (player.x * cell) - 1.5, mapTop + (player.y * cell) - 1.5, 3, 3);
		context.strokeStyle = '#ffffff';
		context.beginPath();
		context.moveTo(mapLeft + (player.x * cell), mapTop + (player.y * cell));
		context.lineTo(mapLeft + ((player.x + (Math.cos(player.angle) * 1.6)) * cell), mapTop + ((player.y + (Math.sin(player.angle) * 1.6)) * cell));
		context.stroke();

		if (this.#message) {
			this.#drawText(this.#message.text, width / 2, 70, {size: 20, color: '#ffe14d', align: 'center'});
		}
	}

	// The title, and the end of a round, over a darker arena.
	#drawScreen(title, lines) {
		const context = this.#context;
		const {width, height} = this.#image;
		context.fillStyle = 'rgb(0 0 30 / 0.65)';
		context.fillRect(0, 0, width, height);
		const gradient = context.createLinearGradient(0, 40, 0, 80);
		gradient.addColorStop(0, '#ffe14d');
		gradient.addColorStop(1, '#ff6a00');
		this.#drawText(title, width / 2, 36, {size: 34, color: gradient, align: 'center'});

		for (const [index, line] of lines.entries()) {
			this.#drawText(line, width / 2, 92 + (index * 15), {size: 10, align: 'center'});
		}
	}

	#render() {
		if (!this.#level) {
			this.#levelName = this.parts.level.value;
			this.#level = levels[this.#levelName];
			this.#grid = this.#level.map.trim().split('\n').map(row => [...row]);
			this.#droppedWalls = [];
			this.#player = {...this.#makeCraft(this.#findCells('P')[0]), powerUp: undefined, invisible: 0};
			this.#robots = [];
			this.#flags = this.#findCells('B').map(cell => ({...cell, color: 'blue', isTaken: false}));
			this.#powerUps = [];
			this.#elapsedTime = 0;
		}

		this.#drawWorld();

		if (this.#state === 'title') {
			this.#drawScreen('HOVER!', [this.#level.name, 'Get 3 blue flags before the robots get 3 red ones.', 'Arrows or WASD steer, Space uses a power-up.', 'Press Enter or tap Start!']);
			return;
		}

		this.#drawHud();

		if (this.#state === 'won') {
			this.#drawScreen('YOU WIN!', [`All ${flagsToWin} flags in ${formatTime(this.#elapsedTime)}`, 'Press Enter or tap Play Again']);
		} else if (this.#state === 'lost') {
			this.#drawScreen('GAME OVER', ['The robots got their flags first.', 'Bump the red one to make it spin!', 'Press Enter or tap Play Again']);
		}
	}

	#renderBest() {
		const best = this.stored('best', {});
		const times = Object.entries(levels).filter(([name]) => best[name] !== undefined).map(([name, {name: title}]) => `${title} ${formatTime(best[name])}`);
		this.parts.best.textContent = times.length > 0 ? `Best times: ${times.join(', ')}.` : 'On a phone, hold the buttons under the arena to steer.';
	}

	// For visitors who prefer reduced motion, a key press or tap lets the game run a moment.
	#nudge() {
		if (this.reducedMotion) {
			this.#motionBudget = Math.min(this.#motionBudget + 0.4, 0.8);
		}

		this.#loop.start();
	}

	#releaseAll() {
		for (const control of Object.keys(this.#keys)) {
			this.#keys[control] = false;
			this.#held[control] = false;
		}

		for (const button of this.#controlButtons) {
			delete button.dataset.state;
		}
	}
}
