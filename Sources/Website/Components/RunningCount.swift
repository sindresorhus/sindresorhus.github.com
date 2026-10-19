import Elementary
import SiteKit

/**
A count that starts at 0 when the page is opened and goes up at a rate in every frame, like the npm downloads while the visitor has been on the page. A ``StatCard`` shows it for a ``Stat`` with a rate.

Without JavaScript, it stays at 0.

It is not a CSS animation of an `@property` integer shown with `counter()`, as Safari 27 animates the integer as a decimal, which `counter()` does not accept, so it shows 0. CSS also cannot start the count when a prerendered page is opened.
*/
struct RunningCount: ScriptedElement {
	static let script = ElementScript(inline: #"""
	export default class extends HTMLElement {
		#frame;

		connectedCallback() {
			const perMillisecond = JSON.parse(this.dataset.config).perSecond / 1000;
			// With reduced motion, the count changes once a second instead of in every frame.
			const step = matchMedia('(prefers-reduced-motion: reduce)').matches ? 1000 : 1;
			// The time of a frame counts from the start of the navigation. A page that the speculation rules prerendered was opened later, at `activationStart`, which the entry only has from then on, while the element connects during the prerendering, so it is read in each frame.
			const navigation = performance.getEntriesByType('navigation')[0];

			const update = time => {
				const elapsed = Math.floor(Math.max(0, time - (navigation?.activationStart ?? 0)) / step) * step;
				// Without a thousands separator, like the other numbers of a stat card. Only a new number is written, as with reduced motion, most frames have the same one.
				const count = String(Math.floor(elapsed * perMillisecond));

				if (this.textContent !== count) {
					this.textContent = count;
				}

				this.#frame = requestAnimationFrame(update);
			};

			cancelAnimationFrame(this.#frame);
			this.#frame = requestAnimationFrame(update);
		}

		disconnectedCallback() {
			cancelAnimationFrame(this.#frame);
		}
	}
	"""#)

	let perSecond: Double

	var config: Config {
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
