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
		PageMetadata(title: PageMetadata.titled("Component Gallery"), isIndexed: false)
	}

	var body: some HTML {
		section {
			h1 {
				"Component Gallery"
			}
			.style(Styles.title)

			p {
				"Every component of the site. Switch the appearance of the system to see dark mode."
			}
			.style(Styles.intro)

			Section("Buttons", id: "buttons") {
				div {
					for fill in [Button<HTMLText>.Fill.primary, .dark, .gradient] {
						for size in [Button<HTMLText>.Size.small, .regular] {
							Button("Button", destination: "#buttons", fill: fill, size: size)
						}
					}

					Button("Download", destination: "#buttons", size: .large)
				}
				.style(Styles.row)
			}

			Section("Badges", id: "badges") {
				div {
					Badge("free")
					Badge("new!", kind: .new)
					Badge("macOS", kind: .platform)
					Badge("archived", kind: .archived)
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
					a(.href("#labels")) {
						Label("Leading icon", icon: .arrowLeft)
					}
					.style(Styles.labelLink)

					a(.href("#labels")) {
						Label("Trailing icon", icon: .arrowRight, iconPosition: .trailing)
					}
					.style(Styles.labelLink)

					IconLink(url: "#labels", label: "RSS", icon: .rss)
					IconLink(url: "#labels", label: "Mail", icon: .mail)
				}
				.style(Styles.row)
			}

			Section("Overflow Menu", id: "overflow-menu") {
				div {
					OverflowMenu(id: "gallery-menu", label: "Gallery menu", links: [LabeledLink("First", path: "/_gallery"), LabeledLink("Second", path: "/_gallery")], [LabeledLink("After a rule", path: "/_gallery")])
					OverflowMenu(id: "gallery-title-menu", label: "Gallery title menu", groups: [LinkGroup(title: "Group", links: [LabeledLink("Link", path: "/_gallery")])], variant: .title)
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
						AppIcon(app, size: 32, isNamedNearby: true)
					}
					.style(Styles.row)

					AppCard(app: app, isNew: true)

					ul {
						LinkRow(app: app)
					}

					p {
						DateText(app.publicationDate, format: .site.month(.wide).day().year())
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
				])
			}

			Section("Prose", id: "prose") {
				Prose(html: MarkdownDocument(parsing: Self.markdownSample, options: MarkdownDocument.Options(theme: .site, showsFootnotesInPopovers: true, addsCopyButtons: true)).html)
			}
		}
		.style(Styles.root)
	}

	private static let markdownSample = """
	Text with **bold**, *italic*, `code`, a [link](#prose), a footnote[^note], and the shortcut ++Command+Shift+K++.

	> [!NOTE]
	> An alert.

	> [!WARNING]
	> A warning.

	- A list item
	- Another item

	| Column | Another |
	| --- | --- |
	| Cell | Cell |

	```swift
	let greeting = "Hello"
	```

	[^note]: The footnote, in a popover.
	"""
}

extension GalleryPage {
	enum Styles: StyleSet {
		case root
		case title
		case intro
		case row
		case icons
		case icon
		case labelLink

		var style: Style {
			switch self {
			case .root:
				Style()
					.frame(maxWidth: .rem(64))
					.margin(.horizontal, .auto)
					.padding(.horizontal, .rem(1.5))
					.pagePadding()
					.children("section") {
						$0.margin(.top, .rem(3))
					}
					.children("section > h2") {
						$0
							.margin(.bottom, .rem(1))
							.font(.xl, weight: .semibold)
							.color(.primaryText)
					}
			case .title:
				Style().font(.xl4, weight: .bold)
			case .intro:
				Style()
					.margin(.top, .rem(0.5))
					.color(.secondaryText)
			case .row:
				Style()
					.hstack(alignment: .center, spacing: .rem(1))
					.flexWrap()
			case .icons:
				Style()
					.display(.grid)
					.declaration("grid-template-columns", "repeat(auto-fill, minmax(8rem, 1fr))")
					.gap(.rem(0.75))
			case .icon:
				Style()
					.hstack(alignment: .center, spacing: .rem(0.5))
					.font(.sm)
					.color(.bodyText)
			case .labelLink:
				Style()
					.display(.inlineFlex)
					.alignItems(.center)
					.gap(.rem(0.5))
					.color(.link)
			}
		}
	}
}
