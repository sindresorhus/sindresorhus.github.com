import Foundation
import SiteKit

/**
What Sindre did lately on Bluesky and GitHub, like in the week and in the year, for the now page, and the comments of all time, for the about page, which are in the same request as the contributions.

All of it is extra, so a failed request leaves out its part, with a warning, instead of failing the build. The contributions, the sponsors, the comments, and the activity of the week need a GitHub token, so without one they are left out without a warning.
*/
struct RecentActivity {
	var blueskyPost: BlueskyPost?
	var contributions: ContributionCalendar?
	var sponsorCount: Int?

	/**
	The comments of Sindre on issues and pull requests of all time, for the about page. It needs a GitHub token.
	*/
	var commentCount: Int?

	/**
	The issues closed and the pull requests by other people merged in the week (``weekStart(before:)``), like the numbers of the year and of all time.
	*/
	var weekMaintenance: GitHub.Maintenance?

	/**
	The contributions, commits, and comments of Sindre in the week. It needs a GitHub token.
	*/
	var weekActivity: GitHub.Activity?

	/**
	The issues closed and the pull requests by other people merged in the year of the build, for the numbers of the year.
	*/
	var yearMaintenance: GitHub.Maintenance?

	/**
	The latest releases of the open-source projects, newest first.
	*/
	var releases = [OpenSourceRelease]()

	/**
	The start of the week of the numbers, like the issues closed: the start of the day (UTC) 6 days before the build, so the week is the 7 days up to and with the day of the build, like the last week of ``ContributionCalendar/weeklyCounts``. A whole day, as the GitHub contributions count whole days, so all the numbers of the week count the same days. The requests of builds on the same day then have the same cache key too.
	*/
	static func weekStart(before buildDate: Date) -> Date {
		Calendar.site.startOfDay(for: buildDate.addingTimeInterval(-(Duration.days(6) / .seconds(1))))
	}

	static func load(
		github: GitHub,
		cache: ResponseCache,
		buildDate: Date,
		warnings: WarningCollector
	) async -> Self {
		let weekStart = Self.weekStart(before: buildDate)

		// Child tasks, so the requests run at the same time, and are cancelled with the build.
		async let blueskyPost = warnings.value(warning: "Could not get the latest Bluesky post, so the page leaves that out") {
			try await BlueskyPost.latest(cache: cache)
		}
		async let profile = warnings.value(warning: "Could not get the GitHub contributions, sponsors, and comments, so the page leaves that out") {
			try await github.profile()
		}
		async let weekMaintenance = warnings.value(warning: "Could not get the issues closed and the pull requests merged this week, so the page leaves that out") {
			try await github.maintenance(since: weekStart)
		}
		async let releases = warnings.value(warning: "Could not get the latest open-source releases, so the page leaves that out") {
			try await github.latestReleases()
		}
		async let weekActivity = warnings.value(warning: "Could not get the GitHub contributions, commits, and comments of the week, so the page leaves that out") {
			try await github.activity(since: weekStart)
		}
		async let yearMaintenance = warnings.value(warning: "Could not get the issues closed and the pull requests merged this year, so the page leaves that out") {
			try await github.maintenance(since: Date(year: buildDate.siteYear, month: 1, day: 1))
		}

		var activity = Self()
		activity.blueskyPost = await blueskyPost ?? nil
		let loadedProfile = await profile ?? nil
		activity.contributions = loadedProfile?.contributions
		activity.sponsorCount = loadedProfile?.sponsorCount
		activity.commentCount = loadedProfile?.commentCount
		activity.weekMaintenance = await weekMaintenance
		activity.releases = await releases ?? []
		activity.weekActivity = await weekActivity ?? nil
		activity.yearMaintenance = await yearMaintenance
		return activity
	}
}
