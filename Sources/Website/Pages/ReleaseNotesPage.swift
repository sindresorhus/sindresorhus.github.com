import Elementary
import Foundation
import SiteKit
import SOML

struct ReleaseNotesPage: Page {
	let app: App
	let releaseNotes: App.ReleaseNotes
	let releases: [GitHubRelease]

	var path: RoutePath {
		releaseNotes.path
	}

	var navigation: SiteHeader.Variant {
		.appSubpage(app)
	}

	var socialImage: SocialImage {
		.cardOf(app)
	}

	/**
	An unlisted app is left out, as it is not indexed, like its app page.
	*/
	var sitemapEntry: SitemapEntry {
		SitemapEntry(lastModified: releases.first.map { SOML.Date($0.publishedAt) })
	}

	var metadata: PageMetadata {
		PageMetadata(
			// The app first, as people search for the changelog of an app, and a phone cuts a long title at the end.
			title: "\(app.title) Release Notes",
			description: description,
			isIndexed: app.isListed,
			favicon: app.iconPath,
			feeds: [releaseNotes.feed]
		)
	}

	/**
	The latest version and its date, so search results show that the page is current.
	*/
	private var description: String {
		let summary = "What is new in each version of \(app.title)."

		guard let latest = releases.first else {
			return summary
		}

		return "\(summary) The latest is \(latest.version), from \(latest.publishedAt.formatted(.siteDay))."
	}

	var body: some HTML {
		ProsePage(app: app, title: "Release Notes") {
			for release in releases {
				article {
					div {
						// The tag is external data, so it is not validated as an element ID.
						h2(.id(release.version)) {
							release.version
						}
						.style(Styles.releaseTitle)

						DateText(day: SOML.Date(release.publishedAt), format: .siteDay)
							.style(Styles.releaseDate)
					}
					.style(Styles.releaseHeader)

					if !release.notesHTML.isEmpty {
						div {
							HTMLRaw(release.notesHTML)
						}
						.style(Styles.releaseNotes)
					}
				}
				.style(Styles.release)
			}
		} accessory: {
			IconLink(
				"\(app.title) Release Notes RSS Feed",
				icon: .rss,
				destination: .path(releaseNotes.feed.path),
				iconSize: .rootEm(1)
			)
				.help("RSS feed for release notes")
		}
	}

	enum Styles: StyleSet {
		case release
		case releaseHeader
		case releaseTitle
		case releaseDate
		case releaseNotes

		/**
		The width of the column of the versions on wide screens, and the space between it and the notes.
		*/
		private static let versionColumnWidth = LengthPercentage.rootEm(9)
		private static let versionColumnSpacing = LengthPercentage.rootEm(2)

		var style: Style {
			switch self {
			case .release:
				// On wide screens, the version and the date are in a column in the empty space at the left of the notes, so the versions make a line to scan down, and the notes stay in line with the text above them. Not on smaller screens, which have no space for it.
				// The padding is the only space between releases, as the notes have no margins at their ends, so each release has the same space, whichever column is taller.
				Style()
					.padding(.vertical, .rootEm(1.5))
					.from(.desktop) {
						$0
							.display(.grid)
							.gridColumns(.fixed(Self.versionColumnWidth), .fraction(1))
							.gap(Self.versionColumnSpacing)
							// The version and the first note share a baseline.
							.alignItems(.baseline)
							.margin(.leading, .length(-(Self.versionColumnWidth + Self.versionColumnSpacing)))
					}
			case .releaseHeader:
				// In the column, it stays in view while its notes scroll, below the header of the site.
				Style()
					.hstack(alignment: .baseline, spacing: .rootEm(1))
					.from(.desktop) {
						$0
							.vstack(alignment: .end, spacing: .rootEm(0.25))
							.position(.sticky)
							.top(.length(SiteHeader.height + .rootEm(1)))
							.textAlign(.trailing)
							// The site header is not sticky on a short screen, so nothing is above it.
							.media(.shortScreen) {
								$0.top(.rootEm(1))
							}
					}
			case .releaseTitle:
				// Not the margins of a prose heading, which add space in the flex row.
				Style()
					.margin(.zero)
					.font(.extraLarge2)
					.from(.laptop) {
						$0.font(size: .em(1.8), lineHeight: 1.1111)
					}
					// Smaller in the column, so the notes, not the versions, draw the eye.
					.from(.desktop) {
						$0.font(size: .em(1.5), lineHeight: 1.2)
					}
			case .releaseNotes:
				// Next to the version in the column, the first note starts on the line of the version. Below the version, the margin of the first note is the space between them. At the end, also the margin of the last item of a list, which is inside the notes in the grid.
				Style()
					.descendants(":last-child") {
						$0.margin(.bottom, .zero)
					}
					.from(.desktop) {
						$0.children(":first-child") {
							$0.margin(.top, .zero)
						}
					}
			case .releaseDate:
				Style()
					.secondaryText()
			}
		}
	}
}
