import Foundation
import SiteKit

/**
A link with a visible label, like a button in the app header.
*/
struct LabeledLink: Hashable, Sendable {
	var title: String
	var destination: LinkDestination

	var description: String?

	init(_ title: String, destination: LinkDestination, description: String? = nil) {
		self.title = title
		self.destination = destination
		self.description = description
	}

	init(_ title: String, url: URL) {
		self.init(title, destination: .url(url))
	}

	init(_ title: String, path: RoutePath) {
		self.init(title, destination: .path(path))
	}
}

/**
The pages about all the apps, which the site footer, the apps page, and the menus of the app pages link to, so they have the same title everywhere. The footer and the menus only show the title.
*/
extension LabeledLink {
	static let faq = Self("FAQ", destination: .path(.faq), description: "Frequently asked questions about my apps")
	static let appTimeline = Self("Timeline", destination: .path(.appTimeline), description: "Every app by the year it came out")
	static let wallOfLove = Self("Wall of Love", destination: .path(.reviews), description: "What the press and App Store reviewers say")
	static let olderVersions = Self("Older Versions", destination: .path(.olderVersions), description: "Apps for older macOS versions")
	static let discounts = Self("Discounts", destination: .path(.discounts), description: "Student discounts and special offers for my apps")
	static let termsOfUse = Self("Terms of Use", destination: .path(.terms), description: "Guidelines and conditions for using my apps")
}

/**
Links under a heading, like the app categories.
*/
struct LinkGroup: Sendable {
	var title: String
	var links: [LabeledLink]

	init(title: String, links: [LabeledLink]) {
		self.title = title
		self.links = links
	}
}

extension [LabeledLink] {
	/**
	Adds the links like assigning keys to a JavaScript object: a link with an existing title replaces the URL in place, and new titles are appended.
	*/
	func merging(_ links: some Sequence<LabeledLink>) -> Self {
		var result = self

		for link in links {
			if let index = result.firstIndex(where: { $0.title == link.title }) {
				result[index] = link
			} else {
				result.append(link)
			}
		}

		return result
	}
}
