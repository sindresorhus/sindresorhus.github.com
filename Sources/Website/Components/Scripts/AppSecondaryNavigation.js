export default class extends HTMLElement {
	// Stops the observers and the listeners of the page when the element is removed, so connecting it again does not add them twice.
	#abortController;

	connectedCallback() {
		this.#abortController = new AbortController();
		this.#replaceSiteNavigation();
		this.#markCurrentSection();
	}

	disconnectedCallback() {
		this.#abortController.abort();
	}

	// An intersection observer that stops when the element is removed.
	#observer(callback, options) {
		const observer = new IntersectionObserver(callback, options);

		this.#abortController.signal.addEventListener('abort', () => {
			observer.disconnect();
		});

		return observer;
	}

	// The navigation of the app replaces the site navigation in the header when the app header has almost scrolled away. Scrolling starts the fade, and the transition in the styles then finishes it, also when the scrolling stops.
	#replaceSiteNavigation() {
		const hero = document.getElementById('app-hero');
		// The site header has the styles of both navigations.
		const header = this.closest('site-header');

		if (!hero || !header) {
			return;
		}

		const visibleRatio = 0.1;

		this.#observer(([entry]) => {
			// Only when the hero is above the view, not below it, like after opening a link to a section further down.
			const isScrolledAway = entry.intersectionRatio < visibleRatio && entry.boundingClientRect.top < 0;
			header.toggleAttribute('data-app-hero-scrolled-away', isScrolledAway);
		}, {threshold: [0, visibleRatio]}).observe(hero);
	}

	// Scroll spy: marks the link of the section that was last scrolled past the header, so the app navigation underlines it.
	// TODO: Replace this with CSS scroll spy (`scroll-target-group` and `:target-current`) when Safari and Firefox support it.
	#markCurrentSection() {
		const links = [...this.querySelectorAll('[data-part="sectionLink"]')];

		// The heading of the section that a link goes to.
		const headingOf = link => {
			try {
				return document.getElementById(decodeURIComponent(link.hash.slice(1)));
			} catch {
				return undefined;
			}
		};

		// In the order of the page, which `findLast` needs.
		const headings = [...new Set(links.map(link => headingOf(link)).filter(Boolean))].sort((first, second) => first.compareDocumentPosition(second) & Node.DOCUMENT_POSITION_FOLLOWING ? -1 : 1);

		if (links.length === 0 || headings.length === 0) {
			return;
		}

		// The area above the scroll padding is behind the header. A heading above a line a little below it has been scrolled past, which includes a heading that a section link scrolled to.
		const line = Number.parseFloat(getComputedStyle(document.documentElement).scrollPaddingTop) + 20;
		let isAtEnd = false;

		const update = () => {
			// At the end of the page, the last section may be too short to scroll past the header. The position is read here, not from the observer entries, as a jump, like with the Home key, can move a heading past the line without an entry for it.
			const activeHeading = isAtEnd ? headings.at(-1) : headings.findLast(heading => heading.getBoundingClientRect().top < line);

			for (const link of links) {
				if (activeHeading && headingOf(link) === activeHeading) {
					link.setAttribute('aria-current', 'location');
				} else {
					link.removeAttribute('aria-current');
				}
			}
		};

		// The observer only says when to update. The threshold of 1 also reports a heading when its top passes the line, not only when all of it has. A section link scrolls the heading to the scroll padding, where it can stop with its top above the line and its bottom below it.
		const headingObserver = this.#observer(update, {rootMargin: `-${line}px 0px 0px 0px`, threshold: [0, 1]});

		// A jump can move every heading without changing whether it is in the area, so there is no observer entry.
		addEventListener('scrollend', update, {signal: this.#abortController.signal});

		for (const heading of headings) {
			headingObserver.observe(heading);
		}

		const footer = document.getElementById('site-footer');

		if (footer) {
			this.#observer(([entry]) => {
				isAtEnd = entry.isIntersecting;
				update();
			}).observe(footer);
		}
	}
}
