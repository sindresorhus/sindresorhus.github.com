import Foundation
import SiteKit

/**
The values of the whole site that are content, not code, so they are changed without Swift, loaded from `content/site.soml`.

```soml
featuredApps: [
	'velja'
	'supercharge'
]
appUserCount: 6000000
supportEmailCount: 10000
```
*/
@Frontmatter
struct SiteSettings {
	/**
	The slugs of the main apps, like `velja`, at most ``maximumFeaturedAppCount``. The apps page shows them first, in an order that changes every day (``SiteContent/dailyFeaturedApps``), so each of them is sometimes first, and `llms.txt` lists them first, in this order. Each must be an active app with its own page.
	*/
	var featuredApps = [String]()

	/**
	About how many people use the apps. No service counts this, so it is updated by hand. The apps page and the about page show it rounded down, like “6M+ users”.
	*/
	var appUserCount: Int

	/**
	About how many support emails Sindre has answered. No service counts this, so it is updated by hand. The apps page and the about page show it rounded down, like “10K+”.
	*/
	var supportEmailCount: Int

	/**
	The path of the file, relative to the root of the project.
	*/
	static let path = "content/site.soml"

	/**
	The most apps that the apps page features.
	*/
	static let maximumFeaturedAppCount = 4

	func validate(into problems: inout FrontmatterProblems<Self>) {
		problems.addRepeatedItems(of: featuredApps, at: .featuredApps)

		for (index, slug) in featuredApps.enumerated().dropFirst(Self.maximumFeaturedAppCount) {
			problems.add("The apps page features at most \(Self.maximumFeaturedAppCount) apps. Remove `\(slug)` or another app.", at: .featuredApps, index: index)
		}

		// The apps page and the about page show the counts, like “6M+ users”.
		for (count, key) in [(appUserCount, CodingKeys.appUserCount), (supportEmailCount, .supportEmailCount)] where count < 1 {
			problems.add("The pages show the count, so it must be more than 0, not \(count).", at: key)
		}
	}
}

extension SiteSettings {
	/**
	Settings from values, like for content that is made in code.
	*/
	init(
		featuredApps: [String] = [],
		appUserCount: Int = 0,
		supportEmailCount: Int = 0
	) {
		self.featuredApps = featuredApps
		self.appUserCount = appUserCount
		self.supportEmailCount = supportEmailCount
	}
}
