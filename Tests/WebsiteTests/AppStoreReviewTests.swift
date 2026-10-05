import Foundation
import SiteKit
import Testing
@testable import Website

@Suite
struct AppStoreReviewTests {
	@Test(.temporaryDirectory)
	func `reviews come from all the App Stores, newest first, without duplicates, and a malformed feed gives a warning`() async throws {
		func entry(title: String, day: Int) -> String {
			#"{"author": {"name": {"label": "A reviewer"}}, "title": {"label": "\#(title)"}, "content": {"label": "A review that is long enough to be shown on the page of the app."}, "im:rating": {"label": "5"}, "updated": {"label": "2026-01-\#(day < 10 ? "0\(day)" : "\(day)")T00:00:00-07:00"}}"#
		}

		let malformedEntry = #"{"author": {"name": {"label": "Another reviewer"}}}"#

		let feeds = [
			"us": [entry(title: "Valid", day: 1), malformedEntry],
			"gb": (1...12).map { entry(title: "Review \($0)", day: $0 + 1) },
			"ca": [entry(title: "Review 12", day: 13)],
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

		// The same review in two App Stores is shown once, and the malformed feed is left out.
		#expect(reviews[1]?.map(\.title) == (1...12).reversed().map { "Review \($0)" })
		#expect(warnings.all.count == 1)
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
			let date = Calendar.current.date(byAdding: .day, value: number, to: Date(timeIntervalSince1970: 1_767_225_600))!.ISO8601Format()
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

		#expect(reviews[1]?.map(\.title) == (36...60).reversed().map { "Review \($0)" })
		#expect(AppStoreReview.maximumCountPerApp == 25)
		#expect(warnings.all.isEmpty)
	}
}
