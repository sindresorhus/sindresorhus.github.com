import Foundation
import ImageIO
import SiteKit
import Testing
@testable import Website

@Suite
struct OpenGraphCardTests {
	@Test
	func `renders a 1200×630 PNG with the bundled font`() throws {
		let project = Project(root: URL(filePath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent())
		let card = OpenGraphCard(path: "/og/test.png", title: "A Very Long Title That Wraps Onto More Lines Than Allowed", subtitle: "Subtitle", image: project.publicFile("/assets/sindre-sorhus.jpg"))
		let data = try card.renderPNG()

		let properties = try #require(CGImageSourceCreateWithData(data as CFData, nil).flatMap { CGImageSourceCopyPropertiesAtIndex($0, 0, nil) as? [CFString: Any] })
		#expect(properties[kCGImagePropertyPixelWidth] as? Int == 1200)
		#expect(properties[kCGImagePropertyPixelHeight] as? Int == 630)
	}

	@Test
	func `renders without the image when it is missing`() throws {
		let card = OpenGraphCard(path: "/og/test.png", title: "Title", subtitle: "Subtitle", image: URL(filePath: "/missing/icon.png"))
		_ = try card.renderPNG()
	}
}
