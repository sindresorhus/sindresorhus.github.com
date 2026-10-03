import Foundation
import SiteKit

/**
Everything the pages are rendered from: the content and the data fetched from the App Store and GitHub.

It is loaded once, before any page renders, so rendering is synchronous and cannot fail because of the network.
*/
public struct SiteContent: Sendable {
	/**
	All apps, including unlisted and archived ones, newest first.
	*/
	public let apps: [App]

	/**
	All blog posts, including unlisted ones, newest first.
	*/
	public let posts: [BlogPost]

	public let pages: [MarkdownPage]
	private let pagesByPath: [RoutePath: MarkdownPage]

	/**
	More app pages, like the categories, from `content/apps-extra.json`.
	*/
	public let appExtras: [LinkGroup]
	public let appStoreInfo: [Int: AppStoreInfo]

	/**
	Recent five-star reviews by App Store ID.
	*/
	public let appStoreReviews: [Int: [AppStoreReview]]

	/**
	The releases of each app's releases repo.
	*/
	public let releases: [String: [GitHubRelease]]

	public let recentRepositories: [GitHubRepository]

	/**
	When the site is built. Everything that depends on the date uses it, like the “new” badge and the daily related apps, so one build is consistent.
	*/
	public let buildDate: Date

	init(apps: [App], posts: [BlogPost], pages: [MarkdownPage], appExtras: [LinkGroup], appStoreInfo: [Int: AppStoreInfo], appStoreReviews: [Int: [AppStoreReview]] = [:], releases: [String: [GitHubRelease]], recentRepositories: [GitHubRepository], buildDate: Date) {
		self.apps = apps
		self.posts = posts
		self.pages = pages
		self.pagesByPath = Dictionary(uniqueKeysWithValues: pages.map { ($0.path, $0) })
		self.appExtras = appExtras
		self.appStoreInfo = appStoreInfo
		self.appStoreReviews = appStoreReviews
		self.releases = releases
		self.recentRepositories = recentRepositories
		self.buildDate = buildDate
	}

	/**
	- Parameter cache: Where the App Store and GitHub responses are cached.
	*/
	public static func load(from project: Project, cache: ResponseCache, buildDate: Date = .now) async throws -> Self {
		// The mistakes of all content types are reported together.
		async let apps = App.load(from: project)
		async let posts = BlogPost.load(from: project)
		async let pages = MarkdownPage.load(from: project)
		let contentDirectory = project.root.appending(path: "content")
		var errors = [ContentError]()
		var loadedApps: [App]?
		var loadedPosts: [BlogPost]?
		var loadedPages: [MarkdownPage]?

		do {
			loadedApps = try await apps
		} catch {
			errors += ContentErrors(converting: error, file: contentDirectory).errors
		}

		do {
			loadedPosts = try await posts
		} catch {
			errors += ContentErrors(converting: error, file: contentDirectory).errors
		}

		do {
			loadedPages = try await pages
		} catch {
			errors += ContentErrors(converting: error, file: contentDirectory).errors
		}

		guard
			let loadedApps,
			let loadedPosts,
			let loadedPages
		else {
			throw ContentErrors(errors)
		}

		return try await load(apps: loadedApps, posts: loadedPosts, pages: loadedPages, project: project, cache: cache, buildDate: buildDate)
	}

	private static func load(apps: [App], posts: [BlogPost], pages: [MarkdownPage], project: Project, cache: ResponseCache, buildDate: Date) async throws -> Self {
		let github = GitHub(cache: cache)
		let appExtras = try JSONDecoder().decode([LinkGroup].self, from: Data(contentsOf: project.root.appending(path: "content/apps-extra.json")))

		async let appStoreInfo = AppStoreInfo.lookup(ids: apps.compactMap(\.appStoreID), cache: cache)
		async let appStoreReviews = AppStoreReview.recentFiveStar(appIDs: apps.filter { !$0.isArchived }.compactMap(\.appStoreID), cache: cache)
		async let recentRepositories = github.recentRepositories()

		let releases = try await withThrowingTaskGroup(of: (String, [GitHubRelease]).self) { group in
			for repository in Set(apps.compactMap(\.releaseNotes?.repository)) {
				group.addTask {
					(repository, try await github.releases(repository: repository))
				}
			}

			return try await group.reduce(into: [:]) { $0[$1.0] = $1.1 }
		}

		// When the lookup works, an app without a result likely has a wrong App Store ID, so its links go nowhere.
		let loadedAppStoreInfo = await appStoreInfo

		if !loadedAppStoreInfo.isEmpty {
			for app in apps where !app.isArchived {
				if
					let id = app.appStoreID,
					loadedAppStoreInfo[id] == nil
				{
					print("Warning: The App Store has no app with the ID \(id), which \(app.title) uses. Check its `appStoreId`.")
				}
			}
		}

		return try await Self(
			apps: apps,
			posts: posts,
			pages: pages,
			appExtras: appExtras,
			appStoreInfo: loadedAppStoreInfo,
			appStoreReviews: appStoreReviews,
			releases: releases,
			recentRepositories: recentRepositories,
			buildDate: buildDate
		)
	}
}

extension SiteContent {
	/**
	Apps that are listed and not archived. These are the apps people browse.
	*/
	public var activeApps: [App] {
		apps.filter(\.isActive)
	}

	/**
	Apps that are not archived, including unlisted ones. These get support.
	*/
	public var maintainedApps: [App] {
		apps.filter { !$0.isArchived }
	}

	/**
	Apps that are listed, including archived ones.
	*/
	public var listedApps: [App] {
		apps.filter(\.isListed)
	}

	/**
	Blog posts that are not unlisted.
	*/
	public var listedPosts: [BlogPost] {
		posts.filter { !$0.isUnlisted }
	}

	public func releases(of app: App) -> [GitHubRelease] {
		app.releaseNotes.flatMap { releases[$0.repository] } ?? []
	}

	public func appStoreInfo(of app: App) -> AppStoreInfo? {
		app.appStoreID.flatMap { appStoreInfo[$0] }
	}

	public func appStoreReviews(of app: App) -> [AppStoreReview] {
		app.appStoreID.flatMap { appStoreReviews[$0] } ?? []
	}

	/**
	An active app that changes every day, like for “while you’re here” suggestions.
	*/
	public var randomApp: App? {
		var generator = SeededRandomNumberGenerator.daily("random-app", on: buildDate)
		return activeApps.filter { !$0.isRedirect }.randomElement(using: &generator)
	}

	/**
	Where a link on a page is written in the content, like `content/apps/dato.md:12`. Empty when the link is not in the Markdown of the page.
	*/
	public func sourceLocations(ofLink link: String, onPage page: String, project: Project) -> [String] {
		let documents = apps.map { ($0.path, $0.file, $0.markdown) } + posts.map { ($0.path, $0.file, $0.markdown) } + pages.map { ($0.path, $0.file, $0.markdown) }

		return documents
			.filter { $0.0.description == page }
			.flatMap { _, file, markdown in
				markdown.links
					.filter { $0.destination == link }
					.map { file.location(ofBodyLine: $0.line, relativeTo: project.root) }
			}
	}

	public func page(_ path: RoutePath) -> MarkdownPage? {
		pagesByPath[path]
	}
}
