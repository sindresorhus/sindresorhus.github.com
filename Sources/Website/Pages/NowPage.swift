import Elementary
import Foundation
import SiteKit
import SOML

/**
What Sindre is working on now, like the pages on https://nownownow.com: the hand-written status, focus, reading, and listening of `content/pages/now.md`, and what the build gets, so the rest never goes stale: the newest app, app updates, two reviews, GitHub and npm activity, and the latest posts.

Each part that the build could not get is left out. The latest commits are only loaded in the browser (`now.js`), which also shows a newer Bluesky post than the one of the build. Whether Sindre is probably awake (``AwakeStatus``) and the npm downloads while the visitor has been on the page (``RunningCount``) are also only in the browser.
*/
struct NowPage: Page {
	let page: MarkdownPage
	let content: SiteContent

	var path: RoutePath {
		page.path
	}

	var metadata: PageMetadata {
		page.metadata
	}

	var sitemapEntry: SitemapEntry {
		SitemapEntry(lastModified: lastChange)
	}

	var body: some HTML {
		ProsePage(title: .plain(page.title)) {
			// The chips are in a row, which wraps on small screens.
			div {
				if let lastChange {
					// The text is in a span, so the stack keeps the space after “Updated”.
					p {
						span {
							"Updated "
							DateText(day: lastChange, format: .siteDay)
						}
					}
					.style(Styles.updated)
				}

				AwakeStatus()
			}
			.style {
				$0
					.hstack(spacing: .rootEm(0.5))
					.flexWrap()
			}

			if let status = page.status {
				p {
					status.inlineContent
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

		ModuleScript(#path("/scripts/now.js"))
	}

	/**
	The newest app as a card that links to it. The light of the card is in the color of the icon.
	*/
	private func newestApp(_ app: App) -> some HTML {
		a(.href(app.url)) {
			AppIcon(decorative: app, size: 64, isAboveFold: true)

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
	The contributions of each week of the last year as a sparkline, so this week can be seen next to the others.
	*/
	@ContentBuilder
	private func weeklyContributions(_ counts: [Int]) -> some HTML {
		if let sparkline = Sparkline(values: counts, label: "Lowest week: \(counts.min() ?? 0). Highest week: \(counts.max() ?? 0). Last 7 days: \(counts.last ?? 0).") {
			figure {
				// The caption says what the chart is, and the label what it shows.
				sparkline

				figcaption {
					"Contributions a week in the last year"
				}
				.style(Styles.caption)
			}
			.vstack(spacing: .rootEm(0.75))
			.style(Styles.card)
		}
	}

	/**
	The widths of the repo and the message of each placeholder commit, in `em` of the root. They are different, like real commits. There are five, as `now.js` shows at most five commits (`.slice(0, 5)`).
	*/
	private static let placeholderCommitWidths: [(repository: Double, message: Double)] = [(5.5, 24), (4, 17), (7, 21), (5, 12), (6, 19)]

	/**
	A row that holds the place of a commit while the commits load. Each line is in a span with the text style of the commit, so the row is as high as a commit.
	*/
	private func placeholderCommit(repositoryWidth: Double, messageWidth: Double) -> some HTML {
		li {
			span {
				span {
					placeholder(width: repositoryWidth)
				}
				.style(Styles.rowLabel)

				span {
					placeholder(width: 5)
				}
				.style(Styles.rowDate)
			}
			.style(Styles.rowHeader)

			span {
				placeholder(width: messageWidth)
			}
		}
		.accessibilityHidden()
		.style(Styles.row, Styles.stackedRow, Styles.placeholderRow)
	}

	/**
	A gray line in the place of a text that is still loading. The width is in `em` of the root, not a percentage, as the parent is only as wide as its content, so a percentage would be zero.
	*/
	private func placeholder(width: Double) -> some HTML {
		span {}
			.style(Styles.placeholder)
			.style {
				$0.frame(width: .rootEm(width))
			}
	}

	/**
	A part of a section: a small title above a card, or above other content. The parts of a section are in two columns on larger screens, and a wide part spans both.
	*/
	private func group(_ title: String, isWide: Bool = false, @HTMLBuilder content: () -> some HTML) -> some HTML {
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
	A section of parts (``group(_:isWide:content:)``), in two columns on larger screens.
	*/
	private func groupedSection(_ title: String, id: ElementID, @HTMLBuilder content: () -> some HTML) -> some HTML<HTMLTag.section> {
		Section(title, id: id) {
			div {
				content()
			}
			.style(Styles.groups)
		}
	}

	/**
	Links in a card, one in each row, with thin lines between them, like the new projects.
	*/
	private func rows(_ links: [LabeledLink]) -> some HTML {
		ul {
			for link in links {
				li {
					a(.href(link.destination)) {
						link.title
					}

					if let description = link.description {
						span {
							description
						}
						.style(Styles.caption)
					}
				}
				.style(Styles.row, Styles.stackedRow)
			}
		}
		.style(Styles.card, Styles.rows)
	}

	/**
	The latest commits, the npm downloads while the visitor has been on the page, the numbers of the week, and the contributions. The latest commits are only loaded in the browser, so without the other parts, the section is hidden until they load.
	*/
	private var buildingNow: some HTML {
		let contributions = content.recentActivity.profile?.contributions
		let weekStats = weekStats
		// From the average of the last week, so it is not live downloads.
		let downloadStat = content.npmStatistics.downloadsPerSecond.map { Stat(perSecond: $0, label: "downloads of my packages while you have been here") }

		return groupedSection("Building Now", id: ElementID("building-now")) {
			// `now.js` fills in the commits, or shows a link to GitHub when it cannot get them. Without scripts, there are no commits to show.
			div(.id(IDs.latestCommits)) {
				h3 {
					"Right Now on GitHub"
				}
				.style(Styles.groupTitle)

				// While the commits load, gray lines take the place of five of them, so the page does not move when they come in. Screen readers know that the list is loading, so they do not read the empty rows.
				ul(.ariaBusy()) {
					ForEach(Self.placeholderCommitWidths) { widths in
						placeholderCommit(repositoryWidth: widths.repository, messageWidth: widths.message)
					}
				}
				.style(Styles.card, Styles.rows)

				// `now.js` shows it instead of the commits when GitHub does not send them, like when the visitor has made too many searches. Without a token, GitHub allows 10 searches a minute.
				p(.id(IDs.latestCommitsError), .hidden) {
					"GitHub did not send the latest commits right now. "
					a(.href(.url(Site.author.gitHubURL))) {
						"See them on GitHub"
					}
					"."
				}
				.style(Styles.card)

				// `now.js` fills in the repo, the message, and when it was committed.
				template(.id(IDs.commitTemplate)) {
					li {
						span {
							span(.hook(Hooks.commitRepository)) {}
								.style(Styles.rowLabel)

							// Not a `time`, as an empty `time` without a `datetime` is invalid HTML, and the template has no date for it.
							span(.hook(Hooks.commitTime)) {}
								.style(Styles.rowDate)
						}
						.style(Styles.rowHeader)

						a(.hook(Hooks.commitLink), .href(.url(Site.author.gitHubURL))) {}
							.style(Styles.commitLink)
					}
					.style(Styles.row, Styles.stackedRow)
				}
			}
			.style(Styles.group, Styles.wideGroup)
			.style {
				$0.hiddenWithoutScripting()
			}

			if let downloadStat {
				group("Right Now on npm", isWide: true) {
					StatCard(stats: [downloadStat])
				}
			}

			if !weekStats.isEmpty {
				group("This Week in Open Source", isWide: true) {
					StatCard(stats: weekStats)

					if let counts = contributions?.weeklyCounts {
						weeklyContributions(counts)
					}
				}
			}

			if let contributions {
				group("Contributions", isWide: true) {
					div {
						ContributionHeatmap(calendar: contributions, scale: content.contributionScale)
							.style {
								$0.margin(vertical: .rootEm(1.5), horizontal: .zero)
							}

						p {
							"\(contributions.totalCount.formatted(counting: "contribution")) on GitHub in the last year, and a streak of \(contributions.currentStreak.formatted(counting: "day"))."

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
		.attributes(.hidden, when: contributions == nil && downloadStat == nil && weekStats.isEmpty)
	}

	@HTMLBuilder
	private var apps: some HTML {
		let updates = appUpdates
		// The newest five-star reviews of all the apps.
		let reviews = recentReviews
		let updateDateFormat = dayFormat(for: updates.map(\.date))

		if !updates.isEmpty || !reviews.isEmpty {
			groupedSection("Apps", id: ElementID("apps")) {
				if !updates.isEmpty {
					group("Latest Updates") {
						ul {
							for update in updates {
								li {
									AppIcon(decorative: update.app, size: 32)

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

										DateText(day: SOML.Date(update.date), format: updateDateFormat)
											.style(Styles.caption)
									}
									.style(Styles.text)
								}
								.style(Styles.row)
							}
						}
						.style(Styles.card, Styles.rows)
					}
				}

				if !reviews.isEmpty {
					group("A Recent Review") {
						for review in reviews {
							QuoteFigure(kind: .review(review.review), app: review.app)
						}

						// A caption, as the reviews are the point.
						p {
							// The stars of the reviews are decorative, as they are all five stars.
							VisuallyHidden("All with five stars. ")
							"More on the "
							a(.href(.path(.reviews))) {
								"Wall of Love"
							}
						}
						.style(Styles.caption)
					}
				}
			}
		}
	}

	@HTMLBuilder
	private var openSource: some HTML {
		let repositories = newProjects
		let releases = latestReleases
		let releaseDateFormat = dayFormat(for: releases.map(\.date))
		if !repositories.isEmpty || !releases.isEmpty {
			groupedSection("Open Source", id: ElementID("open-source")) {
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

									DateText(day: SOML.Date(release.date), format: releaseDateFormat)
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
						rows(repositories.map { LabeledLink($0.displayName, destination: .url($0.url), description: $0.summary) })
					}
				}
			}
		}
	}

	@HTMLBuilder
	private var latestPosts: some HTML {
		let blueskyPost = content.recentActivity.blueskyPost
		let blogPost = latestBlogPost

		if blueskyPost != nil || blogPost != nil {
			groupedSection("Latest Posts", id: ElementID("posts")) {
				if let blueskyPost {
					group("On Social Media") {
						div {
							span {
								Icon.bluesky.size(.rootEm(1.125))
								"Bluesky"
							}
							.style(Styles.postSource)

							// `now.js` replaces the text, the link, and the date with a newer post.
							blockquote(.id(IDs.blueskyPost)) {
								p(.id(IDs.blueskyPostText)) {
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

							// The date links to the post. `now.js` changes the link and the date for a newer post. The other services are on a line of their own, as the card is too narrow for both on one line.
							p {
								a(.id(IDs.blueskyPostLink), .href(.url(blueskyPost.url))) {
									// With the year, like the date that `now.js` writes for a newer post. The `datetime` has the time, so `now.js` only shows a post that is newer.
									time(.id(IDs.blueskyPostTime), .dateTime(blueskyPost.date)) {
										blueskyPost.date.formatted(.siteDay)
									}
								}
								.style(Styles.postFooterLink)

								br()

								"Also on "

								for (index, link) in socialLinks.enumerated() {
									Self.listSeparator(before: index, count: socialLinks.count)

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

				if let blogPost {
					group("On the Blog") {
						rows([LabeledLink(blogPost.title, destination: blogPost.url, description: blogPost.description)])
					}
				}
			}
		}
	}

	/**
	On this day in earlier years, the year so far, the sponsors, a link to the numbers of all the years, and where the idea of a now page is from.
	*/
	private var footerRow: some HTML {
		let anniversaries = onThisDay

		return footer {
			if !anniversaries.isEmpty {
				Section("On This Day", id: ElementID("on-this-day")) {
					rows(anniversaries.map { LabeledLink($0.title, destination: $0.destination, description: $0.description) })
				}
			}

			yearSection

			// Apart from the cards above, as they are not about the year. The link to the numbers of all the years is last, as it leads on from the page. Both are captions, as they are notes of the same kind.
			div {
				if let sponsorCount = content.recentActivity.profile?.sponsorCount {
					p {
						"\(sponsorCount.formatted(.number.locale(.site))) people and companies "
						a(.href(.path(.supporters))) {
							"sponsor my open-source work"
						}
						"."
					}
					.style(Styles.caption)
				}

				p {
					"All-time numbers are on the "
					a(.href(.path(.about, fragment: AboutPage.numbersID.rawValue))) {
						"About"
					}
					" page."
				}
				.style(Styles.caption)
			}
			.vstack(spacing: .rootEm(0.5))
			.style {
				$0.margin(.top, .rootEm(1.5))
			}

			// A quiet note at the end of the page, like a colophon.
			p {
				"This is a "
				a(.href(.url(#URL("https://nownownow.com/about")))) {
					"now page"
				}
				", like on many other personal sites."
			}
			.style(Styles.colophon)
		}
	}

	/**
	The numbers of the year so far. The apps, the open-source work, and npm are apart, so it is clear what each number is about, like the busiest day.
	*/
	@HTMLBuilder
	private var yearSection: some HTML {
		let appStats = yearAppStats
		let openSourceStats = yearOpenSourceStats
		let npmStats = yearNPMStats

		if !appStats.isEmpty || !openSourceStats.isEmpty || !npmStats.isEmpty {
			groupedSection("\(currentYear) So Far", id: ElementID("year")) {
				if !appStats.isEmpty {
					group("Apps and Blog", isWide: true) {
						StatCard(stats: appStats)
					}
				}

				if !openSourceStats.isEmpty {
					group("Open Source", isWide: true) {
						StatCard(stats: openSourceStats)
						repositoryCommitsCaption
					}
				}

				if !npmStats.isEmpty {
					group("npm", isWide: true) {
						StatCard(stats: npmStats)
					}
				}
			}
		}
	}

	/**
	The repos with the most commits of the year, like “Most commits went to ky (1,163), chalk/chalk (2), and got (1).”
	*/
	@HTMLBuilder
	private var repositoryCommitsCaption: some HTML {
		let repositoryCommits = repositoryCommits

		if !repositoryCommits.isEmpty {
			p {
				"Most commits went to "

				for (index, commits) in repositoryCommits.enumerated() {
					Self.listSeparator(before: index, count: repositoryCommits.count)

					a(.href(.url(commits.url))) {
						commits.repository.displayName
					}

					" (\(commits.count.formatted(.number.locale(.site))))"
				}

				"."
			}
			.style(Styles.caption)
		}
	}

	/**
	The text before an item of a list in a sentence, like “, and ” before the last of three items, with the comma of the lists of the site (``Foundation/Locale/site``), or nothing before the first item.
	*/
	private static func listSeparator(before index: Int, count: Int) -> String {
		switch index {
		case 0:
			""
		case count - 1:
			count > 2 ? ", and " : " and "
		default:
			", "
		}
	}

	/**
	The other places where the posts are, as the card already says Bluesky.
	*/
	private var socialLinks: [Person.SocialLink] {
		Site.author.socialLinks.filter { [.x, .mastodon].contains($0.icon) }
	}

	/**
	The newest blog post. Posts that only send visitors to another page, like an app page, are left out.
	*/
	private var latestBlogPost: BlogPost? {
		content.listedPosts.first { !$0.isRedirect }
	}

	/**
	The five newest repos.
	*/
	private var newProjects: ArraySlice<GitHubRepository> {
		content.recentRepositories.prefix(5)
	}

	/**
	The newest five-star review of the apps. Only one, so the column of the reviews ends with the column of the updates next to it.
	*/
	private var recentReviews: [SiteContent.AppReview] {
		Array(content.activeAppReviews.prefix(1))
	}

	/**
	The five apps that were updated last, each with its latest version: the newer of the App Store version and the latest release of its releases repo. A version from the day of the launch or before is the launch, and like in the numbers of the year, a launch is not an update.
	*/
	private var appUpdates: [AppListing.VersionRelease] {
		let updates = content.activeApps.compactMap { app in
			content.listing(of: app).versionReleases
				.filter { SOML.Date($0.date) > app.publicationDate }
				.sorted(using: KeyPathComparator(\.date, order: .reverse))
				.first
		}

		return Array(updates.sorted(using: KeyPathComparator(\.date, order: .reverse)).prefix(5))
	}

	private struct Release {
		/**
		The paired project and version identity, without a private delimiter encoding.
		*/
		struct Identity: Hashable {
			let name: String
			let version: String
		}

		var identity: Identity {
			Identity(name: name, version: version)
		}

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
			.filter(\.repository.isOwners)
			.map { release in
				Release(
					name: release.repository.name,
					displayName: release.repository.displayName,
					version: release.version,
					url: release.url,
					date: release.date
				)
			}

		// A package version that has a GitHub release is shown as the release, which has the release notes. A newer version without a release is shown as the package.
		let gitHubVersions = Set(gitHubReleases.map(\.identity))

		// Only the packages of repositories that the same owners have, as the npm search also finds packages that he only helps maintain, like `yeoman-generator`.
		let npmReleases = (content.npmStatistics.packages ?? [])
			.filter { $0.repository?.isOwners ?? false }
			.map { Release(
				name: $0.unscopedName,
				displayName: $0.name,
				version: $0.version,
				url: $0.url,
				date: $0.date
			) }
			.filter { !gitHubVersions.contains($0.identity) }

		return Array(
			(gitHubReleases + npmReleases)
				.sorted(using: [KeyPathComparator(\.date, order: .reverse), KeyPathComparator(\.displayName, comparator: .localizedStandard)])
				.uniqued(by: \.name)
				.prefix(5)
		)
	}

	/**
	The format of the dates of a list: without the year when they are all in the year of the build, which is shorter and easier to read.
	*/
	private func dayFormat(for dates: [Date]) -> Date.FormatStyle {
		dates.allSatisfy(isThisYear) ? .siteDayWithoutYear : .siteDay
	}

	/**
	The contributions, the commits, the issues closed, the pull requests merged from others, the comments, and the npm packages updated in the week (``RecentActivity/weekStart(before:)``), with the same labels as the numbers of the year.
	*/
	private var weekStats: [Stat] {
		let activity = content.recentActivity
		let week = activity.weekActivity
		let updatedPackageCount = content.npmStatistics.updatedPackageCount(since: RecentActivity.weekStart(before: content.buildDate))

		let stats: [Stat?] = [
			week.map { Stat(count: $0.contributionCount, noun: "contribution") },
			week.map { Stat(count: $0.commitCount, noun: "commit") },
			activity.weekMaintenance.map { Stat(count: $0.closedIssueCount, noun: "issue", suffix: "closed") },
			activity.weekMaintenance.map { Stat(count: $0.mergedPullRequestCount, noun: "pull request", suffix: "merged from others") },
			week.map { Stat(count: $0.commentCount, noun: "comment") },
			updatedPackageCount.map { Stat(count: $0, noun: "npm package", suffix: "updated") },
		]

		return stats.compactMap(\.self)
	}

	/**
	Something from an earlier year on the day of the build, like an app that launched on this day.
	*/
	private struct Anniversary {
		let title: String
		let destination: LinkDestination
		let description: String

		/**
		The year for ordering, like 2019.
		*/
		let year: Int
	}

	/**
	The apps that launched and the blog posts that were published on this day in earlier years (UTC), newest first. App updates are left out, as they are many and not of interest years later.
	*/
	private var onThisDay: [Anniversary] {
		let today = SOML.Date(content.buildDate)

		func isAnniversary(_ date: SOML.Date) -> Bool {
			date.year < today.year && date.month == today.month && date.day == today.day
		}

		func yearsAgo(_ date: SOML.Date) -> String {
			"\((today.year - date.year).formatted(counting: "year")) ago"
		}

		let apps = content.listedApps
			.filter { !$0.isRedirect && isAnniversary($0.publicationDate) }
			.map { Anniversary(
				title: $0.title,
				destination: $0.url,
				description: "launched \(yearsAgo($0.publicationDate))",
				year: $0.publicationDate.year
			) }

		let posts = content.listedPosts
			.filter { isAnniversary($0.publicationDate) }
			.map { Anniversary(
				title: $0.title,
				destination: $0.url,
				description: "posted \(yearsAgo($0.publicationDate))",
				year: $0.publicationDate.year
			) }

		return (apps + posts).sorted(using: [KeyPathComparator(\.year, order: .reverse), KeyPathComparator(\.title, comparator: .localizedStandard)])
	}

	/**
	The year of the build, like 2026.
	*/
	private var currentYear: Int {
		content.buildDate.siteYear
	}

	/**
	The GitHub contributions of the year of the build. It needs a GitHub token.
	*/
	private var contributionYear: ContributionYear? {
		content.contributionYears.last { $0.year == currentYear }
	}

	/**
	The three public repositories with the most commits in the year of the build, like eslint-plugin-unicorn with 933.
	*/
	private var repositoryCommits: [ContributionYear.RepositoryCommits] {
		let commits = contributionYear?.totals.repositoryCommits ?? []
		return Array(commits.filter { !$0.isPrivate }.prefix(3))
	}

	/**
	Whether the date is in the year of the build.
	*/
	private func isThisYear(_ date: Date) -> Bool {
		date.siteYear == currentYear
	}

	/**
	The new apps, app updates, and blog posts of the year of the build. Counts of zero are left out.
	*/
	private var yearAppStats: [Stat] {
		let appCount = content.listedApps.count { $0.publicationDate.year == currentYear }
		// The App Store only has the date of the current version, so this counts the apps with an update this year, not the updates. The apps that launched this year are new apps, not updated ones.
		let updatedAppCount = content.activeApps.count { app in
			app.publicationDate.year != currentYear && (content.listing(of: app).appStoreVersionDate.map(isThisYear) ?? false)
		}
		let postCount = content.listedPosts.count { $0.publicationDate.year == currentYear }

		return [
			Stat(count: appCount, noun: "new app"),
			Stat(count: updatedAppCount, noun: "app", suffix: "updated"),
			Stat(count: postCount, noun: "blog post"),
		]
		.filter(\.hasValue)
	}

	/**
	The open-source work of the year of the build on GitHub: the contributions, like the commits, the busiest day, and the new repos, and the issues closed and the pull requests merged from others. Counts of zero are left out.
	*/
	private var yearOpenSourceStats: [Stat] {
		let year = contributionYear
		let totals = year?.totals
		let maintenance = content.recentActivity.yearMaintenance

		// Ten numbers when all have data, so from tablets, the last row has one number. The issues that Sindre opened are left out, as they say the least.
		let stats: [Stat?] = [
			year.map { Stat(count: $0.calendar.totalCount, noun: "contribution") },
			year.map { Stat(count: $0.activeDayCount, noun: "day", suffix: "with contributions") },
			// Short enough for one line, also with the longest month.
			year?.busiestDay.map { Stat(busiestDay: $0, format: .siteDayWithoutYear) },
			totals.map { Stat(count: $0.commitCount, noun: "commit") },
			totals.map { Stat(
				count: $0.committedRepositoryCount,
				noun: "repository",
				pluralNoun: "repositories",
				suffix: "committed to"
			) },
			totals.map { Stat(count: $0.pullRequestCount, noun: "pull request", suffix: "opened") },
			totals.map { Stat(count: $0.reviewCount, noun: "code review") },
			totals.map { Stat(count: $0.repositoryCount, noun: "new repository", pluralNoun: "new repositories") },
			maintenance.map { Stat(count: $0.closedIssueCount, noun: "issue", suffix: "closed") },
			maintenance.map { Stat(count: $0.mergedPullRequestCount, noun: "pull request", suffix: "merged from others") },
		]

		return stats.compactMap(\.self).filter(\.hasValue)
	}

	/**
	The new npm packages and the npm packages updated in the year of the build. A new package counts as updated too. Counts of zero are left out.
	*/
	private var yearNPMStats: [Stat] {
		let npm = content.npmStatistics
		// The npm search has no date of the first version, so a new package is one in a repo of the account or of the organizations of its projects (``GitHub/owners``) that was made this year.
		let newRepositories = content.gitHubAccount.map { $0.repositories.filter { isThisYear($0.createdAt) }.map(\.nameWithOwner) }

		let stats: [Stat?] = [
			newRepositories.flatMap(npm.packageCount(inRepositories:)).map { Stat(count: $0, noun: "new package") },
			npm.updatedPackageCount(since: Date(year: currentYear, month: 1, day: 1)).map { Stat(count: $0, noun: "package", suffix: "updated") },
		]

		return stats.compactMap(\.self).filter(\.hasValue)
	}

	/**
	When the newest of the things on the page happened, or the hand-written part changed, so the date only changes when the page does.
	*/
	private var lastChange: SOML.Date? {
		let publicationDates = [content.newestApp?.publicationDate, latestBlogPost?.publicationDate].compactMap(\.self)
		let dates = [page.lastCommitDate, content.recentActivity.blueskyPost?.date].compactMap(\.self) + appUpdates.map(\.date) + recentReviews.map(\.review.date) + latestReleases.map(\.date) + newProjects.map(\.createdAt)
		return (publicationDates + dates.map(SOML.Date.init)).max()
	}

	/**
	The IDs that the scripts of the page find elements by.
	*/
	enum IDs: String, ScriptIDSet {
		case blueskyPost = "bluesky-post"
		case blueskyPostText = "bluesky-post-text"
		case blueskyPostLink = "bluesky-post-link"
		case blueskyPostTime = "bluesky-post-time"
		case commitTemplate = "commit-template"
		case latestCommits = "latest-commits"
		case latestCommitsError = "latest-commits-error"
	}

	/**
	The data attributes that the scripts of the page find elements by.
	*/
	enum Hooks: String, ScriptDataAttributeSet {
		/**
		The repo of a commit in its template, which `now.js` fills in.
		*/
		case commitRepository = "commit-repository"

		/**
		The link to a commit in its template, with its message.
		*/
		case commitLink = "commit-link"

		/**
		When a commit was made, in its template.
		*/
		case commitTime = "commit-time"
	}

	enum Styles: StyleSet {
		case updated
		case status
		case newestApp
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
		case commitLink
		case rowDate
		case placeholderRow
		case placeholder
		case version
		case colophon
		case caption
		case post
		case postSource
		case postFooter
		case postFooterLink
		case postText

		var style: Style {
			switch self {
			case .updated:
				Style()
					.statusChip()
					.statusLight()
			case .status:
				Style()
					.margin(top: .rootEm(1.5), horizontal: .zero, bottom: .rootEm(2))
					.font(.extraLarge)
					.color(.primaryText)
			case .newestApp:
				Style()
					.linkCard()
					.margin(top: .rootEm(2), horizontal: .zero, bottom: .rootEm(1))
			case .text:
				// The text next to an icon, like the title of the newest app.
				Style()
					.vstack(spacing: .rootEm(0.125))
					.flex(1)
					.frame(minWidth: .zero)
			case .eyebrow:
				Style().eyebrow()
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
					.frame(minWidth: .zero)
			case .wideGroup:
				Style()
					.from(.tablet) {
						$0.gridColumnSpan(2)
					}
			case .groupTitle:
				Style()
					.margin(.zero)
					.textStyle(.body, weight: .semibold)
					.letterSpacing(.zero)
					.color(.primaryText)
			case .card:
				Style()
					.margin(.zero)
					.padding(.cardPadding)
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
					.margin(.zero)
					.padding(vertical: .rootEm(0.875), horizontal: .zero)
					.border(.bottom, .separator)
					.lastChild {
						$0.border(.bottom, width: .zero)
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
					.frame(minWidth: .zero)
			case .commitLink:
				// Each row is one link, so the message does not need the underline of a link in text, which would make the card a stack of underlines. It has the weight of a title, and the color of links under the pointer.
				Style()
					.underline(false)
					.fontWeight(.semibold)
					.color(.primaryText)
					.hoverColor(.link)
					// The code of the message is lighter and smaller than the message, as a monospaced font in semibold is much heavier than the text around it.
					.descendants("code") {
						$0
							.font(size: .em(0.875))
							.fontWeight(.medium)
					}
			case .rowDate:
				Style()
					.flexShrink(0)
					.secondaryText()
					.monospacedDigit()
					.textWrap(.nowrap)
			// A row that holds the place of a commit while the commits load. On phones, it is as high as a commit with a message on two lines, as most messages wrap there.
			case .placeholderRow:
				Style()
					.below(.tablet) {
						$0.frame(minHeight: .rootEm(5.875))
					}
			// A gray line that holds the place of a text while it loads, like `redacted(reason: .placeholder)` in SwiftUI. It is inline, in a line of the text, so the line is as high as the text. It does not pulse, as it only shows for a moment.
			case .placeholder:
				Style()
					.display(.inlineBlock)
					.frame(height: .em(0.75), maxWidth: .percent(100))
					.cornerRadius(.capsule)
					.verticalAlign(.middle)
					.background(.secondaryText.opacity(0.2))
			case .version:
				// After the link, so the underline of the link does not go under it.
				Style()
					.display(.inlineBlock)
					.padding(vertical: .zero, horizontal: .rootEm(0.375))
					.cornerRadius(.rootEm(0.375))
					.fontFamily(.monospace)
					.font(size: .rootEm(0.75), lineHeight: 1.6)
					.fontWeight(.medium)
					.color(.bodyText)
					.background(.card)
			case .colophon:
				Style()
					.margin(top: .rootEm(5), horizontal: .zero, bottom: .zero)
					.padding(.top, .rootEm(1.5))
					.border(.top, .separator)
					.textAlign(.center)
					.secondaryText()
			// Less important text, like the description of a row.
			case .caption:
				Style()
					.margin(.zero)
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
					.margin(top: .rootEm(0.5), horizontal: .zero, bottom: .zero)
					.padding(.top, .rootEm(0.75))
					.border(.top, .separator)
					.secondaryText(.extraSmall)
			case .postFooterLink:
				// Without the look of a link in prose.
				Style()
					.inherits(.color)
					.fontWeight(.regular)
					.quietLink()
			case .postText:
				// The paragraphs of the post are lines in its text.
				Style()
					.margin(.zero)
					.preservesLineBreaks()
			}
		}
	}
}
