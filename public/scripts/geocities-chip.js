// A chip with four channels, like the music of the demos and the keygens, made with the Web Audio API: a square lead, a thin square that plays a chord as a fast arpeggio, a triangle bass, and drums of noise. The intro (`Cracktro.js`) and the keygen (`Keygen.js`) of the 1999 page play their own songs with it. A song starts only when the visitor presses the button that plays music.
import {midiFrequency} from '/scripts/geocities-element.js';

// One second of white noise for the drums. The same buffer works in every audio context.
let noiseBuffer;

const makeNoise = context => {
	const buffer = context.createBuffer(1, context.sampleRate, context.sampleRate);
	const samples = buffer.getChannelData(0);

	for (let index = 0; index < samples.length; index++) {
		samples[index] = (Math.random() * 2) - 1;
	}

	return buffer;
};

// A square wave with a pulse of 12.5%, the thin and nasal sound of the arpeggios of keygen music. A wave works only in the audio context that made it, so there is one for each context.
const thinPulses = new WeakMap();

const thinPulseWave = context => {
	let wave = thinPulses.get(context);

	if (!wave) {
		const harmonics = 32;
		const real = new Float32Array(harmonics);
		const imaginary = new Float32Array(harmonics);

		for (let harmonic = 1; harmonic < harmonics; harmonic++) {
			imaginary[harmonic] = (2 / (harmonic * Math.PI)) * Math.sin(harmonic * Math.PI * 0.125);
		}

		wave = context.createPeriodicWave(real, imaginary);
		thinPulses.set(context, wave);
	}

	return wave;
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
		playOscillator(output, {type: 'square', frequencies: [midiFrequency(note)], time, duration, peak: 0.1});
	},
	// The arpeggio.
	(output, note, time, duration) => {
		playOscillator(output, {wave: thinPulseWave(output.context), frequencies: chordSteps(note).map(step => midiFrequency(note + step)), time, duration, peak: 0.09});
	},
	// The bass.
	(output, note, time, duration) => {
		playOscillator(output, {type: 'triangle', frequencies: [midiFrequency(note)], time, duration, peak: 0.35});
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
export const pattern = (...lines) => lines.map(line => line.trim().split(/\s+/).map(token => parseNote(token)));

// How long a note plays: until the next note of its channel, but at most a beat, as the patterns have no note-off.
const noteRows = (channelNotes, row) => {
	for (let length = 1; length < 4; length++) {
		if (row + length >= channelNotes.length || channelNotes[row + length] !== null) {
			return length;
		}
	}

	return 4;
};

// The song that plays now in each audio context, so a song that stops frees the audio device only when no other song started in the same context.
const currentPlayers = new WeakMap();

/**
Plays the song, like `{bpm: 125, patterns: [groove, anthem]}`, in a loop with the audio of the element, until `stop()`.
*/
export const playSong = (element, {context, output}, song) => {
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

			if (currentPlayers.get(context) === player) {
				currentPlayers.delete(context);
			}

			// After the fade, the audio device is freed until the next song, unless one started in the meantime. It is a plain timer, as it also frees it after the element was removed.
			setTimeout(() => {
				master.disconnect();

				if (!currentPlayers.has(context)) {
					context.suspend();
				}
			}, 200);
		},
	};

	currentPlayers.set(context, player);
	return player;
};
