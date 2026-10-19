import Elementary
import Foundation
import SiteKit

/**
The GitHub contributions of the last year as a grid of days, like on a GitHub profile, with one column for each week. Screen readers skip the grid, so show the numbers as text next to it.

The career quilt uses the same cells (``Days``) and colors (``Styles/level(_:)``) for its calendars.

```swift
ContributionHeatmap(calendar: calendar)
```
*/
struct ContributionHeatmap: HTML {
	let calendar: ContributionCalendar

	var body: some HTML<HTMLTag.div> {
		div {
			div {
				Days(days: calendar.days)
			}
			.style(Styles.grid)
		}
		.accessibilityHidden()
		// Not a Tab stop, which browsers make a scroller without controls on phones, as it is hidden from screen readers and starts at the newest week.
		.attributes(.tabindex(-1))
		.style(Styles.root)
	}

	/**
	A cell for each day, after a blank cell for each weekday before the first day, as the first week can start after Sunday, so each weekday is in its row. The parent is a grid of seven rows that fills its columns first.
	*/
	struct Days: HTML {
		let days: [ContributionCalendar.Day]

		var body: some HTML {
			for _ in 0..<(days.first?.weekday ?? 0) {
				span {}
					.style(Styles.cell)
			}

			for day in days {
				span {}
					.style(Styles.cell, Styles.level(day.level))
			}
		}
	}

	enum Styles: StyleSet {
		case root
		case grid
		case cell
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
			case .grid:
				// Cells that are large enough to see on phones, in a grid that is as wide as its cells. From tablets, the cells fill the width, so the whole year fits.
				Style()
					.display(.inlineGrid)
					.verticalAlign(.top)
					.direction(.leftToRight)
					.gridAutoFlow(.column)
					.gridRows(7, size: .auto)
					.gridAutoColumns(.fixed(.rootEm(0.625)))
					.gap(.pixels(2))
					.from(.tablet) {
						$0
							.display(.grid)
							.gridAutoColumns(.fraction(1))
							.gap(.pixels(3))
					}
			// The corners grow with the cell, like the larger cells of the career quilt.
			case .cell:
				Style()
					.aspectRatio(1)
					.cornerRadius(.percent(20))
			case .noContributions:
				Style().background(.gray(200), dark: .gray(800))
			case .firstQuartile:
				Style().background(.primary(300), dark: .primary(900))
			case .secondQuartile:
				Style().background(.primary(500), dark: .primary(700))
			case .thirdQuartile:
				Style().background(.primary(700), dark: .primary(500))
			case .fourthQuartile:
				Style().background(.primary(900), dark: .primary(300))
			}
		}

		static func level(_ level: ContributionCalendar.Day.Level) -> Self {
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
