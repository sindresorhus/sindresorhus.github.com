import Elementary
import SiteKit

/**
A menu of links behind a “…” button. The menu is a popover with real links, so it works without JavaScript, closes with the Escape key or a click outside, and search engines follow the links. Anchor positioning places it below the button.

Titled groups get a heading. Untitled groups are separated by a rule.
*/
struct OverflowMenu: HTML {
	enum Variant: Sendable {
		/**
		Next to a row of links.
		*/
		case inline

		/**
		Next to a page title.
		*/
		case title
	}

	/**
	The ID of the popover, unique on the page.
	*/
	let id: String

	let label: String
	let groups: [LinkGroup]
	var variant = Variant.inline

	init(id: String, label: String, links: [LabeledLink]...) {
		self.id = id
		self.label = label
		self.groups = links.map { LinkGroup(title: "", links: $0) }
	}

	init(id: String, label: String, groups: [LinkGroup], variant: Variant) {
		self.id = id
		self.label = label
		self.groups = groups
		self.variant = variant
	}

	/**
	The menu of an app page: the pages about the app, and a random app.
	*/
	static func appPage(_ app: App, id: String) -> Self {
		Self(id: id, label: "More about \(app.title)", links: app.pageOverflowLinks, [LabeledLink("Show Random App", path: .randomApp)])
	}

	var body: some HTML {
		div {
			button(.type(.button), .custom(name: "popovertarget", value: id), .ariaLabel(label)) {
				Icon.dots
			}
			.style(Styles.button)

			div(.id(id), .popover) {
				for (index, group) in groups.enumerated() {
					if group.title.isEmpty {
						if index > 0 {
							hr()
								.style(Styles.separator)
						}
					} else {
						p {
							group.title
						}
						.style(Styles.groupTitle)
					}

					ul {
						for link in group.links {
							li {
								a(.href(link.href)) {
									link.title
								}
								.style(Styles.link)
							}
						}
					}
				}
			}
			.style(Styles.menu)
		}
		.style(Styles.root)
		.style(Styles.title, when: variant == .title)
	}

	/**
	The color of the “…” button, which a parent can set, like to match the links next to it.
	*/
	static let color = StyleVariable("--overflow-menu-color")

	enum Styles: StyleSet {
		case root
		case title
		case button
		case menu
		case groupTitle
		case link
		case separator

		var style: Style {
			switch self {
			case .root:
				// The button looks pressed while the menu is open.
				Style()
					.hstack(alignment: .center)
					.padding(.top, .px(2))
					.nested("&:has(:popover-open) \(Self.button.selector)") {
						$0.opacity(0.6)
					}
			case .title:
				Style()
					.nested(Self.button.selector) {
						$0
							.color(.secondary(400))
							.nested(Icon.selector) {
								$0
									.frame(width: .rem(1.75), height: .rem(1.75))
									.breakpoint(.sm) {
										$0.frame(width: .rem(1.25), height: .rem(1.25))
									}
							}
					}
			case .button:
				Style()
					.hstack(alignment: .center)
					.declaration(.color, OverflowMenu.color.value(default: CSSValue(Color.link)))
					.cursor(.pointer)
					// A larger target for fingers, without moving the layout.
					.media(.coarsePointer) {
						$0
							.padding(.rem(0.75))
							.margin(.rem(-0.75))
					}
			case .menu:
				// The invoking button is the anchor of the popover, so it opens below the button, and moves to stay on screen. Without anchor positioning, the browser centers it.
				Style()
					.supports("(position-area: bottom)") {
						$0
							.declaration(.positionArea, "bottom span-left")
							.declaration("position-try-fallbacks", "flip-block, flip-inline")
							.inset(.auto)
							.margin(.px(6))
					}
					.padding(.rem(0.375))
					.frame(minWidth: .rem(12))
					.cornerRadius(.rem(0.75))
					.border(.lightDark(.black.opacity(0.08), .white.opacity(0.1)))
					.font(size: .rem(0.9375), lineHeight: 1.4)
					.fontWeight(.medium)
					.letterSpacing(0)
					.textAlign(.leading)
					.color(.primaryText)
					.background(.white, dark: .slate(900))
					.shadow(.large)
			case .groupTitle:
				Style()
					.padding(top: .rem(0.5), horizontal: .rem(0.75), bottom: .rem(0.25))
					.font(.xs, weight: .semibold)
					.textCase(.uppercase)
					.letterSpacing(.em(0.05))
					.color(.secondaryText)
			case .link:
				Style()
					.display(.block)
					.padding(vertical: .rem(0.375), horizontal: .rem(0.75))
					.cornerRadius(.rem(0.5))
					.noWrap()
					.hover {
						$0.background(.gray(100), dark: .slate(800))
					}
					.focusVisible {
						$0.focusRing(.primary(500), width: .px(2))
					}
			case .separator:
				Style()
					.margin(vertical: .rem(0.375), horizontal: .rem(0.5))
					.borderColor(.separator)
			}
		}
	}
}
