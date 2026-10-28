import Elementary
import Foundation
import Testing
@testable import SiteKit

struct TypedStyleBoundaryTests {
	@Test
	func `maximum sizes retain intrinsic and measurable values without automatic sizing`() {
		let style = Style()
			.frame(width: .auto, maxWidth: .unlimited, maxHeight: .maximumContent)
			.frame(maxWidth: .length(.percent(100) - .rootEm(2)))
		#expect(style.declarations.map(\.property) == [.width, .maxWidth, .maxHeight, .maxWidth])
		#expect(style.declarations.map(\.value.description) == ["auto", "none", "max-content", "calc(100% - 2rem)"])
		#expect(MaximumBoxSize.fitContent.description == "fit-content")
		#expect(MaximumBoxSize.minimumContent.description == "min-content")
	}

	@Test
	func `named stacks reset the direction of a previously composed stack`() {
		let horizontal = Style().vstack().hstack()
		let vertical = Style().hstack().vstack()
		#expect(horizontal.declarations.filter { $0.property == .flexDirection }.map(\.value.description) == ["column", "row"])
		#expect(vertical.declarations.filter { $0.property == .flexDirection }.map(\.value.description) == ["row", "column"])
		#expect(Style().hstack(isInline: true).declarations.first?.value.description == "inline-flex")
	}

	@Test
	func `keyframes reject nested selectors and media conditions`() async {
		await #expect(processExitsWith: .failure) {
			_ = Keyframe.to(Style().hover { $0.opacity(0) })
		}
		await #expect(processExitsWith: .failure) {
			_ = Keyframe.from(Style().dark { $0.opacity(0) })
		}
	}

	@Test
	func `declaration only keyframes retain their registered property definitions`() {
		let progress = RegisteredProperty<CSSNumber>("progress", syntax: .number, initialValue: 0)
		let css = Stylesheet {
			Keyframes("progress", .from(Style().setting(progress, to: 0)), .to(Style().setting(progress, to: 1)))
		}.css
		#expect(css.contains("from {\n\t\t--progress: 0;"))
		#expect(css.contains("to {\n\t\t--progress: 1;"))
		#expect(css.ranges(of: "@property --progress").count == 1)
	}

	@Test
	func `image sources preserve asset queries and reject fragment only destinations`() throws {
		#expect(try ImageSource(validating: "/image.svg?theme=dark#view").description == "/image.svg?theme=dark#view")
		#expect(try ImageSource(validating: "https://example.com/image.png").description == "https://example.com/image.png")
		#expect(ImageSource.path(#path("/image.png")).description == "/image.png")
		#expect(img(.src(.path(#path("/image.svg"), fragment: "view"))).render() == #"<img src="/image.svg#view">"#)
		#expect(ImageSource.path(#path("/image.svg"), query: [URLQueryItem(name: "theme", value: "dark")], fragment: "view").description == "/image.svg?theme=dark#view")
		#expect(throws: ContentError.self) {
			try ImageSource(validating: "#page-section")
		}
		#expect(throws: ContentError.self) {
			try ImageSource(validating: "image.png")
		}
		#expect(throws: (any Error).self) {
			try JSONDecoder().decode(ImageSource.self, from: Data("\"#page-section\"".utf8))
		}
	}

	@Test
	func `accessibility hiding can be reset by a later modifier on the same element`() {
		#expect(div().accessibilityHidden().accessibilityHidden(false).render() == #"<div aria-hidden="false"></div>"#)
		#expect(div().accessibilityHidden(false).accessibilityHidden().render() == #"<div aria-hidden="true"></div>"#)
		#expect(div().accessibilityHidden(false).render() == #"<div aria-hidden="false"></div>"#)
	}
}
