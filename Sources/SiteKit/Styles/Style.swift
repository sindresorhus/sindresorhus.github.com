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
	private var isScoped = false

	/**
	The keyframes and the registered custom properties that the style and its conditions use, so a stylesheet with the style also has them. They are written after the rule of the style, not in it (``nodes(selector:)``).
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
	Sets a property from a typed value without converting it at the call site.
	*/
	public func declaration(_ property: Property, _ value: some StyleValue) -> Self {
		declaration(property, CSSValue(value))
	}

	/**
	Sets a property to a keyword, like ``Display/grid``.
	*/
	public func declaration(_ property: Property, _ keyword: some CSSKeyword) -> Self {
		declaration(property, CSSValue(keyword))
	}

	/**
	Sets a property from a typed value when there is one, like for an optional parameter of a modifier.
	*/
	func declaration(_ property: Property, ifPresent value: some StyleValue?) -> Self {
		guard let value else {
			return self
		}

		return declaration(property, value)
	}

	/**
	Sets a property to a keyword when there is one, like for an optional parameter of a modifier.
	*/
	func declaration(_ property: Property, ifPresent keyword: some CSSKeyword?) -> Self {
		guard let keyword else {
			return self
		}

		return declaration(property, keyword)
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
	The rule of the style for the selector, and then the keyframes and registered properties it uses. A scoped style is wrapped in `@scope`, with `:scope` as the selector.
	*/
	func nodes(selector: CSSSelector) -> [StyleNode] {
		guard
			isScoped,
			!declarations.isEmpty || !children.isEmpty
		else {
			return [.block(selector.description, declarations: declarations, children: children)] + definitions
		}

		return [.block("@scope (\(selector))", children: [.block(":scope", declarations: declarations, children: children)])] + definitions
	}

	/**
	The style with the declarations and conditions of another style added, like a custom view modifier that is a value. The result is scoped when either style is scoped.
	*/
	public func combined(with other: Self) -> Self {
		var copy = self
		copy.declarations += other.declarations
		copy.children.append(merging: other.children)
		copy.definitions += other.definitions
		copy.isScoped = isScoped || other.isScoped
		return copy
	}

	/**
	Styles for a nested selector, like CSS nesting: `&` is this element (`"&:first-child"`, `"& > li"`), and a selector without `&` matches descendants (`".icon"`).
	*/
	public func nested(_ selector: CSSSelector, _ content: (Self) -> Self) -> Self {
		block(selector.description, content)
	}

	/**
	Styles that apply when the media query matches.
	*/
	public func media(_ query: MediaQuery, _ content: (Self) -> Self) -> Self {
		block("@media \(query)", content)
	}

	/**
	Styles that apply when the browser supports a feature, like `.supports(.scrollTimeline)`.
	*/
	public func supports(_ feature: BrowserFeature, _ content: (Self) -> Self) -> Self {
		block("@supports \(feature)", content)
	}

	/**
	The styles an element transitions from when it appears, like when it stops being hidden.
	*/
	public func startingStyle(_ content: (Self) -> Self) -> Self {
		block("@starting-style", content)
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

	/**
	A nested block with the style of the closure: a rule for a nested selector, like `&:hover`, or a condition, like `@media (…)`. Both are blocks in CSS, with the same nesting.
	*/
	private func block(_ prelude: String, _ content: (Self) -> Self) -> Self {
		let style = content(Self())
		var copy = self
		copy.children.append(merging: [.block(prelude, declarations: style.declarations, children: style.children)])
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
	Styles while the pointer is over the element, or while it has the focus of the keyboard, like the fill of a link that shows which one Tab reached, for a site without focus rings.
	*/
	public func hoverOrFocusVisible(_ content: (Self) -> Self) -> Self {
		hover(content).focusVisible(content)
	}

	/**
	Styles each element inside that shows its focus, like one focus ring for all the controls of a page with its own look.
	*/
	public func focusVisibleInside(_ content: (Self) -> Self) -> Self {
		nested("& :focus-visible", content)
	}

	/**
	Styles while an element inside shows its focus, like a card that is lit while the keyboard is on its link.
	*/
	public func descendantFocusVisible(_ content: (Self) -> Self) -> Self {
		nested("&:has(:focus-visible)", content)
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

	/**
	Styles while an element around the element is the current one of a set (`aria-current`), like the text of the open message in a list.
	*/
	public func ancestorCurrent(_ content: (Self) -> Self) -> Self {
		nested("[aria-current] &", content)
	}

	/**
	Styles while a toggle button is pressed (`aria-pressed="true"`), like the tool that is picked, so the look always matches what screen readers say. The script only sets `aria-pressed`, and Swift renders the first value with ``HTMLAttribute/ariaPressed(_:)``.
	*/
	public func pressed(_ content: (Self) -> Self) -> Self {
		nested("&[aria-pressed=\"true\"]", content)
	}

	/**
	Styles while a toggle button around the element is pressed (`aria-pressed="true"`), like the light of the button.
	*/
	public func ancestorPressed(_ content: (Self) -> Self) -> Self {
		nested("[aria-pressed=\"true\"] &", content)
	}

	/**
	Styles while a toggle button in the element is pressed (`aria-pressed="true"`), like the box around the button.
	*/
	public func descendantPressed(_ content: (Self) -> Self) -> Self {
		nested("&:has([aria-pressed=\"true\"])", content)
	}

	/**
	Styles while a checkbox or radio button in the element is checked, like the label of a hidden radio button.
	*/
	public func descendantChecked(_ content: (Self) -> Self) -> Self {
		nested("&:has(input:checked)", content)
	}

	/**
	Styles while the element that a button controls is open (`aria-expanded="true"`), like a menu button while its menu shows, so the look always matches what screen readers say.
	*/
	public func expanded(_ content: (Self) -> Self) -> Self {
		nested("&[aria-expanded=\"true\"]", content)
	}

	public func active(_ content: (Self) -> Self) -> Self {
		nested("&:active", content)
	}

	public func disabled(_ content: (Self) -> Self) -> Self {
		nested("&:disabled", content)
	}

	/**
	Styles while a control around the element is disabled, like the icon of a disabled button: `:disabled &`.
	*/
	public func ancestorDisabled(_ content: (Self) -> Self) -> Self {
		nested(":disabled &", content)
	}

	/**
	Styles while the element is the first child of its parent.
	*/
	public func firstChild(_ content: (Self) -> Self) -> Self {
		nested("&:first-child", content)
	}

	/**
	Styles while the element is the last child of its parent.
	*/
	public func lastChild(_ content: (Self) -> Self) -> Self {
		nested("&:last-child", content)
	}

	/**
	Styles while the element has no children, not even text, like a list that a script has not filled in yet.
	*/
	public func empty(_ content: (Self) -> Self) -> Self {
		nested("&:empty", content)
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
	Styles while a custom element has the custom state, which its script adds to the states of its element internals (a `CustomStateSet`): `&:state(name)`. It is not a data attribute, like `data-state`, which a style reads with `when(States.copied)` (``ElementStateSet``).

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
		nested("&:state(\(raw: name))", content)
	}

	/**
	Styles while a script has set the state on the element (``ElementStateSet``): `&[data-state="copied"]`.

	```swift
	Style()
		.when(States.copied) {
			$0.color(.green)
		}
	```
	*/
	public func when(_ state: some ElementStateSet, _ content: (Self) -> Self) -> Self {
		nested("&\(state.selector)", content)
	}

	/**
	Styles while a script has set the state on an ancestor of the element (``ElementStateSet``), like the label of a copy button while the button shows that it copied: `[data-state="copied"] &`.
	*/
	public func when(ancestorHas state: some ElementStateSet, _ content: (Self) -> Self) -> Self {
		nested("\(state.selector) &", content)
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
	The `::before` pseudo-element. Set ``content(_:alternativeText:)`` to show it.
	*/
	public func before(_ content: (Self) -> Self) -> Self {
		nested("&::before", content)
	}

	/**
	The `::after` pseudo-element. Set ``content(_:alternativeText:)`` to show it.
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
	Styles for the direct children that match the selector, like `children("li")` for `& > li`. A list of selectors, like `children("p, label")`, is in `:is()`, as `& > p, label` would match a `label` at any depth. So the list cannot have a pseudo-element.
	*/
	public func children(_ selector: CSSSelector, _ content: (Self) -> Self) -> Self {
		nested(selector.description.contains(",") ? "& > :is(\(selector))" : "& > \(selector)", content)
	}

	/**
	Styles for the descendants that match the selector, without specificity, so a component inside wins, like the elements of prose: `& :where(selector)`. The selector can be a list, like `descendants("ul, ol")`.

	The selector cannot have a pseudo-element, as `:where()` cannot match one. Style it inside, like `descendants("li") { $0.before { … } }`.
	*/
	public func descendants(_ selector: CSSSelector, _ content: (Self) -> Self) -> Self {
		nested("& :where(\(selector))", content)
	}

	/**
	Styles for another element on a page that has this element, like the site header on a page with a background that continues behind it: `:root:has(&) selector`.
	*/
	public func onSamePage(_ selector: CSSSelector, _ content: (Self) -> Self) -> Self {
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
