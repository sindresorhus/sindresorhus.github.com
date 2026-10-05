// My Discman and my Walkman on the 1999 page. The music is made in the browser: each song is a list of notes, written by a small composer from chords and a seed, and a sequencer plays the notes that are due, a moment ahead, through the speakers. Nothing plays out loud until the visitor puts on the headphones, with a button that says it plays sound. The Discman skips when it is shaken, unless the ESP buffer has music in it; the Walkman eats its tape, is wound back with a pencil, and slows down as its batteries die.
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

// A tiny pixel font of 3 × 5 for the displays, so the text is crisp at any size. Each letter is five rows of three bits.
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

// Shapes for the canvases of the players.
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

// Sets up the headphones, the Discman, and the Walkman in the element, and gives the function that pauses them when another toy starts a tune.
const setUp = (music, {sound: soundButton, discmanCanvas, discmanStatus, walkmanCanvas, walkmanStatus}) => {
	const midi = note => 440 * (2 ** ((note - 69) / 12));

	// A random number generator with a seed, so a song is the same every time.
	const seeded = seed => () => {
		seed = (seed + 0x6D2B79F5) | 0;
		let value = Math.imul(seed ^ (seed >>> 15), 1 | seed);
		value = (value + Math.imul(value ^ (value >>> 7), 61 | value)) ^ value;
		return ((value ^ (value >>> 14)) >>> 0) / 4_294_967_296;
	};

	const scales = {
		major: [0, 2, 4, 5, 7, 9, 11],
		minor: [0, 2, 3, 5, 7, 8, 10],
	};

	// Writes a song: a bass line, chords as arpeggios, drums, and a melody that lands on the notes of the chord on the strong beats, mostly in small steps.
	const compose = ({seed, tempo, root, scale, progression, beatsPerBar = 4, repeats = 3, style}) => {
		const random = seeded(seed);
		const beat = 60 / tempo;
		const notes = [];
		const steps = scales[scale];
		const degreeNote = (degree, octave = 0) => root + steps[((degree % 7) + 7) % 7] + (12 * (Math.floor(degree / 7) + octave));
		// The melody of the first time through is kept, so it comes back on the repeats, like a chorus.
		const melody = [];
		let melodyDegree = 7;
		for (const [barIndex, chord] of progression.entries()) {
			const chordDegrees = [chord, chord + 2, chord + 4];
			for (let index = 0; index < beatsPerBar * 2; index++) {
				const isStrong = index % 2 === 0;
				if (random() < (isStrong ? 0.15 : 0.45)) {
					melody.push({bar: barIndex, eighth: index, rest: true});
					continue;
				}

				if (isStrong) {
					const targets = chordDegrees.map(degree => degree + 7);
					melodyDegree = targets.sort((first, second) => Math.abs(first - melodyDegree) - Math.abs(second - melodyDegree))[random() < 0.7 ? 0 : 1];
				} else {
					melodyDegree += random() < 0.5 ? 1 : -1;
				}

				melodyDegree = clamp(melodyDegree, 4, 13);
				melody.push({bar: barIndex, eighth: index, degree: melodyDegree, isLong: random() < 0.3});
			}
		}

		const barLength = beat * beatsPerBar;
		for (let repeat = 0; repeat < repeats; repeat++) {
			for (const [barIndex, chord] of progression.entries()) {
				const barStart = ((repeat * progression.length) + barIndex) * barLength;
				for (let beatIndex = 0; beatIndex < beatsPerBar; beatIndex++) {
					const time = barStart + (beatIndex * beat);
					// The bass: the root of the chord, walking up in a boogie, or in octaves in a disco.
					if (style === 'boogie') {
						const walk = [0, 2, 4, 5][beatIndex % 4];
						notes.push({time, duration: beat * 0.9, frequency: midi(degreeNote(chord + walk, -2)), instrument: 'triangle', volume: 0.14});
					} else if (style === 'disco') {
						notes.push({time, duration: beat * 0.4, frequency: midi(degreeNote(chord, -2)), instrument: 'triangle', volume: 0.14});
						notes.push({time: time + (beat / 2), duration: beat * 0.4, frequency: midi(degreeNote(chord, -1)), instrument: 'triangle', volume: 0.12});
					} else if (style === 'waltz') {
						if (beatIndex === 0) {
							notes.push({time, duration: beat * 0.9, frequency: midi(degreeNote(chord, -2)), instrument: 'triangle', volume: 0.14});
						} else {
							for (const degree of [chord + 2, chord + 4]) {
								notes.push({time, duration: beat * 0.4, frequency: midi(degreeNote(degree, -1)), instrument: 'square', volume: 0.025});
							}
						}
					} else if (beatIndex % 2 === 0) {
						notes.push({time, duration: beat * 1.8, frequency: midi(degreeNote(chord, -2)), instrument: 'triangle', volume: 0.13});
					}

					// The drums.
					if (style === 'boogie' || style === 'disco' || style === 'pop') {
						if (style === 'disco' || beatIndex % 2 === 0) {
							notes.push({time, duration: 0.15, instrument: 'kick', volume: 0.5});
						}

						if (beatIndex % 2 === 1) {
							notes.push({time, duration: 0.12, instrument: 'snare', volume: 0.18});
						}

						notes.push({time: time + (beat / 2), duration: 0.04, instrument: 'hat', volume: style === 'disco' ? 0.08 : 0.05});
					} else if (style === 'rain') {
						// Soft hi-hats in sixteenths, like rain on the window.
						for (let sixteenth = 0; sixteenth < 4; sixteenth++) {
							notes.push({time: time + (sixteenth * beat / 4), duration: 0.03, instrument: 'hat', volume: 0.015 + (random() * 0.02)});
						}
					}

					// The chords, as arpeggios in eighths, which most songs have, and sparkles for the dreamy ones.
					if (style !== 'waltz') {
						for (let half = 0; half < 2; half++) {
							const degree = [chord, chord + 2, chord + 4, chord + 7][((beatIndex * 2) + half) % 4];
							notes.push({time: time + (half * beat / 2), duration: beat * 0.45, frequency: midi(degreeNote(degree, style === 'dream' ? 1 : 0)), instrument: style === 'dream' || style === 'rain' ? 'triangle' : 'square', volume: style === 'dream' ? 0.04 : 0.02});
						}
					}
				}

				// The melody, which sits out the first time through, so the song builds up.
				if (repeat > 0 || style === 'pop') {
					for (const entry of melody.filter(entry => entry.bar === barIndex && !entry.rest)) {
						notes.push({time: barStart + (entry.eighth * beat / 2), duration: beat * (entry.isLong ? 0.95 : 0.45), frequency: midi(degreeNote(entry.degree)), instrument: style === 'disco' || style === 'pop' ? 'sawtooth' : 'square', volume: style === 'disco' || style === 'pop' ? 0.035 : 0.05});
					}
				}

				// The modem of the disco song answers the melody.
				if (style === 'disco' && barIndex % 4 === 3) {
					for (let chirp = 0; chirp < 4; chirp++) {
						notes.push({time: barStart + (chirp * beat / 4) + (beat * 2), duration: 0.06, frequency: 1200 + (chirp * 500), instrument: 'square', volume: 0.02});
					}
				}
			}
		}

		const length = repeats * progression.length * barLength;
		return {notes: notes.sort((first, second) => first.time - second.time), length};
	};

	// A radio DJ who talks over the start of the song: syllables of a mumbling voice, like a grown-up in a cartoon.
	const babble = (seed, length) => {
		const random = seeded(seed);
		const notes = [];
		let time = 0.1;
		while (time < length - 0.2) {
			const syllable = 0.08 + (random() * 0.12);
			notes.push({time, duration: syllable, frequency: 140 + (random() * 120), instrument: 'babble', volume: 0.12});
			time += syllable + (random() < 0.15 ? 0.25 : 0.03);
		}

		return {notes, length};
	};

	const sound = {
		isOn: false,
		noise: undefined,
		context: undefined,
		output: undefined,
		// Starts with the audio of the element, which is `undefined` when the browser does not let it play yet.
		start(audio) {
			if (!audio) {
				return false;
			}

			try {
				this.context = audio.context;
				this.output = audio.output;
				this.context.resume();
				return true;
			} catch {
				return false;
			}
		},
	};

	// Plays a note of a song at a time of the audio clock, on a bus, at a speed: a slow Walkman plays lower and longer.
	const playNote = (note, when, bus, rate = 1) => {
		const {context} = sound;
		const start = Math.max(when, context.currentTime);
		const duration = note.duration / rate;
		const gain = new GainNode(context, {gain: 0});
		gain.connect(bus);
		if (note.instrument === 'kick') {
			const oscillator = new OscillatorNode(context, {type: 'sine', frequency: 150 * rate});
			oscillator.frequency.setValueAtTime(150 * rate, start);
			oscillator.frequency.exponentialRampToValueAtTime(45 * rate, start + duration);
			gain.gain.setValueAtTime(note.volume, start);
			gain.gain.exponentialRampToValueAtTime(0.001, start + duration);
			oscillator.connect(gain);
			oscillator.start(start);
			oscillator.stop(start + duration + 0.02);
			return;
		}

		if (note.instrument === 'snare' || note.instrument === 'hat') {
			sound.noise ??= (() => {
				const buffer = new AudioBuffer({length: context.sampleRate, sampleRate: context.sampleRate});
				const data = buffer.getChannelData(0);
				for (let index = 0; index < data.length; index++) {
					data[index] = (Math.random() * 2) - 1;
				}

				return buffer;
			})();
			const source = new AudioBufferSourceNode(context, {buffer: sound.noise, playbackRate: rate});
			const filter = new BiquadFilterNode(context, {type: note.instrument === 'hat' ? 'highpass' : 'bandpass', frequency: (note.instrument === 'hat' ? 7000 : 1800) * rate});
			gain.gain.setValueAtTime(note.volume, start);
			gain.gain.exponentialRampToValueAtTime(0.001, start + duration);
			source.connect(filter).connect(gain);
			source.start(start, Math.random() * 0.5);
			source.stop(start + duration + 0.02);
			return;
		}

		const isBabble = note.instrument === 'babble';
		const oscillator = new OscillatorNode(context, {type: isBabble ? 'sawtooth' : note.instrument, frequency: note.frequency * rate});
		let output = oscillator;
		if (isBabble) {
			// A voice is a buzz through the mouth, so the buzz goes through a filter that opens and closes like a mouth.
			const mouth = new BiquadFilterNode(context, {type: 'lowpass', frequency: 400, Q: 6});
			mouth.frequency.setValueAtTime(400, start);
			mouth.frequency.linearRampToValueAtTime(1100, start + (duration / 2));
			mouth.frequency.linearRampToValueAtTime(500, start + duration);
			oscillator.frequency.setValueAtTime(note.frequency * rate, start);
			oscillator.frequency.linearRampToValueAtTime(note.frequency * rate * 0.85, start + duration);
			output = oscillator.connect(mouth);
		}

		gain.gain.setValueAtTime(0, start);
		gain.gain.linearRampToValueAtTime(note.volume, start + 0.01);
		gain.gain.setValueAtTime(note.volume, start + Math.max(0.01, duration - 0.04));
		gain.gain.linearRampToValueAtTime(0, start + duration);
		output.connect(gain);
		oscillator.start(start);
		oscillator.stop(start + duration + 0.02);
	};

	// A player of a list of songs: a position in the song, which the music clock moves on, and the notes that are due, scheduled a moment ahead. A jump, like a skip, drops the notes already scheduled, by fading out their bus, and goes on from the new position.
	const makeSequencer = songs => {
		const sequencer = {
			songs,
			track: 0,
			position: 0,
			isPlaying: false,
			bus: undefined,
			scheduledUntil: 0,
			rate: 1,
			newBus() {
				if (this.bus) {
					const old = this.bus;
					old.gain.setTargetAtTime(0, sound.context.currentTime, 0.01);
					music.timeout(200, () => {
						old.disconnect();
					});
				}

				this.bus = sound.isOn ? new GainNode(sound.context, {gain: 0.8}) : undefined;
				this.bus?.connect(sound.output);
				this.scheduledUntil = this.position;
			},
			jump(position) {
				this.position = clamp(position, 0, this.songs[this.track].length);
				this.newBus();
			},
			// Moves on by real seconds, at the speed of the player, and schedules the notes of the next moment.
			advance(seconds) {
				if (!this.isPlaying) {
					return;
				}

				this.position += seconds * this.rate;
				if (!sound.isOn || !this.bus) {
					this.scheduledUntil = this.position;
					return;
				}

				const song = this.songs[this.track];
				const until = this.position + (0.25 * this.rate);
				for (const note of song.notes) {
					if (note.time >= this.scheduledUntil && note.time < until) {
						playNote(note, sound.context.currentTime + ((note.time - this.position) / this.rate), this.bus, this.rate);
					}
				}

				this.scheduledUntil = Math.max(this.scheduledUntil, until);
			},
			stop() {
				this.isPlaying = false;
				this.newBus();
			},
		};
		return sequencer;
	};

	const players = [];

	// The music clock: it moves the players on, ten times a second, while one plays and the tab is visible, also when the players have scrolled away, as music keeps playing.
	let clock;
	let lastTick;
	const runClock = () => {
		const shouldRun = players.some(player => player.isPlaying) && document.visibilityState === 'visible';
		if (shouldRun && !clock) {
			lastTick = performance.now();
			clock = music.interval(100, () => {
				const now = performance.now();
				const seconds = Math.min((now - lastTick) / 1000, 0.5);
				lastTick = now;
				for (const player of players) {
					player.tick(seconds);
				}
			});
		} else if (!shouldRun && clock) {
			clock.cancel();
			clock = undefined;
		}
	};

	music.on(document, 'visibilitychange', runClock);

	const pauseOthers = source => {
		for (const player of players) {
			if (player.source !== source && player.sequencer.isPlaying) {
				player.pause();
			}
		}
	};

	// Only one tune plays on the page at a time: a player says when it starts to play out loud, and stops when another player of the page does, like the jukebox. The Discman and the Walkman are two players, so one stops the other too: the page only tells the other toys, so the other player stops here, before the page hears of the new tune.
	const tellPage = (player, isPlaying) => {
		if (!isPlaying || sound.isOn) {
			if (isPlaying) {
				pauseOthers(player.source);
			}

			music.music(isPlaying);
		}
	};

	music.on(soundButton, 'click', () => {
		if (!sound.isOn && !sound.start(music.sound())) {
			music.say('Your browser has no headphone jack. (It cannot play sound.)', discmanStatus);
			return;
		}

		sound.isOn = !sound.isOn;
		setPressed(soundButton, sound.isOn);
		for (const player of players) {
			player.sequencer.newBus();
			if (player.sequencer.isPlaying) {
				tellPage(player, sound.isOn);
			}
		}

		music.say(sound.isOn ? 'Headphones on. Press Play on the Discman or the Walkman.' : 'Headphones off. Silence, except for a faint tsk-tsk.', discmanStatus);
	});

	// The Discman, from above: the silver body, the lid with the CD under it, the display, and the cable of the headphones.
	{
		const canvas = discmanCanvas;
		const context = canvas.getContext('2d');
		const status = discmanStatus;
		const espButton = music.querySelector('[data-discman-action="esp"]');
		const runButton = music.querySelector('[data-discman-action="run"]');
		const titles = ['Brunost Boogie', 'Rain in Bergen', 'Waffle Waltz', 'Dial-Up Disco', 'Unicorn Dreams'];
		const songs = [
			compose({seed: 17, tempo: 132, root: 60, scale: 'major', progression: [0, 3, 0, 4, 0, 3, 4, 0], style: 'boogie'}),
			compose({seed: 5, tempo: 84, root: 57, scale: 'minor', progression: [0, 5, 2, 6, 0, 5, 2, 6], style: 'rain', repeats: 2}),
			compose({seed: 1999, tempo: 150, root: 65, scale: 'major', progression: [0, 4, 4, 0, 3, 0, 4, 0], beatsPerBar: 3, style: 'waltz', repeats: 4}),
			compose({seed: 56, tempo: 120, root: 62, scale: 'minor', progression: [0, 0, 5, 6, 0, 0, 3, 4], style: 'disco'}),
			compose({seed: 42, tempo: 96, root: 63, scale: 'major', progression: [0, 5, 3, 4, 0, 5, 3, 4], style: 'dream', repeats: 2}),
		];
		const sequencer = makeSequencer(songs);

		const state = {
			hasESP: false,
			isRunning: false,
			buffer: 0,
			skipUntil: 0,
			shake: 0,
			shakeX: 0,
			shakeY: 0,
			angle: 0,
			lastRunBump: 0,
			skips: 0,
			skipTimers: [],
		};

		// A stop, a pause, or another track cancels the rest of a skip.
		const cancelSkip = () => {
			for (const timer of state.skipTimers) {
				timer.cancel();
			}

			state.skipTimers = [];
		};

		const format = seconds => `${Math.floor(seconds / 60)}:${String(Math.floor(seconds % 60)).padStart(2, '0')}`;

		const draw = () => {
			context.clearRect(0, 0, canvas.width, canvas.height);
			context.save();
			context.translate(state.shakeX, state.shakeY);
			// The body.
			const metal = context.createRadialGradient(100, 90, 20, 120, 120, 115);
			metal.addColorStop(0, '#f4f6fa');
			metal.addColorStop(0.7, '#c4c8d0');
			metal.addColorStop(1, '#8a8e98');
			fillEllipse(context, metal, 120, 120, 112, 112);
			fillEllipse(context, '#9aa0aa', 120, 112, 92, 92);
			fillEllipse(context, '#1a1a22', 120, 112, 88, 88);
			// The CD: a rainbow that turns, and my writing on it.
			context.save();
			context.translate(120, 112);
			context.rotate(state.angle);
			const disc = context.createConicGradient(0, 0, 0);
			for (const [stop, color] of [[0, '#e0e4ec'], [0.15, '#ffd0f0'], [0.3, '#c0f0ff'], [0.45, '#f0ffc0'], [0.6, '#e0e4ec'], [0.75, '#ffe0c0'], [0.9, '#d0d0ff'], [1, '#e0e4ec']]) {
				disc.addColorStop(stop, color);
			}

			fillEllipse(context, disc, 0, 0, 84, 84);
			context.fillStyle = '#1a3a9a';
			context.font = 'bold 13px "Comic Sans MS", "Chalkboard SE", cursive';
			context.textAlign = 'center';
			context.fillText('Sindre’s Mix ’99', 0, -42);
			context.font = '11px "Comic Sans MS", "Chalkboard SE", cursive';
			context.fillText('DO NOT TOUCH!!', 0, 52);
			fillEllipse(context, '#c8ccd4', 0, 0, 20, 20);
			fillEllipse(context, '#1a1a22', 0, 0, 8, 8);
			context.restore();
			// The see-through lid, and the display at the front.
			fillEllipse(context, 'rgba(255, 255, 255, 0.12)', 100, 80, 50, 30);
			context.fillStyle = '#9ab89a';
			context.beginPath();
			context.roundRect(70, 196, 100, 30, 6);
			context.fill();
			const track = String(sequencer.track + 1).padStart(2, '0');
			const isSkipping = performance.now() < state.skipUntil;
			drawPixelText(context, sequencer.isPlaying || sequencer.position > 0 ? `${track} ${format(sequencer.position)}` : `${track} --:--`, 120, 200, '#1a2a1a', {align: 'center', scale: 2});
			if (isSkipping) {
				drawPixelText(context, 'SKIP!', 120, 214, '#aa0000', {align: 'center', scale: 2});
			} else if (state.hasESP) {
				drawPixelText(context, 'ESP', 78, 216, '#1a2a1a');
				fillShape(context, '#4a5a4a', 94, 216, 70, 5);
				fillShape(context, '#1a2a1a', 94, 216, 70 * (state.buffer / 10), 5);
			}

			// The cable of the headphones, and a faint tsk-tsk while nobody wears them.
			fillShape(context, '#222222', 222, 140, 14, 6);
			context.strokeStyle = '#222222';
			context.lineWidth = 2;
			context.beginPath();
			context.moveTo(236, 143);
			context.quadraticCurveTo(250, 180, 232, 236);
			context.stroke();
			if (sequencer.isPlaying && !sound.isOn && (music.reducedMotion || Math.floor(performance.now() / 300) % 2 === 0)) {
				drawPixelText(context, 'TSK', 200, 158, '#555555');
			}

			context.restore();
		};

		const say = text => {
			music.say(text, status);
		};

		// A shock: with ESP, the buffer covers for it while it has music; without ESP, or with an empty buffer, the laser loses its track, and the music skips.
		const shock = amount => {
			state.shake = Math.min(state.shake + amount, 1.5);
			if (!sequencer.isPlaying) {
				return;
			}

			if (state.hasESP && state.buffer > 0) {
				state.buffer = Math.max(0, state.buffer - (amount * 1.6));
				return;
			}

			if (amount < 0.4 || performance.now() < state.skipUntil) {
				return;
			}

			state.skips++;
			state.skipUntil = performance.now() + 450;
			// The skip stutters: the same bit of music twice, then a jump ahead.
			const from = sequencer.position;
			cancelSkip();
			sequencer.jump(from - 0.2);
			state.skipTimers = [
				music.timeout(150, () => {
					sequencer.jump(from - 0.2);
				}),
				music.timeout(300, () => {
					sequencer.jump(from + 0.6 + (Math.random() * 1.2));
				}),
			];
			if (state.skips === 1 || state.skips % 8 === 0) {
				say(state.hasESP ? 'SKIP! The ESP buffer was empty. It can only do 10 seconds.' : 'SKIP! A Discman does not like to be shaken. Turn on the ESP!');
			}

			loop.start();
		};

		const player = {
			source: 'discman',
			sequencer,
			get isPlaying() {
				return sequencer.isPlaying;
			},
			pause() {
				actions.play();
			},
			tick(seconds) {
				if (!sequencer.isPlaying) {
					return;
				}

				// The ESP reads the CD faster than it plays, so the buffer fills while the Discman is still.
				if (state.hasESP && state.shake < 0.2) {
					state.buffer = Math.min(10, state.buffer + (seconds * 1.5));
				}

				// On a run, the Discman bumps with every step.
				if (state.isRunning && performance.now() - state.lastRunBump > 380) {
					state.lastRunBump = performance.now();
					shock(0.75);
				}

				sequencer.advance(seconds);
				if (sequencer.position >= songs[sequencer.track].length) {
					changeTrack(1);
				}
			},
		};
		players.push(player);

		const changeTrack = direction => {
			cancelSkip();
			sequencer.track = (sequencer.track + direction + songs.length) % songs.length;
			sequencer.jump(0);
			say(`Track ${sequencer.track + 1}: “${titles[sequencer.track]}”.`);
			loop.start();
		};

		// The CD turns, the Discman shakes, and the display shows the time, while it plays or shakes. With reduced motion, the CD and the body stand still.
		const step = seconds => {
			if (sequencer.isPlaying && !music.reducedMotion) {
				state.angle += seconds * 8;
			}

			state.shake = Math.max(0, state.shake - (seconds * 2.5));
			const amount = music.reducedMotion ? 0 : state.shake * 6;
			state.shakeX = (Math.random() - 0.5) * amount;
			state.shakeY = (Math.random() - 0.5) * amount;
			draw();
		};

		// When it stops, it draws once more, so “SKIP!” goes away from the display.
		const loop = music.loop(step, {while: () => sequencer.isPlaying || state.shake > 0 || performance.now() < state.skipUntil, target: canvas, stopped: draw});

		const actions = {
			play() {
				cancelSkip();
				sequencer.isPlaying = !sequencer.isPlaying;
				if (sequencer.isPlaying) {
					sequencer.newBus();
					say(`▶ Track ${sequencer.track + 1}: “${titles[sequencer.track]}”.${sound.isOn ? '' : ' Put on the headphones to hear it. For now, they only leak a faint tsk-tsk.'}`);
				} else {
					sequencer.stop();
					say('Paused.');
				}

				tellPage(player, sequencer.isPlaying);
				runClock();
				loop.start();
				draw();
			},
			stop() {
				cancelSkip();
				sequencer.stop();
				sequencer.position = 0;
				state.buffer = 0;
				tellPage(player, false);
				runClock();
				say('Stopped.');
				draw();
			},
			previous() {
				changeTrack(sequencer.position > 3 ? 0 : -1);
				draw();
			},
			next() {
				changeTrack(1);
				draw();
			},
			esp() {
				state.hasESP = !state.hasESP;
				setPressed(espButton, state.hasESP);
				state.buffer = 0;
				say(state.hasESP ? 'ESP on: Electronic Skip Protection. It fills a buffer with 10 seconds of music, so a bump does not skip.' : 'ESP off. Hold it very still.');
				draw();
			},
			run() {
				state.isRunning = !state.isRunning;
				setPressed(runButton, state.isRunning);
				say(state.isRunning ? 'Running with the Discman! Bump, bump, bump.' : 'Stopped running. Out of breath.');
				loop.start();
			},
		};

		for (const button of music.querySelectorAll('[data-discman-action]')) {
			music.on(button, 'click', () => {
				actions[button.dataset.discmanAction]();
			});
		}

		// Dragging the Discman around shakes it: the faster it moves, the bigger the bump.
		let lastPoint;
		music.on(canvas, 'pointerdown', event => {
			if (event.button !== 0) {
				return;
			}

			canvas.setPointerCapture(event.pointerId);
			lastPoint = {x: event.clientX, y: event.clientY, time: event.timeStamp};
		});

		music.on(canvas, 'pointermove', event => {
			if (!lastPoint) {
				return;
			}

			const distance = Math.hypot(event.clientX - lastPoint.x, event.clientY - lastPoint.y);
			const time = Math.max(event.timeStamp - lastPoint.time, 8);
			lastPoint = {x: event.clientX, y: event.clientY, time: event.timeStamp};
			const speed = distance / time;
			if (speed > 0.4) {
				shock(Math.min(speed / 2, 1.2));
				loop.start();
			}
		});

		const endDrag = () => {
			lastPoint = undefined;
		};

		music.on(canvas, 'pointerup', endDrag);
		music.on(canvas, 'pointercancel', endDrag);
		music.on(canvas, 'lostpointercapture', endDrag);

		music.on(canvas, 'keydown', event => {
			if (event.key.startsWith('Arrow')) {
				event.preventDefault();
				shock(0.8);
				loop.start();
			} else if (event.key === ' ' || event.key === 'Enter') {
				event.preventDefault();
				actions.play();
			}
		});

		draw();
	}

	// The Walkman, with a mixtape I taped off the radio, where the DJ talks over the start of every song. The tape starts as tape salad: a pencil in the reel, turned around and around, winds it back in. Playing and rewinding use the batteries, and the tape slows down, and sounds lower, as they die.
	{
		const canvas = walkmanCanvas;
		const context = canvas.getContext('2d');
		const status = walkmanStatus;
		const pencilButton = music.querySelector('[data-walkman-action="pencil"]');
		const turnsNeeded = 6;
		const parts = [
			{title: 'the DJ, talking over the start', song: babble(3, 4)},
			{title: '“Summer Hit ’99”, taped off the radio', song: compose({seed: 9, tempo: 124, root: 67, scale: 'major', progression: [0, 4, 5, 3], style: 'pop', repeats: 4})},
			{title: 'the DJ again: “That was the summer hit! And now the news…”', song: babble(8, 3)},
			{title: '“Eurodance Thing”, with the start cut off', song: compose({seed: 77, tempo: 136, root: 57, scale: 'minor', progression: [0, 5, 2, 6], style: 'disco', repeats: 4})},
			{title: 'the DJ, saying goodbye', song: babble(21, 3)},
		];

		// The tape is one long song, made of the parts one after the other.
		const tape = {notes: [], length: 0, starts: []};
		for (const part of parts) {
			tape.starts.push(tape.length);
			for (const note of part.song.notes) {
				tape.notes.push({...note, time: note.time + tape.length});
			}

			tape.length += part.song.length;
		}

		const sequencer = makeSequencer([tape]);
		const state = {
			isSalad: true,
			hasPencil: false,
			turns: 0,
			pencilAngle: 0,
			lastAngle: undefined,
			battery: 0.35,
			isRewinding: false,
			reelAngle: 0,
			partIndex: -1,
			remoteRaids: 0,
		};

		const reelLeft = {x: 98, y: 92};
		const reelRight = {x: 182, y: 92};

		const draw = () => {
			context.clearRect(0, 0, canvas.width, canvas.height);
			// The body of the Walkman, in sporty yellow, with the window of the cassette.
			context.fillStyle = '#f2c230';
			context.beginPath();
			context.roundRect(10, 10, 260, 180, 18);
			context.fill();
			fillShape(context, '#3a3a40', 30, 30, 220, 120);
			fillShape(context, '#c8c0b0', 40, 40, 200, 100);
			fillShape(context, '#e84040', 40, 52, 200, 10);
			drawPixelText(context, 'MIXTAPE SUMMER 99', 140, 44, '#222222', {align: 'center'});
			fillShape(context, '#5a5048', 70, 74, 140, 36);
			const progress = sequencer.position / tape.length;
			for (const [reel, amount] of [[reelLeft, 1 - progress], [reelRight, progress]]) {
				fillEllipse(context, '#3a2a1a', reel.x, reel.y, 10 + (amount * 16), 10 + (amount * 16));
				fillEllipse(context, '#f4f0e8', reel.x, reel.y, 9, 9);
				context.save();
				context.translate(reel.x, reel.y);
				context.rotate(state.reelAngle);
				for (let tooth = 0; tooth < 6; tooth++) {
					context.rotate(Math.PI / 3);
					fillShape(context, '#3a3a40', -1, -8, 2, 4);
				}

				context.restore();
			}

			// Tape salad: loops of brown tape out of the bottom of the cassette, fewer for each turn of the pencil.
			if (state.isSalad) {
				const loops = Math.ceil((turnsNeeded - state.turns) / 2);
				context.strokeStyle = '#5a3a1a';
				context.lineWidth = 2;
				for (let index = 0; index < loops; index++) {
					context.beginPath();
					const x = 90 + (index * 28);
					context.moveTo(x, 138);
					context.bezierCurveTo(x - 30, 175 + (index * 3), x + 50, 185, x + 20, 140);
					context.stroke();
				}
			}

			// The pencil in the left reel, which turns with the drag.
			if (state.hasPencil) {
				context.save();
				context.translate(reelLeft.x, reelLeft.y);
				context.rotate(state.pencilAngle);
				fillShape(context, '#f2c230', -3, -60, 6, 52);
				fillShape(context, '#e89aa0', -3, -66, 6, 6);
				fillShape(context, '#c0c0c0', -3, -68, 6, 3);
				fillPolygon(context, '#e8c89a', [[-3, -8], [3, -8], [0, 2]]);
				context.restore();
			}

			// The battery meter and the counter of the tape.
			fillShape(context, '#222222', 196, 160, 52, 14);
			fillShape(context, state.battery > 0.25 ? '#44dd44' : '#dd4444', 198, 162, 48 * state.battery, 10);
			fillShape(context, '#222222', 248, 164, 3, 6);
			drawPixelText(context, String(Math.floor(sequencer.position * 4)).padStart(3, '0'), 40, 162, '#222222', {scale: 2});
			if (sequencer.isPlaying && !sound.isOn && (music.reducedMotion || Math.floor(performance.now() / 300) % 2 === 0)) {
				drawPixelText(context, 'TSK TSK', 90, 166, '#7a5a10');
			}
		};

		const say = text => {
			music.say(text, status);
		};

		const player = {
			source: 'walkman',
			sequencer,
			get isPlaying() {
				return sequencer.isPlaying || state.isRewinding;
			},
			pause() {
				actions.stop();
			},
			tick(seconds) {
				if (state.isRewinding) {
					state.battery = Math.max(0, state.battery - (seconds * 0.03));
					sequencer.position = Math.max(0, sequencer.position - (seconds * 8));
					if (sequencer.position === 0 || state.battery === 0) {
						state.isRewinding = false;
						runClock();
						say(state.battery === 0 ? 'The batteries died while it rewound. That is why we use a pencil.' : 'Rewound. Clunk!');
					}

					return;
				}

				if (!sequencer.isPlaying) {
					return;
				}

				// Weak batteries turn the tape slower, so the music goes slow and low, and wobbles a little.
				state.battery = Math.max(0, state.battery - (seconds * 0.006));
				sequencer.rate = state.battery > 0.3 ? 1 : 0.55 + (state.battery * 1.5) + (Math.sin(performance.now() / 300) * 0.02);
				sequencer.advance(seconds);
				const part = tape.starts.findLastIndex(start => sequencer.position >= start);
				if (part !== state.partIndex) {
					state.partIndex = part;
					say(`♪ Now: ${parts[part].title}.`);
				}

				if (state.battery === 0) {
					sequencer.stop();
					tellPage(player, false);
					// A dying Walkman likes to eat the tape.
					if (Math.random() < 0.5) {
						state.isSalad = true;
						state.turns = 0;
						state.pencilAngle = 0;
						say('The batteries died, and the Walkman ate the tape! Tape salad again. Get the pencil.');
					} else {
						say('The batteries are dead. The music went slower and lower, and stopped.');
					}

					runClock();
				} else if (sequencer.position >= tape.length) {
					sequencer.stop();
					tellPage(player, false);
					runClock();
					say('Clunk. End of side A. Rewind it, or turn it over (side B is empty).');
				}
			},
		};
		players.push(player);

		const step = seconds => {
			if (!music.reducedMotion && (sequencer.isPlaying || state.isRewinding)) {
				state.reelAngle += seconds * (state.isRewinding ? -12 : 3 * sequencer.rate);
			}

			draw();
		};

		// The clock stops the tape between frames, like when the batteries die, so it draws once more when it stops.
		const loop = music.loop(step, {while: () => sequencer.isPlaying || state.isRewinding, target: canvas, stopped: draw});

		// One turn of the pencil, from the drag or a key. The tape winds in after enough turns.
		const turnPencil = angle => {
			state.pencilAngle += angle;
			const turns = Math.floor(Math.abs(state.pencilAngle) / (Math.PI * 2));
			if (turns > state.turns && state.isSalad) {
				state.turns = turns;
				if (state.turns >= turnsNeeded) {
					state.isSalad = false;
					say('The tape is back in the cassette! Press Play. Pencils: the best tool of the 1990s.');
				} else {
					say(`Turn ${state.turns} of ${turnsNeeded}. Keep winding!`);
				}
			} else if (!state.isSalad && turns > state.turns) {
				// With the tape in, the pencil rewinds it, without batteries.
				state.turns = turns;
				sequencer.jump(Math.max(0, sequencer.position - 3));
			}

			draw();
		};

		const actions = {
			pencil() {
				state.hasPencil = !state.hasPencil;
				setPressed(pencilButton, state.hasPencil);
				say(state.hasPencil ? 'The pencil is in the reel. Drag around it in circles, or press the arrow keys, to wind the tape.' : 'Pencil out.');
				canvas.focus();
				draw();
			},
			play() {
				if (state.isSalad) {
					say('It does not play: the tape is all over the place. Stick a pencil in and wind it back.');
					return;
				}

				if (state.battery === 0) {
					say('The batteries are dead. Take the ones from the TV remote. Dad will never know.');
					return;
				}

				state.isRewinding = false;
				sequencer.isPlaying = true;
				sequencer.newBus();
				state.partIndex = -1;
				if (!sound.isOn) {
					say('▶ Playing. Put on the headphones to hear it. For now, they only leak a faint tsk-tsk.');
				}

				tellPage(player, true);
				runClock();
				loop.start();
			},
			stop() {
				sequencer.stop();
				state.isRewinding = false;
				tellPage(player, false);
				runClock();
				say('Stopped.');
				draw();
			},
			rewind() {
				if (state.isSalad) {
					say('Rewinding tape salad makes it worse. Use the pencil.');
					return;
				}

				if (sequencer.position === 0) {
					say('It is already at the start.');
					return;
				}

				if (state.battery === 0) {
					say('The batteries are dead. Rewind it with the pencil, like a pro.');
					return;
				}

				sequencer.stop();
				tellPage(player, false);
				state.isRewinding = true;
				say('Rewinding… It eats the batteries.');
				runClock();
				loop.start();
			},
			batteries() {
				state.battery = 1;
				state.remoteRaids++;
				sequencer.rate = 1;
				say(state.remoteRaids > 1 ? 'New batteries from the remote. From downstairs: “WHO TOOK THE BATTERIES FROM THE REMOTE AGAIN?”' : 'Fresh batteries, from the TV remote. Dad will not notice until the news.');
				draw();
			},
		};

		for (const button of music.querySelectorAll('[data-walkman-action]')) {
			music.on(button, 'click', () => {
				actions[button.dataset.walkmanAction]();
			});
		}

		// The angle of the pointer around the left reel: going around it turns the pencil.
		music.on(canvas, 'pointerdown', event => {
			if (event.button !== 0) {
				return;
			}

			if (!state.hasPencil) {
				say('Stick a pencil in first.');
				return;
			}

			canvas.setPointerCapture(event.pointerId);
			const point = canvasPoint(canvas, event);
			state.lastAngle = Math.atan2(point.y - reelLeft.y, point.x - reelLeft.x);
		});

		music.on(canvas, 'pointermove', event => {
			if (state.lastAngle === undefined) {
				return;
			}

			const point = canvasPoint(canvas, event);
			const angle = Math.atan2(point.y - reelLeft.y, point.x - reelLeft.x);
			let delta = angle - state.lastAngle;
			delta = ((delta + Math.PI) % (Math.PI * 2) + (Math.PI * 2)) % (Math.PI * 2) - Math.PI;
			state.lastAngle = angle;
			turnPencil(delta);
		});

		const endDrag = () => {
			state.lastAngle = undefined;
		};

		music.on(canvas, 'pointerup', endDrag);
		music.on(canvas, 'pointercancel', endDrag);
		music.on(canvas, 'lostpointercapture', endDrag);

		music.on(canvas, 'keydown', event => {
			if (event.key.startsWith('Arrow')) {
				event.preventDefault();
				if (state.hasPencil) {
					turnPencil(Math.PI / 2);
				} else {
					say('Stick a pencil in first.');
				}
			}
		});

		draw();
	}

	// Another toy of the page started a tune.
	return () => {
		pauseOthers();
	};
};

export default class extends GeoCitiesElement {
	#pause;

	connected() {
		this.#pause = setUp(this, this.parts);
	}

	musicStopped() {
		this.#pause();
	}
}
