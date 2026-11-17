// @ts-check
class InlineNote extends HTMLElement {
	// Whether the note was open when the pointer last went down on the link. The browser can close the note on the press, as the link is outside the note, so the click must not open it again.
	#wasOpen = false;

	connectedCallback() {
		// The same functions, so connecting the element again does not add second listeners.
		this.addEventListener('pointerdown', this.#rememberState);
		this.addEventListener('click', this.#toggle);
		this.#note.addEventListener('toggle', this.#updateExpanded);
	}

	// Swift renders the link as the only child.
	get #link() {
		return /** @type {HTMLAnchorElement} */ (this.firstElementChild);
	}

	// The note is at the end of the document, as it can have paragraphs, so the link names it, like `popovertarget` of a button.
	get #note() {
		return /** @type {HTMLElement} */ (document.getElementById(this.#link.hash.slice(1)));
	}

	#rememberState = () => {
		this.#wasOpen = this.#note.matches(':popover-open');
	};

	/** @param {MouseEvent} event */
	#toggle = event => {
		event.preventDefault();

		// A click from the keyboard has no pointer press (its `detail` is 0), so a press that did not end in a click, like a right-click, does not count. The note is closed here too, for browsers that do not close it on the press.
		if (event.detail > 0 && this.#wasOpen) {
			this.#note.hidePopover();
			return;
		}

		// The link is the source, so the note is placed next to it.
		this.#note.togglePopover({source: this.#link});
	};

	/** @param {ToggleEvent} event */
	#updateExpanded = event => {
		this.#link.ariaExpanded = String(event.newState === 'open');
	};
}

customElements.define('inline-note', InlineNote);
