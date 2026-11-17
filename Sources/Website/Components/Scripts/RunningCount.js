// @ts-check
import {prefersReducedMotion} from '/scripts/dom.js';

/**
The configuration encoded by RunningCount.Config in Swift. ScriptTypeTests checks the encoded values against this type.
@typedef {Readonly<{perSecond: number, groupingThreshold: number, locale: string}>} RunningCountConfig
*/

class RunningCount extends HTMLElement {
	#frame = 0;
	/** @type {number | undefined} */
	#timeout;
	/** @type {IntersectionObserver | undefined} */
	#observer;

	connectedCallback() {
		// Swift supplies the required configuration attribute.
		const {perSecond, groupingThreshold, locale} = /** @type {RunningCountConfig} */ (JSON.parse(/** @type {string} */ (this.dataset.config)));
		const perMillisecond = perSecond / 1000;
		// With reduced motion, the count changes once a second instead of in every frame.
		const step = prefersReducedMotion ? 1000 : 1;
		// The time counts from the start of the navigation. A page that the speculation rules prerendered was opened later, at `activationStart`, which the entry only has from then on, while the element connects during the prerendering, so it is read in each update.
		// `activationStart` is not in the types of TypeScript yet.
		const navigation = /** @type {{activationStart?: number} | undefined} */ (performance.getEntriesByType('navigation')[0]);

		const update = () => {
			const time = Math.max(0, performance.now() - (navigation?.activationStart ?? 0));
			const elapsed = Math.floor(time / step) * step;
			// A thousands separator only from five digits, in the language of the site, like the other numbers of the site (`SiteNumberFormatStyle`). Only a new number is written, as frames that are close can have the same one.
			const number = Math.floor(elapsed * perMillisecond);
			const count = number < groupingThreshold ? String(number) : number.toLocaleString(locale);

			if (this.textContent !== count) {
				this.replaceChildren(count);
			}

			// With reduced motion, it waits for the next whole second, instead of waking up in every frame.
			if (step === 1) {
				this.#frame = requestAnimationFrame(update);
			} else {
				this.#timeout = setTimeout(update, step - (time % step));
			}
		};

		// It only counts while it is on screen, from a little before, so it never shows an old number. The count comes from the time, so it is right when it starts again. A hidden tab runs no frames, and runs the timer of reduced motion at most once a second, which it already is.
		/** @param {IntersectionObserverEntry[]} entries */
		const toggle = ([entry]) => {
			this.#stop();

			if (entry?.isIntersecting) {
				update();
			}
		};

		this.#observer?.disconnect();
		this.#observer = new IntersectionObserver(toggle, {rootMargin: '200px'});
		// The element has no box of its own (`display: contents`), so its parent is observed.
		this.#observer.observe(/** @type {HTMLElement} */ (this.parentElement));
	}

	disconnectedCallback() {
		this.#observer?.disconnect();
		this.#stop();
	}

	#stop() {
		cancelAnimationFrame(this.#frame);
		clearTimeout(this.#timeout);
	}
}

customElements.define('running-count', RunningCount);
