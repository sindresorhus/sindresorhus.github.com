import CoreGraphics
import Foundation
import ImageIO
import SiteKit
import TestSupport
import Testing
import UniformTypeIdentifiers
@testable import Website

struct ImageThumbnailTests {
	@Test(arguments: [(0, 20), (20, 0), (-1, 20), (20, -1)])
	func `pixel sizes reject nonpositive dimensions`(width: Int, height: Int) {
		#expect(PixelSize(width: width, height: height) == nil)
	}

	@Test
	func `positive pixel dimensions have a finite aspect ratio`() throws {
		let size = try #require(PixelSize(width: 1280, height: 800))
		#expect(size.aspectRatio == 1.6)
		#expect(size.description == "1280×800")
	}

	@Test(.temporaryDirectory)
	func `a tiny Retina image keeps positive display dimensions`() throws {
		let file = try URL.temporaryDirectory().appending(path: "tiny.png")
		let context = try #require(CGContext(
			data: nil,
			width: 1,
			height: 3,
			bitsPerComponent: 8,
			bytesPerRow: 0,
			space: CGColorSpaceCreateDeviceRGB(),
			bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
		))
		let image = try #require(context.makeImage())
		let destination = try #require(CGImageDestinationCreateWithURL(file as CFURL, UTType.png.identifier as CFString, 1, nil))
		CGImageDestinationAddImage(destination, image, [kCGImagePropertyDPIWidth: 144, kCGImagePropertyDPIHeight: 144] as CFDictionary)
		try #require(CGImageDestinationFinalize(destination))

		#expect(file.imageSize == PixelSize(width: 1, height: 3))
		#expect(file.displaySize == PixelSize(width: 1, height: 1))
	}

	@Test(.temporaryDirectory, arguments: [(0xFF0000, "#ff0000" as String?), (0x808080, nil as String?)])
	func `thumbnail decoding bounds dimensions and preserves vivid and neutral accents`(hex: Int, accent: String?) throws {
		let file = try URL.temporaryDirectory().appending(path: "icon.png")
		let context = try #require(CGContext(
			data: nil,
			width: 1024,
			height: 512,
			bitsPerComponent: 8,
			bytesPerRow: 0,
			space: CGColorSpaceCreateDeviceRGB(),
			bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
		))
		context.setFillColor(.hex(hex))
		context.fill(
			CGRect(
				x: 0,
				y: 0,
				width: 1024,
				height: 512
			)
		)
		let image = try #require(context.makeImage())
		let destination = try #require(CGImageDestinationCreateWithURL(
			file as CFURL,
			UTType.png.identifier as CFString,
			1,
			nil
		))
		CGImageDestinationAddImage(destination, image, nil)
		try #require(CGImageDestinationFinalize(destination))

		let thumbnail = try #require(file.imageThumbnail(maximumPixelSize: 32))
		#expect(thumbnail.width == 32)
		#expect(thumbnail.height == 16)
		#expect(thumbnail.accentColor == accent.map { Color(raw: $0) })
		#expect(thumbnail.accentColor == image.accentColor)
		#expect(file.deletingLastPathComponent().appending(path: "missing.png").imageThumbnail(maximumPixelSize: 32) == nil)
	}
}
