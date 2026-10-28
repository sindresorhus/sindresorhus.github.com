import SiteKit

/**
A feed for feed readers to discover, like the release notes of an app. Pages link to it in the head.
*/
struct FeedLink: Sendable {
	let title: String
	let path: RoutePath
}
