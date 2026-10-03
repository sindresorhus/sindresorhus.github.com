import SiteKit

extension ProseStyles {
	/**
	Typography from the Tailwind Typography plugin (`prose prose-lg lg:prose-xl dark:prose-invert`), as the old site used it.

	The element rules use `:where()`, so they have the specificity of the prose class alone, and later rules, like the first-child margin, win over them.
	*/
	static let typography = Style()
		.frame(width: .percent(100), maxWidth: .rem(56))
		.margin(top: .rem(2), horizontal: .auto, bottom: 0)
		.padding(.horizontal, .rem(1.5))
		.font(size: .rem(1.125), lineHeight: 1.7778)
		.letterSpacing(0)
		.declaration(.overflowWrap, "break-word")
		.color(.bodyText)
		.breakpoint(.lg) {
			$0.font(size: .rem(1.25), lineHeight: 1.8)
		}
		.nested(":where(p)") {
			$0
				.margin(vertical: .em(1.3333), horizontal: 0)
				.breakpoint(.lg) {
					$0.margin(vertical: .em(1.2), horizontal: 0)
				}
		}
		.nested(":where(a)") {
			$0
				.color(.black.opacity(0.75), dark: .white.opacity(0.9))
				.fontWeight(.medium)
				.underline(thickness: .px(2))
				.underlineColor(.primary(500))
				.underlineOffset(.px(4))
				.hover {
					$0
						.color(.black)
						.underlineColor(.primary(700))
				}
				.dark {
					$0
						.underlineColor(.primary(400))
						.hover {
							$0
								.color(.white)
								.underlineColor(.primary(300))
						}
				}
		}
		.nested(":where(strong)") {
			$0
				.color(.primaryText)
				.fontWeight(.semibold)
		}
		.nested(":where(a strong, blockquote strong, thead th strong, h1 strong, h2 strong, h3 strong, h4 strong)") {
			$0.color(.inherit)
		}
		.nested(":where(h1, h2, h3, h4, h5, h6, th)") {
			$0
				.color(.gray(900), dark: .slate(300))
				.bold()
				.letterSpacing(.em(-0.05))
		}
		.nested(":where(h1)") {
			$0
				.margin(top: 0, horizontal: 0, bottom: .em(0.8333))
				.font(size: .em(2.6667), lineHeight: 1)
				.breakpoint(.lg) {
					$0
						.margin(.bottom, .em(0.8571))
						.font(size: .em(2.8))
				}
		}
		.nested(":where(h2)") {
			$0
				.margin(top: .rem(6), horizontal: 0, bottom: .em(1.0667))
				.font(size: .em(1.6667), lineHeight: 1.3333)
				.breakpoint(.lg) {
					$0
						.margin(.bottom, .em(0.8889))
						.font(size: .em(1.8), lineHeight: 1.1111)
				}
		}
		.nested(":where(h3)") {
			$0
				.margin(top: .em(1.6667), horizontal: 0, bottom: .em(0.6667))
				.font(size: .em(1.3333), lineHeight: 1.5)
				.breakpoint(.lg) {
					$0
						.margin(top: .em(1.6), horizontal: 0, bottom: .em(0.6667))
						.font(size: .em(1.5), lineHeight: 1.3333)
				}
		}
		.nested(":where(h4)") {
			$0
				.margin(top: .em(1.7778), horizontal: 0, bottom: .em(0.4444))
				.lineHeight(1.5556)
				.letterSpacing(0)
				.breakpoint(.lg) {
					$0
						.margin(top: .em(1.8), horizontal: 0, bottom: .em(0.6))
						.lineHeight(1.6)
				}
		}
		.nested(":where(h5, h6)") {
			$0.letterSpacing(0)
		}
		.nested(":where(ul, ol)") {
			$0
				.margin(vertical: .em(1.3333), horizontal: 0)
				.padding(.leading, .em(1.5556))
				.breakpoint(.lg) {
					$0
						.margin(vertical: .em(1.2), horizontal: 0)
						.padding(.leading, .em(1.6))
				}
		}
		.nested(":where(ul)") {
			$0.declaration(.listStyleType, "disc")
		}
		.nested(":where(ol)") {
			$0.declaration(.listStyleType, "decimal")
		}
		.nested(":where(li)") {
			$0
				.margin(vertical: .em(0.6667), horizontal: 0)
				.padding(.leading, .em(0.4444))
				.breakpoint(.lg) {
					$0
						.margin(vertical: .em(0.6), horizontal: 0)
						.padding(.leading, .em(0.4))
				}
		}
		.nested(":where(ol > li)::marker") {
			$0.color(.gray(500))
		}
		.nested(":where(ul > li)::marker") {
			$0
				.color(.gray(300), dark: .gray(600))
		}
		.nested(":where(ul ul, ul ol, ol ul, ol ol)") {
			$0
				.margin(vertical: .em(0.8889), horizontal: 0)
				.breakpoint(.lg) {
					$0.margin(vertical: .em(0.8), horizontal: 0)
				}
		}
		.nested(":where(hr)") {
			$0
				.margin(vertical: .em(3.1111), horizontal: 0)
				.border(.top)
				.borderColor(.separator)
				.breakpoint(.lg) {
					$0.margin(vertical: .em(2.8), horizontal: 0)
				}
		}
		.nested(":where(blockquote)") {
			$0
				.margin(vertical: .em(1.6667), horizontal: 0)
				.padding(.leading, .em(1))
				.declaration(.borderLeft, ".25rem solid")
				.borderColor(.separator)
				.italic()
				.fontWeight(.medium)
				.color(.gray(900), dark: .gray(100))
				.declaration(.quotes, #""\201C" "\201D" "\2018" "\2019""#)
				.breakpoint(.lg) {
					$0
						.margin(vertical: .em(1.6), horizontal: 0)
						.padding(.leading, .em(1.0667))
				}
		}
		.nested(":where(blockquote p:first-of-type)::before") {
			$0.declaration(.content, "open-quote")
		}
		.nested(":where(blockquote p:last-of-type)::after") {
			$0.declaration(.content, "close-quote")
		}
		.nested(":where(img, video, picture, figure)") {
			$0
				.margin(vertical: .em(1.7778), horizontal: 0)
				.breakpoint(.lg) {
					$0.margin(vertical: .em(2), horizontal: 0)
				}
		}
		.nested(":where(img)") {
			$0
				.cornerRadius(.rem(0.375))
				.shadow(.large)
		}
		.nested(":where(figcaption)") {
			$0
				.margin(.top, .em(1))
				.font(size: .em(0.8889), lineHeight: 1.5)
				.color(.gray(500))
		}
		.nested(":where(code)") {
			$0
				.font(size: .em(0.8889))
				.fontWeight(.semibold)
				.color(.primaryText)
				.breakpoint(.lg) {
					$0.font(size: .em(0.9))
				}
		}
		.nested(":where(a code, h1 code, h2 code, h3 code, h4 code, blockquote code, thead th code)") {
			$0.color(.inherit)
		}
		.nested(":where(pre)") {
			$0
				.margin(vertical: .em(2), horizontal: 0)
				.padding(vertical: .em(1), horizontal: .em(1.5))
				.cornerRadius(.rem(0.375))
				.overflow(horizontal: .auto)
				.font(size: .em(0.8889), lineHeight: 1.75)
				.fontWeight(.regular)
				.color(.gray(200))
				.background(.gray(800), dark: .black.opacity(0.5))
				.breakpoint(.lg) {
					$0
						.padding(vertical: .em(1.1111), horizontal: .em(1.3333))
						.cornerRadius(.rem(0.5))
						.font(size: .em(0.9), lineHeight: 1.7778)
				}
		}
		.nested(":where(pre code)") {
			$0
				.padding(0)
				.declaration(.fontSize, .inherit)
				.declaration(.fontWeight, .inherit)
				.declaration(.lineHeight, .inherit)
				.color(.inherit)
				.background(.transparent)
		}

	/**
	Spacing between blocks, after the element rules so it wins.
	*/
	static let spacing = Style()
		.nested(":where(hr + *, h2 + *, h3 + *, h4 + *)") {
			$0.margin(.top, 0)
		}
		.children(":where(:first-child)") {
			$0.margin(.top, 0)
		}
		.children(":where(:last-child)") {
			$0.margin(.bottom, 0)
		}
		// Note: A subtitle has to be a span, as otherwise Markdown inside it is not rendered. The content uses these class names in raw HTML.
		.nested(".list-subtitle") {
			$0
				.display(.block)
				.font(size: .rem(1), lineHeight: 1.375)
				.opacity(0.65)
				// Slightly more spacing when both are used, and the description is smaller.
				.nested("& + .list-description") {
					$0
						.margin(.top, .rem(0.5))
						.font(.xs)
				}
				.dark {
					$0.opacity(0.6)
				}
		}
		.nested(".list-description") {
			$0
				.display(.block)
				.font(size: .rem(0.875), lineHeight: 1.625)
				.opacity(0.65)
				.dark {
					$0.opacity(0.6)
				}
		}

	/**
	Blog posts: colored links, the tighter site letter spacing, and typographic refinements.
	*/
	static let articleStyle = Style()
		.frame(maxWidth: .rem(48))
		.padding(.bottom, .rem(5))
		.declaration(.letterSpacing, .inherit)
		// Ligatures, kerning, and oldstyle numerals.
		.declaration(.fontFeatureSettings, "'liga' 1, 'kern' 1, 'onum' 1")
		.declaration("text-rendering", "optimizeLegibility")
		.declaration(.hyphens, .auto)
		.declaration("hanging-punctuation", "first")
		// A post that starts with an image moves up, so the gap below the header is the same as with text.
		.nested("&:has(> p:first-child > img)") {
			$0.margin(.top, .px(-16))
		}
		.nested(":where(a)") {
			$0
				.color(.link)
				.hover {
					$0
						.color(.link)
						.underlineColor(.primary(600))
						.underlineThickness(.px(4))
				}
		}
		.nested(":where(h4, h5, h6)") {
			$0.letterSpacing(.em(-0.05))
		}
		// Prevents orphans in paragraphs.
		.nested(":where(p)") {
			$0.textWrap(.pretty)
		}

	static let footnotesStyle = Style()
		.important {
			$0.margin(.top, .px(100))
		}

	/**
	The number of a footnote reference, a button that opens the footnote in a popover.
	*/
	static let footnoteReferenceStyle = Style()
		.padding(.horizontal, .px(2))
		.fontWeight(.semibold)
		.color(.link)
		.cursor(.pointer)
		.hover {
			$0.underline()
		}
		.focusVisible {
			$0.focusRing(.primary(500), width: .px(2))
		}

	/**
	A footnote in a popover, above the reference that opened it, or below when there is no space above. Without anchor positioning, the browser centers it.
	*/
	static let footnotePopoverStyle = Style()
		.supports("(position-area: top)") {
			$0
				.declaration(.positionArea, "top")
				.declaration("position-try-fallbacks", "flip-block")
				.inset(.auto)
				.margin(.px(8))
		}
		.frame(maxWidth: Length("min(24rem, calc(100vw - 2rem))"))
		.padding(vertical: .rem(0.75), horizontal: .rem(1))
		.cornerRadius(.rem(0.75))
		.border(.lightDark(.black.opacity(0.08), .white.opacity(0.1)))
		.font(size: .rem(0.9375), lineHeight: 1.5)
		.textAlign(.leading)
		.color(.bodyText)
		.background(.white, dark: .slate(900))
		.shadow(.large)
		.children(":first-child") {
			$0.margin(.top, 0)
		}
		.children(":last-child") {
			$0.margin(.bottom, 0)
		}

	/**
	A code block with a bar in its corner. It has the margins of the code inside, so the bar is at the top of the code.
	*/
	static let codeBlockStyle = Style()
		.position(.relative)
		.margin(vertical: .em(1.7778), horizontal: 0)
		.breakpoint(.lg) {
			$0.margin(vertical: .em(1.8), horizontal: 0)
		}
		.children("pre") {
			$0.margin(0)
		}

	/**
	The language of the code and the copy button, at the top right. The copy button shows while the pointer is over the code or it has focus, and on touch screens. Without JavaScript, there is no copy button.
	*/
	static let codeBlockBarStyle = Style()
		.position(.absolute)
		.top(.rem(0.375))
		.trailing(.rem(0.375))
		.hstack(alignment: .center, spacing: .rem(0.375))
		.font(size: .rem(0.75), lineHeight: 1.5)

	static let codeBlockLanguageStyle = Style()
		.padding(.horizontal, .rem(0.25))
		.fontFamily(.monospace)
		.color(.gray(400))
		.textSelection(.disabled)

	static let copyButtonStyle = Style()
		.display(.grid)
		.padding(vertical: .rem(0.125), horizontal: .rem(0.5))
		.cornerRadius(.rem(0.375))
		.fontWeight(.medium)
		.color(.gray(200))
		.background(.white.opacity(0.1))
		.opacity(0)
		.transition(.opacity, .backgroundColor, duration: .milliseconds(150))
		.children("span") {
			$0.declaration("grid-area", "1 / 1")
		}
		.children("span:last-child") {
			$0.visibility(false)
		}
		.nested("&[data-state=\"copied\"]") {
			$0
				.children("span:first-child") {
					$0.visibility(false)
				}
				.children("span:last-child") {
					$0.visibility(true)
				}
		}
		.hover {
			$0.background(.white.opacity(0.2))
		}
		.focusVisible {
			$0
				.opacity(1)
				.focusRing(.primary(400), width: .px(2))
		}
		.nested("\(ProseStyles.codeBlock.selector):hover &, \(ProseStyles.codeBlock.selector):focus-within &, &[data-state]") {
			$0.opacity(1)
		}
		.media(.cannotHover) {
			$0.opacity(1)
		}
		.media(.scriptingDisabled) {
			$0.hidden()
		}
}
