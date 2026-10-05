import Foundation
import ImageIO
import SiteKit
import Testing
@testable import Website

@Suite
struct OpenGraphCardTests {
	@Test
	func `renders a 1200×630 JPEG with the bundled font`() throws {
		let card = OpenGraphCard(path: "/og/test.jpg", title: "A Very Long Title That Wraps Onto More Lines Than Allowed", subtitle: "Subtitle", image: Project.website.publicFile("/assets/sindre-sorhus.jpg"), description: "Test")
		let data = try card.renderJPEG()

		let source = try #require(CGImageSourceCreateWithData(data as CFData, nil))
		#expect(CGImageSourceGetType(source) as String? == "public.jpeg")
		let properties = try #require(CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any])
		#expect(properties[kCGImagePropertyPixelWidth] as? Int == 1200)
		#expect(properties[kCGImagePropertyPixelHeight] as? Int == 630)
	}

	@Test
	func `renders without the image when it is missing`() throws {
		let card = OpenGraphCard(path: "/og/test.jpg", title: "Title", subtitle: "Subtitle", image: URL(filePath: "/missing/icon.png"), description: "Test")
		_ = try card.renderJPEG()
	}
}
