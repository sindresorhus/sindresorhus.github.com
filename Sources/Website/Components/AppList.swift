import Elementary
import SiteKit

/**
A bulleted list of apps with their subtitles, optionally grouped by platform.
*/
struct AppList: HTML {
	let apps: [App]
	var isGroupedByPlatform = false

	var body: some HTML {
		if isGroupedByPlatform {
			for platform in Platform.allCases {
				let platformApps = apps.filter { $0.platforms.contains(platform) }

				if !platformApps.isEmpty {
					Section(platform.rawValue, id: platform.rawValue.lowercased()) {
						AppList(apps: platformApps)
					}
				}
			}
		} else {
			ul {
				for app in apps {
					LinkRow(app: app)
				}

				if apps.isEmpty {
					li {
						"No apps found."
					}
				}
			}
		}
	}
}
