import CoreGraphics
import CoreText
import Foundation
import ImageIO
import SiteKit
import UniformTypeIdentifiers

/**
The 1200×630 preview image for social media: an image, the title, the subtitle, and the domain, drawn with Core Graphics and saved as JPEG.

The text uses the bundled Inter font, so a card looks the same on every machine.
*/
struct OpenGraphCard: RouteConvertible {
	let path: RoutePath
	let title: String
	let subtitle: String

	/**
	A PNG or JPEG shown next to the text. When it cannot be read, like for a new app without an icon yet, the space only has the shadow.
	*/
	let image: URL

	/**
	What the card shows, for people who cannot see it, like “Dato app”.
	*/
	let description: String

	var route: Route {
		.file(path) {
			try renderJPEG()
		}
	}

	/**
	The size of the card, which the `og:image:width` and `og:image:height` tags of each page give too.
	*/
	static let width = 1200
	static let height = 630
	private static let textX = 344.0
	private static let textWidth = 776.0
	private static let imageFrame = CGRect(x: 80, y: 215, width: 200, height: 200)
	private static let imageCornerRadius = 46.0

	func renderJPEG() throws -> Data {
		guard
			let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
			let context = CGContext(data: nil, width: Self.width, height: Self.height, bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue),
			let background = Self.background
		else {
			throw OpenGraphCardError.couldNotDraw
		}

		context.draw(background, in: CGRect(x: 0, y: 0, width: Self.width, height: Self.height))

		// The origin is at the top left, like in the design.
		context.translateBy(x: 0, y: Double(Self.height))
		context.scaleBy(x: 1, y: -1)

		if let picture = CGImageSourceCreateWithURL(image as CFURL, nil).flatMap({ CGImageSourceCreateImageAtIndex($0, 0, nil) }) {
			drawImage(picture, in: context)
		}

		try drawText(in: context)

		guard let cardImage = context.makeImage() else {
			throw OpenGraphCardError.couldNotDraw
		}

		let data = NSMutableData()

		guard let destination = CGImageDestinationCreateWithData(data, UTType.jpeg.identifier as CFString, 1, nil) else {
			throw OpenGraphCardError.couldNotEncode
		}

		CGImageDestinationAddImage(destination, cardImage, [kCGImageDestinationLossyCompressionQuality: 0.9] as CFDictionary)

		guard CGImageDestinationFinalize(destination) else {
			throw OpenGraphCardError.couldNotEncode
		}

		return data as Data
	}

	/**
	The part that every card has: the gradient and the shadow of the image. Drawing the large, soft shadow is the slow part of a card, so it is drawn once.
	*/
	private static let background: CGImage? = {
		guard
			let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
			let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue),
			let gradient = CGGradient(colorsSpace: colorSpace, colors: [CGColor.hex(0xF8FAFC), CGColor.hex(0xE2E8F0)] as CFArray, locations: [0, 1])
		else {
			return nil
		}

		context.translateBy(x: 0, y: Double(height))
		context.scaleBy(x: 1, y: -1)

		// A 135° gradient, like `linear-gradient(135deg, …)` in CSS. CSS makes the gradient line long enough for the corners to get the end colors.
		let halfLength = (Double(width) + Double(height)) * 0.5.squareRoot() / 2
		let offset = halfLength * 0.5.squareRoot()
		let center = CGPoint(x: Double(width) / 2, y: Double(height) / 2)
		context.drawLinearGradient(gradient, start: CGPoint(x: center.x - offset, y: center.y - offset), end: CGPoint(x: center.x + offset, y: center.y + offset), options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])

		// Like `box-shadow: 0 20px 60px`. Only the shadow is drawn: the square is outside the card, and the shadow offset moves the shadow back to the image. Shadow offsets ignore the flipped coordinates, so a negative height moves the shadow down.
		let distance = Double(width)
		context.setShadow(offset: CGSize(width: distance, height: -20), blur: 60, color: CGColor(gray: 0, alpha: 0.15))
		context.addPath(CGPath(roundedRect: imageFrame.offsetBy(dx: -distance, dy: 0), cornerWidth: imageCornerRadius, cornerHeight: imageCornerRadius, transform: nil))
		context.fillPath()

		return context.makeImage()
	}()

	/**
	Draws the image as a rounded square, filling the square like `object-fit: cover`.
	*/
	private func drawImage(_ picture: CGImage, in context: CGContext) {
		let frame = Self.imageFrame
		let scale = max(frame.width / Double(picture.width), frame.height / Double(picture.height))
		let size = CGSize(width: Double(picture.width) * scale, height: Double(picture.height) * scale)
		let imageFrame = CGRect(x: frame.midX - size.width / 2, y: frame.midY - size.height / 2, width: size.width, height: size.height)

		context.saveGState()
		context.addPath(CGPath(roundedRect: frame, cornerWidth: Self.imageCornerRadius, cornerHeight: Self.imageCornerRadius, transform: nil))
		context.clip()
		// Images draw upside down in flipped coordinates, so they are flipped back.
		context.translateBy(x: 0, y: imageFrame.minY + imageFrame.maxY)
		context.scaleBy(x: 1, y: -1)
		context.draw(picture, in: imageFrame)
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
			throw OpenGraphCardError.missingFont(weight.rawValue)
		}

		return CTFontCreateWithFontDescriptor(descriptor, size, nil)
	}
}

extension OpenGraphCard {
	/**
	The path of the card for the home page and the pages without their own card.
	*/
	static let sitePath: RoutePath = "/og/sindre-sorhus.jpg"

	/**
	The card for the home page and the pages without their own card.
	*/
	static func site(project: Project) -> Self {
		Self(path: sitePath, title: Site.name, subtitle: Site.description, image: project.publicFile(Site.author.photoPath), description: Site.name)
	}

	init(app: App, project: Project) {
		self.init(path: RoutePath("/og").appending("\(app.slug).jpg"), title: app.title, subtitle: app.subtitle, image: project.publicFile(app.iconPath), description: "\(app.title) app")
	}

	init(post: BlogPost, project: Project) {
		self.init(path: RoutePath("/og/blog").appending("\(post.slug).jpg"), title: post.title, subtitle: post.description ?? "Blog post by \(Site.name)", image: project.publicFile(Site.author.photoPath), description: post.title)
	}
}

enum OpenGraphCardError: Error, CustomStringConvertible {
	case couldNotDraw
	case couldNotEncode
	case missingFont(String)

	var description: String {
		switch self {
		case .couldNotDraw:
			"Could not draw the card."
		case .couldNotEncode:
			"Could not encode the JPEG."
		case .missingFont(let name):
			"The bundled font \(name) is missing."
		}
	}
}
