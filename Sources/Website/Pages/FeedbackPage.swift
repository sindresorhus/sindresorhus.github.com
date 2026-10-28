import Elementary
import Foundation
import SiteKit

/**
The support form. Without a selected app (`?product=`), the page shows the apps to pick from instead of the form, so every message says which app it is about. `feedback.js` shows the form for the selected app, and ``FAQSuggestions`` suggests FAQ answers while the message is typed. The markup that the scripts add is in `<template>` elements, here and in the components, so its look is defined in Swift.
*/
struct FeedbackPage: Page {
	let apps: [App]

	/**
	The general FAQ page, for the questions that are useful for every app (`<!-- @faq.general -->`).
	*/
	let faq: MarkdownPage?

	/**
	For the photo on the card of the page.
	*/
	let project: Project

	var path: RoutePath {
		.feedback
	}

	var socialImage: SocialImage {
		.card(OpenGraphCard(page: self, project: project))
	}

	var metadata: PageMetadata {
		PageMetadata(
			title: "Feedback & Support",
			description: "Send feedback, report a bug, or get support for apps by Sindre Sorhus.",
			preconnectOrigins: [SiteOrigin(#URL("https://formcarry.com"))]
		)
	}

	/**
	A classic script in the head marks the page when the URL selects an app, before the body is parsed, so the browser does not show the picker or load its icons. It also marks the page after a send (`?success`, where Formcarry sends the visitor back), so the page shows the message and not the picker, and it notes the send for the form, which empties itself when Back brings it back (`feedback.js`). `feedback.js` is a module, which runs only after the whole page is parsed.
	*/
	var head: some HTML {
		script {
			HTMLRaw(#"""
			if (location.search === '?success') {
				document.documentElement.setAttribute('\#(Hooks.sent.attributeName)', '');

				try {
					sessionStorage.setItem('feedback-sent', '');
				} catch {
					// Without storage, the form keeps its text after Back.
				}
			} else if (new URLSearchParams(location.search).get('product')) {
				document.documentElement.setAttribute('\#(Hooks.hasProduct.attributeName)', '');
			}
			"""#)
		}
	}

	var body: some HTML {
		div {
			// With a selected app, `feedback.js` shows its icon next to its name and the title, like a heading for the app. The link to pick another app goes to the picker, and `feedback.js` keeps the other parameters of the URL in it.
			AppHeader.selectedByScript(title: "Feedback & Support") {
				a(.id(IDs.changeAppLink), .href(.feedback), .hidden) {
					"Change App"
				}
				.style {
					$0.moreLink()
				}
			}
			// The space below the title of the other pages.
			.style {
				$0
					.margin(.bottom, .rootEm(2.5))
					.when(ancestorHas: Hooks.sent) {
						$0.hidden()
					}
			}

			// After a send, in place of the title of the form, which it hides, so its `<h2>` follows the `<h1>`. In the HTML, so it shows as soon as the page does, not after `feedback.js`, which only goes to the apps page after a while.
			FeedbackSuccess()
				.style {
					$0
						.hidden()
						.when(ancestorHas: Hooks.sent) {
							$0.display(.flex)
						}
				}

			// Without a selected app, the app is picked first, so the message says which app it is about. The script in the head marks the page when an app is selected, and the styles hide the picker and show the form.
			// Without JavaScript, the picker shows, but not the form, so the note is above the picker, where it is seen. Not in the prose, so it lines up with the picker, and the address does not break with a hyphen.
			// A warning alert with a title that says what is wrong, not only “WARNING”. The text only has a link, so it uses no styles or scripts of the Markdown that the page would need to add.
			div {
				HTMLRaw(MarkdownTheme.site.alert(.warning, title: "JavaScript is off", contentHTML: MarkdownDocument(parsing: "The form needs JavaScript. Turn it on and reload the page, or email [\(Site.author.email)](mailto:\(Site.author.email)) and say which app it is about. With a content blocker, allow the scripts of this site.", options: .site).html))
			}
			.style(Styles.scriptingNotice)

			appPicker

			// The notes for the selected app. The styles show them when `feedback.js` has added the app, like the form.
			section {
				// In the prose, so it lines up with the notes.
				div {
					h2 {
						"Before You Write"
					}
					.style(Styles.notesTitle)

					// `feedback.js` adds the help for the selected app.
					div(.id(IDs.additionalInformation)) {}

					ul {
						li {
							"Make sure you are on the latest version of the app, and try restarting your device first, especially on macOS 27 and iOS 27."
						}

						li {
							"If you get a permission issue on macOS, try "
							a(.href(.resetPermissionsQuestion)) {
								"resetting permissions"
							}
							" for the app."
						}

						li {
							"Focus Filters are broken on macOS 26.5 and later. This is out of my control."
						}
					}
				}
				.style(ProseStyles.root, Styles.notesContent)
			}
			.style(Styles.notes, Styles.shownWithSelectedApp)

			form(
				.id(IDs.form),
				.action("https://formcarry.com/s/UBfgr97yfY"),
				.method(.post),
				.enctype(.multipartFormData),
				// The declarative WebMCP API of Chrome (an origin trial) lets an AI agent fill the form as a tool. Without `toolautosubmit`, the visitor still sends it.
				.custom(name: "toolname", value: "sendFeedback"),
				.custom(name: "tooldescription", value: "Send feedback, a bug report, or a question about an app to the developer, Sindre Sorhus. The visitor reviews the message and sends it.")
			) {
				input(.type(.hidden), .name("_gotcha"))
				messageField
				emailField
				AttachmentPicker()
				input(.type(.hidden), .name("g-recaptcha-response"))

				div {
					// The two labels share one grid cell, so the button keeps its width while it sends. It is disabled until `feedback.js` has added the app and the other hidden fields, so a form that shows before the script runs, or without it, is not sent without them.
					button(.id(IDs.submitButton), .type(.submit), .disabled) {
						span {
							span {
								"Send Feedback"
							}
							.style(Styles.submitLabel)

							span {
								"Sending…"
							}
							.style(Styles.sendingLabel)
						}
						.style(Styles.labels)
					}
					.buttonStyle()
					.style(Styles.submit)

					p {
						"If you haven’t received a reply within \(Site.supportReplyTime), check your spam folder. When you get a reply, respond in that email thread instead of sending a new message."
					}
					.style(Styles.fineprint)
				}
				.style(Styles.actions)
			}
			.style(Styles.form, Styles.shownWithSelectedApp)
		}
		.style(Styles.root)

		templates

		JSONScript(id: IDs.data, FeedbackData(apps: apps))
		// After the form, so the browser shows the fields below the message before it has the large data of the questions, which the suggestions only read when the visitor starts to type.
		FAQSuggestions.Questions(apps: apps, faq: faq)
		ModuleScript(#path("/scripts/feedback.js"))
	}

	/**
	The apps to pick from, by name, each a link to the form for the app. Not the unlisted apps, like an app before its launch, which the picker would announce. Their form still works with `?product=`, like for App Review.
	*/
	private var appPicker: some HTML {
		section(.id(IDs.appPicker)) {
			h2 {
				"Which app is it about?"
			}
			.style(Styles.appPickerTitle)

			// `feedback.js` hides the apps whose name and subtitle do not have the text, and Enter opens the first app. Without JavaScript, there is no filter.
			input(
				.id(IDs.appFilter),
				.type(.search),
				.placeholder("Filter apps"),
				.autocomplete("off"),
				.enterKeyHint(.go),
				.spellcheck(false)
			)
			.accessibilityLabel("Filter apps")
			.style(FormFieldStyles.control)
			// On the element, so it wins over the display of the field.
			.style {
				$0
					.margin(.bottom, .rootEm(1))
					.hiddenWithoutScripting()
			}

			ul {
				for app in apps.filter(\.isListed).sorted(using: KeyPathComparator(\.title, comparator: .localizedStandard)) {
					li(.hook(Hooks.appFilterText, value: "\(app.title) \(app.subtitle)")) {
						a(.href(App.feedbackURL(appTitle: app.title, referrer: .appPicker))) {
							AppIcon(decorative: app, size: 32)

							span {
								app.title
							}
						}
						.style(Styles.appPickerLink)
					}
				}
			}
			.style(Styles.appPickerList)

			// `feedback.js` says when no app matches the filter. A polite live region that is always on the page, so screen readers announce the text without interrupting the typing.
			p(.id(IDs.appFilterStatus), .role("status")) {}
				.style {
					$0
						.margin(.bottom, .rootEm(1.5))
						.empty {
							$0.margin(.zero)
						}
						.color(.secondaryText)
				}

			p {
				"Not about an app? See "
				a(.href(.contact)) {
					"the contact page"
				}
				"."
			}
			.style(Styles.appNotice)
		}
		.style {
			$0
				.when(ancestorHas: Hooks.hasProduct) {
					$0.hidden()
				}
				.when(ancestorHas: Hooks.sent) {
					$0.hidden()
				}
		}
	}

	private var messageField: some HTML {
		FormField(label: "Message", controlID: ElementID("message"), errorMessage: "Write at least 20 characters.") {
			textarea(
				.placeholder("I’m a human. Please be nice."),
				.name("message"),
				.minlength(20),
				.rows(4),
				.required,
				.custom(name: "toolparamdescription", value: "The message, in the language of the visitor. Include the steps to reproduce a bug."),
				.autocapitalize(.sentences),
				// Right-to-left messages, like Arabic, show in their own direction.
				.dir(.auto)
			) {}
			.style(Styles.message)
		} accessory: {
			FAQSuggestions(messageID: ElementID("message"))
				.attributes(.id(IDs.faqSuggestions))
		}
	}

	private var emailField: some HTML {
		FormField(
			label: "Email",
			controlID: ElementID("email"),
			hint: "Only used for replying to you",
			errorMessage: "Enter a valid email address.",
			// The warning too, so a screen reader says it again when the visitor comes back to the field, as a wrong address is the one mistake that stops the reply.
			additionalDescriptionIDs: [IDs.emailWarning.id]
		) {
			input(
				.type(.email),
				.name("email"),
				.autocomplete("email"),
				.custom(name: "toolparamdescription", value: "The email address of the visitor, for the reply."),
				.enterKeyHint(.send),
				.required
			)
		} accessory: {
			// `feedback.js` fills it for likely typos, like `gmial.com`. A polite live region that is always on the page, so screen readers announce the text without interrupting the typing.
			p(.id(IDs.emailWarning), .role("status")) {}
				.style(Styles.emailWarning)
		}
	}

	/**
	The markup that `feedback.js` clones. The script fills in the elements marked with `data-` attributes.
	*/
	@ContentBuilder
	private var templates: some HTML {
		// The warning for an address with a likely typo. A click on the corrected address puts it in the field, which is easier than finding the wrong letters, especially on a phone.
		template(.id(IDs.emailSuggestionTemplate)) {
			span {
				"Did you mean "
				button(.type(.button), .hook(Hooks.suggestedEmail)) {}
					.style {
						$0.linkButton()
					}
				"?"
			}
		}

		template(.id(IDs.repositoryTemplate)) {
			p {
				"If you have a GitHub account, "
				a(.hook(Hooks.repositoryLink), .target(.blank), .rel("noopener noreferrer")) {
					"open an issue on the repo"
					VisuallyHidden(" (opens in a new tab)")
				}
				" instead."
			}
		}

		template(.id(IDs.appFAQTemplate)) {
			p {
				"See the "
				a(.hook(Hooks.appFAQLink)) {
					"app’s frequently asked questions (FAQs)"
				}
				" and the "
				a(.href(.faq)) {
					"general FAQs"
				}
				" in case your question has already been answered. If the app crashed, it would be very helpful if you could send a "
				a(.href(.crashReportQuestion)) {
					"crash report"
				}
				"."
			}
		}
	}
}

extension FeedbackPage {
	/**
	The IDs that the scripts of the page find elements by.
	*/
	enum IDs: String, ScriptIDSet {
		case additionalInformation = "additional-information"
		case appFAQTemplate = "app-faq-template"
		case appFilter = "app-filter"
		case appFilterStatus = "app-filter-status"
		case appPicker = "app-picker"
		case changeAppLink = "change-app-link"
		case emailSuggestionTemplate = "email-suggestion-template"
		case emailWarning = "email-warning"
		case faqSuggestions = "faq-suggestions"
		case data = "feedback-data"
		case form = "feedback-form"
		case repositoryTemplate = "repository-template"
		case submitButton = "submit-button"
	}

	/**
	The data attributes that the scripts of the page find elements by.
	*/
	enum Hooks: String, ScriptDataAttributeSet {
		case appFAQLink = "app-faq-link"
		case appFilterText = "app-filter-text"
		case hasProduct = "has-product"
		case repositoryLink = "repository-link"

		/**
		On the root element after a send (`?success`), so the page shows the message and nothing else.
		*/
		case sent

		/**
		On the root element when `feedback.js` has added the selected app and its notes, so the notes and the form show only then, and the message field does not move down when the notes come in on a slow network.
		*/
		case productShown = "product-shown"

		case suggestedEmail = "suggested-email"
	}

	/**
	The states that `feedback.js` sets.
	*/
	enum States: String, ElementStateSet {
		/**
		The submit button while the form sends.
		*/
		case sending
	}

	enum Styles: StyleSet {
		case root
		case appPickerTitle
		case appPickerList
		case appPickerLink
		case appNotice
		case notes
		case notesTitle
		case shownWithSelectedApp
		case notesContent
		case scriptingNotice
		case form
		case message
		case emailWarning
		case actions
		case submit
		case labels
		case submitLabel
		case sendingLabel
		case fineprint

		var style: Style {
			switch self {
			case .root:
				// The column of prose pages, so the title lines up with theirs. While the page waits for `feedback.js` to show the form of the selected app, it keeps the height of the screen, so the footer does not show and then move down.
				Style()
					.vstack()
					.contentColumn(.prose)
					.pagePadding()
					.when(ancestorHas: Hooks.hasProduct) {
						$0.frame(minHeight: .smallViewportHeight(100))
					}
					.when(ancestorHas: Hooks.productShown) {
						$0.frame(minHeight: .auto)
					}
			case .appPickerTitle:
				Style()
					.margin(.bottom, .rootEm(1))
					.textStyle(.headline)
			case .appPickerList:
				// Up to three columns, and fewer when a name does not fit, like with large text: two on phones, and three from small tablets.
				Style()
					.grid(minimumColumnWidth: .rootEm(9), maximumColumns: 3, spacing: .rootEm(0.5))
					.margin(.bottom, .rootEm(1.5))
			case .appPickerLink:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.75))
					.padding(.rootEm(0.625))
					.cornerRadius(.fieldRadius)
					.color(.bodyText)
					.background(.card)
					.hoverFill(.cardHover, color: .primaryText)
			case .appNotice:
				Style()
					.margin(.bottom, .rootEm(1))
					.padding(.rootEm(1))
					.fieldBox()
					.color(.secondaryText)
					.textLinks()
			case .notes:
				// The prose inside has the space at the sides.
				Style()
					.margin(.bottom, .rootEm(1))
					.padding(.vertical, .rootEm(1.25))
					.border(.separator)
					.cornerRadius(.fieldRadius)
			case .shownWithSelectedApp:
				// The notes and the form show when `feedback.js` has added the app and its notes above the form. Before, on a slow network, the form would show first and then move down by the height of the notes while the visitor types. Without JavaScript, they stay hidden, and the notice shows instead.
				Style()
					.hidden()
					.when(ancestorHas: Hooks.productShown) {
						$0.display(.block)
					}
			case .notesTitle:
				Style()
					.margin(.bottom, .rootEm(0.5))
					.textStyle(.lead, weight: .semibold)
					.color(.primaryText)
			case .notesContent:
				// Smaller than the prose, which it is in. The components win over the styles of prose.
				Style().font(size: .rootEm(1))
			case .scriptingNotice:
				// Only shown when JavaScript is turned off.
				Style()
					.shownOnlyWithoutScripting()
					.margin(.bottom, .rootEm(2))
					// It is not in the prose, which underlines the links.
					.textLinks()
			case .form:
				// The native controls, like the file picker, get the brand color.
				Style()
					.margin(.top, .rootEm(2))
					.accentColor(.primary(600))
			case .message:
				// Grows with the text. The minimum height keeps four lines, as the empty field would otherwise shrink to one line. Not more, so on a phone, the related help below it shows above the keyboard.
				Style()
					.fieldSizing(.content)
					.frame(minHeight: .length(.lineHeight(4) + .rootEm(1.25) + .pixels(2)))
			case .emailWarning:
				Style()
					.margin(.top, .rootEm(0.375))
					.empty {
						$0.margin(.zero)
					}
					.textStyle(.caption)
					// Dark enough to read on white, like the stars on the about page.
					.color(.amber(700), dark: .amber(400))
			case .actions:
				Style()
					.vstack(spacing: .rootEm(0.75))
					.from(.smallTablet) {
						$0
							.flexDirection(.row)
							.alignItems(.center)
							.gap(.rootEm(1.25))
					}
			case .submit:
				// The button is disabled until the script runs, and while the form sends, when it shows the second label.
				Style()
					.flexShrink(0)
					.frame(width: .percent(100))
					.disabled {
						$0
							.opacity(0.5)
							.allowsHitTesting(false)
					}
					.from(.smallTablet) {
						$0.frame(width: .auto)
					}
			case .labels:
				// The labels share one grid cell, so the button keeps its width while it sends.
				Style().display(.grid)
			case .submitLabel:
				Style()
					.stackedInGrid()
					.when(ancestorHas: States.sending) {
						$0.visibility(false)
					}
			case .sendingLabel:
				Style()
					.stackedInGrid()
					.visibility(false)
					.when(ancestorHas: States.sending) {
						$0.visibility(true)
					}
			case .fineprint:
				Style()
					.secondaryText(.extraSmall)
					.textLinks()
					.textAlign(.center)
					.from(.smallTablet) {
						$0.textAlign(.leading)
					}
			}
		}
	}
}
