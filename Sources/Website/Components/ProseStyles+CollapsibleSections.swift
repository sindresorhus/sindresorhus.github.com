import SiteKit

/**
Collapsible sections, like the FAQ questions, and the links to sections on the FAQ page. The Markdown renderer creates the markup.
*/
extension ProseStyles {
	static let collapsibleSectionsStyle = Style()
		.vstack(spacing: .rootEm(0.625))
		.widerThanProse()
		// On small screens, the sections are full width, with no rounding and tight gaps that read as dividers.
		.below(.smallTablet) {
			$0
				.gap(.rootEm(0.2))
				.margin(.horizontal, -.pageGutter)
		}

	static let collapsibleSectionStyle = Style()
		.cardSurface(isInteractive: false)
		.cornerRadius(.boxRadius)
		// A little more see-through than a card in dark mode, as a long list of questions is a lot of fill.
		.dark {
			$0.background(.white.opacity(0.05))
		}
		// Animates opening and closing, in browsers that can animate to `auto`.
		.supports(.interpolateSize) {
			$0
				.detailsContent {
					$0
						.overflow(.hidden)
						.frame(height: 0)
						// The discrete transition of `content-visibility` keeps the content shown while it closes.
						.transition(.height, .contentVisibility, animation: .default(duration: .milliseconds(250)))
				}
				.open {
					$0.detailsContent {
						$0.frame(height: .auto)
					}
				}
		}
		.below(.smallTablet) {
			$0.cornerRadius(0)
		}
		.target {
			$0.targetHighlight()
		}

	/**
	The padding and corners of a summary, which the link to more questions shares, so it looks like a closed question.
	*/
	private static let collapsibleRow = Style()
		// The horizontal padding is the padding of the page, so on small screens, where the sections are full width, the text lines up with the text around it.
		.padding(vertical: .rootEm(1), horizontal: .pageGutter)
		.cornerRadius(.boxRadius)
		// Full width on small screens, like the questions.
		.below(.smallTablet) {
			$0.cornerRadius(0)
		}

	/**
	The summary of a section, with the question and the chevron. As a flexbox, it has no disclosure marker of the browser.
	*/
	static let collapsibleSummaryStyle = collapsibleRow
		.hstack(alignment: .center)
		.position(.relative)
		.fontWeight(.semibold)
		.color(.primaryText)
		.cursor(.pointer)
		.textSelection(.disabled)
		.transition(.backgroundColor, animation: .stateChange)
		.hover {
			$0.background(.cardHover)
		}
		.nested("a") {
			$0.declaration(.fontWeight, .inherit)
		}

	/**
	The question in the summary, which is a heading, so it is in the outline of the page. It looks like the rest of the summary.
	*/
	static let collapsibleTitleStyle = Style()
		.flex(1)
		.frame(minWidth: 0)
		.margin(0)
		.inheritsFont()
		.declaration(.letterSpacing, .inherit)
		.color(.inherit)
		.declaration(.textWrap, .inherit)
		// The font has more space above the capitals than below the baseline, so the text looks a little low next to the chevron.
		.offset(y: .pixels(-1))

	static let collapsibleChevronStyle = Style()
		.display(.inlineFlex)
		.alignItems(.center)
		.flexShrink(0)
		.margin(.leading, .rootEm(0.5))
		.after {
			$0
				.content("")
				.frame(width: .rootEm(0.5), height: .rootEm(0.5))
				.border([.trailing, .bottom], .lightDark(.gray(400), .gray(500)), width: .pixels(2))
				.rotationEffect(.degrees(-45))
				.transition(.rotationEffect, animation: .default(duration: .milliseconds(200)))
		}
		.nested("details:open > * > &::after") {
			$0.rotationEffect(.degrees(45))
		}

	static let collapsibleContentStyle = Style()
		.padding(top: .rootEm(0.625), horizontal: .pageGutter, bottom: .rootEm(1.25))
		.trimmingChildMargins()

	/**
	The link to more questions below the questions, a row like a closed question, so the list ends with it. The arrow is where the chevrons of the questions are.
	*/
	static let collapsibleMoreLinkStyle = collapsibleRow
		.hstack(alignment: .center, justification: .spaceBetween)
		.margin(.top, .rootEm(0.625))
		.shadow(Shadow(y: 0, spread: .pixels(1), color: .separator, isInset: true))
		.fontWeight(.medium)
		.color(.secondaryText)
		.underline(false)
		.transition(.color, .backgroundColor, animation: .stateChange)
		.after {
			$0.content("→")
		}
		.hover {
			$0
				.background(.card)
				.color(.primaryText)
		}

	static let anchoredHeadingStyle = Style()
		.position(.relative)
		.target {
			$0.targetHighlight()
		}

	/**
	The link is next to the first line of the summary, not in the middle of an open section.
	*/
	static let anchoredSectionStyle = Style()
		.position(.relative)
		.children(ProseStyles.headingAnchor.selector) {
			$0
				.bottom(.auto)
				.frame(height: .lineHeight(1) + .rootEm(2))
				// The sections are full width on small screens, so the link is in the padding of the summary, not outside the screen.
				.below(.smallTablet) {
					$0.leading(0)
				}
		}

	/**
	The link to a section, shown while the pointer is over the section. `site.js` copies its URL on click and sets `data-state`.
	*/
	static let headingAnchorStyle = Style()
		.position(.absolute)
		.top(0)
		.bottom(0)
		.leading(.pixels(-28))
		.hstack(alignment: .center, justification: .center)
		.frame(width: .pixels(24))
		// On small screens, the link is in the padding of the page, not cut off at its edge.
		.below(.smallTablet) {
			$0.leading(.pixels(-24))
		}
		.opacity(0)
		.color(.gray(400))
		.allowsHitTesting(false)
		.transition(.opacity, .color, animation: .stateChange)
		.before {
			$0
				.content("")
				.position(.absolute)
				.inset(.pixels(-8))
		}
		.media(.hover) {
			$0
				// The hovered heading is in `:where()`, so it adds no specificity, and the states below win over it.
				.nested(":where(\(ProseStyles.anchoredHeading.selector):hover, \(ProseStyles.anchoredSection.selector):hover) > &") {
					$0.opacity(0.6)
				}
				// The link takes the pointer in every state while the heading is hovered, so the pointer stays over the heading, and `site.js` sees it leave after a copy. This rule stays more specific than the states below.
				.nested(":is(\(ProseStyles.anchoredHeading.selector), \(ProseStyles.anchoredSection.selector)):hover > &") {
					$0.allowsHitTesting(true)
				}
		}
		.hover {
			$0
				.opacity(1)
				.color(.primary(500))
		}
		// Keyboard users see the link they move to.
		.focusVisible {
			$0
				.opacity(1)
				.allowsHitTesting(true)
				.color(.primary(500))
		}
		.when(.state, is: "copied") {
			$0
				.opacity(1)
				.color(.primary(500))
				.allowsHitTesting(false)
				.nested(ProseStyles.headingAnchorLinkIcon.selector) {
					$0.hidden()
				}
				.nested(ProseStyles.headingAnchorCheckIcon.selector) {
					$0.display(.block)
				}
		}
		.when(.state, is: "hidden") {
			$0
				.opacity(0)
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

extension Style {
	/**
	Briefly highlights the background, like on the section or heading that a link points to.
	*/
	func targetHighlight() -> Self {
		animation(ProseAnimations.targetHighlight, .easeOut(duration: .seconds(2)))
	}
}
