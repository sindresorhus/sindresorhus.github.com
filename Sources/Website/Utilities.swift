import CoreGraphics
import Elementary
import Foundation
import ImageIO
import Markdown
import SiteKit
import SOML

extension Markdown.Heading {
	/**
	Whether the section of the heading has something that the page shows before the next heading of the same or a higher level, like the answer of a question. A directive below the heading, like `<!-- @faq.keywords … -->`, does not count.
	*/
	var hasSectionContent: Bool {
		guard let parent else {
			return false
		}

		return Array(parent.children)
			.contentOfSection(afterHeadingAt: indexInParent, level: headingLevel) { ($0 as? Markdown.Heading)?.headingLevel }
			.contains { !$0.isCommentOnly }
	}
}

extension MarkdownFile {
	/**
	The error of a question of an FAQ without an answer, as the page would show a question that opens to an empty box: in an app file, in the shared questions, and on the general FAQ page.
	*/
	func missingAnswerError(question: String, line: SiteKit.SourceLocation.Line?) -> ContentError {
		error(line: line, "The question “\(question)” has no answer. Write it below the heading.")
	}
}

/**
A random number generator that gives the same numbers for the same seed (SplitMix64).
*/
struct SeededRandomNumberGenerator: RandomNumberGenerator {
	private var state: UInt64

	init(seed: UInt64) {
		self.state = seed
	}

	/**
	A generator that gives the same numbers for the same key during a day (UTC), and other numbers the next day.
	*/
	static func daily(_ key: String, on date: Date) -> Self {
		Self(seed: key.stableHash ^ UInt64(date.duration(since: Date(timeIntervalSince1970: 0)) / .days(1)))
	}

	mutating func next() -> UInt64 {
		state &+= 0x9E37_79B9_7F4A_7C15
		var value = state
		value = (value ^ (value >> 30)) &* 0xBF58_476D_1CE4_E5B9
		value = (value ^ (value >> 27)) &* 0x94D0_49BB_1331_11EB
		return value ^ (value >> 31)
	}
}

/**
Text in frontmatter that is shown as it is written, like a title, which goes in the `<title>`, the link previews, and the hero: not empty, and without Markdown, like `**bold**`, `*emphasis*`, `code`, or a link, as the page would show the syntax.
*/
struct PlainTextString: PlainValidatedValue, Hashable, Sendable {
	/**
	Markdown syntax: strong text, emphasis, code, and a link.
	*/
	nonisolated(unsafe) private static let markdownSyntax = /\*\*|`|\]\(|\*[^\s*][^*]*\*/

	let value: String

	init(validating value: String) throws(ContentError) {
		let text = try NonEmptyString(validating: value).value

		guard !text.contains(Self.markdownSyntax) else {
			throw ContentError(reason: "This field is plain text, so Markdown is not rendered here, like `**`, `*`, a backtick, or a link. Write it without Markdown.")
		}

		self.value = text
	}
}

/**
Plain text in frontmatter, like `@PlainText var title: String`. See ``PlainTextString``.
*/
typealias PlainText<Value> = Validated<PlainTextString, Value>

/**
A description in frontmatter for search results and link previews: plain text (``PlainTextString``), and short enough that a search result shows all of it.
*/
struct SnippetText: PlainValidatedValue, Hashable, Sendable {
	/**
	The most characters of a description that a search result shows.
	*/
	static let maximumLength = 160

	let value: String

	init(validating value: String) throws(ContentError) {
		let text = try PlainTextString(validating: value).value

		guard text.count <= Self.maximumLength else {
			throw ContentError(reason: "Must be at most \(Self.maximumLength) characters, so search results show all of it, got \(text.count).")
		}

		self.value = text
	}
}

/**
A description in frontmatter, like `@Snippet var description: String?`. See ``SnippetText``.
*/
typealias Snippet<Value> = Validated<SnippetText, Value>

extension String {
	/**
	Whether the text calls something free, like “This is free, it’s effective”, for the reviews and quotes of a paid app. Not words with “free” in them, like “ad-free” or “freedom”.
	*/
	var callsAppFree: Bool {
		lowercased()
			.split { !$0.isLetter && $0 != "-" }
			.contains("free")
	}

	/**
	Shortens the text to fit a search result snippet (``SnippetText/maximumLength``), cutting at a word boundary.
	*/
	var shortenedForSnippet: String {
		let maximumLength = SnippetText.maximumLength

		guard count > maximumLength else {
			return self
		}

		let shortened = prefix(maximumLength - 1)
		let wordBoundary = shortened.lastIndex(of: " ") ?? shortened.endIndex
		return shortened[..<wordBoundary].replacing(Self.trailingPunctuation, with: "") + "…"
	}

	/**
	A punctuation mark at the end, which a shortened text leaves out before its “…”.
	*/
	nonisolated(unsafe) private static let trailingPunctuation = /[,.:;]$/
}

extension URL {
	/**
	A Markdown link to the URL, like `[Dato](https://sindresorhus.com/dato.md)`, for the Markdown copies of the pages and `llms.txt`.
	*/
	func markdownLink(_ text: String) -> String {
		"[\(text)](\(absoluteString))"
	}
}

extension Int {
	/**
	The number rounded down to its first significant digits, like 1,068 to 1,000 and 515,161 to 510,000 with two digits. A number that changes every day, like a download count, then changes the page less often.
	*/
	func roundedDown(significantDigits: Int) -> Int {
		let limit = Int(pow(10, Double(significantDigits)))
		var magnitude = 1

		while self / magnitude >= limit {
			magnitude *= 10
		}

		return self / magnitude * magnitude
	}

	/**
	The number rounded down to two significant digits and abbreviated, like `21B+` for 21,456,789,012 and `1.5K+` for 1,520, for numbers that change every day, like download counts, so they change the page less often. Rounded down, so it never claims more. A number below 1,000 is as it is.
	*/
	var approximateCount: String {
		guard self >= 1000 else {
			return String(self)
		}

		return roundedDown(significantDigits: 2).formatted(.number.notation(.compactName).locale(.site)) + "+"
	}

	/**
	The approximate count (``approximateCount``) with the noun, in the plural when the count is not 1, like “1 star” or “4.2M+ downloads”. The plural adds an “s”.
	*/
	func approximateCount(counting noun: String) -> String {
		"\(approximateCount) \(noun.pluralized(for: self))"
	}
}

extension Decimal {
	/**
	Whether the number has no fraction, like 4, but not 4.99.
	*/
	var isWholeNumber: Bool {
		var value = self
		var rounded = Decimal()
		NSDecimalRound(
			&rounded,
			&value,
			0,
			.plain
		)
		return rounded == self
	}
}

extension Sequence where Element: AdditiveArithmetic {
	/**
	The sum of the elements, and zero for an empty sequence.

	```
	[1, 2, 3].sum
	//=> 6
	```
	*/
	var sum: Element {
		reduce(.zero, +)
	}
}

/**
Schema.org types for structured data (JSON-LD). Unset properties are left out.
*/
enum Schema {
	/**
	A schema.org object that can be the top level of structured data, where ``JSONScript/init(schema:)`` adds the `@context`.
	*/
	protocol Object: Encodable {}

	struct Person: Object {
		let type = "Person"

		/**
		The ID of the person, so the structured data of all the pages is about the same person.
		*/
		var id: URL?

		var name: String?
		var givenName: String?
		var familyName: String?

		/**
		Another name of the person, like a username.
		*/
		var alternateName: String?

		var url: URL?
		var image: URL?
		var jobTitle: String?
		var description: String?
		var sameAs: [URL]?
		var knowsAbout: [String]?
	}

	/**
	An article, like a blog post or a guide. The dates are days, like `2026-10-05`.
	*/
	struct Article: Object {
		/**
		The schema.org type, like `Article` for a guide and `BlogPosting` for a post.
		*/
		enum Kind: String, Encodable {
			case article = "Article"
			case blogPosting = "BlogPosting"
		}

		let type: Kind
		let headline: String
		var description: String?
		let url: URL
		let datePublished: SOML.Date
		let dateModified: SOML.Date
		let author: Person

		/**
		The social card, and more images of the article, like the screenshot of a guide.
		*/
		let image: [URL]

		var keywords: [String]?

		/**
		What the article is about, like the apps of a guide.
		*/
		var about: [Reference]?
	}

	/**
	A reference to an object with an `@id` in the structured data of another page, like the app of a guide.
	*/
	struct Reference: Encodable {
		let id: URL
	}

	/**
	A page about one person, like an about page.
	*/
	struct ProfilePage: Object {
		let type = "ProfilePage"
		let mainEntity: Person

		/**
		The day that the page last changed. `nil` when it is not known, like in a test without git.
		*/
		var dateModified: SOML.Date?
	}

	/**
	The site, for the site name in search results.
	*/
	struct WebSite: Object {
		let type = "WebSite"
		let name: String
		let url: URL
	}

	/**
	An app. The type is `MobileApplication` for an app that does not run on the Mac.
	*/
	struct SoftwareApplication: Object {
		/**
		The schema.org type of the app, based on its platforms.
		*/
		enum Kind: String, Encodable {
			case softwareApplication = "SoftwareApplication"
			case mobileApplication = "MobileApplication"
		}

		/**
		The categories emitted in structured data, from the App Store category or the utilities fallback.
		*/
		enum Category: String, Encodable {
			case developer = "DeveloperApplication"
			case design = "DesignApplication"
			case multimedia = "MultimediaApplication"
			case game = "GameApplication"
			case entertainment = "EntertainmentApplication"
			case lifestyle = "LifestyleApplication"
			case health = "HealthApplication"
			case educational = "EducationalApplication"
			case finance = "FinanceApplication"
			case business = "BusinessApplication"
			case reference = "ReferenceApplication"
			case travel = "TravelApplication"
			case socialNetworking = "SocialNetworkingApplication"
			case sports = "SportsApplication"
			case utilities = "UtilitiesApplication"
		}

		let type: Kind

		/**
		The ID of the app (``App/structuredDataID``), so the structured data of other pages can refer to it, like a guide.
		*/
		let id: URL

		let name: String
		let description: String
		let url: URL
		let applicationCategory: Category
		let operatingSystem: String
		let author: Person
		var datePublished: SOML.Date?

		/**
		When the current version was released.
		*/
		var dateModified: SOML.Date?

		var image: URL?
		var screenshot: [URL]?
		var downloadUrl: URL?
		var softwareVersion: String?
		var softwareRequirements: String?

		/**
		The release notes page.
		*/
		var releaseNotes: URL?

		/**
		The download size with its unit, as a number alone is read as kilobytes, like the page shows it (``AppListing/fileSizeTexts``): “6 MB”, or “2.87 GB on Mac, 1.84 GB on iPhone and iPad” for an app on Mac and iPhone.
		*/
		var fileSize: String?

		/**
		The other pages of the app, like the App Store and the repo.
		*/
		var sameAs: [URL]?

		var offers: Offer?
		var aggregateRating: AggregateRating?
		var review: [Review]?

		/**
		The demo videos of the app, like the one of Text Lens.
		*/
		var video: [VideoObject]?
	}

	/**
	A demo video of an app, so search engines can show it in video results. Google needs the name, the thumbnail, and the upload date.
	*/
	struct VideoObject: Encodable {
		let type = "VideoObject"

		/**
		The name, like “Text Lens demo”.
		*/
		let name: String

		let description: String

		/**
		The poster of the video.
		*/
		let thumbnailUrl: URL

		let contentUrl: URL
		let uploadDate: SOML.Date
	}

	struct Offer: Encodable {
		let type = "Offer"
		let availability = "https://schema.org/InStock"
		let url: URL
		let seller: Person
		let price: Decimal
		let priceCurrency: String

		init(url: URL, seller: Person, price: Price) {
			self.url = url
			self.seller = seller
			self.price = price.amount
			self.priceCurrency = price.currency.identifier
		}
	}

	struct AggregateRating: Encodable {
		let type = "AggregateRating"
		let ratingValue: Double

		/**
		The best rating of a scale other than the 1 to 5 stars that schema.org assumes, like 100 for a percentage.
		*/
		private(set) var bestRating: Int?

		/**
		The worst rating of a scale other than the 1 to 5 stars, like 0 for a percentage.
		*/
		private(set) var worstRating: Int?

		let ratingCount: Int

		/**
		The same validated and rounded rating that the page shows: the average of stars on a store, or the percentage of positive ratings on Setapp, on the 100-point scale that Setapp uses in its own structured data.
		*/
		init(rating: AppRating) {
			switch rating {
			case .store(let rating):
				self.ratingValue = rating.roundedAverage
				self.ratingCount = rating.count
			case .setapp(let rating):
				self.ratingValue = Double(rating.percentPositive)
				self.bestRating = 100
				self.worstRating = 0
				self.ratingCount = rating.count
			}
		}
	}

	struct Review: Encodable {
		let type = "Review"
		let author: Person
		let datePublished: SOML.Date

		/**
		The title, which a review on Gumroad does not have.
		*/
		let name: String?

		let reviewBody: String
		let reviewRating: Rating
	}

	struct Rating: Encodable {
		let type = "Rating"
		let ratingValue: ReviewStars
		let bestRating = 5
	}

	/**
	A list of links to the pages of its items, like the apps of the apps page. Each item is only its position and URL, as each page has the full structured data of its item, which Google asks for on such a summary page.
	*/
	struct ItemList: Object {
		struct ListItem: Encodable {
			let type = "ListItem"
			let position: Int
			let url: URL
		}

		let type = "ItemList"
		let name: String
		let description: String
		let url: URL
		let numberOfItems: Int
		let itemListElement: [ListItem]

		init(
			name: String,
			description: String,
			url: URL,
			itemURLs: [URL]
		) {
			self.name = name
			self.description = description
			self.url = url
			self.numberOfItems = itemURLs.count
			self.itemListElement = itemURLs.enumerated().map { ListItem(position: $0.offset + 1, url: $0.element) }
		}
	}

	/**
	The trail of links that a page shows, like “Back to Command X” above the title of a guide, or the breadcrumb of the footer (``Page/parents``), like “Apps › Supercharge › Release Notes”, which search results can show instead of the path of the URL. The last item is the page itself, without a URL, so Google uses the URL of the page.
	*/
	struct BreadcrumbList: Object {
		struct ListItem: Encodable {
			let type = "ListItem"
			let position: Int
			let name: String

			/**
			The URL of the page, or `nil` for the last item.
			*/
			var item: URL?
		}

		let type = "BreadcrumbList"
		let itemListElement: [ListItem]

		/**
		- Parameter parents: The pages above the page, from the first, like the app of a guide.
		- Parameter name: The name of the page itself, like the title of a guide.
		*/
		init(parents: [(name: String, url: URL)], name: String) {
			self.itemListElement = parents.enumerated().map { ListItem(position: $0.offset + 1, name: $0.element.name, item: $0.element.url) } + [ListItem(position: parents.count + 1, name: name)]
		}
	}
}

extension JSONScript {
	/**
	Structured data for search engines.
	*/
	init(schema value: some Schema.Object) {
		self.init(structuredData: SchemaTopLevel(value: value))
	}
}

/**
A schema.org object at the top level of structured data, with the `@context` next to its own keys, as only the top level has it.
*/
private struct SchemaTopLevel<Value: Schema.Object>: Encodable {
	private enum CodingKeys: CodingKey {
		case context
	}

	let value: Value

	func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode("https://schema.org", forKey: .context)
		// The object asks for the same keyed container, so its keys are in the same JSON object.
		try value.encode(to: encoder)
	}
}

extension Schema.SoftwareApplication {
	/**
	An app, with the version and the size from the App Store or the appcast (``AppListing/version`` and ``AppListing/fileSizeTexts``, like the page, without the model that the app downloads), the demo videos, and the price and the eligible rating that the page shows (``AppListing/price`` and ``AppListing/rating(at:)``), as Google treats a rating that the page does not show as spam. A free app that is downloaded from its own site, like from GitHub, gets an offer with the price 0.

	The reviews are only included when there is a rating, as Google requires an `aggregateRating` with reviews (“Multiple reviews without aggregateRating object”). The rating is not computed from the reviews, as they are only the newest five-star ones. They are the reviews that the app page shows (``AppListing/newestReviews``).
	*/
	init(listing: AppListing, buildDate: Date) {
		let app = listing.app
		let info = listing.appStoreInfo

		self.init(
			type: app.platforms.contains(.macOS) ? .softwareApplication : .mobileApplication,
			id: app.structuredDataID,
			name: app.title,
			description: app.description,
			url: app.path.absoluteURL,
			// The category of the App Store, or else a utility, as most of the apps are. A category is required, and `MobileApplication` is a type, not a category.
			applicationCategory: info?.schemaApplicationCategory ?? .utilities,
			operatingSystem: app.operatingSystems,
			author: .author,
			datePublished: app.publicationDate,
			image: app.iconURL
		)

		screenshot = app.screenshotURLs.nilIfEmpty
		softwareRequirements = listing.requirement?.descriptionByPlatform
		releaseNotes = app.releaseNotes?.path.absoluteURL
		dateModified = listing.currentVersionDate
		fileSize = listing.fileSizeTexts.nilIfEmpty?.joined(separator: ", ")
		// The plain pages of the stores, not the Setapp link, as it is a referral link, and not the Gumroad link, as it opens the checkout.
		sameAs = [app.appStoreURL, app.purchase.gumroad?.id.url, app.frontmatter.setappID?.pageURL, app.frontmatter.repositoryURL?.value].compactMap(\.self).nilIfEmpty

		softwareVersion = listing.version

		// The App Store, or else the own link of an app that is not on the App Store, like the download on GitHub or the purchase on Gumroad. The page has no App Store download for an archived app.
		let storeURL = if let appStoreURL = app.appStoreURL {
			app.frontmatter.isArchived ? nil : appStoreURL
		} else {
			app.ownDownloadURL
		}

		if let storeURL {
			// A paid app that is not on the App Store is bought on its own site, not downloaded.
			if app.appStoreURL != nil || !app.isPaid {
				downloadUrl = storeURL
			}

			// The product page on Gumroad, which has the price and the ratings, not the checkout of the Buy button. An archived app is no longer available, so it has no offer, like the archived apps without a download.
			let offerURL = app.purchase.gumroad?.id.url ?? storeURL
			offers = app.isArchived ? nil : listing.price.map { Schema.Offer(url: offerURL, seller: .authorName, price: $0) }
		}

		// A video without its date, like in a test without git, is left out, as Google needs the date.
		video = app.media.compactMap(\.video).compactMap { asset in
			asset.uploadDate.map { date in
				Schema.VideoObject(
					name: app.demoVideoTitle,
					description: app.subtitle,
					thumbnailUrl: asset.poster.absoluteURL,
					contentUrl: asset.path.absoluteURL,
					uploadDate: SOML.Date(date)
				)
			}
		}
		.nilIfEmpty

		if let rating = listing.rating(at: buildDate) {
			aggregateRating = Schema.AggregateRating(rating: rating)
			review = listing.newestReviews.map(Schema.Review.init).nilIfEmpty
		}
	}
}

extension Schema.Review {
	/**
	A review from the App Store or Gumroad.
	*/
	init(_ review: StoreReview) {
		self.init(
			author: Schema.Person(name: review.author),
			datePublished: SOML.Date(review.date),
			name: review.displayTitle,
			reviewBody: review.displayText,
			reviewRating: Schema.Rating(ratingValue: review.rating)
		)
	}
}

extension CGColor {
	/**
	An sRGB color from a hex value, like `0x0F172A`.
	*/
	static func hex(_ value: Int) -> CGColor {
		CGColor(
			srgbRed: Double((value >> 16) & 0xFF) / 255,
			green: Double((value >> 8) & 0xFF) / 255,
			blue: Double(value & 0xFF) / 255,
			alpha: 1
		)
	}
}

extension CGImage {
	/**
	The first image of a PNG or JPEG file, or `nil` when it cannot be read.
	*/
	static func read(_ url: URL) -> CGImage? {
		CGImageSource.read(url)?.firstImage
	}

	/**
	The most common vivid color of the image, like the blue of a blue app icon, written as hex, like `#1e88e5`. `nil` when the image has almost no vivid colors, like a gray icon.

	The color is the average of the largest hue group of the vivid pixels (``vividHues``), when that group is more than 8% of the image.
	*/
	var accentColor: Color? {
		guard
			let hues = vividHues,
			hues.largest.weight / Double(hues.opaqueCount) > 0.08
		else {
			return nil
		}

		return hues.largest.color
	}

	/**
	The color of the glow below an icon in a row of icons, like on a category page of the apps: the largest hue group, like ``accentColor``, but counted among the colored pixels only, so a white icon with a colored glyph and a colorful icon get a color too. `nil` when less than 3% of the image has color, like a gray or white icon, or when no hue leads, like a rainbow. The accent of the app pages stays ``accentColor``.
	*/
	var glowColor: Color? {
		guard
			let hues = vividHues,
			Double(hues.coloredCount) / Double(hues.opaqueCount) >= 0.03,
			hues.largest.weight / Double(hues.coloredCount) >= 0.2
		else {
			return nil
		}

		return hues.largest.color
	}

	/**
	The largest group by hue (one of 12) of the opaque, saturated pixels of a 32 × 32 copy of the image, where more saturated and brighter pixels count more, with the number of opaque pixels and of colored pixels. `nil` when the image cannot be drawn or has no colored pixels.
	*/
	private var vividHues: (largest: HueGroup, opaqueCount: Int, coloredCount: Int)? {
		let side = 32
		let bytesPerPixel = 4
		let bytesPerRow = side * bytesPerPixel
		var pixels = [UInt8](repeating: 0, count: side * bytesPerRow)

		guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else {
			return nil
		}

		let drewImage = pixels.withUnsafeMutableBytes { buffer in
			guard let context = CGContext(
				data: buffer.baseAddress,
				width: side,
				height: side,
				bitsPerComponent: 8,
				bytesPerRow: bytesPerRow,
				space: colorSpace,
				bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
			) else {
				return false
			}

			context.interpolationQuality = .medium
			context.draw(
				self,
				in: CGRect(
					x: 0,
					y: 0,
					width: side,
					height: side
				)
			)
			return true
		}

		guard drewImage else {
			return nil
		}

		var groups = [HueGroup](repeating: HueGroup(), count: 12)
		var opaqueCount = 0
		var coloredCount = 0

		for offset in stride(from: 0, to: pixels.count, by: bytesPerPixel) {
			let alpha = Double(pixels[offset + 3]) / 255

			guard alpha > 0.9 else {
				continue
			}

			opaqueCount += 1

			// The pixels are premultiplied by their alpha.
			let red = Double(pixels[offset]) / 255 / alpha
			let green = Double(pixels[offset + 1]) / 255 / alpha
			let blue = Double(pixels[offset + 2]) / 255 / alpha
			let maximum = max(red, green, blue)
			let minimum = min(red, green, blue)
			let saturation = maximum > 0 ? (maximum - minimum) / maximum : 0

			guard
				saturation > 0.3,
				maximum > 0.25
			else {
				continue
			}

			let delta = maximum - minimum
			let hue = switch maximum {
			case red:
				((green - blue) / delta).truncatingRemainder(dividingBy: 6) / 6
			case green:
				((blue - red) / delta + 2) / 6
			default:
				((red - green) / delta + 4) / 6
			}

			coloredCount += 1
			let group = Int(((hue < 0 ? hue + 1 : hue) * 12).rounded(.down)) % 12
			let weight = saturation * maximum
			groups[group].weight += weight
			groups[group].red += red * weight
			groups[group].green += green * weight
			groups[group].blue += blue * weight
		}

		guard
			let largest = groups.sorted(using: KeyPathComparator(\HueGroup.weight, order: .reverse)).first,
			coloredCount > 0
		else {
			return nil
		}

		return (largest, opaqueCount, coloredCount)
	}
}

/**
The pixels of one hue of an image (``CGImage/accentColor``), with their colors summed by weight.
*/
private struct HueGroup {
	var weight = 0.0
	var red = 0.0
	var green = 0.0
	var blue = 0.0

	/**
	The average color, as hex, like `#1e88e5`.
	*/
	var color: Color {
		func hex(_ value: Double) -> String {
			let byte = min(max(Int((value / weight * 255).rounded()), 0), 255)
			return (byte < 16 ? "0" : "") + String(byte, radix: 16)
		}

		return Color(raw: "#\(hex(red))\(hex(green))\(hex(blue))")
	}
}

extension Duration {
	/**
	A number of days of 24 hours, like `.days(30)`.
	*/
	static func days(_ days: Int) -> Self {
		.seconds(days * 24 * 60 * 60)
	}
}

extension Date {
	/**
	The start of a day in UTC (``Calendar/site``), for a date in the code, like `Date(year: 2011, month: 9, day: 6)`.
	*/
	init(year: Int, month: Int, day: Int) {
		let components = DateComponents(year: year, month: month, day: day)

		guard
			let date = Calendar.site.date(from: components),
			Calendar.site.dateComponents([.year, .month, .day], from: date) == components
		else {
			preconditionFailure("\(year)-\(month)-\(day) is not a date.")
		}

		self = date
	}

	/**
	The year of the date in UTC (``Calendar/site``), like 2026.
	*/
	var siteYear: Int {
		Calendar.site.component(.year, from: self)
	}

	/**
	The whole years in UTC from the other date to this date, like 11 for the age of the first app. The count goes up on the day of the other date, not on January 1.
	*/
	func wholeYears(since date: Date) -> Int {
		Calendar.site.dateComponents([.year], from: date, to: self).year ?? 0
	}

	/**
	The time from the other date to this date, like the age of an app. It is negative when the other date is later.
	*/
	func duration(since date: Date) -> Duration {
		.seconds(timeIntervalSince(date))
	}
}

/**
Sets the validated bitmap dimensions of a canvas.
*/
extension HTML where Tag == HTMLTag.canvas {
	/**
	Sets the intrinsic bitmap dimensions, independently of the display size in CSS.
	*/
	func bitmapSize(_ size: PixelSize) -> _AttributedContent<Self> {
		intrinsicSize(size)
	}
}

/**
Scoped drawing operations on a graphics context.
*/
extension CGContext {
	/**
	Runs the closure with saved graphics state and restores that state when it returns or throws. The current path is not part of the saved state.
	*/
	func withSavedState<Value>(_ body: () throws -> Value) rethrows -> Value {
		saveGState()
		defer {
			restoreGState()
		}

		return try body()
	}
}
