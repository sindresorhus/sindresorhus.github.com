import Foundation
import SiteKit
import TestSupport
import Testing
@testable import Website

struct AppStoreReviewTests {
	@Test(arguments: [1, 2, 3, 4, 5])
	func `individual review stars encode and decode as whole numbers`(count: Int) throws {
		let stars = try #require(ReviewStars(rawValue: count))
		let encoded = try JSONEncoder().encode(Schema.Rating(ratingValue: stars))
		let object = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
		#expect(object["ratingValue"] as? Int == count)
		#expect(try JSONDecoder().decode(ReviewStars.self, from: JSONEncoder().encode(count)) == stars)
	}

	@Test(.temporaryDirectory)
	func `invalid review stars are skipped without discarding the feed or stopping pagination`() async throws {
		func entry(stars: String, title: String) -> String {
			#"{"author": {"name": {"label": "A reviewer"}}, "title": {"label": "\#(title)"}, "content": {"label": "A review that is long enough to be shown on the page of the app."}, "im:rating": {"label": "\#(stars)"}, "updated": {"label": "2026-01-01T00:00:00Z"}}"#
		}

		let invalidEntries = (0..<50).map { index in
			entry(stars: ["0", "6", "invalid", "-1", "3.5"][index % 5], title: "Invalid")
		}
		var responses = [
			"https://itunes.apple.com/us/rss/customerreviews/page=1/id=1/sortBy=mostRecent/json": #"{"feed": {"entry": [\#(invalidEntries.joined(separator: ","))]}}"#,
			"https://itunes.apple.com/us/rss/customerreviews/page=2/id=1/sortBy=mostRecent/json": #"{"feed": {"entry": [\#(entry(stars: "5", title: "Valid"))]}}"#,
		]
		for storefront in ["gb", "ca", "au", "nz", "ie"] {
			responses["https://itunes.apple.com/\(storefront)/rss/customerreviews/page=1/id=1/sortBy=mostRecent/json"] = #"{"feed": {}}"#
		}

		let warnings = WarningCollector()
		let reviews = await AppStoreReview.recentFiveStar(appIDs: [1], cache: try ResponseCache(responses: responses), warnings: warnings)
		#expect(reviews[1]?.map(\.title) == ["Valid"])
		#expect(reviews[1]?.first?.rating == .five)
		#expect(warnings.all.isEmpty)
	}

	@Test(.temporaryDirectory)
	func `reviews come from all the App Stores, newest first, without duplicates or other languages, and a malformed feed gives a warning`() async throws {
		func entry(title: String, day: Int) -> String {
			#"{"author": {"name": {"label": "A reviewer"}}, "title": {"label": "\#(title)"}, "content": {"label": "A review that is long enough to be shown on the page of the app."}, "im:rating": {"label": "5"}, "updated": {"label": "2026-01-\#(day < 10 ? "0\(day)" : "\(day)")T00:00:00-07:00"}}"#
		}

		let malformedEntry = #"{"author": {"name": {"label": "Another reviewer"}}}"#
		let frenchEntry = #"{"author": {"name": {"label": "Un client"}}, "title": {"label": "Fantastique et simple"}, "content": {"label": "Une application très simple et très utile, je la recommande à tout le monde sans hésiter."}, "im:rating": {"label": "5"}, "updated": {"label": "2026-01-20T00:00:00-07:00"}}"#

		let feeds = [
			"us": [entry(title: "Valid", day: 1), malformedEntry],
			"gb": (1...12).map { entry(title: "Review \($0)", day: $0 + 1) },
			"ca": [entry(title: "Review 12", day: 13), frenchEntry],
			"au": [],
			"nz": [],
			"ie": [],
		]

		// Fresh cached responses, so the test does not use the network.
		let responses = Dictionary(uniqueKeysWithValues: feeds.map { storefront, entries in
			("https://itunes.apple.com/\(storefront)/rss/customerreviews/page=1/id=1/sortBy=mostRecent/json", #"{"feed": {"entry": [\#(entries.joined(separator: ", "))]}}"#)
		})

		let cache = try ResponseCache(responses: responses)
		let warnings = WarningCollector()
		let reviews = await AppStoreReview.recentFiveStar(appIDs: [1], cache: cache, warnings: warnings)

		// The same review in two App Stores is shown once, and the malformed feed and the review in French are left out.
		#expect(reviews[1]?.map(\.title) == (1...12).reversed().map { "Review \($0)" })
		#expect(warnings.all.count == 1)
	}

	/**
	A very short review says little, and a long one does not fit the page.
	*/
	@Test(.temporaryDirectory)
	func `only reviews of 40 to 360 characters are shown`() async throws {
		func entry(length: Int) -> String {
			let text = String(String(repeating: "The app works well, and I use it every day. ", count: 10).prefix(length - 1)) + "x"
			return #"{"author": {"name": {"label": "A reviewer"}}, "title": {"label": "Review \#(length)"}, "content": {"label": "\#(text)"}, "im:rating": {"label": "5"}, "updated": {"label": "2026-01-0\#(length % 9 + 1)T00:00:00Z"}}"#
		}

		var responses = ["https://itunes.apple.com/us/rss/customerreviews/page=1/id=1/sortBy=mostRecent/json": #"{"feed": {"entry": [\#([39, 40, 360, 361].map(entry(length:)).joined(separator: ", "))]}}"#]

		for storefront in ["gb", "ca", "au", "nz", "ie"] {
			responses["https://itunes.apple.com/\(storefront)/rss/customerreviews/page=1/id=1/sortBy=mostRecent/json"] = #"{"feed": {}}"#
		}

		let reviews = await AppStoreReview.recentFiveStar(appIDs: [1], cache: try ResponseCache(responses: responses), warnings: WarningCollector())
		#expect(Set(reviews[1]?.map(\.title) ?? []) == ["Review 40", "Review 360"])
	}

	@Test(.temporaryDirectory)
	func `feeds without entries for every app give one warning`() async throws {
		// Like the feeds of Apple since 2026, which have no `entry` for any app.
		let responses = Dictionary(uniqueKeysWithValues: [1, 2].flatMap { id in
			["us", "gb", "ca", "au", "nz", "ie"].map { ("https://itunes.apple.com/\($0)/rss/customerreviews/page=1/id=\(id)/sortBy=mostRecent/json", #"{"feed": {"author": {"name": {"label": "iTunes Store"}}}}"#) }
		})

		let cache = try ResponseCache(responses: responses)
		let warnings = WarningCollector()
		let reviews = await AppStoreReview.recentFiveStar(appIDs: [1, 2], cache: cache, warnings: warnings)

		#expect(reviews.count == 2)
		#expect(reviews.values.allSatisfy { $0.isEmpty })
		#expect(warnings.all.map(\.message) == ["App Store review feeds returned no entries, so the pages have no App Store reviews."])
	}

	@Test(.temporaryDirectory)
	func `a full page of a feed reads the next page, and each app keeps the newest reviews up to the maximum`() async throws {
		func entry(number: Int) -> String {
			// One review a day, from the first of January, so a higher number is newer.
			let date = Date(timeIntervalSince1970: 1_767_225_600 + Double(number * 86_400)).ISO8601Format()
			return #"{"author": {"name": {"label": "A reviewer"}}, "title": {"label": "Review \#(number)"}, "content": {"label": "A review that is long enough to be shown on the page of the app."}, "im:rating": {"label": "5"}, "updated": {"label": "\#(date)"}}"#
		}

		func response(_ numbers: ClosedRange<Int>) -> String {
			#"{"feed": {"entry": [\#(numbers.map(entry(number:)).joined(separator: ", "))]}}"#
		}

		// The first page is full, so the second page is read. The second page is not full, so the third page is not read, and it is not in the cache.
		var responses = [
			"https://itunes.apple.com/us/rss/customerreviews/page=1/id=1/sortBy=mostRecent/json": response(11...60),
			"https://itunes.apple.com/us/rss/customerreviews/page=2/id=1/sortBy=mostRecent/json": response(1...10),
		]

		for storefront in ["gb", "ca", "au", "nz", "ie"] {
			responses["https://itunes.apple.com/\(storefront)/rss/customerreviews/page=1/id=1/sortBy=mostRecent/json"] = #"{"feed": {}}"#
		}

		let cache = try ResponseCache(responses: responses)
		let warnings = WarningCollector()
		let reviews = await AppStoreReview.recentFiveStar(appIDs: [1], cache: cache, warnings: warnings)

		// The 25 newest.
		#expect(reviews[1]?.map(\.title) == (36...60).reversed().map { "Review \($0)" })
		#expect(warnings.all.isEmpty)
	}
}
