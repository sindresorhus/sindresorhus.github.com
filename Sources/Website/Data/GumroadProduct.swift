import Foundation
import SiteKit

/**
The public info of an app on Gumroad (`/l/<id>.json`), like its price and its rating, for the apps that are sold there (`gumroadID`). Gumroad has the ratings of these apps, which are not on the App Store.
*/
struct GumroadProduct: Decodable {
	struct Ratings: Decodable {
		let count: Int
		let average: Double
	}

	/**
	The price in cents, like `2000` for $20. For a product with a price that the buyer can raise, it is the lowest price.
	*/
	let priceCents: Int

	let ratings: Ratings?

	enum CodingKeys: String, CodingKey {
		case priceCents = "price_cents"
		case ratings
	}

	/**
	The products of the store, like `https://sindresorhus.gumroad.com/l/shortcutie`.
	*/
	static let storeURL = #URL("https://sindresorhus.gumroad.com/l")

	var price: Price {
		Price(Decimal(priceCents) / 100)
	}

	/**
	The rating, when the product has ratings.
	*/
	var rating: StoreRating? {
		guard
			let ratings,
			ratings.count > 0
		else {
			return nil
		}

		return StoreRating(average: ratings.average, count: ratings.count, store: .gumroad)
	}

	/**
	The products of the IDs, like `supercharge`, each with one request. A product that fails to load is a warning and is left out, so the others still have their ratings.

	The price is in the currency of the product, which is USD for all the apps.
	*/
	static func load(ids: [GumroadProductID], cache: ResponseCache, warnings: WarningCollector) async -> [GumroadProductID: Self] {
		await withTaskGroup(of: (GumroadProductID, Self?).self) { group in
			for id in Set(ids) {
				group.addTask {
					let url = storeURL.appending(path: "\(id.rawValue).json")
					do {
						return (id, try await cache.decoded(Self.self, from: URLRequest(url: url, timeoutInterval: 15)))
					} catch {
						warnings.add(Warning(message: "Could not get the Gumroad product “\(id)”, so its app page leaves out its rating: \(error)"))
						return (id, nil)
					}
				}
			}

			return await group.reduce(into: [:]) { $0[$1.0] = $1.1 }
		}
	}
}

/**
The ID of a product on Gumroad, like `shortcutie` in `https://sindresorhus.gumroad.com/l/shortcutie`: lowercase letters, digits, and hyphens.
*/
struct GumroadProductID: Hashable, CustomStringConvertible {
	let rawValue: String

	/**
	`nil` for text that is not an ID, like `Test App`.
	*/
	init?(_ rawValue: String) {
		guard
			!rawValue.isEmpty,
			rawValue.allSatisfy({ ($0.isASCII && ($0.isLowercase || $0.isNumber)) || $0 == "-" })
		else {
			return nil
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

extension GumroadProductID: Decodable {
	init(from decoder: any Decoder) throws {
		let container = try decoder.singleValueContainer()
		let value = try container.decode(String.self)

		guard let id = Self(value) else {
			throw DecodingError.dataCorruptedError(in: container, debugDescription: "A Gumroad product ID is the ID in the link, like `shortcutie`, got `\(value)`.")
		}

		self = id
	}
}
