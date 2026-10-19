import Foundation
import SiteKit

/**
The GitHub contributions of one year, for the career quilt.
*/
struct ContributionYear: Sendable {
	let year: Int
	let calendar: ContributionCalendar

	/**
	The contributions of the year by kind, like the commits.
	*/
	let totals: Totals

	/**
	The days of the year up to the build date. The calendar of the current year goes on to the end of the year, and one day after it.
	*/
	let days: [ContributionCalendar.Day]

	/**
	The year of the first contributions in the quilt.
	*/
	static let firstYear = 2010

	/**
	The contributions of a year by kind, and the repositories with the most commits, from the same request as the calendar.
	*/
	struct Totals: Decodable, Sendable {
		let commitCount: Int
		let pullRequestCount: Int
		let reviewCount: Int
		let repositoryCount: Int

		/**
		The repositories with commits in the year, like 522.
		*/
		let committedRepositoryCount: Int

		/**
		The five repositories with the most commits in the year, most first. GitHub only counts the commits of the default branch. It includes private repositories when the token can see them, like a personal token, so a page that shows them leaves those out.
		*/
		let repositoryCommits: [RepositoryCommits]

		enum CodingKeys: String, CodingKey {
			case commitCount = "totalCommitContributions"
			case pullRequestCount = "totalPullRequestContributions"
			case reviewCount = "totalPullRequestReviewContributions"
			case repositoryCount = "totalRepositoryContributions"
			case committedRepositoryCount = "totalRepositoriesWithContributedCommits"
			case repositoryCommits = "commitContributionsByRepository"
		}
	}

	/**
	The commits of a year in one repository.
	*/
	struct RepositoryCommits: Decodable, Sendable {
		/**
		The repository, like `sindresorhus/ky`.
		*/
		let repository: GitHubRepositoryName

		let url: URL
		let count: Int
		let isPrivate: Bool

		private struct Repository: Decodable {
			let nameWithOwner: GitHubRepositoryName
			let url: URL
			let isPrivate: Bool
		}

		private struct Contributions: Decodable {
			let totalCount: Int
		}

		enum CodingKeys: CodingKey {
			case repository
			case contributions
		}

		init(from decoder: any Decoder) throws {
			let container = try decoder.container(keyedBy: CodingKeys.self)
			let repository = try container.decode(Repository.self, forKey: .repository)
			self.repository = repository.nameWithOwner
			self.url = repository.url
			self.isPrivate = repository.isPrivate
			self.count = try container.decode(Contributions.self, forKey: .contributions).totalCount
		}
	}

	init(year: Int, calendar: ContributionCalendar, totals: Totals, until date: Date) {
		self.year = year
		self.calendar = calendar
		self.totals = totals
		self.days = calendar.days.filter { Calendar.site.component(.year, from: $0.date) == year && $0.date <= date }
	}

	/**
	The busiest day of the year, the earliest when several days have the same count. `nil` for a year without contributions.
	*/
	var busiestDay: ContributionCalendar.Day? {
		days.busiest
	}

	/**
	The number of days of the year with contributions, like 271.
	*/
	var activeDayCount: Int {
		days.count { $0.count > 0 }
	}

	/**
	The total of the year and its busiest day, like “4,078 contributions. The busiest day was March 3, with 92.”
	*/
	var summary: String {
		let total = "\(calendar.totalCount.formatted(counting: "contribution"))."

		guard let busiestDay else {
			return total
		}

		return "\(total) The busiest day was \(busiestDay.date.formatted(.siteDayWithoutYear)), with \(busiestDay.count.formatted(.number.locale(.site)))."
	}

	/**
	The contributions of every year since ``firstYear``, oldest first, with one request for each year at the same time. The GraphQL API needs a token, so it is empty without one.

	A past year does not change once its last contributions show, which takes GitHub up to a day, so a response fetched more than a week after the year ended is used for good: its maximum age is the time since then, so only a response fetched earlier is asked for again. The current year asks with only a start date, so its response has another cache key, and a past year that was cached as the current year is asked for again.
	*/
	static func load(github: GitHub, until date: Date) async throws -> [Self] {
		guard github.token != nil else {
			return []
		}

		let currentYear = date.siteYear

		return try await (firstYear...currentYear).concurrentMap { year in
			let timeSinceSettled = date.duration(since: Date(year: year + 1, month: 1, day: 8))
			let contributions = try await contributions(of: year, isPastYear: year < currentYear, maximumAge: timeSinceSettled > .zero ? timeSinceSettled : nil, github: github)
			return Self(year: year, calendar: contributions.contributionCalendar, totals: contributions.totals, until: date)
		}
	}

	/**
	The calendar and the totals by kind of one year.
	*/
	private struct Contributions: Decodable {
		let contributionCalendar: ContributionCalendar
		let totals: Totals

		enum CodingKeys: CodingKey {
			case contributionCalendar
		}

		init(from decoder: any Decoder) throws {
			self.contributionCalendar = try decoder.container(keyedBy: CodingKeys.self).decode(ContributionCalendar.self, forKey: .contributionCalendar)
			// The totals are next to the calendar in the response.
			self.totals = try Totals(from: decoder)
		}
	}

	private static func contributions(of year: Int, isPastYear: Bool, maximumAge: Duration?, github: GitHub) async throws -> Contributions {
		struct Content: Decodable {
			struct User: Decodable {
				let contributionsCollection: Contributions
			}

			let user: User
		}

		let fields = "contributionCalendar { totalContributions weeks { contributionDays { date contributionCount contributionLevel } } } totalCommitContributions totalPullRequestContributions totalPullRequestReviewContributions totalRepositoryContributions totalRepositoriesWithContributedCommits commitContributionsByRepository(maxRepositories: 5) { repository { nameWithOwner url isPrivate } contributions { totalCount } }"
		let query = isPastYear
			? "query($from: DateTime!, $to: DateTime!) { user(login: \"\(GitHub.account)\") { contributionsCollection(from: $from, to: $to) { \(fields) } } }"
			: "query($from: DateTime!) { user(login: \"\(GitHub.account)\") { contributionsCollection(from: $from) { \(fields) } } }"

		var variables = ["from": "\(year)-01-01T00:00:00Z"]

		if isPastYear {
			variables["to"] = "\(year)-12-31T23:59:59Z"
		}

		return try await github.graphQL(Content.self, query: query, variables: variables, maximumAge: maximumAge).user.contributionsCollection
	}
}

extension [ContributionYear] {
	/**
	The contributions of all the years, like all the contributions since ``ContributionYear/firstYear`` for the years of the career quilt.
	*/
	var totalCount: Int {
		map(\.calendar.totalCount).sum
	}

	/**
	The most days in a row with contributions in all the years, like 412. The years are oldest first, so a streak goes on from one year to the next.
	*/
	var longestStreak: Int {
		flatMap(\.days).split { $0.count == 0 }.map(\.count).max() ?? 0
	}

	/**
	The sum of a number of the totals of all the years, like the commits.
	*/
	func total(_ keyPath: KeyPath<ContributionYear.Totals, Int>) -> Int {
		map { $0.totals[keyPath: keyPath] }.sum
	}

	/**
	The busiest day of all the years, the earliest when several days have the same count. `nil` without contributions.
	*/
	var busiestDay: ContributionCalendar.Day? {
		flatMap(\.days).busiest
	}

	/**
	The weekday with the most contributions in all the years, from 0 for Sunday to 6 for Saturday (``ContributionCalendar/Day/weekday``), and its contributions. The earliest in the week when several have the same count. `nil` without contributions.
	*/
	var busiestWeekday: (weekday: Int, count: Int)? {
		var counts = [Int](repeating: 0, count: 7)

		for day in flatMap(\.days) {
			counts[day.weekday] += day.count
		}

		guard
			let highest = counts.max(),
			highest > 0,
			let weekday = counts.firstIndex(of: highest)
		else {
			return nil
		}

		return (weekday, highest)
	}
}

extension Sequence<ContributionCalendar.Day> {
	/**
	The day with the most contributions, the first when several days have the same count. `nil` without contributions.
	*/
	fileprivate var busiest: Element? {
		reduce(nil) { busiest, day in
			day.count > (busiest?.count ?? 0) ? day : busiest
		}
	}
}
