// Sindre’s Arcade of the 1999 page: a cabinet with six games in one, drawn on a screen of 224 × 288 pixels, like the arcade machines of 1981: Unicorn Invaders, Paperclip Pong, Waffle Stacker, the Information Superhighway, 88×31 Breakout, and SkiFri. It takes coins, has an attract mode, a “CONTINUE?” countdown, high scores with three initials, and tickets for the Prize Counter. The games run only while the screen of the cabinet is in view and the tab is visible. With reduced motion, the games move a few steps for each key or tap, so nothing moves by itself. The arcade keeps the coins, the tickets, and the sound for the Game Room too (`GameRoom.js`), whose coin games take the same coins. What the visitor wins is kept in the browser.
const randomItem = items => items[Math.floor(Math.random() * items.length)];
const randomInteger = (minimum, maximum) => minimum + Math.floor(Math.random() * (maximum - minimum + 1));
const clamp = (value, minimum, maximum) => Math.min(Math.max(value, minimum), maximum);
const count = value => Math.max(Math.round(Number(value) || 0), 0);
const plural = (amount, word) => `${amount.toLocaleString('en-US')} ${word}${amount === 1 ? '' : 's'}`;

const shuffle = items => {
	const copy = [...items];

	for (let index = copy.length - 1; index > 0; index--) {
		const other = Math.floor(Math.random() * (index + 1));
		[copy[index], copy[other]] = [copy[other], copy[index]];
	}

	return copy;
};

// The letters of the screen, 5 × 7 pixels each, like the fonts of the arcade machines. Each number is a row, and its bits are the pixels from the left.
const glyphs = {
	A: [14, 17, 17, 31, 17, 17, 17], B: [30, 17, 17, 30, 17, 17, 30], C: [14, 17, 16, 16, 16, 17, 14], D: [28, 18, 17, 17, 17, 18, 28],
	E: [31, 16, 16, 30, 16, 16, 31], F: [31, 16, 16, 30, 16, 16, 16], G: [14, 17, 16, 23, 17, 17, 15], H: [17, 17, 17, 31, 17, 17, 17],
	I: [14, 4, 4, 4, 4, 4, 14], J: [7, 2, 2, 2, 2, 18, 12], K: [17, 18, 20, 24, 20, 18, 17], L: [16, 16, 16, 16, 16, 16, 31],
	M: [17, 27, 21, 21, 17, 17, 17], N: [17, 17, 25, 21, 19, 17, 17], O: [14, 17, 17, 17, 17, 17, 14], P: [30, 17, 17, 30, 16, 16, 16],
	Q: [14, 17, 17, 17, 21, 18, 13], R: [30, 17, 17, 30, 20, 18, 17], S: [15, 16, 16, 14, 1, 1, 30], T: [31, 4, 4, 4, 4, 4, 4],
	U: [17, 17, 17, 17, 17, 17, 14], V: [17, 17, 17, 17, 17, 10, 4], W: [17, 17, 17, 21, 21, 21, 10], X: [17, 17, 10, 4, 10, 17, 17],
	Y: [17, 17, 10, 4, 4, 4, 4], Z: [31, 1, 2, 4, 8, 16, 31],
	0: [14, 17, 19, 21, 25, 17, 14], 1: [4, 12, 4, 4, 4, 4, 14], 2: [14, 17, 1, 2, 4, 8, 31], 3: [31, 2, 4, 2, 1, 17, 14],
	4: [2, 6, 10, 18, 31, 2, 2], 5: [31, 16, 30, 1, 1, 17, 14], 6: [6, 8, 16, 30, 17, 17, 14], 7: [31, 1, 2, 4, 8, 8, 8],
	8: [14, 17, 17, 14, 17, 17, 14], 9: [14, 17, 17, 15, 1, 2, 12],
	' ': [0, 0, 0, 0, 0, 0, 0], '!': [4, 4, 4, 4, 4, 0, 4], '?': [14, 17, 1, 2, 4, 0, 4], '.': [0, 0, 0, 0, 0, 12, 12],
	',': [0, 0, 0, 0, 12, 4, 8], ':': [0, 12, 12, 0, 12, 12, 0], '-': [0, 0, 0, 31, 0, 0, 0], '\'': [4, 4, 8, 0, 0, 0, 0],
	'/': [1, 1, 2, 4, 8, 16, 16], '*': [0, 4, 21, 14, 21, 4, 0], '+': [0, 4, 4, 31, 4, 4, 0], '=': [0, 0, 31, 0, 31, 0, 0],
	'(': [2, 4, 8, 8, 8, 4, 2], ')': [8, 4, 2, 2, 2, 4, 8], '"': [10, 10, 0, 0, 0, 0, 0], '_': [0, 0, 0, 0, 0, 0, 31],
	'&': [12, 18, 20, 8, 21, 18, 13], '#': [10, 10, 31, 10, 31, 10, 10], '%': [24, 25, 2, 4, 8, 19, 3], '$': [4, 15, 20, 14, 5, 30, 4],
	'♥': [0, 10, 31, 31, 14, 4, 0], '×': [0, 17, 10, 4, 10, 17, 0], '<': [2, 4, 8, 16, 8, 4, 2], '>': [8, 4, 2, 1, 2, 4, 8],
	'▲': [0, 4, 14, 31, 0, 0, 0], '▼': [0, 0, 0, 31, 14, 4, 0], '◀': [2, 6, 14, 30, 14, 6, 2], '▶': [8, 12, 14, 15, 14, 12, 8],
	'@': [14, 17, 23, 21, 23, 16, 14],
};

const width = 224;
const height = 288;

// The screen of the cabinet, and the letters, sprites, and boxes that the games draw on it.
const makeScreen = canvas => {
	const context = canvas.getContext('2d');
	// The screen has twice the pixels of the games, so the letters are sharp.
	context.scale(canvas.width / width, canvas.height / height);

	const drawText = (text, x, y, color = '#fff', {scale = 1, align = 'left'} = {}) => {
		const characters = [...String(text).toUpperCase().replaceAll('’', '\'')];
		const textWidth = (characters.length * 6 * scale) - scale;
		let left = Math.round(align === 'center' ? x - (textWidth / 2) : (align === 'right' ? x - textWidth : x));
		context.fillStyle = color;

		for (const character of characters) {
			const rows = glyphs[character] ?? glyphs['?'];

			for (const [row, bits] of rows.entries()) {
				for (let column = 0; column < 5; column++) {
					if (bits & (16 >> column)) {
						context.fillRect(left + (column * scale), Math.round(y) + (row * scale), scale, scale);
					}
				}
			}

			left += 6 * scale;
		}
	};

	// A sprite is rows of letters, each a color of the palette, and a dot is see-through.
	const drawSprite = (rows, x, y, palette, {flip = false, scale = 1} = {}) => {
		const left = Math.round(x);
		const top = Math.round(y);

		for (const [row, line] of rows.entries()) {
			for (let column = 0; column < line.length; column++) {
				const color = palette[line[flip ? line.length - 1 - column : column]];

				if (color) {
					context.fillStyle = color;
					context.fillRect(left + (column * scale), top + (row * scale), scale, scale);
				}
			}
		}
	};

	const fill = (color, x, y, rectangleWidth, rectangleHeight) => {
		context.fillStyle = color;
		context.fillRect(Math.round(x), Math.round(y), Math.round(rectangleWidth), Math.round(rectangleHeight));
	};

	return {context, drawText, drawSprite, fill};
};

const overlaps = (first, second) => first.x < second.x + second.width && first.x + first.width > second.x && first.y < second.y + second.height && first.y + first.height > second.y;

const sprites = {
	unicorn: [
		'.........y.',
		'........yy.',
		'.......wy..',
		'..m...wwww.',
		'.mmm.wwkww.',
		'mmmwwwwwwpp',
		'mm.wwwwww..',
		'...wwwwww..',
		'..wwwwwww..',
		'..w.w..w.w.',
		'..w.w..w.w.',
	],
	// The three kinds of Y2K bugs of Unicorn Invaders, each with two frames for the march, like the squid, the crab, and the octopus of Space Invaders.
	bugs: {
		squid: [
			[
				'....ggg....',
				'...ggggg...',
				'..ggggggg..',
				'..gg.g.gg..',
				'..ggggggg..',
				'...g...g...',
				'..g.ggg.g..',
				'.g.g...g.g.',
			],
			[
				'....ggg....',
				'...ggggg...',
				'..ggggggg..',
				'..gg.g.gg..',
				'..ggggggg..',
				'....g.g....',
				'...g...g...',
				'....g.g....',
			],
		],
		crab: [
			[
				'..g.....g..',
				'...g...g...',
				'..ggggggg..',
				'.gg.ggg.gg.',
				'ggggggggggg',
				'g.ggggggg.g',
				'g.g.....g.g',
				'...gg.gg...',
			],
			[
				'..g.....g..',
				'g..g...g..g',
				'g.ggggggg.g',
				'ggg.ggg.ggg',
				'ggggggggggg',
				'.ggggggggg.',
				'..g.....g..',
				'.g.......g.',
			],
		],
		octopus: [
			[
				'...ggggg...',
				'.ggggggggg.',
				'ggggggggggg',
				'ggg..g..ggg',
				'ggggggggggg',
				'...gg.gg...',
				'..gg.g.gg..',
				'gg.......gg',
			],
			[
				'...ggggg...',
				'.ggggggggg.',
				'ggggggggggg',
				'ggg..g..ggg',
				'ggggggggggg',
				'..ggg.ggg..',
				'.gg..g..gg.',
				'..gg...gg..',
			],
		],
	},
	boom: [
		'g...g...g',
		'.g..g..g.',
		'..g...g..',
		'gg.....gg',
		'..g...g..',
		'.g..g..g.',
		'g...g...g',
	],
	// The unicorn when a zero hits it: glitter everywhere.
	unicornBoom: [
		[
			'y....m....y',
			'..y..w..m..',
			'.m..www..y.',
			'...wwwww...',
			'y.wwpwwmw.m',
			'...wwwww...',
			'.y..www..m.',
			'..m..w..y..',
			'm....y....w',
		],
		[
			'..m.....y..',
			'y...w.w...m',
			'...m...y...',
			'.w.......w.',
			'..y.....m..',
			'.w.......w.',
			'...y...m...',
			'm...w.w...y',
			'..y.....m..',
		],
	],
	disc: [
		'....ssssss....',
		'..ssrryybbss..',
		'.ssrryyggbbss.',
		'sssrry..ggbsss',
		'.sssss..sssss.',
		'..ssssssssss..',
		'....ssssss....',
	],
	envelope: [
		'wwwwwwwwwwww',
		'wkwwwwwwwwkw',
		'wwkwwwwwwkww',
		'wwwkwwwwkwww',
		'wwwwkkkkwwww',
		'wwwwwrrwwwww',
		'wwwwwwwwwwww',
		'wwwwwwwwwwww',
	],
	skier: [
		'...rr...',
		'..rrrr..',
		'...ff...',
		'..bbbb..',
		'.bbbbbb.',
		'..bbbb..',
		'..k..k..',
		'..k..k..',
		'kkkkkkkk',
	],
	skierSide: [
		'...rr.....',
		'..rrrr....',
		'...ff.....',
		'..bbbb....',
		'.bbbbbb...',
		'..bbbb....',
		'...kk.....',
		'...k.k....',
		'.kkkkkkkk.',
	],
	skierCrash: [
		'..........',
		'..........',
		'..........',
		'k.......k.',
		'.k.rr..k..',
		'..bbbbff..',
		'.bbbbbbb..',
		'k.......k.',
	],
	tree: [
		'....g....',
		'...ggg...',
		'..ggggg..',
		'...ggg...',
		'..ggggg..',
		'.ggggggg.',
		'..ggggg..',
		'.ggggggg.',
		'ggggggggg',
		'....t....',
		'....t....',
	],
	rock: [
		'..ssss..',
		'.ssssss.',
		'sssddsss',
		'ssddddss',
	],
	stump: [
		'.tttt.',
		'tttttt',
		'tttttt',
	],
	troll: [
		'..h......h..',
		'..hh.hh.hh..',
		'...gggggg...',
		'..gwkggwkg..',
		'..gggnnggg..',
		'.ggggnnnggg.',
		'.gggwwwwggg.',
		'gggggggggggg',
		'g.gggggggg.g',
		'g.gggggggg.g',
		'..gggggggg..',
		'..ggg..ggg..',
		'.ggg....ggg.',
	],
};

const palettes = {
	unicorn: {y: '#ffd700', w: '#ffffff', m: '#ff66cc', k: '#000000', p: '#ff66cc'},
	bugs: [{g: '#ff4444'}, {g: '#ff9933'}, {g: '#ffee33'}, {g: '#44ff66'}, {g: '#33ccff'}],
	boom: {g: '#ffffff'},
	disc: {s: '#d0d0e0', r: '#ff5555', y: '#ffee55', g: '#55ff55', b: '#5599ff'},
	envelope: {w: '#ffffff', k: '#555555', r: '#ff3333'},
	skier: {r: '#ff2222', f: '#ffcc99', b: '#2244cc', k: '#000000'},
	tree: {g: '#118833', t: '#663300'},
	rock: {s: '#888888', d: '#555555'},
	stump: {t: '#7a4a1a'},
	troll: {h: '#888866', g: '#6a8a4a', w: '#ffffff', k: '#000000', n: '#4a6a2a'},
};

// Whether a box touches a filled pixel of a sprite, so a shot only hits what it visibly hits, not the empty corners around a sprite.
const touchesSprite = (rows, x, y, box, {flip = false} = {}) => {
	const left = Math.max(Math.floor(box.x - x), 0);
	const right = Math.min(Math.ceil(box.x + box.width - x), rows[0].length);
	const top = Math.max(Math.floor(box.y - y), 0);
	const bottom = Math.min(Math.ceil(box.y + box.height - y), rows.length);

	for (let row = top; row < bottom; row++) {
		for (let column = left; column < right; column++) {
			const line = rows[row];

			if (line[flip ? line.length - 1 - column : column] !== '.') {
				return true;
			}
		}
	}

	return false;
};

// Each game gets the machine of the cabinet (`machine` in `setUpArcade`): the screen to draw on, the controls that are held and pressed, the pointer, and the sounds.

// Unicorn Invaders: Y2K bugs march down from space, faster as there are fewer, and drop zeros. The unicorn shoots waffles from its horn, from behind blocks of brown cheese, which crumble. An AOL CD flies over for extra points. Each wave starts lower and drops more zeros.
const createInvaders = ({fill, drawText, drawSprite, held, pressed, pointer, sounds, beep, waitFrames, isReducedMotion}) => {
	const game = {score: 0, lives: 3, isOver: false, usesPointer: true, hud: '#ffffff'};
	const groundY = 271;
	const player = {x: 106, y: 257, width: 11, height: 11, facesLeft: false};
	// The rows from the top: the squids are worth the most, like in Space Invaders.
	const rowKinds = ['squid', 'crab', 'crab', 'octopus', 'octopus'];
	const rowPoints = [30, 20, 20, 10, 10];
	// The four notes of the march, which get faster with the bugs, like the heartbeat of Space Invaders.
	const marchNotes = [98, 87, 78, 73];
	let wave = 0;
	let bugs = [];
	let direction = 1;
	let marchTimer = 0;
	let marchFrame = 0;
	let marchNote = 0;
	let shots = [];
	let fireCooldown = 0;
	// A press of fire that waits a moment for the unicorn to be ready, so no press is lost.
	let fireBuffer = 0;
	let bombs = [];
	let shields = [];
	let disc;
	let discTimer = 900;
	let explosions = [];
	let popups = [];
	let readyFrames = waitFrames(150);
	let deathFrames = 0;
	let hasExtraLife = false;

	const setUpWave = () => {
		bugs = [];

		for (let row = 0; row < rowKinds.length; row++) {
			for (let column = 0; column < 8; column++) {
				bugs.push({x: 40 + (column * 18), y: 36 + (row * 14) + (Math.min(wave, 4) * 8), width: 11, height: 8, row});
			}
		}

		direction = 1;
		marchTimer = 0;
		bombs = [];
		shots = [];
	};

	const setUpShields = () => {
		shields = [];

		for (let index = 0; index < 4; index++) {
			for (let row = 0; row < 8; row++) {
				for (let column = 0; column < 11; column++) {
					// An arch, like the bunkers of Space Invaders, with round top corners and a gap at the bottom of the middle.
					const isCorner = (row === 0 && (column < 2 || column > 8)) || (row === 1 && (column === 0 || column === 10));
					const isArch = row >= 5 && column >= 3 && column <= 7;

					if (!isCorner && !isArch) {
						shields.push({x: 21 + (index * 50) + (column * 2), y: 222 + (row * 2), width: 2, height: 2});
					}
				}
			}
		}
	};

	setUpWave();
	setUpShields();

	const bugSprite = bug => sprites.bugs[rowKinds[bug.row]][marchFrame];

	// A hit takes a ragged bite out of the cheese, bigger for a zero than for a waffle.
	const crumble = (cell, radius) => {
		shields = shields.filter(item => {
			const distance = Math.hypot(item.x - cell.x, item.y - cell.y);
			return distance > radius || (distance > radius - 2 && Math.random() < 0.5);
		});
	};

	const hitShield = (thing, radius) => {
		const cell = shields.find(item => overlaps(item, thing));

		if (!cell) {
			return false;
		}

		crumble(cell, radius);
		return true;
	};

	const addPopup = (text, x, y, color = '#ffffff') => {
		popups.push({text: String(text), x, y, color, frames: 45});
	};

	const addScore = points => {
		game.score += points;

		if (!hasExtraLife && game.score >= 1500) {
			hasExtraLife = true;
			game.lives++;
			game.banner = {text: 'EXTRA UNICORN!', frames: 90};
			sounds.bonus();
		}
	};

	const fire = () => {
		// The waffle comes out of the horn, which is on the side the unicorn faces.
		shots.push({x: player.x + (player.facesLeft ? 0 : 8), y: player.y - 4, width: 3, height: 5});
		// With reduced motion, a press is a few steps, so the unicorn is ready again by the next press.
		fireCooldown = isReducedMotion() ? 6 : 16;
		fireBuffer = 0;
		sounds.shoot();
	};

	const die = () => {
		game.lives--;
		deathFrames = waitFrames(100);
		bombs = [];
		shots = [];
		sounds.die();
	};

	// Moves a waffle up in small steps, so it never skips over a thin bit of cheese or a bug, and returns whether it still flies.
	const moveShot = shot => {
		for (let step = 0; step < 3; step++) {
			shot.y -= 2;

			if (shot.y < 14) {
				return false;
			}

			if (hitShield(shot, 2.5)) {
				return false;
			}

			const bug = bugs.find(item => overlaps(item, shot) && touchesSprite(bugSprite(item), item.x, item.y, shot));

			if (bug) {
				bugs = bugs.filter(item => item !== bug);
				const points = rowPoints[bug.row];
				addScore(points);
				explosions.push({x: bug.x + 1, y: bug.y, frames: 14, color: palettes.bugs[bug.row].g});
				addPopup(points, bug.x + 5, bug.y, palettes.bugs[bug.row].g);
				sounds.hit();
				return false;
			}

			if (disc && overlaps(disc, shot)) {
				const points = randomItem([50, 100, 150, 300]);
				addScore(points);
				game.banner = {text: `${points} FREE HOURS!`, frames: 90};
				addPopup(points, disc.x + 7, disc.y, '#ff66cc');
				disc = undefined;
				sounds.bonus();
				return false;
			}
		}

		return true;
	};

	const march = () => {
		marchFrame = 1 - marchFrame;
		const isAtEdge = bugs.some(bug => (direction > 0 ? bug.x + bug.width + 3 > width - 4 : bug.x - 3 < 4));

		for (const bug of bugs) {
			if (isAtEdge) {
				bug.y += 8;
			} else {
				bug.x += 3 * direction;
			}
		}

		if (isAtEdge) {
			direction = -direction;
		}

		beep(marchNotes[marchNote], 0.09, {volume: 0.06});
		marchNote = (marchNote + 1) % marchNotes.length;

		// The bugs eat the cheese they march through.
		if (bugs.some(bug => bug.y + bug.height >= 222)) {
			shields = shields.filter(cell => !bugs.some(bug => overlaps(bug, cell)));
		}
	};

	const dropBomb = () => {
		// The bottom bug of a column drops the zero. Every other zero comes from the column above the unicorn, so standing still is not safe.
		const columnBugs = Math.random() < 0.5 ? bugs.filter(bug => Math.abs((bug.x + 5) - (player.x + 5)) < 10) : [];
		const shooter = columnBugs.length > 0 ? randomItem(columnBugs) : randomItem(bugs);
		const bottom = bugs.filter(bug => Math.abs(bug.x - shooter.x) < 4).toSorted((first, second) => second.y - first.y)[0];
		bombs.push({x: bottom.x + 4, y: bottom.y + 8, width: 3, height: 6});
	};

	const updateEffects = () => {
		for (const explosion of explosions) {
			explosion.frames--;
		}

		explosions = explosions.filter(explosion => explosion.frames > 0);

		for (const popup of popups) {
			popup.frames--;
			popup.y -= 0.3;
		}

		popups = popups.filter(popup => popup.frames > 0);
	};

	game.update = () => {
		updateEffects();

		// When a zero hits the unicorn, everything stops while it explodes, like in Space Invaders.
		if (deathFrames > 0) {
			deathFrames--;

			if (deathFrames === 0) {
				if (game.lives <= 0) {
					game.isOver = true;
				} else {
					player.x = 106;
					readyFrames = waitFrames(60);
				}
			}

			return;
		}

		const speed = 2;

		if (held.has('left')) {
			player.x -= speed;
			player.facesLeft = true;
		} else if (held.has('right')) {
			player.x += speed;
			player.facesLeft = false;
		} else if (pointer.isDown && pointer.x !== undefined) {
			const deltaX = clamp(pointer.x - (player.x + 5), -speed * 1.5, speed * 1.5);
			player.x += deltaX;

			if (Math.abs(deltaX) > 0.5) {
				player.facesLeft = deltaX < 0;
			}
		}

		player.x = clamp(player.x, 4, width - 15);

		// A press waits up to 12 steps for the unicorn to be ready. Holding fire, or a finger on the screen, fires as fast as the unicorn can.
		if (pressed.has('a')) {
			fireBuffer = 12;
		}

		fireCooldown--;
		fireBuffer--;

		if (shots.length < 2 && fireCooldown <= 0 && (fireBuffer > 0 || held.has('a') || pointer.isDown)) {
			fire();
		}

		shots = shots.filter(shot => moveShot(shot));

		// Before a wave, the bugs wait, and the screen says how to play.
		if (readyFrames > 0) {
			readyFrames--;
			return;
		}

		// The bugs march one step at a time, and faster when there are fewer of them, like in Space Invaders.
		marchTimer--;

		if (marchTimer <= 0) {
			marchTimer = Math.max(1, Math.round(bugs.length * 0.5) + 2 - Math.min(wave, 3));
			march();
		}

		if (bugs.some(bug => bug.y + bug.height >= player.y + 2)) {
			game.lives = 1;
			game.banner = {text: 'THE BUGS LANDED!', frames: 100};
			die();
			return;
		}

		if (bugs.length > 0 && bombs.length < Math.min(3 + wave, 6) && Math.random() < 0.03 + (Math.min(wave, 6) * 0.006)) {
			dropBomb();
		}

		for (const bomb of bombs) {
			bomb.y += Math.min(1.7 + (wave * 0.15), 2.8);
		}

		bombs = bombs.filter(bomb => bomb.y < groundY - 4 && !hitShield(bomb, 3.5));

		if (bombs.some(bomb => overlaps(bomb, player) && touchesSprite(sprites.unicorn, player.x, player.y, bomb, {flip: player.facesLeft}))) {
			die();
			return;
		}

		discTimer--;

		if (discTimer <= 0 && !disc) {
			const fromLeft = Math.random() < 0.5;
			disc = {x: fromLeft ? -14 : width, y: 20, width: 14, height: 7, speed: fromLeft ? 0.9 : -0.9};
			discTimer = randomInteger(1200, 1800);
		}

		if (disc) {
			disc.x += disc.speed;

			if (disc.x < -16 || disc.x > width + 2) {
				disc = undefined;
			}
		}

		if (bugs.length === 0) {
			wave++;
			game.banner = {text: `WAVE ${wave + 1}`, frames: 100};
			game.announcement = `Wave ${wave + 1}! The bugs come lower, and drop more zeros.`;
			readyFrames = waitFrames(100);
			setUpWave();
			setUpShields();
			sounds.bonus();
		}
	};

	game.draw = () => {
		fill('#000010', 0, 0, width, height);

		// A few stars.
		for (let index = 0; index < 30; index++) {
			fill('#333366', (index * 53) % width, 16 + ((index * 97) % 200), 1, 1);
		}

		for (const bug of bugs) {
			drawSprite(bugSprite(bug), bug.x, bug.y, palettes.bugs[bug.row]);
		}

		for (const cell of shields) {
			fill('#b8682a', cell.x, cell.y, cell.width, cell.height);
		}

		if (disc) {
			drawSprite(sprites.disc, disc.x, disc.y, palettes.disc);
		}

		for (const shot of shots) {
			// A waffle, with its squares.
			fill('#ffcc55', shot.x, shot.y, 3, 5);
			fill('#a06a1a', shot.x + 1, shot.y + 1, 1, 1);
			fill('#a06a1a', shot.x + 1, shot.y + 3, 1, 1);
		}

		for (const bomb of bombs) {
			drawText('0', bomb.x - 1, bomb.y - 1, '#ff5555');
		}

		for (const explosion of explosions) {
			drawSprite(sprites.boom, explosion.x, explosion.y, {g: explosion.color});
		}

		if (deathFrames > 0) {
			drawSprite(sprites.unicornBoom[Math.floor(deathFrames / 6) % 2], player.x, player.y - 1, palettes.unicorn);
		} else {
			drawSprite(sprites.unicorn, player.x, player.y, palettes.unicorn, {flip: player.facesLeft});
		}

		for (const popup of popups) {
			drawText(popup.text, popup.x, popup.y, popup.color, {align: 'center'});
		}

		fill('#44ff66', 0, groundY, width, 1);
		drawText(`WAVE ${wave + 1}`, 4, 277, '#44ff66');

		if (readyFrames > 0 && deathFrames === 0) {
			drawText(`WAVE ${wave + 1}`, 112, 150, '#ffee55', {scale: 2, align: 'center'});
			drawText('GET READY!', 112, 172, '#ffffff', {align: 'center'});

			if (wave === 0 && game.score === 0) {
				drawText('◀ ▶ MOVE    A FIRE', 112, 190, '#33ffff', {align: 'center'});
				drawText('OR DRAG ON THE SCREEN', 112, 202, '#33ffff', {align: 'center'});
			}
		}
	};

	game.continue = () => {
		game.lives = 3;
		game.isOver = false;
		deathFrames = 0;
		player.x = 106;
		readyFrames = waitFrames(90);

		// Bugs that landed go back up, so the continue is not over at once.
		if (bugs.some(bug => bug.y + bug.height >= player.y - 30)) {
			setUpWave();
			setUpShields();
		}
	};

	game.tickets = () => Math.max(1, Math.floor(game.score / 100));
	return game;
};

// Paperclip Pong: the visitor plays at the bottom, and the paperclip at the top, which only wants to help. The ball leaves a trail of glitter. The first to 7 wins.
const createPong = ({context, fill, drawText, held, pointer, sounds, waitFrames}) => {
	const game = {score: 0, lives: 7, isOver: false, usesPointer: true, hud: '#ffffff'};
	const player = {x: 94, y: 262, width: 36, height: 4};
	const paperclip = {x: 94, y: 30, width: 36, height: 4};
	let points = {player: 0, paperclip: 0};
	let ball;
	let serveFrames = waitFrames(60);
	let trail = [];
	let hue = 0;
	let speech;

	const helpLines = ['IT LOOKS LIKE YOU ARE|TRYING TO WIN.', 'WOULD YOU LIKE HELP|WITH THAT?', 'I SEE YOU MISSED.|NEED A HAND?', 'DID YOU KNOW YOU CAN|PRESS F1 FOR HELP?'];
	const angryLines = ['WAS THAT AN|ACCIDENT?', 'I WAS ONLY TRYING|TO HELP!', 'IT LOOKS LIKE YOU|ARE CHEATING.', 'I WILL REMEMBER|THIS.'];

	const serve = towardPlayer => {
		const angle = (Math.random() - 0.5) * 1.2;
		const speed = 2.6;
		ball = {x: 110, y: 142, width: 4, height: 4, vx: Math.sin(angle) * speed, vy: Math.cos(angle) * speed * (towardPlayer ? 1 : -1), speed};
	};

	let paperclipAim = 0;

	const bounce = (paddle, direction) => {
		// Where the ball hits the paddle sets the angle, so the visitor can aim.
		const offset = clamp(((ball.x + 2) - (paddle.x + (paddle.width / 2))) / (paddle.width / 2), -1, 1);
		ball.speed = Math.min(ball.speed + 0.25, 6);
		ball.vx = offset * ball.speed * 0.75;
		ball.vy = direction * Math.sqrt((ball.speed ** 2) - (ball.vx ** 2));
		paperclipAim = randomInteger(-12, 12);
		sounds.blip();
	};

	game.update = () => {
		const speed = 4;

		if (held.has('left')) {
			player.x -= speed;
		} else if (held.has('right')) {
			player.x += speed;
		} else if (pointer.isDown && pointer.x !== undefined) {
			player.x += clamp(pointer.x - (player.x + (player.width / 2)), -speed * 2, speed * 2);
		}

		player.x = clamp(player.x, 2, width - player.width - 2);

		if (speech) {
			speech.frames--;

			if (speech.frames <= 0) {
				speech = undefined;
			}
		}

		if (!ball) {
			serveFrames--;

			if (serveFrames <= 0) {
				serve(points.paperclip > points.player);
			}

			return;
		}

		// The paperclip follows the ball when it comes into its half, a little slower than the ball can go, and not always with the middle of its paddle, so a fast ball with an angle gets past it.
		const target = ball.vy < 0 && ball.y < 190 ? ball.x + 2 + paperclipAim : width / 2;
		paperclip.x += clamp(target - (paperclip.x + (paperclip.width / 2)), -2.2, 2.2);
		paperclip.x = clamp(paperclip.x, 2, width - paperclip.width - 2);

		ball.x += ball.vx;
		ball.y += ball.vy;
		hue = (hue + 12) % 360;
		trail.push({x: ball.x, y: ball.y, hue});
		trail = trail.slice(-10);

		if (ball.x < 2 || ball.x > width - 6) {
			ball.vx = -ball.vx;
			ball.x = clamp(ball.x, 2, width - 6);
		}

		if (ball.vy > 0 && overlaps(ball, player)) {
			bounce(player, -1);
		}

		if (ball.vy < 0 && overlaps(ball, paperclip)) {
			bounce(paperclip, 1);
		}

		if (ball.y < 10 || ball.y > height - 14) {
			const playerScored = ball.y < 10;

			if (playerScored) {
				points.player++;
				game.score += 100;
				speech = {lines: randomItem(angryLines).split('|'), frames: 150};
				sounds.bonus();
			} else {
				points.paperclip++;
				game.lives--;
				speech = {lines: randomItem(helpLines).split('|'), frames: 150};
				sounds.hit();
			}

			ball = undefined;
			trail = [];
			serveFrames = waitFrames(90);

			if (points.player >= 7) {
				game.score += 1000 + (game.lives * 100);
				game.won = true;
				game.isOver = true;
				game.banner = {text: 'YOU BEAT THE PAPERCLIP!', frames: 120};
			} else if (points.paperclip >= 7) {
				game.isOver = true;
			}
		}
	};

	game.draw = () => {
		fill('#003300', 0, 0, width, height);

		for (let x = 4; x < width; x += 12) {
			fill('#2a6a2a', x, 145, 6, 2);
		}

		drawText(points.paperclip, 112, 120, '#2a8a2a', {scale: 3, align: 'center'});
		drawText(points.player, 112, 154, '#2a8a2a', {scale: 3, align: 'center'});

		for (const [index, spot] of trail.entries()) {
			fill(`hsl(${spot.hue} 100% 65%)`, spot.x + 1, spot.y + 1, 2, 2);

			if (index % 3 === 0) {
				fill('#ffffff', spot.x + 2 + ((index % 2) * 3) - 1, spot.y - 2, 1, 1);
			}
		}

		if (ball) {
			fill('#ffffff', ball.x, ball.y, ball.width, ball.height);
		}

		fill('#ff66cc', player.x, player.y, player.width, player.height);
		fill('#ffd700', player.x + 2, player.y + 1, player.width - 4, 2);

		// A paperclip on its side, with eyes.
		context.strokeStyle = '#c0c0d0';
		context.lineWidth = 1.5;
		context.beginPath();
		context.roundRect(paperclip.x, paperclip.y - 2, paperclip.width, 8, 4);
		context.roundRect(paperclip.x + 4, paperclip.y, paperclip.width - 10, 4, 2);
		context.stroke();
		fill('#ffffff', paperclip.x + 12, paperclip.y - 8, 4, 4);
		fill('#ffffff', paperclip.x + 20, paperclip.y - 8, 4, 4);
		fill('#000000', paperclip.x + 14, paperclip.y - 7, 2, 2);
		fill('#000000', paperclip.x + 22, paperclip.y - 7, 2, 2);

		if (speech) {
			const top = 44;
			const boxWidth = (Math.max(...speech.lines.map(line => line.length)) * 6) + 10;
			const left = clamp(paperclip.x + 18 - (boxWidth / 2), 2, width - boxWidth - 2);
			fill('#ffffcc', left, top, boxWidth, (speech.lines.length * 9) + 6);
			fill('#000000', left, top, boxWidth, 1);
			fill('#000000', left, top + (speech.lines.length * 9) + 5, boxWidth, 1);

			for (const [index, line] of speech.lines.entries()) {
				drawText(line, left + 5, top + 4 + (index * 9), '#000000');
			}
		}
	};

	game.continue = () => {
		points = {player: 0, paperclip: 0};
		game.lives = 7;
		game.isOver = false;
		serveFrames = waitFrames(60);
	};

	game.tickets = () => Math.max(1, Math.floor(game.score / 50));
	return game;
};

// Waffle Stacker: falling pieces of waffle with toppings. A full row is eaten, and four rows at once is a brunost.
const createStacker = ({context, fill, drawText, held, pressed, sounds}) => {
	const game = {score: 0, lives: 1, isOver: false, usesPointer: false, hud: '#ffffff'};
	const columns = 10;
	const rows = 20;
	const cell = 11;
	const left = 14;
	const top = 44;
	const toppings = ['#e8b04a', '#8b4a1c', '#d22d4b', '#4a5ad2', '#f2efe2', '#77cc33', '#ffe066'];
	const shapes = [
		[[1, 1, 1, 1]],
		[[1, 1], [1, 1]],
		[[0, 1, 0], [1, 1, 1]],
		[[0, 1, 1], [1, 1, 0]],
		[[1, 1, 0], [0, 1, 1]],
		[[1, 0, 0], [1, 1, 1]],
		[[0, 0, 1], [1, 1, 1]],
	];
	let board = Array.from({length: rows}, () => Array.from({length: columns}).fill(undefined));
	let piece;
	// The pieces come from a shuffled bag of all seven, like in the Tetris games after 2001, so the long piece never stays away for long.
	let bag = [];

	const takeFromBag = () => {
		if (bag.length === 0) {
			bag = shuffle([0, 1, 2, 3, 4, 5, 6]);
		}

		return bag.pop();
	};

	let next = takeFromBag();
	let fallTimer = 0;
	let repeatTimer = 0;
	let lines = 0;
	let level = 0;

	const rotate = shape => shape[0].map((_, column) => shape.map(row => row[column]).toReversed());

	const fits = (shape, x, y) => shape.every((row, rowIndex) => row.every((filled, columnIndex) => {
		if (!filled) {
			return true;
		}

		const boardX = x + columnIndex;
		const boardY = y + rowIndex;
		return boardX >= 0 && boardX < columns && boardY < rows && (boardY < 0 || !board[boardY][boardX]);
	}));

	const spawn = () => {
		piece = {shape: shapes[next], color: toppings[next], x: 3, y: 0};
		next = takeFromBag();

		if (!fits(piece.shape, piece.x, piece.y)) {
			game.isOver = true;
		}
	};

	const lock = () => {
		for (const [rowIndex, row] of piece.shape.entries()) {
			for (const [columnIndex, filled] of row.entries()) {
				if (filled && piece.y + rowIndex >= 0) {
					board[piece.y + rowIndex][piece.x + columnIndex] = piece.color;
				}
			}
		}

		const remaining = board.filter(row => row.some(color => !color));
		const cleared = rows - remaining.length;

		if (cleared > 0) {
			board = [...Array.from({length: cleared}, () => Array.from({length: columns}).fill(undefined)), ...remaining];
			game.score += [0, 40, 100, 300, 1200][cleared] * (level + 1);
			lines += cleared;
			level = Math.floor(lines / 10);
			game.banner = {text: cleared === 4 ? 'BRUNOST!!!' : randomItem(['YUM!', 'TASTY!', 'NOM NOM!', 'WAFFLE TIME!']), frames: 60};

			if (cleared === 4) {
				sounds.bonus();
			} else {
				sounds.coin();
			}
		} else {
			sounds.blip();
		}

		spawn();
	};

	const move = deltaX => {
		if (fits(piece.shape, piece.x + deltaX, piece.y)) {
			piece.x += deltaX;
		}
	};

	game.update = () => {
		if (pressed.has('up') || pressed.has('a')) {
			const rotated = rotate(piece.shape);
			// It moves sideways a little when it rotates against a wall, so it can still turn there.
			const kick = [0, -1, 1, -2, 2].find(offset => fits(rotated, piece.x + offset, piece.y));

			if (kick !== undefined) {
				piece.shape = rotated;
				piece.x += kick;
			}
		}

		if (pressed.has('left') || pressed.has('right')) {
			move(pressed.has('left') ? -1 : 1);
			repeatTimer = 10;
		} else if (held.has('left') || held.has('right')) {
			repeatTimer--;

			if (repeatTimer <= 0) {
				move(held.has('left') ? -1 : 1);
				repeatTimer = 4;
			}
		}

		fallTimer--;

		// Down drops faster at once, not only after the next step of the fall.
		if (held.has('down')) {
			fallTimer = Math.min(fallTimer, 2);
		}

		if (fallTimer <= 0) {
			fallTimer = held.has('down') ? 2 : Math.max(4, 40 - (level * 4));

			if (fits(piece.shape, piece.x, piece.y + 1)) {
				piece.y++;

				if (held.has('down')) {
					game.score++;
				}
			} else {
				lock();
			}
		}
	};

	const drawWaffle = (x, y, color) => {
		fill(color, x, y, cell - 1, cell - 1);
		// The squares of a waffle, darker.
		context.fillStyle = 'rgb(0 0 0 / 25%)';
		context.fillRect(x + 3, y, 1, cell - 1);
		context.fillRect(x + 6, y, 1, cell - 1);
		context.fillRect(x, y + 3, cell - 1, 1);
		context.fillRect(x, y + 6, cell - 1, 1);
	};

	game.draw = () => {
		fill('#1a0f2e', 0, 0, width, height);
		fill('#000000', left - 2, top - 2, (columns * cell) + 3, (rows * cell) + 3);
		fill('#3a2a1a', left - 3, top - 3, 1, (rows * cell) + 5);
		fill('#3a2a1a', left + (columns * cell) + 1, top - 3, 1, (rows * cell) + 5);

		for (const [rowIndex, row] of board.entries()) {
			for (const [columnIndex, color] of row.entries()) {
				if (color) {
					drawWaffle(left + (columnIndex * cell), top + (rowIndex * cell), color);
				}
			}
		}

		if (piece) {
			// An outline where the piece will land, so it is clear where it goes.
			let landingY = piece.y;

			while (fits(piece.shape, piece.x, landingY + 1)) {
				landingY++;
			}

			context.strokeStyle = 'rgb(255 255 255 / 40%)';
			context.lineWidth = 1;

			for (const [rowIndex, row] of piece.shape.entries()) {
				for (const [columnIndex, filled] of row.entries()) {
					if (filled && landingY + rowIndex >= 0) {
						context.strokeRect(left + ((piece.x + columnIndex) * cell) + 0.5, top + ((landingY + rowIndex) * cell) + 0.5, cell - 2, cell - 2);
					}
				}
			}

			for (const [rowIndex, row] of piece.shape.entries()) {
				for (const [columnIndex, filled] of row.entries()) {
					if (filled && piece.y + rowIndex >= 0) {
						drawWaffle(left + ((piece.x + columnIndex) * cell), top + ((piece.y + rowIndex) * cell), piece.color);
					}
				}
			}
		}

		const side = 140;
		drawText('NEXT', side, top, '#ffee55');

		for (const [rowIndex, row] of shapes[next].entries()) {
			for (const [columnIndex, filled] of row.entries()) {
				if (filled) {
					drawWaffle(side + (columnIndex * cell), top + 14 + (rowIndex * cell), toppings[next]);
				}
			}
		}

		drawText('LINES', side, top + 50, '#ffee55');
		drawText(lines, side, top + 60);
		drawText('LEVEL', side, top + 78, '#ffee55');
		drawText(level + 1, side, top + 88);
		drawText('TOPPINGS:', side, top + 112, '#ff99cc');

		for (const [index, name] of ['WAFFLE', 'BRUNOST', 'JAM', 'BLUEBERRY', 'CREAM', 'KIWI', 'BUTTER'].entries()) {
			fill(toppings[index], side, top + 124 + (index * 10), 6, 6);
			drawText(name, side + 9, top + 124 + (index * 10), '#cccccc');
		}
	};

	game.continue = () => {
		board = board.map(row => row.map(() => undefined));
		game.isOver = false;
		spawn();
	};

	game.tickets = () => Math.max(1, Math.floor(game.score / 100));
	spawn();
	return game;
};

// The Information Superhighway: an e-mail hops across five lanes of traffic and the data stream, on floppy disks and CDs, to the inboxes at the top, like Frogger.
const createHighway = ({context, fill, drawText, drawSprite, held, pressed, sounds, waitFrames}) => {
	const game = {score: 0, lives: 3, isOver: false, usesPointer: false, hud: '#ffffff'};
	const rowY = row => 24 + (row * 16);
	// The floppies and the CDs are drawn 16 pixels apart, so the lengths of their lanes are a whole number of them, and the e-mail can ride every one that the visitor sees.
	const lanes = [
		{row: 1, speed: -0.8, length: 48, gap: 42, kind: 'floppy'},
		{row: 2, speed: 0.7, length: 48, gap: 40, kind: 'cd'},
		{row: 3, speed: -1.1, length: 64, gap: 56, kind: 'floppy'},
		{row: 4, speed: 0.9, length: 32, gap: 48, kind: 'cd'},
		{row: 5, speed: -0.6, length: 48, gap: 44, kind: 'floppy'},
		{row: 7, speed: 0.8, length: 48, gap: 70, kind: 'car', label: 'AOL', color: '#ffcc00'},
		{row: 8, speed: -1.6, length: 18, gap: 90, kind: 'car', label: 'T1', color: '#ff3333'},
		{row: 9, speed: 1, length: 40, gap: 60, kind: 'car', label: '56K', color: '#999999'},
		{row: 10, speed: -0.9, length: 20, gap: 56, kind: 'car', label: 'IE', color: '#3399ff'},
		{row: 11, speed: 0.6, length: 20, gap: 60, kind: 'car', label: 'NN', color: '#33cc99'},
	];
	const inboxes = [8, 56, 104, 152, 200];
	let filled = [];
	let level = 0;
	let player;
	let hopTimer = 0;
	let timeLeft;
	let bestRow;
	let deathFrames = 0;
	let deathText = '';

	const reset = () => {
		player = {x: 104, y: rowY(12), row: 12, width: 12, height: 8};
		timeLeft = 1800;
		bestRow = 12;
	};

	const things = lane => {
		const span = lane.length + lane.gap;
		const amount = Math.ceil((width + span) / span);
		const offset = ((lane.offset % span) + span) % span;
		return Array.from({length: amount}, (_, index) => ({x: (index * span) + offset - span, y: rowY(lane.row) + 2, width: lane.length, height: 12}));
	};

	for (const lane of lanes) {
		lane.offset = Math.random() * 100;
	}

	reset();

	const die = text => {
		game.lives--;
		deathFrames = waitFrames(50);
		deathText = text;
		sounds.die();
	};

	game.update = () => {
		for (const lane of lanes) {
			lane.offset += lane.speed * (1 + (level * 0.15));
		}

		if (deathFrames > 0) {
			deathFrames--;

			if (deathFrames === 0) {
				if (game.lives <= 0) {
					game.isOver = true;
				} else {
					reset();
				}
			}

			return;
		}

		// Each press hops, and a held key hops again after a moment. With reduced motion, a press is only a few steps, so it must never wait for the last hop.
		hopTimer--;
		const directions = ['up', 'down', 'left', 'right'];
		const direction = directions.find(name => pressed.has(name)) ?? directions.find(name => held.has(name) && hopTimer <= 0);

		if (direction) {
			hopTimer = 13;

			if (direction === 'up' && player.row > 0) {
				player.row--;
			} else if (direction === 'down' && player.row < 12) {
				player.row++;
			} else if (direction === 'left') {
				player.x = Math.max(0, player.x - 16);
			} else if (direction === 'right') {
				player.x = Math.min(width - 12, player.x + 16);
			}

			player.y = rowY(player.row) + 4;
			sounds.blip();

			if (player.row < bestRow) {
				bestRow = player.row;
				game.score += 10;
			}
		}

		timeLeft--;

		if (timeLeft <= 0) {
			die('TIMED OUT!');
			return;
		}

		const box = {x: player.x + 2, y: rowY(player.row) + 4, width: 8, height: 8};

		if (player.row === 0) {
			const inbox = inboxes.findIndex(x => Math.abs((player.x + 6) - (x + 8)) < 9);

			if (inbox === -1 || filled.includes(inbox)) {
				die('BOUNCED!');
				return;
			}

			filled.push(inbox);
			game.score += 50 + Math.floor(timeLeft / 30);
			sounds.coin();

			if (filled.length === inboxes.length) {
				filled = [];
				level++;
				game.score += 1000;
				game.banner = {text: 'ALL MAIL DELIVERED!', frames: 100};
			} else {
				game.banner = {text: 'YOU\'VE GOT MAIL!', frames: 70};
			}

			reset();
			return;
		}

		const lane = lanes.find(item => item.row === player.row);

		if (!lane) {
			return;
		}

		if (lane.kind === 'car') {
			if (things(lane).some(thing => overlaps(thing, box))) {
				die(randomItem(['ERROR 404!', 'SPLAT!', 'CONNECTION LOST!']));
			}

			return;
		}

		// In the data stream, the e-mail rides a floppy or a CD while any of it is on one, and is lost when it falls in, or rides off the screen. A car only hits the middle of the e-mail, so the game forgives a close call both ways.
		if (!things(lane).some(thing => overlaps(thing, {...box, x: player.x, width: 12}))) {
			die('LOST IN CYBERSPACE!');
			return;
		}

		player.x += lane.speed * (1 + (level * 0.15));

		if (player.x < -4 || player.x > width - 8) {
			die('LOST IN CYBERSPACE!');
		}
	};

	game.draw = () => {
		fill('#000000', 0, 0, width, height);
		// The inboxes, the data stream, the sidewalk in the middle, the road, and the start.
		fill('#113311', 0, rowY(0), width, 16);
		fill('#000066', 0, rowY(1), width, 80);
		fill('#555555', 0, rowY(6), width, 16);
		fill('#222222', 0, rowY(7), width, 80);
		fill('#555555', 0, rowY(12), width, 16);
		drawText('SURF THE WEB', 112, rowY(6) + 5, '#bbbbbb', {align: 'center'});

		for (let row = 8; row <= 11; row++) {
			for (let x = 0; x < width; x += 16) {
				fill('#777777', x, rowY(row), 8, 1);
			}
		}

		for (const [index, x] of inboxes.entries()) {
			fill('#000000', x, rowY(0) + 1, 16, 15);
			drawText('@', x + 5, rowY(0) + 4, '#33ff66');

			if (filled.includes(index)) {
				drawSprite(sprites.envelope, x + 2, rowY(0) + 4, palettes.envelope);
			}
		}

		for (const lane of lanes) {
			for (const thing of things(lane)) {
				if (lane.kind === 'car') {
					fill(lane.color, thing.x, thing.y, thing.width, thing.height);
					fill('#000000', thing.x + 2, thing.y + 10, 4, 3);
					fill('#000000', thing.x + thing.width - 6, thing.y + 10, 4, 3);
					drawText(lane.label, thing.x + (thing.width / 2), thing.y + 2, '#000000', {align: 'center'});
				} else if (lane.kind === 'floppy') {
					for (let x = thing.x; x < thing.x + thing.width; x += 16) {
						fill('#2244aa', x, thing.y, 14, 12);
						fill('#c0c0c0', x + 3, thing.y, 8, 4);
						fill('#ffffff', x + 3, thing.y + 7, 8, 5);
					}
				} else {
					for (let x = thing.x; x < thing.x + thing.width; x += 16) {
						context.fillStyle = '#d0d0e0';
						context.beginPath();
						context.arc(x + 7, thing.y + 6, 6, 0, Math.PI * 2);
						context.fill();
						fill('#ff66cc', x + 6, thing.y + 5, 2, 2);
					}
				}
			}
		}

		if (deathFrames > 0) {
			drawText('×', player.x + 3, rowY(player.row) + 4, '#ff3333', {scale: 1});
			drawText(deathText, 112, 250, '#ff5555', {align: 'center'});
		} else {
			drawSprite(sprites.envelope, player.x, rowY(player.row) + 4, palettes.envelope);
		}

		drawText('TIME', 4, 262, '#ffee55');
		fill(timeLeft < 400 ? '#ff3333' : '#33ff66', 32, 263, (timeLeft / 1800) * 180, 5);
		drawText(`LEVEL ${level + 1}`, 112, 274, '#bbbbbb', {align: 'center'});
	};

	game.continue = () => {
		game.lives = 3;
		game.isOver = false;
		reset();
	};

	game.tickets = () => Math.max(1, Math.floor(game.score / 50));
	return game;
};

const brickName = image => image.dataset.source.split('/').at(-1).replace('.gif', '').replace('button-', '').replaceAll('-', ' ');

const createBreakout = ({context, fill, held, pressed, pointer, drawText, sounds, brickImages}) => {
	const game = {score: 0, lives: 3, isOver: false, usesPointer: true, hud: '#ffffff'};
	const paddle = {x: 92, y: 262, width: 40, height: 5};
	let bricks = [];
	let ball;
	let level = 0;
	let broke;

	for (const image of brickImages) {
		if (!image.src) {
			image.src = image.dataset.source;
		}
	}

	const setUpBricks = () => {
		const images = shuffle(brickImages);
		bricks = [];

		for (let row = 0; row < 7; row++) {
			for (let column = 0; column < 3; column++) {
				bricks.push({x: 10 + (column * 70), y: 30 + (row * 26), width: 64, height: 22, image: images[((row * 3) + column) % images.length], row});
			}
		}
	};

	const resetBall = () => {
		ball = {x: paddle.x + 18, y: paddle.y - 5, width: 4, height: 4, vx: 0, vy: 0, speed: 2.4 + (level * 0.3), isStuck: true};
	};

	setUpBricks();
	resetBall();

	game.update = () => {
		const speed = 3.5;

		if (held.has('left')) {
			paddle.x -= speed;
		} else if (held.has('right')) {
			paddle.x += speed;
		} else if (pointer.isDown && pointer.x !== undefined) {
			paddle.x += clamp(pointer.x - (paddle.x + (paddle.width / 2)), -speed * 2, speed * 2);
		}

		paddle.x = clamp(paddle.x, 2, width - paddle.width - 2);

		if (broke) {
			broke.frames--;

			if (broke.frames <= 0) {
				broke = undefined;
			}
		}

		if (ball.isStuck) {
			ball.x = paddle.x + 18;
			ball.y = paddle.y - 5;

			if (pressed.has('a') || pressed.has('up')) {
				ball.isStuck = false;
				const angle = (Math.random() - 0.5) * 0.8;
				ball.vx = Math.sin(angle) * ball.speed;
				ball.vy = -Math.cos(angle) * ball.speed;
			}

			return;
		}

		ball.x += ball.vx;
		ball.y += ball.vy;

		if (ball.x < 2 || ball.x > width - 6) {
			ball.vx = -ball.vx;
			ball.x = clamp(ball.x, 2, width - 6);
		}

		if (ball.y < 16) {
			ball.vy = Math.abs(ball.vy);
		}

		if (ball.vy > 0 && overlaps(ball, paddle)) {
			const offset = clamp(((ball.x + 2) - (paddle.x + (paddle.width / 2))) / (paddle.width / 2), -1, 1);
			ball.vx = offset * ball.speed * 0.8;
			ball.vy = -Math.sqrt((ball.speed ** 2) - (ball.vx ** 2));
			sounds.blip();
		}

		const brick = bricks.find(item => overlaps(item, ball));

		if (brick) {
			// It bounces off the side that it went in the least.
			const overlapX = Math.min(ball.x + ball.width - brick.x, brick.x + brick.width - ball.x);
			const overlapY = Math.min(ball.y + ball.height - brick.y, brick.y + brick.height - ball.y);

			if (overlapX < overlapY) {
				ball.vx = -ball.vx;
			} else {
				ball.vy = -ball.vy;
			}

			bricks = bricks.filter(item => item !== brick);
			game.score += 50 + ((6 - brick.row) * 10);
			broke = {text: brickName(brick.image), frames: 90};
			ball.speed = Math.min(ball.speed + 0.06, 5);
			const scale = ball.speed / Math.hypot(ball.vx, ball.vy);
			ball.vx *= scale;
			ball.vy *= scale;
			sounds.hit();

			if (bricks.length === 0) {
				level++;
				game.score += 500;
				game.banner = {text: 'THE WEB IS BROKEN!', frames: 100};
				setUpBricks();
				resetBall();
			}
		}

		if (ball.y > height) {
			game.lives--;
			sounds.die();

			if (game.lives <= 0) {
				game.isOver = true;
			} else {
				resetBall();
			}
		}
	};

	game.draw = () => {
		fill('#000033', 0, 0, width, height);

		for (const brick of bricks) {
			if (brick.image.complete && brick.image.naturalWidth > 0) {
				context.drawImage(brick.image, brick.x, brick.y, brick.width, brick.height);
			} else {
				fill('#888888', brick.x, brick.y, brick.width, brick.height);
			}
		}

		fill('#ffffff', ball.x, ball.y, ball.width, ball.height);
		fill('#c0c0c0', paddle.x, paddle.y, paddle.width, paddle.height);
		fill('#ffffff', paddle.x, paddle.y, paddle.width, 1);
		fill('#808080', paddle.x, paddle.y + paddle.height - 1, paddle.width, 1);

		if (broke) {
			drawText(`YOU BROKE: ${broke.text}`, 112, 274, '#ffee55', {align: 'center'});
		} else if (ball.isStuck) {
			drawText('PRESS A TO LAUNCH', 112, 274, '#33ffff', {align: 'center'});
		}
	};

	game.continue = () => {
		game.lives = 3;
		game.isOver = false;
		resetBall();
	};

	game.tickets = () => Math.max(1, Math.floor(game.score / 50));
	return game;
};

// SkiFri: down a mountain in Norway, like SkiFree, around trees and rocks, and over jumps. At 1,000 meters a troll comes. Trolls turn to stone in the sun, so the visitor only has to ski until the sun comes up. The F key goes faster, like in SkiFree.
const createSki = ({context, fill, drawText, drawSprite, held, pressed, sounds, waitFrames}) => {
	const game = {score: 0, lives: 1, isOver: false, usesPointer: false, hud: '#000080'};
	const skierY = 80;
	let skier = {x: 0, direction: 0, crashFrames: 0, airFrames: 0};
	let distance = 0;
	let style = 0;
	let things = [];
	let nextThing = skierY + 40;
	let troll;
	let trollFrames = 0;
	let eatenFrames = 0;
	// The sun comes up 35 seconds after the troll, which is just long enough to get away with a crash or two, if the visitor skis straight down most of the time.
	const sunriseFrames = 2100;

	const spawn = worldY => {
		const roll = Math.random();
		const kind = roll < 0.5 ? 'tree' : (roll < 0.62 ? 'rock' : (roll < 0.72 ? 'stump' : (roll < 0.9 ? 'mogul' : 'ramp')));
		things.push({kind, x: skier.x + randomInteger(-160, 160), y: worldY, hit: false});
	};

	const size = kind => ({tree: {width: 18, height: 22}, rock: {width: 16, height: 8}, stump: {width: 12, height: 6}, mogul: {width: 24, height: 6}, ramp: {width: 32, height: 10}})[kind];

	game.update = () => {
		if (eatenFrames > 0) {
			eatenFrames--;

			if (eatenFrames === 0) {
				game.isOver = true;
			}

			return;
		}

		if (pressed.has('left')) {
			skier.direction = Math.max(-2, skier.direction - 1);
		}

		if (pressed.has('right')) {
			skier.direction = Math.min(2, skier.direction + 1);
		}

		if (pressed.has('down')) {
			skier.direction = 0;
		}

		if (pressed.has('a') && skier.airFrames === 0 && skier.crashFrames === 0) {
			skier.airFrames = 30;
			sounds.blip();
		}

		let speedX = [-1.2, -1.1, 0, 1.1, 1.2][skier.direction + 2];
		let speedY = [0.4, 1.6, 2.2, 1.6, 0.4][skier.direction + 2];
		const boost = (held.has('f') ? 1.4 : 1) * (held.has('down') && skier.direction === 0 ? 1.2 : 1) * (held.has('up') ? 0.4 : 1);
		speedX *= boost;
		speedY *= boost;

		if (skier.crashFrames > 0) {
			skier.crashFrames--;
			speedX = 0;
			speedY = 0;
		}

		if (skier.airFrames > 0) {
			skier.airFrames--;
		}

		skier.x += speedX;
		distance += speedY;

		// The mountain goes on forever: new things appear below the screen, and the ones above it are gone.
		while (nextThing < distance + height + 20) {
			spawn(nextThing);
			nextThing += randomInteger(12, 28);
		}

		things = things.filter(thing => thing.y > distance - 20);
		const box = {x: skier.x - 5, y: distance + skierY + 12, width: 10, height: 6};

		for (const thing of things) {
			const {width: thingWidth, height: thingHeight} = size(thing.kind);
			const thingBox = {x: thing.x - (thingWidth / 2), y: thing.y - thingHeight, width: thingWidth, height: thingHeight};

			if (thing.hit || !overlaps(box, thingBox)) {
				continue;
			}

			thing.hit = true;

			if (thing.kind === 'ramp' && skier.crashFrames === 0) {
				skier.airFrames = 50;
				style += 100;
				game.banner = {text: randomItem(['RAD!', 'TUBULAR!', 'KULT!', 'AWESOME!']), frames: 50};
				sounds.bonus();
			} else if (thing.kind !== 'mogul' && skier.airFrames === 0 && skier.crashFrames === 0) {
				skier.crashFrames = waitFrames(50);
				style = Math.max(0, style - 20);
				game.banner = {text: randomItem(['OOF!', 'AU!', 'OUCH!']), frames: 40};
				sounds.hit();
			}
		}

		game.score = Math.floor(distance / 4) + style;

		if (!troll && distance / 4 > 1000) {
			troll = {x: skier.x - 30, y: distance - 60};
			game.banner = {text: 'A TROLL! HOLD ▼ AND SKI!', frames: 120};
			game.announcement = 'A troll! Hold Down to ski straight and fast, and ski until the sun comes up!';
			sounds.die();
		}

		if (troll) {
			trollFrames++;

			// The troll gets faster, and turns to stone when the sun comes up.
			if (trollFrames >= sunriseFrames) {
				game.score += 5000;
				game.won = true;
				game.isOver = true;
				game.banner = {text: 'THE TROLL TURNED TO STONE!', frames: 150};
				return;
			}

			const trollSpeed = 2 + (trollFrames * 0.0003);
			const deltaX = skier.x - troll.x;
			const deltaY = (distance + skierY) - troll.y;
			const length = Math.hypot(deltaX, deltaY) || 1;
			troll.x += (deltaX / length) * trollSpeed;
			troll.y += (deltaY / length) * trollSpeed;

			if (length < 14) {
				eatenFrames = waitFrames(100);
				game.banner = {text: 'NOM NOM NOM!', frames: 100};
				sounds.gameOver();
			}
		}
	};

	game.draw = () => {
		// The snow turns pink and orange when the sun comes up.
		const sunrise = troll ? trollFrames / sunriseFrames : 0;
		context.fillStyle = `rgb(255 ${Math.round(255 - (sunrise * 60))} ${Math.round(255 - (sunrise * 110))})`;
		context.fillRect(0, 0, width, height);
		const cameraX = skier.x - (width / 2);

		for (const thing of things) {
			const x = thing.x - cameraX;
			const y = thing.y - distance;
			const {width: thingWidth, height: thingHeight} = size(thing.kind);

			if (y < -20 || y > height + 20) {
				continue;
			}

			if (thing.kind === 'mogul') {
				fill('#d8e4f0', x - 12, y - 5, 24, 5);
				fill('#c0d0e0', x - 8, y - 7, 16, 2);
			} else if (thing.kind === 'ramp') {
				// A jump with yellow and black stripes, and an arrow, so it looks like something to ski over.
				for (let stripe = 0; stripe < 4; stripe++) {
					fill(stripe % 2 === 0 ? '#ffcc00' : '#222222', x - 16 + (stripe * 8), y - 10, 8, 10);
				}

				fill('#996600', x - 16, y - 2, 32, 2);
				drawText('▲', x - 2, y - 19, '#ff6600');
			} else {
				drawSprite(sprites[thing.kind], x - (thingWidth / 2), y - thingHeight, palettes[thing.kind], {scale: 2});
			}
		}

		if (eatenFrames > 0) {
			// The troll jumps up and down on the spot where the skier was.
			drawSprite(sprites.troll, (width / 2) - 12, skierY - 8 + ((eatenFrames % 10 < 5) ? -4 : 0), palettes.troll, {scale: 2});
		} else {
			const sprite = skier.crashFrames > 0 ? sprites.skierCrash : (Math.abs(skier.direction) === 2 ? sprites.skierSide : sprites.skier);
			const lift = skier.airFrames > 0 ? Math.round(Math.sin((skier.airFrames / 50) * Math.PI) * 14) : 0;

			if (lift > 0) {
				fill('#cccccc', (width / 2) - 8, skierY + 17, 16, 2);
			}

			drawSprite(sprite, (width / 2) - 8, skierY - lift, palettes.skier, {flip: skier.direction < 0, scale: 2});

			if (troll) {
				const trollY = troll.y - distance - 13;
				drawSprite(sprites.troll, troll.x - cameraX - 12, trollY, palettes.troll, {scale: 2});

				// Above the screen, an arrow shows where the troll is, and how far behind.
				if (trollY < -20) {
					drawText(`▲ TROLL ${Math.round((skierY - trollY) / 4)} M`, clamp(troll.x - cameraX, 40, width - 40), 16, '#cc0000', {align: 'center'});
				}
			}
		}

		drawText(`${Math.floor(distance / 4)} M`, 4, 276, '#000080');

		if (troll) {
			drawText(`SUNRISE IN ${Math.ceil((sunriseFrames - trollFrames) / 60)}`, 220, 276, '#cc3300', {align: 'right'});
		} else {
			drawText(`STYLE ${style}`, 220, 276, '#000080', {align: 'right'});
		}
	};

	game.continue = () => {
		game.isOver = false;
		eatenFrames = 0;
		troll = {x: skier.x - 40, y: distance - 120};
	};

	game.tickets = () => Math.max(1, Math.floor(game.score / 100));
	return game;
};

const gameMakers = {
	invaders: createInvaders,
	pong: createPong,
	stacker: createStacker,
	highway: createHighway,
	breakout: createBreakout,
	ski: createSki,
};

// The help of each game for the status line, and the two short lines of controls that the attract screen shows, where ◀ ▶ ▲ ▼ and A are the joystick and the button of the cabinet, and also the arrow keys and Space.
const gameHelp = {
	invaders: 'Move with the arrow keys or the joystick, and fire waffles with Space or A. On a touch screen, keep a finger on the screen: the unicorn follows it and fires.',
	pong: 'Move with the arrow keys or the joystick, or drag on the screen. Hit the ball with the edge of the paddle to aim. First to 7 wins.',
	stacker: 'Move with Left and Right, turn with Up, Space, A, or a tap on the screen, and drop faster with Down. A full row is eaten, and four at once is a brunost.',
	highway: 'Hop with the arrow keys or the joystick. Cross the traffic, ride the floppies and CDs over the data stream, and get the e-mail into the five inboxes at the top.',
	breakout: 'Move with the arrow keys or the joystick, or drag on the screen. Launch the ball with Space or A.',
	ski: 'Steer with Left and Right, hold Down to ski straight down and fast, slow down with Up, and jump with Space or A. At 1,000 meters a troll comes: hold Down, and ski until the sun comes up. A secret key goes even faster.',
};

const gameControls = {
	invaders: ['◀ ▶ MOVE    A FIRE', 'OR DRAG ON THE SCREEN'],
	pong: ['◀ ▶ OR DRAG TO MOVE', 'FIRST TO 7 WINS'],
	stacker: ['◀ ▶ MOVE  ▲ OR A TURN', '▼ DROP FASTER'],
	highway: ['▲ ▼ ◀ ▶ HOP', 'FILL THE 5 INBOXES'],
	breakout: ['◀ ▶ OR DRAG TO MOVE', 'A LAUNCHES THE BALL'],
	ski: ['◀ ▶ STEER  HOLD ▼ FAST', 'A JUMP  ESCAPE THE TROLL'],
};

// The high scores of each game, with three initials, and made-up scores to beat at first, like on the arcade machines.
const baseScores = {invaders: 1000, pong: 400, stacker: 1000, highway: 400, breakout: 500, ski: 600};
const attractTitles = {invaders: ['UNICORN', 'INVADERS'], pong: ['PAPERCLIP', 'PONG'], stacker: ['WAFFLE', 'STACKER'], highway: ['INFORMATION', 'SUPERHIGHWAY'], breakout: ['88×31', 'BREAKOUT'], ski: ['SKIFRI', '']};
const stepTime = 1000 / 60;

const setUpArcade = (arcade, {cabinet, screen, start, credits: creditDisplay, insert, mom, kick, tickets: ticketDisplay, scoresTitle, scores: scoresList, prizeStatus, shelf, bricks}) => {
	const {games: gameTitles, prizes} = arcade.config;

	// The coins, the credits in the machine, and the tickets. The coin games of the Game Room take the same coins.
	const wallet = {
		coins: count(arcade.stored('coins', 10)),
		credits: count(arcade.stored('credits', 0)),
		tickets: count(arcade.stored('tickets', 0)),
	};

	// The coins show in the arcade and in the coin games of the Game Room.
	const coinDisplays = document.querySelectorAll('[data-arcade-coins]');

	const showWallet = () => {
		for (const display of coinDisplays) {
			display.textContent = wallet.coins.toLocaleString('en-US');
		}

		ticketDisplay.textContent = wallet.tickets.toLocaleString('en-US');

		creditDisplay.textContent = wallet.credits;
		arcade.store('coins', wallet.coins);
		arcade.store('credits', wallet.credits);
		arcade.store('tickets', wallet.tickets);
	};

	// The amounts are always whole numbers, so a mistake can never turn the wallet into NaN.
	const addCoins = amount => {
		wallet.coins += count(amount);
		showWallet();
	};

	const spendCoins = amount => {
		if (wallet.coins < amount) {
			return false;
		}

		wallet.coins -= amount;
		showWallet();
		return true;
	};

	const addTickets = amount => {
		const tickets = count(amount);
		wallet.tickets += tickets;
		showWallet();
		return tickets;
	};

	// The sound is off until the visitor turns it on, with one of the sound buttons of the arcade and the Game Room, which all show the same.
	const soundButtons = document.querySelectorAll('[data-arcade-sound]');
	let isSoundOn = false;

	const showSound = () => {
		for (const button of soundButtons) {
			button.textContent = isSoundOn ? '🔊 Sound' : '🔇 Sound';
			button.setAttribute('aria-pressed', String(isSoundOn));
		}
	};

	for (const button of soundButtons) {
		arcade.on(button, 'click', () => {
			const sound = arcade.sound();

			if (!sound) {
				return;
			}

			isSoundOn = !isSoundOn;

			if (isSoundOn) {
				sound.context.resume();
			} else {
				sound.context.suspend();
			}

			showSound();
		});
	}

	// A beep of a sound chip, with an optional slide to another frequency, like the sounds of the arcade machines.
	const beep = (frequency, duration, {type = 'square', volume = 0.04, delay = 0, slideTo} = {}) => {
		if (!isSoundOn) {
			return;
		}

		const {context: audioContext, output} = arcade.sound();
		const start = audioContext.currentTime + delay;
		const oscillator = audioContext.createOscillator();
		const gain = audioContext.createGain();
		oscillator.type = type;
		oscillator.frequency.setValueAtTime(frequency, start);

		if (slideTo) {
			oscillator.frequency.exponentialRampToValueAtTime(slideTo, start + duration);
		}

		gain.gain.setValueAtTime(volume, start);
		gain.gain.exponentialRampToValueAtTime(0.0001, start + duration);
		oscillator.connect(gain).connect(output);
		oscillator.start(start);
		oscillator.stop(start + duration);
	};

	const sounds = {
		coin() {
			beep(988, 0.08);
			beep(1319, 0.3, {delay: 0.08});
		},
		shoot() {
			beep(880, 0.1, {slideTo: 220});
		},
		hit() {
			beep(200, 0.15, {type: 'sawtooth', slideTo: 60});
		},
		blip() {
			beep(660, 0.05);
		},
		bonus() {
			for (const [index, note] of [523, 659, 784, 1047].entries()) {
				beep(note, 0.1, {delay: index * 0.08});
			}
		},
		die() {
			beep(400, 0.6, {type: 'sawtooth', slideTo: 40, volume: 0.05});
		},
		gameOver() {
			for (const [index, note] of [392, 330, 262, 196].entries()) {
				beep(note, 0.25, {delay: index * 0.22, type: 'triangle', volume: 0.08});
			}
		},
	};

	// A wait of a game, like before a serve or after a crash. With reduced motion, each key is a few steps, so a wait is a few keys, not a long one.
	const waitFrames = frames => (arcade.reducedMotion ? Math.min(frames, 12) : frames);

	// The controls that are held down, and the ones pressed since the last step, which a game takes once.
	const held = new Set();
	const pressed = new Set();
	// Where a finger or the mouse is on the screen, for the paddles, in the pixels of the game.
	const pointer = {x: undefined, isDown: false};

	// 88×31 Breakout: the bricks are the 88×31 buttons of the page.
	const brickImages = [...bricks.content.querySelectorAll('img')].map(template => {
		const image = new Image();
		// Loaded only when the game starts, so the page does not load all the buttons twice.
		image.dataset.source = template.getAttribute('src');
		return image;
	});

	const {context, fill, drawText, drawSprite} = makeScreen(screen);
	// What the games use of the cabinet: its screen, its controls, and its sounds.
	const machine = {context, fill, drawText, drawSprite, held, pressed, pointer, sounds, beep, waitFrames, isReducedMotion: () => arcade.reducedMotion, brickImages};

	const storedScores = arcade.stored('scores', {});
	const highScores = Object.fromEntries(Object.entries(baseScores).map(([id, base]) => {
		const stored = Array.isArray(storedScores[id]) ? storedScores[id].filter(entry => typeof entry?.initials === 'string').map(entry => ({initials: entry.initials.slice(0, 3).toUpperCase(), score: count(entry.score)})) : [];
		const defaults = [['SIN', 5], ['MOM', 4], ['DAD', 3], ['WAF', 2], ['Y2K', 1]].map(([initials, multiple]) => ({initials, score: base * multiple}));
		return [id, stored.length > 0 ? stored.slice(0, 5) : defaults];
	}));

	const gameButtons = [...arcade.querySelectorAll('[data-arcade-game]')];

	let chosen = 'invaders';
	// `attract`, `playing`, `paused`, `continue`, or `initials`.
	let mode = 'attract';
	let game;
	let continueCount = 0;
	let continueTimer;
	let initials;
	let tiltFrames = 0;
	let lastTime;
	// The time since the last step that is not yet a whole step, so the games have the same speed at any refresh rate of the screen.
	let leftoverTime = 0;
	let attractTime = 0;

	const showHighScores = () => {
		scoresTitle.textContent = `High Scores: ${gameTitles[chosen]}`;
		scoresList.replaceChildren(...highScores[chosen].map(entry => {
			const item = document.createElement('li');
			const name = document.createElement('span');
			const score = document.createElement('span');
			name.textContent = entry.initials;
			score.textContent = entry.score;
			item.append(name, score);
			return item;
		}));
	};

	const showChosen = () => {
		for (const button of gameButtons) {
			const isChosen = button.dataset.arcadeGame === chosen;
			button.setAttribute('aria-pressed', String(isChosen));
			button.dataset.state = isChosen ? 'on' : '';
		}

		showHighScores();
	};

	const drawHud = () => {
		fill('#000000', 0, 0, width, 12);
		drawText(`SCORE ${game.score}`, 3, 3, '#ffffff');
		drawText(`HI ${Math.max(game.score, highScores[chosen][0].score)}`, 128, 3, '#ffee55', {align: 'center'});

		if (chosen !== 'ski') {
			drawText(chosen === 'pong' ? `♥${game.lives}` : '♥'.repeat(Math.max(game.lives, 0)), 221, 3, '#ff66cc', {align: 'right'});
		}
	};

	const drawBanner = () => {
		if (!game.banner) {
			return;
		}

		const lineWidth = (game.banner.text.length * 6) + 10;
		fill('#000000', 112 - (lineWidth / 2), 132, lineWidth, 17);
		drawText(game.banner.text, 112, 137, '#ffee55', {align: 'center'});
	};

	const isBlinkOn = () => arcade.reducedMotion || Math.floor(attractTime / 500) % 2 === 0;

	const drawAttract = () => {
		fill('#000000', 0, 0, width, height);

		// The stars of the attract mode drift down slowly, unless the visitor prefers less motion.
		for (let index = 0; index < 40; index++) {
			const y = (((index * 71) + (arcade.reducedMotion ? 0 : attractTime / 40)) % height);
			fill(index % 3 === 0 ? '#5555aa' : '#333366', (index * 53) % width, y, 1, 1);
		}

		drawText(`CREDIT ${wallet.credits}`, 220, 3, '#ffffff', {align: 'right'});
		drawText('SINDRE\'S ARCADE', 112, 22, '#ff66cc', {align: 'center'});
		const [first, second] = attractTitles[chosen];
		drawText(first, 112, 44, '#ffee55', {scale: first.length > 9 ? 1.5 : 2, align: 'center'});
		drawText(second, 112, 64, '#ffee55', {scale: second.length > 9 ? 1.5 : 2, align: 'center'});

		// A picture of the game.
		if (chosen === 'invaders') {
			for (const [index, kind] of ['squid', 'crab', 'octopus', 'crab'].entries()) {
				drawSprite(sprites.bugs[kind][Math.floor(attractTime / 600) % 2], 70 + (index * 22), 88, palettes.bugs[index]);
			}

			drawSprite(sprites.unicorn, 106, 100, palettes.unicorn);
		} else if (chosen === 'ski') {
			drawSprite(sprites.tree, 60, 84, palettes.tree, {scale: 2});
			drawSprite(sprites.skier, 104, 88, palettes.skier, {scale: 2});
			drawSprite(sprites.troll, 140, 82, palettes.troll, {scale: 2});
		} else if (chosen === 'highway') {
			drawSprite(sprites.envelope, 106, 94, palettes.envelope);
		} else if (chosen === 'pong') {
			fill('#ffffff', 110, 96, 4, 4);
		} else if (chosen === 'stacker') {
			for (const [index, color] of ['#e8b04a', '#8b4a1c', '#d22d4b', '#ffe066'].entries()) {
				fill(color, 90 + (index * 11), 94, 10, 10);
			}
		} else {
			fill('#c0c0c0', 92, 102, 40, 5);
		}

		if (tiltFrames > 0) {
			drawText('TILT', 112, 118, '#ff3333', {scale: 3, align: 'center'});
		} else if (isBlinkOn()) {
			// With coins in the pocket, Start puts one in by itself, so it only says “INSERT COIN” when the pockets are empty.
			const canStart = wallet.credits > 0 || wallet.coins > 0;
			drawText(canStart ? 'PRESS START' : 'INSERT COIN', 112, 122, canStart ? '#33ff66' : '#ff5555', {scale: 1.5, align: 'center'});
		}

		for (const [index, line] of gameControls[chosen].entries()) {
			drawText(line, 112, 142 + (index * 10), '#cccccc', {align: 'center'});
		}

		drawText('HIGH SCORES', 112, 170, '#33ffff', {align: 'center'});

		for (const [index, entry] of highScores[chosen].entries()) {
			drawText(`${index + 1}. ${entry.initials.padEnd(3, ' ')} ${String(entry.score).padStart(6, ' ')}`, 112, 183 + (index * 11), index === 0 ? '#ffee55' : '#ffffff', {align: 'center'});
		}

		drawText('◀ ▶ CHOOSE A GAME', 112, 250, '#888888', {align: 'center'});
		drawText('(C) 1999 SINDRE', 112, 268, '#888888', {align: 'center'});
	};

	const drawContinue = () => {
		game.draw();
		drawHud();
		context.fillStyle = 'rgb(0 0 0 / 70%)';
		context.fillRect(0, 0, width, height);
		// A box behind the countdown, so the text of the game does not show through it.
		fill('#000000', 24, 80, 176, 142);
		drawText(game.isTilted ? 'TILT' : 'GAME OVER', 112, 90, '#ff3333', {scale: 2, align: 'center'});
		drawText('CONTINUE?', 112, 124, '#ffffff', {scale: 2, align: 'center'});
		drawText(continueCount, 112, 150, '#ffee55', {scale: 4, align: 'center'});
		drawText(wallet.credits > 0 || wallet.coins > 0 ? 'PRESS START' : 'ASK MOM FOR COINS', 112, 196, '#33ff66', {align: 'center'});
		drawText(`CREDIT ${wallet.credits}`, 112, 210, '#ffffff', {align: 'center'});
	};

	const drawInitials = () => {
		fill('#000000', 0, 0, width, height);
		drawText('NEW HIGH SCORE!', 112, 50, '#ffee55', {scale: 1.5, align: 'center'});
		drawText(game.score, 112, 74, '#ffffff', {scale: 2, align: 'center'});
		drawText('ENTER YOUR INITIALS', 112, 110, '#33ffff', {align: 'center'});

		for (let index = 0; index < 3; index++) {
			const x = 82 + (index * 24);
			const isCurrent = index === initials.position;
			drawText(initials.letters[index], x + 6, 136, isCurrent ? '#ffee55' : '#ffffff', {scale: 3, align: 'center'});
			fill(isCurrent ? '#ffee55' : '#555555', x - 2, 160, 16, 2);

			if (isCurrent) {
				drawText('▲', x + 6, 124, '#888888', {align: 'center'});
				drawText('▼', x + 6, 165, '#888888', {align: 'center'});
			}
		}

		drawText('UP/DOWN: LETTER', 112, 196, '#888888', {align: 'center'});
		drawText('A: NEXT  START: DONE', 112, 208, '#888888', {align: 'center'});
		drawText('OR TYPE THEM', 112, 220, '#888888', {align: 'center'});
	};

	const draw = () => {
		screen.dataset.state = mode === 'playing' ? 'playing' : '';

		if (mode === 'attract') {
			drawAttract();
		} else if (mode === 'continue') {
			drawContinue();
		} else if (mode === 'initials') {
			drawInitials();
		} else {
			game.draw();
			drawHud();
			drawBanner();

			if (mode === 'paused') {
				fill('#000000', 52, 126, 120, 30);
				drawText('PAUSED', 112, 131, '#ffee55', {scale: 1.5, align: 'center'});
				drawText('PRESS START', 112, 145, '#ffffff', {align: 'center'});
			}
		}
	};

	const step = () => {
		if (tiltFrames > 0) {
			tiltFrames--;
		}

		if (mode !== 'playing') {
			return;
		}

		game.update();
		pressed.clear();

		if (game.banner) {
			game.banner.frames--;

			if (game.banner.frames <= 0) {
				game.banner = undefined;
			}
		}

		if (game.announcement) {
			arcade.say(game.announcement);
			game.announcement = undefined;
		}

		if (game.isOver) {
			endGame();
		}
	};

	// The screen draws frames only while it is on the screen, the tab is visible, and something moves.
	const screenLoop = arcade.loop((seconds, time) => {
		// Fixed steps of 60 a second, so the games have the same speed on fast and slow screens, and at most a few after a pause.
		leftoverTime += lastTime === undefined ? stepTime : time - lastTime;
		const steps = Math.min(Math.floor(leftoverTime / stepTime), 4);
		leftoverTime = steps === 4 ? 0 : leftoverTime - (steps * stepTime);
		lastTime = time;
		attractTime = time;

		for (let index = 0; index < steps; index++) {
			step();
		}

		draw();
	}, {
		while: () => !arcade.reducedMotion && (mode === 'playing' || mode === 'attract'),
		stopped() {
			lastTime = undefined;
			leftoverTime = 0;
		},
	});

	const run = () => {
		draw();
		screenLoop.start();
	};

	const startGame = () => {
		game = gameMakers[chosen](machine);
		mode = 'playing';
		held.clear();
		pressed.clear();
		arcade.say(`${gameTitles[chosen]}! ${gameHelp[chosen]}${arcade.reducedMotion ? ' The game moves a few steps for each key or tap, as your computer prefers less motion.' : ''}`);
		sounds.coin();
		screen.focus({preventScroll: true});
		run();
	};

	// A pause that a press of a pointer causes leaves the status as it is, as a shorter message would make the cabinet shorter and move the button under the pointer before the click, which would then be lost. The screen says that the game is paused.
	const pause = message => {
		if (mode !== 'playing') {
			return;
		}

		mode = 'paused';

		if (message) {
			arcade.say(message);
		}

		run();
	};

	const finishGame = () => {
		continueTimer?.cancel();
		const ending = game.won ? `You won ${gameTitles[chosen]}!` : 'Game over!';
		const tickets = addTickets(game.tickets());
		const table = highScores[chosen];

		if (game.score > table.at(-1).score) {
			mode = 'initials';
			initials = {letters: ['A', 'A', 'A'], position: 0, tickets};
			arcade.say(`${ending} New high score: ${game.score}! The machine gives you ${plural(tickets, 'ticket')}. Enter your initials with the arrow keys, or type them, and press Start.`);
			screen.focus({preventScroll: true});
		} else {
			mode = 'attract';
			arcade.say(`${ending} Your score: ${game.score}. The machine gives you ${plural(tickets, 'ticket')}.`);
		}

		run();
	};

	const endGame = () => {
		sounds.gameOver();

		if (game.won) {
			arcade.celebrate();
			finishGame();
			return;
		}

		mode = 'continue';
		continueCount = 10;
		arcade.say(`${game.isTilted ? 'TILT! You kicked the machine during a game. ' : ''}Game over! Press Start in 10 seconds to continue for one coin. Your score: ${game.score}.`);
		continueTimer?.cancel();

		// It counts down once a second, and waits while the tab is hidden or the cabinet is off the screen.
		continueTimer = arcade.interval(1000, () => {
			if (!arcade.isVisible) {
				return;
			}

			continueCount--;

			if (continueCount < 0) {
				finishGame();
			} else {
				draw();
			}
		});

		run();
	};

	const saveInitials = () => {
		const entry = {initials: initials.letters.join(''), score: game.score};
		const table = highScores[chosen];
		table.push(entry);
		table.sort((first, second) => second.score - first.score);
		table.splice(5);
		arcade.store('scores', highScores);
		const place = table.indexOf(entry) + 1;
		mode = 'attract';
		showHighScores();
		arcade.say(`${entry.initials} is number ${place} on the high scores of ${gameTitles[chosen]}!${place === 1 ? ' The best!' : ''}`);

		if (place === 1) {
			arcade.celebrate();
		}

		run();
	};

	// A game takes a credit, or else a coin from the pocket, which Start puts in by itself, so nobody gets stuck at “INSERT COIN”.
	const takeCredit = () => {
		if (wallet.credits > 0) {
			wallet.credits--;
			showWallet();
			return true;
		}

		return spendCoins(1);
	};

	const pressStart = () => {
		if (mode === 'attract') {
			if (takeCredit()) {
				startGame();
			} else {
				arcade.say('No coins left! Ask Mom, or kick the machine.');
			}
		} else if (mode === 'playing') {
			pause('Paused. Press Start, or tap the screen, to go on.');
		} else if (mode === 'paused') {
			mode = 'playing';
			arcade.say('Go on!');
			screen.focus({preventScroll: true});
			run();
		} else if (mode === 'continue') {
			if (takeCredit()) {
				continueTimer?.cancel();
				game.isTilted = false;
				game.continue();
				mode = 'playing';
				arcade.say('Continue! Your score is kept.');
				sounds.coin();
				screen.focus({preventScroll: true});
				run();
			} else {
				arcade.say('No coins left! Ask Mom! Hurry!');
			}
		} else if (mode === 'initials') {
			saveInitials();
		}
	};

	const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 ';

	const changeInitial = control => {
		const letter = initials.letters[initials.position];

		if (control === 'up' || control === 'down') {
			const index = letters.indexOf(letter);
			initials.letters[initials.position] = letters[(index + (control === 'up' ? 1 : letters.length - 1)) % letters.length];
		} else if (control === 'left') {
			initials.position = Math.max(0, initials.position - 1);
		} else if (control === 'right' || control === 'a') {
			if (initials.position === 2 && control === 'a') {
				saveInitials();
				return;
			}

			initials.position = Math.min(2, initials.position + 1);
		}

		draw();
	};

	const chooseGame = id => {
		if (!gameMakers[id]) {
			return;
		}

		if (mode === 'initials') {
			arcade.say('Enter your initials first!');
			return;
		}

		if (mode === 'playing') {
			arcade.say('Finish your game first, or pause it with Start.');
			return;
		}

		// A game that waits for a continue ends now, with its tickets and high score, which the status says, so the next click chooses. A paused game is left for the new one.
		if (mode === 'continue') {
			finishGame();
			return;
		}

		mode = 'attract';

		chosen = id;
		showChosen();
		arcade.say(`${gameTitles[chosen]}. ${gameHelp[chosen]}`);
		run();
	};

	// A control of the joystick or a key. With reduced motion, a game moves a few steps for each press, so nothing moves by itself.
	const press = control => {
		if (mode === 'initials') {
			changeInitial(control);
			return;
		}

		if (mode === 'attract' && (control === 'left' || control === 'right')) {
			const index = gameButtons.findIndex(button => button.dataset.arcadeGame === chosen);
			chooseGame(gameButtons[(index + (control === 'left' ? gameButtons.length - 1 : 1)) % gameButtons.length].dataset.arcadeGame);
			return;
		}

		// The fire button also starts, and goes on after a pause, like Start. It does not continue, as that costs a coin, and a visitor may still press fire when the game ends.
		if (control === 'a' && (mode === 'attract' || mode === 'paused')) {
			pressStart();
			return;
		}

		if (mode !== 'playing') {
			return;
		}

		pressed.add(control);

		if (arcade.reducedMotion) {
			for (let index = 0; index < 6 && mode === 'playing'; index++) {
				step();
			}

			draw();
		}
	};

	// The buttons of the joystick and the fire button.
	const controlButtons = [...cabinet.querySelectorAll('[data-arcade-control]')];

	for (const button of controlButtons) {
		const control = button.dataset.arcadeControl;

		const release = () => {
			held.delete(control);
		};

		arcade.on(button, 'pointerdown', event => {
			if (event.button !== 0) {
				return;
			}

			event.preventDefault();
			button.setPointerCapture(event.pointerId);
			held.add(control);
			press(control);
			// The screen keeps the focus, so the keys of the keyboard keep working.
			screen.focus({preventScroll: true});
		});

		arcade.on(button, 'pointerup', release);
		arcade.on(button, 'pointercancel', release);
		arcade.on(button, 'lostpointercapture', release);

		// A click without a pointer, like from a screen reader, is one press.
		arcade.on(button, 'click', event => {
			if (event.detail === 0) {
				press(control);
			}
		});

		arcade.on(button, 'contextmenu', event => {
			event.preventDefault();
		});

		// Chrome and Firefox focus a button on a press of the mouse, which would take the focus from the screen.
		arcade.on(button, 'mousedown', event => {
			event.preventDefault();
		});
	}

	const keyControls = {ArrowUp: 'up', ArrowDown: 'down', ArrowLeft: 'left', ArrowRight: 'right', ' ': 'a', z: 'a', x: 'a', Z: 'a', X: 'a'};

	// The keys only work while the focus is on the screen, so they do not reach the other games of the page.
	arcade.on(screen, 'keydown', event => {
		if (event.altKey || event.ctrlKey || event.metaKey) {
			return;
		}

		if (mode === 'initials' && /^[a-z\d]$/i.test(event.key)) {
			event.preventDefault();
			event.stopPropagation();
			initials.letters[initials.position] = event.key.toUpperCase();
			initials.position = Math.min(2, initials.position + 1);
			draw();
			return;
		}

		if (event.key === 'Enter') {
			event.preventDefault();
			event.stopPropagation();

			if (!event.repeat) {
				pressStart();
			}

			return;
		}

		if (event.key === 'p' || event.key === 'P' || event.key === 'Escape') {
			if (mode === 'playing') {
				event.preventDefault();
				pause('Paused. Press Start, or tap the screen, to go on.');
			}

			return;
		}

		if (/^[1-6]$/.test(event.key) && mode === 'attract') {
			event.preventDefault();
			event.stopPropagation();
			chooseGame(gameButtons[Number(event.key) - 1].dataset.arcadeGame);
			return;
		}

		// F goes faster in SkiFri, like in SkiFree.
		if ((event.key === 'f' || event.key === 'F') && mode === 'playing') {
			event.preventDefault();
			event.stopPropagation();
			held.add('f');
			return;
		}

		const control = keyControls[event.key];

		if (!control) {
			return;
		}

		event.preventDefault();
		event.stopPropagation();
		held.add(control);

		// Held keys repeat, which only moves the games with reduced motion, where each press is a few steps.
		if (!event.repeat || arcade.reducedMotion) {
			press(control);
		}
	});

	arcade.on(screen, 'keyup', event => {
		held.delete(event.key === 'f' || event.key === 'F' ? 'f' : keyControls[event.key]);
	});

	// When the focus moves from the screen to another element, like a button of the coin door or the next element with the Tab key, the keys no longer reach the game, so it pauses. Start is left out, as it pauses and goes on by itself, and so are the joystick and the fire button, which give the focus back to the screen, and whose held directions stay. The focus often moves with a press of a pointer, so the status stays, and screen readers say the element with the focus.
	arcade.on(screen, 'blur', event => {
		if (controlButtons.includes(event.relatedTarget)) {
			return;
		}

		held.clear();

		if (event.relatedTarget && event.relatedTarget !== start) {
			pause();
		}
	});

	// A finger or the mouse on the screen moves the paddles and the unicorn, and a tap fires.
	const pointerX = event => {
		const bounds = screen.getBoundingClientRect();
		return ((event.clientX - bounds.left) / bounds.width) * width;
	};

	let tapStart;

	arcade.on(screen, 'pointerdown', event => {
		if (event.button !== 0) {
			return;
		}

		screen.setPointerCapture(event.pointerId);
		tapStart = {x: event.clientX, y: event.clientY, time: event.timeStamp};

		if (mode === 'playing' && game.usesPointer) {
			pointer.isDown = true;
			pointer.x = pointerX(event);
		}
	});

	arcade.on(screen, 'pointermove', event => {
		if (pointer.isDown) {
			pointer.x = pointerX(event);
		}
	});

	const endPointer = event => {
		pointer.isDown = false;

		if (tapStart && event.type === 'pointerup' && Math.hypot(event.clientX - tapStart.x, event.clientY - tapStart.y) < 10 && event.timeStamp - tapStart.time < 300) {
			press('a');
		}

		tapStart = undefined;
	};

	arcade.on(screen, 'pointerup', endPointer);
	arcade.on(screen, 'pointercancel', endPointer);

	arcade.on(start, 'click', () => {
		pressStart();
	});

	for (const button of gameButtons) {
		arcade.on(button, 'click', () => {
			chooseGame(button.dataset.arcadeGame);
		});
	}

	arcade.on(insert, 'click', () => {
		if (!spendCoins(1)) {
			arcade.say('Your pockets are empty! Ask Mom for coins.');
			return;
		}

		wallet.credits++;
		showWallet();
		sounds.coin();
		arcade.say(`Clink! ${plural(wallet.credits, 'credit')}. ${mode === 'continue' ? 'Press Start to continue!' : 'Press Start!'}`);
		draw();
	});

	// Mom gives coins, less each time, then sends the visitor to Dad, and then Mormor helps out, behind Mom’s back.
	const momAnswers = [
		{coins: 5, text: 'Mom: “Here are 5 coins, vennen min. Do not spend them all at once!”'},
		{coins: 5, text: 'Mom: “Again? OK, 5 more. But then you do your homework.”'},
		{coins: 3, text: 'Mom: “Money does not grow on trees! Here are 3. Ask your father next time.”'},
		{coins: 2, text: 'Dad: “In my day, a game cost 1 krone, and we walked to the arcade in the snow, uphill both ways. Here are 2 coins.”'},
		{coins: 0, text: 'Mom: “No. Go play outside. It is only raining a little.” (It is Bergen. It is always raining.)'},
		{coins: 10, text: 'Mormor: “Here are 10 coins! Do not tell your mother.”'},
	];
	let momAsks = 0;

	arcade.on(mom, 'click', () => {
		const answer = momAnswers[momAsks < momAnswers.length ? momAsks : 4 + ((momAsks - momAnswers.length) % 2)];
		momAsks++;
		addCoins(answer.coins);

		if (answer.coins > 0) {
			sounds.coin();
		}

		arcade.say(answer.text);
	});

	// Kicking the machine is not nice. Sometimes a coin falls out, and while a game is on, it tilts.
	arcade.on(kick, 'click', () => {
		cabinet.dataset.state = 'kicked';
		arcade.timeout(450, () => {
			cabinet.dataset.state = '';
		});
		sounds.hit();

		if (mode === 'playing' || mode === 'paused') {
			game.isTilted = true;
			game.isOver = true;
			game.lives = 0;
			mode = 'playing';
			endGame();
			return;
		}

		tiltFrames = 90;
		const roll = Math.random();

		if (roll < 0.25) {
			addCoins(1);
			arcade.say('Clunk! A coin fell out of the coin return. Nice.');
		} else if (roll < 0.35) {
			wallet.credits++;
			showWallet();
			arcade.say('The machine coughs and gives you a free credit!');
		} else {
			arcade.say(randomItem(['TILT! The machine is offended.', 'Ouch, my foot!', 'The man at the counter is looking at you.', 'TILT! Nothing happens, except TILT.']));
		}

		// With reduced motion, the TILT stays for a moment, as there are no frames to count it down.
		if (arcade.reducedMotion) {
			arcade.timeout(1500, () => {
				tiltFrames = 0;
				draw();
			});
		}

		run();
	});

	// A game pauses when the visitor clicks, taps, or tabs away from the cabinet, as the keys no longer reach it, so nobody loses a life while reading the page. The status stays, so the menu of the games below the cabinet on a phone does not move under the finger.
	arcade.on(document, 'pointerdown', event => {
		if (!cabinet.contains(event.target)) {
			pause();
		}
	});

	// Safari does not focus a button on a click, so a click on the cabinet during a game gives the focus back to the screen, where the keys work.
	arcade.on(cabinet, 'click', () => {
		if (mode === 'playing' && document.activeElement !== screen) {
			screen.focus({preventScroll: true});
		}
	});

	// The Prize Counter: the tickets buy prizes for the shelf.
	const owned = arcade.stored('shelf', []).filter(index => prizes[index]);

	const showShelf = () => {
		shelf.dataset.state = owned.length === 0 ? 'empty' : '';

		if (owned.length === 0) {
			const item = document.createElement('li');
			item.textContent = 'Nothing yet. Win some tickets!';
			shelf.replaceChildren(item);
			return;
		}

		shelf.replaceChildren(...owned.map(index => {
			const item = document.createElement('li');
			const emoji = document.createElement('span');
			emoji.textContent = prizes[index].emoji;
			emoji.title = prizes[index].name;
			emoji.setAttribute('role', 'img');
			emoji.setAttribute('aria-label', prizes[index].name);
			item.append(emoji);
			return item;
		}));
	};

	for (const button of arcade.querySelectorAll('[data-arcade-prize]')) {
		arcade.on(button, 'click', () => {
			const index = Number(button.dataset.arcadePrize);
			const prize = prizes[index];

			if (wallet.tickets < prize.price) {
				arcade.say(`You need ${plural(prize.price - wallet.tickets, 'more ticket')} for that. Keep playing!`, prizeStatus);
				return;
			}

			wallet.tickets -= prize.price;
			showWallet();
			owned.push(index);
			arcade.store('shelf', owned);
			showShelf();
			arcade.say(`You got ${prize.name.replace(/^An? /, 'the ').replace(/^The /, 'the ')}! The lady at the counter says: “${prize.line}”`, prizeStatus);

			if (prize.price >= 300) {
				arcade.celebrate();
			}
		});
	}

	showWallet();
	showSound();
	showChosen();
	showShelf();
	run();

	return {
		run,
		// The screen comes back, or it goes away, as the tab is hidden or the arcade scrolled away.
		visibilityChanged(isVisible) {
			if (isVisible) {
				run();
			} else {
				pause(document.hidden ? 'Paused, as you left the page. Press Start to go on.' : 'Paused, as the arcade scrolled away. Press Start to go on.');
			}
		},
		addCoins,
		spendCoins,
		addTickets,
		beep,
		sounds,
	};
};

export default class extends GeoCitiesElement {
	#arcade;

	// The games run only while the screen of the cabinet is in view, not while only the menu or the Prize Counter is.
	get visibilityTarget() {
		return this.parts.screen;
	}

	connected() {
		this.#arcade = setUpArcade(this, this.parts);
	}

	visibilityChanged(isVisible) {
		this.#arcade.visibilityChanged(isVisible);
	}

	reducedMotionChanged() {
		this.#arcade.run();
	}

	// Glitter cheers too.
	celebrate() {
		super.celebrate();
		this.cheer();
	}

	// The wallet and the sound of the arcade, which the Game Room uses too.
	spendCoins(amount) {
		return this.#arcade.spendCoins(amount);
	}

	addCoins(amount) {
		this.#arcade.addCoins(amount);
	}

	addTickets(amount) {
		return this.#arcade.addTickets(amount);
	}

	beep(frequency, duration, options) {
		this.#arcade.beep(frequency, duration, options);
	}

	get sounds() {
		return this.#arcade.sounds;
	}
}
