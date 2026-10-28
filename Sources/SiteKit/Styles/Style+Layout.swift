// MARK: Stacks and grids

extension Style {
	public func display(_ display: Display) -> Self {
		declaration(.display, display)
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
	Hides the element when JavaScript is turned off, like a button that only works with its script.
	*/
	public func hiddenWithoutScripting() -> Self {
		media(.scriptingDisabled) {
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
			.padding(.zero)
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
	public func hstack(
		alignment: Alignment? = nil,
		justification: Justification? = nil,
		spacing: LengthPercentage? = nil,
		isInline: Bool = false
	) -> Self {
		stack(
			direction: .row,
			alignment: alignment,
			justification: justification,
			spacing: spacing,
			isInline: isInline
		)
	}

	/**
	A flex column, like a `VStack`.

	- Parameter isInline: Whether the stack flows with the text around it, like `inline-flex`.
	*/
	public func vstack(
		alignment: Alignment? = nil,
		justification: Justification? = nil,
		spacing: LengthPercentage? = nil,
		isInline: Bool = false
	) -> Self {
		stack(
			direction: .column,
			alignment: alignment,
			justification: justification,
			spacing: spacing,
			isInline: isInline
		)
	}

	private func stack(
		direction: FlexDirection,
		alignment: Alignment?,
		justification: Justification?,
		spacing: LengthPercentage?,
		isInline: Bool
	) -> Self {
		display(isInline ? .inlineFlex : .flex)
			.declaration(.flexDirection, direction)
			.declaration(.alignItems, ifPresent: alignment)
			.declaration(.justifyContent, ifPresent: justification)
			.declaration(.gap, ifPresent: spacing)
	}

	public func flexDirection(_ direction: FlexDirection) -> Self {
		declaration(.flexDirection, direction)
	}

	/**
	Wraps the items onto more lines when they do not fit, or with `.nowrap`, keeps them on one line.
	*/
	public func flexWrap(_ wrap: FlexWrap = .wrap) -> Self {
		declaration(.flexWrap, wrap)
	}

	/**
	Where the lines of a wrapping flex container go, like at its start, when they do not fill it.
	*/
	public func alignContent(_ alignment: Alignment) -> Self {
		declaration(.alignContent, alignment)
	}

	public func alignItems(_ alignment: Alignment) -> Self {
		declaration(.alignItems, alignment)
	}

	public func alignSelf(_ alignment: Alignment) -> Self {
		declaration(.alignSelf, alignment)
	}

	/**
	How the element lines up in the inline direction of its grid cell, like `.center` to center it horizontally.
	*/
	public func justifySelf(_ alignment: Alignment) -> Self {
		declaration(.justifySelf, alignment)
	}

	public func justifyContent(_ justification: Justification) -> Self {
		declaration(.justifyContent, justification)
	}

	public func gap(_ length: LengthPercentage) -> Self {
		declaration(.gap, length)
	}

	public func gap(row: LengthPercentage? = nil, column: LengthPercentage? = nil) -> Self {
		declaration(.rowGap, ifPresent: row)
			.declaration(.columnGap, ifPresent: column)
	}

	/**
	How much the element grows to fill the free space of a stack, like `flex: 1`.
	*/
	public func flex(_ grow: CSSNumber) -> Self {
		declaration(.flex, grow)
	}

	public func flexShrink(_ value: CSSNumber) -> Self {
		declaration(.flexShrink, value)
	}

	/**
	Where the element goes among the items of its stack or grid, like `order: 1` to show it after the items with the default order of `0`. It changes only where the item shows, not the order of the Tab key or of a screen reader.
	*/
	public func order(_ order: Int) -> Self {
		declaration(.order, CSSValue(order))
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
	A grid with one or more typed tracks, including fixed, automatic, and flexible tracks.
	*/
	public func grid(columns first: GridTrack, _ remaining: GridTrack...) -> Self {
		grid(columns: GridTrackList([first] + remaining))
	}

	/**
	A grid composed from a typed track list, including fixed repetitions and adaptive columns.
	*/
	public func grid(columns: GridTrackList) -> Self {
		display(.grid).gridColumns(columns)
	}

	/**
	A grid with a leading column followed by repeated tracks, like a row number and one column for each channel.
	*/
	public func grid(columns first: GridTrack, repeating track: GridTrack, count: Int) -> Self {
		grid(columns: GridTrackList(first, repeating: track, count: count))
	}

	/**
	A grid with as many equal-width columns as fit, each at least the minimum width, like `GridItem(.adaptive(minimum:))` in SwiftUI. A column is never wider than the grid, so one column fits on narrow screens.
	*/
	public func grid(minimumColumnWidth: LengthPercentage) -> Self {
		grid(columns: GridTrackList.adaptive(minimum: minimumColumnWidth))
	}

	/**
	A grid like ``grid(minimumColumnWidth:)``, with at most the maximum number of columns, so the columns are wider when they have space, and fewer when their content needs the minimum width, like with large text. It also sets the spacing, as the widest columns depend on it.

	```swift
	Style().grid(minimumColumnWidth: .rootEm(9), maximumColumns: 3, spacing: .rootEm(0.5))
	//=> grid-template-columns: repeat(auto-fill, minmax(max(min(100%, 9rem), (100% - 1rem) / 3), 1fr)); gap: .5rem
	```
	*/
	public func grid(minimumColumnWidth: LengthPercentage, maximumColumns: Int, spacing: LengthPercentage) -> Self {
		grid(columns: GridTrackList.adaptive(minimum: minimumColumnWidth, maximumColumns: maximumColumns, spacing: spacing))
			.gap(spacing)
	}

	/**
	The number of equal-width columns, without making the element a grid, like for a breakpoint.
	*/
	public func gridColumns(_ count: Int) -> Self {
		gridColumns(GridTrackList.repeating(.flexible(), count: count))
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
		precondition(count > 0, "A grid or column count must be positive.")
		return declaration(.gridColumn, CSSValue(raw: "span \(count) / span \(count)"))
	}

	/**
	Spans every column of the grid, also when the number of columns changes, like a footer below the columns of a grid with as many columns as fit.
	*/
	public func gridColumnSpanAll() -> Self {
		declaration(.gridColumn, "1 / -1")
	}

	/**
	How many columns the element spans in a grid, from the column with the number, like `gridColumnSpan(2, from: 2)` for the second and third columns. The columns count from 1, like in CSS.
	*/
	public func gridColumnSpan(_ count: Int, from start: Int) -> Self {
		precondition(count > 0, "A grid or column count must be positive.")
		precondition(start != 0, "A grid line index must not be zero.")
		return declaration(.gridColumn, CSSValue(raw: "\(start) / span \(count)"))
	}

	/**
	How many rows the element spans in a grid.
	*/
	public func gridRowSpan(_ count: Int) -> Self {
		precondition(count > 0, "A grid or column count must be positive.")
		return declaration(.gridRow, CSSValue(raw: "span \(count) / span \(count)"))
	}

	/**
	Flows the content through columns, like a newspaper: as many columns as fit, each at least the minimum width, and at most the maximum count. Children of different heights fit together, like cards. Use ``keepsTogether()`` on the children, so each stays in one column, and ``gap(row:column:)`` for the space between the columns.
	*/
	public func columns(_ maximumCount: Int, minimumWidth: Length) -> Self {
		precondition(maximumCount > 0, "A grid or column count must be positive.")
		return declaration(.columns, CSSValue(raw: "\(minimumWidth) \(maximumCount)"))
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
	public func flowSpacing(_ spacing: LengthPercentage) -> Self {
		nested("& > * + *") {
			$0.margin(.top, .length(spacing))
		}
	}

	/**
	Removes the top margin of the first child and the bottom margin of the last child, so the margins of the content do not add to the padding of the element.
	*/
	public func trimmingChildMargins() -> Self {
		children(":first-child") {
			$0.margin(.top, .zero)
		}
		.children(":last-child") {
			$0.margin(.bottom, .zero)
		}
	}

	/**
	The column track sizes, without making the element a grid, like for a breakpoint.
	*/
	public func gridColumns(_ columns: CSSValue) -> Self {
		declaration(.gridTemplateColumns, columns)
	}

	/**
	The typed column list, without changing the element's display mode.
	*/
	public func gridColumns(_ columns: GridTrackList) -> Self {
		declaration(.gridTemplateColumns, columns)
	}

	/**
	The size of each column, without making the element a grid, like `gridColumns(.auto, .fraction(1))` for a column as wide as its content and a column with the rest of the space.
	*/
	public func gridColumns(_ first: GridTrack, _ others: GridTrack...) -> Self {
		gridColumns(GridTrackList([first] + others))
	}

	/**
	The number of rows, each with the size, like `gridRows(7, size: .auto)` for rows as tall as their content.
	*/
	public func gridRows(_ count: Int, size: GridTrack) -> Self {
		declaration(.gridTemplateRows, GridTrackList.repeating(size, count: count))
	}

	/**
	The direction in which the items without a cell fill the grid, like `.column` to fill each column from the top before the next column.
	*/
	public func gridAutoFlow(_ flow: GridAutoFlow) -> Self {
		declaration(.gridAutoFlow, flow)
	}

	/**
	The width of the columns that the grid adds for items outside its columns, like the columns of a grid that fills columns with ``gridAutoFlow(_:)``.
	*/
	public func gridAutoColumns(_ size: GridTrack) -> Self {
		declaration(.gridAutoColumns, size)
	}
}

// MARK: Size and position

extension Style {
	/**
	The same width and height, like for a square icon or a circle.
	*/
	public func frame(size: BoxSize) -> Self {
		frame(width: size, height: size)
	}

	/**
	The size constraints, like SwiftUI's `frame` modifier.
	*/
	public func frame(
		width: BoxSize? = nil,
		height: BoxSize? = nil,
		minWidth: BoxSize? = nil,
		maxWidth: MaximumBoxSize? = nil,
		minHeight: BoxSize? = nil,
		maxHeight: MaximumBoxSize? = nil
	) -> Self {
		declaration(.width, ifPresent: width)
			.declaration(.height, ifPresent: height)
			.declaration(.minWidth, ifPresent: minWidth)
			.declaration(.maxWidth, ifPresent: maxWidth)
			.declaration(.minHeight, ifPresent: minHeight)
			.declaration(.maxHeight, ifPresent: maxHeight)
	}

	/**
	The ratio of width to height, like `16 / 9`.
	*/
	public func aspectRatio(_ ratio: Double) -> Self {
		declaration(.aspectRatio, CSSValue(ratio))
	}

	/**
	How an image or a video fills its frame, like `.contain` to fit it without cropping, or `.cover` to fill it, like `scaledToFit()` and `scaledToFill()` in SwiftUI.
	*/
	public func objectFit(_ fit: ObjectFit) -> Self {
		declaration(.objectFit, fit)
	}

	/**
	Makes the element a container, so the container units of its descendants, like ``LengthPercentage/containerInlineSize(_:)``, are percentages of its content box.
	*/
	public func containerType(_ type: ContainerType) -> Self {
		declaration(.containerType, type)
	}

	/**
	Whether a declared size includes padding and borders.
	*/
	public func boxSizing(_ value: BoxSizing) -> Self {
		declaration(.boxSizing, value)
	}

	public func padding(_ length: LengthPercentage) -> Self {
		declaration(.padding, length)
	}

	public func padding(_ edges: Edge.Set, _ length: LengthPercentage) -> Self {
		declaration(.padding, length, edges: edges)
	}

	public func padding(vertical: LengthPercentage, horizontal: LengthPercentage) -> Self {
		declaration(.padding, CSSValue(raw: "\(vertical) \(horizontal)"))
	}

	/**
	The padding of the given edges. The other edges keep their padding.
	*/
	public func padding(top: LengthPercentage? = nil, horizontal: LengthPercentage? = nil, bottom: LengthPercentage? = nil) -> Self {
		sides(
			top: top,
			horizontal: horizontal,
			bottom: bottom,
			property: .padding
		)
	}

	public func margin(_ length: AutoLength) -> Self {
		declaration(.margin, length)
	}

	public func margin(_ edges: Edge.Set, _ length: AutoLength) -> Self {
		declaration(.margin, length, edges: edges)
	}

	public func margin(vertical: AutoLength, horizontal: AutoLength) -> Self {
		declaration(.margin, CSSValue(raw: "\(vertical) \(horizontal)"))
	}

	/**
	The margins of the given edges, like `margin(top: .zero, horizontal: .auto, bottom: .rootEm(5))`. The other edges keep their margins.
	*/
	public func margin(top: AutoLength? = nil, horizontal: AutoLength? = nil, bottom: AutoLength? = nil) -> Self {
		sides(
			top: top,
			horizontal: horizontal,
			bottom: bottom,
			property: .margin
		)
	}

	/**
	Sets the shorthand when all three are given, and each given side otherwise.
	*/
	private func sides<Value: StyleValue>(
		top: Value?,
		horizontal: Value?,
		bottom: Value?,
		property: BoxProperty
	) -> Self {
		if
			let top,
			let horizontal,
			let bottom
		{
			return declaration(property.property, CSSValue(raw: "\(top) \(horizontal) \(bottom)"))
		}

		var style = self

		for (edges, length) in [(Edge.Set.top, top), (.horizontal, horizontal), (.bottom, bottom)] {
			if let length {
				style = style.declaration(property, length, edges: edges)
			}
		}

		return style
	}

	public func position(_ position: Position) -> Self {
		declaration(.position, position)
	}

	public func inset(_ length: AutoLength) -> Self {
		declaration(.inset, length)
	}

	public func top(_ length: AutoLength) -> Self {
		declaration(.top, length)
	}

	/**
	The position of a side of an anchor, like `.top(anchor: header, side: .bottom)` for an element that starts below the header (`anchor(--site-header bottom)` in CSS).

	Without an explicit anchor, uses the default anchor from ``positionAnchor(_:)`` or the button that opened a popover. The side must be valid for this inset's axis.
	*/
	public func top(anchor: Anchor? = nil, side: AnchorSide) -> Self {
		let arguments = [anchor?.name.description, side.rawValue].compactMap(\.self).joined(separator: " ")
		return declaration(.top, CSSValue(raw: "anchor(\(arguments))"))
	}

	public func bottom(_ length: AutoLength) -> Self {
		declaration(.bottom, length)
	}

	/**
	The distance from the leading edge, like `inset-inline-start`.
	*/
	public func leading(_ length: AutoLength) -> Self {
		declaration(.insetInlineStart, length)
	}

	/**
	The distance from the trailing edge, like `inset-inline-end`.
	*/
	public func trailing(_ length: AutoLength) -> Self {
		declaration(.insetInlineEnd, length)
	}

	/**
	Makes the element an anchor that positioned elements can be next to, with ``positionAnchor(_:)`` or ``top(anchor:side:)``.
	*/
	public func anchorName(_ anchor: Anchor) -> Self {
		declaration(.anchorName, CSSValue(raw: anchor.name.description))
	}

	/**
	The anchor that ``positionArea(_:)`` and ``top(anchor:side:)`` position the element next to. Without it, a popover is next to the button that opened it.
	*/
	public func positionAnchor(_ anchor: Anchor) -> Self {
		declaration(.positionAnchor, CSSValue(raw: anchor.name.description))
	}

	/**
	Where the positioned element goes around its anchor, like `.top` for a tooltip above its button. A popover also needs `inset(.auto)`, as its default insets of `0` and auto margins center it in the area instead of next to the anchor.
	*/
	public func positionArea(_ area: PositionArea) -> Self {
		declaration(.positionArea, area)
	}

	/**
	The other positions that the browser tries, in order, when the positioned element does not fit, like `.flipBlock` for below the anchor when there is no space above it.
	*/
	public func positionTryFallbacks(_ fallback: PositionTryFallback, _ moreFallbacks: PositionTryFallback...) -> Self {
		declaration(.positionTryFallbacks, CSSValue(([fallback] + moreFallbacks).map(\.rawValue), separator: ", "))
	}

	public func zIndex(_ index: Int) -> Self {
		declaration(.zIndex, CSSValue(index))
	}

	public func overflow(_ overflow: Overflow) -> Self {
		declaration(.overflow, overflow)
	}

	/**
	The overflow in the horizontal direction, like for a horizontally scrolling row.
	*/
	public func overflow(horizontal overflow: Overflow) -> Self {
		declaration(.overflowX, overflow)
	}

	/**
	Moves the element to the edge, with the text that follows flowing around it, like a photo at the trailing edge of a paragraph. The edges follow the writing direction.
	*/
	public func float(_ edge: HorizontalEdge) -> Self {
		declaration(.float, edge)
	}

	/**
	The areas at the top and the bottom of a scrolling element, like the page, that sticky bars cover, so links and focused controls scroll into view between the bars. The area at the sides is for a row that scrolls sideways, like the space of the page in front of its first item, which the items then snap to.
	*/
	public func scrollPadding(top: LengthPercentage? = nil, bottom: LengthPercentage? = nil, horizontal: LengthPercentage? = nil) -> Self {
		declaration(.scrollPaddingTop, ifPresent: top)
			.declaration(.scrollPaddingBottom, ifPresent: bottom)
			.declaration(.scrollPaddingInline, ifPresent: horizontal)
	}

	/**
	The space above and below an element that the browser keeps free when it scrolls the element into view, like for a focused control under a sticky bar that only covers part of a page.
	*/
	public func scrollMargin(top: Length? = nil, bottom: Length? = nil) -> Self {
		declaration(.scrollMarginTop, ifPresent: top)
			.declaration(.scrollMarginBottom, ifPresent: bottom)
	}

	/**
	Whether a scrolling element shows its scroll bars, like `.scrollIndicators(.hidden)` for a row that scrolls sideways with a swipe, like SwiftUI's `scrollIndicators(_:)`.
	*/
	public func scrollIndicators(_ visibility: ScrollIndicatorVisibility) -> Self {
		declaration(.scrollbarWidth, visibility)
	}

	/**
	What a horizontal scroll does at the end of the element, like `.contain` for a row that scrolls sideways, so a swipe on a trackpad at its end does not go back in the history.
	*/
	public func overscrollBehavior(horizontal behavior: Overscroll) -> Self {
		declaration(.overscrollBehaviorX, behavior)
	}

	/**
	Snaps the scrolling to the children with ``scrollSnapAlign(_:)``, like the pages of a carousel.

	- Parameter isMandatory: Whether the scrolling always stops at a child, instead of only when it stops near one.
	*/
	public func scrollSnapType(_ axis: ScrollSnapAxis, isMandatory: Bool = false) -> Self {
		declaration(.scrollSnapType, CSSValue(raw: isMandatory ? "\(axis.rawValue) mandatory" : axis.rawValue))
	}

	/**
	Where the element stops in a scrolling element with ``scrollSnapType(_:isMandatory:)``, like `.center` for the item of a carousel.
	*/
	public func scrollSnapAlign(_ alignment: ScrollSnapAlignment) -> Self {
		declaration(.scrollSnapAlign, alignment)
	}

	/**
	Whether the element keeps the space of a classic scroll bar when it does not scroll, like `.stable` on the page, so the layout does not move between pages that scroll and pages that do not.
	*/
	public func scrollbarGutter(_ gutter: ScrollbarGutter) -> Self {
		declaration(.scrollbarGutter, gutter)
	}

	/**
	How the element scrolls to a link or a script position, like `.smooth` for an animated scroll. Use it only when the visitor allows motion.
	*/
	public func scrollBehavior(_ behavior: ScrollBehavior) -> Self {
		declaration(.scrollBehavior, behavior)
	}

	/**
	Sets a typed box value for the selected edges.
	*/
	func declaration(_ property: BoxProperty, _ value: some StyleValue, edges: Edge.Set) -> Self {
		declaration(property, CSSValue(value), edges: edges)
	}

	/**
	Sets a box property, like `padding`, for the edges. See ``Edge/Set/declarations(_:property:)``.
	*/
	func declaration(_ property: BoxProperty, _ value: CSSValue, edges: Edge.Set) -> Self {
		var copy = self
		copy.declarations += edges.declarations(value, property: property)
		return copy
	}
}

/**
Only these property families support the box edge suffixes. Arbitrary CSS properties cannot enter the expansion path.
*/
enum BoxProperty: String {
	case padding
	case margin
	case border

	var property: Property {
		Property(rawValue)
	}
}

extension Edge.Set {
	/**
	The declarations of a box property, like `padding`, for the edges: the shorthand for all edges, `padding-inline` and `padding-block` for an axis, and a property for each other edge. The leading and trailing edges follow the writing direction.
	*/
	func declarations(_ value: CSSValue, property: BoxProperty) -> [Declaration] {
		if self == .all {
			return [Declaration(property: property.property, value: value)]
		}

		var declarations = [Declaration]()

		if isSuperset(of: .vertical) {
			declarations.append(Declaration(property: Property("\(property.rawValue)-block"), value: value))
		} else {
			for (edge, name) in [(Self.top, "top"), (.bottom, "bottom")] where contains(edge) {
				declarations.append(Declaration(property: Property("\(property.rawValue)-\(name)"), value: value))
			}
		}

		if isSuperset(of: .horizontal) {
			declarations.append(Declaration(property: Property("\(property.rawValue)-inline"), value: value))
		} else {
			for (edge, name) in [(Self.leading, "inline-start"), (.trailing, "inline-end")] where contains(edge) {
				declarations.append(Declaration(property: Property("\(property.rawValue)-\(name)"), value: value))
			}
		}

		return declarations
	}
}
