import Elementary

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
	Text only for screen readers, like the heading of the footnotes.
	*/
	case visuallyHidden

	/**
	The `+` between the keys of a keyboard shortcut.
	*/
	case keySeparator

	/**
	The container of a table, which scrolls a table that is wider than the content. It has keyboard focus and a label, so keyboard and screen reader users can scroll it too.
	*/
	case tableContainer

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
	A collapsible section with a link to itself: the link, and then the section. The link is outside the section, as a closed section only shows its summary, and a summary cannot have links, as it is a button. For the same reason, the links of the heading are only their text.
	*/
	case anchoredSection

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

The classes are only for styles. Scripts find the elements by their `data-` attributes, which the theme does not change:
- `data-copy-link`: the link to a section (``MarkdownDocument/Options/addsHeadingAnchors``). The script copies its URL, and sets `data-state` on it.
- `data-footnote-ref`, `data-footnotes`, and `data-footnote-backref`: a footnote reference, the footnotes section, and the link back to a reference, like on GitHub. The popovers of footnotes use `popovertarget`, so they need no script.

```swift
let theme = MarkdownTheme { element in
	element == .keySeparator ? "kbd-sep" : MarkdownTheme.default.classes(for: element)
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
	Classes from the names of the elements, like `key-separator` for ``MarkdownElement/keySeparator``, and `alert alert-note` for a note alert.
	*/
	public static let `default` = Self { element in
		guard case .alert(let kind) = element else {
			return String(describing: element).kebabCased
		}

		return "alert alert-\(kind.rawValue)"
	}
}

extension MarkdownTheme {
	/**
	A collapsible section (`<details>`) with the look of the collapsible sections, like for a `@Details` directive.

	- Parameter titleHTML: The HTML of the summary.
	*/
	public func collapsibleSection(titleHTML: String, contentHTML: String) -> String {
		collapsibleSection(id: nil, name: nil, headingLevel: nil, titleHTML: titleHTML, contentHTML: contentHTML)
	}

	/**
	A collapsible section (`<details>`).

	- Parameter headingLevel: The level of the heading that is the title in the summary, like `3` for a question of a FAQ. Without it, the title is a `span`.
	*/
	func collapsibleSection(id: String?, name: String?, headingLevel: Int?, titleHTML: String, contentHTML: String) -> String {
		let attributes: [HTMLAttribute<HTMLTag.details>?] = [
			id.map { .id($0) },
			name.map { .custom(name: "name", value: $0) },
			.class(classes(for: .collapsibleSection))
		]

		return details(attributes: attributes.compactMap(\.self)) {
			summary(.class(classes(for: .collapsibleSummary))) {
				collapsibleTitle(headingLevel: headingLevel, html: titleHTML)
				span(.class(classes(for: .collapsibleChevron))) {}
					.accessibilityHidden()
			}
			div(.class(classes(for: .collapsibleContent))) {
				HTMLRaw(contentHTML)
			}
		}
		.render()
	}

	@HTMLBuilder
	private func collapsibleTitle(headingLevel: Int?, html: String) -> some HTML {
		let classes = classes(for: .collapsibleTitle)

		switch headingLevel {
		case 1:
			h1(.class(classes)) {
				HTMLRaw(html)
			}
		case 2:
			h2(.class(classes)) {
				HTMLRaw(html)
			}
		case 3:
			h3(.class(classes)) {
				HTMLRaw(html)
			}
		case 4:
			h4(.class(classes)) {
				HTMLRaw(html)
			}
		case 5:
			h5(.class(classes)) {
				HTMLRaw(html)
			}
		case 6:
			h6(.class(classes)) {
				HTMLRaw(html)
			}
		default:
			span(.class(classes)) {
				HTMLRaw(html)
			}
		}
	}

	/**
	The link after the collapsible sections, like to more questions.
	*/
	func collapsibleMoreLink(_ link: MarkdownDocument.CollapsibleSections.MoreLink) -> String {
		a(.href(link.url), .class(classes(for: .collapsibleMoreLink))) {
			link.title
		}
		.render()
	}

	/**
	A box with the look of a GitHub alert, like for a `@Tips` directive.

	- Parameter title: The title, which is the title of the kind by default, like `NOTE`.
	*/
	public func alert(_ kind: MarkdownAlert, title: String? = nil, contentHTML: String) -> String {
		div(.class(classes(for: .alert(kind))), .dir(.auto)) {
			p(.class(classes(for: .alertTitle)), .dir(.auto)) {
				// Elementary writes an SVG path as `<path … />`, so the icon is written as HTML, which keeps the markup as it was.
				HTMLRaw(#"<svg class="\#(classes(for: .alertIcon).escapedForHTML)" viewBox="0 0 16 16" width="16" height="16" aria-hidden="true"><path d="\#(kind.iconPath)"></path></svg>"#)
				title ?? kind.title
			}
			HTMLRaw(contentHTML)
		}
		.render()
	}

	/**
	A keyboard shortcut as one `<kbd>` per key, with a `+` between them that screen readers skip, like GitHub.

	- Parameter keysHTML: The HTML of each key, like `Cmd` and `K`.
	*/
	func keyboardShortcut(keysHTML: [String]) -> String {
		keysHTML.enumerated()
			.map { index, key in
				let separator = index == 0 ? "" : #"<span class="\#(classes(for: .keySeparator))" aria-hidden="true">+</span>"#
				return "\(separator)<kbd>\(key)</kbd>"
			}
			.joined()
	}

	/**
	A link to the section, with a link icon and a check icon that `site.js` shows after copying the URL.
	*/
	func headingAnchor(id: String) -> String {
		// Elementary writes an SVG path as `<path … />`, so the icons are written as HTML, which keeps the markup as it was.
		let icon = { (element: MarkdownElement, path: String) in
			HTMLRaw(#"<svg class="\#(classes(for: element).escapedForHTML)" width="16" height="16" viewBox="0 0 16 16" fill="currentColor" aria-hidden="true"><path d="\#(path)"/></svg>"#)
		}

		return a(.href("#\(id)"), .class(classes(for: .headingAnchor)), .data("copy-link", value: "")) {
			icon(.headingAnchorLinkIcon, "M7.775 3.275a.75.75 0 001.06 1.06l1.25-1.25a2 2 0 112.83 2.83l-2.5 2.5a2 2 0 01-2.83 0 .75.75 0 00-1.06 1.06 3.5 3.5 0 004.95 0l2.5-2.5a3.5 3.5 0 00-4.95-4.95l-1.25 1.25zm-.025 9.45a.75.75 0 01-1.06-1.06l-1.25 1.25a2 2 0 01-2.83-2.83l2.5-2.5a2 2 0 012.83 0 .75.75 0 001.06-1.06 3.5 3.5 0 00-4.95 0l-2.5 2.5a3.5 3.5 0 004.95 4.95l1.25-1.25z")
			icon(.headingAnchorCheckIcon, "M13.78 4.22a.75.75 0 010 1.06l-7.25 7.25a.75.75 0 01-1.06 0L2.22 9.28a.75.75 0 011.06-1.06L6 10.94l6.72-6.72a.75.75 0 011.06 0z")
		}
		.accessibilityLabel("Copy link to section")
		.render()
	}

	/**
	The container of a table, which scrolls a table that is wider than the content.

	- Parameter label: The name of the region, for screen readers.
	*/
	func tableContainer(label: String, tableHTML: String) -> String {
		div(.class(classes(for: .tableContainer)), .tabindex(0), .role("region")) {
			HTMLRaw("\n" + tableHTML)
		}
		.accessibilityLabel(label)
		.render()
	}
}
