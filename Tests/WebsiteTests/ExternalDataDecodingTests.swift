import Foundation
import SiteKit
import SOML
import TestSupport
import Testing
@testable import Website

struct ExternalDataDecodingTests {
	@Test(.temporaryDirectory)
	func `URL cache overloads share request caching and preserve cancellation`() async throws {
		struct Counts: Decodable {
			let count: Int
		}

		let directory = try URL.temporaryDirectory()
		let url = #URL("https://example.com/counts")
		let cache = try ResponseCache(responses: [url.absoluteString: #"{"count":7}"#], directory: directory)
		let counts = try await cache.decoded(Counts.self, from: url)
		#expect(counts.count == 7)
		let body = try await cache.decoded(from: url) { $0 }
		#expect(body == Data(#"{"count":7}"#.utf8))
		#expect(cache.warnings.isEmpty)

		let cancelled = Task {
			withUnsafeCurrentTask { $0?.cancel() }
			return try await cache.decoded(Counts.self, from: url)
		}

		await #expect(throws: CancellationError.self) {
			try await cancelled.value
		}
	}

	@Test
	func `contribution wire days retain calendar identity through year filtering and UTC presentation`() throws {
		let calendar = try ContributionCalendar(json: #"{"totalContributions":7,"weeks":[{"contributionDays":[{"date":"2025-12-31","contributionCount":4},{"date":"2026-01-01","contributionCount":2},{"date":"2026-01-02","contributionCount":1}]}]}"#)
		let day: SOML.Date = try #require(calendar.days.first?.date)
		#expect(day.description == "2025-12-31")
		#expect(day.foundationDate.formatted(.iso8601) == "2025-12-31T00:00:00Z")
		#expect(calendar.days.first?.weekday == .wednesday)
		let year = ContributionYear(year: 2026, calendar: calendar, totals: .zero, until: try Date("2026-01-01T23:59:59Z", strategy: .iso8601))
		#expect(year.days.map(\.date.description) == ["2026-01-01"])
	}

	@Test(arguments: ["2026-02-30", "2026-01-01T00:00:00Z", "yesterday"])
	func `contribution days reject invalid calendar dates and instant strings`(date: String) {
		#expect(throws: DecodingError.self) {
			try ContributionCalendar.Day(json: #"{"date":"\#(date)","contributionCount":1}"#)
		}
	}

	@Test(arguments: [
		(json: #"{"price_cents":0}"#, price: "$0", average: Optional<Double>.none),
		(json: #"{"price_cents":499,"ratings":{"average":4.8,"count":26}}"#, price: "$4.99", average: Optional(4.8)),
		(json: #"{"price_cents":499,"ratings":null}"#, price: "$4.99", average: Optional<Double>.none),
	])
	func `Gumroad responses normalize prices and optional ratings`(json: String, price: String, average: Double?) throws {
		let product = try GumroadProduct(json: json)

		#expect(product.price?.formatted == price)
		#expect(product.rating?.average == average)
	}

	@Test(arguments: [#"{}"#, #"{"price_cents":"499"}"#, #"{"price_cents":499,"ratings":{"count":"26","average":4.8}}"#, #"{"price_cents":499,"ratings":{"count":26,"average":"4.8"}}"#])
	func `Gumroad normalization keeps required and wrongly typed wire failures`(json: String) {
		#expect(throws: DecodingError.self) {
			try GumroadProduct(json: json)
		}
	}

	/**
	A response that cannot be decoded is removed from the cache, so the next build asks again instead of using it until it expires.
	*/
	@Test(.temporaryDirectory)
	func `an unexpected response is an error, and is not kept in the cache`() async throws {
		struct Totals: Decodable {
			let count: Int
		}

		let url = #URL("https://example.com/totals")
		let directory = try URL.temporaryDirectory()
		let cache = try ResponseCache(responses: [url.absoluteString: #"{"error": "Not found"}"#], directory: directory)
		#expect(try directory.filesRecursively().count == 1)

		await #expect(throws: (any Error).self) {
			try await cache.decoded(Totals.self, from: URLRequest(url: url))
		}

		#expect(try directory.filesRecursively().isEmpty)
	}

	@Test(arguments: [
		(json: #"{"trackId":123}"#, isMac: false, platforms: Set<Platform>()),
		(json: #"{"trackId":123,"kind":"mac-software"}"#, isMac: true, platforms: Set([Platform.macOS])),
		(json: #"{"trackId":123,"kind":"unknown","supportedDevices":["Unknown-Device"]}"#, isMac: false, platforms: Set<Platform>()),
		(json: #"{"trackId":123,"kind":"software","supportedDevices":["iPhone5s-iPhone5s","iPad-iPad","MacDesktop-MacDesktop","AppleVisionPro-AppleVisionPro"]}"#, isMac: false, platforms: Set([Platform.macOS, .iOS, .visionOS])),
	])
	func `app store device strings normalize into stored platform facts`(json: String, isMac: Bool, platforms: Set<Platform>) throws {
		let info = try AppStoreInfo(json: json)

		#expect(info.isMacApp == isMac)
		#expect(info.listedPlatforms == platforms)
	}

	@Test
	func `platform normalization retains wrongly typed wire field failures`() {
		for json in [#"{"trackId":123,"kind":12}"#, #"{"trackId":123,"supportedDevices":[12]}"#] {
			#expect(throws: DecodingError.self) {
				try AppStoreInfo(json: json)
			}
		}
	}

	@Test
	func `app version candidates retain source facts before page owned launch filters`() async throws {
		let app = try await App(publicationDate: "2026-01-01", frontmatter: "releasesRepository: 'sindresorhus/test'")
		let info = try AppStoreInfo(json: #"{"trackId":123,"version":"2.0","currentVersionReleaseDate":"2025-12-31T00:00:00Z"}"#)
		let listing = AppListing(app: app, appStoreInfo: info, releases: [
			GitHubRelease(tagName: "v1.0", publishedAt: Date(year: 2026, month: 1, day: 1), notesHTML: ""),
			GitHubRelease(tagName: "v3.0", publishedAt: Date(year: 2026, month: 10, day: 1), notesHTML: ""),
		])
		let candidates = listing.versionReleases

		#expect(candidates.map(\.version) == ["3.0", "2.0"])
		#expect(candidates.map(\.date.isoDay) == ["2026-10-01", "2025-12-31"])
		#expect(candidates.allSatisfy { $0.app.slug == app.slug })
		#expect(candidates.first?.destination == app.releaseNotes?.destination(of: listing.releases[1]))
		#expect(candidates.last?.destination == app.url)
	}

	@Test
	func `annual app metrics retain the release date when the version string is missing`() async throws {
		let app = try await App(publicationDate: "2026-01-01")
		let info = try AppStoreInfo(json: #"{"trackId":123,"currentVersionReleaseDate":"2026-10-01T00:00:00Z"}"#)
		let listing = AppListing(app: app, appStoreInfo: info)

		#expect(listing.appStoreVersionDate?.isoDay == "2026-10-01")
		#expect(listing.versionReleases.isEmpty)
	}

}
