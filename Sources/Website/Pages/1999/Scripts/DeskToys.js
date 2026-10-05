// Pappa’s Desk Toys on the 1999 page: the Newton’s cradle, the plasma ball, the pin art, the drinking bird, the Zen garden, the magnet sculpture, the stress ball, the Executive Decision Maker, and the perpetual motion machine, each drawn on its own canvas. A canvas runs only while it is on the screen and the tab is visible. With reduced motion, nothing moves by itself: the toys take one step for each press. Nothing makes a sound until the visitor turns on the sound.
//
// Each toy is set up by its own function, with the desk (the element, for its helpers, like `say()`, `on()`, and `loop()`), its canvas, and the sound of the desk.

// A stored count can be broken or changed by hand, so anything that is not a whole number from 0 is a count of 0.
const loadCount = (desk, key) => Math.max(0, Math.round(Number(desk.stored(key, 0)) || 0));

const clamp = (value, minimum, maximum) => Math.min(Math.max(value, minimum), maximum);

// A loop of a toy, which runs while its canvas is on the screen and the tab is visible, and while `isBusy` says so. A step is at most a 30th of a second, so a toy does not jump after a pause.
const toyLoop = (desk, canvas, update, isBusy) => desk.loop(update, {while: isBusy, target: canvas, maximumStep: 1 / 30});

// The position of a pointer on a canvas, in the pixels of the canvas.
const canvasPoint = (canvas, event) => {
	const rectangle = canvas.getBoundingClientRect();
	return {
		x: (event.clientX - rectangle.left) * canvas.width / rectangle.width,
		y: (event.clientY - rectangle.top) * canvas.height / rectangle.height,
	};
};

// A number between 0 and 1 that is always the same for the same seed, for the things that must not flicker, like the shape of a stone.
const hash = seed => {
	const value = Math.sin(seed * 127.1 + 311.7) * 43_758.5453;
	return value - Math.floor(value);
};

const turn = Math.PI * 2;
const width = 480;
const height = 360;

const deskButton = (desk, id) => desk.querySelector(`[data-desk-button="${id}"]`);

const onButton = (desk, id, action) => {
	desk.on(deskButton(desk, id), 'click', action);
};

// The keys that a toy handles do not scroll the page.
const onKeys = (desk, canvas, handler) => {
	desk.on(canvas, 'keydown', event => {
		if (event.altKey || event.ctrlKey || event.metaKey) {
			return;
		}

		if (handler(event) !== false) {
			event.preventDefault();
		}
	});
};

// The sounds, made in the browser once the visitor turns them on: the click-clack, the buzz of the plasma ball, the squeak, and the ticks of the wheel.
const makeSounds = () => ({
	context: undefined,
	output: undefined,
	isOn: false,
	noise: undefined,
	buzz: undefined,
	// Starts with the audio of the desk, which is `undefined` when the browser does not let it play yet.
	start(audio) {
		if (!audio) {
			return false;
		}

		this.context = audio.context;
		this.output = audio.output;
		this.context.resume();

		if (!this.noise) {
			const context = this.context;
			this.noise = new AudioBuffer({length: context.sampleRate * 2, sampleRate: context.sampleRate});
			const samples = this.noise.getChannelData(0);
			for (let index = 0; index < samples.length; index++) {
				samples[index] = (Math.random() * 2) - 1;
			}

			// The buzz of the plasma ball: the hum of the transformer in the base, and the hiss of the sparks.
			this.buzz = new GainNode(context, {gain: 0});
			this.buzz.connect(this.output);
			const hum = new OscillatorNode(context, {type: 'sawtooth', frequency: 100});
			hum.connect(new BiquadFilterNode(context, {type: 'lowpass', frequency: 500})).connect(new GainNode(context, {gain: 0.5})).connect(this.buzz);
			hum.start();
			const hiss = new AudioBufferSourceNode(context, {buffer: this.noise, loop: true});
			hiss.connect(new BiquadFilterNode(context, {type: 'bandpass', frequency: 3500, Q: 0.8})).connect(new GainNode(context, {gain: 0.6})).connect(this.buzz);
			hiss.start();
		}

		return true;
	},
	get isRunning() {
		return this.isOn && this.context?.state === 'running';
	},
	level(node, value) {
		if (node && this.context) {
			node.gain.setTargetAtTime(this.isOn ? value : 0, this.context.currentTime, 0.06);
		}
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
		gain.gain.linearRampToValueAtTime(volume, start + 0.004);
		gain.gain.exponentialRampToValueAtTime(0.0001, start + duration);
		oscillator.connect(gain).connect(this.output);
		oscillator.start(start);
		oscillator.stop(start + duration + 0.02);
	},
	burst(duration, {volume = 0.2, frequency = 800, type = 'lowpass', when = 0, quality = 1} = {}) {
		if (!this.isRunning) {
			return;
		}

		const start = this.context.currentTime + when;
		const source = new AudioBufferSourceNode(this.context, {buffer: this.noise});
		const gain = new GainNode(this.context, {gain: volume});
		gain.gain.setValueAtTime(volume, start);
		gain.gain.exponentialRampToValueAtTime(0.0001, start + duration);
		source.connect(new BiquadFilterNode(this.context, {type, frequency, Q: quality})).connect(gain).connect(this.output);
		source.start(start, Math.random());
		source.stop(start + duration + 0.02);
	},
	// Two steel balls that hit: a short, bright click, and the ring of the steel.
	clack(strength) {
		const volume = clamp(strength, 0.05, 1);
		this.burst(0.025, {volume: 0.5 * volume, frequency: 4200, type: 'bandpass', quality: 2});
		this.tone(2637, 0.07, {type: 'sine', volume: 0.08 * volume});
		this.tone(5200, 0.04, {type: 'sine', volume: 0.03 * volume});
	},
	tick() {
		this.burst(0.015, {volume: 0.25, frequency: 2500, type: 'bandpass', quality: 3});
	},
	thud() {
		this.tone(110, 0.15, {type: 'sine', volume: 0.25, slide: 60});
		this.burst(0.06, {volume: 0.3, frequency: 400});
	},
});

// A shiny steel ball, lit from the top left, like the balls of the cradle and the weights of the wheel.
const steelBall = (context, x, y, radius, tint = '#8a929c') => {
	const gradient = context.createRadialGradient(x - (radius * 0.35), y - (radius * 0.4), radius * 0.05, x, y, radius);
	gradient.addColorStop(0, '#ffffff');
	gradient.addColorStop(0.2, '#e4e8ec');
	gradient.addColorStop(0.65, tint);
	gradient.addColorStop(1, '#2a2e34');
	context.fillStyle = gradient;
	context.beginPath();
	context.arc(x, y, radius, 0, turn);
	context.fill();
};

// The top of Pappa’s desk, which is behind every toy.
const drawDesk = (context, top, {light = '#7a4a26', dark = '#4a2a12'} = {}) => {
	const gradient = context.createLinearGradient(0, top, 0, height);
	gradient.addColorStop(0, light);
	gradient.addColorStop(1, dark);
	context.fillStyle = gradient;
	context.fillRect(0, top, width, height - top);
	context.strokeStyle = '#00000022';
	context.lineWidth = 1;
	for (let line = 0; line < 6; line++) {
		const y = top + 6 + (line * ((height - top) / 6));
		context.beginPath();
		context.moveTo(0, y);
		context.bezierCurveTo(width * 0.3, y + 4, width * 0.6, y - 4, width, y + 2);
		context.stroke();
	}
};

// Newton’s cradle: five steel balls on strings. Each ball is a pendulum, and the balls that touch swap their speed, which carries the push through the row to the last ball.
const setupCradle = (desk, canvas, sound) => {
	const context = canvas.getContext('2d');
	const count = 5;
	const radius = 22;
	const length = 178;
	const pivotY = 66;
	const pivots = Array.from({length: count}, (_, index) => 240 + ((index - 2) * radius * 2));
	const angles = Array.from({length: count}, () => 0);
	const speeds = Array.from({length: count}, () => 0);
	// The pull back to the middle, for a swing of about a second, like the real one.
	const stiffness = 34;
	// Steel bounces well, but not perfectly, so the balls slowly start to swing together, like on Pappa’s desk.
	const restitution = 0.982;
	const maximumAngle = 0.85;
	const liftAngle = 0.62;
	const drags = new Map();
	let still = {left: 0, right: 0, amplitude: 0};
	let lastClack = 0;
	let clacks = 0;

	const ballX = index => pivots[index] + (length * Math.sin(angles[index]));
	const ballY = index => pivotY + (length * Math.cos(angles[index]));
	const isHeld = index => [...drags.values()].some(drag => drag.indices.includes(index));

	const collide = (index, strongest) => {
		const next = index + 1;
		const gap = ballX(next) - ballX(index) - (radius * 2);
		if (gap > 0.02) {
			return strongest;
		}

		const isLeftHeld = isHeld(index);
		const isRightHeld = isHeld(next);
		if (isLeftHeld && isRightHeld) {
			return strongest;
		}

		// Balls that overlap are pushed apart, so they never go through each other.
		if (gap < 0) {
			if (isLeftHeld) {
				angles[next] -= gap / length;
			} else if (isRightHeld) {
				angles[index] += gap / length;
			} else {
				angles[index] += gap / (2 * length);
				angles[next] -= gap / (2 * length);
			}
		}

		const approach = (speeds[index] * Math.cos(angles[index])) - (speeds[next] * Math.cos(angles[next]));
		if (approach <= 0) {
			return strongest;
		}

		if (isLeftHeld) {
			speeds[next] = -restitution * speeds[next];
		} else if (isRightHeld) {
			speeds[index] = -restitution * speeds[index];
		} else {
			const left = speeds[index];
			const right = speeds[next];
			speeds[index] = (((1 - restitution) * left) + ((1 + restitution) * right)) / 2;
			speeds[next] = (((1 + restitution) * left) + ((1 - restitution) * right)) / 2;
		}

		return Math.max(strongest, approach * length);
	};

	const step = (delta, time) => {
		const substeps = 12;
		const substep = delta / substeps;
		let strongest = 0;
		for (let iteration = 0; iteration < substeps; iteration++) {
			for (let index = 0; index < count; index++) {
				if (isHeld(index)) {
					speeds[index] = 0;
					continue;
				}

				speeds[index] -= stiffness * Math.sin(angles[index]) * substep;
				speeds[index] *= 1 - (0.06 * substep);
				angles[index] += speeds[index] * substep;
			}

			// A few sweeps both ways, so a push goes through all the balls that touch at once.
			for (let pass = 0; pass < count; pass++) {
				for (let index = 0; index < count - 1; index++) {
					strongest = collide(index, strongest);
				}

				for (let index = count - 2; index >= 0; index--) {
					strongest = collide(index, strongest);
				}
			}
		}

		if (strongest > 20 && time - lastClack > 45) {
			lastClack = time;
			clacks++;
			sound.clack(strongest / 500);
		}

		// The balls stop for real when they almost stop, so the loop can rest.
		if (drags.size === 0 && speeds.every(speed => Math.abs(speed) < 0.01) && angles.every(angle => Math.abs(angle) < 0.003)) {
			angles.fill(0);
			speeds.fill(0);
		}
	};

	const isBusy = () => !desk.reducedMotion && (drags.size > 0 || speeds.some(speed => speed !== 0) || angles.some(angle => angle !== 0));

	const draw = () => {
		const background = context.createLinearGradient(0, 0, 0, height);
		background.addColorStop(0, '#2c3a48');
		background.addColorStop(1, '#141c24');
		context.fillStyle = background;
		context.fillRect(0, 0, width, height);
		drawDesk(context, 318);

		// The black base of lacquered wood.
		context.fillStyle = '#111111';
		context.beginPath();
		context.roundRect(26, 312, 428, 28, 6);
		context.fill();
		context.fillStyle = '#2b2b2b';
		context.fillRect(32, 314, 416, 4);

		// The shadows of the balls on the base.
		for (let index = 0; index < count; index++) {
			const lift = (pivotY + length) - ballY(index);
			context.fillStyle = `rgba(0, 0, 0, ${0.5 - (lift / 300)})`;
			context.beginPath();
			context.ellipse(ballX(index), 314, radius * (1 + (lift / 200)), 4, 0, 0, turn);
			context.fill();
		}

		// The chrome frame: two bars on top, and the legs.
		context.lineCap = 'round';
		for (const [y, color, lineWidth] of [[pivotY - 10, '#7a828c', 5], [pivotY, '#d8dde2', 6]]) {
			context.strokeStyle = color;
			context.lineWidth = lineWidth;
			context.beginPath();
			context.moveTo(50, 314);
			context.lineTo(60, y);
			context.lineTo(420, y);
			context.lineTo(430, 314);
			context.stroke();
		}

		context.strokeStyle = '#ffffff99';
		context.lineWidth = 1.5;
		context.beginPath();
		context.moveTo(62, pivotY - 2);
		context.lineTo(418, pivotY - 2);
		context.stroke();

		// Two strings for each ball, one to each bar, so the balls swing in one line only.
		for (let index = 0; index < count; index++) {
			const x = ballX(index);
			const y = ballY(index) - radius + 2;
			context.strokeStyle = '#c9ced4';
			context.lineWidth = 1;
			for (const [offset, top] of [[-6, pivotY - 10], [6, pivotY]]) {
				context.beginPath();
				context.moveTo(pivots[index] + offset, top);
				context.lineTo(x, y);
				context.stroke();
			}
		}

		for (let index = 0; index < count; index++) {
			steelBall(context, ballX(index), ballY(index), radius);
			// The office window, reflected in each ball.
			context.fillStyle = '#ffffff40';
			context.fillRect(ballX(index) - 9, ballY(index) - 14, 6, 5);
			context.fillRect(ballX(index) - 2, ballY(index) - 14, 6, 5);
		}

		context.fillStyle = '#d8dde2';
		context.font = 'bold 13px "Times New Roman", serif';
		context.textAlign = 'center';
		context.fillText(`Click-clacks: ${clacks}`, 240, 30);
	};

	const loop = toyLoop(desk, canvas, (delta, time) => {
		step(delta, time);
		draw();
	}, isBusy);

	const showStill = () => {
		for (let index = 0; index < count; index++) {
			if (index < still.left) {
				angles[index] = -still.amplitude;
			} else if (index >= count - still.right) {
				angles[index] = still.amplitude;
			} else {
				angles[index] = 0;
			}
		}

		speeds.fill(0);
		draw();
	};

	// With reduced motion, each press shows the next moment: the balls that were out on one side are out on the other side.
	const stepStill = () => {
		if (still.left === 0 && still.right === 0) {
			desk.say('The balls hang still. Drag a ball out first, or press Lift One.');
			return;
		}

		sound.clack(still.amplitude);
		clacks++;
		if (still.left > 0 && still.right > 0) {
			still.amplitude *= 0.85;
		} else {
			[still.left, still.right] = [still.right, still.left];
			still.amplitude *= 0.88;
		}

		if (still.amplitude < 0.12) {
			still = {left: 0, right: 0, amplitude: 0};
			desk.say('Click… clack… click. The balls stop.');
		}

		showStill();
	};

	const names = ['', 'One ball', 'Two balls', 'Three balls'];

	const lift = (left, right) => {
		drags.clear();
		const number = left || right;
		if (desk.reducedMotion) {
			still = {left, right, amplitude: liftAngle};
			showStill();
			desk.say(left > 0 && right > 0 ? 'One ball out on each side. Press the cradle, or Space, for the next click-clack.' : `${names[number]} out. Press the cradle, or Space, for the next click-clack.`);
			return;
		}

		desk.say(left > 0 && right > 0 ? 'One ball on each side! They hit in the middle and bounce back out, again and again.' : `${names[number]} out. Click-clack, and ${names[number].toLowerCase()} ${number === 1 ? 'swings' : 'swing'} out on the other side. Momentum!`);

		for (let index = 0; index < count; index++) {
			if (index < left) {
				angles[index] = -liftAngle;
			} else if (index >= count - right) {
				angles[index] = liftAngle;
			} else {
				angles[index] = 0;
			}
		}

		speeds.fill(0);
		loop.start();
	};

	const stop = () => {
		drags.clear();
		angles.fill(0);
		speeds.fill(0);
		still = {left: 0, right: 0, amplitude: 0};
		sound.thud();
		draw();
		desk.say('Pappa grabs all the balls. “Some of us are trying to work here!”');
	};

	desk.on(canvas, 'pointerdown', event => {
		const point = canvasPoint(canvas, event);
		let nearest = -1;
		let nearestDistance = Number.POSITIVE_INFINITY;
		for (let index = 0; index < count; index++) {
			const distance = Math.hypot(point.x - ballX(index), point.y - ballY(index));
			if (distance < nearestDistance && !isHeld(index)) {
				nearest = index;
				nearestDistance = distance;
			}
		}

		event.preventDefault();
		canvas.focus({preventScroll: true});
		if (nearest === -1 || nearestDistance > radius * 1.8) {
			if (desk.reducedMotion) {
				stepStill();
			}

			return;
		}

		canvas.setPointerCapture(event.pointerId);
		// A ball takes the balls outside it along, and the middle ball takes the side that it is dragged to.
		let indices = [];
		let side = 0;
		if (nearest < 2) {
			indices = Array.from({length: nearest + 1}, (_, index) => index);
			side = -1;
		} else if (nearest > 2) {
			indices = Array.from({length: count - nearest}, (_, index) => nearest + index);
			side = 1;
		}

		drags.set(event.pointerId, {grabbed: nearest, indices, side, hasMoved: false});
		loop.start();
	});

	desk.on(canvas, 'pointermove', event => {
		const drag = drags.get(event.pointerId);
		if (!drag) {
			return;
		}

		const point = canvasPoint(canvas, event);
		const horizontal = point.x - pivots[drag.grabbed];
		if (drag.side === 0) {
			if (Math.abs(horizontal) < 4) {
				return;
			}

			drag.side = Math.sign(horizontal);
			drag.indices = drag.side < 0 ? [0, 1, 2] : [2, 3, 4];
			// The other hand may already hold balls on that side.
			for (const [pointerId, other] of drags) {
				if (other !== drag && other.indices.some(index => drag.indices.includes(index))) {
					drags.delete(pointerId);
				}
			}
		}

		const angle = Math.atan2(horizontal, Math.max(point.y - pivotY, 1));
		const limited = drag.side < 0 ? clamp(angle, -maximumAngle, 0) : clamp(angle, 0, maximumAngle);
		for (const index of drag.indices) {
			angles[index] = limited;
			speeds[index] = 0;
		}

		drag.hasMoved = true;
		if (desk.reducedMotion) {
			draw();
		}
	});

	const release = event => {
		const drag = drags.get(event.pointerId);
		if (!drag) {
			return;
		}

		drags.delete(event.pointerId);
		// A finger that scrolls the page from a ball puts it back, as the visitor did not lift it.
		if (event.type === 'pointercancel') {
			for (const index of drag.indices) {
				angles[index] = 0;
			}

			draw();
			return;
		}

		// A click on a ball, which a first visitor tries before a drag, lifts it and the balls outside it, and lets go. A click while the other hand holds balls, or with reduced motion while balls are out, goes on as before.
		if (
			!drag.hasMoved
			&& drags.size === 0
			&& event.type === 'pointerup'
			&& (!desk.reducedMotion || (still.left === 0 && still.right === 0))
		) {
			if (drag.side === 0) {
				desk.say('Drag the middle ball out to one side, and let go.');
			} else if (drag.side < 0) {
				lift(drag.indices.length, 0);
			} else {
				lift(0, drag.indices.length);
			}

			return;
		}

		if (desk.reducedMotion) {
			if (!drag.hasMoved) {
				stepStill();
				return;
			}

			const left = angles.filter(angle => angle < -0.05).length;
			const right = angles.filter(angle => angle > 0.05).length;
			still = {left, right, amplitude: Math.max(...angles.map(angle => Math.abs(angle)))};
			showStill();
			desk.say('Let go. Press the cradle, or Space, for the next click-clack.');
			return;
		}

		if (drag.indices.length > 0) {
			const number = drag.indices.length;
			desk.say(drags.size > 0 ? 'Now let go of the other side too!' : `${names[number]} out, and ${names[number].toLowerCase()} out on the other side. The same number, every time. Pappa says it is the conservation of momentum.`);
		}

		loop.start();
	};

	desk.on(canvas, 'pointerup', release);
	desk.on(canvas, 'pointercancel', release);

	onKeys(desk, canvas, event => {
		if (['1', '2', '3'].includes(event.key)) {
			lift(Number(event.key), 0);
		} else if (event.key === 'b' || event.key === 'B') {
			lift(1, 1);
		} else if (event.key === ' ' || event.key === 'Enter') {
			if (desk.reducedMotion) {
				stepStill();
			} else {
				stop();
			}
		} else {
			return false;
		}
	});

	onButton(desk, 'cradle-one', () => {
		lift(1, 0);
	});
	onButton(desk, 'cradle-two', () => {
		lift(2, 0);
	});
	onButton(desk, 'cradle-three', () => {
		lift(3, 0);
	});
	onButton(desk, 'cradle-both', () => {
		lift(1, 1);
	});
	onButton(desk, 'cradle-stop', stop);

	draw();
};

// A jagged line of lightning from one point to another, made by moving the middle of each piece to the side, again and again.
const lightning = (from, to, roughness, levels = 5) => {
	let points = [from, to];
	for (let level = 0; level < levels; level++) {
		const next = [points[0]];
		for (let index = 1; index < points.length; index++) {
			const start = points[index - 1];
			const end = points[index];
			const length = Math.hypot(end.x - start.x, end.y - start.y);
			const offset = (Math.random() - 0.5) * roughness * length;
			next.push({
				x: ((start.x + end.x) / 2) - ((end.y - start.y) / (length || 1) * offset),
				y: ((start.y + end.y) / 2) + ((end.x - start.x) / (length || 1) * offset),
			}, end);
		}

		points = next;
	}

	return points;
};

// The plasma ball: lightning from the electrode in the middle to the glass, which all goes to a finger on the glass. The fluorescent tube next to it lights up in the field, with no cable.
const setupPlasma = (desk, canvas, sound) => {
	const context = canvas.getContext('2d');
	const center = {x: 190, y: 160};
	const radius = 116;
	const tubeLength = 150;
	const tubeFar = {x: 420, y: 196};
	const tubeNear = {x: 342, y: 150};
	const tube = {...tubeFar};
	const touchButton = deskButton(desk, 'plasma-touch');
	const tubeButton = deskButton(desk, 'plasma-tube');
	const powerButton = deskButton(desk, 'plasma-power');
	let isOn = true;
	let touch;
	let keyboardTouch = false;
	let fingerAngle = -0.7;
	let tubeDrag;
	let glow = 0;
	let hasTouched = false;
	let hasLitTube = false;
	const tendrils = Array.from({length: 7}, (_, index) => {
		const angle = (index / 7 * turn) + (Math.random() * 0.5);
		return {
			angle,
			drift: (Math.random() - 0.5) * 1.2,
			depth: Math.random() * turn,
			x: center.x + (Math.cos(angle) * radius * 0.9),
			y: center.y + (Math.sin(angle) * radius * 0.9),
		};
	});

	// The tube stands at an angle, and its top end is the end that is closest to the ball.
	const tubeTop = () => ({x: tube.x - 22, y: tube.y - (tubeLength / 2)});
	const tubeBottom = () => ({x: tube.x + 22, y: tube.y + (tubeLength / 2)});

	const distanceToTube = point => {
		const top = tubeTop();
		const bottom = tubeBottom();
		const lengthSquared = ((bottom.x - top.x) ** 2) + ((bottom.y - top.y) ** 2);
		const along = clamp((((point.x - top.x) * (bottom.x - top.x)) + ((point.y - top.y) * (bottom.y - top.y))) / lengthSquared, 0, 1);
		return Math.hypot(point.x - (top.x + (along * (bottom.x - top.x))), point.y - (top.y + (along * (bottom.y - top.y))));
	};

	const fieldAtTube = () => {
		if (!isOn) {
			return 0;
		}

		const top = tubeTop();
		const bottom = tubeBottom();
		let nearest = Number.POSITIVE_INFINITY;
		for (let step = 0; step <= 10; step++) {
			const x = top.x + ((bottom.x - top.x) * step / 10);
			const y = top.y + ((bottom.y - top.y) * step / 10);
			nearest = Math.min(nearest, Math.hypot(x - center.x, y - center.y) - radius);
		}

		return clamp(1 - (nearest / 90), 0, 1);
	};

	const touchPoint = () => {
		if (touch) {
			return touch;
		}

		if (keyboardTouch) {
			return {x: center.x + (Math.cos(fingerAngle) * radius * 0.94), y: center.y + (Math.sin(fingerAngle) * radius * 0.94)};
		}

		return undefined;
	};

	const updateBuzz = () => {
		sound.level(sound.buzz, isOn && visibility.isVisible ? (touchPoint() ? 0.07 : 0.03) : 0);
	};

	const visibility = desk.watchVisibility(canvas, updateBuzz);

	const update = delta => {
		const finger = touchPoint();
		const follow = desk.reducedMotion ? 1 : 1 - Math.exp(-delta * (finger ? 14 : 5));
		for (const tendril of tendrils) {
			tendril.angle += tendril.drift * delta;
			tendril.depth += delta * 0.9;
			if (Math.random() < delta * 0.5) {
				tendril.drift = (Math.random() - 0.5) * 1.4;
			}

			// The tendrils in front of and behind the electrode end inside the circle, as the ball is round.
			const reach = 0.72 + (0.26 * Math.abs(Math.cos(tendril.depth)));
			const target = finger ? {x: finger.x + ((Math.random() - 0.5) * 8), y: finger.y + ((Math.random() - 0.5) * 8)} : {x: center.x + (Math.cos(tendril.angle) * radius * reach), y: center.y + (Math.sin(tendril.angle) * radius * reach)};
			tendril.x += (target.x - tendril.x) * follow;
			tendril.y += (target.y - tendril.y) * follow;
		}

		const field = fieldAtTube();
		glow = desk.reducedMotion ? field : glow + ((field - glow) * (1 - Math.exp(-delta * 8)));
		if (field > 0.5 && !hasLitTube) {
			hasLitTube = true;
			desk.say('The tube lights up, with no cable at all! Pappa says it is the electric field. Trond says it is a lightsaber.');
		}
	};

	const strokeBolt = (points, widths) => {
		for (const [lineWidth, color] of widths) {
			context.strokeStyle = color;
			context.lineWidth = lineWidth;
			context.beginPath();
			context.moveTo(points[0].x, points[0].y);
			for (const point of points.slice(1)) {
				context.lineTo(point.x, point.y);
			}

			context.stroke();
		}
	};

	const drawTube = () => {
		const top = tubeTop();
		const bottom = tubeBottom();
		const angle = Math.atan2(bottom.y - top.y, bottom.x - top.x);
		const flicker = desk.reducedMotion ? 1 : 0.85 + (Math.random() * 0.15);
		const light = glow * flicker;

		if (light > 0.05) {
			const halo = context.createRadialGradient(tube.x, tube.y, 10, tube.x, tube.y, 120);
			halo.addColorStop(0, `rgba(200, 255, 255, ${0.35 * light})`);
			halo.addColorStop(1, 'rgba(200, 255, 255, 0)');
			context.fillStyle = halo;
			context.fillRect(tube.x - 120, tube.y - 120, 240, 240);
		}

		context.save();
		context.translate(tube.x, tube.y);
		context.rotate(angle);
		const glass = context.createLinearGradient(0, -8, 0, 8);
		if (light > 0.05) {
			glass.addColorStop(0, `rgba(230, 255, 255, ${0.5 + (0.5 * light)})`);
			glass.addColorStop(0.5, `rgba(255, 255, 255, ${0.6 + (0.4 * light)})`);
			glass.addColorStop(1, `rgba(170, 230, 240, ${0.5 + (0.5 * light)})`);
		} else {
			glass.addColorStop(0, '#c8ced2');
			glass.addColorStop(0.5, '#f2f4f5');
			glass.addColorStop(1, '#a8b0b6');
		}

		const half = Math.hypot(bottom.x - top.x, bottom.y - top.y) / 2;
		context.fillStyle = glass;
		context.beginPath();
		context.roundRect(-half, -7, half * 2, 14, 7);
		context.fill();
		// The metal caps and pins at the ends.
		context.fillStyle = '#8c9095';
		context.fillRect(-half - 2, -7, 12, 14);
		context.fillRect(half - 10, -7, 12, 14);
		context.fillStyle = '#5c6065';
		context.fillRect(-half - 7, -4, 5, 2);
		context.fillRect(-half - 7, 2, 5, 2);
		context.fillRect(half + 2, -4, 5, 2);
		context.fillRect(half + 2, 2, 5, 2);
		context.restore();

		// Pappa’s hand holds the tube at the bottom.
		context.fillStyle = '#e8b890';
		context.strokeStyle = '#a87050';
		context.lineWidth = 1.5;
		context.beginPath();
		context.roundRect(bottom.x - 34, bottom.y - 44, 30, 36, 9);
		context.fill();
		context.stroke();
		for (let finger = 0; finger < 3; finger++) {
			context.beginPath();
			context.moveTo(bottom.x - 33, bottom.y - 34 + (finger * 9));
			context.lineTo(bottom.x - 14, bottom.y - 34 + (finger * 9));
			context.stroke();
		}

		context.fillStyle = '#334466';
		context.fillRect(bottom.x - 32, bottom.y - 10, 26, 30);
	};

	const draw = () => {
		const background = context.createLinearGradient(0, 0, 0, height);
		background.addColorStop(0, '#0b0a18');
		background.addColorStop(1, '#03030a');
		context.fillStyle = background;
		context.fillRect(0, 0, width, height);
		drawDesk(context, 318, {light: '#3a2414', dark: '#1e1208'});

		// The glow of the ball on the desk and the wall.
		if (isOn) {
			const shine = context.createRadialGradient(center.x, center.y, radius * 0.5, center.x, center.y, radius * 2.2);
			shine.addColorStop(0, 'rgba(140, 60, 220, 0.25)');
			shine.addColorStop(1, 'rgba(140, 60, 220, 0)');
			context.fillStyle = shine;
			context.fillRect(0, 0, width, height);
		}

		// The black base with the switch.
		context.fillStyle = '#121212';
		context.beginPath();
		context.moveTo(center.x - 78, 330);
		context.lineTo(center.x - 46, center.y + radius - 18);
		context.lineTo(center.x + 46, center.y + radius - 18);
		context.lineTo(center.x + 78, 330);
		context.closePath();
		context.fill();
		context.fillStyle = '#2a2a2a';
		context.beginPath();
		context.ellipse(center.x, 330, 78, 9, 0, 0, turn);
		context.fill();
		context.fillStyle = isOn ? '#ff3030' : '#501010';
		context.beginPath();
		context.arc(center.x + 40, 312, 3, 0, turn);
		context.fill();

		// The glass, with the gas inside.
		const gas = context.createRadialGradient(center.x, center.y, 10, center.x, center.y, radius);
		gas.addColorStop(0, isOn ? '#3a1858' : '#141418');
		gas.addColorStop(1, isOn ? '#120420' : '#0a0a0e');
		context.fillStyle = gas;
		context.beginPath();
		context.arc(center.x, center.y, radius, 0, turn);
		context.fill();

		if (isOn) {
			const finger = touchPoint();
			context.save();
			context.beginPath();
			context.arc(center.x, center.y, radius - 2, 0, turn);
			context.clip();
			context.globalCompositeOperation = 'lighter';
			context.lineCap = 'round';
			context.lineJoin = 'round';
			for (const tendril of tendrils) {
				const points = lightning(center, tendril, finger ? 0.35 : 0.5);
				strokeBolt(points, [[finger ? 9 : 6, 'rgba(120, 40, 255, 0.18)'], [3, 'rgba(220, 90, 255, 0.5)'], [1.2, 'rgba(255, 220, 255, 0.9)']]);
				// A few small forks near the glass.
				if (!finger) {
					const fork = points[Math.floor(points.length * (0.6 + (Math.random() * 0.3)))];
					const angle = Math.atan2(tendril.y - center.y, tendril.x - center.x) + ((Math.random() - 0.5) * 1.6);
					strokeBolt(lightning(fork, {x: fork.x + (Math.cos(angle) * 26), y: fork.y + (Math.sin(angle) * 26)}, 0.6, 3), [[2, 'rgba(220, 90, 255, 0.4)'], [0.8, 'rgba(255, 220, 255, 0.7)']]);
				}

				// The end of the tendril spreads out on the glass, like a little flower.
				const end = context.createRadialGradient(tendril.x, tendril.y, 0, tendril.x, tendril.y, 10);
				end.addColorStop(0, 'rgba(255, 160, 255, 0.6)');
				end.addColorStop(1, 'rgba(255, 160, 255, 0)');
				context.fillStyle = end;
				context.fillRect(tendril.x - 10, tendril.y - 10, 20, 20);
			}

			if (finger) {
				const spot = context.createRadialGradient(finger.x, finger.y, 0, finger.x, finger.y, 34);
				spot.addColorStop(0, 'rgba(255, 255, 255, 0.95)');
				spot.addColorStop(0.3, 'rgba(255, 120, 255, 0.6)');
				spot.addColorStop(1, 'rgba(160, 60, 255, 0)');
				context.fillStyle = spot;
				context.fillRect(finger.x - 34, finger.y - 34, 68, 68);
			}

			context.restore();
		}

		// The electrode in the middle.
		const core = context.createRadialGradient(center.x, center.y, 0, center.x, center.y, 22);
		core.addColorStop(0, isOn ? '#ffffff' : '#555555');
		core.addColorStop(0.4, isOn ? '#ff9cff' : '#333333');
		core.addColorStop(1, isOn ? 'rgba(160, 60, 255, 0)' : '#22222200');
		context.fillStyle = core;
		context.beginPath();
		context.arc(center.x, center.y, 22, 0, turn);
		context.fill();

		// The shine of the glass.
		context.strokeStyle = 'rgba(255, 255, 255, 0.35)';
		context.lineWidth = 2;
		context.beginPath();
		context.arc(center.x, center.y, radius, 0, turn);
		context.stroke();
		context.strokeStyle = 'rgba(255, 255, 255, 0.4)';
		context.lineWidth = 6;
		context.lineCap = 'round';
		context.beginPath();
		context.arc(center.x, center.y, radius - 14, Math.PI * 1.1, Math.PI * 1.4);
		context.stroke();

		// A finger on the glass.
		const finger = touchPoint();
		if (finger) {
			context.fillStyle = '#e8b890cc';
			context.beginPath();
			context.ellipse(finger.x, finger.y + 2, 9, 12, 0, 0, turn);
			context.fill();
		}

		drawTube();
	};

	const loop = toyLoop(desk, canvas, delta => {
		update(delta);
		draw();
	}, () => isOn && !desk.reducedMotion);

	const refresh = () => {
		updateBuzz();
		if (desk.reducedMotion) {
			update(1);
		} else {
			loop.start();
		}

		draw();
	};

	const isOnGlass = point => Math.hypot(point.x - center.x, point.y - center.y) < radius;

	const touchAt = point => {
		const distance = Math.hypot(point.x - center.x, point.y - center.y);
		const scale = Math.min(1, (radius * 0.94) / distance);
		touch = {x: center.x + ((point.x - center.x) * scale), y: center.y + ((point.y - center.y) * scale)};
		if (!hasTouched && isOn) {
			hasTouched = true;
			desk.say('Zzzap! All the lightning goes to your finger. Lillesøster says it tickles.');
			sound.burst(0.2, {volume: 0.3, frequency: 3000, type: 'highpass'});
		}
	};

	const moveTube = point => {
		tube.x = clamp(point.x, 30, width - 30);
		tube.y = clamp(point.y, 90, height - 80);
		// The tube cannot go through the glass of the ball.
		const top = tubeTop();
		const distance = Math.hypot(top.x - center.x, top.y - center.y);
		if (distance < radius + 8) {
			const push = (radius + 8 - distance) / distance;
			tube.x += (top.x - center.x) * push;
			tube.y += (top.y - center.y) * push;
		}
	};

	desk.on(canvas, 'pointerdown', event => {
		const point = canvasPoint(canvas, event);
		event.preventDefault();
		canvas.focus({preventScroll: true});
		canvas.setPointerCapture(event.pointerId);
		if (distanceToTube(point) < 24 || (point.x > tube.x - 50 && point.x < tube.x + 30 && point.y > tubeBottom().y - 50 && point.y < tubeBottom().y + 20)) {
			tubeDrag = {x: point.x - tube.x, y: point.y - tube.y};
		} else if (isOnGlass(point)) {
			touchAt(point);
		}

		refresh();
	});

	desk.on(canvas, 'pointermove', event => {
		const point = canvasPoint(canvas, event);
		if (tubeDrag) {
			moveTube({x: point.x - tubeDrag.x, y: point.y - tubeDrag.y});
		} else if (event.buttons > 0 && touch) {
			touchAt(point);
		} else if (event.pointerType === 'mouse' && event.buttons === 0) {
			// A mouse that only hovers over the glass also touches it, like a hand that comes close.
			if (isOnGlass(point)) {
				touchAt(point);
			} else {
				touch = undefined;
			}
		} else {
			return;
		}

		refresh();
	});

	const letGo = event => {
		tubeDrag = undefined;
		if (event.pointerType !== 'mouse' || event.type !== 'pointerup') {
			touch = undefined;
		}

		refresh();
	};

	desk.on(canvas, 'pointerup', letGo);
	desk.on(canvas, 'pointercancel', letGo);
	desk.on(canvas, 'pointerleave', () => {
		if (!tubeDrag) {
			touch = undefined;
			refresh();
		}
	});

	const toggleTouch = () => {
		keyboardTouch = !keyboardTouch;
		touchButton.textContent = keyboardTouch ? '✋ Let Go' : '☝️ Touch the Glass';
		if (keyboardTouch && !hasTouched && isOn) {
			hasTouched = true;
			desk.say('Zzzap! All the lightning goes to the finger. Lillesøster says it tickles.');
		}

		refresh();
	};

	const toggleTube = () => {
		const isNear = Math.hypot(tube.x - tubeNear.x, tube.y - tubeNear.y) < 20;
		moveTube(isNear ? tubeFar : tubeNear);
		if (isNear) {
			desk.say('The tube goes back, and it goes dark.');
		}

		refresh();
	};

	const togglePower = () => {
		isOn = !isOn;
		powerButton.textContent = isOn ? '⏻ Off' : '⏻ On';
		sound.tick();
		desk.say(isOn ? 'Bzzzz. The plasma ball is on, and the lightning is back.' : 'The plasma ball is off. Pappa says it saves power. Mamma says it saves her nerves.');
		refresh();
	};

	onKeys(desk, canvas, event => {
		if (event.key === ' ' || event.key === 'Enter') {
			toggleTouch();
		} else if (event.key === 'ArrowLeft' || event.key === 'ArrowUp') {
			fingerAngle -= 0.2;
			if (keyboardTouch) {
				refresh();
			} else {
				toggleTouch();
			}
		} else if (event.key === 'ArrowRight' || event.key === 'ArrowDown') {
			fingerAngle += 0.2;
			if (keyboardTouch) {
				refresh();
			} else {
				toggleTouch();
			}
		} else if (event.key === 't' || event.key === 'T') {
			toggleTube();
		} else {
			return false;
		}
	});

	desk.on(touchButton, 'click', toggleTouch);
	desk.on(tubeButton, 'click', toggleTube);
	desk.on(powerButton, 'click', togglePower);

	update(1);
	draw();

	// The sound button tells the buzz when the sound goes on or off.
	return updateBuzz;
};

// Pin art: a frame of steel pins, which a hand pushes out from behind. The pins that are out are lighter and cast a longer shadow, so the shape shows in 3D.
const setupPins = (desk, canvas, sound) => {
	const context = canvas.getContext('2d');
	const columns = 44;
	const rows = 32;
	const spacing = 10;
	const left = 25;
	const top = 25;
	const heights = new Float32Array(columns * rows);
	const targets = new Float32Array(columns * rows);
	const cursor = {column: 22, row: 16, isVisible: false};
	let flip;
	let lastPoint;
	let lastSound = 0;
	let hasPressed = false;

	// A press during a flip waits for nothing: the flip is done at once, so the press is not lost.
	const finishFlip = () => {
		if (flip && !flip.hasReset) {
			heights.fill(0);
			targets.fill(0);
		}

		flip = undefined;
	};

	const pressAt = (column, row, size = 2.6) => {
		finishFlip();
		for (let y = Math.max(0, Math.floor(row - size)); y <= Math.min(rows - 1, Math.ceil(row + size)); y++) {
			for (let x = Math.max(0, Math.floor(column - size)); x <= Math.min(columns - 1, Math.ceil(column + size)); x++) {
				const distance = Math.hypot(x - column, y - row) / size;
				if (distance < 1) {
					const index = (y * columns) + x;
					targets[index] = Math.max(targets[index], Math.sqrt(1 - (distance * distance)));
				}
			}
		}
	};

	// Each stamp is drawn in gray on a small canvas, four pixels for each pin, and lighter gray pushes a pin out farther.
	const stamps = {
		hand(stamp) {
			stamp.fillStyle = '#c8c8c8';
			stamp.beginPath();
			stamp.ellipse(88, 86, 26, 28, 0, 0, turn);
			stamp.fill();
			stamp.fillRect(70, 100, 36, 28);
			stamp.strokeStyle = '#ececec';
			stamp.lineCap = 'round';
			stamp.lineWidth = 11;
			for (const [fromX, fromY, toX, toY] of [[66, 92, 38, 66], [74, 64, 64, 14], [88, 60, 88, 6], [102, 64, 112, 14], [110, 74, 132, 40]]) {
				stamp.beginPath();
				stamp.moveTo(fromX, fromY);
				stamp.lineTo(toX, toY);
				stamp.stroke();
			}

			// The lines in the palm, which Mormor says tell the future.
			stamp.strokeStyle = '#8c8c8c';
			stamp.lineWidth = 3;
			stamp.beginPath();
			stamp.moveTo(68, 78);
			stamp.quadraticCurveTo(90, 74, 108, 82);
			stamp.moveTo(72, 98);
			stamp.quadraticCurveTo(80, 84, 104, 92);
			stamp.stroke();
		},
		fist(stamp) {
			stamp.fillStyle = '#c0c0c0';
			stamp.beginPath();
			stamp.roundRect(52, 40, 76, 62, 18);
			stamp.fill();
			stamp.fillStyle = '#f2f2f2';
			for (let knuckle = 0; knuckle < 4; knuckle++) {
				stamp.beginPath();
				stamp.ellipse(64 + (knuckle * 17), 48, 9, 8, 0, 0, turn);
				stamp.fill();
			}

			stamp.fillStyle = '#909090';
			for (let gap = 0; gap < 3; gap++) {
				stamp.fillRect(71 + (gap * 17), 58, 3, 30);
			}

			stamp.fillStyle = '#dadada';
			stamp.beginPath();
			stamp.ellipse(80, 92, 30, 9, -0.15, 0, turn);
			stamp.fill();
			stamp.fillStyle = '#a8a8a8';
			stamp.fillRect(66, 100, 46, 28);
		},
		face(stamp) {
			stamp.fillStyle = '#909090';
			stamp.beginPath();
			stamp.ellipse(88, 66, 38, 50, 0, 0, turn);
			stamp.fill();
			// The bowl cut, which every boy in Bergen had in 1999.
			stamp.fillStyle = '#b4b4b4';
			stamp.beginPath();
			stamp.ellipse(88, 34, 42, 24, 0, Math.PI, turn);
			stamp.fill();
			stamp.fillRect(46, 30, 84, 10);
			stamp.fillStyle = '#c0c0c0';
			for (const x of [72, 104]) {
				stamp.beginPath();
				stamp.ellipse(x, 48, 13, 4, 0, 0, turn);
				stamp.fill();
			}

			stamp.fillStyle = '#3a3a3a';
			for (const x of [72, 104]) {
				stamp.beginPath();
				stamp.ellipse(x, 58, 9, 6, 0, 0, turn);
				stamp.fill();
			}

			stamp.fillStyle = '#ffffff';
			stamp.beginPath();
			stamp.moveTo(88, 52);
			stamp.lineTo(98, 84);
			stamp.lineTo(78, 84);
			stamp.closePath();
			stamp.fill();
			stamp.fillStyle = '#b0b0b0';
			for (const x of [62, 114]) {
				stamp.beginPath();
				stamp.ellipse(x, 84, 10, 8, 0, 0, turn);
				stamp.fill();
			}

			stamp.fillStyle = '#d0d0d0';
			stamp.beginPath();
			stamp.ellipse(88, 100, 17, 7, 0, 0, turn);
			stamp.fill();
			stamp.fillStyle = '#505050';
			stamp.fillRect(72, 99, 32, 3);
		},
		rocky(stamp) {
			stamp.fillStyle = '#b4b4b4';
			stamp.beginPath();
			for (let point = 0; point <= 12; point++) {
				const angle = point / 12 * turn;
				const distance = 1 + (0.12 * Math.sin(point * 2.7)) + (0.08 * Math.cos(point * 1.3));
				const x = 88 + (Math.cos(angle) * 54 * distance);
				const y = 74 + (Math.sin(angle) * 38 * distance);
				if (point === 0) {
					stamp.moveTo(x, y);
				} else {
					stamp.lineTo(x, y);
				}
			}

			stamp.fill();
			for (const x of [70, 106]) {
				stamp.fillStyle = '#ffffff';
				stamp.beginPath();
				stamp.arc(x, 60, 13, 0, turn);
				stamp.fill();
				stamp.fillStyle = '#7a7a7a';
				stamp.beginPath();
				stamp.arc(x + 3, 64, 6, 0, turn);
				stamp.fill();
			}

			stamp.fillStyle = '#8c8c8c';
			stamp.fillRect(76, 92, 24, 3);
		},
	};

	const stampMessages = {
		hand: 'Pappa’s hand, five fingers in steel. It looks like he waves from the other side.',
		fist: 'A fist! Pappa says this is how he feels about the fax machine.',
		face: 'My face, in 1 408 pins. Mamma says I should not press my face into things at Pappa’s office.',
		rocky: 'Rocky the pet rock, in pins. He held very still for it. He always does.',
	};

	const stamp = name => {
		finishFlip();
		const scratch = document.createElement('canvas');
		scratch.width = columns * 4;
		scratch.height = rows * 4;
		const scratchContext = scratch.getContext('2d', {willReadFrequently: true});
		scratchContext.filter = 'blur(1.5px)';
		// A stamp lands a bit to the side each time, so two stamps make two shapes.
		const shiftX = Math.round((Math.random() - 0.5) * 30);
		const shiftY = Math.round((Math.random() - 0.5) * 12);
		scratchContext.translate(shiftX, shiftY);
		stamps[name](scratchContext);
		const pixels = scratchContext.getImageData(0, 0, scratch.width, scratch.height).data;
		for (let row = 0; row < rows; row++) {
			for (let column = 0; column < columns; column++) {
				const value = pixels[((((row * 4) + 2) * scratch.width) + (column * 4) + 2) * 4] / 255;
				const index = (row * columns) + column;
				targets[index] = Math.max(targets[index], value);
			}
		}

		sound.burst(0.25, {volume: 0.25, frequency: 3000, type: 'highpass'});
		desk.say(stampMessages[name]);
		refresh();
	};

	const isMoving = () => flip !== undefined || targets.some((target, index) => Math.abs(target - heights[index]) > 0.002);

	const update = (delta, time) => {
		if (flip) {
			flip.progress = Math.min(1, flip.progress + (delta / 0.7));
			// Halfway, the frame is on its edge, and the pins slide back.
			if (flip.progress >= 0.5 && !flip.hasReset) {
				flip.hasReset = true;
				heights.fill(0);
				targets.fill(0);
			}

			if (flip.progress >= 1) {
				flip = undefined;
			}
		}

		const follow = 1 - Math.exp(-delta * 16);
		for (let index = 0; index < heights.length; index++) {
			heights[index] += (targets[index] - heights[index]) * follow;
			if (Math.abs(targets[index] - heights[index]) < 0.002) {
				heights[index] = targets[index];
			}
		}

		if (!flip && time - lastSound > 70 && isMoving()) {
			lastSound = time;
			sound.burst(0.04, {volume: 0.05, frequency: 5000, type: 'highpass'});
		}
	};

	const draw = () => {
		context.fillStyle = '#1b1b1d';
		context.fillRect(0, 0, width, height);
		context.save();
		if (flip) {
			const squash = Math.max(0.02, Math.abs(Math.cos(flip.progress * Math.PI)));
			context.translate(0, height / 2);
			context.scale(1, squash);
			context.translate(0, -height / 2);
		}

		// The black plastic frame, and the clear front.
		context.fillStyle = '#0c0c0e';
		context.beginPath();
		context.roundRect(4, 4, width - 8, height - 8, 10);
		context.fill();
		context.fillStyle = '#2a2d33';
		context.fillRect(14, 14, width - 28, height - 28);

		// The shadows first, longer for the pins that are out farther.
		context.fillStyle = 'rgba(0, 0, 0, 0.45)';
		context.beginPath();
		for (let row = 0; row < rows; row++) {
			for (let column = 0; column < columns; column++) {
				const height = heights[(row * columns) + column];
				if (height > 0.05) {
					const x = left + (column * spacing) + (height * 5);
					const y = top + (row * spacing) + (height * 5);
					context.moveTo(x + 4.5, y);
					context.arc(x, y, 4.5, 0, turn);
				}
			}
		}

		context.fill();

		// Then the heads, in layers from the flat ones to the ones that are out, so a pin that is out is on top of its neighbors. A head is lit by the slope of the pins around it, light from the top left, which shows the shape in 3D.
		const layers = 6;
		const shades = 10;
		const groups = Array.from({length: layers * shades}, () => []);
		const heightAt = (column, row) => heights[(clamp(row, 0, rows - 1) * columns) + clamp(column, 0, columns - 1)];
		for (let row = 0; row < rows; row++) {
			for (let column = 0; column < columns; column++) {
				const height = heightAt(column, row);
				const slope = (heightAt(column + 1, row) - heightAt(column - 1, row)) + (heightAt(column, row + 1) - heightAt(column, row - 1));
				const light = clamp(0.12 + (0.5 * height) + (0.9 * slope), 0, 1);
				const layer = Math.min(layers - 1, Math.floor(height * layers));
				groups[(layer * shades) + Math.min(shades - 1, Math.floor(light * shades))].push(column, row);
			}
		}

		for (const [group, pins] of groups.entries()) {
			if (pins.length === 0) {
				continue;
			}

			const shade = Math.round(50 + ((group % shades) * 22));
			context.fillStyle = `rgb(${shade}, ${shade + 5}, ${shade + 12})`;
			context.beginPath();
			const highlights = [];
			for (let index = 0; index < pins.length; index += 2) {
				const height = heightAt(pins[index], pins[index + 1]);
				const x = left + (pins[index] * spacing) - (height * 4);
				const y = top + (pins[index + 1] * spacing) - (height * 4);
				const size = 3.7 + (height * 0.7);
				context.moveTo(x + size, y);
				context.arc(x, y, size, 0, turn);
				highlights.push(x, y);
			}

			context.fill();
			context.fillStyle = `rgba(255, 255, 255, ${0.15 + ((group % shades) * 0.06)})`;
			context.beginPath();
			for (let index = 0; index < highlights.length; index += 2) {
				context.moveTo(highlights[index], highlights[index + 1]);
				context.arc(highlights[index] - 1.3, highlights[index + 1] - 1.3, 1.3, 0, turn);
			}

			context.fill();
		}

		// The glare on the clear plastic front.
		const glare = context.createLinearGradient(0, 0, width, height);
		glare.addColorStop(0, 'rgba(255, 255, 255, 0.08)');
		glare.addColorStop(0.4, 'rgba(255, 255, 255, 0)');
		context.fillStyle = glare;
		context.fillRect(14, 14, width - 28, height - 28);

		if (cursor.isVisible) {
			context.strokeStyle = '#ffcc00';
			context.lineWidth = 2;
			context.beginPath();
			context.arc(left + (cursor.column * spacing), top + (cursor.row * spacing), 26, 0, turn);
			context.stroke();
		}

		context.restore();
	};

	const loop = toyLoop(desk, canvas, (delta, time) => {
		update(delta, time);
		draw();
	}, isMoving);

	const refresh = () => {
		if (desk.reducedMotion) {
			heights.set(targets);
		} else {
			loop.start();
		}

		draw();
	};

	const pinAt = point => ({column: (point.x - left) / spacing, row: (point.y - top) / spacing});

	desk.on(canvas, 'pointerdown', event => {
		event.preventDefault();
		canvas.focus({preventScroll: true});
		canvas.setPointerCapture(event.pointerId);
		cursor.isVisible = false;
		lastPoint = pinAt(canvasPoint(canvas, event));
		pressAt(lastPoint.column, lastPoint.row);
		refresh();
		// The first press says what happens, as the note still shows the toy that was used before.
		if (!hasPressed) {
			hasPressed = true;
			desk.say('The shape comes out on the front of the pins. Drag to draw, or try a stamp.');
		}
	});

	desk.on(canvas, 'pointermove', event => {
		if (!lastPoint) {
			return;
		}

		// The pins between two moves are pressed too, so a fast drag leaves no gaps.
		const point = pinAt(canvasPoint(canvas, event));
		const distance = Math.hypot(point.column - lastPoint.column, point.row - lastPoint.row);
		const steps = Math.max(1, Math.ceil(distance * 2));
		for (let step = 1; step <= steps; step++) {
			pressAt(lastPoint.column + ((point.column - lastPoint.column) * step / steps), lastPoint.row + ((point.row - lastPoint.row) * step / steps));
		}

		lastPoint = point;
		refresh();
	});

	const letGo = () => {
		lastPoint = undefined;
	};

	desk.on(canvas, 'pointerup', letGo);
	desk.on(canvas, 'pointercancel', letGo);

	const flipOver = () => {
		sound.burst(0.6, {volume: 0.2, frequency: 6000, type: 'highpass'});
		desk.say('Flip! The pins slide back, and the pin art is flat again.');
		if (desk.reducedMotion) {
			heights.fill(0);
			targets.fill(0);
			draw();
			return;
		}

		flip = {progress: 0, hasReset: false};
		loop.start();
	};

	desk.on(canvas, 'blur', () => {
		cursor.isVisible = false;
		draw();
	});

	onKeys(desk, canvas, event => {
		const moves = {ArrowLeft: [-1, 0], ArrowRight: [1, 0], ArrowUp: [0, -1], ArrowDown: [0, 1]};
		if (moves[event.key]) {
			const [column, row] = moves[event.key];
			cursor.column = clamp(cursor.column + column, 0, columns - 1);
			cursor.row = clamp(cursor.row + row, 0, rows - 1);
			cursor.isVisible = true;
			pressAt(cursor.column, cursor.row);
			refresh();
		} else if (event.key === ' ' || event.key === 'Enter') {
			cursor.isVisible = true;
			pressAt(cursor.column, cursor.row, 3.4);
			refresh();
		} else if (event.key === 'f' || event.key === 'F') {
			flipOver();
		} else {
			return false;
		}
	});

	for (const name of Object.keys(stamps)) {
		onButton(desk, `pins-${name}`, () => {
			stamp(name);
		});
	}

	onButton(desk, 'pins-flip', flipOver);

	draw();
};

// The drinking bird: the red liquid rises in its neck while its wet head cools, so it tips over, dips its beak in the water, and swings back up when the liquid runs back down. It stops when the glass is too empty for the beak to reach.
const setupBird = (desk, canvas, sound) => {
	const context = canvas.getContext('2d');
	const keyboardButton = deskButton(desk, 'bird-keyboard');
	const pivot = {x: 205, y: 178};
	const headDistance = 100;
	const bulbDistance = 90;
	const beakLength = 40;
	const rest = 0.1;
	const dip = 1.45;
	const glass = {left: 290, right: 360, rim: 168, bottom: 250};
	const fullWater = 178;
	const prompts = [
		'FORMAT C:? (Y/N)',
		'DELETE ALL E-MAIL? (Y/N)',
		'FAX ALL 312 CUSTOMERS? (Y/N)',
		'ORDER 400 WAFFLES? (Y/N)',
		'APPROVE Y2K BUDGET? (Y/N)',
		'MORE POCKET MONEY FOR SINDRE? (Y/N)',
		'INSTALL WINDOWS 98 SE? (Y/N)',
		'CANCEL MEETING WITH BOSS? (Y/N)',
		'REPLY ALL? (Y/N)',
		'ARE YOU SURE? (Y/N)',
	];
	let angle = rest;
	let speed = 0;
	let liquid = 0.3;
	let wetness = 1;
	let water = 1;
	let dipTime = 0;
	let isDipping = false;
	let isOverKeyboard = false;
	let hasWarned = false;
	let keyPress = 0;
	let stillStep = 0;
	let dips = loadCount(desk, 'dips');
	let promptIndex = 0;
	let typed = 0;
	const screenLines = ['C:\\PAPPA> RUN WORK.BAT', prompts[0]];

	const waterTop = () => fullWater + ((glass.bottom - fullWater) * (1 - water));
	const local = (x, y, at = angle) => ({x: pivot.x + (x * Math.cos(at)) - (y * Math.sin(at)), y: pivot.y + (x * Math.sin(at)) + (y * Math.cos(at))});
	const beakTip = (at = angle) => local(beakLength, -headDistance + 2, at);

	// The beak is at the bottom: it drinks, or it presses Y.
	const drink = () => {
		dips++;
		desk.store('dips', dips);
		if (isOverKeyboard) {
			keyPress = 1;
			sound.tick();
			screenLines[screenLines.length - 1] += ' Y';
			promptIndex = (promptIndex + 1) % prompts.length;
			screenLines.push(prompts[promptIndex]);
			while (screenLines.length > 6) {
				screenLines.shift();
			}

			// Only the first answers are said, so the bird does not talk over the other toys all day.
			typed++;
			if (typed <= 3) {
				desk.say(`The bird presses Y. ${screenLines.at(-2).replace(' (Y/N) Y', '')} Yes!`);
			}

			return;
		}

		if (beakTip(dip).y > waterTop() + 2) {
			wetness = 1;
			water = Math.max(0, water - 0.045);
			sound.tone(880, 0.08, {type: 'sine', volume: 0.12, slide: 1400});
			sound.burst(0.06, {volume: 0.1, frequency: 1500, type: 'bandpass'});
			if (dips % 10 === 0) {
				desk.say(`${dips} dips! The bird is very thirsty today.`);
			} else if (desk.reducedMotion) {
				desk.say('Slurp! The beak dips into the water, and the head gets wet again.');
			}
		} else {
			sound.tone(330, 0.05, {type: 'triangle', volume: 0.06});
			if (!hasWarned) {
				hasWarned = true;
				desk.say('The beak does not reach the water anymore. The head dries, and the bird slows down. Refill the glass!');
			}
		}
	};

	const update = delta => {
		if (isDipping) {
			dipTime += delta;
			angle = dip;
			if (dipTime > 0.7) {
				// The liquid runs back down into the bulb, and the bird swings up.
				isDipping = false;
				liquid = 0;
				speed = -1.4;
			}

			return;
		}

		// The wet head cools, and the cool head pulls the liquid up the neck, so the bird gets heavier in the front.
		liquid = Math.min(1, liquid + (delta * wetness / 6));
		if (!isOverKeyboard) {
			wetness = Math.max(0, wetness - (delta / 24));
		}

		const balance = rest + (liquid * (dip + 0.25 - rest));
		speed += ((-15 * (angle - balance)) - (0.9 * speed)) * delta;
		angle += speed * delta;
		if (angle >= dip) {
			angle = dip;
			speed = 0;
			isDipping = true;
			dipTime = 0;
			drink();
		}

		angle = Math.max(angle, -0.5);
		keyPress = Math.max(0, keyPress - (delta * 4));
	};

	const isBusy = () => !desk.reducedMotion && (isDipping || wetness > 0.001 || Math.abs(speed) > 0.004);

	const drawGlass = () => {
		// Pappa’s binders, which the glass stands on.
		const binders = isOverKeyboard ? [[262, 214, '#2850a0', 'Y2K'], [256, 236, '#a02828', 'BUDSJETT'], [266, 258, '#287040', 'ÅRSRAPPORT 1998'], [258, 280, '#555555', 'MØTER']] : [[262, 258, '#287040', 'ÅRSRAPPORT 1998'], [256, 280, '#a02828', 'BUDSJETT']];
		for (const [x, y, color, label] of binders) {
			context.fillStyle = color;
			context.fillRect(x, y, 140, 22);
			context.fillStyle = '#ffffffdd';
			context.fillRect(x + 30, y + 5, 80, 12);
			context.fillStyle = '#111111';
			context.font = 'bold 9px Arial, sans-serif';
			context.textAlign = 'center';
			context.fillText(label, x + 70, y + 14);
		}

		if (isOverKeyboard) {
			// Pappa’s beige keyboard, with the Y key under the beak.
			context.fillStyle = '#d8d0b8';
			context.beginPath();
			context.moveTo(262, 214);
			context.lineTo(404, 214);
			context.lineTo(396, 196);
			context.lineTo(270, 196);
			context.closePath();
			context.fill();
			context.fillStyle = '#b8b098';
			context.fillRect(262, 212, 142, 3);
			for (let row = 0; row < 3; row++) {
				for (let key = 0; key < 11; key++) {
					const x = 274 + (key * 11) - (row * 1.5);
					const y = 199 + (row * 5);
					const isY = row === 0 && key === 4;
					context.fillStyle = isY ? (keyPress > 0 ? '#ffe680' : '#f2ecd8') : '#ece4cc';
					context.fillRect(x, y + (isY ? keyPress * 1.5 : 0), 9, 4);
				}
			}

			context.fillStyle = '#333333';
			context.font = 'bold 5px Arial, sans-serif';
			context.fillText('Y', 322, 203 + (keyPress * 1.5));
			return;
		}

		const top = waterTop();
		context.fillStyle = 'rgba(120, 180, 230, 0.55)';
		context.fillRect(glass.left + 3, top, glass.right - glass.left - 6, glass.bottom - top - 3);
		context.fillStyle = 'rgba(220, 240, 255, 0.7)';
		context.fillRect(glass.left + 3, top, glass.right - glass.left - 6, 2);
		context.strokeStyle = 'rgba(230, 245, 255, 0.85)';
		context.lineWidth = 2.5;
		context.beginPath();
		context.moveTo(glass.left, glass.rim);
		context.lineTo(glass.left + 3, glass.bottom);
		context.lineTo(glass.right - 3, glass.bottom);
		context.lineTo(glass.right, glass.rim);
		context.stroke();
		context.fillStyle = 'rgba(255, 255, 255, 0.25)';
		context.fillRect(glass.left + 8, glass.rim + 6, 5, 70);
	};

	const drawScreen = () => {
		// Pappa’s monitor, where the bird answers the questions.
		context.fillStyle = '#d8d0b8';
		context.beginPath();
		context.roundRect(286, 10, 186, 128, 8);
		context.fill();
		context.fillStyle = '#0a1a0a';
		context.fillRect(296, 18, 166, 104);
		context.font = 'bold 9px "Courier New", monospace';
		context.textAlign = 'left';
		context.fillStyle = '#44ff66';
		for (const [index, line] of screenLines.entries()) {
			context.fillText(line, 300, 32 + (index * 15), 158);
		}

		context.fillStyle = '#b8b098';
		context.fillRect(350, 138, 60, 8);
	};

	const draw = () => {
		const wall = context.createLinearGradient(0, 0, 0, 300);
		wall.addColorStop(0, '#d8d2bc');
		wall.addColorStop(1, '#b0a88e');
		context.fillStyle = wall;
		context.fillRect(0, 0, width, height);
		// The blinds of the office window, with the rain of Bergen behind them.
		context.fillStyle = '#8a9aa8';
		context.fillRect(20, 20, 150, 110);
		context.fillStyle = '#e8e4d8';
		for (let slat = 0; slat < 11; slat++) {
			context.fillRect(20, 22 + (slat * 10), 150, 6);
		}

		drawDesk(context, 300);

		if (isOverKeyboard) {
			drawScreen();
		}

		// The stand: two brass legs and the feet.
		context.strokeStyle = '#b08a30';
		context.lineWidth = 4;
		for (const offset of [-22, 22]) {
			context.beginPath();
			context.moveTo(pivot.x, pivot.y);
			context.lineTo(pivot.x + offset, 296);
			context.stroke();
		}

		context.fillStyle = '#7a5a18';
		context.fillRect(pivot.x - 34, 294, 68, 6);

		context.save();
		context.translate(pivot.x, pivot.y);
		context.rotate(angle);

		// The tail feather.
		context.strokeStyle = '#e8a020';
		context.lineWidth = 3;
		for (let feather = 0; feather < 3; feather++) {
			context.beginPath();
			context.moveTo(-4, 40);
			context.quadraticCurveTo(-30, 30 + (feather * 8), -46, 16 + (feather * 12));
			context.stroke();
		}

		// The glass neck and the bulb, with the red liquid.
		context.fillStyle = 'rgba(220, 240, 255, 0.35)';
		context.fillRect(-5, -headDistance + 10, 10, headDistance + bulbDistance - 30);
		const neckBottom = bulbDistance - 22;
		const neckTop = -headDistance + 14;
		const level = neckBottom - ((neckBottom - neckTop) * liquid);
		context.fillStyle = '#d01818';
		context.fillRect(-3, level, 6, neckBottom - level + 4);
		context.fillStyle = 'rgba(220, 240, 255, 0.4)';
		context.beginPath();
		context.arc(0, bulbDistance, 26, 0, turn);
		context.fill();
		context.fillStyle = '#d01818';
		context.beginPath();
		context.arc(0, bulbDistance, 24, Math.PI * (0.05 + (liquid * 0.3)), Math.PI * (0.95 - (liquid * 0.3)));
		context.fill();
		context.strokeStyle = 'rgba(255, 255, 255, 0.7)';
		context.lineWidth = 2;
		context.beginPath();
		context.arc(0, bulbDistance, 26, 0, turn);
		context.stroke();
		context.beginPath();
		context.arc(0, bulbDistance, 18, Math.PI * 1.1, Math.PI * 1.4);
		context.stroke();
		// The pivot bar on the neck.
		context.fillStyle = '#c8a040';
		context.fillRect(-10, -3, 20, 6);

		// The fuzzy blue head, a bit darker while it is wet.
		context.fillStyle = wetness > 0.3 ? '#1e3c9a' : '#3a62d8';
		context.beginPath();
		context.arc(0, -headDistance, 17, 0, turn);
		context.fill();
		context.fillStyle = '#ffffff';
		context.beginPath();
		context.arc(8, -headDistance - 5, 5, 0, turn);
		context.fill();
		context.fillStyle = '#000000';
		context.beginPath();
		context.arc(9.5, -headDistance - 5, 2.4, 0, turn);
		context.fill();

		// The beak.
		context.fillStyle = '#f4c430';
		context.beginPath();
		context.moveTo(12, -headDistance - 4);
		context.lineTo(beakLength, -headDistance + 2);
		context.lineTo(12, -headDistance + 7);
		context.closePath();
		context.fill();

		// The black top hat with a red band.
		context.fillStyle = '#111111';
		context.fillRect(-20, -headDistance - 17, 40, 5);
		context.fillRect(-13, -headDistance - 42, 26, 26);
		context.fillStyle = '#c01818';
		context.fillRect(-13, -headDistance - 22, 26, 5);
		context.restore();

		drawGlass();

		context.fillStyle = '#222222';
		context.font = 'bold 13px "Comic Sans MS", "Comic Sans", cursive';
		context.textAlign = 'left';
		context.fillText(`Dips: ${dips}`, 20, 150);
	};

	const loop = toyLoop(desk, canvas, delta => {
		update(delta);
		draw();
	}, isBusy);

	// With reduced motion, each press is a step of the cycle: upright, tipping, and down in the water.
	const stepStill = () => {
		stillStep = (stillStep + 1) % 3;
		if (stillStep === 1) {
			angle = (rest + dip) / 2;
			liquid = 0.6;
			desk.say('The red liquid climbs up the neck, and the bird tips over.');
		} else if (stillStep === 2) {
			angle = dip;
			liquid = 1;
			drink();
		} else {
			angle = rest;
			liquid = 0;
			keyPress = 0;
			desk.say('The liquid runs back down, and the bird stands up again.');
		}

		draw();
	};

	const tip = () => {
		if (desk.reducedMotion) {
			stepStill();
			return;
		}

		speed += 1.6;
		wetness = Math.max(wetness, 0.4);
		desk.say('You tip the bird, and it dips its beak.');
		loop.start();
	};

	// A click, not a press, tips it, so a finger that scrolls the page over the bird does not tip it.
	desk.on(canvas, 'click', () => {
		canvas.focus({preventScroll: true});
		tip();
	});

	onKeys(desk, canvas, event => {
		if (event.key === ' ' || event.key === 'Enter') {
			tip();
		} else {
			return false;
		}
	});

	onButton(desk, 'bird-tip', tip);

	onButton(desk, 'bird-refill', () => {
		water = 1;
		wetness = 1;
		hasWarned = false;
		sound.burst(0.8, {volume: 0.15, frequency: 900, type: 'bandpass'});
		desk.say(isOverKeyboard ? 'You fill the glass, but the bird is over the keyboard now. It does not need water to press Y.' : 'Pappa fills the glass from the tap in the kitchen of the office, and wets the head of the bird. Off it goes again.');
		draw();
		loop.start();
	});

	desk.on(keyboardButton, 'click', () => {
		isOverKeyboard = !isOverKeyboard;
		typed = 0;
		keyboardButton.textContent = isOverKeyboard ? '🥛 Back to the Glass' : '⌨️ Over the Keyboard';
		wetness = 1;
		desk.say(isOverKeyboard ? 'The bird is over Pappa’s keyboard now, on a stack of binders. It answers Y to every question, like Homer Simpson did. What could go wrong?' : 'The bird is back at its glass of water. Pappa checks his e-mail. All of it is gone.');
		draw();
		loop.start();
	});

	draw();
};

// The Zen garden: a box of sand, raked with four tines. The rake smooths the old lines under it before it draws its own, like in real sand.
const setupSand = (desk, canvas, sound) => {
	const context = canvas.getContext('2d');
	const frame = 18;
	const tines = [-13.5, -4.5, 4.5, 13.5];
	const sand = document.createElement('canvas');
	sand.width = width;
	sand.height = height;
	const sandContext = sand.getContext('2d');
	const grains = document.createElement('canvas');
	grains.width = 96;
	grains.height = 96;
	const grainsContext = grains.getContext('2d');
	grainsContext.fillStyle = '#e8dcbc';
	grainsContext.fillRect(0, 0, 96, 96);
	for (let grain = 0; grain < 900; grain++) {
		grainsContext.fillStyle = hash(grain) > 0.5 ? '#d6c69e' : '#f6eed6';
		grainsContext.fillRect(Math.floor(hash(grain + 0.3) * 96), Math.floor(hash(grain + 0.7) * 96), 1, 1);
	}

	const pattern = sandContext.createPattern(grains, 'repeat');
	const stones = [
		{x: 330, y: 120, radius: 30, seed: 1},
		{x: 140, y: 236, radius: 22, seed: 2},
		{x: 372, y: 262, radius: 15, seed: 3},
	];
	const rake = {x: 240, y: 180, angle: 0, isVisible: false};
	let stroke;
	let hasRaked = false;
	let stoneDrag;
	let circles;
	let smoothing;
	let raked = 0;

	const clipToSand = () => {
		sandContext.beginPath();
		sandContext.rect(frame, frame, width - (frame * 2), height - (frame * 2));
		sandContext.clip();
	};

	const rakeSegment = (from, to) => {
		const length = Math.hypot(to.x - from.x, to.y - from.y);
		if (length < 0.5) {
			return;
		}

		const normal = {x: -(to.y - from.y) / length, y: (to.x - from.x) / length};
		sandContext.save();
		clipToSand();
		sandContext.fillStyle = pattern;
		sandContext.beginPath();
		sandContext.moveTo(from.x + (normal.x * 19), from.y + (normal.y * 19));
		sandContext.lineTo(to.x + (normal.x * 19), to.y + (normal.y * 19));
		sandContext.lineTo(to.x - (normal.x * 19), to.y - (normal.y * 19));
		sandContext.lineTo(from.x - (normal.x * 19), from.y - (normal.y * 19));
		sandContext.closePath();
		sandContext.fill();
		sandContext.lineCap = 'round';
		// Each groove has a shadow on the side of the light, and a bright edge on the other side.
		for (const [shift, color, lineWidth] of [[-0.9, 'rgba(120, 92, 52, 0.55)', 3.2], [1.6, 'rgba(255, 252, 240, 0.8)', 1.4]]) {
			sandContext.strokeStyle = color;
			sandContext.lineWidth = lineWidth;
			sandContext.beginPath();
			for (const offset of tines) {
				sandContext.moveTo(from.x + (normal.x * offset) + shift, from.y + (normal.y * offset) + shift);
				sandContext.lineTo(to.x + (normal.x * offset) + shift, to.y + (normal.y * offset) + shift);
			}

			sandContext.stroke();
		}

		sandContext.restore();
		raked += length;
		if (raked > 16) {
			raked = 0;
			sound.burst(0.06, {volume: 0.07, frequency: 2600, type: 'bandpass', quality: 0.7});
		}
	};

	const smoothArea = (x, y, areaWidth, areaHeight) => {
		sandContext.save();
		clipToSand();
		sandContext.fillStyle = pattern;
		sandContext.fillRect(x, y, areaWidth, areaHeight);
		sandContext.restore();
	};

	// The sand around a stone that was just put down is pressed smooth.
	const smoothAround = stone => {
		sandContext.save();
		clipToSand();
		sandContext.fillStyle = pattern;
		sandContext.beginPath();
		sandContext.arc(stone.x, stone.y, stone.radius + 6, 0, turn);
		sandContext.fill();
		sandContext.restore();
	};

	const rakeLines = () => {
		for (let y = frame + 22; y < height - frame - 10; y += 38) {
			rakeSegment({x: frame, y}, {x: width - frame, y});
		}
	};

	const circlePoint = (stone, angle) => {
		const distance = stone.radius + 24;
		return {x: stone.x + (Math.cos(angle) * distance), y: stone.y + (Math.sin(angle) * distance)};
	};

	const stoneShape = (stone, scale = 1) => {
		context.beginPath();
		for (let point = 0; point <= 14; point++) {
			const angle = point / 14 * turn;
			const distance = stone.radius * scale * (0.86 + (0.2 * hash((stone.seed * 31) + (point % 14))));
			const x = stone.x + (Math.cos(angle) * distance);
			const y = stone.y + (Math.sin(angle) * distance * 0.82);
			if (point === 0) {
				context.moveTo(x, y);
			} else {
				context.lineTo(x, y);
			}
		}

		context.closePath();
	};

	const drawStone = stone => {
		context.save();
		context.translate(5, 6);
		context.fillStyle = 'rgba(70, 50, 20, 0.35)';
		stoneShape(stone);
		context.fill();
		context.restore();
		const shade = context.createRadialGradient(stone.x - (stone.radius * 0.4), stone.y - (stone.radius * 0.4), 2, stone.x, stone.y, stone.radius * 1.1);
		const tone = 90 + Math.round(hash(stone.seed * 7) * 40);
		shade.addColorStop(0, `rgb(${tone + 70}, ${tone + 68}, ${tone + 62})`);
		shade.addColorStop(1, `rgb(${tone - 40}, ${tone - 42}, ${tone - 46})`);
		context.fillStyle = shade;
		stoneShape(stone);
		context.fill();
		// A bit of moss, because it rains in Bergen, also inside.
		context.fillStyle = 'rgba(80, 120, 50, 0.45)';
		context.beginPath();
		context.ellipse(stone.x + (stone.radius * 0.2), stone.y + (stone.radius * 0.35), stone.radius * 0.35, stone.radius * 0.15, 0.3, 0, turn);
		context.fill();
	};

	const drawRake = () => {
		context.save();
		context.translate(rake.x, rake.y);
		context.rotate(rake.angle);
		// The handle points back, the way the rake came from.
		context.strokeStyle = '#8a5a2a';
		context.lineWidth = 5;
		context.lineCap = 'round';
		context.beginPath();
		context.moveTo(-6, 0);
		context.lineTo(-70, 0);
		context.stroke();
		context.fillStyle = '#a06a34';
		context.fillRect(-8, -21, 7, 42);
		context.fillStyle = '#6a4420';
		for (const offset of tines) {
			context.fillRect(-1, offset - 1.5, 6, 3);
		}

		context.restore();
	};

	const draw = () => {
		// The black lacquered box around the sand.
		context.fillStyle = '#1a1210';
		context.fillRect(0, 0, width, height);
		context.fillStyle = '#3a2418';
		context.fillRect(4, 4, width - 8, height - 8);
		context.drawImage(sand, 0, 0);
		context.strokeStyle = '#00000066';
		context.lineWidth = 4;
		context.strokeRect(frame - 2, frame - 2, width - (frame * 2) + 4, height - (frame * 2) + 4);
		for (const stone of stones) {
			drawStone(stone);
		}

		if (smoothing) {
			context.fillStyle = '#a06a34';
			context.fillRect(smoothing.x - 4, frame, 8, height - (frame * 2));
		}

		if (rake.isVisible) {
			drawRake();
		}
	};

	const update = delta => {
		if (circles) {
			const previous = circles.angle;
			circles.angle = Math.min(turn + 0.15, circles.angle + (delta * turn / 1.4));
			for (const stone of stones) {
				for (let angle = previous; angle < circles.angle; angle += 0.05) {
					rakeSegment(circlePoint(stone, angle), circlePoint(stone, Math.min(angle + 0.05, circles.angle)));
				}
			}

			const last = circlePoint(stones.at(-1), circles.angle);
			rake.x = last.x;
			rake.y = last.y;
			rake.angle = circles.angle + (Math.PI / 2);
			if (circles.angle >= turn + 0.15) {
				circles = undefined;
				rake.isVisible = false;
			}
		}

		if (smoothing) {
			const next = Math.min(width - frame, smoothing.x + (delta * 600));
			smoothArea(smoothing.x - 6, frame, next - smoothing.x + 12, height - (frame * 2));
			smoothing.x = next;
			if (next >= width - frame) {
				smoothing = undefined;
			}
		}
	};

	const loop = toyLoop(desk, canvas, delta => {
		update(delta);
		draw();
	}, () => circles !== undefined || smoothing !== undefined);

	const stoneAt = point => stones.findLast(stone => Math.hypot(point.x - stone.x, point.y - stone.y) < stone.radius + 4);

	const inSand = point => ({x: clamp(point.x, frame + 4, width - frame - 4), y: clamp(point.y, frame + 4, height - frame - 4)});

	desk.on(canvas, 'pointerdown', event => {
		event.preventDefault();
		canvas.focus({preventScroll: true});
		canvas.setPointerCapture(event.pointerId);
		const point = inSand(canvasPoint(canvas, event));
		const stone = stoneAt(point);
		if (stone) {
			stoneDrag = {stone, x: point.x - stone.x, y: point.y - stone.y};
			// The stone that is picked up goes on top of the others.
			stones.splice(stones.indexOf(stone), 1);
			stones.push(stone);
		} else {
			stroke = point;
			hasRaked = false;
			rake.x = point.x;
			rake.y = point.y;
			rake.isVisible = true;
		}

		draw();
	});

	desk.on(canvas, 'pointermove', event => {
		const point = inSand(canvasPoint(canvas, event));
		if (stoneDrag) {
			stoneDrag.stone.x = clamp(point.x - stoneDrag.x, frame + stoneDrag.stone.radius, width - frame - stoneDrag.stone.radius);
			stoneDrag.stone.y = clamp(point.y - stoneDrag.y, frame + stoneDrag.stone.radius, height - frame - stoneDrag.stone.radius);
		} else if (stroke) {
			if (Math.hypot(point.x - stroke.x, point.y - stroke.y) < 2) {
				return;
			}

			rake.angle = Math.atan2(point.y - stroke.y, point.x - stroke.x);
			rakeSegment(stroke, point);
			hasRaked = true;
			stroke = point;
			rake.x = point.x;
			rake.y = point.y;
		} else {
			return;
		}

		draw();
	});

	const letGo = () => {
		if (stoneDrag) {
			smoothAround(stoneDrag.stone);
			sound.thud();
			stoneDrag = undefined;
		}

		if (stroke) {
			stroke = undefined;
			rake.isVisible = false;
			if (!hasRaked) {
				desk.say('Hold and drag to rake lines in the sand. Drag a stone to move it.');
			}
		}

		draw();
	};

	desk.on(canvas, 'pointerup', letGo);
	desk.on(canvas, 'pointercancel', letGo);

	const addStone = () => {
		if (stones.length >= 7) {
			desk.say('The garden is full of stones. Pappa says that in Zen, less is more. Then he buys more stones.');
			return;
		}

		const radius = 12 + Math.round(Math.random() * 16);
		let best;
		for (let attempt = 0; attempt < 30; attempt++) {
			const candidate = {x: frame + radius + (Math.random() * (width - (frame * 2) - (radius * 2))), y: frame + radius + (Math.random() * (height - (frame * 2) - (radius * 2)))};
			const room = Math.min(...stones.map(stone => Math.hypot(stone.x - candidate.x, stone.y - candidate.y) - stone.radius));
			if (!best || room > best.room) {
				best = {...candidate, room};
			}
		}

		const stone = {x: best.x, y: best.y, radius, seed: Math.random() * 1000};
		stones.push(stone);
		smoothAround(stone);
		sound.thud();
		desk.say(['A stone from the beach at Nordnes.', 'A stone from the garden of Mormor.', 'A stone that Rocky approves of.', 'A stone that looks a bit like Trond.'][stones.length % 4]);
		draw();
	};

	const rakeCircles = () => {
		desk.say('The rake goes around each stone. Ripples in the sand, like the sea around the islands outside Bergen.');
		if (desk.reducedMotion) {
			for (const stone of stones) {
				for (let angle = 0; angle < turn + 0.1; angle += 0.05) {
					rakeSegment(circlePoint(stone, angle), circlePoint(stone, angle + 0.05));
				}
			}

			draw();
			return;
		}

		circles = {angle: 0};
		rake.isVisible = true;
		loop.start();
	};

	const smooth = () => {
		desk.say('Swish. The sand is smooth again. The mind of Pappa too, for a minute.');
		sound.burst(0.7, {volume: 0.12, frequency: 1800, type: 'bandpass', quality: 0.5});
		circles = undefined;
		rake.isVisible = false;
		if (desk.reducedMotion) {
			smoothArea(0, 0, width, height);
			draw();
			return;
		}

		smoothing = {x: frame};
		loop.start();
	};

	onKeys(desk, canvas, event => {
		const moves = {ArrowLeft: [-10, 0], ArrowRight: [10, 0], ArrowUp: [0, -10], ArrowDown: [0, 10]};
		if (!moves[event.key]) {
			return false;
		}

		const [x, y] = moves[event.key];
		const from = {x: rake.x, y: rake.y};
		const to = inSand({x: rake.x + x, y: rake.y + y});
		rake.angle = Math.atan2(y, x);
		rakeSegment(from, to);
		rake.x = to.x;
		rake.y = to.y;
		rake.isVisible = true;
		draw();
	});

	desk.on(canvas, 'blur', () => {
		if (!stroke && !circles) {
			rake.isVisible = false;
			draw();
		}
	});

	onButton(desk, 'sand-stone', addStone);
	onButton(desk, 'sand-circles', rakeCircles);
	onButton(desk, 'sand-smooth', smooth);

	smoothArea(0, 0, width, height);
	rakeLines();
	for (const stone of stones) {
		smoothAround(stone);
		for (let angle = 0; angle < turn + 0.1; angle += 0.05) {
			rakeSegment(circlePoint(stone, angle), circlePoint(stone, angle + 0.05));
		}
	}

	draw();
};

// The magnet sculpture: paper clips stick to the magnet and to each other, and they point out along the field, which makes the spikes. A chain that is too long is too far from the magnet, and the clip falls off.
const setupMagnet = (desk, canvas, sound) => {
	const context = canvas.getContext('2d');
	const magnet = {x: 240, top: 262, radius: 64};
	const field = {x: 240, y: 286};
	const table = 340;
	const clipLength = 34;
	const maximumDepth = 6;
	const colors = ['#c8ccd2', '#c8ccd2', '#c8ccd2', '#c8ccd2', '#e03030', '#3060d0', '#20a040', '#f0c020', '#e060c0'];
	const clips = Array.from({length: 36}, (_, index) => ({
		x: 30 + (Math.random() * 420),
		y: table - 3,
		angle: Math.random() * Math.PI,
		parent: undefined,
		depth: 0,
		vx: 0,
		vy: 0,
		color: colors[index % colors.length],
		target: undefined,
	}));
	let drag;
	let shake = 0;
	let lastClink = 0;

	// The end of a clip where the next one sticks, where the clip will be when it is still on its way there.
	const outerEnd = clip => {
		const {x, y, angle} = clip.target ?? clip;
		return {x: x + (Math.cos(angle) * clipLength / 2), y: y + (Math.sin(angle) * clipLength / 2)};
	};

	const isLoose = clip => clip.parent === undefined;

	const place = (clip, x, y, angle) => {
		if (desk.reducedMotion) {
			clip.x = x;
			clip.y = y;
			clip.angle = angle;
			clip.target = undefined;
		} else {
			clip.target = {x, y, angle};
		}
	};

	// A clip on the magnet, or on the end of another clip, points away from the middle of the magnet, along the field.
	const attach = (clip, parentIndex, near = clip) => {
		let anchor;
		let depth;
		if (parentIndex === -1) {
			anchor = {x: clamp(near.x, magnet.x - magnet.radius + 8, magnet.x + magnet.radius - 8), y: magnet.top};
			depth = 1;
		} else {
			anchor = outerEnd(clips[parentIndex]);
			depth = clips[parentIndex].depth + 1;
		}

		const length = Math.hypot(anchor.x - field.x, anchor.y - field.y);
		let angle = Math.atan2((anchor.y - field.y) / length, (anchor.x - field.x) / length) + ((Math.random() - 0.5) * 0.9);
		// The clips spread out more, the farther they are from the magnet.
		if (parentIndex !== -1) {
			angle = ((clips[parentIndex].target ?? clips[parentIndex]).angle * 0.7) + (angle * 0.3) + ((Math.random() - 0.5) * 0.5);
		}

		// The spikes stand up a bit at least, as the clips are heavy too.
		angle = clamp(angle, -Math.PI + 0.3, -0.3);
		clip.parent = parentIndex;
		clip.depth = depth;
		clip.vx = 0;
		clip.vy = 0;
		place(clip, anchor.x + (Math.cos(angle) * ((clipLength / 2) + 1)), anchor.y + (Math.sin(angle) * ((clipLength / 2) + 1)), angle);
	};

	const detach = clipIndex => {
		const clip = clips[clipIndex];
		clip.parent = undefined;
		clip.depth = 0;
		clip.target = undefined;
		clip.vx = (Math.random() - 0.5) * 120;
		clip.vy = -40;
		for (const [index, other] of clips.entries()) {
			if (other.parent === clipIndex) {
				detach(index);
			}
		}
	};

	const clink = () => {
		const now = performance.now();
		if (now - lastClink > 40) {
			lastClink = now;
			sound.tone(3200 + (Math.random() * 1500), 0.05, {type: 'sine', volume: 0.05});
		}
	};

	// A clip sticks with a clink, however it gets there, and the last clip on the magnet finishes the sculpture. It says whether it was the last one.
	const stick = (clip, parentIndex, near) => {
		attach(clip, parentIndex, near);
		clink();
		if (clips.some(other => isLoose(other))) {
			return false;
		}

		desk.say('All 36 paper clips are on the magnet! Pappa calls it “Modern Art, 1999”.');
		desk.celebrate();
		return true;
	};

	// A dropped clip sticks to the nearest end of a clip, or to the magnet. Too far out, and it falls.
	const drop = clipIndex => {
		const clip = clips[clipIndex];
		let best;
		const end = outerEnd(clip);
		for (const point of [clip, end]) {
			if (Math.abs(point.x - magnet.x) < magnet.radius + 6 && point.y > magnet.top - 26 && point.y < magnet.top + 16) {
				const distance = Math.abs(point.y - magnet.top);
				if (!best || distance < best.distance) {
					best = {parent: -1, distance};
				}
			}

			for (const [index, other] of clips.entries()) {
				if (index === clipIndex || isLoose(other)) {
					continue;
				}

				const otherEnd = outerEnd(other);
				const distance = Math.hypot(point.x - otherEnd.x, point.y - otherEnd.y);
				if (distance < 26 && (!best || distance < best.distance)) {
					best = {parent: index, distance};
				}
			}
		}

		if (!best) {
			desk.say('The paper clip falls on the desk. Put it on the magnet, or on another clip.');
			return;
		}

		if (best.parent !== -1 && clips[best.parent].depth >= maximumDepth) {
			desk.say('Too far from the magnet! The pull is too weak out there, and the clip falls off.');
			return;
		}

		if (!stick(clip, best.parent) && best.parent !== -1 && clips[best.parent].depth === maximumDepth - 1) {
			desk.say('Six clips in a chain! That is as far as the magnet reaches.');
		}
	};

	const throwOne = () => {
		const index = clips.findIndex(clip => isLoose(clip) && clip !== drag?.clip);
		if (index === -1) {
			desk.say('All the paper clips are on the magnet already.');
			return;
		}

		// A spike that reaches out of the picture gets no more clips, and after a few tries, the clip goes on the magnet itself.
		const parents = clips.map((other, otherIndex) => otherIndex).filter(otherIndex => !isLoose(clips[otherIndex]) && clips[otherIndex].depth < 4);
		const isOnSpike = parents.length > 0 && Math.random() < 0.75;
		let parent = -1;
		for (let attempt = 0; isOnSpike && attempt < 12; attempt++) {
			const candidate = parents[Math.floor(Math.random() * parents.length)];
			const end = outerEnd(clips[candidate]);
			if (end.y > 30 && end.x > 20 && end.x < width - 20) {
				parent = candidate;
				break;
			}
		}

		if (!stick(clips[index], parent, {x: magnet.x + ((Math.random() - 0.5) * magnet.radius * 1.6)})) {
			desk.say('Clink! A paper clip flies onto the sculpture.');
		}

		loop.start();
	};

	const pullOff = () => {
		for (const clip of clips) {
			if (!isLoose(clip)) {
				clip.parent = undefined;
				clip.depth = 0;
				clip.vx = 0;
				// The clips go to the sides of the desk, not back on the magnet.
				const side = Math.random() < 0.5 ? 30 + (Math.random() * 130) : 320 + (Math.random() * 130);
				place(clip, side, table - 3, Math.random() * Math.PI);
			}
		}

		sound.burst(0.3, {volume: 0.15, frequency: 4000, type: 'highpass'});
		desk.say('You pull all the paper clips off. It takes some force. Magnets are strong!');
		loop.start();
	};

	const shakeDesk = () => {
		let fallen = 0;
		for (const [index, clip] of clips.entries()) {
			if (!isLoose(clip) && clip.depth >= 3 && Math.random() < (clip.depth - 2) / 4) {
				detach(index);
				fallen++;
			} else if (isLoose(clip) && !clip.target) {
				clip.vy = -150 - (Math.random() * 200);
				clip.vx = (Math.random() - 0.5) * 100;
			}
		}

		shake = desk.reducedMotion ? 0 : 0.5;
		sound.thud();
		desk.say(fallen > 0 ? `You bump the desk, and ${fallen} paper clips fall off the end of the spikes.` : 'You bump the desk, but the sculpture holds on.');
		if (desk.reducedMotion) {
			settle();
		}

		draw();
		loop.start();
	};

	// With reduced motion, a falling clip is on the desk at once.
	const settle = () => {
		for (const clip of clips) {
			if (isLoose(clip) && clip !== drag?.clip) {
				clip.target = undefined;
				clip.y = table - 3;
				clip.x = clamp(Math.abs(clip.x - magnet.x) < magnet.radius + 10 ? magnet.x + (Math.sign(clip.x - magnet.x || 1) * (magnet.radius + 20)) : clip.x, 10, width - 10);
				clip.vx = 0;
				clip.vy = 0;
				clip.angle = Math.round(clip.angle / Math.PI) * Math.PI;
			}
		}
	};

	const update = delta => {
		shake = Math.max(0, shake - delta);
		for (const clip of clips) {
			if (clip === drag?.clip) {
				continue;
			}

			if (clip.target) {
				const follow = 1 - Math.exp(-delta * 14);
				clip.x += (clip.target.x - clip.x) * follow;
				clip.y += (clip.target.y - clip.y) * follow;
				clip.angle += (clip.target.angle - clip.angle) * follow;
				if (Math.hypot(clip.target.x - clip.x, clip.target.y - clip.y) < 0.3) {
					clip.x = clip.target.x;
					clip.y = clip.target.y;
					clip.angle = clip.target.angle;
					clip.target = undefined;
				}

				continue;
			}

			if (!isLoose(clip)) {
				continue;
			}

			const wasAbove = clip.y < magnet.top;
			clip.vy += 1400 * delta;
			clip.x = clamp(clip.x + (clip.vx * delta), 8, width - 8);
			clip.y += clip.vy * delta;
			// A clip that falls onto the top of the magnet sticks to it.
			if (wasAbove && clip.y >= magnet.top - 4 && Math.abs(clip.x - magnet.x) < magnet.radius - 4) {
				stick(clip, -1);
				continue;
			}

			// A clip that hits the side of the magnet slides off it.
			if (clip.y > magnet.top && Math.abs(clip.x - magnet.x) < magnet.radius + 6) {
				clip.x = magnet.x + (Math.sign(clip.x - magnet.x || 1) * (magnet.radius + 6));
			}

			if (clip.y >= table - 3) {
				clip.y = table - 3;
				clip.vy = Math.abs(clip.vy) > 120 ? -clip.vy * 0.3 : 0;
				clip.vx *= 0.8;
				const flat = Math.round(clip.angle / Math.PI) * Math.PI;
				clip.angle += (flat - clip.angle) * 0.3;
			}
		}
	};

	const isBusy = () => !desk.reducedMotion && (shake > 0 || clips.some(clip => clip.target || (isLoose(clip) && clip !== drag?.clip && (clip.y < table - 3 || clip.vy !== 0 || Math.abs(clip.vx) > 1))));

	const drawClip = clip => {
		context.save();
		context.translate(clip.x, clip.y);
		context.rotate(clip.angle);
		const half = clipLength / 2;
		context.strokeStyle = '#00000055';
		context.lineWidth = 3;
		context.beginPath();
		context.roundRect(-half, -5.5, clipLength, 11, 5.5);
		context.stroke();
		context.strokeStyle = clip.color;
		context.lineWidth = 1.8;
		context.beginPath();
		context.roundRect(-half, -5.5, clipLength, 11, 5.5);
		context.stroke();
		context.beginPath();
		context.roundRect(-half + 5, -2.8, clipLength - 12, 5.6, 2.8);
		context.stroke();
		context.restore();
	};

	const draw = () => {
		context.save();
		if (shake > 0) {
			context.translate(Math.sin(shake * 60) * shake * 10, 0);
		}

		const wall = context.createLinearGradient(0, 0, 0, height);
		wall.addColorStop(0, '#4a5a6a');
		wall.addColorStop(1, '#2a3440');
		context.fillStyle = wall;
		context.fillRect(-20, 0, width + 40, height);
		drawDesk(context, 330);

		for (const clip of clips) {
			if (isLoose(clip) && clip.y >= magnet.top && clip !== drag?.clip) {
				drawClip(clip);
			}
		}

		// The magnet: a black block with a chrome top.
		context.fillStyle = '#151515';
		context.fillRect(magnet.x - magnet.radius, magnet.top, magnet.radius * 2, 330 - magnet.top);
		context.beginPath();
		context.ellipse(magnet.x, 330, magnet.radius, 10, 0, 0, Math.PI);
		context.fill();
		const top = context.createLinearGradient(magnet.x - magnet.radius, 0, magnet.x + magnet.radius, 0);
		top.addColorStop(0, '#6a6e74');
		top.addColorStop(0.4, '#e8ecf0');
		top.addColorStop(1, '#5a5e64');
		context.fillStyle = top;
		context.beginPath();
		context.ellipse(magnet.x, magnet.top, magnet.radius, 12, 0, 0, turn);
		context.fill();
		context.fillStyle = '#d8b040';
		context.font = 'bold 10px "Times New Roman", serif';
		context.textAlign = 'center';
		context.fillText('MAGNETIC', magnet.x, magnet.top + 34);
		context.fillText('SCULPTURE', magnet.x, magnet.top + 47);

		for (const clip of clips) {
			if ((!isLoose(clip) || clip.y < magnet.top) && clip !== drag?.clip) {
				drawClip(clip);
			}
		}

		if (drag) {
			drawClip(drag.clip);
		}

		context.restore();
	};

	const loop = toyLoop(desk, canvas, delta => {
		update(delta);
		draw();
	}, isBusy);

	desk.on(canvas, 'pointerdown', event => {
		event.preventDefault();
		canvas.focus({preventScroll: true});
		const point = canvasPoint(canvas, event);
		let nearest = -1;
		let nearestDistance = 20;
		for (const [index, clip] of clips.entries()) {
			const distance = Math.hypot(point.x - clip.x, point.y - clip.y);
			if (distance <= nearestDistance) {
				nearest = index;
				nearestDistance = distance;
			}
		}

		// A click that misses the paper clips throws one on, so the first click always does something.
		if (nearest === -1) {
			throwOne();
			draw();
			return;
		}

		canvas.setPointerCapture(event.pointerId);
		const clip = clips[nearest];
		const wasAttached = !isLoose(clip);
		detach(nearest);
		clip.vx = 0;
		clip.vy = 0;
		if (wasAttached) {
			sound.tone(1800, 0.04, {type: 'sine', volume: 0.04});
		}

		drag = {clip, index: nearest, x: point.x - clip.x, y: point.y - clip.y};
		if (desk.reducedMotion) {
			settle();
		}

		draw();
		loop.start();
	});

	desk.on(canvas, 'pointermove', event => {
		if (!drag) {
			return;
		}

		const point = canvasPoint(canvas, event);
		drag.clip.x = clamp(point.x - drag.x, 8, width - 8);
		drag.clip.y = clamp(point.y - drag.y, 8, table - 3);
		draw();
	});

	const letGo = () => {
		if (!drag) {
			return;
		}

		const {index} = drag;
		drag = undefined;
		drop(index);
		if (desk.reducedMotion) {
			settle();
		}

		draw();
		loop.start();
	};

	desk.on(canvas, 'pointerup', letGo);
	desk.on(canvas, 'pointercancel', letGo);

	onKeys(desk, canvas, event => {
		if (event.key === ' ' || event.key === 'Enter') {
			throwOne();
			draw();
		} else {
			return false;
		}
	});

	onButton(desk, 'magnet-throw', () => {
		throwOne();
		draw();
	});
	onButton(desk, 'magnet-off', () => {
		pullOff();
		draw();
	});
	onButton(desk, 'magnet-shake', shakeDesk);

	// Pappa’s sculpture, as he left it, with some clips on the desk.
	for (let index = 0; index < 24; index++) {
		const clip = clips[index];
		const parents = clips.slice(0, index).map((other, otherIndex) => otherIndex).filter(otherIndex => clips[otherIndex].depth < 4);
		const parent = parents.length > 0 && index % 3 !== 0 ? parents[Math.floor(Math.random() * parents.length)] : -1;
		attach(clip, parent, {x: magnet.x + ((Math.random() - 0.5) * magnet.radius * 1.9), y: magnet.top});
		if (clip.target) {
			clip.x = clip.target.x;
			clip.y = clip.target.y;
			clip.angle = clip.target.angle;
			clip.target = undefined;
		}
	}

	for (const clip of clips) {
		if (isLoose(clip) && Math.abs(clip.x - magnet.x) < magnet.radius + 10) {
			clip.x = clip.x < magnet.x ? magnet.x - magnet.radius - 20 - (Math.random() * 100) : magnet.x + magnet.radius + 20 + (Math.random() * 100);
		}
	}

	draw();
};

// Pappa’s stress ball: a yellow foam ball with a face, which squashes while it is held, more the longer it is held, and wobbles back.
const setupStress = (desk, canvas, sound) => {
	const context = canvas.getContext('2d');
	const radius = 92;
	const floor = 300;
	const milestones = new Map([
		[1, 'Squish! Hold it down longer to squeeze harder.'],
		[10, 'Ten squeezes. Pappa’s stress is down to the level of a normal Monday.'],
		[25, 'Twenty-five squeezes! Pappa can now look at the Y2K plan without crying.'],
		[50, 'Fifty squeezes. Pappa is so calm that he answers the phone with “Namaste”.'],
		[100, 'A hundred squeezes! Pappa is totally zen. He goes to lunch early.'],
	]);
	let squeeze = 0;
	let squeezeSpeed = 0;
	let isHeld = false;
	let holdTime = 0;
	let hardTime = 0;
	let poppedTime = 0;
	let wasSqueezed = false;
	let pressTime = 0;
	let releaseTimer;
	let squeezes = loadCount(desk, 'squeezes');
	let session = 0;

	const target = () => (isHeld ? Math.min(1, 0.55 + (holdTime * 0.35)) : 0);

	const count = () => {
		squeezes++;
		session++;
		desk.store('squeezes', squeezes);
		sound.tone(700, 0.18, {type: 'sine', volume: 0.12, slide: 1100});
		sound.tone(1400, 0.12, {type: 'triangle', volume: 0.03, slide: 2000});
		if (milestones.has(session)) {
			desk.say(milestones.get(session));
			if (session === 100) {
				desk.celebrate();
			}
		}
	};

	const update = delta => {
		if (isHeld) {
			holdTime += delta;
		}

		if (desk.reducedMotion) {
			// With reduced motion, a press is a full squeeze at once, as there is no spring to push it further.
			squeeze = isHeld ? Math.min(1, target() + 0.15) : 0;
			squeezeSpeed = 0;
		} else {
			// A spring that is a bit loose, so the ball wobbles when it is let go.
			squeezeSpeed += ((180 * (target() - squeeze)) - (8 * squeezeSpeed)) * delta;
			squeeze = clamp(squeeze + (squeezeSpeed * delta), -0.25, 1.05);
		}

		if (squeeze > 0.6 && !wasSqueezed) {
			wasSqueezed = true;
			count();
		} else if (squeeze < 0.25) {
			wasSqueezed = false;
		}

		// Held at the most for a while, the eyes pop out on springs.
		hardTime = squeeze > 0.95 ? hardTime + delta : 0;
		if (hardTime > 1.5 && poppedTime === 0) {
			poppedTime = 3;
			sound.tone(200, 0.4, {type: 'sine', volume: 0.15, slide: 900});
			desk.say('“Au! Ikke så hardt!” (Ouch! Not so hard!) The eyes of the ball pop out.');
		}

		if (!isHeld && poppedTime > 0) {
			poppedTime = Math.max(0, poppedTime - delta);
		}
	};

	const draw = () => {
		const wall = context.createLinearGradient(0, 0, 0, height);
		wall.addColorStop(0, '#c8d4c0');
		wall.addColorStop(1, '#98a690');
		context.fillStyle = wall;
		context.fillRect(0, 0, width, height);
		drawDesk(context, floor);

		const stretch = 1 + (0.32 * squeeze);
		const flatten = 1 - (0.4 * squeeze);
		const radiusX = radius * stretch;
		const radiusY = radius * flatten;
		const centerX = 240;
		const centerY = floor - radiusY;

		context.fillStyle = 'rgba(0, 0, 0, 0.3)';
		context.beginPath();
		context.ellipse(centerX, floor + 2, radiusX * 0.9, 8, 0, 0, turn);
		context.fill();

		const foam = context.createRadialGradient(centerX - (radiusX * 0.35), centerY - (radiusY * 0.4), 8, centerX, centerY, Math.max(radiusX, radiusY));
		foam.addColorStop(0, '#fff7a0');
		foam.addColorStop(0.6, '#ffd800');
		foam.addColorStop(1, '#d09000');
		context.fillStyle = foam;
		context.beginPath();
		context.ellipse(centerX, centerY, radiusX, radiusY, 0, 0, turn);
		context.fill();

		// The face and the text squash with the ball.
		context.save();
		context.translate(centerX, centerY);
		context.scale(stretch, flatten);
		const isPopped = poppedTime > 0;
		const eyeSize = 11 + (squeeze * 9);
		for (const side of [-1, 1]) {
			let eyeX = side * 30;
			let eyeY = -24;
			if (isPopped) {
				context.strokeStyle = '#444444';
				context.lineWidth = 2;
				context.beginPath();
				for (let coil = 0; coil <= 8; coil++) {
					const x = side * (30 + (coil * 4));
					const y = -24 - (coil * 7);
					context.lineTo(x + ((coil % 2) * 6) - 3, y);
				}

				context.stroke();
				eyeX = side * 62;
				eyeY = -80;
			}

			context.fillStyle = '#ffffff';
			context.beginPath();
			context.arc(eyeX, eyeY, eyeSize, 0, turn);
			context.fill();
			context.strokeStyle = '#000000';
			context.lineWidth = 2;
			context.stroke();
			context.fillStyle = '#000000';
			context.beginPath();
			context.arc(eyeX + (side * squeeze * 3), eyeY + 2, 4 + (squeeze * 2), 0, turn);
			context.fill();
		}

		context.strokeStyle = '#000000';
		context.lineWidth = 4;
		context.lineCap = 'round';
		context.beginPath();
		if (squeeze < 0.35) {
			context.arc(0, 4, 40, Math.PI * 0.2, Math.PI * 0.8);
			context.stroke();
		} else {
			context.fillStyle = '#7a1010';
			context.ellipse(0, 20, 12 + (squeeze * 10), 8 + (squeeze * 12), 0, 0, turn);
			context.fill();
			context.stroke();
		}

		context.fillStyle = '#b01010';
		context.font = 'bold 13px Arial, sans-serif';
		context.textAlign = 'center';
		context.fillText('Y2K? NO PROBLEM!', 0, 62);
		context.restore();

		// Pappa’s hand, which comes down to squeeze.
		const handY = isHeld || squeeze > 0.05 ? floor - (radiusY * 2) - 2 : floor - (radius * 2) - 40;
		context.fillStyle = '#e8b890';
		context.strokeStyle = '#a87050';
		context.lineWidth = 2;
		for (let finger = 0; finger < 4; finger++) {
			const x = 168 + (finger * 38);
			const lengthOfFinger = finger === 0 || finger === 3 ? 64 : 76;
			context.beginPath();
			context.roundRect(x, handY - lengthOfFinger, 32, lengthOfFinger, [0, 0, 16, 16]);
			context.fill();
			context.stroke();
		}

		// The back of the hand, and the sleeve of Pappa’s suit.
		context.fillStyle = '#e8b890';
		context.beginPath();
		context.roundRect(164, handY - 120, 152, 60, 20);
		context.fill();
		context.stroke();
		context.fillStyle = '#3a4a6a';
		context.fillRect(186, 0, 108, Math.max(0, handY - 112));
		context.fillStyle = '#ffffff';
		context.fillRect(186, Math.max(0, handY - 122), 108, 10);

		context.fillStyle = '#222222';
		context.font = 'bold 14px "Comic Sans MS", "Comic Sans", cursive';
		context.textAlign = 'left';
		context.fillText(`Squeezes: ${squeezes}`, 14, 26);
		const stress = Math.max(1, 99 - session);
		context.fillText('Pappa’s stress:', 14, 48);
		context.fillStyle = '#ffffff';
		context.fillRect(14, 54, 104, 14);
		context.fillStyle = stress > 60 ? '#d02020' : (stress > 25 ? '#e0a020' : '#20a040');
		context.fillRect(16, 56, stress, 10);
		context.fillStyle = '#222222';
		context.fillText(`${stress}%`, 124, 66);
	};

	const loop = toyLoop(desk, canvas, delta => {
		update(delta);
		draw();
	}, () => !desk.reducedMotion && (isHeld || Math.abs(squeeze) > 0.002 || Math.abs(squeezeSpeed) > 0.01 || poppedTime > 0));

	const press = () => {
		clearTimeout(releaseTimer);
		if (isHeld) {
			return;
		}

		isHeld = true;
		holdTime = 0;
		pressTime = performance.now();
		if (desk.reducedMotion) {
			update(0);
			draw();
		}

		loop.start();
	};

	const release = () => {
		if (!isHeld) {
			return;
		}

		isHeld = false;
		sound.tone(240, 0.12, {type: 'sine', volume: 0.1, slide: 140});
		if (desk.reducedMotion) {
			poppedTime = 0;
			update(0);
			draw();
		}

		loop.start();
	};

	// A quick click, which is what a first visitor tries, still squeezes the ball all the way, as the foam takes a moment to squash.
	const letGo = () => {
		clearTimeout(releaseTimer);
		releaseTimer = setTimeout(release, Math.max(0, 300 - (performance.now() - pressTime)));
	};

	desk.on(canvas, 'pointerdown', event => {
		event.preventDefault();
		canvas.focus({preventScroll: true});
		canvas.setPointerCapture(event.pointerId);
		press();
	});
	desk.on(canvas, 'pointerup', letGo);
	desk.on(canvas, 'pointercancel', letGo);

	desk.on(canvas, 'keydown', event => {
		if (event.key === ' ' || event.key === 'Enter') {
			event.preventDefault();
			if (!event.repeat) {
				press();
			} else if (desk.reducedMotion) {
				// With reduced motion, holding the key squeezes harder, one step for each repeat.
				holdTime += 0.15;
				update(0);
				draw();
			}
		}
	});
	desk.on(canvas, 'keyup', event => {
		if (event.key === ' ' || event.key === 'Enter') {
			letGo();
		}
	});
	desk.on(canvas, 'blur', release);

	const squeezeButton = deskButton(desk, 'stress-squeeze');
	desk.on(squeezeButton, 'pointerdown', press);
	desk.on(squeezeButton, 'pointerup', letGo);
	desk.on(squeezeButton, 'pointerleave', letGo);
	desk.on(squeezeButton, 'click', event => {
		// A click from the keyboard has no press and release of its own, so it is a quick squeeze.
		if (!isHeld && event.detail === 0) {
			press();
			letGo();
		}
	});

	draw();
};

// The Executive Decision Maker: a wheel of answers, with pegs that tick against the flapper at the top.
const setupSpinner = (desk, canvas, sound) => {
	const context = canvas.getContext('2d');
	const answers = [
		{lines: ['YES'], color: '#c82020', text: '#ffffff', message: 'Yes! Pappa signs the papers with his best pen.'},
		{lines: ['NO'], color: '#1d4fc0', text: '#ffffff', message: 'No. Pappa tells his boss that the computer says no.'},
		{lines: ['ASK YOUR', 'MOTHER'], color: '#f2c230', text: '#222222', message: 'Ask your mother. Pappa calls Mamma, but the line is busy, because I am on the Internet.'},
		{lines: ['LUNCH'], color: '#20904a', text: '#ffffff', message: 'Lunch! Pappa takes his matpakke with brown cheese out of the drawer. It is 10:15.'},
		{lines: ['HAVE A', 'MEETING'], color: '#c82020', text: '#ffffff', message: 'Have a meeting. About when to have the next meeting.'},
		{lines: ['FAX IT'], color: '#1d4fc0', text: '#ffffff', message: 'Fax it! The fax screams, and the paper curls up like a pølse.'},
		{lines: ['WAIT UNTIL', '2000'], color: '#f2c230', text: '#222222', message: 'Wait until 2000. If the computers still work then.'},
		{lines: ['GO HOME'], color: '#20904a', text: '#ffffff', message: 'Go home! Pappa looks at the clock, and then at his boss, and then at the wheel again.'},
	];
	const center = {x: 240, y: 196};
	const radius = 146;
	const segment = turn / answers.length;
	let rotation = -Math.PI / 2 - (segment / 2);
	let speed = 0;
	let flapper = 0;
	let flapperSpeed = 0;
	let lastPeg = Math.floor((rotation + (Math.PI / 2)) / segment);
	let drag;
	let spins = 0;

	const answerAt = () => {
		const angle = ((((-Math.PI / 2) - rotation) % turn) + turn) % turn;
		return answers[Math.floor(angle / segment) % answers.length];
	};

	const announce = () => {
		spins++;
		desk.say(`The Executive Decision Maker says: ${answerAt().message}`);
		sound.tone(1047, 0.1, {volume: 0.04});
		sound.tone(1568, 0.2, {volume: 0.04, when: 0.1});
	};

	const checkPegs = () => {
		const peg = Math.floor((rotation + (Math.PI / 2)) / segment);
		if (peg !== lastPeg) {
			lastPeg = peg;
			if (!desk.reducedMotion) {
				flapperSpeed -= Math.sign(speed || 1) * 14;
			}

			sound.tick();
		}
	};

	const update = delta => {
		if (!drag && speed !== 0) {
			rotation += speed * delta;
			// The friction of the axle, and a bit more for each peg against the flapper.
			const slowing = (0.6 + (Math.abs(speed) * 0.25)) * delta;
			speed = Math.abs(speed) <= slowing ? 0 : speed - (Math.sign(speed) * slowing);
			checkPegs();
			if (speed === 0) {
				announce();
			}
		}

		flapperSpeed += ((-200 * flapper) - (14 * flapperSpeed)) * delta;
		flapper = clamp(flapper + (flapperSpeed * delta), -0.6, 0.6);
	};

	const draw = () => {
		const wall = context.createLinearGradient(0, 0, 0, height);
		wall.addColorStop(0, '#3a2a4a');
		wall.addColorStop(1, '#1a1220');
		context.fillStyle = wall;
		context.fillRect(0, 0, width, height);
		drawDesk(context, 330);

		// The stand, behind the wheel.
		context.fillStyle = '#2a1a0c';
		context.beginPath();
		context.moveTo(center.x - 20, center.y);
		context.lineTo(center.x - 60, 340);
		context.lineTo(center.x + 60, 340);
		context.lineTo(center.x + 20, center.y);
		context.fill();

		context.fillStyle = 'rgba(0, 0, 0, 0.4)';
		context.beginPath();
		context.arc(center.x + 5, center.y + 7, radius + 6, 0, turn);
		context.fill();
		context.fillStyle = '#c8a040';
		context.beginPath();
		context.arc(center.x, center.y, radius + 6, 0, turn);
		context.fill();

		context.save();
		context.translate(center.x, center.y);
		context.rotate(rotation);
		for (const [index, answer] of answers.entries()) {
			context.fillStyle = answer.color;
			context.beginPath();
			context.moveTo(0, 0);
			context.arc(0, 0, radius, index * segment, (index + 1) * segment);
			context.closePath();
			context.fill();
			context.strokeStyle = '#ffffff';
			context.lineWidth = 2;
			context.stroke();
			context.save();
			context.rotate((index + 0.5) * segment);
			context.fillStyle = answer.text;
			context.font = 'bold 15px Arial, sans-serif';
			context.textAlign = 'right';
			context.textBaseline = 'middle';
			for (const [line, text] of answer.lines.entries()) {
				context.fillText(text, radius - 14, ((line - ((answer.lines.length - 1) / 2)) * 16));
			}

			context.restore();
		}

		// The brass pegs on the rim.
		for (let index = 0; index < answers.length; index++) {
			steelBall(context, Math.cos(index * segment) * (radius - 4), Math.sin(index * segment) * (radius - 4), 5, '#c8a040');
		}

		context.restore();

		// The brass hub.
		steelBall(context, center.x, center.y, 24, '#c8a040');
		context.fillStyle = '#3a2a06';
		context.font = 'bold 8px "Times New Roman", serif';
		context.textAlign = 'center';
		context.textBaseline = 'middle';
		context.fillText('EXEC', center.x, center.y - 4);
		context.fillText('1999', center.x, center.y + 6);
		context.textBaseline = 'alphabetic';

		// The red flapper at the top, which the pegs push to the side.
		context.save();
		context.translate(center.x, center.y - radius - 22);
		context.rotate(flapper);
		context.fillStyle = '#e02020';
		context.strokeStyle = '#600000';
		context.lineWidth = 2;
		context.beginPath();
		context.moveTo(-10, 0);
		context.lineTo(10, 0);
		context.lineTo(0, 34);
		context.closePath();
		context.fill();
		context.stroke();
		context.restore();
		steelBall(context, center.x, center.y - radius - 22, 6, '#c8a040');

		context.fillStyle = '#ffd860';
		context.font = 'bold 13px "Times New Roman", serif';
		context.textAlign = 'left';
		context.fillText(`Decisions: ${spins}`, 12, 24);
	};

	const loop = toyLoop(desk, canvas, delta => {
		update(delta);
		draw();
	}, () => drag !== undefined || (!desk.reducedMotion && (speed !== 0 || Math.abs(flapper) > 0.002 || Math.abs(flapperSpeed) > 0.01)));

	const spin = (startSpeed = 10 + (Math.random() * 9)) => {
		if (desk.reducedMotion) {
			const index = Math.floor(Math.random() * answers.length);
			rotation = (-Math.PI / 2) - ((index + 0.3 + (Math.random() * 0.4)) * segment);
			lastPeg = Math.floor((rotation + (Math.PI / 2)) / segment);
			sound.tick();
			announce();
			draw();
			return;
		}

		speed = startSpeed;
		desk.say('Tikk-tikk-tikk-tikk… The wheel spins. Pappa holds his breath.');
		loop.start();
	};

	const pointerAngle = event => {
		const point = canvasPoint(canvas, event);
		return Math.atan2(point.y - center.y, point.x - center.x);
	};

	desk.on(canvas, 'pointerdown', event => {
		event.preventDefault();
		canvas.focus({preventScroll: true});
		canvas.setPointerCapture(event.pointerId);
		speed = 0;
		drag = {angle: pointerAngle(event), samples: [{angle: rotation, time: performance.now()}], hasMoved: false};
		loop.start();
	});

	desk.on(canvas, 'pointermove', event => {
		if (!drag) {
			return;
		}

		const angle = pointerAngle(event);
		let change = angle - drag.angle;
		if (change > Math.PI) {
			change -= turn;
		} else if (change < -Math.PI) {
			change += turn;
		}

		drag.angle = angle;
		rotation += change;
		drag.hasMoved = drag.hasMoved || Math.abs(change) > 0.01;
		const now = performance.now();
		drag.samples.push({angle: rotation, time: now});
		while (drag.samples.length > 2 && now - drag.samples[0].time > 100) {
			drag.samples.shift();
		}

		checkPegs();
		if (desk.reducedMotion) {
			draw();
		}
	});

	const letGo = () => {
		if (!drag) {
			return;
		}

		const first = drag.samples[0];
		const last = drag.samples.at(-1);
		// A wheel that was held still before the release is not flicked.
		const flick = last.time > first.time && performance.now() - last.time < 100 ? (last.angle - first.angle) / ((last.time - first.time) / 1000) : 0;
		const {hasMoved} = drag;
		drag = undefined;
		if (!hasMoved) {
			spin();
		} else if (Math.abs(flick) > 3) {
			if (desk.reducedMotion) {
				spin();
			} else {
				speed = clamp(flick, -30, 30);
				desk.say('What a flick! The wheel spins.');
				loop.start();
			}
		} else {
			announce();
			draw();
		}
	};

	desk.on(canvas, 'pointerup', letGo);
	desk.on(canvas, 'pointercancel', letGo);

	onKeys(desk, canvas, event => {
		if (event.key === ' ' || event.key === 'Enter') {
			spin();
		} else {
			return false;
		}
	});

	onButton(desk, 'spinner-spin', () => {
		spin();
	});

	draw();
};

// The perpetual motion machine: an overbalanced wheel, with weights that swing out on one side, which turns forever. Behind it, there is a cable to the wall.
const setupPerpetual = (desk, canvas, sound) => {
	const context = canvas.getContext('2d');
	const plugButton = deskButton(desk, 'perpetual-plug');
	const hub = {x: 240, y: 150};
	const radius = 92;
	let rotation = 0;
	let speed = 0.9;
	let isPlugged = true;
	let isBehind = false;

	const update = delta => {
		const goal = isPlugged ? 0.9 : 0;
		speed += (goal - speed) * (1 - Math.exp(-delta * (isPlugged ? 1.5 : 0.8)));
		if (!isPlugged && speed < 0.01) {
			speed = 0;
		}

		rotation += speed * delta;
	};

	const drawWheel = () => {
		context.strokeStyle = '#c8a040';
		context.lineWidth = 5;
		context.beginPath();
		context.arc(hub.x, hub.y, radius, 0, turn);
		context.stroke();
		for (let arm = 0; arm < 8; arm++) {
			const angle = rotation + (arm * turn / 8);
			const rim = {x: hub.x + (Math.cos(angle) * radius), y: hub.y + (Math.sin(angle) * radius)};
			context.strokeStyle = '#b08a30';
			context.lineWidth = 3;
			context.beginPath();
			context.moveTo(hub.x, hub.y);
			context.lineTo(rim.x, rim.y);
			context.stroke();
			// The weights swing out on the right side, and fold in on the left, which looks like it should turn the wheel forever. It does not.
			const out = (Math.cos(angle) + 1) / 2;
			const swing = {x: (Math.cos(angle) * out) + (Math.sin(angle) * (1 - out)), y: (Math.sin(angle) * out) + ((1 - out) * 0.6)};
			const length = Math.hypot(swing.x, swing.y) || 1;
			const weight = {x: rim.x + (swing.x / length * 30), y: rim.y + (swing.y / length * 30)};
			context.strokeStyle = '#8a8e94';
			context.lineWidth = 2;
			context.beginPath();
			context.moveTo(rim.x, rim.y);
			context.lineTo(weight.x, weight.y);
			context.stroke();
			steelBall(context, weight.x, weight.y, 9);
		}

		steelBall(context, hub.x, hub.y, 12, '#c8a040');
	};

	const draw = () => {
		const wall = context.createLinearGradient(0, 0, 0, height);
		wall.addColorStop(0, '#e2dcc8');
		wall.addColorStop(1, '#b8b098');
		context.fillStyle = wall;
		context.fillRect(0, 0, width, height);

		if (isBehind) {
			// The wall outlet, round, like all of them in Norway, with the plug of the machine in it.
			context.fillStyle = '#f4f2ea';
			context.beginPath();
			context.roundRect(380, 180, 70, 70, 10);
			context.fill();
			context.strokeStyle = '#a8a490';
			context.lineWidth = 2;
			context.stroke();
			context.fillStyle = '#e0ddd0';
			context.beginPath();
			context.arc(415, 215, 24, 0, turn);
			context.fill();
			context.fillStyle = '#333333';
			context.beginPath();
			context.arc(407, 215, 3, 0, turn);
			context.arc(423, 215, 3, 0, turn);
			context.fill();
			context.font = 'bold 10px Arial, sans-serif';
			context.textAlign = 'center';
			context.fillText('230 V', 415, 262);
		}

		drawDesk(context, 300);

		// The cable, from the base to the wall.
		const plug = isPlugged ? {x: 415, y: 215} : {x: 440, y: 290};
		context.strokeStyle = '#1a1a1a';
		context.lineWidth = 4;
		context.beginPath();
		context.moveTo(300, 296);
		context.bezierCurveTo(340, 330, isBehind ? 380 : 470, 320, isBehind ? plug.x : 490, isBehind ? plug.y + 20 : 300);
		context.stroke();
		if (isBehind) {
			context.fillStyle = '#222222';
			context.beginPath();
			context.arc(plug.x, plug.y, 16, 0, turn);
			context.fill();
		}

		// The stand: two brass posts on a base of dark wood.
		context.strokeStyle = '#a07a28';
		context.lineWidth = 8;
		context.beginPath();
		context.moveTo(hub.x - 50, 270);
		context.lineTo(hub.x, hub.y);
		context.lineTo(hub.x + 50, 270);
		context.stroke();

		drawWheel();

		context.fillStyle = '#3a2212';
		context.beginPath();
		context.roundRect(110, 266, 260, 34, 6);
		context.fill();

		if (isBehind) {
			// The little electric motor under the base, with a rubber belt to the axle.
			context.fillStyle = '#4a5a6a';
			context.beginPath();
			context.roundRect(hub.x - 26, 226, 52, 34, 6);
			context.fill();
			context.fillStyle = '#ffffff';
			context.font = 'bold 9px Arial, sans-serif';
			context.textAlign = 'center';
			context.fillText('MOTOR', hub.x, 247);
			context.strokeStyle = '#111111';
			context.lineWidth = 2;
			context.beginPath();
			context.moveTo(hub.x - 6, hub.y);
			context.lineTo(hub.x - 10, 228);
			context.moveTo(hub.x + 6, hub.y);
			context.lineTo(hub.x + 10, 228);
			context.stroke();
		} else {
			// The brass plate on the front.
			const brass = context.createLinearGradient(0, 272, 0, 294);
			brass.addColorStop(0, '#f6e08a');
			brass.addColorStop(1, '#a67c1e');
			context.fillStyle = brass;
			context.fillRect(150, 272, 180, 22);
			context.fillStyle = '#3a2a06';
			context.font = 'bold 12px "Times New Roman", serif';
			context.textAlign = 'center';
			context.fillText(speed === 0 ? 'PERPETUAL MOTION*' : 'PERPETUAL MOTION', 240, 288);
			if (speed === 0) {
				context.fillStyle = '#222222';
				context.font = 'italic 11px "Times New Roman", serif';
				context.fillText('*while plugged in', 240, 320);
			}
		}

		context.fillStyle = '#222222';
		context.font = 'bold 13px "Comic Sans MS", "Comic Sans", cursive';
		context.textAlign = 'left';
		context.fillText(isBehind ? 'Behind it…' : (speed === 0 ? 'It stopped!' : 'It runs forever!'), 12, 24);
	};

	const loop = toyLoop(desk, canvas, delta => {
		update(delta);
		draw();
	}, () => !desk.reducedMotion && (isPlugged || speed !== 0));

	const next = () => {
		if (isPlugged && !isBehind) {
			isBehind = true;
			plugButton.textContent = '🔌 Unplug It';
			desk.say('Behind it, there is a little motor and a cable to the wall. Pappa says I did not see that.');
		} else if (isPlugged) {
			isPlugged = false;
			isBehind = false;
			plugButton.textContent = '🔌 Plug It Back In';
			sound.tick();
			desk.say('You unplug it. The perpetual motion machine slows down… and stops. Perpetual means until somebody unplugs it, Pappa says.');
			if (desk.reducedMotion) {
				speed = 0;
			}
		} else {
			isPlugged = true;
			plugButton.textContent = '🔌 Look Behind It';
			sound.tone(120, 0.3, {type: 'sawtooth', volume: 0.04, slide: 240});
			desk.say('Plugged in again. It runs forever again. Pappa says nobody needs to know.');
			speed = desk.reducedMotion ? 0.9 : speed;
		}

		draw();
		loop.start();
	};

	desk.on(plugButton, 'click', next);
	// A click, not a press, pokes the wheel, so a finger that scrolls the page over it does not poke it.
	desk.on(canvas, 'click', () => {
		canvas.focus({preventScroll: true});
		if (desk.reducedMotion) {
			desk.say(isPlugged ? 'You poke the wheel. It does not care. It runs forever.' : 'You poke the wheel. Nothing happens. So much for perpetual.');
		} else {
			if (speed === 0) {
				desk.say('You give the wheel a push. It turns a bit, and stops. So much for perpetual.');
			} else {
				desk.say(isPlugged ? 'You stop the wheel with a finger, and let go. It starts again by itself. Spooky!' : 'You stop the wheel with a finger. It stays still. So much for perpetual.');
			}

			speed = speed === 0 ? 3 : 0;
			loop.start();
		}
	});

	onKeys(desk, canvas, event => {
		if (event.key === ' ' || event.key === 'Enter') {
			next();
		} else {
			return false;
		}
	});

	draw();
};

export default class extends GeoCitiesElement {
	connected() {
		const {sound: soundButton, cradle, plasma, pins, bird, sand, magnet, stress, spinner, perpetual} = this.parts;
		const sound = makeSounds();

		setupCradle(this, cradle, sound);
		const updateBuzz = setupPlasma(this, plasma, sound);
		setupPins(this, pins, sound);
		setupBird(this, bird, sound);
		setupSand(this, sand, sound);
		setupMagnet(this, magnet, sound);
		setupStress(this, stress, sound);
		setupSpinner(this, spinner, sound);
		setupPerpetual(this, perpetual, sound);

		this.on(soundButton, 'click', () => {
			sound.isOn = !sound.isOn && sound.start(this.sound());
			soundButton.setAttribute('aria-pressed', String(sound.isOn));
			soundButton.textContent = sound.isOn ? '🔊 Sound' : '🔈 Sound';
			this.say(sound.isOn ? 'The sound is on: click-clack, bzzzz, and squeak. Pappa’s colleagues look over the wall of the cubicle.' : 'The sound is off. The office is quiet again, except for the fax.');
			sound.tick();
			updateBuzz();
		});
	}
}
