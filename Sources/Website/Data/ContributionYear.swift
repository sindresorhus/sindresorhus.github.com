import Foundation
import SiteKit

/**
The GitHub contributions of one year, for the career quilt.
*/
struct ContributionYear: Sendable {
	let year: Int
	let calendar: ContributionCalendar

	/**
	The contributions of the year by kind, like the commits. `nil` when they were not loaded.
	*/
	let totals: Totals?

	/**
	The days of the year up to the build date. The calendar of the current year goes on to the end of the year, and one day after it.
	*/
	let days: [ContributionCalendar.Day]

	/**
	The year of the first contributions in the quilt.
	*/
	static let firstYear = 2010

	/**
	The contributions of a year by kind, from the same request as the calendar.
	*/
	struct Totals: Decodable, Sendable {
		let commitCount: Int
		let pullRequestCount: Int
		let issueCount: Int
		let reviewCount: Int
		let repositoryCount: Int

		enum CodingKeys: String, CodingKey {
			case commitCount = "totalCommitContributions"
			case pullRequestCount = "totalPullRequestContributions"
			case issueCount = "totalIssueContributions"
			case reviewCount = "totalPullRequestReviewContributions"
			case repositoryCount = "totalRepositoryContributions"
		}
	}

	init(year: Int, calendar: ContributionCalendar, totals: Totals? = nil, until date: Date) {
		let today = date.isoDay
		self.year = year
		self.calendar = calendar
		self.totals = totals
		self.days = calendar.weeks.flatMap(\.days).filter { $0.date.hasPrefix("\(year)-") && $0.date <= today }
	}

	/**
	The busiest day of the year, the earliest when several days have the same count. `nil` for a year without contributions.
	*/
	var busiestDay: ContributionCalendar.Day? {
		days.reduce(nil) { busiest, day in
			day.count > (busiest?.count ?? 0) ? day : busiest
		}
	}

	/**
	The weekday of the first day of the year, from 0 for Sunday to 6 for Saturday, like the rows of the calendar.
	*/
	var firstWeekday: Int {
		guard let date = days.first?.startOfDay else {
			return 0
		}

		return Calendar.site.component(.weekday, from: date) - 1
	}

	/**
	The total of the year and its busiest day, like “4,078 contributions. The busiest day was March 3, with 92.”
	*/
	var summary: String {
		let total = "\(calendar.totalCount.formatted(counting: "contribution"))."

		guard
			let busiestDay,
			let date = busiestDay.startOfDay
		else {
			return total
		}

		return "\(total) The busiest day was \(date.formatted(.siteDayWithoutYear)), with \(busiestDay.count.formatted(.number.locale(.site)))."
	}

	/**
	The contributions of every year since ``firstYear``, oldest first, with one request for each year at the same time. The GraphQL API needs a token, so it is `nil` without one.

	A past year does not change once its last contributions show, which takes GitHub up to a day, so its response is cached for 100 years from a week after the year ended. The current year asks with only a start date, so its response has another cache key, and a past year that was cached as the current year is asked for again.
	*/
	static func load(github: GitHub, until date: Date) async throws -> [Self]? {
		guard github.token != nil else {
			return nil
		}

		let currentYear = date.siteYear
		let lastSettledYear = date.addingTimeInterval(-(Duration.days(7) / .seconds(1))).siteYear - 1

		return try await withThrowingTaskGroup { group in
			for year in firstYear...currentYear {
				group.addTask {
					let contributions = try await contributions(of: year, isPastYear: year < currentYear, isSettled: year <= lastSettledYear, github: github)
					return Self(year: year, calendar: contributions.contributionCalendar, totals: contributions.totals, until: date)
				}
			}

			return try await group.reduce(into: []) { $0.append($1) }.sorted(using: KeyPathComparator(\.year))
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

	private static func contributions(of year: Int, isPastYear: Bool, isSettled: Bool, github: GitHub) async throws -> Contributions {
		struct Content: Decodable {
			struct User: Decodable {
				let contributionsCollection: Contributions
			}

			let user: User
		}

		let fields = "contributionCalendar { totalContributions weeks { contributionDays { date contributionCount contributionLevel } } } totalCommitContributions totalPullRequestContributions totalIssueContributions totalPullRequestReviewContributions totalRepositoryContributions"
		let query = isPastYear
			? "query($from: DateTime!, $to: DateTime!) { user(login: \"sindresorhus\") { contributionsCollection(from: $from, to: $to) { \(fields) } } }"
			: "query($from: DateTime!) { user(login: \"sindresorhus\") { contributionsCollection(from: $from) { \(fields) } } }"

		var variables = ["from": "\(year)-01-01T00:00:00Z"]

		if isPastYear {
			variables["to"] = "\(year)-12-31T23:59:59Z"
		}

		return try await github.graphQL(Content.self, query: query, variables: variables, maximumAge: isSettled ? .days(365 * 100) : nil).user.contributionsCollection
	}
}

extension [ContributionYear] {
	/**
	The contributions of all the years, like all the contributions since ``ContributionYear/firstYear`` for the years of the career quilt.
	*/
	var totalCount: Int {
		map(\.calendar.totalCount).reduce(0, +)
	}
}
