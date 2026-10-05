// MARK: Background, border, and shadow

extension Style {
	/**
	The background color.
	*/
	public func background(_ color: Color) -> Self {
		declaration(.backgroundColor, CSSValue(color))
	}

	/**
	The background color, with another color in dark mode.
	*/
	public func background(_ color: Color, dark: Color) -> Self {
		background(.lightDark(color, dark))
	}

	/**
	A background image, like a gradient from ``CSSValue/linearGradient(_:_:in:)``. Several images are layers, and the first one is on top.
	*/
	public func backgroundImage(_ image: CSSValue, _ moreImages: CSSValue...) -> Self {
		declaration(.backgroundImage, CSSValue(([image] + moreImages).map(\.description).joined(separator: ", ")))
	}

	/**
	Images that hide the element where they are transparent, like a radial gradient that fades the edges of a photo. Several images are layers, and the element shows where any of them is opaque.
	*/
	public func maskImage(_ image: CSSValue, _ moreImages: CSSValue...) -> Self {
		declaration(.maskImage, CSSValue(([image] + moreImages).map(\.description).joined(separator: ", ")))
	}

	/**
	What the background is drawn in, like `.text` for a gradient in the letters.
	*/
	public func backgroundClip(_ clip: BackgroundClip) -> Self {
		declaration(.backgroundClip, CSSValue(clip.rawValue))
	}

	/**
	A border around the element. A style like `.outset` draws a raised edge in shades of the color, like the windows and buttons of old operating systems.
	*/
	public func border(_ color: Color = .currentColor, width: Length = .pixels(1), style: BorderStyle = .solid) -> Self {
		declaration(.border, CSSValue("\(width) \(style.rawValue) \(color)"))
	}

	public func border(_ edges: Edge.Set, _ color: Color = .currentColor, width: Length = .pixels(1), style: BorderStyle = .solid) -> Self {
		declaration(.border, CSSValue("\(width) \(style.rawValue) \(color)"), edges: edges)
	}

	public func borderColor(_ color: Color) -> Self {
		declaration(.borderColor, CSSValue(color))
	}

	/**
	The border color, with another color in dark mode.
	*/
	public func borderColor(_ color: Color, dark: Color) -> Self {
		borderColor(.lightDark(color, dark))
	}

	public func cornerRadius(_ radius: Length) -> Self {
		declaration(.borderRadius, CSSValue(radius))
	}

	/**
	Clips the element to a rounded rectangle that is inset from its edges, like SwiftUI's `clipShape(_:)`. Unlike a corner radius, it also clips replaced content like images, and it can cut away the edges of the element.

	```swift
	Style().clipShape(inset: .percent(1.2), cornerRadius: .percent(22.5))
	```

	It also clips the filters of the element, like a drop shadow, so put a shadow on a parent.
	*/
	public func clipShape(inset: Length, cornerRadius: Length) -> Self {
		declaration(.clipPath, CSSValue("inset(\(inset) round \(cornerRadius))"))
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
	public func shadow(_ shadows: [Shadow]) -> Self {
		declaration(.boxShadow, CSSValue(shadows.isEmpty ? "none" : shadows.map(\.description).joined(separator: ", ")))
	}

	public func shadow(_ shadows: Shadow...) -> Self {
		shadow(shadows)
	}

	/**
	A focus ring: an outline in the color, which follows the corner radius. It is not a box shadow, so it does not replace the shadow of the element, and a hover shadow does not replace it. In forced colors mode, the browser draws it in a system color.

	- Parameter offset: The space between the ring and the border, like a negative offset to draw the ring over the border of a field.
	- Parameter style: The line of the ring, like `.dotted` for the focus rectangle of Windows 95.
	*/
	public func focusRing(_ color: Color, width: Length = .pixels(4), offset: Length? = nil, style lineStyle: BorderStyle = .solid) -> Self {
		outline(color, width: width, offset: offset, style: lineStyle)
	}

	/**
	An outline around the border of the element. It follows the corner radius and takes no space, so it does not move the content. For the focus of a control, use ``focusRing(_:width:offset:style:)``.

	- Parameter offset: The space between the outline and the border, like a negative offset to draw the outline inside the element.
	- Parameter style: The line of the outline, like `.dashed` for stitches.
	*/
	public func outline(_ color: Color = .currentColor, width: Length = .pixels(1), offset: Length? = nil, style lineStyle: BorderStyle = .solid) -> Self {
		let style = declaration(.outline, CSSValue("\(width) \(lineStyle.rawValue) \(color)"))

		guard let offset else {
			return style
		}

		return style.declaration(.outlineOffset, CSSValue(offset))
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
		declaration(.mixBlendMode, CSSValue(mode.rawValue))
	}

	public func opacity(_ opacity: Double) -> Self {
		declaration(.opacity, CSSValue(floatLiteral: opacity))
	}

	public func cursor(_ cursor: Cursor) -> Self {
		declaration(.cursor, CSSValue(cursor.rawValue))
	}

	/**
	An image as the mouse pointer, like an arrow in pixel art.

	- Parameters:
		- x: The horizontal position of the point of the pointer in the image, in pixels from the left.
		- y: The vertical position of the point of the pointer in the image, in pixels from the top.
		- fallback: The pointer while the image loads, or when it cannot be used.
	*/
	public func cursor(_ image: RoutePath, x: Int = 0, y: Int = 0, fallback: Cursor = .auto) -> Self {
		declaration(.cursor, CSSValue("\(CSSValue.url(image)) \(x) \(y), \(fallback.rawValue)"))
	}

	/**
	The colors of the scroll bars of the element, for browsers without ``scrollbar(_:_:)``, like Firefox. Browsers with both use these colors instead of the parts, so put it in `.supports(!.webKitScrollbar)` to use the parts where they work.
	*/
	public func scrollbarColor(thumb: Color, track: Color) -> Self {
		declaration(.scrollbarColor, CSSValue("\(thumb) \(track)"))
	}

	/**
	Styles for a part of the scroll bars of the element, like the thumb, in Chrome and Safari. For the scroll bars of the page, style the root element, like with ``onPageRoot(_:)``.
	*/
	public func scrollbar(_ part: ScrollbarPart, _ content: (Self) -> Self) -> Self {
		nested("&\(part.rawValue)", content)
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
		declaration(.touchAction, CSSValue(action.rawValue))
	}

	/**
	How the image or the canvas is scaled, like `.pixelated` for pixel art that is shown larger than its size.
	*/
	public func imageRendering(_ rendering: ImageRendering) -> Self {
		declaration(.imageRendering, CSSValue(rendering.rawValue))
	}

	/**
	The color schemes that the element supports, which the browser uses for its controls and scroll bars, and to pick the colors of `light-dark()`. Like `.dark` for a code block that is light on dark in both modes.
	*/
	public func colorScheme(_ scheme: ColorScheme) -> Self {
		declaration(.colorScheme, CSSValue(scheme.rawValue))
	}

	/**
	The color of the native controls, like check boxes, radio buttons, sliders, and progress bars, instead of the system color.
	*/
	public func accentColor(_ color: Color) -> Self {
		declaration(.accentColor, CSSValue(color))
	}

	/**
	How a form field is sized, like `.content` for a text area that grows with its text.
	*/
	public func fieldSizing(_ sizing: FieldSizing) -> Self {
		declaration(.fieldSizing, CSSValue(sizing.rawValue))
	}
}

// MARK: Effects

extension Style {
	/**
	Scales the element from its center, like SwiftUI's `scaleEffect(_:)`.
	*/
	public func scaleEffect(_ scale: Double) -> Self {
		declaration(.scale, CSSValue(floatLiteral: scale))
	}

	/**
	Moves the element without affecting the layout, like SwiftUI's `offset(x:y:)`.
	*/
	public func offset(x: Length = 0, y: Length = 0) -> Self {
		declaration(.translate, y == 0 ? CSSValue(x) : [CSSValue(x), CSSValue(y)])
	}

	/**
	Rotates the element around its center, like SwiftUI's `rotationEffect(_:)`.
	*/
	public func rotationEffect(_ angle: Angle) -> Self {
		declaration(.rotate, CSSValue(angle.description))
	}

	/**
	A transform, for what the effect modifiers cannot express, like a 3D rotation.
	*/
	public func transform(_ value: CSSValue) -> Self {
		declaration(.transform, value)
	}

	/**
	Filters for the element, applied in order, like `.filter(.blur(radius: .pixels(2)), .brightness(1.1))`. Use `.filter(.none)` to remove them.
	*/
	public func filter(_ filter: Filter, _ moreFilters: Filter...) -> Self {
		declaration(.filter, CSSValue(([filter] + moreFilters).map(\.description).joined(separator: " ")))
	}

	/**
	Filters for the area behind the element, like `.backdropFilter(.blur(radius: .pixels(14)))` for frosted glass. Use `.backdropFilter(.none)` to remove them.
	*/
	public func backdropFilter(_ filter: Filter, _ moreFilters: Filter...) -> Self {
		declaration(.backdropFilter, CSSValue(([filter] + moreFilters).map(\.description).joined(separator: " ")))
	}

	/**
	Adds a value to the latest declaration of the property in this style, or sets the property.
	*/
	private func appending(_ value: String, to property: Property, separator: String) -> Self {
		// A previous `none`, like from `noTransition()`, is replaced, as `none` cannot be in a list. An important value cannot be in a list either, so the value is a declaration of its own, and the important one still wins.
		guard
			let index = declarations.lastIndex(where: { $0.property == property }),
			declarations[index].value.description != "none",
			!declarations[index].value.description.hasSuffix("!important")
		else {
			return declaration(property, CSSValue(value))
		}

		var copy = self
		copy.declarations[index] = Declaration(property: property, value: CSSValue("\(declarations[index].value)\(separator)\(value)"))
		return copy
	}
}

// MARK: Transitions and animations

extension Style {
	/**
	Animates changes of the properties. Transitions add up, so properties can have different durations:

	```swift
	Style()
		.transition(.colors, animation: .default(duration: .milliseconds(150)))
		.transition(.scaleEffect, animation: .easeOut(duration: .milliseconds(300)))
	```
	*/
	public func transition(_ properties: TransitionProperty..., animation: Animation) -> Self {
		precondition(!animation.repeatsForever, "A transition runs once.")

		var style = self

		for property in properties {
			for name in property.properties {
				let transition = "\(name) \(animation.timing)" + (property.isDiscrete ? " allow-discrete" : "")
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
	Runs the keyframes, like `.animation(Animations.spin, .linear(duration: .seconds(1)).repeatForever(autoreverses: false))`.

	- Parameter fillMode: Whether the element keeps the styles of the first keyframe before the animation and of the last after it.
	*/
	public func animation(_ keyframes: some KeyframeSet, _ animation: Animation, fillMode: AnimationFillMode? = nil) -> Self {
		let parts = [
			keyframes.name,
			animation.timing,
			animation.repeatsForever ? "infinite" : nil,
			animation.autoreverses ? "alternate" : nil,
			fillMode?.rawValue,
		]

		var style = declaration(.animation, CSSValue(parts.compactMap(\.self).joined(separator: " ")))
		style.definitions += [keyframes.node] + keyframes.definitions
		return style
	}

	/**
	Runs the keyframes as the page scrolls instead of over time, like a header that changes when a section scrolls away. A ``AnimationTimeline/view(_:)`` timeline is named with ``viewTimeline(_:)`` on the element that scrolls through the view, and a shared ancestor makes it available with ``timelineScope(_:)``.

	- Parameter range: The part of the scrolling that runs the animation, like `exit 90% exit 100%`.
	*/
	public func animation(_ keyframes: some KeyframeSet, timeline: AnimationTimeline, range: String) -> Self {
		var style = declaration(.animation, CSSValue("\(keyframes.name) linear both"))
			.declaration(.animationTimeline, CSSValue(timeline.description))
			.declaration(.animationRange, CSSValue(range))

		style.definitions += [keyframes.node] + keyframes.definitions
		return style
	}

	/**
	Names the progress of the element through the view, for scroll-driven animations of other elements. An ancestor of those elements needs the timeline in ``timelineScope(_:)``.
	*/
	public func viewTimeline(_ timeline: ViewTimeline) -> Self {
		declaration(.viewTimelineName, CSSValue(timeline.name))
	}

	/**
	Makes a view timeline of a descendant available to all descendants, like a view timeline of a section for the header.
	*/
	public func timelineScope(_ timeline: ViewTimeline) -> Self {
		declaration(.timelineScope, CSSValue(timeline.name))
	}

	/**
	Stops the animations, like for reduced motion.
	*/
	public func noAnimation() -> Self {
		declaration(.animation, .none)
	}
}
