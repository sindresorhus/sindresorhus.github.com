import Elementary
import Foundation
import SiteKit

/**
The download badges (App Store, Setapp) and custom download buttons.
*/
struct DownloadOptions: HTML {
	let app: App

	var body: some HTML {
		if !app.downloadOptions.isEmpty {
			div {
				for option in app.downloadOptions {
					div {
						OptionLink(option: option)
					}
					.style(Styles.option)
				}

				if app.hasTrial {
					div {
						Link("Free Trial", destination: .fragment(App.trialSectionID))
							.buttonStyle(.secondary, size: .large)
							.style(Styles.button)
					}
					.style(Styles.option)
				}
			}
			.style(Styles.root)
		}
	}

	private struct OptionLink: HTML {
		let option: DownloadOption

		var body: some HTML {
			if let badge = option.badge {
				a(.href(option.url)) {
					img(.src(badge.imagePath), .width(badge.width), .height(60), .alt(badge.label))
						.style(Styles.badgeImage)
				}
				.style(Styles.badge)
			} else if case .link(let link) = option {
				Link(link.title, destination: link.destination)
					.buttonStyle(size: .large)
					.style(Styles.button)
			}
		}
	}

	enum Styles: StyleSet {
		case root
		case option
		case badge
		case badgeImage
		case button

		var style: Style {
			switch self {
			case .root:
				// On phones, the options are a little smaller, so two fit side by side, like the App Store badge and “Free Trial”. A third option wraps to the next line.
				Style()
					.hstack(justification: .center)
					.flexWrap()
					.gap(.rootEm(1))
					.margin(.top, .rootEm(0.5))
					.below(.smallTablet) {
						$0.declaration(.zoom, 0.9)
					}
			case .badge:
				// Not inline, as `scale` does not apply to inline elements, and the badge disappeared after the hover transition.
				// A shadow like the one of the buttons next to it. A filter, so it follows the shape of the badge. It is on the link with the brightness of the press effect, not on the image, as Safari stopped drawing the badge under the pointer when both had a filter.
				Style()
					.display(.block)
					.textSelection(.disabled)
					.pressEffect()
					.filter(Self.badgeShadow)
					.hover {
						$0.filter(Self.badgeShadow, .brightness(1.08))
					}
					.active {
						$0.filter(Self.badgeShadow, .brightness(0.95))
					}
			case .option:
				Style().position(.relative)
			case .badgeImage:
				Style()
					.display(.block)
					.frame(height: .pixels(60))
					.textSelection(.disabled)
			case .button:
				Style().margin(.bottom, .rootEm(0.5))
			}
		}

		private static let badgeShadow = Filter.dropShadow(Shadow(y: .pixels(5), blur: .pixels(8), color: .black.opacity(0.3)))
	}
}
