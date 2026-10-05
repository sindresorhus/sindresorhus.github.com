import Foundation
import SiteKit
import Testing
@testable import Website

@Suite
struct NPMStatisticsTests {
	private static let searchURL = "https://registry.npmjs.org/-/v1/search?text=maintainer:sindresorhus&size=250&from=0"

	@Test(.temporaryDirectory)
	func `the package count is read`() async throws {
		let cache = try ResponseCache(responses: [
			Self.searchURL: #"{"objects": [], "total": 1068, "time": "2026-10-06T00:21:12.561Z"}"#,
		])

		let warnings = WarningCollector()
		let statistics = await NPMStatistics.load(cache: cache, warnings: warnings)

		#expect(statistics.packageCount == 1068)
		#expect(warnings.all.isEmpty)
	}

	@Test(.temporaryDirectory)
	func `the packages are read with their weekly downloads and the date of the latest version`() async throws {
		let cache = try ResponseCache(responses: [
			Self.searchURL: #"{"objects": [{"package": {"name": "chalk", "version": "6.0.0", "date": "2026-10-05T14:57:36.835Z"}, "downloads": {"monthly": 4000, "weekly": 1000}}, {"package": {"name": "execa", "version": "10.1.0", "date": "2026-10-06T16:08:09.000Z"}, "downloads": {"monthly": 2000, "weekly": 500}}], "total": 2}"#,
		])

		let warnings = WarningCollector()
		let statistics = await NPMStatistics.load(cache: cache, warnings: warnings)

		#expect(statistics.packageCount == 2)
		#expect(statistics.weeklyDownloads == 1500)
		#expect(statistics.packages.map(\.version) == ["6.0.0", "10.1.0"])
		#expect(statistics.packages.last?.date == Date(timeIntervalSince1970: 1_791_302_889))
		#expect(warnings.all.isEmpty)
	}

	@Test(.temporaryDirectory)
	func `a failed request leaves out its number with a warning`() async throws {
		let cache = try ResponseCache(responses: [
			Self.searchURL: #"{"error": "Search is down"}"#,
		])

		let warnings = WarningCollector()
		let statistics = await NPMStatistics.load(cache: cache, warnings: warnings)

		#expect(statistics.packageCount == nil)
		#expect(statistics.weeklyDownloads == nil)
		#expect(warnings.all.count == 1)
	}

	@Test(arguments: [
		(number: 0, significantDigits: 2, expected: 0),
		(number: 7, significantDigits: 2, expected: 7),
		(number: 99, significantDigits: 2, expected: 99),
		(number: 100, significantDigits: 2, expected: 100),
		(number: 999, significantDigits: 2, expected: 990),
		(number: 1000, significantDigits: 2, expected: 1000),
		(number: 1068, significantDigits: 2, expected: 1000),
		(number: 515_161, significantDigits: 2, expected: 510_000),
		(number: 1_000_000_000, significantDigits: 1, expected: 1_000_000_000),
		(number: 2_134_519_388, significantDigits: 1, expected: 2_000_000_000),
		(number: 9_999_999_999, significantDigits: 1, expected: 9_000_000_000),
	])
	func `numbers are rounded down to their first digits`(number: Int, significantDigits: Int, expected: Int) {
		#expect(number.roundedDown(significantDigits: significantDigits) == expected)
	}

	@Test
	func `approximate counts are rounded down to two digits and abbreviated, so they never claim more`() {
		#expect(2_134_519_388.approximateCount == "2.1B+")
		#expect(21_456_789_012.approximateCount == "21B+")
		#expect(515_161.approximateCount == "510K+")
		#expect(1_960_000.approximateCount == "1.9M+")
		#expect(999_999.approximateCount == "990K+")
		#expect(2_999_999_999.approximateCount == "2.9B+")
		#expect(1_050_000.approximateCount == "1M+")
		#expect(49_612.approximateCount == "49K+")
		#expect(1_520.approximateCount == "1.5K+")
		#expect(999.approximateCount == "999")
	}
}
