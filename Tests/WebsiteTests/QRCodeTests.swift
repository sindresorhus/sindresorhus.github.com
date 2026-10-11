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

	@Test
	func `the terminal text has the modules in half blocks with a margin`() throws {
		let code = QRCode(url: try #require(URL(string: "https://sindresorhus.com")), label: "QR code")
		let colors = "\u{1B}[38;5;16;48;5;231m"
		let reset = "\u{1B}[0m"
		let lines = code.terminalText.split(separator: "\n").map(String.init)

		#expect(lines.allSatisfy { $0.hasPrefix(colors) && $0.hasSuffix(reset) })

		// Each line has two rows of modules, the upper and the lower half of each character.
		var rows = [[Bool]]()

		for line in lines {
			let characters = Array(line.dropFirst(colors.count).dropLast(reset.count))
			rows.append(characters.map { "█▀".contains($0) })
			rows.append(characters.map { "█▄".contains($0) })
		}

		// The margin of two modules is around the code, and the last line has an empty lower half when the rows are odd.
		let margin = 2
		let size = code.modules.count
		#expect(rows.allSatisfy { $0.count == size + (margin * 2) })
		#expect(rows.count == size + (margin * 2) + ((size + (margin * 2)) % 2))
		#expect(rows[margin..<(margin + size)].map { Array($0[margin..<(margin + size)]) } == code.modules)
		#expect(rows.allSatisfy { !$0[..<margin].contains(true) && !$0[(margin + size)...].contains(true) })
		#expect(rows.enumerated().allSatisfy { y, row in (margin..<(margin + size)).contains(y) || !row.contains(true) })
	}
}
