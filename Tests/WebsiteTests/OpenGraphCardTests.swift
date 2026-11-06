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
