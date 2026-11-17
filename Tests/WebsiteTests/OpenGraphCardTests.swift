import Foundation
import ImageIO
import SiteKit
import Testing
@testable import Website

struct OpenGraphCardTests {
	private static var calendarArtwork: OpenGraphCard.Artwork {
		// Fixed valid JSON supplies the decoded day for this large artwork fixture.
		let day = try! ContributionCalendar.Day(json: #"{"date":"2026-01-06","contributionCount":1}"#)
		let days = Array(repeating: day, count: 366)
		return .calendars(of: Array(repeating: days, count: 17), scale: ContributionScale(days: days))
	}

	@Test(arguments: [
		OpenGraphCard.Artwork.image(Project.website.publicFile(#path("/assets/sindre-sorhus.jpg"))),
		.appScreenshot(icon: Project.website.publicFile(#path("/assets/sindre-sorhus.jpg")), screenshot: Project.website.publicFile(#path("/assets/sindre-sorhus.jpg"))),
		.icons(Array(repeating: Project.website.publicFile(#path("/assets/sindre-sorhus.jpg")), count: 8)),
		OpenGraphCardTests.calendarArtwork,
	])
	func `renders a 1200×630 JPEG with the bundled font`(artwork: OpenGraphCard.Artwork) throws {
		let card = OpenGraphCard(
			path: #path("/og/test.jpg"),
			title: "A Very Long Title That Wraps Onto More Lines Than Allowed",
			subtitle: "Subtitle",
			artwork: artwork,
			description: "Test"
		)
		let data = try card.renderJPEG()

		let source = try #require(CGImageSourceCreateWithData(data as CFData, nil))
		#expect(CGImageSourceGetType(source) as String? == "public.jpeg")
		let properties = try #require(CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any])
		#expect(properties[kCGImagePropertyPixelWidth] as? Int == 1200)
		#expect(properties[kCGImagePropertyPixelHeight] as? Int == 630)
	}

	/**
	The calendars are drawn like the heatmaps: a blank for each weekday before the first day, and the level of each day from the scale of the site.
	*/
	@Test
	func `the calendar artwork makes a patch for each calendar, with a blank for each weekday before its first day`() throws {
		// 2026-01-01 is a Thursday, so four blanks come before it.
		let calendar = try ContributionCalendar(json: #"{"totalContributions": 1, "weeks": [{"contributionDays": [{"date": "2026-01-01", "contributionCount": 1}]}]}"#)
		let artwork = OpenGraphCard.Artwork.calendars(of: [calendar.days, []], scale: ContributionScale(days: calendar.days))

		guard case .calendars(let patches) = artwork else {
			Issue.record("The artwork is not calendars.")
			return
		}

		#expect(patches.map(\.blankDayCount) == [4, 0])
		#expect(patches.map(\.levels) == [[.first], []])
		#expect(patches.map(\.dayCount) == [5, 0])
	}

	@Test(arguments: [
		OpenGraphCard.Artwork.image(URL(filePath: "/missing/icon.png")),
		.appScreenshot(icon: URL(filePath: "/missing/icon.png"), screenshot: URL(filePath: "/missing/screenshot1.png")),
		.icons([URL(filePath: "/missing/icon.png")]),
	])
	func `renders without the image when it is missing`(artwork: OpenGraphCard.Artwork) throws {
		let card = OpenGraphCard(
			path: #path("/og/test.jpg"),
			title: "Title",
			subtitle: "Subtitle",
			artwork: artwork,
			description: "Test"
		)
		_ = try card.renderJPEG()
	}

	/**
	The dark card, for the share dialog of an app page in dark mode, has the dark background of the site, at its own path.
	*/
	@Test(arguments: [
		OpenGraphCard.Artwork.image(URL(filePath: "/missing/icon.png")),
		.icons([]),
	])
	func `a dark card has a dark background`(artwork: OpenGraphCard.Artwork) throws {
		func firstPixel(of appearance: OpenGraphCard.Appearance) throws -> UInt8 {
			let card = OpenGraphCard(
				path: OpenGraphCard.path(ofPage: #path("/test"), appearance: appearance),
				title: "Title",
				subtitle: "Subtitle",
				artwork: artwork,
				description: "Test",
				appearance: appearance
			)
			let source = try #require(CGImageSourceCreateWithData(try card.renderJPEG() as CFData, nil))
			let image = try #require(CGImageSourceCreateImageAtIndex(source, 0, nil))
			let pixels = try #require(image.dataProvider?.data as Data?)
			return pixels[0]
		}

		#expect(try firstPixel(of: .light) > 200)
		#expect(try firstPixel(of: .dark) < 60)
		#expect(OpenGraphCard.path(ofPage: #path("/dato"), appearance: .dark) == #path("/og/dato-dark.jpg"))
	}

	/**
	A long subtitle gets a smaller size before it is cut off, like the description of a guide, which names the app at its end.
	*/
	@Test
	func `a long text gets smaller before it is cut off`() throws {
		func card(subtitle: String) -> OpenGraphCard {
			OpenGraphCard(
				path: #path("/og/test.jpg"),
				title: "Title",
				subtitle: subtitle,
				artwork: .image(URL(filePath: "/missing/icon.png")),
				description: "Test"
			)
		}

		// Four lines at the largest size, and three at the smaller size.
		let fitting = card(subtitle: "Add the date, the week number, and the time in other time zones to the menu bar of your Mac, and see your calendar events with Dato, the app that does it all")
		#expect(try fitting.cutTexts() == (title: false, subtitle: false))

		let cut = card(subtitle: String(repeating: "A sentence that is much too long for the card. ", count: 6))
		#expect(try cut.cutTexts() == (title: false, subtitle: true))
	}

	/**
	Discord shows no preview for a component embed that is larger than 3,000 bytes, or that has another component than one container at the top, so the embed of each app page is smaller, and starts with the container.
	*/
	@Test
	func `the Discord preview of each app page is a container within the size that Discord reads`() async throws {
		var checkedCount = 0

		for page in try await RenderedPage.website {
			guard let script = page.html.scriptTags.first(where: { $0.id == DiscordEmbed.id.rawValue }) else {
				continue
			}

			checkedCount += 1
			#expect(script.type == "application/vnd.discord.component-embed+json")
			#expect(script.body.utf8.count <= DiscordEmbed.maximumSize, "\(page.route.path): \(script.body.utf8.count) bytes")
			let json = try #require(try JSONSerialization.jsonObject(with: Data(script.body.utf8)) as? [String: Any])
			#expect(json.keys.sorted() == ["component"])
			#expect((json["component"] as? [String: Any])?["type"] as? Int == 17)
		}

		#expect(checkedCount >= 50)
	}

	/**
	A page can show the card of another page (``SocialImage/cardOf(_:)``), which only that page publishes, so the image of each page must be a route of the site.
	*/
	@Test
	func `the social image of every page is published`() async throws {
		let paths = Set(try await Site(content: .website).routes(includesGallery: true).map(\.path))

		for page in try await RenderedPage.website {
			let image = try #require(page.html.firstMatch(of: /<meta property="og:image" content="https:\/\/[^\/"]+([^"?]*)(?:\?v=[0-9a-f]{16})?">/), "\(page.route.path) has no social image.")
			#expect(paths.contains(RoutePath(String(image.1))), "\(page.route.path): \(image.1)")
		}
	}
}
