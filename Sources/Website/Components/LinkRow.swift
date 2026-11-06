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

	var body: some HTML<HTMLTag.li> {
		li {
			a(.href(link.destination)) {
				link.title
			}

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
					.font(size: .em(0.875))
					.color(.secondaryText)
			}
		}
	}
}

extension LinkRow {
	/**
	The app with its subtitle.
	*/
	init(app: App) {
		self.init(link: LabeledLink(app.title, destination: app.url, description: app.subtitle))
	}
}
