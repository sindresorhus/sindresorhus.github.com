import Foundation
import Elementary
import SiteKit

/**
A menu of links behind a “…” button. It is a native `<select>`, so it works with the keyboard and on touch devices, and looks native. Its script opens the chosen link, or shows the popover that a `#id` option points to, like the QR code of an app.

Search engines do not follow the options, so a page also links the pages somewhere else, like ``AppFooterLinks``.

Limitation: in Chrome and Firefox on Windows and Linux, the arrow keys change the value of a closed `<select>`, so the first arrow key press opens the first option. Keyboard users can open the menu with Space or Alt+Down first.

Titled groups become option groups. Untitled groups are separated by a rule.

A menu can also share a page, with a “Share…” option at the end. It is hidden until the script finds that the browser can share, so it is not there in browsers that cannot, like Firefox on desktop.
*/
struct OverflowMenu: ScriptedElement {
	static let script = ElementScript()

	enum Variant {
		/**
		Next to a row of links.
		*/
		case inline

		/**
		Next to a page title.
		*/
		case title

		/**
		A chip at the end of a row of chips, like the section links of an app page.
		*/
		case chip
	}

	let label: String
	let groups: [LinkGroup]
	var variant = Variant.inline

	/**
	The page that the “Share…” option shares, and the ID of the popover that shows instead when the browser refuses to share from the menu, like Safari on the Mac.
	*/
	var sharedPage: (title: String, url: URL, popoverID: String)?

	init(label: String, links: [LabeledLink]...) {
		self.label = label
		self.groups = links.map { LinkGroup(title: "", links: $0) }
	}

	init(label: String, groups: [LinkGroup], variant: Variant) {
		self.label = label
		self.groups = groups
		self.variant = variant
	}

	/**
	The menu of an app page: the pages about the app, a random app, and then the ways to pass the app on, the QR code and sharing. The random app is in its own group, as it is not about this app.
	*/
	static func appPage(_ app: App, variant: Variant = .inline) -> Self {
		// “Share…” comes after the QR code, as the menu adds it at the end.
		var menu = Self(label: "More about \(app.title)", links: app.pageOverflowLinks, [LabeledLink("Show Random App", path: .randomApp)], [LabeledLink("Show QR Code", destination: .fragment(AppHero.qrCodeID))])
		menu.variant = variant
		menu.sharedPage = (app.title, app.shareURL, AppHero.sharePopoverID)
		return menu
	}

	var rootAttributes: [HTMLAttribute<ElementTag<Self>>] {
		guard let sharedPage else {
			return []
		}

		return [.custom(name: "share-title", value: sharedPage.title), .custom(name: "share-url", value: sharedPage.url.absoluteString)]
	}

	var content: some HTML {
		div {
			select {
				option(.value(""), .disabled, .selected) {
					""
				}

				for (index, group) in groups.enumerated() {
					if group.title.isEmpty {
						if index > 0 {
							hr()
						}

						for link in group.links {
							option(.value(link.destination.description)) {
								link.title
							}
						}
					} else {
						optgroup(.label(group.title)) {
							for link in group.links {
								option(.value(link.destination.description)) {
									link.title
								}
							}
						}
					}
				}

				// Disabled too, as Safari on iOS shows hidden options. Its value is the popover that shows when the browser refuses to share from the menu. The script reads the shared page from the attributes of the element.
				if let sharedPage {
					option(.value("#\(sharedPage.popoverID)"), .hidden, .disabled, .part(Parts.share)) {
						"Share…"
					}
				}
			}
			.accessibilityLabel(label)
			.style(Styles.select)

			// A chip shows the dots without a circle, as a circle in a chip looks doubled.
			if variant == .chip {
				Icon.ellipsis.size(.rootEm(1.125))
			} else {
				Icon.dots
			}
		}
		.style(Styles.container)
		.style(Styles.title, when: variant == .title)
		.style(Styles.chip, when: variant == .chip)
	}

	/**
	The color of the “…” icon, which a parent can set, like to match the links next to it.
	*/
	static let color = StyleVariable<Color>("--overflow-menu-color")

	enum Parts: String, ElementPartSet {
		case share
	}

	enum Styles: ElementStyleSet {
		case root
		case container
		case title
		case chip

		/**
		The invisible `<select>` over the icon, so the native menu opens on click.
		*/
		case select

		var style: Style {
			switch self {
			case .root:
				// The element only adds the behavior, so the menu is laid out as if it were not there.
				Style().display(.contents)
			case .container:
				Style()
					.position(.relative)
					.hstack(alignment: .center)
					.padding(.top, .pixels(2))
					.cornerRadius(.capsule)
					.nested(Icon.selector) {
						$0
							.allowsHitTesting(false)
							.color(OverflowMenu.color.value(default: .link))
					}
					// The select is invisible, and the icon has no focus ring, like the rest of the site. Chrome also shows the focus of a clicked `<select>` as `:focus-visible`, so a ring would show after every click.
					// A larger target for fingers, without moving the layout.
					.media(.coarsePointer) {
						$0
							.padding(.rootEm(0.75))
							.margin(.rootEm(-0.75))
					}
			case .title:
				Style()
					// The menu would otherwise get the large font of the title.
					.nested(Self.select.selector) {
						$0.font(size: .rootEm(1.25))
					}
					.nested(Icon.selector) {
						$0
							.frame(width: .rootEm(1.75), height: .rootEm(1.75))
							.color(.secondary(400))
							.from(.smallTablet) {
								$0.frame(width: .rootEm(1.25), height: .rootEm(1.25))
							}
					}
			case .chip:
				// The whole chip opens the menu, as the select covers it. The chip is a large enough target for fingers, so it does not get the negative margin of the root, which would make it overlap the chip before it.
				Style()
					.chip()
					.padding(vertical: .rootEm(0.375), horizontal: .rootEm(0.75))
					.margin(0)
					.setting(OverflowMenu.color, to: .bodyText)
			case .select:
				Style()
					.position(.absolute)
					.inset(0)
					.frame(width: .percent(100), height: .percent(100))
					.padding(0)
					.opacity(0)
					.cursor(.pointer)
					.declaration(.fontFamily, "system-ui")
					.declaration(.fontWeight, "initial")
					// Chrome and Firefox on Windows and Linux draw the menu with the colors of the select. The base styles make it transparent and give it the color of the text around it, so in dark mode, the options were light text on white.
					.color("FieldText")
					.background("Field")
			}
		}
	}
}
