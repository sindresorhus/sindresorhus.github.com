import Elementary
import SiteKit

/**
A row of short facts, like “63 apps · 11 years of craft”, with dots between them on larger screens, and one fact on each line on phones.
*/
struct StatList: HTML {
	let stats: [String]

	/**
	Centers the facts, like below a centered title.
	*/
	var isCentered = false

	var body: some HTML<HTMLTag.p> {
		p {
			for (index, stat) in stats.enumerated() {
				// A space between the facts, for copied text and reader modes. The flex layout does not show it.
				if index > 0 {
					" "
				}

				span {
					stat
				}
				.style(Styles.stat)
			}
		}
		.style(Styles.root)
		.style(Styles.centered, when: isCentered)
	}

	enum Styles: String, StyleSet {
		case root
		case centered
		case stat

		var style: Style {
			switch self {
			case .root:
				Style()
					.vstack(spacing: .rootEm(0.25))
					.secondaryText()
					.monospacedDigit()
					.from(.tablet) {
						// No space between the facts in a row, as the margins of the dots are the space, so the dots are in the middle.
						$0
							.flexDirection(.row)
							.flexWrap()
							.gap(row: .rootEm(0.25), column: .zero)
					}
			case .centered:
				Style()
					.alignItems(.center)
					.from(.tablet) {
						$0.justifyContent(.center)
					}
			case .stat:
				// Screen readers skip the dot, as its alternative text is empty.
				Style()
					.from(.tablet) {
						$0.nested("& + &::before") {
							$0
								.content("·", alternativeText: "")
								.margin(vertical: .zero, horizontal: .rootEm(0.5))
								.opacity(0.5)
						}
					}
			}
		}
	}
}

/**
A line of short facts in text, like “May 2023 · 4 min read”, with a dot and an en space at each side between them. Each fact is an element, like a `span` or a `time`, and the line breaks only between the facts. A link that is not the last fact is in a `span`, so the dot after it is not part of the link. The dot is at the end of the fact before it, so no line starts with a dot.

Limitation: the dots and the spaces are drawn by the styles, so copied text has no space between the facts.

```swift
FactLine {
	span {
		"2021"
	}

	span {
		"Translated from German"
	}
}
```
*/
struct FactLine<Content: HTML>: HTML {
	/**
	Plain-text facts before any richer content, each wrapped as one item.
	*/
	var facts = [String]()
	@HTMLBuilder let content: Content

	var body: some HTML<HTMLTag.span> {
		span {
			for fact in facts {
				span {
					fact
				}
			}

			content
		}
		.style(FactLineStyles.root)
	}
}

/**
The styles of ``FactLine``, outside of it, as a generic type cannot have a static style set.
*/
enum FactLineStyles: String, StyleSet {
	case root

	var style: Style {
		switch self {
		case .root:
			// Each fact is a box, so a line only breaks between the facts, or inside a fact that is longer than the line. Screen readers skip the dots, as their alternative text is empty.
			Style()
				.children("*") {
					$0.display(.inlineBlock)
				}
				.children(":not(:last-child)") {
					$0.after {
						$0.content("\u{2002}·\u{2002}", alternativeText: "")
					}
				}
		}
	}
}

extension Style {
	/**
	Each fact of a ``FactLine`` on its own line, without the dots, for a line of facts that would otherwise wrap after a dot, like on a small screen.
	*/
	func stackedFacts() -> Self {
		children("*") {
			$0.display(.block)
		}
		.children(":not(:last-child)") {
			$0.after {
				$0.hidden()
			}
		}
	}
}
