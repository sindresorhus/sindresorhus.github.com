import Foundation
import Testing
@testable import SiteKit

@Suite
struct MarkdownTests {
	@Test
	func `custom heading IDs are used and removed from the text`() {
		let document = MarkdownDocument(parsing: "## Hello World {#custom-id}\n\nText")
		#expect(document.headings == [Heading(level: 2, text: "Hello World", id: "custom-id")])
		#expect(document.html.contains(#"<h2 id="custom-id">Hello World</h2>"#))
	}

	@Test
	func `custom heading IDs do not affect generated slugs`() {
		let document = MarkdownDocument(parsing: "## First {#same}\n\n## Same\n\n## Same")
		#expect(document.headings.map(\.id) == ["same", "same", "same-1"])
	}

	@Test
	func `heading slug collisions match GitHub`() {
		let document = MarkdownDocument(parsing: "## Same\n## Same\n## Same-1\n## Same")
		#expect(document.headings.map(\.id) == ["same", "same-1", "same-1-1", "same-2"])
	}

	@Test
	func `heading slugs match GitHub punctuation and Unicode rules`() {
		#expect(HeadingSlugger.slug("Can you support SwiftUI.Color / UIColor / NSColor formats?") == "can-you-support-swiftuicolor--uicolor--nscolor-formats")
		#expect(HeadingSlugger.slug("🦄 Sponsor $1000/month") == "-sponsor-1000month")
		#expect(HeadingSlugger.slug("hidden the … menu item") == "hidden-the--menu-item")
		#expect(HeadingSlugger.slug("café") == "café")
		#expect(HeadingSlugger.slug("Why inspect a .DS_Store file?") == "why-inspect-a-ds_store-file")
		#expect(HeadingSlugger.slug("What does the ⓘ symbol mean?") == "what-does-the-ⓘ-symbol-mean")
		#expect(HeadingSlugger.slug("Donate ❤️") == "donate-\u{FE0F}")
	}

	@Test
	func `heading slugs use code text but not image descriptions`() {
		let document = MarkdownDocument(parsing: "## Use `npx` ![icon](icon.png) now")
		#expect(document.headings.first?.id == "use-npx--now")
	}

	@Test
	func `headings inside HTML comments are ignored`() {
		let document = MarkdownDocument(parsing: """
		## Visible

		<!--
		## Hidden
		-->

		## Also Visible
		""")

		#expect(document.headings.map(\.text) == ["Visible", "Also Visible"])
	}

	@Test
	func `heading directives attach to the heading above`() {
		let document = MarkdownDocument(parsing: """
		### Test {#test}
		<!-- @faq.keywords launch open -->
		<!-- @faq.platforms macOS -->

		### Other {#other}
		<!-- A regular comment -->
		<!-- @faq.keywords ignored -->
		""")

		#expect(document.headings[0].directives["faq.keywords"] == ["launch", "open"])
		#expect(document.headings[0].directives["faq.platforms"] == ["macOS"])
		#expect(document.headings[1].directives["faq.keywords"] == [])
	}

	@Test
	func `introduction is the plain text of the first paragraph`() {
		#expect(MarkdownDocument(parsing: "Use [Dato](/dato) to see the **date** with `npx`.\n\n## Heading").introduction == "Use Dato to see the date with npx.")
		#expect(MarkdownDocument(parsing: "Instant access to your Mac's camera feed.").introduction == "Instant access to your Mac's camera feed.")
		#expect(MarkdownDocument(parsing: "A viewer for .DS_Store files.").introduction == "A viewer for .DS_Store files.")
		#expect(MarkdownDocument(parsing: "Line one\nline two.").introduction == "Line one line two.")
		#expect(MarkdownDocument(parsing: "With a note[^1].\n\n[^1]: The note.").introduction == "With a note.")
	}

	@Test
	func `introduction skips only HTML comments`() {
		#expect(MarkdownDocument(parsing: "<!-- Hidden. -->\n\nVisible.").introduction == "Visible.")
		#expect(MarkdownDocument(parsing: "<br>\n\nParagraph.").introduction == nil)
		#expect(MarkdownDocument(parsing: "## Heading\n\nParagraph.").introduction == nil)
		#expect(MarkdownDocument(parsing: "![Screenshot](screenshot.png)\n\nParagraph.").introduction == nil)
	}

	@Test
	func `alerts keep all paragraphs and uppercase labels`() {
		let document = MarkdownDocument(parsing: """
		> [!IMPORTANT]
		> First paragraph.
		>
		> Second paragraph.
		""")

		#expect(document.html.contains(#"<div class="markdown-alert markdown-alert-important" dir="auto"><p class="markdown-alert-title" dir="auto"><svg class="octicon""#))
		#expect(document.html.contains("</svg>IMPORTANT</p><p>First paragraph.</p>"))
		#expect(document.html.contains("<p>Second paragraph.</p>"))
		#expect(!document.html.contains("<blockquote>"))
	}

	@Test
	func `regular block quotes stay block quotes`() {
		#expect(MarkdownDocument(parsing: "> Just a quote.").html == "<blockquote>\n<p>Just a quote.</p>\n</blockquote>\n")
	}

	@Test
	func `footnotes are numbered by first reference`() {
		let document = MarkdownDocument(parsing: """
		First[^second], then[^first], again[^second].

		[^first]: First definition.
		[^second]: Second definition.
		""")

		#expect(document.html.contains(##"<sup><a href="#user-content-fn-second" id="user-content-fnref-second" data-footnote-ref="" aria-describedby="footnote-label">1</a></sup>"##))
		#expect(document.html.contains(##"<sup><a href="#user-content-fn-first" id="user-content-fnref-first" data-footnote-ref="" aria-describedby="footnote-label">2</a></sup>"##))
		#expect(document.html.contains(##"id="user-content-fnref-second-2""##))
		#expect(document.html.contains(#"<li id="user-content-fn-second"><p>Second definition. "#))
		#expect(document.html.contains(#"aria-label="Back to reference 1-2""#))
		#expect(document.headings.last == Heading(level: 2, text: "Footnotes", id: "footnote-label"))
	}

	@Test
	func `footnotes can open in popovers next to their references`() {
		let document = MarkdownDocument(parsing: """
		Text[^note] and again[^note].

		[^note]: The note.
		""", options: .init(showsFootnotesInPopovers: true))

		#expect(document.html.contains(##"<sup><button type="button" popovertarget="user-content-fn-popover-note" id="user-content-fnref-note" data-footnote-ref="" aria-label="Footnote 1" class="footnote-reference">1</button></sup>"##))
		#expect(document.html.contains(##"id="user-content-fnref-note-2""##))
		#expect(document.html.components(separatedBy: "<div popover").count == 2)
		#expect(document.html.contains(#"<div popover id="user-content-fn-popover-note" role="note" class="footnote-popover"><p>The note.</p>"#))
		// The list at the end stays, for printing and the links back.
		#expect(document.html.contains(#"<li id="user-content-fn-note">"#))
	}

	@Test
	func `code blocks can get a bar with the language and a copy button`() {
		let html = MarkdownDocument(parsing: "```sh\nnpm test\n```\n\n```\nplain\n```", options: .init(addsCopyButtons: true)).html

		#expect(html.contains(#"<div class="code-block" data-code-block=""><div class="code-block-bar"><span class="code-block-language">sh</span><button type="button" class="copy-button" data-copy-code=""><span>Copy</span><span>Copied</span></button></div><pre tabindex="0"><code class="language-sh">npm test\#n</code></pre></div>"#))
		// Without a language, there is only the button.
		#expect(html.contains(#"<div class="code-block-bar"><button"#))
	}

	@Test
	func `footnote references without a definition and unused definitions are problems`() {
		let document = MarkdownDocument(parsing: "Text[^missing].\n\n[^unused]: Never referenced.")

		#expect(document.problems.map(\.message) == [
			"The footnote `[^missing]` has no definition, like `[^missing]: The note.` If it is not a footnote, write it as code.",
			"The footnote `[^unused]` is defined but not used.",
		])
		#expect(document.html.contains("Text[^missing]."))
	}

	@Test
	func `footnotes in code blocks are left alone`() {
		let document = MarkdownDocument(parsing: """
		Text[^1].

		```
		array[^1]
		[^1]: Not a definition.
		```

		[^1]: The definition.
		""")

		#expect(document.html.contains("array[^1]\n[^1]: Not a definition."))
		#expect(document.html.contains("The definition."))
		#expect(document.html.components(separatedBy: "data-footnote-ref").count == 2)
	}

	@Test
	func `tight lists render without paragraphs`() {
		let html = MarkdownDocument(parsing: "- First\n- Second\n  - Nested").html
		#expect(html.contains("<li>First</li>"))
		#expect(html.contains("<li>Second\n<ul>"))
		#expect(html.contains("<li>Nested</li>"))
		#expect(!html.contains("<p>"))
	}

	@Test
	func `loose lists render with paragraphs`() {
		let html = MarkdownDocument(parsing: "- First\n\n- Second").html
		#expect(html.contains("<li>\n<p>First</p>\n</li>"))
		#expect(html.contains("<li>\n<p>Second</p>\n</li>"))
	}

	@Test
	func `lists with Windows line endings stay tight`() {
		let html = MarkdownDocument(parsing: "- First\\\r\n  Description\r\n- Second\\\r\n  Description", style: .releaseNotes).html
		#expect(!html.contains("<p>"))
	}

	@Test
	func `keyboard shortcuts are split into keys`() {
		let html = MarkdownDocument(parsing: "<kbd>Command+Shift+C</kbd>, <kbd>Command+</kbd>, and <kbd>+</kbd>").html
		#expect(html.contains(#"<kbd>Command</kbd><span class="kbd-sep" aria-hidden="true">+</span><kbd>Shift</kbd><span class="kbd-sep" aria-hidden="true">+</span><kbd>C</kbd>"#))
		#expect(html.contains(#"<kbd>Command</kbd><span class="kbd-sep" aria-hidden="true">+</span><kbd>+</kbd>"#))
		#expect(html.contains(", and <kbd>+</kbd>"))
	}

	@Test
	func `a plus right after a separator is the plus key`() {
		let html = MarkdownDocument(parsing: "<kbd>Cmd++</kbd>").html
		#expect(html.contains(#"<kbd>Cmd</kbd><span class="kbd-sep" aria-hidden="true">+</span><kbd>+</kbd>"#))
		#expect(!html.contains("<kbd></kbd>"))
	}

	@Test
	func `bare URLs are not linked inside links`() {
		let rawLink = MarkdownDocument(parsing: #"<a href="/x">see https://example.com</a>"#).html
		#expect(rawLink.contains(#"<a href="/x">see https://example.com</a>"#))

		let emphasisInLink = MarkdownDocument(parsing: "[*https://example.com*](/x) and https://example.org").html
		#expect(emphasisInLink.contains(#"<a href="/x"><em>https://example.com</em></a>"#))
		#expect(emphasisInLink.contains(#"and <a href="https://example.org">https://example.org</a>"#))
	}

	@Test
	func `bare URLs keep balanced closing brackets`() {
		let html = MarkdownDocument(parsing: "See https://en.wikipedia.org/wiki/Swift_(programming_language). (Or https://example.com/a)").html
		#expect(html.contains(#"<a href="https://en.wikipedia.org/wiki/Swift_(programming_language)">https://en.wikipedia.org/wiki/Swift_(programming_language)</a>."#))
		#expect(html.contains(#"(Or <a href="https://example.com/a">https://example.com/a</a>)"#))
	}

	@Test
	func `file names with an at sign are not emails`() {
		let html = MarkdownDocument(parsing: "Use icon@2x.png or write to hi@example.io.", style: .releaseNotes).html
		#expect(html.contains("Use icon@2x.png or"))
		#expect(html.contains(#"<a href="mailto:hi@example.io">hi@example.io</a>."#))
	}

	@Test
	func `HTML comments are not published`() {
		let html = MarkdownDocument(parsing: """
		## Heading {#heading}
		<!-- @faq.keywords open -->

		Text <!-- inline note --> here.

		<!--
		Draft paragraph.
		-->

		<div>Kept</div><!-- trailing -->
		""").html

		#expect(!html.contains("<!--"))
		#expect(html.contains("<p>Text  here.</p>"))
		#expect(html.contains("<div>Kept</div>"))
	}

	@Test
	func `release notes link bare URLs and emails without other extensions`() {
		let document = MarkdownDocument(parsing: "## Fixes\n\nContact support@example.com or https://example.com/help. <kbd>Command+Delete</kbd>", style: .releaseNotes)
		#expect(document.html.contains("<h2>Fixes</h2>"))
		#expect(document.html.contains(#"<a href="mailto:support@example.com">support@example.com</a>"#))
		#expect(document.html.contains(#"<a href="https://example.com/help">https://example.com/help</a>."#))
		#expect(document.html.contains("<kbd>Command+Delete</kbd>"))
		#expect(document.headings.isEmpty)
	}

	@Test
	func `site content links bare URLs but not URLs in links or code`() {
		let html = MarkdownDocument(parsing: "See https://example.com/a. [Link https://example.com/b](https://example.com/c) `https://example.com/d`").html
		#expect(html.contains(#"See <a href="https://example.com/a">https://example.com/a</a>."#))
		#expect(html.contains(#"<a href="https://example.com/c">Link https://example.com/b</a>"#))
		#expect(html.contains("<code>https://example.com/d</code>"))
	}

	@Test
	func `tables keep alignment`() {
		let html = MarkdownDocument(parsing: "| A | B |\n|:--|--:|\n| 1 | 2 |").html
		#expect(html.contains(#"<th align="left">A</th>"#))
		#expect(html.contains(#"<td align="right">2</td>"#))
	}

	@Test
	func `footnote references in code stay as they are`() {
		let html = MarkdownDocument(parsing: "Text[^1] and `array[^1]`.\n\n[^1]: The note.").html
		#expect(html.contains("<code>array[^1]</code>"))
		#expect(html.components(separatedBy: "data-footnote-ref").count == 2)
	}

	@Test
	func `headings of a level after a heading become collapsible sections`() {
		let options = MarkdownDocument.Options(collapsibleSections: .init(level: 4, startHeadingID: "faq", name: "faq", moreLink: .init(title: "More", url: "/faq")), addsHeadingAnchors: true)
		let document = MarkdownDocument(parsing: """
		#### Before

		## FAQ {#faq}

		#### First {#first}
		<!-- @faq.keywords one -->

		Answer.

		#### Second

		More.

		## After

		#### Not a section
		""", options: options)

		#expect(document.html.contains("<div class=\"collapsible-sections\">\n<details id=\"first\" name=\"faq\" class=\"collapsible-section\"><summary class=\"collapsible-summary\"><span class=\"collapsible-title\">First</span><span class=\"collapsible-chevron\" aria-hidden=\"true\"></span><a href=\"#first\" class=\"heading-anchor\""))
		#expect(document.html.contains("<div class=\"collapsible-content\">\n<p>Answer.</p>\n</div></details>"))
		#expect(document.html.contains(#"<details id="second" name="faq""#))
		#expect(document.html.contains("<a href=\"/faq\" class=\"collapsible-more-link\">More</a>\n</div>\n<h2 id=\"after\" class=\"anchored-heading\">"))
		#expect(document.html.contains(#"<h4 id="before" class="anchored-heading">Before<a"#))
		#expect(document.html.contains(#"<h4 id="not-a-section" class="anchored-heading">Not a section<a"#))
		#expect(document.headings.map(\.id) == ["before", "faq", "first", "second", "after", "not-a-section"])
		#expect(document.headings[2].directives["faq.keywords"] == ["one"])
	}

	@Test
	func `a theme gives the created markup its classes`() {
		let theme = MarkdownTheme { element in
			element == .alert(.tip) ? "tip" : "x"
		}

		let html = MarkdownDocument(parsing: "> [!TIP]\n> Text <kbd>A+B</kbd>", options: .init(theme: theme)).html
		#expect(html.contains(#"<div class="tip" dir="auto"><p class="x" dir="auto"><svg class="x""#))
		#expect(html.contains(#"<span class="x" aria-hidden="true">+</span>"#))
	}

	@Test
	func `unknown and misplaced heading directives are problems with lines`() {
		let document = MarkdownDocument(parsing: """
		## Question {#question}
		<!-- @faq.keyword open -->

		Text.

		<!-- @faq.keywords misplaced -->
		<!-- A regular comment -->
		""", options: .init(headingDirectives: ["faq.keywords"]))

		#expect(document.problems.map(\.line) == [2, 6])
		#expect(document.problems[0].message.contains("Unknown directive `@faq.keyword`"))
		#expect(document.problems[1].message.contains("directly below a heading"))
	}

	@Test
	func `images need a description`() {
		let document = MarkdownDocument(parsing: "Text.\n\n![](/image.png)\n\n![A cat](/cat.png)", options: .init(imageSize: { _ in (width: 10, height: 20) }))
		#expect(document.problems.map(\.line) == [3])
		#expect(document.html.contains(#"<img src="/cat.png" alt="A cat" width="10" height="20">"#))
	}

	@Test
	func `plus signs around keys make a keyboard shortcut`() {
		let html = MarkdownDocument(parsing: "Press ++Option+◀++, not C++ and C++.").html
		#expect(html.contains(#"<kbd>Option</kbd><span class="kbd-sep" aria-hidden="true">+</span><kbd>◀</kbd>"#))
		#expect(html.contains("not C++ and C++."))
	}

	@Test
	func `links can be resolved and keep their lines`() {
		let document = MarkdownDocument(parsing: "Intro.\n\nSee [Dato](dato.md) and [broken](nope.md).", options: .init(resolveLink: { destination in
			guard destination != "nope.md" else {
				throw CocoaError(.fileNoSuchFile)
			}

			return destination == "dato.md" ? "/dato" : destination
		}))

		#expect(document.html.contains(#"<a href="/dato">Dato</a>"#))
		#expect(document.links.map(\.destination) == ["/dato", "nope.md"])
		#expect(document.links.map(\.line) == [3, 3])
		#expect(document.problems.count == 1)
	}

	@Test
	func `block directives and inline attributes render with the options`() {
		let options = MarkdownDocument.Options(
			inlineAttributes: { attributes, html in "<b data-a='\(attributes)'>\(html)</b>" },
			blockDirectives: ["Box": { arguments, html in "<section title=\"\(arguments["title"] ?? "")\">\(html)</section>" }]
		)

		let document = MarkdownDocument(parsing: """
		^[Mac](platform: "macOS") only.

		@Box(title: "Hi") {
		  Inside.
		}

		@Unknown {
		  Text.
		}
		""", options: options)

		#expect(document.html.contains(#"<b data-a='platform: "macOS"'>Mac</b> only."#))
		#expect(document.html.contains(#"<section title="Hi"><p>Inside.</p>"#))
		#expect(document.problems.map(\.line) == [7])
	}

	@Test
	func `list items get subtitles and descriptions from colon lines`() {
		let html = MarkdownDocument(parsing: """
		- Calculate Bearing
			:: Get the compass direction between *two* coordinates.

		- Get Active Browser Tab
			: Gets the URL and title
			:: Supports Safari.
		""").html

		#expect(html.contains("Calculate Bearing\n<span class=\"list-description\">Get the compass direction between <em>two</em> coordinates.</span>"))
		#expect(html.contains("Get Active Browser Tab\n<span class=\"list-subtitle\">Gets the URL and title</span>\n<span class=\"list-description\">Supports Safari.</span>"))
		#expect(MarkdownDocument(parsing: "Not a list\n: no subtitle").html == "<p>Not a list\n: no subtitle</p>\n")
	}
}

@Suite
struct MarkdownLinkTests {
	private static let options = MarkdownDocument.Options(resolveLink: { destination in
		destination.hasSuffix(".md") ? "/" + destination.dropLast(3) : destination
	})

	@Test
	func `links in the first paragraph of an alert are resolved and listed`() {
		let document = MarkdownDocument(parsing: "> [!NOTE]\n> See [the FAQ](faq.md).", options: Self.options)

		#expect(document.html.contains(#"<a href="/faq">the FAQ</a>"#))
		#expect(document.links.map(\.destination) == ["/faq"])
	}

	@Test
	func `links in footnote definitions are resolved and listed`() {
		var options = Self.options
		options.showsFootnotesInPopovers = true
		let document = MarkdownDocument(parsing: "Text[^note].\n\n[^note]: See [the FAQ](faq.md).", options: options)

		#expect(document.html.contains(#"<a href="/faq">the FAQ</a>"#))
		// Once, although the definition is in the list and in the popover.
		#expect(document.links.map(\.destination) == ["/faq"])
	}

	@Test
	func `links keep their title`() {
		#expect(MarkdownDocument(parsing: #"[Dato](/dato "Calendar app")"#).html.contains(#"<a href="/dato" title="Calendar app">Dato</a>"#))
	}
}

@Suite
struct EscapingTests {
	@Test
	func `a combining mark after a special character does not stop the escaping`() {
		let attack = "x\"\u{301} onerror=alert(1) <\u{301}b &\u{301}"
		let escaped = attack.escapedForHTML
		let escapedAmpersand = "&amp;\u{301}"

		// The scalars are checked, as `contains` compares whole characters, and a mark joins the character before it.
		#expect(!escaped.unicodeScalars.contains("\""))
		#expect(!escaped.unicodeScalars.contains("<"))
		#expect(escaped.contains(escapedAmpersand))

		let html = MarkdownDocument(parsing: "![a\"\u{301} onerror=alert(1) x](/i.png)").html
		#expect(html.contains("<img src=\"/i.png\" alt=\"a"))
		let scalars = Array(html.unicodeScalars)
		let hasRawQuoteWithMark = zip(scalars, scalars.dropFirst()).contains { $0 == "\"" && $1.value == 0x301 }
		#expect(!hasRawQuoteWithMark)
	}
}
