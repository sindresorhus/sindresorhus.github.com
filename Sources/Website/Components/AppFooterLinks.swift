import Elementary
import SiteKit

/**
Links to the pages about the app at the end of the app page, and below them the guides about it. The overflow menus are `<select>` elements, which search engines do not follow, so the pages are also linked here.
*/
struct AppFooterLinks: HTML {
	let app: App

	/**
	The guides about the app (``SiteContent/guides(about:)``), which are only linked here. They are a group of their own, with larger rows, so a guide does not look like one more page of the app, like the privacy policy.
	*/
	var guides = [Guide]()

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

					GuideLinks(guides: guides)
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
						guide.title
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
		case guides
		case guideList
		case guideLink

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
				Style()
					.frame(maxWidth: .length(Style.ColumnWidth.standard.maximum - .pageGutter * 2))
					.margin(top: .zero, horizontal: .auto, bottom: .rootEm(3.5))
					.hstack(justification: .center)
					.flexWrap()
					.gap(row: .rootEm(0.5), column: .rootEm(1.5))
					.below(.smallTablet) {
						$0.gap(row: .rootEm(0.75))
					}
			case .pageLink:
				Style().quietLink()
			case .guides:
				// As wide as a guide title on one line on wider screens, and centered below the page links. From laptops, two columns as wide as the box to get the app above them, so the many guides of an app, like Supercharge, are not a long list. The rows of each line have one height, and a last guide alone in its line is centered, like the only guide of an app.
				Style()
					.frame(maxWidth: .rootEm(32))
					.margin(vertical: .zero, horizontal: .auto)
					.wideAppPartColumn()
					.from(.laptop) {
						$0.children(Styles.guideList.selector) {
							$0
								.display(.grid)
								.balancedColumns(2)
								.children("li") {
									$0.display(.grid)
								}
						}
					}
			case .guideList:
				// The space between the questions of a FAQ.
				Style().vstack(spacing: .rootEm(0.625))
			case .guideLink:
				// A row with an arrow at the end, like the link to more questions below the FAQ, so it reads as a link to a page to read. It has the corners of the questions, so a row of one line is not a capsule.
				Style()
					.linkCard()
					.cornerRadius(.boxRadius)
					.hstack(alignment: .center, justification: .spaceBetween, spacing: .rootEm(1))
					.padding(vertical: .rootEm(0.875), horizontal: .rootEm(1.25))
					.textStyle(.body)
					// A title that wraps breaks at a natural point, not before its last word.
					.textWrap(.balance)
					.after {
						$0
							.content("→", alternativeText: "")
							.color(.secondaryText)
					}
			}
		}
	}
}
