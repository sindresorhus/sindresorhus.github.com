// Lemmingz ’99 on the 1999 page: a screen of 256 × 144 pixels of dirt, steel, and bricks, drawn twice as large, and lemmings of 3 × 10 pixels, which take 15 steps a second, like the Lemmings of 1991. A lemming walks up steps of up to 6 pixels and turns at higher walls, and a fall of more than 56 pixels kills it, unless it has an umbrella.

const randomItem = items => items[Math.floor(Math.random() * items.length)];
const randomBetween = (minimum, maximum) => minimum + (Math.random() * (maximum - minimum));
const clamp = (value, minimum, maximum) => Math.min(Math.max(value, minimum), maximum);

export default class extends GeoCitiesElement {
	// The lemmings only walk while their canvas is on the screen, not while only the buttons below it are.
	get visibilityTarget() {
		return this.parts.screen;
	}

	connected() {
		const {screen: lemmingsCanvas, title, pause: pauseButton, next: nextButton, level: levelSelect, step: stepButton, restart, nuke} = this.parts;
		const skillButtons = [...this.querySelectorAll('[data-lemmings-skill]')];
		const width = 256;
		const height = 144;
		const air = 0;
		const dirt = 1;
		const steel = 2;
		const brick = 3;
		const ticksPerSecond = 15;
		const deadlyFall = 56;
		const skillNames = {dig: 'Dig', build: 'Build', bash: 'Bash', block: 'Block', float: 'Float', bomb: 'Bomb'};
		const scene = document.createElement('canvas');
		scene.width = width;
		scene.height = height;
		const sceneContext = scene.getContext('2d');
		const terrainCanvas = document.createElement('canvas');
		terrainCanvas.width = width;
		terrainCanvas.height = height;
		const terrainContext = terrainCanvas.getContext('2d');
		const context = lemmingsCanvas.getContext('2d');
		const progress = this.stored('progress', {});

		// The ground, as one number for each pixel, and its colors.
		const terrain = new Uint8Array(width * height);
		const pixels = new ImageData(width, height);
		let isTerrainChanged = true;

		const hexColor = hex => [Number.parseInt(hex.slice(1, 3), 16), Number.parseInt(hex.slice(3, 5), 16), Number.parseInt(hex.slice(5, 7), 16)];

		const setPixel = (x, y, kind, color) => {
			if (x < 0 || x >= width || y < 0 || y >= height) {
				return;
			}

			const index = (y * width) + x;
			terrain[index] = kind;
			const [red, green, blue] = kind === air ? [0, 0, 0] : hexColor(color);
			pixels.data.set([red, green, blue, kind === air ? 0 : 255], index * 4);
			isTerrainChanged = true;
		};

		const kindAt = (x, y) => {
			if (x < 0 || x >= width) {
				return steel;
			}

			if (y < 0 || y >= height) {
				return air;
			}

			return terrain[(y * width) + x];
		};

		const isSolid = (x, y) => kindAt(x, y) !== air;

		// Digging, bashing, and bombs take away dirt and bricks, but not steel.
		const removeAt = (x, y) => {
			const kind = kindAt(x, y);

			if (kind === dirt || kind === brick) {
				setPixel(x, y, air);
				return true;
			}

			return false;
		};

		const painter = {
			// Dirt, with grass on top.
			dirt(left, top, rectWidth, rectHeight) {
				const colors = ['#8b5a2b', '#7a4a20', '#9b6a3b', '#86552a'];

				for (let y = top; y < top + rectHeight; y++) {
					for (let x = left; x < left + rectWidth; x++) {
						setPixel(x, y, dirt, y === top ? '#3cb043' : colors[((x * 7) + (y * 13) + ((x * y) % 5)) % colors.length]);
					}
				}
			},
			steel(left, top, rectWidth, rectHeight) {
				for (let y = top; y < top + rectHeight; y++) {
					for (let x = left; x < left + rectWidth; x++) {
						const isRivet = (x - left) % 6 === 2 && (y - top) % 6 === 2;
						setPixel(x, y, steel, isRivet ? '#f0f0ff' : ((x - left) % 6 === 0 || (y - top) % 6 === 0 ? '#707088' : '#a8a8bc'));
					}
				}
			},
			// The wall of the last level, in the colors of 88×31 buttons.
			buttons(left, top, rectWidth, rectHeight) {
				const colors = ['#cc0000', '#0033cc', '#ffcc00', '#009933', '#9900cc', '#ff6600', '#00cccc', '#ff3399'];

				for (let y = top; y < top + rectHeight; y++) {
					for (let x = left; x < left + rectWidth; x++) {
						const button = Math.floor((x - left) / 11) + (Math.floor((y - top) / 6) * 3);
						const isEdge = (x - left) % 11 === 0 || (y - top) % 6 === 0;
						setPixel(x, y, dirt, isEdge ? '#222222' : colors[button % colors.length]);
					}
				}
			},
		};

		const levels = [
			{
				name: 'Just dig!',
				hint: 'The lemmings are stuck on the big block. Give one of them the Dig job, away from the trapdoor, and the others follow it down the hole.',
				count: 10,
				need: 8,
				rate: 30,
				skills: {dig: 2, build: 0, bash: 0, block: 0, float: 0, bomb: 0},
				hatch: {x: 70, y: 22},
				exit: {x: 200, y: 111},
				paint() {
					painter.dirt(30, 62, 196, 30);
					// A steel plate under the trapdoor, where a digger only goes CLANG. A hole there would drop the new lemmings from the trapdoor all the way to the floor, which kills them.
					painter.steel(56, 62, 30, 6);
					painter.steel(30, 38, 6, 24);
					painter.steel(220, 38, 6, 24);
					painter.dirt(0, 112, 256, 32);
				},
			},
			{
				name: 'Mind the gap',
				hint: 'Build a bridge over the water. One builder lays 12 bricks, which is not enough, so give the Build job again when it shrugs.',
				count: 10,
				need: 7,
				rate: 45,
				skills: {dig: 0, build: 3, bash: 0, block: 0, float: 0, bomb: 0},
				hatch: {x: 30, y: 40},
				exit: {x: 222, y: 83},
				water: 130,
				paint() {
					painter.dirt(0, 84, 96, 60);
					painter.dirt(128, 84, 128, 60);
				},
			},
			{
				name: 'Umbrellas, please',
				hint: 'Give each lemming an umbrella before it lands at the bottom. Then bash through the wall down there.',
				count: 10,
				need: 6,
				rate: 45,
				// The umbrellas come first, so Float is the job that is picked at the start.
				skills: {float: 10, bash: 2, bomb: 1, dig: 0, build: 0, block: 0},
				hatch: {x: 40, y: 8},
				exit: {x: 232, y: 133},
				paint() {
					painter.steel(0, 0, 6, 46);
					painter.dirt(6, 34, 94, 12);
					painter.dirt(0, 134, 256, 10);
					painter.dirt(160, 98, 14, 36);
				},
			},
			{
				name: 'The wall of 88×31',
				hint: 'Bash through the wall of 88×31 buttons, and build over the water. A blocker holds the others back while you work, and a bomb gets rid of the blocker.',
				count: 12,
				need: 9,
				rate: 30,
				// No Dig: a hole in the ground near the trapdoor would drop every lemming off the bottom of the screen.
				skills: {bash: 1, block: 1, build: 2, bomb: 1, float: 1, dig: 0},
				hatch: {x: 30, y: 70},
				exit: {x: 234, y: 111},
				water: 132,
				paint() {
					painter.dirt(0, 112, 168, 32);
					painter.dirt(200, 112, 56, 32);
					painter.buttons(96, 56, 44, 56);
					painter.steel(96, 50, 44, 6);
				},
			},
		];

		const game = {level: 0, lemmings: [], particles: [], released: 0, saved: 0, tick: 0, lastRelease: 0, skills: {}, skill: 'dig', isPaused: false, isOver: false, isNuked: false, hover: undefined, selected: undefined};
		const isAlive = lemming => !['dead', 'saved'].includes(lemming.state);
		const canAct = lemming => isAlive(lemming) && !['exit', 'splat', 'drown'].includes(lemming.state);

		const showSkills = () => {
			for (const button of skillButtons) {
				const skill = button.dataset.lemmingsSkill;
				const isPicked = skill === game.skill;
				this.querySelector(`[data-lemmings-count="${skill}"]`).textContent = String(game.skills[skill]);
				button.setAttribute('aria-pressed', String(isPicked));

				if (isPicked) {
					button.dataset.state = 'on';
				} else {
					delete button.dataset.state;
				}

				button.disabled = game.skills[skill] === 0 && !isPicked;
			}
		};

		const showLevels = () => {
			levelSelect.replaceChildren(...levels.slice(0, progress.reached + 1).map((level, index) => {
				const option = document.createElement('option');
				option.value = String(index);
				option.textContent = `${index + 1}. ${level.name}`;
				return option;
			}));
			levelSelect.value = String(game.level);
		};

		const startLevel = index => {
			const level = levels[index];
			game.level = index;
			game.lemmings = [];
			game.particles = [];
			game.released = 0;
			game.saved = 0;
			game.tick = 0;
			game.lastRelease = 0;
			game.skills = {...level.skills};
			// The first job in the skills of the level, which is the one the level needs first.
			game.skill = Object.keys(level.skills).find(skill => level.skills[skill] > 0);
			game.isOver = false;
			game.isNuked = false;
			game.selected = undefined;
			game.hover = undefined;
			terrain.fill(air);
			pixels.data.fill(0);
			level.paint();
			isTerrainChanged = true;
			nextButton.hidden = true;
			progress.current = index;
			this.store('progress', progress);
			title.textContent = `LEMMINGZ.EXE: Level ${index + 1}, ${level.name}`;
			showSkills();
			showLevels();
			this.say(`Level ${index + 1}, “${level.name}”: save ${level.need} of ${level.count}. ${level.hint}${this.reducedMotion ? ' Your computer prefers less motion, so the lemmings only move when you press Step.' : ''}`);
			draw();
		};

		// MARK: The jobs

		const say = (lemming, text) => {
			game.particles.push({x: lemming.x, y: lemming.y - 14, text, life: 20, velocityX: 0, velocityY: -0.3});
		};

		const blockerAhead = lemming => game.lemmings.some(other => other !== lemming && other.state === 'block' && Math.sign(other.x - lemming.x) === lemming.direction && Math.abs(other.x - lemming.x) <= 4 && Math.abs(other.y - lemming.y) <= 8);

		// A job that did nothing at all, like digging on steel or bashing thin air, is given back, so a first wrong try does not lose the level.
		const giveBack = (lemming, skill, message) => {
			if (lemming.hasWorked) {
				return;
			}

			game.skills[skill]++;
			showSkills();
			this.say(message);
		};

		const startFalling = lemming => {
			lemming.state = 'fall';
			lemming.fall = 0;
		};

		const walk = lemming => {
			if (blockerAhead(lemming)) {
				lemming.direction = -lemming.direction;
				return;
			}

			const nextX = lemming.x + lemming.direction;

			if (isSolid(nextX, lemming.y)) {
				let climb = 1;

				while (climb <= 6 && isSolid(nextX, lemming.y - climb)) {
					climb++;
				}

				// A wall: it turns around.
				if (climb > 6) {
					lemming.direction = -lemming.direction;
					return;
				}

				lemming.x = nextX;
				lemming.y -= climb;
				return;
			}

			lemming.x = nextX;
			let drop = 0;

			while (drop < 4 && !isSolid(lemming.x, lemming.y + 1 + drop)) {
				drop++;
			}

			if (drop >= 4) {
				lemming.y++;
				startFalling(lemming);
			} else {
				lemming.y += drop;
			}
		};

		const fall = lemming => {
			const hasUmbrella = lemming.isFloater && lemming.fall > 14;
			const speed = hasUmbrella ? 1 : 3;

			for (let step = 0; step < speed; step++) {
				if (isSolid(lemming.x, lemming.y + 1)) {
					if (lemming.fall > deadlyFall && !lemming.isFloater) {
						lemming.state = 'splat';
						lemming.timer = 12;
						say(lemming, 'SPLAT');
					} else {
						lemming.state = 'walk';
					}

					return;
				}

				lemming.y++;
				lemming.fall++;
			}
		};

		const dig = lemming => {
			if (game.tick % 2 !== 0) {
				return;
			}

			if (!isSolid(lemming.x, lemming.y + 1)) {
				startFalling(lemming);
				return;
			}

			const row = lemming.y + 1;

			for (let x = lemming.x - 3; x <= lemming.x + 3; x++) {
				if (kindAt(x, row) === steel) {
					lemming.state = 'shrug';
					lemming.timer = 10;
					say(lemming, 'CLANG');
					giveBack(lemming, 'dig', 'CLANG! That is steel, and nobody can dig through steel. You got the Dig job back. Try a lemming away from the steel.');
					return;
				}
			}

			for (let x = lemming.x - 3; x <= lemming.x + 3; x++) {
				removeAt(x, row);
			}

			lemming.hasWorked = true;
			lemming.y++;
		};

		const build = lemming => {
			if (game.tick % 4 !== 0) {
				return;
			}

			const {x, y, direction} = lemming;

			for (let index = 0; index < 6; index++) {
				if (!isSolid(x + (direction * index), y)) {
					setPixel(x + (direction * index), y, brick, index % 2 === 0 ? '#e8b060' : '#d09848');
				}
			}

			lemming.bricks--;

			// It bumps its head on a ceiling or a wall, and turns around.
			if (isSolid(x + (direction * 2), y - 1) || isSolid(x + (direction * 2), y - 9)) {
				lemming.direction = -direction;
				lemming.state = 'walk';
				return;
			}

			lemming.x += direction * 2;
			lemming.y--;

			if (lemming.bricks === 3) {
				say(lemming, '...');
			}

			if (lemming.bricks <= 0) {
				lemming.state = 'shrug';
				lemming.timer = 12;
			}
		};

		const bash = lemming => {
			if (game.tick % 2 !== 0) {
				return;
			}

			const {direction} = lemming;
			const frontX = lemming.x + (direction * 3);
			const nearX = lemming.x + direction;

			if (!isSolid(lemming.x, lemming.y + 1)) {
				startFalling(lemming);
				return;
			}

			const nothingToBash = 'That lemming found no wall to bash, so you got the Bash job back. Give it to a lemming that walks toward a wall.';

			if (frontX + direction < 0 || frontX + direction >= width) {
				lemming.state = 'walk';
				giveBack(lemming, 'bash', nothingToBash);
				return;
			}

			for (let rise = 0; rise <= 9; rise++) {
				if ([nearX, nearX + direction, frontX, frontX + direction].some(x => kindAt(x, lemming.y - rise) === steel)) {
					lemming.state = 'walk';
					lemming.direction = -direction;
					say(lemming, 'CLANG');
					giveBack(lemming, 'bash', 'CLANG! That is steel, and nobody can bash through steel. You got the Bash job back.');
					return;
				}
			}

			// The tunnel starts right in front of it, so no thin wall stays behind.
			for (let rise = 0; rise <= 9; rise++) {
				for (const x of [nearX, nearX + direction, frontX, frontX + direction]) {
					if (removeAt(x, lemming.y - rise)) {
						lemming.hasWorked = true;
					}
				}
			}

			lemming.x += direction;

			// It stops when there is nothing more to bash in front of it.
			let hasMore = false;

			for (let distance = 3; distance <= 10 && !hasMore; distance++) {
				for (let rise = 1; rise <= 8; rise++) {
					const x = lemming.x + (direction * distance);

					if (x >= 0 && x < width && isSolid(x, lemming.y - rise)) {
						hasMore = true;
						break;
					}
				}
			}

			// Before it reaches a wall, it walks on toward one for a few steps, so the visitor does not have to give the job at the exact moment.
			if (!hasMore && !lemming.hasWorked && lemming.steps < 30) {
				lemming.steps++;

				// A blocker turns it around, like any walker.
				if (blockerAhead(lemming)) {
					lemming.direction = -direction;
				}

				return;
			}

			if (!hasMore) {
				lemming.state = 'walk';
				giveBack(lemming, 'bash', nothingToBash);
			}
		};

		const explode = lemming => {
			for (let dy = -9; dy <= 9; dy++) {
				for (let dx = -9; dx <= 9; dx++) {
					if ((dx * dx) + (dy * dy) <= 81) {
						removeAt(lemming.x + dx, lemming.y - 4 + dy);
					}
				}
			}

			for (let index = 0; index < 18; index++) {
				game.particles.push({x: lemming.x, y: lemming.y - 4, velocityX: randomBetween(-2, 2), velocityY: randomBetween(-3, 0.5), color: randomItem(['#ff3333', '#ffcc00', '#22dd22', '#3355ff', '#ffffff']), life: randomBetween(15, 30)});
			}

			lemming.state = 'dead';
		};

		const updateLemming = lemming => {
			if (lemming.bombTimer !== undefined && canAct(lemming)) {
				lemming.bombTimer--;

				if (lemming.bombTimer === 20) {
					say(lemming, 'Oh no!');
				}

				if (lemming.bombTimer <= 0) {
					explode(lemming);
					return;
				}
			}

			switch (lemming.state) {
				case 'fall': {
					fall(lemming);
					break;
				}

				case 'walk': {
					walk(lemming);
					break;
				}

				case 'dig': {
					dig(lemming);
					break;
				}

				case 'build': {
					build(lemming);
					break;
				}

				case 'bash': {
					bash(lemming);
					break;
				}

				// A blocker falls when the ground under it is gone, like after a bomb.
				case 'block': {
					if (!isSolid(lemming.x, lemming.y + 1)) {
						startFalling(lemming);
					}

					break;
				}

				case 'shrug':
				case 'splat':
				case 'drown':
				case 'exit': {
					lemming.timer--;

					if (lemming.timer <= 0) {
						if (lemming.state === 'exit') {
							lemming.state = 'saved';
							game.saved++;
						} else if (lemming.state === 'shrug') {
							lemming.state = 'walk';
						} else {
							lemming.state = 'dead';
						}
					}

					break;
				}

				default: {
					break;
				}
			}

			const level = levels[game.level];

			if (['walk', 'fall', 'dig', 'build', 'bash', 'shrug'].includes(lemming.state) && Math.abs(lemming.x - level.exit.x) <= 3 && Math.abs(lemming.y - level.exit.y) <= 5) {
				lemming.state = 'exit';
				lemming.timer = 8;
				lemming.bombTimer = undefined;
			} else if (level.water && lemming.y >= level.water && canAct(lemming)) {
				lemming.state = 'drown';
				lemming.timer = 12;
				say(lemming, 'glug');
			} else if (lemming.y >= height + 4 && isAlive(lemming)) {
				lemming.state = 'dead';
			}
		};

		const endLevel = () => {
			game.isOver = true;
			const level = levels[game.level];
			const isWon = game.saved >= level.need;

			if (!isWon) {
				this.say(`Oh no! You saved ${game.saved} of ${level.count}, and you needed ${level.need}. Press Restart level and try again.`);
				return;
			}

			progress.reached = Math.max(progress.reached, Math.min(game.level + 1, levels.length - 1));
			this.store('progress', progress);
			showLevels();

			if (game.level === levels.length - 1) {
				this.say(`You saved ${game.saved} of ${level.count}! You beat all the levels of Lemmingz ’99. The lemmings of my page thank you!`);
				this.celebrate();
				return;
			}

			nextButton.hidden = false;
			this.say(`Yes! You saved ${game.saved} of ${level.count}, and you needed ${level.need}. On to the next level!`);
		};

		const tick = () => {
			if (game.isOver) {
				return;
			}

			game.tick++;
			const level = levels[game.level];

			// The trapdoor opens, and the lemmings drop out one at a time.
			if (!game.isNuked && game.tick > 20 && game.released < level.count && game.tick - game.lastRelease >= level.rate) {
				game.lemmings.push({x: level.hatch.x, y: level.hatch.y, direction: 1, state: 'fall', fall: 0, bricks: 0, timer: 0, isFloater: false, bombTimer: undefined});
				game.released++;
				game.lastRelease = game.tick;
			}

			for (const lemming of game.lemmings) {
				updateLemming(lemming);
			}

			for (const particle of game.particles) {
				particle.x += particle.velocityX;
				particle.y += particle.velocityY;

				if (!particle.text) {
					particle.velocityY += 0.2;
				}

				particle.life--;
			}

			game.particles = game.particles.filter(particle => particle.life > 0);

			if (game.selected && !canAct(game.selected)) {
				game.selected = undefined;
			}

			const isDone = (game.released === level.count || game.isNuked) && game.lemmings.every(lemming => !isAlive(lemming));

			if (isDone && game.particles.length === 0) {
				endLevel();
			}
		};

		// MARK: Drawing

		const drawLemming = lemming => {
			const {x, y, direction, state} = lemming;
			const front = direction > 0 ? 1 : -1;
			const step = Math.floor(game.tick / 2) % 2;
			const fill = (color, left, top, rectWidth, rectHeight) => {
				sceneContext.fillStyle = color;
				sceneContext.fillRect(left, top, rectWidth, rectHeight);
			};

			if (state === 'splat') {
				fill('#22dd22', x - 2, y - 1, 5, 1);
				fill('#3355ff', x - 3, y, 7, 1);
				return;
			}

			if (state === 'drown') {
				fill('#22dd22', x - 1, y - 2 - Math.floor(lemming.timer / 3), 3, 2);
				return;
			}

			const top = state === 'exit' ? y - 9 + Math.floor((8 - lemming.timer) / 2) : y - 9;
			const bob = state === 'dig' ? step : 0;
			fill('#22dd22', x - 1 + (front > 0 ? 0 : 1), top + bob, 2, 2);
			fill('#22dd22', x - 1 - front, top + 1 + bob, 1, 1);
			fill('#ffccaa', x - 1, top + 2 + bob, 3, 2);
			fill('#3355ff', x - 1, top + 4 + bob, 3, 3);

			if (state === 'exit') {
				return;
			}

			if (state === 'block') {
				fill('#ffccaa', x - 3, y - 5, 2, 1);
				fill('#ffccaa', x + 2, y - 5, 2, 1);
			} else if (state === 'build') {
				fill('#e8b060', x + (front * 2), y - 4, 2, 1);
			} else if (state === 'bash') {
				fill('#ffccaa', x + (front * (2 + step)), y - 5, 1, 1);
			} else if (state === 'shrug') {
				fill('#ffccaa', x - 3, y - 7, 1, 1);
				fill('#ffccaa', x + 3, y - 7, 1, 1);
			}

			// The legs walk, and stand still for the jobs.
			if (state === 'walk' && step === 1) {
				fill('#3355ff', x - 1, y - 2, 1, 2);
				fill('#3355ff', x + 1, y - 2, 1, 2);
			} else {
				fill('#3355ff', x, y - 2, 1, 2);
				fill('#3355ff', x - 1, y - 1, 3, 1);
			}

			if (lemming.isFloater && state === 'fall' && lemming.fall > 14) {
				fill('#ff3333', x - 3, top - 4, 7, 1);
				fill('#ffffff', x - 2, top - 5, 5, 1);
				fill('#ff3333', x - 1, top - 6, 3, 1);
				fill('#ffffff', x, top - 3, 1, 3);
			}
		};

		const draw = () => {
			const level = levels[game.level];

			if (isTerrainChanged) {
				terrainContext.putImageData(pixels, 0, 0);
				isTerrainChanged = false;
			}

			sceneContext.fillStyle = '#000010';
			sceneContext.fillRect(0, 0, width, height);
			sceneContext.drawImage(terrainCanvas, 0, 0);

			// The trapdoor, which opens at the start.
			const {hatch, exit} = level;
			sceneContext.fillStyle = '#6b4423';
			sceneContext.fillRect(hatch.x - 10, hatch.y - 10, 20, 6);
			sceneContext.fillStyle = game.tick > 20 ? '#000000' : '#8b5a2b';
			sceneContext.fillRect(hatch.x - 6, hatch.y - 4, 12, 2);

			// The exit: a doorway with two flames on top.
			sceneContext.fillStyle = '#a0522d';
			sceneContext.fillRect(exit.x - 7, exit.y - 15, 14, 16);
			sceneContext.fillStyle = '#000000';
			sceneContext.fillRect(exit.x - 4, exit.y - 10, 8, 11);
			sceneContext.fillStyle = game.tick % 4 < 2 ? '#ffcc00' : '#ff6600';
			sceneContext.fillRect(exit.x - 7, exit.y - 19, 3, 4);
			sceneContext.fillRect(exit.x + 4, exit.y - 19, 3, 4);

			if (level.water) {
				sceneContext.fillStyle = '#1144aa';
				sceneContext.fillRect(0, level.water, width, height - level.water);
				sceneContext.fillStyle = '#4488ff';

				for (let x = (game.tick % 8) - 8; x < width; x += 8) {
					sceneContext.fillRect(x, level.water, 4, 1);
				}

				// The ground stays in front of the water.
				sceneContext.drawImage(terrainCanvas, 0, level.water, width, height - level.water, 0, level.water, width, height - level.water);
			}

			for (const lemming of game.lemmings) {
				if (isAlive(lemming)) {
					drawLemming(lemming);
				}
			}

			for (const particle of game.particles) {
				if (!particle.text) {
					sceneContext.fillStyle = particle.color;
					sceneContext.fillRect(Math.round(particle.x), Math.round(particle.y), 1, 1);
				}
			}

			context.imageSmoothingEnabled = false;
			context.drawImage(scene, 0, 0, lemmingsCanvas.width, lemmingsCanvas.height);

			// The words and the cursor, in sharp letters on the large canvas.
			context.font = 'bold 12px "Courier New", monospace';
			context.textAlign = 'center';

			for (const lemming of game.lemmings) {
				if (lemming.bombTimer !== undefined && canAct(lemming) && lemming.bombTimer > 20) {
					context.fillStyle = '#ffffff';
					context.fillText(String(Math.ceil(lemming.bombTimer / ticksPerSecond)), lemming.x * 2, (lemming.y - 12) * 2);
				}
			}

			for (const particle of game.particles) {
				if (particle.text) {
					context.fillStyle = particle.text === 'Oh no!' ? '#ff6666' : '#ffff66';
					context.fillText(particle.text, particle.x * 2, particle.y * 2);
				}
			}

			const marked = game.hover ?? game.selected;

			if (marked && canAct(marked)) {
				context.strokeStyle = '#ffffff';
				context.lineWidth = 2;
				context.strokeRect((marked.x - 4) * 2, (marked.y - 11) * 2, 18, 26);
			}

			const out = game.lemmings.filter(lemming => isAlive(lemming) && lemming.state !== 'saved').length;
			context.textAlign = 'left';
			context.fillStyle = '#33ff66';
			context.fillText(`OUT ${out}  IN ${game.saved}/${level.need}  LEFT ${level.count - game.released}`, 8, 18);

			if (game.isPaused && !game.isOver) {
				context.textAlign = 'center';
				context.fillStyle = '#ffff66';
				context.font = 'bold 28px Impact, "Arial Black", sans-serif';
				context.fillText('PAUSED', lemmingsCanvas.width / 2, lemmingsCanvas.height / 2);
			}
		};

		let clock = 0;

		const step = seconds => {
			clock += seconds * ticksPerSecond;

			while (clock >= 1) {
				clock--;
				tick();
			}

			draw();
		};

		const loop = this.loop(step, {while: () => !this.reducedMotion && !game.isPaused && !game.isOver});

		// MARK: Controls

		const pointFromEvent = event => {
			const rect = lemmingsCanvas.getBoundingClientRect();
			return {x: ((event.clientX - rect.left) / rect.width) * width, y: ((event.clientY - rect.top) / rect.height) * height};
		};

		const lemmingAt = (point, reach) => {
			let best;
			let bestDistance = Number.POSITIVE_INFINITY;

			for (const lemming of game.lemmings) {
				const distance = Math.hypot(lemming.x - point.x, (lemming.y - 5) - point.y);

				if (canAct(lemming) && distance < reach && distance < bestDistance) {
					best = lemming;
					bestDistance = distance;
				}
			}

			return best;
		};

		const assign = lemming => {
			const skill = game.skill;

			if (!lemming || !canAct(lemming) || game.isOver) {
				return;
			}

			if (game.skills[skill] <= 0) {
				this.say(`No more ${skillNames[skill]} jobs left on this level.`);
				return;
			}

			switch (skill) {
				case 'float': {
					if (lemming.isFloater) {
						this.say('That lemming already has an umbrella.');
						return;
					}

					lemming.isFloater = true;
					break;
				}

				case 'bomb': {
					if (lemming.bombTimer !== undefined) {
						return;
					}

					lemming.bombTimer = 5 * ticksPerSecond;
					break;
				}

				default: {
					if (lemming.state === 'block') {
						this.say('A blocker never stops blocking. Only a bomb can move it now.');
						return;
					}

					if (!['walk', 'dig', 'build', 'bash', 'shrug'].includes(lemming.state)) {
						this.say(`A lemming has to be on the ground to ${skillNames[skill].toLowerCase()}.`);
						return;
					}

					if (lemming.state === skill && skill !== 'build') {
						return;
					}

					lemming.state = skill;
					lemming.bricks = 12;
					lemming.hasWorked = false;
					lemming.steps = 0;
				}
			}

			game.skills[skill]--;
			showSkills();
			draw();
		};

		const pickSkill = skill => {
			if (!(skill in game.skills)) {
				return;
			}

			game.skill = skill;
			showSkills();
		};

		for (const button of skillButtons) {
			this.on(button, 'click', () => {
				pickSkill(button.dataset.lemmingsSkill);
			});
		}

		this.on(lemmingsCanvas, 'pointermove', event => {
			if (event.pointerType === 'mouse') {
				game.hover = lemmingAt(pointFromEvent(event), 10);

				if (game.isPaused || this.reducedMotion || game.isOver) {
					draw();
				}
			}
		});

		this.on(lemmingsCanvas, 'pointerleave', () => {
			game.hover = undefined;
			draw();
		});

		this.on(lemmingsCanvas, 'pointerdown', event => {
			const lemming = lemmingAt(pointFromEvent(event), event.pointerType === 'mouse' ? 10 : 16);

			if (lemming) {
				game.selected = lemming;
				assign(lemming);
			}
		});

		// The lemmings in the order of the screen, for the arrow keys.
		const pickNext = direction => {
			const candidates = game.lemmings.filter(lemming => canAct(lemming)).sort((first, second) => first.x - second.x);

			if (candidates.length === 0) {
				return;
			}

			const index = candidates.indexOf(game.selected);
			game.selected = candidates[(index === -1 ? (direction > 0 ? 0 : candidates.length - 1) : (index + direction + candidates.length) % candidates.length)];
			draw();
		};

		const togglePause = () => {
			game.isPaused = !game.isPaused;
			pauseButton.setAttribute('aria-pressed', String(game.isPaused));
			loop.start();
			draw();
		};

		// Moves the game on by one second at once, for when it is paused, or when the visitor prefers reduced motion.
		const stepOneSecond = () => {
			for (let index = 0; index < ticksPerSecond; index++) {
				tick();
			}

			draw();
		};

		this.on(lemmingsCanvas, 'keydown', event => {
			const skills = Object.keys(skillNames);

			if (event.key === 'ArrowRight' || event.key === 'ArrowLeft') {
				event.preventDefault();
				pickNext(event.key === 'ArrowRight' ? 1 : -1);
			} else if (/^[1-6]$/.test(event.key)) {
				pickSkill(skills[Number(event.key) - 1]);
			} else if (event.key === ' ' || event.key === 'Enter') {
				event.preventDefault();
				assign(game.selected);
			} else if (event.key === 'p' || event.key === 'P') {
				togglePause();
			}
		});

		this.on(pauseButton, 'click', togglePause);
		this.on(stepButton, 'click', stepOneSecond);

		this.on(restart, 'click', () => {
			startLevel(game.level);
			loop.start();
		});

		this.on(nextButton, 'click', () => {
			startLevel(Math.min(game.level + 1, levels.length - 1));
			lemmingsCanvas.focus();
			loop.start();
		});

		this.on(levelSelect, 'change', () => {
			startLevel(Number(levelSelect.value));
			loop.start();
		});

		this.on(nuke, 'click', () => {
			if (game.isOver || game.isNuked) {
				return;
			}

			game.isNuked = true;

			for (const [index, lemming] of game.lemmings.filter(item => canAct(item)).entries()) {
				lemming.bombTimer ??= (2 * ticksPerSecond) + index;
			}

			this.say('NUKE! Oh no! Oh no! Oh no!');
			draw();
			loop.start();
		});

		// The storage can hold anything, so the levels are checked.
		progress.reached = clamp(Math.floor(Number(progress.reached) || 0), 0, levels.length - 1);
		progress.current = clamp(Math.floor(Number(progress.current) || 0), 0, progress.reached);
		startLevel(progress.current);
	}
}
