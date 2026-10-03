import Elementary
import SiteKit

/**
An app in the grid on the apps page: icon, name, subtitle, and badges.
*/
struct AppCard: HTML {
	let app: App
	let isNew: Bool

	var body: some HTML {
		// `apps.js` filters the cards by `data-slug`.
		a(.href(app.url), .hook(.slugAttribute, value: app.slug)) {
			div {
				AppIcon(app, size: 128, isNamedNearby: true, morphsAcrossPages: true)
					.style(Styles.iconImage)
			}
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
						Badge("new!", kind: .new)
					}

					Badge(app.isPaid ? "paid" : "free")

					if app.repositoryURL != nil {
						Badge("open-source")
					}

					for platform in app.platforms {
						Badge(platform.rawValue, kind: .platform)
					}
				}
				.style(Styles.badges)
			}
			.style(Styles.text)
		}
		.style(Styles.root)
	}

	enum Styles: StyleSet {
		case root
		case icon
		case iconImage
		case text
		case title
		case subtitle
		case badges

		var style: Style {
			switch self {
			case .root:
				Style()
					.display(.flex)
					.padding(vertical: .rem(1), horizontal: .rem(0.5))
					.background(.white, dark: .black.opacity(0.2))
					.shadow(.medium)
					.transition(.colors, .shadow, .transform, duration: .milliseconds(300), curve: .cubicBezier(0.4, 0, 0.2, 1))
					.nested("&:first-child") {
						$0.margin(.top, .rem(2))
					}
					.hover {
						$0.shadow(.extraLarge)
					}
					.breakpoint(.sm) {
						$0
							.padding(.rem(1.5))
							.border(.transparent)
							.cornerRadius(.rem(0.75))
							.nested("&:first-child") {
								$0.margin(.top, 0)
							}
							.hover {
								$0
									.borderColor(.indigo(200).opacity(0.7))
									.background(.indigo(50).opacity(0.4))
									.offset(y: .rem(-0.125))
							}
					}
					.dark {
						$0
							.shadow(.large)
							.breakpoint(.sm) {
								$0
									.borderColor(.slate(800))
									.hover {
										$0
											.borderColor(.indigo(500).opacity(0.3))
											.background(.indigo(950).opacity(0.2))
											.shadow(.extraLarge(color: .indigo(500).opacity(0.2)))
									}
							}
					}
			case .icon:
				Style()
					.flexShrink(0)
					.margin(.trailing, .rem(0.5))
					.breakpoint(.sm) {
						$0.margin(.trailing, .rem(0.75))
					}
			case .iconImage:
				Style()
					.padding(.px(12))
					.dropShadow(Shadow(y: .px(2), blur: .px(2), color: "rgb(0 0 0 / 10%)"))
			case .text:
				Style()
					.vstack(justification: .center)
					.margin(.top, .rem(0.75))
					.margin(.trailing, .rem(0.5))
					.margin(.bottom, .rem(0.75))
					.margin(.leading, 0)
					.breakpoint(.sm) {
						$0.margin(.top, .px(-1))
					}
			case .title:
				Style()
					.margin(.bottom, .rem(0.125))
					.font(.xl2, weight: .bold)
					.breakpoint(.sm) {
						$0.font(.xl3)
					}
			case .subtitle:
				Style()
					.font(size: .rem(1.125), lineHeight: 1.25)
					.color(.gray(700), dark: .gray(200).opacity(0.9))
					.textWrap(.pretty)
					.declaration("hanging-punctuation", "first last")
					.breakpoint(.sm) {
						$0.font(size: .rem(1.25))
					}
			case .badges:
				Style()
					.hstack(spacing: .rem(0.375))
					.flexWrap()
					.margin(.top, .rem(0.75))
					.opacity(0.9)
			}
		}
	}
}
