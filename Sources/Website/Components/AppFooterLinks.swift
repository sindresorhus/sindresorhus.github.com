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

			if !guides.isEmpty {
				div {
					h2 {
						"Guides"
					}
					.style(Styles.guidesTitle)

					ul {
						for guide in guides {
							li {
								a(.href(guide.url)) {
									guide.title
								}
								.style(Styles.guideLink)
							}
						}
					}
					.style(Styles.guideList)
				}
				.style(Styles.guides)
			}
		}
		.accessibilityLabel("More about \(app.title)")
		.style(Styles.root)
	}

	enum Styles: StyleSet {
		case root
		case pageLinks
		case pageLink
		case guides
		case guidesTitle
		case guideList
		case guideLink

		var style: Style {
			switch self {
			case .root:
				Style()
					.contentColumn()
					.secondaryText()
					// Larger on phones, so the links are easy to read and to tap.
					.below(.smallTablet) {
						$0.textStyle(.body)
					}
			case .pageLinks:
				// The space below sets the guides clearly apart, so they read as their own group. It is on the page links, so an app with only guides has no empty space above them.
				Style()
					.margin(.bottom, .rootEm(3.5))
					.hstack(justification: .center)
					.flexWrap()
					.gap(row: .rootEm(0.5), column: .rootEm(1.5))
					.below(.smallTablet) {
						$0.gap(row: .rootEm(0.75))
					}
			case .pageLink:
				Style().quietLink()
			case .guides:
				// As wide as a guide title on one line on wider screens, and centered below the page links.
				Style()
					.frame(maxWidth: .rootEm(32))
					.margin(vertical: .zero, horizontal: .auto)
			case .guidesTitle:
				// Like the titles of the groups of the footer.
				Style()
					.margin(.bottom, .rootEm(0.75))
					.textAlign(.center)
					.textStyle(.caption, weight: .semibold)
					.color(.secondaryText)
			case .guideList:
				Style().vstack(spacing: .rootEm(0.5))
			case .guideLink:
				// A row with an arrow at the end, like the link to more questions below the FAQ, so it reads as a link to a page to read.
				Style()
					.linkCard()
					.hstack(alignment: .center, justification: .spaceBetween, spacing: .rootEm(1))
					.padding(vertical: .rootEm(0.875), horizontal: .rootEm(1.25))
					.textStyle(.body)
					.after {
						$0
							.content("→", alternativeText: "")
							.color(.secondaryText)
					}
			}
		}
	}
}
