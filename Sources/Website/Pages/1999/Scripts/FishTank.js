// The aquarium on the 1999 page: fish of big pixels on a canvas of 320 × 180, drawn twice as large. Each fish swims to food when it is hungry, follows the finger of the visitor when it is close, and else wanders. Food that nobody eats rots on the sand and turns the water green. The glass scares the fish when tapped and puffs up the pufferfish.

const randomItem = items => items[Math.floor(Math.random() * items.length)];
const randomBetween = (minimum, maximum) => minimum + (Math.random() * (maximum - minimum));
const clamp = (value, minimum, maximum) => Math.min(Math.max(value, minimum), maximum);

// Makes a canvas with a sprite of big pixels, from rows of letters where each letter is a color of the palette, and any other letter, like a dot, is clear. Short rows are clear at the end.
const makeSprite = (rows, palette, scale = 1) => {
	const width = Math.max(...rows.map(row => row.length));
	const canvas = document.createElement('canvas');
	canvas.width = width * scale;
	canvas.height = rows.length * scale;
	const context = canvas.getContext('2d');

	for (const [y, row] of rows.entries()) {
		for (const [x, letter] of [...row].entries()) {
			if (palette[letter]) {
				context.fillStyle = palette[letter];
				context.fillRect(x * scale, y * scale, scale, scale);
			}
		}
	}

	return canvas;
};

// The same sprite, facing the other way.
const mirrorSprite = sprite => {
	const canvas = document.createElement('canvas');
	canvas.width = sprite.width;
	canvas.height = sprite.height;
	const context = canvas.getContext('2d');
	context.translate(sprite.width, 0);
	context.scale(-1, 1);
	context.drawImage(sprite, 0, 0);
	return canvas;
};

// A sprite that faces right, and its mirror, which faces left.
const makeFacingSprite = (rows, palette, scale) => {
	const right = makeSprite(rows, palette, scale);
	return {right, left: mirrorSprite(right)};
};

export default class extends GeoCitiesElement {
	// The fish only swim while the water is on the screen, not while only the buttons below it are.
	get visibilityTarget() {
		return this.parts.tank;
	}

	connected() {
		const {tank: tankCanvas, stats: tankStats, lights: lightsButton, species: speciesSelect, food, tap, clean, buy} = this.parts;
		const width = 320;
		const height = 180;
		const sandTop = 160;
		const scene = document.createElement('canvas');
		scene.width = width;
		scene.height = height;
		const sceneContext = scene.getContext('2d');
		const context = tankCanvas.getContext('2d');

		const species = {
			goldfish: {name: 'goldfish', speed: 30, names: ['Goldie', 'Bubbles', 'Flipper', 'Sunny'], sprite: makeFacingSprite([
				'......oo...',
				'o...ooooo..',
				'oo.oooooyko',
				'ooooooooooo',
				'oo.oooyooo.',
				'o...ooooo..',
				'......o....',
			], {o: '#ff8c1a', y: '#ffcc44', k: '#000000'}, 2)},
			neon: {name: 'neon tetra', speed: 45, names: ['Zippy', 'Sparky', 'Neon', 'Laser'], glows: true, sprite: makeFacingSprite([
				'...ssss...',
				's.bbbbbbk.',
				'ssbbbbbbbs',
				's.rrrrrrs.',
				'...ssss...',
			], {s: '#c0d0e0', b: '#22ddff', r: '#ff3355', k: '#000000'}, 2)},
			angel: {name: 'angelfish', speed: 20, names: ['Wanda', 'Angel', 'Halo', 'Gabriel'], sprite: makeFacingSprite([
				'....s....',
				'...ss....',
				'..sss....',
				's.sdsds..',
				'sssdsdsks',
				's.sdsdss.',
				'..sss....',
				'...ss....',
				'....s....',
			], {s: '#f0f0e0', d: '#333333', k: '#000000'}, 2)},
			puffer: {name: 'pufferfish', speed: 15, names: ['Puff', 'Spike', 'Balloon', 'Pompom'], sprite: makeFacingSprite([
				'...yyyy...',
				'y.yybyyyy.',
				'yyyyyyykyy',
				'y.wwwwwww.',
				'...wwww...',
			], {y: '#e8d040', b: '#a08020', w: '#fffbe0', k: '#000000'}, 2), puffed: makeFacingSprite([
				'.....b......',
				'..b.yyyy.b..',
				'...yyyyyy...',
				'..yybyyyyy..',
				'b.yyyyyykyy.b',
				'.yyyyyyyyyy.',
				'..wwwwwwww..',
				'b..wwwwww..b',
				'....b..b....',
			], {y: '#e8d040', b: '#a08020', w: '#fffbe0', k: '#000000'}, 2)},
			cod: {name: 'cod', speed: 25, names: ['Torsk', 'Mr. Cod', 'Fiskepinne', 'Big Bergen'], sprite: makeFacingSprite([
				'.....dddd.......',
				'd..bbbbbbbbbb...',
				'ddbbbbdbbbbbbkb.',
				'ddbbbbbbbbbbbbbb',
				'd..wwwwwwwwwwbb.',
				'.....wwwwww..d..',
			], {b: '#8a7a5a', d: '#5a4a3a', w: '#e8e0d0', k: '#000000'}, 2)},
		};

		const saved = this.stored('tank', {});
		const savedFishes = Array.isArray(saved.fishes) ? saved.fishes.slice(0, 12) : undefined;
		const fishes = [];
		const flakes = [];
		const bubbles = [];
		const finger = {x: width / 2, y: height / 2, lastMove: -10_000, isKeyboard: false};
		let murk = clamp(Number(saved.murk) || 0, 0, 1);
		let isLightOn = saved.isLightOn ?? true;
		let eaten = Number.isInteger(saved.eaten) ? saved.eaten : 0;
		let time = 0;
		let signTime = 0;
		let sulkTime = 0;
		let taps = 0;
		let lastTapTime = -100;

		const addFish = (kind, name, size = 1) => {
			const fish = {kind, name, size, x: randomBetween(30, width - 30), y: randomBetween(30, 140), velocityX: 0, velocityY: 0, direction: Math.random() < 0.5 ? -1 : 1, hunger: Math.random() * 0.5, wander: undefined, wanderTime: 0, scaredTime: 0, puffTime: 0, flee: undefined};
			fishes.push(fish);
			return fish;
		};

		for (const fish of savedFishes ?? [{kind: 'goldfish', name: 'Goldie'}, {kind: 'neon', name: 'Zippy'}, {kind: 'angel', name: 'Wanda'}, {kind: 'puffer', name: 'Puff'}]) {
			if (species[fish.kind]) {
				addFish(fish.kind, String(fish.name), clamp(Number(fish.size) || 1, 1, 1.8));
			}
		}

		const saveTank = () => {
			this.store('tank', {fishes: fishes.map(fish => ({kind: fish.kind, name: fish.name, size: Math.round(fish.size * 100) / 100})), murk, isLightOn, eaten});
		};

		const waterWord = () => {
			if (murk > 0.6) {
				return 'GREEN';
			}

			return murk > 0.25 ? 'cloudy' : 'clean';
		};

		const showStats = () => {
			tankStats.textContent = `Fish: ${fishes.length} ★ Food eaten: ${eaten} ★ Water: ${waterWord()}`;
		};

		// The sand, the pebbles, and the castle do not change, so they are drawn once.
		const background = document.createElement('canvas');
		background.width = width;
		background.height = height;

		{
			const backgroundContext = background.getContext('2d');
			const water = backgroundContext.createLinearGradient(0, 0, 0, height);
			water.addColorStop(0, '#2a88cc');
			water.addColorStop(1, '#0b3a6b');
			backgroundContext.fillStyle = water;
			backgroundContext.fillRect(0, 0, width, height);
			backgroundContext.fillStyle = '#d8c08a';
			backgroundContext.fillRect(0, sandTop, width, height - sandTop);

			for (let index = 0; index < 90; index++) {
				backgroundContext.fillStyle = randomItem(['#b89860', '#e8d8a8', '#a08050', '#c86040', '#6080a0']);
				backgroundContext.fillRect(Math.floor(Math.random() * width), sandTop + 2 + Math.floor(Math.random() * 18), 2, 1);
			}

			// The castle, with a little flag of Norway on the top.
			const castle = makeSprite([
				'.........r.........',
				'.........rRRw......',
				'.........rwwww.....',
				'.........rRRw......',
				'.........k.........',
				'g.g.g...ggg...g.g.g',
				'ggggg...ggg...ggggg',
				'gGggg..gGggg..gggGg',
				'ggggg..ggggg..ggggg',
				'ggkgg..ggkgg..ggkgg',
				'ggggggggggggggggggg',
				'gggGggggggggggGgggg',
				'ggggggggkkkgggggggg',
				'gggggggkkkkkggggggg',
				'ggGggggkkkkkgggGggg',
				'gggggggkkkkkggggggg',
			], {g: '#8890a0', G: '#6a7080', k: '#202838', r: '#cc0000', R: '#00205b', w: '#ffffff'}, 2);
			backgroundContext.drawImage(castle, 236, sandTop - castle.height + 4);
		}

		const chestClosed = makeSprite([
			'.bbbbbbbbbb.',
			'bBBBBBBBBBBb',
			'bbbbbyybbbbb',
			'bBBBByyBBBBb',
			'bBBBBBBBBBBb',
			'bbbbbbbbbbbb',
		], {b: '#5a3410', B: '#8b5a2b', y: '#ffd700'}, 2);

		const chestOpen = makeSprite([
			'.bbbbbbbbbb.',
			'bBBBBBBBBBBb',
			'............',
			'byyyyyyyyyyb',
			'bBBBByyBBBBb',
			'bBBBBBBBBBBb',
			'bbbbbbbbbbbb',
		], {b: '#5a3410', B: '#8b5a2b', y: '#ffd700'}, 2);

		const nearest = (fish, items) => {
			let best;
			let bestDistance = Number.POSITIVE_INFINITY;

			for (const item of items) {
				const distance = Math.hypot(item.x - fish.x, item.y - fish.y);

				if (distance < bestDistance) {
					best = item;
					bestDistance = distance;
				}
			}

			return best;
		};

		const updateFish = (fish, index, seconds) => {
			const kind = species[fish.kind];
			fish.hunger = Math.min(1, fish.hunger + (seconds / 45));
			fish.scaredTime = Math.max(0, fish.scaredTime - seconds);
			fish.puffTime = Math.max(0, fish.puffTime - seconds);
			fish.wanderTime -= seconds;
			const isFingerNear = time - finger.lastMove < 2 && Math.hypot(finger.x - fish.x, finger.y - fish.y) < 170;
			let target;

			if (fish.scaredTime > 0) {
				target = fish.flee;
			} else if (sulkTime > 0) {
				target = {x: 16 + ((index % 4) * 8), y: 140 - ((index % 3) * 8)};
			} else if (flakes.length > 0 && fish.hunger > 0.05) {
				target = nearest(fish, flakes);
			} else if (isFingerNear) {
				// The fish gather around the finger, each at its own spot, so they do not stack.
				target = {x: finger.x + (Math.cos(index * 2.4) * 14), y: finger.y + (Math.sin(index * 2.4) * 10)};
			} else {
				if (!fish.wander || fish.wanderTime <= 0 || Math.hypot(fish.wander.x - fish.x, fish.wander.y - fish.y) < 8) {
					fish.wander = {x: randomBetween(16, width - 16), y: randomBetween(20, 150)};
					fish.wanderTime = randomBetween(3, 8);
				}

				target = fish.wander;
			}

			let speed = kind.speed * (fish.scaredTime > 0 ? 3.5 : 1) * (isLightOn ? 1 : 0.35) * (fish.puffTime > 0 ? 0.3 : 1);
			const distance = Math.hypot(target.x - fish.x, target.y - fish.y);
			speed *= Math.min(1, distance / 20);
			const desiredX = distance > 0 ? ((target.x - fish.x) / distance) * speed : 0;
			const desiredY = distance > 0 ? ((target.y - fish.y) / distance) * speed * 0.6 : 0;
			const turn = Math.min(1, seconds * 3);
			fish.velocityX += (desiredX - fish.velocityX) * turn;
			fish.velocityY += (desiredY - fish.velocityY) * turn;
			fish.x = clamp(fish.x + (fish.velocityX * seconds), 14, width - 14);
			fish.y = clamp(fish.y + (fish.velocityY * seconds), 20, sandTop - 10);

			if (Math.abs(fish.velocityX) > 3) {
				fish.direction = Math.sign(fish.velocityX);
			}

			const flake = flakes.find(item => Math.hypot(item.x - fish.x, item.y - fish.y) < 9 * fish.size);

			if (flake && fish.hunger > 0.05) {
				flakes.splice(flakes.indexOf(flake), 1);
				fish.size = Math.min(1.8, fish.size + 0.03);
				fish.hunger = Math.max(0, fish.hunger - 0.12);
				eaten++;
				showStats();
			}
		};

		let lastWater = waterWord();
		let chestTime = 0;

		const simulate = seconds => {
			time += seconds;
			signTime = Math.max(0, signTime - seconds);
			sulkTime = Math.max(0, sulkTime - seconds);
			chestTime = (chestTime + seconds) % 14;

			for (const [index, fish] of fishes.entries()) {
				updateFish(fish, index, seconds);
			}

			for (const flake of [...flakes]) {
				if (flake.y < sandTop) {
					flake.y = Math.min(sandTop, flake.y + (10 * seconds));
					flake.x += Math.sin((time * 2) + flake.y) * 4 * seconds;
				} else {
					flake.age += seconds;

					// Food that nobody eats rots, and the water turns green.
					if (flake.age > 25) {
						flakes.splice(flakes.indexOf(flake), 1);
						murk = Math.min(1, murk + 0.05);
					}
				}
			}

			// Bubbles from the air stone, and from the chest while it is open.
			if (Math.random() < seconds * 3) {
				bubbles.push({x: 150 + randomBetween(-2, 2), y: sandTop - 2, size: randomItem([1, 1, 2])});
			}

			if (chestTime > 11 && Math.random() < seconds * 8) {
				bubbles.push({x: 52 + randomBetween(-6, 6), y: sandTop - 12, size: randomItem([1, 2, 2])});
			}

			for (const bubble of [...bubbles]) {
				bubble.y -= (18 + (bubble.size * 8)) * seconds;
				bubble.x += Math.sin((time * 4) + bubble.y) * 6 * seconds;

				if (bubble.y < 12) {
					bubbles.splice(bubbles.indexOf(bubble), 1);
				}
			}

			if (waterWord() !== lastWater) {
				lastWater = waterWord();
				showStats();
				saveTank();

				if (lastWater === 'GREEN') {
					this.say('The water is turning green! Too much food. Clean the tank!');
				}
			}
		};

		const drawFish = fish => {
			const kind = species[fish.kind];
			const sprite = fish.puffTime > 0 && kind.puffed ? kind.puffed : kind.sprite;
			const image = fish.direction > 0 ? sprite.right : sprite.left;
			const drawWidth = Math.round(image.width * fish.size);
			const drawHeight = Math.round(image.height * fish.size);
			sceneContext.drawImage(image, Math.round(fish.x - (drawWidth / 2)), Math.round(fish.y - (drawHeight / 2)), drawWidth, drawHeight);
		};

		const draw = () => {
			sceneContext.imageSmoothingEnabled = false;
			sceneContext.drawImage(background, 0, 0);

			// Rays of light from the lamp of the tank.
			if (isLightOn) {
				sceneContext.fillStyle = 'rgba(255, 255, 255, 0.06)';

				for (const x of [40, 130, 220]) {
					const sway = Math.sin((time * 0.5) + x) * 10;
					sceneContext.beginPath();
					sceneContext.moveTo(x + sway, 10);
					sceneContext.lineTo(x + 24 + sway, 10);
					sceneContext.lineTo(x + 60, sandTop);
					sceneContext.lineTo(x + 20, sandTop);
					sceneContext.fill();
				}
			}

			// The water line at the top.
			sceneContext.fillStyle = 'rgba(255, 255, 255, 0.35)';
			sceneContext.fillRect(0, 9, width, 1);

			// Seaweed that sways in the water.
			for (const [baseX, tall] of [[18, 70], [96, 50], [190, 64], [300, 80]]) {
				for (let y = 0; y < tall; y += 2) {
					const sway = Math.sin((time * 1.5) + (y / 12) + baseX) * (y / 12);
					sceneContext.fillStyle = y % 6 === 0 ? '#2e8b3a' : '#3cb043';
					sceneContext.fillRect(Math.round(baseX + sway), sandTop - y - 2, 3, 2);
				}
			}

			sceneContext.drawImage(chestTime > 11 ? chestOpen : chestClosed, 40, sandTop - 12);

			// The air stone.
			sceneContext.fillStyle = '#555555';
			sceneContext.fillRect(146, sandTop - 3, 8, 3);

			for (const bubble of bubbles) {
				sceneContext.strokeStyle = 'rgba(255, 255, 255, 0.8)';
				sceneContext.strokeRect(Math.round(bubble.x), Math.round(bubble.y), bubble.size + 1, bubble.size + 1);
			}

			sceneContext.fillStyle = '#c8783a';

			for (const flake of flakes) {
				sceneContext.fillRect(Math.round(flake.x), Math.round(flake.y), 2, 2);
			}

			for (const fish of fishes) {
				drawFish(fish);
			}

			if (murk > 0) {
				sceneContext.fillStyle = `rgba(70, 140, 30, ${murk * 0.65})`;
				sceneContext.fillRect(0, 10, width, sandTop - 10);
			}

			if (!isLightOn) {
				sceneContext.fillStyle = 'rgba(0, 0, 30, 0.65)';
				sceneContext.fillRect(0, 0, width, height);

				// The neon tetras glow in the dark.
				for (const fish of fishes) {
					if (species[fish.kind].glows) {
						drawFish(fish);
					}
				}
			}

			if (finger.isKeyboard && time - finger.lastMove < 4) {
				sceneContext.strokeStyle = '#ffffff';
				sceneContext.strokeRect(Math.round(finger.x) - 3, Math.round(finger.y) - 3, 6, 6);
			}

			context.imageSmoothingEnabled = false;
			context.drawImage(scene, 0, 0, tankCanvas.width, tankCanvas.height);

			// The sign, in sharp letters on the large canvas.
			if (signTime > 0) {
				context.fillStyle = '#ffffff';
				context.fillRect(120, 30, 400, 64);
				context.strokeStyle = '#cc0000';
				context.lineWidth = 4;
				context.strokeRect(122, 32, 396, 60);
				context.fillStyle = '#cc0000';
				context.font = 'bold 22px Impact, "Arial Black", sans-serif';
				context.textAlign = 'center';
				context.fillText('PLEASE DO NOT TAP', 320, 58);
				context.fillText('ON THE GLASS!!!', 320, 84);
			}
		};

		const step = seconds => {
			simulate(seconds);
			draw();
		};

		this.loop(step, {while: () => !this.reducedMotion});

		// Without motion, each thing the visitor does moves the tank on by a few seconds at once, and shows the new picture.
		const skipAhead = seconds => {
			if (!this.reducedMotion) {
				return;
			}

			for (let elapsed = 0; elapsed < seconds; elapsed += 1 / 30) {
				simulate(1 / 30);
			}

			draw();
		};

		const dropFood = (x, amount = 1) => {
			for (let index = 0; index < amount; index++) {
				flakes.push({x: clamp(x + randomBetween(-12, 12), 4, width - 4), y: 12 + randomBetween(0, 6), age: 0});
			}

			// Too much food at once makes the water cloudy.
			if (flakes.length > 18) {
				murk = Math.min(1, murk + 0.03);
			}
		};

		const pointFromEvent = event => {
			const rect = tankCanvas.getBoundingClientRect();
			return {x: ((event.clientX - rect.left) / rect.width) * width, y: ((event.clientY - rect.top) / rect.height) * height};
		};

		this.on(tankCanvas, 'pointermove', event => {
			const point = pointFromEvent(event);
			finger.x = point.x;
			finger.y = clamp(point.y, 16, sandTop - 6);
			finger.lastMove = time;
			finger.isKeyboard = false;
		});

		this.on(tankCanvas, 'pointerleave', () => {
			finger.lastMove = -10_000;
		});

		this.on(tankCanvas, 'pointerdown', event => {
			const point = pointFromEvent(event);
			finger.x = point.x;
			finger.y = clamp(point.y, 16, sandTop - 6);
			finger.lastMove = time;
			finger.isKeyboard = false;
			dropFood(point.x, 2);
			skipAhead(3);
		});

		this.on(tankCanvas, 'keydown', event => {
			const moves = {ArrowLeft: [-10, 0], ArrowRight: [10, 0], ArrowUp: [0, -8], ArrowDown: [0, 8]};

			if (moves[event.key]) {
				event.preventDefault();
				const [x, y] = moves[event.key];
				finger.x = clamp(finger.x + x, 8, width - 8);
				finger.y = clamp(finger.y + y, 16, sandTop - 6);
				finger.lastMove = time;
				finger.isKeyboard = true;
				skipAhead(0.5);
			} else if (event.key === ' ' || event.key === 'Enter') {
				event.preventDefault();
				dropFood(finger.x, 2);
				skipAhead(3);
			}
		});

		this.on(food, 'click', () => {
			for (let index = 0; index < 3; index++) {
				dropFood(randomBetween(30, width - 30), 2);
			}

			this.say(flakes.length > 18 ? 'That is a LOT of food. The water does not look so good.' : 'Dinner time! The fish race to the food.');
			skipAhead(4);
		});

		this.on(tap, 'click', () => {
			taps = time - lastTapTime < 20 ? taps + 1 : 1;
			lastTapTime = time;
			signTime = 3;

			for (const fish of fishes) {
				fish.scaredTime = 1.5;
				fish.flee = {x: fish.x < width / 2 ? randomBetween(width * 0.6, width - 10) : randomBetween(10, width * 0.4), y: randomBetween(20, 150)};

				if (fish.kind === 'puffer') {
					fish.puffTime = 6;
				}
			}

			if (taps >= 3) {
				sulkTime = 10;
				this.say('The fish are sulking in the corner now. Happy?');
			} else {
				this.say(fishes.some(fish => fish.kind === 'puffer') ? 'TAP TAP! The fish panic, and the pufferfish puffs up like a balloon.' : 'TAP TAP! The fish panic.');
			}

			if (this.reducedMotion) {
				skipAhead(0.4);
				this.timeout(3000, () => {
					skipAhead(3);
				});
			}
		});

		this.on(lightsButton, 'click', () => {
			isLightOn = !isLightOn;
			lightsButton.setAttribute('aria-pressed', String(isLightOn));
			saveTank();
			this.say(isLightOn ? 'Lights on! Good morning, fish.' : 'Lights off. The fish go to sleep, and the neon tetras glow.');
			skipAhead(0.1);
		});

		this.on(clean, 'click', () => {
			const wasDirty = murk > 0.05 || flakes.length > 0;
			murk = 0;
			flakes.length = 0;
			lastWater = 'clean';
			showStats();
			saveTank();
			this.say(wasDirty ? 'Scrub scrub! The tank is sparkling clean.' : 'The tank is already clean. You cleaned it anyway. The fish are impressed.');
			skipAhead(0.1);
		});

		this.on(buy, 'click', () => {
			if (fishes.length >= 12) {
				this.say('The tank is full. Even the cod agrees.');
				return;
			}

			const kind = speciesSelect.value;
			const used = new Set(fishes.map(fish => fish.name));
			const name = species[kind].names.find(item => !used.has(item)) ?? `${species[kind].names[0]} ${fishes.length + 1}`;
			const fish = addFish(kind, name);
			fish.x = width / 2;
			fish.y = 14;
			saveTank();
			showStats();
			this.say(`Say hello to ${name} the ${species[kind].name}! Free from the pet shop.`);
			skipAhead(1);
		});

		// The size of the fish is saved now and then, as they grow while they eat.
		this.interval(15_000, () => {
			if (!document.hidden) {
				saveTank();
			}
		});

		lightsButton.setAttribute('aria-pressed', String(isLightOn));
		showStats();
		simulate(0);
		draw();
	}
}
