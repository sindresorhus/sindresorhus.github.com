import Foundation
import SiteKit
import SOML

/**
The GitHub contributions of the last year, by day, like the calendar on a GitHub profile.
*/
struct ContributionCalendar: Decodable {
	/**
	The fields shared by queries that decode a contribution calendar.
	*/
	static let selection = "contributionCalendar { totalContributions weeks { contributionDays { date contributionCount } } }"

	/**
	The weekdays in the site's Sunday-first calendar, with Foundation's values and an explicit zero-based plotting index.
	*/
	enum Weekday: Int, CaseIterable, Sendable {
		case sunday = 1
		case monday
		case tuesday
		case wednesday
		case thursday
		case friday
		case saturday

		/**
		The weekday containing a date in the site's UTC calendar.
		*/
		init(date: Date) {
			guard let weekday = Self(rawValue: Calendar.site.component(.weekday, from: date)) else {
				preconditionFailure("The Gregorian calendar must return a weekday from 1 through 7.")
			}

			self = weekday
		}

		/**
		The row of the weekday, from zero for Sunday to six for Saturday.
		*/
		var index: Int {
			rawValue - 1
		}
	}

	/**
	A contribution calendar as a patch of a card, like a year of the career quilt: the level of each day, after a blank for each weekday before its first day, as the first week can start after Sunday, so each weekday is in its row. HTML and social-card renderers share this input and own their colors and layout.
	*/
	struct Plot {
		let blankDayCount: Int
		let levels: [ContributionScale.Level]

		/**
		Maps the days onto Sunday-first rows and contribution levels.
		*/
		init(days: [Day], scale: ContributionScale) {
			self.blankDayCount = days.first?.weekday.index ?? 0
			self.levels = days.map { scale.level(for: $0.count) }
		}

		/**
		The number of days with the blanks.
		*/
		var dayCount: Int {
			blankDayCount + levels.count
		}
	}

	struct Day: Decodable {
		/**
		The calendar day, from a date like `2026-10-07`, without a time or time zone.
		*/
		let date: SOML.Date

		let count: Int

		enum CodingKeys: String, CodingKey {
			case date
			case count = "contributionCount"
		}

		init(from decoder: any Decoder) throws {
			let container = try decoder.container(keyedBy: CodingKeys.self)
			// A day, like `2026-10-07`, not a date with a time, so it is read here, not by the date strategy of the decoder.
			self.date = try container.decode(SOML.Date.self, forKey: .date)
			self.count = try container.decode(Int.self, forKey: .count)
		}

		/**
		The weekday of the day, whose index gives its Sunday-first calendar row.
		*/
		var weekday: Weekday {
			Weekday(date: date.foundationDate)
		}
	}

	struct Week: Decodable {
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
		let days = days
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

/**
The levels of the colors of the contribution calendars, from the counts of the days, so a day has the same color in the heatmap of the last year and in the career quilt, and the colors of two years compare. GitHub has levels too, but it computes them for each calendar from its busiest day, so one busy day makes almost every other day of the calendar the lightest color.

The levels are the quartiles of the days with contributions: a quarter of them are in each level.

```swift
let scale = ContributionScale(days: years.flatMap(\.days))
scale.level(for: 5)
//=> .second
```
*/
struct ContributionScale {
	/**
	How many contributions a day has, compared to the other days.
	*/
	enum Level: Int, CaseIterable {
		case none
		case first
		case second
		case third
		case fourth
	}

	/**
	The highest count of each of the first three levels with contributions, like `[3, 7, 13]`. Empty without contributions.
	*/
	let upperBounds: [Int]

	/**
	The highest count of a day, like 24, or 0 without contributions. A level above every day, like the fourth when many days have the same count, has no text in the legend.
	*/
	let maximumCount: Int

	/**
	The scale of the days, from the counts of the days with contributions. Each upper bound is the count at a quarter, a half, and three quarters of the sorted counts (the nearest rank).
	*/
	init(days: [ContributionCalendar.Day]) {
		let counts = days.map(\.count).filter { $0 > 0 }.sorted()
		self.upperBounds = counts.isEmpty ? [] : [1, 2, 3].map { counts[(counts.count - 1) * $0 / 4] }
		self.maximumCount = counts.last ?? 0
	}

	/**
	The level of a day with the count, like `.second` for 5 with the upper bounds `[3, 7, 13]`.
	*/
	func level(for count: Int) -> Level {
		guard count > 0 else {
			return .none
		}

		return Level(rawValue: 1 + upperBounds.count { count > $0 }) ?? .fourth
	}

	/**
	The counts of a level as text, like “4–7” or “14+”, for the legend of the colors. `nil` for a level without counts, like a level with the same upper bound as the level before it.
	*/
	func countText(of level: Level) -> String? {
		guard level != .none else {
			return "0"
		}

		guard !upperBounds.isEmpty else {
			return nil
		}

		let bounds = [0] + upperBounds
		let lowerBound = bounds[level.rawValue - 1] + 1

		guard level != .fourth else {
			// The busiest days do not have to be in the fourth level, like when many days have the same count, so it can have no counts.
			return lowerBound <= maximumCount ? "\(lowerBound)+" : nil
		}

		let upperBound = bounds[level.rawValue]

		guard lowerBound <= upperBound else {
			return nil
		}

		return lowerBound == upperBound ? "\(upperBound)" : "\(lowerBound)–\(upperBound)"
	}
}

extension SiteContent {
	/**
	The scale of the colors of the contribution calendars, from the days of all the years of the career quilt, or from the days of the last year when the build has no years.
	*/
	var contributionScale: ContributionScale {
		contributionYears.isEmpty ? ContributionScale(days: recentActivity.profile?.contributions.days ?? []) : contributionYears.contributionScale
	}
}
