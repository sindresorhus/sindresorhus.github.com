import Elementary
import Foundation
import SOML

/**
The ID of an HTML element, kept as a distinct type when another attribute refers to it, like `for`, `aria-labelledby`, or `popovertarget`.
*/
public struct ElementID: Hashable, Sendable, CustomStringConvertible, ValidatedValue {
	public let rawValue: String

	/**
	Creates an ID from its raw HTML value, like `email-hint`. Empty text or ASCII whitespace is a programmer error; use ``init(validating:)`` for dynamic input.
	*/
	public init(_ rawValue: String) {
		do {
			try self.init(validating: rawValue)
		} catch {
			preconditionFailure(error.reason)
		}
	}

	/**
	Creates an ID that is nonempty and contains no ASCII whitespace, as HTML requires. Uniqueness and whether a referenced element exists are checked on the complete page.
	*/
	public init(validating rawValue: String) throws(ContentError) {
		guard
			!rawValue.isEmpty,
			!rawValue.unicodeScalars.contains(where: \.isHTMLWhitespace)
		else {
			throw ContentError(reason: "An element ID must not be empty or contain ASCII whitespace, got “\(rawValue)”.")
		}

		self.rawValue = rawValue
	}

	public var description: String {
		rawValue
	}
}

/**
The source of an image: a site path or an absolute URL. A fragment alone names part of the current document, not an image. Paths can retain queries and image fragments, like an SVG view.
*/
public struct ImageSource: ValidatedValue, Hashable, Sendable, CustomStringConvertible {
	private let destination: LinkDestination

	private init(destination: LinkDestination) {
		self.destination = destination
	}

	/**
	Parses an authored source, rejecting fragment-only navigation destinations.
	*/
	public init(validating source: String) throws(ContentError) {
		let destination = try LinkDestination(validating: source)
		guard !destination.isFragment else {
			throw ContentError(reason: "An image source must be a site path or an absolute URL, got “\(source)”.")
		}

		self.init(destination: destination)
	}

	/**
	An image published on the site, with an optional query and fragment, like an SVG view.
	*/
	public static func path(_ path: RoutePath, query: [URLQueryItem] = [], fragment: String? = nil) -> Self {
		Self(destination: .path(path, query: query, fragment: fragment))
	}

	/**
	An image at an absolute URL.
	*/
	public static func url(_ url: AbsoluteURL) -> Self {
		Self(destination: .url(url))
	}

	public var description: String {
		destination.description
	}
}

extension Unicode.Scalar {
	/**
	Whether the scalar is ASCII whitespace as defined by HTML: tab, line feed, form feed, carriage return, or space.
	*/
	var isHTMLWhitespace: Bool {
		"\t\n\u{C}\r ".unicodeScalars.contains(self)
	}
}

/**
The supported attributes whose values refer to element IDs. Rendering and link validation share this list so a new attribute cannot silently escape reference checks.
*/
public enum IDReferenceAttribute: String, CaseIterable, Sendable {
	case ariaControls = "aria-controls"
	case ariaDescribedBy = "aria-describedby"
	case ariaLabelledBy = "aria-labelledby"
	case ariaOwns = "aria-owns"
	case `for`
	case list
	case popoverTarget = "popovertarget"
	case commandFor = "commandfor"

	/**
	The IDs in the value, preserving their order. A single-ID attribute does not interpret spaces as a list.
	*/
	func ids(in value: String) -> [String] {
		switch self {
		case .ariaControls, .ariaDescribedBy, .ariaLabelledBy, .ariaOwns:
			value.unicodeScalars.split(whereSeparator: \.isHTMLWhitespace).map { String(String.UnicodeScalarView($0)) }
		case .for, .list, .popoverTarget, .commandFor:
			[value]
		}
	}
}

extension LinkDestination {
	/**
	A link to an element of the current page.
	*/
	public static func fragment(_ id: ElementID) -> Self {
		.fragment(id.rawValue)
	}

	/**
	A link to an element of another page of the site.
	*/
	public static func path(_ path: RoutePath, query: [URLQueryItem] = [], fragment: ElementID) -> Self {
		.path(path, query: query, fragment: fragment.rawValue)
	}
}

extension HTMLAttribute where Tag: HTMLTrait.Attributes.Global {
	/**
	The ID of this element, which links and other attributes can refer to.
	*/
	public static func id(_ id: ElementID) -> Self {
		.id(id.rawValue)
	}

	/**
	Tells the translation of browsers, like Safari and Chrome, to leave the text as it is (`translate="no"` in HTML), like code, keys, and names, which a translation would change, like a command that then fails when it is copied, or an app name that then cannot be found on the App Store.
	*/
	public static var notTranslated: Self {
		.custom(name: "translate", value: "no")
	}

	/**
	The kind of current item in a navigation or sequence.
	*/
	public static func ariaCurrent(_ value: ARIACurrent) -> Self {
		.custom(name: "aria-current", value: value.rawValue)
	}

	public static func ariaControls(_ id: ElementID, _ moreIDs: ElementID...) -> Self {
		.idReferences(.ariaControls, [id] + moreIDs)
	}

	public static func ariaDescribedBy(_ id: ElementID, _ moreIDs: ElementID...) -> Self {
		.idReferences(.ariaDescribedBy, [id] + moreIDs)
	}

	/**
	Names the element with the text of another element, like a section with its heading.
	*/
	public static func ariaLabelledBy(_ id: ElementID, _ moreIDs: ElementID...) -> Self {
		.idReferences(.ariaLabelledBy, [id] + moreIDs)
	}

	/**
	The elements controlled by this element, omitted when the list is empty.
	*/
	public static func ariaControls(_ ids: [ElementID]) -> Self? {
		ids.isEmpty ? nil : .idReferences(.ariaControls, ids)
	}

	/**
	The descriptions of this element, omitted when the list is empty. Reference order is preserved.
	*/
	public static func ariaDescribedBy(_ ids: [ElementID]) -> Self? {
		ids.isEmpty ? nil : .idReferences(.ariaDescribedBy, ids)
	}

	/**
	The labels of this element, omitted when the list is empty. Reference order is preserved.
	*/
	public static func ariaLabelledBy(_ ids: [ElementID]) -> Self? {
		ids.isEmpty ? nil : .idReferences(.ariaLabelledBy, ids)
	}

	/**
	Serializes a list of HTML ID references with its meaningful order.
	*/
	private static func idReferences(_ attribute: IDReferenceAttribute, _ ids: [ElementID]) -> Self {
		.custom(name: attribute.rawValue, value: ids.map(\.rawValue).joined(separator: " "))
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

	/**
	What screen readers call the kind of the element, instead of its role, like “carousel” for a section of slides (`aria-roledescription` in HTML).
	*/
	public static func ariaRoleDescription(_ description: String) -> Self {
		.custom(name: "aria-roledescription", value: description)
	}

	/**
	The name that screen readers say for the element, like for an icon or a region.
	*/
	public static func ariaLabel(_ label: String) -> Self {
		.custom(name: "aria-label", value: label)
	}

	/**
	How the element announces a change while the visitor reads the page, like a status line that a script fills.
	*/
	public static func ariaLive(_ value: ARIALive) -> Self {
		.custom(name: "aria-live", value: value.rawValue)
	}

	/**
	Whether the content is still loading, so screen readers wait for it.
	*/
	public static func ariaBusy(_ isBusy: Bool = true) -> Self {
		.custom(name: "aria-busy", value: isBusy ? "true" : "false")
	}

	/**
	The label of the Enter key of the keyboard on a phone, like “Send” for the last field of a form.
	*/
	public static func enterKeyHint(_ hint: EnterKeyHint) -> Self {
		.custom(name: "enterkeyhint", value: hint.rawValue)
	}

	/**
	Whether the browser checks the spelling of the text, like `false` for a field that filters names.
	*/
	public static func spellcheck(_ isEnabled: Bool) -> Self {
		.custom(name: "spellcheck", value: isEnabled ? "true" : "false")
	}

	/**
	Which letters the keyboard on a phone writes as capitals, like the first letter of each sentence of a message.
	*/
	public static func autocapitalize(_ value: Autocapitalize) -> Self {
		.custom(name: "autocapitalize", value: value.rawValue)
	}
}

extension HTML where Tag: HTMLTrait.Attributes.Global {
	/**
	Adds an attribute when it is present, like `.attributes(optional: id.map { .id($0) })` for an optional element ID.
	*/
	public func attributes(optional attribute: HTMLAttribute<Tag>?) -> _AttributedContent<Self> {
		attributes(contentsOf: attribute.map { [$0] } ?? [])
	}

	/**
	The name that screen readers say for the element, like SwiftUI's `accessibilityLabel(_:)`. Use it when the visible content does not describe the element, like an icon.
	*/
	public func accessibilityLabel(_ label: String) -> _AttributedContent<Self> {
		attributes(.ariaLabel(label))
	}

	/**
	Hides decorative content from screen readers, like SwiftUI's `accessibilityHidden(_:)`. Passing `false` resets an earlier value on this element; it does not unhide content inside a hidden ancestor.
	*/
	public func accessibilityHidden(_ isHidden: Bool = true) -> _AttributedContent<Self> {
		attributes(.custom(name: "aria-hidden", value: isHidden ? "true" : "false"))
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

	/**
	An image published on the site or at an absolute URL.
	*/
	public static func src(_ source: ImageSource) -> Self {
		.src(source.description)
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

	/**
	The media type of the image of the source, like `image/jxl`, so a browser that cannot show it uses the next source, or the image of the `<picture>`.
	*/
	public static func type(_ mediaType: String) -> Self {
		.custom(name: "type", value: mediaType)
	}
}

extension HTMLAttribute where Tag == HTMLTag.input {
	/**
	The suggestions of the field, a `datalist` with this ID.
	*/
	public static func list(id: ElementID) -> Self {
		.custom(name: IDReferenceAttribute.list.rawValue, value: id.rawValue)
	}
}

extension HTMLAttribute where Tag == HTMLTag.time {
	/**
	The date and the time for machines, in UTC, like `2026-10-30T12:00:00Z`.
	*/
	public static func dateTime(_ date: Date) -> Self {
		.custom(name: "datetime", value: date.ISO8601Format())
	}

	/**
	The day for machines, in UTC, like `2026-10-30`.
	*/
	public static func dateTime(_ day: SOML.Date) -> Self {
		.custom(name: "datetime", value: day.description)
	}
}

extension HTMLAttribute where Tag == HTMLTag.button {
	/**
	Shows or hides the popover with the ID when the button is pressed, without a script.
	*/
	public static func popoverTarget(_ id: ElementID) -> Self {
		.custom(name: IDReferenceAttribute.popoverTarget.rawValue, value: id.rawValue)
	}
}

extension HTMLAttribute where Tag == HTMLTag.label {
	/**
	The form control that this label names.
	*/
	public static func `for`(_ id: ElementID) -> Self {
		.custom(name: IDReferenceAttribute.for.rawValue, value: id.rawValue)
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

	/**
	An image that shows until the video plays, like its first frame.
	*/
	public static func poster(_ path: RoutePath) -> Self {
		.custom(name: "poster", value: path.description)
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

/**
The kind of current item for `aria-current`, so a misspelled state cannot silently lose its accessibility meaning.
*/
public enum ARIACurrent: String, Sendable {
	case page
	case step
	case location
	case date
	case time
	case item = "true"
}

/**
How a live region announces its changes, for `aria-live`.
*/
public enum ARIALive: String, Sendable {
	case off
	case polite
	case assertive
}

/**
The label of the Enter key of the keyboard on a phone, for `enterkeyhint`.
*/
public enum EnterKeyHint: String, Sendable {
	case enter
	case done
	case go
	case next
	case previous
	case search
	case send
}

/**
Which letters the keyboard on a phone writes as capitals, for `autocapitalize`.
*/
public enum Autocapitalize: String, Sendable {
	case none
	case sentences
	case words
	case characters
}
