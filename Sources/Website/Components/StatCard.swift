import Elementary
import Foundation
import SiteKit

/**
A number with what it counts, like “59 pull requests merged”.
*/
struct Stat {
	let value: Value
	let label: String

	enum Value {
		/**
		A number or text that does not change, like “3467”, “22B+”, or “Fri”.

		The count says how many things the number is about, like 59 pull requests, the number of ratings of an average rating, or the contributions of the busiest weekday. A page can leave out the numbers with a count of zero.
		*/
		case text(String, count: Int)

		/**
		A count that starts at 0 when the page is opened and goes up by the rate each second (``RunningCount``).
		*/
		case running(perSecond: Double)

		/**
		Whether the number goes up while the visitor is on the page.
		*/
		var isRunning: Bool {
			if case .running = self {
				true
			} else {
				false
			}
		}
	}

	/**
	Whether the statistic has a positive count or a positive finite running rate. A tiny positive rate is meaningful even before its first whole count.
	*/
	var hasValue: Bool {
		switch value {
		case .text(_, let count):
			count > 0
		case .running(let perSecond):
			perSecond.isFinite && perSecond > 0
		}
	}

	/**
	- Parameters:
		- noun: What one of them is, like “pull request”. The label adds an “s” when the count is not 1.
		- pluralNoun: The plural of the noun, for a noun that does not add an “s”, like “repositories”.
		- suffix: The words after the noun, like “merged” or “a week”.
		- isApproximate: Whether the count is rounded down and abbreviated, like “22B+”, for counts that are too large to read in full.
	*/
	init(
		count: Int,
		noun: String,
		pluralNoun: String? = nil,
		suffix: String? = nil,
		isApproximate: Bool = false
	) {
		self.init(count: count, label: [noun.pluralized(for: count, plural: pluralNoun), suffix].compactMap(\.self).joined(separator: " "), isApproximate: isApproximate)
	}

	/**
	A count with its own label, like “5” and “of the 10 most-downloaded packages”.
	*/
	init(count: Int, label: String, isApproximate: Bool = false) {
		// No thousands separator, as the large numbers read better without it, like “3467”.
		self.init(count: count, value: isApproximate ? count.approximateCount : count.formatted(.siteNumber), label: label)
	}

	/**
	An average rating out of 5, like “4.7” and “average rating”.
	*/
	init(rating: StoreRating) {
		self.init(count: rating.count, value: rating.formattedAverage, label: "average rating")
	}

	/**
	The busiest day of contributions, like “383” and “busiest day, September 19”.
	*/
	init(busiestDay day: ContributionCalendar.Day, format: Date.FormatStyle) {
		self.init(count: day.count, label: "busiest day, \(day.date.foundationDate.formatted(format))")
	}

	/**
	A count that is shown as text, like “Fri” and “busiest weekday” for the contributions on Fridays.
	*/
	init(count: Int, value: String, label: String) {
		self.value = .text(value, count: count)
		self.label = label
	}

	/**
	A count that starts at 0 when the page is opened and goes up at the rate, like the npm downloads while the visitor has been on the page (``RunningCount``).
	*/
	init(perSecond: Double, label: String) {
		// A positive finite rate keeps even a slow count, without inventing an integer count.
		self.value = .running(perSecond: perSecond)
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
						switch stat.value {
						case .text(let text, _):
							text
						case .running(let perSecond):
							RunningCount(perSecond: perSecond)
						}
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
				.style(Styles.runningStat, when: stat.value.isRunning)
			}
		}
		.style(Styles.root)
	}

	enum Styles: String, StyleSet {
		case root
		case stat
		case runningStat
		case value
		case label

		/**
		Three numbers without a running count, which are in three columns on phones from 22rem.
		*/
		private static var threeShortStats: CSSSelector {
			"&:has(> :nth-child(3):last-child:not(\(runningStat.selector)))"
		}

		/**
		Below it, the numbers are in one column (352px at the default text size).
		*/
		private static let oneColumnBreakpoint = Breakpoint(minimumWidthInRem: 22)

		var style: Style {
			switch self {
			case .root:
				// Two columns on phones, and three from tablets, so the numbers of all the cards line up. Three numbers are in three columns on phones too, a little smaller, as the numbers are short, so none is alone in a row, unless the third is a running count, which gets long and has its own row.
				Style()
					.grid(columns: 2)
					.gap(row: .rootEm(1.25), column: .rootEm(1))
					.margin(.zero)
					.padding(.cardPadding)
					.cardSurface(isInteractive: false)
					.textStyle(.body)
					.below(.tablet) {
						$0.nested(Self.threeShortStats) {
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
					// One column where the numbers do not fit next to each other, like on a small phone or with a larger text size, as the numbers do not wrap. The width is in rem, so it follows the text size.
					.below(Self.oneColumnBreakpoint) {
						$0
							.gridColumns(1)
							.nested(Self.threeShortStats) {
								$0.gridColumns(1)
							}
					}
			case .stat:
				Style()
					.vstack(spacing: .rootEm(0.25))
					.frame(minWidth: .rootEm(4))
					.margin(.zero)
					.padding(.zero)
			case .runningStat:
				Style()
					.below(.tablet) {
						$0.gridColumnSpan(2)
					}
					.below(Self.oneColumnBreakpoint) {
						$0.gridColumnSpan(1)
					}
			case .value:
				Style()
					.fontFamily(.rounded)
					.font(.extraLarge4, weight: .bold)
					// On one line, so the “+” of a rounded number stays with it.
					.textWrap(.nowrap)
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
