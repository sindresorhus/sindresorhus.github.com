import Elementary
import SiteKit

/**
Whether I am probably awake or asleep, from the time where I am, as a chip with an icon, like “Probably asleep · 04:12 my time”. It is a guess from my usual rhythm: asleep from 3 AM to 10 AM.

The time zone is UTC+7, without the name of a place. The script finds the time from the clock of the visitor, as the site is only built once a night, and changes the text each minute. It is invisible until the script sets the time of day, but it keeps its space, so the page does not move when it shows. Without JavaScript, it is not shown.
*/
struct AwakeStatus: ScriptedElement {
	static let script = ElementScript(inline: #"""
	export default class extends HTMLElement {
		#timer;

		connectedCallback() {
			clearTimeout(this.#timer);
			this.#update();
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
			const {state, icon, text} = JSON.parse(this.dataset.config).statuses.find(status => hour < status.beforeHour);

			this.dataset.state = state;
			const use = this.querySelector('use');
			use.setAttribute('href', use.getAttribute('href').replace(/#.*/, `#${icon}`));
			this.querySelector('[data-part="text"]').textContent = text;
			this.querySelector('[data-part="time"]').textContent = `${time} my time`;

			// At the start of the next minute, so the time is the same as on a clock.
			this.#timer = setTimeout(this.#update, 60_000 - (now.getSeconds() * 1000) - now.getMilliseconds());
		};
	}
	"""#)

	/**
	The four display outcomes, including the two that share the daytime color.
	*/
	struct Status: Encodable {
		let state: States
		let icon: Icon
		let text: String
		let beforeHour: Int
	}

	static let statuses = [
		Status(state: .late, icon: .moon, text: "Probably still coding", beforeHour: 3),
		Status(state: .asleep, icon: .zzz, text: "Probably asleep", beforeHour: 10),
		Status(state: .day, icon: .coffee, text: "Probably having coffee", beforeHour: 12),
		Status(state: .day, icon: .sun, text: "Probably building things", beforeHour: 24),
	]

	struct Config: Encodable {
		let statuses = AwakeStatus.statuses
	}

	let config: Config? = Config()

	var content: some HTML {
		// The script changes the icon and the text. Until then, the text is the longest text of the script, so the invisible chip already has its width, and it does not move to the next line when it shows.
		p {
			Icon.moon.size(.rootEm(1))
			FactLine {
				span(.part(Parts.text)) {
					Self.statuses.max(by: { $0.text.count < $1.text.count })?.text ?? ""
				}

				span(.part(Parts.time)) {
					"00:00 my time"
				}
			}
		}
		.style {
			$0
				.statusChip()
				.nested(Icon.selector) {
					$0.margin(.trailing, .rootEm(0.375))
				}
				.hiddenWithoutScripting()
		}
	}

	enum Parts: String, ElementPartSet {
		case text
		case time
	}

	enum States: String, ElementStateSet, Encodable {
		case late
		case asleep
		case day
	}

	enum Styles: ElementStyleSet {
		case root

		var style: Style {
			switch self {
			case .root:
				// The chip is laid out as if the element were not there. It is invisible until the script sets the time of day, and the chip inherits it. The icon has the color of the time of day, amber in the day.
				Style()
					.display(.contents)
					.visibility(false)
					.when(States.day) {
						$0
							.visibility(true)
							.nested(Icon.selector) {
								$0.color(.amber(600), dark: .amber(400))
							}
					}
					.when(States.late) {
						$0
							.visibility(true)
							.nested(Icon.selector) {
								$0.color(.violet(500))
							}
					}
					.when(States.asleep) {
						$0
							.visibility(true)
							.nested(Icon.selector) {
								$0.color(.indigo(500), dark: .indigo(200))
							}
					}
			}
		}
	}
}
