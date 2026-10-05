// Klinkekuler on the 1999 page: the marbles of the school yard in Bergen, seen from above on the gravel, with rolling, friction, elastic collisions, and swirls that turn in 3D as the marbles roll. The visitor plays Hull, Ring, and Tårn against the kids of the school, for fun or for real, until the bell rings. The marble bag is kept in the browser. The canvas runs only while it is on screen and the tab is visible. Nothing makes a sound until the visitor turns on the sound.

// A phone has no keys to aim with, so the tips there only say what a finger does.
const coarsePointer = matchMedia('(pointer: coarse)');

const randomItem = items => items[Math.floor(Math.random() * items.length)];
const clamp = (value, minimum, maximum) => Math.min(Math.max(value, minimum), maximum);

// A random number with a bell curve around 0, for the aim of the kids, which is mostly close and sometimes far off.
const gaussian = () => {
	const first = 1 - Math.random();
	const second = Math.random();
	return Math.sqrt(-2 * Math.log(first)) * Math.cos(2 * Math.PI * second);
};

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

// A random number generator with a seed, so a marble has the same swirls on each frame, and the gravel the same stones on each visit.
const seededRandom = seed => () => {
	seed = (seed + 0x6D_2B_79_F5) | 0;
	let value = Math.imul(seed ^ (seed >>> 15), 1 | seed);
	value = (value + Math.imul(value ^ (value >>> 7), 61 | value)) ^ value;
	return ((value ^ (value >>> 14)) >>> 0) / 4_294_967_296;
};

// The kinds of marbles. A heavier marble hits harder: the steel ball is three times as heavy as glass of the same size.
const kinds = {
	clay: {name: 'Leirkule', plural: 'leirkuler', english: 'clay marble', radius: 10, density: 0.85, restitution: 0.75, speed: 1},
	glass: {name: 'Glasskule', plural: 'glasskuler', english: 'glass swirl', radius: 11, density: 1, restitution: 0.93, speed: 1},
	catseye: {name: 'Katteøye', plural: 'katteøyne', english: 'cat’s eye', radius: 11, density: 1, restitution: 0.93, speed: 1},
	big: {name: 'Kinakule', plural: 'kinakuler', english: 'big one', radius: 16, density: 1, restitution: 0.88, speed: 0.86},
	steel: {name: 'Stålkule', plural: 'stålkuler', english: 'steel ball bearing', radius: 10.5, density: 3.1, restitution: 0.9, speed: 0.92},
	king: {name: 'Kongen', plural: 'konger', english: 'the king', radius: 15, density: 1.15, restitution: 0.92, speed: 0.88},
};

const kindOrder = ['clay', 'glass', 'catseye', 'big', 'steel', 'king'];

// The marbles a kid puts in the game first: the cheap ones.
const stakeOrder = ['clay', 'glass', 'catseye', 'big'];

const describe = (kind, count) => `${count} ${count === 1 ? kinds[kind].name.toLowerCase() : kinds[kind].plural}`;

const describeAll = kindList => {
	const counts = new Map();
	for (const kind of kindList) {
		counts.set(kind, (counts.get(kind) ?? 0) + 1);
	}

	const parts = kindOrder.filter(kind => counts.has(kind)).map(kind => describe(kind, counts.get(kind)));
	return parts.length === 0 ? 'nothing' : parts.join(', ');
};

// The kids of the school yard, with their aim (how far off the angle can be, in radians) and how even their power is. Their lines are in Norwegian, with what they mean.
const kids = {
	trond: {
		name: 'Trond',
		aim: 0.035,
		power: 0.07,
		shooter: 'catseye',
		stake: ['glass', 'catseye', 'glass', 'big', 'glass'],
		sleeve: '#c0392b',
		towerLine: 330,
		fee: 'glass',
		lines: {
			start: [['Skal vi ta en runde?', 'Shall we play a round?']],
			myGood: [['Kult skudd!', 'Cool shot!'], ['Rått!', 'Wicked!']],
			myMiss: [['Nesten!', 'Almost!'], ['Uff, bom.', 'Oops, a miss.']],
			theirGood: [['Ja! Den satt!', 'Yes! Got it!']],
			theirMiss: [['Æsj, bom.', 'Ugh, missed.'], ['Gruset er skeivt!', 'The gravel is crooked!']],
			win: [['Godt spilt, uansett.', 'Good game, anyway.']],
			lose: [['Du er for god! Revansj i neste friminutt.', 'You are too good! Rematch next recess.']],
			accused: [['Hæ? Jeg jukser aldri.', 'Huh? I never cheat.']],
			tower: [['Én kule per skudd. Fra streken!', 'One marble per shot. From the line!']],
			towerLost: [['Æsj! Tårnet er ditt.', 'Ugh! The tower is yours.']],
			pay: [['Her, én glasskule.', 'Here, one glass marble.']],
		},
	},
	kevin: {
		name: 'Kevin',
		aim: 0.06,
		power: 0.1,
		shooter: 'glass',
		stake: ['clay', 'clay', 'glass', 'clay', 'clay'],
		sleeve: '#2f8f2f',
		towerLine: 410,
		fee: 'clay',
		lines: {
			start: [['Jeg er verdensmester i klinkekuler, bare så du vet det.', 'I am the world champion of marbles, just so you know.']],
			myGood: [['Flaks.', 'Luck.'], ['Det telte nesten ikke.', 'That almost did not count.']],
			myMiss: [['Hah! Bom!', 'Hah! Miss!']],
			theirGood: [['Sa jo det. Verdensmester.', 'Told you. World champion.']],
			theirMiss: [['Det var vinden.', 'It was the wind.'], ['Jeg nøs!', 'I sneezed!']],
			win: [['Verdensmester!', 'World champion!']],
			lose: [['Du jukset, sikkert.', 'You cheated, probably.']],
			accused: [['Selv juks!', 'You are the cheater!']],
			caught: [['Ok, ok… den lå der. Kanskje.', 'Okay, okay… it was there. Maybe.']],
			tower: [['Streken er her bak. Det er reglene.', 'The line is back here. Those are the rules.']],
			gum: [['Toppen falt ikke! Den må falle, ellers teller det ikke!', 'The top did not fall! It has to fall, or it does not count!']],
			gumCaught: [['…Det er ikke tyggis. Det er lim. Nei, vent.', '…That is not gum. It is glue. No, wait.']],
			towerLost: [['Det var flaks!', 'That was luck!']],
			pay: [['Her, en ekte glasskule. Den er bare litt matt.', 'Here, a real glass marble. It is just a bit dull.']],
		},
	},
	geir: {
		name: 'Store-Geir',
		aim: 0.018,
		power: 0.045,
		shooter: 'steel',
		stake: ['king', 'catseye', 'big', 'catseye', 'glass'],
		sleeve: '#222222',
		towerLine: 400,
		fee: undefined,
		lines: {
			start: [['Spiller du med meg, så spiller vi på ordentlig.', 'If you play with me, we play for real.']],
			myGood: [['Hmpf.', 'Hmph.']],
			myMiss: [['Småunge.', 'Little kid.']],
			theirGood: [['Selvfølgelig.', 'Of course.']],
			theirMiss: [['Det der skjedde ikke.', 'That did not happen.']],
			win: [['Takk for kulene.', 'Thanks for the marbles.']],
			lose: [['…', '…']],
			grab: [['Takk for kulene, småen!', 'Thanks for the marbles, little one!']],
			accused: [['Sier du at jeg jukser?', 'Are you saying I cheat?']],
			forReal: [['På lek? Det er for småunger. Vi spiller på ordentlig.', 'For fun? That is for little kids. We play for real.']],
			tower: [['To kuler per skudd. Kongen ligger på toppen.', 'Two marbles a shot. The king is on top.']],
			towerLost: [['…Den teller ikke. Neida, ta den.', '…That does not count. Nah, take it.']],
			pay: [['Jeg betaler etterpå.', 'I will pay later.']],
		},
	},
	sister: {
		name: 'Lillesøster',
		aim: 0.14,
		power: 0.28,
		shooter: 'big',
		stake: ['glass', 'clay', 'glass', 'glass', 'clay'],
		sleeve: '#ff7fbf',
		towerLine: 280,
		fee: undefined,
		lines: {
			start: [['Får jeg være med? Jeg kan reglene!', 'Can I play? I know the rules!']],
			myGood: [['Ikke så hardt!', 'Not so hard!']],
			myMiss: [['Hihi!', 'Teehee!']],
			theirGood: [['Jeg klarte det! Så du?', 'I did it! Did you see?']],
			theirMiss: [['Den ville ikke!', 'It did not want to!'], ['Den trillet feil vei!', 'It rolled the wrong way!']],
			win: [['Jeg vant! Jeg sier det til Mamma!', 'I won! I will tell Mamma!']],
			lose: [['Det er ikke rettferdig!', 'That is not fair!']],
			cry: [['Buhuuu! Jeg sier det til Mamma!', 'Boohoo! I am telling Mamma!']],
			accused: [['Jeg har ikke jukset! Du er dum!', 'I did not cheat! You are dumb!']],
			tower: [['Du må stå der! Og betale én!', 'You have to stand there! And pay one!']],
			towerLost: [['Neeei! Mitt tårn!', 'Nooo! My tower!']],
			pay: [['Her! Det er en knapp. Den er fin.', 'Here! It is a button. It is pretty.']],
		},
	},
	ola: {
		name: 'Ola fra 3A',
		aim: 0.1,
		power: 0.2,
		shooter: 'glass',
		stake: ['clay', 'glass', 'clay', 'clay', 'glass'],
		sleeve: '#3a7bd5',
		towerLine: 350,
		fee: 'glass',
		lines: {
			start: [['Kan jeg skyte på tårnet ditt?', 'Can I shoot at your tower?']],
			theirGood: [['JAAA!', 'YESSS!']],
			theirMiss: [['Åh nei.', 'Oh no.']],
			accused: [['Hva betyr juks?', 'What does cheat mean?']],
			pay: [['Her er én glasskule.', 'Here is one glass marble.']],
		},
	},
};

const teacherLines = {
	steel: ['Stålkuler er forbudt i skolegården! Den tar jeg.', 'Steel balls are not allowed in the school yard! I will take that.'],
	tattle: ['Hva er det nå, Sindre? Ikke sladre.', 'What is it now, Sindre? Do not tell tales.'],
	geir: ['Geir! Gi tilbake kulene, nå! Og stålkula di tar jeg.', 'Geir! Give the marbles back, now! And I will take your steel ball.'],
	kevin: ['Kevin! Spill ordentlig, ellers går du inn.', 'Kevin! Play fair, or you go inside.'],
	back: ['Her. Men ikke ta den med på skolen igjen!', 'Here. But do not bring it to school again!'],
	wait: ['Du får den etter friminuttet.', 'You get it after the recess.'],
};

// The recesses of a school day, by the minute of the day, and how long they are. Each shot takes a minute.
const recesses = [
	{name: 'Første friminutt', english: 'the first recess', start: (10 * 60) + 15, length: 15},
	{name: 'Storefri', english: 'the long lunch recess', start: (11 * 60) + 30, length: 30},
	{name: 'Siste friminutt', english: 'the last recess', start: (13 * 60) + 15, length: 15},
];

const formatTime = minutes => `${String(Math.floor(minutes / 60)).padStart(2, '0')}:${String(minutes % 60).padStart(2, '0')}`;
const startingBag = {clay: 4, glass: 16, catseye: 3, big: 1, steel: 1, king: 0};

// The places on the gravel.
const ring = {x: 320, y: 215, radius: 130};
const hole = {x: 320, y: 160, radius: 18};
const throwLine = 392;
const towerSpot = {x: 320, y: 150};
const puddles = [
	{x: 95, y: 250, radiusX: 55, radiusY: 28},
	{x: 545, y: 300, radiusX: 48, radiusY: 24},
	{x: 470, y: 70, radiusX: 36, radiusY: 18},
];

// The physics of the gravel, in pixels and seconds. A flick at full power rolls about 670 pixels on dry gravel, and much less in the mud.
const maximumSpeed = 700;
const drag = 0.3;
const dryFriction = 230;
const wetFriction = 400;
const puddleFriction = 1300;
const spinAcceleration = 95;

// MARK: The rotation of a marble

// A marble keeps its orientation as a rotation matrix, so its swirls turn the right way as it rolls. The canvas has x to the right and y down, so z points into the screen, and the side of a marble that faces the visitor is where z is below 0.
const rotationMatrix = (x, y, z, angle) => {
	const cos = Math.cos(angle);
	const sin = Math.sin(angle);
	const rest = 1 - cos;
	return [
		(rest * x * x) + cos, (rest * x * y) - (sin * z), (rest * x * z) + (sin * y),
		(rest * x * y) + (sin * z), (rest * y * y) + cos, (rest * y * z) - (sin * x),
		(rest * x * z) - (sin * y), (rest * y * z) + (sin * x), (rest * z * z) + cos,
	];
};

const multiply = (first, second) => {
	const result = Array.from({length: 9}, () => 0);
	for (let row = 0; row < 3; row++) {
		for (let column = 0; column < 3; column++) {
			let sum = 0;
			for (let index = 0; index < 3; index++) {
				sum += first[(row * 3) + index] * second[(index * 3) + column];
			}

			result[(row * 3) + column] = sum;
		}
	}

	return result;
};

const transform = (matrix, [x, y, z]) => [
	(matrix[0] * x) + (matrix[1] * y) + (matrix[2] * z),
	(matrix[3] * x) + (matrix[4] * y) + (matrix[5] * z),
	(matrix[6] * x) + (matrix[7] * y) + (matrix[8] * z),
];

// Small errors add up over many turns, so the matrix is made a clean rotation again now and then.
const orthonormalize = matrix => {
	const first = matrix.slice(0, 3);
	const firstLength = Math.hypot(...first);
	const firstUnit = first.map(value => value / firstLength);
	const second = matrix.slice(3, 6);
	const dot = (second[0] * firstUnit[0]) + (second[1] * firstUnit[1]) + (second[2] * firstUnit[2]);
	const secondOrthogonal = second.map((value, index) => value - (dot * firstUnit[index]));
	const secondLength = Math.hypot(...secondOrthogonal);
	const secondUnit = secondOrthogonal.map(value => value / secondLength);
	const third = [
		(firstUnit[1] * secondUnit[2]) - (firstUnit[2] * secondUnit[1]),
		(firstUnit[2] * secondUnit[0]) - (firstUnit[0] * secondUnit[2]),
		(firstUnit[0] * secondUnit[1]) - (firstUnit[1] * secondUnit[0]),
	];
	return [...firstUnit, ...secondUnit, ...third];
};

const randomOrientation = random => {
	const axis = [random() - 0.5, random() - 0.5, random() - 0.5];
	const length = Math.hypot(...axis) || 1;
	return rotationMatrix(axis[0] / length, axis[1] / length, axis[2] / length, random() * Math.PI * 2);
};

// A marble that rolls without slipping turns around the axis that lies flat on the ground, across its path, by the distance over its radius.
const roll = (marble, deltaX, deltaY) => {
	const distance = Math.hypot(deltaX, deltaY);
	if (distance < 1e-6) {
		return;
	}

	marble.orientation = multiply(rotationMatrix(deltaY / distance, -deltaX / distance, 0, distance / marble.radius), marble.orientation);
	marble.turns++;
	if (marble.turns % 120 === 0) {
		marble.orientation = orthonormalize(marble.orientation);
	}
};

// MARK: The marbles

let nextSeed = Math.floor(Math.random() * 100_000);

const makeMarble = (kind, owner, x, y, seed = nextSeed++) => {
	const {radius, density} = kinds[kind];
	return {
		kind,
		owner,
		x,
		y,
		vx: 0,
		vy: 0,
		radius,
		mass: density * ((radius / 11) ** 3),
		seed,
		orientation: randomOrientation(seededRandom(seed)),
		turns: 0,
		spin: 0,
		mud: 0,
		isInHole: false,
		holeSpot: undefined,
		sink: 1,
		isTower: false,
		isTop: false,
		isGlued: false,
		isShooter: false,
		path: [],
	};
};

const glassPalettes = [
	{tint: [170, 220, 255], ribbons: ['#e8302a', '#ffd400', '#ffffff']},
	{tint: [190, 255, 210], ribbons: ['#1f5fe0', '#ffffff', '#1f5fe0']},
	{tint: [255, 236, 196], ribbons: ['#ff7a00', '#7a2be2', '#ffd400']},
	{tint: [210, 235, 255], ribbons: ['#18a44a', '#ffeb3b', '#18a44a']},
	{tint: [230, 220, 255], ribbons: ['#ff3f8e', '#00b3c7', '#ffffff']},
	{tint: [200, 250, 250], ribbons: ['#c0122b', '#0f3fa0', '#f5f5f5']},
];

const clayColors = ['#b5653a', '#c99a4a', '#6f7fa0', '#8d9a5b', '#9a5a6a'];
const catseyeColors = [['#ff3b30', '#ffd60a'], ['#0a84ff', '#30d158'], ['#ff9f0a', '#ffffff'], ['#bf5af2', '#64d2ff']];
const bandColors = [['#d6242f', '#1d4fbf'], ['#1d8f4a', '#f2a900'], ['#7b2fbf', '#e85d9e']];

// A ribbon inside a swirl marble: it winds around the axis from one pole to the other, where all the ribbons meet, like where the glass was cut from the rod.
const helix = (phase, twist, spread) => Array.from({length: 22}, (_, index) => {
	const position = -0.92 + (1.84 * index / 21);
	const reach = Math.sqrt(1 - (position * position)) * spread;
	const angle = phase + (twist * position);
	return [Math.cos(angle) * reach, Math.sin(angle) * reach, position * 0.94];
});

const surfacePoint = random => {
	const z = (random() * 2) - 1;
	const angle = random() * Math.PI * 2;
	const reach = Math.sqrt(1 - (z * z));
	return [Math.cos(angle) * reach, Math.sin(angle) * reach, z];
};

const patterns = new Map();

// The look of a marble, made once from its seed, in the space of the marble, so it turns with it.
const patternFor = marble => {
	const key = `${marble.kind}:${marble.seed}`;
	if (patterns.has(key)) {
		return patterns.get(key);
	}

	const random = seededRandom((marble.seed * 7919) + 13);
	const pattern = {
		mud: Array.from({length: 16}, () => ({point: surfacePoint(random), size: 0.12 + (random() * 0.18)})),
	};

	if (marble.kind === 'glass') {
		const palette = glassPalettes[Math.floor(random() * glassPalettes.length)];
		pattern.tint = palette.tint;
		const twist = 1.4 + (random() * 1.8);
		const phase = random() * Math.PI * 2;
		pattern.ribbons = palette.ribbons.map((color, index) => ({color, width: 0.2 + (random() * 0.1), points: helix(phase + (index * Math.PI * 2 / 3), twist, 0.55 + (random() * 0.15))}));
	} else if (marble.kind === 'king') {
		pattern.tint = [255, 196, 80];
		const twist = 2.6;
		const colors = ['#b0122b', '#1a3fb0', '#ffffff', '#b0122b', '#1a3fb0'];
		pattern.ribbons = colors.map((color, index) => ({color, width: 0.16, points: helix(index * Math.PI * 2 / 5, twist, 0.68)}));
		pattern.sparkles = Array.from({length: 30}, () => {
			const point = surfacePoint(random);
			const depth = 0.3 + (random() * 0.55);
			return point.map(value => value * depth);
		});
	} else if (marble.kind === 'catseye') {
		const colors = catseyeColors[Math.floor(random() * catseyeColors.length)];
		const count = random() < 0.5 ? 3 : 4;
		const offset = random() * Math.PI;
		pattern.tint = [215, 240, 255];
		pattern.petals = Array.from({length: count}, (_, index) => {
			const angle = offset + (index * Math.PI / count);
			const cos = Math.cos(angle);
			const sin = Math.sin(angle);
			const outline = [];
			for (let step = 0; step <= 16; step++) {
				const along = -0.82 + (1.64 * step / 16);
				const half = 0.4 * (1 - ((along / 0.82) ** 2));
				outline.push([along * cos, along * sin, half]);
			}

			for (let step = 16; step >= 0; step--) {
				const along = -0.82 + (1.64 * step / 16);
				const half = 0.4 * (1 - ((along / 0.82) ** 2));
				outline.push([along * cos, along * sin, -half]);
			}

			return {color: colors[index % 2], outline};
		});
	} else if (marble.kind === 'clay') {
		pattern.color = clayColors[Math.floor(random() * clayColors.length)];
		pattern.speckles = Array.from({length: 28}, () => ({point: surfacePoint(random), size: 0.05 + (random() * 0.07), isLight: random() < 0.4}));
	} else if (marble.kind === 'big') {
		const colors = bandColors[Math.floor(random() * bandColors.length)];
		pattern.bands = [-0.62, -0.3, 0, 0.3, 0.62].map((z, index) => {
			const reach = Math.sqrt(1 - (z * z));
			return {
				color: colors[index % 2],
				width: index === 2 ? 0.16 : 0.09,
				points: Array.from({length: 33}, (_, step) => {
					const angle = step / 32 * Math.PI * 2;
					return [Math.cos(angle) * reach, Math.sin(angle) * reach, z];
				}),
			};
		});
	}

	patterns.set(key, pattern);
	return pattern;
};

// MARK: The gravel

const hexToRgb = hex => [Number.parseInt(hex.slice(1, 3), 16), Number.parseInt(hex.slice(3, 5), 16), Number.parseInt(hex.slice(5, 7), 16)];
const rgba = ([red, green, blue], alpha = 1) => `rgba(${Math.round(red)}, ${Math.round(green)}, ${Math.round(blue)}, ${alpha})`;
const shade = (color, amount) => color.map(value => clamp(value * amount, 0, 255));

const pebbleColors = ['#9b9488', '#b8b0a2', '#7d776d', '#c9bfae', '#8d8172', '#a59a8a', '#6e6a64', '#d6ccb9', '#a88f78', '#8f7a6a'].map(hexToRgb);

// The gravel of the school yard, drawn once for dry weather and once for rain, with the same stones in the same places. Bergen gravel is gray and pink granite.
const makeGround = (isWet, {width, height}) => {
	const ground = document.createElement('canvas');
	ground.width = width;
	ground.height = height;
	const context = ground.getContext('2d');
	const random = seededRandom(1999);
	context.fillStyle = isWet ? '#76674f' : '#b3a68b';
	context.fillRect(0, 0, width, height);

	// Soft patches of sand and dirt.
	for (let index = 0; index < 40; index++) {
		const x = random() * width;
		const y = random() * height;
		const radius = 30 + (random() * 70);
		const gradient = context.createRadialGradient(x, y, 0, x, y, radius);
		const isLight = random() < 0.5;
		gradient.addColorStop(0, isLight ? (isWet ? 'rgba(150, 130, 100, 0.25)' : 'rgba(220, 205, 170, 0.35)') : (isWet ? 'rgba(40, 30, 20, 0.3)' : 'rgba(120, 100, 70, 0.25)'));
		gradient.addColorStop(1, 'rgba(0, 0, 0, 0)');
		context.fillStyle = gradient;
		context.fillRect(x - radius, y - radius, radius * 2, radius * 2);
	}

	// The grain of the sand, pixel by pixel.
	const image = context.getImageData(0, 0, width, height);
	for (let index = 0; index < image.data.length; index += 4) {
		const noise = (random() - 0.5) * 40;
		image.data[index] = clamp(image.data[index] + noise, 0, 255);
		image.data[index + 1] = clamp(image.data[index + 1] + noise, 0, 255);
		image.data[index + 2] = clamp(image.data[index + 2] + noise, 0, 255);
	}

	context.putImageData(image, 0, 0);

	// The stones, each with a shadow and a light side.
	for (let index = 0; index < 2200; index++) {
		const x = random() * width;
		const y = random() * height;
		const size = 1.2 + ((random() ** 2) * 4.5);
		const angle = random() * Math.PI;
		const stretch = 0.6 + (random() * 0.4);
		const color = shade(pebbleColors[Math.floor(random() * pebbleColors.length)], isWet ? 0.62 : 1);
		context.save();
		context.translate(x, y);
		context.rotate(angle);
		context.fillStyle = 'rgba(30, 20, 10, 0.35)';
		context.beginPath();
		context.ellipse(0.8, 1, size, size * stretch, 0, 0, Math.PI * 2);
		context.fill();
		const gradient = context.createRadialGradient(-size * 0.3, -size * 0.3, 0, 0, 0, size);
		gradient.addColorStop(0, rgba(shade(color, isWet ? 1.35 : 1.18)));
		gradient.addColorStop(1, rgba(shade(color, 0.85)));
		context.fillStyle = gradient;
		context.beginPath();
		context.ellipse(0, 0, size, size * stretch, 0, 0, Math.PI * 2);
		context.fill();
		if (isWet && size > 2) {
			context.fillStyle = 'rgba(255, 255, 255, 0.55)';
			context.beginPath();
			context.arc(-size * 0.35, -size * 0.3, size * 0.22, 0, Math.PI * 2);
			context.fill();
		}

		context.restore();
	}

	drawLitter(context, isWet);
	return ground;
};

// What lies in every school yard: the cap of a bottle of Solo, the wrapper of a Hubba Bubba, a birch leaf from last fall, and a twig.
const drawLitter = (context, isWet) => {
	context.save();
	context.translate(64, 404);
	context.fillStyle = 'rgba(0, 0, 0, 0.3)';
	context.beginPath();
	context.arc(1.5, 2, 10, 0, Math.PI * 2);
	context.fill();
	context.fillStyle = isWet ? '#d65f00' : '#ff7a00';
	context.beginPath();
	for (let index = 0; index < 42; index++) {
		const angle = index / 42 * Math.PI * 2;
		const radius = index % 2 === 0 ? 10 : 8.8;
		context.lineTo(Math.cos(angle) * radius, Math.sin(angle) * radius);
	}

	context.closePath();
	context.fill();
	context.fillStyle = '#ffd34d';
	context.beginPath();
	context.arc(0, 0, 6.5, 0, Math.PI * 2);
	context.fill();
	context.fillStyle = '#c4002b';
	context.font = 'bold 5px Arial, sans-serif';
	context.textAlign = 'center';
	context.textBaseline = 'middle';
	context.fillText('Solo', 0, 0.5);
	context.restore();

	context.save();
	context.translate(586, 64);
	context.rotate(-0.5);
	context.fillStyle = 'rgba(0, 0, 0, 0.25)';
	context.fillRect(-12, -5, 28, 13);
	context.fillStyle = isWet ? '#d9739f' : '#ff8fc0';
	context.fillRect(-14, -7, 28, 13);
	context.strokeStyle = '#ffffff';
	context.lineWidth = 1;
	context.beginPath();
	for (let index = 0; index <= 8; index++) {
		context.lineTo(-13 + (index * 3.25), index % 2 === 0 ? -5 : -3);
	}

	context.stroke();
	context.fillStyle = '#ffffff';
	context.font = 'bold 5px Arial, sans-serif';
	context.textAlign = 'center';
	context.fillText('HUBBA BUBBA', 0, 3);
	context.restore();

	context.save();
	context.translate(44, 66);
	context.rotate(0.7);
	context.fillStyle = isWet ? '#8a7a1f' : '#c9b13a';
	context.beginPath();
	context.ellipse(0, 0, 13, 9, 0, 0, Math.PI * 2);
	context.fill();
	context.strokeStyle = 'rgba(90, 70, 10, 0.7)';
	context.lineWidth = 1;
	context.beginPath();
	context.moveTo(-16, 0);
	context.lineTo(12, 0);
	for (let index = -2; index <= 2; index++) {
		context.moveTo(index * 4, 0);
		context.lineTo((index * 4) + 4, -6);
		context.moveTo(index * 4, 0);
		context.lineTo((index * 4) + 4, 6);
	}

	context.stroke();
	context.restore();

	context.save();
	context.translate(596, 380);
	context.strokeStyle = isWet ? '#3e2a18' : '#5a3d22';
	context.lineCap = 'round';
	context.lineWidth = 3;
	context.beginPath();
	context.moveTo(-26, 12);
	context.lineTo(20, -10);
	context.moveTo(-2, 1);
	context.lineTo(4, 12);
	context.stroke();
	context.restore();
};

const otherSide = side => (side === 'me' ? 'them' : 'me');
const distanceToHole = marble => Math.hypot(marble.x - hole.x, marble.y - hole.y);

// MARK: Shooting

const speedFor = (marble, power) => power * maximumSpeed * kinds[marble.kind ?? 'glass'].speed;

// The edge of the ring along a direction from a point inside it.
const distanceToEdge = (x, y, directionX, directionY) => {
	const offsetX = x - ring.x;
	const offsetY = y - ring.y;
	const along = (offsetX * directionX) + (offsetY * directionY);
	const rest = (offsetX * offsetX) + (offsetY * offsetY) - (ring.radius * ring.radius);
	return -along + Math.sqrt(Math.max((along * along) - rest, 0));
};

// MARK: The trade stand

const tradeOffers = [
	{kid: 'trond', give: {glass: 3}, get: {catseye: 1}, line: ['Tre glass for et katteøye? Rettferdig.', 'Three glass ones for a cat’s eye? Fair.']},
	{kid: 'trond', give: {big: 1}, get: {glass: 5}, line: ['Fem glass for kinakula di?', 'Five glass ones for your big one?']},
	{kid: 'trond', give: {catseye: 2}, get: {big: 1}, line: ['To katteøyne for en kinakule.', 'Two cat’s eyes for a big one.']},
	{kid: 'kevin', give: {catseye: 1}, get: {clay: 4}, line: ['Fire diamantkuler for katteøyet ditt!', 'Four diamond marbles for your cat’s eye!'], reveal: 'The “diamond marbles” are four clay marbles. Kevin is already gone.'},
	{kid: 'kevin', give: {glass: 6}, get: {steel: 1}, real: {clay: 1}, line: ['Ekte stålkule! Bare seks glass!', 'A real steel ball! Only six glass ones!'], reveal: 'The “steel ball” is a clay marble that Kevin painted with silver paint. It comes off on your fingers.'},
	{kid: 'kevin', give: {glass: 2}, get: {glass: 3}, line: ['Tre for to. Seriøst, ingen juks.', 'Three for two. Seriously, no tricks.'], reveal: 'He really meant it. Weird.'},
	{kid: 'geir', give: {glass: 12}, get: {steel: 1}, line: ['Tolv glass. Ikke pruting.', 'Twelve glass ones. No haggling.']},
	{kid: 'geir', give: {steel: 1, big: 2, catseye: 4}, get: {king: 1}, line: ['Kongen. For alt du har.', 'The king. For everything you have.']},
	{kid: 'sister', give: {clay: 1}, get: {big: 1}, line: ['Jeg vil ha den brune! Du kan få den store.', 'I want the brown one! You can have the big one.']},
	{kid: 'sister', give: {glass: 1}, get: {catseye: 1}, line: ['Den er blå! Jeg vil ha den!', 'It is blue! I want it!']},
	{kid: 'ola', give: {catseye: 1}, get: {glass: 4}, line: ['Fire for ett katteøye?', 'Four for one cat’s eye?']},
];

const expand = counts => Object.entries(counts).flatMap(([kind, count]) => Array.from({length: count}, () => kind));

// MARK: Drawing the marbles

const drawShadow = (context, marble, x, y, radius) => {
	const gradient = context.createRadialGradient(x + (radius * 0.45), y + (radius * 0.55), radius * 0.2, x + (radius * 0.45), y + (radius * 0.55), radius * 1.3);
	gradient.addColorStop(0, 'rgba(20, 12, 4, 0.42)');
	gradient.addColorStop(1, 'rgba(20, 12, 4, 0)');
	context.fillStyle = gradient;
	context.beginPath();
	context.arc(x + (radius * 0.45), y + (radius * 0.55), radius * 1.3, 0, Math.PI * 2);
	context.fill();

	// Glass bends the sunlight into a bright spot inside the shadow.
	const pattern = patternFor(marble);
	if (pattern.tint) {
		const spot = context.createRadialGradient(x + (radius * 0.62), y + (radius * 0.7), 0, x + (radius * 0.62), y + (radius * 0.7), radius * 0.55);
		spot.addColorStop(0, rgba(shade(pattern.tint, 1.1), marble.kind === 'king' ? 0.75 : 0.55));
		spot.addColorStop(1, rgba(pattern.tint, 0));
		context.fillStyle = spot;
		context.beginPath();
		context.arc(x + (radius * 0.62), y + (radius * 0.7), radius * 0.55, 0, Math.PI * 2);
		context.fill();
	}
};

const drawRibbons = (context, ribbons, matrix, x, y, radius) => {
	const segments = [];
	for (const ribbon of ribbons) {
		const points = ribbon.points.map(point => transform(matrix, point));
		for (let index = 0; index < points.length - 1; index++) {
			const from = points[index];
			const to = points[index + 1];
			segments.push({from, to, depth: (from[2] + to[2]) / 2, color: ribbon.color, width: ribbon.width});
		}
	}

	// The far side first, seen dimmer through the glass.
	segments.sort((first, second) => second.depth - first.depth);
	context.lineCap = 'round';
	for (const segment of segments) {
		context.globalAlpha = segment.depth > 0 ? 0.5 : 1;
		context.strokeStyle = segment.color;
		context.lineWidth = segment.width * radius * (1 - (segment.depth * 0.25));
		context.beginPath();
		context.moveTo(x + (segment.from[0] * radius), y + (segment.from[1] * radius));
		context.lineTo(x + (segment.to[0] * radius), y + (segment.to[1] * radius));
		context.stroke();
	}

	context.globalAlpha = 1;
};

// Dots on the surface of a marble, only on the side that faces up, smaller toward the edge.
const drawSurfaceDots = (context, dots, matrix, x, y, radius, color) => {
	for (const dot of dots) {
		const [pointX, pointY, pointZ] = transform(matrix, dot.point);
		if (pointZ > 0) {
			continue;
		}

		context.fillStyle = typeof color === 'function' ? color(dot) : color;
		context.beginPath();
		context.ellipse(x + (pointX * radius), y + (pointY * radius), dot.size * radius, dot.size * radius * Math.max(-pointZ, 0.25), Math.atan2(pointY, pointX), 0, Math.PI * 2);
		context.fill();
	}
};

const drawMarble = (context, marble, x, y, radius, ground) => {
	const pattern = patternFor(marble);
	const matrix = marble.orientation;
	context.save();
	context.beginPath();
	context.arc(x, y, radius, 0, Math.PI * 2);
	context.clip();

	if (pattern.tint) {
		// The gravel under the marble shows through the glass, upside down and bigger, like through a lens.
		if (ground) {
			context.save();
			context.translate(x, y);
			context.scale(-1, -1);
			context.drawImage(ground, x - (radius * 0.75), y - (radius * 0.75), radius * 1.5, radius * 1.5, -radius, -radius, radius * 2, radius * 2);
			context.restore();
		} else {
			context.fillStyle = '#d9d2c0';
			context.fillRect(x - radius, y - radius, radius * 2, radius * 2);
		}

		const glass = context.createRadialGradient(x - (radius * 0.3), y - (radius * 0.3), radius * 0.1, x, y, radius);
		const clearness = marble.kind === 'catseye' ? 0.2 : 0.35;
		glass.addColorStop(0, rgba(pattern.tint, clearness));
		glass.addColorStop(0.7, rgba(pattern.tint, clearness + 0.2));
		glass.addColorStop(1, rgba(shade(pattern.tint, 0.55), 0.9));
		context.fillStyle = glass;
		context.fillRect(x - radius, y - radius, radius * 2, radius * 2);

		if (pattern.ribbons) {
			drawRibbons(context, pattern.ribbons, matrix, x, y, radius);
		}

		if (pattern.petals) {
			const petals = pattern.petals.map(petal => {
				const points = petal.outline.map(point => transform(matrix, point));
				let depth = 0;
				for (const point of points) {
					depth += point[2];
				}

				return {color: petal.color, points, depth: depth / points.length};
			}).sort((first, second) => second.depth - first.depth);
			for (const petal of petals) {
				context.fillStyle = petal.color;
				context.strokeStyle = 'rgba(0, 0, 0, 0.35)';
				context.lineWidth = Math.max(0.6, radius * 0.04);
				context.beginPath();
				for (const point of petal.points) {
					context.lineTo(x + (point[0] * radius), y + (point[1] * radius));
				}

				context.closePath();
				context.globalAlpha = 0.92;
				context.fill();
				context.stroke();
			}

			context.globalAlpha = 1;
		}

		if (pattern.sparkles) {
			for (const [index, point] of pattern.sparkles.entries()) {
				const [pointX, pointY, pointZ] = transform(matrix, point);
				const twinkle = Math.abs(Math.sin((index * 1.7) + (pointX * 6) + (pointY * 4)));
				context.fillStyle = `rgba(255, 250, 210, ${(pointZ > 0 ? 0.35 : 0.9) * twinkle})`;
				context.beginPath();
				context.arc(x + (pointX * radius), y + (pointY * radius), radius * 0.05, 0, Math.PI * 2);
				context.fill();
			}
		}

		// The glass gathers the light on the side away from the sun.
		const inner = context.createRadialGradient(x + (radius * 0.35), y + (radius * 0.4), 0, x + (radius * 0.35), y + (radius * 0.4), radius * 0.6);
		inner.addColorStop(0, 'rgba(255, 255, 255, 0.45)');
		inner.addColorStop(1, 'rgba(255, 255, 255, 0)');
		context.fillStyle = inner;
		context.fillRect(x - radius, y - radius, radius * 2, radius * 2);
	} else if (marble.kind === 'steel') {
		// A mirror ball: the gray sky of Bergen in the middle, the houses around it, and the gravel at the edge.
		const steel = context.createRadialGradient(x - (radius * 0.2), y - (radius * 0.22), 0, x, y, radius);
		steel.addColorStop(0, '#f4f7fa');
		steel.addColorStop(0.35, '#c9d1da');
		steel.addColorStop(0.62, '#79818b');
		steel.addColorStop(0.78, '#3d4249');
		steel.addColorStop(0.9, '#8a7a62');
		steel.addColorStop(1, '#3a3128');
		context.fillStyle = steel;
		context.fillRect(x - radius, y - radius, radius * 2, radius * 2);
		context.fillStyle = 'rgba(30, 30, 40, 0.3)';
		context.beginPath();
		context.ellipse(x + (radius * 0.12), y + (radius * 0.08), radius * 0.16, radius * 0.2, 0, 0, Math.PI * 2);
		context.fill();
	} else if (marble.kind === 'clay') {
		const color = hexToRgb(pattern.color);
		const clay = context.createRadialGradient(x - (radius * 0.35), y - (radius * 0.35), 0, x, y, radius);
		clay.addColorStop(0, rgba(shade(color, 1.3)));
		clay.addColorStop(0.6, rgba(color));
		clay.addColorStop(1, rgba(shade(color, 0.55)));
		context.fillStyle = clay;
		context.fillRect(x - radius, y - radius, radius * 2, radius * 2);
		drawSurfaceDots(context, pattern.speckles, matrix, x, y, radius, dot => (dot.isLight ? rgba(shade(color, 1.5), 0.6) : rgba(shade(color, 0.5), 0.7)));
	} else if (marble.kind === 'big') {
		const china = context.createRadialGradient(x - (radius * 0.35), y - (radius * 0.35), 0, x, y, radius);
		china.addColorStop(0, '#ffffff');
		china.addColorStop(0.65, '#f1ead8');
		china.addColorStop(1, '#b9ae95');
		context.fillStyle = china;
		context.fillRect(x - radius, y - radius, radius * 2, radius * 2);
		context.lineCap = 'round';
		for (const band of pattern.bands) {
			const points = band.points.map(point => transform(matrix, point));
			context.strokeStyle = band.color;
			for (let index = 0; index < points.length - 1; index++) {
				const from = points[index];
				const to = points[index + 1];
				if (from[2] > 0.05 || to[2] > 0.05) {
					continue;
				}

				context.lineWidth = band.width * radius * Math.max(-((from[2] + to[2]) / 2), 0.3);
				context.beginPath();
				context.moveTo(x + (from[0] * radius), y + (from[1] * radius));
				context.lineTo(x + (to[0] * radius), y + (to[1] * radius));
				context.stroke();
			}
		}
	}

	if (marble.mud > 0.05) {
		drawSurfaceDots(context, pattern.mud, matrix, x, y, radius, `rgba(80, 55, 30, ${Math.min(marble.mud, 0.85)})`);
	}

	// The edge of the ball is darker, as it curves away.
	const rim = context.createRadialGradient(x, y, radius * 0.7, x, y, radius);
	rim.addColorStop(0, 'rgba(0, 0, 0, 0)');
	rim.addColorStop(1, marble.kind === 'clay' ? 'rgba(0, 0, 0, 0.2)' : 'rgba(0, 0, 0, 0.32)');
	context.fillStyle = rim;
	context.fillRect(x - radius, y - radius, radius * 2, radius * 2);
	context.restore();

	// The shine of the sun, from the top left. Clay is matte.
	const isMatte = marble.kind === 'clay';
	context.save();
	context.translate(x - (radius * 0.38), y - (radius * 0.42));
	context.rotate(-0.7);
	context.scale(1, 0.62);
	const shine = context.createRadialGradient(0, 0, 0, 0, 0, radius * 0.4);
	shine.addColorStop(0, `rgba(255, 255, 255, ${isMatte ? 0.35 : 0.95})`);
	shine.addColorStop(1, 'rgba(255, 255, 255, 0)');
	context.fillStyle = shine;
	context.beginPath();
	context.arc(0, 0, radius * 0.4, 0, Math.PI * 2);
	context.fill();
	context.restore();
	if (!isMatte) {
		context.fillStyle = 'rgba(255, 255, 255, 0.95)';
		context.beginPath();
		context.arc(x - (radius * 0.42), y - (radius * 0.45), radius * 0.1, 0, Math.PI * 2);
		context.fill();
		context.strokeStyle = 'rgba(255, 255, 255, 0.35)';
		context.lineWidth = radius * 0.08;
		context.beginPath();
		context.arc(x, y, radius * 0.84, Math.PI * 0.15, Math.PI * 0.55);
		context.stroke();
	}

	context.strokeStyle = 'rgba(0, 0, 0, 0.4)';
	context.lineWidth = Math.max(0.7, radius * 0.06);
	context.beginPath();
	context.arc(x, y, radius, 0, Math.PI * 2);
	context.stroke();
};

const ringPath = Array.from({length: 121}, (_, index) => {
	const angle = index / 120 * Math.PI * 2;
	const wobble = (Math.sin(angle * 5) * 1.6) + (Math.sin(angle * 11) * 0.8);
	return [ring.x + (Math.cos(angle) * (ring.radius + wobble)), ring.y + (Math.sin(angle) * (ring.radius + wobble))];
});

const linePath = y => Array.from({length: 53}, (_, index) => [50 + (index * 10), y + (Math.sin(index * 0.9) * 1.2)]);

const roundedRectangle = (context, x, y, rectangleWidth, rectangleHeight, radius) => {
	context.beginPath();
	context.roundRect(x, y, rectangleWidth, rectangleHeight, radius);
};

export default class extends GeoCitiesElement {
	#yard;
	#width;
	#height;
	#gameButtons;
	#opponentButtons;
	#spinButtons;

	// What is kept between visits: the bag, the shooter, the drawer of the teacher, the score, and the stake of a game for real that was still going, which goes back in the bag on the next visit, as the game itself is not kept.
	#bag;

	#shooterKind;
	#drawer;
	#wins;
	#losses;
	#day;
	#gameId;
	#opponentId;
	#isForReal;
	#recess;

	#persist() {
		const inPlay = this.#match?.isForReal && this.#match.phase !== 'over' ? this.#match.stake.me : [];
		this.store('state', {bag: this.#bag, shooter: this.#shooterKind, drawer: this.#drawer, wins: this.#wins, losses: this.#losses, day: this.#day, game: this.#gameId, opponent: this.#opponentId, isForReal: this.#isForReal, recess: this.#recess.index, inPlay});
	}

	#spin = 0;
	#isRaining = false;
	#isSoundOn = false;

	#isInPuddle(x, y) {
		return this.#isRaining && puddles.some(puddle => (((x - puddle.x) / puddle.radiusX) ** 2) + (((y - puddle.y) / puddle.radiusY) ** 2) < 1);
	}

	#frictionAt(x, y) {
		if (this.#isInPuddle(x, y)) {
			return puddleFriction;
		}

		return this.#isRaining ? wetFriction : dryFriction;
	}

	#captureSpeed() {
		return this.#isRaining ? 240 : 200;
	}

	#grounds = {};

	#groundFor(isWet) {
		const {canvas} = this.parts;
		this.#grounds[isWet] ??= makeGround(isWet, canvas);
		return this.#grounds[isWet];
	}

	// MARK: The sound

	// The sound, made in the browser. It plays only while the sound is on.
	#noiseBuffer;

	// The audio while the sound is on, or `undefined`.
	get #runningSound() {
		const sound = this.#isSoundOn ? this.sound() : undefined;
		return sound?.context.state === 'running' ? sound : undefined;
	}

	#beep(frequency, duration = 0.1, {type = 'sine', volume = 0.05, when = 0, slideTo} = {}) {
		const sound = this.#runningSound;
		if (!sound) {
			return;
		}

		const {context, output} = sound;
		const start = context.currentTime + when;
		const oscillator = new OscillatorNode(context, {type, frequency});
		if (slideTo) {
			oscillator.frequency.exponentialRampToValueAtTime(slideTo, start + duration);
		}

		const gain = new GainNode(context, {gain: 0});
		gain.gain.setValueAtTime(0, start);
		gain.gain.linearRampToValueAtTime(volume, start + 0.003);
		gain.gain.exponentialRampToValueAtTime(0.0001, start + duration);
		oscillator.connect(gain).connect(output);
		oscillator.start(start);
		oscillator.stop(start + duration + 0.02);
	}

	#noise(duration, {volume = 0.1, frequency = 1000, type = 'bandpass', when = 0} = {}) {
		const sound = this.#runningSound;
		if (!sound) {
			return;
		}

		const {context, output} = sound;
		if (!this.#noiseBuffer) {
			this.#noiseBuffer = new AudioBuffer({length: context.sampleRate, sampleRate: context.sampleRate});
			const data = this.#noiseBuffer.getChannelData(0);
			for (let index = 0; index < data.length; index++) {
				data[index] = (Math.random() * 2) - 1;
			}
		}

		const start = context.currentTime + when;
		const source = new AudioBufferSourceNode(context, {buffer: this.#noiseBuffer});
		const filter = new BiquadFilterNode(context, {type, frequency});
		const gain = new GainNode(context, {gain: volume});
		gain.gain.setValueAtTime(volume, start);
		gain.gain.exponentialRampToValueAtTime(0.0001, start + duration);
		source.connect(filter).connect(gain).connect(output);
		source.start(start, Math.random() * 0.5);
		source.stop(start + duration + 0.02);
	}

	// The whistle of the teacher: a high tone with the rattle of the pea inside.
	#whistle() {
		const sound = this.#runningSound;
		if (!sound) {
			return;
		}

		const {context, output} = sound;
		const start = context.currentTime;
		const oscillator = new OscillatorNode(context, {type: 'sine', frequency: 2900});
		const rattle = new OscillatorNode(context, {type: 'sine', frequency: 32});
		const rattleDepth = new GainNode(context, {gain: 180});
		rattle.connect(rattleDepth).connect(oscillator.frequency);
		const gain = new GainNode(context, {gain: 0});
		gain.gain.setValueAtTime(0, start);
		gain.gain.linearRampToValueAtTime(0.06, start + 0.03);
		gain.gain.setValueAtTime(0.06, start + 0.55);
		gain.gain.exponentialRampToValueAtTime(0.0001, start + 0.75);
		oscillator.connect(gain).connect(output);
		oscillator.start(start);
		rattle.start(start);
		oscillator.stop(start + 0.8);
		rattle.stop(start + 0.8);
	}

	#effects = {
		// Glass on glass clicks high, the steel clanks lower and rings longer, and clay just knocks.
		click: (speed, first, second) => {
			const volume = clamp(speed / 700, 0.015, 0.22);
			const kindsInvolved = [first, second];
			if (kindsInvolved.includes('clay')) {
				this.#beep(620 + (Math.random() * 120), 0.05, {volume: volume * 0.9});
				this.#noise(0.03, {volume: volume * 0.5, frequency: 900});
				return;
			}

			const isSteel = kindsInvolved.includes('steel');
			const isBig = kindsInvolved.includes('big') || kindsInvolved.includes('king');
			const frequency = isSteel ? 1900 + (Math.random() * 200) : (isBig ? 2500 : 3300) + (Math.random() * 500);
			const ring = isSteel ? 0.16 : 0.07;
			this.#beep(frequency, ring, {volume});
			this.#beep(frequency * 1.51, ring * 0.6, {volume: volume * 0.45});
			this.#noise(0.015, {volume: volume * 0.7, frequency: 6000, type: 'highpass'});
		},
		flick: power => {
			this.#noise(0.04, {volume: 0.06, frequency: 2500});
			this.#noise(0.25 + (power * 0.5), {volume: 0.03 + (power * 0.03), frequency: 1600, when: 0.02});
		},
		plop: () => {
			this.#beep(240, 0.14, {slideTo: 120, volume: 0.12});
			this.#noise(0.08, {volume: 0.06, frequency: 500, type: 'lowpass'});
			this.#beep(2900, 0.05, {volume: 0.04, when: 0.09});
		},
		splash: () => {
			this.#noise(0.3, {volume: 0.08, frequency: 900, type: 'lowpass'});
		},
		// The electric school bell, a fast clatter of a hammer on a bell.
		bell: () => {
			for (let index = 0; index < 36; index++) {
				this.#beep(index % 2 === 0 ? 1180 : 1240, 0.08, {type: 'triangle', volume: 0.05, when: index * 0.055});
				this.#beep(2950, 0.05, {volume: 0.015, when: index * 0.055});
			}
		},
		trade: () => {
			this.#beep(3400, 0.06, {volume: 0.06});
			this.#beep(3000, 0.06, {volume: 0.06, when: 0.1});
			this.#beep(3600, 0.08, {volume: 0.06, when: 0.2});
		},
		cry: () => {
			this.#beep(640, 0.5, {type: 'triangle', slideTo: 420, volume: 0.05});
			this.#beep(600, 0.6, {type: 'triangle', slideTo: 380, volume: 0.05, when: 0.55});
		},
		win: () => {
			for (const [index, frequency] of [523, 659, 784, 1047].entries()) {
				this.#beep(frequency, 0.18, {type: 'square', volume: 0.035, when: index * 0.11});
			}
		},
	};

	// MARK: The state of the game

	// The marbles that lie on the gravel.
	#field = [];

	// The game in progress, as plain data, so it can be copied and put back when Kevin is caught cheating.
	#match;
	#lastSnapshot;
	#aim = {angle: -Math.PI / 2, power: 0.5};
	#pointerDrag;
	#aiAim;
	#flickAnimation;
	#bubble;
	#teacher;
	#gameTime = 0;
	#needsDraw = true;
	#scheduled = [];
	#tweens = [];
	#ripples = [];
	#trades = [];

	#requestDraw() {
		this.#needsDraw = true;
	}

	// Runs later in the time of the game, which stops while the toy is off screen. Without motion, it runs at once.
	#later(seconds, action) {
		if (this.reducedMotion) {
			action();
		} else {
			this.#scheduled.push({at: this.#gameTime + seconds, action});
		}
	}

	#snapshot() {
		return structuredClone({field: this.#field, match: this.#match});
	}

	#restore(saved) {
		const copy = structuredClone(saved);
		this.#field = copy.field;
		this.#match = copy.match;
	}

	#kid() {
		return kids[this.#match.kid];
	}

	#currentRecess() {
		return recesses[this.#recess.index];
	}

	#clockMinutes() {
		return this.#currentRecess().start + this.#recess.minutes;
	}

	// What was said since the last shot, so the prompt of the next turn adds to it instead of hiding it.
	#lastLine = '';

	#tell(text) {
		this.#lastLine = text;
		this.say(text);
		this.#requestDraw();
	}

	// A kid, the teacher, or the bell says something in a speech bubble on the gravel, and the status says it with what it means.
	#speak(speaker, [norwegian, english], after = '') {
		this.#bubble = {speaker, text: norwegian, until: this.#gameTime + 4};
		const name = speaker === 'teacher' ? 'Frøken Brekke' : (speaker === 'bell' ? 'The bell' : kids[speaker].name);
		const meaning = norwegian === english ? '' : ` (${english})`;
		this.#tell(`${name}: “${norwegian}”${meaning}${after ? ` ${after}` : ''}`);
	}

	#speakLine(line, after) {
		const lines = this.#kid().lines[line];
		if (lines) {
			this.#speak(this.#match.kid, randomItem(lines), after);
		} else if (after) {
			this.#tell(after);
		}
	}

	// MARK: The bag

	#sumBag() {
		let total = 0;
		for (const kind of kindOrder) {
			total += this.#bag[kind];
		}

		return total;
	}

	// The marbles that can go in a game: the shooter stays in the hand.
	#spare(kind) {
		return this.#bag[kind] - (kind === this.#shooterKind ? 1 : 0);
	}

	#takeStake(count) {
		const taken = [];
		for (const kind of stakeOrder) {
			while (taken.length < count && this.#spare(kind) > 0) {
				this.#bag[kind]--;
				taken.push(kind);
			}
		}

		if (taken.length < count) {
			for (const kind of taken) {
				this.#bag[kind]++;
			}

			return undefined;
		}

		return taken;
	}

	#addToBag(kindList) {
		for (const kind of kindList) {
			this.#bag[kind] = Math.min(this.#bag[kind] + 1, 999);
		}
	}

	#removeFromBag(kindList) {
		for (const kind of kindList) {
			this.#bag[kind] = Math.max(this.#bag[kind] - 1, 0);
		}
	}

	// The shooter must be in the bag. When it is gone, like to the teacher, the best one left takes its place.
	#ensureShooter() {
		if (this.#bag[this.#shooterKind] > 0) {
			return;
		}

		this.#shooterKind = ['glass', 'catseye', 'big', 'clay', 'steel', 'king'].find(kind => this.#bag[kind] > 0) ?? 'glass';
	}

	// MARK: Starting a game

	#stakeSize() {
		if (this.#match?.kid === 'geir' || this.#opponentId === 'geir') {
			return this.#gameId === 'ring' ? 5 : 3;
		}

		return this.#gameId === 'ring' ? 3 : 2;
	}

	// A game that stops before the end gives each kid back the marbles that are theirs.
	#abandon() {
		if (!this.#match || this.#match.phase === 'over') {
			return;
		}

		this.#finish('abandon');
	}

	#startGame() {
		this.#abandon();
		if (this.#match?.grab) {
			this.#tell(`Store-Geir runs off with ${describeAll(this.#match.grab.gains)}. They are gone.`);
		}

		if (this.#recess.isOver) {
			this.#nextRecess();
		}

		this.#field = [];
		this.#lastSnapshot = undefined;
		this.#bubble = undefined;
		this.#teacher = undefined;
		this.#aiAim = undefined;
		this.#flickAnimation = undefined;
		this.#pointerDrag = undefined;
		this.#scheduled = [];
		this.#tweens = [];
		let note = '';
		if (this.#opponentId === 'geir' && !this.#isForReal) {
			this.#isForReal = true;
			note = 'geir';
		}

		this.#match = {
			game: this.#gameId,
			kid: this.#opponentId,
			isForReal: this.#isForReal,
			phase: 'aim',
			turn: 'me',
			stage: undefined,
			score: {me: 0, them: 0},
			won: {me: [], them: []},
			captured: [],
			stake: {me: [], them: []},
			ready: undefined,
			cheat: undefined,
			grab: undefined,
			fees: [],
			shots: 0,
			thrown: 0,
			queue: [],
			queueIndex: 0,
			towerFallen: false,
			gumRevealed: false,
			holedThisShot: 0,
		};

		const ownCount = this.#gameId === 'tower' ? 0 : (this.#gameId === 'my-tower' ? 4 : this.#stakeSize());
		if (ownCount > 0) {
			const stake = this.#isForReal ? this.#takeStake(ownCount) : Array.from({length: ownCount}, (_, index) => stakeOrder[index % 2 === 0 ? 1 : 0]);
			if (!stake) {
				this.#match = undefined;
				this.#updateAll();
				this.#tell(`Your bag does not have ${ownCount} spare marbles for that. Trade some at the trade stand, or play “på lek” (for fun).`);
				return;
			}

			this.#match.stake.me = stake;
		}

		if (this.#gameId === 'hull') {
			this.#setUpHull();
		} else if (this.#gameId === 'ring') {
			this.#setUpRing();
		} else if (this.#gameId === 'tower') {
			this.#setUpTower();
		} else {
			this.#setUpMyTower();
		}

		this.#persist();
		this.#updateAll();
		if (note === 'geir') {
			this.#speakLine('forReal', 'Playing for real now.');
		}

		this.#beginTurn(true);
	}

	#setUpHull() {
		this.#match.stage = 'throw';
		this.#match.stake.them = kids[this.#match.kid].stake.slice(0, this.#stakeSize());
		this.#match.hand = {x: 320};
	}

	#setUpRing() {
		this.#match.stake.them = kids[this.#match.kid].stake.slice(0, 3);
		// The marbles of the ring lie in a cross in the middle, with the marbles of the two kids in turns.
		const marbles = [];
		const mine = [...this.#match.stake.me];
		const theirs = [...this.#match.stake.them];
		while (mine.length > 0 || theirs.length > 0) {
			if (mine.length > 0) {
				marbles.push(['me', mine.shift()]);
			}

			if (theirs.length > 0) {
				marbles.push(['them', theirs.shift()]);
			}
		}

		const spots = [[0, 0], [30, 0], [-30, 0], [0, 30], [0, -30], [60, 0], [-60, 0], [0, 60], [0, -60], [90, 0], [-90, 0]];
		for (const [index, [owner, kind]] of marbles.entries()) {
			const [x, y] = spots[index];
			this.#field.push(makeMarble(kind, owner, ring.x + x, ring.y + y));
		}

		this.#match.turn = this.#match.kid === 'geir' ? 'them' : 'me';
	}

	// The tower: three marbles that touch, and one on top.
	#buildTower(kindList, owner) {
		const [first, second, third, top] = kindList;
		const baseRadius = Math.max(kinds[first].radius, kinds[second].radius, kinds[third].radius);
		const distance = (baseRadius * 2) / Math.sqrt(3);
		for (const [index, kind] of [first, second, third].entries()) {
			const angle = (-Math.PI / 2) + (index * Math.PI * 2 / 3);
			const marble = makeMarble(kind, owner, towerSpot.x + (Math.cos(angle) * distance), towerSpot.y + (Math.sin(angle) * distance));
			marble.isTower = true;
			this.#field.push(marble);
		}

		const topMarble = makeMarble(top, owner, towerSpot.x, towerSpot.y);
		topMarble.isTower = true;
		topMarble.isTop = true;
		this.#field.push(topMarble);
		return topMarble;
	}

	#setUpTower() {
		const builder = kids[this.#match.kid];
		const kindList = this.#match.kid === 'geir' ? ['catseye', 'big', 'catseye', 'king'] : builder.stake.slice(1, 5);
		const top = this.#buildTower(kindList, 'them');
		top.isGlued = this.#match.kid === 'kevin';
		this.#match.stake.them = kindList;
		this.#match.lineY = builder.towerLine;
		this.#match.fee = this.#match.kid === 'geir' ? 2 : 1;
		this.#match.turn = 'me';
		this.#match.shooterX = 320;
	}

	#setUpMyTower() {
		this.#buildTower([this.#match.stake.me[0], this.#match.stake.me[1], this.#match.stake.me.length > 2 ? this.#match.stake.me[2] : 'glass', this.#match.stake.me[3] ?? 'glass'], 'me');
		this.#match.lineY = 350;
		const others = ['trond', 'kevin', 'geir', 'sister', 'ola'].filter(id => id !== this.#match.kid).sort(() => Math.random() - 0.5);
		this.#match.queue = [this.#match.kid, ...others];
		this.#match.turn = 'them';
	}

	// MARK: Turns

	#target() {
		if (this.#match.game === 'hull') {
			return hole;
		}

		if (this.#match.game === 'ring') {
			return ring;
		}

		return towerSpot;
	}

	// The marble or the handful that the visitor flicks next.
	#prepareMyShot() {
		if (this.#match.game === 'hull') {
			if (this.#match.stage === 'throw') {
				this.#match.ready = {isHandful: true, x: this.#match.hand.x, y: throwLine, radius: 14, kinds: this.#match.stake.me};
			} else {
				const choices = this.#flickable();
				if (!choices.includes(this.#match.ready)) {
					this.#match.ready = choices[0];
				}
			}
		} else if (this.#match.game === 'ring') {
			if (!this.#match.ready || !this.#field.includes(this.#match.ready)) {
				const angle = this.#match.edgeAngle ?? (Math.PI / 2);
				const shooter = makeMarble(this.#shooterKind, 'me', 0, 0);
				shooter.isShooter = true;
				this.#match.ready = shooter;
				this.#placeOnEdge(shooter, angle);
			}
		} else if (this.#match.game === 'tower') {
			const shooter = makeMarble(this.#shooterKind, 'me', this.#match.shooterX, this.#match.lineY);
			shooter.isShooter = true;
			this.#match.ready = shooter;
		}

		const goal = this.#target();
		this.#aim = {angle: Math.atan2(goal.y - this.#match.ready.y, goal.x - this.#match.ready.x), power: this.#aim.power};
	}

	#placeOnEdge(marble, angle) {
		this.#match.edgeAngle = angle;
		marble.x = ring.x + (Math.cos(angle) * (ring.radius + marble.radius + 3));
		marble.y = ring.y + (Math.sin(angle) * (ring.radius + marble.radius + 3));
	}

	// The marbles of Hull that can be flicked, the closest to the hole first.
	#flickable() {
		return this.#field.filter(marble => !marble.isInHole).sort((first, second) => distanceToHole(first) - distanceToHole(second));
	}

	#beginTurn(isFirst = false) {
		if (!this.#match || this.#match.phase === 'over') {
			return;
		}

		this.#aiAim = undefined;
		if (this.#match.turn === 'me') {
			this.#match.phase = 'aim';
			this.#prepareMyShot();
			if (isFirst) {
				this.#speakLine('start', this.#myPrompt());
			} else {
				this.#tell(this.#lastLine ? `${this.#lastLine} ${this.#shortPrompt()}` : this.#myPrompt());
			}
		} else if (!this.reducedMotion) {
			this.#match.phase = 'thinking';
			if (isFirst) {
				this.#speakLine('start');
			}

			this.#later(isFirst ? 1.2 : 0.6, () => {
				this.#aiTurn();
			});
		} else {
			this.#match.phase = 'waiting';
			const name = this.#shooterKid().name;
			const text = `It is ${name}’s turn. ${coarsePointer.matches ? 'Tap Go On or the gravel' : 'Press Go On (or Space)'} to watch.`;
			if (isFirst) {
				this.#speakLine('start', text);
			} else {
				this.#tell(this.#lastLine ? `${this.#lastLine} ${text}` : text);
			}
		}

		this.#updateAll();
	}

	#shortPrompt() {
		if (this.#match.game === 'hull') {
			return this.#match.stage === 'throw' ? 'Your throw.' : 'Your flick: pick a marble.';
		}

		return this.#match.game === 'ring' && this.#field.includes(this.#match.ready) ? 'Your shot, from where your shooter lies.' : 'Your shot.';
	}

	#myPrompt() {
		const isTouch = coarsePointer.matches;
		const flick = `Drag back from your ${this.#match.ready.isHandful ? 'marbles' : 'marble'} and let go${isTouch ? '' : ' (or aim with the arrow keys and press Space)'}.`;
		const click = isTouch ? 'Tap' : 'Click';
		if (this.#match.game === 'hull') {
			if (this.#match.stage === 'throw') {
				return `Your throw: your ${this.#match.stake.me.length} marbles at once, at the hole. ${flick} ${click} the line to move along it.`;
			}

			return `Your flick: pick any marble (${isTouch ? 'tap it' : 'click it, or press N'}) and flick it into the hole. ${flick}`;
		}

		if (this.#match.game === 'ring') {
			const isOnField = this.#field.includes(this.#match.ready);
			return `Your shot${isOnField ? ', from where your shooter lies' : ''}: knock marbles out of the ring. ${flick}${isOnField ? '' : ` ${click} outside the ring to move along it.`}`;
		}

		return `Shoot at ${this.#kid().name}’s tower from the line${this.#match.isForReal ? `. A miss costs ${describe('glass', this.#match.fee)}` : ''}. ${flick} ${click} the line to move along it.`;
	}

	// MARK: Shooting

	#shoot(ready, angle, power, withSpin) {
		this.#lastSnapshot = this.#snapshot();
		this.#lastLine = '';
		// Without motion, nothing walks off or fades, so the teacher and the speech bubble of the last shot go away at the next one.
		if (this.reducedMotion) {
			this.#teacher = undefined;
			this.#bubble = undefined;
		}

		this.#match.phase = 'rolling';
		this.#match.holedThisShot = 0;
		this.#match.shots++;
		this.#recess.minutes++;
		for (const marble of this.#field) {
			marble.path = [[marble.x, marble.y]];
		}

		if (ready.isHandful) {
			// A handful never flies straight: each marble goes a bit to its own side.
			const side = [-Math.sin(angle), Math.cos(angle)];
			for (const [index, kind] of ready.kinds.entries()) {
				const offset = (index - ((ready.kinds.length - 1) / 2)) * 16;
				const marble = makeMarble(kind, ready.owner ?? 'me', ready.x + (side[0] * offset), ready.y + (side[1] * offset));
				const spread = angle + (gaussian() * 0.05);
				const speed = speedFor(marble, power) * (1 + (gaussian() * 0.07));
				marble.vx = Math.cos(spread) * speed;
				marble.vy = Math.sin(spread) * speed;
				marble.path = [[marble.x, marble.y]];
				this.#field.push(marble);
			}
		} else {
			if (!this.#field.includes(ready)) {
				this.#field.push(ready);
			}

			const speed = speedFor(ready, power);
			ready.vx = Math.cos(angle) * speed;
			ready.vy = Math.sin(angle) * speed;
			ready.spin = withSpin;
			ready.path = [[ready.x, ready.y]];
		}

		this.#effects.flick(power);
		if (this.reducedMotion) {
			this.#settleInstantly();
			this.#afterShot();
		} else {
			this.#flickAnimation = {x: ready.x, y: ready.y, angle, radius: ready.radius, sleeve: this.#match.turn === 'me' ? '#2c4fa0' : this.#shooterKid().sleeve, start: this.#gameTime};
		}

		this.#updateAll();
	}

	// The kid who shoots next: the one picked to play against, or in Build My Own Tower, the next in the line of kids who pay to shoot at it.
	#shooterId() {
		return (this.#match.game === 'my-tower' ? this.#match.queue[this.#match.queueIndex % this.#match.queue.length] : this.#match.kid);
	}

	#shooterKid() {
		return kids[this.#shooterId()];
	}

	#isSettled() {
		return this.#field.every(marble => marble.isInHole || (Math.abs(marble.vx) < 2 && Math.abs(marble.vy) < 2)) && this.#tweens.length === 0;
	}

	#settleInstantly() {
		for (let step = 0; step < 240 * 30; step++) {
			this.#stepPhysics(1 / 240);
			if (this.#isSettled()) {
				break;
			}
		}

		this.#stopAll();
	}

	#stopAll() {
		for (const marble of this.#field) {
			marble.vx = 0;
			marble.vy = 0;
			marble.orientation = orthonormalize(marble.orientation);
		}
	}

	// MARK: The physics

	#stepPhysics(seconds) {
		const isHull = this.#match?.game === 'hull';
		for (const marble of this.#field) {
			if (marble.isInHole || marble.isTop) {
				continue;
			}

			let speed = Math.hypot(marble.vx, marble.vy);
			if (speed === 0) {
				continue;
			}

			// The spin of the flick curves the marble to the side, less and less as it slows down.
			if (marble.spin !== 0 && speed > 20) {
				const push = marble.spin * spinAcceleration * seconds;
				const {vx, vy} = marble;
				marble.vx += (-vy / speed) * push;
				marble.vy += (vx / speed) * push;
				marble.spin *= Math.exp(-1.5 * seconds);
				speed = Math.hypot(marble.vx, marble.vy);
			}

			const wasInPuddle = this.#isInPuddle(marble.x, marble.y);
			const slowed = Math.max(0, speed - (this.#frictionAt(marble.x, marble.y) * seconds) - (speed * drag * seconds));
			if (slowed === 0) {
				marble.vx = 0;
				marble.vy = 0;
			} else {
				// The stones of the gravel push a rolling marble a little off its path, the slow ones more.
				const wobble = gaussian() * Math.sqrt(seconds) * (this.#isRaining ? 0.07 : 0.1) * (120 / (speed + 120));
				const angle = Math.atan2(marble.vy, marble.vx) + wobble;
				marble.vx = Math.cos(angle) * slowed;
				marble.vy = Math.sin(angle) * slowed;
			}

			if (isHull) {
				this.#fallIntoHole(marble, seconds);
				if (marble.isInHole) {
					continue;
				}
			}

			const deltaX = marble.vx * seconds;
			const deltaY = marble.vy * seconds;
			marble.x += deltaX;
			marble.y += deltaY;
			roll(marble, deltaX, deltaY);
			if (this.#isRaining) {
				marble.mud = Math.min(1, marble.mud + (Math.hypot(deltaX, deltaY) * 0.0015));
			}

			if (!wasInPuddle && this.#isInPuddle(marble.x, marble.y) && speed > 40) {
				this.#effects.splash();
				this.#ripples.push({x: marble.x, y: marble.y, age: 0, size: 18});
			}

			this.#bounceOffEdges(marble);
			const last = marble.path.at(-1);
			if (!last || Math.hypot(marble.x - last[0], marble.y - last[1]) > 5) {
				marble.path.push([marble.x, marble.y]);
			}
		}

		this.#collide();
		this.#followGlue();
	}

	// The edge of the yard: the curb and the shoes of the kids stop a marble.
	#bounceOffEdges(marble) {
		if (marble.x < marble.radius) {
			marble.x = marble.radius;
			marble.vx = Math.abs(marble.vx) * 0.4;
		} else if (marble.x > this.#width - marble.radius) {
			marble.x = this.#width - marble.radius;
			marble.vx = -Math.abs(marble.vx) * 0.4;
		}

		if (marble.y < marble.radius) {
			marble.y = marble.radius;
			marble.vy = Math.abs(marble.vy) * 0.4;
		} else if (marble.y > this.#height - marble.radius) {
			marble.y = this.#height - marble.radius;
			marble.vy = -Math.abs(marble.vy) * 0.4;
		}
	}

	// The edge of the hole slopes in, so a marble that comes close is pulled in, and one that is slow enough falls in. A fast one jumps over.
	#fallIntoHole(marble, seconds) {
		const deltaX = hole.x - marble.x;
		const deltaY = hole.y - marble.y;
		const distance = Math.hypot(deltaX, deltaY);
		if (distance > hole.radius + (marble.radius * 0.5) || distance < 0.01) {
			return;
		}

		const pull = 700 * seconds;
		marble.vx += deltaX / distance * pull;
		marble.vy += deltaY / distance * pull;
		if (distance < hole.radius - (marble.radius * 0.35) && Math.hypot(marble.vx, marble.vy) < this.#captureSpeed()) {
			const count = this.#field.filter(other => other.isInHole).length;
			marble.isInHole = true;
			marble.vx = 0;
			marble.vy = 0;
			marble.sink = this.reducedMotion ? 1 : 0;
			marble.fromX = marble.x;
			marble.fromY = marble.y;
			marble.holeSpot = {x: hole.x + (Math.cos(count * 2.4) * Math.min(7, count * 3)), y: hole.y + (Math.sin(count * 2.4) * Math.min(7, count * 3))};
			marble.path.push([hole.x, hole.y]);
			if (this.#match) {
				this.#match.holedThisShot++;
			}

			this.#effects.plop();
		}
	}

	// Elastic collisions: the marbles push each other apart along the line between their centers, by their weights.
	#collide() {
		const active = this.#field.filter(marble => !marble.isInHole && !marble.isTop);
		for (let first = 0; first < active.length; first++) {
			for (let second = first + 1; second < active.length; second++) {
				const one = active[first];
				const other = active[second];
				const deltaX = other.x - one.x;
				const deltaY = other.y - one.y;
				const minimum = one.radius + other.radius;
				const distanceSquared = (deltaX * deltaX) + (deltaY * deltaY);
				if (distanceSquared >= minimum * minimum || distanceSquared === 0) {
					continue;
				}

				const distance = Math.sqrt(distanceSquared);
				const normalX = deltaX / distance;
				const normalY = deltaY / distance;
				const overlap = minimum - distance;
				const totalMass = one.mass + other.mass;
				one.x -= normalX * overlap * (other.mass / totalMass);
				one.y -= normalY * overlap * (other.mass / totalMass);
				other.x += normalX * overlap * (one.mass / totalMass);
				other.y += normalY * overlap * (one.mass / totalMass);
				const approach = ((one.vx - other.vx) * normalX) + ((one.vy - other.vy) * normalY);
				if (approach <= 0) {
					continue;
				}

				const restitution = Math.min(kinds[one.kind].restitution, kinds[other.kind].restitution);
				const impulse = (1 + restitution) * approach / ((1 / one.mass) + (1 / other.mass));
				one.vx -= impulse / one.mass * normalX;
				one.vy -= impulse / one.mass * normalY;
				other.vx += impulse / other.mass * normalX;
				other.vy += impulse / other.mass * normalY;
				if (approach > 12) {
					this.#effects.click(approach, one.kind, other.kind);
				}

				if ((one.isTower || other.isTower) && this.#match && !this.#match.towerFallen) {
					this.#knockTower();
				}
			}
		}
	}

	// A hit on the tower knocks the top off, unless it is glued on with chewing gum.
	#knockTower() {
		this.#match.towerFallen = true;
		const top = this.#field.find(marble => marble.isTop);
		if (!top || top.isGlued) {
			return;
		}

		top.isTop = false;
		const angle = Math.random() * Math.PI * 2;
		top.x += Math.cos(angle) * top.radius * 1.2;
		top.y += Math.sin(angle) * top.radius * 1.2;
		top.vx = Math.cos(angle) * 110;
		top.vy = Math.sin(angle) * 110;
		this.#effects.click(200, top.kind, 'glass');
	}

	// A glued top rides along on the marble it is glued to.
	#followGlue() {
		const top = this.#field.find(marble => marble.isTop && marble.isGlued);
		if (!top) {
			return;
		}

		const base = this.#field.find(marble => marble.isTower && !marble.isTop);
		if (base) {
			top.glueOffset ??= {x: top.x - base.x, y: top.y - base.y};
			const deltaX = base.x + top.glueOffset.x - top.x;
			const deltaY = base.y + top.glueOffset.y - top.y;
			top.x += deltaX;
			top.y += deltaY;
			roll(top, deltaX, deltaY);
		}
	}

	// MARK: After a shot

	#afterShot() {
		if (!this.#match) {
			return;
		}

		this.#stopAll();
		this.#match.phase = 'settled';
		this.#flickAnimation = undefined;
		if (this.#match.game === 'hull') {
			this.#afterHullShot();
		} else if (this.#match.game === 'ring') {
			this.#afterRingShot();
		} else if (this.#match.game === 'tower') {
			this.#afterTowerShot();
		} else {
			this.#afterMyTowerShot();
		}

		// A fee paid or a steel ball taken is kept, also if the page closes before the end of the game.
		this.#persist();
		this.#updateAll();
	}

	// The bell rings when the recess is over, after the shot that took the last minute.
	#checkBell() {
		if (this.#recess.minutes < this.#currentRecess().length) {
			if (this.#recess.minutes === this.#currentRecess().length - 2) {
				this.toast('Two minutes left of the recess!');
			}

			return false;
		}

		this.#recess.isOver = true;
		this.#effects.bell();
		this.#bubble = {speaker: 'bell', text: 'RIIIIIING!', until: this.#gameTime + 5};
		this.#finish('bell');
		return true;
	}

	#teacherSeesSteel() {
		if (this.#match.turn !== 'me' || this.#match.ready?.kind !== 'steel' || this.#match.ready.owner !== 'me' || !this.#field.includes(this.#match.ready) || Math.random() > 0.35) {
			return false;
		}

		this.#confiscate(this.#match.ready);
		return true;
	}

	#afterHullShot() {
		const remaining = this.#field.filter(marble => !marble.isInHole);
		if (this.#match.stage === 'throw') {
			this.#match.ready = undefined;
			this.#match.thrown++;
			const thrower = this.#match.turn;
			if (this.#match.thrown < 2) {
				this.#match.turn = otherSide(thrower);
				if (!this.#checkBell()) {
					this.#later(0.4, () => {
						this.#beginTurn();
					});
				}

				return;
			}

			if (remaining.length === 0) {
				this.#match.winner = thrower;
				this.#finish('done');
				return;
			}

			if (this.#checkBell()) {
				return;
			}

			this.#match.stage = 'flick';
			this.#lastSnapshot = this.#snapshot();
			const closest = this.#flickable()[0];
			if (this.#match.kid === 'kevin' && closest.owner === 'me' && Math.random() < 0.8) {
				this.#kevinNudges();
				return;
			}

			this.#startFlicking();
			return;
		}

		if (remaining.length === 0) {
			this.#match.winner = this.#match.turn;
			this.#finish('done');
			return;
		}

		const scored = this.#match.holedThisShot > 0;
		this.#reactToShot(scored);
		if (this.#checkBell()) {
			return;
		}

		if (!scored) {
			this.#match.turn = otherSide(this.#match.turn);
		}

		this.#later(0.6, () => {
			this.#beginTurn();
		});
	}

	#startFlicking() {
		const closest = this.#flickable()[0];
		this.#match.turn = closest.owner;
		this.#match.ready = closest;
		const whose = closest.owner === 'me' ? 'Your marble is closest to the hole, so you start to flick' : `${this.#kid().name}’s marble is closest to the hole, so ${this.#kid().name} starts to flick`;
		this.#tell(`${this.#lastLine ? `${this.#lastLine} ` : ''}${whose}. Who flicks in the last marble wins them all!`);
		this.#later(1.2, () => {
			this.#beginTurn();
		});
	}

	// Kevin bends down to tie his shoe, and his marble is suddenly next to the hole.
	#kevinNudges() {
		const cheatSnapshot = this.#snapshot();
		const his = this.#field.filter(marble => marble.owner === 'them' && !marble.isInHole).sort((first, second) => distanceToHole(first) - distanceToHole(second))[0];
		if (!his) {
			this.#startFlicking();
			return;
		}

		const angle = Math.atan2(his.y - hole.y, his.x - hole.x);
		const distance = hole.radius + his.radius + 2;
		const toX = hole.x + (Math.cos(angle) * distance);
		const toY = hole.y + (Math.sin(angle) * distance);
		this.#match.cheat = {type: 'nudge', snapshot: cheatSnapshot};
		his.path = [[his.x, his.y], [toX, toY]];
		this.#tell('Kevin bends down to tie his shoe… Hey, did his marble just move?');
		this.#slide(his, toX, toY, 0.7, () => {
			this.#startFlicking();
		});
	}

	#slide(marble, toX, toY, seconds, done) {
		if (this.reducedMotion) {
			marble.x = toX;
			marble.y = toY;
			done?.();
		} else {
			this.#tweens.push({marble, fromX: marble.x, fromY: marble.y, toX, toY, start: this.#gameTime, seconds, done});
		}
	}

	#reactToShot(isGood) {
		if (this.#match.turn === 'me') {
			if (Math.random() < 0.5) {
				this.#speakLine(isGood ? 'myGood' : 'myMiss');
			} else {
				this.#tell(isGood ? 'In! You flick again.' : `Missed. Now ${this.#kid().name} shoots.`);
			}
		} else {
			this.#speakLine(isGood ? 'theirGood' : 'theirMiss');
		}
	}

	#afterRingShot() {
		const shooter = this.#match.ready;
		const knockedOut = this.#field.filter(marble => !marble.isShooter && Math.hypot(marble.x - ring.x, marble.y - ring.y) > ring.radius);
		for (const marble of knockedOut) {
			this.#match.won[this.#match.turn].push(marble.kind);
			this.#match.score[this.#match.turn]++;
			if (this.#match.turn === 'me' && marble.owner === 'them') {
				this.#match.captured.push(marble.kind);
			}
		}

		this.#field = this.#field.filter(marble => !knockedOut.includes(marble));
		const isShooterOut = !shooter || Math.hypot(shooter.x - ring.x, shooter.y - ring.y) > ring.radius;
		if (this.#field.filter(marble => !marble.isShooter).length === 0) {
			this.#finish('done');
			return;
		}

		const scored = knockedOut.length > 0;
		const cheatHint = this.#match.cheat?.type === 'line' ? ' Hmm… did Kevin knuckle down inside the line?' : '';
		if (scored) {
			const text = `${this.#match.turn === 'me' ? 'You knock' : `${this.#kid().name} knocks`} out ${describeAll(knockedOut.map(marble => marble.kind))}!${cheatHint}`;
			if (this.#match.turn === 'me') {
				this.#speakLine('myGood', text);
			} else {
				this.#speakLine('theirGood', text);
			}
		} else if (cheatHint) {
			this.#speakLine('theirMiss', cheatHint.trim());
		} else {
			this.#reactToShot(false);
		}

		if (this.#teacherSeesSteel()) {
			this.#match.ready = undefined;
		}

		if (this.#checkBell()) {
			return;
		}

		// A kid who knocks one out shoots again, from where the shooter lies if it is still in the ring. Else the shooter is picked up, and the other kid shoots.
		if (!scored || isShooterOut) {
			this.#field = this.#field.filter(marble => marble !== shooter);
			this.#match.ready = undefined;
		}

		if (!scored) {
			this.#match.turn = otherSide(this.#match.turn);
		}

		this.#later(0.7, () => {
			this.#beginTurn();
		});
	}

	#afterTowerShot() {
		const shooter = this.#match.ready;
		const hitTower = this.#match.towerFallen;
		const top = this.#field.find(marble => marble.isTop);
		if (hitTower && !(top?.isGlued)) {
			this.#match.winner = 'me';
			this.#finish('done');
			return;
		}

		// Kevin says it does not count, as the top did not fall, and builds his tower again.
		if (hitTower) {
			this.#match.cheat = {type: 'gum'};
			this.#speakLine('gum', 'He takes your marble and builds his tower again. Hmm. Why did the top not fall?');
		} else {
			this.#speakLine('myMiss');
		}

		this.#payFee();
		if (this.#teacherSeesSteel()) {
			this.#match.ready = undefined;
		}

		this.#field = this.#field.filter(marble => marble !== shooter);
		this.#rebuildTower();
		this.#match.ready = undefined;
		if (this.#checkBell()) {
			return;
		}

		if (this.#match.isForReal && !this.#canPay(this.#match.fee)) {
			this.#tell('You have no more spare marbles to pay with. The tower stays.');
			this.#finish('broke');
			return;
		}

		this.#later(0.6, () => {
			this.#beginTurn();
		});
	}

	#canPay(count) {
		let total = 0;
		for (const kind of stakeOrder) {
			total += Math.max(this.#spare(kind), 0);
		}

		return total >= count;
	}

	#payFee() {
		if (!this.#match.isForReal) {
			return;
		}

		const fee = this.#takeStake(this.#match.fee);
		if (fee) {
			this.#match.fees.push(...fee);
		}
	}

	#rebuildTower() {
		const tower = this.#lastSnapshot.field.filter(marble => marble.isTower);
		this.#field = [...this.#field.filter(marble => !marble.isTower), ...structuredClone(tower)];
		this.#match.towerFallen = false;
	}

	#afterMyTowerShot() {
		const id = this.#shooterId();
		const shooter = kids[id];
		this.#field = this.#field.filter(marble => marble !== this.#match.ready);
		if (this.#match.towerFallen) {
			this.#match.winner = id;
			this.#speak(id, randomItem(shooter.lines.theirGood), `${shooter.name} hits your tower and takes it.`);
			this.#finish('done');
			return;
		}

		this.#speak(id, randomItem(shooter.lines.theirMiss));
		this.#rebuildTower();
		this.#match.queueIndex++;
		if (this.#checkBell()) {
			return;
		}

		this.#later(0.8, () => {
			this.#beginTurn();
		});
	}

	// MARK: The kids shoot

	// How fast a marble must start to roll a distance and still have some speed left, on this gravel.
	#startSpeed(distance, arrival = 0) {
		return Math.sqrt((arrival * arrival) + (2 * (this.#isRaining ? wetFriction : dryFriction) * 1.18 * Math.max(distance, 0)));
	}

	#aiTurn() {
		if (!this.#match || !['thinking', 'waiting'].includes(this.#match.phase)) {
			return;
		}

		const plan = this.#planShot();
		if (!plan) {
			this.#match.turn = 'me';
			this.#beginTurn();
			return;
		}

		const skill = this.#shooterKid();
		const angle = plan.angle + (gaussian() * skill.aim);
		const power = clamp(plan.power * (1 + (gaussian() * skill.power)), 0.04, 1);
		this.#match.ready = plan.ready;
		if (this.reducedMotion) {
			this.#shoot(plan.ready, angle, power, 0);
		} else {
			this.#aiAim = {ready: plan.ready, angle, power, start: this.#gameTime, sleeve: skill.sleeve};
			this.#match.phase = 'aiming';
			this.#later(0.8, () => {
				this.#aiAim = undefined;
				this.#shoot(plan.ready, angle, power, 0);
			});
			this.#requestDraw();
		}
	}

	#planShot() {
		if (this.#match.game === 'hull') {
			return this.#planHull();
		}

		if (this.#match.game === 'ring') {
			return this.#planRing();
		}

		return this.#planMyTower();
	}

	#powerToReach(marble, distance, arrival) {
		return clamp(this.#startSpeed(distance, arrival) / (maximumSpeed * kinds[marble.kind ?? 'glass'].speed), 0.05, 1);
	}

	#planHull() {
		if (this.#match.stage === 'throw') {
			const x = 280 + (Math.random() * 80);
			const ready = {isHandful: true, owner: 'them', x, y: throwLine, radius: 14, kinds: this.#match.stake.them, kind: 'glass'};
			const distance = Math.hypot(hole.x - x, hole.y - throwLine);
			return {ready, angle: Math.atan2(hole.y - throwLine, hole.x - x), power: this.#powerToReach(ready, distance - 6, 0)};
		}

		const marble = this.#flickable()[0];
		if (!marble) {
			return undefined;
		}

		const distance = distanceToHole(marble);
		return {ready: marble, angle: Math.atan2(hole.y - marble.y, hole.x - marble.x), power: this.#powerToReach(marble, distance, 110)};
	}

	#isBlocked(from, to, ignore) {
		return this.#field.some(marble => {
		if (marble === ignore || marble === from || marble.isInHole) {
			return false;
		}

		const lineX = to.x - from.x;
		const lineY = to.y - from.y;
		const length = Math.hypot(lineX, lineY);
		const along = (((marble.x - from.x) * lineX) + ((marble.y - from.y) * lineY)) / length;
		if (along <= 0 || along >= length) {
			return false;
		}

		const across = Math.abs(((marble.x - from.x) * lineY) - ((marble.y - from.y) * lineX)) / length;
		return across < marble.radius + from.radius;
	});
	}

	#planRing() {
		const targets = this.#field.filter(marble => !marble.isShooter);
		if (targets.length === 0) {
			return undefined;
		}

		const isFresh = !this.#match.ready || !this.#field.includes(this.#match.ready);
		const skill = this.#kid();
		let shooter = this.#match.ready;
		if (isFresh) {
			shooter = makeMarble(skill.shooter, 'them', 0, 0);
			shooter.isShooter = true;
		}

		// The kid tries spots around the ring, and picks the shot that pushes a marble out the shortest way.
		const starts = isFresh ? Array.from({length: 24}, (_, index) => index / 24 * Math.PI * 2) : [undefined];
		let best;
		for (const start of starts) {
			const from = start === undefined ? shooter : {
				x: ring.x + (Math.cos(start) * (ring.radius + shooter.radius + 3)),
				y: ring.y + (Math.sin(start) * (ring.radius + shooter.radius + 3)),
				radius: shooter.radius,
			};
			for (const marble of targets) {
				const length = Math.hypot(marble.x - from.x, marble.y - from.y);
				const directionX = (marble.x - from.x) / length;
				const directionY = (marble.y - from.y) / length;
				const edge = distanceToEdge(marble.x, marble.y, directionX, directionY);
				const cost = edge + (length * 0.35) + (this.#isBlocked(from, marble, marble) ? 200 : 0);
				if (!best || cost < best.cost) {
					best = {cost, start, marble, length, edge, angle: Math.atan2(directionY, directionX)};
				}
			}
		}

		if (isFresh) {
			let angle = best.start;
			// Kevin knuckles down a bit inside the line, where it is closer.
			if (this.#match.kid === 'kevin' && Math.random() < 0.6) {
				this.#match.cheat = {type: 'line', snapshot: this.#snapshot()};
				shooter.x = ring.x + (Math.cos(angle) * (ring.radius - 16));
				shooter.y = ring.y + (Math.sin(angle) * (ring.radius - 16));
				angle = undefined;
				this.#tell('Kevin knuckles down… right on the line? Or over it?');
			}

			if (angle !== undefined) {
				shooter.x = ring.x + (Math.cos(angle) * (ring.radius + shooter.radius + 3));
				shooter.y = ring.y + (Math.sin(angle) * (ring.radius + shooter.radius + 3));
			}

			best.angle = Math.atan2(best.marble.y - shooter.y, best.marble.x - shooter.x);
			best.length = Math.hypot(best.marble.y - shooter.y, best.marble.x - shooter.x);
		}

		// The marble that is hit must roll past the edge, so the shooter must arrive fast enough to push it there.
		const pushSpeed = this.#startSpeed(best.edge + 18);
		const contactSpeed = pushSpeed * (shooter.mass + best.marble.mass) / ((1 + 0.9) * shooter.mass);
		const travel = best.length - shooter.radius - best.marble.radius;
		return {ready: shooter, angle: best.angle, power: clamp(this.#startSpeed(travel, contactSpeed) / (maximumSpeed * kinds[shooter.kind].speed), 0.05, 1)};
	}

	#planMyTower() {
		const id = this.#shooterId();
		const {fee, lines, shooter: kind} = kids[id];
		this.#match.kid = id;
		// In “på lek”, the fees count for the score too, but nobody gets them.
		if (fee) {
			this.#match.fees.push(fee);
		}

		this.#speak(id, randomItem(lines.pay), fee ? `(+1 ${kinds[fee].name.toLowerCase()} for you)` : '(No marble for you.)');
		const x = 320 + (gaussian() * 40);
		const shooter = makeMarble(kind, 'them', clamp(x, 60, 580), this.#match.lineY);
		shooter.isShooter = true;
		const distance = Math.hypot(towerSpot.x - shooter.x, towerSpot.y - shooter.y) - 20;
		return {ready: shooter, angle: Math.atan2(towerSpot.y - shooter.y, towerSpot.x - shooter.x), power: this.#powerToReach(shooter, distance, 160)};
	}

	// MARK: The end of a game

	#finish(reason) {
		const gains = [];
		let outcome = 'none';
		let summary = '';
		const forReal = this.#match.isForReal;
		if (this.#match.game === 'hull') {
			if (reason === 'done') {
				const all = this.#field.map(marble => marble.kind);
				outcome = this.#match.winner === 'me' ? 'win' : 'loss';
				if (outcome === 'win') {
					gains.push(...all);
				}

				summary = outcome === 'win' ? `You flick in the last marble and win the whole hole: ${describeAll(all)}!` : `${this.#kid().name} flicks in the last marble and wins the whole hole.`;
			} else {
				gains.push(...this.#field.filter(marble => marble.owner === 'me').map(marble => marble.kind));
				if (this.#match.stage === 'throw' && this.#match.thrown === 0) {
					gains.splice(0, gains.length, ...this.#match.stake.me);
				}

				summary = 'Everybody picks up their own marbles.';
			}
		} else if (this.#match.game === 'ring') {
			gains.push(...this.#match.won.me);
			if (reason !== 'done') {
				gains.push(...this.#field.filter(marble => !marble.isShooter && marble.owner === 'me').map(marble => marble.kind));
			}

			if (this.#match.score.me !== this.#match.score.them) {
				outcome = this.#match.score.me > this.#match.score.them ? 'win' : 'loss';
			}

			summary = `You knocked out ${this.#match.score.me}, ${this.#kid().name} ${this.#match.score.them}.${reason === 'done' ? '' : ' The rest go back to their owners.'}`;
		} else if (this.#match.game === 'tower') {
			if (this.#match.winner === 'me') {
				outcome = 'win';
				gains.push(...this.#match.stake.them);
				summary = `You win the tower: ${describeAll(this.#match.stake.them)}!`;
			} else {
				outcome = this.#match.fees.length > 0 ? 'loss' : 'none';
				summary = `The tower stays with ${this.#kid().name}${this.#match.fees.length > 0 ? `, and so do the ${this.#match.fees.length} marbles you paid` : ''}.`;
			}
		} else if (reason === 'done') {
			gains.push(...this.#match.fees);
			outcome = this.#match.fees.length >= 4 ? 'win' : 'loss';
			summary = `You lose your tower, but keep the fees: ${describeAll(this.#match.fees)}.`;
		} else {
			gains.push(...this.#match.stake.me, ...this.#match.fees);
			outcome = this.#match.fees.length > 0 ? 'win' : 'none';
			summary = `Nobody hit your tower! You keep it, and the fees: ${describeAll(this.#match.fees)}.`;
		}

		this.#match.phase = 'over';
		this.#match.ready = undefined;
		this.#match.cheat = undefined;
		this.#aiAim = undefined;
		if (reason === 'abandon') {
			if (forReal) {
				this.#addToBag(gains);
			}

			this.#match = undefined;
			return;
		}

		if (outcome === 'win') {
			this.#wins++;
			this.#effects.win();
		} else if (outcome === 'loss') {
			this.#losses++;
		}

		const isMyTower = this.#match.game === 'my-tower';

		// Store-Geir does not like to lose. When the visitor wins his marbles, he grabs all of them, unless the teacher comes.
		if (forReal && this.#match.kid === 'geir' && !isMyTower && outcome === 'win' && Math.random() < 0.7) {
			this.#match.grab = {gains};
			this.#sweepToGeir();
			this.#speak('geir', randomItem(kids.geir.lines.grab), 'Store-Geir grabs ALL the marbles! Call the teacher, quick!');
			this.#finishUpdate();
			return;
		}

		if (forReal) {
			this.#addToBag(gains);
		}

		const bellText = reason === 'bell' ? 'RIIIIING! The bell! The recess is over. ' : '';
		const realText = forReal ? '' : ' (It was only på lek, so everybody gets their own marbles back.)';
		const text = `${bellText}${summary}${realText} ${coarsePointer.matches ? 'Tap' : 'Click'} the gravel to play again.`;
		let lineKey;
		if (outcome === 'win') {
			lineKey = this.#match.game === 'tower' ? 'towerLost' : 'lose';
		} else if (outcome === 'loss') {
			lineKey = 'win';
		}

		const lines = lineKey ? this.#kid().lines[lineKey] : undefined;
		if (reason !== 'bell' && !isMyTower && lines) {
			this.#speak(this.#match.kid, randomItem(lines), text);
		} else {
			this.#tell(text);
		}

		if (forReal && gains.includes('king')) {
			this.celebrate();
			this.toast('You won KONGEN, the king of all marbles!');
		} else if (forReal && outcome === 'win') {
			this.toast(`You won marbles! ${describeAll(gains)}.`);
		}

		// Lillesøster cries, and at dinner Mamma says what she always says.
		let fromSister = [];
		if (forReal && this.#match.kid === 'sister' && outcome === 'win' && !isMyTower) {
			fromSister = this.#match.game === 'ring' ? this.#match.captured : this.#match.stake.them;
		}

		if (fromSister.length > 0) {
			this.#effects.cry();
			this.#removeFromBag(fromSister);
			this.#later(this.reducedMotion ? 0 : 2.5, () => {
				this.#speak('sister', kids.sister.lines.cry[0], `At dinner, Mamma says: “Gi kulene tilbake til søsteren din, Sindre.” (Give the marbles back to your sister.) You give back ${describeAll(fromSister)}.`);
				this.#finishUpdate();
			});
		}

		this.#finishUpdate();
	}

	#finishUpdate() {
		this.#ensureShooter();
		this.#persist();
		this.#updateAll();
	}

	#sweepToGeir() {
		for (const marble of this.#field) {
			if (marble.isInHole) {
				marble.isInHole = false;
				marble.x = marble.holeSpot.x;
				marble.y = marble.holeSpot.y;
			}

			marble.path = [[marble.x, marble.y], [320, 0]];
			this.#slide(marble, 320 + (gaussian() * 20), -20, 0.9);
		}

		if (this.reducedMotion) {
			this.#field = [];
		}
	}

	// MARK: The teacher

	#confiscate(marble) {
		// A steel ball that was traded away in the meantime is not in the bag, so the drawer does not get a new one from nothing.
		if (this.#bag.steel > 0) {
			this.#bag.steel--;
			this.#drawer++;
		}

		this.#field = this.#field.filter(other => other !== marble);
		this.#teacherWalksIn(marble.x, marble.y);
		this.#whistle();
		this.#speak('teacher', teacherLines.steel, 'Your steel ball goes in her drawer until after the bell.');
		this.#ensureShooter();
		this.#persist();
	}

	#teacherWalksIn(x, y) {
		const toX = clamp(x - 80, 30, this.#width - 60);
		const toY = clamp(y, 60, this.#height - 40);
		this.#teacher = {x: this.reducedMotion ? toX : -60, y: toY, fromX: -60, toX, start: this.#gameTime, leaveAt: this.#gameTime + 4.5};
	}

	#callTeacher() {
		this.#whistle();
		// She stops at the side of the yard, so she does not cover the game.
		this.#teacherWalksIn(140, 300);
		if (this.#match?.grab) {
			const {gains} = this.#match.grab;
			this.#match.grab = undefined;
			this.#addToBag(gains);
			this.#speak('teacher', teacherLines.geir, `You get your marbles back: ${describeAll(gains)}. Store-Geir’s steel ball goes in the drawer.`);
			if (gains.includes('king')) {
				this.celebrate();
				this.toast('You won KONGEN, the king of all marbles!');
			}

			this.#finishUpdate();
			return;
		}

		if (this.#match?.cheat && this.#match.phase !== 'rolling' && this.#match.phase !== 'over') {
			this.#catchCheat(true);
			return;
		}

		const steel = this.#field.find(marble => marble.kind === 'steel' && marble.owner === 'me') ?? (this.#match?.ready?.kind === 'steel' && this.#match.ready.owner === 'me' ? this.#match.ready : undefined);
		if (steel) {
			this.#speak('teacher', teacherLines.tattle);
			this.#later(this.reducedMotion ? 0 : 1.6, () => {
				// A second call, or a shot in the meantime, may have taken it already.
				if (this.#match?.ready !== steel && !this.#field.includes(steel)) {
					return;
				}

				this.#confiscate(steel);
				if (this.#match?.ready === steel) {
					this.#match.ready = undefined;
					if (this.#match.turn === 'me' && this.#match.phase === 'aim') {
						this.#prepareMyShot();
					}
				}

				this.#updateAll();
			});
			return;
		}

		this.#speak('teacher', teacherLines.tattle);
	}

	// MARK: Cheating

	#catchCheat(byTeacher) {
		const {cheat} = this.#match;
		this.#match.cheat = undefined;
		// Kevin does not get to take the shot he was about to take, or to finish sliding his marble.
		this.#scheduled = [];
		this.#tweens = [];
		this.#aiAim = undefined;
		if (cheat.type === 'gum') {
			this.#match.gumRevealed = true;
			this.#match.winner = 'me';
			this.#finish('done');
			const [norwegian, english] = byTeacher ? teacherLines.kevin : kids.kevin.lines.gumCaught[0];
			this.#speak(byTeacher ? 'teacher' : 'kevin', [norwegian, english], `Chewing gum! Kevin glued the top of his tower. The tower is yours: ${describeAll(this.#match.stake.them)}.`);
			return;
		}

		this.#restore(cheat.snapshot);
		this.#match.cheat = undefined;
		this.#match.turn = 'me';
		this.#match.ready = undefined;
		if (cheat.type === 'nudge') {
			this.#match.stage = 'flick';
			this.#match.ready = this.#flickable()[0];
		}

		this.#speak(byTeacher ? 'teacher' : 'kevin', byTeacher ? teacherLines.kevin : kids.kevin.lines.caught[0], cheat.type === 'nudge' ? 'His marble goes back where it was, and you start.' : 'His shot from inside the ring does not count. Your turn.');
		this.#match.phase = 'aim';
		this.#prepareMyShot();
		this.#updateAll();
	}

	#accuse() {
		if (!this.#match || this.#match.phase === 'over' || this.#match.phase === 'rolling') {
			this.#tell('Juks? Nobody is playing right now.');
			return;
		}

		if (this.#match.cheat) {
			this.#catchCheat(false);
			return;
		}

		this.#speak(this.#shooterId(), randomItem(this.#shooterKid().lines.accused), 'Nobody cheated that time.');
	}

	// MARK: Recess and weather

	#nextRecess() {
		this.#recess.index++;
		this.#recess.minutes = 0;
		this.#recess.isOver = false;
		if (this.#recess.index >= recesses.length) {
			this.#recess.index = 0;
			this.#day++;
			this.toast(`A new day at school. Day ${this.#day}.`);
		}

		// Bergen weather: it changes between every recess, and mostly to rain.
		if (Math.random() < (this.#isRaining ? 0.35 : 0.5)) {
			this.#setRain(!this.#isRaining, true);
		}

		this.#makeTrades();
		this.#persist();
	}

	#setRain(raining, isWeather = false) {
		this.#isRaining = raining;
		const {rain} = this.parts;
		setPressed(rain, this.#isRaining);
		rain.textContent = this.#isRaining ? 'Rain: On' : 'Rain';
		if (isWeather) {
			this.toast(this.#isRaining ? 'Typisk Bergen: it is raining again.' : 'The sun is out! In Bergen!');
		}

		this.#requestDraw();
	}

	// MARK: The trade stand

	#makeTrades() {
		const shuffled = [...tradeOffers].sort(() => Math.random() - 0.5);
		this.#trades = shuffled.slice(0, 3).map(offer => ({...offer, isDone: false}));
		this.#renderTrades();
	}

	#canAfford(counts) {
		return Object.entries(counts).every(([kind, count]) => this.#bag[kind] >= count);
	}

	#renderTrades() {
		const {newGame, tradeList} = this.parts;
		const buttonClass = newGame.className;
		const items = this.#trades.map((trade, index) => {
			const item = document.createElement('li');
			const text = document.createElement('span');
			const trader = kids[trade.kid];
			if (trade.isDone) {
				text.textContent = trade.result;
				item.append(text);
				return item;
			}

			text.textContent = `${trader.name}: “${trade.line[0]}” (${trade.line[1]}) You give ${describeAll(expand(trade.give))}, and get ${describeAll(expand(trade.get))}.`;
			const button = document.createElement('button');
			button.type = 'button';
			button.className = buttonClass;
			button.dataset.marblesTrade = String(index);
			button.textContent = 'Bytt! (Trade)';
			button.disabled = !this.#canAfford(trade.give);
			item.append(text, button);
			return item;
		});
		tradeList.replaceChildren(...items);
	}

	#trade(index) {
		const offer = this.#trades[index];
		if (!offer || offer.isDone || !this.#canAfford(offer.give)) {
			return;
		}

		this.#removeFromBag(expand(offer.give));
		this.#addToBag(expand(offer.real ?? offer.get));
		offer.isDone = true;
		offer.result = `Traded with ${kids[offer.kid].name}. ${offer.reveal ?? 'Deal!'}`;
		this.#effects.trade();
		this.#ensureShooter();
		this.#persist();
		this.#tell(offer.result);
		if ((offer.real ?? offer.get).king) {
			this.celebrate();
			this.toast('You have KONGEN, the king of all marbles!');
		}

		this.#updateAll();
	}

	// MARK: The panel

	#bagButtons = new Map();

	#makeBag() {
		const {bagList} = this.parts;
		for (const kind of kindOrder) {
			const button = document.createElement('button');
			button.type = 'button';
			button.dataset.marblesKind = kind;
			const icon = document.createElement('canvas');
			icon.width = 44;
			icon.height = 44;
			const label = document.createElement('span');
			button.append(icon, label);
			bagList.append(button);
			this.#bagButtons.set(kind, {button, icon, label});
			const marble = makeMarble(kind, 'me', 0, 0, kindOrder.indexOf(kind) + 3);
			const context = icon.getContext('2d');
			const radius = kind === 'big' || kind === 'king' ? 19 : 15;
			drawShadow(context, marble, 22, 22, radius * 0.8);
			drawMarble(context, marble, 22, 22, radius);
		}
	}

	#updateBag() {
		for (const [kind, {button, label}] of this.#bagButtons) {
			label.textContent = `${kinds[kind].name} ×${this.#bag[kind]}: ${kinds[kind].english}`;
			button.disabled = this.#bag[kind] === 0;
			button.setAttribute('aria-pressed', String(kind === this.#shooterKind));
		}
	}

	#updateLcd() {
		const lines = [`DAG ${this.#day}: ${this.#currentRecess().name.toUpperCase()}`, `KLOKKA ${formatTime(this.#clockMinutes())}${this.#recess.isOver ? ' RIIING!' : ''}`, `RINGER ${formatTime(this.#currentRecess().start + this.#currentRecess().length)}`];
		if (this.#match) {
			const name = this.#kid().name.toUpperCase();
			const gameName = {hull: 'HULL', ring: 'RING', tower: 'TÅRN', 'my-tower': 'MITT TÅRN'}[this.#match.game];
			lines.push(`${gameName}, ${this.#match.isForReal ? 'PÅ ORDENTLIG' : 'PÅ LEK'}`);
			if (this.#match.game === 'ring') {
				lines.push(`MEG ${this.#match.score.me}, ${name} ${this.#match.score.them}`, `I RINGEN ${this.#field.filter(marble => !marble.isShooter).length}`);
			} else if (this.#match.game === 'hull') {
				lines.push(`MOT ${name}`, `I GROPA ${this.#field.filter(marble => marble.isInHole).length}`);
			} else if (this.#match.game === 'tower') {
				lines.push(`MOT ${name}`, `SKUDD ${this.#match.shots}, BETALT ${this.#match.fees.length}`);
			} else {
				lines.push(`SKUDD ${this.#match.queueIndex}`, `TJENT ${this.#match.fees.length}`);
			}
		} else {
			lines.push('INGEN SPILL');
		}

		lines.push(`POSEN: ${this.#sumBag()} KULER`, `${this.#wins} SEIERE, ${this.#losses} TAP`);
		const {lcd} = this.parts;
		lcd.textContent = lines.join('\n');
	}

	#updateButtons() {
		for (const button of this.#gameButtons) {
			setPressed(button, button.dataset.marblesGame === this.#gameId);
		}

		for (const button of this.#opponentButtons) {
			setPressed(button, button.dataset.marblesOpponent === this.#opponentId);
		}

		for (const button of this.#spinButtons) {
			setPressed(button, Number({none: 0, left: -1, right: 1}[button.dataset.marblesSpin]) === this.#spin);
		}

		const {stakes, goOn, cheat, teacher, newGame, drawer, drawerText} = this.parts;
		stakes.textContent = this.#isForReal ? 'På ordentlig (for Real)' : 'På lek (for Fun)';
		setPressed(stakes, this.#isForReal);
		goOn.disabled = this.#match?.phase !== 'waiting';
		goOn.dataset.state = this.#match?.phase === 'waiting' ? 'urgent' : '';
		cheat.disabled = !this.#match || this.#match.phase === 'over';
		teacher.dataset.state = this.#match?.grab ? 'urgent' : '';
		newGame.dataset.state = !this.#match || this.#match.phase === 'over' ? 'urgent' : '';
		newGame.textContent = this.#recess.isOver ? 'Next Recess' : 'New Game';
		drawer.disabled = this.#drawer === 0;
		drawerText.textContent = this.#drawer === 0 ? 'Empty, except for a confiscated yo-yo and a Tamagotchi.' : `${describe('steel', this.#drawer)}, confiscated. ${this.#recess.isOver ? 'The bell has rung: ask for it back!' : 'You get it back after the bell.'}`;
	}

	#updateAll() {
		this.#updateBag();
		this.#updateLcd();
		this.#updateButtons();
		const {tradeList} = this.parts;
		for (const button of tradeList.querySelectorAll('[data-marbles-trade]')) {
			button.disabled = !this.#canAfford(this.#trades[Number(button.dataset.marblesTrade)].give);
		}

		this.#requestDraw();
	}

	// MARK: Drawing the yard

	#drawPuddles() {
		for (const puddle of puddles) {
			const gradient = this.#yard.createLinearGradient(puddle.x, puddle.y - puddle.radiusY, puddle.x, puddle.y + puddle.radiusY);
			gradient.addColorStop(0, '#a9b8c6');
			gradient.addColorStop(1, '#5f6f7d');
			this.#yard.fillStyle = 'rgba(40, 30, 20, 0.5)';
			this.#yard.beginPath();
			this.#yard.ellipse(puddle.x, puddle.y, puddle.radiusX + 4, puddle.radiusY + 3, 0, 0, Math.PI * 2);
			this.#yard.fill();
			this.#yard.fillStyle = gradient;
			this.#yard.beginPath();
			this.#yard.ellipse(puddle.x, puddle.y, puddle.radiusX, puddle.radiusY, 0, 0, Math.PI * 2);
			this.#yard.fill();
			this.#yard.strokeStyle = 'rgba(255, 255, 255, 0.4)';
			this.#yard.lineWidth = 2;
			this.#yard.beginPath();
			this.#yard.ellipse(puddle.x - (puddle.radiusX * 0.2), puddle.y - (puddle.radiusY * 0.35), puddle.radiusX * 0.45, puddle.radiusY * 0.2, 0, Math.PI * 1.1, Math.PI * 1.7);
			this.#yard.stroke();
		}
	}

	// A line drawn in the gravel with a stick: a dark groove with the gravel pushed up on the side.
	#drawGroove(path) {
		this.#yard.lineCap = 'round';
		this.#yard.lineJoin = 'round';
		this.#yard.strokeStyle = 'rgba(235, 225, 200, 0.35)';
		this.#yard.lineWidth = 3;
		this.#yard.beginPath();
		for (const [x, y] of path) {
			this.#yard.lineTo(x + 1.5, y + 1.5);
		}

		this.#yard.stroke();
		this.#yard.strokeStyle = 'rgba(55, 40, 25, 0.6)';
		this.#yard.lineWidth = 2.5;
		this.#yard.beginPath();
		for (const [x, y] of path) {
			this.#yard.lineTo(x, y);
		}

		this.#yard.stroke();
	}

	#drawHole() {
		const rim = this.#yard.createRadialGradient(hole.x, hole.y, hole.radius * 0.6, hole.x, hole.y, hole.radius + 9);
		rim.addColorStop(0, 'rgba(40, 28, 16, 0.9)');
		rim.addColorStop(0.7, 'rgba(90, 70, 45, 0.6)');
		rim.addColorStop(0.85, 'rgba(210, 195, 160, 0.5)');
		rim.addColorStop(1, 'rgba(210, 195, 160, 0)');
		this.#yard.fillStyle = rim;
		this.#yard.beginPath();
		this.#yard.arc(hole.x, hole.y, hole.radius + 9, 0, Math.PI * 2);
		this.#yard.fill();
		const pit = this.#yard.createRadialGradient(hole.x - 3, hole.y - 3, 1, hole.x, hole.y, hole.radius);
		pit.addColorStop(0, '#1a120a');
		pit.addColorStop(1, '#4a3622');
		this.#yard.fillStyle = pit;
		this.#yard.beginPath();
		this.#yard.arc(hole.x, hole.y, hole.radius, 0, Math.PI * 2);
		this.#yard.fill();
	}

	#drawMarblesInHole(ground) {
		const holed = this.#field.filter(marble => marble.isInHole);
		if (holed.length === 0) {
			return;
		}

		this.#yard.save();
		for (const marble of holed) {
			const progress = marble.sink;
			const x = marble.fromX + ((marble.holeSpot.x - marble.fromX) * progress);
			const y = marble.fromY + ((marble.holeSpot.y - marble.fromY) * progress);
			const radius = marble.radius * (1 - (progress * 0.25));
			if (progress >= 1) {
				this.#yard.beginPath();
				this.#yard.arc(hole.x, hole.y, hole.radius, 0, Math.PI * 2);
				this.#yard.clip();
			}

			drawMarble(this.#yard, marble, x, y, radius, ground);
		}

		this.#yard.fillStyle = 'rgba(20, 12, 4, 0.35)';
		this.#yard.beginPath();
		this.#yard.arc(hole.x, hole.y, hole.radius, 0, Math.PI * 2);
		this.#yard.fill();
		this.#yard.restore();
	}

	// The shoes of the kid at the top of the yard, seen from above, with the toes toward the marbles.
	#drawShoes(kidId, centerX) {
		const isBoots = kidId === 'sister' || this.#isRaining;
		const shoe = {
			trond: {upper: '#f4f4f4', sole: '#9aa0a8', accent: '#1d4fbf', length: 46, width: 18},
			kevin: {upper: '#e8e0ff', sole: '#6b5bb5', accent: '#ff2a6d', length: 46, width: 18},
			geir: {upper: '#1b1b1b', sole: '#5a4a30', accent: '#e6c200', length: 56, width: 22},
			sister: {upper: '#ff7fbf', sole: '#c94f8c', accent: '#ffffff', length: 36, width: 15},
			ola: {upper: '#3a7bd5', sole: '#e0e0e0', accent: '#ffd400', length: 36, width: 14},
		}[kidId];
		for (const side of [-1, 1]) {
			const x = centerX + (side * (shoe.width * 0.75));
			const top = -shoe.length * 0.35;
			this.#yard.fillStyle = 'rgba(0, 0, 0, 0.3)';
			roundedRectangle(this.#yard, x - (shoe.width / 2) + 3, top + 4, shoe.width, shoe.length, shoe.width / 2);
			this.#yard.fill();
			this.#yard.fillStyle = isBoots && kidId !== 'geir' ? (kidId === 'sister' ? '#ff7fbf' : '#1f6b3a') : shoe.sole;
			roundedRectangle(this.#yard, x - (shoe.width / 2) - 1.5, top - 1.5, shoe.width + 3, shoe.length + 3, (shoe.width / 2) + 1.5);
			this.#yard.fill();
			this.#yard.fillStyle = isBoots && kidId !== 'geir' ? (kidId === 'sister' ? '#ff9fd0' : '#2f8a4f') : shoe.upper;
			roundedRectangle(this.#yard, x - (shoe.width / 2), top, shoe.width, shoe.length, shoe.width / 2);
			this.#yard.fill();
			if (isBoots && kidId !== 'geir') {
				// Rubber boots: a shine, and a flower for Lillesøster.
				this.#yard.fillStyle = 'rgba(255, 255, 255, 0.35)';
				roundedRectangle(this.#yard, x - (shoe.width / 2) + 3, top + 4, 3, shoe.length - 12, 1.5);
				this.#yard.fill();
				if (kidId === 'sister') {
					this.#yard.fillStyle = '#ffffff';
					for (let petal = 0; petal < 5; petal++) {
						const angle = petal / 5 * Math.PI * 2;
						this.#yard.beginPath();
						this.#yard.arc(x + (Math.cos(angle) * 2.5), top + (shoe.length * 0.62) + (Math.sin(angle) * 2.5), 1.8, 0, Math.PI * 2);
						this.#yard.fill();
					}

					this.#yard.fillStyle = '#ffd400';
					this.#yard.beginPath();
					this.#yard.arc(x, top + (shoe.length * 0.62), 1.4, 0, Math.PI * 2);
					this.#yard.fill();
				}

				continue;
			}

			// The laces, and the stripe or the stitching.
			this.#yard.strokeStyle = kidId === 'geir' ? '#e6c200' : 'rgba(80, 80, 90, 0.8)';
			this.#yard.lineWidth = 1;
			for (let lace = 0; lace < 4; lace++) {
				const y = top + (shoe.length * 0.2) + (lace * 4);
				this.#yard.beginPath();
				this.#yard.moveTo(x - (shoe.width * 0.22), y);
				this.#yard.lineTo(x + (shoe.width * 0.22), y + 2);
				this.#yard.stroke();
			}

			this.#yard.strokeStyle = shoe.accent;
			this.#yard.lineWidth = 2;
			this.#yard.beginPath();
			this.#yard.moveTo(x + (side * shoe.width * 0.48), top + (shoe.length * 0.3));
			this.#yard.quadraticCurveTo(x + (side * shoe.width * 0.2), top + (shoe.length * 0.65), x + (side * shoe.width * 0.45), top + (shoe.length * 0.8));
			this.#yard.stroke();

			// Kevin’s L.A. Gear shoes light up at the heel.
			if (kidId === 'kevin') {
				const isOn = this.reducedMotion || Math.floor(this.#gameTime * 4) % 2 === 0;
				this.#yard.fillStyle = isOn ? '#ff2020' : '#661010';
				this.#yard.beginPath();
				this.#yard.arc(x, top + 4, 3, 0, Math.PI * 2);
				this.#yard.fill();
			}
		}
	}

	// The teacher on yard duty, seen from above: her wool coat, her hair in a bun, her wooden clogs, and her whistle.
	#drawTeacher() {
		if (!this.#teacher) {
			return;
		}

		const {x, y} = this.#teacher;
		this.#yard.fillStyle = 'rgba(10, 10, 20, 0.28)';
		this.#yard.beginPath();
		this.#yard.ellipse(x + 10, y + 14, 30, 36, 0, 0, Math.PI * 2);
		this.#yard.fill();
		const step = !this.reducedMotion && this.#teacher.x < this.#teacher.toX ? Math.sin(this.#gameTime * 12) * 4 : 0;
		for (const side of [-1, 1]) {
			const clogY = y + (side * 10);
			const offset = side * step;
			this.#yard.fillStyle = '#c08a48';
			roundedRectangle(this.#yard, x + 4 + offset, clogY - 6, 28, 12, 6);
			this.#yard.fill();
			this.#yard.fillStyle = '#5a2a12';
			roundedRectangle(this.#yard, x + 16 + offset, clogY - 5.5, 15, 11, 5.5);
			this.#yard.fill();
		}

		this.#yard.fillStyle = '#8b1e3f';
		this.#yard.strokeStyle = '#4a0f22';
		this.#yard.lineWidth = 1.5;
		this.#yard.beginPath();
		this.#yard.ellipse(x, y, 15, 27, 0, 0, Math.PI * 2);
		this.#yard.fill();
		this.#yard.stroke();
		for (const side of [-1, 1]) {
			this.#yard.beginPath();
			this.#yard.ellipse(x + 4, y + (side * 24), 12, 6, side * 0.3, 0, Math.PI * 2);
			this.#yard.fill();
			this.#yard.stroke();
		}

		this.#yard.fillStyle = '#7a4a22';
		this.#yard.strokeStyle = '#4a2a10';
		this.#yard.beginPath();
		this.#yard.arc(x + 1, y, 11, 0, Math.PI * 2);
		this.#yard.fill();
		this.#yard.stroke();
		this.#yard.beginPath();
		this.#yard.arc(x - 8, y, 5.5, 0, Math.PI * 2);
		this.#yard.fill();
		this.#yard.stroke();
		this.#yard.strokeStyle = '#d0d0d0';
		this.#yard.lineWidth = 1;
		this.#yard.beginPath();
		this.#yard.moveTo(x + 9, y - 6);
		this.#yard.quadraticCurveTo(x + 20, y, x + 14, y + 8);
		this.#yard.stroke();
		this.#yard.fillStyle = '#c0c4c8';
		roundedRectangle(this.#yard, x + 12, y + 6, 9, 5, 2);
		this.#yard.fill();
	}

	// The hand that flicks: the knuckle down on the gravel next to the marble, and the thumb that pulls back with the power.
	#drawHand(x, y, angle, pull, radius, sleeve, alpha = 1, thumbForward = 0) {
		const skin = '#f2c6a0';
		const outline = '#b07a55';
		const back = -radius - 4;
		const side = radius + 16;
		this.#yard.save();
		this.#yard.globalAlpha = alpha;
		this.#yard.translate(x, y);
		this.#yard.rotate(angle);

		const capsule = (fromX, fromY, toX, toY, thickness, color = skin, edge = outline) => {
			this.#yard.lineCap = 'round';
			this.#yard.strokeStyle = edge;
			this.#yard.lineWidth = thickness + 2;
			this.#yard.beginPath();
			this.#yard.moveTo(fromX, fromY);
			this.#yard.lineTo(toX, toY);
			this.#yard.stroke();
			this.#yard.strokeStyle = color;
			this.#yard.lineWidth = thickness;
			this.#yard.stroke();
		};

		// The shadow of the hand and the arm, and the sleeve of the rain jacket.
		this.#yard.fillStyle = 'rgba(20, 12, 4, 0.22)';
		this.#yard.beginPath();
		this.#yard.ellipse(back - 26, side + 16, 44, 22, 0.35, 0, Math.PI * 2);
		this.#yard.fill();
		capsule(back - 30, side + 14, back - 90, side + 40, 30, sleeve, 'rgba(0, 0, 0, 0.45)');

		// The fist lies on its side next to the marble, with the knuckles of the curled fingers toward it.
		this.#yard.fillStyle = skin;
		this.#yard.strokeStyle = outline;
		this.#yard.lineWidth = 1.5;
		roundedRectangle(this.#yard, back - 30, side - 12, 38, 28, 12);
		this.#yard.fill();
		this.#yard.stroke();
		for (let finger = 0; finger < 4; finger++) {
			this.#yard.beginPath();
			this.#yard.ellipse(back - 22 + (finger * 9), side - 11, 5, 4, 0, 0, Math.PI * 2);
			this.#yard.fill();
			this.#yard.stroke();
		}

		// The thumb comes from the fist to just behind the marble, and pulls back with the power.
		const tipX = thumbForward > 0 ? -radius + (thumbForward * 7) : -radius - 3 - (pull * 16);
		capsule(back - 18, side - 6, tipX, 0, 10);
		this.#yard.fillStyle = '#ffe1e1';
		this.#yard.strokeStyle = 'rgba(176, 122, 85, 0.6)';
		this.#yard.lineWidth = 1;
		this.#yard.beginPath();
		this.#yard.ellipse(tipX - 1, -1, 3.5, 3, Math.atan2(side - 6, back - 18 - tipX), 0, Math.PI * 2);
		this.#yard.fill();
		this.#yard.stroke();
		this.#yard.restore();
	}

	// The hint of the path: where the marble rolls, as far as a kid can guess, up to the first marble it hits.
	#predictPath(ready, angle, power, withSpin) {
		const ghost = {x: ready.x, y: ready.y, radius: ready.radius, kind: ready.kind ?? 'glass'};
		const speed = speedFor(ghost, power);
		let vx = Math.cos(angle) * speed;
		let vy = Math.sin(angle) * speed;
		let spinLeft = withSpin;
		const points = [[ghost.x, ghost.y]];
		let travelled = 0;
		let contact;
		let isHoled = false;
		const others = this.#field.filter(marble => marble !== ready && !marble.isInHole);
		const seconds = 1 / 120;
		for (let step = 0; step < 120 * 5; step++) {
			let current = Math.hypot(vx, vy);
			if (current < 2) {
				break;
			}

			if (spinLeft !== 0 && current > 20) {
				const push = spinLeft * spinAcceleration * seconds;
				const oldX = vx;
				vx += (-vy / current) * push;
				vy += (oldX / current) * push;
				spinLeft *= Math.exp(-1.5 * seconds);
				current = Math.hypot(vx, vy);
			}

			const slowed = Math.max(0, current - (this.#frictionAt(ghost.x, ghost.y) * seconds) - (current * drag * seconds));
			vx = vx / current * slowed;
			vy = vy / current * slowed;
			ghost.x += vx * seconds;
			ghost.y += vy * seconds;
			travelled += slowed * seconds;
			if (this.#match.game === 'hull' && !ready.isHandful) {
				const distance = Math.hypot(hole.x - ghost.x, hole.y - ghost.y);
				if (distance < hole.radius - (ghost.radius * 0.35) && slowed < this.#captureSpeed()) {
					isHoled = true;
					points.push([hole.x, hole.y]);
					break;
				}
			}

			const hit = others.find(marble => Math.hypot(marble.x - ghost.x, marble.y - ghost.y) < marble.radius + ghost.radius);
			if (hit) {
				contact = {x: ghost.x, y: ghost.y};
				break;
			}

			if (ghost.x < 0 || ghost.x > this.#width || ghost.y < 0 || ghost.y > this.#height) {
				break;
			}

			if (Math.hypot(ghost.x - points.at(-1)[0], ghost.y - points.at(-1)[1]) > 9) {
				points.push([ghost.x, ghost.y]);
			}

			if (travelled > 280) {
				break;
			}
		}

		return {points, contact, isHoled};
	}

	#drawHint() {
		if (this.#match?.turn !== 'me' || this.#match.phase !== 'aim' || !this.#match.ready) {
			return;
		}

		const {points, contact, isHoled} = this.#predictPath(this.#match.ready, this.#aim.angle, this.#aim.power, this.#match.ready.isHandful ? 0 : this.#spin);
		for (const [index, [x, y]] of points.entries()) {
			if (index === 0) {
				continue;
			}

			this.#yard.fillStyle = `rgba(255, 255, 255, ${0.9 - (index / points.length * 0.6)})`;
			this.#yard.beginPath();
			this.#yard.arc(x, y, 2, 0, Math.PI * 2);
			this.#yard.fill();
		}

		if (contact) {
			this.#yard.strokeStyle = 'rgba(255, 255, 255, 0.85)';
			this.#yard.setLineDash([3, 3]);
			this.#yard.lineWidth = 1.5;
			this.#yard.beginPath();
			this.#yard.arc(contact.x, contact.y, this.#match.ready.radius, 0, Math.PI * 2);
			this.#yard.stroke();
			this.#yard.setLineDash([]);
		}

		if (isHoled) {
			this.#yard.strokeStyle = 'rgba(255, 255, 120, 0.9)';
			this.#yard.lineWidth = 2;
			this.#yard.beginPath();
			this.#yard.arc(hole.x, hole.y, hole.radius + 3, 0, Math.PI * 2);
			this.#yard.stroke();
		}

		// The power, as a bar of the hand-drawn kind.
		const barX = clamp(this.#match.ready.x - 20, 4, this.#width - 46);
		const barY = this.#match.ready.y - this.#match.ready.radius - 14 > 6 ? this.#match.ready.y - this.#match.ready.radius - 14 : this.#match.ready.y + this.#match.ready.radius + 8;
		this.#yard.fillStyle = 'rgba(0, 0, 0, 0.5)';
		this.#yard.fillRect(barX - 1, barY - 1, 42, 7);
		this.#yard.fillStyle = this.#aim.power > 0.8 ? '#ff4040' : (this.#aim.power > 0.5 ? '#ffd400' : '#40e040');
		this.#yard.fillRect(barX, barY, 40 * this.#aim.power, 5);
	}

	// The paths of the marbles of the last shot, as dotted lines, for visitors who prefer reduced motion.
	#drawPaths() {
		this.#yard.setLineDash([2, 5]);
		this.#yard.lineCap = 'round';
		for (const marble of this.#field) {
			if (marble.path.length < 2) {
				continue;
			}

			this.#yard.strokeStyle = 'rgba(0, 0, 0, 0.45)';
			this.#yard.lineWidth = 3;
			this.#yard.beginPath();
			for (const [x, y] of marble.path) {
				this.#yard.lineTo(x, y);
			}

			this.#yard.stroke();
			this.#yard.strokeStyle = 'rgba(255, 255, 255, 0.95)';
			this.#yard.lineWidth = 1.5;
			this.#yard.stroke();
		}

		this.#yard.setLineDash([]);
	}

	#wrapText(text, maximumWidth) {
		const words = text.split(' ');
		const lines = [];
		let line = '';
		for (const word of words) {
			const candidate = line ? `${line} ${word}` : word;
			if (this.#yard.measureText(candidate).width > maximumWidth && line) {
				lines.push(line);
				line = word;
			} else {
				line = candidate;
			}
		}

		if (line) {
			lines.push(line);
		}

		return lines;
	}

	#drawBubble() {
		if (!this.#bubble || (!this.reducedMotion && this.#gameTime > this.#bubble.until)) {
			return;
		}

		let anchorX = 360;
		let anchorY = 34;
		if (this.#bubble.speaker === 'teacher' && this.#teacher) {
			anchorX = this.#teacher.x + 12;
			anchorY = this.#teacher.y - 14;
		} else if (this.#bubble.speaker === 'bell') {
			anchorX = 320;
			anchorY = 220;
		}

		this.#yard.font = 'bold 17px "Comic Sans MS", "Comic Sans", "Chalkboard SE", cursive';
		const lines = this.#wrapText(this.#bubble.text, 230);
		const lineHeight = 20;
		const boxWidth = Math.max(...lines.map(line => this.#yard.measureText(line).width)) + 20;
		const boxHeight = (lines.length * lineHeight) + 14;
		const boxX = clamp(anchorX + 10, 6, this.#width - boxWidth - 6);
		// In the lower half of the yard, the bubble goes above what speaks, so it does not cover it.
		const isAbove = anchorY > this.#height / 2;
		const boxY = clamp(isAbove ? anchorY - 14 - boxHeight : anchorY + 14, 6, this.#height - boxHeight - 6);
		this.#yard.fillStyle = this.#bubble.speaker === 'bell' ? '#ffff66' : '#ffffff';
		this.#yard.strokeStyle = '#000000';
		this.#yard.lineWidth = 2;
		roundedRectangle(this.#yard, boxX, boxY, boxWidth, boxHeight, 10);
		this.#yard.fill();
		this.#yard.stroke();
		const edgeY = isAbove ? boxY + boxHeight - 1 : boxY + 1;
		this.#yard.beginPath();
		this.#yard.moveTo(boxX + 14, edgeY);
		this.#yard.lineTo(anchorX, anchorY);
		this.#yard.lineTo(boxX + 28, edgeY);
		this.#yard.fill();
		this.#yard.stroke();
		this.#yard.fillStyle = this.#bubble.speaker === 'bell' ? '#cc0000' : '#000000';
		this.#yard.textAlign = 'left';
		this.#yard.textBaseline = 'top';
		for (const [index, line] of lines.entries()) {
			this.#yard.fillText(line, boxX + 10, boxY + 8 + (index * lineHeight));
		}
	}

	#drawRain() {
		for (const ripple of this.#ripples) {
			const progress = ripple.age / 0.8;
			this.#yard.strokeStyle = `rgba(230, 240, 255, ${0.6 * (1 - progress)})`;
			this.#yard.lineWidth = 1;
			this.#yard.beginPath();
			this.#yard.ellipse(ripple.x, ripple.y, ripple.size * progress, ripple.size * progress * 0.6, 0, 0, Math.PI * 2);
			this.#yard.stroke();
		}
	}

	#drawHandful(ready) {
		for (const [index, kind] of ready.kinds.entries()) {
			const marble = makeMarble(kind, 'me', 0, 0, (index * 31) + 7);
			const x = ready.x + ((index - ((ready.kinds.length - 1) / 2)) * 16);
			drawShadow(this.#yard, marble, x, ready.y, marble.radius);
			drawMarble(this.#yard, marble, x, ready.y, marble.radius, this.#groundFor(this.#isRaining));
		}
	}

	#draw() {
		const ground = this.#groundFor(this.#isRaining);
		this.#yard.drawImage(ground, 0, 0);
		if (this.#isRaining) {
			this.#drawPuddles();
		}

		if (this.#match) {
			if (this.#match.game === 'ring') {
				this.#drawGroove(ringPath);
			} else if (this.#match.game === 'hull') {
				this.#drawGroove(linePath(throwLine));
				this.#drawHole();
				this.#drawMarblesInHole(ground);
			} else {
				this.#drawGroove(linePath(this.#match.lineY));
			}
		}

		if (this.reducedMotion) {
			this.#drawPaths();
		}

		const visible = this.#field.filter(marble => !marble.isInHole);
		const ready = this.#match?.ready;
		const isReadyLoose = ready && !ready.isHandful && !this.#field.includes(ready);
		for (const marble of visible) {
			drawShadow(this.#yard, marble, marble.x + (marble.isTop ? 4 : 0), marble.y + (marble.isTop ? 5 : 0), marble.radius);
		}

		if (isReadyLoose) {
			drawShadow(this.#yard, ready, ready.x, ready.y, ready.radius);
		}

		for (const marble of visible.filter(marble => !marble.isTop)) {
			drawMarble(this.#yard, marble, marble.x, marble.y, marble.radius, ground);
		}

		if (isReadyLoose) {
			drawMarble(this.#yard, ready, ready.x, ready.y, ready.radius, ground);
		}

		if (ready?.isHandful && this.#match.turn === 'me' && this.#match.phase === 'aim') {
			this.#drawHandful(ready);
		}

		if (this.#aiAim?.ready.isHandful) {
			this.#drawHandful(this.#aiAim.ready);
		}

		for (const top of visible.filter(marble => marble.isTop)) {
			drawMarble(this.#yard, top, top.x, top.y, top.radius * 1.12, ground);
			// Kevin’s chewing gum: a tiny pink smudge, until he is caught.
			if (top.isGlued) {
				const base = this.#field.find(marble => marble.isTower && !marble.isTop);
				if (base) {
					this.#yard.fillStyle = this.#match?.gumRevealed ? '#ff6fb5' : 'rgba(255, 111, 181, 0.7)';
					this.#yard.beginPath();
					this.#yard.arc((top.x + base.x) / 2, (top.y + base.y) / 2, this.#match?.gumRevealed ? 6 : 1.8, 0, Math.PI * 2);
					this.#yard.fill();
				}
			}
		}

		this.#drawHint();
		if (this.#match?.turn === 'me' && this.#match.phase === 'aim' && ready) {
			this.#drawHand(ready.x, ready.y, this.#aim.angle, this.#aim.power, ready.radius, '#2c4fa0');
		}

		if (this.#aiAim) {
			const pull = Math.min((this.#gameTime - this.#aiAim.start) / 0.7, 1) * this.#aiAim.power;
			this.#drawHand(this.#aiAim.ready.x, this.#aiAim.ready.y, this.#aiAim.angle, pull, this.#aiAim.ready.radius, this.#aiAim.sleeve);
		}

		if (this.#flickAnimation) {
			const age = this.#gameTime - this.#flickAnimation.start;
			if (age < 0.4) {
				this.#drawHand(this.#flickAnimation.x, this.#flickAnimation.y, this.#flickAnimation.angle, 0, this.#flickAnimation.radius, this.#flickAnimation.sleeve, 1 - (age / 0.4), Math.min(age / 0.06, 1));
			}
		}

		if (this.#match) {
			this.#drawShoes(this.#shooterId(), 320);
		}

		this.#drawTeacher();
		if (this.#isRaining && !this.reducedMotion) {
			this.#drawRain();
		}

		this.#drawBubble();
	}

	// MARK: The loop

	#step(seconds) {
		if (this.reducedMotion) {
			if (this.#match?.phase === 'rolling') {
				this.#settleInstantly();
				this.#afterShot();
			}

			if (this.#tweens.length > 0) {
				for (const tween of this.#tweens) {
					tween.marble.x = tween.toX;
					tween.marble.y = tween.toY;
					tween.done?.();
				}

				this.#tweens = [];
			}

			if (this.#needsDraw) {
				this.#needsDraw = false;
				this.#draw();
			}

			return;
		}

		this.#gameTime += seconds;
		const due = this.#scheduled.filter(item => item.at <= this.#gameTime);
		this.#scheduled = this.#scheduled.filter(item => item.at > this.#gameTime);
		for (const item of due) {
			item.action();
		}

		if (this.#match?.phase === 'rolling') {
			const substeps = Math.max(1, Math.ceil(seconds * 240));
			for (let index = 0; index < substeps; index++) {
				this.#stepPhysics(seconds / substeps);
			}

			if (this.#isSettled() && this.#gameTime - (this.#flickAnimation?.start ?? 0) > 0.2) {
				this.#afterShot();
			}
		}

		for (const tween of this.#tweens) {
			const progress = Math.min((this.#gameTime - tween.start) / tween.seconds, 1);
			const eased = 1 - ((1 - progress) ** 2);
			const deltaX = tween.fromX + ((tween.toX - tween.fromX) * eased) - tween.marble.x;
			const deltaY = tween.fromY + ((tween.toY - tween.fromY) * eased) - tween.marble.y;
			tween.marble.x += deltaX;
			tween.marble.y += deltaY;
			roll(tween.marble, deltaX, deltaY);
			tween.isDone = progress >= 1;
		}

		const finished = this.#tweens.filter(tween => tween.isDone);
		this.#tweens = this.#tweens.filter(tween => !tween.isDone);
		for (const tween of finished) {
			tween.done?.();
		}

		if (this.#match?.grab && this.#tweens.length === 0) {
			this.#field = this.#field.filter(marble => marble.y > 0);
		}

		for (const marble of this.#field) {
			if (marble.isInHole && marble.sink < 1) {
				marble.sink = Math.min(1, marble.sink + (seconds * 5));
			}
		}

		if (this.#teacher) {
			const walk = Math.min((this.#gameTime - this.#teacher.start) / 1.2, 1);
			this.#teacher.x = this.#teacher.fromX + ((this.#teacher.toX - this.#teacher.fromX) * walk);
			if (this.#gameTime > this.#teacher.leaveAt) {
				this.#teacher.x -= (this.#gameTime - this.#teacher.leaveAt) * 160;
				if (this.#teacher.x < -80) {
					this.#teacher = undefined;
				}
			}
		}

		if (this.#isRaining) {
			for (let drop = 0; drop < 2; drop++) {
				if (Math.random() < 0.5) {
					const puddle = Math.random() < 0.5 ? randomItem(puddles) : undefined;
					this.#ripples.push(puddle ? {x: puddle.x + ((Math.random() - 0.5) * puddle.radiusX * 1.6), y: puddle.y + ((Math.random() - 0.5) * puddle.radiusY * 1.6), age: 0, size: 9} : {x: Math.random() * this.#width, y: Math.random() * this.#height, age: 0, size: 3});
				}
			}
		}

		for (const ripple of this.#ripples) {
			ripple.age += seconds;
		}

		this.#ripples = this.#ripples.filter(ripple => ripple.age < 0.8);
		this.#draw();
	}

	// MARK: Input

	#myShot() {
		if (this.#match?.turn !== 'me' || this.#match.phase !== 'aim' || !this.#match.ready || this.#aim.power < 0.04) {
			return;
		}

		// Once the visitor shoots, it is too late to call out the cheat before.
		this.#match.cheat = undefined;
		if (this.#match.game === 'tower' && this.#match.isForReal && !this.#canPay(this.#match.fee)) {
			this.#tell('You have no spare marbles to pay for a shot.');
			return;
		}

		this.#shoot(this.#match.ready, this.#aim.angle, this.#aim.power, this.#spin);
	}

	#aimFrom(point) {
		const ready = this.#match.ready;
		const deltaX = ready.x - point.x;
		const deltaY = ready.y - point.y;
		const distance = Math.hypot(deltaX, deltaY);
		if (distance < ready.radius + 4) {
			this.#aim.power = 0;
		} else {
			this.#aim.angle = Math.atan2(deltaY, deltaX);
			this.#aim.power = clamp((distance - ready.radius - 4) / 140, 0, 1);
		}

		this.#requestDraw();
	}

	// Moves the shooter along the line or the edge of the ring, before the shot.
	#canPlace() {
		return this.#match?.turn === 'me' && this.#match.phase === 'aim' && this.#match.ready && (this.#match.ready.isHandful || (this.#match.game === 'tower') || (this.#match.game === 'ring' && !this.#field.includes(this.#match.ready)));
	}

	#placeAt(point) {
		const ready = this.#match.ready;
		if (this.#match.game === 'ring') {
			this.#placeOnEdge(ready, Math.atan2(point.y - ring.y, point.x - ring.x));
		} else {
			ready.x = clamp(point.x, 40, this.#width - 40);
			if (ready.isHandful) {
				this.#match.hand.x = ready.x;
			} else {
				this.#match.shooterX = ready.x;
			}
		}

		const goal = this.#target();
		this.#aim.angle = Math.atan2(goal.y - ready.y, goal.x - ready.x);
		this.#requestDraw();
	}

	// After the end of a game, a click on the gravel starts the next one, so the visitor does not have to look for New Game. Not while Store-Geir runs off with the marbles or Lillesøster still has to cry.
	#canStartAgain() {
		return this.#match.phase === 'over' && !this.#match.grab && this.#scheduled.length === 0;
	}

	#endDrag(event) {
		if (!this.#pointerDrag || event.pointerId !== this.#pointerDrag.pointerId) {
			return;
		}

		this.#pointerDrag = undefined;
		if (event.type === 'pointerup' && this.#match?.ready) {
			// Where the finger lets go counts too, as a quick flick may have no move events.
			const {canvas} = this.parts;
			this.#aimFrom(canvasPoint(canvas, event));
			this.#myShot();
		}
	}

	// What the buttons of the school yard and the drawer do, by the names of their parts.
	#actions = {
		stakes: () => {
			this.#isForReal = !this.#isForReal;
			if (!this.#isForReal && this.#opponentId === 'geir') {
				this.#opponentId = 'trond';
			}

			this.#startGame();
			this.toast(this.#isForReal ? 'På ordentlig! Now you win and lose real marbles.' : 'På lek: just for fun. Everybody keeps their own marbles.');
		},
		rain: () => {
			this.#setRain(!this.#isRaining);
			this.#tell(this.#isRaining ? 'Rain! The gravel turns to mud, the marbles roll slower, and the puddles stop them dead.' : 'The rain stops. The gravel dries, more or less.');
		},
		cheat: () => {
			this.#accuse();
		},
		teacher: () => {
			this.#callTeacher();
		},
		goOn: () => {
			this.#aiTurn();
		},
		newGame: () => {
			this.#startGame();
		},
		sound: () => {
			// Browsers only make the audio in the handler of a click, and can suspend it, so it is resumed at each click.
			this.#isSoundOn = !this.#isSoundOn && this.sound() !== undefined;
			if (this.#isSoundOn) {
				this.sound().context.resume();
			}

			const {sound} = this.parts;
			setPressed(sound, this.#isSoundOn);
			sound.textContent = this.#isSoundOn ? 'Sound: On' : 'Sound: Off';
			if (this.#isSoundOn) {
				this.#effects.click(300, 'glass', 'glass');
			}
		},
		drawer: () => {
			if (this.#drawer === 0) {
				return;
			}

			if (!this.#recess.isOver) {
				this.#speak('teacher', teacherLines.wait);
				return;
			}

			this.#bag.steel += this.#drawer;
			this.#drawer = 0;
			this.#speak('teacher', teacherLines.back, 'You get your steel ball back.');
			this.#finishUpdate();
		},
	};

	connected() {
		const {canvas} = this.parts;
		this.#yard = canvas.getContext('2d');
		this.#width = canvas.width;
		this.#height = canvas.height;
		this.#gameButtons = [...this.querySelectorAll('[data-marbles-game]')];
		this.#opponentButtons = [...this.querySelectorAll('[data-marbles-opponent]')];
		this.#spinButtons = [...this.querySelectorAll('[data-marbles-spin]')];

		const stored = this.stored('state', {});
		this.#bag = Object.fromEntries(kindOrder.map(kind => {
			const count = stored.bag?.[kind];
			return [kind, Number.isInteger(count) && count >= 0 ? Math.min(count, 999) : startingBag[kind]];
		}));

		if (Array.isArray(stored.inPlay)) {
			for (const kind of stored.inPlay.slice(0, 10)) {
				if (Object.hasOwn(this.#bag, kind)) {
					this.#bag[kind] = Math.min(this.#bag[kind] + 1, 999);
				}
			}
		}

		this.#shooterKind = Object.hasOwn(kinds, stored.shooter) ? stored.shooter : 'glass';
		this.#drawer = Number.isInteger(stored.drawer) ? clamp(stored.drawer, 0, 99) : 0;
		this.#wins = Number.isInteger(stored.wins) ? stored.wins : 0;
		this.#losses = Number.isInteger(stored.losses) ? stored.losses : 0;
		this.#day = Number.isInteger(stored.day) ? clamp(stored.day, 1, 9999) : 1;
		this.#gameId = ['hull', 'ring', 'tower', 'my-tower'].includes(stored.game) ? stored.game : 'ring';
		this.#opponentId = ['trond', 'kevin', 'geir', 'sister'].includes(stored.opponent) ? stored.opponent : 'trond';
		this.#isForReal = stored.isForReal === true;
		this.#recess = {
			index: Number.isInteger(stored.recess) ? clamp(stored.recess, 0, recesses.length - 1) : 0,
			minutes: 0,
			isOver: false,
		};

		this.loop(seconds => {
			this.#step(seconds);
		});

		this.on(canvas, 'pointerdown', event => {
			if (!event.isPrimary || event.button !== 0 || !this.#match) {
				return;
			}

			if (this.#canStartAgain()) {
				event.preventDefault();
				this.#startGame();
				return;
			}

			if (this.#match.phase === 'waiting') {
				this.#aiTurn();
				return;
			}

			if (this.#match.turn !== 'me' || this.#match.phase !== 'aim') {
				return;
			}

			const point = canvasPoint(canvas, event);
			const choices = this.#match.game === 'hull' && this.#match.stage === 'flick' ? this.#flickable() : [this.#match.ready];
			const near = choices.filter(Boolean).map(marble => ({marble, distance: Math.hypot(marble.x - point.x, marble.y - point.y)})).filter(choice => choice.distance < choice.marble.radius + 22).sort((first, second) => first.distance - second.distance)[0];
			if (near) {
				event.preventDefault();
				this.#match.ready = near.marble;
				canvas.setPointerCapture(event.pointerId);
				this.#pointerDrag = {pointerId: event.pointerId};
				this.#aim.power = 0;
				this.#requestDraw();
				return;
			}

			if (this.#canPlace()) {
				const isOnLine = this.#match.game === 'ring' ? Math.hypot(point.x - ring.x, point.y - ring.y) > ring.radius : point.y > (this.#match.ready.y - 40);
				if (isOnLine) {
					this.#placeAt(point);
				}
			}
		});

		this.on(canvas, 'pointermove', event => {
			if (!this.#pointerDrag || event.pointerId !== this.#pointerDrag.pointerId || !this.#match?.ready) {
				return;
			}

			this.#aimFrom(canvasPoint(canvas, event));
		});

		this.on(canvas, 'pointerup', event => {
			this.#endDrag(event);
		});

		this.on(canvas, 'pointercancel', event => {
			this.#endDrag(event);
		});

		this.on(canvas, 'keydown', event => {
			if (event.altKey || event.ctrlKey || event.metaKey || !this.#match) {
				return;
			}

			// The keys of the toy never scroll the page, also while the marbles roll or another kid shoots.
			if ([' ', 'Enter', 'ArrowLeft', 'ArrowRight', 'ArrowUp', 'ArrowDown'].includes(event.key)) {
				event.preventDefault();
			}

			if (event.key === ' ' || event.key === 'Enter') {
				// A held key repeats, and must not start the next game and then shoot in it.
				if (event.repeat) {
					return;
				}

				if (this.#match.phase === 'waiting') {
					this.#aiTurn();
					return;
				}

				if (this.#canStartAgain()) {
					this.#startGame();
					return;
				}
			}

			if (this.#match.turn !== 'me' || this.#match.phase !== 'aim') {
				return;
			}

			const fine = event.shiftKey ? 0.25 : 1;
			const key = event.key.toLowerCase();
			if (event.key === 'ArrowLeft' || event.key === 'ArrowRight') {
				this.#aim.angle += (event.key === 'ArrowLeft' ? -1 : 1) * 0.05 * fine;
			} else if (event.key === 'ArrowUp' || event.key === 'ArrowDown') {
				this.#aim.power = clamp(this.#aim.power + ((event.key === 'ArrowUp' ? 1 : -1) * 0.05 * fine), 0, 1);
			} else if ((key === 'a' || key === 'd') && this.#canPlace()) {
				const direction = key === 'a' ? -1 : 1;
				if (this.#match.game === 'ring') {
					this.#placeOnEdge(this.#match.ready, (this.#match.edgeAngle ?? (Math.PI / 2)) - (direction * 0.08));
					const goal = this.#target();
					this.#aim.angle = Math.atan2(goal.y - this.#match.ready.y, goal.x - this.#match.ready.x);
				} else {
					this.#placeAt({x: this.#match.ready.x + (direction * 12), y: this.#match.ready.y});
				}
			} else if (key === 'n' && this.#match.game === 'hull' && this.#match.stage === 'flick') {
				const choices = this.#flickable();
				this.#match.ready = choices[(choices.indexOf(this.#match.ready) + 1) % choices.length];
				this.#aim.angle = Math.atan2(hole.y - this.#match.ready.y, hole.x - this.#match.ready.x);
			} else if (event.key === ' ' || event.key === 'Enter') {
				this.#myShot();
			} else {
				return;
			}

			event.preventDefault();
			this.#requestDraw();
		});

		for (const [name, action] of Object.entries(this.#actions)) {
			this.on(this.parts[name], 'click', () => {
				action();
				this.#updateAll();
			});
		}

		this.on(this, 'click', event => {
			const gameButton = event.target.closest('[data-marbles-game]');
			if (gameButton) {
				this.#gameId = gameButton.dataset.marblesGame;
				this.#startGame();
				return;
			}

			const opponentButton = event.target.closest('[data-marbles-opponent]');
			if (opponentButton) {
				this.#opponentId = opponentButton.dataset.marblesOpponent;
				this.#startGame();
				return;
			}

			const spinButton = event.target.closest('[data-marbles-spin]');
			if (spinButton) {
				this.#spin = {none: 0, left: -1, right: 1}[spinButton.dataset.marblesSpin] ?? 0;
				this.#updateAll();
				return;
			}

			const kindButton = event.target.closest('[data-marbles-kind]');
			if (kindButton) {
				const kind = kindButton.dataset.marblesKind;
				if (this.#bag[kind] > 0) {
					this.#shooterKind = kind;
					this.#persist();
					// A shooter that is not yet on the gravel changes at once.
					if (this.#match?.turn === 'me' && this.#match.phase === 'aim' && this.#match.ready && !this.#match.ready.isHandful && !this.#field.includes(this.#match.ready)) {
						const {x, y} = this.#match.ready;
						this.#match.ready = makeMarble(kind, 'me', x, y);
						this.#match.ready.isShooter = true;
					}

					this.#tell(this.#match?.game === 'hull' ? `Your shooter is now a ${kinds[kind].english}. (In Hull, you flick the marbles of the game, so it stays in the bag.)` : `Your shooter is now a ${kinds[kind].english}${kind === 'steel' ? '. Watch out for the teacher!' : '.'}`);
					this.#updateAll();
				}

				return;
			}

			const tradeButton = event.target.closest('[data-marbles-trade]');
			if (tradeButton) {
				this.#trade(Number(tradeButton.dataset.marblesTrade));
			}
		});

		this.#ensureShooter();
		this.#makeBag();
		this.#makeTrades();
		this.#startGame();
		this.#draw();
	}

	// The game runs only while the canvas is on screen, not while only the buttons below it are.
	get visibilityTarget() {
		return this.parts.canvas;
	}

	// A turn that waits for the time of the game would never come without motion, so it runs at once.
	reducedMotionChanged(isReduced) {
		if (isReduced) {
			const due = this.#scheduled;
			this.#scheduled = [];
			for (const item of due) {
				item.action();
			}
		}

		this.#requestDraw();
	}
}
