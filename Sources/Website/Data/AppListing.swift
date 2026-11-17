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
	The product of an app that is sold on Gumroad, for its rating. Its reviews are in ``storeReviews``.
	*/
	var gumroadProduct: GumroadProduct?

	/**
	The rating on Setapp of an app that is on Setapp, which the page shows when the app has no other rating (``rating(at:)``).
	*/
	var setappRating: SetappRating?

	/**
	The recent five-star reviews on the App Store, or on Gumroad for an app that is sold there, newest first, also the ones that ``reviews`` leaves out.
	*/
	var storeReviews = [StoreReview]()

	/**
	The recent five-star reviews (``storeReviews``), newest first. For a paid app, reviews that call it free are left out, as they were written while it was free and would confuse visitors about the price.
	*/
	var reviews: [StoreReview] {
		storeReviews.filter { review in
			!(app.isPaid && review.callsAppFree)
		}
	}

	/**
	The published releases, newest first, like on the release notes page. Empty for an app without release notes, like an archived app.
	*/
	var releases = [GitHubRelease]()

	/**
	The number of updates on the release notes: the releases after the day that the app was published, as the first release is not an update. It does not count on the first release, as a repo can start with a later version, like 1.1.0.
	*/
	var updateCount: Int {
		releases.count { SOML.Date($0.publishedAt) > app.publicationDate }
	}

	/**
	The number of free updates of a paid app with release notes (``updateCount``), like 52 for Supercharge, as it shows that the one-time price includes the work that came later. `nil` for a free app, which has only free updates, and for an app without release notes or updates.
	*/
	var freeUpdateCount: Int? {
		guard
			app.isPaid,
			app.releaseNotes != nil,
			updateCount > 0
		else {
			return nil
		}

		return updateCount
	}

	/**
	The four newest reviews, which the app page shows. They fill two rows of two, so none is alone in a row. The wall of love has more.
	*/
	var newestReviews: [StoreReview] {
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
	The lowest OS version (``minimumOSVersion``) with the platforms, like “macOS 26 or later”. An app on several platforms names them once, like “macOS, iOS, or visionOS 26 or later”, as the platforms share their version numbers.
	*/
	var requirement: OSRequirement? {
		minimumOSVersion.map { OSRequirement(platforms: app.platforms, version: $0) }
	}

	/**
	The trial card of the app (``App/Frontmatter/trialCard``) for the trial dialog, which covers the requirement of the hero, so the card shows it next to its button when the trial has no requirement of its own. A trial that is a download is only for the Mac, so it says only macOS, like “Requires macOS 27 or later”.
	*/
	var trialCard: AppDownloadCard? {
		guard
			var card = app.frontmatter.trialCard,
			let trial = app.frontmatter.trial
		else {
			return nil
		}

		let appRequirement = trial.isMacOnly ? minimumOSVersion.map(OSRequirement.macOS) : requirement
		card.requirement = card.requirement ?? appRequirement?.sentence
		return card
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
	The platforms and the requirement as one fact (``requirement``), like “Requires macOS, iOS, or visionOS 26 or later”, or only the platforms when the requirement is unknown, like “Available on macOS and iOS”.
	*/
	var availabilityFact: String {
		requirement?.sentence ?? "Available on \(app.platforms.map(\.rawValue).formattedList(.and))"
	}

	/**
	The rating that the page shows after at least ten ratings and one whole year since publication: on the App Store (of the iPhone and the Mac version together for a universal app), or on Gumroad for an app that is sold there, or else on Setapp, like for an app that has no ratings on a store. One source is enough, and the stores come before Setapp. The structured data has the same rating, as it must be visible on the page. Archived apps have no information section, so their rating is not shown.
	*/
	func rating(at date: Date) -> AppRating? {
		guard
			!app.isArchived,
			let rating = storeRating.map(AppRating.store) ?? setappRating.map(AppRating.setapp),
			rating.count >= 10,
			date.wholeYears(since: app.publicationDate.foundationDate) >= 1
		else {
			return nil
		}

		return rating
	}

	/**
	The fetched rating on a store, before the visibility rules of ``rating(at:)``: on the App Store, or else on Gumroad for an app that is sold there.
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
	The price as text, like “$10”, or `nil` when the download is free or the price is unknown, for a place that shows a price only for an app that costs money, like `apps.json`.
	*/
	var paidPriceText: String? {
		price.flatMap { $0.isFree ? nil : $0.formatted }
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
	Whether a family can share the purchase of the app with Family Sharing: an app with a price on the App Store. Not an app that is free to download with an in-app purchase, as the developer sets Family Sharing for each in-app purchase.
	*/
	var hasFamilySharing: Bool {
		guard case .appStore(let price) = resolvedPrice else {
			return false
		}

		return !price.isFree
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
		(appStoreVersionDate ?? appcast?.releaseDate ?? releases.map(\.publishedAt).max()).map { max(SOML.Date($0), app.publicationDate) }
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

	/**
	The size of the download (``fileSize``) as text, like “6 MB” or “2.87 GB”, in whole megabytes below a gigabyte. A universal app has the size of each version, as they are often far apart, like “2.87 GB on Mac” and “1.84 GB on iPhone and iPad” for Aiko, with the Mac first, as most visitors use a Mac. Empty when the size is unknown.
	*/
	var fileSizeTexts: [String] {
		func text(_ size: Int64) -> String {
			// From 999.5 MB, which would round to “1000 MB”.
			guard size >= 999_500_000 else {
				return "\((Double(size) / 1_000_000).formatted(.number.grouping(.never).locale(.site).precision(.fractionLength(0)))) MB"
			}

			return size.formatted(.siteFileSize)
		}

		guard let fileSize else {
			return []
		}

		guard let iOSFileSize = appStoreInfo?.iOSFileSize else {
			return [text(fileSize)]
		}

		return [
			"\(text(fileSize)) on Mac",
			"\(text(iOSFileSize)) on iPhone and iPad",
		]
	}

	/**
	The size of the app as the Size fact of its page and its Markdown copy show it: the size of the download (``fileSizeTexts``), and then the model that the app downloads at its first launch (`downloadedModelSize`), like “66 MB” and “plus the 16 GB model” for Imago, as a visitor with little free space must see the large download before the purchase. Empty when the size of the download is unknown.
	*/
	var sizeLines: [String] {
		guard !fileSizeTexts.isEmpty else {
			return []
		}

		return fileSizeTexts + [app.frontmatter.downloadedModelSize.map { "plus the \(Int64($0.value).formatted(.siteFileSize)) model" }].compactMap(\.self)
	}
}

/**
The rating that an app page shows (``AppListing/rating(at:)``): an average of stars on a store, or the percentage of positive ratings on Setapp.
*/
enum AppRating {
	case store(StoreRating)
	case setapp(SetappRating)

	/**
	The number of ratings on the selected source.
	*/
	var count: Int {
		switch self {
		case .store(let rating):
			rating.count
		case .setapp(let rating):
			rating.count
		}
	}

	/**
	The source of the rating, like “Gumroad rating”, which the facts of the app page and its Markdown copy show before the value (``value``).
	*/
	var label: String {
		switch self {
		case .store(let rating):
			switch rating.store {
			case .appStore:
				"US App Store rating"
			case .gumroad:
				"Gumroad rating"
			}
		case .setapp:
			"Setapp rating"
		}
	}

	/**
	The rating with the number of ratings, like “4.8/5 (120 ratings)”, or “99% positive (878 ratings)” on Setapp.
	*/
	var value: String {
		switch self {
		case .store(let rating):
			"\(rating.formattedAverage)/5 (\(rating.count.formatted(counting: "rating")))"
		case .setapp(let rating):
			"\(rating.formattedPercentage) positive (\(rating.count.formatted(counting: "rating")))"
		}
	}
}
