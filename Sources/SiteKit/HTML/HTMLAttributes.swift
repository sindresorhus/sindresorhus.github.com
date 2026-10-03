import Elementary

extension HTMLAttribute where Tag: HTMLTrait.Attributes.Global {
	public static func ariaLabel(_ value: String) -> Self {
		.custom(name: "aria-label", value: value)
	}

	/**
	Hides decorative content from assistive technology.
	*/
	public static var ariaHidden: Self {
		.custom(name: "aria-hidden", value: "true")
	}

	public static func ariaCurrent(_ value: String) -> Self {
		.custom(name: "aria-current", value: value)
	}

	public static func ariaControls(_ id: String) -> Self {
		.custom(name: "aria-controls", value: id)
	}

	public static func ariaDescribedBy(_ id: String) -> Self {
		.custom(name: "aria-describedby", value: id)
	}

	public static func ariaExpanded(_ isExpanded: Bool) -> Self {
		.custom(name: "aria-expanded", value: isExpanded ? "true" : "false")
	}
}

extension HTML where Tag: HTMLTrait.Attributes.Global {
	/**
	The name that screen readers say for the element, like SwiftUI's `accessibilityLabel(_:)`. Use it when the visible content does not describe the element, like an icon.
	*/
	public func accessibilityLabel(_ label: String) -> _AttributedContent<Self> {
		attributes(.ariaLabel(label))
	}

	/**
	Hides decorative content from screen readers, like SwiftUI's `accessibilityHidden(_:)`.
	*/
	public func accessibilityHidden(_ isHidden: Bool = true) -> _AttributedContent<Self> {
		attributes(.ariaHidden, when: isHidden)
	}

	/**
	Hides the element with the `hidden` attribute when the condition is true, like content that a script shows.
	*/
	public func hidden(when condition: Bool) -> _AttributedContent<Self> {
		attributes(.hidden, when: condition)
	}
}

extension HTMLAttribute where Tag: HTMLTrait.Attributes.href {
	/**
	A link to a page of the site.
	*/
	public static func href(_ path: RoutePath) -> Self {
		.href(path.description)
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
