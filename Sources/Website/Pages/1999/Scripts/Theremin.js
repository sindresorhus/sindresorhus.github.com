// The theremin of the DJ booth in the Music Room on the 1999 page. It plays while the pointer or a finger holds it: across is the pitch, over three octaves, and up is louder. Auto-Tune rounds the pitch to the nearest note at once, which makes the jumpy sound of “Believe” by Cher. It plays through the sound card of the Music Room, `geocities-sound-card.js`.
import {context, master, connectVolume, startAudio, midiFrequency, noteName, addStopHandler} from '/scripts/geocities-sound-card.js';

const clamp = (value, minimum, maximum) => Math.min(Math.max(value, minimum), maximum);
const hasModifier = event => event.ctrlKey || event.metaKey || event.altKey;

export default class extends GeoCitiesElement {
	connected() {
		const {pad, hand, readout, autoTune, vibrato} = this.parts;
		connectVolume(this.querySelectorAll('[data-music-volume]'), this.signal);
		let oscillator;
		let output;
		let wobbleDepth;
		let x = 0.5;
		let y = 0.5;
		let pointerId;

		const pitch = () => {
			const frequency = 130.81 * (2 ** (x * 3));
			const note = Math.round((12 * Math.log2(frequency / 440)) + 69);
			return {note, frequency: autoTune.checked ? midiFrequency(note) : frequency};
		};

		const loudness = () => 0.04 + ((1 - y) * 0.3);

		const update = () => {
			hand.style.left = `${x * 100}%`;
			hand.style.top = `${y * 100}%`;
			const {note, frequency} = pitch();
			readout.textContent = `${noteName(note)} · ${Math.round(frequency)} Hz${oscillator ? ' · ♪' : ''}`;

			if (oscillator) {
				oscillator.frequency.setTargetAtTime(frequency, context.currentTime, autoTune.checked ? 0.004 : 0.03);
				output.gain.setTargetAtTime(loudness(), context.currentTime, 0.03);
			}
		};

		const start = () => {
			if (oscillator || !startAudio()) {
				return;
			}

			oscillator = new OscillatorNode(context, {type: 'sine', frequency: pitch().frequency});
			const wobble = new OscillatorNode(context, {frequency: 5.5});
			wobbleDepth = new GainNode(context, {gain: vibrato.checked ? 30 : 0});
			wobble.connect(wobbleDepth).connect(oscillator.detune);
			output = new GainNode(context, {gain: 0});
			oscillator.connect(output).connect(master);
			oscillator.start();
			wobble.start();
			this.on(oscillator, 'ended', () => {
				wobble.stop();
			});
			hand.dataset.state = 'on';
			update();
		};

		const stop = () => {
			if (!oscillator) {
				return;
			}

			output.gain.setTargetAtTime(0, context.currentTime, 0.05);
			oscillator.stop(context.currentTime + 0.3);
			oscillator = undefined;
			delete hand.dataset.state;
			update();
		};

		addStopHandler(stop, this.signal);

		const moveTo = event => {
			const bounds = pad.getBoundingClientRect();
			x = clamp((event.clientX - bounds.left) / bounds.width, 0, 1);
			y = clamp((event.clientY - bounds.top) / bounds.height, 0, 1);
			update();
		};

		this.on(pad, 'pointerdown', event => {
			if (event.pointerType === 'mouse' && event.button !== 0) {
				return;
			}

			event.preventDefault();
			pad.focus({preventScroll: true});
			pad.setPointerCapture(event.pointerId);
			pointerId = event.pointerId;
			moveTo(event);
			start();
			this.say('Woooo-eeee-oooo! Spooky!');
		});

		this.on(pad, 'pointermove', event => {
			if (event.pointerId === pointerId) {
				moveTo(event);
			}
		});

		const letGo = event => {
			if (event.pointerId === pointerId) {
				pointerId = undefined;
				stop();
			}
		};

		this.on(pad, 'pointerup', letGo);
		this.on(pad, 'pointercancel', letGo);

		// With the keyboard, Space or Enter turns the sound on and off, and the arrow keys move the hand.
		this.on(pad, 'keydown', event => {
			if (hasModifier(event)) {
				return;
			}

			const moves = {ArrowLeft: [-0.03, 0], ArrowRight: [0.03, 0], ArrowUp: [0, -0.05], ArrowDown: [0, 0.05]};

			if (moves[event.key]) {
				event.preventDefault();
				x = clamp(x + moves[event.key][0], 0, 1);
				y = clamp(y + moves[event.key][1], 0, 1);
				update();
			} else if (event.key === ' ' || event.key === 'Enter') {
				event.preventDefault();

				if (oscillator) {
					stop();
				} else {
					start();
				}
			} else if (event.key === 'Escape') {
				stop();
			}
		});

		this.on(pad, 'blur', stop);

		this.on(autoTune, 'change', () => {
			update();
			this.say(autoTune.checked ? 'Auto-Tune is on. Cher would be proud.' : 'Auto-Tune is off. Back to the spooky slide.');
		});

		this.on(vibrato, 'change', () => {
			wobbleDepth?.gain.setTargetAtTime(vibrato.checked ? 30 : 0, context.currentTime, 0.05);
		});

		update();
	}
}
