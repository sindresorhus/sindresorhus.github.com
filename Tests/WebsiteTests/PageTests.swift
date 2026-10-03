import Foundation
import SiteKit
import Testing
@testable import Website

/**
Renders every page of the site from the real content, without the network: there is no App Store or GitHub data.
*/
@Suite
struct PageTests {
	private static let project = Project(root: URL(filePath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent())

	private static func site() async throws -> Site {
		let appExtras = try JSONDecoder().decode([LinkGroup].self, from: Data(contentsOf: project.root.appending(path: "content/apps-extra.json")))

		let content = try await SiteContent(
			apps: App.load(from: project),
			posts: BlogPost.load(from: project),
			pages: MarkdownPage.load(from: project),
			appExtras: appExtras,
			appStoreInfo: [:],
			releases: [:],
			recentRepositories: [],
			buildDate: Date(timeIntervalSince1970: 1_790_000_000)
		)

		return Site(content: content)
	}

	@Test
	func `every page has one h1, a unique title, and a short description`() async throws {
		let routes = try await Self.site().routes(project: Self.project, includesGallery: true)
		var pathsByTitle = [String: String]()
		var pageCount = 0

		for route in routes {
			guard case .page(_, let render) = route.output else {
				continue
			}

			let html = try render()
			let path = route.path.description
			pageCount += 1

			// The content of a template is not part of the page until a script uses it.
			let document = html.replacing(/<template[\s>].*?<\/template>/.dotMatchesNewlines(), with: "")
			#expect(document.matches(of: /<h1[\s>]/).count == 1, "\(path) must have one <h1>.")

			let title = try #require(html.firstMatch(of: /<title>([^<]*)<\/title>/)?.1, "\(path) has no <title>.")
			#expect(pathsByTitle[String(title)] == nil, "\(path) has the same title as \(pathsByTitle[String(title)] ?? ""): \(title)")
			pathsByTitle[String(title)] = path

			if let description = html.firstMatch(of: /<meta name="description" content="([^"]*)">/)?.1 {
				let text = description.replacing("&amp;", with: "&").replacing("&quot;", with: "\"").replacing("&lt;", with: "<").replacing("&gt;", with: ">")
				#expect(text.count <= 160, "The description of \(path) is longer than 160 characters.")
			}
		}

		#expect(pageCount > 100)
	}

	@Test
	func `the shared stylesheet defines each class once`() {
		// Top-level rules in the layers are indented once.
		let selectors = Stylesheet.site.css.split(separator: "\n").compactMap { line in
			line.wholeMatch(of: /\t(\.[a-z0-9-]+) \{/).map { String($0.1) }
		}

		#expect(!selectors.isEmpty)
		#expect(Dictionary(grouping: selectors, by: \.self).filter { $0.value.count > 1 }.keys.sorted() == [])
	}

	@Test
	func `every feed renders, and redirect items keep their GUIDs`() async throws {
		let site = try await Self.site()
		var feeds = [String: String]()

		for route in site.routes(project: Self.project) where route.path.description.hasSuffix("rss.xml") || route.path.description.hasPrefix("/rss-") {
			guard case .file(let render) = route.output else {
				continue
			}

			feeds[route.path.description] = String(decoding: try await render(), as: UTF8.self)
		}

		#expect(feeds.count >= 3)

		// Feed readers know the items by their GUIDs, so the GUIDs of redirect posts must not change.
		let blogFeed = try #require(feeds["/rss.xml"])
		let redirectPosts = site.content.listedPosts.filter(\.isRedirect)
		#expect(!redirectPosts.isEmpty)

		for post in redirectPosts {
			#expect(blogFeed.contains("<guid isPermaLink=\"false\">https://sindresorhus.com/blog/\(post.slug)</guid>"))
		}
	}
}
