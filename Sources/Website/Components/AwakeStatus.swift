import Elementary
import SiteKit

/**
Whether I am probably awake or asleep, from the time where I am, as a chip with an icon, like “Probably asleep · 04:12 my time”. It is a guess from my usual rhythm: asleep from 3 AM to 10 AM.

The time zone is UTC+7, without the name of a place. The script finds the time from the clock of the visitor, as the site is only built once a night, and changes the text each minute. It is hidden until the script shows it, so it is not shown without JavaScript.
*/
struct AwakeStatus: ScriptedElement {
	static let script = ElementScript(inline: #"""
	export default class extends HTMLElement {
		#timer;

		connectedCallback() {
			clearTimeout(this.#timer);
			this.#update();
			this.firstElementChild.hidden = false;
		}

		disconnectedCallback() {
			clearTimeout(this.#timer);
		}

		#update = () => {
			// UTC+7. The sign of the `Etc` zones is the other way around.
			const timeZone = 'Etc/GMT-7';
			const now = new Date();
			// In the 24-hour format, like “04:12”.
			const time = now.toLocaleString('en-US', {timeZone, hour: '2-digit', minute: '2-digit', hourCycle: 'h23'});
			const hour = Number.parseInt(time, 10);

			// The state, the icon in the sprite, and the text.
			let status;

			if (hour < 3) {
				status = ['late', 'moon', 'Probably still coding'];
			} else if (hour < 10) {
				status = ['asleep', 'zzz', 'Probably asleep'];
			} else if (hour < 12) {
				status = ['day', 'coffee', 'Probably having coffee'];
			} else {
				status = ['day', 'sun', 'Probably building things'];
			}

			const [state, icon, text] = status;
			this.dataset.state = state;
			const use = this.querySelector('use');
			use.setAttribute('href', use.getAttribute('href').replace(/#.*/, `#${icon}`));
			this.querySelector('span').textContent = `${text} · ${time} my time`;

			// At the start of the next minute, so the time is the same as on a clock.
			this.#timer = setTimeout(this.#update, 60_000 - (now.getSeconds() * 1000) - now.getMilliseconds());
		};
	}
	"""#)

	var content: some HTML {
		// The script changes the icon and the text.
		p(.hidden) {
			Icon.moon.size(.rootEm(1))
			span {}
		}
		.style {
			$0
				.statusChip()
				.nested(Icon.selector) {
					$0.margin(.trailing, .rootEm(0.375))
				}
		}
	}

	enum States: String, ElementStateSet {
		case late
		case asleep
		case day
	}

	enum Styles: ElementStyleSet {
		case root

		var style: Style {
			switch self {
			case .root:
				// The chip is laid out as if the element were not there. The icon has the color of the time of day, amber in the day.
				Style()
					.display(.contents)
					.when(States.day) {
						$0.nested(Icon.selector) {
							$0.color(.amber(600), dark: .amber(400))
						}
					}
					.when(States.late) {
						$0.nested(Icon.selector) {
							$0.color(.violet(500))
						}
					}
					.when(States.asleep) {
						$0.nested(Icon.selector) {
							$0.color(.indigo(500), dark: .indigo(200))
						}
					}
			}
		}
	}
}
