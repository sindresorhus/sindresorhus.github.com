import Elementary
import Foundation
import SiteKit
import SOML

struct ReleaseNotesPage: Page {
	let app: App
	let releaseNotes: App.ReleaseNotes
	let releases: [GitHubRelease]
	let project: Project

	var path: RoutePath {
		releaseNotes.path
	}

	var navigation: SiteHeader.Variant {
		.appSubpage(app)
	}

	var breadcrumbTitle: String {
		"Release Notes"
	}

	/**
	A card of its own, with the latest version in the subtitle, so a link to the release notes does not look like a link to the app page, and each release gives the card a new URL. The title is only “Release Notes”, as the title of the page would break into two lines, and the subtitle and the icon name the app.
	*/
	var socialImage: SocialImage {
		.card(
			OpenGraphCard(
				path: OpenGraphCard.path(ofPage: path),
				title: "Release Notes",
				subtitle: description,
				artwork: .icon(of: app, project: project),
				description: metadata.title
			)
		)
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

	var searchKeywords: [String] {
		["changelog", "what’s new", "version history"]
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

					if !release.notes.rawValue.isEmpty {
						div {
							release.notes
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
				iconSize: .rootEm(1),
				// The icon ends at the edge of the text, like the back link at the start of the row.
				isOutset: true
			)
				.help("RSS feed for release notes")
		}
	}

	enum Styles: String, StyleSet {
		case release
		case releaseHeader
		case releaseTitle
		case releaseDate
		case releaseNotes

		/**
		The width of the column of the versions on wide screens, and the space between it and the notes. Together, they are the 11rem of the column of ``Breakpoint/proseWithSideColumn``.
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
					.from(.proseWithSideColumn) {
						$0
							.grid(columns: .fixed(Self.versionColumnWidth), .fraction(1))
							.gap(Self.versionColumnSpacing)
							// The version and the first note share a baseline.
							.alignItems(.baseline)
							.margin(.leading, .length(-(Self.versionColumnWidth + Self.versionColumnSpacing)))
					}
			case .releaseHeader:
				// In the column, it stays in view while its notes scroll, below the header of the site.
				Style()
					.hstack(alignment: .baseline, spacing: .rootEm(1))
					.from(.proseWithSideColumn) {
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
					// Digits of one width, so the dates after versions of the same length line up.
					.monospacedDigit()
					// Smaller in the column, so the notes, not the versions, draw the eye.
					.from(.proseWithSideColumn) {
						$0.font(size: .em(1.5), lineHeight: 1.2)
					}
			case .releaseNotes:
				// Next to the version in the column, the first note starts on the line of the version. Below the version, the margin of the first note is the space between them. At the end, also the margin of the last item of a list, which is inside the notes in the grid.
				Style()
					.descendants(":last-child") {
						$0.margin(.bottom, .zero)
					}
					.from(.proseWithSideColumn) {
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
