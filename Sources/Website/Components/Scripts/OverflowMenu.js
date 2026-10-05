export default class extends HTMLElement {
	connectedCallback() {
		// The “Share…” option is hidden until the browser can share. Some browsers, like Firefox on desktop, cannot.
		const shareOption = this.querySelector('[data-part="share"]');

		if (shareOption && navigator.canShare?.(this.#sharedPage)) {
			shareOption.hidden = false;
			shareOption.disabled = false;
		}

		// The same function, so connecting the element again does not add a second listener.
		this.addEventListener('change', this.#choose);
	}

	get #sharedPage() {
		return {title: this.getAttribute('share-title'), url: this.getAttribute('share-url')};
	}

	// Choosing an option opens its link, or shows the popover that an `#id` option points to, like the QR code of an app.
	#choose = async event => {
		const menu = event.target;
		const destination = menu.value;

		if (!destination) {
			return;
		}

		const isShare = menu.selectedOptions[0].dataset.part === 'share';
		menu.value = '';

		if (isShare) {
			// Focused, as Safari may place the share sheet at the focused element instead of at the pointer.
			menu.focus();

			try {
				await navigator.share(this.#sharedPage);
				return;
			} catch (error) {
				// Safari on the Mac does not count a choice in a `<select>` menu as an action of the visitor, so it refuses to share from the menu. Then the share popover that the option points to shows instead, as its buttons count.
				if (error.name !== 'NotAllowedError') {
					if (error.name !== 'AbortError') {
						console.error('Share failed:', error.message);
					}

					return;
				}
			}
		}

		const popover = destination.startsWith('#') ? document.getElementById(destination.slice(1)) : undefined;

		if (popover?.popover) {
			// The menu is the source, so focus goes back to it when the popover closes.
			popover.showPopover({source: menu});
			popover.focus();
		} else {
			location.href = destination;
		}
	};
}
