// My LEGO on the 1999 page: a builder like LEGO Creator (1998). Bricks go on a green baseplate of 10 × 10 studs, drawn in an isometric view, each brick dropped onto whatever is below it. A click on the plate or on a brick puts the chosen brick there, on top. The bricks are drawn as unit cells sorted from the back to the front, with only the faces that show, and lines only where one brick ends, so a 2×4 looks like one brick. A second canvas, not on the page, has each visible face in a color of its own, so a click finds the brick under the pointer. The building is kept in the browser.
const randomItem = items => items[Math.floor(Math.random() * items.length)];
const randomInteger = (minimum, maximum) => minimum + Math.floor(Math.random() * (maximum - minimum + 1));
const clamp = (value, minimum, maximum) => Math.min(Math.max(value, minimum), maximum);
const plural = (count, word) => `${count.toLocaleString('en-US')} ${word}${count === 1 ? '' : 's'}`;

// Shows a toggle button as pressed, for screen readers and for the style.
const setPressed = (button, isPressed) => {
	button.setAttribute('aria-pressed', String(isPressed));
	button.dataset.state = isPressed ? 'on' : '';
};

// The position of a pointer on a canvas, in the pixels of the canvas.
const canvasPoint = (canvas, event) => {
	const rectangle = canvas.getBoundingClientRect();
	return {
		x: (event.clientX - rectangle.left) * canvas.width / rectangle.width,
		y: (event.clientY - rectangle.top) * canvas.height / rectangle.height,
	};
};

// A tiny pixel font of 3 × 5 for the text on the plate, so it is crisp at any size. Each letter is five rows of three bits.
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

// A canvas that is not on the page, for picking.
const makeCanvas = (width, height) => {
	const canvas = document.createElement('canvas');
	canvas.width = width;
	canvas.height = height;
	return canvas;
};

// Sets up the builder in the element, and gives the function that draws the plate.
const setUp = (lego, {canvas, step: stepText}) => {
	const context = canvas.getContext('2d');
	const pickCanvas = makeCanvas(canvas.width, canvas.height);
	const pickContext = pickCanvas.getContext('2d', {willReadFrequently: true});
	const size = 10;
	const maximumHeight = 7;

	// The isometric view: a step along x goes right and down, a step along y goes left and down, and a brick is 30 pixels high.
	const cellX = 26;
	const cellY = 13;
	const brickHeight = 30;
	const originX = canvas.width / 2;
	const originY = 190;

	const colors = {
		red: '#c91a09',
		blue: '#0055bf',
		yellow: '#f2cd37',
		green: '#237841',
		white: '#f4f4f4',
		gray: '#a0a5a9',
		black: '#2a2a2a',
		clear: '#bfe6f0',
	};

	const colorNames = Object.fromEntries([...lego.querySelectorAll('[data-lego-color]')].map(button => [button.dataset.legoColor, button.textContent.trim().toLowerCase()]));

	const pieces = {
		'2x4': {width: 4, depth: 2, name: '2×4'},
		'2x2': {width: 2, depth: 2, name: '2×2'},
		'1x4': {width: 4, depth: 1, name: '1×4'},
		'1x2': {width: 2, depth: 1, name: '1×2'},
		'1x1': {width: 1, depth: 1, name: '1×1'},
		figure: {width: 1, depth: 1, name: 'minifigure'},
	};

	// Set 6999, the Brunost Cruiser of LEGO Space, step by step: each step is a brick, with where it goes. The height is where it drops to.
	const instructions = [
		{piece: '2x4', color: 'blue', x: 2, y: 4, isTurned: false},
		{piece: '2x4', color: 'blue', x: 6, y: 4, isTurned: false},
		{piece: '2x4', color: 'gray', x: 4, y: 1, isTurned: true},
		{piece: '2x4', color: 'gray', x: 4, y: 5, isTurned: true},
		{piece: '1x2', color: 'red', x: 4, y: 1, isTurned: false},
		{piece: '1x2', color: 'red', x: 4, y: 8, isTurned: false},
		{piece: '2x2', color: 'clear', x: 7, y: 4, isTurned: false},
		{piece: '2x2', color: 'white', x: 2, y: 4, isTurned: false},
		{piece: '1x2', color: 'yellow', x: 2, y: 4, isTurned: true},
		{piece: 'figure', color: 'red', x: 6, y: 5, isTurned: false},
	];

	const isValidBrick = brick => {
		if (!Object.hasOwn(pieces, brick?.piece) || !Object.hasOwn(colors, brick.color) || typeof brick.isTurned !== 'boolean' || ![brick.x, brick.y, brick.z].every(Number.isInteger)) {
			return false;
		}

		const {width, depth} = footprint(brick);
		return brick.x >= 0 && brick.y >= 0 && brick.x + width <= size && brick.y + depth <= size && brick.z >= 0 && brick.z + (brick.piece === 'figure' ? 2 : 1) <= maximumHeight;
	};

	const state = {
		piece: '2x4',
		color: 'red',
		isTurned: false,
		isRemoving: false,
		hover: undefined,
		cursor: {x: 4, y: 4},
		usesKeyboard: false,
		step: undefined,
		isSetOpen: false,
		flight: undefined,
		undo: [],
	};

	const footprint = brick => {
		const piece = pieces[brick.piece];
		return brick.isTurned ? {width: piece.depth, depth: piece.width} : {width: piece.width, depth: piece.depth};
	};

	const stored = lego.stored('bricks', []);
	let bricks = (Array.isArray(stored) ? stored : []).filter(brick => isValidBrick(brick)).map(({piece, color, isTurned, x, y, z}) => ({piece, color, isTurned, x, y, z}));

	// The unit cells of a brick. A minifigure is two cells high: the legs and the body, and the head.
	const cellsOf = brick => {
		const {width, depth} = footprint(brick);
		const cells = [];
		const levels = brick.piece === 'figure' ? 2 : 1;
		for (let level = 0; level < levels; level++) {
			for (let x = brick.x; x < brick.x + width; x++) {
				for (let y = brick.y; y < brick.y + depth; y++) {
					cells.push({x, y, z: brick.z + level, brick, level});
				}
			}
		}

		return cells;
	};

	let grid = new Map();
	const key = (x, y, z) => `${x},${y},${z}`;

	const rebuildGrid = () => {
		grid = new Map();
		for (const brick of bricks) {
			for (const cell of cellsOf(brick)) {
				grid.set(key(cell.x, cell.y, cell.z), cell);
			}
		}
	};

	// The height a brick drops to: on top of the highest thing below its footprint.
	const dropHeight = (x, y, width, depth) => {
		let height = 0;
		for (const cell of grid.values()) {
			if (cell.x >= x && cell.x < x + width && cell.y >= y && cell.y < y + depth) {
				height = Math.max(height, cell.z + 1);
			}
		}

		return height;
	};

	// Where the chosen brick would go for a stud: centered on it, inside the plate, and dropped.
	const placement = (x, y, piece = state.piece, isTurned = state.isTurned, color = state.color) => {
		const brick = {piece, color, isTurned, x: 0, y: 0, z: 0};
		const {width, depth} = footprint(brick);
		brick.x = clamp(x - Math.floor((width - 1) / 2), 0, size - width);
		brick.y = clamp(y - Math.floor((depth - 1) / 2), 0, size - depth);
		brick.z = dropHeight(brick.x, brick.y, width, depth);
		brick.isValid = brick.z + (piece === 'figure' ? 2 : 1) <= maximumHeight;
		return brick;
	};

	const project = (x, y, z) => [originX + ((x - y) * cellX), originY + ((x + y) * cellY) - (z * brickHeight)];

	const shade = (hex, factor) => {
		const value = Number.parseInt(hex.slice(1), 16);
		const channel = shift => Math.round(((value >> shift) & 255) * factor);
		return `rgb(${channel(16)}, ${channel(8)}, ${channel(0)})`;
	};

	const face = (target, color, corners) => {
		target.fillStyle = color;
		target.beginPath();
		for (const corner of corners) {
			target.lineTo(...project(...corner));
		}

		target.closePath();
		target.fill();
	};

	const line = (target, color, from, to) => {
		target.strokeStyle = color;
		target.lineWidth = 1.5;
		target.beginPath();
		target.moveTo(...project(...from));
		target.lineTo(...project(...to));
		target.stroke();
	};

	// A stud on the top of a cell, at the height of its top: a short cylinder, with a light top.
	const stud = (target, color, x, y, z) => {
		const [centerX, centerY] = project(x + 0.5, y + 0.5, z);
		const radiusX = cellX * 0.42;
		const radiusY = cellY * 0.42;
		const height = 5;
		target.fillStyle = shade(color, 0.7);
		target.beginPath();
		target.ellipse(centerX, centerY, radiusX, radiusY, 0, 0, Math.PI);
		target.lineTo(centerX - radiusX, centerY - height);
		target.ellipse(centerX, centerY - height, radiusX, radiusY, 0, Math.PI, 0, true);
		target.closePath();
		target.fill();
		target.fillStyle = color;
		target.beginPath();
		target.ellipse(centerX, centerY - height, radiusX, radiusY, 0, 0, Math.PI * 2);
		target.fill();
		target.fillStyle = 'rgba(255, 255, 255, 0.25)';
		target.beginPath();
		target.ellipse(centerX - 3, centerY - height - 1, radiusX * 0.4, radiusY * 0.35, 0, 0, Math.PI * 2);
		target.fill();
	};

	// Draws one cell of a brick: the top, the right side, and the front side, only where nothing covers them, with lines where the brick ends. A cell of a minifigure is drawn as legs and a body, or as a yellow head.
	const drawCell = (target, cell, lift = 0) => {
		const {x, y, brick} = cell;
		const z = cell.z + lift;
		const base = colors[brick.color];
		const isClear = brick.color === 'clear';
		const neighbor = (dx, dy, dz) => grid.get(key(cell.x + dx, cell.y + dy, cell.z + dz));
		const sameBrick = (dx, dy, dz) => neighbor(dx, dy, dz)?.brick === brick;
		target.globalAlpha = isClear ? 0.6 : 1;

		if (brick.piece === 'figure') {
			drawFigureCell(target, cell, z, base);
			target.globalAlpha = 1;
			return;
		}

		const edge = shade(base, 0.45);
		if (!neighbor(0, 0, 1)) {
			face(target, base, [[x, y, z + 1], [x + 1, y, z + 1], [x + 1, y + 1, z + 1], [x, y + 1, z + 1]]);
			if (!sameBrick(-1, 0, 0)) {
				line(target, edge, [x, y, z + 1], [x, y + 1, z + 1]);
			}

			if (!sameBrick(0, -1, 0)) {
				line(target, edge, [x, y, z + 1], [x + 1, y, z + 1]);
			}
		}

		if (!neighbor(1, 0, 0) || (neighbor(1, 0, 0).brick.color === 'clear' && !isClear)) {
			face(target, shade(base, 0.62), [[x + 1, y, z], [x + 1, y + 1, z], [x + 1, y + 1, z + 1], [x + 1, y, z + 1]]);
			line(target, edge, [x + 1, y, z + 1], [x + 1, y + 1, z + 1]);
			line(target, edge, [x + 1, y, z], [x + 1, y + 1, z]);
			if (!sameBrick(0, 1, 0)) {
				line(target, edge, [x + 1, y + 1, z], [x + 1, y + 1, z + 1]);
			}
		}

		if (!neighbor(0, 1, 0) || (neighbor(0, 1, 0).brick.color === 'clear' && !isClear)) {
			face(target, shade(base, 0.8), [[x, y + 1, z], [x + 1, y + 1, z], [x + 1, y + 1, z + 1], [x, y + 1, z + 1]]);
			line(target, edge, [x, y + 1, z + 1], [x + 1, y + 1, z + 1]);
			line(target, edge, [x, y + 1, z], [x + 1, y + 1, z]);
			if (!sameBrick(-1, 0, 0)) {
				line(target, edge, [x, y + 1, z], [x, y + 1, z + 1]);
			}
		}

		if (!neighbor(0, 0, 1)) {
			stud(target, base, x, y, z + 1);
		}

		target.globalAlpha = 1;
	};

	// A minifigure: blue legs and a body in the chosen color in the lower cell, and the yellow head with a smile and a stud in the upper cell.
	const drawFigureCell = (target, cell, z, base) => {
		const {x, y} = cell;
		const inset = 0.18;
		const box = (color, bottom, top, left = inset, right = 1 - inset) => {
			face(target, color, [[x + left, y + left, top], [x + right, y + left, top], [x + right, y + right, top], [x + left, y + right, top]]);
			face(target, shade(color.startsWith('#') ? color : '#888888', 0.62), [[x + right, y + left, bottom], [x + right, y + right, bottom], [x + right, y + right, top], [x + right, y + left, top]]);
			face(target, shade(color.startsWith('#') ? color : '#888888', 0.8), [[x + left, y + right, bottom], [x + right, y + right, bottom], [x + right, y + right, top], [x + left, y + right, top]]);
		};

		if (cell.level === 0) {
			box('#2a4a9a', z, z + 0.45);
			box(base, z + 0.45, z + 1);
			return;
		}

		box('#f2cd37', z, z + 0.55, 0.28, 0.72);
		const [faceX, faceY] = project(x + 0.72, y + 0.72, z + 0.3);
		target.fillStyle = '#222222';
		target.fillRect(faceX - 6, faceY - 4, 2, 2);
		target.fillRect(faceX + 2, faceY - 4, 2, 2);
		target.strokeStyle = '#222222';
		target.lineWidth = 1.2;
		target.beginPath();
		target.arc(faceX - 1, faceY - 1, 4, 0.2 * Math.PI, 0.8 * Math.PI);
		target.stroke();
		const [studX, studY] = project(x + 0.5, y + 0.5, z + 0.55);
		target.fillStyle = '#e0bb2a';
		target.beginPath();
		target.ellipse(studX, studY - 2, 5, 2.5, 0, 0, Math.PI * 2);
		target.fill();
	};

	// The green baseplate, with a stud on each cell that has nothing on it.
	const plateColor = '#237841';
	const drawPlate = (target, showsAllStuds) => {
		face(target, shade(plateColor, 0.6), [[size, 0, 0], [size, size, 0], [size, size, -0.2], [size, 0, -0.2]]);
		face(target, shade(plateColor, 0.78), [[0, size, 0], [size, size, 0], [size, size, -0.2], [0, size, -0.2]]);
		face(target, plateColor, [[0, 0, 0], [size, 0, 0], [size, size, 0], [0, size, 0]]);
		for (let sum = 0; sum < size * 2; sum++) {
			for (let x = 0; x < size; x++) {
				const y = sum - x;
				if (y >= 0 && y < size && (showsAllStuds || !grid.has(key(x, y, 0)))) {
					stud(target, plateColor, x, y, 0);
				}
			}
		}
	};

	// The cells from the back to the front, so the nearer ones are drawn over the ones behind them. With the view from the front, nearer means a larger x, y, and z.
	const sortedCells = () => [...grid.values()].sort((first, second) => (first.x + first.y + (first.z * 0.87)) - (second.x + second.y + (second.z * 0.87)));

	// The picking canvas: each visible face of a cell, and each stud of the plate, in a color of its own, so the color under the pointer says which cell it is. The blue channel is a check, so the soft edges between two faces are ignored.
	const encode = id => `rgb(${id & 255}, ${id >> 8}, ${((id & 255) * 7 + ((id >> 8) * 13)) & 255})`;

	// The id of the blinking brick of the instructions on the picking canvas, above the ids of the cells.
	const stepId = 2000;

	// The three faces of a cell that can show: the top, the right side, and the front side.
	const pickCell = (color, {x, y, z}) => {
		face(pickContext, color, [[x, y, z + 1], [x + 1, y, z + 1], [x + 1, y + 1, z + 1], [x, y + 1, z + 1]]);
		face(pickContext, color, [[x + 1, y, z], [x + 1, y + 1, z], [x + 1, y + 1, z + 1], [x + 1, y, z + 1]]);
		face(pickContext, color, [[x, y + 1, z], [x + 1, y + 1, z], [x + 1, y + 1, z + 1], [x, y + 1, z + 1]]);
	};

	const rebuildPicking = () => {
		pickContext.clearRect(0, 0, pickCanvas.width, pickCanvas.height);
		for (let x = 0; x < size; x++) {
			for (let y = 0; y < size; y++) {
				face(pickContext, encode(1 + x + (y * size)), [[x, y, 0], [x + 1, y, 0], [x + 1, y + 1, 0], [x, y + 1, 0]]);
			}
		}

		for (const cell of sortedCells()) {
			pickCell(encode(1 + cell.x + (cell.y * size) + ((cell.z + 1) * 100)), cell);
		}

		// The blinking brick of the instructions goes on top, so a click on it puts the brick there, also where it floats over the plate and covers other bricks. While taking bricks off, a click goes to the bricks under it.
		const step = currentStep();
		if (step && !state.isRemoving) {
			for (const cell of cellsOf(step)) {
				pickCell(encode(stepId), cell);
			}
		}
	};

	// The cell under a point of the canvas: a stud of the plate, a cell of a brick, or the blinking brick of the instructions.
	const pick = (pointX, pointY) => {
		const [red, green, blue, alpha] = pickContext.getImageData(Math.floor(pointX), Math.floor(pointY), 1, 1).data;
		if (alpha < 255 || blue !== (((red * 7) + (green * 13)) & 255)) {
			return undefined;
		}

		const id = red + (green << 8);
		if (id === stepId) {
			return {isStep: true};
		}

		if (id < 1) {
			return undefined;
		}

		return {x: (id - 1) % size, y: Math.floor((id - 1) / size) % size, z: Math.floor((id - 1) / 100) - 1};
	};

	const currentStep = () => (state.step === undefined ? undefined : instructions[state.step]);

	// The height of each brick of the instructions, from dropping the bricks of the steps before it.
	{
		const savedGrid = grid;
		grid = new Map();
		for (const step of instructions) {
			const {width, depth} = footprint(step);
			step.z = dropHeight(step.x, step.y, width, depth);
			for (const cell of cellsOf(step)) {
				grid.set(key(cell.x, cell.y, cell.z), cell);
			}
		}

		grid = savedGrid;
	}

	// A brick that is not on the plate, drawn see-through: the brick that the pointer would put on, or the brick of the step of the instructions.
	const drawGhost = (target, brick, {alpha, outline}) => {
		const ghostGrid = grid;
		grid = new Map(grid);
		for (const cell of cellsOf(brick)) {
			grid.set(key(cell.x, cell.y, cell.z), cell);
		}

		target.globalAlpha = 1;
		const cells = cellsOf(brick).sort((first, second) => (first.x + first.y + first.z) - (second.x + second.y + second.z));
		target.save();
		target.globalAlpha = alpha;
		for (const cell of cells) {
			target.globalAlpha = alpha;
			drawCell(target, cell);
		}

		target.restore();
		grid = ghostGrid;
		if (outline) {
			const {width, depth} = footprint(brick);
			const height = brick.piece === 'figure' ? 2 : 1;
			target.setLineDash([5, 4]);
			target.strokeStyle = outline;
			target.lineWidth = 2;
			target.beginPath();
			for (const corner of [[brick.x, brick.y, brick.z + height], [brick.x + width, brick.y, brick.z + height], [brick.x + width, brick.y + depth, brick.z + height], [brick.x, brick.y + depth, brick.z + height]]) {
				target.lineTo(...project(...corner));
			}

			target.closePath();
			target.stroke();
			target.setLineDash([]);
		}
	};

	const draw = (time = performance.now()) => {
		context.clearRect(0, 0, canvas.width, canvas.height);
		const sky = context.createLinearGradient(0, 0, 0, canvas.height);
		sky.addColorStop(0, '#9cc3e6');
		sky.addColorStop(1, '#d8e8f4');
		context.fillStyle = sky;
		context.fillRect(0, 0, canvas.width, canvas.height);

		if (state.flight) {
			// The building flies around the room, and the plate shows all its studs while it is gone.
			drawPlate(context, true);
			const {x, y, angle} = state.flight.position;
			// It tilts around the middle of the plate, like a ship in a turn.
			const [centerX, centerY] = project(size / 2, size / 2, 1);
			context.save();
			context.translate(x + centerX, y + centerY);
			context.rotate(angle);
			context.translate(-centerX, -centerY);
			for (const cell of sortedCells()) {
				drawCell(context, cell);
			}

			context.restore();
			for (const spark of state.flight.sparks) {
				context.fillStyle = spark.life > 0.5 ? '#ffee55' : '#ff7722';
				context.fillRect(spark.x, spark.y, 4, 4);
			}

			drawPixelText(context, 'VRRROOOOM!', originX, 24, '#c91a09', {align: 'center', scale: 4});
			return;
		}

		drawPlate(context, false);
		for (const cell of sortedCells()) {
			drawCell(context, cell);
		}

		const step = currentStep();
		if (step) {
			const isBlinkOn = lego.reducedMotion || Math.floor(time / 450) % 2 === 0;
			drawGhost(context, step, {alpha: 0.35, outline: isBlinkOn ? '#ffffff' : '#0055bf'});
		}

		const target = state.usesKeyboard ? state.cursor : state.hover;
		if (target && !state.isRemoving) {
			const brick = placement(target.x, target.y);
			drawGhost(context, brick, {alpha: brick.isValid ? 0.55 : 0.25, outline: brick.isValid ? undefined : '#ff0000'});
		} else if (target && state.isRemoving) {
			const top = topCell(target.x, target.y);
			if (top) {
				drawGhost(context, top.brick, {alpha: 0, outline: '#ff0000'});
			}
		}

		if (bricks.length === 0 && !step) {
			drawPixelText(context, 'CLICK THE PLATE TO BUILD!', originX, 40, '#0055bf', {align: 'center', scale: 3});
		}
	};

	// The top cell of a column, which the keyboard and the Take Off tool take.
	const topCell = (x, y) => [...grid.values()].filter(cell => cell.x === x && cell.y === y).sort((first, second) => second.z - first.z)[0];

	const matchesStep = step => brick => brick.piece === step.piece && brick.color === step.color && brick.x === step.x && brick.y === step.y && brick.z === step.z && (brick.piece === 'figure' || brick.isTurned === step.isTurned || step.piece === '2x2' || step.piece === '1x1');

	// While the instructions are open, the step is the first one whose brick is not in its place, so taking a brick off, or Undo, goes back to it.
	const syncStep = () => {
		if (!state.isSetOpen) {
			return;
		}

		const missing = instructions.findIndex(step => !bricks.some(matchesStep(step)));
		const step = missing === -1 ? undefined : missing;
		if (step !== state.step && step !== undefined) {
			selectPiece(instructions[step].piece);
			selectColor(instructions[step].color);
			state.isTurned = instructions[step].isTurned;
		}

		state.step = step;
		showStep();
		blink.start();
	};

	const changed = () => {
		rebuildGrid();
		syncStep();
		rebuildPicking();
		lego.store('bricks', bricks.map(({piece, color, isTurned, x, y, z}) => ({piece, color, isTurned, x, y, z})));
		draw();
	};

	const remember = () => {
		state.undo.push(JSON.stringify(bricks));
		state.undo.splice(0, state.undo.length - 50);
	};

	const describe = brick => `${brick.piece === 'figure' ? `a minifigure in ${colorNames[brick.color]}` : `a ${colorNames[brick.color]} ${pieces[brick.piece].name}`}`;

	const showStep = () => {
		const step = currentStep();
		stepText.hidden = !step;
		if (step) {
			stepText.textContent = `Set 6999, the Brunost Cruiser. Step ${state.step + 1} of ${instructions.length}: ${describe(step)}. Click the blinking brick to put it there.`;
		}
	};

	const selectPiece = piece => {
		state.piece = piece;
		for (const button of lego.querySelectorAll('[data-lego-piece]')) {
			setPressed(button, button.dataset.legoPiece === piece);
		}
	};

	const selectColor = color => {
		state.color = color;
		for (const button of lego.querySelectorAll('[data-lego-color]')) {
			setPressed(button, button.dataset.legoColor === color);
		}
	};

	const setRemoving = isRemoving => {
		state.isRemoving = isRemoving;
		setPressed(lego.querySelector('[data-lego-action="remove"]'), isRemoving);
		rebuildPicking();
	};

	// After a brick, says when it finished a step of the instructions, or the whole set.
	const reportStep = before => {
		if (!state.isSetOpen || before === state.step) {
			return false;
		}

		if (state.step === undefined) {
			lego.celebrate();
			lego.say('You built set 6999, the Brunost Cruiser! It is ready for space. Press Swoosh!');
			return true;
		}

		lego.say(`Step ${state.step} done! Next: ${describe(instructions[state.step])}.`);
		return true;
	};

	// A click on the blinking brick puts the brick of the step there, the way it is turned in the instructions.
	const placeStep = () => {
		const {piece, color, isTurned, x, y, z} = currentStep();
		const {width, depth} = footprint({piece, isTurned});

		// A brick of your own in the way would lift it off its place, and then the step would never be done.
		if (dropHeight(x, y, width, depth) !== z) {
			lego.say('Another brick is in the way of this step. Press Take Off and click that brick first.');
			return;
		}

		remember();
		const before = state.step;
		bricks.push({piece, color, isTurned, x, y, z});
		changed();
		reportStep(before);
	};

	const placeAt = (x, y) => {
		const brick = placement(x, y);
		if (!brick.isValid) {
			lego.say('Too high! Mom says the ceiling is the limit, and so is this plate.');
			return;
		}

		remember();
		delete brick.isValid;
		const before = state.step;
		bricks.push(brick);
		changed();
		if (!reportStep(before)) {
			lego.say(`Click! ${describe(brick)}${brick.z > 0 ? `, on level ${brick.z + 1}` : ''}.`);
		}
	};

	const removeAt = (x, y, z) => {
		const cell = z === undefined ? topCell(x, y) : grid.get(key(x, y, z));
		if (!cell) {
			lego.say('There is no brick there.');
			return;
		}

		const {brick} = cell;
		const isCovered = cellsOf(brick).some(part => {
			const above = grid.get(key(part.x, part.y, part.z + 1));
			return above && above.brick !== brick;
		});
		if (isCovered) {
			lego.say('There is a brick on top of it. Take that one off first.');
			return;
		}

		remember();
		bricks = bricks.filter(other => other !== brick);
		changed();
		lego.say(`Took off ${describe(brick)}. ${randomItem(['Pop!', 'With the teeth, like everyone does.', 'Click.'])}`);
	};

	// The Swoosh button: the building lifts off the plate and flies a loop around the room, with sparks from the back, and lands again, like every LEGO spaceship ever. With reduced motion, it only says so.
	const swoosh = () => {
		if (bricks.length === 0) {
			lego.say('There is nothing to swoosh. Build something first!');
			return;
		}

		if (lego.reducedMotion) {
			lego.say('Swoosh! It flew around the room, in your imagination. It made the noise too: vrrroooom!');
			return;
		}

		if (state.flight) {
			return;
		}

		lego.say('Swoosh! Vrrroooom! Pew pew!');
		const cells = [...grid.values()];
		const backX = Math.min(...cells.map(cell => cell.x));
		const backCells = cells.filter(cell => cell.x === backX);
		const back = {x: backX, y: 0, z: 0};
		for (const cell of backCells) {
			back.y += (cell.y + 0.5) / backCells.length;
			back.z += (cell.z + 0.5) / backCells.length;
		}

		state.flight = {time: 0, position: {x: 0, y: 0, angle: 0}, sparks: [], back};
		flightLoop.start();
	};

	// The flight, frame by frame, until it lands.
	const flightLoop = lego.loop(seconds => {
		const flight = state.flight;
		flight.time += seconds;
		const progress = flight.time / 3.2;
		// Up, a figure of eight, and down again.
		const lift = Math.sin(Math.min(progress, 1) * Math.PI);
		const angle = progress * Math.PI * 2;
		flight.position = {
			x: Math.sin(angle) * 150 * lift,
			y: (-70 * lift) + (Math.sin(angle * 2) * 30 * lift),
			angle: Math.cos(angle) * 0.2 * lift,
		};
		// The sparks come out of the back of the building, the end with the smallest x, which is the back of a ship that flies along x.
		const [backX, backY] = project(flight.back.x, flight.back.y, flight.back.z);
		flight.sparks.push({x: backX + flight.position.x + randomInteger(-6, 6), y: backY + flight.position.y + randomInteger(-6, 6), life: 1});
		for (const spark of flight.sparks) {
			spark.life -= seconds * 2;
			spark.y += seconds * 60;
		}

		flight.sparks = flight.sparks.filter(spark => spark.life > 0);
		draw();
		if (progress >= 1) {
			state.flight = undefined;
			lego.say('And it lands. Perfect landing! Only three bricks fell off. Just kidding.');
			draw();
			blink.start();
		}
	}, {while: () => state.flight !== undefined});

	const startSet = () => {
		remember();
		bricks = [];
		state.isSetOpen = true;
		state.step = undefined;
		setRemoving(false);
		changed();
		lego.say('The box is open, and the old building went back in the bucket (Undo brings it back). Follow the instructions!');
	};

	const actions = {
		rotate() {
			state.isTurned = !state.isTurned;
			lego.say(state.isTurned ? 'Turned the brick.' : 'Turned it back.');
			draw();
		},
		remove() {
			setRemoving(!state.isRemoving);
			lego.say(state.isRemoving ? 'Take Off: click a brick to take it off.' : 'Back to building.');
			draw();
		},
		undo() {
			if (state.undo.length === 0) {
				lego.say('Nothing to undo.');
				return;
			}

			bricks = JSON.parse(state.undo.pop());
			changed();
			lego.say('Undone.');
		},
		swoosh,
		set: startSet,
		tidy() {
			if (bricks.length === 0) {
				lego.say('It is already tidy. Mom is impressed.');
				return;
			}

			remember();
			const count = bricks.length;
			bricks = [];
			state.isSetOpen = false;
			state.step = undefined;
			showStep();
			changed();
			lego.say(`Tidied up ${plural(count, 'brick')} into the bucket. Mom says thank you. (Undo brings them back.)`);
		},
	};

	for (const button of lego.querySelectorAll('[data-lego-piece]')) {
		lego.on(button, 'click', () => {
			selectPiece(button.dataset.legoPiece);
			setRemoving(false);
			draw();
		});
	}

	for (const button of lego.querySelectorAll('[data-lego-color]')) {
		lego.on(button, 'click', () => {
			selectColor(button.dataset.legoColor);
			setRemoving(false);
			draw();
		});
	}

	for (const button of lego.querySelectorAll('[data-lego-action]')) {
		lego.on(button, 'click', () => {
			actions[button.dataset.legoAction]();
		});
	}

	lego.on(canvas, 'pointermove', event => {
		if (state.flight) {
			return;
		}

		const point = canvasPoint(canvas, event);
		const cell = pick(point.x, point.y);
		const hover = cell && !cell.isStep ? {x: cell.x, y: cell.y, z: cell.z} : undefined;
		// It only draws again when the pointer is over another cell.
		if (!state.usesKeyboard && hover?.x === state.hover?.x && hover?.y === state.hover?.y && hover?.z === state.hover?.z) {
			return;
		}

		state.usesKeyboard = false;
		state.hover = hover;
		draw();
	});

	lego.on(canvas, 'pointerleave', () => {
		state.hover = undefined;
		draw();
	});

	// A click, not a press, so a finger that scrolls the page over the plate does not put a brick on.
	lego.on(canvas, 'click', event => {
		if (state.flight || event.button !== 0) {
			return;
		}

		const point = canvasPoint(canvas, event);
		const cell = pick(point.x, point.y);
		state.usesKeyboard = false;
		if (!cell) {
			return;
		}

		if (cell.isStep) {
			placeStep();
		} else if (state.isRemoving) {
			removeAt(cell.x, cell.y, cell.z >= 0 ? cell.z : undefined);
		} else {
			placeAt(cell.x, cell.y);
		}

		// A finger has no hover, so the see-through brick goes away after a tap.
		state.hover = event.pointerType === 'mouse' ? state.hover : undefined;
		draw();
	});

	lego.on(canvas, 'keydown', event => {
		if (state.flight || event.metaKey || event.altKey) {
			return;
		}

		// The arrow keys move along the rows of studs as they look on the screen: right and left go along x, up and down along y.
		const moves = {ArrowRight: [1, 0], ArrowLeft: [-1, 0], ArrowDown: [0, 1], ArrowUp: [0, -1]};
		const lowerKey = event.key.toLowerCase();
		if (moves[event.key]) {
			event.preventDefault();
			const [x, y] = moves[event.key];
			state.cursor = {x: clamp(state.cursor.x + x, 0, size - 1), y: clamp(state.cursor.y + y, 0, size - 1)};
			state.usesKeyboard = true;
			draw();
		} else if (event.key === 'Enter' || event.key === ' ') {
			event.preventDefault();
			state.usesKeyboard = true;
			if (state.isRemoving) {
				removeAt(state.cursor.x, state.cursor.y);
			} else {
				placeAt(state.cursor.x, state.cursor.y);
			}
		} else if (event.key === 'Delete' || event.key === 'Backspace') {
			event.preventDefault();
			removeAt(state.cursor.x, state.cursor.y);
		} else if (lowerKey === 'r' && !event.ctrlKey) {
			event.preventDefault();
			actions.rotate();
		} else if (lowerKey === 'z' && (event.ctrlKey || !event.shiftKey)) {
			event.preventDefault();
			actions.undo();
		}
	});

	// Only a focus from the keyboard shows the brick at the cursor of the keyboard.
	lego.on(canvas, 'focus', () => {
		state.usesKeyboard = canvas.matches(':focus-visible');
		draw();
	});

	lego.on(canvas, 'blur', () => {
		state.usesKeyboard = false;
		draw();
	});

	// The blinking brick of the instructions needs frames, only while the instructions are open, and not with reduced motion.
	const blink = lego.loop(() => {
		draw();
	}, {while: () => state.step !== undefined && !lego.reducedMotion && !state.flight});

	selectPiece(state.piece);
	selectColor(state.color);
	rebuildGrid();
	rebuildPicking();
	draw();

	return draw;
};

export default class extends GeoCitiesElement {
	#draw;

	connected() {
		this.#draw = setUp(this, this.parts);
	}

	// The blinking brick of the instructions only blinks while the plate is on the screen.
	get visibilityTarget() {
		return this.parts.canvas;
	}

	reducedMotionChanged() {
		this.#draw();
	}
}
