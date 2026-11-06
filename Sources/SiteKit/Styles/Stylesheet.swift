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

	Keyframes("fade-in", .from(Style().opacity(0)))
}
```
*/
public struct Stylesheet: StyleContent {
	public let nodes: [StyleNode]

	/**
	The style sets in the stylesheet, also the ones in layers and conditions, so pages that link to the stylesheet do not repeat them.
	*/
	let styleSets: [any StyleSet.Type]

	/**
	Keyframes and registered properties that several style sets use are written once.

	With more than one top-level ``Layer``, the stylesheet starts with the order of the layers, which is the order of their first blocks. A `Layer` inside another one is a sublayer, and layers in conditions are not in the order.
	*/
	public init(@StyleBuilder _ content: () -> [StyleNode]) {
		let nodes = content().uniqueDefinitions
		var layerNames = [CascadeLayer]()

		for node in nodes {
			if
				case .layer(let name, _) = node.kind,
				!layerNames.contains(name)
			{
				layerNames.append(name)
			}
		}

		self.nodes = layerNames.count > 1 ? [StyleNode(kind: .layerOrder(layerNames))] + nodes : nodes
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
A part of a stylesheet: a rule, a conditional group, a layer, keyframes, a registered property, the order of the layers, or a record of a style set.
*/
public struct StyleNode: Sendable {
	/**
	The supported block forms retain their meaning until rendering; CSS text is never inspected to decide whether a block is a selector or a conditional group.
	*/
	enum Prelude: Hashable, CustomStringConvertible {
		case selector(CSSSelector)
		case media(MediaQuery)
		case supports(BrowserFeature)
		case scope(CSSSelector, until: CSSSelector?)
		case startingStyle

		var isSelector: Bool {
			if case .selector = self {
				return true
			}

			return false
		}

		var description: String {
			switch self {
			case .selector(let selector):
				selector.description
			case .media(let query):
				"@media \(query)"
			case .supports(let feature):
				"@supports \(feature)"
			case .scope(let selector, let limit):
				"@scope (\(selector))" + (limit.map { " to (\($0))" } ?? "")
			case .startingStyle:
				"@starting-style"
			}
		}
	}

	enum Kind {
		/**
		A rule, like `.a { … }`, or a conditional group, like `@media (…) { … }`, with its declarations and nested nodes. The prelude is the selector of a rule. A conditional group only has declarations when it is nested in a rule.
		*/
		case block(prelude: Prelude, declarations: [Declaration], children: [StyleNode])
		case layer(name: CascadeLayer, children: [StyleNode])
		case keyframes(name: String, frames: [StyleNode])
		case property(name: String, declarations: [Declaration])

		/**
		The order of the cascade layers, like `@layer base, components;`.
		*/
		case layerOrder([CascadeLayer])

		/**
		A record that the style set is in the stylesheet. It renders nothing, as the rules of the style set are the nodes after it.
		*/
		case styleSet(any StyleSet.Type)
	}

	let kind: Kind

	static func block(_ prelude: Prelude, declarations: [Declaration] = [], children: [StyleNode]) -> Self {
		Self(kind: .block(prelude: prelude, declarations: declarations, children: children))
	}

	/**
	The name of keyframes or a registered property, which a stylesheet defines once.
	*/
	enum Definition: Hashable {
		case keyframes(String)
		case property(String)
	}

	var definition: Definition? {
		switch kind {
		case .keyframes(let name, _):
			.keyframes(name)
		case .property(let name, _):
			.property(name)
		case .block, .layer, .layerOrder, .styleSet:
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
			case .block(_, _, let children), .layer(_, let children):
				children.styleSets
			case .keyframes, .property, .layerOrder:
				[]
			}
		}
	}
}

extension [StyleNode] {
	/**
	The nodes without repeated keyframes and registered properties, as several styles can use the same animation.

	Limitation: The first definition of a name is kept without comparing the others, so two different keyframes with the same generated name, like of `Foo.Animations` and of a top-level `FooAnimations`, end up as one. Unlike the class names of style sets, the names are not checked for duplicates, as it has not happened.
	*/
	fileprivate var uniqueDefinitions: Self {
		var names = Set<StyleNode.Definition>()
		return removingDuplicateDefinitions(names: &names)
	}

	/**
	The nodes without the definitions that have a name in `names`, also in layers, so a definition in two layers is written once. In a condition, like `@media`, a definition is removed when the condition or the nodes around it already have it.
	*/
	private func removingDuplicateDefinitions(names: inout Set<StyleNode.Definition>) -> Self {
		compactMap { node in
			switch node.kind {
			case .layer(let name, let children):
				return StyleNode(kind: .layer(name: name, children: children.removingDuplicateDefinitions(names: &names)))
			case .block(let prelude, let declarations, let children):
				// A definition in a condition, like `@media`, only applies when the condition matches, so it does not count for the nodes after the block.
				var blockNames = names
				return .block(prelude, declarations: declarations, children: children.removingDuplicateDefinitions(names: &blockNames))
			case .keyframes, .property, .layerOrder, .styleSet:
				guard let name = node.definition else {
					return node
				}

				return names.insert(name).inserted ? node : nil
			}
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
		case (.block(let prelude, let declarations, let children), .block(let nextPrelude, let nextDeclarations, let nextChildren)):
			guard
				prelude == nextPrelude,
				children.isEmpty || nextDeclarations.isEmpty
			else {
				return nil
			}

			var mergedChildren = children
			mergedChildren.append(merging: nextChildren)
			return .block(prelude, declarations: declarations + nextDeclarations, children: mergedChildren)
		default:
			return nil
		}
	}
}

struct Declaration: Hashable {
	let property: Property
	let value: CSSValue

	/**
	Whether the declaration overrides normal declarations (`!important` in CSS).
	*/
	let isImportant: Bool

	init(property: Property, value: CSSValue, isImportant: Bool = false) {
		self.property = property
		self.value = value
		self.isImportant = isImportant
	}
}

/**
A style for a selector, for markup that components do not own, like Markdown output or elements that scripts create. Components use a ``StyleSet`` instead.
*/
public struct Rule: StyleContent {
	public let nodes: [StyleNode]

	public init(_ selector: CSSSelector, _ style: Style) {
		self.nodes = style.nodes(selector: selector)
	}
}

/**
A selector, like `.feed-card-title` or `& > li`. Write it as a literal, and put other selectors in it with interpolation, like `"\(Styles.root.selector):hover &"`. Only selectors can be interpolated, so a class name without its dot, or other text, does not compile. Interpolate other text with `raw:`, like `"&:state(\(raw: name))"`.
*/
public struct CSSSelector: Hashable, Sendable, CustomStringConvertible, ExpressibleByStringInterpolation {
	public let description: String

	private init(raw selector: String) {
		self.description = selector
	}

	/**
	An attribute selector with an optional quoted value. Names start with an ASCII letter or underscore and contain only ASCII letters, digits, underscores, and hyphens; values use CSS string escaping.
	*/
	public static func attribute(_ name: String, value: String? = nil) -> Self {
		let hasValidStart = name.utf8.first.map { $0.isASCIILetter || $0 == 95 } ?? false
		let hasValidRest = name.utf8.allSatisfy { $0.isASCIILetter || $0.isASCIIDigit || $0 == 95 || $0 == 45 }
		precondition(hasValidStart && hasValidRest, "A CSS attribute name must start with an ASCII letter or underscore and contain only ASCII letters, digits, underscores, and hyphens, got: \(name)")
		return Self(raw: "[\(name)\(value.map { "=\(CSSValue.string($0))" } ?? "")]")
	}

	/**
	The class selector of the class name, like `.feed-card` for `feed-card`.
	*/
	init(className: String) {
		self.init(raw: ".\(className)")
	}

	public init(stringLiteral value: String) {
		self.init(raw: value)
	}

	/**
	The selector, in `:is()` when it is a list, so a combinator applies to each selector of the list, like `:is(td, th) &`, not `td, th &`.
	*/
	var groupedForCombinator: Self {
		description.contains(",") ? ":is(\(self))" : self
	}

	public init(stringInterpolation: StringInterpolation) {
		self.init(raw: stringInterpolation.selector)
	}

	public struct StringInterpolation: StringInterpolationProtocol {
		fileprivate var selector = ""

		public init(literalCapacity: Int, interpolationCount: Int) {
			selector.reserveCapacity(literalCapacity)
		}

		public mutating func appendLiteral(_ literal: String) {
			selector += literal
		}

		public mutating func appendInterpolation(_ selector: CSSSelector) {
			self.selector += selector.description
		}

		/**
		Text that is part of a selector, like the name of a state in `"&:state(\(raw: name))"`. It stands out in a review, like ``Property/init(_:)``.
		*/
		public mutating func appendInterpolation(raw text: String) {
			selector += text
		}
	}
}

/**
Rules that apply when the media query matches, like `@media (prefers-color-scheme: dark)`.
*/
public struct Media: StyleContent {
	public let nodes: [StyleNode]

	public init(_ query: MediaQuery, @StyleBuilder rules: () -> [StyleNode]) {
		self.nodes = [.block(.media(query), children: rules())]
	}

	/**
	Rules that apply when the media condition matches.
	*/
	public init(_ condition: MediaCondition, @StyleBuilder rules: () -> [StyleNode]) {
		self.init(MediaQuery(condition), rules: rules)
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
		Rule("a", Style().inherits(.color))
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
		self.nodes = [StyleNode(kind: .layer(name: layer, children: rules()))]
	}
}

/**
The name of a cascade layer. Define each layer once as a static member, so a typo cannot make a new layer that wins over the others. Names support unescaped CSS identifiers and dot-separated sublayers; CSS escape sequences are unsupported.
*/
public struct CascadeLayer: Hashable, Sendable {
	public let name: String

	public init(_ name: String) {
		do {
			try self.init(validating: name)
		} catch {
			preconditionFailure(error.reason)
		}
	}

	/**
	Checks a dynamic layer name. Each dot-separated component must be an unescaped CSS identifier other than a CSS-wide keyword.
	*/
	public init(validating name: String) throws(ContentError) {
		guard
			!name.isEmpty,
			name.split(separator: ".", omittingEmptySubsequences: false).allSatisfy({ String($0).isCSSIdentifier })
		else {
			throw ContentError(reason: "A cascade layer needs a CSS identifier other than a CSS-wide keyword for each dot-separated name component, got “\(name)”.")
		}

		self.name = name
	}
}

/**
An animation with typed keyframes (`from`, `to`, or a percentage).
*/
public struct Keyframes: StyleContent {
	public let nodes: [StyleNode]

	/**
	Creates a named animation from its keyframes.
	*/
	public init(_ name: String, _ frames: Keyframe...) {
		self.init(name, frames)
	}

	/**
	Creates a named animation from a list of keyframes, including the registered properties the frames use. The name must be an unescaped CSS custom identifier other than `none`; quoted names and CSS escape sequences are unsupported.
	*/
	public init(_ name: String, _ frames: [Keyframe]) {
		do {
			try self.init(validating: name, frames)
		} catch {
			preconditionFailure(error.reason)
		}
	}

	/**
	Checks a dynamic animation name, then creates its keyframes. The supported spelling is an unescaped CSS custom identifier other than `none`.
	*/
	public init(validating name: String, _ frames: Keyframe...) throws(ContentError) {
		try self.init(validating: name, frames)
	}

	/**
	Checks a dynamic animation name, then creates its list of keyframes, including the registered properties the frames use.
	*/
	public init(validating name: String, _ frames: [Keyframe]) throws(ContentError) {
		guard
			name.isCSSIdentifier,
			!["none", "default"].contains(name.lowercased())
		else {
			throw ContentError(reason: "Keyframes need a CSS identifier other than a CSS-wide keyword, none, or default, got “\(name)”.")
		}

		self.nodes = [StyleNode(kind: .keyframes(name: name, frames: frames.map(\.node)))] + frames.flatMap(\.definitions)
	}
}

private extension String {
	/**
	Whether the string is an unescaped CSS identifier other than a CSS-wide keyword. Non-ASCII characters follow the CSS identifier grammar; other reserved words are checked by the owning API.
	*/
	var isCSSIdentifier: Bool {
		let bytes = utf8
		guard
			let first = bytes.first,
			first.isCSSNameStart || (first == 45 && bytes.dropFirst().first.map { $0.isCSSNameStart || $0 == 45 } == true),
			bytes.allSatisfy({ $0.isCSSNameStart || $0.isASCIIDigit || $0 == 45 })
		else {
			return false
		}

		return !["initial", "inherit", "unset", "revert", "revert-layer", "revert-rule"].contains(lowercased())
	}
}

private extension UInt8 {
	/**
	A byte that can begin an unescaped CSS name: an ASCII letter, underscore, or part of a non-ASCII character in a valid Swift string.
	*/
	var isCSSNameStart: Bool {
		isASCIILetter || self == 95 || self >= 128
	}
}

/**
A media feature or a Boolean combination of features. Combine conditions with `&&`, `||`, and `!`; complete queries such as print and opaque raw queries remain a separate type.
*/
public struct MediaCondition: Hashable, Sendable, CustomStringConvertible {
	private indirect enum Condition: Hashable, Sendable {
		case feature(String)
		case and(Self, Self)
		case or(Self, Self)
		case not(Self)

		var description: String {
			switch self {
			case .feature(let text):
				text
			case .and(let first, let second):
				"\(first.operand(forConjunction: true)) and \(second.operand(forConjunction: true))"
			case .or(let first, let second):
				"\(first.operand(forConjunction: false)) or \(second.operand(forConjunction: false))"
			case .not(let condition):
				"not \(condition.grouped)"
			}
		}

		private var grouped: String {
			if case .feature = self {
				return description
			}

			return "(\(description))"
		}

		/**
		Groups a nested condition unless it uses the same connective as its parent.
		*/
		func operand(forConjunction isConjunction: Bool) -> String {
			switch self {
			case .and where isConjunction:
				description
			case .or where !isConjunction:
				description
			default:
				grouped
			}
		}
	}

	private let condition: Condition

	private init(_ condition: Condition) {
		self.condition = condition
	}

	/**
	A trusted media feature, including its parentheses.
	*/
	private init(condition: String) {
		self.init(.feature(condition))
	}

	public var description: String {
		condition.description
	}

	/**
	A condition following the `and` of a media type must group a disjunction.
	*/
	fileprivate var mediaTypeOperand: String {
		condition.operand(forConjunction: true)
	}

	public static let light = Self(condition: "(prefers-color-scheme: light)")
	public static let dark = Self(condition: "(prefers-color-scheme: dark)")
	public static let reducedMotion = Self(condition: "(prefers-reduced-motion: reduce)")

	/**
	The visitor has not asked for reduced motion, for motion that is not needed, like smooth scrolling.
	*/
	public static let allowsMotion = Self(condition: "(prefers-reduced-motion: no-preference)")
	public static let reducedTransparency = Self(condition: "(prefers-reduced-transparency: reduce)")

	public static let moreContrast = Self(condition: "(prefers-contrast: more)")
	public static let forcedColors = Self(condition: "(forced-colors: active)")
	public static let hover = Self(condition: "(hover: hover)")

	/**
	Devices whose main pointer cannot hover, like touch screens.
	*/
	public static let cannotHover = Self(condition: "(hover: none)")

	/**
	A touch screen, where tap targets should be larger.
	*/
	public static let coarsePointer = Self(condition: "(pointer: coarse)")

	/**
	A precise pointer, like a mouse or a trackpad, for effects that follow the pointer.
	*/
	public static let finePointer = Self(condition: "(pointer: fine)")

	/**
	JavaScript is turned off, like `<noscript>` for styles.
	*/
	public static let scriptingDisabled = Self(condition: "(scripting: none)")

	/**
	A short screen, like a phone in landscape, or with the text at 200%, where a sticky bar would cover much of the page.
	*/
	public static let shortScreen = Self(condition: "(height < 30rem)")

	/**
	Screens at least as wide as the breakpoint, like `(width >= 40rem)`.
	*/
	public static func from(_ breakpoint: Breakpoint) -> Self {
		Self(condition: "(width >= \(breakpoint.minimumWidth))")
	}

	/**
	Screens narrower than the breakpoint, like `(width < 40rem)`. It does not overlap with ``from(_:)`` of the same breakpoint.
	*/
	public static func below(_ breakpoint: Breakpoint) -> Self {
		Self(condition: "(width < \(breakpoint.minimumWidth))")
	}

	/**
	Both conditions, preserving grouping when conjunction and disjunction mix.
	*/
	public static func && (lhs: Self, rhs: Self) -> Self {
		Self(.and(lhs.condition, rhs.condition))
	}

	/**
	Either condition, preserving grouping when conjunction and disjunction mix.
	*/
	public static func || (lhs: Self, rhs: Self) -> Self {
		Self(.or(lhs.condition, rhs.condition))
	}

	/**
	The negation of a condition, with grouping preserved.
	*/
	public static prefix func ! (condition: Self) -> Self {
		Self(.not(condition.condition))
	}
}

/**
A complete media query. Conditions have their own Boolean operations; raw whole queries are opaque and rendered unchanged.
*/
public struct MediaQuery: Hashable, Sendable, CustomStringConvertible {
	public let description: String

	/**
	A complete query that tests a media condition.
	*/
	public init(_ condition: MediaCondition) {
		self.description = condition.description
	}

	/**
	An arbitrary complete media query, rendered unchanged. Raw queries are not parsed or composed.
	*/
	public init(raw query: String) {
		self.description = query
	}

	/**
	The page is printed, or saved as a PDF.
	*/
	public static let print = Self(raw: "print")

	/**
	The page is printed and the condition matches, like `.print(matching: .dark || .moreContrast)`.
	*/
	public static func print(matching condition: MediaCondition) -> Self {
		Self(raw: "print and \(condition.mediaTypeOperand)")
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
			case .block(let prelude, let declarations, let children):
				// An empty rule or condition, like `.dark { $0 }`, would be an empty block.
				guard !declarations.isEmpty || !children.isEmpty else {
					continue
				}

				precondition(depth > 0 || declarations.isEmpty || prelude.isSelector, "Top-level \(prelude) declarations must be inside a rule.")

				block(prelude.description) { renderer in
					renderer.write(declarations)
					renderer.render(children)
				}
			case .layer(let name, let children):
				block("@layer \(name.name)") { renderer in
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
			case .layerOrder(let names):
				line("@layer \(names.map(\.name).joined(separator: ", "));")
			case .styleSet:
				continue
			}
		}
	}

	private mutating func write(_ declarations: [Declaration]) {
		for declaration in declarations {
			let importance = declaration.isImportant ? " !important" : ""
			line("\(declaration.property): \(declaration.value)\(importance);")
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
