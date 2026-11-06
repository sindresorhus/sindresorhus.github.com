import Elementary
import CoreGraphics
import JavaScriptCore
import Foundation
import SiteKit
import SOML
import Testing
import TestSupport
@testable import Website

struct DomainValueTests {
	@Test(.temporaryDirectory)
	func `project frontmatter formatting orders model keys and preserves values and bodies`() throws {
		let app = """
		---
		redirectFrom: ['/old']
		feedbackNote: 'Keep me'
		pressQuotes: [{source: 'Z', quote: 'First'}, {source: 'A', quote: 'Second'}]
		isPaid: true
		testFlightURL: 'https://testflight.apple.com/join/abc'
		gumroad: {price: 6, id: 'sample'}
		platforms: ['iOS', 'macOS']
		publicationDate: 2026-01-01
		# The app title.
		title: 'Sample'
		isArchived: true
		isDraft: true
		---

		# App body

		Keep  two spaces and `code`.

		"""
		let post = "---\ntags: ['swift', 'programming']\nredirectFrom: ['/old-post']\npublicationDate: 2026-01-02\ntitle: 'Post'\nisUnlisted: true\nisDraft: true\n---\n\nPost body.\n"
		let guide = "---\napps: ['sample']\ntitle: 'Guide'\nscreenshot: {description: 'The result', number: 1}\n---\n\nGuide body.\n"
		let expectedGuide = "---\napps: [\n\t'sample'\n]\ntitle: 'Guide'\nscreenshot: {\n\tdescription: 'The result'\n\tnumber: 1\n}\n---\n\nGuide body.\n"
		let page = "---\nlinks: {Second: 'https://example.com/b', First: 'https://example.com/a'}\ntitle: 'Page'\n---\n\nPage body.\n"
		let expectedPage = "---\nlinks: {\n\tSecond: 'https://example.com/b'\n\tFirst: 'https://example.com/a'\n}\ntitle: 'Page'\n---\n\nPage body.\n"
		let root = try URL.temporaryDirectory(files: [
			"content/apps/sample/index.md": app,
			"content/blog/post.md": post,
			"content/guides/guide.md": guide,
			"content/pages/page.md": page,
			"content/pages/plain.md": "No frontmatter.\n",
			"content/apps/sample/data.txt": "tags: ['unchanged']\n",
		])
		let project = Project.site(root: root)
		let changed = try project.formatFrontmatter()

		#expect(changed.map { $0.path(relativeTo: root) } == ["content/apps/sample/index.md", "content/blog/post.md", "content/guides/guide.md", "content/pages/page.md"])
		for (path, expected) in [
			("content/guides/guide.md", expectedGuide),
			("content/pages/page.md", expectedPage),
			("content/pages/plain.md", "No frontmatter.\n"),
			("content/apps/sample/data.txt", "tags: ['unchanged']\n"),
		] {
			#expect(try String(contentsOf: root.appending(path: path), encoding: .utf8) == expected)
		}

		for (path, original, order) in [
			("content/apps/sample/index.md", app, App.formattingKeys.map(\.stringValue)),
			("content/blog/post.md", post, BlogPost.formattingKeys.map(\.stringValue)),
		] {
			let url = root.appending(path: path)
			let formatted = try String(contentsOf: url, encoding: .utf8)
			let originalDocument = try SOML.Document(parsing: MarkdownFile(contents: original, url: url).frontmatter)
			let formattedDocument = try SOML.Document(parsing: MarkdownFile(contents: formatted, url: url).frontmatter)
			let originalObject = try #require(originalDocument.value.objectValue)
			let formattedObject = try #require(formattedDocument.value.objectValue)

			#expect(formattedDocument.value == originalDocument.value)
			#expect(formattedObject.keys == order.filter { originalObject[$0] != nil })
			#expect(formattedDocument.text + "\n" == formattedDocument.formatted(expandingContainers: true))
			let originalBody = try #require(original.range(of: "\n---\n"))
			let formattedBody = try #require(formatted.range(of: "\n---\n"))
			#expect(formatted[formattedBody.lowerBound...].utf8.elementsEqual(original[originalBody.lowerBound...].utf8))
		}

		let formattedApp = try String(contentsOf: root.appending(path: "content/apps/sample/index.md"), encoding: .utf8)
		let appDocument = try SOML.Document(parsing: MarkdownFile(contents: formattedApp, url: root.appending(path: "content/apps/sample/index.md")).frontmatter)
		#expect(appDocument.value["gumroad"]?.objectValue?.keys == ["price", "id"])
		#expect(appDocument.value["pressQuotes"]?.arrayValue?.compactMap(\.objectValue).map(\.keys) == [["source", "quote"], ["source", "quote"]])
		#expect(formattedApp.contains("# The app title.\ntitle: 'Sample'"))

		let modificationDates = try changed.map { try $0.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate }
		#expect(try project.formatFrontmatter().isEmpty)
		#expect(try changed.map { try $0.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate } == modificationDates)
	}

	@Test(.temporaryDirectory)
	func `project frontmatter formatting reports each invalid file and its source line`() throws {
		let root = try URL.temporaryDirectory(files: [
			"content/apps/broken.md": "---\ntitle: 'Broken'\npublicationDate: 2026-02-30\n---\nBody.\n",
			"content/blog/missing-fence.md": "---\ntitle: 'No closing fence'\n",
		])
		let errors = try #require(throws: ContentErrors.self) {
			try Project.site(root: root).formatFrontmatter()
		}.errors

		#expect(errors.map { $0.file?.path(relativeTo: root) } == ["content/apps/broken.md", "content/blog/missing-fence.md"])
		#expect(errors.first?.line == 3)
	}

	@Test(.temporaryDirectory)
	func `every document kind shares its published mapping`() throws {
		let fixtures = [
			("content/apps/draft-app/index.md", #path("/draft-app")),
			("content/blog/draft-post/index.md", #path("/blog/draft-post")),
			("content/guides/draft-guide.md", #path("/guides/draft-guide")),
			("content/pages/nested/draft-page.md", #path("/nested/draft-page")),
		]
		let root = try URL.temporaryDirectory(files: Dictionary(uniqueKeysWithValues: fixtures.map { ($0.0, "") }))
		let project = Project.site(root: root)

		for (relativePath, path) in fixtures {
			#expect(RoutePath(contentFile: project.root.appending(path: relativePath), project: project) == path)
		}
	}

	@Test
	func `feedback exports preserve the title slug and aliases from their shared app owner`() async throws {
		let app = try await App(title: "System Color Picker", frontmatter: "feedbackNames: ['Color Picker', 'Colour Picker']", slug: "system-color-picker")
		let expected = ["System Color Picker", "system-color-picker", "Color Picker", "Colour Picker"]

		#expect(app.feedbackLookupNames == expected)
		#expect(FeedbackData(listings: [AppListing(app: app)]).apps.first?.names == expected)
	}

	@Test
	func `feedback repository URLs retain their validated type without changing JSON`() async throws {
		struct PlainAppData: Encodable {
			let title: String
			let names: [String]
			let iconURL: RoutePath
			let faqURL: LinkDestination?
			let repositoryURL: URL?
			let olderVersions = [String]()
		}

		let encoder = JSONEncoder()
		encoder.outputFormatting = .sortedKeys

		for frontmatter in ["repositoryURL: 'https://github.com/sindresorhus/test'", ""] {
			let app = try await App(frontmatter: frontmatter)
			let data = try #require(FeedbackData(listings: [AppListing(app: app)]).apps.first)
			let repository: AbsoluteURL? = data.repositoryURL
			let plain = PlainAppData(title: data.title, names: data.names, iconURL: data.iconURL, faqURL: data.faqURL, repositoryURL: repository?.value)

			#expect(repository == app.repositoryURL)
			#expect(try encoder.encode(data) == encoder.encode(plain))
		}
	}

	@Test
	func `project sources pair each daily card with its published collection and labels`() async throws {
		var statistics = NPMStatistics()
		statistics.search = .complete(total: 1, packages: [NPMStatistics.Package(name: "chalk", version: "6", description: "Terminal styling", date: .now, weeklyDownloads: 42, dependentCount: nil, repository: #repository("chalk/chalk"))])
		let repository = try GitHubRepository(json: #"{"name":"awesome","full_name":"sindresorhus/awesome","html_url":"https://github.com/sindresorhus/awesome","description":"Awesome lists","created_at":"2026-01-01T00:00:00Z","archived":false,"fork":false,"stargazers_count":123}"#)
		let account = GitHub.Account(repositoryCount: 1, followerCount: 0, starCount: 123, maintenance: GitHub.Maintenance(closedIssueCount: 0, mergedPullRequestCount: 0), repositories: [repository])
		let content = SiteContent.test(gitHubAccount: account, npmStatistics: statistics)
		let routes = Site(content: content).textFileRoutes

		for source in ProjectOfTheDay.Source.allCases {
			let card = try #require(ProjectOfTheDay(source: source, content: content))
			let route = try #require(routes.first { $0.path == source.path })
			let json = try await route.renderedFile()
			#expect(card.title == source.title)
			#expect(card.randomTitle == source.randomTitle)
			#expect(card.listPath == source.path)
			#expect(card.project.name == source.projects(in: content).first?.name)
			#expect(json == ProjectOfTheDay.listJSON(source.projects(in: content)))
		}

		#expect(ProjectOfTheDay.Source.packages.path == #path("/npm-packages.json"))
		#expect(ProjectOfTheDay.Source.repositories.path == #path("/repos.json"))
	}

	@Test
	func `date text displays its calendar day even with a western format time zone`() throws {
		var format = Date.FormatStyle.dateTime.year().month(.twoDigits).day(.twoDigits).locale(.site)
		format.calendar = .site
		format.timeZone = try #require(TimeZone(secondsFromGMT: -8 * 60 * 60))
		let day = try #require(SOML.Date("2026-02-23"))
		let html = DateText(day: day, format: format).render()

		#expect(html.contains(#"datetime="2026-02-23""#))
		#expect(html.contains("02/23/2026"))
	}

	@Test
	func `code owned dates reject normalization and retain valid leap days`() async {
		#expect(Date(year: 2024, month: 2, day: 29).isoDay == "2024-02-29")
		await #expect(processExitsWith: .failure) {
			_ = Date(year: 2026, month: 2, day: 30)
		}
	}

	@Test(arguments: [".", "..", "../tags", "folder/Test.zip"])
	func `a GitHub download requires a single asset filename at its authored field`(filename: String) async throws {
		let errors = try await #require(throws: ContentErrors.self) {
			try await App(frontmatter: "gitHubDownload: {\n\trepository: 'sindresorhus/test'\n\tfile: '\(filename)'\n}")
		}

		#expect(errors.errors.map(\.line) == [8])
		#expect(errors.errors.first?.reason == "Invalid `gitHubDownload.file`: Must be one release asset filename, without slashes or dot segments.")
	}

	@Test
	func `GitHub download filenames preserve spaces and Unicode`() async throws {
		let app = try await App(frontmatter: "gitHubDownload: {repository: 'sindresorhus/test', file: 'Test Édition.zip'}")
		#expect(app.gitHubDownload?.url.absoluteString == "https://github.com/sindresorhus/test/releases/latest/download/Test%20%C3%89dition.zip")
	}

	@Test(arguments: [-1.0, 0, 5.1])
	func `invalid star averages are omitted without losing the store price`(average: Double) throws {
		let info = try AppStoreInfo(json: #"{"trackId": 123, "price": 4.99, "currency": "USD", "averageUserRating": \#(average), "userRatingCount": 10}"#)
		#expect(info.rating == nil)
		#expect(info.price?.formatted == "$4.99")

		let product = try GumroadProduct(json: #"{"price_cents": 499, "ratings": {"average": \#(average), "count": 10}}"#)
		#expect(product.rating == nil)
		#expect(product.price?.formatted == "$4.99")
	}

	@Test(arguments: [-1.0, 101, 1e100])
	func `invalid Setapp percentages fail without an integer conversion trap`(percentage: Double) {
		let html = Data(#"<script type="application/ld+json">{"aggregateRating": {"ratingValue": \#(percentage), "bestRating": 100, "ratingCount": 10}}</script>"#.utf8)
		#expect(throws: ResponseCache.ReadError.self) {
			try SetappRating(html: html)
		}
	}

	@Test
	func `rating constructors validate their own scales and counts`() throws {
		for average in [Double.nan, .infinity, -1, 0, 5.1] {
			#expect(StoreRating(average: average, count: 1, store: .appStore) == nil)
		}
		#expect(StoreRating(average: 4.8, count: 0, store: .gumroad) == nil)
		#expect(StoreRating(average: 4.8, count: -1, store: .gumroad) == nil)
		let rating = try #require(StoreRating(average: 4.8, count: 26, store: .gumroad))
		#expect(Schema.AggregateRating(rating: .store(rating)).ratingValue == 4.8)
		#expect(Schema.AggregateRating(rating: .store(rating)).ratingCount == 26)
		#expect(StoreRating(average: 1, count: 1, store: .appStore) != nil)
		#expect(StoreRating(average: 5, count: 1, store: .appStore) != nil)

		#expect(SetappRating(ratingValue: 0, bestRating: 100, count: 1)?.percentPositive == 0)
		#expect(SetappRating(ratingValue: 99.6, bestRating: 100, count: 1)?.percentPositive == 100)
		#expect(SetappRating(ratingValue: 100, bestRating: 100, count: 1)?.percentPositive == 100)
		#expect(SetappRating(ratingValue: .nan, bestRating: 100, count: 1) == nil)
		#expect(SetappRating(ratingValue: .infinity, bestRating: 100, count: 1) == nil)
		#expect(SetappRating(ratingValue: 99, bestRating: 100, count: 0) == nil)
		#expect(SetappRating(ratingValue: 99, bestRating: 5, count: 1) == nil)
	}

	@Test
	func `store identifiers validate every direct and decoding construction path`() throws {
		for invalid in [0, -1] {
			#expect(throws: ContentError.self) {
				try AppStoreID(validating: invalid)
			}
			#expect(throws: ContentError.self) {
				try SetappID(validating: invalid)
			}
			#expect(throws: DecodingError.self) {
				try JSONDecoder().decode(AppStoreID.self, from: JSONEncoder().encode(invalid))
			}
			#expect(throws: DecodingError.self) {
				try JSONDecoder().decode(SetappID.self, from: JSONEncoder().encode(invalid))
			}
		}

		let identifier = try AppStoreID(validating: 123)
		#expect(String(decoding: try JSONEncoder().encode(identifier), as: UTF8.self) == "123")
		#expect(identifier.url.absoluteString == "https://apps.apple.com/app/id123")
		#expect(try SetappID(validating: 571).pageURL.absoluteString == "https://setapp.com/apps/571")
	}

	@Test
	func `code owned store identifiers and OS versions reject invalid programmer input`() async {
		await #expect(processExitsWith: .failure) {
			_ = AppStoreID(-1)
		}
		await #expect(processExitsWith: .failure) {
			let _: AppStoreID = 0
		}
		await #expect(processExitsWith: .failure) {
			_ = OSVersion(major: -1)
		}
		await #expect(processExitsWith: .failure) {
			_ = OSVersion(major: 26, minor: -1)
		}
	}

	@Test
	func `prices accept imported zero and currency precision while rejecting invalid amounts`() throws {
		#expect(try Price(amount: 0) == .free)
		let amount = Decimal(1234) / 1000
		#expect(try Price(amount: amount, currency: "KWD").amount == amount)
		for invalid in [Decimal(-1), .nan] {
			#expect(throws: ContentError.self) {
				try Price(amount: invalid)
			}
		}
		for invalid in [0.0, -1, 1.234, .nan, .infinity] {
			#expect(throws: ContentError.self) {
				try Price(validating: invalid)
			}
		}
		let info = try AppStoreInfo(json: #"{"trackId": 123, "price": -1, "currency": "USD", "version": "1.2"}"#)
		#expect(info.price == nil)
		#expect(info.version == "1.2")
		#expect(try GumroadProduct(json: #"{"price_cents": -1}"#).price == nil)
	}

	@Test(arguments: ["26", "26.1", "26.1.2", "invalid"])
	func `store OS versions are decoded once without losing other optional data`(text: String) throws {
		let info = try AppStoreInfo(json: #"{"trackId": 123, "minimumOsVersion": "\#(text)", "price": 0, "currency": "USD"}"#)
		#expect(info.minimumOSVersion == OSVersion(text))
		#expect(info.price == .free)
		#expect(OSVersion("26.1.2") == OSVersion(major: 26, minor: 1))
		#expect(OSVersion("0") == OSVersion(major: 0))
	}

	@Test(arguments: ["", #", "minimumOsVersion": null"#])
	func `a missing or null store OS version keeps the other store data`(extra: String) throws {
		let info = try AppStoreInfo(json: #"{"trackId": 123, "version": "1.2", "price": 4.99, "currency": "USD"\#(extra)}"#)

		#expect(info.minimumOSVersion == nil)
		#expect(info.version == "1.2")
		#expect(info.price?.formatted == "$4.99")
	}

	@Test
	func `a malformed optional store version does not discard the app`() throws {
		let info = try AppStoreInfo(json: #"{"trackId": 123, "minimumOsVersion": 26, "version": "1.2"}"#)
		#expect(info.minimumOSVersion == nil)
		#expect(info.version == "1.2")
	}

	@Test
	func `download options derive their store URL from their identifier and placement`() throws {
		let identifier = try AppStoreID(validating: 123)
		let appStore = DownloadOption.appStore(identifier, placement: .downloadButton)
		#expect(appStore.url == .url(identifier.url(placement: .downloadButton)))
		let setapp = try SetappID(validating: 571)
		#expect(DownloadOption.setapp(setapp).url == .url(setapp.referralURL))
	}

	@Test
	func `a guide page resolves its primary app independently of the content order`() async throws {
		let guide = try await Guide(markdown: Guide.testMarkdown(), slug: "how-to-test")
		let app = try await App()
		let other = try await App(title: "Other", slug: "other")
		let content = SiteContent.test(apps: [other, app], guides: [guide], resolvedGuides: [try #require(Guide.Resolved(guide: guide, apps: [app]))])
		#expect(GuidePage(guide: try #require(content.resolvedGuides.first), content: content).feedbackApp?.slug == app.slug)
	}

	@Test(arguments: [
		#"{"trackId":123,"price":4.99,"version":"1.2","fileSizeBytes":"19244046"}"#,
		#"{"trackId":123,"currency":"USD","version":"1.2","fileSizeBytes":"19244046"}"#,
	])
	func `incomplete price pairs do not discard other normalized store values`(json: String) throws {
		let info = try AppStoreInfo(json: json)
		#expect(info.price == nil)
		#expect(info.version == "1.2")
		#expect(info.fileSize == 19_244_046)
	}

	@Test
	func `invalid file size text does not discard normalized ratings or prices`() throws {
		let info = try AppStoreInfo(json: #"{"trackId":123,"price":4.99,"currency":"USD","averageUserRating":4.65,"userRatingCount":25,"fileSizeBytes":"invalid"}"#)
		#expect(info.fileSize == nil)
		#expect(info.price?.formatted == "$4.99")
		#expect(info.rating?.average == 4.65)
		#expect(info.rating?.count == 25)
	}

	@Test
	func `publication days remain typed and sort chronologically`() async throws {
		let later = try await App(publicationDate: "2026-01-02", slug: "later")
		let earlier = try await App(publicationDate: "2026-01-01", slug: "earlier")
		let publicationDay: SOML.Date = earlier.publicationDate
		#expect(publicationDay == SOML.Date(Date(year: 2026, month: 1, day: 1)))
		#expect(publicationDay < later.publicationDate)
		#expect([earlier, later].sorted(using: App.sortOrder).map(\.slug) == ["later", "earlier"])
		#expect(String(decoding: try JSONEncoder().encode(publicationDay), as: UTF8.self) == #""2026-01-01""#)
	}

	@Test
	func `published documents accept native SOML dates`() async throws {
		let app = try await App(publicationDate: "2024-02-29")
		let post = try await BlogPost(markdown: "---\ntitle: 'Test'\npublicationDate: 2024-02-29\n---\n\nText.")
		let guide = try await Guide(markdown: "---\ntitle: 'Test'\ndescription: 'A guide.'\npublicationDate: 2024-02-29\ntopic: 'mac'\napps: ['test']\n---\n\n\(Guide.testBody)")
		let expected = try #require(SOML.Date("2024-02-29"))

		#expect(app.publicationDate == expected)
		#expect(post.publicationDate == expected)
		#expect(guide.publicationDate == expected)
	}

	@Test(arguments: ["'2026-01-01'", "\"2026-01-01\"", "2026-01-01T00:00:00Z", "'2026-01-01T00:00:00Z'"])
	func `published documents reject strings and instants at the publication date line`(value: String) async throws {
		let appErrors = try await #require(throws: ContentErrors.self) {
			try await App(publicationDate: value)
		}
		let postErrors = try await #require(throws: ContentErrors.self) {
			try await BlogPost(markdown: "---\ntitle: 'Test'\npublicationDate: \(value)\n---\n\nText.")
		}
		let guideErrors = try await #require(throws: ContentErrors.self) {
			try await Guide(markdown: "---\ntitle: 'Test'\ndescription: 'A guide.'\npublicationDate: \(value)\ntopic: 'mac'\napps: ['test']\n---\n\n\(Guide.testBody)")
		}

		for (errors, line) in [(appErrors, 4), (postErrors, 3), (guideErrors, 4)] {
			#expect(errors.errors.map(\.line?.rawValue) == [line])
			#expect(errors.errors.first?.reason.contains("publicationDate") == true)
		}
	}

	@Test
	func `platform membership is unique while presentation keeps canonical order`() async throws {
		let app = try await App(platforms: [.iOS, .macOS, .iOS])
		let platforms: Set<Platform> = app.frontmatter.platforms
		#expect(platforms == [.macOS, .iOS])
		#expect(app.platforms == [.macOS, .iOS])
		#expect(app.operatingSystems == "macOS, iOS")
	}

	@Test
	func `star components preserve validated values and rounded average labels`() throws {
		let average = try #require(StoreRating(average: 4.64999, count: 10, store: .appStore))
		let html = StarRating(average: average).render()
		#expect(html.contains(#"aria-label="4.6 out of 5 stars""#))
		#expect(!html.contains("4.64999"))
		#expect(StarRating(stars: .five).render().contains(#"aria-label="5 out of 5 stars""#))
		#expect(!StarRating(stars: .five, isDecorative: true).render().contains("aria-label"))
	}

	@Test(arguments: [
		"https://example.com/join/abc",
		"http://testflight.apple.com/join/abc",
		"https://testflight.apple.com/app/abc",
		"https://testflight.apple.com/join",
	])
	func `TestFlight invitations validate direct and decoding construction`(text: String) throws {
		#expect(throws: ContentError.self) {
			try TestFlightInvitation(validating: #require(URL(string: text)))
		}
		#expect(throws: DecodingError.self) {
			try JSONDecoder().decode(TestFlightInvitation.self, from: JSONEncoder().encode(text))
		}
	}

	@Test
	func `TestFlight values retain the authored key and locate malformed invitations`() async throws {
		let url = #URL("https://testflight.apple.com/join/abc")
		let app = try await App(frontmatter: "testFlightURL: '\(url)'", body: "")
		#expect(app.frontmatter.testFlight?.url == url)
		#expect(app.links.contains { $0.title == "TestFlight" && $0.destination == .url(url) })
		let errors = try await #require(throws: ContentErrors.self) {
			try await App(frontmatter: "testFlightURL: 'https://example.com/join/abc'")
		}
		#expect(errors.errors.count == 1)
		#expect(errors.errors.first?.line == 6)
		#expect(errors.errors.first?.reason.contains("Invalid `testFlightURL`") == true)
	}

	@Test
	func `resolved guides require every app and the requested screenshot`() async throws {
		let guide = try await Guide(markdown: Guide.testMarkdown(apps: "['test', 'other']"), slug: "how-to-test")
		let app = try await App()
		#expect(Guide.Resolved(guide: guide, apps: [app]) == nil)
		let other = try await App(title: "Other", slug: "other")
		let resolved = try #require(Guide.Resolved(guide: guide, apps: [app, other]))
		#expect(resolved.app.slug == "test")
		#expect(resolved.apps.map(\.slug) == ["test", "other"])
		#expect(resolved.screenshot == nil)

		let screenshotGuide = try await Guide(markdown: Guide.testMarkdown(frontmatter: "screenshot: {number: 1, description: 'The result'}"), slug: "how-to-test")
		#expect(Guide.Resolved(guide: screenshotGuide, apps: [app]) == nil)

		// The number counts from 1, so the second screenshot is not the first, like for several guides.
		let randomNumber = try #require(try await SiteContent.website.resolvedGuides.first { $0.guide.slug == "random-number-iphone" })
		#expect(randomNumber.screenshot?.asset.path == #path("/randa/screenshot2.jpg"))
	}

	@Test(arguments: ["", "Test App", "UPPERCASE", "path/id", "é"])
	func `the Gumroad identifiers use the same validation for direct and decoded values`(text: String) throws {
		#expect(throws: ContentError.self) {
			try GumroadProductID(validating: text)
		}
		#expect(throws: DecodingError.self) {
			try JSONDecoder().decode(GumroadProductID.self, from: JSONEncoder().encode(text))
		}
	}

	@Test
	func `valid Gumroad identifiers retain their spelling and product URL`() throws {
		let identifier = try GumroadProductID(validating: "test-app2")
		let decoded = try JSONDecoder().decode(GumroadProductID.self, from: Data(#""test-app2""#.utf8))

		#expect(decoded == identifier)
		#expect(identifier.url.absoluteString == "https://sindresorhus.gumroad.com/l/test-app2")
	}

	@Test
	func `invalid Gumroad identifiers retain the frontmatter key and line`() async throws {
		let errors = try await #require(throws: ContentErrors.self) {
			try await App(frontmatter: "gumroad: {id: 'Test App', price: 6}")
		}

		#expect(errors.errors.first?.line == 6)
		#expect(errors.errors.first?.reason.contains("gumroad.id") == true)
		#expect(errors.errors.first?.reason.contains("A Gumroad product ID is the ID in the link") == true)
	}

	@Test
	func `a form field wires its root control and keeps accessory descriptions separate`() throws {
		let html = FormField(label: "Email", controlID: ElementID("email"), hint: "A hint", errorMessage: "An error", additionalDescriptionIDs: [ElementID("email-warning")]) {
			input(.type(.email))
		} accessory: {
			p(.id("email-warning")) {
				"A warning"
			}
		}
		.render()
		let control = try #require(html.firstMatch(of: /<input[^>]*>/)).output

		#expect(control.contains(#"id="email""#))
		#expect(control.contains(#"aria-describedby="email-hint email-error email-warning""#))
		#expect(html.contains(#"for="email""#))
		#expect(html.contains(#"id="email-hint""#))
		#expect(html.contains(#"id="email-error""#))
		#expect(html.contains(#"<p id="email-warning">A warning</p>"#))
	}

	@Test
	func `a form field does not refer to descriptions that were not supplied`() throws {
		let html = FormField(label: "Message", controlID: ElementID("message")) {
			textarea {
			}
		}
		.render()
		let control = try #require(html.firstMatch(of: /<textarea[^>]*>/)).output

		#expect(control.contains(#"id="message""#))
		#expect(!control.contains("aria-describedby"))
	}

	@Test
	func `the feedback page preserves field accessories and preconnects to the form origin`() throws {
		let html = try FeedbackPage(apps: [], faq: nil, project: .empty).renderedHTML()
		let email = try #require(html.firstMatch(of: /<input[^>]*name="email"[^>]*>/)).output
		let message = try #require(html.firstMatch(of: /<textarea[^>]*name="message"[^>]*>/)).output

		#expect(html.contains(#"<link rel="preconnect" href="https://formcarry.com">"#))
		#expect(email.contains(#"aria-describedby="email-hint email-error email-warning""#))
		#expect(message.contains(#"aria-describedby="message-error""#))
		#expect(html.contains(#"id="email-warning" role="status""#))
		#expect(html.contains("</textarea><faq-suggestions"))
	}
	@Test(arguments: [Double.leastNonzeroMagnitude, 0.01, 1, Double.greatestFiniteMagnitude])
	func `running statistics retain positive finite rates without integer conversion`(rate: Double) {
		let stat = Stat(perSecond: rate, label: "downloads")
		#expect(stat.hasValue)
		guard case .running(let storedRate) = stat.value else {
			Issue.record("A running statistic must keep its rate.")
			return
		}
		#expect(storedRate == rate)
	}

	@Test(arguments: [0.0, -1, Double.nan, Double.infinity])
	func `running statistics omit nonpositive or nonfinite rates`(rate: Double) {
		#expect(!Stat(perSecond: rate, label: "downloads").hasValue)
		#expect(!Stat(count: 0, noun: "download").hasValue)
		#expect(Stat(count: 1, noun: "download").hasValue)
	}

	@Test
	func `graphics state is restored on normal and throwing exits`() throws {
		enum Failure: Error {
			case expected
		}

		let context = try #require(CGContext(data: nil, width: 8, height: 8, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
		let initial = context.ctm
		let result = context.withSavedState {
			context.translateBy(x: 2, y: 3)
			return 42
		}
		#expect(result == 42)
		#expect(context.ctm == initial)
		#expect(throws: Failure.self) {
			try context.withSavedState {
				context.scaleBy(x: 2, y: 4)
				throw Failure.expected
			}
		}
		#expect(context.ctm == initial)
	}

	@Test
	func `script hook selectors escape quoted values and support presence selectors`() {
		enum Hooks: String, ScriptDataAttributeSet {
			case theme
		}
		#expect(Hooks.theme.selector(value: "a\"b\\c").description == #"[data-theme="a\"b\\c"]"#)
		#expect(Hooks.theme.selector().description == "[data-theme]")
	}

	@Test
	func `item headings retain their concrete level and translation attributes`() {
		let second = ItemHeadingLevel.h2.heading(style: AppCard.Styles.title, isNotTranslated: true) {
			"Title"
		}.render()
		let third = ItemHeadingLevel.h3.heading(style: ArticleRow.Styles.title) {
			"Title"
		}.render()
		#expect(second.hasPrefix("<h2"))
		#expect(second.contains(#"translate="no""#))
		#expect(second.contains(AppCard.Styles.title.className))
		#expect(third.hasPrefix("<h3"))
		#expect(!third.contains("translate="))
		#expect(third.contains(ArticleRow.Styles.title.className))
	}

	@Test
	func `labeled links and dialog popovers retain their paired attributes`() {
		let link = LabeledLink("A title", path: #path("/about"))
		#expect(Link(link).render() == Link(link.title, destination: link.destination).render())
		let dialog = div {}.dialogPopover(id: ElementID("dialog"), labelledBy: ElementID("caption")).render()
		#expect(dialog.contains(#"id="dialog""#))
		#expect(dialog.contains(#"role="dialog""#))
		#expect(dialog.contains(#"aria-labelledby="caption""#))
		#expect(dialog.contains(#"tabindex="-1""#))
		#expect(dialog.contains("popover"))
	}

	@Test
	func `toy and canvas dimensions retain their validated width and height`() throws {
		let size = try #require(PixelSize(width: 80, height: 120))
		let html = canvas {}.bitmapSize(size).render()
		#expect(html.contains(#"width="80""#))
		#expect(html.contains(#"height="120""#))
		#expect(GeoCitiesEffectToys.toys.first?.size == size)
	}

	@Test
	func `Windows launchers use catalog identities while preserving contextual names`() {
		let program = GeoCitiesWindows.Program.calculator
		let html = GeoCitiesWindows.window(program) {
			"Content"
		}.render()
		#expect(html.contains(#"data-desktop-window="calc""#))
		#expect(html.contains(#"id="geocities-window-calc""#))
		#expect(html.contains(program.title))
		let items = GeoCitiesWindows.startMenuItems.render()
		#expect(items.contains(#"data-desktop-open="calc""#))
		#expect(items.contains("Calculator"))
		#expect(GeoCitiesWindows.DesktopItem(program: .wordPad, title: "LETTER TO SANTA 2000.DOC").title == "LETTER TO SANTA 2000.DOC")
	}

	@Test
	func `Taipei quarter cells keep their amounts and formulas together`() throws {
		let html = GeoCitiesWindowsTaipei().render()
		let cells = Dictionary(uniqueKeysWithValues: html.matches(of: /<td[^>]*data-taipei-cell="([^"]+)"([^>]*)>([^<]*)<\/td>/).map {
			(String($0.1), (attributes: String($0.2), value: String($0.3)))
		})

		for (name, value) in ["B4": "450", "C4": "2 870", "D4": "610", "E4": "3 930", "D6": "378", "D11": "50", "B12": "14 059", "C12": "16 469", "D12": "15 468", "E12": "45 996"] {
			#expect(try #require(cells[name]).value == value, "\(name) must keep its authored amount or computed total.")
		}

		#expect(try #require(cells["C4"]).attributes.contains(#"data-taipei-formula="=450+2420""#))
		#expect(try #require(cells["D6"]).attributes.contains(#"data-taipei-formula="=189*2""#))
		#expect(try #require(cells["D11"]).attributes.contains(#"data-taipei-formula="=100-50""#))
		#expect(try #require(cells["E4"]).attributes.contains(#"data-taipei-formula="=SUM(B4:D4)""#))
		#expect(html.contains("Januar"))
		#expect(html.contains("Februar"))
		#expect(html.contains("Mars"))
	}

	@Test
	func `overflow options serialize popover intent independently of fragment navigation`() {
		let menu = OverflowMenu(label: "Actions", items: [.link(LabeledLink("Navigate", destination: .fragment(ElementID("target")))), .popover(title: "Open", id: ElementID("target"))]).render()
		#expect(menu.contains(##"<option value="#target">Navigate</option>"##))
		#expect(menu.contains(##"<option value="#target" data-menu-popover="">Open</option>"##))
	}

	@Test
	func `overflow scripts navigate ordinary fragments and open only explicit popover actions`() throws {
		let source = try String(contentsOf: Project.website.root.appending(path: "Sources/Website/Components/Scripts/OverflowMenu.js"), encoding: .utf8)
		let context = try #require(JSContext())
		context.evaluateScript("""
		var location = {href: ''};
		var opened = 0;
		var focused = 0;
		var navigator = {};
		function elementForFragment(hash) {
			return document.getElementById(hash.slice(1));
		}
		var document = {
			getElementById() {
				return {
					popover: 'auto',
					showPopover() {
						opened++;
					},
					focus() {
						focused++;
					}
				};
			}
		};
		class HTMLElement {
			querySelector() {
				return undefined;
			}
			addEventListener(name, listener) {
				this.listener = listener;
			}
		}
		var customElements = {
			define(name, constructor) {
				globalThis.Element = constructor;
			}
		};
		""")
		// The first line imports the shared helpers of `dom.js`, which a plain script cannot load, so the context above has a stand-in for `elementForFragment`. The tested paths do not call the others.
		context.evaluateScript(source.split(separator: "\n").dropFirst().joined(separator: "\n"))
		context.evaluateScript("""
		const element = new Element();
		element.connectedCallback();
		const option = {
			dataset: {},
			hasAttribute() {
				return false;
			}
		};
		const menu = {value: '#target', selectedOptions: [option]};
		element.listener({target: menu});
		""")
		#expect(context.exception == nil)
		#expect(context.objectForKeyedSubscript("location").forProperty("href").toString() == "#target")
		#expect(context.objectForKeyedSubscript("opened").toInt32() == 0)
		context.evaluateScript("""
		option.hasAttribute = () => true;
		menu.value = '#target';
		element.listener({target: menu});
		""")
		#expect(context.exception == nil)
		#expect(context.objectForKeyedSubscript("opened").toInt32() == 1)
		#expect(context.objectForKeyedSubscript("focused").toInt32() == 1)
	}

	@Test
	func `published article projections share the same modification day`() async throws {
		let post = try await BlogPost(markdown: "---\ntitle: 'Article'\npublicationDate: 2026-01-01\n---\nBody", slug: "article")
		let metadata = PageMetadata(article: post, title: post.title, description: post.description)
		let schema = Schema.Article(document: post, type: .blogPosting, title: post.title, description: post.description, images: [])
		guard case .article(let published, let modified, _) = metadata.kind else {
			Issue.record("An article must carry its publication dates.")
			return
		}
		#expect(published == post.publicationDate)
		#expect(modified == post.lastModified)
		#expect(schema.datePublished == published)
		#expect(schema.dateModified == modified)
		#expect(schema.url == post.path.absoluteURL)
		let json = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(schema)) as? [String: Any])
		#expect(json["datePublished"] as? String == "2026-01-01")
		#expect(json["dateModified"] as? String == "2026-01-01")
	}

	@Test(arguments: [
		(nil, "2026-01-02"),
		("2026-01-01T23:59:59Z", "2026-01-02"),
		("2026-01-02T23:59:59Z", "2026-01-02"),
		("2026-01-03T00:30:00+02:00", "2026-01-02"),
		("2026-01-03T00:30:00Z", "2026-01-03"),
	])
	func `modification dates stay native and never precede publication`(commit: String?, expected: String) throws {
		var file = try MarkdownFile(contents: "---\ntitle: 'Article'\npublicationDate: 2026-01-02\n---\nBody", url: URL(filePath: "/content/blog/article.md"))
		file.lastCommitDate = try commit.map { try Date($0, strategy: .iso8601) }
		let post = try BlogPost(file: file.decoded(), project: .empty)
		let day: SOML.Date = post.lastModified

		#expect(day.description == expected)
		#expect([post].listSitemapEntry.lastModified == day)
	}

	@Test
	func `app prose titles and optional back links use the same app`() async throws {
		let app = try await App(title: "Sample App")
		let linked = ProsePage(app: app, title: "Privacy Policy") {
			"Body"
		}.render()
		let unlinked = ProsePage(app: app, title: "Privacy Policy", linksBack: false) {
			"Body"
		}.render()
		#expect(linked.contains("Back to Sample App"))
		#expect(!unlinked.contains("Back to"))
		#expect(linked.contains("Privacy Policy"))
		#expect(unlinked.contains("Privacy Policy"))
	}

	@Test
	func `app links that share a title with a footer link name the app for screen readers`() async throws {
		let app = try await App(title: "Sample App")
		let privacyPolicy = try #require(app.pageOverflowLinks.first { $0.title == "Privacy Policy" })
		#expect(privacyPolicy.accessibilityLabel == "Privacy Policy of Sample App")
		#expect(Link(privacyPolicy).render().contains(#"aria-label="Privacy Policy of Sample App""#))
		#expect(app.pageOverflowLinks.first { $0.title == "Terms of Use" }?.accessibilityLabel == nil)
	}

	@Test
	func `wall entries keep the required app in their filter and title data`() async throws {
		let app = try await App(title: "Sample App", frontmatter: "pressQuotes: [{quote: 'Great', source: 'Example'}]", slug: "sample")
		let content = SiteContent.test(apps: [app], buildDate: Date(timeIntervalSince1970: 1767225600))
		let html = ReviewsPage(content: content).body.render()
		#expect(html.contains(#"data-app="sample""#))
		#expect(html.contains(#""sample":{"title":"Sample App","url":"/sample"}"#))
		#expect(!html.contains(#"data-app="""#))
	}

}

extension DomainValueTests {
	@Test
	func `frontmatter declaration order preserves the editorial wire key order`() {
		#expect(App.formattingKeys.map(\.stringValue) == [
			"isDraft", "isUnlisted", "isArchived", "title", "subtitle", "description", "publicationDate", "platforms", "minimumOSVersion", "isPaid", "isMenuBarApp", "appStoreID", "setappID", "gumroad", "gitHubDownload", "testFlightURL", "repositoryURL", "releasesRepository", "downloadCount", "hasSentry", "script", "categories", "links", "overflowLinks", "redirectURL", "redirectFrom", "feedbackNames", "nonAppStoreVersion", "trial", "announcement", "sharedQuestions", "olderVersions", "pressQuotes", "privacyNote", "feedbackNote",
		])
		#expect(BlogPost.formattingKeys.map(\.stringValue) == ["isDraft", "isUnlisted", "title", "description", "publicationDate", "tags", "redirectURL", "redirectFrom"])
		#expect(Guide.formattingKeys.isEmpty)
		#expect(MarkdownPage.formattingKeys.isEmpty)
	}

	@Test
	func `content section traversal includes deeper headings and stops at a peer`() {
		let levels: [HeadingLevel?] = [.h2, nil, .h3, nil, .h2, nil, .h1]
		#expect(Array(levels.contentOfSection(afterHeadingAt: 0, level: .h2) { $0 }) == [nil, .h3, nil])
		#expect(Array(levels.contentOfSection(afterHeadingAt: 2, level: .h3) { $0 }) == [nil])
		#expect(levels.contentOfSection(afterHeadingAt: 6, level: .h1) { $0 }.isEmpty)
	}

	@Test
	func `feedback lookup normalization matches the browser for Unicode names`() throws {
		let context = try #require(JSContext())
		for name in ["Color Picker", "ÉCRITURE", "İMAGO", "Σίσυφος"] {
			let expected = try #require(context.evaluateScript("\(JSONEncoder.pageJSON(name)).toLowerCase()")?.toString())
			#expect(name.feedbackLookupKey == expected)
		}
	}

	@Test
	func `document diagnostics keep renamed key locations`() async throws {
		let app = try await App(frontmatter: "testFlightURL: 'https://testflight.apple.com/join/test'")
		let warning = app.warning(.unknownAppStoreID, at: .testFlight, "Check this.")
		let error = app.error(at: .testFlight, "Check this.")
		#expect(warning.location == error.location)
		#expect(error.line == app.file.line(of: App.Frontmatter.CodingKeys.testFlight))
		#expect(error.file == app.file.url)
	}

	@Test(.temporaryDirectory)
	func `path collisions are checked when the apps directory is unavailable`() async throws {
		let project = Project.site(root: try URL.temporaryDirectory(files: [
			"content/blog/same.md": "---\ntitle: 'Post'\npublicationDate: 2020-01-01\n---\n\nText.\n",
			"content/pages/blog/same.md": "---\ntitle: 'Page'\n---\n\nText.\n",
			SiteSettings.path: SiteSettings.testSOML,
		]))
		try Guide.directory.fileURL(in: project.root).createDirectory()
		let errors = try await #require(throws: ContentErrors.self) {
			try await SiteContent.load(from: project, externalData: .none)
		}
		#expect(errors.errors.contains { $0.reason.contains("same page") && $0.reason.contains("/blog/same") })
		#expect(errors.errors.contains { $0.file?.lastPathComponent == "apps" })
	}

	@Test
	func `shared question IDs decode at their authored list item`() async throws {
		let file = try MarkdownFile(contents: App.testMarkdown(frontmatter: "sharedQuestions: [\n\t'bad id'\n]"), url: URL(filePath: "/content/apps/test.md"))
		let errors = try #require(throws: ContentErrors.self) {
			try file.decodeFrontmatter(as: App.Frontmatter.self)
		}
		#expect(errors.errors.first?.line == 7)
		#expect(errors.errors.first?.reason.contains("sharedQuestions[0]") == true)
	}

	@Test
	func `an icon placeholder has no source-only derivatives`() async throws {
		let app = try await App()
		#expect(app.hasPlaceholderIcon)
		#expect(app.iconPath == App.placeholderIconPath)
		#expect(app.iconEnclosure == nil)
		#expect(app.iconJPEGXL == nil)
		#expect(app.tint == nil)
	}

	@Test
	func `release note identity derives both routes from the app`() {
		let notes = App.ReleaseNotes(repository: #repository("sindresorhus/test-meta"), appPath: #path("/test"), title: "Test")
		#expect(notes.path == #path("/test/release-notes"))
		#expect(notes.feed.path == #path("/test/rss.xml"))
		#expect(notes.feed.title == "Test Release Notes")
	}
}

extension DomainValueTests {
	@Test
	func `Markdown export rewrites parsed destinations without reformatting surrounding content`() async throws {
		let app = try await App(body: """
		1. Open [the apps](/apps).
		2. Keep this authored number.
		3. Keep this one too.

		Écrit [![Preview](/image(1).png)](/apps).

		`[Example](/apps)`

		```
		[Code](/apps)
		```
		""")
		let content = SiteContent.test(apps: [app])
		let route = try #require(Site(content: content).textFileRoutes.first { $0.path == #path("/llms-full.txt") })
		let markdown = String(decoding: try await route.renderedFile(), as: UTF8.self)
		#expect(markdown.contains("1. Open [the apps](https://sindresorhus.com/apps).\n2. Keep this authored number.\n3. Keep this one too."))
		#expect(markdown.contains("Écrit [![Preview](https://sindresorhus.com/image(1).png)](https://sindresorhus.com/apps)."))
		#expect(markdown.contains("`[Example](/apps)`"))
		#expect(markdown.contains("[Code](/apps)"))
	}

	@Test
	func `Markdown export rewrites HTML links while preserving HTML code examples`() async throws {
		let app = try await App(body: """
		```xml
		<a href="/apps">Apps</a>
		```

		`<a href="/apps">Apps</a>`

		<a href="/apps">Apps</a>

		<div>
		<a href="/about">About</a>
		</div>
		""")
		let route = try #require(Site(content: .test(apps: [app])).textFileRoutes.first { $0.path == #path("/test.md") })
		let markdown = String(decoding: try await route.renderedFile(), as: UTF8.self)

		#expect(markdown.contains("```xml\n<a href=\"/apps\">Apps</a>\n```"))
		#expect(markdown.contains("`<a href=\"/apps\">Apps</a>`"))
		#expect(markdown.contains("\n\n<a href=\"https://sindresorhus.com/apps\">Apps</a>"))
		#expect(markdown.contains("<div>\n<a href=\"https://sindresorhus.com/about\">About</a>\n</div>"))
	}

	@Test
	func `Markdown export preserves the containers of HTML blocks`() async throws {
		let app = try await App(body: """
		> <div>
		> <a href="/apps">Apps</a>
		> </div>

		1. <div>
		   <a href="/about">About</a>
		   </div>

		2. Keep this item.
		""")
		let route = try #require(Site(content: .test(apps: [app])).textFileRoutes.first { $0.path == #path("/test.md") })
		let markdown = String(decoding: try await route.renderedFile(), as: UTF8.self)

		#expect(markdown.contains("> <div>\n> <a href=\"https://sindresorhus.com/apps\">Apps</a>\n> </div>"))
		#expect(markdown.contains("1. <div>\n   <a href=\"https://sindresorhus.com/about\">About</a>\n   </div>\n\n2. Keep this item."))
	}

	@Test
	func `release asset names validate direct construction and retain absolute source links`() async throws {
		for name in ["", " ", ".", "..", "folder/App.zip"] {
			#expect(throws: ContentError.self) {
				try GitHubReleaseAssetName(validating: name)
			}
		}

		let filename = try GitHubReleaseAssetName(validating: "App Édition.zip")
		#expect(filename.value == "App Édition.zip")
		let app = try await App(frontmatter: "repositoryURL: 'https://github.com/sindresorhus/test'")
		let repository: AbsoluteURL = try #require(app.repositoryURL)
		#expect(app.ownOptions.contains(.sourceCode(repository)))
		#expect(LabeledLink("Source", url: repository).destination == .url(repository))
		#expect(app.ownDownloadURL == repository.value)
	}

	@Test
	func `purchase sources retain their payment and independent download choices`() async throws {
		let free = try await App()
		let paid = try await App(frontmatter: "isPaid: true")
		#expect(!free.purchase.isPaid)
		#expect(paid.purchase.isPaid)
		let store = try await App(frontmatter: "appStoreID: 123\nisPaid: true\nsetappID: 571\ngitHubDownload: {repository: 'sindresorhus/test', file: 'Test.zip'}")
		guard case .appStore(let identifier, let isPaid) = store.purchase else {
			Issue.record("Expected the App Store purchase source.")
			return
		}
		#expect(identifier == 123)
		#expect(isPaid)
		#expect(store.downloadOptions.count == 3)
		let freeStore = try await App(frontmatter: "appStoreID: 456")
		#expect(freeStore.appStoreID == 456)
		#expect(!freeStore.isPaid)
		#expect(freeStore.purchase.gumroad == nil)
		let gumroad = try await App(frontmatter: "gumroad: {id: 'test', price: 6}")
		#expect(gumroad.isPaid)
		#expect(try gumroad.purchase.gumroad?.price == Price(validating: 6))
		#expect(gumroad.gumroadURL?.query() == "wanted=true")
	}

	@Test(arguments: ["appStoreID: 123", "isPaid: false"])
	func `incompatible purchase metadata remains an authored gumroad error`(other: String) async throws {
		let error = try await #require(throws: ContentErrors.self) {
			try await App(frontmatter: "gumroad: {id: 'test', price: 6}\n\(other)")
		}
		#expect(error.errors.first?.line == 6)
		#expect(error.errors.first?.reason.contains("`gumroad` is only for paid apps") == true)
	}

	@Test
	func `resolved guide content preserves the built in split and accepts app link queries`() async throws {
		let body = "@QuickAnswer {\nUse [Test](/test?source=guide#faq).\n}\n\n@Steps {\n1. Open Test.\n}\n\n## Without an app\n\nUse the built-in way."
		let guide = try await Guide(markdown: Guide.testMarkdown(body: body))
		let app = try await App()
		#expect(guide.quickAnswerLinkError(to: app) == nil)
		let resolved = try #require(Guide.Resolved(guide: guide, apps: [app]))
		#expect(resolved.parts.before.html.contains("Open Test."))
		#expect(!resolved.parts.before.html.contains("Use the built-in way."))
		#expect(resolved.parts.after.html.contains("Use the built-in way."))
	}

	@Test
	func `resolved quote attribution retains required article dates and optional personal dates`() async throws {
		let app = try await App(publicationDate: "2020-01-01", frontmatter: "pressQuotes: [{quote: 'Good', source: 'Article', url: 'https://example.com/2021/review', year: 2021}, {quote: 'Useful', source: 'Buyer', url: 'https://sindresorhus.gumroad.com/l/test'}, {quote: 'Nice', source: 'Mom'}]")
		let quotes = app.pressQuotes
		guard case .article(let source, let url, let year) = quotes[0].attribution else {
			Issue.record("Expected dated article attribution.")
			return
		}
		#expect(source == "Article")
		#expect(url.value.host() == "example.com")
		#expect(year == 2021)
		guard case .buyer(_, _, nil) = quotes[1].attribution else {
			Issue.record("Expected a buyer without an article date.")
			return
		}
		guard case .person("Mom", nil) = quotes[2].attribution else {
			Issue.record("Expected an unlinked personal attribution.")
			return
		}
		let html = PressQuotes(quotes: quotes).render()
		#expect(html.contains("2021"))
		#expect(html.contains("Buyer"))
		#expect(html.contains("Mom"))
	}

	@Test
	func `sponsor presentations require logo tier links and retain text only sponsors`() throws {
		let decoder = JSONDecoder()
		let logos = try decoder.decode(MarkdownPage.SponsorTier.self, from: Data(#"{"title":"Gold","price":"$100","sponsors":[{"name":"Example","url":"https://example.com","logo":{"path":"/logo.png","width":120,"height":40}}]}"#.utf8))
		guard case .logos(let linked) = try logos.resolved.presentation else {
			Issue.record("Expected linked logo sponsors.")
			return
		}
		#expect(linked.first?.url.value == #URL("https://example.com"))
		let html = SponsorList(tiers: [try logos.resolved]).render()
		#expect(html.contains(#"href="https://example.com" rel="nofollow""#))
		#expect(html.contains(#"width="120""#))

		let text = try decoder.decode(MarkdownPage.SponsorTier.self, from: Data(#"{"title":"Thanks","price":"$1","sponsors":[{"name":"A reader"}]}"#.utf8))
		#expect(SponsorList(tiers: [try text.resolved]).render().contains("<li>A reader</li>"))
		let missingLink = try decoder.decode(MarkdownPage.SponsorTier.self, from: Data(#"{"title":"Gold","price":"$100","sponsors":[{"name":"Example","logo":{"path":"/logo.png","width":120,"height":40}}]}"#.utf8))
		#expect(throws: ContentError.self) {
			try missingLink.resolved
		}
	}

	@Test(arguments: [0, -1])
	func `sponsor logo sizes reject invalid direct and decoded values`(width: Int) throws {
		#expect(throws: ContentError.self) {
			try MarkdownPage.Logo.Pixels(validating: width)
		}
		#expect(throws: DecodingError.self) {
			try JSONDecoder().decode(MarkdownPage.Logo.self, from: Data("{\"path\":\"/logo.png\",\"width\":\(width),\"height\":40}".utf8))
		}
	}

	@Test
	func `sponsor export expands only parsed directives and preserves fenced examples`() async throws {
		let page = try await MarkdownPage(markdown: """
		---
		title: 'Supporters'
		sponsorTiers: [{title: 'Gold', price: '$100/month', sponsors: [{name: 'Example'}]}]
		---

		```
		@Sponsors
		```

		@Sponsors
		""", slug: "supporters")
		let content = SiteContent.test(pages: [page])
		let route = try #require(Site(content: content).textFileRoutes.first { $0.path == #path("/llms-full.txt") })
		let markdown = String(decoding: try await route.renderedFile(), as: UTF8.self)
		#expect(markdown.contains("```\n@Sponsors\n```"))
		#expect(markdown.components(separatedBy: "## Gold $100/month").count == 2)
		#expect(markdown.contains("- Example"))
	}
}

extension DomainValueTests {
	@Test(.temporaryDirectory)
	func `shared answers count visible HTML following a comment as content`() throws {
		let root = try URL.temporaryDirectory(files: [
			"content/shared-questions.md": "### Shared question {#shared}\n\n<!-- author note --><p>Visible answer.</p>\n",
		])
		let library = try App.SharedQuestions.Library(project: .site(root: root))
		#expect(library.file?.url.lastPathComponent == "shared-questions.md")
	}
}

extension DomainValueTests {
	@Test
	func `palette shades have ordered unique keys and resolvable references`() {
		for palette in Palette.allCases {
			let shades = palette.shades
			let keys = shades.map(\.key)
			#expect(!keys.isEmpty)
			#expect(keys == keys.sorted())
			#expect(Set(keys).count == keys.count)

			for (shade, value) in shades {
				let reference = palette.color(shade)
				#expect(reference.description == "var(--\(palette.rawValue)-\(shade))")
				#expect(reference.resolved == value)
			}
		}

		#expect(Color.gray(950).resolved.description == "oklch(18.8% .004 286deg)")
		#expect(Color.primary(500).resolved.description == "oklch(62.3% .214 259.815deg)")
		#expect(Color.secondary(600).resolved.description == "oklch(59.2% .249 .584deg)")
		#expect(Color.white.resolved == .white)
		#expect(Color(raw: "oklch(50% .2 180deg)").resolved == Color(raw: "oklch(50% .2 180deg)"))
	}

	@Test
	func `palette lookups reject a shade absent from the authored palette`() async {
		await #expect(processExitsWith: .failure) {
			_ = Palette.primary.color(123)
		}
	}
}
