import Elementary
import Foundation
import Markdown
import SiteKit

/**
The search of the whole site, in the header (``SiteHeader``): a round button with a magnifying glass, which opens a dialog with one field that finds the apps, the pages, the guides, the sections and the shortcuts of the app pages, the questions of the FAQs, the tips, the posts, and the open-source projects. Command+K or Control+K toggles the dialog. The `/` key and a link with the query in `?q=` also open it, like the search of a browser (``openSearchPath``). The button has the shortcut in its tooltip. Before the visitor types, the dialog shows the featured apps and links to the lists of the site. The results are in groups, at most 5 in each, and a group with more ends with a button that shows the others. The Down Arrow and Up Arrow keys go through the results, and Return in the field opens the first result.

The script loads the index (``indexPath``) when the dialog opens the first time, as it is large. An entry matches when its title has the whole query, like “ai” for Ask AI, or when each word of the query is a word of the entry, another form of it, or the start of it, as the visitor may still be typing it. The words have the rules of the related help of the feedback page (``SuggestedQuestion``), which `/scripts/words.js` shares, so “calendar menubar” finds the same questions on both pages. A result of a later group with the whole query in its title, like the title of a guide, is first, as the top hit, when the first group only matches by other words. On a page, its own results come first in their group, like the questions of the app on its page. When nothing matches, the dialog shows the app with the closest name, like Gifski for “gifksi”, and counts the search with a GoatCounter event, so the owner sees what visitors look for. Without JavaScript, the button is hidden.
*/
struct SiteSearch: ScriptedElement {
	static let script = ElementScript()

	var config: Config? {
		Config()
	}

	var content: some HTML {
		button(
			.part(Parts.button),
			.type(.button),
			.popoverTarget(Self.dialogID),
			.custom(name: "aria-keyshortcuts", value: "Meta+K Control+K /")
		) {
			Icon.search
		}
		.accessibilityLabel("Search")
		.style(Styles.button)

		div(.part(Parts.dialog)) {
			p(.id(Self.titleID)) {
				"Search"
			}
			.style(VisuallyHidden.Styles.root)

			div {
				Icon.search
				input(
					.part(Parts.field),
					.type(.search),
					.placeholder("Search apps and guides"),
					.autocomplete("off"),
					.enterKeyHint(.search),
					.autofocus
				)
				.autocorrectionDisabled()
				.accessibilityLabel("Search")
				.style(Styles.field)

				// On touch screens, where the results can fill the screen, and there is no Escape key. The look of the close button of the dialogs of an app page, but in the row of the field, not in the corner of the dialog, as the field starts at the top. With a mouse or a trackpad, Escape and a click outside close the dialog, and the hint says so.
				button(.type(.button), .popoverTarget(Self.dialogID)) {
					Icon.close.size(.rootEm(1), strokeWidth: 1.5)
				}
				.accessibilityLabel("Close")
				.style(AppHero.Styles.closeButton)
				.style {
					$0
						.position(.static)
						.flexShrink(0)
						.margin(.trailing, .rootEm(-0.375))
						.media(.finePointer) {
							$0.hidden()
						}
				}
			}
			.style(Styles.fieldRow)

			// The number of results, which the script sets when they change, so screen readers hear it while the visitor types.
			p(.part(Parts.status), .role(.status)) {}
				.style(VisuallyHidden.Styles.root)

			// Above the results of a query with a corrected typo, like “calender”. The script also gives its text to screen readers.
			// In a paragraph of its own, as the message is a stack, which would put the query on a line of its own.
			div(.part(Parts.correctionNote), .hidden) {
				p {
					"Showing results for “"
					span(.part(Parts.correctedQuery)) {}
					"”."
				}
			}
			.style(Styles.message)
			.style {
				$0.padding(.bottom, .zero)
			}

			// Above results that only have some of the words of the query. The script also gives its text to screen readers.
			p(.part(Parts.partialNote), .hidden) {
				"No exact match. Results with some of the words:"
			}
			.style(Styles.message)
			.style {
				$0.padding(.bottom, .zero)
			}

			div(.part(Parts.results)) {}
				.style(Styles.results)

			// The index loads when the dialog opens, so a slow or failed request would else leave the dialog without results and without a reason.
			p(.part(Parts.loadError), .hidden) {
				"The search did not load. Check your connection, and open the search again."
			}
			.style(Styles.message)

			div(.part(Parts.empty), .hidden) {
				p {
					"No results for “"
					span(.part(Parts.emptyQuery)) {}
					"”."
				}

				p {
					"A question about an app? "
					a(.href(.feedback)) {
						"Ask me"
					}
					"."
				}
			}
			.style(Styles.message)

			// Only for a keyboard, so not on touch screens.
			p {
				span {
					kbd {
						"↑"
					}
					" "
					kbd {
						"↓"
					}
					" to choose"
				}

				span {
					kbd {
						"Return"
					}
					" to open"
				}

				span {
					kbd {
						"Esc"
					}
					" to close"
				}
			}
			.accessibilityHidden()
			.style(Styles.hint)

			template(.part(Parts.groupTemplate)) {
				// Not a heading, as the dialog is in the header, before the title of the page. The script gives the list the title as its name.
				div {
					p(.part(Parts.groupTitle)) {}
						.accessibilityHidden()
						.style(Styles.groupTitle)

					// Keep the list semantics in Safari, as the styles remove its bullets.
					ul(.part(Parts.groupList), .role(.list)) {}
						.style(Styles.groupList)
				}
			}

			template(.part(Parts.resultTemplate)) {
				li {
					a(.part(Parts.link)) {
						img(.part(Parts.icon), .alt(""), .width(32), .height(32))
							.style(Styles.icon)

						// The symbol of the group, which the script shows for an entry without an icon (``Index/Symbol``).
						for symbol in Index.Symbol.allCases {
							span(.part(symbol.part), .hidden) {
								symbol.icon.size(.rootEm(1.125))
							}
							.style(Styles.symbol)
						}

						span {
							span(.part(Parts.title)) {}
								.style(Styles.title)

							span(.part(Parts.detail)) {}
								.style(Styles.detail)
						}
						.style {
							$0.frame(minWidth: .zero)
						}
					}
					.style(Styles.row)
				}
			}

			// The last row of a group with more than 5 results, which shows the others.
			template(.part(Parts.moreTemplate)) {
				li {
					button(.part(Parts.moreButton), .type(.button)) {
						span {
							Icon.ellipsis.size(.rootEm(1.125))
						}
						.style(Styles.symbol)

						span(.part(Parts.moreLabel)) {}
					}
					.style(Styles.row, Styles.moreButton)
				}
			}
		}
		.dialogPopover(id: Self.dialogID, labelledBy: Self.titleID)
		.style(Styles.dialog)
	}

	private static let dialogID = ElementID("site-search")

	private static let titleID = ElementID("site-search-title")

	/**
	The index of the search (``Index``), which the script loads when the dialog opens the first time.
	*/
	static let indexPath = #path("/search.json")

	/**
	The description of the search for browsers (OpenSearch), which the head of each page links to, so a browser can add the search of the site to its address bar, like “sindresorhus.com gifski”. The browser opens the home page with the query in `?q=`, and the script opens the dialog with it.
	*/
	static let openSearchPath = #path("/opensearch.xml")

	/**
	The OpenSearch description at ``openSearchPath``.
	*/
	static var openSearchDescription: String {
		"""
		<?xml version="1.0" encoding="UTF-8"?>
		<OpenSearchDescription xmlns="http://a9.com/-/spec/opensearch/1.1/">
			<ShortName>\(Site.name)</ShortName>
			<Description>Search the apps, guides, and questions of \(Site.name)</Description>
			<InputEncoding>UTF-8</InputEncoding>
			<Image width="96" height="96" type="image/png">\(#path("/favicon.png").absoluteURL.absoluteString)</Image>
			<Url type="text/html" template="\(RoutePath.root.absoluteURL.absoluteString)?q={searchTerms}"/>
		</OpenSearchDescription>

		"""
	}

	/**
	A button outside the header that opens the search, like in the footer. With a query, the field starts with it, like “Dato ” below the FAQ heading of Dato, so the results are about the app, and the visitor types the rest. Hidden without JavaScript, like the button of the header, as the dialog needs the script.
	*/
	struct OpenButton<Label: HTML>: HTML {
		/**
		The text that the field starts with, like “Dato ”, or empty.
		*/
		let query: String

		let label: Label

		init(query: String = "", @HTMLBuilder label: () -> Label) {
			self.query = query
			self.label = label()
		}

		var body: some HTML<HTMLTag.button> {
			button(.type(.button), .popoverTarget(SiteSearch.dialogID), .hook(SiteSearch.Hooks.query, value: query)) {
				self.label
			}
			.style {
				$0.hiddenWithoutScripting()
			}
		}
	}

	struct Config: Encodable {
		let indexPath = SiteSearch.indexPath.description
	}

	/**
	The data attributes that the script finds elements by.
	*/
	enum Hooks: String, ScriptDataAttributeSet {
		/**
		The query of a button that opens the search (``OpenButton``).
		*/
		case query = "search-query"
	}

	enum Parts: String, ElementPartSet {
		case button
		case dialog
		case field
		case status
		case results
		case correctionNote
		case correctedQuery
		case partialNote
		case loadError
		case empty
		case emptyQuery
		case groupTemplate
		case groupTitle
		case groupList
		case resultTemplate
		case link
		case icon
		case questionSymbol
		case pageSymbol
		case githubSymbol
		case title
		case detail
		case moreTemplate
		case moreButton
		case moreLabel
	}

	enum Styles: String, ElementStyleSet {
		case root
		case button
		case dialog
		case fieldRow
		case field
		case results
		case message
		case hint
		case groupTitle
		case groupList
		case row
		case moreButton
		case icon
		case symbol
		case title
		case detail

		/**
		The space at the sides of the field and the hint, which the text of the results lines up with.
		*/
		private static let inset = LengthPercentage.rootEm(1.25)

		/**
		The size of the icon of a result, and of the symbol of a result without an icon, so the titles line up.
		*/
		private static let iconSize = LengthPercentage.rootEm(2)

		var style: Style {
			switch self {
			case .root:
				// The element only adds the behavior, so the button is laid out as if it were not there, next to the menu button on phones, and after the links from tablets (``SiteHeader``).
				Style().display(.contents)
			case .button:
				// The look of the menu button and the contact link next to it. On phones, it goes to the end of the row, next to the menu button. From tablets, it is after the links, like a second icon link.
				Style()
					.iconButton()
					.flexShrink(0)
					.hiddenWithoutScripting()
					// After the margin of the larger target for fingers of the icon button, so it wins over it. On phones, it fades out with the site name while the bar of an app replaces them, as the “Get” button of the bar is at its place. From tablets, the site navigation that it is in fades out.
					.below(.tablet) {
						$0
							.margin(.leading, .auto)
							.navigationSwap(isShownWhileScrolledAway: false)
					}
					.from(.tablet) {
						$0
							.order(1)
							.margin(.leading, .rootEm(0.25))
					}
			case .dialog:
				// Near the top of the window, so the results grow down, and the field stays at the same place while the visitor types. The results scroll in the dialog.
				AppHero.Styles.dialogSurface
					.padding(.zero)
					.margin(top: .rootEm(1), horizontal: .auto, bottom: .auto)
					.from(.tablet) {
						$0.margin(top: .viewportHeight(12), horizontal: .auto, bottom: .auto)
					}
					.frame(
						width: .length(.min(.rootEm(40), .viewportWidth(100) - .pageGutter * 2)),
						maxHeight: .length(.dynamicViewportHeight(80))
					)
					.overflow(.hidden)
					.color(.bodyText)
					// Visible also while the navigation around it is hidden, like on an app page from tablets, where the navigation of the app replaces it after a scroll, but Command+K still opens the search.
					.visibility(true)
					.popoverOpen {
						$0.vstack()
					}
			case .fieldRow:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.75))
					.flexShrink(0)
					.padding(vertical: .rootEm(1), horizontal: Self.inset)
					.border(.bottom, .separator)
					.color(.secondaryText)
					// The magnifying glass is as wide as the icon of a result, with the glass in the middle, so the typed text starts where the titles of the results start.
					.children("svg") {
						$0
							.padding(horizontal: .rootEm(0.375))
							.boxSizing(.contentBox)
					}
			case .field:
				// The row is the box of the field, so the field itself has no border, and the caret shows the focus.
				Style()
					.flex(1)
					.frame(minWidth: .zero)
					.padding(.zero)
					.border(width: .zero)
					.background(.transparent)
					.declaration(raw: .appearance, .none)
					.textStyle(.lead)
					.color(.primaryText)
					.placeholder {
						$0
							.color(.secondaryText)
							.opacity(1)
					}
					// Escape closes the dialog, and the text is short, so the field needs no clear button.
					.searchCancelButton {
						$0.hidden()
					}
			case .results:
				// A swipe at the end of the results does not scroll the page behind the dialog.
				Style()
					.vstack(spacing: .rootEm(1))
					.overflow(.auto)
					.overscrollBehavior(.contain)
					.padding(.rootEm(0.5))
					.empty {
						$0.hidden()
					}
			case .message:
				Style()
					.vstack(spacing: .rootEm(0.25))
					.margin(.zero)
					.padding(vertical: .rootEm(1), horizontal: Self.inset)
					.color(.secondaryText)
					.textLinks()
			case .hint:
				// Hidden while there are no results to choose, like before the index has loaded.
				Style()
					.hstack(alignment: .center, spacing: .rootEm(1.25))
					.flexWrap()
					.flexShrink(0)
					.margin(.zero)
					.padding(vertical: .rootEm(0.625), horizontal: Self.inset)
					.border(.top, .separator)
					.textStyle(.caption)
					.color(.secondaryText)
					.combined(with: ProseStyles.keyboardKeys)
					.media(.coarsePointer) {
						$0.hidden()
					}
					.nested(":is(\(Styles.results.selector)):empty ~ &") {
						$0.hidden()
					}
			case .groupTitle:
				// Like the title of the sections of an app in the menu of the header. It stays at the top of the results while the rows of its group scroll below it, with the fill of the dialog, so a row is not under it, and the title of the next group pushes it away.
				Style()
					.position(.sticky)
					.top(.rootEm(-0.5))
					.zIndex(1)
					.margin(.zero)
					.padding(top: .rootEm(0.75), horizontal: .rootEm(0.75), bottom: .rootEm(0.375))
					.background(.white, dark: .darkPopoverBackground)
					.textStyle(.caption, weight: .semibold)
					.color(.secondaryText)
			case .groupList:
				Style().vstack()
			case .row:
				// The pointer underlines the label. Keyboard focus fills the row, so the two are distinct even if the pointer rests over another result.
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.75))
					.padding(vertical: .rootEm(0.5), horizontal: .rootEm(0.75))
					.cornerRadius(.rootEm(0.75))
					.hover {
						$0.descendants("\(class: Self.title)") {
							$0.underline()
						}
					}
					.focusVisible {
						$0.background(.cardHover)
					}
					.active {
						$0.background(.card)
					}
			case .moreButton:
				// As wide as a row, with the text at the start, like the rows above it.
				Style()
					.frame(width: .percent(100))
					.textAlign(.leading)
					.color(.secondaryText)
					.hover {
						$0.children("span:last-child") {
							$0.underline()
						}
					}
			case .icon:
				// An app icon has its shape, with transparent corners, so the corners only round a square image.
				Style()
					.frame(size: .length(Self.iconSize))
					.flexShrink(0)
					.cornerRadius(.percent(22.5))
			case .symbol:
				// On a square with the fill of a card and the corners of an app icon, so it lines up with the icons of the other groups.
				Style()
					.hstack(alignment: .center, justification: .center)
					.frame(size: .length(Self.iconSize))
					.flexShrink(0)
					.cornerRadius(.percent(22.5))
					.background(.card)
					.color(.secondaryText)
			case .title:
				// The words that match the query are bold (`<strong>`), so the visitor sees why a result is there.
				Style()
					.display(.block)
					.fontWeight(.medium)
					.color(.primaryText)
					.children("strong") {
						$0.fontWeight(.bold)
					}
			case .detail:
				// The start of an answer is longer than other details, so it shows at most two lines, and a result stays one row on a phone.
				// The words that match the query are bold too, like “menu bar” in the subtitle of Zone Bar, so the visitor sees why a result without them in its title is there.
				Style()
					.lineClamp(2)
					.textStyle(.caption)
					.color(.secondaryText)
					.children("strong") {
						$0
							.fontWeight(.semibold)
							.color(.primaryText)
					}
			}
		}
	}
}

extension SiteSearch {
	/**
	What the search finds, at ``indexPath``: the groups of entries, in the order of the dialog, the groups that the dialog shows before the visitor types (``start``), and the word rules of ``SuggestedQuestion``, which `/scripts/words.js` uses for the query.
	*/
	struct Index: Encodable {
		/**
		What a result without an icon shows in its place, so the kinds of results are clear, and the titles line up. The raw value is the name of its part in the template of a result.
		*/
		enum Symbol: String, CaseIterable, Encodable {
			case question = "questionSymbol"
			case page = "pageSymbol"
			case github = "githubSymbol"

			var icon: Icon {
				switch self {
				case .question:
					.questionMark
				case .page:
					.file
				case .github:
					.github
				}
			}

			var part: Parts {
				switch self {
				case .question:
					.questionSymbol
				case .page:
					.pageSymbol
				case .github:
					.githubSymbol
				}
			}
		}

		struct Group: Encodable {
			let title: String

			/**
			The symbol of the entries of the group that have no icon.
			*/
			let symbol: Symbol

			let entries: [Entry]
		}

		struct Entry: Encodable {
			let title: String

			/**
			The small text below the title, like the subtitle of an app, or the app of a question and the start of its answer.
			*/
			let detail: String?

			let url: LinkDestination

			/**
			The icon of an app, of the first app of a guide, of the app of a section or a tip, or of a shortcut. The others show the symbol of their group (``Group/symbol``).
			*/
			let icon: RoutePath?

			/**
			The words of the title and the keywords, with their synonyms (``SuggestedQuestion/matchableWords(of:)``), and the names with a hyphen or a short part as one word (``joinedWords(in:)``).
			*/
			let words: [String]

			/**
			- Parameter keywords: More text that the entry is found by, like the name of the app of a question.
			*/
			init(
				title: String,
				detail: String?,
				url: LinkDestination,
				icon: RoutePath? = nil,
				keywords: [String] = []
			) {
				self.title = title
				self.detail = detail
				self.url = url
				self.icon = icon
				let text = ([title] + keywords).joined(separator: " ")
				self.words = SuggestedQuestion.matchableWords(of: SuggestedQuestion.words(in: text.replacing("_", with: " ")) + Self.joinedWords(in: text))
			}

			/**
			The names with a hyphen, and any word of two capital letters with the next word, as one word, like “wifi” for “Wi-Fi”, “plimit” for “p-limit”, “vscode” for “VS Code”, and “aiactions” for “AI Actions”, as a part of fewer than 3 letters is not a word (``SuggestedQuestion/WordPatterns``), so a visitor finds them in any spelling. The script joins a query word with a short part, and these names in a title, the same way.
			*/
			private static func joinedWords(in text: String) -> [String] {
				text.matches(of: joinedName).map { match in
					String(match.output.lowercased().filter { $0.isLetter || $0.isNumber })
				}
			}

			nonisolated(unsafe) private static let joinedName = /[A-Za-z0-9]+(?:-[A-Za-z0-9]+)+|\b[A-Z]{2}\s+[A-Za-z0-9]+/
		}

		let groups: [Group]

		/**
		The groups that the dialog shows before the visitor types: the featured apps, and the lists of the site.
		*/
		let start: [Group]

		let stopwords = SuggestedQuestion.stopwords.sorted()
		let wordPatterns = SuggestedQuestion.wordPatterns
		let wordForms = SuggestedQuestion.wordForms

		init(site: Site) {
			let content = site.content
			let apps = content.activeAppsWithPages

			func appEntry(_ app: App) -> Entry {
				Entry(
					title: app.title,
					detail: app.isArchived ? "Archived · \(app.subtitle)" : app.subtitle,
					url: .path(app.path),
					icon: app.iconPath,
					keywords: [app.subtitle]
				)
			}

			// The archived apps are last, so they do not push the active apps out of the group.
			let appEntries = (apps + content.archivedAppsWithPages).map(appEntry)

			// The lists of the site, the pages of `content/pages`, and the release notes of the apps, with the words that people search them by (``Page/searchKeywords``), like “black friday” for the discounts.
			let pageEntries = (site.specialPages + site.contentPages)
				.filter { $0.path != .root && $0.metadata.isIndexed }
				.map { page in
					Entry(
						title: page.linkTitle,
						detail: page.path == .faq ? "General FAQ" : nil,
						url: .path(page.path),
						keywords: page.searchKeywords
					)
				}

			let releaseNotesEntries = apps.compactMap { app -> Entry? in
				guard let releaseNotes = app.releaseNotes else {
					return nil
				}

				let page = ReleaseNotesPage(
					app: app,
					releaseNotes: releaseNotes,
					releases: content.listing(of: app).releases,
					project: content.project
				)

				return Entry(
					title: page.metadata.title,
					detail: nil,
					url: .path(page.path),
					icon: app.iconPath,
					keywords: page.searchKeywords
				)
			}

			// The title without “How to”, like the lists of guides. The short answer (`description`) has the words that people search for, like “caffeinate” for “Keep Your Mac Awake”, and the title still ranks first. The names of the Terminal commands of the guide are words too, like “sips”, as a visitor who knows the command searches for it.
			let guideEntries = content.guides.map { resolved -> Entry in
				let appTitles = resolved.apps.map(\.title)
				let commandNames = Document(parsing: resolved.guide.file.body, options: .parseBlockDirectives)
					.descendants(of: Markdown.CodeBlock.self)
					.flatMap { codeBlock in
						// The language is the first word of the fence, like `console`, before the name of a file.
						let language = codeBlock.language?.split(separator: " ").first.flatMap { CodeBlock.Language(rawValue: String($0)) }
						return CodeBlock(source: codeBlock.code, language: language).commandNames
					}

				return Entry(
					title: resolved.guide.task,
					detail: appTitles.formattedList(.and),
					url: .path(resolved.guide.path),
					icon: resolved.app.iconPath,
					keywords: appTitles + [resolved.guide.description] + commandNames
				)
			}

			// The sections of the older versions, one for each macOS version, like “Older Versions for macOS 15”, as the error of the App Store names the version, like “requires macOS 26”, and a visitor searches for it. Only the numbers, not the names of the versions, like “Sequoia”.
			let olderVersionEntries = OlderVersionsPage(content: content).versions.map { version in
				Entry(
					title: "Older Versions for \(version.title)",
					detail: "The older versions of my apps for this macOS version",
					url: .path(.olderVersions, fragment: version.id)
				)
			}

			// The sections of the app pages, like “URL scheme” and “Scripting”, and the shortcuts that they share, like “Presentation Mode” of Supercharge, which are deep in long pages. A shortcut opens the page of its app, as its card has no ID.
			let sectionEntries = apps.flatMap { app in
				app.searchSections.map { heading in
					Entry(
						title: heading.text,
						detail: app.title,
						url: .path(app.path, fragment: heading.id),
						icon: app.iconPath,
						keywords: [app.title]
					)
				}
			}

			// A visitor can open the whole FAQ, like “velja faq”, as well as its individual questions.
			let faqEntries = apps.compactMap { app in
				app.faqDestination.map { destination in
					Entry(
						title: "\(app.title) FAQ",
						detail: App.Section.faq.title,
						url: destination,
						icon: app.iconPath,
						keywords: [App.Section.faq.title]
					)
				}
			}

			// The shortcuts of a page are in no order, so they are sorted by name, and a shortcut that several pages share is there once, with the first app.
			let shortcutEntries = apps
				.flatMap { app in
					app.shortcuts
						.sorted(using: KeyPathComparator(\Shortcut.name))
						.map { shortcut in
							(
								id: shortcut.id,
								entry: Entry(
									title: shortcut.name,
									detail: "\(app.title) · Shortcut",
									url: .path(app.path),
									icon: shortcut.iconPath,
									keywords: [app.title]
								)
							)
						}
				}
				.uniqued { $0.id }
				.map(\.entry)

			// A question that many apps have with the same answer, like the ones that the build adds and the shared questions, is there once, with the first app that has it, so it does not fill the results. A question with the own answer of an app, like “Can you localize the app?”, is there for each app. The detail has the start of the answer (the text of a link preview), so the visitor sees if it is the right question. Its words are not words of the entry, so the matches stay the same.
			let appQuestionEntries = apps.flatMap { app in
				let blocks = Array(app.documentWithGeneratedSections.blockChildren)

				return app.faqHeadings.map { heading in
					(
						answer: app.faqAnswerMarkdown(of: heading),
						entry: Entry(
							title: heading.text,
							detail: [app.title, blocks.previewText(ofSection: heading, in: app.file)].compactMap(\.self).joined(separator: " · "),
							url: .path(app.path, fragment: heading.id),
							keywords: [app.title] + (heading[FAQDirectives.Keywords.self] ?? [])
						)
					)
				}
			}
			.uniqued { [$0.entry.title, $0.answer ?? ""] }
			.map(\.entry)

			let generalQuestionEntries: [Entry] = content.page(.faq).map { faq in
				let blocks = Array(faq.file.parsedBody.blockChildren)

				return faq.markdown.headings.filter { $0.level == .h3 }.map { heading in
					Entry(
						title: heading.text,
						detail: ["General FAQ", blocks.previewText(ofSection: heading, in: faq.file)].compactMap(\.self).joined(separator: " · "),
						url: .path(.faq, fragment: heading.id),
						keywords: heading[FAQDirectives.Keywords.self] ?? []
					)
				}
			} ?? []

			// The tips with a custom ID, which the feedback form also suggests (``App/tipHeadings``), like “Batch transcribe” of Aiko.
			let tipEntries = apps.flatMap { app in
				app.tipHeadings.map { heading in
					Entry(
						title: heading.text,
						detail: app.title,
						url: .path(app.path, fragment: heading.id),
						icon: app.iconPath,
						keywords: [app.title] + (heading[FAQDirectives.Keywords.self] ?? [])
					)
				}
			}

			let postEntries = content.listedPostsWithPages.map { post in
				Entry(
					title: post.title,
					detail: post.frontmatter.description,
					url: .path(post.path),
					keywords: post.frontmatter.description.map { [$0] } ?? []
				)
			}

			// The projects of the open-source page, like Chalk and Ky, with the repo as the link. Not the apps on GitHub, which are already apps.
			let openSourceEntries = OpenSourceProject.Group.allCases
				.filter { $0 != .apps }
				.flatMap(content.openSourceProjects.projects(of:))
				.map { project in
					Entry(
						title: project.name,
						detail: project.summary.hasSuffix(".") ? String(project.summary.dropLast()) : project.summary,
						url: .url(project.repository.url),
						keywords: [project.summary]
					)
				}

			self.groups = [
				Group(title: "Apps", symbol: .page, entries: appEntries),
				Group(title: "Pages", symbol: .page, entries: pageEntries + releaseNotesEntries),
				Group(title: "Guides", symbol: .page, entries: guideEntries),
				Group(title: "Sections", symbol: .page, entries: sectionEntries + faqEntries + shortcutEntries + olderVersionEntries),
				Group(title: "Questions", symbol: .question, entries: appQuestionEntries + generalQuestionEntries),
				Group(title: "Tips", symbol: .page, entries: tipEntries),
				Group(title: "Posts", symbol: .page, entries: postEntries),
				Group(title: "Open Source", symbol: .github, entries: openSourceEntries),
			]

			self.start = [
				Group(title: "Featured Apps", symbol: .page, entries: content.featuredApps.map(appEntry)),
				Group(
					title: "Browse",
					symbol: .page,
					entries: [
						Entry(title: "All Apps", detail: apps.count.formatted(counting: "app"), url: .path(.apps)),
						Entry(title: LabeledLink.guides.title, detail: LabeledLink.guides.description, url: LabeledLink.guides.destination),
						Entry(title: "Frequently Asked Questions", detail: LabeledLink.faq.description, url: LabeledLink.faq.destination),
					]
				),
			]
		}
	}

	/**
	The index as the JSON file at ``indexPath``.
	*/
	static func index(for site: Site) -> Data {
		Data(JSONEncoder.pageJSON(Index(site: site)).utf8)
	}
}

extension App {
	/**
	The sections of the page that the search finds (``SiteSearch/Index``): the level 2 and 3 headings that the file writes, like “Scripting” and “URL scheme”, without the FAQ section and the “Tips” section, whose questions and tips are in groups of their own.
	*/
	fileprivate var searchSections: [SiteKit.Heading] {
		var sections = [SiteKit.Heading]()
		var isInFAQOrTips = false

		for heading in markdown.headings {
			if heading.level <= .h2 {
				isInFAQOrTips = [App.Section.faq, .tips].contains { $0.isHeading(level: heading.level, id: heading.id) }
			}

			if
				heading.line != nil,
				!isInFAQOrTips,
				heading.level == .h2 || heading.level == .h3
			{
				sections.append(heading)
			}
		}

		return sections
	}
}
