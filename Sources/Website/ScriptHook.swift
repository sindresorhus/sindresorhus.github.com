import Elementary
import Foundation
import SiteKit

/**
The IDs and data attributes that a script finds elements by, or reads the value of, like `data-mac-theme="bondi"`. A component declares the hooks of its elements as a nested `enum Hooks: String, ScriptHookSet`, like it declares its `Styles`, and another file that needs one uses it from there, like `AppHero.Hooks.hero`, and a test checks that the scripts still use each one, and that every hook a script uses is declared.

```swift
enum Hooks: String, ScriptHookSet {
	case restart = "appdle-restart"
}

button(.id(Hooks.restart)) {}
```

A data attribute starts with `data-`. Every other hook is an ID. An enum can have both, so the functions of an ID, like `.id(_:)`, and of a data attribute, like `.hook(_:)`, fail at the first render for the other kind. Refer to the ID of a hook with `id`, like `.for(Hooks.name.id)`, or `'#\#(Hooks.wall.id)'` in an inline script, not with `rawValue`.
*/
protocol ScriptHookSet: RawRepresentable<String>, CaseIterable {}

extension ScriptHookSet {
	/**
	The ID, for an attribute or a script that refers to the element, like `.ariaControls(Hooks.menu.id)`. It fails for a data attribute.
	*/
	var id: String {
		precondition(!rawValue.hasPrefix("data-"), "The hook “\(rawValue)” is a data attribute, not an ID. Use `.hook(_:)` for it.")
		return rawValue
	}

	/**
	The name of the data attribute. It fails for an ID.
	*/
	fileprivate var attributeName: String {
		precondition(rawValue.hasPrefix("data-"), "The hook “\(rawValue)” is an ID, not a data attribute. Use `.id(_:)` for it, or start it with `data-`.")
		return rawValue
	}

	/**
	The attribute selector of a data attribute, like `[data-mac-theme="bondi"]`, or `[data-mac-theme]` for any value.
	*/
	func selector(value: String? = nil) -> CSSSelector {
		guard let value else {
			return "[\(raw: attributeName)]"
		}

		return "[\(raw: attributeName)=\"\(raw: value)\"]"
	}
}

extension HTMLAttribute where Tag: HTMLTrait.Attributes.Global {
	/**
	The ID that a script finds the element by.
	*/
	static func id(_ id: some ScriptHookSet) -> Self {
		.id(id.id)
	}

	/**
	The data attribute that a script finds the element by, or reads the value of.
	*/
	static func hook(_ attribute: some ScriptHookSet, value: String = "") -> Self {
		.custom(name: attribute.attributeName, value: value)
	}
}

extension HTMLAttribute where Tag == HTMLTag.button {
	/**
	Shows or hides the popover that a script also finds by its ID.
	*/
	static func popoverTarget(_ id: some ScriptHookSet) -> Self {
		.popoverTarget(id.id)
	}
}

extension JSONScript {
	/**
	Data for a page script, which finds it by the ID.
	*/
	init(id: some ScriptHookSet, _ value: some Encodable) {
		self.init(id: id.id, value)
	}
}

extension Style {
	/**
	Styles while a script has set the data attribute on the element, optionally to the value, like `when(Hooks.theme, is: "bondi")`. For a state, use an ``ElementStateSet``.
	*/
	func when(_ attribute: some ScriptHookSet, is value: String? = nil, _ content: (Self) -> Self) -> Self {
		nested("&\(attribute.selector(value: value))", content)
	}

	/**
	Styles while a script has set the data attribute on an ancestor, optionally to the value, like on the site header for the navigation in it.
	*/
	func when(ancestorHas attribute: some ScriptHookSet, is value: String? = nil, _ content: (Self) -> Self) -> Self {
		nested("\(attribute.selector(value: value)) &", content)
	}
}
