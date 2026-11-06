import Elementary
import Foundation
import SiteKit
import SOML

/**
The GitHub contributions of the last year as a grid of days, like on a GitHub profile, with one column for each week, and the names of the months above it. Screen readers skip the grid, so show the numbers as text next to it.

The career quilt uses the same cells (``Days``), colors (``Styles/level(_:)``), and scale (``ContributionScale``) for its calendars, so a day has the same color in both.

```swift
ContributionHeatmap(calendar: calendar, scale: content.contributionScale)
```
*/
struct ContributionHeatmap: HTML {
	let calendar: ContributionCalendar
	let scale: ContributionScale

	var body: some HTML<HTMLTag.div> {
		div {
			div {
				// Each week is a column: the name of its month, when the month starts in it, and its days.
				for (week, monthName) in zip(calendar.weeks, monthNames) {
					div {
						monthName ?? ""
					}
					.style(Styles.monthName)

					Days(days: week.days, scale: scale)
				}
			}
			.style(Styles.grid, Styles.cells)
		}
		.accessibilityHidden()
		// Not a Tab stop, which browsers make a scroller without controls on phones, as it is hidden from screen readers and starts at the newest week.
		.attributes(.tabindex(-1))
		.style(Styles.root)
	}

	/**
	The short name of the month of each week, like “Jan”, for the first week that starts in the month, and `nil` for the other weeks. A month with fewer than two weeks that start in it, which can only be the first or the last month of the year, has no name, as it would overlap the name of the next month or reach past the grid.
	*/
	private var monthNames: [String?] {
		let months = calendar.weeks.map { $0.days.first.map { $0.date.month } }

		return months.indices.map { index in
			guard
				index == 0 || months[index - 1] != months[index],
				index + 1 < months.count,
				months[index + 1] == months[index]
			else {
				return nil
			}

			return calendar.weeks[index].days.first?.date.foundationDate.formatted(.site.month(.abbreviated))
		}
	}

	/**
	A cell for each day, after a blank cell for each weekday before the first day, as the first week can start after Sunday, so each weekday is in its row. The parent is a grid of seven rows for the days that fills its columns first, and has the look of the cells (``Styles/cells``).
	*/
	struct Days: HTML {
		let days: [ContributionCalendar.Day]
		let scale: ContributionScale

		var body: some HTML {
			let plot = ContributionCalendar.Plot(days: days, scale: scale)

			for _ in 0..<plot.blankDayCount {
				span {}
			}

			for level in plot.levels {
				span {}
					.style(Styles.level(level))
			}
		}
	}

	enum Styles: String, StyleSet {
		case root
		case grid
		case monthName
		case cells
		case noContributions
		case firstQuartile
		case secondQuartile
		case thirdQuartile
		case fourthQuartile

		var style: Style {
			switch self {
			case .root:
				// On phones, the year is wider than the screen, so it scrolls sideways. Right to left, so it starts at the newest week, without a script. The grid inside is left to right again.
				Style()
					.overflow(horizontal: .auto)
					.scrollIndicators(.hidden)
					.direction(.rightToLeft)
					// The older weeks fade out at the left edge, so the cut week and month read as more to scroll to, not as a broken layout, as the scroll bar is hidden. The fade stays when the visitor scrolls to the oldest week, so the first few weeks of the year are faint then.
					.below(.tablet) {
						$0.maskImage(.linearGradient(.toRight, Color.transparent.at(.zero), Color.black.at(.rootEm(3))))
					}
			case .grid:
				// Cells that are large enough to see on phones, in a grid that is as wide as its cells. From tablets, the cells fill the width, so the whole year fits. The first row has the names of the months.
				Style()
					.display(.inlineGrid)
					.verticalAlign(.top)
					.direction(.leftToRight)
					.gridAutoFlow(.column)
					.gridRows(8, size: .auto)
					.gridAutoColumns(.fixed(.rootEm(0.625)))
					.gap(.pixels(2))
					.from(.tablet) {
						$0
							.display(.grid)
							.gridAutoColumns(.fraction(1))
							.gap(.pixels(3))
					}
			case .monthName:
				// Wider than its week, over the weeks after it, which have no name. Its box has no width, so the name does not make its column wider than the other weeks.
				Style()
					.frame(width: .zero)
					.secondaryText(.extraSmall)
					.textWrap(.nowrap)
			// The look of the cells, on their parent, so each day has only the class of its color, as the career quilt has thousands of days. The corners grow with the cell, like the larger cells of the career quilt.
			case .cells:
				Style()
					.children("span") {
						$0
							.aspectRatio(1)
							.cornerRadius(.percent(20))
							// Forced colors would remove the backgrounds, which are the contributions, so the cells have shades of the colors of forced colors instead (``level(_:)``).
							.forcedColorAdjust(.none)
					}
			case .noContributions:
				Style().levelBackground(.gray(200), dark: .gray(800), forcedColorsAmount: 15)
			case .firstQuartile:
				Style().levelBackground(.primary(300), dark: .primary(900), forcedColorsAmount: 35)
			case .secondQuartile:
				Style().levelBackground(.primary(500), dark: .primary(700), forcedColorsAmount: 55)
			case .thirdQuartile:
				Style().levelBackground(.primary(700), dark: .primary(500), forcedColorsAmount: 75)
			case .fourthQuartile:
				Style().levelBackground(.primary(900), dark: .primary(300), forcedColorsAmount: 100)
			}
		}

		static func level(_ level: ContributionScale.Level) -> Self {
			switch level {
			case .none:
				.noContributions
			case .first:
				.firstQuartile
			case .second:
				.secondQuartile
			case .third:
				.thirdQuartile
			case .fourth:
				.fourthQuartile
			}
		}
	}
}

extension Style {
	/**
	The background of a level of contributions, and in forced colors, the text color of forced colors mixed into their background color by an amount in percent, so the levels are steps from the background to the text.
	*/
	fileprivate func levelBackground(_ light: Color, dark: Color, forcedColorsAmount: Double) -> Self {
		background(light, dark: dark)
			.media(.forcedColors) {
				$0.background(Color.canvas.mix(with: .canvasText, amount: .percent(forcedColorsAmount)))
			}
	}
}
