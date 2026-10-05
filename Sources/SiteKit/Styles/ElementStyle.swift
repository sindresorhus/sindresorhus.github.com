import Elementary

/**
A style that only one element has, written on the element itself, like a modifier in SwiftUI, so it needs no named case in a ``StyleSet``:

```swift
a(.href(app.path)) {
	"← Back"
}
.style {
	$0
		.secondaryText()
		.fontWeight(.medium)
}
```

The class name is the name of the file and a hash of the rules, like `back-link-1x2y3z4`, so the same style in the same file is one rule, and the class name tells where the style comes from. The page collects the rules like the rules of style sets, in their own cascade layer after the layer of the components (``PageResources/elementStyleNodes``), so a style on an element wins over the style of its component.

Use a named style set for a look that more than one element has, for variants, and for a style that another selector refers to, like a parent that changes the style of a child while it is hovered, as a hashed class name cannot be referred to.
*/
struct ElementStyle {
	let className: String
	let nodes: [StyleNode]

	init(_ style: Style, fileID: String) {
		let fileName = fileID.split(separator: "/").last.map { String($0.split(separator: ".").first ?? $0) } ?? "element"
		let css = Stylesheet { Rule(".element", style) }.css
		let hash = String(String(css.stableHash, radix: 36).suffix(7))
		// Only the characters of a class name, as a file name can have others, like `+` in `Page+Styles.swift`.
		let prefix = fileName.kebabCased.replacing(/[^a-z0-9-]+/, with: "-")
		self.className = "\(prefix)-\(hash)"
		self.nodes = [style.node(selector: ".\(className)")] + style.definitions
	}
}

extension HTML where Tag: HTMLTrait.Attributes.Global {
	/**
	Styles only this element, like a modifier in SwiftUI (``ElementStyle``).

	```swift
	p {
		"Hello"
	}
	.style {
		$0.secondaryText()
	}
	```
	*/
	public func style(fileID: String = #fileID, _ style: (Style) -> Style) -> _AttributedContent<Self> {
		let elementStyle = ElementStyle(style(Style()), fileID: fileID)
		PageResources.current?.use(elementStyle)
		return attributes(.class(elementStyle.className))
	}

	/**
	Lays out the children of the element in a column, like `VStack` in SwiftUI. See ``Style/vstack(alignment:justification:spacing:isInline:)``.
	*/
	public func vstack(alignment: Alignment? = nil, justification: Justification? = nil, spacing: Length? = nil, isInline: Bool = false, fileID: String = #fileID) -> _AttributedContent<Self> {
		style(fileID: fileID) {
			$0.vstack(alignment: alignment, justification: justification, spacing: spacing, isInline: isInline)
		}
	}

	/**
	Lays out the children of the element in a row, like `HStack` in SwiftUI. See ``Style/hstack(alignment:justification:spacing:isInline:)``.
	*/
	public func hstack(alignment: Alignment? = nil, justification: Justification? = nil, spacing: Length? = nil, isInline: Bool = false, fileID: String = #fileID) -> _AttributedContent<Self> {
		style(fileID: fileID) {
			$0.hstack(alignment: alignment, justification: justification, spacing: spacing, isInline: isInline)
		}
	}
}
