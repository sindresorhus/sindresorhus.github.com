import Testing
import SiteKit

@Suite
struct HTMLSanitizerTests {
	@Test
	func `removes unsafe HTML and keeps text structure`() {
		let sanitized = """
		<!-- private -->
		<p>Hello <a href="https://example.com" class="x" onclick="steal()">site</a>.</p>
		<img src="https://example.com/a.png">
		<script>alert(1)</script>
		<a href="javascript:alert(1)">bad</a>
		<br>
		""".sanitizedHTML

		#expect(!sanitized.contains("private"))
		#expect(sanitized.contains(#"<p>Hello <a href="https://example.com">site</a>.</p>"#))
		#expect(!sanitized.contains("<img"))
		#expect(!sanitized.contains("alert(1)"))
		#expect(sanitized.contains("<a>bad</a>"))
		#expect(sanitized.contains("<br />"))
	}

	@Test
	func `does not let removed tags join text into new tags`() {
		let sanitized = "<<x>script>alert(1)<</x>/script> 1 < 2 <b>bold</b>".sanitizedHTML

		#expect(!sanitized.contains("<script"))
		#expect(sanitized == "&lt;script&gt;alert(1)&lt;/script&gt; 1 &lt; 2 <b>bold</b>")
	}

	@Test
	func `keeps entities in link URLs as they are`() {
		#expect(#"<a href="https://example.com/?a=1&amp;b=2">Link</a>"#.sanitizedHTML == #"<a href="https://example.com/?a=1&amp;b=2">Link</a>"#)
	}

	@Test(arguments: [
		#"<a href="javascript&#58;alert(1)">x</a>"#,
		#"<a href="javascript&colon;alert(1)">x</a>"#,
		#"<a href="&#106;avascript:alert(1)">x</a>"#,
		#"<a href="java&#x09;script:alert(1)">x</a>"#,
	])
	func `rejects scripts hidden with entities`(html: String) {
		#expect(html.sanitizedHTML == "<a>x</a>")
	}

	@Test
	func `removes characters that XML does not allow`() {
		#expect("<p>a&#0;b&#x1;c&#65;&#x9;</p>".sanitizedHTML == "<p>abc&#65;&#x9;</p>")
		#expect(#"<a href="https://example.com/&#0;a">x</a>"#.sanitizedHTML == #"<a href="https://example.com/a">x</a>"#)
	}
}
