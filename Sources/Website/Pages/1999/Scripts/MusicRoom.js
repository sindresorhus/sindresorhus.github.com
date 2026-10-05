// The mixer of the sound card at the start of Sindre’s Music Room on the 1999 page, with a speaker test that asks if the visitor heard it, and a button that stops all the music of the room. The toys of the room play through the sound card of `geocities-sound-card.js`.
import {context, master, connectVolume, startAudio, pluck, midiFrequency, stopEverything} from '/scripts/geocities-sound-card.js';

const advice = [
	'Is the speaker plugged in? The green plug goes in the back of the computer.',
	'Is the speaker turned on? There is a little knob on the front.',
	'Is the volume up? Try the slider above, and the knob on the speaker.',
	'Did you try turning it off and on again?',
	'Did your big brother take the speakers to his room again?',
];

export default class extends GeoCitiesElement {
	#adviceIndex = 0;

	connected() {
		const {question, stopAll} = this.parts;
		connectVolume(this.querySelectorAll('[data-music-volume]'), this.signal);

		for (const button of this.querySelectorAll('[data-music-speaker]')) {
			this.on(button, 'click', () => {
				if (!startAudio()) {
					this.say('Your browser has no sound card. Sorry!');
					return;
				}

				const side = button.dataset.musicSpeaker;
				const panner = new StereoPannerNode(context, {pan: side === 'left' ? -1 : 1});
				panner.connect(master);
				const time = context.currentTime + 0.05;

				// A chime that goes up, like the sound test of a sound card.
				for (const [index, note] of [72, 76, 79, 84].entries()) {
					pluck({frequency: midiFrequency(note), time: time + (index * 0.12), duration: 0.7, destination: panner, type: 'sine', volume: 0.35});
				}

				setTimeout(() => {
					panner.disconnect();
				}, 1500);

				this.say(side === 'left' ? 'Testing the LEFT speaker: ding ding ding ding!' : 'Testing the RIGHT speaker: ding ding ding ding!');
				question.hidden = false;
			});
		}

		for (const button of this.querySelectorAll('[data-music-answer]')) {
			this.on(button, 'click', () => {
				if (button.dataset.musicAnswer === 'yes') {
					this.say('Great! Your sound card works. Now go and make some music!');
				} else {
					this.say(advice[this.#adviceIndex % advice.length]);
					this.#adviceIndex++;
				}
			});
		}

		this.on(stopAll, 'click', () => {
			stopEverything();
			this.say('All the music stopped. Ahh, silence.');
		});
	}
}
