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
		JSONScript(id: Hooks.slugs, content.activeAppsWithPages.map(\.slug))

		script {
			HTMLRaw(#"""
			{
				const slugs = JSON.parse(document.querySelector('#\#(Hooks.slugs.rawValue)').textContent);
				const referrerApp = URL.parse(document.referrer)?.pathname.split('/')[1];
				const candidates = slugs.filter(slug => slug !== referrerApp);

				if (candidates.length > 0) {
					location.replace(`/${candidates[Math.floor(Math.random() * candidates.length)]}#\#(AppHero.anotherRandomAppID)`);
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
	The IDs and data attributes that the scripts of the page find elements by.
	*/
	enum Hooks: String, ScriptHookSet {
		case slugs = "random-app-slugs"
	}

	enum Styles: StyleSet {
		/**
		Only shown when JavaScript is turned off. Otherwise, the page redirects before it shows.
		*/
		case scriptingDisabledOnly

		var style: Style {
			Style().shownOnlyWithoutScripting()
		}
	}
}
