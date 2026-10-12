import Foundation

/**
The GitHub contributions of the last year, by day, like the calendar on a GitHub profile.
*/
struct ContributionCalendar: Decodable, Sendable {
	struct Day: Decodable, Sendable {
		/**
		How many contributions the day has, compared to the other days, like on GitHub.
		*/
		enum Level: String, Decodable, Sendable, CaseIterable {
			case none = "NONE"
			case first = "FIRST_QUARTILE"
			case second = "SECOND_QUARTILE"
			case third = "THIRD_QUARTILE"
			case fourth = "FOURTH_QUARTILE"
		}

		/**
		The day, like `2026-10-07`.
		*/
		let date: String

		let count: Int
		let level: Level

		enum CodingKeys: String, CodingKey {
			case date
			case count = "contributionCount"
			case level = "contributionLevel"
		}

		/**
		The start of the day in UTC, or `nil` when the date is not a day, like `2026-10-07`.
		*/
		var startOfDay: Date? {
			try? Date(date, strategy: .iso8601.year().month().day())
		}

		/**
		The weekday of the day, from 0 for Sunday to 6 for Saturday, like the rows of the calendar. `nil` when the date is not a day.
		*/
		var weekday: Int? {
			startOfDay.map { Calendar.site.component(.weekday, from: $0) - 1 }
		}
	}

	struct Week: Decodable, Sendable {
		/**
		The days from Sunday to Saturday. The first and the last week can have fewer days.
		*/
		let days: [Day]

		enum CodingKeys: String, CodingKey {
			case days = "contributionDays"
		}
	}

	let totalCount: Int
	let weeks: [Week]

	enum CodingKeys: String, CodingKey {
		case totalCount = "totalContributions"
		case weeks
	}

	/**
	All the days, oldest first.
	*/
	var days: [Day] {
		weeks.flatMap(\.days)
	}

	/**
	The number of days in a row with contributions, up to the last day. The last day is today, which may not have contributions yet, so then the streak ends the day before.
	*/
	var currentStreak: Int {
		let days = self.days
		let pastDays = days.last?.count == 0 ? days.dropLast() : days[...]
		return pastDays.reversed().prefix { $0.count > 0 }.count
	}

	/**
	The contributions of each 7 days in a row, oldest first, up to the last day, like the 52 weeks of the last year. The last week is the last 7 days, not a calendar week, so it is a whole week. The days before the first whole week are left out.
	*/
	var weeklyCounts: [Int] {
		let counts = days.map(\.count)
		return stride(from: counts.count % 7, to: counts.count, by: 7).map { counts[$0..<($0 + 7)].sum }
	}
}
