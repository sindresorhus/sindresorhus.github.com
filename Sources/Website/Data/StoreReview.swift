import Foundation
import NaturalLanguage
import SiteKit

/**
The whole number of stars in one review, from one to five. Aggregate ratings keep their fractional averages.
*/
enum ReviewStars: Int, Codable {
	case one = 1
	case two
	case three
	case four
	case five
}

/**
A review of an app on an English-language App Store, or on Gumroad for an app that is sold there (``GumroadProduct/reviews``).
*/
struct StoreReview: Hashable {
	/**
	The title, which a review on Gumroad does not have.
	*/
	let title: String?

	let text: String
	let author: String
	let rating: ReviewStars
	let date: Date

	/**
	The store of the review, which the card names.
	*/
	var store = StoreRating.Store.appStore

	/**
	The text that `hiddenReviews` of `content/site.soml` matches to hide the review: its title, or its text for a review without a title, like on Gumroad. It is the text of the store, which can be a little different from the text on the page (``displayTitle``, ``displayText``), like “Simply beautiful.” for “Simply beautiful”.
	*/
	var hidingKey: String {
		title ?? text
	}

	/**
	The title as the pages show it (``String/tidiedReviewText``), without the periods at its end, like a heading: “Simply beautiful.” and “Simply beautiful..” become “Simply beautiful”, but “Wow…” stays. A title with 6 or more letters that are all capital letters is in sentence case, so it does not shout next to the other titles: “NEVER MISS A MEETING AGAIN” becomes “Never miss a meeting again”, but “WOW” stays. The stored title stays the text of the reviewer, which ``hidingKey`` matches.

	Limitation: a name in such a title, like “MAC”, becomes lowercase too.
	*/
	var displayTitle: String? {
		title.map { title in
			let letters = title.filter(\.isLetter)
			let isAllCapitals = letters.count >= 6 && letters.allSatisfy(\.isUppercase)
			let tidied = (isAllCapitals ? title.lowercased() : title).tidiedReviewText
			// Three periods are already an ellipsis (``Swift/String/typographicPunctuation``), so the periods at the end are a full stop, also two of them.
			let periodCount = tidied.reversed().prefix { $0 == "." }.count
			return String(tidied.dropLast(periodCount))
		}
	}

	/**
	The text as the pages show it (``String/tidiedReviewText``). The stored text stays the text of the reviewer, which ``hidingKey`` matches.
	*/
	var displayText: String {
		text.tidiedReviewText
	}

	/**
	The App Stores that the reviews come from. They are in English, like the site, but people also write in other languages there, like French in Canada, so those reviews are left out (``isEnglish``).
	*/
	private static let storefronts: [Locale.Region] = [.unitedStates, .unitedKingdom, .canada, .australia, .newZealand, .ireland]

	/**
	The most reviews of one app, so the reviews of a popular app do not fill the wall of love.
	*/
	private static let maximumCountPerApp = 25

	/**
	The number of reviews on a page of a feed. A full page means that the next page may have more.
	*/
	private static let pageSize = 50

	/**
	The number of pages that a feed has at most.
	*/
	private static let maximumPageCount = 10

	/**
	How long a page of a feed is used without asking Apple again, also on CI. Reviews come slowly, and Apple refuses some of the hundreds of requests of a build with status 403 on some nights. 60 hours, not 3 days, so the nightly builds, which start about 24 hours apart, ask for a page again on every third night, not on the second or the fourth night because of a few minutes. A page that Apple refused is asked for again the next night, and an empty page with the normal maximum age of the cache, so on every deploy build. An empty page does not replace a cached page with reviews, as an app does not lose all its reviews, so it is an error of Apple: the build uses the cached page with a warning, like for a refused request. Limitation: when an app really leaves the App Store of a country, its old reviews of that country stay, with the warning on each build, until the cached response is removed from `.cache/responses`.
	*/
	private static let feedMaximumAge = Duration.seconds(60 * 60 * 60)

	/**
	The most recent five-star reviews of each app, newest first and at most ``maximumCountPerApp``, from the public reviews feeds of the ``storefronts``. A feed is read page by page while the pages are full, and a page is asked for again only after ``feedMaximumAge``. Reviews that are very short or long are left out, so they fit the page.

	Limitation: an entry that cannot be decoded rejects its page. The earlier pages are kept, and the later pages of that feed are not read.

	The reviews are extra, so a failed request leaves out the reviews of that app on that App Store, with a warning, instead of failing the build. When every feed has no reviews at all, which happens when Apple stops filling the feeds, there is one warning, so the missing reviews are not silent.

	A cancelled task keeps the reviews already read, without a request-failure warning.
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
								// An empty page does not replace a cached page with entries (`feedMaximumAge`).
								var feed = try await cache.decoded(
									ReviewFeed.self,
									from: url,
									maximumAge: feedMaximumAge,
									keepsCached: { cached, new in
										new.entryCount == 0 && cached.entryCount > 0
									}
								)

								// Apple sometimes sends feeds without entries for a while, so an empty page has the normal maximum age of the cache, like before, not the long one, which would hide the reviews of the app for days.
								if feed.entryCount == 0 {
									feed = try await cache.decoded(ReviewFeed.self, from: url)
								}

								reviews += feed.reviews.filter(\.isShowable)
								feedReviewCount = (feedReviewCount ?? 0) + feed.entryCount

								guard feed.entryCount == pageSize else {
									break
								}
							} catch {
								// The reviews of the earlier pages are kept.
								if !Task.isCancelled {
									warnings.add(Warning(.failedRequest, "Could not get page \(page) of the App Store reviews of app \(id) in the “\(storefront.identifier)” App Store: \(error)"))
								}
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
				!Task.isCancelled,
				!feedReviewCounts.isEmpty,
				feedReviewCounts.allSatisfy({ $0 == 0 })
			{
				warnings.add(Warning(.failedRequest, "App Store review feeds returned no entries, so the pages have no App Store reviews."))
			}

			// The language is checked last, and only until an app has enough reviews, as it is the slow check. Each app is checked in its own task.
			return await withTaskGroup { group in
				for (id, reviews) in reviewsByApp {
					group.addTask {
						// The title breaks ties, so the order does not depend on which request finished first.
						let newestFirst = reviews.sorted(using: [KeyPathComparator(\.date, order: .reverse), KeyPathComparator(\.hidingKey, comparator: .localizedStandard)])
						// A loop, as an array of a lazy filter runs the check again for its count.
						var englishReviews = [Self]()

						for review in newestFirst where review.isEnglish {
							englishReviews.append(review)

							if englishReviews.count == maximumCountPerApp {
								break
							}
						}

						return (id, englishReviews)
					}
				}

				var newestReviewsByApp = [AppStoreID: [Self]]()

				for await (id, reviews) in group {
					newestReviewsByApp[id] = reviews
				}

				return newestReviewsByApp
			}
		}
	}

	/**
	Whether the review calls the app free, like “This is free, it’s effective”, so a paid app, which was free before, does not show it. Not words with “free” in them, like “ad-free” or “freedom”.
	*/
	var callsAppFree: Bool {
		"\(title ?? "") \(text)".callsAppFree
	}

	/**
	Whether the review can be shown, without the language, which is checked last (``isEnglish``). A review on the App Store needs a title, as the reviews there have one.
	*/
	var isShowable: Bool {
		rating == .five && (40...360).contains(text.count) && (store != .appStore || title?.isEmpty == false)
	}

	/**
	Whether the review is in English, like the site, so screen readers read it with the right voice.
	*/
	var isEnglish: Bool {
		let recognizer = NLLanguageRecognizer()
		recognizer.processString([title, text].compactMap(\.self).joined(separator: "\n"))
		return recognizer.dominantLanguage == .english
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

	let reviews: [StoreReview]

	/**
	The number of entries before invalid star ratings are skipped, for pagination and detecting empty feeds.
	*/
	let entryCount: Int

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

		self.entryCount = entries.count
		self.reviews = try entries.compactMap { entry in
			guard let rating = Int(entry.rating.label).flatMap(ReviewStars.init(rawValue:)) else {
				return nil
			}

			// With typographic quotes, like the rest of the site, as reviewers type straight ones.
			return StoreReview(
				// Some reviewers start the title with star emoji, which would repeat the stars of the rating.
				title: entry.title.label.trimmingCharacters(in: .whitespacesAndNewlines.union(CharacterSet(charactersIn: "⭐★\u{FE0F}"))).typographicPunctuation,
				text: entry.content.label.trimmingCharacters(in: .whitespacesAndNewlines).typographicPunctuation,
				author: entry.author.name.label.typographicPunctuation,
				rating: rating,
				date: try Date(entry.updated.label, strategy: .iso8601)
			)
		}
	}
}

extension String {
	/**
	A word between asterisks, like `*cute*`, which a reviewer writes for emphasis, as the store has no formatting. Only with no space inside the asterisks, so a list item like `* Fast` is not a match.
	*/
	nonisolated(unsafe) private static let reviewEmphasis = /\*{1,2}([^\s*](?:[^*\n]*[^\s*])?)\*{1,2}/

	/**
	The word “i” alone, also in “i’m”, “i’ve”, “i’d”, and “i’ll”, with the character before it, but not the “i” of “i.e.” or “iPhone”, or a letter of a word with spaces between its letters, like “t i o n”. The text already has typographic apostrophes (``Swift/String/typographicPunctuation``).
	*/
	nonisolated(unsafe) private static let lowercaseI = /(^|[\s(“‘])i(?!\s\p{L}(?:\s|$))(?=’(?:m|ve|d|ll)(?!\p{L})|[\s,!?;:)”]|\.(?![\p{L}\d])|$)/

	/**
	The text of a review, tidied for the page, like the edited press quotes, without a change to the words of the reviewer: without the asterisks of emphasis (“*cute*” becomes “cute”), with “I” for the word “i” (“what i wanted” becomes “what I wanted”), and with a capital first letter when the first word has only lowercase letters (“de-fancifies styled text” becomes “De-fancifies styled text”, but “iPhone” and “macOS” stay). Limitation: a product name that the reviewer wrote in lowercase at the start, like “iphone”, becomes “Iphone”.
	*/
	fileprivate var tidiedReviewText: String {
		let text = replacing(Self.reviewEmphasis) { $0.output.1 }
			.replacing(Self.lowercaseI) { "\($0.output.1)I" }

		let firstWord = text.prefix { !$0.isWhitespace }

		guard
			let first = firstWord.first,
			first.isLowercase,
			!firstWord.contains(where: \.isUppercase)
		else {
			return text
		}

		return first.uppercased() + text.dropFirst()
	}
}
