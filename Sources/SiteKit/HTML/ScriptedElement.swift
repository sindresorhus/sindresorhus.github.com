import Elementary
import Foundation

/**
A component that is a custom element with a script: Swift renders all its markup, without a shadow DOM, and the script of the element adds the behavior, so the markup is there before the script runs.

The element replaces the root element of the component: it renders `content` inside the custom element, with the `root` style of the component. The tag name comes from the type name, like the class names of a ``StyleSet``, so it is the class name of the root style too, like `feed-ticker` for `FeedTicker`.

The script is the `.js` file with the same name in the `Scripts` folder next to the Swift file, or a short script inline in the Swift file (``ElementScript``).

A script file is a module that defines its element, with the tag name of the element, and a class named like the type. It extends a base class of the site, or `HTMLElement` for a small element that needs none of its helpers:

```js
import ScriptedElement from '/scripts/scripted-element.js';

class FeedTicker extends ScriptedElement {
	connected() {
		this.on(this.parts.refresh, 'click', () => {
			this.parts.refresh.disabled = true;
		});
	}
}

customElements.define('feed-ticker', FeedTicker);
```

The build publishes every script file unchanged at `/scripts/elements/<file name>`, like `/scripts/elements/FeedTicker.js` (``Project/elementScripts()``), and the page loads it like a ``ModuleScript``. So the build needs no list of the elements: it finds the scripts in the `Scripts` folders. The tag name is written twice, in the type name and in the script, so the site tests that each element on a page is defined.

An inline script is for a small element: it only has the class, `export default class extends HTMLElement {`, and the page that shows the element gets it once, with the definition of the element (``generatedScript()``), so its tag name is never written by hand.

```swift
struct FeedTicker: ScriptedElement {
	static let script = ElementScript()

	var content: some HTML {
		button(.part(Parts.refresh), .type(.button)) {
			"Refresh"
		}
		.style(Styles.refresh)
	}

	enum Parts: String, ElementPartSet {
		case refresh
	}

	enum Styles: ElementStyleSet {
		case root
		case refresh

		var style: Style {
			switch self {
			case .root:
				Style().display(.block)
			case .refresh:
				Style().padding(.rootEm(0.5))
			}
		}
	}
}
```

A custom element is inline by default, so the root style sets the display. A small element that only adds behavior to the element inside it, like a button, can use `display: contents`, so the layout around it is the same as without it.
*/
public protocol ScriptedElement: HTML, SendableMetatype {
	associatedtype Content: HTML
	associatedtype Styles: ElementStyleSet
	associatedtype Parts: ElementPartSet = NoElementParts
	associatedtype States: ElementStateSet = NoElementStates
	associatedtype Config: Encodable = Never?

	/**
	The script of the element, in the `Scripts` folder next to the Swift file: `static let script = ElementScript()`.
	*/
	static var script: ElementScript { get }

	/**
	The markup inside the element.
	*/
	@HTMLBuilder
	var content: Content { get }

	/**
	Values for the script, which it reads as `this.config`, like the size of a board that the markup uses too. The element has none by default.
	*/
	var config: Config { get }

	/**
	More attributes of the element itself, like an `id` that links on the page jump to, a `tabindex`, or a `role` and an `aria-label` for the element that was a `section` before. The element has none by default. A class is added to the class of the root style, and `data-config` is for ``config``.

	```swift
	var rootAttributes: [HTMLAttribute<ElementTag<Self>>] {
		[.id("feed"), .role("region"), .ariaLabelledBy("feed-title")]
	}
	```

	The place that uses the element can add attributes too, like `FeedTicker().attributes(.id("news"))`.
	*/
	var rootAttributes: [HTMLAttribute<ElementTag<Self>>] { get }
}

extension ScriptedElement where Config == Never? {
	public var config: Never? {
		nil
	}
}

extension ScriptedElement {
	public var rootAttributes: [HTMLAttribute<ElementTag<Self>>] {
		[]
	}

	public var body: HTMLElement<ElementTag<Self>, Content> {
		PageResources.current?.require(element: Self.self)

		var attributes: [HTMLAttribute<ElementTag<Self>>] = [.class(classNames(Styles.root))]

		if let config = configJSON {
			attributes.append(.custom(name: "data-config", value: config))
		}

		attributes.append(contentsOf: rootAttributes)

		return HTMLElement(attributes: attributes) {
			content
		}
	}

	/**
	The config as JSON, or `nil` when it is `nil`.
	*/
	private var configJSON: String? {
		// Encoding a config of plain values only fails for a mistake, like a `Double.nan`, which stops the build, like in ``JSONScript``, so the script never runs without its config.
		let json = JSONEncoder.pageJSON(config)
		return json == "null" ? nil : json
	}

	/**
	The name of the custom element, like `feed-ticker` for `FeedTicker`, or `geo-cities-page-clock` for `GeoCitiesPage.Clock`. It is the class name of the root style too.

	It is computed once, as Elementary reads it for the start tag and the end tag each time an element renders, and the name comes from reflection.
	*/
	public static var tagName: String {
		cached(for: Self.self) {
			typePath(of: Self.self).joined().kebabCased
		}
	}

	/**
	The script that the page writes for an element with an inline script: the class with the name of the type, so it can be defined, and the definition of the element. A script file defines its element itself.

	An inline script is for a small element, so it extends `HTMLElement` and imports nothing. Throws when it does not have exactly one `export default class extends HTMLElement {` line.
	*/
	public static func generatedScript() throws -> String {
		var source = try script.source
		let declarations = source.ranges(of: inlineClassDeclaration)

		guard
			declarations.count == 1,
			let declaration = declarations.first
		else {
			throw ElementScriptError.classDeclaration("The inline script of \(Self.self)")
		}

		let className = String(describing: Self.self)
		source.replaceSubrange(declaration, with: "export default class \(className) extends HTMLElement {")

		return """
		\(source)
		customElements.define('\(tagName)', \(className));

		"""
	}
}

/**
The line that declares the class of an inline script (``ScriptedElement/generatedScript()``). Not a literal in the function, as Swift parses a regex literal each time the code runs, and the function runs for each page that shows the element.
*/
nonisolated(unsafe) private let inlineClassDeclaration = /^export default class extends HTMLElement \{$/.anchorsMatchLineEndings()

/**
The script of a ``ScriptedElement``: the `.js` file with the same name as the Swift file that creates it, in the `Scripts` folder next to it, like `Scripts/Clock.js` for `Clock.swift`, or a short script inline in the Swift file.

The build reads a file from the source directory, so the preview server shows a change to it without building the tool again. The target of the Swift file excludes the `Scripts` folder in `Package.swift`, so the scripts need no entry each. An inline script needs neither, but a change to it builds the tool again, and it has no syntax highlighting, so use it only for a few lines.
*/
public struct ElementScript: Sendable {
	private enum Location {
		case file(URL)
		case inline(String)
	}

	private let location: Location

	/**
	The path that the build publishes a script file at, like `/scripts/elements/Clock.js` for `Scripts/Clock.js` (``Project/elementScripts()``).
	*/
	static func publishedPath(of file: URL) -> RoutePath {
		RoutePath("/scripts/elements").appending(file.lastPathComponent)
	}

	/**
	- Parameter swiftFile: The Swift file. Leave it out, so it is the file that creates the script.
	*/
	public init(swiftFile: String = #filePath) {
		let swiftFile = URL(filePath: swiftFile)
		self.location = .file(swiftFile.deletingLastPathComponent().appending(path: "Scripts").appending(path: swiftFile.deletingPathExtension().lastPathComponent).appendingPathExtension("js"))
	}

	/**
	A short script in the Swift file, as a raw string, so backslashes and `${}` stay as they are:

	```swift
	static let script = ElementScript(inline: #"""
	export default class extends HTMLElement {
		connectedCallback() {}
	}
	"""#)
	```

	The page writes it in a `<script>` element as it is, so it must not contain `</script`.
	*/
	public init(inline source: String) {
		self.location = .inline(source)
	}

	/**
	The file of the script, or `nil` for an inline script.
	*/
	public var file: URL? {
		switch location {
		case .file(let file):
			file
		case .inline:
			nil
		}
	}

	/**
	The path that the build publishes the script file at, like `/scripts/elements/Clock.js`, or `nil` for an inline script.
	*/
	public var path: RoutePath? {
		file.map(Self.publishedPath(of:))
	}

	/**
	The text of the script.
	*/
	public var source: String {
		get throws {
			switch location {
			case .file(let file):
				try String(contentsOf: file, encoding: .utf8)
			case .inline(let source):
				source
			}
		}
	}
}

public enum ElementScriptError: Error, CustomStringConvertible {
	case classDeclaration(String)

	public var description: String {
		switch self {
		case .classDeclaration(let script):
			"\(script) must have one line “export default class extends HTMLElement {”. A script that needs a base class of the site, like ScriptedElement, is a script file."
		}
	}
}

/**
The tag of a ``ScriptedElement``, which Elementary renders with the tag name of the element.
*/
public enum ElementTag<Element: ScriptedElement>: HTMLTrait.Paired {
	public static var name: String {
		Element.tagName
	}
}

/**
The styles of a ``ScriptedElement``. The `root` style is on the element itself.
*/
public protocol ElementStyleSet: StyleSet {
	static var root: Self { get }
}

/**
The elements inside a ``ScriptedElement`` that its script uses, like a canvas and its buttons, as a nested `enum Parts: String, ElementPartSet`. The raw value is the name of the case, so `.part(Parts.newGame)` renders `data-part="newGame"`, and the script finds it as `this.parts.newGame`. The script only finds the parts of its own element, not the parts of an element inside it. A part inside a `template` is in the same enum, and the script finds it in a copy of the template, with `clone()`, like `const {element: row, parts} = this.clone('rowTemplate'); parts.name.textContent = name;`.

Use parts instead of IDs. Only use an ID where HTML needs one, like for `label(for:)` and ARIA references.
*/
public protocol ElementPartSet: RawRepresentable<String>, CaseIterable, Sendable {}

/**
The parts of an element without parts.
*/
public enum NoElementParts: ElementPartSet {
	public init?(rawValue: String) {
		nil
	}

	public var rawValue: String {
		switch self {}
	}
}

/**
The states that the script of a ``ScriptedElement`` sets on the element or its parts as `data-state`, for the styles, like `copied` for a copy button, as a nested `enum States: String, ElementStateSet`. The raw value is the name of the case, so the script sets it as `button.dataset.state = 'copied'`, the styles use it as `.when(States.copied) { … }`, and Swift renders a first state with `.state(States.copied)`. A test checks that the states that the script sets as literals are cases, and that each case is set and styled.

A component that is not a custom element, but that a page script sets states on, declares its states the same way.

Do not copy an ARIA state or a checked control to a state. Style it directly, so the look always matches what screen readers say: a toggle button with ``Style/pressed(_:)``, the current item of a set with ``Style/current(_:)``, and the element around them with ``Style/descendantPressed(_:)`` or ``Style/descendantChecked(_:)``.
*/
public protocol ElementStateSet: RawRepresentable<String>, CaseIterable, Sendable {}

extension ElementStateSet {
	/**
	The attribute selector of the state, like `[data-state="copied"]`, for a selector that a style builds itself, like `&:has(> [data-state="copied"])`.
	*/
	public var selector: CSSSelector {
		"[data-state=\"\(raw: rawValue)\"]"
	}
}

/**
The states of an element without states.
*/
public enum NoElementStates: ElementStateSet {
	public init?(rawValue: String) {
		nil
	}

	public var rawValue: String {
		switch self {}
	}
}

extension HTMLAttribute where Tag: HTMLTrait.Attributes.Global {
	/**
	Marks the element as a part of its ``ScriptedElement``, which the script finds as `this.parts.name`, or as `parts.name` in a copy of a template (`clone()`).
	*/
	public static func part(_ part: some ElementPartSet) -> Self {
		.custom(name: "data-part", value: part.rawValue)
	}

	/**
	The state that the element has before its script changes it, like the tab that is open first.
	*/
	public static func state(_ state: some ElementStateSet) -> Self {
		.custom(name: "data-state", value: state.rawValue)
	}
}
