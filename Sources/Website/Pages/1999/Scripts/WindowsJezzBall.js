// JezzBall on the desktop of the 1999 page, like the one of the Microsoft Entertainment Pack (Dima Pavlovsky, 1992): atoms bounce in a room, and walls that grow both ways from a click box them in. An atom that hits a wall while it grows breaks that half and takes a life. The parts of the room without atoms fill in, and `config.goal` percent cleared wins the level. Level n has n + 1 atoms, n + 1 lives, and a clock. Nothing makes a sound until the visitor turns on the sound.

// The room is a grid of 40 × 25 tiles of 12 pixels. A tile is open or filled, and the atoms bounce off the filled ones.
const tile = 12;
const atomRadius = 5;
const wallSpeed = 20;
const step = 1 / 120;

const levelTime = level => 50 + (level * 15);

export default class extends GeoCitiesElement {
	#context;
	#columns;
	#rows;
	#goal;
	#best;
	#loop;
	#crosshair;
	#isCrosshairShown = false;

	#game = {
		level: 1,
		lives: 2,
		score: 0,
		time: 0,
		grid: undefined,
		atoms: [],
		halves: [],
		cleared: 0,
		mode: 'ready',
		isVertical: false,
	};

	connected() {
		const {screen, newGame, pause, sound, turn} = this.parts;
		this.#context = screen.getContext('2d');
		this.#columns = screen.width / tile;
		this.#rows = screen.height / tile;
		this.#goal = this.config.goal;
		this.#game.grid = new Uint8Array(this.#columns * this.#rows);
		this.#crosshair = {column: Math.floor(this.#columns / 2), row: Math.floor(this.#rows / 2)};
		this.#best = this.stored('best', 0);

		// The game runs only while it is on the screen, in its open window, and the tab is visible. With reduced motion, it runs only for a moment after each action.
		this.#loop = this.loop(seconds => {
			let left = seconds;

			while (left > 0 && this.#game.mode === 'playing') {
				this.#update(Math.min(step, left));
				left -= step;
			}

			this.#draw();
			this.#showStats();
		}, {while: () => this.#game.mode === 'playing' && !this.reducedMotion, maximumStep: 0.05});

		this.on(sound, 'click', () => {
			const isOn = !this.#isSoundOn;
			sound.setAttribute('aria-pressed', String(isOn));
			sound.textContent = isOn ? '🔊 Sound' : '🔈 Sound';

			if (isOn) {
				this.#sounds.build();
			}
		});

		this.on(screen, 'pointerdown', event => {
			if (event.button === 2) {
				this.#turn();
				this.#nudge();
				return;
			}

			if (event.button !== 0) {
				return;
			}

			this.#crosshair = this.#tileAt(event);
			this.#isCrosshairShown = event.pointerType === 'mouse';
			this.#act(this.#crosshair.column, this.#crosshair.row);
		});

		this.on(screen, 'pointermove', event => {
			if (event.pointerType !== 'mouse') {
				return;
			}

			this.#crosshair = this.#tileAt(event);
			this.#isCrosshairShown = true;
			this.#drawWhenStill();
		});

		this.on(screen, 'pointerleave', () => {
			this.#isCrosshairShown = false;
			this.#drawWhenStill();
		});

		// The right mouse button turns the wall, like in JezzBall, instead of opening the menu of the browser.
		this.on(screen, 'contextmenu', event => {
			event.preventDefault();
		});

		this.on(screen, 'keydown', event => {
			this.#keyDown(event);
		});

		this.on(turn, 'click', event => {
			this.#turn();
			this.#nudge();

			// Safari does not focus a button on a click, so a click gives the focus to the room, where the keys work. The keyboard stays on the button.
			if (event.detail > 0) {
				screen.focus({preventScroll: true});
			}
		});

		this.on(pause, 'click', () => {
			this.#setPaused(this.#game.mode === 'playing');
		});

		this.on(newGame, 'click', () => {
			this.#newGame();
			screen.focus();
		});

		// A click elsewhere pauses the game, as the keys no longer reach it, so nobody loses a life while reading the page. The message box of the desktop is not elsewhere.
		this.on(document, 'pointerdown', event => {
			if (!this.desktopWindow.contains(event.target) && !event.target.closest('[data-desktop-window="message"]')) {
				this.#setPaused(true, 'Paused, as you clicked somewhere else. Click the room or press P to go on.');
			}
		});

		this.#newGame();
	}

	visibilityChanged(isVisible) {
		if (isVisible) {
			this.#draw();
		} else if (document.hidden) {
			this.#setPaused(true, 'Paused, as you left the page. Click the room or press P to go on.');
		} else if (this.desktopWindow.hidden) {
			this.#setPaused(true);
		} else {
			this.#setPaused(true, 'Paused, as the room scrolled away. Click the room or press P to go on.');
		}
	}

	#percentCleared() {
		return Math.floor((this.#game.cleared / this.#game.grid.length) * 100);
	}

	// The stats are shown every frame, so they are only written when they changed.
	#showStats() {
		const game = this.#game;
		const text = `Level ${game.level} ★ Lives ${game.lives} ★ Cleared ${this.#percentCleared()}% ★ Time ${Math.ceil(game.time)} ★ Score ${game.score.toLocaleString('en-US')} ★ Best ${Math.max(this.#best, game.score).toLocaleString('en-US')}`;
		const {stats} = this.parts;

		if (stats.textContent !== text) {
			stats.textContent = text;
		}
	}

	get #isSoundOn() {
		return this.parts.sound.getAttribute('aria-pressed') === 'true';
	}

	// The sounds, made with tones, once the visitor turns them on.
	#tone(frequency, start, duration, {type = 'square', volume = 0.06, slide} = {}) {
		const sound = this.#isSoundOn && this.sound();

		if (!sound) {
			return;
		}

		const {context, output} = sound;
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
		build: () => this.#tone(660, 0, 0.08),
		done: () => this.#tone(220, 0, 0.12, {type: 'triangle', volume: 0.12}),
		broken: () => this.#tone(300, 0, 0.35, {type: 'sawtooth', slide: 60}),
		won: () => {
			for (const [index, frequency] of [523, 659, 784, 1047].entries()) {
				this.#tone(frequency, index * 0.1, 0.2, {type: 'triangle', volume: 0.1});
			}
		},
		over: () => {
			for (const [index, frequency] of [392, 330, 262, 196].entries()) {
				this.#tone(frequency, index * 0.18, 0.25, {type: 'triangle', volume: 0.1});
			}
		},
	};

	// A question with the message box of the desktop.
	ask(options) {
		return super.ask({title: 'JezzBall', icon: '⚛️', opener: this.parts.screen, ...options});
	}

	#isFilled(column, row) {
		return column < 0 || row < 0 || column >= this.#columns || row >= this.#rows || this.#game.grid[(row * this.#columns) + column] === 1;
	}

	#isFilledAt(x, y) {
		return this.#isFilled(Math.floor(x / tile), Math.floor(y / tile));
	}

	// The box of an atom is smaller than a tile, so its four corners find every tile that it touches.
	#isBlocked(x, y) {
		return this.#isFilledAt(x - atomRadius, y - atomRadius) || this.#isFilledAt(x + atomRadius - 0.01, y - atomRadius) || this.#isFilledAt(x - atomRadius, y + atomRadius - 0.01) || this.#isFilledAt(x + atomRadius - 0.01, y + atomRadius - 0.01);
	}

	#startLevel() {
		const game = this.#game;
		const {screen} = this.parts;
		game.grid.fill(0);
		game.cleared = 0;
		game.halves = [];
		game.lives = game.level + 1;
		game.time = levelTime(game.level);
		game.atoms = [];
		const speed = Math.min(70 + (game.level * 5), 120);

		for (let index = 0; index <= game.level; index++) {
			// Each atom starts somewhere in the room, away from the others, and goes off at 45 degrees.
			let x;
			let y;

			do {
				x = tile + (Math.random() * (screen.width - (tile * 2)));
				y = tile + (Math.random() * (screen.height - (tile * 2)));
			} while (game.atoms.some(atom => Math.hypot(atom.x - x, atom.y - y) < tile * 3));

			game.atoms.push({
				x,
				y,
				vx: speed * (Math.random() < 0.5 ? -1 : 1),
				vy: speed * (Math.random() < 0.5 ? -1 : 1),
				spin: Math.random() * Math.PI * 2,
			});
		}

		this.#showStats();
	}

	#newGame() {
		this.#game.level = 1;
		this.#game.score = 0;
		this.parts.pause.setAttribute('aria-pressed', 'false');
		this.#startLevel();
		this.#game.mode = 'ready';
		this.say(`Level 1: 2 atoms, 2 lives. Click in the room or press Space to start.${this.reducedMotion ? ' The atoms move only for a moment after each wall, key, or tap, as your computer prefers less motion.' : ''}`);
		this.#draw();
	}

	// The halves of the wall that grow, each from its first tile in one direction, until they reach a filled tile.
	#halfTiles(half) {
		return half.tiles.map((tilePosition, index) => {
			const isTip = index === half.tiles.length - 1 && !half.isDone;
			const part = isTip ? Math.min(Math.max(half.progress - index, 0), 1) : 1;
			let x = tilePosition.column * tile;
			let y = tilePosition.row * tile;
			let width = tile;
			let height = tile;

			// The tip grows out of the tile before it.
			if (half.dc !== 0) {
				width = tile * part;
				x += half.dc < 0 ? tile - width : 0;
			} else {
				height = tile * part;
				y += half.dr < 0 ? tile - height : 0;
			}

			return {x, y, width, height};
		});
	}

	#build(column, row) {
		const game = this.#game;

		if (game.halves.length > 0) {
			this.say('Wait for the wall to finish first!');
			return false;
		}

		if (this.#isFilled(column, row)) {
			this.say('That part is already filled. Build in the open part of the room.');
			return false;
		}

		const dc = game.isVertical ? 0 : 1;
		const dr = game.isVertical ? 1 : 0;
		game.halves = [
			{origin: {column, row}, dc: -dc, dr: -dr, tiles: [], progress: 0, isDone: false, color: '#ff2020'},
			{origin: {column: column + dc, row: row + dr}, dc, dr, tiles: [], progress: 0, isDone: false, color: '#2050ff'},
		];
		this.#sounds.build();
		return true;
	}

	// The parts of the room that no atom can reach fill in.
	#capture() {
		const game = this.#game;
		const columns = this.#columns;
		const reached = new Uint8Array(game.grid.length);
		const stack = [];

		for (const atom of game.atoms) {
			const index = (Math.floor(atom.y / tile) * columns) + Math.floor(atom.x / tile);

			if (game.grid[index] === 0 && reached[index] === 0) {
				reached[index] = 1;
				stack.push(index);
			}
		}

		while (stack.length > 0) {
			const index = stack.pop();
			const column = index % columns;
			const row = Math.floor(index / columns);

			for (const [dc, dr] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) {
				if (!this.#isFilled(column + dc, row + dr)) {
					const next = ((row + dr) * columns) + column + dc;

					if (reached[next] === 0) {
						reached[next] = 1;
						stack.push(next);
					}
				}
			}
		}

		let filled = 0;

		for (const [index, value] of game.grid.entries()) {
			if (value === 0 && reached[index] === 0) {
				game.grid[index] = 1;
				filled++;
			}
		}

		return filled;
	}

	#countCleared() {
		this.#game.cleared = 0;

		for (const value of this.#game.grid) {
			this.#game.cleared += value;
		}
	}

	#finishHalf(half) {
		const game = this.#game;
		half.isDone = true;

		for (const {column, row} of half.tiles) {
			game.grid[(row * this.#columns) + column] = 1;
		}

		const wallTiles = half.tiles.length;
		const filled = this.#capture();
		this.#countCleared();
		game.score += (wallTiles + filled) * game.level;

		if (filled > 0) {
			this.#sounds.done();
		}

		this.#showStats();

		if (this.#percentCleared() >= this.#goal) {
			this.#winLevel();
		} else if (filled > 40) {
			this.say(`Boxed off ${filled} tiles! ${this.#percentCleared()}% cleared, ${this.#goal}% to go… I mean, ${this.#goal}% to reach.`);
		}
	}

	#loseLife(message) {
		const game = this.#game;
		game.lives--;
		this.#sounds.broken();
		this.#showStats();

		if (game.lives <= 0) {
			this.#gameOver(message);
		} else {
			this.say(`${message} ${game.lives} ${game.lives === 1 ? 'life' : 'lives'} left.`);
		}
	}

	async #winLevel() {
		const game = this.#game;
		game.mode = 'won';
		game.halves = [];
		const percent = this.#percentCleared();
		const bonus = ((percent - this.#goal) * 50 * game.level) + (Math.ceil(game.time) * 10 * game.level);
		game.score += bonus;
		this.#updateBest();
		this.#showStats();
		this.#sounds.won();
		this.#draw();
		const text = `Level ${game.level} cleared, with ${percent}% of the room!\n\nBonus: ${bonus.toLocaleString('en-US')} points for the time left and the extra room.\n\nLevel ${game.level + 1} has ${game.level + 2} atoms.`;
		this.say(text.replaceAll('\n\n', ' '));
		await this.ask({icon: '🎉', text});

		// New Game while the message box was open already started over.
		if (game.mode !== 'won') {
			return;
		}

		game.level++;
		this.#startLevel();
		game.mode = 'ready';
		this.say(`Level ${game.level}: ${game.level + 1} atoms, ${game.lives} lives. Click in the room or press Space to start.`);
		this.#draw();
	}

	#updateBest() {
		if (this.#game.score > this.#best) {
			this.#best = this.#game.score;
			this.store('best', this.#best);
		}
	}

	async #gameOver(message) {
		const game = this.#game;
		game.mode = 'over';
		game.halves = [];
		const isRecord = game.score > this.#best;
		this.#updateBest();
		this.#showStats();
		this.#sounds.over();
		this.#draw();
		const text = `${message}\n\nGame over! You reached level ${game.level} with ${game.score.toLocaleString('en-US')} points.${isRecord ? ' A new high score!' : ''}`;
		this.say(text.replaceAll('\n\n', ' '));
		await this.ask({icon: '💥', text});
		this.say('Click in the room, or press Space, for a new game.');
	}

	#update(delta) {
		const game = this.#game;
		game.time -= delta;

		if (game.time <= 0) {
			game.halves = [];
			game.time = levelTime(game.level);
			this.#loseLife('Time’s up! The clock takes a life.');

			if (game.mode !== 'playing') {
				return;
			}
		}

		for (const atom of game.atoms) {
			atom.spin += delta * 6;
			const nextX = atom.x + (atom.vx * delta);

			if (this.#isBlocked(nextX, atom.y)) {
				atom.vx = -atom.vx;
			} else {
				atom.x = nextX;
			}

			const nextY = atom.y + (atom.vy * delta);

			if (this.#isBlocked(atom.x, nextY)) {
				atom.vy = -atom.vy;
			} else {
				atom.y = nextY;
			}
		}

		// Atoms that touch bounce off each other, like billiard balls of the same weight.
		for (const [index, first] of game.atoms.entries()) {
			for (const second of game.atoms.slice(index + 1)) {
				const dx = second.x - first.x;
				const dy = second.y - first.y;

				if (Math.hypot(dx, dy) < atomRadius * 2 && ((second.vx - first.vx) * dx) + ((second.vy - first.vy) * dy) < 0) {
					[first.vx, second.vx] = [second.vx, first.vx];
					[first.vy, second.vy] = [second.vy, first.vy];
				}
			}
		}

		for (const half of game.halves) {
			if (half.isDone) {
				continue;
			}

			half.progress += wallSpeed * delta;

			while (!half.isDone && half.tiles.length < Math.ceil(half.progress)) {
				const column = half.origin.column + (half.dc * half.tiles.length);
				const row = half.origin.row + (half.dr * half.tiles.length);

				if (this.#isFilled(column, row)) {
					this.#finishHalf(half);
				} else {
					half.tiles.push({column, row});
				}
			}

			if (game.mode !== 'playing') {
				return;
			}

			// An atom that touches the growing half breaks it, and the half is gone.
			const isHit = this.#halfTiles(half).some(box => game.atoms.some(atom => atom.x + atomRadius > box.x && atom.x - atomRadius < box.x + box.width && atom.y + atomRadius > box.y && atom.y - atomRadius < box.y + box.height));

			if (isHit) {
				half.isDone = true;
				half.tiles = [];
				this.#loseLife(`Zap! An atom broke the ${half.color === '#ff2020' ? 'red' : 'blue'} half of your wall.`);

				if (game.mode !== 'playing') {
					return;
				}
			}
		}

		if (game.halves.every(half => half.isDone)) {
			game.halves = [];
		}
	}

	#drawAtom(atom) {
		const context = this.#context;
		context.save();
		context.translate(atom.x, atom.y);
		context.rotate(this.reducedMotion ? 0 : atom.spin);
		context.fillStyle = '#ffffff';
		context.beginPath();
		context.arc(0, 0, atomRadius, 0, Math.PI * 2);
		context.fill();
		context.fillStyle = '#e01010';
		context.beginPath();
		context.arc(0, 0, atomRadius, 0, Math.PI);
		context.fill();
		context.restore();
		context.strokeStyle = '#400000';
		context.lineWidth = 1;
		context.beginPath();
		context.arc(atom.x, atom.y, atomRadius, 0, Math.PI * 2);
		context.stroke();
		context.fillStyle = 'rgb(255 255 255 / 70%)';
		context.fillRect(atom.x - 3, atom.y - 3, 2, 2);
	}

	#drawCrosshair() {
		const context = this.#context;
		const x = (this.#crosshair.column * tile) + (tile / 2);
		const y = (this.#crosshair.row * tile) + (tile / 2);
		context.strokeStyle = '#ffff00';
		context.lineWidth = 2;
		context.strokeRect(x - (tile / 2), y - (tile / 2), tile, tile);

		// The double arrow shows which way the next wall grows.
		context.beginPath();

		if (this.#game.isVertical) {
			context.moveTo(x, y - 14);
			context.lineTo(x, y + 14);
			context.moveTo(x - 4, y - 10);
			context.lineTo(x, y - 14);
			context.lineTo(x + 4, y - 10);
			context.moveTo(x - 4, y + 10);
			context.lineTo(x, y + 14);
			context.lineTo(x + 4, y + 10);
		} else {
			context.moveTo(x - 14, y);
			context.lineTo(x + 14, y);
			context.moveTo(x - 10, y - 4);
			context.lineTo(x - 14, y);
			context.lineTo(x - 10, y + 4);
			context.moveTo(x + 10, y - 4);
			context.lineTo(x + 14, y);
			context.lineTo(x + 10, y + 4);
		}

		context.stroke();
	}

	#drawBanner(title, subtitle) {
		const context = this.#context;
		context.fillStyle = 'rgb(0 0 64 / 85%)';
		context.fillRect(90, 110, 300, 80);
		context.strokeStyle = '#ffffff';
		context.lineWidth = 2;
		context.strokeRect(90, 110, 300, 80);
		context.fillStyle = '#ffff00';
		context.textAlign = 'center';
		context.font = 'bold 22px "Comic Sans MS", "Comic Sans", cursive';
		context.fillText(title, 240, 145);
		context.fillStyle = '#ffffff';
		context.font = '14px system-ui, sans-serif';
		context.fillText(subtitle, 240, 172);
	}

	#draw() {
		const context = this.#context;
		const game = this.#game;
		const {screen} = this.parts;

		// The open room is tiled in gray, like the room of JezzBall, and the cleared parts are black.
		context.fillStyle = '#000000';
		context.fillRect(0, 0, screen.width, screen.height);

		for (let row = 0; row < this.#rows; row++) {
			for (let column = 0; column < this.#columns; column++) {
				if (!this.#isFilled(column, row)) {
					context.fillStyle = (column + row) % 2 === 0 ? '#c8c8c8' : '#bdbdbd';
					context.fillRect(column * tile, row * tile, tile, tile);
					context.fillStyle = '#e8e8e8';
					context.fillRect(column * tile, row * tile, tile, 1);
					context.fillRect(column * tile, row * tile, 1, tile);
				}
			}
		}

		for (const half of game.halves) {
			context.fillStyle = half.color;

			for (const box of this.#halfTiles(half)) {
				context.fillRect(box.x, box.y, box.width, box.height);
			}
		}

		for (const atom of game.atoms) {
			this.#drawAtom(atom);
		}

		if (game.mode === 'playing' && this.#isCrosshairShown) {
			this.#drawCrosshair();
		}

		if (game.mode === 'ready') {
			this.#drawBanner(`Level ${game.level}`, `${game.level + 1} atoms. Click or press Space to start!`);
		} else if (game.mode === 'paused') {
			this.#drawBanner('Paused', 'Click the room or press P to go on.');
		} else if (game.mode === 'over') {
			this.#drawBanner('Game Over', 'Click or press Space for a new game.');
		} else if (game.mode === 'won') {
			this.#drawBanner('Level Cleared!', `${this.#percentCleared()}% of the room is yours.`);
		}
	}

	// The loop draws every frame while the game runs, so a change only needs a drawing of its own while it does not.
	#drawWhenStill() {
		if (!this.#loop.isRunning) {
			this.#draw();
		}
	}

	// With reduced motion, the room moves for half a second after an action, all at once, so nothing moves by itself.
	#nudge() {
		if (!this.reducedMotion || this.#game.mode !== 'playing') {
			return;
		}

		for (let time = 0; time < 0.5 && this.#game.mode === 'playing'; time += step) {
			this.#update(step);
		}

		this.#draw();
		this.#showStats();
	}

	#setPaused(isPaused, reason = 'Paused. Click the room or press P to go on.') {
		const game = this.#game;

		if (isPaused && game.mode === 'playing') {
			game.mode = 'paused';
			this.say(reason);
		} else if (!isPaused && game.mode === 'paused') {
			game.mode = 'playing';
			this.say(this.reducedMotion ? 'Go! The atoms move for a moment after each wall, key, or tap.' : 'Go!');
		} else {
			return;
		}

		this.parts.pause.setAttribute('aria-pressed', String(game.mode === 'paused'));
		this.#draw();
		this.#loop.start();
	}

	// A click, a tap, or Space starts the level, goes on after a pause, starts a new game after the last one, or builds a wall.
	#act(column, row) {
		const game = this.#game;

		if (game.mode === 'won') {
			return;
		}

		if (game.mode === 'over') {
			this.#newGame();
			return;
		}

		if (game.mode === 'ready') {
			game.mode = 'playing';
			this.say(this.reducedMotion ? 'Go! The atoms move for half a second after each wall, key, or tap, as your computer prefers less motion.' : 'Go! Box in the atoms.');
			this.#draw();
			this.#loop.start();
			this.#nudge();
			return;
		}

		if (game.mode === 'paused') {
			this.#setPaused(false);
			return;
		}

		this.#build(column, row);
		this.#nudge();
		this.#draw();
	}

	#turn() {
		const game = this.#game;
		const {turn} = this.parts;
		game.isVertical = !game.isVertical;
		turn.textContent = game.isVertical ? '↕ Up and Down' : '↔ Across';
		turn.setAttribute('aria-label', `Wall direction: ${game.isVertical ? 'up and down' : 'across'}. Click to turn it.`);
		this.#draw();
	}

	#tileAt(event) {
		const box = this.parts.screen.getBoundingClientRect();
		return {
			column: Math.min(Math.max(Math.floor(((event.clientX - box.left) / box.width) * this.#columns), 0), this.#columns - 1),
			row: Math.min(Math.max(Math.floor(((event.clientY - box.top) / box.height) * this.#rows), 0), this.#rows - 1),
		};
	}

	#keyDown(event) {
		if (event.ctrlKey || event.altKey || event.metaKey) {
			return;
		}

		const move = {ArrowLeft: [-1, 0], ArrowRight: [1, 0], ArrowUp: [0, -1], ArrowDown: [0, 1]}[event.key];

		if (move) {
			event.preventDefault();
			const distance = event.shiftKey ? 4 : 1;
			this.#crosshair = {
				column: Math.min(Math.max(this.#crosshair.column + (move[0] * distance), 0), this.#columns - 1),
				row: Math.min(Math.max(this.#crosshair.row + (move[1] * distance), 0), this.#rows - 1),
			};
			this.#isCrosshairShown = true;
			this.#drawWhenStill();
		} else if (event.key === ' ' || event.key === 'Enter') {
			event.preventDefault();

			if (!event.repeat) {
				this.#isCrosshairShown = true;
				this.#act(this.#crosshair.column, this.#crosshair.row);
			}
		} else if (event.key === 'r' || event.key === 'R') {
			event.preventDefault();
			this.#turn();
			this.#nudge();
		} else if (event.key === 'p' || event.key === 'P') {
			event.preventDefault();
			this.#setPaused(this.#game.mode === 'playing');
		}
	}
}
