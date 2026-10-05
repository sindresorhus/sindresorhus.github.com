import Foundation
import SiteKit

/**
A standalone Markdown page, like `/about` or `/apps/faq`, loaded from `content/pages/<path>.md`.
*/
struct MarkdownPage: ContentDocument {
	let frontmatter: Frontmatter
	let markdown: MarkdownDocument
	let file: MarkdownFile

	static let directory = "content/pages"

	static let sortOrder = [KeyPathComparator(\MarkdownPage.path.description)]

	/**
	The line that places the sponsors of `sponsorTiers` in the Markdown.
	*/
	static var sponsorsDirective: Regex<Substring> {
		/(?m)^@Sponsors[ \t]*$/
	}

	init(file: MarkdownFile, frontmatter: Frontmatter, project: Project) throws {
		// The sponsors are only shown where the Markdown places them, so without the directive they would be silently missing.
		guard frontmatter.sponsorTiers.isEmpty || file.body.contains(Self.sponsorsDirective) else {
			throw ContentError(file: file.url, line: file.line(ofFrontmatterKey: "sponsorTiers"), reason: "The page has `sponsorTiers`, so the Markdown needs a `@Sponsors` line where the sponsors are shown.")
		}

		// Only the now page shows them, so on another page they would be silently missing.
		let nowKeys = [("status", frontmatter.status != nil), ("reading", !frontmatter.reading.isEmpty), ("listening", !frontmatter.listening.isEmpty)]

		for (key, isSet) in nowKeys where isSet && Self.path(slug: file.slug) != .now {
			throw ContentError(file: file.url, line: file.line(ofFrontmatterKey: key), reason: "Only `content/pages/now.md` can have `\(key)`.")
		}

		self.frontmatter = frontmatter
		self.file = file
		self.markdown = try MarkdownDocument(parsing: file, options: Self.path(slug: file.slug) == .faq ? .faqPage(file, project: project) : .content(file, project: project, sponsorTiers: frontmatter.sponsorTiers))
	}

	static func path(slug: String) -> RoutePath {
		RoutePath("/\(slug)")
	}

	var redirectFrom: [RoutePath] {
		frontmatter.redirectFrom
	}

	var title: String {
		frontmatter.title
	}

	var description: String? {
		frontmatter.description
	}
}

extension MarkdownPage {
	@Frontmatter
	struct Frontmatter {
		@NonEmpty var title: String
		@NonEmpty var description: String?

		/**
		A round photo next to the title on larger screens, like a portrait.
		*/
		var photo: LinkDestination?

		/**
		Old paths of the page, like `/thanks`. They redirect to the page.
		*/
		var redirectFrom = [RoutePath]()

		/**
		The sponsors, by tier, for the supporters page. The Markdown places them with `@Sponsors`.
		*/
		var sponsorTiers = [SponsorTier]()

		/**
		What Sindre is up to, in one line, for the now page.
		*/
		@NonEmpty var status: String?

		/**
		What Sindre is reading, one line each, for the now page.
		*/
		var reading = [NonEmptyString]()

		/**
		What Sindre is listening to, one line each, for the now page.
		*/
		var listening = [NonEmptyString]()

		func validate() throws(ContentError) {
			for sponsor in sponsorTiers.flatMap(\.sponsors) where sponsor.logo != nil {
				guard sponsor.logoWidth != nil else {
					throw ContentError(reason: "The logo of “\(sponsor.name)” needs `logoWidth`.")
				}

				// A tier with logos is a list of links.
				guard sponsor.url != nil else {
					throw ContentError(reason: "The sponsor “\(sponsor.name)” has a logo, so it needs `url`.")
				}
			}
		}
	}

	/**
	A level of sponsorship, like “Silver sponsor”, with its sponsors.
	*/
	@Frontmatter
	struct SponsorTier {
		@NonEmpty var title: String

		/**
		Like `$100/month`.
		*/
		@NonEmpty var price: String

		var sponsors: [Sponsor]
	}

	@Frontmatter
	struct Sponsor {
		@NonEmpty var name: String
		@Absolute var url: URL?

		/**
		The logo, made for a light background, which it is shown on in both modes. Without a logo, the name is shown.
		*/
		var logo: RoutePath?

		/**
		The width of the logo, in pixels. A logo needs it.
		*/
		var logoWidth: Int?

		/**
		Shows the name next to the logo, for a logo without the name in it.
		*/
		var showsName: Bool = false
	}
}
