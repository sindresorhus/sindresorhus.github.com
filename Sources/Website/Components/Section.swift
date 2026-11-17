import Elementary
import SiteKit

/**
A group of content under a heading, like the apps of a macOS version.

```swift
Section("macOS 14", id: ElementID("14")) {
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
	let id: ElementID?

	/**
	The page of the section, which the title links to, like the page of a topic of the guides, or `nil` for a title that is only text.
	*/
	let link: RoutePath?

	let content: Content

	init(_ title: String, id: ElementID? = nil, link: RoutePath? = nil, @ContentBuilder content: () -> Content) {
		self.title = title
		self.id = id
		self.link = link
		self.content = content()
	}

	var body: some HTML<HTMLTag.section> {
		section {
			// With the spans of the headings of prose, so a title with a hyphen, like “Command-Line”, does not break at the hyphen.
			// With an ID, it has the link that copies the URL of the section, like the headings of prose (``SiteKit/MarkdownDocument/Options/addsHeadingAnchors``), so a reply to a question can link to a section, like “macOS 12” of the older versions page. The link is inside the heading, so the heading is named by its text, not also by the name of the link.
			h2 {
				// A link to the page of the section has the look of the title of a guide in a list (``ArticleRow``): the color of the title, with a thick underline under the pointer. It is only around the text, next to the link that copies the URL, as links cannot be nested.
				if let link {
					a(.href(link)) {
						MarkdownTheme.site.headingTextHTML(title)
					}
					.style(ArticleRow.Styles.link)
				} else {
					MarkdownTheme.site.headingTextHTML(title)
				}

				if let id {
					a(.href(.fragment(id)), .hook(ProseStyles.Hooks.copyLink), .ariaLabel("Copy link to section: \(title)")) {}
						.style(ProseStyles.headingAnchor)
				}
			}
			.attributes(contentsOf: id.map { [.id($0), .custom(name: "aria-label", value: title)] } ?? [])
			.style(SectionStyles.title)
			.style(ProseStyles.anchoredHeading, when: id != nil)

			content
		}
	}
}

/**
The styles of ``Section``, outside the generic type, so the class names are the same for every content type. The title looks like a heading in prose, so a section in prose looks the same as one outside it.
*/
enum SectionStyles: String, StyleSet {
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
				.textStyle(.sectionTitle)
				.color(.primaryText)
				.breaksLongWords()
		case .label:
			Style()
				.margin(.bottom, .rootEm(1.5))
				.secondaryText(.lead)
				.fontWeight(.semibold)
				.textAlign(.center)
		}
	}
}
