// The Cool Text generator on the 1999 page: the word in the picked style, one box for each letter, so the letters can wave, shake, and have their own colors. The visitor can put the logo at the top of the page, as its title.

// By what the eye sees as one letter, so an emoji made of several characters, like a flag, stays whole.
const graphemes = new Intl.Segmenter('en');

export default class extends GeoCitiesElement {
	#typewriterTimers = new Map();
	#titleLetters;

	connected() {
		const {form, input, label, letters, title} = this.parts;
		this.#watchLetters(letters);

		const coolText = () => input.value.trim() || 'Sindre';
		const coolEffect = () => form.querySelector('input[type="radio"]:checked').value;

		const showCoolText = () => {
			label.textContent = coolText();
			this.#showLetters(letters, coolText(), coolEffect());
		};

		this.on(form, 'input', showCoolText);

		this.on(form, 'submit', event => {
			event.preventDefault();
			showCoolText();
		});

		showCoolText();

		// The logo goes to the top of the page as its title, until the page reloads. Screen readers read the word as the title.
		this.on(title, 'click', () => {
			const welcome = document.querySelector('#geocities-welcome');
			const titleLabel = label.cloneNode(true);
			titleLabel.removeAttribute('data-part');
			const isFirst = !this.#titleLetters;

			if (isFirst) {
				this.#titleLetters = document.createElement('span');
				this.#titleLetters.className = letters.className;
				this.#titleLetters.ariaHidden = 'true';
			}

			welcome.replaceChildren(titleLabel, this.#titleLetters);

			if (isFirst) {
				this.#watchLetters(this.#titleLetters);
			}

			this.#showLetters(this.#titleLetters, coolText(), coolEffect());
			this.say(`“${coolText()}” is now the title of my page! Scroll up to see it, or reload the page to get my title back.`);
		});
	}

	// The letters move only while they are in view, as the flames of fire repaint their shadows on each frame, which costs the whole page a layout on each frame, also far out of view.
	#watchLetters(container) {
		this.watchVisibility(container, isVisible => {
			container.toggleAttribute('data-cool-text-on-screen', isVisible);
		});
	}

	#showLetters(container, text, effect) {
		const characters = [...graphemes.segment(text)].map(({segment}) => segment);
		container.dataset.state = effect;
		container.replaceChildren(...characters.map((character, index) => {
			const letter = document.createElement('span');
			letter.textContent = character === ' ' ? ' ' : character;
			// The letters start their waves and shakes one after the other, and the rainbow goes across the word.
			letter.style.animationDelay = `${-index * 90}ms`;

			if (effect === 'rainbow') {
				letter.style.color = `hsl(${Math.round(index * 300 / Math.max(characters.length - 1, 1))} 100% 60%)`;
			}

			return letter;
		}));
		this.#typewrite(container);
	}

	// The typewriter types the letters one by one, again and again, while the word is in view. Without motion, it shows the whole word.
	#typewrite(container) {
		this.#typewriterTimers.get(container)?.cancel();

		const letters = [...container.children];
		if (this.reducedMotion || container.dataset.state !== 'typewriter') {
			for (const letter of letters) {
				letter.style.visibility = '';
			}

			return;
		}

		let count = 0;

		const type = () => {
			// With reduced motion, turned on while it types, it shows the whole word and stops.
			if (this.reducedMotion) {
				for (const letter of letters) {
					letter.style.visibility = '';
				}

				return;
			}

			// It waits while the word is out of view or the tab is hidden.
			if (!container.hasAttribute('data-cool-text-on-screen')) {
				this.#typewriterTimers.set(container, this.timeout(500, type));
				return;
			}

			for (const [index, letter] of letters.entries()) {
				letter.style.visibility = index < count ? '' : 'hidden';
			}

			count = count > letters.length ? 0 : count + 1;
			this.#typewriterTimers.set(container, this.timeout(count === 0 ? 1500 : 160, type));
		};

		type();
	}
}
