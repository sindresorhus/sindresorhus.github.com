import {partList, parts} from '/scripts/dom.js';

/**
The configuration encoded by SiteHeader.Config in Swift. ScriptTypeTests checks the encoded values against this type.
@typedef {Readonly<{tabletQuery: string}>} SiteHeaderConfig
*/

class SiteHeader extends HTMLElement {
	connectedCallback() {
		const {menu} = parts(this);
		// The same functions, so connecting the element again does not add second listeners.
		menu.addEventListener('focusout', this.#closeMenu);
		menu.addEventListener('click', this.#closeForSection);
		menu.addEventListener('beforetoggle', this.#markCurrentSection);

		// From tablets, the menu is a row in the header, but a menu that is still open stays a layer on the page that takes every tap. So it closes when the window becomes wide, like when a phone rotates.
		const {tabletQuery} = /** @type {SiteHeaderConfig} */ (JSON.parse(this.dataset.config));
		matchMedia(tabletQuery).addEventListener('change', () => {
			if (menu.matches(':popover-open')) {
				menu.hidePopover();
			}
		});
	}

	// The scroll spy of the navigation of the app sets the section that the visitor is in on the header, so the menu marks it among the sections of the app when it opens.
	#markCurrentSection = event => {
		if (event.newState !== 'open') {
			return;
		}

		for (const link of partList(this, 'appSectionLink')) {
			link.ariaCurrent = link.hash === this.dataset.currentSection ? 'location' : null;
		}
	};

	// A link to a section of the page, like the FAQ of an app, scrolls the page behind the menu, so the menu closes to show the section.
	#closeForSection = event => {
		const menu = event.currentTarget;

		if (event.target.closest('a[href^="#"]') && menu.matches(':popover-open')) {
			menu.hidePopover();
		}
	};

	// The mobile menu covers the page, so it closes when keyboard focus moves out of it, like to a link behind it. Not when it moves to the menu button, which closes it itself.
	#closeMenu = event => {
		const menu = event.currentTarget;
		const destination = event.relatedTarget;
		const isLeaving = destination && !menu.contains(destination) && destination.popoverTargetElement !== menu;

		if (isLeaving && menu.matches(':popover-open')) {
			menu.hidePopover();
		}
	};
}

customElements.define('site-header', SiteHeader);
