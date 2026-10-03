/**
The animations of a component. Each case is an animation, and its name is generated from the component and the case, so names cannot clash.

Nest it in the component as `Animations`, run one with ``Style/animation(_:duration:curve:delay:repeats:autoreverses:fillMode:)``, and add the component's animations to the stylesheet with `Stylesheet { MyComponent.Animations.self }`:

```swift
enum Animations: KeyframeSet {
	case spin

	var keyframes: [Keyframe] {
		switch self {
		case .spin:
			[.to(Style().rotationEffect(.degrees(360)))]
		}
	}
}
```

The name of `spin` in `Spinner.Animations` is `spinner-spin`.
*/
public protocol KeyframeSet: CaseIterable, Sendable {
	var keyframes: [Keyframe] { get }
}

extension KeyframeSet {
	/**
	The animation name, like `spinner-spin`.
	*/
	public var name: String {
		"\(generatedComponentName(of: Self.self, suffix: "Animations"))-\(String(describing: self).kebabCased)"
	}

	static var nodes: [StyleNode] {
		allCases.flatMap { [$0.node] + $0.definitions }.uniqueDefinitions
	}

	var node: StyleNode {
		StyleNode(kind: .keyframes(name: name, frames: keyframes.map(\.node)))
	}

	/**
	The registered properties that the keyframes animate.
	*/
	var definitions: [StyleNode] {
		keyframes.flatMap(\.definitions)
	}
}

/**
The styles at a point of an animation.
*/
public struct Keyframe: Sendable {
	let node: StyleNode
	let definitions: [StyleNode]

	private init(selector: String, style: Style) {
		self.node = .rule(selector: selector, declarations: style.declarations, children: style.children)
		self.definitions = style.definitions
	}

	public static func from(_ style: Style) -> Self {
		Self(selector: "from", style: style)
	}

	public static func to(_ style: Style) -> Self {
		Self(selector: "to", style: style)
	}

	/**
	The styles at a percentage of the animation, like `at(50, …)` for the middle.
	*/
	public static func at(_ percentage: Double, _ style: Style) -> Self {
		Self(selector: CSSValue.percent(percentage).description, style: style)
	}
}
