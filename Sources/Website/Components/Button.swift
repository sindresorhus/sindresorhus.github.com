import Elementary
import SiteKit

/**
A link that looks like a button, with white text on a fill.

```swift
Button(destination: "/apps", fill: .gradient) {
	Label("Another Random App", icon: .shuffle)
}
```
*/
struct Button<Content: HTML>: HTML {
	enum Fill: Sendable {
		/**
		The brand blue, for the main action, like downloading an app.
		*/
		case primary

		/**
		Near black, for a neutral action, like going back to the home page.
		*/
		case dark

		/**
		The blue to pink gradient of the site.
		*/
		case gradient
	}

	enum Size: Sendable {
		/**
		For a bar, like the header.
		*/
		case small

		case regular

		/**
		Like the App Store badge, for download links.
		*/
		case large
	}

	let destination: String
	var fill = Fill.primary
	var size = Size.regular
	let content: Content

	init(destination: String, fill: Fill = .primary, size: Size = .regular, @HTMLBuilder content: () -> Content) {
		self.destination = destination
		self.fill = fill
		self.size = size
		self.content = content()
	}

	var body: some HTML<HTMLTag.a> {
		a(.href(destination)) {
			content
		}
		.style(ButtonStyles.root, fill.style, size.style)
	}
}

extension Button where Content == HTMLText {
	init(_ title: String, destination: String, fill: Fill = .primary, size: Size = .regular) {
		self.init(destination: destination, fill: fill, size: size) {
			HTMLText(title)
		}
	}
}

extension Button.Fill {
	fileprivate var style: ButtonStyles {
		switch self {
		case .primary:
			.primary
		case .dark:
			.dark
		case .gradient:
			.gradient
		}
	}
}

extension Button.Size {
	fileprivate var style: ButtonStyles {
		switch self {
		case .small:
			.small
		case .regular:
			.regular
		case .large:
			.large
		}
	}
}

/**
The styles of ``Button``, outside the generic type, so the class names are the same for every content type. They are one style set, so a fill or size always wins over the base. They set no margins, so the parent places the button.
*/
enum ButtonStyles: StyleSet {
	case root
	case primary
	case dark
	case gradient
	case small
	case regular
	case large

	var style: Style {
		switch self {
		case .root:
			Style()
				.display(.inlineFlex)
				.alignItems(.center)
				.justifyContent(.center)
				.gap(.rem(0.5))
				.cornerRadius(.capsule)
				.textAlign(.center)
				.noWrap()
				.color(.white)
				.transition(.backgroundColor, .shadow, duration: .milliseconds(150))
				.focusVisible {
					$0.focusRing(.primary(300))
				}
		case .primary:
			Style()
				.background(.primary(700))
				.hover {
					$0.background(.primary(700).lighter(0.06))
				}
		case .dark:
			Style()
				.background(.gray(900), dark: .gray(700))
				.shadow(.large)
				.hover {
					$0.background(.gray(800))
				}
		case .gradient:
			Style()
				.backgroundImage(.brandGradient)
				.shadow(Shadow(y: .px(1), blur: .px(2), color: .black.opacity(0.05)))
				.hover {
					$0
						.backgroundImage(.brandGradientHover)
						.shadow(.medium)
				}
		case .small:
			Style()
				.padding(vertical: .rem(0.5), horizontal: .rem(1.25))
				.font(.sm, weight: .bold)
		case .regular:
			Style()
				.padding(vertical: .rem(0.625), horizontal: .rem(1.25))
				.fontWeight(.semibold)
				.lineHeight(1.375)
		case .large:
			// Like the App Store badge next to it, it grows a little under the pointer.
			Style()
				.frame(width: .px(180), height: .px(60))
				.padding(vertical: .rem(1), horizontal: .rem(2.5))
				.cornerRadius(.rem(0.5))
				.font(.xl, weight: .bold)
				.transition(.backgroundColor, .transform, .filter, duration: .milliseconds(200))
				.hover {
					$0
						.brightness(1.1)
						.scaleEffect(1.05)
				}
				.active {
					$0
						.brightness(0.95)
						.scaleEffect(0.97)
				}
		}
	}
}
