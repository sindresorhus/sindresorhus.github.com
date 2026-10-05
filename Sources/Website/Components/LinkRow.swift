import Elementary
import SiteKit

/**
A list item with a link and a description, like “Dato — Menu bar calendar”.
*/
struct LinkRow: HTML {
	let title: String
	let destination: LinkDestination
	let description: String?

	var body: some HTML<HTMLTag.li> {
		li {
			a(.href(destination)) {
				title
			}

			if let description {
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
		self.init(title: app.title, destination: destination ?? app.url, description: app.subtitle)
	}

	init(link: LabeledLink) {
		self.init(title: link.title, destination: link.destination, description: link.description)
	}
}
