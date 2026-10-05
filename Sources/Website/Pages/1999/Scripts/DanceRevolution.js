// Dans Dans Revolusjon on the 1999 page: my own Dance Dance Revolution. The songs are made in the browser, the step charts are made from the beat and the tune of each song, and each step is judged by the clock of the sound. The screen is drawn on a canvas, which runs only while it is on the screen and the tab is visible. The settings, the delay, the kroner, and the best scores are kept in the browser.

const randomItem = items => items[Math.floor(Math.random() * items.length)];
const clamp = (value, minimum, maximum) => Math.min(Math.max(value, minimum), maximum);

// Shows a toggle button as pressed, for screen readers and for the style.
const setPressed = (button, isPressed) => {
	button.setAttribute('aria-pressed', String(isPressed));
	button.dataset.state = isPressed ? 'on' : '';
};

// A random number generator with a seed, so a song and a difficulty always have the same steps, like the real machine.
const seededRandom = text => {
	let seed = 2_166_136_261;
	for (const character of text) {
		seed = Math.imul(seed ^ character.codePointAt(0), 16_777_619);
	}

	return () => {
		seed = (seed + 0x6D_2B_79_F5) | 0;
		let value = Math.imul(seed ^ (seed >>> 15), 1 | seed);
		value = (value + Math.imul(value ^ (value >>> 7), 61 | value)) ^ value;
		return ((value ^ (value >>> 14)) >>> 0) / 4_294_967_296;
	};
};

// Picks one of the choices by its weight, like `[[choice, 2], [other, 1]]`.
const weightedPick = (choices, random) => {
	let total = 0;
	for (const [, weight] of choices) {
		total += weight;
	}

	let value = random() * total;
	for (const [choice, weight] of choices) {
		value -= weight;
		if (value < 0) {
			return choice;
		}
	}

	return choices.at(-1)[0];
};

// A tiny pixel font of 3 × 5 for the screen of the machine, so the text is crisp at any size. Each letter is five rows of three bits.
const pixelFont = {
	A: [2, 5, 7, 5, 5], B: [6, 5, 6, 5, 6], C: [3, 4, 4, 4, 3], D: [6, 5, 5, 5, 6], E: [7, 4, 6, 4, 7], F: [7, 4, 6, 4, 4], G: [3, 4, 5, 5, 3], H: [5, 5, 7, 5, 5], I: [7, 2, 2, 2, 7], J: [1, 1, 1, 5, 2], K: [5, 5, 6, 5, 5], L: [4, 4, 4, 4, 7], M: [5, 7, 7, 5, 5], N: [6, 5, 5, 5, 5], O: [2, 5, 5, 5, 2], P: [6, 5, 6, 4, 4], Q: [2, 5, 5, 6, 3], R: [6, 5, 6, 5, 5], S: [3, 4, 2, 1, 6], T: [7, 2, 2, 2, 2], U: [5, 5, 5, 5, 7], V: [5, 5, 5, 5, 2], W: [5, 5, 7, 7, 5], X: [5, 5, 2, 5, 5], Y: [5, 5, 2, 2, 2], Z: [7, 1, 2, 4, 7],
	0: [7, 5, 5, 5, 7], 1: [2, 6, 2, 2, 7], 2: [6, 1, 2, 4, 7], 3: [6, 1, 2, 1, 6], 4: [5, 5, 7, 1, 1], 5: [7, 4, 6, 1, 6], 6: [3, 4, 7, 5, 7], 7: [7, 1, 2, 2, 2], 8: [7, 5, 7, 5, 7], 9: [7, 5, 7, 1, 6],
	' ': [0, 0, 0, 0, 0], '.': [0, 0, 0, 0, 2], ',': [0, 0, 0, 2, 4], '!': [2, 2, 2, 0, 2], '?': [6, 1, 2, 0, 2], ':': [0, 2, 0, 2, 0], '-': [0, 0, 7, 0, 0], '+': [0, 2, 7, 2, 0], '/': [1, 1, 2, 4, 4], '\'': [2, 2, 0, 0, 0], '(': [1, 2, 2, 2, 1], ')': [4, 2, 2, 2, 4], '×': [0, 5, 2, 5, 0], '%': [5, 1, 2, 4, 5], '<': [1, 2, 4, 2, 1], '>': [4, 2, 1, 2, 4], '=': [0, 7, 0, 7, 0], '*': [0, 5, 2, 5, 0],
	Æ: [3, 6, 7, 6, 7], Ø: [3, 5, 7, 5, 6], Å: [2, 0, 2, 5, 7],
};

// The width of a text in the pixel font, in pixels.
const pixelTextWidth = (text, scale = 1) => (([...String(text)].length * 4) - 1) * scale;

// Draws text in the pixel font, at a whole pixel, with a scale for bigger letters, and a dark shadow so it reads on the busy background. The alignment is `left`, `center`, or `right`.
const drawPixelText = (context, text, x, y, color, {scale = 1, align = 'left', shadow = '#000000'} = {}) => {
	const characters = [...String(text).toUpperCase()];
	const width = pixelTextWidth(text, scale);
	const left = Math.round(align === 'center' ? x - (width / 2) : (align === 'right' ? x - width : x));
	const passes = shadow ? [[shadow, Math.max(1, Math.floor(scale / 2))], [color, 0]] : [[color, 0]];

	for (const [fill, offset] of passes) {
		context.fillStyle = fill;
		let characterLeft = left;
		for (const character of characters) {
			const rows = pixelFont[character] ?? pixelFont['?'];
			for (const [row, bits] of rows.entries()) {
				for (let column = 0; column < 3; column++) {
					if (bits & (4 >> column)) {
						context.fillRect(characterLeft + (column * scale) + offset, Math.round(y) + (row * scale) + offset, scale, scale);
					}
				}
			}

			characterLeft += 4 * scale;
		}
	}
};

// MARK: The songs

// A note name, like `C#5`, as a MIDI note number.
const noteNumber = name => {
	const letters = {C: 0, D: 2, E: 4, F: 5, G: 7, A: 9, B: 11};
	let semitone = letters[name[0]];
	let index = 1;
	if (name[index] === '#') {
		semitone++;
		index++;
	} else if (name[index] === 'b') {
		semitone--;
		index++;
	}

	return (12 * (Number(name.slice(index)) + 1)) + semitone;
};

const frequencyOf = note => 440 * (2 ** ((note - 69) / 12));

// A phrase of a tune, written as notes and their lengths in sixteenths, like `C5:2 -:2 E5:4`, where `-` is a rest.
const parsePhrase = text => {
	const notes = [];
	let position = 0;
	for (const token of text.trim().split(' ')) {
		if (token === '') {
			continue;
		}

		const [name, length] = token.split(':');
		const sixteenths = Number(length);
		if (name !== '-') {
			notes.push({position, length: sixteenths, pitch: noteNumber(name)});
		}

		position += sixteenths;
	}

	return notes;
};

const parseChord = text => text.split(' ').map(name => noteNumber(name));

// The form of every song of the machine, in bars of four beats. The last chorus has the key change, as every Eurodance song must.
const structure = [
	{name: 'intro', bars: 4},
	{name: 'verse', bars: 8},
	{name: 'build', bars: 4},
	{name: 'chorus', bars: 8},
	{name: 'break', bars: 4},
	{name: 'chorus', bars: 8, transpose: 2},
	{name: 'end', bars: 1},
];

// Each bar with its section and its place in the section.
const bars = structure.flatMap(section => Array.from({length: section.bars}, (_, barInSection) => ({section, barInSection})));

// The songs are my own: a plastic princess, a butterfly in a high voice, and a rave in the rain of Bergen. Each has a tune for the verse (2 bars) and for the chorus (4 bars), the chords of 4 bars, and its own sounds.
const songs = {
	prinsesse: {
		title: 'Plastikk-Prinsesse',
		artist: 'Vannmelon',
		bpm: 126,
		chords: ['E4 G#4 B4', 'B3 D#4 F#4', 'C#4 E4 G#4', 'A3 C#4 E4'].map(chord => parseChord(chord)),
		verse: parsePhrase('B4:2 B4:2 E5:2 B4:2 C#5:4 B4:4 G#4:2 G#4:2 B4:2 G#4:2 A4:4 F#4:4'),
		chorus: parsePhrase('E5:3 E5:1 F#5:2 G#5:2 B5:4 G#5:4 F#5:2 F#5:2 G#5:2 F#5:2 D#5:8 C#5:3 C#5:1 D#5:2 E5:2 G#5:4 E5:2 C#5:2 B4:2 C#5:2 E5:4 E5:8'),
		bass: 'bounce',
		stabs: [0, 3, 6, 10, 12],
		lead: 'bubble',
		background: ['#ff66cc', '#ffccee', '#cc33ff'],
	},
	sommerfugl: {
		title: 'Sommerfugl',
		artist: 'Smilefjes',
		bpm: 138,
		chords: ['A3 C4 E4', 'F3 A3 C4', 'C4 E4 G4', 'G3 B3 D4'].map(chord => parseChord(chord)),
		verse: parsePhrase('A5:2 C6:2 A5:2 G5:2 E5:4 G5:4 A5:2 C6:2 D6:2 C6:2 A5:8'),
		chorus: parsePhrase('E6:2 D6:2 C6:2 A5:2 C6:2 D6:2 E6:4 D6:2 C6:2 A5:2 G5:2 A5:8 C6:1 C6:1 C6:2 D6:2 E6:2 G6:4 E6:4 D6:2 E6:2 D6:2 C6:2 A5:8'),
		bass: 'offbeat',
		stabs: [0, 2, 6, 8, 11, 14],
		lead: 'chipmunk',
		background: ['#33ccff', '#ffff66', '#66ff99'],
	},
	regn: {
		title: 'Regnværs-Rave',
		artist: 'DJ Paraply',
		bpm: 155,
		chords: ['D4 F4 A4', 'Bb3 D4 F4', 'C4 E4 G4', 'A3 C#4 E4'].map(chord => parseChord(chord)),
		verse: parsePhrase('D5:1 F5:1 A5:2 D5:1 F5:1 A5:2 C5:1 E5:1 G5:2 C5:2 A4:2 Bb4:1 D5:1 F5:2 Bb4:1 D5:1 F5:2 A4:2 C#5:2 E5:4'),
		chorus: parsePhrase('D5:4 A5:4 G5:2 F5:2 E5:4 F5:2 E5:2 D5:2 C5:2 D5:8 D5:4 A5:4 Bb5:2 A5:2 G5:4 A5:2 G5:2 F5:4 E5:8'),
		bass: 'gallop',
		stabs: [0, 3, 6, 8, 11, 14],
		lead: 'hoover',
		hasRain: true,
		background: ['#3366ff', '#33ffcc', '#9966ff'],
	},
};

const difficultyNames = {basic: 'Basic', trick: 'Trick', maniac: 'Maniac'};

for (const song of Object.values(songs)) {
	song.sixteenth = 60 / song.bpm / 4;
	song.beat = 60 / song.bpm;
	song.duration = bars.length * 16 * song.sixteenth;
}

// MARK: The step charts

// The colors of the real arrows: red on the beat, blue between the beats, and yellow for the sixteenths.
const arrowColor = position => {
	if (position % 4 === 0) {
		return 'red';
	}

	return position % 2 === 0 ? 'blue' : 'yellow';
};

// The notes of the tune that start in a bar of a phrase, with their place in the bar.
const melodyInBar = (phrase, barInPhrase) => phrase
	.filter(note => Math.floor(note.position / 16) === barInPhrase)
	.map(note => ({position: note.position % 16, length: note.length}));

const beats = [0, 4, 8, 12];
const eighths = [0, 2, 4, 6, 8, 10, 12, 14];

// The rows of steps of a chart, from the beat and the tune of the song. A row has a place in sixteenths, a length if it is a freeze arrow, and whether it wants to be a jump.
const chartRows = (song, difficulty) => {
	const rows = [];
	const add = (position, {length = 0, wantsJump = false} = {}) => {
		rows.push({position, length, wantsJump});
	};

	for (const [bar, {section, barInSection}] of bars.entries()) {
		const base = bar * 16;
		const addEach = positions => {
			for (const position of positions) {
				add(base + position);
			}
		};

		const isBasic = difficulty === 'basic';
		const isManiac = difficulty === 'maniac';
		switch (section.name) {
			case 'intro': {
				// The first two bars are for “Ready” and “Here we go!”.
				if (barInSection >= 2) {
					addEach(isBasic ? [0, 8] : (isManiac ? [0, 4, 8, 10, 12, 14] : beats));
				}

				break;
			}

			case 'verse': {
				const melody = melodyInBar(song.verse, barInSection % 2);
				if (isBasic) {
					addEach(barInSection < 4 ? [0, 8] : beats);
				} else {
					addEach(beats);
					for (const note of melody) {
						if (isManiac || note.position % 2 === 0) {
							add(base + note.position);
						}
					}
				}

				break;
			}

			case 'build': {
				if (isBasic) {
					addEach(barInSection < 3 ? [0, 8] : beats);
				} else if (isManiac) {
					addEach(barInSection < 3 ? eighths : [0, 2, 4, 6, 8, 9, 10, 11, 12, 13, 14, 15]);
				} else {
					addEach(barInSection < 2 ? beats : eighths);
				}

				break;
			}

			case 'chorus': {
				const barInPhrase = barInSection % 4;
				const melody = melodyInBar(song.chorus, barInPhrase);
				const jumpEvery = isBasic ? 4 : (isManiac ? 1 : 2);
				add(base, {wantsJump: barInSection % jumpEvery === 0});
				addEach([4, 8, 12]);
				if (!isBasic) {
					for (const note of melody) {
						if (isManiac || note.position % 2 === 0) {
							add(base + note.position);
						}
					}
				}

				// The long notes at the end of a line of the chorus are freeze arrows.
				const longest = isBasic ? 8 : 6;
				for (const note of melody) {
					if (note.length >= longest && (!isBasic || barInPhrase === 3)) {
						add(base + note.position, {length: note.length - 2});
					}
				}

				if (isManiac && barInPhrase === 1) {
					add(base + 8, {wantsJump: true});
				}

				break;
			}

			case 'break': {
				// The quiet part is for holding: freeze arrows on the chords, and a run into the last chorus.
				if (barInSection < 3) {
					if (isBasic) {
						if (barInSection !== 1) {
							add(base, {length: 24});
						}
					} else {
						add(base, {length: 12});
						if (isManiac) {
							addEach([4, 8, 12]);
						}
					}
				} else {
					addEach(isBasic ? beats : (isManiac ? [0, 2, 4, 6, 8, 10, 12, 13, 14, 15] : eighths));
				}

				break;
			}

			default: {
				add(base, {wantsJump: true});
			}
		}
	}

	// Rows at the same place become one, which keeps the longest freeze and the wish for a jump.
	rows.sort((first, second) => first.position - second.position);
	const merged = [];
	for (const row of rows) {
		const last = merged.at(-1);
		if (last?.position === row.position) {
			last.length = Math.max(last.length, row.length);
			last.wantsJump ||= row.wantsJump;
		} else {
			merged.push({...row});
		}
	}

	return merged;
};

// The jumps that feel good on a pad, with how often they come: left and right is the classic.
const jumpPairs = [[[0, 3], 5], [[1, 2], 2], [[0, 2], 1], [[0, 1], 1], [[1, 3], 1], [[2, 3], 1]];

// Puts the rows of a chart on arrows like a dancer would step: the feet take turns, the left foot never crosses to the right arrow and the other way around, a fast step never hits the same arrow twice in a row, and a jump only comes with time before and after it.
const makeChart = (songId, difficulty) => {
	const song = songs[songId];
	const random = seededRandom(`${songId}/${difficulty}`);
	const rows = chartRows(song, difficulty);
	const isManiac = difficulty === 'maniac';
	const jumpGap = difficulty === 'basic' ? 4 : 2;
	const footLanes = {left: [0, 1, 2], right: [3, 1, 2]};
	const homeLane = {left: 0, right: 3};
	const feet = {left: 0, right: 3};
	const notes = [];
	let nextFoot = 'left';
	let lastLane;
	let lastPosition = -99;
	let frozen;

	const makeNote = (row, lane) => ({
		time: row.position * song.sixteenth,
		lane,
		color: arrowColor(row.position),
		length: row.length * song.sixteenth,
		end: row.position + row.length,
	});

	for (const [index, row] of rows.entries()) {
		if (frozen && row.position >= frozen.end) {
			frozen = undefined;
		}

		// While a freeze arrow is held, only Maniac has steps for the other foot, and only on the beat.
		if (frozen && (!isManiac || row.position % 4 !== 0 || row.length > 0)) {
			continue;
		}

		// A step right as a freeze arrow ends is too much for the feet, and soon after it, no step or jump is on the arrow that was held.
		const endedFreeze = frozen ? undefined : notes.findLast(note => note.length > 0 && note.end <= row.position + 1 && row.position - note.end < 4);
		if (endedFreeze && row.position - endedFreeze.end < 2) {
			continue;
		}

		const gap = row.position - lastPosition;
		const nextGap = (rows[index + 1]?.position ?? 9999) - row.position;
		if (row.wantsJump && !frozen && row.length === 0 && gap >= jumpGap && nextGap >= jumpGap) {
			// Right after a step or a freeze arrow, a jump lands on other arrows than that one.
			const pairs = jumpPairs.filter(([pair]) => !(gap <= 2 && pair.includes(lastLane)) && !pair.includes(endedFreeze?.lane));
			const pair = weightedPick(pairs, random);
			feet.left = pair[0];
			feet.right = pair[1];
			for (const lane of pair) {
				notes.push(makeNote(row, lane));
			}

			nextFoot = random() < 0.5 ? 'left' : 'right';
			lastLane = undefined;
			lastPosition = row.position;
			continue;
		}

		const foot = frozen ? (frozen.foot === 'left' ? 'right' : 'left') : nextFoot;
		const otherFoot = foot === 'left' ? 'right' : 'left';
		let options = footLanes[foot].filter(lane => lane !== feet[otherFoot] && lane !== frozen?.lane && lane !== endedFreeze?.lane);
		const withoutJack = options.filter(lane => lane !== lastLane && lane !== feet[foot]);
		if (withoutJack.length > 0 && (gap <= 4 || random() < 0.85)) {
			options = withoutJack;
		}

		if (options.length === 0) {
			options = [homeLane[foot]];
		}

		const lane = weightedPick(options.map(option => [option, option === homeLane[foot] ? 2 : 1]), random);
		notes.push(makeNote(row, lane));
		feet[foot] = lane;
		lastLane = lane;
		lastPosition = row.position;
		if (row.length > 0) {
			frozen = {foot, lane, end: row.position + row.length};
		}

		nextFoot = otherFoot;
	}

	return notes;
};

const charts = new Map();

const chartFor = (songId, difficulty) => {
	const key = `${songId}/${difficulty}`;
	if (!charts.has(key)) {
		charts.set(key, makeChart(songId, difficulty));
	}

	return charts.get(key);
};

const ratings = new Map();

// The rating in feet, like on the song wheel, from how many steps a second (a jump is two) and the fast arrows.
const footRating = (songId, difficulty) => {
	const key = `${songId}/${difficulty}`;
	if (!ratings.has(key)) {
		ratings.set(key, rateChart(songId, difficulty));
	}

	return ratings.get(key);
};

const rateChart = (songId, difficulty) => {
	const notes = chartFor(songId, difficulty);
	const song = songs[songId];
	const seconds = song.duration - (2 * 16 * song.sixteenth);
	const stepsPerSecond = notes.length / seconds;
	const fastSteps = notes.filter(note => note.color === 'yellow').length;
	return clamp(Math.round((stepsPerSecond * 1.6) + (fastSteps / 25) - 0.5), 1, 10);
};

// MARK: The sound

// One note of an instrument, with a soft start and end, and an optional vibrato or detune.
const tone = (destination, frequency, start, duration, {type = 'square', volume = 0.05, attack = 0.005, vibrato = 0, detune = 0, lowpass, q = 1} = {}) => {
	const audioContext = destination.context;
	const oscillator = new OscillatorNode(audioContext, {type, frequency, detune});
	const gain = new GainNode(audioContext, {gain: 0});
	gain.gain.setValueAtTime(0, start);
	gain.gain.linearRampToValueAtTime(volume, start + attack);
	gain.gain.setValueAtTime(volume, Math.max(start + attack, start + duration - 0.04));
	gain.gain.exponentialRampToValueAtTime(0.0001, start + duration);
	let output = oscillator.connect(gain);
	if (lowpass) {
		output = output.connect(new BiquadFilterNode(audioContext, {type: 'lowpass', frequency: lowpass, Q: q}));
	}

	output.connect(destination);
	if (vibrato > 0) {
		const wobble = new OscillatorNode(audioContext, {frequency: 6});
		const depth = new GainNode(audioContext, {gain: vibrato});
		wobble.connect(depth).connect(oscillator.frequency);
		wobble.start(start);
		wobble.stop(start + duration + 0.05);
	}

	oscillator.start(start);
	oscillator.stop(start + duration + 0.05);
};

// A pluck, which starts loud and fades at once, like the piano of a Eurodance record.
const pluck = (destination, frequency, start, duration, {type = 'square', volume = 0.05, lowpass = 2400} = {}) => {
	const audioContext = destination.context;
	const oscillator = new OscillatorNode(audioContext, {type, frequency});
	const filter = new BiquadFilterNode(audioContext, {type: 'lowpass', frequency: lowpass});
	const gain = new GainNode(audioContext, {gain: 0});
	gain.gain.setValueAtTime(volume, start);
	gain.gain.exponentialRampToValueAtTime(0.0001, start + duration);
	oscillator.connect(filter).connect(gain).connect(destination);
	oscillator.start(start);
	oscillator.stop(start + duration + 0.05);
};

// A second of white noise for each audio context, for the drums, the riser, and the rain of Bergen.
const noiseBuffers = new WeakMap();

const noiseBuffer = audioContext => {
	if (!noiseBuffers.has(audioContext)) {
		const buffer = new AudioBuffer({length: audioContext.sampleRate, sampleRate: audioContext.sampleRate});
		const data = buffer.getChannelData(0);
		for (let index = 0; index < data.length; index++) {
			data[index] = (Math.random() * 2) - 1;
		}

		noiseBuffers.set(audioContext, buffer);
	}

	return noiseBuffers.get(audioContext);
};

// A burst of noise through a filter, for the drums, the riser, and the rain of Bergen. The volume can rise slowly, and the filter can sweep.
const noise = (destination, start, duration, {volume = 0.1, type = 'highpass', frequency = 6000, q = 1, sweepTo, attack = 0.002, isSustained = false} = {}) => {
	const audioContext = destination.context;
	const source = new AudioBufferSourceNode(audioContext, {buffer: noiseBuffer(audioContext), loop: true});
	const filter = new BiquadFilterNode(audioContext, {type, frequency, Q: q});
	if (sweepTo) {
		filter.frequency.setValueAtTime(frequency, start);
		filter.frequency.exponentialRampToValueAtTime(sweepTo, start + duration);
	}

	const gain = new GainNode(audioContext, {gain: 0});
	gain.gain.setValueAtTime(0, start);
	gain.gain.linearRampToValueAtTime(volume, start + Math.min(attack, duration * 0.95));
	// A sustained noise, like the rain, holds its volume until a short fade at the end.
	if (isSustained) {
		gain.gain.setValueAtTime(volume, Math.max(start + attack, start + duration - 0.5));
	}

	gain.gain.exponentialRampToValueAtTime(0.0001, start + duration);
	source.connect(filter).connect(gain).connect(destination);
	source.start(start, Math.random() * 0.5);
	source.stop(start + duration + 0.05);
};

const kick = (destination, start, volume = 0.7) => {
	const audioContext = destination.context;
	const oscillator = new OscillatorNode(audioContext, {type: 'sine', frequency: 160});
	oscillator.frequency.setValueAtTime(160, start);
	oscillator.frequency.exponentialRampToValueAtTime(42, start + 0.11);
	const gain = new GainNode(audioContext, {gain: 0});
	gain.gain.setValueAtTime(volume, start);
	gain.gain.exponentialRampToValueAtTime(0.0001, start + 0.28);
	oscillator.connect(gain).connect(destination);
	oscillator.start(start);
	oscillator.stop(start + 0.3);
};

// The clap of a drum machine: three quick bursts of noise.
const clap = (destination, start, volume = 0.25) => {
	for (const [index, offset] of [0, 0.011, 0.022].entries()) {
		noise(destination, start + offset, index === 2 ? 0.14 : 0.02, {volume, type: 'bandpass', frequency: 1300, q: 0.9});
	}
};

// Plays one event of a song: a drum, a bass note, a chord, or a note of the tune.
const playEvent = (event, start, destination, song) => {
	const {voice} = event;
	switch (voice) {
		case 'kick': {
			kick(destination, start);
			break;
		}

		case 'clap': {
			clap(destination, start);
			break;
		}

		case 'snare': {
			noise(destination, start, 0.12, {volume: event.volume ?? 0.2, type: 'bandpass', frequency: 1800, q: 0.7});
			break;
		}

		case 'hat': {
			noise(destination, start, event.isOpen ? 0.11 : 0.03, {volume: event.isOpen ? 0.08 : 0.04, type: 'highpass', frequency: 7500});
			break;
		}

		case 'crash': {
			noise(destination, start, 1.6, {volume: 0.12, type: 'highpass', frequency: 4500});
			break;
		}

		case 'riser': {
			noise(destination, start, event.duration, {volume: 0.09, type: 'bandpass', frequency: 400, sweepTo: 7000, q: 2, attack: event.duration * 0.92});
			break;
		}

		case 'rain': {
			noise(destination, start, event.duration, {volume: 0.05, type: 'lowpass', frequency: 2600, attack: 1, isSustained: true});
			break;
		}

		case 'drop': {
			noise(destination, start, 0.02, {volume: 0.05, type: 'bandpass', frequency: 3000 + (Math.random() * 3000), q: 4});
			break;
		}

		case 'bass': {
			tone(destination, frequencyOf(event.pitch), start, event.duration, {type: 'sawtooth', volume: 0.16, lowpass: song.bass === 'gallop' ? 500 : 800, q: 5});
			break;
		}

		case 'stab': {
			for (const pitch of event.chord) {
				pluck(destination, frequencyOf(pitch + 12), start, 0.3, {type: 'square', volume: 0.028, lowpass: 2200});
			}

			break;
		}

		case 'pad': {
			for (const pitch of event.chord) {
				tone(destination, frequencyOf(pitch), start, event.duration, {type: 'sawtooth', volume: 0.018, attack: 0.25, lowpass: 1400, detune: -8});
				tone(destination, frequencyOf(pitch), start, event.duration, {type: 'sawtooth', volume: 0.018, attack: 0.25, lowpass: 1400, detune: 8});
			}

			break;
		}

		case 'lead': {
			const frequency = frequencyOf(event.pitch);
			const volume = event.volume ?? 1;
			if (song.lead === 'bubble') {
				tone(destination, frequency, start, event.duration, {type: 'square', volume: 0.05 * volume, lowpass: 3500});
				tone(destination, frequency * 2, start, event.duration * 0.6, {type: 'triangle', volume: 0.03 * volume});
			} else if (song.lead === 'chipmunk') {
				tone(destination, frequency, start, event.duration, {type: 'square', volume: 0.04 * volume, vibrato: 9, lowpass: 5000});
				tone(destination, frequency / 2, start, event.duration, {type: 'triangle', volume: 0.04 * volume});
			} else {
				for (const detune of [-14, 0, 14]) {
					tone(destination, frequency, start, event.duration, {type: 'sawtooth', volume: 0.024 * volume, detune, lowpass: 3000});
				}
			}

			break;
		}

		default: {
			break;
		}
	}
};

// All the events of a song, from its form, chords, tunes, and sounds, with their time in seconds from the first beat.
const composeSong = song => {
	const events = [];
	const sixteenth = song.sixteenth;
	const add = (position, voice, details = {}) => {
		events.push({time: position * sixteenth, voice, ...details});
	};

	for (const [bar, {section, barInSection}] of bars.entries()) {
		const base = bar * 16;
		const transpose = section.transpose ?? 0;
		const chord = song.chords[bar % 4].map(pitch => pitch + transpose);
		const bassRoot = chord[0] - 24;
		const name = section.name;
		const isLoud = name === 'verse' || name === 'chorus';

		// The drums.
		if (name !== 'break') {
			for (const beat of (name === 'end' ? [0] : beats)) {
				add(base + beat, 'kick');
			}
		}

		if (isLoud) {
			add(base + 4, 'clap');
			add(base + 12, 'clap');
		}

		if (isLoud || (name === 'intro' && barInSection >= 2)) {
			for (const position of [2, 6, 10, 14]) {
				add(base + position, 'hat', {isOpen: true});
			}
		}

		if (name === 'chorus' || name === 'break') {
			for (let position = 1; position < 16; position += 2) {
				add(base + position, 'hat');
			}
		}

		if (name === 'build') {
			const positions = barInSection < 2 ? [4, 12] : (barInSection === 2 ? eighths : Array.from({length: 16}, (_, index) => index));
			for (const position of positions) {
				add(base + position, 'snare', {volume: 0.08 + (0.04 * barInSection) + (position / 160)});
			}

			if (barInSection === 0) {
				add(base, 'riser', {duration: 16 * 4 * sixteenth});
			}
		}

		if (name === 'break' && barInSection === 3) {
			for (const position of eighths) {
				add(base + position, 'snare', {volume: 0.06 + (position / 100)});
			}
		}

		if ((name === 'chorus' && barInSection === 0) || name === 'end') {
			add(base, 'crash');
		}

		// The rain of Bergen, in the intro and the break of the rave.
		if (song.hasRain && (name === 'intro' || name === 'break') && barInSection === 0) {
			add(base, 'rain', {duration: section.bars * 16 * sixteenth});
			for (let drop = 0; drop < section.bars * 12; drop++) {
				add(base + (Math.random() * section.bars * 16), 'drop');
			}
		}

		// The bass.
		if (isLoud || name === 'build') {
			let pattern;
			if (song.bass === 'bounce') {
				pattern = eighths.map((position, index) => [position, bassRoot + (index % 2 === 0 ? 0 : 12), 2]);
			} else if (song.bass === 'gallop') {
				pattern = [2, 3, 6, 7, 10, 11, 14, 15].map(position => [position, bassRoot + 12, 1]);
			} else {
				pattern = [2, 6, 10, 14].map((position, index) => [position, bassRoot + (index % 2 === 0 ? 12 : 24), 2]);
			}

			for (const [position, pitch, length] of pattern) {
				add(base + position, 'bass', {pitch, duration: length * sixteenth * 0.9});
			}
		}

		// The chords: plucks in the loud parts, and a soft pad in the quiet ones.
		if (isLoud) {
			for (const position of song.stabs) {
				add(base + position, 'stab', {chord});
			}
		}

		if (name === 'intro' || name === 'break' || name === 'build' || name === 'chorus') {
			add(base, 'pad', {chord, duration: 16 * sixteenth});
		}

		// The tune.
		if (name === 'verse' || name === 'chorus') {
			const phrase = name === 'verse' ? song.verse : song.chorus;
			const barInPhrase = barInSection % (name === 'verse' ? 2 : 4);
			for (const note of phrase) {
				if (Math.floor(note.position / 16) === barInPhrase) {
					add(base + (note.position % 16), 'lead', {pitch: note.pitch + transpose, duration: note.length * sixteenth * 0.92, volume: name === 'verse' ? 0.75 : 1});
				}
			}
		}

		if (name === 'end') {
			add(base, 'pad', {chord: song.chords[0].map(pitch => pitch + 2), duration: 8 * sixteenth});
			add(base, 'lead', {pitch: song.chorus[0].pitch + 2, duration: 8 * sixteenth});
		}
	}

	events.sort((first, second) => first.time - second.time);
	return events;
};

const compositions = new Map();

const compositionFor = songId => {
	if (!compositions.has(songId)) {
		compositions.set(songId, composeSong(songs[songId]));
	}

	return compositions.get(songId);
};

// MARK: The settings

const speeds = [1, 1.5, 2, 3];

const gradeOrder = ['E', 'D', 'C', 'B', 'A', 'AA', 'AAA'];

// MARK: The game

// The judgments, from the closest to the target to the furthest, with how far from the beat a step may be, in seconds.
const judgments = [
	{name: 'perfect', label: 'PERFECT', window: 0.045, color: '#ffee44', points: 1000, dancePoints: 2},
	{name: 'great', label: 'GREAT', window: 0.09, color: '#44ff66', points: 600, dancePoints: 1},
	{name: 'good', label: 'GOOD', window: 0.135, color: '#44ccff', points: 200, dancePoints: 0},
	{name: 'boo', label: 'BOO', window: 0.18, color: '#cc66ff', points: 0, dancePoints: -4},
];

const missJudgment = {name: 'miss', label: 'MISS', color: '#ff3344', points: 0, dancePoints: -8};

// How much each judgment fills or drains the Dance Gauge, for each difficulty. Basic forgives a first-time dancer a dozen misses, and Maniac forgives less.
const gaugeChanges = {
	basic: {perfect: 0.025, great: 0.015, good: 0.005, boo: -0.02, miss: -0.04, ok: 0.02, ng: -0.04},
	trick: {perfect: 0.02, great: 0.01, good: 0, boo: -0.04, miss: -0.08, ok: 0.02, ng: -0.06},
	maniac: {perfect: 0.015, great: 0.008, good: 0, boo: -0.05, miss: -0.1, ok: 0.015, ng: -0.08},
};

// A freeze arrow may be let go this long, in seconds, and pressed again, before it breaks.
const freezeGrace = 0.25;

const formatScore = score => String(Math.round(score)).padStart(7, '0');

const gradeOf = ({counts, notes, isFailed}) => {
	if (isFailed) {
		return 'E';
	}

	const freezes = notes.filter(note => note.length > 0).length;
	const maximum = (notes.length * 2) + (freezes * 6);
	const earned = (counts.perfect * 2) + counts.great - (counts.boo * 4) - (counts.miss * 8) + (counts.ok * 6);
	const ratio = maximum === 0 ? 0 : earned / maximum;
	if (ratio >= 1) {
		return 'AAA';
	}

	if (ratio >= 0.93) {
		return 'AA';
	}

	if (ratio >= 0.8) {
		return 'A';
	}

	if (ratio >= 0.65) {
		return 'B';
	}

	if (ratio >= 0.45) {
		return 'C';
	}

	return 'D';
};

const comboLines = new Map([
	[25, 'Woo!'],
	[50, 'You\'re on fire!'],
	[100, 'Dancing machine!'],
	[200, 'Unbelievable!'],
]);

const gradeLines = {
	AAA: ['Unbelievable! Perfect!', 'Trond: “AAA?! You are better than the boy from Japan on the ferry!”'],
	AA: ['Wonderful!', 'Trond: “Nesten perfekt!” (Almost perfect!) He wants a rematch.'],
	A: ['Great job!', 'Pappa: “Very nice. Now can we eat the waffles?”'],
	B: ['Not bad!', 'Mamma: “Is this how they dance in Japan? With the knees?”'],
	C: ['Okay. Keep practicing!', 'Lillesøster: “I can do it better.” She cannot reach the bar yet.'],
	D: ['Boo! Boo!', 'Trond: “That was more like a fisherman in a storm.”'],
	E: ['Boo! You failed! Go home and practice!', 'The machine said Boo, and the whole arcade heard it. Even the captain.'],
};

const trondDemoLines = [
	'Trond shows off. He has played it 40 times on the ferry, and says it is all in the knees.',
	'Trond dances like nobody is watching. Everybody is watching.',
	'Trond: “Watch and learn.” He does not even look at the screen.',
];

const startLines = [
	'Trond: “Do not look at your feet!”',
	'Mamma is filming with the camcorder.',
	'A queue of Danish kids forms behind the machine.',
	'Pappa holds your jacket and the waffles.',
	'The ferry rocks a little. That is the excuse.',
];

const kronerLines = new Map([
	[10, 'Pappa: “One coin. Then we eat waffles in the cafeteria.”'],
	[30, 'Pappa: “That was my coffee money.”'],
	[50, 'Pappa: “That was the money for the waffles. You can eat the brown cheese alone.”'],
	[100, 'Mamma: “Hundre kroner?! (A hundred kroner?!) For jumping?”'],
	[200, 'Pappa: “For this money, I could have bought the machine. Almost.”'],
	[500, 'The captain asks if you want to work on the ferry. As a dancer.'],
]);

// MARK: The dancer

// The poses of the dancer, as the angles of the arms and legs, in degrees from straight down: 90 is to the right of the screen, −90 to the left, and 180 up. The lean tilts the body, and the hip goes down for a squat.
const poses = {
	idle: {lean: 0, hip: 0, armA: [-12, -5], armB: [12, 5], legA: [-8, -4], legB: [8, 4]},
	stepA: {lean: 4, hip: 1, armA: [-40, -20], armB: [20, 60], legA: [-38, -14], legB: [5, 3]},
	stepB: {lean: -4, hip: 1, armA: [-20, -60], armB: [40, 20], legA: [-5, -3], legB: [38, 14]},
	armsUp: {lean: 0, hip: -1, armA: [-150, -170], armB: [150, 170], legA: [-16, -8], legB: [16, 8]},
	point: {lean: -5, hip: 0, armA: [-100, -95], armB: [45, -40], legA: [-10, -5], legB: [22, 10]},
	disco: {lean: 6, hip: 0, armA: [-25, -10], armB: [155, 165], legA: [-18, -6], legB: [10, 35]},
	squat: {lean: 0, hip: 9, armA: [-80, -170], armB: [80, 170], legA: [-58, -5], legB: [58, 5]},
	kick: {lean: -8, hip: -1, armA: [-130, -150], armB: [100, 120], legA: [-5, -2], legB: [78, 88]},
	robot: {lean: 0, hip: 0, armA: [-90, 180], armB: [90, 0], legA: [-10, -5], legB: [10, 5]},
	jump: {lean: 0, hip: -10, armA: [-140, -160], armB: [140, 160], legA: [-40, 20], legB: [40, -20]},
	stumble: {lean: 18, hip: 4, armA: [-120, -60], armB: [60, 100], legA: [10, -20], legB: [-10, 25]},
	slump: {lean: 22, hip: 7, armA: [-4, 0], armB: [4, 0], legA: [-22, 10], legB: [22, -10]},
	cheer: {lean: 0, hip: -3, armA: [-160, -175], armB: [160, 175], legA: [-20, -10], legB: [20, 10]},
};

// The moves of the dancer get better with the combo: from stepping side to side to kicks and jumps.
const poseTiers = [
	['idle', 'stepA', 'idle', 'stepB'],
	['stepA', 'disco', 'stepB', 'squat', 'armsUp', 'point'],
	['kick', 'robot', 'jump', 'disco', 'squat', 'armsUp', 'point', 'stepA', 'stepB'],
];

const lanePoses = ['stepA', 'squat', 'armsUp', 'stepB'];

const dancerSkins = {
	sindre: {skin: '#f5c999', hair: '#ffe066', shirt: '#2266ff', stripe: '#ffffff', pants: '#3a5f9a', shoes: '#ffffff', name: 'SINDRE'},
	mormor: {skin: '#f3d1b5', hair: '#dddddd', shirt: '#9955aa', stripe: '#ffccee', pants: '#e8c9a8', shoes: '#222222', skirt: '#553366', name: 'MORMOR'},
};

const vector = (angle, length) => {
	const radians = angle * Math.PI / 180;
	return [Math.sin(radians) * length, Math.cos(radians) * length];
};

const drawLimb = (context, from, angles, lengths, color, lineWidth) => {
	const [upperX, upperY] = vector(angles[0], lengths[0]);
	const joint = [from[0] + upperX, from[1] + upperY];
	const [lowerX, lowerY] = vector(angles[1], lengths[1]);
	const end = [joint[0] + lowerX, joint[1] + lowerY];
	context.strokeStyle = color;
	context.lineWidth = lineWidth;
	context.beginPath();
	context.moveTo(...from);
	context.lineTo(...joint);
	context.lineTo(...end);
	context.stroke();
	return end;
};

// Draws a dancer on the stage of the screen, at its feet.
const drawDancer = (context, dancer, x, floor, pose) => {
	if (dancer === 'rocky') {
		drawRocky(context, x, floor, pose);
		return;
	}

	context.save();
	drawSkin(context, dancer, x, floor, pose);
	context.restore();
};

const drawSkin = (context, dancer, x, floor, pose) => {
	const skin = dancerSkins[dancer] ?? dancerSkins.sindre;
	const hip = [x, floor - 37 + pose.hip];
	const [torsoX, torsoY] = vector(180 + pose.lean, 24);
	const neck = [hip[0] + torsoX, hip[1] + torsoY];
	const [headX, headY] = vector(180 + (pose.lean * 1.3), 9);
	const head = [neck[0] + headX, neck[1] + headY];
	context.lineCap = 'round';
	context.lineJoin = 'round';

	// The shadow on the floor.
	context.fillStyle = 'rgba(0, 0, 0, 0.45)';
	context.beginPath();
	context.ellipse(x, floor + 1, 16, 3, 0, 0, Math.PI * 2);
	context.fill();

	const legWidth = dancer === 'sindre' ? 6 : 3;
	const footA = drawLimb(context, [hip[0] - 3, hip[1]], pose.legA, [19, 18], skin.pants, legWidth);
	const footB = drawLimb(context, [hip[0] + 3, hip[1]], pose.legB, [19, 18], skin.pants, legWidth);
	context.fillStyle = skin.shoes;
	for (const foot of [footA, footB]) {
		context.fillRect(Math.round(foot[0] - 4), Math.round(foot[1] - 2), 8, 4);
	}

	if (skin.skirt) {
		context.fillStyle = skin.skirt;
		context.beginPath();
		context.moveTo(hip[0] - 6, hip[1] - 4);
		context.lineTo(hip[0] + 6, hip[1] - 4);
		context.lineTo(hip[0] + 11, hip[1] + 13);
		context.lineTo(hip[0] - 11, hip[1] + 13);
		context.closePath();
		context.fill();
	}

	context.strokeStyle = skin.shirt;
	context.lineWidth = 10;
	context.beginPath();
	context.moveTo(...hip);
	context.lineTo(...neck);
	context.stroke();
	context.strokeStyle = skin.stripe;
	context.lineWidth = 2;
	context.beginPath();
	context.moveTo(hip[0] + (torsoX * 0.45), hip[1] + (torsoY * 0.45));
	context.lineTo(hip[0] + (torsoX * 0.6), hip[1] + (torsoY * 0.6));
	context.stroke();

	const shoulder = [neck[0], neck[1] + 2];
	const handA = drawLimb(context, [shoulder[0] - 3, shoulder[1]], pose.armA, [13, 12], skin.shirt, 4);
	const handB = drawLimb(context, [shoulder[0] + 3, shoulder[1]], pose.armB, [13, 12], skin.shirt, 4);
	context.fillStyle = skin.skin;
	for (const hand of [handA, handB]) {
		context.beginPath();
		context.arc(hand[0], hand[1], 2.5, 0, Math.PI * 2);
		context.fill();
	}

	// Mormor dances with her handbag.
	if (dancer === 'mormor') {
		context.fillStyle = '#8b5a2b';
		context.fillRect(Math.round(handB[0] - 3), Math.round(handB[1] + 1), 7, 6);
	}

	context.fillStyle = skin.skin;
	context.beginPath();
	context.arc(head[0], head[1], 7.5, 0, Math.PI * 2);
	context.fill();
	context.fillStyle = skin.hair;
	context.beginPath();
	context.arc(head[0], head[1] - 1, 7.5, Math.PI * 1.05, Math.PI * 1.95);
	context.fill();
	if (dancer === 'sindre') {
		// A cap, backwards, as was cool in 1999.
		context.fillStyle = '#ff2244';
		context.beginPath();
		context.arc(head[0], head[1] - 2, 7.5, Math.PI, Math.PI * 2);
		context.fill();
		context.fillRect(Math.round(head[0] + 4), Math.round(head[1] - 3), 6, 2);
	} else {
		// The bun and the glasses of Mormor.
		context.beginPath();
		context.arc(head[0], head[1] - 9, 4, 0, Math.PI * 2);
		context.fill();
		context.fillStyle = '#222222';
		context.fillRect(Math.round(head[0] - 5), Math.round(head[1] - 1), 4, 3);
		context.fillRect(Math.round(head[0] + 1), Math.round(head[1] - 1), 4, 3);
	}

	context.fillStyle = '#222222';
	if (dancer === 'sindre') {
		context.fillRect(Math.round(head[0] - 3), Math.round(head[1]), 2, 2);
		context.fillRect(Math.round(head[0] + 2), Math.round(head[1]), 2, 2);
	}

	context.fillRect(Math.round(head[0] - 2), Math.round(head[1] + 4), 4, 1);
	drawPixelText(context, skin.name, x, floor + 5, '#ffffff', {align: 'center'});
};

// Rocky the pet rock has no arms or legs, so he hops, tilts, and spins, with his sunglasses on.
const drawRocky = (context, x, floor, pose) => {
	const hop = Math.max(0, -pose.hip) + (pose.armA[0] < -100 ? 8 : 0);
	const squash = pose.hip > 5 ? 0.8 : 1;
	const tilt = (pose.lean + ((pose.legA[0] + pose.legB[0]) / 2)) * Math.PI / 180;
	context.fillStyle = 'rgba(0, 0, 0, 0.45)';
	context.beginPath();
	context.ellipse(x, floor + 1, 16 - (hop / 2), 3, 0, 0, Math.PI * 2);
	context.fill();

	context.save();
	context.translate(x, floor - 13 - hop);
	context.rotate(tilt);
	context.scale(1 / squash, squash);
	context.fillStyle = '#8c8c8c';
	context.beginPath();
	context.ellipse(0, 0, 18, 13, 0, 0, Math.PI * 2);
	context.fill();
	context.fillStyle = '#6e6e6e';
	for (const [spotX, spotY] of [[-9, 4], [6, 7], [11, -3], [-4, -8]]) {
		context.fillRect(spotX, spotY, 3, 2);
	}

	context.fillStyle = '#a8a8a8';
	context.fillRect(-12, -8, 6, 2);
	context.fillStyle = '#111111';
	context.fillRect(-11, -4, 9, 5);
	context.fillRect(2, -4, 9, 5);
	context.fillRect(-2, -3, 4, 1);
	context.fillStyle = '#66ccff';
	context.fillRect(-9, -3, 2, 1);
	context.fillRect(4, -3, 2, 1);
	context.fillStyle = '#331111';
	context.fillRect(-3, 5, 7, 1);
	context.restore();
	drawPixelText(context, 'ROCKY', x, floor + 5, '#ffffff', {align: 'center'});
};

// MARK: Drawing

const targetY = 30;
const laneX = lane => 35 + (lane * 30);
const fieldLeft = 16;
const fieldRight = 144;

const colorFills = {red: ['#ff3355', '#ffb0bf'], blue: ['#3377ff', '#b0ccff'], yellow: ['#ffd022', '#fff3b0'], green: ['#22dd55', '#b8ffcc']};

// The angle of the arrow of each lane: the shape points up, and turns for the others.
const laneAngles = [-Math.PI / 2, Math.PI, 0, Math.PI / 2];

const arrowShape = [[0, -12], [12, 0], [12, 3], [5, 3], [5, 12], [-5, 12], [-5, 3], [-12, 3], [-12, 0]];

const traceArrow = (context, x, y, lane, scale = 1) => {
	const angle = laneAngles[lane];
	const cosine = Math.cos(angle);
	const sine = Math.sin(angle);
	context.beginPath();
	for (const [index, [pointX, pointY]] of arrowShape.entries()) {
		const rotatedX = ((pointX * cosine) - (pointY * sine)) * scale;
		const rotatedY = ((pointX * sine) + (pointY * cosine)) * scale;
		if (index === 0) {
			context.moveTo(x + rotatedX, y + rotatedY);
		} else {
			context.lineTo(x + rotatedX, y + rotatedY);
		}
	}

	context.closePath();
};

const drawArrow = (context, x, y, lane, color, {scale = 1, alpha = 1} = {}) => {
	const [fill, light] = colorFills[color];
	context.globalAlpha = alpha;
	traceArrow(context, x, y, lane, scale);
	context.fillStyle = fill;
	context.fill();
	context.lineWidth = 2;
	context.strokeStyle = '#ffffff';
	context.stroke();
	traceArrow(context, x, y, lane, scale * 0.5);
	context.fillStyle = light;
	context.fill();
	context.globalAlpha = 1;
};

const gradeColors = {AAA: '#ffee44', AA: '#ffee44', A: '#ff66cc', B: '#66ccff', C: '#66ff99', D: '#cccccc', E: '#ff3344'};

const keyLanes = {ArrowLeft: 0, ArrowDown: 1, ArrowUp: 2, ArrowRight: 3, a: 0, s: 1, w: 2, d: 3};

const laneOfKey = event => keyLanes[event.key] ?? keyLanes[event.key?.toLowerCase()];

// The player of a song schedules the notes of the next part of a second, a little at a time, so the sound clock keeps them exactly on the beat.
class SongPlayer {
	#audioContext;
	#master;
	#timer;
	#output;
	#events = [];
	#nextEvent = 0;
	#start = 0;
	#song;

	constructor(audioContext, master) {
		this.#audioContext = audioContext;
		this.#master = master;
	}

	play(songId, start) {
		this.stop();
		this.#song = songs[songId];
		this.#events = compositionFor(songId);
		this.#nextEvent = 0;
		this.#start = start;
		this.#output = new GainNode(this.#audioContext, {gain: 1});
		this.#output.connect(this.#master);
		this.#timer = setInterval(() => {
			this.#schedule();
		}, 50);
		this.#schedule();
	}

	#schedule() {
		const audioContext = this.#audioContext;
		const horizon = audioContext.currentTime + 0.3;
		while (this.#nextEvent < this.#events.length && this.#start + this.#events[this.#nextEvent].time < horizon) {
			const event = this.#events[this.#nextEvent];
			const when = this.#start + event.time;
			if (when >= audioContext.currentTime - 0.02) {
				playEvent(event, Math.max(when, audioContext.currentTime), this.#output, this.#song);
			}

			this.#nextEvent++;
		}
	}

	// Stops the song: at once, or with a fade, like when the dancer fails and the music dies.
	stop({fade = 0.08} = {}) {
		clearInterval(this.#timer);
		this.#timer = undefined;
		if (this.#output) {
			const output = this.#output;
			const now = this.#audioContext.currentTime;
			output.gain.cancelScheduledValues(now);
			output.gain.setValueAtTime(output.gain.value, now);
			output.gain.linearRampToValueAtTime(0, now + fade);
			setTimeout(() => {
				output.disconnect();
			}, (fade * 1000) + 300);
		}

		this.#output = undefined;
	}

	// The song goes on to its end without new notes from the scheduler, for the last chord.
	finish() {
		clearInterval(this.#timer);
		this.#timer = undefined;
	}
}

export default class extends GeoCitiesElement {
	#context;
	#padButtons;
	#loop;
	#settings;
	#bestScores;
	#kronerSpent;
	#game;

	// The sound, once the visitor pressed a button that plays the machine: the audio context, and the volume that every sound goes through.
	#audio;
	#player;
	#announcedAt = 0;

	// The calibration plays 16 beats at 120 BPM. After 4 beats to count in, the visitor steps on each beat, and the median of how late the steps are becomes the delay.
	#calibration = {
		start: 0,
		beat: 0.5,
		beats: 16,
		taps: [],
		tappedBeats: new Set(),
		timer: undefined,
		output: undefined,
	};

	#dancer = {
		from: poses.idle,
		to: poses.idle,
		changedAt: 0,
		lastBeat: -1,
	};

	connected() {
		const {screen, start, demo, speed, still, announcer, calibrate, earlier, later} = this.parts;
		this.#context = screen.getContext('2d');
		this.#padButtons = [...this.querySelectorAll('[data-ddr-lane]')].sort((first, second) => Number(first.dataset.ddrLane) - Number(second.dataset.ddrLane));

		const settings = {
			song: 'prinsesse',
			difficulty: 'basic',
			dancer: 'sindre',
			speed: 1.5,
			isStill: this.reducedMotion,
			isAnnouncerOn: true,
			delay: 0,
			...this.stored('settings', {}),
		};

		if (!Object.hasOwn(songs, settings.song)) {
			settings.song = 'prinsesse';
		}

		if (!Object.hasOwn(difficultyNames, settings.difficulty)) {
			settings.difficulty = 'basic';
		}

		if (!['sindre', 'mormor', 'rocky'].includes(settings.dancer)) {
			settings.dancer = 'sindre';
		}

		settings.isStill = Boolean(settings.isStill);
		settings.isAnnouncerOn = Boolean(settings.isAnnouncerOn);

		if (!speeds.includes(settings.speed)) {
			settings.speed = 1.5;
		}

		settings.delay = clamp(Math.round(Number(settings.delay) || 0), -300, 300);
		this.#settings = settings;

		// The best scores, by song and difficulty, like `prinsesse/basic`. Anything else in the storage is left out.
		this.#bestScores = {};
		const storedScores = this.stored('best', {});
		if (storedScores && typeof storedScores === 'object') {
			for (const [key, value] of Object.entries(storedScores)) {
				if (Number.isFinite(value?.score) && gradeOrder.includes(value?.grade)) {
					this.#bestScores[key] = {score: value.score, grade: value.grade, combo: Number(value.combo) || 0};
				}
			}
		}

		const storedKroner = this.stored('kroner', 0);
		this.#kronerSpent = Number.isSafeInteger(storedKroner) && storedKroner >= 0 ? storedKroner : 0;

		this.#game = {
			// `title`, `playing`, `ending`, `results`, or `calibrating`.
			screen: 'title',
			isDemo: false,
			stagesLeft: 0,
			stage: 1,
			notes: [],
			songId: settings.song,
			difficulty: settings.difficulty,
			start: 0,
			gauge: 0.5,
			combo: 0,
			maxCombo: 0,
			score: 0,
			counts: {},
			lastJudgment: undefined,
			held: [false, false, false, false],
			pressedAt: [-9, -9, -9, -9],
			flashes: [],
			freezeMessages: [],
			lastMissAt: -9,
			isFailed: false,
			endedAt: 0,
			result: undefined,
			saidLowGauge: false,
			saidFullGauge: false,
			saidHereWeGo: false,
			demoRelease: [undefined, undefined, undefined, undefined],
		};

		// The arrows are drawn at the time of the frame.
		this.#loop = this.loop((seconds, now) => {
			const game = this.#game;

			if (game.screen === 'playing') {
				this.#update(this.#songTimeAt(now));
			}

			if (game.screen === 'ending' && now - game.endedAt > (game.isFailed ? 1800 : 2200)) {
				this.#showResults();
			}

			this.#draw(now);
		}, {while: () => this.#isBusy || !this.reducedMotion});

		const songButtons = this.querySelectorAll('[data-ddr-song]');
		const difficultyButtons = this.querySelectorAll('[data-ddr-difficulty]');
		const dancerButtons = this.querySelectorAll('[data-ddr-dancer]');

		for (const button of songButtons) {
			this.on(button, 'click', () => {
				if (this.#isBusy) {
					this.say('The song is playing. Finish the stage first, or stop it.');
					return;
				}

				settings.song = button.dataset.ddrSong;
				this.#saveSettings();
				this.#backToTitle();
				this.#updateChoices();
				const song = songs[settings.song];
				this.say(`“${song.title}” by ${song.artist}, ${song.bpm} BPM.`);
				this.#draw();
			});
		}

		for (const button of difficultyButtons) {
			this.on(button, 'click', () => {
				if (this.#isBusy) {
					this.say('The song is playing. Finish the stage first, or stop it.');
					return;
				}

				settings.difficulty = button.dataset.ddrDifficulty;
				this.#saveSettings();
				this.#backToTitle();
				this.#updateChoices();
				const comments = {basic: 'Basic: for Mormor and beginners.', trick: 'Trick: with eighths, jumps, and freezes.', maniac: 'Maniac: Trond says only the boy from Japan can do it.'};
				this.say(`${comments[settings.difficulty]} ${footRating(settings.song, settings.difficulty)} feet.`);
				this.#draw();
			});
		}

		for (const button of dancerButtons) {
			this.on(button, 'click', () => {
				settings.dancer = button.dataset.ddrDancer;
				this.#saveSettings();
				this.#updateChoices();
				this.#setPose('cheer');
				const comments = {sindre: 'I dance myself, in my cap.', mormor: 'Mormor dances, with her handbag. She was a champion of the polka in 1952.', rocky: 'Rocky the pet rock dances. He has no legs, but he has rhythm.'};
				this.say(comments[settings.dancer]);
				this.#draw();
			});
		}

		this.on(start, 'click', () => {
			if (this.#isBusy) {
				this.#abortSong('You stepped off the pad, and the song stopped. The stage does not count.');
				return;
			}

			this.#startSong();
		});

		this.on(demo, 'click', () => {
			this.#startSong({isDemo: true});
		});

		this.on(speed, 'click', () => {
			settings.speed = speeds[(speeds.indexOf(settings.speed) + 1) % speeds.length];
			this.#saveSettings();
			this.#updateChoices();
			this.say(`Speed ×${settings.speed}: the arrows come ${settings.speed > 1.5 ? 'faster, with more space between them' : 'slower, closer together'}.`);
			this.#draw();
		});

		this.on(still, 'click', () => {
			settings.isStill = !settings.isStill;
			this.#saveSettings();
			this.#updateChoices();
			this.say(settings.isStill ? 'Still mode: the arrows do not scroll. Each one lights up in its target, and is brightest at its time.' : 'The arrows scroll up again, like on the real machine.');
			this.#draw();
		});

		this.on(announcer, 'click', () => {
			settings.isAnnouncerOn = !settings.isAnnouncerOn;
			this.#saveSettings();
			this.#updateChoices();
			if (!settings.isAnnouncerOn) {
				this.#hushAnnouncer();
			}

			this.say(settings.isAnnouncerOn ? 'The announcer is back. “Woo!”' : 'The announcer is quiet. The arcade is not.');
		});

		this.on(calibrate, 'click', () => {
			this.#beginCalibration();
		});

		this.on(earlier, 'click', () => {
			this.#changeDelay(-10);
		});

		this.on(later, 'click', () => {
			this.#changeDelay(10);
		});

		// The keys step on the pad while the song plays, or on the screen and the pad when it does not.
		this.on(this, 'keydown', event => {
			if (event.altKey || event.ctrlKey || event.metaKey) {
				return;
			}

			const lane = laneOfKey(event);
			const isOnMachine = event.target === screen || this.#padButtons.includes(event.target);
			if (lane !== undefined && (this.#isBusy || isOnMachine)) {
				event.preventDefault();
				if (!event.repeat) {
					this.#press(lane, {at: event.timeStamp});
				}

				return;
			}

			if (event.target === screen && (event.key === 'Enter' || event.key === ' ')) {
				// Space would scroll the page away from the machine.
				event.preventDefault();
				if (!this.#isBusy) {
					this.#startSong();
				}

				return;
			}

			if (event.key === 'Escape' && this.#isBusy) {
				this.#abortSong('You stepped off the pad, and the song stopped. The stage does not count.');
			}
		});

		// The key can come up after the focus left the machine, so the foot comes off the pad then too.
		this.on(document, 'keyup', event => {
			const lane = laneOfKey(event);
			if (lane !== undefined && this.#game.held[lane]) {
				this.#release(lane, {at: event.timeStamp});
				this.#draw();
			}
		});

		// A finger or the mouse on the pad steps at once, on pointer down, so the timing is right, and each finger is its own foot for a jump.
		for (const [lane, button] of this.#padButtons.entries()) {
			this.on(button, 'pointerdown', event => {
				event.preventDefault();
				this.#press(lane, {at: event.timeStamp});
			});

			for (const type of ['pointerup', 'pointercancel', 'pointerleave']) {
				this.on(button, type, event => {
					if (this.#game.held[lane]) {
						this.#release(lane, {at: event.timeStamp});
						this.#draw();
					}
				});
			}

			// The keyboard can press a pad button too, with Enter or Space.
			this.on(button, 'click', event => {
				if (event.detail !== 0) {
					return;
				}

				this.#press(lane, {at: event.timeStamp});
				setTimeout(() => {
					this.#release(lane);
					this.#draw();
				}, 100);
			});

			this.on(button, 'contextmenu', event => {
				event.preventDefault();
			});
		}

		this.on(screen, 'click', () => {
			if (!this.#isBusy) {
				this.#startSong();
			}
		});

		// The keyup of a held key is lost when the window loses the focus, so the feet come off the pad then.
		this.on(globalThis, 'blur', () => {
			for (const lane of [0, 1, 2, 3]) {
				if (this.#game.held[lane]) {
					this.#release(lane);
				}
			}
		});

		this.#updateChoices();
		this.#updateDelay();
		this.#updateCoins();
		this.#updateStartButton();
		this.#draw();
	}

	disconnected() {
		this.#player?.stop();
		this.#stopCalibration();
		this.#hushAnnouncer();
	}

	// The visitor dances to the screen, so the machine runs only while the screen is on view, not while only the menu under it is.
	get visibilityTarget() {
		return this.parts.screen;
	}

	// The song stops when the visitor walks away from the machine, or when the tab is hidden, as the screen does not run then.
	visibilityChanged(isVisible) {
		if (!isVisible) {
			this.#walkAway();
		}
	}

	reducedMotionChanged() {
		this.#draw();
	}

	// One tune plays at a time on the page.
	musicStopped() {
		this.#abortSong('Somebody turned on other music, so the machine stopped the song.');
	}

	#walkAway() {
		this.#abortSong('You walked away from the machine, so the song stopped. The stage does not count.');
	}

	// MARK: The sound

	// The sound, made in the browser. It starts when the visitor presses a button that plays the machine.
	#startAudio() {
		try {
			if (!this.#audio) {
				const sound = this.sound();
				if (!sound) {
					return false;
				}

				const {context, output} = sound;
				const compressor = new DynamicsCompressorNode(context, {threshold: -14, ratio: 4});
				const master = new GainNode(context, {gain: 0.8});
				master.connect(compressor).connect(output);
				noiseBuffer(context);
				this.#audio = {context, master};
				this.#player = new SongPlayer(context, master);
			}

			this.#audio.context.resume().catch(() => {});
			return true;
		} catch {
			return false;
		}
	}

	// The time of the sound that the visitor hears at a moment of `performance.now()`, in the seconds of the sound clock. The output timestamp includes the delay of the speakers, so an arrow reaches the top when its beat is heard. Without sound, it is the clock of the page.
	#heardTimeAt(performanceTime) {
		const audioContext = this.#audio?.context;
		if (!audioContext) {
			return performanceTime / 1000;
		}

		const stamp = audioContext.getOutputTimestamp?.();
		if (stamp && stamp.contextTime > 0 && stamp.performanceTime > 0) {
			return stamp.contextTime + ((performanceTime - stamp.performanceTime) / 1000);
		}

		return audioContext.currentTime - (audioContext.outputLatency || audioContext.baseLatency || 0) + ((performanceTime - performance.now()) / 1000);
	}

	// The sad sound of a failed song, like a record that slows down.
	#failSound() {
		if (!this.#audio) {
			return;
		}

		const {context: audioContext, master} = this.#audio;
		const start = audioContext.currentTime;
		const oscillator = new OscillatorNode(audioContext, {type: 'sawtooth', frequency: 330});
		oscillator.frequency.setValueAtTime(330, start);
		oscillator.frequency.exponentialRampToValueAtTime(55, start + 1.2);
		const gain = new GainNode(audioContext, {gain: 0.08});
		gain.gain.setValueAtTime(0.08, start);
		gain.gain.exponentialRampToValueAtTime(0.0001, start + 1.3);
		oscillator.connect(gain).connect(master);
		oscillator.start(start);
		oscillator.stop(start + 1.4);
	}

	// The ding of a coin in the slot.
	#coinSound() {
		if (!this.#audio) {
			return;
		}

		const {context: audioContext, master} = this.#audio;
		const start = audioContext.currentTime;
		pluck(master, 1568, start, 0.15, {volume: 0.08, lowpass: 6000});
		pluck(master, 2093, start + 0.08, 0.4, {volume: 0.08, lowpass: 6000});
	}

	// The announcer of the arcade, with the voice of the browser. He talks only after the visitor started the machine, and not too often.
	#announce(text, {isImportant = false} = {}) {
		if (!this.#settings.isAnnouncerOn || !this.#audio || !('speechSynthesis' in globalThis)) {
			return;
		}

		const now = performance.now();
		if (!isImportant && now - this.#announcedAt < 2500) {
			return;
		}

		this.#announcedAt = now;
		speechSynthesis.cancel();
		const utterance = new SpeechSynthesisUtterance(text);
		utterance.lang = 'en-US';
		utterance.rate = 1.1;
		utterance.pitch = 0.6;
		speechSynthesis.speak(utterance);
	}

	#hushAnnouncer() {
		if ('speechSynthesis' in globalThis) {
			speechSynthesis.cancel();
		}
	}

	// MARK: The settings

	#saveSettings() {
		this.store('settings', this.#settings);
	}

	// The time in the song that a moment of `performance.now()` is, as the visitor hears and sees it, with the delay that the visitor calibrated.
	#songTimeAt(performanceTime) {
		return this.#heardTimeAt(performanceTime) - this.#game.start - (this.#settings.delay / 1000);
	}

	get #isInSong() {
		return this.#game.screen === 'playing';
	}

	// The machine is busy while a song or the calibration runs.
	get #isBusy() {
		const {screen} = this.#game;
		return screen === 'playing' || screen === 'ending' || screen === 'calibrating';
	}

	// MARK: Steps

	#flash(lane, color) {
		const game = this.#game;
		game.flashes.push({lane, color, at: performance.now()});
		if (game.flashes.length > 24) {
			game.flashes.shift();
		}
	}

	#applyJudgment(judgment, note) {
		const game = this.#game;
		game.counts[judgment.name]++;
		game.lastJudgment = {judgment, at: performance.now()};
		game.gauge = clamp(game.gauge + gaugeChanges[game.difficulty][judgment.name], 0, 1);
		if (judgment.name === 'perfect' || judgment.name === 'great') {
			game.combo++;
			game.maxCombo = Math.max(game.maxCombo, game.combo);
			game.score += judgment.points * (1 + (Math.min(game.combo, 100) / 100));
			this.#flash(note.lane, judgment.color);
			const line = comboLines.get(game.combo);
			if (line) {
				this.#announce(line);
			}
		} else {
			if (judgment.name === 'good') {
				game.score += judgment.points;
				this.#flash(note.lane, judgment.color);
			} else {
				game.lastMissAt = performance.now();
			}

			if (game.combo >= 25 && judgment.name !== 'good') {
				this.#announce('Boo!');
			}

			game.combo = 0;
		}

		if (game.gauge >= 1 && !game.saidFullGauge) {
			game.saidFullGauge = true;
			this.#announce('Feel the groove!');
		}

		if (game.gauge < 0.25 && !game.saidLowGauge && !game.isDemo) {
			game.saidLowGauge = true;
			this.#announce('Come on! Don\'t give up!');
		}
	}

	#freezeResult(note, isOk) {
		const game = this.#game;
		note.hold = isOk ? 'ok' : 'ng';
		game.counts[note.hold]++;
		game.gauge = clamp(game.gauge + gaugeChanges[game.difficulty][note.hold], 0, 1);
		game.freezeMessages.push({lane: note.lane, isOk, at: performance.now()});
		if (isOk) {
			game.score += 1000;
		}
	}

	// A step on an arrow of the pad, at a moment of `performance.now()`, or at a time in the song for Trond. It lights up the pad, and judges the oldest arrow of that lane in reach that has not been stepped on, like the real machine, so a late step on an arrow is never taken as an early step on the next one.
	#press(lane, {at = performance.now(), songTime, isDemo = false} = {}) {
		const game = this.#game;
		game.held[lane] = true;
		game.pressedAt[lane] = performance.now();
		this.#padButtons[lane].dataset.state = 'on';

		// On a step, the dancer moves with the feet of the visitor when nothing moves by itself.
		if (game.screen !== 'playing' || this.reducedMotion) {
			this.#setPose(lanePoses[lane]);
		}

		if (game.screen === 'calibrating') {
			this.#tapCalibration(this.#calibrationTimeAt(at));
			this.#draw();
			return;
		}

		if (!this.#isInSong || (game.isDemo && !isDemo)) {
			this.#draw();
			return;
		}

		const time = songTime ?? this.#songTimeAt(at);

		// Pressing a freeze arrow again in time keeps it going.
		for (const note of game.notes) {
			if (note.lane === lane && note.hold === 'holding') {
				note.releasedAt = undefined;
			}
		}

		const target = game.notes.find(note => note.lane === lane && !note.judgment && Math.abs(note.time - time) <= judgments.at(-1).window);
		if (!target) {
			return;
		}

		const judgment = judgments.find(item => Math.abs(target.time - time) <= item.window);
		target.judgment = judgment.name;
		this.#applyJudgment(judgment, target);
		if (target.length > 0) {
			if (judgment.name === 'boo') {
				this.#freezeResult(target, false);
			} else {
				target.hold = 'holding';
				target.releasedAt = undefined;
			}
		}
	}

	#release(lane, {at = performance.now(), songTime, isDemo = false} = {}) {
		const game = this.#game;
		game.held[lane] = false;
		this.#padButtons[lane].dataset.state = '';
		if (!this.#isInSong || (game.isDemo && !isDemo)) {
			return;
		}

		for (const note of game.notes) {
			if (note.lane === lane && note.hold === 'holding') {
				note.releasedAt = songTime ?? this.#songTimeAt(at);
			}
		}
	}

	#releaseAll() {
		for (const lane of [0, 1, 2, 3]) {
			this.#game.held[lane] = false;
			this.#padButtons[lane].dataset.state = '';
		}
	}

	// Judges the arrows that went by, the freeze arrows, Trond’s steps in the demonstration, and the end of the song.
	#update(time) {
		const game = this.#game;
		if (game.screen !== 'playing') {
			return;
		}

		const song = songs[game.songId];
		if (!game.saidHereWeGo && time >= 16 * song.sixteenth) {
			game.saidHereWeGo = true;
			this.#announce('Here we go!', {isImportant: true});
		}

		if (game.isDemo) {
			for (const [lane, releaseAt] of game.demoRelease.entries()) {
				if (releaseAt !== undefined && time >= releaseAt) {
					game.demoRelease[lane] = undefined;
					this.#release(lane, {songTime: time, isDemo: true});
				}
			}

			for (const note of game.notes) {
				if (note.time > time) {
					break;
				}

				if (!note.judgment) {
					this.#press(note.lane, {songTime: note.time, isDemo: true});
					game.demoRelease[note.lane] = note.time + Math.max(note.length, 0.09);
				}
			}
		}

		for (const note of game.notes) {
			if (note.time > time) {
				break;
			}

			if (!note.judgment && time - note.time > judgments.at(-1).window) {
				note.judgment = 'miss';
				this.#applyJudgment(missJudgment, note);
				if (note.length > 0) {
					this.#freezeResult(note, false);
				}
			}

			if (note.hold === 'holding') {
				const end = note.time + note.length;
				if (time >= end) {
					this.#freezeResult(note, true);
				} else if (!game.held[note.lane] && note.releasedAt !== undefined && time - note.releasedAt > freezeGrace) {
					this.#freezeResult(note, false);
				}
			}
		}

		if (game.gauge <= 0 && !game.isDemo) {
			this.#endSong({isFailed: true});
			return;
		}

		if (time >= song.duration + 0.4) {
			this.#endSong({isFailed: false});
		}
	}

	// MARK: Starting and ending

	#updateStartButton() {
		const {start} = this.parts;
		const game = this.#game;
		if (this.#isBusy) {
			start.textContent = '■ Stop';
			return;
		}

		if (game.stagesLeft === 0) {
			start.textContent = '🪙 Insert 10 kr and Dance (Sound!)';
		} else {
			start.textContent = game.stagesLeft === 1 ? '▶ Dance the Final Stage (Sound!)' : `▶ Dance Stage ${4 - game.stagesLeft} (Sound!)`;
		}
	}

	#updateCoins() {
		const {coins} = this.parts;
		const credit = this.#game.stagesLeft > 0 ? ` · Stages left: ${this.#game.stagesLeft}` : '';
		coins.textContent = `Spent: ${this.#kronerSpent} kr${credit}`;
	}

	#startSong({isDemo = false} = {}) {
		const game = this.#game;
		const {screen, demo, calibrate} = this.parts;
		if (game.screen === 'playing' || game.screen === 'ending') {
			return;
		}

		this.#startAudio();
		if (!isDemo && game.stagesLeft === 0) {
			this.#kronerSpent += 10;
			game.stagesLeft = 3;
			this.store('kroner', this.#kronerSpent);
			this.#coinSound();
			const line = kronerLines.get(this.#kronerSpent);
			if (line) {
				this.toast(line);
			}
		}

		this.#updateCoins();

		// The screen must be on view, as the game only runs there.
		screen.scrollIntoView({block: 'nearest'});
		const song = songs[this.#settings.song];
		game.screen = 'playing';
		game.isDemo = isDemo;
		game.songId = this.#settings.song;
		game.difficulty = this.#settings.difficulty;
		game.stage = isDemo ? 0 : 4 - game.stagesLeft;
		game.notes = chartFor(game.songId, game.difficulty).map(note => ({...note}));
		game.gauge = 0.5;
		game.combo = 0;
		game.maxCombo = 0;
		game.score = 0;
		game.counts = {perfect: 0, great: 0, good: 0, boo: 0, miss: 0, ok: 0, ng: 0};
		game.lastJudgment = undefined;
		game.flashes = [];
		game.freezeMessages = [];
		game.lastMissAt = -9;
		game.isFailed = false;
		game.result = undefined;
		game.saidLowGauge = false;
		game.saidFullGauge = false;
		game.saidHereWeGo = false;
		game.demoRelease = [undefined, undefined, undefined, undefined];
		this.#releaseAll();

		const now = this.#audio ? this.#audio.context.currentTime : performance.now() / 1000;
		game.start = now + 0.25;
		this.#player?.play(game.songId, game.start);
		this.music(true);
		this.#announce(isDemo ? 'Here comes a new challenger!' : 'Are you ready?', {isImportant: true});

		const stageName = isDemo ? 'Demonstration' : (game.stagesLeft === 1 ? 'Final Stage' : `Stage ${game.stage}`);
		this.say(`${stageName}: “${song.title}” by ${songs[game.songId].artist}, ${difficultyNames[game.difficulty]}. ${isDemo ? randomItem(trondDemoLines) : randomItem(startLines)}`);
		this.#updateStartButton();
		demo.disabled = true;
		calibrate.disabled = true;
		screen.focus({preventScroll: true});
		this.#loop.start();
	}

	#endSong({isFailed}) {
		const game = this.#game;
		game.screen = 'ending';
		game.isFailed = isFailed;
		game.endedAt = performance.now();
		this.#releaseAll();
		if (isFailed) {
			this.#player?.stop({fade: 1});
			this.#failSound();
			this.#announce(gradeLines.E[0], {isImportant: true});
		} else {
			this.#player?.finish();
		}

		const grade = gradeOf(game);
		const key = `${game.songId}/${game.difficulty}`;
		const previous = this.#bestScores[key];
		const isFullCombo = !isFailed && game.counts.miss === 0 && game.counts.boo === 0 && game.counts.good === 0 && game.counts.ng === 0;
		const isRecord = !game.isDemo && !isFailed && (!previous || game.score > previous.score);
		game.result = {grade, isFullCombo, isRecord};
		if (isRecord) {
			this.#bestScores[key] = {score: Math.round(game.score), grade, combo: game.maxCombo};
			this.store('best', this.#bestScores);
			this.#updateBest();
		}

		if (!game.isDemo) {
			game.stagesLeft = isFailed ? 0 : game.stagesLeft - 1;
		}

		this.#updateCoins();
		this.#loop.start();
	}

	// Shows the results after the last chord, or after the music died.
	#showResults() {
		const game = this.#game;
		const {demo, calibrate} = this.parts;
		game.screen = 'results';
		this.#player?.stop();
		this.music(false);
		const {grade, isFullCombo, isRecord} = game.result;
		const [spoken, line] = gradeLines[grade];
		if (!game.isFailed) {
			this.#announce(isFullCombo ? 'Full combo! Wonderful!' : spoken, {isImportant: true});
		}

		if (game.isDemo) {
			this.say(`Trond got ${grade} with ${Math.round(game.score).toLocaleString('en-US')} points. “Now you,” he says, and gives you the pad.`);
		} else {
			const gameOver = game.stagesLeft === 0 ? ' Game over: insert another 10 kr to dance on.' : '';
			this.say(`Grade ${grade}, ${Math.round(game.score).toLocaleString('en-US')} points, ${game.maxCombo} max combo.${isFullCombo ? ' FULL COMBO!' : ''}${isRecord ? ' A new record!' : ''} ${line}${gameOver}`);
			if (grade === 'AAA' || grade === 'AA' || isFullCombo) {
				this.celebrate();
			}
		}

		this.#updateStartButton();
		demo.disabled = false;
		calibrate.disabled = false;
		this.#draw();
		this.#loop.start();
	}

	// Stops the song before its end, or the calibration, like when the visitor walks away from the machine. The stage does not count.
	#abortSong(message) {
		const game = this.#game;
		const {demo, calibrate} = this.parts;
		if (!this.#isBusy) {
			return;
		}

		const wasCalibrating = game.screen === 'calibrating';
		this.#player?.stop();
		this.#stopCalibration();
		this.#hushAnnouncer();
		this.#releaseAll();
		if (game.screen === 'ending' && game.result) {
			this.#showResults();
			return;
		}

		game.screen = 'title';
		this.music(false);
		this.#updateCoins();

		this.#updateStartButton();
		demo.disabled = false;
		calibrate.disabled = false;
		this.say(wasCalibrating ? 'The calibration stopped.' : message);
		this.#draw();
	}

	// MARK: The calibration

	#beginCalibration() {
		const calibration = this.#calibration;
		const {screen, demo, calibrate} = this.parts;
		if (this.#isBusy) {
			return;
		}

		if (!this.#startAudio()) {
			this.say('This browser has no sound, so there is nothing to calibrate.');
			return;
		}

		const {context: audioContext, master} = this.#audio;
		this.music(true);
		screen.scrollIntoView({block: 'nearest'});
		this.#game.screen = 'calibrating';
		calibration.taps = [];
		calibration.tappedBeats = new Set();
		calibration.start = audioContext.currentTime + 0.3;
		calibration.output = new GainNode(audioContext, {gain: 1});
		calibration.output.connect(master);
		for (let beat = 0; beat < calibration.beats; beat++) {
			const when = calibration.start + (beat * calibration.beat);
			pluck(calibration.output, beat % 4 === 0 ? 1760 : 1320, when, 0.08, {type: 'square', volume: 0.08, lowpass: 8000});
			kick(calibration.output, when, 0.4);
		}

		calibration.timer = setTimeout(() => {
			this.#finishCalibration();
		}, ((calibration.beats * calibration.beat) + 0.6) * 1000);
		this.#updateStartButton();
		demo.disabled = true;
		calibrate.disabled = true;
		this.say('Listen to the beat. After four beats, step on any arrow on each beat: 12 steps.');
		screen.focus({preventScroll: true});
		this.#loop.start();
	}

	// The time in the calibration, as the visitor hears it, without the delay of before.
	#calibrationTimeAt(performanceTime) {
		return this.#heardTimeAt(performanceTime) - this.#calibration.start;
	}

	#tapCalibration(heard) {
		const calibration = this.#calibration;
		const beat = Math.round(heard / calibration.beat);
		// One step counts for each beat, so a jump or a double tap does not count twice.
		if (beat < 4 || beat >= calibration.beats || calibration.tappedBeats.has(beat)) {
			return;
		}

		calibration.tappedBeats.add(beat);
		calibration.taps.push(heard - (beat * calibration.beat));
	}

	#stopCalibration() {
		const calibration = this.#calibration;
		clearTimeout(calibration.timer);
		calibration.timer = undefined;
		calibration.output?.disconnect();
		calibration.output = undefined;
	}

	#finishCalibration() {
		const calibration = this.#calibration;
		const settings = this.#settings;
		const {demo, calibrate} = this.parts;
		this.#stopCalibration();
		this.music(false);
		this.#game.screen = 'title';
		demo.disabled = false;
		calibrate.disabled = false;
		this.#updateStartButton();
		if (calibration.taps.length < 4) {
			this.say('Not enough steps to tell. Try again, and step on each beat after the first four.');
		} else {
			const sorted = calibration.taps.toSorted((first, second) => first - second);
			const median = sorted[Math.floor(sorted.length / 2)];
			settings.delay = clamp(Math.round(median * 1000 / 5) * 5, -300, 300);
			this.#saveSettings();
			this.#updateDelay();
			const comment = Math.abs(settings.delay) <= 20 ? 'Right on the beat, like a metronome.' : (settings.delay > 0 ? 'You are a little late, like the bus to Bergen. The machine waits for you now.' : 'You are a little early, like Mormor at the airport. The machine hurries now.');
			this.say(`Delay: ${settings.delay > 0 ? '+' : ''}${settings.delay} ms, from ${calibration.taps.length} steps. ${comment}`);
		}

		this.#draw();
	}

	// MARK: The dancer

	#setPose(name) {
		const dancer = this.#dancer;
		if (dancer.to === poses[name]) {
			return;
		}

		dancer.from = this.#currentPose(performance.now());
		dancer.to = poses[name];
		dancer.changedAt = performance.now();
	}

	#currentPose(now) {
		const dancer = this.#dancer;
		const progress = this.reducedMotion ? 1 : clamp((now - dancer.changedAt) / 110, 0, 1);
		const eased = 1 - ((1 - progress) ** 2);
		const mix = (first, second) => first + ((second - first) * eased);
		const pose = {};
		for (const key of Object.keys(dancer.to)) {
			const first = dancer.from[key];
			const second = dancer.to[key];
			pose[key] = Array.isArray(second) ? second.map((value, index) => mix(first[index], value)) : mix(first, second);
		}

		return pose;
	}

	// Picks a new pose on each beat of the song, from the tier of the combo, or a stumble after a miss.
	#danceToBeat(beatNumber, now) {
		const dancer = this.#dancer;
		if (beatNumber === dancer.lastBeat) {
			return;
		}

		dancer.lastBeat = beatNumber;
		if (now - this.#game.lastMissAt < 500) {
			this.#setPose('stumble');
			return;
		}

		const tier = this.#game.combo >= 50 ? 2 : (this.#game.combo >= 12 ? 1 : 0);
		const choices = poseTiers[tier];
		this.#setPose(tier === 0 ? choices[beatNumber % choices.length] : randomItem(choices));
	}

	// MARK: Drawing

	// The target arrows at the top, which blink on each beat, light up on a step, and burst on a good step.
	#drawTargets(time, now) {
		const context = this.#context;
		const game = this.#game;
		const song = songs[game.songId];
		const beatPhase = ((time / song.beat) % 1 + 1) % 1;
		const isOnBeat = !this.reducedMotion && this.#isInSong && time > 0 && beatPhase < 0.15;
		for (let lane = 0; lane < 4; lane++) {
			const x = laneX(lane);
			const isPressed = game.held[lane] || now - game.pressedAt[lane] < 80;
			traceArrow(context, x, targetY, lane);
			context.fillStyle = isPressed ? '#7788aa' : (isOnBeat ? '#556080' : '#222a3e');
			context.fill();
			context.lineWidth = 2;
			context.strokeStyle = isOnBeat || isPressed ? '#ffffff' : '#99a3bb';
			context.stroke();
		}

		for (const item of game.flashes) {
			const age = (now - item.at) / 220;
			if (age >= 1) {
				continue;
			}

			const x = laneX(item.lane);
			context.globalAlpha = 1 - age;
			context.strokeStyle = item.color;
			context.lineWidth = 3;
			traceArrow(context, x, targetY, item.lane, this.reducedMotion ? 1.15 : 1 + (age * 0.6));
			context.stroke();
			context.globalAlpha = 1;
		}

		for (const item of game.freezeMessages) {
			const age = (now - item.at) / 700;
			if (age < 1) {
				drawPixelText(context, item.isOk ? 'OK!' : 'NG', laneX(item.lane), targetY + 18, item.isOk ? '#ffee44' : '#ff3344', {align: 'center'});
			}
		}
	}

	// The arrows scroll up from the bottom to the targets. A freeze arrow has a green tail, which gets shorter while it is held.
	#drawScrollingNotes(time) {
		const context = this.#context;
		const game = this.#game;
		const speed = 32 * this.#settings.speed * songs[game.songId].bpm / 60;
		for (const note of game.notes) {
			const isHolding = note.hold === 'holding';
			if (note.judgment && note.judgment !== 'miss' && !isHolding && note.hold !== 'ng') {
				continue;
			}

			const y = targetY + ((note.time - time) * speed);
			if (y > context.canvas.height + 20) {
				break;
			}

			const x = laneX(note.lane);
			if (note.length > 0) {
				const tailY = targetY + ((note.time + note.length - time) * speed);
				const headY = isHolding ? targetY : y;
				if (tailY < -14) {
					continue;
				}

				const isBroken = note.hold === 'ng' || note.judgment === 'miss';
				context.fillStyle = isBroken ? '#555555' : (isHolding && game.held[note.lane] ? '#88ffaa' : '#22aa44');
				context.fillRect(x - 7, headY, 14, Math.max(0, tailY - headY));
				context.fillStyle = isBroken ? '#888888' : '#ccffdd';
				context.fillRect(x - 7, tailY - 2, 14, 3);
				if (note.hold === 'ng' && !isHolding) {
					continue;
				}

				drawArrow(context, x, headY, note.lane, 'green', {alpha: isBroken ? 0.4 : 1});
				continue;
			}

			if (y < -14) {
				continue;
			}

			drawArrow(context, x, y, note.lane, note.color, {alpha: note.judgment === 'miss' ? 0.35 : 1});
		}
	}

	// In the still mode, nothing scrolls: the next arrow of each lane lights up in its target, brighter as its time comes, and four lamps count the beats.
	#drawStillNotes(time) {
		const context = this.#context;
		const game = this.#game;
		const song = songs[game.songId];
		const lightUp = song.beat * 2;
		for (let lane = 0; lane < 4; lane++) {
			const next = game.notes.find(note => note.lane === lane && (!note.judgment || note.hold === 'holding') && note.time + note.length - time > -0.05);
			if (!next) {
				continue;
			}

			const until = next.time - time;
			const x = laneX(lane);
			if (next.hold === 'holding') {
				drawArrow(context, x, targetY, lane, 'green');
				drawPixelText(context, 'HOLD', x, targetY + 18, '#88ffaa', {align: 'center'});
				continue;
			}

			if (until > lightUp) {
				continue;
			}

			const color = next.length > 0 ? 'green' : next.color;
			drawArrow(context, x, targetY, lane, color, {alpha: clamp(1 - (until / lightUp), 0.12, 1)});
			if (until < 0.06) {
				context.lineWidth = 3;
				context.strokeStyle = '#ffffff';
				traceArrow(context, x, targetY, lane, 1.25);
				context.stroke();
			}

			// The arrows after it, small and dim, so the visitor sees what comes.
			const after = game.notes.find(note => note.lane === lane && note.time > next.time + 0.01);
			if (after && after.time - time < lightUp * 1.5) {
				drawArrow(context, x, targetY + 34, lane, after.length > 0 ? 'green' : after.color, {scale: 0.5, alpha: 0.6});
			}
		}

		const beatNumber = Math.floor(time / song.beat);
		for (let lamp = 0; lamp < 4; lamp++) {
			const isLit = time >= 0 && ((beatNumber % 4) + 4) % 4 === lamp;
			context.fillStyle = isLit ? '#ffee44' : '#333a50';
			context.fillRect(42 + (lamp * 22), 92, 14, 6);
		}

		drawPixelText(context, 'STILL MODE', 80, 104, '#99a3bb', {align: 'center'});
	}

	// The Dance Gauge at the top: it flows like a rainbow when it is full, and blinks red when it is almost empty.
	#drawGauge(now) {
		const context = this.#context;
		const {gauge} = this.#game;
		const left = 8;
		const top = 6;
		const gaugeWidth = 144;
		context.fillStyle = '#000000';
		context.fillRect(left - 2, top - 2, gaugeWidth + 4, 12);
		context.strokeStyle = '#c0c0c0';
		context.lineWidth = 1;
		context.strokeRect(left - 1.5, top - 1.5, gaugeWidth + 3, 11);
		const segments = 36;
		const lit = Math.round(gauge * segments);
		const isFull = gauge >= 1;
		const isLow = gauge < 0.25;
		const blinkOff = isLow && !this.reducedMotion && Math.floor(now / 150) % 2 === 0;
		for (let segment = 0; segment < segments; segment++) {
			let color = '#1b2238';
			if (segment < lit && !blinkOff) {
				if (isFull) {
					const hue = ((segment * 12) - (this.reducedMotion ? 0 : now / 4)) % 360;
					color = `hsl(${hue}, 100%, 60%)`;
				} else if (isLow) {
					color = '#ff3344';
				} else {
					color = segment > segments * 0.75 ? '#ffee44' : '#44ccff';
				}
			}

			context.fillStyle = color;
			context.fillRect(left + (segment * 4), top, 3, 8);
		}
	}

	// The busy background of the machine, which pulses on the beat: rings around the dancer, and the lit floor of a disco.
	#drawBackground(time, now) {
		const context = this.#context;
		const {width, height} = context.canvas;
		const game = this.#game;
		const isSongOn = game.screen === 'playing' || game.screen === 'ending';
		const song = songs[isSongOn ? game.songId : this.#settings.song];
		const isMoving = !this.reducedMotion;
		const beatClock = isSongOn ? time : now / 1000;
		const beatPhase = isMoving ? (((beatClock / song.beat) % 1) + 1) % 1 : 0.5;
		const pulse = isMoving ? (1 - beatPhase) ** 2 : 0.3;
		const beatNumber = isMoving ? Math.floor(beatClock / song.beat) : 0;

		const gradient = context.createLinearGradient(0, 0, 0, height);
		gradient.addColorStop(0, '#120a2a');
		gradient.addColorStop(1, '#2a0a3a');
		context.fillStyle = gradient;
		context.fillRect(0, 0, width, height);

		const [colorA, colorB, colorC] = song.background;
		const centerX = 236;
		const centerY = 120;
		context.lineWidth = 9;
		for (let ring = 9; ring >= 0; ring--) {
			const radius = (ring * 20) + (beatPhase * 20);
			context.globalAlpha = 0.18 + (pulse * 0.35);
			context.strokeStyle = [colorA, colorB, colorC][(((ring + beatNumber) % 3) + 3) % 3];
			context.beginPath();
			context.arc(centerX, centerY, radius, 0, Math.PI * 2);
			context.stroke();
		}

		context.globalAlpha = 1;

		// The floor of the stage, with tiles that light up on the beat.
		const floorTop = 204;
		for (let row = 0; row < 3; row++) {
			for (let column = 0; column < 9; column++) {
				const isLit = ((column * 7) + (row * 3) + beatNumber) % 4 === 0;
				context.fillStyle = isLit ? [colorA, colorB, colorC][(column + row) % 3] : ((column + row) % 2 === 0 ? '#2a1a4a' : '#1a1030');
				context.fillRect(150 + (column * 19), floorTop + (row * 12), 18, 11);
			}
		}

		// The lanes of the arrows, darker, so the arrows read.
		context.fillStyle = 'rgba(0, 0, 0, 0.6)';
		context.fillRect(fieldLeft, 0, fieldRight - fieldLeft, height);
		context.fillStyle = 'rgba(255, 255, 255, 0.05)';
		for (let lane = 0; lane < 4; lane++) {
			context.fillRect(laneX(lane) - 1, 0, 2, height);
		}
	}

	#drawJudgmentAndCombo(now) {
		const context = this.#context;
		const game = this.#game;
		const last = game.lastJudgment;
		if (last && now - last.at < 600) {
			const age = (now - last.at) / 600;
			const pop = this.reducedMotion ? 0 : Math.max(0, 3 - (age * 30));
			let color = last.judgment.color;
			if (last.judgment.name === 'perfect' && !this.reducedMotion) {
				color = `hsl(${(now / 3) % 360}, 100%, 70%)`;
			}

			drawPixelText(context, last.judgment.label, 80, 118 - pop, color, {scale: 3, align: 'center'});
		}

		if (game.combo >= 4) {
			drawPixelText(context, game.combo, 80, 140, '#ffffff', {scale: 5, align: 'center', shadow: '#ff2fa8'});
			drawPixelText(context, 'COMBO', 80, 168, '#ffcc00', {scale: 2, align: 'center'});
		}
	}

	get #stageLabel() {
		if (this.#game.isDemo) {
			return 'DEMO: TROND';
		}

		return this.#game.stage === 3 ? 'FINAL STAGE' : `STAGE ${this.#game.stage}`;
	}

	#drawPlaying(time, now) {
		const context = this.#context;
		const game = this.#game;
		const song = songs[game.songId];
		this.#drawBackground(time, now);
		this.#drawGauge(now);
		this.#drawTargets(time, now);
		if (this.#settings.isStill) {
			this.#drawStillNotes(time);
		} else {
			this.#drawScrollingNotes(time);
		}

		if (game.screen === 'playing') {
			this.#drawJudgmentAndCombo(now);
		}

		// “Ready” and “Here we go!” in the first two bars, like the real machine.
		const bar = time / (16 * song.sixteenth);
		if (bar < 1 && game.screen === 'playing') {
			drawPixelText(context, 'READY?', 80, 140, '#ffcc00', {scale: 3, align: 'center'});
		} else if (bar < 2 && game.screen === 'playing') {
			drawPixelText(context, 'HERE WE GO!', 80, 140, '#ff66cc', {scale: 2, align: 'center'});
		}

		if (game.screen === 'ending') {
			const text = game.isFailed ? 'FAILED' : (game.result?.isFullCombo ? 'FULL COMBO!' : 'CLEARED!');
			drawPixelText(context, text, 80, 112, game.isFailed ? '#ff3344' : '#ffee44', {scale: game.isFailed ? 4 : 3, align: 'center', shadow: '#000000'});
		}

		drawPixelText(context, formatScore(game.score), 20, 228, '#ffffff', {scale: 2});
		drawPixelText(context, song.title, 312, 6, '#ffffff', {align: 'right'});
		drawPixelText(context, this.#stageLabel, 312, 14, '#ffcc00', {align: 'right'});
		drawPixelText(context, `${difficultyNames[game.difficulty]} ${footRating(game.songId, game.difficulty)}`, 312, 22, '#99ccff', {align: 'right'});

		if (game.screen === 'ending') {
			this.#setPose(game.isFailed ? 'slump' : 'cheer');
		} else if (!this.reducedMotion && time >= 0) {
			this.#danceToBeat(Math.floor(time / song.beat), now);
		}

		drawDancer(context, this.#settings.dancer, 236, 204, this.#currentPose(now));
	}

	#drawTitle(now) {
		const context = this.#context;
		const settings = this.#settings;
		const game = this.#game;
		this.#drawBackground(0, now);
		const song = songs[settings.song];
		drawPixelText(context, 'DANS DANS', 80, 14, '#ff66cc', {scale: 4, align: 'center', shadow: '#330044'});
		drawPixelText(context, 'REVOLUSJON', 80, 38, '#ffcc00', {scale: 3, align: 'center', shadow: '#330044'});

		context.fillStyle = 'rgba(0, 0, 20, 0.8)';
		context.fillRect(12, 64, 136, 104);
		context.strokeStyle = '#ff66cc';
		context.lineWidth = 2;
		context.strokeRect(13, 65, 134, 102);
		drawPixelText(context, 'SELECT MUSIC', 80, 70, '#99ccff', {align: 'center'});
		drawPixelText(context, song.title, 80, 82, '#ffffff', {scale: pixelTextWidth(song.title, 2) <= 128 ? 2 : 1, align: 'center'});
		drawPixelText(context, song.artist, 80, 98, '#ffcc00', {align: 'center'});
		drawPixelText(context, `${song.bpm} BPM`, 80, 106, '#ffcc00', {align: 'center'});
		const rating = footRating(settings.song, settings.difficulty);
		drawPixelText(context, difficultyNames[settings.difficulty], 80, 118, '#66ff99', {scale: 2, align: 'center'});
		for (let foot = 0; foot < 10; foot++) {
			context.fillStyle = foot < rating ? (foot < 4 ? '#66ff99' : (foot < 7 ? '#ffcc00' : '#ff3355')) : '#333a50';
			context.fillRect(30 + (foot * 10), 133, 7, 5);
		}

		const best = this.#bestScores[`${settings.song}/${settings.difficulty}`];
		drawPixelText(context, best ? `BEST ${best.grade}  ${formatScore(best.score)}` : 'NO RECORD YET', 80, 146, '#ffffff', {align: 'center'});
		drawPixelText(context, `SPEED ×${settings.speed}${settings.isStill ? '  STILL' : ''}`, 80, 156, '#99a3bb', {align: 'center'});

		const isBlinkOn = this.reducedMotion || Math.floor(now / 500) % 2 === 0;
		if (isBlinkOn) {
			drawPixelText(context, game.stagesLeft > 0 ? 'PRESS START' : 'INSERT COIN', 80, 176, '#ffffff', {scale: 2, align: 'center'});
		}

		drawPixelText(context, game.stagesLeft > 0 ? `CREDIT: ${game.stagesLeft} STAGES` : '10 KR = 3 STAGES', 80, 194, '#ffcc00', {align: 'center'});
		drawPixelText(context, 'TAP HERE TO DANCE (SOUND!)', 80, 208, '#99ccff', {align: 'center'});
		drawPixelText(context, '(C) 1999 SINDRE, NOT KONAMI', 80, 226, '#666e88', {align: 'center'});

		if (!this.reducedMotion) {
			this.#danceToBeat(Math.floor(now / 1000 / song.beat), now);
		}

		drawDancer(context, settings.dancer, 236, 204, this.#currentPose(now));
	}

	#drawResults(now) {
		const context = this.#context;
		const game = this.#game;
		this.#drawBackground(0, now);
		const {grade, isFullCombo, isRecord} = game.result;
		context.fillStyle = 'rgba(0, 0, 20, 0.75)';
		context.fillRect(8, 8, 304, 224);
		drawPixelText(context, game.isFailed ? 'FAILED...' : (game.isDemo ? 'TROND\'S RESULT' : `${this.#stageLabel} CLEAR!`), 160, 14, game.isFailed ? '#ff3344' : '#ffcc00', {scale: 2, align: 'center'});
		drawPixelText(context, songs[game.songId].title, 160, 30, '#ffffff', {align: 'center'});

		let color = gradeColors[grade];
		if (grade === 'AAA' && !this.reducedMotion) {
			color = `hsl(${(now / 4) % 360}, 100%, 65%)`;
		}

		drawPixelText(context, grade, 72, 64, color, {scale: grade.length === 3 ? 8 : 11, align: 'center', shadow: '#330044'});
		if (isFullCombo) {
			drawPixelText(context, 'FULL COMBO!', 72, 132, '#66ff99', {scale: 2, align: 'center'});
		}

		if (isRecord && (this.reducedMotion || Math.floor(now / 400) % 2 === 0)) {
			drawPixelText(context, 'NEW RECORD!', 72, 150, '#ff66cc', {scale: 2, align: 'center'});
		}

		const lines = [
			['PERFECT', game.counts.perfect, judgments[0].color],
			['GREAT', game.counts.great, judgments[1].color],
			['GOOD', game.counts.good, judgments[2].color],
			['BOO', game.counts.boo, judgments[3].color],
			['MISS', game.counts.miss, missJudgment.color],
			['OK', game.counts.ok, '#ffee44'],
			['NG', game.counts.ng, '#ff3344'],
			['MAX COMBO', game.maxCombo, '#ffffff'],
		];
		for (const [index, [label, count, labelColor]] of lines.entries()) {
			const y = 44 + (index * 13);
			drawPixelText(context, label, 150, y, labelColor, {scale: 2});
			drawPixelText(context, count, 304, y, '#ffffff', {scale: 2, align: 'right'});
		}

		drawPixelText(context, 'SCORE', 150, 158, '#ffcc00', {scale: 2});
		drawPixelText(context, formatScore(game.score), 304, 174, '#ffffff', {scale: 2, align: 'right'});

		let footer = 'PRESS START FOR THE NEXT STAGE';
		if (game.isDemo) {
			footer = game.stagesLeft > 0 ? 'NOW YOU! PRESS START' : 'NOW YOU! INSERT A COIN';
		} else if (game.stagesLeft === 0) {
			footer = 'GAME OVER. THANK YOU FOR PLAYING!';
		}

		// At scale 2, as a phone shows the canvas at about its own size, where the small letters are too small to read.
		drawPixelText(context, footer, 160, 212, '#99ccff', {scale: 2, align: 'center'});
	}

	#drawCalibration(now) {
		const context = this.#context;
		const calibration = this.#calibration;
		const {delay} = this.#settings;
		this.#drawBackground(0, now);
		context.fillStyle = 'rgba(0, 0, 20, 0.8)';
		context.fillRect(8, 8, 304, 224);
		drawPixelText(context, 'CALIBRATE THE DELAY', 160, 16, '#ffcc00', {scale: 2, align: 'center'});
		const time = this.#calibrationTimeAt(now);
		const beat = Math.floor(time / calibration.beat);
		const phase = time / calibration.beat - beat;
		const isOnBeat = time >= 0 && phase < 0.2 && beat < calibration.beats;
		for (let lane = 0; lane < 4; lane++) {
			traceArrow(context, 100 + (lane * 40), 70, lane, 1.3);
			context.fillStyle = isOnBeat ? (beat % 4 === 0 ? '#ff66cc' : '#ffee44') : '#222a3e';
			context.fill();
			context.lineWidth = 2;
			context.strokeStyle = '#ffffff';
			context.stroke();
		}

		let instruction = 'LISTEN...';
		if (beat >= 0 && beat < 4) {
			instruction = `${4 - beat}`;
		} else if (beat >= 4 && beat < calibration.beats) {
			instruction = 'STEP ON EACH BEAT!';
		} else if (beat >= calibration.beats) {
			instruction = 'DONE!';
		}

		drawPixelText(context, instruction, 160, 100, '#ffffff', {scale: 3, align: 'center'});
		drawPixelText(context, `STEPS: ${calibration.taps.length}/12`, 160, 128, '#99ccff', {scale: 2, align: 'center'});

		// A line of how early or late each step was: early to the left, late to the right.
		const lineY = 170;
		context.fillStyle = '#555e78';
		context.fillRect(40, lineY, 240, 2);
		context.fillStyle = '#ffffff';
		context.fillRect(159, lineY - 8, 2, 18);
		drawPixelText(context, 'EARLY', 40, lineY + 10, '#99a3bb', {scale: 2});
		drawPixelText(context, 'LATE', 280, lineY + 10, '#99a3bb', {scale: 2, align: 'right'});
		for (const tap of calibration.taps) {
			const x = 160 + clamp(tap * 600, -118, 118);
			context.fillStyle = '#ff66cc';
			context.fillRect(Math.round(x) - 2, lineY - 4, 4, 10);
		}

		drawPixelText(context, `NOW: ${delay > 0 ? '+' : ''}${delay} MS`, 160, 206, '#ffcc00', {scale: 2, align: 'center'});
	}

	#draw(now = performance.now()) {
		const {screen, result} = this.#game;
		this.#context.imageSmoothingEnabled = false;
		if (screen === 'playing' || screen === 'ending') {
			this.#drawPlaying(this.#songTimeAt(now), now);
		} else if (screen === 'results' && result) {
			this.#drawResults(now);
		} else if (screen === 'calibrating') {
			this.#drawCalibration(now);
		} else {
			this.#drawTitle(now);
		}
	}

	// MARK: The buttons

	#updateBest() {
		for (const label of this.querySelectorAll('[data-ddr-best]')) {
			const best = this.#bestScores[`${label.dataset.ddrBest}/${this.#settings.difficulty}`];
			label.textContent = best ? `Best: ${best.grade} · ${best.score.toLocaleString('en-US')}` : 'No record yet';
		}
	}

	#updateFeet() {
		for (const label of this.querySelectorAll('[data-ddr-feet]')) {
			label.textContent = `🦶 ×${footRating(this.#settings.song, label.dataset.ddrFeet)}`;
		}
	}

	#updateChoices() {
		const settings = this.#settings;
		const {speed, still, announcer} = this.parts;
		for (const button of this.querySelectorAll('[data-ddr-song]')) {
			setPressed(button, button.dataset.ddrSong === settings.song);
		}

		for (const button of this.querySelectorAll('[data-ddr-difficulty]')) {
			setPressed(button, button.dataset.ddrDifficulty === settings.difficulty);
		}

		for (const button of this.querySelectorAll('[data-ddr-dancer]')) {
			setPressed(button, button.dataset.ddrDancer === settings.dancer);
		}

		setPressed(still, settings.isStill);
		setPressed(announcer, settings.isAnnouncerOn);
		speed.textContent = `Speed: ×${settings.speed}`;
		this.#updateBest();
		this.#updateFeet();
	}

	#updateDelay() {
		const {delay} = this.parts;
		const milliseconds = this.#settings.delay;
		delay.textContent = `Delay: ${milliseconds > 0 ? '+' : ''}${milliseconds} ms`;
	}

	#backToTitle() {
		if (this.#game.screen === 'results') {
			this.#game.screen = 'title';
		}
	}

	#changeDelay(change) {
		const settings = this.#settings;
		settings.delay = clamp(settings.delay + change, -300, 300);
		this.#saveSettings();
		this.#updateDelay();
		this.say(`Delay: ${settings.delay > 0 ? '+' : ''}${settings.delay} ms. ${change > 0 ? 'The arrows wait longer for the feet.' : 'The arrows wait less for the feet.'}`);
		this.#draw();
	}
}
