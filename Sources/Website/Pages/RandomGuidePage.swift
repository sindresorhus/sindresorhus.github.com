import Elementary
import Foundation
import SiteKit

/**
Redirects to a random guide with JavaScript, like the random app (``RandomAppPage``), so a visitor of the list of guides can find a useful trick by chance.
*/
struct RandomGuidePage: Page {
	let content: SiteContent

	var path: RoutePath {
		.randomGuide
	}

	var metadata: PageMetadata {
		PageMetadata(title: "Random Guide", isIndexed: false)
	}

	/**
	A classic script in the head redirects before the page shows, so the visitor never sees this page. It skips the guide the visitor comes from.
	*/
	var head: some HTML {
		JSONScript(id: IDs.guides, content.guides.map(\.guide.path))

		script {
			HTMLRaw(#"""
			{
				const paths = JSON.parse(document.querySelector('#\#(IDs.guides.id)').textContent);
				const referrerPath = URL.parse(document.referrer)?.pathname;
				const candidates = paths.filter(path => path !== referrerPath);

				if (candidates.length > 0) {
					location.replace(candidates[Math.floor(Math.random() * candidates.length)]);
				}
			}
			"""#)
		}
	}

	var body: some HTML {
		ProsePage(title: "Random Guide") {
			p {
				"JavaScript is required to show a random guide. You can always browse the "
				a(.href(.guides)) {
					"list of guides"
				}
				" manually."
			}
		}
		.style(RandomAppPage.Styles.scriptingDisabledOnly)
	}

	/**
	The IDs that the scripts of the page find elements by.
	*/
	enum IDs: String, ScriptIDSet {
		case guides = "random-guides"
	}
}
