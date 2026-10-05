import Foundation
import SiteKit

/**
The npm packages of the `sindresorhus` account: how many there are, and how often they are downloaded in total.

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

	struct Package: Sendable {
		let name: String
		let version: String

		/**
		When the latest version was published.
		*/
		let date: Date

		let weeklyDownloads: Int

		/**
		The owner of the GitHub repository of the package, like `chalk` for `https://github.com/chalk/chalk`. `nil` when the package has no GitHub repository.
		*/
		let repositoryOwner: String?

		var url: URL {
			#URL("https://www.npmjs.com/package/").appending(path: name)
		}
	}

	/**
	The downloads of all the packages in the last week, when the search worked.
	*/
	var weeklyDownloads: Int? {
		packages.isEmpty ? nil : packages.map(\.weeklyDownloads).reduce(0, +)
	}

	/**
	Gets the packages with the npm search, 250 at a time, with their weekly downloads.
	*/
	static func load(cache: ResponseCache, warnings: WarningCollector) async -> Self {
		var statistics = Self()

		do {
			var packages = [Package]()

			for offset in stride(from: 0, to: Int.max, by: SearchResult.pageSize) {
				let page = try await cache.decoded(SearchResult.self, from: URLRequest(url: URL(string: "https://registry.npmjs.org/-/v1/search?text=maintainer:sindresorhus&size=\(SearchResult.pageSize)&from=\(offset)")!, timeoutInterval: 15))
				statistics.packageCount = statistics.packageCount ?? page.total
				packages += page.packages

				guard
					!page.packages.isEmpty,
					offset + SearchResult.pageSize < page.total
				else {
					break
				}
			}

			statistics.packages = packages
		} catch {
			let missing = statistics.packageCount == nil ? "the number of npm packages and their weekly downloads, so the about page and the now page leave them out" : "all the npm packages, so the about page and the now page leave out their weekly downloads"
			warnings.add(Warning(message: "Could not get \(missing): \(error)"))
		}

		return statistics
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
			let date: String
			let links: Links?
		}

		struct Downloads: Decodable {
			let weekly: Int
		}

		let package: Package
		let downloads: Downloads?
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

			// The repository can be written in several ways, like `git+https://github.com/owner/name.git`.
			let repositoryOwner = object.package.links?.repository?.firstMatch(of: /github\.com[\/:]([^\/]+)\//).map { String($0.1) }

			return NPMStatistics.Package(name: object.package.name, version: object.package.version, date: date, weeklyDownloads: object.downloads?.weekly ?? 0, repositoryOwner: repositoryOwner)
		}
	}
}
