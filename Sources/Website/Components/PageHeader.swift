import Elementary
import SiteKit

/**
The title of a page, with an introduction below it, so the titles of the pages have the same look and line up with the content of their page. The `#` title of Markdown pages gets the same look from the prose. The home page, the app pages, and the playful pages, like GeoCities, have their own titles.

```swift
PageHeader(title: "App Timeline", intro: "58 apps since 2015, newest first.")
```

The introduction can have links:

```swift
PageHeader(title: "Shortcuts Apps") {
	"Apps for the "
	a(.href("https://support.apple.com/guide/shortcuts-mac")) {
		"Shortcuts app"
	}
	"."
}
```
*/
struct PageHeader<Intro: HTML>: HTML {
	private let title: String
	private let intro: Intro?
	private let isCentered: Bool

	/**
	- Parameter isCentered: Centers the header, for a page whose content is centered, like a game.
	*/
	init(title: String, isCentered: Bool = false, @ContentBuilder intro: () -> Intro) {
		self.title = title
		self.intro = intro()
		self.isCentered = isCentered
	}

	var body: some HTML<HTMLTag.header> {
		header {
			h1 {
				title
			}
			.style(PageHeaderStyles.title)

			if let intro {
				p {
					intro
				}
				.style(PageHeaderStyles.intro)
			}
		}
		.style(PageHeaderStyles.centered, when: isCentered)
	}
}

extension PageHeader where Intro == StringContent {
	init(title: String, intro: String? = nil, isCentered: Bool = false) {
		self.title = title
		self.intro = intro.map(StringContent.init)
		self.isCentered = isCentered
	}
}

/**
The styles of ``PageHeader``, outside the generic type, so the class names are the same for every introduction.
*/
enum PageHeaderStyles: StyleSet {
	case title
	case intro
	case centered

	var style: Style {
		switch self {
		case .title:
			Style()
				.textStyle(.largeTitle)
				.color(.primaryText)
		case .intro:
			Style()
				.margin(.top, .rootEm(0.5))
				.secondaryText(.lead)
				.textLinks()
		case .centered:
			Style().textAlign(.center)
		}
	}
}
