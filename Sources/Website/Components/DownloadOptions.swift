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
			nav(.ariaLabel("Download options")) {
				for (index, option) in app.downloadOptions.enumerated() {
					div {
						// Next to the first option. `app.js` shows it when the browser can share.
						if index == 0 {
							button(.id(.shareButton), .hidden, .type(.button), .ariaLabel("Share \(app.title)"), .hook(.shareTitleAttribute, value: app.title), .hook(.shareUrlAttribute, value: shareURL)) {
								Icon.share.size(.rem(1))
							}
							.style(Styles.shareButton)
						}

						OptionLink(option: option)
					}
					.style(Styles.option)
				}
			}
			.style(Styles.root)
		}
	}

	/**
	The App Store page, or the app page for apps that are not on the App Store.
	*/
	private var shareURL: String {
		(app.appStoreURL ?? app.path.absoluteURL(site: Site.url)).absoluteString
	}

	private struct OptionLink: HTML {
		let option: DownloadOption

		var body: some HTML {
			switch option {
			case .appStore(let url):
				a(.href(url.absoluteString)) {
					img(.src("/assets/download-on-app-store-badge.svg"), .alt("Download on the App Store"))
						.style(Styles.badgeImage)
				}
				.style(Styles.badge)
			case .setapp(let url):
				a(.href(url.absoluteString)) {
					img(.src("/assets/download-on-setapp-badge.svg"), .alt("Download on Setapp"))
						.style(Styles.badgeImage)
				}
				.style(Styles.badge)
			case .link(let link):
				Button(link.title, destination: link.href, size: .large)
					.style(Styles.button)
			}
		}
	}

	enum Styles: StyleSet {
		case root
		case option
		case badge
		case shareButton
		case badgeImage
		case button

		var style: Style {
			switch self {
			case .root:
				Style()
					.vstack()
					.gap(row: .rem(2), column: .rem(1))
					.margin(.top, .rem(0.5))
					.breakpoint(.sm) {
						$0.flexDirection(.row)
					}
			case .badge:
				// Not inline, as `scale` does not apply to inline elements, and the badge disappeared after the hover transition.
				Style()
					.display(.block)
					.transition(.transform, .filter, duration: .milliseconds(200))
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
			case .option:
				Style().position(.relative)
			case .shareButton:
				Style()
					.position(.absolute)
					.inset(0)
					.leading(.px(-26))
					.frame(width: .px(16))
					.opacity(0.9)
					.cursor(.pointer)
			case .badgeImage:
				Style()
					.display(.block)
					.frame(height: .px(60))
					.textSelection(.disabled)
			case .button:
				Style().margin(.bottom, .rem(0.5))
			}
		}
	}
}
