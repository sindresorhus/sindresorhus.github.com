// The Casio keyboard of the Music Room on the 1999 page. Each key holds its note while it is pressed, with the tone of the keyboard. The rhythms are patterns of sixteen steps (twelve for the waltz), and with Casio Chord, a key of the lowest octave picks the chord that the rhythm plays along. It plays through the sound card of the Music Room, `geocities-sound-card.js`.
import {context, master, connectVolume, startAudio, midiFrequency, noteNames, pluck, drums, startPlaying, stopPlaying, makeBus, fadeOut, Clock, addStopHandler} from '/scripts/geocities-sound-card.js';

const clamp = (value, minimum, maximum) => Math.min(Math.max(value, minimum), maximum);

// A key handler ignores the keys that go to a text field or a menu inside the keyboard, and the shortcuts of the browser.
const isTypingTarget = event => event.target.closest('input, textarea, select, [contenteditable]') !== null;
const hasModifier = event => event.ctrlKey || event.metaKey || event.altKey;

export default class extends GeoCitiesElement {
	connected() {
		const {keyboard, display, start: startButton, slower, faster, chord: chordButton, demo: demoButton, record: recordButton, playback: playbackButton} = this.parts;
		connectVolume(this.querySelectorAll('[data-music-volume]'), this.signal);
		const keys = [...this.querySelectorAll('[data-casio-note]')];
		const toneButtons = [...this.querySelectorAll('[data-casio-tone]')];
		const rhythmButtons = [...this.querySelectorAll('[data-casio-rhythm]')];
		const lowestNote = 60;
		const computerKeys = ['KeyA', 'KeyW', 'KeyS', 'KeyE', 'KeyD', 'KeyF', 'KeyT', 'KeyG', 'KeyY', 'KeyH', 'KeyU', 'KeyJ', 'KeyK', 'KeyO', 'KeyL', 'KeyP', 'Semicolon', 'Quote'];

		// Each tone builds its sound into the output, and has an envelope: how fast it starts, how loud, how fast it falls to its sustain level, and how fast it fades when the key is let go.
		const tones = {
			piano: {
				envelope: {attack: 0.005, peak: 0.3, decay: 0.5, sustain: 0.15, release: 0.15},
				build(frequency, output, nodes) {
					for (const [type, multiple, level] of [['triangle', 1, 1], ['sine', 2, 0.4]]) {
						const oscillator = new OscillatorNode(context, {type, frequency: frequency * multiple});
						oscillator.connect(new GainNode(context, {gain: level})).connect(output);
						nodes.push(oscillator);
					}
				},
			},
			vibes: {
				envelope: {attack: 0.003, peak: 0.3, decay: 0.8, sustain: 0.1, release: 0.4},
				build(frequency, output, nodes) {
					const tremolo = new GainNode(context, {gain: 0.8});
					const wobble = new OscillatorNode(context, {frequency: 6});
					wobble.connect(new GainNode(context, {gain: 0.2})).connect(tremolo.gain);
					tremolo.connect(output);

					for (const [multiple, level] of [[1, 1], [4, 0.15]]) {
						const oscillator = new OscillatorNode(context, {type: 'sine', frequency: frequency * multiple});
						oscillator.connect(new GainNode(context, {gain: level})).connect(tremolo);
						nodes.push(oscillator);
					}

					nodes.push(wobble);
				},
			},
			organ: {
				envelope: {attack: 0.01, peak: 0.18, decay: 1, sustain: 1, release: 0.05},
				build(frequency, output, nodes) {
					for (const [multiple, level] of [[0.5, 0.6], [1, 1], [2, 0.5], [3, 0.3]]) {
						const oscillator = new OscillatorNode(context, {type: 'sine', frequency: frequency * multiple});
						oscillator.connect(new GainNode(context, {gain: level})).connect(output);
						nodes.push(oscillator);
					}
				},
			},
			trumpet: {
				envelope: {attack: 0.04, peak: 0.2, decay: 0.3, sustain: 0.7, release: 0.08},
				build(frequency, output, nodes) {
					const oscillator = new OscillatorNode(context, {type: 'sawtooth', frequency});
					const filter = new BiquadFilterNode(context, {type: 'lowpass', frequency: frequency * 3, Q: 2});
					const wobble = new OscillatorNode(context, {frequency: 5});
					wobble.connect(new GainNode(context, {gain: 8})).connect(oscillator.detune);
					oscillator.connect(filter).connect(output);
					nodes.push(oscillator, wobble);
				},
			},
			synth: {
				envelope: {attack: 0.01, peak: 0.14, decay: 0.2, sustain: 0.8, release: 0.1},
				build(frequency, output, nodes) {
					const filter = new BiquadFilterNode(context, {type: 'lowpass', frequency: 2800});
					filter.connect(output);

					for (const detune of [-12, 12]) {
						const oscillator = new OscillatorNode(context, {type: 'square', frequency, detune});
						oscillator.connect(filter);
						nodes.push(oscillator);
					}
				},
			},
			musicBox: {
				envelope: {attack: 0.002, peak: 0.3, decay: 0.25, sustain: 0.05, release: 0.6},
				build(frequency, output, nodes) {
					for (const [multiple, level] of [[2, 1], [4, 0.3], [6.3, 0.1]]) {
						const oscillator = new OscillatorNode(context, {type: 'sine', frequency: frequency * multiple});
						oscillator.connect(new GainNode(context, {gain: level})).connect(output);
						nodes.push(oscillator);
					}
				},
			},
			cow: {
				// Tone 99: a cow that moos the note, rising at the start and sinking at the end.
				envelope: {attack: 0.08, peak: 0.22, decay: 0.6, sustain: 0.8, release: 0.25},
				build(frequency, output, nodes, time) {
					const oscillator = new OscillatorNode(context, {type: 'sawtooth', frequency: frequency / 2});
					oscillator.frequency.setValueAtTime(frequency * 0.4, time);
					oscillator.frequency.linearRampToValueAtTime(frequency / 2, time + 0.15);
					oscillator.frequency.linearRampToValueAtTime(frequency * 0.42, time + 1.2);
					const wobble = new OscillatorNode(context, {frequency: 4});
					wobble.connect(new GainNode(context, {gain: 20})).connect(oscillator.detune);

					for (const [formant, level] of [[350, 3], [700, 1.5]]) {
						const filter = new BiquadFilterNode(context, {type: 'bandpass', frequency: formant, Q: 4});
						oscillator.connect(filter).connect(new GainNode(context, {gain: level})).connect(output);
					}

					nodes.push(oscillator, wobble);
				},
			},
		};

		const rhythms = {
			rock: {steps: 16, tempo: 120, kick: 'x.......x.x.....', snare: '....x.......x...', hat: 'x.x.x.x.x.x.x.x.', bass: 'x.......x.......', chord: '....x.......x...'},
			disco: {steps: 16, tempo: 122, kick: 'x...x...x...x...', snare: '....x.......x...', openHat: '..x...x...x...x.', bass: 'x.x.x.x.x.x.x.x.', chord: '..x...x...x...x.'},
			samba: {steps: 16, tempo: 104, kick: 'x..xx..xx..xx..x', shaker: 'xxxxxxxxxxxxxxxx', cowbell: 'x.x..x.x.x..x.x.', bass: 'x..x....x..x....', chord: '..x..x.x..x..x..'},
			waltz: {steps: 12, tempo: 140, kick: 'x...........', snare: '....x...x...', hat: 'x.x.x.x.x.x.', bass: 'x...........', chord: '....x...x...'},
			techno: {steps: 16, tempo: 135, kick: 'x...x...x...x...', clap: '....x.......x...', openHat: '..x...x...x...x.', hat: 'x.x.x.x.x.x.x.x.', bass: '..x...x...x...x.', chord: 'x.....x.....x...'},
			polka: {steps: 16, tempo: 150, kick: 'x.......x.......', snare: '....x.......x...', hat: '..x...x...x...x.', bass: 'x.......x.......', chord: '..x.x.x...x.x.x.'},
		};

		let toneId = 'piano';
		let rhythmId = 'rock';
		let tempo = rhythms.rock.tempo;
		let isChordMode = false;
		let chordRoot;
		const held = new Map();

		// A note of the tone that holds until `stop`. A stop before the attack is over waits for it, so a quick tap still sounds.
		const startNote = ({note, time = context.currentTime, destination = master, tone = toneId}) => {
			const {envelope, build} = tones[tone];
			const output = new GainNode(context, {gain: 0});
			output.connect(destination);
			const nodes = [];
			build(midiFrequency(note), output, nodes, time);
			output.gain.setValueAtTime(0, time);
			output.gain.linearRampToValueAtTime(envelope.peak, time + envelope.attack);
			output.gain.setTargetAtTime(envelope.peak * envelope.sustain, time + envelope.attack, envelope.decay / 3);

			for (const node of nodes) {
				node.start(time);
			}

			return {
				stop(stopTime = context.currentTime) {
					// Just after the attack, as canceling the events at its end would also cancel the attack.
					const end = Math.max(stopTime, time + envelope.attack + 0.001);
					output.gain.cancelScheduledValues(end);
					output.gain.setTargetAtTime(0, end, envelope.release / 3);

					for (const node of nodes) {
						node.stop(end + envelope.release + 0.1);
					}

					setTimeout(() => {
						output.disconnect();
					}, ((end - context.currentTime) + envelope.release + 0.3) * 1000);
				},
			};
		};

		const majorChord = rootNote => [rootNote, rootNote + 4, rootNote + 7];
		const chordName = rootNote => noteNames[rootNote % 12];

		const showDisplay = () => {
			const tone = toneButtons.find(button => button.dataset.casioTone === toneId).textContent.trim();
			const parts = [tone];

			if (rhythmClock.isRunning) {
				parts.push(`♪ ${rhythmId} ${tempo}`);
			}

			if (isChordMode) {
				parts.push(`CHORD ${chordRoot === undefined ? '-' : chordName(chordRoot)}`);
			}

			if (isRecording) {
				parts.push('● REC');
			}

			display.textContent = parts.join(' · ');
		};

		const light = (note, isLit) => {
			const key = keys.find(key => Number(key.dataset.casioNote) === note);

			if (!key) {
				return;
			}

			if (isLit) {
				key.dataset.state = 'lit';
			} else {
				delete key.dataset.state;
			}
		};

		// What the visitor plays is recorded as notes with their start and end, in seconds from the start of the recording.
		let isRecording = false;
		let recordingStart = 0;
		let recording = [];
		const openNotes = new Map();

		const noteOn = note => {
			if (!startAudio() || held.has(note)) {
				return;
			}

			light(note, true);

			// With Casio Chord, the lowest octave picks the chord. While the rhythm plays, the rhythm plays the chord, and else the key plays it.
			if (isChordMode && note < lowestNote + 12) {
				chordRoot = note - 12;
				showDisplay();

				if (rhythmClock.isRunning) {
					held.set(note, {stop() {}});
					return;
				}

				const voices = majorChord(chordRoot).map(chordNote => startNote({note: chordNote}));
				held.set(note, {
					stop() {
						for (const chordVoice of voices) {
							chordVoice.stop();
						}
					},
				});
				return;
			}

			held.set(note, startNote({note}));

			if (isRecording) {
				openNotes.set(note, {note, start: context.currentTime - recordingStart, tone: toneId});
			}
		};

		const noteOff = note => {
			light(note, false);
			held.get(note)?.stop();
			held.delete(note);
			const open = openNotes.get(note);

			if (open) {
				openNotes.delete(note);
				recording.push({...open, end: context.currentTime - recordingStart});
			}
		};

		const releaseAll = () => {
			for (const note of [...held.keys()]) {
				noteOff(note);
			}
		};

		// The keys play with the mouse and with fingers, also sliding from key to key. Each finger is its own pointer.
		const pointerNotes = new Map();
		const keyAt = (x, y) => document.elementFromPoint(x, y)?.closest('[data-casio-note]');

		this.on(keyboard, 'pointerdown', event => {
			const key = event.target.closest('[data-casio-note]');

			if (!key || (event.pointerType === 'mouse' && event.button !== 0)) {
				return;
			}

			event.preventDefault();
			keyboard.focus({preventScroll: true});
			keyboard.setPointerCapture(event.pointerId);
			const note = Number(key.dataset.casioNote);
			pointerNotes.set(event.pointerId, note);
			noteOn(note);
		});

		this.on(keyboard, 'pointermove', event => {
			if (!pointerNotes.has(event.pointerId)) {
				return;
			}

			const key = keyAt(event.clientX, event.clientY);
			const note = key ? Number(key.dataset.casioNote) : undefined;
			const previous = pointerNotes.get(event.pointerId);

			if (note === previous) {
				return;
			}

			if (previous !== undefined) {
				noteOff(previous);
			}

			pointerNotes.set(event.pointerId, note);

			if (note !== undefined) {
				noteOn(note);
			}
		});

		const endPointer = event => {
			const note = pointerNotes.get(event.pointerId);
			pointerNotes.delete(event.pointerId);

			if (note !== undefined) {
				noteOff(note);
			}
		};

		this.on(keyboard, 'pointerup', endPointer);
		this.on(keyboard, 'pointercancel', endPointer);

		// The keys of the computer play while the focus is anywhere in the keyboard, but not in a text field. They are letters, so Space and Enter still press the buttons.
		this.on(this, 'keydown', event => {
			const index = computerKeys.indexOf(event.code);

			if (index === -1 || isTypingTarget(event) || hasModifier(event)) {
				return;
			}

			event.preventDefault();

			if (!event.repeat) {
				noteOn(lowestNote + index);
			}
		});

		this.on(this, 'keyup', event => {
			const index = computerKeys.indexOf(event.code);

			if (index !== -1) {
				noteOff(lowestNote + index);
			}
		});

		this.on(this, 'focusout', event => {
			if (!this.contains(event.relatedTarget)) {
				releaseAll();
			}
		});

		addStopHandler(releaseAll, this.signal);

		// The rhythm, and the chord that it plays along with Casio Chord.
		let rhythmBus;
		const rhythmClock = new Clock({
			stepLength: () => 60 / tempo / 4,
			onStep(step, time) {
				const rhythm = rhythms[rhythmId];
				const index = step % rhythm.steps;
				const plays = part => rhythm[part]?.[index] === 'x';

				for (const part of ['kick', 'snare', 'hat', 'openHat', 'clap', 'shaker', 'cowbell']) {
					if (plays(part)) {
						drums[part](time, rhythmBus);
					}
				}

				if (isChordMode && chordRoot !== undefined) {
					const stepLength = 60 / tempo / 4;

					if (plays('bass')) {
						// The bass goes between the root and the fifth.
						const hit = [...rhythm.bass.slice(0, index)].filter(mark => mark === 'x').length;
						pluck({frequency: midiFrequency(chordRoot - 12 + (hit % 2 === 1 ? 7 : 0)), time, duration: stepLength * 2.5, destination: rhythmBus, type: 'triangle', volume: 0.45});
					}

					if (plays('chord')) {
						for (const note of majorChord(chordRoot + 12)) {
							pluck({frequency: midiFrequency(note), time, duration: stepLength * 2, destination: rhythmBus, type: 'square', volume: 0.05, filter: {type: 'lowpass', frequency: 1800}});
						}
					}
				}
			},
		});

		const rhythmPlayer = {
			stop() {
				rhythmClock.stop();
				fadeOut(rhythmBus);
				rhythmBus = undefined;
				stopPlaying(rhythmPlayer);
				startButton.setAttribute('aria-pressed', 'false');
				delete startButton.dataset.state;
				showDisplay();
			},
		};

		const startRhythm = () => {
			startPlaying(rhythmPlayer);
			rhythmBus = makeBus();
			rhythmClock.start();
			startButton.setAttribute('aria-pressed', 'true');
			startButton.dataset.state = 'on';
			showDisplay();
		};

		this.on(startButton, 'click', () => {
			if (rhythmClock.isRunning) {
				rhythmPlayer.stop();
				this.say('The rhythm stopped.');
				return;
			}

			if (!startAudio()) {
				return;
			}

			startRhythm();
			this.say(isChordMode ? `${rhythmId} rhythm! Press a key of the lowest octave for a chord.` : `${rhythmId} rhythm at ${tempo} beats a minute. Play along!`);
		});

		for (const [button, change] of [[slower, -6], [faster, 6]]) {
			this.on(button, 'click', () => {
				tempo = clamp(tempo + change, 60, 220);
				showDisplay();
				this.say(`Tempo ${tempo}.`);
			});
		}

		const choose = (buttons, attribute, id) => {
			for (const button of buttons) {
				const isOn = button.dataset[attribute] === id;
				button.setAttribute('aria-pressed', String(isOn));

				if (isOn) {
					button.dataset.state = 'on';
				} else {
					delete button.dataset.state;
				}
			}
		};

		for (const button of toneButtons) {
			this.on(button, 'click', () => {
				toneId = button.dataset.casioTone;
				choose(toneButtons, 'casioTone', toneId);
				showDisplay();

				// The tone plays its own name, so the visitor hears it at once.
				if (startAudio()) {
					startNote({note: 67}).stop(context.currentTime + 0.4);
				}

				this.say(toneId === 'cow' ? 'Tone 99, Moo Cow. Every Casio has a silly one.' : `Tone ${button.textContent.trim()}.`);
			});
		}

		for (const button of rhythmButtons) {
			this.on(button, 'click', () => {
				rhythmId = button.dataset.casioRhythm;
				tempo = rhythms[rhythmId].tempo;
				choose(rhythmButtons, 'casioRhythm', rhythmId);
				showDisplay();
				this.say(`${button.textContent.trim()} rhythm. Press Start/Stop.`);
			});
		}

		this.on(chordButton, 'click', () => {
			isChordMode = !isChordMode;
			chordRoot = undefined;
			chordButton.setAttribute('aria-pressed', String(isChordMode));

			if (isChordMode) {
				chordButton.dataset.state = 'on';
			} else {
				delete chordButton.dataset.state;
			}

			showDisplay();
			this.say(isChordMode ? 'Casio Chord is on: the lowest octave, A to J, plays a whole chord with one finger. Press Start/Stop for the rhythm.' : 'Casio Chord is off.');
		});

		// The demo song is The Entertainer by Scott Joplin (1902), with the keys that light up as it plays. Each note is a MIDI note and its length in sixteenth notes, and 0 is a rest.
		const entertainerStart = [[62, 1], [63, 1], [64, 1], [72, 2], [64, 1], [72, 2], [64, 1], [72, 6], [0, 1]];
		const demoMelody = [
			...entertainerStart,
			[72, 1], [74, 1], [75, 1], [76, 1], [72, 1], [74, 1], [76, 2], [71, 1], [74, 2], [72, 6], [0, 2],
			...entertainerStart,
			[69, 1], [67, 1], [66, 1], [69, 1], [72, 1], [76, 2], [74, 1], [72, 1], [69, 1], [74, 6], [0, 2],
			...entertainerStart,
			[72, 1], [74, 1], [75, 1], [76, 1], [72, 1], [74, 1], [76, 2], [71, 1], [74, 2], [72, 8],
		];
		const demoBass = [48, 55, 48, 55, 43, 50, 48, 48];
		let demoBus;
		let demoTimers = [];

		const stopDemo = () => {
			for (const timer of demoTimers) {
				clearTimeout(timer);
			}

			demoTimers = [];
			fadeOut(demoBus);
			demoBus = undefined;

			for (const key of keys) {
				delete key.dataset.state;
			}

			demoButton.setAttribute('aria-pressed', 'false');
			delete demoButton.dataset.state;
		};

		const demoPlayer = {
			stop() {
				stopDemo();
				stopPlaying(demoPlayer);
			},
		};

		// Plays notes of the piano tone and lights their keys, from a time.
		const playNotes = (notes, start, bus, sixteenth) => {
			let time = start;

			for (const [note, length] of notes) {
				const duration = length * sixteenth;

				if (note > 0) {
					startNote({note, time, destination: bus, tone: 'piano'}).stop(time + (duration * 0.9));
					demoTimers.push(setTimeout(() => {
						light(note, true);
					}, (time - context.currentTime) * 1000), setTimeout(() => {
						light(note, false);
					}, (time + (duration * 0.9) - context.currentTime) * 1000));
				}

				time += duration;
			}

			return time;
		};

		this.on(demoButton, 'click', () => {
			if (demoBus) {
				demoPlayer.stop();
				this.say('The demo stopped.');
				return;
			}

			if (!startAudio()) {
				return;
			}

			startPlaying(demoPlayer);
			demoBus = makeBus();
			demoButton.setAttribute('aria-pressed', 'true');
			demoButton.dataset.state = 'on';
			const sixteenth = 60 / 92 / 4;
			const start = context.currentTime + 0.1;
			const end = playNotes(demoMelody, start, demoBus, sixteenth);

			// An oom-pah under it: the bass on the beat, and a soft chord after it.
			for (let beat = 0; start + (beat * sixteenth * 4) < end - (sixteenth * 4); beat++) {
				const time = start + (sixteenth * 3) + (beat * sixteenth * 4);
				const bass = demoBass[Math.floor(beat / 2) % demoBass.length];
				pluck({frequency: midiFrequency(bass - 12), time, duration: sixteenth * 2, destination: demoBus, type: 'triangle', volume: 0.3});

				for (const note of majorChord(bass)) {
					pluck({frequency: midiFrequency(note), time: time + (sixteenth * 2), duration: sixteenth * 1.5, destination: demoBus, type: 'triangle', volume: 0.06});
				}
			}

			demoTimers.push(setTimeout(() => {
				demoPlayer.stop();
				this.say('Clap clap clap! (You did not play that. I know.)');
			}, (end - context.currentTime + 0.5) * 1000));
			this.say('Demo: The Entertainer, by Scott Joplin. Pretend you play it.');
		});

		// The memory records up to a minute, and plays it back with the tones it was played with.
		let recordTimer;

		const stopRecording = () => {
			isRecording = false;
			clearTimeout(recordTimer);
			recordButton.setAttribute('aria-pressed', 'false');
			delete recordButton.dataset.state;

			for (const note of [...openNotes.keys()]) {
				noteOff(note);
			}

			playbackButton.disabled = recording.length === 0;
			showDisplay();
		};

		this.on(recordButton, 'click', () => {
			if (isRecording) {
				stopRecording();
				this.say(recording.length > 0 ? `Recorded ${recording.length} notes. Press Play Memory.` : 'Nothing recorded. Press Rec and play some keys.');
				return;
			}

			if (!startAudio()) {
				return;
			}

			isRecording = true;
			recording = [];
			playbackButton.disabled = true;
			recordingStart = context.currentTime;
			recordButton.setAttribute('aria-pressed', 'true');
			recordButton.dataset.state = 'on';
			recordTimer = setTimeout(() => {
				stopRecording();
				this.say('The memory is full! One minute is all a Casio can hold.');
			}, 60_000);
			showDisplay();
			this.say('Recording! Play some keys, then press Rec again.');
		});

		this.on(playbackButton, 'click', () => {
			if (!startAudio() || recording.length === 0) {
				return;
			}

			startPlaying(demoPlayer);
			stopDemo();
			demoBus = makeBus();
			const firstStart = Math.min(...recording.map(note => note.start));
			const start = context.currentTime + 0.1;
			let end = start;

			for (const recorded of recording) {
				const time = start + recorded.start - firstStart;
				const stopTime = start + recorded.end - firstStart;
				startNote({note: recorded.note, time, destination: demoBus, tone: recorded.tone}).stop(stopTime);
				end = Math.max(end, stopTime);
				demoTimers.push(setTimeout(() => {
					light(recorded.note, true);
				}, (time - context.currentTime) * 1000), setTimeout(() => {
					light(recorded.note, false);
				}, (stopTime - context.currentTime) * 1000));
			}

			demoTimers.push(setTimeout(() => {
				demoPlayer.stop();
			}, (end - context.currentTime + 0.5) * 1000));
			this.say('Playing the memory.');
		});

		showDisplay();
	}
}
