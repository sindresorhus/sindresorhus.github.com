import Foundation
import SiteKit
import SOML

/**
A standalone Markdown page, like `/about` or `/apps/faq`, loaded from `content/pages/<path>.md`.
*/
struct MarkdownPage: ContentDocument {
	let markdown: MarkdownDocument
	let decodedFile: DecodedMarkdownFile<Frontmatter>
	let sponsorTiers: [SponsorTier.Resolved]

	/**
	The `status` of the now page, which is inline Markdown, so it can have links, like the text of the page.
	*/
	let status: MarkdownDocument?

	static let directory: Project.ContentDirectory = "content/pages"

	static let sortOrder = [KeyPathComparator(\MarkdownPage.path.description)]

	/**
	Standalone pages have no draft frontmatter.
	*/
	var isDraft: Bool {
		false
	}

	init(file decodedFile: DecodedMarkdownFile<Frontmatter>, project: Project) throws {
		try self.init(file: decodedFile, project: project, today: nil)
	}

	/**
	- Parameter today: The day of the build, which decides what `@Scheduled` shows. Without it, like in a test, `@Scheduled` is an unknown directive. The FAQ page cannot have it, as the feedback page would suggest a question that the page does not show.
	*/
	init(file decodedFile: DecodedMarkdownFile<Frontmatter>, project: Project, today: SOML.Date?) throws {
		let file = decodedFile.source
		let frontmatter = decodedFile.frontmatter
		// Only the now page shows them, so on another page they would be silently missing.
		let nowKeys: [(key: Frontmatter.CodingKeys, isSet: Bool)] = [(.status, frontmatter.status != nil), (.reading, !frontmatter.reading.isEmpty), (.listening, !frontmatter.listening.isEmpty)]

		let kind = Kind(path: Self.path(slug: file.slug))

		for (key, isSet) in nowKeys where isSet && kind != .now {
			throw decodedFile.error(at: key, "Only `content/pages/now.md` can have `\(key.stringValue)`.")
		}

		self.decodedFile = decodedFile

		do throws(ContentError) {
			self.sponsorTiers = try frontmatter.sponsorTiers.map { (tier: SponsorTier) throws(ContentError) in
				try tier.resolved
			}
		} catch {
			throw decodedFile.error(at: .sponsorTiers, error.reason)
		}

		self.status = try frontmatter.status.map { try MarkdownDocument(parsing: $0, at: .status, of: decodedFile, project: project) }
		self.markdown = try MarkdownDocument(parsing: file, options: kind == .faq ? .faqPage(file, project: project) : .content(
			file,
			project: project,
			sponsorTiers: sponsorTiers,
			today: today
		))

		// The feedback page suggests the general questions, so the directives of another heading would silently do nothing.
		if kind == .faq {
			let errors = markdown.headings.compactMap { heading -> ContentError? in
				guard
					!heading.contains(FAQDirectives.General.self),
					heading.hasFAQDirective
				else {
					return nil
				}

				return file.error(line: heading.line, "The feedback page suggests only the questions with `<!-- @\(FAQDirectives.General.name) -->`, so the directives of “\(heading.text)”, like `@\(FAQDirectives.Keywords.name)`, do nothing. Add it, or remove them.")
			}

			guard errors.isEmpty else {
				throw ContentErrors(errors)
			}
		}

		// The page is split before the headings, so with a renamed ID, its parts would silently be at the end.
		if
			!kind.requiredHeadingIDs.isEmpty,
			markdown.contentSeparated(beforeHeadings: kind.requiredHeadingIDs) == nil
		{
			throw file.error(line: file.bodyStartLine, "The page needs level 2 headings with the IDs \(kind.requiredHeadingIDs.map { "`\($0)`" }.formattedList(.and)), in this order and not inside a block directive, as the page shows other parts before them, like `## Some Things About Me {#\(AboutPage.nowNextHeadingID)}`.")
		}

		// The sponsors are only shown where the Markdown places them, so without the directive they would be silently missing. The rendered blocks are checked, not the text, so a `@Sponsors` in a code block or a comment does not count.
		guard
			frontmatter.sponsorTiers.isEmpty
				|| markdown.blocks.contains(where: { $0.siteDirectiveName == .sponsors })
		else {
			throw decodedFile.error(at: .sponsorTiers, "The page has `sponsorTiers`, so the Markdown needs a `@Sponsors` line where the sponsors are shown.")
		}
	}

	/**
	How the site shows the page, by its path.
	*/
	var kind: Kind {
		Kind(path: path)
	}

	/**
	The metadata of a page that shows the document: its title and description.
	*/
	var metadata: PageMetadata {
		PageMetadata(title: frontmatter.title, description: frontmatter.description)
	}

	/**
	The sitemap entry of a page that shows the document, which changes when the content file does.
	*/
	var sitemapEntry: SitemapEntry {
		SitemapEntry(lastModified: lastCommitDate.map(SOML.Date.init))
	}
}

extension MarkdownPage {
	/**
	The pages that the site shows in their own way, so the page and what it needs have one owner, not a compare of paths in each place.
	*/
	enum Kind {
		/**
		The about page (``AboutPage``), which shows the numbers and the projects between its sections.
		*/
		case about

		/**
		The now page (``NowPage``), the only page with `status`, `reading`, and `listening`.
		*/
		case now

		/**
		The general FAQ (``RoutePath/faq``), with collapsible questions, which the feedback page suggests.
		*/
		case faq

		case standard

		init(path: RoutePath) {
			self = switch path {
			case .about:
				.about
			case .now:
				.now
			case .faq:
				.faq
			default:
				.standard
			}
		}

		/**
		The IDs of the level 2 headings that the page is split before, in their order, which the page must have.
		*/
		var requiredHeadingIDs: [ElementID] {
			self == .about ? AboutPage.splitHeadingIDs : []
		}
	}
}

extension MarkdownPage {
	@Frontmatter
	struct Frontmatter: DocumentFrontmatter {
		@PlainText var title: String
		@Snippet var description: String?

		/**
		A round photo next to the title on larger screens, like a portrait.
		*/
		var photo: ImageSource?

		/**
		Old paths of the page, like `/thanks`. They redirect to the page.
		*/
		var redirectFrom = [RoutePath]()
		static let redirectFromKey = CodingKeys.redirectFrom

		/**
		The sponsors, by tier, for the supporters page. The Markdown places them with `@Sponsors`.
		*/
		var sponsorTiers = [SponsorTier]()

		/**
		What Sindre is up to, in one line of inline Markdown, for the now page, which shows its links, and for the about page, which shows its text in a card that links to the now page.
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

		func validate(into problems: inout FrontmatterProblems<Self>) {
			problems.validate(sponsorTiers, at: .sponsorTiers)
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

		/**
		A logo tier has a destination for every sponsor; a text tier allows unlinked names.
		*/
		enum Presentation: Sendable {
			case logos([Sponsor.Linked])
			case text([Sponsor])
		}

		/**
		The tier's heading and complete presentation, resolved at the content-loading boundary.
		*/
		struct Resolved: Sendable {
			let title: String
			let price: String
			let presentation: Presentation
		}

		/**
		Whether this tier uses the shared logo-grid presentation.
		*/
		private var hasLogos: Bool {
			sponsors.contains { $0.logo != nil }
		}

		/**
		Resolves the presentation before rendering so a logo-grid entry always has a link.
		*/
		var resolved: Resolved {
			get throws(ContentError) {
				let presentation: Presentation

				if hasLogos {
					presentation = .logos(try sponsors.map { (sponsor: Sponsor) throws(ContentError) in
						try sponsor.linked
					})
				} else {
					presentation = .text(sponsors)
				}

				return Resolved(title: title, price: price, presentation: presentation)
			}
		}

		func validate(into problems: inout FrontmatterProblems<Self>) {
			// A tier with logos is a list of links, also to the sponsors without a logo.
			guard hasLogos else {
				return
			}

			for (index, sponsor) in sponsors.enumerated() {
				do {
					_ = try sponsor.linked
				} catch {
					problems.add(error.reason, at: .sponsors, index: index)
				}
			}
		}
	}

	@Frontmatter
	struct Sponsor {
		@NonEmpty var name: String
		var url: AbsoluteURL?

		/**
		The logo, made for a light background, which it is shown on in both modes. Without a logo, the name is shown.
		*/
		var logo: Logo?

		/**
		Shows the name next to the logo, for a logo without the name in it.
		*/
		var showsName = false

		/**
		A sponsor with the required destination for the logo grid.
		*/
		struct Linked: Sendable {
			let sponsor: Sponsor
			let url: AbsoluteURL
		}

		/**
		Checks the one link requirement shared by validation and presentation resolution.
		*/
		var linked: Linked {
			get throws(ContentError) {
				guard let url else {
					throw ContentError(reason: "The sponsor “\(name)” is in a tier with logos, which is a list of links, so it needs `url`.")
				}

				return Linked(sponsor: self, url: url)
			}
		}
	}

	/**
	The logo of a sponsor, with its size, which a logo needs, so the layout does not move while it loads, and the logos can have about the same area (``relativeHeight``).
	*/
	@Frontmatter
	struct Logo {
		var path: RoutePath

		/**
		The width, in pixels, at the aspect ratio of the image.
		*/
		var width: Pixels

		/**
		The height, in pixels, at the aspect ratio of the image.
		*/
		var height: Pixels

		/**
		A positive image size in pixels, checked when it enters the model.
		*/
		struct Pixels: PlainValidatedValue, Sendable {
			let value: Int

			init(validating value: Int) throws(ContentError) {
				guard value > 0 else {
					throw ContentError(reason: "The size of a logo must be a positive number of pixels, got \(value).")
				}

				self.value = value
			}
		}

		/**
		The height of the logo in its box, from 0 to 1, so the logos have about the same area, and a wide logo does not look much larger than a square one. A logo up to twice as wide as it is high fills the height, and a wider one is lower, like a logo four times as wide as it is high at 71%.
		*/
		var relativeHeight: Double {
			let aspectRatio = Double(width.value) / Double(height.value)
			return min(1, (2 / aspectRatio).squareRoot())
		}
	}
}
