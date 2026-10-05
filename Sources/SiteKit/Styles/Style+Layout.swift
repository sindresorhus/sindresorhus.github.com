// MARK: Stacks and grids

extension Style {
	public func display(_ display: Display) -> Self {
		declaration(.display, CSSValue(display.rawValue))
	}

	/**
	Hides the element, like `display: none`. Unlike SwiftUI's `hidden()`, the element takes no space.
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
		from(breakpoint) {
			$0.hidden()
		}
	}

	/**
	Shows the element only when JavaScript is turned off, like `<noscript>`, for a note that a feature needs JavaScript.
	*/
	public func shownOnlyWithoutScripting(display: Display = .block) -> Self {
		hidden()
			.media(.scriptingDisabled) {
				$0.display(display)
			}
	}

	/**
	Hides the element visually, but not from screen readers, like a label for an icon, or a file input with a styled label instead.
	*/
	public func visuallyHidden() -> Self {
		position(.absolute)
			.frame(width: .pixels(1), height: .pixels(1))
			.padding(0)
			.margin(.pixels(-1))
			.overflow(.hidden)
			.declaration(.clipPath, "inset(50%)")
			.textWrap(.nowrap)
			.declaration(.border, 0)
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

	/**
	Wraps the items onto more lines when they do not fit.

	- Parameter isReversed: Whether each new line goes above the last one instead of below it, like a pile that grows from the bottom.
	*/
	public func flexWrap(isReversed: Bool = false) -> Self {
		declaration(.flexWrap, isReversed ? "wrap-reverse" : "wrap")
	}

	/**
	Where the lines of a wrapping flex container go, like at its start, when they do not fill it.
	*/
	public func alignContent(_ alignment: Alignment) -> Self {
		declaration(.alignContent, CSSValue(alignment.rawValue))
	}

	public func alignItems(_ alignment: Alignment) -> Self {
		declaration(.alignItems, CSSValue(alignment.rawValue))
	}

	public func alignSelf(_ alignment: Alignment) -> Self {
		declaration(.alignSelf, CSSValue(alignment.rawValue))
	}

	/**
	How the element lines up in the inline direction of its grid cell, like `.center` to center it horizontally.
	*/
	public func justifySelf(_ alignment: Alignment) -> Self {
		declaration(.justifySelf, CSSValue(alignment.rawValue))
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
	Where the element goes among the items of its stack or grid, like `order: 1` to show it after the items with the default order of `0`. It changes only where the item shows, not the order of the Tab key or of a screen reader.
	*/
	public func order(_ order: Int) -> Self {
		declaration(.order, CSSValue(integerLiteral: order))
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
	A grid with as many equal-width columns as fit, each at least the minimum width, like `GridItem(.adaptive(minimum:))` in SwiftUI. A column is never wider than the grid, so one column fits on narrow screens.
	*/
	public func grid(minimumColumnWidth: Length) -> Self {
		grid(columns: CSSValue("repeat(auto-fill, minmax(min(100%, \(minimumColumnWidth)), 1fr))"))
	}

	/**
	The number of equal-width columns, without making the element a grid, like for a breakpoint.
	*/
	public func gridColumns(_ count: Int) -> Self {
		gridColumns(CSSValue("repeat(\(count), minmax(0, 1fr))"))
	}

	/**
	Puts the element in the first cell of its grid, so elements with it stack on each other, like the views of a `ZStack` in SwiftUI. The grid is as large as the largest of them.
	*/
	public func stackedInGrid() -> Self {
		declaration(.gridArea, "1 / 1")
	}

	/**
	How many columns the element spans in a grid.
	*/
	public func gridColumnSpan(_ count: Int) -> Self {
		declaration(.gridColumn, CSSValue("span \(count) / span \(count)"))
	}

	/**
	Flows the content through columns, like a newspaper: as many columns as fit, each at least the minimum width, and at most the maximum count. Children of different heights fit together, like cards. Use ``keepsTogether()`` on the children, so each stays in one column, and ``gap(row:column:)`` for the space between the columns.
	*/
	public func columns(_ maximumCount: Int, minimumWidth: Length) -> Self {
		declaration(.columns, CSSValue("\(minimumWidth) \(maximumCount)"))
	}

	/**
	Keeps the element in one column of ``columns(_:minimumWidth:)``, instead of splitting it across two.
	*/
	public func keepsTogether() -> Self {
		declaration(.breakInside, "avoid")
	}

	/**
	The space between the children of a block, as a top margin on each child after the first, like the spacing of a `VStack` for flowing content, which can mix text and blocks.
	*/
	public func flowSpacing(_ spacing: Length) -> Self {
		nested("& > * + *") {
			$0.margin(.top, spacing)
		}
	}

	/**
	Removes the top margin of the first child and the bottom margin of the last child, so the margins of the content do not add to the padding of the element.
	*/
	public func trimmingChildMargins() -> Self {
		children(":first-child") {
			$0.margin(.top, 0)
		}
		.children(":last-child") {
			$0.margin(.bottom, 0)
		}
	}

	/**
	The column track sizes, without making the element a grid, like for a breakpoint.
	*/
	public func gridColumns(_ columns: CSSValue) -> Self {
		declaration(.gridTemplateColumns, columns)
	}

	/**
	The number of rows, each with the size, like `gridRows(7, size: .auto)` for rows as tall as their content.
	*/
	public func gridRows(_ count: Int, size: GridTrack) -> Self {
		declaration(.gridTemplateRows, CSSValue("repeat(\(count), \(size))"))
	}

	/**
	The direction in which the items without a cell fill the grid, like `.column` to fill each column from the top before the next column.
	*/
	public func gridAutoFlow(_ flow: GridAutoFlow) -> Self {
		declaration(.gridAutoFlow, CSSValue(flow.rawValue))
	}

	/**
	The width of the columns that the grid adds for items outside its columns, like the columns of a grid that fills columns with ``gridAutoFlow(_:)``.
	*/
	public func gridAutoColumns(_ size: GridTrack) -> Self {
		declaration(.gridAutoColumns, CSSValue(size.description))
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

	/**
	How an image or a video fills its frame, like `.contain` to fit it without cropping, or `.cover` to fill it, like `scaledToFit()` and `scaledToFill()` in SwiftUI.
	*/
	public func objectFit(_ fit: ObjectFit) -> Self {
		declaration(.objectFit, CSSValue(fit.rawValue))
	}

	/**
	Makes the element a container, so the container units of its descendants, like ``Length/containerInlineSize(_:)``, are percentages of its content box.
	*/
	public func containerType(_ type: ContainerType) -> Self {
		declaration(.containerType, CSSValue(type.rawValue))
	}

	public func padding(_ length: Length) -> Self {
		declaration(.padding, CSSValue(length))
	}

	public func padding(_ edges: Edge.Set, _ length: Length) -> Self {
		declaration(.padding, CSSValue(length), edges: edges)
	}

	public func padding(vertical: Length, horizontal: Length) -> Self {
		declaration(.padding, CSSValue("\(vertical) \(horizontal)"))
	}

	/**
	The padding of the given edges. The other edges keep their padding.
	*/
	public func padding(top: Length? = nil, horizontal: Length? = nil, bottom: Length? = nil) -> Self {
		sides(top: top, horizontal: horizontal, bottom: bottom, property: .padding)
	}

	public func margin(_ length: Length) -> Self {
		declaration(.margin, CSSValue(length))
	}

	public func margin(_ edges: Edge.Set, _ length: Length) -> Self {
		declaration(.margin, CSSValue(length), edges: edges)
	}

	public func margin(vertical: Length, horizontal: Length) -> Self {
		declaration(.margin, CSSValue("\(vertical) \(horizontal)"))
	}

	/**
	The margins of the given edges, like `margin(top: 0, horizontal: .auto, bottom: .rootEm(5))`. The other edges keep their margins.
	*/
	public func margin(top: Length? = nil, horizontal: Length? = nil, bottom: Length? = nil) -> Self {
		sides(top: top, horizontal: horizontal, bottom: bottom, property: .margin)
	}

	/**
	Sets the shorthand when all three are given, and each given side otherwise.
	*/
	private func sides(top: Length?, horizontal: Length?, bottom: Length?, property: Property) -> Self {
		if
			let top,
			let horizontal,
			let bottom
		{
			return declaration(property, CSSValue("\(top) \(horizontal) \(bottom)"))
		}

		var style = self

		for (edges, length) in [(Edge.Set.top, top), (.horizontal, horizontal), (.bottom, bottom)] {
			if let length {
				style = style.declaration(property, CSSValue(length), edges: edges)
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

	/**
	Makes the element an anchor that positioned elements can be next to, with ``positionAnchor(_:)`` or ``Length/anchor(_:_:)``.
	*/
	public func anchorName(_ anchor: Anchor) -> Self {
		declaration(.anchorName, CSSValue(anchor.name))
	}

	/**
	The anchor that ``positionArea(_:)`` and ``Length/anchor(_:)`` position the element next to. Without it, a popover is next to the button that opened it.
	*/
	public func positionAnchor(_ anchor: Anchor) -> Self {
		declaration(.positionAnchor, CSSValue(anchor.name))
	}

	/**
	Where the positioned element goes around its anchor, like `.top` for a tooltip above its button. A popover also needs `inset(.auto)`, as its default insets of `0` and auto margins center it in the area instead of next to the anchor.
	*/
	public func positionArea(_ area: PositionArea) -> Self {
		declaration(.positionArea, CSSValue(area.rawValue))
	}

	/**
	The other positions that the browser tries, in order, when the positioned element does not fit, like `.flipBlock` for below the anchor when there is no space above it.
	*/
	public func positionTryFallbacks(_ fallback: PositionTryFallback, _ moreFallbacks: PositionTryFallback...) -> Self {
		declaration(.positionTryFallbacks, CSSValue(([fallback] + moreFallbacks).map(\.rawValue).joined(separator: ", ")))
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

	/**
	Moves the element to the edge, with the text that follows flowing around it, like a photo at the trailing edge of a paragraph. The edges follow the writing direction.
	*/
	public func float(_ edge: HorizontalEdge) -> Self {
		declaration(.float, CSSValue(edge.rawValue))
	}

	/**
	The areas at the top and the bottom of a scrolling element, like the page, that sticky bars cover, so links and focused controls scroll into view between the bars.
	*/
	public func scrollPadding(top: Length? = nil, bottom: Length? = nil) -> Self {
		var style = self

		if let top {
			style = style.declaration(.scrollPaddingTop, CSSValue(top))
		}

		if let bottom {
			style = style.declaration(.scrollPaddingBottom, CSSValue(bottom))
		}

		return style
	}

	/**
	The space above and below an element that the browser keeps free when it scrolls the element into view, like for a focused control under a sticky bar that only covers part of a page.
	*/
	public func scrollMargin(top: Length? = nil, bottom: Length? = nil) -> Self {
		var style = self

		if let top {
			style = style.declaration(.scrollMarginTop, CSSValue(top))
		}

		if let bottom {
			style = style.declaration(.scrollMarginBottom, CSSValue(bottom))
		}

		return style
	}

	/**
	Whether a scrolling element shows its scroll bars, like `.scrollIndicators(.hidden)` for a row that scrolls sideways with a swipe, like SwiftUI's `scrollIndicators(_:)`.
	*/
	public func scrollIndicators(_ visibility: ScrollIndicatorVisibility) -> Self {
		declaration(.scrollbarWidth, CSSValue(visibility.rawValue))
	}

	/**
	What a horizontal scroll does at the end of the element, like `.contain` for a row that scrolls sideways, so a swipe on a trackpad at its end does not go back in the history.
	*/
	public func overscrollBehavior(horizontal behavior: Overscroll) -> Self {
		declaration(.overscrollBehaviorX, CSSValue(behavior.rawValue))
	}

	/**
	Snaps the scrolling to the children with ``scrollSnapAlign(_:)``, like the pages of a carousel.

	- Parameter isMandatory: Whether the scrolling always stops at a child, instead of only when it stops near one.
	*/
	public func scrollSnapType(_ axis: ScrollSnapAxis, isMandatory: Bool = false) -> Self {
		declaration(.scrollSnapType, CSSValue(isMandatory ? "\(axis.rawValue) mandatory" : axis.rawValue))
	}

	/**
	Where the element stops in a scrolling element with ``scrollSnapType(_:isMandatory:)``, like `.center` for the item of a carousel.
	*/
	public func scrollSnapAlign(_ alignment: ScrollSnapAlignment) -> Self {
		declaration(.scrollSnapAlign, CSSValue(alignment.rawValue))
	}

	/**
	Whether the element keeps the space of a classic scroll bar when it does not scroll, like `.stable` on the page, so the layout does not move between pages that scroll and pages that do not.
	*/
	public func scrollbarGutter(_ gutter: ScrollbarGutter) -> Self {
		declaration(.scrollbarGutter, CSSValue(gutter.rawValue))
	}

	/**
	How the element scrolls to a link or a script position, like `.smooth` for an animated scroll. Use it only when the visitor allows motion.
	*/
	public func scrollBehavior(_ behavior: ScrollBehavior) -> Self {
		declaration(.scrollBehavior, CSSValue(behavior.rawValue))
	}

	/**
	Sets a box property, like `padding`, for the edges. See ``Edge/Set/declarations(_:property:)``.
	*/
	func declaration(_ property: Property, _ value: CSSValue, edges: Edge.Set) -> Self {
		var copy = self
		copy.declarations += edges.declarations(value, property: property)
		return copy
	}
}

extension Edge.Set {
	/**
	The declarations of a box property, like `padding`, for the edges: the shorthand for all edges, `padding-inline` and `padding-block` for an axis, and a property for each other edge. The leading and trailing edges follow the writing direction.
	*/
	func declarations(_ value: CSSValue, property: Property) -> [Declaration] {
		if self == .all {
			return [Declaration(property: property, value: value)]
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
