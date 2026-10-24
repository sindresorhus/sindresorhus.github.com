import Elementary
import Foundation
import SiteKit

extension MarkdownDocument.Options {
	/**
	The site's classes, and no other options. For short texts, like frontmatter fields.
	*/
	static let site = Self(theme: .site)

	/**
	The options for a content file: the features of ``contentFeatures``, the known heading directives, links to other content files (`[Dato](dato.md)`), and the sizes of local images.

	- Parameter sponsorTiers: The sponsors from the frontmatter, which `@Sponsors` shows.
	*/
	static func content(_ file: MarkdownFile, project: Project, sponsorTiers: [MarkdownPage.SponsorTier] = []) -> Self {
		var options = contentFeatures
		options.headingDirectives = FAQDirectives.all

		options.resolveLink = { destination in
			try file.resolvingLink(destination, project: project)
		}

		options.imageSize = { source in
			// An image from another site has no size, as it is not a file of this one, and a path from content is already checked by the link. A screenshot of a Retina display is shown at half its pixel size, so it is sharp.
			(try? RoutePath(validating: source)).flatMap { project.publicFile($0).displaySize }
		}

		if !sponsorTiers.isEmpty {
			options.blockDirectives["Sponsors"] = .init { _ in
				SponsorList(tiers: sponsorTiers).render()
			}
		}

		return options
	}

	/**
	The Markdown of content files without a file, for the samples in the gallery: the features of ``contentFeatures``, collapsible sections for level 3 headings, like the questions of an FAQ, and links that copy the URL of a section.
	*/
	static let gallery: Self = {
		var options = contentFeatures
		options.collapsibleSections = MarkdownDocument.CollapsibleSections(level: 3, name: "gallery")
		options.addsHeadingAnchors = true
		return options
	}()

	/**
	What content files and the samples of the gallery have: the site's classes, platform badges, the block directives, inline notes as `InlineNote`, and code blocks as `CodeBlock`, with a copy button and Swift and SOML highlighting.
	*/
	private static let contentFeatures = Self(
		theme: .site,
		inlineAttributes: .init(render: renderPlatformBadge),
		blockDirectives: [
			"Details": .init(render: renderDetails),
			"Feature": .init(render: renderFeature),
			"QuickAnswer": .init(render: renderQuickAnswer),
			"Trial": .init(render: renderTrial),
			"TinyApp": .init(render: renderTinyApp),
			"Tips": .init(render: renderTips),
			"Cards": .init(render: renderCards),
			"Steps": .init(render: renderSteps),
			"Changelog": .init(render: renderChangelog),
			"SocialLinks": .init(render: renderSocialLinks),
		],
		codeBlock: CodeBlock.render,
		inlineNote: InlineNote.render
	)

	/**
	The questions below the “Frequently Asked Questions” heading of an app page are collapsible, followed by a link to the general FAQ. Each section has a link that copies its URL. The common questions that apply to the app (``CommonQuestion``), the shared questions that it picks, and, unless the app is archived, the feedback question are added to the questions, and the older versions get their section (``App/Frontmatter/addingGeneratedSections(to:sharedQuestions:)``).
	*/
	static func appPage(_ file: MarkdownFile, project: Project, frontmatter: App.Frontmatter, sharedQuestions: App.SharedQuestions) -> Self {
		var options = content(file, project: project)
		options.headingDirectives.append(App.SharedQuestions.First.self)
		options.collapsibleSections = MarkdownDocument.CollapsibleSections(level: 3, startHeadingID: App.faqSectionID, name: "faq", moreLink: .init(title: "More FAQs", destination: .path(.faq)))
		options.addsHeadingAnchors = true
		options.rewrite = { document in
			frontmatter.addingGeneratedSections(to: document, sharedQuestions: sharedQuestions)
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
private enum FeatureSectionStyles: StyleSet {
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
private enum QuickAnswerStyles: StyleSet {
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
	The text of the button, like “Try on TestFlight”.
	*/
	@NonEmpty var title = "Download Free Trial"
}

/**
The trial of an app, like `@Trial(url: "https://example.com/App-trial.zip") { The only limitation is … }`: a card with the text and a download button. It goes below the “Trial” heading, which the “Free Trial” button of the app links to, so the card is highlighted when the visitor comes from there.
*/
@Sendable
private func renderTrial(arguments: TrialArguments, contentHTML: String) -> String {
	// Not an aside, as the trial is part of the page about the app.
	div {
		HTMLRaw(contentHTML)

		Link(arguments.title, destination: .url(arguments.url))
			.buttonStyle()
	}
	.style(TrialStyles.root)
	.render()
}

/**
The styles of `@Trial` cards.
*/
private enum TrialStyles: StyleSet {
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
The arguments of `@TinyApp(title: "Copy URL", download: "https://example.com/Copy-URL.zip") { … }`.
*/
@Frontmatter
private struct TinyAppArguments {
	@NonEmpty var title: String

	/**
	Without an icon, the card shows the placeholder icon, so the titles of all cards line up.
	*/
	var icon: RoutePath?

	/**
	The app, or the page of its latest release.
	*/
	@Absolute var download: URL

	@Absolute var source: URL?

	/**
	Like “Requires macOS 15 or later”.
	*/
	@NonEmpty var requirement: String?
}

/**
A small app without a page of its own, like `@TinyApp(title: "Copy URL", download: "https://example.com/Copy-URL.zip") { What it does. }`: a card with the icon, the name, the text, a download button, and the requirement, like a small app card.
*/
@Sendable
private func renderTinyApp(arguments: TinyAppArguments, contentHTML: String) -> String {
	section {
		AppIcon(decorative: arguments.icon ?? App.placeholderIconPath, size: 128)
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

				if let requirement = arguments.requirement {
					span {
						requirement
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
The styles of `@TinyApp` cards.
*/
enum TinyAppStyles: StyleSet {
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
				.display(.grid)
				.gridColumns(.auto, .fraction(1))
				.gap(row: .rootEm(1), column: .rootEm(1))
				.alignItems(.center)
				.proseCard()
				.widerThanProse()
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
			// The icon is smaller on phones, where it is only as high as the title.
			Style()
				.frame(size: .rootEm(3.5))
				.filter(AppCard.iconShadow)
				.from(.smallTablet) {
					$0
						.frame(size: .rootEm(4.5))
						.gridRowSpan(2)
				}
		case .text:
			// The paragraphs are closer than in prose, so they read as one text, which is closer to the title than to the buttons.
			Style()
				.frame(minWidth: 0)
				.children("p") {
					$0.margin(vertical: .em(0.5), horizontal: 0)
				}
				.trimmingChildMargins()
				.below(.smallTablet) {
					$0.gridColumnSpan(2)
				}
		case .title:
			// Like the title of an app card. The margin of a heading in prose is reset.
			AppCard.Styles.title.style.margin(0)
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
			.proseBlockMargin()
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
			.proseBlockMargin()
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
									.top(.lineHeight(1) + .rootEm(0.375))
									.bottom(.rootEm(0.375))
									.leading(.lineHeight(0.5) - .pixels(1))
									.frame(width: .pixels(2))
									.cornerRadius(.capsule)
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
									.plainList()
									.margin(top: .rootEm(0.25), horizontal: 0, bottom: 0)
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
private func renderChangelog(contentHTML: String) throws -> String {
	// A change of a list with blank lines between the changes is in a paragraph.
	let html = try contentHTML.replacing(#/(<li>(?:\s*<p>)?)([A-Z][a-z]+): /#) { match in
		let title = String(match.2)

		guard let kind = ChangeKind(rawValue: title) else {
			throw ContentError(reason: "“\(title)” is not a kind of change. Use \(ChangeKind.allCases.map(\.rawValue).formatted(.list(type: .or))).")
		}

		return match.1 + Badge(title, kind: kind.badgeKind).render() + " "
	}

	return div {
		HTMLRaw(html)
	}
	.style(ChangelogStyles.root)
	.render()
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
enum ChangelogStyles: StyleSet {
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
							.cornerRadius(.capsule)
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
									.frame(size: .rootEm(dotSize))
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
private enum SocialLinksStyles: StyleSet {
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
				.padding(0)
		// A flex container, so it has no bullet.
		case .item:
			Style()
				.display(.flex)
				.margin(0)
				.padding(0)
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
			.margin(top: .rootEm(0.625), horizontal: 0, bottom: 0)
	}
}
