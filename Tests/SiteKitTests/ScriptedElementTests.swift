import Elementary
import Foundation
import TestSupport
import Testing
import SiteKit

struct ScriptedElementTests {
	@Test
	func `script source alternatives expose their applicable nonoptional payload`() throws {
		let fileScript = ElementScript(swiftFile: "/example/Widget.swift")
		guard case .file(let file) = fileScript.location else {
			Issue.record("Expected a script file.")
			return
		}
		#expect(file.path() == "/example/Scripts/Widget.js")

		let script = ElementScript(inline: "export default class extends HTMLElement {}")
		guard case .inline(let text) = script.location else {
			Issue.record("Expected inline script text.")
			return
		}
		#expect(text == "export default class extends HTMLElement {}")
	}

	@Test
	func `rendered element fragments replay inline and file script requirements`() throws {
		let fragment = try RenderedHTML {
			FeedTicker(config: nil)
			InlineTicker()
		}
		let resources = PageResources()
		_ = try resources.collect {
			div {
				fragment
				fragment
			}.render()
		}
		#expect(resources.elements.count == 2)
		#expect(resources.scripts == [try #require(FeedTicker.script.path)])
		#expect(resources.inlineScriptElements.map { ObjectIdentifier($0) } == [ObjectIdentifier(InlineTicker.self)])
	}

	@Test
	func `a snapshot keeps its selected style cases when the collector is reused`() throws {
		let resources = PageResources()
		_ = try resources.collect {
			div {
			}
			.style(FeedTicker.Styles.root)
			.render()
		}
		let snapshot = resources.snapshot

		_ = try resources.collect {
			div {
			}
			.style(FeedTicker.Styles.refresh)
			.render()
		}

		let snapshotCSS = Stylesheet {
			snapshot.styleNodes
		}.css
		let currentCSS = Stylesheet {
			resources.styleNodes
		}.css

		#expect(snapshotCSS.contains(".feed-ticker {"))
		#expect(!snapshotCSS.contains(".feed-ticker-refresh"))
		#expect(currentCSS.contains(".feed-ticker {"))
		#expect(currentCSS.contains(".feed-ticker-refresh {"))
	}

	@Test
	func `independent fragments detect conflicting style names when embedded together`() throws {
		let element = try RenderedHTML {
			FeedTicker(config: nil)
		}
		let other = try RenderedHTML {
			div {
			}
			.style(FeedTickerStyles.root)
		}
		let resources = PageResources()

		let error = try #require(throws: StyleError.self) {
			try resources.collect {
				div {
					element
					other
				}.render()
			}
		}

		switch error {
		case .duplicateClassNames(let names):
			#expect(names == ["feed-ticker"])
		}
	}

	@Test
	func `generated element names reject single words and reserved HTML spellings`() async {
		await #expect(processExitsWith: .failure) {
			_ = Clock.tagName
		}
		await #expect(processExitsWith: .failure) {
			_ = FontFace.tagName
		}
		#expect(PlainTicker.tagName == "plain-ticker")
	}

	@Test(arguments: ["</script>", "</SCRIPT>", "text </ScRiPt suffix"])
	func `inline element scripts reject HTML closing tags at construction`(source: String) async {
		await #expect(processExitsWith: .failure) { [source] in
			_ = ElementScript(inline: source)
		}
	}

	@Test
	func `the tag name comes from the type, like the class name of the root style, and the path of the script from its file`() {
		#expect(FeedTicker.tagName == "feed-ticker")
		#expect(FeedTicker.tagName == FeedTicker.Styles.root.className)
		#expect(FeedTicker.script.path == #path("/scripts/elements/FeedTicker.js"))
		#expect(InlineTicker.script.path == nil)
	}

	/**
	The build finds the scripts of the elements in the `Scripts` folders, so it needs no list of the elements. Only the `.js` files directly in a `Scripts` folder are scripts of elements.
	*/
	@Test(.temporaryDirectory)
	func `the project finds the scripts of the elements in the Scripts folders of the sources`() throws {
		let root = try URL.temporaryDirectory(
			files: [
				"Sources/Website/Scripts/Clock.js": "",
				"Sources/Website/Pages/Scripts/Game.js": "",
				"Sources/Website/Scripts/notes.txt": "",
				"Sources/Website/helper.js": "",
				"Sources/Website/Scripts/Nested/Deep.js": "",
				"public/scripts/site.js": "",
			]
		)

		let scripts = Project(root: root).elementScripts()

		#expect(scripts.map(\.path) == [#path("/scripts/elements/Game.js"), #path("/scripts/elements/Clock.js")])
		#expect(scripts.map(\.source.lastPathComponent) == ["Game.js", "Clock.js"])
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
	func `an explicitly encoded null remains a present configuration`() {
		#expect(NullableTicker(config: .some(nil)).render().contains(#"data-config="null""#))
		#expect(!NullableTicker(config: nil).render().contains("data-config"))
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

	let config: Config?

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

	enum Styles: String, ElementStyleSet {
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
A separate style set whose generated root class conflicts with `FeedTicker.Styles`.
*/
private enum FeedTickerStyles: String, StyleSet {
	case root

	var style: Style {
		Style().display(.inline)
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

	enum Styles: String, ElementStyleSet {
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

	enum Styles: String, ElementStyleSet {
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

	enum Styles: String, ElementStyleSet {
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

	enum Styles: String, ElementStyleSet {
		case root

		var style: Style {
			Style().display(.block)
		}
	}
}

private struct LabeledTicker: ScriptedElement {
	static let script = ElementScript()

	var rootAttributes: [HTMLAttribute<ElementTag<Self>>] {
		[.id("ticker"), .tabindex(-1), .role(.region), .custom(name: "aria-label", value: "News"), .class("wide")]
	}

	var content: some HTML {
		EmptyHTML()
	}

	enum Parts: String, ElementPartSet {
		case none
	}

	enum Styles: String, ElementStyleSet {
		case root

		var style: Style {
			Style().display(.block)
		}
	}
}

/**
An element whose configuration can explicitly encode JSON null.
*/
private struct NullableTicker: ScriptedElement {
	static let script = ElementScript()
	typealias Config = String?
	typealias Styles = PlainTicker.Styles

	let config: Config?

	var content: some HTML {
		EmptyHTML()
	}
}

private struct Clock: ScriptedElement {
	static let script = ElementScript(inline: "export default class extends HTMLElement {}")
	typealias Styles = PlainTicker.Styles

	var content: some HTML {
		EmptyHTML()
	}
}

private struct FontFace: ScriptedElement {
	static let script = ElementScript(inline: "export default class extends HTMLElement {}")
	typealias Styles = PlainTicker.Styles

	var content: some HTML {
		EmptyHTML()
	}
}
