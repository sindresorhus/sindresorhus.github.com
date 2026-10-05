import Elementary
import SiteKit

/**
Help below the feedback message, which its script shows while the visitor types: a request for a crash report when the message is about a crash, and the FAQ questions that the message is about. The script fills the list with the suggestion template.

The message field is the `for` attribute of the element, like the `for` of a label. The page script sets the `app` attribute to the title of the selected app, so its questions are suggested too.
*/
struct FAQSuggestions: ScriptedElement {
	static let script = ElementScript()

	/**
	The ID of the message field, whose text the suggestions are about.
	*/
	let messageID: String

	let questions: Questions

	var rootAttributes: [HTMLAttribute<ElementTag<Self>>] {
		[.custom(name: "for", value: messageID)]
	}

	var content: some HTML {
		div(.part(Parts.crashWarning), .hidden) {
			"Looks like you’re reporting a crash. It would be very helpful if you could also attach a "
			Link("crash report", destination: .crashReportQuestion, opensInNewTab: true)
				.style(Styles.crashReportLink)
			"."
		}
		.style(Styles.notice, Styles.crashWarning)

		// A live region, so screen readers announce the suggestions while the visitor types. The links are reached with Tab.
		div(.part(Parts.panel), .hidden, .role("status")) {
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
		.style(Styles.notice, Styles.panel)

		template(.part(Parts.template)) {
			li {
				Link(destination: nil, opensInNewTab: true) {
					span {
						Icon.chevronRight.size(.rootEm(0.75))
					}
					.style(Styles.chevron)

					span(.part(Parts.question)) {}
						.style(Styles.question)
				}
				.style(Styles.link)
			}
		}

		JSONScript(part: Parts.questions, questions)
	}

	/**
	The questions that the script suggests, and the words that it leaves out of the message.
	*/
	struct Questions: Encodable {
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

		/**
		- Parameter faq: The general FAQ page, for the questions that are useful for every app (`<!-- @faq.general -->`).
		*/
		init(apps: [App], faq: MarkdownPage?) {
			self.apps = apps.map { app in
				AppQuestions(
					title: app.title,
					platforms: app.platforms,
					questions: app.faqHeadings.map { heading in
						SuggestedQuestion(heading, url: .path(app.path, fragment: heading.id))
					}
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
		case panel
		case dismiss
		case list
		case template
		case question
		case questions
	}

	enum Styles: ElementStyleSet {
		/**
		The box of the crash warning and the suggestions. It comes first, so the colors of the others win over its border color.
		*/
		case notice

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
		case question

		var style: Style {
			switch self {
			case .notice:
				Style()
					.margin(.top, .rootEm(0.75))
					.padding(.rootEm(0.75))
					.border()
					.cornerRadius(.rootEm(0.5))
					.textStyle(.caption)
			case .root:
				// The element only adds the behavior, so the warning and the suggestions are laid out as if it were not there.
				Style().display(.contents)
			case .panel:
				// A card, like the other help on the site. Fades in when shown, and out when hidden. The discrete transition of `display` keeps it displayed until the fade ends.
				Style()
					.padding(.rootEm(1))
					.borderColor(.transparent)
					.cardSurface(isInteractive: false)
					// Less round than a card, like the fields above and below it.
					.cornerRadius(.rootEm(0.75))
					.transition(.opacity, .offset, .display, animation: .easeOut(duration: .milliseconds(150)))
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
					.borderColor(.amber(300), dark: .amber(700))
					.color(.amber(800), dark: .amber(300))
					.background(.amber(50), dark: .amber(900).opacity(0.2))
			case .crashReportLink:
				Style()
					.fontWeight(.medium)
					.underline()
					.hover {
						$0.color(.amber(900), dark: .amber(200))
					}
			case .header:
				Style()
					.hstack(alignment: .center, justification: .spaceBetween)
					.margin(.bottom, .rootEm(0.5))
			case .title:
				Style()
					.fontWeight(.semibold)
					.color(.secondaryText)
			case .dismissButton:
				Style()
					.margin(.rootEm(-0.375))
					.padding(.rootEm(0.375))
					.color(.secondaryText)
					.hover {
						$0.color(.primaryText)
					}
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
