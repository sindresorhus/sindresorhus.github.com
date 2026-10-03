import Elementary
import SiteKit

/**
A link with only an icon, like the RSS link in the header. The label is for screen readers.
*/
struct IconLink: HTML {
	let url: String
	let label: String
	let icon: Icon

	/**
	Like `me` for a profile of the author.
	*/
	var relationship: HTMLAttribute<HTMLTag.a>?

	/**
	The tooltip.
	*/
	// TODO: Use an interest invoker (`interestfor`) with a styled popover instead of `title` when Safari and Firefox support it.
	var title: String?

	var iconSize = Length.rem(1.25)

	var body: some HTML {
		a(.href(url), .ariaLabel(label)) {
			icon.size(iconSize)
		}
		.attributes(contentsOf: [relationship, title.map { .title($0) }].compactMap(\.self))
		.style(Styles.root)
	}

	/**
	The look of an icon link, for other controls that look the same, like the menu button. A control reuses the style value instead of the class, as the order of rules from different style sets is not defined.
	*/
	static let look = Style()
		.display(.inlineFlex)
		.alignItems(.center)
		.padding(.rem(0.625))
		// A larger target for fingers, without moving the layout.
		.media(.coarsePointer) {
			$0
				.padding(.rem(0.75))
				.margin(.rem(-0.125))
		}
		.cornerRadius(.rem(0.5))
		.color(.secondaryText)
		.hover {
			$0.background(.gray(100))
		}
		.focusVisible {
			$0
				.focusRing(.gray(200))
		}
		.dark {
			$0
				.hover {
					$0.background(.gray(700))
				}
				.focusVisible {
					$0.focusRing(.gray(700))
				}
		}

	enum Styles: StyleSet {
		case root

		var style: Style {
			IconLink.look
		}
	}
}
