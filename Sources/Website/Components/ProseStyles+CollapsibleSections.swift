import SiteKit

/**
Collapsible sections, like the FAQ questions, and the links to sections on the FAQ page. The Markdown renderer creates the markup.
*/
extension ProseStyles {
	/**
	The states that `site.js` sets on the link to a section or to a step (``StepListStyles/link``): copied after a click, and hidden until the pointer leaves the section.
	*/
	enum States: String, ElementStateSet {
		case copied
		case hidden
	}

	/**
	The data attribute of a link that copies the URL of its section or step when it is clicked (`site.js`), like the link of a heading that the Markdown renderer adds (``SiteKit/MarkdownDocument/Options/addsHeadingAnchors``).
	*/
	enum Hooks: String, ScriptDataAttributeSet {
		case copyLink = "copy-link"
	}

	/**
	The gap between two collapsible sections, like the questions of an FAQ, so their boxes do not touch.
	*/
	static let collapsibleSectionSpacing = LengthPercentage.rootEm(0.625)

	static let collapsibleSectionsStyle = Style()
		.vstack(spacing: collapsibleSectionSpacing)
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
		.setting(sectionFill, to: .lightDark(.card, .white.opacity(0.05)))
		// With more contrast, the fill of the other cards, which is stronger then.
		.media(.moreContrast) {
			$0.setting(sectionFill, to: .card)
		}
		.background(sectionFill.value)
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
		.squareInFullWidthGroup()
		// The section is as wide as the screen there, so it has the edge of a card only above and below it, not at the edges of the screen, like the tables of prose.
		.inFullWidthGroup {
			$0.screenWideCardEdges()
		}
		.target {
			$0
				.targetHighlight(.sectionTargetHighlight)
				// A link to the section opens it at once, as the answer that grows while the page scrolls to it makes the page slide past it on phones and jump back (scroll anchoring with the sticky question).
				.detailsContent {
					$0.noTransition()
				}
		}

	/**
	The padding and corners of a summary, which the link to more questions shares, so it looks like a closed question.
	*/
	private static let collapsibleRow = Style()
		// The horizontal padding is the padding of the page, so on small screens, where the sections are full width, the text lines up with the text around it.
		.padding(vertical: .rootEm(1), horizontal: .pageGutter)
		.cornerRadius(.boxRadius)
		.squareInFullWidthGroup()

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
		// The question of an open section stays at the top of the screen while the visitor reads a long answer, so the visitor sees what it answers, and can close it there (`site.js` then scrolls back to it). Its bottom corners are square, so its fill under the pointer is the top of the section, not a pill on it.
		.nested("details:open > &") {
			$0
				.position(.sticky)
				.top(.length(SiteHeader.height))
				// Above the positioned elements of the answer, like a code block, which scroll under it.
				.zIndex(1)
				.bottomCornerRadius(.zero)
				// Opaque, so the answer does not show through it: the fill of the section, over the fill of a box around it, like a box of tips, over the page. The fill under the pointer is a layer too, as the background color is below the layers.
				.backgroundImage(.fill(sectionFill.value), .fill(alertFill.value(default: .transparent)), .fill(.pageBackground))
				// The edge of the section, which the opaque fill would cover, so it also has a line below the question, which keeps it apart from the answer that scrolls under it. Not inherited from the section, as Chrome gives a summary the values of the slot of its `details`, not of the `details` itself.
				.shadow(.edge(.cardEdge), .cardTopLight)
				.media(.moreContrast) {
					$0.shadow(.edge(.separator))
				}
				// Where the section is as wide as the screen, the edges of the section, which the opaque fill would cover, with the line below.
				.inFullWidthGroup {
					$0.screenWideCardEdges()
				}
				.hoverOrFocusVisibleOrActive {
					$0.backgroundImage(.fill(.cardHover), .fill(sectionFill.value), .fill(alertFill.value(default: .transparent)), .fill(.pageBackground))
				}
				// The header scrolls with the page on short screens (``SiteHeader``), so the question stays at the top of the screen there.
				.media(.shortScreen) {
					$0.top(.zero)
				}
		}

	/**
	The question in the summary, which is a heading, so it is in the outline of the page. It looks like the rest of the summary.
	*/
	static let collapsibleTitleStyle = Style()
		.flex(1)
		.frame(minWidth: .zero)
		.margin(.zero)
		.inheritsFont()
		// The line height of a title, like a heading of the prose, so the lines of a question that wraps stay together, not the line height of the text.
		.lineHeight(1.3)
		.inherits(.letterSpacing)
		.inherits(.color)
		// Balanced, so a question that wraps does not end with one word on its last line. The questions are short, and `pretty` in Chrome does not always prevent it.
		.textWrap(.balance)
		// The font has more space above the capitals than below the baseline, so the text would look a little low next to the chevron. Trimming the text to the capitals and the baseline centers it at every size and zoom, and the padding keeps the height of the line.
		.trimmedText()

	static let collapsibleChevronStyle = Style()
		.hstack(alignment: .center, isInline: true)
		.flexShrink(0)
		.margin(.leading, .rootEm(0.5))
		// The chevron icon of the site, like on the link cards of the about page. The ink of the icon is only the middle of its box, so the negative margin puts the end of its ink at the padding of the row, like the start of the question on the other side. The path ends at 16 of 24, so the empty space is a third of the box.
		.margin(.trailing, Icon.chevronTrailingMargin)
		.after {
			$0
				.content("")
				.frame(size: .rootEm(1.25))
				.background(.secondaryText)
				.maskImage(Self.chevronMask)
				.transition(.rotationEffect, timing: .disclosure)
				// Forced colors would paint the background, which is the chevron, in the color of the page.
				.media(.forcedColors) {
					$0
						.forcedColorAdjust(.none)
						.background(.canvasText)
				}
		}
		.nested("details:open > * > &::after") {
			$0.rotationEffect(.degrees(90))
		}

	/**
	The shape of the chevron, written once.
	*/
	private static let chevronMask = CSSImage.url(svg: Icon.chevronRight.standaloneSVG)

	/**
	The shape of the arrow of the link to more questions, written once.
	*/
	private static let arrowMask = CSSImage.url(svg: Icon.arrowRight.standaloneSVG)

	static let collapsibleContentStyle = Style()
		.padding(top: .rootEm(0.625), horizontal: .pageGutter, bottom: .rootEm(1.25))
		.trimmingChildMargins()
		// The answer is already a box, so a code block or an alert in it stays inside its padding, and does not hang into the space at the sides of the text (``Style/widerThanProse()``), which here is the edge of the answer.
		.children("\(CodeBlock.Styles.root.selector), \(ProseStyles.alert.selector)") {
			$0.margin(.horizontal, .zero)
		}

	/**
	The link to more questions below the questions, a row like a closed question, so the list ends with it. The arrow is the arrow icon of the site, with the line of the chevrons of the questions, and it ends where they end.
	*/
	static let collapsibleMoreLinkStyle = collapsibleRow
		.hstack(alignment: .center, justification: .spaceBetween)
		.margin(.top, .length(collapsibleSectionSpacing))
		.shadow(.edge(.separator))
		.inFullWidthGroup {
			$0.shadow(.horizontalEdges(.separator))
		}
		// The line height of the questions above it, so the rows have one height.
		.lineHeight(1.3)
		.fontWeight(.medium)
		.color(.secondaryText)
		.noUnderline()
		// In the color of the link. The ink of the arrow is wider than the ink of the chevron, so its negative margin is smaller.
		.after {
			$0
				.content("")
				.frame(size: .rootEm(1.25))
				.flexShrink(0)
				.margin(.trailing, .rootEm(-0.26))
				.background(.currentColor)
				.maskImage(Self.arrowMask)
				// Forced colors would paint the background, which is the arrow, in the color of the page, so it has the color of links there.
				.media(.forcedColors) {
					$0
						.forcedColorAdjust(.none)
						.background(.linkText)
				}
		}
		.hoverFill(.card, color: .primaryText)

	static let anchoredHeadingStyle = Style()
		.position(.relative)
		// Small, as the highlight adds its space to the corners (``ProseAnimations/headingTargetHighlight``).
		.cornerRadius(.rootEm(0.125))
		.target {
			$0.targetHighlight(.headingTargetHighlight)
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
				// It is part of the answer there, so it scrolls under the question that stays at the top of the screen.
				.media(.cannotHover) {
					$0
						.top(.auto)
						.bottom(.length(Self.touchCopyLinkInset))
						.leading(.length(.pageGutter))
						.frame(height: .auto)
						.zIndex(0)
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
		// Above the question of an open section, which is opaque, and on small screens has the link in its padding.
		.zIndex(2)
		// Until prose has space at its sides, the link is in the padding of the page, not cut off at its edge.
		.below(.proseWithGutters) {
			$0.leading(.pixels(-24))
		}
		.opacity(0)
		.color(.secondaryText)
		.allowsHitTesting(false)
		.transition(.opacity, .color, timing: .stateChange)
		// The link of a closed question is not in the tab order, so a keyboard user does not press Tab twice for each question of a long FAQ, like the 75 of Dato. It is there when the question is open, and under the pointer. In `:where()`, so it adds no specificity, and the hovered section below wins.
		.directlyInside(":where(\(ProseStyles.anchoredSection.selector):not(:has(> details[open])))") {
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
A short highlight of the section or heading that a link points to, like the FAQ question that a suggestion on the feedback page opens. In the colors of the selection, so it has the accent of the page, like the color of the app on an app page.
*/
enum ProseAnimations: String, KeyframeSet {
	case targetHighlight

	/**
	The highlight of a collapsible section, which fades its fill (``sectionFill``), not its background, so the question of an open section, which paints the fill too, has the highlight.
	*/
	case sectionTargetHighlight

	/**
	The highlight of a heading, which has no padding, so the fill also has some space around the text, as a shadow, which does not change the layout.
	*/
	case headingTargetHighlight

	var keyframes: [Keyframe] {
		switch self {
		case .targetHighlight:
			[.from(Style().background(.selectionFill))]
		case .sectionTargetHighlight:
			[.from(Style().setting(sectionFill, to: .selectionFill))]
		case .headingTargetHighlight:
			[
				.from(
					Style()
						.background(.selectionFill)
						.shadow(BoxShadow(y: .zero, spread: .rootEm(0.5), color: .selectionFill))
				),
			]
		}
	}
}

extension Style {
	/**
	Briefly highlights the background, like on the section or heading that a link points to. It also runs with reduced motion, as it only fades a color, and it shows the visitor where the link went.
	*/
	func targetHighlight(_ highlight: ProseAnimations = .targetHighlight) -> Self {
		animation(highlight, .easeOut(duration: .seconds(2)), isEssential: true)
	}

	/**
	Square corners on small screens in a group of sections, which is full width there (``ProseStyles/collapsibleSectionsStyle``), for the sections, their summaries, and the link to more questions. A section alone, like a `@Details` in a box of tips, keeps its round corners.
	*/
	fileprivate func squareInFullWidthGroup() -> Self {
		inFullWidthGroup {
			$0.cornerRadius(.zero)
		}
	}

	/**
	Styles the element on small screens in a group of sections, which is full width there (``ProseStyles/collapsibleSectionsStyle``).
	*/
	fileprivate func inFullWidthGroup(_ content: (Self) -> Self) -> Self {
		below(.smallTablet) {
			$0.inside(ProseStyles.collapsibleSections.selector, content)
		}
	}
}

/**
The fill of a collapsible section. The question of an open section paints it too, as it is opaque while it stays at the top of the screen (``ProseStyles/collapsibleSummaryStyle``). It is registered, so the highlight of the section that a link opens (``ProseAnimations/sectionTargetHighlight``) fades it in both.
*/
private let sectionFill = RegisteredProperty<Color>("section-fill", initialValue: .transparent)

extension CSSImage {
	/**
	An image of one color, to stack see-through fills as layers of a background.
	*/
	fileprivate static func fill(_ color: Color) -> Self {
		linearGradient(.toBottom, color, color)
	}
}
