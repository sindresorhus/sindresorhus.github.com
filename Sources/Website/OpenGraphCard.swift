import CoreGraphics
import CoreText
import Foundation
import ImageIO
import SiteKit
import UniformTypeIdentifiers

/**
The 1200×630 preview image for social media: an image, the title, the subtitle, and the domain, drawn with Core Graphics.

The text uses the bundled Inter font, so a card looks the same on every machine.
*/
struct OpenGraphCard: Sendable {
	let path: RoutePath
	let title: String
	let subtitle: String

	/**
	A PNG or JPEG shown next to the text. When it cannot be read, like for a new app without an icon yet, the space stays empty.
	*/
	let image: URL

	var route: Route {
		.file(path) {
			try renderPNG()
		}
	}

	private static let width = 1200
	private static let height = 630
	private static let textX = 344.0
	private static let textWidth = 776.0

	func renderPNG() throws -> Data {
		guard
			let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
			let context = CGContext(data: nil, width: Self.width, height: Self.height, bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
		else {
			throw OpenGraphCardError(path: path, message: "Could not create the drawing context.")
		}

		// The origin is at the top left, like in the design.
		context.translateBy(x: 0, y: Double(Self.height))
		context.scaleBy(x: 1, y: -1)

		drawBackground(in: context, colorSpace: colorSpace)

		if let picture = CGImageSourceCreateWithURL(image as CFURL, nil).flatMap({ CGImageSourceCreateImageAtIndex($0, 0, nil) }) {
			drawImage(picture, in: context)
		}

		try drawText(in: context)

		guard let cardImage = context.makeImage() else {
			throw OpenGraphCardError(path: path, message: "Could not draw the card.")
		}

		let data = NSMutableData()

		guard let destination = CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil) else {
			throw OpenGraphCardError(path: path, message: "Could not encode the PNG.")
		}

		CGImageDestinationAddImage(destination, cardImage, nil)

		guard CGImageDestinationFinalize(destination) else {
			throw OpenGraphCardError(path: path, message: "Could not encode the PNG.")
		}

		return data as Data
	}

	/**
	A 135° gradient, like `linear-gradient(135deg, …)` in CSS.
	*/
	private func drawBackground(in context: CGContext, colorSpace: CGColorSpace) {
		guard let gradient = CGGradient(colorsSpace: colorSpace, colors: [CGColor.hex(0xF8FAFC), CGColor.hex(0xE2E8F0)] as CFArray, locations: [0, 1]) else {
			return
		}

		// CSS makes the gradient line long enough for the corners to get the end colors.
		let halfLength = (Double(Self.width) + Double(Self.height)) * 0.5.squareRoot() / 2
		let offset = halfLength * 0.5.squareRoot()
		let center = CGPoint(x: Double(Self.width) / 2, y: Double(Self.height) / 2)
		context.drawLinearGradient(gradient, start: CGPoint(x: center.x - offset, y: center.y - offset), end: CGPoint(x: center.x + offset, y: center.y + offset), options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
	}

	/**
	Draws the image as a rounded square with a soft shadow, filling the square like `object-fit: cover`.
	*/
	private func drawImage(_ picture: CGImage, in context: CGContext) {
		let frame = CGRect(x: 80, y: 215, width: 200, height: 200)
		let scale = max(frame.width / Double(picture.width), frame.height / Double(picture.height))
		let size = CGSize(width: Double(picture.width) * scale, height: Double(picture.height) * scale)
		let imageFrame = CGRect(x: frame.midX - size.width / 2, y: frame.midY - size.height / 2, width: size.width, height: size.height)

		context.saveGState()
		// Like `box-shadow: 0 20px 60px`. Shadow offsets ignore the flipped coordinates, so a negative height moves the shadow down.
		context.setShadow(offset: CGSize(width: 0, height: -20), blur: 60, color: CGColor(gray: 0, alpha: 0.15))
		context.beginTransparencyLayer(auxiliaryInfo: nil)
		context.addPath(CGPath(roundedRect: frame, cornerWidth: 46, cornerHeight: 46, transform: nil))
		context.clip()
		// Images draw upside down in flipped coordinates, so they are flipped back.
		context.translateBy(x: 0, y: imageFrame.minY + imageFrame.maxY)
		context.scaleBy(x: 1, y: -1)
		context.draw(picture, in: imageFrame)
		context.endTransparencyLayer()
		context.restoreGState()
	}

	/**
	Draws the title, the subtitle, and the domain as a column that is vertically centered, laid out like CSS line boxes. Long texts wrap, and are cut off with an ellipsis after three lines.
	*/
	private func drawText(in context: CGContext) throws {
		let title = try TextBlock(lines: Self.lines(title, font: Self.font(.bold, size: 68), color: .hex(0x0F172A), maximumLines: 3), font: Self.font(.bold, size: 68), lineHeight: 68 * 1.1)
		let subtitle = try TextBlock(lines: Self.lines(subtitle, font: Self.font(.regular, size: 32), color: .hex(0x64748B), maximumLines: 3), font: Self.font(.regular, size: 32), lineHeight: 32 * 1.4)
		let domainFont = try Self.font(.bold, size: 22)
		let domain = TextBlock(lines: Self.lines("sindresorhus.com", font: domainFont, color: .hex(0x94A3B8), maximumLines: 1), font: domainFont, lineHeight: nil)

		let titleMargin = 20.0
		let domainMargin = 48.0
		let height = title.height + titleMargin + subtitle.height + domainMargin + domain.height
		var top = (Double(Self.height) - height) / 2

		context.textMatrix = CGAffineTransform(scaleX: 1, y: -1)

		for (block, marginAfter) in [(title, titleMargin), (subtitle, domainMargin), (domain, 0)] {
			block.draw(in: context, x: Self.textX, top: top)
			top += block.height + marginAfter
		}
	}

	/**
	Lines of text with the same font and line height.
	*/
	private struct TextBlock {
		let lines: [CTLine]
		let ascent: Double
		let lineHeight: Double

		/**
		- Parameter lineHeight: The height of each line. `nil` uses the normal line height of the font.
		*/
		init(lines: [CTLine], font: CTFont, lineHeight: Double?) {
			self.lines = lines
			self.ascent = CTFontGetAscent(font)
			self.lineHeight = lineHeight ?? CTFontGetAscent(font) + CTFontGetDescent(font)
			self.contentHeight = CTFontGetAscent(font) + CTFontGetDescent(font)
		}

		private let contentHeight: Double

		var height: Double {
			Double(lines.count) * lineHeight
		}

		/**
		Draws each line on its baseline. Like in CSS, the extra line height is split above and below the text.
		*/
		func draw(in context: CGContext, x: Double, top: Double) {
			for (index, line) in lines.enumerated() {
				let lineTop = top + Double(index) * lineHeight
				context.textPosition = CGPoint(x: x, y: lineTop + (lineHeight - contentHeight) / 2 + ascent)
				CTLineDraw(line, context)
			}
		}
	}

	/**
	Wraps the text to the text width at word boundaries.
	*/
	private static func lines(_ text: String, font: CTFont, color: CGColor, maximumLines: Int) -> [CTLine] {
		let attributes: [NSAttributedString.Key: Any] = [
			NSAttributedString.Key(kCTFontAttributeName as String): font,
			NSAttributedString.Key(kCTForegroundColorAttributeName as String): color,
		]

		let attributedText = NSAttributedString(string: text, attributes: attributes)
		let typesetter = CTTypesetterCreateWithAttributedString(attributedText)
		var lines = [CTLine]()
		var start = 0

		while start < attributedText.length {
			let count = CTTypesetterSuggestLineBreak(typesetter, start, textWidth)

			guard lines.count < maximumLines - 1 || start + count >= attributedText.length else {
				// The last line gets the rest of the text, cut off with an ellipsis.
				let rest = CTTypesetterCreateLine(typesetter, CFRange(location: start, length: attributedText.length - start))
				let ellipsis = CTLineCreateWithAttributedString(NSAttributedString(string: "…", attributes: attributes))
				lines.append(CTLineCreateTruncatedLine(rest, textWidth, .end, ellipsis) ?? rest)
				break
			}

			lines.append(CTTypesetterCreateLine(typesetter, CFRange(location: start, length: count)))
			start += count
		}

		return lines
	}

	private enum FontWeight: String {
		case regular = "Inter-Regular"
		case bold = "Inter-Bold"
	}

	private static func font(_ weight: FontWeight, size: Double) throws -> CTFont {
		guard
			let url = Bundle.module.url(forResource: weight.rawValue, withExtension: "ttf", subdirectory: "Fonts"),
			let descriptor = (CTFontManagerCreateFontDescriptorsFromURL(url as CFURL) as? [CTFontDescriptor])?.first
		else {
			throw OpenGraphCardError(path: "/og", message: "The bundled font \(weight.rawValue) is missing.")
		}

		return CTFontCreateWithFontDescriptor(descriptor, size, nil)
	}
}

extension OpenGraphCard {
	static let site = path(for: "sindre-sorhus")

	/**
	The card for the home page and the pages without their own card.
	*/
	static func site(project: Project) -> Self {
		Self(path: site, title: Site.name, subtitle: Site.description, image: project.publicFile(Site.author.photoPath))
	}

	static func path(for app: App) -> RoutePath {
		path(for: app.slug)
	}

	static func path(for post: BlogPost) -> RoutePath {
		RoutePath("/og/blog").appending("\(post.slug).png")
	}

	private static func path(for slug: String) -> RoutePath {
		RoutePath("/og").appending("\(slug).png")
	}

	init(app: App, project: Project) {
		self.init(path: Self.path(for: app), title: app.title, subtitle: app.subtitle, image: project.publicFile(app.iconPath))
	}

	init(post: BlogPost, project: Project) {
		self.init(path: Self.path(for: post), title: post.title, subtitle: post.description ?? "Blog post by \(Site.name)", image: project.publicFile(Site.author.photoPath))
	}
}

struct OpenGraphCardError: Error, CustomStringConvertible {
	let path: RoutePath
	let message: String

	var description: String {
		"Could not render the social card \(path): \(message)"
	}
}

extension CGColor {
	/**
	An sRGB color from a hex value, like `0x0F172A`.
	*/
	fileprivate static func hex(_ value: Int) -> CGColor {
		CGColor(srgbRed: Double((value >> 16) & 0xFF) / 255, green: Double((value >> 8) & 0xFF) / 255, blue: Double(value & 0xFF) / 255, alpha: 1)
	}
}
