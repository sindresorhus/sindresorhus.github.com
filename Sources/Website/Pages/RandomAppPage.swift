import Elementary
import Foundation
import SiteKit

/**
Redirects to a random app with JavaScript.
*/
struct RandomAppPage: Page {
	let content: SiteContent

	var path: RoutePath {
		.randomApp
	}

	var metadata: PageMetadata {
		PageMetadata(title: PageMetadata.titled("Random App"), isIndexed: false)
	}

	var body: some HTML {
		ProsePage {
			h1 {
				"Random App"
			}

			p {
				"JavaScript is required to show a random app. You can always browse the "
				a(.href(.apps)) {
					"app list"
				}
				" manually."
			}
			.style(Styles.scriptingNotice)
		}

		JSONScript(id: ScriptHook.randomAppData.rawValue, ["slugs": content.activeApps.map(\.slug)])
		ModuleScript("/scripts/random-app.js")
	}

	enum Styles: StyleSet {
		/**
		Only shown when JavaScript is turned off.
		*/
		case scriptingNotice

		var style: Style {
			Style()
				.hidden()
				.media(.scriptingDisabled) {
					$0.display(.block)
				}
		}
	}
}
