// The warez corner of the 1999 page: the shareware nag window, the keygen of TEAM WAFFLE with its scroller and keygen music, and the NFO file of the release. The scroller runs only while it is on the screen and the tab is visible, and for visitors who prefer reduced motion, it shows a still picture, the serial does not roll, and the NFO file does not type. The music plays only after the visitor presses the button that says it plays music.
//
// The page is registered to the name of a serial from the keygen, which is kept in the browser. The scroller of the intro (`Cracktro.js`) thanks the visitor for it: the keygen sends the name with the `geocities-registration` event when it starts and when it changes, and the intro can read `registeredName` of the keygen.

const randomItem = items => items[Math.floor(Math.random() * items.length)];

// MARK: The music

// A chip with four channels, like the music of the demos and the keygens, made with the Web Audio API: a square lead, a thin square that plays a chord as a fast arpeggio, a triangle bass, and drums of noise. It starts only when the visitor presses the button that plays music. The intro (`Cracktro.js`) has the same chip, with its own song.
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

const polka = pattern(
	'C-5 --- E-5 --- G-5 --- E-5 --- F-5 --- A-5 --- G-5 --- E-5 ---',
	'--- --- --- --- C-5 --- --- --- --- --- --- --- G-4 --- --- ---',
	'C-3 --- --- --- G-2 --- --- --- F-2 --- --- --- G-2 --- --- ---',
	'KCK --- SNR --- KCK --- SNR --- KCK --- SNR --- KCK --- SNR SNR',
);

// The song of the keygen, as patterns in order, composed by me in FastTracker 2, with a polka in the middle, as a surprise.
const song = {bpm: 145, patterns: [anthem, anthem, anthem, polka]};

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

// MARK: The serial

// The serial of a name, which the keygen makes and the nag window checks: a word, and two groups of hexadecimal digits from a hash of the name, like the serials of 1999.
const hashText = text => {
	let hash = 0x81_1C_9D_C5;

	for (const character of text) {
		hash ^= character.codePointAt(0);
		hash = Math.imul(hash, 0x01_00_01_93) >>> 0;
	}

	return hash >>> 0;
};

const normalizedName = name => name.trim().replaceAll(/\s+/g, ' ').toUpperCase();
const serialWords = ['WAFL', 'BRUN', 'UNIC', 'GLTR', 'TABS', 'IMAC', 'BOND', 'Y2K0'];
const hexGroup = value => value.toString(16).toUpperCase().padStart(4, '0');

const serialFor = name => {
	const first = hashText(normalizedName(name));
	const second = hashText(`${normalizedName(name)}*TWF`);
	return `TWF-${serialWords[first % serialWords.length]}-${hexGroup(first >>> 16)}-${hexGroup((first ^ second) & 0xFF_FF)}`;
};

// Some names get a message, like the keygens that knew their friends.
const specialNames = {
	'BILL GATES': 'Bill Gates detected. Here is your serial anyway. That will be $1,000 per forward.',
	TROND: 'Trond, you are in TEAM WAFFLE. You do not need a serial. But here is one.',
	GLITTER: 'Unicorns cannot type. Who is really typing? Here is a serial anyway.',
	SINDRE: 'Hi, me! Here is my own serial for my own home page.',
	MAMMA: 'Hi, Mamma! Yes, I did my homework. Here is your serial.',
};

const laterMessages = [
	'OK. I will remind you later.',
	'It is later now. Please register.',
	'Mamma says you should register.',
	'Glitter is crying. Look what you did.',
	'Fine. I will wait. I have all the time in the world. Until Y2K.',
	'Registering is free! The keygen is right there!',
];

// Notepad reads the bytes of code page 437 as Windows-1252, so the blocks and lines of the ANSI art turn into letters.
const notepadCharacters = {'█': 'Û', '▓': '²', '▒': '±', '░': '°', '▄': 'Ü', '▀': 'ß', '═': 'Í', '║': 'º', '╔': 'É', '╗': '»', '╚': 'È', '╝': '¼', '─': 'Ä', '·': 'ú'};

const scrollerText = '★ SINDRE.EXE KEYGEN ★ CRACKED BY TEAM WAFFLE IN 1999 ★ TYPE ANY NAME AND PRESS GENERATE ★ GREETINGS TO ALL ELITE WEB MASTERS ★ ';

export default class extends GeoCitiesElement {
	#registeredName;
	#generated;
	#roll;
	#finishRoll;
	#shake;
	#laterCount = 0;
	#isNotepad = false;
	#typingFrame;
	#player;
	#scroller;
	#drawScroller;

	// The name that the page is registered to, for the scroller of the intro.
	get registeredName() {
		return this.#registeredName;
	}

	connected() {
		const {music} = this.parts;
		this.#registeredName = this.stored('registration', '').slice(0, 24) || undefined;
		this.#setUpKeygen();
		this.#setUpNag();
		this.#setUpNfo();

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

			// One tune plays at a time on the page, so the jukebox, the intro, and the Music Room stop when the keygen music starts.
			this.music(true);
			music.textContent = '♪ Stop';
		});

		// The music stops when the visitor leaves the tab, like the scroller.
		this.on(document, 'visibilitychange', () => {
			if (document.hidden) {
				this.#stopMusic();
			}
		});

		this.#sendRegistration();
	}

	disconnected() {
		this.#stopMusic();
		this.#stopTyping();
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
		this.parts.music.textContent = '♪ Music';
	}

	reducedMotionChanged() {
		// The scroller draws a still picture when motion stops.
		if (this.#scroller.isVisible) {
			this.#drawScroller(0);
		}
	}

	// MARK: The keygen

	#setUpKeygen() {
		const {form, name: nameInput, serial: serialOutput, copy, scroller} = this.parts;

		this.on(form, 'submit', event => {
			event.preventDefault();
			const name = nameInput.value.trim();

			if (!name) {
				return;
			}

			const serial = serialFor(name);
			const message = specialNames[normalizedName(name)] ?? `Serial for ${name} generated. Type the same name and the serial into the nag window to register.`;
			this.#roll?.cancel();

			const finish = () => {
				this.#roll?.cancel();
				this.#finishRoll = undefined;
				this.#generated = {name, serial};
				serialOutput.value = serial;
				this.say(message);
			};

			if (this.reducedMotion) {
				finish();
				return;
			}

			// The characters roll for a moment, like a keygen that works hard.
			let rolls = 0;
			const characters = '0123456789ABCDEF';
			this.#finishRoll = finish;
			this.#roll = this.interval(40, () => {
				rolls++;

				if (rolls > 12) {
					finish();
					return;
				}

				serialOutput.value = `TWF-${serial.slice(4).replaceAll(/[\dA-Z]/g, () => randomItem(characters))}`;
			});
		});

		this.on(copy, 'click', async () => {
			// A serial that still rolls is finished first, so the copy is the real one.
			this.#finishRoll?.();

			if (!this.#generated) {
				this.say('Press Generate first. A keygen cannot copy what it has not made.');
				return;
			}

			try {
				await navigator.clipboard.writeText(this.#generated.serial);
				this.say('Copied! Now paste it into the nag window.');
			} catch {
				serialOutput.select();
				this.say('The serial is selected. Copy it with Ctrl+C, like in 1999.');
			}
		});

		// The scroller of the keygen, in a rainbow, one letter at a time.
		const scrollerContext = scroller.getContext('2d');
		let scrollerPosition = 0;
		let scrollerTime = 0;

		this.#drawScroller = delta => {
			scrollerTime += delta;
			scrollerPosition += delta * 50;
			scrollerContext.fillStyle = '#000';
			scrollerContext.fillRect(0, 0, scroller.width, scroller.height);
			scrollerContext.font = 'bold 14px "Courier New", monospace';
			scrollerContext.textBaseline = 'middle';
			const letterWidth = 9;
			const first = Math.floor(scrollerPosition / letterWidth);

			for (let index = 0; index <= (scroller.width / letterWidth) + 1; index++) {
				const x = (index * letterWidth) - (scrollerPosition % letterWidth);
				const y = 12 + (Math.sin((x * 0.05) + (scrollerTime * 4)) * 5);
				scrollerContext.fillStyle = `hsl(${((x * 2) + (scrollerTime * 200)) % 360} 100% 60%)`;
				scrollerContext.fillText(scrollerText[(first + index) % scrollerText.length], x, y);
			}
		};

		// It moves while it is on the screen, the tab is visible, and motion is allowed. A step of 0 seconds draws a still picture, so the first step of a run moves like a frame.
		this.loop(seconds => {
			this.#drawScroller(seconds || (1 / 60));
		}, {target: scroller, maximumStep: 0.05, while: () => !this.reducedMotion});

		// The first picture is drawn when it first shows, also when nothing moves.
		let hasDrawn = false;

		this.#scroller = this.watchVisibility(scroller, isVisible => {
			if (isVisible && !hasDrawn) {
				hasDrawn = true;
				this.#drawScroller(0);
			}
		});
	}

	// MARK: The nag window

	#setUpNag() {
		const {nag, nagForm, nagName: nameInput, nagSerial: serialInput, later, unregister, trial, nagMessage, nagStatus, registered} = this.parts;

		// The trial started on the first visit, which is kept in the browser.
		const firstVisit = Number(this.stored('first-visit', 0)) || Date.now();
		this.store('first-visit', firstVisit);
		// A first visit in the future, from a clock that was wrong, is day 1.
		const day = Math.max(1, Math.floor((Date.now() - firstVisit) / 86_400_000) + 1);
		trial.textContent = day <= 30 ? `This is day ${day} of your 30-day free trial.` : `Your 30-day free trial ended ${day - 30} days ago. The page still works. Please feel guilty.`;

		this.on(nagForm, 'submit', event => {
			event.preventDefault();
			const name = nameInput.value.trim();
			const serial = serialInput.value.trim().toUpperCase();

			if (serial !== serialFor(name)) {
				this.say(serial === this.#generated?.serial ? `This serial is for ${this.#generated.name}. Type the same name as in the keygen.` : 'Invalid serial number for this name. Did you use the keygen? It is right there.', nagStatus);

				if (!this.reducedMotion) {
					// The shake starts again for each wrong serial, also when the last one still shakes.
					this.#shake?.cancel();
					delete nag.dataset.state;
					void nag.offsetWidth;
					nag.dataset.state = 'wrong';
					this.#shake = this.timeout(450, () => {
						delete nag.dataset.state;
					});
				}

				return;
			}

			this.#setRegisteredName(name);
			this.#showRegistration();

			// The form is gone, so the focus moves to the thank you.
			registered.tabIndex = -1;
			registered.focus();
			this.say(`Thank you for registering, ${name}!`, nagStatus);
			this.toast(`Sindre’s Home Page is now registered to ${name}. Thank you!`);

			// The win of Solitaire, and Glitter cheers too.
			this.celebrate();
			this.cheer();
		});

		this.on(later, 'click', () => {
			this.say(laterMessages[Math.min(this.#laterCount, laterMessages.length - 1)], nagMessage);
			this.#laterCount++;
		});

		this.on(unregister, 'click', () => {
			this.#setRegisteredName(undefined);
			this.#showRegistration();
			serialInput.value = '';

			// The thank you is gone, so the focus moves to the nag again. It goes to the text, not the field, as Safari on the iPhone does not focus a field without a tap on it.
			trial.tabIndex = -1;
			trial.focus();
			this.say('Unregistered. The nag window is back. It missed you.', nagStatus);
		});

		this.#showRegistration();
	}

	#showRegistration() {
		const {nagTitle, unregistered, registered, registeredName} = this.parts;
		nagTitle.textContent = this.#registeredName ? 'Sindre’s Home Page 1999: Registered' : 'Sindre’s Home Page 1999: UNREGISTERED';
		unregistered.hidden = Boolean(this.#registeredName);
		registered.hidden = !this.#registeredName;
		registeredName.textContent = this.#registeredName ?? '';
	}

	#setRegisteredName(name) {
		this.#registeredName = name;
		this.store('registration', name);
		this.#sendRegistration();
	}

	// The scroller of the intro thanks the visitor for registering.
	#sendRegistration() {
		document.dispatchEvent(new CustomEvent('geocities-registration', {detail: {name: this.#registeredName}}));
	}

	// MARK: The NFO file

	#setUpNfo() {
		const {nfo, nfoTitle, notepad} = this.parts;
		const original = nfo.textContent;
		const currentText = () => this.#isNotepad ? original.replaceAll(/./g, character => notepadCharacters[character] ?? character) : original;

		for (const button of this.querySelectorAll('[data-nfo-speed]')) {
			this.on(button, 'click', () => {
				this.#stopTyping();
				const bitsPerSecond = Number(button.dataset.nfoSpeed);
				const text = currentText();

				// A modem sends 10 bits for each character: 8 for the character, and a start and a stop bit.
				const seconds = Math.round((text.length * 10) / bitsPerSecond);
				const done = () => {
					nfo.textContent = text;
					nfo.removeAttribute('aria-busy');
					this.toast(`TWF-SINDRE.NFO downloaded: ${text.length.toLocaleString('en-US')} bytes in ${seconds} ${seconds === 1 ? 'second' : 'seconds'} at ${button.textContent}.`);
				};

				if (this.reducedMotion) {
					done();
					return;
				}

				nfo.setAttribute('aria-busy', 'true');
				let start;

				// The typing goes on while the file is off the screen, like a download, so it is a chain of frames of its own and not a loop of the element, which only runs on the screen.
				const frame = now => {
					start ??= now;
					const count = Math.floor(((now - start) / 1000) * (bitsPerSecond / 10));

					if (count >= text.length) {
						done();
						return;
					}

					nfo.textContent = `${text.slice(0, count)}█`;
					this.#typingFrame = requestAnimationFrame(frame);
				};

				this.#typingFrame = requestAnimationFrame(frame);
			});
		}

		this.on(notepad, 'click', () => {
			this.#stopTyping();
			this.#isNotepad = !this.#isNotepad;
			nfo.textContent = currentText();
			nfoTitle.textContent = this.#isNotepad ? 'TWF-SINDRE.NFO - Notepad' : 'TWF-SINDRE.NFO: DOS Prompt';
			notepad.textContent = this.#isNotepad ? 'Open in DOS' : 'Open in Notepad';

			if (this.#isNotepad) {
				nfo.dataset.state = 'notepad';
				this.toast('Notepad does not know the characters of DOS, so the ANSI art turns into garbage, like on Windows 98.');
			} else {
				delete nfo.dataset.state;
			}
		});
	}

	#stopTyping() {
		cancelAnimationFrame(this.#typingFrame);
		this.parts.nfo.removeAttribute('aria-busy');
	}
}
