import Elementary
import Foundation
import SiteKit

/**
A number with what it counts, like “59 pull requests merged”.
*/
struct Stat {
	/**
	How many things the number is about, like 59 pull requests, the number of ratings of an average rating, or the contributions of the busiest weekday. A page can leave out the numbers with a count of zero.
	*/
	let count: Int

	let value: String
	let label: String

	/**
	- Parameters:
		- noun: What one of them is, like “pull request”. The label adds an “s” when the count is not 1.
		- pluralNoun: The plural of the noun, for a noun that does not add an “s”, like “repositories”.
		- suffix: The words after the noun, like “merged” or “a week”.
		- isApproximate: Whether the count is rounded down and abbreviated, like “22B+”, for counts that are too large to read in full.
	*/
	init(count: Int, noun: String, pluralNoun: String? = nil, suffix: String? = nil, isApproximate: Bool = false) {
		self.init(count: count, label: [count == 1 ? noun : pluralNoun ?? noun + "s", suffix].compactMap(\.self).joined(separator: " "), isApproximate: isApproximate)
	}

	/**
	A count with its own label, like “5” and “of the 10 most-downloaded packages”.
	*/
	init(count: Int, label: String, isApproximate: Bool = false) {
		// No thousands separator, as the large numbers read better without it, like “3467”.
		self.init(count: count, value: isApproximate ? count.approximateCount : count.formatted(.number.grouping(.never).locale(.site)), label: label)
	}

	/**
	An average rating out of 5, like “4.7” and “average rating”.
	*/
	init(rating: AppStoreInfo.Rating) {
		self.init(count: rating.count, value: rating.average.formatted(.number.locale(.site).precision(.fractionLength(1))), label: "average rating")
	}

	/**
	The busiest day of contributions, like “383” and “busiest day, September 19”. `nil` when the date cannot be read.
	*/
	init?(busiestDay day: ContributionCalendar.Day, format: Date.FormatStyle) {
		guard let date = day.startOfDay else {
			return nil
		}

		self.init(count: day.count, label: "busiest day, \(date.formatted(format))")
	}

	/**
	A count that is shown as text, like “Fri” and “busiest weekday” for the contributions on Fridays.
	*/
	init(count: Int, value: String, label: String) {
		self.count = count
		self.value = value
		self.label = label
	}
}

/**
Numbers that stand out in a card, each with a label below it, like “59” and “pull requests merged”.
*/
struct StatCard: HTML {
	let stats: [Stat]

	var body: some HTML<HTMLTag.ul> {
		ul {
			for stat in stats {
				li {
					span {
						stat.value
					}
					.style(Styles.value)

					// A space between the number and the label, for copied text and screen readers. The stack does not show it.
					" "

					span {
						stat.label
					}
					.style(Styles.label)
				}
				.style(Styles.stat)
			}
		}
		.style(Styles.root)
	}

	enum Styles: StyleSet {
		case root
		case stat
		case value
		case label

		var style: Style {
			switch self {
			case .root:
				// Two columns on phones, and three from tablets, so the numbers of all the cards line up. Three numbers are in three columns on phones too, a little smaller, as the numbers are short, so none is alone in a row.
				Style()
					.display(.grid)
					.gridColumns(2)
					.gap(row: .rootEm(1.25), column: .rootEm(1))
					.margin(0)
					.padding(.rootEm(1.25))
					.cardSurface(isInteractive: false)
					.textStyle(.body)
					.below(.tablet) {
						$0.nested("&:has(> :nth-child(3):last-child)") {
							$0
								.gridColumns(3)
								.nested(Self.value.selector) {
									$0.font(size: .rootEm(1.875))
								}
						}
					}
					.from(.tablet) {
						$0.gridColumns(3)
					}
			case .stat:
				Style()
					.vstack(spacing: .rootEm(0.25))
					.frame(minWidth: .rootEm(4))
					.margin(0)
					.padding(0)
			case .value:
				Style()
					.fontFamily(.rounded)
					.font(size: .rootEm(2.25), lineHeight: 1.1)
					// On one line, so the “+” of a rounded number stays with it.
					.textWrap(.nowrap)
					.bold()
					.letterSpacing(.em(-0.02))
					.monospacedDigit()
					.color(.primaryText)
			case .label:
				Style()
					.secondaryText()
			}
		}
	}
}
