import {elementForFragment, share, sharedPage} from '/scripts/dom.js';

class OverflowMenu extends HTMLElement {
	connectedCallback() {
		// The “Share…” option is hidden until the browser can share. Some browsers, like Firefox on desktop, cannot.
		const shareOption = this.querySelector('[data-part="share"]');

		if (shareOption && navigator.canShare?.(sharedPage(this))) {
			shareOption.hidden = false;
			shareOption.disabled = false;
		}

		// The same function, so connecting the element again does not add a second listener.
		this.addEventListener('change', this.#choose);
	}

	// Choosing an option opens its link, or shows its explicitly marked popover, like the QR code of an app.
	#choose = async event => {
		const menu = event.target;
		const destination = menu.value;

		if (!destination) {
			return;
		}

		const option = menu.selectedOptions[0];
		const isShare = option.dataset.part === 'share';
		const isPopover = option.hasAttribute('data-menu-popover');
		menu.value = '';

		if (isShare) {
			// Focused, as Safari may place the share sheet at the focused element instead of at the pointer.
			menu.focus();

			// Safari on the Mac does not count a choice in a `<select>` menu as an action of the visitor, so it refuses to share from the menu. Then the share popover that the option points to shows instead, as its buttons count.
			if (await share(sharedPage(this))) {
				return;
			}
		}

		const popover = isPopover ? elementForFragment(destination) : undefined;

		if (popover?.popover) {
			// The menu is the source, so focus goes back to it when the popover closes.
			popover.showPopover({source: menu});
			popover.focus();
		} else {
			location.href = destination;
		}
	};
}

customElements.define('overflow-menu', OverflowMenu);
