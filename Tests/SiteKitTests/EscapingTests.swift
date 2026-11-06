import Elementary
import Foundation
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

struct HTMLAttributeTests {
	@Test
	func `pressed states support mixed toggles while preserving Boolean output`() {
		#expect(button(.ariaPressed(.on)) {}.render() == #"<button aria-pressed="true"></button>"#)
		#expect(button(.ariaPressed(.off)) {}.render() == #"<button aria-pressed="false"></button>"#)
		#expect(button(.ariaPressed(.mixed)) {}.render() == #"<button aria-pressed="mixed"></button>"#)
		#expect(button(.ariaPressed(true)) {}.render() == button(.ariaPressed(.on)) {}.render())
		#expect(button(.ariaPressed(false)) {}.render() == button(.ariaPressed(.off)) {}.render())
		#expect(button {}.render() == "<button></button>")
	}

	@Test
	func `source media accepts conditions restricted print queries and opaque raw queries`() {
		#expect(source(.media(.dark || .hover)).render() == #"<source media="(prefers-color-scheme: dark) or (hover: hover)">"#)
		#expect(source(.media(.print(matching: .dark || .moreContrast))).render() == #"<source media="print and ((prefers-color-scheme: dark) or (prefers-contrast: more))">"#)
		#expect(source(.media(MediaQuery(raw: "screen, print"))).render() == #"<source media="screen, print">"#)
	}

	@Test
	func `image candidate sets preserve descriptor families ordering and URL tokens`() throws {
		let small = ImageSource.path(#path("/small photo.png"))
		let large = ImageSource.path(#path("/large,photo.png"))
		let density = ImageSourceSet.density([(small, 2), (large, 3)])
		#expect(density.description == "/small%20photo.png 2x, /large,photo.png 3x")
		#expect(img(.srcset(density)).render() == #"<img srcset="/small%20photo.png 2x, /large,photo.png 3x">"#)
		let width = ImageSourceSet.width([(large, 640), (small, 320)])
		#expect(source(.srcset(width)).render() == #"<source srcset="/large,photo.png 640w, /small%20photo.png 320w">"#)
		#expect(source(.srcset(RoutePath("/single photo.png"))).render() == #"<source srcset="/single%20photo.png">"#)
		let data = try ImageSource(validating: "data:image/png;base64,AAAA")
		#expect(ImageSourceSet(data).description == "data:image/png;base64,AAAA")
		let encoded = try ImageSource(validating: "https://example.com/photo%2C")
		#expect(ImageSourceSet(encoded).description == "https://example.com/photo%2C")
		#expect(ImageSourceSet.density([(small, 0.000001), (large, 0.000002)]).description == "/small%20photo.png 1e-06x, /large,photo.png 2e-06x")
	}

	@Test
	func `image candidate sets reject empty invalid duplicate and ambiguous candidates`() async {
		await #expect(processExitsWith: .failure) {
			_ = ImageSourceSet.density([])
		}
		await #expect(processExitsWith: .failure) {
			_ = ImageSourceSet.width([])
		}
		await #expect(processExitsWith: .failure) {
			_ = ImageSourceSet.density([(.path(#path("/a.png")), 0)])
		}
		await #expect(processExitsWith: .failure) {
			_ = ImageSourceSet.density([(.path(#path("/a.png")), -.infinity)])
		}
		await #expect(processExitsWith: .failure) {
			_ = ImageSourceSet.density([(.path(#path("/a.png")), .infinity)])
		}
		await #expect(processExitsWith: .failure) {
			_ = ImageSourceSet.density([(.path(#path("/a.png")), .nan)])
		}
		await #expect(processExitsWith: .failure) {
			_ = ImageSourceSet.width([(.path(#path("/a.png")), -1)])
		}
		await #expect(processExitsWith: .failure) {
			_ = ImageSourceSet.density([(.path(#path("/a.png")), 2), (.path(#path("/b.png")), 2)])
		}
		await #expect(processExitsWith: .failure) {
			_ = ImageSourceSet.width([(.path(#path("/a.png")), 320), (.path(#path("/b.png")), 320)])
		}
		await #expect(processExitsWith: .failure) {
			_ = ImageSourceSet(.path(#path("/trailing,")))
		}
	}

	@Test
	func `named roles and media types retain their HTML spelling`() {
		#expect(div(.role(.status)) {}.render() == #"<div role="status"></div>"#)
		#expect(source(.type(.jpegXL)).render() == #"<source type="image/jxl">"#)
		#expect(link(.type(.rss)).render() == #"<link type="application/rss+xml">"#)
	}

	@Test
	func `media types normalize bare tokens and reject parameters and wildcards`() throws {
		#expect(try MediaType(validating: "Application/Vnd.Example+JSON").rawValue == "application/vnd.example+json")
		for value in ["", "text", "/html", "text/", "text/html; charset=utf-8", "text/*", "text/html\r\nX-Test: bad", "téxt/html"] {
			#expect(throws: ContentError.self) {
				try MediaType(validating: value)
			}
		}
	}

	@Test
	func `intrinsic sizes replace both dimensions while preserving other attributes and styles`() throws {
		let size = try #require(PixelSize(width: 640, height: 480))
		let resources = PageResources()
		let html = try resources.collect {
			img(.src("/image.png"), .alt("Preview & settings"), .width(1), .height(2), .class("preview"))
				.style(fileID: "Tests/IntrinsicSize.swift") {
					$0.opacity(0.5)
				}
				.intrinsicSize(size)
				.render()
		}

		#expect(html.contains(#"width="640""#))
		#expect(html.contains(#"height="480""#))
		#expect(!html.contains(#"width="1""#))
		#expect(!html.contains(#"height="2""#))
		#expect(html.contains(#"src="/image.png""#))
		#expect(html.contains(#"alt="Preview &amp; settings""#))
		#expect(html.contains(#"class="preview intrinsic-size-"#))
		let css = Stylesheet {
			resources.elementStyleNodes
		}.css
		#expect(css.contains("opacity: .5;"))
	}

	@Test
	func `intrinsic sizes set paired HTML dimensions on media and canvas`() throws {
		let size = try #require(PixelSize(width: 640, height: 480))
		#expect(img().intrinsicSize(size).render() == #"<img width="640" height="480">"#)
		#expect(video {}.intrinsicSize(size).render() == #"<video width="640" height="480"></video>"#)
		#expect(canvas {}.intrinsicSize(size).render() == #"<canvas width="640" height="480"></canvas>"#)
	}
}

struct JSONScriptTests {
	@Test
	func `structured data models own keyword mappings without rewriting nested domain keys`() throws {
		struct Child: Encodable {
			let id: String
			let type: String
		}

		struct Model: Encodable {
			let type = "Thing"
			let child = Child(id: "domain-id", type: "domain-type")
			let text = "</script>"

			private enum CodingKeys: String, CodingKey {
				case type = "@type"
				case child
				case text
			}
		}

		let model = Model()
		let object = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(model)) as? [String: Any])
		#expect(object["@type"] as? String == "Thing")
		let child = try #require(object["child"] as? [String: String])
		#expect(child == ["id": "domain-id", "type": "domain-type"])
		#expect(JSONScript(structuredData: model).render() == #"<script type="application/ld+json">{"@type":"Thing","child":{"id":"domain-id","type":"domain-type"},"text":"\u003C/script>"}</script>"#)
	}

	@Test
	func `speculation rules own their wire keys when encoded directly`() throws {
		let rules = SpeculationRules(prefetch: [
			.init(condition: .init(all: [.hrefMatches("/*"), .notMatching(["/private/*"])]), eagerness: .moderate),
		])
		let data = try JSONEncoder().encode(rules)
		let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
		let prefetch = try #require(object["prefetch"] as? [[String: Any]])
		let condition = try #require(prefetch.first?["where"] as? [String: Any])
		let clauses = try #require(condition["and"] as? [[String: Any]])
		try #require(clauses.count == 2)
		#expect(clauses[0]["href_matches"] as? String == "/*")
		#expect(clauses[0]["hrefMatches"] == nil)
		let excluded = try #require(clauses[1]["not"] as? [String: Any])
		#expect(excluded["href_matches"] as? [String] == ["/private/*"])
		#expect(excluded["hrefMatches"] == nil)
	}

	@Test
	func `speculation rules preserve nested predicates snake case and eagerness`() {
		let condition = SpeculationRules.Rule.Condition(all: [
			.hrefMatches("/*"),
			.notMatching(["/*.*", "/feedback"]),
		])
		let rules = SpeculationRules(
			prefetch: [.init(condition: condition, eagerness: .moderate)],
			prerender: [.init(condition: condition, eagerness: .conservative)]
		)

		#expect(JSONScript(speculationRules: rules).render() == #"<script type="speculationrules">{"prefetch":[{"eagerness":"moderate","where":{"and":[{"href_matches":"/*"},{"not":{"href_matches":["/*.*","/feedback"]}}]}}],"prerender":[{"eagerness":"conservative","where":{"and":[{"href_matches":"/*"},{"not":{"href_matches":["/*.*","/feedback"]}}]}}]}</script>"#)
	}

	@Test
	func `speculation rules allow empty rule sets and escape script delimiters`() {
		#expect(JSONScript(speculationRules: SpeculationRules()).render() == #"<script type="speculationrules">{"prefetch":[],"prerender":[]}</script>"#)
		let rules = SpeculationRules(prefetch: [
			.init(condition: .init(all: [.hrefMatches("</script>")]), eagerness: .moderate),
		])
		let html = JSONScript(speculationRules: rules).render()
		#expect(html.contains(#""href_matches":"\u003C/script>""#))
		#expect(html.components(separatedBy: "</script>").count == 2)
	}
}
