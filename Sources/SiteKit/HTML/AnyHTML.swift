import Elementary

/**
HTML of any type, which renders on its own, like `AnyView` in SwiftUI. Use it where a large component holds the content of a page, like the layout around the body of a page.

In a debug build, each generic level of the render of Elementary keeps a copy of its content on the stack, so a large page in many levels can use the whole 512 KB stack of a thread of Swift concurrency. Here, the levels above hold only a reference, and the content renders from a new level.

```swift
main {
	AnyHTML(page.body)
}
```
*/
public struct AnyHTML: HTML {
	private let content: any HTML

	public init(_ content: some HTML) {
		self.content = content
	}

	public var body: HTMLRaw {
		HTMLRaw(content.render())
	}
}
