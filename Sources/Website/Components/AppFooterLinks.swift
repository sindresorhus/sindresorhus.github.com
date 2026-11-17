import Elementary
import Foundation
import SiteKit

/**
Links to the pages about the app at the end of the app page, and below them the guides about it. The overflow menus are `<select>` elements, which search engines do not follow, so the pages are also linked here.
*/
struct AppFooterLinks: HTML {
	let app: App

	/**
	The guides about the app, the guides whose first app it is and the most read guides first (``SiteContent/guides(about:)``), which are only linked here. They are a group of their own, with larger rows, so a guide does not look like one more page of the app, like the privacy policy. An app with more than 10 guides (``shownGuideLimit``), like Supercharge, shows the first 8, and a row below them opens the others, so the list is not several screens tall on a phone. When the row has 20 or more guides, they are in groups by topic (``Guide/Topic``), each in the order of the guides of the app. The others are in the HTML also while the row is closed, so they stay linked.
	*/
	var guides = [Guide]()

	/**
	The most guides that all show. An app with more shows the first 8, and the others are in a row that opens (``moreGuidesID``).
	*/
	static let shownGuideLimit = 10

	/**
	The row that opens the guides that do not show at first, which opens when a link goes to it (`openTargetedSection` in `site.js`).
	*/
	static let moreGuidesID = ElementID("more-guides")

	/**
	Where a link to all the guides of an app with the number of guides goes, like “All 92 Supercharge Guides” at the end of a guide: the row that opens the guides that do not show at first, so the link does not lead to 8 guides and a closed row, or the group of the guides when all show.
	*/
	static func allGuidesID(count: Int) -> ElementID {
		count > shownGuideLimit ? moreGuidesID : App.Section.guides.id
	}

	/**
	Whether there is nothing to link, like for an archived app without pages or guides, so the page leaves the links out.
	*/
	var isEmpty: Bool {
		app.pageOverflowLinks.isEmpty && guides.isEmpty
	}

	var body: some HTML<HTMLTag.nav> {
		nav {
			if !app.pageOverflowLinks.isEmpty {
				div {
					for link in app.pageOverflowLinks {
						Link(link)
						.style(Styles.pageLink)
						.style(Styles.otherSitePageLink, when: link.destination.isOtherSite)
					}
				}
				.style(Styles.pageLinks)
			}

			// The “…” menu of the page links to the group (``App/Section/guides``).
			if !guides.isEmpty {
				div(.id(App.Section.guides.id)) {
					// The title looks like “You Might Also Like” below it, as both are extra content at the end of the page.
					h2 {
						App.Section.guides.title
					}
					.style(SectionStyles.label)

					// Up to 10, all guides show, as a row that opens 1 or 2 more guides saves almost no space.
					if guides.count > Self.shownGuideLimit {
						let otherGuides = Array(guides.dropFirst(8))

						GuideLinks(guides: Array(guides.prefix(8)))

						details(.id(Self.moreGuidesID)) {
							summary {
								"\(otherGuides.count.formatted(.siteNumber)) More Guides"

								// Empty, so screen readers skip it.
								span {}
									.style {
										$0.combined(with: ProseStyles.collapsibleChevronStyle)
									}
							}
							// A guide row with a chevron, like a question of a FAQ, so it reads as a row that opens. From laptops, it is as wide as one of the two columns of guides above it, and centered, like a last guide alone in its line. As a flexbox, it has no disclosure marker of the browser.
							.style {
								$0
									.combined(with: Styles.guideRow)
									.cursor(.pointer)
									.textSelection(.disabled)
									.from(.laptop) {
										$0
											// Half the width, without half the space between the columns.
											.frame(maxWidth: .length(.percent(50) - LengthPercentage.cardSpacing / 2))
											.margin(.horizontal, .auto)
									}
							}

							// Many guides, like the 77 more of Supercharge, are in groups by topic, in the order of the list of guides, so a visitor scans short groups, not one long list. A few guides need no titles.
							if otherGuides.count >= 20 {
								for topic in Guide.Topic.allCases {
									let topicGuides = otherGuides.filter { $0.frontmatter.topic == topic }

									if !topicGuides.isEmpty {
										h3 {
											topic.title
										}
										.style {
											$0
												.margin(top: .rootEm(2), horizontal: .zero, bottom: .zero)
												.secondaryText()
												.fontWeight(.semibold)
												.below(.smallTablet) {
													$0.textStyle(.body)
												}
										}

										// A last guide alone in its line starts in the first column, below the title, not centered.
										GuideLinks(guides: topicGuides)
											.style {
												$0.from(.laptop) {
													$0.children("li") {
														$0.gridColumnSpan(2)
													}
												}
											}
									}
								}
							} else {
								GuideLinks(guides: otherGuides)
							}
						}
						// The space between the rows, above the row that opens and above the guides in it.
						.style {
							$0
								.margin(.top, .length(ProseStyles.collapsibleSectionSpacing))
								.children(Styles.guideList.selector) {
									$0.margin(.top, .length(ProseStyles.collapsibleSectionSpacing))
								}
						}
					} else {
						GuideLinks(guides: guides)
					}
				}
				.style(Styles.guides)
			}
		}
		.accessibilityLabel("More about \(app.title)")
		.style(Styles.root)
	}

}

/**
The rows of some guides, like the guides at the end of an app page and the more guides at the end of a guide. Each place writes the title above them.
*/
struct GuideLinks: HTML {
	let guides: [Guide]

	var body: some HTML<HTMLTag.ul> {
		// Keep the list semantics in Safari, as the styles remove its bullets.
		ul(.role(.list)) {
			for guide in guides {
				li {
					a(.href(guide.url)) {
						guide.task
					}
					.style(AppFooterLinks.Styles.guideLink)
				}
			}
		}
		.style(AppFooterLinks.Styles.guideList)
	}
}

extension AppFooterLinks {
	enum Styles: String, StyleSet {
		case root
		case pageLinks
		case pageLink
		case otherSitePageLink
		case guides
		case guideList
		case guideLink

		/**
		The look of a guide row, which the row that opens more guides shares. It has the corners and the padding of the questions of a FAQ, so a row of one line is not a capsule, and the text of both kinds of rows starts at the same inset.
		*/
		fileprivate static let guideRow = Style()
			.linkCard()
			.cornerRadius(.boxRadius)
			.hstack(alignment: .center, justification: .spaceBetween, spacing: .rootEm(1))
			.padding(vertical: .rootEm(1), horizontal: .pageGutter)
			.textStyle(.body)
			// A title that wraps breaks at a natural point, not before its last word.
			.textWrap(.balance)

		var style: Style {
			switch self {
			case .root:
				// The space of the page at the sides, and the page links and the guides set their own widths.
				Style()
					.padding(.horizontal, .pageGutter)
					.secondaryText()
					// Larger on phones, so the links are easy to read and to tap.
					.below(.smallTablet) {
						$0.textStyle(.body)
					}
			case .pageLinks:
				// The space below sets the guides clearly apart, so they read as their own group. It is on the page links, so an app with only guides has no empty space above them.
				// On phones, the links are inline blocks in balanced lines, so the lines have about the same number of links, and the last line is not one link alone, like “Purchase Help”. Flex items cannot be balanced.
				Style()
					.frame(maxWidth: .length(Style.ColumnWidth.standard.maximum - .pageGutter * 2))
					.margin(top: .zero, horizontal: .auto, bottom: .rootEm(3.5))
					.below(.smallTablet) {
						$0
							.textAlign(.center)
							.textWrap(.balance)
					}
					.from(.smallTablet) {
						$0
							.hstack(justification: .center)
							.flexWrap()
							.gap(row: .rootEm(0.5), column: .rootEm(1.5))
					}
			case .pageLink:
				// On phones, the margins are the space between the links and between the lines (``pageLinks``).
				Style()
					.quietLink()
					.below(.smallTablet) {
						$0
							.display(.inlineBlock)
							.margin(vertical: .rootEm(0.375), horizontal: .rootEm(0.75))
							.textWrap(.nowrap)
					}
			case .otherSitePageLink:
				// The arrow of the press quote sources, like “What’s New” on the App Store, so a visitor knows that the link leaves the site, while the pages of the site next to it, like the privacy policy, have none. Screen readers skip it.
				Style()
					.after {
						$0
							.content(" ↗", alternativeText: "")
							.fontFamily(.system)
							.opacity(0.6)
					}
			case .guides:
				// As wide as a guide title on one line on wider screens, and centered below the page links. From laptops, two columns as wide as the box to get the app above them, so the many guides of an app, like Supercharge, are not a long list. The rows of each line have one height, and a last guide alone in its line is centered, like the only guide of an app. The guides in the row that opens have the same columns.
				Style()
					.frame(maxWidth: .rootEm(32))
					.margin(vertical: .zero, horizontal: .auto)
					.from(.laptop) {
						$0
							.wideAppPartColumn()
							.nested(Styles.guideList.selector) {
								$0
									.display(.grid)
									.balancedColumns(2)
									// The space between the columns of the cards of “You Might Also Like” below (``LengthPercentage/cardSpacing``), so the columns line up.
									.gap(column: .cardSpacing)
									.children("li") {
										$0.display(.grid)
									}
							}
					}
			case .guideList:
				// The space between the questions of a FAQ.
				Style().vstack(spacing: ProseStyles.collapsibleSectionSpacing)
			case .guideLink:
				// A row with an arrow at the end, like the link to more questions below the FAQ, so it reads as a link to a page to read. Semibold, so its line has the weight of the chevron of the “More Guides” row below it.
				Self.guideRow
					.after {
						$0
							.content("→", alternativeText: "")
							.color(.secondaryText)
							.fontWeight(.semibold)
					}
			}
		}
	}
}
