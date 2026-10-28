import Elementary
import Foundation
import SiteKit

/**
The IDs that a script finds elements by. A component declares the IDs of its elements as a nested `enum IDs: String, ScriptIDSet`, and the data attributes as a nested `enum Hooks: String, ScriptDataAttributeSet`, like it declares its `Styles`. Another file that needs one uses it from there, like `AppHero.IDs.hero`. A test checks that the scripts still use each one, and that every ID and data attribute a script uses is declared.

```swift
enum IDs: String, ScriptIDSet {
	case restart = "appdle-restart"
}

button(.id(IDs.restart)) {}
```

As the two kinds are different types, an ID cannot be used as a data attribute, or the opposite. Refer to an ID with `id`, like `.for(IDs.name.id)`, or `'#\#(IDs.wall.id)'` in an inline script, not with `rawValue`.
*/
protocol ScriptIDSet: RawRepresentable<String>, CaseIterable {}

extension ScriptIDSet {
	/**
	The ID, for an attribute or a script that refers to the element, like `.ariaControls(IDs.menu.id)`.
	*/
	var id: ElementID {
		ElementID(rawValue)
	}
}

/**
The data attributes that a script finds elements by, or reads the value of, like `data-mac-theme="bondi"`, declared as a nested `enum Hooks: String, ScriptDataAttributeSet` (see ``ScriptIDSet``). The raw value is the name after `data-`, like `mac-theme` for `data-mac-theme`, which ``attributeName`` adds, so an attribute cannot miss it.

```swift
enum Hooks: String, ScriptDataAttributeSet {
	case theme = "mac-theme"
}

div(.hook(Hooks.theme, value: "bondi")) {}
```

Refer to the name of a data attribute with `attributeName`, not with `rawValue`.
*/
protocol ScriptDataAttributeSet: RawRepresentable<String>, CaseIterable {}

extension ScriptDataAttributeSet {
	/**
	The name of the data attribute, like `setAttribute('\#(Hooks.hasProduct.attributeName)', '')` in an inline script.
	*/
	var attributeName: String {
		"data-\(rawValue)"
	}

	/**
	The attribute selector of the data attribute, like `[data-mac-theme="bondi"]`, or `[data-mac-theme]` for any value.
	*/
	func selector(value: String? = nil) -> CSSSelector {
		.attribute(attributeName, value: value)
	}
}

extension HTMLAttribute where Tag: HTMLTrait.Attributes.Global {
	/**
	The ID that a script finds the element by.
	*/
	static func id(_ id: some ScriptIDSet) -> Self {
		.id(id.id)
	}

	/**
	The data attribute that a script finds the element by, or reads the value of.
	*/
	static func hook(_ attribute: some ScriptDataAttributeSet, value: String = "") -> Self {
		.custom(name: attribute.attributeName, value: value)
	}
}

extension HTMLAttribute where Tag == HTMLTag.button {
	/**
	Shows or hides the popover that a script also finds by its ID.
	*/
	static func popoverTarget(_ id: some ScriptIDSet) -> Self {
		.popoverTarget(id.id)
	}
}

extension JSONScript {
	/**
	Data for a page script, which finds it by the ID.
	*/
	init(id: some ScriptIDSet, _ value: some Encodable) {
		self.init(id: id.id, value)
	}
}

extension Style {
	/**
	Styles while a script has set the data attribute on the element, optionally to the value, like `when(Hooks.theme, is: "bondi")`. For a state, use an ``ElementStateSet``.
	*/
	func when(_ attribute: some ScriptDataAttributeSet, is value: String? = nil, _ content: (Self) -> Self) -> Self {
		nested("&\(attribute.selector(value: value))", content)
	}

	/**
	Styles while a script has set the data attribute on an ancestor, optionally to the value, like on the site header for the navigation in it.
	*/
	func when(ancestorHas attribute: some ScriptDataAttributeSet, is value: String? = nil, _ content: (Self) -> Self) -> Self {
		nested("\(attribute.selector(value: value)) &", content)
	}
}
