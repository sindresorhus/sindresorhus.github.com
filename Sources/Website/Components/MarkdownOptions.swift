import Elementary
import Foundation
import protocol Markdown.BlockMarkup
import protocol Markdown.InlineMarkup
import protocol Markdown.Markup
import struct Markdown.BlockDirective
import struct Markdown.Document
import struct Markdown.Emphasis
import struct Markdown.Heading
import struct Markdown.HTMLBlock
import struct Markdown.InlineHTML
import struct Markdown.Link
import struct Markdown.ListItem
import struct Markdown.Paragraph
import struct Markdown.Strong
import struct Markdown.Text
import struct Markdown.UnorderedList
import SiteKit
import SOML

extension MarkdownDocument.Options {
	/**
	The site's classes, and no other options. For short texts, like frontmatter fields.
	*/
	static let site = Self(theme: .site)

	/**
	The options for a content file: the features of ``contentFeatures``, links to other content files (`[Dato](dato.md)`), and the sizes of local images.

	- Parameter sponsorTiers: The sponsors from the frontmatter, which `@Sponsors` shows.
	- Parameter today: The day of the build, which decides what `@Scheduled` shows. Without it, `@Scheduled` is an unknown directive.
	*/
	static func content(
		_ file: MarkdownFile,
		project: Project,
		sponsorTiers: [MarkdownPage.SponsorTier.Resolved] = [],
		today: SOML.Date? = nil
	) -> Self {
		var options = contentFeatures

		options.resolveLink = { (destination: String) throws(ContentError) in
			try file.resolvingLink(destination, project: project)
		}

		options.imageSize = { source in
			// An image from another site has no size, as it is not a file of this one, and a path from content is already checked by the link. A screenshot of a Retina display is shown at half its pixel size, so it is sharp.
			(try? RoutePath(validating: source)).flatMap { project.publicFile($0).displaySize }
		}

		// The Markdown arguments of the directives, like the summary of `@Details`, get the checks of the document when they render, like the names of keys, the links, and the platforms of badges (``MarkdownDocument/Options/BlockDirectiveRenderer/Context``).
		options.blockDirectives = .site(sponsorTiers: sponsorTiers, today: today)
		// The tags of guides are named with the titles of their guides.
		options.linkTags = .site(project: project)
		return options
	}

	/**
	Shows the small icon of one of my apps before the first link to its page in the text, like “Second Clock” on the page of Dato, and before each link that starts a list item with a `:: ` line, so a reader sees that the text names an app of mine, and how it looks (``MarkdownDocument/Options/linkIcon``). A link to the product of an app on Gumroad, like `https://sindresorhus.gumroad.com/l/supercharge/BLACKFRIDAY` in a list of a sale, counts as a link to its page. A link to one of the excluded apps has none, like the app of an app page, which the page already shows. The icon is only in the HTML, so the Markdown copy and the link previews do not change.

	Limitation: The text renders before the other apps are loaded, so a link to an archived or unlisted app gets the icon too, and a Gumroad product is the app with the same slug, as the IDs of the products are the slugs of their apps.

	- Parameter iconCopies: The JPEG XL copies of the icons of the apps, by the path of the icon (``App/iconJPEGXLCopies(project:)``), which are made before the text renders.
	- Parameter excludedApps: The paths of the apps whose links get no icon, like `/dato` on the page of Dato.
	*/
	mutating func addAppLinkIcons(
		project: Project,
		iconCopies: [RoutePath: JPEGXLCopy],
		excluding excludedApps: Set<RoutePath> = []
	) {
		linkIcon = { destination in
			let pagePath = URL(string: destination).flatMap(GumroadProductID.init(productURL:)).map { "/\($0)" } ?? String(destination.prefix { $0 != "#" && $0 != "?" })

			guard
				let path = try? RoutePath(validating: pagePath),
				!excludedApps.contains(path)
			else {
				return nil
			}

			let iconPath = path.appending("icon.png")
			let pageFile = App.directory.fileURL(in: project.root).appending(path: path.relativePath).pageBundleIndex

			guard
				pageFile.isFile,
				RoutePath(contentFile: pageFile, project: project) == path,
				project.existingPublicFile(iconPath) != nil
			else {
				return nil
			}

			// About as large as the capital letters, on the baseline, so the line keeps its height. It is in the link, so it opens the page too, and it is an inline block, so the underline is only below the name. The space before it is larger than a space between words, so the icon does not touch the word before the link.
			return AppIcon(decorative: iconPath, jpegXL: iconCopies[iconPath], size: 32)
				.style {
					$0.linkIconPlacement()
				}
				.renderFragment()
		}
	}

	/**
	Shows the small icon of each app before the heading of its section, which is “With” and the title of the app, like “With Dato” in a guide (``MarkdownDocument/Options/headingIcon``), so the sections of the apps look different from the built-in way at a glance, and a guide with several apps shows which app each section uses. The titles are read from the files of the apps, as the text renders before the apps are loaded, like the titles of the guide tags (``Guide/task(slug:project:)``).

	- Parameter iconCopies: The JPEG XL copies of the icons of the apps, by the path of the icon (``App/iconJPEGXLCopies(project:)``).
	- Parameter apps: The slugs of the apps, like the `apps` of a guide.
	*/
	mutating func addAppHeadingIcons(
		project: Project,
		iconCopies: [RoutePath: JPEGXLCopy],
		apps: [ContentSlug]
	) {
		let iconPathsByHeading = Dictionary(
			apps.compactMap { slug -> (String, RoutePath)? in
				guard
					let file = App.sourceFile(for: slug, in: project),
					let title = (try? MarkdownFile(url: file).decodeFrontmatter(as: App.Frontmatter.self))?.title
				else {
					return nil
				}

				let iconPath = App.path(slug: slug).appending("icon.png")
				return ("With \(title)", project.existingPublicFile(iconPath) == nil ? App.placeholderIconPath : iconPath)
			}
		) { first, _ in first }

		headingIcon = { text in
			// About as large as the capital letters of the heading, on the baseline, like the icon of an app link, with the space of a word after it.
			iconPathsByHeading[text].map { iconPath in
				AppIcon(decorative: iconPath, jpegXL: iconCopies[iconPath], size: 32)
					.style {
						$0
							.frame(size: .em(1.1))
							.verticalAlign(.em(-0.18))
							.margin(.trailing, .em(0.35))
					}
					.renderFragment()
			}
		}
	}

	/**
	Shows the small icon of a shared shortcut before the first link to it in a sentence, like the icon of an app before a link to its page (``addAppLinkIcons(project:iconCopies:excluding:)``), so a reader sees that the link adds a ready-made shortcut. A link that is a card already shows the icon (``ShortcutCard``), and a link to a shortcut that did not load has none. Call it after ``addAppLinkIcons(project:iconCopies:excluding:)``, as it keeps the icons of the app links.
	*/
	mutating func addShortcutLinkIcons(_ shortcuts: [Shortcut.ID: Shortcut]) {
		let appLinkIcon = linkIcon

		linkIcon = { destination in
			guard let shortcut = Shortcut.ID(link: destination).flatMap({ shortcuts[$0] }) else {
				return appLinkIcon?(destination)
			}

			// Inline, like the icon of an app link, and with the corners of an icon of the Shortcuts app, like on the card, as the icon from iCloud is a square.
			return JPEGXLPicture(copy: shortcut.iconJPEGXL) {
				img(
					.src(shortcut.iconPath),
					.alt(""),
					.width(32),
					.height(32),
					.lazyLoading,
					.asyncDecoding
				)
				.style {
					$0
						.plainImage()
						.display(.inlineBlock)
						.linkIconPlacement()
						.cornerRadius(.percent(22.5))
				}
			}
			.renderFragment()
		}
	}

	/**
	The Markdown of content files without a file, for the samples in the gallery: the features of ``contentFeatures``, collapsible sections for level 3 headings, like the questions of an FAQ, and links that copy the URL of a section.
	*/
	static let gallery: Self = {
		var options = contentFeatures
		options.collapsibleSections = MarkdownDocument.CollapsibleSections(level: .h3)
		options.addsHeadingAnchors = true
		return options
	}()

	/**
	The options of ``gallery`` with `@Scheduled`, for the samples of the gallery page.

	- Parameter today: The day of the build, which decides what `@Scheduled` shows.
	*/
	static func gallery(today: SOML.Date) -> Self {
		var options = gallery
		options.blockDirectives = .site(today: today)
		return options
	}

	/**
	What content files and the samples of the gallery have: the site's classes, platform badges, the block directives, “Guide” and “Details” tags (`<guide:slug>` and `<section:id>`), inline notes as `InlineNote`, code blocks as `CodeBlock`, with a copy button and Swift and SOML highlighting, and the headings that `@Chips` links to as groups with a title that stays at the top of the screen.
	*/
	private static let contentFeatures: Self = {
		var options = Self(
			theme: .site,
			inlineAttributes: .init(render: renderPlatformBadge),
			// The content directives also have examples in the gallery.
			blockDirectives: .site(),
			linkTags: .site(project: nil),
			codeBlock: CodeBlock.render,
			inlineNote: InlineNote.render
		)
		options.groupedHeadingIDs = ChipsArguments.linkedHeadingIDs
		return options
	}()

	/**
	The questions below the “Frequently Asked Questions” heading of an app page are collapsible, below links to ask an assistant about the page (``AssistantLinks``), and followed by a link to the general FAQ and, unless the app is archived, a link to send a message. A platform badge must be for a platform of the app. Each section has a link that copies its URL. The common questions that apply to the app (``CommonQuestion``), the shared questions that it picks, and, unless the app is archived, the feedback question are added to the questions, and the older versions get their section (``App/Frontmatter/addingGeneratedSections(to:sharedQuestions:renderDownloadCard:)``). A link that is alone in its paragraph or list item to one of the shortcuts is a card (``ShortcutCard``).
	*/
	static func appPage(
		_ file: MarkdownFile,
		project: Project,
		frontmatter: App.Frontmatter,
		sharedQuestions: App.SharedQuestions,
		shortcuts: [Shortcut.ID: Shortcut],
		appIconCopies: [RoutePath: JPEGXLCopy]
	) -> Self {
		// Download cards come from typed metadata, rather than content directives.
		var options = content(file, project: project)
		// The page already shows the icon of its own app.
		options.addAppLinkIcons(project: project, iconCopies: appIconCopies, excluding: [App.path(slug: file.slug)])
		options.addShortcutLinkIcons(shortcuts)

		// A badge for a platform that the app is not on would say that a part works on a platform where the app is not. The arguments of the directives get the check too.
		options.inlineAttributes = .init { (attributes: PlatformBadgeAttributes, content: HTMLFragment) throws(ContentError) in
			guard frontmatter.platforms.contains(attributes.platform) else {
				throw ContentError(reason: "The platform badge is for \(attributes.platform.rawValue), but the app is not on it. Add it to `platforms`, or remove the badge.")
			}

			return renderPlatformBadge(attributes: attributes, content: content)
		}

		// The feedback page suggests the questions of the FAQ section. The picked shared questions have their own directives too.
		options.headingDirectives = FAQDirectives.all + [App.SharedQuestions.First.self]
		// The end of the questions is where a visitor who did not find the answer gives up, so it says that a message is welcome. An archived app gets no support.
		// A note about the FAQ, like the line about the assistants below its heading (``AssistantLinks``), so it has the same look, and does not read as the start of the next section.
		let feedbackURL = App.feedbackURL(appTitle: frontmatter.title, referrer: .faq)
		let footer: @Sendable () -> HTMLFragment = {
			UnansweredQuestionNote(feedback: feedbackURL).renderFragment()
		}

		options.collapsibleSections = MarkdownDocument.CollapsibleSections(
			level: .h3,
			startHeadingID: App.Section.faq.id,
			moreLink: .init(title: "More FAQs", destination: .path(.faq)),
			footer: frontmatter.isArchived ? nil : footer
		)
		options.addsHeadingAnchors = true

		// An unlisted app has no Markdown copy for the assistant to read.
		let assistantLinks = frontmatter.isUnlisted ? nil : AssistantLinks(appTitle: frontmatter.title, markdownCopyURL: App.path(slug: file.slug).markdownCopy.absoluteURL)

		options.rewrite = { document in
			var faqIntroduction = assistantLinks.map { [HTMLBlock($0.render())] } ?? []

			// A long FAQ, like the 87 questions of Dato, gets a button that opens the search of the site with the name of the app, so a visitor finds an answer without reading the titles of all the questions.
			if Array(document.blockChildren).faqQuestionCount >= 20 {
				let searchButton = SiteSearch.OpenButton(query: "\(frontmatter.title) ") {
					Icon.search.size(.rootEm(1))
					"Search Questions"
				}
				.style {
					$0.chip(hasIcon: true)
				}

				faqIntroduction.insert(HTMLBlock(searchButton.render()), at: 0)
			}

			return frontmatter.addingGeneratedSections(
				to: document.showingShortcutCards(shortcuts),
				sharedQuestions: sharedQuestions,
				faqIntroduction: faqIntroduction
			) { card in
				[HTMLBlock(card.render())]
			}
		}

		return options
	}

	/**
	Every question of the general FAQ is collapsible, and each has a link that copies its URL. Only this page can mark questions as useful for every app (`<!-- @faq.general -->`), which the feedback page suggests.
	*/
	static func faqPage(_ file: MarkdownFile, project: Project) -> Self {
		var options = content(file, project: project)
		options.headingDirectives = FAQDirectives.all + [FAQDirectives.General.self]
		options.collapsibleSections = MarkdownDocument.CollapsibleSections(level: .h3)
		options.addsHeadingAnchors = true
		return options
	}
}

/**
The block directives of the content, like `@Details(summary: "More") { … }`. The raw value is the name in the Markdown.
*/
enum BlockDirectiveName: String, CaseIterable {
	case details = "Details"
	case feature = "Feature"
	case quickAnswer = "QuickAnswer"
	case tinyApp = "TinyApp"
	case liveFact = "LiveFact"
	case tips = "Tips"
	case cards = "Cards"
	case columns = "Columns"
	case chips = "Chips"
	case photos = "Photos"
	case steps = "Steps"
	case changelog = "Changelog"
	case socialLinks = "SocialLinks"
	case sponsors = "Sponsors"
	case scheduled = "Scheduled"

	/**
	The renderer of the directive, or `nil` when the page cannot have it.

	- Parameter sponsorTiers: The sponsors that `@Sponsors` shows. Without them, `@Sponsors` is an unknown directive.
	- Parameter today: The day of the build, which decides what `@Scheduled` shows. Without it, `@Scheduled` is an unknown directive.
	*/
	fileprivate func renderer(sponsorTiers: [MarkdownPage.SponsorTier.Resolved], today: SOML.Date?) -> MarkdownDocument.Options.BlockDirectiveRenderer? {
		switch self {
		case .details:
			DetailsArguments.renderer
		case .feature:
			FeatureArguments.renderer
		case .quickAnswer:
			.init(render: renderQuickAnswer)
		case .tinyApp:
			TinyAppArguments.renderer
		case .liveFact:
			LiveFactArguments.renderer
		case .tips:
			.init(render: renderTips) { arguments, content in
				// Without a title, the box is “Tips”, which the heading above it often says already.
				(arguments.title.map { [Paragraph(Strong(Markdown.Text($0)))] } ?? []) + content
			}
		case .cards:
			.init(content: .unorderedList, rewriteContent: markingLinkCards, render: renderCards)
		case .columns:
			.init(content: .unorderedList, render: renderColumns)
		case .chips:
			.init(content: .unorderedList, rewriteContent: ChipsArguments.checkingLinks, render: ChipsArguments.render)
		case .photos:
			.init(content: .unorderedList, render: renderPhotos)
		case .steps:
			.init(content: .orderedList, render: renderSteps)
		case .changelog:
			.init(content: .unorderedList, rewriteContent: addingChangeBadges, render: renderChangelog)
		case .socialLinks:
			.init(content: .empty, render: renderSocialLinks) { _ in
				[UnorderedList(Site.author.socialLinks.map { ListItem(Paragraph(Markdown.Link(destination: .url($0.url), text: $0.name))) })]
			}
		case .sponsors:
			sponsorTiers.isEmpty ? nil : .init(content: .empty) { _ in
				SponsorList(tiers: sponsorTiers).renderFragment()
			}
		case .scheduled:
			today.map { today in
				.init { (arguments: ScheduledArguments, content: HTMLFragment) -> HTMLFragment in
					if arguments.contains(today) {
						return content
					}

					guard
						let sale = arguments.sale,
						let announcement = arguments.saleAnnouncement(on: today)
					else {
						return .empty
					}

					return MarkdownTheme.site.alert(.tip, title: sale, content: p { announcement }.renderFragment())
				}
			}
		}
	}
}

extension BlockDirective {
	/**
	The directive of the site, or `nil` for another name, which the build reports as unknown.
	*/
	var siteName: BlockDirectiveName? {
		BlockDirectiveName(rawValue: name)
	}

	/**
	The arguments of a `@Scheduled` block, or `nil` for another directive, and for arguments that are not valid, which the build already reported.
	*/
	var scheduled: ScheduledArguments? {
		guard siteName == .scheduled else {
			return nil
		}

		return try? arguments(as: ScheduledArguments.self)
	}

	/**
	The blocks of the directive in plain Markdown, with what the page shows from its arguments, like the title of `@Feature` as a heading (``MarkdownDocument/Options/BlockDirectiveRenderer/plainBlocks(of:)``). A list, like the cards of `@Cards`, is only its list, and a directive that is not of the site is its content.
	*/
	var plainBlocks: [any BlockMarkup] {
		Self.siteRenderers[name]?.plainBlocks(of: self) ?? Array(blockChildren)
	}

	/**
	The renderers for ``plainBlocks``, which do not depend on the page.
	*/
	private static let siteRenderers = [String: MarkdownDocument.Options.BlockDirectiveRenderer].site()
}

extension PlainMarkdownRewriter {
	/**
	A rewriter with the tags of links of the site (``Swift/Dictionary/site(project:)``), so no text for readers outside the site has a tag as raw text, like `<guide:find-screenshots-mac>`.

	- Parameter project: Names a “Guide” tag with the task of its guide, like `[Guide: Find Screenshots on Mac](guide:find-screenshots-mac)`. Without it, like in the link previews, the tag is only its text.
	- Parameter linkDestination: Resolves the destinations of links and images, like to absolute URLs.
	- Parameter blockDirective: The blocks of a block directive, by default what the page shows from it (``Markdown/BlockDirective/plainBlocks``).
	*/
	static func site(
		project: Project?,
		linkDestination: ((String) -> String)? = nil,
		blockDirective: @escaping (BlockDirective) -> [any BlockMarkup] = { $0.plainBlocks }
	) -> Self {
		Self(linkDestination: linkDestination, linkTags: .site(project: project), blockDirective: blockDirective)
	}
}

/**
The inline Markdown of an argument of a directive in plain Markdown, like the title of `@Feature`. The build already checked it.
*/
private func inlineMarkup(_ markdown: String) -> [any InlineMarkup] {
	Document(parsing: markdown).blockChildren.compactMap { $0 as? Paragraph }.first.map { Array($0.inlineChildren) } ?? []
}

extension MarkdownDocument.Block {
	/**
	The directive of the site that the block is, like `.quickAnswer`, or `nil` for another block.
	*/
	var siteDirectiveName: BlockDirectiveName? {
		directiveName.flatMap(BlockDirectiveName.init(rawValue:))
	}
}

extension [String: MarkdownDocument.Options.BlockDirectiveRenderer] {
	/**
	The block directives of the site, by name (``BlockDirectiveName``).

	- Parameter sponsorTiers: The sponsors that `@Sponsors` shows. Without them, `@Sponsors` is an unknown directive.
	- Parameter today: The day of the build, which decides what `@Scheduled` shows. Without it, `@Scheduled` is an unknown directive.
	*/
	static func site(sponsorTiers: [MarkdownPage.SponsorTier.Resolved] = [], today: SOML.Date? = nil) -> Self {
		Dictionary(uniqueKeysWithValues: BlockDirectiveName.allCases.compactMap { name in
			name.renderer(sponsorTiers: sponsorTiers, today: today).map { (name.rawValue, $0) }
		})
	}
}

/**
The inline attributes of a platform badge, like `^[macOS only](platform: "macOS")`.
*/
@Frontmatter
private struct PlatformBadgeAttributes {
	var platform: Platform
}

/**
A platform badge, like `^[macOS only](platform: "macOS")`.
*/
@Sendable
private func renderPlatformBadge(attributes: PlatformBadgeAttributes, content: HTMLFragment) -> HTMLFragment {
	span {
		content
	}
	.style(Badge.Styles.root, Badge.Kind.platform)
	.attributes(.data("platform", value: attributes.platform.rawValue))
	.renderFragment()
}

/**
The arguments of `@Details(summary: "Why?") { … }`.
*/
@Frontmatter
struct DetailsArguments {
	/**
	Inline Markdown.
	*/
	@NonEmpty var summary: String
}

/**
A collapsible section, like `@Details(summary: "Why?") { … }`, with the look of the FAQ questions.
*/
extension DetailsArguments: BlockDirectiveDefinition {
	typealias Arguments = Self
	static let name = BlockDirectiveName.details.rawValue

	static func render(
		arguments: DetailsArguments,
		content: HTMLFragment,
		context: MarkdownDocument.Options.BlockDirectiveRenderer.Context
	) throws(ContentError) -> HTMLFragment {
		let summary = try context.inlineDocument(parsing: arguments.summary)

		// A click on the summary opens the section, so a link in it could not be followed.
		guard summary.links.isEmpty else {
			throw ContentError(reason: "The `summary` cannot have links, as a click on it opens the section. Put the link in the section.")
		}

		return MarkdownTheme.site.collapsibleSection(title: summary.inlineHTML, content: content)
	}

	static func plainBlocks(arguments: Self, content: [any BlockMarkup]) -> [any BlockMarkup] {
		[Paragraph(Strong(inlineMarkup(arguments.summary)))] + content
	}
}

/**
The arguments of `@Feature(title: "Open links in the right browser", label: "Browsers") { … }`.
*/
@Frontmatter
struct FeatureArguments {
	/**
	Inline Markdown.
	*/
	@NonEmpty var title: String

	/**
	The plain name of what the feature is about, like “Calendar”, after the number, like “01 · CALENDAR”, so a visitor who scans the sections for a noun finds it, and the title can be about what the feature does for the visitor. Without it, the number is alone.
	*/
	@PlainText var label: String?
}

/**
A main feature of an app, like `@Feature(title: "Open links in the right browser") { … }`: a section with a numbered title, like “01”, so a few main features stand out from the rest of the page. With a `label`, the number and the label are a line above the title, like “01 · CALENDAR”.
*/
extension FeatureArguments: BlockDirectiveDefinition {
	typealias Arguments = Self
	static let name = BlockDirectiveName.feature.rawValue

	static func render(
		arguments: FeatureArguments,
		content: HTMLFragment,
		context: MarkdownDocument.Options.BlockDirectiveRenderer.Context
	) throws(ContentError) -> HTMLFragment {
		let title = try context.inlineDocument(parsing: arguments.title).inlineHTML

		return section {
			// The label is text, not generated content, so find in the page finds it, and screen readers say it before the title.
			if let label = arguments.label {
				p {
					label
				}
				.style(FeatureSectionStyles.label)
			}

			h2 {
				title
			}
			.style(FeatureSectionStyles.title, when: arguments.label == nil)
			.style(FeatureSectionStyles.labeledTitle, when: arguments.label != nil)

			content
		}
		.style(FeatureSectionStyles.root)
		.renderFragment()
	}

	static func plainBlocks(arguments: Self, content: [any BlockMarkup]) -> [any BlockMarkup] {
		// The label is text on the page, so the copy has it before the title, like “Calendar: Your week in the menu bar”.
		let title = arguments.label.map { "\($0): \(arguments.title)" } ?? arguments.title
		return [Markdown.Heading(level: .h2, inlineMarkup(title))] + content
	}
}

/**
The styles of `@Feature` sections. The sections of a page are numbered in order with a CSS counter.
*/
private enum FeatureSectionStyles: String, StyleSet {
	case root
	case title
	case label
	case labeledTitle

	enum Counters: String, CounterSet {
		case feature
	}

	var style: Style {
		switch self {
		case .root:
			// The margin separates the last section from the content after it, with the space between two sections (the space above a title of prose), so the content after it does not look like a part of the last section. Between sections, it collapses into the same top margin of the next title.
			Style()
				.counterIncrement(Counters.feature)
				.margin(.bottom, .length(.partSpacing(rootEm: 5)))
		case .title:
			// The number is in the accent of the page, like the color of the icon on an app page. Screen readers skip it, as the title says what the section is, and “zero one” before it is noise.
			Style()
				.before {
					$0
						.content(counter: Counters.feature, style: .decimalLeadingZero, alternativeText: "")
						.display(.block)
						.margin(.bottom, .rootEm(0.75))
						.featureNumber()
				}
		case .label:
			// The number and the label are one line with the look of the number alone, and the space above a title of prose, as the line is the start of the section. The number is before the label, and screen readers skip it, like the number of a title without a label.
			Style()
				.margin(top: .length(.partSpacing(rootEm: 5)), horizontal: .zero, bottom: .rootEm(0.75))
				.featureNumber()
				// The label is text, so it has the accent for text, which has the contrast of text, also for a light accent in light mode or a dark accent in dark mode. The number alone is a mark (``Color/accentMark``).
				.color(.accentText)
				.textCase(.uppercase)
				// Capitals need more space between the letters than the digits of the number alone.
				.letterSpacing(.em(0.06))
				.before {
					$0.content(counter: Counters.feature, style: .decimalLeadingZero, suffix: " · ", alternativeText: "")
				}
		case .labeledTitle:
			// Close to the label above it, which has the space above the section.
			Style().margin(.top, .zero)
		}
	}
}

extension Style {
	/**
	The look of the number of a `@Feature` section, and of the label after it: small, bold, and in the accent of the page.
	*/
	fileprivate func featureNumber() -> Self {
		fontFamily(.rounded)
			.font(.callout)
			.fontWeight(.bold)
			.letterSpacing(.em(0.02))
			.monospacedDigit()
			.color(.accentMark)
	}
}

/**
The short answer at the top of a guide, like `@QuickAnswer { Hold Fn and click the link. }`, in a box with a “Quick Answer” label, for readers who only want the answer.
*/
@Sendable
private func renderQuickAnswer(content: HTMLFragment) -> HTMLFragment {
	aside {
		p {
			"Quick Answer"
		}
		.style(QuickAnswerStyles.label)

		content
	}
	.style(QuickAnswerStyles.root)
	.renderFragment()
}

/**
The styles of `@QuickAnswer` boxes.
*/
private enum QuickAnswerStyles: String, StyleSet {
	case root
	case label

	var style: Style {
		switch self {
		case .root:
			// Below tablets, as wide as the screen, like the box to get the app below it, so its text starts where the paragraphs start. It has no corners there, and only the edges at its top and bottom.
			Style()
				.proseCard()
				.color(.primaryText)
				.screenWideBelowTablet()
		case .label:
			// A block as wide as its text, not an inline block, so its margin and the margin of the answer below it collapse into one space, a little less than the padding of the box, so the label stays with the answer.
			Style()
				.frame(width: .fitContent)
				.margin(.bottom, .rootEm(1))
				.padding(vertical: .rootEm(0.125), horizontal: .rootEm(0.625))
				.cornerRadius(.capsule)
				// The size and weight of the other short labels above content (``Style/eyebrow()``).
				.textStyle(.caption, weight: .semibold)
				// Not the color of links, as it is not a link, but the accent for text, so the small text has the contrast of text on the tint of the accent, also on a guide in the color of its app.
				.color(.accentText)
				.background(Color.pageAccent.opacity(0.1))
		}
	}
}

/**
A download card generated from the typed metadata of an app: its trial or its version outside the App Store. The text, download link, and requirement also provide the plain Markdown export.
*/
struct AppDownloadCard: HTML {
	let text: [any BlockMarkup]
	let buttonTitle: String
	let url: AbsoluteURL
	var requirement: String?
	var setappURL: URL?

	/**
	How to install a zip file of an app, which the card shows below a zip download, the “Older Versions” section of an app page below its list, and the top of the page of older versions. It names the zip file and the app, so it reads well without a sentence about an app before it. The folder is its name in Finder, not its path.
	*/
	static let installSentence = "Download the zip file to the Downloads folder, double-click it to unzip, and then move the app to the “Applications” folder."

	var body: some HTML<HTMLTag.div> {
		// Not an aside, as the download is part of the page about the app.
		div {
			MarkdownDocument(blocks: text, options: .site).content

			// The requirement is next to the button, as it decides whether the download is any use.
			div {
				Link(buttonTitle, destination: .url(url))
					.buttonStyle()

				if let requirement {
					span {
						requirement
					}
					.style(Styles.requirement)
				}
			}
			.style(Styles.actions)

			let isZip = url.value.pathExtension == "zip"

			// How to install the download, and the trial on Setapp, which are both about how to try the app.
			if isZip || setappURL != nil {
				div {
					if isZip {
						p {
							// “double-click” stays on one line, like in prose (``SiteKit/MarkdownTheme/textHTML(_:)``).
							MarkdownTheme.site.headingTextHTML(Self.installSentence)
						}
					}

					if let setappURL {
						p {
							"You can also "
							a(.href(.url(setappURL))) {
								"try it on Setapp"
							}
							" for 7 days for free."
						}
					}
				}
				.style(Styles.footer)
			}
		}
		.style(Styles.root)
	}

	/**
	The same text, download link, and requirement as plain Markdown, without the card presentation.
	*/
	var plainBlocks: [any BlockMarkup] {
		text + [
			Paragraph(Markdown.Link(destination: .url(url), text: buttonTitle)),
			requirement.map { Paragraph(Emphasis(Markdown.Text($0))) },
		].compactMap(\.self)
	}
}

/**
The styles of the generated download cards. The card has a soft light of the accent of the app in its corner, so it stands out from the text around it as the place to get the app.
*/
extension AppDownloadCard {
	enum Styles: String, StyleSet {
		case root
		case actions
		case requirement
		case footer

		var style: Style {
			switch self {
			case .root:
				// The stack has the space between the blocks, so the margins of the paragraphs of prose are reset.
				// Directly in prose below tablets, as wide as the screen, like the Quick Answer of a guide, so its text starts where the paragraphs start. Not in another place, like the trial dialog of the app page.
				Style()
					.vstack(alignment: .start, spacing: .rootEm(1.25))
					.proseCard()
					.directlyInside(ProseStyles.root.selector) {
						$0.screenWideBelowTablet()
					}
					// In dark mode, a dark accent gets the lightness of the selection (``Color/darkModeHighlightAccent``), so its light shows on the dark card.
					.backgroundImage(Self.light(Color.pageAccent.opacity(0.1)), dark: Self.light(Color.darkModeHighlightAccent.opacity(0.16)))
					.directlyAfter(":target") {
						$0.targetHighlight()
					}
					.children("p") {
						$0.margin(.zero)
					}
			case .actions:
				Style()
					.hstack(alignment: .center)
					.flexWrap()
					.gap(row: .rootEm(0.75), column: .rootEm(1.25))
			case .requirement:
				Style().secondaryText()
			case .footer:
				// Below a line, as it is about what to do after the download, or another way to try the app. The margins of the paragraphs of prose are reset.
				Style()
					.vstack(spacing: .rootEm(0.5))
					.frame(width: .percent(100))
					.padding(.top, .rootEm(1))
					.border(.top, .separator)
					.secondaryText()
					.children("p") {
						$0.margin(.zero)
					}
			}
		}

		/**
		The light of a tint of the accent in the top leading corner, like the light of an interactive card under the pointer.
		*/
		private static func light(_ color: Color) -> CSSImage {
			.radialGradient(.circle(at: .init(x: .percent(0), y: .percent(0))), color.at(.percent(0)), Color.transparent.at(.percent(60)))
		}
	}
}

/**
The arguments of `@TinyApp(title: "Copy URL", download: "https://example.com/Copy-URL.zip") { … }`.
*/
@Frontmatter
struct TinyAppArguments {
	@PlainText var title: String

	/**
	Without an icon, the card shows the placeholder icon, so the titles of all cards line up.
	*/
	var icon: RoutePath?

	/**
	The app, or the page of its latest release.
	*/
	var download: AbsoluteURL

	var source: AbsoluteURL?

	/**
	The oldest macOS version that the app runs on, like `macOS: "15"`, which the card shows as “Requires macOS 15 or later”.
	*/
	var macOS: OSVersion?
}

/**
A small app without a page of its own, like `@TinyApp(title: "Copy URL", download: "https://example.com/Copy-URL.zip") { What it does. }`: a card with the icon, the name, the text, a download button, and the requirement, like a small app card.
*/
extension TinyAppArguments: BlockDirectiveDefinition {
	typealias Arguments = Self
	static let name = BlockDirectiveName.tinyApp.rawValue

	static func render(arguments: Self, content: HTMLFragment, context: MarkdownDocument.Options.BlockDirectiveRenderer.Context) -> HTMLFragment {
		section {
			// The icons load at once, as the first one is in the first screen, and a directive does not know whether it is the first. The tiny apps page has only a few.
			AppIcon(decorative: arguments.icon ?? App.placeholderIconPath, size: 128, isAboveFold: true)
				.style(TinyAppStyles.icon)

			h2 {
				arguments.title
			}
			.style(TinyAppStyles.title)

			div {
				content

				// The name of the app is in the links for screen readers, as a page has several cards, and a list of the links would have the same names.
				div {
					Link(destination: .url(arguments.download)) {
						"Download"
						VisuallyHidden(" \(arguments.title)")
					}
					.buttonStyle(size: .small)

					if let source = arguments.source {
						Link(destination: .url(source)) {
							"Source Code"
							VisuallyHidden(" of \(arguments.title)")
						}
						.buttonStyle(.secondary, size: .small)
					}

					if let macOS = arguments.macOS {
						span {
							OSRequirement.macOS(macOS).sentence
						}
						.style(TinyAppStyles.requirement)
					}
				}
				.style(TinyAppStyles.actions)
			}
			.style(TinyAppStyles.text)
		}
		.style(TinyAppStyles.root)
		.renderFragment()
	}

	/**
	A `@TinyApp` card in plain Markdown: the name as a heading, the text, the links, and the requirement.
	*/
	static func plainBlocks(arguments: Self, content: [any BlockMarkup]) -> [any BlockMarkup] {
		let links = [
			Markdown.Link(destination: .url(arguments.download), text: "Download"),
			arguments.source.map { Markdown.Link(destination: .url($0), text: "Source Code") },
		]
		.compactMap(\.self)

		let requirement: [any BlockMarkup] = arguments.macOS.map { [Paragraph(Emphasis(Markdown.Text(OSRequirement.macOS($0).sentence)))] } ?? []
		return [Markdown.Heading(level: .h2, Markdown.Text(arguments.title))] + content + [UnorderedList(links.map { ListItem(Paragraph($0)) })] + requirement
	}
}

/**
The styles of `@TinyApp` cards.
*/
enum TinyAppStyles: String, StyleSet {
	case root
	case icon
	case text
	case title
	case actions
	case requirement

	var style: Style {
		switch self {
		case .root:
			// The icon is next to the title, and the text is below the title. On phones, the text is also below the icon, so it has the whole width.
			Style()
				.grid(columns: .auto, .fraction(1))
				.gap(row: .rootEm(1), column: .rootEm(1))
				.alignItems(.center)
				.proseCard()
				// Less padding on phones, so the text has more of the narrow width.
				.below(.smallTablet) {
					$0.padding(.rootEm(1.25))
				}
				.from(.smallTablet) {
					$0
						.gap(row: .rootEm(0.5), column: .rootEm(1.5))
						.alignItems(.start)
				}
		case .icon:
			// The icon is smaller on phones, where it is about as high as the title. In pixels, so it does not grow with larger text, which needs the room more than the icon.
			Style()
				.frame(size: .pixels(56))
				.from(.smallTablet) {
					$0
						.frame(size: .pixels(72))
						.gridRowSpan(2)
				}
		case .text:
			// The paragraphs are closer than in prose, so they read as one text, which is closer to the title than to the buttons.
			Style()
				.frame(minWidth: .zero)
				.children("p") {
					$0.margin(vertical: .em(0.5), horizontal: .zero)
				}
				.trimmingChildMargins()
				.below(.smallTablet) {
					$0.gridColumnSpan(2)
				}
		case .title:
			// Like the title of an app card. The margin of a heading in prose is reset.
			AppCard.Styles.title.style.margin(.zero)
		case .actions:
			Style()
				.hstack(alignment: .center, spacing: .rootEm(0.75))
				.flexWrap()
				.margin(.top, .rootEm(1.5))
		case .requirement:
			Style()
				.secondaryText()
		}
	}
}

/**
The arguments of `@Tips(title: "Hidden features") { … }`.
*/
@Frontmatter
struct TipsArguments {
	/**
	The title of the box, for a box below a heading that already says “Tips”. Without it, the box is “Tips”.
	*/
	@PlainText var title: String?
}

/**
A box of tips, like `@Tips { - Tip }`, with the look of a tip alert.
*/
@Sendable
private func renderTips(arguments: TipsArguments, content: HTMLFragment) -> HTMLFragment {
	MarkdownTheme.site.alert(.tip, title: arguments.title ?? "Tips", content: content)
}

extension HTMLFragment {
	/**
	The list of a directive, like the steps of `@Steps`, with `role="list"`, so VoiceOver in Safari still says that it is a list and how many items it has, as the styles remove its bullets. The content is the one list that the renderer checked, so the first list tag is its own.
	*/
	func addingListRole() -> Self {
		let html = rawValue.replacing(listStartTag, maxReplacements: 1) { match in
			"<\(match.1) role=\"list\""
		}

		return Self(rawValue: html)
	}

	/**
	The list of a directive, like the steps of `@Steps`, with its list role (``addingListRole()``) in a box with the style of the directive.
	*/
	fileprivate func listDirective(style: some StyleSet) -> Self {
		div {
			addingListRole()
		}
		.style(style)
		.renderFragment()
	}
}

/**
The start of the tag of a list, like `<ol` of `<ol start="2">`, for ``HTMLFragment/addingListRole()``. Not a literal in the function, as Swift parses a regex literal each time the code runs, and it runs for each directive.
*/
nonisolated(unsafe) private let listStartTag = /<(ol|ul)\b/

/**
A list as cards, like `@Cards { - Focus is a feature }`, so a list of short points is easy to scan. The text of each item is the title of its card, and a nested list is smaller text below it. From tablets, the cards flow through two columns, so cards of different heights fit together.
*/
@Sendable
private func renderCards(content: HTMLFragment) -> HTMLFragment {
	content.listDirective(style: CardListStyles.root)
}

/**
Marks the title of each card of `@Cards` that is only a link, like `- [Random color](https://www.color.pizza)`, also with tags after it, like `<guide:bing-wallpaper-mac>`, so the whole card is the link (``LinkCard``).

- Parameter content: One bulleted list, the cards, which the renderer checked (`.unorderedList`).
*/
@Sendable
private func markingLinkCards(in content: [any BlockMarkup]) -> [any BlockMarkup] {
	content.map { (block: any BlockMarkup) -> any BlockMarkup in
		guard var cards = block as? UnorderedList else {
			return block
		}

		cards.setListItems(cards.listItems.map(LinkCard.markingTitle(of:)))
		return cards
	}
}

/**
A card that is a link as a whole, while the link is only its title, like a card of `@Cards` that is only a link, “Random color” of the use cases of Plash. The link of the title covers the card (``Style/cardCoveringLink()``), and the card lights up under the pointer and with the focus of the keyboard, like other cards that are links (``Style/cardSurface(isInteractive:)``). An arrow after the title says where the link goes: “↗” to another site, and “→” to a page of the site. Other links in the card, like a “Guide” tag, stay above the covering link, so they keep working.

Give the title the ``title`` class, and the card the look of ``card``.
*/
enum LinkCard: String, StyleSet {
	case title

	/**
	The look of the card around a ``title``: the positioned parent of the covering link, with the light of an interactive card. Its other links are above the covering link.
	*/
	static let card = Style()
		.position(.relative)
		.cardSurface()
		.children("a") {
			$0.position(.relative)
		}

	var style: Style {
		switch self {
		case .title:
			// The arrow is after the link, so the underline of a link does not go under it, and screen readers skip it.
			Style()
				// The weight of the title of the card, like a link in a title of a card that is not a link card.
				.children("a") {
					$0
						.cardCoveringLink()
						.inherits(.fontWeight)
				}
				.after {
					$0
						.content(" →", alternativeText: "")
						.fontFamily(.system)
						.fontWeight(.regular)
						.color(.secondaryText)
				}
				.hasChild("a[href^='https:']") {
					$0.after {
						$0.content(" ↗", alternativeText: "")
					}
				}
		}
	}

	/**
	The card with its link in a span of ``title`` when it is only a link, also with tags after it, like “Guide”, and has nothing below it, or the card as it is.
	*/
	static func markingTitle(of card: ListItem) -> ListItem {
		guard
			card.childCount == 1,
			var paragraph = card.child(at: 0) as? Paragraph,
			let link = paragraph.child(at: 0) as? Markdown.Link,
			paragraph.inlineChildren.dropFirst().allSatisfy({ $0.isSpaceOrTag })
		else {
			return card
		}

		let title: [any InlineMarkup] = [
			// Collected, as the page does not collect a class in the text of HTML.
			InlineHTML(#"<span class="\#(Self.title.collectedClassName)">"#),
			link,
			InlineHTML("</span>"),
		]

		paragraph.setInlineChildren(title + paragraph.inlineChildren.dropFirst())
		var card = card
		card.replaceChildrenInRange(0..<1, with: [paragraph] as [any BlockMarkup])
		return card
	}
}

extension InlineMarkup {
	/**
	Whether the markup is only whitespace, or a link whose text is its destination, like a tag (`<guide:slug>`).
	*/
	fileprivate var isSpaceOrTag: Bool {
		if let text = self as? Markdown.Text {
			return text.string.allSatisfy(\.isWhitespace)
		}

		guard let link = self as? Markdown.Link else {
			return false
		}

		return link.plainText == link.destination
	}
}

/**
A list of short items in columns, like `@Columns { - Zoom }`, so a long list of names, like the services that an app supports, does not make a narrow column several screens tall. It is opt-in, as a list of sentences reads better in one column.
*/
@Sendable
private func renderColumns(content: HTMLFragment) -> HTMLFragment {
	content.listDirective(style: ColumnListStyles.root)
}

/**
The styles of `@Columns` lists.
*/
private enum ColumnListStyles: String, StyleSet {
	case root

	var style: Style {
		// As many columns of at least 8 rem as fit, at most four, so a column is not wider than its names. An item is not split across two columns.
		Style()
			.proseBlockMargin()
			.children("ul") {
				$0
					.margin(.zero)
					.columns(4, minimumWidth: .rootEm(8))
					// The bullet of a column hangs in the gap, so the gap is the space of the bullet and 1.5 rem.
					.gap(column: .rootEm(2.25))
					.children("li") {
						$0
							.keepsTogether()
							.margin(top: .zero, horizontal: .zero, bottom: .rootEm(0.5))
							// A wrapped name has its lines closer than the items, so it reads as one item.
							.lineHeight(1.35)
					}
			}
	}
}

/**
A row of three small photos with captions, like `@Photos { - [![Me at the family computer](family-computer.jpg)](family-computer.jpg) }` with a nested item as the caption, so a few old photos are visible in the text, not only links. Each photo links to the full image.
*/
@Sendable
private func renderPhotos(content: HTMLFragment) -> HTMLFragment {
	content.listDirective(style: PhotoListStyles.root)
}

/**
The styles of `@Photos` lists.
*/
private enum PhotoListStyles: String, StyleSet {
	case root

	var style: Style {
		// Three columns at all widths, so the photos are a row. Each photo is cut to 4:3, so the captions start on one line, also with a tall photo. A nested list is the caption, in the small text of a caption.
		Style()
			.proseBlockMargin()
			.children("ul") {
				$0
					.plainList()
					.grid(columns: 3)
					.gap(row: .rootEm(1), column: .rootEm(0.75))
					.from(.tablet) {
						$0.gap(row: .rootEm(1), column: .rootEm(1.25))
					}
					.children("li") {
						$0
							.descendants("p") {
								$0.margin(.zero)
							}
							.descendants("img") {
								$0
									.display(.block)
									.frame(width: .percent(100), height: .auto)
									.margin(.zero)
									.aspectRatio(4.0 / 3)
									.objectFit(.cover)
							}
							.children("ul") {
								$0
									.detailsList()
									.secondaryText()
							}
					}
			}
	}
}

/**
The styles of `@Cards` lists.
*/
enum CardListStyles: String, StyleSet {
	case root

	var style: Style {
		// The items are blocks instead of list items, so they have no bullets.
		Style()
			.proseBlockMargin()
			.children("ul") {
				$0
					.margin(.zero)
					.padding(.zero)
					.from(.tablet) {
						$0
							.columns(2, minimumWidth: .rootEm(15))
							.gap(column: .cardSpacing)
					}
					// Not a stack, so the links in the text stay in its lines. An inline block as wide as its column keeps its bottom margin in its column, as Safari otherwise moves the margin of the last card of a column to the top of the next column.
					.children("li") {
						$0
							.display(.inlineBlock)
							.frame(width: .percent(100))
							.verticalAlign(.top)
							.margin(top: .zero, horizontal: .zero, bottom: .length(.cardSpacing))
							.plainCard()
							.keepsTogether()
							.textStyle(.body, weight: .semibold)
							.color(.primaryText)
							// The title is balanced, so it does not end with one word, like “most-starred”. The text below it keeps its wrap.
							.textWrap(.balance)
							// A link in the title has the weight of the title, as the underline already shows it.
							.children("a") {
								$0.inherits(.fontWeight)
							}
							// A card that is only a link is the link as a whole.
							.hasChild(LinkCard.title.selector) {
								$0.combined(with: LinkCard.card)
							}
							.children("ul") {
								$0
									.detailsList()
									.secondaryText()
									.fontWeight(.regular)
									.textWrap(.pretty)
							}
					}
			}
	}
}

/**
A numbered list as steps, with each number in a circle in the accent of the page and a line to the next, like `@Steps { 1. Write down every idea }`, for a short list of steps in order, like how I make an app. A nested list is smaller text below its item. Below a heading, each step has an ID and a link that copies its URL (``HTMLFragment/addingStepLinks(headingID:)``).
*/
@Sendable
private func renderSteps(content: HTMLFragment, context: MarkdownDocument.Options.BlockDirectiveRenderer.Context) -> HTMLFragment {
	(context.headingID.map { content.addingStepLinks(headingID: $0) } ?? content).listDirective(style: StepListStyles.root)
}

/**
The tag of a list or a list item, like `<ol>`, `</ul>`, or `<li>`, for ``HTMLFragment/addingStepLinks(headingID:)``. Not a literal in the function, as Swift parses a regex literal each time the code runs.
*/
nonisolated(unsafe) private let listOrListItemTag = /<(\/?)(ol|ul|li)\b[^>]*>/

extension HTMLFragment {
	/**
	The steps with IDs from the heading above them and their numbers, like `with-dato-step-2`, so a reader can send one step, like the one that does not work, and the link goes to it. The number of each step is a link that copies its URL, like the link of a heading (`data-copy-link`). Only the items of the list get IDs, not the items of a nested list.

	Limitation: A second list of steps below the same heading has no IDs, as its IDs would be the IDs of the first list (``SiteKit/MarkdownDocument/Options/BlockDirectiveRenderer/Context/headingID``).
	*/
	fileprivate func addingStepLinks(headingID: ElementID) -> Self {
		var listDepth = 0
		var stepNumber = 0

		let html = rawValue.replacing(listOrListItemTag) { match -> String in
			let (tag, closingSlash, name) = match.output

			guard name == "li" else {
				listDepth += closingSlash.isEmpty ? 1 : -1
				return String(tag)
			}

			guard
				closingSlash.isEmpty,
				listDepth == 1
			else {
				return String(tag)
			}

			stepNumber += 1
			let id = ElementID("\(headingID)-step-\(stepNumber)")

			let link = a(.href(.fragment(id)), .hook(ProseStyles.Hooks.copyLink), .ariaLabel("Copy link to step \(stepNumber)")) {}
				.style(StepListStyles.link)
				.renderFragment()

			return #"<li id="\#(id.rawValue.escapedForHTML)""# + tag.dropFirst("<li".count) + link.rawValue
		}

		return Self(rawValue: html)
	}
}

/**
The styles of `@Steps` lists. The items are numbered with a CSS counter, like `@Feature` sections, as items that are not list items have no markers.
*/
enum StepListStyles: String, StyleSet {
	case root

	/**
	The link over the number of a step that copies the URL of the step (``HTMLFragment/addingStepLinks(headingID:)``).
	*/
	case link

	enum Counters: String, CounterSet {
		case step
	}

	var style: Style {
		switch self {
		case .root:
			Self.rootStyle
		case .link:
			Self.linkStyle
		}
	}

	/**
	The link is a circle over the number, which the pointer and the keyboard focus make darker, like a button. After a copy, the circle is filled, with a checkmark in place of the number, like the link of a heading (`site.js`).
	*/
	private static let linkStyle = Style()
		.position(.absolute)
		.top(.zero)
		.leading(.zero)
		.frame(size: .lineHeight(1))
		.cornerRadius(.circle)
		.cursor(.pointer)
		.transition(.backgroundColor, timing: .stateChange)
		.hoverOrFocusVisible {
			$0.background(.accentMark.opacity(0.14))
		}
		.when(ProseStyles.States.copied) {
			$0
				.background(.accentMark)
				.after {
					$0
						.content("")
						.position(.absolute)
						.inset(.percent(22))
						.background(.pageBackground)
						.maskImage(.url(#path("/assets/check.svg")))
				}
		}

	private static var rootStyle: Style {
		Style()
			.proseBlockMargin()
			.children("ol") {
				$0
					.counterReset(Counters.step)
					.margin(.zero)
					.padding(.zero)
					.children("li") {
						$0
							.counterIncrement(Counters.step)
							.display(.block)
							.position(.relative)
							.margin(.zero)
							.padding(top: .zero, horizontal: .zero, bottom: .rootEm(1.75))
							.padding(.leading, .rootEm(3))
							// The step that a link goes to, like `#with-dato-step-2`, is highlighted for a moment, like a heading (``HTMLFragment/addingStepLinks(headingID:)``).
							.cornerRadius(.rootEm(0.125))
							.target {
								$0.targetHighlight(.headingTargetHighlight)
							}
							// The number in a circle as high as a line of the text, so it lines up with the first line.
							.before {
								$0
									.content(counter: Counters.step, style: .decimal)
									.position(.absolute)
									.top(.zero)
									.leading(.zero)
									.frame(size: .lineHeight(1))
									.cornerRadius(.circle)
									.background(.accentMark.opacity(0.14))
									.fontFamily(.rounded)
									.bold()
									.monospacedDigit()
									.textAlign(.center)
									.color(.accentMark)
							}
							// The line from the circle to the next one, so the items read as steps in order. It touches both circles, so the steps are one rail, also when a step is one line and the line is short. The next circle is at the top of the next item, so the line goes to the bottom of this one, with its padding.
							.after {
								$0
									.content("")
									.position(.absolute)
									.top(.length(.lineHeight(1)))
									.bottom(.zero)
									.leading(.length(.lineHeight(0.5) - .pixels(1)))
									.frame(width: .pixels(2))
									.cornerRadius(.capsule)
									.background(.accentMark.opacity(0.14))
							}
							.lastChild {
								$0
									.padding(.bottom, .zero)
									.after {
										$0.display(.none)
									}
							}
							.children("ul") {
								$0
									.detailsList()
									.secondaryText(.body)
							}
					}
			}
	}
}

/**
A list of years with the changes of each, as a timeline, like `@Changelog { - 2014 }` with a nested `- Added: Awesome`. The kind before the colon of a change, like “Added”, becomes a badge. A change can also have no kind. Only the changes, the second level of the list, can have a kind.
*/
@Sendable
private func renderChangelog(content: HTMLFragment) -> HTMLFragment {
	content.listDirective(style: ChangelogStyles.root)
}

/**
The list of `@Changelog` with the kind at the start of each change, like “Added: ”, as a badge (``ChangeKind``). Only the changes, the second level of the list, can have a kind, so a year or a nested note, like “Note: …”, stays text.

- Parameter content: One bulleted list, the years, which the renderer checked (`.unorderedList`).
*/
@Sendable
private func addingChangeBadges(to content: [any BlockMarkup]) throws(ContentError) -> [any BlockMarkup] {
	try content.map { (block: any BlockMarkup) throws(ContentError) -> any BlockMarkup in
		guard var years = block as? UnorderedList else {
			return block
		}

		years.setListItems(try years.listItems.map { (year: ListItem) throws(ContentError) in
			var year = year
			year.setBlockChildren(try year.blockChildren.map { (child: any BlockMarkup) throws(ContentError) -> any BlockMarkup in
				guard var changes = child as? UnorderedList else {
					return child
				}

				changes.setListItems(try changes.listItems.map(ChangeKind.addingBadge(to:)))
				return changes
			})
			return year
		})
		return years
	}
}

/**
The kinds of changes of `@Changelog`, like in a changelog of software. The raw value is the word in the Markdown, like “Added”.
*/
private enum ChangeKind: String, CaseIterable {
	case added = "Added"
	case changed = "Changed"
	case fixed = "Fixed"
	case removed = "Removed"
	case deprecated = "Deprecated"

	/**
	A capitalized word and a colon at the start of a change, like “Added: ”, which must be a kind.
	*/
	nonisolated(unsafe) private static let prefix = #/^([A-Z][a-z]+): /#

	/**
	The change with its kind as a badge, or the change as it is without a kind. A capitalized word and a colon that is not a kind is an error, as it is likely a typo, like “Add: ”, and so is a kind in another case, like “added: ”.

	Limitation: the text after the kind is a new node, so a problem in it, like an invalid keyboard shortcut, is reported at the page without its line.
	*/
	static func addingBadge(to change: ListItem) throws(ContentError) -> ListItem {
		// A change of a list with blank lines between the changes is a paragraph too.
		guard
			var paragraph = change.child(at: 0) as? Paragraph,
			let text = paragraph.child(at: 0) as? Markdown.Text
		else {
			return change
		}

		// A kind in another case, like “added: ”, is not a capitalized word (``prefix``), so it would silently lose its badge.
		if let kind = allCases.first(where: { text.string.lowercased().hasPrefix("\($0.rawValue.lowercased()): ") && !text.string.hasPrefix($0.rawValue) }) {
			throw ContentError(reason: "Write the kind “\(text.string.prefix(kind.rawValue.count))” as “\(kind.rawValue)”.")
		}

		guard let match = text.string.prefixMatch(of: prefix) else {
			return change
		}

		let title = String(match.1)

		guard let kind = Self(rawValue: title) else {
			throw ContentError(reason: "“\(title)” is not a kind of change. Use \(allCases.map(\.rawValue).formattedList(.or)).")
		}

		let badge: [any InlineMarkup] = [
			InlineHTML(Badge(title, kind: kind.badgeKind).render() + " "),
			Markdown.Text(String(text.string[match.range.upperBound...])),
		]

		paragraph.setInlineChildren(badge + paragraph.inlineChildren.dropFirst())
		var change = change
		change.replaceChildrenInRange(0..<1, with: [paragraph] as [any BlockMarkup])
		return change
	}

	/**
	The color of the badge of the kind.
	*/
	var badgeKind: Badge.Kind {
		switch self {
		case .added:
			.added
		case .changed:
			.changed
		case .fixed:
			.fixed
		case .removed:
			.removed
		case .deprecated:
			.standard
		}
	}
}

/**
The styles of `@Changelog` lists, like a timeline: a line on the leading side that fades out at the oldest year, a ring at each year, and the year as a label above its changes. The newest year has a filled dot with a soft halo, like the present.
*/
enum ChangelogStyles: String, StyleSet {
	case root

	var style: Style {
		// The size of the dot of a year, and the space from its center to the changes.
		let dotSize = 0.75
		let indent = 1.75

		// The items are blocks instead of list items, so they have no bullets.
		return Style()
			.proseBlockMargin()
			.children("ul") {
				$0
					.position(.relative)
					.margin(.zero)
					.padding(.zero)
					.padding(.leading, .rootEm(indent))
					// The line, through the centers of the dots, from the newest year.
					.before {
						$0
							.content("")
							.position(.absolute)
							.top(.rootEm(dotSize))
							.bottom(.zero)
							.leading(.length(.rootEm(dotSize / 2) - .pixels(1)))
							.frame(width: .pixels(2))
							.cornerRadius(.capsule)
							.backgroundImage(
								.linearGradient(
									.toBottom,
									Color.accentMark.opacity(0.3).at(.percent(0)),
									Color.accentMark.opacity(0.3).at(.percent(90)),
									Color.transparent.at(.percent(100))
								)
							)
					}
					.children("li") {
						$0
							.display(.block)
							.position(.relative)
							.margin(.zero)
							.padding(.bottom, .rootEm(2.25))
							// The year.
							.fontFamily(.rounded)
							.textStyle(.headline, weight: .bold)
							.monospacedDigit()
							.color(.primaryText)
							.lastChild {
								$0.padding(.bottom, .zero)
							}
							// The ring of the year, in the middle of the first line, with a gap of the page color around it, so it stands apart from the line.
							.before {
								$0
									.content("")
									.position(.absolute)
									.top(.length(.lineHeight(0.5) - .rootEm(dotSize / 2)))
									.leading(.rootEm(-indent))
									.frame(size: .rootEm(dotSize))
									.cornerRadius(.circle)
									.border(.accentMark, width: .pixels(2))
									.background(.pageBackground)
									.shadow(BoxShadow(y: .zero, spread: .pixels(4), color: .pageBackground))
							}
							.firstChild {
								$0.before {
									$0
										.background(.accentMark)
										.shadow(BoxShadow(y: .zero, spread: .pixels(3), color: .pageBackground), BoxShadow(y: .zero, spread: .pixels(7), color: .accentMark.opacity(0.2)))
								}
							}
							.children("ul") {
								$0
									.detailsList()
									.fontFamily(.system)
									.textStyle(.body, weight: .regular)
									// Not the letter spacing and the digits of the year.
									.letterSpacing(.zero)
									.fontVariantNumeric([])
									.color(.bodyText)
									// The badge hangs on the leading side, so the lines of a long change start after it, also on phones. The text starts 0.75 after the badge.
									.children("li") {
										$0
											.position(.relative)
											.padding(.leading, .rootEm(5.75))
											// The paragraph of a change in a list with blank lines, so it lines up with its badge like the others.
											.children("p") {
												$0.margin(.zero)
											}
									}
									// The badges have the same width, so the changes line up. The middle of the badge is in the middle of the capital letters of the first line, which is a little below the middle of the line (1.55rem high), whatever the size of the badge.
									.nested(Badge.Styles.root.selector) {
										$0
											.position(.absolute)
											.top(.rootEm(0.79))
											.offset(y: .percent(-50))
											.leading(.zero)
											.frame(width: .rootEm(5))
											.textAlign(.center)
									}
							}
					}
			}
	}
}

/**
A calendar date as an argument of a block directive, like `from: 2026-11-27`: a date of SOML, written without quotes, like in frontmatter. An argument of a directive is always text, also with quotes, so the date is read from the text.
*/
struct DirectiveDate: Decodable, Sendable {
	let date: SOML.Date

	init(from decoder: any Decoder) throws {
		let container = try decoder.singleValueContainer()
		let text = try container.decode(String.self)

		guard case .date(let date)? = try? SOML.Value(parsingValue: text) else {
			throw DecodingError.dataCorruptedError(in: container, debugDescription: "Expected a date, like 2026-11-27, but found “\(text)”.")
		}

		self.date = date
	}
}

/**
The arguments of `@Scheduled(from: 2026-11-27, until: 2026-11-30) { … }`, or with the name of a sale, `@Scheduled(from: 2026-11-27, until: 2026-11-30, sale: "Black Friday") { … }`.

The directive shows its content only in a build from the first day through the last day, and nothing before or after, like the text of a sale. So the text shows and goes away by itself at the nightly build. The content is always rendered, so a mistake that the renderer finds, like an unknown directive or a relative link to a file that does not exist, is found before the first day, and the ID of a heading in it must be unique on the page, also while the page does not show it. Its links to other pages and to sections are always checked too, as the build checks the links of the Markdown of each page of `content/pages`, not only the links of the published page (``Site/build(project:output:externalData:buildDate:isPreview:onPublished:)``). So a wrong link does not first fail the build of the first day.

Limitation: the days are days in UTC, and the text changes at the next build, not at an exact hour. The content must not have footnotes or inline notes, as their popovers stay on the page while the block is not shown. A link to a heading in the block only works while the page shows it, so it is a broken link on the other days, also when the link is in the block itself. A link in raw HTML in the block is only checked while the page shows it.
*/
@Frontmatter
struct ScheduledArguments {
	/**
	The first day that the page shows the content.
	*/
	var from: DirectiveDate

	/**
	The last day that the page shows the content.
	*/
	var until: DirectiveDate

	/**
	The name of the sale, like `sale: "Black Friday"`, when the content is the text of a sale. Then the page of each paid and active app that the content links to, like `[Dato](/dato)` or its product on Gumroad, shows a note about the sale on the same days, with a link to the page of the block (``Sale``). A free or archived app gets no note. Before the first day, the page shows the name and the dates of the sale in place of the content (``saleAnnouncement(on:)``).
	*/
	@PlainText var sale: String?

	func validate(into problems: inout FrontmatterProblems<Self>) {
		if until.date < from.date {
			problems.add("`until` must not be before `from`.", at: .until)
		}
	}

	/**
	Whether a build on the day shows the content.
	*/
	func contains(_ day: SOML.Date) -> Bool {
		from.date <= day && day <= until.date
	}

	/**
	What the page shows before the first day of a sale, in place of the content, like “The sale runs from November 27 to November 30. The apps and the discounts show here when it starts.”, or “The sale is on November 27. …” for a sale of one day, so a visitor who comes early knows when to come back. The page shows it in an alert with the name of the sale as its title, and the Markdown copy with the name in bold before it, so the sentence does not repeat the name. It is `nil` for a block without a `sale` name, and from the first day.
	*/
	func saleAnnouncement(on day: SOML.Date) -> String? {
		guard
			day < from.date,
			sale != nil
		else {
			return nil
		}

		let firstDay = from.date.foundationDate.formatted(.siteDayWithoutYear)
		let days = from.date == until.date ? "is on \(firstDay)" : "runs from \(firstDay) to \(until.date.foundationDate.formatted(.siteDayWithoutYear))"

		return "The sale \(days). The apps and the discounts show here when it starts."
	}
}

/**
The social links of the author, the same links as the footer, as chips with icons, like `@SocialLinks`. It has no content.
*/
@Sendable
private func renderSocialLinks(content: HTMLFragment) -> HTMLFragment {
	ul {
		for link in Site.author.socialLinks {
			li {
				ProfileLink(profile: link, iconSize: .rootEm(1))
					.style(SocialLinksStyles.link)
			}
			.style(SocialLinksStyles.item)
		}
	}
	.style(SocialLinksStyles.root)
	.renderFragment()
}

/**
The styles of `@SocialLinks`.
*/
private enum SocialLinksStyles: String, StyleSet {
	case root
	case item
	case link

	var style: Style {
		switch self {
		case .root:
			Style()
				.hstack(spacing: .rootEm(0.5))
				.flexWrap()
				// The space of a block, like the cards, so the links are apart from the text above them.
				.proseBlockMargin()
				.padding(.zero)
		// A flex container, so it has no bullet.
		case .item:
			Style()
				.display(.flex)
				.margin(.zero)
				.padding(.zero)
		case .link:
			// The chips with icons have a little less padding than other chips, so all the links fit on one line next to the prose.
			Style().chip(hasIcon: true)
		}
	}
}

extension Style {
	/**
	The nested list of an item of a block directive, like the details of a card or a step, or the changes of a year: no bullets, in a column, a little below the item.
	*/
	fileprivate func detailsList() -> Self {
		plainList()
			.vstack(spacing: .rootEm(0.5))
			.margin(top: .rootEm(0.625), horizontal: .zero, bottom: .zero)
	}

	/**
	The size and the place of the icon before the text of a link (``SiteKit/MarkdownDocument/Options/linkIcon``): about as large as the capital letters, on the baseline, so the line keeps its height, with more space before it than a space between words, so the icon does not touch the word before the link.
	*/
	fileprivate func linkIconPlacement() -> Self {
		frame(size: .em(1.1))
			.verticalAlign(.em(-0.18))
			.margin(.leading, .em(0.2))
			.margin(.trailing, .em(0.3))
	}
}
