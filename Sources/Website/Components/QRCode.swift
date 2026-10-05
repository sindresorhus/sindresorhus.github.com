import CoreImage
import CoreImage.CIFilterBuiltins
import Elementary
import Foundation
import SiteKit

/**
A QR code of a URL as SVG, made at build time, like for opening the App Store page of an app on an iPhone. It is drawn in the current text color, and fills the width of its container, which the parent can style.
*/
struct QRCode: HTML {
	/**
	The modules of the code, row by row, where `true` is dark. The quiet zone around the code is included.
	*/
	let modules: [[Bool]]

	let label: String

	init(url: URL, label: String) {
		self.modules = Self.modules(for: url)
		self.label = label
	}

	var body: some HTML<HTMLTag.div> {
		div {
			SVG.svg(
				.xmlns(),
				.viewBox(0, 0, .init(integerLiteral: modules.count), .init(integerLiteral: modules.count)),
				SVGAttribute(name: "shape-rendering", value: "crispEdges"),
				SVGAttribute(name: "role", value: "img"),
				SVGAttribute(name: "aria-label", value: label)
			) {
				SVG.path(.fill("currentColor"), .d(path))
			}
		}
	}

	/**
	A rectangle for each run of dark modules in a row.
	*/
	private var path: String {
		var commands = [String]()

		for (y, row) in modules.enumerated() {
			var x = 0

			while x < row.count {
				guard row[x] else {
					x += 1
					continue
				}

				let start = x

				while x < row.count, row[x] {
					x += 1
				}

				commands.append("M\(start) \(y)h\(x - start)v1h-\(x - start)z")
			}
		}

		return commands.joined()
	}

	/**
	Creating a context is slow, and a context is thread-safe, so all codes share one.
	*/
	private static let context = CIContext()

	private static func modules(for url: URL) -> [[Bool]] {
		let filter = CIFilter.qrCodeGenerator()
		filter.message = Data(url.absoluteString.utf8)
		filter.correctionLevel = "M"

		guard
			let image = filter.outputImage,
			let cgImage = context.createCGImage(image, from: image.extent)
		else {
			preconditionFailure("Could not make a QR code of \(url).")
		}

		// One pixel is one module.
		let size = cgImage.width
		var pixels = [UInt8](repeating: 0, count: size * size)

		pixels.withUnsafeMutableBytes { buffer in
			let context = CGContext(data: buffer.baseAddress, width: size, height: size, bitsPerComponent: 8, bytesPerRow: size, space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue)
			context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: size, height: size))
		}

		return (0..<size).map { y in
			(0..<size).map { x in
				pixels[(y * size) + x] < 128
			}
		}
	}
}
