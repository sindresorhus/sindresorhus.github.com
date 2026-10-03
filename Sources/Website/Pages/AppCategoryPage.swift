import Elementary
import Foundation
import SiteKit

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
		PageMetadata(title: PageMetadata.titled(category.title), description: description.introduction)
	}

	var body: some HTML {
		ProsePage {
			h1 {
				category.title
			}

			HTMLRaw(description.html)
			AppList(apps: category.apps(in: content), isGroupedByPlatform: category == .free || category == .paid)

			switch category {
			case .free:
				br()

				p {
					"If you like my work, consider leaving a review on the App Store. And also check out my "
					a(.href("/apps/paid")) {
						"paid apps"
					}
					"."
				}

				p {
					a(.href(.olderVersions)) {
						"Older versions"
					}
					" of paid apps for older macOS versions are available for free."
				}
			case .paid:
				br()

				p {
					"You can find my free apps "
					a(.href("/apps/free")) {
						"here"
					}
					"."
				}
			default:
				EmptyHTML()
			}
		}
	}
}
