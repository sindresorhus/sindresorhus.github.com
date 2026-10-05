import Elementary
import SiteKit

/**
A blog post in a list of posts: the title, the description, and the date. The blog index and the “More Posts” of a post use it.
*/
struct BlogPostRow: HTML {
	let post: BlogPost

	var body: some HTML {
		article {
			header {
				h2 {
					a(.href(post.url)) {
						post.title
					}
					.style(Styles.link)
					.style(Styles.externalLink, when: post.isExternal)
				}
				.style(Styles.title)
			}

			p {
				post.description ?? ""
			}
			.style(Styles.description)

			footer {
				span {
					PublicationInfo(post: post, showsReadingTime: !post.isRedirect)
				}
				.style(Styles.meta)
			}
			.style(Styles.footer)
		}
		.style(Styles.root)
	}

	enum Styles: StyleSet {
		case root
		case title
		case link
		case externalLink
		case footer
		case description
		case meta

		var style: Style {
			switch self {
			case .root:
				Style()
					.frame(maxWidth: .rootEm(28))
					.margin(vertical: 0, horizontal: .auto)
					.from(.tablet) {
						$0.declaration(.maxWidth, .none)
					}
			case .title:
				Style()
					.margin(.bottom, .rootEm(0.5))
					.color(.primaryText)
					.font(size: .rootEm(1.875), lineHeight: 1.375)
					.bold()
					.from(.smallTablet) {
						$0.font(size: .rootEm(2.25))
					}
			case .link:
				// A shadow instead of an underline, so the arrow of external links is not underlined.
				Style()
					.hover {
						$0
							.shadow(Shadow(y: .pixels(-4), color: .currentColor, isInset: true))
							.underline(false)
					}
			case .externalLink:
				Style()
					.after {
						$0
							.content(" ⤤")
							.opacity(0.6)
					}
			case .footer:
				Style().margin(.top, .rootEm(1))
			case .description:
				Style()
					.margin(.top, .rootEm(0.5))
					.textStyle(.lead)
					.opacity(0.8)
					.from(.smallTablet) {
						$0.font(.extraLarge)
					}
			case .meta:
				Style()
					.color(.secondaryText)
			}
		}
	}
}
