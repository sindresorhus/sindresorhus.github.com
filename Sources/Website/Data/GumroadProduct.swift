import Foundation
import SiteKit

/**
The public info of an app on Gumroad (`/l/<id>.json`), like its price and its rating, for the apps that are sold there (`gumroad`). Gumroad has the ratings of these apps, which are not on the App Store.
*/
struct GumroadProduct: Decodable {
	/**
	The price in the currency of the product, which is USD for all the apps. For a product with a price that the buyer can raise, it is the lowest price.
	*/
	let price: Price?

	/**
	The rating, when the product has ratings.
	*/
	let rating: StoreRating?

	/**
	The requirement that the product page shows, like `macOS 26`: the value of its “Requires” attribute, written by hand on Gumroad.
	*/
	let requirement: String?

	/**
	The OS version of the requirement: its first word that is a version, like `26` in `macOS 26 or later`.
	*/
	var requiredOSVersion: OSVersion? {
		requirement?.split(separator: " ").lazy.compactMap { OSVersion(String($0)) }.first
	}

	enum CodingKeys: String, CodingKey {
		case priceCents = "price_cents"
		case ratings
		case attributes
	}

	/**
	The products of the store, like `https://sindresorhus.gumroad.com/l/shortcutie`.
	*/
	static let storeURL = #URL("https://sindresorhus.gumroad.com/l")

	init(from decoder: any Decoder) throws {
		struct Ratings: Decodable {
			let count: Int
			let average: Double
		}

		struct Attribute: Decodable {
			let name: String
			let value: String
		}

		let container = try decoder.container(keyedBy: CodingKeys.self)
		let priceCents = try container.decode(Int.self, forKey: .priceCents)
		let ratings = try container.decodeIfPresent(Ratings.self, forKey: .ratings)
		let attributes = try container.decodeIfPresent([Attribute].self, forKey: .attributes) ?? []
		self.price = try? Price(amount: Decimal(priceCents) / 100)
		self.rating = ratings.flatMap { StoreRating(average: $0.average, count: $0.count, store: .gumroad) }
		self.requirement = attributes.first { $0.name == "Requires" }?.value
	}

	/**
	The products of the IDs, like `supercharge`, each with one request. A product that fails to load is a warning and is left out, so the others still have their ratings.

	The price is in the currency of the product, which is USD for all the apps.
	*/
	static func load(ids: [GumroadProductID], cache: ResponseCache, warnings: WarningCollector) async -> [GumroadProductID: Self] {
		await warnings.values(of: ids) { id in
			"Could not get the Gumroad product “\(id)”, so its app page leaves out its rating"
		} request: { id in
			try await cache.decoded(Self.self, from: storeURL.appending(path: "\(id.rawValue).json"))
		}
	}
}

/**
The ID of a product on Gumroad, like `shortcutie` in `https://sindresorhus.gumroad.com/l/shortcutie`: lowercase letters, digits, and hyphens.
*/
struct GumroadProductID: ValidatedValue, Hashable, CustomStringConvertible {
	let rawValue: String

	/**
	Rejects text that is not an ID, like `Test App`.
	*/
	init(validating rawValue: String) throws(ContentError) {
		guard
			!rawValue.isEmpty,
			rawValue.allSatisfy({ ($0.isASCII && ($0.isLowercase || $0.isNumber)) || $0 == "-" })
		else {
			throw ContentError(reason: "A Gumroad product ID is the ID in the link, like `shortcutie`, got `\(rawValue)`.")
		}

		self.rawValue = rawValue
	}

	var description: String {
		rawValue
	}

	/**
	The page of the product, like `https://sindresorhus.gumroad.com/l/shortcutie`.
	*/
	var url: URL {
		GumroadProduct.storeURL.appending(path: rawValue)
	}
}
