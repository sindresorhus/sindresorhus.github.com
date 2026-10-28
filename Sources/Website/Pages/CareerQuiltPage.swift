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

	/**
	The patches of the quilt, as a shared link is most often about them.
	*/
	var socialImage: SocialImage {
		.card(OpenGraphCard(page: self, artwork: .calendars(of: years.map(\.days), scale: years.contributionScale)))
	}

	var body: some HTML {
		// The scale of all the years, so a day has the same color in every year.
		let scale = years.contributionScale

		return section {
			PageHeader(title: "Career Quilt", intro: "\(years.totalCount.formatted(counting: "contribution")) on GitHub since \(ContributionYear.firstYear), one patch for each year.")

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

						// The summary says what the squares show. The squares are the ones of the contributions on the now page.
						div {
							ContributionHeatmap.Days(days: year.days, scale: scale)
						}
						.accessibilityHidden()
						.style(Styles.calendar, ContributionHeatmap.Styles.cells)
					}
					.style(Styles.patch)
				}
			}
			.vstack(spacing: .rootEm(1))

			// The contributions of a day for each color.
			div {
				"Contributions a day:"

				for level in ContributionScale.Level.allCases {
					if let countText = scale.countText(of: level) {
						span {
							span {}
								.style(ContributionHeatmap.Styles.level(level))

							countText
						}
						.style(Styles.legendItem, ContributionHeatmap.Styles.cells)
					}
				}
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
		case legendItem

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
					// Thin gaps on phones, where 53 weeks share a narrow card, so the squares are not much smaller than the gaps.
					.gap(.pixels(1))
					.from(.smallTablet) {
						$0.gap(.pixels(2))
					}
					.from(.tablet) {
						$0.gap(.pixels(3))
					}
			case .legend:
				Style()
					.hstack(alignment: .center, justification: .end, spacing: .rootEm(0.75))
					.flexWrap()
					.secondaryText(.extraSmall)
			// A color next to its count, so they stay on one line.
			case .legendItem:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.25))
					.children("span") {
						$0.frame(width: .rootEm(0.75))
					}
			}
		}
	}
}
