import SiteKit

extension ProseStyles {
	/**
	The space between list items, and between the items of nested lists. It is less than the space below a heading, so a heading stays with the text below it, and less than the space between paragraphs, so the items of a list read as one block.
	*/
	static let listItemSpacing = Length.em(0.375)

	/**
	The space above and below a block that is set off from the text, like code, an image, a quote, a table, or an alert. It is more than the space between paragraphs.
	*/
	static let blockSpacing = Length.em(1.75)

	/**
	Typography based on the Tailwind Typography plugin (`prose prose-lg dark:prose-invert`), with shorter lines (about 78 characters, see ``Style/ColumnWidth/prose``) and a calmer heading scale.

	The element rules use `:where()`, so they have the specificity of the prose class alone, and later rules, like the first-child margin, win over them.
	*/
	static let typography = Style()
		.contentColumn(.prose)
		.frame(width: .percent(100))
		.font(size: .rootEm(1.125), lineHeight: 1.65)
		.letterSpacing(0)
		.overflowWrap(.breakWord)
		.color(.bodyText)
		// A list has the space of a paragraph around it.
		.nested(":where(p, ul, ol)") {
			$0.margin(vertical: .em(1), horizontal: 0)
		}
		.nested(":where(a)") {
			$0.textLink()
		}
		.nested(":where(strong)") {
			$0
				.color(.primaryText)
				.fontWeight(.semibold)
		}
		// Headings, and the headers of tables.
		.nested(":where(h1, h2, h3, h4, h5, h6, th)") {
			$0
				.color(.primaryText)
				.fontWeight(.semibold)
		}
		// The title of Markdown pages, the same as the title of other pages (``PageHeader``) and the space below it (``ProsePage``).
		.nested(":where(h1)") {
			$0
				.margin(top: 0, horizontal: 0, bottom: .rootEm(2.5))
				.textStyle(.largeTitle)
		}
		// Larger headings, up to `h3`, get tighter letter spacing, like the system fonts of Apple platforms.
		.nested(":where(h2)") {
			$0
				.margin(top: .rootEm(5), horizontal: 0, bottom: .rootEm(1.5))
				.font(size: .em(1.6667), lineHeight: 1.15)
				.bold()
				.letterSpacing(.em(-0.025))
		}
		// Each level is clearly smaller than the one above it: 22px, then the 18px of the text, and then 16px.
		.nested(":where(h3)") {
			$0
				.margin(top: .rootEm(2.5), horizontal: 0, bottom: .rootEm(1))
				.font(size: .em(1.2222), lineHeight: 1.3)
				.letterSpacing(.em(-0.015))
		}
		.nested(":where(h4, h5, h6)") {
			$0
				.margin(top: .rootEm(2), horizontal: 0, bottom: .rootEm(1))
				.lineHeight(1.5)
		}
		.nested(":where(h5, h6)") {
			$0.font(size: .em(0.8889))
		}
		// A line break right after a heading, which some content uses for more space, does not add to the space below the heading.
		.nested(":where(:is(h2, h3, h4, h5, h6) + br)") {
			$0.hidden()
		}
		.nested(":where(ul, ol)") {
			$0.padding(.leading, .em(1.5556))
		}
		.nested(":where(ul)") {
			$0.declaration(.listStyleType, "disc")
		}
		.nested(":where(ol)") {
			$0.declaration(.listStyleType, "decimal")
		}
		// List items, nested lists, and the paragraphs of a loose list, where Markdown wraps each item in a paragraph, have the space of list items.
		.nested(":where(li, li > :is(p, ul, ol))") {
			$0.margin(vertical: listItemSpacing, horizontal: 0)
		}
		.nested(":where(li)") {
			$0.padding(.leading, .em(0.4444))
		}
		// In a list with `: ` and `:: ` lines, like the features of an app, a nested list is details of its item, so it looks like the `:: ` lines, and not heavier than them.
		.nested(":where(:is(ul, ol):has(> li > :is(\(ProseStyles.listSubtitle.selector), \(ProseStyles.listDescription.selector))) > li > :is(ul, ol))") {
			$0
				.font(size: .rootEm(0.875), lineHeight: 1.625)
				.color(.secondaryText)
		}
		.nested(":where(ol > li)::marker") {
			$0.color(.gray(500))
		}
		.nested(":where(ul > li)::marker") {
			$0.color(.gray(300), dark: .gray(600))
		}
		// The margins are with the element rules, so the spacing rules after them, like no space below a heading, win.
		.nested(":where(blockquote, pre, img, video, picture, figure, \(ProseStyles.tableContainer.selector), \(CodeBlock.Styles.root.selector))") {
			$0.margin(vertical: blockSpacing, horizontal: 0)
		}
		.nested(":where(\(CodeBlock.Styles.root.selector))") {
			$0.widerThanProse()
		}
		.nested(":where(hr)") {
			$0
				.margin(vertical: .em(3), horizontal: 0)
				.border(.top, .separator)
		}
		.nested(":where(blockquote)") {
			$0
				.padding(.leading, .em(1))
				.border(.leading, .separator, width: .rootEm(0.25))
				.italic()
				.fontWeight(.medium)
				.color(.gray(900), dark: .gray(100))
		}
		.nested(":where(blockquote p:first-of-type)::before") {
			$0.declaration(.content, "open-quote")
		}
		.nested(":where(blockquote p:last-of-type)::after") {
			$0.declaration(.content, "close-quote")
		}
		// App icons (`icon.png`) have their own shape and shadow.
		.nested(":where(img:not([src$='/icon.png']))") {
			$0
				.cornerRadius(.rootEm(0.375))
				.shadow(.large)
		}
		.nested(":where(figcaption)") {
			$0
				.margin(.top, .em(1))
				.font(size: .em(0.8889), lineHeight: 1.5)
				.color(.secondaryText)
		}
		// Code is not hyphenated, like in blog posts on phones, as a hyphen would change it.
		.nested(":where(code)") {
			$0
				.font(size: .em(0.8889))
				.fontWeight(.semibold)
				.color(.primaryText)
				.declaration(.hyphens, .none)
		}
		// Strong text and code in links, quotes, headings, and table headers have the color of the text around them.
		.nested(":where(:is(a, blockquote, h1, h2, h3, h4, h5, h6, th) :is(strong, code))") {
			$0.color(.inherit)
		}
		// Code that is not a `CodeBlock`, like in release notes.
		.nested(":where(pre)") {
			$0.codeSurface()
		}
		// The code in a code block has the font of the block, not of inline code.
		.nested(":where(pre code)") {
			$0
				.inheritsFont()
				.color(.inherit)
		}

	/**
	Spacing between blocks, after the element rules so it wins.
	*/
	static let spacing = Style()
		// Also after a line break that follows a heading, which takes no space.
		.nested(":where(:is(hr, h2, h3, h4, h5, h6) + *, :is(h2, h3, h4, h5, h6) + br + *)") {
			$0.margin(.top, 0)
		}
		// Low specificity, so a block that sets its own margin, like an alert, keeps it.
		.children(":where(:first-child)") {
			$0.margin(.top, 0)
		}
		.children(":where(:last-child)") {
			$0.margin(.bottom, 0)
		}

	/**
	A `: ` line in a list item.
	*/
	static let listSubtitleStyle = Style()
		// Note: A subtitle has to be a span, as otherwise Markdown inside it is not rendered.
		.display(.block)
		.font(size: .rootEm(1), lineHeight: 1.375)
		.color(.secondaryText)

	/**
	A `:: ` line in a list item.
	*/
	static let listDescriptionStyle = Style()
		.display(.block)
		.font(size: .rootEm(0.875), lineHeight: 1.625)
		.color(.secondaryText)
		// Slightly more spacing when both are used, and the description is smaller.
		.nested("\(ProseStyles.listSubtitle.selector) + &") {
			$0
				.margin(.top, .rootEm(0.5))
				.font(.extraSmall)
		}

	/**
	Blog posts: colored links and typographic refinements.
	*/
	static let articleStyle = Style()
		.padding(.bottom, .rootEm(5))
		// Oldstyle numerals. Ligatures and kerning are on by default.
		.declaration(.fontVariantNumeric, "oldstyle-nums")
		.declaration(.textRendering, "optimizeLegibility")
		// Only on phones, where the column is narrow.
		.below(.smallTablet) {
			$0.declaration(.hyphens, .auto)
		}
		.declaration(.hangingPunctuation, "first")
		.nested(":where(a)") {
			$0
				.color(.link)
				.hover {
					$0
						.underlineColor(.primary(600))
						.underlineThickness(.pixels(4))
				}
		}

	/**
	The footnotes at the end, below a line, in smaller text, so they do not look like more of the text.
	*/
	static let footnotesStyle = Style()
		.margin(.top, .rootEm(4))
		.padding(.top, .rootEm(2))
		.border(.top, .separator)
		.font(size: .rootEm(0.9375), lineHeight: 1.6)

	/**
	The number of a footnote reference, a button that opens the footnote in a popover.
	*/
	static let footnoteReferenceStyle = Style()
		.padding(.horizontal, .pixels(2))
		.fontWeight(.semibold)
		.color(.link)
		.cursor(.pointer)
		.hover {
			$0.underline()
		}
		.minimumTapArea()

	/**
	A footnote in a popover, above the reference that opened it, or below when there is no space above.
	*/
	static let footnotePopoverStyle = Style()
		.positionArea(.top)
		.positionTryFallbacks(.flipBlock)
		.inset(.auto)
		.margin(.pixels(8))
		.frame(maxWidth: .min(.rootEm(24), .viewportWidth(100) - .rootEm(2)))
		.padding(vertical: .rootEm(0.75), horizontal: .rootEm(1))
		.cornerRadius(.rootEm(0.75))
		.popoverSurface()
		.font(size: .rootEm(0.9375), lineHeight: 1.5)
		.textAlign(.leading)
		.color(.bodyText)
		.trimmingChildMargins()
}

extension Style {
	/**
	An image in prose that does not look like an image of prose, like an app icon or a logo in a card: without the margins, the rounded corners, and the shadow.
	*/
	func plainImage() -> Self {
		margin(0)
			.cornerRadius(0)
			.shadow([])
	}

	/**
	A card that is set off from the text of prose, like a quick answer or a trial, with the space of a block around it.
	*/
	func proseCard() -> Self {
		margin(vertical: ProseStyles.blockSpacing, horizontal: 0)
			.padding(.rootEm(1.75))
			.cardSurface(isInteractive: false)
			.trimmingChildMargins()
	}
}
