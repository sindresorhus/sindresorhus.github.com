// The intro of TEAM WAFFLE on the 1999 page: a cracktro in seven parts, drawn pixel by pixel in a canvas of 320 × 200 with big square pixels, like the demos of the 1990s, with a sine scroller that the visitor can rewrite, a remote control, and a chiptune. It runs only while its screen is on the screen and the tab is visible. For visitors who prefer reduced motion, each part shows a still picture that changes only when the visitor does something. The music plays only after the visitor presses the button that says it plays music.
//
// The scroller thanks the visitor who registered the page with the serial of the keygen (`Keygen.js`), which sends the name with the `geocities-registration` event.

const clamp = (value, minimum, maximum) => Math.min(Math.max(value, minimum), maximum);
const wrap = (value, size) => ((value % size) + size) % size;

// MARK: Pixels and colors

// A color as the four bytes of a pixel in an `ImageData`, which is red first on the little-endian computers that run browsers.
const rgb = (red, green, blue) => ((255 << 24) | (clamp(Math.round(blue), 0, 255) << 16) | (clamp(Math.round(green), 0, 255) << 8) | clamp(Math.round(red), 0, 255)) >>> 0;

const channels = color => [color & 255, (color >> 8) & 255, (color >> 16) & 255];

const scaleColor = (color, factor) => {
	const [red, green, blue] = channels(color);
	return rgb(red * factor, green * factor, blue * factor);
};

const cssColor = color => {
	const [red, green, blue] = channels(color);
	return `rgb(${red} ${green} ${blue})`;
};

/**
A palette of 256 colors that goes smoothly through the colors, like the palettes of VGA mode 13h.
*/
const makePalette = stops => {
	const palette = new Uint32Array(256);

	for (let index = 0; index < 256; index++) {
		const position = (index / 256) * (stops.length - 1);
		const from = stops[Math.floor(position)];
		const to = stops[Math.min(Math.floor(position) + 1, stops.length - 1)];
		const amount = position - Math.floor(position);
		palette[index] = rgb(...from.map((value, channel) => value + ((to[channel] - value) * amount)));
	}

	return palette;
};

// The palettes of the intro. Each starts and ends with the same color, so the colors can go around and around. The Effect Toy Box (`EffectToys.js`) has the same.
const palettes = [
	{name: 'AMIGA', palette: makePalette([[0, 0, 60], [60, 0, 160], [220, 0, 170], [255, 140, 210], [255, 255, 255], [120, 210, 255], [0, 70, 180], [0, 0, 60]])},
	{name: 'ACID', palette: makePalette([[0, 30, 0], [0, 200, 40], [230, 255, 0], [255, 0, 200], [80, 0, 120], [0, 30, 0]])},
	{name: 'FIRE', palette: makePalette([[20, 0, 0], [170, 0, 0], [255, 120, 0], [255, 230, 60], [255, 255, 220], [255, 140, 0], [20, 0, 0]])},
	{name: 'C64', palette: makePalette([[53, 40, 121], [108, 94, 181], [112, 164, 178], [154, 210, 132], [184, 199, 111], [111, 79, 37], [53, 40, 121]])},
	{name: 'RAINBOW', palette: makePalette([[255, 0, 0], [255, 200, 0], [0, 255, 0], [0, 200, 255], [120, 0, 255], [255, 0, 160], [255, 0, 0]])},
];

const firePalette = makePalette([[0, 0, 0], [80, 0, 0], [200, 30, 0], [255, 120, 0], [255, 210, 40], [255, 255, 180], [255, 255, 255]]);

/**
A canvas that is drawn pixel by pixel, with the pixels as one number each.
*/
const pixelSurface = canvas => {
	const context = canvas.getContext('2d');
	const image = context.createImageData(canvas.width, canvas.height);

	return {
		context,
		width: canvas.width,
		height: canvas.height,
		pixels: new Uint32Array(image.data.buffer),
		show() {
			context.putImageData(image, 0, 0);
		},
	};
};

// The pixels of a canvas that is drawn with the drawing functions of the browser, like text, as numbers.
const canvasPixels = canvas => new Uint32Array(canvas.getContext('2d').getImageData(0, 0, canvas.width, canvas.height).data.buffer);

const makeCanvas = (width, height) => {
	const canvas = document.createElement('canvas');
	canvas.width = width;
	canvas.height = height;
	return canvas;
};

// A sine from a table, which is much faster for the effects that need one for every pixel. The angle is in steps of 1/1024 of a turn.
const sineTable = Float32Array.from({length: 1024}, (_, index) => Math.sin((index / 1024) * Math.PI * 2));
const fastSine = steps => sineTable[steps & 1023];

const loadImage = source => new Promise(resolve => {
	const image = new Image();
	image.addEventListener('load', () => {
		resolve(image);
	});
	image.addEventListener('error', () => {
		resolve(undefined);
	});
	image.src = source;
});

// MARK: The animation

/**
Runs `step(delta)` on each frame while the canvas is on the screen, the tab is visible, and motion is allowed, with a loop of the element. The first picture is drawn with `step(0)` when the canvas first shows, also when nothing moves. The returned controls pause it, `poke(delta)` draws one more frame when nothing runs by itself, like when the visitor prefers reduced motion and does something, and `drawStill()` draws a still picture when the motion changes.
*/
const animate = (element, canvas, step) => {
	let isPaused = false;
	let hasDrawn = false;

	// A step of 0 seconds draws a still picture, like the vector balls that jump to their shape, so the first step of a run moves like a frame.
	const loop = element.loop(seconds => {
		step(seconds || (1 / 60));
	}, {target: canvas, maximumStep: 0.05, while: () => !isPaused && !element.reducedMotion});

	const visibility = element.watchVisibility(canvas, isVisible => {
		if (isVisible && !hasDrawn) {
			hasDrawn = true;
			step(0);
		}
	});

	const isRunning = () => visibility.isVisible && !isPaused && !element.reducedMotion;

	return {
		setPaused(value) {
			isPaused = value;
			loop.start();
		},
		poke(delta = 0) {
			if (!isRunning()) {
				step(delta);
			}
		},
		drawStill() {
			if (visibility.isVisible) {
				step(0);
			}
		},
	};
};

// MARK: The music

// A chip with four channels, like the music of the demos and the keygens, made with the Web Audio API: a square lead, a thin square that plays a chord as a fast arpeggio, a triangle bass, and drums of noise. It starts only when the visitor presses the button that plays music. The keygen (`Keygen.js`) has the same chip, with its own song.
let noiseBuffer;

// One second of white noise for the drums.
const makeNoise = context => {
	const buffer = context.createBuffer(1, context.sampleRate, context.sampleRate);
	const samples = buffer.getChannelData(0);

	for (let index = 0; index < samples.length; index++) {
		samples[index] = (Math.random() * 2) - 1;
	}

	return buffer;
};

const noteFrequency = note => 440 * (2 ** ((note - 69) / 12));

// A square wave with a pulse of 12.5%, the thin and nasal sound of the arpeggios of keygen music.
let thinPulse;

const thinPulseWave = context => {
	if (!thinPulse) {
		const harmonics = 32;
		const real = new Float32Array(harmonics);
		const imaginary = new Float32Array(harmonics);

		for (let harmonic = 1; harmonic < harmonics; harmonic++) {
			imaginary[harmonic] = (2 / (harmonic * Math.PI)) * Math.sin(harmonic * Math.PI * 0.125);
		}

		thinPulse = context.createPeriodicWave(real, imaginary);
	}

	return thinPulse;
};

// The chords of the arpeggios: a major chord on C, E, F, and G, and a minor chord on the other notes, which fits the songs in A minor.
const chordSteps = note => [0, 4, 5, 7].includes(note % 12) ? [0, 4, 7, 12] : [0, 3, 7, 12];

// The drums by the key: C is the kick, D is the snare, and the other keys are hi-hats.
const drumOf = note => {
	const semitone = note % 12;

	if (semitone <= 1) {
		return 'kick';
	}

	if (semitone <= 4) {
		return 'snare';
	}

	return 'hat';
};

const envelope = (gain, time, peak, duration) => {
	gain.gain.setValueAtTime(0.0001, time);
	gain.gain.exponentialRampToValueAtTime(peak, time + 0.005);
	gain.gain.exponentialRampToValueAtTime(peak * 0.6, time + Math.max(0.01, Math.min(0.1, duration)));
	gain.gain.setValueAtTime(peak * 0.6, time + Math.max(0.01, duration));
	gain.gain.exponentialRampToValueAtTime(0.0001, time + duration + 0.04);
};

const playOscillator = (output, {type, wave, frequencies, time, duration, peak}) => {
	const {context} = output;
	const oscillator = context.createOscillator();
	const gain = context.createGain();

	if (wave) {
		oscillator.setPeriodicWave(wave);
	} else {
		oscillator.type = type;
	}

	// An arpeggio changes the note 50 times a second, like the effect 0xy of the trackers.
	for (let index = 0; index * 0.02 < duration; index++) {
		oscillator.frequency.setValueAtTime(frequencies[index % frequencies.length], time + (index * 0.02));
	}

	envelope(gain, time, peak, duration);
	oscillator.connect(gain).connect(output);
	oscillator.start(time);
	oscillator.stop(time + duration + 0.05);
};

const playNoise = (output, {time, duration, peak, filter, frequency}) => {
	const {context} = output;
	const source = context.createBufferSource();
	source.buffer = noiseBuffer;
	const filterNode = context.createBiquadFilter();
	filterNode.type = filter;
	filterNode.frequency.value = frequency;
	const gain = context.createGain();
	gain.gain.setValueAtTime(peak, time);
	gain.gain.exponentialRampToValueAtTime(0.0001, time + duration);
	source.connect(filterNode).connect(gain).connect(output);
	source.start(time, Math.random() * 0.5);
	source.stop(time + duration);
};

const instruments = [
	// The lead.
	(output, note, time, duration) => {
		playOscillator(output, {type: 'square', frequencies: [noteFrequency(note)], time, duration, peak: 0.1});
	},
	// The arpeggio.
	(output, note, time, duration) => {
		playOscillator(output, {wave: thinPulseWave(output.context), frequencies: chordSteps(note).map(step => noteFrequency(note + step)), time, duration, peak: 0.09});
	},
	// The bass.
	(output, note, time, duration) => {
		playOscillator(output, {type: 'triangle', frequencies: [noteFrequency(note)], time, duration, peak: 0.35});
	},
	// The drums.
	(output, note, time) => {
		const drum = drumOf(note);

		if (drum === 'kick') {
			const {context} = output;
			const oscillator = context.createOscillator();
			const gain = context.createGain();
			oscillator.frequency.setValueAtTime(160, time);
			oscillator.frequency.exponentialRampToValueAtTime(40, time + 0.12);
			gain.gain.setValueAtTime(0.6, time);
			gain.gain.exponentialRampToValueAtTime(0.0001, time + 0.2);
			oscillator.connect(gain).connect(output);
			oscillator.start(time);
			oscillator.stop(time + 0.2);
		} else if (drum === 'snare') {
			playNoise(output, {time, duration: 0.16, peak: 0.3, filter: 'bandpass', frequency: 1800});
		} else {
			playNoise(output, {time, duration: 0.04, peak: 0.12, filter: 'highpass', frequency: 7000});
		}
	},
];

// A note as the trackers write it, like `C-4` or `F#5`, or a drum by its name.
const noteNames = ['C-', 'C#', 'D-', 'D#', 'E-', 'F-', 'F#', 'G-', 'G#', 'A-', 'A#', 'B-'];

const parseNote = token => {
	if (token === '---') {
		return null;
	}

	const drum = {KCK: 36, SNR: 38, HAT: 42}[token];

	if (drum) {
		return drum;
	}

	return noteNames.indexOf(token.slice(0, 2)) + ((Number(token[2]) + 1) * 12);
};

// A pattern of 16 rows, written as one line of 16 notes for each of the four channels, like in a tracker.
const pattern = (...lines) => lines.map(line => line.trim().split(/\s+/).map(token => parseNote(token)));

const anthem = pattern(
	'A-5 --- E-5 A-5 C-6 --- A-5 F-5 G-5 --- E-5 C-6 B-5 D-6 G-5 B-5',
	'A-4 --- --- --- F-4 --- --- --- C-5 --- --- --- G-4 --- --- ---',
	'A-2 --- A-3 --- F-2 --- F-3 --- C-3 --- C-4 --- G-2 --- G-3 ---',
	'KCK --- HAT --- SNR --- HAT --- KCK KCK HAT --- SNR --- HAT SNR',
);

const groove = pattern(
	'E-5 --- --- D-5 C-5 --- D-5 --- E-5 --- G-5 E-5 D-5 --- B-4 ---',
	'A-4 --- --- --- --- --- --- --- G-4 --- --- --- E-4 --- --- ---',
	'A-2 --- --- A-2 --- --- A-2 --- G-2 --- --- G-2 E-2 --- E-3 ---',
	'KCK --- HAT --- SNR --- HAT KCK KCK --- HAT --- SNR --- HAT HAT',
);

// The song of the intro, as patterns in order, composed by me in FastTracker 2.
const song = {bpm: 125, patterns: [groove, groove, anthem, anthem]};

// How long a note plays: until the next note of its channel, but at most a beat, as the patterns have no note-off.
const noteRows = (channelNotes, row) => {
	for (let length = 1; length < 4; length++) {
		if (row + length >= channelNotes.length || channelNotes[row + length] !== null) {
			return length;
		}
	}

	return 4;
};

let currentPlayer;

/**
Plays the song in a loop with the audio of the element, until `stop()`.
*/
const playSong = (element, {context, output}) => {
	noiseBuffer ??= makeNoise(context);
	context.resume();

	const master = context.createGain();
	master.gain.value = 0.5;
	master.connect(output);

	const rowDuration = 60 / song.bpm / 4;
	let patternIndex = 0;
	let row = 0;
	let nextTime = context.currentTime + 0.06;

	// The notes are scheduled a little ahead, so the timers of the browser can be late without a hiccup in the music.
	const schedule = () => {
		while (nextTime < context.currentTime + 0.15) {
			for (const [channel, notes] of song.patterns[patternIndex].entries()) {
				const note = notes[row];

				if (note !== null) {
					instruments[channel](master, note, nextTime, noteRows(notes, row) * rowDuration * 0.95);
				}
			}

			row++;

			if (row === 16) {
				row = 0;
				patternIndex = (patternIndex + 1) % song.patterns.length;
			}

			nextTime += rowDuration;
		}
	};

	schedule();
	const timer = element.interval(25, schedule);

	const player = {
		stop() {
			timer.cancel();
			master.gain.setTargetAtTime(0, context.currentTime, 0.02);

			if (currentPlayer === player) {
				currentPlayer = undefined;
			}

			// After the fade, the audio device is freed until the next song, unless one started in the meantime. It is a plain timer, as it also frees it after the element was removed.
			setTimeout(() => {
				master.disconnect();

				if (!currentPlayer) {
					context.suspend();
				}
			}, 200);
		},
	};

	currentPlayer = player;
	return player;
};

// MARK: The intro

const width = 320;
const height = 200;
const black = rgb(0, 0, 0);
const speeds = [1, 2, 4, 8];

// The scroller, the logo, and the seven parts, drawn on the screen, and the remote control and the form of the scroller. It gives the class what it needs when the motion or the registration changes.
const setUpIntro = (cracktro, {screen, guru, part: partLabel, previous, next, faster, colors, pause, fullscreen, form, text: textInput, texture}) => {
	const surface = pixelSurface(screen);
	const {context, pixels} = surface;

	let speedIndex = 0;
	let paletteIndex = 0;
	let partIndex = 0;
	let partTime = 0;
	let time = 3;
	let flash = 0;
	let isPausedByVisitor = false;
	const palette = () => palettes[paletteIndex].palette;

	// MARK: The scroller

	const defaultText = 'TEAM WAFFLE PROUDLY PRESENTS SINDRE’S HOME PAGE 1999 ★ CRACKED, TRAINED, AND WAFFLED BY SINDRE ★ GREETINGS TO MAMMA, GLITTER, TROND, MORMOR, AND ALL ELITE WEB MASTERS ★ SPECIAL GREETINGS TO SPACEBALLS, FUTURE CREW, AND EVERYBODY IN VIKINGSKIPET ★ NO GREETINGS TO MY SISTER, WHO PICKED UP THE PHONE WHILE I DOWNLOADED A MOD ★ THIS INTRO IS 100% HANDMADE, WITH REAL PIXELS ★ SEE YOU AT THE GATHERING 2000 ★ ';
	let customText = cracktro.stored('scroller', '').slice(0, 140);

	// The name that the page is registered to. The keygen sends it when it starts, so this is only the name of a keygen that started before the intro.
	let registeredName = document.querySelector('geo-cities-keygen')?.registeredName;
	let strip;
	let scrollPosition = 220;
	const scrollFont = 'bold 18px Impact, "Arial Black", sans-serif';

	const scrollText = () => {
		const text = customText ? `${customText} ★ ${customText} ★ ` : defaultText;
		return registeredName ? `${text}THIS COPY IS REGISTERED TO ${registeredName.toUpperCase()} ★ THANK YOU FOR REGISTERING ★ ` : text;
	};

	// The text is drawn once in a long strip, and the scroller copies one column of it for each column of the screen, each a bit higher or lower, like the sine scrollers of the Amiga.
	const buildStrip = () => {
		const text = scrollText();
		const measure = makeCanvas(1, 1).getContext('2d');
		measure.font = scrollFont;
		const stripWidth = Math.min(Math.ceil(measure.measureText(text).width) + width, 16_000);
		const canvas = makeCanvas(stripWidth, 24);
		const stripContext = canvas.getContext('2d');
		stripContext.font = scrollFont;
		stripContext.textBaseline = 'top';
		stripContext.fillStyle = '#fff';
		stripContext.fillText(text, width, 2);
		strip = {pixels: canvasPixels(canvas), width: stripWidth, height: 24};
	};

	buildStrip();

	const scrollerPalette = palettes[4].palette;

	const drawScroller = (top, delta) => {
		scrollPosition = wrap(scrollPosition + (delta * 110), strip.width);
		const start = Math.floor(scrollPosition);
		const colorShift = Math.floor(time * 90);

		for (let x = 0; x < width; x++) {
			const sourceX = (start + x) % strip.width;
			const offset = Math.round(Math.sin((x * 0.03) + (time * 3)) * 10);

			for (let y = 0; y < strip.height; y++) {
				if ((strip.pixels[(y * strip.width) + sourceX] >>> 24) > 120) {
					const screenY = top + y + offset;

					if (screenY >= 0 && screenY < height) {
						pixels[(screenY * width) + x] = scrollerPalette[((y * 8) + x + colorShift) & 255];
					}
				}
			}
		}
	};

	// MARK: The logo

	const logo = (() => {
		const canvas = makeCanvas(width, 64);
		const logoContext = canvas.getContext('2d');
		logoContext.font = 'bold 50px Impact, "Arial Black", sans-serif';
		logoContext.textAlign = 'center';
		logoContext.textBaseline = 'middle';
		const chrome = logoContext.createLinearGradient(0, 8, 0, 56);
		chrome.addColorStop(0, '#ffffff');
		chrome.addColorStop(0.45, '#8fd3ff');
		chrome.addColorStop(0.5, '#1a2a6a');
		chrome.addColorStop(0.7, '#ffcc66');
		chrome.addColorStop(1, '#ffffff');
		logoContext.lineWidth = 4;
		logoContext.strokeStyle = '#000';
		logoContext.strokeText('TEAM WAFFLE', width / 2, 32);
		logoContext.fillStyle = chrome;
		logoContext.fillText('TEAM WAFFLE', width / 2, 32);
		return canvasPixels(canvas);
	})();

	// Each line of the logo is moved sideways by a sine, like the logos of the cracktros that wobble.
	const drawLogo = top => {
		for (let row = 0; row < 64; row++) {
			const offset = Math.round(Math.sin((row * 0.12) + (time * 3)) * 6);
			const screenRow = (top + row) * width;

			for (let x = 0; x < width; x++) {
				const sourceX = x - offset;

				if (sourceX >= 0 && sourceX < width) {
					const color = logo[(row * width) + sourceX];

					if ((color >>> 24) > 120) {
						pixels[screenRow + x] = (color | 0xFF_00_00_00) >>> 0;
					}
				}
			}
		}
	};

	// MARK: Part 1: copper bars and stars

	const stars = Array.from({length: 160}, () => ({x: (Math.random() * 2) - 1, y: (Math.random() * 2) - 1, z: Math.random()}));

	const drawStars = delta => {
		for (const star of stars) {
			star.z -= delta * 0.35;

			if (star.z <= 0.02) {
				star.x = (Math.random() * 2) - 1;
				star.y = (Math.random() * 2) - 1;
				star.z = 1;
			}

			const x = Math.round(160 + ((star.x / star.z) * 120));
			const y = Math.round(100 + ((star.y / star.z) * 120));

			if (x >= 0 && x < width - 1 && y >= 0 && y < height) {
				const brightness = (1 - star.z) * 255;
				pixels[(y * width) + x] = rgb(brightness, brightness, brightness);

				if (star.z < 0.3) {
					pixels[(y * width) + x + 1] = rgb(brightness, brightness, brightness);
				}
			}
		}
	};

	const drawCopper = delta => {
		pixels.fill(black);
		drawStars(delta);

		for (let bar = 0; bar < 7; bar++) {
			const center = 100 + (Math.sin((time * 1.6) + (bar * 0.45)) * 68);
			const color = palette()[((bar * 36) + 40) & 255];

			for (let offset = -7; offset <= 7; offset++) {
				const y = Math.round(center + offset);

				if (y >= 0 && y < height) {
					pixels.fill(scaleColor(color, 1 - (Math.abs(offset) / 8)), y * width, (y + 1) * width);
				}
			}
		}

		drawLogo(14);
		drawScroller(160, delta);
		surface.show();
	};

	// MARK: Part 2: plasma and a glenz vector

	const distanceTable = new Uint16Array(width * height);

	for (let y = 0; y < height; y++) {
		for (let x = 0; x < width; x++) {
			distanceTable[(y * width) + x] = Math.floor(Math.hypot(x - 160, y - 100) * 8);
		}
	}

	const cubeVertices = [[-1, -1, -1], [1, -1, -1], [1, 1, -1], [-1, 1, -1], [-1, -1, 1], [1, -1, 1], [1, 1, 1], [-1, 1, 1]];
	const cubeFaces = [[0, 1, 2, 3], [5, 4, 7, 6], [4, 0, 3, 7], [1, 5, 6, 2], [4, 5, 1, 0], [3, 2, 6, 7]];

	const rotate = ([x, y, z], angleX, angleY, angleZ) => {
		let [cos, sin] = [Math.cos(angleX), Math.sin(angleX)];
		[y, z] = [(y * cos) - (z * sin), (y * sin) + (z * cos)];
		[cos, sin] = [Math.cos(angleY), Math.sin(angleY)];
		[x, z] = [(x * cos) + (z * sin), (z * cos) - (x * sin)];
		[cos, sin] = [Math.cos(angleZ), Math.sin(angleZ)];
		[x, y] = [(x * cos) - (y * sin), (x * sin) + (y * cos)];
		return [x, y, z];
	};

	const drawPlasma = delta => {
		const colors = palette();
		const a = Math.floor(time * 60);
		const b = Math.floor(time * 45);
		const c = Math.floor(time * 30);
		const shift = Math.floor(time * 50);

		for (let y = 0, index = 0; y < height; y++) {
			for (let x = 0; x < width; x++, index++) {
				const value = fastSine((x * 6) + a) + fastSine((y * 7) - b) + fastSine(((x + y) * 4) + c) + fastSine(distanceTable[index] - (a * 2));
				pixels[index] = colors[(Math.floor(value * 32) + shift) & 255];
			}
		}

		drawScroller(168, delta);
		surface.show();

		// The glenz vector: a see-through cube with faces of two colors, like the cubes of the demos of 1993. The faces at the back are drawn first.
		const points = cubeVertices.map(vertex => {
			const [x, y, z] = rotate(vertex, time * 0.9, time * 0.7, time * 0.4);
			const scale = 260 / (z + 4.5);
			return [160 + (x * scale), 86 + (y * scale)];
		});

		const faces = cubeFaces.map(face => {
			const [p0, p1, p2] = face.map(index => points[index]);
			const area = ((p1[0] - p0[0]) * (p2[1] - p0[1])) - ((p1[1] - p0[1]) * (p2[0] - p0[0]));
			return {face, isFront: area < 0};
		});

		const glenzColor = cssColor(colors[200]);

		for (const isFront of [false, true]) {
			for (const {face} of faces.filter(item => item.isFront === isFront)) {
				const corners = face.map(index => points[index]);
				const center = [0, 0];

				for (const [x, y] of corners) {
					center[0] += x / 4;
					center[1] += y / 4;
				}

				for (let index = 0; index < 4; index++) {
					const next = corners[(index + 1) % 4];
					context.globalAlpha = isFront ? 0.55 : 0.3;
					context.fillStyle = index % 2 === 0 ? '#ffffff' : glenzColor;
					context.beginPath();
					context.moveTo(...center);
					context.lineTo(...corners[index]);
					context.lineTo(...next);
					context.closePath();
					context.fill();
				}
			}
		}

		context.globalAlpha = 1;
	};

	// MARK: Part 3: a tunnel of waffle

	const tunnelWidth = 480;
	const tunnelHeight = 300;
	let tunnel;

	// The tables of the tunnel are made the first time it shows, as they take a moment.
	const makeTunnel = () => {
		const angles = new Uint8Array(tunnelWidth * tunnelHeight);
		const depths = new Uint8Array(tunnelWidth * tunnelHeight);
		const shades = new Uint8Array(tunnelWidth * tunnelHeight);

		for (let y = 0, index = 0; y < tunnelHeight; y++) {
			for (let x = 0; x < tunnelWidth; x++, index++) {
				const dx = x - (tunnelWidth / 2);
				const dy = y - (tunnelHeight / 2);
				const distance = Math.max(Math.hypot(dx, dy), 1);
				angles[index] = Math.floor(((Math.atan2(dy, dx) / (Math.PI * 2)) + 0.5) * 128) & 63;
				depths[index] = Math.floor(2048 / distance) & 63;
				shades[index] = Math.min(15, Math.floor(distance / 9));
			}
		}

		// A waffle: golden ridges around darker squares, in 16 shades from dark to light.
		const waffle = new Uint32Array(64 * 64);

		for (let y = 0; y < 64; y++) {
			for (let x = 0; x < 64; x++) {
				const ridgeX = x % 16 < 4;
				const ridgeY = y % 16 < 4;
				const isRidge = ridgeX || ridgeY;
				const shine = isRidge ? 1.05 : 0.35 + (((x % 16) + (y % 16)) / 50);
				waffle[(y * 64) + x] = rgb(250 * shine, 180 * shine, 70 * shine);
			}
		}

		const shadedTextures = Array.from({length: 16}, (_, level) => waffle.map(color => scaleColor(color, level / 15)));
		return {angles, depths, shades, shadedTextures};
	};

	const drawTunnel = delta => {
		tunnel ??= makeTunnel();
		const offsetX = 80 + Math.round(Math.sin(time * 0.7) * 70);
		const offsetY = 50 + Math.round(Math.cos(time * 0.9) * 45);
		const shiftU = Math.floor(time * 12);
		const shiftV = Math.floor(time * 40);

		for (let y = 0, index = 0; y < height; y++) {
			let source = ((y + offsetY) * tunnelWidth) + offsetX;

			for (let x = 0; x < width; x++, index++, source++) {
				const u = (tunnel.angles[source] + shiftU) & 63;
				const v = (tunnel.depths[source] + shiftV) & 63;
				pixels[index] = tunnel.shadedTextures[tunnel.shades[source]][(v * 64) + u];
			}
		}

		drawScroller(168, delta);
		surface.show();
	};

	// MARK: Part 4: a rotozoomer of the unicorn

	const unicornTexture = new Uint32Array(64 * 64);

	// A checkerboard until the unicorn has loaded.
	for (let index = 0; index < unicornTexture.length; index++) {
		unicornTexture[index] = ((index >> 3) + (index >> 9)) % 2 === 0 ? rgb(255, 120, 200) : rgb(120, 60, 200);
	}

	const textureImage = texture.content.querySelector('img');

	if (textureImage) {
		loadImage(textureImage.src).then(image => {
			if (!image) {
				return;
			}

			const canvas = makeCanvas(64, 64);
			const textureContext = canvas.getContext('2d');
			const background = textureContext.createLinearGradient(0, 0, 64, 64);
			background.addColorStop(0, '#ff88cc');
			background.addColorStop(1, '#8844ff');
			textureContext.fillStyle = background;
			textureContext.fillRect(0, 0, 64, 64);
			const scale = Math.min(56 / image.naturalWidth, 56 / image.naturalHeight);
			textureContext.drawImage(image, (64 - (image.naturalWidth * scale)) / 2, (64 - (image.naturalHeight * scale)) / 2, image.naturalWidth * scale, image.naturalHeight * scale);
			unicornTexture.set(canvasPixels(canvas));
		});
	}

	const drawRotozoom = delta => {
		const angle = time * 0.5;
		const zoom = 0.3 + ((Math.sin(time * 0.6) + 1) * 0.6);
		const cos = Math.cos(angle) * zoom;
		const sin = Math.sin(angle) * zoom;
		const offset = time * 20;

		for (let y = 0, index = 0; y < height; y++) {
			let u = (-160 * cos) - ((y - 100) * sin) + offset;
			let v = (-160 * sin) + ((y - 100) * cos) + offset;

			for (let x = 0; x < width; x++, index++) {
				pixels[index] = unicornTexture[((v & 63) * 64) + (u & 63)];
				u += cos;
				v += sin;
			}
		}

		drawScroller(168, delta);
		surface.show();
	};

	// MARK: Part 5: vector balls

	const ballCount = 64;

	const shapes = [
		// A sphere.
		index => {
			const y = 1 - ((index / (ballCount - 1)) * 2);
			const radius = Math.sqrt(1 - (y * y));
			const angle = index * 2.399_96;
			return [Math.cos(angle) * radius, y, Math.sin(angle) * radius];
		},
		// A cube of 4 × 4 × 4.
		index => [((index % 4) / 1.5) - 1, ((Math.floor(index / 4) % 4) / 1.5) - 1, ((Math.floor(index / 16)) / 1.5) - 1].map(value => value * 0.8),
		// A doughnut, or a ring of waffle batter.
		index => {
			const around = (Math.floor(index / 8) / 8) * Math.PI * 2;
			const tube = ((index % 8) / 8) * Math.PI * 2;
			const radius = 0.75 + (0.3 * Math.cos(tube));
			return [radius * Math.cos(around), 0.3 * Math.sin(tube), radius * Math.sin(around)];
		},
		// A double helix.
		index => {
			const step = index % 32;
			const angle = ((step / 32) * Math.PI * 4) + (index >= 32 ? Math.PI : 0);
			return [Math.cos(angle) * 0.6, ((step / 32) * 2) - 1, Math.sin(angle) * 0.6];
		},
	];

	const balls = Array.from({length: ballCount}, (_, index) => shapes[0](index));
	let shapeIndex = 0;
	let shapeTime = 0;
	let ballSprite;
	let ballSpritePalette;

	const makeBallSprite = () => {
		const canvas = makeCanvas(32, 32);
		const spriteContext = canvas.getContext('2d');
		const gradient = spriteContext.createRadialGradient(11, 11, 1, 16, 16, 16);
		gradient.addColorStop(0, '#ffffff');
		// A color from the middle of the palette, as the bright end of most palettes is almost white.
		gradient.addColorStop(0.35, cssColor(palette()[90]));
		gradient.addColorStop(1, '#000000');
		spriteContext.fillStyle = gradient;
		spriteContext.beginPath();
		spriteContext.arc(16, 16, 15.5, 0, Math.PI * 2);
		spriteContext.fill();
		return canvas;
	};

	const drawBalls = delta => {
		const colors = palette();

		for (let y = 0; y < height; y++) {
			pixels.fill(scaleColor(colors[(y + Math.floor(time * 30)) & 255], 0.3), y * width, (y + 1) * width);
		}

		drawScroller(168, delta);
		surface.show();

		shapeTime += delta;

		if (shapeTime > 3.5) {
			shapeTime = 0;
			shapeIndex = (shapeIndex + 1) % shapes.length;
		}

		const amount = delta === 0 ? 1 : Math.min(1, delta * 3);

		for (const [index, ball] of balls.entries()) {
			const target = shapes[shapeIndex](index);

			for (let axis = 0; axis < 3; axis++) {
				ball[axis] += (target[axis] - ball[axis]) * amount;
			}
		}

		if (ballSpritePalette !== paletteIndex) {
			ballSprite = makeBallSprite();
			ballSpritePalette = paletteIndex;
		}

		const projected = balls.map(ball => rotate(ball, time * 0.5, time * 0.8, 0)).sort((first, second) => second[2] - first[2]);

		for (const [x, y, z] of projected) {
			const scale = 240 / (z + 3.5);
			const size = 22 * (2.5 / (z + 3.5));
			context.drawImage(ballSprite, 160 + (x * scale) - (size / 2), 86 + (y * scale) - (size / 2), size, size);
		}
	};

	// MARK: Part 6: Kefrens bars and a twister

	const lineBuffer = new Uint32Array(width);

	const drawTwister = delta => {
		const colors = palette();
		const bar = Array.from({length: 12}, (_, index) => scaleColor(colors[((index * 6) + 60) & 255], 0.3 + (0.7 * Math.sin(((index + 0.5) / 12) * Math.PI))));

		// The bars are drawn into one line, which is not cleared between the lines of the screen, so each bar stays below the one above it, like the Kefrens bars of the Amiga.
		lineBuffer.fill(rgb(0, 0, 24));

		for (let y = 0; y < height; y++) {
			const x = Math.round(160 + (Math.sin((y * 0.035) + (time * 2.1)) * Math.sin((time * 0.6) + (y * 0.008)) * 140)) - 6;

			for (let index = 0; index < 12; index++) {
				if (x + index >= 0 && x + index < width) {
					lineBuffer[x + index] = bar[index];
				}
			}

			pixels.set(lineBuffer, y * width);
		}

		// The twister: a bar with four sides that twists down the screen. Only the sides that face the front are drawn, brighter when they are wider.
		const faceColors = [colors[20], colors[90], colors[160], colors[230]];

		for (let y = 0; y < height; y++) {
			const angle = (time * 1.4) + (Math.sin((y * 0.011) + (time * 0.8)) * 2.4);
			const edges = [0, 1, 2, 3].map(side => 160 + (Math.sin(angle + (side * Math.PI / 2)) * 34));

			for (let side = 0; side < 4; side++) {
				const left = edges[side];
				const right = edges[(side + 1) % 4];

				if (right > left) {
					const color = scaleColor(faceColors[side], 0.35 + (0.65 * ((right - left) / 48)));
					const start = Math.round(left);
					const end = Math.round(right);
					pixels.fill(color, (y * width) + start, (y * width) + end);
					pixels[(y * width) + start] = black;
				}
			}
		}

		drawScroller(168, delta);
		surface.show();
	};

	// MARK: Part 7: the credits over a fire

	const fireWidth = 160;
	// The fire has two more lines than the screen shows, so the line that burns at the bottom is out of sight.
	const fireHeight = 102;
	const fire = new Uint8Array(fireWidth * fireHeight);
	let fireTime = 0;

	const burn = () => {
		for (let x = 0; x < fireWidth; x++) {
			fire[((fireHeight - 1) * fireWidth) + x] = Math.random() < 0.6 ? 255 : 30;
		}

		for (let y = 0; y < fireHeight - 1; y++) {
			const below = Math.min(y + 2, fireHeight - 1) * fireWidth;

			for (let x = 0; x < fireWidth; x++) {
				const next = (y + 1) * fireWidth;
				const sum = fire[next + Math.max(x - 1, 0)] + fire[next + x] + fire[next + Math.min(x + 1, fireWidth - 1)] + fire[below + x];
				fire[(y * fireWidth) + x] = Math.max(0, (sum / 4.03) - (Math.random() * 1.6));
			}
		}
	};

	const credits = [
		'TEAM WAFFLE',
		'',
		'CODE',
		'SINDRE',
		'',
		'GRAPHICS',
		'SINDRE (AND MS PAINT)',
		'',
		'MUSIC',
		'SINDRE IN FASTTRACKER 2',
		'',
		'MORAL SUPPORT',
		'TROND',
		'',
		'WAFFLES',
		'MORMOR',
		'',
		'RELEASED AT',
		'THE GATHERING 1999',
		'VIKINGSKIPET, HAMAR',
		'',
		'WE PLACED 37TH',
		'OUT OF 38',
		'',
		'SEE YOU IN 2000!',
	];

	const creditsDuration = ((credits.length * 16) + height + 20) / 24;

	const drawCredits = delta => {
		fireTime += delta;

		// The fire burns 40 times a second, at any refresh rate of the screen, and is lit before its first still picture.
		if (delta === 0 && fire[(fireHeight - 20) * fireWidth] === 0) {
			for (let step = 0; step < 80; step++) {
				burn();
			}
		}

		while (fireTime > 0.025) {
			fireTime -= 0.025;
			burn();
		}

		for (let y = 0, index = 0; y < height; y++) {
			const row = (y >> 1) * fireWidth;

			for (let x = 0; x < width; x++, index++) {
				pixels[index] = firePalette[fire[row + (x >> 1)]];
			}
		}

		surface.show();

		const offset = (cracktro.reducedMotion ? Math.max(partTime, 6) : partTime) * 24;
		context.font = 'bold 13px "Courier New", monospace';
		context.textAlign = 'center';
		context.lineWidth = 3;
		context.strokeStyle = '#000';
		context.fillStyle = '#fff';

		for (const [index, line] of credits.entries()) {
			const y = height + 10 + (index * 16) - offset;

			if (line && y > -10 && y < height + 10) {
				context.strokeText(line, 160, y);
				context.fillText(line, 160, y);
			}
		}
	};

	// MARK: Playing the parts

	const parts = [
		{name: 'COPPER BARS', title: 'Copper bars and stars', draw: drawCopper, duration: 14},
		{name: 'GLENZ VECTOR', title: 'A glenz vector over a plasma', draw: drawPlasma, duration: 14},
		{name: 'WAFFLE TUNNEL', title: 'A tunnel of waffle', draw: drawTunnel, duration: 14},
		{name: 'ROTOZOOMER', title: 'A rotozoomer of a unicorn', draw: drawRotozoom, duration: 14},
		{name: 'VECTOR BALLS', title: 'Vector balls', draw: drawBalls, duration: 14},
		{name: 'KEFRENS BARS', title: 'Kefrens bars and a twister', draw: drawTwister, duration: 14},
		{name: 'CREDITS', title: 'The credits over a fire', draw: drawCredits, duration: creditsDuration},
	];

	const showPart = () => {
		partLabel.textContent = `PART ${partIndex + 1}/${parts.length}: ${parts[partIndex].name} ★ ${speeds[speedIndex]}× ★ ${palettes[paletteIndex].name}`;
	};

	const changePart = step => {
		partIndex = wrap(partIndex + step, parts.length);
		partTime = 0;
		flash = 1;
		showPart();
	};

	const animation = animate(cracktro, screen, delta => {
		const demoDelta = delta * speeds[speedIndex];
		time += demoDelta;
		partTime += demoDelta;

		if (partTime > parts[partIndex].duration) {
			changePart(1);
		}

		parts[partIndex].draw(demoDelta);

		// A white flash between the parts.
		if (flash > 0 && delta > 0) {
			context.fillStyle = `rgb(255 255 255 / ${flash * 0.7})`;
			context.fillRect(0, 0, width, height);
			flash = Math.max(0, flash - (delta * 3));
		}
	});

	const redraw = () => {
		flash = 0;
		animation.poke(0);
	};

	const crash = () => {
		speedIndex = 0;
		showPart();
		animation.setPaused(true);

		if (document.fullscreenElement) {
			document.exitFullscreen().catch(() => {});
		}

		guru.hidden = false;
		guru.focus();
		cracktro.say('Software Failure. Guru Meditation. The intro was too fast for the Amiga, and it crashed.');
	};

	cracktro.on(guru, 'click', () => {
		guru.hidden = true;
		animation.setPaused(isPausedByVisitor);
		faster.focus();
		redraw();
		cracktro.say('Phew. The intro is back at normal speed.');
	});

	cracktro.on(previous, 'click', () => {
		changePart(-1);
		redraw();
		cracktro.say(`Part ${partIndex + 1} of ${parts.length}: ${parts[partIndex].title}.`);
	});

	cracktro.on(next, 'click', () => {
		changePart(1);
		redraw();
		cracktro.say(`Part ${partIndex + 1} of ${parts.length}: ${parts[partIndex].title}.`);
	});

	cracktro.on(faster, 'click', () => {
		if (speedIndex === speeds.length - 1) {
			crash();
			return;
		}

		speedIndex++;
		showPart();
		redraw();
		cracktro.say(speedIndex === speeds.length - 1 ? 'Speed 8×. Careful, the Amiga is getting hot!' : `Speed ${speeds[speedIndex]}×.`);
	});

	cracktro.on(colors, 'click', () => {
		paletteIndex = (paletteIndex + 1) % palettes.length;
		showPart();
		redraw();
		cracktro.say(`Colors: ${palettes[paletteIndex].name}.`);
	});

	// The pause button does nothing while nothing moves, so it says so.
	const showPause = () => {
		pause.disabled = cracktro.reducedMotion;
		pause.textContent = cracktro.reducedMotion ? 'Paused (reduced motion)' : (isPausedByVisitor ? 'Play' : 'Pause');
	};

	cracktro.on(pause, 'click', () => {
		isPausedByVisitor = !isPausedByVisitor;
		animation.setPaused(isPausedByVisitor || !guru.hidden);
		showPause();
	});

	showPause();

	// Safari on the iPhone can only show a video full screen, so the button is only there where it works.
	fullscreen.hidden = !document.fullscreenEnabled || !screen.requestFullscreen;

	cracktro.on(fullscreen, 'click', () => {
		screen.requestFullscreen().catch(() => {});
	});

	textInput.value = customText;

	cracktro.on(form, 'submit', event => {
		event.preventDefault();
		customText = textInput.value.trim().toUpperCase().slice(0, 140);
		cracktro.store('scroller', customText);
		buildStrip();
		scrollPosition = 220;
		redraw();
		cracktro.say(customText ? 'Your scroller is on the screen. Greetings!' : 'The scroller has my greetings again.');
	});

	showPart();

	return {
		reducedMotionChanged() {
			showPause();

			// The intro draws a still picture when motion stops.
			animation.drawStill();
		},
		registered(name) {
			registeredName = name;
			buildStrip();
			redraw();
		},
	};
};

export default class extends GeoCitiesElement {
	#intro;
	#player;

	connected() {
		const {music} = this.parts;
		this.#intro = setUpIntro(this, this.parts);

		this.on(document, 'geocities-registration', event => {
			this.#intro.registered(event.detail.name);
		});

		this.on(music, 'click', () => {
			if (this.#player) {
				this.#stopMusic();
				return;
			}

			let sound;

			try {
				sound = this.sound();
			} catch {
				return;
			}

			if (!sound) {
				return;
			}

			this.#player = playSong(this, sound);

			// One tune plays at a time on the page, so the jukebox, the keygen, and the Music Room stop when the song of the intro starts.
			this.music(true);
			music.textContent = '♪ Stop Music';
		});

		// The music stops when the visitor leaves the tab, like the loops of the effects.
		this.on(document, 'visibilitychange', () => {
			if (document.hidden) {
				this.#stopMusic();
			}
		});
	}

	disconnected() {
		this.#stopMusic();
	}

	musicStopped() {
		this.#stopMusic();
	}

	#stopMusic() {
		if (!this.#player) {
			return;
		}

		this.#player.stop();
		this.#player = undefined;

		// The page hears that the music stopped, like the screen saver, which waits while music plays.
		this.music(false);
		this.parts.music.textContent = '♪ Play Music';
	}

	reducedMotionChanged() {
		this.#intro.reducedMotionChanged();
	}
}
