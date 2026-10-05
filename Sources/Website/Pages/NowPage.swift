import Elementary
import Foundation
import SiteKit

/**
What Sindre is working on now, like the pages on https://nownownow.com: the hand-written status, focus, reading, and listening of `content/pages/now.md`, and what the build gets, so the rest never goes stale: the newest app, app updates, a review, GitHub and npm activity, and the latest posts.

Each part that the build could not get is left out. The latest commits are only loaded in the browser (`now.js`), which also shows a newer Bluesky post than the one of the build.
*/
struct NowPage: Page {
	let page: MarkdownPage
	let content: SiteContent

	var path: RoutePath {
		page.path
	}

	var metadata: PageMetadata {
		PageMetadata(title: page.title, description: page.description)
	}

	var sitemapEntry: SitemapEntry? {
		SitemapEntry(lastModified: lastChange)
	}

	var body: some HTML {
		ProsePage(title: page.title) {
			if let lastChange {
				// The text is in a span, so the stack keeps the space after “Updated”.
				p {
					span {
						"Updated "
						DateText(lastChange, format: .siteDay)
					}
				}
				.style(Styles.updated)
			}

			if let status = page.frontmatter.status {
				p {
					status
				}
				.style(Styles.status)
			}

			if let app = content.newestApp {
				newestApp(app)
			}

			page.markdown.content

			for (label, items) in [("Reading", page.frontmatter.reading), ("Listening to", page.frontmatter.listening)] where !items.isEmpty {
				p {
					strong {
						"\(label): "
					}
					items.map(\.value).formatted(.list(type: .and).locale(.site))
				}
			}

			buildingNow
			apps
			openSource
			latestPosts
			footerRow
		}

		ModuleScript("/scripts/now.js")
	}

	/**
	The newest app as a card that links to it. The light of the card is in the color of the icon.
	*/
	private func newestApp(_ app: App) -> some HTML {
		a(.href(app.url)) {
			AppIcon(decorative: app, size: 64, isAboveFold: true)
				.style(Styles.icon)

			span {
				span {
					"Newest App"
				}
				.style(Styles.eyebrow)

				span {
					app.title
				}
				.style(Styles.newestAppTitle)

				span {
					app.subtitle
				}
				.style(Styles.newestAppSubtitle)
			}
			.style(Styles.text)

			Icon.chevronRight.size(.rootEm(1.25))
		}
		.tint(app.tint)
		.style(Styles.newestApp)
	}

	/**
	A part of a section: a small title above a card, or above other content. The parts of a section are in two columns on larger screens, and a wide part spans both.
	*/
	private func group<Content: HTML>(_ title: String, isWide: Bool = false, @HTMLBuilder content: () -> Content) -> some HTML {
		div {
			h3 {
				title
			}
			.style(Styles.groupTitle)

			content()
		}
		.style(Styles.group)
		.style(Styles.wideGroup, when: isWide)
	}

	/**
	A link with an optional description below it, like a new project.
	*/
	private struct Row {
		let title: String
		let destination: LinkDestination
		let description: String?
	}

	/**
	Links in a card, one in each row, with thin lines between them, like the new projects.
	*/
	private func rows(_ rows: [Row]) -> some HTML {
		ul {
			for row in rows {
				li {
					a(.href(row.destination)) {
						row.title
					}

					if let description = row.description {
						span {
							description
						}
						.style(Styles.rowDescription)
					}
				}
				.style(Styles.row, Styles.stackedRow)
			}
		}
		.style(Styles.card, Styles.rows)
	}

	/**
	Numbers that stand out, each with a label below it, like “59” and “pull requests merged”.
	*/
	private func statRow(_ stats: [Stat]) -> some HTML {
		ul {
			for stat in stats {
				li {
					span {
						stat.value
					}
					.style(Styles.statValue)

					// A space between the number and the label, for copied text and screen readers. The stack does not show it.
					" "

					span {
						stat.label
					}
					.style(Styles.statLabel)
				}
				.style(Styles.stat)
			}
		}
		.style(Styles.card, Styles.stats)
	}

	/**
	The latest commits, the numbers of the week, and the contributions. The latest commits are only loaded in the browser, so without the other parts, the section is hidden until they load.
	*/
	private var buildingNow: some HTML {
		let contributions = content.recentActivity.contributions
		let weekStats = weekStats

		return Section("Building Now", id: "building-now") {
			div {
				div(.id(Hooks.latestCommits), .hidden) {
					h3 {
						"Right Now on GitHub"
					}
					.style(Styles.groupTitle)

					ul {}
						.style(Styles.card, Styles.rows)

					// `now.js` fills in the repo, the message, and when it was committed.
					template(.id(Hooks.commitTemplate)) {
						li {
							span {
								span {}
									.style(Styles.rowLabel)

								time {}
									.style(Styles.rowDate)
							}
							.style(Styles.rowHeader)

							a(.href(.url(#URL("https://github.com/sindresorhus")))) {}
						}
						.style(Styles.row, Styles.stackedRow)
					}
				}
				.style(Styles.group, Styles.wideGroup)

				if !weekStats.isEmpty {
					group("This Week in Open Source", isWide: true) {
						statRow(weekStats)
					}
				}

				if let contributions {
					group("Contributions", isWide: true) {
						div {
							ContributionHeatmap(calendar: contributions)

							p {
								"\(contributions.totalCount.formatted(.number.locale(.site))) contributions on GitHub in the last year, and a streak of \(contributions.currentStreak.formatted(counting: "day"))."

								// The quilt is only built with a GitHub token.
								if !content.contributionYears.isEmpty {
									" See every year in the "
									a(.href(.careerQuilt)) {
										"Career Quilt"
									}
									"."
								}
							}
							.style(Styles.caption)
						}
						.style(Styles.card)
					}
				}
			}
			.style(Styles.groups)
		}
		.attributes(.hidden, when: contributions == nil && weekStats.isEmpty)
	}

	@HTMLBuilder
	private var apps: some HTML {
		let updates = appUpdates
		// The newest five-star review of all the apps.
		let review = content.activeAppReviews.first
		let updateDateFormat = dayFormat(for: updates.map(\.date))

		if !updates.isEmpty || review != nil {
			Section("Apps", id: "apps") {
				div {
					if !updates.isEmpty {
						group("Latest Updates") {
							ul {
								for update in updates {
									li {
										AppIcon(decorative: update.app, size: 32)
											.style(Styles.icon)

										span {
											span {
												a(.href(update.destination)) {
													update.app.title
												}
												" "
												span {
													update.version
												}
												.style(Styles.version)
											}

											DateText(update.date, format: updateDateFormat)
												.style(Styles.rowDescription)
										}
										.style(Styles.text)
									}
									.style(Styles.row)
								}
							}
							.style(Styles.card, Styles.rows)
						}
					}

					if let review {
						group("A Recent Review") {
							QuoteFigure(kind: .review(review.review), app: review.app)
						}
					}
				}
				.style(Styles.groups)
			}
		}
	}

	@HTMLBuilder
	private var openSource: some HTML {
		let repositories = Array(content.recentRepositories.prefix(5))
		let releases = latestReleases
		let releaseDateFormat = dayFormat(for: releases.map(\.date))
		if !repositories.isEmpty || !releases.isEmpty {
			Section("Open Source", id: "open-source") {
				div {
					if !releases.isEmpty {
						group("Latest Releases") {
							ul {
								for release in releases {
									li {
										span {
											a(.href(.url(release.url))) {
												release.displayName
											}
											" "
											span {
												release.version
											}
											.style(Styles.version)
										}
										.style(Styles.rowLink)

										DateText(release.date, format: releaseDateFormat)
											.style(Styles.rowDate)
									}
									.style(Styles.row)
								}
							}
							.style(Styles.card, Styles.rows)
						}
					}

					if !repositories.isEmpty {
						group("New Projects") {
							rows(repositories.map { Row(title: $0.name, destination: .url($0.url), description: $0.summary) })
						}
					}
				}
				.style(Styles.groups)
			}
		}
	}

	@HTMLBuilder
	private var latestPosts: some HTML {
		let blueskyPost = content.recentActivity.blueskyPost
		let blogPosts = latestBlogPosts

		if blueskyPost != nil || !blogPosts.isEmpty {
			Section("Latest Posts", id: "posts") {
				div {
					if let blueskyPost {
						group("On Social Media") {
							div {
								span {
									Icon.bluesky.size(.rootEm(1.125))
									"Bluesky"
								}
								.style(Styles.postSource)

								// `now.js` replaces the text, the link, and the date with a newer post. The details are the next element after the quote.
								blockquote(.id(Hooks.blueskyPost)) {
									p {
										for segment in blueskyPost.segments {
											if let link = segment.link {
												a(.href(.url(link))) {
													segment.text
												}
											} else {
												segment.text
											}
										}
									}
									.style(Styles.postText)
								}
								.style(QuoteFigure.Styles.text)

								// The date links to the post. `now.js` changes the first link and the date for a newer post.
								p {
									a(.href(.url(blueskyPost.url))) {
										// With the year, like the date that `now.js` writes for a newer post. The `datetime` has the time, so `now.js` only shows a post that is newer.
										time(.custom(name: "datetime", value: blueskyPost.date.ISO8601Format())) {
											blueskyPost.date.formatted(.siteDay)
										}
									}
									.style(Styles.postFooterLink)

									" · Also on "

									for (index, link) in socialLinks.enumerated() {
										if index > 0 {
											index == socialLinks.count - 1 ? " and " : ", "
										}

										a(.href(.url(link.url))) {
											link.name
										}
										.style(Styles.postFooterLink)
									}
								}
								.style(Styles.postFooter)
							}
							.style(Styles.card, Styles.post)
						}
					}

					if !blogPosts.isEmpty {
						group("On the Blog") {
							rows(blogPosts.map { Row(title: $0.title, destination: $0.url, description: $0.description) })
						}
					}
				}
				.style(Styles.groups)
			}
		}
	}

	/**
	On this day in earlier years, the year so far, the sponsors, and where the idea of a now page is from.
	*/
	private var footerRow: some HTML {
		let anniversaries = onThisDay
		let yearStats = yearStats

		return footer {
			if !anniversaries.isEmpty {
				Section("On This Day", id: "on-this-day") {
					rows(anniversaries.map { Row(title: $0.title, destination: $0.destination, description: $0.description) })
				}
			}

			if !yearStats.isEmpty {
				Section("\(currentYear) So Far", id: "year") {
					statRow(yearStats)
				}
			}

			// The totals, after the numbers of the year, as the page is about what is happening now. The apps and the open-source work are apart, so it is clear what the users are of.
			Section("All Time", id: "all-time") {
				div {
					group("Apps", isWide: true) {
						statRow(allTimeAppStats)
					}

					// Without npm and contribution data, like in a build without the network, there are no open-source totals.
					if !allTimeOpenSourceStats.isEmpty {
						group("Open Source", isWide: true) {
							statRow(allTimeOpenSourceStats)
						}
					}
				}
				.style(Styles.groups)
			}

			if let sponsorCount = content.recentActivity.sponsorCount {
				p {
					"\(sponsorCount.formatted(.number.locale(.site))) people and companies "
					a(.href(.path(.supporters))) {
						"sponsor my open-source work"
					}
					"."
				}
			}

			// A quiet note at the end of the page, like a colophon.
			p {
				"This is a "
				a(.href(.url(#URL("https://nownownow.com/about")))) {
					"now page"
				}
				.style(Styles.colophonLink)
				", like on many other personal sites."
			}
			.style(Styles.colophon)
		}
	}

	/**
	The other places where the posts are, as the card already says Bluesky.
	*/
	private var socialLinks: [Person.SocialLink] {
		Site.author.socialLinks.filter { [.x, .mastodon].contains($0.icon) }
	}

	/**
	The three newest blog posts. Posts that only send visitors to another page, like an app page, are left out.
	*/
	private var latestBlogPosts: [BlogPost] {
		Array(content.listedPosts.filter { !$0.isRedirect }.prefix(3))
	}

	private struct AppUpdate {
		let app: App
		let version: String
		let date: Date
		let destination: LinkDestination
	}

	/**
	The five apps that were updated last, each with its latest version: the newer of the App Store version and the latest release of its releases repo.
	*/
	private var appUpdates: [AppUpdate] {
		let updates = content.activeAppsWithPages.compactMap { app in
			let release = app.releaseNotes.flatMap { releaseNotes in
				content.releases(of: app)
					.sorted(using: KeyPathComparator(\.publishedAt, order: .reverse))
					.first
					.map { AppUpdate(app: app, version: $0.version, date: $0.publishedAt, destination: releaseNotes.destination(of: $0)) }
			}

			let appStoreVersion = content.appStoreInfo(of: app).flatMap { info in
				info.version.flatMap { version in
					info.currentVersionReleaseDate.map { AppUpdate(app: app, version: version, date: $0, destination: app.url) }
				}
			}

			return [release, appStoreVersion]
				.compactMap(\.self)
				.sorted(using: KeyPathComparator(\.date, order: .reverse))
				.first
		}

		return Array(updates.sorted(using: KeyPathComparator(\.date, order: .reverse)).prefix(5))
	}

	private struct Release {
		/**
		The name of the project, like `execa`, without the scope of an npm package, like `is` for `@sindresorhus/is`, so a project is listed once.
		*/
		let name: String

		/**
		The name to show, like `execa` or `chalk/chalk`.
		*/
		let displayName: String

		let version: String
		let url: URL
		let date: Date
	}

	/**
	The five newest releases of the open-source projects: the GitHub releases, and the npm packages that were published without one. Only the newest release of each project.
	*/
	private var latestReleases: [Release] {
		let gitHubReleases = content.recentActivity.releases
			.filter { Self.releaseOwners.contains(String($0.repository.prefix { $0 != "/" })) }
			.map { release in
				Release(name: release.name, displayName: release.displayName, version: release.version, url: release.url, date: release.date)
			}

		let names = Set(gitHubReleases.map(\.name))

		// Only the packages of repositories that the same owners have, as the npm search also finds packages that he only helps maintain, like `yeoman-generator`.
		let npmReleases = content.npmStatistics.packages
			.filter { $0.repositoryOwner.map(Self.releaseOwners.contains) ?? false }
			.map { Release(name: String($0.name.split(separator: "/").last ?? ""), displayName: $0.name, version: $0.version, url: $0.url, date: $0.date) }
			.filter { !names.contains($0.name) }

		var listedNames = Set<String>()

		return Array(
			(gitHubReleases + npmReleases)
				.sorted(using: [KeyPathComparator(\.date, order: .reverse), KeyPathComparator(\.displayName, comparator: .localizedStandard)])
				.filter { listedNames.insert($0.name).inserted }
				.prefix(5)
		)
	}

	/**
	The owners of the repos whose releases the page shows: his own, and the organizations of his bigger projects.
	*/
	private static let releaseOwners: Set = ["sindresorhus", "xojs", "chalk", "soml-lang"]

	/**
	The format of the dates of a list: without the year when they are all in the year of the build, which is shorter and easier to read.
	*/
	private func dayFormat(for dates: [Date]) -> Date.FormatStyle {
		dates.allSatisfy { $0.siteYear == currentYear } ? .siteDayWithoutYear : .siteDay
	}

	/**
	When a week ago was, for the numbers of the week.
	*/
	private var weekStart: Date {
		RecentActivity.weekStart(before: content.buildDate)
	}

	/**
	A number with what it counts, like “59 pull requests merged”.
	*/
	private struct Stat {
		let count: Int

		/**
		What one of them is, like “pull request”. The label adds an “s” when the count is not 1.
		*/
		let noun: String

		/**
		The plural of the noun, for a noun that does not add an “s”, like “repositories”.
		*/
		var pluralNoun: String?

		/**
		What happened to them, like “merged”.
		*/
		var verb: String?

		/**
		Whether the count is rounded down and abbreviated, like “22B+”, for counts that are too large to read in full.
		*/
		var isApproximate = false

		var value: String {
			// No thousands separator, as the large numbers read better without it, like “3467”.
			isApproximate ? count.approximateCount : count.formatted(.number.grouping(.never).locale(.site))
		}

		var label: String {
			[count == 1 ? noun : pluralNoun ?? noun + "s", verb].compactMap(\.self).joined(separator: " ")
		}
	}

	/**
	The pull requests merged, the issues closed, and the npm packages published in the last 7 days.
	*/
	private var weekStats: [Stat] {
		let activity = content.recentActivity
		let publishedCount = content.npmStatistics.packages.isEmpty ? nil : content.npmStatistics.packages.count { $0.date >= weekStart }

		return [
			activity.mergedPullRequestCount.map { Stat(count: $0, noun: "pull request", verb: "merged") },
			activity.closedIssueCount.map { Stat(count: $0, noun: "issue", verb: "closed") },
			publishedCount.map { Stat(count: $0, noun: "npm package", verb: "published") },
		]
		.compactMap(\.self)
	}

	/**
	The totals of the apps of all the years, like “61 apps”, “6M+ users”, and “11 years of craft”.
	*/
	private var allTimeAppStats: [Stat] {
		[
			Stat(count: content.activeApps.count, noun: "app"),
			Stat(count: Site.appUserCount, noun: "user", isApproximate: true),
			content.yearsOfCraft.map { Stat(count: $0, noun: "year", verb: "of craft") },
		]
		.compactMap(\.self)
	}

	/**
	The totals of the open-source work of all the years: the contributions on GitHub since the first year of the career quilt, and the npm packages and their weekly downloads.
	*/
	private var allTimeOpenSourceStats: [Stat] {
		// The career quilt has every year, so their sum is all the contributions.
		let contributionCount = content.contributionYears.isEmpty ? nil : content.contributionYears.totalCount

		return [contributionCount.map { Stat(count: $0, noun: "contribution", verb: "on GitHub", isApproximate: true) }].compactMap(\.self) + npmStats
	}

	/**
	The npm packages and their weekly downloads, rounded down, like “1K+ npm packages” and “21B+ downloads a week”.
	*/
	private var npmStats: [Stat] {
		[
			content.npmStatistics.packageCount.map { Stat(count: $0, noun: "npm package", isApproximate: true) },
			content.npmStatistics.weeklyDownloads.map { Stat(count: $0, noun: "download", verb: "a week", isApproximate: true) },
		]
		.compactMap(\.self)
	}

	/**
	Something from an earlier year on the day of the build, like an app that launched on this day.
	*/
	struct Anniversary {
		let title: String
		let destination: LinkDestination
		let description: String
		let date: Date
	}

	/**
	The apps that launched, the app versions that were released, and the blog posts that were published on this day in earlier years (UTC), newest first, at most six.
	*/
	var onThisDay: [Anniversary] {
		let today = Calendar.site.dateComponents([.year, .month, .day], from: content.buildDate)

		func isAnniversary(_ date: Date) -> Bool {
			let components = Calendar.site.dateComponents([.year, .month, .day], from: date)

			guard
				let year = components.year,
				let currentYear = today.year
			else {
				return false
			}

			return components.month == today.month && components.day == today.day && year < currentYear
		}

		func year(_ date: Date) -> String {
			String(date.siteYear)
		}

		let apps = content.listedApps
			.filter { !$0.isRedirect && isAnniversary($0.publicationDate) }
			.map { Anniversary(title: $0.title, destination: $0.url, description: "launched in \(year($0.publicationDate))", date: $0.publicationDate) }

		let releases = content.activeApps.flatMap { app in
			app.releaseNotes.map { releaseNotes in
				content.releases(of: app)
					.filter { isAnniversary($0.publishedAt) }
					.map { Anniversary(title: "\(app.title) \($0.version)", destination: releaseNotes.destination(of: $0), description: "released in \(year($0.publishedAt))", date: $0.publishedAt) }
			} ?? []
		}

		let posts = content.listedPosts
			.filter { isAnniversary($0.publicationDate) }
			.map { Anniversary(title: $0.title, destination: $0.url, description: "posted in \(year($0.publicationDate))", date: $0.publicationDate) }

		return Array((apps + releases + posts).sorted(using: [KeyPathComparator(\.date, order: .reverse), KeyPathComparator(\.title, comparator: .localizedStandard)]).prefix(6))
	}

	/**
	The year of the build, like 2026.
	*/
	private var currentYear: Int {
		content.buildDate.siteYear
	}

	/**
	The new apps, app updates, and blog posts of the year of the build. Counts of zero are left out.
	*/
	private var yearStats: [Stat] {
		func isThisYear(_ date: Date) -> Bool {
			date.siteYear == currentYear
		}

		let appCount = content.listedApps.count { isThisYear($0.publicationDate) }
		// The App Store only has the date of the current version, so this counts the apps with an update this year, not the updates. The apps that launched this year are new apps, not updated ones.
		let updatedAppCount = content.activeApps.count { app in
			!isThisYear(app.publicationDate) && (content.appStoreInfo(of: app)?.currentVersionReleaseDate.map(isThisYear) ?? false)
		}
		let postCount = content.listedPosts.count { isThisYear($0.publicationDate) }
		// The npm search only has the date of the latest version, which is enough to know that a package was updated this year.
		let updatedPackageCount = content.npmStatistics.packages.count { isThisYear($0.date) }
		let year = content.contributionYears.last { $0.year == currentYear }
		let totals = year?.totals

		let stats: [Stat?] = [
			Stat(count: appCount, noun: "new app"),
			Stat(count: updatedAppCount, noun: "app", verb: "updated"),
			Stat(count: postCount, noun: "blog post"),
			year.map { Stat(count: $0.calendar.totalCount, noun: "contribution") },
			totals.map { Stat(count: $0.commitCount, noun: "commit") },
			totals.map { Stat(count: $0.pullRequestCount, noun: "pull request", verb: "opened") },
			totals.map { Stat(count: $0.issueCount, noun: "issue", verb: "opened") },
			totals.map { Stat(count: $0.reviewCount, noun: "code review") },
			totals.map { Stat(count: $0.repositoryCount, noun: "new repository", pluralNoun: "new repositories") },
			Stat(count: updatedPackageCount, noun: "npm package", verb: "updated"),
		]

		return stats.compactMap(\.self).filter { $0.count > 0 }
	}

	/**
	When the newest of the things on the page happened, or the hand-written part changed, so the date only changes when the page does.
	*/
	private var lastChange: Date? {
		let dates: [Date?] = [page.lastCommitDate, content.newestApp?.publicationDate, latestBlogPosts.first?.publicationDate, content.recentActivity.blueskyPost?.date]
		return (dates.compactMap(\.self) + appUpdates.map(\.date) + latestReleases.map(\.date) + content.recentRepositories.prefix(5).map(\.createdAt)).max()
	}

	/**
	The IDs and data attributes that the scripts of the page find elements by.
	*/
	enum Hooks: String, ScriptHookSet {
		case blueskyPost = "bluesky-post"
		case commitTemplate = "commit-template"
		case latestCommits = "latest-commits"
	}

	enum Styles: StyleSet {
		case updated
		case status
		case newestApp
		case icon
		case text
		case eyebrow
		case newestAppTitle
		case newestAppSubtitle
		case groups
		case group
		case wideGroup
		case groupTitle
		case card
		case rows
		case row
		case stackedRow
		case rowHeader
		case rowLabel
		case rowLink
		case rowDate
		case rowDescription
		case version
		case stats
		case colophon
		case colophonLink
		case stat
		case statValue
		case statLabel
		case caption
		case post
		case postSource
		case postFooter
		case postFooterLink
		case postText

		var style: Style {
			switch self {
			case .updated:
				// The dot is like a status light. It does not move.
				Style()
					.hstack(alignment: .center, isInline: true)
					.margin(0)
					.padding(vertical: .rootEm(0.25), horizontal: .rootEm(0.75))
					.cornerRadius(.capsule)
					.textStyle(.caption, weight: .medium)
					.monospacedDigit()
					.color(.secondaryText)
					.background(.card)
					.before {
						$0
							.content("")
							.frame(width: .rootEm(0.5), height: .rootEm(0.5))
							.margin(.trailing, .rootEm(0.5))
							.cornerRadius(.circle)
							.background(.emerald(700), dark: .emerald(400))
					}
			case .status:
				Style()
					.margin(top: .rootEm(1.5), horizontal: 0, bottom: .rootEm(2))
					.font(.extraLarge)
					.color(.primaryText)
			case .newestApp:
				// A link, but without the look of a link in prose, as the whole card is the link.
				Style()
					.hstack(alignment: .center, spacing: .rootEm(1.25))
					.margin(top: .rootEm(2), horizontal: 0, bottom: .rootEm(1))
					.padding(.rootEm(1.25))
					.cardSurface()
					.fontWeight(.regular)
					.color(.primaryText)
					.children(Icon.selector) {
						$0
							.flexShrink(0)
							.color(.secondaryText)
					}
			case .icon:
				// The icon images have their own shape and shadow, and transparent margins. The size is the size of the image.
				Style()
					.plainImage()
					.flexShrink(0)
			case .text:
				// The text next to an icon, like the title of the newest app.
				Style()
					.vstack(spacing: .rootEm(0.125))
					.flex(1)
					.frame(minWidth: 0)
			case .eyebrow:
				// The link color, not the color of the icon, as small text in the color of some icons is hard to read.
				Style()
					.textStyle(.caption, weight: .semibold)
					.color(.link)
			case .newestAppTitle:
				Style()
					.font(.extraLarge2, weight: .bold)
					.letterSpacing(.em(-0.02))
			case .newestAppSubtitle:
				Style()
					.secondaryText(.body)
			case .groups:
				// One column on phones, and two from tablets. A part that is alone spans both. Each part is as high as its content, so a short card has no empty space.
				Style()
					.display(.grid)
					.alignItems(.start)
					.gap(row: .rootEm(2.5), column: .rootEm(1.25))
					.from(.tablet) {
						$0
							.gridColumns(2)
							.children(":only-child") {
								$0.gridColumnSpan(2)
							}
					}
			case .group:
				Style()
					.vstack(spacing: .rootEm(0.75))
					.frame(minWidth: 0)
			case .wideGroup:
				Style()
					.from(.tablet) {
						$0.gridColumnSpan(2)
					}
			case .groupTitle:
				Style()
					.margin(0)
					.textStyle(.body, weight: .semibold)
					.letterSpacing(0)
					.color(.primaryText)
			case .card:
				Style()
					.margin(0)
					.padding(.rootEm(1.25))
					.cardSurface(isInteractive: false)
					.textStyle(.body)
					.trimmingChildMargins()
			// The rows have thin lines between them, like a grouped list.
			case .rows:
				Style()
					.vstack()
					.padding(vertical: .rootEm(0.25), horizontal: .rootEm(1.25))
			case .row:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.75))
					.margin(0)
					.padding(vertical: .rootEm(0.875), horizontal: 0)
					.border(.bottom, .separator)
					.lastChild {
						$0.border(.bottom, width: 0)
					}
			// The children are not wider than the row, so a long word, like a URL in a commit message, breaks instead of overflowing.
			case .stackedRow:
				Style()
					.flexDirection(.column)
					.alignItems(.start)
					.gap(.rootEm(0.25))
					.children("*") {
						$0.frame(maxWidth: .percent(100))
					}
			case .rowHeader:
				Style()
					.hstack(alignment: .baseline, justification: .spaceBetween, spacing: .rootEm(0.75))
					.frame(width: .percent(100))
			case .rowLabel:
				Style()
					.textStyle(.caption, weight: .medium)
					.color(.secondaryText)
			case .rowLink:
				Style()
					.flex(1)
					.frame(minWidth: 0)
			case .rowDate:
				Style()
					.flexShrink(0)
					.secondaryText()
					.monospacedDigit()
					.textWrap(.nowrap)
			case .rowDescription:
				Style()
					.secondaryText()
			case .version:
				// After the link, so the underline of the link does not go under it.
				Style()
					.display(.inlineBlock)
					.padding(vertical: 0, horizontal: .rootEm(0.375))
					.cornerRadius(.rootEm(0.375))
					.fontFamily(.monospace)
					.font(size: .rootEm(0.75), lineHeight: 1.6)
					.fontWeight(.medium)
					.color(.bodyText)
					.background(.card)
			case .colophon:
				Style()
					.margin(top: .rootEm(4), horizontal: 0, bottom: 0)
					.padding(.top, .rootEm(1.5))
					.border(.top, .separator)
					.textAlign(.center)
					.secondaryText()
			case .colophonLink:
				Style()
					.color(.inherit)
					.fontWeight(.regular)
					.underlineColor(.separator)
					.hover {
						$0.underlineColor(.inherit)
					}
			case .stats:
				// Two columns on phones, and three from tablets, so the numbers of all the cards line up. Three numbers are in three columns on phones too, a little smaller, as the numbers are short, so none is alone in a row.
				Style()
					.display(.grid)
					.gridColumns(2)
					.gap(row: .rootEm(1.25), column: .rootEm(1))
					.below(.tablet) {
						$0.nested("&:has(> :nth-child(3):last-child)") {
							$0
								.gridColumns(3)
								.nested(Self.statValue.selector) {
									$0.font(size: .rootEm(1.875))
								}
						}
					}
					.from(.tablet) {
						$0.gridColumns(3)
					}
			case .stat:
				Style()
					.vstack(spacing: .rootEm(0.25))
					.flex(1)
					.frame(minWidth: .rootEm(4))
					.margin(0)
					.padding(0)
			case .statValue:
				Style()
					.fontFamily(.rounded)
					.font(size: .rootEm(2.25), lineHeight: 1.1)
					// On one line, so the “+” of a rounded number stays with it.
					.textWrap(.nowrap)
					.bold()
					.letterSpacing(.em(-0.02))
					.monospacedDigit()
					.color(.primaryText)
			case .statLabel:
				Style()
					.secondaryText()
			case .caption:
				Style()
					.margin(0)
					.secondaryText()
			case .post:
				Style()
					.vstack(spacing: .rootEm(0.75))
			case .postSource:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.5))
					.textStyle(.caption, weight: .semibold)
					.color(.primaryText)
					.children(Icon.selector) {
						$0.color(.link)
					}
			// A quiet footer of the card, below a thin line, like the details of a post in a social app.
			case .postFooter:
				// More space above the line than the gap between the other parts of the card.
				Style()
					.margin(top: .rootEm(0.5), horizontal: 0, bottom: 0)
					.padding(.top, .rootEm(0.75))
					.border(.top, .separator)
					.secondaryText(.extraSmall)
			case .postFooterLink:
				Style()
					.color(.inherit)
					.fontWeight(.regular)
					.underline(false)
					.transition(.color, animation: .stateChange)
					.hover {
						$0
							.color(.primaryText)
							.underline()
					}
			case .postText:
				// The paragraphs of the post are lines in its text.
				Style()
					.margin(0)
					.preservesLineBreaks()
			}
		}
	}
}
