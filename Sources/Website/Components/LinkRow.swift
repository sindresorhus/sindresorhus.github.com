import Elementary
import SiteKit

/**
A list item with a link and a description on its own line below it, like “Dato” and “Menu bar calendar”, so a row that wraps does not mix the link and the description on one line.
*/
struct LinkRow: HTML {
	let link: LabeledLink

	/**
	Secondary text after the link, on its line, like the requirement of an older version of an app, so the link is only the name of what it opens.
	*/
	var note: String?

	/**
	Whether the link has the arrow of a link to another site (``AppFooterLinks/Styles/otherSitePageLink``), like a search on GitHub in a list of pages of the site. A list where all links leave the site, like the downloads of older versions, does not need it.
	*/
	var isExternal = false

	var body: some HTML<HTMLTag.li> {
		li {
			a(.href(link.destination)) {
				link.title
			}
			.style(AppFooterLinks.Styles.otherSitePageLink, when: isExternal)

			if let note {
				" "

				span {
					note
				}
				.style(Styles.note)
			}

			if let description = link.description {
				span {
					description
				}
				.style(Styles.description)
			}
		}
	}

	enum Styles: String, StyleSet {
		case note
		case description

		var style: Style {
			switch self {
			case .note:
				Style().color(.secondaryText)
			case .description:
				// Smaller, like the descriptions of the rows of the App Timeline.
				Style()
					.display(.block)
					.secondaryText()
			}
		}
	}
}

extension LinkRow {
	/**
	The app with its subtitle.
	*/
	init(app: App) {
		self.init(link: LabeledLink(app.title, destination: app.url, description: app.displaySubtitle))
	}
}
