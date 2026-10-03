import Foundation

public enum Platform: String, CaseIterable, Sendable {
	case macOS
	case iOS
	case watchOS
	case tvOS
	case visionOS
	case Linux
	case Windows
}

public struct PressQuote: Sendable {
	public let quote: String
	public let source: String
	public let url: String?
	public let isStarRating: Bool
}

public struct Announcement: Sendable {
	public let text: String
	public let url: String?
	public let urlText: String?
}

public struct FAQMetadata: Sendable, Hashable {
	public var keywords: [String] = []
	public var platforms: [String] = []
}

public struct HeadingInfo: Sendable, Hashable {
	public let level: Int
	public let text: String
	public let id: String
}

public struct FAQHeading: Sendable, Hashable {
	public let text: String
	public let slug: String
	public let metadata: FAQMetadata
}

public struct MediaAsset: Sendable, Hashable {
	public let path: String
	public let width: Int
	public let height: Int
}

public struct App: Sendable {
	public let slug: String
	public let body: String
	public let draft: Bool
	public let isUnlisted: Bool
	public let isArchived: Bool
	public let title: String
	public let subtitle: String
	public let explicitDescription: String?
	public let publicationDate: Date
	public let platforms: [Platform]
	public let repositoryURL: String?
	public let appStoreID: Int?
	public let setappID: Int?
	public let isPaid: Bool
	public let isMenuBarApp: Bool
	public let mainLinks: [String: String]
	public let links: [String: String]
	public let overflowLinks: [String: String]
	public let showSupportLink: Bool
	public let redirectURL: String?
	public let releasesRepository: String?
	public let olderMacOSVersions: [String]
	public let requirement: String?
	public let downloads: Int?
	public let feedbackNote: String?
	public let hasSentry: Bool
	public let pressQuotes: [PressQuote]
	public let announcement: Announcement?
	public let markdown: ProcessedMarkdown
	public let media: [MediaAsset]

	public var url: String { redirectURL ?? "/\(slug)" }
	public var isRedirect: Bool { redirectURL != nil }
	public var iconURL: String { "/apps/\(slug)/icon.png" }
	public var appStoreURL: String? { appStoreID.map { "https://apps.apple.com/app/id\($0)" } }
	public var setappURL: String? { setappID.map { "https://go.setapp.com/stp181?refAppID=\($0)&utm_medium=vendor_program&utm_content=button" } }
	public var olderVersionsURL: String { repositoryURL.map { "\($0)#download" } ?? "/\(slug)#older-versions" }
	public var description: String {
		explicitDescription ?? TextUtilities.shortenForSnippet([subtitle, markdown.introduction].compactMap { $0 }.joined(separator: ". "))
	}

	public func isNew(relativeTo date: Date = Date()) -> Bool {
		Calendar(identifier: .gregorian).dateComponents([.day], from: publicationDate, to: date).day.map { $0 < 30 } ?? false
	}
}

public struct BlogPost: Sendable {
	public let slug: String
	public let body: String
	public let draft: Bool
	public let isUnlisted: Bool
	public let title: String
	public let description: String?
	public let publicationDate: Date
	public let tags: [String]
	public let redirectURL: String?
	public let markdown: ProcessedMarkdown

	public var url: String { redirectURL ?? "/blog/\(slug)" }
	public var isRedirect: Bool { redirectURL != nil }
	public var readingTime: Int {
		let words = body.split { $0.isWhitespace }.count
		return max(1, Int(ceil(Double(words) / 225)))
	}
}

public struct MarkdownPage: Sendable {
	public let route: String
	public let title: String
	public let description: String?
	public let markdown: ProcessedMarkdown
}

public struct ProcessedMarkdown: Sendable {
	public let html: String
	public let headings: [HeadingInfo]
	public let headingMetadata: [String: [String: FAQMetadata]]
	public let introduction: String?
}

public struct RSSFeedLink: Sendable {
	public let title: String
	public let href: String

	public init(title: String, href: String) {
		self.title = title
		self.href = href
	}
}

public struct PageMetadata: Sendable {
	public var title: String
	public var description: String
	public var image: String?
	public var imageAlt: String?
	public var noindex: Bool
	public var nofollow: Bool
	public var openGraphTitle: String
	public var openGraphType: String
	public var appStoreID: Int?
	public var favicon: String?
	public var rssFeeds: [RSSFeedLink]
	public var article: ArticleMetadata?

	public init(
		title: String,
		description: String = "",
		image: String? = nil,
		imageAlt: String? = nil,
		noindex: Bool = false,
		nofollow: Bool = false,
		openGraphTitle: String? = nil,
		openGraphType: String = "website",
		appStoreID: Int? = nil,
		favicon: String? = nil,
		rssFeeds: [RSSFeedLink] = [],
		article: ArticleMetadata? = nil
	) {
		self.title = title
		self.description = description
		self.image = image
		self.imageAlt = imageAlt
		self.noindex = noindex
		self.nofollow = nofollow
		self.openGraphTitle = openGraphTitle ?? title
		self.openGraphType = openGraphType
		self.appStoreID = appStoreID
		self.favicon = favicon
		self.rssFeeds = rssFeeds
		self.article = article
	}
}

public struct ArticleMetadata: Sendable {
	public let publishedTime: String
	public let authors: [String]
	public let tags: [String]
}

public struct AppStoreInfo: Sendable, Decodable {
	public let trackId: Int
	public let version: String?
	public let price: Double?
	public let currency: String?
	public let averageUserRating: Double?
	public let userRatingCount: Int?
}

public struct GitHubRelease: Sendable, Decodable {
	public let tagName: String
	public let publishedAt: String
	public let body: String?
	public let draft: Bool
	public let prerelease: Bool

	enum CodingKeys: String, CodingKey {
		case tagName = "tag_name"
		case publishedAt = "published_at"
		case body
		case draft
		case prerelease
	}
}

public struct GitHubRepository: Sendable, Decodable {
	public let name: String
	public let description: String?
	public let htmlURL: String
	public let createdAt: String
	public let archived: Bool
	public let fork: Bool

	enum CodingKeys: String, CodingKey {
		case name
		case description
		case htmlURL = "html_url"
		case createdAt = "created_at"
		case archived
		case fork
	}
}

public enum SiteConfiguration {
	public static let name = "Sindre Sorhus"
	public static let origin = "https://sindresorhus.com"
	public static let description = "Full-Time Open-Sourcerer & App Maker"
	public static let blogPostsPerPage = 10
}
