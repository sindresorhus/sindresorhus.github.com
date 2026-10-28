import CoreGraphics
import Elementary
import Foundation
import ImageIO
import SiteKit
import SOML

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
	Shortens the text to fit a search result snippet (``SnippetText/maximumLength``), cutting at a word boundary.
	*/
	var shortenedForSnippet: String {
		let maximumLength = SnippetText.maximumLength

		guard count > maximumLength else {
			return self
		}

		let shortened = prefix(maximumLength - 1)
		let wordBoundary = shortened.lastIndex(of: " ") ?? shortened.endIndex
		return shortened[..<wordBoundary].replacing(/[,.:;]$/, with: "") + "…"
	}

	/**
	The noun for the count: as it is for 1, else in the plural, like “day” and “days”. The plural adds an “s”, unless it is given, like “repositories”.
	*/
	func pluralized(for count: Int, plural: String? = nil) -> String {
		count == 1 ? self : plural ?? self + "s"
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

	/**
	The count with the noun, in the plural when the count is not 1, like “1 day” or “1,234 days”. The plural adds an “s”.
	*/
	func formatted(counting noun: String) -> String {
		"\(formatted(.number.locale(.site))) \(noun.pluralized(for: self))"
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

extension Sequence {
	/**
	The elements without the later ones with the same key, in their order, like one release of each project.

	```
	["ky", "got", "ky"].uniqued(by: \.self)
	//=> ["ky", "got"]
	```
	*/
	func uniqued<Key: Hashable>(by key: (Element) -> Key) -> [Element] {
		var keys = Set<Key>()
		return filter { keys.insert(key($0)).inserted }
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
	A schema.org object that can be the top level of structured data, which has the `@context`.
	*/
	protocol Object: Encodable {
		var context: String? { get set }
	}

	struct Person: Object {
		var context: String?
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

		var context: String?
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
	}

	/**
	A page about one person, like an about page.
	*/
	struct ProfilePage: Object {
		var context: String?
		let type = "ProfilePage"
		let mainEntity: Person
	}

	/**
	The site, for the site name in search results.
	*/
	struct WebSite: Object {
		var context: String?
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

		var context: String?
		let type: Kind
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
		The download size with its unit, like “19.2 MB”, as a number alone is read as kilobytes.
		*/
		var fileSize: String?

		/**
		The other pages of the app, like the App Store and the repo.
		*/
		var sameAs: [URL]?

		var offers: Offer?
		var aggregateRating: AggregateRating?
		var review: [Review]?
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
		let ratingCount: Int

		/**
		The same validated and rounded rating that the page shows.
		*/
		init(rating: StoreRating) {
			self.ratingValue = rating.roundedAverage
			self.ratingCount = rating.count
		}
	}

	struct Review: Encodable {
		let type = "Review"
		let author: Person
		let datePublished: SOML.Date
		let name: String
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

		var context: String?
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
}

extension JSONScript {
	/**
	Structured data for search engines.
	*/
	init(schema value: some Schema.Object) {
		var value = value
		value.context = "https://schema.org"
		self.init(structuredData: value)
	}
}

extension Schema.SoftwareApplication {
	/**
	An app, with the version and the size from the App Store or the appcast (``AppListing/version`` and ``AppListing/fileSize``), and the price and the rating that the page shows (``AppListing/price`` and ``AppListing/storeRating``), as Google treats a rating that the page does not show as spam. A free app that is downloaded from its own site, like from GitHub, gets an offer with the price 0.

	The reviews are only included when there is a rating, as Google requires an `aggregateRating` with reviews (“Multiple reviews without aggregateRating object”). The rating is not computed from the reviews, as they are only the newest five-star ones. They are the reviews that the app page shows (``AppListing/newestReviews``).
	*/
	init(listing: AppListing) {
		let app = listing.app
		let info = listing.appStoreInfo

		self.init(
			type: app.platforms.contains(.macOS) ? .softwareApplication : .mobileApplication,
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
		softwareRequirements = listing.minimumVersionsByPlatform
		releaseNotes = app.releaseNotes?.path.absoluteURL
		dateModified = listing.currentVersionDate
		fileSize = listing.fileSize?.formatted(.byteCount(style: .file).locale(.site))
		// The plain pages of the stores, not the Setapp link, as it is a referral link, and not the Gumroad link, as it opens the checkout.
		sameAs = [app.appStoreURL, app.frontmatter.gumroad?.id.url, app.frontmatter.setappID?.pageURL, app.frontmatter.repositoryURL?.value].compactMap(\.self).nilIfEmpty

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

			// The product page on Gumroad, which has the price and the ratings, not the checkout of the Buy button.
			let offerURL = app.frontmatter.gumroad?.id.url ?? storeURL
			offers = listing.price.map { Schema.Offer(url: offerURL, seller: .authorName, price: $0) }
		}

		if let rating = listing.storeRating {
			aggregateRating = Schema.AggregateRating(rating: rating)
			review = listing.newestReviews.map(Schema.Review.init).nilIfEmpty
		}
	}
}

extension Schema.Review {
	/**
	A review from the App Store.
	*/
	init(_ review: AppStoreReview) {
		self.init(
			author: Schema.Person(name: review.author),
			datePublished: SOML.Date(review.date),
			name: review.title,
			reviewBody: review.text,
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
		CGImageSourceCreateWithURL(url as CFURL, nil).flatMap { CGImageSourceCreateImageAtIndex($0, 0, nil) }
	}

	/**
	The most common vivid color of the image, like the blue of a blue app icon, written as hex, like `#1e88e5`. `nil` when the image has almost no vivid colors, like a gray icon.

	The image is scaled down, and the colors of the opaque, saturated pixels are grouped by hue. The color is the average of the largest group, where more saturated and brighter pixels count more.
	*/
	var accentColor: Color? {
		struct HueGroup {
			var weight = 0.0
			var red = 0.0
			var green = 0.0
			var blue = 0.0
		}

		let side = 32

		guard
			let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
			let context = CGContext(
				data: nil,
				width: side,
				height: side,
				bitsPerComponent: 8,
				bytesPerRow: side * 4,
				space: colorSpace,
				bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
			)
		else {
			return nil
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

		guard let data = context.data else {
			return nil
		}

		let pixels = data.bindMemory(to: UInt8.self, capacity: side * side * 4)
		var groups = [HueGroup](repeating: HueGroup(), count: 12)
		var opaqueCount = 0

		for index in 0..<(side * side) {
			let alpha = Double(pixels[index * 4 + 3]) / 255

			guard alpha > 0.9 else {
				continue
			}

			opaqueCount += 1

			// The pixels are premultiplied by their alpha.
			let red = Double(pixels[index * 4]) / 255 / alpha
			let green = Double(pixels[index * 4 + 1]) / 255 / alpha
			let blue = Double(pixels[index * 4 + 2]) / 255 / alpha
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

			let group = Int(((hue < 0 ? hue + 1 : hue) * 12).rounded(.down)) % 12
			let weight = saturation * maximum
			groups[group].weight += weight
			groups[group].red += red * weight
			groups[group].green += green * weight
			groups[group].blue += blue * weight
		}

		guard
			let largest = groups.sorted(using: KeyPathComparator(\HueGroup.weight, order: .reverse)).first,
			opaqueCount > 0,
			largest.weight / Double(opaqueCount) > 0.08
		else {
			return nil
		}

		func hex(_ value: Double) -> String {
			let byte = min(max(Int((value / largest.weight * 255).rounded()), 0), 255)
			return (byte < 16 ? "0" : "") + String(byte, radix: 16)
		}

		return Color(raw: "#\(hex(largest.red))\(hex(largest.green))\(hex(largest.blue))")
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
		attributes(.width(size.width), .height(size.height))
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
