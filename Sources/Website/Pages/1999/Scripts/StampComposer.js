// The stamp composer of the Music Room on the 1999 page, like the music maker of a painting game for game consoles from 1992: a staff of 32 beats, where each beat holds up to three stamps, like in that game. The height of a stamp is its note, from the C below the staff to the G above it, and the stamp is its instrument. The song is kept in the browser. It plays through the sound card of the Music Room, `geocities-sound-card.js`.
import {context, connectVolume, startAudio, midiFrequency, noteName, tone, pluck, noiseHit, voice, drums, startPlaying, stopPlaying, makeBus, fadeOut, Clock} from '/scripts/geocities-sound-card.js';

const clamp = (value, minimum, maximum) => Math.min(Math.max(value, minimum), maximum);
const hasModifier = event => event.ctrlKey || event.metaKey || event.altKey;

export default class extends GeoCitiesElement {
	connected() {
		const {staff: canvas, runner, play: playButton, tempo: tempoInput, clear} = this.parts;
		connectVolume(this.querySelectorAll('[data-music-volume]'), this.signal);
		const drawing = canvas.getContext('2d');
		const scroller = canvas.parentElement;
		const stampButtons = [...this.querySelectorAll('[data-stamps-stamp]')];
		const width = 936;
		const height = 170;
		const left = 48;
		const columnWidth = 28;
		const columnCount = 32;
		const scale = [60, 62, 64, 65, 67, 69, 71, 72, 74, 76, 77, 79];
		const bottom = 140;
		const lineGap = 10;
		drawing.scale(canvas.width / width, canvas.height / height);

		const stamps = {
			unicorn: {emoji: '🦄', play: (note, time, bus) => {
				pluck({frequency: midiFrequency(note), time, duration: 0.8, destination: bus, type: 'triangle', volume: 0.35});
				pluck({frequency: midiFrequency(note + 12), time, duration: 0.4, destination: bus, type: 'sine', volume: 0.1});
			}},
			waffle: {emoji: '🧇', play: (note, time, bus) => {
				pluck({frequency: midiFrequency(note), time, duration: 0.3, destination: bus, type: 'sine', volume: 0.45});
				pluck({frequency: midiFrequency(note) * 4, time, duration: 0.05, destination: bus, type: 'sine', volume: 0.08});
			}},
			cat: {emoji: '🐱', play: (note, time, bus) => {
				// Meow: the pitch and the vowel go up and down.
				const frequency = midiFrequency(note);
				const audio = bus.context;
				const oscillator = new OscillatorNode(audio, {type: 'sawtooth', frequency: frequency * 0.8});
				oscillator.frequency.setValueAtTime(frequency * 0.8, time);
				oscillator.frequency.linearRampToValueAtTime(frequency * 1.1, time + 0.12);
				oscillator.frequency.linearRampToValueAtTime(frequency * 0.85, time + 0.38);
				const filter = new BiquadFilterNode(audio, {type: 'bandpass', frequency: 800, Q: 3});
				filter.frequency.setValueAtTime(800, time);
				filter.frequency.linearRampToValueAtTime(1600, time + 0.12);
				filter.frequency.linearRampToValueAtTime(700, time + 0.38);
				const envelope = new GainNode(audio, {gain: 0});
				envelope.gain.setValueAtTime(0, time);
				envelope.gain.linearRampToValueAtTime(0.7, time + 0.04);
				envelope.gain.linearRampToValueAtTime(0, time + 0.4);
				oscillator.connect(filter).connect(envelope).connect(bus);
				oscillator.start(time);
				oscillator.stop(time + 0.42);
			}},
			hamster: {emoji: '🐹', play: (note, time, bus) => {
				for (const delay of [0, 0.09]) {
					tone({frequency: midiFrequency(note + 24), slideTo: midiFrequency(note + 28), time: time + delay, duration: 0.07, destination: bus, type: 'sine', volume: 0.25});
				}
			}},
			dog: {emoji: '🐶', play: (note, time, bus) => {
				voice({frequency: midiFrequency(note - 12), slideTo: midiFrequency(note - 17), time, duration: 0.16, destination: bus, from: 'a', to: 'u', volume: 0.6});
				noiseHit({time, duration: 0.06, destination: bus, volume: 0.15, type: 'lowpass', frequency: 1200});
			}},
			star: {emoji: '⭐', play: (note, time, bus) => {
				pluck({frequency: midiFrequency(note + 12), time, duration: 1.2, destination: bus, type: 'sine', volume: 0.25});
				pluck({frequency: midiFrequency(note + 12) * 2.76, time, duration: 0.6, destination: bus, type: 'sine', volume: 0.08});
			}},
			floppy: {emoji: '💾', play: (note, time, bus) => {
				// The buzz of the stepper motor of a floppy drive, which people made play music.
				tone({frequency: midiFrequency(note - 12), time, duration: 0.22, destination: bus, type: 'square', volume: 0.12, filter: {type: 'bandpass', frequency: 600, Q: 1}});
				tone({frequency: 30, time, duration: 0.22, destination: bus, type: 'square', volume: 0.05});
			}},
			drum: {emoji: '🥁', play: (note, time, bus) => {
				if (note <= 64) {
					drums.kick(time, bus);
				} else {
					drums.tom(time, bus, 0.6, midiFrequency(note - 24));
				}
			}},
		};

		// The song, as a list of stamps for each beat: the height on the staff, from 0 for the C below it, and the stamp.
		const emptySong = () => Array.from({length: columnCount}, () => []);
		const storedSong = this.stored('song', undefined);
		let song = emptySong();

		if (Array.isArray(storedSong)) {
			song = song.map((_, column) => (Array.isArray(storedSong[column]) ? storedSong[column] : [])
				.filter(note => Number.isInteger(note?.position) && note.position >= 0 && note.position < scale.length && typeof note.stamp === 'string' && Object.hasOwn(stamps, note.stamp))
				.slice(0, 3));
		}

		let selected = 'unicorn';
		let cursor = {column: 0, position: 4};
		let playingColumn = -1;
		let hasFocus = false;

		const columnX = column => left + (column * columnWidth) + (columnWidth / 2);
		const positionY = position => bottom - (position * lineGap);

		const draw = () => {
			drawing.fillStyle = '#ffffff';
			drawing.fillRect(0, 0, width, height);

			if (playingColumn >= 0) {
				drawing.fillStyle = '#fff3a0';
				drawing.fillRect(left + (playingColumn * columnWidth), 10, columnWidth, height - 20);
			}

			// The five lines of the staff, E, G, B, D, and F, and a line at every bar of four beats.
			drawing.strokeStyle = '#333';
			drawing.lineWidth = 1;

			for (const position of [2, 4, 6, 8, 10]) {
				drawing.beginPath();
				drawing.moveTo(8, positionY(position) + 0.5);
				drawing.lineTo(width - 8, positionY(position) + 0.5);
				drawing.stroke();
			}

			for (let column = 0; column <= columnCount; column += 4) {
				const x = left + (column * columnWidth) + 0.5;
				drawing.beginPath();
				drawing.moveTo(x, positionY(10));
				drawing.lineTo(x, positionY(2));
				drawing.stroke();
			}

			drawing.fillStyle = '#333';
			drawing.font = '64px serif';
			drawing.textAlign = 'center';
			drawing.textBaseline = 'middle';
			drawing.fillText('𝄞', 26, positionY(5));
			drawing.font = '18px sans-serif';

			for (const [column, notes] of song.entries()) {
				for (const note of notes) {
					const x = columnX(column);
					const y = positionY(note.position);

					// The C below the staff has a short line through it, like in printed music.
					if (note.position === 0) {
						drawing.beginPath();
						drawing.moveTo(x - 12, y + 0.5);
						drawing.lineTo(x + 12, y + 0.5);
						drawing.stroke();
					}

					drawing.fillText(stamps[note.stamp].emoji, x, y);
				}
			}

			if (hasFocus) {
				drawing.strokeStyle = '#ff6f3c';
				drawing.lineWidth = 2;
				drawing.setLineDash([4, 3]);
				drawing.strokeRect(columnX(cursor.column) - 13, positionY(cursor.position) - 10, 26, 20);
				drawing.setLineDash([]);
			}
		};

		const playStamp = (stamp, position, time, destination) => {
			stamps[stamp].play(scale[position], time, destination);
		};

		const previewStamp = (stamp, position) => {
			if (!startAudio()) {
				return;
			}

			const previewBus = makeBus();
			playStamp(stamp, position, context.currentTime + 0.02, previewBus);
			setTimeout(() => {
				previewBus.disconnect();
			}, 2000);
		};

		// Stamps the picked stamp at a spot, or takes it away when the same stamp is there, or erases with the eraser.
		const stampAt = (column, position) => {
			const notes = song[column];
			const existing = notes.findIndex(note => note.position === position);

			if (selected === 'eraser') {
				if (existing === -1) {
					this.say('Nothing to erase there.');
				} else {
					notes.splice(existing, 1);
					this.say('Erased.');
				}
			} else if (existing !== -1 && notes[existing].stamp === selected) {
				notes.splice(existing, 1);
				this.say('Taken away.');
			} else if (existing !== -1) {
				notes[existing].stamp = selected;
				previewStamp(selected, position);
			} else if (notes.length >= 3) {
				this.say('Only three stamps fit on one beat, like in the old painting game.');
				return;
			} else {
				notes.push({position, stamp: selected});
				previewStamp(selected, position);
				this.say(`${stampButtons.find(button => button.dataset.stampsStamp === selected).getAttribute('aria-label')} on ${noteName(scale[position])}, beat ${column + 1}.`);
			}

			this.store('song', song);
			draw();
		};

		this.on(canvas, 'click', event => {
			const bounds = canvas.getBoundingClientRect();
			const x = (event.clientX - bounds.left) * (width / bounds.width);
			const y = (event.clientY - bounds.top) * (height / bounds.height);
			const column = Math.floor((x - left) / columnWidth);
			const position = Math.round((bottom - y) / lineGap);

			if (column < 0 || column >= columnCount || position < 0 || position >= scale.length) {
				return;
			}

			cursor = {column, position};
			stampAt(column, position);
		});

		this.on(canvas, 'keydown', event => {
			if (hasModifier(event)) {
				return;
			}

			const moves = {ArrowUp: [0, 1], ArrowDown: [0, -1], ArrowLeft: [-1, 0], ArrowRight: [1, 0]};

			if (moves[event.key]) {
				event.preventDefault();
				const [columnChange, positionChange] = moves[event.key];
				cursor = {column: clamp(cursor.column + columnChange, 0, columnCount - 1), position: clamp(cursor.position + positionChange, 0, scale.length - 1)};
				const notes = song[cursor.column].filter(note => note.position === cursor.position);
				this.say(`Beat ${cursor.column + 1}, ${noteName(scale[cursor.position])}${notes.length > 0 ? `: ${stampButtons.find(button => button.dataset.stampsStamp === notes[0].stamp).getAttribute('aria-label')}` : ''}`);
				scrollTo(cursor.column);
				draw();
			} else if (event.key === 'Enter' || event.key === ' ') {
				event.preventDefault();
				stampAt(cursor.column, cursor.position);
			} else if (event.key === 'Delete' || event.key === 'Backspace') {
				event.preventDefault();
				const previous = selected;
				selected = 'eraser';
				stampAt(cursor.column, cursor.position);
				selected = previous;
			}
		});

		this.on(canvas, 'focus', () => {
			hasFocus = true;
			draw();
		});

		this.on(canvas, 'blur', () => {
			hasFocus = false;
			draw();
		});

		// Keeps a beat in view inside the box of the staff, without scrolling the page.
		const scrollTo = column => {
			const x = columnX(column);

			if (x < scroller.scrollLeft + 40 || x > scroller.scrollLeft + scroller.clientWidth - 40) {
				scroller.scrollLeft = x - (scroller.clientWidth / 2);
			}
		};

		for (const button of stampButtons) {
			this.on(button, 'click', () => {
				selected = button.dataset.stampsStamp;

				for (const other of stampButtons) {
					const isOn = other === button;
					other.setAttribute('aria-pressed', String(isOn));

					if (isOn) {
						other.dataset.state = 'on';
					} else {
						delete other.dataset.state;
					}
				}

				if (selected !== 'eraser') {
					previewStamp(selected, 7);
				}
			});
		}

		// Playing: one beat after the other, to the last bar with a stamp, and Glitter hops from beat to beat above the staff.
		let bus;
		let lastColumn = 0;
		const clock = new Clock({
			stepLength: () => 60 / Number(tempoInput.value),
			onStep: (step, time) => {
				if (step > lastColumn) {
					// The stop waits a moment, so the stamps of the last beat ring out.
					clock.atTime(time + 1.2, () => {
						player.stop();
						this.say('Bravo! 👏');
					});
					clock.isRunning = false;
					return;
				}

				for (const note of song[step]) {
					playStamp(note.stamp, note.position, time, bus);
				}

				clock.atTime(time, () => {
					const previousX = columnX(Math.max(playingColumn, 0)) - 12;
					playingColumn = step;
					draw();
					scrollTo(step);
					const x = columnX(step) - 12;
					runner.style.translate = `${x}px 0`;

					if (!this.reducedMotion) {
						runner.animate([{translate: `${previousX}px 0`}, {translate: `${(previousX + x) / 2}px -10px`}, {translate: `${x}px 0`}], {duration: Math.min(250, (60 / Number(tempoInput.value)) * 900), easing: 'ease-out'});
					}
				});
			},
		});

		const player = {
			stop() {
				clock.stop();
				fadeOut(bus);
				bus = undefined;
				stopPlaying(player);
				playingColumn = -1;
				runner.style.translate = '';
				playButton.textContent = '▶ Play';
				draw();
			},
		};

		this.on(playButton, 'click', () => {
			if (clock.isRunning || bus) {
				player.stop();
				return;
			}

			const usedColumns = song.flatMap((notes, column) => (notes.length > 0 ? [column] : []));

			if (usedColumns.length === 0) {
				this.say('The staff is empty. Stamp some notes first, or load a song.');
				return;
			}

			if (!startAudio()) {
				return;
			}

			// It plays to the end of the last bar with a stamp.
			lastColumn = (Math.floor(usedColumns.at(-1) / 4) * 4) + 3;
			startPlaying(player);
			bus = makeBus();
			clock.start();
			playButton.textContent = '■ Stop';
			this.say('Go, Glitter, go!');
		});

		// The songs to start from, as beats of notes: the stamp, and the note name, from C (low) to G (high, written g).
		const songs = {
			twinkle: [
				['star C', 'drum D'], ['star C'], ['star G', 'unicorn E'], ['star G'], ['star A', 'drum C'], ['star A'], ['star G', 'unicorn E'], [],
				['star F', 'drum C'], ['star F'], ['star E', 'unicorn C'], ['star E'], ['star D', 'drum C'], ['star D'], ['star C', 'unicorn E'], [],
			],
			hop: [
				['hamster C', 'drum D'], ['cat E'], ['hamster G', 'drum A'], ['dog C'], ['hamster C', 'drum D'], ['cat E'], ['waffle G', 'drum A'], ['waffle A'],
				['hamster F', 'drum C'], ['cat A'], ['hamster c', 'drum A'], ['dog F'], ['floppy G', 'drum C'], ['floppy G'], ['star c', 'unicorn E', 'drum A'], ['star g'],
			],
		};
		const positions = {C: 0, D: 1, E: 2, F: 3, G: 4, A: 5, B: 6, c: 7, d: 8, e: 9, f: 10, g: 11};

		for (const button of this.querySelectorAll('[data-stamps-song]')) {
			this.on(button, 'click', () => {
				song = emptySong();

				for (const [column, notes] of songs[button.dataset.stampsSong].entries()) {
					song[column] = notes.map(note => {
						const [stamp, name] = note.split(' ');
						return {position: positions[name], stamp};
					});
				}

				this.store('song', song);
				draw();
				this.say(`Loaded ${button.textContent.trim()}. Press Play!`);
			});
		}

		this.on(clear, 'click', () => {
			song = emptySong();
			this.store('song', song);
			draw();
			this.say('The staff is empty.');
		});

		draw();
	}
}
