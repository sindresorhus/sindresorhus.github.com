// The Composer of the Nokia 3210 in the Music Room on the 1999 page, and the ringtone ad of a magazine. A note is written like `8.#f2`: its length (1 is a whole note and 32 the shortest), a dot for one and a half times as long, a sharp, the note or `-` for a rest, and the octave from 1 to 3. Octave 1 starts at the C of 523 Hz, as phones beeped high. The tune and the phone bill are kept in the browser. It plays through the sound card of the Music Room, `geocities-sound-card.js`.
import {context, connectVolume, startAudio, midiFrequency, tone, startPlaying, stopPlaying, makeBus, fadeOut, midiFile, download} from '/scripts/geocities-sound-card.js';

const clamp = (value, minimum, maximum) => Math.min(Math.max(value, minimum), maximum);
const randomItem = items => items[Math.floor(Math.random() * items.length)];

// A key handler ignores the keys that go to a text field or a menu inside the phone, and the shortcuts of the browser.
const isTypingTarget = event => event.target.closest('input, textarea, select, [contenteditable]') !== null;
const hasModifier = event => event.ctrlKey || event.metaKey || event.altKey;

export default class extends GeoCitiesElement {
	connected() {
		const {phone, code: screenCode, text, tempo: tempoSelect, status, call: callScreen, caller, answer: answerButton, reject: rejectButton, play, ring: ringButton, midi, clear, bill, pay: payButton} = this.parts;
		connectVolume(this.querySelectorAll('[data-music-volume]'), this.signal);
		const lengths = [1, 2, 4, 8, 16, 32];
		const letters = ['c', 'd', 'e', 'f', 'g', 'a', 'b'];
		const semitones = {c: 0, d: 2, e: 4, f: 5, g: 7, a: 9, b: 11};
		const maximumNotes = 50;
		const notePattern = /^(1|2|4|8|16|32)(\.?)(#?)([a-g]|-)([1-3]?)$/;

		const ringtones = {
			nokia: {tempo: 200, code: '8e2 8d2 4#f1 4#g1 8#c2 8b1 4d1 4e1 8b1 8a1 4#c1 4e1 2a1'},
			elise: {tempo: 125, code: '16e2 16#d2 16e2 16#d2 16e2 16b1 16d2 16c2 8a1 16- 16c1 16e1 16a1 8b1 16- 16e1 16#g1 16b1 8c2 16- 16e1 16e2 16#d2 16e2 16#d2 16e2 16b1 16d2 16c2 8a1 16- 16c1 16e1 16a1 8b1 16- 16e1 16c2 16b1 4a1'},
			morning: {tempo: 100, code: '8g1 8e1 8d1 8c1 8d1 8e1 8g1 8e1 8d1 8c1 16d1 16e1 16d1 16e1 8g1 8e1 8g1 8a1 8e1 8a1 8g1 8e1 8d1 4.c1'},
			mozart: {tempo: 125, code: '4g1 8- 8d1 4g1 8- 8d1 8g1 8d1 8g1 8b1 4d2 4- 4c2 8- 8a1 4c2 8- 8a1 8c2 8a1 8#f1 8a1 4d1'},
			joy: {tempo: 160, code: '4e1 4e1 4f1 4g1 4g1 4f1 4e1 4d1 4c1 4c1 4d1 4e1 4.e1 8d1 2d1'},
			boogie: {tempo: 160, code: '8c1 8e1 8g1 8a1 8#a1 8a1 8g1 8e1 8c1 8e1 8g1 8a1 8#a1 8a1 8g1 8e1 8f1 8a1 8c2 8d2 8#d2 8d2 8c2 8a1 8c1 8e1 8g1 8a1 8#a1 8a1 8g1 8e1 8g1 8b1 8d2 8b1 8f1 8a1 4c2 4-'},
			alarm: {tempo: 250, code: '16c3 16- 16c3 16- 16c3 8- 16g2 16- 16g2 16- 16g2 8- 16c3 16g2 16e2 16c2 16e2 16g2 4c3'},
		};

		const format = note => `${note.length}${note.isDotted ? '.' : ''}${note.isSharp ? '#' : ''}${note.letter}${note.letter === '-' ? '' : note.octave}`;

		// Reads a code, or returns the first word it does not understand.
		const parse = code => {
			const notes = [];

			for (const word of code.toLowerCase().split(/\s+/).filter(Boolean)) {
				const match = notePattern.exec(word);

				if (!match) {
					return {error: word};
				}

				const [, length, dot, sharp, letter, octave] = match;
				notes.push({length: Number(length), isDotted: dot === '.', isSharp: sharp === '#' && letter !== '-', letter, octave: Number(octave) || 1});
			}

			return {notes};
		};

		let notes = parse(ringtones.nokia.code).notes;
		tempoSelect.value = String(ringtones.nokia.tempo);

		const show = () => {
			const code = notes.map(note => format(note)).join(' ');
			screenCode.textContent = code || '_';
			text.value = code;
			this.store('tone', {code, tempo: tempoSelect.value});
		};

		const stored = this.stored('tone', undefined);

		if (typeof stored?.code === 'string' && parse(stored.code).notes) {
			notes = parse(stored.code).notes.slice(0, maximumNotes);

			if ([...tempoSelect.options].some(option => option.value === String(stored.tempo))) {
				tempoSelect.value = String(stored.tempo);
			}
		}

		const noteMidi = note => 72 + ((note.octave - 1) * 12) + semitones[note.letter] + (note.isSharp ? 1 : 0);
		const noteSeconds = (note, tempo) => (4 / note.length) * (60 / tempo) * (note.isDotted ? 1.5 : 1);

		// The beep of the phone: a quiet square wave, a little shorter than the note, so notes of the same pitch are apart.
		const beep = (note, time, tempo, destination) => {
			const duration = noteSeconds(note, tempo);

			if (note.letter !== '-') {
				tone({frequency: midiFrequency(noteMidi(note)), time, duration: duration * 0.9, destination, type: 'square', volume: 0.12, filter: {type: 'lowpass', frequency: 5000}});
			}

			return duration;
		};

		let bus;
		let timer;
		let isRinging = false;

		const player = {
			stop() {
				clearTimeout(timer);
				fadeOut(bus);
				bus = undefined;
				stopPlaying(player);

				if (isRinging) {
					endCall();
				}
			},
		};

		// Plays the tune, as many times as asked, and then calls `onEnd`.
		const playTune = ({times = 1, onEnd}) => {
			if (!startAudio()) {
				return;
			}

			player.stop();
			startPlaying(player);
			bus = makeBus();
			const tempo = Number(tempoSelect.value);
			let time = context.currentTime + 0.05;

			for (let round = 0; round < times; round++) {
				for (const note of notes) {
					time += beep(note, time, tempo, bus);
				}

				time += 0.6;
			}

			timer = setTimeout(() => {
				fadeOut(bus);
				bus = undefined;
				stopPlaying(player);
				onEnd?.();
			}, (time - context.currentTime) * 1000);
		};

		// The keys of the phone, like on the real Composer: 1 to 7 add a note with the length and the octave of the last one, 8 and 9 make the last note shorter and longer, 0 adds a rest, * changes the octave of the last note, # makes it sharp, and C deletes it.
		const press = key => {
			const last = notes.at(-1);

			if ('1234567'.includes(key) || key === '0') {
				if (notes.length >= maximumNotes) {
					this.say('The Composer is full. A Nokia 3210 only holds 50 notes!');
					return;
				}

				const letter = key === '0' ? '-' : letters[Number(key) - 1];
				notes.push({length: last?.length ?? 4, isDotted: false, isSharp: false, letter, octave: last?.octave ?? 1});
			} else if (!last) {
				this.say('Press 1 to 7 for a note first.');
				return;
			} else if (key === '8' || key === '9') {
				const index = lengths.indexOf(last.length) + (key === '8' ? 1 : -1);
				last.length = lengths[clamp(index, 0, lengths.length - 1)];
			} else if (key === '*') {
				last.octave = (last.octave % 3) + 1;
			} else if (key === '#') {
				if (last.letter === 'e' || last.letter === 'b' || last.letter === '-') {
					this.say(`There is no ${last.letter === '-' ? 'sharp rest' : `${last.letter.toUpperCase()} sharp`} on a Nokia.`);
					return;
				}

				last.isSharp = !last.isSharp;
			} else if (key === 'c') {
				notes.pop();
			}

			show();
			const note = notes.at(-1);

			// Each key beeps the note it made, like on the phone.
			if (key !== 'c' && note && note.letter !== '-' && startAudio()) {
				const previewBus = makeBus();
				beep(note, context.currentTime + 0.02, Number(tempoSelect.value), previewBus);
				setTimeout(() => {
					previewBus.disconnect();
				}, 3000);
			}
		};

		for (const button of this.querySelectorAll('[data-nokia-key]')) {
			this.on(button, 'click', () => {
				press(button.dataset.nokiaKey);
			});
		}

		// The keys of the computer work like the keys of the phone while the focus is on the phone, but not in the text field.
		this.on(this, 'keydown', event => {
			if (isTypingTarget(event) || hasModifier(event) || !phone.contains(event.target)) {
				return;
			}

			const key = event.key === 'Backspace' || event.key === 'Delete' ? 'c' : event.key;

			if (!'0123456789*#c'.includes(key) || key.length !== 1) {
				return;
			}

			// The page has other games that listen to the number keys, like Zap the Aliens, so the key stops here.
			event.preventDefault();
			event.stopPropagation();
			const button = this.querySelector(`[data-nokia-key="${CSS.escape(key)}"]`);
			button.dataset.state = 'pressed';
			setTimeout(() => {
				delete button.dataset.state;
			}, 120);
			press(key);
		});

		this.on(text, 'input', () => {
			const result = parse(text.value);

			if (result.error) {
				status.textContent = `The phone does not understand “${result.error.slice(0, 12)}”. A note looks like 8e2 or 4.#c1, and a rest like 4-.`;
				return;
			}

			notes = result.notes.slice(0, maximumNotes);
			screenCode.textContent = notes.map(note => format(note)).join(' ') || '_';
			status.textContent = result.notes.length > maximumNotes ? 'Only the first 50 notes fit in a Nokia 3210.' : '';
			this.store('tone', {code: text.value, tempo: tempoSelect.value});
		});

		this.on(tempoSelect, 'change', show);

		this.on(play, 'click', () => {
			if (notes.length === 0) {
				this.say('There are no notes. Press the keys of the phone, or order a ringtone.');
				return;
			}

			playTune({});
			this.say('♪ Beep beep!');
		});

		this.on(clear, 'click', () => {
			notes = [];
			show();
			this.say('Cleared. Press 1 to 7 to compose.');
		});

		// Someone calls, and the phone shakes and rings with the tune until the visitor answers, rejects, or it has rung three times.
		const callers = [
			['Mamma', '“Sindre! Dinner is ready! And turn off the computer, I need the phone line.”'],
			['Mormor', '“Hello? Hello? Is this the Internet? I want to order waffles.”'],
			['Kevin from school', '“Did you get past 2,000 points in Snake? I did. Bye.”'],
			['Pappa', '“Have you seen my mobile phone?” (You are holding it.)'],
			['Unknown number', '“Congratulations! You have won a free trip to Spain! Press 1.” (It is a recording.)'],
			['Lena', '“Is your ringtone the Nokia Tune? Mine is Barbie Girl. Mine is better.”'],
		];
		let call;

		const endCall = () => {
			isRinging = false;
			delete phone.dataset.state;
			callScreen.hidden = true;
			answerButton.hidden = true;
			rejectButton.hidden = true;
		};

		this.on(ringButton, 'click', () => {
			if (notes.every(note => note.letter === '-')) {
				notes = parse(ringtones.nokia.code).notes;
				show();
			}

			// A call that rings already ends first, so the new call keeps its screen.
			player.stop();

			if (!startAudio()) {
				return;
			}

			call = randomItem(callers);
			playTune({times: 3, onEnd: () => {
				endCall();
				this.say(`1 missed call: ${call[0]}.`);
			}});
			caller.textContent = `${call[0]} calling`;
			callScreen.hidden = false;
			answerButton.hidden = false;
			rejectButton.hidden = false;
			phone.dataset.state = 'ringing';
			isRinging = true;
			this.say(`📳 ${call[0]} is calling! Answer or Reject, under the screen.`);
		});

		this.on(answerButton, 'click', () => {
			player.stop();
			this.say(`${call[0]}: ${call[1]}`);
		});

		this.on(rejectButton, 'click', () => {
			player.stop();
			this.say(`You rejected ${call[0]}. ${call[0] === 'Mamma' ? 'That is going to be a problem later.' : 'Rude, but fair.'}`);
		});

		this.on(midi, 'click', () => {
			if (notes.length === 0) {
				this.say('There are no notes to save.');
				return;
			}

			const midiNotes = [];
			let tick = 0;

			for (const note of notes) {
				const length = Math.round((4 / note.length) * 96 * (note.isDotted ? 1.5 : 1));

				if (note.letter !== '-') {
					midiNotes.push({note: noteMidi(note), start: tick, length: Math.max(1, Math.round(length * 0.9))});
				}

				tick += length;
			}

			download(midiFile({tempo: Number(tempoSelect.value), programs: {0: 80}, notes: midiNotes}), 'ringtone.mid');
			this.say('Saved ringtone.mid. Put it on your home page with <bgsound src="ringtone.mid">!');
		});

		// The ringtone ad: each tone costs 15 kroner on the phone bill. At 90 kroner, Mamma blocks the number, until the visitor pays with the allowance.
		const billLimit = 90;
		let spent = clamp(Number(this.stored('bill', 0)) || 0, 0, billLimit);
		const orderButtons = [...this.querySelectorAll('[data-nokia-tone]')];

		const showBill = () => {
			bill.textContent = spent >= billLimit ? `Phone bill: kr ${spent},-. Mamma has blocked the ringtone number!` : `Phone bill this month: kr ${spent},-`;

			for (const button of orderButtons) {
				button.disabled = spent >= billLimit;
			}

			payButton.hidden = spent < billLimit;
			this.store('bill', spent);
		};

		this.on(payButton, 'click', () => {
			spent = 0;
			showBill();
			orderButtons[0].focus();
			this.say('There goes my allowance. The ringtone number works again.');
		});

		for (const button of orderButtons) {
			this.on(button, 'click', () => {
				if (spent >= billLimit) {
					return;
				}

				const id = button.dataset.nokiaTone;
				const title = button.closest('li').querySelector('span').textContent;
				spent += 15;
				const total = spent;
				this.say(`Sending SMS: ${button.textContent} to 1999…`);

				setTimeout(() => {
					notes = parse(ringtones[id].code).notes;
					tempoSelect.value = String(ringtones[id].tempo);
					show();
					this.say(`Ringtone received: ${title}! Press Play, or Ring Me!`);

					if (total === 60) {
						this.toast('Pappa: “Why is the phone bill so high this month?”');
					}

					if (total === billLimit) {
						this.toast('Mamma: “WHO SPENT 90 KRONER ON RINGTONES?!”');
						showBill();
						return;
					}

					showBill();
				}, 1200);

				bill.textContent = `Phone bill this month: kr ${spent},-`;
			});
		}

		show();
		showBill();
	}

	// When a call ends, Answer and Reject hide, so the focus goes to Ring Me!. When the phone bill blocks the ringtones, the focus goes to the button that pays it.
	focusReplacement(control) {
		const {answer, reject, ring, pay} = this.parts;

		if (control === answer || control === reject) {
			return ring;
		}

		if (control.dataset.nokiaTone) {
			return pay;
		}

		return super.focusReplacement(control);
	}
}
