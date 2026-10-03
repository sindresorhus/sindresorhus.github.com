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
	A background image, like a gradient from ``CSSValue/linearGradient(_:_:in:)``.
	*/
	public func backgroundImage(_ image: CSSValue) -> Self {
		declaration(.backgroundImage, image)
	}

	public func border(_ color: Color = .currentColor, width: Length = .px(1)) -> Self {
		declaration(.border, CSSValue("\(width) solid \(color)"))
	}

	public func border(_ edges: Edge.Set, _ color: Color = .currentColor, width: Length = .px(1)) -> Self {
		declarations(edges.declarations(CSSValue("\(width) solid \(color)"), property: "border"))
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
	A focus ring: a transparent outline, which stays visible in forced colors mode, and a ring in the color.
	*/
	public func focusRing(_ color: Color, width: Length = .px(4)) -> Self {
		declaration(.outline, "2px solid transparent")
			.shadow(.ring(width, color))
	}

	public func opacity(_ opacity: Double) -> Self {
		declaration(.opacity, CSSValue(floatLiteral: opacity))
	}

	public func cursor(_ cursor: Cursor) -> Self {
		declaration(.cursor, CSSValue(cursor.rawValue))
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
	Blurs the element, like SwiftUI's `blur(radius:)`.
	*/
	public func blur(radius: Length) -> Self {
		filter("blur(\(radius))")
	}

	/**
	Brightens (above 1) or darkens (below 1) the element, like SwiftUI's `brightness(_:)`, but with 1 as no change, as in CSS.
	*/
	public func brightness(_ amount: Double) -> Self {
		filter("brightness(\(CSSValue(floatLiteral: amount)))")
	}

	/**
	A shadow that follows the shape of the content, like transparent parts of an image.
	*/
	public func dropShadow(_ shadow: Shadow) -> Self {
		filter("drop-shadow(\(shadow.x) \(shadow.y) \(shadow.blur) \(shadow.color))")
	}

	/**
	A filter function, like `saturate(150%)`. Filters add up: `.blur(radius: .px(2)).brightness(1.1)` applies both.
	*/
	public func filter(_ function: String) -> Self {
		appending(function, to: .filter, separator: " ")
	}

	/**
	A filter for the area behind the element, like `blur(14px)` for frosted glass. Filters add up.
	*/
	public func backdropFilter(_ function: String) -> Self {
		appending(function, to: .backdropFilter, separator: " ")
	}

	/**
	Adds a value to the latest declaration of the property in this style, or sets the property.
	*/
	private func appending(_ value: String, to property: Property, separator: String) -> Self {
		// A previous `none`, like from `noTransition()`, is replaced, as `none` cannot be in a list.
		guard
			let index = declarations.lastIndex(where: { $0.property == property }),
			declarations[index].value.description != "none"
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
		.transition(.colors, duration: .milliseconds(150))
		.transition(.transform, duration: .milliseconds(300), curve: .easeOut)
	```
	*/
	public func transition(_ properties: TransitionProperty..., duration: Duration, curve: AnimationCurve? = nil) -> Self {
		properties
			.flatMap(\.properties)
			.map { [$0, duration.cssValue, curve?.description].compactMap(\.self).joined(separator: " ") }
			.reduce(self) { $0.appending($1, to: .transition, separator: ", ") }
	}

	/**
	Animates a property that switches between values, like `display` or `content-visibility`, so the element stays shown until the other transitions end.
	*/
	public func appendingDiscreteTransition(_ property: String, duration: Duration, curve: AnimationCurve? = nil) -> Self {
		appending([property, duration.cssValue, curve?.description, "allow-discrete"].compactMap(\.self).joined(separator: " "), to: .transition, separator: ", ")
	}

	/**
	Removes the transitions, like for reduced motion.
	*/
	public func noTransition() -> Self {
		declaration(.transition, .none)
	}

	/**
	Runs the keyframes.

	- Parameter repeats: Whether the animation repeats forever.
	- Parameter autoreverses: Whether every other run plays backwards.
	- Parameter fillMode: Whether the element keeps the styles of the first keyframe before the animation and of the last after it.
	*/
	public func animation(_ keyframes: some KeyframeSet, duration: Duration, curve: AnimationCurve? = nil, delay: CSSValue? = nil, repeats: Bool = false, autoreverses: Bool = false, fillMode: AnimationFillMode? = nil) -> Self {
		let parts = [
			keyframes.name,
			duration.cssValue,
			curve?.description,
			delay?.description,
			repeats ? "infinite" : nil,
			autoreverses ? "alternate" : nil,
			fillMode?.rawValue,
		]

		var style = declaration(.animation, CSSValue(parts.compactMap(\.self).joined(separator: " ")))
		style.definitions += [keyframes.node] + keyframes.definitions
		return style
	}

	/**
	Runs the keyframes as an element scrolls through the view instead of over time, like a header that changes when a section scrolls away.

	- Parameter timeline: The name of a view timeline, like `--hero`, from ``viewTimeline(_:)`` on the element that scrolls.
	- Parameter range: The part of the scrolling that runs the animation, like `exit 90% exit 100%`.
	*/
	public func animation(_ keyframes: some KeyframeSet, timeline: String, range: String) -> Self {
		var style = declaration(.animation, CSSValue("\(keyframes.name) linear both"))
			.declaration(.animationTimeline, CSSValue(timeline))
			.declaration(.animationRange, CSSValue(range))

		style.definitions += [keyframes.node] + keyframes.definitions
		return style
	}

	/**
	Names the progress of the element through the view, for scroll-driven animations of other elements. An ancestor of those elements needs the name in ``timelineScope(_:)``.
	*/
	public func viewTimeline(_ name: String) -> Self {
		declaration("view-timeline-name", CSSValue(name))
	}

	/**
	Makes a named timeline of a descendant available to all descendants, like a view timeline of a section for the header.
	*/
	public func timelineScope(_ name: String) -> Self {
		declaration("timeline-scope", CSSValue(name))
	}

	/**
	Stops the animations, like for reduced motion.
	*/
	public func noAnimation() -> Self {
		declaration(.animation, .none)
	}
}
