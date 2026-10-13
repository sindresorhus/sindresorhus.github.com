import Elementary
import SiteKit

/**
Columns of links to the pages of the site, so pages that the header does not link, like the FAQ, are easy to find, a column of the social links, and below them a quote.
*/
struct SiteFooter: HTML {
	var body: some HTML {
		footer(.id(Hooks.siteFooter)) {
			div {
				nav {
					for group in Self.linkGroups {
						div {
							h2 {
								group.title
							}
							.style(Styles.groupTitle)

							ul {
								for link in group.links {
									li {
										a(.href(link.destination)) {
											link.title
										}
										// `site.js` shows the link to the source in the greeting in the console.
										.attributes(.hook(Hooks.sourceLink), when: link.destination == Self.sourceLink.destination)
										.style(Styles.link)
									}
								}
							}
							.style(Styles.links)
						}
					}
				}
				.accessibilityLabel("Site")
				.style(Styles.groups)

				div {
					h2 {
						"Follow"
					}
					.style(Styles.groupTitle)

					ul {
						for link in Site.author.socialLinks {
							li {
								a(.href(.url(link.url)), .rel("me")) {
									link.icon.size(Self.socialIconSize)
									link.name
								}
								.style(Styles.link, Styles.socialLink)
							}
						}
					}
					.style(Styles.links)
				}

				div {
					q {
						"The people who are crazy enough to think they can change the world are the ones who do"
					}
					.style(Styles.quote)
				}
				.style(Styles.bottom)
			}
			.style(Styles.content)
		}
		.hiddenFromSearchSnippets()
		.style(Styles.root)
	}

	private static let linkGroups = [
		LinkGroup(
			title: "Apps",
			links: [LabeledLink("All Apps", path: .apps)] + [AppCategory.free, .paid, .macOS, .iOS, .menuBar].map { LabeledLink($0.title, path: $0.path) } + [
				.wallOfLove,
				.appTimeline,
				LabeledLink("Guess the App", path: .appdle),
			]
		),
		LinkGroup(
			title: "Help",
			links: [
				.faq,
				LabeledLink("Feedback", path: .feedback),
				LabeledLink("Contact", path: .contact),
				.olderVersions,
				.discounts,
				LabeledLink("Refunds", destination: .refundQuestion),
				.termsOfUse,
			]
		),
		LinkGroup(
			title: "About",
			links: [
				LabeledLink("About Me", path: .about),
				LabeledLink("Blog", path: .blog),
				LabeledLink("Now", path: .now),
				LabeledLink("Visit 1999", path: .geoCities),
				LabeledLink("Donate", path: .donate),
				LabeledLink("Supporters", path: .supporters),
				LabeledLink("RSS Feeds", path: .feeds),
				sourceLink,
			]
		),
	]

	private static let sourceLink = LabeledLink("Source Code", destination: .url(Site.sourceURL))

	/**
	The size of the icons of the social links, which the style uses to put them in the middle of the capital letters.
	*/
	private static let socialIconSize = Length.rootEm(1)

	/**
	The IDs and data attributes that the scripts of the component find elements by.
	*/
	enum Hooks: String, ScriptHookSet {
		case siteFooter = "site-footer"
		case sourceLink = "data-source-link"
	}

	/**
	A faint line, as the space and the smaller text already set the footer and its quote apart.
	*/
	private static let lineColor = Color.lightDark(.black.opacity(0.06), .white.opacity(0.06))

	enum Styles: StyleSet {
		case root
		case content
		case groups
		case groupTitle
		case links
		case link
		case bottom
		case quote
		case socialLink

		var style: Style {
			switch self {
			case .root:
				Style()
					.border(.top, SiteFooter.lineColor)
			case .content:
				// On phones, the link groups and the social links are a grid of two columns, two groups in each row. From tablets, they are four columns of the same width, spread over the width of the header, so there is no empty space between them. The space between the rows and the margin of the quote add up to the space above the quote.
				Style()
					.pageWidth()
					.grid(columns: 2)
					.gap(row: .rootEm(2.5), column: .rootEm(1.5))
					.padding(vertical: .rootEm(3), horizontal: .pageGutter)
					.from(.tablet) {
						$0
							.gridColumns(4)
							.padding(top: .rootEm(4), horizontal: .pageGutter, bottom: .rootEm(2.5))
					}
			case .groups:
				// The groups are in the grid of the footer, with the social links.
				Style().display(.contents)
			case .groupTitle:
				Style()
					.margin(.bottom, .rootEm(0.75))
					.textStyle(.caption, weight: .semibold)
					.color(.primaryText)
			case .links:
				Style().vstack(spacing: .rootEm(0.5))
			case .link:
				Style()
					.secondaryText()
					.quietLink()
					// Larger on phones, so the links are easy to read and to tap.
					.below(.smallTablet) {
						$0.textStyle(.body)
					}
			case .bottom:
				Style()
					.gridColumnSpan(2)
					.from(.tablet) {
						$0.gridColumnSpan(4)
					}
					.margin(.top, .rootEm(0.5))
					.padding(.top, .rootEm(1.5))
					.border(.top, SiteFooter.lineColor)
					.textAlign(.center)
			case .quote:
				Style().secondaryText(.extraSmall)
			case .socialLink:
				// The icon is in the line of the text, not in a stack, so the text is on the same baseline as the text of the other columns, and the lines are as high. The icon is in the middle of the capital letters, as `middle` puts it in the middle of the lowercase letters, which looks low.
				Style()
					.nested(Icon.selector) {
						$0
							.display(.inlineBlock)
							.verticalAlign(.capitalHeight(0.5) - SiteFooter.socialIconSize * 0.5)
							.margin(.trailing, .rootEm(0.5))
					}
			}
		}
	}
}
