import Testing
@testable import SiteKit

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
