import Elementary
import Foundation
import Markdown
import SiteKit

extension MarkdownDocument.Options {
	/**
	The site's classes, and no other options. For short texts, like frontmatter fields.
	*/
	static let site = Self(theme: .site)

	/**
	The options for a content file: the site's classes, the known heading directives, links to other content files (`[Dato](dato.md)`), the sizes of local images, platform badges, the block directives, footnotes in popovers, and code blocks as `CodeBlock`, with a copy button and Swift highlighting.

	- Parameter sponsorTiers: The sponsors from the frontmatter, which `@Sponsors` shows.
	*/
	static func content(_ file: MarkdownFile, project: Project, sponsorTiers: [MarkdownPage.SponsorTier] = []) -> Self {
		var options = Self(
			theme: .site,
			headingDirectives: FAQDirectives.all,
			inlineAttributes: .init(render: renderPlatformBadge),
			blockDirectives: contentBlockDirectives,
			resolveLink: { destination in
				try file.resolvingLink(destination, project: project)
			},
			imageSize: { source in
				source.hasPrefix("/") ? project.publicFile(RoutePath(source)).mediaSize : nil
			},
			showsFootnotesInPopovers: true,
			codeBlock: CodeBlock.render
		)

		if !sponsorTiers.isEmpty {
			options.blockDirectives["Sponsors"] = .init { _ in
				SponsorList(tiers: sponsorTiers).render()
			}
		}

		return options
	}

	/**
	The Markdown of content files without a file, for the samples in the gallery: platform badges, the block directives, collapsible sections for level 3 headings, like the questions of an FAQ, links that copy the URL of a section, footnotes in popovers, and code blocks as `CodeBlock`, with a copy button and Swift highlighting.
	*/
	static let gallery = Self(
		theme: .site,
		collapsibleSections: MarkdownDocument.CollapsibleSections(level: 3, name: "gallery"),
		addsHeadingAnchors: true,
		inlineAttributes: .init(render: renderPlatformBadge),
		blockDirectives: contentBlockDirectives,
		showsFootnotesInPopovers: true,
		codeBlock: CodeBlock.render
	)

	/**
	The block directives of content files.
	*/
	private static let contentBlockDirectives: [String: BlockDirectiveRenderer] = [
		"Details": .init(render: renderDetails),
		"Feature": .init(render: renderFeature),
		"QuickAnswer": .init(render: renderQuickAnswer),
		"Trial": .init(render: renderTrial),
		"Tips": .init(render: renderTips),
		"Cards": .init(render: renderCards),
		"Steps": .init(render: renderSteps),
		"Changelog": .init(render: renderChangelog),
		"SocialLinks": .init(render: renderSocialLinks),
	]

	/**
	The questions below the “Frequently Asked Questions” heading of an app page are collapsible, followed by a link to the general FAQ. Each section has a link that copies its URL. The common questions that apply to the app (``CommonQuestion``) and, unless the app is archived, the feedback question are added to the questions, and the older versions get their section.
	*/
	static func appPage(_ file: MarkdownFile, project: Project, frontmatter: App.Frontmatter) -> Self {
		var options = content(file, project: project)
		options.collapsibleSections = MarkdownDocument.CollapsibleSections(level: 3, startHeadingID: App.faqSectionID, name: "faq", moreLink: .init(title: "More FAQs", url: RoutePath.faq.description))
		options.addsHeadingAnchors = true
		options.rewrite = { document in
			let document = document.addingCommonQuestions(CommonQuestion.questions(for: frontmatter))

			// An archived app gets no support, and the feedback page does not list it.
			return (frontmatter.isArchived ? document : document.addingFeedbackQuestion(appTitle: frontmatter.title))
				.addingOlderVersions(frontmatter.olderVersions, isPaid: frontmatter.isPaid)
		}
		return options
	}

	/**
	Every question of the general FAQ is collapsible, and each has a link that copies its URL. Only this page can mark questions as useful for every app (`<!-- @faq.general -->`), which the feedback page suggests.
	*/
	static func faqPage(_ file: MarkdownFile, project: Project) -> Self {
		var options = content(file, project: project)
		options.headingDirectives.append(FAQDirectives.General.self)
		options.collapsibleSections = MarkdownDocument.CollapsibleSections(level: 3, name: "faq")
		options.addsHeadingAnchors = true
		return options
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
private struct DetailsArguments {
	/**
	Inline Markdown.
	*/
	@NonEmpty var summary: String
}

/**
A collapsible section, like `@Details(summary: "Why?") { … }`, with the look of the FAQ questions.
*/
@Sendable
private func renderDetails(arguments: DetailsArguments, contentHTML: String) -> String {
	MarkdownTheme.site.collapsibleSection(titleHTML: MarkdownDocument(parsing: arguments.summary, options: .site).inlineHTML, contentHTML: contentHTML)
}

/**
The arguments of `@Feature(title: "Open links in the right browser") { … }`.
*/
@Frontmatter
private struct FeatureArguments {
	/**
	Inline Markdown.
	*/
	@NonEmpty var title: String
}

/**
A main feature of an app, like `@Feature(title: "Open links in the right browser") { … }`: a section with a numbered title, like “01”, so a few main features stand out from the rest of the page.
*/
@Sendable
private func renderFeature(arguments: FeatureArguments, contentHTML: String) -> String {
	section {
		h2 {
			HTMLRaw(MarkdownDocument(parsing: arguments.title, options: .site).inlineHTML)
		}
		.style(FeatureSectionStyles.title)

		HTMLRaw(contentHTML)
	}
	.style(FeatureSectionStyles.root)
	.render()
}

/**
The styles of `@Feature` sections. The sections of a page are numbered in order with a CSS counter.
*/
enum FeatureSectionStyles: StyleSet {
	case root
	case title

	var style: Style {
		switch self {
		case .root:
			// The margin separates the last section from the content after it. Between sections, it collapses into the larger top margin of the next title.
			Style()
				.counterIncrement("feature")
				.margin(.bottom, .rootEm(4))
		case .title:
			// The number is in the accent of the page, like the color of the icon on an app page.
			Style()
				.before {
					$0
						.content(counter: "feature", style: .decimalLeadingZero)
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
The short answer at the top of a how-to post, like `@QuickAnswer { Hold Fn and click the link. }`, in a box with a “Quick Answer” label, for readers who only want the answer.
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
enum QuickAnswerStyles: StyleSet {
	case root
	case label

	var style: Style {
		switch self {
		case .root:
			Style()
				.proseCard()
				.color(.primaryText)
		case .label:
			Style()
				.display(.inlineBlock)
				.margin(.bottom, .rootEm(0.75))
				.padding(vertical: .rootEm(0.125), horizontal: .rootEm(0.625))
				.cornerRadius(.capsule)
				.font(size: .rootEm(0.8125), lineHeight: 1.5)
				.fontWeight(.semibold)
				.color(.link)
				.background(.primary(500).opacity(0.1))
		}
	}
}

/**
The arguments of `@Trial(url: "https://example.com/App-trial.zip") { … }`.
*/
@Frontmatter
private struct TrialArguments {
	@Absolute var url: URL

	/**
	The text of the button, like “Try on TestFlight”. Defaults to “Download Free Trial”.
	*/
	@NonEmpty var title: String?
}

/**
The trial of an app, like `@Trial(url: "https://example.com/App-trial.zip") { The only limitation is … }`: a card with the text and a download button. It goes below the “Trial” heading, which the “Free Trial” button of the app links to, so the card is highlighted when the visitor comes from there.
*/
@Sendable
private func renderTrial(arguments: TrialArguments, contentHTML: String) -> String {
	// Not an aside, as the trial is part of the page about the app.
	div {
		HTMLRaw(contentHTML)

		Link(arguments.title ?? "Download Free Trial", destination: .url(arguments.url))
			.buttonStyle()
	}
	.style(TrialStyles.root)
	.render()
}

/**
The styles of `@Trial` cards.
*/
enum TrialStyles: StyleSet {
	case root

	var style: Style {
		Style()
			.vstack(alignment: .start, spacing: .rootEm(1.25))
			.proseCard()
			.widerThanProse()
			.nested(":target + &") {
				$0.targetHighlight()
			}
	}
}

/**
A box of tips, like `@Tips { - Tip }`, with the look of a tip alert.
*/
@Sendable
private func renderTips(contentHTML: String) -> String {
	MarkdownTheme.site.alert(.tip, title: "Tips", contentHTML: contentHTML)
}

/**
A list as cards, like `@Cards { - Focus is a feature }`, so a list of short points is easy to scan. The text of each item is the title of its card, and a nested list is smaller text below it. From tablets, the cards flow through two columns, so cards of different heights fit together.
*/
@Sendable
private func renderCards(contentHTML: String) -> String {
	div {
		HTMLRaw(contentHTML)
	}
	.style(CardListStyles.root)
	.render()
}

/**
The styles of `@Cards` lists.
*/
enum CardListStyles: StyleSet {
	case root

	var style: Style {
		// The items are blocks instead of list items, so they have no bullets.
		Style()
			.margin(vertical: ProseStyles.blockSpacing, horizontal: 0)
			.children("ul") {
				$0
					.margin(0)
					.padding(0)
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
							.margin(top: 0, horizontal: 0, bottom: .rootEm(1))
							.padding(vertical: .rootEm(1.125), horizontal: .rootEm(1.25))
							.cardSurface(isInteractive: false)
							.keepsTogether()
							.textStyle(.body, weight: .semibold)
							.color(.primaryText)
							.children("ul") {
								$0
									.vstack(spacing: .rootEm(0.5))
									.margin(top: .rootEm(0.625), horizontal: 0, bottom: 0)
									.padding(0)
									.secondaryText()
									.fontWeight(.regular)
									.children("li") {
										$0
											.display(.block)
											.margin(0)
											.padding(0)
									}
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
		HTMLRaw(contentHTML)
	}
	.style(StepListStyles.root)
	.render()
}

/**
The styles of `@Steps` lists. The items are numbered with a CSS counter, like `@Feature` sections, as items that are not list items have no markers.
*/
enum StepListStyles: StyleSet {
	case root

	var style: Style {
		Style()
			.margin(vertical: ProseStyles.blockSpacing, horizontal: 0)
			.children("ol") {
				$0
					.counterReset("step")
					.margin(0)
					.padding(0)
					.children("li") {
						$0
							.counterIncrement("step")
							.display(.block)
							.position(.relative)
							.margin(0)
							.padding(top: 0, horizontal: 0, bottom: .rootEm(1.75))
							.padding(.leading, .rootEm(3))
							// The number in a circle as high as a line of the text, so it lines up with the first line.
							.before {
								$0
									.content(counter: "step", style: .decimal)
									.position(.absolute)
									.top(0)
									.leading(0)
									.frame(width: .lineHeight(1), height: .lineHeight(1))
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
									.top(.lineHeight(1) + .rootEm(0.375))
									.bottom(.rootEm(0.375))
									.leading(.lineHeight(0.5) - .pixels(1))
									.frame(width: .pixels(2))
									.cornerRadius(.circle)
									.background(.accentMark.opacity(0.14))
							}
							.lastChild {
								$0
									.padding(.bottom, 0)
									.after {
										$0.display(.none)
									}
							}
							.children("ul") {
								$0
									.margin(top: .rootEm(0.25), horizontal: 0, bottom: 0)
									.padding(0)
									.secondaryText(.body)
									.children("li") {
										$0
											.display(.block)
											.margin(0)
											.padding(0)
									}
							}
					}
			}
	}
}

/**
A list of years with the changes of each, as a timeline, like `@Changelog { - 2014 }` with a nested `- Added: Awesome`. The kind before the colon of a change, like “Added”, becomes a badge. A change can also have no kind. Only the changes, the second level of the list, can have a kind.
*/
@Sendable
private func renderChangelog(contentHTML: String) throws -> String {
	// A change of a list with blank lines between the changes is in a paragraph.
	let html = try contentHTML.replacing(#/(<li>(?:\s*<p>)?)([A-Z][a-z]+): /#) { match in
		let title = String(match.2)

		guard let kind = changelogKinds[title] else {
			throw ContentError(reason: "“\(title)” is not a kind of change. Use \(changelogKinds.keys.sorted().formatted(.list(type: .or))).")
		}

		return match.1 + Badge(title, kind: kind).render() + " "
	}

	return div {
		HTMLRaw(html)
	}
	.style(ChangelogStyles.root)
	.render()
}

/**
The kinds of changes of `@Changelog`, like in a changelog of software, and the color of each.
*/
private let changelogKinds: [String: Badge.Kind] = [
	"Added": .added,
	"Changed": .changed,
	"Fixed": .fixed,
	"Removed": .removed,
	"Deprecated": .standard,
]

/**
The styles of `@Changelog` lists, like a timeline: a line on the leading side that fades out at the oldest year, a ring at each year, and the year as a label above its changes. The newest year has a filled dot with a soft halo, like the present.
*/
enum ChangelogStyles: StyleSet {
	case root

	var style: Style {
		// The size of the dot of a year, and the space from its center to the changes.
		let dotSize = 0.75
		let indent = 1.75

		// The items are blocks instead of list items, so they have no bullets.
		return Style()
			.margin(vertical: ProseStyles.blockSpacing, horizontal: 0)
			.children("ul") {
				$0
					.position(.relative)
					.margin(0)
					.padding(0)
					.padding(.leading, .rootEm(indent))
					// The line, through the centers of the dots, from the newest year.
					.before {
						$0
							.content("")
							.position(.absolute)
							.top(.rootEm(dotSize))
							.bottom(0)
							.leading(.rootEm(dotSize / 2) - .pixels(1))
							.frame(width: .pixels(2))
							.cornerRadius(.circle)
							.backgroundImage(.linearGradient("to bottom", Color.accentMark.opacity(0.3).at(.percent(0)), Color.accentMark.opacity(0.3).at(.percent(90)), Color.transparent.at(.percent(100))))
					}
					.children("li") {
						$0
							.display(.block)
							.position(.relative)
							.margin(0)
							.padding(.bottom, .rootEm(2.25))
							// The year.
							.fontFamily(.rounded)
							.textStyle(.headline, weight: .bold)
							.monospacedDigit()
							.color(.primaryText)
							.lastChild {
								$0.padding(.bottom, 0)
							}
							// The ring of the year, in the middle of the first line, with a gap of the page color around it, so it stands apart from the line.
							.before {
								$0
									.content("")
									.position(.absolute)
									.top(.lineHeight(0.5) - .rootEm(dotSize / 2))
									.leading(.rootEm(-indent))
									.frame(width: .rootEm(dotSize), height: .rootEm(dotSize))
									.cornerRadius(.circle)
									.border(.accentMark, width: .pixels(2))
									.background(.pageBackground)
									.shadow(Shadow(y: 0, spread: .pixels(4), color: .pageBackground))
							}
							.firstChild {
								$0.before {
									$0
										.background(.accentMark)
										.shadow(Shadow(y: 0, spread: .pixels(3), color: .pageBackground), Shadow(y: 0, spread: .pixels(7), color: .accentMark.opacity(0.2)))
								}
							}
							.children("ul") {
								$0
									.vstack(spacing: .rootEm(0.5))
									.margin(top: .rootEm(0.625), horizontal: 0, bottom: 0)
									.padding(0)
									.fontFamily(.system)
									.textStyle(.body, weight: .regular)
									.color(.bodyText)
									// The badge hangs on the leading side, so the lines of a long change start after it, also on phones. The text starts 0.75 after the badge.
									.children("li") {
										$0
											.display(.block)
											.position(.relative)
											.margin(0)
											.padding(0)
											.padding(.leading, .rootEm(5.75))
											// The paragraph of a change in a list with blank lines, so it lines up with its badge like the others.
											.children("p") {
												$0.margin(0)
											}
									}
									// The badges have the same width, so the changes line up. In the middle of the first line.
									.nested(Badge.Styles.root.selector) {
										$0
											.position(.absolute)
											.top(.em(0.3))
											.leading(0)
											.frame(width: .rootEm(5))
											.textAlign(.center)
									}
							}
					}
			}
	}
}

/**
The social links of the author, the same links as the footer, as chips with icons, like `@SocialLinks`. It has no content.
*/
@Sendable
private func renderSocialLinks(contentHTML: String) throws -> String {
	guard contentHTML.isEmpty else {
		throw ContentError(reason: "It takes no content, as it shows the social links of the author.")
	}

	return ul {
		for link in Site.author.socialLinks {
			li {
				a(.href(.url(link.url)), .rel("me")) {
					link.icon.size(.rootEm(1))
					link.name
				}
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
enum SocialLinksStyles: StyleSet {
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
				.margin(vertical: ProseStyles.blockSpacing, horizontal: 0)
				.padding(0)
		// A flex container, so it has no bullet.
		case .item:
			Style()
				.display(.flex)
				.margin(0)
				.padding(0)
		case .link:
			Style()
				.chip()
				// A little less padding than other chips, so all the links fit on one line next to the prose.
				.padding(.horizontal, .rootEm(0.75))
				.hstack(alignment: .center, spacing: .rootEm(0.375))
				.underline(false)
		}
	}
}

/**
A question that many apps have, like “Can you localize the app into my language?”. The build adds it to the FAQ section of each app that it applies to, so the app files do not repeat it. A file that has a question with the same text in its FAQ section keeps its own answer, like one with more details about the app.
*/
private struct CommonQuestion {
	let title: String
	let answer: Paragraph

	/**
	Whether the question goes before the questions of the file instead of after them, as visitors with a problem look for it. The feedback question still goes first.
	*/
	var isFirst = false

	/**
	The ID of the heading, instead of the slug of the title, for a question that code finds.
	*/
	var id: String?

	/**
	The question and its answer, as a level 3 heading and a paragraph, like the questions in the files.
	*/
	var blocks: [any BlockMarkup] {
		[Markdown.Heading(level: 3, Markdown.Text(title + (id.map { " {#\($0)}" } ?? ""))), answer]
	}

	/**
	The questions that apply to the app: the menu bar question for menu bar apps, the free question for free apps on the App Store that are not archived, and the localization question for all apps.
	*/
	static func questions(for frontmatter: App.Frontmatter) -> [Self] {
		var questions = [Self]()

		if frontmatter.isMenuBarApp {
			questions.append(Self(
				title: "The app does not show up in the menu bar",
				answer: Paragraph(Markdown.Link(destination: LinkDestination.menuBarQuestion.description, Markdown.Text("How to make the app show up in the menu bar"))),
				isFirst: true,
				id: App.addedMenuBarQuestionID
			))
		}

		// The answer asks for a review on the App Store, so archived apps and apps that are not there do not get it.
		if
			!frontmatter.isPaid,
			!frontmatter.isArchived,
			frontmatter.appStoreID != nil
		{
			questions.append(Self(
				title: "Why is this free without ads?",
				answer: Paragraph(Markdown.Text("I just enjoy making apps. Consider leaving a nice review on the App Store."))
			))
		}

		questions.append(Self(
			title: "Can you localize the app into my language?",
			answer: Paragraph(Markdown.Text("I don’t plan to localize the app."))
		))

		return questions
	}
}

extension [any BlockMarkup] {
	/**
	The blocks of the FAQ section of an app page, after its heading. `nil` when the page has no FAQ section.
	*/
	fileprivate var faqSection: Range<Int>? {
		guard let headingIndex = firstIndex(where: { block in
			guard let heading = block as? Markdown.Heading else {
				return false
			}

			// The custom ID is still in the text, as the IDs are read while rendering.
			return heading.level == 2 && heading.plainText.hasSuffix("{#\(App.faqSectionID)}")
		}) else {
			return nil
		}

		let start = headingIndex + 1
		return start..<(self[start...].firstIndex { (($0 as? Markdown.Heading)?.level ?? 3) <= 2 } ?? endIndex)
	}

	/**
	Where the questions of the FAQ section start: at its first heading, after any text under the FAQ heading. `nil` when the page has no FAQ section.
	*/
	fileprivate var faqQuestionsStart: Int? {
		faqSection.map { section in
			self[section].firstIndex { $0 is Markdown.Heading } ?? section.upperBound
		}
	}
}

extension Document {
	/**
	Adds the common questions that the FAQ section does not have yet: the first ones before the other questions, and the rest after them.
	*/
	fileprivate func addingCommonQuestions(_ questions: [CommonQuestion]) -> Document {
		var blocks = Array(blockChildren)

		guard
			let section = blocks.faqSection,
			let questionsStart = blocks.faqQuestionsStart
		else {
			return self
		}

		let existingTitles = Set(blocks[section].compactMap { ($0 as? Markdown.Heading)?.plainText.removingCustomHeadingID })
		let newQuestions = questions.filter { !existingTitles.contains($0.title) }
		// The later position first, so the earlier one stays the same.
		blocks.insert(contentsOf: newQuestions.filter { !$0.isFirst }.flatMap(\.blocks), at: section.upperBound)
		blocks.insert(contentsOf: newQuestions.filter(\.isFirst).flatMap(\.blocks), at: questionsStart)

		return Document(blocks)
	}

	/**
	Adds the feedback question to the FAQ section, or adds the answer to an existing question with the same title.
	*/
	fileprivate func addingFeedbackQuestion(appTitle: String) -> Document {
		var blocks = Array(blockChildren)

		guard let section = blocks.faqSection else {
			return self
		}

		let answer = Paragraph(
			Markdown.Text("Click the feedback button in the app or "),
			Markdown.Link(destination: App.feedbackURL(appTitle: appTitle, referrer: "Website-FAQ").absoluteURL.absoluteString, Markdown.Text("send it here."))
		)

		let customID = Markdown.Text(" {#\(App.feedbackHeadingID)}")

		if let questionIndex = blocks[section].firstIndex(where: { block in
			guard let heading = block as? Markdown.Heading else {
				return false
			}

			return heading.level == 3 && heading.plainText.removingCustomHeadingID == App.feedbackQuestionTitle
		}), let question = blocks[questionIndex] as? Markdown.Heading {
			// The question gets the feedback ID instead of its own.
			let content = question.inlineChildren.map { child -> any InlineMarkup in
				guard let text = child as? Markdown.Text else {
					return child
				}

				return Markdown.Text(text.string.removingCustomHeadingID)
			}

			blocks[questionIndex] = Markdown.Heading(level: question.level, content + [customID])

			// After the directives of the question, which must be directly below it.
			let answerIndex = blocks[(questionIndex + 1)...].firstIndex { !(($0 as? HTMLBlock)?.isOnlyDirectives ?? false) } ?? blocks.endIndex
			blocks.insert(answer, at: answerIndex)
		} else {
			let question = Markdown.Heading(level: 3, [Markdown.Text(App.feedbackQuestionTitle), customID])
			blocks.insert(contentsOf: [question, answer] as [any BlockMarkup], at: blocks.faqQuestionsStart ?? section.lowerBound)
		}

		return Document(blocks)
	}

	/**
	Adds the “Older Versions” section before the “Non-App Store Version” section, or at the end.
	*/
	fileprivate func addingOlderVersions(_ olderVersions: [App.OlderVersion], isPaid: Bool) -> Document {
		guard !olderVersions.isEmpty else {
			return self
		}

		var blocks = Array(blockChildren)

		let nonAppStoreVersionIndex = blocks.firstIndex { block in
			guard let heading = block as? Markdown.Heading else {
				return false
			}

			return heading.level == 2 && heading.plainText == App.nonAppStoreVersionTitle
		}

		blocks.insert(contentsOf: olderVersions.markdownSection(isPaid: isPaid), at: nonAppStoreVersionIndex ?? blocks.endIndex)
		return Document(blocks)
	}
}

extension [App.OlderVersion] {
	/**
	The “Older Versions” section of an app page.

	The versions of paid apps are free, but they only run on their macOS version, so they do not say “or later” (`+`).
	*/
	func markdownSection(isPaid: Bool) -> [any BlockMarkup] {
		let items = map { olderVersion in
			ListItem(Paragraph(
				Markdown.Link(destination: olderVersion.url.absoluteString, Markdown.Text(olderVersion.version)),
				Markdown.Text(" for macOS \(olderVersion.macOS.rawValue)\(isPaid ? "" : "+")")
			))
		}

		var section: [any BlockMarkup] = [
			Markdown.Heading(level: 2, Markdown.Text("Older Versions")),
			UnorderedList(items),
		]

		if isPaid {
			section.append(Paragraph(Markdown.Text("These are free for everyone but they will not run on newer macOS versions.")))
		}

		return section
	}
}
