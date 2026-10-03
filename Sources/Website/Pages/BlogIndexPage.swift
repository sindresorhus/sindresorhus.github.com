import Elementary
import Foundation
import SiteKit

/**
A page of the blog post list. The first page is `/blog`, then `/blog/2`, and so on.
*/
struct BlogIndexPage: Page {
	static let postsPerPage = 10

	let posts: [BlogPost]
	let pageNumber: Int
	let pageCount: Int

	/**
	One page for each group of posts.
	*/
	static func pages(for posts: [BlogPost]) -> [Self] {
		let groups = stride(from: 0, to: posts.count, by: postsPerPage).map { Array(posts[$0..<min($0 + postsPerPage, posts.count)]) }
		return groups.enumerated().map { Self(posts: $0.element, pageNumber: $0.offset + 1, pageCount: groups.count) }
	}

	var path: RoutePath {
		Self.path(pageNumber: pageNumber)
	}

	private static func path(pageNumber: Int) -> RoutePath {
		pageNumber == 1 ? .blog : RoutePath.blog.appending(String(pageNumber))
	}

	var metadata: PageMetadata {
		PageMetadata(
			title: pageNumber == 1 ? PageMetadata.titled("Blog") : PageMetadata.titled("Blog", "Page \(pageNumber)"),
			description: "Articles by Sindre Sorhus about open source and programming.",
			kind: .blog,
			isIndexed: pageNumber == 1
		)
	}

	var body: some HTML {
		section {
			// The design has no visible title.
			h1 {
				pageNumber == 1 ? "Blog" : "Blog, Page \(pageNumber)"
			}
			.style(VisuallyHidden.Styles.root)

			ul {
				for post in posts {
					li {
						article {
							header {
								h2 {
									a(.href(post.url)) {
										post.title
									}
									.style(Styles.itemLink)
									.style(Styles.externalItemLink, when: post.isExternal)
								}
								.style(Styles.itemTitle)
							}

							p {
								post.description ?? ""
							}
							.style(Styles.itemDescription)

							footer {
								span {
									PublicationInfo(post: post, showsReadingTime: !post.isRedirect)
								}
								.style(Styles.itemMeta)
							}
							.style(Styles.itemFooter)
						}
						.style(Styles.item)
					}
				}
			}
			.style(Styles.list)

			if pageCount > 1 {
				div {
					// Without a newer or older page, the link has no destination and keeps its space, hidden.
					a {
						Label("Newer posts", icon: .arrowLeft, iconSize: .rem(1.5))
					}
					.style(Styles.paginationLink)
					.attributes(.href(Self.path(pageNumber: pageNumber - 1)), when: pageNumber > 1)

					a {
						Label("Older posts", icon: .arrowRight, iconPosition: .trailing, iconSize: .rem(1.5))
					}
					.style(Styles.paginationLink)
					.attributes(.href(Self.path(pageNumber: pageNumber + 1)), when: pageNumber < pageCount)
				}
				.style(Styles.pagination)
			}
		}
		.style(Styles.root)
	}
}

extension BlogIndexPage {
	enum Styles: StyleSet {
		case root
		case list
		case item
		case itemTitle
		case itemLink
		case externalItemLink
		case itemFooter
		case itemDescription
		case itemMeta
		case pagination
		case paginationLink

		var style: Style {
			switch self {
			case .root:
				Style()
					.frame(maxWidth: .rem(42))
					.margin(vertical: 0, horizontal: .auto)
					.padding(vertical: .rem(3), horizontal: .rem(1.5))
					.breakpoint(.sm) {
						$0.padding(vertical: .rem(4), horizontal: .rem(1.5))
					}
					.breakpoint(.lg) {
						$0.padding(vertical: .rem(5), horizontal: .rem(1.5))
					}
			case .item:
				Style()
					.frame(maxWidth: .rem(28))
					.margin(vertical: 0, horizontal: .auto)
					.breakpoint(.md) {
						$0.declaration(.maxWidth, .none)
					}
			case .itemTitle:
				Style()
					.margin(.bottom, .rem(0.5))
					.font(size: .rem(1.875), lineHeight: 1.375)
					.bold()
					.breakpoint(.sm) {
						$0.font(size: .rem(2.25))
					}
			case .itemLink:
				// A shadow instead of an underline, so the arrow of external links is not underlined.
				Style()
					.hover {
						$0
							.shadow(Shadow(y: .px(-4), color: .currentColor, isInset: true))
							.important {
								$0.noUnderline()
							}
					}
			case .externalItemLink:
				Style()
					.after {
						$0
							.content(" ⤤")
							.opacity(0.6)
					}
			case .itemFooter:
				Style().margin(.top, .rem(1))
			case .itemDescription:
				Style()
					.margin(.top, .rem(0.5))
					.font(.lg)
					.opacity(0.8)
					.breakpoint(.sm) {
						$0.font(.xl)
					}
			case .itemMeta:
				Style()
					.color(.gray(500), dark: .slate(400))
			case .pagination:
				Style()
					.display(.flex)
					.justifyContent(.spaceBetween)
			case .paginationLink:
				Style()
					.display(.inlineFlex)
					.alignItems(.center)
					.gap(.rem(0.5))
					.padding(vertical: .rem(0.75), horizontal: .rem(0.5))
					.fontWeight(.medium)
					.lineHeight(1.375)
					.color(.gray(600), dark: .gray(400))
					.transition(.color, duration: .milliseconds(200), curve: .easeIn)
					.nested("&:not([href])") {
						$0.visibility(false)
					}
					.hover {
						$0.color(.gray(900))
					}
					.dark {
						$0
							.hover {
								$0.color(.white)
							}
					}
			case .list:
				Style()
					.nested("& > li") {
						$0
							.margin(.bottom, .rem(2.5))
							.breakpoint(.md) {
								$0.margin(.bottom, .rem(4))
							}
					}
			}
		}
	}
}
