import Foundation
import SiteKit

/**
The Sparkle appcast that a Mac app that is not on the App Store checks for updates (``App/appcastURL``), like `https://sindresorhus.com/quickgpt-meta/appcast.xml`. The page shows the macOS version that its latest version needs, so these apps do not need `minimumOSVersion`, and the structured data has the version, its date, and the size of its download, like for an app on the App Store.
*/
struct Appcast {
	/**
	The first item, which is the latest version, as the workflow that makes the appcasts lists the newest version first. The appcast is made by a workflow, so a regex is enough to read it.
	*/
	nonisolated(unsafe) private static let firstItemPattern = /<item>(.*?)<\/item>/.dotMatchesNewlines()

	/**
	The minimum macOS version of an item, like `<sparkle:minimumSystemVersion>26.0</sparkle:minimumSystemVersion>`.
	*/
	nonisolated(unsafe) private static let minimumSystemVersionPattern = /<sparkle:minimumSystemVersion>\s*([^<]+?)\s*<\/sparkle:minimumSystemVersion>/

	/**
	The version that people see, like `<sparkle:shortVersionString>1.30.1</sparkle:shortVersionString>`.
	*/
	nonisolated(unsafe) private static let versionPattern = /<sparkle:shortVersionString>\s*([^<]+?)\s*<\/sparkle:shortVersionString>/

	/**
	When the version was released, in the RFC 822 format of RSS, like `<pubDate>Mon, 28 Sep 2026 04:33:04 +0000</pubDate>`.
	*/
	nonisolated(unsafe) private static let releaseDatePattern = /<pubDate>\s*([^<]+?)\s*<\/pubDate>/

	/**
	The size of the download in bytes, like `<enclosure url="…" length="16227548" …/>`.
	*/
	nonisolated(unsafe) private static let fileSizePattern = /<enclosure\b[^>]*\slength="(\d+)"/

	private static let releaseDateStrategy = Date.ParseStrategy(
		format: "\(weekday: .abbreviated), \(day: .twoDigits) \(month: .abbreviated) \(year: .defaultDigits) \(hour: .twoDigits(clock: .twentyFourHour, hourCycle: .zeroBased)):\(minute: .twoDigits):\(second: .twoDigits) \(timeZone: .iso8601(.short))",
		locale: Locale(identifier: "en_US_POSIX"),
		timeZone: .gmt
	)

	/**
	The macOS version that the latest version of the app needs, like `26.4`.
	*/
	let minimumSystemVersion: OSVersion

	/**
	The latest version, like `1.30.1`.
	*/
	let version: String?

	/**
	When the latest version was released.
	*/
	let releaseDate: Date?

	/**
	The size of the download of the latest version in bytes.
	*/
	let fileSize: Int64?

	/**
	Throws for an appcast whose first item has no valid minimum macOS version, so the response is not cached. The other values are only extra facts for the structured data, so an item without them is fine.
	*/
	init(xml: Data) throws(ResponseCache.ReadError) {
		guard
			let item = String(decoding: xml, as: UTF8.self).firstMatch(of: Self.firstItemPattern)?.output.1,
			let match = item.firstMatch(of: Self.minimumSystemVersionPattern),
			let minimumSystemVersion = OSVersion(String(match.1))
		else {
			throw ResponseCache.ReadError("The appcast has no valid `sparkle:minimumSystemVersion`.")
		}

		self.minimumSystemVersion = minimumSystemVersion
		self.version = item.firstMatch(of: Self.versionPattern).map { String($0.1) }
		releaseDate = item.firstMatch(of: Self.releaseDatePattern).flatMap { try? Date(String($0.1), strategy: Self.releaseDateStrategy) }
		fileSize = item.firstMatch(of: Self.fileSizePattern).flatMap { Int64($0.1) }
	}

	/**
	The appcasts of the URLs, each with one request. An appcast that fails to load is a warning and is left out, so the page of its app falls back to `minimumOSVersion`.
	*/
	static func load(urls: [URL], cache: ResponseCache, warnings: WarningCollector) async -> [URL: Self] {
		await warnings.values(of: urls) { url in
			"Could not get the appcast \(url), so the page of its app shows `minimumOSVersion`, or no requirement"
		} request: { url in
			try await cache.decoded(from: url) { try Self(xml: $0) }
		}
	}
}
