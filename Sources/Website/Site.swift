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
	static let name = "Sindre Sorhus"

	/**
	About how many people use the apps. No service counts this, so it is updated by hand. The apps page and the now page show it rounded down, like “6M+ users”.
	*/
	static let appUserCount = 6_000_000
	static let url = #URL("https://sindresorhus.com")
	static let description = "Full-Time Open-Sourcerer & App Maker"
	static let author = Person.sindreSorhus

	/**
	The provider ID from App Store Connect (App Analytics → Campaigns), which App Store links need for campaign tokens, so App Analytics shows which part of the site brought a download. Campaign tokens are left out while it is `nil`.
	*/
	static let appStoreProviderToken: String? = nil

	/**
	The picture that feed readers show for the site feeds.
	*/
	static let feedImage = RoutePath("/assets/sindre-sorhus-small.jpg").absoluteURL

	/**
	The source code of the site.
	*/
	static let sourceURL = #URL("https://github.com/sindresorhus/sindresorhus.github.com")

	let content: SiteContent

	public init(content: SiteContent) {
		self.content = content
	}
}

extension Schema.Person {
	/**
	The author with the profiles that identify him.
	*/
	static let author = Self(name: Site.author.name, givenName: Site.author.givenName, familyName: Site.author.familyName, url: Site.url, sameAs: Site.author.sameAs)

	/**
	The author by name only, for nested mentions like the seller of an app.
	*/
	static let authorName = Self(name: Site.author.name)

	/**
	The author with the full profile, for the home page and the about page.
	*/
	static let authorProfile = Self(
		name: Site.author.name,
		url: Site.url,
		image: Site.author.photoPath.absoluteURL,
		jobTitle: Site.description,
		description: "Full-time open-source developer and app maker focused on macOS apps, Node.js packages, and CLI tools.",
		sameAs: Site.author.sameAs,
		worksFor: Schema.Organization(name: "Independent"),
		knowsAbout: ["Software Development", "Open Source", "Swift", "Node.js", "CLI Tools", "macOS", "iOS"]
	)
}

extension Site {
	/**
	Every published file. Reading the sections below is enough to understand the site map.

	- Parameter includesGallery: Adds the component gallery at `/_gallery`, for the preview server.
	*/
	@RouteBuilder
	public func routes(project: Project, includesGallery: Bool = false) -> [Route] {
		let routes = pageRoutes + appRoutes + blogRoutes + redirectRoutes + feedRoutes + textFileRoutes + assetRoutes(project: project)
		routes

		// The 404 page suggests the closest page, so it is made from the other routes.
		NotFoundPage(suggestedPaths: routes.filter { $0.sitemapEntry != nil }.map(\.path), content: content)

		if includesGallery {
			GalleryPage(content: content)
		}
	}

	@RouteBuilder
	private var pageRoutes: [Route] {
		HomePage()
		ContactPage()
		FeedbackPage(apps: content.maintainedApps, faq: content.page(.faq))
		FeedsPage(apps: content.maintainedApps)
		GeoCitiesPage(content: content)

		// The quilt needs the contributions, which need a GitHub token.
		if !content.contributionYears.isEmpty {
			CareerQuiltPage(years: content.contributionYears)
		}

		for page in content.pages {
			if page.path == .about {
				AboutPage(page: page, content: content)
			} else if page.path == .now {
				NowPage(page: page, content: content)
			} else {
				MarkdownContentPage(page: page)
			}
		}
	}

	/**
	The old paths of the apps, posts, and pages.
	*/
	@RouteBuilder
	private var redirectRoutes: [Route] {
		for document in content.documents {
			for oldPath in document.redirectFrom {
				Route.redirect(oldPath, to: .path(document.path))
			}
		}
	}

	@RouteBuilder
	private var appRoutes: [Route] {
		AppsPage(content: content)
		AppCategory.allCases.map { AppCategoryPage(category: $0, content: content) }
		OlderVersionsPage(content: content)
		AppTimelinePage(content: content)
		ReviewsPage(content: content)
		RandomAppPage(content: content)
		AppdlePage(content: content)

		for app in content.apps {
			// An app with a page elsewhere has no page here. Its other pages stay, as the App Store links to the privacy policy.
			if let redirectURL = app.redirectURL {
				Route.redirect(app.path, to: .url(redirectURL))
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
		}
	}

	@RouteBuilder
	private var blogRoutes: [Route] {
		BlogIndexPage(posts: content.listedPosts)

		// A post on another site has no page. Its URL sends visitors there, as it was published as a page before. An unlisted post keeps its page, as its URL may already be shared.
		for post in content.posts {
			if let redirectURL = post.redirectURL {
				Route.redirect(post.path, to: .url(redirectURL))
			} else {
				BlogPostPage(post: post, content: content)
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
	The site social card, the stylesheet, the icons, and the scripts of the elements. Pages with their own social card publish it with the page.
	*/
	@RouteBuilder
	private func assetRoutes(project: Project) -> [Route] {
		OpenGraphCard.site(project: project)

		Route.text(Stylesheet.sitePath) {
			Stylesheet.site.css
		}

		Route.text(Icon.spritePath) {
			Icon.sprite
		}

		for element in Self.scriptedElements where !element.script.isInline {
			Route.text(element.scriptPath) {
				try element.generatedScript()
			}
		}
	}

	/**
	The components that are custom elements with a script. The build writes their scripts before the pages render, and the tests check them, so each one must be listed here, also an element with an inline script.
	*/
	static let scriptedElements: [any ScriptedElement.Type] = [
		AppMedia.self,
		AppSecondaryNavigation.self,
		AttachmentPicker.self,
		CodeBlock.self,
		CopyButton.self,
		FAQSuggestions.self,
		GeoCitiesAdventure.self,
		GeoCitiesArcade.self,
		GeoCitiesBeeper.self,
		GeoCitiesBergenTrail.self,
		GeoCitiesBestViewed.self,
		GeoCitiesBopIt.self,
		GeoCitiesBuddyList.self,
		GeoCitiesCalculator.self,
		GeoCitiesCasio.self,
		GeoCitiesChristmas.self,
		GeoCitiesClassNotes.self,
		GeoCitiesCoaster.self,
		GeoCitiesComicChat.self,
		GeoCitiesCommodore.self,
		GeoCitiesComputer.self,
		GeoCitiesCoolText.self,
		GeoCitiesCracktro.self,
		GeoCitiesCrafts.self,
		GeoCitiesDanceRevolution.self,
		GeoCitiesDeskToys.self,
		GeoCitiesDJBooth.Turntable.self,
		GeoCitiesDollz.self,
		GeoCitiesEffectToys.self,
		GeoCitiesFishTank.self,
		GeoCitiesFortuneToys.self,
		GeoCitiesFurby.self,
		GeoCitiesGameRoom.self,
		GeoCitiesGIFPile.self,
		GeoCitiesHamsterBand.self,
		GeoCitiesHandheld.self,
		GeoCitiesHandheldCamera.self,
		GeoCitiesInbox.self,
		GeoCitiesInsultFight.self,
		GeoCitiesKaraoke.self,
		GeoCitiesKeygen.self,
		GeoCitiesKinderEgg.self,
		GeoCitiesLego.self,
		GeoCitiesLemmings.self,
		GeoCitiesLinkingBook.self,
		GeoCitiesMailOrder.self,
		GeoCitiesMarbles.self,
		GeoCitiesMusic.self,
		GeoCitiesMusicRoom.Mixer.self,
		GeoCitiesNapster.self,
		GeoCitiesNeonSign.self,
		GeoCitiesNorwayDays.self,
		GeoCitiesNorwayHolidays.self,
		GeoCitiesPageMaker.self,
		GeoCitiesPrintShop.self,
		GeoCitiesRingtones.self,
		GeoCitiesRoom.self,
		GeoCitiesRoomToys.self,
		GeoCitiesRubik.self,
		GeoCitiesSkater.self,
		GeoCitiesStampComposer.self,
		GeoCitiesTekstTV.self,
		GeoCitiesTheremin.self,
		GeoCitiesTown.self,
		GeoCitiesTracker.self,
		GeoCitiesTradingCards.self,
		GeoCitiesVCR.self,
		GeoCitiesVisualizer.self,
		GeoCitiesWaffleClues.self,
		GeoCitiesWaffleJay.self,
		GeoCitiesWaffleQuest.self,
		GeoCitiesWindowsChips.self,
		GeoCitiesWindowsEncarta.self,
		GeoCitiesWindowsFunStuff.self,
		GeoCitiesWindowsGoo.self,
		GeoCitiesWindowsHearts.self,
		GeoCitiesWindowsHover.self,
		GeoCitiesWindowsJezzBall.self,
		GeoCitiesWindowsMovieMaker.self,
		GeoCitiesWindowsNetMeeting.self,
		GeoCitiesWindowsPinball.self,
		GeoCitiesWindowsRodent.self,
		GeoCitiesWindowsSpider.self,
		GeoCitiesWindowsTaipei.self,
		GeoCitiesWindowsTerminal.self,
		GeoCitiesWinterGames.self,
		GeoCitiesWorldCup.self,
		GeoCitiesWorms.self,
		GeoCitiesY2KKit.self,
		OverflowMenu.self,
		ShareButton.self,
		SiteHeader.self,
	]
}

/**
The paths of the pages that code links to. Apps and posts have their paths on their models, like `App.path`.
*/
extension RoutePath {
	static let apps: Self = "/apps"
	static let randomApp: Self = "/apps/random"
	static let olderVersions: Self = "/apps/older-versions"
	static let appTimeline: Self = "/apps/timeline"

	/**
	The daily game where visitors guess an app from a part of its icon.
	*/
	static let appdle: Self = "/apps/guess"

	/**
	The general FAQ for the apps.
	*/
	static let faq: Self = "/apps/faq"

	static let terms: Self = "/apps/terms"
	static let discounts: Self = "/apps/discounts"

	/**
	The wall of love: press quotes and App Store reviews of the apps.
	*/
	static let reviews: Self = "/apps/reviews"

	static let about: Self = "/about"
	static let donate: Self = "/donate"
	static let supporters: Self = "/supporters"
	static let blog: Self = "/blog"
	static let contact: Self = "/contact"
	static let feedback: Self = "/feedback"
	static let feeds: Self = "/feeds"
	static let notFound: Self = "/404"
	static let now: Self = "/now"

	/**
	One GitHub contribution calendar for each year since 2010. It exists only when the build has a GitHub token.
	*/
	static let careerQuilt: Self = "/quilt"

	/**
	The home page and the about page as a personal home page from 1999.
	*/
	static let geoCities: Self = "/1999"
}

/**
The questions of the general FAQ that code links to. The link check finds a question that no longer has the ID.
*/
extension LinkDestination {
	static let crashReportQuestion = path(.faq, fragment: "crash-report")
	static let refundQuestion = path(.faq, fragment: "refund")
	static let resetPermissionsQuestion = path(.faq, fragment: "mac-reset-permissions")
}

extension RoutePath {
	/**
	The whole URL of the path on the site, like `https://sindresorhus.com/apps`, for places outside the page, like feeds and structured data.
	*/
	var absoluteURL: URL {
		absoluteURL(site: Site.url)
	}
}

extension LinkDestination {
	/**
	The whole URL, like `https://sindresorhus.com/feedback?product=Dato`, for places outside the page, like feeds. A fragment of the same page has none.
	*/
	var absoluteURL: URL {
		absoluteURL(site: Site.url)
	}
}

extension FormatStyle where Self == Date.FormatStyle {
	/**
	Dates in English and UTC, so the output does not depend on the build machine.
	*/
	static var site: Self {
		Date.FormatStyle(locale: .site, timeZone: .gmt)
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
