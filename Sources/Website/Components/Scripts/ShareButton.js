import {share, sharedPage} from '/scripts/dom.js';

class ShareButton extends HTMLElement {
	connectedCallback() {
		// The same function, so connecting the element again does not add a second listener.
		this.addEventListener('click', this.#share);
	}

	#share = () => {
		this.closest('[popover]')?.hidePopover();
		share(sharedPage(this));
	};
}

customElements.define('share-button', ShareButton);
