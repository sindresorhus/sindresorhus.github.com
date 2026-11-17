import Elementary

/**
HTML that the build rendered or escaped, like the HTML of Markdown or of a block directive, so a plain text and HTML are different types, and a text cannot go into a page as HTML by mistake.

In string interpolation, it is its HTML (``description``), so the HTML of a theme can contain it.
*/
public struct HTMLFragment: HTML, Sendable, Hashable, CustomStringConvertible {
	public let rawValue: String

	/**
	HTML that is already a string, like the output of the Markdown renderer.
	*/
	public init(rawValue: String) {
		self.rawValue = rawValue
	}

	/**
	The text, escaped.
	*/
	public init(text: some StringProtocol) {
		self.rawValue = String(text).escapedForHTML
	}

	/**
	No HTML, like a block directive that shows nothing.
	*/
	public static var empty: Self {
		Self(rawValue: "")
	}

	public var description: String {
		rawValue
	}

	public var body: HTMLRaw {
		HTMLRaw(rawValue)
	}
}

extension HTML {
	/**
	The HTML of the component as a fragment, like a card that a block directive renders.

	```swift
	div {
		content
	}
	.renderFragment()
	```
	*/
	public func renderFragment() -> HTMLFragment {
		HTMLFragment(rawValue: render())
	}
}
