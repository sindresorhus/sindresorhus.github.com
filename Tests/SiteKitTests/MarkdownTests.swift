import Elementary
import Foundation
import Markdown
import Testing
@testable import SiteKit

struct MarkdownTests {
	@Test
	func `generated HTML blocks retain the styles used while rewriting Markdown`() throws {
		let document = MarkdownDocument(blocks: [Paragraph(Markdown.Text("Text."))], options: .init(rewrite: { document in
			Document(Array(document.blockChildren) + [HTMLBlock(div {
				"A generated card"
			}.style {
				$0.padding(.pixels(1))
			}.render())])
		}))
		let resources = PageResources()
		let html = try resources.collect {
			document.content.render()
		}

		#expect(html.contains("A generated card"))
		#expect(!resources.elementStyleNodes.isEmpty)
	}

	@Frontmatter
	struct NoticeArguments {
		var title: NonEmptyString
	}

	enum Notice: BlockDirectiveDefinition {
		typealias Arguments = NoticeArguments
		static let name = "Notice"

		static func render(arguments: Arguments, contentHTML: String, context: MarkdownDocument.Options.BlockDirectiveRenderer.Context) -> String {
			"<aside><h2>\(arguments.title.value)</h2>\(contentHTML)</aside>"
		}
	}

	@Test
	func `directive definitions bind rendering and AST decoding to the same argument model`() throws {
		let options = MarkdownDocument.Options(blockDirectives: [Notice.name: Notice.renderer])
		let parsed = ParsedMarkdown(parsing: "@Notice(title: \"Read this\") {\nDetails.\n}", options: options)
		let directive = try #require(parsed.document.blockDirectives.first)
		let arguments: NoticeArguments = try directive.arguments(for: Notice.self)
		let document = try parsed.rendered()

		#expect(arguments.title.value == "Read this")
		#expect(document.html.contains("<aside><h2>Read this</h2><p>Details.</p>"))
		#expect(throws: ContentErrors.self) {
			try BlockDirective(name: "Other").arguments(for: Notice.self)
		}
		let invalid = MarkdownDocument(parsing: "@Notice(title: \"\") {\nDetails.\n}", options: options)
		#expect(invalid.problems.first?.line == 1)
		#expect(invalid.problems.first?.reason.contains("Must not be empty") == true)
	}

	@Test
	func `release notes retain only their applicable configuration through parsing and rendering`() throws {
		let options = MarkdownDocument.ReleaseNotesOptions(resolveLink: { "/resolved" + $0 })
		let parsed = ParsedMarkdown(releaseNotes: "# Version\n\n[Link](/page)\n\n<script>unsafe()</script>", options: options)
		let document = try parsed.rendered()

		#expect(document.html.contains("<h3>Version</h3>"))
		#expect(document.html.contains("href=\"/resolved/page\""))
		#expect(document.html.contains("&lt;script&gt;"))
		#expect(document.headings.isEmpty)
		#expect(document.html == MarkdownDocument(releaseNotes: "# Version\n\n[Link](/page)\n\n<script>unsafe()</script>", options: options).html)
	}

	@Test
	func `typed descendants preserve document order and exclude the receiver`() throws {
		let document = Document(parsing: "@Outer {\n@Inner {\nText.\n}\n}\n\n@Last", options: .parseBlockDirectives)
		let outer = try #require(document.child(at: 0) as? BlockDirective)
		#expect(document.descendants(of: BlockDirective.self).map(\.name) == ["Outer", "Inner", "Last"])
		#expect(outer.descendants(of: BlockDirective.self).map(\.name) == ["Inner"])
		#expect(outer.blockDirectives.map(\.name) == ["Inner"])
		#expect(document.descendants(of: Markdown.Text.self).map(\.string) == ["Text."])
	}

	@Test(arguments: HeadingLevel.allCases)
	func `parsed heading metadata retains its valid comparable level`(level: HeadingLevel) {
		let document = MarkdownDocument(parsing: "\(String(repeating: "#", count: level.rawValue)) Title")
		#expect(document.headings.first?.level == level)
		#expect(document.blocks.first?.headingLevel == level)
		#expect((level > .h3) == (level.rawValue > 3))
	}

	@Test
	func `a heading directive can parse a scalar value directly`() throws {
		enum Rank: HeadingDirective {
			static let name: HeadingDirectiveName = "rank"

			static func decode(values: [String]) throws(ContentError) -> Int {
				guard
					values.count == 1,
					let rank = Int(values[0])
				else {
					throw ContentError(reason: "Expected one integer.")
				}

				return rank
			}
		}

		let document = MarkdownDocument(parsing: "## First\n<!-- @rank 2 -->\n\n## Second\n<!-- @rank 1 2 -->\n\n## Third\n<!-- @rank nope -->", options: .init(headingDirectives: [Rank.self]))
		#expect(document.headings[0][Rank.self] == 2)
		#expect(document.headings[1][Rank.self] == nil)
		#expect(document.headings[2][Rank.self] == nil)
		#expect(document.problems.map(\.reason) == Array(repeating: "The values of `@rank` are invalid: Expected one integer.", count: 2))
	}

	@Test
	func `integer heading directives use a shared strict decoder`() throws {
		enum Rank: HeadingDirective {
			static let name: HeadingDirectiveName = "rank"
			typealias Value = Int
		}

		let document = MarkdownDocument(parsing: "## First\n<!-- @rank -2 -->\n\n## Second\n<!-- @rank 1 2 -->\n\n## Third\n<!-- @rank nope -->", options: .init(headingDirectives: [Rank.self]))
		#expect(document.headings[0][Rank.self] == -2)
		#expect(document.headings[1][Rank.self] == nil)
		#expect(document.headings[2][Rank.self] == nil)
		#expect(document.problems.map(\.line) == [5, 8])
		#expect(document.problems.map(\.reason) == [
			"The values of `@rank` are invalid: Expected one integer, got 2 values.",
			"The values of `@rank` are invalid: Expected an integer, got “nope”.",
		])

		let error = try #require(throws: ContentError.self) {
			try Rank.decode(values: [])
		}
		#expect(error.reason == "Expected one integer, got 0 values.")
	}

	/**
	A cell that a span covers has no cell of its own, like in GitHub’s tables.
	*/
	@Test
	func `table cells that a span covers are not rendered`() {
		#expect(!MarkdownDocument(parsing: "| a | b |\n|---|---|\n| x ||").html.contains("<td></td>"))
		#expect(!MarkdownDocument(parsing: "| a | b |\n|---|---|\n| x | y |\n| ^ | z |").html.contains("<td></td>"))
	}

	/**
	Like on GitHub, the marker is alone on its line, and the alert has text, so a quote that starts with a marker is a quote. It would show the marker as text, so it is a problem, like a marker with an unknown kind.
	*/
	@Test
	func `an alert marker is alone on its line`() {
		#expect(MarkdownDocument(parsing: "> [!NOTE] is a marker").html.contains("<blockquote>"))
		#expect(MarkdownDocument(parsing: "> [!NOTE]").html.contains("<blockquote>"))
		#expect(MarkdownDocument(parsing: "Text.\n\n> [!NOTE] is a marker").problems.map { "\($0.line?.rawValue ?? 0): \($0.reason)" } == ["3: The marker `[!NOTE]` must be alone on its line. Put the text on the next line."])
		#expect(MarkdownDocument(parsing: "> [!NOTE]").problems.map(\.reason) == ["The alert `[!NOTE]` has no text. Write the text on the next line."])
		#expect(MarkdownDocument(parsing: "> [!WARNNG]\n> Text").problems.map(\.reason) == ["`[!WARNNG]` is not an alert. Use `[!NOTE]`, `[!TIP]`, `[!IMPORTANT]`, `[!WARNING]`, or `[!CAUTION]`. Did you mean `[!WARNING]`?"])
		#expect(MarkdownDocument(parsing: "> [!WARN] Text").problems.map(\.reason) == ["`[!WARN]` is not an alert. Use `[!NOTE]`, `[!TIP]`, `[!IMPORTANT]`, `[!WARNING]`, or `[!CAUTION]`."])
		#expect(MarkdownDocument(parsing: "> [!NOTE]\n> Text\n\n> A quote [!NOTE]").problems.isEmpty)
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
		#expect(document.headings.map(\.id.rawValue) == ["use-id"])
		#expect(document.html.contains(#"id="use-id""#))
		#expect(MarkdownDocument(parsing: "## Install {#setup}").headings.map(\.id.rawValue) == ["setup"])
	}

	/**
	Smart punctuation makes `--` a dash, but a custom ID keeps its hyphens, like the slug of “Cut & Paste” that keeps the URL of a renamed heading.
	*/
	@Test
	func `a custom ID can have double hyphens`() {
		let document = MarkdownDocument(parsing: "## Copy and Paste {#cut--paste}\n\n## Other {#a---b}")
		#expect(document.headings.map(\.id.rawValue) == ["cut--paste", "a---b"])
		#expect(document.headings.map(\.text) == ["Copy and Paste", "Other"])
		#expect(document.html.contains(#"<h2 id="cut--paste">Copy and Paste</h2>"#))
	}

	/**
	An invalid custom ID, like one with a space or a dot, would otherwise be visible text and a part of the slug, like `with-gifski-with-gifski`.
	*/
	@Test
	func `an invalid custom ID is a problem, not text`() throws {
		let document = MarkdownDocument(parsing: "Text.\n\n## With Gifski {#with gifski}\n\n## Version {#v1.2}")
		#expect(document.problems.map(\.line) == [3, 5])
		#expect(document.problems.first?.reason == "The custom ID `with gifski` can only have letters, digits, underscores, and hyphens, like `{#with-gifski}`.")
		// The suggestion leaves out a space at the end, which is a typo, so it is the ID that the links use.
		#expect(MarkdownDocument(parsing: "## A question? {#a-question }").problems.map(\.reason) == ["The custom ID `a-question ` can only have letters, digits, underscores, and hyphens, like `{#a-question}`."])
		#expect(document.headings.map(\.text) == ["With Gifski", "Version"])
		#expect(!document.html.contains("{#"))
	}

	@Test
	func `an empty custom ID is a problem that says so`() {
		let document = MarkdownDocument(parsing: "## Features {#}")
		#expect(document.problems.map(\.reason) == ["The custom ID `{#}` is empty. Write it like `{#features}`."])
	}

	/**
	The custom ID of a heading that code adds, which the renderer and ``Markdown/Heading/customID`` read back.
	*/
	@Test
	func `a heading made with an ID has it as its custom ID`() {
		let heading = Markdown.Heading(level: .h2, "Older Versions", id: ElementID("older"))
		#expect(heading.title == "Older Versions")
		#expect(heading.customID == ElementID("older"))
		#expect(Markdown.Heading(level: 2, Markdown.Text("Install {#with gifski}")).customID == nil)
		#expect(Markdown.Heading(level: 2, Markdown.Text("Install")).customID == nil)
	}

	@Test
	func `rendered heading IDs remain typed through section splitting and links`() throws {
		let document = MarkdownDocument(parsing: "Introduction.\n\n## Æøå\n\nText.", options: .init(addsHeadingAnchors: true))
		let heading = try #require(document.headings.first)
		let id: ElementID = heading.id

		#expect(id.rawValue == "æøå")
		#expect(document.html.contains("href=\"#%C3%A6%C3%B8%C3%A5\""))
		#expect(document.contentSeparated(beforeHeading: id)?.after.html.contains(#"id="æøå""#) == true)
	}

	@Test(arguments: HeadingLevel.allCases)
	func `typed heading construction preserves inline children`(level: HeadingLevel) throws {
		let children: [any InlineMarkup] = [Strong(Markdown.Text("Strong")), Markdown.Text(" and "), InlineCode("code")]
		let sequenceHeading = Markdown.Heading(level: level, children)
		let variadicHeading = Markdown.Heading(level: level, Strong(Markdown.Text("Strong")), Markdown.Text(" and "), InlineCode("code"))

		#expect(sequenceHeading.headingLevel == level)
		#expect(variadicHeading.headingLevel == level)
		let sequenceDocument = try ParsedMarkdown(blocks: [sequenceHeading]).rendered()
		let variadicDocument = try ParsedMarkdown(blocks: [variadicHeading]).rendered()
		#expect(sequenceDocument.html == variadicDocument.html)
		#expect(sequenceDocument.html == "<h\(level.rawValue) id=\"strong-and-code\"><strong>Strong</strong> and <code translate=\"no\">code</code></h\(level.rawValue)>\n")
	}

	@Test(arguments: ["install_2", "æøå", "cut--paste"])
	func `generated heading IDs round trip through rendering and title replacement`(rawID: String) throws {
		let id = ElementID(rawID)
		var heading = Markdown.Heading(level: .h2, "Before", id: id)
		heading.setTitle("After", id: id)
		let document = try ParsedMarkdown(blocks: [heading]).rendered()

		#expect(heading.customID == id)
		#expect(document.headings.first?.id == id)
		#expect(document.headings.first?.text == "After")
	}

	@Test(arguments: ["with.dot", "with#hash", "with{brace}", "cut–paste", "cut—paste"])
	func `generated headings reject element IDs outside custom heading syntax`(rawID: String) async {
		await #expect(processExitsWith: .failure) { [rawID] in
			_ = Markdown.Heading(level: .h2, "Title", id: ElementID(rawID))
		}
	}

	@Test
	func `the shared heading level bridge rejects unsupported code built levels`() async {
		await #expect(processExitsWith: .failure) {
			_ = Markdown.Heading(level: 7, Markdown.Text("Title")).headingLevel
		}
	}

	@Test(arguments: HeadingLevel.allCases)
	func `generated headings render at their typed level`(level: HeadingLevel) {
		let document = MarkdownDocument(parsing: "", options: .init(rewrite: { _ in
			Document([Markdown.Heading(level: level, "Generated", id: ElementID("generated"))])
		}))

		#expect(document.problems.isEmpty)
		#expect(document.headings.first?.level == level)
		#expect(document.blocks.first?.headingLevel == level)
		#expect(document.html == "<h\(level.rawValue) id=\"generated\">Generated</h\(level.rawValue)>\n")
	}

	@Test(arguments: HeadingLevel.allCases)
	func `collapsible sections use their typed heading level`(level: HeadingLevel) {
		let source = "\(String(repeating: "#", count: level.rawValue)) Question\n\nAnswer."
		let options = MarkdownDocument.Options(collapsibleSections: .init(level: level))
		let document = MarkdownDocument(parsing: source, options: options)

		#expect(document.problems.isEmpty)
		#expect(document.html.contains(#"<h\#(level.rawValue) class="collapsible-title">Question</h\#(level.rawValue)>"#))
		#expect(document.html.contains(#"<details id="question""#))
	}

	/**
	Code is shown as written, so footnote syntax in it, like `` `[^1]` ``, stays in the heading ID and the introduction.
	*/
	@Test
	func `footnote syntax in inline code stays in the plain text`() {
		#expect(MarkdownDocument(parsing: "## The `[^1]` syntax").headings.map(\.id.rawValue) == ["the-1-syntax"])
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
		let html = MarkdownDocument(releaseNotes: "**Full Changelog**: https://github.com/sindresorhus/ky/compare/v1.0.0...v1.1.0").html
		#expect(html.contains(#"href="https://github.com/sindresorhus/ky/compare/v1.0.0...v1.1.0""#))
		#expect(html.contains(#">https://github.com/sindresorhus/ky/compare/v1.0.0...v1.1.0</a>"#))
		#expect(MarkdownDocument(parsing: "See https://example.com/a--b for more.").html.contains(#"href="https://example.com/a--b""#))
		#expect(MarkdownDocument(parsing: "See https://en.wikipedia.org/wiki/Hitchhiker's_Guide for more.").html.contains(#"href="https://en.wikipedia.org/wiki/Hitchhiker's_Guide""#))
	}

	@Test
	func `custom heading IDs are used and removed from the text`() {
		let document = MarkdownDocument(parsing: "## Hello World {#custom-id}\n\nText")
		#expect(document.headings.map(\.text) == ["Hello World"])
		#expect(document.headings.map(\.id.rawValue) == ["custom-id"])
		#expect(document.headings.map(\.line) == [1])
		#expect(document.html.contains(#"<h2 id="custom-id">Hello World</h2>"#))
	}

	@Test
	func `inline HTML removes the paragraph only when there is one`() {
		#expect(MarkdownDocument(parsing: "Hello *world*").inlineHTML == "Hello <em>world</em>")
		#expect(MarkdownDocument(parsing: "First\n\nSecond").inlineHTML == "<p>First</p>\n<p>Second</p>")
		#expect(MarkdownDocument(parsing: #"First\#n\#n<p class="note">Second</p>"#).inlineHTML == #"<p>First</p>\#n<p class="note">Second</p>"#)
	}

	@Test(arguments: ["# Heading", "First\n\nSecond", "- Item", "```swift\nlet value = 1\n```", "<!-- Only a comment -->", "", "Text[^1].\n\n[^1]: A note.", #"A ^[term](note: "A note.")"#])
	func `checked inline arguments reject blocks and popovers`(source: String) {
		let context = MarkdownDocument.Options.BlockDirectiveRenderer.Context(documentOptions: .init())

		#expect(throws: ContentError.self) {
			try context.inlineDocument(parsing: source)
		}
	}

	@Test
	func `checked inline arguments preserve bold text and ignore comment blocks`() throws {
		let context = MarkdownDocument.Options.BlockDirectiveRenderer.Context(documentOptions: .init())
		let document = try context.inlineDocument(parsing: "<!-- An author note -->\n\n**Highlights**\n\n<!-- Another note -->")

		#expect(document.inlineHTML == "<strong>Highlights</strong>")
		#expect(document.html.contains("<p class=\"bold-label\"><strong>Highlights</strong></p>"))
		#expect(try context.inlineDocument(parsing: "Hello *world* <span>!</span>").inlineHTML == "Hello <em>world</em> <span>!</span>")
	}

	@Test
	func `checked bold inline arguments retain link resolution and attribute validation`() throws {
		let context = MarkdownDocument.Options.BlockDirectiveRenderer.Context(documentOptions: .init(
			inlineAttributes: .init { (attributes: BadgeAttributes, contentHTML: String) throws(ContentError) in
				guard attributes.platform == "macOS" else {
					throw ContentError(reason: "Unsupported platform.")
				}

				return "<span>\(contentHTML)</span>"
			},
			resolveLink: { (destination: String) throws(ContentError) in
				guard destination != "missing.md" else {
					throw ContentError(reason: "Missing destination.")
				}

				return "/" + destination.replacing(".md", with: "")
			}
		))
		let document = try context.inlineDocument(parsing: #"**[Guide](guide.md) ^[Mac](platform: "macOS")**"#)

		#expect(document.inlineHTML == #"<strong><a href="/guide">Guide</a> <span>Mac</span></strong>"#)
		#expect(document.links.map(\.destination) == ["/guide"])

		let linkError = try #require(throws: ContentError.self) {
			try context.inlineDocument(parsing: #"**[Guide](missing.md) ^[Mac](platform: "macOS")**"#)
		}
		#expect(linkError.reason.contains("Missing destination."))

		let attributesError = try #require(throws: ContentError.self) {
			try context.inlineDocument(parsing: #"**[Guide](guide.md) ^[Mac](platform: "iOS")**"#)
		}
		#expect(attributesError.reason.contains("Unsupported platform."))
	}

	@Test
	func `duplicate heading directive registrations fail after options are mutated`() async {
		await #expect(processExitsWith: .failure) {
			var options = MarkdownDocument.Options(headingDirectives: [Keywords.self])
			options.headingDirectives.append(OtherKeywords.self)
			_ = MarkdownDocument(parsing: "## Title", options: options)
		}
	}

	/**
	A table in raw HTML gets the same container as a Markdown table.
	*/
	@Test(arguments: ["| A | B |\n| --- | --- |\n| 1 | 2 |", "<table>\n<tr><td>A</td></tr>\n</table>"])
	func `tables are in a container that keyboard users can scroll`(markdown: String) {
		let document = MarkdownDocument(parsing: markdown)
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
		#expect(document.headings.map(\.id.rawValue) == ["same", "same", "same-1"])
		// The second “Same” has the ID of the first heading, and the third “Same” is a second section with the same heading.
		#expect(document.problems.map(\.line) == [3, 5])
		let reason = try #require(document.problems.first).reason
		#expect(reason.contains("`same`"))
	}

	/**
	A heading that is both a second section with the same text and has the ID of that section is one problem, not two at the same line.
	*/
	@Test
	func `a repeated heading with the ID of the first is one problem`() {
		let document = MarkdownDocument(parsing: "## Install {#install}\n\n## Install")
		#expect(document.headings.map(\.id.rawValue) == ["install", "install"])
		#expect(document.problems.map(\.line) == [3])
	}

	@Test
	func `two headings with the same custom ID are a problem`() {
		let document = MarkdownDocument(parsing: "## First {#x}\n\n## Second {#x}\n\n## Third {#y}")
		#expect(document.headings.map(\.id.rawValue) == ["x", "x", "y"])
		#expect(document.problems.map(\.line) == [3])
	}

	@Test
	func `heading slug collisions match GitHub`() {
		let document = MarkdownDocument(parsing: "## Same\n## Same\n## Same-1\n## Same")
		#expect(document.headings.map(\.id.rawValue) == ["same", "same-1", "same-1-1", "same-2"])
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
		#expect(document.headings.first?.id.rawValue == "use-npx--now")
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
		let document = MarkdownDocument(
			parsing: "### Own {#own}\n\n[Own link](https://example.com/own)",
			options: .init(
				headingDirectives: [Keywords.self],
				rewrite: { document in
					let added = Document(parsing: "Text.\n\n### Added {#added}\n<!-- @faq.keywords launch -->\n<!-- @faq.unknown -->\n\n[Link](https://example.com)", file: URL(filePath: "/shared.md"), options: .init())
					return Document(Array(document.blockChildren) + Array(added.blockChildren.dropFirst()))
				}
			)
		)

		#expect(document.headings.map(\.line) == [1, nil])
		#expect(document.headings[1][Keywords.self] == ["launch"])
		#expect(document.links.map(\.line) == [3, 7])
		#expect(document.links.map(\.otherFile) == [nil, URL(filePath: "/shared.md")])
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
		let document = MarkdownDocument(parsing: "<!-- Hidden. -->\n\nUse [Dato](/dato) daily.\n\nSecond paragraph.[^1]\n\n[^1]: A note.")
		let separated = try #require(document.contentSeparatingIntroduction)
		#expect(separated.introduction.html == #"Use <a href="/dato">Dato</a> daily."#)
		#expect(separated.remainder.html.hasPrefix("<p>Second paragraph."))
		// The popover of the footnote stays with the rest.
		#expect(document.html.hasSuffix(separated.remainder.html))
		#expect(separated.remainder.html.contains("A note."))

		#expect(MarkdownDocument(parsing: "## Heading\n\nParagraph.").contentSeparatingIntroduction == nil)
		#expect(MarkdownDocument(parsing: "![Screenshot](screenshot.png)\n\nParagraph.").contentSeparatingIntroduction == nil)
	}

	@Test
	func `a document can be separated before a heading`() throws {
		let document = MarkdownDocument(parsing: "First.\n\n## Section\n\n`<h2 id=\"end\">`\n\n## End\n\nMore.")
		let separated = try #require(document.contentSeparated(beforeHeading: ElementID("end")))
		#expect(separated.before.html.contains("Section"))
		// The heading in code is not a heading.
		#expect(separated.before.html.contains(#"<code translate="no">"#))
		#expect(separated.after.html.hasPrefix(#"<h2 id="end""#))
		#expect(separated.after.html.contains("More."))

		#expect(document.contentSeparated(beforeHeading: ElementID("missing")) == nil)
	}

	/**
	A heading inside a block directive is not a place to split, as the HTML of the directive would be cut in two.
	*/
	@Test
	func `a heading inside a block directive is not a place to split`() {
		var options = MarkdownDocument.Options()
		options.blockDirectives["Box"] = .init { "<div>\($0)</div>" }
		let document = MarkdownDocument(parsing: "First.\n\n@Box {\n  Intro.\n\n  ## Inside {#inside}\n\n  Text.\n}", options: options)

		#expect(document.headings.map(\.id.rawValue) == ["inside"])
		#expect(document.html.contains("<div><p>Intro.</p>\n<h2 id=\"inside\">"))
		#expect(document.contentSeparated(beforeHeading: ElementID("inside")) == nil)
	}

	@Test
	func `a document can be separated before several headings, in their order`() throws {
		let document = MarkdownDocument(parsing: "First.\n\n## Middle\n\nSecond.\n\n## End\n\nThird.")
		let parts = try #require(document.contentSeparated(beforeHeadings: [ElementID("middle"), ElementID("end")])).map(\.html)
		try #require(parts.count == 3)
		#expect(parts[0].contains("First.") && !parts[0].contains("Second."))
		#expect(parts[1].hasPrefix(#"<h2 id="middle""#) && parts[1].contains("Second.") && !parts[1].contains("Third."))
		#expect(parts[2].hasPrefix(#"<h2 id="end""#) && parts[2].contains("Third."))

		#expect(document.contentSeparated(beforeHeadings: [ElementID("end"), ElementID("middle")]) == nil)
		#expect(document.contentSeparated(beforeHeadings: [ElementID("middle"), ElementID("missing")]) == nil)
	}

	@Test
	func `splitting content preserves empty leading parts and puts popovers only in the final part`() throws {
		let document = MarkdownDocument(parsing: "## First\n\nA ^[note](note: \"Body.\").\n\n## End\n\nEnd.")
		let parts = try #require(document.content.separated(beforeHeadings: [ElementID("first"), ElementID("end")]))
		#expect(parts.count == 3)
		#expect(parts[0].html.isEmpty)
		#expect(!parts[1].html.contains("<div popover "))
		#expect(parts[2].html.ranges(of: "<div popover ").count == 1)
		#expect(parts.map(\.html).joined() == document.content.html)
		let first = try #require(document.content.separatedBeforeFirstSection)
		#expect(first.before.html.isEmpty)
		#expect(first.after.html == document.content.html)
	}

	@Test
	func `directive block parsing keeps line positions and eligibility in one result`() {
		let block = HTMLBlock("<!-- @one value -->\n\n<!-- @two -->\n")
		let parsed = block.parsedDirectiveComments
		#expect(parsed.isOnlyDirectives)
		#expect(parsed.comments.map { $0?.name } == ["one", nil, "two", nil])
		#expect(parsed.comments[0]?.values == ["value"])
	}

	@Test(arguments: ["<!-- @one x --><!-- @two y -->", "Text <!-- @one x -->", "<!-- @one x -->\nText"])
	func `directive block parsing rejects lines with other content`(source: String) {
		#expect(!HTMLBlock(source).parsedDirectiveComments.isOnlyDirectives)
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

		let rendered = MarkdownDocument(
			parsing: "```swift title\nlet a = 1\n```\n\n```\nplain\n```",
			options: .init(
				codeBlock: { code, language in
					"<x-code>\(language ?? "none"): \(code)</x-code>"
				}
			)
		).html

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
		let source = "# A comment.\nname: \"é😀\\t\"\n\"is enabled\": true\ntags: [1, 1h30m, 2026-09-19, 2026-09-19T14:00:00Z]\n"
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
			"number 2026-09-19",
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
		let html = MarkdownDocument(releaseNotes: "- First\\\r\n  Description\r\n- Second\\\r\n  Description").html
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

		// Like a shortcut in the Markdown: a glyph key has its name for screen readers, and the plus key is `+`. The text is HTML, so an escape is not escaped again.
		let glyphHTML = MarkdownDocument(parsing: "<div><kbd>Command+◀</kbd> <kbd>Command+Plus</kbd> <kbd>Option+&amp;</kbd></div>").html
		#expect(glyphHTML.contains(#"<kbd><span role="img" aria-label="Left Arrow">◀</span></kbd>"#))
		#expect(glyphHTML.contains(#"<kbd>Command</kbd><span class="key-separator" aria-hidden="true">+</span><kbd>+</kbd>"#))
		#expect(glyphHTML.contains("<kbd>&amp;</kbd>"))
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
		let html = MarkdownDocument(releaseNotes: "Write to hi@example.io.").html
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
		let document = MarkdownDocument(releaseNotes: "# Big\n\n## Fixes\n\n##### Small\n\nContact support@example.com or https://example.com/help. <kbd>Command+Delete</kbd>")
		// The page shows each release below a heading of its version (`<h2>`), so the headings go two levels down.
		#expect(document.html.contains("<h3>Big</h3>\n<h4>Fixes</h4>\n<h6>Small</h6>"))
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
	func `each table keeps its own header body and spanning cell alignments`() {
		let html = MarkdownDocument(parsing: """
		| Left | Right |
		| :--- | ---: |
		| one | two |

		| Center | Plain |
		| :---: | --- |
		| three | four |
		| span ||

		| Unaligned |
		| --- |
		| five |
		""").html
		#expect(html.contains(#"<th align="left">Left</th>"#))
		#expect(html.contains(#"<td align="right">two</td>"#))
		#expect(html.contains(#"<th align="center">Center</th>"#))
		#expect(html.contains(#"<td align="center">three</td>"#))
		#expect(html.contains(#"<td align="center" colspan="2">span</td>"#))
		#expect(html.contains("<th>Plain</th>"))
		#expect(html.contains("<td>four</td>"))
		#expect(html.contains("<th>Unaligned</th>"))
		#expect(html.contains("<td>five</td>"))
	}

	@Test
	func `footnote references in code stay as they are`() {
		let html = MarkdownDocument(parsing: "Text[^1] and `array[^1]`.\n\n[^1]: The note.").html
		#expect(html.contains(#"<code translate="no">array[^1]</code>"#))
		#expect(html.components(separatedBy: "footnote-reference").count == 2)
	}

	@Test
	func `headings of a level after a heading become collapsible sections`() throws {
		let options = MarkdownDocument.Options(
			collapsibleSections: .init(
				level: .h4,
				startHeadingID: ElementID("faq"),
				name: "faq",
				moreLink: .init(title: "More", destination: .path(#path("/faq")))
			),
			addsHeadingAnchors: true,
			headingDirectives: [Keywords.self]
		)
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
		try #require(document.headings.map(\.id.rawValue) == ["before", "faq", "first", "second", "after", "not-a-section"])
		#expect(document.headings[2][Keywords.self] == ["one"])
	}

	/**
	Screen readers list the links of a page by name, so each link to a section has the text of its heading. The link is inside a heading, so the heading is named by its text, without the name of the link.
	*/
	@Test
	func `links to sections are named after their headings, which are named by their text`() {
		let options = MarkdownDocument.Options(collapsibleSections: .init(level: .h3, startHeadingID: ElementID("faq")), addsHeadingAnchors: true)
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
		let options = MarkdownDocument.Options(collapsibleSections: .init(level: .h4, startHeadingID: ElementID("faq")))
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
		let options = MarkdownDocument.Options(collapsibleSections: .init(level: .h4, startHeadingID: ElementID("faq")))
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
		enum Size: String, ContentEnum {
			case small
			case large
		}

		enum Sizes: HeadingDirective {
			static let name: HeadingDirectiveName = "faq.sizes"
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
		#expect(document.headings[2][Sizes.self] == nil)
		try #require(document.problems.map(\.line) == [5, 8])
		#expect(document.problems[0].reason.hasPrefix("The values of `@faq.sizes` are invalid:"))
		#expect(document.problems[1].reason == "`@faq.sizes` needs at least one value.")
	}

	@Test
	func `custom heading directive decoders override constrained defaults`() throws {
		enum Rank: HeadingDirective {
			static let name: HeadingDirectiveName = "test.rank"
			typealias Value = Int

			static func decode(values: [String]) throws(ContentError) -> Int {
				guard values == ["first"] else {
					throw ContentError(reason: "Use first.")
				}
				return 1
			}
		}

		enum Size: String, ContentEnum {
			case small
		}

		enum Sizes: HeadingDirective {
			static let name: HeadingDirectiveName = "test.sizes"
			typealias Value = [Size]

			static func decode(values: [String]) throws(ContentError) -> [Size] {
				guard values == ["compact"] else {
					throw ContentError(reason: "Use compact.")
				}
				return [.small]
			}
		}

		let document = MarkdownDocument(parsing: """
		## First
		<!-- @test.rank first -->
		<!-- @test.sizes compact -->

		## Second
		<!-- @test.rank 1 -->
		<!-- @test.sizes small -->
		""", options: .init(headingDirectives: [Rank.self, Sizes.self]))

		try #require(document.headings.count == 2)
		#expect(document.headings[0][Rank.self] == 1)
		#expect(document.headings[0][Sizes.self] == [.small])
		#expect(document.headings[1][Rank.self] == nil)
		#expect(document.headings[1][Sizes.self] == nil)
		#expect(document.problems.map(\.line) == [6, 7])
		#expect(document.problems.map(\.reason) == [
			"The values of `@test.rank` are invalid: Use first.",
			"The values of `@test.sizes` are invalid: Use compact.",
		])
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
		#expect(html.contains(#"<kbd>Option</kbd><span class="key-separator" aria-hidden="true">+</span><kbd><span role="img" aria-label="Left Arrow">◀</span>"#))
		#expect(html.contains("not C++ and C++."))
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
	func `a modifier given twice is a problem that says so, not one about the order`() {
		let document = MarkdownDocument(parsing: "Press ++Command+Command+N++.")

		#expect(document.problems.map(\.reason) == ["The keyboard shortcut `Command+Command+N` has Command twice."])
	}

	/**
	CommonMark gives an unclosed fence or directive the rest of the document, so the problem is at the line where it opens, not at a later problem that it causes.
	*/
	@Test
	func `an unclosed code fence or block directive is a problem at its first line`() {
		let fence = MarkdownDocument(parsing: "Text.\n\n```swift\nlet x = 1\n\n## Heading\n")
		let quotedFence = MarkdownDocument(parsing: "> ~~~~\n> code\n")
		let directive = MarkdownDocument(parsing: "Text.\n\n@Plain {\nInside.\n\nAfter.\n", options: plainDirectiveOptions)

		#expect(fence.problems.map(\.line) == [3])
		#expect(fence.problems.map(\.reason) == ["The code block that starts here has no closing ```, so the rest of the file is code."])
		#expect(quotedFence.problems.map(\.reason) == ["The code block that starts here has no closing ~~~~, so the rest of the file is code."])
		#expect(directive.problems.map(\.line) == [3])
		#expect(directive.problems.map(\.reason) == ["The block directive `@Plain` that starts here has no closing `}`, so the rest of the file is its content."])

		// Closed fences, also in a quote and a list, a longer closing fence, indented code, and closed directives are fine.
		for source in ["```swift\nlet x\n```", "> ```\n> code\n> ```", "- Item\n\n  ```\n  code\n  ````\n", "Text.\n\n    indented\n", "@Plain {\nInside.\n}\n\nAfter.", "@Plain {\n@Plain {\nInside.\n}\n}"] {
			#expect(MarkdownDocument(parsing: source, options: plainDirectiveOptions).problems.isEmpty, "\(source)")
		}
	}

	/**
	A file of the page bundle works in raw HTML too, like `<img src="screenshot1.jpg">`, and a broken link in raw HTML is at its line.
	*/
	@Test
	func `the links of raw HTML are resolved like Markdown links and recorded at their lines`() {
		let options = MarkdownDocument.Options(resolveLink: { destination in
			destination.contains(":") || destination.hasPrefix("/") ? destination : "/dato/\(destination)"
		})
		let document = MarkdownDocument(parsing: "Text.\n\n<img src=\"screenshot1.jpg\" width=\"10\" height=\"10\">\n\nSee <a href=\"/apps?a=1&amp;b=2\">apps</a> and <img src=\"https://example.com/a.png\">.", options: options)

		#expect(document.html.contains(#"<img src="/dato/screenshot1.jpg" width="10" height="10">"#))
		#expect(document.html.contains(#"<a href="/apps?a=1&amp;b=2">"#))
		#expect(document.links.map(\.destination) == ["/dato/screenshot1.jpg", "/apps?a=1&b=2", "https://example.com/a.png"])
		#expect(document.links.map(\.line) == [3, 5, 5])
	}

	@Test
	func `an unknown argument of a block directive is named without the Swift type`() {
		let options = MarkdownDocument.Options(blockDirectives: ["Box": .init { (arguments: BoxArguments, html) in html }])
		let document = MarkdownDocument(parsing: "@Box(title: \"Hi\", isWid: \"true\") {\nText.\n}", options: options)

		#expect(document.problems.map(\.reason) == ["`@Box`: Unknown key `isWid`. Did you mean `isWide`?"])
	}

	@Test
	func `a heading without text is a problem`() {
		let document = MarkdownDocument(parsing: "## Tips\n\n### \n\nText.")

		#expect(document.problems.map(\.line) == [3])
		#expect(document.problems.map(\.reason) == ["The heading has no text."])
	}

	@Test
	func `a table row with more cells than the header is a problem`() {
		let document = MarkdownDocument(parsing: "| A | B |\n| --- | --- |\n| 1 | 2 |\n| Key | Opens | Extra cell text |\n| `a\\|b` | c |")

		#expect(document.problems.map(\.line) == [4])
		#expect(document.problems.map(\.reason) == ["The row has 3 cells, but the table has 2 columns, so the page leaves out “Extra cell text”."])
	}

	@Test
	func `two sections with the same heading are a problem`() {
		let document = MarkdownDocument(parsing: "## Tips\n\nText.\n\n## Other\n\n### Tips\n\n## Tips\n\n## Tips {#more-tips}")

		#expect(document.problems.map(\.line) == [9])
		#expect(document.problems.map(\.reason) == ["The page already has a section “Tips” (line 1). Give the sections different headings."])
	}

	/**
	The decoder reports a missing key before an unknown one, but a misspelled key is the likely cause.
	*/
	@Test
	func `an unknown inline attribute is named with the closest known one`() {
		let options = MarkdownDocument.Options(
			inlineAttributes: .init { (attributes: BadgeAttributes, html) in
				"<b>\(html)</b>"
			}
		)
		let document = MarkdownDocument(parsing: #"^[Spotlight](notes: "The search.") and ^[Mac](platfrom: "macOS")"#, options: options)

		#expect(document.problems.map(\.reason) == [
			#"Unknown attribute `notes` in `notes: "The search."`. Did you mean `note`?"#,
			#"Unknown attribute `platfrom` in `platfrom: "macOS"`. Did you mean `platform`?"#,
		])
		#expect(document.html.contains("Spotlight and Mac"))
	}

	@Test
	func `the closing punctuation after a shortcut of more than one key stays on its line`() {
		let html = MarkdownDocument(parsing: "Press ++Shift+Command+V++), ++Q++, or ++Control+C++ to stop.").html

		#expect(html.contains(#"Press <span class="keyboard-shortcut-with-punctuation"><kbd class="keyboard-shortcut" translate="no"><kbd>Shift</kbd>"#))
		#expect(html.contains(#"<kbd>V</kbd></kbd>),</span> <kbd translate="no">Q</kbd>, or <kbd class="keyboard-shortcut" translate="no">"#))
		#expect(html.contains(#"<kbd>C</kbd></kbd> to stop."#))
	}

	@Test
	func `shortcut parts own punctuation without requiring alternating text fragments`() {
		let parts = "Copy (++Command+K++), ++Q++!"[...].keyboardShortcutParts
		let fragments = parts.map { part in
			switch part {
			case .text(let text):
				"text: \(text)"
			case .shortcut(let text, let openingPunctuation, let punctuation):
				"shortcut: \(text) opening: \(openingPunctuation) punctuation: \(punctuation)"
			}
		}

		#expect(fragments == ["text: Copy ", "shortcut: Command+K opening: ( punctuation: ),", "text:  ", "shortcut: Q opening:  punctuation: !"])
		#expect(MarkdownDocument(parsing: "Copy (++Command+K++), ++Q++!").introduction == "Copy (Command+K), Q!")
		#expect(MarkdownDocument(parsing: "Copy (++Shift+Command+V++) now.").html.contains(#"Copy <span class="keyboard-shortcut-with-punctuation">(<kbd class="keyboard-shortcut" translate="no"><kbd>Shift</kbd>"#))
	}

	@Test
	func `link suppression is restored for following sibling links`() {
		let source = #"^[Term](note: "Note.") [Following](/after)"#
		let document = MarkdownDocument(parsing: source)
		#expect(document.problems.isEmpty)
		#expect(document.html.contains(#"<a href="/after">Following</a>"#))

		let sections = MarkdownDocument(parsing: "## Question\n\n[Inside](/inside)\n\n# After\n\n[Following](/after)", options: .init(collapsibleSections: .init(level: .h2)))
		#expect(sections.problems.isEmpty)
		#expect(sections.links.map(\.destination) == ["/inside", "/after"])
		#expect(sections.html.contains(#"<a href="/inside">Inside</a>"#))
		#expect(sections.html.contains(#"<a href="/after">Following</a>"#))
	}

	@Test
	func `a rejected note inside a link restores sibling notes and their links`() throws {
		let document = MarkdownDocument(parsing: #"[Link ^[inside](note: "Ignored.")](/outer) ^[Term](note: "See [Note link](/inside).") [Following](/after)"#)

		#expect(document.problems.count == 1)
		let problem = try #require(document.problems.first)
		#expect(problem.reason.contains("inside a link"))
		#expect(document.html.contains(#"<a href="/outer">Link inside</a>"#))
		#expect(!document.html.contains("Ignored."))
		#expect(document.html.contains(#"See <a href="/inside">Note link</a>."#))
		#expect(document.html.contains(#"<a href="/after">Following</a>"#))
		#expect(document.links.map(\.destination) == ["/outer", "/inside", "/after"])
	}

	@Test
	func `the keys of a shortcut have their names on the keyboard of a Mac`() {
		let reasons = MarkdownDocument(parsing: "Press ++Cmd+K++, ++⌥⌘V++, ++command+k++, or ++Command+⌫++.").problems.map(\.reason)

		#expect(reasons == [
			"Write the key `Cmd` of the keyboard shortcut `Cmd+K` as `Command`, its name on the keyboard of a Mac.",
			"Write the key `⌥⌘V` of the keyboard shortcut `⌥⌘V` as `Option+Command+V`, its name on the keyboard of a Mac.",
			"Write the key `command` of the keyboard shortcut `command+k` as `Command`, its name on the keyboard of a Mac.",
			"Write the key `k` of the keyboard shortcut `command+k` as `K`, its name on the keyboard of a Mac.",
		])
		#expect(MarkdownDocument(parsing: "Press ++Esc++, ++Fn++, ++Option+◀++, or ++Shift+Command+,++.").problems.isEmpty)

		// A common name of another keyboard gets the name of the key, not a hint to add a key.
		#expect(MarkdownDocument(parsing: "Press ++Escape++, ++Command+Spacebar++, or ++Command+Up Arrow++.").problems.map(\.reason) == [
			"Write the key `Escape` of the keyboard shortcut `Escape` as `Esc`, its name on the keyboard of a Mac.",
			"Write the key `Spacebar` of the keyboard shortcut `Command+Spacebar` as `Space`, its name on the keyboard of a Mac.",
			"Write the key `Up Arrow` of the keyboard shortcut `Command+Up Arrow` as `▲`, its name on the keyboard of a Mac.",
		])
	}

	/**
	A suggestion is always the name of a key, so a misspelled key is not suggested with a capital letter.
	*/
	@Test
	func `a key in another case gets its name, and a misspelled key gets no name`() {
		#expect(MarkdownDocument(parsing: "Press ++page up++, ++ESC++, ++Command+plus++, or ++enterr++.").problems.map(\.reason) == [
			"Write the key `page up` of the keyboard shortcut `page up` as `Page Up`, its name on the keyboard of a Mac.",
			"Write the key `ESC` of the keyboard shortcut `ESC` as `Esc`, its name on the keyboard of a Mac.",
			"Write the key `plus` of the keyboard shortcut `Command+plus` as `Plus`, its name on the keyboard of a Mac.",
			"`enterr` of the keyboard shortcut `enterr` is not a key of a Mac keyboard. Write the name on the key, like `Return` or `K`, or add the key to `KeyboardKey.keyNames`.",
		])
	}

	@Test
	func `a shortcut with modifier glyphs is corrected with the name of its key too`() {
		let reasons = MarkdownDocument(parsing: "Press ++⌘c++.").problems.map(\.reason)

		#expect(reasons == ["Write the key `⌘c` of the keyboard shortcut `⌘c` as `Command+C`, its name on the keyboard of a Mac."])
		#expect(KeyboardKey.correctedShortcut("cmd+c") == "Command+C")
		#expect(KeyboardKey.correctedShortcut("⌥⌘v") == "Option+Command+V")
		#expect(KeyboardKey.correctedShortcut("Command+") == "Command+Plus")
	}

	/**
	The corrected shortcut must pass the check of the order of the modifiers, or following the suggestion would be another problem.
	*/
	@Test
	func `a corrected shortcut has the modifiers in the order of Apple`() {
		#expect(KeyboardKey.correctedShortcut("cmd+shift+k") == "Shift+Command+K")
		#expect(KeyboardKey.correctedShortcut("⌘⇧k") == "Shift+Command+K")
		#expect(KeyboardKey.correctedShortcut("ctrl+alt+del") == "Control+Option+Delete")
		#expect(KeyboardKey.correctedShortcut("opt+esc") == "Option+Esc")
		#expect(MarkdownDocument(parsing: "Press ++⌘⇧K++.").problems.map(\.reason).contains { $0.contains("as `Shift+Command+K`") })
	}

	/**
	Smart punctuation makes a quote typographic, but the key is the straight quote on the keyboard, which is not a glyph without a name.
	*/
	@Test
	func `a quote key is the straight quote of the keyboard`() {
		let document = MarkdownDocument(parsing: "Press ++Command+'++ or ++Shift+Command+\"++.")

		#expect(document.problems.isEmpty)
		#expect(document.html.contains("<kbd>'</kbd>"))
		#expect(document.html.contains("<kbd>&quot;</kbd>"))
	}

	/**
	A screen reader would read the Unicode name of the glyph, like “black left-pointing triangle”.
	*/
	@Test
	func `a glyph key has its name for screen readers, and a glyph without a name is a problem`() {
		let document = MarkdownDocument(parsing: "Press ++Command+◀++, <kbd>▶</kbd>, or ++★++.")

		#expect(document.html.contains(#"<kbd>Command</kbd><span class="key-separator" aria-hidden="true">+</span><kbd><span role="img" aria-label="Left Arrow">◀</span></kbd>"#))
		#expect(document.html.contains(#"<kbd translate="no"><span role="img" aria-label="Right Arrow">▶</span></kbd>"#))
		#expect(document.problems.map(\.reason) == ["The key `★` of the keyboard shortcut `★` is a glyph without a name for screen readers. Write the name of the key, or add the glyph to `KeyboardKey.Glyph`."])
	}

	@Test
	func `a key that a Mac keyboard does not have is a problem`() {
		let document = MarkdownDocument(parsing: "Press ++Command+Enterr++, ++Shift+F12++, ++Option+Page Down++, ++Command+/++, or ++Win+R++.")

		#expect(document.problems.map(\.reason) == ["`Enterr` of the keyboard shortcut `Command+Enterr` is not a key of a Mac keyboard. Write the name on the key, like `Return` or `K`, or add the key to `KeyboardKey.keyNames`."])
	}

	@Test
	func `a shortcut without its closing plus signs is a problem, but C++ is text`() {
		let document = MarkdownDocument(parsing: "Press ++Command+N to make an event.\n\nWrite C++ and C++17, add a ++ b, or press ++Q++.")

		#expect(document.problems.map(\.line) == [1])
		#expect(document.problems.first?.reason == "The text has a `++` without its closing `++`, so the page shows the plus signs. Write a keyboard shortcut like `++Command+N++`.")
	}

	@Test
	func `a table without its delimiter row is a problem`() {
		let document = MarkdownDocument(parsing: "| A | B |\n| 1 | 2 |\n\n| A | B |\n| - | - |\n| 1 | 2 |\n\nA | B")

		#expect(document.problems.map(\.line) == [1])
		#expect(document.problems.first?.reason == "The table has no delimiter row below its header, like `| --- | --- |`, so the page shows the pipes.")
	}

	@Test
	func `the plus key is written as Plus`() {
		let document = MarkdownDocument(parsing: "Press ++Command+Plus++.")
		#expect(document.html.contains(#"<kbd>Command</kbd><span class="key-separator" aria-hidden="true">+</span><kbd>+</kbd>"#))
		#expect(document.problems.isEmpty)
	}

	@Test
	func `raw details and summary are a problem when there is a Details directive`() {
		let options = MarkdownDocument.Options(blockDirectives: ["Details": .init { (contentHTML: String) in contentHTML }])
		#expect(MarkdownDocument(parsing: "Text.\n\n<details>\n<summary>Why?</summary>\n\nBecause.\n\n</details>", options: options).problems.map(\.line) == [3])
		#expect(MarkdownDocument(parsing: "Text.\n\n<!-- <details></details> -->", options: options).problems.isEmpty)
		#expect(MarkdownDocument(parsing: "<details><summary>Why?</summary></details>").problems.isEmpty)
		#expect(MarkdownDocument(parsing: "Text <!-- <details> --> more.", options: options).problems.isEmpty)
		#expect(MarkdownDocument(parsing: "Text <details-panel>more</details-panel>.", options: options).problems.isEmpty)
		#expect(!MarkdownDocument(parsing: "Text <details open>more</details>.", options: options).problems.isEmpty)
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
		let document = MarkdownDocument(
			parsing: "Intro.\n\nSee [Dato](dato.md) and [broken](nope.md).",
			options: .init(
				resolveLink: { (destination: String) throws(ContentError) in
					guard destination != "nope.md" else {
						throw ContentError(reason: "The linked file does not exist.")
					}

					return destination == "dato.md" ? "/dato" : destination
				}
			)
		)

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
		#expect(document.headings.map(\.id.rawValue) == ["section", "section-1"])
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
		let options = MarkdownDocument.Options(collapsibleSections: .init(level: .h3))
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
	func `directive content rewrites return blocks and keep their rendered links`() {
		let options = MarkdownDocument.Options(blockDirectives: [
			"Box": .init(
				rewriteContent: { content -> [any BlockMarkup] in
					[BlockQuote(content)]
				},
				render: { "<section>\($0)</section>" }
			),
		])
		let document = MarkdownDocument(parsing: "@Box {\n[Inside](/inside)\n}", options: options)

		#expect(document.problems.isEmpty)
		#expect(document.html == "<section><blockquote>\n<p><a href=\"/inside\">Inside</a></p>\n</blockquote>\n</section>\n")
		#expect(document.links.map(\.destination) == ["/inside"])
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
		// An unknown key is reported before a missing one, as it is often a misspelling.
		#expect(document.problems[0].reason == "Unknown attribute `size` in `size: 2`. Known attributes: `note`, `platform`.")
		// The attributes that cannot be parsed say what is wrong.
		#expect(document.problems[1].reason.hasPrefix("The inline attributes `platform: ` are invalid: Expected a value"))
		#expect(document.problems[3].reason == "`@Box`: Missing required key `title`.")
		#expect(document.problems[4].reason == "`@Plain`: It takes no arguments.")
	}

	/**
	A check of the content reads the arguments like the renderer, also of a directive inside another one.
	*/
	@Test
	func `the typed arguments of directives can be read from the tree`() throws {
		let document = Document(parsing: "@Box(title: \"One\") {\n  Text.\n}\n\n@Plain {\n  @Box(title: \"Two\") {\n    Text.\n  }\n}\n\n@Box(name: \"Invalid\") {\n  Text.\n}", options: .parseBlockDirectives)
		let boxes = document.blockDirectives.filter { $0.name == "Box" }

		#expect(try boxes.prefix(2).map { try $0.arguments(as: BoxArguments.self).title } == ["One", "Two"])
		#expect(boxes.map { $0.range?.lowerBound.line } == [1, 6, 11])
		#expect(throws: ContentErrors.self) {
			try boxes[2].arguments(as: BoxArguments.self)
		}
	}

	/**
	A directive that shows a list as steps or cards needs one list. Indented content is the usual mistake: swift-markdown removes the indentation of the first line from each line, so a nested list becomes part of the outer list, which is split.
	*/
	@Test
	func `a block directive can require one list or no content`() {
		let options = MarkdownDocument.Options(blockDirectives: [
			"Steps": .init(content: .orderedList) { html in "<div>\(html)</div>" },
			"Cards": .init(content: .unorderedList) { html in "<div>\(html)</div>" },
			"Links": .init(content: .empty) { _ in "<ul></ul>" },
		])

		func reasons(_ markdown: String) -> [String] {
			MarkdownDocument(parsing: markdown, options: options).problems.map(\.reason)
		}

		let hint = " A nested list must be indented more than its item, and the content of the directive must not be indented."
		#expect(reasons("@Steps {\n1. One\n   - Detail\n2. Two\n}").isEmpty)
		// A comment is not shown, so it does not count.
		#expect(reasons("@Cards {\n<!-- Draft -->\n\n- One\n}").isEmpty)
		#expect(reasons("@Links").isEmpty)
		#expect(reasons("@Steps {\n\t1. One\n\t\t- Detail\n\t2. Two\n}") == ["`@Steps` must contain one numbered list, and it has 3 blocks." + hint])
		#expect(reasons("@Steps {\nFirst:\n\n1. One\n}") == ["`@Steps` must contain one numbered list, and it has 2 blocks."])
		#expect(reasons("@Steps {\n- One\n}") == ["`@Steps` must contain one numbered list, and it has a bulleted list."])
		#expect(reasons("@Cards {\nText.\n}") == ["`@Cards` must contain one bulleted list, and it has a paragraph."])
		#expect(reasons("@Cards {\n}") == ["`@Cards` must contain one bulleted list, and it has no content."])
		#expect(reasons("@Links {\nText.\n}") == ["`@Links` takes no content."])
		#expect(MarkdownDocument(parsing: "@Cards {\nText.\n}", options: options).html == "<p>Text.</p>\n")
	}

	/**
	An empty directive is a lost edit, like a deleted list, but a directive without braces has no content.
	*/
	@Test
	func `a block directive with empty braces is a problem`() {
		let options = MarkdownDocument.Options(blockDirectives: [
			"Tips": .init { html in "<aside>\(html)</aside>" },
			"Box": .init { (_: BoxArguments, html) in "<section>\(html)</section>" },
		])

		func reasons(_ markdown: String) -> [String] {
			MarkdownDocument(parsing: markdown, options: options).problems.map(\.reason)
		}

		let reason = "has no content. Write it between the braces, or remove the directive."
		#expect(reasons("@Tips {\n}") == ["`@Tips` \(reason)"])
		#expect(reasons("@Tips {\n<!-- Later -->\n}") == ["`@Tips` \(reason)"])
		#expect(reasons("@Box(title: \"Hi\") {\n\n}") == ["`@Box` \(reason)"])
		#expect(reasons("@Box(title: \"Hi\")").isEmpty)
		#expect(reasons("@Box(\n\ttitle: \"Hi\"\n)").isEmpty)
		#expect(reasons("@Tips {\n- Tip\n}").isEmpty)
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
		## Press ++Command+K++[^heading] {#press}

		- Item
			: Subtitle[^list]

		[^heading]: Heading note.
		[^list]: List note.
		""")

		#expect(document.html.contains("<kbd>Command</kbd>"))
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

struct PlainMarkdownRewriterTests {
	@Test
	func `change tracking stays cumulative while unchanged subtrees keep their identity`() throws {
		var rewriter = PlainMarkdownRewriter(linkDestination: { $0 }, blockDirective: { Array($0.blockChildren) })
		let unchanged = Document(parsing: "> Keep *this* [link](/page).")
		let firstResult = rewriter.visit(unchanged)
		let first = try #require(firstResult)
		#expect(first.isIdentical(to: unchanged))
		#expect(!rewriter.didChange)

		let changed = Document(parsing: """
		## Changed {#changed}

		@Box {
		Press ++Command+K++.
		}

		Plain *end*.
		""", options: .parseBlockDirectives)
		let changedResult = rewriter.visit(changed)
		#expect(changedResult?.format() == "## Changed\n\nPress Command+K.\n\nPlain *end*.")
		#expect(rewriter.didChange)

		let lastResult = rewriter.visit(unchanged)
		let last = try #require(lastResult)
		#expect(last.isIdentical(to: unchanged))
		#expect(rewriter.didChange)
	}

	private static func plain(_ markdown: String) -> (markdown: String, didChange: Bool) {
		var rewriter = PlainMarkdownRewriter { directive in
			[Paragraph(Strong(Markdown.Text(directive.name)))] + Array(directive.blockChildren)
		}

		let markdown = rewriter.visit(Document(parsing: markdown, options: .parseBlockDirectives))?.format() ?? ""
		return (markdown, rewriter.didChange)
	}

	@Test
	func `the syntax of the site becomes plain Markdown`() {
		let result = Self.plain("## Shortcuts {#shortcuts}\n<!-- @faq.keywords keys -->\n\nPress ++Shift+Command+N++ in ^[Spotlight](note: \"The *search* of macOS.\") to add a ^[macOS only](platform: \"macOS\") note.\n\n@Feature(title: \"Fast\") {\nPress ++Q++.\n}")

		#expect(result.didChange)
		#expect(result.markdown == "## Shortcuts\n\nPress Shift+Command+N in Spotlight (The *search* of macOS.) to add a (macOS only) note.\n\n**Feature**\n\nPress Q.")
	}

	@Test
	func `Markdown without the syntax of the site is not changed`() {
		let result = Self.plain("## Install\n\nRun `++x++` and C++.")

		#expect(!result.didChange)
		#expect(result.markdown == "## Install\n\nRun `++x++` and C++.")
	}

	@Test
	func `a platform badge in the text of a note becomes plain text too`() {
		let result = Self.plain(#"The ^[^[Spotlight](platform: "macOS") search](note: "The search.") app."#)

		#expect(result.markdown == "The (Spotlight) search (The search.) app.")
	}

	@Test
	func `inline comments are removed, and a note with several paragraphs is one parenthesis`() {
		let result = Self.plain(#"Text <!-- @faq.keywords x --> and ^[A](note: "One.\n\nTwo.")."#)

		#expect(result.didChange)
		#expect(result.markdown == "Text  and A (One. Two.).")
	}

	@Test
	func `a heading loses an invalid ID too`() {
		#expect(Self.plain("## Install {#with gifski}").markdown == "## Install")
	}
}

struct MarkdownLinkTests {
	private static let options = MarkdownDocument.Options(
		resolveLink: { destination in
			destination.hasSuffix(".md") ? "/" + destination.dropLast(3) : destination
		}
	)

	/**
	The links in the first paragraph of an alert and in footnote definitions are resolved and listed once, like a link in the text.
	*/
	@Test(arguments: ["> [!NOTE]\n> See [the FAQ](faq.md).", "Text[^note].\n\n[^note]: See [the FAQ](faq.md)."])
	func `links in alerts and footnote definitions are resolved and listed`(markdown: String) {
		let document = MarkdownDocument(parsing: markdown, options: Self.options)

		#expect(document.html.contains(#"<a href="/faq">the FAQ</a>"#))
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
		let options = MarkdownDocument.Options(
			inlineNote: { textHTML, noteID in
				"<x-note for=\"\(noteID)\">\(textHTML)</x-note>"
			}
		)

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
		"""#, options: .init(
			resolveLink: { (destination: String) throws(ContentError) in
				guard destination != "missing.md" else {
					throw ContentError(reason: "Missing.")
				}

				return destination
			}
		))

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
	func `the links that a directive renders from its arguments are at its line, and its content keeps the lines of its own links`() {
		let options = MarkdownDocument.Options(
			blockDirectives: [
				"Icon": .init { (arguments: BoxArguments, html) in
					"<div><img src=\"\(arguments.title)\" alt=\"\">\(html)</div>"
				},
			]
		)

		let document = MarkdownDocument(parsing: "Intro.\n\n@Icon(title: \"/a.png\") {\n  See [B](/b).\n}", options: options)

		#expect(document.links.map { "\($0.line?.rawValue ?? 0): \($0.destination)" } == ["4: /b", "3: /a.png"])
	}

	@Test
	func `nested directive links keep their own lines without duplicates and decode HTML escapes`() {
		let options = MarkdownDocument.Options(blockDirectives: [
			"Icon": .init { (arguments: BoxArguments, html) in
				"<div><img src=\"\(arguments.title.escapedForHTML)\" alt=\"\">\(html)</div>"
			},
		])
		let document = MarkdownDocument(parsing: "@Icon(title: \"/outer.png?a=1&b=2\") {\n@Icon(title: \"/inner.png\") {\nSee [B](/b).\n}\n}", options: options)

		#expect(document.problems.isEmpty)
		#expect(document.links.map { "\($0.line?.rawValue ?? 0): \($0.destination)" } == ["3: /b", "2: /inner.png", "1: /outer.png?a=1&b=2"])
	}

	@Test
	func `links rendered by a directive from another file keep that file and its line`() {
		let otherFile = URL(filePath: "/shared.md")
		let options = MarkdownDocument.Options(
			rewrite: { document in
				let added = Document(parsing: "Intro.\n\n@Icon(title: \"/icon.png\")", source: otherFile, options: .parseBlockDirectives)
				return Document(Array(document.blockChildren) + Array(added.blockChildren.dropFirst()))
			},
			blockDirectives: [
				"Icon": .init { (arguments: BoxArguments, html) in
					"<div><img src=\"\(arguments.title)\" alt=\"\">\(html)</div>"
				},
			]
		)
		let document = MarkdownDocument(parsing: "Own text.", options: options)

		#expect(document.problems.isEmpty)
		#expect(document.links.map(\.destination) == ["/icon.png"])
		#expect(document.links.map(\.otherFile) == [otherFile])
		#expect(document.links.map(\.line) == [3])
	}

	@Test
	func `a link without text is a problem, but not a link with only an image`() {
		let document = MarkdownDocument(parsing: "See [](https://example.com) and [ ](/a).\n\n[![Icon](/icon.png)](/b)")

		#expect(document.problems.map(\.line) == [1, 1])
		#expect(document.problems.first?.reason == "The link to `https://example.com` has no text, so it is not visible, and screen readers have no name for it. Write its text, like `[Dato](https://example.com)`.")
	}

	@Test
	func `a link with an HTML image inside emphasis has a name`() {
		let document = MarkdownDocument(parsing: #"[**<img src="/icon.png" alt="Icon">**](/app)"#)

		#expect(document.html.contains(#"<strong><img src="/icon.png" alt="Icon"></strong>"#))
		#expect(document.problems.isEmpty)
	}

	@Test
	func `an inline note in the heading of a collapsible section is a problem`() throws {
		let options = MarkdownDocument.Options(collapsibleSections: .init(level: .h3))
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
private func tokens(of parts: [CodePart]) -> [String] {
	parts.compactMap { part in
		part.token.map { "\($0.rawValue) \(part.text)" }
	}
}

private enum Keywords: HeadingDirective {
	static let name: HeadingDirectiveName = "faq.keywords"
	typealias Value = [String]
}

private enum OtherKeywords: HeadingDirective {
	static let name = Keywords.name
	typealias Value = HeadingDirectiveFlag
}

private enum Platforms: HeadingDirective {
	static let name: HeadingDirectiveName = "faq.platforms"
	typealias Value = [String]
}

private enum General: HeadingDirective {
	static let name: HeadingDirectiveName = "faq.general"
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
		let html = MarkdownDocument(releaseNotes: source).html
		#expect(!html.contains("<script>"))
		#expect(!html.contains("<iframe"))
		#expect(!html.contains("<table"))
		#expect(!html.contains("<img src=x"))
		#expect(!html.contains("<kbd onclick"))
		#expect(html.contains("&lt;"))
	}

	@Test(arguments: ["javascript:alert(1)", "JAVASCRIPT:alert(1)", "data:text/html,evil", "file:///etc/passwd", "vbscript:evil"])
	func `external release notes disable unsafe destinations`(destination: String) {
		let html = MarkdownDocument(releaseNotes: "[Link](\(destination)) ![Image](\(destination))").html
		#expect(html.hasPrefix("<p>Link <img"))
		#expect(!html.contains("<a"))
		#expect(!html.contains("src=\"\(destination)\""))
	}

	@Test(arguments: ["&#32;javascript:alert(1)", "&#x20;JAVASCRIPT:alert(1)", "&#32;data:text/html,evil"])
	func `entity decoded spaces cannot conceal executable schemes`(destination: String) {
		let html = MarkdownDocument(releaseNotes: "[Link](\(destination))").html
		#expect(html == "<p>Link</p>\n")
		#expect(!html.lowercased().contains("javascript:"))
		#expect(!html.contains("data:text/html"))
	}

	@Test
	func `release notes retain Markdown and safe destinations`() {
		let html = MarkdownDocument(releaseNotes: "**Fixed** [Issue](https://github.com/test/repo/issues/1) ![Preview](https://example.com/image.png)").html
		#expect(html.contains("<strong>Fixed</strong>"))
		#expect(html.contains("href=\"https://github.com/test/repo/issues/1\""))
		#expect(html.contains("src=\"https://example.com/image.png\""))
	}
}

extension MarkdownTests {
	@Test
	func `heading metadata belongs to its registered directive type`() throws {
		enum Registered: HeadingDirective {
			static let name: HeadingDirectiveName = "test.words"
			typealias Value = [String]
		}

		enum Unregistered: HeadingDirective {
			static let name: HeadingDirectiveName = "test.words"
			typealias Value = [String]
		}

		let document = MarkdownDocument(parsing: "## Heading {#heading}\n<!-- @test.words one two -->", options: .init(headingDirectives: [Registered.self]))
		let heading = try #require(document.headings.first)
		#expect(document.problems.isEmpty)
		#expect(heading[Registered.self] == ["one", "two"])
		#expect(heading[Unregistered.self] == nil)
		#expect(!heading.contains(Unregistered.self))
	}

	@Test
	func `heading provenance stays attached to its identifier`() throws {
		let headings = MarkdownDocument(parsing: "## Authored {#fixed}\n\n## Generated").headings
		let authored = try #require(headings.first)
		let generated = try #require(headings.last)
		guard
			case .authored(let authoredID) = authored.identity,
			case .generated(let generatedID) = generated.identity
		else {
			Issue.record("Heading ID provenance was lost")
			return
		}

		#expect(authoredID.rawValue == "fixed")
		#expect(generatedID.rawValue == "generated")
		#expect(authored.hasCustomID)
		#expect(!generated.hasCustomID)
	}

	@Test
	func `comment detection distinguishes HTML following a comment`() {
		#expect(HTMLBlock("<!-- author note -->\n\t<!-- another -->").isCommentOnly)
		#expect(!HTMLBlock("<!-- author note --><div>Visible</div>").isCommentOnly)
		#expect(!Paragraph(Markdown.Text("Text")).isCommentOnly)
	}

	@Test
	func `paragraph blocks keep inline markup without parsing their wrapper`() throws {
		let document = MarkdownDocument(parsing: "A <span title=\"a > b\">value</span> and `</p>`.\n\n## Next")
		guard case .paragraph(let inlineHTML, let isBoldLabel) = document.blocks.first?.kind else {
			Issue.record("Expected a structured paragraph")
			return
		}

		#expect(!isBoldLabel)
		#expect(inlineHTML.contains("<span title=\"a > b\">value</span>"))
		let separated = try #require(document.contentSeparatingIntroduction)
		#expect(separated.introduction.html == inlineHTML)
		#expect(document.blocks.first?.html == "<p>\(inlineHTML)</p>\n")
	}

	@Test
	func `typed Markdown links serialize destinations and escape their labels`() throws {
		let link = Markdown.Link(destination: .path(#path("/guide"), query: [URLQueryItem(name: "q", value: "a&b")], fragment: "steps"), text: "<Guide> & help")
		let rendered = try ParsedMarkdown(blocks: [Paragraph(link)]).rendered()
		#expect(rendered.inlineHTML == #"<a href="/guide?q=a%26b#steps">&lt;Guide&gt; &amp; help</a>"#)
	}

	@Test
	func `single section split keeps trailing popovers only with the remainder`() throws {
		let document = MarkdownDocument(parsing: "## Start {#start}\n\nText[^note].\n\n[^note]: A note.")
		let split = try #require(document.content.separated(beforeHeading: ElementID("start")))
		#expect(split.before.html.isEmpty)
		#expect(split.after.html == document.html)
		#expect(document.content.separated(beforeHeading: ElementID("missing")) == nil)
	}
}

extension MarkdownTests {
	@Test(arguments: ["faq.keywords", "a-b", "-", "déjà.東京", "a_b", "0", ".", "a-"])
	func `heading directive names preserve the comment parser grammar`(spelling: String) throws {
		let name = try HeadingDirectiveName(validating: spelling)
		let comment = try #require(DirectiveComment(line: "<!-- @\(spelling) -->"[...]))

		#expect(name.rawValue == spelling)
		#expect(name.description == spelling)
		#expect(comment.name == name)
		#expect(comment.values.isEmpty)
		#expect(comment.isOnOwnLine)
	}

	@Test(arguments: ["", "a b", "a--b", "@faq", "faq/words", "faq:words", "\n"])
	func `heading directive names reject unparseable spellings`(spelling: String) {
		#expect(throws: ContentError.self) {
			try HeadingDirectiveName(validating: spelling)
		}
	}

	@Test
	func `invalid heading directive literals fail at construction`() async {
		await #expect(processExitsWith: .failure) {
			let _: HeadingDirectiveName = "invalid--name"
		}
	}

	@Test
	func `registered Unicode and hyphenated directive names attach to headings`() throws {
		enum Words: HeadingDirective {
			static let name: HeadingDirectiveName = "詳しい.faq-words"
			typealias Value = [String]
		}

		let document = MarkdownDocument(parsing: "## Title\n<!-- @詳しい.faq-words one two -->", options: .init(headingDirectives: [Words.self]))
		#expect(document.problems.isEmpty)
		#expect(document.headings.first?[Words.self] == ["one", "two"])
	}

	@Frontmatter
	struct CheckedArguments {
		var first: String
		var second: String

		func validate(into problems: inout FrontmatterProblems<Self>) {
			problems.add("First invalid.", at: .first)
			problems.add("Second invalid.", at: .second)
		}
	}

	@Test
	func `typed rendering callbacks preserve aggregate argument diagnostics and fallback content`() throws {
		let renderer = MarkdownDocument.Options.BlockDirectiveRenderer { (_: CheckedArguments, _: String) in
			"Must not render invalid arguments."
		}
		let source = "@Check(first: \"one\", second: \"two\") {\nFallback.\n}"
		let directive = try #require(Document(parsing: source, options: .parseBlockDirectives).blockDirectives.first)
		let errors = try #require(throws: ContentErrors.self) {
			try renderer.render(directive.parsedArguments(), "Fallback.", .init(documentOptions: .init()))
		}

		#expect(errors.errors.map(\.reason) == ["First invalid.", "Second invalid."])
		let document = MarkdownDocument(parsing: source, options: .init(blockDirectives: ["Check": renderer]))
		#expect(document.html == "<p>Fallback.</p>\n")
		#expect(document.problems.map(\.line) == [1])
		#expect(document.problems.first?.reason == "`@Check`: First invalid.\nSecond invalid.")
	}

	@Test
	func `typed customization failures retain source lines and supported fallbacks`() {
		let options = MarkdownDocument.Options(
			inlineAttributes: .init { (_: BadgeAttributes, _: String) throws(ContentError) in
				throw ContentError(reason: "Cannot render badge.")
			},
			blockDirectives: [
				"Render": .init { (_: String) throws(ContentError) in
					throw ContentError(reason: "Cannot render block.")
				},
				"Rewrite": .init(
					rewriteContent: { (_: [any BlockMarkup]) throws(ContentError) in
						throw ContentError(reason: "Cannot rewrite block.")
					},
					render: { "<section>\($0)</section>" }
				),
			],
			resolveLink: { (_: String) throws(ContentError) in
				throw ContentError(reason: "Cannot resolve link.")
			}
		)
		let document = MarkdownDocument(parsing: "[Link](/original)\n\n^[Badge](platform: \"macOS\")\n\n@Render {\nRendered content.\n}\n\n@Rewrite {\nOriginal content.\n}", options: options)

		#expect(document.problems.map(\.line) == [1, 3, 5, 9])
		#expect(document.problems.map(\.reason) == [
			"Cannot resolve link.",
			"The inline attributes `platform: \"macOS\"` are invalid: Cannot render badge.",
			"`@Render`: Cannot render block.",
			"`@Rewrite`: Cannot rewrite block.",
		])
		#expect(document.html == "<p><a href=\"/original\">Link</a></p>\n<p>Badge</p>\n<p>Rendered content.</p>\n<p>Original content.</p>\n")
		#expect(document.links.map(\.destination) == ["/original"])
	}
}
