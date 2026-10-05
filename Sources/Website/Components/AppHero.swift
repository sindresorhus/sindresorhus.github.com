import Elementary
import Foundation
import SiteKit

/**
The top of an app page: the icon, the name, the subtitle, the introduction, the download buttons, the price and platforms, and the links. The rating is with the reviews (``AppReviews``), so the hero is not crowded.
*/
struct AppHero: HTML {
	let app: App

	/**
	The App Store info, for the price.
	*/
	let info: AppStoreInfo?

	/**
	The HTML of the first paragraph of the page, so visitors see what the app does before the screenshots.
	*/
	var introduction: MarkdownContent?

	var body: some HTML {
		header(.id(Hooks.hero)) {
			AppIcon(app, size: 256, isAboveFold: true, imageID: Hooks.icon.rawValue)
				.style(Styles.icon)

			h1 {
				app.title
			}
			.style(Styles.title)

			p {
				app.subtitle
			}
			.style(Styles.subtitle)

			if let introduction {
				p {
					introduction
				}
				.style(Styles.introduction)
			}

			// Shown when coming from the random app page, which links to `#another-random-app`.
			div {
				Link(destination: .path(.randomApp)) {
					Label("Another Random App", icon: .shuffle)
				}
				.buttonStyle(.gradient)
				.style(Styles.anotherRandomAppButton)
			}
			.style(Styles.anotherRandomApp)

			if app.isArchived {
				div {
					Badge("Archived", kind: .archived)
				}
				.style(Styles.archivedBadge)
			}

			DownloadOptions(app: app)

			if let downloads = app.downloads {
				p {
					span {
						downloads.approximateCount
					}
					.style(Styles.downloadCount)

					span {
						" downloads"
					}
					.style(Styles.downloadLabel)
				}
				.style(Styles.downloads)
			}

			if !details.isEmpty {
				p {
					details.joined(separator: " · ")
				}
				.style(Styles.details)
			}

			// The “Show QR Code” option of the “…” menu shows it, like on a computer, to open the App Store page on an iPhone. An app that is not on iPhone, Apple Watch, or Vision Pro gets the page of the app instead, to open it on a phone, like to send it to someone.
			let appStoreURL = app.qrCodeURL
			// A dialog named by its caption, which the “…” menu focuses, so screen readers announce it.
			figure(.id(Self.qrCodeID), .popover, .role("dialog"), .ariaLabelledBy("\(Self.qrCodeID)-caption"), .tabindex(-1)) {
				QRCode(url: appStoreURL ?? app.path.absoluteURL, label: appStoreURL != nil ? "QR code that opens \(app.title) on the App Store" : "QR code that opens this page")
					.style(Styles.qrCodeImage)

				figcaption(.id("\(Self.qrCodeID)-caption")) {
					appStoreURL != nil ? "Scan with your iPhone to open \(app.title) on the App Store" : "Scan with your phone to open this page"
				}
			}
			.style(Styles.dialog)

			// The “Share…” option of the “…” menu shows it when it cannot share, like in Safari on the Mac, which does not count a choice in a menu as an action of the visitor. Its buttons count.
			div(.id(Self.sharePopoverID), .popover, .role("dialog"), .ariaLabelledBy(Self.shareTitleID), .tabindex(-1)) {
				p(.id(Self.shareTitleID)) {
					"Share \(app.title)"
				}
				.style(Styles.shareTitle)

				div {
					ShareButton(pageTitle: app.title, url: app.shareURL)

					CopyButton(title: "Copy Link", text: app.shareURL.absoluteString)
				}
				.hstack(alignment: .center, justification: .center, spacing: .rootEm(0.5))
			}
			.style(Styles.dialog)

			AppLinks(app: app)
		}
		.style(Styles.root)
	}

	/**
	The price and the platforms. An archived app is no longer available, so it has neither.
	*/
	private var details: [String] {
		guard !app.isArchived else {
			return []
		}

		return [app.priceText(info: info), app.availabilityText].compactMap(\.self)
	}

	/**
	The fragment that the random app page adds, which shows the “Another Random App” button. The app page has the ID at its top, so the page does not scroll.
	*/
	static let anotherRandomAppID = "another-random-app"

	/**
	The ID of the QR code popover, which the “…” menu shows.
	*/
	static let qrCodeID = "qr-code"

	/**
	The ID of the share popover, which the “Share…” option of the “…” menu shows when the browser refuses to share from the menu.
	*/
	static let sharePopoverID = "share-popover"

	private static let shareTitleID = "share-title"

	/**
	The IDs that scripts find elements of the hero by: the hero, which the navigation of the app observes and links to, and the icon, which the script of an app page can change, like the googly eyes of the Googly Eyes page.
	*/
	enum Hooks: String, ScriptHookSet {
		case hero = "app-hero"
		case icon = "app-icon"
	}

	enum Styles: StyleSet {
		case root
		case icon
		case title
		case subtitle
		case introduction
		case anotherRandomApp
		case anotherRandomAppButton
		case dialog
		case shareTitle
		case qrCodeImage
		case archivedBadge
		case downloads
		case downloadCount
		case downloadLabel
		case details

		var style: Style {
			switch self {
			case .root:
				Style()
					.vstack(alignment: .center)
					.padding(.horizontal, .rootEm(1))
					.textAlign(.center)
					.children(DownloadOptions.Styles.root.selector) {
						$0.margin(.top, .rootEm(2))
					}
					.from(.smallTablet) {
						$0.padding(.horizontal, .rootEm(1.5))
					}
			case .icon:
				// The icon images have transparent margins, so the icon looks smaller than its frame.
				Style()
					.frame(width: .rootEm(8), height: .rootEm(8))
					.margin(.bottom, .rootEm(1.25))
					.filter(
						.dropShadow(Shadow(y: .pixels(1), blur: .pixels(2), color: .black.opacity(0.15))),
						.dropShadow(Shadow(y: .pixels(4), blur: .pixels(10), color: .black.opacity(0.1))),
						.dropShadow(Shadow(y: .pixels(12), blur: .pixels(28), color: .black.opacity(0.07))),
						// A soft glow in the color of the icon. Without an accent, it is transparent, as the alpha of `transparent` is 0.
						.dropShadow(Shadow(y: .pixels(10), blur: .pixels(24), color: Color.accent.value(default: .transparent).opacity(0.5)))
					)
					.from(.smallTablet) {
						$0.frame(width: .rootEm(11), height: .rootEm(11))
					}
			case .title:
				Style()
					.margin(.bottom, .rootEm(0.75))
					.textStyle(.largeTitle)
					.color(.primaryText)
			case .subtitle:
				Style()
					.frame(maxWidth: .rootEm(36))
					.margin(.horizontal, .auto)
					.font(size: .clamp(.rootEm(1.25), .viewportWidth(3), .rootEm(1.5)), lineHeight: 1.3)
					.fontWeight(.medium)
					.letterSpacing(.em(-0.01))
					.color(.primaryText)
					.textWrap(.balance)
					.declaration(.hangingPunctuation, "first last")
			case .introduction:
				Style()
					.frame(maxWidth: .rootEm(40))
					.margin(top: .rootEm(1), horizontal: .auto, bottom: 0)
					.textStyle(.lead)
					.color(.secondaryText)
					.textLinks()
			case .anotherRandomApp:
				Style()
					.hidden()
					.justifyContent(.center)
					.nested(":target &") {
						$0.display(.flex)
					}
			case .anotherRandomAppButton:
				Style().margin(.top, .rootEm(1.5))
			case .shareTitle:
				Style()
					.fontWeight(.semibold)
					.color(.primaryText)
			case .dialog:
				// The browser centers a popover with the auto margins, which the reset removes. It closes with the Escape key or a click outside.
				Style()
					.popoverOpen {
						$0.vstack(alignment: .center, spacing: .rootEm(1))
					}
					.margin(.auto)
					.frame(maxWidth: .rootEm(18))
					.padding(.rootEm(1.5))
					.cornerRadius(.rootEm(1))
					.popoverSurface()
					.secondaryText()
					.textAlign(.center)
					.backdrop {
						$0.background(.black.opacity(0.3))
					}
			case .qrCodeImage:
				Style()
					.frame(width: .pixels(176), height: .pixels(176))
					.padding(.pixels(8))
					.cornerRadius(.rootEm(0.5))
					.color(.gray(900))
					.background(.white)
			case .archivedBadge:
				// Below the introduction, which says why the app is archived.
				Style()
					.margin(.top, .rootEm(1))
					.setting(Badge.fontSize, to: .pixels(16))
			case .downloads:
				Style()
					.margin(.top, .rootEm(1))
					.textStyle(.caption)
					.monospacedDigit()
			case .downloadCount:
				Style()
					.fontWeight(.semibold)
					.color(.bodyText)
			case .downloadLabel:
				Style()
					.color(.secondaryText)
			case .details:
				Style()
					.margin(.top, .rootEm(1))
					.textStyle(.caption)
					.monospacedDigit()
					.color(.secondaryText)
			}
		}
	}
}

/**
The end of an app page, for visitors who read the whole page: the icon, the name, the download options, and the price.
*/
struct AppCallToAction: HTML {
	let app: App

	/**
	The App Store info, for the price.
	*/
	let info: AppStoreInfo?

	var body: some HTML<HTMLTag.section> {
		section {
			AppIcon(decorative: app, size: 128)
				.style(Styles.icon)

			h2 {
				"Get \(app.title)"
			}
			.style(Styles.title)

			p {
				app.subtitle
			}
			.style(Styles.subtitle)

			DownloadOptions(app: app)

			if let price = app.priceText(info: info) {
				p {
					price
				}
				.style(Styles.price)
			}
		}
		.style(Styles.root)
	}

	enum Styles: StyleSet {
		case root
		case icon
		case title
		case subtitle
		case price

		var style: Style {
			switch self {
			case .root:
				// A panel, so the end of the page stands out from the text above it.
				Style()
					.frame(maxWidth: .rootEm(48))
					.margin(.horizontal, .auto)
					.vstack(alignment: .center)
					.padding(vertical: .rootEm(3), horizontal: .rootEm(1.5))
					.background(.card)
					.cornerRadius(.panelRadius)
					.textAlign(.center)
					.from(.smallTablet) {
						$0.padding(vertical: .rootEm(4), horizontal: .rootEm(2))
					}
					// Below tablets, the panel is as wide as the screen, so it has no corners at its edges.
					.below(.tablet) {
						$0.cornerRadius(0)
					}
			case .icon:
				Style()
					.frame(width: .rootEm(5.25), height: .rootEm(5.25))
					.filter(.dropShadow(Shadow(y: .pixels(4), blur: .pixels(10), color: .black.opacity(0.12))))
			case .title:
				Style()
					.margin(.top, .rootEm(1))
					.textStyle(.title)
					.color(.primaryText)
			case .subtitle:
				Style()
					.margin(top: .rootEm(0.5), horizontal: 0, bottom: .rootEm(1.5))
					.font(size: .rootEm(1.0625), lineHeight: 1.5)
					.color(.secondaryText)
			case .price:
				Style()
					.margin(.top, .rootEm(1))
					.secondaryText()
			}
		}
	}
}
