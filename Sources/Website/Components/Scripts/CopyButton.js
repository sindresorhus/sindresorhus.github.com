import {copy} from '/scripts/dom.js';

class CopyButton extends HTMLElement {
	// The pending timer that removes the copied state, so a second click restarts it.
	#copiedStateTimer;

	connectedCallback() {
		// Without clipboard access, the button stays hidden, as the visitor can still select the text.
		if (!navigator.clipboard) {
			return;
		}

		this.hidden = false;
		// The same function, so connecting the element again does not add a second listener.
		this.addEventListener('click', this.#copy);
	}

	#copy = async () => {
		// The button says “Copied”, as the element itself has no box.
		if (!await copy(this.getAttribute('text'), this.firstElementChild)) {
			return;
		}

		this.dataset.state = 'copied';

		clearTimeout(this.#copiedStateTimer);
		this.#copiedStateTimer = setTimeout(() => {
			delete this.dataset.state;
		}, 1500);
	};
}

customElements.define('copy-button', CopyButton);
