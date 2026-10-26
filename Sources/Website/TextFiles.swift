import Foundation
import Markdown
import SiteKit

/**
The plain files for crawlers, AI assistants, and other tools: `robots.txt`, `humans.txt`, `llms.txt`, `llms-full.txt`, `/apps.json`, WebFinger, and the app site association, and the npm packages and the repos for the buttons of ``ProjectOfTheDay``.
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

		Route.text(Self.llmsFullPath) {
			llmsFull
		}

		Route.file("/apps.json") {
			try appsJSON()
		}

		Route.file("/.well-known/webfinger") {
			Self.webFinger()
		}

		if let sharedPuzzlePage = SharedPuzzlePage(apps: content.apps) {
			Route.file("/.well-known/apple-app-site-association") {
				sharedPuzzlePage.appSiteAssociation
			}
		}

		// Without projects, the about page has no card for them, so its button needs no file.
		let packages = content.discoverablePackages
		let repositories = content.discoverableRepositories

		if !packages.isEmpty {
			Route.file(.npmPackages) {
				ProjectOfTheDay.listJSON(packages)
			}
		}

		if !repositories.isEmpty {
			Route.file(.repositories) {
				ProjectOfTheDay.listJSON(repositories)
			}
		}
	}

	private static let llmsFullPath: RoutePath = "/llms-full.txt"

	/**
	The AI crawlers that are explicitly allowed. Every other crawler is allowed too, but naming them makes the policy clear.
	*/
	private static let aiCrawlers = ["GPTBot", "OAI-SearchBot", "ChatGPT-User", "ClaudeBot", "Claude-User", "Claude-SearchBot", "PerplexityBot", "Google-Extended", "Applebot-Extended", "CCBot", "Meta-ExternalAgent"]

	private static var robots: String {
		"""
		User-agent: *
		Allow: /

		# AI crawlers may use the content, for search and for training.
		\(aiCrawlers.lazy.map { "User-agent: \($0)" }.joined(separator: "\n"))
		Allow: /

		Sitemap: \(Sitemap.indexPath.absoluteURL.absoluteString)

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
		Source: \(sourceURL.absoluteString)

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

		lines += content.activeAppsWithPages.map { app in
			"- [\(app.title)](\(app.path.absoluteURL.absoluteString)): \(app.subtitle). \(app.operatingSystems)."
		}

		lines += ["", "## Pages", ""]
		lines += content.pages.map { page in
			"- [\(page.title)](\(page.path.absoluteURL.absoluteString))\(page.description.map { ": \($0)" } ?? "")"
		}

		lines += ["", "## Blog", ""]
		lines += content.listedPosts.map { post in
			"- [\(post.title)](\(post.absoluteURL.absoluteString))\(post.description.map { ": \($0)" } ?? "")"
		}

		lines += ["", "## Optional", "", "- [Everything](\(Self.llmsFullPath.absoluteURL.absoluteString)): All the app pages, pages, and blog posts as Markdown, in one file."]
		return lines.joined(separator: "\n") + "\n"
	}

	/**
	All the app pages, pages, and blog posts as Markdown, in one file.
	*/
	private var llmsFull: String {
		let apps = content.activeAppsWithPages.map { app in
			"# \(app.title)\n\n\(app.subtitle).\n\nURL: \(app.path.absoluteURL.absoluteString)\n\n\(app.file.withAbsoluteLinks(app.fullMarkdown, page: app.path.absoluteURL, project: content.project))"
		}

		let pages = content.pages.map { page in
			"# \(page.title)\n\nURL: \(page.path.absoluteURL.absoluteString)\n\n\(page.file.withAbsoluteLinks(page.fullMarkdown, page: page.path.absoluteURL, project: content.project))"
		}

		let posts = content.listedPosts.filter { !$0.isRedirect }.map { post in
			"# \(post.title)\n\nURL: \(post.absoluteURL.absoluteString)\n\n\(post.file.withAbsoluteLinks(post.file.body, page: post.absoluteURL, project: content.project))"
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
			let appStoreID: AppStoreID?
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
	private static func webFinger() -> Data {
		let handle = author.fediverseHandle.drop { $0 == "@" }
		let parts = handle.split(separator: "@")

		guard parts.count == 2 else {
			preconditionFailure("A fediverse handle is a user and a server, like `@sindresorhus@mastodon.social`, got `\(author.fediverseHandle)`.")
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

		let user = parts[0]
		let server = parts[1]
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

		return Data(JSONEncoder.pageJSON(resource).utf8)
	}
}

extension App {
	/**
	The Markdown of the page with what the build adds from the facts of the app, like the common and shared questions and the older versions, where the page shows them (``App/Frontmatter/addingGeneratedSections(to:sharedQuestions:)``). The blocks of the file keep their source, and the added blocks are formatted.

	Limitation: the parser leaves link reference definitions and footnote definitions out of the blocks, so they are left out, and it gives a setext heading (underlined with `=` or `-`) directly followed by text a range that has the next line, so that line is there twice. The app files have none.
	*/
	fileprivate var fullMarkdown: String {
		let lines = file.body.split(separator: "\n", omittingEmptySubsequences: false)
		let document = frontmatter.addingGeneratedSections(to: Document(parsing: file.body, options: .parseBlockDirectives), sharedQuestions: sharedQuestions)

		return document.blockChildren.map { block in
			guard
				// Raw HTML is formatted as it is written, and the parser ends the range of an HTML comment of several lines a line early.
				!(block is HTMLBlock),
				// The added blocks have no range, or the source of their own file, like the shared questions.
				let range = block.range,
				range.lowerBound.source == nil
			else {
				return block.format()
			}

			// A top-level block has whole lines.
			return lines[(range.lowerBound.line - 1)..<range.upperBound.line].joined(separator: "\n")
		}
		// Raw HTML ends with its line break, and the range of a list has the blank line after it.
		.lazy.map { $0.trimmingCharacters(in: .newlines) }
		.joined(separator: "\n\n")
	}
}

extension MarkdownFile {
	/**
	The Markdown with the destinations of its links and images, and the root-relative URLs of its raw HTML, as absolute URLs, as the file is read outside the site. A link to a content file, like `donate.md`, goes to its page.
	*/
	fileprivate func withAbsoluteLinks(_ markdown: String, page: URL, project: Project) -> String {
		let markdown = markdown.replacing(/\]\(([^()\s]+)\)/) { match in
			let destination = (try? resolvingLink(String(match.1), project: project)) ?? String(match.1)
			return "](\(URL(string: destination, relativeTo: page)?.absoluteString ?? destination))"
		}

		// Most files have no root-relative URL in raw HTML, and the word boundary makes the search slow (about 0.1 s for all the files).
		guard markdown.contains(#"="/"#) else {
			return markdown
		}

		// The root-relative URLs of raw HTML, like `<img src="/dato/icon.png">` and `href="/"`, but not `//example.com`, which is another host.
		return markdown.replacing(/\b(src|href)="(\/(?:[^"\/][^"]*)?)"/) { match in
			#"\#(match.1)="\#(URL(string: String(match.2), relativeTo: page)?.absoluteString ?? String(match.2))""#
		}
	}
}

extension MarkdownPage {
	/**
	The Markdown of the page with the sponsors from the frontmatter, where the page shows them.
	*/
	fileprivate var fullMarkdown: String {
		file.body.replacing(Self.sponsorsDirective, with: frontmatter.sponsorTiers.map(\.markdown).joined(separator: "\n\n"))
	}
}

extension MarkdownPage.SponsorTier {
	/**
	The tier as a heading and a list of its sponsors, like on the page.
	*/
	fileprivate var markdown: String {
		let sponsors = sponsors.map { sponsor in
			sponsor.url.map { "- [\(sponsor.name)](\($0.absoluteString))" } ?? "- \(sponsor.name)"
		}

		return "## \(title) \(price)\n\n\(sponsors.joined(separator: "\n"))"
	}
}
