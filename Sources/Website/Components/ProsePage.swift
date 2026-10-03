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
	private let app: App?
	private let isSpacious: Bool
	private let content: Content
	private let accessory: Accessory

	/**
	- Parameter backTo: The app to link back to, above the title.
	- Parameter isSpacious: Adds vertical space on larger screens, like Markdown pages.
	- Parameter accessory: Shown next to the back link, like an RSS feed link.
	*/
	init(title: String? = nil, backTo app: App? = nil, isSpacious: Bool = false, @HTMLBuilder content: () -> Content, @HTMLBuilder accessory: () -> Accessory) {
		self.title = title
		self.app = app
		self.isSpacious = isSpacious
		self.content = content()
		self.accessory = accessory()
	}

	var body: some HTML<HTMLTag.section> {
		section {
			Prose {
				if let app {
					div {
						BackLink(app: app)
						accessory
					}
					.style(ProsePageStyles.backRow)
				}

				if let title {
					h1 {
						title
					}
				}

				content
			}
		}
		.style(ProsePageStyles.root)
		.style(ProsePageStyles.spacious, when: isSpacious)
	}
}

extension ProsePage where Accessory == EmptyHTML {
	init(title: String? = nil, backTo app: App? = nil, isSpacious: Bool = false, @HTMLBuilder content: () -> Content) {
		self.init(title: title, backTo: app, isSpacious: isSpacious, content: content) {
			EmptyHTML()
		}
	}
}

extension ProsePage where Content == HTMLRaw, Accessory == EmptyHTML {
	init(isSpacious: Bool = false, html: String) {
		self.init(isSpacious: isSpacious) {
			HTMLRaw(html)
		}
	}
}

/**
The styles of ``ProsePage``, outside the generic type, so the class names are the same for every content type.
*/
enum ProsePageStyles: StyleSet {
	case root
	case spacious

	/**
	The back link, with the accessory at the other end.
	*/
	case backRow

	var style: Style {
		switch self {
		case .root:
			Style()
				.frame(maxWidth: .rem(48))
				.margin(top: 0, horizontal: .auto, bottom: .rem(5))
				.breakpoint(.sm) {
					$0.padding(.horizontal, .rem(1.5))
				}
				.breakpoint(.md) {
					$0
						.frame(minHeight: .svh(100))
						// The old site had an empty title above these pages, and its margin added this space.
						.children(ProseStyles.root.selector) {
							$0.margin(.top, .rem(4))
						}
				}
		case .backRow:
			Style()
				.hstack(alignment: .center, justification: .spaceBetween)
				.margin(.bottom, .rem(1.5))
		case .spacious:
			Style()
				.breakpoint(.md) {
					$0
						.padding(vertical: .rem(2), horizontal: .rem(1.5))
						.children(ProseStyles.root.selector) {
							$0.margin(.top, .rem(2))
						}
				}
		}
	}
}
