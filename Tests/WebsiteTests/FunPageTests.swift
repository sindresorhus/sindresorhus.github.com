import Elementary
import Foundation
import SOML
import ImageIO
import SiteKit
import Testing
@testable import Website

/**
The fun pages: Appdle, the career quilt, and the 1999 page, from the real content, without the network.
*/
struct FunPageTests {
	@Test
	func `Mac catalog actions and submenu leaves retain the script contract`() {
		let command = GeoCitiesMacOS.Command.launch(.extensions)
		#expect(command.title == "Extensions Manager")
		#expect(command.icon == "extension")
		#expect(command.action.value == "launch-extensions")
		#expect(GeoCitiesMacOS.Action.open(.about).value == "open-about")

		let html = GeoCitiesMacOS.MenuBarItem(item: .submenu("Panels", id: "panels", commands: [command])).render()
		#expect(html.contains("aria-controls=\"geocities-mac-menu-panels\""))
		#expect(html.contains("data-mac-action=\"launch-extensions\""))
		#expect(html.contains("data-mac-part=\"icon-extension\""))
		#expect(html.contains(">Extensions Manager</button>"))

		let window = GeoCitiesMacOSWindows.window(.simpleText, title: "A document") {
			"Text"
		}.render()
		#expect(window.contains("data-mac-window=\"simpletext\""))
		#expect(window.contains("aria-labelledby=\"geocities-mac-title-simpletext\""))
		#expect(window.contains(">A document</h3>"))
	}

	@Test
	func `Control Strip modules keep their help beside their identity`() {
		let modules = GeoCitiesMacOS.ControlStripModule.all
		#expect(modules.map(\.id) == ["volume", "depth", "appletalk", "sharing", "speech"])
		#expect(modules.allSatisfy { !$0.label.isEmpty && !$0.help.isEmpty })
		let html = GeoCitiesMacOS.controlStrip.render()
		for module in modules {
			#expect(html.contains("data-mac-strip-module=\"\(module.id)\""))
			#expect(html.decodingHTMLEscapes.contains("data-mac-balloon=\"\(module.help)\""))
		}
	}

	@Test
	func `both handhelds retain their direction metadata and decorative brand`() {
		let handheld = GeoCitiesHandheld().render()
		let camera = GeoCitiesHandheldCamera().render()
		#expect(GeoCitiesHandheld.Direction.rows.flatMap(\.self).map(\.rawValue) == ["up", "left", "right", "down"])
		for direction in GeoCitiesHandheld.Direction.allCases {
			for html in [handheld, camera] {
				#expect(html.contains("aria-label=\"\(direction.label)\""))
				#expect(html.contains(">\(direction.symbol)</button>"))
			}
		}
		let brand = GeoCitiesHandheld.Brand().render()
		#expect(brand.contains("aria-hidden=\"true\""))
		#expect(handheld.contains(brand))
		#expect(camera.contains(brand))
	}

	@Test
	func `Winter Games event identities pair menu buttons and instructions`() {
		let html = GeoCitiesWinterGames(project: .website).render()
		#expect(GeoCitiesWinterGames.events.map(\.id) == GeoCitiesWinterGames.Event.ID.allCases)
		for event in GeoCitiesWinterGames.events {
			#expect(html.contains("data-winter-event=\"\(event.id.rawValue)\""))
			#expect(html.contains("data-winter-howto=\"\(event.id.rawValue)\""))
		}
	}

	@Test
	func `retro fields assign matching label and control ids`() {
		let html = GeoCitiesPageMaker(project: .website).render()
		let controls = html.matches(of: /<(input|select|textarea)\b[^>]*\bid="([^"]+)"/)
		let labels = html.matches(of: /<label\b[^>]*\bfor="([^"]+)"/)

		#expect(labels.count == 6)

		let controlIDs = Set(controls.map { String($0.2) })
		let labelIDs = Set(labels.map { String($0.1) })
		#expect(controlIDs == labelIDs)
		#expect(Set(controls.map { String($0.1) }) == ["input", "select", "textarea"])
	}

	@Test
	func `calculator metadata agrees with Tronds rendered transfer menu`() throws {
		let calculator = GeoCitiesCalculator()
		let html = calculator.render()
		let config = try renderedConfig(calculator)
		let programs = try #require(config["programs"] as? [[String: Any]])
		#expect(programs.compactMap { $0["name"] as? String } == ["FALLDOWN", "CATPIC", "RPGQUEST", "PHOENIX", "WAFFLRUN", "SNAKE", "QUIZ"])
		#expect(programs.count == 7)

		for program in programs {
			let name = try #require(program["name"] as? String)
			let byteCount = try #require(program["byteCount"] as? Int)
			#expect(html.contains("\(byteCount) bytes"))
			#expect(html.contains("data-ti83-send=\"\(name)\""))
		}
	}

	@Test
	func `skater runtime gaps identify the rendered checklist with its names and scores`() throws {
		let skater = GeoCitiesSkater(project: .website)
		let html = skater.render()
		let config = try renderedConfig(skater)
		let gaps = try #require(config["gaps"] as? [[String: Any]])
		let ids = Set(html.matches(of: /data-skater-gap="([^"]+)"/).map { String($0.1) })
		#expect(gaps.count == 9)
		#expect(Set(gaps.compactMap { $0["id"] as? String }) == ids)

		for gap in gaps {
			let name = try #require(gap["name"] as? String)
			let points = try #require(gap["points"] as? Int)
			#expect(html.contains("\(name) (\(points))"))
			#expect(gap["hint"] == nil)
		}
	}

	@Test
	func `Casio runtime bindings retain physical codes and their printed labels`() throws {
		let casio = GeoCitiesCasio(project: .website)
		let config = try renderedConfig(casio)
		let keys = try #require(config["computerKeys"] as? [[String: String]])
		#expect(config["lowestNote"] as? Int == 60)
		#expect(keys.count == 18)
		#expect(keys.first == ["code": "KeyA", "label": "A"])
		#expect(keys[16] == ["code": "Semicolon", "label": ";"])
		#expect(keys[17] == ["code": "Quote", "label": "'"])
		let html = casio.render().decodingHTMLEscapes
		for key in keys {
			let label = try #require(key["label"])
			#expect(html.contains(">\(label)</span>"))
		}
		#expect(html.matches(of: /data-casio-note="[^"]+"/).count == GeoCitiesCasio.keyCount)
	}

	@Test
	func `tracker runtime dimensions agree with rendered channels and instruments`() throws {
		let tracker = GeoCitiesTracker()
		let config = try renderedConfig(tracker)
		let channelCount = try #require(config["channelCount"] as? Int)
		let instruments = try #require(config["instruments"] as? [String])
		let html = tracker.render()
		#expect(config["rowCount"] == nil)
		#expect(html.matches(of: /data-tracker-mute="[^"]+"/).count == channelCount)
		#expect(html.matches(of: /data-tracker-cell="[^"]+"/).count == channelCount * GeoCitiesTracker.rowCount)
		#expect(instruments == ["Kick", "Snare", "HiHat", "Bass", "Lead", "Pad"])
		for instrument in instruments {
			#expect(html.contains(instrument))
		}
	}

	@Test
	func `movie maker tools each identify a drawer and scenes starts visible`() {
		let html = GeoCitiesWindowsMovieMaker().render()
		let tools = html.matches(of: /<button\b[^>]*data-moviemaker-tool="([^"]+)"[^>]*>/)
		let panels = html.matches(of: /<div\b[^>]*data-moviemaker-panel="([^"]+)"[^>]*>/)
		let expected = Set(GeoCitiesWindowsMovieMaker.Tool.allCases.map(\.rawValue))
		#expect(Set(tools.map { String($0.1) }) == expected)
		#expect(Set(panels.map { String($0.1) }) == expected)
		for tool in tools {
			#expect(tool.0.contains("aria-pressed=\"true\"") == (tool.1 == "scenes"))
		}
		for panel in panels {
			#expect(panel.0.contains(" hidden") == (panel.1 != "scenes"))
		}
	}

	@Test
	func `VCR live programs keep broadcast channels separate from AV and cover live drawings`() throws {
		let vcr = GeoCitiesVCR()
		let config = try renderedConfig(vcr)
		let channels = try #require(config["channelNames"] as? [String: String])
		let programs = try #require(config["programs"] as? [[String: Any]])
		#expect(channels == ["1": "NRK1", "2": "TV 2", "3": "TVNorge"])
		#expect(programs.count == 8)
		#expect(Set(programs.compactMap { $0["scene"] as? String }) == Set(GeoCitiesVCR.Program.Scene.allCases.map(\.rawValue)))
		let html = vcr.render()
		for program in programs {
			let channel = try #require(program["channel"] as? Int)
			let code = try #require(program["code"] as? String)
			#expect(channels[String(channel)] != nil)
			#expect(html.contains("data-vcr-program=\"\(code)\""))
		}
	}

	@Test
	func `pet markup retains the Neko control UFO image and four canvas pets`() {
		let html = GeoCitiesPets(project: .website).render()
		#expect(html.contains("id=\"\(GeoCitiesPets.IDs.prey.id)\""))
		#expect(html.contains("id=\"\(GeoCitiesPets.IDs.basket.id)\""))
		#expect(html.contains("/1999/ufo.gif"))
		let toggles = Set(html.matches(of: /data-critter-toggle="([^"]+)"/).map { String($0.1) })
		#expect(toggles == ["neko", "sheep", "birds", "mouse", "ufo", "worm"])
		let pictures = Set(html.matches(of: /<canvas\b[^>]*data-critter-picture="([^"]+)"/).map { String($0.1) })
		#expect(pictures == ["sheep", "birds", "mouse", "worm"])
	}

	@Test
	func `Rubik booklet advertises every supported highlight group`() {
		let html = GeoCitiesRubik().render()
		let groups = Set(html.matches(of: /data-rubik-highlight="([^"]+)"/).map { String($0.1) })
		#expect(groups == Set(GeoCitiesRubik.Highlight.allCases.map(\.rawValue)))
	}

	@Test
	func `SVG images escape accessible labels while sprite icons retain their typed shell`() throws {
		let label = #"A & B "quoted""#
		let sparkline = try #require(Sparkline(values: [1, 3, 2], label: label)).render()
		let url = try #require(URL(string: "https://example.com"))
		let qrCode = QRCode(url: url, label: label).render()
		for html in [sparkline, qrCode] {
			#expect(html.contains("role=\"img\""))
			#expect(html.contains("aria-label=\"A &amp; B &quot;quoted&quot;\""))
		}
		let icon = Icon.copy.size(.rootEm(1), strokeWidth: 2.5).render()
		#expect(icon.contains("width=\"1rem\""))
		#expect(icon.contains("stroke-width=\"2.5\""))
		#expect(icon.contains("aria-hidden=\"true\""))
		#expect(icon.contains("/assets/icons.svg?v="))
		#expect(icon.contains("#copy"))
		#expect(Icon.copy.size(.rootEm(1)).render().contains("stroke-width=\"2\""))
	}

	@Test
	func `encoded icons identify the same symbols as rendered icons and the sprite`() throws {
		let sprite = Icon.sprite
		for icon in Icon.allCases {
			let identifier = try JSONDecoder().decode(String.self, from: JSONEncoder().encode(icon))
			let html = icon.size(.pixels(24)).render()
			#expect(html.contains("#\(identifier)\""))
			#expect(sprite.contains("id=\"\(identifier)\""))
		}
		#expect(try JSONDecoder().decode(String.self, from: JSONEncoder().encode(Icon.appStore)) == "app-store")
	}

	@Test
	func `AwakeStatus outcomes share states and reserve the longest configured label`() throws {
		let awake = AwakeStatus()
		let config = try renderedConfig(awake)
		let statuses = try #require(config["statuses"] as? [[String: Any]])
		#expect(statuses.compactMap { $0["beforeHour"] as? Int } == [3, 10, 12, 24])
		#expect(statuses.compactMap { $0["state"] as? String } == ["late", "asleep", "day", "day"])
		#expect(statuses.compactMap { $0["icon"] as? String } == ["moon", "zzz", "coffee", "sun"])
		let longest = try #require(statuses.compactMap { $0["text"] as? String }.max(by: { $0.count < $1.count }))
		#expect(awake.render().contains(">\(longest)</span>"))
	}

	@Test(arguments: 1...5)
	func `quote layout shares the responsive columns for each supported count`(count: Int) {
		let layout = QuoteLayout(count: count)
		let css = Stylesheet {
			Rule(".quotes", layout.style)
		}.css
		#expect(css.contains("repeat(4, minmax(0, 1fr))") == (count > 1))
		#expect(css.contains("repeat(6, minmax(0, 1fr))") == (count == 3 || count == 5))
		#expect(!css.contains("gap:"))
		// A shared layout may be collected before the review component, so its root must not override the columns.
		let reviewRoot = Stylesheet {
			Rule(".reviews", QuoteGrid.Styles.root.style)
		}.css
		#expect(!reviewRoot.contains("grid-template-columns:"))
	}

	@Test
	func `app icons accept ordinary element ids and the hero retains its script id`() async throws {
		let app = try await App(title: "Example")
		let id = ElementID("ordinary-app-icon")
		let html = AppIcon(app, size: 64, imageID: id).render()
		#expect(html.contains("id=\"\(id)\""))
		let hero = AppHero(listing: AppListing(app: app), buildDate: .now).render()
		#expect(hero.contains("id=\"\(AppHero.IDs.icon.id)\""))
	}

	@Test
	func `shared puzzle script and universal links use the same query name`() async throws {
		#expect(SudokuBoard.queryName == "p")
		let app = try await App(title: "Pipoku", slug: "pipoku")
		let page = try #require(SharedPuzzlePage(apps: [app]))
		let json = try #require(JSONSerialization.jsonObject(with: page.appSiteAssociation) as? [String: Any])
		let links = try #require(json["applinks"] as? [String: Any])
		let details = try #require(links["details"] as? [[String: Any]])
		let detail = try #require(details.first)
		let components = try #require(detail["components"] as? [[String: Any]])
		let component = try #require(components.first)
		#expect(component["?"] as? [String: String] == [SudokuBoard.queryName: "?*"])
		#expect(try SudokuBoard.script.source.contains(".get('\(SudokuBoard.queryName)')"))
	}

	/**
	Reads the runtime configuration from the actual element markup.
	*/
	private func renderedConfig(_ element: some ScriptedElement) throws -> [String: Any] {
		let value = try #require(element.render().firstMatch(of: /data-config="([^"]+)"/)).1
		let json = String(value).decodingHTMLEscapes
		return try #require(JSONSerialization.jsonObject(with: Data(json.utf8)) as? [String: Any])
	}

	@Test
	func `the 1999 navigation and room targets identify rendered elements`() async throws {
		let html = GeoCitiesPage(content: try await SiteContent.website).body.render()
		let ids = Set(html.matches(of: /\sid="([^"]+)"/).map { String($0.1) })
		let targets = GeoCitiesPage.siteMapItems.map(\.anchor) + GeoCitiesRoom.hotspots.compactMap(\.target)

		#expect(targets.count > 30)
		for target in targets {
			#expect(ids.contains(target.rawValue), "The target \(target) is missing from the 1999 page.")
		}
	}

	/**
	The desktop icons, the Start menu, and the taskbar open the windows by the catalog ID, so a typo in a raw value would leave a program that does nothing.
	*/
	@Test
	func `every launcher opens a window of the same program`() async throws {
		let html = GeoCitiesPage(content: try await SiteContent.website).body.render()
		let windowIDs = Set(html.matches(of: /\sdata-desktop-window="([^"]+)"/).map { String($0.1) })
		let launcherIDs = Set(html.matches(of: /\sdata-desktop-open="([^"]+)"/).map { String($0.1) })

		#expect(!launcherIDs.isEmpty)
		#expect(launcherIDs.subtracting(windowIDs).isEmpty, "These launchers open no window: \(launcherIDs.subtracting(windowIDs).sorted().joined(separator: ", ")).")
	}

	/**
	The name and the link of a puzzle are those of its app, which loading checks: the title is plain text that is not empty (`@PlainText`), and the link is the path of the page or an absolute URL.
	*/
	@Test
	func `every Appdle puzzle has its own name and an icon`() async throws {
		let page = AppdlePage(content: try await SiteContent.website)
		let puzzles = page.puzzles

		#expect(puzzles.count > 20)
		#expect(Set(puzzles.map(\.title)).count == puzzles.count)

		for puzzle in puzzles {
			#expect(Project.website.publicFile(puzzle.icon).isFile, "\(puzzle.title) has no icon at \(puzzle.icon).")
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

		let html = try #require(try await RenderedPage.website.first { $0.route.path == .geoCities }).html
		// The images of the page, like `src=/1999/smiley.gif`, found once, as a search of the long page for each GIF is slow.
		let images = Set(html.matches(of: /(src|srcset)="([^"]*)"/).map { "\($0.1)=\($0.2)" })
		let frameCount = { (file: URL) in
			CGImageSourceCreateWithURL(file as CFURL, nil).map(CGImageSourceGetCount) ?? 0
		}

		for gif in GeoCitiesPage.GIF.allCases {
			let file = Project.website.publicFile(gif.path)
			let still = Project.website.publicFile(gif.stillPath)

			#expect(images.contains("src=\(gif.path)"), "\(gif.path) is not on the page.")
			#expect(frameCount(file) > 0, "\(gif.path) is not a GIF.")
			#expect(gif.size(in: .website) == file.imageSize, "The size in the header of \(gif.path) is not the size that ImageIO reads.")
			#expect(still.isFile == (frameCount(file) > 1), "\(gif.path) needs a still frame only when it moves.")

			if still.isFile {
				#expect(frameCount(still) == 1, "\(gif.stillPath) moves.")
				#expect(images.contains("srcset=\(gif.stillPath)"), "\(gif.stillPath) is not on the page.")
			}
		}

		#expect(stills.count == GeoCitiesPage.GIF.allCases.count { Project.website.publicFile($0.stillPath).isFile })
	}

	@Test
	func `without a GitHub token, the quilt is left out without a request or a warning`() async throws {
		let cache = ResponseCache(directory: nil, maximumAge: .zero)
		let years = try await ContributionYear.load(github: GitHub(token: nil, cache: cache), until: .now)
		#expect(years.isEmpty)

		let content = try await SiteContent.website
		let paths = Site(content: content).routes().map(\.path)
		#expect(!paths.contains(.careerQuilt))
		#expect(paths.contains(.appdle))
		#expect(paths.contains(.geoCities))
	}

	/**
	A year has only its own days, from its first day, on its weekday, to the build date.
	*/
	@Test
	func `a contribution year starts on its weekday and ends at the build date`() throws {
		let json = #"""
		{
			"totalContributions": 12,
			"weeks": [
				{"contributionDays": [{"date": "2025-12-31", "contributionCount": 50, "contributionLevel": "FOURTH_QUARTILE"}, {"date": "2026-01-01", "contributionCount": 2, "contributionLevel": "FIRST_QUARTILE"}, {"date": "2026-01-02", "contributionCount": 7, "contributionLevel": "FOURTH_QUARTILE"}, {"date": "2026-01-03", "contributionCount": 0, "contributionLevel": "NONE"}]},
				{"contributionDays": [{"date": "2026-01-04", "contributionCount": 3, "contributionLevel": "SECOND_QUARTILE"}, {"date": "2026-01-05", "contributionCount": 7, "contributionLevel": "FOURTH_QUARTILE"}, {"date": "2026-01-06", "contributionCount": 0, "contributionLevel": "NONE"}]}
			]
		}
		"""#

		let calendar = try ContributionCalendar(json: json)
		let buildDate = try Date("2026-01-05T12:00:00Z", strategy: .iso8601)
		let year = ContributionYear(
			year: 2026,
			calendar: calendar,
			totals: .zero,
			until: buildDate
		)

		// 2026-01-01 is a Thursday. The busier last day of the year before is not in the year.
		#expect(year.days.first?.weekday == .thursday)
		#expect(year.days.map(\.date.description) == ["2026-01-01", "2026-01-02", "2026-01-03", "2026-01-04", "2026-01-05"])
		#expect(year.busiestDay?.date.description == "2026-01-02")
		#expect(year.activeDayCount == 4)
	}

	/**
	The first day is in the row of its weekday, after a blank cell for each weekday before it, in the contributions of the last year and in a patch of the quilt.
	*/
	@Test
	func `the contribution calendars start with blank cells before the weekday of the first day`() throws {
		// 2026-01-01 is a Thursday, so the first week has three days.
		let json = #"""
		{
			"totalContributions": 5,
			"weeks": [
				{"contributionDays": [{"date": "2026-01-01", "contributionCount": 2, "contributionLevel": "FIRST_QUARTILE"}, {"date": "2026-01-02", "contributionCount": 3, "contributionLevel": "FOURTH_QUARTILE"}, {"date": "2026-01-03", "contributionCount": 0, "contributionLevel": "NONE"}]},
				{"contributionDays": [{"date": "2026-01-04", "contributionCount": 0, "contributionLevel": "NONE"}]}
			]
		}
		"""#

		let calendar = try ContributionCalendar(json: json)
		let year = ContributionYear(
			year: 2026,
			calendar: calendar,
			totals: .zero,
			until: try Date("2026-01-04T12:00:00Z", strategy: .iso8601)
		)
		let blankCell = "<span></span>"

		for html in [ContributionHeatmap(calendar: calendar, scale: ContributionScale(days: calendar.days)).render(), try CareerQuiltPage(years: [year]).renderedHTML()] {
			#expect(html.ranges(of: blankCell).count == 4)
		}
	}

	/**
	The name of a month is above the first week that starts in it, and only when the next week starts in it too, so it has room, and not above the first and the last month, which can have one week.
	*/
	@Test
	func `the heatmap names each month above the first week that starts in it`() throws {
		// Each week starts on a Sunday, from December 2025 to March 2026.
		let dates = ["2025-12-28", "2026-01-04", "2026-01-11", "2026-02-01", "2026-02-08", "2026-03-01"]
		let weeks = dates.map { #"{"contributionDays": [{"date": "\#($0)", "contributionCount": 1}]}"# }.joined(separator: ", ")
		let calendar = try ContributionCalendar(json: #"{"totalContributions": 6, "weeks": [\#(weeks)]}"#)
		let html = ContributionHeatmap(calendar: calendar, scale: ContributionScale(days: calendar.days)).render()

		#expect(html.ranges(of: "Jan").count == 1)
		#expect(html.ranges(of: "Feb").count == 1)
		#expect(!html.contains("Mar"))
		#expect(!html.contains("Dec"))
	}

	/**
	The colors of the contributions are the quartiles of the counts of the days with contributions, not the levels of GitHub, so a day has the same color in every calendar.
	*/
	@Test
	func `the contribution levels are the quartiles of the days with contributions`() throws {
		let days = (0...12).map { #"{"date": "2026-01-\#(($0 + 1).formatted(.number.precision(.integerLength(2))))", "contributionCount": \#($0 * 2)}"# }.joined(separator: ", ")
		let calendar = try ContributionCalendar(json: #"{"totalContributions": 0, "weeks": [{"contributionDays": [\#(days)]}]}"#)
		let scale = ContributionScale(days: calendar.days)

		// The counts with contributions are 2, 4, …, 24.
		#expect(scale.upperBounds == [6, 12, 18])
		#expect([0, 1, 6, 7, 12, 18, 19, 500].map(scale.level(for:)) == [.none, .first, .first, .second, .second, .third, .fourth, .fourth])
		#expect(ContributionScale.Level.allCases.map(scale.countText(of:)) == ["0", "1–6", "7–12", "13–18", "19+"])

		// Many days have the same count, so the busiest days are in the third level, and the fourth has no counts.
		let tiedDays = (0..<5).map { #"{"date": "2026-01-\#(($0 + 1).formatted(.number.precision(.integerLength(2))))", "contributionCount": \#($0 < 3 ? 1 : 5)}"# }.joined(separator: ", ")
		let tiedScale = ContributionScale(days: try ContributionCalendar(json: #"{"totalContributions": 13, "weeks": [{"contributionDays": [\#(tiedDays)]}]}"#).days)

		#expect(tiedScale.upperBounds == [1, 1, 5])
		#expect(tiedScale.level(for: 5) == .third)
		#expect(tiedScale.countText(of: .fourth) == nil)
	}

	@Test
	func `the longest streak goes on from one year to the next, and the busiest day and weekday are of all the years`() throws {
		func year(_ year: Int, days: [(date: String, count: Int)]) throws -> ContributionYear {
			let days = days.lazy.map { #"{"date": "\#($0.date)", "contributionCount": \#($0.count), "contributionLevel": "\#($0.count > 0 ? "FIRST_QUARTILE" : "NONE")"}"# }.joined(separator: ", ")
			let json = #"{"totalContributions": 0, "weeks": [{"contributionDays": [\#(days)]}]}"#
			let calendar = try ContributionCalendar(json: json)
			return ContributionYear(
				year: year,
				calendar: calendar,
				totals: .zero,
				until: try Date("2026-12-31T12:00:00Z", strategy: .iso8601)
			)
		}

		let years = [
			try year(2025, days: [("2025-12-27", 9), ("2025-12-28", 0), ("2025-12-29", 1), ("2025-12-30", 2), ("2025-12-31", 3)]),
			try year(2026, days: [("2026-01-01", 9), ("2026-01-02", 4), ("2026-01-03", 0), ("2026-01-04", 1)]),
		]

		#expect(years.longestStreak == 5)
		// The earliest of the days with the same count.
		#expect(years.busiestDay?.date.description == "2025-12-27")
		// Thursday (index 4) and Saturday (index 6) both have 9, so the earlier in the week wins.
		#expect(years.busiestWeekday?.weekday == .thursday)
		#expect(years.busiestWeekday?.count == 9)
		#expect([ContributionYear]().longestStreak == 0)
		#expect([ContributionYear]().busiestWeekday == nil)
	}

	@Test
	func `contribution weekdays have distinct Foundation values and plotting indices`() throws {
		let weekdays = ContributionCalendar.Weekday.allCases

		#expect(weekdays.map(\.rawValue) == Array(1...7))
		#expect(weekdays.map(\.index) == Array(0..<7))
		#expect(ContributionCalendar.Weekday(date: try Date("2026-01-04T00:00:00Z", strategy: .iso8601)) == .sunday)
		#expect(ContributionCalendar.Weekday(date: try Date("2026-01-10T00:00:00Z", strategy: .iso8601)) == .saturday)
	}

	@Test
	func `contribution plots share their leading blanks and ordered color levels`() throws {
		let calendar = try ContributionCalendar(json: #"{"totalContributions": 5, "weeks": [{"contributionDays": [{"date": "2026-01-01", "contributionCount": 2}, {"date": "2026-01-02", "contributionCount": 3}, {"date": "2026-01-03", "contributionCount": 0}]}]}"#)
		let scale = ContributionScale(days: calendar.days)
		let plot = ContributionCalendar.Plot(days: calendar.days, scale: scale)

		#expect(plot.blankDayCount == 4)
		#expect(plot.levels == calendar.days.map { scale.level(for: $0.count) })
		#expect(plot.dayCount == 7)
		let empty = ContributionCalendar.Plot(days: [], scale: scale)
		#expect(empty.blankDayCount == 0)
		#expect(empty.dayCount == 0)
		#expect(empty.levels.isEmpty)
	}

}
