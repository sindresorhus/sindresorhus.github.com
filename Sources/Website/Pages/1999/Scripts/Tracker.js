// WaffleTracker 2 in the Music Room on the 1999 page, a music tracker like FastTracker 2: a pattern of 32 rows and four channels. Each spot has a note and an instrument, or nothing. A row is a sixteenth note at 125 beats a minute, which is speed 6 in FastTracker 2. The pattern is kept in the browser. It plays through the sound card of the Music Room, `geocities-sound-card.js`.
import {context, connectVolume, startAudio, midiFrequency, noteName, tone, pluck, drums, startPlaying, stopPlaying, makeBus, fadeOut, Clock, midiFile, download} from '/scripts/geocities-sound-card.js';

const clamp = (value, minimum, maximum) => Math.min(Math.max(value, minimum), maximum);
const hasModifier = event => event.ctrlKey || event.metaKey || event.altKey;

export default class extends GeoCitiesElement {
	connected() {
		const {pattern, play: playButton, title, octave: octaveText, clear, midi} = this.parts;
		connectVolume(this.querySelectorAll('[data-music-volume]'), this.signal);
		const rows = [...this.querySelectorAll('[data-tracker-row]')];
		const cells = rows.map(row => [...row.querySelectorAll('[data-tracker-cell]')]);
		const meters = [...this.querySelectorAll('[data-tracker-meter]')];
		const muteButtons = [...this.querySelectorAll('[data-tracker-mute]')];
		const instrumentButtons = [...this.querySelectorAll('[data-tracker-instrument]')];
		const rowCount = rows.length;
		const channelCount = 4;
		const stepLength = 60 / 125 / 4;
		const instrumentNames = ['Kick', 'Snare', 'HiHat', 'Bass', 'Lead', 'Pad'];

		// The keys of the computer as the keys of a piano, like in FastTracker 2: the bottom row is one octave (Z is C, S is C sharp), and the row of Q the next.
		const pianoKeys = {
			KeyZ: 0, KeyS: 1, KeyX: 2, KeyD: 3, KeyC: 4, KeyV: 5, KeyG: 6, KeyB: 7, KeyH: 8, KeyN: 9, KeyJ: 10, KeyM: 11, Comma: 12, KeyL: 13, Period: 14,
			KeyQ: 12, Digit2: 13, KeyW: 14, Digit3: 15, KeyE: 16, KeyR: 17, Digit5: 18, KeyT: 19, Digit6: 20, KeyY: 21, Digit7: 22, KeyU: 23, KeyI: 24, Digit9: 25, KeyO: 26, Digit0: 27, KeyP: 28,
		};

		const instruments = [
			(note, time, bus) => drums.kick(time, bus, 0.6),
			(note, time, bus) => drums.snare(time, bus, 0.3),
			(note, time, bus) => drums.hat(time, bus, 0.15),
			(note, time, bus) => pluck({frequency: midiFrequency(note), time, duration: 0.3, destination: bus, type: 'sawtooth', volume: 0.2, filter: {type: 'lowpass', frequency: 900, Q: 4}}),
			(note, time, bus) => tone({frequency: midiFrequency(note), time, duration: stepLength * 1.8, destination: bus, type: 'square', volume: 0.07, filter: {type: 'lowpass', frequency: 3200}}),
			(note, time, bus) => {
				for (const detune of [-10, 10]) {
					tone({frequency: midiFrequency(note), time, duration: stepLength * 7, destination: bus, type: 'sawtooth', volume: 0.05, detune, attack: 0.15, release: 0.3, filter: {type: 'lowpass', frequency: 1500}});
				}
			},
		];

		const emptyPattern = () => Array.from({length: rowCount}, () => Array.from({length: channelCount}, () => undefined));

		// The modules to load. Each is a list of notes: the row, the channel, the MIDI note, and the instrument.
		const modules = {
			brunost: {
				file: 'brunost.xm',
				notes: [
					...[0, 4, 8, 12, 16, 20, 24, 28].map(row => [row, 0, 60, 1]),
					...[4, 12, 20, 28].map(row => [row, 1, 60, 2]),
					...[2, 6, 10, 14, 18, 22, 26, 30].map(row => [row, 1, 60, 3]),
					...[[2, 45], [6, 45], [10, 45], [14, 48], [18, 41], [22, 41], [26, 43], [30, 43]].map(([row, note]) => [row, 2, note, 4]),
					...[69, 72, 76, 72, 69, 72, 76, 81, 65, 69, 72, 69, 67, 71, 74, 79].map((note, index) => [index * 2, 3, note, 5]),
				],
			},
			hamster: {
				file: 'hampster.mod',
				notes: [
					...[0, 8, 16, 24].map(row => [row, 0, 60, 1]),
					...[4, 12, 20, 28].map(row => [row, 1, 60, 2]),
					...[2, 6, 10, 14, 18, 22, 26, 30].map(row => [row, 1, 60, 3]),
					...[[0, 48], [4, 43], [8, 48], [12, 43], [16, 41], [20, 48], [24, 43], [28, 50]].map(([row, note]) => [row, 2, note, 4]),
					...[[0, 76], [2, 79], [4, 79], [6, 76], [8, 72], [10, 74], [12, 76], [16, 77], [18, 81], [20, 81], [22, 77], [24, 79], [26, 74], [28, 72]].map(([row, note]) => [row, 3, note, 5]),
				],
			},
		};

		const storedPattern = this.stored('pattern', undefined);
		let song = emptyPattern();

		// A stored pattern is checked spot by spot, so a broken one cannot break the tracker.
		if (Array.isArray(storedPattern)) {
			song = song.map((row, rowIndex) => row.map((_, channel) => {
				const cell = storedPattern[rowIndex]?.[channel];
				return Number.isInteger(cell?.note) && Number.isInteger(cell?.instrument) && cell.instrument >= 1 && cell.instrument <= 6 ? {note: clamp(cell.note, 12, 107), instrument: cell.instrument} : undefined;
			}));
		}

		let cursor = {row: 0, channel: 0};
		let octave = 4;
		let instrument = 1;
		const muted = [false, false, false, false];

		const hex = number => number.toString(16).toUpperCase().padStart(2, '0');
		const trackerNote = note => `${['C-', 'C#', 'D-', 'D#', 'E-', 'F-', 'F#', 'G-', 'G#', 'A-', 'A#', 'B-'][note % 12]}${Math.floor(note / 12) - 1}`;
		const cellText = cell => (cell ? `${trackerNote(cell.note)} ${hex(cell.instrument)}` : '--- --');
		const cellDescription = cell => (cell ? `${noteName(cell.note)} ${instrumentNames[cell.instrument - 1]}` : 'empty');

		const showCell = (row, channel) => {
			cells[row][channel].textContent = cellText(song[row][channel]);
		};

		const showSong = () => {
			for (let row = 0; row < rowCount; row++) {
				for (let channel = 0; channel < channelCount; channel++) {
					showCell(row, channel);
				}
			}

			this.store('pattern', song);
		};

		const showCursor = shouldAnnounce => {
			for (const row of cells) {
				for (const cell of row) {
					delete cell.dataset.state;
				}
			}

			const cell = cells[cursor.row][cursor.channel];
			cell.dataset.state = 'cursor';

			// The cursor stays in view inside the pattern, without scrolling the page.
			const top = cell.offsetTop;

			if (top < pattern.scrollTop || top + cell.offsetHeight > pattern.scrollTop + pattern.clientHeight) {
				pattern.scrollTop = top - (pattern.clientHeight / 2);
			}

			if (shouldAnnounce) {
				this.say(`Row ${hex(cursor.row)}, channel ${cursor.channel + 1}: ${cellDescription(song[cursor.row][cursor.channel])}`);
			}
		};

		const preview = cell => {
			if (!startAudio()) {
				return;
			}

			const previewBus = makeBus();
			instruments[cell.instrument - 1](cell.note, context.currentTime + 0.02, previewBus);
			setTimeout(() => {
				previewBus.disconnect();
			}, 2000);
		};

		const enterNote = offset => {
			const note = clamp(((octave + 1) * 12) + offset, 12, 107);
			const cell = {note, instrument};
			song[cursor.row][cursor.channel] = cell;
			showCell(cursor.row, cursor.channel);
			this.store('pattern', song);
			preview(cell);

			// Like in FastTracker 2, the cursor moves down a row after a note, so a melody can be typed.
			cursor.row = (cursor.row + 1) % rowCount;
			showCursor(false);
			this.say(`${cellDescription(cell)} on row ${hex((cursor.row + rowCount - 1) % rowCount)}.`);
		};

		const erase = () => {
			song[cursor.row][cursor.channel] = undefined;
			showCell(cursor.row, cursor.channel);
			this.store('pattern', song);
			showCursor(true);
		};

		const setOctave = value => {
			octave = clamp(value, 1, 7);
			octaveText.textContent = octave;
			this.say(`Octave ${octave}.`);
		};

		this.on(pattern, 'keydown', event => {
			if (hasModifier(event)) {
				return;
			}

			const moves = {ArrowUp: [-1, 0], ArrowDown: [1, 0], ArrowLeft: [0, -1], ArrowRight: [0, 1]};

			if (moves[event.key]) {
				event.preventDefault();
				const [rowChange, channelChange] = moves[event.key];
				cursor = {row: (cursor.row + rowChange + rowCount) % rowCount, channel: clamp(cursor.channel + channelChange, 0, channelCount - 1)};
				showCursor(true);
				return;
			}

			if (event.key === 'Delete' || event.key === 'Backspace') {
				event.preventDefault();
				erase();
				return;
			}

			if (event.key === ' ') {
				event.preventDefault();
				togglePlay();
				return;
			}

			// The keys of notes stop here, as other games of the page listen to some of them, like the digits.
			if (pianoKeys[event.code] !== undefined) {
				event.preventDefault();
				event.stopPropagation();

				if (!event.repeat) {
					enterNote(pianoKeys[event.code]);
				}
			}
		});

		this.on(pattern, 'focus', () => {
			showCursor(true);
		});

		for (const [rowIndex, row] of cells.entries()) {
			for (const [channel, cell] of row.entries()) {
				this.on(cell, 'click', () => {
					cursor = {row: rowIndex, channel};
					pattern.focus({preventScroll: true});
					showCursor(true);
				});
			}
		}

		for (const button of this.querySelectorAll('[data-tracker-note]')) {
			this.on(button, 'click', () => {
				const value = button.dataset.trackerNote;

				if (value === 'delete') {
					erase();
				} else if (value === 'up' || value === 'down') {
					setOctave(octave + (value === 'up' ? 1 : -1));
				} else {
					enterNote(Number(value));
				}
			});
		}

		for (const button of instrumentButtons) {
			this.on(button, 'click', () => {
				instrument = Number(button.dataset.trackerInstrument);

				for (const other of instrumentButtons) {
					const isOn = other === button;
					other.setAttribute('aria-pressed', String(isOn));

					if (isOn) {
						other.dataset.state = 'on';
					} else {
						delete other.dataset.state;
					}
				}

				preview({note: (octave + 1) * 12, instrument});
				this.say(`Instrument ${hex(instrument)}, ${instrumentNames[instrument - 1]}.`);
			});
		}

		for (const button of muteButtons) {
			this.on(button, 'click', () => {
				const channel = Number(button.dataset.trackerMute);
				muted[channel] = !muted[channel];
				button.setAttribute('aria-pressed', String(muted[channel]));

				if (muted[channel]) {
					button.dataset.state = 'muted';
				} else {
					delete button.dataset.state;
				}

				this.say(`Channel ${channel + 1} ${muted[channel] ? 'muted' : 'on'}.`);
			});
		}

		// Playing: a bar runs down the pattern, and the meter of a channel lights up for each note.
		let bus;
		const clock = new Clock({
			stepLength: () => stepLength,
			onStep(step, time) {
				const row = step % rowCount;

				for (let channel = 0; channel < channelCount; channel++) {
					const cell = song[row][channel];

					if (cell && !muted[channel]) {
						instruments[cell.instrument - 1](cell.note, time, bus);
						clock.atTime(time, () => {
							meters[channel].dataset.state = 'hit';
							setTimeout(() => {
								delete meters[channel].dataset.state;
							}, 60);
						});
					}
				}

				clock.atTime(time, () => {
					showPlayingRow(row);
				});
			},
		});

		const showPlayingRow = row => {
			for (const [index, element] of rows.entries()) {
				if (index === row) {
					element.dataset.state = 'now';
				} else {
					delete element.dataset.state;
				}
			}

			if (row >= 0) {
				pattern.scrollTop = rows[row].offsetTop - (pattern.clientHeight / 2);
			}
		};

		const player = {
			stop() {
				clock.stop();
				fadeOut(bus);
				bus = undefined;
				stopPlaying(player);
				showPlayingRow(-1);
				playButton.textContent = '▶ Play';
			},
		};

		const togglePlay = () => {
			if (clock.isRunning) {
				player.stop();
				this.say('Stopped.');
				return;
			}

			if (!startAudio()) {
				return;
			}

			startPlaying(player);
			bus = makeBus();
			clock.start();
			playButton.textContent = '■ Stop';
			this.say(song.flat().some(Boolean) ? 'Playing the pattern.' : 'Playing an empty pattern. Type some notes!');
		};

		this.on(playButton, 'click', togglePlay);

		for (const button of this.querySelectorAll('[data-tracker-module]')) {
			this.on(button, 'click', () => {
				const module = modules[button.dataset.trackerModule];
				song = emptyPattern();

				for (const [row, channel, note, number] of module.notes) {
					song[row][channel] = {note, instrument: number};
				}

				showSong();
				title.textContent = `WaffleTracker 2.08 - ${module.file}`;
				this.say(`Loaded ${module.file}. Press Play!`);
			});
		}

		this.on(clear, 'click', () => {
			song = emptyPattern();
			showSong();
			title.textContent = 'WaffleTracker 2.08 - untitled.xm';
			this.say('A new, empty pattern.');
		});

		// The MIDI file has the pattern four times. The drums go on channel 10 (9 from 0), with the notes of the General MIDI drums, and the bass, the lead, and the pad on their own channels with their own instruments.
		this.on(midi, 'click', () => {
			const drumNotes = {1: 36, 2: 38, 3: 42};
			const channels = {4: 0, 5: 1, 6: 2};
			const lengths = {4: 2, 5: 2, 6: 8};
			const notes = [];

			for (let repeat = 0; repeat < 4; repeat++) {
				for (const [row, channelsOfRow] of song.entries()) {
					for (const cell of channelsOfRow) {
						if (!cell) {
							continue;
						}

						const start = ((repeat * rowCount) + row) * 24;
						notes.push(drumNotes[cell.instrument]
							? {note: drumNotes[cell.instrument], start, length: 12, channel: 9}
							: {note: cell.note, start, length: lengths[cell.instrument] * 24, channel: channels[cell.instrument], velocity: 90});
					}
				}
			}

			if (notes.length === 0) {
				this.say('The pattern is empty. There is nothing to save.');
				return;
			}

			download(midiFile({tempo: 125, programs: {0: 38, 1: 80, 2: 89}, notes}), 'waffletracker.mid');
			this.say('Saved waffletracker.mid.');
		});

		showSong();
	}
}
