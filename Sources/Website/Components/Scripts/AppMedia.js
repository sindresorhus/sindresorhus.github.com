// Read once, when the page loads, like on the rest of the site.
const prefersReducedMotion = matchMedia('(prefers-reduced-motion: reduce)').matches;

class AppMedia extends HTMLElement {
	// Stops the observer and the listeners when the element is removed, so connecting it again does not add them twice.
	#abortController;

	connectedCallback() {
		this.#abortController = new AbortController();
		this.#playVideosInView();
		this.#setUpButtons();
	}

	disconnectedCallback() {
		this.#abortController.abort();
	}

	// Demo videos play while they are visible, unless the visitor prefers reduced motion. A click, or Enter or Space, pauses and plays a video, so it can always be stopped (WCAG 2.2.2).
	#playVideosInView() {
		const {signal} = this.#abortController;
		const videos = this.querySelectorAll('video');

		// The videos that the visitor paused, which stay paused when they come back into view.
		const pausedByVisitor = new WeakSet();

		const toggle = video => {
			if (video.paused) {
				pausedByVisitor.delete(video);
				video.play().catch(() => {});
			} else {
				pausedByVisitor.add(video);
				video.pause();
			}
		};

		const observer = new IntersectionObserver(entries => {
			// By the ratio, as the observer also reports when a video starts to show, like the next item that peeks in on phones.
			for (const {target: video, intersectionRatio} of entries) {
				const isInView = intersectionRatio >= 0.5;

				if (isInView && !prefersReducedMotion && !pausedByVisitor.has(video)) {
					video.play().catch(() => {});
				} else if (!isInView) {
					video.pause();
				}
			}
		}, {threshold: 0.5});

		signal.addEventListener('abort', () => {
			observer.disconnect();
		});

		for (const video of videos) {
			observer.observe(video);
			video.addEventListener('click', () => toggle(video), {signal});
			video.addEventListener('keydown', event => {
				if (event.key === 'Enter' || event.key === ' ') {
					event.preventDefault();
					toggle(video);
				}
			}, {signal});
		}
	}

	// The buttons of the media carousel. A button is disabled at the end it points to, and the styles hide it.
	// TODO: Replace this with CSS carousels (`::scroll-button` and `::scroll-marker`) when Safari and Firefox support them.
	#setUpButtons() {
		const {signal} = this.#abortController;
		const carousel = this.querySelector('[data-part="scroller"]');
		const previousButton = this.querySelector('[data-part="previous"]');
		const nextButton = this.querySelector('[data-part="next"]');
		const dotList = this.querySelector('[data-part="dots"]');
		const dots = dotList ? [...dotList.children] : [];
		const items = [...carousel.children];

		if (items.length === 0) {
			return;
		}

		// Shows the first item, instead of the scroll position that the browser restores.
		carousel.scrollLeft = 0;

		let currentIndex = 0;

		const visibleIndex = () => {
			const center = carousel.getBoundingClientRect().left + (carousel.offsetWidth / 2);
			let closestIndex = 0;
			let closestDistance = Number.POSITIVE_INFINITY;

			for (const [index, item] of items.entries()) {
				const {left, width} = item.getBoundingClientRect();
				const distance = Math.abs(left + (width / 2) - center);

				if (distance < closestDistance) {
					closestDistance = distance;
					closestIndex = index;
				}
			}

			return closestIndex;
		};

		const updateButtons = () => {
			const focusedElement = document.activeElement;

			previousButton.disabled = currentIndex === 0;
			nextButton.disabled = currentIndex === items.length - 1;

			// A disabled button loses the focus, like “Next screenshot” at the last item, so the focus goes to the other button instead of the start of the page.
			if (focusedElement === previousButton && previousButton.disabled) {
				nextButton.focus();
			} else if (focusedElement === nextButton && nextButton.disabled) {
				previousButton.focus();
			}

			for (const [index, dot] of dots.entries()) {
				if (index === currentIndex) {
					dot.setAttribute('aria-current', 'true');
				} else {
					dot.removeAttribute('aria-current');
				}
			}
		};

		const scrollTo = index => {
			currentIndex = Math.max(0, Math.min(items.length - 1, index));
			items[currentIndex].scrollIntoView({behavior: prefersReducedMotion ? 'instant' : 'smooth', block: 'nearest', inline: 'center'});
			updateButtons();
		};

		previousButton.addEventListener('click', () => {
			scrollTo(currentIndex - 1);
		}, {signal});

		nextButton.addEventListener('click', () => {
			scrollTo(currentIndex + 1);
		}, {signal});

		for (const [index, dot] of dots.entries()) {
			dot.addEventListener('click', () => {
				scrollTo(index);
			}, {signal});
		}

		if (dotList) {
			dotList.hidden = false;
		}

		// Keeps the buttons right after the visitor swipes.
		carousel.addEventListener('scrollend', () => {
			currentIndex = visibleIndex();
			updateButtons();
		}, {signal});

		updateButtons();
	}
}

customElements.define('app-media', AppMedia);
