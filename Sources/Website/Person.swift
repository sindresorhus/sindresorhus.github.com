import Foundation
import SiteKit

/**
A person, for the footer links and structured data.
*/
struct Person {
	struct SocialLink {
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

	/**
	A smaller copy of the photo, for where it shows small, like on the home page. It is 320 pixels wide, so it is sharp up to 160 CSS pixels on a screen with two pixels for each CSS pixel.
	*/
	let smallPhotoPath: RoutePath

	/**
	The GitHub profile, which is also in the social links, like for the links to the code.
	*/
	let gitHubURL: URL

	let socialLinks: [SocialLink]

	static let sindreSorhus: Self = {
		let gitHubURL = #URL("https://github.com/sindresorhus")

		return Self(
			name: "Sindre Sorhus",
			givenName: "Sindre",
			familyName: "Sorhus",
			twitterHandle: "@sindresorhus",
			fediverseHandle: "@sindresorhus@mastodon.social",
			email: "sindresorhus@gmail.com",
			photoPath: "/assets/sindre-sorhus.jpg",
			smallPhotoPath: "/assets/sindre-sorhus-small.jpg",
			gitHubURL: gitHubURL,
			socialLinks: [
				SocialLink(name: "X (Twitter)", url: #URL("https://x.com/sindresorhus"), icon: .x),
				SocialLink(name: "Mastodon", url: #URL("https://mastodon.social/@sindresorhus"), icon: .mastodon),
				SocialLink(name: "Bluesky", url: #URL("https://bsky.app/profile/sindresorhus.com"), icon: .bluesky),
				SocialLink(name: "Instagram", url: #URL("https://instagram.com/sindresorhus"), icon: .instagram, isIdentity: false),
				SocialLink(name: "Unsplash", url: #URL("https://unsplash.com/@sindresorhus"), icon: .unsplash, isIdentity: false),
				SocialLink(name: "GitHub", url: gitHubURL, icon: .github),
			]
		)
	}()

	/**
	The profiles that identify the person in structured data, with GitHub first.
	*/
	var sameAs: [URL] {
		let profiles = socialLinks.filter(\.isIdentity)
		return (profiles.filter { $0.icon == .github } + profiles.filter { $0.icon != .github }).map(\.url)
	}
}
