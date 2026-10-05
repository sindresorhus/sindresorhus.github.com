import Foundation
import SiteKit

/**
What Sindre did lately on Bluesky and GitHub, for the now page.

All of it is extra, so a failed request leaves out its part, with a warning, instead of failing the build. The contributions and the sponsors need a GitHub token, so without one they are left out without a warning.
*/
struct RecentActivity: Sendable {
	var blueskyPost: BlueskyPost?
	var contributions: ContributionCalendar?
	var sponsorCount: Int?

	/**
	The pull requests by Sindre that were merged in the last 7 days.
	*/
	var mergedPullRequestCount: Int?

	/**
	The issues in the repos of Sindre that were closed in the last 7 days.
	*/
	var closedIssueCount: Int?

	/**
	The latest releases of the open-source projects, newest first.
	*/
	var releases = [OpenSourceRelease]()

	/**
	The start of the week of the numbers, like the merged pull requests: 7 days before the build, rounded down to the hour, so the search requests of builds in the same hour have the same cache key.
	*/
	static func weekStart(before buildDate: Date) -> Date {
		let start = buildDate.timeIntervalSince1970 - (Duration.days(7) / .seconds(1))
		return Date(timeIntervalSince1970: (start / 3600).rounded(.down) * 3600)
	}

	static func load(github: GitHub, cache: ResponseCache, buildDate: Date, warnings: WarningCollector) async -> Self {
		// The time too, not only the day, so the searches count the same 7 days as the npm releases.
		let weekStart = weekStart(before: buildDate).formatted(.iso8601)

		// Child tasks, so the requests run at the same time, and are cancelled with the build.
		async let blueskyPost = value(missing: "the latest Bluesky post", warnings: warnings) {
			try await BlueskyPost.latest(cache: cache)
		}
		async let profile = value(missing: "the GitHub contributions and sponsors", warnings: warnings) {
			try await github.contributionsAndSponsors()
		}
		async let mergedPullRequestCount = value(missing: "the number of merged pull requests", warnings: warnings) {
			try await github.issueCount(matching: "is:pr is:merged author:sindresorhus merged:>=\(weekStart)")
		}
		async let closedIssueCount = value(missing: "the number of closed issues", warnings: warnings) {
			try await github.issueCount(matching: "is:issue is:closed user:sindresorhus closed:>=\(weekStart)")
		}
		async let releases = value(missing: "the latest open-source releases", warnings: warnings) {
			try await github.latestReleases()
		}

		var activity = Self()
		activity.blueskyPost = await blueskyPost ?? nil
		let loadedProfile = await profile ?? nil
		activity.contributions = loadedProfile?.contributions
		activity.sponsorCount = loadedProfile?.sponsorCount
		activity.mergedPullRequestCount = await mergedPullRequestCount
		activity.closedIssueCount = await closedIssueCount
		activity.releases = await releases ?? []
		return activity
	}

	/**
	The value of the request, or `nil` with a warning when it fails, so the now page leaves the value out.
	*/
	private static func value<Value: Sendable>(missing: String, warnings: WarningCollector, _ request: @Sendable () async throws -> Value) async -> Value? {
		do {
			return try await request()
		} catch {
			warnings.add(Warning(message: "Could not get \(missing), so the now page leaves it out: \(error)"))
			return nil
		}
	}
}
