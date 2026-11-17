import Elementary
import SiteKit

/**
A link to a shared shortcut as a card with its icon and its name from iCloud, like in the Shortcuts app, for a link that is alone in its paragraph or list item on an app page, or at the start of a list item, where the text after it is a note below the card (``Shortcut``). The card is a large target, and it shows what the visitor gets, also when the text of the link is vague, like “Example shortcut”.

The title is the text of the link, as the text around it can refer to it, like “the iOS shortcut”. The name from iCloud is below it, when it is different.
*/
struct ShortcutCard: HTML {
	let shortcut: Shortcut
	let title: String

	var body: some HTML<HTMLTag.a> {
		// The card shows the shortcut, so it shows no preview of it (``LinkPreview``).
		a(.href(.url(shortcut.id.url)), .hook(LinkPreview.Hooks.noLinkPreview)) {
			// The cards are far down the page, or in a closed answer, so the icon loads when it is near the screen.
			JPEGXLPicture(copy: shortcut.iconJPEGXL) {
				img(
					.src(shortcut.iconPath),
					.alt(""),
					.width(40),
					.height(40),
					.lazyLoading,
					.asyncDecoding
				)
				.style(Styles.icon)
			}

			span {
				span {
					title
				}
				.style(Styles.name)

				span {
					title.removingSmartPunctuation == shortcut.name ? "Shortcut" : "Shortcut: \(shortcut.name)"
				}
				.style(Styles.kind)
			}
			.style(Styles.text)

			span {
				"Add Shortcut"
			}
			.style(Styles.action)
		}
		.style(Styles.root)
	}

	enum Styles: String, StyleSet {
		case root
		case inMixedList
		case icon
		case text
		case name
		case kind
		case action

		var style: Style {
			switch self {
			case .root:
				// A card in the text, with the same width for each card of a list, wide enough for a title that is a sentence. A list of only cards has no bullets and no indent, so the cards line up with the text around the list. In a list with text items too, a card is one item of the list, with its bullet or number, and starts where the text of the other items starts.
				// A compact card has the corners of a box, so they are parallel to the corners of the icon, which is close to the edge.
				Style()
					.cardSurface()
					.cornerRadius(.boxRadius)
					.hstack(alignment: .center, spacing: .rootEm(0.875))
					.frame(width: .percent(100), maxWidth: .rootEm(36))
					.margin(vertical: .rootEm(0.5), horizontal: .zero)
					.padding(vertical: .rootEm(0.625), horizontal: .rootEm(0.75))
					.fontWeight(.regular)
					// In an FAQ answer, which is a gray box, the card has the page background in light mode, so it is not a gray card on a gray box. In dark mode, the answer is a lighter fill, and the card already stands out. The answer has no specificity, so the fill under the pointer stays.
					.inside(":where(\(ProseStyles.collapsibleSection.selector))") {
						$0.background(.pageBackground, dark: .card)
					}
					.nested(":is(ul, ol):has(> li > &):not(:has(> li > \(Self.inMixedList.selector)))") {
						$0
							.padding(.leading, .zero)
							.children("li") {
								$0
									.padding(.leading, .zero)
									.listStyle(.none)
							}
					}
					// The note of a card, the text after its link in a list item, which the Markdown of the page has after the card (``Shortcut``): small text below the card, inside its padding, so it reads as part of the card. It is a `span`, or a paragraph in a list with blank lines between its items.
					.nested("& + :is(span, p)") {
						$0
							.display(.block)
							.margin(top: .rootEm(0.5), horizontal: .zero, bottom: .rootEm(1))
							.padding(vertical: .zero, horizontal: .rootEm(0.75))
							.secondaryText()
					}
			case .inMixedList:
				// In a list with text items too, the card is in the line of the marker of its item, which is then in the middle of the card. The space between the items is the space of the list, as the margins of an inline card do not collapse with the margins of its item.
				Style()
					.display(.inlineFlex)
					.verticalAlign(.middle)
					.margin(.vertical, .zero)
			case .icon:
				// The corners of an icon of the Shortcuts app. The icon from iCloud is a square.
				Style()
					.plainImage()
					.frame(size: .rootEm(2.5))
					.flexShrink(0)
					.cornerRadius(.rootEm(0.5625))
			case .text:
				Style()
					.vstack(alignment: .start)
					.frame(minWidth: .zero)
			case .name:
				// The size of prose text, also where the text around the card is small, like the description of an action.
				Style()
					.font(size: .rootEm(1.125), lineHeight: 1.4)
					.fontWeight(.semibold)
					.color(.primaryText)
			case .kind:
				// The secondary color, so the title leads.
				Style()
					.secondaryText()
			case .action:
				// At the end of the card. Phones leave it out, so the name has the space. The whole card is the link. In the accent for text, like the link below the reviews, so the card has the color of the app.
				Style()
					.margin(.leading, .auto)
					.flexShrink(0)
					.font(size: .rootEm(0.875), lineHeight: 1.4)
					.color(.accentText)
					.below(.smallTablet) {
						$0.hidden()
					}
			}
		}
	}
}
