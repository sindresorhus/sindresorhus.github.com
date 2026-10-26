import Elementary
import SiteKit

/**
An app in a grid of apps: icon, name, subtitle, whether it is paid, and the platforms.

The name is a heading with the link, which covers the whole card, so the link has a short name, like “Scratchpad”, not the text of the whole card, and screen readers can move from app to app by the headings.
*/
struct AppCard: HTML {
	let app: App
	let isNew: Bool

	/**
	Whether the card is in the first rows of the page, so its icon loads at once.
	*/
	var isAboveFold = false

	/**
	The level of the heading of the name: 3 below a section heading, or 2 right below the title of the page.
	*/
	var headingLevel = 3

	var body: some HTML {
		// `apps.js` filters the cards by `data-slug`.
		// The accent of the card is the color of the icon, for the light while the pointer is over it.
		div(.hook(Hooks.slug, value: app.slug)) {
			AppIcon(decorative: app, size: 128, isAboveFold: isAboveFold)
				.style(Styles.icon)

			div {
				if headingLevel == 2 {
					h2(.notTranslated) {
						titleLink
					}
					.style(Styles.title)
				} else {
					h3(.notTranslated) {
						titleLink
					}
					.style(Styles.title)
				}

				div {
					app.subtitle
				}
				.style(Styles.subtitle)

				div {
					if isNew {
						Badge("New", kind: .new)
					}

					// The price is on the page of the app, so visitors see the app before the price. An archived app has no App Store or Setapp download, so it has no price, like its page shows.
					if !app.isArchived {
						Badge(app.isPaid ? "Paid" : "Free")
					}

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
					.style(Styles.platforms)
				}
				.style(Styles.details)
			}
			.style(Styles.text)
		}
		.tint(app.tint)
		.style(Styles.root)
	}

	private var titleLink: some HTML<HTMLTag.a> {
		a(.href(app.url)) {
			app.title
		}
		.style(Styles.link)
	}

	/**
	The IDs and data attributes that the scripts of the component find elements by.
	*/
	enum Hooks: String, ScriptHookSet {
		case slug = "data-slug"
	}

	/**
	The soft shadow below the icon of an app on a card, like the cards of tiny apps.
	*/
	static let iconShadow = Filter.dropShadow(Shadow(y: .pixels(2), blur: .pixels(2), color: .black.opacity(0.1)))

	enum Styles: StyleSet {
		case root
		case icon
		case text
		case title
		case link
		case subtitle
		case details
		case platforms

		var style: Style {
			switch self {
			case .root:
				// The fill and a soft glow change while the pointer is over the card, but nothing moves. The card is compact until laptops, as the grid has two columns from small tablets.
				Style()
					.position(.relative)
					.hstack(alignment: .center, spacing: .rootEm(1))
					.padding(.rootEm(1.25))
					.cardSurface()
					.from(.laptop) {
						$0
							.gap(.rootEm(1.5))
							.padding(.rootEm(1.75))
					}
			case .icon:
				// The negative margin makes the icon take a little less space than its size, so it is nearer to the edges of the card and to the text.
				Style()
					.frame(size: .rootEm(5))
					.margin(.rootEm(-0.25))
					.filter(AppCard.iconShadow)
					.from(.laptop) {
						$0.frame(size: .rootEm(6.5))
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
			case .link:
				// It covers the card, so the whole card is the link, like before, but its name is only the name of the app.
				Style()
					.color(.inherit)
					.underline(false)
					.after {
						$0
							.content("")
							.position(.absolute)
							.inset(0)
							.cornerRadius(.cardRadius)
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

	/**
	The level of the headings of the names of the apps (``AppCard/headingLevel``).
	*/
	var headingLevel = 3

	var body: some HTML {
		div {
			// The first cards fill the screen on most devices.
			for (index, app) in apps.enumerated() {
				AppCard(app: app, isNew: app.isNew(at: content.buildDate), isAboveFold: isAtTop && index < 6, headingLevel: headingLevel)
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
	Sets the accent of the element and its content, like `tint(_:)` in SwiftUI, like the color of the icon of an app for the light of its card. `nil` keeps the accent of the page (``Page/tint``). It is a style of the element (``ElementStyle``), so each color is one rule.
	*/
	func tint(_ color: Color?, fileID: String = #fileID) -> _AttributedContent<Self> {
		guard let color else {
			return attributes(contentsOf: [])
		}

		return style(fileID: fileID) {
			$0.setting(Color.accent, to: color)
		}
	}
}
