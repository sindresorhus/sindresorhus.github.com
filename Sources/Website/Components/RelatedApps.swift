import Elementary
import Foundation
import SiteKit

/**
Four similar apps as cards: the best matches by platform, menu bar, and price, with a daily shuffle among equally good matches. The page leaves it out when there are none.
*/
struct RelatedApps: HTML {
	let relatedApps: [App]
	let content: SiteContent

	var body: some HTML<HTMLTag.aside> {
		aside(.ariaLabelledBy(Self.titleID)) {
			h2(.id(Self.titleID)) {
				"You Might Also Like"
			}
			.style(SectionStyles.label)

			AppGrid(apps: relatedApps, buildDate: content.buildDate)
		}
		.style {
			$0.contentColumn(.page)
		}
	}

	private static let titleID = ElementID("related-apps")
}
