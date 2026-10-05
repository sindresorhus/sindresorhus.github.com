// WaffleJay ’99 on the 1999 page, a music program like Dance eJay: each sample is one bar of sixteen steps, which follows the chord of its bar. The four chords repeat (A minor, F, C, G), so every sample fits with every other. The mix and the best place on the chart are kept in the browser. It plays through the sound card of the Music Room, `geocities-sound-card.js`.
import {context, connectVolume, startAudio, noiseBuffer, midiFrequency, tone, pluck, noiseHit, voice, drums, chords, startPlaying, stopPlaying, makeBus, fadeOut, Clock} from '/scripts/geocities-sound-card.js';

const clamp = (value, minimum, maximum) => Math.min(Math.max(value, minimum), maximum);
const randomItem = items => items[Math.floor(Math.random() * items.length)];
const randomInteger = (minimum, maximum) => minimum + Math.floor(Math.random() * (maximum - minimum + 1));

export default class extends GeoCitiesElement {
	connected() {
		const {play: playButton, status, hit, clear, release, songTitle, chart: chartBox, place: placeText, review, best: bestText, ghostTemplate} = this.parts;
		connectVolume(this.querySelectorAll('[data-music-volume]'), this.signal);
		const sampleButtons = [...this.querySelectorAll('[data-jay-sample]')];
		const cells = [...this.querySelectorAll('[data-jay-cell]')];
		const barNumbers = [...this.querySelectorAll('[data-jay-bar]')];
		const trackCount = 6;
		const barCount = 8;
		const tempo = 140;
		const stepLength = 60 / tempo / 4;
		const progression = [chords.Am, chords.F, chords.C, chords.G];

		const samples = {
			kick(step, time, chord, bus) {
				if (step % 4 === 0) {
					drums.kick(time, bus);
				}

				if (step % 4 === 2) {
					drums.openHat(time, bus, 0.1);
				}
			},
			break(step, time, chord, bus) {
				if ([0, 6, 10].includes(step)) {
					drums.kick(time, bus, 0.8);
				}

				if (step === 4 || step === 12) {
					drums.snare(time, bus);
				}

				if (step === 7 || step === 15) {
					drums.snare(time, bus, 0.15);
				}

				if (step % 2 === 0) {
					drums.hat(time, bus, 0.1);
				}
			},
			hats(step, time, chord, bus) {
				if (step === 14) {
					drums.openHat(time, bus);
				} else {
					drums.hat(time, bus, step % 4 === 2 ? 0.2 : 0.08);
				}
			},
			roll(step, time, chord, bus) {
				// A snare roll that gets louder, the build-up before the drop.
				drums.snare(time, bus, 0.08 + (step * 0.03));
			},
			bounce(step, time, chord, bus) {
				if (step % 4 === 2) {
					pluck({frequency: midiFrequency(chord[0] - 12), time, duration: 0.2, destination: bus, type: 'sawtooth', volume: 0.35, filter: {type: 'lowpass', frequency: 700}});
				}
			},
			acid(step, time, chord, bus, bar) {
				// The squelch of a Roland TB-303: a sawtooth through a filter that rings, which opens and closes.
				const pattern = [0, 0, 12, 0, 3, 0, 7, 12, 0, 0, 10, 0, 3, 7, 0, 12];
				const sweep = 300 + (2200 * (0.5 + (0.5 * Math.sin(((bar * 16) + step) / 5))));
				tone({frequency: midiFrequency(chord[0] - 12 + pattern[step]), time, duration: stepLength * 0.9, destination: bus, type: 'sawtooth', volume: 0.16, filter: {type: 'lowpass', frequency: sweep, Q: 12}});
			},
			sub(step, time, chord, bus) {
				if (step !== 0) {
					return;
				}

				// A long bass note through a filter that wobbles eight times a bar.
				const oscillator = new OscillatorNode(context, {type: 'sawtooth', frequency: midiFrequency(chord[0] - 12)});
				const filter = new BiquadFilterNode(context, {type: 'lowpass', frequency: 500, Q: 6});
				const wobble = new OscillatorNode(context, {type: 'sine', frequency: 2 / (stepLength * 4)});
				wobble.connect(new GainNode(context, {gain: 400})).connect(filter.frequency);
				const envelope = new GainNode(context, {gain: 0});
				const length = stepLength * 16;
				envelope.gain.setValueAtTime(0, time);
				envelope.gain.linearRampToValueAtTime(0.3, time + 0.02);
				envelope.gain.setValueAtTime(0.3, time + length - 0.05);
				envelope.gain.linearRampToValueAtTime(0, time + length);
				oscillator.connect(filter).connect(envelope).connect(bus);

				for (const node of [oscillator, wobble]) {
					node.start(time);
					node.stop(time + length);
				}
			},
			hoover(step, time, chord, bus) {
				if (step !== 0 && step !== 8) {
					return;
				}

				// The hoover of rave music: detuned sawtooths that swoop up into the chord.
				for (const note of chord) {
					for (const detune of [-25, 25]) {
						tone({frequency: midiFrequency(note - 2), slideTo: midiFrequency(note), time, duration: stepLength * 7, destination: bus, type: 'sawtooth', volume: 0.045, detune, attack: 0.02, release: 0.1, filter: {type: 'lowpass', frequency: 2400}});
					}
				}
			},
			piano(step, time, chord, bus) {
				if (![0, 3, 6, 10, 13].includes(step)) {
					return;
				}

				for (const note of chord) {
					pluck({frequency: midiFrequency(note + 12), time, duration: 0.35, destination: bus, type: 'square', volume: 0.07, filter: {type: 'lowpass', frequency: 2500}});
					pluck({frequency: midiFrequency(note + 24), time, duration: 0.25, destination: bus, type: 'triangle', volume: 0.05});
				}
			},
			arp(step, time, chord, bus) {
				const note = chord[step % 3] + 12 + (12 * (Math.floor(step / 3) % 2));
				pluck({frequency: midiFrequency(note), time, duration: 0.14, destination: bus, type: 'square', volume: 0.09, filter: {type: 'lowpass', frequency: 2200}});
			},
			hey(step, time, chord, bus) {
				if (step === 4 || step === 12) {
					noiseHit({time, duration: 0.05, destination: bus, volume: 0.25, type: 'bandpass', frequency: 1800, Q: 1});
					voice({frequency: 210, slideTo: 170, time: time + 0.03, duration: 0.25, destination: bus, from: 'e', to: 'i', volume: 0.45});
				}
			},
			ooh(step, time, chord, bus) {
				if (step === 0) {
					voice({frequency: midiFrequency(chord[2] + 12), time, duration: stepLength * 7.5, destination: bus, from: 'o', to: 'u', volume: 0.3, vibrato: 25});
				}

				if (step === 8) {
					voice({frequency: midiFrequency(chord[1] + 12), time, duration: stepLength * 7.5, destination: bus, from: 'u', to: 'o', volume: 0.3, vibrato: 25});
				}
			},
			robot(step, time, chord, bus) {
				// “Waf-fle, waf-fle”, monotone, like a robot.
				if (step % 8 === 0) {
					voice({frequency: 110, time, duration: stepLength * 1.5, destination: bus, from: 'u', to: 'a', volume: 0.45});
				}

				if (step % 8 === 2) {
					voice({frequency: 98, time, duration: stepLength * 1.5, destination: bus, from: 'uh', to: 'o', volume: 0.45});
				}
			},
			siren(step, time, chord, bus) {
				if (step !== 0) {
					return;
				}

				const oscillator = new OscillatorNode(context, {type: 'square', frequency: 900});
				const sweep = new OscillatorNode(context, {type: 'triangle', frequency: 1 / (stepLength * 8)});
				sweep.connect(new GainNode(context, {gain: 300})).connect(oscillator.frequency);
				const envelope = new GainNode(context, {gain: 0});
				const length = stepLength * 16;
				envelope.gain.setValueAtTime(0, time);
				envelope.gain.linearRampToValueAtTime(0.05, time + 0.05);
				envelope.gain.setValueAtTime(0.05, time + length - 0.1);
				envelope.gain.linearRampToValueAtTime(0, time + length);
				oscillator.connect(new BiquadFilterNode(context, {type: 'lowpass', frequency: 3000})).connect(envelope).connect(bus);

				for (const node of [oscillator, sweep]) {
					node.start(time);
					node.stop(time + length);
				}
			},
			laser(step, time, chord, bus) {
				if ([0, 6, 12].includes(step)) {
					tone({frequency: 2400, slideTo: 120, time, duration: 0.18, destination: bus, type: 'square', volume: 0.07});
				}
			},
			riser(step, time, chord, bus) {
				if (step === 0) {
					// Noise that rises and gets louder for a whole bar, before the drop.
					const length = stepLength * 16;
					const source = new AudioBufferSourceNode(context, {buffer: noiseBuffer(context), loop: true});
					const filter = new BiquadFilterNode(context, {type: 'bandpass', frequency: 300, Q: 4});
					filter.frequency.setValueAtTime(300, time);
					filter.frequency.exponentialRampToValueAtTime(7000, time + length);
					const envelope = new GainNode(context, {gain: 0.001});
					envelope.gain.setValueAtTime(0.001, time);
					envelope.gain.exponentialRampToValueAtTime(0.5, time + length - 0.02);
					envelope.gain.linearRampToValueAtTime(0, time + length);
					source.connect(filter).connect(envelope).connect(bus);
					source.start(time);
					source.stop(time + length);
				}
			},
		};

		const groupOf = Object.fromEntries(sampleButtons.map(button => [button.dataset.jaySample, button.dataset.jayGroup]));
		const shortOf = Object.fromEntries(sampleButtons.map(button => [button.dataset.jaySample, button.dataset.jayShort]));
		const titleOf = Object.fromEntries(sampleButtons.map(button => [button.dataset.jaySample, button.textContent.trim()]));

		// The sample on each spot, track by track, or nothing. A stored name is only kept when it is a sample, not a property that every object has, like `constructor`.
		const storedMix = this.stored('mix', []);
		let mix = Array.from({length: trackCount * barCount}, (_, index) => (typeof storedMix[index] === 'string' && Object.hasOwn(samples, storedMix[index]) ? storedMix[index] : undefined));
		let selected = 'kick';

		// A mix that “Make Me a Hit!” made, which the visitor has not changed yet. The chart can tell.
		let isComputerMade = false;

		const showCell = index => {
			const cell = cells[index];
			const sample = mix[index];
			const track = Math.floor(index / barCount) + 1;
			const bar = (index % barCount) + 1;
			cell.textContent = sample ? shortOf[sample] : '';

			if (sample) {
				cell.dataset.jayGroup = groupOf[sample];
			} else {
				delete cell.dataset.jayGroup;
			}

			cell.setAttribute('aria-label', `Track ${track}, bar ${bar}: ${sample ? titleOf[sample] : 'empty'}`);
		};

		const showMix = () => {
			for (const index of mix.keys()) {
				showCell(index);
			}

			this.store('mix', mix);
		};

		const select = sample => {
			selected = sample;

			for (const button of sampleButtons) {
				const isSelected = button.dataset.jaySample === sample;
				button.setAttribute('aria-pressed', String(isSelected));

				if (isSelected) {
					button.dataset.state = 'selected';
				} else {
					delete button.dataset.state;
				}
			}
		};

		// The loop: eight bars, sixteen steps each, and the number of the bar lights up while it plays.
		let bus;
		const clock = new Clock({
			stepLength: () => stepLength,
			onStep(step, time) {
				const bar = Math.floor(step / 16) % barCount;
				const barStep = step % 16;
				const chord = progression[bar % 4];

				for (let track = 0; track < trackCount; track++) {
					const sample = mix[(track * barCount) + bar];

					if (sample) {
						samples[sample](barStep, time, chord, bus, bar);
					}
				}

				if (barStep === 0) {
					clock.atTime(time, () => {
						showPlayingBar(bar);
					});
				}
			},
		});

		const showPlayingBar = bar => {
			for (const [index, number] of barNumbers.entries()) {
				if (index === bar) {
					number.dataset.state = 'now';
				} else {
					delete number.dataset.state;
				}
			}

			for (const [index, cell] of cells.entries()) {
				if (index % barCount === bar) {
					cell.dataset.state = 'now';
				} else if (cell.dataset.state === 'now') {
					delete cell.dataset.state;
				}
			}
		};

		const player = {
			stop() {
				clock.stop();
				fadeOut(bus);
				bus = undefined;
				stopPlaying(player);
				showPlayingBar(-1);
				playButton.textContent = '▶ Play';
			},
		};

		this.on(playButton, 'click', () => {
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
			this.say(mix.some(Boolean) ? 'Playing your mix. Turn it up!' : 'Playing… silence. Put some samples on the tracks!');
		});

		// Previews a sample alone for one bar, while the loop does not play.
		let previewBus;
		const preview = sample => {
			if (clock.isRunning || !startAudio()) {
				return;
			}

			fadeOut(previewBus);
			previewBus = makeBus();
			const start = context.currentTime + 0.05;

			for (let step = 0; step < 16; step++) {
				samples[sample](step, start + (step * stepLength), progression[0], previewBus, 0);
			}
		};

		let draggedSample;

		for (const button of sampleButtons) {
			this.on(button, 'click', () => {
				select(button.dataset.jaySample);

				if (draggedSample) {
					draggedSample = undefined;
					return;
				}

				preview(button.dataset.jaySample);
				this.say(`${titleOf[selected]} is picked. Click a spot on the tracks to put it there.`);
			});
		}

		const place = (index, sample) => {
			if (mix[index] === sample) {
				mix[index] = undefined;
				this.say(`Removed ${titleOf[sample]}.`);
			} else {
				mix[index] = sample;
				this.say(`${titleOf[sample]} on track ${Math.floor(index / barCount) + 1}, bar ${(index % barCount) + 1}.`);
			}

			isComputerMade = false;
			showCell(index);
			this.store('mix', mix);
		};

		for (const [index, cell] of cells.entries()) {
			this.on(cell, 'click', () => {
				place(index, selected);
			});
		}

		// With a mouse or a pen, a sample can also be dragged onto the tracks, like in Dance eJay. A finger taps instead, so it can still scroll the page.
		let ghost;
		let dragStart;
		let target;

		const setTarget = cell => {
			if (target === cell) {
				return;
			}

			if (target?.dataset.state === 'target') {
				delete target.dataset.state;
			}

			target = cell;

			if (target) {
				target.dataset.state = 'target';
			}
		};

		for (const button of sampleButtons) {
			this.on(button, 'pointerdown', event => {
				if (event.pointerType === 'touch' || event.button !== 0) {
					return;
				}

				dragStart = {x: event.clientX, y: event.clientY, button, pointerId: event.pointerId};
			});
		}

		this.on(document, 'pointermove', event => {
			if (!dragStart || event.pointerId !== dragStart.pointerId) {
				return;
			}

			if (!ghost) {
				if (Math.hypot(event.clientX - dragStart.x, event.clientY - dragStart.y) < 6) {
					return;
				}

				ghost = ghostTemplate.content.firstElementChild.cloneNode(true);
				ghost.textContent = dragStart.button.dataset.jayShort;
				ghost.dataset.jayGroup = dragStart.button.dataset.jayGroup;
				document.body.append(ghost);
			}

			ghost.style.translate = `${event.clientX - 24}px ${event.clientY - 16}px`;
			setTarget(document.elementFromPoint(event.clientX, event.clientY)?.closest('[data-jay-cell]'));
		});

		const endDrag = event => {
			if (!dragStart || event.pointerId !== dragStart.pointerId) {
				return;
			}

			if (ghost) {
				draggedSample = dragStart.button.dataset.jaySample;

				if (target) {
					place(cells.indexOf(target), draggedSample);
				}

				ghost.remove();
				ghost = undefined;
				setTarget(undefined);

				// The click after a drag, which tells the sample not to play its preview, may land elsewhere, so the drag is forgotten after it.
				this.timeout(0, () => {
					draggedSample = undefined;
				});
			}

			dragStart = undefined;
		};

		this.on(document, 'pointerup', endDrag);
		this.on(document, 'pointercancel', endDrag);

		// Fills the tracks like a hit of 1999: an intro, a build-up with a snare roll and a riser, and a drop with everything.
		this.on(hit, 'click', () => {
			const fill = (track, sample, bars) => {
				for (const bar of bars) {
					mix[(track * barCount) + bar] = sample;
				}
			};

			mix = mix.map(() => undefined);
			fill(0, randomItem(['kick', 'kick', 'break']), [2, 4, 5, 6, 7]);
			fill(1, 'hats', [0, 1, 2, 4, 5, 6]);
			fill(1, 'roll', [3, 7]);
			fill(2, randomItem(['bounce', 'acid', 'sub']), [2, 3, 4, 5, 6, 7]);
			fill(3, randomItem(['piano', 'arp']), [0, 1, 2, 3]);
			fill(3, randomItem(['hoover', 'piano', 'arp']), [4, 5, 6, 7]);
			fill(4, randomItem(['hey', 'robot']), [4, 6]);
			fill(4, 'ooh', [2, 3]);
			fill(5, 'riser', [3]);
			fill(5, randomItem(['siren', 'laser']), [4]);
			fill(5, randomItem(['laser', 'riser']), [7]);
			showMix();
			isComputerMade = true;
			this.say('A hit, made by the computer! Press Play. The chart likes it more when you change something yourself.');
		});

		this.on(clear, 'click', () => {
			mix = mix.map(() => undefined);
			isComputerMade = false;
			showMix();
			this.say('All the tracks are empty.');
		});

		// The single goes to the Norwegian chart, VG-lista, and gets a place from how good the mix is: many kinds of samples, not too empty and not too full, a beat in most bars, a build-up before the drop, and not too many sirens.
		let best = this.stored('best', undefined);

		const showBest = () => {
			bestText.textContent = best?.place ? `My best so far: #${best.place} with “${best.title}”.` : '';
		};

		showBest();

		this.on(release, 'submit', event => {
			event.preventDefault();
			const title = songTitle.value.trim() || 'Untitled';
			const used = mix.filter(Boolean);
			const groups = new Set(used.map(sample => groupOf[sample]));
			const beatBars = Array.from({length: barCount}, (_, bar) => mix.some((sample, index) => index % barCount === bar && groupOf[sample] === 'beats')).filter(Boolean).length;
			const fx = used.filter(sample => groupOf[sample] === 'fx').length;
			const hasBuildUp = mix.some((sample, index) => (sample === 'roll' || sample === 'riser') && index % barCount === 3);
			const fullness = used.length / mix.length;
			const comments = [];

			let score = (groups.size * 11) + (new Set(used).size * 2) + ((beatBars / barCount) * 20);

			if (fullness >= 0.35 && fullness <= 0.8) {
				score += 12;
			} else if (fullness > 0.8) {
				comments.push('There is so much going on that my ears hurt.');
			} else {
				comments.push('It is a bit empty. Is the record finished?');
			}

			if (hasBuildUp) {
				score += 6;
				comments.push('The build-up in bar 4 gave me goosebumps!');
			}

			if (used.includes('hey')) {
				score += 4;
				comments.push('Everybody shouts “Hey!” with it at the school disco.');
			}

			if (fx > 6) {
				score -= 15;
				comments.push('Too many sirens. The neighbors called the police.');
			}

			if (isComputerMade) {
				score -= 30;
				comments.push('VG says it sounds like a computer made it. Change something and make it your own!');
			}

			if (beatBars < 3) {
				comments.push('Where is the beat? You cannot dance to this.');
			}

			if (!groups.has('bass')) {
				comments.push('It needs more bass. My dad’s car speakers agree.');
			}

			// The text is set a frame after the box shows, so screen readers announce it.
			const showChart = (heading, text) => {
				chartBox.hidden = false;
				requestAnimationFrame(() => {
					placeText.textContent = heading;
					review.textContent = text;
				});
			};

			if (used.length === 0) {
				showChart('Did not chart', `The record company sent “${title}” back with a note: “There is no music on this record.”`);
				return;
			}

			if (score < 25) {
				showChart('Did not chart', `“${title}” sold 12 copies, all to Mormor. ${comments.join(' ')}`);
				return;
			}

			// The charts are a bit random, like in real life.
			const chartPlace = clamp(Math.round(46 - ((score + randomInteger(-6, 6)) * 0.38)), 1, 40);
			const verdict = chartPlace === 1
				? 'NUMBER 1 IN NORWAY! Bigger than Aqua! Bigger than A1! Mormor bought 40 copies.'
				: (chartPlace <= 5
					? 'NRK P3 plays it every hour. Bring sunglasses to school.'
					: (chartPlace <= 20 ? 'The kids dance to it at the school disco.' : 'Mamma likes it. That counts.'));
			showChart(`#${chartPlace} on VG-lista Topp 40`, `“${title}”: ${verdict} ${comments.join(' ')}`);

			if (!best?.place || chartPlace < best.place) {
				best = {place: chartPlace, title: title.slice(0, 40)};
				this.store('best', best);
				showBest();
			}

			if (chartPlace === 1) {
				this.celebrate();
				// Glitter cheers for a big win of the Music Room too, like for the other wins of the page.
				this.cheer();
			}
		});

		select(selected);
		showMix();
	}
}
