import Elementary
import Synchronization

/**
The style sets and scripts that a page uses, collected while it renders, like SwiftUI preferences.

Applying a style with ``Elementary/HTML/style(_:)`` adds it, a style on an element (``ElementStyle``) adds its rule, and ``ModuleScript`` adds a script. The layout renders the page body first in ``collect(_:)``, and then writes only the styles and scripts the page uses. A style set adds only the rules of the cases the page applies.

```swift
let resources = PageResources()
let body = try resources.collect {
	PageBody().render()
}

resources.styleNodes // The rules of every style the body used.
```
*/
public final class PageResources: Sendable {
	private struct State {
		var styleSets = Set<ObjectIdentifier>()
		var styleNodes = [@Sendable (_ usedClassNames: Set<String>) -> [StyleNode]]()
		var usedClassNames = Set<String>()
		var classNames = [String: ObjectIdentifier]()
		var duplicateClassNames = Set<String>()
		var scripts = [RoutePath]()
		var inlineScriptElements = [any ScriptedElement.Type]()
		var elementStyleClassNames = Set<String>()
		var elementStyleNodes = [StyleNode]()

		/**
		What the rendering used, so another collector can use it too (``include(_:)``).
		*/
		var replays = [@Sendable (PageResources) -> Void]()
	}

	@TaskLocal static var current: PageResources?

	private let state: Mutex<State>
	private let sharedStyleSets: Set<ObjectIdentifier>

	/**
	- Parameter sharedStylesheet: The stylesheet that the page links to. Its style sets are not collected.
	*/
	public init(sharedStylesheet: Stylesheet? = nil) {
		let sharedStyleSets = sharedStylesheet?.styleSets ?? []
		self.sharedStyleSets = Set(sharedStyleSets.map(ObjectIdentifier.init))

		// The class names of the shared style sets are taken too, so a page style set with the same name is a duplicate.
		var state = State()

		for styles in sharedStyleSets {
			for (className, identifier) in Self.classNames(of: styles) {
				state.classNames[className] = identifier
			}
		}

		self.state = Mutex(state)
	}

	private static func classNames<Styles: StyleSet>(of styles: Styles.Type) -> [(String, ObjectIdentifier)] {
		Styles.allCases.map { ($0.className, ObjectIdentifier(styles)) }
	}

	/**
	Runs the rendering with this collector, so the styles and scripts that the rendering uses are added to it.

	Throws ``StyleError/duplicateClassNames(_:)`` when two style sets that the page uses generate the same class name.
	*/
	public func collect<Value>(_ render: () throws -> Value) throws -> Value {
		let value = try Self.$current.withValue(self) {
			try render()
		}

		let duplicateClassNames = state.withLock(\.duplicateClassNames)

		guard duplicateClassNames.isEmpty else {
			throw StyleError.duplicateClassNames(duplicateClassNames.sorted())
		}

		return value
	}

	func use<Styles: StyleSet>(_ style: Styles) {
		state.withLock { state in
			state.replays.append { $0.use(style) }

			let identifier = ObjectIdentifier(Styles.self)

			guard !sharedStyleSets.contains(identifier) else {
				return
			}

			state.usedClassNames.insert(style.className)

			guard state.styleSets.insert(identifier).inserted else {
				return
			}

			// Only the cases that the page uses, in the order of the style set, so the rules keep their order.
			state.styleNodes.append { usedClassNames in
				Styles.allCases
					.filter { usedClassNames.contains($0.className) }
					.flatMap(\.nodes)
			}

			for style in Styles.allCases {
				if
					let existing = state.classNames[style.className],
					existing != identifier
				{
					state.duplicateClassNames.insert(style.className)
				}

				state.classNames[style.className] = identifier
			}
		}
	}

	/**
	Adds the rules of a style that only one element has, once for each class name.
	*/
	func use(_ elementStyle: ElementStyle) {
		state.withLock { state in
			state.replays.append { $0.use(elementStyle) }

			guard state.elementStyleClassNames.insert(elementStyle.className).inserted else {
				return
			}

			state.elementStyleNodes += elementStyle.nodes
		}
	}

	func require(script path: RoutePath) {
		state.withLock { state in
			state.replays.append { $0.require(script: path) }

			if !state.scripts.contains(path) {
				state.scripts.append(path)
			}
		}
	}

	/**
	Adds the inline script of the element to the page, once, however many times the page shows the element.
	*/
	func require<Element: ScriptedElement>(inlineScriptOf element: Element.Type) {
		state.withLock { state in
			state.replays.append { $0.require(inlineScriptOf: element) }

			if !state.inlineScriptElements.contains(where: { $0 == element }) {
				state.inlineScriptElements.append(element)
			}
		}
	}

	/**
	Uses everything that the other collector collected, like the styles of the block directives of a Markdown document that rendered before the page, when the page shows it (``MarkdownContent``).
	*/
	public func include(_ other: PageResources) {
		for replay in other.state.withLock(\.replays) {
			replay(self)
		}
	}

	/**
	The rules of the styles that the page used, by style set in the order the page first used them.
	*/
	public var styleNodes: [StyleNode] {
		let (styleNodes, usedClassNames) = state.withLock { ($0.styleNodes, $0.usedClassNames) }
		return styleNodes.flatMap { $0(usedClassNames) }.uniqueDefinitions
	}

	/**
	The rules of the styles that only one element has (``ElementStyle``), in the order the page first used them. The layout puts them in a cascade layer after the styles of the components, so they win over them.
	*/
	public var elementStyleNodes: [StyleNode] {
		state.withLock(\.elementStyleNodes).uniqueDefinitions
	}

	/**
	The scripts, in the order the page first required them, each once.
	*/
	public var scripts: [RoutePath] {
		state.withLock(\.scripts)
	}

	/**
	The elements with an inline script (``ElementScript/init(inline:)``) that the page shows, in the order the page first showed them, each once, as an element can only be defined once.
	*/
	public var inlineScriptElements: [any ScriptedElement.Type] {
		state.withLock(\.inlineScriptElements)
	}
}

public enum StyleError: Error, CustomStringConvertible {
	/**
	Two style sets generate the same class name, like `Badge.Styles` and a top-level `BadgeStyles`, so their styles would clash.
	*/
	case duplicateClassNames([String])

	public var description: String {
		switch self {
		case .duplicateClassNames(let names):
			"More than one style set generates the class names \(names.joined(separator: ", ")). Rename one of the types."
		}
	}
}

/**
A JavaScript module that a component needs. It renders nothing where it is used: the layout adds each script once, at the end of the page.

```swift
var body: some HTML {
	button(.id("share-button")) {
		"Share"
	}

	ModuleScript("/scripts/share.js")
}
```
*/
public struct ModuleScript: HTML, Sendable {
	let path: RoutePath

	public init(_ path: RoutePath) {
		self.path = path
	}

	public var body: some HTML {
		PageResources.current?.require(script: path)
		return EmptyHTML()
	}
}
