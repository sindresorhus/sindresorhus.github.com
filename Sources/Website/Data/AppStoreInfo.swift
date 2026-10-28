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
	The App Store page with the campaign for its placement on the website, or the plain link without a provider token.
	*/
	func url(placement: App.AppStorePlacement) -> URL {
		guard let campaignQueryItems = placement.campaignQueryItems else {
			return url
		}

		return url.appending(queryItems: campaignQueryItems)
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

Mac App Store apps always have a rating count of 0.
*/
struct AppStoreInfo: Decodable {
	let id: AppStoreID

	let version: String?

	/**
	When the current version was released.
	*/
	let currentVersionReleaseDate: Date?

	/**
	The price to download the app, with its currency.
	*/
	let price: Price?

	/**
	The rating, when the app has ratings. Mac App Store apps have none.
	*/
	let rating: StoreRating?

	/**
	Whether the App Store lists a native Mac app (`mac-software`), rather than an iPhone, iPad, or Apple Vision app that may also run on the Mac.
	*/
	let isMacApp: Bool

	/**
	The lowest version of macOS for Mac apps, of visionOS for Apple Vision apps, or else of iOS, like `26.0`.
	*/
	let minimumOSVersion: OSVersion?

	/**
	The platforms that the App Store lists for the app, decoded from device strings like `iPhone5s-iPhone5s` and `MacDesktop-MacDesktop`. It does not list where iPad apps also run, like on Apple Vision and Macs with Apple silicon.
	*/
	let listedPlatforms: Set<Platform>

	/**
	The download size in bytes, decoded from the text of `fileSizeBytes`, like `"19244046"`.
	*/
	let fileSize: Int64?

	/**
	The main category of the app on the App Store, like `Developer Tools`.
	*/
	let primaryGenreName: String?

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

		self.isMacApp = try container.decodeIfPresent(String.self, forKey: .kind) == "mac-software"
		self.minimumOSVersion = (try? container.decode(String.self, forKey: .minimumOSVersion)).flatMap(OSVersion.init)
		let devices = try container.decodeIfPresent([String].self, forKey: .supportedDevices) ?? []
		var platforms = Set<Platform>()

		if isMacApp || devices.contains(where: { $0.hasPrefix("MacDesktop") }) {
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
	Looks up the apps with one request.
	*/
	static func lookup(ids: [AppStoreID], cache: ResponseCache) async throws -> [AppStoreID: Self] {
		struct Response: Decodable {
			let results: [AppStoreInfo]
		}

		guard !ids.isEmpty else {
			return [:]
		}

		let url = #URL("https://itunes.apple.com/lookup").appending(queryItems: [URLQueryItem(name: "id", value: ids.uniqued(by: \.self).map(\.description).joined(separator: ","))])

		let response = try await cache.decoded(Response.self, from: url)
		return Dictionary(response.results.map { ($0.id, $0) }) { first, _ in first }
	}
}

extension Sequence<AppStoreInfo> {
	/**
	The ratings of all the apps together: the averages weighted by their number of ratings, and the total number of ratings. Like all the info, they are of the US App Store, and Mac App Store apps have none. `nil` when no app has ratings, like when all are Mac apps.
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
		The name of the store in a sentence, like “the App Store”.
		*/
		var name: String {
			switch self {
			case .appStore:
				"the App Store"
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
