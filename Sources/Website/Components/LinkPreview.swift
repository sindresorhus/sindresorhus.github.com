import Elementary
import Foundation
import Markdown
import SiteKit

/**
A small preview of what a link in prose goes to, which shows when the pointer rests on the link, like the page previews of Wikipedia. So a visitor sees what the link adds without leaving the page. It has three kinds of links (``Content``):

- A link to the page of an app, like “Velja” on the tiny apps page: the icon, the name, the subtitle, and the platforms, the price, and the trial.
- A link to a question of an FAQ, on the same page or on another page, like `/apps/faq#refund`: the question, the start of the answer (also when the answer starts with a list), and the name of the FAQ.
- A link to a shared shortcut in a sentence, like “this (iOS)”: the icon and the name of the shortcut from iCloud (``Shortcut``).

`site.js` loads the previews from `/link-previews.json` at the first hover, and shows a copy of the template next to the link. The preview only adds to the link, which still opens the page, so it is not focusable, and screen readers skip it. Only with a precise pointer that can hover: on a touch screen, a tap opens the page at once.
*/
struct LinkPreview: HTML {
	var body: some HTML {
		template(.id(IDs.template)) {
			// A manual popover, so it does not close an open footnote or inline note.
			div(.popover(.manual)) {
				img(.part(Parts.icon), .alt(""), .width(48), .height(48))
					.style(Styles.icon)

				span {
					span(.part(Parts.name)) {}
						.style(Styles.name)

					span(.part(Parts.subtitle)) {}
						.style(Styles.subtitle)

					span(.part(Parts.facts)) {}
						.style(Styles.facts)
				}
			}
			.accessibilityHidden()
			.style(Styles.card)
		}
	}

	/**
	The IDs that the scripts of the component find elements by.
	*/
	enum IDs: String, ScriptIDSet {
		case template = "link-preview-template"
	}

	/**
	The data attributes that the scripts of the component find elements by.
	*/
	enum Hooks: String, ScriptDataAttributeSet {
		/**
		The text whose links show the preview, like prose.
		*/
		case linkPreviews = "link-previews"

		/**
		A box inside that text that already shows the app of its links, like the box to get the app of a guide, or a link that already shows what it goes to, like the card of a shortcut, so the links show no preview.
		*/
		case noLinkPreview = "no-link-preview"
	}

	/**
	The elements in the template that `site.js` fills.
	*/
	enum Parts: String, ElementPartSet {
		case icon
		case name
		case subtitle

		/**
		What the link goes to: for an app, the platforms, the price, and the trial, like “macOS · $10 · Free Trial”, for a question, its FAQ, like “General FAQ”, and for a shortcut, “Shortcut”.
		*/
		case facts
	}

	enum Styles: String, StyleSet {
		case card
		case icon
		case name
		case subtitle
		case facts

		var style: Style {
			switch self {
			case .card:
				// Below the link, or above it when there is no space below, like a note. It starts where the link starts, so it does not hang into the margin of the page, or it ends where the link ends when there is no space to the right. The width is the width of its content, as the area from the link to the edge of the window would make it narrower. In a window that is too narrow for the two, it is centered below or above the link. It fades in, but does not move, and closes at once, and the pointer goes through it, as it only adds to the link.
				Style()
					.positionArea(.bottomSpanRight)
					.positionTryFallbacks(
						.flipBlock,
						.flipInline,
						.flipBlockAndInline,
						.bottom,
						.top
					)
					.inset(.auto)
					.margin(vertical: .pixels(8), horizontal: .zero)
					.frame(width: .maximumContent, maxWidth: .length(.min(.rootEm(22), .viewportWidth(100) - .rootEm(2))))
					.padding(.rootEm(0.875))
					.popoverSurface()
					.hstack(alignment: .center, spacing: .rootEm(0.875))
					.color(.bodyText)
					.allowsHitTesting(false)
					.transition(.opacity, timing: .easeOut(duration: .milliseconds(150)))
					.startingStyle {
						$0.opacity(0)
					}
			case .icon:
				// The icon of a shortcut is a square, so it gets the corners of an icon of the Shortcuts app. An app icon has its shape, with transparent corners, so the corners do not change it.
				Style()
					.frame(size: .rootEm(3))
					.flexShrink(0)
					.cornerRadius(.percent(22.5))
			case .name:
				Style()
					.display(.block)
					.fontWeight(.semibold)
					.color(.primaryText)
					.textWrap(.balance)
			case .subtitle:
				Style()
					.display(.block)
					.textStyle(.caption)
			case .facts:
				Style()
					.display(.block)
					.margin(.top, .rootEm(0.25))
					.font(size: .rootEm(0.8125), lineHeight: 1.4)
					.color(.secondaryText)
			}
		}
	}
}

extension LinkPreview {
	/**
	What the preview shows for a link, in `/link-previews.json`. The keys are the names of the ``Parts`` that `site.js` fills.
	*/
	struct Content: Encodable {
		/**
		The path of the icon. A question has none.
		*/
		var icon: RoutePath?

		let name: String
		var subtitle: String?

		/**
		The small text at the end, like “macOS · $10 · Free Trial” or “General FAQ”.
		*/
		let facts: String
	}

	static let dataPath = #path("/link-previews.json")

	/**
	The previews by the link that shows them: the path of an app page, like `/dato`, the path and the fragment of a question, like `/apps/faq#refund`, or the link of a shared shortcut. Only the questions that a link in the content goes to have a preview, as the pages have more than a thousand questions.
	*/
	static func data(for content: SiteContent) -> Data {
		var previews = [String: Content]()

		for app in content.activeAppsWithPages {
			let facts = [
				app.operatingSystems,
				content.listing(of: app).paidPriceText ?? (app.isPaid ? nil : "Free"),
				app.hasTrial ? "Free Trial" : nil,
			]

			previews[app.path.description] = Content(
				icon: app.iconPath,
				name: app.title,
				subtitle: app.subtitle,
				facts: facts.compactMap(\.self).joined(separator: " · ")
			)
		}

		for shortcut in content.apps.flatMap(\.shortcuts) {
			previews[shortcut.id.url.absoluteString] = Content(icon: shortcut.iconPath, name: shortcut.name, facts: "Shortcut")
		}

		// The links to a section in the content, as the path and the fragment, like `/dato#refresh-interval` for `#refresh-interval` on the page of Dato. The feedback page shows the notes of the apps.
		let sectionLinks = Set(
			content.documents.flatMap { document in
				document.markdown.links.map { $0.destination.hasPrefix("#") ? "\(document.path)\($0.destination)" : $0.destination }
			}
				+ content.apps.flatMap { $0.feedbackNote?.links.map(\.destination) ?? [] }
		)

		func addQuestions(
			_ questions: [SiteKit.Heading],
			of page: RoutePath,
			in document: @autoclosure () -> Document,
			file: MarkdownFile,
			facts: String
		) {
			let questions = questions.filter { sectionLinks.contains("\(page)#\($0.id)") }

			guard !questions.isEmpty else {
				return
			}

			let blocks = Array(document().blockChildren)

			for question in questions {
				previews["\(page)#\(question.id)"] = Content(name: question.text, subtitle: blocks.previewText(ofSection: question, in: file), facts: facts)
			}
		}

		for app in content.activeAppsWithPages {
			addQuestions(
				app.faqHeadings,
				of: app.path,
				in: app.documentWithGeneratedSections,
				file: app.file,
				facts: "\(app.title) FAQ"
			)
		}

		if let faq = content.page(.faq) {
			addQuestions(
				faq.markdown.headings.filter { $0.level == .h3 },
				of: faq.path,
				in: Document(parsing: faq.file.body, options: .parseBlockDirectives),
				file: faq.file,
				facts: "General FAQ"
			)
		}

		return Data(JSONEncoder.pageJSON(previews).utf8)
	}
}

extension [any BlockMarkup] {
	/**
	The start of the section of the heading as text for a preview, like the start of the answer of a question: the paragraphs and the list items before its next heading, shortened to a few lines. An authored heading without a custom ID is found by its source line, so questions with the same title keep their own answers. A list item is its first paragraph, and it gets a period when it has no punctuation mark at its end, so the items read as sentences. `nil` when the section has no such text, like an answer that is only an image.
	*/
	fileprivate func previewText(ofSection question: SiteKit.Heading, in file: MarkdownFile) -> String? {
		guard let heading = firstIndex(where: { block in
			guard let heading = block as? Markdown.Heading else {
				return false
			}

			if let id = heading.customID {
				return id == question.id
			}

			return question.line == file.line(of: heading)
		}) else {
			return nil
		}

		let paragraphs = self[(heading + 1)...].prefix { !($0 is Markdown.Heading) }.flatMap { block -> [Paragraph] in
			switch block {
			// A paragraph that is only bold text is a label for the text below it, like `**macOS**`, not the start of the answer (the rule of the `boldLabel` class of the renderer).
			case let paragraph as Paragraph:
				paragraph.childCount == 1 && paragraph.child(at: 0) is Strong ? [] : [paragraph]
			case let list as any ListItemContainer:
				list.children.compactMap { $0.child(at: 0) as? Paragraph }
			default:
				[]
			}
		}

		return paragraphs
			.map { $0.previewText }
			.filter { !$0.isEmpty }
			.map { text in text.last.map { ".!?:…".contains($0) } == true ? text : "\(text)." }
			.joined(separator: " ")
			.nilIfEmpty?
			.shortenedForSnippet
	}
}

extension Paragraph {
	/**
	The text of the paragraph for a preview: without the syntax of the site, like a keyboard shortcut, and without the backticks of inline code.
	*/
	fileprivate var previewText: String {
		var rewriter = PlainMarkdownRewriter(blockDirective: \.plainBlocks)
		return ((rewriter.visit(self) as? Paragraph) ?? self).plainText(includingImageDescriptions: false)
	}
}
