import Foundation
import Markdown
import SiteKit
import SOML

/**
A short how-to for a task, like “How to Convert a Video to a GIF on Mac”, loaded from `content/guides/<slug>.md`. It names the app for the task and the built-in way. The guides are not posts, so they are not in the blog or its feed.
*/
struct Guide: ContentDocument {
	let frontmatter: Frontmatter
	let markdown: MarkdownDocument
	let file: MarkdownFile

	static let directory = "content/guides"

	// The slug is one component of the path of the page, so the file cannot be in a subdirectory.
	static let allowsSubdirectories = false

	static let sortOrder = [KeyPathComparator(\Guide.frontmatter.title, comparator: .localizedStandard)]

	static let pageRoute = RoutePath.guides

	init(file: MarkdownFile, frontmatter: Frontmatter, project: Project) throws {
		self.frontmatter = frontmatter
		self.file = file
		self.markdown = try MarkdownDocument(parsing: file, options: .content(file, project: project))

		// A draft is not published, so it can be written in any order, but its frontmatter is still checked.
		let errors = frontmatter.isDraft ? [] : shapeErrors()

		guard errors.isEmpty else {
			throw ContentErrors(errors)
		}
	}

	/**
	The mistakes in the shape that every guide has: it starts with the short answer (`@QuickAnswer`), it has the steps (`@Steps`), and it has an honest “Without an app” section (a level 2 heading) with text, so the app box that the page shows before it does not stand alone. The text has no level 1 heading, as the page shows the title as one. The link of the short answer to the first app is checked when the apps are loaded (``quickAnswerLinkError(to:)``).
	*/
	private func shapeErrors() -> [ContentError] {
		var errors = [ContentError]()

		if quickAnswerLines == nil {
			errors.append(file.error(line: file.bodyStartLine, "A guide starts with the short answer: `@QuickAnswer { … }`."))
		}

		if !markdown.blocks.contains(where: { $0.siteDirectiveName == .steps }) {
			errors.append(file.error(line: file.bodyStartLine, "A guide needs the steps of the task: `@Steps { 1. … }`."))
		}

		if let error = markdown.titleHeadingError(in: file) {
			errors.append(error)
		}

		if let heading = markdown.headings.first(where: { $0.level == .h2 && $0.text == Self.withoutAppTitle }) {
			// The blocks of the section, with its subsections, until the next section. A heading is not text, and HTML, like a comment, is a note for the author.
			let sectionBlocks = markdown.blocks.firstIndex { $0.kind == .heading(level: heading.level, id: heading.id) }.map { index in
				markdown.blocks.contentOfSection(afterHeadingAt: index, level: heading.level) { $0.headingLevel }
			} ?? []

			let hasText = sectionBlocks.contains { block in
				switch block.kind {
				case .heading:
					false
				// A comment renders as nothing, but other raw HTML, like a table, is text.
				case .html:
					!block.isEmpty
				default:
					true
				}
			}

			if !hasText {
				errors.append(file.error(line: heading.line, "The section “\(Self.withoutAppTitle)” is empty. Write the built-in way below its heading."))
			}
		} else {
			errors.append(file.error(line: file.bodyStartLine, "A guide needs the built-in way, in a section with the heading `## \(Self.withoutAppTitle)`."))
		}

		return errors
	}

	/**
	The lines of the short answer (`@QuickAnswer`), which is the first block. HTML blocks, like comments, which are notes for the author, can come before it. `nil` when the guide does not start with it.
	*/
	private var quickAnswerLines: ClosedRange<Int>? {
		guard
			let quickAnswer = markdown.blocks.first(where: { $0.kind != .html }),
			quickAnswer.siteDirectiveName == .quickAnswer,
			case .directive(_, let lines?) = quickAnswer.kind
		else {
			return nil
		}

		return lines
	}

	/**
	The short answer (`@QuickAnswer`) must link to the first app of `apps`, which the page names. The loader checks it with the loaded apps (``SiteContent``), so it is checked only for an app that exists, as the message would else ask to change a link that can be right.
	*/
	func quickAnswerLinkError(to app: App) -> ContentError? {
		guard
			!frontmatter.isDraft,
			let lines = quickAnswerLines,
			!markdown.links.contains(where: { link in
				guard
					link.otherFile == nil,
					lines.contains(link.line ?? 0),
					case .path(let path, _, _) = try? LinkDestination(validating: link.destination)
				else {
					return false
				}

				return path == app.path
			})
		else {
			return nil
		}

		return file.error(line: lines.lowerBound, "The `@QuickAnswer` must link to `\(app.slug)`, the first app of `apps`: `[…](../apps/\(app.slug)/index.md)`.")
	}

	/**
	The heading of the section with the built-in way, which every guide has.
	*/
	static let withoutAppTitle = "Without an app"

	/**
	The ID of the heading of the section with the built-in way (``withoutAppTitle``), so the page can show the app before it. Every guide has it (``shapeErrors``).
	*/
	var withoutAppHeadingID: ElementID? {
		markdown.headings.first { $0.level == .h2 && $0.text == Self.withoutAppTitle }?.id
	}
}

extension Guide {
	@Frontmatter
	struct Frontmatter: PublishedFrontmatter {
		/**
		A draft is not published, and neither are the files of its page bundle.
		*/
		var isDraft = false

		@PlainText var title: String

		/**
		The short answer, for the list of guides and search results.
		*/
		@Snippet var description: String

		/**
		The calendar date when the guide was published.
		*/
		var publicationDate: SOML.Date
		static let publicationDateKey = CodingKeys.publicationDate

		/**
		The slugs of the apps that the guide is about, like `gifski`. The first one is the app that the page links back to.
		*/
		var apps: [String]

		/**
		The topic of the guide, like `menu-bar`, which groups it on the list of guides.
		*/
		var topic: Topic

		/**
		Old paths of the guide, like `/guides/old-name`. They redirect to the guide.
		*/
		var redirectFrom = [RoutePath]()
		static let redirectFromKey = CodingKeys.redirectFrom

		/**
		The screenshot of the first app that shows the result, like the date in the menu bar, which the page shows after the steps of the app.
		*/
		var screenshot: Screenshot?

		func validate(into problems: inout FrontmatterProblems<Self>) {
			// The page shows its date next to the link back to the first app, so without an app it would have no date.
			if apps.isEmpty {
				problems.add("A guide needs `apps`, the slugs of the apps that it is about, like `apps: ['gifski']`.", at: .apps)
			}

			problems.addRepeatedItems(of: apps, at: .apps)
			problems.validate(screenshot, at: .screenshot)
			validatePublicationDate(into: &problems)
		}
	}

	/**
	The topic of a guide, which groups it on the list of guides (``GuidesPage``), in the order of the cases. The raw value is the value in the frontmatter, like `topic: 'menu-bar'`, and the ID of its section. A fixed list, unlike free tags, so the topics stay few.
	*/
	enum Topic: String, ContentEnum {
		case menuBar = "menu-bar"
		case finderAndDesktop = "finder-and-desktop"
		case keyboardAndTrackpad = "keyboard-and-trackpad"
		case textImagesAndSound = "text-images-and-sound"
		case browsersLinksAndEmail = "browsers-links-and-email"
		case iPhone = "iphone"
		case mac

		var title: String {
			switch self {
			case .menuBar:
				"Menu Bar"
			case .finderAndDesktop:
				"Finder and Desktop"
			case .keyboardAndTrackpad:
				"Keyboard and Trackpad"
			case .textImagesAndSound:
				"Text, Images, and Sound"
			case .browsersLinksAndEmail:
				"Browsers, Links, and Email"
			case .iPhone:
				"iPhone"
			case .mac:
				"More for the Mac"
			}
		}
	}

	/**
	A screenshot of the first app of a guide, like `screenshot: {number: 1, description: 'The date and the week number in the menu bar'}`.
	*/
	@Frontmatter
	struct Screenshot {
		/**
		The number of the screenshot of the app, like `1` for `screenshot1.png`, counted like on the app page: in natural order, without the videos.
		*/
		var number: Int

		/**
		What the screenshot shows, for screen readers (the `alt` text).
		*/
		@PlainText var description: String

		func validate(into problems: inout FrontmatterProblems<Self>) {
			if number < 1 {
				problems.add("`screenshot.number` starts at 1, like `1` for the first screenshot of the app, got \(number).", at: .number)
			}
		}
	}

	/**
	The screenshot of the frontmatter (`screenshot`), from the screenshots of the first app of the guide. `nil` when the guide has none, or the app has no screenshot with that number, which the loader reports (``SiteContent``).
	*/
	func screenshot(of app: App) -> ScreenshotAsset? {
		guard let number = frontmatter.screenshot?.number else {
			return nil
		}

		let screenshots = app.screenshots

		guard screenshots.indices.contains(number - 1) else {
			return nil
		}

		return screenshots[number - 1]
	}
}

extension Guide {
	/**
	A guide with its app references and screenshot resolved at the content-loading boundary. Pages only accept this complete value.
	*/
	struct Resolved {
		let guide: Guide
		let app: App
		let apps: [App]

		/**
		The content around the required built-in section, resolved once before a page can render it.
		*/
		let parts: (before: MarkdownContent, after: MarkdownContent)

		let screenshot: (asset: ScreenshotAsset, description: String)?

		/**
		Resolves the required first app and optional screenshot. The loader reports reference mistakes before constructing the published content.
		*/
		init?(guide: Guide, apps: [App]) {
			// Preserve every resolved association in authored order, including secondary apps.
			guard
				apps.map(\.slug) == guide.apps,
				let app = apps.first,
				let headingID = guide.withoutAppHeadingID,
				let parts = guide.markdown.contentSeparated(beforeHeading: headingID)
			else {
				return nil
			}

			self.guide = guide
			self.app = app
			self.apps = apps
			self.parts = parts

			if let screenshot = guide.frontmatter.screenshot {
				guard let asset = guide.screenshot(of: app) else {
					return nil
				}

				self.screenshot = (asset, screenshot.description)
			} else {
				self.screenshot = nil
			}
		}
	}
}
