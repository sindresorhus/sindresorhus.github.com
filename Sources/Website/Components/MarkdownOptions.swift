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
		return options
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
	What content files and the samples of the gallery have: the site's classes, platform badges, the block directives, inline notes as `InlineNote`, and code blocks as `CodeBlock`, with a copy button and Swift and SOML highlighting.
	*/
	private static let contentFeatures = Self(
		theme: .site,
		inlineAttributes: .init(render: renderPlatformBadge),
		// The content directives also have examples in the gallery.
		blockDirectives: .site(),
		codeBlock: CodeBlock.render,
		inlineNote: InlineNote.render
	)

	/**
	The questions below the “Frequently Asked Questions” heading of an app page are collapsible, followed by a link to the general FAQ. A platform badge must be for a platform of the app. Each section has a link that copies its URL. The common questions that apply to the app (``CommonQuestion``), the shared questions that it picks, and, unless the app is archived, the feedback question are added to the questions, and the older versions get their section (``App/Frontmatter/addingGeneratedSections(to:sharedQuestions:renderDownloadCard:)``). A link that is alone in its paragraph or list item to one of the shortcuts is a card (``ShortcutCard``).
	*/
	static func appPage(
		_ file: MarkdownFile,
		project: Project,
		frontmatter: App.Frontmatter,
		sharedQuestions: App.SharedQuestions,
		shortcuts: [Shortcut.ID: Shortcut]
	) -> Self {
		// Download cards come from typed metadata, rather than content directives.
		var options = content(file, project: project)

		// A badge for a platform that the app is not on would say that a part works on a platform where the app is not. The arguments of the directives get the check too.
		options.inlineAttributes = .init { (attributes: PlatformBadgeAttributes, contentHTML: String) throws(ContentError) in
			guard frontmatter.platforms.contains(attributes.platform) else {
				throw ContentError(reason: "The platform badge is for \(attributes.platform.rawValue), but the app is not on it. Add it to `platforms`, or remove the badge.")
			}

			return renderPlatformBadge(attributes: attributes, contentHTML: contentHTML)
		}

		// The feedback page suggests the questions of the FAQ section. The picked shared questions have their own directives too.
		options.headingDirectives = FAQDirectives.all + [App.SharedQuestions.First.self]
		options.collapsibleSections = MarkdownDocument.CollapsibleSections(
			level: .h3,
			startHeadingID: App.Section.faq.id,
			moreLink: .init(title: "More FAQs", destination: .path(.faq))
		)
		options.addsHeadingAnchors = true
		options.rewrite = { document in
			frontmatter.addingGeneratedSections(to: document.showingShortcutCards(shortcuts), sharedQuestions: sharedQuestions) { card in
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
			.init(content: .unorderedList, render: renderCards)
		case .columns:
			.init(content: .unorderedList, render: renderColumns)
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
				SponsorList(tiers: sponsorTiers).render()
			}
		case .scheduled:
			today.map { today in
				.init { (arguments: ScheduledArguments, contentHTML: String) in
					arguments.contains(today) ? contentHTML : ""
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
private func renderPlatformBadge(attributes: PlatformBadgeAttributes, contentHTML: String) -> String {
	span {
		HTMLRaw(contentHTML)
	}
	.style(Badge.Styles.root, Badge.Kind.platform)
	.attributes(.data("platform", value: attributes.platform.rawValue))
	.render()
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
		contentHTML: String,
		context: MarkdownDocument.Options.BlockDirectiveRenderer.Context
	) throws(ContentError) -> String {
		let summary = try context.inlineDocument(parsing: arguments.summary)

		// A click on the summary opens the section, so a link in it could not be followed.
		guard summary.links.isEmpty else {
			throw ContentError(reason: "The `summary` cannot have links, as a click on it opens the section. Put the link in the section.")
		}

		return MarkdownTheme.site.collapsibleSection(titleHTML: summary.inlineHTML, contentHTML: contentHTML)
	}

	static func plainBlocks(arguments: Self, content: [any BlockMarkup]) -> [any BlockMarkup] {
		[Paragraph(Strong(inlineMarkup(arguments.summary)))] + content
	}
}

/**
The arguments of `@Feature(title: "Open links in the right browser") { … }`.
*/
@Frontmatter
struct FeatureArguments {
	/**
	Inline Markdown.
	*/
	@NonEmpty var title: String
}

/**
A main feature of an app, like `@Feature(title: "Open links in the right browser") { … }`: a section with a numbered title, like “01”, so a few main features stand out from the rest of the page.
*/
extension FeatureArguments: BlockDirectiveDefinition {
	typealias Arguments = Self
	static let name = BlockDirectiveName.feature.rawValue

	static func render(
		arguments: FeatureArguments,
		contentHTML: String,
		context: MarkdownDocument.Options.BlockDirectiveRenderer.Context
	) throws(ContentError) -> String {
		let titleHTML = try context.inlineDocument(parsing: arguments.title).inlineHTML

		return section {
			h2 {
				HTMLRaw(titleHTML)
			}
			.style(FeatureSectionStyles.title)

			HTMLRaw(contentHTML)
		}
		.style(FeatureSectionStyles.root)
		.render()
	}

	static func plainBlocks(arguments: Self, content: [any BlockMarkup]) -> [any BlockMarkup] {
		[Markdown.Heading(level: .h2, inlineMarkup(arguments.title))] + content
	}
}

/**
The styles of `@Feature` sections. The sections of a page are numbered in order with a CSS counter.
*/
private enum FeatureSectionStyles: String, StyleSet {
	case root
	case title

	enum Counters: String, CounterSet {
		case feature
	}

	var style: Style {
		switch self {
		case .root:
			// The margin separates the last section from the content after it. Between sections, it collapses into the larger top margin of the next title.
			Style()
				.counterIncrement(Counters.feature)
				.margin(.bottom, .rootEm(4))
		case .title:
			// The number is in the accent of the page, like the color of the icon on an app page. Screen readers skip it, as the title says what the section is, and “zero one” before it is noise.
			Style()
				.before {
					$0
						.content(counter: Counters.feature, style: .decimalLeadingZero, alternativeText: "")
						.display(.block)
						.margin(.bottom, .rootEm(0.75))
						.fontFamily(.rounded)
						.font(size: .rootEm(0.9375), lineHeight: 1.5)
						.fontWeight(.bold)
						.letterSpacing(.em(0.02))
						.monospacedDigit()
						.color(.accentMark)
				}
		}
	}
}

/**
The short answer at the top of a guide, like `@QuickAnswer { Hold Fn and click the link. }`, in a box with a “Quick Answer” label, for readers who only want the answer.
*/
@Sendable
private func renderQuickAnswer(contentHTML: String) -> String {
	aside {
		p {
			"Quick Answer"
		}
		.style(QuickAnswerStyles.label)

		HTMLRaw(contentHTML)
	}
	.style(QuickAnswerStyles.root)
	.render()
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
			Style()
				.proseCard()
				.color(.primaryText)
		case .label:
			// A block as wide as its text, not an inline block, so its margin and the margin of the answer below it collapse into one space, a little less than the padding of the box, so the label stays with the answer.
			Style()
				.frame(width: .fitContent)
				.margin(.bottom, .rootEm(1))
				.padding(vertical: .rootEm(0.125), horizontal: .rootEm(0.625))
				.cornerRadius(.capsule)
				.font(size: .rootEm(0.8125), lineHeight: 1.5)
				.fontWeight(.semibold)
				// Not the color of links, as it is not a link, but the darker one of links with more contrast, so the small text has enough contrast on the tint in light mode.
				.color(.lightDark(.primary(700), .primary(400)))
				.background(.primary(500).opacity(0.1))
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
							"Download it to the Downloads folder, double-click to unzip, and then move it to the "
							code(.notTranslated) {
								"/Applications"
							}
							" folder."
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
				Style()
					.vstack(alignment: .start, spacing: .rootEm(1.25))
					.proseCard()
					.backgroundImage(Self.light(strength: 0.1), dark: Self.light(strength: 0.16))
					.nested(":target + &") {
						$0.targetHighlight()
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
		The light of the accent in the top leading corner, like the light of an interactive card under the pointer.
		*/
		private static func light(strength: Double) -> CSSImage {
			.radialGradient(.circle(at: .init(x: .percent(0), y: .percent(0))), Color.pageAccent.opacity(strength).at(.percent(0)), Color.transparent.at(.percent(60)))
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

	static func render(arguments: Self, contentHTML: String, context: MarkdownDocument.Options.BlockDirectiveRenderer.Context) -> String {
		section {
			// The icons load at once, as the first one is in the first screen, and a directive does not know whether it is the first. The tiny apps page has only a few.
			AppIcon(decorative: arguments.icon ?? App.placeholderIconPath, size: 128, isAboveFold: true)
				.style(TinyAppStyles.icon)

			h2 {
				arguments.title
			}
			.style(TinyAppStyles.title)

			div {
				HTMLRaw(contentHTML)

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
							macOS.macOSRequirementSentence
						}
						.style(TinyAppStyles.requirement)
					}
				}
				.style(TinyAppStyles.actions)
			}
			.style(TinyAppStyles.text)
		}
		.style(TinyAppStyles.root)
		.render()
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

		let requirement: [any BlockMarkup] = arguments.macOS.map { [Paragraph(Emphasis(Markdown.Text($0.macOSRequirementSentence)))] } ?? []
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
				.filter(AppCard.iconShadow)
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
private func renderTips(arguments: TipsArguments, contentHTML: String) -> String {
	MarkdownTheme.site.alert(.tip, title: arguments.title ?? "Tips", contentHTML: contentHTML)
}

/**
The list of a directive, like the steps of `@Steps`, with `role="list"`, so VoiceOver in Safari still says that it is a list and how many items it has, as the styles remove its bullets. The content is the one list that the renderer checked, so the first list tag is its own.
*/
private func addingListRole(to contentHTML: String) -> String {
	contentHTML.replacing(listStartTag, maxReplacements: 1) { match in
		"<\(match.1) role=\"list\""
	}
}

/**
The start of the tag of a list, like `<ol` of `<ol start="2">`, for ``addingListRole(to:)``. Not a literal in the function, as Swift parses a regex literal each time the code runs, and it runs for each directive.
*/
nonisolated(unsafe) private let listStartTag = /<(ol|ul)\b/

/**
A list as cards, like `@Cards { - Focus is a feature }`, so a list of short points is easy to scan. The text of each item is the title of its card, and a nested list is smaller text below it. From tablets, the cards flow through two columns, so cards of different heights fit together.
*/
@Sendable
private func renderCards(contentHTML: String) -> String {
	div {
		HTMLRaw(addingListRole(to: contentHTML))
	}
	.style(CardListStyles.root)
	.render()
}

/**
A list of short items in columns, like `@Columns { - Zoom }`, so a long list of names, like the services that an app supports, does not make a narrow column several screens tall. It is opt-in, as a list of sentences reads better in one column.
*/
@Sendable
private func renderColumns(contentHTML: String) -> String {
	div {
		HTMLRaw(addingListRole(to: contentHTML))
	}
	.style(ColumnListStyles.root)
	.render()
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
					.gap(column: .rootEm(1.25))
					.children("li") {
						$0
							.keepsTogether()
							.margin(top: .zero, horizontal: .zero, bottom: .rootEm(0.25))
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
							.gap(column: .rootEm(1))
					}
					// Not a stack, so the links in the text stay in its lines. An inline block as wide as its column keeps its bottom margin in its column, as Safari otherwise moves the margin of the last card of a column to the top of the next column.
					.children("li") {
						$0
							.display(.inlineBlock)
							.frame(width: .percent(100))
							.verticalAlign(.top)
							.margin(top: .zero, horizontal: .zero, bottom: .rootEm(1))
							.padding(vertical: .rootEm(1.125), horizontal: .rootEm(1.25))
							.cardSurface(isInteractive: false)
							.keepsTogether()
							.textStyle(.body, weight: .semibold)
							.color(.primaryText)
							.children("ul") {
								$0
									.detailsList()
									.secondaryText()
									.fontWeight(.regular)
							}
					}
			}
	}
}

/**
A numbered list as steps, with each number in a circle in the accent of the page and a line to the next, like `@Steps { 1. Write down every idea }`, for a short list of steps in order, like how I make an app. A nested list is smaller text below its item.
*/
@Sendable
private func renderSteps(contentHTML: String) -> String {
	div {
		HTMLRaw(addingListRole(to: contentHTML))
	}
	.style(StepListStyles.root)
	.render()
}

/**
The styles of `@Steps` lists. The items are numbered with a CSS counter, like `@Feature` sections, as items that are not list items have no markers.
*/
enum StepListStyles: String, StyleSet {
	case root

	enum Counters: String, CounterSet {
		case step
	}

	var style: Style {
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
							// The line from the circle to the next one, so the items read as steps in order.
							.after {
								$0
									.content("")
									.position(.absolute)
									.top(.length(.lineHeight(1) + .rootEm(0.375)))
									.bottom(.rootEm(0.375))
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
									.plainList()
									.margin(top: .rootEm(0.25), horizontal: .zero, bottom: .zero)
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
private func renderChangelog(contentHTML: String) -> String {
	div {
		HTMLRaw(addingListRole(to: contentHTML))
	}
	.style(ChangelogStyles.root)
	.render()
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
	The change with its kind as a badge, or the change as it is without a kind. A capitalized word and a colon that is not a kind is an error, as it is likely a typo, like “Add: ”.

	Limitation: the text after the kind is a new node, so a problem in it, like an invalid keyboard shortcut, is reported at the page without its line.
	*/
	static func addingBadge(to change: ListItem) throws(ContentError) -> ListItem {
		// A change of a list with blank lines between the changes is a paragraph too.
		guard
			var paragraph = change.child(at: 0) as? Paragraph,
			let text = paragraph.child(at: 0) as? Markdown.Text,
			let match = text.string.prefixMatch(of: prefix)
		else {
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
									// The badges have the same width, so the changes line up. In the middle of the first line.
									.nested(Badge.Styles.root.selector) {
										$0
											.position(.absolute)
											.top(.em(0.3))
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
	The name of the sale, like `sale: "Black Friday"`, when the content is the text of a sale. Then the page of each app that the content links to, like `[Dato](/dato)` or its product on Gumroad, shows a note about the sale on the same days, with a link to the page of the block (``Sale``).
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
}

/**
The social links of the author, the same links as the footer, as chips with icons, like `@SocialLinks`. It has no content.
*/
@Sendable
private func renderSocialLinks(contentHTML: String) -> String {
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
	.render()
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
	The nested list of an item of a block directive, like the details of a card or the changes of a year: no bullets, in a column, a little below the item.
	*/
	fileprivate func detailsList() -> Self {
		plainList()
			.vstack(spacing: .rootEm(0.5))
			.margin(top: .rootEm(0.625), horizontal: .zero, bottom: .zero)
	}
}
