import Elementary
import Foundation

/**
A component that is a custom element with a script: Swift renders all its markup, without a shadow DOM, and the script of the element adds the behavior, so the markup is there before the script runs.

The element replaces the root element of the component: it renders `content` inside the custom element, with the `root` style of the component. The tag name comes from the type name, like the class names of a ``StyleSet``, so it is the class name of the root style too, like `feed-ticker` for `FeedTicker`.

The script is the `.js` file with the same name in the `Scripts` folder next to the Swift file, or a short script inline in the Swift file (``ElementScript``). It only has the class of the element, which extends a base class of the site, or `HTMLElement` for a small element that needs none of its helpers:

```js
export default class extends ScriptedElement {
	connected() {
		this.on(this.parts.refresh, 'click', () => {
			this.parts.refresh.disabled = true;
		});
	}
}
```

The build writes it to `/scripts/elements/<tag name>.js` with the import of the base class and `customElements.define(…)`, and the page loads it like a ``ModuleScript``. An inline script is instead written into each page that shows the element, once, so it needs no file. The site lists its elements, so the build knows the scripts before the pages render, and the tests check them.

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
		if Self.script.isInline {
			PageResources.current?.require(inlineScriptOf: Self.self)
		} else {
			PageResources.current?.require(script: Self.scriptPath)
		}

		PageResources.current?.use(Styles.root)

		var attributes: [HTMLAttribute<ElementTag<Self>>] = [.class(Styles.root.className)]

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
		let encoder = JSONEncoder()
		encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]

		// Encoding a config of plain values cannot fail.
		let json = String(decoding: (try? encoder.encode(config)) ?? Data(), as: UTF8.self)
		return json == "null" || json.isEmpty ? nil : json
	}

	/**
	The name of the custom element, like `feed-ticker` for `FeedTicker`, or `geo-cities-page-clock` for `GeoCitiesPage.Clock`. It is the class name of the root style too.
	*/
	public static var tagName: String {
		typePath(of: Self.self).joined().kebabCased
	}

	/**
	The path of the script that the build writes for the element.
	*/
	public static var scriptPath: RoutePath {
		RoutePath("/scripts/elements/\(tagName).js")
	}

	/**
	The script that the build writes for the element: the import of the base class that the class of ``script`` extends, the class with the name of the type, so it can be defined, and the definition of the element.

	Throws when the file is missing, when it does not have exactly one `export default class extends Base {` line, or when it extends another class. `HTMLElement` needs no import.

	- Parameter baseClasses: The URLs of the modules of the base classes, by class name, like `/scripts/scripted-element.js` for `ScriptedElement`.
	*/
	public static func generatedScript(baseClasses: [String: String]) throws -> String {
		let name = script.file?.path(percentEncoded: false) ?? "The inline script of \(Self.self)"
		var source = try script.source
		let declarations = source.matches(of: /^export default class extends (\w+) \{$/.anchorsMatchLineEndings())

		guard
			declarations.count == 1,
			let declaration = declarations.first
		else {
			throw ElementScriptError.classDeclaration(name)
		}

		let baseClass = String(declaration.output.1)
		let className = String(describing: Self.self)
		source.replaceSubrange(declaration.range, with: "export default class \(className) extends \(baseClass) {")

		let definition = """
		\(source)
		customElements.define('\(tagName)', \(className));

		"""

		if baseClass == "HTMLElement" {
			return definition
		}

		guard let baseClassPath = baseClasses[baseClass] else {
			throw ElementScriptError.unknownBaseClass(baseClass, script: name, baseClasses: (baseClasses.keys + ["HTMLElement"]).sorted())
		}

		return """
		import \(baseClass) from '\(baseClassPath)';

		\(definition)
		"""
	}
}

/**
The script of a ``ScriptedElement``: the `.js` file with the same name as the Swift file that creates it, in the `Scripts` folder next to it, like `Scripts/Clock.js` for `Clock.swift`, or a short script inline in the Swift file.

The build reads a file from the source directory, so the preview server shows a change to it without building the tool again. The target of the Swift file excludes the `Scripts` folder in `Package.swift`, so the scripts need no entry each. An inline script needs neither, but a change to it builds the tool again, and it has no syntax highlighting, so use it only for a few lines.
*/
public struct ElementScript: Sendable {
	private enum Location: Sendable {
		case file(URL)
		case inline(String)
	}

	private let location: Location

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
	Whether the script is in the Swift file, so the page gets it instead of a script file.
	*/
	public var isInline: Bool {
		file == nil
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
	case unknownBaseClass(String, script: String, baseClasses: [String])

	public var description: String {
		switch self {
		case .classDeclaration(let script):
			"\(script) must have one line “export default class extends Base {”, where Base is a base class of the site, like ScriptedElement, or HTMLElement."
		case .unknownBaseClass(let baseClass, let script, let baseClasses):
			"\(script) extends \(baseClass), which is not a base class of the site. Use one of: \(baseClasses.joined(separator: ", "))."
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
The elements inside a ``ScriptedElement`` that its script uses, like a canvas and its buttons, as a nested `enum Parts: String, ElementPartSet`. The raw value is the name of the case, so `.part(Parts.newGame)` renders `data-part="newGame"`, and the script finds it as `this.parts.newGame`. The script only finds the parts of its own element, not the parts of an element inside it.

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

extension HTMLAttribute where Tag: HTMLTrait.Attributes.Global {
	/**
	Marks the element as a part of its ``ScriptedElement``, which the script finds as `this.parts.name`.
	*/
	public static func part(_ part: some ElementPartSet) -> Self {
		.custom(name: "data-part", value: part.rawValue)
	}
}
