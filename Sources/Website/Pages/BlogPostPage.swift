import Elementary
import Foundation
import SiteKit

struct BlogPostPage: Page {
	let post: BlogPost
	let content: SiteContent

	var path: RoutePath {
		post.path
	}

	/**
	An unlisted post is left out, like from the blog and the feeds.
	*/
	var sitemapEntry: SitemapEntry? {
		post.isListed ? SitemapEntry(lastModified: post.lastModified) : nil
	}

	var socialCard: OpenGraphCard? {
		OpenGraphCard(post: post, project: content.project)
	}

	var metadata: PageMetadata {
		PageMetadata(
			title: post.title,
			description: post.description,
			socialTitle: post.title,
			kind: .article(publishedAt: post.publicationDate, tags: post.tags)
		)
	}

	var body: some HTML {
		section {
			article {
				div {
					p {
						PublicationInfo(post: post, showsReadingTime: true)
					}
					.style(Styles.meta)

					PageHeader(title: post.title, intro: post.description)

					hr()
						.style(Styles.rule)
				}
				.style(Styles.header)

				Prose(markdown: post.markdown.content, variant: .article)
			}

			if !morePosts.isEmpty {
				aside(.ariaLabelledBy(Self.morePostsTitleID)) {
					// The title and the link to all posts share a row, lined up with the posts.
					div {
						h2(.id(Self.morePostsTitleID)) {
							"More Posts"
						}
						.style(Styles.morePostsTitle)

						a(.href(.blog)) {
							"All Posts →"
						}
						.style(Styles.allPosts)
					}
					.style(Styles.morePostsHeader)

					ul {
						for post in morePosts {
							li {
								BlogPostRow(post: post)
							}
						}
					}
					.vstack(spacing: .rootEm(2.5))
				}
				.style(Styles.morePosts)
			}
		}
		.style(Styles.root)

		JSONScript(schema: structuredData)
	}

	/**
	The three newest other posts, for readers who reach the end.
	*/
	private var morePosts: [BlogPost] {
		Array(content.listedPosts.filter { $0.slug != post.slug }.prefix(3))
	}

	private static let morePostsTitleID = "more-posts"

	private var structuredData: Schema.BlogPosting {
		Schema.BlogPosting(
			headline: post.title,
			description: post.description,
			url: path.absoluteURL,
			datePublished: post.publicationDate.formatted(.iso8601),
			dateModified: post.lastModified.formatted(.iso8601),
			author: .author,
			image: (socialCard?.path ?? OpenGraphCard.sitePath).absoluteURL,
			keywords: post.tags.map(\.rawValue).nilIfEmpty
		)
	}
}

extension BlogPostPage {
	enum Styles: StyleSet {
		case root
		case header
		case meta
		case rule
		case morePosts
		case morePostsHeader
		case morePostsTitle
		case allPosts

		var style: Style {
			switch self {
			case .root:
				Style()
					.margin(vertical: 0, horizontal: .auto)
					.nested(ProseStyles.root.selector) {
						$0
							.margin(.top, .rootEm(2))
							// A post that starts with an image moves up, so the gap below the header is the same as with text.
							.nested("&:has(> p:first-child > img)") {
								$0.margin(.top, .pixels(-16))
							}
					}
					.padding(vertical: .rootEm(2), horizontal: 0)
					.from(.smallTablet) {
						$0.padding(vertical: .rootEm(4), horizontal: 0)
					}
					.from(.laptop) {
						$0.padding(vertical: .rootEm(3.5), horizontal: 0)
					}
			case .header:
				// Lines up with the text of the post.
				Style().contentColumn(.prose)
			case .meta:
				// The same text as the other dates and numbers of the site, like on the blog index.
				Style()
					.margin(.bottom, .rootEm(0.5))
					.secondaryText()
					.monospacedDigit()
			case .morePosts:
				// A little faded, so it does not draw attention from the post.
				Style()
					.contentColumn(.prose)
					.margin(.top, .rootEm(4))
					.margin(.bottom, .rootEm(3))
					.padding(.top, .rootEm(4))
					.border(.top, .separator)
					.opacity(0.8)
			case .morePostsHeader:
				Style()
					.hstack(alignment: .baseline, justification: .spaceBetween, spacing: .rootEm(1))
					.margin(.bottom, .rootEm(2.5))
			case .morePostsTitle:
				Style()
					.textStyle(.lead, weight: .semibold)
					.color(.secondaryText)
			case .allPosts:
				Style()
					.textStyle(.caption, weight: .semibold)
					.color(.link)
					.underline(false)
					.hover {
						$0.underline()
					}
			case .rule:
				Style()
					.margin(top: .rootEm(2), horizontal: 0, bottom: 0)
					.border(.top, style: .dashed)
					.opacity(0.15)
			}
		}
	}
}
