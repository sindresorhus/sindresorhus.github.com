import CoreGraphics
import CoreText
import CryptoKit
import Foundation
import ImageIO
import SiteKit
import Synchronization
import UniformTypeIdentifiers

/**
The 1200×630 preview image for social media: the artwork, the title, the subtitle, and the domain (for a post, also its month and reading time), drawn with Core Graphics and saved as JPEG.

The text uses the bundled Inter font, so a card looks the same on every machine.
*/
struct OpenGraphCard: RouteConvertible {
	let path: RoutePath
	let title: String
	let subtitle: String
	let artwork: Artwork

	/**
	What the card shows, for people who cannot see it, like “Dato app”.
	*/
	let description: String

	/**
	The last line of the card, below the subtitle: the domain, and for a post also its month and reading time.
	*/
	var footer = Site.url.host() ?? ""

	/**
	The colors of the card (``Appearance``).
	*/
	var appearance = Appearance.light

	var route: Route {
		.file(path) {
			try cachedJPEG()
		}
	}

	/**
	What a card shows: its text, and its artwork with the size and modification date of each of its files.
	*/
	private struct CacheKey: Hashable {
		let title: String
		let subtitle: String
		let footer: String
		let artwork: Artwork
		let artworkFiles: [FileStamp]
		let appearance: Appearance
	}

	/**
	The JPEG of each card that the process drew, by what it shows, so a rebuild of `website serve` only draws the cards that changed. The drawing code does not change while the process runs, as a change of the sources restarts the tool.

	Limitation: the cache keeps the old version of each changed card until the process ends, which is about 100 KB for each card.
	*/
	private static let drawnCards = Mutex<[CacheKey: Data]>([:])

	fileprivate func cachedJPEG() throws -> Data {
		let artworkFiles: [URL] = switch artwork {
		case .image(let file):
			[file]
		case .appScreenshot(let icon, let screenshot):
			[icon, screenshot]
		case .icons(let files):
			files
		case .calendars:
			[]
		}

		let key = CacheKey(
			title: title,
			subtitle: subtitle,
			footer: footer,
			artwork: artwork,
			artworkFiles: artworkFiles.map { FileStamp($0) },
			appearance: appearance
		)

		if let data = Self.drawnCards.withLock({ $0[key] }) {
			return data
		}

		let data = try renderJPEG()
		Self.drawnCards.withLock { $0[key] = data }
		return data
	}

	/**
	The image of a card, from PNG or JPEG files. A file that cannot be read, like the icon of a new app that has none yet, is left out.
	*/
	enum Artwork: Hashable {
		/**
		An image next to the text, like the icon of an app. When it cannot be read, the space only has the shadow.
		*/
		case image(URL)

		/**
		The icon of an app above the text, and its first screenshot on the right, whole, so a shared link shows what the app looks like.
		*/
		case appScreenshot(icon: URL, screenshot: URL)

		/**
		App icons in a row above the text, on a slight arc, like for a category.
		*/
		case icons([URL])

		/**
		Contribution calendars in a grid above the text, like the patches of the career quilt.
		*/
		case calendars([ContributionCalendar.Plot])

		/**
		The photo of Sindre, for the cards of the site, of the posts, and of the other pages.
		*/
		static func authorPhoto(project: Project) -> Self {
			.image(project.publicFile(Site.author.photoPath))
		}

		/**
		The icon of an app, for the card of a guide about it and of its release notes.
		*/
		static func icon(of app: App, project: Project) -> Self {
			.image(project.publicFile(app.iconPath))
		}

		/**
		The icon and the first screenshot of an app, for the card of the app, or only the icon for an app without a screenshot.
		*/
		static func screenshot(of app: App, project: Project) -> Self {
			guard let screenshot = app.screenshots.first else {
				return icon(of: app, project: project)
			}

			return .appScreenshot(icon: project.publicFile(app.iconPath), screenshot: project.publicFile(screenshot.path))
		}

		/**
		The icons of the first apps, as many as the card shows.
		*/
		static func icons(of apps: [App], project: Project) -> Self {
			.icons(apps.prefix(iconRowCount).map { project.publicFile($0.iconPath) })
		}

		/**
		The icons of the apps that are most often in the list, like the apps of the guides, the app with the most first, and by title for the same number, so the card is the same in each build.
		*/
		static func icons(ofMostCommon apps: [App], project: Project) -> Self {
			icons(of: apps.mostCommonFirst.map(\.app), project: project)
		}

		/**
		The calendars of the days, like the years of the career quilt, in the colors of the scale.
		*/
		static func calendars(of calendars: [[ContributionCalendar.Day]], scale: ContributionScale) -> Self {
			.calendars(calendars.map { days in
				ContributionCalendar.Plot(days: days, scale: scale)
			})
		}

	}

	/**
	The colors of a card: light, like the site in light mode, or dark, like the site in dark mode, for the share dialog of an app page in dark mode (``AppHero``), so the preview is not a bright card in the dark dialog. The pages give the light card to link previews (`og:image`), as other apps show a preview in their own look.
	*/
	enum Appearance: Hashable, CaseIterable {
		case light
		case dark

		/**
		The colors of the 135° gradient of the background, from the top left to the bottom right.
		*/
		fileprivate var backgroundColors: [CGColor] {
			switch self {
			case .light:
				[.hex(0xF8FAFC), .hex(0xE2E8F0)]
			case .dark:
				// The dark page of the site (``SemanticColor/pageBackgroundColors``) at the bottom right, and a little lighter at the top left, in the same blue hue, like the light gradient.
				[.hex(0x181B20), .hex(0x07090E)]
			}
		}

		fileprivate var titleColor: CGColor {
			switch self {
			case .light:
				.hex(0x0F172A)
			case .dark:
				.hex(0xF1F5F9)
			}
		}

		fileprivate var subtitleColor: CGColor {
			switch self {
			case .light:
				.hex(0x64748B)
			case .dark:
				.hex(0x94A3B8)
			}
		}

		fileprivate var footerColor: CGColor {
			switch self {
			case .light:
				.hex(0x94A3B8)
			case .dark:
				.hex(0x64748B)
			}
		}
	}

	/**
	The size of the card, which the `og:image:width` and `og:image:height` tags of each page give too.
	*/
	static let width = 1200
	static let height = 630
	private static let bounds = CGRect(
		x: 0,
		y: 0,
		width: width,
		height: height
	)

	/**
	The space at the sides of the card.
	*/
	private static let margin = 80.0

	private static let imageFrame = CGRect(
		x: margin,
		y: 215,
		width: 200,
		height: 200
	)

	/**
	The text is to the right of the image.
	*/
	private static let textX = 344.0

	/**
	The icon above the text of a card with a screenshot, and the space below it.
	*/
	private static let screenshotCardIconSize = 112.0
	private static let screenshotCardIconMargin = 32.0

	/**
	The width of the text of a card with a screenshot, which leaves the right side to the screenshot.
	*/
	private static let screenshotCardTextWidth = 480.0

	/**
	The largest size of the screenshot, and its space to the right edge, like the margin of the text at the left, but a little smaller, as the screenshot is wider than the text.
	*/
	private static let screenshotMaximumWidth = 560.0
	private static let screenshotMaximumHeight = 470.0
	private static let screenshotMargin = 64.0
	private static let screenshotCornerRadius = 14.0

	/**
	The size of the middle icon of a row, and how much each icon overlaps the next one. All seven icons fit on the card.
	*/
	private static let iconSize = 150.0
	private static let iconOverlap = 24.0
	private static let iconRowCount = 7

	/**
	The space between the row of icons and the title.
	*/
	private static let iconRowMargin = 48.0

	/**
	The least space above a row of icons and below the text below it. A long text, like a title of two lines and a long description, makes the row smaller (``renderJPEG()``), so the icons are not cut at the edge, also when a social app puts rounded corners and a border on the card.
	*/
	private static let minimumVerticalMargin = 48.0

	/**
	The corner radius of an icon on the grid of Apple, about 23% of its size, like the icons on the site.
	*/
	private static func cornerRadius(ofIconSize size: Double) -> Double {
		size * 0.23
	}

	func renderJPEG() throws -> Data {
		guard let context = Self.makeContext() else {
			throw OpenGraphCardError.couldNotDraw
		}

		// The background of the image, or a plain one below a row of icons or the calendars.
		let background = switch artwork {
		case .image:
			Self.imageBackgrounds[appearance]
		case .appScreenshot, .icons, .calendars:
			Self.plainBackgrounds[appearance]
		}

		guard let background else {
			throw OpenGraphCardError.couldNotDraw
		}

		context.draw(background, in: Self.bounds)
		context.flipToTopLeftOrigin()
		let text = try textColumn()

		// Draws the artwork of the height, and the text below it, with the space between them.
		func drawAboveText(height: Double, spacing: Double, drawArtwork: (_ top: Double) -> Void) {
			let top = (Double(Self.height) - height - spacing - text.height) / 2
			drawArtwork(top)
			text.draw(in: context, x: Self.margin, top: top + height + spacing)
		}

		switch artwork {
		case .image(let url):
			if let picture = CGImage.read(url) {
				Self.draw(
					picture,
					in: context,
					frame: Self.imageFrame,
					cornerRadius: Self.cornerRadius(ofIconSize: Self.imageFrame.width)
				)
			}

			// Vertically centered.
			text.draw(in: context, x: Self.textX, top: (Double(Self.height) - text.height) / 2)
		case .appScreenshot(let iconURL, let screenshotURL):
			// The whole screenshot, as large as it fits, at the right, and vertically centered. Like `box-shadow: 0 20px 60px`.
			if let screenshot = CGImage.read(screenshotURL) {
				let scale = min(Self.screenshotMaximumWidth / Double(screenshot.width), Self.screenshotMaximumHeight / Double(screenshot.height))
				let size = CGSize(width: Double(screenshot.width) * scale, height: Double(screenshot.height) * scale)
				let frame = CGRect(
					x: Double(Self.width) - Self.screenshotMargin - size.width,
					y: (Double(Self.height) - size.height) / 2,
					width: size.width,
					height: size.height
				)

				Self.drawShadow(
					of: frame,
					cornerRadius: Self.screenshotCornerRadius,
					offset: 20,
					blur: 60,
					opacity: 0.2,
					in: context
				)
				Self.draw(
					screenshot,
					in: context,
					frame: frame,
					cornerRadius: Self.screenshotCornerRadius
				)
			}

			// The icon and the text below it are vertically centered together. Like `box-shadow: 0 12px 36px`.
			drawAboveText(height: Self.screenshotCardIconSize, spacing: Self.screenshotCardIconMargin) { top in
				let frame = CGRect(
					x: Self.margin,
					y: top,
					width: Self.screenshotCardIconSize,
					height: Self.screenshotCardIconSize
				)
				let cornerRadius = Self.cornerRadius(ofIconSize: frame.width)

				Self.drawShadow(
					of: frame.insetBy(dx: 2, dy: 2),
					cornerRadius: cornerRadius,
					offset: 12,
					blur: 36,
					opacity: 0.15,
					in: context
				)

				if let icon = CGImage.read(iconURL) {
					Self.draw(
						icon,
						in: context,
						frame: frame,
						cornerRadius: cornerRadius
					)
				}
			}
		case .icons(let urls):
			// The row and the text below it are vertically centered together. With a long text, the row and the space below it are smaller, so the vertical margin stays (``minimumVerticalMargin``), but not smaller than 70%, so the icons stay clear.
			let icons = urls.compactMap(CGImage.read)
			let rowHeight = Self.iconRowHeight(count: icons.count)
			let availableHeight = Double(Self.height) - Self.minimumVerticalMargin * 2 - text.height
			let scale = min(1, max(0.7, availableHeight / (rowHeight + Self.iconRowMargin)))

			drawAboveText(height: rowHeight * scale, spacing: Self.iconRowMargin * scale) { top in
				Self.drawIconRow(icons, in: context, top: top, iconSize: Self.iconSize * scale)
			}
		case .calendars(let calendars):
			// The grid and the text below it are vertically centered together, like a row of icons.
			let grid = CalendarGrid(calendars: calendars)

			drawAboveText(height: grid.height, spacing: Self.iconRowMargin) { top in
				grid.draw(in: context, top: top)
			}
		}

		guard let cardImage = context.makeImage() else {
			throw OpenGraphCardError.couldNotDraw
		}

		let data = NSMutableData()

		guard let destination = CGImageDestinationCreateWithData(
			data,
			UTType.jpeg.identifier as CFString,
			1,
			nil
		) else {
			throw OpenGraphCardError.couldNotEncode
		}

		CGImageDestinationAddImage(destination, cardImage, [kCGImageDestinationLossyCompressionQuality: 0.9] as CFDictionary)

		guard CGImageDestinationFinalize(destination) else {
			throw OpenGraphCardError.couldNotEncode
		}

		return data as Data
	}

	/**
	An empty card, without alpha, in sRGB.
	*/
	private static func makeContext() -> CGContext? {
		guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else {
			return nil
		}

		return CGContext(
			data: nil,
			width: width,
			height: height,
			bitsPerComponent: 8,
			bytesPerRow: 0,
			space: colorSpace,
			bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
		)
	}

	/**
	The gradient that every card has, drawn once for each appearance.
	*/
	private static let plainBackgrounds: [Appearance: CGImage] = Dictionary(
		uniqueKeysWithValues: Appearance.allCases.compactMap { appearance in
			plainBackground(appearance).map { (appearance, $0) }
		}
	)

	/**
	The gradient and the shadow of the image of a card with an image, drawn once for each appearance, as drawing the large, soft shadow is the slow part of a card.
	*/
	private static let imageBackgrounds: [Appearance: CGImage] = Dictionary(
		uniqueKeysWithValues: Appearance.allCases.compactMap { appearance in
			imageBackground(appearance).map { (appearance, $0) }
		}
	)

	/**
	The gradient that every card of the appearance has.
	*/
	private static func plainBackground(_ appearance: Appearance) -> CGImage? {
		guard
			let context = makeContext(),
			let gradient = CGGradient(colorsSpace: context.colorSpace, colors: appearance.backgroundColors as CFArray, locations: [0, 1])
		else {
			return nil
		}

		context.flipToTopLeftOrigin()

		// A 135° gradient, like `linear-gradient(135deg, …)` in CSS. CSS makes the gradient line long enough for the corners to get the end colors.
		let halfLength = (Double(width) + Double(height)) * 0.5.squareRoot() / 2
		let offset = halfLength * 0.5.squareRoot()
		let center = CGPoint(x: Double(width) / 2, y: Double(height) / 2)
		context.drawLinearGradient(
			gradient,
			start: CGPoint(x: center.x - offset, y: center.y - offset),
			end: CGPoint(x: center.x + offset, y: center.y + offset),
			options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
		)

		return context.makeImage()
	}

	/**
	The gradient of the appearance and the shadow of the image of a card with an image.
	*/
	private static func imageBackground(_ appearance: Appearance) -> CGImage? {
		guard
			let plainBackground = plainBackgrounds[appearance],
			let context = makeContext()
		else {
			return nil
		}

		context.draw(plainBackground, in: bounds)
		context.flipToTopLeftOrigin()

		// Like `box-shadow: 0 20px 60px`. Only the shadow is drawn: the square is outside the card, and the shadow offset moves the shadow back to the image. Shadow offsets ignore the flipped coordinates, so a negative height moves the shadow down.
		let distance = Double(width)
		context.setShadow(offset: CGSize(width: distance, height: -20), blur: 60, color: CGColor(gray: 0, alpha: 0.15))
		context.addPath(
			CGPath(
				roundedRect: imageFrame.offsetBy(dx: -distance, dy: 0),
				cornerWidth: cornerRadius(ofIconSize: imageFrame.width),
				cornerHeight: cornerRadius(ofIconSize: imageFrame.width),
				transform: nil
			)
		)
		context.fillPath()

		return context.makeImage()
	}

	/**
	The height of a row of icons of the full size, with the lower icons at the ends of the arc.
	*/
	private static func iconRowHeight(count: Int) -> Double {
		iconSize * (1 + IconArc(index: 0, count: count).drop)
	}

	/**
	Draws the icons from the left on a slight arc (``IconArc``), like the icons at the top of a category page, each overlapping the next one. The icons nearer the middle are in front, so they are drawn last, each with a soft shadow.

	- Parameter iconSize: The size of the middle icon, which is smaller than ``iconSize`` when the text is long.
	*/
	private static func drawIconRow(
		_ icons: [CGImage],
		in context: CGContext,
		top: Double,
		iconSize: Double
	) {
		let iconOverlap = Self.iconOverlap * iconSize / Self.iconSize
		let row = icons.enumerated().map { (icon: $0.element, index: $0.offset, arc: IconArc(index: $0.offset, count: icons.count)) }

		for (icon, index, arc) in row.sorted(using: KeyPathComparator(\.arc.zIndex)) {
			let size = iconSize * arc.scale
			let center = CGPoint(
				x: margin + iconSize / 2 + Double(index) * (iconSize - iconOverlap),
				y: top + iconSize / 2 + iconSize * arc.drop
			)
			let frame = CGRect(
				x: -size / 2,
				y: -size / 2,
				width: size,
				height: size
			)
			let cornerRadius = cornerRadius(ofIconSize: size)

			context.withSavedState {
				context.translateBy(x: center.x, y: center.y)
				context.rotate(by: arc.turnInDegrees * .pi / 180)

				// Like `box-shadow: 0 12px 36px`, below the icon. Shadow offsets ignore the turn too, so the shadow stays below the icon.
				drawShadow(
					of: frame.insetBy(dx: 2, dy: 2),
					cornerRadius: cornerRadius,
					offset: 12,
					blur: 36,
					opacity: 0.18,
					in: context
				)

				draw(
					icon,
					in: context,
					frame: frame,
					cornerRadius: cornerRadius
				)
			}
		}
	}

	/**
	Draws the soft shadow of a rounded rectangle, like `box-shadow: 0 <offset>px <blur>px`, for an image that is drawn over it. The rectangle is white, so the shadow does not show through the edge of the image.
	*/
	private static func drawShadow(
		of frame: CGRect,
		cornerRadius: Double,
		offset: Double,
		blur: Double,
		opacity: Double,
		in context: CGContext
	) {
		context.withSavedState {
			// Shadow offsets ignore the flipped coordinates, so a negative height moves the shadow down.
			context.setShadow(offset: CGSize(width: 0, height: -offset), blur: blur, color: CGColor(gray: 0, alpha: opacity))
			context.setFillColor(CGColor(gray: 1, alpha: 1))
			context.addPath(
				CGPath(
					roundedRect: frame,
					cornerWidth: cornerRadius,
					cornerHeight: cornerRadius,
					transform: nil
				)
			)
			context.fillPath()
		}
	}

	/**
	Draws the image as a rounded rectangle, filling the rectangle like `object-fit: cover`.
	*/
	private static func draw(
		_ picture: CGImage,
		in context: CGContext,
		frame: CGRect,
		cornerRadius: Double
	) {
		let scale = max(frame.width / Double(picture.width), frame.height / Double(picture.height))
		let size = CGSize(width: Double(picture.width) * scale, height: Double(picture.height) * scale)
		let imageFrame = CGRect(
			x: frame.midX - size.width / 2,
			y: frame.midY - size.height / 2,
			width: size.width,
			height: size.height
		)

		context.withSavedState {
			// The icons are larger than the card shows them.
			context.interpolationQuality = .high
			context.addPath(
				CGPath(
					roundedRect: frame,
					cornerWidth: cornerRadius,
					cornerHeight: cornerRadius,
					transform: nil
				)
			)
			context.clip()
			// Images draw upside down in flipped coordinates, so they are flipped back.
			context.translateBy(x: 0, y: imageFrame.minY + imageFrame.maxY)
			context.scaleBy(x: 1, y: -1)
			context.draw(picture, in: imageFrame)
		}
	}

	/**
	Contribution calendars in a grid of up to five columns, as wide as the text, like the patches of the career quilt. Each calendar is a white patch with a column of days for each week.
	*/
	private struct CalendarGrid {
		private static let maximumColumnCount = 5
		private static let gap = 12.0
		private static let cornerRadius = 10.0

		let calendars: [ContributionCalendar.Plot]
		let columnCount: Int
		let rowCount: Int
		let patchWidth: Double

		/**
		The space between the edge of a patch and its days, and the distance from one day to the next.
		*/
		let padding: Double
		let pitch: Double

		init(calendars: [ContributionCalendar.Plot]) {
			self.calendars = calendars
			self.columnCount = max(1, min(calendars.count, Self.maximumColumnCount))
			self.rowCount = (calendars.count + columnCount - 1) / columnCount
			self.patchWidth = (Double(OpenGraphCard.width) - OpenGraphCard.margin * 2 - Self.gap * Double(columnCount - 1)) / Double(columnCount)
			self.padding = patchWidth / 40

			// A year has 53 weeks, or 54 when it starts late in the week, so all the calendars have the same size.
			let weekCount = max(53, calendars.map { ($0.dayCount + 6) / 7 }.max() ?? 0)
			self.pitch = (patchWidth - padding * 2) / Double(weekCount)
		}

		private var daySize: Double {
			pitch * 0.8
		}

		private var patchHeight: Double {
			padding * 2 + pitch * 6 + daySize
		}

		var height: Double {
			guard rowCount > 0 else {
				return 0
			}

			return Double(rowCount) * patchHeight + Double(rowCount - 1) * Self.gap
		}

		/**
		Draws each calendar as a patch, from the left, row by row, with a soft shadow, and a rounded square for each day, in the light colors of the heatmaps of the site (``ContributionHeatmap``).
		*/
		func draw(in context: CGContext, top: Double) {
			for (index, calendar) in calendars.enumerated() {
				let patch = CGRect(
					x: OpenGraphCard.margin + Double(index % columnCount) * (patchWidth + Self.gap),
					y: top + Double(index / columnCount) * (patchHeight + Self.gap),
					width: patchWidth,
					height: patchHeight
				)

				// Like `box-shadow: 0 4px 12px`. Shadow offsets ignore the flipped coordinates, so a negative height moves the shadow down.
				context.withSavedState {
					context.setShadow(offset: CGSize(width: 0, height: -4), blur: 12, color: CGColor(gray: 0, alpha: 0.08))
					context.setFillColor(CGColor(gray: 1, alpha: 1))
					context.addPath(
						CGPath(
							roundedRect: patch,
							cornerWidth: Self.cornerRadius,
							cornerHeight: Self.cornerRadius,
							transform: nil
						)
					)
					context.fillPath()
				}

				// The days start after the blanks of the first week.
				for (dayIndex, level) in zip(calendar.blankDayCount..., calendar.levels) {
					let day = CGRect(
						x: patch.minX + padding + Double(dayIndex / 7) * pitch,
						y: patch.minY + padding + Double(dayIndex % 7) * pitch,
						width: daySize,
						height: daySize
					)

					context.setFillColor(level.cardColor)
					context.addPath(
						CGPath(
							roundedRect: day,
							cornerWidth: daySize * 0.2,
							cornerHeight: daySize * 0.2,
							transform: nil
						)
					)
					context.fillPath()
				}
			}
		}
	}

	/**
	The width of the text: next to the image, at the left of a screenshot, or the width of the card below a row of icons or the calendars.
	*/
	private var textWidth: Double {
		switch artwork {
		case .image:
			Double(Self.width) - Self.textX - Self.margin
		case .appScreenshot:
			Self.screenshotCardTextWidth
		case .icons, .calendars:
			Double(Self.width) - Self.margin * 2
		}
	}

	/**
	The title and the subtitle get smaller when they are longer than three lines, so a guide keeps the name of its app at the end of its description. At the smallest size, they are cut off with an ellipsis after three lines (``cutTexts()``).
	*/
	private var titleBlock: TextBlock {
		get throws {
			try TextBlock(
				fitting: title,
				sizes: [68, 60, 54],
				weight: .bold,
				color: appearance.titleColor,
				width: textWidth,
				lineHeightMultiple: 1.1,
				isBalanced: true
			)
		}
	}

	/**
	The subtitle of a card with an image is larger when it fits, as a chat shows the card small, like 300 pixels wide on a phone. Below a row of icons or the calendars, it stays smaller, as a taller text makes the row smaller.
	*/
	private var subtitleBlock: TextBlock {
		get throws {
			let sizes: [Double] = switch artwork {
			case .image, .appScreenshot:
				[40, 36, 32, 29]
			case .icons, .calendars:
				[32, 29]
			}

			return try TextBlock(
				fitting: subtitle,
				sizes: sizes,
				weight: .regular,
				color: appearance.subtitleColor,
				width: textWidth,
				lineHeightMultiple: 1.4
			)
		}
	}

	/**
	The title, the subtitle, and the footer as a column, laid out like CSS line boxes. Long texts wrap to the width.
	*/
	private func textColumn() throws -> TextColumn {
		TextColumn(blocks: [
			(try titleBlock, marginAfter: 20),
			(try subtitleBlock, marginAfter: 48),
			(
				try TextBlock(
					footer,
					font: Self.font(.bold, size: 22),
					color: appearance.footerColor,
					width: textWidth,
					maximumLines: 1
				),
				marginAfter: 0
			),
		])
	}

	/**
	Whether the card cuts off its title or its subtitle with an ellipsis, as it is longer than three lines at the smallest size. It only breaks the lines, without drawing the card.
	*/
	func cutTexts() throws -> (title: Bool, subtitle: Bool) {
		(try titleBlock.isCut, try subtitleBlock.isCut)
	}

	/**
	Text blocks below each other, each with its space below.
	*/
	private struct TextColumn {
		let blocks: [(block: TextBlock, marginAfter: Double)]

		var height: Double {
			blocks.map { $0.block.height + $0.marginAfter }.reduce(0, +)
		}

		func draw(in context: CGContext, x: Double, top: Double) {
			context.textMatrix = CGAffineTransform(scaleX: 1, y: -1)
			var top = top

			for (block, marginAfter) in blocks {
				block.draw(in: context, x: x, top: top)
				top += block.height + marginAfter
			}
		}
	}

	/**
	Lines of text with the same font and line height.
	*/
	private struct TextBlock {
		let lines: [CTLine]

		/**
		Whether the text is longer than the lines, so the last line is cut off with an ellipsis.
		*/
		let isCut: Bool

		let ascent: Double
		let lineHeight: Double
		private let contentHeight: Double

		/**
		Wraps the text to the width at word boundaries.

		- Parameter lineHeight: The height of each line. `nil` uses the normal line height of the font.
		*/
		init(
			_ text: String,
			font: CTFont,
			color: CGColor,
			width: Double,
			maximumLines: Int,
			lineHeight: Double? = nil
		) {
			let attributes: [NSAttributedString.Key: Any] = [
				NSAttributedString.Key(kCTFontAttributeName as String): font,
				NSAttributedString.Key(kCTForegroundColorAttributeName as String): color,
			]

			let attributedText = NSAttributedString(string: text, attributes: attributes)
			let typesetter = CTTypesetterCreateWithAttributedString(attributedText)
			var lines = [CTLine]()
			var start = 0
			var isCut = false

			while start < attributedText.length {
				let count = CTTypesetterSuggestLineBreak(typesetter, start, width)

				guard lines.count < maximumLines - 1 || start + count >= attributedText.length else {
					// The last line gets the rest of the text, cut off with an ellipsis.
					let rest = CTTypesetterCreateLine(typesetter, CFRange(location: start, length: attributedText.length - start))
					let ellipsis = CTLineCreateWithAttributedString(NSAttributedString(string: "…", attributes: attributes))
					lines.append(
						CTLineCreateTruncatedLine(
							rest,
							width,
							.end,
							ellipsis
						) ?? rest
					)
					isCut = true
					break
				}

				lines.append(CTTypesetterCreateLine(typesetter, CFRange(location: start, length: count)))
				start += count
			}

			self.lines = lines
			self.isCut = isCut
			self.ascent = CTFontGetAscent(font)
			self.contentHeight = CTFontGetAscent(font) + CTFontGetDescent(font)
			self.lineHeight = lineHeight ?? contentHeight
		}

		/**
		The text at the first of the sizes where it fits in three lines and its longest word fits on a line, or else at the last size, cut off with an ellipsis. A line never breaks inside a word, like “Pasteboa / rd”, when the word fits.

		- Parameter sizes: The font sizes to try, largest first.
		- Parameter lineHeightMultiple: The line height as a multiple of the font size.
		- Parameter isBalanced: Whether the lines have about the same length, like `text-wrap: balance` in CSS, so the last line is not one word alone, like “Screen”. The lines break at the narrowest width that keeps their number, and the text stays at the start.
		*/
		init(
			fitting text: String,
			sizes: [Double],
			weight: FontWeight,
			color: CGColor,
			width: Double,
			lineHeightMultiple: Double,
			isBalanced: Bool = false
		) throws {
			for (index, size) in sizes.enumerated() {
				let font = try OpenGraphCard.font(weight, size: size)

				func wrapping(at width: Double) -> Self {
					Self(
						text,
						font: font,
						color: color,
						width: width,
						maximumLines: 3,
						lineHeight: size * lineHeightMultiple
					)
				}

				let block = wrapping(at: width)

				// The width of the longest word, as the lines must not be narrower.
				let longestWordWidth = text.split(whereSeparator: \.isWhitespace).map { word in
					let line = CTLineCreateWithAttributedString(NSAttributedString(string: String(word), attributes: [NSAttributedString.Key(kCTFontAttributeName as String): font]))
					return CTLineGetTypographicBounds(line, nil, nil, nil)
				}.max() ?? 0

				guard
					(!block.isCut && longestWordWidth <= width) || index == sizes.count - 1
				else {
					continue
				}

				guard
					isBalanced,
					!block.isCut,
					block.lines.count > 1
				else {
					self = block
					return
				}

				// The lines cannot be narrower than the width divided by their number or than the longest word, so the search is between that width and the whole width, to about a point.
				var narrowestWidth = width
				var tooNarrowWidth = max(width / Double(block.lines.count), longestWordWidth)

				while narrowestWidth - tooNarrowWidth > 1 {
					let middle = (narrowestWidth + tooNarrowWidth) / 2
					let candidate = wrapping(at: middle)

					if
						!candidate.isCut,
						candidate.lines.count == block.lines.count
					{
						narrowestWidth = middle
					} else {
						tooNarrowWidth = middle
					}
				}

				self = wrapping(at: narrowestWidth)
				return
			}

			throw OpenGraphCardError.couldNotDraw
		}

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

	private enum FontWeight: String, CaseIterable {
		case regular = "Inter-Regular"
		case bold = "Inter-Bold"
	}

	/**
	The fonts in the bundle, read once for all the cards. A font that cannot be read is left out. Font descriptors cannot change, so the cards can share them while they draw at the same time.
	*/
	nonisolated(unsafe) private static let fontDescriptors: [FontWeight: CTFontDescriptor] = Dictionary(uniqueKeysWithValues: FontWeight.allCases.compactMap { weight in
		guard
			let url = Bundle.module.url(forResource: weight.rawValue, withExtension: "ttf", subdirectory: "Fonts"),
			let descriptor = (CTFontManagerCreateFontDescriptorsFromURL(url as CFURL) as? [CTFontDescriptor])?.first
		else {
			return nil
		}

		return (weight, descriptor)
	})

	private static func font(_ weight: FontWeight, size: Double) throws -> CTFont {
		guard let descriptor = fontDescriptors[weight] else {
			throw OpenGraphCardError.missingFont(weight.rawValue)
		}

		return CTFontCreateWithFontDescriptor(descriptor, size, nil)
	}
}

extension OpenGraphCard {
	/**
	The path of the card for the home page and the pages without their own card.
	*/
	static let sitePath = #path("/og/sindre-sorhus.jpg")

	/**
	The card for the home page, the about page, the now page without a status, and the pages without a card of their own (``SocialImage/site``).
	*/
	static func site(project: Project) -> Self {
		Self(
			path: sitePath,
			title: Site.name,
			subtitle: Site.description,
			artwork: .authorPhoto(project: project),
			description: Site.name
		)
	}

	/**
	The path of the card of a page, in `/og` at the path of the page, like `/og/dato.jpg` for `/dato`, and `/og/dato-dark.jpg` for the dark card (``Appearance/dark``).
	*/
	static func path(ofPage path: RoutePath, appearance: Appearance = .light) -> RoutePath {
		let suffix = appearance == .dark ? "-dark" : ""
		return #path("/og").appending(path: "\(path.relativePath)\(suffix).jpg")
	}

	/**
	The text of the card of an app, for people who cannot see it: the name and the subtitle, like the card shows them. Other pages about the app share the card (``SocialImage/cardOf(_:)``).
	*/
	static func description(of app: App) -> String {
		"\(app.title): \(app.subtitle)"
	}

	/**
	- Parameter appearance: The colors of the card. The page gives the light card to link previews, and the share dialog of the page shows the dark card in dark mode (``AppHero``).
	*/
	init(app: App, project: Project, appearance: Appearance = .light) {
		self.init(
			path: Self.path(ofPage: app.path, appearance: appearance),
			title: app.title,
			subtitle: app.subtitle,
			artwork: .screenshot(of: app, project: project),
			description: Self.description(of: app),
			appearance: appearance
		)
	}

	/**
	A post has the month and the reading time after the domain, like the top of its page, so a shared link to an old post does not look new.
	*/
	init(post: BlogPost, project: Project) {
		self.init(
			path: Self.path(ofPage: post.path),
			title: post.title,
			subtitle: post.description ?? "Blog post by \(Site.name)",
			artwork: .authorPhoto(project: project),
			description: post.title
		)

		footer = [footer, post.publicationDate.foundationDate.formatted(.siteMonth), post.readingTimeText].joined(separator: " · ")
	}

	/**
	The card of a page without a card of its own, like the discounts page: the title and the description of the page next to the photo of Sindre, so a shared link says which page it is. The home page and the about page are about Sindre, so they keep the card of the site, and the now page has its status (``init(nowPage:now:project:)``).
	*/
	init(page: some Page, project: Project) {
		self.init(page: page, artwork: .authorPhoto(project: project))
	}

	/**
	The now page has its status as the subtitle, like “Trying out coffee shops in Thailand. …”, next to the photo of Sindre, so a shared link says what Sindre is working on now. The links of the status are only their text. `nil` without a status, so the page keeps the card of the site.
	*/
	init?(nowPage page: MarkdownPage, now: MarkdownPage.Now.Resolved, project: Project) {
		guard let status = now.status?.introduction else {
			return nil
		}

		self.init(
			path: Self.path(ofPage: page.path),
			title: page.title,
			subtitle: status,
			artwork: .authorPhoto(project: project),
			description: page.title
		)
	}

	/**
	The card of a page with its own artwork, like the patches of the career quilt.
	*/
	init(page: some Page, artwork: Artwork) {
		let metadata = page.metadata
		let title = metadata.title

		self.init(
			path: Self.path(ofPage: page.path),
			title: title,
			subtitle: metadata.description ?? Site.description,
			artwork: artwork,
			description: title
		)
	}

	/**
	A guide has the icon of its app, as it is about a task that the app does.
	*/
	init(guide: Guide, app: App, project: Project) {
		self.init(
			path: Self.path(ofPage: guide.path),
			title: guide.title,
			subtitle: guide.description,
			artwork: .icon(of: app, project: project),
			description: guide.title
		)
	}

	/**
	A category has the icons of its first apps, in the order of its page, and the description of its page, like “33 apps that live in the menu bar, like Dato, Velja, Plash, and Pure Paste, by Sindre Sorhus.” (``AppCategory/searchDescription(apps:featuredApps:)``).
	*/
	init(category: AppCategory, apps: [App], featuredApps: [App], project: Project) {
		self.init(
			path: Self.path(ofPage: category.path),
			title: category.title,
			subtitle: category.searchDescription(apps: apps, featuredApps: featuredApps),
			artwork: .icons(of: apps, project: project),
			description: category.title
		)
	}
}

/**
The preview image of a page for social media (`og:image`).
*/
enum SocialImage {
	/**
	The card of the site, for the pages without a card of their own.
	*/
	case site

	/**
	The card of the page, which is published with the page.
	*/
	case card(OpenGraphCard)

	/**
	The card of the page of an app, for another page about the app, like its privacy policy. Only the app page publishes it, so no card is published twice. An app with a page elsewhere has no card here, so its pages get the site card.
	*/
	case cardOf(App)

	/**
	The path of the card, and what the card shows, for people who cannot see it (`og:image:alt`), from one place, so they always match.
	*/
	private var target: (path: RoutePath, description: String) {
		switch self {
		case .card(let card):
			(card.path, card.description)
		case .cardOf(let app) where !app.isRedirect:
			(OpenGraphCard.path(ofPage: app.path), OpenGraphCard.description(of: app))
		case .site, .cardOf:
			(OpenGraphCard.sitePath, Site.name)
		}
	}

	var path: RoutePath {
		target.path
	}

	var description: String {
		target.description
	}

	/**
	The URL of the card, for `og:image`. The card of the page has the hash of its JPEG, like `https://sindresorhus.com/og/dato.jpg?v=1a2b3c4d5e6f7a8b`, as link previews keep an image by its URL, so a changed card gets a new URL at once. The file stays at its path, so old shares still work.

	Limitation: the site card and the card of an app on its other pages (``cardOf(_:)``) have no hash, as the page does not draw them.
	*/
	var url: URL {
		// A card that cannot be drawn fails the build in its own route.
		guard let jpeg = try? publishedCard?.cachedJPEG() else {
			return path.absoluteURL
		}

		return path.absoluteURL.appending(queryItems: [URLQueryItem(name: "v", value: String(SHA256.hash(data: jpeg).hexString.prefix(16)))])
	}

	/**
	The card that the page publishes with it.
	*/
	var publishedCard: OpenGraphCard? {
		guard case .card(let card) = self else {
			return nil
		}

		return card
	}
}

extension CGContext {
	/**
	Moves the origin to the top left, with y going down, like in CSS.
	*/
	fileprivate func flipToTopLeftOrigin() {
		translateBy(x: 0, y: Double(height))
		scaleBy(x: 1, y: -1)
	}
}

extension ContributionScale.Level {
	/**
	The light color of the level in the heatmaps of the site (``ContributionHeatmap``), in sRGB, as Core Graphics cannot read the colors of the stylesheet.
	*/
	fileprivate var cardColor: CGColor {
		switch self {
		case .none:
			.hex(0xE8E8ED)
		case .first:
			.hex(0x8EC5FF)
		case .second:
			.hex(0x2B7FFF)
		case .third:
			.hex(0x1447E6)
		case .fourth:
			.hex(0x1C398E)
		}
	}
}

private enum OpenGraphCardError: Error, CustomStringConvertible {
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

extension SiteContent {
	/**
	The social cards of the content files that cut off their title or their subtitle, as it is longer than three lines at the smallest size. A card is only seen when someone shares a link, so nothing else tells the author. The warning is at the key of the text, like `description` for a guide, as the author can shorten it.
	*/
	func socialCardWarnings() -> [Warning] {
		var warnings = [Warning]()

		func check<Value: Frontmatter>(
			_ card: OpenGraphCard,
			file: DecodedMarkdownFile<Value>,
			titleKey: Value.CodingKeys,
			subtitleKey: Value.CodingKeys
		) {
			guard let cutTexts = try? card.cutTexts() else {
				return
			}

			if cutTexts.title {
				warnings.append(file.warning(.cutSocialCardText, at: titleKey, "The social card cuts off the title after three lines. Shorten it."))
			}

			if cutTexts.subtitle {
				warnings.append(file.warning(.cutSocialCardText, at: subtitleKey, "The social card cuts off `\(subtitleKey.stringValue)` after three lines. Shorten it."))
			}
		}

		for app in apps where app.redirectURL == nil {
			check(
				OpenGraphCard(app: app, project: project),
				file: app.decodedFile,
				titleKey: App.Frontmatter.CodingKeys.title,
				subtitleKey: App.Frontmatter.CodingKeys.subtitle
			)
		}

		for resolved in guides {
			check(
				OpenGraphCard(guide: resolved.guide, app: resolved.app, project: project),
				file: resolved.guide.decodedFile,
				titleKey: Guide.Frontmatter.CodingKeys.title,
				subtitleKey: Guide.Frontmatter.CodingKeys.description
			)
		}

		for post in posts where post.redirectURL == nil {
			check(
				OpenGraphCard(post: post, project: project),
				file: post.decodedFile,
				titleKey: BlogPost.Frontmatter.CodingKeys.title,
				subtitleKey: BlogPost.Frontmatter.CodingKeys.description
			)
		}

		// The about page has the card of the site.
		for page in pages {
			switch page.kind {
			case .faq, .standard:
				check(
					OpenGraphCard(page: MarkdownContentPage(page: page, content: self), project: project),
					file: page.decodedFile,
					titleKey: MarkdownPage.Frontmatter.CodingKeys.title,
					subtitleKey: MarkdownPage.Frontmatter.CodingKeys.description
				)
			case .about, .now:
				break
			}
		}

		// The card of the now page has its status, which changes often.
		if
			let nowPage = page(.now),
			case .now(let now) = nowPage.kind,
			let card = OpenGraphCard(nowPage: nowPage, now: now, project: project)
		{
			check(
				card,
				file: nowPage.decodedFile,
				titleKey: MarkdownPage.Frontmatter.CodingKeys.title,
				subtitleKey: MarkdownPage.Frontmatter.CodingKeys.now
			)
		}

		return warnings
	}
}

extension Warning.Kind {
	static let cutSocialCardText = Self("Text that the social card cuts off")
}

extension [App] {
	/**
	Each app of the list once, with the number of times that it is in the list, like the apps of the guides: the app with the most first, and by title for the same number, so the order is the same in each build.
	*/
	var mostCommonFirst: [(app: App, count: Int)] {
		Dictionary(grouping: self, by: \.slug)
			.map { (app: $0.value[0], count: $0.value.count) }
			.sorted(using: [KeyPathComparator(\.count, order: .reverse), KeyPathComparator(\.app.title, comparator: .localizedStandard)])
	}
}
