import Foundation
import SiteKit
import TestSupport
import Testing
@testable import Website

@Suite
struct NPMStatisticsTests {
	@Test(.temporaryDirectory)
	func `the package count is read`() async throws {
		let cache = try ResponseCache.npm(search: #"{"objects": [], "total": 1068, "time": "2026-10-06T00:21:12.561Z"}"#)

		let warnings = WarningCollector()
		let statistics = await NPMStatistics.load(cache: cache, warnings: warnings)

		#expect(statistics.packageCount == 1068)
		// Without packages, there is no share and no count of the most downloaded.
		#expect(statistics.downloadShare == nil)
		#expect(statistics.mostDownloadedCount(of: 10) == nil)
		#expect(warnings.all.isEmpty)
	}

	/**
	A list in another format, like with double quotes, has no names, so it is left out with a warning instead of counting wrong names.
	*/
	@Test(.temporaryDirectory)
	func `a list of the most-downloaded packages in another format is left out with a warning`() async throws {
		let cache = try ResponseCache.npm(search: #"{"objects": [], "total": 0}"#, mostDownloaded: "// Don't edit.\nexport const topDownload = [\n  \"chalk\",\n]")
		let warnings = WarningCollector()
		let statistics = await NPMStatistics.load(cache: cache, warnings: warnings)

		#expect(statistics.mostDownloadedPackageNames.isEmpty)
		try #require(warnings.all.count == 1)
		#expect(warnings.all[0].message.contains("The file has no package names."))
	}

	@Test(.temporaryDirectory)
	func `the packages are read with their weekly downloads, their dependents, the date of the latest version, and how they compare with all of npm`() async throws {
		let cache = try ResponseCache.npm(
			search: #"{"objects": [{"package": {"name": "chalk", "version": "6.0.0", "date": "2026-10-05T14:57:36.835Z"}, "downloads": {"monthly": 4000, "weekly": 1000}, "dependents": "3845"}, {"package": {"name": "execa", "version": "10.1.0", "date": "2026-10-06T16:08:09.000Z"}, "downloads": {"monthly": 2000, "weekly": 500}, "dependents": 155}, {"package": {"name": "ora", "version": "9.0.0", "date": "2026-10-06T16:08:09.000Z"}, "downloads": {"monthly": 20, "weekly": 5}}], "total": 3}"#,
			registryDownloads: #"{"downloads": 15050, "start": "2026-10-05", "end": "2026-10-11"}"#,
			mostDownloaded: "export const topDownload = [\n  'semver',\n  'chalk',\n  'execa',\n]"
		)

		let warnings = WarningCollector()
		let statistics = await NPMStatistics.load(cache: cache, warnings: warnings)

		#expect(statistics.packageCount == 3)
		#expect(statistics.weeklyDownloads == 1505)
		// The dependents are a string or a number, and a package without them is left out of the sum.
		#expect(statistics.dependentCount == 4000)
		#expect(statistics.packages.map(\.version) == ["6.0.0", "10.1.0", "9.0.0"])
		// 1505 of the 15050 downloads of all of npm, and chalk and execa are among the most downloaded.
		#expect(statistics.downloadShare == 0.1)
		#expect(statistics.mostDownloadedCount(of: 10) == 2)
		#expect(statistics.mostDownloadedCount(of: 1) == 0)
		#expect(statistics.packages.last?.date == Date(timeIntervalSince1970: 1_791_302_889))
		#expect(warnings.all.isEmpty)
	}

	/**
	The dependents of a package in another form are unknown, so the package is still read, instead of failing the page of the search. Without downloads on npm, there is no share of them.
	*/
	@Test(.temporaryDirectory)
	func `dependents in another form are unknown, and no downloads on npm give no share`() async throws {
		let cache = try ResponseCache.npm(search: #"{"objects": [{"package": {"name": "chalk", "version": "6.0.0", "date": "2026-10-05T14:57:36.835Z"}, "downloads": {"weekly": 1000}, "dependents": "many"}, {"package": {"name": "execa", "version": "10.1.0", "date": "2026-10-06T16:08:09.000Z"}, "downloads": {"weekly": 500}, "dependents": null}], "total": 2}"#, registryDownloads: #"{"downloads": 0}"#)
		let warnings = WarningCollector()
		let statistics = await NPMStatistics.load(cache: cache, warnings: warnings)

		#expect(statistics.packages.map(\.dependentCount) == [nil, nil])
		#expect(statistics.dependentCount == nil)
		#expect(statistics.downloadShare == nil)
		#expect(warnings.all.isEmpty)
	}

	/**
	The description is shown as text, so it has no backticks of code, and a description with no text left is none, so the package is not a project of the day. The label of the weekly downloads has the noun in the plural unless the count is 1.
	*/
	@Test(.temporaryDirectory)
	func `the description is read without the backticks of code, an empty one is none, and the weekly downloads have a label`() async throws {
		let cache = try ResponseCache.npm(search: #"{"objects": [{"package": {"name": "p-map", "version": "7.0.0", "description": "Map over `promises` concurrently ", "date": "2026-10-05T14:57:36.835Z"}, "downloads": {"weekly": 4200000}}, {"package": {"name": "empty", "version": "1.0.0", "description": " `` ", "date": "2026-10-05T14:57:36.835Z"}, "downloads": {"weekly": 1}}, {"package": {"name": "none", "version": "1.0.0", "date": "2026-10-05T14:57:36.835Z"}, "downloads": {"weekly": 0}}], "total": 3}"#)
		let statistics = await NPMStatistics.load(cache: cache, warnings: WarningCollector())

		#expect(statistics.packages.map(\.description) == ["Map over promises concurrently", nil, nil])
		#expect(statistics.packages.map(\.weeklyDownloadsLabel) == ["4.2M+ downloads a week", "1 download a week", "0 downloads a week"])
	}

	@Test(.temporaryDirectory)
	func `a failed request leaves out its number with a warning`() async throws {
		let cache = try ResponseCache.npm(search: #"{"error": "Search is down"}"#)

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
