import Elementary
import SiteKit

/**
An article in a list of articles: the title, the description, and the date of a blog post, or the icon of the app of a guide. The blog index, the “More Posts” of a post, and the guides page use it.

```swift
ArticleRow(.post(post))
ArticleRow(.guide(guide))
```
*/
struct ArticleRow: HTML {
	enum Article {
		case post(BlogPost)

		/**
		A guide, with the icon of its first app, so the visitor sees what the guide is about before the click. Its title is smaller than the title of a post, as the guides are many and short.
		*/
		case guide(Guide.Resolved)
	}

	private let article: Article

	/**
	The level of the title: 2 right below the title of the page, or 3 when the list has a heading of its own, like “More Posts”.
	*/
	private let headingLevel: ItemHeadingLevel

	/**
	Whether the icon of a guide is in view when the page opens, so it loads at once, not lazily, like the first rows of a list.
	*/
	private let isAboveFold: Bool

	init(_ article: Article, headingLevel: ItemHeadingLevel = .h2, isAboveFold: Bool = false) {
		self.article = article
		self.headingLevel = headingLevel
		self.isAboveFold = isAboveFold
	}

	var body: some HTML {
		switch article {
		case .post(let post):
			row(title: post.title, url: post.url, description: post.description, isExternal: post.isExternal) {
				footer {
					PublicationInfo(post: post)
				}
				.style(Styles.footer)
			}
		case .guide(let resolved):
			let guide = resolved.guide

			// The icon only shows the app of the title next to it, so screen readers skip it.
			div {
				AppIcon(decorative: resolved.app, size: 56, isAboveFold: isAboveFold)
					.style(Styles.icon)

				row(title: guide.title, url: guide.url, description: guide.description, isExternal: false) {
					EmptyHTML()
				}
				.style(Styles.guide)
			}
			.style(Styles.iconRow)
		}
	}

	private func row(
		title: String,
		url: LinkDestination,
		description: String?,
		isExternal: Bool,
		@ContentBuilder footer: () -> some HTML
	) -> some HTML<HTMLTag.article> {
		Elementary.article {
			header {
				headingLevel.heading(style: Styles.title) {
					titleLink(title: title, url: url, isExternal: isExternal)
				}
			}

			if let description {
				p {
					description
				}
				.style(Styles.description)
			}

			footer()
		}
	}

	private func titleLink(title: String, url: LinkDestination, isExternal: Bool) -> some HTML<HTMLTag.a> {
		a(.href(url)) {
			title
		}
		.style(Styles.link)
		.style(Styles.externalLink, when: isExternal)
	}

	enum Styles: String, StyleSet {
		case title
		case link
		case externalLink
		case footer
		case description
		case iconRow
		case icon
		case guide

		var style: Style {
			switch self {
			case .title:
				// The size of a heading in prose, and a little larger from small tablets, with the tighter lines of titles.
				Style()
					.margin(.bottom, .rootEm(0.5))
					.textStyle(.sectionTitle)
					.color(.primaryText)
					.from(.smallTablet) {
						$0.font(size: .rootEm(2.25))
					}
			case .link:
				// A thick underline under the pointer. The arrow of external links is an inline block, so it is not underlined.
				Style()
					.underlineOffset(.pixels(6))
					.hoverOrFocusVisible {
						$0.underline(thickness: .pixels(3))
					}
			case .externalLink:
				Style()
					.after {
						$0
							.content("⤤", alternativeText: "")
							.display(.inlineBlock)
							.margin(.leading, .em(0.25))
							.opacity(0.6)
					}
			case .footer:
				Style()
					.margin(.top, .rootEm(1))
					.color(.secondaryText)
			case .description:
				// A long word, like a keyboard shortcut, breaks with large text, instead of making the page wider than the screen.
				Style()
					.margin(.top, .rootEm(0.5))
					.textStyle(.lead)
					.color(.bodyText)
					.overflowWrap(.breakWord)
					.from(.smallTablet) {
						$0.font(.extraLarge)
					}
			case .iconRow:
				// On phones, the icon is next to the title, and the description is below them at the full width, so it is not a narrow column below the title. The article is a part of the grid there (``guide``). From small tablets, the icon is at the start of the title, and the text is in the rest of the row.
				Style()
					.grid(columns: .auto, .fraction(1))
					.alignItems(.center)
					.gap(row: .zero, column: .rootEm(1))
					.from(.smallTablet) {
						$0
							.hstack(alignment: .start, spacing: .rootEm(1.25))
					}
			case .icon:
				// Smaller on phones, so the title has more room. In pixels, so it does not grow with larger text, which needs the room more than the icon.
				Style()
					.frame(width: .pixels(44))
					.filter(AppCard.iconShadow)
					.from(.smallTablet) {
						$0.frame(width: .pixels(56))
					}
			case .guide:
				// One step smaller than the titles of posts, so most titles fit on one line on wider screens, and the titles are not larger than the headings in a guide. The description stays the size of a lead, in the secondary color, so the titles stand out in the long list.
				// On phones, the title and the description are parts of the grid of the row (``iconRow``), so the space between them is the margin of the description.
				Style()
					.below(.smallTablet) {
						$0
							.display(.contents)
							.nested(Self.title.selector) {
								$0.margin(.bottom, .zero)
							}
							.nested(Self.description.selector) {
								$0.gridColumnSpanAll()
							}
					}
					.from(.smallTablet) {
						$0
							.flex(1)
							.frame(minWidth: .zero)
					}
					.nested(Self.title.selector) {
						$0
							.font(size: .rootEm(1.25))
							.from(.smallTablet) {
								$0.font(size: .rootEm(1.5))
							}
					}
					.nested(Self.description.selector) {
						$0.secondaryText(.lead)
					}
			}
		}
	}
}
