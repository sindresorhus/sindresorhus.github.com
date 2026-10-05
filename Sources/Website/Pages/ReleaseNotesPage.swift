import Elementary
import Foundation
import SiteKit

struct ReleaseNotesPage: Page {
	let app: App
	let releaseNotes: App.ReleaseNotes
	let releases: [GitHubRelease]

	var path: RoutePath {
		releaseNotes.path
	}

	var navigation: SiteHeader.Variant {
		.appSubpage
	}

	var sitemapEntry: SitemapEntry? {
		SitemapEntry(lastModified: releases.first?.publishedAt)
	}

	var metadata: PageMetadata {
		PageMetadata(
			title: "Release Notes — \(app.title)",
			description: "The changes in each version of the \(app.title) app.",
			feeds: [releaseNotes.feed]
		)
	}

	var body: some HTML {
		ProsePage(title: "Release Notes for \(app.title)", backTo: app) {
			for release in releases {
				article {
					div {
						h2(.id(release.version)) {
							release.version
						}
						.style(Styles.releaseTitle)

						DateText(release.publishedAt, format: .siteDay)
							.style(Styles.releaseDate)
					}
					.hstack(alignment: .baseline, spacing: .rootEm(1))

					if !release.notesHTML.isEmpty {
						div {
							HTMLRaw(release.notesHTML)
						}
					}
				}
				.style(Styles.release)
			}
		} accessory: {
			IconLink("\(app.title) Release Notes RSS Feed", icon: .rss, destination: .path(releaseNotes.feed.path), iconSize: .rootEm(1))
				.help("RSS feed for release notes")
		}
		.style(Styles.root)
	}

	enum Styles: StyleSet {
		case root
		case release
		case releaseTitle
		case releaseDate

		var style: Style {
			switch self {
			case .root:
				Style().padding(.bottom, .rootEm(4))
			case .release:
				Style().padding(.vertical, .rootEm(1))
			case .releaseTitle:
				// Not the margins of a prose heading, which add space in the flex row.
				Style()
					.margin(0)
					.font(.extraLarge2)
					.from(.laptop) {
						$0.font(size: .em(1.8), lineHeight: 1.1111)
					}
			case .releaseDate:
				Style()
					.secondaryText()
			}
		}
	}
}
