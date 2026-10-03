import Elementary

/**
The IDs and `data-` attributes that the scripts in `public/scripts` find elements by. Use them instead of strings, so a test can check that the scripts still use each one.

```swift
div(.id(.appMedia)) {}
a(.hook(.repositoryLinkAttribute)) {}
```
*/
enum ScriptHook: String, CaseIterable {
	case additionalInfo = "additional-info"
	case anotherRandomApp = "another-random-app"
	case appFaqTemplate = "app-faq-template"
	case appIcon = "app-icon"
	case appMedia = "app-media"
	case appNavigation = "app-navigation"
	case appsFilterNotice = "apps-filter-notice"
	case attachmentTemplate = "attachment-template"
	case attachmentsInput = "attachments-input"
	case closestPage = "closest-page"
	case closestPageLink = "closest-page-link"
	case contactEmail = "contact-email"
	case crashWarning = "crash-warning"
	case emailWarning = "email-warning"
	case faqDismiss = "faq-dismiss"
	case faqList = "faq-list"
	case faqSuggestions = "faq-suggestions"
	case feedbackData = "feedback-data"
	case feedbackForm = "feedback-form"
	case fileList = "file-list"
	case main = "main"
	case mediaNext = "media-next"
	case mediaPrevious = "media-previous"
	case nebula = "nebula"
	case notFoundData = "not-found-data"
	case productName = "product-name"
	case randomAppData = "random-app-data"
	case repositoryTemplate = "repository-template"
	case shareButton = "share-button"
	case siteHeader = "site-header"
	case sparkleTemplate = "sparkle-template"
	case submitButton = "submit-button"
	case successTemplate = "success-template"
	case suggestionTemplate = "suggestion-template"
	case unicornTemplate = "unicorn-template"

	// Data attributes.
	case appFaqLinkAttribute = "data-app-faq-link"
	case nameAttribute = "data-name"
	case questionAttribute = "data-question"
	case repositoryLinkAttribute = "data-repository-link"
	case shareTitleAttribute = "data-share-title"
	case shareUrlAttribute = "data-share-url"
	case sizeAttribute = "data-size"
	case slugAttribute = "data-slug"

	var isDataAttribute: Bool {
		rawValue.hasPrefix("data-")
	}

	/**
	The name that `dataset` gives a data attribute in a script, like `shareTitle` for `data-share-title`.
	*/
	var datasetName: String? {
		guard isDataAttribute else {
			return nil
		}

		let parts = rawValue.dropFirst("data-".count).split(separator: "-")
		return parts.first.map(String.init).map { first in first + parts.dropFirst().map(\.capitalized).joined() }
	}
}

extension HTMLAttribute where Tag: HTMLTrait.Attributes.Global {
	/**
	The ID that a script finds the element by.
	*/
	static func id(_ hook: ScriptHook) -> Self {
		precondition(!hook.isDataAttribute, "\(hook) is a data attribute.")
		return .id(hook.rawValue)
	}

	/**
	The data attribute that a script finds the element by, or reads the value of.
	*/
	static func hook(_ hook: ScriptHook, value: String = "") -> Self {
		precondition(hook.isDataAttribute, "\(hook) is an ID.")
		return .custom(name: hook.rawValue, value: value)
	}
}
