import Elementary
import SiteKit

/**
A page that is a column of prose, like `/about`, optionally with a title and a link back to the app it is about.

```swift
ProsePage(title: "Privacy Policy for Dato", backTo: app) {
	p {
		"No data is collected."
	}
}
```
*/
struct ProsePage<Content: HTML, Accessory: HTML>: HTML {
	private let title: String?
	private let photo: LinkDestination?
	private let app: App?
	private let content: Content
	private let accessory: Accessory

	/**
	- Parameter photo: A round photo next to the title on larger screens, like a portrait.
	- Parameter backTo: The app to link back to, above the title.
	- Parameter accessory: Shown next to the back link, like an RSS feed link.
	*/
	init(title: String? = nil, photo: LinkDestination? = nil, backTo app: App? = nil, @ContentBuilder content: () -> Content, @ContentBuilder accessory: () -> Accessory) {
		self.title = title
		self.photo = photo
		self.app = app
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

					if let title {
						PageHeader(title: title)
					}
				}
				.style(ProsePageStyles.header)
			}

			Prose {
				// In the prose, so the text flows around it.
				if let photo {
					img(.src(photo.description), .alt(""), .width(112), .height(112))
						.style(ProsePageStyles.photo)
				}

				content
			}
		}
		.style(ProsePageStyles.root)
	}
}

extension ProsePage where Accessory == EmptyHTML {
	init(title: String? = nil, photo: LinkDestination? = nil, backTo app: App? = nil, @ContentBuilder content: () -> Content) {
		self.init(title: title, photo: photo, backTo: app, content: content) {
			EmptyHTML()
		}
	}
}

extension ProsePage where Content == MarkdownContent, Accessory == EmptyHTML {
	init(photo: LinkDestination? = nil, markdown: MarkdownContent) {
		self.init(photo: photo) {
			markdown
		}
	}
}

/**
The styles of ``ProsePage``, outside the generic type, so the class names are the same for every content type.
*/
enum ProsePageStyles: StyleSet {
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
				.frame(maxWidth: Style.ColumnWidth.prose.maximum)
				.margin(.horizontal, .auto)
				.pagePadding()
				.from(.tablet) {
					$0.frame(minHeight: .smallViewportHeight(100))
				}
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
			Style()
				.float(.trailing)
				// Next to the first paragraph, and not taller than it, so the second paragraph starts below it, and its first line is not short.
				.frame(width: .pixels(112))
				.margin(.top, .pixels(4))
				.margin(.leading, .pixels(30))
				.cornerRadius(.circle)
				.hidden(below: .smallTablet)
		}
	}
}
