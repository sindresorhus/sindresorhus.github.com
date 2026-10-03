import Elementary
import SiteKit

/**
A group of content under a heading, like the apps of a macOS version.

```swift
Section("macOS 14", id: "14") {
	ul {
		…
	}
}
```
*/
struct Section<Content: HTML>: HTML {
	let title: String

	/**
	The ID of the heading, so links can point to the section.
	*/
	let id: String?

	let content: Content

	init(_ title: String, id: String? = nil, @HTMLBuilder content: () -> Content) {
		self.title = title
		self.id = id
		self.content = content()
	}

	var body: some HTML<HTMLTag.section> {
		section {
			h2 {
				title
			}
			.attributes(.id(id ?? ""), when: id != nil)

			content
		}
	}
}
