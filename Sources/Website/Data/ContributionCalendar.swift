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
	The number of days in a row with contributions, up to the last day. The last day is today, which may not have contributions yet, so then the streak ends the day before.
	*/
	var currentStreak: Int {
		let days = weeks.flatMap(\.days)
		let pastDays = days.last?.count == 0 ? days.dropLast() : days[...]
		return pastDays.reversed().prefix { $0.count > 0 }.count
	}
}
