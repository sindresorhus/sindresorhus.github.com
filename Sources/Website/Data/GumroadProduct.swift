import Foundation
import SiteKit

/**
The public info of an app on Gumroad (`/l/<id>.json`), like its price, its rating, and its newest reviews, for the apps that are sold there (`gumroad`). Gumroad has the ratings and the reviews of these apps, which are not on the App Store.
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
	The newest reviews that a page can show, newest first, with the rules of the App Store reviews (``StoreReview/isShowable``, ``StoreReview/isEnglish``). Limitation: Gumroad gives only the five newest reviews, also with ratings below five stars, so an app shows at most five.
	*/
	let reviews: [StoreReview]

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
		case reviews
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

		/**
		A review, or `nil` for a rating without a message or a review with an unexpected shape. A review with an unexpected shape is left out, so the product keeps its rating and its other reviews.
		*/
		struct Review: Decodable {
			struct Fields: Decodable {
				struct Rater: Decodable {
					let name: String
				}

				let rating: Int
				let message: String?
				let rater: Rater
				let createdAt: String

				enum CodingKeys: String, CodingKey {
					case rating
					case message
					case rater
					case createdAt = "created_at"
				}
			}

			let review: StoreReview?

			init(from decoder: any Decoder) {
				// Like the reviews of the App Store, with typographic quotes. A rating without a message is not a review to show.
				guard
					let fields = try? Fields(from: decoder),
					let rating = ReviewStars(rawValue: fields.rating),
					let message = fields.message,
					let date = try? Date(fields.createdAt, strategy: .iso8601)
				else {
					self.review = nil
					return
				}

				self.review = StoreReview(
					title: nil,
					text: message.trimmingCharacters(in: .whitespacesAndNewlines).typographicPunctuation,
					author: fields.rater.name.typographicPunctuation,
					rating: rating,
					date: date,
					store: .gumroad
				)
			}
		}

		let container = try decoder.container(keyedBy: CodingKeys.self)
		let priceCents = try container.decode(Int.self, forKey: .priceCents)
		let ratings = try container.decodeIfPresent(Ratings.self, forKey: .ratings)
		let attributes = try container.decodeIfPresent([Attribute].self, forKey: .attributes) ?? []
		// The reviews only add to the page, so reviews of an unexpected shape do not remove the rating.
		let reviews = (try? container.decode([Review].self, forKey: .reviews)) ?? []
		self.price = try? Price(amount: Decimal(priceCents) / 100)
		self.rating = ratings.flatMap { StoreRating(average: $0.average, count: $0.count, store: .gumroad) }
		self.requirement = attributes.first { $0.name == "Requires" }?.value
		self.reviews = reviews
			.compactMap(\.review)
			.filter { $0.isShowable && $0.isEnglish }
			.sorted(using: KeyPathComparator(\.date, order: .reverse))
	}

	/**
	The products of the IDs, like `supercharge`, each with one request. A product that fails to load is a warning and is left out, so the others still have their ratings and their reviews.

	The price is in the currency of the product, which is USD for all the apps.
	*/
	static func load(ids: [GumroadProductID], cache: ResponseCache, warnings: WarningCollector) async -> [GumroadProductID: Self] {
		await warnings.values(of: ids) { id in
			"Could not get the Gumroad product “\(id)”, so its app page leaves out its rating and its reviews"
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

	/**
	The product of a link to it on Gumroad, also with a discount code or a query after it, like `https://sindresorhus.gumroad.com/l/supercharge/BLACKFRIDAY`. `nil` for another link.
	*/
	init?(productURL url: URL) {
		let store = GumroadProduct.storeURL

		guard
			url.host() == store.host(),
			url.pathComponents.count > store.pathComponents.count,
			url.pathComponents.starts(with: store.pathComponents),
			let id = try? Self(validating: url.pathComponents[store.pathComponents.count])
		else {
			return nil
		}

		self = id
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
