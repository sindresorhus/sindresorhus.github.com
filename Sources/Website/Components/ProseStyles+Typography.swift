import SiteKit

extension ProseStyles {
	/**
	The space between list items, and between the items of nested lists. It is less than the space below a heading, so a heading stays with the text below it, and less than the space between paragraphs, so the items of a list read as one block.
	*/
	static let listItemSpacing = LengthPercentage.em(0.375)

	/**
	The space above and below a block that is set off from the text, like code, an image, a quote, a table, or an alert. It is more than the space between paragraphs.
	*/
	static let blockSpacing = LengthPercentage.em(1.75)

	/**
	The size of smaller text in prose, like code and captions: 16px next to the 18px of the text.
	*/
	static let smallTextSize = LengthPercentage.em(0.8889)

	/**
	Typography based on the Tailwind Typography plugin (`prose prose-lg dark:prose-invert`), with lines of about 87 characters (see ``Style/ColumnWidth/prose``) and a calmer heading scale.

	The element rules use `:where()`, so they have the specificity of the prose class alone, and later rules, like the first-child margin, win over them.
	*/
	static let typography = Style()
		.contentColumn(.prose)
		.frame(width: .percent(100))
		.font(size: .rootEm(1.125), lineHeight: 1.65)
		// On phones, a line has about 38 characters, not 87, and a short line needs less space between lines, so the eye still finds the start of the next line. The line height of body text (``TextStyle/body``).
		.below(.smallTablet) {
			$0.lineHeight(1.55)
		}
		.letterSpacing(.zero)
		.overflowWrap(.breakWord)
		.color(.bodyText)
		// An opening quote hangs outside the column, so the text lines up. Like in a book, for all prose, not only blog posts. Words do not break with a hyphen, also not on phones, as a hyphen splits many short words, like “meet-ing,” (browsers count the punctuation after a word), and the lines are already even (`text-wrap: pretty`).
		.hangingPunctuation(.first)
		// A list has the space of a paragraph around it.
		.descendants("p, ul, ol") {
			$0.margin(vertical: .em(1), horizontal: .zero)
		}
		// A link wraps only between its words, also in a text that breaks long words (``Style/breaksLongWords()``), as a hyphen in a link cuts its underline in two, so it looks like two links, like “Send me a mes-” and “sage”.
		.descendants("a") {
			$0
				.textLink()
				.hyphenation(false)
		}
		// A link with code, like “`uint8array-extras` package”, has one straight underline below the code, as the underline position of each font is different, and the underline of the code would cut through its fill.
		.descendants("a:has(code)") {
			$0.underlinePosition(.under)
		}
		.descendants("strong") {
			$0
				.color(.primaryText)
				.fontWeight(.semibold)
		}
		// A link in bold text has the weight of the text, as the underline already shows it. After the rule of links, so it wins.
		.descendants("strong a") {
			$0.inherits(.fontWeight)
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
				.margin(top: .zero, horizontal: .zero, bottom: .rootEm(2.5))
				.textStyle(.largeTitle)
		}
		// A paragraph right below the title is its introduction, with the look and the space of the introduction of other pages (``PageHeader``).
		.descendants("h1:has(+ p)") {
			$0.margin(.bottom, .length(PageHeaderStyles.introSpacing))
		}
		.descendants("h1 + p") {
			$0
				.margin(top: .length(PageHeaderStyles.introSpacing), horizontal: .zero, bottom: .rootEm(2.5))
				.secondaryText(.lead)
		}
		// Larger headings, up to `h3`, get tighter letter spacing, like the system fonts of Apple platforms.
		.descendants("h2") {
			$0
				.margin(top: .length(.partSpacing(rootEm: 5)), horizontal: .zero, bottom: .rootEm(1.5))
				.textStyle(.sectionTitle)
		}
		// Each level is clearly smaller than the one above it: 22px, then the 18px of the text, and then 16px.
		.descendants("h3") {
			$0
				.margin(top: .rootEm(2.5), horizontal: .zero, bottom: .rootEm(1))
				.font(size: .em(1.2222), lineHeight: 1.3)
				.letterSpacing(.em(-0.015))
		}
		.descendants("h4, h5, h6") {
			$0
				.margin(top: .rootEm(2), horizontal: .zero, bottom: .rootEm(1))
				.lineHeight(1.5)
		}
		.descendants("h5, h6") {
			$0.font(size: smallTextSize)
		}
		// A line break right after a heading, which some content uses for more space, does not add to the space below the heading.
		.descendants(":is(h2, h3, h4, h5, h6) + br") {
			$0.hidden()
		}
		// On phones, a smaller indent, so the narrow column has more room for the text of a list, also in a nested list. The markers still hang clearly.
		.descendants("ul, ol") {
			$0
				.padding(.leading, .em(1.5556))
				.below(.smallTablet) {
					$0.padding(.leading, .em(1.125))
				}
		}
		.descendants("ul") {
			$0.listStyle(.disc)
		}
		.descendants("ol") {
			$0.listStyle(.decimal)
		}
		// List items, nested lists, and the paragraphs of a loose list, where Markdown wraps each item in a paragraph, have the space of list items.
		.descendants("li, li > :is(p, ul, ol)") {
			$0.margin(vertical: .length(listItemSpacing), horizontal: .zero)
		}
		.descendants("li") {
			$0
				.padding(.leading, .em(0.4444))
				.below(.smallTablet) {
					$0.padding(.leading, .em(0.25))
				}
		}
		// In a list with `: ` and `:: ` lines, like the features of an app, a nested list is details of its item, so it looks like the `:: ` lines, and not heavier than them.
		.descendants(":is(ul, ol):has(> li > :is(\(class: ProseStyles.listSubtitle), \(class: ProseStyles.listDescription))) > li > :is(ul, ol)") {
			$0.listDetailText()
		}
		.nested(":where(ol > li)::marker") {
			$0.color(.secondaryText)
		}
		.nested(":where(ul > li)::marker") {
			// Between gray 300 and gray 400 in light mode, so the bullets have about the weight of gray 600 in dark mode.
			$0.color(.gray(300).mix(with: .gray(400), amount: .percent(50)), dark: .gray(600))
		}
		// The margins are with the element rules, so the spacing rules after them, like no space below a heading, win. Without specificity, like the element rules, also for the table container and the code block, as their margins are only for prose.
		.descendants("blockquote, pre, img, video, picture, figure, \(class: ProseStyles.tableContainer), \(class: CodeBlock.Styles.root)") {
			$0.proseBlockMargin()
		}
		// A collapsible section outside a group of questions, like `@Details`, is a block, like an alert. Sections in a row have the gap of the questions of an FAQ, so they do not touch. Only directly in the prose, as the questions of an FAQ are in their group, and a section in a box, like a box of tips, has the spacing of the box.
		.children(":where(details)") {
			$0.proseBlockMargin()
		}
		.children(":where(details:has(+ details))") {
			$0.margin(.bottom, .length(collapsibleSectionSpacing))
		}
		.children(":where(details + details)") {
			$0.margin(.top, .length(collapsibleSectionSpacing))
		}
		.descendants("\(class: CodeBlock.Styles.root)") {
			$0.widerThanProse()
		}
		.descendants("hr") {
			$0
				.margin(vertical: .em(3), horizontal: .zero)
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
				$0.content(.openQuote)
			}
		}
		.descendants("blockquote p:last-of-type") {
			$0.after {
				$0.content(.closeQuote)
			}
		}
		// A quote with its source below it has only the space of the source between them (``ProseStyles/quoteSourceStyle``).
		.descendants("blockquote:has(+ \(class: ProseStyles.quoteSource))") {
			$0.margin(.bottom, .zero)
		}
		// The look of a picture of a window, like the screenshots of a guide, so a white image has an edge on the white page. App icons (`icon.png`) have their own shape and shadow.
		.descendants("img:not([src$='/icon.png'])") {
			$0.windowSurface()
		}
		.descendants("figcaption") {
			$0
				.margin(.top, .em(1))
				.font(size: smallTextSize, lineHeight: 1.5)
				.color(.secondaryText)
		}
		.combined(with: inlineCode)
		// Strong text and code in links, quotes, headings, and table headers have the color of the text around them.
		.descendants(":is(a, blockquote, h1, h2, h3, h4, h5, h6, th) :is(strong, code)") {
			$0.inherits(.color)
		}
		// Code that is not a `CodeBlock`, like in release notes.
		.descendants("pre") {
			$0.codeSurface()
		}
		// The code in a code block has the font of the block, not of inline code, and no fill.
		.descendants("pre code") {
			$0
				.padding(.zero)
				.background(.transparent)
				.inheritsFont()
				.inherits(.color)
		}

	/**
	Inline code, in prose and in other text with Markdown, like the introduction of an app hero. Code is not hyphenated, also in a text that breaks long words, as a hyphen would change it. A faint fill shows the code, not a heavier weight, so a sentence or a table with much code is not a wall of bold text. Code in a link has the color of the link.
	*/
	static let inlineCode = Style()
		.descendants("code") {
			$0
				.font(size: smallTextSize)
				// Little space at the sides, so a comma or a period right after the code does not look like it has a space before it.
				.padding(vertical: .em(0.125), horizontal: .em(0.2))
				.cornerRadius(.smallRadius)
				// Code that wraps over two lines has one fill, which the line break cuts, so the pieces of a long URL in a table do not become pills of their own.
				.background(.black.opacity(0.05), dark: .white.opacity(0.09))
				.color(.primaryText)
				.hyphenation(false)
		}
		.descendants("a code") {
			$0.inherits(.color)
		}

	/**
	Spacing between blocks, after the element rules so it wins.
	*/
	static let spacing = Style()
		// Also after a line break that follows a heading, which takes no space.
		.descendants(":is(hr, h2, h3, h4, h5, h6) + *, :is(h2, h3, h4, h5, h6) + br + *") {
			$0.margin(.top, .zero)
		}
		// The first heading below chips to the sections, like on the general FAQ, has the space between the parts of a page instead of the space of a new section, like the first section below the chips of the guides, so the chips read as the contents of the sections below them.
		.descendants("\(class: ChipNavigation.Styles.root) + h2, \(class: ChipNavigation.Styles.root) + section > h2:first-child") {
			$0.margin(.top, .rootEm(2.5))
		}
		// Low specificity, so a block that sets its own margin, like an alert, keeps it.
		.children(":where(:first-child)") {
			$0.margin(.top, .zero)
		}
		.children(":where(:last-child)") {
			$0.margin(.bottom, .zero)
		}
		// Also the last block of the last section, like a list, as its margin goes through the section, so the page ends with the same space above the footer as other pages.
		.children(":where(section:last-child)") {
			$0.children(":where(:last-child)") {
				$0.margin(.bottom, .zero)
			}
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
		.directlyAfter(ProseStyles.listSubtitle.selector) {
			$0
				.margin(.top, .rootEm(0.5))
				.font(.extraSmall)
		}

	/**
	A list where each item is code with a `:: ` line below it, like the URL scheme of an app (``SiteKit/MarkdownElement/commandList``). It is a reference, so it has no bullets and no indent, and the code starts at the edge of the text, which gives a long URL more room on a phone. The items have a little more space between them, as each has two lines. The features of an app, which start with text, keep their bullets.
	*/
	static let commandListStyle = Style()
		.padding(.leading, .zero)
		.children("li") {
			$0
				.display(.block)
				.padding(.leading, .zero)
				.margin(vertical: .em(0.75), horizontal: .zero)
		}

	/**
	A paragraph that only has bold text, like `**Highlights**` or `**More features**`, which works as a label for the list or text below it. It has slightly more space above than the space between paragraphs, so it reads as the start of a new group, and not as the end of the text above. The space below stays, so the label stays with its content. The renderer only gives this class to a paragraph that has nothing but bold text and does not end with a period (``Markdown/Paragraph/isBoldLabel``), so a line like `**macOS:** Click …` and a bold sentence keep the normal space. This is intentional.
	*/
	static let boldLabelStyle = Style()
		// Not as the first block, which has no space above, and not below a heading or a rule, which has its own space below.
		.nested("&:not(:first-child, :is(hr, h1, h2, h3, h4, h5, h6, br) + &)") {
			$0.margin(.top, .em(1.5))
		}

	/**
	A paragraph that only has italic text, like `*Requires macOS 26 or later*` (``SiteKit/MarkdownElement/sideNote``): a side note in the small, secondary text of the details of a list item, not in italics, as italics are hard to read for more than a few words, and the note then reads as a note. The Markdown keeps the italics, so the Markdown copy does not change.
	*/
	static let sideNoteStyle = Style()
		.listDetailText()
		// Small text in the full width of prose has lines that are too long to read, so a side note keeps a line of about 75 characters.
		.frame(maxWidth: .em(36))
		.children("em") {
			$0.italic(false)
		}

	/**
	The source of the block quote above it, like “— Darius Foroux” (``SiteKit/MarkdownElement/quoteSource``), in the small text of the source of a press quote (``QuoteFigure``), and with the indent of the text of the quote: its padding (1em of the 18px text) and its line.
	*/
	static let quoteSourceStyle = Style()
		.font(.footnote, weight: .medium)
		.color(.secondaryText)
		.margin(.top, .rootEm(0.75))
		.padding(.leading, .rootEm(1.375))

	/**
	A heading that starts a group and the blocks below it (``SiteKit/MarkdownElement/headingGroup``), like a group of the features of Supercharge that the chips above the list link to. The title of the group stays below the header of the site while its blocks scroll, like the topics of the guides, so a visitor in the middle of a long list knows which group a row is in. The section stops it at the end of its group, so the title of the next group replaces it.
	*/
	static let headingGroupStyle = Style()
		.children(":first-child") {
			$0.stickySectionTitle()
		}

	/**
	An item of a menu path, like “General ›” in “System Settings › General › Date & Time”, which goes to the next line as a whole, so a line breaks only after an arrow, not inside the name of an item. An item that is wider than the column still wraps inside. A quote at its start does not hang outside it.
	*/
	static let menuPathItemStyle = Style()
		.display(.inlineBlock)
		.frame(maxWidth: .percent(100))
		.hangingPunctuation([])

	/**
	The arrow between the items of a menu path, in the color of secondary text, so the levels are easy to see.
	*/
	static let menuPathSeparatorStyle = Style()
		.color(.secondaryText)

	/**
	A word with a hyphen in a heading or a title, like “To-Do” (``SiteKit/MarkdownElement/hyphenatedWord``), which stays on one line.
	*/
	static let hyphenatedWordStyle = Style()
		.textWrap(.nowrap)

	/**
	A link that is a small tag, like “Guide ›” for `<guide:find-screenshots-mac>` after a feature (``SiteKit/MarkdownElement/linkTag``): a quiet pill in the color of secondary text, so the link reads as a side note, not as a part of the feature, and a list with many of them stays calm. It is an inline block, so “Guide ›” stays on one line, and it is a little above the baseline, so it is in the middle of the capital letters. It has one size, like a chip, also in the smaller text of a nested list and in the larger text of an introduction. The space around it is in `em`, so it follows that size.
	*/
	static let linkTagStyle = Style()
		.display(.inlineBlock)
		.font(.footnote)
		.fontWeight(.medium)
		.padding(vertical: .em(0.05), horizontal: .em(0.65))
		.margin(.leading, .em(0.25))
		.verticalAlign(.em(0.165))
		.cornerRadius(.capsule)
		.color(.secondaryText)
		.background(.card)
		.noUnderline()
		.hoverFill(.cardHover, color: .primaryText)
		.after {
			$0.content(" ›", alternativeText: "")
		}
		// A tag that goes to another site, like “Apple ↗” for the instructions of Apple (`SourceSite`), has an arrow that points out of the page.
		.nested("&[href^='https:']") {
			$0.after {
				$0.content(" ↗", alternativeText: "")
			}
		}

	/**
	Blog posts: colored links, optimized legibility, and a fainter fill of code in headings. The hanging punctuation is in ``typography``, for all prose.
	*/
	static let articleStyle = Style()
		// Ligatures and kerning are on by default.
		.declaration(raw: .textRendering, "optimizeLegibility")
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
		// Code in a heading has a fainter fill than in the text, so a question like “Why did `Buffer` exist?” reads as one title, not as a sentence with buttons in it. The fill stays, so the code is still set off. Only in posts, as their headings are titles, while on app pages the fill marks a menu item or a glyph in a question, like “…”.
		.descendants(":is(h2, h3, h4) code") {
			$0.background(.black.opacity(0.03), dark: .white.opacity(0.05))
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
	A footnote or an inline note in a popover, above the reference that opened it, or below when there is no space above. The margins at its sides are the rest of its largest width on a phone, so a note that is as wide as the screen has the same space at both sides.
	*/
	static let popoverStyle = Style()
		.positionArea(.top)
		.positionTryFallbacks(.flipBlock)
		.inset(.auto)
		.margin(vertical: .pixels(8), horizontal: .rootEm(1))
		.frame(maxWidth: .length(.min(.rootEm(24), .viewportWidth(100) - .rootEm(2))))
		.padding(vertical: .rootEm(0.75), horizontal: .rootEm(1))
		.popoverSurface()
		.font(.callout)
		.textAlign(.leading)
		.color(.bodyText)
		.trimmingChildMargins()
}

extension Style {
	/**
	An image in prose that does not look like an image of prose, like an app icon or a logo in a card: without the margins, the rounded corners, and the shadow.
	*/
	func plainImage() -> Self {
		margin(.zero)
			.cornerRadius(.zero)
			.shadow([])
	}

	/**
	A list in prose that does not look like a list of prose, like the details below a card or a step: without the space of a list, and with items that are blocks, so they have no bullets. Put it first, so the styles after it win.
	*/
	func plainList() -> Self {
		margin(.zero)
			.padding(.zero)
			.children("li") {
				$0
					.display(.block)
					.margin(.zero)
					.padding(.zero)
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
	The space of a block in prose above and below the element (``ProseStyles/blockSpacing``), like code, an alert, or a card, so it is set off from the text. Right below a heading, a bold label (``ProseStyles/boldLabelStyle``), or a paragraph that ends with a colon (``SiteKit/MarkdownElement/leadIn``), it has only the space below them, like the text, so “Apple’s instructions:” is as close to its steps as to a list.
	*/
	func proseBlockMargin() -> Self {
		margin(vertical: .length(ProseStyles.blockSpacing), horizontal: .zero)
			// Right below a heading, a bold label, or a paragraph that ends with a colon, the space of the heading or the paragraph, like the text. Here, and not only in ``ProseStyles/spacing``, as the margin of a component, like steps or cards, wins over the rules of the prose.
			.directlyAfter("h2, h3, h4, h5, h6, \(ProseStyles.boldLabel.selector), \(ProseStyles.leadIn.selector)") {
				$0.margin(.top, .zero)
			}
			// In a list item, the paragraph has only the space of list items below it, so the block below “Run this command:” of a step has the space of a paragraph above it, like below a paragraph that ends with a colon outside a list. More specific than the rule above, so it wins.
			.directlyAfter("li > \(ProseStyles.leadIn.selector)") {
				$0.margin(.top, .em(1))
			}
	}

	/**
	A card that is set off from the text of prose, like a quick answer or a trial, with the space of a block around it. Its text starts where the paragraphs start (``widerThanProse()``).
	*/
	func proseCard() -> Self {
		proseBlockMargin()
			.padding(vertical: .rootEm(1.75), horizontal: .boxInset)
			.widerThanProse()
			.cardSurface(isInteractive: false)
			.trimmingChildMargins()
			// No space below the last card, like the last block of prose (``ProseStyles/spacing``), which has no specificity, so the margin of the card would win, and add to the space at the end of a page, like the last tiny app.
			.lastChild {
				$0.margin(.bottom, .zero)
			}
	}
}
