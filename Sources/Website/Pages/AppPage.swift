import Elementary
import Foundation
import SiteKit

struct AppPage: Page {
	let app: App
	let content: SiteContent

	var path: RoutePath {
		app.path
	}

	var navigation: SiteHeader.Variant {
		.app(app)
	}

	var lastModified: Date? {
		max(app.lastCommitDate ?? app.publicationDate, app.publicationDate)
	}

	/**
	The icon and the screenshots.
	*/
	var sitemapImages: [URL] {
		[app.iconURL] + app.screenshotURLs
	}

	var metadata: PageMetadata {
		PageMetadata(
			title: PageMetadata.titled("\(app.title): \(app.subtitle)"),
			description: app.description,
			socialTitle: app.title,
			kind: .product,
			image: PageMetadata.SocialImage(path: OpenGraphCard.path(for: app), description: "\(app.title) app"),
			appStoreID: showsAppStoreBanner ? app.appStoreID : nil,
			appStoreCampaign: app.appStoreBannerCampaign,
			favicon: app.iconPath,
			feeds: app.releaseNotes.map { [$0.feed] } ?? []
		)
	}

	/**
	Safari shows the banner on iOS, so only apps that run there get it.
	*/
	private var showsAppStoreBanner: Bool {
		!app.isArchived && app.platforms.contains { $0 == .iOS || $0 == .visionOS }
	}

	var body: some HTML {
		section {
			// The random app page links to `#another-random-app`, which shows the “Another Random App” button. The ID is at the top, so the page does not scroll.
			article(.id(.anotherRandomApp)) {
				AppHero(app: app, price: content.appStoreInfo(of: app)?.priceText(isPaid: app.isPaid))

				if let availability = app.availabilityText {
					p {
						availability
					}
					.style(Styles.availability)
				}

				if let announcement = app.announcement {
					AnnouncementBanner(announcement: announcement)
				}

				AppMedia(app: app)

				if !app.pressQuotes.isEmpty {
					PressQuotes(quotes: app.pressQuotes)
				}

				let reviews = content.appStoreReviews(of: app)

				if !reviews.isEmpty {
					AppReviews(reviews: reviews)
				}

				Prose(html: app.markdown.html)
				RelatedApps(relatedApps: app.relatedApps(from: content.activeApps, on: content.buildDate))
			}
		}
		.style(Styles.root)

		JSONScript(schema: structuredData)
		ModuleScript("/scripts/app.js")

		if let script = app.script {
			ModuleScript(script.description)
		}
	}

	private var structuredData: Schema.SoftwareApplication {
		var application = Schema.SoftwareApplication(
			name: app.title,
			description: app.description,
			url: app.path.absoluteURL(site: Site.url),
			applicationCategory: app.schemaCategory,
			operatingSystem: app.operatingSystems,
			author: .author,
			datePublished: app.publicationDate.isoDay,
			image: app.iconURL
		)

		application.screenshot = app.screenshotURLs.isEmpty ? nil : app.screenshotURLs

		if
			let info = content.appStoreInfo(of: app),
			let appStoreURL = app.appStoreURL
		{
			application.downloadUrl = appStoreURL
			application.softwareVersion = info.version

			if let price = info.price, let currency = info.currency {
				application.offers = Schema.Offer(url: appStoreURL, seller: .authorName, price: price, priceCurrency: currency)
			}

			if
				let count = info.userRatingCount,
				count > 0,
				let rating = info.averageUserRating
			{
				application.aggregateRating = Schema.AggregateRating(ratingValue: (rating * 10).rounded() / 10, ratingCount: count)
			}
		}

		return application
	}
}

extension AppPage {
	enum Styles: StyleSet {
		case root
		case availability

		var style: Style {
			switch self {
			case .root:
				Style()
					.frame(maxWidth: .rem(64))
					.margin(top: 0, horizontal: .auto, bottom: .rem(2.5))
					.pagePadding()
					.breakpoint(.lg) {
						$0.margin(.top, .rem(-2.5))
					}
			case .availability:
				Style()
					.margin(top: .rem(-6), horizontal: 0, bottom: .rem(8))
					.font(.sm)
					.textAlign(.center)
					.color(.gray(500))
			}
		}
	}
}
