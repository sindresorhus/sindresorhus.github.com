import Elementary

extension HTMLAttribute where Tag: HTMLTrait.Attributes.Global {
	public static func ariaCurrent(_ value: String) -> Self {
		.custom(name: "aria-current", value: value)
	}

	public static func ariaControls(_ id: String) -> Self {
		.custom(name: "aria-controls", value: id)
	}

	public static func ariaDescribedBy(_ id: String) -> Self {
		.custom(name: "aria-describedby", value: id)
	}

	/**
	Names the element with the text of another element, like a section with its heading.
	*/
	public static func ariaLabelledBy(_ id: String) -> Self {
		.custom(name: "aria-labelledby", value: id)
	}

	public static func ariaExpanded(_ isExpanded: Bool) -> Self {
		.custom(name: "aria-expanded", value: isExpanded ? "true" : "false")
	}

	/**
	Whether a toggle button is on, like a tool of a drawing program.
	*/
	public static func ariaPressed(_ isPressed: Bool) -> Self {
		.custom(name: "aria-pressed", value: isPressed ? "true" : "false")
	}

	/**
	Marks a dialog that covers the page, so screen readers keep to it while it is open.
	*/
	public static var ariaModal: Self {
		.custom(name: "aria-modal", value: "true")
	}
}

extension HTML where Tag: HTMLTrait.Attributes.Global {
	/**
	The name that screen readers say for the element, like SwiftUI's `accessibilityLabel(_:)`. Use it when the visible content does not describe the element, like an icon.
	*/
	public func accessibilityLabel(_ label: String) -> _AttributedContent<Self> {
		attributes(.custom(name: "aria-label", value: label))
	}

	/**
	Hides decorative content from screen readers, like SwiftUI's `accessibilityHidden(_:)`.
	*/
	public func accessibilityHidden(_ isHidden: Bool = true) -> _AttributedContent<Self> {
		attributes(.custom(name: "aria-hidden", value: "true"), when: isHidden)
	}

	/**
	The tooltip, like SwiftUI's `help(_:)`.
	*/
	// TODO: Use an interest invoker (`interestfor`) with a styled popover instead of `title` when Safari and Firefox support it.
	public func help(_ text: String) -> _AttributedContent<Self> {
		attributes(.title(text))
	}

	/**
	Hides the element with the `hidden` attribute when the condition is true, like content that a script shows.
	*/
	public func hidden(when condition: Bool) -> _AttributedContent<Self> {
		attributes(.hidden, when: condition)
	}

	/**
	Leaves the text of the element out of the snippets that search engines show for the page, like navigation and footers, with `data-nosnippet`.
	*/
	public func hiddenFromSearchSnippets() -> _AttributedContent<Self> {
		attributes(.data("nosnippet", value: ""))
	}
}

extension HTMLAttribute where Tag: HTMLTrait.Attributes.href {
	/**
	A link to a page of the site.
	*/
	public static func href(_ path: RoutePath) -> Self {
		.href(path.description)
	}

	/**
	A link to a page of the site, a page elsewhere, or a section of the same page.
	*/
	public static func href(_ destination: LinkDestination) -> Self {
		.href(destination.description)
	}
}

extension HTMLAttribute where Tag: HTMLTrait.Attributes.src {
	/**
	A file of the site, like an image.
	*/
	public static func src(_ path: RoutePath) -> Self {
		.src(path.description)
	}
}

extension HTMLTrait.Attributes {
	/**
	The elements with a `media` attribute.
	*/
	public protocol media {}
}

extension HTMLTag.meta: HTMLTrait.Attributes.media {}
extension HTMLTag.source: HTMLTrait.Attributes.media {}

extension HTMLAttribute where Tag: HTMLTrait.Attributes.media {
	/**
	The media that the element applies to, like the dark theme color, or the dark image of a `<picture>`.
	*/
	public static func media(_ query: MediaQuery) -> Self {
		HTMLAttribute(name: "media", value: query.description)
	}
}

extension HTMLAttribute where Tag == HTMLTag.source {
	/**
	The image of the source of a `<picture>`, like a still image for visitors who prefer reduced motion.
	*/
	public static func srcset(_ path: RoutePath) -> Self {
		.custom(name: "srcset", value: path.description)
	}
}

extension HTMLAttribute where Tag == HTMLTag.button {
	/**
	Shows or hides the popover with the ID when the button is pressed, without a script.
	*/
	public static func popoverTarget(_ id: String) -> Self {
		.custom(name: "popovertarget", value: id)
	}
}

extension HTMLAttribute where Tag == HTMLTag.video {
	public static var loop: Self {
		.custom(name: "loop", value: "")
	}

	/**
	Plays without sound. Browsers only allow muted videos to play without a click.
	*/
	public static var muted: Self {
		.custom(name: "muted", value: "")
	}

	/**
	Plays in the page on iPhone, instead of full screen.
	*/
	public static var playsInline: Self {
		.custom(name: "playsinline", value: "")
	}

	public enum Preload: String, Sendable {
		case none
		case metadata
		case auto
	}

	/**
	How much of the video loads before it plays.
	*/
	public static func preload(_ preload: Preload) -> Self {
		.custom(name: "preload", value: preload.rawValue)
	}
}

extension HTMLAttribute where Tag == HTMLTag.img {
	/**
	Loads the image when it is about to scroll into view.
	*/
	public static var lazyLoading: Self {
		.custom(name: "loading", value: "lazy")
	}

	/**
	Decodes the image off the main thread, so a large image does not delay other content.
	*/
	public static var asyncDecoding: Self {
		.custom(name: "decoding", value: "async")
	}

	public enum FetchPriority: String, Sendable {
		case high
		case low
		case auto
	}

	/**
	How soon the browser loads the image compared to other resources, like `high` for the main image of the page.
	*/
	public static func fetchPriority(_ priority: FetchPriority) -> Self {
		.custom(name: "fetchpriority", value: priority.rawValue)
	}
}
