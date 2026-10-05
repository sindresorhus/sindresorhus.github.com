// The Hampster Band of the Music Room on the 1999 page plays a loop of four bars in G, a slow country song at 33 RPM. Like a record, a faster speed makes it both faster and higher, so at 78 RPM it becomes the Hampster Dance. It plays through the sound card of the Music Room, `geocities-sound-card.js`.
import {context, connectVolume, startAudio, midiFrequency, tone, pluck, voice, drums, chords, startPlaying, stopPlaying, makeBus, fadeOut, Clock} from '/scripts/geocities-sound-card.js';

export default class extends GeoCitiesElement {
	connected() {
		const {everybody: everybodyButton, stop} = this.parts;
		connectVolume(this.querySelectorAll('[data-music-volume]'), this.signal);
		const partButtons = [...this.querySelectorAll('[data-hamster-part]')];
		const members = [...this.querySelectorAll('[data-hamster-member]')];
		const speedInputs = [...this.querySelectorAll('[data-hamster-speed]')];
		const baseTempo = 92;
		const progression = [chords.G, chords.C, chords.D, chords.G];
		const parts = new Set();
		let rate = Number(speedInputs.find(input => input.checked)?.value ?? 33) / 33;
		let hasCelebrated = false;

		// The whistled melody, one bar for each chord: the step in the bar, the MIDI note, and the length in steps.
		const melody = [
			[[0, 74, 4], [4, 71, 2], [6, 74, 2], [8, 79, 4], [12, 76, 4]],
			[[0, 76, 4], [4, 72, 2], [6, 76, 2], [8, 79, 4], [12, 76, 4]],
			[[0, 78, 4], [4, 81, 2], [6, 78, 2], [8, 74, 4], [12, 69, 4]],
			[[0, 71, 2], [2, 74, 2], [4, 79, 8], [12, 79, 2], [14, 74, 2]],
		];

		const pitch = note => midiFrequency(note) * rate;

		const play = {
			drums(step, time, chord, bus) {
				if (step === 0 || step === 8) {
					drums.kick(time, bus, 0.7);
				}

				if (step === 4 || step === 12) {
					drums.snare(time, bus, 0.35);
				}

				if (step % 2 === 0) {
					drums.hat(time, bus, 0.1);
				}
			},
			bass(step, time, chord, bus, stepLength) {
				if (step === 0 || step === 8) {
					pluck({frequency: pitch(chord[0] - 12 + (step === 8 ? 7 : 0)), time, duration: stepLength * 3, destination: bus, type: 'triangle', volume: 0.5});
				}
			},
			banjo(step, time, chord, bus, stepLength) {
				// A roll of the banjo: the notes of the chord, picked fast and bright.
				const roll = [chord[0] + 12, chord[1] + 12, chord[2] + 12, chord[0] + 24];
				pluck({frequency: pitch(roll[step % 4]), time, duration: stepLength * 2, destination: bus, type: 'square', volume: 0.07, filter: {type: 'highpass', frequency: 400}});
			},
			whistle(step, time, chord, bus, stepLength, bar) {
				const note = melody[bar].find(([start]) => start === step);

				if (note) {
					const [, midi, length] = note;
					const oscillator = tone({frequency: pitch(midi), time, duration: stepLength * length * 0.95, destination: bus, type: 'sine', volume: 0.25, attack: 0.03, release: 0.06});
					const wobble = new OscillatorNode(context, {frequency: 6});
					wobble.connect(new GainNode(context, {gain: 18})).connect(oscillator.detune);
					wobble.start(time);
					wobble.stop(time + (stepLength * length));
				}
			},
			vocals(step, time, chord, bus, stepLength) {
				if (step === 2 || step === 6 || step === 10) {
					voice({frequency: pitch(chord[1]), time, duration: stepLength * 1.5, destination: bus, from: 'i', volume: 0.35});
				}

				if (step === 14) {
					voice({frequency: pitch(chord[0]), time, duration: stepLength * 1.8, destination: bus, from: 'o', to: 'u', volume: 0.35});
				}
			},
		};

		let bus;
		const clock = new Clock({
			stepLength: () => 60 / (baseTempo * rate) / 4,
			onStep(step, time) {
				const bar = Math.floor(step / 16) % 4;
				const stepLength = 60 / (baseTempo * rate) / 4;

				for (const part of parts) {
					play[part](step % 16, time, progression[bar], bus, stepLength, bar);
				}
			},
		});

		// A hamster dances while its part plays: its GIF moves, and else it shows the still frame.
		const showMembers = () => {
			for (const member of members) {
				const isOn = parts.has(member.dataset.hamsterMember);
				const image = member.querySelector('img');
				image.src = isOn ? image.dataset.animated : image.dataset.still;

				if (isOn) {
					member.dataset.state = 'on';
				} else {
					delete member.dataset.state;
				}
			}

			for (const button of partButtons) {
				const isOn = parts.has(button.dataset.hamsterPart);
				button.setAttribute('aria-pressed', String(isOn));

				if (isOn) {
					button.dataset.state = 'on';
				} else {
					delete button.dataset.state;
				}
			}
		};

		for (const member of members) {
			const image = member.querySelector('img');
			image.dataset.animated = image.getAttribute('src');
			image.dataset.still = image.dataset.animated.replace('/1999/', '/1999/still/');
		}

		const player = {
			stop() {
				clock.stop();
				fadeOut(bus);
				bus = undefined;
				stopPlaying(player);
				parts.clear();
				showMembers();
			},
		};

		const speedMessages = {
			33: '33 RPM: a nice, slow country song. Yee-haw.',
			45: '45 RPM: hmm, this sounds familiar…',
			78: '78 RPM: IT’S THE HAMPSTER DANCE! Dee dee doo!',
		};

		const update = () => {
			if (parts.size === 0) {
				player.stop();
				this.say('The band is resting. Turn on a hamster.');
				return;
			}

			if (!clock.isRunning) {
				if (!startAudio()) {
					return;
				}

				startPlaying(player);
				bus = makeBus();
				clock.start();
			}

			showMembers();
			const names = partButtons.filter(button => parts.has(button.dataset.hamsterPart)).map(button => button.querySelector('strong').textContent);
			this.say(`${names.join(', ')} ${names.length === 1 ? 'plays' : 'play'}. ${speedMessages[Math.round(rate * 33)] ?? ''}`);

			if (parts.size === partButtons.length && rate > 2 && !hasCelebrated) {
				hasCelebrated = true;
				this.celebrate();
				// Glitter cheers for a big win of the Music Room too, like for the other wins of the page.
				this.cheer();
			}
		};

		for (const button of partButtons) {
			this.on(button, 'click', () => {
				const part = button.dataset.hamsterPart;

				if (parts.has(part)) {
					parts.delete(part);
				} else {
					parts.add(part);
				}

				update();
			});
		}

		this.on(everybodyButton, 'click', () => {
			for (const button of partButtons) {
				parts.add(button.dataset.hamsterPart);
			}

			update();
		});

		this.on(stop, 'click', () => {
			player.stop();
			this.say('The band is resting.');
		});

		for (const input of speedInputs) {
			this.on(input, 'change', () => {
				rate = Number(input.value) / 33;

				if (parts.size > 0) {
					update();
				} else {
					this.say(`${speedMessages[input.value]} Turn on some hamsters!`);
				}
			});
		}

		showMembers();
	}
}
