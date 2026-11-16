import Elementary
import Foundation
import TestSupport
import Testing
import SiteKit

struct ScriptedElementTests {
	@Test
	func `the script is the file with the name of the Swift file in the Scripts folder next to it`() {
		#expect(ElementScript(swiftFile: "/example/Widget.swift").file.path() == "/example/Scripts/Widget.js")
	}

	@Test
	func `rendered element fragments replay their script requirements`() throws {
		let fragment = try RenderedHTML {
			FeedTicker(config: nil)
			PlainTicker()
		}
		let resources = PageResources()
		_ = try resources.collect {
			div {
				fragment
				fragment
			}.render()
		}
		#expect(resources.elements.count == 2)
		#expect(resources.scripts == [FeedTicker.script.path, PlainTicker.script.path])
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

	@Test
	func `the tag name comes from the type, like the class name of the root style, and the path of the script from its file`() {
		#expect(FeedTicker.tagName == "feed-ticker")
		#expect(FeedTicker.tagName == FeedTicker.Styles.root.className)
		#expect(FeedTicker.script.path == #path("/scripts/elements/FeedTicker.js"))
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
		#expect(resources.scripts == [FeedTicker.script.path])

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

	/**
	The elements of the pages that render inside a collector are collected in it too, like the elements of all the pages of the site in a test.
	*/
	@Test
	func `a collector around another one gets its elements and scripts`() throws {
		let outer = PageResources()
		let inner = PageResources()

		try outer.collect {
			_ = try inner.collect {
				(FeedTicker(config: FeedTicker.Config(speed: 1)).render(), PlainTicker().render())
			}
		}

		#expect(outer.elements.map { ObjectIdentifier($0) } == [ObjectIdentifier(FeedTicker.self), ObjectIdentifier(PlainTicker.self)])
		#expect(outer.scripts == [FeedTicker.script.path, PlainTicker.script.path])
	}

	@Test
	func `the script of an element is added to the page once`() throws {
		let resources = PageResources()
		let html = try resources.collect {
			(PlainTicker().render(), PlainTicker().render())
		}

		#expect(html.0 == #"<plain-ticker class="plain-ticker"></plain-ticker>"#)
		#expect(resources.scripts == [PlainTicker.script.path])
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
	static let script = ElementScript()
	typealias Styles = PlainTicker.Styles

	var content: some HTML {
		EmptyHTML()
	}
}

private struct FontFace: ScriptedElement {
	static let script = ElementScript()
	typealias Styles = PlainTicker.Styles

	var content: some HTML {
		EmptyHTML()
	}
}
