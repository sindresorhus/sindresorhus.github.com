import Elementary
import Foundation
import Testing
import SiteKit

@Suite
struct ScriptedElementTests {
	@Test
	func `the tag name comes from the type, like the class name of the root style`() {
		#expect(FeedTicker.tagName == "feed-ticker")
		#expect(FeedTicker.tagName == FeedTicker.Styles.root.className)
		#expect(FeedTicker.scriptPath == "/scripts/elements/feed-ticker.js")
	}

	@Test
	func `renders the content in the element, with the root style, the parts, and the config`() throws {
		let resources = PageResources()
		let html = try resources.collect {
			FeedTicker(config: FeedTicker.Config(speed: 2)).render()
		}

		#expect(html == #"<feed-ticker class="feed-ticker" data-config="{&quot;speed&quot;:2}"><button data-part="refresh" class="feed-ticker-refresh">Refresh</button></feed-ticker>"#)
		#expect(resources.scripts == [FeedTicker.scriptPath])

		let css = Stylesheet {
			resources.styleNodes
		}.css

		#expect(css.contains(".feed-ticker {"))
	}

	@Test
	func `an element without a config has no data attribute for it`() {
		#expect(PlainTicker().render() == #"<plain-ticker class="plain-ticker"></plain-ticker>"#)
	}

	@Test
	func `the component and the place that uses it can give the element more attributes`() {
		#expect(LabeledTicker().render() == #"<labeled-ticker class="labeled-ticker wide" id="ticker" tabindex="-1" role="region" aria-label="News"></labeled-ticker>"#)
		#expect(PlainTicker().attributes(.id("plain")).render() == #"<plain-ticker class="plain-ticker" id="plain"></plain-ticker>"#)
	}

	@Test(.temporaryDirectory)
	func `the script gets the import of its base class and the definition of the element`() throws {
		try writeScript("""
		// The ticker.
		export default class extends ScriptedElement {
			connected() {}
		}
		""")

		let script = try FeedTicker.generatedScript(baseClasses: ["ScriptedElement": "/scripts/scripted-element.js?v=1"])

		#expect(script == """
		import ScriptedElement from '/scripts/scripted-element.js?v=1';

		// The ticker.
		export default class FeedTicker extends ScriptedElement {
			connected() {}
		}
		customElements.define('feed-ticker', FeedTicker);

		""")
	}

	@Test(.temporaryDirectory)
	func `a script needs one class that extends a known base class`() throws {
		try writeScript("export class Ticker extends HTMLElement {}")

		#expect(throws: ElementScriptError.self) {
			try FeedTicker.generatedScript(baseClasses: ["ScriptedElement": "/scripts/scripted-element.js"])
		}

		try writeScript("export default class extends LitElement {\n}")

		#expect(throws: ElementScriptError.self) {
			try FeedTicker.generatedScript(baseClasses: ["ScriptedElement": "/scripts/scripted-element.js"])
		}
	}

	@Test(.temporaryDirectory)
	func `a script that extends HTMLElement has no import`() throws {
		try writeScript("export default class extends HTMLElement {\n}")

		#expect(try FeedTicker.generatedScript(baseClasses: [:]) == """
		export default class FeedTicker extends HTMLElement {
		}
		customElements.define('feed-ticker', FeedTicker);

		""")
	}

	@Test
	func `an inline script is added to the page once, instead of a script file`() throws {
		let resources = PageResources()
		let html = try resources.collect {
			(InlineTicker().render(), InlineTicker().render())
		}

		#expect(html.0 == #"<inline-ticker class="inline-ticker"></inline-ticker>"#)
		#expect(resources.scripts == [])
		#expect(resources.inlineScriptElements.map { ObjectIdentifier($0) } == [ObjectIdentifier(InlineTicker.self)])
		#expect(InlineTicker.script.isInline)
		#expect(InlineTicker.script.file == nil)
		#expect(try InlineTicker.generatedScript(baseClasses: [:]).hasSuffix("customElements.define('inline-ticker', InlineTicker);\n"))
	}

	private func writeScript(_ source: String) throws {
		let file = try #require(FeedTicker.script.file)
		try file.deletingLastPathComponent().createDirectory()
		try Data(source.utf8).write(to: file)
	}
}

/**
An element with a script in the temporary directory of the test.
*/
private struct FeedTicker: ScriptedElement {
	static var script: ElementScript {
		ElementScript(swiftFile: (TemporaryDirectoryTrait.current ?? FileManager.default.temporaryDirectory).appending(path: "FeedTicker.swift").path(percentEncoded: false))
	}

	let config: Config

	var content: some HTML {
		button(.part(Parts.refresh)) {
			"Refresh"
		}
		.style(Styles.refresh)
	}

	struct Config: Encodable {
		let speed: Int
	}

	enum Parts: String, ElementPartSet {
		case refresh
	}

	enum Styles: ElementStyleSet {
		case root
		case refresh

		var style: Style {
			switch self {
			case .root:
				Style().display(.block)
			case .refresh:
				Style().opacity(1)
			}
		}
	}
}

/**
An element with an inline script and no parts.
*/
private struct InlineTicker: ScriptedElement {
	static let script = ElementScript(inline: """
	export default class extends HTMLElement {
		connectedCallback() {}
	}
	""")

	var content: some HTML {
		EmptyHTML()
	}

	enum Styles: ElementStyleSet {
		case root

		var style: Style {
			Style().display(.contents)
		}
	}
}

private struct PlainTicker: ScriptedElement {
	static let script = ElementScript()

	var content: some HTML {
		EmptyHTML()
	}

	enum Parts: String, ElementPartSet {
		case none
	}

	enum Styles: ElementStyleSet {
		case root

		var style: Style {
			Style().display(.block)
		}
	}
}

private struct LabeledTicker: ScriptedElement {
	static let script = ElementScript()

	var rootAttributes: [HTMLAttribute<ElementTag<Self>>] {
		[.id("ticker"), .tabindex(-1), .role("region"), .custom(name: "aria-label", value: "News"), .class("wide")]
	}

	var content: some HTML {
		EmptyHTML()
	}

	enum Parts: String, ElementPartSet {
		case none
	}

	enum Styles: ElementStyleSet {
		case root

		var style: Style {
			Style().display(.block)
		}
	}
}
