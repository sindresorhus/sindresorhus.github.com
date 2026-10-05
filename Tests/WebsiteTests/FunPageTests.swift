import Elementary
import Foundation
import ImageIO
import SiteKit
import Testing
@testable import Website

/**
The fun pages: Appdle, the career quilt, and the 1999 page, from the real content, without the network.
*/
@Suite
struct FunPageTests {
	@Test
	func `every Appdle puzzle has a name, an icon, and a link`() async throws {
		let page = AppdlePage(content: try await SiteContent.website)
		let puzzles = page.puzzles

		#expect(puzzles.count > 20)
		#expect(Set(puzzles.map(\.title)).count == puzzles.count)

		for puzzle in puzzles {
			#expect(!puzzle.title.isEmpty)
			#expect(!puzzle.url.isEmpty)
			#expect(Project.website.publicFile(RoutePath(puzzle.icon)).isFile, "\(puzzle.title) has no icon at \(puzzle.icon).")
		}
	}

	/**
	The script picks the puzzle at the day number modulo the count, so the order must be the same in every build of the same content.
	*/
	@Test
	func `the Appdle order is the same in every build`() async throws {
		let content = try await SiteContent.website
		let first = AppdlePage(content: content).puzzles.map(\.title)

		// Another build loads the content again.
		let secondContent = try await SiteContent.load(from: .website, externalData: .none, buildDate: content.buildDate)
		let second = AppdlePage(content: secondContent).puzzles.map(\.title)

		#expect(first == second)

		// Shuffled, not in the order of the apps.
		#expect(first != content.activeAppsWithPages.filter { !$0.hasPlaceholderIcon }.map(\.title))
	}

	/**
	The GIFs in `public/1999` and the cases of `GeoCitiesPage.GIF` are the same, so no file is left over and no case is missing. A GIF that moves has a still frame for reduced motion, and a GIF that does not move has none.
	*/
	@Test
	func `every GIF of the 1999 page is on the page, and each that moves has a still frame`() async throws {
		let directory = Project.website.publicDirectory.appending(path: "1999")
		let files = try directory.filesRecursively().filter { $0.pathExtension == "gif" }
		let gifs = files.filter { $0.deletingLastPathComponent().lastPathComponent == "1999" }
		let stills = files.filter { $0.deletingLastPathComponent().lastPathComponent == "still" }

		#expect(Set(gifs.map { $0.deletingPathExtension().lastPathComponent }) == Set(GeoCitiesPage.GIF.allCases.map(\.rawValue)))

		let html = GeoCitiesPage(content: try await SiteContent.website).body.render()
		let frameCount = { (file: URL) in
			CGImageSourceCreateWithURL(file as CFURL, nil).map(CGImageSourceGetCount) ?? 0
		}

		for gif in GeoCitiesPage.GIF.allCases {
			let file = Project.website.publicFile(gif.path)
			let still = Project.website.publicFile(gif.stillPath)

			#expect(html.contains("src=\"\(gif.path)\""), "\(gif.path) is not on the page.")
			#expect(frameCount(file) > 0, "\(gif.path) is not a GIF.")
			#expect(still.isFile == (frameCount(file) > 1), "\(gif.path) needs a still frame only when it moves.")

			if still.isFile {
				#expect(frameCount(still) == 1, "\(gif.stillPath) moves.")
				#expect(html.contains("srcset=\"\(gif.stillPath)\""), "\(gif.stillPath) is not on the page.")
			}
		}

		#expect(stills.count == GeoCitiesPage.GIF.allCases.count { Project.website.publicFile($0.stillPath).isFile })
	}

	@Test
	func `without a GitHub token, the quilt is left out without a request or a warning`() async throws {
		let cache = ResponseCache(directory: nil, maximumAge: .zero)
		let years = try await ContributionYear.load(github: GitHub(token: nil, cache: cache), until: .now)
		#expect(years == nil)

		let content = try await SiteContent.website
		let paths = Site(content: content).routes(project: .website).map(\.path)
		#expect(!paths.contains(.careerQuilt))
		#expect(paths.contains(.appdle))
		#expect(paths.contains(.geoCities))
	}

	@Test
	func `a contribution year starts on its weekday and ends at the build date`() throws {
		let json = #"""
		{
			"totalContributions": 12,
			"weeks": [
				{"contributionDays": [{"date": "2026-01-01", "contributionCount": 2, "contributionLevel": "FIRST_QUARTILE"}, {"date": "2026-01-02", "contributionCount": 7, "contributionLevel": "FOURTH_QUARTILE"}, {"date": "2026-01-03", "contributionCount": 0, "contributionLevel": "NONE"}]},
				{"contributionDays": [{"date": "2026-01-04", "contributionCount": 3, "contributionLevel": "SECOND_QUARTILE"}, {"date": "2026-01-05", "contributionCount": 7, "contributionLevel": "FOURTH_QUARTILE"}, {"date": "2026-01-06", "contributionCount": 0, "contributionLevel": "NONE"}]}
			]
		}
		"""#

		let calendar = try JSONDecoder().decode(ContributionCalendar.self, from: Data(json.utf8))
		let buildDate = try Date("2026-01-05T12:00:00Z", strategy: .iso8601)
		let year = ContributionYear(year: 2026, calendar: calendar, until: buildDate)

		// 2026-01-01 is a Thursday.
		#expect(year.firstWeekday == 4)
		#expect(year.days.map(\.date) == ["2026-01-01", "2026-01-02", "2026-01-03", "2026-01-04", "2026-01-05"])
		#expect(year.busiestDay?.date == "2026-01-02")
	}
}
