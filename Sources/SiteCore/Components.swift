import Elementary
import Foundation

public struct PageDocument<Content: HTML>: HTMLDocument {
	public let title: String
	public let path: String
	public let metadata: PageMetadata
	public let isAppPage: Bool
	public let extraHeadHTML: String
	public let pageContent: Content

	public init(
		path: String,
		metadata: PageMetadata,
		isAppPage: Bool = false,
		extraHeadHTML: String = "",
		@ContentBuilder content: () -> Content
	) {
		title = metadata.title
		self.path = path
		self.metadata = metadata
		self.isAppPage = isAppPage
		self.extraHeadHTML = extraHeadHTML
		pageContent = content()
	}

	public var lang: String { "en" }

	public var bodyAttributes: [HTMLAttribute<HTMLTag.body>] {
		[.class("site-body")]
	}

	public var head: some HTML {
		meta(.name(.viewport), .content("width=device-width, initial-scale=1"))
		meta(.name(.author), .content("Sindre Sorhus"))
		meta(.custom(name: "name", value: "twitter:site"), .content("@sindresorhus"))
		meta(.custom(name: "name", value: "twitter:creator"), .content("@sindresorhus"))
		meta(.custom(name: "name", value: "fediverse:creator"), .content("@sindresorhus@mastodon.social"))
		meta(.custom(name: "name", value: "x-build-time"), .content(buildTime))
		meta(.custom(name: "name", value: "twitter:card"), .content("summary_large_image"))
		meta(.custom(name: "name", value: "theme-color"), .content("#ffffff"), .custom(name: "media", value: "(prefers-color-scheme: light)"))
		meta(.custom(name: "name", value: "theme-color"), .content("#020617"), .custom(name: "media", value: "(prefers-color-scheme: dark)"))
		if !metadata.description.isEmpty {
			meta(.name(.description), .content(metadata.description))
			meta(.custom(name: "name", value: "twitter:description"), .content(metadata.description))
		}
		if metadata.noindex || metadata.nofollow {
			meta(.custom(name: "name", value: "robots"), .content([metadata.noindex ? "noindex" : nil, metadata.nofollow ? "nofollow" : nil].compactMap { $0 }.joined(separator: ",")))
		}
		if let appStoreID = metadata.appStoreID {
			meta(.custom(name: "name", value: "apple-itunes-app"), .content("app-id=\(appStoreID)"))
		}
		link(.custom(name: "rel", value: "canonical"), .href(canonicalURL))
		link(.custom(name: "rel", value: "stylesheet"), .href("/assets/site.css"))
		link(.custom(name: "rel", value: "sitemap"), .href("/sitemap-index.xml"))
		link(.custom(name: "rel", value: "apple-touch-icon"), .href("/apple-touch-icon.png"))
		link(.custom(name: "rel", value: "icon"), .href(metadata.favicon ?? "/favicon.png"))
		FeedLinks(additional: metadata.rssFeeds)
		OpenGraphMetadata(metadata: metadata, canonicalURL: canonicalURL)
		if !extraHeadHTML.isEmpty { HTMLRaw(extraHeadHTML) }
		script(.src("https://gc.zgo.at/count.js"), .async, .data("goatcounter", value: "https://sindresorhus.goatcounter.com/count")) {}
	}

	public var body: some HTML {
		SiteHeader(currentPath: path, isAppPage: isAppPage)
		main { pageContent }
		SiteFooter()
		script(.src("/scripts/site.js"), .type(.module)) {}
	}

	private var canonicalURL: String {
		path == "/" ? SiteConfiguration.origin + "/" : SiteConfiguration.origin + path
	}

	private var buildTime: String {
		let formatter = DateFormatter()
		formatter.calendar = Calendar(identifier: .gregorian)
		formatter.locale = Locale(identifier: "en_US_POSIX")
		formatter.timeZone = TimeZone(secondsFromGMT: 0)
		formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss 'GMT'"
		return formatter.string(from: Date())
	}
}

private struct FeedLinks: HTML {
	let additional: [RSSFeedLink]
	var body: some HTML {
		link(.custom(name: "rel", value: "alternate"), .custom(name: "type", value: "application/rss+xml"), .custom(name: "title", value: "Sindre Sorhus — Blog"), .href("/rss.xml"))
		link(.custom(name: "rel", value: "alternate"), .custom(name: "type", value: "application/rss+xml"), .custom(name: "title", value: "Sindre Sorhus — New Apps"), .href("/rss-apps.xml"))
		link(.custom(name: "rel", value: "alternate"), .custom(name: "type", value: "application/rss+xml"), .custom(name: "title", value: "Sindre Sorhus — New Repos"), .href("/rss-repos.xml"))
		for feed in additional {
			link(.custom(name: "rel", value: "alternate"), .custom(name: "type", value: "application/rss+xml"), .custom(name: "title", value: feed.title), .href(feed.href))
		}
	}
}

private struct OpenGraphMetadata: HTML {
	let metadata: PageMetadata
	let canonicalURL: String
	var body: some HTML {
		let image = SiteConfiguration.origin + (metadata.image ?? "/og/sindre-sorhus.png")
		meta(.property("og:title"), .content(metadata.openGraphTitle))
		meta(.property("og:type"), .content(metadata.openGraphType))
		meta(.property("og:url"), .content(canonicalURL))
		meta(.property("og:image"), .content(image))
		meta(.property("og:image:width"), .content("1200"))
		meta(.property("og:image:height"), .content("630"))
		meta(.property("og:image:alt"), .content(metadata.image == nil ? SiteConfiguration.name : (metadata.imageAlt ?? metadata.openGraphTitle)))
		meta(.property("og:locale"), .content("en_US"))
		meta(.property("og:site_name"), .content(SiteConfiguration.name))
		if !metadata.description.isEmpty { meta(.property("og:description"), .content(metadata.description)) }
		meta(.custom(name: "name", value: "twitter:title"), .content(metadata.openGraphTitle))
		meta(.custom(name: "name", value: "twitter:image"), .content(image))
		if let article = metadata.article {
			meta(.property("article:published_time"), .content(article.publishedTime))
			for author in article.authors { meta(.property("article:author"), .content(author)) }
			for tag in article.tags { meta(.property("article:tag"), .content(tag)) }
		}
	}
}

public struct SiteHeader: HTML {
	let currentPath: String
	let isAppPage: Bool

	public var body: some HTML {
		header(.id("site-header"), .class("site-header"), .data("nosnippet", value: "")) {
			div(.id("site-nav-content"), .class("site-nav")) {
				div(.class("site-nav-top")) {
					a(.class("site-brand"), .href("/")) { currentPath == "/" ? "🦄" : "Sindre Sorhus" }
					label(.for("menu-toggle"), .class("mobile-menu-toggle icon-link"), .custom(name: "aria-label", value: "Toggle menu")) { Icon(name: .menu) }
				}
				input(.id("menu-toggle"), .type(.checkbox), .custom(name: "aria-label", value: "Toggle menu"))
				div(.class("site-links-wrap")) {
					nav(.custom(name: "aria-label", value: "Primary navigation")) {
						ul(.class("site-links")) {
							NavigationLink("Apps", href: "/apps", currentPath: currentPath)
							NavigationLink("About", href: "/about", currentPath: currentPath)
							NavigationLink("Blog", href: "/blog", currentPath: currentPath)
							li(.class("mobile-nav-only")) {
								a(
									.href("/contact"),
									.custom(name: "aria-current", value: currentPath == "/contact" ? "page" : nil)
								) { "Contact" }
							}
							if !isAppPage {
								li(.class("nav-separator"), .custom(name: "aria-hidden", value: "true")) {}
								NavigationLink("Donate", href: "/donate", currentPath: currentPath)
								NavigationLink("Supporters", href: "/supporters", currentPath: currentPath)
							}
							li(.class("desktop-nav-only")) {
								a(.href("/feeds"), .class("icon-link"), .custom(name: "aria-label", value: "RSS Feeds")) {
									Icon(name: .rss)
								}
							}
							li(.class("desktop-nav-only")) {
								a(.href("/contact"), .class("icon-link"), .custom(name: "aria-label", value: "Contact")) {
									Icon(name: .mail)
								}
							}
						}
					}
				}
			}
		}
	}
}

private struct NavigationLink: HTML {
	let text: String
	let href: String
	let currentPath: String
	init(_ text: String, href: String, currentPath: String) { self.text = text; self.href = href; self.currentPath = currentPath }
	var body: some HTML {
		li { a(.href(href), .custom(name: "aria-current", value: isCurrent ? "page" : nil)) { text } }
	}
	private var isCurrent: Bool { currentPath == href || (href != "/" && currentPath.hasPrefix(href + "/")) }
}

public struct SiteFooter: HTML {
	public var body: some HTML {
		footer(.class("site-footer"), .data("nosnippet", value: "")) {
			div(.class("site-footer-inner")) {
				ul(.class("social-links")) {
					SocialLink(href: "https://x.com/sindresorhus", label: "X (Twitter)", icon: .x)
					SocialLink(href: "https://mastodon.social/@sindresorhus", label: "Mastodon", icon: .mastodon)
					SocialLink(href: "https://bsky.app/profile/sindresorhus.com", label: "Bluesky", icon: .bluesky)
					SocialLink(href: "https://instagram.com/sindresorhus", label: "Instagram", icon: .instagram)
					SocialLink(href: "https://unsplash.com/@sindresorhus", label: "Unsplash", icon: .unsplash)
					SocialLink(href: "https://github.com/sindresorhus", label: "GitHub", icon: .github)
				}
				div(.class("site-footer-quote")) { q { "The people who are crazy enough to think they can change the world are the ones who do" } }
			}
		}
	}
}

private struct SocialLink: HTML {
	let href: String
	let label: String
	let icon: IconName
	var body: some HTML {
		li { a(.href(href), .class("icon-link"), .custom(name: "rel", value: "me"), .custom(name: "aria-label", value: label)) { Icon(name: icon) } }
	}
}

public enum IconName { case menu, rss, mail, github, x, mastodon, bluesky, instagram, unsplash, appStore, shuffle, share, arrowLeft, arrowRight, sparkles, dots }

public struct Icon: HTML {
	let name: IconName
	let className: String
	public init(name: IconName, className: String = "icon") { self.name = name; self.className = className }
	public var body: some HTML { HTMLRaw(svg) }

	private var svg: String {
		let paths: String = switch name {
		case .menu: #"<path d="M4 8h16M4 16h16"/>"#
		case .rss: #"<path d="M4 19a1 1 0 1 0 2 0a1 1 0 1 0-2 0"/><path d="M4 4a16 16 0 0 1 16 16M4 11a9 9 0 0 1 9 9"/>"#
		case .mail: #"<path d="M3 7a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2v10a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V7"/><path d="m3 7 9 6 9-6"/>"#
		case .github: #"<path d="M9 19c-4.3 1.4-4.3-2.5-6-3m12 5v-3.5c0-1 .1-1.4-.5-2 2.8-.3 5.5-1.4 5.5-6a4.6 4.6 0 0 0-1.3-3.2 4.2 4.2 0 0 0-.1-3.2s-1.1-.3-3.5 1.3a12.3 12.3 0 0 0-6.2 0C6.5 2.8 5.4 3.1 5.4 3.1a4.2 4.2 0 0 0-.1 3.2A4.6 4.6 0 0 0 4 9.5c0 4.6 2.7 5.7 5.5 6-.6.6-.6 1.2-.5 2V21"/>"#
		case .x: #"<path d="m4 4 11.733 16H20L8.267 4H4M4 20l6.768-6.768m2.46-2.46L20 4"/>"#
		case .mastodon: #"<path d="M18.648 15.254C16.832 17.017 12 16.88 12 16.88a18.262 18.262 0 0 1-3.288-.256c1.127 1.985 4.12 2.81 8.982 2.475-1.945 2.013-13.598 5.257-13.668-7.636L4 10.309c0-3.036.023-4.115 1.352-5.633C7.023 2.766 12 3.01 12 3.01s4.977-.243 6.648 1.667C19.977 6.195 20 7.274 20 10.31s-.456 4.074-1.352 4.944"/><path d="M12 11.204V8.278C12 7.02 11.105 6 10 6S8 7.02 8 8.278V13m4-4.722C12 7.02 12.895 6 14 6s2 1.02 2 2.278V13"/>"#
		case .bluesky: #"<path d="M6.335 5.144C4.681 3.945 2 3.017 2 5.97c0 .59.35 4.953.556 5.661.713 2.463 3.13 2.75 5.444 2.369-4.045.665-4.889 3.208-2.667 5.41C6.363 20.428 7.246 21 8 21c2 0 3.134-2.769 3.5-3.5.333-.667.5-1.167.5-1.5 0 .333.167.833.5 1.5.366.731 1.5 3.5 3.5 3.5.754 0 1.637-.571 2.667-1.59 2.222-2.203 1.378-4.746-2.667-5.41 2.314.38 4.73.094 5.444-2.369.206-.708.556-5.072.556-5.661 0-2.953-2.68-2.025-4.335-.826C15.372 6.806 12.905 10.192 12 12c-.905-1.808-3.372-5.194-5.665-6.856"/>"#
		case .instagram: #"<path d="M3 7a4 4 0 0 1 4-4h10a4 4 0 0 1 4 4v10a4 4 0 0 1-4 4H7a4 4 0 0 1-4-4V7"/><path d="M8.5 12a3.5 3.5 0 1 0 7 0 3.5 3.5 0 0 0-7 0M17 7v.01"/>"#
		case .unsplash: #"<path d="M4 11h5v4h6v-4h5v9H4v-9M9 4h6v4H9V4"/>"#
		case .appStore: #"<path d="M3 12a9 9 0 1 0 18 0 9 9 0 1 0-18 0M8 16l1.106-1.99m1.4-2.522L13 7M7 14h5m2.9 0H17M16 16l-2.51-4.518m-1.487-2.677L11.003 7"/>"#
		case .shuffle: #"<path d="m18 4 3 3-3 3m0 10 3-3-3-3M3 7h3a5 5 0 0 1 5 5 5 5 0 0 0 5 5h5m0-10h-5a4.978 4.978 0 0 0-3 1m-4 8a4.984 4.984 0 0 1-3 1H3"/>"#
		case .share: #"<path d="M8 9H7a2 2 0 0 0-2 2v8a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2v-8a2 2 0 0 0-2-2h-1M12 14V3M9 6l3-3 3 3"/>"#
		case .arrowLeft: #"<path d="M5 12h14M5 12l6 6m-6-6 6-6"/>"#
		case .arrowRight: #"<path d="M5 12h14m-6 6 6-6m-6-6 6 6"/>"#
		case .sparkles: #"<path d="M16 18a2 2 0 0 1 2 2 2 2 0 0 1 2-2 2 2 0 0 1-2-2 2 2 0 0 1-2 2m0-12a2 2 0 0 1 2 2 2 2 0 0 1 2-2 2 2 0 0 1-2-2 2 2 0 0 1-2 2M9 18a6 6 0 0 1 6-6 6 6 0 0 1-6-6 6 6 0 0 1-6 6 6 6 0 0 1 6 6"/>"#
		case .dots: #"<circle cx="12" cy="12" r="9"/><path d="M8 12h.01M12 12h.01M16 12h.01"/>"#
		}
		return #"<svg class="\#(className)" xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">\#(paths)</svg>"#
	}
}

public extension App {
	var resolvedMainLinks: [(String, String)] {
		var result: [(String, String)] = []
		if let repositoryURL { result.append(("Learn More", repositoryURL)) }
		if let redirectURL { result.append(("Learn More", redirectURL)) }
		for key in mainLinks.keys.sorted() { if let value = mainLinks[key] { result.removeAll { $0.0 == key }; result.append((key, value)) } }
		return result
	}

	var headerLinks: [(String, String)] {
		markdown.headings.filter { $0.level == 2 && $0.text != "Footnotes" }.map { heading in
			(heading.text == "Frequently Asked Questions" ? "FAQ" : heading.text, "#\(heading.id)")
		}
	}

	var resolvedLinks: [(String, String)] {
		var result = headerLinks.filter { $0.0 != "Non-App Store Version" }
		for key in links.keys.sorted() { if let value = links[key] { result.removeAll { $0.0 == key }; result.append((key, value)) } }
		if showSupportLink && !isArchived { result.append(("Support", "/feedback?product=\(title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? title)")) }
		return result
	}

	var resolvedOverflowLinks: [(String, String)] {
		var result = overflowLinks.keys.sorted().compactMap { key in overflowLinks[key].map { (key, $0) } }
		if let nonAppStore = headerLinks.first(where: { $0.0 == "Non-App Store Version" }) { result.append(nonAppStore) }
		return result
	}

	var pageOverflowLinks: [(String, String)] {
		var result = resolvedOverflowLinks
		if !isArchived, let appStoreURL {
			result.append(("What's New", appStoreURL))
		}
		if !isArchived, releasesRepository != nil {
			result.append(("Release Notes", "/\(slug)/release-notes"))
		}
		if !isArchived {
			result.append(("Privacy Policy", "/\(slug)/privacy-policy"))
		}
		result.append(("Terms of Use", "/apps/terms"))
		if isPaid {
			result.append(("Discounts", "/apps/discounts"))
		}
		return result
	}

	var hasFAQSection: Bool { markdown.headings.contains { $0.level == 2 && $0.text == "Frequently Asked Questions" } }

	var faqHeadings: [FAQHeading] {
		guard let start = markdown.headings.firstIndex(where: { $0.level == 2 && $0.text == "Frequently Asked Questions" }) else { return [] }
		var output: [FAQHeading] = []
		var inSubsection = false
		for heading in markdown.headings.dropFirst(start + 1) {
			if heading.level == 2 { break }
			if heading.level == 3 { inSubsection = true; continue }
			if !inSubsection && heading.level == 4 && heading.id != "feedback" {
				output.append(FAQHeading(text: heading.text, slug: heading.id, metadata: markdown.headingMetadata[heading.id]?["faq"] ?? FAQMetadata()))
			}
		}
		return output
	}
}
