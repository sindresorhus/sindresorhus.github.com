// Christmas in Bergen on the 1999 page, three toys with the Norwegian traditions of Christmas: Pepperkakebyen, where the visitor builds a gingerbread house, glues it with icing, decorates it, and brings it to the gingerbread town with the little train, Nisse Bowling, like Elf Bowling, where Julenissen bowls at ten nisser who taunt him, and the porridge of Christmas Eve, with the almond, the marzipan pig, and the bowl for the barn nisse, who plays pranks on the page when he gets no butter. Each canvas runs only while it is on the screen and the tab is visible. The pranks of the nisse reach outside the element, on the rest of the page, and go on while the toy is off screen (but not while the tab is hidden), and he puts them all back when he gets a bowl with butter, or when the toy is removed. With reduced motion, nothing moves by itself. Nothing makes a sound until the visitor turns on the sound or plays a song.
const randomItem = items => items[Math.floor(Math.random() * items.length)];
const randomBetween = (minimum, maximum) => minimum + (Math.random() * (maximum - minimum));
const randomInteger = (minimum, maximum) => Math.floor(randomBetween(minimum, maximum + 1));
const clamp = (value, minimum, maximum) => Math.min(Math.max(value, minimum), maximum);
const lerp = (from, to, amount) => from + ((to - from) * amount);

// The position of a pointer on a canvas, in the pixels of the canvas.
const canvasPoint = (canvas, event) => {
	const rectangle = canvas.getBoundingClientRect();
	return {
		x: (event.clientX - rectangle.left) * canvas.width / rectangle.width,
		y: (event.clientY - rectangle.top) * canvas.height / rectangle.height,
	};
};

const setPressed = (button, isPressed) => {
	button.ariaPressed = String(isPressed);
	if (isPressed) {
		button.dataset.state = 'on';
	} else {
		delete button.dataset.state;
	}
};

// A speech bubble on a canvas, with its tail down to the one who speaks. It stays inside the canvas.
const drawBubble = (context, text, x, y) => {
	const size = 10;
	context.save();
	context.font = `bold ${size}px "Comic Sans MS", "Comic Sans", "Chalkboard SE", "Comic Neue", cursive`;
	const words = text.split(' ');
	const lines = [];
	let line = '';
	for (const word of words) {
		const candidate = line ? `${line} ${word}` : word;
		if (context.measureText(candidate).width > 120 && line) {
			lines.push(line);
			line = word;
		} else {
			line = candidate;
		}
	}

	lines.push(line);
	const width = Math.max(...lines.map(item => context.measureText(item).width)) + 12;
	const height = (lines.length * (size + 2)) + 8;
	const left = clamp(x - (width / 2), 2, context.canvas.width - width - 2);
	const top = Math.max(2, y - height - 8);
	context.fillStyle = '#ffffff';
	context.strokeStyle = '#000000';
	context.lineWidth = 1.5;
	context.beginPath();
	context.roundRect(left, top, width, height, 7);
	context.moveTo(clamp(x - 4, left + 6, left + width - 12), top + height);
	context.lineTo(clamp(x, left + 2, left + width - 2), Math.min(y, top + height + 8));
	context.lineTo(clamp(x + 4, left + 10, left + width - 6), top + height);
	context.fill();
	context.stroke();
	context.fillStyle = '#ffffff';
	context.fillRect(clamp(x - 3, left + 7, left + width - 11), top + height - 2, 6, 3);
	context.fillStyle = '#000000';
	context.textAlign = 'center';
	context.textBaseline = 'top';
	for (const [index, item] of lines.entries()) {
		context.fillText(item, left + (width / 2), top + 4 + (index * (size + 2)));
	}

	context.restore();
};

// The sounds, made in the browser once the visitor turns them on: sleigh bells, gingerbread, icing, the train, the bowling, the spoons, and the nisse.
const sound = {
	context: undefined,
	output: undefined,
	isOn: false,
	noise: undefined,
	// Starts the audio of the element, which is `undefined` when the browser does not allow it yet.
	start(audio) {
		if (!audio) {
			return false;
		}

		this.context = audio.context;
		this.output = audio.output;
		this.context.resume();

		if (!this.noise) {
			this.noise = new AudioBuffer({length: this.context.sampleRate * 2, sampleRate: this.context.sampleRate});
			const samples = this.noise.getChannelData(0);
			for (let index = 0; index < samples.length; index++) {
				samples[index] = (Math.random() * 2) - 1;
			}
		}

		return true;
	},
	get isRunning() {
		return this.isOn && this.context?.state === 'running';
	},
	tone(frequency, duration, {type = 'square', volume = 0.06, when = 0, slide, destination, force = false} = {}) {
		if (!(force ? this.context?.state === 'running' : this.isRunning)) {
			return;
		}

		const start = this.context.currentTime + when;
		const oscillator = new OscillatorNode(this.context, {type, frequency});
		const gain = new GainNode(this.context, {gain: 0});
		if (slide) {
			oscillator.frequency.setValueAtTime(frequency, start);
			oscillator.frequency.exponentialRampToValueAtTime(slide, start + duration);
		}

		gain.gain.setValueAtTime(0, start);
		gain.gain.linearRampToValueAtTime(volume, start + 0.005);
		gain.gain.exponentialRampToValueAtTime(0.0001, start + duration);
		oscillator.connect(gain).connect(destination ?? this.output);
		oscillator.start(start);
		oscillator.stop(start + duration + 0.02);
	},
	burst(duration, {volume = 0.2, frequency = 800, type = 'lowpass', when = 0, quality = 1, slide, destination, force = false} = {}) {
		if (!(force ? this.context?.state === 'running' : this.isRunning)) {
			return;
		}

		const start = this.context.currentTime + when;
		const source = new AudioBufferSourceNode(this.context, {buffer: this.noise});
		const filter = new BiquadFilterNode(this.context, {type, frequency, Q: quality});
		if (slide) {
			filter.frequency.setValueAtTime(frequency, start);
			filter.frequency.exponentialRampToValueAtTime(slide, start + duration);
		}

		const gain = new GainNode(this.context, {gain: 0});
		gain.gain.setValueAtTime(0, start);
		gain.gain.linearRampToValueAtTime(volume, start + 0.01);
		gain.gain.exponentialRampToValueAtTime(0.0001, start + duration);
		source.connect(filter).connect(gain).connect(destination ?? this.output);
		source.start(start, Math.random());
		source.stop(start + duration + 0.02);
	},
	// A shake of the sleigh bells: small bells of metal, a little out of time with each other.
	bells(count = 6, {when = 0, volume = 0.03, destination, force = false} = {}) {
		for (let index = 0; index < count; index++) {
			const at = when + (index * 0.035) + randomBetween(0, 0.02);
			const pitch = randomBetween(2600, 4200);
			this.tone(pitch, 0.18, {type: 'sine', volume, when: at, destination, force});
			this.tone(pitch * 2.76, 0.08, {type: 'sine', volume: volume / 2, when: at, destination, force});
		}

		this.burst(0.12, {volume: volume * 2, frequency: 7000, type: 'highpass', when, destination, force});
	},
	place() {
		this.tone(260, 0.07, {type: 'triangle', volume: 0.1});
		this.burst(0.05, {volume: 0.15, frequency: 900});
	},
	squeeze() {
		this.burst(0.08, {volume: 0.06, frequency: 500, type: 'bandpass', quality: 3, slide: 300});
	},
	candy() {
		this.tone(randomBetween(1400, 1900), 0.05, {type: 'triangle', volume: 0.06});
	},
	crunch() {
		for (let index = 0; index < 4; index++) {
			this.burst(0.06, {volume: 0.3, frequency: randomBetween(1200, 2400), type: 'bandpass', quality: 1.5, when: index * 0.09});
		}
	},
	crash() {
		this.burst(0.5, {volume: 0.35, frequency: 600, slide: 120});
		for (let index = 0; index < 5; index++) {
			this.tone(randomBetween(90, 160), 0.12, {type: 'triangle', volume: 0.12, when: index * 0.11});
		}
	},
	toot() {
		for (const when of [0, 0.45]) {
			this.tone(740, 0.35, {type: 'sine', volume: 0.07, when, slide: 700});
			this.tone(932, 0.35, {type: 'sine', volume: 0.05, when, slide: 880});
			this.burst(0.35, {volume: 0.05, frequency: 2000, type: 'bandpass', when, quality: 2});
		}
	},
	roll(duration) {
		this.burst(duration, {volume: 0.12, frequency: 160, quality: 2});
	},
	pin() {
		this.tone(randomBetween(700, 1100), 0.08, {type: 'triangle', volume: 0.08});
		this.burst(0.06, {volume: 0.15, frequency: 2500, type: 'bandpass', quality: 2});
	},
	gutter() {
		this.tone(300, 0.6, {type: 'sawtooth', volume: 0.04, slide: 90});
	},
	// “Ho ho ho!”, deep, from the belly of Julenissen.
	hoHoHo() {
		for (let index = 0; index < 3; index++) {
			this.tone(150, 0.22, {type: 'sawtooth', volume: 0.06, when: index * 0.28, slide: 105});
			this.burst(0.2, {volume: 0.12, frequency: 450, type: 'bandpass', quality: 4, when: index * 0.28});
		}
	},
	fanfare() {
		for (const [index, note] of [523, 659, 784, 1047].entries()) {
			this.tone(note, 0.25, {type: 'square', volume: 0.05, when: index * 0.1});
		}

		this.bells(10, {when: 0.2});
	},
	stir() {
		this.burst(0.18, {volume: 0.12, frequency: 1500, type: 'bandpass', quality: 1.5, slide: 900});
	},
	spoon() {
		this.tone(2600, 0.12, {type: 'sine', volume: 0.04});
		this.tone(3900, 0.06, {type: 'sine', volume: 0.02});
	},
	door() {
		this.tone(180, 0.6, {type: 'sawtooth', volume: 0.025, slide: 260});
		this.burst(0.5, {volume: 0.06, frequency: 700, type: 'bandpass', quality: 6});
	},
	// The nisse giggles, up to no good.
	giggle() {
		for (let index = 0; index < 6; index++) {
			this.tone(1100 + (index * 90), 0.07, {type: 'triangle', volume: 0.05, when: index * 0.08, slide: 1500});
		}
	},
	grumble() {
		this.tone(110, 0.5, {type: 'sawtooth', volume: 0.06, slide: 70});
		this.burst(0.5, {volume: 0.15, frequency: 300, quality: 3});
	},
};

// The Christmas songs, played with bells: “Bjelleklang” (“Jingle Bells”, 1857) with sleigh bells on the beat, and “Glade jul” (“Silent Night”, 1818). The notes are MIDI numbers, with their lengths in beats.
const songs = {
	bjelleklang: {
		name: '“Bjelleklang”',
		beat: 0.28,
		hasSleighBells: true,
		notes: [
			[64, 1], [64, 1], [64, 2], [64, 1], [64, 1], [64, 2], [64, 1], [67, 1], [60, 1.5], [62, 0.5], [64, 4],
			[65, 1], [65, 1], [65, 1.5], [65, 0.5], [65, 1], [64, 1], [64, 1], [64, 0.5], [64, 0.5], [64, 1], [62, 1], [62, 1], [64, 1], [62, 2], [67, 2],
			[64, 1], [64, 1], [64, 2], [64, 1], [64, 1], [64, 2], [64, 1], [67, 1], [60, 1.5], [62, 0.5], [64, 4],
			[65, 1], [65, 1], [65, 1.5], [65, 0.5], [65, 1], [64, 1], [64, 1], [64, 0.5], [64, 0.5], [67, 1], [67, 1], [65, 1], [62, 1], [60, 4],
		],
	},
	'glade-jul': {
		name: '“Glade jul”',
		beat: 0.32,
		hasSleighBells: false,
		notes: [
			[67, 1.5], [69, 0.5], [67, 1], [64, 3], [67, 1.5], [69, 0.5], [67, 1], [64, 3],
			[74, 2], [74, 1], [71, 3], [72, 2], [72, 1], [67, 3],
			[69, 2], [69, 1], [72, 1.5], [71, 0.5], [69, 1], [67, 1.5], [69, 0.5], [67, 1], [64, 3],
			[69, 2], [69, 1], [72, 1.5], [71, 0.5], [69, 1], [67, 1.5], [69, 0.5], [67, 1], [64, 3],
			[74, 2], [74, 1], [77, 1.5], [74, 0.5], [71, 1], [72, 3], [76, 3],
			[72, 1], [67, 1], [64, 1], [67, 1.5], [65, 0.5], [62, 1], [60, 6],
		],
	},
};

export default class extends GeoCitiesElement {
	#music = {playing: undefined, gain: undefined, timer: undefined};
	#toys = [];

	connected() {
		const {sound: soundButton} = this.parts;
		this.on(soundButton, 'click', () => {
			sound.isOn = !sound.isOn && sound.start(this.sound());
			setPressed(soundButton, sound.isOn);
			soundButton.textContent = sound.isOn ? '🔔 Sound On' : '🔔 Sound';
			// The audio can still be waking up after the click.
			sound.context?.resume().then(() => {
				sound.bells(8);
			}, () => {});
		});

		for (const button of this.#musicButtons) {
			this.on(button, 'click', () => {
				if (this.#music.playing === button.dataset.christmasMusic) {
					this.#stopMusic();
				} else {
					this.#playSong(button.dataset.christmasMusic);
				}
			});
		}

		this.#toys = [this.#setUpGingerbread(), this.#setUpBowling(), this.#setUpPorridge()];
	}

	disconnected() {
		this.#stopMusic();
		for (const toy of this.#toys) {
			toy.disconnected?.();
		}
	}

	reducedMotionChanged() {
		for (const toy of this.#toys) {
			toy.reducedMotionChanged();
		}
	}

	// One tune plays at a time on the page. It still tells the page that its song stopped, so the screen saver and the Furby know.
	musicStopped() {
		this.#stopMusic();
	}

	// A porridge button that disappears after it was used gives the focus to the next step of the evening.
	focusReplacement(control) {
		return control.dataset.christmasPorridge ? this.querySelector('[data-christmas-porridge]:not([hidden])') : super.focusReplacement(control);
	}

	get #musicButtons() {
		return [...this.querySelectorAll('[data-christmas-music]')];
	}

	#updateMusicButtons() {
		for (const button of this.#musicButtons) {
			const isPlaying = this.#music.playing === button.dataset.christmasMusic;
			setPressed(button, isPlaying);
			button.textContent = `${isPlaying ? '⏹ Stop' : '🎵 Play'} ${songs[button.dataset.christmasMusic].name}`;
		}
	}

	#stopMusic({isQuiet = false} = {}) {
		const music = this.#music;
		if (!music.playing) {
			return;
		}

		music.playing = undefined;
		clearTimeout(music.timer);
		music.gain?.gain.setTargetAtTime(0, sound.context.currentTime, 0.05);
		music.gain = undefined;
		this.#updateMusicButtons();
		if (!isQuiet) {
			this.music(false);
		}
	}

	#playSong(id) {
		if (!sound.start(this.sound())) {
			return;
		}

		this.#stopMusic({isQuiet: true});
		const music = this.#music;
		const song = songs[id];
		music.playing = id;
		music.gain = new GainNode(sound.context, {gain: 1});
		music.gain.connect(sound.output);
		this.#updateMusicButtons();
		this.music(true);

		// The audio can still be waking up after the click.
		const destination = music.gain;
		sound.context.resume().then(() => {
			if (music.gain !== destination) {
				return;
			}

			let when = 0.1;
			for (const [note, beats] of song.notes) {
				const frequency = 440 * (2 ** ((note - 69) / 12));
				const length = beats * song.beat;
				// A bell: the note, and the bright overtones of metal that die away fast.
				sound.tone(frequency, Math.max(length * 1.4, 0.4), {type: 'sine', volume: 0.09, when, destination, force: true});
				sound.tone(frequency * 2, length, {type: 'triangle', volume: 0.025, when, destination, force: true});
				sound.tone(frequency * 3.01, 0.15, {type: 'sine', volume: 0.02, when, destination, force: true});
				when += length;
			}

			if (song.hasSleighBells) {
				for (let beat = 0.1; beat < when; beat += song.beat * 2) {
					sound.bells(3, {when: beat, volume: 0.012, destination, force: true});
				}
			}

			music.timer = setTimeout(() => {
				if (music.gain === destination) {
					this.#stopMusic();
				}
			}, (when + 1) * 1000);
		}, () => {});
	}

	#setUpGingerbread() {
		// Pepperkakebyen: the gingerbread house on the cake board, in a front view. The pieces stand in six columns, like the gables of Bryggen: walls on the board or on walls, a gable roof on the top wall, and a chimney on the roof. Each seam between two pieces, and between a wall and the board, needs icing, or the piece falls off when the icing dries or on the way to the town.
		const {house: houseCanvas, houseStatus, houseName: nameField, town: townCanvas, toot: tootButton} = this.parts;
		const houseContext = houseCanvas.getContext('2d');
		const townContext = townCanvas.getContext('2d');
		const toolButtons = [...this.querySelectorAll('[data-christmas-tool]')];
		const houseActionButtons = [...this.querySelectorAll('[data-christmas-house-action]')];

		const houseWidth = houseCanvas.width;
		const houseHeight = houseCanvas.height;
		const boardTop = 232;
		const columnLeft = 30;
		const columnWidth = 50;
		const columnCount = 6;
		const rowHeight = 46;
		const roofHeight = 40;
		const maximumWalls = 3;
		const icingCell = 3;
		const icingColumns = Math.ceil(houseWidth / icingCell);
		const icingRows = Math.ceil(houseHeight / icingCell);
		const maximumIcingPoints = 2500;

		const gingerbread = {
			light: '#c8803e',
			base: '#a8622a',
			dark: '#7a3f17',
			edge: '#5a2c0e',
		};

		const smartiesColors = ['#e32636', '#ffcc00', '#2e7d32', '#1565c0', '#ff7f00', '#8e24aa', '#ff69b4', '#6d3b1d'];
		const bearColors = ['#e53935', '#43a047', '#fdd835', '#fb8c00', '#ffffff'];

		const toolMessages = {
			wall: 'A wall. Tap a column on the cake board, and it goes on top.',
			roof: 'A gable roof, like on Bryggen. It goes on the top wall of a column.',
			chimney: 'A chimney, for Julenissen. It goes on a roof.',
			icing: 'The piping bag! Drag along the red dashes: the seams where the pieces meet each other and the board.',
			smarties: 'Smarties! They only stick where there is icing.',
			bear: 'Gummy bears! They only stick where there is icing.',
			licorice: 'Licorice (lakris), in long strips. It only sticks where there is icing.',
			peppermint: 'Peppermint candy, red and white. It only sticks where there is icing.',
		};

		// What to do next, after a piece is on the board.
		const placedMessages = {
			wall: 'A wall! Tap again for one more on top, or tap another column. Then pick 🔺 Roof.',
			roof: 'A roof! Now pick the 🧁 Piping Bag, and pipe icing on the red dashes.',
			chimney: 'A chimney for Julenissen! Glue it on with the 🧁 Piping Bag.',
		};

		const emptyHouse = () => ({pieces: [], strokes: [], candies: [], snow: [], name: '', nextId: 1});

		const house = {
			model: emptyHouse(),
			tool: 'wall',
			history: [],
			falling: [],
			rubble: [],
			icing: new Uint8Array(icingColumns * icingRows),
			stroke: undefined,
			cursor: {x: 180, y: 150},
			isFocused: false,
			isKeyPiping: false,
			lastSqueeze: 0,
		};

		// The rectangle of a piece, and for a roof its gable, in the pixels of the canvas.
		const pieceBounds = piece => {
			const left = columnLeft + (piece.column * columnWidth);
			const bottom = boardTop - (piece.row * rowHeight);
			if (piece.kind === 'wall') {
				return {left, right: left + columnWidth, top: bottom - rowHeight, bottom};
			}

			if (piece.kind === 'roof') {
				return {left: left - 5, right: left + columnWidth + 5, top: bottom - roofHeight, bottom};
			}

			// The chimney stands on the right slope of the roof.
			const chimneyLeft = left + 31;
			return {left: chimneyLeft, right: chimneyLeft + 10, top: bottom - roofHeight - 4, bottom: bottom - 14};
		};

		const roofPath = (context, bounds) => {
			context.beginPath();
			context.moveTo(bounds.left, bounds.bottom);
			context.lineTo((bounds.left + bounds.right) / 2, bounds.top);
			context.lineTo(bounds.right, bounds.bottom);
			context.closePath();
		};

		const isInsidePiece = (piece, x, y) => {
			const bounds = pieceBounds(piece);
			if (x < bounds.left || x > bounds.right || y < bounds.top || y > bounds.bottom) {
				return false;
			}

			return piece.kind !== 'roof' || y >= roofTop(bounds, x);
		};

		// The height of the slope of a gable roof at a place.
		const roofTop = (bounds, x) => {
			const middle = (bounds.left + bounds.right) / 2;
			return bounds.top + ((Math.abs(x - middle) / (middle - bounds.left)) * (bounds.bottom - bounds.top));
		};

		const pieceAt = (model, x, y) => model.pieces.findLast(piece => isInsidePiece(piece, x, y));

		// The icing is kept on a grid of small cells, so the seams and the candy can find it fast.
		const rebuildIcing = () => {
			house.icing.fill(0);
			for (const stroke of house.model.strokes) {
				for (const [index, point] of stroke.entries()) {
					markIcingLine(stroke[index - 1] ?? point, point);
				}
			}
		};

		const markIcingLine = (from, to) => {
			const steps = Math.max(1, Math.ceil(Math.hypot(to.x - from.x, to.y - from.y) / 2));
			for (let step = 0; step <= steps; step++) {
				markIcing(lerp(from.x, to.x, step / steps), lerp(from.y, to.y, step / steps));
			}
		};

		const markIcing = (x, y) => {
			const column = Math.floor(x / icingCell);
			const row = Math.floor(y / icingCell);
			for (let rowOffset = -1; rowOffset <= 1; rowOffset++) {
				for (let columnOffset = -1; columnOffset <= 1; columnOffset++) {
					const cellColumn = column + columnOffset;
					const cellRow = row + rowOffset;
					if (cellColumn >= 0 && cellColumn < icingColumns && cellRow >= 0 && cellRow < icingRows) {
						house.icing[(cellRow * icingColumns) + cellColumn] = 1;
					}
				}
			}
		};

		const hasIcing = (x, y) => {
			const column = Math.floor(x / icingCell);
			const row = Math.floor(y / icingCell);
			return column >= 0 && column < icingColumns && row >= 0 && row < icingRows && house.icing[(row * icingColumns) + column] === 1;
		};

		// The seams of the house: where a piece stands on the board or on another piece, and where two walls meet side by side.
		const houseSeams = model => {
			const seams = [];
			const find = (kind, column, row) => model.pieces.find(piece => piece.kind === kind && piece.column === column && piece.row === row);
			for (const piece of model.pieces) {
				const bounds = pieceBounds(piece);
				if (piece.kind === 'wall') {
					seams.push({upper: piece, lower: piece.row === 0 ? 'board' : find('wall', piece.column, piece.row - 1), from: {x: bounds.left + 5, y: bounds.bottom}, to: {x: bounds.right - 5, y: bounds.bottom}, isSide: false});
					const neighbor = find('wall', piece.column + 1, piece.row);
					if (neighbor) {
						seams.push({upper: piece, lower: neighbor, from: {x: bounds.right, y: bounds.top + 5}, to: {x: bounds.right, y: bounds.bottom - 5}, isSide: true});
					}
				} else if (piece.kind === 'roof') {
					seams.push({upper: piece, lower: find('wall', piece.column, piece.row - 1), from: {x: bounds.left + 8, y: bounds.bottom}, to: {x: bounds.right - 8, y: bounds.bottom}, isSide: false});
				} else {
					seams.push({upper: piece, lower: find('roof', piece.column, piece.row), from: {x: bounds.left, y: bounds.bottom - 2}, to: {x: bounds.right, y: bounds.bottom - 6}, isSide: false});
				}
			}

			return seams;
		};

		// Icing a little beside the seam glues it too, as a finger hides the seam while it pipes.
		const isGlued = seam => {
			const samples = 7;
			const reach = [0, -4, 4];
			let covered = 0;
			for (let index = 0; index < samples; index++) {
				const amount = index / (samples - 1);
				const x = lerp(seam.from.x, seam.to.x, amount);
				const y = lerp(seam.from.y, seam.to.y, amount);
				if (reach.some(offset => seam.isSide ? hasIcing(x + offset, y) : hasIcing(x, y + offset))) {
					covered++;
				}
			}

			return covered >= 4;
		};

		// The pieces that fall: every piece that does not hang together with the board. A piece hangs on the one under it by its weight while the house stands still, but only by icing when it dries or rides in the car. Walls side by side only hold each other with icing.
		const fallingPieces = ({needsIcing}) => {
			const seams = houseSeams(house.model);
			const standing = new Set(['board']);
			let didChange = true;
			while (didChange) {
				didChange = false;
				for (const seam of seams) {
					if (!seam.lower) {
						continue;
					}

					const holds = (seam.isSide || needsIcing) ? isGlued(seam) : true;
					if (!holds) {
						continue;
					}

					if (standing.has(seam.lower) && !standing.has(seam.upper)) {
						standing.add(seam.upper);
						didChange = true;
					} else if (seam.isSide && standing.has(seam.upper) && !standing.has(seam.lower)) {
						standing.add(seam.lower);
						didChange = true;
					}
				}
			}

			return house.model.pieces.filter(piece => !standing.has(piece));
		};

		const saveDraft = () => {
			this.store('house', house.model);
		};

		const remember = () => {
			house.history.push(structuredClone(house.model));
			if (house.history.length > 40) {
				house.history.shift();
			}
		};

		const columnStack = column => {
			const pieces = house.model.pieces.filter(piece => piece.column === column);
			return {
				walls: pieces.filter(piece => piece.kind === 'wall').length,
				roof: pieces.find(piece => piece.kind === 'roof'),
				chimney: pieces.find(piece => piece.kind === 'chimney'),
			};
		};

		const addPiece = (kind, column) => {
			const stack = columnStack(column);
			if (kind === 'wall') {
				if (stack.roof) {
					return 'A wall on top of the roof? Pappa says nei.';
				}

				if (stack.walls >= maximumWalls) {
					return 'Too tall! It would not fit in the Volvo.';
				}
			} else if (kind === 'roof') {
				if (stack.walls === 0) {
					return 'A roof needs a wall under it.';
				}

				if (stack.roof) {
					return 'That column has a roof already.';
				}
			} else if (!stack.roof) {
				return 'A chimney goes on a roof.';
			} else if (stack.chimney) {
				return 'One chimney is enough, even for Julenissen.';
			}

			remember();
			const piece = {id: house.model.nextId++, kind, column, row: stack.walls, bites: [], detail: undefined};
			if (kind === 'wall') {
				piece.detail = piece.row === 0 && Math.random() < 0.55 ? 'door' : randomItem(['window', 'window', 'heart', 'round']);
			}

			house.model.pieces.push(piece);
			sound.place();
			return placedMessages[kind];
		};

		const addCandy = (kind, x, y) => {
			const piece = pieceAt(house.model, x, y);
			const sticks = piece && hasIcing(x, y);
			const candy = {
				kind,
				x: Math.round(x),
				y: Math.round(y),
				angle: Math.round(randomBetween(-40, 40)),
				color: kind === 'bear' ? randomItem(bearColors) : randomItem(smartiesColors),
				piece: piece?.id,
			};

			if (!sticks) {
				// It slides down and falls off the house, onto the table.
				house.falling.push({type: 'candy', candy, x, y, vx: randomBetween(-30, 30), vy: 0, angle: candy.angle, spin: randomBetween(-200, 200), floor: randomBetween(244, 262)});
				if (this.reducedMotion) {
					settleFalling();
				}

				houseLoop.start();
				sound.candy();
				return piece ? 'No icing there, so it slid off! Pipe some icing first.' : 'It fell on the table. Candy needs icing on a piece of the house.';
			}

			remember();
			house.model.candies.push(candy);
			sound.candy();
			return undefined;
		};

		const pipe = (x, y) => {
			if (countIcingPoints() >= maximumIcingPoints) {
				return false;
			}

			const stroke = house.stroke;
			const last = stroke.at(-1);
			if (last && Math.hypot(last.x - x, last.y - y) < 2) {
				return true;
			}

			stroke.push({x: Math.round(x), y: Math.round(y)});
			markIcingLine(last ?? {x, y}, {x, y});

			const now = performance.now();
			if (now - house.lastSqueeze > 90) {
				house.lastSqueeze = now;
				sound.squeeze();
			}

			return true;
		};

		const countIcingPoints = () => {
			let count = 0;
			for (const stroke of house.model.strokes) {
				count += stroke.length;
			}

			return count;
		};

		const startStroke = (x, y) => {
			if (countIcingPoints() >= maximumIcingPoints) {
				this.say('The piping bag is empty! Mamma says that is enough icing for one house.', houseStatus);
				return;
			}

			remember();
			house.stroke = [];
			house.model.strokes.push(house.stroke);
			pipe(x, y);
		};

		const endStroke = () => {
			if (!house.stroke) {
				return;
			}

			house.stroke = undefined;
			const seams = houseSeams(house.model).filter(seam => seam.lower);
			const glued = seams.filter(seam => isGlued(seam)).length;
			this.say(seams.length > 0 ? `Icing on ${glued} of ${seams.length} seams.${glued === seams.length ? ' All of them! Now the candy, or 🚗 Bring It to the Town.' : ''}` : 'Icing! Now build something to glue.', houseStatus);
			saveDraft();
		};

		// The pieces that fall tumble down to the table, with the candy on them, and break into rubble.
		const dropPieces = pieces => {
			const ids = new Set(pieces.map(piece => piece.id));
			for (const piece of pieces) {
				const bounds = pieceBounds(piece);
				house.falling.push({
					type: 'piece',
					piece,
					candies: house.model.candies.filter(candy => candy.piece === piece.id),
					x: (bounds.left + bounds.right) / 2,
					y: (bounds.top + bounds.bottom) / 2,
					offsetX: (bounds.left + bounds.right) / 2,
					offsetY: (bounds.top + bounds.bottom) / 2,
					vx: randomBetween(-60, 60),
					vy: randomBetween(-40, 0),
					angle: 0,
					spin: randomBetween(-240, 240),
					floor: randomBetween(240, 258),
				});
			}

			house.model.pieces = house.model.pieces.filter(piece => !ids.has(piece.id));
			house.model.candies = house.model.candies.filter(candy => !ids.has(candy.piece));
			house.model.snow = house.model.snow.filter(flake => !ids.has(flake.piece));
			// The icing on the pieces that fell goes with them. A stroke that went over a fallen piece breaks into the parts that are left, so no icing is drawn across the gap.
			const strokes = [];
			for (const stroke of house.model.strokes) {
				let part = [];
				for (const point of stroke) {
					const isKept = !pieces.some(piece => isInsidePiece(piece, point.x, point.y)) || pieceAt(house.model, point.x, point.y);
					if (isKept) {
						part.push(point);
					} else if (part.length > 0) {
						strokes.push(part);
						part = [];
					}
				}

				if (part.length > 0) {
					strokes.push(part);
				}
			}

			house.model.strokes = strokes;
			rebuildIcing();
			sound.crash();
			if (this.reducedMotion) {
				settleFalling();
			}

			houseLoop.start();
		};

		const settleFalling = () => {
			for (const item of house.falling) {
				addRubble(item);
			}

			house.falling = [];
		};

		const addRubble = item => {
			house.rubble.push({type: item.type, kind: item.piece?.kind, candy: item.candy, x: clamp(item.x, 20, houseWidth - 20), y: item.floor, angle: Math.round(randomBetween(-30, 30) + (item.type === 'piece' ? 90 * randomInteger(0, 1) : 0))});
			if (house.rubble.length > 30) {
				house.rubble.shift();
			}
		};

		const stepFalling = seconds => {
			for (const item of house.falling) {
				item.vy += 600 * seconds;
				item.x += item.vx * seconds;
				item.y += item.vy * seconds;
				item.angle += item.spin * seconds;
			}

			const landed = house.falling.filter(item => item.y >= item.floor);
			for (const item of landed) {
				addRubble(item);
			}

			house.falling = house.falling.filter(item => item.y < item.floor);
		};

		const houseLoop = this.loop(seconds => {
			stepFalling(seconds);
			drawHouse();
		}, {while: () => house.falling.length > 0 && !this.reducedMotion, target: houseCanvas});

		// Draws a piece of gingerbread, with its cut-out window or door, and the dents of a fork, which every gingerbread has.
		const drawPiece = (context, piece, bounds = pieceBounds(piece)) => {
			context.save();
			context.lineWidth = 2;
			context.strokeStyle = gingerbread.edge;
			if (piece.kind === 'roof') {
				roofPath(context, bounds);
				const gradient = context.createLinearGradient(0, bounds.top, 0, bounds.bottom);
				gradient.addColorStop(0, gingerbread.base);
				gradient.addColorStop(1, gingerbread.dark);
				context.fillStyle = gradient;
				context.fill();
				context.stroke();
				context.save();
				roofPath(context, bounds);
				context.clip();
				context.strokeStyle = '#6a3412';
				context.lineWidth = 1;
				for (let y = bounds.bottom - 8; y > bounds.top; y -= 8) {
					for (let x = bounds.left + ((y / 8) % 2 === 0 ? 0 : 5); x < bounds.right; x += 10) {
						context.beginPath();
						context.arc(x, y, 5, 0, Math.PI);
						context.stroke();
					}
				}

				context.restore();
			} else {
				const gradient = context.createLinearGradient(bounds.left, bounds.top, bounds.right, bounds.bottom);
				gradient.addColorStop(0, gingerbread.light);
				gradient.addColorStop(1, gingerbread.base);
				context.fillStyle = gradient;
				context.beginPath();
				context.roundRect(bounds.left + 1, bounds.top + 1, bounds.right - bounds.left - 2, bounds.bottom - bounds.top - 2, 3);
				context.fill();
				context.stroke();
				context.fillStyle = gingerbread.dark;
				for (let index = 0; index < 5; index++) {
					const x = bounds.left + 6 + (((piece.id * 13) + (index * 17)) % Math.max(1, bounds.right - bounds.left - 12));
					const y = bounds.top + 6 + (((piece.id * 7) + (index * 23)) % Math.max(1, bounds.bottom - bounds.top - 12));
					context.fillRect(x, y, 1.5, 1.5);
				}
			}

			if (piece.kind === 'wall') {
				const middle = (bounds.left + bounds.right) / 2;
				context.fillStyle = '#2b1305';
				if (piece.detail === 'door') {
					context.beginPath();
					context.roundRect(middle - 8, bounds.bottom - 26, 16, 25, [8, 8, 0, 0]);
					context.fill();
					context.fillStyle = '#ffcc33';
					context.fillRect(middle + 3, bounds.bottom - 13, 2, 2);
				} else {
					// The window glows, as there is a candle inside, like in the real Pepperkakebyen.
					context.fillStyle = '#ffd25a';
					if (piece.detail === 'heart') {
						context.beginPath();
						context.moveTo(middle, bounds.top + 32);
						context.bezierCurveTo(middle - 14, bounds.top + 20, middle - 8, bounds.top + 8, middle, bounds.top + 16);
						context.bezierCurveTo(middle + 8, bounds.top + 8, middle + 14, bounds.top + 20, middle, bounds.top + 32);
						context.fill();
					} else if (piece.detail === 'round') {
						context.beginPath();
						context.arc(middle, bounds.top + 22, 9, 0, Math.PI * 2);
						context.fill();
						context.strokeStyle = gingerbread.edge;
						context.lineWidth = 1.5;
						context.stroke();
					} else {
						context.fillRect(middle - 11, bounds.top + 12, 22, 20);
						context.strokeStyle = gingerbread.base;
						context.lineWidth = 2;
						context.beginPath();
						context.moveTo(middle, bounds.top + 12);
						context.lineTo(middle, bounds.top + 32);
						context.moveTo(middle - 11, bounds.top + 22);
						context.lineTo(middle + 11, bounds.top + 22);
						context.stroke();
					}
				}
			}

			context.restore();
		};

		const drawCandy = (context, candy, x = candy.x, y = candy.y, angle = candy.angle) => {
			context.save();
			context.translate(x, y);
			context.rotate(angle * Math.PI / 180);
			if (candy.kind === 'smarties') {
				context.fillStyle = candy.color;
				context.beginPath();
				context.ellipse(0, 0, 4.5, 3.5, 0, 0, Math.PI * 2);
				context.fill();
				context.fillStyle = '#ffffff99';
				context.beginPath();
				context.arc(-1.5, -1.2, 1.2, 0, Math.PI * 2);
				context.fill();
			} else if (candy.kind === 'bear') {
				context.fillStyle = candy.color === '#ffffff' ? '#f4f0e0' : candy.color;
				context.globalAlpha = 0.85;
				context.beginPath();
				context.arc(0, -4, 3, 0, Math.PI * 2);
				context.arc(-2.5, -6.5, 1.3, 0, Math.PI * 2);
				context.arc(2.5, -6.5, 1.3, 0, Math.PI * 2);
				context.ellipse(0, 1.5, 3.5, 4, 0, 0, Math.PI * 2);
				context.arc(-3.5, 0, 1.5, 0, Math.PI * 2);
				context.arc(3.5, 0, 1.5, 0, Math.PI * 2);
				context.arc(-2, 5, 1.6, 0, Math.PI * 2);
				context.arc(2, 5, 1.6, 0, Math.PI * 2);
				context.fill();
				context.globalAlpha = 1;
				context.fillStyle = '#00000066';
				context.fillRect(-1.5, -4.8, 1, 1);
				context.fillRect(0.5, -4.8, 1, 1);
			} else if (candy.kind === 'licorice') {
				context.fillStyle = '#1a1a1a';
				context.beginPath();
				context.roundRect(-9, -2, 18, 4, 2);
				context.fill();
				context.strokeStyle = '#555555';
				context.lineWidth = 0.6;
				for (let index = -7; index < 9; index += 3) {
					context.beginPath();
					context.moveTo(index, -2);
					context.lineTo(index + 1.5, 2);
					context.stroke();
				}
			} else {
				context.fillStyle = '#ffffff';
				context.beginPath();
				context.arc(0, 0, 5, 0, Math.PI * 2);
				context.fill();
				context.fillStyle = '#d6001c';
				for (let index = 0; index < 4; index++) {
					context.beginPath();
					context.moveTo(0, 0);
					context.arc(0, 0, 5, index * Math.PI / 2, (index * Math.PI / 2) + 0.7);
					context.closePath();
					context.fill();
				}

				context.strokeStyle = '#99999966';
				context.lineWidth = 0.5;
				context.beginPath();
				context.arc(0, 0, 5, 0, Math.PI * 2);
				context.stroke();
			}

			context.restore();
		};

		const drawIcing = (context, strokes) => {
			context.save();
			context.lineCap = 'round';
			context.lineJoin = 'round';
			// A gray shadow under the white icing.
			for (const [width, color, offset] of [[6, '#c9c4b8', 0.7], [4.5, '#ffffff', 0]]) {
				context.lineWidth = width;
				context.strokeStyle = color;
				for (const stroke of strokes) {
					context.beginPath();
					for (const point of stroke) {
						context.lineTo(point.x + offset, point.y + offset);
					}

					// A dot of icing is a very short line, so its round caps draw it.
					if (stroke.length === 1) {
						context.lineTo(stroke[0].x + offset + 0.5, stroke[0].y + offset + 0.5);
					}

					context.stroke();
				}
			}

			context.restore();
		};

		// Draws the house without the kitchen, so the town can draw it too. Lillesøster’s bites are cut out of everything, the icing and the candy too.
		const drawHouseModel = (context, model) => {
			for (const piece of model.pieces.filter(item => item.kind === 'chimney')) {
				drawPiece(context, piece);
			}

			for (const piece of model.pieces.filter(item => item.kind !== 'chimney')) {
				drawPiece(context, piece);
			}

			drawIcing(context, model.strokes);
			for (const candy of model.candies) {
				drawCandy(context, candy);
			}

			context.fillStyle = '#ffffff';
			for (const flake of model.snow) {
				context.fillRect(flake.x, flake.y, flake.size, flake.size);
			}

			context.save();
			context.globalCompositeOperation = 'destination-out';
			for (const piece of model.pieces) {
				for (const bite of piece.bites) {
					// A bite of small teeth: a big round bite, with a wavy edge.
					context.beginPath();
					context.arc(bite.x, bite.y, 8, 0, Math.PI * 2);
					for (let tooth = 0; tooth < 7; tooth++) {
						const angle = tooth * Math.PI * 2 / 7;
						context.moveTo(bite.x + (Math.cos(angle) * 8), bite.y + (Math.sin(angle) * 8));
						context.arc(bite.x + (Math.cos(angle) * 8), bite.y + (Math.sin(angle) * 8), 2.6, 0, Math.PI * 2);
					}

					context.fill();
				}
			}

			context.restore();
		};

		const houseLayer = new OffscreenCanvas(houseWidth, houseHeight);
		const houseLayerContext = houseLayer.getContext('2d');

		const drawKitchen = context => {
			// The wallpaper of the kitchen, with little red hearts, and the window with the rain of Bergen.
			context.fillStyle = '#f3e3c3';
			context.fillRect(0, 0, houseWidth, houseHeight);
			context.fillStyle = '#e8c9a0';
			for (let y = 10; y < boardTop; y += 24) {
				for (let x = (y / 24) % 2 === 0 ? 12 : 24; x < houseWidth; x += 24) {
					context.beginPath();
					context.arc(x - 2, y, 2.2, 0, Math.PI * 2);
					context.arc(x + 2, y, 2.2, 0, Math.PI * 2);
					context.moveTo(x - 4, y + 1);
					context.lineTo(x, y + 5);
					context.lineTo(x + 4, y + 1);
					context.fill();
				}
			}

			// The red and white table cloth, and the cake board on it.
			context.fillStyle = '#ffffff';
			context.fillRect(0, boardTop + 4, houseWidth, houseHeight - boardTop);
			context.fillStyle = '#cc2222';
			for (let x = 0; x < houseWidth; x += 16) {
				for (let y = boardTop + 4; y < houseHeight; y += 16) {
					if (((x + y) / 16) % 2 < 1) {
						context.fillRect(x, y, 8, 8);
						context.fillRect(x + 8, y + 8, 8, 8);
					}
				}
			}

			// A cake board of gold foil, so the white icing shows on it.
			const foil = context.createLinearGradient(0, boardTop, 0, boardTop + 8);
			foil.addColorStop(0, '#f2d06b');
			foil.addColorStop(1, '#a8801e');
			context.fillStyle = foil;
			context.fillRect(columnLeft - 14, boardTop, (columnWidth * columnCount) + 28, 8);

			// Faint marks of the columns on the board, so the visitor sees where the pieces go.
			context.fillStyle = '#00000014';
			for (let column = 0; column < columnCount; column++) {
				context.fillRect(columnLeft + (column * columnWidth) + 3, boardTop + 3, columnWidth - 6, 2);
			}
		};

		const drawHouse = () => {
			drawKitchen(houseContext);
			for (const item of house.rubble) {
				houseContext.save();
				houseContext.translate(item.x, item.y);
				houseContext.rotate(item.angle * Math.PI / 180);
				if (item.type === 'candy') {
					drawCandy(houseContext, item.candy, 0, 0, 0);
				} else {
					houseContext.fillStyle = item.kind === 'roof' ? gingerbread.dark : gingerbread.base;
					houseContext.strokeStyle = gingerbread.edge;
					houseContext.beginPath();
					houseContext.moveTo(-10, -4);
					houseContext.lineTo(4, -6);
					houseContext.lineTo(11, 1);
					houseContext.lineTo(2, 5);
					houseContext.lineTo(-8, 4);
					houseContext.closePath();
					houseContext.fill();
					houseContext.stroke();
				}

				houseContext.restore();
			}

			houseLayerContext.clearRect(0, 0, houseWidth, houseHeight);
			drawHouseModel(houseLayerContext, house.model);
			houseContext.drawImage(houseLayer, 0, 0);

			for (const item of house.falling) {
				houseContext.save();
				houseContext.translate(item.x, item.y);
				houseContext.rotate(item.angle * Math.PI / 180);
				if (item.type === 'candy') {
					drawCandy(houseContext, item.candy, 0, 0, 0);
				} else {
					houseContext.translate(-item.offsetX, -item.offsetY);
					drawPiece(houseContext, item.piece);
					for (const candy of item.candies) {
						drawCandy(houseContext, candy);
					}
				}

				houseContext.restore();
			}

			// With the piping bag, the seams that still need icing are dashed, like the lines of a sewing pattern.
			if (house.tool === 'icing') {
				houseContext.save();
				houseContext.strokeStyle = '#ff1010';
				houseContext.lineWidth = 3.5;
				houseContext.setLineDash([6, 4]);
				for (const seam of houseSeams(house.model)) {
					if (seam.lower && !isGlued(seam)) {
						houseContext.beginPath();
						houseContext.moveTo(seam.from.x, seam.from.y);
						houseContext.lineTo(seam.to.x, seam.to.y);
						houseContext.stroke();
					}
				}

				houseContext.restore();
			}

			// The piping bag, or the hand with the piece, where the keys point.
			if (house.isFocused || house.isKeyPiping) {
				const {x, y} = house.cursor;
				houseContext.save();
				houseContext.translate(x, y);
				if (house.tool === 'icing') {
					houseContext.rotate(-0.5);
					houseContext.fillStyle = '#e8f0ff';
					houseContext.strokeStyle = '#3355aa';
					houseContext.lineWidth = 1.5;
					houseContext.beginPath();
					houseContext.moveTo(0, 0);
					houseContext.lineTo(-7, -26);
					houseContext.lineTo(7, -26);
					houseContext.closePath();
					houseContext.fill();
					houseContext.stroke();
				} else {
					houseContext.strokeStyle = '#000080';
					houseContext.lineWidth = 2;
					houseContext.beginPath();
					houseContext.moveTo(-8, 0);
					houseContext.lineTo(8, 0);
					houseContext.moveTo(0, -8);
					houseContext.lineTo(0, 8);
					houseContext.stroke();
				}

				houseContext.restore();
			}
		};

		const selectTool = tool => {
			house.tool = tool;
			// Only the piping bag keeps a finger on the board from scrolling the page.
			if (tool === 'icing') {
				houseCanvas.dataset.state = 'piping';
			} else {
				delete houseCanvas.dataset.state;
			}

			for (const button of toolButtons) {
				setPressed(button, button.dataset.christmasTool === tool);
			}

			this.say(toolMessages[tool], houseStatus);
			drawHouse();
		};

		for (const button of toolButtons) {
			this.on(button, 'click', () => {
				selectTool(button.dataset.christmasTool);
			});
		}

		// A tap with a piece puts it in the column that was tapped, and with a candy, right where it was tapped.
		const useTool = (x, y) => {
			let message;
			if (['wall', 'roof', 'chimney'].includes(house.tool)) {
				const column = Math.floor((x - columnLeft) / columnWidth);
				if (column < 0 || column >= columnCount) {
					message = 'That is off the cake board!';
				} else {
					message = addPiece(house.tool, column);
				}
			} else {
				message = addCandy(house.tool, x, y);
			}

			if (message) {
				this.say(message, houseStatus);
			}

			saveDraft();
			drawHouse();
		};

		this.on(houseCanvas, 'pointerdown', event => {
			// One finger or button pipes at a time.
			if (house.stroke || !event.isPrimary || event.button !== 0) {
				return;
			}

			event.preventDefault();
			houseCanvas.focus({preventScroll: true});
			if (house.tool === 'icing') {
				const point = canvasPoint(houseCanvas, event);
				house.cursor = {x: point.x, y: point.y};
				houseCanvas.setPointerCapture(event.pointerId);
				startStroke(point.x, point.y);
				drawHouse();
			}
		});

		// A piece or a candy goes on with a click or a tap, so a finger that scrolls the page over the board puts nothing there.
		this.on(houseCanvas, 'click', event => {
			if (house.tool === 'icing') {
				return;
			}

			const point = canvasPoint(houseCanvas, event);
			house.cursor = {x: point.x, y: point.y};
			useTool(point.x, point.y);
		});

		this.on(houseCanvas, 'pointermove', event => {
			if (!house.stroke || house.isKeyPiping) {
				return;
			}

			for (const coalesced of event.getCoalescedEvents?.() ?? [event]) {
				const point = canvasPoint(houseCanvas, coalesced);
				if (!pipe(point.x, point.y)) {
					endStroke();
					this.say('The piping bag is empty! Mamma says that is enough icing for one house.', houseStatus);
					break;
				}
			}

			drawHouse();
		});

		for (const type of ['pointerup', 'pointercancel']) {
			this.on(houseCanvas, type, () => {
				if (!house.isKeyPiping) {
					endStroke();
					drawHouse();
				}
			});
		}

		this.on(houseCanvas, 'focus', () => {
			house.isFocused = houseCanvas.matches(':focus-visible');
			drawHouse();
		});

		this.on(houseCanvas, 'blur', () => {
			house.isFocused = false;
			if (house.isKeyPiping) {
				house.isKeyPiping = false;
				endStroke();
			}

			drawHouse();
		});

		this.on(houseCanvas, 'keydown', event => {
			const moves = {ArrowLeft: [-1, 0], ArrowRight: [1, 0], ArrowUp: [0, -1], ArrowDown: [0, 1]};
			if (moves[event.key]) {
				event.preventDefault();
				const step = event.shiftKey ? 15 : 5;
				house.isFocused = true;
				house.cursor.x = clamp(house.cursor.x + (moves[event.key][0] * step), 2, houseWidth - 2);
				house.cursor.y = clamp(house.cursor.y + (moves[event.key][1] * step), 2, houseHeight - 2);
				if (house.isKeyPiping) {
					pipe(house.cursor.x, house.cursor.y);
				}

				drawHouse();
			} else if (event.key === ' ' || event.key === 'Enter') {
				event.preventDefault();
				house.isFocused = true;
				if (house.tool === 'icing') {
					if (!house.isKeyPiping && !event.repeat) {
						house.isKeyPiping = true;
						startStroke(house.cursor.x, house.cursor.y);
					}
				} else if (!event.repeat) {
					useTool(house.cursor.x, house.cursor.y);
				}

				drawHouse();
			}
		});

		this.on(houseCanvas, 'keyup', event => {
			if ((event.key === ' ' || event.key === 'Enter') && house.isKeyPiping) {
				house.isKeyPiping = false;
				endStroke();
				drawHouse();
			}
		});

		// The top of the house at a place, where the powdered sugar lands.
		const topAt = x => {
			let top;
			let piece;
			for (const item of house.model.pieces) {
				const bounds = pieceBounds(item);
				if (x < bounds.left || x > bounds.right) {
					continue;
				}

				const y = item.kind === 'roof' ? roofTop(bounds, x) : bounds.top;

				if (top === undefined || y < top) {
					top = y;
					piece = item;
				}
			}

			return {top, piece};
		};

		const dustWithSnow = () => {
			if (house.model.pieces.length === 0) {
				return 'Melis everywhere, on the board and on the floor. Build something first!';
			}

			remember();
			for (let index = 0; index < 160; index++) {
				const x = randomBetween(columnLeft - 6, columnLeft + (columnWidth * columnCount) + 6);
				const {top, piece} = topAt(x);
				if (top === undefined) {
					continue;
				}

				house.model.snow.push({x: Math.round(x), y: Math.round(top + randomBetween(-1, Math.random() < 0.8 ? 3 : 18)), size: Math.random() < 0.3 ? 2 : 1.5, piece: piece.id});
			}

			if (house.model.snow.length > 1200) {
				house.model.snow = house.model.snow.slice(-1200);
			}

			sound.burst(0.6, {volume: 0.05, frequency: 6000, type: 'highpass'});
			return 'Powdered sugar (melis) through the sieve, like snow. Finally some snow in Bergen!';
		};

		// Lillesøster takes a bite. She eats the broken pieces first, and a piece with three bites breaks.
		const takeBite = () => {
			if (house.rubble.length > 0) {
				const item = house.rubble.splice(randomInteger(0, house.rubble.length - 1), 1)[0];
				sound.crunch();
				return item.type === 'candy' ? 'Lillesøster eats the candy from the table. “It fell, so it is mine!”' : 'Lillesøster eats a broken piece from the table. Crunch! “It was broken anyway!”';
			}

			const candidates = house.model.pieces.filter(piece => piece.kind !== 'chimney' || house.model.pieces.length === 1);
			if (candidates.length === 0) {
				return 'Lillesøster looks for gingerbread, but there is nothing to eat. She eats the dough instead.';
			}

			remember();
			const piece = randomItem(candidates);
			const bounds = pieceBounds(piece);
			const edges = piece.kind === 'roof'
				? [{x: bounds.left + 4, y: bounds.bottom - 2}, {x: bounds.right - 4, y: bounds.bottom - 2}, {x: (bounds.left + bounds.right) / 2, y: bounds.top + 3}]
				: [{x: bounds.left, y: randomBetween(bounds.top + 8, bounds.bottom - 8)}, {x: bounds.right, y: randomBetween(bounds.top + 8, bounds.bottom - 8)}, {x: randomBetween(bounds.left + 8, bounds.right - 8), y: bounds.top}];
			const bite = randomItem(edges);
			piece.bites.push({x: Math.round(bite.x), y: Math.round(bite.y)});
			sound.crunch();
			if (piece.bites.length < 3) {
				return piece.bites.length === 1 ? 'Lillesøster takes a bite. “Just one!”' : 'Another bite! “It tastes like Christmas!”';
			}

			// The piece breaks, and whatever stood only on it falls.
			dropPieces([piece]);
			const loose = fallingPieces({needsIcing: false});
			if (loose.length > 0) {
				dropPieces(loose);
			}

			return loose.length > 0 ? 'Three bites, and the piece broke! Everything on it fell down. MAMMA!!!' : 'Three bites, and the piece broke. Lillesøster says it was like that before.';
		};

		// Pappa’s Bryggen kit: four tall gable houses side by side, without icing.
		const buildBryggen = () => {
			remember();
			house.model = {...emptyHouse(), name: house.model.name};
			house.rubble = [];
			for (const [column, walls] of [[1, 2], [2, 3], [3, 2], [4, 1]]) {
				for (let row = 0; row < walls; row++) {
					house.model.pieces.push({id: house.model.nextId++, kind: 'wall', column, row, bites: [], detail: row === 0 ? (column === 2 ? 'door' : 'window') : randomItem(['window', 'heart', 'round'])});
				}

				house.model.pieces.push({id: house.model.nextId++, kind: 'roof', column, row: walls, bites: [], detail: undefined});
			}

			house.model.pieces.push({id: house.model.nextId++, kind: 'chimney', column: 2, row: 3, bites: [], detail: undefined});
			rebuildIcing();
			sound.place();
			return 'Pappa’s Bryggen kit: four gables, like the old wooden houses by the harbor. There is no icing on the seams yet!';
		};

		const testHouse = ({isTrip}) => {
			if (house.model.pieces.length === 0) {
				return {message: isTrip ? 'There is nothing to bring! Build a house first.' : 'There is no house to dry yet.', isStanding: false};
			}

			const loose = fallingPieces({needsIcing: true});
			if (loose.length > 0) {
				// Undo puts the house back together, so the visitor can pipe the missing seams.
				remember();
				dropPieces(loose);
				const count = loose.length === 1 ? 'A piece' : `${loose.length} pieces`;
				return {
					message: isTrip
						? `On the way down from Fløyen, in Pappa’s Volvo, ${count.toLowerCase()} fell off! Pipe icing on every seam, on the board, between the pieces, and under the roof.`
						: `The icing dried, and ${count.toLowerCase()} fell off. The seams without icing do not hold!`,
					isStanding: false,
				};
			}

			return {message: 'The icing is as hard as stone. This house will survive anything, even Lillesøster.', isStanding: true};
		};

		// The house of a draft or of the town, as the browser kept it. Anything else, like an old or broken value, is left out.
		const isHouseModel = value => typeof value === 'object'
			&& value !== null
			&& typeof value.name === 'string'
			&& ['pieces', 'strokes', 'candies', 'snow'].every(key => Array.isArray(value[key]))
			&& value.pieces.every(piece => typeof piece === 'object' && piece !== null && Array.isArray(piece.bites) && Number.isInteger(piece.column) && Number.isInteger(piece.row))
			&& value.strokes.every(stroke => Array.isArray(stroke) && stroke.every(point => Number.isFinite(point?.x) && Number.isFinite(point?.y)));

		const town = {
			houses: this.stored('town', []).filter(model => isHouseModel(model)),
			images: [],
			train: 0,
			smoke: [],
			flakes: Array.from({length: 40}, () => ({x: randomBetween(0, 360), y: randomBetween(0, 180), speed: randomBetween(8, 20), size: randomBetween(1, 2.5)})),
			time: 0,
		};

		// The house of the visitor, drawn once into a small picture for the town.
		const houseImage = model => {
			const canvas = new OffscreenCanvas(houseWidth, houseHeight);
			drawHouseModel(canvas.getContext('2d'), model);
			let left = houseWidth;
			let right = 0;
			let top = boardTop;
			for (const piece of model.pieces) {
				const bounds = pieceBounds(piece);
				left = Math.min(left, bounds.left - 6);
				right = Math.max(right, bounds.right + 6);
				top = Math.min(top, bounds.top - 6);
			}

			return {canvas, left, right, top, bottom: boardTop + 2};
		};

		const refreshTownImages = () => {
			town.images = town.houses.map(model => houseImage(model));
		};

		const bringHouse = () => {
			const result = testHouse({isTrip: true});
			if (!result.isStanding) {
				return result.message;
			}

			const hasWall = house.model.pieces.some(piece => piece.kind === 'wall');
			const hasRoof = house.model.pieces.some(piece => piece.kind === 'roof');
			if (!hasWall || !hasRoof) {
				return 'The lady at Pepperkakebyen says a house needs walls AND a roof.';
			}

			const model = structuredClone(house.model);
			model.name = [...nameField.value.trim()].slice(0, 18).join('') || 'Sindre, 11 år';
			// The icing of the house in the town is kept with fewer points, so the town fits in the browser.
			model.strokes = model.strokes.map(stroke => stroke.filter((point, index) => index % 2 === 0 || index === stroke.length - 1));
			town.houses.push(model);
			if (town.houses.length > 4) {
				town.houses.shift();
			}

			this.store('town', town.houses);
			refreshTownImages();
			drawTown();
			sound.toot();
			sound.bells(10, {when: 0.6});
			if (town.houses.length === 1) {
				this.celebrate();
			}

			townCanvas.scrollIntoView({block: 'nearest', behavior: this.reducedMotion ? 'instant' : 'smooth'});
			return `“${model.name}” stands in Pepperkakebyen now, between the gingerbread Bryggen and the church! Thousands of people come to look at it.`;
		};

		const houseActions = {
			snow: dustWithSnow,
			bite: takeBite,
			bryggen: buildBryggen,
			undo() {
				const previous = house.history.pop();
				if (!previous) {
					return 'There is nothing to undo.';
				}

				house.model = previous;
				house.falling = [];
				house.rubble = [];
				rebuildIcing();
				return 'Undone.';
			},
			clear() {
				remember();
				house.model = {...emptyHouse(), name: house.model.name};
				house.rubble = [];
				rebuildIcing();
				return 'A clean cake board. Mamma baked new pieces.';
			},
			dry: () => testHouse({isTrip: false}).message,
			bring: bringHouse,
			'empty-town': () => {
				if (town.houses.length === 0) {
					return 'None of my houses are in the town yet.';
				}

				town.houses = [];
				this.store('town', town.houses);
				refreshTownImages();
				drawTown();
				return 'I took my houses home after New Year. We ate them, even the dusty ones.';
			},
		};

		for (const button of houseActionButtons) {
			this.on(button, 'click', () => {
				const message = houseActions[button.dataset.christmasHouseAction]();
				saveDraft();
				drawHouse();
				if (message) {
					this.say(message, houseStatus);
				}
			});
		}

		// A gingerbread house of the town, of other kids or of the town itself, with icing on the edges.
		const drawTownHouse = (context, x, ground, width, height, {roof = '#7a3f17', icing = '#ffffff', candy = [], tower = false} = {}) => {
			context.fillStyle = gingerbread.base;
			context.strokeStyle = gingerbread.edge;
			context.lineWidth = 1;
			context.fillRect(x, ground - height, width, height);
			context.strokeRect(x, ground - height, width, height);
			context.fillStyle = roof;
			context.beginPath();
			context.moveTo(x - 3, ground - height);
			context.lineTo(x + (width / 2), ground - height - (tower ? width * 1.8 : width * 0.6));
			context.lineTo(x + width + 3, ground - height);
			context.closePath();
			context.fill();
			context.strokeStyle = icing;
			context.lineWidth = 1.5;
			context.stroke();
			context.fillStyle = '#ffd25a';
			context.fillRect(x + (width / 2) - 3, ground - height + 5, 6, 6);
			context.fillRect(x + (width / 2) - 2, ground - 8, 4, 8);
			for (const [index, color] of candy.entries()) {
				context.fillStyle = color;
				context.beginPath();
				context.arc(x + 3 + ((index * 5) % (width - 4)), ground - height + 2, 1.8, 0, Math.PI * 2);
				context.fill();
			}
		};

		const trackX = 180;
		const trackY = 150;
		const trackRadiusX = 160;
		const trackRadiusY = 18;

		const trainCar = (angle, isEngine) => {
			const x = trackX + (Math.cos(angle) * trackRadiusX);
			const y = trackY + (Math.sin(angle) * trackRadiusY);
			const scale = 0.8 + (Math.sin(angle) * 0.2);
			return {x, y, scale, isEngine, isFront: Math.sin(angle) >= 0, direction: -Math.sin(angle) >= 0 ? 1 : -1};
		};

		const drawTrainCar = (context, car) => {
			context.save();
			context.translate(car.x, car.y);
			context.scale(car.scale * car.direction, car.scale);
			if (car.isEngine) {
				context.fillStyle = '#222222';
				context.fillRect(-10, -12, 16, 9);
				context.fillStyle = '#cc0000';
				context.fillRect(4, -18, 8, 15);
				context.fillStyle = '#222222';
				context.fillRect(-7, -19, 4, 7);
				context.fillStyle = '#ffd25a';
				context.fillRect(-13, -9, 3, 3);
			} else {
				context.fillStyle = gingerbread.base;
				context.fillRect(-9, -14, 18, 11);
				context.strokeStyle = '#ffffff';
				context.lineWidth = 1;
				context.strokeRect(-9, -14, 18, 11);
				context.fillStyle = '#ffd25a';
				context.fillRect(-6, -12, 4, 4);
				context.fillRect(2, -12, 4, 4);
			}

			context.fillStyle = '#111111';
			context.beginPath();
			context.arc(-5, -2, 2.5, 0, Math.PI * 2);
			context.arc(5, -2, 2.5, 0, Math.PI * 2);
			context.fill();
			context.restore();
		};

		const drawTown = () => {
			const context = townContext;
			const width = townCanvas.width;
			const height = townCanvas.height;
			const sky = context.createLinearGradient(0, 0, 0, height);
			sky.addColorStop(0, '#0b1a3a');
			sky.addColorStop(1, '#2a3f6e');
			context.fillStyle = sky;
			context.fillRect(0, 0, width, height);

			// Fløyen and Ulriken behind the town, with the lights of Fløibanen up the hill.
			context.fillStyle = '#16264a';
			context.beginPath();
			context.moveTo(0, 90);
			context.quadraticCurveTo(70, 20, 150, 70);
			context.quadraticCurveTo(230, 10, 300, 60);
			context.quadraticCurveTo(340, 40, 360, 70);
			context.lineTo(360, 120);
			context.lineTo(0, 120);
			context.fill();
			context.fillStyle = '#ffe9a0';
			for (let index = 0; index < 8; index++) {
				context.fillRect(40 + (index * 9), 86 - (index * 6.5), 2, 2);
			}

			context.fillStyle = '#ffffff';
			for (let index = 0; index < 30; index++) {
				context.fillRect((index * 97) % width, (index * 37) % 50, 1, 1);
			}

			// The cotton-wool snow of the town, the gingerbread Bryggen, and the church.
			context.fillStyle = '#f4f7ff';
			context.fillRect(0, 112, width, height - 112);
			const bryggenRoofs = ['#b22222', '#e0a020', '#f4f4f4', '#b22222', '#c86414', '#e0a020'];
			for (const [index, roof] of bryggenRoofs.entries()) {
				drawTownHouse(context, 8 + (index * 17), 112, 15, 26 + ((index * 5) % 9), {roof});
			}

			drawTownHouse(context, 312, 112, 22, 26, {roof: '#556655', tower: true});
			drawTownHouse(context, 120, 112, 26, 20, {roof: '#7a3f17', candy: smartiesColors});
			drawTownHouse(context, 258, 112, 30, 18, {roof: '#e75480', icing: '#ffd1e8'});
			context.font = 'bold 7px Verdana, sans-serif';
			context.fillStyle = '#333333';
			context.textAlign = 'center';
			context.fillText('Trond', 133, 120);
			context.fillText('Ingrid ♥', 273, 120);
			context.fillText('Bryggen', 58, 120);

			const cars = [0, 1, 2, 3].map(index => trainCar(town.train - (index * 0.17), index === 0));
			const drawTrack = isFront => {
				context.strokeStyle = '#8a6a4a';
				context.lineWidth = 2;
				context.beginPath();
				context.ellipse(trackX, trackY, trackRadiusX, trackRadiusY, 0, isFront ? 0 : Math.PI, isFront ? Math.PI : Math.PI * 2);
				context.stroke();
			};

			drawTrack(false);
			for (const car of cars.filter(item => !item.isFront)) {
				drawTrainCar(context, car);
			}

			// The houses of the visitor, in the middle of the town, with their signs.
			const slots = town.images.length;
			for (const [index, image] of town.images.entries()) {
				const slotWidth = 64;
				const x = 180 + ((index - ((slots - 1) / 2)) * (slotWidth + 8));
				const sourceWidth = image.right - image.left;
				const sourceHeight = image.bottom - image.top;
				const scale = Math.min(slotWidth / sourceWidth, 46 / sourceHeight);
				const drawWidth = sourceWidth * scale;
				const drawHeight = sourceHeight * scale;
				context.drawImage(image.canvas, image.left, image.top, sourceWidth, sourceHeight, x - (drawWidth / 2), 142 - drawHeight, drawWidth, drawHeight);
				const name = town.houses[index].name;
				context.font = 'bold 7px Verdana, sans-serif';
				const signWidth = Math.min(slotWidth + 6, context.measureText(name).width + 6);
				context.fillStyle = '#ffffff';
				context.fillRect(x - (signWidth / 2), 143, signWidth, 9);
				context.strokeStyle = '#cc0000';
				context.lineWidth = 1;
				context.strokeRect(x - (signWidth / 2), 143, signWidth, 9);
				context.fillStyle = '#000000';
				context.fillText(name, x, 150, slotWidth + 2);
			}

			if (slots === 0) {
				context.font = 'bold 9px "Comic Sans MS", "Comic Sans", "Chalkboard SE", cursive';
				context.fillStyle = '#cc0000';
				context.fillText('Your house goes here!', 180, 136);
			}

			drawTrack(true);
			for (const car of cars.filter(item => item.isFront)) {
				drawTrainCar(context, car);
			}

			context.fillStyle = '#ffffffcc';
			for (const puff of town.smoke) {
				context.beginPath();
				context.arc(puff.x, puff.y, puff.size, 0, Math.PI * 2);
				context.fill();
			}

			if (!this.reducedMotion) {
				context.fillStyle = '#ffffff';
				for (const flake of town.flakes) {
					context.fillRect(flake.x, flake.y, flake.size, flake.size);
				}
			}

			context.font = 'bold 9px Verdana, sans-serif';
			context.textAlign = 'left';
			context.fillStyle = '#ffe9a0';
			context.fillText(`PEPPERKAKEBYEN 1999 ★ ${(1734 + town.houses.length).toLocaleString('nb-NO')} houses`, 6, 12);
		};

		const puffSmoke = () => {
			const engine = trainCar(town.train, true);
			town.smoke.push({x: engine.x + (engine.direction * 4), y: engine.y - 20, size: 2.5, life: 1.6});
		};

		this.loop(seconds => {
			town.time += seconds;
			town.train = (town.train + (seconds * 0.35)) % (Math.PI * 2);
			if (Math.random() < seconds * 4) {
				puffSmoke();
			}

			for (const puff of town.smoke) {
				puff.y -= seconds * 14;
				puff.size += seconds * 3;
				puff.life -= seconds;
			}

			town.smoke = town.smoke.filter(puff => puff.life > 0);
			for (const flake of town.flakes) {
				flake.y += flake.speed * seconds;
				flake.x += Math.sin((town.time * 2) + flake.speed) * seconds * 6;
				if (flake.y > townCanvas.height) {
					flake.y = -2;
					flake.x = randomBetween(0, townCanvas.width);
				}
			}

			drawTown();
		}, {while: () => !this.reducedMotion, target: townCanvas});

		// The train toots. With reduced motion, it moves a bit along the track with each toot instead of going around by itself.
		this.on(tootButton, 'click', () => {
			sound.toot();
			if (this.reducedMotion) {
				town.train = (town.train + 0.6) % (Math.PI * 2);
				town.smoke = [];
				puffSmoke();
				town.smoke[0].size = 5;
			} else {
				for (let index = 0; index < 4; index++) {
					puffSmoke();
				}
			}

			drawTown();
			this.say('Tut-tut! The little train of Pepperkakebyen goes around the town.', houseStatus);
		});


		// The house that the visitor was building is kept, so it is still there after a reload.
		const draft = this.stored('house', undefined);
		if (isHouseModel(draft)) {
			house.model = {...emptyHouse(), ...draft};
		}

		rebuildIcing();
		refreshTownImages();
		drawHouse();
		drawTown();

		return {
			reducedMotionChanged: () => {
				if (this.reducedMotion) {
					settleFalling();
				}

				drawHouse();
				drawTown();
			},
		};
	}

	#setUpBowling() {
		// Nisse Bowling, like Elf Bowling: Julenissen bowls at ten nisser. The lane is computed from above, in units where the lane is 2 wide and the head nisse stands 16 down the lane, and drawn in perspective from behind Julenissen.
		const {lane: laneCanvas, spin: spinDisplay, sheet, best: bestDisplay, bowlingStatus} = this.parts;
		const laneContext = laneCanvas.getContext('2d');
		const sheetFrames = [...sheet.querySelectorAll('li')];
		const bowlButtons = [...this.querySelectorAll('[data-christmas-bowl]')];

		const laneWidth = laneCanvas.width;
		const laneHalf = 1;
		const gutterHalf = 1.22;
		const pinRadius = 0.12;
		const ballRadius = 0.2;
		const headPin = 16;
		const laneEnd = 18.4;
		const ballSpeed = 8.5;

		const taunts = [
			'Du bommer! (You’ll miss!)',
			'Mormor bowler bedre!',
			'Ho ho HOPELØS!',
			'Er det en ball eller en grøtklump?',
			'Hei, tjukken! Pass på magen!',
			'Treff meg om du kan!',
			'Rudolf sikter bedre enn deg!',
			'Vi vil ha lønn! (We want pay!)',
			'Kom igjen, bestefar!',
			'Zzz… si fra når du kaster.',
			'Pakkene lager seg ikke selv!',
			'Jeg er IKKE en kjegle!',
		];

		const ouches = ['Au!', 'Uff da!', 'Ikke skjegget!', 'Neeei!', 'MAMMA!', 'Aiii!', 'Lua mi!', 'Det var juks!'];
		const gutterLaughs = ['HAHAHA! Renna!', 'Hi hi hi!', 'Bom bom bom!', 'Pinlig!'];

		const bowling = {
			state: 'aim',
			position: 0,
			spin: 0,
			steer: 0,
			pins: [],
			ball: undefined,
			path: [],
			rolls: this.stored('bowling-rolls', []),
			best: Math.max(0, this.stored('bowling-best', 0)),
			bubbles: [],
			banner: undefined,
			time: 0,
			tauntTimer: 2,
			settleTime: 0,
			resultTimer: 0,
			isGutter: false,
			cheer: 0,
			strikeStreak: 0,
			heldMove: 0,
		};

		// The scores of the frames, by the rules of bowling: a strike counts the next two balls, and a spare the next one.
		const frameScores = rolls => {
			const frames = [];
			let index = 0;
			let total = 0;
			for (let frame = 0; frame < 10 && index < rolls.length; frame++) {
				const first = rolls[index];
				const second = rolls[index + 1];
				const third = rolls[index + 2];
				if (frame === 9) {
					const balls = rolls.slice(index, index + 3);
					const isComplete = balls.length === 3 || (balls.length === 2 && balls[0] + balls[1] < 10);
					total += sum(balls);
					frames.push({balls, total: isComplete ? total : undefined});
					break;
				}

				if (first === 10) {
					const hasBonus = second !== undefined && third !== undefined;
					total += 10 + (second ?? 0) + (third ?? 0);
					frames.push({balls: [10], total: hasBonus ? total : undefined});
					index += 1;
				} else {
					const isOpen = second !== undefined && first + second < 10;
					const isSpare = second !== undefined && first + second === 10;
					total += first + (second ?? 0) + (isSpare ? (third ?? 0) : 0);
					frames.push({balls: second === undefined ? [first] : [first, second], total: isOpen || (isSpare && third !== undefined) ? total : undefined});
					index += 2;
				}
			}

			return frames;
		};

		const sum = numbers => {
			let total = 0;
			for (const number of numbers) {
				total += number;
			}

			return total;
		};

		// Where the game is: the frame, the ball of the frame, whether the nisser stand up again for this ball, and whether the game is over.
		const gameState = rolls => {
			let index = 0;
			for (let frame = 0; frame < 9; frame++) {
				if (index >= rolls.length) {
					return {frame, ball: 0, isFreshRack: true, isOver: false};
				}

				if (rolls[index] === 10) {
					index += 1;
					continue;
				}

				if (index + 1 >= rolls.length) {
					return {frame, ball: 1, isFreshRack: false, isOver: false};
				}

				index += 2;
			}

			const tenth = rolls.slice(index);
			if (tenth.length === 0) {
				return {frame: 9, ball: 0, isFreshRack: true, isOver: false};
			}

			if (tenth.length === 1) {
				return {frame: 9, ball: 1, isFreshRack: tenth[0] === 10, isOver: false};
			}

			if (tenth.length === 2 && (tenth[0] === 10 || tenth[0] + tenth[1] === 10)) {
				return {frame: 9, ball: 2, isFreshRack: (tenth[0] === 10 && tenth[1] === 10) || (tenth[0] !== 10 && tenth[0] + tenth[1] === 10), isOver: false};
			}

			return {frame: 9, ball: tenth.length, isFreshRack: false, isOver: true};
		};

		// The marks of the balls of a frame: X for a strike, / for a spare, and - for nothing.
		const ballMarks = (balls, isTenth) => {
			const marks = [];
			let rackStart = 0;
			for (const [index, pins] of balls.entries()) {
				const isFirstOfRack = index === rackStart;
				if (isFirstOfRack && pins === 10) {
					marks.push('X');
					rackStart = index + 1;
				} else if (!isFirstOfRack && balls[index - 1] + pins === 10) {
					marks.push('/');
					rackStart = index + 1;
				} else {
					marks.push(pins === 0 ? '-' : String(pins));
					if (!isFirstOfRack) {
						rackStart = index + 1;
					}
				}

				if (!isTenth && pins === 10) {
					break;
				}
			}

			return marks;
		};

		const renderSheet = () => {
			const frames = frameScores(bowling.rolls);
			for (const [index, item] of sheetFrames.entries()) {
				const [, ballsElement, totalElement] = item.children;
				const frame = frames[index];
				ballsElement.textContent = frame ? ballMarks(frame.balls, index === 9).join(' ') : '';
				totalElement.textContent = frame?.total === undefined ? '' : String(frame.total);
			}

			bestDisplay.textContent = `Best: ${bowling.best}`;
		};

		const rackPins = () => {
			bowling.pins = [];
			for (let row = 0; row < 4; row++) {
				for (let index = 0; index <= row; index++) {
					bowling.pins.push({
						x: (index - (row / 2)) * 0.6,
						y: headPin + (row * 0.52),
						vx: 0,
						vy: 0,
						z: 0,
						vz: 0,
						tilt: 0,
						spin: 0,
						isDown: false,
						isGone: false,
						hop: undefined,
						role: 'normal',
						phase: Math.random() * 6,
					});
				}
			}
		};

		const standingPins = () => bowling.pins.filter(pin => !pin.isDown && !pin.isGone);

		// Before each ball, one nisse is a coward who dodges, and sometimes one turns around and wiggles his behind at Julenissen.
		const pickRoles = () => {
			for (const pin of bowling.pins) {
				pin.role = 'normal';
			}

			const standing = standingPins();
			if (standing.length > 1 && Math.random() < 0.6) {
				randomItem(standing).role = 'dodger';
			}

			const others = standing.filter(pin => pin.role === 'normal');
			if (others.length > 0 && Math.random() < 0.45) {
				const mooner = randomItem(others);
				mooner.role = 'mooner';
				say(mooner, randomItem(['Kyss meg her! Nei, vent…', 'Bom bom, kan ikke treffe DENNE!', 'Wiggle wiggle!', 'Se på rumpa mi!']), 3);
			}
		};

		const say = (pin, text, seconds = 2.4) => {
			bowling.bubbles = bowling.bubbles.filter(bubble => bubble.pin !== pin);
			bowling.bubbles.push({pin, text, life: seconds});
			if (bowling.bubbles.length > 3) {
				bowling.bubbles.shift();
			}
		};

		const updateSpin = () => {
			const arrows = {'-3': '↶↶↶', '-2': '↶↶', '-1': '↶', 0: 'none', 1: '↷', 2: '↷↷', 3: '↷↷↷'};
			spinDisplay.textContent = `Spin: ${arrows[bowling.spin]}`;
		};

		const newRack = state => {
			if (state.isFreshRack) {
				rackPins();
			} else {
				bowling.pins = bowling.pins.filter(pin => !pin.isDown && !pin.isGone);
				for (const pin of bowling.pins) {
					pin.vx = 0;
					pin.vy = 0;
				}
			}

			bowling.ball = undefined;
			bowling.path = [];
			bowling.state = 'aim';
			bowling.banner = undefined;
			bowling.bubbles = bowling.bubbles.filter(bubble => bowling.pins.includes(bubble.pin));
			pickRoles();
		};

		const newGame = () => {
			bowling.rolls = [];
			this.store('bowling-rolls', bowling.rolls);
			bowling.strikeStreak = 0;
			bowling.position = 0;
			newRack({isFreshRack: true});
			renderSheet();
			drawLane();
			this.say('New game! Frame 1. The nisser are laughing already.', bowlingStatus);
		};

		const throwBall = () => {
			if (bowling.state === 'result') {
				finishRoll();
				return;
			}

			if (bowling.state !== 'aim') {
				return;
			}

			if (gameState(bowling.rolls).isOver) {
				newGame();
				return;
			}

			bowling.state = 'rolling';
			// Julenissen is not a machine: each ball goes a little off where he aimed.
			bowling.ball = {x: bowling.position + randomBetween(-0.04, 0.04), y: 0.6, vx: randomBetween(-0.05, 0.05), vy: ballSpeed, isInGutter: false, spinAngle: 0};
			bowling.path = [{x: bowling.ball.x, y: bowling.ball.y}];
			bowling.settleTime = 0;
			bowling.isGutter = false;
			bowling.bubbles = [];
			sound.roll(2.2);
			if (this.reducedMotion) {
				rollToEnd();
			} else {
				bowlingLoop.start();
			}
		};

		// With reduced motion, the whole ball is computed at once, and the lane shows where it went.
		const rollToEnd = () => {
			for (let step = 0; step < 1200 && bowling.state !== 'result'; step++) {
				stepBowling(1 / 60);
			}

			if (bowling.state !== 'result') {
				showResult();
			}

			drawLane();
		};

		const hitPin = (pin, speed) => {
			if (pin.isDown) {
				return;
			}

			pin.isDown = true;
			pin.vz = clamp(speed * 0.55, 0.6, 4.5);
			pin.spin = randomBetween(-12, 12);
			sound.pin();
			if (Math.random() < 0.5 || pin.role === 'mooner') {
				say(pin, pin.role === 'mooner' ? 'AU! Rett i rumpa!' : randomItem(ouches), 1.6);
			}
		};

		// One small step of the lane: the ball rolls and hooks with its spin, and knocks the nisser into each other.
		const stepBowling = seconds => {
			const substeps = 4;
			const dt = seconds / substeps;
			for (let substep = 0; substep < substeps; substep++) {
				const ball = bowling.ball;
				if (ball && bowling.state === 'rolling') {
					if (!ball.isInGutter) {
						// The spin hooks the ball more and more, the farther it rolls, like a real hook ball.
						const hook = ball.y > 5 ? bowling.spin * 0.16 : 0;
						ball.vx += (hook + (bowling.steer * (ball.y < 12 ? 0.9 : 0))) * dt;
					}

					ball.x += ball.vx * dt;
					ball.y += ball.vy * dt;
					ball.spinAngle += dt * 14;
					if (!ball.isInGutter && Math.abs(ball.x) > laneHalf + 0.02) {
						ball.isInGutter = true;
						ball.vx = 0;
						ball.x = Math.sign(ball.x) * 1.11;
						// Only a ball that falls in before the nisser is a gutter ball. One that bounces off them into the gutter still counts.
						if (ball.y < headPin - 0.3) {
							bowling.isGutter = true;
							sound.gutter();
						}
					}

					for (const pin of bowling.pins) {
						if (pin.isGone || ball.isInGutter || pin.z > 0.25) {
							continue;
						}

						// The coward hops away when the ball comes.
						if (pin.role === 'dodger' && !pin.hop && !pin.isDown && pin.y > ball.y && pin.y - ball.y < 2.4 && Math.abs(pin.x - ball.x) < ballRadius + pinRadius + 0.2) {
							const direction = pin.x >= ball.x ? 1 : -1;
							pin.hop = {from: pin.x, to: clamp(pin.x + (direction * 0.42), -0.95, 0.95), time: 0};
							say(pin, randomItem(['HOPP!', 'Nei takk!', 'Ha! Bom!']), 1.6);
							continue;
						}

						const dx = pin.x - ball.x;
						const dy = pin.y - ball.y;
						const distance = Math.hypot(dx, dy);
						if (distance < ballRadius + pinRadius && distance > 0) {
							const normalX = dx / distance;
							const normalY = dy / distance;
							const relative = ((ball.vx - pin.vx) * normalX) + ((ball.vy - pin.vy) * normalY);
							if (relative > 0) {
								const ballMass = 6;
								const pinMass = 1.5;
								const impulse = (2 * relative) / (ballMass + pinMass);
								ball.vx -= impulse * pinMass * normalX;
								ball.vy -= impulse * pinMass * normalY;
								pin.vx += impulse * ballMass * normalX;
								pin.vy += impulse * ballMass * normalY;
								hitPin(pin, relative);
							}

							const overlap = (ballRadius + pinRadius) - distance;
							pin.x += normalX * overlap;
							pin.y += normalY * overlap;
						}
					}

					if (bowling.path.length === 0 || Math.hypot(bowling.path.at(-1).x - ball.x, bowling.path.at(-1).y - ball.y) > 0.3) {
						bowling.path.push({x: ball.x, y: ball.y});
					}

					if (ball.y > laneEnd + 0.5) {
						bowling.state = 'settling';
						bowling.ball = undefined;
					}
				}

				for (const pin of bowling.pins) {
					if (pin.isGone) {
						continue;
					}

					if (pin.hop) {
						pin.hop.time += dt / 0.35;
						pin.x = lerp(pin.hop.from, pin.hop.to, Math.min(pin.hop.time, 1));
						pin.z = Math.sin(Math.min(pin.hop.time, 1) * Math.PI) * 0.35;
						if (pin.hop.time >= 1) {
							pin.z = 0;
							pin.hop = undefined;
							pin.role = 'normal';
						}

						continue;
					}

					pin.x += pin.vx * dt;
					pin.y += pin.vy * dt;
					pin.z += pin.vz * dt;
					if (pin.z > 0 || pin.vz > 0) {
						pin.vz -= 9.8 * dt;
					}

					if (pin.z < 0) {
						pin.z = 0;
						pin.vz = Math.abs(pin.vz) > 0.8 ? -pin.vz * 0.3 : 0;
					}

					if (pin.isDown) {
						pin.tilt = Math.min(Math.PI / 2, pin.tilt + (dt * 7));
						pin.phase += pin.spin * dt;
					}

					const friction = Math.max(0, 1 - (dt * (pin.z > 0 ? 0.3 : 2.2)));
					pin.vx *= friction;
					pin.vy *= friction;
					if (Math.abs(pin.x) > gutterHalf || pin.y > laneEnd + 0.4) {
						pin.isGone = true;
						pin.isDown = true;
					}
				}

				// The nisser bump into each other, and one that is bumped hard enough falls too.
				for (const [index, first] of bowling.pins.entries()) {
					if (first.isGone) {
						continue;
					}

					for (const second of bowling.pins.slice(index + 1)) {
						if (second.isGone || Math.abs(first.z - second.z) > 0.3) {
							continue;
						}

						const dx = second.x - first.x;
						const dy = second.y - first.y;
						const distance = Math.hypot(dx, dy);
						const reach = (pinRadius * 2) + (first.isDown || second.isDown ? 0.06 : 0);
						if (distance < reach && distance > 0) {
							const normalX = dx / distance;
							const normalY = dy / distance;
							const relative = ((first.vx - second.vx) * normalX) + ((first.vy - second.vy) * normalY);
							if (relative > 0) {
								first.vx -= relative * normalX * 0.85;
								first.vy -= relative * normalY * 0.85;
								second.vx += relative * normalX * 0.85;
								second.vy += relative * normalY * 0.85;
								if (relative > 0.8) {
									hitPin(first, relative);
									hitPin(second, relative);
								}
							}

							const overlap = (reach - distance) / 2;
							first.x -= normalX * overlap;
							first.y -= normalY * overlap;
							second.x += normalX * overlap;
							second.y += normalY * overlap;
						}
					}
				}

				if (bowling.state === 'settling') {
					const isMoving = bowling.pins.some(pin => !pin.isGone && (Math.hypot(pin.vx, pin.vy) > 0.05 || pin.z > 0 || pin.hop));
					bowling.settleTime = isMoving ? 0 : bowling.settleTime + dt;
					if (bowling.settleTime > 0.5 || bowling.pins.every(pin => pin.isGone)) {
						showResult();
					}
				}
			}
		};

		// The ball is done: the nisser on the floor are counted, and the score sheet is written.
		const showResult = () => {
			const state = gameState(bowling.rolls);
			const standingBefore = state.isFreshRack ? 10 : bowling.pins.length;
			const standing = standingPins().length;
			const knocked = standingBefore - standing;
			bowling.rolls.push(knocked);
			this.store('bowling-rolls', bowling.rolls);
			bowling.state = 'result';
			bowling.resultTimer = 1.8;
			const isStrike = state.isFreshRack && knocked === 10;
			const isSpare = !state.isFreshRack && standing === 0;
			const frameText = `Frame ${state.frame + 1}`;
			let message;
			if (isStrike) {
				bowling.strikeStreak++;
				bowling.banner = {text: bowling.strikeStreak >= 3 ? 'KALKUN!!!' : 'STRIKE!', life: 2};
				bowling.cheer = 1.6;
				sound.fanfare();
				sound.hoHoHo();
				message = bowling.strikeStreak >= 3 ? `${frameText}: three strikes in a row, a turkey (kalkun)! HO HO HO!` : `${frameText}: STRIKE! All ten nisser are on the floor. HO HO HO!`;
				if (bowling.strikeStreak === 3) {
					this.celebrate();
				}
			} else if (isSpare) {
				bowling.strikeStreak = 0;
				bowling.banner = {text: 'SPARE!', life: 1.6};
				bowling.cheer = 1;
				sound.bells(8);
				message = `${frameText}: spare! The last nisser are down.`;
			} else {
				bowling.strikeStreak = 0;
				if (bowling.isGutter || knocked === 0) {
					for (const pin of standingPins().slice(0, 3)) {
						say(pin, randomItem(gutterLaughs), 2);
					}

					message = bowling.isGutter ? `${frameText}: in the gutter (renna)! The nisser laugh at Julenissen.` : `${frameText}: not one nisse. They dance.`;
				} else {
					message = `${frameText}: ${knocked} ${knocked === 1 ? 'nisse' : 'nisser'} down.`;
				}
			}

			const next = gameState(bowling.rolls);
			if (next.isOver) {
				const total = frameScores(bowling.rolls).at(-1)?.total ?? 0;
				const isBest = total > bowling.best;
				bowling.best = Math.max(bowling.best, total);
				this.store('bowling-best', bowling.best);
				const verdict = total >= 200 ? 'Julenissen is the bowling king of the North Pole!' : total >= 120 ? 'Not bad for an old man with a big belly.' : total >= 60 ? 'The nisser say Rudolf is better.' : 'The nisser will tell everyone at the North Pole.';
				message += ` Game over: ${total} points. ${verdict}${isBest ? ' A new best score!' : ''} Press Bowl for a new game.`;
				bowling.banner = {text: `${total} POENG`, life: 3};
			} else if (this.reducedMotion) {
				message += ' Press Bowl to set up the next ball.';
			}

			renderSheet();
			this.say(message, bowlingStatus);
		};

		// After the ball, the nisser on the floor get up and leave, grumbling, and the next ball can come.
		const finishRoll = () => {
			const state = gameState(bowling.rolls);
			if (state.isOver) {
				bowling.state = 'aim';
				bowling.banner = undefined;
				newGame();
				return;
			}

			newRack(state);
			drawLane();
			// With reduced motion, the visitor pressed Bowl to get here, so the status must no longer ask for it.
			if (this.reducedMotion) {
				const pinsText = state.isFreshRack ? 'ten new nisser stand' : 'the nisser that are left stand';
				this.say(`Frame ${state.frame + 1}, ball ${state.ball + 1}: ${pinsText} on the lane. Press Bowl to roll.`, bowlingStatus);
			}
		};

		const bowlingLoop = this.loop(seconds => {
			bowling.time += seconds;
			if (bowling.state === 'aim') {
				if (bowling.heldMove !== 0) {
					bowling.position = clamp(bowling.position + (bowling.heldMove * seconds * 1.2), -0.85, 0.85);
				}

				bowling.tauntTimer -= seconds;
				if (bowling.tauntTimer <= 0) {
					bowling.tauntTimer = randomBetween(2.5, 4.5);
					const standing = standingPins();
					if (standing.length > 0) {
						say(randomItem(standing), randomItem(taunts));
					}
				}
			} else if (bowling.state === 'rolling' || bowling.state === 'settling') {
				stepBowling(seconds);
			} else if (bowling.state === 'result' && !gameState(bowling.rolls).isOver) {
				bowling.resultTimer -= seconds;
				if (bowling.resultTimer <= 0) {
					finishRoll();
				}
			}

			for (const bubble of bowling.bubbles) {
				bubble.life -= seconds;
			}

			bowling.bubbles = bowling.bubbles.filter(bubble => bubble.life > 0);
			if (bowling.banner) {
				bowling.banner.life -= seconds;
				if (bowling.banner.life <= 0 && bowling.state !== 'result') {
					bowling.banner = undefined;
				}
			}

			bowling.cheer = Math.max(0, bowling.cheer - seconds);
			drawLane();
		}, {while: () => !this.reducedMotion, target: laneCanvas});

		// The perspective of the lane: far away is small, near the top of the canvas.
		const project = (x, y, z = 0) => {
			const depth = y + 14;
			const scale = 1960 / depth;
			return {x: (laneWidth / 2) + (x * scale), y: -112 + (7098 / depth) - (z * scale), scale};
		};

		const drawNisse = (context, pin) => {
			const base = project(pin.x, pin.y, pin.z);
			const scale = base.scale;
			const bob = this.reducedMotion || pin.isDown ? 0 : Math.sin((bowling.time * 4) + pin.phase) * 0.02 * scale;
			context.save();
			context.translate(base.x, base.y);
			if (pin.isDown) {
				context.rotate(pin.phase);
				context.translate(0, -0.2 * scale);
				context.rotate(pin.tilt * (pin.spin >= 0 ? 1 : -1));
				context.translate(0, 0.2 * scale);
			}

			const unit = scale * 0.32;
			context.translate(0, bob);
			// The shadow on the lane.
			if (!pin.isDown) {
				context.fillStyle = '#00000033';
				context.beginPath();
				context.ellipse(0, 0, unit * 0.9, unit * 0.25, 0, 0, Math.PI * 2);
				context.fill();
			}

			if (pin.role === 'mooner' && !pin.isDown) {
				// From behind: the gray sweater, and the red trousers that wiggle.
				const wiggle = this.reducedMotion ? 0.4 : Math.sin(bowling.time * 14);
				context.fillStyle = '#7a7a7a';
				context.fillRect(-unit * 0.6, -unit * 2, unit * 1.2, unit * 1);
				context.save();
				context.translate(wiggle * unit * 0.15, 0);
				context.fillStyle = '#d01818';
				context.beginPath();
				context.arc(-unit * 0.3, -unit * 0.7, unit * 0.42, 0, Math.PI * 2);
				context.arc(unit * 0.3, -unit * 0.7, unit * 0.42, 0, Math.PI * 2);
				context.fill();
				context.fillStyle = '#ffd25a';
				context.fillRect(-unit * 0.45, -unit * 0.85, unit * 0.25, unit * 0.25);
				context.restore();
				context.fillStyle = '#3a2a1a';
				context.fillRect(-unit * 0.5, -unit * 0.3, unit * 0.35, unit * 0.3);
				context.fillRect(unit * 0.15, -unit * 0.3, unit * 0.35, unit * 0.3);
				context.fillStyle = '#d01818';
				context.beginPath();
				context.moveTo(-unit * 0.5, -unit * 2);
				context.lineTo(unit * 0.5, -unit * 2);
				context.lineTo(unit * 0.15, -unit * 3.1);
				context.closePath();
				context.fill();
				context.restore();
				return;
			}

			// A nisse from the front: wooden shoes, knickers, a gray sweater, a white beard, and the red cap with a tassel.
			context.fillStyle = '#3a2a1a';
			context.fillRect(-unit * 0.5, -unit * 0.3, unit * 0.38, unit * 0.3);
			context.fillRect(unit * 0.12, -unit * 0.3, unit * 0.38, unit * 0.3);
			context.fillStyle = '#2c4a7a';
			context.fillRect(-unit * 0.5, -unit * 0.9, unit, unit * 0.65);
			context.fillStyle = '#8a8a8a';
			context.beginPath();
			context.roundRect(-unit * 0.6, -unit * 1.9, unit * 1.2, unit * 1.1, unit * 0.3);
			context.fill();
			context.fillStyle = '#f2c9a0';
			context.beginPath();
			context.arc(0, -unit * 2.15, unit * 0.42, 0, Math.PI * 2);
			context.fill();
			context.fillStyle = '#ffffff';
			context.beginPath();
			context.moveTo(-unit * 0.42, -unit * 2.1);
			context.quadraticCurveTo(0, -unit * 1.1, unit * 0.42, -unit * 2.1);
			context.fill();
			context.fillStyle = '#000000';
			const isScared = pin.role === 'dodger';
			context.beginPath();
			context.arc(-unit * 0.15, -unit * 2.25, unit * (isScared ? 0.09 : 0.06), 0, Math.PI * 2);
			context.arc(unit * 0.15, -unit * 2.25, unit * (isScared ? 0.09 : 0.06), 0, Math.PI * 2);
			context.fill();
			context.fillStyle = '#e06060';
			context.beginPath();
			context.arc(0, -unit * 2.1, unit * 0.08, 0, Math.PI * 2);
			context.fill();
			context.fillStyle = '#d01818';
			context.beginPath();
			context.moveTo(-unit * 0.45, -unit * 2.4);
			context.lineTo(unit * 0.45, -unit * 2.4);
			context.lineTo(unit * 0.6, -unit * 3.3);
			context.closePath();
			context.fill();
			context.fillStyle = '#ffffff';
			context.beginPath();
			context.arc(unit * 0.6, -unit * 3.3, unit * 0.13, 0, Math.PI * 2);
			context.fill();
			if (isScared) {
				// A drop of sweat: this nisse is a coward.
				context.fillStyle = '#66ccff';
				context.beginPath();
				context.arc(unit * 0.5, -unit * 2.5, unit * 0.09, 0, Math.PI * 2);
				context.fill();
			}

			context.restore();
		};

		const drawJulenissen = context => {
			const x = (laneWidth / 2) + (bowling.position * 110);
			const jump = bowling.cheer > 0 && !this.reducedMotion ? Math.abs(Math.sin(bowling.cheer * 9)) * 10 : 0;
			const y = 398 - jump;
			context.save();
			context.translate(x, y);
			// Julenissen from behind: the red suit, the white trim, the black belt, and the sack on his back.
			context.fillStyle = '#5a3a1a';
			context.beginPath();
			context.ellipse(-24, -58, 14, 18, -0.3, 0, Math.PI * 2);
			context.fill();
			context.fillStyle = '#c41010';
			context.beginPath();
			context.ellipse(0, -36, 26, 32, 0, 0, Math.PI * 2);
			context.fill();
			context.fillStyle = '#111111';
			context.fillRect(-26, -34, 52, 7);
			context.fillStyle = '#ffffff';
			context.fillRect(-26, -8, 52, 6);
			context.fillStyle = '#c41010';
			context.beginPath();
			context.arc(0, -72, 14, 0, Math.PI * 2);
			context.fill();
			context.fillStyle = '#ffffff';
			context.fillRect(-15, -72, 30, 5);
			context.beginPath();
			context.arc(14, -88, 5, 0, Math.PI * 2);
			context.fill();
			context.fillStyle = '#c41010';
			context.beginPath();
			context.moveTo(-12, -78);
			context.quadraticCurveTo(4, -100, 14, -88);
			context.lineTo(12, -76);
			context.closePath();
			context.fill();
			if (bowling.state === 'aim') {
				// The ball in his hand, ready.
				context.fillStyle = '#1a3a8a';
				context.beginPath();
				context.arc(26, -20, 10, 0, Math.PI * 2);
				context.fill();
				context.fillStyle = '#ffffff';
				context.fillRect(24, -24, 2, 2);
				context.fillRect(28, -22, 2, 2);
			}

			context.restore();
		};

		const drawLane = () => {
			const context = laneContext;
			// The back wall of the alley, with the banner, the garland, and the pit.
			context.fillStyle = '#2a1a3a';
			context.fillRect(0, 0, laneWidth, laneCanvas.height);
			context.fillStyle = '#1b5e20';
			for (let x = 0; x < laneWidth; x += 14) {
				context.beginPath();
				context.arc(x + 7, 4, 9, 0, Math.PI);
				context.fill();
			}

			for (const [index, color] of ['#ff3333', '#ffdd33', '#33aaff', '#ff66cc'].entries()) {
				const isLit = this.reducedMotion || Math.floor((bowling.time * 3) + index) % 2 === 0;
				context.fillStyle = isLit ? color : '#444444';
				for (let x = 10 + (index * 14); x < laneWidth; x += 56) {
					context.beginPath();
					context.arc(x, 11, 2.5, 0, Math.PI * 2);
					context.fill();
				}
			}

			const far = project(0, laneEnd);
			const near = project(0, 0);
			// The gutters and the boards of the lane.
			context.fillStyle = '#333333';
			context.beginPath();
			context.moveTo(project(-gutterHalf, laneEnd).x, far.y);
			context.lineTo(project(gutterHalf, laneEnd).x, far.y);
			context.lineTo(project(gutterHalf, 0).x, near.y);
			context.lineTo(project(-gutterHalf, 0).x, near.y);
			context.fill();
			const wood = context.createLinearGradient(0, far.y, 0, near.y);
			wood.addColorStop(0, '#c9965a');
			wood.addColorStop(1, '#e8bb7a');
			context.fillStyle = wood;
			context.beginPath();
			context.moveTo(project(-laneHalf, laneEnd).x, far.y);
			context.lineTo(project(laneHalf, laneEnd).x, far.y);
			context.lineTo(project(laneHalf, 0).x, near.y);
			context.lineTo(project(-laneHalf, 0).x, near.y);
			context.fill();
			context.strokeStyle = '#b07c44';
			context.lineWidth = 0.6;
			for (let board = -laneHalf + 0.2; board < laneHalf; board += 0.2) {
				context.beginPath();
				context.moveTo(project(board, laneEnd).x, far.y);
				context.lineTo(project(board, 0).x, near.y);
				context.stroke();
			}

			// The arrows on the lane, which bowlers aim by.
			context.fillStyle = '#7a4a1a';
			for (const x of [-0.6, -0.3, 0, 0.3, 0.6]) {
				const tip = project(x, 5.2);
				const left = project(x - 0.06, 4.8);
				const right = project(x + 0.06, 4.8);
				context.beginPath();
				context.moveTo(tip.x, tip.y);
				context.lineTo(left.x, left.y);
				context.lineTo(right.x, right.y);
				context.fill();
			}

			// Where the ball went, in dots, for reduced motion.
			if (this.reducedMotion && bowling.path.length > 1) {
				context.fillStyle = '#1a3a8a';
				for (const point of bowling.path) {
					const position = project(point.x, point.y);
					context.beginPath();
					context.arc(position.x, position.y, Math.max(1, position.scale * 0.04), 0, Math.PI * 2);
					context.fill();
				}
			}

			// The nisser and the ball, the farthest first.
			const things = bowling.pins.filter(pin => !pin.isGone).map(pin => ({y: pin.y, pin}));
			if (bowling.ball) {
				things.push({y: bowling.ball.y, ball: bowling.ball});
			}

			things.sort((first, second) => second.y - first.y);
			for (const thing of things) {
				if (thing.pin) {
					drawNisse(context, thing.pin);
				} else {
					const ball = thing.ball;
					const position = project(ball.x, ball.y, ballRadius);
					const radius = ballRadius * position.scale;
					context.fillStyle = '#1a3a8a';
					context.beginPath();
					context.arc(position.x, position.y, radius, 0, Math.PI * 2);
					context.fill();
					context.fillStyle = '#ffffff';
					const holeAngle = ball.spinAngle;
					context.beginPath();
					context.arc(position.x + (Math.cos(holeAngle) * radius * 0.5), position.y - (Math.abs(Math.sin(holeAngle)) * radius * 0.4), Math.max(1, radius * 0.12), 0, Math.PI * 2);
					context.fill();
				}
			}

			if (bowling.state === 'aim') {
				// Where the ball goes from, and which way it hooks.
				const start = project(bowling.position, 0.6);
				const aim = project(bowling.position + (bowling.spin * 0.12), 5);
				context.strokeStyle = '#ffffffaa';
				context.setLineDash([4, 4]);
				context.lineWidth = 2;
				context.beginPath();
				context.moveTo(start.x, start.y - 20);
				context.lineTo(aim.x, aim.y);
				context.stroke();
				context.setLineDash([]);
			}

			// The frame, under the speech bubbles, which only stay for a moment.
			const state = gameState(bowling.rolls);
			context.fillStyle = '#ffffff';
			context.font = 'bold 11px Verdana, sans-serif';
			context.textAlign = 'left';
			context.fillText(state.isOver ? 'GAME OVER' : `FRAME ${state.frame + 1} · BALL ${state.ball + 1}`, 6, 30);
			drawJulenissen(context);
			for (const bubble of bowling.bubbles) {
				const head = project(bubble.pin.x, bubble.pin.y, bubble.pin.isDown ? 0.2 : 1.05);
				drawBubble(context, bubble.text, head.x, head.y);
			}

			if (bowling.banner) {
				context.save();
				context.font = 'bold 40px Impact, "Arial Black", sans-serif';
				context.textAlign = 'center';
				context.lineWidth = 6;
				context.strokeStyle = '#000000';
				context.fillStyle = Math.floor(bowling.time * 8) % 2 === 0 || this.reducedMotion ? '#ffdd00' : '#ff3333';
				context.strokeText(bowling.banner.text, laneWidth / 2, 230);
				context.fillText(bowling.banner.text, laneWidth / 2, 230);
				context.restore();
			}
		};

		const moveJulenissen = direction => {
			if (bowling.state !== 'aim') {
				return;
			}

			bowling.position = clamp(bowling.position + (direction * 0.1), -0.85, 0.85);
			if (this.reducedMotion) {
				const standing = standingPins();
				if (standing.length > 0 && Math.random() < 0.35) {
					say(randomItem(standing), randomItem(taunts));
				}
			}

			drawLane();
		};

		const changeSpin = direction => {
			if (bowling.state !== 'aim') {
				return;
			}

			bowling.spin = clamp(bowling.spin + direction, -3, 3);
			updateSpin();
			drawLane();
		};

		const bowlActions = {
			left: () => moveJulenissen(-1),
			right: () => moveJulenissen(1),
			'spin-left': () => changeSpin(-1),
			'spin-right': () => changeSpin(1),
			bowl: throwBall,
			new: newGame,
		};

		for (const button of bowlButtons) {
			const action = button.dataset.christmasBowl;
			this.on(button, 'click', bowlActions[action]);

			// Holding the move buttons steers the ball while it rolls, like the arrow keys.
			if (action === 'left' || action === 'right') {
				const direction = action === 'left' ? -1 : 1;
				this.on(button, 'pointerdown', () => {
					if (bowling.state === 'rolling') {
						bowling.steer = direction;
					}
				});

				for (const type of ['pointerup', 'pointerleave', 'pointercancel']) {
					this.on(button, type, () => {
						bowling.steer = 0;
					});
				}
			}
		}

		this.on(laneCanvas, 'keydown', event => {
			const directions = {ArrowLeft: -1, ArrowRight: 1};
			if (directions[event.key] !== undefined) {
				event.preventDefault();
				if (bowling.state === 'rolling') {
					bowling.steer = directions[event.key];
				} else if (this.reducedMotion) {
					moveJulenissen(directions[event.key]);
				} else if (!event.repeat) {
					moveJulenissen(directions[event.key]);
					bowling.heldMove = directions[event.key];
				}
			} else if (event.key === 'a' || event.key === 'A') {
				changeSpin(-1);
			} else if (event.key === 'd' || event.key === 'D') {
				changeSpin(1);
			} else if (event.key === ' ' || event.key === 'Enter') {
				event.preventDefault();
				if (!event.repeat) {
					throwBall();
				}
			}
		});

		this.on(laneCanvas, 'keyup', event => {
			if (event.key === 'ArrowLeft' || event.key === 'ArrowRight') {
				bowling.steer = 0;
				bowling.heldMove = 0;
			}
		});

		this.on(laneCanvas, 'blur', () => {
			bowling.steer = 0;
			bowling.heldMove = 0;
		});

		// A tap on the lane bowls, from where Julenissen stands.
		this.on(laneCanvas, 'click', throwBall);


		// A game in the middle is kept, so a reload goes on with it.
		if (!Array.isArray(bowling.rolls) || bowling.rolls.some(roll => !Number.isInteger(roll) || roll < 0 || roll > 10)) {
			bowling.rolls = [];
		}

		{
			const state = gameState(bowling.rolls);
			rackPins();
			if (!state.isFreshRack && !state.isOver) {
				// The nisser that were knocked down in the first ball of the frame stay away.
				const knocked = bowling.rolls.at(-1);
				bowling.pins = bowling.pins.slice(knocked);
			}

			pickRoles();
			bowling.bubbles = [];
		}

		updateSpin();
		renderSheet();
		drawLane();

		return {
			// A ball that rolls when reduced motion turns on goes to its end at once, as the loop stops.
			reducedMotionChanged: () => {
				if (this.reducedMotion && (bowling.state === 'rolling' || bowling.state === 'settling')) {
					rollToEnd();
				} else {
					drawLane();
				}
			},
		};
	}

	#setUpPorridge() {
		// The porridge of Christmas Eve at Mormor’s farm: the rice porridge is cooked and stirred, the almond is hidden in it, and the family eats until someone finds it. Then a bowl goes out to the barn for the nisse, and without butter, he plays pranks on the page.
		const {barn: barnCanvas, pigs: pigsDisplay, porridgeStatus, pranks: pranksBox, prankList} = this.parts;
		const barnContext = barnCanvas.getContext('2d');
		const porridgeButtons = new Map([...this.querySelectorAll('[data-christmas-porridge]')].map(button => [button.dataset.christmasPorridge, button]));

		const barnWidth = barnCanvas.width;
		const barnHeight = barnCanvas.height;

		const family = [
			{id: 'mormor', name: 'Mormor'},
			{id: 'pappa', name: 'Pappa'},
			{id: 'me', name: 'Meg'},
			{id: 'mamma', name: 'Mamma'},
			{id: 'lillesoster', name: 'Lillesøster'},
		];

		const freshPorridge = () => ({
			stage: 'cook',
			progress: 0,
			burn: 0,
			stir: 0,
			stirAngle: 0,
			almondDrop: 1,
			bowls: {},
			eaten: {},
			owner: undefined,
			spoonAt: 0,
			finder: undefined,
			isHidden: false,
			isFixed: false,
			isMealOver: false,
			helpings: 0,
			nisseBowl: {isFilled: false, butter: false, sugar: false, cinnamon: false},
			walk: 0,
			morning: undefined,
			time: 0,
			smoke: [],
		});

		const porridge = freshPorridge();
		let pigs = Math.max(0, Math.floor(this.stored('pigs', 0)));

		const nisse = {
			isAngry: this.stored('nisse', false),
			pranks: [],
			timer: undefined,
			delay: undefined,
		};

		// The buttons that can be used in each part of the evening.
		const stageButtons = {
			cook: ['stir'],
			almond: ['almond'],
			ready: ['serve'],
			table: ['eat'],
			nisse: ['fill', 'butter', 'sugar', 'cinnamon', 'carry', 'steal'],
			barn: ['morning'],
			morning: ['again'],
		};

		const updatePorridgeButtons = () => {
			const visible = new Set(stageButtons[porridge.stage]);
			if (porridge.stage === 'table' && porridge.isMealOver) {
				visible.delete('eat');
				visible.add('fill');
			} else if (porridge.stage === 'table' && porridge.bowls.me === 0) {
				visible.delete('eat');
				visible.add('more');
			}

			if (porridge.stage === 'nisse') {
				if (porridge.nisseBowl.isFilled) {
					visible.delete('fill');
				} else {
					for (const action of ['butter', 'sugar', 'cinnamon', 'carry', 'steal']) {
						visible.delete(action);
					}
				}
			}

			if ((porridge.stage === 'morning' || porridge.stage === 'ready') && nisse.isAngry) {
				visible.add('fill');
			}

			for (const [action, button] of porridgeButtons) {
				button.hidden = !visible.has(action);
			}

			for (const action of ['butter', 'sugar', 'cinnamon']) {
				setPressed(porridgeButtons.get(action), porridge.nisseBowl[action]);
			}
		};

		const updatePigs = () => {
			pigsDisplay.textContent = pigs === 0 ? 'Marzipan pigs: none yet' : `Marzipan pigs: ${'🐷'.repeat(Math.min(pigs, 8))}${pigs > 8 ? ` × ${pigs}` : ''}`;
		};

		const setStage = stage => {
			porridge.stage = stage;
			updatePorridgeButtons();
			drawBarn();
		};

		const stirPot = () => {
			porridge.stir = 0.5;
			porridge.stirAngle += 1.4;
			porridge.burn = 0;
			porridge.progress = Math.min(100, porridge.progress + (this.reducedMotion ? 12.5 : 8));
			sound.stir();
			if (porridge.progress >= 100) {
				setStage('almond');
				return 'The porridge is thick and creamy. Ferdig! Now the almond, before Mamma serves it.';
			}

			return porridge.progress < 40 ? 'Stir, stir. The milk is starting to bubble.' : porridge.progress < 80 ? 'It is getting thick! Keep stirring, it burns at the bottom so easily.' : 'Almost done!';
		};

		const burnPorridge = () => {
			porridge.progress = 0;
			porridge.burn = 0;
			this.say('SVIDD! The porridge burned at the bottom, and the whole house smells. Mamma opens the window, says a word I can’t write here, and starts again. Stir more often!', porridgeStatus);
			sound.grumble();
		};

		const hideAlmond = () => {
			porridge.almondDrop = this.reducedMotion ? 1 : 0;
			sound.tone(1600, 0.08, {type: 'triangle', volume: 0.05});
			sound.burst(0.15, {volume: 0.1, frequency: 400, when: 0.4});
			setStage('ready');
			return 'Mamma drops one peeled almond in the pot, and stirs, so nobody knows where it is. Whoever finds it in their bowl wins the marzipan pig!';
		};

		const servePorridge = () => {
			for (const person of family) {
				porridge.bowls[person.id] = 6;
				porridge.eaten[person.id] = 0;
			}

			porridge.helpings = 1;
			// Mamma does not know where the almond went, but Pappa sometimes “helps” Lillesøster.
			const roll = Math.random();
			porridge.isFixed = roll < 0.18;
			porridge.owner = porridge.isFixed ? 'lillesoster' : roll < 0.45 ? 'me' : roll < 0.62 ? 'mormor' : roll < 0.7 ? 'mamma' : roll < 0.78 ? 'pappa' : roll < 0.84 ? 'lillesoster' : 'pot';
			porridge.spoonAt = randomInteger(2, 6);
			porridge.finder = undefined;
			porridge.isHidden = false;
			porridge.isMealOver = false;
			sound.spoon();
			setStage('table');
			return 'Risengrynsgrøt with sugar, cinnamon, and a pat of butter in the middle (the smørøye) for everyone. Eat, and look for the almond!';
		};

		// Someone finds the almond. Only Mormor keeps it secret in her cheek, until all the bowls are empty, like every year.
		const findAlmond = finder => {
			porridge.finder = finder;
			if (finder === 'mormor' && !porridge.isHidden && family.some(person => person.id !== 'mormor' && porridge.bowls[person.id] > 0)) {
				porridge.isHidden = true;
				return 'Mormor stops chewing for a second, and smiles a strange little smile.';
			}

			porridge.isMealOver = true;
			if (finder === 'me') {
				pigs++;
				this.store('pigs', pigs);
				updatePigs();
				sound.fanfare();
				this.celebrate();
				return 'MANDEL!!! I found the almond! I win the marzipan pig (mandelgave), pink, with a red bow. Lillesøster cries. Now the nisse needs his bowl!';
			}

			sound.bells(6);
			const messages = {
				mormor: 'Mormor opens her mouth: the almond! She had it in her cheek the WHOLE time, while we ate and ate. She wins the marzipan pig. Again.',
				pappa: 'Pappa found the almond! He gives the marzipan pig to Lillesøster, because she cried.',
				mamma: 'Mamma found the almond! She says she will share the marzipan pig. She never does.',
				lillesoster: porridge.isFixed ? 'Lillesøster found the almond! Pappa winks at Mamma. I KNOW he put it in her bowl, like every year.' : 'Lillesøster found the almond! She runs around the table with the marzipan pig.',
			};
			return `${messages[finder]} Now the nisse needs his bowl!`;
		};

		const eatSpoonful = () => {
			if (porridge.bowls.me <= 0) {
				return undefined;
			}

			porridge.bowls.me--;
			porridge.eaten.me++;
			for (const person of family.filter(item => item.id !== 'me')) {
				if (porridge.bowls[person.id] > 0 && Math.random() < 0.7) {
					porridge.bowls[person.id]--;
					porridge.eaten[person.id]++;
				}
			}

			sound.spoon();
			let message = randomItem(['Mmm. Sugar and cinnamon.', 'A spoonful with butter from the smørøye.', 'No almond in this one.', 'Lillesøster looks in everyone’s bowls.', 'Pappa chews very slowly. Suspicious.']);
			const finder = family.find(person => person.id === porridge.owner && !porridge.finder && porridge.eaten[person.id] >= porridge.spoonAt);
			if (finder) {
				message = findAlmond(finder.id);
			}

			if (!porridge.isMealOver && porridge.bowls.me === 0) {
				// When my bowl is empty, the others finish theirs, and then everyone sees who has it.
				for (const person of family) {
					porridge.eaten[person.id] += porridge.bowls[person.id];
					porridge.bowls[person.id] = 0;
				}

				if (porridge.owner === 'pot' || (porridge.owner === 'me' && !porridge.finder)) {
					porridge.owner = 'pot';
					message = 'All the bowls are empty, and nobody found the almond! It must still be in the pot. Take seconds, quick, before Pappa does!';
				} else {
					message = findAlmond(porridge.owner);
				}
			}

			updatePorridgeButtons();
			drawBarn();
			return message;
		};

		const takeSeconds = () => {
			porridge.helpings++;
			porridge.bowls.me = 6;
			if (porridge.owner === 'pot') {
				porridge.owner = 'me';
				porridge.spoonAt = porridge.eaten.me + randomInteger(1, 6);
			}

			sound.spoon();
			updatePorridgeButtons();
			drawBarn();
			return 'Seconds! I am SO full, but the almond must be somewhere.';
		};

		const toggleTopping = topping => {
			porridge.nisseBowl[topping] = !porridge.nisseBowl[topping];
			sound.tone(topping === 'butter' ? 500 : 1800, 0.08, {type: 'triangle', volume: 0.05});
			updatePorridgeButtons();
			drawBarn();
			const messages = {
				butter: ['A big pat of butter in the middle. The nisse LOVES butter.', 'No butter? Are you sure? Remember the story…'],
				sugar: ['Sugar on top.', 'No sugar.'],
				cinnamon: ['Cinnamon on top.', 'No cinnamon.'],
			};
			return messages[topping][porridge.nisseBowl[topping] ? 0 : 1];
		};

		const carryBowl = () => {
			porridge.walk = this.reducedMotion ? 1 : 0;
			sound.door();
			setStage('barn');
			return 'In my boots and my jacket, I carry the bowl through the snow to the barn, and put it on the step. It is dark and cold, and something rustles in the hay. Now go to bed!';
		};

		const eatNisseBowl = () => {
			porridge.nisseBowl.isFilled = false;
			sound.spoon();
			updatePorridgeButtons();
			drawBarn();
			makeAngry();
			return 'Mmm, the best porridge of the evening… Oh no. That was the nisse’s bowl. Something giggles in the barn. Fill a new bowl, quick!';
		};

		const nextMorning = () => {
			const bowl = porridge.nisseBowl;
			const isHappy = bowl.butter;
			porridge.morning = {isHappy};
			setStage('morning');
			if (!isHappy) {
				makeAngry();
				sound.grumble();
				return 'In the morning, the porridge is thrown all over the barn door, and there is a note: “INGEN SMØR?! NÅ SKAL DU FÅ SE!” (“No butter?! Now you will see!”) Look at my page…';
			}

			const wasAngry = nisse.isAngry;
			makeHappy();
			sound.bells(10);
			const deed = randomItem(['The horse is brushed, and the cow has fresh hay.', 'The cat got a bit of porridge too, and the barn is swept.', 'There are tiny footprints in the snow, all the way to the woods.']);
			return `The bowl is licked clean! ${deed}${bowl.sugar && bowl.cinnamon ? '' : ' A tiny note says: “Mer sukker og kanel neste år.” (“More sugar and cinnamon next year.”)'}${wasAngry ? ' And the nisse put everything on my page back the way it was.' : ' God jul, nisse!'}`;
		};

		const porridgeActions = {
			stir: stirPot,
			almond: hideAlmond,
			serve: servePorridge,
			eat: eatSpoonful,
			more: takeSeconds,
			fill() {
				porridge.nisseBowl = {isFilled: true, butter: false, sugar: false, cinnamon: false};
				porridge.morning = undefined;
				sound.spoon();
				setStage('nisse');
				return 'A wooden bowl of warm porridge for the nisse in the barn. What goes on top?';
			},
			butter: () => toggleTopping('butter'),
			sugar: () => toggleTopping('sugar'),
			cinnamon: () => toggleTopping('cinnamon'),
			carry: carryBowl,
			steal: eatNisseBowl,
			morning: nextMorning,
			again() {
				Object.assign(porridge, freshPorridge());
				setStage('cook');
				return 'Christmas Eve again! The rice and the milk are in the pot. Stir, so it does not burn!';
			},
		};

		for (const [action, button] of porridgeButtons) {
			this.on(button, 'click', () => {
				const message = porridgeActions[action]();
				if (message) {
					this.say(message, porridgeStatus);
				}

				porridgeLoop.start();
			});
		}

		// Sets an inline style on an element that another part of the page owns, and gives back the undo, which leaves the style alone when that part changed it in the meantime.
		const changeStyle = (element, property, value) => {
			const previous = element.style[property];
			element.style[property] = value;
			const changed = element.style[property];
			return () => {
				if (element.style[property] === changed) {
					element.style[property] = previous;
				}
			};
		};

		// The pranks of the angry nisse, on the rest of the page, outside this element: small things, which he puts back when he gets a bowl with butter. None of them hides a button or turns a canvas that the visitor plays on.
		const pranks = {
			window: {
				label: 'Knocked the title bar of one of my windows crooked',
				toast: '😠 The barn nisse knocked a window of my page crooked! Bring him porridge WITH butter.',
				apply: () => {
					// The bowling first, as it is right next to the porridge.
					const titleBar = ['bowling', 'gingerbread', 'porridge'].map(name => this.querySelector(`[data-christmas-title-bar="${name}"]`)).find(item => item.dataset.state !== 'tilted');
					if (!titleBar) {
						return undefined;
					}

					titleBar.dataset.state = 'tilted';
					return {target: titleBar, undo() {
						delete titleBar.dataset.state;
					}};
				},
			},
			tilt: {
				label: 'Tilted a GIF',
				toast: '😠 The barn nisse tilted a GIF! Bring him porridge WITH butter.',
				apply() {
					const image = pickGIF();
					return image && {target: image, undo: changeStyle(image, 'rotate', `${randomItem([-1, 1]) * randomInteger(15, 30)}deg`)};
				},
			},
			flip: {
				label: 'Turned a GIF upside down',
				toast: '😠 The barn nisse turned a GIF upside down! Bring him porridge WITH butter.',
				apply() {
					const image = pickGIF();
					return image && {target: image, undo: changeStyle(image, 'scale', '1 -1')};
				},
			},
			counter: {
				label: 'Smeared porridge on my visitor counter, so nobody can read how popular I am',
				toast: '😠 The barn nisse smeared porridge on my visitor counter! Bring him porridge WITH butter.',
				apply() {
					const counter = document.querySelector('#geocities-counter');
					return counter && {target: counter.parentElement, undo: changeStyle(counter, 'filter', 'blur(4px) sepia(1)')};
				},
			},
			title: {
				label: 'Swapped two letters of my title',
				toast: '😠 The barn nisse messed with the title of my page! Bring him porridge WITH butter.',
				apply() {
					const welcome = document.querySelector('#geocities-welcome');
					if (!welcome) {
						return undefined;
					}

					const walker = document.createTreeWalker(welcome, NodeFilter.SHOW_TEXT);
					let node = walker.nextNode();
					while (node && node.data.trim().length < 5) {
						node = walker.nextNode();
					}

					if (!node) {
						return undefined;
					}

					const original = node.data;
					const letters = [...original];
					const isLetter = character => character.toLowerCase() !== character.toUpperCase();
					const candidates = letters.map((character, index) => index).filter(index => index > 0 && index < letters.length - 1 && isLetter(letters[index]) && isLetter(letters[index + 1]) && letters[index] !== letters[index + 1]);
					if (candidates.length === 0) {
						return undefined;
					}

					const index = randomItem(candidates);
					[letters[index], letters[index + 1]] = [letters[index + 1], letters[index]];
					const swapped = letters.join('');
					node.data = swapped;
					return {target: welcome, detail: `“${swapped.trim()}”`, undo() {
						if (node.isConnected && node.data === swapped) {
							node.data = original;
						}
					}};
				},
			},
		};

		const prankedImages = new Set();

		// A GIF that the visitor can see right now, or one of the nearest ones.
		const pickGIF = () => {
			const middle = innerHeight / 2;
			const distance = image => {
				const rectangle = image.getBoundingClientRect();
				return Math.abs(rectangle.top + (rectangle.height / 2) - middle);
			};

			const images = [...document.querySelectorAll('picture > img')]
				.filter(image => !prankedImages.has(image) && image.style.visibility !== 'hidden' && image.width >= 16 && image.width <= 300 && image.checkVisibility())
				.map(image => ({image, distance: distance(image)}))
				.sort((first, second) => first.distance - second.distance)
				.slice(0, 4);
			const image = randomItem(images)?.image;
			if (image) {
				prankedImages.add(image);
			}

			return image;
		};

		const renderPranks = () => {
			pranksBox.hidden = nisse.pranks.length === 0;
			prankList.replaceChildren(...nisse.pranks.map(prank => {
				const item = document.createElement('li');
				item.textContent = prank.detail ? `${prank.label}: ${prank.detail}` : prank.label;
				const button = document.createElement('button');
				button.type = 'button';
				button.textContent = '👀 Show Me';
				this.on(button, 'click', () => {
					prank.target.scrollIntoView({block: 'center', behavior: this.reducedMotion ? 'instant' : 'smooth'});
				});
				item.append(button);
				return item;
			}));
		};

		const playPrank = () => {
			if (!nisse.isAngry || document.visibilityState !== 'visible') {
				return;
			}

			const done = new Set(nisse.pranks.map(prank => prank.kind));
			// Each prank once, in this order, and then more crooked windows and GIFs, up to six pranks.
			const fresh = ['window', 'tilt', 'counter', 'title', 'flip'].filter(kind => !done.has(kind));
			const kinds = [...fresh, ...(nisse.pranks.length < 6 ? ['tilt', 'flip', 'window'] : [])];
			for (const kind of kinds) {
				const result = pranks[kind].apply();
				if (result) {
					nisse.pranks.push({kind, label: pranks[kind].label, ...result});
					renderPranks();
					sound.giggle();
					this.toast(pranks[kind].toast);
					drawBarn();
					return;
				}
			}
		};

		const makeAngry = () => {
			const wasAngry = nisse.isAngry;
			nisse.isAngry = true;
			this.store('nisse', true);
			if (!wasAngry || nisse.pranks.length === 0) {
				playPrank();
			}

			nisse.timer?.cancel();
			nisse.timer = this.interval(20_000, playPrank);
			updatePorridgeButtons();
		};

		const makeHappy = () => {
			nisse.isAngry = false;
			this.store('nisse', false);
			nisse.timer?.cancel();
			undoPranks();
			updatePorridgeButtons();
		};

		const undoPranks = () => {
			for (const prank of nisse.pranks.toReversed()) {
				prank.undo();
			}

			nisse.pranks = [];
			prankedImages.clear();
			renderPranks();
		};

		// Drawing of the scenes of the evening.
		const drawPig = (context, x, y, size = 1) => {
			context.save();
			context.translate(x, y);
			context.scale(size, size);
			context.fillStyle = '#ffb6c8';
			context.beginPath();
			context.ellipse(0, 0, 12, 8, 0, 0, Math.PI * 2);
			context.arc(11, -3, 6, 0, Math.PI * 2);
			context.fill();
			context.fillStyle = '#ff8fab';
			context.beginPath();
			context.ellipse(16, -2, 2.5, 2, 0, 0, Math.PI * 2);
			context.moveTo(8, -8);
			context.lineTo(10, -13);
			context.lineTo(13, -8);
			context.fill();
			context.fillStyle = '#000000';
			context.fillRect(12, -5, 1.5, 1.5);
			context.strokeStyle = '#ff8fab';
			context.lineWidth = 1.5;
			context.beginPath();
			context.arc(-14, -2, 2.5, 0, Math.PI * 1.6);
			context.stroke();
			context.fillStyle = '#d6001c';
			context.beginPath();
			context.moveTo(6, -6);
			context.lineTo(2, -10);
			context.lineTo(2, -2);
			context.lineTo(6, -6);
			context.lineTo(10, -10);
			context.lineTo(10, -2);
			context.fill();
			context.restore();
		};

		const drawBowl = (context, x, y, level, {width = 26, isWooden = false, butter = true, cinnamon = true, sugar = false} = {}) => {
			context.save();
			context.fillStyle = isWooden ? '#8a5a2a' : '#f4f4f4';
			context.strokeStyle = isWooden ? '#5a3a1a' : '#9db4d8';
			context.lineWidth = 1.5;
			context.beginPath();
			context.ellipse(x, y, width / 2, width / 6, 0, 0, Math.PI);
			context.lineTo(x - (width / 2), y);
			context.fill();
			context.beginPath();
			context.moveTo(x - (width / 2), y);
			context.quadraticCurveTo(x, y + (width * 0.75), x + (width / 2), y);
			context.fill();
			context.stroke();
			if (level > 0) {
				context.fillStyle = '#fdf6e3';
				context.beginPath();
				context.ellipse(x, y + ((1 - level) * width * 0.2), (width / 2.3) * (0.6 + (level * 0.4)), (width / 8) * (0.6 + (level * 0.4)), 0, 0, Math.PI * 2);
				context.fill();
				if (cinnamon) {
					context.fillStyle = '#8b4513';
					for (let index = 0; index < 6; index++) {
						context.fillRect(x - (width / 4) + ((index * 7) % (width / 2)), y - 1 + ((index * 3) % 3), 1.5, 1.5);
					}
				}

				if (sugar) {
					context.fillStyle = '#ffffff';
					for (let index = 0; index < 8; index++) {
						context.fillRect(x - (width / 3) + ((index * 5) % (width / 1.5)), y - 2 + ((index * 2) % 4), 1, 1);
					}
				}

				if (butter) {
					// The smørøye, the “butter eye”, melting in the middle.
					context.fillStyle = '#ffd84a';
					context.beginPath();
					context.ellipse(x, y + ((1 - level) * width * 0.2), 4, 1.6, 0, 0, Math.PI * 2);
					context.fill();
				}
			}

			if (!isWooden) {
				context.strokeStyle = '#3366cc';
				context.lineWidth = 1;
				context.beginPath();
				context.moveTo(x - (width / 2.4), y + 4);
				context.quadraticCurveTo(x, y + (width * 0.45), x + (width / 2.4), y + 4);
				context.stroke();
			}

			context.restore();
		};

		const drawAngryNisse = (context, x, y) => {
			context.save();
			context.translate(x, y);
			context.fillStyle = '#f2c9a0';
			context.beginPath();
			context.arc(0, 0, 8, 0, Math.PI * 2);
			context.fill();
			context.fillStyle = '#ffffff';
			context.beginPath();
			context.moveTo(-8, 1);
			context.quadraticCurveTo(0, 14, 8, 1);
			context.fill();
			context.fillStyle = '#d01818';
			context.beginPath();
			context.moveTo(-9, -4);
			context.lineTo(9, -4);
			context.lineTo(-2, -20);
			context.closePath();
			context.fill();
			context.strokeStyle = '#000000';
			context.lineWidth = 1.5;
			context.beginPath();
			context.moveTo(-6, -4);
			context.lineTo(-1, -1);
			context.moveTo(6, -4);
			context.lineTo(1, -1);
			context.stroke();
			context.fillStyle = '#000000';
			context.fillRect(-4, -1, 2, 2);
			context.fillRect(2, -1, 2, 2);
			context.restore();
		};

		const drawKitchenScene = context => {
			context.fillStyle = '#e8d2a8';
			context.fillRect(0, 0, barnWidth, barnHeight);
			context.strokeStyle = '#d4b98a';
			context.lineWidth = 1;
			for (let x = 0; x < barnWidth; x += 18) {
				context.beginPath();
				context.moveTo(x, 0);
				context.lineTo(x, 140);
				context.stroke();
			}

			// The kitchen window, with a star of Advent in it (julestjerne), and the dark winter evening outside.
			context.fillStyle = '#10204a';
			context.fillRect(20, 20, 70, 60);
			context.strokeStyle = '#ffffff';
			context.lineWidth = 3;
			context.strokeRect(20, 20, 70, 60);
			context.beginPath();
			context.moveTo(55, 20);
			context.lineTo(55, 80);
			context.stroke();
			context.fillStyle = '#ffdd66';
			context.beginPath();
			for (let point = 0; point < 10; point++) {
				const angle = (point * Math.PI / 5) - (Math.PI / 2);
				const radius = point % 2 === 0 ? 12 : 5;
				context.lineTo(55 + (Math.cos(angle) * radius), 40 + (Math.sin(angle) * radius));
			}

			context.fill();
			context.fillStyle = '#ffffff';
			for (let index = 0; index < 12; index++) {
				context.fillRect(24 + ((index * 23) % 62), 24 + ((index * 17) % 52), 1.5, 1.5);
			}

			// The black iron stove, and the big pot.
			context.fillStyle = '#9a7a5a';
			context.fillRect(0, 140, barnWidth, 60);
			context.fillStyle = '#222222';
			context.fillRect(150, 110, 140, 90);
			context.fillStyle = porridge.burn > 50 ? '#ff3300' : '#552222';
			context.beginPath();
			context.ellipse(220, 112, 40, 6, 0, 0, Math.PI * 2);
			context.fill();
			context.fillStyle = '#666666';
			context.fillRect(178, 70, 84, 42);
			context.beginPath();
			context.ellipse(220, 70, 42, 8, 0, 0, Math.PI * 2);
			context.fill();
			const thickness = porridge.progress / 100;
			context.fillStyle = `rgb(${Math.round(lerp(250, 253, thickness))}, ${Math.round(lerp(250, 240, thickness))}, ${Math.round(lerp(255, 205, thickness))})`;
			context.beginPath();
			context.ellipse(220, 72, 38, 6.5, 0, 0, Math.PI * 2);
			context.fill();
			if (!this.reducedMotion && porridge.progress > 10) {
				context.fillStyle = '#ffffffcc';
				for (let index = 0; index < 4; index++) {
					const phase = (porridge.time * (1 + (index * 0.3))) % 1;
					context.beginPath();
					context.arc(195 + (index * 16), 71 + ((index % 2) * 2), phase * 3, 0, Math.PI * 2);
					context.fill();
				}
			}

			// The wooden spoon, which turns with each stir.
			const angle = porridge.stirAngle;
			context.strokeStyle = '#b07c44';
			context.lineWidth = 4;
			context.beginPath();
			context.moveTo(220 + (Math.cos(angle) * 22), 72 + (Math.sin(angle) * 4));
			context.lineTo(240 + (Math.cos(angle) * 30), 30);
			context.stroke();

			if (porridge.almondDrop < 1) {
				context.fillStyle = '#e8d0a0';
				context.beginPath();
				context.ellipse(214, lerp(10, 70, porridge.almondDrop), 4, 2.5, 0.5, 0, Math.PI * 2);
				context.fill();
			}

			for (const puff of porridge.smoke) {
				context.fillStyle = `rgba(60, 60, 60, ${puff.life / 2})`;
				context.beginPath();
				context.arc(puff.x, puff.y, puff.size, 0, Math.PI * 2);
				context.fill();
			}

			// The meters of the pot.
			context.fillStyle = '#ffffff';
			context.fillRect(20, 150, 110, 12);
			context.fillRect(20, 172, 110, 12);
			context.fillStyle = '#ffcc66';
			context.fillRect(21, 151, porridge.progress * 1.08, 10);
			context.fillStyle = '#cc2200';
			context.fillRect(21, 173, (this.reducedMotion ? 0 : porridge.burn) * 1.08, 10);
			context.fillStyle = '#000000';
			context.font = 'bold 8px Verdana, sans-serif';
			context.textAlign = 'left';
			context.fillText('GRØT', 24, 159);
			context.fillText(this.reducedMotion ? 'BURNS: NOT TODAY' : 'BURNS', 24, 181);
		};

		const drawTableScene = context => {
			context.fillStyle = '#5a2a1a';
			context.fillRect(0, 0, barnWidth, barnHeight);
			context.fillStyle = '#ffdd88';
			context.beginPath();
			context.arc(160, -10, 60, 0, Math.PI);
			context.fill();
			context.fillStyle = '#b81d24';
			context.fillRect(0, 70, barnWidth, 130);
			context.fillStyle = '#ffffff22';
			for (let x = 0; x < barnWidth; x += 20) {
				context.fillRect(x, 70, 10, 130);
			}

			// Candles on the table.
			for (const x of [60, 260]) {
				context.fillStyle = '#ffffff';
				context.fillRect(x - 3, 40, 6, 30);
				context.fillStyle = '#ffcc33';
				context.beginPath();
				context.ellipse(x, 34 + (this.reducedMotion ? 0 : Math.sin(porridge.time * 10) * 0.8), 2.5, 5, 0, 0, Math.PI * 2);
				context.fill();
			}

			for (const [index, person] of family.entries()) {
				const x = 36 + (index * 62);
				const y = 120;
				const spoons = porridge.bowls[person.id] ?? 6;
				drawBowl(context, x, y, spoons / 6, {width: 40});
				context.fillStyle = '#ffffff';
				context.font = 'bold 9px Verdana, sans-serif';
				context.textAlign = 'center';
				context.fillText(person.name, x, 166);
				if (porridge.finder === person.id && (!porridge.isHidden || porridge.isMealOver)) {
					// The marzipan pig, and the almond on the edge of the bowl.
					drawPig(context, x, 92, 1.3);
					context.fillStyle = '#e8d0a0';
					context.beginPath();
					context.ellipse(x + 16, 118, 4, 2.5, 0.4, 0, Math.PI * 2);
					context.fill();
					context.fillStyle = '#ffdd00';
					context.font = 'bold 9px "Comic Sans MS", "Comic Sans", cursive';
					context.fillText('MANDEL!', x, 182);
				}
			}

			if (porridge.helpings > 1) {
				context.fillStyle = '#ffffff';
				context.font = 'bold 9px "Comic Sans MS", "Comic Sans", cursive';
				context.fillText(`Meg: helping ${porridge.helpings}`, 160, 64);
			}
		};

		const drawNisseBowlScene = context => {
			drawKitchenScene(context);
			context.fillStyle = '#c8a070';
			context.fillRect(0, 130, barnWidth, 70);
			const bowl = porridge.nisseBowl;
			drawBowl(context, 160, 150, bowl.isFilled ? 1 : 0, {width: 70, isWooden: true, butter: bowl.butter, cinnamon: bowl.cinnamon, sugar: bowl.sugar});
			if (bowl.butter) {
				context.fillStyle = '#ffd84a';
				context.fillRect(154, 140, 12, 7);
			}

			context.fillStyle = '#000000';
			context.font = 'bold 9px "Comic Sans MS", "Comic Sans", cursive';
			context.textAlign = 'center';
			context.fillText(bowl.isFilled ? 'FOR NISSEN' : 'An empty bowl…', 160, 194);
		};

		const drawFarm = (context, {isNight}) => {
			const sky = context.createLinearGradient(0, 0, 0, 130);
			sky.addColorStop(0, isNight ? '#050b24' : '#8ab4e8');
			sky.addColorStop(1, isNight ? '#1a2a5a' : '#f4d8c0');
			context.fillStyle = sky;
			context.fillRect(0, 0, barnWidth, barnHeight);
			if (isNight) {
				context.fillStyle = '#ffffff';
				for (let index = 0; index < 40; index++) {
					context.fillRect((index * 83) % barnWidth, (index * 29) % 90, 1, 1);
				}

				context.fillStyle = '#fff6c0';
				context.beginPath();
				context.arc(270, 30, 12, 0, Math.PI * 2);
				context.fill();
			} else {
				context.fillStyle = '#ffe080';
				context.beginPath();
				context.arc(40, 110, 16, 0, Math.PI * 2);
				context.fill();
			}

			context.fillStyle = isNight ? '#c8d4f0' : '#ffffff';
			context.fillRect(0, 130, barnWidth, 70);
			// The farmhouse, with a candle in the window, and the red barn with snow on the roof.
			context.fillStyle = '#f0f0f0';
			context.fillRect(10, 90, 50, 42);
			context.fillStyle = '#555555';
			context.beginPath();
			context.moveTo(4, 92);
			context.lineTo(35, 66);
			context.lineTo(66, 92);
			context.fill();
			context.fillStyle = isNight ? '#ffcc44' : '#88aacc';
			context.fillRect(20, 100, 10, 10);
			context.fillRect(40, 100, 10, 10);
			context.fillStyle = '#a01c1c';
			context.fillRect(180, 70, 110, 66);
			context.fillStyle = '#ffffff';
			context.beginPath();
			context.moveTo(172, 72);
			context.lineTo(235, 30);
			context.lineTo(298, 72);
			context.fill();
			context.fillStyle = '#7a1414';
			context.beginPath();
			context.moveTo(180, 72);
			context.lineTo(235, 38);
			context.lineTo(290, 72);
			context.fill();
			// The big doors, with the white cross, and the hatch of the hay loft.
			context.fillStyle = '#8a1818';
			context.fillRect(212, 90, 46, 46);
			context.strokeStyle = '#ffffff';
			context.lineWidth = 2;
			context.strokeRect(212, 90, 46, 46);
			context.beginPath();
			context.moveTo(212, 90);
			context.lineTo(258, 136);
			context.moveTo(258, 90);
			context.lineTo(212, 136);
			context.moveTo(235, 90);
			context.lineTo(235, 136);
			context.stroke();
			context.fillStyle = '#220a0a';
			context.fillRect(226, 50, 18, 16);
			context.fillStyle = '#e0e0e0';
			context.fillRect(205, 136, 60, 6);
		};

		const drawBarnScene = context => {
			drawFarm(context, {isNight: true});
			// My footprints in the snow, from the house to the barn.
			const walk = porridge.walk;
			context.fillStyle = '#9aa8cc';
			for (let step = 0; step < 14; step++) {
				const amount = step / 14;
				if (amount > walk) {
					break;
				}

				const x = lerp(62, 212, amount);
				context.beginPath();
				context.ellipse(x, 150 + ((step % 2) * 5) - (Math.sin(amount * Math.PI) * 6), 3, 1.5, 0, 0, Math.PI * 2);
				context.fill();
			}

			if (walk < 1) {
				// Me, in my blue snowsuit and the red hat from Mormor, with the bowl.
				const x = lerp(62, 212, walk);
				const y = 145 - (Math.sin(walk * Math.PI) * 6);
				context.fillStyle = '#2244aa';
				context.fillRect(x - 5, y - 18, 10, 18);
				context.fillStyle = '#f2c9a0';
				context.beginPath();
				context.arc(x, y - 22, 5, 0, Math.PI * 2);
				context.fill();
				context.fillStyle = '#d01818';
				context.beginPath();
				context.arc(x, y - 25, 5, Math.PI, 0);
				context.fill();
				drawBowl(context, x + 9, y - 12, 1, {width: 12, isWooden: true, cinnamon: false});
			} else {
				const bowl = porridge.nisseBowl;
				drawBowl(context, 235, 134, 1, {width: 22, isWooden: true, butter: bowl.butter, cinnamon: bowl.cinnamon, sugar: bowl.sugar});
				// Two eyes in the dark of the hay loft. They blink.
				const isBlinking = !this.reducedMotion && (porridge.time % 3) > 2.85;
				if (!isBlinking) {
					context.fillStyle = '#ffee88';
					context.fillRect(230, 56, 3, 3);
					context.fillRect(237, 56, 3, 3);
				}
			}
		};

		const drawMorningScene = context => {
			drawFarm(context, {isNight: false});
			const morning = porridge.morning;
			if (morning?.isHappy) {
				drawBowl(context, 235, 134, 0, {width: 22, isWooden: true});
				// The nisse waves from the door of the barn.
				context.save();
				context.translate(270, 132);
				context.fillStyle = '#8a8a8a';
				context.fillRect(-6, -20, 12, 14);
				context.fillStyle = '#2c4a7a';
				context.fillRect(-6, -7, 12, 7);
				context.fillStyle = '#f2c9a0';
				context.beginPath();
				context.arc(0, -25, 5, 0, Math.PI * 2);
				context.fill();
				context.fillStyle = '#ffffff';
				context.beginPath();
				context.moveTo(-5, -24);
				context.quadraticCurveTo(0, -14, 5, -24);
				context.fill();
				context.fillStyle = '#d01818';
				context.beginPath();
				context.moveTo(-6, -28);
				context.lineTo(6, -28);
				context.lineTo(8, -40);
				context.closePath();
				context.fill();
				context.strokeStyle = '#8a8a8a';
				context.lineWidth = 3;
				const wave = this.reducedMotion ? 0 : Math.sin(porridge.time * 8) * 0.4;
				context.beginPath();
				context.moveTo(6, -18);
				context.lineTo(12 + (wave * 4), -30);
				context.stroke();
				context.restore();
				drawBubble(context, 'Takk for grøten!', 270, 88);
			} else {
				// The porridge on the barn door, and the angry note.
				context.fillStyle = '#fdf6e3';
				for (const [x, y, radius] of [[228, 100, 8], [240, 108, 6], [222, 116, 5], [246, 96, 4], [232, 124, 4]]) {
					context.beginPath();
					context.arc(x, y, radius, 0, Math.PI * 2);
					context.fill();
				}

				drawBowl(context, 200, 160, 0, {width: 22, isWooden: true});
				context.fillStyle = '#ffffff';
				context.fillRect(100, 150, 70, 30);
				context.strokeStyle = '#cc0000';
				context.strokeRect(100, 150, 70, 30);
				context.fillStyle = '#cc0000';
				context.font = 'bold 8px "Comic Sans MS", "Comic Sans", cursive';
				context.textAlign = 'center';
				context.fillText('INGEN SMØR?!', 135, 162);
				context.fillText('NÅ SKAL DU FÅ SE!', 135, 174);
				drawAngryNisse(context, 290, 120);
			}
		};

		const drawBarn = () => {
			const scenes = {
				cook: drawKitchenScene,
				almond: drawKitchenScene,
				ready: drawKitchenScene,
				table: drawTableScene,
				nisse: drawNisseBowlScene,
				barn: drawBarnScene,
				morning: drawMorningScene,
			};
			scenes[porridge.stage](barnContext);
			if (nisse.isAngry && porridge.stage !== 'morning') {
				// The angry nisse peeks in at the corner while he plays his pranks.
				drawAngryNisse(barnContext, barnWidth - 14, 26);
			}
		};

		const porridgeLoop = this.loop(seconds => {
			porridge.time += seconds;
			porridge.stir = Math.max(0, porridge.stir - seconds);
			if (porridge.stir > 0) {
				porridge.stirAngle += seconds * 6;
			}

			if (porridge.stage === 'cook' && porridge.progress > 0) {
				// Once the visitor stirs, the porridge cooks by itself, and it burns at the bottom if nobody stirs it for a few seconds.
				porridge.progress = Math.min(99, porridge.progress + (seconds * 1.5));
				porridge.burn += seconds * 24;
				if (porridge.burn > 60 && Math.random() < seconds * 8) {
					porridge.smoke.push({x: randomBetween(190, 250), y: 66, size: 3, life: 2});
				}

				if (porridge.burn >= 100) {
					burnPorridge();
				}
			}

			for (const puff of porridge.smoke) {
				puff.y -= seconds * 18;
				puff.size += seconds * 4;
				puff.life -= seconds;
			}

			porridge.smoke = porridge.smoke.filter(puff => puff.life > 0);
			if (porridge.almondDrop < 1) {
				porridge.almondDrop = Math.min(1, porridge.almondDrop + (seconds * 1.6));
			}

			if (porridge.stage === 'barn' && porridge.walk < 1) {
				porridge.walk = Math.min(1, porridge.walk + (seconds * 0.4));
			}

			drawBarn();
		}, {while: () => !this.reducedMotion, target: barnCanvas});


		// An angry nisse stays angry after a reload, and goes on with his pranks a little later.
		if (nisse.isAngry) {
			nisse.timer = this.interval(20_000, playPrank);
			nisse.delay = this.timeout(5000, playPrank);
			this.say('The nisse is still angry from last time! Cook the porridge, and bring him a bowl WITH butter.', porridgeStatus);
		}

		updatePigs();
		updatePorridgeButtons();
		drawBarn();

		return {
			reducedMotionChanged: () => {
				if (this.reducedMotion) {
					porridge.walk = 1;
					porridge.almondDrop = 1;
					porridge.smoke = [];
				}

				drawBarn();
			},
			// The pranks are on the rest of the page, so they are put back when the toy is removed, and the nisse stays angry in the browser, like after a reload.
			disconnected() {
				undoPranks();
			},
		};
	}
}
