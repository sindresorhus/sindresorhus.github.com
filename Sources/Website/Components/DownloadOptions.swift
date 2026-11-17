import Elementary
import Foundation
import SiteKit

/**
The download badges (App Store, Setapp), the “Learn More”, “Download”, and “Buy” buttons, and the “Source Code” and “Free Trial” buttons. The parent leaves it out when the app has no download options, and sets the space around it.
*/
struct DownloadOptions: HTML {
	let app: App

	/**
	Where the App Store badge is, for the campaign of its link.
	*/
	var appStorePlacement = App.AppStorePlacement.downloadButton

	/**
	The dialog of the page with the trial card, which the “Free Trial” button opens over the page, like on the app page (``AppHero/trialDialogID``). Without it, the button links to the trial section of the app page, like in a guide.
	*/
	var trialDialogID: ElementID?

	/**
	Whether the “Free Trial” button is shown, when the app has a trial. A guide about the iPhone leaves out a trial that is only for the Mac (``App/Trial/isMacOnly``).
	*/
	var showsTrial = true

	/**
	Whether the options are at the top of the page, like in the hero of an app page, so the badges load with a high priority, before the other images, and the ways to get the app do not show last on a slow connection.
	*/
	var isAboveFold = false

	var body: some HTML<HTMLTag.div> {
		div {
			for option in options {
				OptionLink(option: option, trialDialogID: trialDialogID, isAboveFold: isAboveFold)
			}
		}
		.style(Styles.root)
	}

	private var options: [DownloadOption] {
		app.downloadOptions(appStorePlacement: appStorePlacement).filter { option in
			guard case .trial = option else {
				return true
			}

			return showsTrial
		}
	}

	private struct OptionLink: HTML {
		let option: DownloadOption
		let trialDialogID: ElementID?
		let isAboveFold: Bool

		// A switch, so a new kind of option does not compile until it has its look.
		var body: some HTML {
			switch option {
			case .appStore:
				badgeLink(.appStore)
			case .setapp:
				badgeLink(.setapp)
			case .website:
				buttonLink("Learn More", destination: option.url)
			case .gitHubDownload:
				buttonLink("Download", destination: option.url)
			case .gumroad:
				buttonLink("Buy", destination: option.url)
			case .sourceCode:
				// Secondary, like “Free Trial”, so the store or the purchase stays the strongest action.
				buttonLink("Source Code", destination: option.url, fill: .secondary)
			case .trial:
				if let trialDialogID {
					button(.type(.button), .popoverTarget(trialDialogID)) {
						"Free Trial"
					}
					.buttonStyle(.secondary, size: .large)
				} else {
					buttonLink("Free Trial", destination: option.url, fill: .secondary)
				}
			}
		}

		/**
		The common markup of download actions that are not store badges.
		*/
		private func buttonLink(_ title: String, destination: LinkDestination, fill: ButtonStyles.Fill = .primary) -> some HTML<HTMLTag.a> {
			Link(title, destination: destination)
				.buttonStyle(fill, size: .large)
		}

		private func badgeLink(_ badge: DownloadOption.Badge) -> some HTML<HTMLTag.a> {
			a(.href(option.url)) {
				img(
					.src(badge.imagePath),
					.width(badge.width),
					.height(60),
					.alt(badge.label)
				)
					.attributes(.fetchPriority(.high), when: isAboveFold)
					.style(Styles.badgeImage)
			}
			.style(Styles.badge)
		}
	}

	enum Styles: String, StyleSet {
		case root
		case badge
		case badgeImage

		var style: Style {
			switch self {
			case .root:
				// On phones, the options are a little smaller, so two fit side by side, like the App Store badge and “Free Trial”. A third option wraps to the next line. The options are at the top of the row, so a badge is not stretched to the height of a button.
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
			}
		}

		private static let badgeShadow = Filter.dropShadow(Shadow(y: .pixels(5), blur: .pixels(8), color: .black.opacity(0.3)))
	}
}
