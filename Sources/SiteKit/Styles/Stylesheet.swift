import Foundation

/**
A stylesheet written in Swift: the named styles of components, rules for other selectors, media queries, and keyframes.

Nested selectors and conditions are written with native CSS nesting (`&` is the parent selector).

```swift
let stylesheet = Stylesheet {
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
	The style sets in the stylesheet, also the ones in layers and conditions, so pages that link to the stylesheet do not repeat them.
	*/
	public let styleSets: [any StyleSet.Type]

	/**
	Keyframes and registered properties that several style sets use are written once.

	With more than one top-level ``Layer``, the stylesheet starts with the order of the layers, which is the order of their first blocks. A `Layer` inside another one is a sublayer, and layers in conditions are not in the order.
	*/
	public init(@StyleBuilder _ content: () -> [StyleNode]) {
		let nodes = content().uniqueDefinitions
		var layerNames = [String]()

		for node in nodes {
			if
				case .layer(let name, _) = node.kind,
				!layerNames.contains(name)
			{
				layerNames.append(name)
			}
		}

		self.nodes = layerNames.count > 1 ? [StyleNode(kind: .statement("@layer \(layerNames.joined(separator: ", "));"))] + nodes : nodes
		self.styleSets = nodes.styleSets
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
A part of a stylesheet: a rule, a conditional group, a layer, keyframes, a registered property, a statement, or a record of a style set.
*/
public struct StyleNode: Sendable {
	enum Kind {
		case rule(selector: String, declarations: [Declaration], children: [StyleNode])
		case conditional(prelude: String, declarations: [Declaration], children: [StyleNode])
		case layer(name: String, children: [StyleNode])
		case keyframes(name: String, frames: [StyleNode])
		case property(name: String, declarations: [Declaration])
		case statement(String)

		/**
		A record that the style set is in the stylesheet. It renders nothing, as the rules of the style set are the nodes after it.
		*/
		case styleSet(any StyleSet.Type)
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
		case .rule, .conditional, .layer, .statement, .styleSet:
			nil
		}
	}
}

extension [StyleNode] {
	/**
	The style sets that the nodes record, also in nested nodes.
	*/
	fileprivate var styleSets: [any StyleSet.Type] {
		flatMap { node -> [any StyleSet.Type] in
			switch node.kind {
			case .styleSet(let styles):
				[styles]
			case .rule(_, _, let children), .conditional(_, _, let children), .layer(_, let children):
				children.styleSets
			case .keyframes, .property, .statement:
				[]
			}
		}
	}
}

extension [StyleNode] {
	/**
	The nodes without repeated keyframes and registered properties, as several styles can use the same animation.
	*/
	var uniqueDefinitions: Self {
		var names = Set<String>()
		return removingDuplicateDefinitions(names: &names)
	}

	/**
	The nodes without the definitions that have a name in `names`, also in layers, so a definition in two layers is written once.
	*/
	private func removingDuplicateDefinitions(names: inout Set<String>) -> Self {
		compactMap { node in
			if case .layer(let name, let children) = node.kind {
				return StyleNode(kind: .layer(name: name, children: children.removingDuplicateDefinitions(names: &names)))
			}

			guard let name = node.definitionName else {
				return node
			}

			return names.insert(name).inserted ? node : nil
		}
	}
}

extension [StyleNode] {
	/**
	Appends the nodes, and merges a node into the last one when both are rules with the same selector or conditions with the same prelude, like two `.dark { … }` in a row. They merge only when the order of the declarations stays the same, so the output is shorter and means the same.
	*/
	mutating func append(merging nodes: Self) {
		for node in nodes {
			guard
				let last,
				let merged = last.merged(with: node)
			else {
				append(node)
				continue
			}

			self[endIndex - 1] = merged
		}
	}
}

extension StyleNode {
	/**
	This node and a node that follows it as one node, or `nil` when they cannot merge.

	The declarations of a node come before its nested rules, so the declarations of the next node can only join when this node has no nested rules. Otherwise, a nested rule of this node would move after them, and win over them.
	*/
	fileprivate func merged(with next: Self) -> Self? {
		switch (kind, next.kind) {
		case (.rule(let selector, let declarations, let children), .rule(let nextSelector, let nextDeclarations, let nextChildren)):
			guard
				selector == nextSelector,
				children.isEmpty || nextDeclarations.isEmpty
			else {
				return nil
			}

			var mergedChildren = children
			mergedChildren.append(merging: nextChildren)
			return .rule(selector: selector, declarations: declarations + nextDeclarations, children: mergedChildren)
		case (.conditional(let prelude, let declarations, let children), .conditional(let nextPrelude, let nextDeclarations, let nextChildren)):
			guard
				prelude == nextPrelude,
				children.isEmpty || nextDeclarations.isEmpty
			else {
				return nil
			}

			var mergedChildren = children
			mergedChildren.append(merging: nextChildren)
			return .conditional(prelude: prelude, declarations: declarations + nextDeclarations, children: mergedChildren)
		default:
			return nil
		}
	}
}

struct Declaration: Hashable {
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
Rules in a cascade layer. Rules in a later layer win over rules in an earlier one, whatever their specificity. The ``Stylesheet`` writes the order of its layers, so the order of the blocks is the order of the cascade. The first stylesheet of the page that names the layers sets their order, so a stylesheet with one layer, like the styles of a page, must come after the stylesheet with all the layers.

```swift
extension CascadeLayer {
	static let base = Self("base")
	static let components = Self("components")
}

Stylesheet {
	Layer(.base) {
		Rule("a", Style().color(.inherit))
	}

	Layer(.components) {
		Card.Styles.self
	}
}
```
*/
public struct Layer: StyleContent {
	public let nodes: [StyleNode]

	public init(_ layer: CascadeLayer, @StyleBuilder rules: () -> [StyleNode]) {
		self.nodes = [StyleNode(kind: .layer(name: layer.name, children: rules().uniqueDefinitions))]
	}
}

/**
The name of a cascade layer. Define each layer once as a static member, so a typo cannot make a new layer that wins over the others.
*/
public struct CascadeLayer: Hashable, Sendable {
	public let name: String

	public init(_ name: String) {
		self.name = name
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

	public static let light: Self = "(prefers-color-scheme: light)"
	public static let dark: Self = "(prefers-color-scheme: dark)"
	public static let reducedMotion: Self = "(prefers-reduced-motion: reduce)"

	/**
	The visitor has not asked for reduced motion, for motion that is not needed, like smooth scrolling.
	*/
	public static let allowsMotion: Self = "(prefers-reduced-motion: no-preference)"
	public static let reducedTransparency: Self = "(prefers-reduced-transparency: reduce)"

	/**
	The page is printed, or saved as a PDF.
	*/
	public static let print: Self = "print"
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
	A precise pointer, like a mouse or a trackpad, for effects that follow the pointer.
	*/
	public static let finePointer: Self = "(pointer: fine)"

	/**
	JavaScript is turned off, like `<noscript>` for styles.
	*/
	public static let scriptingDisabled: Self = "(scripting: none)"

	/**
	Screens at least as wide as the breakpoint, like `(width >= 40rem)`.
	*/
	public static func from(_ breakpoint: Breakpoint) -> Self {
		Self("(width >= \(breakpoint.minimumWidth))")
	}

	/**
	Screens narrower than the breakpoint, like `(width < 40rem)`. It does not overlap with ``from(_:)`` of the same breakpoint.
	*/
	public static func below(_ breakpoint: Breakpoint) -> Self {
		Self("(width < \(breakpoint.minimumWidth))")
	}

	/**
	Both queries. A query with `not` or `or` is in parentheses, as Media Queries 4 does not allow them next to `and` without them.
	*/
	public static func && (lhs: Self, rhs: Self) -> Self {
		func operand(_ query: Self) -> String {
			let text = query.description
			return text.hasPrefix("not ") || text.contains(" or ") ? "(\(text))" : text
		}

		return Self("\(operand(lhs)) and \(operand(rhs))")
	}
}

@resultBuilder
public enum StyleBuilder {
	public static func buildExpression(_ content: some StyleContent) -> [StyleNode] {
		content.nodes
	}

	public static func buildExpression<Styles: StyleSet>(_ styles: Styles.Type) -> [StyleNode] {
		[StyleNode(kind: .styleSet(styles))] + Styles.nodes
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
			case .layer(let name, let children):
				block("@layer \(name)") { renderer in
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
			case .styleSet:
				continue
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
