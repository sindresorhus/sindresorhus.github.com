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
	The size of smaller text in prose, like code and captions: 16px next to the 18px of the text.
	*/
	static let smallTextSize = Length.em(0.8889)

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
		// Long words break with a hyphen only on phones, where the column is narrow, like the long answers of an FAQ. An opening quote hangs outside the column, so the text lines up. Like in a book, for all prose, not only blog posts.
		.below(.smallTablet) {
			$0.hyphenation(true)
		}
		.declaration(.hangingPunctuation, "first")
		// A list has the space of a paragraph around it.
		.descendants("p, ul, ol") {
			$0.margin(vertical: .em(1), horizontal: 0)
		}
		.descendants("a") {
			$0.textLink()
		}
		.descendants("strong") {
			$0
				.color(.primaryText)
				.fontWeight(.semibold)
		}
		// Headings, and the headers of tables.
		.descendants("h1, h2, h3, h4, h5, h6, th") {
			$0
				.color(.primaryText)
				.fontWeight(.semibold)
		}
		// The title of Markdown pages, the same as the title of other pages (``PageHeader``) and the space below it (``ProsePage``).
		.descendants("h1") {
			$0
				.margin(top: 0, horizontal: 0, bottom: .rootEm(2.5))
				.textStyle(.largeTitle)
		}
		// A paragraph right below the title is its introduction, with the look and the space of the introduction of other pages (``PageHeader``).
		.descendants("h1:has(+ p)") {
			$0.margin(.bottom, .rootEm(0.5))
		}
		.descendants("h1 + p") {
			$0
				.margin(top: .rootEm(0.5), horizontal: 0, bottom: .rootEm(2.5))
				.secondaryText(.lead)
		}
		// Larger headings, up to `h3`, get tighter letter spacing, like the system fonts of Apple platforms.
		.descendants("h2") {
			$0
				.margin(top: .rootEm(5), horizontal: 0, bottom: .rootEm(1.5))
				.textStyle(.sectionTitle)
		}
		// Each level is clearly smaller than the one above it: 22px, then the 18px of the text, and then 16px.
		.descendants("h3") {
			$0
				.margin(top: .rootEm(2.5), horizontal: 0, bottom: .rootEm(1))
				.font(size: .em(1.2222), lineHeight: 1.3)
				.letterSpacing(.em(-0.015))
		}
		.descendants("h4, h5, h6") {
			$0
				.margin(top: .rootEm(2), horizontal: 0, bottom: .rootEm(1))
				.lineHeight(1.5)
		}
		.descendants("h5, h6") {
			$0.font(size: smallTextSize)
		}
		// A line break right after a heading, which some content uses for more space, does not add to the space below the heading.
		.descendants(":is(h2, h3, h4, h5, h6) + br") {
			$0.hidden()
		}
		.descendants("ul, ol") {
			$0.padding(.leading, .em(1.5556))
		}
		.descendants("ul") {
			$0.listStyle(.disc)
		}
		.descendants("ol") {
			$0.listStyle(.decimal)
		}
		// List items, nested lists, and the paragraphs of a loose list, where Markdown wraps each item in a paragraph, have the space of list items.
		.descendants("li, li > :is(p, ul, ol)") {
			$0.margin(vertical: listItemSpacing, horizontal: 0)
		}
		.descendants("li") {
			$0.padding(.leading, .em(0.4444))
		}
		// In a list with `: ` and `:: ` lines, like the features of an app, a nested list is details of its item, so it looks like the `:: ` lines, and not heavier than them.
		.descendants(":is(ul, ol):has(> li > :is(\(ProseStyles.listSubtitle.selector), \(ProseStyles.listDescription.selector))) > li > :is(ul, ol)") {
			$0.listDetailText()
		}
		.nested(":where(ol > li)::marker") {
			$0.color(.secondaryText)
		}
		.nested(":where(ul > li)::marker") {
			$0.color(.gray(300), dark: .gray(600))
		}
		// The margins are with the element rules, so the spacing rules after them, like no space below a heading, win.
		.descendants("blockquote, pre, img, video, picture, figure, \(ProseStyles.tableContainer.selector), \(CodeBlock.Styles.root.selector)") {
			$0.proseBlockMargin()
		}
		.descendants(CodeBlock.Styles.root.selector) {
			$0.widerThanProse()
		}
		.descendants("hr") {
			$0
				.margin(vertical: .em(3), horizontal: 0)
				.border(.top, .separator)
		}
		.descendants("blockquote") {
			$0
				.padding(.leading, .em(1))
				.border(.leading, .separator, width: .rootEm(0.25))
				.italic()
				.fontWeight(.medium)
				.color(.gray(900), dark: .gray(100))
		}
		.descendants("blockquote p:first-of-type") {
			$0.before {
				$0.declaration(.content, "open-quote")
			}
		}
		.descendants("blockquote p:last-of-type") {
			$0.after {
				$0.declaration(.content, "close-quote")
			}
		}
		// App icons (`icon.png`) have their own shape and shadow.
		.descendants("img:not([src$='/icon.png'])") {
			$0
				.cornerRadius(.rootEm(0.375))
				.shadow(.large)
		}
		.descendants("figcaption") {
			$0
				.margin(.top, .em(1))
				.font(size: smallTextSize, lineHeight: 1.5)
				.color(.secondaryText)
		}
		// Code is not hyphenated, like the prose on phones, as a hyphen would change it.
		.descendants("code") {
			$0
				.font(size: smallTextSize)
				.fontWeight(.semibold)
				.color(.primaryText)
				.hyphenation(false)
		}
		// Strong text and code in links, quotes, headings, and table headers have the color of the text around them.
		.descendants(":is(a, blockquote, h1, h2, h3, h4, h5, h6, th) :is(strong, code)") {
			$0.color(.inherit)
		}
		// Code that is not a `CodeBlock`, like in release notes.
		.descendants("pre") {
			$0.codeSurface()
		}
		// The code in a code block has the font of the block, not of inline code.
		.descendants("pre code") {
			$0
				.inheritsFont()
				.color(.inherit)
		}

	/**
	Spacing between blocks, after the element rules so it wins.
	*/
	static let spacing = Style()
		// Also after a line break that follows a heading, which takes no space.
		.descendants(":is(hr, h2, h3, h4, h5, h6) + *, :is(h2, h3, h4, h5, h6) + br + *") {
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
		.listDetailText()
		// Slightly more spacing when both are used, and the description is smaller.
		.nested("\(ProseStyles.listSubtitle.selector) + &") {
			$0
				.margin(.top, .rootEm(0.5))
				.font(.extraSmall)
		}

	/**
	A paragraph that only has bold text, like `**Highlights**` or `**More features**`, which works as a label for the list or text below it. It has slightly more space above than the space between paragraphs, so it reads as the start of a new group, and not as the end of the text above. The space below stays, so the label stays with its content. The renderer only gives this class to a paragraph that has nothing but bold text, so a line like `**macOS:** Click …` keeps the normal space. This is intentional.
	*/
	static let boldLabelStyle = Style()
		// Not as the first block, which has no space above, and not below a heading or a rule, which has its own space below.
		.nested("&:not(:first-child, :is(hr, h1, h2, h3, h4, h5, h6, br) + &)") {
			$0.margin(.top, .em(1.5))
		}

	/**
	Blog posts: colored links, oldstyle numerals, and optimized legibility. The hyphenation and hanging punctuation are in ``typography``, for all prose.
	*/
	static let articleStyle = Style()
		.padding(.bottom, .rootEm(5))
		// Oldstyle numerals. Ligatures and kerning are on by default.
		.declaration(.fontVariantNumeric, "oldstyle-nums")
		.declaration(.textRendering, "optimizeLegibility")
		.descendants("a") {
			$0
				.color(.link)
				// The color of the link, so the underline is not darker than the text in dark mode.
				.hoverOrFocusVisible {
					$0
						.underlineColor(.link)
						.underlineThickness(.pixels(4))
				}
		}

	/**
	The number of a footnote reference, a button that opens the footnote in a popover.
	*/
	static let footnoteReferenceStyle = Style()
		.padding(.horizontal, .pixels(2))
		.fontWeight(.semibold)
		.color(.link)
		.hoverOrFocusVisible {
			$0.underline()
		}
		.minimumTapArea()

	/**
	A footnote or an inline note in a popover, above the reference that opened it, or below when there is no space above.
	*/
	static let popoverStyle = Style()
		.positionArea(.top)
		.positionTryFallbacks(.flipBlock)
		.inset(.auto)
		.margin(.pixels(8))
		.frame(maxWidth: .min(.rootEm(24), .viewportWidth(100) - .rootEm(2)))
		.padding(vertical: .rootEm(0.75), horizontal: .rootEm(1))
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
	A list in prose that does not look like a list of prose, like the details below a card or a step: without the space of a list, and with items that are blocks, so they have no bullets. Put it first, so the styles after it win.
	*/
	func plainList() -> Self {
		margin(0)
			.padding(0)
			.children("li") {
				$0
					.display(.block)
					.margin(0)
					.padding(0)
			}
	}

	/**
	The small, secondary text of the details of a list item in prose, like a `:: ` line, and a nested list below it, so they look the same.
	*/
	fileprivate func listDetailText() -> Self {
		font(size: .rootEm(0.875), lineHeight: 1.625)
			.color(.secondaryText)
	}

	/**
	The space of a block in prose above and below the element (``ProseStyles/blockSpacing``), like code, an alert, or a card, so it is set off from the text.
	*/
	func proseBlockMargin() -> Self {
		margin(vertical: ProseStyles.blockSpacing, horizontal: 0)
	}

	/**
	A card that is set off from the text of prose, like a quick answer or a trial, with the space of a block around it.
	*/
	func proseCard() -> Self {
		proseBlockMargin()
			.padding(.rootEm(1.75))
			.cardSurface(isInteractive: false)
			.trimmingChildMargins()
	}
}
