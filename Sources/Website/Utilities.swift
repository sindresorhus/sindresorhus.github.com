import CoreGraphics
import Foundation
import SiteKit

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

extension String {
	/**
	Shortens the text to fit a search result snippet (160 characters), cutting at a word boundary.
	*/
	var shortenedForSnippet: String {
		let maximumLength = 160

		guard count > maximumLength else {
			return self
		}

		let shortened = prefix(maximumLength - 1)
		let wordBoundary = shortened.lastIndex(of: " ") ?? shortened.endIndex
		return shortened[..<wordBoundary].replacing(/[,.:;]$/, with: "") + "…"
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
	The count with the noun, in the plural when the count is not 1, like “1 day” or “1,234 days”. The plural adds an “s”.
	*/
	func formatted(counting noun: String) -> String {
		"\(formatted(.number.locale(.site))) \(self == 1 ? noun : noun + "s")"
	}
}

extension Decimal {
	/**
	Whether the number has no fraction, like 4, but not 4.99.
	*/
	var isWholeNumber: Bool {
		var value = self
		var rounded = Decimal()
		NSDecimalRound(&rounded, &value, 0, .plain)
		return rounded == self
	}
}

extension Array {
	/**
	`nil` for an empty array, like for leaving an empty list out of JSON.
	*/
	var nilIfEmpty: Self? {
		isEmpty ? nil : self
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
		var name: String?
		var givenName: String?
		var familyName: String?
		var url: URL?
		var image: URL?
		var jobTitle: String?
		var description: String?
		var sameAs: [URL]?
		var worksFor: Organization?
		var knowsAbout: [String]?
	}

	/**
	A blog post. Dates are ISO 8601 with the time.
	*/
	struct BlogPosting: Object {
		var context: String?
		let type = "BlogPosting"
		let headline: String
		var description: String?
		let url: URL
		let datePublished: String
		let dateModified: String
		let author: Person
		let image: URL
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

	struct Organization: Object {
		var context: String?
		let type = "Organization"
		let name: String
	}

	struct SoftwareApplication: Object {
		var context: String?
		let type = "SoftwareApplication"
		let name: String
		let description: String
		let url: URL
		let applicationCategory: String
		let operatingSystem: String
		let author: Person
		var datePublished: String?
		var image: URL?
		var screenshot: [URL]?
		var downloadUrl: URL?
		var softwareVersion: String?
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
	}

	struct Review: Encodable {
		let type = "Review"
		let author: Person
		let datePublished: String
		let name: String
		let reviewBody: String
		let reviewRating: Rating
	}

	struct Rating: Encodable {
		let type = "Rating"
		let ratingValue: Int
		let bestRating = 5
	}

	struct ItemList<Item: Encodable>: Object {
		struct ListItem: Encodable {
			let type = "ListItem"
			let position: Int
			let item: Item
		}

		var context: String?
		let type = "ItemList"
		let name: String
		let description: String
		let url: URL
		let numberOfItems: Int
		let itemListElement: [ListItem]

		init(name: String, description: String, url: URL, items: [Item]) {
			self.name = name
			self.description = description
			self.url = url
			self.numberOfItems = items.count
			self.itemListElement = items.enumerated().map { ListItem(position: $0.offset + 1, item: $0.element) }
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
	An app, with the version, price, and rating from the App Store when there is info. A free app that is downloaded from its own site, like from GitHub, gets an offer with the price 0.

	The reviews are only included when there is a rating, as Google requires an `aggregateRating` with reviews (“Multiple reviews without aggregateRating object”). The rating is not computed from the reviews, as they are only the newest five-star ones.
	*/
	init(app: App, info: AppStoreInfo?, reviews: [AppStoreReview] = []) {
		self.init(
			name: app.title,
			description: app.description,
			url: app.path.absoluteURL,
			applicationCategory: app.schemaCategory,
			operatingSystem: app.operatingSystems,
			author: .author,
			datePublished: app.publicationDate.isoDay,
			image: app.iconURL
		)

		screenshot = app.screenshotURLs.isEmpty ? nil : app.screenshotURLs

		if
			let info,
			let appStoreURL = app.appStoreURL
		{
			softwareVersion = info.version

			// The page has no App Store download for an archived app.
			if !app.frontmatter.isArchived {
				downloadUrl = appStoreURL

				if let price = info.price {
					offers = Schema.Offer(url: appStoreURL, seller: .authorName, price: price)
				}
			}

			if let rating = info.rating {
				aggregateRating = Schema.AggregateRating(ratingValue: rating.average, ratingCount: rating.count)

				if !reviews.isEmpty {
					review = reviews.map(Schema.Review.init)
				}
			}
		} else if
			app.appStoreURL == nil,
			let url = app.ownDownloadURL
		{
			// A free app that is downloaded from its own site, or a paid app that is sold there.
			if !app.isPaid {
				downloadUrl = url
				offers = Schema.Offer(url: url, seller: .authorName, price: Price(0))
			} else if let price = app.frontmatter.price {
				offers = Schema.Offer(url: url, seller: .authorName, price: price)
			}
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
			datePublished: review.date.isoDay,
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
		CGColor(srgbRed: Double((value >> 16) & 0xFF) / 255, green: Double((value >> 8) & 0xFF) / 255, blue: Double(value & 0xFF) / 255, alpha: 1)
	}
}

extension CGImage {
	/**
	The most common vivid color of the image, like the blue of a blue app icon, as hex, like `#1e88e5`. `nil` when the image has almost no vivid colors, like a gray icon.

	The image is scaled down, and the colors of the opaque, saturated pixels are grouped by hue. The color is the average of the largest group, where more saturated and brighter pixels count more.
	*/
	var accentColor: String? {
		struct HueGroup {
			var weight = 0.0
			var red = 0.0
			var green = 0.0
			var blue = 0.0
		}

		let side = 32

		guard
			let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
			let context = CGContext(data: nil, width: side, height: side, bitsPerComponent: 8, bytesPerRow: side * 4, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
		else {
			return nil
		}

		context.interpolationQuality = .medium
		context.draw(self, in: CGRect(x: 0, y: 0, width: side, height: side))

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

		return "#\(hex(largest.red))\(hex(largest.green))\(hex(largest.blue))"
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

extension Locale {
	/**
	English, the language of the site, so numbers and dates do not depend on the build machine.
	*/
	static let site = Self(identifier: "en_US")
}

extension Calendar {
	/**
	The Gregorian calendar in UTC, so the year or the day of a date does not depend on the time zone of the build machine.
	*/
	static let site: Self = {
		var calendar = Self(identifier: .gregorian)
		calendar.timeZone = .gmt
		return calendar
	}()
}

extension Date {
	/**
	The year of the date in UTC (``Calendar/site``), like 2026.
	*/
	var siteYear: Int {
		Calendar.site.component(.year, from: self)
	}

	/**
	The time from the other date to this date, like the age of an app. It is negative when the other date is later.
	*/
	func duration(since date: Date) -> Duration {
		.seconds(timeIntervalSince(date))
	}
}
