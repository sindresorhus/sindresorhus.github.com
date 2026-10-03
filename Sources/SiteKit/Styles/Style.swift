import Foundation

/**
The declarations for an element, written as a chain of modifiers, like SwiftUI view modifiers.

Each modifier returns a new style. For the same property, a later modifier wins over an earlier one. Conditions like ``hover(_:)``, ``dark(_:)``, and ``breakpoint(_:_:)`` take a closure that gets an empty style, so they nest. The declarations of the style itself are written before its conditions, so a condition wins over a base declaration wherever it is in the chain:

```swift
let card = Style()
	.padding(.rem(1))
	.cornerRadius(.rem(0.5))
	.background(.white)
	.hover {
		$0.background(.gray100)
	}
	.dark {
		$0
			.background(.slate900)
			.hover {
				$0.background(.slate800)
			}
	}
```

Use ``declaration(_:_:)`` for properties without a modifier.
*/
public struct Style: Sendable {
	var declarations = [Declaration]()
	var children = [StyleNode]()

	/**
	The selector of the elements that end the scope of the nested rules. See ``scope(excluding:)``.
	*/
	var scopeLimit: String?

	/**
	The keyframes and the registered custom properties that the style and its conditions use, so a stylesheet with the style also has them. They are written at the top level of the stylesheet.
	*/
	var definitions = [StyleNode]()

	public init() {}

	/**
	Sets a property. Use it for properties without a modifier.
	*/
	public func declaration(_ property: Property, _ value: CSSValue) -> Self {
		var copy = self
		copy.declarations.append(Declaration(property: property, value: value))
		return copy
	}

	/**
	Limits the style and its nested rules to the elements outside the descendants that match the selector, like `@scope (…) to (…)` in CSS. Use it for styles of markup that components do not own, like typography for Markdown, so components inside can opt out.
	*/
	public func scope(excluding selector: String) -> Self {
		var copy = self
		copy.scopeLimit = selector
		return copy
	}

	/**
	The rule of the style for the selector. A scoped style is wrapped in `@scope`, with `:scope` as the selector.
	*/
	func node(selector: String) -> StyleNode {
		guard
			let scopeLimit,
			!declarations.isEmpty || !children.isEmpty
		else {
			return .rule(selector: selector, declarations: declarations, children: children)
		}

		return .conditional(prelude: "@scope (\(selector)) to (\(scopeLimit))", declarations: [], children: [.rule(selector: ":scope", declarations: declarations, children: children)])
	}

	/**
	The style with the declarations and conditions of another style added, like a custom view modifier that is a value.
	*/
	public func combined(with other: Self) -> Self {
		var copy = self
		copy.declarations += other.declarations
		copy.children += other.children
		copy.definitions += other.definitions
		return copy
	}

	/**
	Styles for a nested selector, like CSS nesting: `&` is this element (`"&:first-child"`, `"& > li"`), and a selector without `&` matches descendants (`".icon"`).
	*/
	public func nested(_ selector: String, _ content: (Self) -> Self) -> Self {
		let style = content(Self())
		var copy = self
		copy.children.append(.rule(selector: selector, declarations: style.declarations, children: style.children))
		copy.definitions += style.definitions
		return copy
	}

	/**
	Styles that apply when the media query matches.
	*/
	public func media(_ query: MediaQuery, _ content: (Self) -> Self) -> Self {
		conditional("@media \(query)", content)
	}

	/**
	Styles that apply when the browser supports a feature, like `(interpolate-size: allow-keywords)`.
	*/
	public func supports(_ condition: String, _ content: (Self) -> Self) -> Self {
		conditional("@supports \(condition)", content)
	}

	/**
	The styles an element transitions from when it appears, like when it stops being hidden.
	*/
	public func startingStyle(_ content: (Self) -> Self) -> Self {
		conditional("@starting-style", content)
	}

	/**
	Marks the declarations in the closure `!important`. Only plain declarations can be important, not conditions or animations.
	*/
	public func important(_ content: (Self) -> Self) -> Self {
		let style = content(Self())
		precondition(style.children.isEmpty && style.definitions.isEmpty, "Only plain declarations can be important.")

		var copy = self
		copy.declarations += style.declarations.map { Declaration(property: $0.property, value: .important($0.value)) }
		return copy
	}

	private func conditional(_ prelude: String, _ content: (Self) -> Self) -> Self {
		let style = content(Self())
		var copy = self
		copy.children.append(.conditional(prelude: prelude, declarations: style.declarations, children: style.children))
		copy.definitions += style.definitions
		return copy
	}
}

// MARK: Conditions

extension Style {
	/**
	Styles while the pointer is over the element. They only apply on devices that can hover, so hover effects do not stick after a tap on a touch screen.
	*/
	public func hover(_ content: (Self) -> Self) -> Self {
		media(.hover) {
			$0.nested("&:hover", content)
		}
	}

	public func focusVisible(_ content: (Self) -> Self) -> Self {
		nested("&:focus-visible", content)
	}

	/**
	Styles while the element or an element inside it has focus.
	*/
	public func focusWithin(_ content: (Self) -> Self) -> Self {
		nested("&:focus-within", content)
	}

	/**
	Styles while the element is the target of the URL fragment, like after following a link to `#refund`.
	*/
	public func target(_ content: (Self) -> Self) -> Self {
		nested("&:target", content)
	}

	public func active(_ content: (Self) -> Self) -> Self {
		nested("&:active", content)
	}

	public func disabled(_ content: (Self) -> Self) -> Self {
		nested("&:disabled", content)
	}

	public func placeholder(_ content: (Self) -> Self) -> Self {
		nested("&::placeholder", content)
	}

	/**
	The `::before` pseudo-element. Set ``content(_:)`` to show it.
	*/
	public func before(_ content: (Self) -> Self) -> Self {
		nested("&::before", content)
	}

	/**
	The `::after` pseudo-element. Set ``content(_:)`` to show it.
	*/
	public func after(_ content: (Self) -> Self) -> Self {
		nested("&::after", content)
	}

	public func dark(_ content: (Self) -> Self) -> Self {
		media(.dark, content)
	}

	public func reducedMotion(_ content: (Self) -> Self) -> Self {
		media(.reducedMotion, content)
	}

	/**
	Styles for visitors who turn off transparency in the system settings, like solid backgrounds instead of frosted glass.
	*/
	public func reducedTransparency(_ content: (Self) -> Self) -> Self {
		media(.reducedTransparency, content)
	}

	/**
	Styles for screens at least as wide as the breakpoint.
	*/
	public func breakpoint(_ breakpoint: Breakpoint, _ content: (Self) -> Self) -> Self {
		media(.minWidth(breakpoint.minimumWidth), content)
	}

	/**
	Styles for screens narrower than the breakpoint.
	*/
	public func below(_ breakpoint: Breakpoint, _ content: (Self) -> Self) -> Self {
		media(.narrowerThan(breakpoint.minimumWidth), content)
	}

	/**
	Styles for the direct children that match the selector, like `children("li")` for `& > li`.
	*/
	public func children(_ selector: String, _ content: (Self) -> Self) -> Self {
		nested("& > \(selector)", content)
	}
}
