import Elementary
import Foundation
import SiteKit

struct BlogPostPage: Page {
	let post: BlogPost

	var path: RoutePath {
		post.path
	}

	var lastModified: Date? {
		max(post.lastCommitDate ?? post.publicationDate, post.publicationDate)
	}

	var metadata: PageMetadata {
		PageMetadata(
			title: PageMetadata.titled(post.title),
			description: post.description,
			socialTitle: post.title,
			kind: .article(publishedAt: post.publicationDate, tags: post.tags),
			image: PageMetadata.SocialImage(path: OpenGraphCard.path(for: post), description: post.title)
		)
	}

	var body: some HTML {
		section {
			article {
				header {
					p {
						PublicationInfo(post: post, showsReadingTime: true)
					}
					.style(Styles.meta)

					h1 {
						post.title
					}
					.style(Styles.title)
					.style(Styles.titleWithDescription, when: post.description != nil)

					if let description = post.description {
						p {
							description
						}
						.style(Styles.description)
					}

					hr()
						.style(Styles.rule)
				}
				.style(Styles.header)

				Prose(html: post.markdown.html, variant: .article)
			}
		}
		.style(Styles.root)
	}
}

extension BlogPostPage {
	enum Styles: StyleSet {
		case root
		case header
		case meta
		case title
		case titleWithDescription
		case description
		case rule

		var style: Style {
			switch self {
			case .root:
				Style()
					.margin(vertical: 0, horizontal: .auto)
					.padding(vertical: .rem(2), horizontal: 0)
					.breakpoint(.sm) {
						$0.padding(vertical: .rem(4), horizontal: 0)
					}
					.breakpoint(.lg) {
						$0.padding(vertical: .rem(3.5), horizontal: 0)
					}
			case .header:
				Style().contentColumn()
			case .meta:
				Style()
					.margin(.bottom, .rem(0.5))
					.fontFamily(.monospace)
					.font(.sm)
					.letterSpacing(.em(0.1))
					.opacity(0.5)
			case .title:
				Style()
					.margin(.bottom, .rem(0.75))
					.font(size: .rem(3), lineHeight: 1.25)
					.fluidFontSize(fromRem: 3, toRem: 3.75, between: .md, and: .lg)
					.bold()
					.letterSpacing(.em(-0.025))
			case .titleWithDescription:
				Style().margin(.bottom, .rem(1))
			case .description:
				Style()
					.font(.xl)
					.italic()
					.opacity(0.65)
					.textWrap(.pretty)
			case .rule:
				Style()
					.margin(top: .rem(2), horizontal: 0, bottom: 0)
					.declaration(.borderStyle, "dashed")
					.opacity(0.15)
			}
		}
	}
}
