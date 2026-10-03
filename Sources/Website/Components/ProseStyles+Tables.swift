import SiteKit

extension ProseStyles {
	/**
	Tables. A table that is wider than the content scrolls horizontally instead of making the page scroll.
	*/
	static let tables = Style()
		.nested(":where(table)") {
			$0
				.frame(width: .percent(100))
				.margin(vertical: .em(2), horizontal: 0)
				.declaration(.tableLayout, .auto)
				.font(size: .em(0.8889), lineHeight: 1.5)
				.breakpoint(.lg) {
					$0.font(size: .em(0.9), lineHeight: 1.5556)
				}
		}
		.nested(":where(thead)") {
			$0
				.border(.bottom)
				.borderColor(.gray(300), dark: .gray(600))
		}
		.nested(":where(thead th)") {
			$0
				.padding(top: 0, horizontal: .em(0.75), bottom: .em(0.75))
				.declaration(.verticalAlign, "bottom")
				.fontWeight(.semibold)
		}
		.nested(":where(tbody tr)") {
			$0
				.border(.bottom)
				.borderColor(.separator)
				.nested("&:last-child") {
					$0.declaration(.borderBottomWidth, 0)
				}
		}
		.nested(":where(tbody td)") {
			$0
				.padding(.em(0.75))
				.declaration(.verticalAlign, "baseline")
		}
		.nested(":where(th, td)") {
			$0.declaration(.textAlign, "start")
		}
		.nested(":where(thead th:first-child, tbody td:first-child)") {
			$0.padding(.leading, 0)
		}
		.nested(":where(thead th:last-child, tbody td:last-child)") {
			$0.padding(.trailing, 0)
		}
		// The rows are put in an inner table, so the table still fills the width. Limitation: Tables with a header or footer do not scroll, as each row group would become its own table and the columns would not line up.
		.nested("table:not(:has(> thead, > tfoot))") {
			$0
				.display(.block)
				.overflow(horizontal: .auto)
				.children("tbody") {
					$0
						.declaration(.display, "table")
						.frame(width: .percent(100))
				}
		}
}
