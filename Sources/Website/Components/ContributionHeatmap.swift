import Elementary
import Foundation
import SiteKit

/**
The GitHub contributions of the last year as a grid of days, like on a GitHub profile, with one column for each week. Screen readers skip the grid, so show the numbers as text next to it.

The career quilt uses the same cells and colors (``Styles/cell`` and ``Styles/level(_:)``) for its calendars.

```swift
ContributionHeatmap(calendar: calendar)
```
*/
struct ContributionHeatmap: HTML {
	let calendar: ContributionCalendar

	var body: some HTML<HTMLTag.div> {
		div {
			div {
				// The first week can start after Sunday, so empty cells keep each weekday in its row.
				for _ in 0..<(7 - (calendar.weeks.first?.days.count ?? 7)) {
					span {}
						.style(Styles.cell)
				}

				for day in calendar.weeks.flatMap(\.days) {
					span {}
						.style(Styles.cell, Styles.level(day.level))
				}
			}
			.style(Styles.grid)
		}
		.accessibilityHidden()
		.style(Styles.root)
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
					.margin(vertical: .rootEm(1.5), horizontal: 0)
					.overflow(horizontal: .auto)
					.scrollIndicators(.hidden)
					.declaration(.direction, "rtl")
			case .grid:
				// Cells that are large enough to see on phones, in a grid that is as wide as its cells. From tablets, the cells fill the width, so the whole year fits.
				Style()
					.display(.inlineGrid)
					.verticalAlign(.top)
					.declaration(.direction, "ltr")
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
