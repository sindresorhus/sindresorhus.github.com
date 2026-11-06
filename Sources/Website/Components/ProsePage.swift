import Elementary
import SiteKit

/**
A page that is a column of prose, like `/about`, optionally with a title and a link back to the app it is about.

```swift
ProsePage(app: app, title: "Privacy Policy") {
	p {
		"No data is collected."
	}
}
```
*/
struct ProsePage<Content: HTML, Accessory: HTML>: HTML {
	/**
	Only this component can pair an app heading with its back link.
	*/
	private enum Header {
		case plain(ProsePageTitle)
		case app(App, String)
	}

	private let title: Header?
	private let photo: ImageSource?
	private let app: App?
	private let content: Content
	private let accessory: Accessory

	/**
	- Parameter photo: A round photo at the start of the text, like a portrait.
	- Parameter backTo: The app to link back to, above the title.
	- Parameter accessory: Shown next to the back link, like an RSS feed link.
	*/
	init(
		title: ProsePageTitle? = nil,
		photo: ImageSource? = nil,
		backTo app: App? = nil,
		@ContentBuilder content: () -> Content, @ContentBuilder accessory: () -> Accessory
	) {
		self.title = title.map(Header.plain)
		self.photo = photo
		self.app = app
		self.content = content()
		self.accessory = accessory()
	}

	/**
	Creates an app section whose title and optional back link identify the same app.
	*/
	init(
		app: App,
		title: String,
		linksBack: Bool = true,
		@ContentBuilder content: () -> Content, @ContentBuilder accessory: () -> Accessory
	) {
		self.title = .app(app, title)
		self.photo = nil
		self.app = linksBack ? app : nil
		self.content = content()
		self.accessory = accessory()
	}

	var body: some HTML<HTMLTag.section> {
		section {
			if app != nil || title != nil {
				div {
					if let app {
						div {
							BackLink(app: app)
							accessory
						}
						.style(ProsePageStyles.backRow)
					}

					switch title {
					case .plain(let title):
						PageHeader(title: title.text, intro: title.intro)
					case .app(let app, let title):
						AppHeader(app: app, title: title)
					case nil:
						EmptyHTML()
					}
				}
				.style(ProsePageStyles.header)
			}

			Prose {
				// In the prose, so the text flows around it. It is in view when the page opens, so it is not lazy.
				if let photo {
					img(
						.src(photo),
						.alt(""),
						.width(112),
						.height(112)
					)
						.style(ProsePageStyles.photo)
				}

				content
			}
		}
		.style(ProsePageStyles.root)
	}
}

extension ProsePage where Accessory == EmptyHTML {
	/**
	Creates an app section without accessory content.
	*/
	init(
		app: App,
		title: String,
		linksBack: Bool = true,
		@ContentBuilder content: () -> Content
	) {
		self.init(
			app: app,
			title: title,
			linksBack: linksBack,
			content: content
		) {
			EmptyHTML()
		}
	}

	init(
		title: ProsePageTitle? = nil,
		photo: ImageSource? = nil,
		backTo app: App? = nil,
		@ContentBuilder content: () -> Content
	) {
		self.init(
			title: title,
			photo: photo,
			backTo: app,
			content: content
		) {
			EmptyHTML()
		}
	}
}

/**
The title of a ``ProsePage``. A string literal is a plain title.
*/
struct ProsePageTitle: ExpressibleByStringInterpolation {
	let text: String
	let intro: String?

	/**
	A title, like “Older Versions”, with an optional introduction below it. App headings use ProsePage's app initializer instead.
	*/
	static func plain(_ text: String, intro: String? = nil) -> Self {
		Self(text: text, intro: intro)
	}

	init(stringLiteral value: String) {
		self = .plain(value)
	}

	private init(text: String, intro: String?) {
		self.text = text
		self.intro = intro
	}
}

/**
The styles of ``ProsePage``, outside the generic type, so the class names are the same for every content type.
*/
private enum ProsePageStyles: String, StyleSet {
	case root
	case header

	/**
	The back link, with the accessory at the other end.
	*/
	case backRow

	case photo

	var style: Style {
		switch self {
		case .root:
			// As wide as the prose, which has the space of the page at its sides, so the header lines up with the text, and the title is where the titles of the other pages are (``Style/pagePadding()``).
			Style()
				.centeredColumn(.prose)
				.pagePadding()
		case .header:
			// Lines up with the text of the prose. The space below is the same as below the `#` title of Markdown pages.
			Style()
				.margin(.bottom, .rootEm(2.5))
				.padding(.horizontal, .pageGutter)
		case .backRow:
			// One line high, so an accessory, like the larger RSS feed button, does not move the back link down, and the back link is at the same place on all the pages of an app.
			Style()
				.hstack(alignment: .center, justification: .spaceBetween)
				.frame(height: .lineHeight(1))
				.margin(.bottom, .rootEm(1.5))
		case .photo:
			// It is in the prose, so it starts without the margins and the shadow of the images of prose.
			Style()
				.plainImage()
				.float(.trailing)
				// Next to the first paragraph, and not taller than it, so the second paragraph starts below it, and its first line is not short.
				.frame(width: .pixels(112))
				.margin(.top, .pixels(4))
				.margin(.leading, .pixels(30))
				.cornerRadius(.circle)
				// Smaller on phones, where the column is narrow, so the text next to it still has room.
				.below(.smallTablet) {
					$0
						.frame(width: .rootEm(4.5))
						.margin(.leading, .rootEm(1))
				}
		}
	}
}
