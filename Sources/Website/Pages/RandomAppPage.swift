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
		PageMetadata(title: "Random App", isIndexed: false)
	}

	/**
	A classic script in the head redirects before the page shows, so the visitor never sees this page. It skips the app the visitor comes from, and `#another-random-app` shows the “Another Random App” button on the app page.
	*/
	var head: some HTML {
		JSONScript(id: IDs.apps, content.activeAppsWithPages.map { AppTarget(slug: $0.slug, path: $0.path) })

		script {
			HTMLRaw(#"""
			{
				const apps = JSON.parse(document.querySelector('#\#(IDs.apps.id)').textContent);
				const referrerApp = URL.parse(document.referrer)?.pathname.split('/')[1];
				const candidates = apps.filter(app => app.slug !== referrerApp);

				if (candidates.length > 0) {
					const app = candidates[Math.floor(Math.random() * candidates.length)];
					location.replace(`${app.path}#\#(AppHero.anotherRandomAppID)`);
				}
			}
			"""#)
		}
	}

	var body: some HTML {
		ProsePage(title: "Random App") {
			p {
				"JavaScript is required to show a random app. You can always browse the "
				a(.href(.apps)) {
					"app list"
				}
				" manually."
			}
		}
		.style(Styles.scriptingDisabledOnly)
	}

	/**
	The IDs that the scripts of the page find elements by.
	*/
	enum IDs: String, ScriptIDSet {
		case apps = "random-apps"
	}

	/**
	An app to pick: the slug that the page skips when the visitor comes from the app, and the path of its page, which content owns.
	*/
	private struct AppTarget: Encodable {
		let slug: ContentSlug
		let path: RoutePath
	}

	enum Styles: String, StyleSet {
		/**
		Only shown when JavaScript is turned off. Otherwise, the page redirects before it shows.
		*/
		case scriptingDisabledOnly

		var style: Style {
			Style().shownOnlyWithoutScripting()
		}
	}
}
