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

	var body: some HTML {
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

	enum Styles: StyleSet {
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
						$0
							.flexDirection(.row)
							.flexWrap()
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
								.margin(vertical: 0, horizontal: .rootEm(0.5))
								.opacity(0.5)
						}
					}
			}
		}
	}
}
