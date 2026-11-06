import Elementary
import Foundation
import SiteKit

/**
The download badges (App Store, Setapp), custom download buttons, and the “Source Code” and “Free Trial” buttons. The parent leaves it out when the app has no download options, and sets the space around it.
*/
struct DownloadOptions: HTML {
	let app: App

	/**
	Where the App Store badge is, for the campaign of its link.
	*/
	var appStorePlacement = App.AppStorePlacement.downloadButton

	var body: some HTML<HTMLTag.div> {
		div {
			for option in app.downloadOptions(appStorePlacement: appStorePlacement) {
				OptionLink(option: option)
			}
		}
		.style(Styles.root)
	}

	private struct OptionLink: HTML {
		let option: DownloadOption

		// A switch, so a new kind of option does not compile until it has its look.
		var body: some HTML {
			switch option {
			case .appStore:
				badgeLink(.appStore)
			case .setapp:
				badgeLink(.setapp)
			case .link(let link):
				buttonLink(link.title, destination: link.destination)
			case .sourceCode:
				// Secondary, like “Free Trial”, so the store or the purchase stays the strongest action.
				buttonLink("Source Code", destination: option.url, fill: .secondary)
			case .trial:
				buttonLink("Free Trial", destination: option.url, fill: .secondary)
			}
		}

		/**
		The common markup of download actions that are not store badges.
		*/
		private func buttonLink(_ title: String, destination: LinkDestination, fill: ButtonStyles.Fill = .primary) -> some HTML<HTMLTag.a> {
			Link(title, destination: destination)
				.buttonStyle(fill, size: .large)
				.style(Styles.button)
		}

		private func badgeLink(_ badge: DownloadOption.Badge) -> some HTML<HTMLTag.a> {
			a(.href(option.url)) {
				img(
					.src(badge.imagePath),
					.width(badge.width),
					.height(60),
					.alt(badge.label)
				)
					.style(Styles.badgeImage)
			}
			.style(Styles.badge)
		}
	}

	enum Styles: String, StyleSet {
		case root
		case badge
		case badgeImage
		case button

		var style: Style {
			switch self {
			case .root:
				// On phones, the options are a little smaller, so two fit side by side, like the App Store badge and “Free Trial”. A third option wraps to the next line. The options are at the top of the row, so a badge is not stretched to the height of a button and its bottom margin.
				Style()
					.hstack(alignment: .start, justification: .center)
					.flexWrap()
					.gap(.rootEm(1))
					.below(.smallTablet) {
						$0.declaration(raw: .zoom, 0.9)
					}
			case .badge:
				// Not inline, as `scale` does not apply to inline elements, and the badge disappeared after the hover transition.
				// A shadow like the one of the buttons next to it. A filter, so it follows the shape of the badge. It is on the link with the brightness of the press effect, not on the image, as Safari stopped drawing the badge under the pointer when both had a filter.
				Style()
					.display(.block)
					.textSelection(.disabled)
					.pressEffect(keeping: Self.badgeShadow)
			case .badgeImage:
				Style()
					.display(.block)
					.frame(height: .pixels(60))
			case .button:
				Style().margin(.bottom, .rootEm(0.5))
			}
		}

		private static let badgeShadow = Filter.dropShadow(Shadow(y: .pixels(5), blur: .pixels(8), color: .black.opacity(0.3)))
	}
}
