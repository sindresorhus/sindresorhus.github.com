// The sound of a toy of the 1999 page that the visitor turns on and off with a sound button, like the beeper (`Beeper.js`) and the Kinderegg (`KinderEgg.js`): the audio of the element, through a gain, and the short tones and bursts of noise of the toy. Each toy has its own, like `const audio = new ToySound();`, so the sound of one toy can be on while the sound of another is off.
export default class ToySound {
	context;
	output;
	isOn = false;

	// Uses the audio of the element (`sound()`), which is `undefined` until the visitor clicks, as browsers only let audio play then. It returns whether the toy has audio now.
	start(sound) {
		if (!sound) {
			return false;
		}

		if (!this.context) {
			this.context = sound.context;
			this.output = this.context.createGain();
			this.output.gain.value = 0.6;
			this.output.connect(sound.output);
		}

		return true;
	}

	ensure() {
		if (this.context?.state === 'suspended') {
			this.context.resume();
		}

		return this.context;
	}

	// The audio context, only while the visitor has the sound on.
	soundContext() {
		return this.isOn ? this.ensure() : undefined;
	}

	tone(frequency, delay, duration, {type = 'sine', volume = 0.1, attack = 0.004} = {}) {
		const context = this.soundContext();
		if (!context) {
			return;
		}

		const start = context.currentTime + delay;
		const oscillator = context.createOscillator();
		const gain = context.createGain();
		oscillator.type = type;
		oscillator.frequency.value = frequency;
		gain.gain.setValueAtTime(0, start);
		gain.gain.linearRampToValueAtTime(volume, start + attack);
		gain.gain.setValueAtTime(volume, start + Math.max(attack, duration - 0.015));
		gain.gain.linearRampToValueAtTime(0, start + duration);
		oscillator.connect(gain).connect(this.output);
		oscillator.start(start);
		oscillator.stop(start + duration + 0.05);
	}

	// A short burst of noise, like a click or a crack.
	noise(delay, duration, {volume = 0.1, frequency = 3000} = {}) {
		const context = this.soundContext();
		if (!context) {
			return;
		}

		const buffer = context.createBuffer(1, Math.ceil(context.sampleRate * duration), context.sampleRate);
		const data = buffer.getChannelData(0);
		for (let index = 0; index < data.length; index++) {
			data[index] = ((Math.random() * 2) - 1) * (1 - (index / data.length));
		}

		const source = context.createBufferSource();
		source.buffer = buffer;
		const filter = context.createBiquadFilter();
		filter.type = 'bandpass';
		filter.frequency.value = frequency;
		const gain = context.createGain();
		gain.gain.value = volume;
		source.connect(filter).connect(gain).connect(this.output);
		source.start(context.currentTime + delay);
	}
}
