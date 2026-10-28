import Elementary
import SiteKit

/**
A list item with a link and a description, like “Dato — Menu bar calendar”.
*/
struct LinkRow: HTML {
	let link: LabeledLink

	var body: some HTML<HTMLTag.li> {
		li {
			a(.href(link.destination)) {
				link.title
			}

			if let description = link.description {
				span {
					" — \(description)"
				}
				.style(Styles.description)
			}
		}
	}

	enum Styles: StyleSet {
		case description

		var style: Style {
			Style().color(.secondaryText)
		}
	}
}

extension LinkRow {
	/**
	The app with its subtitle.
	*/
	init(app: App, destination: LinkDestination? = nil) {
		self.init(link: LabeledLink(app.title, destination: destination ?? app.url, description: app.subtitle))
	}
}
