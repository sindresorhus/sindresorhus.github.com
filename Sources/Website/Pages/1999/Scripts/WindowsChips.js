// Chip’s Challenge on the desktop of the 1999 page, like the one of the Microsoft Entertainment Pack 4 (Chuck Sommerville, 1989): Chip collects the computer chips of a level, goes through the chip socket, and finds the exit. Keys open doors of their color, flippers let him swim, fire boots let him walk on fire, ice and force floors push him along, blocks sink into water and leave dirt, balls bounce, bugs follow the walls, teeth chase him, and a thief takes his boots. Each level has a four-letter password, like Chip’s Challenge. The game moves in ticks of a tenth of a second, and Chip one tile every two ticks. Nothing makes a sound until the visitor turns on the sound.

/*
The levels. Each tile is a character:
# wall, . floor, @ Chip, c chip, S chip socket, E exit, ? hint,
r b y g keys, R B Y G doors, f flippers, o fire boots,
~ water, ^ fire, = ice, < > A V force floors (left, right, up, down), : dirt, x block,
T thief, + green button, Q green wall (closed), q green wall (open),
u bug (starts going down), z ball (starts going right), t teeth.
*/
const levels = [
	{
		name: 'Lesson 1: Chips',
		password: 'WAFL',
		time: 100,
		hint: 'Collect all the chips. Then the chip socket lets you through to the exit. Move with the arrow keys, the buttons, a swipe, or a tap.',
		map: `
			###############
			#c...#...#...c#
			#....#...#....#
			#..#.......#..#
			#..#...?...#..#
			#......@......#
			#..#.......#..#
			#..#..#S#..#..#
			#c...##E##...c#
			#....#####....#
			###############
		`,
	},
	{
		name: 'Lesson 2: Lock and Key',
		password: 'BRUN',
		time: 150,
		hint: 'A key opens the door of its color, and is used up. The green key opens green doors again and again, like the key to Mormor’s cabin.',
		map: `
			###############
			#c.y.#...#.b.c#
			#....R...Y....#
			#....#...#....#
			##G###?@.###B##
			#....#...#....#
			#..c.#.r.#.c..#
			#....#...#....#
			#c...##S##..g.#
			#....##E##....#
			###############
		`,
	},
	{
		name: 'Lesson 3: Fire and Water',
		password: 'FJRD',
		time: 150,
		hint: 'Chip cannot swim without flippers, and fire is hot without fire boots. Mamma says no swimming for 30 minutes after waffles.',
		map: `
			###############
			#c...#~~~#...c#
			#....#~~~#....#
			#?@..~~~~~..o.#
			#....#~~~#....#
			#.f..#~~~#..c.#
			######~~~######
			#c.^^^^^^^^^.c#
			#..^^^^S^^^^..#
			#..^^^#E#^^^..#
			###############
		`,
	},
	{
		name: 'Ice Ice Baby',
		password: 'KOSS',
		time: 120,
		hint: 'Ice is slippery! Chip slides until he hits something. The arrows on the floor push him along, like the line at the ski lift in Hemsedal.',
		map: `
			#############
			#@.?........#
			#.=========.#
			#.==c===#==.#
			#.=====c===.#
			#.=#=======.#
			#.====#=c==.#
			#.=c=======.#
			#.=========.#
			#...........#
			#########S###
			#########V###
			#E<<<<<<<<###
			#############
		`,
	},
	{
		name: 'Block Party',
		password: 'LEGO',
		time: 200,
		hint: 'Push the blocks into the water to make a bridge. A block sinks and leaves dirt. Step on the dirt to sweep it away, or a block cannot go there.',
		map: `
			###############
			#@.?..#....~~c#
			#..x..#....~~.#
			#.....:....~~c#
			#..x..#....~~.#
			#c....#..c.~~S#
			#############E#
			###############
		`,
	},
	{
		name: 'Ping-Pong Hotel',
		password: 'PONG',
		time: 200,
		hint: 'The balls bounce back and forth all day. Wait in a nook in the wall until a ball goes by, then run!',
		map: `
			###############
			#@.?..........#
			######.########
			#c...z........#
			###.##.###.####
			##########.####
			#c.......z....#
			####.####.##.##
			############.##
			#c..z.........#
			#####.#.#.#####
			#######S#######
			#######E#######
			###############
		`,
	},
	{
		name: 'The Thief of Bergen',
		password: 'TYVN',
		time: 200,
		hint: 'Watch out for the thief! He takes all your boots, and sells them at the fish market. The green button opens green walls.',
		map: `
			###############
			#@.?.#~~~~~~~c#
			#.f..Q~~~c~~~~#
			#..+.#~~~~~~~c#
			#....##########
			#.o..#^^^^^^^c#
			#....:^^c^^^^^#
			####T##########
			#ES..##########
			###############
		`,
	},
	{
		name: 'Melinda’s Teeth',
		password: 'MLND',
		time: 200,
		hint: 'The teeth chase you, but they are slow, and the pillars confuse them. Like Pappa looking for the remote.',
		map: `
			###############
			#@.?..........#
			#.#.#.#.#.#.#.#
			#c...........c#
			#.#.#.#.#.#.#.#
			#......t......#
			#.#.#.#.#.#.#.#
			#c.t.......t.c#
			#.#.#.#.#.#.#.#
			#......t.....r#
			#.#.#.#.#.#.#.#
			#c.....R.....c#
			#######S#######
			#######E#######
			###############
		`,
	},
];

const directionVectors = {up: [0, -1], down: [0, 1], left: [-1, 0], right: [1, 0]};
const forceDirections = {'<': [-1, 0], '>': [1, 0], A: [0, -1], V: [0, 1]};
const keyNames = {r: 'red', b: 'blue', y: 'yellow', g: 'green'};
const doorKeys = {R: 'r', B: 'b', Y: 'y', G: 'g'};
const monsterKinds = {u: ['bug', 0, 1], z: ['ball', 1, 0], t: ['teeth', 0, 1]};

const deathMessages = {
	bug: 'Ooops! Look out for bugs!',
	ball: 'Ooops! A bouncing ball got you!',
	teeth: 'Ooops! The teeth got you! They smelled the brunost.',
};

// One level being played: the tiles, Chip, the monsters, and what Chip carries. It knows nothing of the page, so it can also run without it.
class ChipLevel {
	constructor(level) {
		this.level = level;
		this.map = level.map.trim().split('\n').map(row => [...row.trim()]);
		this.width = this.map[0].length;
		this.height = this.map.length;
		this.monsters = [];
		this.inventory = {r: 0, b: 0, y: 0, g: 0, f: false, o: false};
		this.chipsLeft = 0;
		this.ticks = 0;
		this.cooldown = 0;
		this.state = 'playing';
		this.events = [];

		for (const [y, row] of this.map.entries()) {
			for (const [x, tile] of row.entries()) {
				if (tile === '@') {
					this.chip = {x, y, dx: 0, dy: 1};
					row[x] = '.';
				} else if (monsterKinds[tile]) {
					const [kind, dx, dy] = monsterKinds[tile];
					this.monsters.push({kind, x, y, dx, dy});
					row[x] = '.';
				} else if (tile === 'c') {
					this.chipsLeft++;
				}
			}
		}
	}

	get timeLeft() {
		return Math.max((this.level.time * 10) - this.ticks, 0);
	}

	tileAt(x, y) {
		return this.map[y]?.[x] ?? '#';
	}

	monsterAt(x, y) {
		return this.monsters.find(monster => monster.x === x && monster.y === y);
	}

	emit(sound, message) {
		this.events.push({sound, message});
	}

	bump(message) {
		this.emit('bump', message);
		return false;
	}

	die(message) {
		this.state = 'dead';
		this.message = message;
		this.emit('death');
	}

	// Moves Chip one tile, if he can go there, and opens, pushes, and picks up what is in the way.
	tryMove(dx, dy, {isForced = false} = {}) {
		const {chip} = this;
		chip.dx = dx;
		chip.dy = dy;
		const x = chip.x + dx;
		const y = chip.y + dy;
		const tile = this.tileAt(x, y);

		if (tile === '#' || tile === 'Q') {
			return isForced ? false : this.bump();
		}

		if (doorKeys[tile]) {
			const key = doorKeys[tile];

			if (this.inventory[key] === 0) {
				return isForced ? false : this.bump(`This door needs a ${keyNames[key]} key.`);
			}

			// The green key opens every green door, like in Chip’s Challenge.
			if (key !== 'g') {
				this.inventory[key]--;
			}

			this.map[y][x] = '.';
			this.emit('door');
		} else if (tile === 'S') {
			if (this.chipsLeft > 0) {
				return isForced ? false : this.bump(`The chip socket needs ${this.chipsLeft} more ${this.chipsLeft === 1 ? 'chip' : 'chips'}.`);
			}

			this.map[y][x] = '.';
			this.emit('socket', 'The chip socket opens!');
		} else if (tile === 'x') {
			// A block moves on to the floor, or sinks into the water and leaves dirt.
			const beyondX = x + dx;
			const beyondY = y + dy;
			const beyond = this.tileAt(beyondX, beyondY);

			if ((beyond !== '.' && beyond !== '~') || this.monsterAt(beyondX, beyondY)) {
				return isForced ? false : this.bump();
			}

			this.map[beyondY][beyondX] = beyond === '~' ? ':' : 'x';
			this.map[y][x] = '.';
			this.emit(beyond === '~' ? 'splash' : 'push', beyond === '~' ? 'Splash! The block made dirt.' : undefined);
		}

		chip.x = x;
		chip.y = y;
		this.enter();
		return true;
	}

	// What happens when Chip steps on a tile.
	enter() {
		const {chip} = this;
		const tile = this.tileAt(chip.x, chip.y);
		this.slide = undefined;
		const monster = this.monsterAt(chip.x, chip.y);

		if (monster) {
			this.die(deathMessages[monster.kind]);
			return;
		}

		if (tile === 'c') {
			this.chipsLeft--;
			this.map[chip.y][chip.x] = '.';
			this.emit('chip', this.chipsLeft === 0 ? 'That was the last chip! Now to the chip socket.' : undefined);
		} else if (keyNames[tile]) {
			this.inventory[tile]++;
			this.map[chip.y][chip.x] = '.';
			this.emit('item', `A ${keyNames[tile]} key!`);
		} else if (tile === 'f' || tile === 'o') {
			this.inventory[tile] = true;
			this.map[chip.y][chip.x] = '.';
			this.emit('item', tile === 'f' ? 'Flippers! Now Chip can swim.' : 'Fire boots! Now Chip can walk on fire.');
		} else if (tile === ':') {
			this.map[chip.y][chip.x] = '.';
		} else if (tile === '~' && !this.inventory.f) {
			this.die('Ooops! Chip can’t swim without flippers!');
		} else if (tile === '^' && !this.inventory.o) {
			this.die('Ooops! Don’t step in the fire without fire boots!');
		} else if (tile === '=') {
			this.slide = [chip.dx, chip.dy];
		} else if (tile === 'T') {
			const hadBoots = this.inventory.f || this.inventory.o;
			this.inventory.f = false;
			this.inventory.o = false;
			this.emit(hadBoots ? 'thief' : 'item', hadBoots ? 'The thief took your boots! He sells them at the fish market.' : 'The thief looks at your feet. No boots. He is sad.');
		} else if (tile === '+') {
			for (const row of this.map) {
				for (const [x, rowTile] of row.entries()) {
					if (rowTile === 'Q') {
						row[x] = 'q';
					} else if (rowTile === 'q') {
						row[x] = 'Q';
					}
				}
			}

			this.emit('door', 'Click! The green walls changed.');
		} else if (tile === '?') {
			this.emit('hint', this.level.hint);
		} else if (tile === 'E') {
			this.state = 'won';
			this.emit('win');
		}
	}

	isMonsterFree(x, y) {
		const tile = this.tileAt(x, y);
		return (tile === '.' || tile === 'q') && !this.monsterAt(x, y);
	}

	// Bugs keep a wall on their left, balls bounce back, and teeth go toward Chip, along the longer way first.
	monsterChoices(monster) {
		const {dx, dy} = monster;

		if (monster.kind === 'bug') {
			return [[dy, -dx], [dx, dy], [-dy, dx], [-dx, -dy]];
		}

		if (monster.kind === 'ball') {
			return [[dx, dy], [-dx, -dy]];
		}

		const distanceX = this.chip.x - monster.x;
		const distanceY = this.chip.y - monster.y;
		const across = [Math.sign(distanceX), 0];
		const down = [0, Math.sign(distanceY)];
		const choices = Math.abs(distanceX) >= Math.abs(distanceY) ? [across, down] : [down, across];
		return choices.filter(([x, y]) => x !== 0 || y !== 0);
	}

	moveMonsters(kinds) {
		for (const monster of this.monsters) {
			if (!kinds.includes(monster.kind)) {
				continue;
			}

			for (const [dx, dy] of this.monsterChoices(monster)) {
				if (this.isMonsterFree(monster.x + dx, monster.y + dy)) {
					monster.x += dx;
					monster.y += dy;
					monster.dx = dx;
					monster.dy = dy;
					break;
				}
			}

			if (monster.x === this.chip.x && monster.y === this.chip.y) {
				this.die(deathMessages[monster.kind]);
				return;
			}
		}
	}

	// Ice and force floors move Chip by themselves, one tile each tick, twice as fast as he walks.
	isSliding() {
		return Boolean(this.slide) || (Boolean(forceDirections[this.tileAt(this.chip.x, this.chip.y)]) && !this.isStuck);
	}

	// One tick of a tenth of a second. Chip walks one tile every two ticks, like the monsters, and the teeth move every four.
	tick(direction) {
		if (this.state !== 'playing') {
			return;
		}

		this.ticks++;
		this.cooldown = Math.max(this.cooldown - 1, 0);
		const force = forceDirections[this.tileAt(this.chip.x, this.chip.y)];
		this.isStuck = false;

		if (force) {
			// A force floor that pushes Chip into a wall lets him walk off it.
			if (!this.tryMove(...force, {isForced: true})) {
				this.isStuck = true;

				if (direction && this.cooldown === 0) {
					this.tryMove(...directionVectors[direction]);
					this.cooldown = 2;
					this.didWalk = true;
				}
			}
		} else if (this.slide) {
			if (!this.tryMove(...this.slide, {isForced: true})) {
				this.slide = undefined;
			}
		} else if (direction && this.cooldown === 0) {
			this.tryMove(...directionVectors[direction]);
			this.cooldown = 2;
			this.didWalk = true;
		}

		if (this.state !== 'playing') {
			return;
		}

		if (this.ticks % 2 === 0) {
			this.moveMonsters(['bug', 'ball']);
		}

		if (this.ticks % 4 === 0) {
			this.moveMonsters(['teeth']);
		}

		if (this.state === 'playing' && this.timeLeft <= 0) {
			this.die('Ooops! Out of time!');
		}
	}

	// One step at a time, for visitors who prefer reduced motion: the world moves the two ticks of a step, and the slides to their end.
	act(direction) {
		this.didWalk = false;
		let ticks = 0;

		do {
			this.tick(this.didWalk ? undefined : direction);
			ticks++;
		} while (this.state === 'playing' && ticks < 80 && (ticks < 2 || this.cooldown > 1 || this.isSliding()));
	}
}

const size = 32;
const view = 9;

// The pictures of the tiles, drawn once each on a small canvas, in the gray, blue, and brown of Chip’s Challenge.
const tileCache = new Map();

const bevel = (draw, color, light, dark, width = 3) => {
	draw.fillStyle = color;
	draw.fillRect(0, 0, size, size);
	draw.fillStyle = light;
	draw.fillRect(0, 0, size, width);
	draw.fillRect(0, 0, width, size);
	draw.fillStyle = dark;
	draw.fillRect(0, size - width, size, width);
	draw.fillRect(size - width, 0, width, size);
};

const floor = draw => {
	bevel(draw, '#c0c0c0', '#e0e0e0', '#9a9a9a', 2);
};

const drawKey = (draw, color) => {
	draw.fillStyle = color;
	draw.strokeStyle = '#202020';
	draw.lineWidth = 1;
	draw.beginPath();
	draw.arc(11, 16, 6, 0, Math.PI * 2);
	draw.fill();
	draw.stroke();
	draw.fillRect(16, 14, 12, 4);
	draw.strokeRect(16, 14, 12, 4);
	draw.fillRect(22, 18, 3, 4);
	draw.fillRect(26, 18, 2, 3);
	draw.fillStyle = '#c0c0c0';
	draw.beginPath();
	draw.arc(11, 16, 2, 0, Math.PI * 2);
	draw.fill();
};

const keyColors = {r: '#e02020', b: '#2040e0', y: '#f0d000', g: '#20b020'};

const tilePainters = {
	'.': floor,
	'#': draw => bevel(draw, '#6d7fa0', '#a8b8d8', '#36445e', 4),
	c(draw) {
		floor(draw);
		draw.fillStyle = '#d0a020';

		for (let index = 0; index < 4; index++) {
			draw.fillRect(9 + (index * 4), 6, 2, 4);
			draw.fillRect(9 + (index * 4), 22, 2, 4);
		}

		draw.fillStyle = '#202020';
		draw.fillRect(7, 10, 18, 12);
		draw.fillStyle = '#808080';
		draw.fillRect(9, 12, 3, 3);
	},
	S(draw) {
		bevel(draw, '#707070', '#a0a0a0', '#404040');

		for (let index = 0; index < 4; index++) {
			draw.fillStyle = index % 2 === 0 ? '#f0d000' : '#202020';
			draw.fillRect(4 + (index * 6), 4, 6, 24);
		}

		draw.fillStyle = '#202020';
		draw.fillRect(9, 11, 14, 10);
		draw.fillStyle = '#d0a020';
		draw.fillRect(11, 13, 10, 6);
	},
	E(draw) {
		for (let ring = 0; ring < 5; ring++) {
			draw.fillStyle = ring % 2 === 0 ? '#1030c0' : '#40c0ff';
			draw.fillRect(ring * 3, ring * 3, size - (ring * 6), size - (ring * 6));
		}

		draw.fillStyle = '#ffffff';
		draw.fillRect(15, 15, 2, 2);
	},
	'?'(draw) {
		floor(draw);
		draw.fillStyle = '#1040c0';
		draw.fillRect(6, 6, 20, 20);
		draw.fillStyle = '#ffffff';
		draw.font = 'bold 18px system-ui, sans-serif';
		draw.textAlign = 'center';
		draw.textBaseline = 'middle';
		draw.fillText('?', 16, 17);
	},
	'~'(draw) {
		draw.fillStyle = '#1050d0';
		draw.fillRect(0, 0, size, size);
		draw.strokeStyle = '#70b0ff';
		draw.lineWidth = 2;

		for (const y of [8, 18, 28]) {
			draw.beginPath();
			draw.moveTo(2, y);
			draw.quadraticCurveTo(9, y - 5, 16, y);
			draw.quadraticCurveTo(23, y + 5, 30, y);
			draw.stroke();
		}
	},
	'^'(draw) {
		draw.fillStyle = '#500000';
		draw.fillRect(0, 0, size, size);

		for (const [x, height, color] of [[4, 22, '#ff5000'], [12, 28, '#ff8000'], [20, 20, '#ff5000'], [26, 24, '#ffb000'], [9, 14, '#ffe060'], [19, 12, '#ffe060']]) {
			draw.fillStyle = color;
			draw.beginPath();
			draw.moveTo(x - 5, 32);
			draw.lineTo(x, 32 - height);
			draw.lineTo(x + 5, 32);
			draw.fill();
		}
	},
	'='(draw) {
		draw.fillStyle = '#c8ecff';
		draw.fillRect(0, 0, size, size);
		draw.strokeStyle = '#ffffff';
		draw.lineWidth = 2;
		draw.beginPath();
		draw.moveTo(4, 14);
		draw.lineTo(14, 4);
		draw.moveTo(10, 28);
		draw.lineTo(28, 10);
		draw.stroke();
		draw.strokeStyle = '#90c8e8';
		draw.strokeRect(0.5, 0.5, size - 1, size - 1);
	},
	':'(draw) {
		draw.fillStyle = '#8a5a2a';
		draw.fillRect(0, 0, size, size);
		draw.fillStyle = '#5e3a18';

		for (const [x, y] of [[4, 5], [20, 3], [12, 12], [26, 15], [6, 22], [17, 25], [27, 27], [10, 29]]) {
			draw.fillRect(x, y, 3, 2);
		}
	},
	x(draw) {
		bevel(draw, '#b07030', '#e0a060', '#603810', 4);
		draw.strokeStyle = '#603810';
		draw.lineWidth = 2;
		draw.beginPath();
		draw.moveTo(6, 6);
		draw.lineTo(26, 26);
		draw.moveTo(26, 6);
		draw.lineTo(6, 26);
		draw.stroke();
	},
	f(draw) {
		floor(draw);
		draw.fillStyle = '#2060e0';

		for (const x of [8, 20]) {
			draw.beginPath();
			draw.moveTo(x - 2, 6);
			draw.lineTo(x + 2, 6);
			draw.lineTo(x + 6, 27);
			draw.lineTo(x - 6, 27);
			draw.fill();
		}
	},
	o(draw) {
		floor(draw);
		// A red boot with a black sole and a flame on top.
		draw.fillStyle = '#ffb000';
		draw.beginPath();
		draw.moveTo(10, 8);
		draw.lineTo(13, 2);
		draw.lineTo(15, 6);
		draw.lineTo(18, 1);
		draw.lineTo(19, 8);
		draw.fill();
		draw.fillStyle = '#d02010';
		draw.fillRect(10, 7, 9, 15);
		draw.beginPath();
		draw.moveTo(10, 18);
		draw.lineTo(22, 18);
		draw.arc(23, 23, 5, -Math.PI / 2, Math.PI / 2);
		draw.lineTo(10, 28);
		draw.fill();
		draw.fillStyle = '#202020';
		draw.fillRect(9, 27, 20, 3);
		draw.fillStyle = '#ff8070';
		draw.fillRect(12, 9, 2, 10);
	},
	T(draw) {
		floor(draw);
		// A burglar of the comics: a black hat and mask, a striped shirt, and a sack.
		draw.fillStyle = '#202020';
		draw.fillRect(10, 3, 12, 5);
		draw.fillStyle = '#f0c090';
		draw.fillRect(11, 8, 10, 8);
		draw.fillStyle = '#202020';
		draw.fillRect(11, 10, 10, 3);

		for (let index = 0; index < 4; index++) {
			draw.fillStyle = index % 2 === 0 ? '#202020' : '#ffffff';
			draw.fillRect(9, 16 + (index * 3), 14, 3);
		}

		draw.fillStyle = '#806040';
		draw.beginPath();
		draw.arc(25, 22, 5, 0, Math.PI * 2);
		draw.fill();
		draw.fillStyle = '#404040';
		draw.fillRect(10, 28, 4, 3);
		draw.fillRect(18, 28, 4, 3);
	},
	'+'(draw) {
		floor(draw);
		draw.fillStyle = '#106010';
		draw.beginPath();
		draw.arc(16, 16, 10, 0, Math.PI * 2);
		draw.fill();
		draw.fillStyle = '#30d030';
		draw.beginPath();
		draw.arc(15, 15, 8, 0, Math.PI * 2);
		draw.fill();
	},
	Q(draw) {
		bevel(draw, '#30a030', '#80e080', '#105010', 4);
	},
	q(draw) {
		floor(draw);
		draw.strokeStyle = '#30a030';
		draw.lineWidth = 2;
		draw.setLineDash([4, 3]);
		draw.strokeRect(3, 3, size - 6, size - 6);
		draw.setLineDash([]);
	},
};

for (const [key, color] of Object.entries(keyColors)) {
	tilePainters[key] = draw => {
		floor(draw);
		drawKey(draw, color);
	};

	tilePainters[key.toUpperCase()] = draw => {
		bevel(draw, color, '#ffffff80', '#00000080', 4);
		draw.fillStyle = '#202020';
		draw.beginPath();
		draw.arc(16, 13, 4, 0, Math.PI * 2);
		draw.fill();
		draw.fillRect(14, 13, 4, 9);
	};
}

for (const [tile, [dx, dy]] of Object.entries(forceDirections)) {
	tilePainters[tile] = draw => {
		draw.fillStyle = '#7fa07f';
		draw.fillRect(0, 0, size, size);
		draw.save();
		draw.translate(16, 16);
		draw.rotate(Math.atan2(dy, dx));
		draw.strokeStyle = '#e0ffe0';
		draw.lineWidth = 3;

		for (const offset of [-8, 4]) {
			draw.beginPath();
			draw.moveTo(offset - 4, -8);
			draw.lineTo(offset + 4, 0);
			draw.lineTo(offset - 4, 8);
			draw.stroke();
		}

		draw.restore();
	};
}

const tilePicture = tile => {
	if (!tileCache.has(tile)) {
		const canvas = document.createElement('canvas');
		canvas.width = size;
		canvas.height = size;
		(tilePainters[tile] ?? floor)(canvas.getContext('2d'));
		tileCache.set(tile, canvas);
	}

	return tileCache.get(tile);
};

// The panel next to the board, like the one of Chip’s Challenge: the level, the time, and the chips left in yellow digits, and the keys and boots that Chip carries. A screen reader reads the same in a hidden paragraph.
const panelX = view * size;
const keyDirections = {ArrowUp: 'up', ArrowDown: 'down', ArrowLeft: 'left', ArrowRight: 'right'};

export default class extends GeoCitiesElement {
	#context;
	#loop;
	#levelIndex;
	#game;
	#mode = 'ready';
	#score = 0;
	#tickTime = 0;
	#queued;
	#held = [];
	#swipeStart;

	connected() {
		const {screen, restart, pause, sound, passwordForm, password} = this.parts;
		this.#context = screen.getContext('2d');
		this.#levelIndex = Math.min(Math.max(this.stored('level', 0), 0), levels.length - 1);

		// The game runs only while its board is on the screen, in its open window, and the tab is visible. With reduced motion, it moves one step for each move of Chip.
		this.#loop = this.loop(seconds => {
			this.#tickTime += seconds * 1000;

			while (this.#tickTime >= 100 && this.#mode === 'playing' && this.#game.state === 'playing') {
				this.#tickTime -= 100;
				this.#game.tick(this.#queued ?? this.#held.at(-1));

				if (this.#game.didWalk) {
					this.#queued = undefined;
					this.#game.didWalk = false;
				}
			}

			this.#afterTicks();
		}, {while: () => this.#mode === 'playing' && !this.reducedMotion, maximumStep: 0.25});

		this.on(sound, 'click', () => {
			const isOn = !this.#isSoundOn;
			sound.setAttribute('aria-pressed', String(isOn));
			sound.textContent = isOn ? '🔊 Sound' : '🔈 Sound';

			if (isOn) {
				this.#sounds.chip();
			}
		});

		this.on(screen, 'keydown', event => {
			if (event.ctrlKey || event.altKey || event.metaKey) {
				return;
			}

			const direction = keyDirections[event.key];

			if (direction) {
				event.preventDefault();

				if (!event.repeat) {
					this.#press(direction);
				}
			} else if (event.key === ' ' && this.reducedMotion && this.#mode === 'playing') {
				// With reduced motion, Space waits a step, so a ball can go by.
				event.preventDefault();
				this.#game.act();
				this.#afterTicks();
			} else if (event.key === 'p' || event.key === 'P') {
				event.preventDefault();
				this.#setPaused(this.#mode === 'playing');
			}
		});

		this.on(screen, 'keyup', event => {
			const direction = keyDirections[event.key];

			if (direction) {
				this.#release(direction);
			}
		});

		this.on(screen, 'blur', () => {
			this.#held.length = 0;
		});

		// A swipe on the board moves Chip that way, and a tap moves him one tile toward the tapped tile.
		this.on(screen, 'pointerdown', event => {
			if (event.button === 0) {
				this.#swipeStart = {x: event.clientX, y: event.clientY};
			}
		});

		this.on(screen, 'pointerup', event => {
			this.#swipe(event);
		});

		this.on(screen, 'pointercancel', () => {
			this.#swipeStart = undefined;
		});

		// The buttons of the direction pad walk while they are held, and a key on the keyboard moves one step.
		for (const button of this.querySelectorAll('[data-chips-move]')) {
			const direction = button.dataset.chipsMove;

			this.on(button, 'pointerdown', event => {
				if (event.button !== 0) {
					return;
				}

				button.setPointerCapture(event.pointerId);
				this.#press(direction);

				// Safari does not focus a button on a click, so the board gets the focus, where the arrow keys work too.
				screen.focus({preventScroll: true});
			});

			for (const type of ['pointerup', 'pointercancel', 'lostpointercapture']) {
				this.on(button, type, () => {
					this.#release(direction);
				});
			}

			this.on(button, 'click', event => {
				if (event.detail === 0) {
					this.#press(direction);
					this.#release(direction);
				}
			});

			// A long press of a finger would open the menu of the browser.
			this.on(button, 'contextmenu', event => {
				event.preventDefault();
			});
		}

		this.on(restart, 'click', () => {
			this.#startLevel(this.#levelIndex);
			screen.focus();
		});

		this.on(pause, 'click', () => {
			this.#setPaused(this.#mode === 'playing');
		});

		this.on(passwordForm, 'submit', event => {
			event.preventDefault();
			const text = password.value.trim().toUpperCase();
			const index = levels.findIndex(level => level.password === text);

			if (index === -1) {
				this.say(`${text || 'Nothing'} is not a password. (It is not Mamma’s password either.)`);
				return;
			}

			password.value = '';
			this.#startLevel(index);
			screen.focus();
		});

		// A click elsewhere pauses the game, as the keys no longer reach it. The message box of the desktop is not elsewhere.
		this.on(document, 'pointerdown', event => {
			if (!this.desktopWindow.contains(event.target) && !event.target.closest('[data-desktop-window="message"]')) {
				this.#setPaused(true, 'Paused, as you clicked somewhere else. Press an arrow key, P, or tap the board to go on.');
			}
		});

		this.#startLevel(this.#levelIndex);
	}

	get visibilityTarget() {
		return this.parts.screen;
	}

	visibilityChanged(isVisible) {
		if (isVisible) {
			return;
		}

		// A closed window pauses the game before this, in `windowChanged()`, so it does not say that the board scrolled away.
		if (document.hidden) {
			this.#setPaused(true, 'Paused, as you left the page. Press an arrow key, P, or tap the board to go on.');
		} else {
			this.#setPaused(true, 'Paused, as the board scrolled away. Press an arrow key, P, or tap the board to go on.');
		}
	}

	windowChanged(isOpen) {
		if (isOpen) {
			this.#draw();
		} else {
			this.#setPaused(true);
		}
	}

	// A question with the message box of the desktop.
	ask(options) {
		return super.ask({title: 'Chip’s Challenge', icon: '💾', opener: this.parts.screen, ...options});
	}

	get #isSoundOn() {
		return this.parts.sound.getAttribute('aria-pressed') === 'true';
	}

	// The sounds, made with tones through the volume of the tray, once the visitor turns them on.
	#tone(frequency, start, duration, {type = 'square', volume = 0.05, slide} = {}) {
		const audio = this.#isSoundOn ? this.sound() : undefined;

		if (!audio) {
			return;
		}

		const {context, output} = audio;
		const oscillator = context.createOscillator();
		const gain = context.createGain();
		const time = context.currentTime + start;
		oscillator.type = type;
		oscillator.frequency.setValueAtTime(frequency, time);

		if (slide) {
			oscillator.frequency.exponentialRampToValueAtTime(slide, time + duration);
		}

		gain.gain.setValueAtTime(0.0001, time);
		gain.gain.exponentialRampToValueAtTime(volume, time + 0.01);
		gain.gain.exponentialRampToValueAtTime(0.0001, time + duration);
		oscillator.connect(gain).connect(output);
		oscillator.start(time);
		oscillator.stop(time + duration + 0.05);
	}

	#sounds = {
		chip: () => {
			this.#tone(880, 0, 0.06);
			this.#tone(1320, 0.06, 0.08);
		},
		item: () => this.#tone(660, 0, 0.12, {type: 'triangle', volume: 0.1, slide: 990}),
		door: () => this.#tone(330, 0, 0.08, {volume: 0.08}),
		socket: () => {
			for (const [index, frequency] of [523, 659, 784].entries()) {
				this.#tone(frequency, index * 0.06, 0.15, {type: 'triangle', volume: 0.08});
			}
		},
		push: () => this.#tone(110, 0, 0.06, {type: 'triangle', volume: 0.12}),
		splash: () => this.#tone(400, 0, 0.3, {type: 'sawtooth', volume: 0.05, slide: 80}),
		bump: () => this.#tone(90, 0, 0.05, {type: 'triangle', volume: 0.1}),
		hint: () => this.#tone(1320, 0, 0.3, {type: 'sine', volume: 0.08}),
		thief: () => {
			for (const [index, frequency] of [600, 500, 600, 500].entries()) {
				this.#tone(frequency, index * 0.08, 0.07, {volume: 0.05});
			}
		},
		death: () => {
			for (const [index, frequency] of [440, 370, 311, 262].entries()) {
				this.#tone(frequency, index * 0.12, 0.15, {type: 'square', volume: 0.06});
			}
		},
		win: () => {
			for (const [index, frequency] of [523, 659, 784, 1047, 784, 1047].entries()) {
				this.#tone(frequency, index * 0.09, 0.14, {type: 'triangle', volume: 0.08});
			}
		},
	};

	// The monsters and Chip are drawn turned the way they go.
	#drawTurned(x, y, dx, dy, draw) {
		const context = this.#context;
		context.save();
		context.translate(x + 16, y + 16);
		context.rotate(Math.atan2(dy, dx) - (Math.PI / 2));
		draw();
		context.restore();
	}

	#drawMonster(monster, x, y) {
		const context = this.#context;

		if (monster.kind === 'ball') {
			context.fillStyle = '#ff60c0';
			context.beginPath();
			context.arc(x + 16, y + 16, 11, 0, Math.PI * 2);
			context.fill();
			context.fillStyle = '#ffd0f0';
			context.beginPath();
			context.arc(x + 12, y + 12, 4, 0, Math.PI * 2);
			context.fill();
			return;
		}

		if (monster.kind === 'teeth') {
			context.fillStyle = '#c01030';
			context.fillRect(x + 4, y + 8, 24, 16);
			context.fillStyle = '#ffffff';

			for (let index = 0; index < 4; index++) {
				context.beginPath();
				context.moveTo(x + 4 + (index * 6), y + 8);
				context.lineTo(x + 7 + (index * 6), y + 15);
				context.lineTo(x + 10 + (index * 6), y + 8);
				context.fill();
				context.beginPath();
				context.moveTo(x + 4 + (index * 6), y + 24);
				context.lineTo(x + 7 + (index * 6), y + 17);
				context.lineTo(x + 10 + (index * 6), y + 24);
				context.fill();
			}

			return;
		}

		// A red bug with six legs, its head the way it goes.
		this.#drawTurned(x, y, monster.dx, monster.dy, () => {
			context.strokeStyle = '#202020';
			context.lineWidth = 2;

			for (const legY of [-5, 1, 7]) {
				context.beginPath();
				context.moveTo(-11, legY - 2);
				context.lineTo(11, legY + 2);
				context.stroke();
			}

			context.fillStyle = '#d02020';
			context.beginPath();
			context.ellipse(0, 0, 8, 11, 0, 0, Math.PI * 2);
			context.fill();
			context.fillStyle = '#202020';
			context.beginPath();
			context.arc(0, 10, 5, 0, Math.PI * 2);
			context.fill();
			context.fillRect(-1, -10, 2, 18);
		});
	}

	#drawChip(x, y) {
		const context = this.#context;
		const {dx, dy} = this.#game.chip;
		const isDead = this.#game.state === 'dead';
		// The body, the head, and the brown hair of Chip, and his glasses, which look the way he goes.
		context.fillStyle = '#2050d0';
		context.fillRect(x + 9, y + 18, 14, 10);
		context.fillStyle = '#202060';
		context.fillRect(x + 10, y + 28, 4, 3);
		context.fillRect(x + 18, y + 28, 4, 3);
		context.fillStyle = '#f0c090';
		context.beginPath();
		context.arc(x + 16, y + 12, 8, 0, Math.PI * 2);
		context.fill();
		context.fillStyle = '#704010';
		context.fillRect(x + 8, y + 3, 16, dy < 0 ? 12 : 5);

		if (dy < 0) {
			return;
		}

		const eyeX = x + 16 + (dx * 3);

		if (isDead) {
			context.strokeStyle = '#202020';
			context.lineWidth = 2;

			for (const offset of [-4, 4]) {
				context.beginPath();
				context.moveTo(eyeX + offset - 2, y + 10);
				context.lineTo(eyeX + offset + 2, y + 14);
				context.moveTo(eyeX + offset + 2, y + 10);
				context.lineTo(eyeX + offset - 2, y + 14);
				context.stroke();
			}

			return;
		}

		context.strokeStyle = '#202020';
		context.lineWidth = 1.5;

		for (const offset of dx === 0 ? [-4, 4] : [dx * 2]) {
			context.beginPath();
			context.arc(eyeX + offset, y + 12, 3, 0, Math.PI * 2);
			context.stroke();
		}
	}

	// The view of 9 × 9 tiles follows Chip, and stops at the edges of the level.
	#viewOrigin() {
		const game = this.#game;

		const origin = axis => {
			const length = axis === 'x' ? game.width : game.height;
			return length <= view ? -Math.floor((view - length) / 2) : Math.min(Math.max(game.chip[axis] - 4, 0), length - view);
		};

		return {x: origin('x'), y: origin('y')};
	}

	#drawCounter(label, value, y) {
		const context = this.#context;
		context.fillStyle = '#000080';
		context.textAlign = 'center';
		context.textBaseline = 'alphabetic';
		context.font = 'bold 12px system-ui, sans-serif';
		context.fillText(label, panelX + 64, y);
		context.fillStyle = '#000000';
		context.fillRect(panelX + 24, y + 4, 80, 26);
		context.fillStyle = '#ffd800';
		context.font = 'bold 22px "Courier New", monospace';
		context.fillText(String(value).padStart(3, ' '), panelX + 64, y + 25);
	}

	#drawPanel() {
		const context = this.#context;
		const game = this.#game;
		const {screen} = this.parts;
		context.fillStyle = '#c0c0c0';
		context.fillRect(panelX, 0, screen.width - panelX, screen.height);
		context.fillStyle = '#808080';
		context.fillRect(panelX, 0, 3, screen.height);
		const time = Math.ceil(game.timeLeft / 10);
		this.#drawCounter('LEVEL', this.#levelIndex + 1, 22);
		this.#drawCounter('TIME', time, 80);
		this.#drawCounter('CHIPS LEFT', game.chipsLeft, 138);
		const items = [];

		for (const [index, key] of ['r', 'b', 'y', 'g'].entries()) {
			const count = game.inventory[key];
			context.drawImage(tilePicture(count > 0 ? key : '.'), panelX + (index * size), 220);

			if (count > 1) {
				context.fillStyle = '#000000';
				context.font = 'bold 11px system-ui, sans-serif';
				context.textAlign = 'right';
				context.fillText(String(count), panelX + (index * size) + 30, 250);
			}

			if (count > 0) {
				items.push(`${count} ${keyNames[key]} ${count === 1 ? 'key' : 'keys'}`);
			}
		}

		for (const [index, item] of ['f', 'o', '', ''].entries()) {
			context.drawImage(tilePicture(game.inventory[item] ? item : '.'), panelX + (index * size), 252);

			if (game.inventory[item]) {
				items.push(item === 'f' ? 'flippers' : 'fire boots');
			}
		}

		this.parts.counters.textContent = `Level ${this.#levelIndex + 1}, ${time} seconds left, ${game.chipsLeft} ${game.chipsLeft === 1 ? 'chip' : 'chips'} left. Chip carries ${items.length > 0 ? items.join(', ') : 'nothing'}.`;
	}

	// A banner at the top of the board, or at the bottom when Chip is in the top half, so he stays in sight.
	#drawBanner(title, subtitle) {
		const context = this.#context;
		const y = this.#game.chip.y - this.#viewOrigin().y < 5 ? 200 : 12;
		context.fillStyle = 'rgb(0 0 64 / 85%)';
		context.fillRect(16, y, 256, 72);
		context.strokeStyle = '#ffffff';
		context.lineWidth = 2;
		context.strokeRect(16, y, 256, 72);
		context.textAlign = 'center';
		context.textBaseline = 'alphabetic';
		context.fillStyle = '#ffff00';
		context.font = 'bold 20px "Comic Sans MS", "Comic Sans", cursive';
		context.fillText(title, 144, y + 30);
		context.fillStyle = '#ffffff';
		context.font = '13px system-ui, sans-serif';
		context.fillText(subtitle, 144, y + 56);
	}

	#draw() {
		const context = this.#context;
		const game = this.#game;
		const {screen} = this.parts;
		const origin = this.#viewOrigin();
		context.fillStyle = '#000000';
		context.fillRect(0, 0, screen.width, screen.height);

		for (let row = 0; row < view; row++) {
			for (let column = 0; column < view; column++) {
				const x = origin.x + column;
				const y = origin.y + row;

				if (x >= 0 && y >= 0 && x < game.width && y < game.height) {
					context.drawImage(tilePicture(game.tileAt(x, y)), column * size, row * size);
				}
			}
		}

		// The monsters out of the view must not show on the panel.
		context.save();
		context.beginPath();
		context.rect(0, 0, panelX, screen.height);
		context.clip();

		for (const monster of game.monsters) {
			this.#drawMonster(monster, (monster.x - origin.x) * size, (monster.y - origin.y) * size);
		}

		this.#drawChip((game.chip.x - origin.x) * size, (game.chip.y - origin.y) * size);
		context.restore();

		if (this.#mode === 'ready') {
			this.#drawBanner(levels[this.#levelIndex].name, `Password: ${levels[this.#levelIndex].password}`);
		} else if (this.#mode === 'paused') {
			this.#drawBanner('Paused', 'Press an arrow key or tap to go on.');
		} else if (this.#mode === 'done') {
			this.#drawBanner('You did it!', 'Welcome to the Bit Busters club!');
		}

		this.#drawPanel();
	}

	#startLevel(index) {
		this.#levelIndex = index;
		this.store('level', index);
		this.#game = new ChipLevel(levels[index]);
		this.#mode = 'ready';
		this.#queued = undefined;
		this.#held.length = 0;
		this.say(`Level ${index + 1}: ${levels[index].name}. Password: ${levels[index].password}. Move to start the clock.${this.reducedMotion ? ' The game moves one step for each move of Chip, as your computer prefers less motion. Space waits a step.' : ''}`);
		this.#draw();
	}

	// The sounds and messages of what happened in the last ticks.
	#handleEvents() {
		for (const {sound, message} of this.#game.events) {
			this.#sounds[sound]?.();

			if (message) {
				this.say(message);
			}
		}

		this.#game.events = [];
	}

	// The message box does not block the window, so a level that the visitor restarts or picks while it is open wins over the one that was finished.
	async #finishLevel() {
		const finishedGame = this.#game;

		if (finishedGame.state === 'dead') {
			this.#mode = 'dead';
			this.#draw();
			await this.ask({icon: '💀', text: finishedGame.message});

			if (this.#game === finishedGame) {
				this.#startLevel(this.#levelIndex);
			}

			return;
		}

		this.#mode = 'won';
		const timeBonus = Math.ceil(finishedGame.timeLeft / 10) * 10;
		const levelBonus = (this.#levelIndex + 1) * 500;
		this.#score += timeBonus + levelBonus;
		this.#draw();

		if (this.#levelIndex === levels.length - 1) {
			this.store('level', 0);
			this.#mode = 'done';
			this.#draw();
			await this.ask({icon: '🏆', text: `You finished all ${levels.length} levels! Time bonus: ${timeBonus}. Level bonus: ${levelBonus}. Total score: ${this.#score.toLocaleString('en-US')}.\n\nMelinda the Mental Marvel is impressed, and lets you into the Bit Busters club. The club meets in the computer room after school. Bring waffles.`});
			this.say('You beat Chip’s Challenge! Press Restart Level to play the last level again, or type a password.');
			return;
		}

		this.store('level', this.#levelIndex + 1);
		await this.ask({icon: '🎉', text: `Level ${this.#levelIndex + 1} complete!\n\nTime bonus: ${timeBonus}\nLevel bonus: ${levelBonus}\nTotal score: ${this.#score.toLocaleString('en-US')}\n\nThe password for level ${this.#levelIndex + 2} is ${levels[this.#levelIndex + 1].password}.`});

		if (this.#game === finishedGame) {
			this.#startLevel(this.#levelIndex + 1);
		}
	}

	#afterTicks() {
		this.#handleEvents();
		this.#draw();

		if (this.#game.state !== 'playing') {
			this.#finishLevel();
		}
	}

	#setPaused(isPaused, message = 'Paused. Press an arrow key, P, or tap the board to go on.') {
		if (isPaused && this.#mode === 'playing') {
			this.#mode = 'paused';
			this.#held.length = 0;
			this.say(message);
		} else if (!isPaused && this.#mode === 'paused') {
			this.#mode = 'playing';
			this.say('Go!');
		} else {
			return;
		}

		this.parts.pause.setAttribute('aria-pressed', String(this.#mode === 'paused'));
		this.#draw();
		this.#loop.start();
	}

	// A move starts the clock of a new level and goes on after a pause. With reduced motion, the game moves the step at once.
	#press(direction) {
		if (this.#mode === 'paused') {
			this.#setPaused(false);
		}

		if (this.#mode === 'ready') {
			this.#mode = 'playing';
		}

		if (this.#mode !== 'playing') {
			return;
		}

		if (this.reducedMotion) {
			this.#game.act(direction);
			this.#afterTicks();
			return;
		}

		this.#queued = direction;

		if (!this.#held.includes(direction)) {
			this.#held.push(direction);
		}

		this.#loop.start();
	}

	#release(direction) {
		const index = this.#held.indexOf(direction);

		if (index !== -1) {
			this.#held.splice(index, 1);
		}
	}

	#swipe(event) {
		if (!this.#swipeStart) {
			return;
		}

		const {screen} = this.parts;
		const box = screen.getBoundingClientRect();
		let dx = event.clientX - this.#swipeStart.x;
		let dy = event.clientY - this.#swipeStart.y;
		this.#swipeStart = undefined;

		if (Math.hypot(dx, dy) < 20) {
			// A tap on the panel is not a move.
			if ((event.clientX - box.left) / box.width > panelX / screen.width) {
				return;
			}

			const origin = this.#viewOrigin();
			const tileX = Math.floor(((event.clientX - box.left) / box.width) * (screen.width / size)) + origin.x;
			const tileY = Math.floor(((event.clientY - box.top) / box.height) * view) + origin.y;
			dx = tileX - this.#game.chip.x;
			dy = tileY - this.#game.chip.y;

			if (dx === 0 && dy === 0) {
				if (this.#mode === 'paused') {
					this.#setPaused(false);
				}

				return;
			}
		}

		const direction = Math.abs(dx) >= Math.abs(dy) ? (dx > 0 ? 'right' : 'left') : (dy > 0 ? 'down' : 'up');
		this.#press(direction);
		this.#release(direction);
	}
}
