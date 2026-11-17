import Foundation
import SiteKit

/**
The ID of an app on the App Store, like 1607635845 in `https://apps.apple.com/app/id1607635845`.
*/
struct AppStoreID: Hashable, CustomStringConvertible, ExpressibleByIntegerLiteral {
	let value: Int

	/**
	A positive, code-owned App Store ID. Use `init(validating:)` for untrusted numbers.
	*/
	init(_ value: Int) {
		precondition(value > 0, "An App Store ID must be positive.")
		self.value = value
	}

	init(integerLiteral value: Int) {
		self.init(value)
	}

	var description: String {
		String(value)
	}

	/**
	The App Store page of the app.
	*/
	var url: URL {
		#URL("https://apps.apple.com/app").appending(path: "id\(value)")
	}

	/**
	The App Store page with the query of its placement on the website (``App/AppStorePlacement/queryItems``), or the plain link when the placement has none.
	*/
	func url(placement: App.AppStorePlacement) -> URL {
		let queryItems = placement.queryItems

		guard !queryItems.isEmpty else {
			return url
		}

		return url.appending(queryItems: queryItems)
	}
}

extension AppStoreID: Encodable {
	func encode(to encoder: any Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(value)
	}
}

extension AppStoreID: ValidatedValue {
	init(validating rawValue: Int) throws(ContentError) {
		guard rawValue > 0 else {
			throw ContentError(reason: "Must be a positive number, like `1607635845`, got \(rawValue).")
		}

		self.init(rawValue)
	}
}

/**
The App Store info of an app, like the price and rating, from the US App Store.

The App Store has a record for each platform of an app. The plain lookup gives the iPhone record of an app that is also a native Mac app (a universal app), and the record of a Mac app without its ratings. The lookup of Mac apps (`entity=desktopSoftware`) gives the Mac records with their ratings. ``lookup(ids:cache:)`` combines them (``adding(macRecord:)``).
*/
struct AppStoreInfo: Decodable {
	let id: AppStoreID

	/**
	The current version, of the Mac version for a universal app.
	*/
	private(set) var version: String?

	/**
	When the current version was released, of the Mac version for a universal app.
	*/
	private(set) var currentVersionReleaseDate: Date?

	/**
	The price to download the app, with its currency.
	*/
	let price: Price?

	/**
	The rating, when the app has ratings. For a universal app, the ratings of the iPhone and the Mac version together.
	*/
	private(set) var rating: StoreRating?

	/**
	The kind of app of the result. The IDs of apps, songs, and books are one number space, so the lookup of an ID with a typo can find a song, like `La patience de Winnie` for an ID of Dato with two digits swapped. `nil` for a result that is not an app.
	*/
	enum Kind: String {
		/**
		An iPhone, iPad, or Apple Vision app, which may also run on the Mac.
		*/
		case software

		/**
		A native Mac app.
		*/
		case macSoftware = "mac-software"
	}

	let kind: Kind?

	/**
	Whether the App Store lists a native Mac app (`mac-software`), rather than an iPhone, iPad, or Apple Vision app that may also run on the Mac.
	*/
	var isMacApp: Bool {
		kind == .macSoftware
	}

	/**
	The lowest version of macOS for Mac apps and universal apps, of visionOS for Apple Vision apps, or else of iOS, like `26.0`.
	*/
	private(set) var minimumOSVersion: OSVersion?

	/**
	The platforms that the App Store lists for the app, decoded from device strings like `iPhone5s-iPhone5s` and `MacDesktop-MacDesktop`. It does not list where iPad apps also run, like on Apple Vision and Macs with Apple silicon. An app with a Mac record also has macOS (``adding(macRecord:)``).
	*/
	private(set) var listedPlatforms: Set<Platform>

	/**
	The download size in bytes, decoded from the text of `fileSizeBytes`, like `"19244046"`, of the Mac version for a universal app.
	*/
	private(set) var fileSize: Int64?

	/**
	The download size in bytes of the iPhone and iPad version of a universal app, which is often another size than the Mac version (``fileSize``), like 1.84 GB and 2.87 GB for Aiko. `nil` for an app with one version.
	*/
	private(set) var iOSFileSize: Int64?

	/**
	The main category of the app on the App Store, like `Developer Tools`.
	*/
	let primaryGenreName: String?

	/**
	The bundle identifier of the App Store version of the app, like `com.sindresorhus.Dato`. The Setapp version has another one, like `com.sindresorhus.Dato-setapp`.
	*/
	let bundleIdentifier: String?

	enum CodingKeys: String, CodingKey {
		case id = "trackId"
		case version
		case currentVersionReleaseDate
		case priceAmount = "price"
		case currencyCode = "currency"
		case averageUserRating
		case userRatingCount
		case kind
		case minimumOSVersion = "minimumOsVersion"
		case supportedDevices
		case fileSizeBytes
		case primaryGenreName
		case bundleIdentifier = "bundleId"
	}

	init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		self.id = try container.decode(AppStoreID.self, forKey: .id)
		self.version = try container.decodeIfPresent(String.self, forKey: .version)
		self.currentVersionReleaseDate = try container.decodeIfPresent(Date.self, forKey: .currentVersionReleaseDate)

		let priceAmount = try container.decodeIfPresent(Decimal.self, forKey: .priceAmount)
		let currencyCode = try container.decodeIfPresent(String.self, forKey: .currencyCode)
		self.price = if
			let priceAmount,
			let currencyCode
		{
			try? Price(amount: priceAmount, currency: Locale.Currency(currencyCode))
		} else {
			nil
		}

		let average = try container.decodeIfPresent(Double.self, forKey: .averageUserRating)
		let count = try container.decodeIfPresent(Int.self, forKey: .userRatingCount)
		self.rating = if
			let average,
			let count
		{
			StoreRating(average: average, count: count, store: .appStore)
		} else {
			nil
		}

		self.kind = try container.decodeIfPresent(String.self, forKey: .kind).flatMap(Kind.init(rawValue:))
		self.minimumOSVersion = (try? container.decode(String.self, forKey: .minimumOSVersion)).flatMap(OSVersion.init)
		let devices = try container.decodeIfPresent([String].self, forKey: .supportedDevices) ?? []
		var platforms = Set<Platform>()

		if kind == .macSoftware || devices.contains(where: { $0.hasPrefix("MacDesktop") }) {
			platforms.insert(.macOS)
		}

		if devices.contains(where: { $0.hasPrefix("iPhone") || $0.hasPrefix("iPad") }) {
			platforms.insert(.iOS)
		}

		if devices.contains(where: { $0.hasPrefix("AppleVisionPro") }) {
			platforms.insert(.visionOS)
		}

		self.listedPlatforms = platforms
		self.fileSize = try container.decodeIfPresent(String.self, forKey: .fileSizeBytes).flatMap(Int64.init)
		self.primaryGenreName = try container.decodeIfPresent(String.self, forKey: .primaryGenreName)
		self.bundleIdentifier = try container.decodeIfPresent(String.self, forKey: .bundleIdentifier)
	}

	/**
	The App Store category as a category of structured data, like `DeveloperApplication` for `Developer Tools`, from the list that Google supports. `nil` for a category without a match, like `Productivity`.
	*/
	var schemaApplicationCategory: Schema.SoftwareApplication.Category? {
		switch primaryGenreName {
		case "Developer Tools":
			.developer
		case "Graphics & Design":
			.design
		case "Photo & Video", "Music":
			.multimedia
		case "Games":
			.game
		case "Entertainment":
			.entertainment
		case "Lifestyle":
			.lifestyle
		case "Health & Fitness", "Medical":
			.health
		case "Education":
			.educational
		case "Finance":
			.finance
		case "Business":
			.business
		case "Reference":
			.reference
		case "Travel":
			.travel
		case "Social Networking":
			.socialNetworking
		case "Sports":
			.sports
		default:
			nil
		}
	}

	/**
	The info of a universal app with its Mac record, or the Mac record of a native Mac app, which has the ratings that the plain record does not have. The rating of a universal app is of both records: the counts are summed, and the averages are weighted by the counts (``combinedRating``). The version, its date, the requirement, and the size are of the Mac version, as most visitors use a Mac, and the size of the iPhone version is ``iOSFileSize``.
	*/
	func adding(macRecord: Self) -> Self {
		guard !isMacApp else {
			return macRecord
		}

		var info = self
		info.rating = [self, macRecord].combinedRating
		info.version = macRecord.version
		info.currentVersionReleaseDate = macRecord.currentVersionReleaseDate
		info.minimumOSVersion = macRecord.minimumOSVersion
		info.fileSize = macRecord.fileSize
		info.iOSFileSize = fileSize
		info.listedPlatforms.formUnion(macRecord.listedPlatforms)
		return info
	}

	/**
	Looks up the apps with two requests: the plain lookup and the lookup of the Mac records (``adding(macRecord:)``). A result that is not an app, like a song for an ID with a typo, is left out, so the build fails with an error at the `appStoreID` of the app.

	An empty response is a failed lookup, so a temporary error of Apple keeps the cached response with a warning, or warns when no cached response is available.
	*/
	static func lookup(ids: [AppStoreID], cache: ResponseCache) async throws -> [AppStoreID: Self] {
		struct Response: Decodable {
			let results: [AppStoreInfo]

			enum CodingKeys: CodingKey {
				case results
			}

			init(from decoder: any Decoder) throws {
				let container = try decoder.container(keyedBy: CodingKeys.self)
				var results = try container.nestedUnkeyedContainer(forKey: .results)

				guard !results.isAtEnd else {
					throw ResponseCache.ReadError("The App Store lookup returned no results.")
				}

				var apps = [AppStoreInfo]()

				while !results.isAtEnd {
					let decoder = try results.superDecoder()
					let fields = try decoder.container(keyedBy: AppStoreInfo.CodingKeys.self)

					// Other kinds of results, like artists and albums, have no app ID or other app fields.
					guard try fields.decodeIfPresent(String.self, forKey: .kind).flatMap(Kind.init(rawValue:)) != nil else {
						continue
					}

					apps.append(try AppStoreInfo(from: decoder))
				}

				self.results = apps
			}
		}

		guard !ids.isEmpty else {
			return [:]
		}

		let url = #URL("https://itunes.apple.com/lookup").appending(queryItems: [URLQueryItem(name: "id", value: ids.uniqued(by: \.self).map(\.description).joined(separator: ","))])

		// Each request uses its cached response with a warning when it fails, like the other data. An app with only an iPhone version has no Mac record. The Mac records only add to the plain lookup, so when their request fails without a cached response, the apps keep the plain records (a Mac app then has no rating), and the other App Store info stays.
		async let records = cache.decoded(Response.self, from: url)
		async let macRecords = cache.decoded(Response.self, from: url.appending(queryItems: [URLQueryItem(name: "entity", value: "desktopSoftware")]))
		let macRecordsByID = (try? await macRecords.results.keyed(by: \.id)) ?? [:]

		return try await records.results.keyed(by: \.id).mapValues { record in
			macRecordsByID[record.id].map(record.adding(macRecord:)) ?? record
		}
	}
}

extension Sequence<AppStoreInfo> {
	/**
	The ratings of all the apps together: the averages weighted by their number of ratings, and the total number of ratings. Like all the info, they are of the US App Store. `nil` when no app has ratings.
	*/
	var combinedRating: StoreRating? {
		let ratings = compactMap(\.rating)
		let count = ratings.map(\.count).sum

		guard count > 0 else {
			return nil
		}

		// Summed in a fixed order, as the sum of floating point numbers depends on the order, which would make the number on the about page change between builds of the same content.
		let average = ratings.sorted(using: [KeyPathComparator(\.average), KeyPathComparator(\.count)]).map { $0.average * Double($0.count) }.sum / Double(count)
		return StoreRating(average: average, count: count, store: .appStore)
	}
}

/**
The average rating of the app and the number of ratings, on the App Store or on another store, like Gumroad.
*/
struct StoreRating {
	enum Store {
		case appStore
		case gumroad

		/**
		The name of the store in a sentence, like “the App Store” (``title``).
		*/
		var name: String {
			self == .appStore ? "the \(title)" : title
		}

		/**
		The name of the store alone, like “App Store”, like in the source of a review.
		*/
		var title: String {
			switch self {
			case .appStore:
				"App Store"
			case .gumroad:
				"Gumroad"
			}
		}
	}

	/**
	The average as the store gives it, like 4.6333. It is rounded to one decimal where it is shown.
	*/
	let average: Double

	let count: Int

	/**
	The store of the ratings.
	*/
	let store: Store

	/**
	A rating on the five-star scale, or `nil` for an invalid average or a store without ratings.
	*/
	init?(average: Double, count: Int, store: Store) {
		guard
			average.isFinite,
			(1...5).contains(average),
			count > 0
		else {
			return nil
		}

		self.average = average
		self.count = count
		self.store = store
	}

	/**
	The average rounded to one decimal, like 4.6, for the places that show it, like the rating sentence and structured data, so a value just below a tie, like 4.64999, reads as 4.6 and not 4.7.
	*/
	var roundedAverage: Double {
		(average * 10).rounded() / 10
	}

	/**
	The rounded average with one decimal, like “4.6”.
	*/
	var formattedAverage: String {
		roundedAverage.formatted(.number.locale(.site).precision(.fractionLength(1)))
	}

	/**
	The number of ratings and the store, like “565 ratings on the App Store”.
	*/
	var countText: String {
		"\(count.formatted(counting: "rating")) on \(store.name)"
	}

	/**
	The rating as a sentence, like “Rated 4.6 out of 5 from 565 ratings on the App Store”.
	*/
	var text: String {
		"Rated \(formattedAverage) out of 5 from \(countText)"
	}
}
