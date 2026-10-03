import Elementary
import Foundation

public struct SiteBuilder: Sendable {
	public let root: URL
	public let output: URL
	private let dataClient: BuildDataClient

	public init(root: URL, output: URL? = nil, dataClient: BuildDataClient = BuildDataClient()) {
		self.root = root
		self.output = output ?? root.appending(path: "dist")
		self.dataClient = dataClient
	}

	public func build() async throws -> BuildReport {
		StyleRegistry.shared.reset()
		let apps = try ContentLoader.loadApps(root: root)
		let posts = try ContentLoader.loadPosts(root: root)
		let markdownPages = try ContentLoader.loadMarkdownPages(root: root)
		let appExtras = try ContentLoader.loadAppExtras(root: root)
		let listedApps = apps.filter { !$0.isUnlisted }
		let publicApps = listedApps.filter { !$0.isArchived }
		let visibleApps = publicApps
		let visiblePosts = posts.filter { !$0.isUnlisted }
		let appStoreInfo = await dataClient.appStoreInfo(ids: apps.compactMap(\.appStoreID))
		let releaseRepositories = Array(Set(apps.filter { !$0.isArchived }.compactMap(\.releasesRepository)))
		let releasesByRepository = try await fetchReleases(repositories: releaseRepositories)

		try resetOutput()
		try copyPublicAssets()
		try OGImageGenerator.generate(apps: apps, root: root, output: output)
		var routes = Set<String>()

		try writeHTML("/", metadata: .init(title: SiteConfiguration.name, description: SiteConfiguration.description), routes: &routes) { HomePage() }
		try writeHTML("/apps", metadata: .init(title: "Apps — Sindre Sorhus", description: "Quality crafted apps by Sindre Sorhus"), routes: &routes) {
			AppsIndexPage(apps: publicApps, allApps: listedApps, extras: appExtras)
		}
		try writeHTML("/contact", metadata: .init(title: "Contact — Sindre Sorhus", description: "How to contact Sindre Sorhus."), routes: &routes) { ContactPage() }
		let feedbackFAQs = generalFeedbackFAQs(from: markdownPages)
		try writeHTML("/feedback", metadata: .init(title: "Feedback & Support — Sindre Sorhus", description: "Send feedback, report a bug, or get support for apps by Sindre Sorhus."), extraHeadHTML: #"<link rel="preconnect" href="https://formcarry.com">"#, routes: &routes) { FeedbackPage(apps: apps.filter { !$0.isArchived }, generalFAQs: feedbackFAQs) }
		try writeHTML("/feeds", metadata: .init(title: "RSS Feeds — Sindre Sorhus", description: "RSS feeds for the blog, new apps, new repos, and app release notes by Sindre Sorhus."), routes: &routes) {
			FeedsPage(apps: apps.filter { !$0.isArchived })
		}
		try writeHTML("/apps/random", metadata: .init(title: "Random App — Sindre Sorhus", noindex: true), routes: &routes) { RandomAppPage(slugs: visibleApps.map(\.slug)) }
		try writeHTML("/404", metadata: .init(title: "Error 404 — Sindre Sorhus"), routes: &routes) { NotFoundPage() }

		try buildAppCategories(apps: apps, routes: &routes)
		try buildMarkdownPages(markdownPages, routes: &routes)

		for app in apps {
			let showsBanner = !app.isArchived && app.platforms.contains { $0 == .iOS || $0 == .visionOS }
			let feeds = (!app.isArchived && app.releasesRepository != nil) ? [RSSFeedLink(title: "\(app.title) Release Notes", href: "/\(app.slug)/rss.xml")] : []
			let metadata = PageMetadata(
				title: "\(app.title): \(app.subtitle) — Sindre Sorhus",
				description: app.description,
				image: "/og/\(app.slug).png",
				imageAlt: "\(app.title) app",
				openGraphTitle: app.title,
				openGraphType: "product",
				appStoreID: showsBanner ? app.appStoreID : nil,
				favicon: app.iconURL,
				rssFeeds: feeds
			)
			try writeHTML("/\(app.slug)", metadata: metadata, isAppPage: true, routes: &routes) { AppDetailPage(app: app, allApps: visibleApps, appStoreInfo: app.appStoreID.flatMap { appStoreInfo[$0] }) }
		}

		for app in apps where !app.isArchived {
			let privacySummary = app.hasSentry ? "No personal information is collected. Anonymous crash reports are sent to Sentry." : "No data or personal information is collected."
			try writeHTML("/\(app.slug)/privacy-policy", metadata: .init(title: "Privacy Policy — \(app.title) — Sindre Sorhus", description: "The privacy policy of the \(app.title) app. \(privacySummary)"), routes: &routes) { PrivacyPage(app: app) }
		}

		for app in apps where !app.isArchived && app.releasesRepository != nil {
			guard let repository = app.releasesRepository else { continue }
			let releases = releasesByRepository[repository] ?? []
			let feed = RSSFeedLink(title: "\(app.title) Release Notes", href: "/\(app.slug)/rss.xml")
			try writeHTML("/\(app.slug)/release-notes", metadata: .init(title: "Release Notes — \(app.title)", description: "The changes in each version of the \(app.title) app.", rssFeeds: [feed]), routes: &routes) { ReleaseNotesPage(app: app, releases: releases) }
			let feedItems = releases.filter { $0.tagName != "v1.0.0" }.compactMap { release -> RSSItem? in
				guard let date = ISO8601DateFormatter().date(from: release.publishedAt) else { return nil }
				let version = release.tagName.replacingOccurrences(of: "v", with: "", options: .anchored)
				return RSSItem(title: version, link: "/\(app.slug)/release-notes#\(version)", publicationDate: date, contentHTML: release.body.map { MarkdownProcessor.process($0).html })
			}
			try writeText("/\(app.slug)/rss.xml", FeedRenderer.rss(title: "\(app.title) Release Notes", description: "Latest releases of \(app.title)", items: feedItems), routes: &routes)
		}

		try buildBlog(posts: visiblePosts, routes: &routes)
		try await buildFeeds(apps: visibleApps, posts: visiblePosts, routes: &routes)
		try writeRedirect("/thanks", to: "/supporters", routes: &routes)
		try writeRedirect("/lock-screen-one", to: "/any-text", routes: &routes)
		try writeStylesheet()
		try writeSitemap(routes: routes)
		let validation = try validate(routes: routes)
		return BuildReport(appCount: apps.count, postCount: posts.count, routeCount: routes.count, validation: validation)
	}

	private func buildAppCategories(apps: [App], routes: inout Set<String>) throws {
		let categories: [(String, String, String, [App], Bool, String)] = [
			("/apps/free", "Free Apps", "The apps of mine that are completely free (without ads!).", apps.filter { !$0.isArchived && !$0.isUnlisted && !$0.isPaid }, true, #"<br><p>If you like my work, consider leaving a review on the App Store. And also check out my <a href="/apps/paid">paid apps</a>.</p><p><a href="/apps/older-versions">Older versions</a> of paid apps for older macOS versions are available for free.</p>"#),
			("/apps/paid", "Paid Apps", "The apps of mine that are paid. One-time payment. Own forever.", apps.filter { !$0.isArchived && !$0.isUnlisted && $0.isPaid }, true, #"<br><p>You can find my free apps <a href="/apps/free">here</a>.</p>"#),
			("/apps/setapp", "Setapp Apps", "Apps of mine available on **Setapp**.", apps.filter { !$0.isArchived && !$0.isUnlisted && $0.setappID != nil }, false, ""),
			("/apps/macos", "Mac Apps", "The apps of mine that run on the Mac.", apps.filter { !$0.isArchived && !$0.isUnlisted && $0.platforms.contains(.macOS) }, false, ""),
			("/apps/ios", "iPhone & iPad Apps", "The apps of mine that run on iPhone and iPad.", apps.filter { !$0.isArchived && !$0.isUnlisted && $0.platforms.contains(.iOS) }, false, ""),
			("/apps/watchos", "Apple Watch Apps", "The apps of mine that run on Apple Watch.", apps.filter { !$0.isArchived && !$0.isUnlisted && $0.platforms.contains(.watchOS) }, false, ""),
			("/apps/visionos", "Apple Vision Apps", "The apps of mine that run on Apple Vision.", apps.filter { !$0.isArchived && !$0.isUnlisted && $0.platforms.contains(.visionOS) }, false, ""),
			("/apps/menu-bar", "Menu Bar Apps", "I love making menu bar apps.", apps.filter { !$0.isArchived && !$0.isUnlisted && $0.isMenuBarApp }, false, ""),
			("/apps/archived", "Archived Apps", "Apps that are no longer being worked on.", apps.filter { $0.isArchived && !$0.isUnlisted }, false, ""),
			("/apps/shortcuts", "Shortcuts Apps", "Apps related to the [Shortcuts app](https://support.apple.com/guide/shortcuts-mac/intro-to-shortcuts-apdf22b0444c/mac).", ["actions","ai-actions","shortcutie","short-run"].compactMap { slug in apps.first { $0.slug == slug } }, false, "")
		]
		for category in categories {
			let description = MarkdownProcessor.process(category.2).html
			try writeHTML(category.0, metadata: .init(title: "\(category.1) — Sindre Sorhus", description: MarkdownProcessor.process(category.2).introduction ?? category.2), routes: &routes) { AppCategoryPage(title: category.1, descriptionHTML: description, apps: category.3, groupByPlatform: category.4, footerHTML: category.5) }
		}

		let listedApps = apps.filter { !$0.isUnlisted }
		let versions = Set(listedApps.flatMap(\.olderMacOSVersions)).sorted { (Double($0) ?? 0) > (Double($1) ?? 0) }
		let html = versions.map { version in
			let list = listedApps.filter { $0.olderMacOSVersions.contains(version) }.map { #"<li><a href="\#($0.olderVersionsURL)">\#(TextUtilities.escapeHTML($0.title))</a> — \#(TextUtilities.escapeHTML($0.subtitle))</li>"# }.joined()
			return #"<section><h2 id="macos-\#(version.replacingOccurrences(of:".",with:"-"))">macOS \#(version)</h2><ul>\#(list)</ul></section>"#
		}.joined()
		let page = ProcessedMarkdown(html: #"<h1>Older Versions</h1><p>My macOS apps with an older version compatible with the following macOS versions.</p><p>Even my paid apps are free for these older versions.</p>\#(html)"#, headings: [], headingMetadata: [:], introduction: nil)
		try writeHTML("/apps/older-versions", metadata: .init(title: "Older Versions — Apps — Sindre Sorhus", description: "Free older versions of apps by Sindre Sorhus for older macOS versions."), routes: &routes) { MarkdownContentPage(markdown: page) }
	}

	private func buildMarkdownPages(_ pages: [MarkdownPage], routes: inout Set<String>) throws {
		let reserved: Set<String> = ["/apps/random", "/contact", "/feedback", "/feeds"]
		for page in pages where !reserved.contains(page.route) {
			try writeHTML(page.route, metadata: .init(title: "\(page.title) — Sindre Sorhus", description: page.description ?? ""), routes: &routes) { MarkdownContentPage(markdown: page.markdown) }
		}
	}

	private func buildBlog(posts: [BlogPost], routes: inout Set<String>) throws {
		for post in posts {
			let article = ArticleMetadata(publishedTime: ISO8601DateFormatter().string(from: post.publicationDate), authors: ["Sindre Sorhus"], tags: post.tags)
			try writeHTML("/blog/\(post.slug)", metadata: .init(title: "\(post.title) — Sindre Sorhus", description: post.description ?? "", openGraphTitle: post.title, openGraphType: "article", article: article), routes: &routes) { BlogPostPage(post: post) }
		}
		let pages = posts.chunked(size: SiteConfiguration.blogPostsPerPage)
		for (index, page) in pages.enumerated() {
			let number = index + 1
			let route = number == 1 ? "/blog" : "/blog/\(number)"
			let previous = number > 1 ? (number == 2 ? "/blog" : "/blog/\(number - 1)") : nil
			let next = number < pages.count ? "/blog/\(number + 1)" : nil
			try writeHTML(route, metadata: .init(title: "Blog \(number > 1 ? "— Page \(number) " : "")— Sindre Sorhus", description: "Articles by Sindre Sorhus about open source and programming.", noindex: number > 1, openGraphType: "blog"), routes: &routes) { BlogIndexPage(posts: page, title: nil, previousURL: previous, nextURL: next) }
		}
	}

	private func fetchReleases(repositories: [String]) async throws -> [String: [GitHubRelease]] {
		let client = dataClient
		return try await withThrowingTaskGroup(of: (String, [GitHubRelease]).self) { group in
			for repository in repositories {
				group.addTask {
					(repository, try await client.releases(repository: repository))
				}
			}

			var result: [String: [GitHubRelease]] = [:]
			for try await (repository, releases) in group {
				result[repository] = releases
			}
			return result
		}
	}

	private func buildFeeds(apps: [App], posts: [BlogPost], routes: inout Set<String>) async throws {
		var combined = posts.map { RSSItem(title: $0.title, link: $0.url, publicationDate: $0.publicationDate, description: $0.description, guid: $0.isRedirect ? "\(SiteConfiguration.origin)/blog/\($0.slug)" : nil) }
		combined += apps.map { RSSItem(title: "New App: \($0.title)", link: $0.url, publicationDate: $0.publicationDate, description: $0.subtitle, guid: $0.isRedirect ? "\(SiteConfiguration.origin)/blog/\($0.slug)" : nil) }
		combined.sort { $0.publicationDate > $1.publicationDate }
		try writeText("/rss.xml", FeedRenderer.rss(title: "Sindre Sorhus — Blog", description: SiteConfiguration.description, items: combined), routes: &routes)
		let appItems = apps.map { RSSItem(title: $0.title, link: $0.url, publicationDate: $0.publicationDate, description: $0.subtitle) }
		try writeText("/rss-apps.xml", FeedRenderer.rss(title: "Sindre Sorhus — New Apps", description: "New apps by Sindre Sorhus", items: appItems), routes: &routes)
		let repos = try await dataClient.recentRepositories()
		let repoItems = repos.compactMap { repo -> RSSItem? in guard let date = ISO8601DateFormatter().date(from: repo.createdAt) else { return nil }; return RSSItem(title: repo.name, link: repo.htmlURL, publicationDate: date, description: repo.description) }
		try writeText("/rss-repos.xml", FeedRenderer.rss(title: "Sindre Sorhus — New Repos", description: "Recently created GitHub repos by Sindre Sorhus", items: repoItems), routes: &routes)
	}

	private func generalFeedbackFAQs(from pages: [MarkdownPage]) -> [[String: Any]] {
		let allowed: Set<String> = ["refund","device-limit","transfer-purchase","app-store-download-problem","invoice","discounts","universal-purchase","export-settings","localize","homebrew","uninstall-app","app-cant-be-opened","high-cpu","randomly-quits","launch-at-login-not-working","app-not-showing-in-menu-bar","app-problem","icloud-sync","reset-app"]
		guard let faq = pages.first(where: { $0.route == "/apps/faq" }) else { return [] }
		return faq.markdown.headings.filter { $0.level == 3 && allowed.contains($0.id) }.map { heading in
			let metadata = faq.markdown.headingMetadata[heading.id]?["faq"] ?? FAQMetadata()
			var object: [String: Any] = [
				"question": heading.text,
				"url": "/apps/faq#\(heading.id)",
			]
			if !metadata.keywords.isEmpty {
				object["keywords"] = metadata.keywords
			}
			if !metadata.platforms.isEmpty {
				object["platforms"] = metadata.platforms
			}
			return object
		}
	}

	private func writeHTML<Content: HTML>(_ route: String, metadata: PageMetadata, isAppPage: Bool = false, extraHeadHTML: String = "", routes: inout Set<String>, @ContentBuilder content: () -> Content) throws {
		guard routes.insert(route).inserted else { throw BuildError.duplicateRoute(route) }
		let document = PageDocument(path: route, metadata: metadata, isAppPage: isAppPage, extraHeadHTML: extraHeadHTML, content: content)
		try writeFile(route: route, extension: "html", contents: document.render())
	}

	private func writeText(_ route: String, _ text: String, routes: inout Set<String>) throws {
		guard routes.insert(route).inserted else { throw BuildError.duplicateRoute(route) }
		try writeFile(route: route, extension: nil, contents: text)
	}

	private func writeRedirect(_ route: String, to destination: String, routes: inout Set<String>) throws {
		guard routes.insert(route).inserted else { throw BuildError.duplicateRoute(route) }
		let html = #"<!doctype html><meta charset="utf-8"><meta name="robots" content="noindex"><meta http-equiv="refresh" content="0;url=\#(destination)"><link rel="canonical" href="\#(SiteConfiguration.origin)\#(destination)"><title>Redirecting to: \#(destination)</title><a href="\#(destination)">Redirecting…</a>"#
		try writeFile(route: route, extension: "html", contents: html)
	}

	private func writeFile(route: String, extension fileExtension: String?, contents: String) throws {
		let clean = route == "/" ? "index" : String(route.dropFirst())
		let relative = fileExtension.map { clean + ".\($0)" } ?? clean
		let url = output.appending(path: relative)
		try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
		try contents.write(to: url, atomically: true, encoding: .utf8)
	}

	private func writeStylesheet() throws {
		let url = output.appending(path: "assets/site.css")
		try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
		try SiteStyles.stylesheet.write(to: url, atomically: true, encoding: .utf8)
	}

	private func writeSitemap(routes: Set<String>) throws {
		let pageRoutes = routes.filter { !$0.hasSuffix(".xml") && $0 != "/apps/random" && $0 != "/404" }.sorted()
		let urls = pageRoutes.map { "<url><loc>\(TextUtilities.escapeXML(SiteConfiguration.origin + ($0 == "/" ? "" : $0)))</loc></url>" }.joined()
		let sitemap = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\">\(urls)</urlset>"
		try sitemap.write(to: output.appending(path:"sitemap-0.xml"), atomically:true, encoding:.utf8)
		let index = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><sitemapindex xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\"><sitemap><loc>\(SiteConfiguration.origin)/sitemap-0.xml</loc></sitemap></sitemapindex>"
		try index.write(to: output.appending(path:"sitemap-index.xml"), atomically:true, encoding:.utf8)
	}

	private func resetOutput() throws {
		try? FileManager.default.removeItem(at: output)
		try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
	}

	private func copyPublicAssets() throws {
		let source = root.appending(path:"public")
		guard FileManager.default.fileExists(atPath: source.path) else { return }
		for item in try FileManager.default.contentsOfDirectory(at: source, includingPropertiesForKeys:nil) {
			try FileManager.default.copyItem(at:item, to:output.appending(path:item.lastPathComponent))
		}
	}

	private func validate(routes: Set<String>) throws -> ValidationReport {
		let htmlFiles = try recursiveFiles(at: output).filter { $0.pathExtension == "html" }
		var broken: [String] = []
		let hrefRegex = try NSRegularExpression(pattern:#"(?:href|src)=\"(/[^\"?#]*)(?:[?#][^\"]*)?\""#)
		for file in htmlFiles {
			let html = try String(contentsOf:file, encoding:.utf8)
			let matches = hrefRegex.matches(in:html, range:NSRange(html.startIndex..<html.endIndex,in:html))
			for match in matches {
				guard let range = Range(match.range(at:1), in:html) else { continue }
				let path = String(html[range])
				if path.hasPrefix("//") { continue }
				let resource = output.appending(path:String(path.dropFirst()))
				let htmlResource = output.appending(path:String(path.dropFirst()) + ".html")
				if !FileManager.default.fileExists(atPath:resource.path) && !FileManager.default.fileExists(atPath:htmlResource.path) { broken.append("\(file.lastPathComponent): \(path)") }
			}
		}
		return ValidationReport(brokenInternalLinks:Array(Set(broken)).sorted())
	}

	private func recursiveFiles(at url: URL) throws -> [URL] {
		guard let enumerator = FileManager.default.enumerator(at:url, includingPropertiesForKeys:[.isRegularFileKey]) else { return [] }
		return enumerator.compactMap { $0 as? URL }.filter { (try? $0.resourceValues(forKeys:[.isRegularFileKey]).isRegularFile) == true }
	}
}

public struct BuildReport: Sendable {
	public let appCount: Int
	public let postCount: Int
	public let routeCount: Int
	public let validation: ValidationReport
	public var isValid: Bool { validation.brokenInternalLinks.isEmpty }
}

public struct ValidationReport: Sendable { public let brokenInternalLinks: [String] }
public enum BuildError: Error { case duplicateRoute(String) }

private extension Array {
	func chunked(size: Int) -> [[Element]] {
		stride(from:0, to:count, by:size).map { Array(self[$0..<Swift.min($0 + size, count)]) }
	}
}
