// The GIF-O-Matic on the 1999 page: each GIF of the pile is a random GIF of the page, in a picture with its still frame, like the GIFs of the page, so visitors who prefer reduced motion see the still frame, and Stop and Reload of the browser stop and start it too. The size of each comes from the browser, when it knows it.
const maximumPile = 200;

const randomItem = items => items[Math.floor(Math.random() * items.length)];
const randomBetween = (minimum, maximum) => minimum + (Math.random() * (maximum - minimum));

// The still frame of a GIF of the page, which is in the source before its image, or `undefined` for a GIF that does not move.
const stillOf = image => {
	const source = image.previousElementSibling;
	return source?.matches('source[srcset]') ? source.getAttribute('srcset') : undefined;
};

const sizeOf = url => performance.getEntriesByName(new URL(url, location.href).href)[0]?.encodedBodySize || 8000;

const pileMilestone = count => {
	if (count >= maximumPile) {
		return 'The pile is full. Even I think that is enough.';
	}

	if (count >= 100) {
		return 'You win the Internet!';
	}

	if (count >= 50) {
		return 'WARNING: TOO MANY GIFs. Just kidding, there is no such thing.';
	}

	if (count >= 25) {
		return 'Your modem is starting to sweat.';
	}

	if (count >= 10) {
		return 'Now THAT is a home page!';
	}

	return '';
};

export default class extends GeoCitiesElement {
	connected() {
		const {pile, warning, template, more, moreTen, clean, earthquake} = this.parts;
		const panel = document.querySelector('#geocities-panel');
		const pileGIFs = [...new Map([...panel.querySelectorAll('picture > img[src$=".gif"]')].map(image => [image.getAttribute('src'), stillOf(image) ?? image.getAttribute('src')])).entries()];
		let pileCount = 0;
		let pileBytes = 0;
		let isShaking = false;
		let isStopped = false;

		// Stop of the browser shows the still frame of each GIF of the page, also of the pile, until Reload starts them again, so a new GIF of the pile starts stopped in between.
		this.on(document, 'geocities-gifs', event => {
			isStopped = event.detail.isStopped;
		});

		const addToPile = amount => {
			const before = pileCount;

			for (let index = 0; index < amount && pileCount < maximumPile; index++) {
				const [source, still] = randomItem(pileGIFs);
				const picture = template.content.firstElementChild.cloneNode(true);
				const image = picture.querySelector('img');

				// A GIF that does not move has no still frame.
				if (still === source) {
					picture.querySelector('source').remove();
				} else {
					picture.querySelector('source').srcset = still;
				}

				image.src = isStopped ? still : source;
				image.style.rotate = `${Math.round(randomBetween(-15, 15))}deg`;
				pile.append(picture);
				pileCount++;
				pileBytes += sizeOf(source);
			}

			// The newest GIFs land on top, so the pile shows its top when it is higher than the box.
			pile.scrollTo({top: -pile.scrollHeight});
			warning.hidden = pileCount < 50;

			// The win of Solitaire, once, when the pile reaches 100.
			if (before < 100 && pileCount >= 100) {
				this.celebrate();
				this.cheer();
			}

			// At 28.8k, which really did about 3 KB a second.
			const seconds = Math.round(pileBytes / 3000);
			const time = seconds < 120 ? `${seconds} ${seconds === 1 ? 'second' : 'seconds'}` : `${Math.round(seconds / 60)} minutes`;
			this.say(`${pileCount} ${pileCount === 1 ? 'GIF' : 'GIFs'} in the pile. My page is now ${Math.round(pileBytes / 1000).toLocaleString('en-US')} KB bigger, which takes ${time} longer to load at 28.8k. ${pileMilestone(pileCount)}`);
		};

		this.on(more, 'click', () => {
			addToPile(1);
		});

		this.on(moreTen, 'click', () => {
			addToPile(10);
		});

		this.on(clean, 'click', () => {
			pile.replaceChildren();
			pileCount = 0;
			pileBytes = 0;
			warning.hidden = true;
			this.say('All clean. My page looks so empty now.');
		});

		// The earthquake shakes the whole page for a moment and throws the GIFs of the pile around, with a magnitude that grows with the pile.
		this.on(earthquake, 'click', async () => {
			const magnitude = (4 + Math.min(pileCount / 20, 5.9) + Math.random() * 0.1).toFixed(1);

			if (this.reducedMotion) {
				this.say(`A ${magnitude} earthquake would shake the page now, but your computer prefers less motion.`);
				return;
			}

			if (isShaking) {
				return;
			}

			isShaking = true;
			this.say(`EARTHQUAKE! ${magnitude} on the Richter scale. ${pileCount > 0 ? 'The GIFs went everywhere!' : 'Luckily, the pile was empty.'}`);

			const shakes = Array.from({length: 12}, (_, index) => {
				const strength = 10 * (1 - (index / 12));
				return {translate: `${randomBetween(-strength, strength)}px ${randomBetween(-strength / 2, strength / 2)}px`};
			});
			const shake = panel.animate([{translate: '0 0'}, ...shakes, {translate: '0 0'}], {duration: 1200});

			for (const image of pile.querySelectorAll('img')) {
				image.animate([
					{transform: 'none'},
					{transform: `translate(${randomBetween(-60, 60)}px, ${randomBetween(-150, -20)}px) rotate(${randomBetween(-180, 180)}deg)`},
					{transform: 'none'},
				], {duration: randomBetween(700, 1200), easing: 'ease-in-out'});
			}

			await shake.finished;
			isShaking = false;
		});
	}
}
