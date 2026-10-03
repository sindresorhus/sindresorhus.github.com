import SiteKit

extension Stylesheet {
	/**
	Styles for the classes in the raw HTML of the content files, like the sponsor logos on the supporters page.

	The content owns this markup, so these are selector rules. They are in a layer after the prose layer, so they win over the typography.
	*/
	static let content = Stylesheet {
		// A photo at the top of a page, next to the title, on larger screens.
		Rule(".page-photo", Style()
			.frame(width: .px(130))
			.margin(.top, .px(30))
			.margin(.leading, .px(30))
			.cornerRadius(.circle)
			.hidden(below: .sm)
		)

		Rule(".title-emoji", Style().padding(.leading, .rem(0.5)))

		Rule(".reward-price", Style()
			.position(.relative)
			.bottom(.px(2))
			.leading(.px(2))
			.font(size: .px(14))
			.letterSpacing(0)
		)

		Rule(".sponsor", Style()
			.display(.inlineBlock)
			.declaration(.verticalAlign, "middle")
			.padding(vertical: .px(20), horizontal: 0)
			.margin(.trailing, .px(40))
			.nested("&:last-of-type") {
				$0.margin(.trailing, 0)
			}
			.nested("img") {
				$0
					.padding(0)
					.margin(0)
					.shadow([])
			}
			// The logos are made for a light background.
			.dark {
				$0
					.color(.black)
					.background(.white)
					.cornerRadius(.px(5))
					.margin(vertical: .px(20), horizontal: 0)
					.padding(.px(20))
					.important {
						$0.declaration(.position, "unset")
					}
			}
		)

		Rule(".silver-sponsor .sponsor", Style().display(.block))

		// The embedded tweet is too wide on phones.
		Rule("twitterwidget", Style()
			.important {
				$0.declaration(.width, "unset")
			}
		)

		// Keyboard shortcuts in the first column of a table stay on one line.
		Rule(":where(td:first-child:has(> kbd))", Style().noWrap())
	}
}
