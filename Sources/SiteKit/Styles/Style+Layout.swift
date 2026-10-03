// MARK: Stacks and grids

extension Style {
	public func display(_ display: Display) -> Self {
		declaration(.display, CSSValue(display.rawValue))
	}

	/**
	Hides the element, like `display: none`.
	*/
	public func hidden() -> Self {
		display(.none)
	}

	/**
	Hides the element on screens narrower than the breakpoint. Wider screens use the display of the style, like a stack.
	*/
	public func hidden(below breakpoint: Breakpoint) -> Self {
		below(breakpoint) {
			$0.hidden()
		}
	}

	/**
	Hides the element on screens at least as wide as the breakpoint.
	*/
	public func hidden(from breakpoint: Breakpoint) -> Self {
		self.breakpoint(breakpoint) {
			$0.hidden()
		}
	}

	/**
	A flex row, like an `HStack`.

	- Parameter isInline: Whether the stack flows with the text around it, like `inline-flex`.
	*/
	public func hstack(alignment: Alignment? = nil, justification: Justification? = nil, spacing: Length? = nil, isInline: Bool = false) -> Self {
		stack(direction: nil, alignment: alignment, justification: justification, spacing: spacing, isInline: isInline)
	}

	/**
	A flex column, like a `VStack`.

	- Parameter isInline: Whether the stack flows with the text around it, like `inline-flex`.
	*/
	public func vstack(alignment: Alignment? = nil, justification: Justification? = nil, spacing: Length? = nil, isInline: Bool = false) -> Self {
		stack(direction: .column, alignment: alignment, justification: justification, spacing: spacing, isInline: isInline)
	}

	private func stack(direction: FlexDirection?, alignment: Alignment?, justification: Justification?, spacing: Length?, isInline: Bool) -> Self {
		var style = display(isInline ? .inlineFlex : .flex)

		if let direction {
			style = style.flexDirection(direction)
		}

		if let alignment {
			style = style.alignItems(alignment)
		}

		if let justification {
			style = style.justifyContent(justification)
		}

		if let spacing {
			style = style.gap(spacing)
		}

		return style
	}

	public func flexDirection(_ direction: FlexDirection) -> Self {
		declaration(.flexDirection, CSSValue(direction.rawValue))
	}

	public func flexWrap() -> Self {
		declaration(.flexWrap, "wrap")
	}

	public func alignItems(_ alignment: Alignment) -> Self {
		declaration(.alignItems, CSSValue(alignment.rawValue))
	}

	public func alignSelf(_ alignment: Alignment) -> Self {
		declaration(.alignSelf, CSSValue(alignment.rawValue))
	}

	public func justifyContent(_ justification: Justification) -> Self {
		declaration(.justifyContent, CSSValue(justification.rawValue))
	}

	public func gap(_ length: Length) -> Self {
		declaration(.gap, CSSValue(length))
	}

	public func gap(row: Length? = nil, column: Length? = nil) -> Self {
		var style = self

		if let row {
			style = style.declaration(.rowGap, CSSValue(row))
		}

		if let column {
			style = style.declaration(.columnGap, CSSValue(column))
		}

		return style
	}

	/**
	How much the element grows to fill the free space of a stack, like `flex: 1`.
	*/
	public func flex(_ grow: Double) -> Self {
		declaration(.flex, CSSValue(floatLiteral: grow))
	}

	public func flexShrink(_ value: Double) -> Self {
		declaration(.flexShrink, CSSValue(floatLiteral: value))
	}

	/**
	A grid with equal-width columns.
	*/
	public func grid(columns: Int) -> Self {
		display(.grid).gridColumns(columns)
	}

	/**
	A grid with the column track sizes, like `repeat(auto-fill, minmax(16rem, 1fr))`.
	*/
	public func grid(columns: CSSValue) -> Self {
		display(.grid).gridColumns(columns)
	}

	/**
	The number of equal-width columns, without making the element a grid, like for a breakpoint.
	*/
	public func gridColumns(_ count: Int) -> Self {
		gridColumns(CSSValue("repeat(\(count), minmax(0, 1fr))"))
	}

	/**
	How many columns the element spans in a grid.
	*/
	public func gridColumnSpan(_ count: Int) -> Self {
		declaration(.gridColumn, CSSValue("span \(count) / span \(count)"))
	}

	/**
	The column track sizes, without making the element a grid, like for a breakpoint.
	*/
	public func gridColumns(_ columns: CSSValue) -> Self {
		declaration(.gridTemplateColumns, columns)
	}
}

// MARK: Size and position

extension Style {
	/**
	The size constraints, like SwiftUI's `frame` modifier.
	*/
	public func frame(width: Length? = nil, height: Length? = nil, minWidth: Length? = nil, maxWidth: Length? = nil, minHeight: Length? = nil, maxHeight: Length? = nil) -> Self {
		var style = self

		for (property, length) in [(Property.width, width), (.height, height), (.minWidth, minWidth), (.maxWidth, maxWidth), (.minHeight, minHeight), (.maxHeight, maxHeight)] {
			if let length {
				style = style.declaration(property, CSSValue(length))
			}
		}

		return style
	}

	/**
	The ratio of width to height, like `16 / 9`.
	*/
	public func aspectRatio(_ ratio: Double) -> Self {
		declaration(.aspectRatio, CSSValue(floatLiteral: ratio))
	}

	public func padding(_ length: Length) -> Self {
		declaration(.padding, CSSValue(length))
	}

	public func padding(_ edges: Edge.Set, _ length: Length) -> Self {
		edges.declarations(CSSValue(length), property: "padding").reduce(self) { $0.declaration($1.property, $1.value) }
	}

	public func padding(vertical: Length, horizontal: Length) -> Self {
		declaration(.padding, CSSValue("\(vertical) \(horizontal)"))
	}

	/**
	The padding of the given edges. The other edges keep their padding.
	*/
	public func padding(top: Length? = nil, horizontal: Length? = nil, bottom: Length? = nil) -> Self {
		sides(top: top, horizontal: horizontal, bottom: bottom, property: "padding")
	}

	public func margin(_ length: Length) -> Self {
		declaration(.margin, CSSValue(length))
	}

	public func margin(_ edges: Edge.Set, _ length: Length) -> Self {
		edges.declarations(CSSValue(length), property: "margin").reduce(self) { $0.declaration($1.property, $1.value) }
	}

	public func margin(vertical: Length, horizontal: Length) -> Self {
		declaration(.margin, CSSValue("\(vertical) \(horizontal)"))
	}

	/**
	The margins of the given edges, like `margin(top: 0, horizontal: .auto, bottom: .rem(5))`. The other edges keep their margins.
	*/
	public func margin(top: Length? = nil, horizontal: Length? = nil, bottom: Length? = nil) -> Self {
		sides(top: top, horizontal: horizontal, bottom: bottom, property: "margin")
	}

	/**
	Sets the shorthand when all three are given, and each given side otherwise.
	*/
	private func sides(top: Length?, horizontal: Length?, bottom: Length?, property: String) -> Self {
		if let top, let horizontal, let bottom {
			return declaration(Property(property), CSSValue("\(top) \(horizontal) \(bottom)"))
		}

		var style = self

		for (edges, length) in [(Edge.Set.top, top), (.horizontal, horizontal), (.bottom, bottom)] {
			if let length {
				style = style.declarations(edges.declarations(CSSValue(length), property: property))
			}
		}

		return style
	}

	public func position(_ position: Position) -> Self {
		declaration(.position, CSSValue(position.rawValue))
	}

	public func inset(_ length: Length) -> Self {
		declaration(.inset, CSSValue(length))
	}

	public func top(_ length: Length) -> Self {
		declaration(.top, CSSValue(length))
	}

	public func bottom(_ length: Length) -> Self {
		declaration(.bottom, CSSValue(length))
	}

	/**
	The distance from the leading edge, like `inset-inline-start`.
	*/
	public func leading(_ length: Length) -> Self {
		declaration(.insetInlineStart, CSSValue(length))
	}

	/**
	The distance from the trailing edge, like `inset-inline-end`.
	*/
	public func trailing(_ length: Length) -> Self {
		declaration(.insetInlineEnd, CSSValue(length))
	}

	public func zIndex(_ index: Int) -> Self {
		declaration(.zIndex, CSSValue(integerLiteral: index))
	}

	public func overflow(_ overflow: Overflow) -> Self {
		declaration(.overflow, CSSValue(overflow.rawValue))
	}

	/**
	The overflow in the horizontal direction, like for a horizontally scrolling row.
	*/
	public func overflow(horizontal overflow: Overflow) -> Self {
		declaration(.overflowX, CSSValue(overflow.rawValue))
	}

	func declarations(_ declarations: [Declaration]) -> Self {
		declarations.reduce(self) { $0.declaration($1.property, $1.value) }
	}
}

extension Edge.Set {
	/**
	The declarations of a box property, like `padding`, for the edges: the shorthand for all edges, `padding-inline` and `padding-block` for an axis, and a property for each other edge. The leading and trailing edges follow the writing direction.
	*/
	func declarations(_ value: CSSValue, property: String) -> [Declaration] {
		if self == .all {
			return [Declaration(property: Property(property), value: value)]
		}

		var declarations = [Declaration]()

		if isSuperset(of: .vertical) {
			declarations.append(Declaration(property: Property("\(property)-block"), value: value))
		} else {
			for (edge, name) in [(Self.top, "top"), (.bottom, "bottom")] where contains(edge) {
				declarations.append(Declaration(property: Property("\(property)-\(name)"), value: value))
			}
		}

		if isSuperset(of: .horizontal) {
			declarations.append(Declaration(property: Property("\(property)-inline"), value: value))
		} else {
			for (edge, name) in [(Self.leading, "inline-start"), (.trailing, "inline-end")] where contains(edge) {
				declarations.append(Declaration(property: Property("\(property)-\(name)"), value: value))
			}
		}

		return declarations
	}
}
