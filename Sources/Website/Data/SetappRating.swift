import Foundation
import SiteKit

/**
The rating of an app on Setapp, from the structured data of its page on Setapp, which the page shows for the apps that have no rating on the App Store or on Gumroad, like the Mac App Store apps, as Apple gives no ratings for them. Setapp members rate an app with a thumbs up or down, so the rating is the percentage of positive ratings, not an average of stars.

It is only shown as text, never in the structured data of the app page, as Google does not accept ratings that come from another site.
*/
struct SetappRating {
	/**
	The percentage of positive ratings, like 99.
	*/
	let percentPositive: Int

	let count: Int

	/**
	A percentage on the declared 100-point scale, rounded to a whole percent, or `nil` for invalid values or no ratings.
	*/
	init?(ratingValue: Double, bestRating: Int, count: Int) {
		guard
			bestRating == 100,
			ratingValue.isFinite,
			(0...100).contains(ratingValue),
			count > 0
		else {
			return nil
		}

		self.percentPositive = Int(ratingValue.rounded())
		self.count = count
	}

	/**
	The percentage, like “99%”.
	*/
	var formattedPercentage: String {
		"\(percentPositive)%"
	}

	/**
	What the percentage is, with the number of ratings, like “positive from 877 ratings on Setapp”.
	*/
	var countText: String {
		"positive from \(count.formatted(counting: "rating")) on Setapp"
	}

	/**
	The rating as a sentence, like “99% positive from 877 ratings on Setapp”.
	*/
	var text: String {
		"\(formattedPercentage) \(countText)"
	}
}

extension SetappRating {
	/**
	The JSON-LD blocks of a page, like `<script id="app-jsonld" type="application/ld+json">{…}</script>`.
	*/
	nonisolated(unsafe) private static let structuredDataPattern = /<script[^>]*type="application\/ld\+json"[^>]*>(.*?)<\/script>/.dotMatchesNewlines()

	/**
	A JSON-LD block of the page, like the `SoftwareApplication` of the app, with its rating. Other blocks have no rating.
	*/
	private struct Item: Decodable {
		/**
		The rating of the app, like `{"ratingValue": 99, "bestRating": 100, "ratingCount": 877}`.
		*/
		struct AggregateRating: Decodable {
			let ratingValue: Double
			let bestRating: Int
			let ratingCount: Int
		}

		let aggregateRating: AggregateRating?
	}

	/**
	Reads the rating of the app from the `aggregateRating` in the structured data of its page on Setapp, like `{"ratingValue": 99, "bestRating": 100, "ratingCount": 877}`. Throws for a page without it, or with a rating that is not a percentage, so the response is not cached. Limitation: an app that has no ratings on Setapp yet likely has no `aggregateRating`, so its page warns until it has one.
	*/
	init(html: Data) throws(ResponseCache.ReadError) {
		let items = String(decoding: html, as: UTF8.self)
			.matches(of: Self.structuredDataPattern)
			.compactMap { try? JSONDecoder().decode(Item.self, from: Data($0.output.1.utf8)) }

		guard let rating = items.lazy.compactMap(\.aggregateRating).first else {
			throw ResponseCache.ReadError("The page has no `aggregateRating` in its structured data.")
		}

		guard rating.bestRating == 100 else {
			throw ResponseCache.ReadError("The rating is out of \(rating.bestRating), not a percentage out of 100.")
		}

		guard let value = Self(ratingValue: rating.ratingValue, bestRating: rating.bestRating, count: rating.ratingCount) else {
			throw ResponseCache.ReadError("The rating must be a percentage from 0 through 100 with a positive rating count.")
		}

		self = value
	}

	/**
	The ratings of the apps on Setapp, by their `setappID`, each with one request to the page of the app, like `https://setapp.com/apps/571`, which redirects to `https://setapp.com/apps/dato`. A rating that fails to load is a warning and is left out, as it only adds to the page.
	*/
	static func load(ids: [SetappID], cache: ResponseCache, warnings: WarningCollector) async -> [SetappID: Self] {
		await warnings.values(of: ids) { id in
			"Could not get the Setapp rating of the app with the Setapp ID \(id), so its app page leaves it out"
		} request: { id in
			try await cache.decoded(from: id.pageURL) { try Self(html: $0) }
		}
	}
}

/**
The ID of an app on Setapp, like 571 in `https://setapp.com/apps/571`.
*/
struct SetappID: Hashable, CustomStringConvertible {
	let value: Int

	/**
	Creates a positive Setapp ID, rejecting invalid input before it becomes part of a link.
	*/
	init(validating rawValue: Int) throws(ContentError) {
		guard rawValue > 0 else {
			throw ContentError(reason: "Must be a positive number, like `571`, got \(rawValue).")
		}

		self.value = rawValue
	}

	var description: String {
		String(value)
	}

	/**
	The page of the app on Setapp, like `https://setapp.com/apps/571`, which redirects to the page with the name of the app, like `https://setapp.com/apps/dato`.
	*/
	var pageURL: URL {
		#URL("https://setapp.com/apps").appending(path: description)
	}

	/**
	The page of the app on Setapp with the referral of the vendor program, which the app page links to.
	*/
	var referralURL: URL {
		#URL("https://go.setapp.com/stp181").appending(queryItems: [URLQueryItem(name: "refAppID", value: description), URLQueryItem(name: "utm_medium", value: "vendor_program"), URLQueryItem(name: "utm_content", value: "button")])
	}
}

extension SetappID: ValidatedValue {}
