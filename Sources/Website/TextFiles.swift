import Foundation
import Markdown
import SiteKit

/**
The plain files for crawlers, AI assistants, and other tools: `robots.txt`, `humans.txt`, `llms.txt`, `llms-full.txt`, `/apps.json`, WebFinger, and the app site association, and the npm packages and the repos for the buttons of ``ProjectOfTheDay``.
*/
extension Site {
	@RouteBuilder
	var textFileRoutes: [Route] {
		Route.text(#path("/robots.txt")) {
			Self.robots
		}

		Route.text(#path("/humans.txt")) {
			Self.humans
		}

		Route.text(#path("/llms.txt")) {
			llms
		}

		Route.text(Self.llmsFullPath) {
			llmsFull
		}

		Route.file(#path("/apps.json")) {
			try appsJSON()
		}

		Route.file(#path("/.well-known/webfinger")) {
			Self.webFinger()
		}

		if let sharedPuzzlePage = SharedPuzzlePage(apps: content.apps) {
			Route.file(#path("/.well-known/apple-app-site-association")) {
				sharedPuzzlePage.appSiteAssociation
			}
		}

		// Without projects, the about page has no card for them, so its button needs no file.
		for source in ProjectOfTheDay.Source.allCases {
			let projects = source.projects(in: content)

			if !projects.isEmpty {
				Route.file(source.path) {
					ProjectOfTheDay.listJSON(projects)
				}
			}
		}
	}

	private static let llmsFullPath = #path("/llms-full.txt")

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

		// The featured apps first, in the order of `content/site.soml`, as they are the main apps.
		let apps = content.activeAppsWithPages.startingWith(content.featuredApps)

		lines += apps.map { app in
			Self.llmsLink(app.title, url: app.path.absoluteURL, description: "\(app.subtitle). \(content.listing(of: app).llmsFacts)")
		}

		lines += ["", "## Pages", ""]
		lines += content.pages.map { page in
			Self.llmsLink(page.title, url: page.path.absoluteURL, description: page.description)
		}

		lines += swiftPages.map { page in
			Self.llmsLink(page.metadata.title, url: page.path.absoluteURL, description: page.metadata.description)
		}

		lines += ["", "## Blog", ""]
		lines += content.listedPosts.map { post in
			Self.llmsLink(post.title, url: post.absoluteURL, description: post.description)
		}

		lines += ["", "## Guides", ""]
		lines += content.guides.map { guide in
			Self.llmsLink(guide.title, url: guide.path.absoluteURL, description: guide.description)
		}

		lines += ["", "## Optional", "", Self.llmsLink("Everything", url: Self.llmsFullPath.absoluteURL, description: "All the app pages, guides, pages, open-source projects, and blog posts as Markdown, in one file.")]
		return lines.joined(separator: "\n") + "\n"
	}

	/**
	An item of a list of links in `llms.txt`, like `- [Dato](https://sindresorhus.com/dato): Calendar in the menu bar.`, without the colon when there is no description.
	*/
	private static func llmsLink(_ title: String, url: URL, description: String?) -> String {
		"- [\(title)](\(url.absoluteString))\(description.map { ": \($0)" } ?? "")"
	}

	/**
	The indexed pages that are written in Swift, not in Markdown, like the open-source page and the older versions of the apps. The home page is the summary at the top, and the apps, the posts, and the guides have their own sections.
	*/
	private var swiftPages: [any Page] {
		specialPages.filter { $0.path != .root && $0.metadata.isIndexed }
	}

	/**
	All the app pages, guides, pages, open-source projects, and blog posts as Markdown, in one file.
	*/
	private var llmsFull: String {
		let apps = content.activeAppsWithPages.map { app in
			app.exportedMarkdown(body: app.fullMarkdown, introduction: "\(app.subtitle).", project: content.project)
		}

		let guides = content.guides.map { guide in
			guide.exportedMarkdown(body: guide.file.plainMarkdown, project: content.project)
		}

		let pages = content.pages.map { page in
			page.exportedMarkdown(body: page.fullMarkdown, project: content.project)
		}

		// The projects of the open-source page, grouped like on the page.
		let openSource = OpenSourcePage(content: content).plainMarkdown

		let posts = content.listedPosts.filter { !$0.isRedirect }.map { post in
			post.exportedMarkdown(body: post.file.plainMarkdown, project: content.project)
		}

		return (["# \(Self.name)\n\n> \(Self.description)"] + apps + guides + pages + [openSource] + posts).joined(separator: "\n\n---\n\n") + "\n"
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
		let handle = author.fediverseHandle

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

		let profile = handle.profileURL.absoluteString
		let actor = handle.actorURL.absoluteString

		let resource = Resource(
			subject: "acct:\(handle.account)",
			aliases: [profile, actor],
			links: [
				.init(rel: "http://webfinger.net/rel/profile-page", type: "text/html", href: profile),
				.init(rel: "self", type: "application/activity+json", href: actor),
				.init(rel: "http://ostatus.org/schema/1.0/subscribe", template: "\(handle.server.absoluteString)/authorize_interaction?uri={uri}"),
			]
		)

		return Data(JSONEncoder.pageJSON(resource).utf8)
	}
}

extension AppListing {
	/**
	The facts of the app for `llms.txt`, like “Price: Free. Platforms: macOS, iOS. Get it from: App Store. Requires version 26 or later.”, as assistants otherwise quote wrong facts from other sites. An app that is in no store is downloaded from its page. The price is left out when it is unknown, like for a paid app when the App Store did not answer.
	*/
	fileprivate var llmsFacts: String {
		var stores = [
			app.appStoreURL.map { _ in "App Store" },
			app.setappURL.map { _ in "Setapp" },
			app.gumroadURL.map { _ in "Gumroad" },
		]
		.compactMap(\.self)

		if
			stores.isEmpty,
			app.ownDownloadURL != nil
		{
			stores.append("the app page")
		}

		return [
			priceText.map { "Price: \($0)." },
			"Platforms: \(app.operatingSystems).",
			stores.isEmpty ? nil : "Get it from: \(stores.joined(separator: ", ")).",
			requirementSentence.map { "\($0)." },
		]
		.compactMap(\.self)
		.joined(separator: " ")
	}
}

extension App {
	/**
	The Markdown of the page with what the build adds from the facts of the app, like the common and shared questions and the older versions, where the page shows them (``App/Frontmatter/addingGeneratedSections(to:sharedQuestions:page:)``), without the syntax of the site (``Markdown/Document/plainMarkdown(source:)``).
	*/
	fileprivate var fullMarkdown: String {
		frontmatter.addingGeneratedSections(to: Document(parsing: file.body, options: .parseBlockDirectives), sharedQuestions: sharedQuestions, page: path)
			.plainMarkdown(source: file.body)
	}
}

extension Document {
	/**
	The Markdown of the document without the syntax of the site, like block directives, keyboard shortcuts, and heading IDs (``PlainMarkdownRewriter``), as the file is read outside the site. The blocks without it keep their source, and the others, and the blocks that the build added, are formatted.

	Limitation: the parser leaves link reference definitions and footnote definitions out of the blocks, so they are left out, and it gives a setext heading (underlined with `=` or `-`) directly followed by text a range that has the next line, so that line is there twice. The content files have none.

	- Parameter source: The Markdown that the document was parsed from.
	*/
	fileprivate func plainMarkdown(source: String, blockDirective: @escaping (BlockDirective) -> [any BlockMarkup] = { $0.plainBlocks }) -> String {
		let lines = source.split(separator: "\n", omittingEmptySubsequences: false)

		return blockChildren.compactMap { block -> String? in
			var rewriter = PlainMarkdownRewriter(blockDirective: blockDirective)

			// The rewriter changes the children of the document it gets, so a block directive at the top can be several blocks.
			guard let plainBlock = rewriter.visit(Document(block)) else {
				return nil
			}

			guard
				!rewriter.didChange,
				// Raw HTML is formatted as it is written, and the parser ends the range of an HTML comment of several lines a line early.
				!(block is HTMLBlock),
				// The added blocks have no range, or the source of their own file, like the shared questions.
				let range = block.range,
				range.lowerBound.source == nil
			else {
				let markdown = plainBlock.format()
				return markdown.allSatisfy(\.isWhitespace) ? nil : markdown
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
	The Markdown of the file without the syntax of the site (``Markdown/Document/plainMarkdown(source:)``).
	*/
	fileprivate var plainMarkdown: String {
		Document(parsing: body, options: .parseBlockDirectives).plainMarkdown(source: body)
	}

	// Stored, as this runs for each document of `llms-full.txt`.
	// The root-relative URLs of raw HTML, like `<img src="/dato/icon.png">` and `href="/"`, but not `//example.com`, which is another host.
	nonisolated(unsafe) private static let rootRelativeHTMLURL = /\b(src|href)="(\/(?:[^"\/][^"]*)?)"/

	/**
	The Markdown with the destinations of its links and images, and the root-relative URLs of its raw HTML, as absolute URLs, as the file is read outside the site. A link to a content file, like `donate.md`, goes to its page.
	*/
	fileprivate func withAbsoluteLinks(_ markdown: String, page: URL, project: Project) -> String {
		let document = Document(parsing: markdown, options: .parseBlockDirectives)
		let replacements = document.linkReplacements { destination in
			let destination = (try? resolvingLink(destination, project: project)) ?? destination
			return URL(string: destination, relativeTo: page)?.absoluteString ?? destination
		}
		let resolved = markdown.replacingSource(replacements)

		// Most files have no root-relative URL in raw HTML, and the word boundary makes the search slow (about 0.1 s for all the files).
		guard resolved.contains(#"="/"#) else {
			return resolved
		}

		return resolved.replacing(Self.rootRelativeHTMLURL) { match in
			#"\#(match.1)="\#(URL(string: String(match.2), relativeTo: page)?.absoluteString ?? String(match.2))""#
		}
	}
}

extension MarkdownPage {
	/**
	The Markdown of the page with the sponsors from the frontmatter, where the page shows them, without the syntax of the site. The parsed `@Sponsors` directive places its tiers, so code examples remain literal.
	*/
	fileprivate var fullMarkdown: String {
		Document(parsing: file.body, options: .parseBlockDirectives).plainMarkdown(source: file.body, blockDirective: { directive in
			guard directive.siteName == .sponsors else {
				return directive.plainBlocks
			}

			let sponsors = frontmatter.sponsorTiers.map(\.markdown).joined(separator: "\n\n")
			return Array(Document(parsing: sponsors).blockChildren)
		})
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

extension ContentDocument {
	/**
	Frames a document export with its canonical identity, keeping type-specific introductions and bodies at the call site.
	*/
	fileprivate func exportedMarkdown(body: String, introduction: String? = nil, project: Project) -> String {
		let introduction = introduction.map { "\($0)\n\n" } ?? ""
		return "# \(frontmatter.title)\n\n\(introduction)URL: \(absoluteURL.absoluteString)\n\n\(file.withAbsoluteLinks(body, page: absoluteURL, project: project))"
	}
}

extension Markup {
	/**
	The outermost parsed link/image edits. Rewriting a whole subtree handles linked images without overlapping source replacements.
	*/
	fileprivate func linkReplacements(resolving destination: @escaping (String) -> String) -> [Replacement] {
		guard self is Markdown.Link || self is Markdown.Image else {
			return children.flatMap { $0.linkReplacements(resolving: destination) }
		}

		var rewriter = PlainMarkdownRewriter(linkDestination: destination, blockDirective: \.plainBlocks)
		guard
			let range,
			let rewritten = rewriter.visit(self),
			rewriter.didChange
		else {
			return []
		}

		// Formatting an inline replacement must not inherit its surrounding list’s indentation.
		return [Replacement(range: range, replacementText: rewritten.detachedFromParent.format())]
	}
}

extension String {
	/**
	Applies parser-owned UTF-8 ranges from last to first, preserving every byte outside the changed nodes, including authored list numbers.
	*/
	fileprivate func replacingSource(_ replacements: [Replacement]) -> String {
		var bytes = Array(utf8)
		var lineOffsets = [0]

		for (index, byte) in bytes.enumerated() where byte == 10 {
			lineOffsets.append(index + 1)
		}

		for replacement in replacements.reversed() {
			let range = replacement.range
			let lower = lineOffsets[range.lowerBound.line - 1] + range.lowerBound.column - 1
			let upper = lineOffsets[range.upperBound.line - 1] + range.upperBound.column - 1
			bytes.replaceSubrange(lower..<upper, with: replacement.replacementText.utf8)
		}

		return String(decoding: bytes, as: UTF8.self)
	}
}
