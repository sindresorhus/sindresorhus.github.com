// My handheld game console on the 1999 page, with Super Sindre Land on its screen of 160 × 144 pixels: a platform game in three levels through Bergen, Bryggen, the fish market, and up Fløyen, with waffles to collect, lemmings to jump on, seagulls that steal waffles, rain clouds, an umbrella that keeps the rain off and lets the kid float down, and the flag of Norway at the end of each level. The jump goes higher while A is held, and forgives a press a moment too early or a moment after running off an edge, so it feels fair. The cartridge does not always start, like a real one, until the visitor blows on it. The game runs only while the game console is on the screen and the tab is visible, and it pauses by itself when either goes away.
const randomInteger = (minimum, maximum) => minimum + Math.floor(Math.random() * (maximum - minimum + 1));
const clamp = (value, minimum, maximum) => Math.min(Math.max(value, minimum), maximum);
const plural = (count, word) => `${count.toLocaleString('en-US')} ${word}${count === 1 ? '' : 's'}`;

// A tiny pixel font of 3 × 5 for the screen, so the text is crisp at any size. Each letter is five rows of three bits.
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

// Sets up the game console in the element, and gives what it does when the screen comes and goes.
const setUp = (handheld, {screen, power, led, blow}) => {
	const context = screen.getContext('2d');
	const width = 160;
	const height = 144;
	const tile = 8;
	const rows = 18;

	// The levels, made of parts: the ground from one column to another at a row, platforms, crates, rows of waffles, and the rest, which is easier to tune than a map of letters.
	const levelPlans = [
		{
			name: 'BRYGGEN',
			sky: ['#9ec8e8', '#c8e0f0'],
			groundColors: ['#8a5a2b', '#6b4220', '#b07a45'],
			houses: true,
			length: 112,
			// The gaps of the first level are two tiles wide, so a walking jump clears them easily, and the gaps of the next levels are three tiles wide, where a run helps.
			ground: [[0, 22, 14], [25, 46, 14], [47, 52, 12], [53, 60, 14], [63, 84, 14], [87, 112, 14]],
			// The first platform ends well before the first crate, so the jump over the crate does not bump the head on it.
			platforms: [[5, 10, 4], [36, 9, 3], [68, 10, 4], [76, 7, 3]],
			crates: [[16, 13], [30, 13], [31, 13], [31, 12], [58, 13], [95, 13], [96, 13], [96, 12]],
			waffles: [[3, 12, 3], [5, 8, 4], [23, 10, 3], [36, 7, 3], [48, 10, 3], [61, 11, 3], [68, 8, 4], [76, 5, 3], [85, 11, 3], [90, 12, 4]],
			brunost: [[77, 5]],
			umbrellas: [],
			lemmings: [40, 56, 78, 100],
			seagulls: [[66, 6]],
			clouds: [],
			checkpoint: 53,
			flag: 106,
		},
		{
			name: 'FISKETORGET',
			sky: ['#a8c0d8', '#d0dce8'],
			groundColors: ['#7a7a84', '#5a5a64', '#9a9aa4'],
			stalls: true,
			length: 118,
			ground: [[0, 14, 14], [18, 28, 14], [32, 36, 14], [40, 55, 14], [59, 62, 14], [66, 80, 14], [84, 88, 14], [92, 118, 14]],
			platforms: [[44, 9, 3], [69, 9, 3], [96, 9, 3]],
			crates: [[21, 13], [22, 13], [22, 12], [47, 13], [48, 13], [48, 12], [48, 11], [72, 13], [100, 13], [101, 12], [101, 13]],
			waffles: [[3, 12, 3], [15, 10, 4], [21, 10, 2], [29, 10, 4], [37, 10, 4], [44, 7, 3], [56, 10, 4], [63, 11, 3], [69, 7, 3], [81, 10, 4], [89, 11, 3], [96, 7, 3], [105, 12, 4]],
			brunost: [[48, 9]],
			umbrellas: [],
			lemmings: [50, 75, 110],
			seagulls: [[20, 5], [45, 5], [68, 5], [95, 5]],
			clouds: [],
			// The lamp post is after the first three gaps, as the fish market has many.
			checkpoint: 42,
			flag: 114,
		},
		{
			name: 'FLØYEN',
			sky: ['#8898a8', '#b8c4d0'],
			groundColors: ['#4a7a3a', '#5a3a20', '#6a9a4a'],
			trees: true,
			length: 122,
			// The step before the first gap is long enough to land on after a running jump up to it.
			ground: [[0, 12, 14], [13, 20, 13], [21, 29, 12], [33, 38, 12], [39, 44, 11], [48, 58, 11], [59, 64, 10], [68, 80, 10], [84, 90, 9], [94, 122, 9]],
			platforms: [[14, 9, 3], [50, 7, 3], [71, 6, 3], [98, 5, 3]],
			crates: [[36, 11], [56, 10], [56, 9], [104, 8]],
			waffles: [[6, 12, 3], [14, 7, 3], [30, 9, 3], [34, 10, 3], [45, 8, 3], [50, 5, 3], [56, 7, 1], [65, 7, 3], [71, 4, 3], [81, 6, 3], [91, 6, 3], [98, 3, 3], [108, 7, 5]],
			brunost: [[51, 3]],
			umbrellas: [[4, 12]],
			// No lemming walks where the jump over the first gap lands, under the first rain cloud.
			lemmings: [42, 54, 76, 108],
			seagulls: [[60, 3], [88, 2]],
			clouds: [[24, 2], [52, 2], [76, 1], [104, 1]],
			checkpoint: 68,
			flag: 116,
		},
	];

	// Builds the map of a level: a row of letters for each row of tiles. `#` is ground, `=` a platform, and `B` a crate, which are solid.
	const buildLevel = plan => {
		const map = Array.from({length: rows}, () => Array.from({length: plan.length}, () => ' '));
		const groundTop = Array.from({length: plan.length}, () => undefined);
		for (const [from, to, top] of plan.ground) {
			for (let column = from; column <= Math.min(to, plan.length - 1); column++) {
				groundTop[column] = top;
				for (let row = top; row < rows; row++) {
					map[row][column] = '#';
				}
			}
		}

		for (const [column, row, length] of plan.platforms) {
			for (let index = 0; index < length; index++) {
				map[row][column + index] = '=';
			}
		}

		for (const [column, row] of plan.crates) {
			map[row][column] = 'B';
		}

		const items = [];
		for (const [column, row, count] of plan.waffles) {
			for (let index = 0; index < count; index++) {
				items.push({type: 'waffle', x: ((column + index) * tile) + 1, y: (row * tile) + 1, isTaken: false});
			}
		}

		for (const [column, row] of plan.brunost) {
			items.push({type: 'brunost', x: (column * tile) + 1, y: (row * tile) + 2, isTaken: false});
		}

		for (const [column, row] of plan.umbrellas) {
			items.push({type: 'umbrella', x: column * tile, y: row * tile, isTaken: false});
		}

		const enemies = [
			...plan.lemmings.map(column => ({type: 'lemming', x: column * tile, y: ((groundTop[column] ?? 14) * tile) - 7, direction: -1, velocityY: 0, isAlive: true})),
			...plan.seagulls.map(([column, row]) => ({type: 'seagull', homeX: column * tile, homeY: row * tile, x: column * tile, y: row * tile, phase: 'patrol', time: 0, isAlive: true})),
			...plan.clouds.map(([column, row]) => ({type: 'cloud', homeX: column * tile, x: column * tile, y: row * tile, time: Math.random() * 2, isAlive: true})),
		];

		return {plan, map, groundTop, items, enemies, drops: []};
	};

	const isSolid = (level, column, row) => {
		if (column < 0) {
			return true;
		}

		if (row < 0 || row >= rows || column >= level.plan.length) {
			return false;
		}

		return '#=B'.includes(level.map[row][column]);
	};

	// The buttons held down, and the buttons pressed since the last frame, so a quick tap is never missed.
	const buttons = new Set();
	const pressed = new Set();
	const press = name => {
		buttons.add(name);
		pressed.add(name);
	};

	const game = {
		isOn: false,
		mode: 'off',
		isGarbled: false,
		isCartridgeClean: false,
		bootTime: 0,
		levelIndex: 0,
		level: undefined,
		player: undefined,
		cameraX: 0,
		hearts: 3,
		waffles: 0,
		score: 0,
		hasUmbrella: false,
		best: Math.max(0, Math.round(Number(handheld.stored('best', 0)) || 0)),
		modeTime: 0,
		time: 0,
		jumpBuffer: 0,
		checkpointX: 16,
		levelStart: {waffles: 0, score: 0},
	};

	const newPlayer = x => ({x, y: 40, velocityX: 0, velocityY: 0, isOnGround: false, coyote: 0, facing: 1, hurtTime: 0, walkTime: 0});

	const startLevel = index => {
		game.levelIndex = index;
		game.level = buildLevel(levelPlans[index]);
		game.checkpointX = 16;
		game.player = newPlayer(16);
		game.cameraX = 0;
		game.mode = 'intro';
		game.modeTime = 0;
		game.levelStart = {waffles: game.waffles, score: game.score};
		handheld.say(`Level ${index + 1}: ${levelPlans[index].name === 'FLØYEN' ? 'Fløyen' : levelPlans[index].name.charAt(0) + levelPlans[index].name.slice(1).toLowerCase()}.`);
	};

	const startGame = () => {
		game.hearts = 3;
		game.waffles = 0;
		game.score = 0;
		game.hasUmbrella = false;
		startLevel(0);
	};

	// After a game over, Start continues at the start of the same level, with full hearts and the waffles and the score it started with, so a visitor never has to play the first level again and again to see the last one.
	const continueGame = () => {
		game.hearts = 3;
		game.hasUmbrella = false;
		Object.assign(game, game.levelStart);
		startLevel(game.levelIndex);
	};

	const hurt = reason => {
		const {player} = game;
		if (player.hurtTime > 0) {
			return;
		}

		player.hurtTime = 1.2;
		if (game.hasUmbrella && reason !== 'water') {
			game.hasUmbrella = false;
			handheld.say('Ouch! The umbrella broke.');
			return;
		}

		game.hearts--;
		if (game.hearts <= 0) {
			game.mode = 'over';
			game.modeTime = 0;
			finishGame(false);
			return;
		}

		handheld.say(reason === 'water' ? 'Splash! Into the harbor. Back to the last lamp post.' : `Ouch! ${plural(game.hearts, 'heart')} left.`);
	};

	const finishGame = hasWon => {
		const isBest = game.score > game.best;
		if (isBest) {
			game.best = game.score;
			handheld.store('best', game.score);
		}

		if (hasWon) {
			handheld.celebrate();
			handheld.say(`You made it to the top of Fløyen! Score: ${game.score}${isBest ? ', a new record' : ''}. Press Start to play again.`);
		} else {
			handheld.say(`Game over! Score: ${game.score}${isBest ? ', a new record' : ''}. Press Start to try level ${game.levelIndex + 1} again.`);
		}
	};

	// Moves a box through the tiles, first sideways and then up or down, and stops it at solid tiles.
	const moveBox = (box, boxWidth, boxHeight, seconds) => {
		const {level} = game;
		box.x += box.velocityX * seconds;
		const top = Math.floor(box.y / tile);
		const bottom = Math.floor((box.y + boxHeight - 1) / tile);
		let hitWall = false;
		if (box.velocityX > 0) {
			const column = Math.floor((box.x + boxWidth - 1) / tile);
			for (let row = top; row <= bottom; row++) {
				if (isSolid(level, column, row)) {
					box.x = (column * tile) - boxWidth;
					box.velocityX = 0;
					hitWall = true;
					break;
				}
			}
		} else if (box.velocityX < 0) {
			const column = Math.floor(box.x / tile);
			for (let row = top; row <= bottom; row++) {
				if (isSolid(level, column, row)) {
					box.x = (column + 1) * tile;
					box.velocityX = 0;
					hitWall = true;
					break;
				}
			}
		}

		box.y += box.velocityY * seconds;
		const left = Math.floor(box.x / tile);
		const right = Math.floor((box.x + boxWidth - 1) / tile);
		let isOnGround = false;
		if (box.velocityY > 0) {
			const row = Math.floor((box.y + boxHeight - 1) / tile);
			for (let column = left; column <= right; column++) {
				if (isSolid(level, column, row)) {
					box.y = (row * tile) - boxHeight;
					box.velocityY = 0;
					isOnGround = true;
					break;
				}
			}
		} else if (box.velocityY < 0) {
			const row = Math.floor(box.y / tile);
			for (let column = left; column <= right; column++) {
				if (isSolid(level, column, row)) {
					box.y = (row + 1) * tile;
					box.velocityY = 0;
					break;
				}
			}
		}

		return {isOnGround, hitWall};
	};

	const overlaps = (first, second) => first.x < second.x + second.width && first.x + first.width > second.x && first.y < second.y + second.height && first.y + first.height > second.y;

	// One frame of play: the kid, the enemies, the waffles, and the camera.
	const play = seconds => {
		const {player, level} = game;
		const left = buttons.has('left');
		const right = buttons.has('right');
		const isRunning = buttons.has('b');
		// Up jumps too, as it is what most visitors press first to jump.
		const isJumpDown = buttons.has('a') || buttons.has('up');
		const isJumpPressed = pressed.has('a') || pressed.has('up');
		const speed = isRunning ? 96 : 66;
		const target = (right ? speed : 0) - (left ? speed : 0);
		const acceleration = player.isOnGround ? 520 : 340;
		if (target === 0) {
			player.velocityX -= Math.sign(player.velocityX) * Math.min(Math.abs(player.velocityX), 600 * seconds);
		} else {
			player.velocityX += clamp(target - player.velocityX, -acceleration * seconds, acceleration * seconds);
			player.facing = Math.sign(target);
		}

		// The jump: a press is kept for a moment, and the kid can still jump a moment after running off an edge.
		if (isJumpPressed) {
			game.jumpBuffer = 0.12;
		}

		game.jumpBuffer = Math.max(0, game.jumpBuffer - seconds);
		player.coyote = player.isOnGround ? 0.09 : Math.max(0, player.coyote - seconds);
		if (game.jumpBuffer > 0 && player.coyote > 0) {
			player.velocityY = -215;
			player.isOnGround = false;
			player.coyote = 0;
			game.jumpBuffer = 0;
		}

		// Letting go of A ends the jump early, so a tap is a small hop.
		if (!isJumpDown && !isJumpPressed && player.velocityY < -70) {
			player.velocityY = -70;
		}

		player.velocityY = Math.min(player.velocityY + (620 * seconds), 240);
		// The umbrella floats the kid down while A is held.
		if (game.hasUmbrella && isJumpDown && player.velocityY > 38) {
			player.velocityY = 38;
		}

		const {isOnGround} = moveBox(player, 7, 12, seconds);
		player.isOnGround = isOnGround;
		player.x = clamp(player.x, 0, (level.plan.length * tile) - 8);
		player.walkTime = isOnGround && Math.abs(player.velocityX) > 5 ? player.walkTime + seconds : 0;
		player.hurtTime = Math.max(0, player.hurtTime - seconds);

		if (player.x > level.plan.checkpoint * tile && game.checkpointX < level.plan.checkpoint * tile) {
			game.checkpointX = level.plan.checkpoint * tile;
			handheld.say('Checkpoint! The lamp post remembers you.');
		}

		if (player.y > height) {
			hurt('water');
			if (game.mode === 'play') {
				Object.assign(player, newPlayer(game.checkpointX), {hurtTime: 1.2});
			}

			return;
		}

		const playerBox = {x: player.x, y: player.y, width: 7, height: 12};
		for (const item of level.items) {
			if (!item.isTaken && overlaps(playerBox, {x: item.x, y: item.y, width: 7, height: 7})) {
				item.isTaken = true;
				if (item.type === 'waffle') {
					game.waffles++;
					game.score += 10;
				} else if (item.type === 'brunost') {
					game.hearts = Math.min(game.hearts + 1, 5);
					game.score += 50;
					handheld.say('Brunost! One more heart.');
				} else {
					game.hasUmbrella = true;
					handheld.say('An umbrella! It keeps the rain off. Hold A in the air to float.');
				}
			}
		}

		for (const enemy of level.enemies) {
			if (!enemy.isAlive) {
				continue;
			}

			updateEnemy(enemy, seconds, player);
			if (enemy.type === 'cloud') {
				continue;
			}

			const enemyBox = enemy.type === 'lemming' ? {x: enemy.x, y: enemy.y, width: 8, height: 7} : {x: enemy.x, y: enemy.y + 1, width: 10, height: 5};
			if (!overlaps(playerBox, enemyBox)) {
				continue;
			}

			// A landing on top squashes it, and bounces the kid up, higher while A is held.
			if (player.velocityY > 20 && player.y + 12 - (player.velocityY * seconds) <= enemyBox.y + 3) {
				enemy.isAlive = false;
				player.velocityY = isJumpDown ? -200 : -130;
				game.score += 20;
			} else if (enemy.type === 'seagull' && game.waffles > 0 && player.hurtTime === 0) {
				// The seagulls of Bergen steal food, so a seagull takes waffles instead of a heart.
				const stolen = Math.min(5, game.waffles);
				game.waffles -= stolen;
				game.score = Math.max(0, game.score - (stolen * 10));
				player.hurtTime = 1.2;
				enemy.phase = 'escape';
				handheld.say(`A seagull stole ${plural(stolen, 'waffle')}! Typical Bergen.`);
			} else {
				hurt('enemy');
			}
		}

		for (const drop of level.drops) {
			drop.y += 110 * seconds;
			if (overlaps(playerBox, {x: drop.x, y: drop.y, width: 2, height: 4})) {
				drop.y = height + 10;
				if (game.hasUmbrella) {
					game.score += 1;
				} else {
					hurt('rain');
				}
			} else if (isSolid(level, Math.floor(drop.x / tile), Math.floor((drop.y + 4) / tile))) {
				drop.y = height + 10;
			}
		}

		level.drops = level.drops.filter(drop => drop.y < height);

		if (player.x >= level.plan.flag * tile) {
			game.score += 100;
			if (game.levelIndex === levelPlans.length - 1) {
				game.score += game.hearts * 50;
				game.mode = 'won';
				game.modeTime = 0;
				finishGame(true);
			} else {
				game.mode = 'clear';
				game.modeTime = 0;
				handheld.say(`Level ${game.levelIndex + 1} cleared! ${plural(game.waffles, 'waffle')} so far.`);
			}
		}

		game.cameraX = clamp(player.x - 64, 0, (level.plan.length * tile) - width);
	};

	const updateEnemy = (enemy, seconds, player) => {
		const {level} = game;
		if (enemy.type === 'lemming') {
			// Lemmings only move when they are near the screen, so they are where the level put them.
			if (Math.abs(enemy.x - player.x) > 120) {
				return;
			}

			enemy.velocityX = enemy.direction * 18;
			enemy.velocityY = Math.min((enemy.velocityY ?? 0) + (620 * seconds), 240);
			const {hitWall} = moveBox(enemy, 8, 7, seconds);
			const aheadColumn = Math.floor((enemy.x + (enemy.direction > 0 ? 8 : -1)) / tile);
			const belowRow = Math.floor((enemy.y + 8) / tile);
			if (hitWall || !isSolid(level, aheadColumn, belowRow)) {
				enemy.direction *= -1;
			}

			if (enemy.y > height) {
				enemy.isAlive = false;
			}
		} else if (enemy.type === 'seagull') {
			enemy.time += seconds;
			if (enemy.phase === 'patrol') {
				enemy.x = enemy.homeX + (Math.sin(enemy.time * 0.8) * 24);
				enemy.y = enemy.homeY + (Math.sin(enemy.time * 3) * 3);
				if (Math.abs(player.x - enemy.x) < 44 && player.y > enemy.y + 8) {
					enemy.phase = 'swoop';
					enemy.targetX = player.x;
					enemy.targetY = player.y + 2;
				}
			} else if (enemy.phase === 'swoop') {
				const distance = Math.hypot(enemy.targetX - enemy.x, enemy.targetY - enemy.y);
				if (distance < 3) {
					enemy.phase = 'return';
				} else {
					enemy.x += (enemy.targetX - enemy.x) / distance * 70 * seconds;
					enemy.y += (enemy.targetY - enemy.y) / distance * 70 * seconds;
				}
			} else if (enemy.phase === 'return') {
				enemy.y -= 40 * seconds;
				if (enemy.y <= enemy.homeY) {
					enemy.homeX = enemy.x;
					enemy.phase = 'patrol';
					enemy.time = 0;
				}
			} else {
				// A seagull that stole waffles flies off with them.
				enemy.y -= 60 * seconds;
				enemy.x += 50 * seconds;
				if (enemy.y < -20) {
					enemy.isAlive = false;
				}
			}
		} else {
			enemy.time += seconds;
			enemy.x = enemy.homeX + (Math.sin(enemy.time * 0.6) * 30);
			if (Math.abs(enemy.x + 8 - player.x) < 70 && enemy.time % 1.3 < seconds) {
				level.drops.push({x: enemy.x + randomInteger(3, 13), y: enemy.y + 8});
			}
		}
	};

	// The pictures, in big pixels: each is drawn with rectangles in a few bright colors, like the games of 1999.
	const rectangle = (color, x, y, rectangleWidth, rectangleHeight) => {
		context.fillStyle = color;
		context.fillRect(Math.round(x), Math.round(y), rectangleWidth, rectangleHeight);
	};

	const drawPlayer = (x, y, facing, walkTime, isFlashing) => {
		if (isFlashing) {
			return;
		}

		const flip = (offset, pieceWidth) => (facing > 0 ? x + offset : x + 7 - offset - pieceWidth);
		const propeller = handheld.reducedMotion || Math.floor(game.time * 12) % 2 === 0;
		rectangle('#333333', flip(propeller ? 0 : 2, propeller ? 7 : 3), y, propeller ? 7 : 3, 1);
		rectangle('#e83030', flip(1, 3), y + 1, 3, 2);
		rectangle('#f2d030', flip(4, 2), y + 1, 2, 2);
		rectangle('#3060d0', flip(5, 2), y + 2, 2, 1);
		rectangle('#f3c9a0', flip(1, 5), y + 3, 5, 3);
		rectangle('#222222', flip(4, 1), y + 4, 1, 1);
		rectangle('#1aa3b8', flip(1, 5), y + 6, 5, 3);
		rectangle('#f3c9a0', flip(game.hasUmbrella ? 6 : 5, 1), y + 7, 1, 1);
		const step = Math.floor(walkTime * 10) % 2;
		rectangle('#2a4aa0', flip(1, 2), y + 9, 2, step === 0 ? 3 : 2);
		rectangle('#2a4aa0', flip(4, 2), y + 9, 2, step === 1 ? 3 : 2);
		if (game.hasUmbrella) {
			rectangle('#555555', flip(6, 1), y - 1, 1, 8);
			rectangle('#e83030', flip(2, 9), y - 4, 9, 2);
			rectangle('#e83030', flip(3, 7), y - 5, 7, 1);
		}
	};

	const drawWaffle = (x, y) => {
		rectangle('#c88a2a', x, y, 6, 6);
		rectangle('#f2c060', x + 1, y + 1, 4, 4);
		rectangle('#c88a2a', x + 2, y + 1, 1, 4);
		rectangle('#c88a2a', x + 1, y + 3, 4, 1);
	};

	const drawFlag = (x, groundY) => {
		rectangle('#dddddd', x + 3, groundY - 48, 1, 48);
		rectangle('#ffd700', x + 2, groundY - 50, 3, 2);
		rectangle('#ba0c2f', x + 4, groundY - 47, 12, 8);
		rectangle('#ffffff', x + 7, groundY - 47, 3, 8);
		rectangle('#ffffff', x + 4, groundY - 44, 12, 2);
		rectangle('#00205b', x + 8, groundY - 47, 1, 8);
		rectangle('#00205b', x + 4, groundY - 44, 12, 1);
	};

	const drawBackground = plan => {
		const sky = context.createLinearGradient(0, 0, 0, height);
		sky.addColorStop(0, plan.sky[0]);
		sky.addColorStop(1, plan.sky[1]);
		context.fillStyle = sky;
		context.fillRect(0, 0, width, height);
		// The mountains far away move slowly, and the houses in between a little faster.
		const far = game.cameraX * 0.2;
		context.fillStyle = '#6a8a7a';
		context.beginPath();
		context.moveTo(0, 100);
		for (let x = 0; x <= width; x += 8) {
			context.lineTo(x, 70 + (Math.sin((x + far) / 37) * 12) + (Math.sin((x + far) / 13) * 4));
		}

		context.lineTo(width, height);
		context.lineTo(0, height);
		context.fill();
		const near = game.cameraX * 0.5;
		const houseColors = ['#b8312f', '#f2c14e', '#efe9df', '#d9792b'];
		for (let index = Math.floor(near / 24) - 1; index < Math.floor(near / 24) + 9; index++) {
			const x = (index * 24) - near;
			if (plan.houses) {
				const color = houseColors[((index % 4) + 4) % 4];
				rectangle(color, x, 84, 20, 30);
				context.fillStyle = color;
				context.beginPath();
				context.moveTo(x, 84);
				context.lineTo(x + 10, 72);
				context.lineTo(x + 20, 84);
				context.fill();
				rectangle('#3a3a4a', x + 4, 90, 3, 4);
				rectangle('#3a3a4a', x + 13, 90, 3, 4);
			} else if (plan.stalls) {
				rectangle(index % 2 === 0 ? '#d84040' : '#f4f4f4', x, 92, 22, 4);
				rectangle('#8a6a4a', x + 1, 96, 1, 18);
				rectangle('#8a6a4a', x + 20, 96, 1, 18);
				rectangle('#b8c8d8', x + 3, 104, 16, 3);
			} else if (plan.trees) {
				context.fillStyle = '#2d5a3a';
				context.beginPath();
				context.moveTo(x + 10, 70 + ((index % 3) * 6));
				context.lineTo(x + 18, 110);
				context.lineTo(x + 2, 110);
				context.fill();
			}
		}

		// The rain of Bergen, in the background. It stands still for visitors who prefer reduced motion.
		context.fillStyle = 'rgba(255, 255, 255, 0.35)';
		const offset = handheld.reducedMotion ? 0 : game.time * 90;
		for (let index = 0; index < 24; index++) {
			context.fillRect((index * 37) % width, ((index * 53) + offset) % height, 1, 4);
		}
	};

	const drawLevel = () => {
		const {level} = game;
		const {plan} = level;
		drawBackground(plan);
		const firstColumn = Math.floor(game.cameraX / tile);
		const [groundColor, darkColor, lightColor] = plan.groundColors;
		for (let column = firstColumn; column <= firstColumn + 21; column++) {
			for (let row = 0; row < rows; row++) {
				const letter = level.map[row]?.[column];
				const x = (column * tile) - game.cameraX;
				const y = row * tile;
				if (letter === '#') {
					rectangle(groundColor, x, y, tile, tile);
					if (level.map[row - 1]?.[column] !== '#') {
						rectangle(lightColor, x, y, tile, 2);
					}

					rectangle(darkColor, x + ((row * 3) % 6), y + 4, 2, 1);
				} else if (letter === '=') {
					rectangle('#b07a45', x, y, tile, 4);
					rectangle('#6b4220', x, y + 3, tile, 1);
					rectangle('#6b4220', x + 3, y, 1, 3);
				} else if (letter === 'B') {
					rectangle(plan.stalls ? '#4a7ab8' : '#a87a44', x, y, tile, tile);
					rectangle(plan.stalls ? '#2a4a78' : '#6b4a2a', x, y, tile, 1);
					rectangle(plan.stalls ? '#2a4a78' : '#6b4a2a', x, y + 7, tile, 1);
					rectangle(plan.stalls ? '#2a4a78' : '#6b4a2a', x + 3, y + 1, 2, 6);
				}
			}

			// The water of the harbor in the gaps.
			if (level.groundTop[column] === undefined) {
				const x = (column * tile) - game.cameraX;
				const wave = handheld.reducedMotion ? 0 : Math.round(Math.sin((game.time * 3) + column) * 1);
				rectangle('#2a5a9a', x, 130 + wave, tile, height - 130);
				rectangle('#8ac0f0', x + ((column * 3) % 5), 131 + wave, 3, 1);
			}
		}

		const checkpointX = (plan.checkpoint * tile) - game.cameraX;
		if (checkpointX > -10 && checkpointX < width + 10) {
			const groundY = (level.groundTop[plan.checkpoint] ?? 14) * tile;
			rectangle('#333333', checkpointX + 3, groundY - 24, 2, 24);
			rectangle(game.checkpointX >= plan.checkpoint * tile ? '#ffee55' : '#888888', checkpointX + 1, groundY - 28, 6, 4);
		}

		const flagX = (plan.flag * tile) - game.cameraX;
		if (flagX > -20 && flagX < width + 20) {
			drawFlag(flagX, (level.groundTop[plan.flag] ?? 14) * tile);
		}

		for (const item of level.items) {
			const x = item.x - game.cameraX;
			if (item.isTaken || x < -10 || x > width + 10) {
				continue;
			}

			const bob = handheld.reducedMotion ? 0 : Math.round(Math.sin((game.time * 4) + item.x) * 1);
			if (item.type === 'waffle') {
				drawWaffle(x, item.y + bob);
			} else if (item.type === 'brunost') {
				rectangle('#a0602a', x, item.y + bob, 7, 5);
				rectangle('#c88040', x, item.y + bob, 7, 2);
			} else {
				rectangle('#555555', x + 4, item.y + 1 + bob, 1, 7);
				rectangle('#e83030', x, item.y + bob, 9, 2);
				rectangle('#e83030', x + 1, item.y - 1 + bob, 7, 1);
			}
		}

		for (const enemy of level.enemies) {
			const x = enemy.x - game.cameraX;
			if (!enemy.isAlive || x < -20 || x > width + 20) {
				continue;
			}

			if (enemy.type === 'lemming') {
				const step = Math.floor(game.time * 6) % 2;
				rectangle('#7a4a20', x, enemy.y + 1, 8, 5);
				rectangle('#f0d8b0', x + (enemy.direction > 0 ? 5 : 0), enemy.y + 2, 3, 3);
				rectangle('#111111', x + (enemy.direction > 0 ? 6 : 1), enemy.y + 2, 1, 1);
				rectangle('#3a2010', x + 1 + step, enemy.y + 6, 2, 1);
				rectangle('#3a2010', x + 5 - step, enemy.y + 6, 2, 1);
			} else if (enemy.type === 'seagull') {
				const flap = Math.floor(game.time * 8) % 2;
				rectangle('#ffffff', x + 2, enemy.y + 2, 7, 3);
				rectangle('#9aa0a8', x, enemy.y + (flap ? 0 : 3), 4, 2);
				rectangle('#9aa0a8', x + 6, enemy.y + (flap ? 0 : 3), 4, 2);
				rectangle('#ffcc00', x + 9, enemy.y + 3, 2, 1);
				rectangle('#111111', x + 8, enemy.y + 2, 1, 1);
			} else {
				rectangle('#7a8290', x, enemy.y + 2, 18, 6);
				rectangle('#9aa2b0', x + 3, enemy.y, 8, 4);
				rectangle('#9aa2b0', x + 9, enemy.y + 1, 6, 3);
			}
		}

		for (const drop of level.drops) {
			rectangle('#5aa0ff', drop.x - game.cameraX, drop.y, 2, 4);
		}

		const {player} = game;
		// The kid flashes after a hurt, but never on a frame that stands still, like the pause, where it would be gone.
		drawPlayer(player.x - game.cameraX, player.y, player.facing, player.walkTime, game.mode === 'play' && player.hurtTime > 0 && Math.floor(player.hurtTime * 12) % 2 === 0);

		// The status line: hearts, waffles, and the level.
		rectangle('rgba(0, 0, 0, 0.45)', 0, 0, width, 9);
		for (let index = 0; index < game.hearts; index++) {
			drawPixelText(context, '♥', 2 + (index * 5), 2, '#ff4466');
		}

		drawWaffle(56, 1);
		drawPixelText(context, `×${game.waffles}`, 64, 2, '#ffffff');
		drawPixelText(context, `${game.levelIndex + 1}-${plan.name}`, width - 2, 2, '#ffffff', {align: 'right'});
	};

	// The screen when the power is on: the logo, which scrolls down, the title, the levels, and the ends.
	const drawScreen = () => {
		if (!game.isOn) {
			rectangle('#1a1a10', 0, 0, width, height);
			return;
		}

		if (game.mode === 'boot') {
			rectangle('#f4f4f4', 0, 0, width, height);
			const logoY = handheld.reducedMotion ? 64 : Math.min(64, -10 + (game.modeTime * 55));
			if (game.isGarbled) {
				// A dirty cartridge: the logo comes down as blocks, and the game console stops.
				for (let index = 0; index < 40; index++) {
					rectangle('#202020', 30 + ((index * 37) % 100), logoY - 4 + ((index * 13) % 12), 4 + (index % 3) * 2, 3);
				}
			} else {
				drawPixelText(context, 'SINDRE', 80, logoY, '#2a2aa0', {align: 'center', scale: 2});
			}

			return;
		}

		if (game.mode === 'title') {
			drawBackground(levelPlans[0]);
			drawPixelText(context, 'SUPER', 80, 22, '#e83030', {align: 'center', scale: 2});
			drawPixelText(context, 'SINDRE LAND', 80, 36, '#ffffff', {align: 'center', scale: 2});
			drawPixelText(context, 'BERGEN 1999', 80, 52, '#2a2aa0', {align: 'center'});
			drawPlayer(76, 96, 1, handheld.reducedMotion ? 0 : game.time, false);
			if (handheld.reducedMotion || Math.floor(game.time * 2) % 2 === 0) {
				drawPixelText(context, 'PRESS START', 80, 118, '#ffffff', {align: 'center'});
			}

			drawPixelText(context, `BEST ${game.best}`, 80, 132, '#ffee55', {align: 'center'});
			return;
		}

		drawLevel();
		if (game.mode === 'intro') {
			rectangle('rgba(0, 0, 0, 0.6)', 20, 50, 120, 34);
			drawPixelText(context, `LEVEL ${game.levelIndex + 1}`, 80, 56, '#ffee55', {align: 'center', scale: 2});
			drawPixelText(context, levelPlans[game.levelIndex].name, 80, 72, '#ffffff', {align: 'center'});
		} else if (game.mode === 'paused') {
			rectangle('rgba(0, 0, 0, 0.6)', 30, 56, 100, 24);
			drawPixelText(context, 'PAUSED', 80, 64, '#ffffff', {align: 'center', scale: 2});
		} else if (game.mode === 'clear') {
			rectangle('rgba(0, 0, 0, 0.6)', 16, 50, 128, 34);
			drawPixelText(context, 'HIPP HIPP HURRA!', 80, 56, '#ffee55', {align: 'center'});
			drawPixelText(context, `SCORE ${game.score}`, 80, 70, '#ffffff', {align: 'center'});
		} else if (game.mode === 'over' || game.mode === 'won') {
			rectangle('rgba(0, 0, 0, 0.7)', 10, 40, 140, 60);
			drawPixelText(context, game.mode === 'won' ? 'TOP OF FLØYEN!' : 'GAME OVER', 80, 48, game.mode === 'won' ? '#ffee55' : '#ff4466', {align: 'center', scale: 2});
			drawPixelText(context, `SCORE ${game.score}`, 80, 70, '#ffffff', {align: 'center'});
			drawPixelText(context, `BEST ${game.best}`, 80, 80, '#ffee55', {align: 'center'});
			drawPixelText(context, 'PRESS START', 80, 90, '#ffffff', {align: 'center'});
		}
	};

	const step = seconds => {
		game.time += seconds;
		game.modeTime += seconds;
		const startPressed = pressed.has('start');

		if (game.mode === 'boot') {
			if (!game.isGarbled && game.modeTime > (handheld.reducedMotion ? 1 : 2.2)) {
				game.mode = 'title';
				game.modeTime = 0;
				handheld.say('Super Sindre Land! Press Start.');
			}
		} else if (game.mode === 'over') {
			if (startPressed) {
				continueGame();
			}
		} else if (game.mode === 'title' || game.mode === 'won') {
			if (startPressed) {
				startGame();
			}
		} else if (game.mode === 'intro') {
			if (game.modeTime > 1.6 || startPressed) {
				game.mode = 'play';
			}
		} else if (game.mode === 'clear') {
			if (game.modeTime > 2.2) {
				startLevel(game.levelIndex + 1);
			}
		} else if (game.mode === 'paused') {
			if (startPressed) {
				game.mode = 'play';
				handheld.say('Go!');
			}
		} else if (game.mode === 'play') {
			if (startPressed) {
				game.mode = 'paused';
				handheld.say('Paused. Press Start to go on.');
			} else if (!handheld.reducedMotion || buttons.size > 0 || pressed.size > 0) {
				// With reduced motion, time only goes on while the visitor holds a button, so nothing moves by itself. A long frame, on a slow device, is played in short steps, so the kid never moves through a crate or a platform in one step.
				for (let left = seconds; left > 0 && game.mode === 'play'; left -= 1 / 60) {
					play(Math.min(left, 1 / 60));
				}
			}
		}

		pressed.clear();
		drawScreen();
	};

	const loop = handheld.loop(step, {while: () => game.isOn && !game.isGarbled});

	// The black blocks of a cartridge that does not start come down for a moment.
	let fallTime = 0;
	const fall = () => {
		fallTime += 1 / 60;
		game.modeTime = fallTime;
		drawScreen();
	};

	const fallLoop = handheld.loop(fall, {while: () => fallTime < 1.3 && game.isOn && game.isGarbled && !handheld.reducedMotion});

	const turnOn = () => {
		game.isOn = true;
		game.mode = 'boot';
		game.modeTime = 0;
		// A cartridge that was not blown on does not always start, and the first time it never does, as it has been in a drawer since Christmas.
		game.isGarbled = !game.isCartridgeClean && (game.bootTime === 0 || Math.random() < 0.3);
		game.bootTime++;
		game.isCartridgeClean = false;
		power.dataset.state = 'on';
		power.setAttribute('aria-pressed', 'true');
		led.dataset.state = 'on';
		if (game.isGarbled) {
			handheld.say('The logo comes out as black blocks, and the game freezes. Blow on the cartridge!');
			// The blocks still come down, but nothing happens after.
			fallTime = 0;
			fall();
			fallLoop.start();
		} else {
			handheld.say('Bling! It starts.');
			loop.start();
		}

		drawScreen();
	};

	const turnOff = () => {
		game.isOn = false;
		game.mode = 'off';
		power.dataset.state = '';
		power.setAttribute('aria-pressed', 'false');
		led.dataset.state = '';
		handheld.say('It is off.');
		drawScreen();
	};

	handheld.on(power, 'click', () => {
		if (game.isOn) {
			turnOff();
		} else {
			turnOn();
		}
	});

	handheld.on(blow, 'click', () => {
		if (game.isOn && game.isGarbled) {
			game.isCartridgeClean = true;
			handheld.say('Fffffff! You blow the dust out of the cartridge. Turn it off and on again.');
		} else if (game.isOn && game.mode === 'play') {
			game.isGarbled = true;
			game.mode = 'boot';
			game.modeTime = 1.3;
			handheld.say('Fffff! You blew on it while it was on. The game froze! Turn it off and on again.');
			drawScreen();
		} else {
			game.isCartridgeClean = true;
			handheld.say('Fffffff! Clean as new. Everybody knew this works. (It does not. But it does.)');
		}
	});

	// The buttons are held down by the pointer, like real buttons, so a finger can hold Right and A at the same time.
	for (const button of handheld.querySelectorAll('[data-handheld-button]')) {
		const name = button.dataset.handheldButton;
		const release = () => {
			buttons.delete(name);
		};

		handheld.on(button, 'pointerdown', event => {
			event.preventDefault();
			button.setPointerCapture(event.pointerId);
			press(name);
			if (name === 'start' && !game.isOn) {
				handheld.say('Turn it on first! The switch is at the top.');
			}

			loop.start();
		});
		handheld.on(button, 'pointerup', release);
		handheld.on(button, 'pointercancel', release);
		handheld.on(button, 'lostpointercapture', release);
		// A click from a keyboard or a screen reader presses the button for a moment.
		handheld.on(button, 'click', event => {
			if (event.detail === 0) {
				if (name === 'start' && !game.isOn) {
					handheld.say('Turn it on first! The switch is at the top.');
				}

				press(name);
				handheld.timeout(150, release);
				loop.start();
			}
		});
	}

	const keyButtons = {ArrowLeft: 'left', ArrowRight: 'right', ArrowUp: 'up', ArrowDown: 'down', x: 'a', X: 'a', ' ': 'a', z: 'b', Z: 'b', Shift: 'b', Enter: 'start', Backspace: 'select'};

	handheld.on(screen, 'keydown', event => {
		const name = keyButtons[event.key];
		if (!name || event.metaKey || event.ctrlKey || event.altKey) {
			return;
		}

		event.preventDefault();
		if (!game.isOn && name === 'start') {
			turnOn();
			return;
		}

		if (!event.repeat) {
			press(name);
		}

		loop.start();
	});

	handheld.on(screen, 'keyup', event => {
		const name = keyButtons[event.key];
		if (name) {
			buttons.delete(name);
		}
	});

	handheld.on(screen, 'blur', () => {
		buttons.clear();
	});

	drawScreen();

	// The game pauses by itself when the game console scrolls away or the tab is hidden.
	return {
		visibilityChanged(isVisible) {
			if (!isVisible && game.mode === 'play') {
				game.mode = 'paused';
				drawScreen();
			}
		},
	};
};

export default class extends GeoCitiesElement {
	#handheld;

	connected() {
		this.#handheld = setUp(this, this.parts);
	}

	// The game only runs while the screen is on the screen.
	get visibilityTarget() {
		return this.parts.screen;
	}

	visibilityChanged(isVisible) {
		this.#handheld.visibilityChanged(isVisible);
	}
}
