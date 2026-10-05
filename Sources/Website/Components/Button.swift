import Elementary
import SiteKit

extension HTML where Tag == HTMLTag.a {
	/**
	Makes the link look like a button, with white text on a fill. It sets no margins, so the parent places it.

	```swift
	Link(destination: .path(.randomApp)) {
		Label("Another Random App", icon: .shuffle)
	}
	.buttonStyle(.gradient)
	```
	*/
	func buttonStyle(_ fill: ButtonStyles.Fill = .primary, size: ButtonStyles.Size = .regular) -> _AttributedContent<Self> {
		style(ButtonStyles.root, fill.style, size.style)
	}
}

extension HTML where Tag == HTMLTag.button {
	/**
	Makes the button look like the button links, like the submit button of a form. It sets no margins, so the parent places it.
	*/
	func buttonStyle(_ fill: ButtonStyles.Fill = .primary, size: ButtonStyles.Size = .regular) -> _AttributedContent<Self> {
		style(ButtonStyles.root, fill.style, size.style)
	}
}

extension ButtonStyles {
	enum Fill: CaseIterable {
		/**
		The brand blue, for the main action, like downloading an app.
		*/
		case primary

		/**
		A light tint of the brand blue with blue text, for an action next to the main one, like a free trial.
		*/
		case secondary

		/**
		Near black, for a neutral action, like going back to the home page.
		*/
		case dark

		/**
		The blue to pink gradient of the site.
		*/
		case gradient

		fileprivate var style: ButtonStyles {
			switch self {
			case .primary:
				.primary
			case .secondary:
				.secondary
			case .dark:
				.dark
			case .gradient:
				.gradient
			}
		}
	}

	enum Size: CaseIterable {
		/**
		For a bar, like the header.
		*/
		case small

		case regular

		/**
		Like the App Store badge, for download links.
		*/
		case large

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
}

/**
The styles of a link with ``Elementary/HTML/buttonStyle(_:size:)``. They are one style set, so a fill or size always wins over the base. They set no margins, so the parent places the button.
*/
enum ButtonStyles: StyleSet {
	case root
	case primary
	case secondary
	case dark
	case gradient
	case small
	case regular
	case large

	/**
	The accent of the page, with the lightness limited, so the white text of a primary button is readable.
	*/
	private static let primaryFill = Color.accent(fallback: .primary(700), maximumLightness: 0.55)

	/**
	The accent of the page, for the tints of a secondary button.
	*/
	private static let secondaryTint = Color.accent.value(default: .primary(500))

	var style: Style {
		switch self {
		case .root:
			Style()
				.display(.inlineFlex)
				.alignItems(.center)
				.justifyContent(.center)
				.gap(.rootEm(0.5))
				.cornerRadius(.capsule)
				.textAlign(.center)
				.textWrap(.nowrap)
				.textSelection(.disabled)
				.color(.white)
				// Also in prose, where links are underlined.
				.underline(false)
				.transition(.backgroundColor, .shadow, animation: .stateChange)
		case .primary:
			// The accent of the page, like the color of the icon on an app page. It is dark enough for the white text. A soft light at the top, a thin light edge, and a small shadow in the accent give it some depth, like the glass of the cards.
			Style()
				.background(Self.primaryFill)
				.backgroundImage(.linearGradient("to bottom", .white.opacity(0.16), .transparent))
				.shadow(
					Shadow(y: .pixels(6), blur: .pixels(16), spread: .pixels(-6), color: Self.primaryFill.opacity(0.6)),
					Shadow(y: .pixels(1), color: .white.opacity(0.25), isInset: true),
					// A thin edge, like the edge of the App Store and Setapp badges next to it.
					Shadow(y: 0, spread: .pixels(1), color: .white.opacity(0.12), isInset: true)
				)
				.hover {
					$0.background(Self.primaryFill.lighter(0.06))
				}
		case .secondary:
			// A light tint of the accent of the page, with the depth of the primary button, but softer.
			Style()
				.background(Self.secondaryTint.opacity(0.16))
				.backgroundImage(.linearGradient("to bottom", .lightDark(.white.opacity(0.5), .white.opacity(0.06)), .transparent))
				.shadow(
					Shadow(y: .pixels(4), blur: .pixels(12), spread: .pixels(-6), color: Self.secondaryTint.opacity(0.3)),
					Shadow(y: .pixels(1), color: .lightDark(.white.opacity(0.8), .white.opacity(0.1)), isInset: true),
					Shadow(y: 0, spread: .pixels(1), color: .lightDark(Self.secondaryTint.opacity(0.15), .white.opacity(0.1)), isInset: true)
				)
				.color(.accent(fallback: .primary(700), maximumLightness: 0.5), dark: .primary(200))
				.hover {
					$0.background(Self.secondaryTint.opacity(0.24))
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
				.shadow(Shadow(y: .pixels(1), blur: .pixels(2), color: .black.opacity(0.05)))
				.hover {
					$0
						.backgroundImage(.brandGradientHover)
						.shadow(.medium)
				}
		case .small:
			Style()
				.padding(vertical: .rootEm(0.5), horizontal: .rootEm(1.25))
				.textStyle(.caption, weight: .bold)
		case .regular:
			Style()
				.padding(vertical: .rootEm(0.625), horizontal: .rootEm(1.25))
				.fontWeight(.semibold)
				.lineHeight(1.375)
		case .large:
			// Like the App Store badge next to it, it grows a little under the pointer.
			Style()
				// The corners are between those of the App Store badge (10px) and the Setapp badge (13px) next to it.
				.frame(width: .pixels(180), height: .pixels(60))
				.padding(vertical: .rootEm(1), horizontal: .rootEm(2.5))
				.cornerRadius(.rootEm(0.75))
				.font(.extraLarge, weight: .bold)
				.transition(.backgroundColor, animation: .default(duration: .milliseconds(200)))
				.pressEffect()
		}
	}
}
