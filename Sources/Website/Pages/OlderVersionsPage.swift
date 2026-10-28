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
		PageMetadata(title: "Older Versions — Apps", description: "Free older versions of apps by Sindre Sorhus for older macOS versions.")
	}

	var body: some HTML {
		ProsePage(title: .plain("Older Versions", intro: "Free older versions of my macOS apps for older macOS versions, also of my paid apps.")) {
			for version in versions {
				Section("macOS \(version.rawValue)", id: ElementID(version.id)) {
					ul {
						for app in content.listedApps {
							if let olderVersion = content.listing(of: app).olderVersion(for: version) {
								// A version for an older macOS version says so, as the section is for a newer one.
								let title = "\(app.title) \(olderVersion.version)" + (olderVersion.macOS == version ? "" : " (for macOS \(olderVersion.macOS.rawValue) or later)")
								LinkRow(link: LabeledLink(title, destination: .url(olderVersion.url), description: app.subtitle))
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
