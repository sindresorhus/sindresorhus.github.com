import SiteKit

/**
Collapsible sections, like the FAQ questions, and the links to sections on the FAQ page. The Markdown renderer creates the markup.
*/
extension ProseStyles {
	static let collapsibleSectionsStyle = Style()
		.vstack(spacing: .rem(0.75))
		// On small screens, the sections are full width, with no rounding and tight gaps that read as dividers.
		.below(.sm) {
			$0
				.gap(.rem(0.2))
				.margin(.horizontal, .rem(-1.5))
		}

	static let collapsibleSectionStyle = Style()
		.padding(0)
		.cornerRadius(.rem(0.75))
		.background(.black.opacity(0.015), dark: .white.opacity(0.025))
		.nested("&[open] > \(ProseStyles.collapsibleSummary.selector)") {
			$0.shadow(Shadow(y: .px(-1), color: .lightDark("rgb(0 0 0 / 5%)", "rgb(255 255 255 / 7%)"), isInset: true))
		}
		// Animates opening and closing, in browsers that can animate to `auto`.
		.supports("(interpolate-size: allow-keywords)") {
			$0
				.nested("&::details-content") {
					$0
						.overflow(.hidden)
						.frame(height: 0)
						.transition(.height, duration: .milliseconds(250), curve: .ease)
						// Keeps the content shown while it closes.
						.appendingDiscreteTransition("content-visibility", duration: .milliseconds(250), curve: .ease)
				}
				.nested("&[open]::details-content") {
					$0.frame(height: .auto)
				}
		}
		.below(.sm) {
			$0.cornerRadius(0)
		}
		.target {
			$0.animation(ProseAnimations.targetHighlight, duration: .seconds(2), curve: .easeOut)
		}

	static let collapsibleSummaryStyle = Style()
		.hstack(alignment: .center)
		.position(.relative)
		.padding(vertical: .rem(0.75), horizontal: .rem(1))
		.cornerRadius(.rem(0.75))
		.declaration(.fontSize, .inherit)
		.fontWeight(.semibold)
		.declaration(.listStyle, .none)
		.cursor(.pointer)
		.textSelection(.disabled)
		.background(.black.opacity(0.015), dark: .white.opacity(0.035))
		.transition(.backgroundColor, duration: .milliseconds(150))
		.hover {
			$0.background(.black.opacity(0.04), dark: .white.opacity(0.06))
		}
		.nested("&::-webkit-details-marker") {
			$0.hidden()
		}
		.nested("a") {
			$0
				.declaration(.fontSize, .inherit)
				.declaration(.fontWeight, .inherit)
		}
		.below(.sm) {
			$0.cornerRadius(0)
		}

	static let collapsibleTitleStyle = Style()
		.flex(1)
		.frame(minWidth: 0)

	static let collapsibleChevronStyle = Style()
		.display(.inlineFlex)
		.alignItems(.center)
		.flexShrink(0)
		.margin(.leading, .rem(0.5))
		.after {
			$0
				.content("")
				.frame(width: .rem(0.5), height: .rem(0.5))
				.border(.trailing, .gray(400), width: .px(2))
				.border(.bottom, .gray(400), width: .px(2))
				.rotationEffect(.degrees(-45))
				.transition(.transform, duration: .milliseconds(200))
				.dark {
					$0.borderColor("#6b7280")
				}
		}
		.nested("[open] > * > &::after") {
			$0.rotationEffect(.degrees(45))
		}

	static let collapsibleContentStyle = Style()
		.padding(vertical: .rem(0.75), horizontal: .rem(1))
		.children(":first-child") {
			$0.margin(.top, 0)
		}
		.children(":last-child") {
			$0.margin(.bottom, 0)
		}
		.nested("p + p") {
			$0.margin(.top, .rem(0.5))
		}
		.nested("ul, ol") {
			$0
				.margin(vertical: .rem(0.25), horizontal: 0)
				.padding(.leading, .rem(1.25))
		}
		.nested("li + li") {
			$0.margin(.top, .rem(0.125))
		}
		.nested("li p") {
			$0.margin(0)
		}

	static let collapsibleMoreLinkStyle = Style()
		.display(.block)
		.padding(vertical: .rem(0.75), horizontal: .rem(1))
		.cornerRadius(.rem(0.75))
		.declaration(.fontSize, .inherit)
		.color(.black.opacity(0.75), dark: .white.opacity(0.9))
		.underline(color: .primary(500), thickness: .px(2), offset: .px(4))
		.transition(.color, .underlineColor, duration: .milliseconds(150))
		.after {
			$0.content(" →")
		}
		.hover {
			$0
				.color(.black, dark: .white)
				.underlineColor(.primary(700))
				.dark {
					$0.underlineColor(.primary(300))
				}
		}
		.dark {
			$0.underlineColor(.primary(400))
		}
		.below(.sm) {
			$0.cornerRadius(0)
		}

	static let anchoredHeadingStyle = Style()
		.position(.relative)
		.target {
			$0.animation(ProseAnimations.targetHighlight, duration: .seconds(2), curve: .easeOut)
		}

	/**
	The link to a section, shown while the pointer is over the section. `site.js` copies its URL on click and sets `data-state`.
	*/
	static let headingAnchorStyle = Style()
		.position(.absolute)
		.top(0)
		.bottom(0)
		.leading(.px(-28))
		.hstack(alignment: .center, justification: .center)
		.frame(width: .px(24))
		.opacity(0)
		.color(.gray(400))
		.allowsHitTesting(false)
		.transform("translateZ(0)")
		.transition(.opacity, .color, duration: .milliseconds(150), curve: .ease)
		.before {
			$0
				.content("")
				.position(.absolute)
				.inset(.px(-8))
		}
		.media(.hover) {
			$0.nested(":is(\(ProseStyles.anchoredHeading.selector), \(ProseStyles.collapsibleSummary.selector)):hover > &") {
				$0
					.opacity(0.6)
					.allowsHitTesting(true)
			}
		}
		.hover {
			$0
				.important {
					$0.opacity(1)
				}
				.color(.primary(500))
		}
		// Keyboard users see the link they move to.
		.focusVisible {
			$0
				.important {
					$0.opacity(1)
				}
				.allowsHitTesting(true)
				.color(.primary(500))
		}
		.nested("&[data-state=\"copied\"]") {
			$0
				.important {
					$0
						.opacity(1)
						.color(.primary(500))
				}
				.allowsHitTesting(false)
				.nested(ProseStyles.headingAnchorLinkIcon.selector) {
					$0.hidden()
				}
				.nested(ProseStyles.headingAnchorCheckIcon.selector) {
					$0.display(.block)
				}
		}
		.nested("&[data-state=\"hidden\"]") {
			$0
				.important {
					$0.opacity(0)
				}
				.allowsHitTesting(false)
		}

	static let headingAnchorCheckIconStyle = Style()
		.hidden()
}

/**
A short highlight of the section or heading that a link points to, like the FAQ question that a suggestion on the feedback page opens.
*/
enum ProseAnimations: KeyframeSet {
	case targetHighlight

	var keyframes: [Keyframe] {
		[.from(Style().background(.secondary(200), dark: .secondary(800)))]
	}
}
