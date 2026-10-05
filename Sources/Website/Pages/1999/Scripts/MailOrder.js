// Order Now! on the 1999 page: the ads on the back pages of my comic books, the coupons that the visitor cuts out with scissors, the piggy bank that pays, Mamma who says no, the 6 to 8 weeks of waiting for the mailman, the packages with bubble wrap, and the things that came, to play with. The orders are kept in the browser. The kitchen table, the mailbox, and my stuff each run only while their canvas is on the screen and the tab is visible, and for visitors who prefer reduced motion, nothing moves by itself.
const randomItem = items => items[Math.floor(Math.random() * items.length)];
const randomInteger = (minimum, maximum) => minimum + Math.floor(Math.random() * (maximum - minimum + 1));
const randomBetween = (minimum, maximum) => minimum + (Math.random() * (maximum - minimum));
const clamp = (value, minimum, maximum) => Math.min(Math.max(value, minimum), maximum);

// Shows a toggle button as pressed, for screen readers and for the style.
const setPressed = (button, isPressed) => {
	button.setAttribute('aria-pressed', String(isPressed));
	if (isPressed) {
		button.dataset.state = 'on';
	} else {
		delete button.dataset.state;
	}
};

// The position of a pointer on a canvas, in the pixels of the canvas.
const canvasPoint = (canvas, event) => {
	const rectangle = canvas.getBoundingClientRect();
	return {
		x: (event.clientX - rectangle.left) * canvas.width / rectangle.width,
		y: (event.clientY - rectangle.top) * canvas.height / rectangle.height,
	};
};

// What each ad sells, what really comes in the mail, and what Mamma and Pappa say about it.
const catalog = {
	'sea-monkeys': {
		name: 'Sea-Monkeys',
		reality: 'A paper packet of dust, a tiny plastic tank, and no crowns. Not one crown.',
		mamma: 'Sea-Monkeys? No more pets in this house, Sindre. Remember what happened to the hamster.',
		pappa: {isYes: true, text: 'Pappa: “Sea-Monkeys! I had them in 1968. They are only shrimp, Mamma.” Mamma sighs. Yes!'},
	},
	'x-ray-specs': {
		name: 'X-Ray Specs',
		reality: 'Cardboard glasses with a feather between the lenses. They make everything blurry and double.',
	},
	chia: {
		name: 'Chia Pet',
		reality: 'A bald clay ram, a bag of seeds, and a saucer. It has no hair yet. At all.',
	},
	whoopee: {
		name: 'Whoopee Cushion',
		reality: 'A flat pink rubber balloon. Smaller than in the ad. It smells like a bicycle tire.',
		mamma: 'A whoopee cushion? Not in this house. Mormor comes for dinner on Sunday!',
		pappa: {isYes: true, text: 'Pappa laughs so hard that he has to sit down. “Yes! But do not tell Mamma.”'},
	},
	buzzer: {
		name: 'Joy Buzzer',
		reality: 'A tin disc the size of a 5-krone coin, with a spring. No lightning bolts.',
	},
	'onion-gum': {
		name: 'Onion Gum',
		reality: 'Five sticks of gum in a spearmint pack. The pack already smells of onion.',
	},
	crystals: {
		name: 'Crystals',
		reality: 'A plastic cup, a bag of white powder, and a gray rock. The castle must be inside the rock.',
	},
	draw: {
		name: 'Art Test',
		reality: 'A test form with Tippy on it, and a return envelope. Free! For now.',
	},
	hovercraft: {
		name: 'Hovercraft',
		reality: 'One sheet of paper. The plans. Motor, plywood, skirt, and fan not included.',
		mamma: 'A hovercraft? You will not drive a hovercraft on Store Lungegårdsvann!',
		pappa: {isYes: false, text: 'Pappa, behind his newspaper: “What did Mamma say?”'},
	},
};

const catalogOrder = Object.keys(catalog);

// The cost of sending an order, on top of the price.
const postage = 15;
const stampPrice = 4;

const weekOfYear = week => ((week - 1) % 52) + 1;
const yearOfWeek = week => 1999 + Math.floor((week - 1) / 52);

// Fonts of the drawings.
const impact = '"Impact", "Arial Black", "Haettenschweiler", sans-serif';
const comicSans = '"Comic Sans MS", "Comic Sans", "Chalkboard SE", "Comic Neue", cursive';
const times = '"Times New Roman", Times, serif';
const ink = '#1a1a1a';

const drawText = (context, text, x, y, {font = `16px ${comicSans}`, color = ink, align = 'left', baseline = 'alphabetic', stroke, strokeWidth = 3} = {}) => {
	context.font = font;
	context.textAlign = align;
	context.textBaseline = baseline;
	if (stroke) {
		context.lineJoin = 'round';
		context.lineWidth = strokeWidth;
		context.strokeStyle = stroke;
		context.strokeText(text, x, y);
	}

	context.fillStyle = color;
	context.fillText(text, x, y);
};

// Draws text in lines that fit a width, and returns the y after the last line.
const drawWrapped = (context, text, x, y, maxWidth, lineHeight, options = {}) => {
	context.font = options.font ?? `16px ${comicSans}`;
	const lines = [];
	let line = '';
	for (const word of text.split(' ')) {
		const candidate = line ? `${line} ${word}` : word;
		if (line && context.measureText(candidate).width > maxWidth) {
			lines.push(line);
			line = word;
		} else {
			line = candidate;
		}
	}

	if (line) {
		lines.push(line);
	}

	for (const [index, text] of lines.entries()) {
		drawText(context, text, x, y + (index * lineHeight), options);
	}

	return y + (lines.length * lineHeight);
};

// The halftone dots of the comics, as a pattern, made once for each color and size.
const dotPatterns = new Map();
const dots = (context, color, spacing = 5, radius = 1.4) => {
	const key = `${color} ${spacing} ${radius}`;
	if (!dotPatterns.has(key)) {
		const tile = document.createElement('canvas');
		tile.width = spacing;
		tile.height = spacing;
		const tileContext = tile.getContext('2d');
		tileContext.fillStyle = color;
		for (const [x, y] of [[0, 0], [spacing, 0], [0, spacing], [spacing, spacing], [spacing / 2, spacing / 2]]) {
			tileContext.beginPath();
			tileContext.arc(x, y, radius, 0, Math.PI * 2);
			tileContext.fill();
		}

		dotPatterns.set(key, context.createPattern(tile, 'repeat'));
	}

	return dotPatterns.get(key);
};

// Fills a shape with a flat color, then halftone dots for the shade, then a black outline, like the printing of a comic.
const comicShape = (context, makePath, {fill, shade, outline = ink, lineWidth = 2} = {}) => {
	context.beginPath();
	makePath();
	if (fill) {
		context.fillStyle = fill;
		context.fill();
	}

	if (shade) {
		context.fillStyle = dots(context, shade);
		context.fill();
	}

	if (outline) {
		context.lineWidth = lineWidth;
		context.strokeStyle = outline;
		context.lineJoin = 'round';
		context.stroke();
	}
};

// A canvas throws on a negative radius, so a shape that shrinks to nothing is drawn as nothing.
const ellipse = (context, x, y, radiusX, radiusY, rotation = 0) => {
	context.ellipse(x, y, Math.max(0, radiusX), Math.max(0, radiusY), rotation, 0, Math.PI * 2);
};

// A starburst with a word in it, the loudest thing in an ad.
const starburst = (context, x, y, radius, text, {fill = '#ffe100', color = '#d40000', size = 16, points = 12} = {}) => {
	comicShape(context, () => {
		for (let index = 0; index < points * 2; index++) {
			const angle = (index / (points * 2)) * Math.PI * 2;
			const distance = index % 2 ? radius * 0.7 : radius;
			context.lineTo(x + (Math.cos(angle) * distance), y + (Math.sin(angle) * distance));
		}

		context.closePath();
	}, {fill});
	drawText(context, text, x, y + 1, {font: `${size}px ${impact}`, color, align: 'center', baseline: 'middle'});
};

// A simple cartoon face, used for the family: the skin, the hair, glasses, a mustache, a mood, and how green it is from onion gum.
const drawFace = (context, x, y, radius, {skin = '#f5c9a0', hair = '#e8d070', hairStyle = 'short', glasses = false, mustache = false, mood = 'happy', green = 0} = {}) => {
	const faceColor = green > 0 ? mixColor(skin, '#7fbf3f', green) : skin;

	if (hairStyle === 'bun') {
		comicShape(context, () => {
			ellipse(context, x, y - (radius * 1.05), radius * 0.45, radius * 0.35);
		}, {fill: hair, lineWidth: 1.5});
	}

	if (hairStyle === 'long' || hairStyle === 'pigtails') {
		comicShape(context, () => {
			context.roundRect(x - (radius * 1.1), y - (radius * 0.6), radius * 2.2, radius * 1.5, radius * 0.5);
		}, {fill: hair, lineWidth: 1.5});
	}

	if (hairStyle === 'pigtails') {
		for (const side of [-1, 1]) {
			comicShape(context, () => {
				ellipse(context, x + (side * radius * 1.25), y + (radius * 0.2), radius * 0.3, radius * 0.5);
			}, {fill: hair, lineWidth: 1.5});
		}
	}

	comicShape(context, () => {
		ellipse(context, x, y, radius, radius * 1.08);
	}, {fill: faceColor, lineWidth: 2});

	if (hairStyle !== 'none') {
		comicShape(context, () => {
			context.arc(x, y - (radius * 0.1), radius * 1.02, Math.PI * 1.05, Math.PI * 1.95);
			context.quadraticCurveTo(x, y - (radius * 0.55), x - (radius * 0.98), y - (radius * 0.3));
			context.closePath();
		}, {fill: hair, lineWidth: 1.5});
	}

	if (hairStyle === 'spiky') {
		comicShape(context, () => {
			for (let index = 0; index <= 8; index++) {
				const angle = Math.PI * (1.08 + (index * 0.84 / 8));
				const distance = index % 2 ? radius * 1.45 : radius * 0.95;
				context.lineTo(x + (Math.cos(angle) * distance), y + (Math.sin(angle) * distance));
			}

			context.closePath();
		}, {fill: hair, lineWidth: 1.5});
	}

	const eyeY = y - (radius * 0.1);
	context.fillStyle = ink;
	context.strokeStyle = ink;
	context.lineWidth = 2;
	for (const side of [-1, 1]) {
		const eyeX = x + (side * radius * 0.38);
		if (mood === 'shock') {
			context.beginPath();
			context.arc(eyeX, eyeY, radius * 0.16, 0, Math.PI * 2);
			context.fillStyle = 'white';
			context.fill();
			context.stroke();
			context.fillStyle = ink;
			context.beginPath();
			context.arc(eyeX, eyeY, radius * 0.06, 0, Math.PI * 2);
			context.fill();
		} else if (mood === 'sick' || mood === 'cry') {
			context.beginPath();
			context.moveTo(eyeX - (radius * 0.12), eyeY - (radius * 0.06));
			context.lineTo(eyeX + (radius * 0.12), eyeY + (radius * 0.06));
			context.moveTo(eyeX - (radius * 0.12), eyeY + (radius * 0.06));
			context.lineTo(eyeX + (radius * 0.12), eyeY - (radius * 0.06));
			context.stroke();
		} else {
			context.beginPath();
			context.arc(eyeX, eyeY, radius * 0.08, 0, Math.PI * 2);
			context.fill();
		}

		if (mood === 'angry') {
			context.beginPath();
			context.moveTo(eyeX - (side * radius * 0.2), eyeY - (radius * 0.3));
			context.lineTo(eyeX + (side * radius * 0.15), eyeY - (radius * 0.18));
			context.stroke();
		}
	}

	if (mood === 'cry') {
		context.fillStyle = '#66aaff';
		for (const side of [-1, 1]) {
			context.beginPath();
			ellipse(context, x + (side * radius * 0.45), y + (radius * 0.25), radius * 0.07, radius * 0.16);
			context.fill();
		}
	}

	if (glasses) {
		context.lineWidth = 1.5;
		for (const side of [-1, 1]) {
			context.beginPath();
			context.arc(x + (side * radius * 0.38), eyeY, radius * 0.24, 0, Math.PI * 2);
			context.stroke();
		}

		context.beginPath();
		context.moveTo(x - (radius * 0.14), eyeY);
		context.lineTo(x + (radius * 0.14), eyeY);
		context.stroke();
	}

	const mouthY = y + (radius * 0.45);
	context.lineWidth = 2;
	context.beginPath();
	if (mood === 'happy') {
		context.arc(x, mouthY - (radius * 0.15), radius * 0.35, Math.PI * 0.15, Math.PI * 0.85);
		context.stroke();
	} else if (mood === 'shock') {
		ellipse(context, x, mouthY, radius * 0.16, radius * 0.22);
		context.fillStyle = '#7a1a1a';
		context.fill();
		context.stroke();
	} else if (mood === 'sick') {
		context.moveTo(x - (radius * 0.3), mouthY);
		for (let index = 1; index <= 6; index++) {
			context.lineTo(x - (radius * 0.3) + (index * radius * 0.1), mouthY + (index % 2 ? -radius * 0.08 : radius * 0.08));
		}

		context.stroke();
	} else {
		context.arc(x, mouthY + (radius * 0.2), radius * 0.3, Math.PI * 1.2, Math.PI * 1.8);
		context.stroke();
	}

	if (mustache) {
		comicShape(context, () => {
			ellipse(context, x - (radius * 0.2), mouthY - (radius * 0.2), radius * 0.25, radius * 0.1, -0.2);
			ellipse(context, x + (radius * 0.2), mouthY - (radius * 0.2), radius * 0.25, radius * 0.1, 0.2);
		}, {fill: hair, outline: undefined});
	}

	if (green > 0.5) {
		// Stink lines of onion.
		context.strokeStyle = '#4a8a2a';
		context.lineWidth = 2;
		for (const side of [-1, 1]) {
			context.beginPath();
			const startX = x + (side * radius * 1.3);
			context.moveTo(startX, y + (radius * 0.4));
			context.bezierCurveTo(startX + (side * 8), y, startX - (side * 8), y - (radius * 0.3), startX + (side * 4), y - (radius * 0.8));
			context.stroke();
		}
	}
};

// Mixes two hex colors with six digits each.
const mixColor = (from, to, amount) => {
	const parse = color => [1, 3, 5].map(index => Number.parseInt(color.slice(index, index + 2), 16));
	const start = parse(from);
	const end = parse(to);
	return `rgb(${start.map((value, index) => Math.round(value + ((end[index] - value) * amount))).join(', ')})`;
};

// A speech bubble with words in it, pointing down to the one who talks.
const drawBubble = (context, text, x, y, {width = 200, tailX = x, tailY = y + 60, size = 14} = {}) => {
	context.font = `bold ${size}px ${comicSans}`;
	const words = text.split(' ');
	const lines = [];
	let line = '';
	for (const word of words) {
		const candidate = line ? `${line} ${word}` : word;
		if (line && context.measureText(candidate).width > width - 20) {
			lines.push(line);
			line = word;
		} else {
			line = candidate;
		}
	}

	lines.push(line);
	const lineHeight = size + 3;
	const height = (lines.length * lineHeight) + 14;
	const left = clamp(x - (width / 2), 4, context.canvas.width - width - 4);
	const top = Math.max(4, y - height);
	comicShape(context, () => {
		context.roundRect(left, top, width, height, 12);
	}, {fill: 'white', lineWidth: 2});
	comicShape(context, () => {
		const baseX = clamp(tailX, left + 20, left + width - 20);
		context.moveTo(baseX - 8, top + height - 1);
		context.lineTo(tailX, tailY);
		context.lineTo(baseX + 8, top + height - 1);
	}, {fill: 'white', lineWidth: 2});
	context.fillStyle = 'white';
	context.fillRect(clamp(tailX, left + 20, left + width - 20) - 7, top + height - 3, 14, 4);
	for (const [index, text] of lines.entries()) {
		drawText(context, text, left + (width / 2), top + 8 + (index * lineHeight), {font: `bold ${size}px ${comicSans}`, align: 'center', baseline: 'top'});
	}
};

// Things that are drawn in more than one place: in the ads, on the kitchen table, and with my stuff.

// A Sea-Monkey like in the ad: a happy little person with a crown and a curly tail.
const drawAdSeaMonkey = (context, x, y, scale, {crown = true} = {}) => {
	comicShape(context, () => {
		context.moveTo(x - (5 * scale), y + (6 * scale));
		context.quadraticCurveTo(x - (9 * scale), y + (22 * scale), x + (2 * scale), y + (30 * scale));
		context.quadraticCurveTo(x + (14 * scale), y + (36 * scale), x + (10 * scale), y + (26 * scale));
		context.quadraticCurveTo(x + (4 * scale), y + (24 * scale), x + (6 * scale), y + (18 * scale));
		context.quadraticCurveTo(x + (8 * scale), y + (10 * scale), x + (5 * scale), y + (6 * scale));
		context.closePath();
	}, {fill: '#ffb3c1', shade: '#e0607a', lineWidth: 1.5});
	comicShape(context, () => {
		context.arc(x, y, 7 * scale, 0, Math.PI * 2);
	}, {fill: '#ffc8d2', lineWidth: 1.5});
	context.fillStyle = ink;
	context.beginPath();
	context.arc(x - (2.5 * scale), y - scale, 1.1 * scale, 0, Math.PI * 2);
	context.arc(x + (2.5 * scale), y - scale, 1.1 * scale, 0, Math.PI * 2);
	context.fill();
	context.lineWidth = 1.2;
	context.beginPath();
	context.arc(x, y + scale, 3 * scale, Math.PI * 0.2, Math.PI * 0.8);
	context.stroke();
	// Arms that wave.
	context.beginPath();
	context.moveTo(x - (5 * scale), y + (10 * scale));
	context.lineTo(x - (11 * scale), y + (5 * scale));
	context.moveTo(x + (5 * scale), y + (10 * scale));
	context.lineTo(x + (11 * scale), y + (5 * scale));
	context.stroke();
	if (crown) {
		comicShape(context, () => {
			context.moveTo(x - (6 * scale), y - (5 * scale));
			context.lineTo(x - (6 * scale), y - (12 * scale));
			context.lineTo(x - (3 * scale), y - (8 * scale));
			context.lineTo(x, y - (13 * scale));
			context.lineTo(x + (3 * scale), y - (8 * scale));
			context.lineTo(x + (6 * scale), y - (12 * scale));
			context.lineTo(x + (6 * scale), y - (5 * scale));
			context.closePath();
		}, {fill: '#ffd700', lineWidth: 1.2});
	}
};

// A real brine shrimp, as it looks under a magnifying glass: see-through, with a lot of legs, eyes on stalks, and a forked tail.
const drawShrimp = (context, x, y, scale, angle, phase) => {
	context.save();
	context.translate(x, y);
	context.rotate(angle);
	context.scale(scale, scale);
	context.lineWidth = 0.35;
	context.strokeStyle = 'rgba(90, 60, 40, 0.8)';
	// The legs, which beat in a wave.
	for (let index = 0; index < 11; index++) {
		const legX = -4 + (index * 0.8);
		const swing = Math.sin(phase + (index * 0.7)) * 0.8;
		for (const side of [-1, 1]) {
			context.beginPath();
			context.moveTo(legX, side * 0.7);
			context.quadraticCurveTo(legX + swing, side * 2, legX + (swing * 1.5), side * 2.8);
			context.stroke();
		}
	}

	// The body, in segments.
	context.fillStyle = 'rgba(230, 170, 120, 0.55)';
	for (let index = 0; index < 14; index++) {
		const segmentX = -5 + (index * 0.9);
		const width = index < 9 ? 1.1 : 1.1 - ((index - 9) * 0.14);
		context.beginPath();
		ellipse(context, segmentX, Math.sin(phase + index) * 0.1, 0.6, width);
		context.fill();
		context.stroke();
	}

	// The forked tail.
	context.beginPath();
	context.moveTo(7.5, 0);
	context.lineTo(9.5, -1);
	context.moveTo(7.5, 0);
	context.lineTo(9.5, 1);
	context.stroke();
	// The head, with two eyes on stalks and a third eye in the middle.
	context.beginPath();
	ellipse(context, -6, 0, 1.3, 1);
	context.fill();
	context.stroke();
	context.fillStyle = '#111111';
	for (const side of [-1, 1]) {
		context.beginPath();
		context.moveTo(-6.5, side * 0.5);
		context.lineTo(-7.6, side * 1.6);
		context.stroke();
		context.beginPath();
		context.arc(-7.8, side * 1.8, 0.45, 0, Math.PI * 2);
		context.fill();
	}

	context.beginPath();
	context.arc(-6.6, 0, 0.2, 0, Math.PI * 2);
	context.fill();
	context.restore();
};

// The X-Ray Specs as they really are: cardboard, with spirals printed on the lenses, and a feather inside.
const drawSpecs = (context, x, y, scale) => {
	context.save();
	context.translate(x, y);
	context.scale(scale, scale);
	comicShape(context, () => {
		context.roundRect(-60, -22, 120, 44, 8);
	}, {fill: '#f2f2f2', lineWidth: 2});
	for (const side of [-1, 1]) {
		comicShape(context, () => {
			context.arc(side * 28, 0, 17, 0, Math.PI * 2);
		}, {fill: '#ffffff', lineWidth: 2});
		context.strokeStyle = '#cc0000';
		context.lineWidth = 1.5;
		context.beginPath();
		for (let step = 0; step < 60; step++) {
			const angle = step * 0.35;
			const distance = step * 0.27;
			context.lineTo((side * 28) + (Math.cos(angle) * distance), Math.sin(angle) * distance);
		}

		context.stroke();
		// The feather between the lenses, which makes the double picture.
		context.strokeStyle = 'rgba(120, 100, 80, 0.6)';
		context.lineWidth = 0.8;
		context.beginPath();
		context.moveTo((side * 28) - 12, 8);
		context.lineTo((side * 28) + 12, -8);
		for (let barb = -10; barb <= 10; barb += 2) {
			context.moveTo((side * 28) + barb, -barb * 0.66);
			context.lineTo((side * 28) + barb + 3, (-barb * 0.66) + 4);
		}

		context.stroke();
	}

	drawText(context, 'X-RAY', 0, 18, {font: `10px ${impact}`, align: 'center'});
	context.strokeStyle = ink;
	context.lineWidth = 2;
	context.beginPath();
	context.moveTo(-60, -10);
	context.lineTo(-90, -14);
	context.moveTo(60, -10);
	context.lineTo(90, -14);
	context.stroke();
	context.restore();
};

// The clay ram of the Chia Pet, with grooves for the seeds.
const ramShape = {x: 300, y: 205, radiusX: 150, radiusY: 85};
const drawRam = (context, x, y, scale) => {
	context.save();
	context.translate(x, y);
	context.scale(scale, scale);
	const clay = '#c4683a';
	for (const legX of [-100, -50, 50, 100]) {
		comicShape(context, () => {
			context.roundRect(legX - 14, 40, 28, 70, 6);
		}, {fill: clay, shade: '#8a3a1a'});
	}

	comicShape(context, () => {
		ellipse(context, 0, 0, 150, 85);
	}, {fill: clay, shade: '#8a3a1a'});
	// The grooves where the seeds stick.
	context.strokeStyle = 'rgba(90, 40, 20, 0.6)';
	context.lineWidth = 3;
	for (let row = -60; row <= 40; row += 20) {
		const halfWidth = 140 * Math.sqrt(1 - ((row / 85) ** 2));
		context.beginPath();
		for (let groove = -halfWidth + 10; groove < halfWidth - 10; groove += 16) {
			context.moveTo(groove, row);
			context.lineTo(groove + 8, row + 6);
		}

		context.stroke();
	}

	comicShape(context, () => {
		ellipse(context, 165, -55, 48, 38, 0.3);
	}, {fill: clay, shade: '#8a3a1a'});
	comicShape(context, () => {
		ellipse(context, 140, -85, 22, 12, -0.6);
	}, {fill: '#a85030'});
	context.fillStyle = ink;
	context.beginPath();
	context.arc(175, -65, 5, 0, Math.PI * 2);
	context.fill();
	context.lineWidth = 2;
	context.beginPath();
	context.arc(200, -40, 10, 0.2, Math.PI * 0.8);
	context.stroke();
	context.restore();
};

// The whoopee cushion, from flat to round.
const drawCushion = (context, x, y, scale, inflation) => {
	const round = 0.35 + (inflation * 0.22);
	context.save();
	context.translate(x, y);
	context.scale(scale, scale);
	comicShape(context, () => {
		ellipse(context, 0, 0, 34, 34 * round);
		context.moveTo(-6, (-34 * round) + 2);
		context.lineTo(-10, -34 * round - 16);
		context.lineTo(10, -34 * round - 16);
		context.lineTo(6, (-34 * round) + 2);
	}, {fill: '#ff6fa0', shade: inflation > 0 ? '#c0306a' : undefined});
	context.restore();
};

const drawBuzzer = (context, x, y, scale) => {
	comicShape(context, () => {
		context.arc(x, y, 14 * scale, 0, Math.PI * 2);
	}, {fill: '#c8c8c8', shade: '#777777'});
	comicShape(context, () => {
		context.arc(x, y, 6 * scale, 0, Math.PI * 2);
	}, {fill: '#ffcc00'});
};

const drawGumPack = (context, x, y, scale, sticks = 5) => {
	context.save();
	context.translate(x, y);
	context.scale(scale, scale);
	for (let index = 0; index < sticks; index++) {
		comicShape(context, () => {
			context.rect(-30 + (index * 12), -42 + (index % 2 * 4), 10, 30);
		}, {fill: '#e8f8e0', lineWidth: 1});
	}

	comicShape(context, () => {
		context.rect(-34, -20, 68, 40);
	}, {fill: '#3cb878', shade: '#1a7a48'});
	context.fillStyle = 'white';
	context.fillRect(-34, -6, 68, 12);
	drawText(context, 'SPEARMINT', 0, 1, {font: `10px ${impact}`, align: 'center', baseline: 'middle', color: '#1a7a48'});
	context.restore();
};

// Tippy the turtle, in his cap, the one to draw for the art test.
const drawTippy = (context, x, y, scale, {color = true} = {}) => {
	context.save();
	context.translate(x, y);
	context.scale(scale, scale);
	const options = color ? {fill: '#6cbf4a', shade: '#2f7a1f'} : {fill: 'white'};
	for (const legX of [-30, 25]) {
		comicShape(context, () => {
			ellipse(context, legX, 28, 12, 9);
		}, options);
	}

	comicShape(context, () => {
		context.arc(0, 20, 45, Math.PI, 0);
		context.closePath();
	}, color ? {fill: '#9a6a2a', shade: '#5a3a10'} : {fill: 'white'});
	context.lineWidth = 1.5;
	context.beginPath();
	for (const [startX, startY, endX, endY] of [[-25, -5, -10, 18], [0, -24, 0, 18], [25, -5, 10, 18], [-40, 8, 40, 8]]) {
		context.moveTo(startX, startY);
		context.lineTo(endX, endY);
	}

	context.stroke();
	comicShape(context, () => {
		ellipse(context, 58, 0, 18, 16);
	}, options);
	comicShape(context, () => {
		context.arc(58, -6, 17, Math.PI * 1.05, Math.PI * 1.95);
		context.lineTo(84, -10);
		context.lineTo(76, -4);
		context.closePath();
	}, color ? {fill: '#dd2222'} : {fill: 'white'});
	context.fillStyle = ink;
	context.beginPath();
	context.arc(64, 0, 2.5, 0, Math.PI * 2);
	context.fill();
	context.lineWidth = 1.5;
	context.beginPath();
	context.arc(62, 6, 6, Math.PI * 0.1, Math.PI * 0.7);
	context.stroke();
	context.restore();
};

// The hand of a skeleton, with the tip of the pointing finger at the point, for the X-Ray Specs.
const drawBoneHand = (context, x, y, scale) => {
	context.save();
	context.translate(x, y);
	context.scale(scale, scale);
	context.rotate(-0.5);
	context.strokeStyle = '#f4f8ff';
	context.fillStyle = '#f4f8ff';
	context.lineCap = 'round';
	const bone = (fromX, fromY, toX, toY, width) => {
		context.lineWidth = width;
		context.beginPath();
		context.moveTo(fromX, fromY);
		context.lineTo(toX, toY);
		context.stroke();
		context.beginPath();
		context.arc(fromX, fromY, width * 0.7, 0, Math.PI * 2);
		context.arc(toX, toY, width * 0.7, 0, Math.PI * 2);
		context.fill();
	};

	// The pointing finger, then the other fingers curled, then the thumb, the palm, and the wrist.
	bone(0, 2, 0, 12, 3);
	bone(0, 14, 0, 24, 3.4);
	bone(0, 26, 1, 40, 3.8);
	for (const [index, fingerX] of [7, 13, 19].entries()) {
		bone(fingerX, 38 + (index * 2), fingerX + 1, 30 + (index * 2), 3);
		bone(fingerX + 1, 44 + (index * 2), fingerX, 54, 3.4);
	}

	bone(-6, 46, -14, 38, 3.4);
	bone(-14, 36, -18, 28, 3);
	for (const fingerX of [1, 8, 14, 19]) {
		bone(fingerX, 44, fingerX * 0.6 + 4, 66, 3.6);
	}

	bone(-5, 48, 4, 68, 3.6);
	bone(2, 72, 0, 100, 5);
	bone(14, 72, 16, 100, 5);
	context.restore();
};

// The pictures of the ads, in the flat colors and halftone dots of a comic.
const adPictures = {
	'sea-monkeys'(context) {
		comicShape(context, () => {
			context.arc(120, 82, 62, Math.PI * 1.85, Math.PI * 1.15);
			context.closePath();
		}, {fill: '#a8def5', shade: '#3a8fc0'});
		comicShape(context, () => {
			ellipse(context, 120, 34, 50, 7);
		}, {fill: '#d8f2ff'});
		drawAdSeaMonkey(context, 92, 70, 1.4);
		drawAdSeaMonkey(context, 122, 62, 1.8);
		drawAdSeaMonkey(context, 150, 76, 1.2);
		drawAdSeaMonkey(context, 108, 108, 0.8, {crown: false});
		context.strokeStyle = '#3a8fc0';
		context.lineWidth = 1;
		for (const [x, y, radius] of [[70, 90, 3], [76, 76, 2], [168, 100, 3], [160, 60, 2]]) {
			context.beginPath();
			context.arc(x, y, radius, 0, Math.PI * 2);
			context.stroke();
		}

		starburst(context, 205, 32, 30, 'WOW!', {size: 15});
		drawText(context, 'INSTANT LIFE!', 8, 20, {font: `16px ${impact}`, color: '#d40000'});
	},
	'x-ray-specs'(context) {
		drawFace(context, 62, 84, 36, {hairStyle: 'spiky', mood: 'shock'});
		for (const side of [-1, 1]) {
			comicShape(context, () => {
				context.arc(62 + (side * 14), 80, 11, 0, Math.PI * 2);
			}, {fill: 'white', lineWidth: 2.5});
			context.strokeStyle = '#d40000';
			context.lineWidth = 1.2;
			context.beginPath();
			for (let step = 0; step < 30; step++) {
				context.lineTo(62 + (side * 14) + (Math.cos(step * 0.5) * step * 0.33), 80 + (Math.sin(step * 0.5) * step * 0.33));
			}

			context.stroke();
		}

		comicShape(context, () => {
			context.roundRect(150, 60, 50, 60, 10);
			for (let finger = 0; finger < 4; finger++) {
				context.roundRect(151 + (finger * 12.5), 22 + (finger === 0 ? 10 : 0), 11, 44, 5);
			}

			context.roundRect(194, 74, 26, 11, 5);
		}, {fill: '#f5c9a0', shade: '#999999'});
		context.save();
		context.strokeStyle = 'white';
		context.lineCap = 'round';
		context.lineWidth = 3;
		context.beginPath();
		for (let finger = 0; finger < 4; finger++) {
			const fingerX = 156.5 + (finger * 12.5);
			context.moveTo(fingerX, 30 + (finger === 0 ? 10 : 0));
			context.lineTo(fingerX, 108);
		}

		context.moveTo(196, 80);
		context.lineTo(214, 80);
		context.stroke();
		context.restore();
		context.strokeStyle = '#ffcc00';
		context.lineWidth = 3;
		for (const offset of [-8, 8]) {
			context.beginPath();
			context.moveTo(100, 78 + offset);
			for (let step = 1; step <= 5; step++) {
				context.lineTo(100 + (step * 9), 78 + offset + (step % 2 ? -5 : 5));
			}

			context.stroke();
		}

		drawText(context, 'SEE BONES!', 120, 140, {font: `18px ${impact}`, color: '#d40000', align: 'center'});
	},
	chia(context) {
		drawRam(context, 112, 92, 0.4);
		comicShape(context, () => {
			for (let index = 0; index < 34; index++) {
				const angle = (index / 34) * Math.PI * 2;
				context.moveTo(112 + (Math.cos(angle) * 58) + 12, 88 + (Math.sin(angle) * 34));
				context.arc(112 + (Math.cos(angle) * 58), 88 + (Math.sin(angle) * 34), 12, 0, Math.PI * 2);
			}

			ellipse(context, 112, 88, 58, 34);
		}, {fill: '#3c9a2c', shade: '#1d5a14', lineWidth: 1});
		comicShape(context, () => {
			ellipse(context, 178, 70, 19, 15, 0.3);
		}, {fill: '#c4683a'});
		context.fillStyle = ink;
		context.beginPath();
		context.arc(182, 66, 2.5, 0, Math.PI * 2);
		context.fill();
		drawText(context, 'CH-CH-CH-CHIA!', 120, 22, {font: `20px ${impact}`, color: '#2a7a1a', align: 'center', stroke: 'white'});
	},
	whoopee(context) {
		comicShape(context, () => {
			context.rect(40, 100, 60, 10);
			context.rect(44, 110, 6, 34);
			context.rect(90, 110, 6, 34);
			context.rect(88, 50, 8, 52);
		}, {fill: '#a0662a', shade: '#5a3a10'});
		drawCushion(context, 66, 96, 0.6, 3);
		comicShape(context, () => {
			context.roundRect(48, 40, 34, 36, 6);
		}, {fill: '#5566aa', shade: '#223377'});
		drawFace(context, 65, 26, 16, {hair: '#553311', mood: 'shock', mustache: true});
		context.strokeStyle = ink;
		context.lineWidth = 2;
		for (const lineX of [52, 64, 76]) {
			context.beginPath();
			context.moveTo(lineX, 80);
			context.lineTo(lineX, 90);
			context.stroke();
		}

		starburst(context, 170, 75, 58, 'PFFFRRT!', {size: 19, points: 14});
	},
	buzzer(context) {
		comicShape(context, () => {
			context.rect(0, 70, 70, 30);
		}, {fill: '#3355bb', shade: '#112277'});
		comicShape(context, () => {
			context.rect(170, 70, 70, 30);
		}, {fill: '#888888', shade: '#444444'});
		comicShape(context, () => {
			context.roundRect(66, 66, 58, 38, 14);
			context.roundRect(116, 66, 58, 38, 14);
		}, {fill: '#f5c9a0', shade: '#d09060'});
		context.strokeStyle = '#ffcc00';
		context.lineWidth = 4;
		for (const [startX, startY, directionX, directionY] of [[120, 60, -1, -1], [120, 60, 1, -1], [120, 110, -1, 1], [120, 110, 1, 1], [120, 58, 0, -1]]) {
			context.beginPath();
			context.moveTo(startX, startY);
			for (let step = 1; step <= 4; step++) {
				context.lineTo(startX + (directionX * step * 8) + (step % 2 ? 6 : -6), startY + (directionY * step * 8));
			}

			context.stroke();
		}

		starburst(context, 196, 30, 30, 'BZZZT!', {size: 15});
		drawText(context, 'SHOCKING!', 40, 138, {font: `18px ${impact}`, color: '#d40000', align: 'center'});
	},
	'onion-gum'(context) {
		drawGumPack(context, 64, 90, 1.1);
		drawFace(context, 168, 82, 32, {hair: '#b5651d', hairStyle: 'pigtails', mood: 'sick', green: 0.9});
		starburst(context, 200, 30, 28, 'YUCK!', {size: 14, fill: '#9cff57'});
	},
	crystals(context) {
		comicShape(context, () => {
			ellipse(context, 120, 128, 70, 12);
		}, {fill: '#888888', shade: '#444444'});
		const towers = [[70, 128, 20, 60, -0.15], [96, 126, 24, 96, -0.05], [124, 126, 28, 112, 0], [152, 126, 22, 84, 0.08], [176, 128, 18, 56, 0.2]];
		for (const [baseX, baseY, width, height, tilt] of towers) {
			comicShape(context, () => {
				const topX = baseX + (tilt * height);
				context.moveTo(baseX - (width / 2), baseY);
				context.lineTo(topX - (width / 2), baseY - height + 12);
				context.lineTo(topX, baseY - height);
				context.lineTo(topX + (width / 2), baseY - height + 12);
				context.lineTo(baseX + (width / 2), baseY);
				context.closePath();
			}, {fill: '#b07cff', shade: '#5a2aa0'});
		}

		context.fillStyle = 'white';
		for (const [x, y] of [[100, 40], [140, 30], [180, 80], [64, 80]]) {
			context.beginPath();
			for (let index = 0; index < 8; index++) {
				const distance = index % 2 ? 2 : 8;
				context.lineTo(x + (Math.cos(index * Math.PI / 4) * distance), y + (Math.sin(index * Math.PI / 4) * distance));
			}

			context.fill();
		}

		drawText(context, 'ONLY 24 HOURS!', 10, 22, {font: `16px ${impact}`, color: '#d40000'});
	},
	draw(context) {
		drawTippy(context, 90, 90, 1);
		comicShape(context, () => {
			context.moveTo(176, 120);
			context.lineTo(216, 40);
			context.lineTo(226, 45);
			context.lineTo(186, 125);
			context.lineTo(172, 132);
			context.closePath();
		}, {fill: '#ffcc22'});
		starburst(context, 205, 128, 22, 'FREE!', {size: 12});
		drawText(context, 'DRAW ME!', 12, 26, {font: `20px ${impact}`, color: '#d40000'});
	},
	hovercraft(context) {
		comicShape(context, () => {
			context.rect(0, 110, 240, 40);
		}, {fill: '#5aaee8', shade: '#1a5a9a', outline: undefined});
		comicShape(context, () => {
			ellipse(context, 120, 100, 80, 16);
		}, {fill: '#222222'});
		comicShape(context, () => {
			context.moveTo(50, 92);
			context.lineTo(70, 66);
			context.lineTo(176, 66);
			context.lineTo(196, 92);
			context.closePath();
		}, {fill: '#e8322a', shade: '#9a0a0a'});
		comicShape(context, () => {
			context.arc(166, 56, 18, 0, Math.PI * 2);
		}, {fill: '#cccccc', shade: '#777777'});
		drawFace(context, 104, 50, 13, {hairStyle: 'spiky'});
		context.fillStyle = 'white';
		for (const [x, y, radius] of [[30, 112, 8], [18, 104, 6], [210, 112, 8], [224, 102, 6], [40, 100, 4], [200, 98, 4]]) {
			context.beginPath();
			context.arc(x, y, radius, 0, Math.PI * 2);
			context.fill();
		}

		context.strokeStyle = ink;
		context.lineWidth = 2;
		for (const lineY of [60, 72, 84]) {
			context.beginPath();
			context.moveTo(8, lineY);
			context.lineTo(40, lineY);
			context.stroke();
		}

		starburst(context, 206, 30, 28, 'ZOOM!', {size: 14});
	},
};

const drawAd = (canvas, id) => {
	const context = canvas.getContext('2d');
	// The canvas has twice the pixels of the drawing, so it is sharp on a phone too.
	context.scale(canvas.width / 240, canvas.width / 240);
	context.fillStyle = '#fffbe8';
	context.fillRect(0, 0, 240, 150);
	adPictures[id]?.(context);
};

// What really comes in the mail, drawn in the middle of a box.
const realityPictures = {
	'sea-monkeys'(context) {
		comicShape(context, () => {
			context.rect(-60, -30, 60, 70);
		}, {fill: '#f8f8f0'});
		drawText(context, 'INSTANT', -30, -8, {font: `11px ${impact}`, align: 'center'});
		drawText(context, 'LIFE', -30, 6, {font: `11px ${impact}`, align: 'center'});
		comicShape(context, () => {
			context.rect(10, -20, 54, 56);
		}, {fill: 'rgba(200, 230, 255, 0.6)'});
	},
	'x-ray-specs'(context) {
		drawSpecs(context, 0, 0, 0.7);
	},
	chia(context) {
		drawRam(context, -10, 0, 0.25);
		comicShape(context, () => {
			context.rect(40, 10, 24, 30);
		}, {fill: '#e8dcc0'});
	},
	whoopee(context) {
		drawCushion(context, 0, 10, 1, 0);
	},
	buzzer(context) {
		drawBuzzer(context, 0, 0, 1);
	},
	'onion-gum'(context) {
		drawGumPack(context, 0, 10, 0.9);
	},
	crystals(context) {
		comicShape(context, () => {
			context.moveTo(-50, -20);
			context.lineTo(-14, -20);
			context.lineTo(-18, 40);
			context.lineTo(-46, 40);
			context.closePath();
		}, {fill: 'rgba(230, 240, 255, 0.8)'});
		comicShape(context, () => {
			context.rect(0, 0, 30, 40);
		}, {fill: 'white'});
		comicShape(context, () => {
			ellipse(context, 50, 30, 14, 10);
		}, {fill: '#888888', shade: '#444444'});
	},
	draw(context) {
		comicShape(context, () => {
			context.rect(-40, -45, 80, 95);
		}, {fill: 'white'});
		drawTippy(context, -6, 0, 0.35, {color: false});
	},
	hovercraft(context) {
		comicShape(context, () => {
			context.rect(-50, -40, 100, 80);
		}, {fill: '#2a5aa8'});
		context.strokeStyle = 'white';
		context.lineWidth = 1;
		context.beginPath();
		ellipse(context, 0, 0, 34, 18);
		context.rect(-20, -8, 40, 16);
		context.stroke();
		drawText(context, 'PLANS', 0, 34, {font: `10px ${impact}`, color: 'white', align: 'center'});
	},
};

const drawReality = (context, id, x, y, scale = 1) => {
	context.save();
	context.translate(x, y);
	context.scale(scale, scale);
	realityPictures[id]?.(context);
	context.restore();
};

const bottles = [
	['a bottle of Solo', 1],
	['a bottle of Urge', 1],
	['a bottle of Pepsi Max', 1],
	['a bottle of Farris', 1],
	['a big bottle of Coca-Cola', 2],
	['a big bottle of Mozell', 2],
];

// The kitchen table, where coupons are cut out and mailed, and packages are opened.
const coupon = {x: 40, y: 40, width: 280, height: 150};
const perimeter = 2 * (coupon.width + coupon.height);
const segmentCount = 48;
const bubbleColumns = 10;
const bubbleRows = 5;

// The point at a distance along the dashed line, from the top left corner, clockwise, with the direction of the line there.
const perimeterPoint = distance => {
	const {x, y, width, height} = coupon;
	const along = ((distance % perimeter) + perimeter) % perimeter;
	if (along < width) {
		return {x: x + along, y, angle: 0};
	}

	if (along < width + height) {
		return {x: x + width, y: y + (along - width), angle: Math.PI / 2};
	}

	if (along < (2 * width) + height) {
		return {x: x + width - (along - width - height), y: y + height, angle: Math.PI};
	}

	return {x, y: y + height - (along - (2 * width) - height), angle: Math.PI * 1.5};
};

// The nearest point of the dashed line to a point, as the distance along the line, and how far away it is.
const nearestOnPerimeter = point => {
	const {x, y, width, height} = coupon;
	const isInside = point.x > x && point.x < x + width && point.y > y && point.y < y + height;
	let nearestX = clamp(point.x, x, x + width);
	let nearestY = clamp(point.y, y, y + height);
	if (isInside) {
		const distances = [point.y - y, x + width - point.x, y + height - point.y, point.x - x];
		const edge = distances.indexOf(Math.min(...distances));
		if (edge === 0) {
			nearestY = y;
		} else if (edge === 1) {
			nearestX = x + width;
		} else if (edge === 2) {
			nearestY = y + height;
		} else {
			nearestX = x;
		}
	}

	let along;
	if (nearestY === y && nearestX < x + width) {
		along = nearestX - x;
	} else if (nearestX === x + width && nearestY < y + height) {
		along = width + (nearestY - y);
	} else if (nearestY === y + height && nearestX > x) {
		along = width + height + (x + width - nearestX);
	} else {
		along = (2 * width) + height + (y + height - nearestY);
	}

	return {along, distance: Math.hypot(point.x - nearestX, point.y - nearestY), isInside};
};

const segmentMiddle = index => perimeterPoint((index + 0.5) * perimeter / segmentCount);

const bubbleCenter = index => ({
	x: 58 + ((index % bubbleColumns) * 27),
	y: 66 + (Math.floor(index / bubbleColumns) * 27),
});

// The drawing of the kitchen table.
const drawWood = context => {
	context.fillStyle = '#b07840';
	context.fillRect(0, 0, 360, 240);
	context.strokeStyle = 'rgba(90, 50, 20, 0.35)';
	context.lineWidth = 1.5;
	for (let row = 0; row < 12; row++) {
		context.beginPath();
		for (let x = 0; x <= 360; x += 20) {
			context.lineTo(x, 10 + (row * 20) + (Math.sin((x / 60) + (row * 1.7)) * 4));
		}

		context.stroke();
	}
};

const drawScissors = (context, scissors) => {
	context.save();
	context.translate(scissors.x, scissors.y);
	context.rotate(scissors.angle);
	const open = scissors.isOpen ? 0.35 : 0.1;
	for (const side of [-1, 1]) {
		context.save();
		context.rotate(side * open);
		comicShape(context, () => {
			context.moveTo(0, 0);
			context.lineTo(-30, side * -3);
			context.lineTo(-30, side * 2);
			context.closePath();
		}, {fill: '#d0d4d8', lineWidth: 1.5});
		comicShape(context, () => {
			ellipse(context, -40, side * 4, 9, 6);
		}, {fill: '#e8322a', lineWidth: 1.5});
		context.restore();
	}

	context.fillStyle = ink;
	context.beginPath();
	context.arc(-24, 0, 2, 0, Math.PI * 2);
	context.fill();
	context.restore();
};

const drawEnvelope = (context, id, offsetX, isStamped) => {
	context.save();
	context.translate(offsetX, 0);
	context.save();
	context.translate(110, 30);
	context.rotate(-0.05);
	context.fillStyle = 'white';
	context.fillRect(0, 0, 140, 50);
	drawText(context, '✂ ORDER NOW!', 70, 26, {font: `16px ${impact}`, color: '#d40000', align: 'center'});
	context.restore();
	comicShape(context, () => {
		context.rect(50, 60, 260, 150);
	}, {fill: '#f4f0e6'});
	context.strokeStyle = 'rgba(0, 0, 0, 0.25)';
	context.lineWidth = 1.5;
	context.beginPath();
	context.moveTo(50, 60);
	context.lineTo(180, 140);
	context.lineTo(310, 60);
	context.stroke();
	const isArtTest = id === 'draw';
	const lines = isArtTest ? ['Art Test Department', 'P.O. Box 77', 'Minneapolis, Minn.', 'U.S.A.'] : ['Wonder Novelty Co.', 'P.O. Box 1999', 'Chicago, Ill.', 'U.S.A.'];
	for (const [index, line] of lines.entries()) {
		drawText(context, line, 150, 160 + (index * 15), {font: `14px ${comicSans}`, color: '#1a3acc'});
	}

	// The coins, taped on, as the ad says to send cash.
	for (const [index, color] of ['#e0b030', '#c0c0c0', '#e0b030'].entries()) {
		comicShape(context, () => {
			context.arc(80 + (index * 22), 170, 10, 0, Math.PI * 2);
		}, {fill: color, lineWidth: 1});
	}

	context.fillStyle = 'rgba(255, 255, 220, 0.6)';
	context.fillRect(66, 164, 72, 12);
	if (isStamped) {
		comicShape(context, () => {
			context.rect(262, 70, 38, 44);
		}, {fill: '#d42a2a', lineWidth: 1});
		drawText(context, 'NORGE', 281, 86, {font: `9px ${impact}`, color: 'white', align: 'center'});
		drawText(context, '📯', 281, 104, {font: '14px sans-serif', align: 'center'});
	} else {
		context.setLineDash([4, 3]);
		context.strokeStyle = ink;
		context.strokeRect(262, 70, 38, 44);
		context.setLineDash([]);
		drawText(context, 'STAMP', 281, 95, {font: `9px ${impact}`, align: 'center'});
	}

	context.restore();
};

const junkMail = [
	['bills', 'Bills for Pappa. Lots of bills. Pappa sighs from the kitchen.'],
	['bills', 'A bill from Telenor for the Internet. Pappa will not be happy about all that surfing.'],
	['catalog', 'The new IKEA catalog. Mamma will be happy.'],
	['postcard', 'A postcard from Mormor’s friend in Spain. It is sunny there. It is not sunny here.'],
	['paper', 'Bergens Tidende, wet from the rain.'],
	['nothing', 'Nothing. Only rain in the mailbox.'],
	['postcard', 'A letter from Trond: “Did your stuff come yet? Mine did not either.”'],
	['catalog', 'An ad for a Nokia 3210, in a shiny envelope.'],
];

const drawWall = (context, color = '#dfe8d0') => {
	context.fillStyle = color;
	context.fillRect(0, 0, 640, 360);
	context.fillStyle = dots(context, 'rgba(0, 0, 0, 0.06)', 8, 1.5);
	context.fillRect(0, 0, 640, 360);
};

const drawDay = (context, day) => {
	comicShape(context, () => {
		context.rect(12, 12, 92, 34);
	}, {fill: '#fffbe8'});
	drawText(context, `DAY ${day}`, 58, 36, {font: `22px ${impact}`, color: '#d40000', align: 'center'});
};

// The tank of the Sea-Monkeys, the chairs of the Sunday dinner with Mormor, and the paper of the art test.
const tank = {left: 110, top: 60, right: 470, bottom: 330};
const royalNames = ['King Harald', 'Queen Sonja', 'Crown Prince Haakon', 'Princess Märtha Louise', 'Glitter II', 'Trond Jr.', 'Kaptein Sabeltann', 'Brunost', 'Mormor’s Favorite', 'Rocky’s Friend', 'Fiskepudding', 'Pondus', 'Bamse', 'Lillesøster’s', 'Tippy', 'Sir Wiggles'];
const chairs = [{x: 170, name: 'Pappa’s chair'}, {x: 330, name: 'Mormor’s chair'}, {x: 490, name: 'Lillesøster’s chair'}];
const paper = {left: 340, top: 104, right: 624, bottom: 346};

export default class extends GeoCitiesElement {
	#state;
	#toys;
	#xray;
	#tableContext;
	#mailboxContext;
	#stuffContext;
	#tableLoop;
	#stuffLoop;
	#piggyTimer;
	#mammaFor;

	// The ads of the page, by the ID of what they sell.
	#ads = new Map();

	#table = {
		mode: 'idle',
		id: undefined,
		segments: [],
		snips: [],
		scissors: undefined,
		scissorsIndex: -1,
		lastIndex: undefined,
		isPressed: false,
		tears: 0,
		bubbles: [],
		cursor: 0,
		showCursor: false,
		isRuined: false,
		animation: undefined,
	};

	#mail = {
		openUntil: 0,
		shown: undefined,
		drops: Array.from({length: 60}, () => ({x: Math.random() * 360, y: Math.random() * 240, speed: randomBetween(260, 380)})),
		weekClock: 0,
		postman: undefined,
		emptyChecks: 0,
		announced: new Set(),
	};

	#stuff = {
		selected: undefined,
		cursor: {x: 320, y: 220},
		showCursor: false,
		isPressed: false,
		tabs: new Map(),
		tools: [],
	};

	// The sounds of the toy, made in the browser. They are off until the visitor turns on the sound with its button.
	#audio = {
		context: undefined,
		output: undefined,
		isOn: false,
		noiseBuffer: undefined,
		// The audio of the element, which it only has in the handler of a click.
		start(sound) {
			if (!sound) {
				return false;
			}

			this.context = sound.context;
			this.output = sound.output;
			return true;
		},
		get isRunning() {
			return this.isOn && this.context?.state === 'running';
		},
		envelope(start, duration, volume) {
			const gain = new GainNode(this.context, {gain: 0});
			gain.gain.setValueAtTime(0, start);
			gain.gain.linearRampToValueAtTime(volume, start + Math.min(0.01, duration / 4));
			gain.gain.exponentialRampToValueAtTime(0.0001, start + duration);
			gain.connect(this.output);
			return gain;
		},
		// A short tone, which can slide to another pitch.
		beep(frequency, duration = 0.1, {type = 'square', volume = 0.06, when = 0, slideTo} = {}) {
			if (!this.isRunning) {
				return;
			}

			const start = this.context.currentTime + when;
			const oscillator = new OscillatorNode(this.context, {type, frequency});
			if (slideTo) {
				oscillator.frequency.exponentialRampToValueAtTime(slideTo, start + duration);
			}

			oscillator.connect(this.envelope(start, duration, volume));
			oscillator.start(start);
			oscillator.stop(start + duration + 0.02);
		},
		// A hiss through a filter, for pops, rips, snips, and the rain.
		noise(duration, {frequency = 2000, slideTo, q = 1, volume = 0.2, when = 0, type = 'bandpass'} = {}) {
			if (!this.isRunning) {
				return;
			}

			if (!this.noiseBuffer) {
				this.noiseBuffer = new AudioBuffer({length: this.context.sampleRate, sampleRate: this.context.sampleRate});
				const data = this.noiseBuffer.getChannelData(0);
				for (let index = 0; index < data.length; index++) {
					data[index] = (Math.random() * 2) - 1;
				}
			}

			const start = this.context.currentTime + when;
			const source = new AudioBufferSourceNode(this.context, {buffer: this.noiseBuffer, loop: true});
			const filter = new BiquadFilterNode(this.context, {type, frequency, Q: q});
			if (slideTo) {
				filter.frequency.exponentialRampToValueAtTime(slideTo, start + duration);
			}

			source.connect(filter).connect(this.envelope(start, duration, volume));
			source.start(start, Math.random() * 0.5);
			source.stop(start + duration + 0.02);
		},
		// A low, flapping rasp: a whoopee cushion, or a joy buzzer when it is faster.
		rasp(duration, {frequency = 80, flutter = 22, depth = 30, volume = 0.25, type = 'sawtooth', cutoff = 700} = {}) {
			if (!this.isRunning) {
				return;
			}

			const start = this.context.currentTime;
			const oscillator = new OscillatorNode(this.context, {type, frequency});
			oscillator.frequency.linearRampToValueAtTime(frequency * 0.7, start + duration);
			const wobble = new OscillatorNode(this.context, {type: 'square', frequency: flutter});
			const wobbleDepth = new GainNode(this.context, {gain: depth});
			wobble.connect(wobbleDepth).connect(oscillator.frequency);
			const filter = new BiquadFilterNode(this.context, {type: 'lowpass', frequency: cutoff});
			oscillator.connect(filter).connect(this.envelope(start, duration, volume));
			oscillator.start(start);
			wobble.start(start);
			oscillator.stop(start + duration + 0.02);
			wobble.stop(start + duration + 0.02);
		},
	};

	#sounds = {
		coin: () => {
			this.#audio.beep(1568, 0.08, {type: 'triangle', volume: 0.08});
			this.#audio.beep(2093, 0.25, {type: 'triangle', volume: 0.08, when: 0.07});
		},
		clunk: () => {
			this.#audio.beep(90, 0.1, {volume: 0.08});
			this.#audio.noise(0.2, {frequency: 300, type: 'lowpass', volume: 0.2});
		},
		snip: () => {
			this.#audio.noise(0.04, {frequency: 5000, q: 3, volume: 0.25});
		},
		rip: () => {
			this.#audio.noise(0.35, {frequency: 700, slideTo: 3000, q: 0.7, volume: 0.35});
		},
		pop: () => {
			this.#audio.noise(0.03, {frequency: randomBetween(1500, 3000), q: 1.2, volume: 0.6});
			this.#audio.beep(randomBetween(250, 450), 0.04, {type: 'sine', volume: 0.12});
		},
		pfft: () => {
			this.#audio.noise(0.6, {frequency: 500, slideTo: 120, type: 'lowpass', volume: 0.15});
		},
		lick: () => {
			this.#audio.noise(0.25, {frequency: 1200, slideTo: 400, q: 2, volume: 0.15});
		},
		ding: () => {
			this.#audio.beep(988, 0.3, {type: 'triangle', volume: 0.07});
			this.#audio.beep(784, 0.5, {type: 'triangle', volume: 0.07, when: 0.25});
		},
		splash: () => {
			this.#audio.noise(0.5, {frequency: 900, slideTo: 300, type: 'lowpass', volume: 0.2});
		},
		puff: () => {
			this.#audio.noise(0.4, {frequency: 400, type: 'lowpass', volume: 0.18});
		},
		ratchet: () => {
			for (let index = 0; index < 3; index++) {
				this.#audio.beep(1800, 0.02, {volume: 0.05, when: index * 0.06});
			}
		},
		jingle: () => {
			// Ch, ch, ch, chia!
			for (let index = 0; index < 3; index++) {
				this.#audio.noise(0.07, {frequency: 4500, q: 2, volume: 0.35, when: index * 0.18});
			}

			this.#audio.noise(0.08, {frequency: 4500, q: 2, volume: 0.35, when: 0.6});
			this.#audio.beep(660, 0.18, {type: 'square', volume: 0.06, when: 0.66});
			this.#audio.beep(880, 0.35, {type: 'square', volume: 0.06, when: 0.85});
		},
		vacuum: () => {
			this.#audio.noise(2.5, {frequency: 200, slideTo: 1400, type: 'lowpass', volume: 0.3});
			this.#audio.beep(110, 2.5, {type: 'sawtooth', volume: 0.04, slideTo: 330});
		},
	};

	connected() {
		const {pant, mormor, sound, mamma, mammaText, mammaPappa, mammaPromise, mammaCancel, tableCanvas, tableAction, tablePopAll, mailboxCanvas, mailboxCheck, mailboxWait, stuffCanvas, reset} = this.parts;
		this.#tableContext = tableCanvas.getContext('2d');
		this.#mailboxContext = mailboxCanvas.getContext('2d');
		this.#stuffContext = stuffCanvas.getContext('2d');
		this.#xray = this.#makeXray();

		const saved = this.stored('orders', {});
		const savedItems = typeof saved.items === 'object' && saved.items !== null ? saved.items : {};
		this.#state = {
			balance: Number.isInteger(saved.balance) ? clamp(saved.balance, 0, 9999) : 120,
			// The weeks are counted on from week 37 of 1999, when the comic came out.
			week: Number.isInteger(saved.week) ? clamp(saved.week, 37, 9999) : 37,
			items: {},
			approved: Array.isArray(saved.approved) ? saved.approved.filter(id => Object.hasOwn(catalog, id)) : [],
			mormorWeek: Number.isInteger(saved.mormorWeek) ? clamp(saved.mormorWeek, 0, Number.isInteger(saved.week) ? saved.week : 37) : 0,
			letter: typeof saved.letter === 'object' && saved.letter !== null && Number.isInteger(saved.letter.arrives) ? {arrives: saved.letter.arrives, ink: Number(saved.letter.ink) || 0, isRead: Boolean(saved.letter.isRead)} : undefined,
			bottlesLeft: 6,
			pranks: 0,
		};

		for (const id of catalogOrder) {
			const item = savedItems[id];
			if (item && ['mailed', 'table', 'mine'].includes(item.status) && Number.isInteger(item.ordered) && Number.isInteger(item.arrives)) {
				this.#state.items[id] = {status: item.status, ordered: item.ordered, arrives: item.arrives};
			}
		}

		// After the state, as the art test starts with the letter when it was read.
		this.#toys = this.#makeToys();

		for (const article of this.querySelectorAll('[data-mail-order-ad]')) {
			const id = article.dataset.mailOrderAd;
			const ad = {
				article,
				canvas: article.querySelector('[data-part="art"]'),
				coupon: article.querySelector('[data-part="coupon"]'),
				button: article.querySelector('[data-part="cut"]'),
				note: article.querySelector('[data-part="note"]'),
			};
			this.#ads.set(id, ad);
			drawAd(ad.canvas, id);
			this.on(ad.button, 'click', () => {
				this.#order(id);
			});
		}

		this.on(pant, 'click', () => {
			this.#returnBottle();
		});
		this.on(mormor, 'click', () => {
			this.#visitMormor();
		});
		this.on(sound, 'click', () => {
			const audio = this.#audio;
			audio.isOn = !audio.isOn && audio.start(this.sound());
			if (audio.isOn) {
				audio.context.resume().then(() => {
					this.#sounds.coin();
				}).catch(() => {});
			}

			setPressed(sound, audio.isOn);
		});

		this.on(mammaPappa, 'click', () => {
			const answer = catalog[this.#mammaFor]?.pappa;
			if (!answer) {
				return;
			}

			if (answer.isYes) {
				this.#approve(answer.text);
			} else {
				mammaText.textContent = answer.text;
				mammaPappa.disabled = true;
			}
		});
		this.on(mammaPromise, 'click', () => {
			this.#approve('Mamma: “Ja, ja. But your room is clean by Saturday.”');
		});
		const cancelMamma = () => {
			const id = this.#mammaFor;
			this.#closeMamma();
			this.#ads.get(id)?.button.focus();
		};

		this.on(mammaCancel, 'click', () => {
			cancelMamma();
		});
		this.on(mamma, 'keydown', event => {
			if (event.key === 'Escape') {
				cancelMamma();
			}
		});

		// The kitchen table.
		this.#tableLoop = this.loop(() => {
			if (this.#table.animation && this.#animationProgress() >= 1) {
				const {done} = this.#table.animation;
				this.#table.animation = undefined;
				done();
			}

			this.#drawTable();
		}, {while: () => this.#table.animation !== undefined, target: tableCanvas});

		this.on(tableCanvas, 'pointerdown', event => {
			if (event.button !== 0) {
				return;
			}

			const point = canvasPoint(tableCanvas, event);
			tableCanvas.setPointerCapture(event.pointerId);
			this.#table.isPressed = true;
			this.#table.showCursor = false;
			if (this.#table.mode === 'cut') {
				this.#table.lastIndex = undefined;
				this.#cutAt(point);
			} else if (this.#table.mode === 'envelope') {
				this.#mailIt();
			} else if (this.#table.mode === 'package') {
				this.#tear();
			} else if (this.#table.mode === 'bubbles') {
				this.#popAt(point);
			}

			this.#drawTable();
		});
		this.on(tableCanvas, 'pointermove', event => {
			if (this.#table.mode === 'cut') {
				this.#cutAt(canvasPoint(tableCanvas, event));
				this.#drawTable();
			} else if (this.#table.mode === 'bubbles' && this.#table.isPressed) {
				this.#popAt(canvasPoint(tableCanvas, event));
			}
		});
		for (const type of ['pointerup', 'pointercancel']) {
			this.on(tableCanvas, type, () => {
				this.#table.isPressed = false;
				this.#table.lastIndex = undefined;
			});
		}

		this.on(tableCanvas, 'keydown', event => {
			const isPress = event.key === ' ' || event.key === 'Enter';
			const moves = {ArrowRight: [1, 0], ArrowLeft: [-1, 0], ArrowDown: [0, 1], ArrowUp: [0, -1]};
			let isHandled = true;
			if (this.#table.mode === 'cut' && (isPress || event.key in moves)) {
				this.#cutNext(['ArrowLeft', 'ArrowUp'].includes(event.key) ? -1 : 1);
			} else if (this.#table.mode === 'envelope' && isPress) {
				this.#mailIt();
			} else if (this.#table.mode === 'package' && isPress) {
				this.#tear();
			} else if (this.#table.mode === 'bubbles' && event.key in moves) {
				const [columnStep, rowStep] = moves[event.key];
				const column = clamp((this.#table.cursor % bubbleColumns) + columnStep, 0, bubbleColumns - 1);
				const row = clamp(Math.floor(this.#table.cursor / bubbleColumns) + rowStep, 0, bubbleRows - 1);
				this.#table.cursor = (row * bubbleColumns) + column;
				this.#table.showCursor = true;
			} else if (this.#table.mode === 'bubbles' && isPress) {
				this.#table.showCursor = true;
				this.#pop(this.#table.cursor);
			} else if (this.#table.mode === 'reveal' && isPress) {
				this.#putAway();
			} else {
				isHandled = false;
			}

			if (isHandled) {
				event.preventDefault();
				this.#drawTable();
			}
		});
		this.on(tableAction, 'click', () => {
			this.#tableAction();
		});
		this.on(tablePopAll, 'click', () => {
			this.#popAll();
		});

		// The mailbox.
		this.loop(seconds => {
			this.#stepMailbox(seconds);
		}, {while: () => !this.reducedMotion, target: mailboxCanvas});
		this.on(mailboxCanvas, 'click', () => {
			this.#checkMailbox();
		});
		this.on(mailboxCanvas, 'keydown', event => {
			if (event.key === ' ' || event.key === 'Enter') {
				event.preventDefault();
				this.#checkMailbox();
			}
		});
		this.on(mailboxCheck, 'click', () => {
			this.#checkMailbox();
		});
		this.on(mailboxWait, 'click', () => {
			if (!this.#advanceWeek()) {
				this.#sayMail(`Week ${weekOfYear(this.#state.week)}. ${this.#hasMail() ? 'The flag is still up. Check the mailbox!' : ['It rains.', 'It rains a lot.', 'It is still raining.', 'Rain. Bergen.'][this.#state.week % 4]}`);
			}
		});

		// My stuff.
		this.#stuffLoop = this.loop(seconds => {
			if (this.#stuff.selected) {
				this.#toys[this.#stuff.selected].step?.(seconds);
			}

			this.#drawStuff();
		}, {while: () => !this.reducedMotion && this.#stuff.selected !== undefined, target: stuffCanvas});

		const stuffPointer = (type, point) => {
			if (this.#stuff.selected) {
				this.#toys[this.#stuff.selected].pointer?.(type, point, this.#stuff.isPressed);
			}
		};

		this.on(stuffCanvas, 'pointerdown', event => {
			if (event.button !== 0) {
				return;
			}

			stuffCanvas.setPointerCapture(event.pointerId);
			this.#stuff.isPressed = true;
			this.#stuff.showCursor = false;
			stuffPointer('down', canvasPoint(stuffCanvas, event));
			this.#afterInput();
		});
		this.on(stuffCanvas, 'pointermove', event => {
			stuffPointer('move', canvasPoint(stuffCanvas, event));
			if (this.reducedMotion) {
				this.#drawStuff();
			}
		});
		for (const type of ['pointerup', 'pointercancel']) {
			this.on(stuffCanvas, type, event => {
				this.#stuff.isPressed = false;
				stuffPointer('up', canvasPoint(stuffCanvas, event));
				this.#afterInput();
			});
		}

		// The arrow keys move a cursor on the canvas, Space or Enter taps there, and Shift with the arrow keys drags.
		this.on(stuffCanvas, 'keydown', event => {
			const moves = {ArrowRight: [1, 0], ArrowLeft: [-1, 0], ArrowDown: [0, 1], ArrowUp: [0, -1]};
			if (!this.#stuff.selected) {
				return;
			}

			if (event.key in moves) {
				const [moveX, moveY] = moves[event.key];
				this.#stuff.cursor = {x: clamp(this.#stuff.cursor.x + (moveX * 12), 0, 640), y: clamp(this.#stuff.cursor.y + (moveY * 12), 0, 360)};
				this.#stuff.showCursor = true;
				this.#stuff.isPressed = event.shiftKey;
				stuffPointer('move', this.#stuff.cursor);
				this.#stuff.isPressed = false;
			} else if (event.key === ' ' || event.key === 'Enter') {
				this.#stuff.showCursor = true;
				this.#stuff.isPressed = true;
				stuffPointer('down', this.#stuff.cursor);
				this.#stuff.isPressed = false;
				stuffPointer('up', this.#stuff.cursor);
			} else {
				return;
			}

			event.preventDefault();
			this.#afterInput();
		});
		this.on(stuffCanvas, 'blur', () => {
			this.#drawStuff();
		});

		this.on(reset, 'click', () => {
			this.#startOver();
		});

		this.#renderBalance();
		this.#goIdle();
		this.#renderAds();
		this.#renderTabs();
		const firstOwned = catalogOrder.find(id => this.#state.items[id]?.status === 'mine');
		if (firstOwned) {
			this.#stuff.selected = firstOwned;
			setPressed(this.#stuff.tabs.get(firstOwned), true);
		}

		this.#renderTools();
		this.#drawTable();
		this.#drawMailbox();
		this.#drawStuff();
	}

	// The lens of the X-Ray Specs listens to the whole page, so it goes away with the toy.
	disconnected() {
		if (this.#xray.isOn) {
			this.#xray.off();
		}
	}

	// The control that takes the place of the one that went away while it had the focus: the kitchen table while the letter goes in the mail, “Take It Out” for “Pop All”, the promise when Pappa says no, and my stuff for a tool that turns itself off, like “Add Water Purifier”, or that a timer turns off, like “Start It!” when Mamma comes home, so the keyboard does not lose its place. Only the tools and the tabs of my stuff are removed while they can have the focus.
	focusReplacement(control) {
		const {tableCanvas, tableAction, tablePopAll, mammaPappa, mammaPromise, stuffCanvas, stuffTools} = this.parts;
		if (control === tableAction) {
			return tableCanvas;
		}

		if (control === tablePopAll) {
			return tableAction;
		}

		if (control === mammaPappa) {
			return mammaPromise;
		}

		if (control.parentElement === stuffTools || !control.isConnected) {
			return stuffCanvas;
		}

		return super.focusReplacement(control);
	}

	// From the first message on, a status keeps room for its messages, so it does not collapse while it is empty for a frame.
	say(text, status) {
		status.dataset.state = 'said';
		super.say(text, status);
	}

	#sayBank(text) {
		this.say(text, this.parts.bankStatus);
	}

	#sayTable(text) {
		this.say(text, this.parts.tableStatus);
	}

	#sayMail(text) {
		this.say(text, this.parts.mailboxStatus);
	}

	#sayStuff(text) {
		this.say(text, this.parts.stuffStatus);
	}

	#persist() {
		const {balance, week, items, approved, mormorWeek, letter} = this.#state;
		this.store('orders', {balance, week, items, approved, mormorWeek, letter});
	}

	// Scrolls to a section and focuses it, like a link to it, so the keyboard goes on from there. It goes to the middle of the screen, so on a phone the status line under a canvas is in view too, and not under the bar at the bottom.
	#goTo(element) {
		element.scrollIntoView({behavior: this.reducedMotion ? 'auto' : 'smooth', block: 'center'});
		element.focus({preventScroll: true});
	}

	// Goes on to the next step after a pause, unless the visitor went somewhere else with the focus in the meantime.
	#goOnFrom(section, element) {
		if (section.contains(document.activeElement) || document.activeElement === document.body) {
			this.#goTo(element);
		}
	}

	// The piggy bank.

	#shakePiggy() {
		this.parts.piggy.dataset.state = 'shaking';
		clearTimeout(this.#piggyTimer);
		this.#piggyTimer = setTimeout(() => {
			delete this.parts.piggy.dataset.state;
		}, 700);
	}

	#renderBalance() {
		this.parts.balance.textContent = `${this.#state.balance} kr`;
	}

	#earn(amount) {
		this.#state.balance += amount;
		this.#persist();
		this.#renderBalance();
		this.#shakePiggy();
		this.#sounds.coin();
	}

	#returnBottle() {
		if (this.#state.bottlesLeft <= 0) {
			this.#sayBank('No more bottles in the basement. Pappa drinks more next week.');
			return;
		}

		this.#state.bottlesLeft--;
		const [bottle, amount] = randomItem(bottles);
		this.#sounds.clunk();
		this.#earn(amount);
		this.#sayBank(`The machine at Rema takes ${bottle}: ${amount} kr! ${this.#state.bottlesLeft === 0 ? 'That was the last one.' : `${this.#state.bottlesLeft} bottles left in the basement.`}`);
	}

	#visitMormor() {
		const weeksSince = this.#state.week - this.#state.mormorWeek;
		if (this.#state.pranks > 0) {
			this.#state.pranks = 0;
			this.#sayBank('Mormor: “Hmpf. After that cushion, you get waffles, but no money.” Fair.');
			return;
		}

		if (weeksSince < 3) {
			this.#sayBank(`Mormor gives me waffles with brown cheese, but no money. She gave me some ${weeksSince === 0 ? 'this week' : (weeksSince === 1 ? 'last week' : `${weeksSince} weeks ago`)}.`);
			return;
		}

		this.#state.mormorWeek = this.#state.week;
		this.#earn(50);
		this.#sayBank('Mormor slips me a 50-lapp: “Til godteri. Do not tell Mamma.” 50 kr in the piggy bank!');
	}

	// Mamma, who has to say yes to some things first.

	#closeMamma() {
		this.parts.mamma.hidden = true;
		this.#mammaFor = undefined;
	}

	#askMamma(id) {
		this.#mammaFor = id;
		this.parts.mammaText.textContent = `Mamma: “${catalog[id].mamma}”`;
		this.parts.mammaPappa.disabled = false;
		this.parts.mamma.hidden = false;
		this.parts.mammaPappa.focus({preventScroll: true});
		this.parts.mamma.scrollIntoView({behavior: this.reducedMotion ? 'auto' : 'smooth', block: 'nearest'});
	}

	#approve(message) {
		const id = this.#mammaFor;
		this.#closeMamma();
		this.#state.approved.push(id);
		this.#persist();
		this.#startCutting(id, message);
	}

	// The ads and their coupons.

	#orderCost(id) {
		const price = Number(this.#ads.get(id)?.article.dataset.mailOrderPrice) || 0;
		return price + (price === 0 ? stampPrice : postage);
	}

	#noteFor(id) {
		const item = this.#state.items[id];
		if (!item) {
			if (this.#table.id === id && this.#table.mode === 'cut') {
				return 'On the kitchen table, being cut out.';
			}

			if (this.#table.id === id && this.#table.mode === 'envelope') {
				return 'In the envelope. Lick the stamp!';
			}

			return 'Allow 6 to 8 weeks for delivery.';
		}

		if (item.status === 'mailed') {
			if (item.arrives <= this.#state.week) {
				return 'It came! Check the mailbox!';
			}

			const weeks = this.#state.week - item.ordered;
			return weeks === 0 ? 'Mailed this week. Allow 6 to 8 weeks.' : `In the mail: week ${weeks} of 6 to 8.`;
		}

		if (item.status === 'table') {
			return 'On the kitchen table. Open it!';
		}

		return 'Got it! It is with my stuff.';
	}

	#renderAds() {
		for (const [id, ad] of this.#ads) {
			const isCut = Boolean(this.#state.items[id]) || (this.#table.id === id && this.#table.mode === 'envelope');
			if (isCut) {
				ad.coupon.dataset.state = 'cut';
			} else {
				delete ad.coupon.dataset.state;
			}

			ad.button.disabled = isCut;
			ad.note.textContent = this.#noteFor(id);
		}
	}

	#order(id) {
		this.#closeMamma();
		if (['package', 'bubbles', 'reveal', 'mailing'].includes(this.#table.mode)) {
			this.#sayTable('First open the package on the kitchen table!');
			this.#goTo(this.parts.tableCanvas);
			return;
		}

		if (this.#state.items[id]) {
			return;
		}

		const cost = this.#orderCost(id);
		if (this.#state.balance < cost) {
			this.#shakePiggy();
			this.#sounds.pfft();
			this.#sayBank(`The ${catalog[id].name} costs ${cost} kr with postage, and the piggy bank has only ${this.#state.balance} kr. Return bottles, or visit Mormor.`);
			return;
		}

		if (catalog[id].mamma && !this.#state.approved.includes(id)) {
			this.#askMamma(id);
			return;
		}

		this.#startCutting(id);
	}

	// The kitchen table, where coupons are cut out and mailed, and packages are opened.

	#setTableAction(label, isEnabled) {
		this.parts.tableAction.textContent = label;
		this.parts.tableAction.disabled = !isEnabled;
	}

	#animateTable(duration, done = () => {}) {
		if (this.reducedMotion) {
			done();
			this.#drawTable();
			return;
		}

		this.#table.animation = {start: performance.now(), duration, done};
		this.#tableLoop.start();
	}

	#animationProgress() {
		return this.#table.animation ? clamp((performance.now() - this.#table.animation.start) / this.#table.animation.duration, 0, 1) : 1;
	}

	#startCutting(id, message) {
		this.#table.mode = 'cut';
		this.#table.id = id;
		this.#table.segments = Array.from({length: segmentCount}, () => false);
		this.#table.snips = [];
		this.#table.scissors = undefined;
		this.#table.scissorsIndex = -1;
		this.#table.lastIndex = undefined;
		this.parts.tablePopAll.hidden = true;
		this.#setTableAction('Lick the Stamp and Mail It', false);
		this.#renderAds();
		this.#drawTable();
		this.#sayTable(`${message ? `${message} ` : ''}Cut along the dashed line with the scissors: drag all the way around the coupon.`);
		this.#goTo(this.parts.tableCanvas);
	}

	#finishCut() {
		this.#table.mode = 'envelope';
		this.#table.scissors = undefined;
		this.#setTableAction('Lick the Stamp and Mail It', true);
		this.#renderAds();
		const cost = this.#orderCost(this.#table.id);
		this.#sayTable(`Cut out! It goes in an envelope, with ${cost} kr from the piggy bank taped to it.${this.#table.snips.length > 0 ? ' Half the address is cut off, so the post office has to guess.' : ''} Lick the stamp, and mail it!`);
	}

	#cutSegment(index) {
		if (this.#table.segments[index]) {
			return;
		}

		this.#table.segments[index] = true;
		this.#sounds.snip();
		if (this.#table.segments.every(Boolean)) {
			this.#finishCut();
		}
	}

	#snipCoupon(point) {
		if (this.#table.snips.some(snip => Math.hypot(snip.x - point.x, snip.y - point.y) < 25)) {
			return;
		}

		this.#table.snips.push({x: point.x, y: point.y, angle: randomBetween(-0.6, 0.6)});
		this.#sounds.snip();
		if (this.#table.snips.length === 1) {
			this.#sayTable('Oops! You cut into the coupon. There goes half of the address. Stay on the dashed line!');
		}
	}

	#cutAt(point) {
		const {along, distance, isInside} = nearestOnPerimeter(point);
		this.#table.scissors = {x: point.x, y: point.y, angle: perimeterPoint(along).angle, isOpen: !this.#table.scissors?.isOpen};
		if (!this.#table.isPressed) {
			return;
		}

		if (distance <= 14) {
			const index = Math.floor(along / perimeter * segmentCount) % segmentCount;
			if (this.#table.lastIndex !== undefined) {
				const forward = (index - this.#table.lastIndex + segmentCount) % segmentCount;
				const backward = (this.#table.lastIndex - index + segmentCount) % segmentCount;
				if (Math.min(forward, backward) <= 4) {
					const direction = forward <= backward ? 1 : -1;
					for (let step = this.#table.lastIndex; step !== index; step = (step + direction + segmentCount) % segmentCount) {
						this.#cutSegment(step);
					}
				}
			}

			if (this.#table.mode === 'cut') {
				this.#cutSegment(index);
			}

			this.#table.lastIndex = index;
			this.#table.scissorsIndex = index;
		} else if (isInside && distance > 20) {
			this.#table.lastIndex = undefined;
			this.#snipCoupon(point);
		}
	}

	// Cuts the next piece of the dashed line with the keyboard, forward or back.
	#cutNext(direction) {
		for (let step = 1; step <= segmentCount; step++) {
			const index = (((this.#table.scissorsIndex + (direction * step)) % segmentCount) + segmentCount) % segmentCount;
			if (!this.#table.segments[index]) {
				this.#table.scissorsIndex = index;
				const middle = segmentMiddle(index);
				this.#table.scissors = {x: middle.x, y: middle.y, angle: middle.angle, isOpen: !this.#table.scissors?.isOpen};
				this.#cutSegment(index);
				return;
			}
		}
	}

	#mailIt() {
		if (this.#table.mode !== 'envelope') {
			return;
		}

		const id = this.#table.id;
		const cost = this.#orderCost(id);
		if (this.#state.balance < cost) {
			this.#sayTable('The money is gone from the piggy bank! Return bottles, or visit Mormor, and then mail it.');
			return;
		}

		this.#state.balance -= cost;
		const weeks = randomInteger(6, 8) + (this.#table.snips.length > 0 ? 2 : 0);
		this.#state.items[id] = {status: 'mailed', ordered: this.#state.week, arrives: this.#state.week + weeks};
		this.#persist();
		this.#renderBalance();
		this.#shakePiggy();
		this.#sounds.lick();
		this.#sounds.coin();
		this.#table.mode = 'mailing';
		this.#setTableAction('Lick the Stamp and Mail It', false);
		this.#renderAds();
		this.#drawMailbox();
		this.#sayTable(`Slurp! The stamp is on, and the letter is in the red mailbox at the corner. ${cost} kr from the piggy bank. Now: allow 6 to 8 weeks for delivery. ${this.reducedMotion ? 'Press' : 'Watch the mailbox, or press'} “Wait a Week”.`);
		this.#animateTable(900, () => {
			this.#goIdle();
			if (this.#table.mode === 'idle') {
				this.#goOnFrom(this.parts.table, this.parts.mailboxCanvas);
			}
		});
	}

	#startPackage(id) {
		this.#table.mode = 'package';
		this.#table.id = id;
		this.#table.tears = 0;
		this.parts.tablePopAll.hidden = true;
		this.#setTableAction('Take It Out', false);
		this.#sayTable(`A package for Sindre, with stamps from America! It must be the ${catalog[id].name}. Click it, or press Space, to tear off the brown paper.`);
		this.#drawTable();
	}

	// Goes on with the next package on the table, or waits for the next coupon.
	#goIdle() {
		this.#table.animation = undefined;
		const next = catalogOrder.find(id => this.#state.items[id]?.status === 'table');
		if (next) {
			this.#startPackage(next);
			return;
		}

		this.#table.mode = 'idle';
		this.#table.id = undefined;
		this.parts.tablePopAll.hidden = true;
		this.#setTableAction('Lick the Stamp and Mail It', false);
		this.#drawTable();
	}

	#tear() {
		this.#table.tears++;
		this.#sounds.rip();
		if (this.#table.tears >= 4) {
			this.#table.mode = 'bubbles';
			this.#table.bubbles = Array.from({length: bubbleColumns * bubbleRows}, () => false);
			this.#table.cursor = 0;
			this.#table.isRuined = false;
			this.parts.tablePopAll.hidden = false;
			this.#setTableAction('Take It Out', true);
			this.#sayTable('Bubble wrap! The best part. Pop the bubbles one at a time: click them, or use the arrow keys and Space. Or take it out.');
		} else {
			this.#sayTable(['Rrrip! So much tape.', 'Rrrrip! Who uses this much tape?', 'Rrrrrip! Almost there!'][this.#table.tears - 1]);
		}

		this.#drawTable();
	}

	#pop(index) {
		if (this.#table.bubbles[index] || this.#table.isRuined) {
			return;
		}

		this.#table.bubbles[index] = true;
		this.#sounds.pop();
		if (this.#table.bubbles.every(Boolean)) {
			this.parts.tablePopAll.hidden = true;
			this.#sayTable('All 50 bubbles, one at a time, every single one. That is the best part of mail order.');
			this.celebrate();
		}

		this.#drawTable();
	}

	#popAt(point) {
		for (let index = 0; index < this.#table.bubbles.length; index++) {
			const center = bubbleCenter(index);
			if (Math.hypot(center.x - point.x, center.y - point.y) < 13) {
				this.#pop(index);
			}
		}
	}

	#popAll() {
		if (this.#table.mode !== 'bubbles' || this.#table.isRuined) {
			return;
		}

		this.#table.isRuined = true;
		this.#table.bubbles = this.#table.bubbles.map(() => true);
		this.parts.tablePopAll.hidden = true;
		this.#sounds.pfft();
		this.#sayTable('“Pop All” squashed them all at once. It went “pfft”, and the fun is gone forever. Lillesøster wanted to pop some too.');
		this.#drawTable();
	}

	#takeOut() {
		this.#table.mode = 'reveal';
		this.parts.tablePopAll.hidden = true;
		this.#setTableAction('Put It with My Stuff', true);
		this.#sayTable(`The ad, and what came: ${catalog[this.#table.id].reality}`);
		this.#animateTable(500);
	}

	#putAway() {
		const id = this.#table.id;
		this.#state.items[id].status = 'mine';
		this.#persist();
		this.#renderAds();
		this.#renderTabs();
		this.#selectToy(id);
		this.#goIdle();
		if (this.#table.mode === 'idle') {
			this.#sayTable(`The ${catalog[id].name} is with my stuff now. Go play with it!`);
			this.#goTo(this.parts.stuff);
		} else {
			this.#sayTable(`The ${catalog[id].name} is with my stuff. And there is another package!`);
		}
	}

	#tableAction() {
		if (this.#table.mode === 'envelope') {
			this.#mailIt();
		} else if (this.#table.mode === 'bubbles') {
			this.#takeOut();
		} else if (this.#table.mode === 'reveal') {
			this.#putAway();
		}
	}

	// The drawing of the kitchen table.

	#drawCouponFace(context, id, left, top) {
		context.fillStyle = 'white';
		context.fillRect(left, top, coupon.width, coupon.height);
		drawText(context, '✂ ORDER NOW!', left + 140, top + 26, {font: `22px ${impact}`, color: '#d40000', align: 'center'});
		drawText(context, `YES! Rush me the ${catalog[id].name}!`, left + 140, top + 48, {font: `bold 13px ${times}`, align: 'center'});
		drawText(context, `Enclosed: ${this.#orderCost(id)} kr`, left + 140, top + 66, {font: `12px ${times}`, align: 'center'});
		drawText(context, 'Name:', left + 16, top + 94, {font: `12px ${times}`});
		drawText(context, 'Sindre S. (age 10)', left + 60, top + 94, {font: `16px ${comicSans}`, color: '#1a3acc'});
		drawText(context, 'Address:', left + 16, top + 120, {font: `12px ${times}`});
		drawText(context, 'Bergen, NORWAY', left + 72, top + 120, {font: `16px ${comicSans}`, color: '#1a3acc'});
		drawText(context, 'Allow 6 to 8 weeks for delivery.', left + 140, top + 142, {font: `italic 10px ${times}`, align: 'center'});
	}

	#drawPackage(context) {
		comicShape(context, () => {
			context.rect(70, 50, 220, 140);
		}, {fill: '#d8b878', shade: '#a88848'});
		drawText(context, 'FRAGILE', 180, 130, {font: `24px ${impact}`, color: '#a02020', align: 'center'});
		// The brown paper, torn off a strip at a time from the top.
		context.save();
		context.beginPath();
		const top = 50 + (this.#table.tears * 35);
		context.moveTo(70, 190);
		context.lineTo(70, top);
		for (let x = 70; x <= 290; x += 10) {
			context.lineTo(x, top + ((x / 10) % 2 ? 6 : -2));
		}

		context.lineTo(290, 190);
		context.closePath();
		context.clip();
		context.fillStyle = '#b58a4a';
		context.fillRect(70, 50, 220, 140);
		context.fillStyle = dots(context, '#8a6230');
		context.fillRect(70, 50, 220, 140);
		context.strokeStyle = '#f0e8d8';
		context.lineWidth = 3;
		context.beginPath();
		context.moveTo(180, 50);
		context.lineTo(180, 190);
		context.moveTo(70, 120);
		context.lineTo(290, 120);
		context.stroke();
		context.fillStyle = 'white';
		context.fillRect(100, 136, 120, 40);
		drawText(context, 'TO: SINDRE S.', 108, 152, {font: `12px ${comicSans}`});
		drawText(context, 'BERGEN, NORWAY', 108, 168, {font: `12px ${comicSans}`});
		comicShape(context, () => {
			context.rect(240, 60, 36, 30);
		}, {fill: '#3a6ad4', lineWidth: 1});
		drawText(context, 'USA', 258, 80, {font: `11px ${impact}`, color: 'white', align: 'center'});
		comicShape(context, () => {
			context.rect(84, 62, 70, 18);
		}, {fill: '#ffe44a', lineWidth: 1});
		drawText(context, 'PAR AVION', 119, 75, {font: `10px ${impact}`, color: '#1a3acc', align: 'center'});
		context.restore();
		context.strokeStyle = ink;
		context.lineWidth = 2;
		context.strokeRect(70, 50, 220, 140);
	}

	#drawBubbles(context) {
		comicShape(context, () => {
			context.rect(26, 34, 308, 168);
		}, {fill: '#c49a5a', lineWidth: 3});
		context.fillStyle = '#e8d8b8';
		context.fillRect(36, 44, 288, 148);
		context.save();
		context.globalAlpha = 0.6;
		drawReality(context, this.#table.id, 180, 118, 0.9);
		context.restore();
		context.fillStyle = 'rgba(255, 255, 255, 0.35)';
		context.fillRect(40, 48, 280, 140);
		for (let index = 0; index < this.#table.bubbles.length; index++) {
			const {x, y} = bubbleCenter(index);
			if (this.#table.bubbles[index]) {
				context.strokeStyle = 'rgba(120, 140, 150, 0.7)';
				context.lineWidth = 1;
				context.beginPath();
				for (let ray = 0; ray < 5; ray++) {
					const angle = (ray * 1.3) + index;
					context.moveTo(x, y);
					context.lineTo(x + (Math.cos(angle) * 8), y + (Math.sin(angle) * (this.#table.isRuined ? 3 : 8)));
				}

				context.stroke();
			} else {
				const gradient = context.createRadialGradient(x - 4, y - 4, 1, x, y, 12);
				gradient.addColorStop(0, 'rgba(255, 255, 255, 0.95)');
				gradient.addColorStop(0.5, 'rgba(220, 240, 255, 0.4)');
				gradient.addColorStop(1, 'rgba(150, 190, 220, 0.6)');
				context.fillStyle = gradient;
				context.beginPath();
				context.arc(x, y, 11, 0, Math.PI * 2);
				context.fill();
				context.strokeStyle = 'rgba(100, 140, 170, 0.6)';
				context.lineWidth = 1;
				context.stroke();
			}

			if (this.#table.showCursor && index === this.#table.cursor) {
				context.strokeStyle = '#ffcc00';
				context.lineWidth = 3;
				context.beginPath();
				context.arc(x, y, 14, 0, Math.PI * 2);
				context.stroke();
			}
		}

		const popped = this.#table.bubbles.filter(Boolean).length;
		drawText(context, this.#table.isRuined ? 'RUINED' : `${popped} / ${this.#table.bubbles.length}`, 330, 226, {font: `14px ${impact}`, color: 'white', align: 'right', stroke: ink});
	}

	#drawReveal(context) {
		const lift = this.#table.animation ? this.#animationProgress() : 1;
		context.globalAlpha = lift;
		const ad = this.#ads.get(this.#table.id);
		comicShape(context, () => {
			context.rect(14, 30, 152, 120);
		}, {fill: '#fffbe8'});
		if (ad) {
			context.drawImage(ad.canvas, 18, 34, 144, 90);
		}

		drawText(context, 'THE AD', 90, 142, {font: `16px ${impact}`, color: '#d40000', align: 'center'});
		comicShape(context, () => {
			context.rect(194, 30, 152, 120);
		}, {fill: 'white'});
		drawReality(context, this.#table.id, 270, 80, 0.8);
		drawText(context, 'WHAT CAME', 270, 142, {font: `16px ${impact}`, color: ink, align: 'center'});
		starburst(context, 180, 90, 22, 'VS.', {size: 13});
		context.fillStyle = 'rgba(255, 251, 232, 0.92)';
		context.fillRect(10, 160, 340, 72);
		drawWrapped(context, catalog[this.#table.id].reality, 20, 178, 320, 17, {font: `14px ${comicSans}`});
		context.globalAlpha = 1;
	}

	#drawTable() {
		const context = this.#tableContext;
		drawWood(context);
		if (this.#table.mode === 'idle') {
			comicShape(context, () => {
				ellipse(context, 74, 178, 56, 40);
			}, {fill: 'white'});
			for (const [x, y] of [[54, 168], [90, 172], [70, 192]]) {
				comicShape(context, () => {
					context.moveTo(x, y + 14);
					context.bezierCurveTo(x - 26, y - 4, x - 6, y - 20, x, y - 6);
					context.bezierCurveTo(x + 6, y - 20, x + 26, y - 4, x, y + 14);
				}, {fill: '#e0a040', shade: '#a06010', lineWidth: 1.5});
			}

			comicShape(context, () => {
				context.rect(80, 150, 22, 14);
			}, {fill: '#c87a30', lineWidth: 1});
			comicShape(context, () => {
				context.moveTo(300, 40);
				context.lineTo(330, 40);
				context.lineTo(326, 100);
				context.lineTo(304, 100);
				context.closePath();
			}, {fill: '#f8f8ff'});
			context.save();
			context.translate(200, 110);
			context.rotate(0.12);
			comicShape(context, () => {
				context.rect(-60, -80, 120, 160);
			}, {fill: '#ffdd22', shade: '#e0a000'});
			drawText(context, 'DONALD DUCK', 0, -52, {font: `18px ${impact}`, color: '#d40000', align: 'center', stroke: 'white'});
			drawText(context, '& CO.', 0, -32, {font: `16px ${impact}`, color: '#d40000', align: 'center', stroke: 'white'});
			drawText(context, 'Nr. 37', 0, 60, {font: `12px ${impact}`, align: 'center'});
			context.restore();
			drawBubble(context, 'Pick a coupon in the comic!', 200, 230, {width: 190, tailX: 200, tailY: 232, size: 13});
		} else if (this.#table.mode === 'cut') {
			context.fillStyle = '#f6ecc8';
			context.fillRect(10, 10, 340, 220);
			context.fillStyle = dots(context, '#e6d6a0', 6, 1.5);
			context.fillRect(10, 10, 340, 220);
			this.#drawCouponFace(context, this.#table.id, coupon.x, coupon.y);
			context.setLineDash([7, 5]);
			context.strokeStyle = ink;
			context.lineWidth = 2;
			context.strokeRect(coupon.x, coupon.y, coupon.width, coupon.height);
			context.setLineDash([]);
			context.strokeStyle = '#3a2a1a';
			context.lineWidth = 3;
			for (let index = 0; index < segmentCount; index++) {
				if (this.#table.segments[index]) {
					const from = perimeterPoint(index * perimeter / segmentCount);
					const to = perimeterPoint(((index + 1) * perimeter / segmentCount) - 0.01);
					context.beginPath();
					context.moveTo(from.x, from.y);
					context.lineTo(to.x, to.y);
					context.stroke();
				}
			}

			context.lineWidth = 2;
			for (const snip of this.#table.snips) {
				context.beginPath();
				context.moveTo(snip.x - (Math.cos(snip.angle) * 9), snip.y - (Math.sin(snip.angle) * 9));
				context.lineTo(snip.x + (Math.cos(snip.angle) * 9), snip.y + (Math.sin(snip.angle) * 9));
				context.stroke();
			}

			const percent = Math.round(this.#table.segments.filter(Boolean).length / segmentCount * 100);
			drawText(context, `${percent}% cut`, 346, 226, {font: `13px ${impact}`, align: 'right'});
			if (this.#table.scissors) {
				drawScissors(context, this.#table.scissors);
			}
		} else if (this.#table.mode === 'envelope' || this.#table.mode === 'mailing') {
			const isMailing = this.#table.mode === 'mailing';
			const progress = isMailing && this.#table.animation ? this.#animationProgress() : 0;
			drawEnvelope(context, this.#table.id, progress * progress * 420, isMailing);
		} else if (this.#table.mode === 'package') {
			this.#drawPackage(context);
		} else if (this.#table.mode === 'bubbles') {
			this.#drawBubbles(context);
		} else if (this.#table.mode === 'reveal') {
			this.#drawReveal(context);
		}
	}

	// The mailbox outside the house, in the rain of Bergen.

	#hasMail() {
		const {items, week, letter} = this.#state;
		return catalogOrder.some(id => items[id]?.status === 'mailed' && items[id].arrives <= week) || (letter !== undefined && !letter.isRead && letter.arrives <= week);
	}

	#advanceWeek() {
		this.#state.week++;
		this.#mail.weekClock = 0;
		this.#state.bottlesLeft = 6;
		this.#persist();
		this.#renderAds();

		const arrivals = catalogOrder.filter(id => this.#state.items[id]?.status === 'mailed' && this.#state.items[id].arrives <= this.#state.week && !this.#mail.announced.has(id));
		const isLetterArriving = this.#state.letter !== undefined && !this.#state.letter.isRead && this.#state.letter.arrives <= this.#state.week && !this.#mail.announced.has('letter');
		for (const id of arrivals) {
			this.#mail.announced.add(id);
		}

		if (isLetterArriving) {
			this.#mail.announced.add('letter');
		}

		let isAnnounced = true;
		if (arrivals.length > 0 || isLetterArriving) {
			this.#mail.postman = 0;
			this.#sounds.ding();
			this.#sayMail('The mailman was here on his red bicycle! The flag of the mailbox is up!');
		} else if (weekOfYear(this.#state.week) === 1) {
			this.#sayMail(`Happy New Year ${yearOfWeek(this.#state.week)}! The computers still work, and so does the mail.`);
		} else {
			isAnnounced = false;
		}

		this.#drawMailbox();
		return isAnnounced;
	}

	#checkMailbox() {
		this.#mail.openUntil = performance.now() + 2500;
		setTimeout(() => {
			this.#drawMailbox();
		}, 2600);
		const arrived = catalogOrder.filter(id => this.#state.items[id]?.status === 'mailed' && this.#state.items[id].arrives <= this.#state.week);
		const isLetterThere = this.#state.letter !== undefined && !this.#state.letter.isRead && this.#state.letter.arrives <= this.#state.week;
		if (arrived.length > 0) {
			for (const id of arrived) {
				this.#state.items[id].status = 'table';
			}

			this.#persist();
			this.#renderAds();
			this.#mail.shown = 'package';
			this.#sounds.ding();
			this.#sayMail(arrived.length === 1 ? `A package for me! It is the ${catalog[arrived[0]].name}! I take it to the kitchen table.` : `${arrived.length} packages for me! I take them to the kitchen table.`);
			// Nothing was paid for a coupon that is still on the table, so the package goes first.
			if (['idle', 'cut', 'envelope'].includes(this.#table.mode)) {
				this.#startPackage(arrived[0]);
				this.#renderAds();
				// After a look at the open mailbox, the package goes to the kitchen table, which is above the mailbox on a phone.
				setTimeout(() => {
					this.#goOnFrom(this.parts.mailbox, this.parts.tableCanvas);
				}, 1500);
			}
		} else if (isLetterThere) {
			this.#state.letter.isRead = true;
			this.#persist();
			this.#mail.shown = 'letter';
			this.#sayMail('A letter from the art school! It is about my drawing of Tippy. I read it with my stuff.');
			if (this.#state.items.draw?.status === 'mine') {
				this.#toys.draw.view = 'letter';
				if (this.#stuff.selected === 'draw') {
					this.#afterInput();
				}
			}
		} else {
			this.#mail.emptyChecks++;
			const [kind, text] = randomItem(junkMail);
			this.#mail.shown = kind;
			const isWaiting = catalogOrder.some(id => this.#state.items[id]?.status === 'mailed') || this.#state.letter?.isRead === false;
			if (this.#mail.emptyChecks % 5 === 0) {
				this.#sayMail('Mamma: “Sindre, the mailman comes once a day. Stop opening the mailbox, you let the rain in.”');
			} else {
				this.#sayMail(isWaiting ? text : `${text} Did I even order anything?`);
			}
		}

		this.#drawMailbox();
	}

	#drawMailbox() {
		const context = this.#mailboxContext;
		const sky = context.createLinearGradient(0, 0, 0, 200);
		sky.addColorStop(0, '#6e7a86');
		sky.addColorStop(1, '#a9b3bb');
		context.fillStyle = sky;
		context.fillRect(0, 0, 360, 240);
		// Fløyen behind the houses, and the house with a warm window.
		context.fillStyle = '#3e5a48';
		context.beginPath();
		context.moveTo(0, 130);
		context.lineTo(70, 90);
		context.lineTo(150, 110);
		context.lineTo(240, 70);
		context.lineTo(360, 100);
		context.lineTo(360, 200);
		context.lineTo(0, 200);
		context.fill();
		comicShape(context, () => {
			context.rect(220, 60, 150, 150);
		}, {fill: '#f2efe6', lineWidth: 2});
		context.strokeStyle = 'rgba(0, 0, 0, 0.15)';
		context.lineWidth = 1;
		for (let row = 70; row < 210; row += 10) {
			context.beginPath();
			context.moveTo(220, row);
			context.lineTo(360, row);
			context.stroke();
		}

		comicShape(context, () => {
			context.rect(260, 90, 60, 50);
		}, {fill: '#ffd36a', lineWidth: 3});
		context.strokeStyle = ink;
		context.beginPath();
		context.moveTo(290, 90);
		context.lineTo(290, 140);
		context.moveTo(260, 115);
		context.lineTo(320, 115);
		context.stroke();
		context.fillStyle = '#55595e';
		context.fillRect(0, 200, 360, 40);
		context.fillStyle = 'rgba(160, 175, 190, 0.6)';
		for (const [x, y, width] of [[60, 218, 40], [180, 226, 60], [300, 214, 30]]) {
			context.beginPath();
			ellipse(context, x, y, width, 5);
			context.fill();
		}

		// The calendar on the kitchen wall, seen through the window of the mind.
		comicShape(context, () => {
			context.rect(10, 10, 74, 84);
		}, {fill: 'white', lineWidth: 2});
		context.fillStyle = '#d42a2a';
		context.fillRect(11, 11, 72, 18);
		drawText(context, 'UKE', 47, 25, {font: `13px ${impact}`, color: 'white', align: 'center'});
		drawText(context, String(weekOfYear(this.#state.week)), 47, 66, {font: `34px ${impact}`, align: 'center'});
		drawText(context, String(yearOfWeek(this.#state.week)), 47, 86, {font: `13px ${impact}`, align: 'center'});
		const waiting = catalogOrder.filter(id => this.#state.items[id]?.status === 'mailed').length + (this.#state.letter?.isRead === false ? 1 : 0);
		drawText(context, waiting === 0 ? 'Nothing in the mail' : `${waiting} in the mail`, 10, 232, {font: `bold 13px ${comicSans}`, color: 'white', stroke: ink});

		// The mailbox on its post, with the flag up when something came.
		comicShape(context, () => {
			context.rect(124, 120, 12, 90);
		}, {fill: '#6a4a2a'});
		const isOpen = performance.now() < this.#mail.openUntil;
		const isFlagUp = this.#hasMail();
		comicShape(context, () => {
			if (isFlagUp) {
				context.rect(186, 64, 5, 50);
				context.rect(191, 64, 18, 13);
			} else {
				context.rect(186, 106, 30, 5);
				context.rect(208, 100, 13, 17);
			}
		}, {fill: '#e8322a', lineWidth: 1.5});
		comicShape(context, () => {
			context.moveTo(80, 124);
			context.lineTo(80, 96);
			context.arc(104, 96, 24, Math.PI, Math.PI * 1.5);
			context.lineTo(160, 72);
			context.arc(160, 96, 24, Math.PI * 1.5, 0);
			context.lineTo(184, 124);
			context.closePath();
		}, {fill: '#2e7d4a', shade: '#174a2a'});
		context.fillStyle = 'white';
		context.fillRect(110, 100, 50, 13);
		drawText(context, 'SORHUS', 135, 107, {font: `10px ${impact}`, align: 'center', baseline: 'middle'});
		if (isOpen) {
			// The door at the front is open, with what came sticking out.
			comicShape(context, () => {
				ellipse(context, 80, 100, 10, 26);
			}, {fill: '#0e2a18'});
			const shownColors = {package: '#c49a5a', letter: 'white', bills: '#f0f0f0', catalog: '#ffdd00', postcard: '#ffe0f0', paper: '#c8c8c8'};
			if (this.#mail.shown && this.#mail.shown !== 'nothing') {
				comicShape(context, () => {
					context.rect(48, 88, 38, this.#mail.shown === 'package' ? 30 : 20);
				}, {fill: shownColors[this.#mail.shown] ?? 'white', lineWidth: 1.5});
			}

			comicShape(context, () => {
				context.rect(56, 124, 26, 10);
			}, {fill: '#2e7d4a'});
		}

		if (this.#mail.postman !== undefined) {
			const x = -40 + (this.#mail.postman * 440);
			comicShape(context, () => {
				context.arc(x - 14, 205, 9, 0, Math.PI * 2);
				context.moveTo(x + 23, 205);
				context.arc(x + 14, 205, 9, 0, Math.PI * 2);
			}, {fill: undefined, lineWidth: 2});
			comicShape(context, () => {
				context.rect(x - 8, 170, 16, 26);
			}, {fill: '#d42a2a'});
			comicShape(context, () => {
				context.arc(x, 162, 8, 0, Math.PI * 2);
			}, {fill: '#f5c9a0'});
			comicShape(context, () => {
				context.rect(x + 8, 180, 16, 12);
			}, {fill: '#d4a24a', lineWidth: 1});
		}

		context.strokeStyle = 'rgba(210, 225, 240, 0.6)';
		context.lineWidth = 1;
		context.beginPath();
		for (const drop of this.#mail.drops) {
			context.moveTo(drop.x, drop.y);
			context.lineTo(drop.x - 2, drop.y + 9);
		}

		context.stroke();
	}

	#stepMailbox(seconds) {
		for (const drop of this.#mail.drops) {
			drop.y += drop.speed * seconds;
			drop.x -= drop.speed * seconds * 0.2;
			if (drop.y > 240) {
				drop.y = -10;
				drop.x = Math.random() * 400;
			}
		}

		if (this.#mail.postman !== undefined) {
			this.#mail.postman += seconds / 2.5;
			if (this.#mail.postman >= 1) {
				this.#mail.postman = undefined;
			}
		}

		// A week goes by in a few seconds while the visitor watches the mailbox.
		this.#mail.weekClock += seconds;
		if (this.#mail.weekClock >= 5) {
			this.#advanceWeek();
		}

		this.#drawMailbox();
	}

	// My stuff: the things that came in the mail, to play with on a canvas with their own tools. Each toy is a plain object with its own state, made again when the visitor starts over, so its methods reach the element by name.

	// The Sea-Monkeys, in their tank.
	#makeSeaMonkeys() {
		const element = this;
		return {
			stage: 'tap',
			readyClock: 0,
			day: 0,
			dayClock: 0,
			monkeys: [],
			food: [],
			feedings: [],
			bubbles: [],
			cloud: 0,
			isLightOn: false,
			isLensOn: false,
			hasSeenLens: false,
			light: {x: 290, y: 190},
			phase: 0,
			lastFed: undefined,
			tools() {
				return [
					{label: 'Add Water Purifier', disabled: this.stage !== 'tap', action: () => this.purify()},
					{label: 'Add Instant Life', disabled: this.stage !== 'ready', action: () => this.hatch()},
					{label: 'Feed Growth Food', disabled: this.stage !== 'hatched', action: () => this.feed()},
					{label: 'Pump Air', disabled: this.stage === 'tap', action: () => this.pump()},
					{label: 'Flashlight', pressed: this.isLightOn, disabled: this.stage !== 'hatched', action: () => this.toggleLight()},
					{label: 'Magnifying Glass', pressed: this.isLensOn, disabled: this.stage !== 'hatched', action: () => this.toggleLens()},
					{label: 'Wait a Day', disabled: this.stage === 'tap', action: () => this.nextDay(true)},
				];
			},
			enter() {
				element.#sayStuff(this.stage === 'tap' ? 'A tank of tap water. First the Water Purifier, then wait, then Instant Life!' : `My Sea-Monkeys, day ${this.day}.`);
			},
			purify() {
				this.stage = 'purifying';
				this.readyClock = 0;
				element.#sounds.splash();
				element.#sayStuff(`The Water Purifier goes in. ${element.reducedMotion ? 'Press “Wait a Day” for the 24 hours.' : 'Now the water needs 24 hours to get ready.'} (Psst: the eggs are already in this packet. That is the secret of “instant life”.)`);
			},
			hatch() {
				this.stage = 'hatched';
				this.monkeys = Array.from({length: 14}, (_, index) => ({
					x: randomBetween(tank.left + 30, tank.right - 30),
					y: randomBetween(tank.top + 40, tank.bottom - 30),
					heading: randomBetween(0, Math.PI * 2),
					size: randomBetween(0.6, 1),
					name: royalNames[index],
					isAsleep: false,
				}));
				element.#sounds.ding();
				element.#sayStuff('INSTANT LIFE! Tiny white specks wiggle in the water. They are alive! I name them after the royal family.');
			},
			feed() {
				this.feedings.push(this.day);
				for (let index = 0; index < 18 && this.food.length < 60; index++) {
					this.food.push({x: randomBetween(tank.left + 60, tank.right - 60), y: tank.top + 30 + randomBetween(0, 10)});
				}

				const recent = this.feedings.filter(day => day >= this.day - 1).length;
				if (recent >= 3) {
					this.cloud = Math.min(1, this.cloud + 0.35);
					element.#sayStuff('Too much food! The water gets cloudy and brown. The box said one tiny scoop every five days. Pump air to save them!');
				} else {
					element.#sayStuff('One tiny scoop of Growth Food. They wiggle toward it. They grow when they eat!');
				}

				this.lastFed = this.day;
			},
			pump() {
				this.cloud = Math.max(0, this.cloud - 0.25);
				for (let index = 0; index < 14 && this.bubbles.length < 40; index++) {
					this.bubbles.push({x: randomBetween(tank.left + 20, tank.left + 50), y: tank.bottom - 10 - randomBetween(0, 30), speed: randomBetween(50, 90)});
				}

				element.#sounds.puff();
				element.#sayStuff(this.cloud > 0 ? 'Pump, pump, pump! The water clears up a little.' : 'Pump, pump, pump! Fresh air. They like it.');
			},
			toggleLight() {
				this.isLightOn = !this.isLightOn;
				element.#sayStuff(this.isLightOn ? 'Lights off, flashlight on! Move it over the tank: they swim to the light. They really do obey commands!' : 'Lights on again.');
			},
			toggleLens() {
				this.isLensOn = !this.isLensOn;
				if (this.isLensOn && !this.hasSeenLens) {
					this.hasSeenLens = true;
					element.#sayStuff('Under the magnifying glass: no crowns. No smiles. Eleven pairs of legs, a forked tail, and eyes on stalks. They breathe with their feet. The ad lied!');
				} else {
					element.#sayStuff(this.isLensOn ? 'The magnifying glass. Move it over a Sea-Monkey.' : 'Magnifying glass away. From here, they look almost royal.');
				}
			},
			nextDay(isManual) {
				this.day++;
				this.dayClock = 0;
				if (this.stage === 'purifying') {
					this.stage = 'ready';
					element.#renderTools();
					element.#sayStuff('24 hours later: the water is ready! Now add Instant Life.');
					return;
				}

				const isFed = this.lastFed !== undefined && this.day - this.lastFed <= 3;
				for (const monkey of this.monkeys) {
					if (isFed && !monkey.isAsleep) {
						monkey.size = Math.min(4.5, monkey.size + randomBetween(0.2, 0.5));
					}
				}

				this.cloud = Math.max(0, this.cloud - 0.04);
				const awake = this.monkeys.filter(monkey => !monkey.isAsleep);
				if (this.cloud > 0.75 && awake.length > 2) {
					const sleeper = randomItem(awake);
					sleeper.isAsleep = true;
					element.#sayStuff(`${sleeper.name} floats on the back. Pappa says that ${sleeper.name} is only sleeping. Pump air!`);
					return;
				}

				if (isManual) {
					element.#sayStuff(`Day ${this.day}. ${this.monkeys.length === 0 ? 'The water is ready for Instant Life.' : (isFed ? 'They grew a little!' : 'They look hungry. A tiny scoop of food?')}`);
				}
			},
			pointer(type, point) {
				this.light = point;
			},
			step(seconds) {
				this.phase += seconds * 9;
				if (this.stage === 'purifying') {
					this.readyClock += seconds;
					if (this.readyClock >= 4) {
						this.nextDay(false);
					}
				} else if (this.stage === 'hatched') {
					this.dayClock += seconds;
					if (this.dayClock >= 5) {
						this.nextDay(false);
					}
				}

				for (const monkey of this.monkeys) {
					if (monkey.isAsleep) {
						monkey.y = Math.max(tank.top + 40, monkey.y - (8 * seconds));
						continue;
					}

					const speed = (14 + (monkey.size * 5)) * (1 - (this.cloud * 0.6));
					monkey.heading += randomBetween(-3, 3) * seconds;
					if (this.isLightOn) {
						const target = Math.atan2(this.light.y - monkey.y, this.light.x - monkey.x);
						const difference = Math.atan2(Math.sin(target - monkey.heading), Math.cos(target - monkey.heading));
						monkey.heading += difference * Math.min(1, seconds * 3);
					}

					monkey.x += Math.cos(monkey.heading) * speed * seconds;
					monkey.y += Math.sin(monkey.heading) * speed * seconds;
					if (monkey.x < tank.left + 14 || monkey.x > tank.right - 14) {
						monkey.heading = Math.PI - monkey.heading;
						monkey.x = clamp(monkey.x, tank.left + 14, tank.right - 14);
					}

					if (monkey.y < tank.top + 34 || monkey.y > tank.bottom - 12) {
						monkey.heading = -monkey.heading;
						monkey.y = clamp(monkey.y, tank.top + 34, tank.bottom - 12);
					}
				}

				for (const crumb of this.food) {
					crumb.y = Math.min(tank.bottom - 6, crumb.y + (14 * seconds));
				}

				this.food = this.food.filter(crumb => !this.monkeys.some(monkey => !monkey.isAsleep && Math.hypot(monkey.x - crumb.x, monkey.y - crumb.y) < 6));
				for (const bubble of this.bubbles) {
					bubble.y -= bubble.speed * seconds;
				}

				this.bubbles = this.bubbles.filter(bubble => bubble.y > tank.top + 30);
			},
			draw(context) {
				drawWall(context, '#cfdcea');
				comicShape(context, () => {
					context.rect(80, 330, 420, 20);
				}, {fill: '#a0703a'});
				comicShape(context, () => {
					context.roundRect(tank.left, tank.top, tank.right - tank.left, tank.bottom - tank.top, 14);
				}, {fill: this.stage === 'tap' ? '#e6f4fb' : '#d4eef8', lineWidth: 3});
				context.fillStyle = '#c8a870';
				context.fillRect(tank.left + 4, tank.bottom - 14, tank.right - tank.left - 8, 10);
				context.fillStyle = 'rgba(255, 255, 255, 0.7)';
				context.fillRect(tank.left + 4, tank.top + 4, tank.right - tank.left - 8, 22);
				drawText(context, 'SEA-MONKEY TANK', (tank.left + tank.right) / 2, tank.top + 20, {font: `16px ${impact}`, color: '#1a5a9a', align: 'center'});
				context.fillStyle = '#7a5a2a';
				for (const crumb of this.food) {
					context.fillRect(crumb.x, crumb.y, 2, 2);
				}

				for (const monkey of this.monkeys) {
					const length = 3 + (monkey.size * 3);
					context.save();
					context.translate(monkey.x, monkey.y);
					context.rotate(monkey.isAsleep ? Math.PI : monkey.heading);
					context.strokeStyle = 'rgba(200, 170, 130, 0.9)';
					context.lineWidth = 1 + (monkey.size * 0.4);
					context.beginPath();
					context.moveTo(-length * 0.6, 0);
					context.quadraticCurveTo(0, Math.sin(this.phase + monkey.x) * monkey.size, length * 0.6, 0);
					context.stroke();
					context.fillStyle = '#222222';
					context.fillRect((-length * 0.6) - 1, -1, 1.5, 1.5);
					context.restore();
				}

				context.strokeStyle = 'rgba(255, 255, 255, 0.9)';
				context.lineWidth = 1;
				for (const bubble of this.bubbles) {
					context.beginPath();
					context.arc(bubble.x, bubble.y, 3, 0, Math.PI * 2);
					context.stroke();
				}

				if (this.cloud > 0) {
					context.fillStyle = `rgba(150, 130, 70, ${this.cloud * 0.7})`;
					context.fillRect(tank.left + 3, tank.top + 26, tank.right - tank.left - 6, tank.bottom - tank.top - 30);
				}

				// The two round magnifiers on the front of the tank, as on the real one.
				context.strokeStyle = 'rgba(255, 255, 255, 0.8)';
				context.lineWidth = 3;
				for (const x of [200, 380]) {
					context.beginPath();
					context.arc(x, 200, 34, Math.PI * 1.1, Math.PI * 1.5);
					context.stroke();
				}

				drawDay(context, this.day);
				if (this.stage === 'tap') {
					drawBubble(context, 'Tap water. Add the Water Purifier first!', 290, 190, {width: 230, tailX: 290, tailY: 210});
				} else if (this.stage === 'purifying') {
					drawBubble(context, 'Wait 24 hours...', 290, 190, {width: 160, tailX: 290, tailY: 210});
				}

				if (this.isLightOn) {
					const light = context.createRadialGradient(this.light.x, this.light.y, 10, this.light.x, this.light.y, 110);
					light.addColorStop(0, 'rgba(255, 250, 200, 0.15)');
					light.addColorStop(1, 'rgba(0, 0, 25, 0.82)');
					context.fillStyle = light;
					context.fillRect(0, 0, 640, 360);
				}

				if (this.isLensOn) {
					const byDistance = this.monkeys.toSorted((first, second) => Math.hypot(first.x - this.light.x, first.y - this.light.y) - Math.hypot(second.x - this.light.x, second.y - this.light.y));
					const nearest = byDistance[0];
					const radius = 70;
					context.save();
					context.beginPath();
					context.arc(this.light.x, this.light.y, radius, 0, Math.PI * 2);
					context.fillStyle = `rgba(${210 - (this.cloud * 60)}, ${236 - (this.cloud * 80)}, 248, 1)`;
					context.fill();
					context.clip();
					if (nearest) {
						drawShrimp(context, this.light.x, this.light.y, 5 + (nearest.size * 1.2), nearest.heading + Math.PI, this.phase);
					}

					context.restore();
					context.lineWidth = 8;
					context.strokeStyle = '#2a2a2a';
					context.beginPath();
					context.arc(this.light.x, this.light.y, radius, 0, Math.PI * 2);
					context.moveTo(this.light.x + (radius * 0.72), this.light.y + (radius * 0.72));
					context.lineTo(this.light.x + (radius * 1.25), this.light.y + (radius * 1.25));
					context.stroke();
					if (nearest) {
						drawText(context, `${nearest.name}${nearest.isAsleep ? ' (asleep)' : ''}`, this.light.x, this.light.y - radius - 10, {font: `bold 14px ${comicSans}`, color: 'white', align: 'center', stroke: ink});
					}
				}
			},
		};
	}

	// The X-Ray Specs, and their lens over the whole page. The lens listens to the whole page only while the specs are on.
	#makeXray() {
		const element = this;
		const {lens} = this.parts;
		return {
			isOn: false,
			x: 0,
			y: 0,
			frame: undefined,
			box: undefined,
			listeners: undefined,
			context: lens.getContext('2d'),
			pixelRatio: 1,
			resize() {
				this.pixelRatio = Math.min(devicePixelRatio || 1, 2);
				lens.width = Math.round(innerWidth * this.pixelRatio);
				lens.height = Math.round(innerHeight * this.pixelRatio);
				this.box = undefined;
				this.schedule();
			},
			moveTo(x, y) {
				this.x = x;
				this.y = y;
				this.schedule();
			},
			// The keyboard moves the lens too: it looks at what has the focus.
			moveToElement(target) {
				const rectangle = target.getBoundingClientRect();
				this.moveTo(rectangle.left + (rectangle.width / 2), rectangle.top + (rectangle.height / 2));
			},
			on() {
				this.isOn = true;
				if (lens.parentElement !== document.body) {
					document.body.append(lens);
				}

				lens.hidden = false;
				this.listeners = new AbortController();
				const {signal} = this.listeners;
				const follow = event => {
					this.moveTo(event.clientX, event.clientY);
				};

				addEventListener('pointermove', follow, {passive: true, signal});
				addEventListener('pointerdown', follow, {passive: true, signal});
				addEventListener('focusin', event => {
					this.moveToElement(event.target);
				}, {signal});
				addEventListener('scroll', () => {
					this.schedule();
				}, {passive: true, capture: true, signal});
				addEventListener('resize', () => {
					this.resize();
				}, {signal});
				addEventListener('keydown', event => {
					if (event.key === 'Escape') {
						this.off();
					}
				}, {signal});
				this.resize();
				this.moveToElement(element.contains(document.activeElement) ? document.activeElement : element.parts.stuffCanvas);
				element.#sayStuff('The X-Ray Specs are on! Move the pointer over the page, anywhere, or move the focus with Tab, to see its bones: the HTML of everything under it. Press Escape to take them off.');
			},
			off() {
				this.isOn = false;
				this.listeners.abort();
				cancelAnimationFrame(this.frame);
				this.frame = undefined;
				lens.hidden = true;
				if (element.#stuff.selected === 'x-ray-specs') {
					element.#sayStuff('The specs are off. My eyes hurt a little. It is the feather.');
				}

				element.#renderTools();
				element.#drawStuff();
			},
			schedule() {
				if (this.frame === undefined) {
					this.frame = requestAnimationFrame(() => {
						this.frame = undefined;
						this.draw();
					});
				}
			},
			draw() {
				const context = this.context;
				context.setTransform(this.pixelRatio, 0, 0, this.pixelRatio, 0, 0);
				if (this.box) {
					context.clearRect(...this.box);
				}

				const {x, y} = this;
				const radius = clamp(innerWidth * 0.16, 70, 120);
				const found = [];
				const seen = new Set([lens, document.documentElement, document.body]);
				// A few points of the lens are enough to find what is under it, so it stays fast.
				for (const [offsetX, offsetY] of [[0, 0], [0.6, 0], [-0.6, 0], [0, 0.6], [0, -0.6]]) {
					for (const candidate of document.elementsFromPoint(x + (offsetX * radius), y + (offsetY * radius))) {
						if (!seen.has(candidate) && found.length < 40) {
							seen.add(candidate);
							found.push(candidate);
						}
					}
				}

				context.save();
				context.beginPath();
				context.arc(x, y, radius, 0, Math.PI * 2);
				context.clip();
				const film = context.createRadialGradient(x, y, 0, x, y, radius);
				film.addColorStop(0, '#16324e');
				film.addColorStop(1, '#050d18');
				context.fillStyle = film;
				context.fillRect(x - radius, y - radius, radius * 2, radius * 2);
				context.font = `11px ui-monospace, Menlo, monospace`;
				context.textBaseline = 'top';
				context.textAlign = 'left';
				// The outermost first, so the innermost bones are on top. Labels that would overlap are left out.
				const labels = [];
				for (const [index, bone] of found.toReversed().entries()) {
					const rectangle = bone.getBoundingClientRect();
					const alpha = 0.35 + (0.6 * index / Math.max(1, found.length - 1));
					// The feather between the lenses makes a second, blurry picture.
					context.strokeStyle = `rgba(200, 230, 255, ${alpha * 0.3})`;
					context.lineWidth = 1;
					context.strokeRect(rectangle.left + 3, rectangle.top + 2, rectangle.width, rectangle.height);
					context.strokeStyle = `rgba(230, 245, 255, ${alpha})`;
					context.lineWidth = 1.5;
					context.strokeRect(rectangle.left, rectangle.top, rectangle.width, rectangle.height);
					if (['IMG', 'CANVAS', 'SVG', 'VIDEO', 'IFRAME', 'svg'].includes(bone.tagName)) {
						context.beginPath();
						context.moveTo(rectangle.left, rectangle.top);
						context.lineTo(rectangle.right, rectangle.bottom);
						context.moveTo(rectangle.right, rectangle.top);
						context.lineTo(rectangle.left, rectangle.bottom);
						context.stroke();
					}

					const labelX = clamp(rectangle.left + 3, x - radius, x + radius);
					const labelY = clamp(rectangle.top + 3, y - radius, y + radius);
					if (Math.hypot(labelX - x, labelY - y) < radius - 8 && !labels.some(label => Math.abs(label.x - labelX) < 50 && Math.abs(label.y - labelY) < 12)) {
						labels.push({x: labelX, y: labelY});
						context.fillStyle = `rgba(255, 255, 255, ${alpha})`;
						context.fillText(`<${bone.tagName.toLowerCase()}>`, labelX, labelY);
					}
				}

				// The bone right under the pointer gets a big label at the bottom of the lens.
				if (found[0]) {
					drawText(context, `<${found[0].tagName.toLowerCase()}>`, x, y + radius - 14, {font: 'bold 15px ui-monospace, Menlo, monospace', color: '#ffffff', align: 'center', stroke: '#050d18'});
				}

				drawBoneHand(context, x, y, 0.9);
				context.restore();
				context.lineWidth = 12;
				context.strokeStyle = '#1a1a1a';
				context.beginPath();
				context.arc(x, y, radius + 5, 0, Math.PI * 2);
				context.stroke();
				context.lineWidth = 2;
				context.strokeStyle = '#d40000';
				context.beginPath();
				context.arc(x, y, radius + 9, 0, Math.PI * 2);
				context.stroke();
				const margin = 14;
				this.box = [x - radius - margin, y - radius - margin, (radius + margin) * 2, (radius + margin) * 2];
			},
		};
	}

	#makeSpecs() {
		const element = this;
		return {
			tools() {
				return [{label: element.#xray.isOn ? 'Take Them Off' : 'Put Them On', pressed: element.#xray.isOn, action: () => {
					if (element.#xray.isOn) {
						element.#xray.off();
					} else {
						element.#xray.on();
					}
				}}];
			},
			enter() {
				element.#sayStuff('X-Ray Specs! Put them on, and see the bones of the whole page.');
			},
			draw(context) {
				drawWall(context, '#e8e0f0');
				drawSpecs(context, 290, 200, 2.4);
				drawBubble(context, element.#xray.isOn ? 'You are wearing them! Look at the page with the pointer. Escape takes them off.' : 'Put them on, and move over the page. Bones everywhere!', 290, 110, {width: 330, tailX: 290, tailY: 130});
			},
		};
	}

	// The Chia Pet.
	#makeChia() {
		const element = this;
		return {
			seeds: [],
			water: 0,
			day: 0,
			dayClock: 0,
			mode: 'seeds',
			dryDays: 0,
			hasGrown: false,
			singing: 0,
			lastSnip: 0,
			tools() {
				return [
					{label: 'Spread Seeds', pressed: this.mode === 'seeds', action: () => {
						this.mode = 'seeds';
						element.#sayStuff('Drag over the clay to spread the sticky seed paste in the grooves.');
					}},
					{label: 'Water It', action: () => this.giveWater()},
					{label: 'Scissors', pressed: this.mode === 'scissors', disabled: this.seeds.length === 0, action: () => {
						this.mode = 'scissors';
						element.#sayStuff('Scissors! Drag over the green hair to give it a haircut.');
					}},
					{label: 'Wait a Day', action: () => this.nextDay(true)},
					{label: 'Sing the Jingle', action: () => this.sing()},
				];
			},
			enter() {
				element.#sayStuff(this.seeds.length === 0 ? 'A bald clay ram. Spread the seeds on it, water it, and wait for the hair.' : `My Chia Pet, day ${this.day}.`);
			},
			isOnRam(point) {
				return (((point.x - ramShape.x) / ramShape.radiusX) ** 2) + (((point.y - ramShape.y) / ramShape.radiusY) ** 2) < 0.9 && point.y < ramShape.y + 40;
			},
			giveWater() {
				this.water = 3;
				this.dryDays = 0;
				element.#sounds.splash();
				element.#sayStuff(this.seeds.length === 0 ? 'Water in the saucer. Now spread some seeds!' : 'Splash! Water in the saucer for three days.');
			},
			sing() {
				this.singing = element.reducedMotion ? 0 : 1.4;
				element.#sounds.jingle();
				element.#sayStuff(element.#audio.isRunning ? 'Ch-ch-ch-chia!' : 'Ch-ch-ch-chia! (Turn on the sound to hear it.)');
			},
			nextDay(isManual) {
				this.day++;
				this.dayClock = 0;
				if (this.seeds.length > 0 && this.water > 0) {
					this.water--;
					this.dryDays = 0;
					for (const seed of this.seeds) {
						seed.length = Math.min(70, seed.length + randomBetween(4, 10));
					}

					if (!this.hasGrown && this.seeds.some(seed => seed.length > 30)) {
						this.hasGrown = true;
						element.#sayStuff(`Day ${this.day}: it has hair! Well, patches of hair. The ad had a thick green coat. Mine has bald spots where the seeds slid off.`);
						return;
					}
				} else if (this.seeds.length > 0) {
					this.dryDays++;
					if (this.dryDays === 2) {
						element.#sayStuff('The saucer is dry, and the sprouts droop. Water it!');
						return;
					}
				}

				if (isManual) {
					element.#sayStuff(`Day ${this.day}.${this.seeds.length === 0 ? ' Nothing grows on bare clay. Spread some seeds!' : (this.water > 0 ? ' It grows!' : ' The saucer is dry.')}`);
				}
			},
			pointer(type, point, isPressed) {
				if (type === 'up' || (type === 'move' && !isPressed)) {
					return;
				}

				if (this.mode === 'seeds') {
					if (!this.isOnRam(point) || this.seeds.length >= 500) {
						return;
					}

					if (this.seeds.length === 0) {
						element.#sayStuff('Sticky seed paste! Spread it all over the grooves. Where there are no seeds, there will be no hair.');
					}

					for (let index = 0; index < 3; index++) {
						const seed = {x: point.x + randomBetween(-10, 10), y: point.y + randomBetween(-10, 10), length: 0, curl: randomBetween(-0.3, 0.3)};
						if (this.isOnRam(seed)) {
							seed.angle = Math.atan2(seed.y - (ramShape.y + 60), seed.x - ramShape.x);
							this.seeds.push(seed);
						}
					}
				} else {
					let isCut = false;
					for (const seed of this.seeds) {
						const tipX = seed.x + (Math.cos(seed.angle) * seed.length);
						const tipY = seed.y + (Math.sin(seed.angle) * seed.length);
						const along = clamp((((point.x - seed.x) * (tipX - seed.x)) + ((point.y - seed.y) * (tipY - seed.y))) / Math.max(1, seed.length ** 2), 0, 1);
						const distance = Math.hypot(point.x - (seed.x + ((tipX - seed.x) * along)), point.y - (seed.y + ((tipY - seed.y) * along)));
						if (seed.length > 4 && distance < 9) {
							seed.length = Math.max(3, seed.length * along);
							isCut = true;
						}
					}

					if (isCut && performance.now() - this.lastSnip > 120) {
						this.lastSnip = performance.now();
						element.#sounds.snip();
					}
				}
			},
			step(seconds) {
				this.singing = Math.max(0, this.singing - seconds);
				this.dayClock += seconds;
				if (this.dayClock >= 3) {
					this.nextDay(false);
				}
			},
			draw(context) {
				drawWall(context, '#f4e8c0');
				comicShape(context, () => {
					context.rect(0, 318, 640, 42);
				}, {fill: '#ffffff', shade: '#cccccc'});
				comicShape(context, () => {
					ellipse(context, 300, 318, 200, 20);
				}, {fill: '#a85030'});
				if (this.water > 0) {
					context.fillStyle = '#7ac0e8';
					context.beginPath();
					ellipse(context, 300, 316, 180, 12);
					context.fill();
				}

				drawRam(context, ramShape.x, ramShape.y, 1);
				const isDry = this.dryDays >= 2;
				for (const seed of this.seeds) {
					context.fillStyle = '#3a2a1a';
					context.fillRect(seed.x - 1, seed.y - 1, 2, 2);
					if (seed.length > 1) {
						const tipX = seed.x + (Math.cos(seed.angle + (isDry ? 0.6 : 0)) * seed.length);
						const tipY = seed.y + (Math.sin(seed.angle + (isDry ? 0.6 : 0)) * seed.length);
						context.strokeStyle = isDry ? '#9a8a3a' : '#5aa83a';
						context.lineWidth = 1.5;
						context.beginPath();
						context.moveTo(seed.x, seed.y);
						context.quadraticCurveTo(((seed.x + tipX) / 2) + (seed.curl * seed.length), ((seed.y + tipY) / 2), tipX, tipY);
						context.stroke();
						if (seed.length > 12) {
							context.fillStyle = isDry ? '#a89a4a' : '#3c9a2c';
							context.beginPath();
							ellipse(context, tipX - 2, tipY, 3, 1.6, seed.angle);
							ellipse(context, tipX + 2, tipY, 3, 1.6, -seed.angle);
							context.fill();
						}
					}
				}

				drawDay(context, this.day);
				drawText(context, this.water > 0 ? `Water: ${this.water} days` : 'The saucer is dry', 14, 66, {font: `bold 14px ${comicSans}`});
				if (this.singing > 0) {
					drawText(context, 'CH-CH-CH-CHIA!', 320, 70 + (Math.sin(this.singing * 20) * 4), {font: `40px ${impact}`, color: '#2a7a1a', align: 'center', stroke: 'white', strokeWidth: 5});
				}
			},
		};
	}

	// The whoopee cushion, at the Sunday dinner with Mormor.
	#makeWhoopee() {
		const element = this;
		return {
			inflation: 0,
			chair: undefined,
			event: undefined,
			tools() {
				return [
					{label: 'Blow It Up', disabled: this.inflation >= 3, action: () => this.blow()},
					{label: 'Call Mormor to Dinner', action: () => this.callMormor()},
				];
			},
			enter() {
				element.#sayStuff('Sunday dinner. Blow up the cushion, then click a chair to hide it there, and call Mormor to dinner.');
			},
			blow() {
				this.event = undefined;
				this.inflation++;
				element.#sounds.puff();
				element.#sayStuff(['Phhhooo! A little round.', 'Phhhooo! Rounder.', 'Phhhooo! Full and round, and ready. Now hide it on a chair!'][this.inflation - 1]);
			},
			pointer(type, point) {
				if (type !== 'down') {
					return;
				}

				const chair = chairs.findIndex(chair => Math.abs(chair.x - point.x) < 60 && point.y > 150);
				if (chair === -1) {
					return;
				}

				this.event = undefined;
				this.chair = chair;
				element.#sayStuff(chair === 1 ? 'On Mormor’s chair, under the knitted pillow. Perfect.' : `On ${chairs[chair].name}. Hmm. Mormor always sits in the middle.`);
			},
			callMormor() {
				const isWise = element.#state.pranks >= 2 && this.chair !== undefined;
				const target = isWise ? this.chair : (Math.random() < 0.8 ? 1 : randomItem([0, 2]));
				this.event = {time: 0, target, isWise, isSeated: false};
				element.#sayStuff('Mormor! Middag! Mormor comes from the kitchen.');
				if (element.reducedMotion) {
					this.event.time = 2.2;
					this.sit();
				}
			},
			sit() {
				const {event} = this;
				event.isSeated = true;
				const isOnCushion = event.target === this.chair;
				if (event.isWise) {
					element.#audio.rasp(1.4, {volume: 0.25});
					event.outcome = 'wise';
					event.speech = 'Hah! I had one of those in 1952, gutten min.';
					element.#state.pranks = 0;
					this.inflation = 0;
					element.#sayStuff('Mormor lifts the pillow, finds the cushion, and sits on it on purpose. PFFFRRRT! “Hah! I had one of those in 1952, gutten min.”');
				} else if (isOnCushion && this.inflation > 0) {
					element.#audio.rasp(0.4 + (this.inflation * 0.35));
					element.#state.pranks++;
					event.outcome = 'prank';
					event.speech = element.#state.pranks === 1 ? 'Uff da! Unnskyld meg! It must be the fish soup.' : 'SINDRE! I know that was you!';
					element.#sayStuff(`PFFFRRRT! Mormor jumps up. “${event.speech}”`);
					this.inflation = 0;
				} else if (isOnCushion) {
					element.#sounds.pfft();
					event.outcome = 'flat';
					event.speech = 'Is there a frog on my chair?';
					element.#sayStuff('Mormor sits on the flat cushion. Pfff. “Is there a frog on my chair?” Blow it up first!');
				} else {
					event.outcome = 'miss';
					event.speech = 'Takk! Where are the waffles?';
					element.#sayStuff(`Mormor sits on ${chairs[event.target].name}${this.chair === undefined ? '' : `, not on the cushion`}. “Takk! Where are the waffles?”`);
				}
			},
			step(seconds) {
				if (this.event) {
					this.event.time += seconds;
					if (!this.event.isSeated && this.event.time >= 2.2) {
						this.sit();
						element.#renderTools();
					}
				}
			},
			draw(context) {
				context.fillStyle = '#f0dcc0';
				context.fillRect(0, 0, 640, 360);
				context.fillStyle = 'rgba(180, 120, 90, 0.25)';
				for (let x = 0; x < 640; x += 32) {
					context.fillRect(x, 0, 12, 230);
				}

				context.fillStyle = '#8a5a30';
				context.fillRect(0, 230, 640, 130);
				comicShape(context, () => {
					context.rect(100, 190, 460, 24);
				}, {fill: '#fafafa'});
				for (const [x, y] of [[250, 186], [410, 186]]) {
					comicShape(context, () => {
						ellipse(context, x, y, 30, 8);
					}, {fill: '#e0a040', shade: '#a06010', lineWidth: 1.5});
				}

				for (const [index, chair] of chairs.entries()) {
					comicShape(context, () => {
						context.rect(chair.x - 40, 200, 80, 12);
						context.rect(chair.x - 40, 150, 10, 50);
						context.rect(chair.x - 38, 212, 8, 70);
						context.rect(chair.x + 30, 212, 8, 70);
					}, {fill: '#a0662a', shade: '#5a3a10'});
					if (index === 1) {
						comicShape(context, () => {
							context.roundRect(chair.x - 36, 188, 72, 14, 5);
						}, {fill: '#d43a3a', shade: 'white'});
					}

					if (this.chair === index && !(this.event?.isWise && this.event.isSeated)) {
						context.save();
						context.globalAlpha = index === 1 ? 0.75 : 1;
						drawCushion(context, chair.x + 8, 194, 0.7, this.inflation);
						context.restore();
					}
				}

				const {event} = this;
				if (event) {
					const target = chairs[event.target].x;
					const walk = clamp(event.time / 2.2, 0, 1);
					const x = 700 + ((target - 700) * (1 - ((1 - walk) ** 2)));
					const jump = event.outcome === 'prank' || event.outcome === 'wise' ? Math.max(0, Math.sin(clamp((event.time - 2.2) / 0.6, 0, 1) * Math.PI)) * 40 : 0;
					const y = (event.isSeated ? 150 : 120) - jump;
					comicShape(context, () => {
						context.roundRect(x - 26, y, 52, event.isSeated ? 50 : 76, 10);
					}, {fill: '#8a5aa8', shade: '#5a2a78'});
					comicShape(context, () => {
						context.rect(x - 24, y + (event.isSeated ? 46 : 70), 48, event.isSeated ? 20 : 40);
					}, {fill: '#4a4a6a'});
					drawFace(context, x, y - 22, 22, {hair: '#dddddd', hairStyle: 'bun', glasses: true, mood: event.outcome === 'prank' ? 'shock' : (event.outcome === 'wise' ? 'happy' : (event.outcome === 'flat' ? 'angry' : 'happy'))});
					if (event.speech) {
						drawBubble(context, event.speech, x, y - 54, {width: 220, tailX: x, tailY: y - 44});
					}
				}

				// Me, peeking from behind the door.
				drawFace(context, 40, 150, 22, {hairStyle: 'spiky', mood: event?.outcome === 'wise' ? 'shock' : 'happy'});
				if (this.chair === undefined) {
					drawCushion(context, 60, 300, 0.8, this.inflation);
					drawText(context, 'in my hand', 60, 340, {font: `bold 13px ${comicSans}`, align: 'center', color: 'white'});
				}
			},
		};
	}

	// The joy buzzer, and Pappa’s hand.
	#makeBuzzer() {
		const element = this;
		return {
			wound: 0,
			handX: 140,
			buzzes: 0,
			isRefused: false,
			event: undefined,
			tools() {
				return [
					{label: 'Wind It Up', disabled: this.wound >= 3, action: () => this.wind()},
					{label: 'Shake Hands with Pappa', action: () => this.shake()},
				];
			},
			enter() {
				element.#sayStuff('Wind up the joy buzzer, then shake Pappa’s hand: drag my hand to his, or press the button.');
			},
			wind() {
				this.wound++;
				element.#sounds.ratchet();
				element.#sayStuff(this.wound >= 3 ? 'Click, click, click. Wound up all the way!' : 'Click, click. Wind it some more.');
			},
			shake() {
				if (this.event && this.event.time < 0.9) {
					return;
				}

				this.handX = 300;
				if (this.isRefused) {
					this.isRefused = false;
					this.buzzes = 0;
					this.event = {time: 0, kind: 'revenge'};
					element.#audio.rasp(0.9, {frequency: 50, flutter: 35, depth: 20, type: 'square', cutoff: 1800, volume: 0.15});
					element.#sayStuff('Pappa holds out his hand at last. BZZZZT! He has a joy buzzer too! “I got mine in 1962, gutten min.”');
				} else if (this.wound === 0) {
					this.event = {time: 0, kind: 'click'};
					element.#sayStuff('Click. Nothing. Pappa: “Nice to meet you too, Sindre?” Wind it up first!');
				} else {
					this.wound--;
					this.buzzes++;
					this.event = {time: 0, kind: 'buzz'};
					element.#audio.rasp(0.8, {frequency: 55, flutter: 35, depth: 20, type: 'square', cutoff: 1800, volume: 0.15});
					const reactions = ['BZZZZT! Pappa jumps so high that his glasses fall off. “AU! Sindre!”', 'BZZZZT! “Ha. Ha. Very funny.” Pappa shakes his hand.', 'BZZZZT! Pappa puts his hands in his pockets. “No more handshakes in this house.”'];
					element.#sayStuff(reactions[Math.min(this.buzzes, 3) - 1]);
					if (this.buzzes >= 3) {
						this.isRefused = true;
					}
				}

				// Without motion, the shock is over at once, so the next handshake works.
				if (element.reducedMotion) {
					this.event.time = 1.5;
				}
			},
			pointer(type, point, isPressed) {
				if (type === 'up' || (type === 'move' && !isPressed)) {
					return;
				}

				const wasTouching = this.handX >= 296;
				this.handX = clamp(point.x, 80, 300);
				if (this.handX >= 296 && (!wasTouching || type === 'down')) {
					this.shake();
				}
			},
			step(seconds) {
				if (this.event) {
					this.event.time += seconds;
					if (this.event.time > 1.4) {
						this.handX += (140 - this.handX) * Math.min(1, seconds * 3);
					}
				}
			},
			draw(context) {
				const shaking = this.event && this.event.kind !== 'click' && this.event.time < 0.9;
				context.save();
				if (shaking) {
					context.translate(randomBetween(-4, 4), randomBetween(-4, 4));
				}

				drawWall(context, '#e0e8d8');
				// Pappa, with his newspaper on the sofa behind him.
				comicShape(context, () => {
					context.roundRect(400, 200, 160, 160, 20);
				}, {fill: '#3a6aaa', shade: '#ffffff'});
				const isPappaShocked = shaking && this.event.kind === 'buzz';
				drawFace(context, 480, 150, 44, {hair: '#6a4a2a', glasses: !(isPappaShocked && this.buzzes === 1), mustache: true, mood: isPappaShocked ? 'shock' : (this.isRefused ? 'angry' : 'happy'), hairStyle: isPappaShocked ? 'spiky' : 'short'});
				if (!this.isRefused || this.event?.kind === 'revenge') {
					comicShape(context, () => {
						context.rect(330, 236, 80, 30);
					}, {fill: '#3a6aaa'});
					comicShape(context, () => {
						context.roundRect(300, 232, 46, 38, 12);
					}, {fill: '#f5c9a0', shade: '#d09060'});
				}

				// My arm and hand, with the buzzer in the palm.
				comicShape(context, () => {
					context.rect(0, 238, this.handX - 30, 26);
				}, {fill: '#d42a2a'});
				comicShape(context, () => {
					context.roundRect(this.handX - 36, 232, 40, 36, 12);
				}, {fill: '#f5c9a0', shade: '#d09060'});
				drawBuzzer(context, this.handX - 14, 250, 0.6);
				const isMeShocked = shaking && this.event.kind === 'revenge';
				drawFace(context, 110, 160, 36, {hairStyle: 'spiky', mood: isMeShocked ? 'shock' : 'happy'});
				if (shaking) {
					context.strokeStyle = '#ffcc00';
					context.lineWidth = 4;
					for (let bolt = 0; bolt < 6; bolt++) {
						const angle = (bolt / 6) * Math.PI * 2;
						context.beginPath();
						context.moveTo(310 + (Math.cos(angle) * 30), 250 + (Math.sin(angle) * 30));
						for (let step = 1; step <= 4; step++) {
							context.lineTo(310 + (Math.cos(angle) * (30 + (step * 14))) + (step % 2 ? 7 : -7), 250 + (Math.sin(angle) * (30 + (step * 14))));
						}

						context.stroke();
					}

					starburst(context, 310, 110, 50, 'BZZZT!', {size: 24});
				}

				drawText(context, `Spring: ${'●'.repeat(this.wound)}${'○'.repeat(3 - this.wound)}`, 14, 340, {font: `bold 16px ${comicSans}`});
				context.restore();
			},
		};
	}

	// The onion gum, offered to the family.
	#makeOnionGum() {
		const element = this;
		return {
			sticks: 5,
			people: [
				{name: 'Lillesøster', x: 90, face: {hair: '#e8c860', hairStyle: 'pigtails'}, mood: 'cry', green: 0, target: 0, reaction: 'Lillesøster chews, turns green, and runs: “MAMMAAAA! Sindre gave me ONION!”'},
				{name: 'Trond', x: 210, face: {hair: '#5a3a1a', hairStyle: 'spiky'}, mood: 'sick', green: 0, target: 0, reaction: 'Trond chews, turns green, and grins: “Disgusting! Can I have one for my cousin?”'},
				{name: 'Mamma', x: 330, face: {hair: '#8a4a2a', hairStyle: 'long'}, mood: 'angry', isRefusing: true, green: 0, target: 0, reaction: 'Mamma does not even take it. “Nice try. I read the same comics in 1972.”'},
				{name: 'Rocky', x: 450, isRock: true, isRefusing: true, green: 0, target: 0, reaction: 'Rocky does not chew. Rocky is a rock. Rocky is still my best listener.'},
				{name: 'Me', x: 570, face: {hairStyle: 'spiky'}, mood: 'sick', green: 0, target: 0, reaction: 'I chew one myself, to be sure. BLEH! It really is onion. Why did I pay for this?'},
			],
			tools() {
				return this.people.map(person => ({
					label: person.name === 'Me' ? 'Chew One Myself' : `Offer One to ${person.name}`,
					disabled: person.target > 0 && !person.isRefusing,
					action: () => this.offer(person),
				}));
			},
			enter() {
				element.#sayStuff(`Onion gum, ${this.sticks} sticks. It looks just like spearmint. Who wants one?`);
			},
			offer(person) {
				if (person.isRefusing) {
					person.target = 0.01;
					element.#sayStuff(person.reaction);
					return;
				}

				if (this.sticks === 0) {
					element.#sayStuff('The pack is empty. It still smells of onion.');
					return;
				}

				this.sticks--;
				person.target = 1;
				if (element.reducedMotion) {
					person.green = 1;
				}

				if (person.name === 'Lillesøster') {
					this.people[2].target = 0.01;
				}

				element.#sayStuff(`${person.reaction} ${this.sticks === 0 ? 'That was the last stick.' : `${this.sticks} left.`}`);
			},
			step(seconds) {
				for (const person of this.people) {
					person.green += (person.target - person.green) * Math.min(1, seconds * 2);
				}
			},
			draw(context) {
				drawWall(context, '#fff4d8');
				comicShape(context, () => {
					context.rect(0, 300, 640, 60);
				}, {fill: '#b07840'});
				for (const person of this.people) {
					if (person.isRock) {
						comicShape(context, () => {
							ellipse(context, person.x, 200, 46, 34);
						}, {fill: '#9a9a9a', shade: '#555555'});
						for (const side of [-1, 1]) {
							comicShape(context, () => {
								context.arc(person.x + (side * 14), 192, 9, 0, Math.PI * 2);
							}, {fill: 'white', lineWidth: 1.5});
							context.fillStyle = ink;
							context.beginPath();
							context.arc(person.x + (side * 14) + 2, 195, 4, 0, Math.PI * 2);
							context.fill();
						}
					} else {
						const isAngryMamma = person.name === 'Mamma' && person.target > 0;
						comicShape(context, () => {
							context.roundRect(person.x - 34, 238, 68, 70, 14);
						}, {fill: ['#d42a2a', '#2a8a4a', '#aa5aa8', '#888888', '#3a6aaa'][this.people.indexOf(person)]});
						drawFace(context, person.x, 200, 38, {...person.face, mood: person.green > 0.4 ? person.mood : (isAngryMamma ? 'angry' : 'happy'), green: person.green});
					}

					drawText(context, person.name, person.x, 340, {font: `bold 16px ${comicSans}`, align: 'center', color: 'white', stroke: ink});
				}

				drawGumPack(context, 90, 70, 1, this.sticks);
				drawText(context, `${this.sticks} left`, 140, 76, {font: `bold 14px ${comicSans}`});
			},
		};
	}

	// The crystals that grow in a jar.
	#makeCrystals() {
		const element = this;
		return {
			stage: 'empty',
			dissolved: 0,
			day: 0,
			dayClock: 0,
			color: '#6a7aff',
			crystals: [],
			stirring: 0,
			quality: 0,
			last: undefined,
			tools() {
				return [
					{label: 'Pour In the Powder', disabled: this.stage !== 'empty', action: () => this.pour()},
					{label: 'Stir', disabled: this.stage !== 'powder', action: () => this.stir(0.25)},
					{label: 'Drop In the Rock', disabled: this.stage !== 'powder', action: () => this.dropRock()},
					{label: 'Wait a Day', disabled: this.stage !== 'rock', action: () => this.nextDay(true)},
				];
			},
			enter() {
				element.#sayStuff(this.stage === 'empty' ? 'A cup of warm water. Pour in the magic crystal powder!' : `My crystals, day ${this.day}.`);
			},
			pour() {
				this.stage = 'powder';
				this.color = randomItem(['#6a7aff', '#ff5aa8', '#38c8a0']);
				element.#sounds.splash();
				element.#sayStuff('The magic crystal powder goes in. It looks like milk. Stir until it is clear: press Stir, or drag around in the cup.');
			},
			stir(amount) {
				const wasDissolved = this.dissolved >= 1;
				this.dissolved = Math.min(1, this.dissolved + amount);
				this.stirring = element.reducedMotion ? 0 : 0.6;
				if (!wasDissolved && this.dissolved >= 1) {
					element.#sayStuff('All dissolved! The water is clear. Drop in the growing rock.');
				}
			},
			dropRock() {
				this.stage = 'rock';
				this.quality = 0.3 + (this.dissolved * 0.7);
				this.crystals = Array.from({length: 5}, (_, index) => ({x: 300 + ((index - 2) * 9), angle: -Math.PI / 2 + ((index - 2) * 0.35), length: 3, width: randomBetween(4, 7)}));
				element.#sounds.splash();
				element.#sayStuff(this.dissolved < 1 ? 'Plop. The powder is not all dissolved, so the water stays cloudy. Hmm.' : 'Plop! The rock sinks. The box says a castle in 24 hours.');
			},
			nextDay(isManual) {
				this.day++;
				this.dayClock = 0;
				if (this.day <= 7) {
					for (const crystal of this.crystals) {
						crystal.length += randomBetween(2, 6) * this.quality;
						crystal.width += 0.5;
					}

					if (this.crystals.length < 16) {
						const parent = randomItem(this.crystals);
						this.crystals.push({x: parent.x + randomBetween(-12, 12), angle: parent.angle + randomBetween(-0.7, 0.7), length: 2, width: randomBetween(3, 6)});
					}
				}

				if (this.day === 1) {
					element.#sayStuff('24 hours! The castle is... a crust. A small crust.');
				} else if (this.day === 7) {
					element.#sayStuff('One week. It is a crusty lump the size of a walnut. It sparkles a little under the lamp. The ad had a castle.');
				} else if (this.day === 9) {
					element.#sayStuff('It does not grow anymore. Mamma: “It looks like the inside of the kettle.”');
				} else if (isManual) {
					element.#sayStuff(`Day ${this.day}. ${this.day > 7 ? 'Still a lump.' : 'A tiny bit bigger.'}`);
				}
			},
			pointer(type, point, isPressed) {
				if (this.stage !== 'powder' || !isPressed || point.x < 220 || point.x > 380 || point.y < 120) {
					this.last = undefined;
					return;
				}

				if (this.last) {
					this.stir(Math.hypot(point.x - this.last.x, point.y - this.last.y) / 2500);
				}

				this.last = point;
			},
			step(seconds) {
				this.stirring = Math.max(0, this.stirring - seconds);
				if (this.stage === 'rock' && this.day < 9) {
					this.dayClock += seconds;
					if (this.dayClock >= 3) {
						this.nextDay(false);
					}
				}
			},
			draw(context) {
				drawWall(context, '#d8e4ec');
				// The window behind, with the rain of Bergen.
				comicShape(context, () => {
					context.rect(380, 110, 220, 190);
				}, {fill: '#9aa8b4'});
				context.strokeStyle = 'rgba(255, 255, 255, 0.5)';
				context.lineWidth = 1;
				context.beginPath();
				for (let index = 0; index < 30; index++) {
					const x = 390 + ((index * 37) % 200);
					const y = 120 + ((index * 53) % 160);
					context.moveTo(x, y);
					context.lineTo(x - 2, y + 10);
				}

				context.stroke();
				comicShape(context, () => {
					context.rect(0, 300, 640, 60);
				}, {fill: '#ffffff', shade: '#cccccc'});
				const left = 230;
				const right = 370;
				const top = 130;
				const bottom = 300;
				if (this.stage !== 'empty') {
					context.fillStyle = mixColor(this.color, '#ffffff', 0.55);
					context.globalAlpha = 0.6;
					context.fillRect(left + 4, top + 30, right - left - 8, bottom - top - 34);
					context.globalAlpha = 1;
					if (this.dissolved < 1) {
						context.fillStyle = `rgba(255, 255, 255, ${0.8 * (1 - this.dissolved)})`;
						context.fillRect(left + 4, top + 30, right - left - 8, bottom - top - 34);
					}
				} else {
					context.fillStyle = 'rgba(200, 225, 245, 0.5)';
					context.fillRect(left + 4, top + 30, right - left - 8, bottom - top - 34);
				}

				if (this.stage === 'rock') {
					for (const crystal of this.crystals) {
						const baseY = 282;
						const tipX = crystal.x + (Math.cos(crystal.angle) * crystal.length);
						const tipY = baseY + (Math.sin(crystal.angle) * crystal.length);
						const sideX = Math.cos(crystal.angle + (Math.PI / 2)) * crystal.width / 2;
						const sideY = Math.sin(crystal.angle + (Math.PI / 2)) * crystal.width / 2;
						comicShape(context, () => {
							context.moveTo(crystal.x - sideX, baseY - sideY);
							context.lineTo(tipX - sideX, tipY - sideY);
							context.lineTo(tipX + (Math.cos(crystal.angle) * crystal.width * 0.6), tipY + (Math.sin(crystal.angle) * crystal.width * 0.6));
							context.lineTo(tipX + sideX, tipY + sideY);
							context.lineTo(crystal.x + sideX, baseY + sideY);
							context.closePath();
						}, {fill: this.color, shade: 'rgba(255, 255, 255, 0.5)', lineWidth: 1});
					}

					comicShape(context, () => {
						ellipse(context, 300, 288, 26, 12);
					}, {fill: '#888888', shade: '#444444'});
				}

				comicShape(context, () => {
					context.moveTo(left, top);
					context.lineTo(left + 6, bottom);
					context.lineTo(right - 6, bottom);
					context.lineTo(right, top);
				}, {fill: 'rgba(255, 255, 255, 0.15)', lineWidth: 3});
				if (this.stirring > 0) {
					const angle = this.stirring * 20;
					comicShape(context, () => {
						context.moveTo(300 + (Math.cos(angle) * 30), 240);
						context.lineTo(330 + (Math.cos(angle) * 10), 90);
						context.lineTo(336 + (Math.cos(angle) * 10), 92);
						context.lineTo(306 + (Math.cos(angle) * 30), 242);
						context.closePath();
					}, {fill: '#d0d4d8', lineWidth: 1.5});
				}

				drawDay(context, this.day);
				if (this.day >= 7) {
					drawBubble(context, 'The castle?', 160, 150, {width: 120, tailX: 250, tailY: 260});
				}
			},
		};
	}

	// The art test: draw Tippy, mail it in, and get the letter back.
	#makeArtTest() {
		const element = this;
		return {
			strokes: [],
			view: element.#state.letter?.isRead ? 'letter' : 'test',
			tools() {
				const isMailed = element.#state.letter !== undefined;
				const tools = [
					{label: 'Erase', disabled: isMailed || this.strokes.length === 0, action: () => {
						this.strokes = [];
						element.#sayStuff('Erased. Try again: copy Tippy, do not trace him.');
					}},
					{label: `Mail It In (${stampPrice} kr)`, disabled: isMailed, action: () => this.mail()},
				];
				if (element.#state.letter?.isRead) {
					tools.push({label: 'Read the Letter', pressed: this.view === 'letter', action: () => {
						this.view = this.view === 'letter' ? 'test' : 'letter';
						if (this.view === 'letter') {
							this.sayLetter();
						}
					}});
				}

				return tools;
			},
			enter() {
				if (this.view === 'letter') {
					this.sayLetter();
				} else {
					element.#sayStuff(element.#state.letter ? 'My drawing of Tippy is in the mail to the art school. Allow 6 to 8 weeks.' : 'Draw Tippy on the paper on the right, then mail it in for a professional opinion. Free!');
				}
			},
			ink() {
				let length = 0;
				for (const stroke of this.strokes) {
					for (let index = 1; index < stroke.length; index++) {
						length += Math.hypot(stroke[index].x - stroke[index - 1].x, stroke[index].y - stroke[index - 1].y);
					}
				}

				return Math.round(length);
			},
			comment() {
				const amount = element.#state.letter?.ink ?? 0;
				if (amount < 20) {
					return 'We especially liked your bold use of white space.';
				}

				if (amount < 600) {
					return 'Your simple lines remind us of Picasso.';
				}

				return 'Such energy! Such pencil!';
			},
			sayLetter() {
				element.#sayStuff(`The letter: “Dear Sindre, YOU HAVE TALENT! ${this.comment()} Enroll today: only 4 995 kroner.” Mamma: “No representative is coming to this house.”`);
			},
			mail() {
				if (element.#state.balance < stampPrice) {
					element.#sayStuff(`A stamp costs ${stampPrice} kr, and the piggy bank is empty. Return a bottle!`);
					return;
				}

				element.#state.balance -= stampPrice;
				element.#state.letter = {arrives: element.#state.week + randomInteger(6, 8), ink: this.ink(), isRead: false};
				element.#persist();
				element.#renderBalance();
				element.#shakePiggy();
				element.#sounds.lick();
				element.#drawMailbox();
				element.#sayStuff(`Off it goes to the art school, with a ${stampPrice} kr stamp${this.strokes.length === 0 ? ', and no drawing at all. Let us see what the experts say' : ''}. Allow 6 to 8 weeks for their professional opinion.`);
			},
			pointer(type, point, isPressed) {
				if (element.#state.letter || this.view !== 'test') {
					return;
				}

				const isOnPaper = point.x > paper.left && point.x < paper.right && point.y > paper.top && point.y < paper.bottom;
				if (type === 'down' && isOnPaper) {
					this.strokes.push([point]);
				} else if (type === 'move' && isPressed && isOnPaper && this.strokes.length > 0) {
					this.strokes.at(-1).push(point);
				}
			},
			draw(context) {
				drawWall(context, '#e8dcc8');
				if (this.view === 'letter') {
					comicShape(context, () => {
						context.rect(70, 20, 420, 330);
					}, {fill: '#fffef8'});
					drawText(context, 'THE FAMOUS ART ACADEMY', 280, 52, {font: `20px ${times}`, align: 'center', color: '#1a2a6a'});
					drawText(context, 'Minneapolis, Minnesota, U.S.A.', 280, 70, {font: `italic 12px ${times}`, align: 'center'});
					let y = drawWrapped(context, 'Dear Sindre S., our panel of professional artists has studied your drawing of Tippy.', 90, 100, 380, 18, {font: `15px ${times}`});
					drawText(context, 'YOU HAVE TALENT!', 280, y + 18, {font: `24px ${impact}`, color: '#d40000', align: 'center'});
					y = drawWrapped(context, `${this.comment()} Enroll today in our Complete Course in Commercial Art: only 4 995 kroner, or 99 kroner a month for 5 years. A representative will visit your parents soon.`, 90, y + 46, 380, 18, {font: `15px ${times}`});
					starburst(context, 430, 300, 40, 'A+', {size: 26});
					drawBubble(context, 'No representative is coming to this house!', 560, 250, {width: 150, tailX: 600, tailY: 290});
					drawFace(context, 600, 316, 26, {hair: '#8a4a2a', hairStyle: 'long', mood: 'angry'});
					return;
				}

				comicShape(context, () => {
					context.rect(14, 60, 310, 290);
				}, {fill: '#fffef8'});
				drawText(context, 'DRAW TIPPY', 169, 92, {font: `26px ${impact}`, color: '#d40000', align: 'center'});
				drawText(context, 'Copy him. Do not trace!', 169, 112, {font: `italic 14px ${times}`, align: 'center'});
				drawTippy(context, 150, 230, 1.6, {color: false});
				comicShape(context, () => {
					context.rect(paper.left, paper.top, paper.right - paper.left, paper.bottom - paper.top);
				}, {fill: 'white'});
				drawText(context, 'Your drawing:', paper.left + 8, paper.top + 18, {font: `italic 13px ${times}`});
				context.strokeStyle = '#444444';
				context.lineWidth = 2.5;
				context.lineCap = 'round';
				context.lineJoin = 'round';
				for (const stroke of this.strokes) {
					context.beginPath();
					for (const point of stroke) {
						context.lineTo(point.x, point.y);
					}

					if (stroke.length === 1) {
						context.lineTo(stroke[0].x + 0.5, stroke[0].y);
					}

					context.stroke();
				}

				context.lineCap = 'butt';
				if (element.#state.letter && !element.#state.letter.isRead) {
					context.save();
					context.translate(480, 230);
					context.rotate(-0.25);
					context.strokeStyle = '#d40000';
					context.lineWidth = 4;
					context.strokeRect(-80, -26, 160, 52);
					drawText(context, 'MAILED', 0, 12, {font: `36px ${impact}`, color: '#d40000', align: 'center'});
					context.restore();
				}
			},
		};
	}

	// The real hovercraft for 99 kroner, which is a sheet of plans.
	#makeHovercraft() {
		const element = this;
		return {
			borrowed: new Set(),
			view: 'plans',
			event: undefined,
			tools() {
				return [
					{label: 'Borrow Mamma’s Vacuum Cleaner', disabled: this.borrowed.has('vacuum'), action: () => this.borrow('vacuum')},
					{label: 'Borrow Lillesøster’s Sled', disabled: this.borrowed.has('sled'), action: () => this.borrow('sled')},
					{label: 'Borrow a Garbage Bag', disabled: this.borrowed.has('bag'), action: () => this.borrow('bag')},
					{label: 'Start It!', disabled: this.borrowed.size < 3, action: () => this.start()},
					{label: 'Look at the Plans', pressed: this.view === 'plans', action: () => {
						this.view = this.view === 'plans' ? 'garage' : 'plans';
					}},
				];
			},
			enter() {
				element.#sayStuff('The real hovercraft for 99 kroner: one sheet of plans. Motor, plywood, skirt, and fan not included. Maybe there is something in the house?');
			},
			borrow(part) {
				this.borrowed.add(part);
				this.view = 'garage';
				this.event = undefined;
				element.#sayStuff({
					vacuum: 'The vacuum cleaner from the closet. Mamma is at work. It is fine.',
					sled: 'Lillesøster’s red plastic sled. She will not need it until it snows. In Bergen, that is never.',
					bag: 'A black garbage bag for the skirt. The plans say heavy vinyl. Close enough.',
				}[part]);
			},
			start() {
				this.view = 'garage';
				this.event = {time: 0, isMammaThere: false};
				element.#sounds.vacuum();
				element.#sayStuff('VRRRRRMMMM! It lifts... two millimeters! It slides! Top speed: 0.3 km/h. Faster than a moped? No.');
				if (element.reducedMotion) {
					this.event.time = 3;
					this.arrive();
				}
			},
			arrive() {
				this.event.isMammaThere = true;
				this.borrowed.clear();
				element.#sayStuff('Mamma comes home: “SINDRE! Is that my Electrolux?!” Everything goes back where it came from.');
				element.#renderTools();
			},
			step(seconds) {
				if (this.event && !this.event.isMammaThere) {
					this.event.time += seconds;
					if (this.event.time >= 3) {
						this.arrive();
					}
				}
			},
			draw(context) {
				if (this.view === 'plans') {
					context.fillStyle = '#1f4f9a';
					context.fillRect(0, 0, 640, 360);
					context.strokeStyle = 'rgba(255, 255, 255, 0.12)';
					context.lineWidth = 1;
					context.beginPath();
					for (let x = 0; x <= 640; x += 20) {
						context.moveTo(x, 0);
						context.lineTo(x, 360);
					}

					for (let y = 0; y <= 360; y += 20) {
						context.moveTo(0, y);
						context.lineTo(640, y);
					}

					context.stroke();
					context.strokeStyle = 'white';
					context.lineWidth = 2;
					context.beginPath();
					context.moveTo(80, 230);
					context.lineTo(120, 190);
					context.lineTo(400, 190);
					context.lineTo(440, 230);
					context.closePath();
					context.rect(100, 230, 320, 30);
					context.rect(330, 130, 60, 60);
					context.arc(360, 160, 26, 0, Math.PI * 2);
					context.rect(180, 160, 50, 30);
					context.stroke();
					const labels = [['ENGINE: 5 HP LAWNMOWER (NOT INCLUDED)', 205, 160, 30, 60], ['FAN: 24 IN. (NOT INCLUDED)', 360, 130, 300, 100], ['PLYWOOD, 8 × 4 FT (NOT INCLUDED)', 250, 210, 40, 300], ['SKIRT: HEAVY VINYL (NOT INCLUDED)', 400, 255, 360, 320]];
					context.font = `12px ui-monospace, Menlo, monospace`;
					for (const [text, fromX, fromY, toX, toY] of labels) {
						context.beginPath();
						context.moveTo(fromX, fromY);
						context.lineTo(toX + 10, toY - 4);
						context.stroke();
						drawText(context, text, toX, toY + 10, {font: `12px ui-monospace, Menlo, monospace`, color: 'white'});
					}

					drawText(context, 'HOVERCRAFT · SHEET 1 OF 1', 20, 34, {font: `20px ${impact}`, color: 'white'});
					context.save();
					context.translate(470, 250);
					context.rotate(-0.2);
					context.strokeStyle = '#ff4a4a';
					context.lineWidth = 4;
					context.strokeRect(-80, -24, 160, 48);
					drawText(context, 'PLANS ONLY', 0, 10, {font: `28px ${impact}`, color: '#ff4a4a', align: 'center'});
					context.restore();
					return;
				}

				// The garage, with what I could find.
				context.fillStyle = '#9a9a92';
				context.fillRect(0, 0, 640, 360);
				context.fillStyle = '#6a6a64';
				context.fillRect(0, 270, 640, 90);
				const time = this.event?.time ?? 0;
				const isRunning = this.event !== undefined && !this.event.isMammaThere;
				const lift = isRunning ? Math.min(4, time * 3) + (Math.sin(time * 40) * 1) : 0;
				const slide = this.event ? Math.min(3, time) * 12 : 0;
				context.save();
				context.translate(slide, -lift);
				if (this.borrowed.has('bag')) {
					comicShape(context, () => {
						ellipse(context, 260, 262, 120, 18);
					}, {fill: '#1a1a1a', shade: '#444444'});
				}

				if (this.borrowed.has('sled')) {
					comicShape(context, () => {
						context.moveTo(140, 250);
						context.lineTo(380, 250);
						context.quadraticCurveTo(410, 250, 400, 228);
						context.lineTo(150, 236);
						context.closePath();
					}, {fill: '#e8322a', shade: '#9a0a0a'});
				}

				if (this.borrowed.has('vacuum')) {
					comicShape(context, () => {
						context.roundRect(210, 168, 90, 62, 20);
					}, {fill: '#d4c040', shade: '#8a7a10'});
					drawText(context, 'VAC', 255, 206, {font: `16px ${impact}`, align: 'center'});
					context.strokeStyle = '#333333';
					context.lineWidth = 6;
					context.beginPath();
					context.moveTo(300, 200);
					context.quadraticCurveTo(360, 200, 350, 255);
					context.stroke();
				}

				context.restore();
				if (isRunning) {
					context.fillStyle = 'rgba(255, 255, 255, 0.7)';
					for (let index = 0; index < 8; index++) {
						context.beginPath();
						context.arc(140 + slide + (index * 34), 276 + (Math.sin((time * 30) + index) * 3), 5, 0, Math.PI * 2);
						context.fill();
					}

					drawText(context, 'VRRRRMMMM!', 320, 120, {font: `40px ${impact}`, color: '#d40000', align: 'center', stroke: 'white', strokeWidth: 5});
				}

				if (this.borrowed.size === 0 && !this.event) {
					drawBubble(context, 'The garage is empty. Borrow some parts!', 300, 160, {width: 260, tailX: 300, tailY: 180});
				}

				if (this.event?.isMammaThere) {
					drawFace(context, 560, 200, 40, {hair: '#8a4a2a', hairStyle: 'long', mood: 'angry'});
					drawBubble(context, 'SINDRE! Is that my Electrolux?!', 470, 140, {width: 220, tailX: 540, tailY: 170});
				}
			},
		};
	}

	#makeToys() {
		return {
			'sea-monkeys': this.#makeSeaMonkeys(),
			'x-ray-specs': this.#makeSpecs(),
			chia: this.#makeChia(),
			whoopee: this.#makeWhoopee(),
			buzzer: this.#makeBuzzer(),
			'onion-gum': this.#makeOnionGum(),
			crystals: this.#makeCrystals(),
			draw: this.#makeArtTest(),
			hovercraft: this.#makeHovercraft(),
		};
	}

	#renderTabs() {
		const owned = catalogOrder.filter(id => this.#state.items[id]?.status === 'mine');
		this.#stuff.tabs.clear();
		this.parts.stuffTabs.replaceChildren(...owned.map(id => {
			const button = this.parts.stuffTab.content.firstElementChild.cloneNode(true);
			button.textContent = catalog[id].name;
			button.addEventListener('click', () => {
				this.#selectToy(id);
			});
			setPressed(button, id === this.#stuff.selected);
			this.#stuff.tabs.set(id, button);
			return button;
		}));
	}

	#renderTools() {
		const tools = this.#stuff.selected ? this.#toys[this.#stuff.selected].tools() : [];
		this.#stuff.tools = tools;
		const buttons = [...this.parts.stuffTools.children];
		for (const [index, tool] of tools.entries()) {
			let button = buttons[index];
			if (!button) {
				button = this.parts.stuffTool.content.firstElementChild.cloneNode(true);
				button.addEventListener('click', () => {
					this.#stuff.tools[index]?.action();
					this.#afterInput();
				});
				this.parts.stuffTools.append(button);
			}

			button.textContent = tool.label;
			button.disabled = Boolean(tool.disabled);
			if (tool.pressed === undefined) {
				button.removeAttribute('aria-pressed');
				delete button.dataset.state;
			} else {
				setPressed(button, tool.pressed);
			}
		}

		for (const button of buttons.slice(tools.length)) {
			button.remove();
		}
	}

	#drawStuff() {
		const context = this.#stuffContext;
		if (!this.#stuff.selected) {
			drawWall(context, '#e8dcc8');
			comicShape(context, () => {
				context.rect(60, 220, 520, 20);
			}, {fill: '#a0703a'});
			drawText(context, 'My shelf for stuff from the mail.', 320, 160, {font: `22px ${comicSans}`, align: 'center'});
			drawText(context, 'It is empty. For now!', 320, 196, {font: `18px ${comicSans}`, align: 'center'});
			return;
		}

		this.#toys[this.#stuff.selected].draw(context);
		const ad = this.#ads.get(this.#stuff.selected);
		if (ad) {
			comicShape(context, () => {
				context.rect(500, 6, 134, 92);
			}, {fill: '#fffbe8'});
			context.drawImage(ad.canvas, 503, 9, 128, 80);
			drawText(context, 'THE AD', 567, 94, {font: `14px ${impact}`, color: '#d40000', align: 'center', stroke: 'white'});
		}

		if (this.#stuff.showCursor && document.activeElement === this.parts.stuffCanvas) {
			const {x, y} = this.#stuff.cursor;
			context.strokeStyle = '#ff00ff';
			context.lineWidth = 2;
			context.beginPath();
			context.arc(x, y, 8, 0, Math.PI * 2);
			context.moveTo(x - 14, y);
			context.lineTo(x + 14, y);
			context.moveTo(x, y - 14);
			context.lineTo(x, y + 14);
			context.stroke();
		}
	}

	#afterInput() {
		this.#renderTools();
		this.#drawStuff();
		this.#stuffLoop.start();
	}

	#selectToy(id) {
		this.#stuff.selected = id;
		for (const [tabId, button] of this.#stuff.tabs) {
			setPressed(button, tabId === id);
		}

		this.#toys[id].enter?.();
		this.#afterInput();
	}

	#startOver() {
		if (!confirm('Start over with a new comic? All the coupons come back, the piggy bank is refilled, and my stuff from the mail goes away.')) {
			return;
		}

		if (this.#xray.isOn) {
			this.#xray.off();
		}

		Object.assign(this.#state, {balance: 120, week: 37, items: {}, approved: [], mormorWeek: 0, letter: undefined, bottlesLeft: 6, pranks: 0});
		this.#persist();
		this.#toys = this.#makeToys();
		this.#stuff.selected = undefined;
		this.#mail.announced.clear();
		this.#closeMamma();
		this.#renderBalance();
		this.#goIdle();
		this.#renderAds();
		this.#renderTabs();
		this.#renderTools();
		this.#drawStuff();
		this.#drawMailbox();
		this.#sayBank('A brand new comic book, with all the coupons, and 120 kr in the piggy bank!');
	}
}
