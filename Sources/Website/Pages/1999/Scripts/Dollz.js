// Lillesøster’s Dollz corner on the 1999 page: a Dollz Maker that draws a real pixel doll at 1x on a canvas, which the page scales up with crisp pixels. Every piece is drawn into its own layer with shapes, shaded with a ramp of its color (light from the top left), and gets a black outline, like the dollz that kids drew in MS Paint. The recolor tool swaps the ramp of a piece. The glitter and the blinking only animate while the doll is on the screen and the tab is visible, and never for visitors who prefer reduced motion. The Dollz House keeps the saved dolls in the browser. Nothing here makes a sound.
const nextFrame = () => new Promise(resolve => {
	requestAnimationFrame(() => {
		resolve();
	});
});

const randomItem = items => items[Math.floor(Math.random() * items.length)];

const clamp = (value, minimum, maximum) => Math.min(Math.max(value, minimum), maximum);

// Shows a toggle button as pressed, for screen readers and for the style.
const setPressed = (button, isPressed) => {
	button.setAttribute('aria-pressed', String(isPressed));
	button.dataset.state = isPressed ? 'on' : '';
};

// The size of the canvas of the doll in Swift, in pixels. The pieces of the doll are drawn for this size.
const width = 128;
const height = 200;

// The doll is drawn in its own coordinates, and this many rows lower on the canvas, so there is room for her name above her.
const top = 8;

// Colors

const parse = hex => [Number.parseInt(hex.slice(1, 3), 16), Number.parseInt(hex.slice(3, 5), 16), Number.parseInt(hex.slice(5, 7), 16)];

const toHex = channels => '#' + channels.map(channel => Math.round(clamp(channel, 0, 255)).toString(16).padStart(2, '0')).join('');

const mix = (hex, otherHex, amount) => {
	const color = parse(hex);
	const other = parse(otherHex);
	return toHex(color.map((channel, index) => channel + ((other[index] - channel) * amount)));
};

// A ramp of four shades of a color. The shadows lean purple, like the shading of the dollz.
const rampColors = (hex, shadow = '#2a0838') => ({
	light: mix(hex, '#ffffff', 0.5),
	base: hex,
	shade: mix(hex, shadow, 0.3),
	deep: mix(hex, shadow, 0.55),
});

// Skin gets warm shadows, not purple ones.
const skinShadow = '#8a2a1a';

// Shapes, in the coordinates of the doll. A pixel is inside a shape when its center is.

const ellipse = (centerX, centerY, radiusX, radiusY = radiusX) => ({
	left: centerX - radiusX,
	top: centerY - radiusY,
	right: centerX + radiusX,
	bottom: centerY + radiusY,
	contains: (x, y) => (((x - centerX) / radiusX) ** 2) + (((y - centerY) / radiusY) ** 2) <= 1,
});

const rectangle = (x, y, rectangleWidth, rectangleHeight) => ({
	left: x,
	top: y,
	right: x + rectangleWidth,
	bottom: y + rectangleHeight,
	contains: (pointX, pointY) => pointX >= x && pointX < x + rectangleWidth && pointY >= y && pointY < y + rectangleHeight,
});

const polygon = points => ({
	left: Math.min(...points.map(point => point[0])),
	top: Math.min(...points.map(point => point[1])),
	right: Math.max(...points.map(point => point[0])),
	bottom: Math.max(...points.map(point => point[1])),
	contains(x, y) {
		let isInside = false;
		for (let index = 0, previous = points.length - 1; index < points.length; previous = index++) {
			const [x1, y1] = points[index];
			const [x2, y2] = points[previous];
			if ((y1 > y) !== (y2 > y) && x < ((x2 - x1) * (y - y1) / (y2 - y1)) + x1) {
				isInside = !isInside;
			}
		}

		return isInside;
	},
});

// A tube between two points that gets thinner or thicker from one end to the other, like an arm.
const capsule = ([x1, y1, radius1], [x2, y2, radius2]) => {
	const deltaX = x2 - x1;
	const deltaY = y2 - y1;
	const lengthSquared = (deltaX ** 2) + (deltaY ** 2) || 1;
	const largest = Math.max(radius1, radius2);
	return {
		left: Math.min(x1, x2) - largest,
		top: Math.min(y1, y2) - largest,
		right: Math.max(x1, x2) + largest,
		bottom: Math.max(y1, y2) + largest,
		contains(x, y) {
			const along = clamp((((x - x1) * deltaX) + ((y - y1) * deltaY)) / lengthSquared, 0, 1);
			const radius = radius1 + ((radius2 - radius1) * along);
			return ((x - (x1 + (deltaX * along))) ** 2) + ((y - (y1 + (deltaY * along))) ** 2) <= radius ** 2;
		},
	};
};

const union = (...shapes) => {
	const parts = shapes.filter(Boolean);
	return {
		left: Math.min(...parts.map(shape => shape.left)),
		top: Math.min(...parts.map(shape => shape.top)),
		right: Math.max(...parts.map(shape => shape.right)),
		bottom: Math.max(...parts.map(shape => shape.bottom)),
		contains: (x, y) => parts.some(shape => shape.contains(x, y)),
	};
};

// A chain of tubes through points of `[x, y, radius]`, like a whole arm or a strand of hair.
const chain = (points, extra = 0) => union(...points.slice(1).map((point, index) => capsule(
	[points[index][0], points[index][1], points[index][2] + extra],
	[point[0], point[1], point[2] + extra],
)));

const subtract = (shape, ...holes) => ({
	...shape,
	contains: (x, y) => shape.contains(x, y) && !holes.some(hole => hole.contains(x, y)),
});

// Only the part of a shape between two rows and two columns.
const clip = (shape, {top: clipTop = -Infinity, bottom = Infinity, left = -Infinity, right = Infinity}) => ({
	left: Math.max(shape.left, left),
	top: Math.max(shape.top, clipTop),
	right: Math.min(shape.right, right),
	bottom: Math.min(shape.bottom, bottom),
	contains: (x, y) => y >= clipTop && y < bottom && x >= left && x < right && shape.contains(x, y),
});

// A shape made fatter by about `amount` pixels on every side, for the clothes over the body.
const grow = (shape, amount) => ({
	left: shape.left - amount,
	top: shape.top - amount,
	right: shape.right + amount,
	bottom: shape.bottom + amount,
	contains: (x, y) => shape.contains(x, y)
		|| shape.contains(x - amount, y) || shape.contains(x + amount, y)
		|| shape.contains(x, y - amount) || shape.contains(x, y + amount)
		|| shape.contains(x - (amount * 0.7), y - (amount * 0.7)) || shape.contains(x + (amount * 0.7), y - (amount * 0.7))
		|| shape.contains(x - (amount * 0.7), y + (amount * 0.7)) || shape.contains(x + (amount * 0.7), y + (amount * 0.7)),
});

// A stable random number from 0 to 1 for a pixel, so textures and glitter look the same every time.
const hash = (x, y, seed = 0) => {
	let value = Math.imul((x * 374_761_393) + (y * 668_265_263) + (seed * 2_147_483_647), 1_274_126_177);
	value = Math.imul(value ^ (value >>> 13), 1_103_515_245);
	return ((value ^ (value >>> 16)) >>> 0) / 4_294_967_296;
};

// A layer is one piece of the doll, like her hair, with its own colors. A pixel holds the number of its color, and 0 is empty.
class Layer {
	constructor({glitter = false, outline = true} = {}) {
		this.pixels = new Uint8Array(width * height);
		this.colors = [undefined];
		this.glitter = glitter;
		this.hasOutline = outline;
		this.outlineColor = this.color('#000000');
	}

	color(hex) {
		let index = this.colors.indexOf(hex);
		if (index === -1) {
			this.colors.push(hex);
			index = this.colors.length - 1;
		}

		return index;
	}

	ramp(hex, shadow) {
		const colors = rampColors(hex, shadow);
		return {
			light: this.color(colors.light),
			base: this.color(colors.base),
			shade: this.color(colors.shade),
			deep: this.color(colors.deep),
		};
	}

	get(x, y) {
		const row = y + top;
		if (x < 0 || x >= width || row < 0 || row >= height) {
			return 0;
		}

		return this.pixels[(row * width) + x];
	}

	set(x, y, value) {
		const row = y + top;
		if (x >= 0 && x < width && row >= 0 && row < height) {
			this.pixels[(row * width) + x] = value;
		}
	}

	// Paints every pixel of the shape, with a color or with a function of the pixel that gives the color.
	fill(shape, value) {
		const startY = Math.max(Math.floor(shape.top), -top);
		const endY = Math.min(Math.ceil(shape.bottom), height - top);
		const startX = Math.max(Math.floor(shape.left), 0);
		const endX = Math.min(Math.ceil(shape.right), width);
		for (let y = startY; y < endY; y++) {
			for (let x = startX; x < endX; x++) {
				if (shape.contains(x + 0.5, y + 0.5)) {
					const color = typeof value === 'function' ? value(x, y, this.get(x, y)) : value;
					if (color !== undefined) {
						this.set(x, y, color);
					}
				}
			}
		}
	}

	erase(shape) {
		this.fill(shape, 0);
	}

	// Changes the pixels of one color to another, only inside the shape, if there is one.
	swap(from, to, shape) {
		this.fill(shape ?? rectangle(0, -top, width, height), (x, y, current) => current === from ? to : undefined);
	}

	// A line of pixels from one point to another, only where the layer is not empty if `onlyInside` says so.
	line(x1, y1, x2, y2, value, onlyInside = false) {
		const steps = Math.max(Math.abs(x2 - x1), Math.abs(y2 - y1), 1);
		for (let step = 0; step <= steps; step++) {
			const x = Math.round(x1 + ((x2 - x1) * step / steps));
			const y = Math.round(y1 + ((y2 - y1) * step / steps));
			if (!onlyInside || this.get(x, y) !== 0) {
				this.set(x, y, value);
			}
		}
	}

	// Pixels from rows of letters, where each letter is a color in `key`, and other letters are left alone.
	pattern(x, y, rows, key, isMirrored = false) {
		for (const [rowIndex, row] of rows.entries()) {
			for (const [columnIndex, letter] of [...row].entries()) {
				const value = key[letter];
				if (value !== undefined) {
					this.set(isMirrored ? x + row.length - 1 - columnIndex : x + columnIndex, y + rowIndex, value);
				}
			}
		}
	}

	// Shades the pixels of the base color: the light comes from the top left, so the right and bottom edges get the shadow and the left edge gets the light.
	shade(ramp, {light = true, depth = 2} = {}) {
		const updates = [];
		for (let y = -top; y < height - top; y++) {
			for (let x = 0; x < width; x++) {
				if (this.get(x, y) !== ramp.base) {
					continue;
				}

				const isEmpty = (deltaX, deltaY) => this.get(x + deltaX, y + deltaY) === 0;
				if (isEmpty(1, 0) || isEmpty(0, 1)) {
					updates.push([x, y, ramp.deep]);
				} else if (isEmpty(depth, 0) || isEmpty(1, 1) || isEmpty(0, depth)) {
					updates.push([x, y, ramp.shade]);
				} else if (light && (isEmpty(-1, 0) || isEmpty(0, -1)) && !isEmpty(-1, 1)) {
					updates.push([x, y, ramp.light]);
				}
			}
		}

		for (const [x, y, value] of updates) {
			this.set(x, y, value);
		}
	}

	// A highlight band, like the shine on hair or satin, along an ellipse.
	shine(ramp, centerX, centerY, radiusX, radiusY, {from = 0.72, to = 0.86, left = -Infinity, right = Infinity} = {}) {
		this.fill(ellipse(centerX, centerY, radiusX, radiusY), (x, y, current) => {
			const distance = Math.sqrt((((x + 0.5 - centerX) / radiusX) ** 2) + (((y + 0.5 - centerY) / radiusY) ** 2));
			if (current !== 0 && current !== this.outlineColor && distance >= from && distance <= to && x >= left && x <= right) {
				return current === ramp.shade || current === ramp.deep ? ramp.base : ramp.light;
			}

			return undefined;
		});
	}

	// A black line around the layer, on the empty pixels next to it.
	outline() {
		const updates = [];
		for (let y = -top; y < height - top; y++) {
			for (let x = 0; x < width; x++) {
				if (this.get(x, y) === 0 && (this.get(x - 1, y) || this.get(x + 1, y) || this.get(x, y - 1) || this.get(x, y + 1))) {
					updates.push([x, y]);
				}
			}
		}

		for (const [x, y] of updates) {
			this.set(x, y, this.outlineColor);
		}
	}
}

// The bodies

// The joints of the two bases, as `[x, y, radius]`. Both stand in the 3/4 pose and look a little to the left.
const bodies = {
	girl: {
		torso: [[55, 50], [72, 50], [75.5, 51.5], [77, 54.5], [75, 58], [72.5, 64], [70.5, 71], [72, 76], [74, 81], [74, 87], [70, 92], [64, 94], [58, 92], [54.5, 87], [55, 81], [57, 76], [58, 71], [56.5, 64], [54, 58], [51.5, 54.5], [52.5, 51.5]],
		neck: rectangle(60, 40, 7, 12),
		jaw: [[52, 30], [76, 30], [75, 36], [71, 41], [65.5, 44.5], [61, 45], [56, 42], [52.5, 37]],
		legs: [
			[[59.5, 86, 4.8], [56.5, 122, 2.8], [55.8, 131, 3.3], [54.5, 158, 1.8]],
			[[68.5, 86, 4.8], [67, 122, 2.8], [66.6, 131, 3.3], [66, 159, 1.8]],
		],
		feet: [ellipse(52.3, 161.6, 4.3, 2.1), ellipse(63.8, 162.6, 4.3, 2.1)],
		backArm: [[54, 54, 3.3], [49.5, 76, 2.5], [47.5, 95, 1.9]],
		backHand: ellipse(46.6, 98.8, 2.3, 3.4),
		frontArm: [[75, 54, 3.3], [83, 70.5, 2.5], [76.5, 81.5, 2]],
		frontHand: ellipse(74.2, 82.8, 3, 2.3),
		chest: 60,
		isGirl: true,
	},
	guy: {
		torso: [[54, 50], [74, 50], [78.5, 51.5], [80.5, 55], [78, 59], [76, 66], [74.5, 73], [74.5, 80], [74.5, 87], [70, 92], [64, 94], [58, 92], [53.5, 87], [53.5, 80], [53.5, 73], [52, 66], [50, 59], [47.5, 55], [49.5, 51.5]],
		neck: rectangle(59, 40, 9, 12),
		jaw: [[52, 30], [76.5, 30], [76, 37], [72, 42.5], [66, 46], [60, 46], [55.5, 42.5], [52, 37]],
		legs: [
			[[59, 86, 5], [57.5, 122, 3.1], [57.2, 131, 3.4], [56.5, 158, 2.1]],
			[[69, 86, 5], [68.5, 122, 3.1], [68.2, 131, 3.4], [67.5, 159, 2.1]],
		],
		feet: [ellipse(53.8, 161.6, 4.8, 2.3), ellipse(65, 162.6, 4.8, 2.3)],
		backArm: [[50.5, 54, 3.7], [47, 77, 2.8], [46, 96, 2.1]],
		backHand: ellipse(45.6, 99.8, 2.6, 3.7),
		frontArm: [[78, 54, 3.7], [81.5, 77, 2.8], [81, 96, 2.1]],
		frontHand: ellipse(81.4, 99.8, 2.6, 3.7),
		chest: 60,
		isGirl: false,
	},
};

const headShape = body => union(ellipse(64, 30, 12.5, 13.2), polygon(body.jaw), ellipse(76.2, 33, 2, 3));

// The shape of the torso and the legs together, for a piece of clothes that covers both.
const legShape = (body, extra = 0) => union(...body.legs.map(leg => chain(leg, extra)));

// The part of an arm from the shoulder, as long as `length`: 1 is to the elbow, and 2 is to the wrist.
const sleeveShape = (arm, length, extra = 1) => {
	const points = [arm[0]];
	const segment = Math.min(Math.floor(length), 1);
	points.push(...arm.slice(1, segment + 1));
	const fraction = length - segment;
	if (fraction > 0 && segment < 2) {
		const from = arm[segment];
		const to = arm[segment + 1];
		points.push(from.map((value, index) => value + ((to[index] - value) * fraction)));
	}

	return chain(points, extra);
};

// The pieces of the doll

const skins = {
	porcelain: {color: '#fde4d2', says: 'Like me in the winter. And the summer.'},
	peach: {color: '#f8c8a2', says: 'Peach is the normal one.'},
	tan: {color: '#e2a477', says: 'She has been to Syden (the south)!'},
	golden: {color: '#c98a52', says: 'Golden like a waffle.'},
	brown: {color: '#99603a', says: 'Pretty!!! Like Mel B.'},
	deep: {color: '#5e3922', says: 'She is the prettiest one, I think.'},
};

// The eyes of the near side, with the outer corner to the right. The far eye is the same, turned around, and a bit narrower. K is black, W is white, H is the highlight, and the rest are the shades of the eye color.
const eyeStyles = {
	sparkly: {
		color: '#3b7fd9',
		rows: [
			'.KKKKK',
			'KWHDDK',
			'KWDIDW',
			'.WIIL.',
		],
		says: 'Sparkly eyes are the best eyes.',
	},
	lashes: {
		color: '#2f9e55',
		rows: [
			'.....KK',
			'.KKKKK.',
			'KWHDDKK',
			'KWDIDW.',
			'.WIIL..',
			'....K..',
		],
		top: -1,
		says: 'Mamma has mascara like that. I am not allowed.',
	},
	anime: {
		color: '#9b4fd8',
		rows: [
			'.KKKKKK',
			'KKDDDDK',
			'KWHDDHK',
			'KWDIDIW',
			'KWIILIW',
			'.WLLLL.',
		],
		top: -1,
		says: 'Like Sailor Moon!!!',
	},
	sleepy: {
		color: '#7a4a2b',
		rows: [
			'......',
			'.KKKKK',
			'KWDDDK',
			'.WIIL.',
		],
		says: 'She stayed up to watch Robinson-ekspedisjonen.',
	},
	wink: {
		color: '#3b7fd9',
		rows: [
			'.KKKKK',
			'KWHDDK',
			'KWDIDW',
			'.WIIL.',
		],
		isWink: true,
		says: '😉 She is flirting. Ewww.',
	},
	cool: {
		color: '#4d6b8a',
		rows: [
			'KKKKK',
			'.WHDK',
			'.WDDW',
		],
		top: 1,
		says: 'Cool eyes, for a guy dollz. They do not have lashes.',
	},
};

const closedEye = [
	'......',
	'......',
	'KKKKKK',
	'.K..K.',
];

const winkEye = [
	'......',
	'..KK..',
	'.K..K.',
	'K....K',
];

// The mouths, with the middle at the third letter. P is the lip, p the dark lip, W the teeth, H the gloss, and T the tongue.
const mouths = {
	smile: {rows: ['p...p', '.ppp.'], says: 'Smile!!!'},
	gloss: {rows: ['.PPP.', 'PHPPp', '.ppp.'], color: '#ff4f9a', says: 'Lip Smacker with strawberry. Yum.'},
	grin: {rows: ['ppppp', 'pWWWp', '.ppp.'], says: 'She is happy because it is Friday and Fredagsbarnetimen.'},
	tongue: {rows: ['ppppp', '.pTp.', '..T..'], says: ':P :P :P'},
	surprised: {rows: ['.pp.', 'pKKp', '.pp.'], says: 'OH! She saw Sindre without a shirt. Gross.'},
};

const cheeks = {
	none: {},
	blush: {color: '#ff6f91', says: 'Blush, because she is shy.'},
	freckles: {color: '#a0522d', says: 'Freckles, like Pippi Langstrømpe.'},
	gems: {color: '#33ccff', says: 'Face gems!!! Like Gwen Stefani. Mamma will not buy them.'},
};

const draw = {};

// The skin of the doll: the arms, the body with the legs, and the head with the face.
draw.backArm = ({body, skin, layer}) => {
	const arm = layer();
	const ramp = arm.ramp(skin, skinShadow);
	arm.fill(union(chain(body.backArm), body.backHand), ramp.base);
	arm.shade(ramp);
	arm.outline();
};

draw.frontArm = ({body, skin, layer}) => {
	const arm = layer();
	const ramp = arm.ramp(skin, skinShadow);
	arm.fill(union(chain(body.frontArm), body.frontHand), ramp.base);
	arm.shade(ramp);
	if (body.isGirl) {
		// The fingers on the hip.
		arm.line(73, 82, 76, 82, ramp.deep, true);
	}

	arm.outline();
};

draw.body = ({body, skin, layer}) => {
	const figure = layer();
	const ramp = figure.ramp(skin, skinShadow);
	figure.fill(union(polygon(body.torso), body.neck, legShape(body), ...body.feet), ramp.base);
	separateLegs(figure, body, 94, 112);
	figure.shade(ramp);

	// The shadow of the chin on the neck.
	figure.fill(rectangle(60, 43, 8, 3), (x, y, current) => current === 0 ? undefined : ramp.shade);

	// The belly button and the chest.
	figure.set(64, 77, ramp.shade);
	figure.set(64, 78, ramp.deep);
	if (body.isGirl) {
		figure.line(58, body.chest + 2, 61, body.chest + 3, ramp.shade, true);
		figure.line(66, body.chest + 3, 69, body.chest + 2, ramp.shade, true);
	} else {
		figure.line(58, body.chest + 3, 62, body.chest + 3, ramp.shade, true);
		figure.line(66, body.chest + 3, 70, body.chest + 3, ramp.shade, true);
	}

	// The knees.
	for (const leg of body.legs) {
		figure.set(Math.round(leg[1][0]) + 1, Math.round(leg[1][1]), ramp.shade);
	}

	figure.outline();
};

// The swimsuit of the base, like on every dollz base, which the clothes cover.
draw.swimsuit = ({body, layer}) => {
	const swimsuit = layer();
	const ramp = swimsuit.ramp(body.isGirl ? '#ff9ccf' : '#5aa0ff');
	const torso = grow(polygon(body.torso), 0.6);
	swimsuit.fill(union(body.isGirl ? clip(torso, {top: 57, bottom: 63}) : undefined, clip(torso, {top: 82})), ramp.base);
	separateLegs(swimsuit, body, 94, 100);
	swimsuit.shade(ramp);
	swimsuit.fill(rectangle(40, 50, 50, 50), (x, y, current) => current === ramp.base && (x + y) % 4 === 0 && x % 2 === 0 ? swimsuit.color('#ffffff') : undefined);
	swimsuit.outline();
};

draw.head = ({body, skin, doll, layer, colorOf, isBlinking}) => {
	const head = layer();
	const ramp = head.ramp(skin, skinShadow);
	head.fill(headShape(body), ramp.base);
	head.shade(ramp);

	// The ear, the nose, and the eyebrows.
	head.set(76, 32, ramp.deep);
	head.set(76, 33, ramp.shade);
	head.set(62, 36, ramp.shade);
	head.set(61, 37, ramp.deep);
	head.set(60, 37, ramp.shade);
	const brow = head.color(mix(colorOf('hair'), '#000000', 0.45));
	head.line(55, 27, 58, 26, brow);
	head.line(65, 26, 68, 26, brow);
	head.set(69, 27, brow);

	// The eyes.
	const eyes = eyeStyles[doll.eyes] ?? eyeStyles.sparkly;
	const eye = head.ramp(colorOf('eyes'));
	const key = {
		K: head.outlineColor,
		W: head.color('#ffffff'),
		H: head.color('#ffffff'),
		D: eye.deep,
		I: eye.base,
		L: eye.light,
	};
	const rowsTop = 30 + (eyes.top ?? 0);
	const nearRows = isBlinking ? closedEye : eyes.isWink ? winkEye : eyes.rows;
	const farRows = isBlinking ? closedEye : eyes.rows;
	head.pattern(64, rowsTop, nearRows, key);
	head.pattern(54, rowsTop, farRows.map(row => row.slice(0, -1)), key, true);

	// The mouth.
	const mouth = mouths[doll.mouth] ?? mouths.smile;
	const lips = head.ramp(colorOf('mouth'), skinShadow);
	head.pattern(60 - (mouth.rows[0].length === 4 ? 0 : 1), 40, mouth.rows, {
		P: lips.base,
		p: lips.deep,
		H: head.color('#ffffff'),
		W: head.color('#ffffff'),
		T: head.color('#ff7a9a'),
		K: head.color('#5a1020'),
	});

	// The cheeks.
	if (doll.cheeks === 'blush') {
		const blush = head.color(mix(skin, colorOf('cheeks'), 0.55));
		head.pattern(54, 36, ['B.B.', '.B.B'], {B: blush});
		head.pattern(66, 36, ['B.B.B', '.B.B.'], {B: blush});
	} else if (doll.cheeks === 'freckles') {
		const freckle = head.color(mix(skin, colorOf('cheeks'), 0.6));
		head.pattern(54, 35, ['F..F', '.F..', 'F..F'], {F: freckle});
		head.pattern(65, 35, ['.F.F', 'F..F.', '.F.F.'], {F: freckle});
	} else if (doll.cheeks === 'gems') {
		const gem = head.ramp(colorOf('cheeks'));
		const white = head.color('#ffffff');
		head.pattern(71, 31, ['.G', 'GH', '.G', '..', 'g.', 'Hg'], {G: gem.base, g: gem.shade, H: white});
		head.pattern(62, 22, ['.H.', 'HGH', '.G.'], {G: head.color('#ff3399'), H: gem.light});
	}

	head.outline();
};

// The hair, which has a part behind the body and a part in front of the face.

const hairStyles = {
	long: {
		color: '#f0cc5c',
		says: 'Long hair like me! I can sit on mine. Almost.',
		back(layer, ramp) {
			layer.fill(union(ellipse(64, 29, 15, 14), polygon([[50, 26], [78, 26], [80.5, 40], [81, 62], [78.5, 76], [72, 80], [56, 80], [49.5, 76], [47, 62], [47.5, 40]])), ramp.base);
			for (let x = 49; x < 80; x += 3) {
				layer.erase(polygon([[x, 81], [x + 1.5, 76], [x + 3, 81]]));
			}
		},
		backDetails(layer, ramp) {
			for (const x of [51, 54, 75, 78]) {
				layer.line(x, 46, x, 76, ramp.shade, true);
			}
		},
		front(layer, ramp) {
			layer.fill(union(
				clip(ellipse(64, 29, 14, 13.8), {bottom: 26}),
				polygon([[51, 23], [77, 23], [77.5, 29.5], [75, 27], [72, 29.5], [69, 26.5], [66, 29], [62.5, 26], [58.5, 28.5], [55.5, 26], [52, 29.5]]),
				chain([[74, 24, 3.2], [77, 40, 3.4], [77.5, 56, 2.8], [76.5, 64, 1.5]]),
				chain([[53, 24, 3], [50.5, 40, 2.8], [49.5, 56, 2.4], [50, 62, 1.2]]),
			), ramp.base);
		},
		frontDetails(layer, ramp) {
			layer.shine(ramp, 64, 29, 14, 13.8, {right: 72});
			layer.line(77, 34, 78, 58, ramp.shade, true);
			layer.line(51, 34, 50, 56, ramp.light, true);
			layer.line(66, 16, 64, 22, ramp.shade, true);
		},
	},
	pigtails: {
		color: '#f0cc5c',
		says: 'Pigtails!!! Mamma does mine every morning, and it pulls.',
		back(layer, ramp) {
			layer.fill(ellipse(64, 29, 14.5, 14), ramp.base);
		},
		front(layer, ramp) {
			layer.fill(union(
				clip(ellipse(64, 29, 14, 13.8), {bottom: 26}),
				polygon([[51, 23], [77, 23], [77, 28], [74, 26], [71, 28.5], [67.5, 26], [64.5, 28.5], [61, 26], [57.5, 28.5], [54, 26], [51, 29]]),
				chain([[51, 22, 3], [44, 28, 4.5], [41, 38, 4.2], [40, 50, 3.4], [41.5, 60, 1.6]]),
				chain([[77, 22, 3], [84, 28, 4.5], [87, 38, 4.2], [88, 50, 3.4], [86.5, 60, 1.6]]),
			), ramp.base);
		},
		frontDetails(layer, ramp) {
			layer.shine(ramp, 64, 29, 14, 13.8, {right: 73});
			layer.line(64, 16, 64, 22, ramp.deep, true);
			for (const [x1, x2] of [[40, 42], [86, 88]]) {
				layer.line(x1, 42, x1 + 1, 56, ramp.shade, true);
				layer.line(x2, 36, x2, 50, ramp.light, true);
			}

			// The hair bobbles.
			const bobble = layer.ramp('#ff3399');
			layer.pattern(46, 24, ['.BB', 'BLB', 'BBb'], {B: bobble.base, L: bobble.light, b: bobble.deep});
			layer.pattern(80, 24, ['BB.', 'BLB', 'bBB'], {B: bobble.base, L: bobble.light, b: bobble.deep});
		},
	},
	buns: {
		color: '#ff5fc8',
		says: 'Space buns! Pink hair, like on MTV.',
		back(layer, ramp) {
			layer.fill(ellipse(64, 29, 14.5, 14), ramp.base);
		},
		extra(layer, ramp) {
			layer.fill(union(ellipse(51.5, 16, 6.2, 6), ellipse(76.5, 16, 6.2, 6)), ramp.base);
			layer.shade(ramp);
			for (const centerX of [51.5, 76.5]) {
				layer.line(centerX - 3, 15, centerX, 13, ramp.shade, true);
				layer.line(centerX, 13, centerX + 3, 16, ramp.shade, true);
				layer.line(centerX - 1, 18, centerX + 2, 18, ramp.shade, true);
				layer.set(Math.round(centerX) - 3, 13, ramp.light);
			}
		},
		front(layer, ramp) {
			layer.fill(union(
				subtract(clip(ellipse(64, 29, 14, 13.8), {bottom: 28}), ellipse(63.5, 33.5, 10.5, 9.5)),
				chain([[53, 23, 1.4], [52.5, 33, 1], [53.5, 38, 0.7]]),
				chain([[75, 23, 1.4], [76.5, 33, 1], [75.5, 38, 0.7]]),
			), ramp.base);
		},
		frontDetails(layer, ramp) {
			layer.shine(ramp, 64, 29, 14, 13.8, {right: 72});
			layer.line(64, 16, 64, 24, ramp.deep, true);
		},
	},
	bob: {
		color: '#6b3a1e',
		says: 'A bob, like Mamma. Very practical, she says.',
		back(layer, ramp) {
			layer.fill(union(ellipse(64, 29, 15, 14), polygon([[50, 26], [78, 26], [80, 38], [79.5, 44], [75, 47], [53, 47], [48.5, 44], [48, 38]])), ramp.base);
		},
		front(layer, ramp) {
			layer.fill(union(
				clip(ellipse(64, 29, 14.2, 13.8), {bottom: 26}),
				polygon([[51, 22], [77, 22], [77, 27.5], [51, 27.5]]),
				polygon([[72.5, 24], [78.5, 26], [80, 38], [79.5, 45], [75.5, 47.5], [73.5, 44], [75.5, 40]]),
				polygon([[55.5, 24], [50, 26], [48.5, 38], [49, 45], [53, 47.5], [54.5, 44], [53, 40]]),
			), ramp.base);
		},
		frontDetails(layer, ramp) {
			layer.shine(ramp, 64, 29, 14.2, 13.8, {right: 72});
			for (let x = 53; x < 76; x += 4) {
				layer.set(x, 27, ramp.shade);
			}

			layer.line(78, 30, 78, 44, ramp.shade, true);
		},
	},
	curly: {
		color: '#3b2516',
		says: 'Scary Spice hair!!! It is soooo big.',
		back(layer, ramp) {
			const curls = [];
			for (let angle = 0; angle < Math.PI * 2; angle += Math.PI / 7) {
				curls.push(ellipse(64 + (Math.cos(angle) * 19), 28 + (Math.sin(angle) * 17), 5.2, 5));
			}

			layer.fill(union(ellipse(64, 28, 19, 17), ...curls), ramp.base);
		},
		backDetails(layer, ramp) {
			layer.fill(ellipse(64, 28, 25, 23), (x, y, current) => {
				if (current !== ramp.base) {
					return undefined;
				}

				const value = hash(x, y, 3);
				return value < 0.14 ? ramp.shade : value > 0.9 ? ramp.light : undefined;
			});
		},
		front(layer, ramp) {
			const curls = [];
			for (let x = 51; x <= 77; x += 4) {
				curls.push(ellipse(x, 24, 2.6, 2.4));
			}

			layer.fill(union(clip(ellipse(64, 28, 15, 13), {bottom: 24}), ...curls), ramp.base);
		},
		frontDetails(layer, ramp) {
			layer.fill(ellipse(64, 24, 16, 12), (x, y, current) => current === ramp.base && hash(x, y, 4) < 0.18 ? ramp.shade : undefined);
			layer.shine(ramp, 62, 26, 13, 10, {from: 0.7, to: 0.8, right: 66});
		},
	},
	ponytail: {
		color: '#4a2a16',
		says: 'Sporty Spice! She can do a backflip.',
		back(layer, ramp) {
			layer.fill(union(ellipse(64, 29, 14, 13.6), chain([[72, 17, 3.5], [81, 18, 4], [86, 26, 3.6], [86.5, 40, 3], [83.5, 54, 1.4]])), ramp.base);
		},
		backDetails(layer, ramp) {
			layer.line(85, 26, 85, 46, ramp.light, true);
			layer.line(88, 30, 87, 42, ramp.deep, true);
		},
		front(layer, ramp) {
			layer.fill(subtract(clip(ellipse(64, 29, 14, 13.8), {bottom: 28}), ellipse(63.5, 33.5, 10.5, 9.5)), ramp.base);
		},
		frontDetails(layer, ramp) {
			layer.shine(ramp, 64, 29, 14, 13.8, {right: 72});
			for (const x of [56, 61, 67]) {
				layer.line(x, 22, x + 5, 17, ramp.shade, true);
			}

			// The scrunchie.
			const scrunchie = layer.ramp('#ff3366');
			layer.pattern(74, 15, ['.SS.', 'SLSs', 'SSsS', '.sS.'], {S: scrunchie.base, L: scrunchie.light, s: scrunchie.deep});
		},
	},
	spiky: {
		color: '#7a4a24',
		says: 'Spiky hair with frosted tips, like a guy in a boy band. Sindre wants it.',
		back(layer, ramp) {
			layer.fill(clip(ellipse(64, 29, 13.8, 13.4), {bottom: 34}), ramp.base);
		},
		front(layer, ramp) {
			layer.fill(union(
				clip(ellipse(64, 29, 14, 13.4), {bottom: 23}),
				polygon([[50, 25], [45, 16], [55, 19]]),
				polygon([[53, 20], [50, 9], [59.5, 16]]),
				polygon([[58, 17], [59, 6], [65, 15.5]]),
				polygon([[63.5, 16], [69.5, 6], [70.5, 17]]),
				polygon([[69, 17], [78.5, 9.5], [75.5, 21]]),
				polygon([[74, 20], [83.5, 16.5], [78, 26]]),
				polygon([[55, 22], [57, 28.5], [61, 22]]),
				polygon([[61, 22], [65, 28], [67, 21.5]]),
				polygon([[67, 22], [72, 27.5], [73, 22]]),
				rectangle(74, 24, 2, 7),
			), ramp.base);
		},
		frontDetails(layer, ramp, colorOf) {
			// The frosted tips, bleached at the ends with a kit from the pharmacy.
			const tips = layer.ramp(mix(colorOf('hair'), '#fff6c0', 0.85));
			const points = [[45, 16], [50, 9], [59, 6], [69.5, 6], [78.5, 9.5], [83.5, 16.5], [57, 28.5], [65, 28], [72, 27.5]];
			layer.fill(rectangle(40, 0, 50, 32), (x, y, current) => {
				if (current === 0 || current === layer.outlineColor) {
					return undefined;
				}

				const isTip = points.some(([tipX, tipY]) => Math.hypot(x + 0.5 - tipX, y + 0.5 - tipY) < 4.6);
				if (!isTip) {
					return undefined;
				}

				return current === ramp.light ? tips.light : current === ramp.shade ? tips.shade : current === ramp.deep ? tips.deep : tips.base;
			});
		},
	},
	curtains: {
		color: '#c9a25f',
		says: 'Curtains, like Nick Carter. Lillesøster LOVES Nick.',
		back(layer, ramp) {
			layer.fill(union(ellipse(64, 29, 14.5, 14), polygon([[50, 26], [78, 26], [79.5, 36], [78, 42], [50, 42], [48.5, 36]])), ramp.base);
		},
		front(layer, ramp) {
			layer.fill(union(
				clip(ellipse(64, 29, 14, 13.8), {bottom: 22}),
				polygon([[64.5, 16], [58, 17.5], [52, 21], [50.3, 29], [51, 37], [53, 31.5], [56, 26], [61.5, 21]]),
				polygon([[64.5, 16], [70.5, 17.5], [76.5, 21.5], [78.5, 30], [78, 38], [75.5, 32.5], [72, 26], [67.5, 21]]),
			), ramp.base);
		},
		frontDetails(layer, ramp) {
			layer.shine(ramp, 64, 29, 14, 13.8, {right: 74});
			layer.line(64, 16, 64, 20, ramp.deep, true);
			layer.line(54, 24, 52, 33, ramp.light, true);
			layer.line(74, 24, 77, 33, ramp.shade, true);
		},
	},
	none: {
		color: '#6b3a1e',
		says: 'No hair?! Like Pappa soon.',
	},
};

draw.hairBack = ({doll, colorOf, layer}) => {
	const style = hairStyles[doll.hair];
	if (!style?.back) {
		return;
	}

	const hair = layer({glitter: true});
	const ramp = hair.ramp(colorOf('hair'));
	style.back(hair, ramp);
	hair.shade(ramp);
	style.backDetails?.(hair, ramp);
	hair.outline();
};

draw.hairFront = ({doll, colorOf, layer}) => {
	const style = hairStyles[doll.hair];
	if (!style?.front) {
		return;
	}

	if (style.extra) {
		const extra = layer({glitter: true});
		style.extra(extra, extra.ramp(colorOf('hair')));
		extra.outline();
	}

	const hair = layer({glitter: true});
	const ramp = hair.ramp(colorOf('hair'));
	style.front(hair, ramp);
	hair.shade(ramp);
	style.frontDetails?.(hair, ramp, colorOf);
	hair.outline();
};

// A tiny font of 3 by 5 pixels, for the letters on the clothes.
const tinyFont = {
	B: ['11.', '1.1', '11.', '1.1', '11.'],
	S: ['.11', '1..', '.1.', '..1', '11.'],
	G: ['.11', '1..', '1.1', '1.1', '.11'],
	I: ['111', '.1.', '.1.', '.1.', '111'],
	R: ['11.', '1.1', '11.', '1.1', '1.1'],
	L: ['1..', '1..', '1..', '1..', '111'],
	P: ['11.', '1.1', '11.', '1..', '1..'],
	W: ['1.1', '1.1', '1.1', '111', '1.1'],
	9: ['111', '1.1', '111', '..1', '111'],
	'!': ['1', '1', '1', '.', '1'],
};

const writeTiny = (layer, text, x, y, value) => {
	let cursor = x;
	for (const letter of text) {
		const rows = tinyFont[letter];
		if (!rows) {
			cursor += 2;
			continue;
		}

		layer.pattern(cursor, y, rows, {1: value});
		cursor += rows[0].length + 1;
	}
};

// The width of a text in the tiny font.
const tinyWidth = text => {
	let total = 0;
	for (const letter of text) {
		total += (tinyFont[letter]?.[0].length ?? 1) + 1;
	}

	return total - 1;
};

// The clothes. Each piece fills its shape and shades it, and the sleeves are drawn on the arms with the same color.

const torsoOf = body => polygon(body.torso);

// Fills pixels in a layer with a color by a rule, only where the layer already has a pixel that is not the outline.
const paintOver = (layer, shape, rule) => {
	layer.fill(shape, (x, y, current) => current === 0 || current === layer.outlineColor ? undefined : rule(x, y, current));
};

const tops = {
	none: {},
	tank: {
		color: '#ff5fb8',
		says: 'A tank top in hot pink. Hot pink is the best pink.',
		body(layer, ramp, {body}) {
			const left = body.torso[0][0] + 2.5;
			const right = body.torso[1][0] - 3.5;
			layer.fill(union(
				subtract(clip(grow(torsoOf(body), 1), {top: 52, bottom: 83}), ellipse(63.5, 52, 5.5, 3)),
				rectangle(left, 48, 2, 6),
				rectangle(right, 48, 2, 6),
			), ramp.base);
			layer.shade(ramp);
			layer.pattern(62, 55, ['B.B', '.B.'], {B: ramp.deep});
		},
	},
	babytee: {
		color: '#8ec5ff',
		says: 'A baby tee with a star. Baby Spice has one!',
		sleeve: 0.4,
		body(layer, ramp, {body}) {
			layer.fill(subtract(clip(grow(torsoOf(body), 1), {top: 48, bottom: 75}), ellipse(63.5, 48, 4.5, 2.5)), ramp.base);
			layer.shade(ramp);
			const star = layer.ramp('#ffe23a');
			layer.pattern(62, 56, ['..Y..', '.YYY.', 'YYLYY', '.YYY.', '.Y.Y.'], {Y: star.base, L: star.light});
			layer.line(56, 73, 72, 73, ramp.light, true);
		},
	},
	tube: {
		color: '#c13cff',
		says: 'A tube top. Mamma says it will fall down. It will not.',
		body(layer, ramp, {body}) {
			layer.fill(clip(grow(torsoOf(body), 1), {top: 56, bottom: 71}), ramp.base);
			layer.shade(ramp);
			layer.line(56, 58, 70, 58, ramp.light, true);
			layer.line(57, 63, 70, 63, ramp.shade, true);
			layer.line(57, 67, 70, 67, ramp.shade, true);
		},
	},
	girlpower: {
		color: '#d7b2ff',
		says: 'GIRL POWER!!! Zig-a-zig-ah!',
		sleeve: 0.45,
		body(layer, ramp, {body}) {
			layer.fill(subtract(clip(grow(torsoOf(body), 1), {top: 48, bottom: 81}), ellipse(63.5, 48, 4.5, 2.5)), ramp.base);
			layer.shade(ramp);
			const text = layer.color('#ff0080');
			writeTiny(layer, 'GIRL', 64 - Math.floor(tinyWidth('GIRL') / 2), 56, text);
			writeTiny(layer, 'PWR!', 64 - Math.floor(tinyWidth('PWR!') / 2), 63, text);
		},
	},
	lusekofte: {
		color: '#1d2b6b',
		says: 'A lusekofte, the sweater with the lice pattern. It is a warm pattern, not real lice!!!',
		sleeve: 2,
		sleeveExtra: 1.4,
		body(layer, ramp, {body}) {
			layer.fill(subtract(clip(grow(torsoOf(body), 1.4), {top: 47, bottom: 87}), ellipse(63.5, 47, 3.5, 1.5)), ramp.base);
			const white = layer.ramp('#f4f0e2');
			knit(layer, ramp, white, rectangle(40, 46, 50, 42));
			paintOver(layer, rectangle(40, 83, 50, 4), (x, y) => (y === 83 || y === 86) ? white.base : (x + y) % 3 === 0 ? ramp.base : white.base);
			layer.shade(ramp, {light: false});
			layer.shade(white);
			// The pewter clasps at the neck.
			const pewter = layer.color('#b8bcc8');
			layer.set(63, 48, pewter);
			layer.set(63, 50, pewter);
		},
		sleeveDetails(layer, ramp, arm) {
			const white = layer.ramp('#f4f0e2');
			knit(layer, ramp, white, rectangle(30, 46, 70, 60));
			const [wristX, wristY] = arm[2];
			paintOver(layer, ellipse(wristX, wristY, 4.5, 3.2), () => white.base);
			layer.shade(white);
		},
	},
	jersey: {
		color: '#d4213a',
		says: 'A Backstreet Boys jersey! Number 99, because it is 1999.',
		sleeve: 1,
		sleeveExtra: 2.4,
		body(layer, ramp, {body}) {
			layer.fill(subtract(clip(grow(torsoOf(body), 2.2), {top: 47, bottom: 92}), polygon([[59, 45], [68.5, 45], [63.8, 54]])), ramp.base);
			layer.shade(ramp);
			const white = layer.color('#ffffff');
			layer.line(59, 47, 63, 54, white, true);
			layer.line(68, 47, 64, 54, white, true);
			paintOver(layer, rectangle(40, 87, 50, 2), () => white);
			writeTiny(layer, 'BSB', 64 - Math.floor(tinyWidth('BSB') / 2), 58, white);
			writeTiny(layer, '99', 64 - Math.floor(tinyWidth('99') / 2), 66, white);
		},
		sleeveDetails(layer, ramp, arm) {
			const white = layer.color('#ffffff');
			const [elbowX, elbowY] = arm[1];
			paintOver(layer, ellipse(elbowX, elbowY - 2.5, 6, 1.6), () => white);
		},
	},
};

// The lice pattern of a lusekofte: a band with crosses at the shoulders, and white dots under it.
const knit = (layer, ramp, white, shape) => {
	paintOver(layer, shape, (x, y, current) => {
		if (current !== ramp.base) {
			return undefined;
		}

		if (y === 50 || y === 57) {
			return white.base;
		}

		if (y > 50 && y < 57) {
			return (x + y) % 4 === 0 || (x - y + 400) % 4 === 0 ? white.base : undefined;
		}

		if (y > 59) {
			return (x % 4 === 0 && y % 4 === 0) || (x % 4 === 2 && y % 4 === 2) ? white.base : undefined;
		}

		return undefined;
	});
};

// The legs of trousers, from the hips to the ankles, wider at the bottom by `flare`.
const trouserLegs = (body, extra, flare = extra, bottomOffset = 3) => union(...body.legs.map(leg => chain([
	leg[0],
	leg[1],
	leg[2],
	[leg[3][0], leg[3][1] + bottomOffset, leg[3][2]],
].map((point, index) => [point[0], point[1], point[2] + (index === 3 ? flare : extra)]))));

// The middle of a leg at a row, from its joints.
const legCenter = (leg, y) => {
	for (let index = 1; index < leg.length; index++) {
		const [x1, y1] = leg[index - 1];
		const [x2, y2] = leg[index];
		if (y <= y2 || index === leg.length - 1) {
			return x1 + ((x2 - x1) * ((y - y1) / (y2 - y1)));
		}
	}

	return leg[0][0];
};

// Leaves a gap of one pixel between the two legs, which the outline fills, so the legs of trousers do not melt into one.
const separateLegs = (layer, body, fromY, toY) => {
	for (let y = fromY; y < toY; y++) {
		layer.set(Math.floor((legCenter(body.legs[0], y) + legCenter(body.legs[1], y)) / 2), y, 0);
	}
};

const bottoms = {
	none: {},
	flares: {
		color: '#5b8fd6',
		says: 'Flared jeans, so big that they get wet in every puddle.',
		body(layer, ramp, {body}) {
			layer.fill(union(clip(grow(torsoOf(body), 1), {top: 79}), trouserLegs(body, 1.3, 4.2, 4)), ramp.base);
			separateLegs(layer, body, 94, 170);
			layer.shade(ramp);
			// The seams and the stitches of the waist.
			const [, near] = body.legs;
			layer.line(Math.round(near[0][0]) + 4, 88, Math.round(near[3][0]) + 5, 160, ramp.light, true);
			layer.line(54, 81, 74, 81, ramp.light, true);
			layer.line(64, 82, 64, 88, ramp.shade, true);
		},
	},
	plaid: {
		color: '#7d8296',
		says: 'Oh baby, baby! The plaid skirt from the video of Britney.',
		body(layer, ramp, {body}) {
			const red = layer.color('#b8283a');
			layer.fill(union(clip(grow(torsoOf(body), 1), {top: 78, bottom: 85}), polygon([[54.5, 79], [74.5, 79], [80, 102], [49, 102]])), ramp.base);
			paintOver(layer, rectangle(40, 78, 50, 26), (x, y) => {
				if (y === 85 || y === 94 || x % 6 === 0) {
					return ramp.deep;
				}

				if (y === 90 || x % 6 === 3) {
					return red;
				}

				return undefined;
			});
			layer.shade(ramp);
			for (let x = 51; x < 80; x += 3) {
				layer.line(x, 92, x, 101, ramp.shade, true);
			}
		},
	},
	shorts: {
		color: '#6a9ae0',
		says: 'Jean shorts, for the one warm day in Bergen.',
		body(layer, ramp, {body}) {
			layer.fill(union(clip(grow(torsoOf(body), 1), {top: 79}), clip(union(...body.legs.map(leg => chain(leg, 1.4))), {bottom: 103})), ramp.base);
			separateLegs(layer, body, 95, 103);
			layer.shade(ramp);
			paintOver(layer, rectangle(40, 99, 50, 4), (x, y) => y === 99 ? ramp.deep : ramp.light);
			layer.line(54, 81, 74, 81, ramp.light, true);
		},
	},
	cargo: {
		color: '#b4a06a',
		says: 'Cargo pants have 8 pockets. For trading cards.',
		body(layer, ramp, {body}) {
			layer.fill(union(clip(grow(torsoOf(body), 1.2), {top: 79}), trouserLegs(body, 2.2, 2.8, 4)), ramp.base);
			separateLegs(layer, body, 94, 170);
			layer.shade(ramp);
			for (const leg of body.legs) {
				const x = Math.round(leg[1][0]) + (leg === body.legs[0] ? -4 : 2);
				layer.pattern(x, 104, ['DDDD', 'D..D', 'DLLD', 'DDDD', '....', 'D..D'], {D: ramp.deep, L: ramp.light});
				layer.line(Math.round(leg[3][0]) - 3, 156, Math.round(leg[3][0]) + 3, 158, ramp.shade, true);
			}

			layer.line(54, 81, 74, 81, ramp.deep, true);
		},
	},
	trackpants: {
		color: '#25296a',
		says: 'Track pants with stripes and snaps, like Sporty Spice.',
		body(layer, ramp, {body}) {
			layer.fill(union(clip(grow(torsoOf(body), 1.2), {top: 79}), trouserLegs(body, 1.8, 2.6, 4)), ramp.base);
			separateLegs(layer, body, 94, 170);
			layer.shade(ramp, {light: false});
			const white = layer.color('#ffffff');
			for (const [index, leg] of body.legs.entries()) {
				const side = index === 0 ? -1 : 1;
				for (const offset of [2, 4]) {
					const radiusTop = leg[0][2] + 1.8 - offset;
					const radiusBottom = leg[3][2] + 2.6 - offset;
					layer.line(Math.round(leg[0][0] + (side * radiusTop)), 88, Math.round(leg[3][0] + (side * radiusBottom)), Math.round(leg[3][1]) + 3, white, true);
				}
			}

			layer.line(54, 81, 74, 81, white, true);
		},
	},
	overalls: {
		color: '#4f7fc4',
		says: 'Overalls with one strap down, because that is cool. I do not know why.',
		isOverTop: true,
		body(layer, ramp, {body}) {
			const torso = grow(torsoOf(body), 1.2);
			const strapX = body.torso[1][0] - 3;
			layer.fill(union(
				clip(torso, {top: 79}),
				clip(torso, {top: 63, left: 57.5, right: 71}),
				capsule([strapX - 1, 63, 1], [strapX, 50, 1]),
				trouserLegs(body, 1.8, 2.4, 4),
			), ramp.base);
			separateLegs(layer, body, 94, 170);
			layer.shade(ramp);
			// The bib pocket, and the strap that hangs down with its buckle.
			layer.pattern(61, 66, ['DDDDD', 'D...D', 'DDDDD'], {D: ramp.deep});
			const metal = layer.ramp('#d8dce4');
			layer.pattern(Math.round(strapX) - 1, 62, ['MM', 'Mm'], {M: metal.base, m: metal.deep});
			layer.fill(capsule([57.5, 64, 1], [body.torso[18][0] - 1, 86, 1]), ramp.base);
			layer.shade(ramp);
			layer.pattern(Math.round(body.torso[18][0]) - 2, 85, ['MM', 'mM'], {M: metal.base, m: metal.deep});
		},
	},
};

const dresses = {
	none: {},
	unionjack: {
		color: '#1a3a8f',
		says: 'The Union Jack dress of Ginger Spice, from the Brit Awards! Mamma says it is too short.',
		body(layer, ramp, {body}) {
			const shape = subtract(union(clip(grow(torsoOf(body), 1), {top: 50, bottom: 81}), polygon([[55.5, 78], [73.5, 78], [77, 100], [51, 100]])), ellipse(63.5, 50, 5, 2.5));
			layer.fill(shape, ramp.base);
			const white = layer.ramp('#ffffff', '#3a2a5a');
			const red = layer.ramp('#d0213a');
			const [left, right, topEdge, bottomEdge] = [51, 77, 50, 100];
			const length = Math.hypot(right - left, bottomEdge - topEdge);
			paintOver(layer, shape, (x, y) => {
				const centerX = x + 0.5;
				const centerY = y + 0.5;
				const fromDown = Math.abs(((bottomEdge - topEdge) * (centerX - left)) - ((right - left) * (centerY - topEdge))) / length;
				const fromUp = Math.abs(((bottomEdge - topEdge) * (centerX - left)) + ((right - left) * (centerY - bottomEdge))) / length;
				if (Math.abs(centerX - 64) < 1.1 || Math.abs(centerY - 76) < 1.1) {
					return red.base;
				}

				if (Math.abs(centerX - 64) < 2.6 || Math.abs(centerY - 76) < 2.6) {
					return white.base;
				}

				if (fromDown < 0.7 || fromUp < 0.7) {
					return red.base;
				}

				if (fromDown < 2 || fromUp < 2) {
					return white.base;
				}

				return undefined;
			});
			layer.shade(ramp);
			layer.shade(white, {light: false});
			layer.shade(red, {light: false});
		},
	},
	bunad: {
		color: '#c0202a',
		says: 'A bunad, for the 17th of May! Hipp hipp hurra! I have one just like it from Mormor.',
		sleeve: 2,
		sleeveExtra: 1.6,
		sleeveColor: '#fbfaf2',
		layers(layer, {body, colorOf}) {
			// The black skirt, long, to the middle of the leg.
			const skirt = layer({glitter: true});
			const black = skirt.ramp('#26222c', '#000000');
			skirt.fill(union(clip(grow(torsoOf(body), 1), {top: 71}), polygon([[55.5, 71], [73, 71], [79, 140], [49.5, 140]])), black.base);
			skirt.shade(black);
			const band = skirt.ramp('#3a7a3a');
			skirt.fill(rectangle(48, 135, 32, 2), (x, y, current) => current ? band.base : undefined);
			skirt.outline();

			// The white apron with Hardanger embroidery.
			const apron = layer({glitter: true});
			const white = apron.ramp('#fbfaf2', '#4a3a5a');
			apron.fill(polygon([[58, 73], [70, 73], [72.5, 133], [55.5, 133]]), white.base);
			paintOver(apron, rectangle(50, 73, 30, 62), (x, y) => {
				if (y >= 125 && y <= 128) {
					return (x + y) % 2 === 0 ? white.shade : undefined;
				}

				return (x % 4 === 1 && y % 4 === 1) ? white.shade : undefined;
			});
			apron.shade(white);
			apron.outline();

			// The red bodice with the beaded front, over a white shirt with a high collar.
			const top = layer({glitter: true});
			const shirt = top.ramp('#fbfaf2', '#4a3a5a');
			const red = top.ramp(colorOf('dress'));
			top.fill(union(clip(grow(torsoOf(body), 1), {top: 46, bottom: 74}), rectangle(60, 43, 7, 5)), shirt.base);
			top.fill(clip(grow(torsoOf(body), 1.2), {top: 56, bottom: 74}), red.base);
			top.shade(shirt);
			top.shade(red);
			const beads = {
				K: top.color('#18141c'),
				Y: top.color('#ffd23a'),
				G: top.color('#3aa04a'),
				W: top.color('#ffffff'),
				B: top.color('#3a6ad8'),
			};
			top.pattern(59, 57, [
				'KKKKKKKKKK',
				'KYKWKKWKYK',
				'KKGKBBKGKK',
				'KWKYKKYKWK',
				'KKGKBBKGKK',
				'KYKWKKWKYK',
				'KKKKKKKKKK',
			], beads);
			top.line(56, 72, 72, 72, red.deep, true);
			// The sølje, the silver brooch at the collar.
			const silver = top.ramp('#d6dae2');
			top.pattern(62, 48, ['.SS.', 'SLLS', '.SS.', 's.s.', '.s.s'], {S: silver.base, L: silver.light, s: silver.deep});
			top.outline();
		},
		sleeveDetails(layer, ramp, arm) {
			const [wristX, wristY] = arm[2];
			paintOver(layer, ellipse(wristX, wristY, 4, 2.6), () => ramp.shade);
		},
	},
	slip: {
		color: '#c7a2ff',
		says: 'A slip dress in satin, for the school disco. No boys allowed.',
		body(layer, ramp, {body}) {
			const left = body.torso[0][0] + 3;
			const right = body.torso[1][0] - 3;
			layer.fill(union(
				subtract(clip(grow(torsoOf(body), 1), {top: 55, bottom: 81}), polygon([[59.5, 54], [67.5, 54], [63.5, 58.5]])),
				polygon([[55.5, 78], [73.5, 78], [78, 119], [50, 119]]),
				rectangle(left, 49, 1, 7),
				rectangle(right, 49, 1, 7),
			), ramp.base);
			layer.shade(ramp);
			layer.line(58, 82, 55, 117, ramp.light, true);
			layer.line(67, 84, 70, 117, ramp.shade, true);
			paintOver(layer, rectangle(48, 117, 32, 2), (x, y) => (x + y) % 2 === 0 ? layer.color('#ffffff') : undefined);
		},
	},
};

const coats = {
	none: {},
	raincoat: {
		color: '#ffd21f',
		says: 'A raincoat! It rains 248 days a year in Bergen, so you need it on the other days too.',
		sleeve: 2,
		sleeveExtra: 2,
		body(layer, ramp, {body}) {
			layer.fill(union(
				clip(grow(torsoOf(body), 2), {top: 46, bottom: 95}),
				polygon([[53, 88], [75.5, 88], [79, 115], [49.5, 115]]),
				ellipse(64, 47, 10.5, 4),
			), ramp.base);
			layer.shade(ramp);
			layer.line(64, 51, 64, 114, ramp.deep, true);
			layer.line(56, 48, 72, 48, ramp.deep, true);
			const snap = layer.color('#202020');
			for (let y = 56; y < 112; y += 9) {
				layer.set(65, y, snap);
			}

			layer.line(53, 96, 58, 96, ramp.deep, true);
			layer.line(70, 96, 75, 96, ramp.deep, true);
			layer.line(51, 112, 77, 112, ramp.light, true);
		},
	},
	puffer: {
		color: '#c9d1de',
		says: 'A shiny puffer jacket. It goes swish swish when you walk.',
		sleeve: 2,
		sleeveExtra: 2.8,
		body(layer, ramp, {body}) {
			layer.fill(union(clip(grow(torsoOf(body), 3), {top: 46, bottom: 88}), ellipse(64, 46, 8, 3.5)), ramp.base);
			layer.shade(ramp);
			quilt(layer, ramp, rectangle(40, 44, 50, 46));
			layer.line(64, 49, 64, 87, ramp.deep, true);
		},
		sleeveDetails(layer, ramp) {
			quilt(layer, ramp, rectangle(30, 44, 70, 70));
		},
	},
};

// The seams of a puffer jacket, with shine on every puff.
const quilt = (layer, ramp, shape) => {
	paintOver(layer, shape, (x, y, current) => {
		if (y % 6 === 0) {
			return ramp.deep;
		}

		if (y % 6 === 2 && current !== ramp.deep && hash(x, y, 9) < 0.5) {
			return ramp.light;
		}

		return undefined;
	});
};

const shoes = {
	none: {says: 'Barefoot, like on the beach in the summer (the one day).'},
	platforms: {
		color: '#ff4fb0',
		says: 'Platforms like the Spice Girls! Mamma says you fall and break your neck.',
		layers(layer, {body, colorOf}) {
			const sole = layer({glitter: true});
			const white = sole.ramp('#f6f6f6', '#4a4a6a');
			for (const foot of body.feet) {
				sole.fill(rectangle(Math.round(foot.left) - 1, Math.round(foot.bottom) - 1, Math.round(foot.right - foot.left) + 2, 7), white.base);
			}

			sole.shade(white);
			sole.fill(rectangle(40, 0, 50, 200), (x, y, current) => current && y === Math.round(body.feet[0].bottom) + 2 ? white.deep : undefined);
			sole.outline();

			const upper = layer({glitter: true});
			const ramp = upper.ramp(colorOf('shoes'));
			for (const [index, foot] of body.feet.entries()) {
				const [ankleX, ankleY] = body.legs[index][3];
				upper.fill(union(grow(foot, 1), capsule([ankleX, ankleY - 3, 2.8], [ankleX - 1, ankleY + 1, 3])), ramp.base);
			}

			upper.shade(ramp);
			upper.outline();
		},
	},
	boots: {
		color: '#2f8f3c',
		says: 'Gummistøvler! For jumping in the puddles on the way to school.',
		isOverBottom: true,
		body(layer, ramp, {body}) {
			for (const [index, leg] of body.legs.entries()) {
				layer.fill(union(capsule([leg[2][0], leg[2][1] + 3, leg[2][2] + 1.8], [leg[3][0], leg[3][1], leg[3][2] + 2.2]), grow(body.feet[index], 1.4)), ramp.base);
			}

			layer.shade(ramp);
			for (const [index, leg] of body.legs.entries()) {
				layer.line(Math.round(leg[2][0]) - 2, Math.round(leg[2][1]) + 3, Math.round(leg[2][0]) + 3, Math.round(leg[2][1]) + 3, ramp.light, true);
				layer.line(Math.round(leg[2][0]) - 2, Math.round(leg[2][1]) + 7, Math.round(leg[3][0]) - 2, Math.round(leg[3][1]) - 2, ramp.light, true);
				const foot = body.feet[index];
				layer.line(Math.round(foot.left) - 1, Math.round(foot.bottom), Math.round(foot.right), Math.round(foot.bottom), ramp.deep, true);
			}
		},
	},
	skate: {
		color: '#3366cc',
		says: 'Skate shoes, as fat as a waffle iron.',
		layers(layer, {body, colorOf}) {
			const sole = layer({glitter: true});
			const white = sole.ramp('#f6f6f6', '#4a4a6a');
			for (const foot of body.feet) {
				sole.fill(rectangle(Math.round(foot.left) - 2, Math.round(foot.bottom) - 1, Math.round(foot.right - foot.left) + 4, 3), white.base);
			}

			sole.shade(white);
			sole.outline();

			const upper = layer({glitter: true});
			const ramp = upper.ramp(colorOf('shoes'));
			for (const [index, foot] of body.feet.entries()) {
				const [ankleX, ankleY] = body.legs[index][3];
				upper.fill(union(grow(foot, 2), capsule([ankleX, ankleY - 2, 3.2], [ankleX - 1, ankleY + 2, 3.4])), ramp.base);
			}

			upper.shade(ramp);
			const lace = upper.color('#ffffff');
			for (const [index, foot] of body.feet.entries()) {
				const x = Math.round(foot.left + ((foot.right - foot.left) / 2));
				upper.set(x, Math.round(foot.top) - 1, lace);
				upper.set(x + 1, Math.round(foot.top), lace);
				upper.set(Math.round(body.legs[index][3][0]) - 1, Math.round(body.legs[index][3][1]) - 3, lace);
			}

			upper.outline();
		},
	},
	maryjanes: {
		color: '#1c1a20',
		says: 'Mary Janes with white socks, for church and for the 17th of May.',
		layers(layer, {body, colorOf}) {
			const socks = layer();
			const white = socks.ramp('#fbfbfb', '#4a4a7a');
			for (const [index, leg] of body.legs.entries()) {
				socks.fill(union(chain([[leg[2][0], leg[2][1] - 3, leg[2][2]], leg[3]], 0.5), body.feet[index]), white.base);
			}

			socks.shade(white);
			for (const leg of body.legs) {
				socks.line(Math.round(leg[2][0]) - 3, Math.round(leg[2][1]) - 1, Math.round(leg[2][0]) + 3, Math.round(leg[2][1]) - 1, white.shade, true);
			}

			socks.outline();

			const shoe = layer({glitter: true});
			const ramp = shoe.ramp(colorOf('shoes'), '#000000');
			for (const foot of body.feet) {
				shoe.fill(clip(grow(foot, 1), {top: foot.top + 1}), ramp.base);
			}

			shoe.shade(ramp);
			const light = shoe.color(mix(colorOf('shoes'), '#ffffff', 0.7));
			for (const [index, foot] of body.feet.entries()) {
				shoe.line(Math.round(body.legs[index][3][0]) - 2, Math.round(foot.top), Math.round(body.legs[index][3][0]) + 2, Math.round(foot.top), ramp.base);
				shoe.set(Math.round(foot.left) + 1, Math.round(foot.top) + 1, light);
			}

			shoe.outline();
		},
	},
};

// The extras, which a doll can have many of. Each one is drawn at its place in the order: behind her, on her head, or in front.
const extras = {
	sunglasses: {
		name: 'sunglasses',
		place: 'head',
		color: '#5a2a9a',
		says: 'Tiny sunglasses! You cannot see anything, but they are cool.',
		draw({layer, colorOf}) {
			const glasses = layer({glitter: true});
			const ramp = glasses.ramp(colorOf('extra:sunglasses'));
			glasses.fill(union(ellipse(57, 32.5, 3.2, 2.2), ellipse(67, 32.5, 3.5, 2.2)), ramp.base);
			glasses.shade(ramp);
			const white = glasses.color('#ffffff');
			glasses.set(55, 32, white);
			glasses.set(65, 32, white);
			glasses.outline();
			glasses.line(60, 31, 63, 31, glasses.outlineColor);
			glasses.line(71, 31, 75, 32, glasses.outlineColor);
		},
	},
	clips: {
		name: 'butterfly clips',
		place: 'head',
		color: '#ff66cc',
		says: 'Butterfly clips!!! I have 47 of them. Everybody in my class has them.',
		draw({layer, doll}) {
			const clips = layer({glitter: true, outline: false});
			const colors = doll.colors['extra:clips'] ? [doll.colors['extra:clips']] : ['#ff66cc', '#66ccff', '#ffe23a', '#7ee060', '#c08cff'];
			const spots = [[51, 21], [56, 18], [62, 16], [68, 17], [74, 20]];
			for (const [index, [x, y]] of spots.entries()) {
				const ramp = clips.ramp(colors[index % colors.length]);
				clips.pattern(x, y, ['KK.KK', 'BLKLB', '.BKB.', '..K..'], {B: ramp.shade, L: ramp.light, K: clips.outlineColor});
			}
		},
	},
	choker: {
		name: 'tattoo choker',
		place: 'neck',
		color: '#111111',
		says: 'A tattoo choker. It looks like a tattoo but it is plastic. It pinches.',
		draw({layer, body, colorOf}) {
			const choker = layer({outline: false});
			const value = choker.color(colorOf('extra:choker'));
			const {left, right} = body.neck;
			for (let x = Math.round(left); x < Math.round(right); x++) {
				choker.set(x, 45, value);
				choker.set(x, 47, value);
				if (x % 2 === 0) {
					choker.set(x, 46, value);
				}
			}
		},
	},
	wings: {
		name: 'angel wings',
		place: 'behind',
		color: '#f4f8ff',
		says: 'Angel wings, because she is an angel. Unlike Sindre.',
		draw({layer, colorOf}) {
			const wings = layer({glitter: true});
			const ramp = wings.ramp(colorOf('extra:wings'), '#3050a0');
			// The tips of the feathers of the left wing. The right wing has the same, the other way around.
			const tips = [[26, 38, 3.5], [22, 50, 3.6], [24, 62, 3.4], [29, 74, 3.2], [36, 84, 2.8]];
			const sides = [[56, tipX => tipX], [72, tipX => 128 - tipX]];
			const feathers = [];
			for (const [anchorX, place] of sides) {
				for (const [tipX, tipY, radius] of tips) {
					feathers.push(capsule([anchorX, 56, 4.5], [place(tipX), tipY, radius]));
				}
			}

			wings.fill(union(...feathers), ramp.base);
			wings.shade(ramp);
			for (const [anchorX, place] of sides) {
				for (const [tipX, tipY] of tips.slice(0, -1)) {
					const x = place(tipX);
					wings.line(Math.round(anchorX + ((x - anchorX) * 0.45)), Math.round(56 + ((tipY - 56) * 0.45)), Math.round(x + ((anchorX - x) * 0.1)), Math.round(tipY + 2), ramp.shade, true);
				}
			}

			wings.outline();
		},
	},
	halo: {
		name: 'glitter halo',
		place: 'head',
		color: '#ffd84a',
		says: 'A glitter halo! It always glitters, also without the filter.',
		draw({layer, colorOf}) {
			const halo = layer({glitter: 'always'});
			const ramp = halo.ramp(colorOf('extra:halo'), '#804000');
			halo.fill(subtract(ellipse(64, 5, 10, 3), ellipse(64, 5, 7.2, 1.4)), ramp.base);
			halo.shade(ramp);
			halo.outline();
		},
	},
	furby: {
		name: 'Furby',
		place: 'front',
		color: '#b07ad8',
		says: 'A Furby!!! It says “me love you” and wakes everybody at night.',
		draw({layer, colorOf}) {
			const feet = layer();
			const orange = feet.ramp('#ff9a2a');
			feet.fill(union(ellipse(29.5, 165, 3.2, 1.6), ellipse(38.5, 165, 3.2, 1.6)), orange.base);
			feet.shade(orange);
			feet.outline();

			const furby = layer({glitter: true});
			const fur = furby.ramp(colorOf('extra:furby'));
			furby.fill(union(
				ellipse(34, 156, 8, 8.5),
				polygon([[28.5, 150], [23.5, 136], [32, 148]]),
				polygon([[36, 148], [44, 135], [39.5, 150.5]]),
			), fur.base);
			furby.fill(ellipse(34, 159.5, 5, 4.5), fur.light);
			paintOver(furby, rectangle(20, 130, 30, 40), (x, y, current) => current === fur.base && hash(x, y, 11) < 0.12 ? fur.shade : undefined);
			furby.shade(fur);
			const eyes = {
				K: furby.outlineColor,
				W: furby.color('#ffffff'),
				B: furby.color('#3a7ad8'),
			};
			furby.pattern(29, 150, ['.KKK.', 'KWWWK', 'KWBKK', 'KWBKK', '.KKK.'], eyes);
			furby.pattern(35, 150, ['.KKK.', 'KWWWK', 'KWBKK', 'KWBKK', '.KKK.'], eyes);
			const beak = furby.ramp('#ffa030');
			furby.pattern(32, 155, ['BBBB', '.Bb.'], {B: beak.base, b: beak.deep});
			furby.outline();
		},
	},
	tamagotchi: {
		name: 'Tamagotchi',
		place: 'front',
		color: '#ff6fae',
		says: 'A Tamagotchi! Mine died at school because Fru Hansen took it away.',
		draw({layer, body, colorOf}) {
			const hand = body.backHand;
			const centerX = (hand.left + hand.right) / 2;
			const egg = layer({glitter: true});
			const ramp = egg.ramp(colorOf('extra:tamagotchi'));
			egg.fill(ellipse(centerX, hand.bottom + 8, 3.8, 4.6), ramp.base);
			egg.shade(ramp);
			const screen = egg.color('#b8e0a0');
			const pixel = egg.color('#203020');
			const button = egg.color('#ffe23a');
			const x = Math.round(centerX) - 2;
			const y = Math.round(hand.bottom) + 5;
			egg.pattern(x, y, ['SSSS', 'SPSS', 'SSSS', '....', 'Y.Y.'], {S: screen, P: pixel, Y: button});
			egg.outline();
			const chainColor = egg.color('#a8a8b8');
			for (let row = Math.round(hand.bottom) - 1; row < Math.round(hand.bottom) + 3; row++) {
				egg.set(Math.round(centerX), row, chainColor);
			}
		},
	},
	discman: {
		name: 'Discman',
		place: 'head',
		color: '#d0d4dc',
		says: 'A Discman with the Backstreet Boys inside. It skips if you walk.',
		draw({layer, body, colorOf}) {
			const phones = layer();
			const band = phones.ramp('#40404a');
			phones.fill(clip(subtract(ellipse(64, 28, 15.5, 15), ellipse(64, 28, 13.8, 13.4)), {bottom: 25}), band.base);
			phones.shade(band);
			const foam = phones.ramp('#ff8a2a');
			phones.fill(union(ellipse(49.5, 30.5, 2.4, 3.4), ellipse(78.5, 30.5, 2.4, 3.4)), foam.base);
			phones.shade(foam);
			phones.outline();

			// The player, clipped to the trousers, with the cable up to the headphones.
			const player = layer({glitter: true});
			const silver = player.ramp(colorOf('extra:discman'));
			const centerX = body.isGirl ? 80 : 75;
			player.fill(ellipse(centerX, 93, 5.5, 5.5), silver.base);
			player.shade(silver);
			player.fill(subtract(ellipse(centerX, 93, 3.2, 3.2), ellipse(centerX, 93, 1.6, 1.6)), silver.shade);
			player.set(centerX - 1, 92, silver.light);
			player.outline();
			player.line(79, 34, 80, 44, player.outlineColor);
			player.line(80, 44, centerX + 2, 87, player.color('#40404a'));
		},
	},
	skateboard: {
		name: 'skateboard',
		place: 'behind',
		color: '#33cc66',
		says: 'A skateboard, for the hill outside our house. It ends in the fjord.',
		draw({layer, colorOf}) {
			const deck = layer({glitter: true});
			const ramp = deck.ramp(colorOf('extra:skateboard'));
			deck.fill(capsule([98, 104, 4.4], [95, 166, 4.4]), ramp.base);
			deck.shade(ramp);
			const flame = deck.ramp('#ff6a2a');
			deck.pattern(94, 128, ['.F..', 'FFF.', 'FYF.', '.FFF', '.FYF', '..F.'], {F: flame.base, Y: deck.color('#ffe23a')});
			deck.outline();

			const trucks = layer();
			const metal = trucks.ramp('#c8ccd4');
			const wheel = trucks.ramp('#fffbe8', '#806040');
			for (const [x, y] of [[97.5, 114], [95.5, 156]]) {
				trucks.fill(rectangle(x - 5, y, 10, 2), metal.base);
				trucks.fill(union(ellipse(x - 6, y + 1, 1.8, 2.4), ellipse(x + 6, y + 1, 1.8, 2.4)), wheel.base);
			}

			trucks.shade(metal);
			trucks.shade(wheel);
			trucks.outline();
		},
	},
	flag: {
		name: 'flag',
		place: 'behind',
		color: '#ba0c2f',
		says: 'A flag for the 17th of May! She waves it at the children’s parade.',
		draw({layer, body, colorOf}) {
			// The stick goes up and out from the hand, so the arm does not hide it.
			const stick = layer();
			const wood = stick.ramp('#9a6a3a');
			const hand = body.backHand;
			const handX = (hand.left + hand.right) / 2;
			const topX = Math.round(handX - 9);
			stick.fill(capsule([handX, hand.bottom + 4, 0.8], [topX, 60, 0.8]), wood.base);
			stick.outline();

			// The Norwegian flag, with the cross nearer to the stick, and a little wave.
			const flag = layer({glitter: true});
			const red = flag.ramp(colorOf('extra:flag'));
			const white = flag.ramp('#ffffff', '#3a2a5a');
			const blue = flag.ramp('#00205b');
			for (let column = 0; column < 16; column++) {
				const fromStick = 15 - column;
				const wave = Math.round(Math.sin(column / 2.5) * 0.9);
				for (let row = 0; row < 12; row++) {
					const isBlue = fromStick === 5 || fromStick === 6 || row === 5 || row === 6;
					const isWhite = fromStick === 4 || fromStick === 7 || row === 4 || row === 7;
					flag.set(topX - 16 + column, 61 + row + wave, isBlue ? blue.base : isWhite ? white.base : red.base);
				}
			}

			flag.shade(red, {light: false});
			flag.outline();
		},
	},
	rocky: {
		name: 'Rocky',
		place: 'front',
		color: '#8d8a86',
		says: 'Rocky the pet rock! He is the best pet. He never runs away.',
		draw({layer, colorOf}) {
			const rock = layer();
			const ramp = rock.ramp(colorOf('extra:rocky'), '#202030');
			rock.fill(union(ellipse(84, 164, 7, 4.8), ellipse(81, 161.5, 3.8, 3.2), ellipse(87, 162, 3.6, 3)), ramp.base);
			paintOver(rock, rectangle(74, 154, 20, 16), (x, y, current) => current === ramp.base && hash(x, y, 21) < 0.15 ? ramp.shade : undefined);
			rock.shade(ramp);
			const eyes = {W: rock.color('#ffffff'), K: rock.outlineColor};
			rock.pattern(80, 160, ['WWW.WWW', 'WKW.WWK', 'WWW.WWW'], eyes);
			rock.line(82, 165, 85, 165, rock.outlineColor);
			rock.outline();
		},
	},
};

// The backgrounds, drawn straight on the pixels of the canvas.

const paintPixel = (pixels, x, y, hex) => {
	if (x < 0 || x >= width || y < 0 || y >= height) {
		return;
	}

	const [red, green, blue] = parse(hex);
	const offset = ((y * width) + x) * 4;
	pixels[offset] = red;
	pixels[offset + 1] = green;
	pixels[offset + 2] = blue;
	pixels[offset + 3] = 255;
};

// Bands of colors from the top, with a checkerboard where two bands meet, like the dithering of a GIF.
const paintBands = (pixels, colors, from, to) => {
	const bandHeight = (to - from) / colors.length;
	for (let y = from; y < to; y++) {
		const band = (y - from) / bandHeight;
		const index = Math.floor(band);
		const isDither = band - index > 0.75 && index < colors.length - 1;
		for (let x = 0; x < width; x++) {
			paintPixel(pixels, x, y, colors[isDither && (x + y) % 2 === 0 ? index + 1 : index]);
		}
	}
};

const paintShape = (pixels, shape, rule) => {
	for (let y = Math.max(Math.floor(shape.top), 0); y < Math.min(Math.ceil(shape.bottom), height); y++) {
		for (let x = Math.max(Math.floor(shape.left), 0); x < Math.min(Math.ceil(shape.right), width); x++) {
			if (shape.contains(x + 0.5, y + 0.5)) {
				const hex = typeof rule === 'function' ? rule(x, y) : rule;
				if (hex) {
					paintPixel(pixels, x, y, hex);
				}
			}
		}
	}
};

const paintCloud = (pixels, centerX, centerY, scale = 1) => {
	const cloud = union(ellipse(centerX, centerY, 9 * scale, 4 * scale), ellipse(centerX - (5 * scale), centerY - (2 * scale), 5 * scale, 4 * scale), ellipse(centerX + (3 * scale), centerY - (4 * scale), 5 * scale, 4 * scale));
	paintShape(pixels, grow(cloud, 1), '#6a7a9a');
	paintShape(pixels, cloud, (x, y) => y > centerY + (1 * scale) ? '#d8e4f4' : '#ffffff');
};

// A small heart of 7 by 6 pixels.
const heartRows = ['.HH.HH.', 'HLHHHHH', 'HHHHHHH', '.HHHHH.', '..HHH..', '...H...'];

const backgrounds = {
	none: {says: 'No background, so she is see-through, like a real GIF.'},
	rainbow: {
		color: '#7ec8ff',
		says: 'A rainbow! After the rain in Bergen there is always a rainbow. Almost always.',
		draw(pixels, color) {
			paintBands(pixels, [color, mix(color, '#ffffff', 0.2), mix(color, '#ffffff', 0.4), mix(color, '#ffffff', 0.6)], 0, 172);
			paintBands(pixels, ['#7ccf5a', '#5cb04a'], 172, height);
			const colors = ['#ff3b3b', '#ff9a2a', '#ffe23a', '#4ccf4c', '#3a8cff', '#9a5aff'];
			paintShape(pixels, ellipse(64, 160, 70, 82), (x, y) => {
				const distance = Math.hypot((x + 0.5 - 64) / 70, (y + 0.5 - 160) / 82);
				const band = Math.floor((1 - distance) * 36);
				return band >= 0 && band < colors.length ? colors[band] : undefined;
			});
			paintCloud(pixels, 12, 160, 1.3);
			paintCloud(pixels, 116, 162, 1.3);
			paintCloud(pixels, 98, 30);
		},
	},
	stars: {
		color: '#0b0b3d',
		says: 'Stars! You can see them from Fløyen when it does not rain. So never.',
		draw(pixels, color) {
			paintBands(pixels, [color, mix(color, '#3a1a6a', 0.3), mix(color, '#5a2a8a', 0.5), mix(color, '#7a3a9a', 0.7)], 0, height);
			for (let index = 0; index < 90; index++) {
				const x = Math.floor(hash(index, 1, 5) * width);
				const y = Math.floor(hash(index, 2, 5) * height);
				paintPixel(pixels, x, y, hash(index, 3, 5) < 0.3 ? '#ffe880' : '#ffffff');
			}

			for (const [x, y] of [[14, 20], [30, 120], [110, 80], [100, 150], [20, 60], [86, 190]]) {
				paintPixel(pixels, x, y, '#ffffff');
				for (const [deltaX, deltaY] of [[-1, 0], [1, 0], [0, -1], [0, 1], [-2, 0], [2, 0], [0, -2], [0, 2]]) {
					paintPixel(pixels, x + deltaX, y + deltaY, Math.abs(deltaX + deltaY) === 2 ? '#a0a0ff' : '#ffffc0');
				}
			}

			paintShape(pixels, subtract(ellipse(106, 24, 10), ellipse(111, 21, 9)), (x, y) => x < 101 ? '#fff0a0' : '#ffe060');
		},
	},
	bryggen: {
		color: '#a9c3d6',
		says: 'Bryggen in Bergen! The old wooden houses by the harbor. Our city is the most beautiful one.',
		draw(pixels, color) {
			paintBands(pixels, [mix(color, '#ffffff', 0.3), color, mix(color, '#607890', 0.3)], 0, 110);
			// Fløyen, the mountain behind.
			paintShape(pixels, polygon([[0, 78], [20, 62], [44, 54], [70, 60], [96, 50], [128, 58], [128, 120], [0, 120]]), (x, y) => hash(x, y, 7) < 0.1 ? '#2f5a38' : '#3d6b45');
			paintCloud(pixels, 30, 30);
			paintCloud(pixels, 100, 22, 0.8);
			const houses = ['#b8352a', '#e9c35a', '#f3eee0', '#d9822b', '#9e3d22', '#e8b04a', '#f3eee0', '#c0392b'];
			for (let index = 0; index < 8; index++) {
				const left = index * 16;
				const hex = houses[index];
				const apex = 84 + ((index % 3) * 3);
				const house = union(rectangle(left, 104, 16, 70), polygon([[left - 0.5, 105], [left + 8, apex], [left + 16.5, 105]]));
				paintShape(pixels, house, (x, y) => (x - left) % 3 === 2 ? mix(hex, '#000000', 0.18) : hex);
				for (let x = left; x < left + 16; x++) {
					const roofY = Math.round(apex + (Math.abs(x + 0.5 - (left + 8)) * ((105 - apex) / 8.5)));
					paintPixel(pixels, x, roofY, '#2a1a1a');
					paintPixel(pixels, x, roofY - 1, '#2a1a1a');
				}

				paintPixel(pixels, left + 8, apex + 4, '#2a1a1a');
				for (const row of [112, 126, 140]) {
					for (const column of [left + 3, left + 10]) {
						paintShape(pixels, rectangle(column, row, 4, 5), (x, y) => x === column || y === row || x === column + 3 || y === row + 4 ? '#ffffff' : '#30405a');
					}
				}

				paintShape(pixels, rectangle(left + 6, 160, 5, 14), '#3a2418');
				paintShape(pixels, rectangle(left, 174, 16, 1), '#2a1a1a');
			}

			paintShape(pixels, rectangle(0, 175, width, 25), (x, y) => y % 4 === 0 || (x + (Math.floor(y / 4) * 7)) % 19 === 0 ? '#5a4a3a' : '#8a7a66');
		},
	},
	tiles: {
		color: '#cfc6ff',
		says: 'A tiled background, like a real GeoCities page. It loads very slowly.',
		draw(pixels, color) {
			const dark = mix(color, '#4a3a8a', 0.25);
			const tile = [
				'................',
				'...W............',
				'..WWW...........',
				'.WWWWW..........',
				'..WWW...........',
				'..W.W...........',
				'................',
				'.......d........',
				'........d.......',
				'.........HH.HH..',
				'........HLHHHHH.',
				'........HHHHHHH.',
				'.........HHHHH..',
				'..........HHH...',
				'...........H....',
				'................',
			];
			const key = {W: '#ffffff', d: dark, H: '#ff66b2', L: '#ffd0e8'};
			for (let y = 0; y < height; y++) {
				for (let x = 0; x < width; x++) {
					paintPixel(pixels, x, y, key[tile[y % 16][x % 16]] ?? color);
				}
			}
		},
	},
	hearts: {
		color: '#ffd0ea',
		says: 'Hearts! Because she is in love. With Nick Carter.',
		draw(pixels, color) {
			paintBands(pixels, [color, mix(color, '#ffffff', 0.4)], 0, height);
			for (let row = 0; row < 13; row++) {
				for (let column = 0; column < 9; column++) {
					const x = (column * 16) + ((row % 2) * 8) - 4;
					const y = (row * 16) + 2;
					const hex = (row + column) % 2 === 0 ? '#ff4f9a' : '#ff8ac0';
					for (const [rowIndex, line] of heartRows.entries()) {
						for (const [columnIndex, letter] of [...line].entries()) {
							if (letter !== '.') {
								paintPixel(pixels, x + columnIndex, y + rowIndex, letter === 'L' ? '#ffffff' : hex);
							}
						}
					}
				}
			}
		},
	},
	rain: {
		color: '#7f8c9b',
		says: 'Rain in Bergen. Like every day. She does not mind, she has a raincoat. (Does she?)',
		draw(pixels, color) {
			paintBands(pixels, [mix(color, '#404a58', 0.4), color, mix(color, '#ffffff', 0.15), mix(color, '#ffffff', 0.25)], 0, 172);
			paintShape(pixels, rectangle(0, 172, width, 28), (x, y) => hash(x, y, 13) < 0.1 ? '#4a505a' : '#5c636e');
			paintShape(pixels, ellipse(64, 186, 46, 7), '#7a8aa0');
			paintShape(pixels, subtract(ellipse(40, 186, 8, 2.5), ellipse(40, 186, 6.5, 1.5)), '#b8c8dc');
			paintShape(pixels, subtract(ellipse(88, 184, 6, 2), ellipse(88, 184, 4.5, 1.2)), '#b8c8dc');
			for (const [x, y, scale] of [[18, 10, 1.4], [62, 4, 1.6], [108, 12, 1.4]]) {
				const cloud = union(ellipse(x, y, 14 * scale, 6 * scale), ellipse(x - 8, y + 2, 8, 6), ellipse(x + 8, y + 3, 9, 6));
				paintShape(pixels, cloud, (cloudX, cloudY) => cloudY > y + 3 ? '#4a5462' : '#5c6676');
			}

			for (let index = 0; index < 120; index++) {
				const x = Math.floor(hash(index, 1, 17) * width);
				const y = 14 + Math.floor(hash(index, 2, 17) * 160);
				for (let step = 0; step < 3; step++) {
					paintPixel(pixels, x - step, y + (step * 2), '#c8d8ec');
					paintPixel(pixels, x - step, y + (step * 2) + 1, '#c8d8ec');
				}
			}
		},
	},
};

const slots = {
	body: bodies,
	skin: skins,
	eyes: eyeStyles,
	mouth: mouths,
	cheeks,
	hair: hairStyles,
	top: tops,
	bottom: bottoms,
	dress: dresses,
	coat: coats,
	shoes,
	background: backgrounds,
};

// The color of a piece, as the visitor painted it, or as it comes.
const defaultColor = (doll, key) => {
	if (key.startsWith('extra:')) {
		return extras[key.slice('extra:'.length)]?.color;
	}

	if (key === 'mouth') {
		return mouths[doll.mouth].color ?? mix(doll.colors.skin ?? skins[doll.skin].color, '#d8304a', 0.55);
	}

	return slots[key]?.[doll[key]]?.color;
};

// Draws a piece of clothes on the body, and its sleeves on the arms.
const drawClothes = (piece, slot, stage, scene) => {
	if (!piece?.color && !piece?.layers) {
		return;
	}

	const color = scene.colorOf(slot);
	if (stage === 'body') {
		if (piece.layers) {
			piece.layers(scene.layer, scene);
			return;
		}

		const layer = scene.layer({glitter: true});
		piece.body(layer, layer.ramp(color), scene);
		layer.outline();
		return;
	}

	if (!piece.sleeve) {
		return;
	}

	const arm = stage === 'backArm' ? scene.body.backArm : scene.body.frontArm;
	const layer = scene.layer({glitter: true});
	const ramp = layer.ramp(piece.sleeveColor ?? color);
	layer.fill(sleeveShape(arm, piece.sleeve, piece.sleeveExtra ?? 1.2), ramp.base);
	layer.shade(ramp);
	piece.sleeveDetails?.(layer, ramp, arm);
	layer.outline();
};

// The pixels of the doll and her background, and which of them glitter: 1 with the filter, 2 always.
const renderDoll = (doll, {isBlinking = false} = {}) => {
	const body = bodies[doll.body] ?? bodies.girl;
	const layers = [];
	const scene = {
		doll,
		body,
		isBlinking,
		colorOf: key => doll.colors[key] ?? defaultColor(doll, key),
		layer(options) {
			const layer = new Layer(options);
			layers.push(layer);
			return layer;
		},
	};
	scene.skin = scene.colorOf('skin');

	const hasDress = doll.dress !== 'none';
	const clothes = [
		{piece: shoes[doll.shoes], slot: 'shoes', order: shoes[doll.shoes]?.isOverBottom ? 2.5 : 1},
		{piece: hasDress ? undefined : bottoms[doll.bottom], slot: 'bottom', order: bottoms[doll.bottom]?.isOverTop ? 3.5 : 2},
		{piece: hasDress ? undefined : tops[doll.top], slot: 'top', order: 3},
		{piece: dresses[doll.dress], slot: 'dress', order: 4},
		{piece: coats[doll.coat], slot: 'coat', order: 5},
	].toSorted((first, second) => first.order - second.order);
	// The extras are drawn in the order of the list, so the wings are always behind the flag.
	const extrasAt = place => Object.keys(extras).filter(id => doll.extras.includes(id) && extras[id].place === place);

	for (const id of extrasAt('behind')) {
		extras[id].draw(scene);
	}

	draw.hairBack(scene);
	draw.backArm(scene);
	for (const {piece, slot} of clothes) {
		drawClothes(piece, slot, 'backArm', scene);
	}

	draw.body(scene);
	draw.swimsuit(scene);
	for (const {piece, slot} of clothes) {
		drawClothes(piece, slot, 'body', scene);
	}

	for (const id of extrasAt('neck')) {
		extras[id].draw(scene);
	}

	draw.frontArm(scene);
	for (const {piece, slot} of clothes) {
		drawClothes(piece, slot, 'frontArm', scene);
	}

	draw.head(scene);
	draw.hairFront(scene);
	for (const id of [...extrasAt('head'), ...extrasAt('front')]) {
		extras[id].draw(scene);
	}

	const pixels = new Uint8ClampedArray(width * height * 4);
	const glitter = new Uint8Array(width * height);
	const background = backgrounds[doll.background];
	background?.draw?.(pixels, scene.colorOf('background'));

	for (const layer of layers) {
		const colors = layer.colors.map(hex => hex && parse(hex));
		const glitterValue = layer.glitter === 'always' ? 2 : layer.glitter ? 1 : 0;
		for (const [index, value] of layer.pixels.entries()) {
			if (value === 0) {
				continue;
			}

			const [red, green, blue] = colors[value];
			const offset = index * 4;
			pixels[offset] = red;
			pixels[offset + 1] = green;
			pixels[offset + 2] = blue;
			pixels[offset + 3] = 255;
			glitter[index] = value === layer.outlineColor ? 0 : glitterValue;
		}
	}

	return {pixels, glitter};
};

// Text, like the text tool of MS Paint with smoothing off: the browser writes it small, and every pixel is either on or off.

const textCanvas = document.createElement('canvas');
const textContext = textCanvas.getContext('2d', {willReadFrequently: true});
const textMasks = new Map();
const comicSans = '"Comic Sans MS", "Comic Sans", "Chalkboard SE", "Comic Neue", cursive';
const smallFont = `10px ${comicSans}`;
const boldFont = `bold 10px ${comicSans}`;
const titleFont = `bold 13px ${comicSans}`;
const tinyTextFont = 'bold 8px Verdana, Tahoma, Geneva, sans-serif';

const textMask = (text, font) => {
	const key = `${font}|${text}`;
	if (textMasks.has(key)) {
		return textMasks.get(key);
	}

	textContext.font = font;
	const maskWidth = Math.ceil(textContext.measureText(text).width) + 4;
	const maskHeight = 20;
	textCanvas.width = maskWidth;
	textCanvas.height = maskHeight;
	textContext.font = font;
	textContext.textBaseline = 'top';
	textContext.fillStyle = '#000000';
	textContext.fillText(text, 2, 3);
	const data = textContext.getImageData(0, 0, maskWidth, maskHeight).data;
	const bits = new Uint8Array(maskWidth * maskHeight);
	let left = maskWidth;
	let right = 0;
	let topRow = maskHeight;
	let bottomRow = 0;
	for (let index = 0; index < bits.length; index++) {
		if (data[(index * 4) + 3] >= 120) {
			bits[index] = 1;
			const x = index % maskWidth;
			const y = Math.floor(index / maskWidth);
			left = Math.min(left, x);
			right = Math.max(right, x);
			topRow = Math.min(topRow, y);
			bottomRow = Math.max(bottomRow, y);
		}
	}

	const mask = {
		width: right >= left ? right - left + 1 : 0,
		height: bottomRow >= topRow ? bottomRow - topRow + 1 : 0,
		has: (x, y) => x >= 0 && y >= 0 && bits[((y + topRow) * maskWidth) + x + left] === 1 && x + left <= right && y + topRow <= bottomRow,
	};
	textMasks.set(key, mask);
	return mask;
};

// Writes a text on pixels with a fill and a one pixel outline around it, at its left and top edge, or centered on `x`.
const writeText = (pixels, imageWidth, imageHeight, text, {x, y, font = smallFont, fill = '#ffffff', outline = '#ff0099', isCentered = false, maximumWidth = imageWidth - 4}) => {
	// A text that is too wide, like a long name, is written in a smaller font.
	let mask = textMask(text, font);
	if (mask.width > maximumWidth) {
		mask = textMask(text, tinyTextFont);
	}

	const left = isCentered ? Math.round(x - (mask.width / 2)) : x;
	const fillColor = parse(fill);
	const outlineColor = outline && parse(outline);
	const put = (pixelX, pixelY, color) => {
		if (pixelX < 0 || pixelY < 0 || pixelX >= imageWidth || pixelY >= imageHeight) {
			return;
		}

		const offset = ((pixelY * imageWidth) + pixelX) * 4;
		pixels[offset] = color[0];
		pixels[offset + 1] = color[1];
		pixels[offset + 2] = color[2];
		pixels[offset + 3] = 255;
	};

	if (outlineColor) {
		for (let row = -1; row <= mask.height; row++) {
			for (let column = -1; column <= mask.width; column++) {
				if (!mask.has(column, row) && (mask.has(column - 1, row) || mask.has(column + 1, row) || mask.has(column, row - 1) || mask.has(column, row + 1))) {
					put(left + column, y + row, outlineColor);
				}
			}
		}
	}

	for (let row = 0; row < mask.height; row++) {
		for (let column = 0; column < mask.width; column++) {
			if (mask.has(column, row)) {
				put(left + column, y + row, fillColor);
			}
		}
	}

	return mask.width;
};

// “DoN’t StEaL!!!”: every other letter big, like everybody wrote in 1999.
const alternatingCaps = text => {
	let isUpper = true;
	return [...text].map(character => {
		if (character.toLowerCase() === character.toUpperCase()) {
			return character;
		}

		const result = isUpper ? character.toUpperCase() : character.toLowerCase();
		isUpper = !isUpper;
		return result;
	}).join('');
};

// Glitter: some pixels of the clothes and the hair turn white for a frame, and a few get a little cross, like an animated GIF of 1999.
const addGlitter = (pixels, glitter, frame, isOn) => {
	for (let index = 0; index < glitter.length; index++) {
		const kind = glitter[index];
		if (kind === 0 || (kind === 1 && !isOn)) {
			continue;
		}

		const x = index % width;
		const y = Math.floor(index / width);
		const value = hash(x, y, frame + 101);
		if (value < 0.045) {
			const offset = index * 4;
			pixels[offset] = 255;
			pixels[offset + 1] = 255;
			pixels[offset + 2] = 255;
			if (value < 0.007) {
				for (const [deltaX, deltaY] of [[-1, 0], [1, 0], [0, -1], [0, 1]]) {
					const neighbor = ((y + deltaY) * width) + x + deltaX;
					if (x + deltaX >= 0 && x + deltaX < width && glitter[neighbor]) {
						pixels[neighbor * 4] = Math.min(255, pixels[neighbor * 4] + 120);
						pixels[(neighbor * 4) + 1] = Math.min(255, pixels[(neighbor * 4) + 1] + 120);
						pixels[(neighbor * 4) + 2] = Math.min(255, pixels[(neighbor * 4) + 2] + 60);
					}
				}
			}
		}
	}
};

const sisterName = 'Lillesøster';

// The stamps on the picture: her name at the top, and at the bottom the warning and who made her.
const addStamps = (pixels, doll) => {
	const name = doll.name.trim();
	if (name) {
		writeText(pixels, width, height, `~*~ ${alternatingCaps(name)} ~*~`, {x: width / 2, y: 1, font: boldFont, isCentered: true});
	}

	if (doll.stamp) {
		const maker = doll.maker.trim();
		writeText(pixels, width, height, alternatingCaps(maker ? `made by ${maker}` : `base by ${sisterName}`), {x: width / 2, y: 180, isCentered: true, fill: '#ffff66', outline: '#000000'});
		writeText(pixels, width, height, 'DoN’T StEaL!!!', {x: width / 2, y: 190, font: boldFont, isCentered: true, fill: '#ff0000', outline: '#ffffff'});
	}
};

// The dolls

const slotNames = {
	body: 'skin',
	skin: 'skin',
	eyes: 'eyes',
	mouth: 'lips',
	cheeks: 'cheeks',
	hair: 'hair',
	top: 'top',
	bottom: 'bottoms',
	dress: 'dress',
	coat: 'coat',
	shoes: 'shoes',
	background: 'background',
};

const defaultDoll = () => ({
	body: 'girl',
	skin: 'peach',
	eyes: 'sparkly',
	mouth: 'smile',
	cheeks: 'blush',
	hair: 'long',
	top: 'babytee',
	bottom: 'flares',
	dress: 'none',
	coat: 'none',
	shoes: 'platforms',
	extras: ['clips'],
	background: 'none',
	colors: {},
	name: '',
	maker: '',
	glitter: false,
	stamp: true,
});

const isColor = value => typeof value === 'string' && /^#[\da-f]{6}$/i.test(value);

// A doll from the browser or from the house, with only the pieces that exist, in case the storage has something old or broken.
const sanitize = value => {
	const doll = defaultDoll();
	if (!value || typeof value !== 'object') {
		return doll;
	}

	for (const [slot, pieces] of Object.entries(slots)) {
		if (typeof value[slot] === 'string' && Object.hasOwn(pieces, value[slot])) {
			doll[slot] = value[slot];
		}
	}

	if (Array.isArray(value.extras)) {
		doll.extras = [...new Set(value.extras.filter(id => typeof id === 'string' && Object.hasOwn(extras, id)))];
	}

	if (value.colors && typeof value.colors === 'object') {
		for (const [key, color] of Object.entries(value.colors)) {
			const isKnown = Object.hasOwn(slotNames, key) || (key.startsWith('extra:') && Object.hasOwn(extras, key.slice('extra:'.length)));
			if (isKnown && isColor(color)) {
				doll.colors[key] = color;
			}
		}
	}

	doll.name = typeof value.name === 'string' ? value.name.slice(0, 14) : '';
	doll.maker = typeof value.maker === 'string' ? value.maker.slice(0, 14) : '';
	doll.glitter = value.glitter === true;
	doll.stamp = value.stamp !== false;
	return doll;
};

// The dolls that Lillesøster made herself, which live in the Dollz House for good.
const sisterDolls = [
	{
		...defaultDoll(),
		name: 'Me!!! 17. mai',
		maker: sisterName,
		skin: 'porcelain',
		hair: 'pigtails',
		dress: 'bunad',
		shoes: 'maryjanes',
		extras: ['flag', 'clips'],
		background: 'bryggen',
		mouth: 'grin',
	},
	{
		...defaultDoll(),
		name: 'Sindre (ugly)',
		maker: sisterName,
		body: 'guy',
		eyes: 'cool',
		mouth: 'tongue',
		cheeks: 'freckles',
		hair: 'spiky',
		top: 'jersey',
		bottom: 'cargo',
		shoes: 'skate',
		extras: ['discman', 'skateboard'],
		background: 'tiles',
	},
	{
		...defaultDoll(),
		name: 'Mamma',
		maker: sisterName,
		eyes: 'lashes',
		mouth: 'gloss',
		cheeks: 'none',
		hair: 'bob',
		top: 'lusekofte',
		bottom: 'flares',
		coat: 'raincoat',
		shoes: 'boots',
		extras: [],
		background: 'rain',
	},
].map(doll => sanitize(doll));

const girlNames = ['Sparkle', 'Britney', 'Ingrid', 'Tiffany', 'Siri', 'Glitter Girl', 'Baby', 'Kristin', 'Angel', 'Stjerne', 'Ronja', 'Pernille', 'Jessica', 'Cherry', 'Sunshine', 'Mona', 'Thea'];
const guyNames = ['Nick', 'Trond', 'Justin', 'Håkon', 'Brian', 'Even', 'Leo', 'Kevin'];
const likes = ['waffles with brunost', 'the Spice Girls', 'the Backstreet Boys', 'Furbys', 'Glitter the unicorn', 'Kvikk Lunsj', 'jumping in puddles', 'Sabrina the Teenage Witch', 'trading cards', 'skipping rope', 'Titanic (she cried)', 'Rocky the pet rock'];
const fears = ['the Y2K bug', 'the dentist', 'Sindre’s room', 'the troll under the bridge', 'tran (cod liver oil)', 'the noise of the modem', 'spiders', 'the dark', 'Mormor’s fish soup', 'the Teletubbies sun'];

// A random doll, which is what an adoption gives too, with some pieces painted in the colors of the recolor tool.
const randomDoll = paintColors => {
	const isGuy = Math.random() < 0.25;
	const doll = defaultDoll();
	doll.body = isGuy ? 'guy' : 'girl';
	doll.skin = randomItem(Object.keys(skins));
	doll.eyes = isGuy ? randomItem(['cool', 'sparkly', 'wink', 'sleepy']) : randomItem(['sparkly', 'lashes', 'anime', 'sleepy', 'wink']);
	doll.mouth = randomItem(Object.keys(mouths));
	doll.cheeks = randomItem(Object.keys(cheeks));
	doll.hair = isGuy ? randomItem(['spiky', 'curtains', 'curly', 'bob']) : randomItem(['long', 'pigtails', 'buns', 'bob', 'curly', 'ponytail']);
	if (!isGuy && Math.random() < 0.3) {
		doll.dress = randomItem(['unionjack', 'bunad', 'slip']);
	} else {
		doll.top = randomItem(isGuy ? ['jersey', 'lusekofte', 'tank', 'girlpower'] : Object.keys(tops).filter(id => id !== 'none'));
		doll.bottom = randomItem(isGuy ? ['cargo', 'trackpants', 'flares', 'shorts'] : Object.keys(bottoms).filter(id => id !== 'none'));
	}

	doll.coat = Math.random() < 0.15 ? randomItem(['raincoat', 'puffer']) : 'none';
	doll.shoes = randomItem(Object.keys(shoes).filter(id => id !== 'none'));
	doll.extras = Object.keys(extras).filter(() => Math.random() < 0.18);
	doll.background = randomItem(Object.keys(backgrounds).filter(id => id !== 'none'));
	for (const slot of ['hair', 'top', 'bottom', 'eyes']) {
		if (Math.random() < 0.25) {
			doll.colors[slot] = randomItem(paintColors);
		}
	}

	doll.name = randomItem(isGuy ? guyNames : girlNames);
	doll.glitter = Math.random() < 0.4;
	return doll;
};

const recolorName = key => key.startsWith('extra:') ? extras[key.slice('extra:'.length)]?.name ?? 'extra' : slotNames[key] ?? key;

// A small name for a file, with only plain letters, as file names of 1999 were short.
const fileName = name => (name.normalize('NFD').replaceAll(/[^a-z\d]/gi, '').slice(0, 8) || 'dollz').toUpperCase();

const download = (sourceCanvas, scale, name) => {
	const output = document.createElement('canvas');
	output.width = sourceCanvas.width * scale;
	output.height = sourceCanvas.height * scale;
	const outputContext = output.getContext('2d');
	outputContext.imageSmoothingEnabled = false;
	outputContext.drawImage(sourceCanvas, 0, 0, output.width, output.height);
	output.toBlob(blob => {
		if (!blob) {
			return;
		}

		const link = document.createElement('a');
		link.href = URL.createObjectURL(blob);
		link.download = `${name}.PNG`;
		link.click();
		setTimeout(() => {
			URL.revokeObjectURL(link.href);
		}, 1000);
	});
};

// A guy dollz is a he.
const pronoun = someDoll => someDoll.body === 'guy' ? 'He' : 'She';

// Draws a doll with her stamps on a new canvas at the real size.
const dollCanvas = savedDoll => {
	const picture = document.createElement('canvas');
	picture.width = width;
	picture.height = height;
	const rendered = renderDoll(savedDoll);
	const pixels = new ImageData(width, height);
	pixels.data.set(rendered.pixels);
	addGlitter(pixels.data, rendered.glitter, 0, savedDoll.glitter);
	addStamps(pixels.data, savedDoll);
	picture.getContext('2d').putImageData(pixels, 0, 0);
	return picture;
};

const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

// The adoption certificate, with the doll at her real size, drawn on the canvas of `context`.
const drawCertificate = (context, adopted, number, adopter) => {
	const certificateWidth = context.canvas.width;
	const certificateHeight = context.canvas.height;
	const pixels = new ImageData(certificateWidth, certificateHeight);
	const data = pixels.data;
	const put = (x, y, hex) => {
		const [red, green, blue] = parse(hex);
		const offset = ((y * certificateWidth) + x) * 4;
		data[offset] = red;
		data[offset + 1] = green;
		data[offset + 2] = blue;
		data[offset + 3] = 255;
	};

	for (let y = 0; y < certificateHeight; y++) {
		for (let x = 0; x < certificateWidth; x++) {
			put(x, y, hash(x, y, 31) < 0.06 ? '#f6e8cc' : '#fff8e6');
		}
	}

	// A border of hearts, and a line inside it.
	for (let x = 2; x < certificateWidth - 8; x += 10) {
		for (const y of [2, certificateHeight - 8]) {
			for (const [rowIndex, line] of heartRows.entries()) {
				for (const [columnIndex, letter] of [...line].entries()) {
					if (letter !== '.') {
						put(x + columnIndex, y + rowIndex, letter === 'L' ? '#ffffff' : (x / 10) % 2 < 1 ? '#ff3399' : '#cc0066');
					}
				}
			}
		}
	}

	for (let y = 12; y < certificateHeight - 12; y += 10) {
		for (const x of [2, certificateWidth - 9]) {
			for (const [rowIndex, line] of heartRows.entries()) {
				for (const [columnIndex, letter] of [...line].entries()) {
					if (letter !== '.') {
						put(x + columnIndex, y + rowIndex, letter === 'L' ? '#ffffff' : (y / 10) % 2 < 1 ? '#cc0066' : '#ff3399');
					}
				}
			}
		}
	}

	for (let x = 12; x < certificateWidth - 12; x++) {
		put(x, 12, '#cc0099');
		put(x, certificateHeight - 13, '#cc0099');
	}

	for (let y = 12; y < certificateHeight - 12; y++) {
		put(12, y, '#cc0099');
		put(certificateWidth - 13, y, '#cc0099');
	}

	// The doll, at her real size, in a frame on the right.
	const rendered = renderDoll(adopted);
	const dollLeft = 186;
	const dollTop = 20;
	for (let y = 0; y < 170; y++) {
		for (let x = 0; x < 88; x++) {
			const offset = (((y + 6) * width) + x + 20) * 4;
			if (rendered.pixels[offset + 3] > 0) {
				put(dollLeft + x, dollTop + y, toHex([rendered.pixels[offset], rendered.pixels[offset + 1], rendered.pixels[offset + 2]]));
			}
		}
	}

	for (let x = dollLeft - 2; x < dollLeft + 90; x++) {
		put(x, dollTop - 2, '#ffcc33');
		put(x, dollTop + 171, '#ffcc33');
	}

	for (let y = dollTop - 2; y < dollTop + 172; y++) {
		put(dollLeft - 2, y, '#ffcc33');
		put(dollLeft + 89, y, '#ffcc33');
	}

	const today = new Date();
	const lines = [
		{text: 'This is to certify that', y: 40},
		{text: alternatingCaps(adopter), y: 52, font: boldFont, fill: '#cc0099', outline: '#ffe0f0'},
		{text: 'has adopted the doll', y: 66},
		{text: `~*~ ${alternatingCaps(adopted.name)} ~*~`, y: 78, font: boldFont, fill: '#cc0099', outline: '#ffe0f0'},
		{text: `from ${alternatingCaps('Lillesøster’s Dollz')}`, y: 92},
		{text: `on ${today.getDate()} ${months[today.getMonth()]} 1999.`, y: 104},
		{text: `Adoption no. ${String(number).padStart(5, '0')}`, y: 118, fill: '#806000'},
		{text: `${pronoun(adopted)} likes: ${randomItem(likes)}`, y: 130},
		{text: `Scared of: ${randomItem(fears)}`, y: 142},
		{text: 'Remember: LiNk BaCk!!!', y: 156, font: boldFont, fill: '#ff0000', outline: '#ffffff'},
		{text: 'Signed: Lillesøster (6½)', y: 172, fill: '#2040c0'},
	];
	writeText(data, certificateWidth, certificateHeight, alternatingCaps('Adoption Certificate'), {x: 98, y: 17, font: titleFont, isCentered: true, fill: '#ff3399', outline: '#660033'});
	for (const line of lines) {
		writeText(data, certificateWidth, certificateHeight, line.text, {x: 98, y: line.y, font: line.font ?? smallFont, fill: line.fill ?? '#402030', outline: line.outline ?? false, isCentered: true, maximumWidth: 164});
	}

	// The gold seal.
	const [sealX, sealY] = [27, 177];
	const seal = ellipse(sealX, sealY, 9);
	for (let y = sealY - 10; y < sealY + 11; y++) {
		for (let x = sealX - 10; x < sealX + 11; x++) {
			if (seal.contains(x + 0.5, y + 0.5)) {
				const distance = Math.hypot(x + 0.5 - sealX, y + 0.5 - sealY);
				put(x, y, distance > 7.8 ? '#a07000' : distance > 6.5 ? '#ffd84a' : (x + y) % 3 === 0 ? '#ffe680' : '#f0c020');
			}
		}
	}

	writeText(data, certificateWidth, certificateHeight, 'OK', {x: sealX, y: sealY - 4, font: boldFont, isCentered: true, fill: '#ffffff', outline: '#a07000'});
	context.putImageData(pixels, 0, 0);
};

const houseSize = 12;

export default class extends GeoCitiesElement {
	#context;
	#tabButtons;
	#panels;
	#itemButtons;
	#swatches;
	#doll;
	#house;
	#isBlinkOn;
	#adoptions;
	#currentTab = 'base';
	#lastSlot = 'skin';
	#history = [];
	#image;
	#blinkImage;
	#glitterFrame = 0;
	#isBlinking = false;
	#frameImage = new ImageData(width, height);
	#loop;
	#galleryVersion = 0;

	connected() {
		const {canvas, random, undo, reset, house, png, bigPNG, originalColor, name, maker, glitter, stamp, blink, agree, adopt, certificateBox, certificate, saveCertificate, linkCode} = this.parts;
		this.#context = canvas.getContext('2d');
		this.#tabButtons = [...this.querySelectorAll('[data-dollz-tab]')];
		this.#panels = [...this.querySelectorAll('[data-dollz-panel]')];
		this.#itemButtons = [...this.querySelectorAll('[data-dollz-item]')];
		this.#swatches = [...this.querySelectorAll('[data-dollz-color]')];

		this.#doll = sanitize(this.stored('doll', undefined));
		this.#house = this.stored('house', []).slice(0, houseSize).map(entry => ({doll: sanitize(entry?.doll), isAdopted: entry?.isAdopted === true}));
		this.#isBlinkOn = this.stored('blink', true);
		const storedAdoptions = this.stored('adoptions', 0);
		this.#adoptions = Number.isSafeInteger(storedAdoptions) && storedAdoptions > 0 ? storedAdoptions : 0;
		this.#image = renderDoll(this.#doll);

		// The glitter changes every fifth of a second, and she blinks every few seconds. With reduced motion, neither happens by itself.
		let glitterTime = 0;
		let blinkTime = 3;
		this.#loop = this.loop(seconds => {
			glitterTime += seconds;
			blinkTime -= seconds;
			let isChanged = false;
			if ((this.#doll.glitter || this.#hasAlwaysGlitter) && glitterTime > 0.2) {
				glitterTime = 0;
				this.#glitterFrame = (this.#glitterFrame + 1) % 6;
				isChanged = true;
			}

			if (this.#isBlinkOn && blinkTime <= 0) {
				this.#isBlinking = !this.#isBlinking;
				blinkTime = this.#isBlinking ? 0.14 : 2.5 + (Math.random() * 3);
				isChanged = true;
			}

			if (isChanged) {
				this.#show();
			}
		}, {
			while: () => !this.reducedMotion && (this.#doll.glitter || this.#hasAlwaysGlitter || this.#isBlinkOn),
		});

		for (const button of this.#tabButtons) {
			this.on(button, 'click', () => {
				this.#showTab(button.dataset.dollzTab);
			});
		}

		for (const button of this.#itemButtons) {
			this.on(button, 'click', () => {
				this.#choose(button.dataset.dollzSlot, button.dataset.dollzItem);
			});
		}

		for (const swatch of this.#swatches) {
			swatch.style.setProperty('--dollz-swatch', swatch.dataset.dollzColor);
			this.on(swatch, 'click', () => {
				const key = this.#recolorKey;
				if (!this.#hasPiece(key)) {
					this.say(`She has no ${recolorName(key)} to paint! Pick one first.`);
					return;
				}

				this.#remember();
				this.#doll.colors[key] = swatch.dataset.dollzColor;
				const colorName = swatch.getAttribute('aria-label').toLowerCase();
				this.say(key === 'skin' && !['#ffffff', '#c0c0c0', '#808080'].includes(swatch.dataset.dollzColor) ? `Now she has ${colorName} skin. Is she an alien?!` : `Painted the ${recolorName(key)} ${colorName}, with the paint bucket, like in Paint!`);
				this.#update();
			});
		}

		this.on(originalColor, 'click', () => {
			const key = this.#recolorKey;
			if (!this.#doll.colors[key]) {
				this.say(`That is already the original color of the ${recolorName(key)}.`);
				return;
			}

			this.#remember();
			delete this.#doll.colors[key];
			this.say(`Back to the original color of the ${recolorName(key)}.`);
			this.#update();
		});

		this.on(glitter, 'click', () => {
			this.#remember();
			this.#doll.glitter = !this.#doll.glitter;
			this.say(this.#doll.glitter ? 'GLITTER!!! Everything is better with glitter.' : 'No glitter. Boring, but okay.');
			this.#update();
		});

		this.on(stamp, 'click', () => {
			this.#remember();
			this.#doll.stamp = !this.#doll.stamp;
			this.say(this.#doll.stamp ? 'The stamp is on. Now nobody can steal her.' : 'No stamp?! Then everybody will steal her!!!');
			this.#update();
		});

		this.on(blink, 'click', () => {
			this.#isBlinkOn = !this.#isBlinkOn;
			this.#isBlinking = false;
			this.store('blink', this.#isBlinkOn);
			if (this.reducedMotion && this.#isBlinkOn) {
				this.say('She blinks only when you do not prefer less motion.');
			} else {
				this.say(this.#isBlinkOn ? 'She blinks! Like an animated GIF.' : 'She stopped blinking. Now she stares. Creepy.');
			}

			this.#update();
		});

		for (const [input, field] of [[name, 'name'], [maker, 'maker']]) {
			this.on(input, 'input', () => {
				this.#doll[field] = input.value.slice(0, 14);
				this.store('doll', this.#doll);
				this.#show();
			});

			this.on(input, 'change', () => {
				if (field === 'maker' && this.#doll.maker.trim()) {
					this.say(`MaDe By ${alternatingCaps(this.#doll.maker.trim())}. Now everybody knows you made her.`);
				} else if (field === 'name' && this.#doll.name.trim()) {
					this.say(`${this.#doll.name.trim()}! What a pretty name.`);
				}
			});
		}

		this.on(random, 'click', () => {
			this.#remember();
			const dollMaker = this.#doll.maker;
			this.#doll = this.#randomDoll();
			this.#doll.maker = dollMaker;
			this.say(`Meet ${this.#doll.name}! ${pronoun(this.#doll)} was made by the computer. (I could do better.)`);
			this.#update();
		});

		this.on(undo, 'click', () => {
			const previous = this.#history.pop();
			if (!previous) {
				return;
			}

			this.#doll = previous;
			this.say('Undo! Like Ctrl+Z in Paint.');
			this.#update();
		});

		this.on(reset, 'click', () => {
			this.#remember();
			const dollMaker = this.#doll.maker;
			this.#doll = defaultDoll();
			this.#doll.maker = dollMaker;
			this.say('Start over. A new base, all clean.');
			this.#update();
		});

		this.on(png, 'click', () => {
			this.#show();
			download(canvas, 1, fileName(this.#doll.name));
			this.say(`Saved as ${fileName(this.#doll.name)}.PNG, at the real size! It is tiny, like a real dollz.`);
		});

		this.on(bigPNG, 'click', () => {
			this.#show();
			download(canvas, 4, fileName(this.#doll.name));
			this.say(`Saved as ${fileName(this.#doll.name)}.PNG, four times as big, for people with big screens.`);
		});

		// A right click on a doll was “disabled” on every dollz page.
		this.on(canvas, 'contextmenu', event => {
			event.preventDefault();
			this.say('No RiGhT cLiCk!!! DoN’T StEaL mY dOlLz!!! (Use Save PNG. You made her, so that is allowed.)');
			this.toast('🚫 Right click is disabled!!! DoN’T StEaL!!!');
		});

		// The keys of the canvas change the tab and the piece, so the doll can be dressed from the keyboard.
		this.on(canvas, 'keydown', event => {
			// Keys with Ctrl, Cmd, or Alt belong to the browser, like Ctrl+R to reload and Cmd+Z.
			if (event.ctrlKey || event.metaKey || event.altKey) {
				return;
			}

			const tabButtons = this.#tabButtons;
			const tabIndex = tabButtons.findIndex(button => button.dataset.dollzTab === this.#currentTab);
			if (event.key === 'ArrowLeft' || event.key === 'ArrowRight') {
				event.preventDefault();
				const next = tabButtons[(tabIndex + (event.key === 'ArrowLeft' ? tabButtons.length - 1 : 1)) % tabButtons.length];
				this.#showTab(next.dataset.dollzTab);
				this.say(`The ${next.textContent.trim()} tab.`);
			} else if (event.key === 'ArrowUp' || event.key === 'ArrowDown') {
				event.preventDefault();
				const panel = this.#panels.find(element => element.dataset.dollzPanel === this.#currentTab);
				const buttons = [...panel.querySelectorAll('[data-dollz-item]')].filter(button => button.dataset.dollzSlot === panel.querySelector('[data-dollz-slot]').dataset.dollzSlot);
				const slot = buttons[0].dataset.dollzSlot;
				if (slot === 'extras') {
					this.say('Extras go on and off with their buttons.');
					return;
				}

				const index = buttons.findIndex(button => button.dataset.dollzItem === this.#doll[slot]);
				const next = buttons[(index + (event.key === 'ArrowUp' ? buttons.length - 1 : 1)) % buttons.length];
				this.#choose(slot, next.dataset.dollzItem);
			} else if (event.key === 'r' || event.key === 'R') {
				event.preventDefault();
				random.click();
			} else if (event.key === 'g' || event.key === 'G') {
				event.preventDefault();
				glitter.click();
			} else if (event.key === 'z' || event.key === 'Z') {
				event.preventDefault();
				undo.click();
			}
		});

		// The Dollz House

		this.on(house, 'click', () => {
			if (this.#house.length >= houseSize) {
				this.say(`The Dollz House is full! Mamma says no more dolls until some move out.`);
				return;
			}

			// A doll without a name gets one, as a doll cannot move in without a name on her door.
			const isNamed = Boolean(this.#doll.name.trim());
			if (!isNamed) {
				this.#doll.name = randomItem(this.#doll.body === 'guy' ? guyNames : girlNames);
				this.#update();
			}

			this.#putInHouse(this.#doll);
			const who = isNamed ? this.#doll.name.trim() : `No name? Then ${pronoun(this.#doll).toLowerCase()} is ${this.#doll.name}! ${pronoun(this.#doll)}`;
			this.say(`${who} moved into the Dollz House! (${this.#house.length} of ${houseSize} rooms.)`);
			this.toast(`🏠 ${alternatingCaps(this.#doll.name.trim())} moved into the Dollz House!`);
		});

		// Adopt a Doll

		this.on(agree, 'change', () => {
			this.say(agree.checked ? 'YaY!!! You promised. Now you can adopt one.' : 'You have to promise first!!!');
		});

		this.on(adopt, 'click', () => {
			// The status is far up by the doll, so the toast says it here.
			if (!agree.checked) {
				this.say('You have to promise to follow the rules first!!!');
				this.toast('🤙 You have to promise first!!! Check the pinky promise.');
				agree.focus();
				return;
			}

			this.#adoptions++;
			this.store('adoptions', this.#adoptions);
			const adopted = this.#randomDoll();
			// After the visitor loads a doll of Lillesøster, she is the maker, but not the one who adopts.
			const visitor = maker.value.trim();
			const adopter = visitor && visitor !== sisterName ? visitor : 'A Nice Visitor';
			adopted.maker = sisterName;
			drawCertificate(certificate.getContext('2d'), adopted, this.#adoptions, adopter);
			certificateBox.hidden = false;
			linkCode.value = `<a href="http://www.geocities.com/SiliconValley/Bay/1999/dollz.html"><img src="${fileName(adopted.name)}.GIF" alt="I adopted ${adopted.name} from Lillesøster’s Dollz!!!"></a>`;
			const isHome = this.#putInHouse(adopted, true);
			this.#remember();
			// The copy in the house is by Lillesøster, but the doll on the canvas keeps the name of the visitor, for the next adoption.
			this.#doll = {...structuredClone(adopted), maker: this.#doll.maker};
			this.#update();
			this.celebrate();
			this.say(`${adopted.name} is yours now!!! ${isHome ? `${pronoun(adopted)} lives in your Dollz House.` : `Your Dollz House is full, so ${pronoun(adopted).toLowerCase()} sleeps on the sofa.`} Remember rule 1: LiNk BaCk! And rule 3!!!`);
		});

		this.on(saveCertificate, 'click', () => {
			download(certificate, 2, 'ADOPTION');
			this.say('Saved ADOPTION.PNG. Print it and hang it on the fridge!');
		});

		this.#syncControls();
		this.#show();
		this.#drawWhenFontsAreReady();
	}

	// The doll only blinks and glitters while she is on the screen.
	get visibilityTarget() {
		return this.parts.canvas;
	}

	reducedMotionChanged() {
		this.#isBlinking = false;
		this.#show();
	}

	// “Move Out” removes its room, so the focus goes to the first doll of the house, which never moves out.
	focusReplacement(control) {
		if (!control.isConnected) {
			return this.parts.gallery.querySelector('button');
		}

		return super.focusReplacement(control);
	}

	// Lillesøster says everything.
	say(text, status) {
		super.say(`👧 ${text}`, status);
	}

	// The doll is drawn again once the fonts are ready, so the stamps look the same each time.
	async #drawWhenFontsAreReady() {
		await document.fonts?.ready;
		textMasks.clear();
		this.#show();
		this.#renderGallery();
	}

	#show() {
		if (this.#isBlinking && !this.#blinkImage) {
			this.#blinkImage = renderDoll(this.#doll, {isBlinking: true});
		}

		const shown = this.#isBlinking ? this.#blinkImage : this.#image;
		this.#frameImage.data.set(shown.pixels);
		addGlitter(this.#frameImage.data, shown.glitter, this.#glitterFrame, this.#doll.glitter);
		addStamps(this.#frameImage.data, this.#doll);
		this.#context.putImageData(this.#frameImage, 0, 0);
	}

	get #hasAlwaysGlitter() {
		return this.#doll.extras.includes('halo');
	}

	// Draws the doll again after a change, and keeps her in the browser.
	#update() {
		this.#image = renderDoll(this.#doll);
		this.#blinkImage = undefined;
		if (this.reducedMotion) {
			this.#glitterFrame = (this.#glitterFrame + 1) % 6;
		}

		this.#show();
		this.store('doll', this.#doll);
		this.#syncControls();
		this.#loop.start();
	}

	get #recolorKey() {
		return this.#lastSlot === 'body' ? 'skin' : this.#lastSlot;
	}

	#syncControls() {
		const {recolorTarget, glitter, stamp, blink, undo, nameLabel, name, maker} = this.parts;
		for (const button of this.#tabButtons) {
			setPressed(button, button.dataset.dollzTab === this.#currentTab);
		}

		for (const panel of this.#panels) {
			panel.hidden = panel.dataset.dollzPanel !== this.#currentTab;
		}

		for (const button of this.#itemButtons) {
			const {dollzSlot: slot, dollzItem: item} = button.dataset;
			setPressed(button, slot === 'extras' ? this.#doll.extras.includes(item) : this.#doll[slot] === item);
		}

		const key = this.#recolorKey;
		recolorTarget.textContent = recolorName(key);
		const color = this.#doll.colors[key] ?? defaultColor(this.#doll, key);
		for (const swatch of this.#swatches) {
			setPressed(swatch, swatch.dataset.dollzColor === color);
		}

		setPressed(glitter, this.#doll.glitter);
		setPressed(stamp, this.#doll.stamp);
		setPressed(blink, this.#isBlinkOn);
		undo.disabled = this.#history.length === 0;
		const isGuy = this.#doll.body === 'guy';
		nameLabel.textContent = isGuy ? 'His name:' : 'Her name:';
		name.placeholder = isGuy ? 'Nick' : 'Sparkle';
		if (document.activeElement !== name) {
			name.value = this.#doll.name;
		}

		if (document.activeElement !== maker) {
			maker.value = this.#doll.maker;
		}
	}

	#remember() {
		this.#history.push(structuredClone(this.#doll));
		if (this.#history.length > 40) {
			this.#history.shift();
		}
	}

	#randomDoll() {
		return randomDoll(this.#swatches.map(swatch => swatch.dataset.dollzColor));
	}

	// What Lillesøster says about a choice.
	#sayAbout(slot, id, isOn = true) {
		if (slot === 'body') {
			this.say(id === 'guy' ? 'Ewww, a GuY dOlLz! Okay. He can be in the boy band.' : 'A girl dollz. The best kind of dollz.');
			return;
		}

		if (slot === 'extras') {
			this.say(isOn ? extras[id].says : `No more ${extras[id].name}. Okay.`);
			return;
		}

		if (slot === 'cheeks' && id === 'none') {
			this.say('No blush. She is not shy anymore.');
			return;
		}

		const piece = slots[slot]?.[id];
		this.say(piece?.says ?? (id === 'none' ? `No ${slotNames[slot]}. Hmm.` : 'Pretty!!!'));
	}

	#choose(slot, id) {
		this.#remember();
		if (slot === 'extras') {
			const isOn = !this.#doll.extras.includes(id);
			this.#doll.extras = isOn ? [...this.#doll.extras, id] : this.#doll.extras.filter(extra => extra !== id);
			this.#lastSlot = isOn ? `extra:${id}` : this.#lastSlot;
			this.#sayAbout(slot, id, isOn);
		} else {
			this.#doll[slot] = id;
			this.#lastSlot = slot;
			if (slot === 'skin') {
				delete this.#doll.colors.skin;
			}

			if ((slot === 'top' || slot === 'bottom') && id !== 'none' && this.#doll.dress !== 'none') {
				this.#doll.dress = 'none';
			}

			this.#sayAbout(slot, id);
		}

		this.#update();
	}

	#showTab(tab) {
		this.#currentTab = tab;
		const firstSlot = this.#panels.find(panel => panel.dataset.dollzPanel === tab)?.querySelector('[data-dollz-slot]')?.dataset.dollzSlot;
		if (firstSlot && firstSlot !== 'extras') {
			this.#lastSlot = firstSlot;
		}

		this.#syncControls();
	}

	// Whether the piece to recolor is there to recolor. A dress hides the top and the bottoms.
	#hasPiece(key) {
		if (key.startsWith('extra:')) {
			return this.#doll.extras.includes(key.slice('extra:'.length));
		}

		if ((key === 'top' || key === 'bottom') && this.#doll.dress !== 'none') {
			return false;
		}

		return this.#doll[key] !== 'none';
	}

	// The Dollz House

	async #renderGallery() {
		const {gallery, canvas, maker} = this.parts;
		const version = ++this.#galleryVersion;
		const entries = [
			...sisterDolls.map(sisterDoll => ({doll: sisterDoll, isSister: true})),
			...this.#house.map((entry, index) => ({...entry, index})),
		];
		const items = [];
		for (const entry of entries) {
			const item = document.createElement('li');
			item.dataset.state = entry.isSister ? 'sister' : '';
			const loadButton = document.createElement('button');
			loadButton.type = 'button';
			const name = entry.doll.name.trim() || 'No name';
			loadButton.setAttribute('aria-label', `Dress ${name} again`);
			const caption = document.createElement('span');
			caption.textContent = alternatingCaps(name) + (entry.isSister ? ' (by Lillesøster)' : entry.isAdopted ? ' (adopted)' : '');
			item.append(loadButton, caption);
			// The rooms are made again with each change of the house, so their listeners go away with them.
			loadButton.addEventListener('click', () => {
				this.#remember();
				this.#doll = structuredClone(entry.doll);
				if (!entry.isSister) {
					this.#doll.maker ||= maker.value;
				}

				this.say(entry.isSister ? `${name} is Lillesøster’s. You can dress ${entry.doll.body === 'guy' ? 'him' : 'her'} up, but the doll stays in the house.` : `${name} came out of the Dollz House to play.`);
				this.#update();
				canvas.scrollIntoView({block: 'nearest'});
			});
			if (!entry.isSister) {
				const removeButton = document.createElement('button');
				removeButton.type = 'button';
				removeButton.textContent = '✖ Move Out';
				removeButton.addEventListener('click', () => {
					this.#house = this.#house.filter((_, index) => index !== entry.index);
					this.store('house', this.#house);
					this.say(`${name} moved out of the Dollz House. Bye bye!`);
					this.#renderGallery();
				});
				item.append(removeButton);
			}

			items.push({item, loadButton, doll: entry.doll});
		}

		gallery.replaceChildren(...items.map(({item}) => item));

		// The pictures are drawn one at a time, so the page does not stop while they are drawn.
		for (const {loadButton, doll: savedDoll} of items) {
			await nextFrame();
			if (version !== this.#galleryVersion) {
				return;
			}

			loadButton.append(dollCanvas(savedDoll));
		}
	}

	#putInHouse(savedDoll, isAdopted = false) {
		if (this.#house.length >= houseSize) {
			return false;
		}

		this.#house = [...this.#house, {doll: structuredClone(savedDoll), isAdopted}];
		this.store('house', this.#house);
		this.#renderGallery();
		return true;
	}
}
