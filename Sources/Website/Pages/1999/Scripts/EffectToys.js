// The Effect Toy Box of the 1999 page: the effects of the demos of the 1990s as toys, each drawn in a small canvas with big square pixels, like the demos. Each runs only while its canvas is on the screen and the tab is visible. For visitors who prefer reduced motion, each shows a still picture that changes only when the visitor does something.
//
// Each toy is set up by its own function, with the box (the element, for its helpers, like `say()`, `on()`, and `animation()`) and the parts, and gives the actions of its buttons.

const clamp = (value, minimum, maximum) => Math.min(Math.max(value, minimum), maximum);
const wrap = (value, size) => ((value % size) + size) % size;

// MARK: Pixels and colors

// A color as the four bytes of a pixel in an `ImageData`, which is red first on the little-endian computers that run browsers.
const rgb = (red, green, blue) => ((255 << 24) | (clamp(Math.round(blue), 0, 255) << 16) | (clamp(Math.round(green), 0, 255) << 8) | clamp(Math.round(red), 0, 255)) >>> 0;

/**
A palette of 256 colors that goes smoothly through the colors, like the palettes of VGA mode 13h.
*/
const makePalette = stops => {
	const palette = new Uint32Array(256);

	for (let index = 0; index < 256; index++) {
		const position = (index / 256) * (stops.length - 1);
		const from = stops[Math.floor(position)];
		const to = stops[Math.min(Math.floor(position) + 1, stops.length - 1)];
		const amount = position - Math.floor(position);
		palette[index] = rgb(...from.map((value, channel) => value + ((to[channel] - value) * amount)));
	}

	return palette;
};

// The palettes of the toys. Each starts and ends with the same color, so the colors can go around and around. The intro (`Cracktro.js`) has the same.
const palettes = [
	{name: 'AMIGA', palette: makePalette([[0, 0, 60], [60, 0, 160], [220, 0, 170], [255, 140, 210], [255, 255, 255], [120, 210, 255], [0, 70, 180], [0, 0, 60]])},
	{name: 'ACID', palette: makePalette([[0, 30, 0], [0, 200, 40], [230, 255, 0], [255, 0, 200], [80, 0, 120], [0, 30, 0]])},
	{name: 'FIRE', palette: makePalette([[20, 0, 0], [170, 0, 0], [255, 120, 0], [255, 230, 60], [255, 255, 220], [255, 140, 0], [20, 0, 0]])},
	{name: 'C64', palette: makePalette([[53, 40, 121], [108, 94, 181], [112, 164, 178], [154, 210, 132], [184, 199, 111], [111, 79, 37], [53, 40, 121]])},
	{name: 'RAINBOW', palette: makePalette([[255, 0, 0], [255, 200, 0], [0, 255, 0], [0, 200, 255], [120, 0, 255], [255, 0, 160], [255, 0, 0]])},
];

const firePalette = makePalette([[0, 0, 0], [80, 0, 0], [200, 30, 0], [255, 120, 0], [255, 210, 40], [255, 255, 180], [255, 255, 255]]);

/**
A canvas that is drawn pixel by pixel, with the pixels as one number each.
*/
const pixelSurface = canvas => {
	const context = canvas.getContext('2d');
	const image = context.createImageData(canvas.width, canvas.height);

	return {
		context,
		width: canvas.width,
		height: canvas.height,
		pixels: new Uint32Array(image.data.buffer),
		show() {
			context.putImageData(image, 0, 0);
		},
	};
};

// The pixels of a canvas that is drawn with the drawing functions of the browser, like text, as numbers.
const canvasPixels = canvas => new Uint32Array(canvas.getContext('2d').getImageData(0, 0, canvas.width, canvas.height).data.buffer);

const makeCanvas = (width, height) => {
	const canvas = document.createElement('canvas');
	canvas.width = width;
	canvas.height = height;
	return canvas;
};

// The position of the pointer in the pixels of the canvas.
const canvasPoint = (canvas, event) => {
	const box = canvas.getBoundingClientRect();
	return {
		x: ((event.clientX - box.left) / box.width) * canvas.width,
		y: ((event.clientY - box.top) / box.height) * canvas.height,
	};
};

// A sine from a table, which is much faster for the effects that need one for every pixel. The angle is in steps of 1/1024 of a turn.
const sineTable = Float32Array.from({length: 1024}, (_, index) => Math.sin((index / 1024) * Math.PI * 2));
const fastSine = steps => sineTable[steps & 1023];

const loadImage = source => new Promise(resolve => {
	const image = new Image();
	image.addEventListener('load', () => {
		resolve(image);
	});
	image.addEventListener('error', () => {
		resolve(undefined);
	});
	image.src = source;
});

// MARK: The animation

/**
Runs `step(delta)` on each frame while the canvas is on the screen, the tab is visible, and motion is allowed, with a loop of the element. The first picture is drawn with `step(0)` when the canvas first shows, also when nothing moves. The returned controls tell whether it runs and pause it, `poke(delta)` draws one more frame when nothing runs by itself, like when the visitor prefers reduced motion and does something, and `drawStill()` draws a still picture when the motion changes.
*/
const animate = (element, canvas, step) => {
	let isPaused = false;
	let hasDrawn = false;

	// A step of 0 seconds draws a still picture, like Fractint, which then draws its whole picture at once, so the first step of a run moves like a frame.
	const loop = element.loop(seconds => {
		step(seconds || (1 / 60));
	}, {target: canvas, maximumStep: 0.05, while: () => !isPaused && !element.reducedMotion});

	const visibility = element.watchVisibility(canvas, isVisible => {
		if (isVisible && !hasDrawn) {
			hasDrawn = true;
			step(0);
		}
	});

	const isRunning = () => visibility.isVisible && !isPaused && !element.reducedMotion;

	return {
		get isRunning() {
			return isRunning();
		},
		setPaused(value) {
			isPaused = value;
			loop.start();
		},
		poke(delta = 0) {
			if (!isRunning()) {
				step(delta);
			}
		},
		drawStill() {
			if (visibility.isVisible) {
				step(0);
			}
		},
	};
};

// MARK: The Effect Toy Box

/**
Follows the pointer over a canvas: a mouse while it moves over it, and a finger or a pen while it touches. `onMove` gets the position in the pixels of the canvas, and `onLeave` is called when the pointer leaves or lifts.
*/
const trackPointer = (toys, canvas, {onMove, onDown, onLeave}) => {
	toys.on(canvas, 'pointerdown', event => {
		onDown?.(canvasPoint(canvas, event));
		onMove?.(canvasPoint(canvas, event));
	});

	toys.on(canvas, 'pointermove', event => {
		if (event.pointerType === 'mouse' || event.buttons > 0) {
			onMove?.(canvasPoint(canvas, event));
		}
	});

	for (const type of ['pointerleave', 'pointerup', 'pointercancel']) {
		toys.on(canvas, type, event => {
			if (type === 'pointerleave' || event.pointerType !== 'mouse') {
				onLeave?.();
			}
		});
	}
};

// A point that wanders by itself, for the toys that play alone when nobody touches them.
const wander = (time, width, height, phase = 0) => ({
	x: (width / 2) + (Math.sin((time * 0.9) + phase) * Math.cos((time * 0.37) + (phase * 2)) * width * 0.42),
	y: (height / 2) + (Math.sin((time * 0.71) + (phase * 3)) * height * 0.38),
});

// MARK: Lava lamp

const setUpLava = (toys, {lava: canvas}) => {
	const surface = pixelSurface(canvas);
	const {width, height, pixels} = surface;
	const colors = [
		{name: 'orange in purple', wax: [255, 130, 20], liquid: [70, 10, 110]},
		{name: 'green in blue', wax: [90, 255, 110], liquid: [10, 30, 120]},
		{name: 'pink in turquoise', wax: [255, 80, 190], liquid: [0, 80, 100]},
		{name: 'red in yellow', wax: [230, 30, 30], liquid: [240, 190, 40]},
	];

	let colorIndex = 0;
	let time = 0;

	// The glass of the lamp is wide in the middle and narrow at the ends, with a metal cap and base.
	const glassTop = 16;
	const glassBottom = 104;
	const glassWidth = y => 12 + (14 * Math.sin(Math.PI * ((y - glassTop) / (glassBottom - glassTop))));
	const halfWidths = Float32Array.from({length: height}, (_, y) => glassWidth(clamp(y, glassTop, glassBottom)));

	const blobs = Array.from({length: 6}, (_, index) => ({
		x: 40 + ((Math.random() - 0.5) * 20),
		y: 30 + (index * 12),
		radius: 6 + (Math.random() * 4),
		heat: Math.random(),
		velocity: 0,
		phase: Math.random() * 10,
	}));

	const draw = () => {
		const {wax, liquid} = colors[colorIndex];
		const room = rgb(20, 8, 32);

		for (let y = 0, index = 0; y < height; y++) {
			const halfWidth = halfWidths[y];
			const isGlass = y >= glassTop && y <= glassBottom;

			for (let x = 0; x < width; x++, index++) {
				const fromCenter = Math.abs(x - 40);

				if (!isGlass) {
					// The cap and the base, in shiny metal.
					const metalWidth = y < glassTop ? 6 + ((y / glassTop) * 6) : 12 + (((y - glassBottom) / (height - glassBottom)) * 16);
					const shine = 1 - (fromCenter / (metalWidth + 1));
					pixels[index] = fromCenter <= metalWidth ? rgb(90 + (120 * shine), 90 + (120 * shine), 110 + (120 * shine)) : room;
					continue;
				}

				if (fromCenter > halfWidth) {
					pixels[index] = room;
					continue;
				}

				// The wax is where the fields of the blobs add up to more than 1, like metaballs. A pool of wax lies on the heater at the bottom.
				let field = Math.max(0, (y - 94) / 8);

				for (const blob of blobs) {
					const dx = x - blob.x;
					const dy = y - blob.y;
					field += (blob.radius * blob.radius) / ((dx * dx) + (dy * dy) + 1);
				}

				const glow = 0.55 + (0.45 * (y / height));
				const edge = 1 - ((fromCenter / halfWidth) * 0.35);

				if (field > 1) {
					const brightness = Math.min(1.25, 0.75 + ((field - 1) * 0.25)) * edge;
					pixels[index] = rgb(wax[0] * brightness, wax[1] * brightness, wax[2] * brightness);
				} else {
					const near = Math.max(0, field - 0.6) * 0.5;
					pixels[index] = rgb(((liquid[0] * (1 - near)) + (wax[0] * near)) * glow * edge, ((liquid[1] * (1 - near)) + (wax[1] * near)) * glow * edge, ((liquid[2] * (1 - near)) + (wax[2] * near)) * glow * edge);
				}
			}
		}

		surface.show();
	};

	const animation = toys.animation(canvas, delta => {
		time += delta;

		// The heater warms the wax at the bottom, and it cools at the top, so it rises and sinks.
		for (const blob of blobs) {
			if (blob.y > 88) {
				blob.heat += delta * 0.3;
			} else if (blob.y < 36) {
				blob.heat -= delta * 0.3;
			} else {
				blob.heat -= delta * 0.02;
			}

			blob.heat = clamp(blob.heat, 0, 1);
			blob.velocity += (((0.5 - blob.heat) * 24) - (blob.velocity * 1.2)) * delta;
			blob.y = clamp(blob.y + (blob.velocity * delta), glassTop + 6, glassBottom - 4);
			blob.x += Math.sin((time * 0.5) + blob.phase) * delta * 5;
			const limit = Math.max(1, halfWidths[Math.round(blob.y)] - (blob.radius * 0.6));
			blob.x = clamp(blob.x, 40 - limit, 40 + limit);
		}

		draw();
	});

	trackPointer(toys, canvas, {
		onDown(point) {
			const nearest = blobs.find(blob => Math.hypot(blob.x - point.x, blob.y - point.y) < blob.radius + 4);

			if (nearest) {
				nearest.heat = 1;
				nearest.velocity -= 8;
			} else if (blobs.length < 10 && point.y > glassTop && point.y < glassBottom && Math.abs(point.x - 40) < halfWidths[Math.round(point.y)]) {
				blobs.push({x: point.x, y: point.y, radius: 5 + (Math.random() * 4), heat: 0.5, velocity: 0, phase: Math.random() * 10});
			}

			// Without motion, each tap moves the wax a little, so a heated blob still rises.
			animation.poke(0.5);
		},
	});

	return {
		color() {
			colorIndex = (colorIndex + 1) % colors.length;
			animation.poke(0);
			toys.say(`The lava lamp is ${colors[colorIndex].name} now.`);
		},
	};
};

// MARK: Kaleidoscope

const setUpKaleidoscope = (toys, {kaleidoscope: canvas}) => {
	const context = canvas.getContext('2d');
	const center = canvas.width / 2;
	const mirrorCounts = [8, 12, 4, 6];
	let mirrorIndex = 0;
	let hue = 0;
	let lastPoint;
	let lastInput = -Infinity;
	let time = 0;
	let wanderPoint;

	const clear = () => {
		context.fillStyle = '#000';
		context.fillRect(0, 0, canvas.width, canvas.height);
	};

	// Each line is drawn once in each slice of the kaleidoscope, and once more mirrored.
	const drawLine = (from, to) => {
		const mirrors = mirrorCounts[mirrorIndex];
		context.save();
		context.translate(center, center);
		context.lineWidth = 3;
		context.lineCap = 'round';
		context.strokeStyle = `hsl(${hue} 100% 60%)`;
		context.globalCompositeOperation = 'lighter';

		for (let slice = 0; slice < mirrors; slice++) {
			context.rotate((Math.PI * 2) / mirrors);

			for (const mirror of [1, -1]) {
				context.save();
				context.scale(1, mirror);
				context.beginPath();
				context.moveTo(from.x - center, from.y - center);
				context.lineTo(to.x - center, to.y - center);
				context.stroke();
				context.restore();
			}
		}

		context.restore();
		hue = (hue + 3) % 360;
	};

	const wanderStep = delta => {
		time += delta;
		const point = wander(time, canvas.width, canvas.height, 1);

		if (wanderPoint) {
			drawLine(wanderPoint, point);
		}

		wanderPoint = point;
	};

	// It starts with a picture, also when nothing moves.
	clear();

	for (let step = 0; step < 120; step++) {
		wanderStep(1 / 30);
	}

	let fadeTime = 0;

	toys.animation(canvas, delta => {
		if (delta === 0) {
			return;
		}

		// The old lines fade slowly into the dark, in steps that are large enough for the faint colors to reach black.
		fadeTime += delta;

		if (fadeTime > 0.15) {
			fadeTime = 0;
			context.fillStyle = 'rgb(0 0 0 / 0.1)';
			context.fillRect(0, 0, canvas.width, canvas.height);
		}

		if (performance.now() - lastInput > 2000) {
			wanderStep(delta);
		} else {
			wanderPoint = undefined;
		}
	});

	trackPointer(toys, canvas, {
		onMove(point) {
			if (lastPoint) {
				drawLine(lastPoint, point);
			}

			lastPoint = point;
			lastInput = performance.now();
		},
		onLeave() {
			lastPoint = undefined;
		},
	});

	return {
		clear() {
			clear();
			toys.say('Shaken! Draw something new.');
		},
		mirrors() {
			mirrorIndex = (mirrorIndex + 1) % mirrorCounts.length;
			toys.say(`The kaleidoscope has ${mirrorCounts[mirrorIndex]} mirrors now.`);
		},
	};
};

// MARK: Fire

const setUpFire = (toys, {fire: canvas, fireForm: form, fireWord: input}) => {
	const surface = pixelSurface(canvas);
	const {width, height, pixels} = surface;
	// The fire has three more lines than the canvas, so the line that burns at the bottom is out of sight.
	const heatHeight = height + 3;
	const heat = new Uint8Array(width * heatHeight);
	let isLit = true;
	let gasoline = 0;
	let word;
	let wordTime = 0;
	let ticks = 0;
	let lastPoint;
	const waterButton = toys.querySelector('[data-demo-action="fire:water"]');

	// One step of the fire: the bottom line burns, and each pixel gets the average heat of the pixels below it, a bit cooler, so the flames rise and fade.
	const burn = () => {
		const bottom = (heatHeight - 1) * width;

		for (let x = 0; x < width; x++) {
			heat[bottom + x] = isLit ? (Math.random() < 0.55 ? 255 : 90) : 0;
		}

		if (gasoline > 0) {
			heat.fill(255, (heatHeight - 8) * width);
		}

		if (word && wordTime > 0) {
			for (let index = 0; index < word.length; index++) {
				if (word[index] && Math.random() < 0.7) {
					heat[index] = 230 + (Math.random() * 25);
				}
			}
		}

		for (let y = 0; y < heatHeight - 1; y++) {
			const next = (y + 1) * width;
			const below = Math.min(y + 2, heatHeight - 1) * width;

			for (let x = 0; x < width; x++) {
				const sum = heat[next + Math.max(x - 1, 0)] + heat[next + x] + heat[next + Math.min(x + 1, width - 1)] + heat[below + x];
				heat[(y * width) + x] = Math.max(0, (sum / 4.06) - (Math.random() * 2.4));
			}
		}
	};

	const draw = () => {
		for (let index = 0; index < pixels.length; index++) {
			pixels[index] = firePalette[heat[index]];
		}

		surface.show();
	};

	// The fire burns 40 times a second, at any refresh rate of the screen.
	const run = seconds => {
		ticks += seconds * 40;

		while (ticks >= 1) {
			ticks--;
			burn();
			gasoline = Math.max(0, gasoline - (1 / 40));
			wordTime = Math.max(0, wordTime - (1 / 40));
		}

		draw();
	};

	run(2);
	const animation = toys.animation(canvas, run);

	// Without motion, the fire takes a few steps for each thing the visitor does, so it still burns.
	const runOnce = seconds => {
		if (animation.isRunning) {
			return;
		}

		run(seconds);
	};

	const paint = point => {
		for (let y = -3; y <= 3; y++) {
			for (let x = -3; x <= 3; x++) {
				const px = Math.round(point.x + x);
				const py = Math.round(point.y + y);

				if ((x * x) + (y * y) <= 10 && px >= 0 && px < width && py >= 0 && py < height) {
					heat[(py * width) + px] = 255;
				}
			}
		}
	};

	trackPointer(toys, canvas, {
		onMove(point) {
			// The flames are painted along the line from the last point, so a fast pointer leaves no gaps.
			const from = lastPoint ?? point;
			const steps = Math.max(1, Math.ceil(Math.hypot(point.x - from.x, point.y - from.y) / 2));

			for (let step = 1; step <= steps; step++) {
				paint({x: from.x + (((point.x - from.x) * step) / steps), y: from.y + (((point.y - from.y) * step) / steps)});
			}

			lastPoint = point;
			runOnce(0.05);
		},
		onLeave() {
			lastPoint = undefined;
		},
	});

	toys.on(form, 'submit', event => {
		event.preventDefault();
		const text = input.value.trim().toUpperCase().slice(0, 10);

		if (!text) {
			return;
		}

		// The word is drawn once, and its pixels burn for a few seconds.
		const mask = makeCanvas(width, height);
		const maskContext = mask.getContext('2d');
		const size = Math.min(44, Math.floor(150 / (text.length * 0.62)));
		maskContext.font = `bold ${size}px Impact, "Arial Black", sans-serif`;
		maskContext.textAlign = 'center';
		maskContext.textBaseline = 'middle';
		maskContext.fillStyle = '#fff';
		maskContext.fillText(text, width / 2, height * 0.62, width - 8);
		word = canvasPixels(mask).map(color => (color >>> 24) > 128 ? 1 : 0);
		wordTime = 3;
		runOnce(0.6);
		toys.say(`${text} is on fire!`);
	});

	return {
		gasoline() {
			isLit = true;
			gasoline = 1;
			waterButton.textContent = 'Put It Out';
			runOnce(0.5);
			toys.say('FWOOSH!');
		},
		water(button) {
			isLit = !isLit;
			button.textContent = isLit ? 'Put It Out' : 'Light It';
			runOnce(1);
			toys.say(isLit ? 'The fire is lit again.' : 'Psssh. The fire is out.');
		},
	};
};

// MARK: Plasma

const setUpPlasma = (toys, {plasma: canvas}) => {
	const surface = pixelSurface(canvas);
	const {width, height, pixels} = surface;
	let paletteIndex = 4;
	let time = 2;
	let stir = {x: width / 2, y: height / 2};
	let twist = 0;
	let lastPoint;

	// The pointer twists the plasma around it, more the faster it stirs, and the twist slowly settles.
	const draw = () => {
		const colors = palettes[paletteIndex].palette;
		const a = Math.floor(time * 50);
		const b = Math.floor(time * 37);
		const shift = Math.floor(time * 40);

		for (let y = 0, index = 0; y < height; y++) {
			for (let x = 0; x < width; x++, index++) {
				const dx = x - stir.x;
				const dy = y - stir.y;
				const angle = twist * Math.exp(-((dx * dx) + (dy * dy)) / 700);
				const cos = Math.cos(angle);
				const sin = Math.sin(angle);
				const sx = stir.x + ((dx * cos) - (dy * sin));
				const sy = stir.y + ((dx * sin) + (dy * cos));
				const value = fastSine((sx * 9) + a) + fastSine((sy * 11) - b) + fastSine(((sx + sy) * 6) + (a >> 1)) + fastSine((Math.hypot(sx - 80, sy - 50) * 14) - a);
				pixels[index] = colors[(Math.floor(value * 32) + shift) & 255];
			}
		}

		surface.show();
	};

	const animation = toys.animation(canvas, delta => {
		time += delta;
		twist *= Math.exp(-delta * 0.6);
		draw();
	});

	trackPointer(toys, canvas, {
		onMove(point) {
			if (lastPoint) {
				twist = clamp(twist + (Math.hypot(point.x - lastPoint.x, point.y - lastPoint.y) * 0.05), -8, 8);
			}

			lastPoint = point;
			stir = point;
			animation.poke(0);
		},
		onLeave() {
			lastPoint = undefined;
		},
	});

	return {
		colors() {
			paletteIndex = (paletteIndex + 1) % palettes.length;
			animation.poke(0);
			toys.say(`Plasma colors: ${palettes[paletteIndex].name}.`);
		},
	};
};

// MARK: Flashlight

const setUpFlashlight = (toys, {bump: canvas}) => {
	const surface = pixelSurface(canvas);
	const {width, height, pixels} = surface;

	// The heights: a waffle with my name and the year in it, softened a bit, so the light runs smoothly over the edges.
	const heights = (() => {
		const source = makeCanvas(width, height);
		const sourceContext = source.getContext('2d');
		sourceContext.fillStyle = '#555';
		sourceContext.fillRect(0, 0, width, height);
		sourceContext.fillStyle = '#222';

		for (let y = 3; y < height; y += 14) {
			for (let x = 3; x < width; x += 14) {
				sourceContext.fillRect(x, y, 10, 10);
			}
		}

		sourceContext.fillStyle = '#fff';
		sourceContext.textAlign = 'center';
		sourceContext.textBaseline = 'middle';
		sourceContext.font = 'bold 40px Impact, "Arial Black", sans-serif';
		sourceContext.fillText('SINDRE', width / 2, 44);
		sourceContext.font = 'bold 20px Impact, "Arial Black", sans-serif';
		sourceContext.fillText('1999', width / 2, 80);
		let values = Float32Array.from(canvasPixels(source), color => color & 255);

		for (let pass = 0; pass < 2; pass++) {
			const blurred = new Float32Array(values.length);

			for (let y = 0; y < height; y++) {
				for (let x = 0; x < width; x++) {
					let sum = 0;

					for (let offset = -1; offset <= 1; offset++) {
						sum += values[(y * width) + clamp(x + offset, 0, width - 1)] + values[(clamp(y + offset, 0, height - 1) * width) + x];
					}

					blurred[(y * width) + x] = sum / 6;
				}
			}

			values = blurred;
		}

		return values;
	})();

	// The slope of each pixel, which bends the light, like the bump mapping of the demos of 1996.
	const slopesX = new Int16Array(width * height);
	const slopesY = new Int16Array(width * height);

	for (let y = 0; y < height; y++) {
		for (let x = 0; x < width; x++) {
			const index = (y * width) + x;
			slopesX[index] = heights[(y * width) + Math.min(x + 1, width - 1)] - heights[(y * width) + Math.max(x - 1, 0)];
			slopesY[index] = heights[(Math.min(y + 1, height - 1) * width) + x] - heights[(Math.max(y - 1, 0) * width) + x];
		}
	}

	const lightMap = new Float32Array(256 * 256);

	for (let y = 0; y < 256; y++) {
		for (let x = 0; x < 256; x++) {
			lightMap[(y * 256) + x] = Math.max(0, 1 - (Math.hypot(x - 128, y - 128) / 90)) ** 2;
		}
	}

	const lightColors = [
		{name: 'white', color: [255, 255, 255]},
		{name: 'gold', color: [255, 200, 80]},
		{name: 'ice blue', color: [90, 220, 255]},
		{name: 'disco pink', color: [255, 90, 220]},
	];

	let colorIndex = 0;
	let light = {x: 50, y: 40};
	let lastInput = -Infinity;
	let time = 0;

	const draw = () => {
		const [red, green, blue] = lightColors[colorIndex].color;

		for (let y = 0, index = 0; y < height; y++) {
			for (let x = 0; x < width; x++, index++) {
				const u = clamp(Math.round(x - light.x + (slopesX[index] * 0.5) + 128), 0, 255);
				const v = clamp(Math.round(y - light.y + (slopesY[index] * 0.5) + 128), 0, 255);
				const intensity = lightMap[(v * 256) + u] + (heights[index] / 4000);
				pixels[index] = rgb(red * intensity, green * intensity, blue * intensity);
			}
		}

		surface.show();
	};

	const animation = toys.animation(canvas, delta => {
		time += delta;

		if (performance.now() - lastInput > 2000) {
			light = wander(time, width, height, 2);
		}

		draw();
	});

	trackPointer(toys, canvas, {
		onMove(point) {
			light = point;
			lastInput = performance.now();
			animation.poke(0);
		},
	});

	return {
		color() {
			colorIndex = (colorIndex + 1) % lightColors.length;
			animation.poke(0);
			toys.say(`The flashlight is ${lightColors[colorIndex].name} now.`);
		},
	};
};

// MARK: Fractint

const setUpFractint = (toys, {fractal: canvas, fractalInfo: info}) => {
	const surface = pixelSurface(canvas);
	const {context, width, height, pixels} = surface;
	const cycleButton = toys.querySelector('[data-demo-action="fractal:cycle"]');
	const startSpan = 3.2;
	const iterations = new Uint16Array(width * height);
	let center = {x: -0.6, y: 0};
	let span = startSpan;
	let renderedRows = 0;
	let iterationCount = 0;
	let cycle = 0;
	let isCycling = false;
	let hasFocus = false;
	const cross = {x: width / 2, y: height / 2};
	const colors = palettes[0].palette;

	const maxIterations = () => Math.min(600, Math.floor(64 + (Math.log2(startSpan / span) * 24)));

	const colorRow = y => {
		const maximum = maxIterations();

		for (let x = 0, index = y * width; x < width; x++, index++) {
			const count = iterations[index];
			pixels[index] = count >= maximum ? rgb(0, 0, 0) : colors[((count * 5) + Math.floor(cycle)) & 255];
		}
	};

	const renderRow = y => {
		const maximum = maxIterations();
		const imaginary = center.y + (((y - (height / 2)) * span) / width);

		for (let x = 0; x < width; x++) {
			const real = center.x + (((x - (width / 2)) * span) / width);
			let zReal = 0;
			let zImaginary = 0;
			let count = 0;

			while (count < maximum && (zReal * zReal) + (zImaginary * zImaginary) < 4) {
				const nextReal = (zReal * zReal) - (zImaginary * zImaginary) + real;
				zImaginary = (2 * zReal * zImaginary) + imaginary;
				zReal = nextReal;
				count++;
			}

			iterations[(y * width) + x] = count;
			iterationCount += count;
		}

		colorRow(y);
	};

	const formatZoom = zoom => zoom < 1000 ? `${Math.round(zoom)}` : zoom.toExponential(1).replace('e+', '×10^');

	// A 486 at 33 MHz did about 20,000 iterations a second in Fractint, more or less.
	const showInfo = () => {
		const seconds = iterationCount / 20_000;
		const time = renderedRows < height ? 'drawing…' : (seconds < 60 ? `${Math.max(1, Math.round(seconds))} s on my 486` : `${Math.round(seconds / 60)} min on my 486`);
		info.textContent = `Zoom ${formatZoom(startSpan / span)}× ★ ${maxIterations()} iterations ★ ${time}`;
	};

	const drawCross = () => {
		if (!hasFocus) {
			return;
		}

		context.fillStyle = '#fff';
		context.fillRect(cross.x - 4, cross.y, 9, 1);
		context.fillRect(cross.x, cross.y - 4, 1, 9);
	};

	const show = () => {
		surface.show();
		drawCross();
	};

	const animation = toys.animation(canvas, delta => {
		// Like Fractint on a slow computer, the picture is drawn a few lines at a time, over the old one.
		const rowsPerFrame = delta === 0 ? height : 4;

		for (let row = 0; row < rowsPerFrame && renderedRows < height; row++) {
			renderRow(renderedRows);
			renderedRows++;

			if (renderedRows === height) {
				showInfo();
			}
		}

		if (isCycling && delta > 0) {
			cycle += delta * 60;

			for (let y = 0; y < renderedRows; y++) {
				colorRow(y);
			}
		}

		show();
	});

	const finishWithoutMotion = () => {
		if (animation.isRunning) {
			return;
		}

		while (renderedRows < height) {
			renderRow(renderedRows);
			renderedRows++;
		}

		showInfo();
		show();
	};

	const zoomAt = (x, y, factor) => {
		const newSpan = Math.min(startSpan * 1.5, span / factor);

		if (newSpan < 1e-12) {
			toys.say('Fractint ran out of decimals! Zoom out.');
			return;
		}

		center = {x: center.x + (((x - (width / 2)) * span) / width), y: center.y + (((y - (height / 2)) * span) / width)};
		span = newSpan;
		cross.x = width / 2;
		cross.y = height / 2;
		renderedRows = 0;
		iterationCount = 0;
		showInfo();
		finishWithoutMotion();
		toys.say(`Zoom ${formatZoom(startSpan / span)}×.`);
	};

	toys.on(canvas, 'click', event => {
		const point = canvasPoint(canvas, event);
		zoomAt(point.x, point.y, 2);
	});

	toys.on(canvas, 'focus', () => {
		hasFocus = true;
		show();
	});

	toys.on(canvas, 'blur', () => {
		hasFocus = false;
		show();
	});

	toys.on(canvas, 'keydown', event => {
		const moves = {ArrowLeft: [-4, 0], ArrowRight: [4, 0], ArrowUp: [0, -4], ArrowDown: [0, 4]};

		if (moves[event.key]) {
			event.preventDefault();
			cross.x = clamp(cross.x + moves[event.key][0], 0, width - 1);
			cross.y = clamp(cross.y + moves[event.key][1], 0, height - 1);
			show();
		} else if (event.key === 'Enter' || event.key === ' ') {
			event.preventDefault();
			zoomAt(cross.x, cross.y, 2);
		} else if (event.key === '-') {
			event.preventDefault();
			zoomAt(width / 2, height / 2, 0.5);
		}
	});

	showInfo();

	return {
		in() {
			zoomAt(cross.x, cross.y, 2);
		},
		out() {
			zoomAt(width / 2, height / 2, 0.5);
		},
		cycle() {
			// Without motion, each press turns the colors one step instead.
			if (toys.reducedMotion) {
				cycle += 40;

				for (let y = 0; y < renderedRows; y++) {
					colorRow(y);
				}

				show();
				return;
			}

			isCycling = !isCycling;
			cycleButton.textContent = isCycling ? 'Stop Cycling' : 'Color Cycling';
		},
	};
};

// MARK: Fly over the fjord

const setUpFjord = (toys, {voxel: canvas}) => {
	const surface = pixelSurface(canvas);
	const {width, height, pixels} = surface;
	const mapSize = 256;
	const heightMap = new Uint8Array(mapSize * mapSize);
	const colorMap = new Uint32Array(mapSize * mapSize);
	const waterLevel = 46;
	const fjordX = y => 128 + (Math.sin((y / mapSize) * Math.PI * 4) * 50);

	// The landscape: mountains of value noise, with a fjord that winds through them, which wraps around at the edges, so the flight never ends. It is made the first time it shows, as it takes a moment.
	let isLandscapeReady = false;

	const makeLandscape = () => {
		isLandscapeReady = true;
		const lattice = Float32Array.from({length: mapSize * mapSize}, () => Math.random());

		const noise = (x, y, cell) => {
			const cells = mapSize / cell;
			const x0 = Math.floor(x / cell);
			const y0 = Math.floor(y / cell);
			const fx = (x / cell) - x0;
			const fy = (y / cell) - y0;
			const smoothX = fx * fx * (3 - (2 * fx));
			const smoothY = fy * fy * (3 - (2 * fy));
			const at = (cellX, cellY) => lattice[(wrap(cellY, cells) * mapSize) + wrap(cellX, cells)];
			const top = at(x0, y0) + ((at(x0 + 1, y0) - at(x0, y0)) * smoothX);
			const bottom = at(x0, y0 + 1) + ((at(x0 + 1, y0 + 1) - at(x0, y0 + 1)) * smoothX);
			return top + ((bottom - top) * smoothY);
		};

		const raw = new Float32Array(mapSize * mapSize);

		for (let y = 0; y < mapSize; y++) {
			const fjordCenter = fjordX(y);

			for (let x = 0; x < mapSize; x++) {
				let value = (noise(x, y, 64) * 0.5) + (noise(x, y, 32) * 0.25) + (noise(x, y, 16) * 0.13) + (noise(x, y, 8) * 0.08) + (noise(x, y, 4) * 0.04);
				const fromFjord = Math.min(Math.abs(x - fjordCenter), mapSize - Math.abs(x - fjordCenter));
				value *= 0.15 + (0.85 * clamp((fromFjord - 12) / 50, 0, 1));
				raw[(y * mapSize) + x] = value;
			}
		}

		for (let index = 0; index < raw.length; index++) {
			heightMap[index] = Math.max(waterLevel, Math.min(255, raw[index] * 210));
		}

		for (let y = 0; y < mapSize; y++) {
			for (let x = 0; x < mapSize; x++) {
				const index = (y * mapSize) + x;
				const value = heightMap[index];
				const slope = heightMap[(y * mapSize) + wrap(x - 1, mapSize)] - heightMap[(y * mapSize) + wrap(x + 1, mapSize)];
				const shade = clamp(1 + (slope * 0.03), 0.55, 1.35);
				let color;

				if (value <= waterLevel) {
					color = [30, 70 + (Math.random() * 10), 140];
				} else if (value < waterLevel + 4) {
					color = [190, 175, 120];
				} else if (value < 130) {
					color = [50 + (value * 0.2), 110 + (value * 0.3), 45];
				} else if (value < 185) {
					color = [110, 105, 100];
				} else {
					color = [240, 240, 255];
				}

				colorMap[index] = rgb(color[0] * shade, color[1] * shade, color[2] * shade);
			}
		}
	};

	const timesOfDay = [
		{name: 'Day over the fjord.', top: [60, 130, 220], horizon: [200, 230, 255]},
		{name: 'Sunset over the fjord.', top: [50, 30, 110], horizon: [255, 140, 60]},
		{name: 'Night over the fjord. Look, the northern lights!', top: [2, 4, 20], horizon: [20, 35, 70], hasAurora: true},
	];

	const stars = Array.from({length: 40}, () => ({x: Math.floor(Math.random() * width), y: Math.floor(Math.random() * 40)}));
	const camera = {x: fjordX(200), y: 200, angle: 0, height: 100};
	let timeIndex = 0;
	let time = 0;
	let steer = 0;
	let keySteer = 0;
	let targetHeight = 100;
	let lastInput = -Infinity;
	const horizon = 40;
	const distance = 240;
	const columnTops = new Float32Array(width);

	const draw = () => {
		if (!isLandscapeReady) {
			makeLandscape();
		}

		const sky = timesOfDay[timeIndex];
		const [fogRed, fogGreen, fogBlue] = sky.horizon;

		// The sky, with the northern lights at night.
		for (let y = 0; y < height; y++) {
			const amount = clamp(y / (horizon + 20), 0, 1);
			const color = sky.top.map((value, channel) => value + ((sky.horizon[channel] - value) * amount));

			for (let x = 0; x < width; x++) {
				let [red, green, blue] = color;

				if (sky.hasAurora && y < horizon + 10) {
					const curtain = Math.max(0, Math.sin((x * 0.06) + (time * 0.4) + (Math.sin((x * 0.02) + time) * 2))) * Math.max(0, 1 - Math.abs(y - (14 + (Math.sin((x * 0.04) + time) * 6))) / 14);
					green += curtain * 170;
					blue += curtain * 60;
				}

				pixels[(y * width) + x] = rgb(red, green, blue);
			}
		}

		if (sky.hasAurora) {
			for (const star of stars) {
				pixels[(star.y * width) + star.x] = rgb(255, 255, 255);
			}
		}

		// The landscape, drawn from the front to the back, one line of the map at a time, like the Voxel Space engine of Comanche (1992). A column is only drawn above what is already in front of it.
		columnTops.fill(height);
		const sin = Math.sin(camera.angle);
		const cos = Math.cos(camera.angle);
		let step = 1;

		for (let z = 1; z < distance; z += step, step += 0.012) {
			let leftX = (-cos * z) - (sin * z) + camera.x;
			let leftY = (sin * z) - (cos * z) + camera.y;
			const rightX = (cos * z) - (sin * z) + camera.x;
			const rightY = (-sin * z) - (cos * z) + camera.y;
			const stepX = (rightX - leftX) / width;
			const stepY = (rightY - leftY) / width;
			const scale = 45 / z;
			const fog = (z / distance) ** 2;

			for (let x = 0; x < width; x++) {
				const index = ((leftY & 255) * mapSize) + (leftX & 255);
				const top = Math.max(0, Math.floor(((camera.height - heightMap[index]) * scale) + horizon));

				if (top < columnTops[x]) {
					const ground = colorMap[index];
					const red = ground & 255;
					const green = (ground >> 8) & 255;
					const blue = (ground >> 16) & 255;
					const color = rgb(red + ((fogRed - red) * fog), green + ((fogGreen - green) * fog), blue + ((fogBlue - blue) * fog));

					for (let y = top; y < columnTops[x]; y++) {
						pixels[(y * width) + x] = color;
					}

					columnTops[x] = top;
				}

				leftX += stepX;
				leftY += stepY;
			}
		}

		surface.show();
	};

	// When nobody steers, the helicopter follows the fjord by itself.
	const autopilot = () => {
		const aheadY = camera.y - (Math.cos(camera.angle) * 40);
		const wanted = Math.atan2(-(fjordX(aheadY) - camera.x), -(aheadY - camera.y));
		const turn = Math.atan2(Math.sin(camera.angle - wanted), Math.cos(camera.angle - wanted));
		return clamp(turn * 1.5, -1, 1);
	};

	const fly = delta => {
		time += delta;
		const isSteering = performance.now() - lastInput < 2000;
		camera.angle -= (isSteering ? steer + keySteer : autopilot()) * delta * 1.2;
		camera.x -= Math.sin(camera.angle) * delta * 30;
		camera.y -= Math.cos(camera.angle) * delta * 30;

		// The helicopter climbs over the mountains by itself, also the ones just ahead.
		const groundAt = ahead => heightMap[((Math.floor(camera.y - (Math.cos(camera.angle) * ahead)) & 255) * mapSize) + (Math.floor(camera.x - (Math.sin(camera.angle) * ahead)) & 255)];
		const ground = Math.max(groundAt(0), groundAt(10), groundAt(20));
		camera.height += (Math.max(targetHeight, ground + 25) - camera.height) * Math.min(1, delta * 2);
		draw();
	};

	const animation = toys.animation(canvas, fly);

	trackPointer(toys, canvas, {
		onMove(point) {
			lastInput = performance.now();
			steer = clamp((point.x - (width / 2)) / (width / 2), -1, 1);
			targetHeight = 80 + ((1 - (point.y / height)) * 160);
		},
		onLeave() {
			steer = 0;
		},
	});

	toys.on(canvas, 'keydown', event => {
		const turns = {ArrowLeft: -1, ArrowRight: 1};

		if (turns[event.key] !== undefined) {
			event.preventDefault();
			keySteer = turns[event.key];
			lastInput = performance.now();

			// Without motion, each key flies a short way.
			animation.poke(0.15);
		} else if (event.key === 'ArrowUp' || event.key === 'ArrowDown') {
			event.preventDefault();
			targetHeight = clamp(targetHeight + (event.key === 'ArrowUp' ? 15 : -15), 60, 250);
			lastInput = performance.now();
			animation.poke(0.15);
		}
	});

	toys.on(canvas, 'keyup', () => {
		keySteer = 0;
	});

	toys.on(canvas, 'blur', () => {
		keySteer = 0;
	});

	return {
		time() {
			timeIndex = (timeIndex + 1) % timesOfDay.length;
			animation.poke(0);
			toys.say(timesOfDay[timeIndex].name);
		},
	};
};

// MARK: Shadebobs

const setUpShadebobs = (toys, {shadebobs: canvas}) => {
	const surface = pixelSurface(canvas);
	const {width, height, pixels} = surface;
	const buffer = new Uint8Array(width * height);
	const colors = palettes[0].palette;
	const bobCounts = [3, 5, 1, 2];
	let countIndex = 0;
	let time = 0;
	let ticks = 0;
	let pointer;
	let lastInput = -Infinity;

	// A bob adds to the pixels under it, and the sums go around the palette, so the trails turn into rings of color.
	const radius = 9;
	const offsets = [];

	for (let y = -radius; y <= radius; y++) {
		for (let x = -radius; x <= radius; x++) {
			if ((x * x) + (y * y) <= radius * radius) {
				offsets.push([x, y]);
			}
		}
	}

	const addBob = (centerX, centerY) => {
		const bobX = Math.round(centerX);
		const bobY = Math.round(centerY);

		for (const [x, y] of offsets) {
			const px = bobX + x;
			const py = bobY + y;

			if (px >= 0 && px < width && py >= 0 && py < height) {
				const index = (py * width) + px;
				buffer[index] = (buffer[index] + 3) & 255;
			}
		}
	};

	const draw = () => {
		for (let index = 0; index < pixels.length; index++) {
			pixels[index] = colors[buffer[index]];
		}

		surface.show();
	};

	for (let step = 0; step < 90; step++) {
		time += 1 / 60;

		for (let bob = 0; bob < bobCounts[countIndex]; bob++) {
			const point = wander(time, width, height, bob * 2.1);
			addBob(point.x, point.y);
		}
	}

	const animation = toys.animation(canvas, delta => {
		ticks += delta * 60;

		while (ticks >= 1) {
			ticks--;
			time += 1 / 60;
			const isPointerActive = pointer && performance.now() - lastInput < 1000;

			for (let bob = 0; bob < bobCounts[countIndex]; bob++) {
				const point = bob === 0 && isPointerActive ? pointer : wander(time, width, height, bob * 2.1);
				addBob(point.x, point.y);
			}
		}

		draw();
	});

	trackPointer(toys, canvas, {
		onMove(point) {
			pointer = point;
			lastInput = performance.now();

			if (!animation.isRunning) {
				addBob(point.x, point.y);
				draw();
			}
		},
	});

	return {
		bobs() {
			countIndex = (countIndex + 1) % bobCounts.length;
			toys.say(`${bobCounts[countIndex]} ${bobCounts[countIndex] === 1 ? 'shadebob' : 'shadebobs'}.`);
		},
		clear() {
			buffer.fill(0);
			draw();
		},
	};
};

// MARK: Disco floor

const setUpDisco = (toys, {disco: canvas}) => {
	const context = canvas.getContext('2d');
	const size = 8;
	const tile = canvas.width / size;
	const brightness = new Float32Array(size * size);
	const hues = Float32Array.from({length: size * size}, () => Math.random() * 360);
	let danceIndex = 0;
	let time = 0;
	let beat = -1;

	// Each dance lights the tiles on the beat, at 120 beats a minute.
	const dances = [
		{
			name: 'Saturday Night Fever',
			onBeat(count) {
				for (let index = 0; index < brightness.length; index++) {
					if (((index % size) + Math.floor(index / size) + count) % 2 === 0) {
						brightness[index] = 1;
						hues[index] = (count * 47) % 360;
					}
				}
			},
		},
		{
			name: 'the Ripple',
			onBeat(count) {
				for (let index = 0; index < brightness.length; index++) {
					const ring = Math.floor(Math.hypot((index % size) - 3.5, Math.floor(index / size) - 3.5));

					if (ring === count % 5) {
						brightness[index] = 1;
						hues[index] = (count * 60) % 360;
					}
				}
			},
		},
		{
			name: 'the Rainbow Wave',
			everyFrame() {
				for (let index = 0; index < brightness.length; index++) {
					const diagonal = (index % size) + Math.floor(index / size);
					brightness[index] = Math.max(brightness[index], (Math.sin((diagonal * 0.8) - (time * 5)) + 1) / 2);
					hues[index] = ((diagonal * 30) + (time * 80)) % 360;
				}
			},
		},
		{
			name: 'the Sparkle',
			onBeat() {
				for (let count = 0; count < 12; count++) {
					const index = Math.floor(Math.random() * brightness.length);
					brightness[index] = 1;
					hues[index] = Math.random() * 360;
				}
			},
		},
	];

	const draw = () => {
		context.fillStyle = '#000';
		context.fillRect(0, 0, canvas.width, canvas.height);

		for (let index = 0; index < brightness.length; index++) {
			const x = (index % size) * tile;
			const y = Math.floor(index / size) * tile;
			const light = brightness[index];
			context.fillStyle = `hsl(${hues[index]} 100% ${8 + (light * 50)}%)`;
			context.fillRect(x + 1, y + 1, tile - 2, tile - 2);
			context.fillStyle = `hsl(${hues[index]} 100% ${12 + (light * 75)}%)`;
			context.fillRect(x + 5, y + 5, tile - 10, tile - 10);
		}
	};

	dances[0].onBeat(0);

	const animation = toys.animation(canvas, delta => {
		time += delta;
		const dance = dances[danceIndex];
		const count = Math.floor(time * 2);

		if (count !== beat) {
			beat = count;
			dance.onBeat?.(count);
		}

		dance.everyFrame?.();

		for (let index = 0; index < brightness.length; index++) {
			brightness[index] = Math.max(0, brightness[index] - (delta * 2.2));
		}

		draw();
	});

	trackPointer(toys, canvas, {
		onMove(point) {
			const column = clamp(Math.floor(point.x / tile), 0, size - 1);
			const row = clamp(Math.floor(point.y / tile), 0, size - 1);
			const hue = Math.random() * 360;

			for (const [dx, dy, amount] of [[0, 0, 1], [1, 0, 0.6], [-1, 0, 0.6], [0, 1, 0.6], [0, -1, 0.6]]) {
				const x = column + dx;
				const y = row + dy;

				if (x >= 0 && x < size && y >= 0 && y < size) {
					brightness[(y * size) + x] = Math.max(brightness[(y * size) + x], amount);
					hues[(y * size) + x] = hue;
				}
			}

			animation.poke(0);
		},
	});

	return {
		dance() {
			danceIndex = (danceIndex + 1) % dances.length;
			dances[danceIndex].onBeat?.(beat + 1);
			dances[danceIndex].everyFrame?.();
			animation.poke(0);
			toys.say(`Now dancing ${dances[danceIndex].name}.`);
		},
	};
};

// MARK: Moiré

const setUpMoire = (toys, {moire: canvas}) => {
	const surface = pixelSurface(canvas);
	const {width, height, pixels} = surface;
	const ringWidths = [6, 4, 3, 8];
	let ringIndex = 0;
	let time = 1;
	let pointer;
	let lastInput = -Infinity;

	// Two sets of rings, and a pixel is light where exactly one of them has a light ring, which makes the waves of a moiré.
	const draw = () => {
		const first = pointer && performance.now() - lastInput < 3000 ? pointer : wander(time, width, height, 0.5);
		const second = wander(time * 0.8, width, height, 3);
		const ringWidth = ringWidths[ringIndex];
		const light = palettes[4].palette[Math.floor(time * 30) & 255];
		const dark = rgb(10, 0, 30);

		for (let y = 0, index = 0; y < height; y++) {
			for (let x = 0; x < width; x++, index++) {
				const ringA = Math.floor(Math.hypot(x - first.x, y - first.y) / ringWidth);
				const ringB = Math.floor(Math.hypot(x - second.x, y - second.y) / ringWidth);
				pixels[index] = ((ringA + ringB) & 1) === 0 ? light : dark;
			}
		}

		surface.show();
	};

	const animation = toys.animation(canvas, delta => {
		time += delta;
		draw();
	});

	trackPointer(toys, canvas, {
		onMove(point) {
			pointer = point;
			lastInput = performance.now();
			animation.poke(0);
		},
	});

	return {
		rings() {
			ringIndex = (ringIndex + 1) % ringWidths.length;
			animation.poke(0);
			toys.say(ringWidths[ringIndex] < 6 ? 'More rings! Try not to get dizzy.' : 'Fewer rings. Your eyes can rest.');
		},
	};
};

// MARK: Cube of GIFs

// The rotation of a point around the X and Y axes, for the cube of GIFs.
const rotate3D = ([x, y, z], angleX, angleY) => {
	const [cosY, sinY] = [Math.cos(angleY), Math.sin(angleY)];
	[x, z] = [(x * cosY) + (z * sinY), (z * cosY) - (x * sinY)];
	const [cosX, sinX] = [Math.cos(angleX), Math.sin(angleX)];
	[y, z] = [(y * cosX) - (z * sinX), (y * sinX) + (z * cosX)];
	return [x, y, z];
};

const setUpCube = (toys, {cube: canvas, cubeFaces}) => {
	const context = canvas.getContext('2d');
	const center = canvas.width / 2;
	const faceImages = [];
	let angleX = -0.4;
	let angleY = 0.6;
	let velocityY = 0.6;
	let dragX;

	// The GIFs of the page, or their still frames for visitors who prefer reduced motion. They load the first time the cube shows.
	const loadFaces = () => {
		for (const [index, image] of [...cubeFaces.content.querySelectorAll('img')].entries()) {
			faceImages[index] = null;
			loadImage(toys.reducedMotion ? image.dataset.demoStill : image.getAttribute('src')).then(loaded => {
				faceImages[index] = loaded;
				draw();
			});
		}
	};

	const vertices = [[-1, -1, -1], [1, -1, -1], [1, 1, -1], [-1, 1, -1], [-1, -1, 1], [1, -1, 1], [1, 1, 1], [-1, 1, 1]];

	// Each face is its corners from the top left, clockwise, as seen from the front of the face.
	const faces = [[4, 5, 6, 7], [1, 0, 3, 2], [0, 4, 7, 3], [5, 1, 2, 6], [0, 1, 5, 4], [7, 6, 2, 3]];

	const draw = () => {
		if (faceImages.length === 0) {
			loadFaces();
		}

		const background = context.createRadialGradient(center, center, 10, center, center, center * 1.4);
		background.addColorStop(0, '#203070');
		background.addColorStop(1, '#000010');
		context.setTransform(1, 0, 0, 1, 0, 0);
		context.fillStyle = background;
		context.fillRect(0, 0, canvas.width, canvas.height);

		const points = vertices.map(vertex => rotate3D(vertex, angleX, angleY));
		const visible = faces.map((face, index) => {
			const [p0, p1, , p3] = face.map(vertexIndex => points[vertexIndex]);
			const across = [p1[0] - p0[0], p1[1] - p0[1], p1[2] - p0[2]];
			const down = [p3[0] - p0[0], p3[1] - p0[1], p3[2] - p0[2]];
			const facing = (across[0] * down[1]) - (across[1] * down[0]);
			return {face, index, facing};
		}).filter(item => item.facing > 0);

		// The faces are drawn as a picture that is stretched over each face, which works because the cube has no perspective.
		for (const {face, index, facing} of visible) {
			const [p0, p1, , p3] = face.map(vertexIndex => points[vertexIndex]).map(([x, y]) => [center + (x * 70), center + (y * 70)]);
			context.setTransform(p1[0] - p0[0], p1[1] - p0[1], p3[0] - p0[0], p3[1] - p0[1], p0[0], p0[1]);
			context.fillStyle = '#fff';
			context.fillRect(0, 0, 1, 1);
			const image = faceImages[index];

			if (image) {
				const scale = 0.9 / Math.max(image.naturalWidth, image.naturalHeight);
				const imageWidth = image.naturalWidth * scale;
				const imageHeight = image.naturalHeight * scale;
				context.drawImage(image, (1 - imageWidth) / 2, (1 - imageHeight) / 2, imageWidth, imageHeight);
			}

			context.fillStyle = `rgb(0 0 40 / ${0.45 * (1 - Math.min(1, facing / 4))})`;
			context.fillRect(0, 0, 1, 1);
			context.lineWidth = 0.03;
			context.strokeStyle = '#000';
			context.strokeRect(0, 0, 1, 1);
		}

		context.setTransform(1, 0, 0, 1, 0, 0);
	};

	const animation = toys.animation(canvas, delta => {
		if (dragX === undefined) {
			velocityY += (0.6 - velocityY) * Math.min(1, delta * 0.7);
		}

		angleY += velocityY * delta;
		angleX = -0.4 + (Math.sin(angleY * 0.5) * 0.25);
		draw();
	});

	toys.on(canvas, 'pointerdown', event => {
		dragX = event.clientX;
		canvas.setPointerCapture(event.pointerId);
	});

	toys.on(canvas, 'pointermove', event => {
		if (dragX === undefined) {
			return;
		}

		const moved = event.clientX - dragX;
		dragX = event.clientX;
		angleY += moved * 0.015;
		velocityY = clamp(moved * 0.8, -12, 12);
		animation.poke(0);
	});

	for (const type of ['pointerup', 'pointercancel']) {
		toys.on(canvas, type, () => {
			dragX = undefined;
		});
	}

	return {
		spin() {
			velocityY += 10;

			// Without motion, it turns a quarter for each press.
			if (!animation.isRunning) {
				angleY += Math.PI / 2;
				angleX = -0.4 + (Math.sin(angleY * 0.5) * 0.25);
				draw();
			}

			toys.say('Wheee!');
		},
	};
};

// MARK: Bouncing logo

const setUpBounce = (toys, {bounce: canvas, bounceCount: countElement}) => {
	const context = canvas.getContext('2d');
	const logoWidth = 72;
	const logoHeight = 32;
	const maximumX = canvas.width - logoWidth;
	const maximumY = canvas.height - logoHeight;
	const colors = ['#ff3355', '#33ccff', '#ffdd33', '#66ff66', '#cc66ff', '#ff9933', '#ffffff', '#ff66cc'];
	let colorIndex = 0;
	let cornerHits = Math.max(0, Math.floor(Number(toys.stored('corner-hits', 0)) || 0));
	let celebration = 0;
	let ticks = 0;

	// The logo moves one pixel at a time, 80 times a second, from a place where it hits the corner after 30 seconds, and then every 46 seconds, as long as nobody nudges it.
	const logo = {x: 176, y: 0, dx: 1, dy: 1};
	countElement.textContent = cornerHits.toLocaleString('en-US');

	const move = () => {
		logo.x += logo.dx;
		logo.y += logo.dy;
		const hitsSide = logo.x <= 0 || logo.x >= maximumX;
		const hitsTop = logo.y <= 0 || logo.y >= maximumY;

		if (hitsSide) {
			logo.dx = -logo.dx;
		}

		if (hitsTop) {
			logo.dy = -logo.dy;
		}

		if (hitsSide || hitsTop) {
			colorIndex = (colorIndex + 1) % colors.length;
		}

		if (hitsSide && hitsTop) {
			cornerHits++;
			toys.store('corner-hits', cornerHits);
			countElement.textContent = cornerHits.toLocaleString('en-US');
			celebration = 2;
			toys.say('IT HIT THE CORNER!!!');

			// Only Glitter cheers, not the cards of Solitaire, as the corner comes by itself, every 46 seconds, and the cards would cover the page while the visitor plays with another toy.
			toys.cheer();
		}
	};

	const draw = () => {
		context.fillStyle = '#000';
		context.fillRect(0, 0, canvas.width, canvas.height);

		if (celebration > 0) {
			context.fillStyle = colors[Math.floor(celebration * 8) % colors.length];
			context.font = 'bold 28px Impact, "Arial Black", sans-serif';
			context.textAlign = 'center';
			context.fillText('CORNER!!!', canvas.width / 2, canvas.height / 2);
		}

		const color = colors[colorIndex];
		context.fillStyle = color;
		context.textAlign = 'center';
		context.textBaseline = 'middle';
		context.font = 'bold 22px Impact, "Arial Black", sans-serif';
		context.fillText('SINDRE', logo.x + (logoWidth / 2), logo.y + 11);
		context.beginPath();
		context.ellipse(logo.x + (logoWidth / 2), logo.y + 26, logoWidth / 2, 6, 0, 0, Math.PI * 2);
		context.fill();
		context.fillStyle = '#000';
		context.font = 'bold 9px Arial, sans-serif';
		context.fillText('HOME PAGE', logo.x + (logoWidth / 2), logo.y + 26.5);
	};

	const run = delta => {
		ticks += delta * 80;
		celebration = Math.max(0, celebration - delta);

		while (ticks >= 1) {
			ticks--;
			move();
		}

		draw();
	};

	const animation = toys.animation(canvas, run);

	return {
		nudge() {
			// The new place is on a grid of 8 pixels, so the logo can still hit a corner.
			logo.x = clamp(Math.round((logo.x + ((Math.random() - 0.5) * 80)) / 8) * 8, 8, maximumX - 8);
			logo.y = clamp(Math.round((logo.y + ((Math.random() - 0.5) * 60)) / 8) * 8, 8, maximumY - 8);
			logo.dx = Math.random() < 0.5 ? -1 : 1;
			logo.dy = Math.random() < 0.5 ? -1 : 1;

			// Without motion, each nudge moves it a good way.
			if (!animation.isRunning) {
				run(1.5);
			}
		},
	};
};

export default class extends GeoCitiesElement {
	#animations = [];

	connected() {
		this.#animations = [];

		const actions = {
			lava: setUpLava(this, this.parts),
			kaleidoscope: setUpKaleidoscope(this, this.parts),
			fire: setUpFire(this, this.parts),
			plasma: setUpPlasma(this, this.parts),
			bump: setUpFlashlight(this, this.parts),
			fractal: setUpFractint(this, this.parts),
			voxel: setUpFjord(this, this.parts),
			shadebobs: setUpShadebobs(this, this.parts),
			disco: setUpDisco(this, this.parts),
			moire: setUpMoire(this, this.parts),
			cube: setUpCube(this, this.parts),
			bounce: setUpBounce(this, this.parts),
		};

		for (const button of this.querySelectorAll('[data-demo-action]')) {
			this.on(button, 'click', () => {
				const [id, action] = button.dataset.demoAction.split(':');
				actions[id]?.[action]?.(button);
			});
		}
	}

	reducedMotionChanged() {
		// The effects draw a still picture when motion stops.
		for (const animation of this.#animations) {
			animation.drawStill();
		}
	}

	// The animation of a toy (`animate()`), which the box tells when the motion changes.
	animation(canvas, step) {
		const animation = animate(this, canvas, step);
		this.#animations.push(animation);
		return animation;
	}
}
