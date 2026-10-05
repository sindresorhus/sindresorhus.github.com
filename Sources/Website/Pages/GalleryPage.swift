import Elementary
import Foundation
import SiteKit

/**
Every component of the site, for checking how they look after a change. It is only published by `serve`, and is the page to compare with the computed-style tool. The dark mode styles follow the system appearance.
*/
struct GalleryPage: Page {
	let content: SiteContent

	var path: RoutePath {
		"/_gallery"
	}

	var metadata: PageMetadata {
		PageMetadata(title: "Component Gallery", isIndexed: false)
	}

	var body: some HTML {
		section {
			PageHeader(title: "Component Gallery", intro: "Every component of the site. Switch the appearance of the system to see dark mode.")

			Section("Buttons", id: "buttons") {
				div {
					for fill in ButtonStyles.Fill.allCases {
						div {
							for size in ButtonStyles.Size.allCases {
								Link("\(fill)".capitalized, destination: .fragment("buttons"))
									.buttonStyle(fill, size: size)
							}
						}
						.style(Styles.row)
					}
				}
				.vstack(spacing: .rootEm(1))
			}

			Section("Badges", id: "badges") {
				div {
					Badge("Free")
					Badge("New", kind: .new)
					Badge("macOS", kind: .platform)
					Badge("Archived", kind: .archived)
				}
				.style(Styles.row)
			}

			Section("Icons", id: "icons") {
				ul {
					for icon in Icon.allCases {
						li {
							icon
							span {
								String(describing: icon)
							}
						}
						.style(Styles.icon)
					}
				}
				.style(Styles.icons)
			}

			Section("Labels and Icon Links", id: "labels") {
				div {
					a(.href(.fragment("labels"))) {
						Label("Leading icon", icon: .arrowLeft)
					}
					.style(Styles.labelLink)

					a(.href(.fragment("labels"))) {
						Label("Trailing icon", icon: .arrowRight, iconPosition: .trailing)
					}
					.style(Styles.labelLink)

					IconLink("RSS", icon: .rss, destination: .fragment("labels"))
					IconLink("Mail", icon: .mail, destination: .fragment("labels"))
				}
				.style(Styles.row)
			}

			Section("Overflow Menu", id: "overflow-menu") {
				div {
					OverflowMenu(label: "Gallery menu", links: [LabeledLink("First", path: "/_gallery"), LabeledLink("Second", path: "/_gallery")], [LabeledLink("After a rule", path: "/_gallery")])
					OverflowMenu(label: "Gallery title menu", groups: [LinkGroup(title: "Group", links: [LabeledLink("Link", path: "/_gallery")])], variant: .title)
				}
				.style(Styles.row)
			}

			Section("Form Field", id: "form-field") {
				FormField(label: "Email", controlID: "gallery-email", hint: "A hint", errorMessage: "Shown after an invalid value is entered.") {
					input(.id("gallery-email"), .type(.email), .required, .placeholder("Type and leave the field"))
						.style(FormFieldStyles.control)
				}
			}

			if let app = content.activeApps.first {
				Section("Apps", id: "apps") {
					div {
						AppIcon(app, size: 64)
						AppIcon(decorative: app, size: 32)
					}
					.style(Styles.row)

					AppCard(app: app, isNew: true)

					ul {
						LinkRow(app: app)
					}

					p {
						DateText(app.publicationDate, format: .siteDay)
					}

					BackLink(app: app)
				}

				Section("Related Apps", id: "related") {
					RelatedApps(relatedApps: Array(content.activeApps.prefix(4)), content: content)
				}
			}

			if let announcement = content.activeApps.lazy.compactMap(\.announcement).first {
				Section("Announcement", id: "announcement") {
					AnnouncementBanner(announcement: announcement)
				}
			}

			Section("Text", id: "text") {
				p {
					GradientText("Gradient text")
				}

				if let post = content.posts.first {
					p {
						PublicationInfo(post: post, showsReadingTime: true)
					}
				}
			}

			if let tiers = content.pages.lazy.map(\.frontmatter.sponsorTiers).first(where: { !$0.isEmpty }) {
				Section("Sponsors", id: "sponsors") {
					Prose {
						SponsorList(tiers: tiers)
					}
				}
			}

			if let app = content.activeApps.first(where: { !$0.pressQuotes.isEmpty }) {
				Section("Press Quotes", id: "press-quotes") {
					PressQuotes(quotes: app.pressQuotes)
				}
			}

			Section("Reviews", id: "reviews") {
				AppReviews(reviews: [
					AppStoreReview(title: "Exactly what I needed", text: "A review that is long enough to show how the text wraps across a few lines in the card.", author: "A reviewer", rating: 5, date: content.buildDate),
					AppStoreReview(title: "Great", text: "A shorter review, with\na line break.", author: "Another reviewer", rating: 5, date: content.buildDate),
					AppStoreReview(title: Self.longWord, text: "A title with a long word that cannot break must not overflow the card: \(Self.longWord)", author: "A reviewer with a very long name", rating: 4, date: content.buildDate),
				], rating: AppStoreInfo.Rating(average: 4.6, count: 1234))

				AppReviews(reviews: [], rating: AppStoreInfo.Rating(average: 4.6, count: 1234))
			}

			Section("Prose", id: "prose") {
				Prose(markdown: MarkdownDocument(parsing: Self.markdownSample, options: .gallery).content)
			}
		}
		.style(Styles.root)
	}

	/**
	A word that cannot break, which shows text that overflows its box.
	*/
	private static let longWord = "Supercalifragilisticexpialidociouslyunbreakablewordwithoutanyhyphens"

	private static let markdownSample = """
	Text with **bold**, *italic*, `code`, a [link](#prose), a footnote[^note], the shortcut ++Command+Shift+K++, a ^[platform badge](platform: "macOS"), and a long word: \(longWord).

	> A quote, with “quotes” around it.

	> [!NOTE]
	> A note.

	> [!TIP]
	> A tip.

	> [!IMPORTANT]
	> Something important.

	> [!WARNING]
	> A warning.

	> [!CAUTION]
	> A caution.

	- A list item
	- A list item with a subtitle and a description
		: The subtitle
		:: The description, which is smaller after a subtitle.
	- A list item with a description
		:: The description.

	| Column | Another |
	| --- | --- |
	| Cell | Cell |
	| ++Command+K++ | A shortcut in a table |

	```swift
	@MainActor
	struct Greeting {
		// Every kind of highlighted token.
		let text: String = "Hello".uppercased()
		var count = 1
	}
	```

	@Details(summary: "A collapsible section") {
		The content of the section.
	}

	@Tips {
		- A tip.
		- Another tip.
	}

	@QuickAnswer {
		The short answer of a how-to post.
	}

	@Feature(title: "A main feature") {
		The first main feature of an app, with a number above its title.
	}

	@Feature(title: "Another main feature") {
		The second main feature.
	}

	@Cards {
	- A card
		- A point below its title.
	- Another card
	}

	@Steps {
	1. A numbered item
	1. Another numbered item
		- A note below it.
	}

	@SocialLinks

	### A collapsible question

	The answer, which opens like the questions of an FAQ.

	### Another question

	Another answer.

	[^note]: The footnote, in a popover.
	"""
}

extension GalleryPage {
	enum Styles: StyleSet {
		case root
		case row
		case icons
		case icon
		case labelLink

		var style: Style {
			switch self {
			case .root:
				Style()
					.pageColumn(.wide)
			case .row:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(1))
					.flexWrap()
			case .icons:
				Style()
					.grid(minimumColumnWidth: .rootEm(8))
					.gap(.rootEm(0.75))
			case .icon:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.5))
					.textStyle(.caption)
					.color(.bodyText)
			case .labelLink:
				Style()
					.display(.inlineFlex)
					.alignItems(.center)
					.gap(.rootEm(0.5))
					.color(.link)
			}
		}
	}
}
