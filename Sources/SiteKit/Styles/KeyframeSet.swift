/**
The animations of a component. Each case is an animation, and its name is generated from the component and the case, so names cannot clash.

Nest it in the component as `Animations`, and run one with ``Style/animation(_:_:fillMode:isEssential:)``. A style that runs an animation brings its keyframes, so no stylesheet has to list them:

```swift
enum Animations: String, KeyframeSet {
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
public protocol KeyframeSet: RawRepresentable<String>, CaseIterable, Sendable {
	var keyframes: [Keyframe] { get }
}

extension KeyframeSet {
	/**
	The animation name, like `spinner-spin`.
	*/
	public var name: String {
		generatedComponentName(of: Self.self, suffix: "Animations", member: rawValue)
	}

	static var nodes: [StyleNode] {
		allCases.flatMap(\.nodes)
	}

	/**
	The keyframes and the registered properties they animate, built from the same frames.
	*/
	var nodes: [StyleNode] {
		Keyframes(name, keyframes).nodes
	}
}

/**
The styles at a point of an animation.
*/
public struct Keyframe: Sendable {
	let node: StyleNode
	let definitions: [StyleNode]

	private init(selector: String, style: Style) {
		precondition(style.children.isEmpty, "A keyframe only accepts declarations, not nested selectors or conditions.")
		self.node = .block(.selector("\(raw: selector)"), declarations: style.declarations, children: [])
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
		precondition(percentage.isFinite && (0...100).contains(percentage), "A keyframe offset must be finite and between 0 and 100 percent.")
		return Self(selector: CSSValue.percent(percentage).description, style: style)
	}
}
