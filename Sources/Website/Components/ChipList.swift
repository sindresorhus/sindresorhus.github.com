import Elementary
import Markdown
import SiteKit

/**
The arguments of `@Chips(label: "Feature groups") { - [Finder](#finder) }`.
*/
@Frontmatter
struct ChipsArguments {
	/**
	What the links are, for screen readers, like “Feature groups”.
	*/
	@PlainText var label: String
}

extension ChipsArguments {
	/**
	A list of links as chips, like `@Chips(label: "Feature groups") { - [Finder](#finder) }`, with the look of ``ChipNavigation``, so links to the parts of a long page read as navigation, not as a sentence, and each chip keeps its words together. Each item must be one link.
	*/
	@Sendable
	static func render(arguments: Self, content: HTMLFragment) -> HTMLFragment {
		nav {
			content.addingListRole()
		}
		.accessibilityLabel(arguments.label)
		.style(ChipListStyles.root)
		.renderFragment()
	}

	/**
	The IDs of the headings that the chips of the document link to, like `finder` of `[Finder](#finder)`, so each of these headings and the blocks below it are a group whose title stays at the top of the screen while the group scrolls (``SiteKit/MarkdownDocument/Options/groupedHeadingIDs``), like the groups of the features of Supercharge.
	*/
	@Sendable
	static func linkedHeadingIDs(in document: Markdown.Document) -> Set<ElementID> {
		let destinations = document.blockDirectives
			.filter { $0.siteName == .chips }
			.flatMap { $0.descendants(of: Markdown.Link.self) }
			.compactMap(\.destination)
			.filter { $0.hasPrefix("#") }

		return Set(destinations.compactMap { try? ElementID(validating: String($0.dropFirst())) })
	}

	/**
	The content without changes, or an error when an item is not one link, like a link with text after it, as a chip shows only the link.

	- Parameter content: One bulleted list, which the renderer checked (`.unorderedList`).
	*/
	@Sendable
	static func checkingLinks(in content: [any BlockMarkup]) throws(ContentError) -> [any BlockMarkup] {
		for case let list as UnorderedList in content {
			for item in list.listItems {
				guard
					item.childCount == 1,
					let paragraph = item.child(at: 0) as? Paragraph,
					paragraph.childCount == 1,
					paragraph.child(at: 0) is Markdown.Link
				else {
					throw ContentError(reason: "Each item of `@Chips` must be one link, like `- [Finder](#finder)`.")
				}
			}
		}

		return content
	}
}

/**
The styles of `@Chips`.
*/
private enum ChipListStyles: String, StyleSet {
	case root

	var style: Style {
		// The items are chips in rows that wrap, so every link is visible, like the section links of an app page.
		Style()
			.proseBlockMargin()
			.children("ul") {
				$0
					.hstack(alignment: .center, spacing: .rootEm(0.5))
					.flexWrap()
					.listStyle(.none)
					.margin(.zero)
					.padding(.zero)
					.children("li") {
						$0
							.margin(.zero)
							.padding(.zero)
							// An inline flex box, like the chips of ``ChipNavigation``, so its padding makes it as tall as them, not only its line.
							.children("a") {
								$0
									.chip()
									.display(.inlineFlex)
							}
					}
			}
	}
}
