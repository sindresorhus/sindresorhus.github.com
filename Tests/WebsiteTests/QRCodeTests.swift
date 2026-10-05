import CoreImage
import Elementary
import Foundation
import Testing
@testable import Website

@Suite
struct QRCodeTests {
	@Test
	func `the modules read back as the URL`() throws {
		let url = try #require(URL(string: "https://apps.apple.com/app/id1234567890"))
		let code = QRCode(url: url, label: "QR code")
		let size = code.modules.count
		#expect(size > 20)
		#expect(code.modules.allSatisfy { $0.count == size })

		// The modules drawn large, as a scanner sees them.
		let scale = 8
		var pixels = [UInt8](repeating: 255, count: size * scale * size * scale)

		for (y, row) in code.modules.enumerated() {
			for (x, isDark) in row.enumerated() where isDark {
				for pixelY in (y * scale)..<((y + 1) * scale) {
					for pixelX in (x * scale)..<((x + 1) * scale) {
						pixels[(pixelY * size * scale) + pixelX] = 0
					}
				}
			}
		}

		let image = try #require(pixels.withUnsafeMutableBytes { buffer in
			CGContext(data: buffer.baseAddress, width: size * scale, height: size * scale, bitsPerComponent: 8, bytesPerRow: size * scale, space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue)?.makeImage()
		})

		let detector = try #require(CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh]))
		let messages = detector.features(in: CIImage(cgImage: image)).compactMap { ($0 as? CIQRCodeFeature)?.messageString }
		#expect(messages == [url.absoluteString])
	}

	@Test
	func `the SVG draws the dark modules in the current color`() throws {
		let html = QRCode(url: try #require(URL(string: "https://sindresorhus.com")), label: "QR code for “Dato”").render()

		#expect(html.hasPrefix(#"<div><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 "#))
		#expect(html.contains(#"aria-label="QR code for “Dato”""#))
		#expect(html.contains(#"<path fill="currentColor" d="M"#))
	}
}
