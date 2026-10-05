// The karaoke machine of the Music Room on the 1999 page. A song is lines of syllables, each with its MIDI note and its length in beats, and two chords for each line, one a bar. The ball hops to each syllable when it is sung. Key Change moves the rest of the song up a semitone. It plays through the sound card of the Music Room, `geocities-sound-card.js`.
import {context, master, connectVolume, startAudio, midiFrequency, tone, pluck, noiseHit, drums, chords, startPlaying, stopPlaying, makeBus, fadeOut} from '/scripts/geocities-sound-card.js';

const randomInteger = (minimum, maximum) => minimum + Math.floor(Math.random() * (maximum - minimum + 1));

export default class extends GeoCitiesElement {
	#lastSongButton;

	connected() {
		const {ball, banner, songTitle, keyChange: keyChangeButton, stop: stopButton, echo: echoInput, guide: guideInput, judges} = this.parts;
		connectVolume(this.querySelectorAll('[data-music-volume]'), this.signal);
		const songButtons = [...this.querySelectorAll('[data-karaoke-song]')];
		const lines = [...this.querySelectorAll('[data-karaoke-line]')];

		// A syllable is written as `text:note:beats`, and a syllable that ends with a hyphen is joined to the next.
		const songs = {
			modem: {
				title: 'My Modem Loves Me',
				tempo: 116,
				lines: [
					['When:64:1 I:64:1 dial:67:1 in:67:1 late:69:1 at:69:1 night:67:2', 'C F'],
					['my:65:1 mo-:65:1 dem:64:1 starts:64:1 to:62:1 sing:60:3', 'Dm C'],
					['Beep:72:1 beep,:72:1 krrr-:71:1 shhh,:71:1 ding:69:1 ding:67:3', 'Am G'],
					['it’s:65:1 the:67:1 sweet-:69:1 est:71:1 thing!:72:4', 'F C'],
					['Mom,:64:1 please:64:1 don’t:67:1 pick:67:1 up:69:1 the:69:1 phone,:67:2', 'C F'],
					['I’m:65:1 down-:65:1 load-:64:1 ing:64:1 a:62:1 song:60:3', 'Dm C'],
					['Fif-:72:1 ty-:72:1 six:71:1 K:71:1 of:69:1 love,:67:3', 'Am G'],
					['it:65:1 takes:67:1 all:69:1 night:71:1 long!:72:4', 'F C'],
				],
			},
			waffles: {
				title: 'Waffles on a Sunday',
				tempo: 128,
				lines: [
					['Waf-:67:1 fles:67:1 on:71:1 a:71:1 Sun-:74:1 day:74:1 morn,:72:2', 'G C'],
					['heart-:72:1 shaped,:72:1 warm,:71:1 and:71:1 brown,:69:4', 'C D'],
					['with:67:1 brown:67:1 cheese:71:1 on:71:1 the:74:1 top,:76:3', 'G C'],
					['I:74:1 eat:72:1 them:71:1 till:69:1 I:71:1 drop!:67:3', 'D G'],
					['Mor-:67:1 mor:67:1 makes:71:1 a:71:1 stack:74:4', 'G D'],
					['as:72:1 tall:72:1 as:71:1 Gald-:71:1 hø-:69:1 pig-:69:1 gen,:67:2', 'C G'],
					['La:76:1 la:74:1 la,:72:1 brun-:71:1 ost!:69:4', 'C D'],
					['Waf-:67:1 fles,:71:1 here:74:1 I:72:1 come!:67:4', 'D G'],
				],
			},
		};

		const parseLine = ([syllables, chordNames]) => ({
			syllables: syllables.split(' ').map(syllable => {
				const [text, note, beats] = syllable.split(':');
				return {text, note: Number(note), beats: Number(beats)};
			}),
			chords: chordNames.split(' ').map(name => chords[name]),
		});

		let song;
		let bus;
		let echoGain;
		let feedbackGain;
		let transpose = 0;
		let keyChanges = 0;
		let timers = [];
		this.#lastSongButton = songButtons[0];
		let lineIndex = 0;
		let ballPosition;

		// The echo of a karaoke machine: a delay that feeds back into itself, a little quieter each time, so it always dies away. The echoes go to the room, not back into the delay.
		const makeEchoBus = () => {
			const input = makeBus();
			const delay = new DelayNode(context, {delayTime: 0.27});
			feedbackGain = new GainNode(context, {gain: (Number(echoInput.value) / 100) * 0.55});
			echoGain = new GainNode(context, {gain: Number(echoInput.value) / 100});
			input.connect(delay);
			delay.connect(feedbackGain).connect(delay);
			delay.connect(echoGain).connect(master);
			return input;
		};

		this.on(echoInput, 'input', () => {
			const amount = Number(echoInput.value) / 100;
			feedbackGain?.gain.setTargetAtTime(amount * 0.55, context.currentTime, 0.05);
			echoGain?.gain.setTargetAtTime(amount, context.currentTime, 0.05);
		});

		const later = (time, callback) => {
			timers.push(setTimeout(callback, Math.max(0, (time - context.currentTime) * 1000)));
		};

		// Shows a line on each row of the screen, with a span for each syllable.
		const showLines = index => {
			lineIndex = index;

			for (const [row, element] of lines.entries()) {
				element.replaceChildren();
				const line = song.lines[index + row];

				if (!line) {
					continue;
				}

				for (const [position, syllable] of line.syllables.entries()) {
					const span = document.createElement('span');
					span.textContent = syllable.text;
					element.append(span);

					if (!syllable.text.endsWith('-') && position < line.syllables.length - 1) {
						element.append(' ');
					}
				}
			}
		};

		// The ball hops from where it is to above the syllable. Visitors who prefer reduced motion see the words light up instead, as the ball is hidden.
		const hopTo = (span, duration) => {
			const x = span.offsetLeft + (span.offsetWidth / 2) - 8;
			const y = span.offsetTop - 18;
			ball.dataset.state = 'on';

			if (ballPosition && !this.reducedMotion) {
				ball.animate([
					{translate: `${ballPosition.x}px ${ballPosition.y}px`},
					{translate: `${(ballPosition.x + x) / 2}px ${Math.min(ballPosition.y, y) - 22}px`},
					{translate: `${x}px ${y}px`},
				], {duration: Math.min(duration, 0.45) * 1000, easing: 'linear'});
			}

			ball.style.translate = `${x}px ${y}px`;
			ballPosition = {x, y};
		};

		const stop = () => {
			for (const timer of timers) {
				clearTimeout(timer);
			}

			timers = [];
			fadeOut(bus);
			bus = undefined;

			// The echo rings out, and is then taken from the room, as a delay that feeds back into itself would else run forever.
			const echo = echoGain;
			setTimeout(() => {
				echo?.disconnect();
			}, 3000);

			stopPlaying(player);
			delete ball.dataset.state;
			ballPosition = undefined;
			banner.hidden = true;
			songTitle.textContent = '♪ Pick a song and press Sing! ♪';

			for (const line of lines) {
				line.replaceChildren();
			}

			keyChangeButton.disabled = true;
			stopButton.disabled = true;
		};

		const player = {stop};

		// The audience claps: many short bursts of noise at random times.
		const applause = () => {
			const applauseBus = makeBus();
			const time = context.currentTime + 0.05;

			for (let clap = 0; clap < 40; clap++) {
				noiseHit({time: time + (Math.random() * 2), duration: 0.03, destination: applauseBus, volume: 0.15 + (Math.random() * 0.15), type: 'bandpass', frequency: 1000 + (Math.random() * 1500), Q: 1.5});
			}

			setTimeout(() => {
				applauseBus.disconnect();
			}, 3000);
		};

		const showJudges = () => {
			const echo = Number(echoInput.value);
			const comments = [];
			let mamma = randomInteger(7, 9);
			let kevin = randomInteger(1, 5);

			// Kevin likes key changes, up to three. More than five is too much for Mamma, and for the dog next door.
			if (keyChanges > 5) {
				mamma = 5;
				kevin += 6;
				comments.push(`${keyChanges} key changes! The dog next door started to howl along. Mamma covered her ears.`);
			} else if (keyChanges > 0) {
				mamma = Math.min(mamma + 1, 10);
				kevin += Math.min(keyChanges, 3) * 2;
				comments.push(keyChanges >= 3 ? `${keyChanges} key changes! Westlife would be proud.` : 'The key change gave Mamma goosebumps. Kevin wanted more.');
			} else {
				comments.push('Kevin: “Where was the key change? Every good song has a key change.”');
			}

			if (echo > 80) {
				comments.push('So much echo! It sounded like you sang in Nidaros Cathedral.');
			}

			if (!guideInput.checked) {
				kevin += 1;
				comments.push('You sang without the melody. Brave!');
			}

			kevin = Math.min(kevin, 10);
			const total = 10 + mamma + kevin;
			const kevinSays = kevin >= 8 ? 'OK, that was actually cool.' : (kevin >= 5 ? 'Not bad, for a nerd.' : 'My cat sings better.');
			judges.hidden = false;

			// The text is set a frame after the box shows, so screen readers announce it.
			requestAnimationFrame(() => {
				judges.replaceChildren(...[
					'THE JUDGES SAY:',
					'Mormor: 10. “Beautiful! Just like when you were little.”',
					`Mamma: ${mamma}. “Now do your homework.”`,
					`Kevin from school: ${kevin}. “${kevinSays}”`,
					...comments,
					`Total: ${total} of 30 points!${total >= 27 ? ' A STAR IS BORN!' : ''}`,
				].map(text => {
					const paragraph = document.createElement('p');
					paragraph.textContent = text;
					return paragraph;
				}));
			});

			if (total >= 27) {
				this.celebrate();
				// Glitter cheers for a big win of the Music Room too, like for the other wins of the page.
				this.cheer();
			}
		};

		const sing = (id, button) => {
			if (!startAudio()) {
				return;
			}

			stop();
			startPlaying(player);
			this.#lastSongButton = button;
			song = {...songs[id], lines: songs[id].lines.map(line => parseLine(line))};
			bus = makeEchoBus();
			transpose = 0;
			keyChanges = 0;
			judges.hidden = true;
			keyChangeButton.disabled = false;
			stopButton.disabled = false;
			songTitle.textContent = `♪ ${song.title} ♪`;
			showLines(0);

			const beat = 60 / song.tempo;
			let time = context.currentTime + 0.1;

			// Four clicks to count in, like the machine does.
			for (let count = 0; count < 4; count++) {
				drums.hat(time + (count * beat), bus, 0.3);
			}

			time += 4 * beat;

			for (const [index, line] of song.lines.entries()) {
				const lineStart = time;

				// The backing: the bass on beats 1 and 3, a chord on 2 and 4, and the drums. Each bar is scheduled when its time comes, so a key change moves the next bars.
				for (const [bar, chord] of line.chords.entries()) {
					const barStart = lineStart + (bar * 4 * beat);
					later(barStart - 0.15, () => {
						for (let step = 0; step < 4; step++) {
							const stepTime = barStart + (step * beat);
							drums.hat(stepTime + (beat / 2), bus, 0.08);

							if (step % 2 === 0) {
								drums.kick(stepTime, bus, 0.6);
								pluck({frequency: midiFrequency(chord[0] - 12 + transpose + (step === 2 ? 7 : 0)), time: stepTime, duration: beat * 1.5, destination: bus, type: 'triangle', volume: 0.4});
							} else {
								drums.snare(stepTime, bus, 0.25);

								for (const note of chord) {
									pluck({frequency: midiFrequency(note + transpose), time: stepTime, duration: beat * 0.8, destination: bus, type: 'square', volume: 0.04, filter: {type: 'lowpass', frequency: 1600}});
								}
							}
						}
					});
				}

				// The syllables: the melody, the ball, and the words that turn yellow.
				for (const [position, syllable] of line.syllables.entries()) {
					const syllableTime = time;
					const duration = syllable.beats * beat;

					later(syllableTime - 0.1, () => {
						if (guideInput.checked) {
							tone({frequency: midiFrequency(syllable.note + transpose), time: syllableTime, duration: duration * 0.9, destination: bus, type: 'triangle', volume: 0.3, attack: 0.02, release: 0.08});
						}
					});

					later(syllableTime, () => {
						if (lineIndex !== index) {
							showLines(index);
						}

						const span = lines[0].children[position];
						span.dataset.state = 'sung';
						hopTo(span, beat);
					});

					time += duration;
				}
			}

			later(time + beat, () => {
				stop();
				applause();
				songTitle.textContent = '♪ Thank you! Thank you very much! ♪';
				showJudges();
			});
		};

		for (const button of songButtons) {
			this.on(button, 'click', () => {
				sing(button.dataset.karaokeSong, button);
			});
		}

		this.on(keyChangeButton, 'click', () => {
			transpose++;
			keyChanges++;
			banner.hidden = false;
			later(context.currentTime + 1.5, () => {
				banner.hidden = true;
			});
		});

		this.on(stopButton, 'click', stop);
	}

	// Key Change and Stop are turned off when the song ends, so the focus goes back to the song that was sung.
	focusReplacement(control) {
		const {keyChange, stop} = this.parts;
		return control === keyChange || control === stop ? this.#lastSongButton : super.focusReplacement(control);
	}
}
