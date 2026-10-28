import Foundation
import SiteKit
import SOML

/**
An app with the data that the build fetched for it, like its App Store info and its appcast (``SiteContent/listing(of:)``). The values that come from several sources, like the requirement and the price, are on it, so no part of a page can get them from only some of the sources.
*/
struct AppListing {
	let app: App
	var appStoreInfo: AppStoreInfo?

	/**
	The appcast of an app that is not on the App Store (``App/appcastURL``), for its requirement, its version, and the size of its download.
	*/
	var appcast: Appcast?

	/**
	The product of an app that is sold on Gumroad, for its rating.
	*/
	var gumroadProduct: GumroadProduct?

	/**
	The rating on Setapp of an app that is on Setapp, which the page shows when the app has no other rating (``rating``).
	*/
	var setappRating: SetappRating?

	/**
	The recent five-star App Store reviews, newest first, also the ones that ``reviews`` leaves out.
	*/
	var appStoreReviews = [AppStoreReview]()

	/**
	The recent five-star App Store reviews, newest first. For a paid app, not the reviews that call it free, which were written while it was free, as they would confuse visitors about the price.
	*/
	var reviews: [AppStoreReview] {
		app.isPaid ? appStoreReviews.filter { !$0.callsAppFree } : appStoreReviews
	}

	/**
	The published releases, newest first, like on the release notes page. Empty for an app without release notes, like an archived app.
	*/
	var releases = [GitHubRelease]()

	/**
	The four newest reviews, which the app page shows. They fill two rows of two, so none is alone in a row. The wall of love has more.
	*/
	var newestReviews: [AppStoreReview] {
		Array(reviews.prefix(4))
	}

	/**
	The lowest OS version that the app runs on, like `26.1`, from the first of these that has it:

	1. The App Store, which is the version that people get. It has the version of one platform (``AppStoreInfo/minimumOSVersion``), which is the version of all the platforms of the app, as they share their version numbers from 26. A lower version is only for its platform, so it is not used.
	2. The appcast of an app that is not on the App Store (``App/appcastURL``), which is the version of its latest release. It is the macOS version, as Sparkle is only for the Mac, so it can be below 26.
	3. `minimumOSVersion`, like for an app that is not released yet, or an app that is not on the App Store and has no appcast.
	*/
	var minimumOSVersion: OSVersion? {
		fetchedMinimumOSVersion ?? app.frontmatter.minimumOSVersion
	}

	/**
	The lowest OS version of the App Store or the appcast (``minimumOSVersion``), which the page shows instead of `minimumOSVersion`.
	*/
	var fetchedMinimumOSVersion: OSVersion? {
		if
			let version = appStoreInfo?.minimumOSVersion,
			version.major >= App.firstSharedOSVersion
		{
			return version
		}

		return appcast?.minimumSystemVersion
	}

	/**
	The lowest OS version (``minimumOSVersion``) as a sentence, like “Requires macOS 26 or later”. An app on several platforms says “version”, as the platforms share their version numbers.
	*/
	var requirementSentence: String? {
		minimumOSVersion?.requirementSentence(for: app.platforms)
	}

	/**
	The older version (``App/olderVersions``) for a visitor on the macOS version: the one for that version, or for a free app, the newest one for an older macOS version, when the current version of the app (``minimumOSVersion``) does not run on that version either. The older versions of a paid app only run on their own macOS version.
	*/
	func olderVersion(for macOS: MacOSVersion) -> App.OlderVersion? {
		if let olderVersion = app.olderVersions.first(where: { $0.macOS == macOS }) {
			return olderVersion
		}

		guard
			!app.isPaid,
			let minimumOSVersion,
			macOS.osVersion < minimumOSVersion
		else {
			return nil
		}

		// The older versions are newest first.
		return app.olderVersions.first { $0.macOS.osVersion < macOS.osVersion }
	}

	/**
	The lowest version of each platform, like “macOS 26 or later, iOS 26 or later”, for places without the platforms next to it, like the facts at the end of the page and the structured data.
	*/
	var minimumVersionsByPlatform: String? {
		minimumOSVersion.map { version in
			app.platforms.map { "\($0.rawValue) \(version) or later" }.joined(separator: ", ")
		}
	}

	/**
	The platforms and the requirement, as two facts, like “Available on macOS, iOS, and visionOS” and “Requires version 26 or later”. The platforms are left out when the requirement already names the one platform, like “Requires macOS 26 or later”.
	*/
	var availabilityFacts: [String] {
		let platformList = requirementSentence != nil && app.platforms.count == 1 ? nil : "Available on \(app.platforms.map(\.rawValue).formatted(.list(type: .and).locale(.site)))"
		return [platformList, requirementSentence].compactMap(\.self)
	}

	/**
	The rating that the page shows: on the App Store, or on Gumroad for an app that is sold there, or else on Setapp, like for a Mac App Store app, as Apple gives no ratings for them. One source is enough, and the stores come before Setapp, as the structured data has their rating, which must be visible on the page, and Setapp cannot be in it (``SetappRating``).
	*/
	var rating: AppRating? {
		storeRating.map(AppRating.store) ?? setappRating.map(AppRating.setapp)
	}

	/**
	The rating on a store, which the page shows (``rating``) and the structured data has: on the App Store, or else on Gumroad for an app that is sold there.
	*/
	var storeRating: StoreRating? {
		appStoreInfo?.rating ?? gumroadProduct?.rating
	}

	/**
	The price, which the page shows (``priceText``) and the structured data offers: on the App Store, or else the price of `gumroad` in the frontmatter, or else free for an app that is not paid.
	*/
	var price: Price? {
		resolvedPrice?.value
	}

	/**
	Where the resolved price comes from, so its wording follows the same precedence as its amount.
	*/
	private enum ResolvedPrice {
		case appStore(Price)
		case gumroad(Price)
		case free

		/**
		The price carried by its source, or zero for a free fallback.
		*/
		var value: Price {
			switch self {
			case .appStore(let price), .gumroad(let price):
				price
			case .free:
				.free
			}
		}
	}

	/**
	The price together with its source: App Store, Gumroad, or free when the app is not paid.
	*/
	private var resolvedPrice: ResolvedPrice? {
		if let price = appStoreInfo?.price {
			return .appStore(price)
		}

		if let price = app.purchase.gumroad?.price {
			return .gumroad(price)
		}

		return app.isPaid ? nil : .free
	}

	/**
	The price for the app page (``price``), like “$4.99, one-time purchase” or “Free”. A paid app that is free to download has an in-app purchase. A universal purchase says that the purchase is for all the platforms, like “$4.99, one-time purchase for all platforms”. Gumroad adds tax at checkout where it must, like VAT in the EU and the UK and sales tax in some US states, so its price says “plus tax where applicable”.
	*/
	var priceText: String? {
		guard let resolvedPrice else {
			return nil
		}
		let price = resolvedPrice.value

		let text = if price.isFree {
			app.isPaid ? "Free to download, with an in-app purchase" : "Free"
		} else if case .gumroad = resolvedPrice {
			// The price of `gumroad`, as a paid price that is not from the App Store is from Gumroad.
			"\(price.oneTimePurchaseText), plus tax where applicable"
		} else {
			price.oneTimePurchaseText
		}

		return app.isUniversalPurchase ? "\(text) for all platforms" : text
	}

	/**
	A dated version from the App Store or the app's release notes. The caller decides whether it counts as a launch or an update.
	*/
	struct VersionRelease {
		let app: App
		let version: String
		let date: Date
		let destination: LinkDestination
	}

	/**
	The latest dated version from each source, without applying a page's launch or date filters.
	*/
	var versionReleases: [VersionRelease] {
		let release = app.releaseNotes.flatMap { releaseNotes in
			releases.sorted(using: KeyPathComparator(\.publishedAt, order: .reverse)).first.map {
				VersionRelease(
					app: app,
					version: $0.version,
					date: $0.publishedAt,
					destination: releaseNotes.destination(of: $0)
				)
			}
		}
		let appStoreVersion = appStoreInfo.flatMap { info in
			info.version.flatMap { version in
				info.currentVersionReleaseDate.map {
					VersionRelease(
						app: app,
						version: version,
						date: $0,
						destination: app.url
					)
				}
			}
		}

		return [release, appStoreVersion].compactMap(\.self)
	}

	/**
	The App Store's current-version date, also when its version string is unavailable. Annual metrics only need the date.
	*/
	var appStoreVersionDate: Date? {
		appStoreInfo?.currentVersionReleaseDate
	}

	/**
	The calendar date when the current version was released: on the App Store, or else in the appcast, or else the newest release on GitHub, but never before the app was published, as an app can launch on the App Store a day before its page.
	*/
	var currentVersionDate: SOML.Date? {
		(appStoreInfo?.currentVersionReleaseDate ?? appcast?.releaseDate ?? releases.map(\.publishedAt).max()).map { max(SOML.Date($0), app.publicationDate) }
	}

	/**
	The current version, like `1.30.1`: on the App Store, or else in the appcast.
	*/
	var version: String? {
		appStoreInfo?.version ?? appcast?.version
	}

	/**
	The size of the download of the current version in bytes: on the App Store, or else in the appcast.
	*/
	var fileSize: Int64? {
		appStoreInfo?.fileSize ?? appcast?.fileSize
	}
}

/**
The rating that an app page shows (``AppListing/rating``): an average of stars on a store, or the percentage of positive ratings on Setapp.
*/
enum AppRating {
	case store(StoreRating)
	case setapp(SetappRating)

	/**
	The large number, like “4.6” or “99%”.
	*/
	var formattedScore: String {
		switch self {
		case .store(let rating):
			rating.formattedAverage
		case .setapp(let rating):
			rating.formattedPercentage
		}
	}

	/**
	The validated star average for the stars below the number. `nil` for Setapp, which has no stars.
	*/
	var storeRating: StoreRating? {
		switch self {
		case .store(let rating):
			rating
		case .setapp:
			nil
		}
	}

	/**
	The number of ratings and the store, like “565 ratings on the App Store”.
	*/
	var countText: String {
		switch self {
		case .store(let rating):
			rating.countText
		case .setapp(let rating):
			rating.countText
		}
	}

	/**
	The rating as a sentence, for screen readers.
	*/
	var text: String {
		switch self {
		case .store(let rating):
			rating.text
		case .setapp(let rating):
			rating.text
		}
	}
}
