import Elementary
import Foundation
import Testing
import SiteKit

@Suite
struct ScriptedElementTests {
	@Test
	func `the tag name comes from the type, like the class name of the root style, and the path of the script from its file`() {
		#expect(FeedTicker.tagName == "feed-ticker")
		#expect(FeedTicker.tagName == FeedTicker.Styles.root.className)
		#expect(FeedTicker.script.path == "/scripts/elements/FeedTicker.js")
		#expect(InlineTicker.script.path == nil)
	}

	/**
	The build finds the scripts of the elements in the `Scripts` folders, so it needs no list of the elements. Only the `.js` files directly in a `Scripts` folder are scripts of elements.
	*/
	@Test(.temporaryDirectory)
	func `the project finds the scripts of the elements in the Scripts folders of the sources`() throws {
		let root = try #require(TemporaryDirectoryTrait.current)

		for file in ["Sources/Website/Scripts/Clock.js", "Sources/Website/Pages/Scripts/Game.js", "Sources/Website/Scripts/notes.txt", "Sources/Website/helper.js", "Sources/Website/Scripts/Nested/Deep.js", "public/scripts/site.js"] {
			let url = root.appending(path: file)
			try url.deletingLastPathComponent().createDirectory()
			try Data().write(to: url)
		}

		let scripts = Project(root: root).elementScripts()

		#expect(scripts.map(\.path) == ["/scripts/elements/Game.js", "/scripts/elements/Clock.js"])
		#expect(scripts.map { $0.source.lastPathComponent } == ["Game.js", "Clock.js"])
		#expect(Project(root: root.appending(path: "missing")).elementScripts().isEmpty)
	}

	@Test
	func `renders the content in the element, with the root style, the parts, the first state, and the config`() throws {
		let resources = PageResources()
		let html = try resources.collect {
			FeedTicker(config: FeedTicker.Config(speed: 2)).render()
		}

		#expect(html == #"<feed-ticker class="feed-ticker" data-config="{&quot;speed&quot;:2}"><button data-part="refresh" data-state="idle" class="feed-ticker-refresh">Refresh</button></feed-ticker>"#)
		#expect(resources.scripts == [try #require(FeedTicker.script.path)])

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

	@Test
	func `an inline script gets the class name of the type and the definition of the element`() throws {
		#expect(try InlineTicker.generatedScript() == """
		export default class InlineTicker extends HTMLElement {
			connectedCallback() {}
		}
		customElements.define('inline-ticker', InlineTicker);

		""")
	}

	/**
	An inline script is for a small element, so it extends `HTMLElement` and imports nothing. A script that needs a base class of the site is a script file.
	*/
	@Test
	func `an inline script needs one class that extends HTMLElement`() {
		#expect(throws: ElementScriptError.self) {
			try BaseTicker.generatedScript()
		}

		#expect(throws: ElementScriptError.self) {
			try NamedTicker.generatedScript()
		}
	}

	/**
	The elements of the pages that render inside a collector are collected in it too, like the elements of all the pages of the site in a test.
	*/
	@Test
	func `a collector around another one gets its elements and scripts`() throws {
		let outer = PageResources()
		let inner = PageResources()

		try outer.collect {
			_ = try inner.collect {
				(FeedTicker(config: FeedTicker.Config(speed: 1)).render(), InlineTicker().render())
			}
		}

		#expect(outer.elements.map { ObjectIdentifier($0) } == [ObjectIdentifier(FeedTicker.self), ObjectIdentifier(InlineTicker.self)])
		#expect(outer.scripts == [try #require(FeedTicker.script.path)])
		#expect(outer.inlineScriptElements.map { ObjectIdentifier($0) } == [ObjectIdentifier(InlineTicker.self)])
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
		#expect(InlineTicker.script.file == nil)
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
		button(.part(Parts.refresh), .state(States.idle)) {
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

	enum States: String, ElementStateSet {
		case idle
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
An element with an inline script that extends the base class of the site.
*/
private struct BaseTicker: ScriptedElement {
	static let script = ElementScript(inline: """
	// The ticker.
	export default class extends ScriptedElement {
		connected() {}
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

/**
An element with an inline script with a named class, which the page cannot define.
*/
private struct NamedTicker: ScriptedElement {
	static let script = ElementScript(inline: "export class Ticker extends HTMLElement {}")

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
