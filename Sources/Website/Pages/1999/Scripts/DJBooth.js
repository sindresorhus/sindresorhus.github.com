// The turntable of the DJ booth in the Music Room on the 1999 page. The record is two bars of a breakbeat, rendered once into a buffer. Scratching plays small pieces of it, forward or from a reversed copy, as fast as the record moves under the pointer. A record turns at 33⅓ RPM, so one turn is 1.8 seconds of music. It plays through the sound card of the Music Room, `geocities-sound-card.js`.
import {context, connectVolume, startAudio, midiFrequency, tone, pluck, voice, drums, startPlaying, stopPlaying, makeBus, addStopHandler} from '/scripts/geocities-sound-card.js';

const clamp = (value, minimum, maximum) => Math.min(Math.max(value, minimum), maximum);
const randomItem = items => items[Math.floor(Math.random() * items.length)];
const hasModifier = event => event.ctrlKey || event.metaKey || event.altKey;

export default class extends GeoCitiesElement {
	connected() {
		const {record, play: playButton, airHorn, rewind} = this.parts;
		connectVolume(this.querySelectorAll('[data-music-volume]'), this.signal);
		const secondsPerTurn = 1.8;
		const tempo = 95;
		const loopLength = (8 * 60) / tempo;
		let buffer;
		let reversedBuffer;
		let rendering;
		let deckBus;
		let beatSource;
		let beatStart = 0;
		let position = 0;
		let angle = 0;
		let isHolding = false;

		// Renders the record: a breakbeat, a bass line, and a voice that shouts “Ahh!” at the start of each bar, which is what DJs scratch.
		const renderRecord = () => {
			// A render that failed is tried again on the next press.
			rendering ??= (async () => {
				const offline = new OfflineAudioContext({numberOfChannels: 1, length: Math.ceil(loopLength * 44_100), sampleRate: 44_100});
				const destination = offline.destination;
				const sixteenth = 60 / tempo / 4;

				for (let step = 0; step < 32; step++) {
					const time = step * sixteenth;
					const barStep = step % 16;

					if ([0, 10].includes(barStep)) {
						drums.kick(time, destination);
					}

					if (barStep === 4 || barStep === 12) {
						drums.snare(time, destination, 0.5);
					}

					if (step % 2 === 0) {
						drums.hat(time, destination, 0.12);
					}

					if ([0, 3, 6, 8, 11].includes(barStep)) {
						pluck({frequency: midiFrequency(step < 16 ? 40 : 43), time, duration: sixteenth * 2, destination, type: 'sawtooth', volume: 0.25, filter: {type: 'lowpass', frequency: 500}});
					}
				}

				for (const bar of [0, 1]) {
					voice({frequency: bar === 0 ? 220 : 196, slideTo: bar === 0 ? 180 : 160, time: bar * 16 * sixteenth, duration: 0.45, destination, from: 'a', to: 'uh', volume: 0.6});
				}

				buffer = await offline.startRendering();
				reversedBuffer = new AudioBuffer({length: buffer.length, sampleRate: buffer.sampleRate});
				reversedBuffer.getChannelData(0).set(Float32Array.from(buffer.getChannelData(0)).reverse());
			})().catch(error => {
				rendering = undefined;
				throw error;
			});

			return rendering;
		};

		const wrap = seconds => ((seconds % loopLength) + loopLength) % loopLength;

		const currentPosition = () => (beatSource ? wrap(position + (context.currentTime - beatStart)) : position);

		const turnTo = degrees => {
			angle = degrees;
			record.style.rotate = `${angle}deg`;
		};

		// While the beat plays, the record turns with it, unless the visitor prefers reduced motion. It only turns while the record is on the screen and the tab is visible.
		const spinning = this.loop(() => {
			if (beatSource && !isHolding) {
				turnTo((currentPosition() / secondsPerTurn) * 360);
			}
		}, {while: () => isBeatOn && !this.reducedMotion, target: record});

		const startBeat = () => {
			beatSource = new AudioBufferSourceNode(context, {buffer, loop: true});
			beatSource.connect(deckBus);
			beatStart = context.currentTime + 0.02;
			beatSource.start(beatStart, position);
		};

		const pauseBeat = () => {
			position = currentPosition();
			beatSource?.stop();
			beatSource = undefined;
		};

		let isBeatOn = false;
		let rewindTimer;

		const player = {
			stop() {
				clearTimeout(rewindTimer);
				pauseBeat();
				isBeatOn = false;
				spinning.stop();
				stopPlaying(player);
				playButton.setAttribute('aria-pressed', 'false');
				playButton.textContent = '▶ Play the beat';
			},
		};

		const prepare = async () => {
			if (!startAudio()) {
				return false;
			}

			// The record is quiet, as it was rendered without any limit, so the deck turns it up.
			if (!deckBus) {
				deckBus = makeBus();
				deckBus.gain.value = 2;
			}
			await renderRecord();
			return true;
		};

		this.on(playButton, 'click', async () => {
			if (isBeatOn) {
				player.stop();
				this.say('The beat stopped. You can still scratch.');
				return;
			}

			// The record renders the first time, and a second press in the meantime must not start a second beat.
			if (!await prepare() || isBeatOn) {
				return;
			}

			startPlaying(player);
			isBeatOn = true;
			startBeat();
			spinning.start();
			playButton.setAttribute('aria-pressed', 'true');
			playButton.textContent = '■ Stop the beat';
			this.say('The beat is on! Now drag the record back and forth.');
		});

		// A piece of the record, from a position, moved by a number of seconds in a time. Moving back plays the reversed copy.
		const scratch = (start, change, duration) => {
			if (!buffer || Math.abs(change) < 0.0005) {
				return;
			}

			const isForward = change > 0;
			const length = Math.max(duration, 0.03);
			const source = new AudioBufferSourceNode(context, {buffer: isForward ? buffer : reversedBuffer, loop: true, playbackRate: clamp(Math.abs(change) / length, 0.1, 6)});
			const envelope = new GainNode(context, {gain: 0});
			const time = context.currentTime;
			envelope.gain.setValueAtTime(0, time);
			envelope.gain.linearRampToValueAtTime(1, time + 0.005);
			envelope.gain.setValueAtTime(1, time + length - 0.005);
			envelope.gain.linearRampToValueAtTime(0, time + length);
			source.connect(envelope).connect(deckBus);
			source.start(time, isForward ? start : wrap(loopLength - start));
			source.stop(time + length + 0.01);
		};

		const pointerAngle = event => {
			const bounds = record.getBoundingClientRect();
			return Math.atan2(event.clientY - (bounds.top + (bounds.height / 2)), event.clientX - (bounds.left + (bounds.width / 2)));
		};

		let lastAngle;
		let lastTime;
		let pointerId;

		this.on(record, 'pointerdown', async event => {
			if (event.pointerType === 'mouse' && event.button !== 0) {
				return;
			}

			event.preventDefault();
			record.focus({preventScroll: true});
			record.setPointerCapture(event.pointerId);
			pointerId = event.pointerId;
			isHolding = true;
			lastAngle = pointerAngle(event);
			lastTime = performance.now();

			if (!buffer) {
				this.say('Putting the needle on the record…');

				if (!await prepare()) {
					return;
				}

				this.say('The needle is on. Wikka wikka! Press Play the beat to scratch over it.');
			}

			// The hand stops the record.
			if (beatSource) {
				pauseBeat();
			}
		});

		this.on(record, 'pointermove', event => {
			if (!isHolding || event.pointerId !== pointerId || !buffer) {
				return;
			}

			const newAngle = pointerAngle(event);
			let change = newAngle - lastAngle;

			// The angle jumps by a whole turn where it goes past the left side.
			if (change > Math.PI) {
				change -= Math.PI * 2;
			} else if (change < -Math.PI) {
				change += Math.PI * 2;
			}

			const now = performance.now();
			const seconds = (change / (Math.PI * 2)) * secondsPerTurn;
			scratch(position, seconds, (now - lastTime) / 1000);
			position = wrap(position + seconds);
			turnTo(angle + ((change * 180) / Math.PI));
			lastAngle = newAngle;
			lastTime = now;
		});

		const letGo = event => {
			if (!isHolding || event.pointerId !== pointerId) {
				return;
			}

			isHolding = false;

			if (isBeatOn && buffer) {
				startBeat();
			}
		};

		this.on(record, 'pointerup', letGo);
		this.on(record, 'pointercancel', letGo);

		// The arrow keys scratch a quick “wikka” back or forth.
		this.on(record, 'keydown', async event => {
			if ((event.key !== 'ArrowLeft' && event.key !== 'ArrowRight') || hasModifier(event)) {
				return;
			}

			event.preventDefault();

			if (!await prepare()) {
				return;
			}

			const wasPlaying = Boolean(beatSource);
			pauseBeat();
			const change = event.key === 'ArrowRight' ? 0.18 : -0.18;
			scratch(position, change, 0.09);
			position = wrap(position + change);
			turnTo(angle + ((change / secondsPerTurn) * 360));

			if (wasPlaying) {
				setTimeout(() => {
					if (isBeatOn && !beatSource) {
						startBeat();
					}
				}, 100);
			}
		});

		this.on(airHorn, 'click', () => {
			if (!startAudio()) {
				return;
			}

			// The air horn: three blasts of brassy sawtooths, short, short, long.
			const time = context.currentTime + 0.02;

			for (const [start, length] of [[0, 0.16], [0.22, 0.16], [0.44, 0.7]]) {
				for (const [frequency, detune] of [[466, -10], [466, 10], [698, 0]]) {
					tone({frequency, slideTo: frequency * 0.96, time: time + start, duration: length, type: 'sawtooth', volume: 0.1, attack: 0.01, release: 0.05, detune, filter: {type: 'lowpass', frequency: 3200}});
				}
			}

			this.say(randomItem(['BWAAP BWAAP BWAAAAAP!', 'Big up the massive! BWAAAP!', 'Air horn! The crowd goes wild!']));
		});

		// The rewind: the record spins back fast, and the tune starts again from the top.
		this.on(rewind, 'click', async () => {
			if (!await prepare()) {
				return;
			}

			const start = currentPosition();
			pauseBeat();
			const source = new AudioBufferSourceNode(context, {buffer: reversedBuffer, loop: true, playbackRate: 4});
			const time = context.currentTime;
			source.playbackRate.setValueAtTime(4, time);
			source.playbackRate.linearRampToValueAtTime(0.3, time + 0.8);
			const envelope = new GainNode(context, {gain: 1});
			envelope.gain.setValueAtTime(1, time + 0.6);
			envelope.gain.linearRampToValueAtTime(0, time + 0.8);
			source.connect(envelope).connect(deckBus);
			source.start(time, wrap(loopLength - start));
			source.stop(time + 0.85);

			if (!this.reducedMotion) {
				record.animate([{rotate: `${angle}deg`}, {rotate: `${angle - 1080}deg`}], {duration: 800, easing: 'ease-out'});
			}

			this.say('Pull up! Wheel it up, selecta! From the top!');
			clearTimeout(rewindTimer);
			rewindTimer = setTimeout(() => {
				position = 0;
				turnTo(0);

				if (!isBeatOn) {
					startPlaying(player);
					isBeatOn = true;
					playButton.setAttribute('aria-pressed', 'true');
					playButton.textContent = '■ Stop the beat';
					spinning.start();
				}

				if (!isHolding) {
					startBeat();
				}
			}, 850);
		});

		// A rewind that started while the beat was off is not playing yet, so leaving the tab cancels it too.
		addStopHandler(() => {
			clearTimeout(rewindTimer);
		}, this.signal);
	}
}
