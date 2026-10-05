import Elementary
import Foundation
import SiteKit

/**
The GitHub contributions of every year since 2010, one calendar per year, like the patches of a quilt. Each calendar has a text summary, as the squares are only a picture.

The contributions need a GitHub token, so the build leaves the page out without one.
*/
struct CareerQuiltPage: Page {
	/**
	Oldest first.
	*/
	let years: [ContributionYear]

	var path: RoutePath {
		.careerQuilt
	}

	var metadata: PageMetadata {
		PageMetadata(title: "Career Quilt", description: "Every GitHub contribution of Sindre Sorhus since \(ContributionYear.firstYear), one calendar per year, like the patches of a quilt.")
	}

	var body: some HTML {
		section {
			PageHeader(title: "Career Quilt", intro: "\(years.totalCount.formatted(.number.locale(.site))) contributions on GitHub since \(ContributionYear.firstYear), one patch for each year.")

			ol {
				for year in years {
					li {
						h2(.id(String(year.year))) {
							String(year.year)
						}
						.style(Styles.year)

						p {
							year.summary
						}
						.style(Styles.summary)

						// The summary says what the squares show. The squares look like the ones of the contributions on the now page. Blank squares before the first day of the year keep each weekday in its row.
						div {
							for _ in 0..<year.firstWeekday {
								span {}
									.style(ContributionHeatmap.Styles.cell)
							}

							for day in year.days {
								span {}
									.style(ContributionHeatmap.Styles.cell, ContributionHeatmap.Styles.level(day.level))
							}
						}
						.accessibilityHidden()
						.style(Styles.calendar)
					}
					.style(Styles.patch)
				}
			}
			.vstack(spacing: .rootEm(1))

			div {
				"Less"

				for level in ContributionCalendar.Day.Level.allCases {
					span {}
						.style(ContributionHeatmap.Styles.cell, ContributionHeatmap.Styles.level(level))
				}

				"More"
			}
			.accessibilityHidden()
			.style(Styles.legend)
		}
		.style(Styles.root)
	}
}

extension CareerQuiltPage {
	enum Styles: StyleSet {
		case root
		case patch
		case year
		case summary
		case calendar
		case legend

		var style: Style {
			switch self {
			case .root:
				Style()
					.pageColumn(.wide)
			case .patch:
				// A dashed line inside the edge, like the stitches of a quilt patch.
				Style()
					.padding(.rootEm(1.25))
					.cardSurface(isInteractive: false)
					.outline(.lightDark(.gray(300), .gray(700)), offset: .pixels(-6), style: .dashed)
			case .year:
				Style()
					.font(.extraLarge, weight: .bold)
					.monospacedDigit()
					.color(.primaryText)
			case .summary:
				Style()
					.margin(bottom: .rootEm(0.75))
					.secondaryText()
			case .calendar:
				// Weeks are columns and weekdays are rows, like on GitHub. A year has up to 54 weeks, and a year that is not over keeps the width of a whole year.
				Style()
					.grid(columns: 53)
					.gridRows(7, size: .auto)
					.gridAutoFlow(.column)
					.gridAutoColumns(.fraction(1))
					.gap(.pixels(2))
					.from(.tablet) {
						$0.gap(.pixels(3))
					}
			case .legend:
				Style()
					.hstack(alignment: .center, justification: .end, spacing: .rootEm(0.25))
					.secondaryText(.extraSmall)
					.children("span") {
						$0.frame(width: .rootEm(0.75))
					}
			}
		}
	}
}
