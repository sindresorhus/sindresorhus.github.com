import Foundation
import SiteKit

/**
A link with a visible label, like a button in the app header.
*/
@Frontmatter
public struct LabeledLink: Hashable {
	public var title: String

	@Key("url")
	public var destination: LinkDestination

	public var description: String?

	public init(_ title: String, destination: LinkDestination, description: String? = nil) {
		self.title = title
		self.destination = destination
		self.description = description
	}

	public init(_ title: String, url: URL) {
		self.init(title, destination: .url(url))
	}

	public init(_ title: String, path: RoutePath) {
		self.init(title, destination: .path(path))
	}

	/**
	The link for an `href` attribute.
	*/
	public var href: String {
		destination.description
	}
}

/**
Links under a heading, like the groups in `content/apps-extra.json`.
*/
@Frontmatter
public struct LinkGroup {
	@Key("label")
	public var title: String

	@Key("items")
	public var links: [LabeledLink]

	public init(title: String, links: [LabeledLink]) {
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
