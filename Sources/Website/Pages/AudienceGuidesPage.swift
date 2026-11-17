import Elementary
import Foundation
import SiteKit

/**
The guides for one audience (``Guide/Audience``), like the guides for people who come from Windows, the settings that most people change on a new Mac, or the built-in keyboard shortcuts: the guides with the key of the audience in their frontmatter, like `isForWindowsUsers: true` or a `shortcut`, in one list, with the rows of the list of guides (``GuideList``), or only in the table above it, when the table has a row for each guide, like the shortcuts (``Guide/Audience/tableHasEachGuide``). The guides stay in their topics on ``GuidesPage``, which links to this page.

The site only has the page when a guide is for it (``Site/specialPages``).
*/
struct AudienceGuidesPage: Page {
	let audience: Guide.Audience
	let content: SiteContent

	var path: RoutePath {
		audience.path
	}

	private var guides: [Guide.Resolved] {
		content.guides(for: audience)
	}

	/**
	The Markdown of the table above the guides (``Guide/Audience/introTable(guides:)``), or `nil` for none.
	*/
	var introTableMarkdown: String? {
		audience.introTable(guides: guides)
	}

	/**
	The table above the guides, with the tags and the links of the guides by their slugs, like `<guide:cut-and-paste-files-mac>`, which go to the pages of the guides (``guidePath(ofLink:)``). The table is Markdown of code, so it has no file to resolve its links, and a link to a guide that is not published is a problem of the document, which a test checks.
	*/
	var introTable: MarkdownDocument? {
		introTableMarkdown.map { markdown in
			var options = MarkdownDocument.Options.site
			options.linkTags = .site(project: content.project)
			options.resolveLink = { [self] (destination: String) throws(ContentError) in
				guard LinkTagScheme.split(destination)?.scheme == .guide else {
					return destination
				}

				guard let path = guidePath(ofLink: destination) else {
					throw ContentError(reason: "The link `\(destination)` goes to a guide that is not published.")
				}

				// With the fragment of the link, like `#steps`.
				return "\(path)\(destination.drop { $0 != "#" })"
			}

			return MarkdownDocument(parsing: markdown, options: options)
		}
	}

	/**
	The page of the published guide that a link by its slug goes to, like `/guides/cut-and-paste-files-mac` for `guide:cut-and-paste-files-mac#steps` (``LinkTagScheme/guide``), without the fragment, or `nil` for another link and for a slug that is not a published guide.
	*/
	func guidePath(ofLink destination: String) -> RoutePath? {
		guard
			let tag = LinkTagScheme.split(destination),
			tag.scheme == .guide
		else {
			return nil
		}

		let slug = tag.target.prefix { $0 != "#" }
		return content.guides.first { $0.guide.slug.value == slug }?.guide.path
	}

	var sitemapEntry: SitemapEntry {
		guides.map(\.guide).listSitemapEntry
	}

	var metadata: PageMetadata {
		PageMetadata(
			title: audience.title,
			description: audience.intro,
			feeds: [SiteFeed.newGuides.link]
		)
	}

	/**
	The list of guides, as the page is a part of it, like a category page is a part of the apps (``AppCategoryPage``).
	*/
	var parents: [LabeledLink] {
		[.guides]
	}

	/**
	The icons of the apps with the most guides on the page, and the introduction of the page.
	*/
	var socialImage: SocialImage {
		.card(OpenGraphCard(page: self, artwork: .icons(ofMostCommon: guides.map(\.app), project: content.project)))
	}

	var body: some HTML {
		// A page without the list of guides has only the table, so it is in the column of prose, like a guide.
		GuideListPage(title: audience.title, intro: audience.intro, isWide: !audience.tableHasEachGuide) {
			if let introTable {
				// At the start of the column, like the title and the guides, not in the centered column of prose with its own space at the sides.
				Prose(markdown: introTable.content)
					.style {
						let style = $0
							.margin(.horizontal, .zero)
							.padding(.horizontal, .zero)
							.from(.tablet) {
								$0.margin(.top, .rootEm(5))
							}

						// In the column of prose, the table hangs into the space at its sides, like the tables of the guides.
						guard !audience.tableHasEachGuide else {
							return style
						}

						// The wide column has no space at its sides for the table to hang into (``Style/widerThanProse()``), so its edges line up with the title and the guides.
						return style.from(.proseWithGutters) {
							$0.nested(ProseStyles.tableContainer.selector) {
								$0.margin(.horizontal, .zero)
							}
						}
					}
			}

			// The first rows are in view when the page opens, unless a table is above them. A table with a row for each guide, like the shortcuts, is the list.
			if !audience.tableHasEachGuide {
				GuideList(guides: guides, headingLevel: .h2, isAboveFold: introTableMarkdown == nil)
					// From tablets, the space below the introduction is larger than the space between the guides, like on the blog index.
					.style {
						$0.from(.tablet) {
							$0.margin(.top, .rootEm(5))
						}
					}
			}

			// The next page for the same visitor (``Guide/Audience/next``), like the links at the end of a guide, when that page has guides.
			if
				let next = audience.next,
				content.audiencesWithGuides.contains(next)
			{
				p {
					a(.href(.path(next.path))) {
						next.title
					}
					.style {
						$0.guideEndLink()
					}
				}
				.style {
					$0
						.margin(top: .rootEm(4), horizontal: .zero, bottom: .zero)
						.textStyle(.body)
						.hstack(justification: .center)
				}
			}
		}
	}
}
