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

	var path: RoutePath {
		.feedback
	}

	var metadata: PageMetadata {
		PageMetadata(
			title: "Feedback & Support",
			description: "Send feedback, report a bug, or get support for apps by Sindre Sorhus.",
			preconnectOrigins: ["https://formcarry.com"]
		)
	}

	var body: some HTML {
		div(.id(Hooks.main)) {
			// With a selected app, its icon is next to its name and the title, like a heading for the app.
			div {
				// `feedback.js` sets and shows the icon of the selected app.
				img(.id(Hooks.appIcon), .alt(""), .width(128), .height(128), .hidden)
					.style(Styles.appIcon)

				div {
					// `feedback.js` shows the name of the selected app above the title.
					p(.id(Hooks.productName), .hidden) {}
						.style(Styles.productName)

					PageHeader(title: "Feedback & Support")
				}
				.style(Styles.headerText)
			}
			.style(Styles.header)

			// Without a selected app, the app is picked first, so the message says which app it is about. `feedback.js` hides the picker and shows the form when an app is selected.
			appPicker

			// The notes for the selected app. `feedback.js` shows them when an app is selected.
			section(.id(Hooks.beforeYouWrite), .hidden) {
				// In the prose, so it lines up with the notes.
				div {
					h2 {
						"Before You Write"
					}
					.style(Styles.notesTitle)

					// `feedback.js` adds the help for the selected app.
					div(.id(Hooks.additionalInformation)) {}

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
			.style(Styles.notes)

			p {
				"JavaScript is required for this form to work correctly. If you have a content blocker, you may need to allow scripts from this site."
			}
			.style(Styles.scriptingNotice)

			form(.id(Hooks.form), .action("https://formcarry.com/s/UBfgr97yfY"), .method(.post), .enctype(.multipartFormData), .hidden) {
				input(.type(.hidden), .name("_gotcha"))
				messageField
				emailField
				AttachmentPicker()
				input(.type(.hidden), .name("g-recaptcha-response"))

				div {
					// The two labels share one grid cell, so the button keeps its width while it sends.
					button(.id(Hooks.submitButton), .type(.submit)) {
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
						"If you haven’t received a reply for two weeks, check your spam folder. When you get a reply, respond in that email thread instead of sending a new message."
					}
					.style(Styles.fineprint)
				}
				.style(Styles.actions)
			}
			.style(Styles.form)
		}
		.style(Styles.root)

		templates

		JSONScript(id: Hooks.data, FeedbackData(apps: apps))
		ModuleScript("/scripts/feedback.js")
	}

	/**
	The apps to pick from, by name, each a link to the form for the app.
	*/
	private var appPicker: some HTML {
		section(.id(Hooks.appPicker)) {
			h2 {
				"Which app is it about?"
			}
			.style(Styles.appPickerTitle)

			ul {
				for app in apps.sorted(using: KeyPathComparator(\.title, comparator: .localizedStandard)) {
					li {
						a(.href(App.feedbackURL(appTitle: app.title, referrer: "Website-Feedback"))) {
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

			p {
				"Not about an app? See "
				a(.href(.contact)) {
					"the contact page"
				}
				.style(Styles.appNoticeLink)
				"."
			}
			.style(Styles.appNotice)
		}
	}

	private var messageField: some HTML {
		FormField(label: "Message", controlID: "message", errorMessage: "Write at least 20 characters.") {
			textarea(
				.id("message"),
				.placeholder("I’m a human. Please be nice."),
				.name("message"),
				.minlength(20),
				.rows(7),
				.required,
				.autofocus,
				.custom(name: "autocapitalize", value: "sentences"),
				// Right-to-left messages, like Arabic, show in their own direction.
				.dir(.auto)
			) {}
			.style(FormFieldStyles.control, Styles.message)

			FAQSuggestions(messageID: "message", questions: FAQSuggestions.Questions(apps: apps, faq: faq))
				.attributes(.id(Hooks.faqSuggestions))
		}
	}

	private var emailField: some HTML {
		FormField(label: "Email", controlID: "email", hint: "Only used for replying to you", errorMessage: "Enter a valid email address.") {
			input(.id("email"), .type(.email), .name("email"), .autocomplete("email"), .custom(name: "enterkeyhint", value: "send"), .required, .ariaDescribedBy("email-hint"))
				.style(FormFieldStyles.control)

			// `feedback.js` shows it for likely typos, like `gmial.com`.
			p(.id(Hooks.emailWarning), .hidden, .role("alert")) {}
				.style(Styles.emailWarning)
		}
	}

	/**
	The markup that `feedback.js` clones. The script fills in the elements marked with `data-` attributes.
	*/
	@ContentBuilder
	private var templates: some HTML {
		template(.id(Hooks.successTemplate)) {
			FeedbackSuccess()
		}

		template(.id(Hooks.repositoryTemplate)) {
			p {
				"If you have a GitHub account, "
				Link("open an issue on the repo", destination: nil, opensInNewTab: true)
					.attributes(.hook(Hooks.repositoryLink))
				" instead."
			}
		}

		template(.id(Hooks.appFAQTemplate)) {
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
	The IDs and data attributes that the scripts of the page find elements by.
	*/
	enum Hooks: String, ScriptHookSet {
		case additionalInformation = "additional-information"
		case appFAQLink = "data-app-faq-link"
		case appFAQTemplate = "app-faq-template"
		case appIcon = "app-icon"
		case appPicker = "app-picker"
		case beforeYouWrite = "before-you-write"
		case emailWarning = "email-warning"
		case faqSuggestions = "faq-suggestions"
		case data = "feedback-data"
		case form = "feedback-form"
		case main = "main"
		case productName = "product-name"
		case repositoryLink = "data-repository-link"
		case repositoryTemplate = "repository-template"
		case submitButton = "submit-button"
		case successTemplate = "success-template"
	}

	enum Styles: StyleSet {
		case root
		case header
		case headerText
		case appIcon
		case productName
		case appPickerTitle
		case appPickerList
		case appPickerLink
		case appNotice
		case appNoticeLink
		case notes
		case notesTitle
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
				// The column of prose pages, so the title lines up with theirs.
				Style()
					.vstack()
					.contentColumn(.prose)
					.pagePadding()
					.from(.smallTablet) {
						$0.frame(minHeight: .smallViewportHeight(100))
					}
			case .header:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(1.25))
					.margin(.bottom, .rootEm(2))
			case .headerText:
				Style().frame(minWidth: 0)
			case .appIcon:
				// About as tall as the name and the title next to it.
				Style()
					.frame(width: .rootEm(5.5), height: .rootEm(5.5), minWidth: .rootEm(5.5))
					.below(.smallTablet) {
						$0.frame(width: .rootEm(4), height: .rootEm(4), minWidth: .rootEm(4))
					}
			case .productName:
				// Above the title, like the date of a blog post.
				Style()
					.margin(.bottom, .rootEm(0.25))
					.textStyle(.body, weight: .semibold)
					.color(.secondaryText)
			case .appPickerTitle:
				Style()
					.margin(.bottom, .rootEm(1))
					.textStyle(.headline)
			case .appPickerList:
				// Two columns on phones, and three from small tablets, like the sponsors.
				Style()
					.grid(columns: 2)
					.gap(.rootEm(0.5))
					.margin(.bottom, .rootEm(1.5))
					.from(.smallTablet) {
						$0.gridColumns(3)
					}
			case .appPickerLink:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.75))
					.padding(.rootEm(0.625))
					.cornerRadius(.rootEm(0.75))
					.color(.bodyText)
					.background(.card)
					.transition(.backgroundColor, .color, animation: .stateChange)
					.hover {
						$0
							.background(.cardHover)
							.color(.primaryText)
					}
			case .appNotice:
				Style()
					.margin(.bottom, .rootEm(1))
					.padding(.rootEm(1))
					.cornerRadius(.rootEm(0.75))
					.background(.gray(50), dark: .white.opacity(0.05))
					.color(.secondaryText)
			case .appNoticeLink:
				Style().textLink()
			case .notes:
				// The prose inside has the space at the sides.
				Style()
					.margin(.bottom, .rootEm(1))
					.padding(.vertical, .rootEm(1.25))
					.border(.lightDark(.gray(200).opacity(0.8), .white.opacity(0.1)))
					.cornerRadius(.rootEm(0.75))
			case .notesTitle:
				Style()
					.margin(.bottom, .rootEm(0.5))
					.textStyle(.lead, weight: .semibold)
					.color(.primaryText)
			case .notesContent:
				Style().important {
					$0.font(size: .pixels(16))
				}
			case .scriptingNotice:
				// Only shown when JavaScript is turned off.
				Style()
					.shownOnlyWithoutScripting()
					.margin(.top, .rootEm(1.5))
					.textAlign(.center)
					.font(.extraLarge2)
			case .form:
				// The native controls, like the file picker, get the brand color.
				Style()
					.margin(.top, .rootEm(2))
					.accentColor(.primary(600))
			case .message:
				// Grows with the text. The minimum height keeps seven lines, as the empty field would otherwise shrink to one line.
				Style()
					.fieldSizing(.content)
					.frame(minHeight: .lineHeight(7) + .rootEm(1.25) + .pixels(2))
			case .emailWarning:
				Style()
					.margin(.top, .rootEm(0.375))
					.textStyle(.caption)
					.color(.amber(600), dark: .amber(400))
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
				// The disabled button, while the form sends, shows the second label.
				Style()
					.flexShrink(0)
					.frame(width: .percent(100))
					.cursor(.pointer)
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
					.nested(":disabled &") {
						$0.visibility(false)
					}
			case .sendingLabel:
				Style()
					.stackedInGrid()
					.visibility(false)
					.nested(":disabled &") {
						$0.visibility(true)
					}
			case .fineprint:
				Style()
					.secondaryText(.extraSmall)
					.textAlign(.center)
					.from(.smallTablet) {
						$0.textAlign(.leading)
					}
			}
		}
	}
}
