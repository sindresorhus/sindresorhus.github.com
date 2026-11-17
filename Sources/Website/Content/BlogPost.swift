import Foundation
import SiteKit
import SOML

/**
A blog post, loaded from `content/blog/<slug>.md`.
*/
struct BlogPost: ContentDocument {
	enum Tag: String, ContentEnum, Encodable {
		case programming
		case openSource = "open-source"
		case swift
		case javascript
		case nodejs
	}

	let markdown: MarkdownDocument
	let decodedFile: DecodedMarkdownFile<Frontmatter>

	/**
	Minutes to read at 200 words per minute, like the `reading-time` package.
	*/
	let readingTime: Int

	/**
	The reading time as a fact, like “4 min read”, for the top of the page and the social card.
	*/
	var readingTimeText: String {
		"\(readingTime) min read"
	}

	/**
	The root frontmatter order follows the declarations, with status first and related facts together. Missing properties stay absent.
	*/
	static var formattingKeys: [Frontmatter.CodingKeys] {
		Frontmatter.CodingKeys.allCases
	}

	static let directory: Project.ContentDirectory = "content/blog"

	// The slug is one component of the path of the page, so the file cannot be in a subdirectory.
	static let allowsSubdirectories = false

	init(file decodedFile: DecodedMarkdownFile<Frontmatter>, project: Project) throws {
		let file = decodedFile.source
		let frontmatter = decodedFile.frontmatter
		self.decodedFile = decodedFile

		// A post on another site has no page, so its text would not be shown anywhere.
		if
			frontmatter.redirectURL != nil,
			!file.body.allSatisfy(\.isWhitespace)
		{
			throw file.error(line: file.bodyStartLine, "A post with `redirectURL` has no page, so it cannot have text.")
		}

		// Each section has a link that copies its URL, like on app pages, so a reader can send a section of a long post.
		var options = MarkdownDocument.Options.content(file, project: project)
		options.addsHeadingAnchors = true
		self.markdown = try MarkdownDocument(parsing: file, options: options)

		if let error = markdown.titleHeadingError(in: file) {
			throw error
		}

		self.readingTime = Int((Double(file.body.split(whereSeparator: \.isWhitespace).count) / 200).rounded(.up))
	}

	static let pageRoute = RoutePath.blog

	/**
	Whether the post is on another site, like a redirect to an article on Medium.
	*/
	var isExternal: Bool {
		frontmatter.redirectURL.map { $0.value.host() != Site.url.host() } ?? false
	}
}

extension BlogPost {
	@Frontmatter
	struct Frontmatter: PublishedFrontmatter {
		@TrueOrAbsent var isDraft = false
		@TrueOrAbsent var isUnlisted = false
		@PlainText var title: String
		@Snippet var description: String?

		/**
		The calendar date when the post was published.
		*/
		var publicationDate: SOML.Date
		static let publicationDateKey = CodingKeys.publicationDate

		var tags = [Tag]()

		/**
		Makes the post link to an article elsewhere instead of having a page.
		*/
		var redirectURL: AbsoluteURL?

		/**
		Old paths of the post, like `/blog/old-name`. They redirect to the post.
		*/
		var redirectFrom = [RoutePath]()
		static let redirectFromKey = CodingKeys.redirectFrom

		var proseTexts: [ProseText] {
			[
				(title, [CodingKeys.title]),
				(description, [CodingKeys.description]),
			]
		}

		func validate(into problems: inout FrontmatterProblems<Self>) {
			validatePublicationDate(into: &problems)
		}
	}
}
