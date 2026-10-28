/**
A custom property that a component reads for a part of its look, so a parent can change that part without a nested selector into the component, like the size of a badge. The component gives the default.

The type of the value is part of the variable, like the type of an environment value in SwiftUI, so typed modifiers take the variable:

```swift
// In the component:
static let fontSize = StyleVariable<LengthPercentage>("badge-font-size")

Style().font(size: Badge.fontSize.value(default: .pixels(10)))

// In a parent:
Style().setting(Badge.fontSize, to: .pixels(16))
```
*/
public struct StyleVariable<Value: StyleValue>: Sendable {
	public let name: DashedIdentifier

	/**
	- Parameter name: The name without the CSS `--` prefix, like `badge-font-size`.
	*/
	public init(_ name: DashedIdentifier) {
		self.name = name
	}

	/**
	The value that a parent or a script set.
	*/
	public var value: Value {
		Value(raw: CSSValue.variable(name).description)
	}

	/**
	The value that a parent set, or the default.
	*/
	public func value(default defaultValue: Value) -> Value {
		Value(raw: CSSValue.variable(name, fallback: CSSValue(defaultValue)).description)
	}
}

/**
A name with the CSS `--` prefix (`<dashed-ident>`), like `--site-header`: the name of a custom property (``StyleVariable``), an anchor (``Anchor``), or a timeline (``ViewTimeline``). Pass the name without the prefix, which is added automatically. The supported spelling is a nonempty sequence of ASCII letters, digits, underscores, and hyphens, including a leading digit.
*/
public struct DashedIdentifier: Hashable, Sendable, ExpressibleByStringInterpolation, CustomStringConvertible {
	/**
	The name, like `--site-header`, for CSS.
	*/
	public let description: String

	/**
	Creates an identifier from a name without the CSS `--` prefix, like `site-header`.
	*/
	public init(_ name: String) {
		do {
			try self.init(validating: name)
		} catch {
			preconditionFailure(error.reason)
		}
	}

	/**
	Checks a dynamic name without the CSS `--` prefix. Supports ASCII letters, digits, underscores, and hyphens; escaped and non-ASCII spellings are unsupported.
	*/
	public init(validating name: String) throws(ContentError) {
		guard
			!name.isEmpty,
			name.utf8.allSatisfy({ $0.isASCIILetter || $0.isASCIIDigit || $0 == 95 || $0 == 45 })
		else {
			throw ContentError(reason: "A CSS dashed identifier must have a nonempty name containing only ASCII letters, digits, underscores, and hyphens, got “\(name)”.")
		}

		self.description = "--\(name)"
	}

	/**
	A name without the CSS `--` prefix, from a string literal, like `"site-header"`, or one that is built with interpolation, like `"\(palette)-\(shade)"`.
	*/
	public init(stringLiteral name: String) {
		self.init(name)
	}
}

extension Style {
	/**
	Sets a variable for the element and its descendants, like the size of the badges inside.
	*/
	public func setting<Value>(_ variable: StyleVariable<Value>, to value: Value) -> Self {
		declaration(Property(variable.name.description), value)
	}
}
