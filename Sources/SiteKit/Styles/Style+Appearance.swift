// MARK: Background, border, and shadow

extension Style {
	/**
	The background color.
	*/
	public func background(_ color: Color) -> Self {
		declaration(.backgroundColor, color)
	}

	/**
	The background color, with another color in dark mode.
	*/
	public func background(_ color: Color, dark: Color) -> Self {
		background(.lightDark(color, dark))
	}

	/**
	A background image, like a gradient from ``CSSImage/linearGradient(_:_:_:_:in:)``. Several images are layers, and the first one is on top.
	*/
	public func backgroundImage(_ image: CSSImage, _ moreImages: CSSImage...) -> Self {
		declaration(.backgroundImage, CSSValue([image] + moreImages, separator: ", "))
	}

	/**
	A background image, with another image in dark mode, by the color scheme of the element (`light-dark()` in CSS), like a gradient that is stronger on a dark card.
	*/
	public func backgroundImage(_ image: CSSImage, dark: CSSImage) -> Self {
		declaration(.backgroundImage, CSSValue(raw: "light-dark(\(image), \(dark))"))
	}

	/**
	The size of each background image tile.
	*/
	public func backgroundSize(width: LengthPercentage, height: LengthPercentage) -> Self {
		backgroundSize(.dimensions(width: .length(width), height: .length(height)))
	}

	/**
	The background image size, including `cover`, `contain`, and automatic dimensions.
	*/
	public func backgroundSize(_ size: ImageSize) -> Self {
		declaration(.backgroundSize, CSSValue(raw: size.description))
	}

	/**
	Images that hide the element where they are transparent, like a radial gradient that fades the edges of a photo. Several images are layers, and the element shows where any of them is opaque.
	*/
	public func maskImage(_ image: CSSImage, _ moreImages: CSSImage...) -> Self {
		declaration(.maskImage, CSSValue([image] + moreImages, separator: ", "))
	}

	/**
	The size of each tile of the mask images.
	*/
	public func maskSize(width: LengthPercentage, height: LengthPercentage) -> Self {
		maskSize(.dimensions(width: .length(width), height: .length(height)))
	}

	/**
	The mask image size, including `cover`, `contain`, and automatic dimensions.
	*/
	public func maskSize(_ size: ImageSize) -> Self {
		declaration(.maskSize, CSSValue(raw: size.description))
	}

	/**
	Draws the SVG shapes inside with lines only, like line icons: no fill, and lines in the color, with these ends and corners (`fill`, `stroke`, `stroke-linecap`, and `stroke-linejoin` in CSS). The shapes inherit it, and a shape with its own `fill` or `stroke` attribute keeps it.
	*/
	public func strokedShapes(_ color: Color = .currentColor, lineCap: LineCap = .round, lineJoin: LineJoin = .round) -> Self {
		declaration(.fill, CSSValue.none)
			.declaration(.stroke, color)
			.declaration(.strokeLinecap, lineCap)
			.declaration(.strokeLinejoin, lineJoin)
	}

	/**
	Whether forced colors, like Windows High Contrast, change the colors of the element, like `.none` for a background that draws a shape, which forced colors would remove.
	*/
	public func forcedColorAdjust(_ value: ForcedColorAdjust) -> Self {
		declaration(.forcedColorAdjust, value)
	}

	/**
	How the mask images repeat, like `.space` for a row of shapes with even gaps.
	*/
	public func maskRepeat(_ repeat: ImageRepeat) -> Self {
		declaration(.maskRepeat, `repeat`)
	}

	/**
	What the background is drawn in, like `.text` for a gradient in the letters.
	*/
	public func backgroundClip(_ clip: BackgroundClip) -> Self {
		declaration(.backgroundClip, clip)
	}

	/**
	A border around the element. A style like `.outset` draws a raised edge in shades of the color, like the windows and buttons of old operating systems.
	*/
	public func border(_ color: Color = .currentColor, width: Length = .pixels(1), style: BorderStyle = .solid) -> Self {
		border(
			.all,
			color,
			width: width,
			style: style
		)
	}

	public func border(
		_ edges: Edge.Set,
		_ color: Color = .currentColor,
		width: Length = .pixels(1),
		style: BorderStyle = .solid
	) -> Self {
		declaration(.border, .line(color, width: width, style: style), edges: edges)
	}

	public func borderColor(_ color: Color) -> Self {
		declaration(.borderColor, color)
	}

	/**
	The border color, with another color in dark mode.
	*/
	public func borderColor(_ color: Color, dark: Color) -> Self {
		borderColor(.lightDark(color, dark))
	}

	/**
	Whether the borders of adjacent table cells merge.
	*/
	public func borderCollapse(_ value: BorderCollapse) -> Self {
		declaration(.borderCollapse, value)
	}

	public func cornerRadius(_ radius: LengthPercentage) -> Self {
		declaration(.borderRadius, radius)
	}

	/**
	Clips the element to a rounded rectangle that is inset from its edges, like SwiftUI's `clipShape(_:)`. Unlike a corner radius, it also clips replaced content like images, and it can cut away the edges of the element.

	```swift
	Style().clipShape(inset: .percent(1.2), cornerRadius: .percent(22.5))
	```

	It also clips the filters of the element, like a drop shadow, so put a shadow on a parent.
	*/
	public func clipShape(inset: LengthPercentage, cornerRadius: LengthPercentage) -> Self {
		declaration(.clipPath, CSSValue(raw: "inset(\(inset) round \(cornerRadius))"))
	}

	/**
	Rounds the corners into a shape, like SwiftUI's `.capsule` and `.circle`.
	*/
	public func cornerRadius(_ shape: RoundedShape) -> Self {
		cornerRadius(shape.radius)
	}

	/**
	Box shadows, drawn from the first to the last. No shadows removes them.
	*/
	public func shadow(_ shadows: [BoxShadow]) -> Self {
		declaration(.boxShadow, CSSValue(shadows, separator: ", ", emptyValue: .none))
	}

	public func shadow(_ shadows: BoxShadow...) -> Self {
		shadow(shadows)
	}

	/**
	A focus ring: an outline in the color, which follows the corner radius. It is not a box shadow, so it does not replace the shadow of the element, and a hover shadow does not replace it. In forced colors mode, the browser draws it in a system color.

	- Parameter offset: The space between the ring and the border, like a negative offset to draw the ring over the border of a field.
	- Parameter style: The line of the ring, like `.dotted` for the focus rectangle of Windows 95.
	*/
	public func focusRing(
		_ color: Color,
		width: Length = .pixels(4),
		offset: Length? = nil,
		style lineStyle: BorderStyle = .solid
	) -> Self {
		outline(
			color,
			width: width,
			offset: offset,
			style: lineStyle
		)
	}

	/**
	An outline around the border of the element. It follows the corner radius and takes no space, so it does not move the content. For the focus of a control, use ``focusRing(_:width:offset:style:)``.

	- Parameter offset: The space between the outline and the border, like a negative offset to draw the outline inside the element.
	- Parameter style: The line of the outline, like `.dashed` for stitches.
	*/
	public func outline(
		_ color: Color = .currentColor,
		width: Length = .pixels(1),
		offset: Length? = nil,
		style lineStyle: BorderStyle = .solid
	) -> Self {
		declaration(.outline, .line(color, width: width, style: lineStyle))
			.declaration(.outlineOffset, ifPresent: offset)
	}

	/**
	Removes the outline, like the focus ring of the browser on an element that shows its focus in another way.
	*/
	public func noOutline() -> Self {
		declaration(.outline, .none)
	}

	/**
	How the element blends with what is behind it, like `.darken` to drop a white background of an image on a light surface, like SwiftUI's `blendMode(_:)`.
	*/
	public func blendMode(_ mode: BlendMode) -> Self {
		declaration(.mixBlendMode, mode)
	}

	public func opacity(_ opacity: CSSNumber) -> Self {
		declaration(.opacity, opacity)
	}

	public func cursor(_ cursor: Cursor) -> Self {
		declaration(.cursor, cursor)
	}

	/**
	An image as the mouse pointer, like an arrow in pixel art.

	- Parameters:
		- x: The horizontal position of the point of the pointer in the image, in pixels from the left.
		- y: The vertical position of the point of the pointer in the image, in pixels from the top.
		- fallback: The pointer while the image loads, or when it cannot be used.
	*/
	public func cursor(
		_ image: RoutePath,
		x: Int = 0,
		y: Int = 0,
		fallback: Cursor = .auto
	) -> Self {
		declaration(.cursor, CSSValue(raw: "\(CSSValue.url(image)) \(x) \(y), \(fallback.rawValue)"))
	}

	/**
	The colors of the scroll bars of the element, for browsers without ``scrollbar(_:_:)``, like Firefox. Browsers with both use these colors instead of the parts, so put it in `.supports(!.webKitScrollbar)` to use the parts where they work.
	*/
	public func scrollbarColor(thumb: Color, track: Color) -> Self {
		declaration(.scrollbarColor, CSSValue(raw: "\(thumb) \(track)"))
	}

	/**
	Styles for a part of the scroll bars of the element, like the thumb, in Chrome and Safari. For the scroll bars of the page, style the root element, like with ``onPageRoot(_:)``.
	*/
	public func scrollbar(_ part: ScrollbarPart, _ content: (Self) -> Self) -> Self {
		nested("&\(raw: part.rawValue)", content)
	}

	/**
	Whether the element receives clicks, like SwiftUI's `allowsHitTesting(_:)`. Clicks on an element that does not, go to the elements below.
	*/
	public func allowsHitTesting(_ isAllowed: Bool) -> Self {
		declaration(.pointerEvents, isAllowed ? .auto : .none)
	}

	public func visibility(_ isVisible: Bool) -> Self {
		declaration(.visibility, isVisible ? "visible" : "hidden")
	}

	/**
	What a touch on the element does by default, like `.none` for a canvas that the visitor draws on with a finger, so the page does not scroll instead.
	*/
	public func touchAction(_ action: TouchAction) -> Self {
		declaration(.touchAction, action)
	}

	/**
	How the image or the canvas is scaled, like `.pixelated` for pixel art that is shown larger than its size.
	*/
	public func imageRendering(_ rendering: ImageRendering) -> Self {
		declaration(.imageRendering, rendering)
	}

	/**
	The color schemes that the element supports, which the browser uses for its controls and scroll bars, and to pick the colors of `light-dark()`. Like `.dark` for a code block that is light on dark in both modes.
	*/
	public func colorScheme(_ scheme: ColorScheme) -> Self {
		declaration(.colorScheme, scheme)
	}

	/**
	The color of the native controls, like check boxes, radio buttons, sliders, and progress bars, instead of the system color.
	*/
	public func accentColor(_ color: Color) -> Self {
		declaration(.accentColor, color)
	}

	/**
	How a form field is sized, like `.content` for a text area that grows with its text.
	*/
	public func fieldSizing(_ sizing: FieldSizing) -> Self {
		declaration(.fieldSizing, sizing)
	}
}

// MARK: Effects

extension Style {
	/**
	Scales the element from its center, like SwiftUI's `scaleEffect(_:)`.
	*/
	public func scaleEffect(_ scale: CSSNumber) -> Self {
		declaration(.scale, scale)
	}

	/**
	Scales each axis independently, like `.scaleEffect(x: -1, y: 1)` to mirror an element horizontally.
	*/
	public func scaleEffect(x: CSSNumber, y: CSSNumber) -> Self {
		declaration(.scale, [CSSValue(x), CSSValue(y)])
	}

	/**
	Moves the element without affecting the layout, like SwiftUI's `offset(x:y:)`.
	*/
	public func offset(x: LengthPercentage = .zero, y: LengthPercentage = .zero) -> Self {
		declaration(.translate, y == .zero ? CSSValue(x) : [CSSValue(x), CSSValue(y)])
	}

	/**
	Rotates the element around its center, like SwiftUI's `rotationEffect(_:)`.
	*/
	public func rotationEffect(_ angle: Angle) -> Self {
		declaration(.rotate, angle)
	}

	/**
	A transform function that the code builds itself, for what the typed transforms cannot express, like a `matrix`.
	*/
	public func transform(raw value: CSSValue) -> Self {
		declaration(.transform, value)
	}

	/**
	Transform functions applied in their written order. An empty list resets the transform.
	*/
	public func transform(_ transforms: Transform...) -> Self {
		transform(transforms)
	}

	/**
	An ordered list of transform functions, or `none` when the list is empty.
	*/
	public func transform(_ transforms: [Transform]) -> Self {
		declaration(.transform, CSSValue(transforms, separator: " ", emptyValue: .none))
	}

	/**
	Whether transformed children remain in three dimensions.
	*/
	public func transformStyle(_ value: TransformStyle) -> Self {
		declaration(.transformStyle, value)
	}

	/**
	The origin of transforms, with an optional length-only depth.
	*/
	public func transformOrigin(_ position: CSSPosition, depth: Length? = nil) -> Self {
		declaration(.transformOrigin, CSSValue(raw: position.description + (depth.map { " \($0)" } ?? "")))
	}

	/**
	The two-dimensional position of the background image.
	*/
	public func backgroundPosition(_ position: CSSPosition) -> Self {
		declaration(.backgroundPosition, CSSValue(raw: position.description))
	}

	/**
	The distance from the viewer to a three-dimensional scene (`perspective` in CSS).
	*/
	public func perspective(_ distance: Length) -> Self {
		declaration(.perspective, distance)
	}

	/**
	Filters for the element, applied in order, like `.filter(.blur(radius: .pixels(2)), .brightness(1.1))`. Passing no filters removes them.
	*/
	public func filter(_ filters: Filter...) -> Self {
		filter(filters)
	}

	/**
	Filters from a list, like a drop shadow that an element always has and the brightness of a state. An empty list removes them.
	*/
	public func filter(_ filters: [Filter]) -> Self {
		declaration(.filter, CSSValue(filters, separator: " ", emptyValue: .none))
	}

	/**
	Filters for the area behind the element, like `.backdropFilter(.blur(radius: .pixels(14)))` for frosted glass. Passing no filters removes them.
	*/
	public func backdropFilter(_ filters: Filter...) -> Self {
		backdropFilter(filters)
	}

	/**
	Filters for the area behind the element from a list. An empty list removes them.
	*/
	public func backdropFilter(_ filters: [Filter]) -> Self {
		declaration(.backdropFilter, CSSValue(filters, separator: " ", emptyValue: .none))
	}

	/**
	Adds a value to the latest declaration of the property in this style, or sets the property.
	*/
	private func appending(_ value: String, to property: Property, separator: String) -> Self {
		// A previous `none`, like from `noTransition()`, is replaced, as `none` cannot be in a list. An important value cannot be in a list either, so the value is a declaration of its own, and the important one still wins.
		guard
			let index = declarations.lastIndex(where: { $0.property == property }),
			declarations[index].value != .none,
			!declarations[index].isImportant
		else {
			return declaration(property, CSSValue(raw: value))
		}

		var copy = self
		copy.declarations[index] = Declaration(property: property, value: CSSValue(raw: "\(declarations[index].value)\(separator)\(value)"))
		return copy
	}
}

// MARK: Transitions and animations

extension Style {
	/**
	Whether transitions and animations can go to and from size keywords, like `auto`, so the content of a `<details>` element can open smoothly. It is inherited, so it is set on the root.
	*/
	public func interpolateSize(_ interpolation: SizeInterpolation) -> Self {
		declaration(.interpolateSize, interpolation)
	}

	/**
	Animates changes of the properties. Transitions add up, so properties can have different durations:

	```swift
	Style()
		.transition(.colors, timing: .default(duration: .milliseconds(150)))
		.transition(.scaleEffect, timing: .easeOut(duration: .milliseconds(300)))
	```
	*/
	public func transition(_ properties: TransitionProperty..., timing: AnimationTiming) -> Self {
		var style = self

		for property in properties {
			if let registration = property.registration {
				style.definitions.append(registration.node)
			}

			for name in property.properties {
				let transition = "\(name) \(timing)" + (property.isDiscrete ? " allow-discrete" : "")
				style = style.appending(transition, to: .transition, separator: ", ")
			}
		}

		return style
	}

	/**
	Removes the transitions, like for reduced motion.
	*/
	public func noTransition() -> Self {
		declaration(.transition, .none)
	}

	/**
	The properties expected to change soon (`will-change`), like `.willChange(.transform)`. An empty list restores `auto`. Use only for an observed performance need, as preparing many elements can consume more resources.
	*/
	public func willChange(_ properties: Property...) -> Self {
		declaration(.willChange, CSSValue(properties, separator: ", ", emptyValue: .auto))
	}

	/**
	The delay before an animation starts. A negative delay starts partway through the animation.
	*/
	public func animationDelay(_ delay: Duration) -> Self {
		declaration(.animationDelay, CSSValue(raw: delay.cssValue))
	}

	/**
	A time multiplied by a number-valued expression, like `.animationDelay(.milliseconds(100), multipliedBy: .siblingIndex - 2)` for elements that appear one after another. Set it after the animation shorthand, in the same media query.
	*/
	public func animationDelay(_ delay: Duration, multipliedBy multiplier: CSSNumber) -> Self {
		declaration(.animationDelay, CSSValue(raw: "calc(\(multiplier) * \(delay.cssValue))"))
	}

	/**
	Runs the keyframes, like `.animation(Animations.spin, .linear(duration: .seconds(1)).repeatForever(autoreverses: false))`.

	The animation only runs for visitors who allow motion: it is written in `@media (prefers-reduced-motion: no-preference)` (``MediaCondition/allowsMotion``). With reduced motion, the element shows its style without the animation, which must be its still frame, like the end of a fade in. Hide a decoration that only makes sense while it moves with `.reducedMotion { $0.hidden() }`. See “Motion” in `AGENTS.md`.

	The media query comes after the declarations of the style, so the `animation` shorthand in it resets longhands like `animation-delay` that the style sets. Set them in `.media(.allowsMotion)` after the animation.

	- Parameter fillMode: Whether the element keeps the styles of the first keyframe before the animation and of the last after it.
	- Parameter isEssential: Whether the animation also runs with reduced motion, as it carries meaning and hardly moves, like the highlight of the section that a link points to.
	*/
	public func animation(
		_ keyframes: some KeyframeSet,
		_ animation: Animation,
		fillMode: AnimationFillMode? = nil,
		isEssential: Bool = false
	) -> Self {
		let value = animation.cssValue(name: keyframes.name, fillMode: fillMode)

		var style = if isEssential {
			declaration(.animation, value)
		} else {
			media(.allowsMotion) {
				$0.declaration(.animation, value)
			}
		}

		style.definitions += keyframes.nodes
		return style
	}

	/**
	Runs the keyframes as the page scrolls instead of over time, like a header that changes when a section scrolls away. A ``AnimationTimeline/view(_:)`` timeline is named with ``viewTimeline(_:)`` on the element that scrolls through the view, and a shared ancestor makes it available with ``timelineScope(_:)``.

	It also runs with reduced motion, as it follows the scrolling of the visitor instead of moving by itself.

	- Parameters:
		- start: The offset where the animation starts.
		- end: The offset where the animation ends.
	*/
	public func animation(_ keyframes: some KeyframeSet, timeline: AnimationTimeline, from start: LengthPercentage, to end: LengthPercentage) -> Self {
		animation(keyframes, timeline: timeline, rawRange: "\(start) \(end)")
	}

	/**
	An animation between named boundaries of a view timeline, like `from: .entry(.percent(10)), to: .exit(.percent(90))`. Scroll-progress timelines use the overload with plain length or percentage offsets.
	*/
	public func animation(_ keyframes: some KeyframeSet, viewTimeline timeline: ViewTimeline, from start: AnimationRangeBoundary, to end: AnimationRangeBoundary) -> Self {
		animation(keyframes, timeline: .view(timeline), rawRange: "\(start) \(end)")
	}

	/**
	A scroll-driven animation with an explicit unchecked CSS attachment range, for named ranges and other forms beyond plain offsets.
	*/
	public func animation(_ keyframes: some KeyframeSet, timeline: AnimationTimeline, rawRange: String) -> Self {
		var style = declaration(.animation, CSSValue(raw: "\(keyframes.name) linear both"))
			.declaration(.animationTimeline, CSSValue(raw: timeline.description))
			.declaration(.animationRange, CSSValue(raw: rawRange))

		style.definitions += keyframes.nodes
		return style
	}

	/**
	Names the progress of the element through the view, for scroll-driven animations of other elements. An ancestor of those elements needs the timeline in ``timelineScope(_:)``.
	*/
	public func viewTimeline(_ timeline: ViewTimeline) -> Self {
		declaration(.viewTimelineName, CSSValue(raw: timeline.name.description))
	}

	/**
	Makes a view timeline of a descendant available to all descendants, like a view timeline of a section for the header.
	*/
	public func timelineScope(_ timeline: ViewTimeline) -> Self {
		declaration(.timelineScope, CSSValue(raw: timeline.name.description))
	}

	/**
	Stops the animations, like the animation of a shared style in one case. Reduced motion does not need it, as ``animation(_:_:fillMode:isEssential:)`` only runs for visitors who allow motion.

	Use it in a condition, like `.when(States.paused) { $0.noAnimation() }`, or in a later rule. In the style that runs the animation, the animation wins, as its media query comes after the declarations.
	*/
	public func noAnimation() -> Self {
		declaration(.animation, .none)
	}
}

extension CSSValue {
	/**
	A line of a border or an outline, like `1px solid red`.
	*/
	fileprivate static func line(_ color: Color, width: Length, style: BorderStyle) -> Self {
		Self(raw: "\(width) \(style.rawValue) \(color)")
	}
}
