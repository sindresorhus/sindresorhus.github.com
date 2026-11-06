import Elementary
import SiteKit

/**
A link. A link that opens in a new tab gets `rel="noopener noreferrer"`, so the new page cannot control this one and does not see where the visitor came from, and screen readers say that it opens a new tab.

```swift
Link("crash report", destination: .crashReportQuestion, opensInNewTab: true)
```

A destination is required. A template whose destination a script fills uses a plain anchor instead.
*/
struct Link<Content: HTML>: HTML {
	let destination: LinkDestination
	let opensInNewTab: Bool
	let content: Content

	/**
	The name for screen readers instead of the content (``LabeledLink/accessibilityLabel``).
	*/
	var accessibilityLabel: String?

	init(destination: LinkDestination, opensInNewTab: Bool = false, @ContentBuilder content: () -> Content) {
		self.destination = destination
		self.opensInNewTab = opensInNewTab
		self.content = content()
	}

	var body: some HTML<HTMLTag.a> {
		let newTabNotice = opensInNewTab ? " (opens in a new tab)" : ""

		a {
			content

			if opensInNewTab {
				VisuallyHidden(newTabNotice)
			}
		}
		.attributes(.href(destination))
		.attributes(.target(.blank), .rel("noopener noreferrer"), when: opensInNewTab)
		// An empty label would name the link with nothing, which is worse than its content.
		.attributes(optional: accessibilityLabel.flatMap { label in
			label.isEmpty ? nil : .ariaLabel(label + newTabNotice)
		})
	}
}

extension Link where Content == HTMLText {
	/**
	Creates the link from its paired title and destination.
	*/
	init(_ link: LabeledLink, opensInNewTab: Bool = false) {
		self.init(link.title, destination: link.destination, opensInNewTab: opensInNewTab)
		self.accessibilityLabel = link.accessibilityLabel
	}

	init(_ title: String, destination: LinkDestination, opensInNewTab: Bool = false) {
		self.init(destination: destination, opensInNewTab: opensInNewTab) {
			HTMLText(title)
		}
	}
}
