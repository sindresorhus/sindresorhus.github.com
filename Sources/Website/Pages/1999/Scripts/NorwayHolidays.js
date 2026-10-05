// The best week of the year in Norway on the 1999 page, as a game: the Easter ski trip. The canvas runs only while it is on the screen and the tab is visible.
const randomItem = items => items[Math.floor(Math.random() * items.length)];
const randomInteger = (minimum, maximum) => minimum + Math.floor(Math.random() * (maximum - minimum + 1));
const clamp = (value, minimum, maximum) => Math.min(Math.max(value, minimum), maximum);
const plural = (count, word) => `${count.toLocaleString('en-US')} ${word}${count === 1 ? '' : 's'}`;

const nextFrame = () => new Promise(resolve => {
	requestAnimationFrame(() => {
		resolve();
	});
});

// Shows a toggle button as pressed, for screen readers and for the style.
const setPressed = (button, isPressed) => {
	button.setAttribute('aria-pressed', String(isPressed));
	button.dataset.state = isPressed ? 'on' : '';
};

// A tiny pixel font of 3 × 5 for the canvas, so the text is crisp at any size. Each letter is five rows of three bits.
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

// Shapes for the canvas of the game.
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

// The Easter ski trip. The weather of the day says which grip wax holds: a wax for colder snow than today slips back on the hills, and a wax for warmer snow makes snow stick under the skis. Then the kid kicks and glides to the cabin, with the left and the right ski one after the other, in a steady rhythm, against Dad, who skis at a steady speed. Kicking too fast makes the kid fall, and the energy runs out without a Kvikk Lunsj, which has a rule of the mountain code on the back. It runs only while it is on the screen and the tab is visible.
const setUpSki = (holidays, {skiCanvas: canvas, skiWeather: weather, skiStart: start, skiStatus: status, skiWrapper: wrapper}) => {
	const context = canvas.getContext('2d');
	const trackLength = 300;

	// The rules of the mountain code of 1967 to 2016, as they were on the back of every Kvikk Lunsj, with a word from me.
	const mountainCode = [
		['Legg ikke ut på langtur uten trening.', 'Do not go on a long trip without training. I trained on my handheld game console.'],
		['Meld fra hvor du går.', 'Tell someone where you go. I told Glitter.'],
		['Vis respekt for været og værmeldingene.', 'Respect the weather and the forecasts. In Bergen, the forecast is always rain.'],
		['Vær rustet mot uvær og kulde selv på korte turer.', 'Be ready for bad weather and cold, even on short trips. I have a Kvikk Lunsj.'],
		['Lytt til erfarne fjellfolk.', 'Listen to experienced mountain people. That is Dad. He is ahead.'],
		['Bruk kart og kompass.', 'Use a map and a compass. The compass points to the cabin with the waffles.'],
		['Gå ikke alene.', 'Do not go alone. Dad is here, somewhere in front of me.'],
		['Vend i tide, det er ingen skam å snu.', 'Turn back in time, there is no shame in turning back. But there are waffles at the cabin.'],
		['Spar på kreftene og grav deg inn i snøen om nødvendig.', 'Save your strength, and dig into the snow if you must. Or eat another Kvikk Lunsj.'],
	];

	// The grip waxes, with the temperatures of new snow they hold in. Klister is for wet snow above 0.
	const waxes = {
		green: {minimum: -15, maximum: -8},
		blue: {minimum: -10, maximum: -2},
		violet: {minimum: -3, maximum: 0},
		red: {minimum: 0, maximum: 3},
		klister: {minimum: 0.5, maximum: 6},
	};

	const days = [
		{temperature: -12, text: 'Cold and clear. New powder snow.'},
		{temperature: -7, text: 'Sunny, with a little frost. New snow.'},
		{temperature: -4, text: 'Overcast. A few centimeters of new snow.'},
		{temperature: -1, text: 'Grey, just below zero. New snow.'},
		{temperature: 2, text: 'Easter sun! Wet snow, melting.'},
	];

	// The track: hills up and down, as a height for each meter, with the cabin at the end.
	const heightAt = distance => (Math.sin(distance / 37) * 14) + (Math.sin(distance / 13 + 1) * 5) + (Math.sin(distance / 71) * 18);
	const slopeAt = distance => heightAt(distance + 1) - heightAt(distance);

	const state = {
		isPlaying: false,
		day: randomItem(days),
		wax: undefined,
		distance: 0,
		speed: 0,
		dadDistance: 0,
		energy: 100,
		bars: 3,
		lastKick: undefined,
		lastSide: undefined,
		fallenUntil: 0,
		time: 0,
		kickPose: 0,
		ruleIndex: randomInteger(0, mountainCode.length - 1),
		best: Math.max(0, Number(holidays.stored('ski-best', 0)) || 0),
	};

	// How the wax suits the day: right, too hard (it slips), or too soft (snow sticks).
	const fit = () => {
		const wax = waxes[state.wax];
		if (!wax) {
			return 'none';
		}

		if (state.day.temperature > wax.maximum) {
			return 'hard';
		}

		if (state.day.temperature < wax.minimum) {
			return 'soft';
		}

		return 'right';
	};

	const showWeather = () => {
		weather.textContent = `Påskeaften: ${state.day.temperature > 0 ? '+' : ''}${state.day.temperature} °C. ${state.day.text}`;
	};

	const draw = () => {
		const cameraDistance = state.distance - 12;
		const pixelsPerMeter = 6;
		const sky = context.createLinearGradient(0, 0, 0, canvas.height);
		sky.addColorStop(0, state.day.temperature > 0 ? '#7ec8ff' : '#a8c8e8');
		sky.addColorStop(1, '#eef4fa');
		context.fillStyle = sky;
		context.fillRect(0, 0, canvas.width, canvas.height);
		// The mountains far away, which move slowly.
		context.fillStyle = '#d8e4f0';
		context.beginPath();
		context.moveTo(0, 90);
		for (let x = 0; x <= canvas.width; x += 10) {
			context.lineTo(x, 60 + (Math.sin((x + (cameraDistance * 1.5)) / 50) * 16));
		}

		context.lineTo(canvas.width, canvas.height);
		context.lineTo(0, canvas.height);
		context.fill();
		const screenY = distance => 110 - heightAt(distance);
		// The snow and the tracks of the skis.
		context.fillStyle = '#ffffff';
		context.beginPath();
		context.moveTo(0, canvas.height);
		for (let x = 0; x <= canvas.width; x += 4) {
			context.lineTo(x, screenY(cameraDistance + (x / pixelsPerMeter)));
		}

		context.lineTo(canvas.width, canvas.height);
		context.fill();
		context.strokeStyle = '#b8c8dc';
		context.lineWidth = 1;
		for (const offset of [3, 6]) {
			context.beginPath();
			for (let x = 0; x <= canvas.width; x += 4) {
				context.lineTo(x, screenY(cameraDistance + (x / pixelsPerMeter)) + offset);
			}

			context.stroke();
		}

		// Trees and markers along the track, and the cabin at the end, with the flag.
		for (let meter = Math.floor(cameraDistance / 10) * 10; meter < cameraDistance + (canvas.width / pixelsPerMeter); meter += 10) {
			const x = (meter - cameraDistance) * pixelsPerMeter;
			if (meter % 30 === 0 && meter > 0 && meter < trackLength) {
				fillPolygon(context, '#2d5a3a', [[x, screenY(meter) - 30], [x + 9, screenY(meter) - 4], [x - 9, screenY(meter) - 4]]);
				fillShape(context, '#5a3a20', x - 1, screenY(meter) - 4, 2, 4);
			}

			if (meter % 100 === 0) {
				drawPixelText(context, `${trackLength - meter} M`, x, screenY(meter) - 44, '#5a6a7a', {align: 'center'});
			}
		}

		const cabinX = (trackLength - cameraDistance) * pixelsPerMeter;
		if (cabinX < canvas.width + 40) {
			const ground = screenY(trackLength);
			fillShape(context, '#8a3a2a', cabinX, ground - 26, 40, 26);
			fillPolygon(context, '#4a2a1a', [[cabinX - 4, ground - 26], [cabinX + 20, ground - 42], [cabinX + 44, ground - 26]]);
			fillShape(context, '#ffd86a', cabinX + 8, ground - 18, 7, 7);
			fillShape(context, '#3a2a1a', cabinX + 24, ground - 16, 8, 16);
			fillShape(context, '#ffffff', cabinX + 48, ground - 46, 1, 46);
			fillShape(context, '#ba0c2f', cabinX + 49, ground - 46, 12, 8);
			fillShape(context, '#ffffff', cabinX + 52, ground - 46, 3, 8);
			fillShape(context, '#ffffff', cabinX + 49, ground - 43, 12, 2);
			fillShape(context, '#00205b', cabinX + 53, ground - 46, 1, 8);
			fillShape(context, '#00205b', cabinX + 49, ground - 43, 12, 1);
		}

		// A skier: the body, the skis along the slope, and the poles, which swing with the kicks.
		const drawSkier = (distance, color, hat, pose, isFallen) => {
			const x = (distance - cameraDistance) * pixelsPerMeter;
			const y = screenY(distance);
			const angle = Math.atan2(heightAt(distance + 1) - heightAt(distance - 1), 2 / pixelsPerMeter) * -0.15;
			context.save();
			context.translate(x, y);
			context.rotate(isFallen ? -1.3 : angle);
			fillShape(context, '#2a2a2a', -10, 2, 22, 2);
			const swing = Math.sin(pose) * 4;
			fillShape(context, '#2a3a6a', -2 + swing, -8, 3, 10);
			fillShape(context, '#2a3a6a', 1 - swing, -8, 3, 10);
			fillShape(context, color, -4, -18, 9, 11);
			fillEllipse(context, '#f3c9a0', 1, -22, 4, 4);
			fillShape(context, hat, -3, -27, 8, 3);
			context.strokeStyle = '#555555';
			context.lineWidth = 1;
			context.beginPath();
			context.moveTo(3, -14);
			context.lineTo(8 - swing, 2);
			context.moveTo(-2, -14);
			context.lineTo(-7 + swing, 2);
			context.stroke();
			context.restore();
		};

		drawSkier(state.dadDistance, '#d42a2a', '#222222', state.time * 6, false);
		drawSkier(state.distance, '#1aa3b8', '#ffd21f', state.kickPose, state.time < state.fallenUntil);
		// The energy, the Kvikk Lunsj left, and the time.
		fillShape(context, 'rgba(255, 255, 255, 0.8)', 4, 4, 112, 22);
		drawPixelText(context, 'ENERGY', 8, 8, '#222222');
		fillShape(context, '#cccccc', 36, 8, 60, 5);
		fillShape(context, state.energy > 30 ? '#33aa33' : '#dd3333', 36, 8, 60 * state.energy / 100, 5);
		for (let index = 0; index < state.bars; index++) {
			fillShape(context, '#d0021b', 8 + (index * 12), 16, 10, 6);
		}

		drawPixelText(context, `${state.time.toFixed(1)} S`, canvas.width - 6, 8, '#222222', {align: 'right'});
		drawPixelText(context, `DAD ${state.dadDistance > state.distance ? '+' : '-'}${Math.round(Math.abs(state.dadDistance - state.distance))} M`, canvas.width - 6, 16, '#d42a2a', {align: 'right'});
		if (!state.isPlaying && state.distance === 0) {
			drawPixelText(context, state.wax ? 'PRESS GO!' : 'WAX THE SKIS FIRST', canvas.width / 2, 50, '#1a3a6a', {align: 'center', scale: 2});
		}
	};

	const say = text => {
		holidays.say(text, status);
	};

	// A kick: in rhythm, with the other ski than the last kick, it pushes the kid on. Two kicks with the same ski, or kicks too close together, do little, and very fast kicks make the kid fall.
	const kick = side => {
		if (!state.isPlaying || state.time < state.fallenUntil) {
			return;
		}

		const now = state.time;
		const interval = state.lastKick === undefined ? 1 : now - state.lastKick;
		const isAlternating = side !== state.lastSide;
		state.lastKick = now;
		state.lastSide = side;
		if (interval < 0.16) {
			state.fallenUntil = now + 1.4;
			state.speed = 0;
			say('Oops, too fast! You fell in the snow. Steady, left, right, left…');
			return;
		}

		const slope = slopeAt(state.distance);
		const waxFit = fit();
		let power = isAlternating ? 1 : 0.35;
		power *= clamp(interval / 0.45, 0.3, 1);
		if (state.energy <= 0) {
			power *= 0.35;
		}

		// A wax that is too hard slips back on the hills, and no wax slips everywhere.
		if ((waxFit === 'hard' && slope > 0.05) || waxFit === 'none') {
			power *= 0.3;
		}

		state.speed = Math.min(state.speed + (power * 2.4), 9);
		state.energy = Math.max(0, state.energy - 2.2);
		state.kickPose += Math.PI;
		if (state.energy === 0 && state.bars > 0) {
			say('No more energy! Eat a Kvikk Lunsj.');
		}
	};

	const finish = () => {
		state.isPlaying = false;
		start.textContent = 'Ski Again';
		const hasWon = state.distance >= state.dadDistance;
		const time = state.time;
		const isBest = hasWon && (state.best === 0 || time < state.best);
		if (isBest) {
			state.best = time;
			holidays.store('ski-best', time);
		}

		if (hasWon) {
			holidays.celebrate();
		}

		const waxWords = {right: 'The wax was perfect.', hard: 'The wax was too hard for the snow, so the skis slipped on the hills.', soft: 'The wax was too soft for the snow, so snow stuck under the skis.', none: 'You forgot to wax the skis!'};
		say(`${hasWon ? `You beat Dad to the cabin in ${time.toFixed(1)} seconds${isBest ? ', a new record' : ''}! Waffles and hot cocoa for you.` : `Dad was first to the cabin. He is already eating the waffles.`} ${waxWords[fit()]}`);
		start.focus();
	};

	const step = seconds => {
		if (!state.isPlaying) {
			return;
		}

		// With reduced motion, the race only goes on for a moment after each kick, so Dad and the track never move by themselves.
		if (holidays.reducedMotion && state.time - (state.lastKick ?? -1) > 0.6) {
			return;
		}

		state.time += seconds;
		const slope = slopeAt(state.distance);
		const waxFit = fit();
		// The glide slows down by friction, more with snow stuck under a soft wax, and the hills pull the kid down or slow it.
		const friction = waxFit === 'soft' ? 1.6 : 0.55;
		state.speed = Math.max(0, state.speed - (friction * seconds) - (slope * 9 * seconds));
		if (state.time < state.fallenUntil) {
			state.speed = 0;
		}

		state.distance = Math.min(trackLength, state.distance + (state.speed * seconds));
		state.energy = Math.min(100, state.energy + (seconds * 1.5));
		// Dad skis steadily, a little slower up the hills.
		const dadSlope = slopeAt(state.dadDistance);
		state.dadDistance = Math.min(trackLength, state.dadDistance + ((5.6 - (dadSlope * 6)) * seconds));
		if (state.distance >= trackLength || state.dadDistance >= trackLength) {
			finish();
		}

		draw();
	};

	const loop = holidays.loop(step, {while: () => state.isPlaying, target: canvas});

	// The trip pauses when it scrolls away or the tab is hidden, as the loop stops.
	for (const button of holidays.querySelectorAll('[data-ski-wax]')) {
		holidays.on(button, 'click', () => {
			state.wax = button.dataset.skiWax;
			for (const other of holidays.querySelectorAll('[data-ski-wax]')) {
				setPressed(other, other === button);
			}

			say(`${button.querySelector('strong').textContent} wax on the skis. Rub, rub, cork, cork.`);
			draw();
		});
	}

	holidays.on(start, 'click', () => {
		if (!state.wax) {
			say('Wax the skis first! Look at the temperature, and pick the wax for it.');
			return;
		}

		Object.assign(state, {isPlaying: true, distance: 0, speed: 0, dadDistance: 0, energy: 100, bars: 3, lastKick: undefined, lastSide: undefined, fallenUntil: 0, time: 0});
		start.textContent = 'Start Over';
		wrapper.hidden = true;
		say('Go! Left, right, left, right…');
		canvas.focus();
		loop.start();
	});

	const eat = async () => {
		if (!state.isPlaying) {
			say('Save it for the trip!');
			return;
		}

		if (state.bars === 0) {
			say('No more Kvikk Lunsj. Dad has an orange, but he will not share.');
			return;
		}

		state.bars--;
		state.energy = Math.min(100, state.energy + 45);
		const [norwegian, english] = mountainCode[state.ruleIndex];
		state.ruleIndex = (state.ruleIndex + 1) % mountainCode.length;
		wrapper.hidden = false;
		await nextFrame();
		wrapper.textContent = `On the back of the Kvikk Lunsj: “${norwegian}” (${english})`;
		say(`Crunch! A Kvikk Lunsj. Energy up. ${plural(state.bars, 'bar')} left.`);
	};

	for (const button of holidays.querySelectorAll('[data-ski-control]')) {
		const {skiControl} = button.dataset;
		if (skiControl === 'kvikk') {
			holidays.on(button, 'click', eat);
			continue;
		}

		// The kick happens on the press, so the rhythm is right on a phone too, and a click from the keyboard also counts.
		holidays.on(button, 'pointerdown', event => {
			event.preventDefault();
			kick(skiControl);
		});
		holidays.on(button, 'keydown', event => {
			if (event.key === ' ' || event.key === 'Enter') {
				event.preventDefault();
				if (!event.repeat) {
					kick(skiControl);
				}
			}
		});
		holidays.on(button, 'click', event => {
			if (event.detail === 0) {
				kick(skiControl);
			}
		});
	}

	holidays.on(canvas, 'keydown', event => {
		if (event.ctrlKey || event.metaKey || event.altKey) {
			return;
		}

		if (event.key === 'ArrowLeft' || event.key === 'ArrowRight') {
			event.preventDefault();
			if (!event.repeat) {
				kick(event.key === 'ArrowLeft' ? 'left' : 'right');
			}
		} else if (event.key.toLowerCase() === 'k') {
			event.preventDefault();
			eat();
		} else if (event.key === 'Enter' && !state.isPlaying) {
			event.preventDefault();
			start.click();
		}
	});

	showWeather();
	draw();
};

export default class extends GeoCitiesElement {
	connected() {
		setUpSki(this, this.parts);
	}
}
