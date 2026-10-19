import Elementary
import Synchronization

/**
The named styles of a component. Each case is a style, and its class name is generated from the component and the case, so markup and CSS cannot drift apart.

Nest it in the component as `Styles`, and apply a style with ``Elementary/HTML/style(_:)``. Applying a style adds its rules to the page that renders it, so no stylesheet has to list the component:

```swift
struct FeedCard: HTML {
	var body: some HTML {
		a(.href("/rss.xml")) {
			span { "Blog" }
				.style(Styles.title)
		}
		.style(Styles.root)
	}

	enum Styles: StyleSet {
		case root
		case title

		var style: Style {
			switch self {
			case .root:
				Style()
					.padding(.rootEm(1))
					.cornerRadius(.rootEm(0.5))
			case .title:
				Style()
					.fontWeight(.bold)
			}
		}
	}
}
```

The class names are `feed-card` for `root` and `feed-card-title` for `title`.

Limitation: A style set in a generic type has the same class names for every specialization, but each specialization is another style set, so a page that uses two of them fails with ``StyleError/duplicateClassNames(_:)``. Declare the styles of a generic component outside it, like a top-level `FormFieldStyles` for `FormField<Content>`.
*/
public protocol StyleSet: CaseIterable, Hashable, Sendable {
	var style: Style { get }
}

extension StyleSet {
	/**
	The class name, like `feed-card-title`. The `root` case uses the component name alone, like `feed-card`.
	*/
	public var className: String {
		Self.classNames[self] ?? Self.className(of: self, componentName: Self.componentName)
	}

	private static func className(of style: Self, componentName: String) -> String {
		let name = String(describing: style)
		return name == "root" ? componentName : "\(componentName)-\(name.kebabCased)"
	}

	/**
	The class selector, like `.feed-card-title`, for styling the element from a parent style with ``Style/nested(_:_:)``.
	*/
	public var selector: CSSSelector {
		CSSSelector(className: className)
	}

	private static var componentName: String {
		generatedComponentName(of: Self.self, suffix: "Styles")
	}

	/**
	The class name of each case, computed once, as pages apply styles thousands of times.
	*/
	private static var classNames: [Self: String] {
		cached(for: Self.self) {
			// Once for all the cases, as it reads the name of the type.
			let componentName = componentName
			return Dictionary(uniqueKeysWithValues: allCases.map { ($0, className(of: $0, componentName: componentName)) })
		}
	}

	/**
	The rules of the case, and the keyframes and registered properties it uses. They are computed once.
	*/
	var nodes: [StyleNode] {
		Self.caseNodes[self] ?? []
	}

	private static var caseNodes: [Self: [StyleNode]] {
		cached(for: Self.self) {
			Dictionary(uniqueKeysWithValues: allCases.map { ($0, $0.style.nodes(selector: $0.selector)) })
		}
	}

	/**
	The rules of every case, and then the keyframes and registered properties they use. They are built from the cached nodes of the cases. The stylesheet writes each definition once.
	*/
	static var nodes: [StyleNode] {
		let caseNodes = allCases.map(\.nodes)
		return caseNodes.compactMap(\.first) + caseNodes.flatMap { $0.dropFirst() }
	}

	/**
	The rules of the cases with the class names, like the cases that a page uses, in the order of the style set, so the rules keep their order.
	*/
	static func nodes(usedClassNames: Set<String>) -> [StyleNode] {
		allCases
			.filter { usedClassNames.contains($0.className) }
			.flatMap(\.nodes)
	}
}

/**
The identity of a cached value of a type, without allocating an array for each lookup.
*/
private struct TypeCacheKey: Hashable {
	let type: ObjectIdentifier
	let valueType: ObjectIdentifier
}

private let typeCache = Mutex<[TypeCacheKey: any Sendable]>([:])

/**
A value of a type, like the class names of a style set or the tag name of a scripted element, computed on first use and then cached by the type and the type of the value, so a type has one cached value of each value type. A protocol extension cannot have a stored property, so the values that it computes once are cached here.

The value is computed outside the lock, as a style can use the selector of another case, and so other render threads do not wait for the reflection.
*/
func cached<Value: Sendable>(for type: Any.Type, _ compute: () -> Value) -> Value {
	let key = TypeCacheKey(type: ObjectIdentifier(type), valueType: ObjectIdentifier(Value.self))

	if let value = typeCache.withLock({ $0[key] }) as? Value {
		return value
	}

	let value = compute()

	typeCache.withLock {
		$0[key] = value
	}

	return value
}

/**
The name of the type that encloses a nested type, like `feed-card` for `FeedCard.Styles`, or the type name without the suffix for a top-level type.
*/
func generatedComponentName(of type: Any.Type, suffix: String) -> String {
	let path = typePath(of: type)
	let typeName = String(path.last ?? "")
	// Only the suffix at the end, as the name can have it at the start too, like `StylesheetPreviewStyles`.
	let name = path.count > 1 ? path.dropLast().joined() : (typeName.hasSuffix(suffix) ? String(typeName.dropLast(suffix.count)) : typeName)
	return name.kebabCased
}

/**
The names of a type and the types that enclose it, without the module, like `["FeedCard", "Styles"]` for `FeedCard.Styles`.
*/
func typePath(of type: Any.Type) -> [Substring] {
	// The generic arguments of a generic type, like `<Swift.Int>`, are not part of the name, and can have dots. The innermost first, as they can be nested.
	var reflectedName = String(reflecting: type)

	while let genericArguments = reflectedName.firstRange(of: genericArgumentsPattern) {
		reflectedName.removeSubrange(genericArguments)
	}

	// A private type has its context in its name, like `(unknown context at $1088071a4)`, which is not part of the name.
	return reflectedName.split(separator: ".").dropFirst().filter { !$0.hasPrefix("(") }
}

/**
The innermost generic arguments of a reflected type name, like `<Swift.Int>`. Not a literal in ``typePath(of:)``, as Swift parses a regex literal each time the code runs, and it runs for each scripted element that a page shows.
*/
nonisolated(unsafe) private let genericArgumentsPattern = /<[^<>]*>/

extension String {
	/**
	`FeedCard` → `feed-card`, `URLField` → `url-field`, `Heading2Large` → `heading2-large`.
	*/
	public var kebabCased: String {
		let characters = Array(self)
		var result = ""

		for (index, character) in characters.enumerated() {
			if
				character.isUppercase,
				index > 0
			{
				let previous = characters[index - 1]
				let next = index + 1 < characters.count ? characters[index + 1] : nil

				// A new word starts after a lowercase letter or a digit, like `heading2-large`, and at the last capital of an acronym, like `url-field`.
				if previous.isLowercase || previous.isNumber || (previous.isUppercase && next?.isLowercase == true) {
					result.append("-")
				}
			}

			result.append(contentsOf: character.lowercased())
		}

		return result
	}
}

extension HTML where Tag: HTMLTrait.Attributes.Global {
	/**
	Applies named styles to the element. They can come from different style sets, like a shared look and a variant:

	```swift
	textarea {}
		.style(FormFieldStyles.control, Styles.message)
	```

	Styles from different style sets in the same layer must not set the same property, as the order of their rules on a page is not defined. To build on the look of another component, combine its style value instead.
	*/
	public func style<each Styles: StyleSet>(_ styles: repeat each Styles) -> _AttributedContent<Self> {
		attributes(.class(classNames(repeat each styles)))
	}

	/**
	Applies named styles to the element when the condition is true.
	*/
	public func style<each Styles: StyleSet>(_ styles: repeat each Styles, when condition: Bool) -> _AttributedContent<Self> {
		guard condition else {
			return attributes(contentsOf: [])
		}

		return style(repeat each styles)
	}
}

/**
The class names of the styles. The page collects the style sets, so it has their rules.
*/
func classNames<each Styles: StyleSet>(_ styles: repeat each Styles) -> String {
	var names = [String]()

	for style in repeat each styles {
		PageResources.current?.use(style)
		names.append(style.className)
	}

	return names.joined(separator: " ")
}
