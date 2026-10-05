import Foundation
import SiteKit

/**
A person, for the footer links and structured data.
*/
struct Person: Sendable {
	struct SocialLink: Sendable {
		let name: String
		let url: URL
		let icon: Icon

		/**
		Whether the profile identifies the person in structured data.
		*/
		var isIdentity = true
	}

	let name: String
	let givenName: String
	let familyName: String
	let twitterHandle: String
	let fediverseHandle: String
	let email: String

	/**
	A public path, like `/assets/sindre-sorhus.jpg`.
	*/
	let photoPath: RoutePath

	let socialLinks: [SocialLink]

	static let sindreSorhus = Self(
		name: "Sindre Sorhus",
		givenName: "Sindre",
		familyName: "Sorhus",
		twitterHandle: "@sindresorhus",
		fediverseHandle: "@sindresorhus@mastodon.social",
		email: "sindresorhus@gmail.com",
		photoPath: "/assets/sindre-sorhus.jpg",
		socialLinks: [
			SocialLink(name: "X (Twitter)", url: #URL("https://x.com/sindresorhus"), icon: .x),
			SocialLink(name: "Mastodon", url: #URL("https://mastodon.social/@sindresorhus"), icon: .mastodon),
			SocialLink(name: "Bluesky", url: #URL("https://bsky.app/profile/sindresorhus.com"), icon: .bluesky),
			SocialLink(name: "Instagram", url: #URL("https://instagram.com/sindresorhus"), icon: .instagram, isIdentity: false),
			SocialLink(name: "Unsplash", url: #URL("https://unsplash.com/@sindresorhus"), icon: .unsplash, isIdentity: false),
			SocialLink(name: "GitHub", url: #URL("https://github.com/sindresorhus"), icon: .github),
		]
	)

	/**
	The profiles that identify the person in structured data, with GitHub first.
	*/
	var sameAs: [URL] {
		let profiles = socialLinks.filter(\.isIdentity)
		return (profiles.filter { $0.icon == .github } + profiles.filter { $0.icon != .github }).map(\.url)
	}
}
