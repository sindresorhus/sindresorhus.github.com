import Foundation
import SiteKit

/**
A blog post, loaded from `content/blog/<slug>.md`.
*/
@dynamicMemberLookup
public struct BlogPost: ContentEntry {
	public enum Tag: String, Codable, Sendable {
		case programming
		case openSource = "open-source"
		case swift
		case javascript
		case nodejs
	}

	public let slug: String
	public let frontmatter: Frontmatter
	public let markdown: MarkdownDocument

	/**
	When a commit last changed the content file.
	*/
	public let lastCommitDate: Date?

	/**
	The content file, for reporting mistakes at their line.
	*/
	public let file: MarkdownFile

	/**
	Minutes to read at 200 words per minute, like the `reading-time` package.
	*/
	public let readingTime: Int

	public static let directory = "content/blog"

	public static let sortOrder = [KeyPathComparator(\BlogPost.frontmatter.publicationDate, order: .reverse)]

	public init(file: MarkdownFile, frontmatter: Frontmatter, project: Project) throws {
		self.slug = file.slug
		self.frontmatter = frontmatter
		self.lastCommitDate = file.lastCommitDate
		self.file = file

		// A post on another site has no page, so its text would not be shown anywhere.
		if
			frontmatter.redirectURL != nil,
			!file.body.allSatisfy(\.isWhitespace)
		{
			throw FrontmatterError("A post with `redirectUrl` has no page, so it cannot have text.")
		}

		self.markdown = MarkdownDocument(parsing: file.body, options: .content(file, project: project))
		try file.validate(markdown)
		self.readingTime = Int((Double(file.body.split(whereSeparator: \.isWhitespace).count) / 200).rounded(.up))
	}

	public var isDraft: Bool {
		frontmatter.isDraft
	}

	public subscript<Value>(dynamicMember keyPath: KeyPath<Frontmatter, Value>) -> Value {
		frontmatter[keyPath: keyPath]
	}

	public var title: String {
		frontmatter.title.value
	}

	public var description: String? {
		frontmatter.description?.value
	}

	public var path: RoutePath {
		RoutePath.blog.appending(slug)
	}

	/**
	Where links to the post go: the post page, or the external page of a redirect post.
	*/
	public var url: String {
		frontmatter.redirectURL?.absoluteString ?? path.description
	}

	public var isRedirect: Bool {
		frontmatter.redirectURL != nil
	}

	/**
	The absolute URL of the post page, or of the external page of a redirect post.
	*/
	public var absoluteURL: URL {
		frontmatter.redirectURL?.url ?? path.absoluteURL(site: Site.url)
	}

	/**
	Whether the post is on another site, like a redirect to an article on Medium.
	*/
	public var isExternal: Bool {
		frontmatter.redirectURL.map { $0.url.host() != Site.url.host() } ?? false
	}
}

extension BlogPost {
	@Frontmatter
	public struct Frontmatter {
		@Key("draft")
		public var isDraft: Bool = false
		public var isUnlisted: Bool = false
		public var title: NonEmptyString
		public var description: NonEmptyString?
		@Key("pubDate")
		public var publicationDate: Date
		public var tags = [Tag]()

		/**
		Makes the post link to an article elsewhere instead of having a page.
		*/
		@Key("redirectUrl")
		public var redirectURL: AbsoluteURL?
	}
}
