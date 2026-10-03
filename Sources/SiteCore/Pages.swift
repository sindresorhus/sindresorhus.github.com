import Elementary
import Foundation

public struct HomePage: HTML {
	public init() {}
	public var body: some HTML {
		section(.class("home-hero")) {
			canvas(.class("nebula-canvas"), .custom(name: "aria-hidden", value: "true"))
			div(.class("home-center")) {
				div(.class("profile-ring")) {
					img(.src("/assets/sindre-sorhus.jpg"), .alt("Sindre Sorhus profile photo"), .width(144), .height(144), .class("profile-photo"))
				}
				h1(.class("home-title hero-name background-animate gradient-text")) { "Sindre Sorhus" }
				p(.class("home-tagline hero-tagline")) { "Full-Time Open-Sourcerer & App Maker" }
				div(.class("home-actions")) {
					a(.href("/apps"), .class("home-button glass-btn glass-btn-primary")) { Icon(name: .appStore); " Apps" }
					a(.href("https://github.com/sindresorhus"), .class("home-button glass-btn glass-btn-dark")) { Icon(name: .github); " Code" }
				}
			}
		}
		script(.src("/scripts/home.js"), .type(.module)) {}
		HTMLRaw(personJSONLD)
	}

	private var personJSONLD: String {
		#"<script type="application/ld+json">{"@context":"https://schema.org","@type":"Person","name":"Sindre Sorhus","url":"https://sindresorhus.com","image":"https://sindresorhus.com/assets/sindre-sorhus.jpg","jobTitle":"Full-Time Open-Sourcerer & App Maker","description":"Full-time open-source developer and app maker focused on macOS apps, Node.js packages, and CLI tools.","sameAs":["https://github.com/sindresorhus","https://x.com/sindresorhus","https://mastodon.social/@sindresorhus","https://bsky.app/profile/sindresorhus.com"],"worksFor":{"@type":"Organization","name":"Independent"}}</script>"#
	}
}

public struct AppsIndexPage: HTML {
	let apps: [App]
	let allApps: [App]
	let extras: [AppExtraGroup]

	public var body: some HTML {
		div(.class("page-container")) {
			header(.class("apps-hero")) {
				div(.class("apps-title-row")) {
					h1(.class("apps-title")) {
						"Quality Crafted "
						span(.class("gradient-text")) { "Apps" }
					}
					AppsExtraMenu(groups: extras)
				}
				p(.class("apps-stats")) { "\(allApps.count) apps · \(yearsOfCraft) years of craft · 6 million users · 10K answered support emails" }
			}
			section(.id("apps-grid"), .class("apps-grid"), .data("nosnippet", value: "")) {
				for app in apps {
					AppCard(app: app)
				}
			}
			section(.class("prose content-container apps-extra"), .data("nosnippet", value: "")) {
				for group in extras {
					h2 { group.label }
					ul {
						for item in group.items {
							li {
								a(.href(item.url)) { item.title }
								" "
								span(.class("apps-extra-description")) { "- \(item.description)" }
							}
						}
					}
				}
			}
		}
		HTMLRaw(itemListJSONLD)
		script(.src("/scripts/apps.js"), .type(.module)) {}
	}

	private var yearsOfCraft: Int {
		guard let oldest = allApps.map(\.publicationDate).min() else { return 0 }
		return Calendar.current.component(.year, from: Date()) - Calendar.current.component(.year, from: oldest)
	}

	private var itemListJSONLD: String {
		let elements: [[String: Any]] = apps.enumerated().map { index, app in
			var item: [String: Any] = [
				"@type": "SoftwareApplication",
				"name": app.title,
				"description": app.subtitle,
				"url": SiteConfiguration.origin + app.url,
				"applicationCategory": app.platforms.contains(.macOS) ? "UtilitiesApplication" : "MobileApplication",
				"operatingSystem": app.platforms.map(\.rawValue).joined(separator: ", "),
				"author": ["@type": "Person", "name": "Sindre Sorhus"],
			]
			if let appStoreURL = app.appStoreURL {
				item["downloadUrl"] = appStoreURL
			}
			return [
				"@type": "ListItem",
				"position": index + 1,
				"item": item,
			]
		}
		return JSONUtilities.script([
			"@context": "https://schema.org",
			"@type": "ItemList",
			"name": "Sindre Sorhus Apps",
			"description": "Quality crafted apps by Sindre Sorhus",
			"url": "https://sindresorhus.com/apps",
			"numberOfItems": apps.count,
			"itemListElement": elements,
		])
	}
}

private struct AppsExtraMenu: HTML {
	let groups: [AppExtraGroup]

	var body: some HTML {
		div(.class("apps-extra-menu")) {
			select(.class("overflow-menu-component"), .custom(name: "aria-label", value: "More app pages")) {
				option(.value(""), .disabled, .selected) { "" }
				for group in groups {
					optgroup(.label(group.label)) {
						for item in group.items {
							option(.value(item.url)) { item.title }
						}
					}
				}
			}
			Icon(name: .dots)
		}
	}
}

public struct AppCard: HTML {
	let app: App
	public var body: some HTML {
		a(.href(app.url), .class("app-card"), .data("slug", value: app.slug)) {
			img(.src(app.iconURL), .alt("\(app.title) app icon"), .width(128), .height(128), .custom(name: "loading", value: "lazy"), .class("app-card-icon"))
			div {
				h2(.class("app-card-title")) { app.title }
				p(.class("app-card-subtitle")) { app.subtitle }
				div(.class("tags")) {
					if app.isNew() { span(.class("tag")) { "new!" } }
					span(.class("tag")) { app.isPaid ? "paid" : "free" }
					if app.repositoryURL != nil { span(.class("tag")) { "open-source" } }
					for platform in app.platforms { span(.class("tag")) { platform.rawValue } }
				}
			}
		}
	}
}

public struct AppCategoryPage: HTML {
	let title: String
	let descriptionHTML: String
	let apps: [App]
	let groupByPlatform: Bool
	let footerHTML: String

	public var body: some HTML {
		div(.class("content-container prose")) {
			h1 { title }
			if !descriptionHTML.isEmpty { HTMLRaw(descriptionHTML) }
			if groupByPlatform { AppsByPlatform(apps: apps) } else { AppSimpleList(apps: apps) }
			if !footerHTML.isEmpty { HTMLRaw(footerHTML) }
		}
	}
}

private struct AppSimpleList: HTML {
	let apps: [App]
	var body: some HTML {
		ul {
			for app in apps { li { a(.href(app.url)) { app.title }; " — \(app.subtitle)" } }
			if apps.isEmpty { li { "No apps found." } }
		}
	}
}

private struct AppsByPlatform: HTML {
	let apps: [App]
	var body: some HTML {
		for platform in Platform.allCases {
			let selected = apps.filter { $0.platforms.contains(platform) }
			if !selected.isEmpty {
				section {
					h2(.id(platform.rawValue.lowercased())) { platform.rawValue }
					AppSimpleList(apps: selected)
				}
			}
		}
	}
}

public struct AppDetailPage: HTML {
	let app: App
	let allApps: [App]
	let appStoreInfo: AppStoreInfo?

	public var body: some HTML {
		section(.class("app-page")) {
			article(.data("heading-anchors", value: ""), .custom(name: "itemscope", value: nil), .custom(name: "itemtype", value: "https://schema.org/SoftwareApplication")) {
				header(.id("app-hero"), .class("app-hero")) {
					img(.id("app-icon"), .src(app.iconURL), .alt("\(app.title) app icon"), .width(256), .height(256), .class("app-icon"))
					h1(.class("app-title"), .custom(name: "itemprop", value: "name")) { app.title }
					h2(.class("app-subtitle"), .custom(name: "itemprop", value: "description")) { app.subtitle }
					div(.id("another-random-app"), .class("another-random-app")) {
						a(.href("/apps/random"), .class("another-random-app-button")) {
							Icon(name: .shuffle)
							"Another Random App"
						}
					}
					if app.isArchived { span(.class("tag")) { "archived" } }
					DownloadOptions(app: app)
					if let downloads = app.downloads { p { strong { formatDownloads(downloads) }; " downloads" } }
					AppLinks(app: app)
				}
				if !availabilityText.isEmpty { p(.class("availability")) { availabilityText } }
				if let announcement = app.announcement { AnnouncementView(announcement: announcement) }
				if !app.media.isEmpty { AppMedia(app: app) }
				if !app.pressQuotes.isEmpty { PressQuotesView(quotes: app.pressQuotes) }
				div(.class("prose content-container")) { HTMLRaw(app.markdown.html) }
				RelatedApps(currentApp: app, apps: allApps)
				AppOverflowFooter(app: app)
			}
		}
		AppSecondaryNav(app: app)
		HTMLRaw(structuredData)
		HTMLRaw(appPageData)
		script(.src("/scripts/app.js"), .type(.module)) {}
	}

	private var availabilityText: String {
		let requirementMentionsMacOS = app.requirement?.lowercased().contains("macos") == true
		let skipPlatforms = requirementMentionsMacOS && app.platforms == [.macOS]
		let platformText = skipPlatforms ? "" : (app.platforms.isEmpty ? "" : "Available on \(app.platforms.map(\.rawValue).joined(separator: ", "))")
		return [platformText, app.requirement].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " — ")
	}

	private var structuredData: String {
		var object: [String: Any] = [
			"@context": "https://schema.org", "@type": "SoftwareApplication",
			"applicationCategory": app.platforms.contains(.macOS) ? "UtilitiesApplication" : "MobileApplication",
			"name": app.title, "operatingSystem": app.platforms.map(\.rawValue).joined(separator: ", "),
			"datePublished": TextUtilities.isoDate(app.publicationDate), "description": app.description,
			"url": SiteConfiguration.origin + app.url, "image": SiteConfiguration.origin + app.iconURL,
			"author": ["@type":"Person", "givenName":"Sindre", "familyName":"Sorhus", "url":SiteConfiguration.origin]
		]
		if !app.media.isEmpty { object["screenshot"] = app.media.filter { !$0.path.hasSuffix(".mp4") }.map { SiteConfiguration.origin + $0.path } }
		if let info = appStoreInfo, let appStoreURL = app.appStoreURL {
			object["downloadUrl"] = appStoreURL
			object["softwareVersion"] = info.version
			if let price = info.price, let currency = info.currency { object["offers"] = ["@type":"Offer", "availability":"https://schema.org/InStock", "url":appStoreURL, "price":price, "priceCurrency":currency] }
			if let count = info.userRatingCount, count > 0, let rating = info.averageUserRating { object["aggregateRating"] = ["@type":"AggregateRating", "ratingValue":round(rating * 10) / 10, "ratingCount":count] }
		}
		return JSONUtilities.script(object)
	}

	private var appPageData: String {
		let object: [String: Any?] = ["title": app.title, "appStoreURL": app.appStoreURL]
		return JSONUtilities.dataScript(id: "app-page-data", object.compactMapValues { $0 })
	}
}

private struct DownloadOptions: HTML {
	let app: App
	var body: some HTML {
		let links = app.resolvedMainLinks
		if app.appStoreID != nil || app.setappID != nil || !links.isEmpty {
			nav(.class("download-options"), .custom(name: "aria-label", value: "Download options")) {
				if !app.isArchived, let url = app.appStoreURL {
					div(.class("app-store-download download-badge")) {
						button(.id("share-button"), .class("share-button"), .type(.button), .custom(name: "aria-label", value: "Share \(app.title)")) {
							Icon(name: .share)
						}
						a(.href(url)) {
							img(.src("/assets/download-on-app-store-badge.svg"), .alt("Download on the App Store"), .custom(name:"style", value:"height:60px"))
						}
					}
				}
				if !app.isArchived, let url = app.setappURL {
					a(.href(url), .class("download-badge")) {
						img(.src("/assets/download-on-setapp-badge.svg"), .alt("Download on Setapp"), .custom(name:"style", value:"height:60px"))
					}
				}
				for link in links {
					a(.href(link.1), .class("download-badge custom-download-button")) { link.0 }
				}
			}
		}
	}
}

private struct AppLinks: HTML {
	let app: App
	var body: some HTML {
		if !app.resolvedLinks.isEmpty {
			nav(.class("app-links"), .custom(name:"aria-label", value:"App links")) {
				for link in app.resolvedLinks { a(.href(link.1)) { link.0 } }
				OverflowMenu(items: app.pageOverflowLinks + [("Show Random App", "/apps/random")])
			}
		}
	}
}

public struct OverflowMenu: HTML {
	let items: [(String, String)]
	public var body: some HTML {
		div(.class("overflow-menu-wrap")) {
			select(.class("overflow-menu-component"), .custom(name:"aria-label", value:"Overflow menu")) {
				option(.value(""), .disabled, .selected) { "" }
				for item in items { option(.value(item.1)) { item.0 } }
			}
			Icon(name: .dots)
		}
	}
}

private struct AnnouncementView: HTML {
	let announcement: Announcement
	var body: some HTML {
		aside(.class("announcement")) {
			Icon(name: .sparkles)
			div { HTMLRaw(MarkdownProcessor.process(announcement.text).html.replacingOccurrences(of:"<p>", with:"").replacingOccurrences(of:"</p>", with:"")) }
			if let url = announcement.url { a(.href(url), .class("announcement-button")) { announcement.urlText ?? "Learn more"; Icon(name:.arrowRight) } }
		}
	}
}

private struct AppMedia: HTML {
	let app: App
	var body: some HTML {
		div(.class("app-media-carousel")) {
			section(.id("app-media"), .class("app-media"), .custom(name:"aria-label", value:"App media")) {
				for (index, asset) in app.media.enumerated() {
					div(.class("app-media-item")) {
						if asset.path.hasSuffix(".mp4") {
							video(.src(asset.path), .width(asset.width), .height(asset.height), .custom(name:"autoplay"), .custom(name:"loop"), .custom(name:"muted"), .custom(name:"playsinline"), .custom(name:"preload", value:"metadata"), .custom(name:"aria-label", value:"\(app.title) demo video")) {}
						} else {
							img(.src(asset.path), .width(asset.width), .height(asset.height), .alt("\(app.title) screenshot \(index + 1)"), .custom(name:"loading", value:"lazy"))
						}
					}
				}
			}
			button(.class("media-control media-prev"), .type(.button), .custom(name:"aria-label", value:"Previous screenshot")) {
				Icon(name: .arrowLeft)
			}
			button(.class("media-control media-next"), .type(.button), .custom(name:"aria-label", value:"Next screenshot")) {
				Icon(name: .arrowRight)
			}
		}
	}
}

private struct AppOverflowFooter: HTML {
	let app: App
	var body: some HTML {
		nav(.class("app-overflow-footer"), .custom(name: "aria-label", value: "More about \(app.title)")) {
			for item in app.pageOverflowLinks {
				a(.href(item.1)) { item.0 }
			}
		}
	}
}

private struct AppSecondaryNav: HTML {
	let app: App

	var body: some HTML {
		div(
			.id("app-nav-content"),
			.class("app-secondary-nav"),
			.custom(name: "style", value: "filter:opacity(0);pointer-events:none"),
			.custom(name: "inert")
		) {
			a(.href(app.url), .class("app-secondary-identity"), .custom(name: "aria-label", value: app.title)) {
				img(.src(app.iconURL), .width(32), .height(32), .alt(""))
				span { app.title }
			}
			nav(.class("app-secondary-links")) {
				for link in app.resolvedLinks {
					a(.href(link.1)) { link.0 }
				}
				OverflowMenu(items: app.pageOverflowLinks + [("Show Random App", "/apps/random")])
				if !app.isArchived && !providerURLs.isEmpty {
					if let downloadURL {
						a(.href(downloadURL), .class("app-get-button")) { "Get" }
					} else {
						button(.type(.button), .class("app-get-button"), .custom(name: "onclick", value: "window.scrollTo({top:0})")) { "Get" }
					}
				}
			}
		}
	}

	private var providerURLs: [String] {
		var urls: [String] = []
		if let appStoreURL = app.appStoreURL { urls.append(appStoreURL) }
		if let setappURL = app.setappURL { urls.append(setappURL) }
		urls.append(contentsOf: app.resolvedMainLinks.map(\.1))
		return urls
	}

	private var downloadURL: String? {
		providerURLs.count == 1 ? providerURLs[0] : nil
	}
}

private struct PressQuotesView: HTML {
	let quotes: [PressQuote]
	var body: some HTML {
		aside(.class("press-quotes")) {
			for quote in quotes {
				blockquote {
					if quote.isStarRating { div(.custom(name:"aria-label", value:"5 out of 5 stars")) { "★★★★★" } } else { div(.class("quote-mark"), .custom(name:"aria-hidden", value:"true")) { "“" } }
					p { quote.quote }
					footer { if let url = quote.url { a(.href(url)) { quote.source } } else { quote.source } }
				}
			}
		}
	}
}

private struct RelatedApps: HTML {
	let currentApp: App
	let apps: [App]
	var body: some HTML {
		let related = relatedApps
		if !related.isEmpty {
			aside(.class("related-apps")) {
				h2 { "You Might Also Like" }
				div(.class("related-app-list")) {
					for app in related { a(.href(app.url)) { img(.src(app.iconURL), .width(64), .height(64), .alt("\(app.title) app icon"), .custom(name:"loading", value:"lazy")); span { app.title } } }
				}
			}
		}
	}
	private var relatedApps: [App] {
		let candidates = apps.filter { $0.slug != currentApp.slug && !$0.isRedirect }
		let scored: [(app: App, score: Int)] = candidates.map { app in
			var score = app.platforms.filter(currentApp.platforms.contains).count * 3
			if app.isMenuBarApp && currentApp.isMenuBarApp { score += 2 }
			if app.isPaid == currentApp.isPaid { score += 1 }
			return (app: app, score: score)
		}
		let sorted = scored.sorted { lhs, rhs in
			if lhs.score == rhs.score {
				return lhs.app.publicationDate > rhs.app.publicationDate
			}
			return lhs.score > rhs.score
		}
		return Array(sorted.prefix(8)).shuffled().prefix(3).map(\.app)
	}
}

public struct MarkdownContentPage: HTML {
	let markdown: ProcessedMarkdown
	public var body: some HTML { section(.class("content-container prose")) { HTMLRaw(markdown.html) } }
}

public struct PrivacyPage: HTML {
	let app: App
	public var body: some HTML {
		section(.class("content-container prose")) {
			if !app.isUnlisted { p { a(.href("/\(app.slug)")) { "← Back to \(app.title)" } } }
			h1 { "Privacy Policy for \(app.title)" }
			if app.hasSentry { p { "No personal information is collected by this app."; br(); br(); "It sends anonymous crash reports to "; a(.href("https://sentry.io")) { "Sentry" }; " to help fix bugs." } }
			else { p { "No data or personal information is collected by this app." } }
			p { "If you have any questions or suggestions regarding this privacy policy, do not hesitate to "; a(.href("/contact")) { "contact me" }; "." }
		}
	}
}

public struct ReleaseNotesPage: HTML {
	let app: App
	let releases: [GitHubRelease]
	public var body: some HTML {
		section(.class("content-container prose")) {
			p { a(.href("/\(app.slug)")) { "← Back to \(app.title)" } }
			h1 { "Release Notes for \(app.title)" }
			for release in releases {
				article {
					h2(.id(release.tagName.replacingOccurrences(of:"v", with:"", options:.anchored))) { release.tagName.replacingOccurrences(of:"v", with:"", options:.anchored) }
					time(.custom(name:"datetime", value:release.publishedAt)) { TextUtilities.formattedDate(release.publishedAt) }
					if let body = release.body { HTMLRaw(MarkdownProcessor.process(body).html) }
				}
			}
		}
	}
}

public struct BlogIndexPage: HTML {
	let posts: [BlogPost]
	let title: String?
	let previousURL: String?
	let nextURL: String?
	public var body: some HTML {
		section(.class("blog-shell")) {
			if let title { h1 { title } }
			div(.class("blog-list")) { for post in posts { BlogListItem(post: post) } }
			Pagination(previousURL: previousURL, nextURL: nextURL)
		}
	}
}

private struct BlogListItem: HTML {
	let post: BlogPost
	var body: some HTML {
		article(.class("blog-item")) {
			h2 { a(.href(post.url)) { post.title } }
			if let description = post.description { p { description } }
			p(.class("meta")) { time(.custom(name:"datetime", value:TextUtilities.isoDate(post.publicationDate))) { TextUtilities.formattedMonth(post.publicationDate) }; if !post.isRedirect { " — \(post.readingTime) min read" } }
		}
	}
}

private struct Pagination: HTML {
	let previousURL: String?
	let nextURL: String?
	var body: some HTML {
		if previousURL != nil || nextURL != nil {
			div(.class("pagination")) {
				if let previousURL { a(.href(previousURL)) { Icon(name:.arrowLeft); " Newer posts" } } else { span {} }
				if let nextURL { a(.href(nextURL)) { "Older posts "; Icon(name:.arrowRight) } } else { span {} }
			}
		}
	}
}

public struct BlogPostPage: HTML {
	let post: BlogPost
	public var body: some HTML {
		article {
			header(.class("blog-post-header")) {
				p(.class("apps-stats")) { time(.custom(name:"datetime", value:TextUtilities.isoDate(post.publicationDate))) { TextUtilities.formattedMonth(post.publicationDate) }; " — \(post.readingTime) min read" }
				h1(.class("blog-post-title")) { post.title }
				if let description = post.description { p(.class("blog-post-description")) { description } }
			}
			div(.id("post-container"), .class("content-container prose")) { HTMLRaw(post.markdown.html) }
		}
	}
}

public struct ContactPage: HTML {
	public init() {}
	public var body: some HTML {
		section(.id("contact-section"), .class("contact-page")) {
			div(.class("orb orb-blue")); div(.class("orb orb-pink"))
			div(.class("contact-center")) {
				p(.class("reveal contact-eyebrow"), .custom(name: "style", value: "--delay:0ms")) { "say hello" }
				div(.class("reveal contact-email-wrap"), .custom(name: "style", value: "--delay:80ms")) {
					div(.class("tilt-wrap")) {
						a(.id("contact-email"), .href("mailto:sindresorhus@gmail.com"), .class("email-link"), .custom(name:"aria-label", value:"sindresorhus@gmail.com")) {
							EmailLetters()
						}
					}
				}
				ul(.class("reveal contact-note"), .custom(name: "style", value: "--delay:200ms")) {
					li { "Keep it succinct" }
					li { "No calls or job offers" }
					li { "App queries → use in-app feedback" }
				}
			}
		}
		script(.src("/scripts/contact.js"), .type(.module)) {}
	}
}

private struct EmailLetters: HTML {
	var body: some HTML {
		for part in ["sindresorhus", "@gmail.com"] { span(.class("nobr")) { for character in part { span(.class("letter")) { String(character) } } } }
	}
}

public struct FeedbackPage: HTML {
	let apps: [App]
	let generalFAQs: [[String: Any]]

	public var body: some HTML {
		div(.id("main"), .class("feedback-main prose")) {
			div(.class("feedback-header")) {
				img(.id("app-icon"), .class("feedback-app-icon"), .alt(""), .width(128), .height(128))
				h1(.id("product-name"), .class("feedback-product-name")) { "" }
				h2(.class("feedback-title")) { "Feedback & Support" }
				div(.id("additional-info"), .class("feedback-additional-info"))
				br()
				h3(.class("feedback-platform-notice")) {
					"If you are reporting bugs with my apps on macOS/iOS 27. Make sure you are on the latest version of the app and try restarting your device first. If you get any permission issue on macOS, try "
					a(.href("/apps/faq#mac-reset-permissions")) { "resetting permissions" }
					" for the app."
				}
				br()
				p { "Note: Focus filters are broken on macOS 26.5 and later. This is out of my control." }
			}
			noscript {
				br()
				p(.class("feedback-noscript")) {
					"JavaScript is required for this form to work correctly. If you have a content blocker, you may need to allow scripts from this site."
				}
			}
			form(.id("feedback-form"), .class("feedback-form"), .action("https://formcarry.com/s/UBfgr97yfY"), .method(.post), .enctype(.multipartFormData)) {
				input(.type(.hidden), .name("_gotcha"))
				div(.class("field")) {
					label(.for("message"), .class("field-label")) { "Message*" }
					textarea(
						.id("message"),
						.class("input"),
						.placeholder("I'm a human. Please be nice."),
						.name("message"),
						.minlength(20),
						.rows(7),
						.required,
						.autofocus,
						.custom(name: "autocapitalize", value: "sentences"),
						.custom(name: "aria-expanded", value: "false"),
						.custom(name: "aria-controls", value: "faq-suggestions")
					) {}
					div(.id("crash-warning"), .class("feedback-notice crash-warning"), .custom(name: "hidden")) {
						"Looks like you're reporting a crash. It would be very helpful if you could also attach a "
						a(.href("/apps/faq#crash-report"), .target(.blank), .custom(name: "rel", value: "noopener noreferrer")) { "crash report" }
						"."
					}
					div(.id("faq-suggestions"), .class("feedback-notice faq-suggestions"), .custom(name: "hidden"), .custom(name: "tabindex", value: "-1")) {
						div(.class("faq-suggestions-header")) {
							span { "Related help:" }
							button(.id("faq-dismiss"), .type(.button), .custom(name: "tabindex", value: "-1"), .custom(name: "aria-label", value: "Dismiss")) { "×" }
						}
						ul(.id("faq-list")) {}
					}
				}
				div(.class("field")) {
					div(.class("email-label-row")) {
						label(.for("email"), .class("field-label email-label")) { "Email*" }
						span(.class("email-privacy-hint")) { "Only used for replying to you" }
					}
					input(
						.id("email"),
						.class("input"),
						.type(.email),
						.name("email"),
						.autocomplete("email"),
						.custom(name: "enterkeyhint", value: "send"),
						.required
					)
				}
				div(.class("field attachments-field")) {
					label(.id("attach-label"), .class("attachment-picker"), .for("attachments-input")) {
						HTMLRaw(#"<svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="m21.44 11.05-9.19 9.19a6 6 0 0 1-8.49-8.49l8.57-8.57A4 4 0 1 1 18 8.84l-8.59 8.57a2 2 0 0 1-2.83-2.83l8.49-8.48"/></svg>"#)
						"Attach files"
						input(.id("attachments-input"), .type(.file), .name("attachments"), .multiple, .class("attachment-input"), .custom(name: "aria-describedby", value: "attach-label"))
					}
					div(.id("file-list"), .class("file-list")) {}
				}
				input(.type(.hidden), .id("captchaResponse"), .name("g-recaptcha-response"))
				div(.class("feedback-actions")) {
					button(.id("submit-button"), .type(.submit), .class("feedback-submit")) { "Send Feedback" }
					p(.class("feedback-fineprint")) {
						"If you haven't received a reply for two weeks, check your spam folder. When you get a reply, respond in that email thread instead of sending a new message."
					}
				}
			}
		}
		HTMLRaw(feedbackDataScript)
		script(.src("https://code.jquery.com/jquery-4.0.0.min.js"), .custom(name:"crossorigin", value:"anonymous")) {}
		script(.src("/scripts/feedback.js"), .type(.module)) {}
	}

	private var feedbackDataScript: String {
		let appData = apps.map { app -> [String: Any] in
			var object: [String: Any] = [
				"title": app.title,
				"url": app.url,
				"iconUrl": app.iconURL,
				"hasFaqSection": app.hasFAQSection,
				"platforms": app.platforms.map(\.rawValue),
				"faqHeadings": app.faqHeadings.map { heading in
					var headingObject: [String: Any] = [
						"text": heading.text,
						"slug": heading.slug,
					]
					if !heading.metadata.keywords.isEmpty {
						headingObject["keywords"] = heading.metadata.keywords
					}
					if !heading.metadata.platforms.isEmpty {
						headingObject["platforms"] = heading.metadata.platforms
					}
					return headingObject
				},
			]
			if let repositoryURL = app.repositoryURL {
				object["repoUrl"] = repositoryURL
			}
			if let feedbackNote = app.feedbackNote {
				object["feedbackNote"] = MarkdownProcessor.process(feedbackNote).html
			}
			return object
		}
		return JSONUtilities.dataScript(id:"feedback-data", ["apps":appData,"generalFaqs":generalFAQs])
	}
}

public struct FeedsPage: HTML {
	let apps: [App]
	public var body: some HTML {
		section(.class("content-container prose")) {
			h1 { "RSS Feeds" }
			ul { li { a(.href("/rss.xml")) { "Blog" } }; li { a(.href("/rss-apps.xml")) { "New Apps" } }; li { a(.href("/rss-repos.xml")) { "New Repos" } } }
			h2 { "App Release Notes" }
			ul { for app in apps.filter({ $0.releasesRepository != nil }).sorted(by:{ $0.title < $1.title }) { li { a(.href("/\(app.slug)/rss.xml")) { app.title } } } }
		}
	}
}

public struct RandomAppPage: HTML {
	let slugs: [String]
	public var body: some HTML {
		div(.class("content-container prose")) { noscript { p { "JavaScript is required to show a random app. You can always browse the "; a(.href("/apps")) { "app list" }; " manually." } } }
		HTMLRaw(JSONUtilities.dataScript(id:"random-app-data", ["slugs":slugs]))
		script(.src("/scripts/random-app.js"), .type(.module)) {}
	}
}

public struct NotFoundPage: HTML {
	public init() {}
	public var body: some HTML { section(.class("content-container prose")) { h1 { "404" }; p { "The page you're looking for could not be found." }; p { a(.href("/")) { "Go home" } } } }
}

public enum JSONUtilities {
	public static func script(_ object: Any) -> String { #"<script type="application/ld+json">\#(json(object))</script>"# }
	public static func dataScript(id: String, _ object: Any) -> String {
		let escapedJSON = json(object).replacingOccurrences(of: "</", with: #"<\/"#)
		return #"<script type="application/json" id="\#(id)">\#(escapedJSON)</script>"#
	}
	private static func json(_ object: Any) -> String {
		guard JSONSerialization.isValidJSONObject(object), let data = try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys]), let string = String(data:data, encoding:.utf8) else { return "{}" }
		return string
	}
}

private func formatDownloads(_ n: Int) -> String {
	if n >= 1_000_000 { let value = Double(n) / 1_000_000; return value.rounded() == value ? "\(Int(value))M+" : String(format:"%.1fM+", value) }
	if n >= 1000 { return "\(n / 1000)K+" }
	return String(n)
}
