import Foundation
import SiteKit

/**
A blog post, loaded from `content/blog/<slug>.md`.
*/
@dynamicMemberLookup
struct BlogPost: ContentDocument {
	enum Tag: String, Codable, Sendable {
		case programming
		case openSource = "open-source"
		case swift
		case javascript
		case nodejs
	}

	let frontmatter: Frontmatter
	let markdown: MarkdownDocument
	let file: MarkdownFile

	/**
	Minutes to read at 200 words per minute, like the `reading-time` package.
	*/
	let readingTime: Int

	static let directory = "content/blog"

	// The slug is one component of the path of the page, so the file cannot be in a subdirectory.
	static let allowsSubdirectories = false

	static let sortOrder = [KeyPathComparator(\BlogPost.frontmatter.publicationDate, order: .reverse)]

	init(file: MarkdownFile, frontmatter: Frontmatter, project: Project) throws {
		self.frontmatter = frontmatter
		self.file = file

		// A post on another site has no page, so its text would not be shown anywhere.
		if
			frontmatter.redirectURL != nil,
			!file.body.allSatisfy(\.isWhitespace)
		{
			throw ContentError(file: file.url, line: file.bodyStartLine, reason: "A post with `redirectURL` has no page, so it cannot have text.")
		}

		self.markdown = try MarkdownDocument(parsing: file, options: .content(file, project: project))
		self.readingTime = Int((Double(file.body.split(whereSeparator: \.isWhitespace).count) / 200).rounded(.up))
	}

	var isDraft: Bool {
		frontmatter.isDraft
	}

	subscript<Value>(dynamicMember keyPath: KeyPath<Frontmatter, Value>) -> Value {
		frontmatter[keyPath: keyPath]
	}

	/**
	When the post was published, at midnight UTC.
	*/
	var publicationDate: Date {
		frontmatter.publicationDate
	}

	var title: String {
		frontmatter.title
	}

	/**
	When the post last changed: the last commit of the content file, but never before the post was published.
	*/
	var lastModified: Date {
		max(lastCommitDate ?? publicationDate, publicationDate)
	}

	var description: String? {
		frontmatter.description
	}

	static func path(slug: String) -> RoutePath {
		RoutePath.blog.appending(slug)
	}

	var redirectURL: URL? {
		frontmatter.redirectURL
	}

	var redirectFrom: [RoutePath] {
		frontmatter.redirectFrom
	}

	/**
	Whether the post is shown in the blog, the feeds, and the sitemap. An unlisted post still has its page.
	*/
	var isListed: Bool {
		!frontmatter.isUnlisted
	}

	/**
	Whether the post is on another site, like a redirect to an article on Medium.
	*/
	var isExternal: Bool {
		frontmatter.redirectURL.map { $0.host() != Site.url.host() } ?? false
	}
}

extension BlogPost {
	@Frontmatter
	struct Frontmatter {
		var isDraft = false
		var isUnlisted = false
		@NonEmpty var title: String
		@NonEmpty var description: String?
		@CalendarDay var publicationDate: Date
		var tags = [Tag]()

		/**
		Makes the post link to an article elsewhere instead of having a page.
		*/
		@Absolute var redirectURL: URL?

		/**
		Old paths of the post, like `/blog/old-name`. They redirect to the post.
		*/
		var redirectFrom = [RoutePath]()
	}
}
