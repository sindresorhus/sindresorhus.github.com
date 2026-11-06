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
		case icon
		case text
		case name
		case kind
		case action

		var style: Style {
			switch self {
			case .root:
				// A card in the text, with the same width for each card of a list, wide enough for a title that is a sentence. A list item with a card has no bullet. In a list with text items too, the card starts where their text starts. A list of only cards has no indent, so the cards line up with the text around the list.
				Style()
					.cardSurface()
					.hstack(alignment: .center, spacing: .rootEm(0.875))
					.frame(width: .percent(100), maxWidth: .rootEm(36))
					.margin(vertical: .rootEm(0.5), horizontal: .zero)
					.padding(vertical: .rootEm(0.625), horizontal: .rootEm(0.75))
					.fontWeight(.regular)
					.nested("li:has(> &)") {
						$0.listStyle(.none)
					}
					.nested(":is(ul, ol):has(> li > &):not(:has(> li > :not(&, & + :is(span, p))))") {
						$0
							.padding(.leading, .zero)
							.children("li") {
								$0.padding(.leading, .zero)
							}
					}
					// The note of a card, the text after its link in a list item, which the Markdown of the page has after the card (``Shortcut``): small text below the card, inside its padding, so it reads as part of the card. It is a `span`, or a paragraph in a list with blank lines between its items.
					.nested("& + :is(span, p)") {
						$0
							.display(.block)
							.margin(top: .zero, horizontal: .zero, bottom: .rootEm(1))
							.padding(vertical: .zero, horizontal: .rootEm(0.75))
							.secondaryText()
					}
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
				// At the end of the card. Phones leave it out, so the name has the space. The whole card is the link.
				Style()
					.margin(.leading, .auto)
					.flexShrink(0)
					.font(size: .rootEm(0.875), lineHeight: 1.4)
					.color(.link)
					.below(.smallTablet) {
						$0.hidden()
					}
			}
		}
	}
}
