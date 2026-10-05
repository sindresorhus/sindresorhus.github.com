// 3D Pinball for Windows, Space Cadet, on the desktop of the 1999 page: a table in space with a plunger, two flippers, three attack bumpers, slingshots, the re-entry lanes, drop targets, a launch ramp, and a hyperspace hole. Missions promote the player from Cadet to Fleet Admiral, like in Space Cadet. The ball moves in small fixed steps, many for each frame, so it never goes through a flipper or a wall. The table runs only while its window is open, on the screen, and the tab is visible.
const clamp = (value, minimum, maximum) => Math.min(Math.max(value, minimum), maximum);
const formatScore = number => number.toLocaleString('en-US');

// The table is 200 × 320 units, drawn at twice the size on the canvas, so the lines are sharp.
const width = 200;
const height = 320;
const step = 1 / 480;
const gravity = 430;
const ballRadius = 4.5;
const maximumSpeed = 900;

// The posts between the re-entry lanes at the top, and on each side of the mouth of the launch ramp.
const laneEdges = [63, 83, 103, 123];
const posts = [{x: 130, y: 182, radius: 3, bounce: 0.6}, {x: 154, y: 182, radius: 3, bounce: 0.6}];

const hole = {x: 144, y: 96, radius: 7};

// The launch ramp goes up from its mouth on the right, around the top, and down into the left inlane, over the table.
const rampMouth = {left: 133, right: 151, top: 168, bottom: 186};
const rampPath = [[142, 178], [158, 128], [160, 70], [140, 30], [100, 20], [56, 28], [26, 60], [16, 120], [22, 180], [26, 222]];
const rampLengths = [];
let rampLength = 0;

for (let index = 1; index < rampPath.length; index++) {
	rampLength += Math.hypot(rampPath[index][0] - rampPath[index - 1][0], rampPath[index][1] - rampPath[index - 1][1]);
	rampLengths.push(rampLength);
}

const pointOnRamp = progress => {
	const distance = progress * rampLength;
	let index = rampLengths.findIndex(length => length >= distance);
	index = index === -1 ? rampLengths.length - 1 : index;
	const start = index === 0 ? 0 : rampLengths[index - 1];
	const fraction = (distance - start) / (rampLengths[index] - start);
	const [x1, y1] = rampPath[index];
	const [x2, y2] = rampPath[index + 1];
	return {x: x1 + ((x2 - x1) * fraction), y: y1 + ((y2 - y1) * fraction)};
};

// The flippers turn around their pivots. An angle of 0 points straight to the middle, and a positive angle points down. They swing up fast, so they hit the ball hard.
const flipperLength = 30;
const restAngle = 32 * Math.PI / 180;
const upAngle = -26 * Math.PI / 180;

const worldAngleOf = flipper => (flipper.side === 'left' ? flipper.angle : Math.PI - flipper.angle);

const flipperTip = flipper => ({
	x: flipper.pivot.x + (flipperLength * Math.cos(flipper.worldAngle)),
	y: flipper.pivot.y + (flipperLength * Math.sin(flipper.worldAngle)),
});

// The flipper is thick at its pivot and thin at its tip.
const flipperRadius = along => 5.5 - (2.5 * along);

// The parts of the table that light up, fall, or move: the walls with the slingshots, the bumpers, the drop targets, and the flippers.
const makeTable = () => {
	// The walls of the table, as segments with a radius, and the posts, as circles. The ellipse at the top is the arch that the plunger shoots the ball around.
	const walls = [];

	const wall = (x1, y1, x2, y2, options = {}) => {
		const segment = {a: {x: x1, y: y1}, b: {x: x2, y: y2}, radius: 0, bounce: 0.45, ...options};
		walls.push(segment);
		return segment;
	};

	const polyline = (points, options) => {
		for (let index = 0; index < points.length - 1; index++) {
			wall(...points[index], ...points[index + 1], options);
		}
	};

	const arch = [];

	for (let index = 0; index <= 72; index++) {
		const angle = Math.PI + (Math.PI * index / 72);
		arch.push([100 + (94 * Math.cos(angle)), 72 + (66 * Math.sin(angle))]);
	}

	polyline(arch, {bounce: 0.3});
	wall(6, 72, 6, 340);
	wall(194, 72, 194, 340);
	// The plunger lane, with the floor that the plunger is, and a gate at its top that only lets the ball out.
	wall(180, 104, 180, 340, {radius: 1});
	wall(180, 306, 194, 306);
	wall(194, 88, 180, 104, {oneWay: true, bounce: 0.3});
	// The fuel lane on the left, which is closed at the top, so a ball that the plunger shoots around the arch bounces back into the table. The guides at the bottom of the sides send the ball into the inlanes.
	wall(30, 26, 30, 176, {radius: 1.5});
	wall(6, 184, 22, 206, {bounce: 0.3});
	wall(180, 184, 164, 206, {bounce: 0.3});
	// The inlanes, which lead to the flippers, and the outlanes outside of them, which drain.
	polyline([[18, 220], [18, 258], [52, 285]], {radius: 1.5});
	polyline([[168, 220], [168, 258], [134, 285]], {radius: 1.5});
	// The slingshots above the flippers. Their long edge kicks the ball away.
	const slingshots = [
		wall(38, 226, 56, 270, {radius: 1.5, kick: 'left', bounce: 0.5}),
		wall(148, 226, 130, 270, {radius: 1.5, kick: 'right', bounce: 0.5}),
	];
	polyline([[38, 226], [38, 256], [56, 270]], {radius: 1.5});
	polyline([[148, 226], [148, 256], [130, 270]], {radius: 1.5});

	for (const x of laneEdges) {
		wall(x, 40, x, 54, {radius: 1.5});
	}

	const bumpers = [
		{x: 66, y: 110, radius: 9, flash: 0},
		{x: 114, y: 110, radius: 9, flash: 0},
		{x: 90, y: 146, radius: 9, flash: 0},
	];

	// The drop targets on the wall of the lane on the left. Each stands in front of the wall until the ball knocks it down.
	const targets = [120, 138, 156].map(y => ({
		segment: {a: {x: 33, y: y - 7}, b: {x: 33, y: y + 7}, radius: 1.5, bounce: 0.4},
		isUp: true,
		flash: 0,
	}));

	const flippers = [
		{side: 'left', pivot: {x: 58, y: 288}, angle: restAngle, worldAngle: 0, spin: 0, isPressed: false},
		{side: 'right', pivot: {x: 128, y: 288}, angle: restAngle, worldAngle: 0, spin: 0, isPressed: false},
	];

	for (const flipper of flippers) {
		flipper.worldAngle = worldAngleOf(flipper);
	}

	return {walls, slingshots, bumpers, targets, flippers};
};

// The ranks and the missions of Space Cadet. Each mission promotes the player one rank.
const ranks = ['Cadet', 'Ensign', 'Lieutenant', 'Captain', 'Lt. Commander', 'Commander', 'Commodore', 'Admiral', 'Fleet Admiral'];
const missions = [
	{name: 'Target Practice', task: 'Hit the attack bumpers', event: 'bumper', goal: 8},
	{name: 'Launch Training', task: 'Shoot the launch ramp', event: 'ramp', goal: 3},
	{name: 'Re-Entry Training', task: 'Pass the re-entry lanes at the top', event: 'lane', goal: 3},
	{name: 'Science', task: 'Knock down all three drop targets', event: 'bank', goal: 1},
	{name: 'Black Hole', task: 'Shoot the ball into the hyperspace hole', event: 'hole', goal: 2},
	{name: 'Space Radiation', task: 'Hit the attack bumpers', event: 'bumper', goal: 20},
	{name: 'Brunost Delivery', task: 'Shoot the launch ramp to deliver brown cheese to the space station', event: 'ramp', goal: 4},
	{name: 'Refueling', task: 'Shoot the ball up the fuel lane on the left', event: 'fuel', goal: 2},
	{name: 'Satellite Retrieval', task: 'Pass the re-entry lanes at the top', event: 'lane', goal: 6},
	{name: 'Doomsday Machine', task: 'Shoot the ball into the hyperspace hole', event: 'hole', goal: 3},
];

// The panel is shown every frame, so it only writes the texts that changed.
const setText = (element, text) => {
	if (element.textContent !== text) {
		element.textContent = text;
	}
};

// The collisions. Each pushes the ball out of what it hit, and bounces it off with the speed of the surface, like the flippers that move.
const closestOnSegment = (point, a, b) => {
	const dx = b.x - a.x;
	const dy = b.y - a.y;
	const along = clamp((((point.x - a.x) * dx) + ((point.y - a.y) * dy)) / ((dx * dx) + (dy * dy)), 0, 1);
	return {x: a.x + (dx * along), y: a.y + (dy * along), along};
};

const neon = '#4fe3ff';

const label = (target, text, x, y, {angle = 0, color = '#ffd23f', size = 6} = {}) => {
	target.save();
	target.translate(x, y);
	target.rotate(angle);
	target.font = `bold ${size}px "Courier New", monospace`;
	target.textAlign = 'center';
	target.fillStyle = color;
	target.fillText(text, 0, 0);
	target.restore();
};

// With reduced motion, the table only moves for a moment after each key or tap.
const motionPause = 0.6;

const keyControls = {
	z: 'left',
	Z: 'left',
	ArrowLeft: 'left',
	'/': 'right',
	ArrowRight: 'right',
	' ': 'launch',
	ArrowDown: 'launch',
	Enter: 'launch',
};

const codeControls = {ShiftLeft: 'left', ShiftRight: 'right'};
const nudgeKeys = {x: 1, X: 1, '.': -1, ArrowUp: 0};

export default class extends GeoCitiesElement {
	#context;
	#scale;
	#loop;
	#highScore;
	#gameOverTime = 0;
	#isSoundOn = false;
	#isPaused = false;
	#runUntil = 0;
	#table = makeTable();

	// The drawing. The table is drawn once on its own canvas, and each frame adds the lights, the flippers, and the ball.
	#tableCanvas = document.createElement('canvas');
	#isTableDrawn = false;
	#rampCanvas = document.createElement('canvas');

	// The state of the game, and of the ball. The clock only runs while the table runs, so the ball save and the tilt do not count the time of a pause.
	#game = {
		isOver: true,
		isStarted: false,
		score: 0,
		ball: 1,
		balls: 3,
		rank: 0,
		mission: 0,
		round: 0,
		progress: 0,
		missionsDone: 0,
		multiplier: 1,
		lanes: [false, false, false],
		bonus: 0,
		ramps: 0,
		fuel: 0,
		holeBonus: 20_000,
		isTilted: false,
		nudges: [],
		clock: 0,
		ballSaveUntil: 0,
		isSaveReady: true,
		skillLane: 1,
		skillShotUntil: 0,
		message: '',
		messageUntil: 0,
	};

	#ball = {x: 189, y: 301.5, vx: 0, vy: 0, mode: 'plunger', rampProgress: 0, holeTime: 0, stillTime: 0, previousY: 301.5};
	#plunger = {pull: 0, isPulling: false};

	// The lights that go out a moment after they are all lit wait for the clock of the game, so they wait during a pause too.
	#timers = [];

	connected() {
		const {table: canvas, newGame, sound} = this.parts;
		this.#context = canvas.getContext('2d');
		this.#scale = canvas.width / width;
		this.#tableCanvas.width = canvas.width;
		this.#tableCanvas.height = canvas.height;
		this.#rampCanvas.width = canvas.width;
		this.#rampCanvas.height = canvas.height;
		this.#highScore = this.stored('high', 0);
		this.#showHighScore();

		// The loop runs only while the window is open, the table is on the screen, and the tab is visible. With reduced motion, the table only moves for a moment after each key or tap.
		this.#loop = this.loop(seconds => {
			this.#update(seconds);
			this.#draw();
		}, {
			while: () => !this.#isPaused && this.#game.isStarted && !this.#game.isOver && (!this.reducedMotion || performance.now() < this.#runUntil),
			maximumStep: 0.05,
		});

		this.on(sound, 'click', () => {
			this.#isSoundOn = !this.#isSoundOn;
			sound.setAttribute('aria-pressed', String(this.#isSoundOn));

			// The first sound starts the audio of the desktop, which only starts in a click.
			if (this.#isSoundOn) {
				this.#sounds.ramp();
			}
		});

		// The keys only work while the focus is on the table or its window, so they do not take the keys of the buttons and the other games.
		const appWindow = this.desktopWindow;
		const isTableFocused = event => event.target === canvas || event.target === appWindow;

		this.on(appWindow, 'keydown', event => {
			if (!isTableFocused(event) || event.ctrlKey || event.altKey || event.metaKey) {
				return;
			}

			if (event.key === 'F2') {
				event.preventDefault();
				this.#newGame();
				return;
			}

			const control = codeControls[event.code] ?? keyControls[event.key];

			if (control) {
				event.preventDefault();

				if (!event.repeat) {
					this.#press(control);
				}

				return;
			}

			if (event.key in nudgeKeys) {
				event.preventDefault();

				if (!event.repeat) {
					this.#resume();
					this.#nudge(nudgeKeys[event.key]);
				}

				return;
			}

			if (event.key === 'p' || event.key === 'P' || event.key === 'F3') {
				event.preventDefault();

				if (this.#isPaused) {
					this.#resume();
				} else {
					this.#pause();
				}
			}
		});

		this.on(appWindow, 'keyup', event => {
			const control = codeControls[event.code] ?? keyControls[event.key];

			if (control) {
				this.#release(control);
			}
		});

		// A key that is let go while the focus is elsewhere would leave a flipper up.
		this.on(canvas, 'blur', () => {
			this.#releaseAll();
		});

		// A finger or the mouse on the left or the right half of the table flips that flipper, and holding the bottom of the plunger lane pulls the plunger.
		const pointerControls = new Map();

		this.on(canvas, 'pointerdown', event => {
			if (event.button !== 0) {
				return;
			}

			event.preventDefault();
			canvas.focus();
			const game = this.#game;

			// A tap on the table starts a game, but not right after the last ball, when the visitor may still be flipping.
			if (!game.isStarted || (game.isOver && performance.now() - this.#gameOverTime > 1500)) {
				this.#newGame();
				return;
			}

			if (game.isOver) {
				return;
			}

			const box = canvas.getBoundingClientRect();
			const x = (event.clientX - box.left) / box.width;
			const y = (event.clientY - box.top) / box.height;
			const control = x > 0.88 && y > 0.7 && this.#ball.mode === 'plunger' ? 'launch' : (x < 0.5 ? 'left' : 'right');
			pointerControls.set(event.pointerId, control);
			canvas.setPointerCapture(event.pointerId);
			this.#press(control);
		});

		for (const type of ['pointerup', 'pointercancel']) {
			this.on(canvas, type, event => {
				const control = pointerControls.get(event.pointerId);

				if (control) {
					pointerControls.delete(event.pointerId);
					this.#release(control);
				}
			});
		}

		for (const button of this.querySelectorAll('[data-pinball-control]')) {
			const control = button.dataset.pinballControl;

			this.on(button, 'pointerdown', event => {
				if (event.button !== 0) {
					return;
				}

				event.preventDefault();
				button.setPointerCapture(event.pointerId);
				button.dataset.state = 'down';
				this.#press(control);
			});

			for (const type of ['pointerup', 'pointercancel']) {
				this.on(button, type, () => {
					if (button.dataset.state === 'down') {
						delete button.dataset.state;
						this.#release(control);
					}
				});
			}

			// Enter or Space on a button flips for a moment, or launches with a little more than half of the power.
			this.on(button, 'click', event => {
				if (event.detail !== 0) {
					return;
				}

				this.#press(control);

				if (control === 'launch' && this.#plunger.isPulling) {
					this.#plunger.pull = 0.6;
				}

				this.timeout(control === 'launch' ? 50 : 150, () => {
					this.#release(control);
				});
			});
		}

		this.on(newGame, 'click', () => {
			this.#newGame();
			canvas.focus();
		});

		this.#draw();
	}

	get visibilityTarget() {
		return this.parts.table;
	}

	visibilityChanged(isVisible) {
		if (isVisible) {
			this.#loop.requestStep();
		} else {
			this.#pause();
		}
	}

	reducedMotionChanged() {
		this.#runUntil = performance.now() + (motionPause * 1000);
		this.#loop.requestStep();
	}

	windowChanged(isOpen) {
		if (isOpen) {
			this.parts.table.focus();
			this.#draw();

			if (!this.#game.isStarted) {
				this.say(`Press F2 or New Game to start.${this.reducedMotion ? ' The table moves for a moment after each key or tap, as your computer prefers less motion.' : ''}`);
			}
		} else {
			this.#pause();
		}

		this.#run();
	}

	// The sounds, made with oscillators, through the volume of the desktop. They are off until the visitor turns them on.
	#tone(frequency, duration, {type = 'square', volume = 0.08, slide, delay = 0} = {}) {
		const sound = this.#isSoundOn && this.sound();

		if (!sound) {
			return;
		}

		const {context, output} = sound;
		const oscillator = context.createOscillator();
		const gain = context.createGain();
		const time = context.currentTime + delay;
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
		bumper: () => this.#tone(880, 0.12, {slide: 440}),
		sling: () => this.#tone(620, 0.07, {volume: 0.06}),
		flipper: () => this.#tone(140, 0.05, {type: 'triangle', volume: 0.12, slide: 70}),
		target: () => this.#tone(1250, 0.08, {volume: 0.06}),
		lane: () => this.#tone(1568, 0.1, {type: 'sine', volume: 0.08}),
		launch: () => this.#tone(180, 0.35, {type: 'sawtooth', volume: 0.06, slide: 900}),
		drain: () => this.#tone(420, 0.7, {type: 'sawtooth', volume: 0.07, slide: 60}),
		hole: () => this.#tone(900, 0.5, {type: 'sine', volume: 0.1, slide: 120}),
		tilt: () => this.#tone(90, 0.6, {type: 'sawtooth', volume: 0.1}),
		ramp: () => {
			for (const [index, frequency] of [523, 659, 784, 1047].entries()) {
				this.#tone(frequency, 0.12, {type: 'triangle', volume: 0.08, delay: index * 0.07});
			}
		},
		fanfare: () => {
			for (const [index, frequency] of [392, 523, 659, 784, 659, 1047].entries()) {
				this.#tone(frequency, 0.18, {type: 'square', volume: 0.06, delay: index * 0.1});
			}
		},
	};

	#showHighScore() {
		this.parts.high.textContent = `High score: ${formatScore(this.#highScore)}`;
	}

	#later(seconds, run) {
		this.#timers.push({time: this.#game.clock + seconds, run});
	}

	#runTimers() {
		const {clock} = this.#game;
		const due = this.#timers.filter(timer => timer.time <= clock);

		if (due.length > 0) {
			this.#timers = this.#timers.filter(timer => timer.time > clock);

			for (const timer of due) {
				timer.run();
			}
		}
	}

	#missionGoal() {
		const game = this.#game;
		return missions[game.mission].goal + (game.round * Math.ceil(missions[game.mission].goal / 2));
	}

	#showMission() {
		const mission = missions[this.#game.mission];
		const left = this.#missionGoal() - this.#game.progress;
		this.parts.mission.textContent = `Mission: ${mission.name}. ${mission.task}: ${left} more.`;
	}

	#showPanel() {
		const game = this.#game;
		setText(this.parts.score, formatScore(game.score));
		setText(this.parts.ball, `Ball ${Math.min(game.ball, game.balls)} of ${game.balls}`);
		setText(this.parts.rank, `Rank: ${ranks[game.rank]}`);
	}

	// A message on the table and in the status, like the messages of the panel of Space Cadet.
	#showMessage(message, {isImportant = true} = {}) {
		this.#game.message = message;
		this.#game.messageUntil = this.#game.clock + 2.5;

		if (isImportant) {
			this.say(message);
		}
	}

	#addScore(points) {
		if (!this.#game.isTilted && !this.#game.isOver) {
			this.#game.score += points;
		}
	}

	#completeMission() {
		const game = this.#game;
		const mission = missions[game.mission];
		const points = 250_000 + (125_000 * game.rank);
		this.#addScore(points);
		game.missionsDone++;
		const isPromoted = game.rank < ranks.length - 1;

		if (isPromoted) {
			game.rank++;
		}

		game.mission = (game.mission + 1) % missions.length;

		if (game.mission === 0) {
			game.round++;
		}

		game.progress = 0;
		this.#sounds.fanfare();
		let message = `Mission completed: ${mission.name}! ${formatScore(points)} points.${isPromoted ? ` Promotion to ${ranks[game.rank]}!` : ' Fleet Admiral forever!'}`;

		// Every third mission gives an extra ball.
		if (game.missionsDone % 3 === 0) {
			game.balls++;
			message += ' Extra ball!';
		}

		this.#showMessage(message);
		this.#showMission();
	}

	// Counts an event for the mission, like a hit of a bumper.
	#missionEvent(event) {
		const game = this.#game;

		if (game.isTilted || game.isOver || missions[game.mission].event !== event) {
			return;
		}

		game.progress++;

		if (game.progress >= this.#missionGoal()) {
			this.#completeMission();
		} else {
			this.#showMission();
		}
	}

	#serveBall() {
		const ball = this.#ball;
		ball.mode = 'plunger';
		ball.x = 189;
		ball.y = 306 - ballRadius;
		ball.vx = 0;
		ball.vy = 0;
		ball.previousY = ball.y;
		this.#plunger.pull = 0;
		this.#game.isTilted = false;
		this.#game.nudges = [];
		this.#game.skillLane = Math.floor(Math.random() * 3);
		this.#showPanel();
	}

	#newGame() {
		Object.assign(this.#game, {
			isOver: false,
			isStarted: true,
			score: 0,
			ball: 1,
			balls: 3,
			rank: 0,
			mission: 0,
			round: 0,
			progress: 0,
			missionsDone: 0,
			multiplier: 1,
			lanes: [false, false, false],
			bonus: 0,
			ramps: 0,
			fuel: 0,
			holeBonus: 20_000,
			isSaveReady: true,
		});

		this.#timers = [];

		for (const target of this.#table.targets) {
			target.isUp = true;
		}

		this.#serveBall();
		this.#showMission();
		this.#showMessage(`Welcome, Cadet! Hold Space (or Launch) to pull the plunger, and let go.${this.reducedMotion ? ' The table moves for a moment after each key or tap, as your computer prefers less motion.' : ''}`);
		this.#resume();
	}

	#launch() {
		const ball = this.#ball;
		const plunger = this.#plunger;

		if (ball.mode !== 'plunger') {
			plunger.pull = 0;
			return;
		}

		const power = plunger.pull;
		plunger.pull = 0;

		if (power < 0.05) {
			return;
		}

		// The plunger springs back up and throws the ball from the top of the plunger.
		ball.mode = 'free';
		ball.y = 306 - ballRadius;
		ball.vy = -(260 + (430 * power));
		ball.vx = 0;
		// The ball save of Re-Deploy saves each ball once.
		const game = this.#game;
		game.ballSaveUntil = game.isSaveReady ? game.clock + 10 : 0;
		game.skillShotUntil = game.clock + 4;
		this.#sounds.launch();
	}

	#drain() {
		const game = this.#game;
		this.#ball.mode = 'drained';
		this.#sounds.drain();

		if (game.clock < game.ballSaveUntil && !game.isTilted) {
			game.isSaveReady = false;
			game.ballSaveUntil = 0;
			this.#showMessage('Re-Deploy! The ball is saved. Launch it again.');
			this.#serveBall();
			return;
		}

		const bonus = game.isTilted ? 0 : (game.bonus + 5000) * game.multiplier;
		this.#addScore(bonus);
		game.bonus = 0;
		game.multiplier = 1;
		game.ball++;
		game.isSaveReady = true;

		if (game.ball > game.balls) {
			this.#gameOver();
			return;
		}

		this.#showMessage(`${game.isTilted ? 'No bonus after a tilt.' : `Bonus ${formatScore(bonus)}.`} Ball ${game.ball}. Hold Space to launch.`);
		this.#serveBall();
	}

	#gameOver() {
		const game = this.#game;
		game.isOver = true;
		this.#gameOverTime = performance.now();
		const isHighScore = game.score > this.#highScore;

		if (isHighScore) {
			this.#highScore = game.score;
			this.store('high', this.#highScore);
			this.#showHighScore();
		}

		this.#showPanel();
		this.parts.ball.textContent = 'Game over';
		this.parts.mission.textContent = `Final rank: ${ranks[game.rank]}. Press F2 or New Game to play again.`;
		this.#showMessage(`Game over! ${formatScore(game.score)} points, rank ${ranks[game.rank]}.${isHighScore ? ' A new high score!' : ''}`);
		this.#draw();
	}

	// Nudging moves the ball a little. Too many nudges in a short time tilt the table, which turns off the flippers until the ball drains.
	#nudge(direction) {
		const game = this.#game;
		const ball = this.#ball;

		if (game.isOver || game.isTilted || ball.mode !== 'free') {
			return;
		}

		ball.vx += direction * 45;
		ball.vy -= 55;
		game.nudges = game.nudges.filter(time => game.clock - time < 4);
		game.nudges.push(game.clock);

		if (game.nudges.length >= 4) {
			game.isTilted = true;

			for (const flipper of this.#table.flippers) {
				flipper.isPressed = false;
			}

			this.#sounds.tilt();
			this.#showMessage('TILT! The flippers are off until the ball drains.');
		} else if (game.nudges.length === 3) {
			this.#showMessage('Danger! One more nudge, and the table tilts.');
		}
	}

	// The friction slows the ball along the surface by a part of how hard it hits, so a ball that rolls along a wall, like the arch, keeps its speed, and a hard hit takes the spin off.
	#bounceOff(normalX, normalY, bounce, surfaceX = 0, surfaceY = 0, friction = 0.1) {
		const ball = this.#ball;
		const relativeX = ball.vx - surfaceX;
		const relativeY = ball.vy - surfaceY;
		const normalSpeed = (relativeX * normalX) + (relativeY * normalY);

		if (normalSpeed >= 0) {
			return 0;
		}

		const tangentX = relativeX - (normalSpeed * normalX);
		const tangentY = relativeY - (normalSpeed * normalY);
		const tangentSpeed = Math.hypot(tangentX, tangentY);
		const keep = tangentSpeed > 0 ? Math.max(1 - (friction * (1 + bounce) * -normalSpeed / tangentSpeed), 0) : 0;
		ball.vx = surfaceX + (tangentX * keep) - (bounce * normalSpeed * normalX);
		ball.vy = surfaceY + (tangentY * keep) - (bounce * normalSpeed * normalY);
		return -normalSpeed;
	}

	#collideSegment(segment) {
		const ball = this.#ball;
		const closest = closestOnSegment(ball, segment.a, segment.b);
		let dx = ball.x - closest.x;
		let dy = ball.y - closest.y;
		const reach = ballRadius + segment.radius;
		const distanceSquared = (dx * dx) + (dy * dy);

		if (distanceSquared >= reach * reach) {
			return undefined;
		}

		// A one-way gate only stops the ball on its front side, which is on the right of the direction from its start to its end, as seen on the screen.
		if (segment.oneWay) {
			const side = ((ball.x - segment.a.x) * (segment.a.y - segment.b.y)) + ((ball.y - segment.a.y) * (segment.b.x - segment.a.x));

			if (side < 0) {
				return undefined;
			}
		}

		let distance = Math.sqrt(distanceSquared);

		if (distance < 0.0001) {
			dx = segment.a.y - segment.b.y;
			dy = segment.b.x - segment.a.x;
			distance = Math.hypot(dx, dy);
		}

		const normalX = dx / distance;
		const normalY = dy / distance;
		const depth = reach - Math.sqrt(distanceSquared);
		ball.x += normalX * depth;
		ball.y += normalY * depth;
		const speed = this.#bounceOff(normalX, normalY, segment.bounce);
		return {normalX, normalY, speed};
	}

	#collideCircle(circle, bounce) {
		const ball = this.#ball;
		const dx = ball.x - circle.x;
		const dy = ball.y - circle.y;
		const reach = ballRadius + circle.radius;
		const distanceSquared = (dx * dx) + (dy * dy);

		if (distanceSquared >= reach * reach) {
			return undefined;
		}

		const distance = Math.sqrt(distanceSquared) || 0.0001;
		const normalX = dx / distance;
		const normalY = dy / distance;
		ball.x = circle.x + (normalX * reach);
		ball.y = circle.y + (normalY * reach);
		const speed = this.#bounceOff(normalX, normalY, bounce);
		return {normalX, normalY, speed};
	}

	#collideFlipper(flipper) {
		const ball = this.#ball;
		const tip = flipperTip(flipper);
		const closest = closestOnSegment(ball, flipper.pivot, tip);
		const radius = flipperRadius(closest.along);
		const dx = ball.x - closest.x;
		const dy = ball.y - closest.y;
		const reach = ballRadius + radius;
		const distanceSquared = (dx * dx) + (dy * dy);

		if (distanceSquared >= reach * reach) {
			return;
		}

		const distance = Math.sqrt(distanceSquared) || 0.0001;
		const normalX = dx / distance;
		const normalY = dy / distance;
		ball.x = closest.x + (normalX * reach);
		ball.y = closest.y + (normalY * reach);
		// The speed of the flipper where it touches the ball, from how fast it turns and how far the point is from the pivot.
		const contactX = closest.x + (normalX * radius) - flipper.pivot.x;
		const contactY = closest.y + (normalY * radius) - flipper.pivot.y;
		const surfaceX = -flipper.spin * contactY;
		const surfaceY = flipper.spin * contactX;
		this.#bounceOff(normalX, normalY, 0.28, surfaceX, surfaceY, 0.05);
	}

	// Turns the flippers toward where they should be, and remembers how fast they turned, for the collisions.
	#moveFlippers() {
		for (const flipper of this.#table.flippers) {
			const target = flipper.isPressed && !this.#game.isTilted ? upAngle : restAngle;
			const speed = flipper.isPressed ? 30 : 16;
			const change = clamp(target - flipper.angle, -speed * step, speed * step);
			flipper.angle += change;
			const worldAngle = worldAngleOf(flipper);
			flipper.spin = (worldAngle - flipper.worldAngle) / step;
			flipper.worldAngle = worldAngle;
		}
	}

	// The lit lanes move one lane over with each press of a flipper, like on a real table, so the visitor can aim for the dark one.
	#rotateLanes(direction) {
		const game = this.#game;

		if (this.#ball.mode === 'free' && !game.lanes.every(Boolean)) {
			game.lanes = direction < 0 ? [...game.lanes.slice(1), game.lanes[0]] : [game.lanes[2], ...game.lanes.slice(0, 2)];
		}
	}

	#passLane(index) {
		const game = this.#game;
		this.#missionEvent('lane');

		if (game.clock < game.skillShotUntil) {
			game.skillShotUntil = 0;

			if (index === game.skillLane) {
				this.#addScore(50_000);
				this.#sounds.fanfare();
				this.#showMessage('Skill shot! 50,000 points.');
			}
		}

		if (game.lanes[index]) {
			this.#addScore(500);
			return;
		}

		game.lanes[index] = true;
		this.#addScore(2000);
		game.bonus += 1000;
		this.#sounds.lane();

		if (game.lanes.every(Boolean)) {
			game.multiplier = Math.min(game.multiplier + 1, 5);
			this.#addScore(15_000);
			this.#showMessage(`Re-entry lanes complete! Bonus ×${game.multiplier}.`, {isImportant: false});

			this.#later(0.6, () => {
				game.lanes = [false, false, false];
			});
		}
	}

	#passFuelLane() {
		const game = this.#game;
		game.fuel = Math.min(game.fuel + 1, 3);
		const points = game.fuel === 3 ? 25_000 : 5000;
		this.#addScore(points);
		game.bonus += 2000;
		this.#sounds.lane();
		this.#showMessage(game.fuel === 3 ? 'Fuel tanks full! 25,000 points.' : `Fuel lane! ${formatScore(points)} points.`, {isImportant: false});

		if (game.fuel === 3) {
			this.#later(1, () => {
				game.fuel = 0;
			});
		}

		this.#missionEvent('fuel');
	}

	#hitBumper(bumper) {
		bumper.flash = 0.12;
		this.#addScore(500 + (125 * Math.floor(this.#game.rank / 2)));
		this.#game.bonus += 100;
		this.#sounds.bumper();
		this.#missionEvent('bumper');
	}

	#hitTarget(target) {
		const {targets} = this.#table;
		target.isUp = false;
		target.flash = 0.2;
		this.#addScore(1500);
		this.#game.bonus += 1000;
		this.#sounds.target();

		if (targets.every(other => !other.isUp)) {
			this.#addScore(25_000);
			this.#showMessage('Drop targets down! 25,000 points.', {isImportant: false});
			this.#missionEvent('bank');

			this.#later(1.5, () => {
				for (const other of targets) {
					other.isUp = true;
				}
			});
		}
	}

	#enterRamp() {
		const game = this.#game;
		this.#ball.mode = 'ramp';
		this.#ball.rampProgress = 0;
		game.ramps++;
		const points = 10_000 + (2500 * Math.min(game.ramps, 20));
		this.#addScore(points);
		game.bonus += 5000;
		this.#sounds.ramp();
		this.#showMessage(`Launch ramp! ${formatScore(points)} points.`, {isImportant: false});
		this.#missionEvent('ramp');
	}

	#enterHole() {
		const game = this.#game;
		const ball = this.#ball;
		ball.mode = 'hole';
		ball.holeTime = 0;
		ball.x = hole.x;
		ball.y = hole.y;
		this.#addScore(game.holeBonus);
		this.#showMessage(`Hyperspace! ${formatScore(game.holeBonus)} points.`, {isImportant: false});
		game.holeBonus += 10_000;
		this.#sounds.hole();
		this.#missionEvent('hole');
	}

	#stepBall() {
		const ball = this.#ball;
		const {walls, targets, bumpers, flippers} = this.#table;

		if (ball.mode === 'ramp') {
			ball.rampProgress += step / 1.1;

			if (ball.rampProgress >= 1) {
				ball.mode = 'free';
				const end = rampPath.at(-1);
				ball.x = end[0];
				ball.y = end[1];
				ball.vx = 0;
				ball.vy = 110;
			}

			return;
		}

		if (ball.mode === 'hole') {
			ball.holeTime += step;

			if (ball.holeTime >= 1.2) {
				ball.mode = 'free';
				ball.y = hole.y + 10;
				ball.vx = -110 - (Math.random() * 80);
				ball.vy = 140 + (Math.random() * 60);
			}

			return;
		}

		if (ball.mode !== 'free') {
			return;
		}

		ball.previousY = ball.y;
		ball.vy += gravity * step;
		const damping = Math.exp(-0.08 * step);
		ball.vx *= damping;
		ball.vy *= damping;
		const speed = Math.hypot(ball.vx, ball.vy);

		if (speed > maximumSpeed) {
			ball.vx *= maximumSpeed / speed;
			ball.vy *= maximumSpeed / speed;
		}

		ball.x += ball.vx * step;
		ball.y += ball.vy * step;

		for (const segment of walls) {
			const hit = this.#collideSegment(segment);

			if (hit && segment.kick && hit.speed > 35) {
				// The slingshot kicks the ball away from its rubber.
				ball.vx += hit.normalX * 190;
				ball.vy += hit.normalY * 190;
				segment.flash = 0.12;
				this.#addScore(100);
				this.#sounds.sling();
			}
		}

		for (const target of targets) {
			if (target.isUp && this.#collideSegment(target.segment)) {
				this.#hitTarget(target);
			}
		}

		for (const post of posts) {
			this.#collideCircle(post, post.bounce);
		}

		for (const bumper of bumpers) {
			const hit = this.#collideCircle(bumper, 0.5);

			if (hit && bumper.flash <= 0.04) {
				// The pop bumper fires, and throws the ball away, whatever its speed.
				const outward = (ball.vx * hit.normalX) + (ball.vy * hit.normalY);
				const kick = Math.max(300 - outward, 0);
				ball.vx += hit.normalX * kick;
				ball.vy += hit.normalY * kick;
				this.#hitBumper(bumper);
			}
		}

		for (const flipper of flippers) {
			this.#collideFlipper(flipper);
		}

		// The fuel lane counts a ball that goes up through it.
		if (ball.x < 30 && ball.previousY > 96 && ball.y <= 96) {
			this.#passFuelLane();
		}

		// The re-entry lanes count a ball that rolls down through them.
		if (ball.previousY < 54 && ball.y >= 54) {
			for (let index = 0; index < 3; index++) {
				if (ball.x > laneEdges[index] && ball.x < laneEdges[index + 1]) {
					this.#passLane(index);
				}
			}
		}

		// The launch ramp takes a fast ball that goes up through its mouth. A slow one rolls back down.
		if (ball.x > rampMouth.left && ball.x < rampMouth.right && ball.y > rampMouth.top && ball.y < rampMouth.bottom && ball.vy < 0) {
			if (ball.vy < -230) {
				this.#enterRamp();
				return;
			}

			if (ball.y < rampMouth.top + 6) {
				ball.vy = Math.abs(ball.vy) * 0.3;
			}
		}

		const holeDistance = Math.hypot(ball.x - hole.x, ball.y - hole.y);

		if (holeDistance < hole.radius - 1 && Math.hypot(ball.vx, ball.vy) < 420) {
			this.#enterHole();
			return;
		}

		// A ball that rolls back down the plunger lane lands on the plunger again.
		if (ball.x > 180 && ball.y > 290 && Math.abs(ball.vy) < 60) {
			this.#serveBallInLane();
			return;
		}

		// A ball that stands still, like on top of a post, gets a bump from the table, unless it rests on a flipper that is held up.
		const isCradled = flippers.some(flipper => flipper.isPressed) && ball.y > 260;

		if (Math.hypot(ball.vx, ball.vy) < 6 && !isCradled) {
			ball.stillTime += step;

			if (ball.stillTime > 2) {
				ball.stillTime = 0;
				ball.vx = (Math.random() - 0.5) * 160;
				ball.vy = -180;
			}
		} else {
			ball.stillTime = 0;
		}

		if (ball.y > height + 8 && ball.x < 180) {
			this.#drain();
		} else if (ball.x < -20 || ball.x > width + 20 || ball.y < -20 || ball.y > height + 40) {
			// A ball that escapes the table, which should never happen, comes back to the plunger.
			this.#serveBall();
		}
	}

	#serveBallInLane() {
		const ball = this.#ball;
		ball.mode = 'plunger';
		ball.x = 189;
		ball.y = 306 - ballRadius;
		ball.vx = 0;
		ball.vy = 0;
	}

	#update(seconds) {
		const ball = this.#ball;
		const plunger = this.#plunger;
		const {slingshots, targets, bumpers} = this.#table;

		if (plunger.isPulling && ball.mode === 'plunger') {
			plunger.pull = Math.min(plunger.pull + (seconds / 1.1), 1);
		}

		const steps = Math.round(seconds / step);

		for (let index = 0; index < steps; index++) {
			this.#game.clock += step;
			this.#runTimers();
			this.#moveFlippers();
			this.#stepBall();

			for (const bumper of bumpers) {
				bumper.flash = Math.max(bumper.flash - step, 0);
			}

			for (const flasher of [...slingshots, ...targets]) {
				flasher.flash = Math.max((flasher.flash ?? 0) - step, 0);
			}
		}

		if (ball.mode === 'plunger') {
			ball.y = 306 - ballRadius + (plunger.pull * 14);
		}

		if (!this.#game.isOver) {
			this.#showPanel();
		}
	}

	// The walls have a dark edge below them, so the table looks like it has depth, like the 3D of Space Cadet.
	#drawTable() {
		const scale = this.#scale;
		const table = this.#tableCanvas.getContext('2d');
		table.setTransform(scale, 0, 0, scale, 0, 0);
		const space = table.createLinearGradient(0, 0, 0, height);
		space.addColorStop(0, '#0b0630');
		space.addColorStop(0.6, '#081a4a');
		space.addColorStop(1, '#030318');
		table.fillStyle = space;
		table.fillRect(0, 0, width, height);

		// The stars are always the same, so the table looks the same each time.
		let seed = 1999;
		const random = () => {
			seed = (seed * 16_807) % 2_147_483_647;
			return seed / 2_147_483_647;
		};

		for (let index = 0; index < 140; index++) {
			table.fillStyle = `rgba(255, 255, 255, ${0.3 + (random() * 0.7)})`;
			table.fillRect(random() * width, random() * height, random() < 0.1 ? 1 : 0.5, random() < 0.1 ? 1 : 0.5);
		}

		// A ringed planet and a nebula, the pictures of the table.
		const nebula = table.createRadialGradient(92, 192, 4, 92, 192, 60);
		nebula.addColorStop(0, 'rgba(180, 60, 255, 0.45)');
		nebula.addColorStop(1, 'rgba(180, 60, 255, 0)');
		table.fillStyle = nebula;
		table.fillRect(20, 122, 150, 140);
		const planet = table.createRadialGradient(84, 188, 2, 92, 196, 22);
		planet.addColorStop(0, '#ffb35c');
		planet.addColorStop(1, '#8a2f12');
		table.fillStyle = planet;
		table.beginPath();
		table.arc(92, 196, 18, 0, Math.PI * 2);
		table.fill();
		table.strokeStyle = 'rgba(255, 220, 160, 0.8)';
		table.lineWidth = 1.5;
		table.beginPath();
		table.ellipse(92, 196, 32, 7, -0.25, 0, Math.PI * 2);
		table.stroke();

		label(table, 'SPACE', 92, 246, {color: '#ff5a3c', size: 9});
		label(table, 'CADET', 92, 256, {color: '#ff5a3c', size: 9});
		label(table, 'RE-ENTRY', 93, 30, {size: 5});
		label(table, 'ATTACK BUMPERS', 90, 168, {size: 5, color: '#ff8fd0'});
		label(table, 'HYPERSPACE', hole.x, hole.y - 11, {size: 5, color: '#c58bff'});
		label(table, 'LAUNCH', 142, 196, {size: 5});
		label(table, 'RAMP', 142, 202, {size: 5});
		label(table, 'TARGETS', 42, 138, {angle: Math.PI / 2, size: 5, color: '#ff8f3c'});
		label(table, 'FUEL', 18, 112, {size: 5, color: '#33ff66'});
		label(table, 'PLUNGER', 187, 200, {angle: Math.PI / 2, size: 5, color: '#7fd8ff'});

		// The arrow that points at the mouth of the launch ramp.
		table.fillStyle = 'rgba(255, 210, 63, 0.35)';
		table.beginPath();
		table.moveTo(142, 206);
		table.lineTo(134, 216);
		table.lineTo(150, 216);
		table.closePath();
		table.fill();

		// The hyperspace hole, a black hole with a purple ring.
		const glow = table.createRadialGradient(hole.x, hole.y, 2, hole.x, hole.y, 11);
		glow.addColorStop(0, '#000000');
		glow.addColorStop(0.6, '#2a0050');
		glow.addColorStop(1, 'rgba(197, 139, 255, 0)');
		table.fillStyle = glow;
		table.beginPath();
		table.arc(hole.x, hole.y, 11, 0, Math.PI * 2);
		table.fill();

		const drawWall = segment => {
			for (const [offset, color, lineWidth] of [[1.6, '#06203a', 3], [0, segment.oneWay ? '#ffd23f' : neon, 1.4]]) {
				table.strokeStyle = color;
				table.lineWidth = Math.max(lineWidth, segment.radius * 2);
				table.lineCap = 'round';
				table.beginPath();
				table.moveTo(segment.a.x + (offset * 0.6), segment.a.y + offset);
				table.lineTo(segment.b.x + (offset * 0.6), segment.b.y + offset);
				table.stroke();
			}
		};

		// The slingshots are filled, like the plastic of a real table.
		for (const points of [[[38, 226], [38, 256], [56, 270]], [[148, 226], [148, 256], [130, 270]]]) {
			table.fillStyle = '#1b2a6b';
			table.beginPath();
			table.moveTo(...points[0]);
			table.lineTo(...points[1]);
			table.lineTo(...points[2]);
			table.closePath();
			table.fill();
		}

		for (const segment of this.#table.walls) {
			if (!segment.kick) {
				drawWall(segment);
			}
		}

		// The plunger lane is darker, like a channel.
		table.fillStyle = 'rgba(0, 0, 0, 0.35)';
		table.fillRect(181, 92, 12, 214);
		this.#isTableDrawn = true;
	}

	// The ramp is a see-through chute over the table, drawn once on its own canvas: a wide line with the middle cut out leaves its two rails, and a faint glass between them.
	#drawRampCanvas() {
		const ramp = this.#rampCanvas.getContext('2d');
		ramp.setTransform(this.#scale, 0, 0, this.#scale, 0, 0);
		ramp.lineJoin = 'round';
		ramp.lineCap = 'round';
		ramp.beginPath();
		ramp.moveTo(...rampPath[0]);

		for (const point of rampPath.slice(1)) {
			ramp.lineTo(...point);
		}

		ramp.strokeStyle = 'rgba(170, 240, 255, 0.7)';
		ramp.lineWidth = 12;
		ramp.stroke();
		ramp.globalCompositeOperation = 'destination-out';
		ramp.strokeStyle = '#000000';
		ramp.lineWidth = 9.6;
		ramp.stroke();
		ramp.globalCompositeOperation = 'source-over';
		ramp.strokeStyle = 'rgba(120, 200, 255, 0.1)';
		ramp.stroke();
	}

	#drawRamp() {
		const context = this.#context;
		context.setTransform(1, 0, 0, 1, 0, 0);
		context.drawImage(this.#rampCanvas, 0, 0);
		context.setTransform(this.#scale, 0, 0, this.#scale, 0, 0);
	}

	#drawLight(x, y, isOn, color, radius = 2.5) {
		const context = this.#context;
		context.fillStyle = isOn ? color : 'rgba(255, 255, 255, 0.12)';
		context.beginPath();
		context.arc(x, y, radius, 0, Math.PI * 2);
		context.fill();

		if (isOn) {
			context.fillStyle = 'rgba(255, 255, 255, 0.7)';
			context.beginPath();
			context.arc(x - 0.7, y - 0.7, radius / 3, 0, Math.PI * 2);
			context.fill();
		}
	}

	#drawFlipper(flipper) {
		const context = this.#context;
		const tip = flipperTip(flipper);
		const angle = Math.atan2(tip.y - flipper.pivot.y, tip.x - flipper.pivot.x);
		context.save();
		context.translate(flipper.pivot.x, flipper.pivot.y);
		context.rotate(angle);

		for (const [offset, color] of [[2, '#300000'], [0, '#f2f2f2']]) {
			context.fillStyle = color;
			context.beginPath();
			context.arc(0, offset, 5.5, Math.PI / 2, Math.PI * 1.5);
			context.lineTo(flipperLength, offset - 3);
			context.arc(flipperLength, offset, 3, -Math.PI / 2, Math.PI / 2);
			context.closePath();
			context.fill();
		}

		context.fillStyle = '#e8322c';
		context.fillRect(2, -1.2, flipperLength - 4, 2.4);
		context.fillStyle = '#888888';
		context.beginPath();
		context.arc(0, 0, 2, 0, Math.PI * 2);
		context.fill();
		context.restore();
	}

	#drawBumper(bumper) {
		const context = this.#context;
		const isLit = bumper.flash > 0;
		// The bumper is a cylinder, with its side under its top.
		context.fillStyle = '#5a0f2a';
		context.beginPath();
		context.ellipse(bumper.x + 1, bumper.y + 3, bumper.radius, bumper.radius * 0.9, 0, 0, Math.PI * 2);
		context.fill();
		const top = context.createRadialGradient(bumper.x - 3, bumper.y - 3, 1, bumper.x, bumper.y, bumper.radius);
		top.addColorStop(0, isLit ? '#ffffff' : '#ff9ad5');
		top.addColorStop(1, isLit ? '#ffe14f' : '#d4246f');
		context.fillStyle = top;
		context.beginPath();
		context.arc(bumper.x, bumper.y, bumper.radius, 0, Math.PI * 2);
		context.fill();
		context.strokeStyle = isLit ? '#ffffff' : '#ffd23f';
		context.lineWidth = 1;
		context.beginPath();
		context.arc(bumper.x, bumper.y, bumper.radius - 2.5, 0, Math.PI * 2);
		context.stroke();
	}

	#drawBall(x, y, size = 1) {
		const context = this.#context;
		const radius = ballRadius * size;
		context.fillStyle = 'rgba(0, 0, 0, 0.45)';
		context.beginPath();
		context.ellipse(x + (1.5 * size), y + (2.5 * size), radius, radius * 0.8, 0, 0, Math.PI * 2);
		context.fill();
		const shine = context.createRadialGradient(x - (1.5 * size), y - (1.5 * size), 0.5, x, y, radius);
		shine.addColorStop(0, '#ffffff');
		shine.addColorStop(0.4, '#c8d0dc');
		shine.addColorStop(1, '#4a5260');
		context.fillStyle = shine;
		context.beginPath();
		context.arc(x, y, radius, 0, Math.PI * 2);
		context.fill();
	}

	get #isBlinkOn() {
		return this.reducedMotion || Math.floor(this.#game.clock * 4) % 2 === 0;
	}

	#draw() {
		const context = this.#context;
		const game = this.#game;
		const ball = this.#ball;
		const {slingshots, targets, bumpers, flippers} = this.#table;

		if (!this.#isTableDrawn) {
			this.#drawTable();
			this.#drawRampCanvas();
		}

		context.setTransform(1, 0, 0, 1, 0, 0);
		context.drawImage(this.#tableCanvas, 0, 0);
		context.setTransform(this.#scale, 0, 0, this.#scale, 0, 0);

		// The lights of the re-entry lanes, with the skill shot lane blinking right after a launch.
		for (let index = 0; index < 3; index++) {
			const x = (laneEdges[index] + laneEdges[index + 1]) / 2;
			const isSkillLane = game.clock < game.skillShotUntil && index === game.skillLane;
			this.#drawLight(x, 60, game.lanes[index] || (isSkillLane && this.#isBlinkOn), isSkillLane ? '#ff5a3c' : '#ffd23f');
		}

		// The fuel lights in the fuel lane.
		for (let index = 0; index < 3; index++) {
			this.#drawLight(18, 100 - (index * 10), game.fuel > index, '#33ff66', 2.5);
		}

		// The lights of the bonus multiplier, above the flippers.
		for (let multiplier = 2; multiplier <= 5; multiplier++) {
			const x = 66 + ((multiplier - 2) * 18);
			this.#drawLight(x, 224, game.multiplier >= multiplier, '#33ff66', 3);
			label(context, `${multiplier}×`, x, 233, {size: 4.5, color: game.multiplier >= multiplier ? '#33ff66' : '#4a6a8a'});
		}

		// The Re-Deploy light between the flippers, while the ball save lasts.
		const isSaving = game.clock < game.ballSaveUntil && ball.mode !== 'plunger' && !game.isOver;
		this.#drawLight(93, 300, isSaving && (game.ballSaveUntil - game.clock > 3 || this.#isBlinkOn), '#7fd8ff', 3);
		label(context, 'RE-DEPLOY', 93, 311, {size: 4.5, color: isSaving ? '#7fd8ff' : '#2a4a6a'});

		// The light of the ramp, which shows how many more ramps the mission needs.
		this.#drawLight(142, 222, missions[game.mission].event === 'ramp' && !game.isOver, '#ffd23f', 2.5);
		this.#drawLight(hole.x + 12, hole.y + 6, missions[game.mission].event === 'hole' && !game.isOver, '#c58bff', 2.5);

		for (const target of targets) {
			const {a, b} = target.segment;

			if (target.isUp) {
				context.fillStyle = '#06203a';
				context.fillRect(a.x + 0.5, a.y + 1.5, 4, b.y - a.y);
				context.fillStyle = target.flash > 0 ? '#ffffff' : '#ff8f3c';
				context.fillRect(a.x - 1.5, a.y, 4, b.y - a.y);
			} else {
				context.strokeStyle = 'rgba(255, 143, 60, 0.4)';
				context.lineWidth = 0.6;
				context.strokeRect(a.x - 1.5, a.y, 4, b.y - a.y);
			}
		}

		for (const sling of slingshots) {
			context.strokeStyle = sling.flash > 0 ? '#ffffff' : '#ff8f3c';
			context.lineWidth = 3;
			context.lineCap = 'round';
			context.beginPath();
			context.moveTo(sling.a.x, sling.a.y);
			context.lineTo(sling.b.x, sling.b.y);
			context.stroke();
		}

		for (const post of posts) {
			context.fillStyle = '#ffd23f';
			context.beginPath();
			context.arc(post.x, post.y, post.radius, 0, Math.PI * 2);
			context.fill();
		}

		for (const bumper of bumpers) {
			this.#drawBumper(bumper);
		}

		for (const flipper of flippers) {
			this.#drawFlipper(flipper);
		}

		// The plunger, a spring with a red knob, pulled down while the visitor holds it.
		const plungerTop = 306 + (this.#plunger.pull * 14);
		context.strokeStyle = '#b0b0b0';
		context.lineWidth = 0.8;
		context.beginPath();

		for (let index = 0; index <= 8; index++) {
			const y = plungerTop + 2 + (index * (318 - plungerTop - 2) / 8);
			context.lineTo(index % 2 === 0 ? 182 : 192, y);
		}

		context.stroke();
		context.fillStyle = '#e8322c';
		context.fillRect(181, plungerTop, 12, 3);

		if (ball.mode === 'free' || ball.mode === 'plunger' || ball.mode === 'drained') {
			this.#drawBall(ball.x, ball.y);
		}

		if (ball.mode === 'hole') {
			// The ball sinks into hyperspace and spins.
			const size = Math.max(1 - (ball.holeTime / 0.6), 0.2);
			const turn = this.reducedMotion ? 0 : ball.holeTime * 14;
			this.#drawBall(hole.x + (Math.cos(turn) * 2 * size), hole.y + (Math.sin(turn) * 2 * size), size);
		}

		this.#drawRamp();

		if (ball.mode === 'ramp') {
			// On the ramp, the ball is higher, so it looks bigger.
			const point = pointOnRamp(ball.rampProgress);
			this.#drawBall(point.x, point.y, 1.15 + (Math.sin(ball.rampProgress * Math.PI) * 0.25));
		}

		// The big messages over the table.
		let banner;

		if (game.isTilted) {
			banner = 'TILT';
		} else if (!game.isStarted) {
			banner = 'PRESS F2';
		} else if (game.isOver) {
			banner = 'GAME OVER';
		} else if (this.#isPaused) {
			banner = 'PAUSED';
		}

		if (banner) {
			context.fillStyle = 'rgba(0, 0, 20, 0.7)';
			context.fillRect(20, 120, 154, !game.isStarted || game.isOver ? 46 : 30);
			label(context, banner, 97, 141, {size: 16, color: game.isTilted ? '#ff3030' : '#ffd23f'});

			if (!game.isStarted || game.isOver) {
				label(context, 'or tap the table', 97, 160, {size: 7, color: '#7fd8ff'});
			}
		} else if (game.clock < game.messageUntil && game.message) {
			context.fillStyle = 'rgba(0, 0, 20, 0.65)';
			context.fillRect(10, 254, 166, 12);
			const text = game.message.length > 40 ? `${game.message.slice(0, 39)}…` : game.message;
			label(context, text, 93, 262, {size: 5, color: '#ffd23f'});
		}
	}

	// Steps the table in the next frame while it should run, or draws it once when it should not, like after the last key with reduced motion.
	#run() {
		this.#loop.start();
		this.#loop.requestStep();
	}

	// Any key or tap of the game plays on after a pause, and moves the table for a moment with reduced motion.
	#resume() {
		this.#runUntil = performance.now() + (motionPause * 1000);

		if (this.#isPaused) {
			this.#isPaused = false;
			this.say(this.reducedMotion ? 'Playing. The table moves for a moment after each key or tap, as your computer prefers less motion.' : 'Playing.');
		}

		this.#run();
	}

	#pause() {
		const game = this.#game;

		if (game.isStarted && !game.isOver && !this.#isPaused) {
			this.#isPaused = true;

			for (const flipper of this.#table.flippers) {
				flipper.isPressed = false;
			}

			this.#plunger.isPulling = false;
			this.say('Paused. Press a key of the game, or tap the table, to play on.');
			this.#draw();
		}
	}

	// The controls: the flippers and the plunger, from the keys, the buttons, and a finger on the table.
	#press(control) {
		const game = this.#game;

		if (!game.isStarted || game.isOver) {
			return;
		}

		this.#resume();

		if (control === 'launch') {
			if (this.#ball.mode === 'plunger') {
				this.#plunger.isPulling = true;
			}

			return;
		}

		const flipper = this.#table.flippers[control === 'left' ? 0 : 1];

		if (!flipper.isPressed && !game.isTilted) {
			flipper.isPressed = true;
			this.#sounds.flipper();
			this.#rotateLanes(control === 'left' ? -1 : 1);
		}
	}

	#release(control) {
		if (control === 'launch') {
			if (this.#plunger.isPulling) {
				this.#plunger.isPulling = false;
				this.#launch();
			}
		} else {
			this.#table.flippers[control === 'left' ? 0 : 1].isPressed = false;
		}

		this.#runUntil = performance.now() + (motionPause * 1000);
		this.#run();
	}

	#releaseAll() {
		for (const flipper of this.#table.flippers) {
			flipper.isPressed = false;
		}

		if (this.#plunger.isPulling) {
			this.#release('launch');
		}
	}
}
