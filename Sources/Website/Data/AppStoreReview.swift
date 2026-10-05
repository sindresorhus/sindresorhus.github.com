import Foundation
import SiteKit

/**
A review of an app on an English-language App Store.
*/
struct AppStoreReview: Hashable, Sendable {
	let title: String
	let text: String
	let author: String
	let rating: Int
	let date: Date

	/**
	The App Stores that the reviews come from. They are in English, like the site.
	*/
	private static let storefronts: [Locale.Region] = [.unitedStates, .unitedKingdom, .canada, .australia, .newZealand, .ireland]

	/**
	The most reviews of one app, so the reviews of a popular app do not fill the wall of love.
	*/
	static let maximumCountPerApp = 25

	/**
	The number of reviews on a page of a feed. A full page means that the next page may have more.
	*/
	private static let pageSize = 50

	/**
	The number of pages that a feed has at most.
	*/
	private static let maximumPageCount = 10

	/**
	The most recent five-star reviews of each app, newest first and at most ``maximumCountPerApp``, from the public reviews feeds of the ``storefronts``. A feed is read page by page while the pages are full. Reviews that are very short or long are left out, so they fit the page.

	Limitation: an entry that cannot be decoded makes its page look shorter than full, so the next pages of that feed are not read.

	The reviews are extra, so a failed request leaves out the reviews of that app on that App Store, with a warning, instead of failing the build. When every feed has no reviews at all, which happens when Apple stops filling the feeds, there is one warning, so the missing reviews are not silent.
	*/
	static func recentFiveStar(appIDs: [AppStoreID], cache: ResponseCache, warnings: WarningCollector) async -> [AppStoreID: [Self]] {
		await withTaskGroup { group in
			for id in Set(appIDs) {
				for storefront in storefronts {
					// The number of reviews in the feed, before the filter, or `nil` when the request failed.
					group.addTask { () -> (id: AppStoreID, reviews: [Self], feedReviewCount: Int?) in
						var reviews = [Self]()
						var feedReviewCount: Int?

						for page in 1...maximumPageCount {
							let url = #URL("https://itunes.apple.com").appending(path: "\(storefront.identifier.lowercased())/rss/customerreviews/page=\(page)/id=\(id)/sortBy=mostRecent/json")

							do {
								let feed = try await cache.decoded(ReviewFeed.self, from: URLRequest(url: url, timeoutInterval: 15))
								reviews += feed.reviews.filter(\.isShowable)
								feedReviewCount = (feedReviewCount ?? 0) + feed.reviews.count

								guard feed.reviews.count == pageSize else {
									break
								}
							} catch {
								// The reviews of the earlier pages are kept.
								warnings.add(Warning(message: "Could not get page \(page) of the App Store reviews of app \(id) in the “\(storefront.identifier)” App Store: \(error)"))
								break
							}
						}

						return (id, reviews, feedReviewCount)
					}
				}
			}

			var reviewsByApp = [AppStoreID: Set<Self>]()
			var feedReviewCounts = [Int]()

			for await result in group {
				reviewsByApp[result.id, default: []].formUnion(result.reviews)

				if let count = result.feedReviewCount {
					feedReviewCounts.append(count)
				}
			}

			if
				!feedReviewCounts.isEmpty,
				feedReviewCounts.allSatisfy({ $0 == 0 })
			{
				warnings.add(Warning(message: "App Store review feeds returned no entries, so the pages have no App Store reviews."))
			}

			// The title breaks ties, so the order does not depend on which request finished first.
			return reviewsByApp.mapValues { reviews in
				Array(reviews.sorted(using: [KeyPathComparator(\.date, order: .reverse), KeyPathComparator(\.title, comparator: .localizedStandard)]).prefix(maximumCountPerApp))
			}
		}
	}

	private var isShowable: Bool {
		rating == 5 && (40...360).contains(text.count) && !title.isEmpty
	}
}

/**
The reviews feed of the App Store. Its `entry` is a list, one object for one review, or missing without reviews.
*/
private struct ReviewFeed: Decodable {
	/**
	A value in the feed, which has its text in `label`.
	*/
	private struct Field: Decodable {
		let label: String
	}

	private struct Entry: Decodable {
		struct Author: Decodable {
			let name: Field
		}

		let author: Author
		let title: Field
		let content: Field
		let rating: Field
		let updated: Field

		enum CodingKeys: String, CodingKey {
			case author
			case title
			case content
			case rating = "im:rating"
			case updated
		}
	}

	private enum CodingKeys: String, CodingKey {
		case feed
		case entry
	}

	let reviews: [AppStoreReview]

	init(from decoder: any Decoder) throws {
		let feed = try decoder.container(keyedBy: CodingKeys.self).nestedContainer(keyedBy: CodingKeys.self, forKey: .feed)

		let entries: [Entry]

		if feed.contains(.entry) {
			do {
				entries = try feed.decode([Entry].self, forKey: .entry)
			} catch {
				guard let entry = try? feed.decode(Entry.self, forKey: .entry) else {
					throw error
				}

				entries = [entry]
			}
		} else {
			entries = []
		}

		self.reviews = try entries.map { entry in
			AppStoreReview(
				// Some reviewers start the title with star emoji, which would repeat the stars of the rating.
				title: entry.title.label.trimmingCharacters(in: .whitespacesAndNewlines.union(CharacterSet(charactersIn: "⭐★\u{FE0F}"))),
				text: entry.content.label.trimmingCharacters(in: .whitespacesAndNewlines),
				author: entry.author.name.label,
				rating: Int(entry.rating.label) ?? 0,
				date: try Date(entry.updated.label, strategy: .iso8601)
			)
		}
	}
}
