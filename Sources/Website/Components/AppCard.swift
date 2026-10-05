import Elementary
import SiteKit

/**
An app in a grid of apps: icon, name, subtitle, whether it is paid, and the platforms.
*/
struct AppCard: HTML {
	let app: App
	let isNew: Bool

	/**
	Whether the card is in the first rows of the page, so its icon loads at once.
	*/
	var isAboveFold = false

	var body: some HTML {
		// `apps.js` filters the cards by `data-slug`.
		// The accent of the card is the color of the icon, for the light while the pointer is over it.
		a(.href(app.url), .hook(Hooks.slug, value: app.slug)) {
			AppIcon(decorative: app, size: 128, isAboveFold: isAboveFold)
				.style(Styles.icon)

			div {
				div {
					app.title
				}
				.style(Styles.title)

				div {
					app.subtitle
				}
				.style(Styles.subtitle)

				div {
					if isNew {
						Badge("New", kind: .new)
					}

					// The price is on the page of the app, so visitors see the app before the price.
					Badge(app.isPaid ? "Paid" : "Free")

					if app.hasTrial {
						Badge("Free Trial")
					}

					if app.repositoryURL != nil {
						Badge("Open Source")
					}

					span {
						for platform in app.platforms {
							platform.icon.size(.rootEm(0.9375))
						}

						VisuallyHidden(app.operatingSystems)
					}
					.attributes(.title(app.operatingSystems))
					.style(Styles.platforms)
				}
				.style(Styles.details)
			}
			.style(Styles.text)
		}
		.tint(app.tint)
		.style(Styles.root)
	}

	/**
	The IDs and data attributes that the scripts of the component find elements by.
	*/
	enum Hooks: String, ScriptHookSet {
		case slug = "data-slug"
	}

	enum Styles: StyleSet {
		case root
		case icon
		case text
		case title
		case subtitle
		case details
		case platforms

		var style: Style {
			switch self {
			case .root:
				// The fill and a soft glow change while the pointer is over the card, but nothing moves. The card is compact until laptops, as the grid has two columns from small tablets.
				Style()
					.hstack(alignment: .center, spacing: .rootEm(1))
					.padding(.rootEm(1.25))
					.cardSurface()
					.from(.laptop) {
						$0
							.gap(.rootEm(1.5))
							.padding(.rootEm(1.75))
					}
			case .icon:
				// The icon images have transparent margins, so the icon is larger than it looks.
				Style()
					.flexShrink(0)
					.frame(width: .rootEm(5), height: .rootEm(5))
					.margin(.rootEm(-0.25))
					.filter(.dropShadow(Shadow(y: .pixels(2), blur: .pixels(2), color: .black.opacity(0.1))))
					.from(.laptop) {
						$0.frame(width: .rootEm(6.5), height: .rootEm(6.5))
					}
			case .text:
				Style()
					.vstack(spacing: .rootEm(0.25))
					.frame(minWidth: 0)
			case .title:
				Style()
					.textStyle(.headline)
					.color(.primaryText)
					.from(.laptop) {
						$0.font(size: .rootEm(1.375), lineHeight: 1.25)
					}
			case .subtitle:
				Style()
					.font(size: .rootEm(1), lineHeight: 1.35)
					.color(.bodyText)
					.textWrap(.pretty)
					.from(.laptop) {
						$0.font(size: .rootEm(1.0625), lineHeight: 1.4)
					}
			case .details:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.375))
					.flexWrap()
					.margin(.top, .rootEm(0.625))
					.opacity(0.9)
			case .platforms:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.25))
					.margin(.leading, .rootEm(0.125))
					.color(.secondaryText)
			}
		}
	}
}

/**
A grid of app cards: one column on phones, and two from small tablets. Every page with app cards gives it the width of the header and the footer (`contentColumn(.page)`), so the cards line up with them and look the same on every page.
*/
struct AppGrid: HTML {
	let apps: [App]
	let content: SiteContent

	/**
	Whether the grid is at the top of the page, so the icons of the first cards load at once. Grids further down load their icons lazily.
	*/
	var isAtTop = false

	var body: some HTML {
		div {
			// The first cards fill the screen on most devices.
			for (index, app) in apps.enumerated() {
				AppCard(app: app, isNew: app.isNew(at: content.buildDate), isAboveFold: isAtTop && index < 6)
			}
		}
		.style(Styles.root)
	}

	enum Styles: StyleSet {
		case root

		var style: Style {
			// At most two columns, so the cards have room. On phones, the cards reach halfway into the space at the sides of the page, so they use more of the narrow screen.
			Style()
				.display(.grid)
				.gap(.rootEm(1.25))
				.below(.smallTablet) {
					$0.margin(.horizontal, -(Length.pageGutter * 0.5))
				}
				.from(.smallTablet) {
					$0.gridColumns(2)
				}
		}
	}
}

extension HTML where Tag: HTMLTrait.Attributes.Global {
	/**
	Sets the accent of the element and its content, like `tint(_:)` in SwiftUI, like the color of the icon of an app for the light of its card. `nil` keeps the accent of the page (``Page/tint``).
	*/
	func tint(_ color: Color?) -> _AttributedContent<Self> {
		guard let color else {
			return attributes(contentsOf: [])
		}

		return attributes(.style("\(Color.accent.name): \(CSSValue(color))"))
	}
}
