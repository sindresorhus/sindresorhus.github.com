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
	An unlisted post is left out, as it is not indexed, like it is left out of the blog and the feeds.
	*/
	var sitemapEntry: SitemapEntry {
		SitemapEntry(lastModified: post.lastModified)
	}

	var socialImage: SocialImage {
		.card(OpenGraphCard(post: post, project: content.project))
	}

	var metadata: PageMetadata {
		PageMetadata(
			article: post,
			title: post.title,
			description: post.description,
			// The page shows only the month that the post was published, and an update is in the text of the post, like the “Update, October 2026” alerts. The sitemap has the last change of the file (``sitemapEntry``).
			modifiedOn: post.publicationDate,
			tags: post.tags,
			// Search engines do not index an unlisted post, like it is not in the sitemap.
			isIndexed: post.isListed
		)
	}

	var body: some HTML {
		section {
			article {
				div {
					p {
						PublicationInfo(post: post)
					}
					.style(Styles.meta)

					PageHeader(title: post.title, intro: post.description)

					hr()
						.style(Styles.rule)
				}
				.style(Styles.header)

				Prose(markdown: post.markdown.content, variant: .article)
					.style {
						$0.margin(.top, .rootEm(2))
					}
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
							"All Posts"
						}
						.style(Styles.allPosts)
					}
					.style(Styles.morePostsHeader)

					ul {
						for post in morePosts {
							li {
								ArticleRow(.post(post), headingLevel: .h3)
							}
						}
					}
					// The same space between the posts as on the blog page.
					.style {
						$0
							.vstack(spacing: .rootEm(2.5))
							.from(.tablet) {
								$0.gap(.rootEm(4))
							}
					}
				}
				.style(Styles.morePosts)
			}
		}
		.style(Styles.root)

		JSONScript(schema: structuredData)
	}

	/**
	The two other posts with the most shared tags, newest first, for readers who reach the end.
	*/
	private var morePosts: [BlogPost] {
		let tags = Set(post.tags)

		return content.listedPosts
			.filter { $0.slug != post.slug }
			.map { (post: $0, sharedTags: tags.intersection($0.tags).count) }
			.sorted(using: [
				KeyPathComparator(\.sharedTags, order: .reverse),
				KeyPathComparator(\.post.frontmatter.publicationDate, order: .reverse)
			])
			.prefix(2)
			.map(\.post)
	}

	private static let morePostsTitleID = ElementID("more-posts")

	private var structuredData: Schema.Article {
		Schema.Article(
			document: post,
			type: .blogPosting,
			title: post.title,
			description: post.description,
			dateModified: post.publicationDate,
			images: [socialImageURL],
			keywords: post.tags.map(\.rawValue).nilIfEmpty
		)
	}
}

extension BlogPostPage {
	enum Styles: String, StyleSet {
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
				Style().pagePadding()
			case .header:
				// Lines up with the text of the post. From small tablets, the description is one step larger than the text of the post, like the same description on the blog (``ArticleRow``), so it reads as the deck of the post, not as its first paragraph.
				Style()
					.contentColumn(.prose)
					.nested(PageHeaderStyles.intro.selector) {
						$0.from(.smallTablet) {
							$0.font(.extraLarge)
						}
					}
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
					.opacity(0.8)
					// The rule after the post is as wide as the text, inside the space of the page at the sides, with the same space above and below it.
					.before {
						$0
							.content("")
							.display(.block)
							.border(.top, .separator)
							.margin(.bottom, .rootEm(4))
					}
			case .morePostsHeader:
				Style()
					.hstack(alignment: .baseline, justification: .spaceBetween, spacing: .rootEm(1))
					.margin(.bottom, .rootEm(2.5))
			case .morePostsTitle:
				Style()
					.textStyle(.lead, weight: .semibold)
					.color(.secondaryText)
			case .allPosts:
				// The arrow is only on the screen, so the name of the link is its text. The size of the text, like “All Guides” at the end of a guide.
				Style()
					.moreLink()
					.trailingArrow()
			case .rule:
				Style()
					.margin(top: .rootEm(2), horizontal: .zero, bottom: .zero)
					.border(.top, .separator, style: .dashed)
			}
		}
	}
}
