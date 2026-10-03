import Foundation
import SiteKit

/**
The plain files for crawlers, AI assistants, and other tools: `robots.txt`, `humans.txt`, `llms.txt`, `llms-full.txt`, `/apps.json`, and WebFinger.
*/
extension Site {
	@RouteBuilder
	var textFileRoutes: [Route] {
		Route.text("/robots.txt") {
			Self.robots
		}

		Route.text("/humans.txt") {
			Self.humans
		}

		Route.text("/llms.txt") {
			llms
		}

		Route.text("/llms-full.txt") {
			llmsFull
		}

		Route.file("/apps.json") {
			try appsJSON()
		}

		Route.file("/.well-known/webfinger") {
			try Self.webFinger()
		}
	}

	/**
	The AI crawlers that are explicitly allowed. Every other crawler is allowed too, but naming them makes the policy clear.
	*/
	private static let aiCrawlers = ["GPTBot", "OAI-SearchBot", "ChatGPT-User", "ClaudeBot", "Claude-User", "Claude-SearchBot", "PerplexityBot", "Google-Extended", "Applebot-Extended", "CCBot", "Meta-ExternalAgent"]

	private static var robots: String {
		"""
		User-agent: *
		Allow: /

		# AI crawlers may use the content, for search and for training.
		\(aiCrawlers.map { "User-agent: \($0)" }.joined(separator: "\n"))
		Allow: /

		Sitemap: \(Sitemap.indexPath.absoluteURL(site: url).absoluteString)

		"""
	}

	private static var humans: String {
		"""
		         \\
		          \\
		           \\\\
		            \\\\
		             >\\/7
		         _.-(6'  \\
		        (=___._/` \\
		             )  \\ |
		            /   / |
		           /    > /
		          j    < _\\
		      _.-' :      ``.
		      \\ r=._\\        `.
		     <`\\\\_  \\         .`-.
		      \\ r-7  `-. ._  ' .  `\\
		       \\`,      `-.`7  7)   )
		        \\/         \\|  \\'  / `-._
		                   ||    .'
		                    \\\\  (
		                     >\\  >
		                 ,.-' >.'
		                <.'_.''
		                  <'

		/* TEAM */
		Maker: \(author.name)
		Contact: \(author.email)
		From: Norway
		Site: \(url.absoluteString)

		/* SITE */
		Built with: Swift, Elementary, and swift-markdown
		Source: https://github.com/sindresorhus/sindresorhus.github.com

		"""
	}

	/**
	A summary of the site and every app for AI assistants, following https://llmstxt.org.
	*/
	private var llms: String {
		var lines = [
			"# \(Self.name)",
			"",
			"> \(Self.description). Maker of macOS and iOS apps and many open-source projects.",
			"",
			"## Apps",
			"",
		]

		lines += content.activeApps.filter { !$0.isRedirect }.map { app in
			"- [\(app.title)](\(app.path.absoluteURL(site: Self.url).absoluteString)): \(app.subtitle). \(app.platforms.map(\.rawValue).joined(separator: ", "))."
		}

		lines += ["", "## Pages", ""]
		lines += content.pages.map { page in
			"- [\(page.frontmatter.title.value)](\(page.path.absoluteURL(site: Self.url).absoluteString))\(page.frontmatter.description.map { ": \($0.value)" } ?? "")"
		}

		lines += ["", "## Blog", ""]
		lines += content.listedPosts.map { post in
			"- [\(post.title)](\(post.absoluteURL.absoluteString))\(post.description.map { ": \($0)" } ?? "")"
		}

		lines += ["", "## Optional", "", "- [Everything](\(Self.url.absoluteString)/llms-full.txt): All the app pages, pages, and blog posts as Markdown, in one file."]
		return lines.joined(separator: "\n") + "\n"
	}

	/**
	All the app pages, pages, and blog posts as Markdown, in one file.
	*/
	private var llmsFull: String {
		let apps = content.activeApps.filter { !$0.isRedirect }.map { app in
			"# \(app.title)\n\n\(app.subtitle).\n\nURL: \(app.path.absoluteURL(site: Self.url).absoluteString)\n\n\(app.file.body)"
		}

		let pages = content.pages.map { page in
			"# \(page.frontmatter.title.value)\n\nURL: \(page.path.absoluteURL(site: Self.url).absoluteString)\n\n\(page.file.body)"
		}

		let posts = content.listedPosts.filter { !$0.isRedirect }.map { post in
			"# \(post.title)\n\nURL: \(post.absoluteURL.absoluteString)\n\n\(post.file.body)"
		}

		return (["# \(Self.name)\n\n> \(Self.description)"] + apps + pages + posts).joined(separator: "\n\n---\n\n") + "\n"
	}

	/**
	The active apps as JSON, for example for the “More apps” menus in the apps.
	*/
	private func appsJSON() throws -> Data {
		struct AppEntry: Encodable {
			let name: String
			let subtitle: String
			let url: URL
			let icon: URL
			let platforms: [Platform]
			let appStoreID: Int?
			let isPaid: Bool
		}

		let apps = content.activeApps.map { app in
			AppEntry(
				name: app.title,
				subtitle: app.subtitle,
				url: app.absoluteURL,
				icon: app.iconURL,
				platforms: app.platforms,
				appStoreID: app.appStoreID,
				isPaid: app.isPaid
			)
		}

		let encoder = JSONEncoder()
		encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
		return try encoder.encode(apps)
	}

	/**
	WebFinger for the Mastodon account, so searching for `@sindre@sindresorhus.com` (any name) finds it. A static file answers every query with the same account.
	*/
	private static func webFinger() throws -> Data {
		let handle = author.fediverseHandle.drop { $0 == "@" }
		let parts = handle.split(separator: "@")

		guard parts.count == 2 else {
			throw URLError(.badURL)
		}

		struct Resource: Encodable {
			struct Link: Encodable {
				let rel: String
				var type: String?
				var href: String?
				var template: String?
			}

			let subject: String
			let aliases: [String]
			let links: [Link]
		}

		let (user, server) = (parts[0], parts[1])
		let profile = "https://\(server)/@\(user)"
		let actor = "https://\(server)/users/\(user)"

		let resource = Resource(
			subject: "acct:\(handle)",
			aliases: [profile, actor],
			links: [
				.init(rel: "http://webfinger.net/rel/profile-page", type: "text/html", href: profile),
				.init(rel: "self", type: "application/activity+json", href: actor),
				.init(rel: "http://ostatus.org/schema/1.0/subscribe", template: "https://\(server)/authorize_interaction?uri={uri}"),
			]
		)

		let encoder = JSONEncoder()
		encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
		return try encoder.encode(resource)
	}
}
