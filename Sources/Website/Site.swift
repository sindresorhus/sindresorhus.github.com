import Foundation
import SiteKit

/**
sindresorhus.com: the configuration and the routes of every published file.
*/
public struct Site: Sendable {
	/*
	TODO: Use these browser features all over the website, not only on the 1999 page, when the latest Safari, Chrome, and Firefox all support them:
	- `<dialog closedby="any">`, so a dialog closes on a click outside it, instead of a script that listens for clicks on the backdrop.
	- `using` and `DisposableStack` in scripts, instead of cleanup by hand of listeners, timers, observers, and audio.
	- `interestfor` with a popover, for tooltips and hover cards, instead of `title` and scripts.
	- The customizable `<select>` (`appearance: base-select`), instead of drop-downs made by hand.
	- `focusgroup`, for one Tab stop with arrow keys in a group of controls (like the keys of the TI-83 and the color swatches of the 1999 page), instead of a Tab stop for each control or a roving `tabindex`.
	*/
	static let name = author.name

	/**
	The longest time that a reply to a support message takes, which the feedback form and its message after sending promise. The terms of use (`content/pages/apps/terms.md`) say the same time.
	*/
	static let supportReplyTime = "two weeks"

	static let url = #URL("https://sindresorhus.com")
	static let origin = SiteOrigin(url)
	static let description = "Full-Time Open-Sourcerer & App Maker"
	static let author = Person.sindreSorhus

	/**
	The provider ID from App Store Connect (App Analytics → Campaigns), which App Store links need for campaign tokens, so App Analytics shows which part of the site brought a download. Campaign tokens are left out while it is `nil`.
	*/
	static let appStoreProviderToken: String? = nil

	/**
	The picture that feed readers show for the site feeds.
	*/
	static let feedImage = Site.author.smallPhotoPath.absoluteURL

	/**
	The source code of the site.
	*/
	static let sourceURL = author.gitHubURL.appending(path: "sindresorhus.github.com")

	let content: SiteContent

	public init(content: SiteContent) {
		self.content = content
	}
}

extension Schema.Person {
	/**
	The author with the profiles that identify him.
	*/
	static let author = Self(
		id: authorID,
		name: Site.author.name,
		givenName: Site.author.givenName,
		familyName: Site.author.familyName,
		alternateName: Site.author.username,
		url: Site.url,
		sameAs: Site.author.sameAs
	)

	/**
	The author by name only, for nested mentions like the seller of an app.
	*/
	static let authorName = Self(id: authorID, name: Site.author.name)

	/**
	The ID of the author in the structured data of all the pages, like the author of an app and of the about page.
	*/
	private static let authorID = #URL("https://sindresorhus.com/#person")

	/**
	The author with the full profile, for the home page and the about page.
	*/
	static let authorProfile = Self(
		id: authorID,
		name: Site.author.name,
		alternateName: Site.author.username,
		url: Site.url,
		image: Site.author.photoPath.absoluteURL,
		jobTitle: Site.description,
		description: "Full-time open-source developer and app maker focused on macOS apps, Node.js packages, and CLI tools.",
		sameAs: Site.author.sameAs,
		knowsAbout: ["Software Development", "Open Source", "Swift", "Node.js", "CLI Tools", "macOS", "iOS"]
	)
}

extension Site {
	/**
	Every published file. Reading the sections below is enough to understand the site map.

	- Parameter includesGallery: Adds the component gallery at `/_gallery`, for the preview server.
	*/
	@RouteBuilder
	public func routes(includesGallery: Bool = false) -> [Route] {
		let routes = pageRoutes + appRoutes + blogRoutes + guideRoutes + redirectRoutes + feedRoutes + textFileRoutes + assetRoutes

		// The page of a content file names the file, so a redirect that writes the same file names both files to change.
		routes.map { route in
			guard
				route.source == nil,
				let file = content.contentFile(ofPage: route.path)
			else {
				return route
			}

			return route.source("the page of", .file(file))
		}

		// The 404 page suggests the closest page, so it is made from the other routes: the pages in the sitemap, and the privacy policies, which are not indexed, but visitors guess their paths from the links of the App Store, like `/dato/privacy`. Not the policy of an unlisted app, which the 404 page would announce.
		let privacyPolicyPaths = content.apps.filter(\.isActive).map(\.privacyPolicyPath)
		NotFoundPage(suggestedPaths: routes.filter { $0.sitemapEntry != nil }.map(\.path) + privacyPolicyPaths, content: content)

		if includesGallery {
			GalleryPage(content: content)
		}
	}

	/**
	The Swift-authored pages, shared by publication and discovery. Content pages and redirects have their own inventories.
	*/
	var specialPages: [any Page] {
		var pages: [any Page] = [
			HomePage(content: content),
			ContactPage(),
			FeedbackPage(apps: content.maintainedApps, faq: content.page(.faq), project: content.project),
			FeedsPage(apps: content.maintainedApps),
			OpenSourcePage(content: content),
			GeoCitiesPage(content: content),
			AppsPage(content: content),
			OlderVersionsPage(content: content),
			AppTimelinePage(content: content),
			ReviewsPage(content: content),
			RandomAppPage(content: content),
			AppdlePage(content: content),
			BlogIndexPage(posts: content.listedPosts),
			GuidesPage(content: content),
		]

		pages += AppCategory.allCases.map { AppCategoryPage(category: $0, content: content) }

		// The quilt needs the contributions, which need a GitHub token.
		if !content.contributionYears.isEmpty {
			pages.append(CareerQuiltPage(years: content.contributionYears))
		}

		return pages
	}

	@RouteBuilder
	private var pageRoutes: [Route] {
		for page in specialPages {
			page
		}

		for page in content.pages {
			switch page.kind {
			case .about:
				AboutPage(page: page, content: content)
			case .now:
				NowPage(page: page, content: content)
			case .faq, .standard:
				MarkdownContentPage(page: page, project: content.project)
			}
		}
	}

	/**
	The old paths of the apps, posts, guides, and pages.
	*/
	@RouteBuilder
	private var redirectRoutes: [Route] {
		for document in content.documents {
			for oldPath in document.redirectFrom {
				Route.redirect(oldPath, to: document.path)
					.source("`redirectFrom` of", document.redirectFromLocation)
			}
		}
	}

	@RouteBuilder
	private var appRoutes: [Route] {
		for app in content.apps {
			// The app lists show the icon also of an app with a page elsewhere.
			for copy in app.jpegXLCopies {
				copy.route
			}

			// An app with a page elsewhere has no page here. Its other pages stay, as the App Store links to the privacy policy.
			if let redirectURL = app.redirectURL {
				Route.redirect(app.path, to: redirectURL)
			} else {
				AppPage(app: app, content: content)
			}

			if !app.isArchived {
				PrivacyPolicyPage(app: app)
			}

			if let releaseNotes = app.releaseNotes {
				let releases = content.listing(of: app).releases
				ReleaseNotesPage(app: app, releaseNotes: releaseNotes, releases: releases)
				Route.feed(releaseNotes.feed, .releaseNotes(of: app, at: releaseNotes, releases: releases))
			}
		}

		if let sharedPuzzlePage = SharedPuzzlePage(apps: content.apps) {
			sharedPuzzlePage
		}
	}

	@RouteBuilder
	private var blogRoutes: [Route] {
		// A post on another site has no page. Its URL sends visitors there, as it was published as a page before. An unlisted post keeps its page, as its URL may already be shared.
		for post in content.posts {
			if let redirectURL = post.redirectURL {
				Route.redirect(post.path, to: redirectURL)
			} else {
				BlogPostPage(post: post, content: content)
			}
		}
	}

	/**
	The guides are not in the blog or its feed, so they have their own list.
	*/
	@RouteBuilder
	private var guideRoutes: [Route] {
		for guide in content.resolvedGuides {
			GuidePage(guide: guide, content: content)
		}
	}

	@RouteBuilder
	private var feedRoutes: [Route] {
		for feed in SiteFeed.allCases {
			Route.feed(feed.link, feed.feed(content: content))
		}
	}

	/**
	The site social card, the stylesheet, the icons, and the scripts of the elements. Pages with their own social card publish it with the page.
	*/
	@RouteBuilder
	private var assetRoutes: [Route] {
		OpenGraphCard.site(project: content.project)

		Route.text(Stylesheet.sitePath) {
			Stylesheet.site.css
		}

		Route.text(Icon.spritePath) {
			Icon.sprite
		}

		// Published unchanged, as the build read them for their hashes (``Scripts``). Each one defines its element itself.
		for asset in content.project.elementScripts() {
			Route.file(asset.path) {
				try Scripts.published.elementScript(at: asset.path)
			}
		}
	}
}

/**
The paths of the pages that code links to. Apps and posts have their paths on their models, like `App.path`.
*/
extension RoutePath {
	/**
	The npm packages for the button of ``ProjectOfTheDay``.
	*/
	static let npmPackages = #path("/npm-packages.json")

	/**
	The repos for the button of ``ProjectOfTheDay``.
	*/
	static let repositories = #path("/repos.json")

	static let apps = #path("/apps")
	static let randomApp = #path("/apps/random")
	static let olderVersions = #path("/apps/older-versions")
	static let appTimeline = #path("/apps/timeline")

	/**
	The daily game where visitors guess an app from a part of its icon.
	*/
	static let appdle = #path("/apps/guess")

	/**
	The general FAQ for the apps.
	*/
	static let faq = #path("/apps/faq")

	static let terms = #path("/apps/terms")

	/**
	The privacy policy of the website. Each app has its own (`App.privacyPolicyPath`).
	*/
	static let privacy = #path("/privacy")

	static let affiliates = #path("/apps/affiliates")
	static let tinyApps = #path("/tiny-apps")
	static let openSource = #path("/open-source")
	static let discounts = #path("/apps/discounts")

	/**
	The wall of love: press quotes and App Store reviews of the apps.
	*/
	static let reviews = #path("/apps/reviews")

	static let about = #path("/about")
	static let donate = #path("/donate")
	static let supporters = #path("/supporters")
	static let blog = #path("/blog")

	/**
	The how-to guides, like `/guides/convert-video-to-gif-mac`.
	*/
	static let guides = #path("/guides")
	static let contact = #path("/contact")
	static let feedback = #path("/feedback")
	static let feeds = #path("/feeds")
	static let notFound = #path("/404")
	static let now = #path("/now")

	/**
	One GitHub contribution calendar for each year since 2010. It exists only when the build has a GitHub token.
	*/
	static let careerQuilt = #path("/quilt")

	/**
	The home page and the about page as a personal home page from 1999.
	*/
	static let geoCities = #path("/1999")
}

/**
The questions of the general FAQ that code links to. The link check finds a question that no longer has the ID.
*/
extension LinkDestination {
	static let crashReportQuestion = path(.faq, fragment: "crash-report")
	static let refundQuestion = path(.faq, fragment: "refund")
	static let resetPermissionsQuestion = path(.faq, fragment: "mac-reset-permissions")
	static let menuBarQuestion = path(.faq, fragment: App.Section.menuBarQuestion.id)
}

extension RoutePath {
	/**
	The whole URL of the path on the site, like `https://sindresorhus.com/apps`, for places outside the page, like feeds and structured data.
	*/
	var absoluteURL: URL {
		absoluteURL(site: Site.origin)
	}
}

extension LinkDestination {
	/**
	The whole URL on the site, like `https://sindresorhus.com/feedback?product=Dato`, with a fragment resolved against the current page.
	*/
	func absoluteURL(on page: RoutePath) -> URL {
		absoluteURL(site: Site.origin, page: page)
	}
}

extension FormatStyle where Self == Date.FormatStyle {
	/**
	Dates in English, the Gregorian calendar, and UTC, so the output does not depend on the build machine, like a Mac set to the Buddhist calendar.
	*/
	static var site: Self {
		Date.FormatStyle(locale: .site, calendar: .site, timeZone: .gmt)
	}

	/**
	A month and a year, like “June 2024”.
	*/
	static var siteMonth: Self {
		site.month(.wide).year()
	}

	/**
	A full date, like “June 5, 2024”.
	*/
	static var siteDay: Self {
		site.month(.wide).day().year()
	}

	/**
	A date without the year, like “June 5”, for dates in the current year.
	*/
	static var siteDayWithoutYear: Self {
		site.month(.wide).day()
	}
}
