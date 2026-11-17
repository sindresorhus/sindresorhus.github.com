import SiteKit

extension ProseStyles {
	/**
	Tables. They are in a ``tableContainer``, which has the space around them, with the other blocks in ``typography``.
	*/
	static let tables = Style()
		.descendants("table") {
			$0
				.frame(width: .percent(100))
				.borderCollapse(.collapse)
				.font(size: .em(0.8333), lineHeight: 1.5)
		}
		.descendants("thead") {
			$0
				.border(.bottom, tableBorder)
				.background(.card)
		}
		.descendants("tbody tr:not(:last-child)") {
			$0.border(.bottom, tableBorder)
		}
		// The lines of a cell get similar lengths, like the headings, so a short cell does not end with one word alone. A cell is a few short lines, which is what balance is for.
		.descendants("th, td") {
			$0
				.padding(vertical: .em(0.75), horizontal: .em(1))
				.textAlign(.leading)
				.textWrap(.balance)
		}
		// Long code, like a URL, breaks at any character, so it does not make its column too wide for a phone.
		.descendants("td code") {
			$0.overflowWrap(.anywhere)
		}
		// Where the table hangs into the space at the sides of the text (``Style/widerThanProse()``), the text of its first column starts where the paragraphs start, inside the border of the container.
		.from(.proseWithGutters) {
			$0
				.descendants(":is(th, td):first-child") {
					$0.padding(.leading, .boxInset - LengthPercentage(tableContainerBorderWidth))
				}
				.descendants(":is(th, td):last-child") {
					$0.padding(.trailing, .boxInset - LengthPercentage(tableContainerBorderWidth))
				}
		}
		// The look of a heading is with the headings in ``typography``.
		.descendants("th") {
			$0.verticalAlign(.bottom)
		}
		.descendants("td") {
			$0.verticalAlign(.baseline)
		}
		// The column of the shortcuts has the same width in each table of shortcuts, so the descriptions line up from one table to the next, like the groups of shortcuts of an app. A longer shortcut still makes its column wider. A table is a table of shortcuts when a first cell of a row with more than one cell has a shortcut, so other tables should not start such a row with one.
		.descendants("table:has(td:first-child:not(:last-child) > kbd) td:first-child") {
			$0.frame(width: .percent(40))
		}

	/**
	The lines of tables: gray 200 in light mode, a little darker than the separator, and softer in dark mode, as a table has many lines, and the separator would look bright there.
	*/
	private static let tableBorder = Color.lightDark(.gray(200), .white.opacity(0.1))

	/**
	The width of the border around a table, which the padding of its outer cells leaves out, so their text lines up with the paragraphs.
	*/
	private static let tableContainerBorderWidth = Length.pixels(1)

	/**
	A table that is wider than the content scrolls horizontally instead of making the page scroll. A thin border around it, like a box, which has the color of the secondary text while the container has the focus of the keyboard (it is focusable, so keyboard users can scroll a wide table). On phones, a table directly in the text goes to the edges of the screen, like a code block, without the borders at its sides and the corners.
	*/
	static let tableContainerStyle = Style()
		.overflow(horizontal: .auto)
		.widerThanProse()
		.border(tableBorder, width: tableContainerBorderWidth)
		.cornerRadius(.boxRadius)
		// Like a code block (``CodeBlock``), so the columns have more room, and the text of the first column starts where the paragraphs start. Only a table directly in the prose, as the prose is one gutter from the edges, but a list or a box is not.
		.below(.smallTablet) {
			$0.directlyInside(ProseStyles.root.selector) {
				$0
					.margin(.horizontal, .length(-.pageGutter))
					.border(.horizontal, width: .zero)
					.cornerRadius(.zero)
					.descendants(":is(th, td):first-child") {
						$0.padding(.leading, .pageGutter)
					}
					.descendants(":is(th, td):last-child") {
						$0.padding(.trailing, .pageGutter)
					}
			}
		}
		.focusVisible {
			$0.borderColor(.secondaryText)
		}
}
