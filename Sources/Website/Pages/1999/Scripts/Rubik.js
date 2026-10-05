// Pappa’s Rubik’s Cube from 1981 on the 1999 page: a real 3D cube on a canvas, which the visitor turns by dragging the faces or with the keys of the notation, scrambles, times, solves with the help of a layer-by-layer solver, and cheats on like every kid did: by peeling the stickers, or by taking it apart with a screwdriver. The canvas runs only while it is on the screen and the tab is visible. With reduced motion, nothing moves by itself: every turn happens at once. Nothing makes a sound until the visitor turns on the sound. The cube and the best times are kept in the browser.

// The position of a pointer on a canvas, in the pixels of the canvas.
const canvasPoint = (canvas, event) => {
	const rectangle = canvas.getBoundingClientRect();
	return {
		x: (event.clientX - rectangle.left) * canvas.width / rectangle.width,
		y: (event.clientY - rectangle.top) * canvas.height / rectangle.height,
	};
};

// A number between 0 and 1 that is always the same for the same seed, for the things that must not flicker, like the wear of the stickers.
const hash = seed => {
	const value = Math.sin(seed * 127.1 + 311.7) * 43_758.5453;
	return value - Math.floor(value);
};

// Vectors are arrays of three numbers, and matrices are arrays of nine numbers, row by row.
const add = (first, second) => [first[0] + second[0], first[1] + second[1], first[2] + second[2]];
const subtract = (first, second) => [first[0] - second[0], first[1] - second[1], first[2] - second[2]];
const scale = (vector, factor) => [vector[0] * factor, vector[1] * factor, vector[2] * factor];
const dot = (first, second) => (first[0] * second[0]) + (first[1] * second[1]) + (first[2] * second[2]);
const cross = (first, second) => [
	(first[1] * second[2]) - (first[2] * second[1]),
	(first[2] * second[0]) - (first[0] * second[2]),
	(first[0] * second[1]) - (first[1] * second[0]),
];
const negate = vector => [-vector[0], -vector[1], -vector[2]];
const isSameVector = (first, second) => first[0] === second[0] && first[1] === second[1] && first[2] === second[2];
const vectorLength = vector => Math.hypot(vector[0], vector[1], vector[2]);
const normalize = vector => scale(vector, 1 / (vectorLength(vector) || 1));

const identityMatrix = [1, 0, 0, 0, 1, 0, 0, 0, 1];

const multiplyMatrices = (first, second) => {
	const result = [];
	for (let row = 0; row < 3; row++) {
		for (let column = 0; column < 3; column++) {
			result.push((first[row * 3] * second[column]) + (first[(row * 3) + 1] * second[3 + column]) + (first[(row * 3) + 2] * second[6 + column]));
		}
	}

	return result;
};

const transform = (matrix, vector) => [
	(matrix[0] * vector[0]) + (matrix[1] * vector[1]) + (matrix[2] * vector[2]),
	(matrix[3] * vector[0]) + (matrix[4] * vector[1]) + (matrix[5] * vector[2]),
	(matrix[6] * vector[0]) + (matrix[7] * vector[1]) + (matrix[8] * vector[2]),
];

const transpose = matrix => [matrix[0], matrix[3], matrix[6], matrix[1], matrix[4], matrix[7], matrix[2], matrix[5], matrix[8]];

// A rotation about the x, y, or z axis (0, 1, or 2), counterclockwise when seen from the positive end of the axis.
const rotationMatrix = (axis, angle) => {
	const cosine = Math.cos(angle);
	const sine = Math.sin(angle);
	if (axis === 0) {
		return [1, 0, 0, 0, cosine, -sine, 0, sine, cosine];
	}

	if (axis === 1) {
		return [cosine, 0, sine, 0, 1, 0, -sine, 0, cosine];
	}

	return [cosine, -sine, 0, sine, cosine, 0, 0, 0, 1];
};

const rotateQuarters = (vector, axis, quarters) => transform(rotationMatrix(axis, quarters * Math.PI / 2), vector).map(value => Math.round(value) || 0);

// Matrices drift a bit after many small turns of the hand, so they are made straight again.
const orthonormalize = matrix => {
	const first = normalize([matrix[0], matrix[3], matrix[6]]);
	const second = normalize(subtract([matrix[1], matrix[4], matrix[7]], scale(first, dot(first, [matrix[1], matrix[4], matrix[7]]))));
	const third = cross(first, second);
	return [first[0], second[0], third[0], first[1], second[1], third[1], first[2], second[2], third[2]];
};

// Quaternions turn smoothly between two orientations, like when the pieces fall on the table.
const quaternionFromMatrix = matrix => {
	const [m00, m01, m02, m10, m11, m12, m20, m21, m22] = matrix;
	const trace = m00 + m11 + m22;
	if (trace > 0) {
		const factor = Math.sqrt(trace + 1) * 2;
		return [factor / 4, (m21 - m12) / factor, (m02 - m20) / factor, (m10 - m01) / factor];
	}

	if (m00 > m11 && m00 > m22) {
		const factor = Math.sqrt(1 + m00 - m11 - m22) * 2;
		return [(m21 - m12) / factor, factor / 4, (m01 + m10) / factor, (m02 + m20) / factor];
	}

	if (m11 > m22) {
		const factor = Math.sqrt(1 + m11 - m00 - m22) * 2;
		return [(m02 - m20) / factor, (m01 + m10) / factor, factor / 4, (m12 + m21) / factor];
	}

	const factor = Math.sqrt(1 + m22 - m00 - m11) * 2;
	return [(m10 - m01) / factor, (m02 + m20) / factor, (m12 + m21) / factor, factor / 4];
};

const matrixFromQuaternion = ([w, x, y, z]) => [
	1 - (2 * ((y * y) + (z * z))), 2 * ((x * y) - (z * w)), 2 * ((x * z) + (y * w)),
	2 * ((x * y) + (z * w)), 1 - (2 * ((x * x) + (z * z))), 2 * ((y * z) - (x * w)),
	2 * ((x * z) - (y * w)), 2 * ((y * z) + (x * w)), 1 - (2 * ((x * x) + (y * y))),
];

const slerp = (from, to, amount) => {
	let cosine = (from[0] * to[0]) + (from[1] * to[1]) + (from[2] * to[2]) + (from[3] * to[3]);
	let target = to;
	if (cosine < 0) {
		cosine = -cosine;
		target = to.map(value => -value);
	}

	if (cosine > 0.9995) {
		const mixed = from.map((value, index) => value + ((target[index] - value) * amount));
		const length = Math.hypot(...mixed);
		return mixed.map(value => value / length);
	}

	const angle = Math.acos(cosine);
	const sine = Math.sin(angle);
	const first = Math.sin((1 - amount) * angle) / sine;
	const second = Math.sin(amount * angle) / sine;
	return from.map((value, index) => (value * first) + (target[index] * second));
};

const interpolateMatrices = (from, to, amount) => matrixFromQuaternion(slerp(quaternionFromMatrix(from), quaternionFromMatrix(to), amount));

const easeInOut = amount => amount < 0.5 ? 2 * amount * amount : 1 - (((-2 * amount) + 2) ** 2 / 2);

// The model of the cube: 27 small cubes, the cubies, each with a position from −1 to 1 on each axis and the stickers on its outside. The x axis points to the right face, the y axis to the top face, and the z axis to the front face. A turn moves the positions and the directions of the stickers, so the model is right by construction.
const faceNames = ['U', 'R', 'F', 'D', 'L', 'B'];

// Each face, with the directions of its rows and columns as seen from outside, in the order of the standard facelet numbering.
const faceFrames = {
	U: {normal: [0, 1, 0], right: [1, 0, 0], down: [0, 0, 1]},
	R: {normal: [1, 0, 0], right: [0, 0, -1], down: [0, -1, 0]},
	F: {normal: [0, 0, 1], right: [1, 0, 0], down: [0, -1, 0]},
	D: {normal: [0, -1, 0], right: [1, 0, 0], down: [0, 0, -1]},
	L: {normal: [-1, 0, 0], right: [0, 0, 1], down: [0, -1, 0]},
	B: {normal: [0, 0, -1], right: [-1, 0, 0], down: [0, -1, 0]},
};

// The colors of the cube from 1981: white opposite yellow, red opposite orange, and green opposite blue.
const homeColors = {U: 'white', R: 'red', F: 'green', D: 'yellow', L: 'orange', B: 'blue'};
const oppositeColors = {white: 'yellow', yellow: 'white', red: 'orange', orange: 'red', green: 'blue', blue: 'green'};

const createCube = () => {
	const cubies = [];
	for (let x = -1; x <= 1; x++) {
		for (let y = -1; y <= 1; y++) {
			for (let z = -1; z <= 1; z++) {
				const position = [x, y, z];
				const stickers = faceNames
					.filter(face => dot(position, faceFrames[face].normal) === 1)
					.map(face => ({
						normal: faceFrames[face].normal,
						homeNormal: faceFrames[face].normal,
						// Which way is right on the sticker, so the logo turns with its face.
						right: faceFrames[face].right,
						homeRight: faceFrames[face].right,
						color: homeColors[face],
						original: homeColors[face],
						isLogo: face === 'U' && x === 0 && z === 0,
					}));
				const kind = ['core', 'center', 'edge', 'corner'][Math.abs(x) + Math.abs(y) + Math.abs(z)];
				cubies.push({id: cubies.length, home: position, position, stickers, kind});
			}
		}
	}

	return cubies;
};

const cloneCube = cubies => cubies.map(cubie => ({...cubie, stickers: cubie.stickers.map(sticker => ({...sticker}))}));

// A move turns the layers at the given positions on one axis, a number of quarter turns, counterclockwise when seen from the positive end of the axis.
const applyMove = (cubies, move) => {
	for (const cubie of cubies) {
		if (move.layers.includes(cubie.position[move.axis])) {
			cubie.position = rotateQuarters(cubie.position, move.axis, move.quarters);
			for (const sticker of cubie.stickers) {
				sticker.normal = rotateQuarters(sticker.normal, move.axis, move.quarters);
				sticker.right = rotateQuarters(sticker.right, move.axis, move.quarters);
			}
		}
	}
};

// The notation of the letters. A frame says where the right, the top, and the front face are, so “R” always turns the face that is on the right as the visitor holds the cube.
const homeFrame = {R: [1, 0, 0], U: [0, 1, 0], F: [0, 0, 1]};

const letters = {
	R: {kind: 'face', direction: frame => frame.R},
	L: {kind: 'face', direction: frame => negate(frame.R)},
	U: {kind: 'face', direction: frame => frame.U},
	D: {kind: 'face', direction: frame => negate(frame.U)},
	F: {kind: 'face', direction: frame => frame.F},
	B: {kind: 'face', direction: frame => negate(frame.F)},
	M: {kind: 'slice', direction: frame => negate(frame.R)},
	E: {kind: 'slice', direction: frame => negate(frame.U)},
	S: {kind: 'slice', direction: frame => frame.F},
	x: {kind: 'rotation', direction: frame => frame.R},
	y: {kind: 'rotation', direction: frame => frame.U},
	z: {kind: 'rotation', direction: frame => frame.F},
	r: {kind: 'wide', direction: frame => frame.R},
	l: {kind: 'wide', direction: frame => negate(frame.R)},
	u: {kind: 'wide', direction: frame => frame.U},
	d: {kind: 'wide', direction: frame => negate(frame.U)},
	f: {kind: 'wide', direction: frame => frame.F},
	b: {kind: 'wide', direction: frame => negate(frame.F)},
};

const layersOf = (kind, sign) => {
	if (kind === 'face') {
		return [sign];
	}

	if (kind === 'slice') {
		return [0];
	}

	if (kind === 'wide') {
		return [sign, 0];
	}

	return [-1, 0, 1];
};

const tokenName = ({letter, turns}) => `${letter}${Math.abs(turns) === 2 ? '2' : ''}${turns < 0 ? '’' : ''}`;

const moveFromToken = (token, frame = homeFrame) => {
	const {kind, direction} = letters[token.letter];
	const vector = direction(frame);
	const axis = vector.findIndex(value => value !== 0);
	const sign = vector[axis];
	return {axis, layers: layersOf(kind, sign), quarters: -sign * token.turns, name: tokenName(token), isRotation: kind === 'rotation'};
};

const sameLayers = (first, second) => first.length === second.length && first.every(layer => second.includes(layer));

// The name of a move that the visitor made by dragging, as seen from how the cube is held.
const nameOfMove = (move, frame) => {
	for (const [letter, {kind, direction}] of Object.entries(letters)) {
		const vector = direction(frame);
		const axis = vector.findIndex(value => value !== 0);
		const sign = vector[axis];
		if (axis === move.axis && sameLayers(layersOf(kind, sign), move.layers)) {
			const turns = move.quarters / -sign;
			return tokenName({letter, turns: turns === 3 ? -1 : (turns === -3 ? 1 : turns)});
		}
	}

	return '?';
};

const inverseMove = move => ({...move, quarters: -move.quarters, name: invertName(move.name)});

const invertName = name => name.endsWith('’') ? name.slice(0, -1) : `${name}’`;

const primes = new Set(['\'', '’', '′', '`', '´']);
const maximumTokens = 400;

// Reads an algorithm, like “R U R’ U’” or “(R U R’ U’)6”, one character at a time, so a long text cannot make it slow.
const parseAlgorithm = text => {
	const characters = [...text];
	let index = 0;

	const readCount = () => {
		let digits = '';
		while (index < characters.length && characters[index] >= '0' && characters[index] <= '9' && digits.length < 3) {
			digits += characters[index];
			index++;
		}

		return digits === '' ? undefined : Number(digits);
	};

	const parseSequence = depth => {
		const tokens = [];
		while (index < characters.length) {
			const character = characters[index];
			if (character.trim() === '' || character === ',' || character === '.') {
				index++;
			} else if (character === '(' || character === '[') {
				if (depth >= 3) {
					throw new SyntaxError('That has too many parentheses inside parentheses.');
				}

				index++;
				const inner = parseSequence(depth + 1);
				if (characters[index] !== ')' && characters[index] !== ']') {
					throw new SyntaxError('A “(” has no “)”.');
				}

				index++;
				const count = readCount() ?? 1;
				let group = inner;
				if (primes.has(characters[index])) {
					index++;
					group = inner.toReversed().map(token => ({...token, turns: -token.turns}));
				}

				for (let repeat = 0; repeat < count && tokens.length <= maximumTokens; repeat++) {
					tokens.push(...group);
				}
			} else if (character === ')' || character === ']') {
				if (depth === 0) {
					throw new SyntaxError('A “)” has no “(”.');
				}

				return tokens;
			} else if (Object.hasOwn(letters, character)) {
				index++;
				let letter = character;
				if (characters[index] === 'w' && letters[character].kind === 'face') {
					letter = character.toLowerCase();
					index++;
				}

				let turns = (readCount() ?? 1) % 4;
				if (primes.has(characters[index])) {
					index++;
					turns = -turns;
				}

				if (Math.abs(turns) === 3) {
					turns = -Math.sign(turns);
				}

				if (turns !== 0) {
					tokens.push({letter, turns});
				}
			} else {
				throw new SyntaxError(`There is no move called “${character}” on a Rubik’s Cube.`);
			}

			if (tokens.length > maximumTokens) {
				throw new SyntaxError(`That is more than ${maximumTokens} moves. Even Pappa would get bored.`);
			}
		}

		if (depth > 0) {
			throw new SyntaxError('A “(” has no “)”.');
		}

		return tokens;
	};

	return parseSequence(0);
};

const positionKey = position => position.join();

// The 54 stickers, face by face in the order U, R, F, D, L, B, and on each face row by row as seen from outside.
const readFacelets = cubies => {
	const byPosition = new Map(cubies.map(cubie => [positionKey(cubie.position), cubie]));
	const facelets = [];
	for (const face of faceNames) {
		const {normal, right, down} = faceFrames[face];
		for (let row = 0; row < 3; row++) {
			for (let column = 0; column < 3; column++) {
				const position = add(add(normal, scale(right, column - 1)), scale(down, row - 1));
				facelets.push(byPosition.get(positionKey(position))?.stickers.find(sticker => isSameVector(sticker.normal, normal)));
			}
		}
	}

	return facelets;
};

const looksSolved = cubies => {
	const facelets = readFacelets(cubies);
	return faceNames.every((face, faceIndex) => facelets.slice(faceIndex * 9, (faceIndex * 9) + 9).every(sticker => sticker?.color === facelets[(faceIndex * 9) + 4]?.color));
};

const movedStickerCount = cubies => cubies.flatMap(cubie => cubie.stickers).filter(sticker => sticker.color !== sticker.original).length;

// The cube as the solver sees it, with the numbering of Herbert Kociemba: the corners URF, UFL, ULB, UBR, DFR, DLF, DBL, DRB and the edges UR, UF, UL, UB, DR, DF, DL, DB, FR, FL, BL, BR, each with the piece that is there and how it is twisted or flipped.
const [faceU, faceR, faceF, faceD, faceL, faceB] = [0, 1, 2, 3, 4, 5];
const facelet = (face, number) => (face * 9) + number - 1;

const cornerFacelets = [
	[facelet(faceU, 9), facelet(faceR, 1), facelet(faceF, 3)],
	[facelet(faceU, 7), facelet(faceF, 1), facelet(faceL, 3)],
	[facelet(faceU, 1), facelet(faceL, 1), facelet(faceB, 3)],
	[facelet(faceU, 3), facelet(faceB, 1), facelet(faceR, 3)],
	[facelet(faceD, 3), facelet(faceF, 9), facelet(faceR, 7)],
	[facelet(faceD, 1), facelet(faceL, 9), facelet(faceF, 7)],
	[facelet(faceD, 7), facelet(faceB, 9), facelet(faceL, 7)],
	[facelet(faceD, 9), facelet(faceR, 9), facelet(faceB, 7)],
];

const edgeFacelets = [
	[facelet(faceU, 6), facelet(faceR, 2)],
	[facelet(faceU, 8), facelet(faceF, 2)],
	[facelet(faceU, 4), facelet(faceL, 2)],
	[facelet(faceU, 2), facelet(faceB, 2)],
	[facelet(faceD, 6), facelet(faceR, 8)],
	[facelet(faceD, 2), facelet(faceF, 8)],
	[facelet(faceD, 4), facelet(faceL, 8)],
	[facelet(faceD, 8), facelet(faceB, 8)],
	[facelet(faceF, 6), facelet(faceR, 4)],
	[facelet(faceF, 4), facelet(faceL, 6)],
	[facelet(faceB, 6), facelet(faceL, 4)],
	[facelet(faceB, 4), facelet(faceR, 6)],
];

const cornerFaces = [[faceU, faceR, faceF], [faceU, faceF, faceL], [faceU, faceL, faceB], [faceU, faceB, faceR], [faceD, faceF, faceR], [faceD, faceL, faceF], [faceD, faceB, faceL], [faceD, faceR, faceB]];
const edgeFaces = [[faceU, faceR], [faceU, faceF], [faceU, faceL], [faceU, faceB], [faceD, faceR], [faceD, faceF], [faceD, faceL], [faceD, faceB], [faceF, faceR], [faceF, faceL], [faceB, faceL], [faceB, faceR]];

const isOddPermutation = permutation => {
	let inversions = 0;
	for (let first = 0; first < permutation.length; first++) {
		for (let second = first + 1; second < permutation.length; second++) {
			if (permutation[first] > permutation[second]) {
				inversions++;
			}
		}
	}

	return inversions % 2 === 1;
};

// Reads the colors as pieces, relative to the centers, and tells what is wrong if the stickers cannot be on a real cube, like after a visitor moved the stickers. A real cube can only be solved if no corner is twisted alone, no edge is flipped alone, and no two pieces are swapped alone.
const analyzeCube = cubies => {
	const colors = readFacelets(cubies).map(sticker => sticker?.color);
	if (colors.includes(undefined)) {
		return {problem: 'it is not in one piece'};
	}

	const centers = faceNames.map((face, index) => colors[(index * 9) + 4]);
	if (new Set(centers).size !== 6) {
		return {problem: 'two centers have the same color'};
	}

	const homeCornerColors = cornerFaces.map(faces => faces.map(face => homeColors[faceNames[face]]));
	const isRealCorner = triple => homeCornerColors.some(corner => [0, 1, 2].some(shift => corner.every((color, index) => color === triple[(index + shift) % 3])));
	if (oppositeColors[centers[faceU]] !== centers[faceD] || oppositeColors[centers[faceR]] !== centers[faceL] || oppositeColors[centers[faceF]] !== centers[faceB] || !isRealCorner([centers[faceU], centers[faceR], centers[faceF]])) {
		return {problem: 'the centers are in the wrong places'};
	}

	const faceOfColor = new Map(centers.map((color, index) => [color, index]));
	const faces = colors.map(color => faceOfColor.get(color));
	const state = {cp: [], co: [], ep: [], eo: []};

	for (const facelets of cornerFacelets) {
		const pieceFaces = facelets.map(index => faces[index]);
		const orientation = pieceFaces.findIndex(face => face === faceU || face === faceD);
		const piece = orientation === -1 ? -1 : cornerFaces.findIndex(corner => corner[0] === pieceFaces[orientation] && corner[1] === pieceFaces[(orientation + 1) % 3] && corner[2] === pieceFaces[(orientation + 2) % 3]);
		if (piece === -1) {
			return {problem: `a corner has ${pieceFaces.map(face => centers[face]).join(', ')}, and no real corner has that`};
		}

		state.cp.push(piece);
		state.co.push(orientation);
	}

	for (const facelets of edgeFacelets) {
		const pieceFaces = facelets.map(index => faces[index]);
		let piece = edgeFaces.findIndex(edge => edge[0] === pieceFaces[0] && edge[1] === pieceFaces[1]);
		let orientation = 0;
		if (piece === -1) {
			piece = edgeFaces.findIndex(edge => edge[0] === pieceFaces[1] && edge[1] === pieceFaces[0]);
			orientation = 1;
		}

		if (piece === -1) {
			return {problem: `an edge has ${pieceFaces.map(face => centers[face]).join(' and ')}, and no real edge has that`};
		}

		state.ep.push(piece);
		state.eo.push(orientation);
	}

	if (new Set(state.cp).size !== 8) {
		return {problem: 'it has two of the same corner'};
	}

	if (new Set(state.ep).size !== 12) {
		return {problem: 'it has two of the same edge'};
	}

	let twist = 0;
	for (const orientation of state.co) {
		twist += orientation;
	}

	if (twist % 3 !== 0) {
		return {problem: 'one corner is twisted'};
	}

	let flip = 0;
	for (const orientation of state.eo) {
		flip += orientation;
	}

	if (flip % 2 !== 0) {
		return {problem: 'one edge is flipped'};
	}

	if (isOddPermutation(state.cp) !== isOddPermutation(state.ep)) {
		return {problem: 'two pieces are swapped'};
	}

	return {state};
};

// The six turns of the faces in the numbering of the solver.
const zeros = length => Array.from({length}, () => 0);
const basicMoves = {
	U: {cp: [3, 0, 1, 2, 4, 5, 6, 7], co: zeros(8), ep: [3, 0, 1, 2, 4, 5, 6, 7, 8, 9, 10, 11], eo: zeros(12)},
	R: {cp: [4, 1, 2, 0, 7, 5, 6, 3], co: [2, 0, 0, 1, 1, 0, 0, 2], ep: [8, 1, 2, 3, 11, 5, 6, 7, 4, 9, 10, 0], eo: zeros(12)},
	F: {cp: [1, 5, 2, 3, 0, 4, 6, 7], co: [1, 2, 0, 0, 2, 1, 0, 0], ep: [0, 9, 2, 3, 4, 8, 6, 7, 1, 5, 10, 11], eo: [0, 1, 0, 0, 0, 1, 0, 0, 1, 1, 0, 0]},
	D: {cp: [0, 1, 2, 3, 5, 6, 7, 4], co: zeros(8), ep: [0, 1, 2, 3, 5, 6, 7, 4, 8, 9, 10, 11], eo: zeros(12)},
	L: {cp: [0, 2, 6, 3, 4, 1, 5, 7], co: [0, 1, 2, 0, 0, 2, 1, 0], ep: [0, 1, 10, 3, 4, 5, 9, 7, 8, 2, 6, 11], eo: zeros(12)},
	B: {cp: [0, 1, 3, 7, 4, 5, 2, 6], co: [0, 0, 1, 2, 0, 0, 2, 1], ep: [0, 1, 2, 11, 4, 5, 6, 10, 8, 9, 3, 7], eo: [0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 1, 1]},
};

const identityState = {cp: [0, 1, 2, 3, 4, 5, 6, 7], co: zeros(8), ep: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11], eo: zeros(12)};

const multiplyStates = (state, move) => ({
	cp: move.cp.map(from => state.cp[from]),
	co: move.cp.map((from, index) => (state.co[from] + move.co[index]) % 3),
	ep: move.ep.map(from => state.ep[from]),
	eo: move.ep.map((from, index) => (state.eo[from] + move.eo[index]) % 2),
});

const solverMoves = new Map();
for (const face of ['U', 'R', 'F', 'D', 'L', 'B']) {
	const once = basicMoves[face];
	const twice = multiplyStates(once, once);
	solverMoves.set(face, once);
	solverMoves.set(`${face}2`, twice);
	solverMoves.set(`${face}’`, multiplyStates(twice, once));
}

const composeMoves = names => {
	let state = identityState;
	for (const name of names) {
		state = multiplyStates(state, solverMoves.get(name));
	}

	return state;
};

const words = text => text.split(' ').filter(Boolean);

// Turns an algorithm so it works on another side of the cube, by the letters of the faces, like holding the cube turned.
const mapFaces = (moves, mapping) => moves.map(move => `${mapping[move[0]]}${move.slice(1)}`);
const turnedLeft = {F: 'R', R: 'B', B: 'L', L: 'F', U: 'U', D: 'D'};
const upsideDown = {U: 'D', D: 'U', F: 'B', B: 'F', R: 'R', L: 'L'};

// The four versions of an algorithm, one for each side of the cube.
const aroundTheCube = algorithm => {
	const versions = [words(algorithm)];
	for (let index = 1; index < 4; index++) {
		versions.push(mapFaces(versions.at(-1), turnedLeft));
	}

	return versions;
};

// Joins the turns of the same face that come one after the other, like “U U” to “U2”, and takes away the ones that cancel.
const simplifyMoves = moves => {
	const amounts = {'': 1, 2: 2, '’': 3};
	const result = [];
	for (const move of moves) {
		const previous = result.at(-1);
		if (previous?.[0] === move[0]) {
			result.pop();
			const total = (amounts[previous.slice(1)] + amounts[move.slice(1)]) % 4;
			if (total !== 0) {
				result.push(`${move[0]}${['', '', '2', '’'][total]}`);
			}
		} else {
			result.push(move);
		}
	}

	return result;
};

const isEdgeSolved = (state, edge) => state.ep[edge] === edge && state.eo[edge] === 0;
const isCornerSolved = (state, corner) => state.cp[corner] === corner && state.co[corner] === 0;

// How many turns each edge needs to get home on its own, for all of its 24 places, which guides the search for the cross.
const edgeDistances = Array.from({length: 12}, (_, target) => {
	const distances = Array.from({length: 24}, () => -1);
	distances[target * 2] = 0;
	let frontier = [target * 2];
	let distance = 0;
	while (frontier.length > 0) {
		distance++;
		const next = [];
		for (const place of frontier) {
			const position = Math.floor(place / 2);
			const orientation = place % 2;
			for (const move of solverMoves.values()) {
				const newPosition = move.ep.indexOf(position);
				const newPlace = (newPosition * 2) + ((orientation + move.eo[newPosition]) % 2);
				if (distances[newPlace] === -1) {
					distances[newPlace] = distance;
					next.push(newPlace);
				}
			}
		}

		frontier = next;
	}

	return distances;
});

const oppositeFaces = {U: 'D', D: 'U', R: 'L', L: 'R', F: 'B', B: 'F'};
const faceOrder = 'URFDLB';

// The cross on the bottom, one edge at a time, with a search that is guided by how far each edge is from home.
const solveCrossEdge = (start, edges) => {
	const heuristic = state => {
		let maximum = 0;
		for (const edge of edges) {
			const position = state.ep.indexOf(edge);
			maximum = Math.max(maximum, edgeDistances[edge][(position * 2) + state.eo[position]]);
		}

		return maximum;
	};

	const path = [];
	const search = (state, depth, lastFace) => {
		const estimate = heuristic(state);
		if (estimate === 0) {
			return true;
		}

		if (estimate > depth) {
			return false;
		}

		for (const [name, move] of solverMoves) {
			const face = name[0];
			if (face === lastFace || (oppositeFaces[face] === lastFace && faceOrder.indexOf(face) < faceOrder.indexOf(lastFace))) {
				continue;
			}

			path.push(name);
			if (search(multiplyStates(state, move), depth - 1, face)) {
				return true;
			}

			path.pop();
		}

		return false;
	};

	for (let depth = 0; depth <= 10; depth++) {
		if (search(start, depth, '')) {
			return path;
		}
	}

	return undefined;
};

// A search over a few algorithms and turns of the top, like a person who knows the algorithms of the booklet.
const solveWithAlgorithms = (start, algorithms, isDone, maximumDepth) => {
	if (isDone(start)) {
		return [];
	}

	const macros = algorithms.map(moves => ({moves, state: composeMoves(moves), isTopTurn: moves.length === 1 && moves[0][0] === 'U'}));
	const path = [];
	const search = (state, depth, wasTopTurn) => {
		for (const macro of macros) {
			if (macro.isTopTurn && wasTopTurn) {
				continue;
			}

			const next = multiplyStates(state, macro.state);
			path.push(macro.moves);
			if (depth === 1 ? isDone(next) : search(next, depth - 1, macro.isTopTurn)) {
				return true;
			}

			path.pop();
		}

		return false;
	};

	for (let depth = 1; depth <= maximumDepth; depth++) {
		if (search(start, depth, false)) {
			return path.flat();
		}
	}

	return undefined;
};

const topTurns = [['U'], ['U2'], ['U’']];
const repeated = (moves, count) => Array.from({length: count}, () => moves).flat();

// The layer-by-layer method of the booklet. The cross and the corners of the first layer are made on the top, where the visitor can see them, then the cube is turned over, and the rest is solved with the yellow side up. The steps are found on the cube with the white side down, and turned upside down for the first two steps.
const solveCube = cubies => {
	const analysis = analyzeCube(cubies);
	if (analysis.problem) {
		return {problem: analysis.problem};
	}

	const holding = ['', 'x', 'x’', 'x2', 'z', 'z’'].find(rotation => {
		const turned = cloneCube(cubies);
		for (const token of parseAlgorithm(rotation)) {
			applyMove(turned, moveFromToken(token));
		}

		return readFacelets(turned)[4].color === 'white';
	});
	const turned = cloneCube(cubies);
	for (const token of parseAlgorithm(`${holding} x2`)) {
		applyMove(turned, moveFromToken(token));
	}

	let state = analyzeCube(turned).state;
	const steps = [];
	const addStep = (title, moves, transformMoves = moves => moves) => {
		const simplified = simplifyMoves(moves);
		for (const move of simplified) {
			state = multiplyStates(state, solverMoves.get(move));
		}

		steps.push({title, moves: transformMoves(simplified)});
	};

	if (holding) {
		steps.push({title: 'Hold the cube with the white center on top', moves: [holding]});
	}

	const crossMoves = [];
	const crossEdges = [];
	for (const edge of [5, 4, 7, 6]) {
		crossEdges.push(edge);
		const moves = solveCrossEdge(multiplyStates(state, composeMoves(crossMoves)), crossEdges);
		crossMoves.push(...moves);
	}

	addStep('The white cross', crossMoves, moves => mapFaces(moves, upsideDown));

	const sexyMoves = aroundTheCube('R U R’ U’');
	const cornerMoves = [];
	const solvedCorners = [];
	for (const corner of [4, 5, 6, 7]) {
		solvedCorners.push(corner);
		const algorithms = [...topTurns, ...sexyMoves.flatMap(moves => [1, 2, 3, 4, 5].map(count => repeated(moves, count)))];
		const isDone = candidate => [4, 5, 6, 7].every(edge => isEdgeSolved(candidate, edge)) && solvedCorners.every(solved => isCornerSolved(candidate, solved));
		const moves = solveWithAlgorithms(multiplyStates(state, composeMoves(cornerMoves)), algorithms, isDone, 4);
		if (!moves) {
			return {problem: 'the solver got confused at the white corners'};
		}

		cornerMoves.push(...moves);
	}

	addStep('The white corners', cornerMoves, moves => mapFaces(moves, upsideDown));
	steps.push({title: 'Turn the cube over, yellow on top', moves: ['x2']});

	const isFirstLayerDone = candidate => [4, 5, 6, 7].every(piece => isEdgeSolved(candidate, piece) && isCornerSolved(candidate, piece));
	const middleAlgorithms = [...topTurns, ...aroundTheCube('U R U’ R’ U’ F’ U F'), ...aroundTheCube('U’ L’ U L U F U’ F’')];
	const middleMoves = [];
	const solvedEdges = [];
	for (const edge of [8, 9, 10, 11]) {
		solvedEdges.push(edge);
		const isDone = candidate => isFirstLayerDone(candidate) && solvedEdges.every(solved => isEdgeSolved(candidate, solved));
		const moves = solveWithAlgorithms(multiplyStates(state, composeMoves(middleMoves)), middleAlgorithms, isDone, 5);
		if (!moves) {
			return {problem: 'the solver got confused at the middle layer'};
		}

		middleMoves.push(...moves);
	}

	addStep('The middle layer', middleMoves);

	const isTwoLayersDone = candidate => isFirstLayerDone(candidate) && [8, 9, 10, 11].every(edge => isEdgeSolved(candidate, edge));
	const isYellowCrossDone = candidate => isTwoLayersDone(candidate) && [0, 1, 2, 3].every(edge => candidate.eo[edge] === 0);
	const yellowCross = solveWithAlgorithms(state, [...topTurns, words('F R U R’ U’ F’'), words('F U R U’ R’ F’')], isYellowCrossDone, 6);
	if (!yellowCross) {
		return {problem: 'the solver got confused at the yellow cross'};
	}

	addStep('The yellow cross', yellowCross);

	const areYellowEdgesDone = candidate => isYellowCrossDone(candidate) && [0, 1, 2, 3].every(edge => candidate.ep[edge] === edge);
	const yellowEdges = solveWithAlgorithms(state, [...topTurns, ...aroundTheCube('R U R’ U R U2 R’ U')], areYellowEdgesDone, 6);
	if (!yellowEdges) {
		return {problem: 'the solver got confused at the yellow edges'};
	}

	addStep('The yellow edges', yellowEdges);

	const areCornersPlaced = candidate => areYellowEdgesDone(candidate) && [0, 1, 2, 3].every(corner => candidate.cp[corner] === corner);
	const cornerCycles = [...aroundTheCube('U R U’ L’ U R’ U’ L'), ...aroundTheCube('L’ U R U’ L U R’ U’')];
	const placedCorners = solveWithAlgorithms(state, cornerCycles, areCornersPlaced, 3);
	if (!placedCorners) {
		return {problem: 'the solver got confused at the yellow corners'};
	}

	addStep('The yellow corners in their places', placedCorners);

	// The last step of the booklet: R’ D’ R D on the corner in front on the right until it is yellow on top, and U for the next corner. The bottom looks broken in between, and comes back at the end.
	const twistMoves = [];
	let twisted = state;
	for (let corner = 0; corner < 4; corner++) {
		for (let attempt = 0; attempt < 2 && twisted.co[0] !== 0; attempt++) {
			const moves = repeated(words('R’ D’ R D'), 2);
			twistMoves.push(...moves);
			twisted = multiplyStates(twisted, composeMoves(moves));
		}

		twistMoves.push('U');
		twisted = multiplyStates(twisted, solverMoves.get('U'));
	}

	addStep('Twist the yellow corners', twistMoves);

	const isSolved = state.cp.every((piece, index) => piece === index) && state.co.every(orientation => orientation === 0) && state.ep.every((piece, index) => piece === index) && state.eo.every(orientation => orientation === 0);
	if (!isSolved) {
		return {problem: 'the solver got confused at the end'};
	}

	return {steps: steps.filter(step => step.moves.length > 0)};
};

// The drawing: the cube is 3 units wide, at the middle of the world, and seen from a camera in front of it. The x axis of the world points right, y up, and z to the viewer.
const width = 720;
const height = 540;
const cameraDistance = 14;
const focal = 940;
const screenCenter = {x: 360, y: 245};
const tableHeight = -3.4;
const cameraPosition = [0, 0, cameraDistance];
const light = normalize([-0.35, 0.75, 0.7]);
const shine = normalize(add(light, [0, 0, 1]));
const halfSize = 0.5;
const stickerSize = 0.41;

// The colors of the stickers of 1981, a bit faded after 18 years on the shelf in the sun.
const palette = {
	white: [236, 233, 220],
	yellow: [246, 206, 24],
	red: [190, 24, 40],
	orange: [246, 112, 26],
	green: [16, 146, 72],
	blue: [16, 72, 168],
};

const directions = [[1, 0, 0], [-1, 0, 0], [0, 1, 0], [0, -1, 0], [0, 0, 1], [0, 0, -1]];
const homeView = multiplyMatrices(rotationMatrix(0, 0.55), rotationMatrix(1, -0.72));

const project = point => {
	const depth = cameraDistance - point[2];
	return {x: screenCenter.x + (focal * point[0] / depth), y: screenCenter.y - (focal * point[1] / depth)};
};

const distanceToCamera = point => vectorLength(subtract(cameraPosition, point));

const roundVector = vector => vector.map(value => Math.round(value) || 0);

// The 24 ways a cube can lie, as rotations.
const rotations = (() => {
	const generators = [rotationMatrix(0, Math.PI / 2), rotationMatrix(1, Math.PI / 2)].map(matrix => matrix.map(value => Math.round(value) || 0));
	const found = [identityMatrix];
	for (let index = 0; index < found.length; index++) {
		for (const generator of generators) {
			const candidate = multiplyMatrices(generator, found[index]).map(value => Math.round(value) || 0);
			if (!found.some(matrix => matrix.every((value, place) => value === candidate[place]))) {
				found.push(candidate);
			}
		}
	}

	return found;
})();

// The rotation that a piece has now, compared to how it was in the shop.
const rotationOfCubie = cubie => rotations.find(rotation => isSameVector(roundVector(transform(rotation, cubie.home)), cubie.position) && cubie.stickers.every(sticker => isSameVector(roundVector(transform(rotation, sticker.homeNormal)), sticker.normal) && isSameVector(roundVector(transform(rotation, sticker.homeRight)), sticker.right)));

const randomItem = items => items[Math.floor(Math.random() * items.length)];

const shuffled = items => {
	const result = [...items];
	for (let index = result.length - 1; index > 0; index--) {
		const other = Math.floor(Math.random() * (index + 1));
		[result[index], result[other]] = [result[other], result[index]];
	}

	return result;
};

// Pappa’s scramble from 1981, which has been on the shelf since.
const pappasScramble = 'F2 U’ R2 D B’ L2 U R’ F D2 L’ B2 U’ F2 R D’ L B U2 R2 F’ D L2 B’';

const isHomeLogo = (cubie, sticker) => cubie.kind === 'center' && sticker.original === 'white';

const isVector = value => Array.isArray(value) && value.length === 3;

// A saved piece is only used if a real turn of the piece puts it there, so broken data cannot draw a piece outside the cube.
const restoreCube = saved => {
	const cube = createCube();
	if (!Array.isArray(saved) || saved.length !== cube.length) {
		return undefined;
	}

	for (const [index, cubie] of cube.entries()) {
		const item = saved[index];
		if (!isVector(item?.position) || !Array.isArray(item.stickers) || item.stickers.length !== cubie.stickers.length) {
			return undefined;
		}

		cubie.position = item.position;
		for (const [place, sticker] of cubie.stickers.entries()) {
			const savedSticker = item.stickers[place];
			if (!isVector(savedSticker?.normal) || !isVector(savedSticker.right) || !Object.hasOwn(palette, savedSticker.color)) {
				return undefined;
			}

			Object.assign(sticker, {normal: savedSticker.normal, right: savedSticker.right, color: savedSticker.color, isLogo: savedSticker.isLogo === true});
		}

		if (!rotationOfCubie(cubie)) {
			return undefined;
		}
	}

	return new Set(cube.map(cubie => cubie.position.join())).size === cube.length ? cube : undefined;
};

const formatTime = milliseconds => {
	const totalHundredths = Math.floor(milliseconds / 10);
	const minutes = Math.floor(totalHundredths / 6000);
	const seconds = Math.floor(totalHundredths / 100) % 60;
	const hundredths = totalHundredths % 100;
	return `${minutes}:${String(seconds).padStart(2, '0')}.${String(hundredths).padStart(2, '0')}`;
};

const highlighted = {
	cross: cubie => cubie.kind === 'edge' && cubie.home[1] === 1,
	corners: cubie => cubie.kind === 'corner' && cubie.home[1] === 1,
	middle: cubie => cubie.kind === 'edge' && cubie.home[1] === 0,
	yellowCross: cubie => cubie.kind === 'edge' && cubie.home[1] === -1,
	yellowCorners: cubie => cubie.kind === 'corner' && cubie.home[1] === -1,
};

// How many stickers match the center of their face, to tell whether Pappa made it better or worse.
const matchingStickers = cubies => {
	const facelets = readFacelets(cubies);
	return facelets.filter((sticker, index) => sticker?.color === facelets[(Math.floor(index / 9) * 9) + 4]?.color).length;
};

// The drawing of the room: the striped wallpaper, the window with the rain of Bergen, and the table of teak.
const drawRoom = context => {
	const wall = context.createLinearGradient(0, 0, 0, 380);
	wall.addColorStop(0, '#34416a');
	wall.addColorStop(1, '#232c4a');
	context.fillStyle = wall;
	context.fillRect(0, 0, width, height);
	context.fillStyle = 'rgba(255, 255, 255, 0.035)';
	for (let x = 0; x < width; x += 36) {
		context.fillRect(x, 0, 14, height);
	}

	// The window, with rain.
	context.fillStyle = '#e8e2d0';
	context.fillRect(590, 26, 112, 150);
	const sky = context.createLinearGradient(0, 34, 0, 168);
	sky.addColorStop(0, '#7d8a99');
	sky.addColorStop(1, '#a9b3bd');
	context.fillStyle = sky;
	context.fillRect(598, 34, 96, 134);
	context.strokeStyle = 'rgba(230, 240, 255, 0.55)';
	context.lineWidth = 1;
	context.beginPath();
	for (let index = 0; index < 26; index++) {
		const x = 600 + (hash(index) * 90);
		const y = 36 + (hash(index + 50) * 120);
		context.moveTo(x, y);
		context.lineTo(x - 3, y + 10);
	}

	context.stroke();
	context.fillStyle = '#e8e2d0';
	context.fillRect(644, 34, 5, 134);
	context.fillRect(598, 98, 96, 5);

	// The table, from the back edge to the bottom of the picture.
	const back = -7;
	const front = 4;
	const corners = [[-16, tableHeight, back], [16, tableHeight, back], [16, tableHeight, front], [-16, tableHeight, front]].map(point => project(point));
	const wood = context.createLinearGradient(0, corners[0].y, 0, height);
	wood.addColorStop(0, '#6b4024');
	wood.addColorStop(1, '#94603a');
	context.fillStyle = wood;
	context.beginPath();
	context.moveTo(corners[0].x, corners[0].y);
	for (const corner of corners.slice(1)) {
		context.lineTo(corner.x, corner.y);
	}

	context.closePath();
	context.fill();
	context.strokeStyle = 'rgba(40, 20, 8, 0.25)';
	context.beginPath();
	for (let x = -15; x <= 15; x += 1.1) {
		const from = project([x + (hash(x) * 0.4), tableHeight, back]);
		const to = project([x + (hash(x + 9) * 0.4), tableHeight, front]);
		context.moveTo(from.x, from.y);
		context.lineTo(to.x, to.y);
	}

	context.stroke();
	context.fillStyle = '#4a2a14';
	context.fillRect(0, corners[0].y - 4, width, 5);
	context.fillStyle = 'rgba(255, 220, 170, 0.25)';
	context.fillRect(0, corners[0].y + 1, width, 2);
};

const drawShadow = context => {
	const point = project([0, tableHeight, 0]);
	const radius = focal * 2.1 / cameraDistance;
	context.save();
	context.translate(point.x, point.y);
	context.scale(1, 0.22);
	const shadow = context.createRadialGradient(0, 0, 0, 0, 0, radius);
	shadow.addColorStop(0, 'rgba(0, 0, 0, 0.5)');
	shadow.addColorStop(1, 'rgba(0, 0, 0, 0)');
	context.fillStyle = shadow;
	context.beginPath();
	context.arc(0, 0, radius, 0, Math.PI * 2);
	context.fill();
	context.restore();
};

// The screwdriver from Pappa’s toolbox, on the table while the cube is in pieces.
const drawScrewdriver = context => {
	context.save();
	context.translate(590, 470);
	context.rotate(-0.35);
	context.fillStyle = 'rgba(0, 0, 0, 0.3)';
	context.fillRect(-60, 8, 150, 10);
	context.fillStyle = '#9aa0a6';
	context.fillRect(0, -3, 84, 7);
	context.fillStyle = '#d8dde2';
	context.fillRect(0, -3, 84, 2);
	context.fillStyle = '#5a6066';
	context.fillRect(84, -2, 8, 5);
	context.fillStyle = '#e6b800';
	context.beginPath();
	context.roundRect(-64, -10, 66, 21, 7);
	context.fill();
	context.fillStyle = 'rgba(0, 0, 0, 0.25)';
	for (let index = 0; index < 4; index++) {
		context.fillRect(-56 + (index * 14), -10, 5, 21);
	}

	context.restore();
};

const pathRounded = (context, points) => {
	const corner = 0.2;
	const between = (first, second, amount) => ({x: first.x + ((second.x - first.x) * amount), y: first.y + ((second.y - first.y) * amount)});
	context.beginPath();
	const start = between(points[0], points[1], corner);
	context.moveTo(start.x, start.y);
	for (let index = 0; index < 4; index++) {
		const current = points[(index + 1) % 4];
		const previous = points[index];
		const next = points[(index + 2) % 4];
		const before = between(previous, current, 1 - corner);
		const after = between(current, next, corner);
		context.lineTo(before.x, before.y);
		context.quadraticCurveTo(current.x, current.y, after.x, after.y);
	}

	context.closePath();
};

const shade = (color, brightness, gloss) => {
	const [red, green, blue] = color.map(value => Math.min(255, Math.round((value * brightness) + (255 * gloss))));
	return `rgb(${red} ${green} ${blue})`;
};

// The logo of the cube from 1981, on the white center, drawn flat on the sticker as it turns.
const drawLogo = (context, faceCenter, right, down) => {
	const origin = project(faceCenter);
	const unitRight = project(add(faceCenter, scale(right, 0.01)));
	const unitDown = project(add(faceCenter, scale(down, 0.01)));
	context.save();
	context.transform(unitRight.x - origin.x, unitRight.y - origin.y, unitDown.x - origin.x, unitDown.y - origin.y, origin.x, origin.y);
	context.strokeStyle = '#1d2b6b';
	context.lineWidth = 3;
	context.beginPath();
	context.arc(0, 0, 33, 0, Math.PI * 2);
	context.stroke();
	context.fillStyle = '#1d2b6b';
	context.font = 'bold 13px Arial, sans-serif';
	context.textAlign = 'center';
	context.textBaseline = 'middle';
	context.fillText('RUBIK’S', 0, -5);
	context.font = 'bold 10px Arial, sans-serif';
	context.fillText('CUBE', 0, 9);
	context.restore();
};

const wrapText = (context, text, maximumWidth) => {
	const lines = [];
	let line = '';
	for (const word of text.split(' ')) {
		const candidate = line ? `${line} ${word}` : word;
		if (context.measureText(candidate).width > maximumWidth && line) {
			lines.push(line);
			line = word;
		} else {
			line = candidate;
		}
	}

	lines.push(line);
	return lines;
};

// Pappa’s speech bubble, in the corner, pointing at the cube in his hands.
const drawBubble = (context, text) => {
	context.font = 'bold 17px "Comic Sans MS", "Comic Sans", "Chalkboard SE", cursive';
	const lines = ['👨 Pappa:', ...wrapText(context, text, 250)];
	const boxWidth = Math.max(...lines.map(line => context.measureText(line).width)) + 24;
	const boxHeight = (lines.length * 22) + 16;
	context.fillStyle = '#ffffff';
	context.strokeStyle = '#000000';
	context.lineWidth = 2;
	context.beginPath();
	context.roundRect(14, 14, boxWidth, boxHeight, 12);
	context.moveTo(boxWidth - 30, 14 + boxHeight);
	context.lineTo(boxWidth + 4, 14 + boxHeight + 28);
	context.lineTo(boxWidth - 6, 14 + boxHeight);
	context.fill();
	context.stroke();
	context.fillRect(boxWidth - 29, 10 + boxHeight, 22, 6);
	context.fillStyle = '#1a1a1a';
	context.textAlign = 'left';
	context.textBaseline = 'top';
	for (const [index, line] of lines.entries()) {
		context.fillStyle = index === 0 ? '#800000' : '#1a1a1a';
		context.fillText(line, 26, 22 + (index * 22));
	}
};

const isInsidePolygon = (point, polygon) => {
	let isInside = false;
	for (let index = 0, previous = polygon.length - 1; index < polygon.length; previous = index++) {
		const current = polygon[index];
		const other = polygon[previous];
		if ((current.y > point.y) !== (other.y > point.y) && point.x < ((other.x - current.x) * (point.y - current.y) / (other.y - current.y)) + current.x) {
			isInside = !isInside;
		}
	}

	return isInside;
};

// Pappa’s attempt: 3 minutes on his clock, which runs fast, so it takes 15 seconds for the visitor.
const pappaLength = 15_000;
const pappaSeconds = pappa => pappa.elapsed * 180 / pappaLength;
const pappaLines = [
	{at: 0, text: 'Gi meg den. Jeg skal vise deg hvordan.', english: 'Give it to me. I will show you how.'},
	{at: 20, text: 'Først den hvite siden. Det er lett.', english: 'First the white side. That is easy.'},
	{at: 55, text: 'Nesten! … Nei.', english: 'Almost! … No.'},
	{at: 90, text: 'Hvem har funnet på dette?', english: 'Who came up with this?'},
	{at: 125, text: 'Den må være ødelagt.', english: 'It must be broken.'},
	{at: 158, text: 'Fy søren …', english: 'Darn it …'},
	{at: 180, text: 'Jeg gir opp. Den var ødelagt fra fabrikken. Hvem vil ha vafler?', english: 'I give up. It was broken from the factory. Who wants waffles?'},
];

const pappaMoveTimes = () => {
	const moveTimes = [];
	let time = 4;
	while (time < 174) {
		moveTimes.push(time);
		// Pappa turns a few times fast, and then stares at the cube for a long time.
		time += Math.random() < 0.25 ? 9 + (Math.random() * 10) : 1.5 + (Math.random() * 3);
	}

	return moveTimes;
};

const randomFaceToken = previous => {
	let letter;
	do {
		letter = randomItem(['R', 'L', 'U', 'D', 'F', 'B']);
	} while (letter === previous);
	return {letter, turns: randomItem([1, -1, 2])};
};

const keyLetters = {KeyR: 'R', KeyL: 'L', KeyU: 'U', KeyD: 'D', KeyF: 'F', KeyB: 'B', KeyM: 'M', KeyE: 'E', KeyS: 'S', KeyX: 'x', KeyY: 'y', KeyZ: 'z'};

const withArticle = color => `${color === 'orange' ? 'an' : 'a'} ${color}`;

const patternTexts = {
	'M2 E2 S2': 'Six faces like the flag of a car race. Only the middle slices turned twice.',
	'F L F U’ R U F2 L2 U’ L’ B D’ B’ L2 U': 'A small cube inside the big cube. Trond’s big brother can do this one blindfolded, he says.',
	'U D’ R L’ F B’ U D’': 'Every center has a spot of its own color around it.',
	'U R2 F B R B2 R U2 L B2 R U’ D’ R2 F R’ L B2 U2 F2': 'Every edge is flipped, and everything else is in its place. It is 20 moves away from solved, the most that any position can be.',
};

const highlightTexts = {
	cross: 'The four edges with white on them are blinking. They go around the white center.',
	corners: 'The four corners with white on them are blinking. They go between the edges of the cross.',
	middle: 'The four edges of the middle layer are blinking. They have no white and no yellow.',
	yellowCross: 'The four edges with yellow on them are blinking.',
	yellowCorners: 'The four corners with yellow on them are blinking.',
};

// The places on the table where the pieces land, apart from each other and inside the picture.
const tableSpots = () => {
	const spots = [];
	for (let z = -5.2; z <= 1.3; z += 1.6) {
		for (let x = -6.4; x <= 6.4; x += 1.6) {
			const isInPicture = Math.abs(x) <= ((330 / focal) * (cameraDistance - z)) - 0.8;
			const isUnderCube = Math.abs(x) < 1.4 && z < 0.4;
			if (isInPicture && !isUnderCube) {
				spots.push([x + ((Math.random() - 0.5) * 0.3), tableHeight + halfSize, z + ((Math.random() - 0.5) * 0.3)]);
			}
		}
	}

	return shuffled(spots);
};

export default class extends GeoCitiesElement {
	#context;
	#pixelScale;
	#loop;
	#cubies;
	#view = homeView;
	#mode = 'normal';
	#animation;
	#drag;
	#viewTween;
	#spin;
	#pieces;
	#pappa;
	#bubble;
	#highlight;
	#isPeeling = false;
	#selectedSticker;
	#solution;
	#needsDraw = true;
	#hitFaces = [];
	#history = [];
	#recentMoves = [];
	#moveCount = 0;
	#isHelped = false;
	#wasSolved = false;
	#timer = {state: 'idle', start: 0, elapsed: 0};
	#times = [];
	#pappaAttempts = 0;
	#queue = [];
	#pageIndex = 0;

	// The sounds, made in the browser once the visitor turns them on: the clack of the plastic, the pop of a piece, and the rip of a sticker.
	#sounds = {
		audio: undefined,
		isOn: false,
		noise: undefined,
		quietUntil: 0,
		// The audio of `sound()`, which the click on the sound button gives.
		start(audio) {
			if (!audio) {
				return false;
			}

			this.audio = audio;
			audio.context.resume();

			if (!this.noise) {
				this.noise = new AudioBuffer({length: audio.context.sampleRate, sampleRate: audio.context.sampleRate});
				const samples = this.noise.getChannelData(0);
				for (let index = 0; index < samples.length; index++) {
					samples[index] = (Math.random() * 2) - 1;
				}
			}

			return true;
		},
		get isRunning() {
			return this.isOn && this.audio?.context.state === 'running';
		},
		tone(frequency, duration, {type = 'square', volume = 0.06, when = 0, slide} = {}) {
			if (!this.isRunning) {
				return;
			}

			const {context, output} = this.audio;
			const start = context.currentTime + when;
			const oscillator = new OscillatorNode(context, {type, frequency});
			const gain = new GainNode(context, {gain: 0});
			if (slide) {
				oscillator.frequency.exponentialRampToValueAtTime(slide, start + duration);
			}

			gain.gain.setValueAtTime(0, start);
			gain.gain.linearRampToValueAtTime(volume, start + 0.005);
			gain.gain.exponentialRampToValueAtTime(0.0001, start + duration);
			oscillator.connect(gain).connect(output);
			oscillator.start(start);
			oscillator.stop(start + duration + 0.02);
		},
		burst(duration, {volume = 0.2, frequency = 800, type = 'lowpass', when = 0} = {}) {
			if (!this.isRunning) {
				return;
			}

			const {context, output} = this.audio;
			const start = context.currentTime + when;
			const source = new AudioBufferSourceNode(context, {buffer: this.noise});
			const gain = new GainNode(context, {gain: volume});
			gain.gain.setValueAtTime(volume, start);
			gain.gain.exponentialRampToValueAtTime(0.0001, start + duration);
			source.connect(new BiquadFilterNode(context, {type, frequency, Q: 2})).connect(gain).connect(output);
			source.start(start, Math.random() * 0.8);
			source.stop(start + duration + 0.02);
		},
		// The clack of a quarter turn: the plastic clicks over the bump at the end of the turn. Turns that happen at once, like with reduced motion, make one clack.
		turn() {
			if (!this.isRunning || this.audio.context.currentTime < this.quietUntil) {
				return;
			}

			this.quietUntil = this.audio.context.currentTime + 0.04;
			this.burst(0.03, {volume: 0.35, frequency: 2200 + (Math.random() * 900), type: 'bandpass'});
			this.burst(0.05, {volume: 0.2, frequency: 500 + (Math.random() * 200), type: 'bandpass', when: 0.012});
		},
		click() {
			this.burst(0.02, {volume: 0.2, frequency: 3000, type: 'bandpass'});
		},
		pop() {
			this.tone(620, 0.1, {type: 'sine', volume: 0.12, slide: 180});
			this.burst(0.03, {volume: 0.3, frequency: 1800, type: 'bandpass'});
		},
		thud() {
			this.burst(0.07, {volume: 0.35, frequency: 260 + (Math.random() * 120), type: 'bandpass'});
			this.tone(110, 0.06, {type: 'sine', volume: 0.08});
		},
		// The screwdriver scrapes under an edge.
		scrape() {
			for (let index = 0; index < 5; index++) {
				this.burst(0.05, {volume: 0.15, frequency: 3500 + (index * 300), type: 'bandpass', when: index * 0.05});
			}
		},
		// The old glue lets go of the sticker.
		peel() {
			for (let index = 0; index < 7; index++) {
				this.burst(0.025, {volume: 0.12, frequency: 2000 + (index * 450), type: 'highpass', when: index * 0.022});
			}
		},
		stick() {
			this.burst(0.05, {volume: 0.18, frequency: 700, type: 'bandpass'});
		},
		fanfare() {
			for (const [index, frequency] of [523, 659, 784, 1047, 784, 1047].entries()) {
				this.tone(frequency, index === 5 ? 0.5 : 0.16, {volume: 0.05, when: index * 0.11});
			}
		},
		// The sad trombone of a grown-up who gives up.
		sad() {
			for (const [index, frequency] of [392, 370, 349].entries()) {
				this.tone(frequency, 0.35, {type: 'sawtooth', volume: 0.04, when: index * 0.38, slide: frequency * 0.97});
			}

			this.tone(330, 0.9, {type: 'sawtooth', volume: 0.04, when: 1.14, slide: 300});
		},
	};

	connected() {
		const {canvas, undo, view, sound, form, algorithm, scramble, peel, lookSolved, restick, apart, together, sister, pappa, solve, nextStep, playSolution, previousPage, nextPage} = this.parts;
		this.#context = canvas.getContext('2d');
		this.#pixelScale = canvas.width / width;

		// The cube is kept in the browser, with the moved stickers, so it is like the visitor left it.
		this.#cubies = restoreCube(this.stored('cube')) ?? (() => {
			const cube = createCube();
			for (const token of parseAlgorithm(pappasScramble)) {
				applyMove(cube, moveFromToken(token));
			}

			return cube;
		})();

		this.#wasSolved = looksSolved(this.#cubies);
		this.#times = this.stored('times', []).filter(entry => Number.isFinite(entry?.time) && Number.isFinite(entry?.moves)).slice(0, 5);
		const savedPappaAttempts = this.stored('pappa', 0);
		this.#pappaAttempts = Number.isInteger(savedPappaAttempts) ? savedPappaAttempts : 0;

		this.#loop = this.loop(seconds => {
			this.#step(seconds * 1000);
		}, {
			while: () => {
				const isMoving = !this.reducedMotion;
				return this.#needsDraw || Boolean(this.#animation) || this.#queue.length > 0 || Boolean(this.#drag) || Boolean(this.#viewTween) || Boolean(this.#spin) || this.#arePiecesMoving() || Boolean(this.#pieces?.onDone) || Boolean(this.#pappa) || (isMoving && (this.#timer.state === 'running' || Boolean(this.#highlight) || Boolean(this.#bubble)));
			},
		});

		// The canvas has as many pixels as the screen shows, so the cube is sharp on high-density screens too.
		this.observe(new ResizeObserver(() => {
			this.#pixelScale = canvas.clientWidth * devicePixelRatio / width;
			canvas.width = Math.round(width * this.#pixelScale);
			canvas.height = Math.round(height * this.#pixelScale);
			this.#requestDraw();
		})).observe(canvas);

		this.on(canvas, 'pointerdown', event => {
			this.#pointerDown(event);
		});

		this.on(canvas, 'pointermove', event => {
			this.#pointerMove(event);
		});

		this.on(canvas, 'pointerup', event => {
			this.#endDrag(event);
		});

		this.on(canvas, 'pointercancel', event => {
			this.#endDrag(event);
		});

		this.on(canvas, 'keydown', event => {
			this.#keyDown(event);
		});

		this.on(undo, 'click', () => {
			this.#undo();
		});

		this.on(view, 'click', () => {
			this.#snapHome();
			this.say('The cube is back in front of you, with the top up.');
		});

		this.on(sound, 'click', () => {
			const sounds = this.#sounds;
			sounds.isOn = !sounds.isOn && sounds.start(this.sound());
			sound.setAttribute('aria-pressed', String(sounds.isOn));
			sound.textContent = sounds.isOn ? '🔊 Sound' : '🔈 Sound';
			this.say(sounds.isOn ? 'The sound is on: the clack of the old plastic at each turn.' : 'The sound is off.');
			sounds.turn();
		});

		this.on(form, 'submit', event => {
			event.preventDefault();
			this.#playAlgorithm(algorithm.value);
		});

		this.on(scramble, 'click', () => {
			this.#scramble();
		});

		for (const button of this.querySelectorAll('[data-rubik-pattern]')) {
			this.on(button, 'click', () => {
				this.#makePattern(button);
			});
		}

		this.on(peel, 'click', () => {
			this.#togglePeeling();
		});

		this.on(lookSolved, 'click', () => {
			this.#makeLookSolved();
		});

		this.on(restick, 'click', () => {
			this.#restick();
		});

		this.on(apart, 'click', () => {
			this.#takeApart();
		});

		this.on(together, 'click', () => {
			this.#putTogether(false);
		});

		this.on(sister, 'click', () => {
			this.#putTogether(true);
		});

		this.on(pappa, 'click', () => {
			this.#startPappa();
		});

		this.on(solve, 'click', () => {
			this.#solve();
		});

		this.on(nextStep, 'click', () => {
			this.#playSteps(false);
		});

		this.on(playSolution, 'click', () => {
			this.#playSteps(true);
		});

		this.on(previousPage, 'click', () => {
			this.#showPage(this.#pageIndex - 1);
		});

		this.on(nextPage, 'click', () => {
			this.#showPage(this.#pageIndex + 1);
		});

		for (const button of this.querySelectorAll('[data-rubik-algorithm]')) {
			this.on(button, 'click', () => {
				algorithm.value = button.dataset.rubikAlgorithm;
				this.#playAlgorithm(button.dataset.rubikAlgorithm);
			});
		}

		for (const button of this.querySelectorAll('[data-rubik-highlight]')) {
			this.on(button, 'click', () => {
				const key = button.dataset.rubikHighlight;
				this.#highlight = {key, start: performance.now()};
				this.say(highlightTexts[key] ?? '');
				this.#requestDraw();
			});
		}

		this.#renderTimes();
		this.#updateDisplay();
		this.#refreshControls();
	}

	// The cube runs only while the canvas is on the screen, not while only the buttons and papers below it are, so the turns of the solver wait until the cube is in view.
	get visibilityTarget() {
		return this.parts.canvas;
	}

	// When the cube leaves the screen, the turns that are left happen at once, so nothing waits for a loop that does not run, and the turns that wait for the cube to come into view start when it does.
	visibilityChanged(isVisible) {
		if (isVisible) {
			this.#startNext();
		} else if (this.#animation) {
			this.#finishAnimation();
		}
	}

	// A focused button that gets disabled or hidden drops the focus to the top of the page, and a visitor with the keyboard would have to Tab all the way back. So the focus goes to the button that takes its place, or to the cube.
	focusReplacement(control) {
		const {apart, together, sister, previousPage, nextPage} = this.parts;

		const replacements = new Map([
			[apart, together],
			[together, apart],
			[sister, apart],
			[previousPage, nextPage],
			[nextPage, previousPage],
		]);

		return replacements.get(control) ?? super.focusReplacement(control);
	}

	get focusFallback() {
		return this.parts.canvas;
	}

	#requestDraw() {
		this.#needsDraw = true;
		this.#loop.start();
	}

	// Which face is on top, in front, and on the right as the visitor holds the cube, so the letters turn what the visitor sees.
	#currentFrame() {
		// While the cube turns back to the front or spins, the letters go by how it will be held after that.
		const held = this.#viewTween?.to ?? this.#spin?.base ?? this.#view;
		const up = directions.toSorted((first, second) => transform(held, second)[1] - transform(held, first)[1])[0];
		const front = directions.filter(direction => dot(direction, up) === 0).toSorted((first, second) => transform(held, second)[2] - transform(held, first)[2])[0];
		return {U: up, F: front, R: cross(up, front)};
	}

	#updateDisplay(now = performance.now()) {
		const {time, moves, best} = this.parts;
		const timer = this.#timer;

		if (this.#pappa) {
			const seconds = Math.min(180, Math.floor(pappaSeconds(this.#pappa)));
			time.textContent = `Pappa ${Math.floor(seconds / 60)}:${String(seconds % 60).padStart(2, '0')}`;
			time.dataset.state = 'running';
		} else if (timer.state === 'running') {
			time.textContent = formatTime(now - timer.start);
			time.dataset.state = 'running';
		} else if (timer.state === 'done') {
			time.textContent = formatTime(timer.elapsed);
			time.dataset.state = 'solved';
		} else {
			time.textContent = timer.state === 'armed' ? 'Ready' : '0:00.00';
			delete time.dataset.state;
		}

		moves.textContent = `${this.#moveCount} ${this.#moveCount === 1 ? 'move' : 'moves'}${this.#isHelped && timer.state === 'running' ? ' (helped)' : ''}`;
		best.textContent = `Best: ${this.#times[0] ? formatTime(this.#times[0].time) : 'none'}`;
	}

	#renderTimes() {
		for (const [index, item] of this.querySelectorAll('[data-rubik-time]').entries()) {
			const entry = this.#times[index];
			item.hidden = !entry;
			item.textContent = entry ? `${formatTime(entry.time)} · ${entry.moves} moves` : '';
		}
	}

	#isBusy() {
		return Boolean(this.#animation) || this.#queue.length > 0 || Boolean(this.#drag?.kind === 'turn') || Boolean(this.#pappa);
	}

	#canStart() {
		return this.#mode === 'normal' && !this.#isBusy();
	}

	// The turns of a scramble, a pattern, or the solver, which the turns of the visitor must not get mixed into.
	#isTurningByItself() {
		return [this.#animation?.item, ...this.#queue].some(item => item && item.source !== 'visitor' && item.source !== 'undo');
	}

	#refreshControls() {
		const {undo, apart, together, sister, restick, lookSolved, scramble, peel, pappa, solve} = this.parts;
		const isApart = this.#mode !== 'normal';
		undo.disabled = this.#history.length === 0 || isApart || Boolean(this.#pappa);
		apart.hidden = isApart;
		together.hidden = !isApart;
		sister.hidden = !isApart;
		restick.hidden = isApart || movedStickerCount(this.#cubies) === 0;
		lookSolved.hidden = !this.#isPeeling;
		for (const button of [scramble, peel, pappa, solve, apart, ...this.querySelectorAll('[data-rubik-pattern]')]) {
			button.disabled = isApart || Boolean(this.#pappa);
		}

		peel.setAttribute('aria-pressed', String(this.#isPeeling));
		peel.textContent = this.#isPeeling ? '🩹 Done Peeling' : '🩹 Peel the Stickers';
	}

	#hideSolution() {
		this.#solution = undefined;
		this.parts.solution.hidden = true;
	}

	#snapHome() {
		this.#spin = undefined;
		if (this.reducedMotion) {
			this.#view = homeView;
		} else {
			this.#viewTween = {from: this.#view, to: homeView, start: performance.now(), duration: 450};
		}

		this.#requestDraw();
	}

	// Turns: each waits in the queue and turns smoothly, or at once with reduced motion, or while the cube is not on the screen.
	#startNext() {
		while (!this.#animation && this.#queue.length > 0 && this.#drag?.kind !== 'turn') {
			const item = this.#queue.shift();
			if (this.reducedMotion || !this.isVisible || item.duration === 0) {
				this.#completeMove(item);
				continue;
			}

			this.#animation = {
				item,
				axis: item.move.axis,
				layers: item.move.layers,
				fromAngle: 0,
				toAngle: item.move.quarters * Math.PI / 2,
				start: performance.now(),
				duration: item.duration * (Math.abs(item.move.quarters) === 2 ? 1.5 : 1),
			};
		}

		this.#requestDraw();
	}

	// A turn without an item is a layer that the visitor let go of before a quarter turn, which only goes back.
	#finishAnimation() {
		const {item} = this.#animation;
		this.#animation = undefined;
		if (item) {
			this.#completeMove(item);
		}

		this.#startNext();
	}

	#enqueue(moves, source, duration, extra = {}) {
		for (const move of moves) {
			this.#queue.push({move, source, duration, ...extra});
		}

		this.#startNext();
		this.#refreshControls();
	}

	#playTokens(tokens, source, duration, frame = this.#currentFrame()) {
		this.#enqueue(tokens.map(token => moveFromToken(token, frame)), source, duration);
	}

	#completeMove(item) {
		applyMove(this.#cubies, item.move);
		this.#sounds.turn();
		if (item.source !== 'undo') {
			this.#history.push(item.move);
			if (this.#history.length > 500) {
				this.#history = this.#history.slice(-500);
			}
		}

		if (!item.move.isRotation && item.source !== 'scramble' && item.source !== 'pattern') {
			this.#moveCount++;
		}

		if (item.source === 'visitor' || item.source === 'undo') {
			this.#recentMoves.push(item.move.name);
			this.#recentMoves = this.#recentMoves.slice(-16);
			if (!item.isTyped) {
				const {notation} = this.parts;
				notation.textContent = `Your moves: ${this.#recentMoves.join(' ')}`;
			}

			// With reduced motion, the blinking pieces and Pappa’s bubble do not go away by themselves, so they go at the next turn.
			if (this.reducedMotion) {
				this.#highlight = undefined;
				this.#bubble = undefined;
			}
		}

		if (this.#timer.state === 'armed' && item.source === 'visitor' && !item.move.isRotation) {
			this.#timer = {state: 'running', start: performance.now(), elapsed: 0};
		}

		if (item.source === 'solver' || item.source === 'pappa') {
			this.#isHelped = true;
		}

		if (item.source === 'solver' && this.#solution) {
			for (const [index, stepItem] of this.querySelectorAll('[data-rubik-step]').entries()) {
				if (index < item.step) {
					stepItem.dataset.state = 'done';
				} else if (index === item.step) {
					stepItem.dataset.state = 'current';
				}
			}
		} else if (this.#solution) {
			this.#hideSolution();
		}

		this.#checkSolved(item.source);
		if (this.#queue.length === 0) {
			this.#finishBatch(item);
		}

		this.#updateDisplay();
		this.#refreshControls();
	}

	#finishBatch(item) {
		if (item.source === 'scramble') {
			this.#timer = {state: 'armed', start: 0, elapsed: 0};
			this.#moveCount = 0;
			this.#isHelped = movedStickerCount(this.#cubies) > 0;
			this.#history = [];
			this.#recentMoves = [];
			this.say('Scrambled! The clock starts at your first turn, like at a real competition.');
		} else if (item.source === 'pattern') {
			this.say(`${item.patternName}! ${item.patternText}`);
		} else if (item.source === 'solver' && this.#solution && this.#solution.next >= this.#solution.steps.length && looksSolved(this.#cubies)) {
			for (const stepItem of this.querySelectorAll('[data-rubik-step]')) {
				stepItem.dataset.state = 'done';
			}
		}

		this.#saveCube();
	}

	#saveCube() {
		this.store('cube', this.#cubies.map(cubie => ({
			position: cubie.position,
			stickers: cubie.stickers.map(sticker => ({normal: sticker.normal, right: sticker.right, color: sticker.color, isLogo: sticker.isLogo})),
		})));
	}

	#checkSolved(source) {
		const isSolved = this.#mode === 'normal' && looksSolved(this.#cubies);
		if (isSolved && !this.#wasSolved) {
			this.#announceSolved(source);
		}

		this.#wasSolved = isSolved;
	}

	#startSpin() {
		if (!this.reducedMotion) {
			this.#viewTween = undefined;
			this.#spin = {start: performance.now(), duration: 1600, base: this.#view};
			this.#requestDraw();
		}
	}

	#announceSolved(source) {
		const moved = movedStickerCount(this.#cubies);
		if (this.#timer.state === 'running') {
			this.#timer = {state: 'done', start: this.#timer.start, elapsed: performance.now() - this.#timer.start};
		}

		if (source === 'scramble' || source === 'pattern') {
			return;
		}

		if (moved > 0) {
			this.say(`It looks solved! But ${moved} stickers are not on their own pieces, and their edges are bent from the peeling. Mamma would see it at once. Turn it, and the fake shows.`);
			this.#sounds.sad();
			return;
		}

		const isFirstTime = !this.stored('solved', false);
		this.store('solved', true);
		const firstTime = isFirstTime ? ' Nobody in the family has done that since 1981!' : '';
		if (source === 'solver') {
			this.say(`Solved! The solver did it, so it does not count. But it looks like new from the shop again.${firstTime}`);
			this.#sounds.fanfare();
			this.#startSpin();
			return;
		}

		const timer = this.#timer;
		if (timer.state === 'done' && !this.#isHelped) {
			this.#times = [...this.#times, {time: timer.elapsed, moves: this.#moveCount}].toSorted((first, second) => first.time - second.time).slice(0, 5);
			this.store('times', this.#times);
			this.#renderTimes();
			const isBest = this.#times[0].time === timer.elapsed;
			this.say(`Solved in ${formatTime(timer.elapsed)} with ${this.#moveCount} moves!${isBest ? ' That is a new best time!' : ''}${firstTime} Pappa says it must be a trick.`);
			this.toast(`🧊 Pappa’s cube solved in ${formatTime(timer.elapsed)}!`);
		} else if (this.#isHelped) {
			this.say(`Solved! But you had help, so the time does not count.${firstTime}`);
		} else {
			this.say(`Solved!${firstTime} Without the clock, nobody at school will believe you. Scramble it, and do it again with the clock.`);
			this.toast('🧊 Pappa’s cube is solved!');
		}

		this.celebrate();
		this.#sounds.fanfare();
		this.#startSpin();
	}

	#drawCubie({cubie, pose}, now) {
		const context = this.#context;
		const isHighlighted = this.#highlight && highlighted[this.#highlight.key]?.(cubie);
		for (const direction of directions) {
			const normal = transform(pose.rotation, direction);
			const faceCenter = add(pose.position, scale(normal, halfSize));
			if (dot(normal, subtract(cameraPosition, faceCenter)) <= 0) {
				continue;
			}

			const axis = direction.findIndex(value => value !== 0);
			const firstAxis = [0, 0, 0];
			firstAxis[(axis + 1) % 3] = 1;
			const secondAxis = [0, 0, 0];
			secondAxis[(axis + 2) % 3] = 1;
			const first = transform(pose.rotation, firstAxis);
			const second = transform(pose.rotation, secondAxis);
			const corner = (size, firstSign, secondSign) => project(add(faceCenter, add(scale(first, size * firstSign), scale(second, size * secondSign))));
			const points = [corner(halfSize, 1, 1), corner(halfSize, 1, -1), corner(halfSize, -1, -1), corner(halfSize, -1, 1)];
			const brightness = 0.42 + (0.62 * Math.max(0, dot(normal, light)));

			// The black plastic of the piece.
			context.beginPath();
			context.moveTo(points[0].x, points[0].y);
			for (const point of points.slice(1)) {
				context.lineTo(point.x, point.y);
			}

			context.closePath();
			context.fillStyle = shade([30, 30, 32], brightness, 0);
			context.fill();
			context.strokeStyle = '#050505';
			context.lineWidth = 1.2;
			context.stroke();

			const sticker = cubie.stickers.find(item => isSameVector(item.normal, direction));
			this.#hitFaces.push({points, cubie, direction, sticker});
			if (!sticker) {
				continue;
			}

			const stickerPoints = [corner(stickerSize, 1, 1), corner(stickerSize, 1, -1), corner(stickerSize, -1, -1), corner(stickerSize, -1, 1)];
			pathRounded(context, stickerPoints);
			const isLifted = this.#drag?.kind === 'peel' && this.#drag.hasMoved && this.#drag.hit.sticker === sticker;
			if (isLifted) {
				// The glue that is left where the sticker was.
				context.fillStyle = shade([70, 64, 50], brightness, 0);
				context.fill();
				continue;
			}

			const seed = (cubie.id * 7) + axis + (direction[axis] > 0 ? 3 : 0);
			const wear = 0.94 + (hash(seed) * 0.08);
			const gloss = (Math.max(0, dot(normal, shine)) ** 24) * 0.45;
			context.fillStyle = shade(palette[sticker.color], brightness * wear, gloss);
			context.fill();

			// Some old stickers have a corner that lifts, and moved stickers have creases from the peeling.
			if (hash(seed + 100) > 0.9 || sticker.color !== sticker.original) {
				const lift = project(add(faceCenter, add(scale(first, stickerSize * 0.55), scale(second, stickerSize * 0.95))));
				const liftOther = project(add(faceCenter, add(scale(first, stickerSize * 0.95), scale(second, stickerSize * 0.55))));
				context.fillStyle = 'rgba(255, 250, 230, 0.55)';
				context.beginPath();
				context.moveTo(stickerPoints[0].x, stickerPoints[0].y);
				context.lineTo(lift.x, lift.y);
				context.lineTo(liftOther.x, liftOther.y);
				context.closePath();
				context.fill();
			}

			if (sticker.color !== sticker.original) {
				const from = project(add(faceCenter, add(scale(first, -stickerSize * 0.8), scale(second, stickerSize * 0.3))));
				const to = project(add(faceCenter, add(scale(first, stickerSize * 0.7), scale(second, -stickerSize * 0.5))));
				context.strokeStyle = 'rgba(255, 255, 255, 0.45)';
				context.lineWidth = 1;
				context.beginPath();
				context.moveTo(from.x, from.y);
				context.lineTo(to.x, to.y);
				context.stroke();
			}

			if (sticker.isLogo) {
				const right = transform(pose.rotation, sticker.right);
				drawLogo(context, faceCenter, right, cross(right, normal));
			}

			if (this.#selectedSticker === sticker) {
				pathRounded(context, stickerPoints);
				context.setLineDash([5, 4]);
				context.strokeStyle = '#ffffff';
				context.lineWidth = 3;
				context.stroke();
				context.setLineDash([]);
			}

			if (isHighlighted) {
				pathRounded(context, stickerPoints);
				context.strokeStyle = `rgba(255, 240, 0, ${this.reducedMotion ? 1 : 0.55 + (0.45 * Math.sin(now / 140))})`;
				context.lineWidth = 4;
				context.stroke();
			}
		}
	}

	#currentTurn(now) {
		const animation = this.#animation;
		if (animation) {
			const progress = Math.min(1, (now - animation.start) / animation.duration);
			return {axis: animation.axis, layers: animation.layers, angle: animation.fromAngle + ((animation.toAngle - animation.fromAngle) * easeInOut(progress))};
		}

		if (this.#drag?.kind === 'turn' && this.#drag.axis !== undefined) {
			return {axis: this.#drag.axis, layers: [this.#drag.layer], angle: this.#drag.angle};
		}

		return undefined;
	}

	#poseOf(cubie, turn) {
		const piece = this.#pieces?.get(cubie);
		if (piece) {
			return piece.pose;
		}

		const rotation = turn?.layers.includes(cubie.position[turn.axis]) ? multiplyMatrices(this.#view, rotationMatrix(turn.axis, turn.angle)) : this.#view;
		return {rotation, position: transform(rotation, cubie.position)};
	}

	// The pieces are drawn from the back to the front. While the cube is whole, it is cut into three slabs along an axis, which are drawn in order, so a turning layer is never drawn over a layer in front of it.
	#orderForDrawing(items, turn) {
		const byDistance = (first, second) => distanceToCamera(second.pose.position) - distanceToCamera(first.pose.position);
		if (this.#pieces) {
			return items.toSorted(byDistance);
		}

		const cameraInCube = transform(transpose(this.#view), cameraPosition);
		const axis = turn?.axis ?? [0, 1, 2].toSorted((first, second) => Math.abs(cameraInCube[second]) - Math.abs(cameraInCube[first]))[0];
		const slabs = cameraInCube[axis] > 0 ? [-1, 0, 1] : [1, 0, -1];
		return slabs.flatMap(layer => items.filter(item => item.cubie.position[axis] === layer).toSorted(byDistance));
	}

	#drawFloatingSticker() {
		const drag = this.#drag;
		if (drag?.kind !== 'peel' || !drag.hasMoved) {
			return;
		}

		const context = this.#context;
		context.save();
		context.translate(drag.point.x, drag.point.y);
		context.rotate(0.2);
		context.fillStyle = 'rgba(0, 0, 0, 0.35)';
		context.beginPath();
		context.roundRect(-18, -14, 44, 44, 6);
		context.fill();
		context.fillStyle = shade(palette[drag.hit.sticker.color], 1, 0.05);
		context.strokeStyle = 'rgba(0, 0, 0, 0.4)';
		context.beginPath();
		context.roundRect(-24, -24, 44, 44, 6);
		context.fill();
		context.stroke();
		context.restore();
	}

	#draw(now) {
		const context = this.#context;
		context.setTransform(this.#pixelScale, 0, 0, this.#pixelScale, 0, 0);
		drawRoom(context);
		drawShadow(context);
		if (this.#mode !== 'normal') {
			drawScrewdriver(context);
		}

		const turn = this.#currentTurn(now);
		const items = this.#orderForDrawing(this.#cubies.map(cubie => ({cubie, pose: this.#poseOf(cubie, turn)})), turn);
		this.#hitFaces = [];
		for (const item of items) {
			this.#drawCubie(item, now);
		}

		this.#drawFloatingSticker();
		if (this.#bubble) {
			drawBubble(context, this.#bubble.text);
		}
	}

	#hitTest(point) {
		return this.#hitFaces.findLast(face => isInsidePolygon(point, face.points));
	}

	#updatePieces(now) {
		const pieces = this.#pieces;
		let isMoving = false;
		for (const piece of pieces.values()) {
			const progress = (now - piece.start) / piece.duration;
			if (progress <= 0) {
				piece.pose = piece.from;
				isMoving = true;
			} else if (progress >= 1) {
				piece.pose = piece.to;
				if (!piece.hasLanded) {
					piece.hasLanded = true;
					this.#sounds.thud();
				}
			} else {
				isMoving = true;
				const position = add(piece.from.position, scale(subtract(piece.to.position, piece.from.position), progress));
				position[1] += piece.arc * 4 * progress * (1 - progress);
				piece.pose = {position, rotation: interpolateMatrices(piece.from.rotation, piece.to.rotation, easeInOut(progress))};
			}
		}

		if (!isMoving && pieces.onDone) {
			const onDone = pieces.onDone;
			pieces.onDone = undefined;
			onDone();
		}

		return isMoving;
	}

	#arePiecesMoving() {
		return Boolean(this.#pieces) && [...this.#pieces.values()].some(piece => !piece.hasLanded);
	}

	#sayPappa(line) {
		this.#bubble = {text: line.text, until: performance.now() + 4000};
		this.say(`Pappa: “${line.text}” (${line.english})`);
		this.#requestDraw();
	}

	#startPappa() {
		if (!this.#canStart()) {
			this.#explainBusy();
			return;
		}

		this.#isPeeling = false;
		this.#selectedSticker = undefined;
		this.#hideSolution();
		this.#pappaAttempts++;
		this.store('pappa', this.#pappaAttempts);
		const pappa = {elapsed: 0, lineIndex: 0, moveTimes: pappaMoveTimes(), moveIndex: 0, before: matchingStickers(this.#cubies), previous: undefined};
		this.#pappa = pappa;
		this.#isHelped = true;
		if (this.reducedMotion) {
			// Nothing moves by itself, so Pappa’s three minutes happen at once.
			const tokens = pappa.moveTimes.map(() => {
				const token = randomFaceToken(pappa.previous?.letter);
				pappa.previous = token;
				return token;
			});
			this.#playTokens(tokens, 'pappa', 0, homeFrame);
			this.#finishPappa();
			return;
		}

		this.#sayPappa(pappaLines[0]);
		pappa.lineIndex = 1;
		this.#refreshControls();
		this.#requestDraw();
	}

	#updatePappa(delta) {
		const pappa = this.#pappa;
		pappa.elapsed += delta;
		const seconds = pappaSeconds(pappa);
		const line = pappaLines[pappa.lineIndex];
		if (line && seconds >= line.at && line.at < 180) {
			this.#sayPappa(line);
			pappa.lineIndex++;
		}

		if (pappa.moveIndex < pappa.moveTimes.length && seconds >= pappa.moveTimes[pappa.moveIndex] && !this.#animation && this.#queue.length === 0) {
			const token = randomFaceToken(pappa.previous?.letter);
			pappa.previous = token;
			pappa.moveIndex++;
			this.#playTokens([token], 'pappa', 280, homeFrame);
		}

		if (seconds >= 180 && !this.#animation && this.#queue.length === 0) {
			this.#finishPappa();
		}
	}

	#finishPappa() {
		const {before} = this.#pappa;
		this.#pappa = undefined;
		const lastLine = pappaLines.at(-1);
		this.#bubble = {text: lastLine.text, until: performance.now() + 6000};
		let sneaky = '';

		// Every third time, Pappa moves two stickers when he thinks that nobody is looking, so the white side looks better.
		if (this.#pappaAttempts % 3 === 0) {
			const facelets = readFacelets(this.#cubies);
			const whiteFace = faceNames.findIndex((face, index) => facelets[(index * 9) + 4].color === 'white');
			const wrong = facelets.slice(whiteFace * 9, (whiteFace * 9) + 9).find(sticker => sticker.color !== 'white');
			const white = facelets.find((sticker, index) => sticker.color === 'white' && Math.floor(index / 9) !== whiteFace && index % 9 !== 4);
			if (wrong && white) {
				[wrong.color, white.color] = [white.color, wrong.color];
				sneaky = ' And I saw him move a sticker to the white side when he thought that nobody was looking.';
			}
		}

		const after = matchingStickers(this.#cubies);
		this.say(`Pappa: “${lastLine.text}” (${lastLine.english}) Before Pappa, ${before} of the 54 stickers matched their centers. Now ${after} do.${sneaky}`);
		this.#sounds.sad();
		this.#wasSolved = looksSolved(this.#cubies);
		this.#saveCube();
		this.#refreshControls();
		this.#updateDisplay();
		this.#requestDraw();
	}

	#step(delta) {
		const now = performance.now();

		if (this.#viewTween) {
			const viewTween = this.#viewTween;
			const progress = Math.min(1, (now - viewTween.start) / viewTween.duration);
			this.#view = interpolateMatrices(viewTween.from, viewTween.to, easeInOut(progress));
			if (progress >= 1) {
				this.#view = viewTween.to;
				this.#viewTween = undefined;
			}
		}

		if (this.#spin) {
			const spin = this.#spin;
			const progress = Math.min(1, (now - spin.start) / spin.duration);
			this.#view = multiplyMatrices(rotationMatrix(1, Math.PI * 2 * easeInOut(progress)), spin.base);
			if (progress >= 1) {
				this.#view = spin.base;
				this.#spin = undefined;
			}
		}

		if (this.#animation && now - this.#animation.start >= this.#animation.duration) {
			this.#finishAnimation();
		}

		if (this.#pieces) {
			this.#updatePieces(now);
		}

		if (this.#pappa) {
			this.#updatePappa(delta);
		}

		if (this.#highlight && !this.reducedMotion && now - this.#highlight.start > 6000) {
			this.#highlight = undefined;
		}

		if (this.#bubble && !this.#pappa && !this.reducedMotion && now > this.#bubble.until) {
			this.#bubble = undefined;
		}

		this.#updateDisplay(now);
		this.#draw(now);
		this.#needsDraw = false;
	}

	#logicalPoint(event) {
		const point = canvasPoint(this.parts.canvas, event);
		return {x: point.x / this.#pixelScale, y: point.y / this.#pixelScale};
	}

	#turnView(yaw, pitch) {
		this.#spin = undefined;
		this.#viewTween = undefined;
		this.#view = orthonormalize(multiplyMatrices(multiplyMatrices(rotationMatrix(1, yaw), rotationMatrix(0, pitch)), this.#view));
		this.#requestDraw();
	}

	// The drag decides the layer: of the two axes along the face, it takes the one whose turn moves the touched point most like the finger.
	#decideTurn(delta) {
		const drag = this.#drag;
		const hitPoint = add(drag.hit.cubie.position, scale(drag.hit.direction, 0.5));
		const normalAxis = drag.hit.direction.findIndex(value => value !== 0);
		let best;
		for (const axis of [0, 1, 2]) {
			if (axis === normalAxis) {
				continue;
			}

			const unit = [0, 0, 0];
			unit[axis] = 1;
			const velocity = cross(unit, hitPoint);
			const from = project(transform(this.#view, hitPoint));
			const to = project(transform(this.#view, add(hitPoint, scale(velocity, 0.01))));
			const screen = {x: (to.x - from.x) / 0.01, y: (to.y - from.y) / 0.01};
			const length = Math.hypot(screen.x, screen.y);
			if (length < 1) {
				continue;
			}

			const score = Math.abs((delta.x * screen.x) + (delta.y * screen.y)) / length;
			if (!best || score > best.score) {
				best = {axis, screen, score};
			}
		}

		if (best) {
			drag.axis = best.axis;
			drag.layer = drag.hit.cubie.position[best.axis];
			drag.screen = best.screen;
		}
	}

	#releaseTurn() {
		const drag = this.#drag;
		let quarters = Math.round(drag.angle / (Math.PI / 2));
		if (quarters === 0 && Math.abs(drag.angle) > 0.35) {
			quarters = Math.sign(drag.angle);
		}

		quarters = Math.max(-2, Math.min(2, quarters));
		const {axis, angle: fromAngle} = drag;
		const layers = [drag.layer];
		const item = quarters === 0 ? undefined : {move: {axis, layers, quarters, name: nameOfMove({axis, layers, quarters}, this.#currentFrame())}, source: 'visitor'};
		this.#drag = undefined;
		if (this.reducedMotion) {
			if (item) {
				this.#completeMove(item);
			}

			this.#startNext();
			return;
		}

		this.#animation = {item, axis, layers, fromAngle, toAngle: quarters * Math.PI / 2, start: performance.now(), duration: 110 + (Math.abs((quarters * Math.PI / 2) - fromAngle) * 120)};
		this.#requestDraw();
	}

	#afterStickerChange(message) {
		this.#isHelped = true;
		this.#hideSolution();
		const moved = movedStickerCount(this.#cubies);
		const analysis = analyzeCube(this.#cubies);
		const isSolved = looksSolved(this.#cubies);
		let verdict;
		if (moved === 0) {
			verdict = 'Every sticker is back on its own piece, like from the shop in 1981.';
		} else if (isSolved) {
			verdict = `It looks solved! But ${moved} stickers are on the wrong pieces, with bent edges from the peeling. Turn it, and you will find pieces with colors that no real cube has.`;
		} else if (analysis.problem) {
			verdict = `${moved} stickers are on the wrong pieces. Now it can never be solved: ${analysis.problem}.`;
		} else {
			verdict = `${moved} stickers are on the wrong pieces, but by luck, it can still be solved.`;
		}

		this.say(`${message} ${verdict}`);
		this.#wasSolved = isSolved;
		this.#saveCube();
		this.#refreshControls();
		this.#requestDraw();
	}

	#swapStickers(first, second) {
		[first.color, second.color] = [second.color, first.color];
		[first.isLogo, second.isLogo] = [second.isLogo, first.isLogo];
		this.#sounds.stick();
		this.#afterStickerChange(`You swap ${withArticle(second.color)} sticker and ${withArticle(first.color)} sticker.`);
	}

	#releasePeel(point) {
		const target = this.#hitTest(point)?.sticker;
		const {sticker} = this.#drag.hit;
		if (this.#drag.hasMoved) {
			this.#selectedSticker = undefined;
			if (target && target !== sticker) {
				this.#swapStickers(sticker, target);
			} else {
				this.say('The sticker goes back where it was.');
			}
		} else if (!this.#selectedSticker) {
			this.#selectedSticker = sticker;
			this.#sounds.peel();
			this.say(`You peel off ${withArticle(sticker.color)} sticker. Now tap the sticker it should swap places with.`);
		} else if (this.#selectedSticker === sticker) {
			this.#selectedSticker = undefined;
			this.say('You press the sticker back on.');
		} else {
			const first = this.#selectedSticker;
			this.#selectedSticker = undefined;
			this.#swapStickers(first, sticker);
		}

		this.#requestDraw();
	}

	#pointerDown(event) {
		if (event.pointerType === 'mouse' && event.button !== 0) {
			return;
		}

		const point = this.#logicalPoint(event);
		const hit = this.#hitTest(point);
		this.parts.canvas.setPointerCapture(event.pointerId);
		this.#spin = undefined;
		if (this.#mode === 'normal' && this.#isPeeling && hit?.sticker) {
			this.#drag = {kind: 'peel', hit, start: point, point, hasMoved: false, pointerId: event.pointerId};
		} else if (this.#mode === 'normal' && !this.#isPeeling && hit && dot(hit.cubie.position, hit.direction) === 1 && !this.#animation && this.#queue.length === 0 && !this.#pappa) {
			this.#drag = {kind: 'turn', hit, start: point, angle: 0, pointerId: event.pointerId};
		} else {
			this.#drag = {kind: 'view', last: point, pointerId: event.pointerId};
		}

		this.#requestDraw();
	}

	#pointerMove(event) {
		const drag = this.#drag;
		if (drag?.pointerId !== event.pointerId) {
			return;
		}

		const point = this.#logicalPoint(event);
		if (drag.kind === 'view') {
			this.#turnView((point.x - drag.last.x) * 0.009, (point.y - drag.last.y) * 0.009);
			drag.last = point;
		} else if (drag.kind === 'turn') {
			const delta = {x: point.x - drag.start.x, y: point.y - drag.start.y};
			if (drag.axis === undefined && Math.hypot(delta.x, delta.y) > 8) {
				this.#decideTurn(delta);
				if (drag.axis !== undefined) {
					this.#sounds.click();
				}
			}

			if (drag.axis !== undefined) {
				drag.angle = ((delta.x * drag.screen.x) + (delta.y * drag.screen.y)) / ((drag.screen.x ** 2) + (drag.screen.y ** 2));
				drag.angle = Math.max(-Math.PI, Math.min(Math.PI, drag.angle));
			}
		} else if (drag.kind === 'peel') {
			drag.point = point;
			if (!drag.hasMoved && Math.hypot(point.x - drag.start.x, point.y - drag.start.y) > 6) {
				drag.hasMoved = true;
				this.#selectedSticker = undefined;
				this.#sounds.peel();
			}
		}

		this.#requestDraw();
	}

	#endDrag(event) {
		const drag = this.#drag;
		if (drag?.pointerId !== event.pointerId) {
			return;
		}

		if (drag.kind === 'turn' && drag.axis !== undefined && event.type === 'pointerup') {
			this.#releaseTurn();
			return;
		}

		if (drag.kind === 'peel' && event.type === 'pointerup') {
			this.#releasePeel(this.#logicalPoint(event));
		}

		this.#drag = undefined;
		this.#startNext();
		this.#requestDraw();
	}

	#explainBusy() {
		if (this.#pappa) {
			this.say('Pappa is holding the cube. Wait until he gives up.');
		} else if (this.#mode !== 'normal') {
			this.say('The cube is in pieces. Put it back together first.');
		} else {
			this.say('Wait until the cube stops turning.');
		}
	}

	#keyDown(event) {
		if ((event.ctrlKey || event.metaKey) && event.code === 'KeyZ') {
			event.preventDefault();
			this.#undo();
			return;
		}

		if (event.ctrlKey || event.metaKey || event.altKey) {
			return;
		}

		const letter = keyLetters[event.code];
		if (letter) {
			event.preventDefault();
			if (this.#mode !== 'normal' || this.#pappa || this.#isTurningByItself()) {
				this.#explainBusy();
				return;
			}

			this.#playTokens([{letter, turns: event.shiftKey ? -1 : 1}], 'visitor', 150);
			return;
		}

		const turns = {ArrowLeft: [-0.26, 0], ArrowRight: [0.26, 0], ArrowUp: [0, -0.26], ArrowDown: [0, 0.26]}[event.key];
		if (turns) {
			event.preventDefault();
			this.#turnView(...turns);
		} else if (event.key === 'Home') {
			event.preventDefault();
			this.#snapHome();
		} else if (event.key === 'Backspace') {
			event.preventDefault();
			this.#undo();
		}
	}

	#undo() {
		if (this.#mode !== 'normal' || this.#pappa || this.#history.length === 0 || this.#animation || this.#queue.length > 0) {
			return;
		}

		const move = this.#history.pop();
		this.#enqueue([inverseMove(move)], 'undo', 150);
	}

	#playAlgorithm(text) {
		if (this.#mode !== 'normal' || this.#pappa || this.#isTurningByItself()) {
			this.#explainBusy();
			return;
		}

		let tokens;
		try {
			tokens = parseAlgorithm(text);
		} catch (error) {
			this.say(error.message);
			return;
		}

		if (tokens.length === 0) {
			this.say('Type some moves first, like R U R’ U’.');
			return;
		}

		const {notation} = this.parts;
		notation.textContent = `Playing: ${tokens.map(token => tokenName(token)).join(' ')}`;
		const frame = this.#currentFrame();
		this.#enqueue(tokens.map(token => moveFromToken(token, frame)), 'visitor', tokens.length > 30 ? 80 : 150, {isTyped: true});
	}

	#scramble() {
		if (!this.#canStart()) {
			this.#explainBusy();
			return;
		}

		this.#isPeeling = false;
		this.#selectedSticker = undefined;
		this.#hideSolution();
		this.#snapHome();
		const tokens = [];
		let previousAxis;
		while (tokens.length < 25) {
			const letter = randomItem(['R', 'L', 'U', 'D', 'F', 'B']);
			const axis = 'RLUDFB'.indexOf(letter) >> 1;
			if (axis !== previousAxis) {
				previousAxis = axis;
				tokens.push({letter, turns: randomItem([1, -1, 2])});
			}
		}

		this.#timer = {state: 'idle', start: 0, elapsed: 0};
		const {notation} = this.parts;
		notation.textContent = `Scramble: ${tokens.map(token => tokenName(token)).join(' ')}`;
		this.say('Scrambling …');
		this.#playTokens(tokens, 'scramble', 55, homeFrame);
	}

	#makePattern(button) {
		if (!this.#canStart()) {
			this.#explainBusy();
			return;
		}

		const algorithm = button.dataset.rubikPattern;
		this.#isPeeling = false;
		this.#selectedSticker = undefined;
		this.#hideSolution();
		this.#cubies = createCube();
		this.#history = [];
		this.#recentMoves = [];
		this.#moveCount = 0;
		this.#timer = {state: 'idle', start: 0, elapsed: 0};
		this.#wasSolved = true;
		this.#snapHome();
		const name = button.textContent.trim().replace(/^\S+\s/u, '');
		const {notation} = this.parts;
		notation.textContent = `${name}: ${algorithm}`;
		this.#enqueue(parseAlgorithm(algorithm).map(token => moveFromToken(token)), 'pattern', 90, {patternName: name, patternText: patternTexts[algorithm] ?? ''});
	}

	#togglePeeling() {
		if (this.#mode !== 'normal' || this.#pappa) {
			this.#explainBusy();
			return;
		}

		this.#isPeeling = !this.#isPeeling;
		this.#selectedSticker = undefined;
		this.#refreshControls();
		this.#requestDraw();
		this.say(this.#isPeeling ? 'Peel mode: drag a sticker onto another sticker to swap them, or tap two stickers. The glue from 1981 lets go easily. Too easily.' : 'You stop peeling. Drag the faces to turn them again.');
	}

	#makeLookSolved() {
		if (!this.#canStart()) {
			this.#explainBusy();
			return;
		}

		// Every sticker gets the color of the center of its face, which is the same as swapping all the wrong stickers, and the logo goes back on the white center.
		const facelets = readFacelets(this.#cubies);
		for (const sticker of facelets) {
			sticker.isLogo = false;
		}

		for (const [index, sticker] of facelets.entries()) {
			sticker.color = facelets[(Math.floor(index / 9) * 9) + 4].color;
		}

		// A visitor can have moved the white center sticker away, and then no center gets the logo.
		const whiteCenter = facelets.find((sticker, index) => index % 9 === 4 && sticker.color === 'white');
		if (whiteCenter) {
			whiteCenter.isLogo = true;
		}
		this.#sounds.peel();
		this.#afterStickerChange('You peel off every sticker that is wrong, and put each one where its color matches.');
	}

	#restick() {
		if (!this.#canStart()) {
			this.#explainBusy();
			return;
		}

		for (const cubie of this.#cubies) {
			for (const sticker of cubie.stickers) {
				sticker.color = sticker.original;
				sticker.isLogo = isHomeLogo(cubie, sticker);
			}
		}

		this.#sounds.stick();
		this.#afterStickerChange('You peel the stickers again, one by one, and put each one back on its own piece.');
	}

	#takeApart() {
		if (!this.#canStart()) {
			this.#explainBusy();
			return;
		}

		this.#mode = 'apart';
		this.#isPeeling = false;
		this.#selectedSticker = undefined;
		this.#highlight = undefined;
		this.#spin = undefined;
		this.#viewTween = undefined;
		this.#hideSolution();
		this.#isHelped = true;
		if (this.#timer.state === 'running' || this.#timer.state === 'armed') {
			this.#timer = {state: 'idle', start: 0, elapsed: 0};
		}

		const now = performance.now();
		const spots = tableSpots();
		const movable = shuffled(this.#cubies.filter(cubie => cubie.kind === 'corner' || cubie.kind === 'edge'));

		// The screwdriver pries out an edge first, as the corners are held by the edges.
		movable.sort((first, second) => (first.kind === 'edge' ? 0 : 1) - (second.kind === 'edge' ? 0 : 1));
		this.#pieces = new Map();
		for (const [index, cubie] of movable.entries()) {
			const from = this.#poseOf(cubie);
			// Most pieces land with a sticker up, like real pieces that roll until they lie flat.
			const upSticker = randomItem(cubie.stickers);
			const lying = randomItem(rotations.filter(rotation => roundVector(transform(rotation, upSticker.normal))[1] === 1));
			const to = {rotation: multiplyMatrices(rotationMatrix(1, Math.random() * Math.PI * 2), lying), position: spots[index % spots.length]};
			const isInstant = this.reducedMotion;
			this.#pieces.set(cubie, {from, to, pose: isInstant ? to : from, start: now + (index === 0 ? 300 : 700 + (index * 60)), duration: 650 + (Math.random() * 250), arc: 1 + (Math.random() * 1.5), hasLanded: isInstant});
		}

		this.#sounds.scrape();
		setTimeout(() => {
			this.#sounds.pop();
		}, 300);
		this.say('Pappa’s screwdriver goes in under an edge on top, and pop! The cube falls apart, and the pieces roll all over the table. Only the middle with the six centers stays together.');
		this.#refreshControls();
		this.#requestDraw();
	}

	#putTogether(isRandom) {
		if (this.#mode !== 'apart') {
			return;
		}

		if (this.#arePiecesMoving()) {
			this.say('Wait until the pieces stop rolling.');
			return;
		}

		const cubies = this.#cubies;
		const pieces = this.#pieces;
		const centers = cubies.filter(cubie => cubie.kind === 'center');
		const centersRotation = rotations.find(rotation => centers.every(cubie => isSameVector(roundVector(transform(rotation, cubie.home)), cubie.position)));
		const movable = cubies.filter(cubie => cubie.kind === 'corner' || cubie.kind === 'edge');
		const slotsOf = kind => movable.filter(cubie => cubie.kind === kind).map(cubie => roundVector(transform(centersRotation, cubie.home)));
		const freeSlots = {corner: isRandom ? shuffled(slotsOf('corner')) : slotsOf('corner'), edge: isRandom ? shuffled(slotsOf('edge')) : slotsOf('edge')};
		const now = performance.now();
		const finals = new Map();

		for (const [index, cubie] of shuffled(movable).entries()) {
			const piece = pieces.get(cubie);
			const slot = isRandom ? freeSlots[cubie.kind].pop() : roundVector(transform(centersRotation, cubie.home));
			const finalRotation = isRandom ? randomItem(rotations.filter(rotation => isSameVector(roundVector(transform(rotation, cubie.home)), slot))) : centersRotation;
			const turn = multiplyMatrices(finalRotation, transpose(rotationOfCubie(cubie)));
			finals.set(cubie, {slot, finalRotation});
			piece.from = piece.pose;
			piece.to = {rotation: multiplyMatrices(this.#view, turn), position: transform(this.#view, slot)};
			piece.start = now + (index * 70);
			piece.duration = 500 + (Math.random() * 200);
			piece.arc = 0.8 + Math.random();
			piece.hasLanded = this.reducedMotion;
			if (this.reducedMotion) {
				piece.pose = piece.to;
			}
		}

		pieces.onDone = () => {
			for (const [cubie, {slot, finalRotation}] of finals) {
				cubie.position = slot;
				for (const sticker of cubie.stickers) {
					sticker.normal = roundVector(transform(finalRotation, sticker.homeNormal));
					sticker.right = roundVector(transform(finalRotation, sticker.homeRight));
				}
			}

			this.#pieces = undefined;
			this.#mode = 'normal';
			this.#history = [];
			const analysis = analyzeCube(cubies);
			const moved = movedStickerCount(cubies);
			const stickers = moved > 0 ? ` But ${moved} stickers are still on the wrong pieces.` : '';
			if (!isRandom) {
				this.say(`Click, click, click. It is back together and solved, like new from the shop, and nobody has to know.${stickers}`);
			} else if (analysis.problem) {
				this.say(`Lillesøster put it back together, and it looks fine. But it can never be solved, because ${analysis.problem}. Only 1 of the 12 ways to put the pieces back can be solved.${stickers}`);
			} else {
				this.say(`Lillesøster put it back together, and by luck, it can be solved! Only 1 of the 12 ways to put the pieces back can be.${stickers}`);
			}

			this.#sounds.pop();
			this.#wasSolved = looksSolved(cubies);
			this.#saveCube();
			this.#refreshControls();
			this.#requestDraw();
		};

		this.say(isRandom ? 'Lillesøster takes the pieces and pushes them back in, wherever they fit …' : 'You put the pieces back, one by one, in their places …');
		this.#requestDraw();
		if (this.reducedMotion || !this.isVisible) {
			this.#updatePieces(performance.now() + 100_000);
		}
	}

	#showSolution(steps) {
		const {solution, nextStep, playSolution} = this.parts;
		this.#solution = {steps, next: 0};
		for (const [index, item] of this.querySelectorAll('[data-rubik-step]').entries()) {
			const step = steps[index];
			item.hidden = !step;
			delete item.dataset.state;
			if (step) {
				item.querySelector('span').textContent = step.title;
				item.querySelector('code').textContent = step.moves.join(' ');
			}
		}

		solution.hidden = false;
		nextStep.disabled = false;
		playSolution.disabled = false;
	}

	#solve() {
		if (!this.#canStart()) {
			this.#explainBusy();
			return;
		}

		this.#isPeeling = false;
		this.#selectedSticker = undefined;
		this.#refreshControls();
		if (looksSolved(this.#cubies) && movedStickerCount(this.#cubies) === 0) {
			this.say('It is already solved! Scramble it first.');
			return;
		}

		const result = solveCube(this.#cubies);
		if (result.problem) {
			this.#hideSolution();
			const advice = movedStickerCount(this.#cubies) > 0 ? 'Somebody moved the stickers. Put them back first.' : 'Take it apart, and put it back together the right way.';
			this.say(`The solver says: “This cube can not be solved, because ${result.problem}.” ${advice}`);
			this.#sounds.sad();
			return;
		}

		this.#snapHome();
		this.#showSolution(result.steps);
		const total = result.steps.flatMap(step => step.moves).filter(move => !/^[xyz]/u.test(move)).length;
		this.say(`The solver found ${total} moves, in the steps of the booklet. That is not short, but Pappa could follow it. Play it one step at a time, and watch the cube.`);
	}

	#playSteps(all) {
		const solution = this.#solution;
		if (!solution || !this.#canStart()) {
			return;
		}

		const {canvas, nextStep, playSolution} = this.parts;
		this.#snapHome();
		if (this.#timer.state === 'armed') {
			this.#timer = {state: 'idle', start: 0, elapsed: 0};
		}

		const last = all ? solution.steps.length : solution.next + 1;
		for (let index = solution.next; index < last; index++) {
			const moves = parseAlgorithm(solution.steps[index].moves.join(' ')).map(token => moveFromToken(token));
			for (const move of moves) {
				this.#queue.push({move, source: 'solver', duration: all ? 100 : 150, step: index});
			}
		}

		solution.next = last;
		nextStep.disabled = last >= solution.steps.length;
		playSolution.disabled = last >= solution.steps.length;
		// The buttons of the solver are far below the cube, so the cube comes into view first, and the turns start when it is there, instead of all at once off screen.
		if (this.isVisible) {
			this.#startNext();
		} else {
			canvas.scrollIntoView({behavior: this.reducedMotion ? 'auto' : 'smooth', block: 'nearest'});
		}

		this.#refreshControls();
	}

	#showPage(index) {
		const {previousPage, nextPage, pageNumber} = this.parts;
		const pages = this.querySelectorAll('[data-rubik-page]');
		this.#pageIndex = Math.max(0, Math.min(pages.length - 1, index));
		for (const [place, page] of pages.entries()) {
			page.hidden = place !== this.#pageIndex;
		}

		pageNumber.textContent = `${this.#pageIndex + 1} / ${pages.length}`;
		previousPage.disabled = this.#pageIndex === 0;
		nextPage.disabled = this.#pageIndex === pages.length - 1;
		this.#sounds.click();
	}
}
