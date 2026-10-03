/**
A GitHub alert kind, like `> [!NOTE]`.
*/
public enum MarkdownAlert: String, CaseIterable, Sendable {
	case note
	case tip
	case important
	case warning
	case caution

	/**
	The label, like `NOTE`.
	*/
	public var title: String {
		rawValue.uppercased()
	}

	/**
	The path of the GitHub Octicon of the kind.
	*/
	public var iconPath: String {
		switch self {
		case .note:
			"M0 8a8 8 0 1 1 16 0A8 8 0 0 1 0 8Zm8-6.5a6.5 6.5 0 1 0 0 13 6.5 6.5 0 0 0 0-13ZM6.5 7.75A.75.75 0 0 1 7.25 7h1a.75.75 0 0 1 .75.75v2.75h.25a.75.75 0 0 1 0 1.5h-2a.75.75 0 0 1 0-1.5h.25v-2h-.25a.75.75 0 0 1-.75-.75ZM8 6a1 1 0 1 1 0-2 1 1 0 0 1 0 2Z"
		case .tip:
			"M8 1.5c-2.363 0-4 1.69-4 3.75 0 .984.424 1.625.984 2.304l.214.253c.223.264.47.556.673.848.284.411.537.896.621 1.49a.75.75 0 0 1-1.484.211c-.04-.282-.163-.547-.37-.847a8.456 8.456 0 0 0-.542-.68c-.084-.1-.173-.205-.268-.32C3.201 7.75 2.5 6.766 2.5 5.25 2.5 2.31 4.863 0 8 0s5.5 2.31 5.5 5.25c0 1.516-.701 2.5-1.328 3.259-.095.115-.184.22-.268.319-.207.245-.383.453-.541.681-.208.3-.33.565-.37.847a.751.751 0 0 1-1.485-.212c.084-.593.337-1.078.621-1.489.203-.292.45-.584.673-.848.075-.088.147-.173.213-.253.561-.679.985-1.32.985-2.304 0-2.06-1.637-3.75-4-3.75ZM5.75 12h4.5a.75.75 0 0 1 0 1.5h-4.5a.75.75 0 0 1 0-1.5ZM6 15.25a.75.75 0 0 1 .75-.75h2.5a.75.75 0 0 1 0 1.5h-2.5a.75.75 0 0 1-.75-.75Z"
		case .important:
			"M0 1.75C0 .784.784 0 1.75 0h12.5C15.216 0 16 .784 16 1.75v9.5A1.75 1.75 0 0 1 14.25 13H8.06l-2.573 2.573A1.458 1.458 0 0 1 3 14.543V13H1.75A1.75 1.75 0 0 1 0 11.25Zm1.75-.25a.25.25 0 0 0-.25.25v9.5c0 .138.112.25.25.25h2a.75.75 0 0 1 .75.75v2.19l2.72-2.72a.749.749 0 0 1 .53-.22h6.5a.25.25 0 0 0 .25-.25v-9.5a.25.25 0 0 0-.25-.25Zm7 2.25v2.5a.75.75 0 0 1-1.5 0v-2.5a.75.75 0 0 1 1.5 0ZM9 9a1 1 0 1 1-2 0 1 1 0 0 1 2 0Z"
		case .warning:
			"M6.457 1.047c.659-1.234 2.427-1.234 3.086 0l6.082 11.378A1.75 1.75 0 0 1 14.082 15H1.918a1.75 1.75 0 0 1-1.543-2.575Zm1.763.707a.25.25 0 0 0-.44 0L1.698 13.132a.25.25 0 0 0 .22.368h12.164a.25.25 0 0 0 .22-.368Zm.53 3.996v2.5a.75.75 0 0 1-1.5 0v-2.5a.75.75 0 0 1 1.5 0ZM9 11a1 1 0 1 1-2 0 1 1 0 0 1 2 0Z"
		case .caution:
			"M4.47.22A.749.749 0 0 1 5 0h6c.199 0 .389.079.53.22l4.25 4.25c.141.14.22.331.22.53v6a.749.749 0 0 1-.22.53l-4.25 4.25A.749.749 0 0 1 11 16H5a.749.749 0 0 1-.53-.22L.22 11.53A.749.749 0 0 1 0 11V5c0-.199.079-.389.22-.53Zm.84 1.28L1.5 5.31v5.38l3.81 3.81h5.38l3.81-3.81V5.31L10.69 1.5ZM8 4a.75.75 0 0 1 .75.75v3.5a.75.75 0 0 1-1.5 0v-3.5A.75.75 0 0 1 8 4Zm0 8a1 1 0 1 1 0-2 1 1 0 0 1 0 2Z"
		}
	}
}

/**
A part of the HTML that the renderer creates for a Markdown extension. A ``MarkdownTheme`` gives each part its classes.
*/
public enum MarkdownElement: Hashable, Sendable {
	/**
	The container of a GitHub alert.
	*/
	case alert(MarkdownAlert)

	case alertTitle
	case alertIcon

	/**
	The section with the footnotes at the end.
	*/
	case footnotes

	/**
	The link from a footnote back to its reference.
	*/
	case footnoteBackReference

	/**
	The button of a reference that shows the footnote in a popover, with ``MarkdownDocument/Options/showsFootnotesInPopovers``.
	*/
	case footnoteReference

	/**
	The popover with a footnote.
	*/
	case footnotePopover

	/**
	The container of a code block with ``MarkdownDocument/Options/addsCopyButtons``.
	*/
	case codeBlock

	/**
	The bar at the top of a code block, with the language and the copy button.
	*/
	case codeBlockBar

	case codeBlockLanguage
	case copyButton

	/**
	Text only for screen readers, like the heading of the footnotes.
	*/
	case visuallyHidden

	/**
	The `+` between the keys of a keyboard shortcut.
	*/
	case keySeparator

	/**
	The group of collapsible sections, like the questions of a FAQ.
	*/
	case collapsibleSections

	/**
	A collapsible section (`<details>`).
	*/
	case collapsibleSection

	case collapsibleSummary
	case collapsibleTitle
	case collapsibleChevron
	case collapsibleContent

	/**
	The link after the collapsible sections, like to more questions.
	*/
	case collapsibleMoreLink

	/**
	A heading with a link to itself.
	*/
	case anchoredHeading

	/**
	The link to a heading, which copies its URL.
	*/
	case headingAnchor

	case headingAnchorLinkIcon
	case headingAnchorCheckIcon

	/**
	A `: ` line in a list item.
	*/
	case listSubtitle

	/**
	A `:: ` line in a list item.
	*/
	case listDescription
}

/**
The classes of the HTML that the renderer creates for the Markdown extensions.

```swift
let theme = MarkdownTheme { element in
	element == .keySeparator ? "key-separator" : MarkdownTheme.default.classes(for: element)
}
```
*/
public struct MarkdownTheme: Sendable {
	private let classes: @Sendable (MarkdownElement) -> String

	public init(classes: @escaping @Sendable (MarkdownElement) -> String) {
		self.classes = classes
	}

	public func classes(for element: MarkdownElement) -> String {
		classes(element)
	}

	/**
	Classes like GitHub's, such as `markdown-alert markdown-alert-note`.
	*/
	public static let `default` = Self { element in
		switch element {
		case .alert(let kind):
			"markdown-alert markdown-alert-\(kind.rawValue)"
		case .alertTitle:
			"markdown-alert-title"
		case .alertIcon:
			"octicon"
		case .footnotes:
			"footnotes"
		case .footnoteBackReference:
			"data-footnote-backref"
		case .footnoteReference:
			"footnote-reference"
		case .footnotePopover:
			"footnote-popover"
		case .codeBlock:
			"code-block"
		case .codeBlockBar:
			"code-block-bar"
		case .codeBlockLanguage:
			"code-block-language"
		case .copyButton:
			"copy-button"
		case .visuallyHidden:
			"sr-only"
		case .keySeparator:
			"kbd-sep"
		case .collapsibleSections:
			"collapsible-sections"
		case .collapsibleSection:
			"collapsible-section"
		case .collapsibleSummary:
			"collapsible-summary"
		case .collapsibleTitle:
			"collapsible-title"
		case .collapsibleChevron:
			"collapsible-chevron"
		case .collapsibleContent:
			"collapsible-content"
		case .collapsibleMoreLink:
			"collapsible-more-link"
		case .anchoredHeading:
			"anchored-heading"
		case .headingAnchor:
			"heading-anchor"
		case .headingAnchorLinkIcon:
			"heading-anchor-link-icon"
		case .headingAnchorCheckIcon:
			"heading-anchor-check-icon"
		case .listSubtitle:
			"list-subtitle"
		case .listDescription:
			"list-description"
		}
	}
}
