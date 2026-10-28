import Elementary
import SiteKit

/**
A count that starts at 0 when the page is opened and goes up at a rate in every frame while it is on screen, like the npm downloads while the visitor has been on the page. A ``StatCard`` shows it for a ``Stat`` with a rate.

Without JavaScript, it stays at 0.

It is not a CSS animation of an `@property` integer shown with `counter()`, as Safari 27 animates the integer as a decimal, which `counter()` does not accept, so it shows 0. CSS also cannot start the count when a prerendered page is opened.
*/
struct RunningCount: ScriptedElement {
	static let script = ElementScript(inline: #"""
	export default class extends HTMLElement {
		#frame;
		#timeout;
		#observer;

		connectedCallback() {
			const perMillisecond = JSON.parse(this.dataset.config).perSecond / 1000;
			// With reduced motion, the count changes once a second instead of in every frame.
			const step = matchMedia('(prefers-reduced-motion: reduce)').matches ? 1000 : 1;
			// The time counts from the start of the navigation. A page that the speculation rules prerendered was opened later, at `activationStart`, which the entry only has from then on, while the element connects during the prerendering, so it is read in each update.
			const navigation = performance.getEntriesByType('navigation')[0];

			const update = () => {
				const time = Math.max(0, performance.now() - (navigation?.activationStart ?? 0));
				const elapsed = Math.floor(time / step) * step;
				// Without a thousands separator, like the other numbers of a stat card. Only a new number is written, as frames that are close can have the same one.
				const count = String(Math.floor(elapsed * perMillisecond));

				if (this.textContent !== count) {
					this.textContent = count;
				}

				// With reduced motion, it waits for the next whole second, instead of waking up in every frame.
				if (step === 1) {
					this.#frame = requestAnimationFrame(update);
				} else {
					this.#timeout = setTimeout(update, step - (time % step));
				}
			};

			// It only counts while it is on screen, from a little before, so it never shows an old number. The count comes from the time, so it is right when it starts again. A hidden tab runs no frames, and runs the timer of reduced motion at most once a second, which it already is.
			const toggle = ([entry]) => {
				this.#stop();

				if (entry.isIntersecting) {
					update();
				}
			};

			this.#observer?.disconnect();
			this.#observer = new IntersectionObserver(toggle, {rootMargin: '200px'});
			// The element has no box of its own (`display: contents`), so its parent is observed.
			this.#observer.observe(this.parentElement);
		}

		disconnectedCallback() {
			this.#observer.disconnect();
			this.#stop();
		}

		#stop() {
			cancelAnimationFrame(this.#frame);
			clearTimeout(this.#timeout);
		}
	}
	"""#)

	let perSecond: Double

	var config: Config? {
		Config(perSecond: perSecond)
	}

	var content: some HTML {
		"0"
	}

	struct Config: Encodable {
		let perSecond: Double
	}

	enum Styles: ElementStyleSet {
		case root

		var style: Style {
			switch self {
			case .root:
				// The text is laid out as if the element were not there, like the other numbers.
				Style().display(.contents)
			}
		}
	}
}
