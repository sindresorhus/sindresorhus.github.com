import Elementary
import Foundation
import SiteKit

/**
Whether I am probably awake or asleep, from the time where I am, as a chip with an icon, like “Probably asleep · 04:12 my time”. It is a guess from my usual rhythm: asleep from 3 AM to 10 AM.

The time zone is the offset from UTC of the newest public commit of the build (``GitHub/CommitTime``), as it moves with me, without the name of a place. Without the commits, it is UTC+7. The script finds the time from the clock of the visitor, as the site is only built once a night, and changes the text each minute. It is invisible until the script sets the time of day, but it keeps its space, so the page does not move when it shows. Without JavaScript, it is not shown.
*/
struct AwakeStatus: ScriptedElement {
	static let script = ElementScript()

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

		/**
		The offset from UTC where I am, in minutes, like 420 for UTC+7.
		*/
		let utcOffsetMinutes: Int
	}

	let config: Config?

	/**
	- Parameter utcOffsetMinutes: The offset from UTC of the newest public commit, in minutes. Without it, the time is UTC+7.
	*/
	init(utcOffsetMinutes: Int? = nil) {
		self.config = Config(utcOffsetMinutes: utcOffsetMinutes ?? 7 * 60)
	}

	var content: some HTML {
		// The script changes the icon and the text. Until then, the text is the longest text of the script, so the invisible chip already has its width, and it does not move to the next line when it shows.
		p {
			Icon.moon.size(.rootEm(1))
			FactLine {
				span(.part(Parts.text)) {
					Self.statuses.sorted(using: KeyPathComparator(\.text.count)).last?.text ?? ""
				}

				span(.part(Parts.time)) {
					"00:00 my time"
				}
			}
			// The time is on its own line where the longest text and the time do not fit on one line, like on a small phone or with large text, so the line does not end with a dot. The width is in rem, so it follows the text size.
			.style {
				$0.below(.phone) {
					$0.stackedFacts()
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

	enum Styles: String, ElementStyleSet {
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
