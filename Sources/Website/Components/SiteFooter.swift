import Elementary
import SiteKit

/**
Columns of links to the pages of the site, so pages that the header does not link, like the FAQ, are easy to find, a column of the social links, and below them a quote.
*/
struct SiteFooter: HTML {
	/**
	The app of an app page or of a page about the app, like its release notes or a guide (``Page/feedbackApp``), so the “Feedback” link opens the form for the app.
	*/
	var app: App?

	/**
	The form for the app of the page, so the visitor does not pick the app again. An archived app gets no support, so its pages link to the app picker of the form, like the other pages.
	*/
	private var feedbackLink: LabeledLink {
		guard
			let app,
			!app.isArchived
		else {
			return LabeledLink("Feedback", path: .feedback)
		}

		return LabeledLink("Feedback", destination: app.feedbackURL)
	}

	var body: some HTML {
		footer(.id(IDs.siteFooter)) {
			div {
				nav {
					for group in linkGroups {
						div {
							h2 {
								group.title
							}
							.style(Styles.groupTitle)

							ul {
								for link in group.links {
									li {
										Link(link)
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
								ProfileLink(profile: link, iconSize: Self.socialIconSize)
									.style(Styles.link, Styles.socialLink)
							}
						}
					}
					.style(Styles.links)
				}

				div {
					// The credit is only in the tooltip, so the quote stays short.
					q(.title("Apple, “Think Different” (1997)")) {
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

	private var linkGroups: [LinkGroup] {
		[
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
					LabeledLink("Guides", path: .guides),
					feedbackLink,
					LabeledLink("Contact", path: .contact),
					.olderVersions,
					.discounts,
					LabeledLink("Refunds", destination: .refundQuestion),
					.termsOfUse,
					.privacyPolicy,
				]
			),
			LinkGroup(
				title: "About",
				links: [
					LabeledLink("About Me", path: .about),
					LabeledLink("Blog", path: .blog),
					LabeledLink("Now", path: .now),
					LabeledLink("Open Source", path: .openSource),
					LabeledLink("Visit 1999", path: .geoCities),
					LabeledLink("Donate", path: .donate),
					LabeledLink("Supporters", path: .supporters),
					LabeledLink("RSS Feeds", path: .feeds),
					Self.sourceLink,
				]
			),
		]
	}

	private static let sourceLink = LabeledLink("Source Code", destination: .url(Site.sourceURL))

	/**
	The size of the icons of the social links, which the style uses to put them in the middle of the capital letters.
	*/
	private static let socialIconSize = LengthPercentage.rootEm(1)

	/**
	The IDs that the scripts of the component find elements by.
	*/
	enum IDs: String, ScriptIDSet {
		case siteFooter = "site-footer"
	}

	/**
	The data attributes that the scripts of the component find elements by.
	*/
	enum Hooks: String, ScriptDataAttributeSet {
		case sourceLink = "source-link"
	}

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

		private static let columnSpacing = LengthPercentage.rootEm(1.5)

		var style: Style {
			switch self {
			case .root:
				// A faint line, as the space and the smaller text already set the footer and its quote apart.
				Style()
					.border(.top, .separator)
			case .content:
				// On phones, the link groups and the social links are a grid of two columns, two groups in each row, or one column when two columns would be narrower than the longest links, like with large text. From tablets, they are four columns of the same width, spread over the width of the header, so there is no empty space between them. The space between the rows and the margin of the quote add up to the space above the quote.
				Style()
					.pageWidth()
					.grid(minimumColumnWidth: .max(.rootEm(9.5), (.percent(100) - Self.columnSpacing) * 0.5))
					.gap(row: .rootEm(2.5), column: Self.columnSpacing)
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
					.gridColumnSpanAll()
					// More space above the line than below it, so the quote reads as the end of the page, apart from the links. The line is fainter than the line above the footer, as it is only between two parts of the footer.
					.margin(.top, .rootEm(2))
					.padding(.top, .rootEm(1.5))
					.border(.top, .separator.opacity(0.6))
					.textAlign(.center)
			case .quote:
				// A block, so the lines have the line height of its small text, not of the larger text of its parent.
				Style()
					.display(.block)
					.secondaryText(.extraSmall)
					.textWrap(.balance)
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

/**
A link to a social profile of the author, with its icon and name, like in the footer. It has `rel="me"`, so the profile can check that it belongs to the site, like Mastodon does.
*/
struct ProfileLink: HTML {
	let profile: Person.SocialLink
	let iconSize: LengthPercentage

	var body: some HTML<HTMLTag.a> {
		a(.href(.url(profile.url)), .rel("me")) {
			profile.icon.size(iconSize)
			profile.name
		}
	}
}
