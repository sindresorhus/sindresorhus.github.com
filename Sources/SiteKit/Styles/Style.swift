import Foundation

/**
The declarations for an element, written as a chain of modifiers, like SwiftUI view modifiers.

Each modifier returns a new style. For the same property, a later modifier wins over an earlier one. Conditions like ``hover(_:)``, ``dark(_:)``, and ``from(_:_:)`` take a closure that gets an empty style, so they nest. The declarations of the style itself are written before its conditions, so a condition wins over a base declaration wherever it is in the chain:

```swift
let card = Style()
	.padding(.rootEm(1))
	.cornerRadius(.rootEm(0.5))
	.background(.white)
	.hover {
		$0.background("#f3f4f6")
	}
	.dark {
		$0
			.background("#0f172a")
			.hover {
				$0.background("#1e293b")
			}
	}
```

Use ``declaration(_:_:)`` for properties without a modifier.
*/
public struct Style: Sendable {
	var declarations = [Declaration]()
	var children = [StyleNode]()

	/**
	Whether the nested rules are in a scope of the element. See ``scoped()``.
	*/
	var isScoped = false

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
	Puts the style and its nested rules in a scope of the element, like `@scope (…)` in CSS. When two scoped rules have the same specificity, the rule of the closer element wins, whatever their order. Use it for styles of markup that components do not own, like typography for Markdown, where an alert inside prose should win over the prose.
	*/
	public func scoped() -> Self {
		var copy = self
		copy.isScoped = true
		return copy
	}

	/**
	The rule of the style for the selector. A scoped style is wrapped in `@scope`, with `:scope` as the selector.
	*/
	func node(selector: String) -> StyleNode {
		guard
			isScoped,
			!declarations.isEmpty || !children.isEmpty
		else {
			return .rule(selector: selector, declarations: declarations, children: children)
		}

		return .conditional(prelude: "@scope (\(selector))", declarations: [], children: [.rule(selector: ":scope", declarations: declarations, children: children)])
	}

	/**
	The style with the declarations and conditions of another style added, like a custom view modifier that is a value.
	*/
	public func combined(with other: Self) -> Self {
		var copy = self
		copy.declarations += other.declarations
		copy.children.append(merging: other.children)
		copy.definitions += other.definitions
		return copy
	}

	/**
	Styles for a nested selector, like CSS nesting: `&` is this element (`"&:first-child"`, `"& > li"`), and a selector without `&` matches descendants (`".icon"`).
	*/
	public func nested(_ selector: String, _ content: (Self) -> Self) -> Self {
		let style = content(Self())
		var copy = self
		copy.children.append(merging: [.rule(selector: selector, declarations: style.declarations, children: style.children)])
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
	Styles that apply when the browser supports a feature, like `.supports(.scrollTimeline)`.
	*/
	public func supports(_ feature: BrowserFeature, _ content: (Self) -> Self) -> Self {
		conditional("@supports \(feature)", content)
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
		copy.children.append(merging: [.conditional(prelude: prelude, declarations: style.declarations, children: style.children)])
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

	/**
	Styles while the element has focus, also after a click, like a form field that shows where the visitor types. For a focus ring that only shows for the keyboard, use ``focusVisible(_:)``.
	*/
	public func focus(_ content: (Self) -> Self) -> Self {
		nested("&:focus", content)
	}

	public func focusVisible(_ content: (Self) -> Self) -> Self {
		nested("&:focus-visible", content)
	}

	/**
	Styles each element inside that shows its focus, like one focus ring for all the controls of a page with its own look.
	*/
	public func focusVisibleInside(_ content: (Self) -> Self) -> Self {
		nested("& :focus-visible", content)
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

	/**
	Styles while the element is the current one of a set, like the link to the current page in a navigation (`aria-current`).
	*/
	public func current(_ content: (Self) -> Self) -> Self {
		nested("&[aria-current]", content)
	}

	public func active(_ content: (Self) -> Self) -> Self {
		nested("&:active", content)
	}

	public func disabled(_ content: (Self) -> Self) -> Self {
		nested("&:disabled", content)
	}

	/**
	Styles while the element is the last child of its parent.
	*/
	public func lastChild(_ content: (Self) -> Self) -> Self {
		nested("&:last-child", content)
	}

	/**
	Styles while a form control is invalid after the visitor used it, like after leaving a field with a mistake.
	*/
	public func userInvalid(_ content: (Self) -> Self) -> Self {
		nested("&:user-invalid", content)
	}

	/**
	Styles while the element is an open popover.
	*/
	public func popoverOpen(_ content: (Self) -> Self) -> Self {
		nested("&:popover-open", content)
	}

	/**
	Styles while the element is open, like a `<details>` element that shows its content, or a `<dialog>`. For a popover, use ``popoverOpen(_:)``.
	*/
	public func open(_ content: (Self) -> Self) -> Self {
		nested("&:open", content)
	}

	/**
	Styles while a custom element has the custom state, which its script adds to the states of its element internals (a `CustomStateSet`): `&:state(name)`. It is not a data attribute, like `data-state`.

	```swift
	// The script of the element: `this.#internals.states.add('playing')`
	Style()
		.opacity(0.6)
		.state("playing") {
			$0.opacity(1)
		}
	```
	*/
	public func state(_ name: String, _ content: (Self) -> Self) -> Self {
		nested("&:state(\(name))", content)
	}

	public func placeholder(_ content: (Self) -> Self) -> Self {
		nested("&::placeholder", content)
	}

	/**
	The `::details-content` pseudo-element: the content of a `<details>` element after its summary, like for a height that animates when it opens.
	*/
	public func detailsContent(_ content: (Self) -> Self) -> Self {
		nested("&::details-content", content)
	}

	/**
	The `::backdrop` pseudo-element: the layer between the page and a modal dialog, a popover, or an element in full screen, like a dim color that covers the page.
	*/
	public func backdrop(_ content: (Self) -> Self) -> Self {
		nested("&::backdrop", content)
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
	public func from(_ breakpoint: Breakpoint, _ content: (Self) -> Self) -> Self {
		media(.from(breakpoint), content)
	}

	/**
	Styles for screens narrower than the breakpoint.
	*/
	public func below(_ breakpoint: Breakpoint, _ content: (Self) -> Self) -> Self {
		media(.below(breakpoint), content)
	}

	/**
	Styles for the direct children that match the selector, like `children("li")` for `& > li`.
	*/
	public func children(_ selector: String, _ content: (Self) -> Self) -> Self {
		nested("& > \(selector)", content)
	}

	/**
	Styles for another element on a page that has this element, like the site header on a page with a background that continues behind it: `:root:has(&) selector`.
	*/
	public func onSamePage(_ selector: String, _ content: (Self) -> Self) -> Self {
		nested(":root:has(&) \(selector)", content)
	}

	/**
	Styles for the root element on a page that has this element: `:root:has(&)`.

	The browser checks `:has()` again on every change of the page, so on a large page that changes often, a style here can make every change lay out the whole page. For a page with its own look, prefer a `:root` rule in a stylesheet of that page.
	*/
	public func onPageRoot(_ content: (Self) -> Self) -> Self {
		nested(":root:has(&)", content)
	}
}
