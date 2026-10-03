import Elementary
import SiteKit

/**
A link. A link that opens in a new tab gets `rel="noopener noreferrer"`, so the new page cannot control this one and does not see where the visitor came from.

```swift
Link("crash report", destination: "/apps/faq#crash-report", opensInNewTab: true)
```

Without a destination, a script sets it, like in a template.
*/
struct Link<Content: HTML>: HTML {
	let destination: String?
	let opensInNewTab: Bool
	let content: Content

	init(destination: String?, opensInNewTab: Bool = false, @HTMLBuilder content: () -> Content) {
		self.destination = destination
		self.opensInNewTab = opensInNewTab
		self.content = content()
	}

	var body: some HTML<HTMLTag.a> {
		a {
			content
		}
		.attributes(.href(destination ?? ""), when: destination != nil)
		.attributes(.target(.blank), .rel("noopener noreferrer"), when: opensInNewTab)
	}
}

extension Link where Content == HTMLText {
	init(_ title: String, destination: String?, opensInNewTab: Bool = false) {
		self.init(destination: destination, opensInNewTab: opensInNewTab) {
			HTMLText(title)
		}
	}
}
