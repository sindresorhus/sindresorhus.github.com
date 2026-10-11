import Elementary
import SiteKit

/**
A blog post in a list of posts: the title, the description, and the date. The blog index and the “More Posts” of a post use it.
*/
struct BlogPostRow: HTML {
	let post: BlogPost

	/**
	Whether the list has a heading of its own, like “More Posts”, so the titles are a level below it.
	*/
	var isUnderHeading = false

	var body: some HTML {
		article {
			header {
				if isUnderHeading {
					h3 {
						titleLink
					}
					.style(Styles.title)
				} else {
					h2 {
						titleLink
					}
					.style(Styles.title)
				}
			}

			p {
				post.description ?? ""
			}
			.style(Styles.description)

			footer {
				PublicationInfo(post: post, showsReadingTime: !post.isRedirect)
			}
			.style(Styles.footer)
		}
		.style(Styles.root)
	}

	private var titleLink: some HTML<HTMLTag.a> {
		a(.href(post.url)) {
			post.title
		}
		.style(Styles.link)
		.style(Styles.externalLink, when: post.isExternal)
	}

	enum Styles: StyleSet {
		case root
		case title
		case link
		case externalLink
		case footer
		case description

		var style: Style {
			switch self {
			case .root:
				Style()
					.below(.tablet) {
						$0
							.frame(maxWidth: .rootEm(28))
							.margin(vertical: 0, horizontal: .auto)
					}
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
							.content("⤤")
							.display(.inlineBlock)
							.margin(.leading, .em(0.25))
							.opacity(0.6)
					}
			case .footer:
				Style()
					.margin(.top, .rootEm(1))
					.color(.secondaryText)
			case .description:
				Style()
					.margin(.top, .rootEm(0.5))
					.textStyle(.lead)
					.color(.bodyText)
					.from(.smallTablet) {
						$0.font(.extraLarge)
					}
			}
		}
	}
}
