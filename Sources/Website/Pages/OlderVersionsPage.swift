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

	/**
	The icons of the apps with the most older versions.
	*/
	var socialImage: SocialImage {
		.card(OpenGraphCard(page: self, artwork: .icons(ofMostCommon: content.listedApps.flatMap { Array(repeating: $0, count: $0.olderVersions.count) }, project: content.project)))
	}

	var metadata: PageMetadata {
		PageMetadata(title: "Older Versions", description: "Free older versions of apps by Sindre Sorhus for older macOS versions.")
	}

	var body: some HTML {
		// In the order of the alphabet, as a visitor looks for one app by its name.
		let alphabeticalApps = content.listedApps.sorted(using: KeyPathComparator(\.title, comparator: .localizedStandard))

		ProsePage(title: .plain("Older Versions", intro: "Free versions of my Mac apps for older macOS versions, also of the paid apps.")) {
			// How to install the zip files, like below the “Older Versions” section of an app page.
			p {
				MarkdownTheme.site.headingTextHTML(AppDownloadCard.installSentence)
			}
			.style(ProseStyles.sideNote)

			// A link to each version, as the page is long, and a visitor only needs the version of their Mac.
			ChipNavigation(label: "macOS versions", links: versions.map { LabeledLink($0.title, destination: .fragment($0.id)) }, scrollsOnPhones: true)
				.style {
					$0.textAlign(.leading)
				}

			for version in versions {
				Section(version.title, id: ElementID(version.id)) {
					ul {
						for app in alphabeticalApps {
							if let olderVersion = content.listing(of: app).olderVersion(for: version) {
								// A version for an older macOS version says so, as the section is for a newer one.
								LinkRow(
									link: LabeledLink("\(app.title) \(olderVersion.version)", destination: .url(olderVersion.url), description: app.displaySubtitle),
									note: olderVersion.macOS == version ? nil : "for \(olderVersion.macOS.requirement)"
								)
							}
						}
					}
					// Two columns from tablets, as the rows are short, so the page is much shorter, and a visitor finds the version of an app sooner. Each row stays in one column.
					// The space below each row is padding, not a margin, as browsers leave out a margin at the top of a column, or Safari moves it to the next column, so the columns would not start at the same height.
					.style {
						$0.from(.tablet) {
							$0
								.columns(2, minimumWidth: .rootEm(16))
								.gap(column: .rootEm(2.5))
								.children("li") {
									$0
										.keepsTogether()
										.margin(.zero)
										.padding(.bottom, ProseStyles.listItemSpacing)
								}
						}
					}
				}
			}
		}
	}

	/**
	The versions that have older app versions, newest first. The site search has a section for each (``SiteSearch/Index``).
	*/
	var versions: [MacOSVersion] {
		MacOSVersion.allCases.reversed().filter(Set(content.listedApps.flatMap(\.olderVersions).map(\.macOS)).contains)
	}
}
