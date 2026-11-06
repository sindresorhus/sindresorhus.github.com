import Elementary
import SiteKit

/**
Help below the feedback message, which its script shows while the visitor types: a request for a crash report when the message is about a crash, and the FAQ questions, the tips, and the guides that the message is about. The script fills the list with the suggestion template.

The message field is the `for` attribute of the element, like the `for` of a label, and the questions are its `questions` attribute. The page script sets the `app` attribute to the title of the selected app, so its questions are suggested too.

The page has the questions (``Questions``) at its end, not in the element, as they are large data, and the element is in a form, whose fields below it would wait for the data to load. The script reads them on the first input.
*/
struct FAQSuggestions: ScriptedElement {
	static let script = ElementScript()

	/**
	The ID of the message field, whose text the suggestions are about.
	*/
	let messageID: ElementID

	/**
	The ID of the questions (``Questions``), which the `questions` attribute of the element names, so the script does not find them on the page by a fixed ID.
	*/
	static let questionsID = ElementID("faq-questions")

	var rootAttributes: [HTMLAttribute<ElementTag<Self>>] {
		[
			.custom(name: "for", value: messageID.rawValue),
			.custom(name: "questions", value: Self.questionsID.rawValue)
		]
	}

	var content: some HTML {
		// A live region, so screen readers announce the crash warning and the number of suggestions while the visitor types. It is around it, as screen readers only announce changes in a live region that is already on the page, not one that is shown with its content.
		div(.role(.status)) {
			div(.part(Parts.crashWarning), .hidden) {
				"Looks like you’re reporting a crash. It would be very helpful if you could also attach a "
				Link("crash report", destination: .crashReportQuestion, opensInNewTab: true)
					.style(Styles.crashReportLink)
				"."
			}
			.style(Styles.crashWarning)

			// The number of suggestions, which the script sets when they change, so screen readers hear the number, not all the questions again.
			span(.part(Parts.count)) {}
				.style(VisuallyHidden.Styles.root)
		}

		// Not a live region, as it would read all the questions again for each change. The live region above has their number, and the links are reached with Tab.
		div(.part(Parts.panel), .hidden) {
			div {
				span {
					"Related Help"
				}
				.style(Styles.title)

				button(.part(Parts.dismiss), .type(.button)) {
					Icon.close.size(.rootEm(0.875))
				}
				.accessibilityLabel("Dismiss")
				.style(Styles.dismissButton)
			}
			.style(Styles.header)

			ul(.part(Parts.list)) {}
				.style(Styles.list)
		}
		.style(Styles.panel)

		template(.part(Parts.template)) {
			li {
				a(.target(.blank), .rel("noopener noreferrer")) {
					span {
						Icon.chevronRight.size(.rootEm(0.75))
					}
					.style(Styles.chevron)

					// The script fills the label for a guide or a tip, like “Guide: ”, and removes it for an answer of a FAQ.
					span {
						span(.part(Parts.label)) {}
							.style(Styles.label)

						span(.part(Parts.question)) {}
							.style(Styles.question)
					}

					VisuallyHidden(" (opens in a new tab)")
				}
				.attributes(.part(Parts.link))
				.style(Styles.link)
			}
		}
	}

	/**
	The questions that the script suggests, and the words that it leaves out of the message, as JSON that the script finds by the ID in the `questions` attribute of the element.
	*/
	struct Questions: HTML, Encodable {
		struct AppQuestions: Encodable {
			let title: String
			let platforms: [Platform]
			let questions: [SuggestedQuestion]
		}

		let apps: [AppQuestions]
		let generalQuestions: [SuggestedQuestion]

		/**
		The words that are left out of the message, as ``SuggestedQuestion`` leaves them out of the questions.
		*/
		let stopwords = SuggestedQuestion.stopwords.sorted()

		var body: some HTML {
			JSONScript(id: FAQSuggestions.questionsID, self)
		}

		/**
		The questions of an app are the questions of its FAQ section, its tips (``App/tipHeadings``), and the guides about it, which the script scores in the same way.

		- Parameter faq: The general FAQ page, for the questions that are useful for every app (`<!-- @faq.general -->`).
		- Parameter guides: The published guides.
		*/
		init(apps: [App], faq: MarkdownPage?, guides: [Guide] = []) {
			self.apps = apps.map { app in
				AppQuestions(
					title: app.title,
					platforms: app.platforms,
					questions: app.faqHeadings.map { heading in
						SuggestedQuestion(heading, url: .path(app.path, fragment: heading.id))
					}
						+ app.tipHeadings.map { heading in
							SuggestedQuestion(heading, url: .path(app.path, fragment: heading.id), label: .tip)
						}
						+ guides.filter { $0.frontmatter.apps.contains(app.slug) }.map(SuggestedQuestion.init)
				)
			}

			self.generalQuestions = (faq?.markdown.headings ?? [])
				.filter { $0.contains(FAQDirectives.General.self) }
				.map { heading in
					SuggestedQuestion(heading, url: .path(.faq, fragment: heading.id))
				}
		}
	}

	enum Parts: String, ElementPartSet {
		case crashWarning
		case count
		case panel
		case dismiss
		case list
		case template
		case link
		case label
		case question
	}

	enum Styles: String, ElementStyleSet {
		case root

		/**
		The suggestions.
		*/
		case panel

		case crashWarning
		case crashReportLink
		case header
		case title
		case dismissButton
		case list
		case link
		case chevron
		case label
		case question

		var style: Style {
			switch self {
			case .root:
				// The element only adds the behavior, so the warning and the suggestions are laid out as if it were not there.
				Style().display(.contents)
			case .panel:
				// A card, like the other help on the site. Fades in when shown, and out when hidden. The discrete transition of `display` keeps it displayed until the fade ends.
				Style()
					.margin(.top, .rootEm(0.75))
					.padding(.rootEm(1))
					.textStyle(.caption)
					// Less round than a card, like the fields above and below it.
					.fieldBox()
					.transition(
						.opacity,
						.offset,
						.display,
						timing: .easeOut(duration: .milliseconds(150))
					)
					.startingStyle {
						$0
							.opacity(0)
							.offset(y: .rootEm(-0.25))
					}
					.nested("&[hidden]") {
						$0
							.opacity(0)
							.offset(y: .rootEm(-0.25))
					}
			case .crashWarning:
				Style()
					.margin(.top, .rootEm(0.75))
					.padding(.rootEm(0.75))
					.border()
					.cornerRadius(.fieldRadius)
					.textStyle(.caption)
					.borderColor(.amber(300), dark: .amber(700))
					.color(.amber(800), dark: .amber(300))
					.background(.amber(50), dark: .amber(900).opacity(0.2))
			case .crashReportLink:
				Style()
					.fontWeight(.medium)
					.underline()
					.hoverColor(.amber(900), dark: .amber(200))
			case .header:
				Style()
					.hstack(alignment: .center, justification: .spaceBetween)
					.margin(.bottom, .rootEm(0.5))
			case .title:
				Style()
					.fontWeight(.semibold)
					.color(.secondaryText)
			case .dismissButton:
				Style().iconButton(hoverFill: .cardHover, isOutset: true)
			case .list:
				Style().vstack(spacing: .rootEm(0.5))
			// A question that wraps keeps its lines next to the chevron.
			case .link:
				Style()
					.hstack(alignment: .start, spacing: .rootEm(0.375))
					.fontWeight(.medium)
			case .chevron:
				// Next to the first line of the question, and never smaller.
				Style()
					.hstack(alignment: .center)
					.frame(height: .lineHeight(1), minWidth: .rootEm(0.75))
					.color(.secondaryText)
			case .label:
				// Quieter than the title, so the titles still line up for the eye.
				Style()
					.fontWeight(.regular)
					.color(.secondaryText)
			case .question:
				Style()
					.color(.primaryText)
					.hover {
						$0.underline()
					}
			}
		}
	}
}
