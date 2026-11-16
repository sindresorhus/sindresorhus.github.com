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

			YearBars(years: years)

			// The contributions of a day for each color, below the introduction, so the colors are clear before the first patch.
			div {
				// The label is a line of its own, so the five colors stay on one line.
				span {
					"Contributions a day:"
				}
				.style {
					$0.frame(width: .percent(100))
				}

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
		}
		.style(Styles.root)
	}
}

extension CareerQuiltPage {
	enum Styles: String, StyleSet {
		case root
		case patch
		case year
		case summary
		case calendar
		case legend
		case legendItem
		case yearItem
		case yearLink
		case yearBar

		var style: Style {
			switch self {
			case .root:
				Style()
					.pageColumn(.page)
			case .patch:
				// A dashed line inside the edge, like the stitches of a quilt patch.
				Style()
					.padding(.rootEm(1.25))
					.cardSurface(isInteractive: false)
					.outline(.lightDark(.gray(300), .gray(700)), offset: .pixels(-6), style: .dashed)
			case .year:
				// A link to a year, like a bar of ``YearBars``, shows the top of its patch below the header.
				Style()
					.font(.extraLarge, weight: .bold)
					.monospacedDigit()
					.color(.primaryText)
					.scrollMargin(top: .rootEm(1.5))
			case .summary:
				Style()
					.margin(bottom: .rootEm(0.75))
					.secondaryText()
					// Balanced, so the date of the busiest day stays on one line, and the two lines have about the same length.
					.textWrap(.balance)
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
					.hstack(alignment: .center, spacing: .rootEm(0.75))
					.flexWrap()
					.secondaryText(.extraSmall)
			// A color next to its count, so they stay on one line.
			case .legendItem:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.25))
					.children("span") {
						$0.frame(width: .rootEm(0.75))
					}
			// A grid, so the link fills the column, and the whole column is a target.
			case .yearItem:
				Style()
					.display(.grid)
			// The bar on top of its year, at the bottom of the column. The fill of the column shows the pointer and the focus of the keyboard. On phones, the text is smaller, so the 17 years fit next to each other.
			case .yearLink:
				Style()
					.vstack(justification: .end, spacing: .rootEm(0.375))
					.padding(vertical: .rootEm(0.25), horizontal: .zero)
					.cornerRadius(.smallRadius)
					.secondaryText(.extraSmall)
					.below(.smallTablet) {
						$0
							.font(size: .rootEm(0.625))
							.letterSpacing(.em(-0.02))
					}
					.textAlign(.center)
					.monospacedDigit()
					.noUnderline()
					.hoverFill(.card, color: .primaryText)
			// A year with few contributions, like 2010, still has a line.
			case .yearBar:
				Style()
					.display(.block)
					.frame(minHeight: .pixels(2))
					.cornerRadius(.pixels(3))
			}
		}
	}
}

/**
The total of each year as a bar that links to its patch, so the shape of the career is clear before the patches, and a visitor can go to a year. The bars have the darkest color of the quilt. Screen readers read each link as the year and its total, like “2015: 6308 contributions”.

It is its own component, not a part of the body of ``CareerQuiltPage``, so the type of the page does not get deeper, like `CommitHours` of the now page.
*/
private struct YearBars: HTML {
	/**
	Oldest first.
	*/
	let years: [ContributionYear]

	/**
	The height of the bar of the year with the most contributions.
	*/
	private static let maximumBarHeight = 4.0

	var body: some HTML {
		let highest = max(years.map(\.calendar.totalCount).max() ?? 0, 1)

		return nav(.ariaLabel("Years")) {
			ol {
				for year in years {
					li {
						a(.href(.fragment(String(year.year)))) {
							span {}
								.style(CareerQuiltPage.Styles.yearBar, ContributionHeatmap.Styles.level(.fourth))
								.style {
									$0.frame(height: .rootEm(Self.maximumBarHeight * Double(year.calendar.totalCount) / Double(highest)))
								}

							span {
								"’\(String(year.year).suffix(2))"
							}
							.accessibilityHidden()

							VisuallyHidden("\(year.year): \(year.calendar.totalCount.formatted(counting: "contribution"))")
						}
						.style(CareerQuiltPage.Styles.yearLink)
					}
					.style(CareerQuiltPage.Styles.yearItem)
				}
			}
			// One column for each year. Thin gaps on phones, where 17 years share the width.
			.style {
				$0
					.display(.grid)
					.gridAutoFlow(.column)
					.gridAutoColumns(.fraction(1))
					.gap(.pixels(2))
					.from(.tablet) {
						$0.gap(.rootEm(0.25))
					}
			}
		}
		.style {
			$0.margin(.bottom, .rootEm(1.5))
		}
	}
}
