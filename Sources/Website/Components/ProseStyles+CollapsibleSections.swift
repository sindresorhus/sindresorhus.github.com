import SiteKit

/**
Collapsible sections, like the FAQ questions, and the links to sections on the FAQ page. The Markdown renderer creates the markup.
*/
extension ProseStyles {
	/**
	The states that `site.js` sets on the link to a section: copied after a click, and hidden until the pointer leaves the section.
	*/
	enum States: String, ElementStateSet {
		case copied
		case hidden
	}

	static let collapsibleSectionsStyle = Style()
		.vstack(spacing: .rootEm(0.625))
		.widerThanProse()
		// On small screens, the sections are full width, with no rounding and tight gaps that read as dividers.
		.below(.smallTablet) {
			$0
				.gap(.rootEm(0.2))
				.margin(.horizontal, .length(-.pageGutter))
		}

	static let collapsibleSectionStyle = Style()
		.cardSurface(isInteractive: false)
		.cornerRadius(.boxRadius)
		// A little more see-through than a card in dark mode, as a long list of questions is a lot of fill.
		.background(.card, dark: .white.opacity(0.05))
		// Animates opening and closing, in browsers that can animate to `auto`.
		.supports(.interpolateSize) {
			$0
				.detailsContent {
					$0
						.overflow(.hidden)
						.frame(height: .zero)
						// The discrete transition of `content-visibility` keeps the content shown while it closes.
						.transition(.height, .contentVisibility, timing: .disclosure)
				}
				.open {
					$0.detailsContent {
						$0.frame(height: .auto)
					}
				}
		}
		.below(.smallTablet) {
			$0.cornerRadius(.zero)
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
			$0.cornerRadius(.zero)
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
		.hoverFill(.cardHover)
		.nested("a") {
			$0.fontWeight(.inherit)
		}

	/**
	The question in the summary, which is a heading, so it is in the outline of the page. It looks like the rest of the summary.
	*/
	static let collapsibleTitleStyle = Style()
		.flex(1)
		.frame(minWidth: .zero)
		.margin(.zero)
		.inheritsFont()
		.inherits(.letterSpacing)
		.inherits(.color)
		// Like a paragraph, so a question that wraps does not end with one word on its last line.
		.textWrap(.pretty)
		// The font has more space above the capitals than below the baseline, so the text would look a little low next to the chevron. Trimming the text to the capitals and the baseline centers it at every size and zoom, and the padding keeps the height of the line.
		.trimmedText()

	static let collapsibleChevronStyle = Style()
		.hstack(alignment: .center, isInline: true)
		.flexShrink(0)
		.margin(.leading, .rootEm(0.5))
		.after {
			$0
				.content("")
				.frame(size: .rootEm(0.5))
				.border([.trailing, .bottom], .secondaryText, width: .pixels(2))
				.rotationEffect(.degrees(-45))
				.transition(.rotationEffect, timing: .disclosure)
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
		.shadow(.edge(.separator))
		.fontWeight(.medium)
		.color(.secondaryText)
		.underline(false)
		.after {
			$0.content("→", alternativeText: "")
		}
		.hoverFill(.card, color: .primaryText)

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
				.frame(height: .length(.lineHeight(1) + .rootEm(2)))
				// The sections are full width on small screens, so the link is in the padding of the summary, not outside the screen.
				.below(.smallTablet) {
					$0.leading(.zero)
				}
				// Touch screens have no hover, so the link is a chip at the end of the open section (``headingAnchorStyle``).
				.media(.cannotHover) {
					$0
						.top(.auto)
						.bottom(.length(Self.touchCopyLinkInset))
						.leading(.length(.pageGutter))
						.frame(height: .auto)
				}
		}
		// The content has room for the chip of the link below its text on touch screens.
		.media(.cannotHover) {
			$0.children(ProseStyles.collapsibleSection.selector) {
				$0.children(ProseStyles.collapsibleContent.selector) {
					$0.padding(.bottom, Self.touchCopyLinkInset + .rootEm(3))
				}
			}
		}

	/**
	The space below the chip that copies the link to an open section on touch screens, the bottom padding of the content of a section.
	*/
	private static let touchCopyLinkInset = LengthPercentage.rootEm(1.25)

	/**
	The link to a section, shown while the pointer is over the section. `site.js` copies its URL on click and sets `data-state`.
	*/
	static let headingAnchorStyle = Style()
		.position(.absolute)
		.top(.zero)
		.bottom(.zero)
		.leading(.pixels(-28))
		.hstack(alignment: .center, justification: .center)
		.frame(width: .pixels(24))
		// On small screens, the link is in the padding of the page, not cut off at its edge.
		.below(.smallTablet) {
			$0.leading(.pixels(-24))
		}
		.opacity(0)
		.color(.secondaryText)
		.allowsHitTesting(false)
		.transition(.opacity, .color, timing: .stateChange)
		// The link of a closed question is not in the tab order, so a keyboard user does not press Tab twice for each question of a long FAQ, like the 75 of Dato. It is there when the question is open, and under the pointer. In `:where()`, so it adds no specificity, and the hovered section below wins.
		.nested(":where(\(ProseStyles.anchoredSection.selector):not(:has(> details[open]))) > &") {
			$0.visibility(false)
		}
		.before {
			$0
				.content("")
				.position(.absolute)
				.inset(.pixels(-8))
		}
		// The icon, in the color of the link. It is in the styles, so a page with many headings has no copies of it.
		.after {
			$0
				.content("")
				.frame(size: .pixels(16))
				.background(.currentColor)
				.maskImage(.url(#path("/assets/link.svg")))
				// Forced colors would paint the background, which is the icon, in the color of the page, so it has the color of links there.
				.media(.forcedColors) {
					$0
						.forcedColorAdjust(.none)
						.background(.linkText)
				}
		}
		.media(.hover) {
			$0
				// The hovered heading is in `:where()`, so it adds no specificity, and the states below win over it.
				.nested(":where(\(ProseStyles.anchoredHeading.selector):hover, \(ProseStyles.anchoredSection.selector):hover) > &") {
					$0.opacity(0.6)
				}
				// The link takes the pointer in every state while the heading is hovered, so the pointer stays over the heading, and `site.js` sees it leave after a copy. This rule stays more specific than the states below.
				.nested(":is(\(ProseStyles.anchoredHeading.selector), \(ProseStyles.anchoredSection.selector)):hover > &") {
					$0
						.allowsHitTesting(true)
						.visibility(true)
				}
		}
		.hover {
			$0
				.opacity(1)
				.color(.accentMark)
		}
		// Keyboard users see the link they move to.
		.focusVisible {
			$0
				.opacity(1)
				.allowsHitTesting(true)
				.color(.accentMark)
		}
		.when(States.copied) {
			$0
				.opacity(1)
				.color(.accentMark)
				.allowsHitTesting(false)
				.after {
					$0.maskImage(.url(#path("/assets/check.svg")))
				}
		}
		.when(States.hidden) {
			$0
				.opacity(0)
				.allowsHitTesting(false)
		}
		// On touch screens, the link of an open section is a chip with a title at the end of the answer, so visitors can copy the link to share the answer, also from a phone. The link of a closed section stays invisible (above). It stays after a copy, as there is no pointer to leave the section. After the states, so it wins over the hidden state.
		.media(.cannotHover) {
			$0.directlyInside(ProseStyles.anchoredSection.selector) {
				$0
					.chip(hasIcon: true)
					.frame(width: .auto)
					.opacity(1)
					.allowsHitTesting(true)
					// The title, after the icon. The name of the link, for screen readers, has it too.
					.before {
						$0
							.content("Copy Link", alternativeText: "")
							.position(.static)
							.order(1)
					}
					.when(States.copied) {
						$0.before {
							$0.content("Copied", alternativeText: "")
						}
					}
					.when(States.hidden) {
						$0
							.opacity(1)
							.allowsHitTesting(true)
					}
			}
		}
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
	Briefly highlights the background, like on the section or heading that a link points to. It also runs with reduced motion, as it only fades a color, and it shows the visitor where the link went.
	*/
	func targetHighlight() -> Self {
		animation(ProseAnimations.targetHighlight, .easeOut(duration: .seconds(2)), isEssential: true)
	}
}
