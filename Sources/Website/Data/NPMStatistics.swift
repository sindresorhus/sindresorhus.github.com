import Foundation
import SiteKit

/**
The npm packages of the `sindresorhus` account: how many there are, how many packages depend on them, how often they are downloaded in total, and how they compare with all of npm.

On purpose, the package count and the weekly downloads include all the packages that `sindresorhus` maintains, also the ones in the repositories of other people, like `yeoman-generator`. The latest releases of the now page only show the packages of his own repositories and those of his organizations.

The numbers are extra, so a failed request leaves out its number, with a warning, instead of failing the build.
*/
struct NPMStatistics {
	/**
	The number of packages that `sindresorhus` maintains.
	*/
	var packageCount: Int? {
		switch search {
		case .unavailable:
			nil
		case .countOnly(let count), .complete(let count, _):
			count
		}
	}

	/**
	All the packages, from a complete npm search. `nil` when a request failed or a nonzero search returned an empty page, as partial totals would be wrong.
	*/
	var packages: [Package]? {
		guard case .complete(_, let packages) = search else {
			return nil
		}

		return packages
	}

	/**
	The packages for the list of the open-source page, without the ones that have no repository, as they have nothing to read about them, like placeholders, and without the ones of ``unlistedPackageNames``. The numbers of the about page and the now page still count them all. `nil` like ``packages``.
	*/
	var listedPackages: [Package]? {
		packages?.filter { package in
			package.repository != nil
				&& !Self.unlistedPackageNames.contains(package.name)
		}
	}

	/**
	For now, the packages that the list leaves out by name, until they are fixed or deprecated on npm: `enva` is an empty placeholder, and the description of `@ava/bucklescript` is the start of its readme, with the badges.
	*/
	private static let unlistedPackageNames: Set = ["enva", "@ava/bucklescript"]

	/**
	Whether the search is unavailable, has only its advertised count, or returned all pages. A complete search can omit packages with unreadable dates.
	*/
	enum Search {
		case unavailable
		case countOnly(Int)
		case complete(total: Int, packages: [Package])
	}

	var search = Search.unavailable

	/**
	The downloads of all the packages on npm in the last week, like 183,646,517,192.
	*/
	var registryWeeklyDownloads: Int?

	/**
	The names of the most-downloaded packages on npm, most downloaded first, from [npm-high-impact](https://github.com/wooorm/npm-high-impact). Empty when the request failed.
	*/
	var mostDownloadedPackageNames = [String]()

	struct Package {
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
		packages?.compactMap(\.weeklyDownloads).nilIfEmpty?.sum
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
		packages?.compactMap(\.dependentCount).nilIfEmpty?.sum
	}

	/**
	How many packages are in the GitHub repos, like `sindresorhus/ky`. The now page counts the packages in the repos that were made this year as new, as the npm search has no date of the first version. `nil` when the search did not give the packages.
	*/
	func packageCount(inRepositories repositories: [GitHubRepositoryName]) -> Int? {
		let repositories = Set(repositories)
		return packages?.count { $0.repository.map(repositories.contains) ?? false }
	}

	/**
	How many packages have a version since the date, like the start of the week. `nil` when the search did not give the packages. The search only has the date of the latest version, so a new package counts as updated too.
	*/
	func updatedPackageCount(since start: Date) -> Int? {
		packages?.count { $0.date >= start }
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
			let packages,
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
				let page = try await cache.decoded(SearchResult.self, from: url)
				let total = statistics.packageCount ?? page.total
				statistics.search = .countOnly(total)
				// An empty wire page with a nonzero total is incomplete, even if all earlier pages loaded.
				guard page.entryCount > 0 || page.total == 0 else {
					break
				}

				packages += page.packages

				guard offset + SearchResult.pageSize < page.total else {
					statistics.search = .complete(total: total, packages: packages)
					break
				}
			}
		} catch {
			// Without all the pages, the packages are left out, and only the number of packages can remain.
			var missing = ["their dependents", "their weekly downloads", "their share of all the downloads", "how many of the most-downloaded packages are his"]

			if statistics.packageCount == nil {
				missing.insert("their number", at: 0)
			}

			warnings.add(Warning(.failedRequest, "Could not get the npm packages, so the about page leaves out \(missing.formattedList(.and)), and the now page leaves out the npm releases and the numbers of new and updated packages: \(error)"))
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
			try await cache.decoded(Downloads.self, from: #URL("https://api.npmjs.org/downloads/point/last-week")).downloads
		}
	}

	/**
	The names of the most-downloaded packages, from the list of npm-high-impact, which is a JavaScript file with each name in single quotes on its own line, like `  'chalk',`. Empty with a warning when the request failed or the file has no names.
	*/
	private static func mostDownloadedPackageNames(cache: ResponseCache, warnings: WarningCollector) async -> [String] {
		await warnings.value(warning: "Could not get the most-downloaded npm packages, so the about page leaves out how many of them are his") {
			try await cache.decoded(from: #URL("https://unpkg.com/npm-high-impact/lib/top-download.js")) { data in
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

	/**
	The number of wire entries, including packages omitted because their dates cannot be read, for pagination.
	*/
	let entryCount: Int

	enum CodingKeys: String, CodingKey {
		case total
		case objects
	}

	/**
	The packages of the page. A package with a date that cannot be read is left out.
	*/
	let packages: [NPMStatistics.Package]

	init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		self.total = try container.decode(Int.self, forKey: .total)
		let objects = try container.decode([Object].self, forKey: .objects)
		self.entryCount = objects.count
		// Parse the dates and repository links once, while decoding the page.
		self.packages = objects.compactMap { object in
			// Read here, not by the decoder, so one date that cannot be read leaves out its package, not the page.
			guard let date = try? Date(object.package.date, strategy: .iso8601) else {
				return nil
			}

			let repository = object.package.links?.repository.flatMap(GitHubRepositoryName.init(npmRepositoryLink:))

			// Without the backticks of code, which some descriptions have, as the description is shown as text.
			let description = object.package.description?.replacing("`", with: "").trimmingCharacters(in: .whitespaces)

			return NPMStatistics.Package(
				name: object.package.name,
				version: object.package.version,
				description: description?.nilIfEmpty,
				date: date,
				weeklyDownloads: object.downloads?.weekly,
				dependentCount: object.dependents?.count,
				repository: repository
			)
		}
	}
}
