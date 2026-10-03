import Foundation

/**
A stylesheet written in Swift: the named styles of components, rules for other selectors, media queries, and keyframes.

Nested selectors and conditions are written with native CSS nesting (`&` is the parent selector).

```swift
let stylesheet = Stylesheet {
	FeedCard.Styles.self

	Rule("html", Style().lineHeight(1.5))

	Media(.dark) {
		Rule(".prose a", Style().color(.white))
	}

	Keyframes("fade-in") {
		Rule("from", Style().opacity(0))
	}
}
```
*/
public struct Stylesheet: StyleContent {
	public let nodes: [StyleNode]

	/**
	Keyframes and registered properties that several style sets use are written once.
	*/
	public init(@StyleBuilder _ content: () -> [StyleNode]) {
		self.nodes = content().uniqueDefinitions
	}

	/**
	The rendered CSS.
	*/
	public var css: String {
		var renderer = CSSRenderer()
		renderer.render(nodes)
		return renderer.output
	}
}

/**
A part of a stylesheet, like a ``Rule``.
*/
public protocol StyleContent: Sendable {
	var nodes: [StyleNode] { get }
}

/**
A rule, a conditional group, or keyframes in a stylesheet.
*/
public struct StyleNode: Sendable {
	enum Kind: Sendable {
		case rule(selector: String, declarations: [Declaration], children: [StyleNode])
		case conditional(prelude: String, declarations: [Declaration], children: [StyleNode])
		case keyframes(name: String, frames: [StyleNode])
		case property(name: String, declarations: [Declaration])
		case statement(String)
	}

	let kind: Kind

	static func rule(selector: String, declarations: [Declaration], children: [StyleNode]) -> Self {
		Self(kind: .rule(selector: selector, declarations: declarations, children: children))
	}

	static func conditional(prelude: String, declarations: [Declaration], children: [StyleNode]) -> Self {
		Self(kind: .conditional(prelude: prelude, declarations: declarations, children: children))
	}

	/**
	The name of keyframes or a registered property, which a stylesheet defines once.
	*/
	var definitionName: String? {
		switch kind {
		case .keyframes(let name, _), .property(let name, _):
			name
		case .rule, .conditional, .statement:
			nil
		}
	}
}

extension [StyleNode] {
	/**
	The nodes without repeated keyframes and registered properties, as several styles can use the same animation.
	*/
	var uniqueDefinitions: Self {
		var names = Set<String>()

		return filter { node in
			guard let name = node.definitionName else {
				return true
			}

			return names.insert(name).inserted
		}
	}
}

struct Declaration: Hashable, Sendable {
	let property: Property
	let value: CSSValue
}

/**
A style for a selector, for markup that components do not own, like Markdown output or elements that scripts create. Components use a ``StyleSet`` instead.
*/
public struct Rule: StyleContent {
	public let nodes: [StyleNode]

	public init(_ selector: String, _ style: Style) {
		self.nodes = [style.node(selector: selector)] + style.definitions.uniqueDefinitions
	}
}

/**
Rules that apply when the media query matches, like `@media (prefers-color-scheme: dark)`.
*/
public struct Media: StyleContent {
	public let nodes: [StyleNode]

	public init(_ query: MediaQuery, @StyleBuilder rules: () -> [StyleNode]) {
		self.nodes = [.conditional(prelude: "@media \(query)", declarations: [], children: rules())]
	}
}

/**
Rules that apply when the browser supports a feature, like `@supports (interpolate-size: allow-keywords)`.
*/
public struct Supports: StyleContent {
	public let nodes: [StyleNode]

	public init(_ condition: String, @StyleBuilder rules: () -> [StyleNode]) {
		self.nodes = [.conditional(prelude: "@supports \(condition)", declarations: [], children: rules())]
	}
}

/**
Rules in a cascade layer. Rules in a later layer win over rules in an earlier one, whatever their specificity, so the order of the layers is the order of the cascade.

```swift
Stylesheet {
	Layers("base", "components")

	Layer("base") {
		Rule("a", Style().color(.inherit))
	}
}
```
*/
public struct Layer: StyleContent {
	public let nodes: [StyleNode]

	public init(_ name: String, @StyleBuilder rules: () -> [StyleNode]) {
		self.nodes = [.conditional(prelude: "@layer \(name)", declarations: [], children: rules().uniqueDefinitions)]
	}
}

/**
The order of the cascade layers, from the weakest to the strongest. Put it first in the stylesheet.
*/
public struct Layers: StyleContent {
	public let nodes: [StyleNode]

	public init(_ names: String...) {
		self.nodes = [StyleNode(kind: .statement("@layer \(names.joined(separator: ", "));"))]
	}
}

/**
An animation. Use rules with keyframe selectors (`from`, `to`, `50%`) inside.
*/
public struct Keyframes: StyleContent {
	public let nodes: [StyleNode]

	public init(_ name: String, @StyleBuilder frames: () -> [StyleNode]) {
		self.nodes = [StyleNode(kind: .keyframes(name: name, frames: frames()))]
	}
}

/**
A media query condition. Combine conditions with `&&`.
*/
public struct MediaQuery: Hashable, Sendable, CustomStringConvertible, ExpressibleByStringLiteral {
	public let description: String

	public init(_ condition: String) {
		self.description = condition
	}

	public init(stringLiteral value: String) {
		self.init(value)
	}

	public static let dark: Self = "(prefers-color-scheme: dark)"
	public static let reducedMotion: Self = "(prefers-reduced-motion: reduce)"
	public static let reducedTransparency: Self = "(prefers-reduced-transparency: reduce)"
	public static let moreContrast: Self = "(prefers-contrast: more)"
	public static let forcedColors: Self = "(forced-colors: active)"
	public static let hover: Self = "(hover: hover)"

	/**
	Devices whose main pointer cannot hover, like touch screens.
	*/
	public static let cannotHover: Self = "(hover: none)"

	/**
	A touch screen, where tap targets should be larger.
	*/
	public static let coarsePointer: Self = "(pointer: coarse)"

	/**
	JavaScript is turned off, like `<noscript>` for styles.
	*/
	public static let scriptingDisabled: Self = "(scripting: none)"

	public static func minWidth(_ width: Length) -> Self {
		Self("(min-width: \(width))")
	}

	/**
	Screens narrower than the width, like `(width < 40rem)`. Unlike `max-width`, it does not overlap with `min-width` of the same width.
	*/
	public static func narrowerThan(_ width: Length) -> Self {
		Self("(width < \(width))")
	}

	public static func && (lhs: Self, rhs: Self) -> Self {
		Self("\(lhs) and \(rhs)")
	}
}

@resultBuilder
public enum StyleBuilder {
	public static func buildExpression(_ content: some StyleContent) -> [StyleNode] {
		content.nodes
	}

	public static func buildExpression<Styles: StyleSet>(_ styles: Styles.Type) -> [StyleNode] {
		Styles.nodes
	}

	public static func buildExpression<Animations: KeyframeSet>(_ animations: Animations.Type) -> [StyleNode] {
		Animations.nodes
	}

	public static func buildExpression(_ nodes: [StyleNode]) -> [StyleNode] {
		nodes
	}

	public static func buildBlock(_ components: [StyleNode]...) -> [StyleNode] {
		components.flatMap(\.self)
	}

	public static func buildArray(_ components: [[StyleNode]]) -> [StyleNode] {
		components.flatMap(\.self)
	}

	public static func buildOptional(_ component: [StyleNode]?) -> [StyleNode] {
		component ?? []
	}

	public static func buildEither(first component: [StyleNode]) -> [StyleNode] {
		component
	}

	public static func buildEither(second component: [StyleNode]) -> [StyleNode] {
		component
	}
}

/**
Writes the nodes as CSS with native nesting: nested rules and conditions stay inside their rule.
*/
private struct CSSRenderer {
	private(set) var output = ""
	private var depth = 0

	mutating func render(_ nodes: [StyleNode]) {
		for node in nodes {
			switch node.kind {
			case .rule(let selector, let declarations, let children):
				guard !declarations.isEmpty || !children.isEmpty else {
					continue
				}

				block(selector) { renderer in
					renderer.write(declarations)
					renderer.render(children)
				}
			case .conditional(let prelude, let declarations, let children):
				precondition(depth > 0 || declarations.isEmpty, "Top-level \(prelude) declarations must be inside a rule.")

				block(prelude) { renderer in
					renderer.write(declarations)
					renderer.render(children)
				}
			case .keyframes(let name, let frames):
				block("@keyframes \(name)") { renderer in
					renderer.render(frames)
				}
			case .property(let name, let declarations):
				block("@property \(name)") { renderer in
					renderer.write(declarations)
				}
			case .statement(let statement):
				line(statement)
			}
		}
	}

	private mutating func write(_ declarations: [Declaration]) {
		for declaration in declarations {
			line("\(declaration.property): \(declaration.value);")
		}
	}

	private mutating func block(_ prelude: String, content: (inout Self) -> Void) {
		line("\(prelude) {")
		depth += 1
		content(&self)
		depth -= 1
		line("}")
	}

	private mutating func line(_ string: String) {
		output += String(repeating: "\t", count: depth) + string + "\n"
	}
}
