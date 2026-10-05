// WaffleClues on the 1999 page, an extra of the adventure games: a hint book with invisible ink like the InvisiClues of Infocom. Rubbing a box with the pointer or a finger, or pressing it, makes the ink show in two steps.
export default class extends GeoCitiesElement {
	connected() {
		const steps = ['', 'faint', 'shown'];

		const develop = (box, amount = 1) => {
			const step = Math.min(steps.indexOf(box.dataset.state ?? '') + amount, steps.length - 1);
			box.dataset.state = steps[step];
			if (steps[step] === 'shown' && box.hasAttribute('aria-label')) {
				box.removeAttribute('aria-label');
				this.say(`The ink shows: ${box.textContent.trim()}`);
			}
		};

		for (const box of this.querySelectorAll('[data-part="ink"]')) {
			let rubbed = 0;
			let last;
			let wasRubbed = false;
			this.on(box, 'pointerdown', event => {
				last = {x: event.clientX, y: event.clientY};
				rubbed = 0;
				wasRubbed = false;
				box.setPointerCapture(event.pointerId);
			});

			// Rubbing back and forth develops the ink, one step for each stretch of rubbing.
			this.on(box, 'pointermove', event => {
				if (!last) {
					return;
				}

				rubbed += Math.hypot(event.clientX - last.x, event.clientY - last.y);
				last = {x: event.clientX, y: event.clientY};
				if (rubbed > 200) {
					rubbed = 0;
					wasRubbed = true;
					develop(box);
				}
			});

			const stop = () => {
				last = undefined;
			};

			this.on(box, 'pointerup', stop);
			this.on(box, 'pointercancel', stop);

			// A press without rubbing, or Enter and Space, develops one step. A click that ends a rub does not count again.
			this.on(box, 'click', event => {
				if (wasRubbed) {
					wasRubbed = false;
					return;
				}

				// Enter and Space show the whole hint at once, as there is nothing to rub with a keyboard, and a screen reader then reads it.
				develop(box, event.detail === 0 ? 2 : 1);
			});
		}
	}
}
