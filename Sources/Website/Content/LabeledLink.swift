import Foundation
import SiteKit

/**
A link with a visible label, like a button in the app header.
*/
struct LabeledLink: Hashable {
	let title: String
	let destination: LinkDestination

	let description: String?

	/**
	The name of the link for screen readers, when the title alone is not clear, like “Privacy Policy of Dato” next to the “Privacy Policy” of the site in the footer. It starts with the title, so the visible label is in the name (WCAG 2.5.3).
	*/
	var accessibilityLabel: String?

	init(_ title: String, destination: LinkDestination, description: String? = nil) {
		self.title = title
		self.destination = destination
		self.description = description
	}

	init(_ title: String, url: URL) {
		self.init(title, destination: .url(url))
	}

	/**
	Creates a link without discarding its validated absolute destination.
	*/
	init(_ title: String, url: AbsoluteURL) {
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
	static let guides = Self("Guides", destination: .path(.guides), description: "Short how-to guides for tasks on the Mac and iPhone")
	static let feedback = Self("Feedback & Support", destination: .path(.feedback), description: "Ask a question or report a problem with an app")
	static let appTimeline = Self("Timeline", destination: .path(.appTimeline), description: "Every app by the year it came out")
	static let wallOfLove = Self("Wall of Love", destination: .path(.reviews), description: "What the press and App Store reviewers say")
	static let olderVersions = Self("Older Versions", destination: .path(.olderVersions), description: "Apps for older macOS versions")
	static let discounts = Self("Discounts", destination: .path(.discounts), description: "Student discounts and special offers for my apps")
	static let termsOfUse = Self("Terms of Use", destination: .path(.terms), description: "Guidelines and conditions for using my apps")
	static let privacyPolicy = Self("Privacy Policy", destination: .path(.privacy), description: "The data this website and the feedback form get, and who gets it")
}

/**
Links under a heading, like the app categories.
*/
struct LinkGroup {
	let title: String
	let links: [LabeledLink]
}

extension [LabeledLink] {
	/**
	Adds the links like assigning keys to a JavaScript object: a link with an existing title replaces the URL in place, and new titles are appended.
	*/
	func merging(_ links: some Sequence<LabeledLink>) -> Self {
		var result = self
		var indices = [String: Int]()

		for (index, link) in enumerated() where indices[link.title] == nil {
			indices[link.title] = index
		}

		for link in links {
			if let index = indices[link.title] {
				result[index] = link
			} else {
				indices[link.title] = result.endIndex
				result.append(link)
			}
		}

		return result
	}
}
