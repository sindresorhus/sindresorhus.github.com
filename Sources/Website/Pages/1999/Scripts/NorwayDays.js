// The everyday life of a kid in Norway in 1999 on the 1999 page, as toys: my matpakke, dressing for the weather of Bergen, crab fishing off the dock, brown cheese and the cheese slicer, and the Saturday candy. Canvases run only while they are on the screen and the tab is visible.
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

// My matpakke: up to four slices of bread, each with something on it, and a sheet of paper between them, in a lunch box. At school, Mom’s idea of a good lunch and the class’s idea of a cool one are scored, with what happens at the lunch break. A few combinations please both, which is the puzzle.
const setUpLunch = (days, {lunchCanvas: canvas, lunchSlices: slicesText, lunchUndo: undo, lunchGo: go, lunchStatus: status}) => {
	const context = canvas.getContext('2d');
	const maximumSlices = 4;

	const say = text => {
		days.say(text, status);
	};

	// What Mom thinks of each topping, what the class thinks, its color on the bread, and what happens to it at school.
	const toppings = {
		brunost: {mom: 2, cool: 1, color: '#b06a2a', line: 'The brunost is fine. Everybody has brunost.'},
		gulost: {mom: 2, cool: 1, color: '#f2d060', line: 'The cheese sweated a little in the box.'},
		leverpostei: {mom: 3, cool: 0, color: '#8a5a4a', line: 'Leverpostei. Mom says it has iron. Nobody wants to trade for it.'},
		makrell: {mom: 3, cool: -1, color: '#d84a2a', smell: true, line: 'Makrell i tomat! The whole classroom smells of fish. Two kids move to another table.'},
		kaviar: {mom: 2, cool: 0, color: '#f0a0a0', line: 'Kaviar from the tube. Ola says it looks like toothpaste.'},
		syltetøy: {mom: 0, cool: 2, color: '#c8203a', soggy: true, line: 'The jam soaked through the bread. Soggy, but sweet.'},
		nugatti: {mom: -1, cool: 3, color: '#5a3018', line: 'Nugatti! Everyone wants to trade with you.'},
		banan: {mom: 2, cool: 1, color: '#f8e870', line: 'The banana slices went brown, as they always do.'},
	};

	const names = Object.fromEntries([...days.querySelectorAll('[data-lunch-topping]')].map(button => [button.dataset.lunchTopping, button.textContent.trim().replace(/^\S+\s/u, '')]));
	const slices = [];

	const draw = () => {
		fillShape(context, '#d8e8f0', 0, 0, canvas.width, canvas.height);
		// The lunch box, open, from the side: the slices on top of each other, with the paper between them.
		fillShape(context, '#3a7ac0', 40, 108, 160, 34);
		fillShape(context, '#5a9ae0', 40, 108, 160, 5);
		fillShape(context, '#2a5a90', 196, 30, 6, 80);
		for (const [index, topping] of slices.entries()) {
			const y = 100 - (index * 16);
			fillShape(context, '#c8955a', 56, y, 128, 12);
			fillShape(context, '#e8c08a', 58, y + 2, 124, 8);
			fillShape(context, toppings[topping].color, 58, y - 3, 124, 4);
			drawPixelText(context, names[topping].toUpperCase(), 120, y + 3, '#5a3a1a', {align: 'center'});
			if (index < slices.length - 1) {
				// The sheet of paper between the slices, so they do not stick together.
				fillShape(context, '#ffffff', 50, y - 5, 140, 2);
			}
		}

		if (slices.length === 0) {
			drawPixelText(context, 'EMPTY BOX', 120, 120, '#ffffff', {align: 'center', scale: 2});
		}

		drawPixelText(context, `${slices.length}/${maximumSlices} SLICES`, 8, 8, '#2a3a4a');
	};

	const show = () => {
		slicesText.textContent = slices.length === 0 ? 'The lunch box is empty.' : `In the box, from the bottom: ${slices.map(topping => names[topping]).join(', ')}.`;
		draw();
	};

	for (const button of days.querySelectorAll('[data-lunch-topping]')) {
		days.on(button, 'click', () => {
			if (slices.length >= maximumSlices) {
				say('The box is full! Four slices is a proper matpakke.');
				return;
			}

			slices.push(button.dataset.lunchTopping);
			show();
			say(`A slice with ${names[button.dataset.lunchTopping]}${slices.length > 1 ? ', and a sheet of paper under it' : ''}.`);
		});
	}

	days.on(undo, 'click', () => {
		if (slices.length === 0) {
			say('The box is already empty.');
			return;
		}

		const topping = slices.pop();
		show();
		say(`Took out the slice with ${names[topping]}.`);
	});

	days.on(go, 'click', () => {
		if (slices.length === 0) {
			say('An empty box? Mom says: “You are not leaving this house without a matpakke!”');
			return;
		}

		let mom = 0;
		let cool = 0;
		for (const topping of slices) {
			mom += toppings[topping].mom;
			cool += toppings[topping].cool;
		}

		// Mom wants enough food, and the class likes variety.
		const kinds = new Set(slices).size;
		cool += Math.max(0, kinds - 2);
		if (slices.length < 3) {
			mom -= 2;
		}

		const lines = [...new Set(slices)].map(topping => toppings[topping].line);
		if (slices.length < 3) {
			lines.push('You are hungry by the second break.');
		}

		const isPerfect = mom >= 7 && cool >= 5;
		const verdict = isPerfect ? 'The perfect matpakke! Mom is proud, and the class is jealous.' : (mom >= 7 ? 'Mom is happy. The class is not impressed.' : (cool >= 5 ? 'The class loves it. Mom would not.' : 'Neither Mom nor the class is impressed. Try another mix!'));
		if (isPerfect) {
			days.celebrate();
		}

		// The scores are shown up to what pleases each, so the class never gives 7 of 5.
		say(`Lunch break, 11:15. ${lines.join(' ')} Mom: ${clamp(mom, 0, 7)} of 7. Class: ${clamp(cool, 0, 5)} of 5. ${verdict}`);
	});

	show();
};

// Dressing for the weather of Bergen: “there is no bad weather, only bad clothes”. The day has three parts, and the weather changes between them, as it does in Bergen. The clothes keep the kid dry, warm, or cool, and the day is told part by part.
const setUpWeather = (days, {forecast, weatherCanvas: canvas, weatherGo: go, weatherNew: nextDay, weatherStatus: status}) => {
	const context = canvas.getContext('2d');
	const boxes = [...days.querySelectorAll('[data-dress-clothing]')];

	const say = text => {
		days.say(text, status);
	};

	const weathers = {
		rain: {name: 'rain', symbol: '☔', isWet: true, isSunny: false, temperature: 9},
		pouring: {name: 'pouring rain', symbol: '🌧', isWet: true, isSunny: false, temperature: 7},
		sun: {name: 'sun', symbol: '☀', isWet: false, isSunny: true, temperature: 17},
		sleet: {name: 'sleet', symbol: '🌨', isWet: true, isSunny: false, temperature: 1},
		snow: {name: 'snow', symbol: '❄', isWet: false, isSunny: false, temperature: -3},
		wind: {name: 'wind', symbol: '💨', isWet: false, isSunny: false, temperature: 5},
	};

	// Bergen weather: mostly rain, and the sun for a moment now and then.
	const climate = ['rain', 'rain', 'pouring', 'rain', 'sun', 'wind', 'sleet', 'rain', 'snow', 'sun', 'pouring'];
	const dayNames = ['Mandag', 'Tirsdag', 'Onsdag', 'Torsdag', 'Fredag', 'Lørdag', 'Søndag'];
	let day = 0;
	let parts = [];

	// What each piece of clothing does: the part of the body it keeps dry, how warm it is, and shade from the sun. The rain jacket goes over the sweater or the T-shirt, so it has a place of its own, and a cold, wet day can be both warm and dry.
	const clothes = {
		sydvest: {area: 'head', keepsDry: 'head', warmth: 1},
		lue: {area: 'head', warmth: 2},
		caps: {area: 'head', warmth: 0, shade: true},
		regnjakke: {area: 'jacket', keepsDry: 'body', warmth: 1},
		ullgenser: {area: 'body', warmth: 2},
		tskjorte: {area: 'body', warmth: 0},
		regnbukse: {area: 'legs', keepsDry: 'legs', warmth: 1},
		shorts: {area: 'legs', warmth: -1},
		støvler: {area: 'feet', keepsDry: 'feet', warmth: 1},
		joggesko: {area: 'feet', warmth: 0},
		votter: {area: 'hands', warmth: 1},
		solbriller: {area: 'eyes', warmth: 0, shade: true},
	};

	const chosen = () => boxes.filter(box => box.checked).map(box => box.dataset.dressClothing);

	const newDay = () => {
		day = (day + 1) % dayNames.length;
		parts = [randomItem(climate), randomItem(climate), randomItem(climate)].map(name => weathers[name]);
		forecast.textContent = `${dayNames[day]}, Bergen: ${parts.map(part => `${part.symbol} ${part.name}`).join(', then ')}.`;
	};

	const draw = () => {
		const worn = new Set(chosen());
		fillShape(context, '#a8b8c8', 0, 0, canvas.width, canvas.height);
		fillShape(context, '#7a8a7a', 0, 140, canvas.width, 20);
		const has = name => worn.has(name);
		// The kid, from the feet up, with each piece of clothing on top.
		fillShape(context, '#f3c9a0', 48, 116, 8, 20);
		fillShape(context, '#f3c9a0', 64, 116, 8, 20);
		if (has('regnbukse')) {
			fillShape(context, '#ffd21f', 46, 96, 28, 36);
		} else if (has('shorts')) {
			fillShape(context, '#3a6ad0', 46, 96, 28, 16);
		} else {
			fillShape(context, '#2a4a8a', 46, 96, 28, 36);
		}

		if (has('støvler')) {
			fillShape(context, '#2a7a3a', 44, 126, 14, 14);
			fillShape(context, '#2a7a3a', 62, 126, 14, 14);
		} else if (has('joggesko')) {
			fillShape(context, '#ffffff', 44, 134, 14, 6);
			fillShape(context, '#ffffff', 62, 134, 14, 6);
		} else {
			fillShape(context, '#f3c9a0', 46, 134, 10, 6);
			fillShape(context, '#f3c9a0', 64, 134, 10, 6);
		}

		const bodyColor = has('regnjakke') ? '#ffd21f' : (has('ullgenser') ? '#c83a3a' : (has('tskjorte') ? '#ffffff' : '#f3c9a0'));
		fillShape(context, bodyColor, 42, 58, 36, 40);
		fillShape(context, bodyColor, 34, 60, 8, 30);
		fillShape(context, bodyColor, 78, 60, 8, 30);
		if (has('ullgenser') && !has('regnjakke')) {
			for (let x = 44; x < 76; x += 6) {
				fillShape(context, '#ffffff', x, 66, 3, 3);
			}
		}

		fillShape(context, has('votter') ? '#3a6ad0' : '#f3c9a0', 33, 88, 10, 8);
		fillShape(context, has('votter') ? '#3a6ad0' : '#f3c9a0', 77, 88, 10, 8);
		fillEllipse(context, '#f3c9a0', 60, 40, 15, 16);
		fillShape(context, '#222222', 53, 38, 3, 3);
		fillShape(context, '#222222', 64, 38, 3, 3);
		fillShape(context, '#b04040', 56, 47, 8, 2);
		if (has('solbriller')) {
			fillShape(context, '#111111', 49, 36, 22, 6);
		}

		if (has('sydvest')) {
			fillEllipse(context, '#ffd21f', 60, 28, 22, 6);
			fillEllipse(context, '#ffd21f', 60, 24, 14, 8);
		} else if (has('lue')) {
			fillEllipse(context, '#c83a3a', 60, 26, 15, 10);
			fillEllipse(context, '#ffffff', 60, 15, 4, 4);
		} else if (has('caps')) {
			fillEllipse(context, '#3a6ad0', 60, 27, 14, 7);
			fillShape(context, '#3a6ad0', 60, 28, 18, 3);
		} else {
			fillShape(context, '#6a4a2a', 46, 22, 28, 8);
		}
	};

	// One part of the day: wet where rain gets in, cold when the clothes are not warm enough, and hot in the sun with too much on.
	const describePart = (part, worn) => {
		const has = name => worn.includes(name);
		let warmth = 0;
		for (const name of worn) {
			warmth += clothes[name].warmth;
		}

		const needed = part.temperature < 0 ? 6 : (part.temperature < 6 ? 4 : (part.temperature < 12 ? 2 : 0));
		const problems = [];
		let points = 3;
		if (part.isWet) {
			const wetAreas = ['head', 'body', 'legs', 'feet'].filter(area => !worn.some(name => clothes[name].keepsDry === area));
			if (wetAreas.length > 0) {
				points -= Math.min(2, wetAreas.length);
				problems.push(`wet ${wetAreas.map(area => ({head: 'hair', body: 'back', legs: 'pants', feet: 'socks'})[area]).join(' and ')}`);
			}
		}

		if (warmth < needed) {
			points -= needed - warmth > 2 ? 2 : 1;
			problems.push(part.temperature < 0 ? 'frozen fingers and toes' : 'cold');
		} else if (part.isSunny && warmth > 2) {
			points -= 1;
			problems.push('far too hot');
		}

		if (part.isSunny && !has('solbriller') && !has('caps')) {
			problems.push('squinting');
		}

		if (has('solbriller') && (part.name === 'pouring rain' || part.name === 'sleet')) {
			problems.push('sunglasses in the rain: cool, but blind');
		}

		if (has('shorts') && part.temperature < 2) {
			points -= 1;
			problems.push('shorts in the snow, brrr');
		}

		return {points: Math.max(0, points), text: problems.length === 0 ? `${part.name}: perfect` : `${part.name}: ${problems.join(', ')}`};
	};

	for (const box of boxes) {
		days.on(box, 'change', () => {
			// Only one thing for each part of the body, and one jacket, so a new choice takes off the old one.
			const {area} = clothes[box.dataset.dressClothing];
			if (box.checked) {
				for (const other of boxes) {
					if (other !== box && clothes[other.dataset.dressClothing].area === area) {
						other.checked = false;
					}
				}
			}

			draw();
		});
	}

	days.on(go, 'click', () => {
		const worn = chosen();
		if (worn.length === 0) {
			say('You cannot go out naked! Mom says so. So does the law.');
			return;
		}

		const results = parts.map(part => describePart(part, worn));
		let total = 0;
		for (const result of results) {
			total += result.points;
		}

		let verdict;
		if (total === 9) {
			verdict = 'Perfect! There is no bad weather, only bad clothes, and you had good clothes.';
			days.celebrate();
		} else if (total >= 6) {
			verdict = 'Not bad. Mom only says “I told you so” once.';
		} else {
			verdict = 'You come home soaked and frozen. Mom says: “There is no bad weather, only bad clothes!”';
		}

		say(`Morning: ${results[0].text}. Noon: ${results[1].text}. Afternoon: ${results[2].text}. ${total} of 9 points. ${verdict}`);
	});

	days.on(nextDay, 'click', () => {
		newDay();
		say(`A new day, new weather: ${forecast.textContent} Get dressed!`);
	});

	newDay();
	draw();
};

// Crab fishing off the dock in the summer of 1999: the line goes down with a mussel on it, a crab walks over and grabs it, and the line is reeled in by holding a button. A crab lets go when the line goes up too fast, and gets tired of holding on while it waits, and out of the water it holds on less well, so the last bit has to be quick but not too quick. The crabs in the bucket are let go at the end of the day, as everyone does. It runs only while it is on the screen and the tab is visible.
const setUpCrabs = (days, {crabCanvas: canvas, crabLower: lower, crabReel: reel, crabRelease: release, crabStatus: status}) => {
	const context = canvas.getContext('2d');
	const surface = 70;
	const bottom = 182;
	const dockY = 46;
	const lineX = 150;

	const state = {
		phase: 'idle',
		hookY: dockY,
		speed: 0,
		isReeling: false,
		grip: 1,
		waitUntil: 0,
		crab: undefined,
		bucket: [],
		time: 0,
		best: Math.max(0, Math.round(Number(days.stored('crab-best', 0)) || 0)),
		crabs: Array.from({length: 4}, (_, index) => ({x: 40 + (index * 90), direction: index % 2 === 0 ? 1 : -1, size: randomInteger(5, 9)})),
	};

	const drawCrab = (x, y, size, isUpsideDown = false) => {
		fillEllipse(context, '#c84a2a', x, y, size, size * 0.6);
		fillShape(context, '#111111', x - 3, y - (size * 0.6) - 2, 2, 2);
		fillShape(context, '#111111', x + 1, y - (size * 0.6) - 2, 2, 2);
		const legSwing = days.reducedMotion ? 0 : Math.floor(state.time * 8) % 2;
		for (const side of [-1, 1]) {
			fillShape(context, '#a83a1a', x + (side * size) - (side > 0 ? 0 : 3), y - 1 + legSwing, 3, 1);
			fillShape(context, '#a83a1a', x + (side * size) - (side > 0 ? 0 : 3), y + 2 - legSwing, 3, 1);
			fillEllipse(context, '#d85a3a', x + (side * (size + 3)), y - (isUpsideDown ? -3 : 3), 2.5, 2);
		}
	};

	const draw = () => {
		fillShape(context, '#bfe4ff', 0, 0, canvas.width, surface);
		// The fjord, darker further down, with the seaweed and the stones on the bottom.
		const sea = context.createLinearGradient(0, surface, 0, canvas.height);
		sea.addColorStop(0, '#3a8ab0');
		sea.addColorStop(1, '#14405a');
		context.fillStyle = sea;
		context.fillRect(0, surface, canvas.width, canvas.height - surface);
		fillShape(context, '#8a7a5a', 0, bottom + 4, canvas.width, canvas.height - bottom - 4);
		for (let index = 0; index < 12; index++) {
			const x = 10 + (index * 34);
			fillEllipse(context, '#6a6a6a', x, bottom + 6, 8, 4);
			fillShape(context, '#2a7a3a', x + 12, bottom - 14, 2, 18);
			fillShape(context, '#2a7a3a', x + 15, bottom - 10, 2, 14);
		}

		// The dock, with me on it, and the bucket.
		fillShape(context, '#8a5a2b', 0, dockY, 200, 8);
		for (let x = 10; x < 200; x += 40) {
			fillShape(context, '#5a3a1a', x, dockY + 8, 6, canvas.height);
		}

		fillShape(context, '#1aa3b8', 128, dockY - 22, 10, 14);
		fillEllipse(context, '#f3c9a0', 133, dockY - 28, 5, 5);
		fillShape(context, '#ffd21f', 127, dockY - 34, 12, 3);
		fillShape(context, '#2a4aa0', 128, dockY - 8, 4, 8);
		fillShape(context, '#2a4aa0', 134, dockY - 8, 4, 8);
		fillShape(context, '#8a6a4a', 136, dockY - 18, 16, 2);
		fillPolygon(context, '#d42a2a', [[60, dockY - 18], [84, dockY - 18], [80, dockY], [64, dockY]]);
		drawPixelText(context, `${state.bucket.length}`, 72, dockY - 13, '#ffffff', {align: 'center'});

		// The crabs on the bottom, walking sideways, as crabs do.
		for (const crab of state.crabs) {
			if (crab !== state.crab) {
				drawCrab(crab.x, bottom, crab.size);
			}
		}

		// The line and the hook, with the mussel, or the crab on it.
		context.strokeStyle = '#f4f4f4';
		context.lineWidth = 1;
		context.beginPath();
		context.moveTo(lineX + 2, dockY - 18);
		const tug = state.phase === 'bite' && !days.reducedMotion && Math.floor(state.time * 10) % 2 === 0 ? 2 : 0;
		context.lineTo(lineX + tug, state.hookY);
		context.stroke();
		if (state.crab && (state.phase === 'reeling' || state.phase === 'bite')) {
			drawCrab(lineX + tug, state.hookY + 6, state.crab.size);
		} else if (state.phase !== 'idle') {
			fillEllipse(context, '#2a2a4a', lineX, state.hookY + 3, 4, 2);
		}

		// The grip of the crab, while it is on the line.
		if (state.crab && state.phase === 'reeling') {
			fillShape(context, '#ffffff', canvas.width - 30, 80, 14, 100);
			fillShape(context, state.grip > 0.3 ? '#dd6633' : '#dd2222', canvas.width - 28, 82 + (96 * (1 - state.grip)), 10, 96 * state.grip);
			drawPixelText(context, 'GRIP', canvas.width - 23, 184, '#ffffff', {align: 'center'});
			const isTooFast = state.speed > 38;
			drawPixelText(context, isTooFast ? 'TOO FAST!' : 'STEADY', 300, 10, isTooFast ? '#d42a2a' : '#1a6a2a', {align: 'center', scale: 2});
		}

		drawPixelText(context, `BEST DAY: ${state.best}`, canvas.width - 6, 4, '#2a3a4a', {align: 'right'});
	};

	const say = text => {
		days.say(text, status);
	};

	const setPhase = phase => {
		state.phase = phase;
		lower.disabled = phase !== 'idle';
		reel.disabled = phase === 'idle';
		release.disabled = state.bucket.length === 0;
	};

	const step = seconds => {
		state.time += seconds;
		// The crabs on the bottom walk back and forth. When the mussel has waited for a moment, the nearest crab goes for it, so the wait is never long. With reduced motion, the crabs do not walk, and the nearest one is at the mussel at once.
		const nearest = state.crabs.filter(crab => crab !== state.crab).sort((first, second) => Math.abs(first.x - lineX) - Math.abs(second.x - lineX))[0];
		for (const crab of state.crabs) {
			if (crab === state.crab) {
				continue;
			}

			if (state.phase === 'waiting' && crab === nearest && state.time > state.waitUntil) {
				crab.x = days.reducedMotion ? lineX : crab.x + (Math.sign(lineX - crab.x) * Math.min(30 * seconds, Math.abs(lineX - crab.x)));
				if (Math.abs(crab.x - lineX) < 2) {
					state.crab = crab;
					state.phase = 'bite';
					state.grip = 1;
					say('Tug, tug! A crab has the mussel! Hold the reel button to pull it up. Not too fast!');
				}
			} else if (!days.reducedMotion) {
				crab.x += crab.direction * 10 * seconds;
				if (crab.x < 14 || crab.x > canvas.width - 50) {
					crab.direction *= -1;
				}
			}
		}

		if (state.phase === 'lowering') {
			state.hookY = Math.min(bottom - 4, state.hookY + (70 * seconds));
			if (state.hookY >= bottom - 4) {
				setPhase('waiting');
				state.waitUntil = state.time + 1 + (Math.random() * 4);
				say('The mussel is on the bottom. Wait for a crab…');
			}
		} else if (state.phase === 'bite' || state.phase === 'reeling') {
			// Holding the button speeds the line up, and letting go slows it down, so a steady pull is a rhythm of holding and letting go.
			state.speed = state.isReeling ? Math.min(state.speed + (110 * seconds), 80) : Math.max(state.speed - (120 * seconds), 0);
			if (state.speed > 0) {
				state.phase = 'reeling';
			}

			state.hookY -= state.speed * seconds;
			const isOutOfWater = state.hookY < surface;
			// The crab gets tired of waiting, lets go much faster when the line is too fast, and holds on less well out of the water.
			let loss = 0.06;
			if (state.speed > 38) {
				loss += (state.speed - 38) * 0.03;
			}

			if (isOutOfWater) {
				loss *= 2.5;
			}

			state.grip -= loss * seconds;
			if (state.grip <= 0) {
				say(randomItem(['Plop! It let go and sank to the bottom.', 'It let go! Crabs do not like an elevator that fast.', 'Splash. Gone. Try again, slower.']));
				state.crab.x = lineX + randomInteger(-60, 60);
				state.crab = undefined;
				state.speed = 0;
				state.isReeling = false;
				setPhase('lowering');
			} else if (state.hookY <= dockY) {
				state.bucket.push(state.crab.size);
				state.crabs = state.crabs.filter(crab => crab !== state.crab);
				state.crabs.push({x: randomInteger(20, canvas.width - 60), direction: 1, size: randomInteger(5, 9)});
				const size = state.crab.size;
				state.crab = undefined;
				state.isReeling = false;
				state.speed = 0;
				state.hookY = dockY;
				setPhase('idle');
				const isBest = state.bucket.length > state.best;
				if (isBest) {
					state.best = state.bucket.length;
					days.store('crab-best', state.best);
				}

				if (state.bucket.length === 10) {
					days.celebrate();
				}

				say(`Got it! ${size >= 8 ? 'A big one! ' : ''}${plural(state.bucket.length, 'crab')} in the bucket${isBest ? ', a new record' : ''}.`);
				lower.focus();
			}
		}

		draw();
	};

	// The window is watched, not only the canvas, so the line goes on while the buttons below the canvas are in view.
	const loop = days.loop(step, {while: () => state.phase !== 'idle' || !days.reducedMotion, target: canvas.closest('section')});

	const startLowering = () => {
		if (state.phase !== 'idle') {
			return;
		}

		const hadFocus = document.activeElement === lower;
		setPhase('lowering');
		// The lower button is disabled now, so the focus goes on to the reel button.
		if (hadFocus) {
			reel.focus();
		}

		say('Down goes the line, with a mussel on the hook.');
		loop.start();
	};

	days.on(lower, 'click', startLowering);

	const setReeling = isReeling => {
		state.isReeling = isReeling && state.phase !== 'idle';
		if (state.isReeling && (state.phase === 'waiting' || state.phase === 'lowering')) {
			// Reeling in without a crab just brings the mussel back up.
			state.isReeling = false;
			say('Nothing on it yet. Wait for the tug!');
		}
	};

	days.on(reel, 'pointerdown', event => {
		event.preventDefault();
		reel.setPointerCapture(event.pointerId);
		setReeling(true);
	});

	for (const type of ['pointerup', 'pointercancel', 'lostpointercapture']) {
		days.on(reel, type, () => {
			setReeling(false);
		});
	}

	// A keyboard holds the reel with Space or Enter on the button, or the up arrow on the canvas.
	days.on(reel, 'keydown', event => {
		if ((event.key === ' ' || event.key === 'Enter') && !event.repeat) {
			event.preventDefault();
			setReeling(true);
		}
	});

	days.on(reel, 'keyup', event => {
		if (event.key === ' ' || event.key === 'Enter') {
			setReeling(false);
		}
	});

	days.on(reel, 'blur', () => {
		setReeling(false);
	});

	days.on(canvas, 'keydown', event => {
		if (event.key === 'Enter') {
			event.preventDefault();
			startLowering();
		} else if ((event.key === 'ArrowUp' || event.key === ' ') && !event.repeat) {
			event.preventDefault();
			setReeling(true);
		}
	});

	days.on(canvas, 'keyup', event => {
		if (event.key === 'ArrowUp' || event.key === ' ') {
			setReeling(false);
		}
	});

	days.on(canvas, 'blur', () => {
		setReeling(false);
	});

	days.on(release, 'click', () => {
		const count = state.bucket.length;
		state.bucket = [];
		setPhase(state.phase);
		say(`Splash! ${plural(count, 'crab')} run back into the sea, sideways. See you next summer!`);
		(lower.disabled ? reel : lower).focus();
		draw();
	});

	setPhase('idle');
	draw();
};

// Brown cheese and the cheese slicer, the ostehøvel, invented by Thor Bjørklund in 1925. A drag across the top of the cheese cuts a slice: level gives a thin, even slice, pressing down digs deeper, and lifting skips. The top of the cheese keeps the shape of every slice, so uneven slicing makes a ski slope, which every Norwegian dad complains about.
const setUpCheese = (days, {cheeseCanvas: canvas, cheeseNew: newCheese, cheeseStatus: status}) => {
	const context = canvas.getContext('2d');
	const columns = 40;
	const left = 70;
	const columnWidth = 4;
	const floor = 150;

	const state = {
		heights: [],
		stroke: undefined,
		slices: [],
		perfect: 0,
		tilt: 0,
		hasComplainedAboutSlope: false,
	};

	const say = text => {
		days.say(text, status);
	};

	const reset = () => {
		state.heights = Array.from({length: columns}, () => 70);
		state.slices = [];
		state.perfect = 0;
		state.hasComplainedAboutSlope = false;
	};

	// The slope of the top of the cheese, as the difference in height between the left and the right end.
	const slope = () => {
		let first = 0;
		let last = 0;
		for (let index = 0; index < 8; index++) {
			first += state.heights[index] / 8;
			last += state.heights[columns - 1 - index] / 8;
		}

		return first - last;
	};

	const draw = () => {
		fillShape(context, '#f4ecd8', 0, 0, canvas.width, canvas.height);
		fillShape(context, '#c8a070', 0, floor, canvas.width, canvas.height - floor);
		// The cheese: the front, and the top, a little lighter, with the shape of the slices.
		for (let index = 0; index < columns; index++) {
			const x = left + (index * columnWidth);
			const height = state.heights[index];
			fillShape(context, '#a0582a', x, floor - height, columnWidth, height);
			fillShape(context, '#c87a3a', x, floor - height, columnWidth, 3);
		}

		fillShape(context, '#7a4020', left + (columns * columnWidth), floor - state.heights[columns - 1], 4, state.heights[columns - 1]);
		// The slices so far, on a slice of bread to the right.
		fillShape(context, '#d8a868', 250, floor - 8, 60, 8);
		for (const [index, slice] of state.slices.slice(-12).entries()) {
			fillShape(context, slice.isPerfect ? '#c87a3a' : '#a0582a', 252 + (slice.wobble * 2), floor - 10 - (index * 3), 56, Math.max(1, Math.min(3, slice.mean)));
		}

		// The slicer, in the hand, while it cuts.
		if (state.stroke) {
			const {x, y} = state.stroke.point;
			fillPolygon(context, '#c0c4cc', [[x - 14, y], [x + 14, y], [x + 18, y + 6], [x - 18, y + 6]]);
			fillShape(context, '#222222', x - 10, y + 2, 20, 1);
			fillShape(context, '#8a5a2a', x - 3, y - 26, 6, 26);
		} else {
			// The slicer waits at the left, tilted by the keyboard.
			const y = floor - state.heights[0] - 8;
			context.save();
			context.translate(left - 22, y);
			context.rotate(state.tilt * 0.08);
			fillPolygon(context, '#c0c4cc', [[-14, 0], [14, 0], [18, 6], [-18, 6]]);
			fillShape(context, '#8a5a2a', -3, -26, 6, 26);
			context.restore();
		}

		drawPixelText(context, `SLICES ${state.slices.length}  PERFECT ${state.perfect}`, 8, 8, '#5a3a1a');
		if (Math.abs(slope()) > 10) {
			drawPixelText(context, 'SKIBAKKE!', 165, 30, '#c8102e', {align: 'center', scale: 2});
		}
	};

	const columnAt = x => Math.floor((x - left) / columnWidth);

	// Cuts the columns that the slicer passed, at a depth that comes from how far the hand went down since the start.
	const cut = (column, depth) => {
		if (column < 0 || column >= columns || state.stroke.cut.has(column)) {
			return;
		}

		state.stroke.cut.add(column);
		// Lifted too much, the slicer skips over the cheese.
		if (depth < 0.5) {
			state.stroke.skipped++;
			return;
		}

		const amount = Math.min(depth, state.heights[column] - 4);
		state.heights[column] -= amount;
		state.stroke.thicknesses.push(amount);
	};

	const finishSlice = () => {
		const {stroke} = state;
		state.stroke = undefined;
		if (!stroke || stroke.cut.size < 4) {
			draw();
			return;
		}

		const thicknesses = stroke.thicknesses;
		const count = Math.max(thicknesses.length, 1);
		let total = 0;
		for (const thickness of thicknesses) {
			total += thickness;
		}

		const mean = total / count;
		let variance = 0;
		for (const thickness of thicknesses) {
			variance += ((thickness - mean) ** 2) / count;
		}

		const spread = Math.sqrt(variance);
		const isWhole = stroke.cut.size >= columns * 0.8 && stroke.skipped < 3;
		// A slice of almost nothing is not a slice, as the cheese can be gone.
		const isAir = mean < 0.5;
		const isPerfect = isWhole && !isAir && mean <= 2.4 && spread <= 0.6;
		state.slices.push({mean, isPerfect, wobble: Math.round(spread * 2)});
		if (isPerfect) {
			state.perfect++;
		}

		let message;
		if (isAir && Math.max(...state.heights) <= 5) {
			message = 'Only air. The cheese is gone! Time for a new one.';
		} else if (!isWhole) {
			message = stroke.skipped >= 3 ? 'The slicer skipped, and the slice broke into crumbs. Keep it on the cheese!' : 'Half a slice! Go all the way across.';
		} else if (isPerfect) {
			message = randomItem(['A perfect, thin slice!', 'Paper thin! Mormor would be proud.', 'Perfect. You can almost see through it.']);
		} else if (mean > 3.2) {
			message = 'That is not a slice, that is a brick! Do not press down so hard.';
		} else if (spread > 0.9) {
			message = 'A wobbly slice, thick at one end. Keep the slicer level.';
		} else {
			message = 'A good slice, a little thick.';
		}

		if (Math.abs(slope()) > 10 && !state.hasComplainedAboutSlope) {
			state.hasComplainedAboutSlope = true;
			message += ' Dad, from the kitchen: “WHO MADE A SKI SLOPE IN THE BRUNOST?!”';
		}

		if (state.perfect === 8) {
			days.celebrate();
			message += ' Eight perfect slices! You are a true Norwegian.';
		}

		if (Math.min(...state.heights) < 12) {
			message += ' The cheese is almost gone. Time for a new one.';
		}

		say(message);
		draw();
	};

	days.on(canvas, 'pointerdown', event => {
		if (event.button !== 0) {
			return;
		}

		const point = canvasPoint(canvas, event);
		canvas.setPointerCapture(event.pointerId);
		state.stroke = {startY: point.y, point, cut: new Set(), thicknesses: [], skipped: 0, lastColumn: columnAt(point.x)};
		draw();
	});

	days.on(canvas, 'pointermove', event => {
		if (!state.stroke) {
			return;
		}

		const point = canvasPoint(canvas, event);
		const depth = 1.6 + ((point.y - state.stroke.startY) * 0.12);
		const column = columnAt(point.x);
		// Every column between the last point and this one is cut, so a fast drag cuts them all.
		for (let index = Math.max(state.stroke.lastColumn, 0); index <= Math.min(column, columns - 1); index++) {
			cut(index, depth);
		}

		state.stroke.lastColumn = Math.max(state.stroke.lastColumn, column + 1);
		state.stroke.point = point;
		draw();
	});

	days.on(canvas, 'pointerup', finishSlice);
	days.on(canvas, 'pointercancel', finishSlice);
	days.on(canvas, 'lostpointercapture', finishSlice);

	// With the keyboard, the arrow keys tilt the slicer, and Enter cuts a slice at that tilt, thicker at one end when it is tilted.
	days.on(canvas, 'keydown', event => {
		if (event.key === 'ArrowUp' || event.key === 'ArrowDown') {
			event.preventDefault();
			state.tilt = clamp(state.tilt + (event.key === 'ArrowUp' ? -1 : 1), -4, 4);
			say(state.tilt === 0 ? 'The slicer is level.' : `The slicer is tilted ${Math.abs(state.tilt)} to the ${state.tilt > 0 ? 'right' : 'left'}.`);
			draw();
		} else if ((event.key === 'Enter' || event.key === ' ') && !event.repeat) {
			event.preventDefault();
			state.stroke = {startY: 0, point: {x: left, y: 0}, cut: new Set(), thicknesses: [], skipped: 0, lastColumn: 0};
			for (let index = 0; index < columns; index++) {
				cut(index, 1.6 + (state.tilt * ((index / columns) - 0.5) * 2));
			}

			finishSlice();
		}
	});

	days.on(newCheese, 'click', () => {
		reset();
		say('A new brown cheese, fresh from the store. Slice it nicely this time.');
		draw();
	});

	reset();
	draw();
};

// Saturday candy, lørdagsgodt: candy by weight at the store, for the 20 kroner of the week. Each piece weighs a little more or less than the label says, and the scale is at the counter, so the visitor counts and guesses. Too much, and the lady sends you back to the bins. The price is rounded to 50 øre, the smallest coin in Norway in 1999.
const setUpCandy = (days, {candyCanvas: canvas, candyBack: back, candyPay: pay, candyStatus: status}) => {
	const context = canvas.getContext('2d');
	const pricePerGram = 0.089;
	const budget = 20;

	const kinds = {
		seigmenn: {weight: 6, color: '#e83030', name: 'jelly man'},
		skumbananer: {weight: 8, color: '#f2d030', name: 'foam banana'},
		lakris: {weight: 4, color: '#222222', name: 'licorice'},
		sure: {weight: 5, color: '#30c050', name: 'sour tongue'},
		sjokolade: {weight: 3, color: '#6a3a1a', name: 'chocolate button'},
	};

	const state = {
		bag: [],
		tries: 0,
		lastWeight: undefined,
		best: Math.max(0, Math.round(Number(days.stored('candy-best', 0)) || 0)),
	};

	const say = text => {
		days.say(text, status);
	};

	const weightOf = () => {
		let total = 0;
		for (const piece of state.bag) {
			total += piece.weight;
		}

		return total;
	};

	const priceOf = grams => Math.round(grams * pricePerGram * 2) / 2;

	const draw = () => {
		fillShape(context, '#fff4e0', 0, 0, canvas.width, canvas.height);
		// The bins, with a label of the weight of each piece.
		for (const [index, [kind, candy]] of Object.entries(kinds).entries()) {
			const x = 8 + (index * 38);
			fillShape(context, '#c8d8e8', x, 30, 34, 40);
			for (let piece = 0; piece < 10; piece++) {
				fillEllipse(context, candy.color, x + 6 + ((piece * 7) % 24), 60 - (Math.floor(piece / 4) * 7), 3, 2.5);
			}

			drawPixelText(context, `${candy.weight}G`, x + 17, 74, '#333333', {align: 'center'});
			const count = state.bag.filter(piece => piece.kind === kind).length;
			drawPixelText(context, `×${count}`, x + 17, 84, '#c8102e', {align: 'center'});
		}

		// The paper bag, which fills up.
		const fill = Math.min(weightOf() / 300, 1);
		fillPolygon(context, '#e8d0a0', [[212, 40], [292, 40], [300, 150], [204, 150]]);
		for (const [index, piece] of state.bag.slice(-80).entries()) {
			fillEllipse(context, kinds[piece.kind].color, 214 + ((index * 13) % 76), 146 - (Math.floor(index / 6) * 5), 3.5, 3);
		}

		fillShape(context, '#c8b080', 204, 150, 96, 4);
		drawPixelText(context, 'GODTERI', 252, 46, '#8a5a2a', {align: 'center'});
		drawPixelText(context, `${state.bag.length} PIECES`, 8, 8, '#333333', {scale: 2});
		drawPixelText(context, 'BUDGET 20 KR - 8,90 KR/HG', 8, 104, '#555555');
		if (state.lastWeight !== undefined) {
			fillShape(context, '#1a2a1a', 8, 120, 180, 22);
			drawPixelText(context, `LAST WEIGH: ${state.lastWeight} G`, 14, 127, '#33ff66');
		}

		if (fill >= 1) {
			drawPixelText(context, 'FULL!', 252, 90, '#c8102e', {align: 'center', scale: 2});
		}
	};

	for (const button of days.querySelectorAll('[data-candy-kind]')) {
		days.on(button, 'click', () => {
			const kind = button.dataset.candyKind;
			const candy = kinds[kind];
			// Each piece weighs up to a gram more or less than the label.
			const weight = Math.round((candy.weight + ((Math.random() * 2) - 1)) * 10) / 10;
			state.bag.push({kind, weight});
			say(`In the bag: one ${candy.name}. ${plural(state.bag.length, 'piece')}.`);
			draw();
		});
	}

	days.on(back, 'click', () => {
		const piece = state.bag.pop();
		say(piece ? `Put one ${kinds[piece.kind].name} back. (Mom says no eating from the bins.)` : 'The bag is empty.');
		draw();
	});

	days.on(pay, 'click', () => {
		if (state.bag.length === 0) {
			say('An empty bag? The lady at the counter looks confused.');
			return;
		}

		const grams = Math.round(weightOf());
		const price = priceOf(grams);
		state.lastWeight = grams;
		if (price > budget) {
			state.tries++;
			say(`The lady weighs it: ${grams} grams, that is ${price.toFixed(2).replace('.', ',')} kroner. You only have 20! ${state.tries > 2 ? 'The queue behind you sighs loudly.' : 'Put something back.'}`);
			draw();
			return;
		}

		const change = budget - price;
		const isBest = grams > state.best;
		if (isBest) {
			state.best = grams;
			days.store('candy-best', grams);
		}

		let verdict;
		if (change === 0) {
			verdict = 'Exactly 20 kroner! Not one øre wasted. Best Saturday ever.';
			days.celebrate();
		} else if (change <= 1) {
			verdict = `Only ${change.toFixed(2).replace('.', ',')} kroner left, for a Hubba Bubba next week.`;
		} else {
			verdict = `${change.toFixed(2).replace('.', ',')} kroner left over. You could have had more candy!`;
		}

		say(`${grams} grams, ${price.toFixed(2).replace('.', ',')} kroner. ${verdict}${isBest ? ' A new record bag!' : ''}`);
		state.bag = [];
		state.tries = 0;
		draw();
	});

	draw();
};

export default class extends GeoCitiesElement {
	connected() {
		setUpLunch(this, this.parts);
		setUpWeather(this, this.parts);
		setUpCrabs(this, this.parts);
		setUpCheese(this, this.parts);
		setUpCandy(this, this.parts);
	}
}
