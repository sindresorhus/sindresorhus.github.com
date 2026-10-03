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

	var lastModified: Date? {
		releases.first?.publishedAt
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

						DateText(release.publishedAt, format: .site.month(.wide).day().year())
							.style(Styles.releaseDate)
					}
					.style(Styles.releaseHeading)

					if !release.notesHTML.isEmpty {
						div {
							HTMLRaw(release.notesHTML)
						}
					}
				}
				.style(Styles.release)
			}
		} accessory: {
			IconLink(url: releaseNotes.feed.path.description, label: "\(app.title) Release Notes RSS Feed", icon: .rss, title: "RSS feed for release notes", iconSize: .rem(1))
		}
		.style(Styles.root)
	}

	enum Styles: StyleSet {
		case root
		case release
		case releaseHeading
		case releaseTitle
		case releaseDate

		var style: Style {
			switch self {
			case .root:
				Style()
					.padding(.bottom, .rem(4))
					.nested("h1") {
						$0
							.font(.xl3)
							.breakpoint(.lg) {
								$0.font(size: .em(2.8), lineHeight: 1)
							}
					}
			case .release:
				Style().padding(.vertical, .rem(1))
			case .releaseHeading:
				Style().hstack(alignment: .baseline, spacing: .rem(1))
			case .releaseTitle:
				Style()
					.font(.xl2)
					.breakpoint(.lg) {
						$0.font(size: .em(1.8), lineHeight: 1.1111)
					}
			case .releaseDate:
				Style()
					.font(.sm)
					.color(.gray(600))
			}
		}
	}
}
