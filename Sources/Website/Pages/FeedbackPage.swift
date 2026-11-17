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
	The published guides, which the form suggests for the apps that they are about.
	*/
	var guides = [Guide]()

	/**
	The app with the data that the build fetched for it, for the older version that fits the macOS version of a visitor.
	*/
	var listing: @Sendable (App) -> AppListing = { AppListing(app: $0) }

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
			preconnectOrigins: [SiteOrigin(Self.formService)]
		)
	}

	/**
	A classic script in the head marks the page when the URL selects an app, before the body is parsed, so the browser does not show the picker or load its icons. It also marks the page after a send (`?success`, where Formcarry sends the visitor back), so the page shows the message and not the picker, and it notes the send for the form, which empties itself when Back brings it back (`feedback.js`). `feedback.js` is a module, which runs only after the whole page is parsed. When `feedback.js` or one of its imports does not load, like with a content blocker or a dropped connection, the page is marked too (`ScriptLoadFailure`), so it shows the note with the email address, and not only the title. With a selected app, the script in the head adds the app and the details that the app sent (`metadata`) to the email link of the note, as the form would send them.
	*/
	var head: some HTML {
		script {
			HTMLRaw(#"""
			// In a block, so the constants are not global for the other scripts of the page.
			{
				const parameters = new URLSearchParams(location.search);
				const product = parameters.get('\#(Parameters.product.rawValue)');

				if (location.search === '?success') {
					document.documentElement.setAttribute('\#(Hooks.sent.attributeName)', '');

					try {
						sessionStorage.setItem('\#(Self.sentStorageKey)', '');
					} catch {
						// Without storage, the form keeps its text after Back.
					}
				} else if (product) {
					document.documentElement.setAttribute('\#(Hooks.hasProduct.attributeName)', '');

					// The email of the note for a form that did not load has the app and the details that the app sent, which the form would send. Encoded with `encodeURIComponent`, as mail apps read a `+` in a mailto link as a plus, not a space.
					addEventListener('DOMContentLoaded', () => {
						const metadata = parameters.get('\#(Parameters.metadata.rawValue)');
						const body = metadata ? `&body=${encodeURIComponent(`\n\n---\n${metadata}`)}` : '';
						document.getElementById('\#(IDs.emailLink.id)').href += `?subject=${encodeURIComponent(`Feedback for ${product}`)}${body}`;
					});
				}
			}
			"""#)
		}

		ScriptLoadFailure(Self.scriptPath)
	}

	var body: some HTML {
		div {
			// With a selected app, `feedback.js` shows its icon next to its name and the title, like a heading for the app. The link to pick another app goes to the picker, and `feedback.js` keeps the other parameters of the URL in it.
			AppHeader.selectedByScript(title: "Feedback & Support") {
				a(.id(IDs.changeAppLink), .href(.feedback), .hidden) {
					"Change App"
				}
				// The accent of the selected app, like the button and the links of the form.
				.style {
					$0
						.moreLink()
						.color(.accentText)
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

			// After a send, in place of the title of the form, which it hides, so its `<h2>` follows the `<h1>`. In the HTML, so it shows as soon as the page does, without `feedback.js`.
			FeedbackSuccess()
				.style {
					$0
						.hidden()
						.when(ancestorHas: Hooks.sent) {
							$0.display(.flex)
						}
				}

			// Without a selected app, the app is picked first, so the message says which app it is about. The script in the head marks the page when an app is selected, and the styles hide the picker and show the form.
			// Without JavaScript, the picker shows, but not the form, so the note is above the picker, where it is seen. It also shows when `feedback.js` does not load, so its title is correct for the two causes. Not in the prose, so it lines up with the picker, and the address does not break with a hyphen.
			// A warning alert with a title that says what is wrong, not only “Warning”. The text only has a link, so it uses no styles or scripts of the Markdown that the page would need to add. It is not Markdown, so its link has the ID for the script in the head.
			div {
				MarkdownTheme.site.alert(.warning, title: "The form did not load", content: scriptingNoticeText.renderFragment())
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

					// `feedback.js` adds the notes of the selected app at the start of the list, so all the notes have one look.
					ul(.id(IDs.notes)) {
						// `feedback.js` writes the platforms of the selected app, like “watchOS 27” for an Apple Watch app, and hides the notes about macOS for an app without a Mac version.
						li {
							"Make sure you are on the latest version of the app, and try restarting your device first, especially on "
							span(.id(IDs.newestOSVersions)) {
								[Platform.macOS, .iOS].newestVersions
							}
							"."
						}

						li(.hook(Hooks.macOSNote)) {
							"If you get a permission issue on macOS, try "
							a(.href(.resetPermissionsQuestion)) {
								"resetting permissions"
							}
							" for the app."
						}

						li(.hook(Hooks.macOSNote)) {
							"Focus Filters are broken on macOS 26.5 and later. This is out of my control."
						}
					}
				}
				.style(ProseStyles.root, Styles.notesContent)
			}
			.style(Styles.notes, Styles.shownWithSelectedApp)

			form(
				.id(IDs.form),
				.action(Self.formService.appending(path: "s/UBfgr97yfY").absoluteString),
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
					.attributes(.id(IDs.attachmentPicker))
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

		JSONScript(id: IDs.data, FeedbackData(listings: apps.map(listing)))
		// After the form, so the browser shows the fields below the message before it has the large data of the questions, which the suggestions only read when the visitor starts to type.
		FAQSuggestions.Questions(apps: apps, faq: faq, guides: guides)
		ModuleScript(Self.scriptPath)
	}

	/**
	The text of the note for a form that did not load. The script in the head adds the app to its email link.
	*/
	private var scriptingNoticeText: some HTML {
		p {
			"The form needs JavaScript. Turn it on and reload the page, or email "
			a(.id(IDs.emailLink), .href("mailto:\(Site.author.email)")) {
				Site.author.email
			}
			" and say which app it is about. With a content blocker, allow the scripts of this site."
		}
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

			// Above the apps, so a visitor with another question sees the way out before the long list.
			p {
				"Not about an app? See "
				a(.href(.contact)) {
					"the contact page"
				}
				"."
			}
			.style(Styles.appNotice)

			// `feedback.js` hides the apps whose name and subtitle do not have the text, and Enter opens the first app. Without JavaScript, there is no filter. The field stays below the site header while the apps scroll, as they are many rows on a phone.
			div {
				input(
					.id(IDs.appFilter),
					.type(.search),
					.placeholder("Filter apps"),
					.autocomplete("off"),
					.enterKeyHint(.go)
				)
				.autocorrectionDisabled()
				.accessibilityLabel("Filter apps")
				.style(FormFieldStyles.control)
			}
			.style {
				$0
					.stickyFilterField()
					.hiddenWithoutScripting()
			}

			// Keep the list semantics in Safari, as the styles remove its bullets.
			ul(.role(.list)) {
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
			p(.id(IDs.appFilterStatus), .role(.status)) {}
				.style {
					$0
						.margin(.bottom, .rootEm(1.5))
						.empty {
							$0.margin(.zero)
						}
						.color(.secondaryText)
				}
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
		FormField(label: "Message", controlID: FieldNames.message.id, errorMessage: "Write at least 20 characters.") {
			textarea(
				.placeholder("I’m a human. Please be nice."),
				.name(FieldNames.message.rawValue),
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
			FAQSuggestions(messageID: FieldNames.message.id)
				.attributes(.id(IDs.faqSuggestions))
		}
	}

	private var emailField: some HTML {
		FormField(
			label: "Email",
			controlID: FieldNames.email.id,
			hint: "Only used for replying to you",
			errorMessage: "Enter a valid email address.",
			// The warning too, so a screen reader says it again when the visitor comes back to the field, as a wrong address is the one mistake that stops the reply.
			additionalDescriptionIDs: [IDs.emailWarning.id]
		) {
			input(
				.type(.email),
				.name(FieldNames.email.rawValue),
				.autocomplete("email"),
				.custom(name: "toolparamdescription", value: "The email address of the visitor, for the reply."),
				.enterKeyHint(.send),
				.required
			)
		} accessory: {
			// `feedback.js` fills it for likely typos, like `gmial.com`. A polite live region that is always on the page, so screen readers announce the text without interrupting the typing.
			p(.id(IDs.emailWarning), .role(.status)) {}
				.style(Styles.emailWarning)
		}
	}

	/**
	The markup that `feedback.js` clones. The script fills in the parts (``Parts``).
	*/
	@ContentBuilder
	private var templates: some HTML {
		// The warning for an address with a likely typo. A click on the corrected address puts it in the field, which is easier than finding the wrong letters, especially on a phone.
		template(.id(IDs.emailSuggestionTemplate)) {
			span {
				"Did you mean "
				button(.type(.button), .part(Parts.suggestedEmail)) {}
					// The accent of the selected app, like “Change App”, so the form has one link color.
					.style {
						$0
							.linkButton()
							.color(.accentText)
					}
				"?"
			}
		}

		template(.id(IDs.repositoryTemplate)) {
			li {
				"If you have a GitHub account, "
				a(.part(Parts.repositoryLink), .target(.blank), .rel("noopener noreferrer")) {
					"open an issue on the repo"
					VisuallyHidden(" (opens in a new tab)")
				}
				" instead."
			}
		}

		// For a visitor on a macOS version that the app no longer runs on, from the details that the app sent: the last version for it (`olderVersions`). `feedback.js` fills the text and the link.
		template(.id(IDs.olderVersionTemplate)) {
			li {
				strong(.part(Parts.olderVersionText)) {}
				" It gets no more fixes. "
				a(.part(Parts.olderVersionLink)) {}
			}
		}

		template(.id(IDs.appFAQTemplate)) {
			li {
				"See the "
				a(.part(Parts.appFAQLink)) {
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

		// The note of each app that has one (`feedbackNote`), by the title of the app. In the HTML, not in the data, so the page has the styles of the note, like of a platform badge, and the check of the links finds its links. One item of the list of notes, also for a note with more than one paragraph, as the script clones one element.
		for app in apps {
			if let note = app.feedbackNote {
				template(.hook(Hooks.feedbackNote, value: app.title)) {
					// The links of the note show a preview of what they go to, like the links of prose (``LinkPreview``).
					li(.hook(LinkPreview.Hooks.linkPreviews)) {
						note.inlineContent
					}
				}
			}
		}
	}
}

extension FeedbackPage {
	/**
	The script of the page, which the head also names, to find out when it does not load.
	*/
	private static let scriptPath = #path("/scripts/feedback.js")

	/**
	The service that gets the messages of the form.
	*/
	private static let formService = #URL("https://formcarry.com")

	/**
	The session storage key that the script in the head sets after a send, and that `feedback.js` reads to empty the form after Back (``FeedbackData``).
	*/
	static let sentStorageKey = "feedback-sent"

	/**
	The session storage key that `feedback.js` sets to the title of the app when the form sends, so the message after the send shows the app (``FeedbackSuccess``).
	*/
	static let sentAppStorageKey = "feedback-sent-app"

	/**
	The IDs that the scripts of the page find elements by.
	*/
	enum IDs: String, ScriptIDSet {
		case appFAQTemplate = "app-faq-template"
		case appFilter = "app-filter"
		case appFilterStatus = "app-filter-status"
		case appPicker = "app-picker"

		/**
		The file picker of the form, which gets the names of the selected app, for the note on a crash report of another app.
		*/
		case attachmentPicker = "attachment-picker"

		case changeAppLink = "change-app-link"
		/**
		The email address in the note for a form that did not load. With a selected app, the script in the head adds the subject and the details that the app sent.
		*/
		case emailLink = "email-link"

		case emailSuggestionTemplate = "email-suggestion-template"
		case emailWarning = "email-warning"
		case faqSuggestions = "faq-suggestions"
		case data = "feedback-data"
		case form = "feedback-form"

		/**
		The newest versions of the platforms of the selected app, in the note about restarting the device.
		*/
		case newestOSVersions = "newest-os-versions"

		/**
		The list of the notes above the form, which starts with the notes of the selected app.
		*/
		case notes = "feedback-notes"

		case olderVersionTemplate = "older-version-template"
		case repositoryTemplate = "repository-template"
		case submitButton = "submit-button"
	}

	/**
	The data attributes that the scripts of the page find elements by.
	*/
	enum Hooks: String, ScriptDataAttributeSet {
		case appFilterText = "app-filter-text"

		/**
		On the template of the note of an app, with the title of the app.
		*/
		case feedbackNote = "feedback-note"

		case hasProduct = "has-product"

		/**
		A note about macOS, which `feedback.js` hides for an app without a Mac version.
		*/
		case macOSNote = "macos-note"

		/**
		On the root element after a send (`?success`), so the page shows the message and nothing else.
		*/
		case sent

		/**
		On the root element when `feedback.js` has added the selected app and its notes, so the notes and the form show only then, and the message field does not move down when the notes come in on a slow network.
		*/
		case productShown = "product-shown"
	}

	/**
	The elements in the templates that `feedback.js` fills.
	*/
	enum Parts: String, ElementPartSet {
		case appFAQLink

		/**
		The download of the last version of the app for the macOS version of the visitor.
		*/
		case olderVersionLink

		/**
		The sentence that names the macOS version of the visitor and the last version of the app for it.
		*/
		case olderVersionText

		case repositoryLink
		case suggestedEmail
	}

	/**
	The parameters of the URL of the page that the page and `feedback.js` read. The apps send them too, so their names cannot change. `feedback.js` has them as literals.
	*/
	enum Parameters: String, CaseIterable {
		/**
		The app that the message is about, like `Dato`, by its title, its slug, or another name that the app sends (``App/feedbackLookupNames``).
		*/
		case product

		/**
		Where the visitor came from, like a link on the app page (``App/FeedbackReferrer``).
		*/
		case referrer

		/**
		The details that an app sends about itself, like its version. Only the apps send it, so no link of the site has it.
		*/
		case metadata

		/**
		The email address that the form starts with. The apps send it.
		*/
		case emailField

		/**
		The message that the form starts with. The apps send it, like Dato.
		*/
		case messageField
	}

	/**
	The fields that `feedback.js` reads by name (`form.elements.message`). The ID of each field is its name.
	*/
	enum FieldNames: String {
		case message
		case email

		var id: ElementID {
			ElementID(rawValue)
		}
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

	enum Styles: String, StyleSet {
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
				// Two columns until small tablets, and three from there, and fewer when a name does not fit, like with large text. Not three columns from where three of the minimum width fit, as long names, like “Simple Color Palette”, then break over lines.
				Style()
					.grid(minimumColumnWidth: .rootEm(9), maximumColumns: 2, spacing: .rootEm(0.5))
					.from(.smallTablet) {
						$0.grid(minimumColumnWidth: .rootEm(9), maximumColumns: 3, spacing: .rootEm(0.5))
					}
					.margin(.bottom, .rootEm(1.5))
					// No space while the filter hides all the apps, so the text that no app matches is directly below the filter.
					.allChildrenHidden {
						$0.margin(.bottom, .zero)
					}
					// A grid item, so the link fills the row, and the two tiles of a row have the same height when one name wraps.
					.children("li") {
						$0.display(.grid)
					}
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
					// The side padding of the field and the app tiles below, so the text of all three starts at the same edge.
					.padding(vertical: .rootEm(1), horizontal: .rootEm(0.625))
					.fieldBox()
					.color(.secondaryText)
					.textLinks()
			case .notes:
				// A quiet card, not an outline, so the notes do not look like one more empty field above the message field. The prose inside has the space at the sides.
				Style()
					.margin(.bottom, .rootEm(1))
					.padding(.vertical, .rootEm(1.25))
					.cardSurface(isInteractive: false)
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
				// Only shown when JavaScript is turned off, or when `feedback.js` did not load.
				Style()
					.shownOnlyWithoutScripting()
					.when(ancestorHas: ScriptLoadFailure.Hooks.failed) {
						$0.display(.block)
					}
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
					// It grows with the text, so it has no grabber, which would set a fixed size and stop the growth.
					.resize(.disabled)
					.frame(minHeight: .length(.lineHeight(4) + .rootEm(1.25) + .pixels(2)))
			case .emailWarning:
				Style()
					.margin(.top, .rootEm(0.375))
					.empty {
						$0.margin(.zero)
					}
					// The red error of the field says the same while the browser rejects the address, so the warning hides, but a suggestion stays, as its button fixes the address.
					.nested(":user-invalid ~ &:not(:has(button))") {
						$0.hidden()
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
				// The button is disabled until the script runs, and while the form sends, when it shows the second label almost at full strength, so it reads as progress, not as a disabled button.
				Style()
					.flexShrink(0)
					.frame(width: .percent(100))
					.disabled {
						$0
							.opacity(0.5)
							.allowsHitTesting(false)
					}
					// After the disabled style, which has the same specificity.
					.when(States.sending) {
						$0.opacity(0.8)
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
