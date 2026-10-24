import Elementary
import Foundation
import SiteKit

/**
A sudoku puzzle that someone shared from Pipoku, for visitors without the app. A shared link, like `/pipoku/play?p=…`, opens in the app when it is installed, as the site associates the path with it (``appSiteAssociation``), and shows this page otherwise.
*/
struct SharedPuzzlePage: Page {
	let app: App

	/**
	The page for Pipoku, or `nil` when the site does not have the app, like when it is a draft.
	*/
	init?(apps: [App]) {
		guard let app = apps.first(where: { $0.slug == "pipoku" }) else {
			return nil
		}

		self.app = app
	}

	var path: RoutePath {
		app.path.appending("play")
	}

	var navigation: SiteHeader.Variant {
		.appSubpage
	}

	var tint: Color? {
		app.tint
	}

	var metadata: PageMetadata {
		// The puzzle is in the query, so search engines would only see the message for a missing puzzle.
		PageMetadata(title: "Shared \(app.title) Puzzle", description: "A sudoku puzzle shared from \(app.title).", isIndexed: false, appStoreID: app.appStoreID)
	}

	var body: some HTML {
		ProsePage(title: "Shared Puzzle", backTo: app) {
			p {
				"Someone shared this sudoku puzzle from "
				a(.href(app.path)) {
					app.title
				}
				". Open the link on an iPhone or iPad with \(app.title) to play it."
			}

			SudokuBoard()
		}
		.style {
			$0.padding(.bottom, .rootEm(4))
		}
	}

	/**
	The associated domain file (`/.well-known/apple-app-site-association`), so a shared puzzle opens in the app as a universal link, and shows this page without the app. It matches only the page with a `p` query item.

	The app needs the Associated Domains entitlement with `applinks:sindresorhus.com`. Apple’s CDN fetches the file, not the devices, so a change can take a day to reach them (https://developer.apple.com/documentation/xcode/supporting-associated-domains). GitHub Pages serves it as `application/octet-stream`, as it has no extension, which the CDN accepts.
	*/
	var appSiteAssociation: Data {
		struct Association: Encodable {
			struct AppLinks: Encodable {
				struct Detail: Encodable {
					struct Component: Encodable {
						let path: String
						let query: [String: String]

						enum CodingKeys: String, CodingKey {
							case path = "/"
							case query = "?"
						}
					}

					let appIDs: [String]
					let components: [Component]
				}

				let details: [Detail]
			}

			let applinks: AppLinks
		}

		let association = Association(
			applinks: .init(details: [
				.init(
					appIDs: ["YG56YK5RN5.com.sindresorhus.Pipoku"],
					// `?*` is one or more characters. The app checks the code.
					components: [.init(path: path.description, query: ["p": "?*"])]
				),
			])
		)

		return Data(JSONEncoder.pageJSON(association).utf8)
	}
}
