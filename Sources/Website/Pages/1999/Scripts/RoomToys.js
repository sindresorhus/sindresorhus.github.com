// Three toys of my room on the 1999 page, each in a window: under the bed, the glow-in-the-dark stars on the ceiling, and the Magic Screen. Canvases run only while they are on the screen and the tab is visible. What the visitor makes is kept in the browser.
const randomItem = items => items[Math.floor(Math.random() * items.length)];
const randomInteger = (minimum, maximum) => minimum + Math.floor(Math.random() * (maximum - minimum + 1));
const clamp = (value, minimum, maximum) => Math.min(Math.max(value, minimum), maximum);
const plural = (count, word) => `${count.toLocaleString('en-US')} ${word}${count === 1 ? '' : 's'}`;

// The position of a pointer on a canvas, in the pixels of the canvas.
const canvasPoint = (canvas, event) => {
	const rectangle = canvas.getBoundingClientRect();
	return {
		x: (event.clientX - rectangle.left) * canvas.width / rectangle.width,
		y: (event.clientY - rectangle.top) * canvas.height / rectangle.height,
	};
};

// A tiny pixel font of 3 × 5 for the canvases, so the text is crisp at any size. Each letter is five rows of three bits.
const pixelFont = {
	A: [2, 5, 7, 5, 5], B: [6, 5, 6, 5, 6], C: [3, 4, 4, 4, 3], D: [6, 5, 5, 5, 6], E: [7, 4, 6, 4, 7], F: [7, 4, 6, 4, 4], G: [3, 4, 5, 5, 3], H: [5, 5, 7, 5, 5], I: [7, 2, 2, 2, 7], J: [1, 1, 1, 5, 2], K: [5, 5, 6, 5, 5], L: [4, 4, 4, 4, 7], M: [5, 7, 7, 5, 5], N: [6, 5, 5, 5, 5], O: [2, 5, 5, 5, 2], P: [6, 5, 6, 4, 4], Q: [2, 5, 5, 6, 3], R: [6, 5, 6, 5, 5], S: [3, 4, 2, 1, 6], T: [7, 2, 2, 2, 2], U: [5, 5, 5, 5, 7], V: [5, 5, 5, 5, 2], W: [5, 5, 7, 7, 5], X: [5, 5, 2, 5, 5], Y: [5, 5, 2, 2, 2], Z: [7, 1, 2, 4, 7],
	0: [7, 5, 5, 5, 7], 1: [2, 6, 2, 2, 7], 2: [6, 1, 2, 4, 7], 3: [6, 1, 2, 1, 6], 4: [5, 5, 7, 1, 1], 5: [7, 4, 6, 1, 6], 6: [3, 4, 7, 5, 7], 7: [7, 1, 2, 2, 2], 8: [7, 5, 7, 5, 7], 9: [7, 5, 7, 1, 6],
	' ': [0, 0, 0, 0, 0], '.': [0, 0, 0, 0, 2], ',': [0, 0, 0, 2, 4], '!': [2, 2, 2, 0, 2], '?': [6, 1, 2, 0, 2], ':': [0, 2, 0, 2, 0], '-': [0, 0, 7, 0, 0], '+': [0, 2, 7, 2, 0], '/': [1, 1, 2, 4, 4], '\'': [2, 2, 0, 0, 0], '(': [1, 2, 2, 2, 1], ')': [4, 2, 2, 2, 4], '×': [0, 5, 2, 5, 0], '°': [2, 5, 2, 0, 0], '%': [5, 1, 2, 4, 5], '<': [1, 2, 4, 2, 1], '>': [4, 2, 1, 2, 4], '=': [0, 7, 0, 7, 0], '♥': [0, 5, 7, 7, 2], '*': [0, 5, 2, 5, 0],
	Æ: [3, 6, 7, 6, 7], Ø: [3, 5, 7, 5, 6], Å: [2, 0, 2, 5, 7],
};

// Draws text in the pixel font, at a whole pixel, with a scale for bigger letters. The alignment is `left`, `center`, or `right`.
const drawPixelText = (context, text, x, y, color, {scale = 1, align = 'left'} = {}) => {
	const characters = [...String(text).toUpperCase()];
	const width = ((characters.length * 4) - 1) * scale;
	let left = Math.round(align === 'center' ? x - (width / 2) : (align === 'right' ? x - width : x));
	context.fillStyle = color;

	for (const character of characters) {
		const rows = pixelFont[character] ?? pixelFont['?'];
		for (const [row, bits] of rows.entries()) {
			for (let column = 0; column < 3; column++) {
				if (bits & (4 >> column)) {
					context.fillRect(left + (column * scale), Math.round(y) + (row * scale), scale, scale);
				}
			}
		}

		left += 4 * scale;
	}
};

// A canvas that is not on the page, for drawing in layers.
const makeCanvas = (width, height) => {
	const canvas = document.createElement('canvas');
	canvas.width = width;
	canvas.height = height;
	return canvas;
};

// Shapes for the canvases of the toys.
const fillShape = (context, color, x, y, width, height) => {
	context.fillStyle = color;
	context.fillRect(Math.round(x), Math.round(y), Math.round(width), Math.round(height));
};

const fillEllipse = (context, color, x, y, radiusX, radiusY) => {
	context.fillStyle = color;
	context.beginPath();
	context.ellipse(x, y, Math.max(radiusX, 0.1), Math.max(radiusY, 0.1), 0, 0, Math.PI * 2);
	context.fill();
};

const fillPolygon = (context, color, points) => {
	context.fillStyle = color;
	context.beginPath();
	for (const [x, y] of points) {
		context.lineTo(x, y);
	}

	context.closePath();
	context.fill();
};

const fillStar = (context, color, x, y, radius, points = 5) => {
	const corners = [];
	for (let index = 0; index < points * 2; index++) {
		const angle = (index * Math.PI / points) - (Math.PI / 2);
		const length = index % 2 === 0 ? radius : radius * 0.45;
		corners.push([x + (Math.cos(angle) * length), y + (Math.sin(angle) * length)]);
	}

	fillPolygon(context, color, corners);
};

// Under the bed: a flashlight that follows the pointer, or the arrow keys, looks for six lost things in the dark before Mom turns off the light. The batteries are almost dead, so the light gets dimmer and smaller, and banging the flashlight makes it bright again for a while, a little less each time. The light is described for screen readers: the status says when it shines on something.
const setUpUnderBed = (toys, {bedCanvas: canvas, bedList: list, bedStart: start, bedBang: bang, bedStatus: status}) => {
	const context = canvas.getContext('2d');
	const scene = makeCanvas(canvas.width, canvas.height);
	const sceneContext = scene.getContext('2d');
	const roundTime = 60;

	// The things that can be under the bed, each with how to draw it, at its middle, about 16 pixels wide.
	const things = [
		{name: 'the lost 1×1 LEGO brick', draw: (c, x, y) => {
			fillShape(c, '#c91a09', x - 3, y - 2, 6, 5);
			fillShape(c, '#e8352a', x - 2, y - 4, 4, 2);
		}},
		{name: 'my other sock', draw: (c, x, y) => {
			fillShape(c, '#ffffff', x - 4, y - 8, 7, 11);
			fillShape(c, '#ffffff', x - 4, y + 1, 12, 6);
			fillShape(c, '#cc2222', x - 4, y - 6, 7, 2);
			fillShape(c, '#2244cc', x - 4, y - 2, 7, 2);
		}},
		{name: 'the TV remote', draw: (c, x, y) => {
			fillShape(c, '#222222', x - 9, y - 3, 18, 7);
			fillShape(c, '#cc2222', x + 5, y - 1, 2, 2);
			for (let index = 0; index < 3; index++) {
				fillShape(c, '#888888', x - 6 + (index * 3), y - 1, 2, 2);
			}
		}},
		{name: 'a Kvikk Lunsj', draw: (c, x, y) => {
			fillShape(c, '#d0021b', x - 9, y - 4, 18, 8);
			fillShape(c, '#ffffff', x - 5, y - 1, 10, 2);
			fillShape(c, '#f2c84b', x - 9, y - 4, 2, 8);
		}},
		{name: 'my game cartridge', draw: (c, x, y) => {
			fillShape(c, '#8a8a92', x - 6, y - 7, 12, 14);
			fillShape(c, '#4a7a3a', x - 4, y - 5, 8, 6);
			fillShape(c, '#5a5a62', x - 6, y + 5, 12, 2);
		}},
		{name: 'my library book (3 weeks late)', draw: (c, x, y) => {
			fillShape(c, '#2a4aa8', x - 8, y - 6, 16, 12);
			fillShape(c, '#f4f0e0', x + 6, y - 5, 2, 10);
			fillShape(c, '#f2c84b', x - 5, y - 3, 9, 2);
		}},
		{name: 'a waffle from last week', draw: (c, x, y) => {
			fillEllipse(c, '#d9a441', x - 3, y - 2, 4, 4);
			fillEllipse(c, '#d9a441', x + 3, y - 2, 4, 4);
			fillPolygon(c, '#d9a441', [[x - 7, y - 1], [x + 7, y - 1], [x, y + 6]]);
			fillShape(c, '#a87420', x - 4, y - 3, 1, 1);
			fillShape(c, '#a87420', x + 2, y - 1, 1, 1);
		}},
		{name: 'my Tamagotchi (it died in March)', draw: (c, x, y) => {
			fillEllipse(c, '#ff88cc', x, y, 6, 7);
			fillShape(c, '#b8d0a0', x - 3, y - 3, 6, 5);
			fillShape(c, '#ffee55', x - 1, y + 4, 2, 2);
		}},
		{name: 'two AA batteries', draw: (c, x, y) => {
			for (const offset of [-4, 2]) {
				fillShape(c, '#222222', x + offset, y - 6, 4, 12);
				fillShape(c, '#d4a020', x + offset, y - 6, 4, 4);
				fillShape(c, '#cccccc', x + offset + 1, y - 7, 2, 1);
			}
		}},
		{name: 'a floppy disk', draw: (c, x, y) => {
			fillShape(c, '#1a1a1a', x - 7, y - 7, 14, 14);
			fillShape(c, '#b8b8c0', x - 4, y - 7, 8, 5);
			fillShape(c, '#ffffff', x - 5, y + 1, 10, 5);
		}},
		{name: 'Mom’s good scissors', draw: (c, x, y) => {
			fillPolygon(c, '#c0c0c8', [[x - 1, y - 9], [x + 1, y - 9], [x + 3, y + 2], [x - 3, y + 2]]);
			fillEllipse(c, '#e04848', x - 3, y + 5, 3, 3);
			fillEllipse(c, '#e04848', x + 3, y + 5, 3, 3);
		}},
		{name: 'my Pog collection slammer', draw: (c, x, y) => {
			fillEllipse(c, '#555566', x, y, 7, 4);
			fillEllipse(c, '#9aa0b0', x, y - 1, 5, 3);
			fillStar(c, '#ffd700', x, y - 1, 2);
		}},
	];

	const state = {
		isPlaying: false,
		items: [],
		lightX: 160,
		lightY: 100,
		charge: 1,
		maximumCharge: 1,
		timeLeft: roundTime,
		lastInLight: undefined,
		eyes: {x: 280, y: 60},
		best: Math.max(0, Math.round(Number(toys.stored('bed-best', 0)) || 0)),
	};

	const say = text => {
		toys.say(text, status);
	};

	// The dark space under the bed: the floor boards, the slats of the bed, dust bunnies, and the legs of the bed.
	const drawScene = () => {
		const gradient = sceneContext.createLinearGradient(0, 0, 0, canvas.height);
		gradient.addColorStop(0, '#4a3624');
		gradient.addColorStop(1, '#8a6440');
		sceneContext.fillStyle = gradient;
		sceneContext.fillRect(0, 0, canvas.width, canvas.height);
		for (let y = 30; y < canvas.height; y += 14 + (y / 12)) {
			fillShape(sceneContext, '#3a2818', 0, y, canvas.width, 1);
		}

		fillShape(sceneContext, '#2a1c10', 0, 0, canvas.width, 18);
		for (let x = 6; x < canvas.width; x += 34) {
			fillShape(sceneContext, '#5a3e22', x, 0, 22, 12);
		}

		fillShape(sceneContext, '#3a2614', 4, 0, 10, canvas.height);
		fillShape(sceneContext, '#3a2614', canvas.width - 14, 0, 10, canvas.height);
		for (let index = 0; index < 16; index++) {
			const x = 20 + ((index * 97) % 280);
			const y = 30 + ((index * 53) % 140);
			fillEllipse(sceneContext, '#9a9088', x, y, 5 + (index % 3), 3 + (index % 2));
			fillEllipse(sceneContext, '#b8aea4', x - 1, y - 1, 3, 2);
		}

		for (const item of state.items) {
			if (!item.isFound) {
				item.draw(sceneContext, item.x, item.y);
			}
		}
	};

	const radius = () => 12 + (34 * state.charge);

	const isInLight = item => Math.hypot(item.x - state.lightX, item.y - state.lightY) < radius() - 3;

	// The flashlight: the scene inside the circle of light, which is brighter in the middle, and the dark around it. Two eyes glow in the dark now and then, and are gone when the light finds them.
	const draw = time => {
		fillShape(context, '#050302', 0, 0, canvas.width, canvas.height);
		if (state.isPlaying || state.items.length > 0) {
			context.save();
			context.beginPath();
			context.arc(state.lightX, state.lightY, radius(), 0, Math.PI * 2);
			context.clip();
			context.drawImage(scene, 0, 0);
			const light = context.createRadialGradient(state.lightX, state.lightY, radius() * 0.2, state.lightX, state.lightY, radius());
			light.addColorStop(0, 'rgba(255, 240, 180, 0.15)');
			light.addColorStop(0.7, `rgba(5, 3, 2, ${0.55 - (state.charge * 0.35)})`);
			light.addColorStop(1, 'rgba(5, 3, 2, 0.95)');
			context.fillStyle = light;
			context.fillRect(0, 0, canvas.width, canvas.height);
			context.restore();
		}

		const eyesVisible = state.isPlaying && !toys.reducedMotion && Math.hypot(state.eyes.x - state.lightX, state.eyes.y - state.lightY) > radius() + 8 && Math.floor(time / 1700) % 3 !== 0;
		if (eyesVisible) {
			fillEllipse(context, '#ffee55', state.eyes.x - 5, state.eyes.y, 2.5, time % 3000 < 150 ? 0.5 : 2);
			fillEllipse(context, '#ffee55', state.eyes.x + 5, state.eyes.y, 2.5, time % 3000 < 150 ? 0.5 : 2);
		}

		if (state.isPlaying) {
			drawPixelText(context, `${Math.ceil(state.timeLeft)}`, canvas.width - 6, 5, state.timeLeft < 10 ? '#ff4444' : '#cccccc', {align: 'right', scale: 2});
			fillShape(context, '#333333', 6, 6, 32, 6);
			fillShape(context, state.charge > 0.3 ? '#44dd44' : '#dd4444', 7, 7, 30 * state.charge, 4);
		} else if (state.items.length === 0) {
			drawPixelText(context, 'IT IS DARK UNDER MY BED', 160, 84, '#665544', {align: 'center', scale: 2});
		}
	};

	const showList = () => {
		list.replaceChildren(...state.items.map(item => {
			const entry = document.createElement('li');
			entry.textContent = `${item.isFound ? '✅' : '⬜'} ${item.name}`;
			return entry;
		}));
	};

	const end = hasWon => {
		state.isPlaying = false;
		bang.disabled = true;
		start.textContent = 'Look Again';
		const found = state.items.filter(item => item.isFound).length;
		if (hasWon) {
			const seconds = Math.round(roundTime - state.timeLeft);
			const isBest = state.best === 0 || seconds < state.best;
			if (isBest) {
				state.best = seconds;
				toys.store('bed-best', seconds);
			}

			toys.celebrate();
			say(`Found everything in ${plural(seconds, 'second')}${isBest ? ', a new record' : ` (record: ${state.best})`}! Mom says I can stay up for five more minutes.`);
		} else {
			say(`Mom turned off the light! You found ${found} of ${state.items.length}. The rest stay under the bed until next year.`);
		}

		draw(performance.now());
		start.focus();
	};

	const step = seconds => {
		if (!state.isPlaying) {
			return;
		}

		state.timeLeft -= seconds;
		// The batteries run down in about 20 seconds, so the visitor has to bang the flashlight.
		state.charge = Math.max(0, state.charge - (seconds / 20));
		if (state.timeLeft <= 0) {
			state.timeLeft = 0;
			end(false);
			return;
		}

		draw(performance.now());
	};

	// The window is watched, not only the canvas, so the clock of Mom goes on while the list below the canvas is in view.
	const loop = toys.loop(step, {while: () => state.isPlaying, target: canvas.closest('section')});

	const describeLight = () => {
		const item = state.items.find(item => !item.isFound && isInLight(item));
		if (item !== state.lastInLight) {
			state.lastInLight = item;
			if (item) {
				say('The flashlight shines on something! Click it, or press Enter.');
			}
		}
	};

	const moveLight = (x, y) => {
		state.lightX = clamp(x, 0, canvas.width);
		state.lightY = clamp(y, 0, canvas.height);
		if (state.isPlaying) {
			describeLight();
			draw(performance.now());
		}
	};

	const pickUp = (x, y) => {
		if (!state.isPlaying) {
			return;
		}

		const item = state.items.find(item => !item.isFound && isInLight(item) && Math.hypot(item.x - x, item.y - y) < 14);
		if (!item) {
			say(Math.hypot(state.eyes.x - x, state.eyes.y - y) < 20 ? 'Eek! Something was there. We do not have a cat.' : randomItem(['Just a dust bunny.', 'Dust. So much dust.', 'Nothing there. Keep looking!']));
			return;
		}

		item.isFound = true;
		state.lastInLight = undefined;
		drawScene();
		showList();
		const left = state.items.filter(item => !item.isFound).length;
		if (left === 0) {
			end(true);
		} else {
			say(`Found ${item.name}! ${left} to go.`);
			draw(performance.now());
		}
	};

	toys.on(start, 'click', () => {
		const chosen = [...things].sort(() => Math.random() - 0.5).slice(0, 6);
		const items = [];
		for (const thing of chosen) {
			// Each thing gets a place of its own, away from the edges and the other things.
			let x;
			let y;
			let tries = 0;
			do {
				x = randomInteger(28, canvas.width - 28);
				y = randomInteger(32, canvas.height - 16);
				tries++;
			} while (tries < 50 && items.some(item => Math.hypot(item.x - x, item.y - y) < 34));
			items.push({...thing, x, y, isFound: false});
		}

		Object.assign(state, {isPlaying: true, items, charge: 1, maximumCharge: 1, timeLeft: roundTime, lastInLight: undefined});
		state.eyes = {x: randomInteger(40, 280), y: randomInteger(40, 150)};
		drawScene();
		showList();
		bang.disabled = false;
		start.textContent = 'Start Over';
		say('Mom: “Lights out in one minute!” Move the flashlight over the floor.');
		canvas.focus();
		loop.start();
		draw(performance.now());
	});

	toys.on(bang, 'click', () => {
		if (!state.isPlaying) {
			return;
		}

		// Each bang helps a little less, as the batteries are dying.
		state.maximumCharge = Math.max(0.25, state.maximumCharge * 0.85);
		state.charge = state.maximumCharge;
		say(state.maximumCharge > 0.5 ? 'Bang! The light is bright again.' : 'Bang! It helps a little. The batteries are almost gone.');
		draw(performance.now());
	});

	toys.on(canvas, 'pointermove', event => {
		const point = canvasPoint(canvas, event);
		moveLight(point.x, point.y);
	});

	toys.on(canvas, 'pointerdown', event => {
		const point = canvasPoint(canvas, event);
		moveLight(point.x, point.y);
		pickUp(point.x, point.y);
	});

	toys.on(canvas, 'keydown', event => {
		const moves = {ArrowLeft: [-8, 0], ArrowRight: [8, 0], ArrowUp: [0, -8], ArrowDown: [0, 8]};
		if (moves[event.key]) {
			event.preventDefault();
			const [x, y] = moves[event.key];
			moveLight(state.lightX + x, state.lightY + y);
		} else if (event.key === 'Enter' || event.key === ' ') {
			event.preventDefault();
			if (state.isPlaying) {
				// The keyboard picks up the thing nearest the middle of the light.
				const item = state.items.filter(item => !item.isFound && isInLight(item)).sort((first, second) => Math.hypot(first.x - state.lightX, first.y - state.lightY) - Math.hypot(second.x - state.lightX, second.y - state.lightY))[0];
				pickUp(item?.x ?? state.lightX, item?.y ?? state.lightY);
			} else {
				start.click();
			}
		} else if (event.key === 'b' && state.isPlaying) {
			bang.click();
		}
	});

	draw(0);
};

// The glow-in-the-dark stars on the ceiling over the bunk bed. With the light on, a click sticks a star on the ceiling, or peels one off, and the stars soak up the light. With the light off, they glow, and fade as they lose their charge, and a click on a star joins it to the last one, for a constellation of my own. The stars, the lines, and the name are kept in the browser.
const setUpCeiling = (toys, {ceilingCanvas: canvas, ceilingLight: light, ceilingClear: clear, ceilingName: name, ceilingStatus: status}) => {
	const context = canvas.getContext('2d');
	const maximumStars = 40;

	const stored = toys.stored('ceiling', {});
	const stars = (Array.isArray(stored.stars) ? stored.stars : [])
		.filter(star => Number.isFinite(star?.x) && Number.isFinite(star?.y))
		.slice(0, maximumStars)
		.map(star => ({x: clamp(star.x, 0, canvas.width), y: clamp(star.y, 0, canvas.height), size: clamp(Number(star.size) || 4, 3, 7), charge: 1}));
	const lines = (Array.isArray(stored.lines) ? stored.lines : []).filter(line => Array.isArray(line) && stars[line[0]] && stars[line[1]]);
	name.value = typeof stored.name === 'string' ? stored.name.slice(0, 30) : '';

	const state = {
		isLightOn: true,
		selected: undefined,
		cursor: {x: 160, y: 100},
		showsCursor: false,
	};

	const say = text => {
		toys.say(text, status);
	};

	const saveAll = () => {
		toys.store('ceiling', {stars: stars.map(({x, y, size}) => ({x, y, size})), lines, name: name.value.trim()});
	};

	const starAt = (x, y) => stars.findIndex(star => Math.hypot(star.x - x, star.y - y) < star.size + 4);

	const draw = () => {
		if (state.isLightOn) {
			fillShape(context, '#ece8dc', 0, 0, canvas.width, canvas.height);
			// The ceiling lamp, and the top of the bunk bed in the corner.
			fillEllipse(context, '#f8f4e0', 160, 100, 22, 22);
			fillEllipse(context, '#fffbe8', 160, 100, 15, 15);
			fillShape(context, '#8b5a2b', 0, canvas.height - 10, canvas.width, 10);
			for (const star of stars) {
				fillStar(context, `rgb(${236 - (star.charge * 10)}, ${238}, ${200 - (star.charge * 30)})`, star.x, star.y, star.size);
			}
		} else {
			fillShape(context, '#0a0e22', 0, 0, canvas.width, canvas.height);
			fillShape(context, '#05070f', 0, canvas.height - 10, canvas.width, 10);
			context.strokeStyle = 'rgba(160, 255, 140, 0.35)';
			context.lineWidth = 1;
			for (const [first, second] of lines) {
				context.beginPath();
				context.moveTo(stars[first].x, stars[first].y);
				context.lineTo(stars[second].x, stars[second].y);
				context.stroke();
			}

			for (const [index, star] of stars.entries()) {
				const glow = context.createRadialGradient(star.x, star.y, 0, star.x, star.y, star.size * 3.5);
				glow.addColorStop(0, `rgba(170, 255, 140, ${0.6 * star.charge})`);
				glow.addColorStop(1, 'rgba(170, 255, 140, 0)');
				context.fillStyle = glow;
				context.fillRect(star.x - (star.size * 4), star.y - (star.size * 4), star.size * 8, star.size * 8);
				fillStar(context, `rgba(210, 255, 180, ${0.08 + (star.charge * 0.92)})`, star.x, star.y, star.size);
				if (index === state.selected) {
					context.strokeStyle = '#ffffff';
					context.beginPath();
					context.arc(star.x, star.y, star.size + 3, 0, Math.PI * 2);
					context.stroke();
				}
			}

			if (name.value.trim() && lines.length > 0) {
				drawPixelText(context, name.value.trim(), 160, canvas.height - 22, 'rgba(160, 255, 140, 0.6)', {align: 'center'});
			}
		}

		if (state.showsCursor) {
			context.strokeStyle = state.isLightOn ? '#000080' : '#ffffff';
			context.lineWidth = 1;
			context.strokeRect(state.cursor.x - 6, state.cursor.y - 6, 12, 12);
		}
	};

	// The stars charge in the light in a few seconds, and lose their glow in the dark in about a minute, like real glow stars, only faster.
	const step = seconds => {
		for (const star of stars) {
			star.charge = state.isLightOn ? Math.min(1, star.charge + (seconds / 3)) : star.charge * Math.exp(-seconds / 25);
		}

		draw();
		if (!state.isLightOn && stars.length > 0 && stars.every(star => star.charge < 0.03)) {
			say('The stars ran out of glow. Turn on the light to charge them again.');
		}
	};

	const isChanging = () => stars.some(star => (state.isLightOn ? star.charge < 1 : star.charge > 0.03));
	const loop = toys.loop(step, {while: isChanging, target: canvas});

	const act = (x, y) => {
		const index = starAt(x, y);
		if (state.isLightOn) {
			if (index === -1) {
				if (stars.length >= maximumStars) {
					say('The pack of stars is empty. That was all 40.');
					return;
				}

				stars.push({x, y, size: randomInteger(3, 6), charge: 0});
				say(`Stuck on a star. ${plural(stars.length, 'star')} on my ceiling.`);
			} else {
				stars.splice(index, 1);
				// The lines of the star go too, and the lines after it point to the stars that moved down.
				for (let lineIndex = lines.length - 1; lineIndex >= 0; lineIndex--) {
					if (lines[lineIndex].includes(index)) {
						lines.splice(lineIndex, 1);
					} else {
						lines[lineIndex] = lines[lineIndex].map(starIndex => (starIndex > index ? starIndex - 1 : starIndex));
					}
				}

				say('Peeled off a star. The glue stays on the ceiling forever.');
			}

			saveAll();
			loop.start();
		} else if (index === -1) {
			state.selected = undefined;
			say('Click a glowing star to start a constellation.');
		} else if (state.selected === undefined || state.selected === index) {
			state.selected = index;
			say('Now click another star to join them.');
		} else {
			const exists = lines.some(([first, second]) => (first === state.selected && second === index) || (first === index && second === state.selected));
			if (!exists) {
				lines.push([state.selected, index]);
			}

			state.selected = index;
			saveAll();
			say(lines.length >= 6 ? `What a constellation! ${name.value.trim() ? `“${name.value.trim()}” shines over my bed.` : 'Give it a name below.'}` : 'Joined! Click another star to go on.');
		}

		draw();
	};

	// A click, not a press, so a finger that scrolls the page over the ceiling does not stick on a star.
	toys.on(canvas, 'click', event => {
		state.showsCursor = false;
		const point = canvasPoint(canvas, event);
		act(point.x, point.y);
	});

	toys.on(canvas, 'keydown', event => {
		const moves = {ArrowLeft: [-6, 0], ArrowRight: [6, 0], ArrowUp: [0, -6], ArrowDown: [0, 6]};
		if (moves[event.key]) {
			event.preventDefault();
			const [x, y] = moves[event.key];
			state.cursor = {x: clamp(state.cursor.x + x, 6, canvas.width - 6), y: clamp(state.cursor.y + y, 6, canvas.height - 16)};
			state.showsCursor = true;
			draw();
		} else if (event.key === 'Enter' || event.key === ' ') {
			event.preventDefault();
			state.showsCursor = true;
			// In the dark, Enter picks the star nearest the cursor, as the stars are hard to hit exactly.
			const nearest = stars.map((star, index) => ({index, distance: Math.hypot(star.x - state.cursor.x, star.y - state.cursor.y)})).sort((first, second) => first.distance - second.distance)[0];
			if (!state.isLightOn && nearest && nearest.distance < 30) {
				act(stars[nearest.index].x, stars[nearest.index].y);
			} else {
				act(state.cursor.x, state.cursor.y);
			}
		}
	});

	toys.on(canvas, 'blur', () => {
		state.showsCursor = false;
		draw();
	});

	toys.on(light, 'click', () => {
		state.isLightOn = !state.isLightOn;
		state.selected = undefined;
		light.textContent = state.isLightOn ? 'Turn Off the Light' : 'Turn On the Light';
		if (stars.length === 0) {
			say(state.isLightOn ? 'The light is on.' : 'It is dark, and there are no stars yet. Stick some on with the light on!');
		} else {
			say(state.isLightOn ? 'The light is on. The stars soak up the light.' : `Lights out! ${plural(stars.length, 'star')} glow over my bed.`);
		}

		loop.start();
		draw();
	});

	toys.on(clear, 'click', () => {
		stars.length = 0;
		lines.length = 0;
		state.selected = undefined;
		saveAll();
		say('Peeled them all off. Mom is happy. The ceiling has 40 little glue spots now.');
		draw();
	});

	toys.on(name, 'input', () => {
		saveAll();
		draw();
	});

	draw();
};

// The Magic Screen: one line, drawn with two knobs, the left one sideways and the right one up and down, so a circle takes practice. A knob turns when the pointer goes around it, like a real knob, or with the arrow keys. Shaking it erases a part of the drawing each time.
const setUpSketch = (toys, {sketchCanvas: canvas, sketchShake: shakeButton, sketchStatus: status}) => {
	const context = canvas.getContext('2d');
	const screen = {x: 30, y: 22, width: 220, height: 146};
	const knobs = {left: {x: 44, y: 194, angle: 0}, right: {x: 236, y: 194, angle: 0}};
	const drawing = makeCanvas(screen.width, screen.height);
	const drawingContext = drawing.getContext('2d');
	const screenColor = '#c8ccc8';

	const state = {
		x: screen.width / 2,
		y: screen.height / 2,
		drag: undefined,
		jiggle: 0,
		distance: 0,
	};

	const say = text => {
		toys.say(text, status);
	};

	const clearDrawing = () => {
		drawingContext.fillStyle = screenColor;
		drawingContext.fillRect(0, 0, screen.width, screen.height);
	};

	const draw = () => {
		context.clearRect(0, 0, canvas.width, canvas.height);
		const offset = toys.reducedMotion ? 0 : Math.sin(state.jiggle * 40) * state.jiggle * 6;
		context.save();
		context.translate(offset, 0);
		context.fillStyle = '#c8102e';
		context.beginPath();
		context.roundRect(4, 4, canvas.width - 8, canvas.height - 8, 22);
		context.fill();
		fillShape(context, '#8a0a20', screen.x - 4, screen.y - 4, screen.width + 8, screen.height + 8);
		context.drawImage(drawing, screen.x, screen.y);
		// The stylus, a dot where the line is.
		fillShape(context, '#222222', screen.x + state.x - 1, screen.y + state.y - 1, 2, 2);
		drawPixelText(context, 'MAGIC SCREEN', canvas.width / 2, 186, '#ffd84a', {align: 'center', scale: 2});
		for (const knob of Object.values(knobs)) {
			fillEllipse(context, '#f4f4f4', knob.x, knob.y, 18, 18);
			fillEllipse(context, '#d8d8d8', knob.x, knob.y, 12, 12);
			for (let index = 0; index < 8; index++) {
				const angle = knob.angle + (index * Math.PI / 4);
				fillShape(context, '#aaaaaa', knob.x + (Math.cos(angle) * 15) - 1, knob.y + (Math.sin(angle) * 15) - 1, 2, 2);
			}
		}

		context.restore();
	};

	// Moves the stylus, and draws the line behind it.
	const move = (dx, dy) => {
		const x = clamp(state.x + dx, 1, screen.width - 1);
		const y = clamp(state.y + dy, 1, screen.height - 1);
		drawingContext.strokeStyle = '#3a3a3a';
		drawingContext.lineWidth = 1.2;
		drawingContext.lineCap = 'round';
		drawingContext.beginPath();
		drawingContext.moveTo(state.x, state.y);
		drawingContext.lineTo(x, y);
		drawingContext.stroke();
		state.distance += Math.hypot(x - state.x, y - state.y);
		state.x = x;
		state.y = y;
		draw();
	};

	// A shake: the powder covers part of the line again. Three or four shakes erase it all.
	const shake = () => {
		drawingContext.fillStyle = 'rgba(200, 204, 200, 0.45)';
		drawingContext.fillRect(0, 0, screen.width, screen.height);
		state.jiggle = 1;
		if (state.distance > 0) {
			say(randomItem(['Shake, shake! The drawing fades.', 'Shake! Some of it is still there.', 'Shake shake shake! Almost gone.']));
		}

		state.distance = 0;
		jiggleLoop.start();
		draw();
	};

	// When reduced motion turns on while it jiggles, it draws once more, still.
	const jiggleLoop = toys.loop(seconds => {
		state.jiggle = Math.max(0, state.jiggle - (seconds * 3));
		draw();
	}, {while: () => state.jiggle > 0 && !toys.reducedMotion, target: canvas, stopped: draw});

	toys.on(canvas, 'pointerdown', event => {
		if (event.button !== 0) {
			return;
		}

		const point = canvasPoint(canvas, event);
		const knob = Object.entries(knobs).find(([, knob]) => Math.hypot(point.x - knob.x, point.y - knob.y) < 34);
		canvas.setPointerCapture(event.pointerId);
		if (knob) {
			state.drag = {knob: knob[0], angle: Math.atan2(point.y - knob[1].y, point.x - knob[1].x)};
		} else {
			// Dragging the toy itself around fast shakes it, like the real one.
			state.drag = {isShaking: true, x: event.clientX, distance: 0};
		}
	});

	toys.on(canvas, 'pointermove', event => {
		if (!state.drag) {
			return;
		}

		if (state.drag.isShaking) {
			state.drag.distance += Math.abs(event.clientX - state.drag.x);
			state.drag.x = event.clientX;
			if (state.drag.distance > 160) {
				state.drag.distance = 0;
				shake();
			}

			return;
		}

		const point = canvasPoint(canvas, event);
		const knob = knobs[state.drag.knob];
		const angle = Math.atan2(point.y - knob.y, point.x - knob.x);
		const delta = (((angle - state.drag.angle + Math.PI) % (Math.PI * 2)) + (Math.PI * 2)) % (Math.PI * 2) - Math.PI;
		state.drag.angle = angle;
		knob.angle += delta;
		// Clockwise turns the left knob to the right, and the right knob up, like the real toy.
		if (state.drag.knob === 'left') {
			move(delta * 14, 0);
		} else {
			move(0, -delta * 14);
		}
	});

	const endDrag = () => {
		state.drag = undefined;
	};

	toys.on(canvas, 'pointerup', endDrag);
	toys.on(canvas, 'pointercancel', endDrag);
	toys.on(canvas, 'lostpointercapture', endDrag);

	toys.on(canvas, 'keydown', event => {
		const moves = {ArrowLeft: [-2, 0, 'left'], ArrowRight: [2, 0, 'left'], ArrowUp: [0, -2, 'right'], ArrowDown: [0, 2, 'right']};
		const entry = moves[event.key];
		if (!entry) {
			return;
		}

		event.preventDefault();
		const [dx, dy, knob] = entry;
		knobs[knob].angle += (dx + dy) / 6;
		move(dx, dy);
	});

	toys.on(shakeButton, 'click', shake);

	clearDrawing();
	draw();
};

export default class extends GeoCitiesElement {
	connected() {
		setUpUnderBed(this, this.parts);
		setUpCeiling(this, this.parts);
		setUpSketch(this, this.parts);
	}
}
