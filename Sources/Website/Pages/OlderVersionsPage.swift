import Elementary
import Foundation
import SiteKit

/**
Free older versions of the apps for older macOS versions, grouped by version.
*/
struct OlderVersionsPage: Page {
	let content: SiteContent

	var path: RoutePath {
		.olderVersions
	}

	var metadata: PageMetadata {
		PageMetadata(title: PageMetadata.titled("Older Versions", "Apps"), description: "Free older versions of apps by Sindre Sorhus for older macOS versions.")
	}

	var body: some HTML {
		ProsePage {
			h1 {
				"Older Versions"
			}

			p {
				"My macOS apps with an older version compatible with the following macOS versions."
			}

			p {
				"Even my paid apps are free for these older versions."
			}

			for version in versions {
				Section("macOS \(version.rawValue)", id: version.id) {
					ul {
						for app in content.listedApps where app.olderMacOSVersions.contains(version) {
							LinkRow(app: app, destination: app.olderVersionsURL)
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
		Set(content.listedApps.flatMap(\.olderMacOSVersions)).sorted(using: KeyPathComparator(\.number, order: .reverse))
	}
}
