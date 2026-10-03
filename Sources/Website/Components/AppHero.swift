import Elementary
import SiteKit

/**
The top of an app page: the icon, the name, the subtitle, the download buttons, and the links.
*/
struct AppHero: HTML {
	let app: App

	/**
	The price from the App Store, like “$4.99, one-time purchase”.
	*/
	let price: String?

	var body: some HTML {
		header(.id(Self.id)) {
			AppIcon(app, size: 256, isAboveFold: true, morphsAcrossPages: true)
				.attributes(.id(.appIcon))
				.style(Styles.icon)

			h1 {
				app.title
			}
			.style(Styles.title)

			p {
				app.subtitle
			}
			.style(Styles.subtitle)

			// Shown when coming from the random app page, which links to `#another-random-app`.
			div {
				Button(destination: RoutePath.randomApp.description, fill: .gradient) {
					Label("Another Random App", icon: .shuffle)
				}
				.style(Styles.anotherRandomAppButton)
			}
			.style(Styles.anotherRandomApp)

			if app.isArchived {
				div {
					Badge("archived", kind: .archived)
				}
				.style(Styles.archivedBadge)
			}

			DownloadOptions(app: app)

			if let downloads = app.downloads {
				p {
					span {
						downloads.abbreviatedCount
					}
					.style(Styles.downloadCount)

					span {
						" downloads"
					}
					.style(Styles.downloadLabel)
				}
				.style(Styles.downloads)
			}

			if let price {
				p {
					price
				}
				.style(Styles.price)
			}

			// On a computer, a QR code opens the App Store page of an iPhone app on the phone. Apple Watch apps are installed from the iPhone too, so they count, unlike for the App Store banner, which is only for apps that run on the device.
			if
				app.platforms.contains(where: [.iOS, .watchOS, .visionOS].contains),
				let url = app.appStoreURL(placement: "qr-code")
			{
				figure {
					QRCode(url: url, label: "QR code that opens \(app.title) on the App Store")
						.style(Styles.qrCodeImage)

					figcaption {
						"Scan with your iPhone"
					}
				}
				.style(Styles.qrCode)
			}

			AppLinks(app: app)
		}
		.style(Styles.root)
	}

	/**
	The ID of the hero, which the “Get” button of the header links to.
	*/
	static let id = "app-hero"

	/**
	The view timeline of the hero, for the header that changes when it scrolls away.
	*/
	static let timeline = "--app-hero"

	/**
	The end of the hero scrolling out of view at the top.
	*/
	static let scrolledAwayRange = "exit 85% exit 100%"

	enum Styles: StyleSet {
		case root
		case icon
		case title
		case subtitle
		case anotherRandomApp
		case anotherRandomAppButton
		case qrCode
		case qrCodeImage
		case archivedBadge
		case downloads
		case downloadCount
		case downloadLabel
		case price

		var style: Style {
			switch self {
			case .root:
				Style()
					.viewTimeline(AppHero.timeline)
					// For the 3D tilt of the icon in `app.js`.
					.declaration(.perspective, .px(800))
					.vstack(alignment: .center)
					.margin(.bottom, .rem(10))
					.padding(.horizontal, .rem(1))
					.textAlign(.center)
					.breakpoint(.sm) {
						$0.padding(.horizontal, .rem(1.5))
					}
			case .icon:
				Style()
					.declaration(.willChange, "transform, filter")
					.margin(.bottom, .rem(0.75))
					.padding(.px(16))
					.dropShadow(Shadow(y: .px(1), blur: .px(2), color: "rgb(0 0 0 / 15%)")).dropShadow(Shadow(y: .px(4), blur: .px(10), color: "rgb(0 0 0 / 10%)")).dropShadow(Shadow(y: .px(12), blur: .px(28), color: "rgb(0 0 0 / 7%)"))
			case .title:
				Style()
					.margin(.bottom, .rem(1))
					.font(.xl5, weight: .bold)
					.fluidFontSize(fromRem: 3, toRem: 4.5, between: .sm, and: .md)
					.letterSpacing(.em(-0.025))
			case .subtitle:
				Style()
					.frame(maxWidth: .rem(42))
					.margin(top: 0, horizontal: .auto, bottom: .rem(2))
					.font(.xl2, weight: .regular)
					.letterSpacing(.em(-0.025))
					.color(.bodyText)
					.textWrap(.pretty)
					.declaration("hanging-punctuation", "first last")
					.breakpoint(.md) {
						$0.font(.xl4)
					}
			case .anotherRandomApp:
				Style()
					.hidden()
					.justifyContent(.center)
					.nested(":target &") {
						$0.display(.flex)
					}
			case .anotherRandomAppButton:
				Style().margin(.bottom, .rem(1.5))
			case .qrCode:
				// Only on larger screens with a mouse, as on a phone, the download button is right there.
				Style()
					.hidden()
					.media(.minWidth(Breakpoint.md.minimumWidth) && .hover) {
						$0.vstack(alignment: .center, spacing: .rem(0.5))
					}
					.margin(.top, .rem(1.5))
					.font(.xs)
					.color(.secondaryText)
			case .qrCodeImage:
				Style()
					.frame(width: .px(88), height: .px(88))
					.padding(.px(6))
					.cornerRadius(.rem(0.5))
					.color(.gray(900))
					.background(.white)
					.dark {
						$0.border(.white.opacity(0.1))
					}
			case .archivedBadge:
				Style()
					.margin(.bottom, .rem(2.5))
					.setting(Badge.fontSize, to: .px(16))
			case .downloads:
				Style()
					.margin(.top, .rem(1))
					.font(.sm)
					.monospacedDigit()
			case .downloadCount:
				Style()
					.fontWeight(.semibold)
					.color(.gray(700), dark: .gray(200))
			case .downloadLabel:
				Style()
					.color(.gray(400), dark: .gray(500))
			case .price:
				Style()
					.margin(.top, .rem(0.5))
					.font(.sm)
					.color(.secondaryText)
			}
		}
	}
}
