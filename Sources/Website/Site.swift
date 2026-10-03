import Foundation
import SiteKit

/**
sindresorhus.com: the configuration and the routes of every published file.
*/
public struct Site: Sendable {
	public static let name = "Sindre Sorhus"
	public static let url = URL(string: "https://sindresorhus.com")!
	public static let description = "Full-Time Open-Sourcerer & App Maker"
	public static let author = Person.sindreSorhus

	/**
	The provider ID from App Store Connect (App Analytics → Campaigns), which App Store links need for campaign tokens, so App Analytics shows which part of the site brought a download. Campaign tokens are left out while it is `nil`.
	*/
	static let appStoreProviderToken: String? = nil

	/**
	The picture that feed readers show for the site feeds.
	*/
	static let feedImage = url.appending(path: "assets/sindre-sorhus-small.jpg")

	/**
	The source code of the site.
	*/
	public static let sourceURL = URL(string: "https://github.com/sindresorhus/sindresorhus.github.com")!

	public let content: SiteContent

	public init(content: SiteContent) {
		self.content = content
	}
}

/**
A person, for the footer links and structured data.
*/
public struct Person: Sendable {
	public struct SocialLink: Sendable {
		public let name: String
		public let url: URL
		let icon: Icon

		/**
		Whether the profile identifies the person in structured data.
		*/
		var isIdentity = true
	}

	public let name: String
	public let givenName: String
	public let familyName: String
	public let twitterHandle: String
	public let fediverseHandle: String
	public let email: String

	/**
	A public path, like `/assets/sindre-sorhus.jpg`.
	*/
	public let photoPath: String

	public let socialLinks: [SocialLink]

	static let sindreSorhus = Self(
		name: "Sindre Sorhus",
		givenName: "Sindre",
		familyName: "Sorhus",
		twitterHandle: "@sindresorhus",
		fediverseHandle: "@sindresorhus@mastodon.social",
		email: "sindresorhus@gmail.com",
		photoPath: "/assets/sindre-sorhus.jpg",
		socialLinks: [
			SocialLink(name: "X (Twitter)", url: URL(string: "https://x.com/sindresorhus")!, icon: .x),
			SocialLink(name: "Mastodon", url: URL(string: "https://mastodon.social/@sindresorhus")!, icon: .mastodon),
			SocialLink(name: "Bluesky", url: URL(string: "https://bsky.app/profile/sindresorhus.com")!, icon: .bluesky),
			SocialLink(name: "Instagram", url: URL(string: "https://instagram.com/sindresorhus")!, icon: .instagram, isIdentity: false),
			SocialLink(name: "Unsplash", url: URL(string: "https://unsplash.com/@sindresorhus")!, icon: .unsplash, isIdentity: false),
			SocialLink(name: "GitHub", url: URL(string: "https://github.com/sindresorhus")!, icon: .github),
		]
	)

	/**
	The profiles that identify the person in structured data, with GitHub first.
	*/
	var sameAs: [URL] {
		let profiles = socialLinks.filter(\.isIdentity)
		return (profiles.filter { $0.icon == .github } + profiles.filter { $0.icon != .github }).map(\.url)
	}
}

extension Site {
	/**
	Every published file. Reading the sections below is enough to understand the site map.

	- Parameter includesGallery: Adds the component gallery at `/_gallery`, for the preview server.
	*/
	public func routes(project: Project, includesGallery: Bool = false) -> [Route] {
		let routes = pageRoutes + appRoutes + blogRoutes + feedRoutes + textFileRoutes + assetRoutes(project: project)

		// The 404 page suggests the closest page, so it is made from the other routes.
		return routes + [NotFoundPage(suggestedPaths: routes.filter(\.isInSitemap).map(\.path), randomApp: content.randomApp).route] + (includesGallery ? [GalleryPage(content: content).route] : [])
	}

	@RouteBuilder
	private var pageRoutes: [Route] {
		HomePage()
		ContactPage()
		FeedbackPage(apps: content.maintainedApps, faq: content.page(MarkdownPage.faqPath))
		FeedsPage(apps: content.maintainedApps)

		for page in content.pages {
			MarkdownContentPage(page: page)

			for oldPath in page.frontmatter.redirectFrom {
				Route.redirect(oldPath, to: page.path)
			}
		}
	}

	@RouteBuilder
	private var appRoutes: [Route] {
		AppsPage(content: content)
		AppCategory.allCases.map { AppCategoryPage(category: $0, content: content) }
		OlderVersionsPage(content: content)
		AppTimelinePage(content: content)
		RandomAppPage(content: content)

		for app in content.apps {
			// An app with a page elsewhere has no page here. Its other pages stay, as the App Store links to the privacy policy.
			if let redirectURL = app.redirectURL {
				Route.redirect(app.path, to: redirectURL.url)
			} else {
				AppPage(app: app, content: content)
			}

			if !app.isArchived {
				PrivacyPolicyPage(app: app)
			}

			if let releaseNotes = app.releaseNotes {
				let releases = content.releases(of: app)
				ReleaseNotesPage(app: app, releaseNotes: releaseNotes, releases: releases)
				Route.feed(releaseNotes.feed.path, .releaseNotes(of: app, at: releaseNotes, releases: releases))
			}

			for oldPath in app.redirectFrom {
				Route.redirect(oldPath, to: app.path)
			}
		}
	}

	@RouteBuilder
	private var blogRoutes: [Route] {
		BlogIndexPage.pages(for: content.listedPosts)

		// A post on another site has no page. Its URL sends visitors there, as it was published as a page before.
		for post in content.listedPosts {
			if let redirectURL = post.redirectURL {
				Route.redirect(post.path, to: redirectURL.url)
			} else {
				BlogPostPage(post: post)
			}
		}
	}

	@RouteBuilder
	private var feedRoutes: [Route] {
		for feed in SiteFeed.allCases {
			Route.feed(feed.path, feed.feed(content: content))
		}
	}

	/**
	Social cards and the stylesheet.
	*/
	@RouteBuilder
	private func assetRoutes(project: Project) -> [Route] {
		OpenGraphCard.site(project: project).route
		content.apps.map { OpenGraphCard(app: $0, project: project).route }
		content.listedPosts.map { OpenGraphCard(post: $0, project: project).route }

		Route.text(Stylesheet.sitePath) {
			Stylesheet.site.css
		}

		Route.text(Icon.spritePath) {
			Icon.sprite
		}
	}
}

/**
The paths of the pages that code links to. Pages from content files have their paths on their models, like `App.path`.
*/
extension RoutePath {
	static let apps: Self = "/apps"
	static let randomApp: Self = "/apps/random"
	static let olderVersions: Self = "/apps/older-versions"
	static let appTimeline: Self = "/apps/timeline"
	static let about: Self = "/about"
	static let blog: Self = "/blog"
	static let contact: Self = "/contact"
	static let feedback: Self = "/feedback"
	static let feeds: Self = "/feeds"
	static let notFound: Self = "/404"
}

extension Site {
	/**
	The path of the page of a content file, by its path in `content`: `apps/dato.md` is `/dato`, `blog/post.md` is `/blog/post`, and `pages/apps/faq.md` is `/apps/faq`.
	*/
	static func routePath(ofContentFile path: String) -> RoutePath? {
		guard path.hasSuffix(".md") else {
			return nil
		}

		let components = path.dropLast(3).split(separator: "/").map(String.init)

		switch components.first {
		case "apps" where components.count == 2:
			return RoutePath.root.appending(components[1])
		case "blog" where components.count == 2:
			return RoutePath.blog.appending(components[1])
		case "pages" where components.count >= 2:
			return RoutePath("/" + components.dropFirst().joined(separator: "/"))
		default:
			return nil
		}
	}
}

extension FormatStyle where Self == Date.FormatStyle {
	/**
	Dates in English and UTC, so the output does not depend on the build machine.
	*/
	static var site: Self {
		Date.FormatStyle(locale: Locale(identifier: "en_US"), timeZone: .gmt)
	}
}
