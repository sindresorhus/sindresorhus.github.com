import Foundation
import SiteKit

/**
The npm packages of the `sindresorhus` account: how many there are, how many packages depend on them, how often they are downloaded in total, and how they compare with all of npm.

On purpose, the package count and the weekly downloads include all the packages that `sindresorhus` maintains, also the ones in the repositories of other people, like `yeoman-generator`. The latest releases of the now page only show the packages of his own repositories and those of his organizations.

The numbers are extra, so a failed request leaves out its number, with a warning, instead of failing the build.
*/
struct NPMStatistics: Sendable {
	/**
	The number of packages that `sindresorhus` maintains.
	*/
	var packageCount: Int?

	/**
	All the packages, from the npm search. Empty when a request failed, as the totals of some packages would be wrong.
	*/
	var packages = [Package]()

	/**
	The downloads of all the packages on npm in the last week, like 183,646,517,192.
	*/
	var registryWeeklyDownloads: Int?

	/**
	The names of the most-downloaded packages on npm, most downloaded first, from [npm-high-impact](https://github.com/wooorm/npm-high-impact). Empty when the request failed.
	*/
	var mostDownloadedPackageNames = [String]()

	struct Package: Sendable {
		let name: String
		let version: String

		/**
		What the package does, like “Map over promises concurrently”, without the backticks of code. `nil` when the package has none.
		*/
		let description: String?

		/**
		When the latest version was published.
		*/
		let date: Date

		/**
		The weekly downloads. `nil` when the search does not have them, which is not the same as no downloads.
		*/
		let weeklyDownloads: Int?

		/**
		The number of packages on npm that depend on the package, like 3845 for `ansi-styles`. `nil` when the search does not have it.
		*/
		let dependentCount: Int?

		/**
		The GitHub repository of the package, like `chalk/chalk` for `https://github.com/chalk/chalk`. `nil` when the package has no GitHub repository.
		*/
		let repository: GitHubRepositoryName?

		var url: URL {
			#URL("https://www.npmjs.com/package/").appending(path: name)
		}

		/**
		The name without the scope, like `is` for `@sindresorhus/is`.
		*/
		var unscopedName: String {
			String(name.split(separator: "/").last ?? "")
		}

		/**
		The weekly downloads, rounded down when they are large, like “4.2M+ downloads a week” or “6 downloads a week”. `nil` without the downloads.
		*/
		var weeklyDownloadsLabel: String? {
			weeklyDownloads.map { "\($0.approximateCount(counting: "download")) a week" }
		}
	}

	/**
	The downloads of all the packages in the last week, when the search worked. A package without the downloads does not count, so the total is a lower bound.
	*/
	var weeklyDownloads: Int? {
		packages.compactMap(\.weeklyDownloads).nilIfEmpty?.sum
	}

	/**
	The downloads of all the packages a second, on average over the last week, like 34,722.2, when the search worked.
	*/
	var downloadsPerSecond: Double? {
		weeklyDownloads.map { Double($0) / (Duration.days(7) / .seconds(1)) }
	}

	/**
	The dependents of all the packages, when the search worked and has them. A package that depends on several of the packages counts once for each, so it is the sum of the dependents of each package, not the number of packages that depend on them.
	*/
	var dependentCount: Int? {
		packages.compactMap(\.dependentCount).nilIfEmpty?.sum
	}

	/**
	How many packages are in the GitHub repos, like `sindresorhus/ky`. The now page counts the packages in the repos that were made this year as new, as the npm search has no date of the first version. `nil` when the search did not give the packages.
	*/
	func packageCount(inRepositories repositories: [GitHubRepositoryName]) -> Int? {
		let repositories = Set(repositories)
		return packages.nilIfEmpty?.count { $0.repository.map(repositories.contains) ?? false }
	}

	/**
	How many packages have a version since the date, like the start of the week. `nil` when the search did not give the packages. The search only has the date of the latest version, so a new package counts as updated too.
	*/
	func updatedPackageCount(since start: Date) -> Int? {
		packages.nilIfEmpty?.count { $0.date >= start }
	}

	/**
	The part of all the downloads on npm that are of the packages, like 0.1 for 1 in 10. The two numbers are of about the same week, as npm has them for slightly different days.
	*/
	var downloadShare: Double? {
		guard
			let weeklyDownloads,
			let registryWeeklyDownloads,
			registryWeeklyDownloads > 0
		else {
			return nil
		}

		return Double(weeklyDownloads) / Double(registryWeeklyDownloads)
	}

	/**
	How many of the most-downloaded packages on npm are among the packages, like 5 of the 10 most downloaded. `nil` without both lists.
	*/
	func mostDownloadedCount(of count: Int) -> Int? {
		guard
			!packages.isEmpty,
			!mostDownloadedPackageNames.isEmpty
		else {
			return nil
		}

		let names = Set(packages.map(\.name))
		return mostDownloadedPackageNames.prefix(count).count { names.contains($0) }
	}

	/**
	Gets the packages with the npm search, 250 at a time, with their weekly downloads, and at the same time the downloads of all of npm and the most-downloaded packages.
	*/
	static func load(cache: ResponseCache, warnings: WarningCollector) async -> Self {
		var statistics = Self()

		// At the same time as the search.
		async let registryWeeklyDownloads = registryWeeklyDownloads(cache: cache, warnings: warnings)
		async let mostDownloadedPackageNames = mostDownloadedPackageNames(cache: cache, warnings: warnings)

		do {
			var packages = [Package]()

			for offset in stride(from: 0, to: Int.max, by: SearchResult.pageSize) {
				let url = #URL("https://registry.npmjs.org/-/v1/search").appending(formQueryItems: [URLQueryItem(name: "text", value: "maintainer:sindresorhus"), URLQueryItem(name: "size", value: String(SearchResult.pageSize)), URLQueryItem(name: "from", value: String(offset))])
				let page = try await cache.decoded(SearchResult.self, from: URLRequest(url: url, timeoutInterval: 15))
				// Read once, as each read parses the dates and the repository links of the page again.
				let pagePackages = page.packages
				statistics.packageCount = statistics.packageCount ?? page.total
				packages += pagePackages

				guard
					!pagePackages.isEmpty,
					offset + SearchResult.pageSize < page.total
				else {
					break
				}
			}

			statistics.packages = packages
		} catch {
			// Without all the pages, the packages are left out, and only the number of packages can remain.
			var missing = ["their dependents", "their weekly downloads", "their share of all the downloads", "how many of the most-downloaded packages are his"]

			if statistics.packageCount == nil {
				missing.insert("their number", at: 0)
			}

			warnings.add(Warning(message: "Could not get the npm packages, so the about page leaves out \(missing.formatted(.list(type: .and).locale(.site))), and the now page leaves out the npm releases and the numbers of new and updated packages: \(error)"))
		}

		statistics.registryWeeklyDownloads = await registryWeeklyDownloads
		statistics.mostDownloadedPackageNames = await mostDownloadedPackageNames
		return statistics
	}

	/**
	The downloads of all the packages on npm in the last week. `nil` with a warning when the request failed.
	*/
	private static func registryWeeklyDownloads(cache: ResponseCache, warnings: WarningCollector) async -> Int? {
		struct Downloads: Decodable {
			let downloads: Int
		}

		return await warnings.value(warning: "Could not get the downloads of all of npm, so the about page leaves out the share of the downloads") {
			try await cache.decoded(Downloads.self, from: URLRequest(url: #URL("https://api.npmjs.org/downloads/point/last-week"), timeoutInterval: 15)).downloads
		}
	}

	/**
	The names of the most-downloaded packages, from the list of npm-high-impact, which is a JavaScript file with each name in single quotes on its own line, like `  'chalk',`. Empty with a warning when the request failed or the file has no names.
	*/
	private static func mostDownloadedPackageNames(cache: ResponseCache, warnings: WarningCollector) async -> [String] {
		await warnings.value(warning: "Could not get the most-downloaded npm packages, so the about page leaves out how many of them are his") {
			try await cache.decoded(from: URLRequest(url: #URL("https://unpkg.com/npm-high-impact/lib/top-download.js"), timeoutInterval: 15)) { data in
				// Only whole lines, so a quote elsewhere in the file, like in a comment, is not a name.
				let names = String(decoding: data, as: UTF8.self).matches(of: /^\s*'([^']+)',?$/.anchorsMatchLineEndings()).map { String($0.1) }

				// A file in another format has no names, so it is not saved over the cached one.
				guard !names.isEmpty else {
					throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "The file has no package names."))
				}

				return names
			}
		} ?? []
	}
}

/**
A page of the npm search.
*/
private struct SearchResult: Decodable {
	private struct Object: Decodable {
		struct Package: Decodable {
			struct Links: Decodable {
				let repository: String?
			}

			let name: String
			let version: String
			let description: String?
			let date: String
			let links: Links?
		}

		struct Downloads: Decodable {
			let weekly: Int
		}

		/**
		The number of dependents, which the search has as a string, like `"3845"`, or for some packages as a number. Any other value is unknown, so it does not leave out the page.
		*/
		struct Dependents: Decodable {
			let count: Int?

			init(from decoder: any Decoder) throws {
				let container = try decoder.singleValueContainer()
				self.count = (try? container.decode(Int.self)) ?? (try? container.decode(String.self)).flatMap { Int($0) }
			}
		}

		let package: Package
		let downloads: Downloads?
		let dependents: Dependents?
	}

	/**
	The most packages that a page can have.
	*/
	static let pageSize = 250

	let total: Int
	private let objects: [Object]

	/**
	The packages of the page. A package with a date that cannot be read is left out.
	*/
	var packages: [NPMStatistics.Package] {
		objects.compactMap { object in
			// Read here, not by the decoder, so one date that cannot be read leaves out its package, not the page.
			guard let date = try? Date(object.package.date, strategy: .iso8601) else {
				return nil
			}

			let repository = object.package.links?.repository.flatMap(GitHubRepositoryName.init(npmRepositoryLink:))

			// Without the backticks of code, which some descriptions have, as the description is shown as text.
			let description = object.package.description?.replacing("`", with: "").trimmingCharacters(in: .whitespaces)

			return NPMStatistics.Package(name: object.package.name, version: object.package.version, description: description?.isEmpty == false ? description : nil, date: date, weeklyDownloads: object.downloads?.weekly, dependentCount: object.dependents?.count, repository: repository)
		}
	}
}
