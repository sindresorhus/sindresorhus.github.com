// Sindre’s Quest for the Golden Waffle on the 1999 page, a point-and-click adventure like the games of LucasArts and Sierra in the 1990s, with verbs, an inventory, conversations, deaths, saves, and a hint line, and its box, its manual, its copy protection, and its four floppy disks. The canvas runs only while it is on the screen and the tab is visible. Saved games are kept in the browser. The sound button turns on the sound of the other adventure games of the page too (WAFFLE QUEST, Insult Seagull Fighting, and the linking book), with the `geocities-adventure-sound` event.
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

// The position of a pointer on a canvas, in the pixels of the canvas.
const canvasPoint = (canvas, event) => {
	const rectangle = canvas.getBoundingClientRect();
	return {
		x: (event.clientX - rectangle.left) * canvas.width / rectangle.width,
		y: (event.clientY - rectangle.top) * canvas.height / rectangle.height,
	};
};

// Shapes for the canvases of the games.
const fillShape = (context, color, x, y, width, height) => {
	context.fillStyle = color;
	context.fillRect(Math.round(x), Math.round(y), Math.round(width), Math.round(height));
};

const fillEllipse = (context, color, x, y, radiusX, radiusY) => {
	context.fillStyle = color;
	context.beginPath();
	context.ellipse(x, y, Math.max(radiusX, 0.1), Math.max(radiusY, 0.1), 0, 0, Math.PI * 2);
	context.fill();
};

const fillPolygon = (context, color, points) => {
	context.fillStyle = color;
	context.beginPath();
	for (const [x, y] of points) {
		context.lineTo(x, y);
	}

	context.closePath();
	context.fill();
};

const makeCanvas = (width, height) => {
	const canvas = document.createElement('canvas');
	canvas.width = width;
	canvas.height = height;
	return canvas;
};

// A tiny pixel font of 3 × 5 for the screens of the toys, so the text is crisp at any size. Each letter is five rows of three bits.
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

const pixelTextWidth = (text, scale = 1) => (([...String(text)].length * 4) - 1) * scale;

// A short sound effect, made in the browser.
const beep = (audio, frequency, duration = 0.1, {type = 'square', volume = 0.05, when = 0} = {}) => {
	if (audio?.context.state !== 'running') {
		return;
	}

	const start = audio.context.currentTime + when;
	const oscillator = new OscillatorNode(audio.context, {type, frequency});
	const gain = new GainNode(audio.context, {gain: 0});
	gain.gain.setValueAtTime(0, start);
	gain.gain.linearRampToValueAtTime(volume, start + 0.005);
	gain.gain.exponentialRampToValueAtTime(0.0001, start + duration);
	oscillator.connect(gain).connect(audio.output);
	oscillator.start(start);
	oscillator.stop(start + duration + 0.02);
};

// The colors of the pixel art, by the letter that the sprites use for them, a palette like the 256 colors of VGA.
const palette = {
	k: '#000000',
	w: '#ffffff',
	s: '#f4c49c',
	S: '#d8956a',
	h: '#f2d16b',
	H: '#c99a36',
	b: '#2a5bd7',
	B: '#1b3a8a',
	j: '#ffd400',
	J: '#c9a400',
	r: '#d42a2a',
	R: '#8a1414',
	g: '#3fa34d',
	G: '#1f5c2a',
	n: '#8b5a2b',
	N: '#5a3519',
	e: '#8a8a8a',
	E: '#4a4a4a',
	l: '#c8c8c8',
	o: '#ff8c1a',
	p: '#ff8fc8',
	P: '#7a3fb0',
	y: '#ffd700',
	Y: '#b8860b',
	c: '#7fd4ff',
	t: '#8fa86a',
	T: '#5d7a45',
	m: '#b07a3a',
	u: '#9a9aa8',
	U: '#5c5c6a',
};

// Draws a sprite of letters, one letter a pixel and a dot for nothing, at a scale, with its feet at `y`, facing right, or left when it is flipped. The colors can be swapped, like the shirt of Sindre for his rain jacket.
const drawSprite = (context, rows, x, y, {scale = 2, isFlipped = false, colors = {}} = {}) => {
	const width = rows[0].length;
	const top = Math.round(y - (rows.length * scale));
	const left = Math.round(x - (width * scale / 2));
	for (const [row, line] of rows.entries()) {
		for (let column = 0; column < width; column++) {
			const letter = line[isFlipped ? width - 1 - column : column];
			if (letter === '.') {
				continue;
			}

			context.fillStyle = colors[letter] ?? palette[letter];
			context.fillRect(left + (column * scale), top + (row * scale), scale, scale);
		}
	}
};

// The people and animals of Sindre's Quest, as sprites that face right.
const sprites = {
	sindre: [
		'...hhh...',
		'..hhhhhh.',
		'.hhhhhhh.',
		'.hhsssss.',
		'.hsssksk.',
		'.hsssssss',
		'..sssSss.',
		'...ssss..',
		'..bbbbb..',
		'.bbbbbbb.',
		'.bbbbbbb.',
		'sbbbbbbbs',
		's.bbbbb.s',
		'..bbbbb..',
		'..BBBBB..',
		'..BB.BB..',
		'..BB.BB..',
		'..BB.BB..',
		'..kkk.kkk',
	],
	sindreStep: [
		'..BBBBB..',
		'.BB...BB.',
		'BB.....BB',
		'kkk....kkk',
	],
	mamma: [
		'...nnn...',
		'..nnnnn..',
		'.nnsssnn.',
		'.nskssk..',
		'.nsssssn.',
		'.nssrssn.',
		'.nnsssnn.',
		'.n.sss.n.',
		'..ppppp..',
		'.ppppppp.',
		'ppppppppp',
		's.ppppp.s',
		's.ppppp.s',
		'..ppppp..',
		'..bbbbb..',
		'..bbbbb..',
		'..bb.bb..',
		'..bb.bb..',
		'..bb.bb..',
		'..bb.bb..',
		'..rr.rr..',
	],
	mormor: [
		'...lll...',
		'..lllll..',
		'..lllll..',
		'.lsssssl.',
		'.ekeseke.',
		'.lsssssl.',
		'..ssrss..',
		'...sss...',
		'..PPPPP..',
		'.PPwwwPP.',
		'PPPwwwPPP',
		's.PwwwP.s',
		's.PwwwP.s',
		'..PwwwP..',
		'.PPPPPPP.',
		'.PPPPPPP.',
		'.PPPPPPP.',
		'...s.s...',
		'..kk.kk..',
	],
	kevin: [
		'..rrrrr..',
		'.rrrrrrrr',
		'..nnnnn..',
		'.nsssssn.',
		'.ekkekke.',
		'.nsssssn.',
		'..ssSss..',
		'...sss...',
		'..ggggg..',
		'.ggggggg.',
		'ggggggggg',
		's.ggggg.s',
		's.ggggg.s',
		'..ggggg..',
		'..BBBBB..',
		'..BB.BB..',
		'..BB.BB..',
		'..BB.BB..',
		'..ww.ww..',
	],
	fishmonger: [
		'..bbbbb..',
		'.bbbbbbb.',
		'.nsssssn.',
		'.nskssk..',
		'.nsssssn.',
		'.nnnnnnn.',
		'..nnnnn..',
		'...nnn...',
		'..wwwww..',
		'.wwwwwww.',
		'swwwwwwws',
		's.wwwww.s',
		's.wwwww.s',
		'..wwwww..',
		'..wwwww..',
		'..BB.BB..',
		'..BB.BB..',
		'..kk.kk..',
	],
	conductor: [
		'..RRRRR..',
		'.RRyRRRR.',
		'.RRRRRRRR',
		'..sssss..',
		'..skssk..',
		'..sssss..',
		'...srs...',
		'...sss...',
		'..RRRRR..',
		'.RRyRyRR.',
		'RRRRRRRRR',
		's.RRRRR.s',
		's.RRRRR.s',
		'..RRRRR..',
		'..kkkkk..',
		'..kk.kk..',
		'..kk.kk..',
		'..kk.kk..',
		'..kk.kk..',
	],
	troll: [
		'.....GG.GG.......',
		'....GGGGGGG......',
		'...TTTTTTTTT.....',
		'..TTTTTTTTTTT....',
		'..TTwkTTTwkTT....',
		'..TTkkTTTkkTT....',
		'..TTTTTTTTTTTtt..',
		'..TTTTTTTTTTttttt',
		'..TTTTTTTTTTTtttt',
		'...TTkkkkkkTT....',
		'...TTkwkkkkTT....',
		'....TTTTTTTT.....',
		'...nnnnnnnnnn....',
		'..nnnnnnnnnnnn...',
		'.TnnnnnnnnnnnnT..',
		'TTnnnnnnnnnnnnTT.',
		'TT.nnnnnnnnnn.TT.',
		'TT.nnnnnnnnnn.TT.',
		'TT.NNNNNNNNNN.TT.',
		'TT.nnnnnnnnnn.TT.',
		'...nnnnnnnnnn....',
		'...TTTT..TTTT....',
		'...TTTT..TTTT....',
		'...TTTT..TTTT....',
		'..TTTTT..TTTTT...',
		'..TTTTT..TTTTT...',
	],
	seagull: [
		'..www.....',
		'.wwkww....',
		'oowwww....',
		'..wwwwwwll',
		'..wwwwwlll',
		'...wwwwll.',
		'....o.o...',
	],
	glitter: [
		'.......y..',
		'......yy..',
		'.....pwp..',
		'....pwwkw.',
		'...ppwwwww',
		'..pp.wwww.',
		'.wwwwwww..',
		'wwwwwwww..',
		'.w.w.w.w..',
	],
};

// The things of the inventory, drawn as pictures of 16 × 16 pixels.
const itemIcons = {
	jacket(context) {
		fillPolygon(context, palette.j, [[4, 2], [12, 2], [15, 7], [13, 8], [13, 15], [3, 15], [3, 8], [1, 7]]);
		fillShape(context, palette.J, 7, 3, 2, 12);
		fillShape(context, palette.k, 9, 6, 1, 1);
		fillShape(context, palette.k, 9, 9, 1, 1);
		fillShape(context, palette.k, 9, 12, 1, 1);
	},
	piggy(context) {
		fillEllipse(context, palette.p, 8, 9, 6.5, 4.5);
		fillShape(context, palette.p, 4, 12, 2, 3);
		fillShape(context, palette.p, 10, 12, 2, 3);
		fillPolygon(context, palette.p, [[4, 6], [6, 2], [7, 6]]);
		fillEllipse(context, '#ffb8de', 14, 9, 1.5, 1.5);
		fillShape(context, palette.k, 11, 7, 1, 1);
		fillShape(context, palette.k, 6, 5, 4, 1);
	},
	coins(context) {
		fillEllipse(context, palette.Y, 6, 10, 4.5, 4.5);
		fillEllipse(context, palette.y, 6, 10, 3.5, 3.5);
		fillEllipse(context, palette.Y, 11, 6, 4.5, 4.5);
		fillEllipse(context, palette.y, 11, 6, 3.5, 3.5);
		fillShape(context, palette.Y, 10, 4, 2, 4);
	},
	cd(context) {
		fillEllipse(context, '#d8d8e8', 8, 8, 7, 7);
		fillEllipse(context, '#ff9ae0', 6, 6, 3, 2);
		fillEllipse(context, '#9ae0ff', 10, 10, 3, 2);
		fillEllipse(context, '#1a3a8a', 8, 8, 2, 2);
		fillEllipse(context, '#000000', 8, 8, 1, 1);
	},
	slicer(context) {
		fillShape(context, palette.n, 7, 8, 2, 7);
		fillPolygon(context, palette.l, [[3, 2], [13, 2], [12, 8], [4, 8]]);
		fillShape(context, palette.E, 5, 5, 6, 1);
	},
	cheese(context) {
		fillPolygon(context, '#a0521e', [[2, 6], [10, 3], [14, 6], [14, 13], [2, 13]]);
		fillPolygon(context, '#c86f2e', [[2, 6], [10, 3], [14, 6], [6, 9]]);
		fillShape(context, '#7a3a12', 2, 12, 12, 1);
	},
	slices(context) {
		for (const [index, top] of [12, 9, 6, 3].entries()) {
			fillPolygon(context, index % 2 === 0 ? '#c86f2e' : '#a0521e', [[2, top + 2], [5, top], [14, top], [11, top + 2]]);
		}
	},
	fishhead(context) {
		fillPolygon(context, palette.u, [[2, 8], [9, 2], [14, 5], [14, 11], [9, 14]]);
		fillEllipse(context, palette.w, 6, 7, 2, 2);
		fillShape(context, palette.k, 6, 7, 1, 1);
		fillShape(context, palette.r, 11, 4, 1, 8);
		fillShape(context, palette.U, 3, 9, 4, 1);
	},
	ticket(context) {
		fillShape(context, palette.r, 1, 4, 14, 8);
		fillShape(context, palette.w, 3, 6, 7, 1);
		fillShape(context, palette.w, 3, 8, 5, 1);
		fillShape(context, palette.y, 11, 5, 3, 6);
	},
	waffle(context) {
		fillEllipse(context, palette.Y, 8, 8, 7, 7);
		fillEllipse(context, palette.y, 8, 8, 6, 6);
		for (let line = 3; line < 14; line += 3) {
			fillShape(context, palette.Y, line, 2, 1, 12);
			fillShape(context, palette.Y, 2, line, 12, 1);
		}

		fillShape(context, palette.k, 14, 7, 2, 2);
	},
};

export default class extends GeoCitiesElement {
	#game;
	#isSoundOn = false;

	connected() {
		// The sound button of Sindre’s Quest turns the sound on and off for all the adventure games of the page.
		this.on(document, 'geocities-adventure-sound', event => {
			this.#isSoundOn = event.detail.isOn;
		});

		this.#game = this.#setUpGame();
		this.#setUpBox();
	}

	// The game runs only while its scene is on the screen, not while only the box or the manual is.
	get visibilityTarget() {
		return this.parts.scene;
	}

	visibilityChanged(isVisible) {
		this.#game.visibilityChanged(isVisible);
	}

	reducedMotionChanged() {
		this.#game.reducedMotionChanged();
	}

	// The audio is made at the first sound, in the click or the key press that makes it, as browsers only let audio start then.
	#beep(...options) {
		if (this.#isSoundOn) {
			beep(this.sound(), ...options);
		}
	}

	// Sindre's Quest for the Golden Waffle, a point-and-click adventure like the games of LucasArts: pick a verb, then click a thing in the scene, and Sindre walks there and does it. Things in the inventory go together with Use. The people talk, and the visitor picks what Sindre says from a list. The score and three saved games are kept in the browser.
	#setUpGame() {
		const {
			scene: canvas,
			speech,
			sentence,
			score: scoreLabel,
			verbs: verbBar,
			inventory,
			emptyInventory,
			choices,
			titleScreen,
			start: startButton,
			copyProtection: copyForm,
			copyQuestion,
			copyAnswer,
			copyStatus,
			death: deathPanel,
			deathText,
			saves: savesPanel,
			savesTitle,
			hintLine: hintPanel,
			hintText,
			hintBill,
			game: gameWindow,
		} = this.parts;
		const context = canvas.getContext('2d');
		const verbButtons = [...this.querySelectorAll('[data-adventure-verb]')];
		const itemButtons = [...this.querySelectorAll('[data-adventure-item]')];
		const choiceButtons = [...this.querySelectorAll('[data-part="choice"]')];
		const slotButtons = [...this.querySelectorAll('[data-part="slot"]')];
		const soundButton = this.querySelector('[data-adventure-action="sound"]');

		const beep = (...options) => {
			this.#beep(...options);
		};

		const width = canvas.width;
		const height = canvas.height;
		const floor = 152;

		const verbNames = Object.fromEntries(verbButtons.map(button => [button.dataset.adventureVerb, button.textContent.trim()]));
		const itemNames = Object.fromEntries(itemButtons.map(button => [button.dataset.adventureItem, button.textContent.trim()]));

		for (const button of itemButtons) {
			itemIcons[button.dataset.adventureItem]?.(button.querySelector('canvas').getContext('2d'));
		}

		const newState = () => ({
			scene: 'title',
			x: 160,
			isFacingLeft: false,
			items: [],
			flags: {},
			points: {},
		});

		let state = newState();
		let retryState;
		let verb = 'walk';
		let firstItem;
		let hovered;
		let focusIndex = -1;
		let isBusy = false;
		let isOver = false;
		let walkTarget;
		let walkDone;
		let skipLine;
		let lineSpeaker;
		let step = 0;
		let hintStep = 0;
		let bill = this.stored('bill', 0);

		const score = () => {
			let total = 0;
			for (const points of Object.values(state.points)) {
				total += points;
			}

			return total;
		};
		const has = item => state.items.includes(item);
		const flag = name => Boolean(state.flags[name]);

		const award = (key, points) => {
			if (state.points[key] === undefined) {
				state.points[key] = points;
				beep(880, 0.08);
				beep(1320, 0.12, {when: 0.08});
				updateScore();
			}
		};

		const updateScore = () => {
			scoreLabel.textContent = `Score: ${score()} of 100`;
		};

		const addItem = item => {
			if (!has(item)) {
				state.items.push(item);
			}

			updateInventory();
		};

		const removeItem = item => {
			state.items = state.items.filter(other => other !== item);
			if (firstItem === item) {
				firstItem = undefined;
			}

			updateInventory();
		};

		const updateInventory = () => {
			for (const button of itemButtons) {
				const item = button.dataset.adventureItem;
				const isHidden = !has(item);
				if (isHidden && button === document.activeElement) {
					canvas.focus({preventScroll: true});
				}

				button.hidden = isHidden;
				setPressed(button, item === firstItem);
			}

			emptyInventory.hidden = state.items.length > 0;
		};

		// Says a line in the color of whoever says it, at the top of the scene, until it was there long enough to read, or the visitor skips it with a click or the period key, like in the LucasArts games.
		const say = async (speaker, text) => {
			lineSpeaker = speaker;
			speech.dataset.state = speaker;
			speech.textContent = speaker === 'sindre' || speaker === 'narrator' ? text : `${speakerNames[speaker]}: ${text}`;
			beep(speaker === 'troll' ? 110 : (speaker === 'seagull' ? 1400 : 440), 0.03, {volume: 0.02});
			await Promise.race([
				this.wait(clamp(900 + (text.length * 55), 1800, 7000)),
				new Promise(resolve => {
					skipLine = resolve;
				}),
			]);
			skipLine = undefined;
			lineSpeaker = undefined;
			speech.textContent = '';
		};

		const speakerNames = {
			mamma: 'Mamma',
			mormor: 'Mormor',
			kevin: 'Kevin',
			troll: 'Troll',
			seagull: 'Seagull',
			fishmonger: 'Fishmonger',
			glitter: 'Glitter',
			conductor: 'Conductor',
		};

		// Sindre walks to a place on the floor of the scene, or is there at once with reduced motion.
		const walkTo = x => {
			const target = clamp(x, 14, width - 14);
			if (Math.abs(target - state.x) < 2) {
				return Promise.resolve();
			}

			state.isFacingLeft = target < state.x;
			if (this.reducedMotion || !loop.isVisible) {
				state.x = target;
				return Promise.resolve();
			}

			walkDone?.();
			walkTarget = target;
			loop.start();
			return new Promise(resolve => {
				walkDone = resolve;
			});
		};

		// The visitor picks what Sindre says from a list, in place of the verbs and the inventory, like the conversations of Monkey Island.
		const choose = options => new Promise(resolve => {
			const hadFocus = gameWindow.contains(document.activeElement);
			verbBar.hidden = true;
			inventory.hidden = true;
			choices.hidden = false;
			for (const [index, button] of choiceButtons.entries()) {
				const option = options[index];
				button.hidden = !option;
				button.textContent = option?.text ?? '';
				button.onclick = option ? () => {
					const wasInChoices = choices.contains(document.activeElement);
					choices.hidden = true;
					verbBar.hidden = false;
					inventory.hidden = false;
					if (wasInChoices) {
						canvas.focus({preventScroll: true});
					}

					resolve(option);
				} : undefined;
			}

			if (hadFocus) {
				choiceButtons[0].focus({preventScroll: true});
			}
		});

		// A conversation: the visitor picks lines until one ends it. Each line is said by Sindre, then the answer runs.
		const converse = async getOptions => {
			while (true) {
				const option = await choose(getOptions().filter(Boolean));
				await say('sindre', option.text);
				const isDone = await option.answer();
				if (isDone || option.isGoodbye) {
					return;
				}
			}
		};

		const goodbye = (text, speaker, answer) => ({
			text,
			isGoodbye: true,
			answer: () => say(speaker, answer),
		});

		// A death, like in the games of Sierra: a window with what went wrong, and Try Again puts the visitor back to just before.
		const die = async text => {
			beep(220, 0.2, {type: 'sawtooth'});
			beep(165, 0.3, {type: 'sawtooth', when: 0.2});
			beep(110, 0.5, {type: 'sawtooth', when: 0.5});
			state.flags.isDead = true;
			await showPanel(deathPanel);
			this.say(`${text} Thank you for playing Sindre’s Quest. Better luck next time!`, deathText);
			deathPanel.querySelector('button').focus({preventScroll: true});
		};

		// Ends a walk at once, like when the scene changes or a game is loaded.
		const stopWalking = () => {
			walkTarget = undefined;
			walkDone?.();
			walkDone = undefined;
		};

		const go = async (scene, x) => {
			state.scene = scene;
			state.x = x;
			stopWalking();
			hovered = undefined;
			focusIndex = -1;
			draw();
			// The rain of the new scene may need the loop, which stops on the scenes where nothing moves.
			loop.start();
		};

		// The backgrounds of the scenes, drawn once into canvases of their own, as they do not move.
		const backgrounds = {};

		const sky = (target, top, bottom, to = 160) => {
			const gradient = target.createLinearGradient(0, 0, 0, to);
			gradient.addColorStop(0, top);
			gradient.addColorStop(1, bottom);
			target.fillStyle = gradient;
			target.fillRect(0, 0, width, to);
		};

		const planks = (target, top, color, line) => {
			fillShape(target, color, 0, top, width, height - top);
			for (let y = top; y < height; y += 6) {
				fillShape(target, line, 0, y, width, 1);
				for (let x = ((y / 6) % 2) * 20; x < width; x += 40) {
					fillShape(target, line, x, y, 1, 6);
				}
			}
		};

		const windowPane = (target, x, y, paneWidth, paneHeight, glass = '#26334d') => {
			fillShape(target, '#f0ece0', x - 1, y - 1, paneWidth + 2, paneHeight + 2);
			fillShape(target, glass, x, y, paneWidth, paneHeight);
			fillShape(target, '#f0ece0', x + Math.floor(paneWidth / 2), y, 1, paneHeight);
			fillShape(target, '#f0ece0', x, y + Math.floor(paneHeight / 2), paneWidth, 1);
		};

		const gableHouse = (target, x, houseWidth, color, dark, top = 40) => {
			const peak = top - 22;
			fillPolygon(target, dark, [[x - 2, top + 1], [x + (houseWidth / 2), peak - 2], [x + houseWidth + 2, top + 1]]);
			fillPolygon(target, color, [[x, top], [x + (houseWidth / 2), peak], [x + houseWidth, top]]);
			fillShape(target, color, x, top, houseWidth, 118 - top);
			for (let line = top + 3; line < 118; line += 4) {
				fillShape(target, dark, x, line, houseWidth, 1);
			}

			windowPane(target, x + (houseWidth / 2) - 3, peak + 10, 6, 6);
			for (const row of [top + 8, top + 30, top + 52]) {
				windowPane(target, x + 4, row, 7, 10);
				windowPane(target, x + houseWidth - 11, row, 7, 10);
			}
		};

		const pine = (target, x, y, size) => {
			fillShape(target, '#3a2a1a', x - 1, y - 4, 3, 5);
			for (let layer = 0; layer < 3; layer++) {
				const bottom = y - 4 - (size * layer * 0.5);
				const halfWidth = size * (1 - (layer * 0.22));
				fillPolygon(target, layer % 2 === 0 ? '#1f4a2a' : '#245a32', [[x - halfWidth, bottom], [x, bottom - (size * 0.9)], [x + halfWidth, bottom]]);
			}
		};

		const sign = (target, x, y, text, color = '#ffffff', board = '#6a4a2a') => {
			const signWidth = pixelTextWidth(text) + 6;
			fillShape(target, board, x - (signWidth / 2), y, signWidth, 9);
			drawPixelText(target, text, x, y + 2, color, {align: 'center'});
		};

		// The sign to the map of Bergen, at the left edge of the scenes in town.
		const mapArrow = target => {
			fillShape(target, '#5a3a1a', 9, 104, 3, 46);
			fillPolygon(target, '#e8d8a8', [[2, 100], [22, 100], [26, 106], [22, 112], [2, 112]]);
			drawPixelText(target, 'MAP', 4, 104, '#5a3a1a');
		};

		const drawBackground = {
			title(target) {
				sky(target, '#0a0a2a', '#5a2a5a');
				for (let index = 0; index < 40; index++) {
					fillShape(target, '#ffffff', (index * 73) % width, (index * 37) % 70, 1, 1);
				}

				fillPolygon(target, '#14142a', [[0, 120], [40, 70], [80, 95], [130, 50], [190, 90], [240, 60], [320, 100], [320, 160], [0, 160]]);
				for (let x = 0; x < width; x += 12) {
					fillShape(target, '#1e1e3a', x, 118 - ((x * 7) % 14), 10, 50);
					fillShape(target, '#ffd27a', x + 3, 124 - ((x * 7) % 14), 2, 2);
				}

				drawPixelText(target, 'SINDRE\'S QUEST', 162, 22, '#8a2000', {scale: 4, align: 'center'});
				drawPixelText(target, 'SINDRE\'S QUEST', 160, 20, '#ffd700', {scale: 4, align: 'center'});
				drawPixelText(target, 'FOR THE GOLDEN WAFFLE', 160, 46, '#ffeeaa', {scale: 2, align: 'center'});
				drawPixelText(target, '(C) 1999 SINDRESOFT', 160, 60, '#b0a0c0', {align: 'center'});
				drawSprite(target, sprites.sindre, 120, 116, {scale: 2, colors: {b: palette.j}});
				drawSprite(target, sprites.troll, 200, 116, {scale: 2, isFlipped: true});
				drawSprite(target, sprites.seagull, 250, 96, {scale: 2, isFlipped: true});
			},
			room(target) {
				fillShape(target, '#8fb3d9', 0, 0, width, 120);
				for (let x = 4; x < width; x += 16) {
					fillShape(target, '#9cc0e4', x, 0, 4, 120);
				}

				fillShape(target, '#e8e0d0', 0, 114, width, 6);
				planks(target, 120, '#b07a3a', '#8b5a2b');
				// The door, open to the hall, where Mamma stands.
				fillShape(target, '#e8e0d0', 4, 30, 40, 90);
				fillShape(target, '#3a2e24', 8, 34, 32, 86);
				fillShape(target, '#5a4636', 8, 100, 32, 20);
				// The wardrobe.
				fillShape(target, '#7a4f24', 48, 26, 50, 94);
				fillShape(target, '#a0703a', 50, 28, 46, 90);
				fillShape(target, '#7a4f24', 72, 28, 2, 90);
				fillShape(target, '#e8c050', 69, 70, 2, 4);
				fillShape(target, '#e8c050', 75, 70, 2, 4);
				// The window, with red curtains.
				windowPane(target, 110, 26, 46, 52, '#4a5a78');
				fillShape(target, '#c03030', 104, 22, 8, 62);
				fillShape(target, '#c03030', 154, 22, 8, 62);
				fillShape(target, '#e8e0d0', 102, 20, 62, 3);
				// The desk, with the iMac and its keyboard.
				fillShape(target, '#c89858', 164, 90, 78, 5);
				fillShape(target, '#8b5a2b', 168, 95, 4, 25);
				fillShape(target, '#8b5a2b', 234, 95, 4, 25);
				fillEllipse(target, '#0095b6', 197, 74, 16, 15);
				fillEllipse(target, '#3ab8d8', 193, 70, 10, 9);
				fillShape(target, '#d8f0ff', 186, 64, 22, 16);
				fillShape(target, '#2a5bd7', 188, 66, 18, 3);
				fillShape(target, '#90a0b0', 188, 71, 12, 1);
				fillShape(target, '#90a0b0', 188, 74, 15, 1);
				fillShape(target, '#e8f4f8', 192, 86, 10, 4);
				fillShape(target, '#bfe8f4', 176, 87, 16, 3);
				// The bed, with a blue blanket with stars.
				fillShape(target, '#8b5a2b', 244, 94, 6, 30);
				fillShape(target, '#8b5a2b', 312, 104, 6, 20);
				fillShape(target, '#f4f4f4', 248, 102, 66, 8);
				fillShape(target, '#3a5ad0', 262, 104, 52, 16);
				for (let x = 266; x < 312; x += 8) {
					fillShape(target, '#ffd700', x, 110, 2, 2);
				}

				fillShape(target, '#ffffff', 250, 98, 14, 8);
				// The poster of a unicorn and a rainbow.
				fillShape(target, '#ffffff', 252, 22, 50, 40);
				fillShape(target, '#5a2a8a', 254, 24, 46, 36);
				target.lineWidth = 2;
				for (const [index, color] of ['#ff3030', '#ff9a30', '#ffe030', '#30c030', '#3080ff'].entries()) {
					target.strokeStyle = color;
					target.beginPath();
					target.arc(277, 60, 20 - (index * 2), Math.PI, Math.PI * 2);
					target.stroke();
				}

				drawSprite(target, sprites.glitter, 277, 58, {scale: 1});
			},
			map(target) {
				fillShape(target, '#e8d8a8', 0, 0, width, height);
				fillPolygon(target, '#5a8ac8', [[0, 0], [150, 0], [170, 40], [130, 70], [150, 100], [90, 130], [60, 160], [0, 160]]);
				for (const [x, y] of [[40, 30], [70, 60], [30, 100], [90, 20]]) {
					fillShape(target, '#8ab0e0', x, y, 8, 1);
					fillShape(target, '#8ab0e0', x + 4, y + 3, 8, 1);
				}

				fillPolygon(target, '#5a8a4a', [[220, 0], [320, 0], [320, 90], [290, 70], [250, 40]]);
				fillPolygon(target, '#3a6a3a', [[240, 30], [270, 4], [300, 30]]);
				fillPolygon(target, '#3a6a3a', [[280, 50], [305, 20], [320, 46]]);
				target.strokeStyle = '#c8a878';
				target.lineWidth = 3;
				target.beginPath();
				target.moveTo(150, 50);
				target.lineTo(200, 88);
				target.lineTo(265, 112);
				target.moveTo(200, 88);
				target.lineTo(170, 128);
				target.stroke();
				target.strokeStyle = '#7a5a3a';
				target.lineWidth = 1;
				target.setLineDash([2, 2]);
				target.beginPath();
				target.moveTo(200, 88);
				target.lineTo(268, 18);
				target.stroke();
				target.setLineDash([]);
				drawPixelText(target, 'FLOYEN', 270, 36, '#e8f0d8', {align: 'center'});
				drawPixelText(target, 'BERGEN 1999', 316, 150, '#7a5a3a', {align: 'right'});
				drawPixelText(target, 'VAGEN', 60, 70, '#e0f0ff', {align: 'center'});
				// A compass rose, like on every map in an adventure game.
				fillPolygon(target, '#7a5a3a', [[300, 98], [303, 108], [300, 106], [297, 108]]);
				drawPixelText(target, 'N', 299, 90, '#7a5a3a');
			},
			bryggen(target) {
				sky(target, '#6a7a90', '#a8b4c4', 60);
				fillPolygon(target, '#4a6a4a', [[0, 40], [60, 14], [130, 30], [200, 8], [280, 26], [320, 18], [320, 60], [0, 60]]);
				const houses = [['#b8322a', '#8a2018'], ['#e0b040', '#b08020'], ['#e8e4d8', '#b8b4a8'], ['#c87a2a', '#9a5a1a'], ['#b8322a', '#8a2018'], ['#e8e4d8', '#b8b4a8'], ['#e0b040', '#b08020'], ['#c87a2a', '#9a5a1a']];
				for (const [index, [color, dark]] of houses.entries()) {
					gableHouse(target, 2 + (index * 40), 36, color, dark, 44 + ((index % 3) * 4));
				}

				planks(target, 118, '#7a6a5a', '#5a4a3a');
				fillShape(target, '#2a4a6a', 0, 154, width, 6);
				fillShape(target, '#4a6a8a', 0, 154, width, 1);
				mapArrow(target);
			},
			school(target) {
				sky(target, '#7a8aa0', '#b0bccb', 100);
				fillPolygon(target, '#5a7a5a', [[0, 70], [80, 40], [160, 60], [240, 30], [320, 56], [320, 110], [0, 110]]);
				fillShape(target, '#a04a3a', 50, 24, 220, 90);
				for (let y = 26; y < 114; y += 4) {
					fillShape(target, '#8a3a2a', 50, y, 220, 1);
					for (let x = 50 + ((y / 4) % 2) * 6; x < 270; x += 12) {
						fillShape(target, '#8a3a2a', x, y, 1, 4);
					}
				}

				fillShape(target, '#5a2a2a', 46, 20, 228, 6);
				for (const x of [60, 92, 124, 180, 212, 244]) {
					windowPane(target, x, 40, 18, 22, '#5a6a88');
					windowPane(target, x, 76, 18, 22, '#5a6a88');
				}

				fillShape(target, '#5a3a2a', 150, 70, 22, 44);
				fillShape(target, '#e8c050', 167, 92, 2, 3);
				sign(target, 161, 30, 'SKOLE', '#ffffff', '#2a3a6a');
				fillShape(target, '#6a6a6a', 0, 114, width, 46);
				target.strokeStyle = '#e8e8e8';
				target.lineWidth = 1;
				for (const [index, x] of [70, 82, 94, 106].entries()) {
					target.strokeRect(x + 0.5, 132.5 - ((index % 2) * 6), 11, 11);
				}

				// The bike rack, with Kevin's bike of 21 gears.
				target.strokeStyle = '#c8c8c8';
				for (let x = 270; x < 316; x += 8) {
					target.beginPath();
					target.arc(x, 132, 4, Math.PI, Math.PI * 2);
					target.stroke();
				}

				target.strokeStyle = '#2a2a2a';
				target.lineWidth = 2;
				target.beginPath();
				target.arc(282, 140, 7, 0, Math.PI * 2);
				target.moveTo(309, 140);
				target.arc(302, 140, 7, 0, Math.PI * 2);
				target.stroke();
				target.strokeStyle = '#d42a2a';
				target.beginPath();
				target.moveTo(282, 140);
				target.lineTo(290, 130);
				target.lineTo(302, 140);
				target.moveTo(290, 130);
				target.lineTo(300, 130);
				target.stroke();
				mapArrow(target);
			},
			fishmarket(target) {
				sky(target, '#6a7a90', '#a8b4c4', 90);
				fillPolygon(target, '#3e6a3e', [[150, 90], [230, 20], [270, 4], [320, 10], [320, 90]]);
				fillPolygon(target, '#2e5a32', [[250, 30], [270, 4], [292, 24]]);
				target.strokeStyle = '#2a2a2a';
				target.lineWidth = 2;
				target.beginPath();
				target.moveTo(250, 100);
				target.lineTo(300, 14);
				target.stroke();
				fillShape(target, '#d42a2a', 271, 56, 8, 6);
				fillShape(target, '#2a4a6a', 0, 70, 180, 44);
				for (let x = 4; x < 180; x += 22) {
					fillShape(target, '#4a6a8a', x, 80 + ((x * 3) % 20), 10, 1);
				}

				// A boat in Vågen.
				fillPolygon(target, '#e8e4d8', [[20, 92], [70, 92], [64, 102], [26, 102]]);
				fillShape(target, '#b8322a', 26, 98, 38, 4);
				fillShape(target, '#5a3a1a', 44, 70, 2, 22);
				fillShape(target, '#8a8478', 0, 112, width, 48);
				for (let y = 114; y < height; y += 5) {
					for (let x = ((y / 5) % 2) * 5; x < width; x += 10) {
						fillShape(target, '#7a7468', x, y, 9, 1);
					}
				}

				// The fish stall, with a striped roof.
				for (let x = 56; x < 156; x += 10) {
					fillShape(target, (x / 10) % 2 === 0 ? '#d42a2a' : '#f0f0f0', x, 50, 10, 14);
				}

				fillShape(target, '#5a3a1a', 58, 64, 3, 50);
				fillShape(target, '#5a3a1a', 150, 64, 3, 50);
				// The Fløibanen station, with the funicular at the bottom of its track.
				fillShape(target, '#d8ccb0', 228, 46, 88, 72);
				fillPolygon(target, '#6a3a2a', [[222, 48], [272, 30], [320, 44], [320, 48]]);
				fillShape(target, '#3a2a2a', 238, 76, 28, 42);
				fillShape(target, '#d42a2a', 290, 70, 22, 20);
				windowPane(target, 294, 74, 14, 10, '#9ac0e0');
				sign(target, 272, 54, 'FLOIBANEN', '#ffffff', '#b8322a');
				// The post of the seagull.
				fillShape(target, '#6a4a2a', 190, 96, 6, 54);
				fillShape(target, '#8a6a4a', 189, 94, 8, 3);
				mapArrow(target);
			},
			floyen(target) {
				sky(target, '#8a9ab0', '#c8d0d8', 70);
				fillShape(target, '#3a5a7a', 0, 66, width, 40);
				fillPolygon(target, '#5a7a5a', [[0, 62], [50, 54], [110, 64], [180, 50], [250, 60], [320, 52], [320, 70], [0, 70]]);
				for (let index = 0; index < 60; index++) {
					const x = 70 + ((index * 47) % 180);
					const y = 82 + ((index * 13) % 14);
					fillShape(target, ['#e8e4d8', '#b8322a', '#e0b040', '#ffffff'][index % 4], x, y, 2, 2);
				}

				fillPolygon(target, '#4a7a3a', [[0, 104], [80, 98], [180, 106], [260, 96], [320, 102], [320, 160], [0, 160]]);
				for (let index = 0; index < 50; index++) {
					fillShape(target, '#5a8a4a', (index * 61) % width, 108 + ((index * 17) % 50), 3, 1);
				}

				// The top station of Fløibanen.
				fillShape(target, '#b8b0a0', 2, 58, 58, 60);
				fillPolygon(target, '#5a3a2a', [[0, 60], [31, 46], [62, 60]]);
				fillShape(target, '#3a2a2a', 18, 82, 24, 36);
				fillShape(target, '#d42a2a', 22, 90, 16, 14);
				sign(target, 31, 64, 'FLOIBANEN', '#ffffff', '#b8322a');
				for (const [x, size] of [[84, 18], [312, 22], [126, 14], [292, 16]]) {
					pine(target, x, 118, size);
				}

				fillShape(target, '#6a4a2a', 172, 110, 3, 36);
				fillShape(target, '#3a5a2a', 146, 98, 54, 18);
				drawPixelText(target, 'TROLLSKOGEN', 173, 100, '#ffffff', {align: 'center'});
				drawPixelText(target, 'DO NOT FEED', 173, 108, '#e0e8d0', {align: 'center'});
			},
		};

		drawBackground.party = drawBackground.bryggen;

		const background = scene => {
			if (!backgrounds[scene]) {
				const layer = makeCanvas(width, height);
				drawBackground[scene](layer.getContext('2d'));
				backgrounds[scene] = layer;
			}

			return backgrounds[scene];
		};

		// A stack of brown cheese, or of its slices, which the seagull guards on its post, and Mormor's cheese slicer on her stand.
		const drawCheese = (target, x, y, isSliced) => {
			if (isSliced) {
				for (let index = 0; index < 4; index++) {
					fillShape(target, index % 2 === 0 ? '#c86f2e' : '#a0521e', x - 4, y - 2 - (index * 2), 9, 2);
				}
			} else {
				fillShape(target, '#a0521e', x - 5, y - 7, 10, 7);
				fillShape(target, '#c86f2e', x - 5, y - 7, 10, 2);
			}
		};

		const drawWaffleIron = (target, x, y) => {
			fillEllipse(target, '#b8860b', x, y, 7, 6);
			fillEllipse(target, '#ffd700', x, y - 1, 6, 5);
			for (let line = -4; line <= 4; line += 3) {
				fillShape(target, '#b8860b', x + line, y - 5, 1, 9);
			}

			fillShape(target, '#3a2a1a', x + 6, y - 1, 6, 2);
		};

		const thingsSaidAboutNothing = {
			pickup: ['I can’t pick that up.', 'I don’t need that.', 'It won’t fit in my pockets. They are full of trading cards.'],
			use: ['I can’t use that.', 'That doesn’t seem to work.', 'I don’t think that will work.'],
			talk: ['I don’t think it wants to talk.', 'Hello? Nothing. Rude.'],
			give: ['I don’t think it wants that.', 'No, thanks, it says. I mean, it would, if it could talk.'],
			open: ['It doesn’t open.', 'I can’t open that.'],
		};

		// The scenes in the order the visitor meets them, with the things to look at, pick up, use, and talk to. A thing has its area in the pixels of the scene, the place where Sindre stands to reach it, and what each verb does: a text that Sindre says, or a function. A thing that is not there right now has `isHere` say so.
		const scenes = {};

		scenes.title = {things: []};

		scenes.room = {
			entry: 60,
			draw(target) {
				if (flag('wardrobeOpen')) {
					fillShape(target, '#2a1e12', 74, 28, 22, 90);
					fillShape(target, '#a0703a', 96, 28, 10, 90);
					fillShape(target, '#8a8a8a', 76, 36, 18, 1);
					if (!flag('jacketTaken')) {
						drawSprite(target, ['.jjjj.', 'jjjjjj', 'jjjjjj', 'jjJjjj', 'jjJjjj', 'jjJjjj', '.jJjj.', '.jjjj.'], 85, 66, {scale: 3});
					}
				}

				if (!flag('piggyTaken')) {
					drawSprite(target, ['.p.....', 'ppppppp', 'pkppppw', 'ppppppp', '.p...p.'], 226, 90, {scale: 2});
				}

				if (!flag('cdTaken')) {
					fillEllipse(target, '#d8d8e8', 140, 142, 6, 3);
					fillEllipse(target, '#ff9ae0', 138, 141, 2, 1);
					fillEllipse(target, '#1a3a8a', 140, 142, 1.5, 1);
				}

				drawSprite(target, sprites.mamma, 26, 120, {scale: 2});
			},
			things: [
				{
					id: 'mamma',
					name: 'Mamma',
					area: [12, 76, 28, 44],
					stand: 50,
					isExit: true,
					look: 'It’s Mamma. She has a sixth sense for rain.',
					async walk() {
						await leaveRoom();
					},
					async open() {
						await leaveRoom();
					},
					async talk() {
						await say('mamma', 'Yes, vennen?');
						await converse(() => [
							{text: 'Have you seen the Golden Waffle?', answer: () => say('mamma', 'Mormor called. The troll took it! Can you believe it? Trolls, in 1999!')},
							{text: 'Can I go out?', answer: () => say('mamma', state.flags.isWearingJacket ? 'Yes. Be home before dinner. And do not feed the seagulls.' : 'Not without your rain jacket. It is in your wardrobe, where it has been all year.')},
							{text: 'Can I have money for Fløibanen?', answer: () => say('mamma', 'Money? You have a piggy bank full of money. I hear it rattle every night.')},
							{text: 'What’s for dinner?', answer: () => say('mamma', 'Fish. It is always fish. We live in Bergen.')},
							goodbye('Bye, Mamma.', 'mamma', 'Bye, vennen.'),
						]);
					},
					give: () => say('mamma', 'That is sweet, but you keep it, vennen.'),
					pickup: 'Mamma is too big to carry. Also, she would not like it.',
				},
				{
					id: 'wardrobe',
					name: 'wardrobe',
					area: [48, 26, 50, 94],
					stand: 72,
					look: () => flag('wardrobeOpen') ? 'My wardrobe. It’s open, and the monster is not home.' : 'My wardrobe. My rain jacket lives in there. And maybe a monster, but a nice one.',
					async open() {
						if (flag('wardrobeOpen')) {
							await say('sindre', 'It’s already open.');
							return;
						}

						state.flags.wardrobeOpen = true;
						beep(150, 0.2, {type: 'sawtooth', volume: 0.03});
						await say('sindre', 'Creeeak!');
					},
					pickup: 'It’s screwed to the wall. Mamma did that after the IKEA thing.',
				},
				{
					id: 'jacket',
					name: 'rain jacket',
					area: [74, 38, 22, 34],
					stand: 80,
					isHere: () => flag('wardrobeOpen') && !flag('jacketTaken'),
					look: 'My yellow rain jacket. In Bergen, it’s not clothing, it’s survival gear.',
					async pickup() {
						state.flags.jacketTaken = true;
						addItem('jacket');
						await say('sindre', 'Got it. Now to put it on.');
					},
					async use() {
						await say('sindre', 'I should pick it up first.');
					},
				},
				{
					id: 'window',
					name: 'window',
					area: [104, 22, 58, 62],
					stand: 132,
					look: 'It’s raining. It’s Bergen. It started raining in 1997, and it never stopped.',
					open: 'And let the rain in? Mamma would ground me until 2005.',
				},
				{
					id: 'cd',
					name: 'AOL CD',
					area: [130, 134, 20, 14],
					stand: 140,
					isHere: () => !flag('cdTaken'),
					look: 'An AOL CD. 50 hours free! One comes in the mail every day. We use them as coasters.',
					async pickup() {
						state.flags.cdTaken = true;
						addItem('cd');
						award('cd', 5);
						await say('sindre', 'An AOL CD. You never know when you need one.');
					},
				},
				{
					id: 'imac',
					name: 'iMac',
					area: [176, 58, 42, 32],
					stand: 196,
					look: 'My iMac, in Bondi Blue. 233 MHz! It’s see-through, so you can watch it think.',
					async use() {
						await say('sindre', 'I’ll check my e-mail.');
						await say('narrator', '1 new message from Mormor: “THE TROLL TOOK THE GOLDEN WAFFLE!!! COME TO BRYGGEN. Love, Mormor. P.S. Wear a jacket.”');
						award('email', 5);
						await say('sindre', 'Mormor learned the caps lock key. This is serious.');
					},
					pickup: 'It’s heavy, and it’s plugged in. And it’s beautiful where it is.',
					async open() {
						retryState = structuredClone(state);
						await say('sindre', 'Let’s see how it works inside. Where is Mamma’s butter knife?');
						await die('You open the iMac with a butter knife. 233 MHz of electricity says hello. Kids, do not try this at home. Or anywhere.');
					},
				},
				{
					id: 'piggy',
					name: 'piggy bank',
					area: [218, 78, 18, 14],
					stand: 222,
					isHere: () => !flag('piggyTaken'),
					look: 'My piggy bank, Gris. Full of Mormor’s birthday money.',
					async pickup() {
						state.flags.piggyTaken = true;
						addItem('piggy');
						await say('sindre', 'Clink, clink. Gris is coming with me.');
					},
					open: 'I should pick Gris up first.',
				},
				{
					id: 'poster',
					name: 'poster',
					area: [252, 22, 50, 40],
					stand: 262,
					look: 'A unicorn jumping over a rainbow. It’s art.',
					pickup: 'It’s up with Mamma’s best tape. It’s never coming down.',
				},
				{
					id: 'glitter',
					name: 'Glitter',
					area: [270, 46, 16, 14],
					stand: 270,
					look: 'Glitter, my unicorn. Not the virtual one. This one is on the poster, and she talks to me. Don’t tell Kevin.',
					async talk() {
						await say('glitter', 'Neigh! I mean, hi, Sindre!');
						await converse(() => [
							{text: 'Any advice, Glitter?', answer: () => say('glitter', 'Look at everything, pick up everything, and talk to everyone. That’s how adventure games work.')},
							{text: 'Do you want to come along?', answer: () => say('glitter', 'In the rain? Unicorns do not melt, but our glitter runs.')},
							goodbye('See you later, Glitter.', 'glitter', 'Bring me a waffle!'),
						]);
					},
					pickup: 'She’s part of the poster. Also, she guards the iMac.',
				},
				{
					id: 'bed',
					name: 'bed',
					area: [244, 94, 74, 30],
					stand: 262,
					look: 'My bed. Made. Sort of.',
					use: 'It’s not bedtime. It’s adventure time!',
					open: 'There is nothing under it but socks and a Furby that won’t stop talking.',
				},
			],
		};

		const leaveRoom = async () => {
			if (!flag('isWearingJacket')) {
				await say('mamma', 'Not without your rain jacket! It is Bergen, Sindre. It rains.');
				return;
			}

			await say('mamma', 'Bye, vennen! Say hi to Mormor!');
			await go('map');
		};

		scenes.map = {
			draw(target) {
				for (const thing of scenes.map.things) {
					const [x, y] = thing.dot;
					fillEllipse(target, '#d42a2a', x, y, 3, 3);
					fillEllipse(target, '#ffffff', x, y, 1, 1);
					// The names are twice the size of the other pixel text, so they can be read on a phone.
					const labelWidth = pixelTextWidth(thing.label, 2) + 6;
					fillShape(target, '#fff8e0', x - (labelWidth / 2), y + 5, labelWidth, 14);
					drawPixelText(target, thing.label, x, y + 7, '#3a2a1a', {scale: 2, align: 'center'});
				}
			},
			things: [
				{id: 'home', name: 'home', label: 'HOME', dot: [150, 50], scene: 'room', entry: 60, look: 'Home. Mamma, my room, and my iMac.'},
				{id: 'school', name: 'the school', label: 'SCHOOL', dot: [265, 112], scene: 'school', entry: 40, look: 'My school. Closed on Saturdays. Kevin goes anyway.'},
				{id: 'bryggen', name: 'Bryggen', label: 'BRYGGEN', dot: [170, 128], scene: 'bryggen', entry: 40, look: 'Bryggen, the old wooden houses by the harbor. Mormor has her waffle stand there.'},
				{id: 'fishmarket', name: 'the fish market', label: 'FISH MARKET', dot: [200, 88], scene: 'fishmarket', entry: 40, look: 'The fish market, and the bottom station of Fløibanen, the funicular up to Fløyen.'},
			].map(place => ({
				...place,
				area: [place.dot[0] - 36, place.dot[1] - 6, 72, 26],
				isExit: true,
				async walk() {
					await go(place.scene, place.entry);
				},
			})),
		};

		const mapSign = {
			id: 'map',
			name: 'the map',
			area: [0, 98, 28, 52],
			stand: 16,
			isExit: true,
			look: 'A sign to the map of Bergen.',
			async walk() {
				await go('map');
			},
		};

		scenes.bryggen = {
			entry: 40,
			draw(target) {
				drawSprite(target, sprites.mormor, 206, 136, {scale: 2, isFlipped: true});
				fillShape(target, '#5a3a1a', 170, 120, 72, 3);
				for (let x = 170; x < 242; x += 6) {
					fillShape(target, (x / 6) % 2 === 0 ? '#d42a2a' : '#f4f4f4', x, 123, 6, 5);
					fillShape(target, (x / 6) % 2 === 0 ? '#f4f4f4' : '#d42a2a', x, 128, 6, 5);
				}

				fillShape(target, '#5a3a1a', 172, 133, 4, 17);
				fillShape(target, '#5a3a1a', 236, 133, 4, 17);
				fillEllipse(target, '#e8e4d8', 184, 117, 8, 4);
				fillEllipse(target, '#f8e8a8', 184, 115, 6, 2);
				if (!flag('slicerTaken')) {
					fillShape(target, '#8b5a2b', 226, 113, 2, 7);
					fillShape(target, '#c8c8c8', 222, 110, 10, 4);
				}

				sign(target, 206, 74, 'VAFLER', '#ffffff', '#b8322a');
			},
			things: [
				mapSign,
				{
					id: 'mormor',
					name: 'Mormor',
					area: [192, 96, 28, 26],
					stand: 160,
					look: 'Mormor. She has made waffles every Sunday since 1952. Today she looks sad.',
					async talk() {
						if (!flag('metMormor')) {
							state.flags.metMormor = true;
							await say('mormor', 'Sindre! The troll took my Golden Waffle! On my birthday!');
						} else {
							await say('mormor', 'Hello again, vennen.');
						}

						await converse(() => [
							{text: 'Who took the Golden Waffle?', answer: () => say('mormor', 'The troll from Fløyen. He came down in the night. I saw his nose through the window. It was as long as a cucumber.')},
							{
								text: 'How do I get it back?',
								async answer() {
									state.flags.knowsCheese = true;
									await say('mormor', 'Trolls love brown cheese more than gold. Bring him brown cheese, and he will trade.');
									await say('mormor', 'But I have none left. The troll ate it all, the rascal.');
								},
							},
							flag('knowsCheese') && {
								text: 'Where can I find brown cheese?',
								async answer() {
									state.flags.knowsKevin = true;
									await say('mormor', 'The shop is closed on Saturdays. Hmm. Kevin’s mother packs a whole brown cheese in his school bag every day.');
									await say('mormor', 'And Kevin is at the school. He is always at the school.');
								},
							},
							!flag('slicerTaken') && {
								text: 'Can I borrow your cheese slicer?',
								async answer() {
									await takeSlicer();
								},
							},
							{text: 'Happy birthday, Mormor!', answer: () => say('mormor', 'Thank you, vennen. 80 years old, and not one waffle. What a world.')},
							goodbye('Bye, Mormor.', 'mormor', 'Bye! And wear your jacket!'),
						]);
					},
					async give(item) {
						if (item === 'waffle') {
							await ending();
							return;
						}

						const answers = {
							cheese: 'Give it to the troll, not me! I have had enough brown cheese for a lifetime. No, that is a lie. Nobody has.',
							slices: 'Beautiful slices! Give them to the troll, vennen.',
							cd: 'A coaster? How nice. Keep it, vennen.',
							fishhead: 'For the soup? No, you keep it. It looks like it has plans.',
							coins: 'Keep your money, vennen. Buy yourself something nice. Like a ticket to Fløyen.',
						};
						await say('mormor', answers[item] ?? 'Thank you, vennen, but you keep it.');
					},
					pickup: 'Mormor? She’s small, but not that small.',
				},
				{
					id: 'slicer',
					name: 'cheese slicer',
					area: [218, 106, 16, 14],
					stand: 160,
					isHere: () => !flag('slicerTaken'),
					look: 'Mormor’s cheese slicer. Norway’s gift to the world.',
					async pickup() {
						await takeSlicer();
					},
				},
				{
					id: 'stand',
					name: 'waffle stand',
					area: [168, 120, 76, 30],
					stand: 160,
					look: 'Mormor’s waffle stand. Batter ready, brown cheese gone, and no waffle iron. A tragedy in three parts.',
					use: 'I can’t make waffles without the waffle iron. Nobody can. It’s science.',
				},
				{
					id: 'houses',
					name: 'the houses',
					area: [30, 20, 136, 84],
					stand: 100,
					look: 'Bryggen. These wooden houses burned down seven times, and Bergen built them again every time. We are stubborn like that.',
					open: 'They are museums and shops. And it’s not my door.',
				},
				{
					id: 'harbor',
					name: 'the harbor',
					area: [30, 152, 290, 8],
					stand: 120,
					look: 'Vågen, the harbor. The water is 8 degrees. In summer.',
					use: 'Swimming? In October? In Bergen? No.',
				},
			],
		};

		const takeSlicer = async () => {
			if (flag('slicerTaken')) {
				await say('mormor', 'You already have it, vennen.');
				return;
			}

			state.flags.slicerTaken = true;
			addItem('slicer');
			award('slicer', 5);
			await say('mormor', 'Take it! My mormor always said: never go into the mountains without a cheese slicer.');
		};

		scenes.school = {
			entry: 40,
			draw(target) {
				drawSprite(target, sprites.kevin, 210, 150, {scale: 2, isFlipped: true});
				if (!flag('gotCheese')) {
					fillShape(target, '#2a6a3a', 226, 132, 12, 16);
					fillShape(target, '#1f4a2a', 226, 132, 12, 3);
				}

				fillEllipse(target, '#f4f4f4', 128, 146, 5, 5);
				fillShape(target, '#2a2a2a', 127, 143, 3, 3);
			},
			things: [
				mapSign,
				{
					id: 'kevin',
					name: 'Kevin',
					area: [198, 112, 26, 40],
					stand: 180,
					look: 'Kevin from my class. He is at school on a Saturday. He says it’s quieter.',
					async talk() {
						await say('kevin', 'Hey, Sindre! Did you know I have 411 AOL CDs?');
						await converse(() => [
							{
								text: 'Why do you collect AOL CDs?',
								answer: () => say('kevin', 'With 412, I can cover my whole ceiling. Then my room is a disco! I need just one more.'),
							},
							{
								text: 'Do you have brown cheese?',
								async answer() {
									if (flag('gotCheese')) {
										await say('kevin', 'Not anymore! You have it. Mamma packs a new one tomorrow.');
										return;
									}

									await say('kevin', 'Mamma packs a whole brown cheese in my bag every day. In case of war.');
									await say('kevin', 'I’ll trade it to you. For an AOL CD!');
								},
							},
							{text: 'Want to come to Fløyen?', answer: () => say('kevin', 'No way, there is a troll up there. And trees. I’m allergic to trees.')},
							{text: 'Got any new trading cards?', answer: () => say('kevin', 'I traded my best shiny card for a Tamagotchi. It died. Don’t ask.')},
							goodbye('Bye, Kevin.', 'kevin', 'Bye! Bring me AOL CDs!'),
						]);
					},
					async give(item) {
						if (item !== 'cd') {
							await say('kevin', 'Nah. Do you have an AOL CD?');
							return;
						}

						removeItem('cd');
						await say('kevin', '412! FOUR HUNDRED AND TWELVE! Sindre, you’re the best!');
						await say('kevin', 'Here, take the brown cheese. Mamma packs a new one tomorrow.');
						state.flags.gotCheese = true;
						addItem('cheese');
						award('cheese', 10);
					},
					pickup: 'Kevin? He’s heavier than he looks. He had three waffles for breakfast.',
				},
				{
					id: 'bag',
					name: 'Kevin’s school bag',
					area: [222, 128, 20, 22],
					stand: 200,
					isHere: () => !flag('gotCheese'),
					look: 'Kevin’s school bag. It smells of brown cheese.',
					pickup: () => say('kevin', 'Hey! That’s my bag! Want to trade for something?'),
					open: () => say('kevin', 'Hey! Hands off! We can trade, though.'),
				},
				{
					id: 'school',
					name: 'the school',
					area: [50, 20, 220, 92],
					stand: 160,
					look: 'My school. Closed on Saturdays, except for Kevin.',
					open: 'Locked. Kevin climbs in through the window. I’m not that kind of kid.',
				},
				{
					id: 'football',
					name: 'football',
					area: [120, 138, 16, 14],
					stand: 116,
					look: 'A football. It’s flat, like my football career.',
					pickup: 'It’s Kevin’s. He would notice. He notices everything.',
					use: 'I kick the football. It rolls one meter and stops. It’s flat.',
				},
				{
					id: 'bike',
					name: 'Kevin’s bike',
					area: [268, 124, 46, 26],
					stand: 260,
					look: 'Kevin’s bike. It has 21 gears, and he uses one.',
					use: 'It’s Kevin’s. And Bergen is all hills. No thanks.',
				},
			],
		};

		scenes.fishmarket = {
			entry: 40,
			draw: (target, time) => {
				drawSprite(target, sprites.fishmonger, 104, 108, {scale: 2});
				fillShape(target, '#5a3a1a', 62, 104, 88, 4);
				fillShape(target, '#c8e8f4', 62, 98, 88, 6);
				for (let x = 66; x < 146; x += 10) {
					fillEllipse(target, (x / 10) % 3 === 0 ? '#ff8a6a' : '#9aa0aa', x + 3, 98, 4, 2);
				}

				fillShape(target, '#7a5a3a', 62, 108, 88, 6);
				const bob = this.reducedMotion ? 0 : Math.round(Math.sin(time / 300));
				if (flag('cheeseStolen')) {
					drawCheese(target, 193, 94, state.flags.stolenItem === 'slices');
				}

				drawSprite(target, sprites.seagull, 193, (flag('cheeseStolen') ? 86 : 94) + bob, {scale: 2, isFlipped: true});
				drawSprite(target, sprites.conductor, 264, 150, {scale: 2, isFlipped: true});
			},
			things: [
				mapSign,
				{
					id: 'fishmonger',
					name: 'the fishmonger',
					area: [92, 70, 26, 28],
					stand: 104,
					look: 'The fishmonger. He has sold fish here for 40 years, and he smells like it.',
					async talk() {
						await say('fishmonger', 'Fresh shrimp! Salmon! What do you want, kid?');
						await converse(() => [
							{text: 'Where is Fløibanen?', answer: () => say('fishmonger', 'Right there, past the seagull. Up to Fløyen in eight minutes. If the seagull lets you.')},
							{
								text: 'Can I have something for the seagull?',
								async answer() {
									if (has('fishhead') || flag('gaveFishHead')) {
										await say('fishmonger', 'One fish head per customer. I am not made of fish heads.');
										return;
									}

									await say('fishmonger', 'Here, a fish head. Free. A seagull lets go of anything for a fish head.');
									addItem('fishhead');
									award('fishhead', 5);
								},
							},
							{text: 'What is the freshest fish?', answer: () => say('fishmonger', 'The one that is still looking at you.')},
							{text: 'Do you sell brown cheese?', answer: () => say('fishmonger', 'Brown cheese? This is a fish market, kid. Ask the troll, he took all of it anyway.')},
							goodbye('Bye!', 'fishmonger', 'Come back when you are big enough for a whole salmon!'),
						]);
					},
					give: item => say('fishmonger', item === 'coins' ? 'Keep it, kid. Fløibanen costs kr 20, and you will need it.' : 'I sell things, kid. I don’t buy them.'),
				},
				{
					id: 'fish',
					name: 'the fish',
					area: [60, 92, 92, 22],
					stand: 104,
					look: 'Shrimp, salmon, cod, and a crab with an attitude.',
					pickup: () => say('fishmonger', 'Hands off the fish! That’s 90 kroner a kilo!'),
				},
				{
					id: 'seagull',
					name: 'the seagull',
					area: [180, 76, 26, 22],
					stand: 172,
					look: () => flag('cheeseStolen') ? 'The seagull sits on my brown cheese like it’s an egg.' : (flag('seagullFull') ? 'The seagull is full. For about five minutes. That’s a Bergen record.' : 'A Bergen seagull. It has stolen 4,000 waffles, 300 ice creams, and one tourist’s hat.'),
					async talk() {
						await say('seagull', 'SKREEEE!');
						await say('sindre', 'I think that was a no.');
					},
					async pickup() {
						retryState = structuredClone(state);
						await say('sindre', 'Come here, birdie.');
						await die('You try to pick up the seagull. The seagull picks you up instead, flies over Vågen, and drops you in the harbor. The water is 8 degrees. You are not a fish.');
					},
					async give(item) {
						if (item !== 'fishhead') {
							await say('sindre', item === 'cheese' || item === 'slices' ? 'Give my brown cheese to a seagull? Never.' : 'It only wants food. Preferably mine.');
							return;
						}

						removeItem('fishhead');
						state.flags.gaveFishHead = true;
						state.flags.seagullFull = true;
						await say('seagull', 'SKREE! GULP!');
						if (flag('cheeseStolen')) {
							state.flags.cheeseStolen = false;
							addItem(state.flags.stolenItem);
							await say('sindre', 'It dropped my brown cheese for the fish head! And now it’s too full to steal. I hope.');
						} else {
							await say('sindre', 'It swallowed the fish head whole. Now it’s too full to steal anything. I hope.');
						}

						award('seagull', 10);
					},
					use: item => item === 'slicer' ? say('sindre', 'I am not slicing a seagull. I’m a kid, not a pirate.') : say('sindre', 'I don’t want to touch it. It has seen things.'),
				},
				{
					id: 'cheeseOnPost',
					name: 'my brown cheese',
					area: [186, 84, 16, 12],
					stand: 172,
					isHere: () => flag('cheeseStolen'),
					look: 'My brown cheese, under a seagull.',
					async pickup() {
						await say('seagull', 'SKREEEEEE!');
						await say('sindre', 'It won’t let go. Not for free, anyway.');
					},
					// Giving something here is giving it to the seagull that sits on the cheese.
					give: item => scenes.fishmarket.things.find(thing => thing.id === 'seagull').give(item),
				},
				{
					id: 'station',
					name: 'Fløibanen',
					area: [226, 40, 92, 78],
					stand: 248,
					isExit: true,
					look: 'Fløibanen, the funicular up to Fløyen. It has gone up and down since 1918.',
					async walk() {
						await rideUp();
					},
					async open() {
						await rideUp();
					},
					use: async item => (item === 'ticket' || item === undefined ? rideUp() : say('sindre', 'That doesn’t go in the ticket machine.')),
				},
				{
					id: 'conductor',
					name: 'the conductor',
					area: [252, 112, 24, 40],
					stand: 244,
					look: 'The conductor. He has a cap and a whistle, and he knows how to use both.',
					async talk() {
						await say('conductor', 'Tickets for Fløibanen! Kids kr 20, grown-ups kr 40, and trolls ride free. They won’t pay.');
						await converse(() => [
							!has('ticket') && {text: 'One ticket, please.', answer: buyTicket},
							{text: 'Is there really a troll on Fløyen?', answer: () => say('conductor', 'Of course. He sits in the troll forest and grumbles. Nice guy, though. A bit hungry.')},
							{text: 'Why can’t I see Fløyen from here?', answer: () => say('conductor', 'Fog. The view was last seen in 1987.')},
							goodbye('Bye!', 'conductor', 'Mind the gap!'),
						]);
					},
					async give(item) {
						if (item === 'coins') {
							await buyTicket();
						} else if (item === 'ticket') {
							await rideUp();
						} else {
							await say('conductor', item ? `Money or a ticket, kid. I don’t take ${itemNames[item]}s.` : 'Give me what, kid? Pick something in your pockets first.');
						}
					},
				},
			],
		};

		const buyTicket = async () => {
			if (!has('coins')) {
				await say('conductor', 'That’s kr 20, kid. You have kr 0. Math says no.');
				return;
			}

			removeItem('coins');
			addItem('ticket');
			award('ticket', 10);
			await say('conductor', 'Kr 20, thank you! A return ticket for a kid. Up and down as much as you like today.');
		};

		// The seagull steals the brown cheese when Sindre walks past its post with it, unless it ate a fish head first.
		const rideUp = async () => {
			if (!has('ticket')) {
				await say('conductor', 'Ticket, please! Kids are kr 20.');
				return;
			}

			const food = ['cheese', 'slices'].find(item => has(item));
			if (food && !flag('seagullFull')) {
				beep(1600, 0.15, {type: 'triangle'});
				beep(1900, 0.2, {type: 'triangle', when: 0.15});
				await say('seagull', 'SKREEEEEEEEE!');
				removeItem(food);
				state.flags.cheeseStolen = true;
				state.flags.stolenItem = food;
				await say('sindre', 'Hey! The seagull stole my brown cheese! It’s sitting on it, on its post!');
				return;
			}

			await say('narrator', 'Fløibanen climbs 320 meters up the mountain. Sindre presses his nose to the window. Fog. Fog. Troll forest.');
			award('ride', 5);
			await go('floyen', 50);
		};

		scenes.floyen = {
			entry: 50,
			draw(target) {
				drawSprite(target, sprites.troll, 262, 152, {scale: 2, isFlipped: true});
				if (!flag('trollHappy')) {
					drawWaffleIron(target, 246, 120);
				}
			},
			things: [
				{
					id: 'station',
					name: 'Fløibanen',
					area: [2, 46, 58, 72],
					stand: 30,
					isExit: true,
					look: 'The top station of Fløibanen. The way down to the fish market.',
					async walk() {
						await say('narrator', 'Fløibanen goes down again. Sindre’s ears pop.');
						await go('fishmarket', 244);
					},
				},
				{
					id: 'troll',
					name: 'the troll',
					area: [238, 98, 46, 54],
					stand: 210,
					look: () => flag('trollHappy') ? 'The troll. He’s licking his one tooth and smiling.' : 'The troll of Fløyen. Big, gray-green, a nose like a cucumber, and one tooth. And he has the Golden Waffle!',
					async talk() {
						if (flag('trollHappy')) {
							await say('troll', 'TROLL FULL. TROLL HAPPY. TROLL COME TO PARTY.');
							return;
						}

						await say('troll', 'WHO DISTURB TROLL?');
						await converse(() => [
							{text: 'Give back the Golden Waffle!', answer: () => say('troll', 'NO. SHINY. MINE.')},
							{text: 'Why did you take it?', answer: () => say('troll', 'TROLL SMELL WAFFLES FROM MOUNTAIN FOR 300 YEARS. NEVER GET ONE. TROLL TAKE WAFFLE MACHINE. MACHINE NOT TASTY.')},
							{
								text: 'What do trolls eat?',
								async answer() {
									state.flags.knowsTooth = true;
									await say('troll', 'BRUNOST! BEST FOOD! BUT TROLL HAVE ONE TOOTH. BIG BRUNOST TOO HARD. TROLL ONLY LICK IT.');
								},
							},
							{text: 'Would you trade it for brown cheese?', answer: () => say('troll', 'MAYBE. IF TROLL CAN EAT IT.')},
							{text: 'You fight like a dairy farmer!', answer: () => say('troll', 'TROLL NOT FIGHT. TROLL NOT FARM. YOU IN WRONG GAME, SMALL HUMAN.')},
							goodbye('Bye, troll.', 'troll', 'BYE, SMALL HUMAN.'),
						]);
					},
					give: async item => {
						if (flag('trollHappy')) {
							await say('troll', 'TROLL FULL.');
							return;
						}

						if (item === 'cheese') {
							state.flags.knowsTooth = true;
							await say('troll', 'BRUNOST! TROLL BITE... OW! TOO BIG! TROLL HAVE ONE TOOTH!');
							await say('sindre', 'He gave it back. If only it were thinner.');
							return;
						}

						if (item === 'slices') {
							removeItem('slices');
							await say('troll', 'THIN BRUNOST! TROLL CAN EAT! NOM. NOM. NOM.');
							await say('troll', 'TAKE SHINY THING. TROLL NOT KNOW HOW MAKE WAFFLE ANYWAY.');
							state.flags.trollHappy = true;
							addItem('waffle');
							award('troll', 15);
							this.cheer();
							await say('sindre', 'Come to Mormor’s birthday at Bryggen! She’ll make you waffles!');
							await say('troll', 'TROLL COME! TROLL BRING... NOTHING.');
							return;
						}

						await say('troll', item === 'fishhead' ? 'FISH? TROLL IS NOT SEAGULL.' : 'TROLL NOT EAT THAT. TROLL TRIED.');
					},
					async pickup() {
						retryState = structuredClone(state);
						await say('sindre', 'I’ll just lift him up and shake the waffle iron loose.');
						await die('You try to lift the troll. The troll lifts you. Then he eats you, rain jacket and all. He says you taste of rain.');
					},
					async use(item) {
						if (item === 'slicer') {
							retryState = structuredClone(state);
							await say('sindre', 'En garde, troll!');
							await die('You try to slice the troll. Trolls do not like to be sliced. The troll eats you, cheese slicer and all. A cheese slicer is for cheese.');
							return;
						}

						await say('sindre', 'I don’t want to use anything on him. He’s big.');
					},
				},
				{
					id: 'waffleIron',
					name: 'the Golden Waffle',
					area: [236, 110, 22, 18],
					stand: 210,
					isHere: () => !flag('trollHappy'),
					look: 'The Golden Waffle! Mormor’s waffle iron. The troll holds it like a teddy bear.',
					pickup: () => say('troll', 'NO TOUCH! SHINY IS TROLL’S!'),
				},
				{
					id: 'sign',
					name: 'sign',
					area: [144, 96, 58, 22],
					stand: 170,
					look: 'TROLLSKOGEN. DO NOT FEED THE TROLLS. Hmm.',
					pickup: 'It’s nailed down. They had problems with trolls taking it.',
				},
				{
					id: 'view',
					name: 'the view',
					area: [62, 64, 250, 34],
					stand: 140,
					look: 'Bergen, far below. Seven mountains, one city, and a million umbrellas.',
				},
				{
					id: 'trees',
					name: 'the trees',
					area: [64, 90, 80, 30],
					stand: 100,
					look: 'The troll forest. Every tree looks like a troll if you squint. One of them is a troll.',
					pickup: 'I can’t pick a tree. I’m 12.',
				},
			],
		};

		scenes.party = {
			draw(target) {
				fillShape(target, '#ffffff', 40, 6, 240, 12);
				drawPixelText(target, 'GRATULERER MED DAGEN, MORMOR!', 160, 10, '#d42a2a', {align: 'center'});
				for (let x = 44; x < 280; x += 10) {
					fillPolygon(target, ['#d42a2a', '#ffd700', '#2a5bd7', '#3fa34d'][(x / 10) % 4 | 0], [[x, 18], [x + 8, 18], [x + 4, 24]]);
				}

				fillShape(target, '#5a3a1a', 110, 120, 110, 3);
				fillShape(target, '#f4f4f4', 110, 123, 110, 8);
				for (let x = 116; x < 214; x += 14) {
					fillEllipse(target, '#e8b048', x + 5, 119, 6, 3);
					fillShape(target, '#a0521e', x + 3, 116, 4, 2);
				}

				drawSprite(target, sprites.mamma, 40, 150, {scale: 2});
				drawSprite(target, sprites.kevin, 80, 150, {scale: 2});
				drawSprite(target, sprites.mormor, 160, 116, {scale: 2});
				drawWaffleIron(target, 180, 112);
				drawSprite(target, sprites.troll, 256, 150, {scale: 2, isFlipped: true});
				fillPolygon(target, '#ff8fc8', [[248, 98], [256, 82], [264, 98]]);
				drawSprite(target, sprites.seagull, 300, 110, {scale: 2, isFlipped: true});
				drawSprite(target, sprites.glitter, 210, 150, {scale: 2, isFlipped: true});
			},
			things: [],
		};

		// What the things of the inventory do with each verb, and the things that go together.
		const itemActions = {
			jacket: {
				look: 'My yellow rain jacket. It keeps out rain, wind, and seagull droppings.',
				async use() {
					removeItem('jacket');
					state.flags.isWearingJacket = true;
					award('jacket', 5);
					await say('sindre', 'There. Now I’m Bergen-proof.');
				},
			},
			piggy: {
				look: 'Gris, my piggy bank. It rattles.',
				async open() {
					await openPiggy();
				},
				async use() {
					await openPiggy();
				},
			},
			coins: {
				look: 'Twenty kroner. Enough for a kid’s ticket on Fløibanen, or 40 pieces of candy.',
			},
			cd: {
				look: 'AOL! 50 hours free! I don’t even know what I would do for 50 hours.',
				use: 'My iMac doesn’t need it. And the AOL CDs are not for computers anyway, they are for coasters.',
			},
			slicer: {
				look: 'A cheese slicer, invented in Norway in 1925. It’s like a tiny shovel for cheese.',
			},
			cheese: {
				look: 'A whole brown cheese. It weighs as much as a cat. A small cat.',
				use: 'I could eat it, but the troll needs it more. And Mamma says no cheese before dinner.',
			},
			slices: {
				look: 'Thin, perfect slices of brown cheese. Even a troll with one tooth could eat these.',
				use: 'They’re for the troll. I’ll have some at the party.',
			},
			fishhead: {
				look: 'A fish head. It looks at me. I look at it. Neither of us is happy.',
				use: 'What would I do with a fish head? Wear it?',
			},
			ticket: {
				look: 'A return ticket for Fløibanen, for kids. Up and down as much as I like today.',
			},
			waffle: {
				look: 'The Golden Waffle! Mormor’s waffle iron, shiny and heavy. It smells of 47 years of Sundays.',
				use: 'I need batter, and Mormor. She’s at Bryggen.',
			},
		};

		const openPiggy = async () => {
			removeItem('piggy');
			addItem('coins');
			award('coins', 5);
			await say('sindre', 'I pull out the plug of Gris. Kr 20! Mormor’s birthday money from last year.');
		};

		const combinations = {
			'cheese+slicer': async () => {
				removeItem('cheese');
				addItem('slices');
				award('slices', 10);
				beep(1200, 0.05, {type: 'triangle'});
				beep(1200, 0.05, {type: 'triangle', when: 0.1});
				beep(1200, 0.05, {type: 'triangle', when: 0.2});
				await say('sindre', 'Slice, slice, slice. Thin brown cheese, the Norwegian way. Even a troll with one tooth could eat this.');
			},
			'cd+slicer': 'Slicing an AOL CD? Then it’s 25 hours free, twice.',
			'cheese+fishhead': 'Fish head with brown cheese. No. Even trolls have limits.',
			'coins+piggy': 'Gris is empty. I took the money already.',
			'fishhead+slicer': 'Fish head carpaccio? I’m not that hungry.',
			'cd+cheese': 'Brown cheese on an AOL CD. That’s a Bergen pizza.',
		};

		// The hint line knows where the visitor is stuck, and gives a nudge first, then more and more of the answer, like the hint lines of the 1990s.
		const currentHints = () => {
			if (!flag('isWearingJacket')) {
				return ['Mamma will not let you go out in the rain like that.', 'Something in your wardrobe keeps the rain out.', 'Open the wardrobe, pick up the rain jacket, and use it in your inventory.'];
			}

			if (has('waffle')) {
				return ['Mormor is waiting for her waffle iron at Bryggen.', 'Give the Golden Waffle to Mormor.'];
			}

			if (!flag('metMormor')) {
				return state.points.email === undefined ? ['Mormor sent you an e-mail. Use your iMac to read it.', 'Go to Bryggen on the map, and talk to Mormor.'] : ['Mormor asked you to come to Bryggen.', 'Walk out of the door, pick Bryggen on the map, and talk to Mormor.'];
			}

			if (!flag('gotCheese')) {
				return ['Mormor says trolls love brown cheese. Who always has brown cheese?', 'Kevin’s mother packs a whole brown cheese in his school bag. Talk to Kevin at the school.', 'Kevin collects AOL CDs. There is one on the floor of your room. Give it to Kevin.'];
			}

			if (flag('cheeseStolen')) {
				return ['That seagull is a thief, but every thief has a price.', 'Seagulls love fish. The fishmonger might have something for it.', 'Ask the fishmonger for something for the seagull, then give the fish head to the seagull.'];
			}

			if (!has('ticket')) {
				return ['Fløibanen goes up to Fløyen from the fish market, but it is not free.', 'Your piggy bank at home has kr 20 in it.', 'Pick up the piggy bank, open it, and give the money to the conductor at the fish market.'];
			}

			if (has('cheese')) {
				return ['The troll has only one tooth. Think about it.', 'How do you make brown cheese easy to eat? Mormor has the tool for it at Bryggen.', 'Pick up the cheese slicer at Mormor’s stand, then use it with the brown cheese.'];
			}

			if (!flag('seagullFull')) {
				return ['Seagulls in Bergen steal food. Be careful at the fish market.', 'A full seagull does not steal. The fishmonger has free fish heads.', 'Ask the fishmonger for something for the seagull, give the fish head to the seagull, then take Fløibanen.'];
			}

			return ['The troll is on Fløyen. Fløibanen goes there from the fish market.', 'Give the brown cheese slices to the troll.'];
		};

		// The end: Mormor gets her Golden Waffle back, and everybody comes to the birthday, the troll too.
		const ending = async () => {
			removeItem('waffle');
			award('end', 10);
			await say('mormor', 'My Golden Waffle! Sindre, you got it back!');
			await say('mormor', 'Now, let us make waffles!');
			await go('party', 140);
			await say('troll', 'TROLL LIKE WAFFLE! TROLL LIKE WAFFLE VERY MUCH!');
			await say('kevin', 'Can I have my brown cheese back? Kidding! Can I have a waffle?');
			await say('seagull', 'SKREE!');
			await say('mamma', 'Who invited the seagull?');
			await say('mormor', 'Happy birthday to me! Thank you, vennen.');
			isOver = true;
			this.celebrate();
			this.cheer();
			const finalScore = score();
			await say('narrator', `THE END. Your score is ${finalScore} of 100. ${finalScore === 100 ? 'A perfect score! Mormor is proud.' : 'You missed some points. Mormor is proud anyway.'}`);
			startButton.textContent = '▶ Play Again';
			titleScreen.hidden = false;
			if (gameWindow.contains(document.activeElement)) {
				startButton.focus({preventScroll: true});
			}

			this.toast(`🧇 You finished Sindre’s Quest with ${finalScore} of 100 points!`);
		};

		const sceneNames = {
			room: 'My room',
			map: 'Map of Bergen',
			bryggen: 'Bryggen',
			school: 'The school',
			fishmarket: 'Fish market',
			floyen: 'Fløyen',
		};

		const outdoorScenes = new Set(['bryggen', 'school', 'fishmarket', 'floyen', 'party']);
		const scenesWithoutSindre = new Set(['title', 'map', 'party']);

		const thingsHere = () => scenes[state.scene].things.filter(thing => !thing.isHere || thing.isHere());

		// The thing under a point of the scene. Where things overlap, like the cheese slicer on the waffle stand, the smallest one wins, as it is the one in front.
		const thingAt = (x, y) => {
			let found;
			for (const thing of thingsHere()) {
				const [left, top, thingWidth, thingHeight] = thing.area;
				const isInside = x >= left && x < left + thingWidth && y >= top && y < top + thingHeight;
				if (isInside && (!found || (thingWidth * thingHeight) < (found.area[2] * found.area[3]))) {
					found = thing;
				}
			}

			return found;
		};

		const updateSentence = () => {
			if (isBusy || state.scene === 'title') {
				sentence.textContent = '';
				return;
			}

			const target = hovered ?? (focusIndex >= 0 ? thingsHere()[focusIndex] : undefined);
			let text = verbNames[verb];
			if (firstItem) {
				text += ` ${itemNames[firstItem]} ${verb === 'give' ? 'to' : 'with'}`;
			}

			if (target) {
				text += ` ${target.name}`;
			}

			sentence.textContent = text;
		};

		const selectVerb = name => {
			verb = name;
			firstItem = undefined;
			for (const button of verbButtons) {
				setPressed(button, button.dataset.adventureVerb === name);
			}

			updateInventory();
			updateSentence();
		};

		const drawRain = (left, top, rainWidth, rainHeight, time, count) => {
			context.fillStyle = '#c8d4e8';
			context.globalAlpha = 0.55;
			for (let index = 0; index < count; index++) {
				const y = top + ((((index * 29) + (time * 0.12)) % rainHeight + rainHeight) % rainHeight);
				const x = left + (((index * 37) + (y * 0.25)) % rainWidth);
				context.fillRect(Math.round(x), Math.round(y), 1, 4);
			}

			context.globalAlpha = 1;
		};

		const draw = (time = performance.now()) => {
			const motionTime = this.reducedMotion ? 0 : time;
			context.drawImage(background(state.scene), 0, 0);
			if (state.scene === 'room') {
				drawRain(110, 26, 46, 52, motionTime, 18);
			}

			scenes[state.scene].draw?.(context, motionTime);
			if (!scenesWithoutSindre.has(state.scene)) {
				const rows = walkTarget !== undefined && step % 2 === 1 ? [...sprites.sindre.slice(0, -4), ...sprites.sindreStep] : sprites.sindre;
				drawSprite(context, rows, state.x, floor, {scale: 2, isFlipped: state.isFacingLeft, colors: flag('isWearingJacket') ? {b: palette.j} : {}});
			}

			if (outdoorScenes.has(state.scene)) {
				drawRain(0, 0, width, height, motionTime, 70);
			}

			const focused = focusIndex >= 0 && document.activeElement === canvas ? thingsHere()[focusIndex] : undefined;
			if (focused) {
				const [left, top, thingWidth, thingHeight] = focused.area;
				context.strokeStyle = '#ffcc00';
				context.lineWidth = 1;
				context.setLineDash([2, 2]);
				context.strokeRect(left + 0.5, top + 0.5, thingWidth - 1, thingHeight - 1);
				context.setLineDash([]);
			}
		};

		// The loop draws the rain and walks Sindre, only while the game is on screen and the tab is visible. With reduced motion, the scene is only drawn when something changes, and Sindre does not walk but is there at once. Only the rain, the seagull, and a walking Sindre move, so the title, the map, and the party are drawn once.
		const loop = this.loop((seconds, time) => {
			if (walkTarget !== undefined) {
				const distance = walkTarget - state.x;
				const move = 80 * seconds;
				if (Math.abs(distance) <= move || this.reducedMotion) {
					state.x = walkTarget;
					walkTarget = undefined;
					walkDone?.();
					walkDone = undefined;
				} else {
					state.x += Math.sign(distance) * move;
					step = Math.floor(time / 150);
				}
			}

			draw(time);
		}, {while: () => (!this.reducedMotion && !scenesWithoutSindre.has(state.scene)) || walkTarget !== undefined});

		const respond = async (handler, ...values) => {
			const result = typeof handler === 'function' ? handler(...values) : handler;
			if (typeof result === 'string') {
				await say('sindre', result);
			} else {
				await result;
			}
		};

		// Runs what the visitor asked for, with the verbs and the scene waiting until it is done. Then the verb is Walk to again, like in the LucasArts games.
		const run = async action => {
			if (isBusy) {
				return;
			}

			isBusy = true;
			hovered = undefined;
			updateSentence();
			try {
				await action();
			} finally {
				isBusy = false;
				if (!isOver) {
					selectVerb('walk');
				}

				draw();
			}
		};

		const act = (verbName, thing, item) => run(async () => {
			const hasSindre = !scenesWithoutSindre.has(state.scene);
			if (hasSindre && thing.stand !== undefined && verbName !== 'look') {
				await walkTo(thing.stand);
			}

			if (hasSindre) {
				const middle = thing.area[0] + (thing.area[2] / 2);
				state.isFacingLeft = middle < state.x;
			}

			if (verbName === 'walk') {
				if (thing.isExit) {
					await thing.walk();
				}

				return;
			}

			if (thing.isExit && verbName === 'open' && thing.open === undefined) {
				await thing.walk();
				return;
			}

			if (verbName === 'look') {
				await respond(thing.look ?? `It looks like a perfectly normal ${thing.name}.`);
				return;
			}

			if (verbName === 'give') {
				await (thing.give ? thing.give(item) : say('sindre', randomItem(thingsSaidAboutNothing.give)));
				return;
			}

			if (verbName === 'use' && item) {
				await (typeof thing.use === 'function' ? thing.use(item) : say('sindre', randomItem(thingsSaidAboutNothing.use)));
				return;
			}

			const handler = thing[verbName];
			await respond(handler ?? randomItem(thingsSaidAboutNothing[verbName]));
		});

		const actOnItem = (verbName, item) => run(async () => {
			const actions = itemActions[item];
			if (verbName === 'look' || verbName === 'walk') {
				await respond(actions.look);
			} else if (verbName === 'pickup') {
				await say('sindre', 'I already have it.');
			} else if (verbName === 'talk') {
				await say('sindre', `Hello, ${itemNames[item]}. It doesn’t answer. Of course it doesn’t.`);
			} else if (verbName === 'give') {
				await say('sindre', 'Give it to whom? Click Give, then the thing, then a person.');
			} else {
				await respond(actions[verbName] ?? randomItem(thingsSaidAboutNothing[verbName] ?? thingsSaidAboutNothing.use));
			}
		});

		const combine = (first, second) => run(async () => {
			const combination = combinations[[first, second].sort().join('+')];
			await respond(combination ?? randomItem(['That doesn’t seem to work.', 'I don’t think those go together.', 'I can’t do that.']));
		});

		const isPlaying = () => state.scene !== 'title' && !isOver && openPanel === undefined;

		this.on(canvas, 'pointermove', event => {
			if (!isPlaying() || isBusy || event.pointerType === 'touch') {
				return;
			}

			const point = canvasPoint(canvas, event);
			const thing = thingAt(point.x, point.y);
			if (thing !== hovered) {
				hovered = thing;
				updateSentence();
			}
		});

		this.on(canvas, 'pointerleave', () => {
			hovered = undefined;
			updateSentence();
		});

		this.on(canvas, 'click', event => {
			if (skipLine) {
				skipLine();
				return;
			}

			if (!isPlaying() || isBusy) {
				return;
			}

			const point = canvasPoint(canvas, event);
			const thing = thingAt(point.x, point.y);
			focusIndex = -1;
			if (thing) {
				act(verb, thing, firstItem);
			} else if (verb === 'walk' && !scenesWithoutSindre.has(state.scene)) {
				walkTo(point.x).then(() => {
					draw();
				});
			}
		});

		this.on(canvas, 'keydown', event => {
			if (event.key === '.' || (event.key === 'Escape' && skipLine)) {
				event.preventDefault();
				skipLine?.();
				return;
			}

			if (!isPlaying() || isBusy || event.metaKey || event.ctrlKey || event.altKey) {
				return;
			}

			const things = thingsHere();
			if (event.key === 'ArrowRight' || event.key === 'ArrowDown' || event.key === 'ArrowLeft' || event.key === 'ArrowUp') {
				event.preventDefault();
				const direction = event.key === 'ArrowRight' || event.key === 'ArrowDown' ? 1 : -1;
				if (focusIndex < 0) {
					focusIndex = direction > 0 ? 0 : things.length - 1;
				} else {
					focusIndex = (focusIndex + direction + things.length) % things.length;
				}

				hovered = undefined;
				updateSentence();
				draw();
				this.say(things[focusIndex]?.name ?? '', speech);
			} else if ((event.key === 'Enter' || event.key === ' ') && things[focusIndex]) {
				event.preventDefault();
				act(verb, things[focusIndex], firstItem);
			} else if (event.key === 'Escape' && firstItem) {
				selectVerb(verb);
			} else {
				const shortcut = {w: 'walk', l: 'look', p: 'pickup', u: 'use', t: 'talk', g: 'give', o: 'open'}[event.key.toLowerCase()];
				if (shortcut) {
					event.preventDefault();
					selectVerb(shortcut);
				}
			}
		});

		this.on(canvas, 'focus', () => {
			draw();
		});

		this.on(canvas, 'blur', () => {
			draw();
		});

		for (const button of verbButtons) {
			this.on(button, 'click', () => {
				if (!isBusy) {
					selectVerb(button.dataset.adventureVerb);
				}
			});
		}

		for (const button of itemButtons) {
			this.on(button, 'click', () => {
				if (isBusy || !isPlaying()) {
					return;
				}

				const item = button.dataset.adventureItem;
				// A thing that does something by itself, like the rain jacket, is used at once. Other things wait for a second thing to go with, and a second click on the same thing uses it alone.
				if (verb === 'use' && (typeof itemActions[item].use === 'function' || firstItem === item)) {
					actOnItem('use', item);
				} else if ((verb === 'use' || verb === 'give') && !firstItem) {
					firstItem = item;
					updateInventory();
					updateSentence();
				} else if (verb === 'use' && firstItem && firstItem !== item) {
					combine(firstItem, item);
				} else if (verb === 'give' && firstItem) {
					run(() => say('sindre', 'Give it to my own pockets? It’s already there.'));
				} else {
					actOnItem(verb === 'use' ? 'use' : verb, item);
				}
			});
		}

		// The panels on top of the scene: the copy protection, a death, the saved games, and the hint line. One is open at a time, and Escape closes it.
		let openPanel;
		const panels = [copyForm, deathPanel, savesPanel, hintPanel];

		let focusBeforePanel;

		const showPanel = async panel => {
			if (!panels.some(other => other.contains(document.activeElement))) {
				focusBeforePanel = document.activeElement;
			}

			for (const other of panels) {
				other.hidden = other !== panel;
			}

			openPanel = panel;
			updateSentence();
			await nextFrame();
		};

		const closePanel = () => {
			const hadFocus = openPanel?.contains(document.activeElement);
			for (const panel of panels) {
				panel.hidden = true;
			}

			openPanel = undefined;
			if (hadFocus) {
				// The focus goes back to where it was, like a line to say in a conversation, if that is still there.
				const isBackVisible = focusBeforePanel?.isConnected && focusBeforePanel.checkVisibility() && gameWindow.contains(focusBeforePanel) && !titleScreen.contains(focusBeforePanel);
				(isBackVisible ? focusBeforePanel : (state.scene === 'title' || isOver ? startButton : canvas)).focus({preventScroll: true});
			}

			updateSentence();
			draw();
		};

		this.on(this, 'keydown', event => {
			if (event.key === 'Escape' && openPanel && openPanel.contains(event.target)) {
				event.preventDefault();
				if (openPanel === deathPanel) {
					retry();
				} else {
					closePanel();
				}
			}
		});

		const retry = () => {
			state = structuredClone(retryState ?? newState());
			state.flags.isDead = false;
			closePanel();
			updateAll();
			canvas.focus({preventScroll: true});
		};

		const updateAll = () => {
			stopWalking();
			titleScreen.hidden = state.scene !== 'title';
			updateScore();
			updateInventory();
			selectVerb('walk');
			draw();
			loop.start();
		};

		const startGame = async () => {
			state = newState();
			state.scene = 'room';
			state.x = 150;
			isOver = false;
			retryState = undefined;
			startButton.textContent = '▶ New Game';
			closePanel();
			updateAll();
			canvas.focus({preventScroll: true});
			await run(async () => {
				await say('narrator', 'Bergen, Saturday the 9th of October, 1999. It is raining.');
				await say('sindre', 'It’s Mormor’s birthday today! I should check my e-mail on my iMac.');
			});
		};

		// The copy protection asks for a word of the manual, like the games of the time did. Three wrong answers and it gives up, as Mamma says sharing is caring.
		const ordinals = ['first', 'second', 'third', 'fourth', 'fifth', 'sixth', 'seventh', 'eighth'];
		const manualPages = [...this.querySelectorAll('[data-adventure-page]')];
		const wordsOf = page => page.querySelector('[data-part="words"]').textContent.split(/\s+/).filter(Boolean);
		const normalize = word => word.toLowerCase().replaceAll('ø', 'o').replaceAll('æ', 'ae').replaceAll('å', 'a').normalize('NFD').replaceAll(/[^a-z\d]/g, '');
		let copyWord = '';
		let copyTries = 0;

		const askCopyProtection = async () => {
			const page = manualPages[1 + Math.floor(Math.random() * (manualPages.length - 1))];
			const words = wordsOf(page);
			const index = Math.floor(Math.random() * Math.min(words.length, ordinals.length));
			copyWord = normalize(words[index]);
			copyTries = 0;
			copyQuestion.textContent = `Type the ${ordinals[index]} word on page ${page.dataset.adventurePage} of the manual. It is next to the box.`;
			copyAnswer.value = '';
			copyStatus.textContent = '';
			await showPanel(copyForm);
			copyAnswer.focus({preventScroll: true});
		};

		let isStarting = false;

		this.on(copyForm, 'submit', async event => {
			event.preventDefault();
			if (isStarting) {
				return;
			}

			if (normalize(copyAnswer.value) === copyWord) {
				this.store('copy', true);
				isStarting = true;
				this.say('Thank you for buying Sindre’s Quest!', copyStatus);
				await this.wait(900);
				isStarting = false;
				startGame();
				return;
			}

			copyTries++;
			if (copyTries >= 3) {
				isStarting = true;
				this.say('Fine. Mamma says sharing is caring. Starting anyway…', copyStatus);
				await this.wait(1500);
				isStarting = false;
				startGame();
				return;
			}

			this.say(randomItem(['Nice try, pirate! Real pirates live on Monkey Island.', 'That is not it. Did you borrow this game from Kevin?', 'Wrong! Count again, and do not count the title.']), copyStatus);
			copyAnswer.select();
		});

		this.on(startButton, 'click', () => {
			if (this.stored('copy', false)) {
				startGame();
			} else {
				askCopyProtection();
			}
		});

		// Three saved games in the browser, each with where it is, its score, and when it was saved.
		let saveMode = 'save';

		const showSaves = async mode => {
			if (mode === 'save' && (state.scene === 'title' || isOver || isBusy)) {
				this.toast('💾 Start a game first, then save it.');
				return;
			}

			saveMode = mode;
			savesTitle.textContent = mode === 'save' ? 'Save Game' : 'Load Game';
			const slots = this.stored('saves', []);
			for (const [index, button] of slotButtons.entries()) {
				const slot = slots[index];
				button.textContent = slot ? `${index + 1}. ${slot.label}` : `${index + 1}. Empty`;
			}

			await showPanel(savesPanel);
			slotButtons[0].focus({preventScroll: true});
		};

		for (const [index, button] of slotButtons.entries()) {
			this.on(button, 'click', () => {
				const slots = this.stored('saves', []);
				if (saveMode === 'save') {
					const time = new Date().toLocaleString('en-US', {month: 'short', day: 'numeric', hour: 'numeric', minute: '2-digit'});
					slots[index] = {state: structuredClone(state), label: `${sceneNames[state.scene] ?? 'Bergen'}, ${score()} points, ${time}`};
					this.store('saves', slots);
					closePanel();
					this.toast(`💾 Saved in slot ${index + 1}.`);
					return;
				}

				if (!slots[index]) {
					button.textContent = `${index + 1}. Empty! Nothing to load.`;
					return;
				}

				state = structuredClone(slots[index].state);
				state.flags.isDead = false;
				isOver = false;
				startButton.textContent = '▶ New Game';
				closePanel();
				updateAll();
				canvas.focus({preventScroll: true});
				this.toast(`📂 Loaded slot ${index + 1}.`);
			});
		}

		// The hint line, with a bill that grows with each hint, kept in the browser like a real phone bill.
		let hintSet = '';

		const showBill = callCost => {
			hintBill.textContent = `This call: kr ${callCost.toFixed(2)}. Mamma’s phone bill so far: kr ${bill.toFixed(2)}.`;
		};

		let callCost = 0;

		const giveHint = async () => {
			const hints = state.scene === 'title' ? ['Start a game first! You can’t get stuck in a game you haven’t started. Thank you for calling.'] : (isOver ? ['You finished the game! Why are you calling? This is still kr 9.90.'] : currentHints());
			if (hints[0] !== hintSet) {
				hintSet = hints[0];
				hintStep = 0;
			}

			bill = Math.round((bill + 9.9) * 100) / 100;
			callCost += 9.9;
			this.store('bill', bill);
			showBill(callCost);
			this.say(hints[hintStep], hintText);
			hintStep = Math.min(hintStep + 1, hints.length - 1);
		};

		let call = 0;

		const callHintLine = async () => {
			call++;
			const thisCall = call;
			callCost = 0;
			hintText.textContent = '';
			showBill(0);
			await showPanel(hintPanel);
			hintPanel.querySelector('button').focus({preventScroll: true});
			beep(440, 0.4, {type: 'sine'});
			beep(480, 0.4, {type: 'sine', when: 0});
			this.say('Ring, ring… “Welcome to the Sindresoft Hint Line! This call costs kr 9.90 a minute.”', hintText);
			await this.wait(1600);
			if (openPanel === hintPanel && thisCall === call) {
				await giveHint();
			}
		};

		const actions = {
			load: () => showSaves('load'),
			save: () => showSaves('save'),
			close: closePanel,
			retry,
			restart() {
				closePanel();
				if (state.scene === 'title') {
					startButton.click();
				} else {
					startGame();
				}
			},
			call: callHintLine,
			hint: giveHint,
			sound: () => {
				// The other adventure games of the page listen too, so one button turns on the sound of all of them, and this game hears it like they do.
				document.dispatchEvent(new CustomEvent('geocities-adventure-sound', {detail: {isOn: !this.#isSoundOn}}));
				beep(660, 0.1);
				soundButton.textContent = this.#isSoundOn ? '🔊 Sound: On' : '🔈 Sound: Off';
				setPressed(soundButton, this.#isSoundOn);
			},
		};

		for (const button of this.querySelectorAll('[data-adventure-action]')) {
			this.on(button, 'click', () => {
				if (isBusy && button.dataset.adventureAction !== 'sound' && button.dataset.adventureAction !== 'call' && button.dataset.adventureAction !== 'hint' && button.dataset.adventureAction !== 'close') {
					return;
				}

				// The death window waits for Try Again, Restore, or Restart, so it cannot be covered by the hint line or the save window.
				const action = button.dataset.adventureAction;
				if (openPanel === deathPanel && (action === 'call' || action === 'save')) {
					return;
				}

				actions[action]();
			});
		}

		// The box art: Sindre on Fløyen, the troll with the Golden Waffle, and a seagull, like the painted boxes of the games of the time.
		{
			const {cover} = this.parts;
			const coverContext = cover.getContext('2d');
			const gradient = coverContext.createLinearGradient(0, 0, 0, 100);
			gradient.addColorStop(0, '#2a1050');
			gradient.addColorStop(0.6, '#d0602a');
			gradient.addColorStop(1, '#ffd27a');
			coverContext.fillStyle = gradient;
			coverContext.fillRect(0, 0, 160, 100);
			fillEllipse(coverContext, '#ffe8a0', 80, 70, 26, 26);
			fillPolygon(coverContext, '#1a2a3a', [[0, 70], [30, 40], [60, 60], [90, 30], [130, 60], [160, 44], [160, 100], [0, 100]]);
			fillPolygon(coverContext, '#2a4a2a', [[0, 88], [60, 80], [120, 86], [160, 80], [160, 100], [0, 100]]);
			drawSprite(coverContext, sprites.troll, 112, 96, {scale: 2, isFlipped: true});
			drawWaffleIron(coverContext, 96, 64);
			drawSprite(coverContext, sprites.sindre, 46, 96, {scale: 2, colors: {b: palette.j}});
			drawSprite(coverContext, sprites.seagull, 140, 24, {scale: 2, isFlipped: true});
			fillShape(coverContext, '#c8c8c8', 56, 66, 8, 3);
			fillShape(coverContext, '#8b5a2b', 59, 69, 2, 5);
		}

		updateAll();

		return {
			visibilityChanged(isVisible) {
				if (isVisible) {
					// The scene is drawn again when it comes back, also where nothing moves.
					loop.requestStep();
				} else if (walkTarget !== undefined) {
					// Sindre does not wait for the loop to come back to finish his walk.
					state.x = walkTarget;
					walkTarget = undefined;
					walkDone?.();
					walkDone = undefined;
				}
			},
			reducedMotionChanged() {
				draw();
			},
		};
	}

	// The box of Sindre's Quest: the manual, a page at a time, the feelies, and the four floppy disks, which INSTALL asks for one at a time, like the installers of the time.
	#setUpBox() {
		const {openBox, contents, previousPage, nextPage, pageLabel, install: installButton, installStatus} = this.parts;
		const pages = [...this.querySelectorAll('[data-adventure-page]')];
		const disks = [...this.querySelectorAll('[data-adventure-disk]')];
		let page = 0;

		const showPage = index => {
			page = (index + pages.length) % pages.length;
			for (const [other, element] of pages.entries()) {
				element.hidden = other !== page;
			}

			pageLabel.textContent = `Page ${page + 1} of ${pages.length}`;
		};

		this.on(previousPage, 'click', () => {
			showPage(page - 1);
		});

		this.on(nextPage, 'click', () => {
			showPage(page + 1);
		});

		showPage(0);

		this.on(openBox, 'click', () => {
			const isOpen = contents.hidden;
			contents.hidden = !isOpen;
			openBox.setAttribute('aria-expanded', String(isOpen));
			openBox.textContent = isOpen ? '📦 Close the Box' : '📦 Open the Box';
		});

		const feelies = {
			ticket: '🎫 A Fløibanen ticket from the box. It says: NOT VALID ON FLØIBANEN. VALID ONLY IN THE GAME.',
			sticker: '🧀 Scratch, sniff… It smells of cardboard, glue, and 1999. Not of brown cheese at all.',
			map: '🗺️ A cloth map of Bergen. It is mostly blue. That is the rain.',
			card: '📮 Send in the registration card and win a Sindresoft T-shirt! Address: Sindre, his room, Bergen.',
		};

		for (const button of this.querySelectorAll('[data-adventure-feelie]')) {
			this.on(button, 'click', () => {
				this.toast(feelies[button.dataset.adventureFeelie]);
			});
		}

		let neededDisk = 0;
		let isCopying = false;

		const progressBar = percent => `[${'█'.repeat(percent / 5)}${'·'.repeat(20 - (percent / 5))}] ${percent}%`;

		this.on(installButton, 'click', async () => {
			if (isCopying) {
				return;
			}

			neededDisk = 1;
			for (const disk of disks) {
				disk.dataset.state = '';
			}

			this.say(`C:\\> INSTALL\nInstalling Sindre’s Quest to C:\\SINDRE\n${progressBar(0)}\nPlease insert Disk 1 and click it.`, installStatus);
		});

		for (const disk of disks) {
			this.on(disk, 'click', async () => {
				const number = Number(disk.dataset.adventureDisk);
				if (isCopying) {
					return;
				}

				if (neededDisk === 0) {
					this.say('A:\\> _\nThat is a floppy disk. Click INSTALL first, then the disks.', installStatus);
					return;
				}

				if (number !== neededDisk) {
					this.say(number === 3 ? `Disk 3 is the coolest disk, but please insert Disk ${neededDisk}.` : `That is Disk ${number}. Please insert Disk ${neededDisk}.`, installStatus);
					return;
				}

				isCopying = true;
				// The bar fills without being read out at each step, and the next line is announced when it is done.
				installStatus.setAttribute('aria-busy', 'true');
				const from = (number - 1) * 25;
				for (let percent = from; percent <= number * 25; percent += 5) {
					installStatus.textContent = `Copying SINDRE.${String(number).padStart(3, '0')} from Disk ${number}…\n${progressBar(percent)}`;
					// The disk drive was slow, so the bar fills slowly, unless the visitor prefers reduced motion.
					await this.wait(this.reducedMotion ? 0 : 200);
				}

				isCopying = false;
				installStatus.removeAttribute('aria-busy');
				disk.dataset.state = 'done';
				if (number === 4) {
					neededDisk = 0;
					this.say(`${progressBar(100)}\nInstallation complete! 4 disks, 5.76 MB.\nSindre’s Quest is in C:\\SINDRE. Have fun!`, installStatus);
					this.toast('💾 Sindre’s Quest is installed. It was already playable, but now it is installed.');
					return;
				}

				neededDisk = number + 1;
				this.say(`${progressBar(number * 25)}\nPlease insert Disk ${neededDisk} and click it.`, installStatus);
			});
		}
	}
}
