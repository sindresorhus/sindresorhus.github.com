// The sound card of Sindre’s Music Room on the 1999 page, which the toys of the room share: one audio context that starts at the first click on something that plays sound, the volume of the whole room, which all the volume sliders set, the analyser that the visualizer reads, the instruments, and the clock of the sequencers. One tune of the room plays at a time, the volume starts low, and the music stops when the visitor leaves the tab, or when other music of the page starts. Each toy is a custom element that imports what it needs from this module, so they all play through the same sound card.
const clamp = (value, minimum, maximum) => Math.min(Math.max(value, minimum), maximum);

// The frequency of a MIDI note. Note 69 is the A at 440 Hz, and each note up is a semitone, which is the twelfth root of 2 higher.
export const midiFrequency = note => 440 * (2 ** ((note - 69) / 12));
export const noteNames = ['C', 'C♯', 'D', 'D♯', 'E', 'F', 'F♯', 'G', 'G♯', 'A', 'A♯', 'B'];
export const noteName = note => `${noteNames[((note % 12) + 12) % 12]}${Math.floor(note / 12) - 1}`;

export let context;

// The volume of the whole room, which all the volume sliders set, and the analyser that the visualizer reads.
export let master;
export let analyser;
const volumeInputs = new Set();
const volumeKey = 'geocities-music-volume';

// The volume is one value for all the toys, so it is kept by its own key, not by the key of one element. The storage can be missing or full, like in a private window.
const storedVolume = (() => {
	try {
		return Number(JSON.parse(localStorage.getItem(volumeKey)) ?? 30);
	} catch {
		return 30;
	}
})();

let volume = Number.isFinite(storedVolume) ? clamp(storedVolume, 0, 100) : 30;

// The slider is a curve, as the ear hears loudness that way, and it is quiet at the start.
const volumeGain = () => ((volume / 100) ** 2) * 0.8;

// Each toy has a volume slider, and they all move together, as they set the same volume. A slider that is connected already is skipped. The `signal` of the element removes its sliders again.
export const connectVolume = (inputs, signal) => {
	for (const input of inputs) {
		if (volumeInputs.has(input)) {
			continue;
		}

		volumeInputs.add(input);
		input.value = volume;
		input.addEventListener('input', () => {
			volume = clamp(Number(input.value) || 0, 0, 100);

			for (const other of volumeInputs) {
				if (other !== input) {
					other.value = volume;
				}
			}

			master?.gain.setTargetAtTime(volumeGain(), context.currentTime, 0.02);

			try {
				localStorage.setItem(volumeKey, JSON.stringify(volume));
			} catch {}
		}, {signal});

		signal?.addEventListener('abort', () => {
			volumeInputs.delete(input);
		});
	}
};

// Starts the audio, which browsers only allow after a click. A limiter keeps many sounds at once from distorting. It returns `undefined` in a browser without Web Audio.
export const startAudio = () => {
	if (!context) {
		try {
			context = new AudioContext();
		} catch {
			return;
		}

		master = new GainNode(context, {gain: volumeGain()});
		const limiter = new DynamicsCompressorNode(context, {threshold: -10, knee: 6, ratio: 10, attack: 0.003, release: 0.2});
		analyser = new AnalyserNode(context, {fftSize: 1024, smoothingTimeConstant: 0.75});
		master.connect(limiter).connect(analyser).connect(context.destination);
	}

	context.resume();
	return context;
};

// One second of white noise, for the drums, the hiss, and the applause. The same buffer works in every audio context.
let noise;
export const noiseBuffer = audio => {
	if (!noise) {
		noise = new AudioBuffer({length: audio.sampleRate, sampleRate: audio.sampleRate});
		const samples = noise.getChannelData(0);

		for (let index = 0; index < samples.length; index++) {
			samples[index] = (Math.random() * 2) - 1;
		}
	}

	return noise;
};

// The building blocks of all the instruments. Each makes its nodes in the context of its destination, so the same sounds can also be rendered into a buffer, like the record of the turntable.

// A tone that holds, with a quick fade in and out, optionally through a filter and sliding to another frequency.
export const tone = ({frequency, time, duration, destination = master, type = 'square', volume = 0.2, attack = 0.005, release = 0.04, slideTo, detune = 0, filter}) => {
	const audio = destination.context;
	const oscillator = new OscillatorNode(audio, {type, frequency, detune});

	if (slideTo) {
		oscillator.frequency.setValueAtTime(frequency, time);
		oscillator.frequency.exponentialRampToValueAtTime(slideTo, time + duration);
	}

	const envelope = new GainNode(audio, {gain: 0});
	envelope.gain.setValueAtTime(0, time);
	envelope.gain.linearRampToValueAtTime(volume, time + attack);
	envelope.gain.setValueAtTime(volume, time + Math.max(attack, duration - release));
	envelope.gain.linearRampToValueAtTime(0, time + duration);
	const source = filter ? oscillator.connect(new BiquadFilterNode(audio, filter)) : oscillator;
	source.connect(envelope).connect(destination);
	oscillator.start(time);
	oscillator.stop(time + duration + 0.02);
	return oscillator;
};

// A tone that is plucked or struck and dies away, like a string, a bell, or a drum.
export const pluck = ({frequency, time, duration = 0.4, destination = master, type = 'triangle', volume = 0.25, slideTo, filter}) => {
	const audio = destination.context;
	const oscillator = new OscillatorNode(audio, {type, frequency});

	if (slideTo) {
		oscillator.frequency.setValueAtTime(frequency, time);
		oscillator.frequency.exponentialRampToValueAtTime(slideTo, time + duration);
	}

	const envelope = new GainNode(audio, {gain: 0});
	envelope.gain.setValueAtTime(0, time);
	envelope.gain.linearRampToValueAtTime(volume, time + 0.004);
	envelope.gain.exponentialRampToValueAtTime(0.0001, time + duration);
	const source = filter ? oscillator.connect(new BiquadFilterNode(audio, filter)) : oscillator;
	source.connect(envelope).connect(destination);
	oscillator.start(time);
	oscillator.stop(time + duration + 0.02);
};

// A burst of filtered noise, for the snare, the hi-hat, and the claps.
export const noiseHit = ({time, duration, destination = master, volume = 0.3, type = 'highpass', frequency = 2000, Q = 1}) => {
	const audio = destination.context;
	const source = new AudioBufferSourceNode(audio, {buffer: noiseBuffer(audio)});
	const envelope = new GainNode(audio, {gain: 0});
	envelope.gain.setValueAtTime(volume, time);
	envelope.gain.exponentialRampToValueAtTime(0.0001, time + duration);
	source.connect(new BiquadFilterNode(audio, {type, frequency, Q})).connect(envelope).connect(destination);
	source.start(time, Math.random() * 0.5);
	source.stop(time + duration + 0.02);
};

// A voice, made like a vocoder of the time: a buzz through two filters at the formants of a vowel, which can glide from one vowel to another, like “e” to “i” for “hey”.
const vowels = {a: [730, 1090], e: [530, 1840], i: [300, 2300], o: [570, 840], u: [320, 870], uh: [600, 1200]};

export const voice = ({frequency, time, duration, destination = master, from = 'a', to = from, volume = 0.5, slideTo, vibrato = 0}) => {
	const audio = destination.context;
	const source = new OscillatorNode(audio, {type: 'sawtooth', frequency});

	if (slideTo) {
		source.frequency.setValueAtTime(frequency, time);
		source.frequency.linearRampToValueAtTime(slideTo, time + duration);
	}

	if (vibrato) {
		const wobble = new OscillatorNode(audio, {frequency: 5.5});
		wobble.connect(new GainNode(audio, {gain: vibrato})).connect(source.detune);
		wobble.start(time);
		wobble.stop(time + duration + 0.05);
	}

	const envelope = new GainNode(audio, {gain: 0});
	envelope.gain.setValueAtTime(0, time);
	envelope.gain.linearRampToValueAtTime(volume, time + Math.min(0.03, duration / 3));
	envelope.gain.setValueAtTime(volume, time + Math.max(0.03, duration - 0.06));
	envelope.gain.linearRampToValueAtTime(0, time + duration);
	envelope.connect(destination);

	for (const index of [0, 1]) {
		const filter = new BiquadFilterNode(audio, {type: 'bandpass', frequency: vowels[from][index], Q: index === 0 ? 5 : 9});
		filter.frequency.setValueAtTime(vowels[from][index], time);
		filter.frequency.linearRampToValueAtTime(vowels[to][index], time + duration);
		source.connect(filter).connect(new GainNode(audio, {gain: index === 0 ? 3 : 2})).connect(envelope);
	}

	source.start(time);
	source.stop(time + duration + 0.05);
};

// The drums of a drum machine, all made from sine waves and noise.
export const drums = {
	kick(time, destination = master, volume = 0.9) {
		const audio = destination.context;
		const oscillator = new OscillatorNode(audio, {type: 'sine', frequency: 150});
		oscillator.frequency.setValueAtTime(150, time);
		oscillator.frequency.exponentialRampToValueAtTime(45, time + 0.12);
		const envelope = new GainNode(audio, {gain: 0});
		envelope.gain.setValueAtTime(volume, time);
		envelope.gain.exponentialRampToValueAtTime(0.0001, time + 0.35);
		oscillator.connect(envelope).connect(destination);
		oscillator.start(time);
		oscillator.stop(time + 0.4);
	},
	snare(time, destination = master, volume = 0.45) {
		noiseHit({time, duration: 0.16, destination, volume, frequency: 1500});
		pluck({frequency: 190, time, duration: 0.1, destination, volume: volume * 0.7});
	},
	clap(time, destination = master, volume = 0.4) {
		for (const delay of [0, 0.012, 0.024]) {
			noiseHit({time: time + delay, duration: delay === 0.024 ? 0.14 : 0.02, destination, volume, type: 'bandpass', frequency: 1400, Q: 2});
		}
	},
	hat(time, destination = master, volume = 0.18) {
		noiseHit({time, duration: 0.04, destination, volume, frequency: 7500});
	},
	openHat(time, destination = master, volume = 0.15) {
		noiseHit({time, duration: 0.22, destination, volume, frequency: 7000});
	},
	shaker(time, destination = master, volume = 0.1) {
		noiseHit({time, duration: 0.05, destination, volume, type: 'bandpass', frequency: 6000, Q: 3});
	},
	tom(time, destination = master, volume = 0.6, frequency = 140) {
		pluck({frequency, slideTo: frequency * 0.6, time, duration: 0.3, destination, type: 'sine', volume});
	},
	cowbell(time, destination = master, volume = 0.12) {
		for (const frequency of [540, 800]) {
			pluck({frequency, time, duration: 0.25, destination, type: 'square', volume, filter: {type: 'bandpass', frequency: 900, Q: 3}});
		}
	},
};

// The chords that the toys use, as MIDI notes, with the root first.
export const chords = {
	C: [48, 52, 55],
	Dm: [50, 53, 57],
	D: [50, 54, 57],
	F: [53, 57, 60],
	G: [55, 59, 62],
	Am: [57, 60, 64],
};

// One tune plays at a time: a toy that starts its music stops the music of the others, and a `geocities-music` event stops the other music of the page, like the jukebox.
const players = new Set();

export const startPlaying = player => {
	for (const other of [...players]) {
		if (other !== player) {
			other.stop();
		}
	}

	players.add(player);
	document.dispatchEvent(new CustomEvent('geocities-music', {detail: {isPlaying: true, source: 'music-room'}}));
};

// When the last tune of the room stops, the page hears it too, like the screen saver, which waits while music plays.
export const stopPlaying = player => {
	players.delete(player);

	if (players.size === 0) {
		document.dispatchEvent(new CustomEvent('geocities-music', {detail: {isPlaying: false, source: 'music-room'}}));
	}
};

// Each tune plays into its own bus, so a stop fades it out at once, also the notes that were scheduled ahead.
export const makeBus = (destination = master) => {
	const bus = new GainNode(context);
	bus.connect(destination);
	return bus;
};

export const fadeOut = bus => {
	if (!bus) {
		return;
	}

	bus.gain.setTargetAtTime(0, context.currentTime, 0.02);
	setTimeout(() => {
		bus.disconnect();
	}, 300);
};

// Plays steps, like the sixteenth notes of a sequencer, a little ahead of time: a timer looks ahead 0.15 seconds every 25 milliseconds and schedules the steps that start in that time with the exact clock of the audio, so the rhythm stays tight even when the timer is late. `atTime` runs a function for the screen when the step is heard.
export class Clock {
	#timer;
	#visuals = new Set();

	constructor({stepLength, onStep}) {
		this.stepLength = stepLength;
		this.onStep = onStep;
		this.isRunning = false;
	}

	start(delay = 0.08) {
		this.stop();
		this.isRunning = true;
		this.step = 0;
		this.nextTime = context.currentTime + delay;
		this.#timer = setInterval(() => {
			this.#schedule();
		}, 25);
		this.#schedule();
	}

	#schedule() {
		while (this.isRunning && this.nextTime < context.currentTime + 0.15) {
			const {step, nextTime} = this;
			this.nextTime += this.stepLength(step);
			this.step++;
			this.onStep(step, nextTime);
		}
	}

	stop() {
		this.isRunning = false;
		clearInterval(this.#timer);

		for (const timer of this.#visuals) {
			clearTimeout(timer);
		}

		this.#visuals.clear();
	}

	atTime(time, callback) {
		const timer = setTimeout(() => {
			this.#visuals.delete(timer);
			callback();
		}, Math.max(0, (time - context.currentTime) * 1000));
		this.#visuals.add(timer);
	}
}

// Saves a MIDI file of notes, so the visitor can put the song on a home page with `<bgsound>`, like in 1999. It is a standard MIDI file of type 0, with 96 ticks for each quarter note. Each note has a start and a length in ticks, a MIDI channel (9 is the drums), and a velocity.
export const midiFile = ({tempo, programs, notes}) => {
	const variableLength = value => {
		const bytes = [value & 0x7F];

		while ((value >>= 7) > 0) {
			bytes.unshift((value & 0x7F) | 0x80);
		}

		return bytes;
	};

	const events = [];
	const microsecondsPerBeat = Math.round(60_000_000 / tempo);
	events.push({tick: 0, order: 0, bytes: [0xFF, 0x51, 0x03, (microsecondsPerBeat >> 16) & 0xFF, (microsecondsPerBeat >> 8) & 0xFF, microsecondsPerBeat & 0xFF]});

	for (const [channel, program] of Object.entries(programs)) {
		events.push({tick: 0, order: 1, bytes: [0xC0 | Number(channel), program]});
	}

	for (const {note, start, length, channel = 0, velocity = 100} of notes) {
		events.push({tick: start, order: 3, bytes: [0x90 | channel, note, velocity]}, {tick: start + length, order: 2, bytes: [0x80 | channel, note, 0]});
	}

	// The note offs at a tick come before the note ons, so a note that repeats is played again.
	events.sort((first, second) => (first.tick - second.tick) || (first.order - second.order));

	const track = [];
	let lastTick = 0;

	for (const event of events) {
		track.push(...variableLength(event.tick - lastTick), ...event.bytes);
		lastTick = event.tick;
	}

	track.push(0x00, 0xFF, 0x2F, 0x00);

	const header = [0x4D, 0x54, 0x68, 0x64, 0, 0, 0, 6, 0, 0, 0, 1, 0, 96];
	const length = track.length;
	return new Uint8Array([...header, 0x4D, 0x54, 0x72, 0x6B, (length >> 24) & 0xFF, (length >> 16) & 0xFF, (length >> 8) & 0xFF, length & 0xFF, ...track]);
};

export const download = (bytes, fileName) => {
	const url = URL.createObjectURL(new Blob([bytes], {type: 'audio/midi'}));
	const link = document.createElement('a');
	link.href = url;
	link.download = fileName;
	link.click();
	setTimeout(() => {
		URL.revokeObjectURL(url);
	}, 1000);
};

// The music stops when the visitor leaves the tab, and when other music of the page starts, like the jukebox of `geocities.js`.
const stopHandlers = new Set();

// Adds a handler that runs when all the music stops, like for a key that is held, until the `signal` of its element aborts.
export const addStopHandler = (handler, signal) => {
	stopHandlers.add(handler);
	signal?.addEventListener('abort', () => {
		stopHandlers.delete(handler);
	});
};

export const stopEverything = () => {
	for (const player of [...players]) {
		player.stop();
	}

	for (const handler of stopHandlers) {
		handler();
	}
};

document.addEventListener('visibilitychange', () => {
	if (document.hidden) {
		stopEverything();
	}
});

document.addEventListener('geocities-music', event => {
	if (event.detail.isPlaying && event.detail.source !== 'music-room') {
		stopEverything();
	}
});
