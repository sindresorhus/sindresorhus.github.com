import Elementary
import Foundation
import SiteKit

/**
The support form. `feedback.js` shows the selected app (`?product=`) and suggests FAQ answers while the message is typed. The markup that the script adds is in `<template>` elements, so its look is defined here.
*/
struct FeedbackPage: Page {
	let apps: [App]

	/**
	The general FAQ page, for the curated questions in ``generalFAQSlugs``.
	*/
	let faq: MarkdownPage?

	/**
	The questions of `/apps/faq` that are useful for every app.
	*/
	private static let generalFAQSlugs: Set<String> = [
		"refund", "device-limit", "transfer-purchase", "app-store-download-problem", "invoice", "discounts",
		"universal-purchase", "export-settings", "localize", "homebrew", "uninstall-app", "app-cant-be-opened",
		"high-cpu", "randomly-quits", "launch-at-login-not-working", "app-not-showing-in-menu-bar", "app-problem",
		"icloud-sync", "reset-app",
	]

	var path: RoutePath {
		.feedback
	}

	var metadata: PageMetadata {
		PageMetadata(
			title: PageMetadata.titled("Feedback & Support"),
			description: "Send feedback, report a bug, or get support for apps by Sindre Sorhus.",
			preconnectOrigins: ["https://formcarry.com"]
		)
	}

	var body: some HTML {
		div(.id(.main)) {
			div {
				// `feedback.js` sets the icon of the selected app. Without it, the icon keeps its space.
				img(.id(.appIcon), .alt(""), .width(128), .height(128))
					.style(Styles.appIcon)

				// `feedback.js` shows the name of the selected app above the title.
				p(.id(.productName)) {}
					.style(Styles.productName)

				h1 {
					"Feedback & Support"
				}
				.style(Styles.title)

				div(.id(.additionalInfo)) {}
					.style(ProseStyles.root, Styles.additionalInfo)

				br()

				p {
					"If you are reporting bugs with my apps on macOS/iOS 27. Make sure you are on the latest version of the app and try restarting your device first. If you get any permission issue on macOS, try "
					a(.href(MarkdownPage.faqPath.fragment("mac-reset-permissions"))) {
						"resetting permissions"
					}
					" for the app."
				}
				.style(Styles.platformNotice)

				br()

				p {
					"Note: Focus filters are broken on macOS 26.5 and later. This is out of my control."
				}
			}
			.style(Styles.header)

			p {
				"JavaScript is required for this form to work correctly. If you have a content blocker, you may need to allow scripts from this site."
			}
			.style(Styles.scriptingNotice)

			form(.id(.feedbackForm), .action("https://formcarry.com/s/UBfgr97yfY"), .method(.post), .enctype(.multipartFormData)) {
				input(.type(.hidden), .name("_gotcha"))
				messageField
				emailField
				attachmentsField
				input(.type(.hidden), .id("captchaResponse"), .name("g-recaptcha-response"))

				div {
					// The two labels share one grid cell, so the button keeps its width while it sends.
					button(.id(.submitButton), .type(.submit)) {
						span {
							"Send Feedback"
						}
						.style(Styles.submitLabel)

						span {
							"Sending…"
						}
						.style(Styles.sendingLabel)
					}
					.style(Styles.submit)

					p {
						"If you haven't received a reply for two weeks, check your spam folder. When you get a reply, respond in that email thread instead of sending a new message."
					}
					.style(Styles.fineprint)
				}
				.style(Styles.actions)
			}
			.style(Styles.form)
		}
		.style(Styles.root)

		templates

		JSONScript(id: ScriptHook.feedbackData.rawValue, FeedbackData(apps: apps, faq: faq, generalFAQSlugs: Self.generalFAQSlugs))
		ModuleScript("/scripts/feedback.js")
	}

	private var messageField: some HTML {
		FormField(label: "Message*", controlID: "message", errorMessage: "Write at least 20 characters.") {
			textarea(
				.id("message"),
				.placeholder("I'm a human. Please be nice."),
				.name("message"),
				.minlength(20),
				.rows(7),
				.required,
				.autofocus,
				.custom(name: "autocapitalize", value: "sentences")
			) {}
			.style(FormFieldStyles.control, Styles.message)

			div(.id(.crashWarning), .hidden) {
				"Looks like you're reporting a crash. It would be very helpful if you could also attach a "
				Link("crash report", destination: MarkdownPage.faqPath.fragment("crash-report"), opensInNewTab: true)
					.style(Styles.crashReportLink)
				"."
			}
			.style(Styles.notice, Styles.crashWarning)

			// A live region, so screen readers announce the suggestions while the visitor types. The links are reached with Tab.
			div(.id(.faqSuggestions), .hidden, .role("status")) {
				div {
					span {
						"Related help:"
					}
					.style(Styles.suggestionsTitle)

					button(.id(.faqDismiss), .type(.button), .ariaLabel("Dismiss")) {
						Icon.close.size(.rem(0.875))
					}
					.style(Styles.dismissButton)
				}
				.style(Styles.suggestionsHeader)

				ul(.id(.faqList)) {}
					.style(Styles.suggestionList)
			}
			.style(Styles.notice, Styles.suggestions)
		}
	}

	private var emailField: some HTML {
		FormField(label: "Email*", controlID: "email", hint: "Only used for replying to you", errorMessage: "Enter a valid email address.") {
			input(.id("email"), .type(.email), .name("email"), .autocomplete("email"), .custom(name: "enterkeyhint", value: "send"), .required, .ariaDescribedBy("email-hint"))
				.style(FormFieldStyles.control)

			// `feedback.js` shows it for likely typos, like `gmial.com`.
			p(.id(.emailWarning), .hidden, .role("alert")) {}
				.style(Styles.emailWarning)
		}
	}

	private var attachmentsField: some HTML {
		div {
			label(.id("attach-label"), .for(ScriptHook.attachmentsInput.rawValue)) {
				Icon.paperclip.size(.px(14))
				"Attach files"
				input(.id(.attachmentsInput), .type(.file), .name("attachments"), .multiple, .ariaDescribedBy("attach-label"))
					.style(VisuallyHidden.Styles.root)
			}
			.style(Styles.attachmentPicker)

			div(.id(.fileList)) {}
				.style(Styles.fileList)
		}
		.style(Styles.attachmentsField)
	}

	/**
	The markup that `feedback.js` clones. The script fills in the elements marked with `data-` attributes.
	*/
	@HTMLBuilder
	private var templates: some HTML {
		template(.id(.successTemplate)) {
			div {
				div {
					Icon.check.size(.rem(2.5))
				}
				.style(Styles.successIcon)

				div {
					h1 {
						"Message sent!"
					}
					.style(Styles.successTitle)

					p {
						"Thanks for reaching out. I read every message and will get back to you soon. When you get my reply, please respond in that email thread instead of sending a new message."
					}
					.style(Styles.successMessage)
				}

				p {
					"Taking you to the apps page…"
				}
				.style(Styles.successRedirect)
			}
			.style(Styles.success)
		}

		template(.id(.repositoryTemplate)) {
			p {
				"If you have a GitHub account, "
				Link("open an issue on the repo", destination: nil, opensInNewTab: true)
					.attributes(.hook(.repositoryLinkAttribute))
				" instead."
			}
		}

		template(.id(.appFaqTemplate)) {
			p {
				"See the "
				a(.hook(.appFaqLinkAttribute)) {
					"app's frequently asked questions (FAQs)"
				}
				" and the "
				a(.href(MarkdownPage.faqPath)) {
					"general FAQs"
				}
				" in case your question has already been answered. Make sure you are on the latest version and try to restart your device. If the app crashed, it would be very helpful if you could send a "
				a(.href(MarkdownPage.faqPath.fragment("crash-report"))) {
					"crash report"
				}
				"."
			}
		}

		template(.id(.suggestionTemplate)) {
			li {
				Link(destination: nil, opensInNewTab: true) {
					span(.ariaHidden) {
						"→ "
					}

					span(.hook(.questionAttribute)) {}
				}
				.style(Styles.suggestionLink)
			}
		}

		template(.id(.attachmentTemplate)) {
			span {
				// The script keeps the thumbnail for images and the icon for other files.
				img(.alt(""), .width(20), .height(20))
					.style(Styles.attachmentThumbnail)

				Icon.file.size(.px(13))

				span {
					span(.hook(.nameAttribute)) {}
						.style(Styles.attachmentName)

					span(.hook(.sizeAttribute)) {}
						.style(Styles.attachmentSize)
				}
				.style(Styles.attachmentNameRow)

				button(.type(.button)) {
					Icon.close.size(.px(10))
				}
				.style(Styles.attachmentRemove)
			}
			.style(Styles.attachment)
		}
	}
}

/**
The apps and questions for `feedback.js`. Empty lists are left out.
*/
private struct FeedbackData: Encodable {
	struct AppData: Encodable {
		let title: String
		let url: String
		let iconUrl: String
		let hasFaqSection: Bool
		let platforms: [Platform]
		let questions: [SuggestedQuestion]
		let repoUrl: URL?
		let feedbackNote: String?
	}

	let apps: [AppData]
	let generalQuestions: [SuggestedQuestion]

	/**
	The words that are left out of the message, as ``SuggestedQuestion`` leaves them out of the questions.
	*/
	let stopwords = SuggestedQuestion.stopwords.sorted()

	init(apps: [App], faq: MarkdownPage?, generalFAQSlugs: Set<String>) {
		self.apps = apps.map { app in
			AppData(
				title: app.title,
				url: app.url,
				iconUrl: app.iconPath,
				hasFaqSection: app.hasFAQSection,
				platforms: app.platforms,
				questions: app.faqHeadings.map { heading in
					SuggestedQuestion(question: heading.text, url: "\(app.url)#\(heading.id)", keywords: heading.faqKeywords, platforms: heading.faqPlatforms)
				},
				repoUrl: app.repositoryURL?.url,
				feedbackNote: app.feedbackNoteHTML
			)
		}

		guard let faq else {
			self.generalQuestions = []
			return
		}

		// The list names the questions by their IDs, so a renamed question would silently be left out.
		let missingSlugs = generalFAQSlugs.subtracting(faq.markdown.headings.map(\.id))
		precondition(missingSlugs.isEmpty, "The general FAQ questions \(missingSlugs.sorted()) are not on \(faq.path). Update `FeedbackPage.generalFAQSlugs`.")

		self.generalQuestions = faq.markdown.headings
			.filter { $0.level == 3 && generalFAQSlugs.contains($0.id) }
			.map { heading in
				SuggestedQuestion(question: heading.text, url: faq.path.fragment(heading.id), keywords: heading.faqKeywords, platforms: heading.faqPlatforms)
			}
	}
}

/**
A question that the feedback form suggests when the message is about it. The words to match are prepared here, so `feedback.js` only splits the message into words and scores the questions.
*/
struct SuggestedQuestion: Encodable {
	let question: String
	let url: String

	/**
	The platforms the question applies to. All platforms when `nil`.
	*/
	let platforms: [Platform]?

	/**
	The place of the question among the questions that are suggested first, which need only one matching word.
	*/
	let pinnedRank: Int?

	/**
	The words of the question, for how rare a word is among the questions.
	*/
	let questionWords: [String]

	/**
	The words of the keywords and the synonyms that are not in ``questionWords``. Together, they are the words that a message can match.
	*/
	let extraWords: [String]

	init(question: String, url: String, keywords: [String]? = nil, platforms: [Platform]? = nil) {
		self.question = question
		self.url = url
		self.platforms = platforms
		self.pinnedRank = Self.pinnedURLs.firstIndex(of: url)
		let questionWords = Self.words(in: question)
		self.questionWords = questionWords

		var words = [String]()

		for word in questionWords + Self.words(in: keywords?.joined(separator: " ") ?? "") {
			for match in [word] + (Self.synonyms[word] ?? []) where !words.contains(match) {
				words.append(match)
			}
		}

		// Only the words that are not already in the question, so the page does not repeat them.
		self.extraWords = words.filter { !questionWords.contains($0) }
	}

	/**
	The words of the text that can match: lowercase, with at least three letters, and no stopwords. Apostrophes are removed first, so “doesn't” becomes “doesnt” instead of “doesn”.
	*/
	static func words(in text: String) -> [String] {
		text
			.lowercased()
			.replacing("'", with: "")
			.matches(of: /[a-z0-9_]{3,}/)
			.map { String($0.output) }
			.filter { !stopwords.contains($0) }
	}

	/**
	The questions that are suggested first, in order.
	*/
	private static let pinnedURLs = [
		MarkdownPage.faqPath.fragment("refund"),
		MarkdownPage.faqPath.fragment("app-problem"),
		MarkdownPage.faqPath.fragment("app-not-showing-in-menu-bar"),
		"/velja#fn-key-not-detected",
		"/velja#builtin-apps-requests",
	]

	/**
	Common English words that carry no meaning for finding a support question.
	*/
	static let stopwords: Set<String> = [
		"ago", "all", "also", "and", "any", "are", "about", "after", "again", "back",
		"been", "being", "both", "but", "can",
		"come", "could", "day", "did", "does", "done", "each", "even", "ever", "every",
		"far", "feel", "few", "find", "first", "for", "from", "get", "give", "got",
		"had", "has", "have", "her", "here", "his", "how", "into", "its",
		"just", "keep", "know", "last", "let", "like", "look", "made", "make",
		"many", "may", "more", "most", "much", "need", "never", "new", "not", "now",
		"off", "often", "old", "onto", "other", "our", "over", "own",
		"please", "said", "same", "say", "see", "seem", "should", "since",
		"some", "still", "such", "take", "tell", "than", "that", "the",
		"their", "them", "then", "there", "these", "they", "thing", "think", "this", "those",
		"too", "try", "turn", "upon", "use", "used", "using", "very",
		"want", "was", "way", "were", "what", "when", "where", "which",
		"while", "who", "why", "will", "with", "would", "yet", "you", "your",
	]

	/**
	The words that a word also matches. In a group, every word matches the others. A one-way synonym only matches in its direction: a question about a “broken” app matches a message about a bug, but not the other way around.
	*/
	private static let synonyms: [String: [String]] = {
		let groups = [
			["icloud", "sync", "syncing"],
			["screen", "display", "monitor"],
			["crash", "freeze", "hang"],
			["delete", "remove"],
			["settings", "preferences"],
			["notification", "alert", "banner"],
			["shortcut", "hotkey"],
			["update", "upgrade"],
			["storage", "space"],
			["account", "profile"],
			["theme", "appearance"],
			["location", "gps"],
			["picture", "image", "photo"],
		]

		var synonyms = [
			"broken": ["bug", "error", "crash"],
			"slow": ["performance", "battery"],
			"buy": ["purchase", "subscription"],
			"stuck": ["freeze"],
			"wifi": ["network", "connection"],
			"password": ["authentication"],
		]

		for group in groups {
			for word in group {
				synonyms[word] = group.filter { $0 != word }
			}
		}

		return synonyms
	}()
}

extension Heading {
	/**
	Extra words that match the question (`<!-- @faq.keywords … -->`).
	*/
	fileprivate var faqKeywords: [String]? {
		directives["faq.keywords"].nilIfEmpty
	}

	/**
	The platforms the question applies to (`<!-- @faq.platforms … -->`). All platforms when `nil`.
	*/
	fileprivate var faqPlatforms: [Platform]? {
		directives["faq.platforms"].compactMap(Platform.init(rawValue:)).nilIfEmpty
	}
}

extension FeedbackPage {
	enum Styles: StyleSet {
		case root
		case header
		case appIcon
		case productName
		case title
		case additionalInfo
		case platformNotice
		case scriptingNotice
		case form
		case message
		case notice
		case crashWarning
		case crashReportLink
		case suggestions
		case suggestionsHeader
		case suggestionsTitle
		case dismissButton
		case suggestionList
		case suggestionLink
		case emailWarning
		case attachmentsField
		case attachmentPicker
		case fileList
		case attachment
		case attachmentThumbnail
		case attachmentNameRow
		case attachmentName
		case attachmentSize
		case attachmentRemove
		case actions
		case submit
		case submitLabel
		case sendingLabel
		case fineprint
		case success
		case successIcon
		case successTitle
		case successMessage
		case successRedirect

		var style: Style {
			switch self {
			case .root:
				Style()
					.vstack()
					.frame(maxWidth: .rem(48))
					.margin(top: .rem(1.5), horizontal: .auto, bottom: .rem(4))
					.padding(.horizontal, .rem(1))
					.breakpoint(.sm) {
						$0
							.frame(minHeight: .svh(100))
							.padding(.horizontal, .rem(2))
					}
			case .header:
				Style().textAlign(.center)
			case .appIcon:
				Style()
					.display(.flex)
					.margin(top: 0, horizontal: .auto, bottom: .rem(1))
					.nested("&:not([src])") {
						$0.visibility(false)
					}
			case .productName:
				Style()
					.margin(.bottom, .rem(0.5))
					.font(.xl4, weight: .bold)
					.letterSpacing(.em(-0.05))
					.breakpoint(.md) {
						$0.font(.xl5)
					}
			case .title:
				Style()
					.margin(.bottom, .rem(2))
					.font(.xl2)
					.letterSpacing(.em(-0.05))
					.breakpoint(.md) {
						$0.font(.xl3)
					}
			case .additionalInfo:
				Style().declaration(.fontSize, .important(.px(16)))
			case .platformNotice:
				Style()
					.font(.xl)
					.textWrap(.balance)
			case .scriptingNotice:
				// Only shown when JavaScript is turned off.
				Style()
					.hidden()
					.margin(.top, .rem(1.5))
					.textAlign(.center)
					.font(.xl2)
					.media(.scriptingDisabled) {
						$0.display(.block)
					}
			case .form:
				// The native controls, like the file picker, get the brand color.
				Style()
					.margin(.top, .rem(2))
					.declaration(.accentColor, CSSValue(Color.primary(600)))
			case .message:
				// Grows with the text. Browsers without `field-sizing` show seven lines, and the visitor can resize it.
				Style()
					.declaration("field-sizing", "content")
					.frame(minHeight: Length("calc(7lh + 1.25rem + 2px)"))
			case .notice:
				Style()
					.margin(.top, .rem(0.75))
					.padding(.rem(0.75))
					.border()
					.cornerRadius(.rem(0.5))
					.font(.sm)
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
			case .suggestions:
				// Fades in when shown, and out when hidden. `allow-discrete` keeps it displayed until the fade ends.
				Style()
					.borderColor(.primary(200), dark: .primary(800))
					.background(.primary(50), dark: .primary(900).opacity(0.2))
					.transition(.opacity, .transform, .display, duration: .milliseconds(150), curve: .easeOut)
					.declaration(.transitionBehavior, "allow-discrete")
					.startingStyle {
						$0
							.opacity(0)
							.offset(y: .rem(-0.25))
					}
					.nested("&[hidden]") {
						$0
							.opacity(0)
							.offset(y: .rem(-0.25))
					}
			case .suggestionsHeader:
				Style()
					.hstack(alignment: .center, justification: .spaceBetween)
					.margin(.bottom, .rem(0.5))
			case .suggestionsTitle:
				Style()
					.fontWeight(.medium)
					.color(.primary(800), dark: .primary(300))
			case .dismissButton:
				Style()
					.margin(.rem(-0.375))
					.padding(.rem(0.375))
					.color(.primary(400))
					.hover {
						$0.color(.primary(600))
					}
			case .suggestionList:
				Style().vstack(spacing: .rem(0.375))
			case .suggestionLink:
				Style()
					.color(.primary(700), dark: .primary(400))
					.hover {
						$0.underline()
					}
			case .emailWarning:
				Style()
					.margin(.top, .rem(0.375))
					.font(.sm)
					.color(.amber(600), dark: .amber(400))
			case .attachmentsField:
				Style().margin(.bottom, .rem(2))
			case .attachmentPicker:
				Style()
					.display(.inlineFlex)
					.alignItems(.center)
					.gap(.rem(0.375))
					.font(.sm)
					.color(.secondaryText)
					.cursor(.pointer)
					.transition(.color, duration: .milliseconds(150))
					.hover {
						$0.color(.gray(700), dark: .gray(300))
					}
					// The file input is hidden, so the label shows the focus.
					.nested("&:has(:focus-visible)") {
						$0.focusRing(.primary(500), width: .px(2))
					}
			case .fileList:
				Style()
					.vstack(spacing: .rem(0.375))
					.margin(.top, .rem(0.5))
			case .attachment:
				Style()
					.hstack(alignment: .center, spacing: .rem(0.25))
					.padding(vertical: .rem(0.375), horizontal: .rem(0.5))
					.cornerRadius(.rem(0.5))
					.font(.xs)
					.color(.gray(600), dark: .gray(300))
					.background(.gray(100), dark: .gray(700))
					.nested(Icon.selector) {
						$0.flexShrink(0)
					}
			case .attachmentThumbnail:
				Style()
					.flexShrink(0)
					.declaration("object-fit", "cover")
					.cornerRadius(.px(3))
			case .attachmentNameRow:
				Style()
					.display(.flex)
					.flex(1)
					.alignItems(.center)
					.gap(.rem(0.25))
					.frame(minWidth: 0)
			case .attachmentName:
				Style()
					.overflow(.hidden)
					.declaration(.textOverflow, "ellipsis")
					.noWrap()
			case .attachmentSize:
				Style()
					.flexShrink(0)
					.color(.gray(400))
			case .attachmentRemove:
				Style()
					.flexShrink(0)
					.color(.gray(400))
					.hover {
						$0.color(.gray(600), dark: .gray(200))
					}
			case .actions:
				Style()
					.vstack(spacing: .rem(0.75))
					.breakpoint(.sm) {
						$0
							.flexDirection(.row)
							.alignItems(.center)
							.gap(.rem(1.25))
					}
			case .submit:
				// The labels share one grid cell. The disabled button, while the form sends, shows the second label.
				Style()
					.display(.grid)
					.flexShrink(0)
					.frame(width: .percent(100))
					.padding(vertical: .rem(0.75), horizontal: .rem(2))
					.cornerRadius(.capsule)
					.fontWeight(.semibold)
					.textAlign(.center)
					.color(.white)
					.background(.primary(700), dark: .primary(600))
					.transition(.backgroundColor, duration: .milliseconds(150))
					.hover {
						$0.background(.primary(800), dark: .primary(700))
					}
					.focusVisible {
						$0.focusRing(.lightDark(.primary(300), .primary(800)))
					}
					.disabled {
						$0
							.opacity(0.5)
							.allowsHitTesting(false)
					}
					.breakpoint(.sm) {
						$0.frame(width: .auto)
					}
			case .submitLabel:
				Style()
					.declaration("grid-area", "1 / 1")
					.nested(":disabled > &") {
						$0.visibility(false)
					}
			case .sendingLabel:
				Style()
					.declaration("grid-area", "1 / 1")
					.visibility(false)
					.nested(":disabled > &") {
						$0.visibility(true)
					}
			case .fineprint:
				Style()
					.font(.xs)
					.textAlign(.center)
					.color(.secondaryText)
					.breakpoint(.sm) {
						$0.textAlign(.leading)
					}
			case .success:
				Style()
					.vstack(alignment: .center, justification: .center)
					.gap(.rem(1.5))
					.frame(minHeight: .svh(60))
					.padding(vertical: .rem(4), horizontal: 0)
					.textAlign(.center)
			case .successIcon:
				Style()
					.hstack(alignment: .center, justification: .center)
					.frame(width: .rem(5), height: .rem(5))
					.cornerRadius(.capsule)
					.color(.primary(700))
					.background(.primary(600).opacity(0.15))
			case .successTitle:
				Style()
					.margin(.bottom, .rem(0.5))
					.font(.xl3, weight: .bold)
			case .successMessage:
				Style()
					.frame(maxWidth: .rem(24))
					.margin(vertical: 0, horizontal: .auto)
					.color(.secondaryText)
			case .successRedirect:
				Style()
					.font(.sm)
					.color(.gray(400))
			}
		}
	}
}
