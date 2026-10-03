import Foundation
import SiteKit

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
	}

	struct Offer: Encodable {
		let type = "Offer"
		let availability = "https://schema.org/InStock"
		let url: URL
		let seller: Person
		let price: Double
		let priceCurrency: String
	}

	struct AggregateRating: Encodable {
		let type = "AggregateRating"
		let ratingValue: Double
		let ratingCount: Int
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

extension App {
	/**
	The schema.org category. Mac apps are utilities.
	*/
	var schemaCategory: String {
		self.platforms.contains(.macOS) ? "UtilitiesApplication" : "MobileApplication"
	}

	var operatingSystems: String {
		self.platforms.map(\.rawValue).joined(separator: ", ")
	}
}

extension Schema.Person {
	/**
	The author with the profiles that identify him.
	*/
	static let author = Self(givenName: Site.author.givenName, familyName: Site.author.familyName, url: Site.url, sameAs: Site.author.sameAs)

	/**
	The author by name only, for nested mentions like the seller of an app.
	*/
	static let authorName = Self(name: Site.author.name)

	/**
	The author with the full profile, for the home page.
	*/
	static let authorProfile = Self(
		name: Site.author.name,
		url: Site.url,
		image: Site.url.appending(path: Site.author.photoPath.dropFirst()),
		jobTitle: Site.description,
		description: "Full-time open-source developer and app maker focused on macOS apps, Node.js packages, and CLI tools.",
		sameAs: Site.author.sameAs,
		worksFor: Schema.Organization(name: "Independent")
	)
}
