import Elementary
import Synchronization

/**
The style sets and scripts that a page uses, collected while it renders, like SwiftUI preferences.

Applying a style with ``Elementary/HTML/style(_:)`` adds its style set, and ``ModuleScript`` adds a script. The layout renders the page body first in ``collect(_:)``, and then writes only the styles and scripts the page uses.

```swift
let resources = PageResources()
let body = resources.collect {
	PageBody().render()
}

resources.styleNodes // The rules of every style set the body used.
```
*/
public final class PageResources: Sendable {
	private struct State {
		var styleSets = [ObjectIdentifier: Int]()
		var styleNodes = [@Sendable () -> [StyleNode]]()
		var classNames = [String: ObjectIdentifier]()
		var duplicateClassNames = Set<String>()
		var scripts = [String]()
	}

	@TaskLocal static var current: PageResources?

	private let state: Mutex<State>
	private let sharedStyleSets: Set<ObjectIdentifier>

	/**
	- Parameter sharedStyleSets: Style sets that are in a shared stylesheet, so they are not collected.
	*/
	public init(sharedStyleSets: [any StyleSet.Type] = []) {
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
	*/
	public func collect<Value>(_ render: () throws -> Value) rethrows -> Value {
		try Self.$current.withValue(self) {
			try render()
		}
	}

	func use<Styles: StyleSet>(_ styles: Styles.Type) {
		state.withLock { state in
			let identifier = ObjectIdentifier(styles)

			guard
				!sharedStyleSets.contains(identifier),
				state.styleSets[identifier] == nil
			else {
				return
			}

			state.styleSets[identifier] = state.styleNodes.count
			state.styleNodes.append { Styles.nodes }

			for style in Styles.allCases {
				if let existing = state.classNames[style.className], existing != identifier {
					state.duplicateClassNames.insert(style.className)
				}

				state.classNames[style.className] = identifier
			}
		}
	}

	func require(script path: String) {
		state.withLock { state in
			if !state.scripts.contains(path) {
				state.scripts.append(path)
			}
		}
	}

	/**
	The rules of the style sets, in the order the page first used them.
	*/
	public var styleNodes: [StyleNode] {
		state.withLock(\.styleNodes).flatMap { $0() }.uniqueDefinitions
	}

	/**
	The scripts, in the order the page first required them, each once.
	*/
	public var scripts: [String] {
		state.withLock(\.scripts)
	}

	/**
	Class names that more than one style set generates, which would make their styles clash.
	*/
	public var duplicateClassNames: Set<String> {
		state.withLock(\.duplicateClassNames)
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
	let path: String

	public init(_ path: String) {
		self.path = path
	}

	public var body: some HTML {
		PageResources.current?.require(script: path)
		return EmptyHTML()
	}
}
