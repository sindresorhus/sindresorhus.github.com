import SiteKit

extension ProseStyles {
	/**
	Tables. They are in a ``tableContainer``, which has the space around them, with the other blocks in ``typography``.
	*/
	static let tables = Style()
		.nested(":where(table)") {
			$0
				.frame(width: .percent(100))
				.declaration(.borderCollapse, "collapse")
				.font(size: .em(0.8333), lineHeight: 1.5)
		}
		.nested(":where(thead)") {
			$0
				.border(.bottom, tableBorder)
				.background(.card)
		}
		.nested(":where(tbody tr:not(:last-child))") {
			$0.border(.bottom, tableBorder)
		}
		.nested(":where(th, td)") {
			$0
				.padding(vertical: .em(0.75), horizontal: .em(1))
				.textAlign(.leading)
		}
		// The look of a heading is with the headings in ``typography``.
		.nested(":where(th)") {
			$0.verticalAlign(.bottom)
		}
		.nested(":where(td)") {
			$0.verticalAlign(.baseline)
		}
		// Keyboard shortcuts in the first column stay on one line.
		.nested(":where(td:first-child:has(> kbd))") {
			$0.textWrap(.nowrap)
		}
		// The column of the shortcuts has the same width in each table of shortcuts, so the descriptions line up from one table to the next, like the groups of shortcuts of an app. A longer shortcut still makes its column wider. A table is a table of shortcuts when a first cell has a shortcut, so other tables should not start a row with one.
		.nested(":where(table:has(td:first-child > kbd) td:first-child)") {
			$0.frame(width: .percent(40))
		}

	/**
	The lines of tables: the separator color in light mode, and softer in dark mode, as a table has many lines, and the separator would look bright there.
	*/
	private static let tableBorder = Color.lightDark(.gray(200), .white.opacity(0.1))

	/**
	A table that is wider than the content scrolls horizontally instead of making the page scroll. A thin border around it, like a box.
	*/
	static let tableContainerStyle = Style()
		.overflow(horizontal: .auto)
		.widerThanProse()
		.border(tableBorder)
		.cornerRadius(.rootEm(1))
}
