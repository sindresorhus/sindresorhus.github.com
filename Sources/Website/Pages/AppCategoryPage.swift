import Elementary
import Foundation
import SiteKit

/**
The apps of a category, like the free apps, as cards like on the apps page.
*/
struct AppCategoryPage: Page {
	let category: AppCategory
	let content: SiteContent

	var path: RoutePath {
		category.path
	}

	private var description: MarkdownDocument {
		MarkdownDocument(parsing: category.description, options: .site)
	}

	var metadata: PageMetadata {
		PageMetadata(title: category.title, description: description.introduction)
	}

	var body: some HTML {
		section {
			PageHeader(title: category.title) {
				description.inlineContent
			}

			let apps = category.apps(in: content)

			if apps.isEmpty {
				p {
					"No apps found."
				}
			} else if category.isGroupedByPlatform {
				for platform in Platform.allCases {
					let platformApps = apps.filter { $0.platforms.contains(platform) }

					if !platformApps.isEmpty {
						Section(platform.rawValue, id: platform.rawValue.lowercased()) {
							AppGrid(apps: platformApps, content: content)
						}
					}
				}
			} else {
				AppGrid(apps: apps, content: content)
			}

			if let footer = category.footer {
				div {
					Prose(markdown: MarkdownDocument(parsing: footer, options: .site).content)
				}
				.style(Styles.footer)
			}
		}
		.style(Styles.root)
	}

	enum Styles: StyleSet {
		case root
		case footer

		var style: Style {
			switch self {
			case .root:
				Style()
					.pageColumn(.page)
			case .footer:
				Style()
					.margin(.top, .rootEm(4))
					.textAlign(.center)
			}
		}
	}
}
