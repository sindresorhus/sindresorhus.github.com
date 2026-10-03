import Foundation
import SiteKit

/**
A standalone Markdown page, like `/about` or `/apps/faq`, loaded from `content/pages/<path>.md`.
*/
public struct MarkdownPage: ContentEntry {
	public let path: RoutePath
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

	public static let directory = "content/pages"

	public static let sortOrder = [KeyPathComparator(\MarkdownPage.path.description)]

	/**
	The general FAQ for the apps.
	*/
	public static let faqPath: RoutePath = "/apps/faq"

	public init(file: MarkdownFile, frontmatter: Frontmatter, project: Project) throws {
		self.path = RoutePath("/\(file.slug)")
		self.frontmatter = frontmatter
		self.lastCommitDate = file.lastCommitDate
		self.file = file
		self.markdown = MarkdownDocument(parsing: file.body, options: path == Self.faqPath ? .faqPage(file, project: project) : .content(file, project: project))
		try file.validate(markdown)
		try markdown.checkPlatformDirectives()
	}
}

extension MarkdownPage {
	@Frontmatter
	public struct Frontmatter {
		public var title: NonEmptyString
		public var description: NonEmptyString?

		/**
		Old paths of the page, like `/thanks`. They redirect to the page.
		*/
		public var redirectFrom = [RoutePath]()
	}
}
