import Elementary
import SiteKit

/**
The header of a page about one app, like its privacy policy: the icon of the app, its name, and the title of the page, so visitors who come to the page directly, like from the app, see at once which app it is about.

```swift
AppHeader(app: app, title: "Privacy Policy")
```

The feedback form shows it for the app that its script selects (``selectedByScript(title:accessory:)``).
*/
struct AppHeader<Accessory: HTML>: HTML {
	/**
	Which app the header shows.
	*/
	private enum Source {
		case app(App)

		/**
		The script of the page fills in the app (``AppHeader/selectedByScript(title:accessory:)``).
		*/
		case selectedByScript
	}

	private let source: Source

	private let title: String
	private let accessory: Accessory

	/**
	- Parameter accessory: Shown next to the name of the app, like a link to pick another app.
	*/
	init(app: App, title: String, @ContentBuilder accessory: () -> Accessory) {
		self.source = .app(app)
		self.title = title
		self.accessory = accessory()
	}

	private init(title: String, accessory: Accessory) {
		self.source = .selectedByScript
		self.title = title
		self.accessory = accessory
	}

	/**
	The header without an app, for a page whose script selects the app, like the feedback form. The script puts the icon in place of the template (``AppHeaderIDs/iconTemplate``), and fills in and shows the name (``AppHeaderIDs/name``). The heading has no name of an app, so the script also adds the name to the title of the document.
	*/
	static func selectedByScript(title: String, @ContentBuilder accessory: () -> Accessory) -> Self {
		Self(title: title, accessory: accessory())
	}

	var body: some HTML<HTMLTag.header> {
		header {
			switch source {
			case .app(let app):
				AppIcon(decorative: app, size: 128, isAboveFold: true)
					.style(AppHeaderStyles.icon)
			case .selectedByScript:
				// A template, as an image must have a source.
				template(.id(AppHeaderIDs.iconTemplate)) {
					img(.alt(""), .width(128), .height(128))
						.style(AppHeaderStyles.icon)
				}
			}

			div {
				div {
					switch source {
					case .app(let app):
						// Screen readers read the name in the title. Not translated, so visitors find it on the App Store, like in the hero.
						span(.notTranslated) {
							app.title
						}
						.accessibilityHidden()
					case .selectedByScript:
						span(.id(AppHeaderIDs.name), .hidden) {}
					}

					accessory
				}
				.style(AppHeaderStyles.name)

				h1 {
					title

					if case .app(let app) = source {
						VisuallyHidden(" for \(app.title)")
					}
				}
				.style(PageHeaderStyles.title)
			}
			.style(AppHeaderStyles.text)
		}
		.style(AppHeaderStyles.root)
	}
}

extension AppHeader where Accessory == EmptyHTML {
	init(app: App, title: String) {
		self.init(app: app, title: title) {
			EmptyHTML()
		}
	}
}

/**
The IDs that the script of the page fills in, for ``AppHeader/selectedByScript(title:accessory:)``. Outside the generic type, so the script finds the same IDs for every accessory.
*/
enum AppHeaderIDs: String, ScriptIDSet {
	case iconTemplate = "app-icon-template"
	case name = "product-name"
}

/**
The styles of ``AppHeader``, outside the generic type, so the class names are the same for every accessory.
*/
private enum AppHeaderStyles: String, StyleSet {
	case root
	case icon
	case text
	case name

	var style: Style {
		switch self {
		case .root:
			// The text goes below the icon when it has too little room next to it, like on a phone with large text (``text``).
			Style()
				.hstack(alignment: .center, spacing: .rootEm(1.25))
				.flexWrap()
		case .icon:
			// About as tall as the name and the title next to it, with the shadow of the icons of the app cards.
			Style()
				.frame(width: .rootEm(5.5), height: .rootEm(5.5), minWidth: .rootEm(5.5))
				.filter(AppCard.iconShadow)
				.below(.smallTablet) {
					$0.frame(width: .rootEm(4), height: .rootEm(4), minWidth: .rootEm(4))
				}
		case .text:
			// Below the icon when it has less than 10em of room next to it, so the title does not break inside its words.
			Style()
				.flex(1)
				.frame(minWidth: .length(.min(.em(10), .percent(100))))
		case .name:
			// Above the title, like the date of a blog post.
			Style()
				.hstack(alignment: .baseline, spacing: .rootEm(0.75))
				.flexWrap()
				.margin(.bottom, .rootEm(0.25))
				.textStyle(.body, weight: .semibold)
				.color(.secondaryText)
				// Hidden while the script has not filled in the app (``AppHeader/selectedByScript(title:accessory:)``), so its margin does not move the title down.
				.nested("&:not(:has(> :not([hidden])))") {
					$0.hidden()
				}
		}
	}
}
