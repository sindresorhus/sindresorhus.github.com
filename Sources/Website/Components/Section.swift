import Elementary
import SiteKit

/**
A group of content under a heading, like the apps of a macOS version.

```swift
Section("macOS 14", id: "14") {
	ul {
		…
	}
}
```
*/
struct Section<Content: HTML>: HTML {
	let title: String

	/**
	The ID of the heading, so links can point to the section.
	*/
	let id: String?

	let content: Content

	init(_ title: String, id: String? = nil, @ContentBuilder content: () -> Content) {
		self.title = title
		self.id = id
		self.content = content()
	}

	var body: some HTML<HTMLTag.section> {
		section {
			h2 {
				title
			}
			.attributes(.id(id ?? ""), when: id != nil)
			.style(SectionStyles.title)

			content
		}
	}
}

/**
The styles of ``Section``, outside the generic type, so the class names are the same for every content type. The title looks like a heading in prose, so a section in prose looks the same as one outside it.
*/
enum SectionStyles: StyleSet {
	case title

	/**
	A quiet, centered title above extra content at the end of a page, like “You Might Also Like”, so it does not compete with the headings of the page.
	*/
	case label

	var style: Style {
		switch self {
		case .title:
			Style()
				.margin(.bottom, .rootEm(1.5))
				.font(size: .rootEm(1.875), lineHeight: 1.15)
				.bold()
				.letterSpacing(.em(-0.025))
				.color(.primaryText)
		case .label:
			Style()
				.margin(.bottom, .rootEm(1.5))
				.secondaryText(.lead)
				.fontWeight(.semibold)
				.textAlign(.center)
		}
	}
}
