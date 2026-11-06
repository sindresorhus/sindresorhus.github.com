import Elementary
import Foundation
import SiteKit

/**
Free older versions of the apps for older macOS versions, grouped by version, with direct downloads.
*/
struct OlderVersionsPage: Page {
	let content: SiteContent

	var path: RoutePath {
		.olderVersions
	}

	var socialImage: SocialImage {
		.card(OpenGraphCard(page: self, project: content.project))
	}

	var metadata: PageMetadata {
		PageMetadata(title: "Older Versions", description: "Free older versions of apps by Sindre Sorhus for older macOS versions.")
	}

	var body: some HTML {
		ProsePage(title: .plain("Older Versions", intro: "Free older versions of my macOS apps for older macOS versions, also of my paid apps.")) {
			// A link to each version, as the page is long, and a visitor only needs the version of their Mac.
			ChipNavigation(label: "macOS versions", links: versions.map { LabeledLink($0.title, destination: .fragment($0.id)) }, scrollsOnPhones: true)
				.style {
					$0.justifyContent(.start)
				}

			for version in versions {
				Section(version.title, id: ElementID(version.id)) {
					ul {
						for app in content.listedApps {
							if let olderVersion = content.listing(of: app).olderVersion(for: version) {
								// A version for an older macOS version says so, as the section is for a newer one.
								LinkRow(
									link: LabeledLink("\(app.title) \(olderVersion.version)", destination: .url(olderVersion.url), description: app.subtitle),
									note: olderVersion.macOS == version ? nil : "for \(olderVersion.macOS.title) or later"
								)
							}
						}
					}
				}
			}
		}
	}

	/**
	The versions that have older app versions, newest first.
	*/
	private var versions: [MacOSVersion] {
		MacOSVersion.allCases.reversed().filter(Set(content.listedApps.flatMap(\.olderVersions).map(\.macOS)).contains)
	}
}
