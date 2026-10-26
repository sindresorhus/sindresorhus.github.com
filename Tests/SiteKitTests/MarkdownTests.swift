import Foundation
import Markdown
import Testing
@testable import SiteKit

struct MarkdownTests {
	/**
	A cell that a span covers has no cell of its own, like in GitHub’s tables.
	*/
	@Test
	func `table cells that a span covers are not rendered`() {
		#expect(!MarkdownDocument(parsing: "| a | b |\n|---|---|\n| x ||").html.contains("<td></td>"))
		#expect(!MarkdownDocument(parsing: "| a | b |\n|---|---|\n| x | y |\n| ^ | z |").html.contains("<td></td>"))
	}

	/**
	Like on GitHub, the marker is alone on its line, and the alert has text, so a quote that starts with a marker is a quote.
	*/
	@Test
	func `an alert marker is alone on its line`() {
		#expect(MarkdownDocument(parsing: "> [!NOTE] is a marker").html.contains("<blockquote>"))
		#expect(MarkdownDocument(parsing: "> [!NOTE]").html.contains("<blockquote>"))
		#expect(!MarkdownDocument(parsing: "> [!NOTE]\\\n> Text").html.contains("<br>"))
		#expect(MarkdownDocument(parsing: "> [!NOTE]\n> Text").html.contains(#"class="alert alert-note""#))
		#expect(MarkdownDocument(parsing: "> [!NOTE]\n>\n> Text").html.contains(#"class="alert alert-note""#))
	}

	/**
	Code is shown as written, so a heading that ends in code like `` `{#id}` `` has no custom ID.
	*/
	@Test
	func `a heading that ends in inline code has no custom ID`() {
		let document = MarkdownDocument(parsing: "## Use `{#id}`")
		#expect(document.headings.map(\.id) == ["use-id"])
		#expect(document.html.contains(#"id="use-id""#))
		#expect(MarkdownDocument(parsing: "## Install {#setup}").headings.map(\.id) == ["setup"])
	}

	/**
	Smart punctuation makes `--` a dash, but a custom ID keeps its hyphens, like the slug of “Cut & Paste” that keeps the URL of a renamed heading.
	*/
	@Test
	func `a custom ID can have double hyphens`() {
		let document = MarkdownDocument(parsing: "## Copy and Paste {#cut--paste}\n\n## Other {#a---b}")
		#expect(document.headings.map(\.id) == ["cut--paste", "a---b"])
		#expect(document.headings.map(\.text) == ["Copy and Paste", "Other"])
		#expect(document.html.contains(#"<h2 id="cut--paste">Copy and Paste</h2>"#))
	}

	/**
	Code is shown as written, so footnote syntax in it, like `` `[^1]` ``, stays in the heading ID and the introduction.
	*/
	@Test
	func `footnote syntax in inline code stays in the plain text`() {
		#expect(MarkdownDocument(parsing: "## The `[^1]` syntax").headings.map(\.id) == ["the-1-syntax"])
		#expect(MarkdownDocument(parsing: "Write `[^1]` for a footnote.").introduction == "Write [^1] for a footnote.")
		#expect(MarkdownDocument(parsing: "A note[^1].\n\n[^1]: Text.").introduction == "A note.")
	}

	@Test
	func `alert markers are read in any case, like on GitHub`() {
		#expect(MarkdownDocument(parsing: "> [!Tip]\n> Text").html.contains(#"class="alert alert-tip""#))
		#expect(MarkdownDocument(parsing: "> [!note]\n> Text").html.contains(#"class="alert alert-note""#))
	}

	/**
	Smart punctuation turns `...` into `…` and `--` into `–`, which broke compare links in release notes.
	*/
	@Test
	func `a bare URL keeps its dots, hyphens, and quotes`() {
		let html = MarkdownDocument(parsing: "**Full Changelog**: https://github.com/sindresorhus/ky/compare/v1.0.0...v1.1.0", style: .releaseNotes).html
		#expect(html.contains(#"href="https://github.com/sindresorhus/ky/compare/v1.0.0...v1.1.0""#))
		#expect(html.contains(#">https://github.com/sindresorhus/ky/compare/v1.0.0...v1.1.0</a>"#))
		#expect(MarkdownDocument(parsing: "See https://example.com/a--b for more.").html.contains(#"href="https://example.com/a--b""#))
		#expect(MarkdownDocument(parsing: "See https://en.wikipedia.org/wiki/Hitchhiker's_Guide for more.").html.contains(#"href="https://en.wikipedia.org/wiki/Hitchhiker's_Guide""#))
	}

	@Test
	func `custom heading IDs are used and removed from the text`() {
		let document = MarkdownDocument(parsing: "## Hello World {#custom-id}\n\nText")
		#expect(document.headings.map(\.text) == ["Hello World"])
		#expect(document.headings.map(\.id) == ["custom-id"])
		#expect(document.headings.map(\.line) == [1])
		#expect(document.html.contains(#"<h2 id="custom-id">Hello World</h2>"#))
	}

	@Test
	func `inline HTML removes the paragraph only when there is one`() {
		#expect(MarkdownDocument(parsing: "Hello *world*").inlineHTML == "Hello <em>world</em>")
		#expect(MarkdownDocument(parsing: "First\n\nSecond").inlineHTML == "<p>First</p>\n<p>Second</p>")
		#expect(MarkdownDocument(parsing: #"First\#n\#n<p class="note">Second</p>"#).inlineHTML == #"<p>First</p>\#n<p class="note">Second</p>"#)
	}

	@Test
	func `tables are in a container that keyboard users can scroll`() {
		let document = MarkdownDocument(parsing: "| A | B |\n| --- | --- |\n| 1 | 2 |")
		#expect(document.html.hasPrefix(#"<div class="table-container" tabindex="0" role="region" aria-label="Table">"# + "\n<table>"))
		#expect(document.html.hasSuffix("</table>\n</div>\n"))
	}

	@Test
	func `tables in raw HTML are in the same container`() {
		let document = MarkdownDocument(parsing: "<table>\n<tr><td>A</td></tr>\n</table>")
		#expect(document.html.hasPrefix(#"<div class="table-container" tabindex="0" role="region" aria-label="Table">"# + "\n<table>"))
		#expect(document.html.hasSuffix("</table>\n</div>\n"))
	}

	@Test
	func `table regions are named after the heading above them, and each name is unique`() {
		let table = "| A |\n| --- |\n| 1 |"
		let document = MarkdownDocument(parsing: "\(table)\n\n## Keys & Shortcuts\n\n\(table)\n\n\(table)\n\n## Other\n\n<table>\n<tr><td>A</td></tr>\n</table>")
		let labels = document.html.matches(of: /role="region" aria-label="([^"]*)"/).map { String($0.1) }

		#expect(labels == ["Table", "Keys &amp; Shortcuts", "Keys &amp; Shortcuts (2)", "Other"])
	}

	@Test
	func `a table under a heading without text is named “Table”`() {
		let table = "| A |\n| --- |\n| 1 |"
		let document = MarkdownDocument(parsing: "\(table)\n\n## {#empty}\n\n\(table)")
		let labels = document.html.matches(of: /role="region" aria-label="([^"]*)"/).map { String($0.1) }

		#expect(labels == ["Table", "Table (2)"])
	}

	@Test
	func `custom heading IDs do not affect generated slugs, and a repeated ID is a problem`() throws {
		let document = MarkdownDocument(parsing: "## First {#same}\n\n## Same\n\n## Same")
		#expect(document.headings.map(\.id) == ["same", "same", "same-1"])
		#expect(document.problems.map(\.line) == [3])
		let reason = try #require(document.problems.first).reason
		#expect(reason.contains("`same`"))
	}

	@Test
	func `two headings with the same custom ID are a problem`() {
		let document = MarkdownDocument(parsing: "## First {#x}\n\n## Second {#x}\n\n## Third {#y}")
		#expect(document.headings.map(\.id) == ["x", "x", "y"])
		#expect(document.problems.map(\.line) == [3])
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
	func `heading directives attach to the heading above`() throws {
		let document = MarkdownDocument(parsing: """
		### Test {#test}
		<!-- @faq.keywords launch open -->
		<!-- @faq.platforms macOS -->
		<!-- @faq.general -->

		### Other {#other}
		<!-- A regular comment -->
		<!-- @faq.keywords ignored -->

		### Third
		<!-- @faq.general yes -->
		""", options: .init(headingDirectives: [Keywords.self, Platforms.self, General.self]))

		try #require(document.headings.count == 3)
		#expect(document.headings[0][Keywords.self] == ["launch", "open"])
		#expect(document.headings[0][Platforms.self] == ["macOS"])
		#expect(document.headings[0].contains(General.self))
		#expect(document.headings[1][Keywords.self] == nil)
		#expect(!document.headings[1].contains(General.self))
		#expect(!document.headings[2].contains(General.self))
		try #require(document.problems.map(\.line) == [8, 11])
		#expect(document.problems[1].reason == "The values of `@faq.general` are invalid: It is a flag, so it takes no values.")
	}

	/**
	The added markup has the lines of the other file, so it has no lines in this one, but its directives still apply.
	*/
	@Test
	func `markup that a rewrite adds from another file has no lines`() {
		let document = MarkdownDocument(parsing: "### Own {#own}\n\n[Own link](https://example.com/own)", options: .init(headingDirectives: [Keywords.self], rewrite: { document in
			let added = Document(parsing: "Text.\n\n### Added {#added}\n<!-- @faq.keywords launch -->\n<!-- @faq.unknown -->\n\n[Link](https://example.com)", file: URL(filePath: "/shared.md"), options: .init())
			return Document(Array(document.blockChildren) + Array(added.blockChildren.dropFirst()))
		}))

		#expect(document.headings.map(\.line) == [1, nil])
		#expect(document.headings[1][Keywords.self] == ["launch"])
		#expect(document.links.map(\.line) == [3, nil])
		#expect(document.problems.map(\.line) == [nil])
	}

	@Test
	func `a directive given twice for a heading is a problem`() throws {
		let document = MarkdownDocument(parsing: """
		### Test {#test}
		<!-- @faq.keywords launch open -->
		<!-- @faq.keywords start -->
		""", options: .init(headingDirectives: [Keywords.self]))

		try #require(document.headings.count == 1)
		#expect(document.headings[0][Keywords.self] == ["launch", "open"])
		#expect(document.problems.map(\.line) == [3])
		#expect(document.problems.first?.reason == "The heading already has `@faq.keywords`. Put all its values in one directive.")
	}

	@Test
	func `flag directives without a space before the end of the comment are read`() {
		let document = MarkdownDocument(parsing: """
		### First {#first}
		<!--@faq.general-->

		### Second {#second}
		<!-- @faq.general-->
		""", options: .init(headingDirectives: [General.self]))

		#expect(document.problems.isEmpty)
		#expect(document.headings.allSatisfy { $0.contains(General.self) })
	}

	@Test
	func `introduction is the plain text of the first paragraph`() {
		#expect(MarkdownDocument(parsing: "Use [Dato](/dato) to see the **date** with `npx`.\n\n## Heading").introduction == "Use Dato to see the date with npx.")
		#expect(MarkdownDocument(parsing: "Instant access to your Mac's camera feed.").introduction == "Instant access to your Mac's camera feed.")
		#expect(MarkdownDocument(parsing: "“Typographic” and \"straight\" quotes -- and dots...").introduction == "“Typographic” and \"straight\" quotes -- and dots...")
		#expect(MarkdownDocument(parsing: "A viewer for .DS_Store files.").introduction == "A viewer for .DS_Store files.")
		#expect(MarkdownDocument(parsing: "Line one\nline two.").introduction == "Line one line two.")
		#expect(MarkdownDocument(parsing: "With a note[^1].\n\n[^1]: The note.").introduction == "With a note.")
		#expect(MarkdownDocument(parsing: "With a note[^1].\n\n[^1]: Note.").introduction == "With a note.")
	}

	@Test
	func `introduction skips only HTML comments`() {
		#expect(MarkdownDocument(parsing: "<!-- Hidden. -->\n\nVisible.").introduction == "Visible.")
		#expect(MarkdownDocument(parsing: "<br>\n\nParagraph.").introduction == nil)
		#expect(MarkdownDocument(parsing: "## Heading\n\nParagraph.").introduction == nil)
		#expect(MarkdownDocument(parsing: "![Screenshot](screenshot.png)\n\nParagraph.").introduction == nil)
	}

	@Test
	func `the introduction can be separated from the rest of the HTML`() throws {
		let document = MarkdownDocument(parsing: "<!-- Hidden. -->\n\nUse [Dato](/dato) daily.\n\nSecond paragraph.")
		let separated = try #require(document.htmlSeparatingIntroduction)
		#expect(separated.introduction == #"Use <a href="/dato">Dato</a> daily."#)
		#expect(separated.remainder == "<p>Second paragraph.</p>\n")

		#expect(MarkdownDocument(parsing: "## Heading\n\nParagraph.").htmlSeparatingIntroduction == nil)
		#expect(MarkdownDocument(parsing: "![Screenshot](screenshot.png)\n\nParagraph.").htmlSeparatingIntroduction == nil)
	}

	@Test
	func `a document can be separated before a heading`() throws {
		let document = MarkdownDocument(parsing: "First.\n\n## Section\n\n`<h2 id=\"end\">`\n\n## End\n\nMore.")
		let separated = try #require(document.htmlSeparated(beforeHeading: "end"))
		#expect(separated.before.contains("Section"))
		// The heading in code is not a heading.
		#expect(separated.before.contains(#"<code translate="no">"#))
		#expect(separated.after.hasPrefix(#"<h2 id="end""#))
		#expect(separated.after.contains("More."))

		#expect(document.htmlSeparated(beforeHeading: "missing") == nil)
	}

	@Test
	func `a document can be separated before several headings, in their order`() throws {
		let document = MarkdownDocument(parsing: "First.\n\n## Middle\n\nSecond.\n\n## End\n\nThird.")
		let parts = try #require(document.htmlSeparated(beforeHeadings: ["middle", "end"]))
		try #require(parts.count == 3)
		#expect(parts[0].contains("First.") && !parts[0].contains("Second."))
		#expect(parts[1].hasPrefix(#"<h2 id="middle""#) && parts[1].contains("Second.") && !parts[1].contains("Third."))
		#expect(parts[2].hasPrefix(#"<h2 id="end""#) && parts[2].contains("Third."))

		#expect(document.htmlSeparated(beforeHeadings: ["end", "middle"]) == nil)
		#expect(document.htmlSeparated(beforeHeadings: ["middle", "missing"]) == nil)
	}

	@Test
	func `alerts keep all paragraphs and uppercase labels`() {
		let document = MarkdownDocument(parsing: """
		> [!IMPORTANT]
		> First paragraph.
		>
		> Second paragraph.
		""")

		#expect(document.html.contains(#"<div class="alert alert-important" dir="auto"><p class="alert-title" dir="auto"><svg class="alert-icon""#))
		#expect(document.html.contains("</svg>IMPORTANT</p><p>First paragraph.</p>"))
		#expect(document.html.contains("<p>Second paragraph.</p>"))
		#expect(!document.html.contains("<blockquote>"))
	}

	@Test
	func `regular block quotes stay block quotes`() {
		#expect(MarkdownDocument(parsing: "> Just a quote.").html == "<blockquote>\n<p>Just a quote.</p>\n</blockquote>\n")
	}

	@Test
	func `footnotes are numbered by first reference, and open their definitions in popovers at the end`() {
		let document = MarkdownDocument(parsing: """
		First[^second], then[^first], again[^second].

		[^first]: First definition.
		[^second]: Second definition.
		""")

		#expect(document.html == """
		<p>First<sup><button type="button" popovertarget="user-content-fn-1" class="footnote-reference" aria-label="Footnote 1">1</button></sup>, then<sup><button type="button" popovertarget="user-content-fn-2" class="footnote-reference" aria-label="Footnote 2">2</button></sup>, again<sup><button type="button" popovertarget="user-content-fn-1" class="footnote-reference" aria-label="Footnote 1">1</button></sup>.</p>
		<div popover id="user-content-fn-1" role="note" tabindex="-1" autofocus class="footnote-popover"><p>Second definition.</p>
		</div>
		<div popover id="user-content-fn-2" role="note" tabindex="-1" autofocus class="footnote-popover"><p>First definition.</p>
		</div>

		""")
		#expect(document.headings.isEmpty)
	}

	@Test
	func `code blocks are plain text, or what the code block renderer makes of the code and the language`() {
		let plain = MarkdownDocument(parsing: "```sh title\nls <a>\n```").html

		#expect(plain.contains(#"<pre tabindex="0"><code class="language-sh">ls &lt;a&gt;\#n</code></pre>"#))

		let rendered = MarkdownDocument(parsing: "```swift title\nlet a = 1\n```\n\n```\nplain\n```", options: .init(codeBlock: { code, language in
			"<x-code>\(language ?? "none"): \(code)</x-code>"
		})).html

		#expect(rendered.contains("<x-code>swift: let a = 1\n</x-code>"))
		#expect(rendered.contains("<x-code>none: plain\n</x-code>"))
	}

	@Test
	func `swift code is split into the parts that the parser of Swift classifies, with names by where they are, also when it is only a part of a declaration`() {
		let source = "@Frontmatter\nstruct Post {\n\tvar title = \"é😀\" // A comment.\n\tlet count: Int = 1\n}"
		let parts = source.swiftCodeParts

		#expect(parts.map(\.text).joined() == source)
		#expect(tokens(of: parts) == [
			"attribute @Frontmatter",
			"keyword struct",
			"type Post",
			"keyword var",
			"declaration title",
			"string \"é😀\"",
			"comment // A comment.",
			"keyword let",
			"declaration count",
			"type Int",
			"number 1",
		])
		// Names get their kind from where they are, like a member after a period, and a type when they start with an uppercase letter.
		#expect(tokens(of: "Style()\n\t.padding(.rootEm(0.5))\n\t.hover { $0.color(app.tint) }".swiftCodeParts) == [
			"type Style",
			"member padding",
			"member rootEm",
			"number 0.5",
			"member hover",
			"member color",
			"member tint",
		])

		// A freestanding macro has the color of an attached macro, with its `#`, and the parts of a key path are members.
		let macroAndKeyPath = "let url = #URL(\"https://a.com\")\nitems.map(\\.title)"
		#expect(macroAndKeyPath.swiftCodeParts.map(\.text).joined() == macroAndKeyPath)
		#expect(tokens(of: macroAndKeyPath.swiftCodeParts) == [
			"keyword let",
			"declaration url",
			"attribute #URL",
			"string \"https://a.com\"",
			"member map",
			"member title",
		])

		// A string with interpolation has no empty parts, and the detail of a modifier is a keyword.
		let multilineString = "private(set) var text = \"\"\"\n\tHello \\(name)\n\t\"\"\""
		#expect(multilineString.swiftCodeParts.map(\.text).joined() == multilineString)
		#expect(!multilineString.swiftCodeParts.contains { $0.text.isEmpty })
		#expect(tokens(of: multilineString.swiftCodeParts).prefix(3) == ["keyword private", "keyword set", "keyword var"])
	}

	@Test
	func `soml code is split into the parts that the lexer of SOML classifies, with the whitespace between them`() {
		let source = "# A comment.\nname: \"é😀\\t\"\n\"is enabled\": true\ntags: [1, 1h30m, 2026-09-19T14:00:00Z]\n"
		let parts = source.somlCodeParts

		#expect(parts.map(\.text).joined() == source)
		#expect(tokens(of: parts) == [
			"comment # A comment.",
			"declaration name",
			"string \"é😀",
			"string \\t",
			"string \"",
			"declaration \"is enabled\"",
			"keyword true",
			"declaration tags",
			"number 1",
			"number 1h30m",
			"number 2026-09-19T14:00:00Z",
		])
	}

	/**
	Like on GitHub, an unused definition is not shown. The parser leaves it out, so it is not a problem.
	*/
	@Test
	func `footnote references without a definition are problems`() {
		let document = MarkdownDocument(parsing: "Text[^missing].\n\n[^unused]: Never referenced.")

		#expect(document.problems.map(\.reason) == [
			"The footnote `[^missing]` has no definition, like `[^missing]: The note.` If it is not a footnote, write it as code. The parser reads the text between block directives on its own, so a definition after a block directive, like at the end of the file, is only for the footnotes after that directive. A definition inside a block directive is only for the footnotes in that directive.",
		])
		#expect(document.html.contains("Text[^missing]."))
		#expect(!document.html.contains("Never referenced."))
	}

	/**
	The parser reads the content of a block directive on its own, so a footnote and its definition must both be inside it or both outside. Limitation: the parser leaves out a definition without a reference, so the problem cannot say where the definition is.
	*/
	@Test
	func `a footnote and its definition in different block directives is a problem that says so`() throws {
		let inside = MarkdownDocument(parsing: "@Plain {\n  In[^a].\n}\n\n[^a]: Note.", options: plainDirectiveOptions)
		let outside = MarkdownDocument(parsing: "Out[^a].\n\n@Plain {\n  In.\n\n  [^a]: Note.\n}", options: plainDirectiveOptions)
		let both = MarkdownDocument(parsing: "@Plain {\n  In[^a].\n\n  [^a]: Note.\n}", options: plainDirectiveOptions)

		#expect(inside.problems.map(\.line) == [2])
		let insideReason = try #require(inside.problems.first).reason
		let outsideReason = try #require(outside.problems.first).reason
		#expect(insideReason.contains("inside the same directive"))
		#expect(outsideReason.contains("A definition inside a block directive"))
		#expect(both.problems.isEmpty)
		#expect(both.html.contains("footnote-reference"))
	}

	/**
	Limitation: the parser reads the text between block directives on its own, so a definition at the end of the file is not found for a footnote before a block directive. The problem says why.
	*/
	@Test
	func `a footnote before a block directive with its definition after it is a problem that says so`() throws {
		let after = MarkdownDocument(parsing: "Text[^a].\n\n@Plain {\n  In.\n}\n\n[^a]: Note.", options: plainDirectiveOptions)
		let before = MarkdownDocument(parsing: "Text[^a].\n\n[^a]: Note.\n\n@Plain {\n  In.\n}", options: plainDirectiveOptions)

		let reason = try #require(after.problems.first).reason
		#expect(reason.contains("a definition after a block directive"))
		#expect(before.problems.isEmpty)
		#expect(before.html.contains("footnote-reference"))
	}

	@Test
	func `a problem in a footnote has the line of the footnote`() {
		let document = MarkdownDocument(parsing: "Text[^1].\n\n[^1]: See ![](x.png).", firstLine: 10, options: .init())
		#expect(document.problems.map(\.line) == [12])
	}

	@Test
	func `a heading in a footnote is a problem with its line`() throws {
		let document = MarkdownDocument(parsing: "Text[^1].\n\n[^1]: Text.\n\n    ## Heading", firstLine: 10, options: .init())

		#expect(document.problems.map(\.line) == [14])
		let reason = try #require(document.problems.first).reason
		#expect(reason.contains("cannot have headings, like “Heading”"))
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
		#expect(document.html.components(separatedBy: "footnote-reference").count == 2)
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
		#expect(html.contains(#"<kbd>Command</kbd><span class="key-separator" aria-hidden="true">+</span><kbd>Shift</kbd><span class="key-separator" aria-hidden="true">+</span><kbd>C</kbd>"#))
		#expect(html.contains(#"<kbd>Command</kbd><span class="key-separator" aria-hidden="true">+</span><kbd>+</kbd>"#))
		#expect(html.contains(#", and <kbd translate="no">+</kbd>"#))
	}

	@Test
	func `kbd elements in raw HTML blocks are split into keys`() {
		let html = MarkdownDocument(parsing: "<div><kbd>Cmd+K</kbd> and <kbd>A</kbd></div>").html
		#expect(html.contains(#"<div><kbd class="keyboard-shortcut" translate="no"><kbd>Cmd</kbd><span class="key-separator" aria-hidden="true">+</span><kbd>K</kbd></kbd> and <kbd>A</kbd></div>"#))
	}

	@Test
	func `a plus right after a separator is the plus key`() {
		let html = MarkdownDocument(parsing: "<kbd>Cmd++</kbd>").html
		#expect(html.contains(#"<kbd>Cmd</kbd><span class="key-separator" aria-hidden="true">+</span><kbd>+</kbd>"#))
		#expect(!html.contains("<kbd></kbd>"))
	}

	@Test
	func `bare URLs are not linked inside links`() {
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
	func `bare URLs in quotes leave out the closing quote`() {
		let html = MarkdownDocument(parsing: "Go to \"https://example.com\" or 'https://example.org'.").html
		#expect(html.contains(#"“<a href="https://example.com">https://example.com</a>”"#))
		#expect(html.contains(#"‘<a href="https://example.org">https://example.org</a>’."#))
	}

	@Test
	func `emails are links`() {
		let html = MarkdownDocument(parsing: "Write to hi@example.io.", style: .releaseNotes).html
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
		#expect(html.contains(#"<code translate="no">https://example.com/d</code>"#))
	}

	@Test
	func `tables keep alignment`() {
		let html = MarkdownDocument(parsing: "| A | B |\n|:--|--:|\n| 1 | 2 |").html
		#expect(html.contains(#"<th align="left">A</th>"#))
		#expect(html.contains(#"<td align="right">2</td>"#))
		#expect(MarkdownDocument(parsing: "| A | B | C |\n|:--|:-:|--:|\n| x || z |").html.contains(#"<td align="left" colspan="2">x</td>"# + "\n" + #"<td align="right">z</td>"#))
	}

	@Test
	func `footnote references in code stay as they are`() {
		let html = MarkdownDocument(parsing: "Text[^1] and `array[^1]`.\n\n[^1]: The note.").html
		#expect(html.contains(#"<code translate="no">array[^1]</code>"#))
		#expect(html.components(separatedBy: "footnote-reference").count == 2)
	}

	@Test
	func `headings of a level after a heading become collapsible sections`() throws {
		let options = MarkdownDocument.Options(collapsibleSections: .init(level: 4, startHeadingID: "faq", name: "faq", moreLink: .init(title: "More", destination: .path("/faq"))), addsHeadingAnchors: true, headingDirectives: [Keywords.self])
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

		#expect(document.html.contains(##"<div class="collapsible-sections">\##n<div class="anchored-section"><a href="#first" class="heading-anchor""##))
		#expect(document.html.contains(#"</a><details id="first" name="faq" class="collapsible-section"><summary class="collapsible-summary"><h4 class="collapsible-title">First</h4><span class="collapsible-chevron" aria-hidden="true"></span></summary>"#))
		#expect(document.html.contains("<div class=\"collapsible-content\">\n<p>Answer.</p>\n</div></details></div>"))
		#expect(document.html.contains(#"<details id="second" name="faq""#))
		#expect(document.html.contains("<a href=\"/faq\" class=\"collapsible-more-link\">More</a>\n</div>\n<h2 id=\"after\" class=\"anchored-heading\" aria-label=\"After\">"))
		#expect(document.html.contains(#"<h4 id="before" class="anchored-heading" aria-label="Before">Before<a"#))
		#expect(document.html.contains(#"<h4 id="not-a-section" class="anchored-heading" aria-label="Not a section">Not a section<a"#))
		try #require(document.headings.map(\.id) == ["before", "faq", "first", "second", "after", "not-a-section"])
		#expect(document.headings[2][Keywords.self] == ["one"])
	}

	/**
	Screen readers list the links of a page by name, so each link to a section has the text of its heading. The link is inside a heading, so the heading is named by its text, without the name of the link.
	*/
	@Test
	func `links to sections are named after their headings, which are named by their text`() {
		let options = MarkdownDocument.Options(collapsibleSections: .init(level: 3, startHeadingID: "faq"), addsHeadingAnchors: true)
		let html = MarkdownDocument(parsing: "## Use `Cmd` & “Shift” {#faq}\n\n### Why?\n\nBecause.", options: options).html
		#expect(html.contains(##"<h2 id="faq" class="anchored-heading" aria-label="Use Cmd &amp; “Shift”">Use <code translate="no">Cmd</code> &amp; “Shift”<a href="#faq" class="heading-anchor" data-copy-link="" aria-label="Copy link to section: Use Cmd &amp; “Shift”">"##))
		#expect(html.contains(##"<a href="#why" class="heading-anchor" data-copy-link="" aria-label="Copy link to section: Why?">"##))
		#expect(html.contains(#"<h3 class="collapsible-title">Why?</h3>"#))
	}

	/**
	A link in the heading would be lost, so it is a problem, and the link belongs in the text below it.
	*/
	@Test
	func `the links of a collapsible section heading are plain text and a problem, as a summary cannot have links`() {
		let options = MarkdownDocument.Options(collapsibleSections: .init(level: 4, startHeadingID: "faq"))
		let document = MarkdownDocument(parsing: """
		## FAQ {#faq}

		#### Does it work with [Safari](https://apple.com/safari) and https://example.com?

		See [the guide](https://example.com/guide).
		""", options: options)

		#expect(document.html.contains(#"<h4 class="collapsible-title">Does it work with Safari and https://example.com?</h4>"#))
		#expect(document.html.contains(#"See <a href="https://example.com/guide">the guide</a>."#))
		#expect(document.problems.map(\.line) == [3])
	}

	/**
	A bare URL is only text in the heading, like before the parser linked bare URLs, so it is not a lost link.
	*/
	@Test
	func `a bare URL in a collapsible section heading is not a problem`() {
		let options = MarkdownDocument.Options(collapsibleSections: .init(level: 4, startHeadingID: "faq"))
		let document = MarkdownDocument(parsing: "## FAQ {#faq}\n\n#### Is https://example.com or hi@example.com ok?\n\nYes.", options: options)
		#expect(document.problems.isEmpty)
		#expect(document.html.contains(#"<h4 class="collapsible-title">Is https://example.com or hi@example.com ok?</h4>"#))
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
	func `unknown and misplaced heading directives are problems with lines`() throws {
		let document = MarkdownDocument(parsing: """
		## Question {#question}
		<!-- @faq.keyword open -->

		Text.

		<!-- @faq.keywords misplaced -->
		<!-- A regular comment -->

		## Other
		<!-- @faq.keywords a --><!-- @faq.keywords b -->
		""", options: .init(headingDirectives: [Keywords.self]))

		try #require(document.problems.map(\.line) == [2, 6, 10])
		#expect(document.problems[0].reason.contains("Unknown directive `@faq.keyword`"))
		#expect(document.problems[1].reason.contains("directly below a heading"))
		#expect(document.problems[2].reason.contains("on its own line"))
		try #require(document.headings.count == 2)
		#expect(document.headings[1][Keywords.self] == nil)
	}

	@Test
	func `lines after footnote definitions are lines in the source`() {
		let document = MarkdownDocument(parsing: """
		Text[^1][^2].

		[^1]: One
		    More.
		[^2]: Two

		## Later
		[Link](/a)

		![](/image.png)
		""")

		#expect(document.headings.first { $0.text == "Later" }?.line == 7)
		#expect(document.links.map(\.line) == [8, 10])
		#expect(document.problems.map(\.line) == [10])
	}

	@Test
	func `heading directive values are decoded strictly`() throws {
		enum Size: String, Decodable {
			case small
			case large
		}

		enum Sizes: HeadingDirective {
			static let name = "faq.sizes"
			typealias Value = [Size]
		}

		let document = MarkdownDocument(parsing: """
		## First
		<!-- @faq.sizes small large -->

		## Second
		<!-- @faq.sizes small huge -->

		## Third
		<!-- @faq.sizes -->
		""", options: .init(headingDirectives: [Sizes.self]))

		try #require(document.headings.count == 3)
		#expect(document.headings[0][Sizes.self] == [.small, .large])
		#expect(document.headings[1][Sizes.self] == nil)
		#expect(document.headings[2][Sizes.self] == [])
		#expect(document.problems.map(\.line) == [5])
		let reason = try #require(document.problems.first).reason
		#expect(reason.hasPrefix("The values of `@faq.sizes` are invalid:"))
	}

	@Test
	func `images need a description`() {
		let document = MarkdownDocument(parsing: "Text.\n\n![](/image.png)\n\n![A cat](/cat.png)", options: .init(imageSize: { _ in PixelSize(width: 10, height: 20) }))
		#expect(document.problems.map(\.line) == [3])
		#expect(document.html.contains(#"<img src="/cat.png" alt="A cat" width="10" height="20">"#))
	}

	@Test
	func `plus signs around keys make a keyboard shortcut`() {
		let html = MarkdownDocument(parsing: "Press ++Option+◀++, not C++ and C++.").html
		#expect(html.contains(#"<kbd>Option</kbd><span class="key-separator" aria-hidden="true">+</span><kbd>◀</kbd>"#))
		#expect(html.contains("not C++ and C++."))
	}

	@Test
	func `content can be separated before a level 2 heading`() throws {
		let content = MarkdownDocument(parsing: "Intro.\n\n## First {#first}\n\nText.").content
		let parts = try #require(content.separated(beforeHeading: "first"))

		#expect(parts.before.html == "<p>Intro.</p>\n")
		#expect(parts.after.html.hasPrefix(#"<h2 id="first""#))
		#expect(content.separated(beforeHeading: "missing") == nil)
	}

	@Test
	func `a shortcut of more than one key is a key combination, and its modifiers must be in the order of Apple`() {
		let document = MarkdownDocument(parsing: "Press ++Command+Shift+V++ or ++Q++.")

		#expect(document.html.contains(#"<kbd class="keyboard-shortcut" translate="no"><kbd>Command</kbd>"#))
		#expect(document.html.contains(#"or <kbd translate="no">Q</kbd>."#))
		#expect(document.problems.map(\.reason) == ["The modifiers of the keyboard shortcut `Command+Shift+V` must be in the order of Apple: Shift, Command, like `Shift+Command+V`."])
		#expect(MarkdownDocument(parsing: "Press ++Control+Option+Shift+Command+K++.").problems.isEmpty)
	}

	@Test
	func `long code can break at its dots and slashes, and short code is as it is`() {
		let html = MarkdownDocument(parsing: "Run `com.sindresorhus.Dato.joinedVideoCall` or `a.b`.").html

		#expect(html.contains(#"<code translate="no">com<wbr>.sindresorhus<wbr>.Dato<wbr>.joinedVideoCall</code>"#))
		#expect(html.contains(#"<code translate="no">a.b</code>"#))
	}

	@Test
	func `a shortcut of one key ends at its own plus signs, not at the next shortcut`() {
		let html = MarkdownDocument(parsing: "Press ++Q++ twice while holding ++Command++.").html
		#expect(html.contains(#"Press <kbd translate="no">Q</kbd> twice while holding <kbd translate="no">Command</kbd>."#))
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

	/**
	An empty ID is invalid HTML, and its anchor would link to the top of the page.
	*/
	@Test
	func `a heading without text has an ID`() {
		let document = MarkdownDocument(parsing: "## 🎉\n\n## 🎉")
		#expect(!document.html.contains(#"id="""#))
		#expect(document.headings.map(\.id) == ["section", "section-1"])
	}

	@Test
	func `a bare scheme without a host is not a link`() {
		#expect(MarkdownDocument(parsing: "Use http://.").html == "<p>Use http://.</p>\n")
		#expect(MarkdownDocument(parsing: "Use https://a.").html.contains(#"<a href="https://a">"#))
	}

	/**
	A directive belongs on its own line below the heading, so one in the heading line would silently do nothing.
	*/
	@Test
	func `a directive comment inside a line is a problem`() {
		#expect(MarkdownDocument(parsing: "### Question <!-- @faq.keywords open -->\n\nAnswer.").problems.map(\.line) == [1])
		#expect(MarkdownDocument(parsing: "Text <!-- a note --> more.").problems.isEmpty)
	}

	/**
	An unclosed comment would hide the rest of the page in the browser, including the footer of the site.
	*/
	@Test
	func `an unclosed HTML comment is a problem and is not published`() {
		let document = MarkdownDocument(parsing: "Text\n\n<!-- draft\n\nMore")
		#expect(!document.html.contains("<!--"))
		#expect(document.problems.map(\.line) == [3])
	}

	/**
	The references are read from the text after smart punctuation, but the definitions from the source.
	*/
	@Test
	func `a footnote label with quotes or dashes matches its definition`() {
		#expect(MarkdownDocument(parsing: "A[^it's].\n\n[^it's]: Note.").problems.isEmpty)
		#expect(MarkdownDocument(parsing: "A[^a--b].\n\n[^a--b]: Note.").problems.isEmpty)
	}

	/**
	Like GitHub, which matches footnote labels like link labels, without case.
	*/
	@Test
	func `a footnote reference matches its definition in any case`() {
		let document = MarkdownDocument(parsing: "A note[^Note].\n\n[^note]: The note.")
		#expect(document.problems.isEmpty)
		#expect(document.html.contains("The note."))
	}

	/**
	Smart punctuation changes quotes, but a key is the character on the keyboard.
	*/
	@Test
	func `a quote key in a keyboard shortcut is not a smart quote`() {
		let html = MarkdownDocument(parsing: "Press ++Shift+'++ or ++\"++.").html
		#expect(html.contains("<kbd>'</kbd>"))
		#expect(html.contains(#"<kbd translate="no">&quot;</kbd>"#) || html.contains(#"<kbd translate="no">"</kbd>"#))
	}

	@Test
	func `keyboard shortcuts are their keys in plain text`() {
		#expect(MarkdownDocument(parsing: "Press ++Cmd+K++ to search in C++.").introduction == "Press Cmd+K to search in C++.")
		#expect(MarkdownDocument(parsing: "## Press ++Cmd+K++").headings.map(\.text) == ["Press Cmd+K"])
	}

	@Test
	func `a footnote in a collapsible heading is a problem that names the heading`() throws {
		let options = MarkdownDocument.Options(collapsibleSections: .init(level: 3))
		let reason = try #require(MarkdownDocument(parsing: "### Question[^1]\n\nAnswer.\n\n[^1]: Note.", options: options).problems.first).reason
		#expect(reason.contains("collapsible section"))
	}

	@Test
	func `footnotes whose IDs differ only in punctuation get different popovers`() {
		let html = MarkdownDocument(parsing: "A[^a.b] B[^a-b]\n\n[^a.b]: One.\n\n[^a-b]: Two.").html
		let ids = html.matches(of: /\sid="([^"]+)"/).map { String($0.1) }
		#expect(Set(ids).count == ids.count)
		#expect(html.contains(##"popovertarget="user-content-fn-2""##))
	}

	/**
	A fence with four spaces or more before it is indented code, not a fence, so it does not hide the definitions after it.
	*/
	@Test
	func `indented code that looks like a fence does not hide footnote definitions`() {
		let document = MarkdownDocument(parsing: "Text[^1].\n\n    ```\n\n[^1]: Note.")
		#expect(document.html.contains(##"popovertarget="user-content-fn-1""##))
		#expect(document.problems.isEmpty)
	}

	/**
	Like other blocks in CommonMark, a definition can have up to three spaces before it. Four spaces make it code.
	*/
	@Test
	func `a footnote definition can be indented up to three spaces`() {
		let html = MarkdownDocument(parsing: "Text[^1].\n\n   [^1]: Note.").html
		#expect(html.contains(##"popovertarget="user-content-fn-1""##))
		#expect(!html.contains("[^1]: Note."))
		#expect(MarkdownDocument(parsing: "Text.\n\n    [^1]: Code.").html.contains("<code>[^1]: Code."))
	}

	/**
	Like on GitHub, and like link reference definitions in CommonMark.
	*/
	@Test
	func `the first of duplicate footnote definitions is used`() {
		let html = MarkdownDocument(parsing: "A[^1]\n\n[^1]: First.\n\n[^1]: Second.").html
		#expect(html.contains("First."))
		#expect(!html.contains("Second."))
	}

	/**
	The parser reads the parts between block directives on their own, so each part can define the same ID, and the references after the directive would silently show the first definition.
	*/
	@Test
	func `a footnote defined again after a block directive is a problem`() throws {
		let document = MarkdownDocument(parsing: "A[^1].\n\n[^1]: First.\n\n@Plain {\n  In.\n}\n\nB[^1].\n\n[^1]: Second.", options: plainDirectiveOptions)
		#expect(document.problems.map(\.line) == [11])
		let reason = try #require(document.problems.first).reason
		#expect(reason.contains("`[^1]` is already defined"))
	}

	/**
	The introduction is the first paragraph, so a page that starts with a block directive has none, instead of the source of the directive.
	*/
	@Test
	func `a block directive is not the introduction`() {
		#expect(MarkdownDocument(parsing: "@Plain {\n  Inside.\n}\n\nText.", options: plainDirectiveOptions).introduction == nil)
	}

	@Test
	func `block directives and inline attributes render with their typed arguments`() throws {
		let options = MarkdownDocument.Options(
			inlineAttributes: .init { (attributes: BadgeAttributes, html) in
				"<b data-a='\(attributes.platform)'>\(html)</b>"
			},
			blockDirectives: [
				"Box": .init { (arguments: BoxArguments, html) in
					"<section title=\"\(arguments.title)\" data-wide=\"\(arguments.isWide)\">\(html)</section>"
				},
				"Plain": .init { html in
					"<div>\(html)</div>"
				},
			]
		)

		let document = MarkdownDocument(parsing: """
		^[Mac](platform: "macOS") only, ^[not](size: 2), ^[broken](platform: ).

		@Box(title: "Hi") {
		  Inside.
		}

		@Unknown {
		  Text.
		}

		@Box(name: "Hi") {
		  Text.
		}

		@Plain(title: "Hi") {
		  Text.
		}

		@Plain {
		  Text.
		}
		""", options: options)

		#expect(document.html.contains(#"<b data-a='macOS'>Mac</b> only, not, broken."#))
		#expect(document.html.contains(#"<section title="Hi" data-wide="false"><p>Inside.</p>"#))
		#expect(document.html.contains("<div><p>Text.</p>"))
		try #require(document.problems.map(\.line) == [1, 1, 7, 11, 15])
		#expect(document.problems[0].reason == "The inline attributes `size: 2` are invalid: Missing required key `platform`.")
		// The attributes that cannot be parsed say what is wrong.
		#expect(document.problems[1].reason.hasPrefix("The inline attributes `platform: ` are invalid: Expected a value"))
		#expect(document.problems[3].reason == "`@Box`: Missing required key `title`.")
		#expect(document.problems[4].reason == "`@Plain`: It takes no arguments.")
	}

	/**
	The parser gives several errors for one mistake, and the arguments that it reads after the mistake are wrong.
	*/
	@Test
	func `invalid block directive arguments are one problem`() {
		let options = MarkdownDocument.Options(blockDirectives: ["Box": .init { (_: BoxArguments, html) in "<section>\(html)</section>" }])
		let document = MarkdownDocument(parsing: "Intro.\n\n@Box(title: \"Hi\" isWide: \"true\") {\n  Inside.\n}", options: options)

		#expect(document.problems.map(\.line) == [3])
		#expect(document.problems.first?.reason == "The arguments of `@Box` are invalid: a `,` is missing. Write them like `name: \"Value\"`, with a comma between them.")
		#expect(document.html == "<p>Intro.</p>\n<p>Inside.</p>\n")
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

	@Test
	func `headings and list subtitles get footnotes and keyboard shortcuts`() {
		let document = MarkdownDocument(parsing: """
		## Press ++Cmd+K++[^heading] {#press}

		- Item
			: Subtitle[^list]

		[^heading]: Heading note.
		[^list]: List note.
		""")

		#expect(document.html.contains("<kbd>Cmd</kbd>"))
		#expect(document.html.contains(##"popovertarget="user-content-fn-1""##))
		#expect(document.html.contains(##"popovertarget="user-content-fn-2""##))
		#expect(!document.html.contains("[^"))
		#expect(document.problems.isEmpty)
	}

	@Test
	func `a code fence of another kind does not end the code block for footnotes`() {
		let document = MarkdownDocument(parsing: "~~~\n```\n~~~\n\n````\n```\n````\n\n``inline`` code.\n\nRef[^x].\n\n[^x]: Def.")
		#expect(document.html.contains(##"popovertarget="user-content-fn-1""##))
		#expect(document.problems.isEmpty)
	}

	@Test
	func `the code block language is the first word of the info string`() {
		let html = MarkdownDocument(parsing: "```swift title=\"x\"\nlet a = 1\n```").html
		#expect(html.contains(#"<code class="language-swift">"#))
	}

	@Test
	func `bare URLs leave out a trailing ellipsis`() {
		let html = MarkdownDocument(parsing: "See https://example.com...").html
		#expect(html.contains(#"<a href="https://example.com">https://example.com</a>…"#))
	}

	@Test
	func `the introduction has one space where a footnote reference was`() {
		#expect(MarkdownDocument(parsing: "Text [^1] and more.\n\n[^1]: Note.").introduction == "Text and more.")
	}

	@Test
	func `a footnote reference inside a link is a problem`() {
		let document = MarkdownDocument(parsing: "[link[^x]](https://example.com)\n\n[^x]: Def.")
		#expect(!document.html.contains("popover"))
		#expect(document.problems.contains { $0.reason.contains("inside a link") })
	}
}

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
		let document = MarkdownDocument(parsing: "Text[^note].\n\n[^note]: See [the FAQ](faq.md).", options: Self.options)

		#expect(document.html.contains(#"<a href="/faq">the FAQ</a>"#))
		// Once, like a link in the text.
		#expect(document.links.map(\.destination) == ["/faq"])
	}

	@Test
	func `inline notes open their Markdown in a popover at the end, with resolved links`() {
		let document = MarkdownDocument(parsing: #"""
		The ^[Spotlight](note: "The *search*.\n\n- See [the FAQ](faq.md).") app.

		After.
		"""#, options: Self.options)

		#expect(document.html.contains(#"<p>The <button type="button" popovertarget="user-content-note-1-5" class="inline-note">Spotlight</button> app.</p>"#))
		#expect(document.html.hasSuffix(#"<p>After.</p>\#n<div popover id="user-content-note-1-5" role="note" tabindex="-1" autofocus class="inline-note-popover"><p>The <em>search</em>.</p>\#n<ul>\#n<li>See <a href="/faq">the FAQ</a>.</li>\#n</ul>\#n</div>\#n"#))
		#expect(document.links.map(\.destination) == ["/faq"])
		#expect(document.problems.isEmpty)
	}

	@Test
	func `inline notes can have their text rendered by the options`() {
		let options = MarkdownDocument.Options(inlineNote: { textHTML, noteID in
			"<x-note for=\"\(noteID)\">\(textHTML)</x-note>"
		})

		#expect(MarkdownDocument(parsing: #"A ^[*term*](note: "Note.")."#, options: options).html.contains(#"<p>A <x-note for="user-content-note-1-3"><em>term</em></x-note>.</p>"#))
	}

	@Test
	func `invalid inline notes are problems with their lines`() throws {
		let document = MarkdownDocument(parsing: #"""
		^[Empty](note: "").

		[Link ^[inside](note: "A note.")](/x).

		^[With [a link](/x)](note: "A note.").

		^[Other](note: "A note.", size: 2).

		^[Broken](note: "Text.\n\nSee [the FAQ](missing.md).").

		^[Heading](note: "# A heading\n\nText.").

		^[Nested](note: "A ^[nested](note: \"note\").").

		^[Paragraphs](note: "A note.\n\nWith paragraphs, which are fine.").

		^[Footnote](note: "A footnote[^x].\n\n[^x]: Text.").

		^[Page footnote](note: "A footnote of the page[^page].").

		[^page]: Text.
		"""#, options: .init(resolveLink: { destination in
			guard destination != "missing.md" else {
				throw ContentError(reason: "Missing.")
			}

			return destination
		}))

		try #require(document.problems.map(\.line) == [1, 3, 5, 7, 9, 11, 13, 17, 19])
		#expect(document.problems[5].reason.contains("cannot have headings"))
		#expect(document.problems[6].reason.contains("cannot have another note"))
		#expect(document.problems[7].reason.contains("inside another footnote or a note"))
		#expect(document.problems[8].reason.contains("inside a note, which cannot have footnotes"))
		// An invalid note is only its text, and a nested note is only text in its note.
		#expect(document.html.contains("<p>Empty.</p>"))
		#expect(document.html.contains(#"role="note" tabindex="-1" autofocus class="inline-note-popover"><p>A nested.</p>"#))
		#expect(document.html.contains("<p>A note.</p>\n<p>With paragraphs, which are fine.</p>"))
	}

	@Test
	func `inline notes on the same line get different IDs`() {
		let html = MarkdownDocument(parsing: #"^[One](note: "First.") and ^[two](note: "Second.")."#).html

		#expect(html.contains(#"popovertarget="user-content-note-1-1""#))
		#expect(html.contains(#"popovertarget="user-content-note-1-28""#))
	}

	@Test
	func `inline notes in footnotes are at the end too`() {
		let document = MarkdownDocument(parsing: #"""
		A footnote[^footnote].

		[^footnote]: A footnote with ^[a note](note: "The note.").
		"""#)

		#expect(document.html.contains(#"A footnote with <button type="button" popovertarget="user-content-note-3-30" class="inline-note">a note</button>"#))
		// After the popover of the footnote.
		#expect(document.html.hasSuffix(#"</div>\#n<div popover id="user-content-note-3-30" role="note" tabindex="-1" autofocus class="inline-note-popover"><p>The note.</p>\#n</div>\#n"#))
		#expect(document.problems.isEmpty)
	}

	@Test
	func `inline notes in block directives are at the end of the document`() {
		let document = MarkdownDocument(parsing: "@Plain {\n  A ^[term](note: \"The note.\").\n}\n\nAfter.", options: plainDirectiveOptions)

		#expect(document.html.contains(#"<div><p>A <button type="button" popovertarget="user-content-note-2-5" class="inline-note">term</button>.</p>"#))
		#expect(document.html.hasSuffix(#"<p>After.</p>\#n<div popover id="user-content-note-2-5" role="note" tabindex="-1" autofocus class="inline-note-popover"><p>The note.</p>\#n</div>\#n"#))
		#expect(document.problems.isEmpty)
	}

	@Test
	func `problems and links in inline notes have the line of the note in the file`() throws {
		let document = MarkdownDocument(parsing: #"Intro.\#n\#nThe ^[term](note: "See [the FAQ](/faq).\n\n![](x.png)")."#, firstLine: 10, options: .init())

		#expect(document.html.contains(#"popovertarget="user-content-note-12-5""#))
		#expect(document.problems.map(\.line) == [12])
		let reason = try #require(document.problems.first).reason
		#expect(reason.contains("has no description"))
		// The link and the image.
		#expect(document.links.map(\.line) == [12, 12])
	}

	@Test
	func `an inline note in the heading of a collapsible section is a problem`() throws {
		let options = MarkdownDocument.Options(collapsibleSections: .init(level: 3))
		let document = MarkdownDocument(parsing: #"### Question ^[term](note: "The note.")\#n\#nAnswer."#, options: options)

		#expect(document.problems.map(\.line) == [1])
		let reason = try #require(document.problems.first).reason
		#expect(reason.contains("the heading of a collapsible section"))
		#expect(!document.html.contains("popover"))
	}

	@Test
	func `a footnote in the text of an inline note is a problem`() throws {
		let document = MarkdownDocument(parsing: #"^[Term[^1]](note: "The note.").\#n\#n[^1]: Text."#)

		let reason = try #require(document.problems.first).reason
		#expect(reason.contains("the text of a note"))
		#expect(document.html.contains(#"class="inline-note">Term[^1]</button>"#))
		#expect(!document.html.contains("footnote-reference"))
	}

	@Test
	func `the introduction has the text of an inline note, not the note`() {
		#expect(MarkdownDocument(parsing: #"The ^[Spotlight](note: "The search.") app."#).introduction == "The Spotlight app.")
	}

	@Test
	func `links keep their title`() {
		#expect(MarkdownDocument(parsing: #"[Dato](/dato "Calendar app")"#).html.contains(#"<a href="/dato" title="Calendar app">Dato</a>"#))
	}
}

/**
The options with a `@Plain` directive, which renders its content in a `div`.
*/
private let plainDirectiveOptions = MarkdownDocument.Options(blockDirectives: ["Plain": .init { html in "<div>\(html)</div>" }])

/**
The colored parts of highlighted code, each as the name of its token and its text, like `keyword let`.
*/
private func tokens(of parts: [(text: String, token: CodeToken?)]) -> [String] {
	parts.compactMap { part in
		part.token.map { "\($0.rawValue) \(part.text)" }
	}
}

private enum Keywords: HeadingDirective {
	static let name = "faq.keywords"
	typealias Value = [String]
}

private enum Platforms: HeadingDirective {
	static let name = "faq.platforms"
	typealias Value = [String]
}

private enum General: HeadingDirective {
	static let name = "faq.general"
	typealias Value = HeadingDirectiveFlag
}

@Frontmatter
private struct BadgeAttributes {
	var platform: String
}

@Frontmatter
private struct BoxArguments {
	var title: String
	var isWide = false
}

struct ReleaseNotesSecurityTests {
	@Test(arguments: ["<script>alert(1)</script>", "<img src=x onerror=alert(1)>", "<table><tr><td><script>alert(1)</script></td></tr></table>", "Text <iframe src='https://evil.example'></iframe>", "<kbd onclick=alert(1)>Delete</kbd>"])
	func `external release notes escape raw HTML`(source: String) {
		let html = MarkdownDocument(parsing: source, style: .releaseNotes).html
		#expect(!html.contains("<script>"))
		#expect(!html.contains("<iframe"))
		#expect(!html.contains("<table"))
		#expect(!html.contains("<img src=x"))
		#expect(!html.contains("<kbd onclick"))
		#expect(html.contains("&lt;"))
	}

	@Test(arguments: ["javascript:alert(1)", "JAVASCRIPT:alert(1)", "data:text/html,evil", "file:///etc/passwd", "vbscript:evil"])
	func `external release notes disable unsafe destinations`(destination: String) {
		let html = MarkdownDocument(parsing: "[Link](\(destination)) ![Image](\(destination))", style: .releaseNotes).html
		#expect(html.hasPrefix("<p>Link <img"))
		#expect(!html.contains("<a"))
		#expect(!html.contains("src=\"\(destination)\""))
	}

	@Test(arguments: ["&#32;javascript:alert(1)", "&#x20;JAVASCRIPT:alert(1)", "&#32;data:text/html,evil"])
	func `entity decoded spaces cannot conceal executable schemes`(destination: String) {
		let html = MarkdownDocument(parsing: "[Link](\(destination))", style: .releaseNotes).html
		#expect(html == "<p>Link</p>\n")
		#expect(!html.lowercased().contains("javascript:"))
		#expect(!html.contains("data:text/html"))
	}

	@Test
	func `release notes retain Markdown and safe destinations`() {
		let html = MarkdownDocument(parsing: "**Fixed** [Issue](https://github.com/test/repo/issues/1) ![Preview](https://example.com/image.png)", style: .releaseNotes).html
		#expect(html.contains("<strong>Fixed</strong>"))
		#expect(html.contains("href=\"https://github.com/test/repo/issues/1\""))
		#expect(html.contains("src=\"https://example.com/image.png\""))
	}
}
