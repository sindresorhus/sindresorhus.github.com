import Testing
@testable import SiteKit

struct EscapingTests {
	@Test
	func `empty collections become nil without trimming their elements`() {
		let empty: [Int] = []
		#expect(empty.nilIfEmpty == nil)
		#expect([1, 2].nilIfEmpty == [1, 2])
		#expect("".nilIfEmpty == nil)
		#expect(" ".nilIfEmpty == " ")
		#expect("text".nilIfEmpty == "text")
	}

	@Test
	func `Windows line normalization preserves lone CR and trailing newlines`() {
		#expect("a\r\nb\rc\n".normalizingWindowsLineEndings == "a\nb\rc\n")
		#expect("".normalizingWindowsLineEndings == "")
		#expect("a\nb\n".normalizingWindowsLineEndings == "a\nb\n")
	}

	@Test
	func `text is escaped, and text without special characters stays the same`() {
		#expect(#"Tom & “Jerry” <3 "quoted" >"#.escapedForHTML == "Tom &amp; “Jerry” &lt;3 &quot;quoted&quot; &gt;")
		#expect("&amp;".escapedForHTML == "&amp;amp;")
		#expect("Plain text, café 🦄".escapedForHTML == "Plain text, café 🦄")
		#expect("".escapedForHTML == "")
	}

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
