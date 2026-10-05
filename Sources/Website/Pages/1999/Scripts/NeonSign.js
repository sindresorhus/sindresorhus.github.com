// The neon sign on the 1999 page: now and then a letter flickers off and on, like an old tube, while the sign is in view. The kicks do something else each time, in a shuffled order.
const randomItem = items => items[Math.floor(Math.random() * items.length)];
const randomBetween = (minimum, maximum) => minimum + (Math.random() * (maximum - minimum));

export default class extends GeoCitiesElement {
	connected() {
		const {sign, kick: kickButton} = this.parts;
		const signLetters = [...sign.querySelectorAll('[aria-hidden] > span')].filter(letter => /\p{L}/u.test(letter.textContent));
		// The d of “Sindre’s” has a bad tube, so it flickers more than the others.
		const weakLetter = signLetters[3];
		let isSignVisible = false;
		let quietUntil = 0;
		let isSputtering = false;
		let fallenLetter;
		let kicks = 0;
		let kickOutcomes = [];
		let lastKickOutcome;

		const flickerLetter = async letter => {
			letter.dataset.state = 'off';
			await this.wait(randomBetween(50, 120));

			if (letter !== fallenLetter) {
				delete letter.dataset.state;
			}
		};

		// Whether a flicker is waiting or running, so there is only one chain of them.
		let isFlickering = false;

		// The next flicker, only while the sign is in view. The chain stops when it leaves the view, and starts again when it comes back.
		const scheduleFlicker = () => {
			isFlickering = isSignVisible;

			if (isFlickering) {
				this.timeout(randomBetween(900, 3000), flicker);
			}
		};

		const flicker = async () => {
			if (!this.reducedMotion && !isSputtering && Date.now() > quietUntil) {
				const letter = Math.random() < 0.5 ? weakLetter : randomItem(signLetters);

				if (letter !== fallenLetter) {
					await flickerLetter(letter);

					// Sometimes it flickers twice, but never fast enough to flash.
					if (Math.random() < 0.4) {
						await this.wait(250);
						await flickerLetter(letter);
					}
				}
			}

			scheduleFlicker();
		};

		this.watchVisibility(sign, isVisible => {
			isSignVisible = isVisible;

			if (isVisible && !isFlickering) {
				scheduleFlicker();
			}
		});

		// All the letters go dark, and come back on one by one, unless the visitor prefers reduced motion. Kicks wait until it is done, and the status says why.
		const sputter = async () => {
			isSputtering = true;
			this.say('Bzzzzt…');

			for (const letter of signLetters) {
				letter.dataset.state = 'off';
			}

			await this.wait(500);

			for (const letter of signLetters) {
				if (!this.reducedMotion) {
					await this.wait(60);
				}

				if (letter !== fallenLetter) {
					delete letter.dataset.state;
				}
			}

			isSputtering = false;
		};

		const kickResults = {
			async fixed() {
				quietUntil = Date.now() + 15_000;
				await sputter();
				return 'The sign is fixed! For now.';
			},
			async fallen() {
				fallenLetter = randomItem(signLetters);
				fallenLetter.dataset.state = 'fallen';
				return `Oops! The “${fallenLetter.textContent}” fell off.`;
			},
			async crooked() {
				sign.dataset.state = 'crooked';
				return 'Now the sign hangs crooked. Maybe kick it again?';
			},
			async dark() {
				await sputter();
				return 'The sign went dark… and buzzed back on. Phew!';
			},
			async foot() {
				return 'Ouch! My foot. The sign did not even notice.';
			},
		};

		this.on(kickButton, 'click', async () => {
			if (isSputtering) {
				return;
			}

			kicks++;
			const repairs = [];

			// The sign jolts from the kick, unless the visitor prefers reduced motion. It moves by `translate`, so a crooked sign stays crooked.
			if (!this.reducedMotion) {
				sign.animate([{translate: '0 0'}, {translate: '0.5rem -0.375rem'}, {translate: '-0.375rem 0.125rem'}, {translate: '0.125rem 0'}, {translate: '0 0'}], {duration: 350, easing: 'ease-out'});
			}

			// A kick puts back what the last kick broke.
			if (fallenLetter) {
				delete fallenLetter.dataset.state;
				repairs.push(`The “${fallenLetter.textContent}” is back.`);
				fallenLetter = undefined;
			}

			if (sign.dataset.state === 'crooked') {
				delete sign.dataset.state;
				repairs.push('The sign is straight again.');
			}

			if (kickOutcomes.length === 0) {
				kickOutcomes = Object.keys(kickResults).toSorted(() => Math.random() - 0.5);

				// A new round does not start with how the last round ended, so a kick never does the same as the one before.
				if (kickOutcomes.at(-1) === lastKickOutcome) {
					kickOutcomes.reverse();
				}
			}

			lastKickOutcome = kickOutcomes.pop();
			const outcome = await kickResults[lastKickOutcome]();
			this.say(`${[...repairs, outcome].join(' ')} (Kicks: ${kicks})`);
		});
	}
}
