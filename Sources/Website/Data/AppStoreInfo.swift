import Foundation
import SiteKit

/**
The ID of an app on the App Store, like 1607635845 in `https://apps.apple.com/app/id1607635845`.
*/
struct AppStoreID: Hashable, Sendable, CustomStringConvertible, ExpressibleByIntegerLiteral {
	let value: Int

	init(_ value: Int) {
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
struct AppStoreInfo: Decodable, Sendable {
	let id: AppStoreID

	let version: String?

	/**
	When the current version was released.
	*/
	let currentVersionReleaseDate: Date?

	/**
	The amount of the price, in ``currencyCode``. Use ``price``.
	*/
	let priceAmount: Decimal?

	let currencyCode: String?

	let averageUserRating: Double?
	let userRatingCount: Int?

	/**
	`mac-software` for Mac apps, and `software` for iPhone, iPad, and Apple Vision apps, which can run on the Mac too.
	*/
	let kind: String?

	/**
	The lowest version of macOS for Mac apps, of visionOS for Apple Vision apps, or else of iOS, like `26.0`.
	*/
	let minimumOsVersion: String?

	/**
	The devices that can run an app that is not a Mac app, like `iPhone5s-iPhone5s` and `MacDesktop-MacDesktop`.
	*/
	let supportedDevices: [String]?

	enum CodingKeys: String, CodingKey {
		case id = "trackId"
		case version
		case currentVersionReleaseDate
		case priceAmount = "price"
		case currencyCode = "currency"
		case averageUserRating
		case userRatingCount
		case kind
		case minimumOsVersion
		case supportedDevices
	}

	/**
	The average rating of the app and the number of ratings.
	*/
	struct Rating {
		/**
		The average as the App Store gives it, like 4.6333. It is rounded to one decimal where it is shown.
		*/
		let average: Double

		let count: Int

		/**
		The average rounded to one decimal, like 4.6, for the places that show it, like the rating sentence and structured data, so a value just below a tie, like 4.64999, reads as 4.6 and not 4.7.
		*/
		var roundedAverage: Double {
			(average * 10).rounded() / 10
		}

		/**
		The rating as a sentence, like “Rated 4.6 out of 5 from 565 ratings on the App Store”.
		*/
		var text: String {
			"Rated \(roundedAverage.formatted(.number.locale(.site).precision(.fractionLength(1)))) out of 5 from \(count.formatted(counting: "rating")) on the App Store"
		}
	}

	/**
	The rating, when the app has ratings. Mac App Store apps have none.
	*/
	var rating: Rating? {
		guard
			let userRatingCount,
			userRatingCount > 0,
			let averageUserRating
		else {
			return nil
		}

		return Rating(average: averageUserRating, count: userRatingCount)
	}

	var isMacApp: Bool {
		kind == "mac-software"
	}

	/**
	The platforms that the App Store lists for the app. It does not list where iPad apps also run, like on Apple Vision and Macs with Apple silicon.
	*/
	var listedPlatforms: Set<Platform> {
		let devices = supportedDevices ?? []
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

		return platforms
	}

	/**
	The price to download the app.
	*/
	var price: Price? {
		guard
			let priceAmount,
			let currencyCode
		else {
			return nil
		}

		return Price(priceAmount, currency: Locale.Currency(currencyCode))
	}

	/**
	The price for the app page, like “$4.99, one-time purchase” or “Free”. A paid app that is free to download has an in-app purchase.
	*/
	func priceText(isPaid: Bool) -> String? {
		guard let price else {
			return nil
		}

		guard !price.isFree else {
			return isPaid ? "Free to download, with an in-app purchase" : "Free"
		}

		return price.oneTimePurchaseText
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

		let response = try await cache.decoded(Response.self, from: URLRequest(url: url, timeoutInterval: 15))
		return Dictionary(response.results.map { ($0.id, $0) }) { first, _ in first }
	}
}

extension Sequence<AppStoreInfo> {
	/**
	The ratings of all the apps together: the averages weighted by their number of ratings, and the total number of ratings. Like all the info, they are of the US App Store, and Mac App Store apps have none. `nil` when no app has ratings, like when all are Mac apps.
	*/
	var combinedRating: AppStoreInfo.Rating? {
		let ratings = compactMap(\.rating)
		let count = ratings.map(\.count).sum

		guard count > 0 else {
			return nil
		}

		// Summed in a fixed order, as the sum of floating point numbers depends on the order, which would make the number on the about page change between builds of the same content.
		let average = ratings.sorted(using: [KeyPathComparator(\.average), KeyPathComparator(\.count)]).map { $0.average * Double($0.count) }.sum / Double(count)
		return AppStoreInfo.Rating(average: average, count: count)
	}
}
