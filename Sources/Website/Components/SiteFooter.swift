import Elementary
import SiteKit

/**
Columns of links to the pages of the site, so pages that the header does not link, like the FAQ, are easy to find, a column of the social links, and below them a quote.
*/
struct SiteFooter: HTML {
	/**
	The app of an app page or of a page about the app, like its release notes or a guide (``Page/feedbackApp``), so the “Feedback & Support” link opens the form for the app.
	*/
	var app: App?

	/**
	The pages above the page (``Page/parents``), for the breadcrumb at the top of the footer, so a visitor at the end of a long page sees where it is and goes up without scrolling back. Empty for a page without a breadcrumb.
	*/
	var parents = [LabeledLink]()

	/**
	The name of the page, at the end of the breadcrumb (``Page/breadcrumbTitle``).
	*/
	var pageTitle = ""

	/**
	The form for the app of the page, so the visitor does not pick the app again. An archived app gets no support, so its pages link to the app picker of the form, like the other pages.
	*/
	private var feedbackLink: LabeledLink {
		guard
			let app,
			!app.isArchived
		else {
			return .feedback
		}

		return LabeledLink(LabeledLink.feedback.title, destination: app.feedbackURL)
	}

	var body: some HTML {
		footer(.id(IDs.siteFooter)) {
			div {
				if !parents.isEmpty {
					breadcrumb
				}

				nav {
					for group in linkGroups {
						div {
							h2 {
								group.title
							}
							.style(Styles.groupTitle)

							ul {
								// The search of the site is first in “Help”, so a visitor at the end of a long page finds it without going back up, also on an app page, where the bar of the app hides the button of the header.
								if group.title == Self.helpTitle {
									li {
										SiteSearch.OpenButton {
											"Search"
										}
										.style(Styles.link)
									}
								}

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

	/**
	The unicorn of the header of the home page, the pages above the page, and the page.
	*/
	private var breadcrumb: some HTML<HTMLTag.nav> {
		nav {
			ol {
				li {
					a(.href(.root)) {
						"🦄"
					}
					.accessibilityLabel("Home")
					// The emoji cannot change its color, so it shows keyboard focus with a fill.
					.style(Styles.link)
					.style {
						$0.focusFill()
					}
				}
				.style(Styles.breadcrumbItem)

				for link in parents {
					li {
						Link(link)
							.style(Styles.link)
					}
					.style(Styles.breadcrumbItem)
				}

				li(.ariaCurrent(.page)) {
					pageTitle
				}
				.style(Styles.breadcrumbItem)
			}
			.style(Styles.breadcrumbItems)

			// The same trail for search results, which can show it instead of the path of the URL. The home page is only on the page, as search results do not need it. The parents are pages, so the page of the link does not matter.
			JSONScript(
				schema: Schema.BreadcrumbList(
					parents: parents.map { (name: $0.title, url: $0.destination.absoluteURL(on: .root)) },
					name: pageTitle
				)
			)
		}
		.accessibilityLabel("Breadcrumb")
		.style(Styles.breadcrumb)
	}

	private var linkGroups: [LinkGroup] {
		[
			LinkGroup(
				title: "Apps",
				links: [LabeledLink("All Apps", path: .apps)] + [AppCategory.free, .paid, .macOS, .iOS, .menuBar].map { LabeledLink($0.title, path: $0.path) } + [
					.wallOfLove,
					.appTimeline,
					.tinyApps,
				]
			),
			LinkGroup(
				title: Self.helpTitle,
				links: [
					.faq,
					.guides,
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

	private static let helpTitle = "Help"

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

	enum Styles: String, StyleSet {
		case root
		case content
		case groups
		case groupTitle
		case links
		case link
		case bottom
		case quote
		case socialLink
		case breadcrumb
		case breadcrumbItems
		case breadcrumbItem

		private static let columnSpacing = LengthPercentage.rootEm(1.5)

		var style: Style {
			switch self {
			case .root:
				// A faint line, as the space and the smaller text already set the footer and its quote apart.
				Style()
					.border(.top, .separator)
			case .content:
				// On phones, the link groups and the social links are a grid of two columns, two groups in each row, or one column when two columns would be narrower than the longest links, like with large text. From small tablets, they are four columns of the same width, spread over the width of the header, so there is no empty space between them. The space between the rows and the margin of the quote add up to the space above the quote.
				// 9.3125rem is about the width of the longest link, “Feedback & Support”, so a phone of 375px, like the iPhone mini, gets two columns, and a phone of 360px keeps one column, where the link would break.
				Style()
					.pageWidth()
					.grid(minimumColumnWidth: .max(.rootEm(9.3125), (.percent(100) - Self.columnSpacing) * 0.5))
					.gap(row: .rootEm(2.5), column: Self.columnSpacing)
					.padding(vertical: .rootEm(3), horizontal: .pageGutter)
					// Closer columns until tablets, so the longest links fit.
					.from(.smallTablet) {
						$0
							.gridColumns(4)
							.gap(column: .rootEm(1))
					}
					.from(.tablet) {
						$0
							.gap(column: Self.columnSpacing)
							.padding(top: .rootEm(4), horizontal: .pageGutter, bottom: .rootEm(2.5))
					}
			case .groups:
				// The groups are in the grid of the footer, with the social links.
				Style().display(.contents)
			case .groupTitle:
				// On phones, as large as the links (``link``), so a title is not smaller than the links it names.
				Style()
					.margin(.bottom, .rootEm(0.75))
					.textStyle(.caption, weight: .semibold)
					.color(.primaryText)
					.below(.smallTablet) {
						$0.textStyle(.body, weight: .semibold)
					}
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
					// On touch screens, the tap areas of the links touch each other, so a tap between two links still opens one of them.
					.minimumTapArea()
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
			case .breadcrumb:
				// Above the groups, apart from them with the faint line of the quote (``bottom``). The space below the line is less than the space between the rows of the grid.
				Style()
					.gridColumnSpanAll()
					.margin(.bottom, .rootEm(-0.5))
					.padding(.bottom, .rootEm(1.5))
					.border(.bottom, .separator.opacity(0.6))
			case .breadcrumbItems:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.5))
					.flexWrap()
			// A “›” after each item before the last, which screen readers skip, as the list already says the order. It is at the end of an item, so a line that wraps ends with an arrow and no line starts with one, like the dots of the facts of the hero. The current page is in the color of the titles of the groups.
			case .breadcrumbItem:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.5))
					.textStyle(.caption)
					.color(.primaryText)
					// Larger on phones, like the links (``link``).
					.below(.smallTablet) {
						$0.textStyle(.body)
					}
					.notLastChild {
						$0.after {
							$0
								.content("›", alternativeText: "")
								.color(.secondaryText)
						}
					}
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
