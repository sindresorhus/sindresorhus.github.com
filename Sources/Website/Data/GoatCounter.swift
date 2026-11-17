import Foundation
import SiteKit

/**
The visits of the pages from GoatCounter, which counts each page that a visitor opens (`count.js` in ``SiteLayout``). The statistics are private, so the API needs a token (``token``), and a build without it has no visits.
*/
struct GoatCounter {
	let token: String

	// The shared CI response cache can be read from fork pull requests. Keep the private statistics off disk.
	private let cache = ResponseCache(directory: nil, maximumAge: .zero)

	/**
	The token of `GOATCOUNTER_TOKEN`, or `nil` when it is not set. The owner makes it in GoatCounter (the name of the user in the top menu › API), with the permission to read the statistics, and adds it to the secrets of the repo for `ci.yml`.
	*/
	static var token: String? {
		ProcessInfo.processInfo.environment["GOATCOUNTER_TOKEN"]?.nilIfEmpty
	}

	/**
	The paths of the most visited pages of the 30 days before the day of the build, most visited first, like `/guides/flush-dns-cache-mac`. The range uses whole days in UTC, so every build of the same day requests the same period.

	Limitation: GoatCounter returns at most 100 paths for a request, so a page that is not among the 100 most visited pages of the site is not in the list.
	*/
	func mostVisitedPaths(before date: Date) async throws -> [String] {
		var calendar = Calendar(identifier: .gregorian)
		calendar.timeZone = .gmt
		let end = calendar.startOfDay(for: date)
		let start = calendar.date(byAdding: .day, value: -30, to: end) ?? end

		let url = #URL("https://sindresorhus.goatcounter.com/api/v0/stats/hits").appending(
			formQueryItems: [
				URLQueryItem(name: "start", value: start.formatted(.iso8601)),
				URLQueryItem(name: "end", value: end.formatted(.iso8601)),
				URLQueryItem(name: "limit", value: "100"),
			]
		)

		var request = URLRequest(url: url, timeoutInterval: 20)
		request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

		let response: Response = try await cache.decoded(from: request)

		// The hits are sorted by the visits, most first.
		return response.hits.map(\.path)
	}

	private struct Response: Decodable {
		struct Hit: Decodable {
			let path: String
		}

		let hits: [Hit]
	}
}
