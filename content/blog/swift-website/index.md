---
title: 'This Website Is Now Made in Swift'
description: 'SwiftUI-like components, styles as modifiers, and a compiler that catches broken links before visitors do. How this site is made, and why I love working on it.'
publicationDate: '2026-10-11'
tags: [
	'swift'
]
---

This website used to be made with Astro. Now it's all Swift: every page, component, and style. The same language as my apps, and it feels a lot like SwiftUI.

The browser still gets plain HTML and CSS, with a little JavaScript. What changed is how it's made, and how much I enjoy working on it.

## Why Swift?

I write Swift all day, and I love it. I no longer have to switch languages and tools when I go from an app to the website.

But the real reason is the compiler. A website is lots of small things that need to agree: links, class names, styles, scripts, and the data of more than 60 apps. In a typical web stack, they only meet in the browser, and a mistake becomes a broken page. Here, most of them meet in the compiler. Rename a page, and every link to it in the code stops compiling.

## It looks like SwiftUI

A component is a struct with a `body`:

```swift
struct BackLink: HTML {
	let app: App

	var body: some HTML {
		a(.href(app.path)) {
			"Back to \(app.title)"
		}
		.style {
			$0
				.secondaryText()
				.fontWeight(.medium)
				.hoverColor(.primaryText)
		}
	}
}
```

The HTML comes from [Elementary](https://github.com/elementary-swift/elementary). The rest (styles, routes, and content) is my own small framework on top.

The syntax highlighting you see here is Swift too. The build runs the code through Swift's own parser, [swift-syntax](https://github.com/swiftlang/swift-syntax), and colors each token, so the colors are right, and there's no JavaScript for it.

## Styles are modifiers

A style goes on the element, like a modifier in SwiftUI. The `.style { … }` above becomes a class like `back-link-1x2y3z4`, from the file name and a hash of the style. It can't leak to other elements, and when I inspect the HTML, I know which file it came from.

Shared looks and variants are enum cases, so they autocomplete, and a typo doesn't compile. Here is a short version of the badge component:

```swift
struct Badge: HTML {
	enum Kind: StyleSet {
		case standard
		case new

		var style: Style {
			switch self {
			case .standard:
				Style().background(.gray(200), dark: .gray(800))
			case .new:
				Style().background(.teal(100), dark: .teal(900))
			}
		}
	}

	enum Styles: StyleSet {
		case root

		var style: Style {
			Style()
				.display(.inlineBlock)
				.padding(.horizontal, .rootEm(0.375))
				.cornerRadius(.rootEm(0.5))
				.bold()
		}
	}

	let title: String
	var kind = Kind.standard

	var body: some HTML {
		span {
			title
		}
		.style(Styles.root, kind)
	}
}
```

Using it is just like using a SwiftUI view:

```swift
Badge(title: "New", kind: .new)
```

Each page only gets the CSS of the components it shows. Under the hood, it's modern CSS: cascade layers, `light-dark()`, relative colors, scroll-driven animations, and container units. No preprocessor and no Tailwind.

## Typed CSS variables

CSS custom properties are just strings. Here, they have a type:

```swift
static let color = StyleVariable<Color>("--overflow-menu-color")

// The menu uses it, with a default.
.color(OverflowMenu.color.value(default: .link))

// A parent sets it.
.setting(OverflowMenu.color, to: .bodyText)
```

Setting it to a length doesn't compile. With `RegisteredProperty`, the page also gets the `@property` rule, so the browser can animate it, like the gradient on the home page:

```swift
static let gradientStart = RegisteredProperty<Color>("--gradient-start", syntax: "<color>", initialValue: .black)
```

## Responsive and accessible

Breakpoints and media queries are typed, and media queries combine with `&&`:

```swift
Style()
	.grid(columns: 2)
	.from(.tablet) {
		$0.gridColumns(3)
	}
	.media(.coarsePointer) {
		$0.padding(.rootEm(0.75))
	}
	.media(.hover && .finePointer && .allowsMotion) {
		$0.hover {
			$0.setting(titleLight, to: .percent(35))
		}
	}
```

The last one is the light that follows the pointer over the title of the apps page. It's only there with a mouse or a trackpad, and only when motion is allowed.

Colors are semantic, like `.secondaryText`. Each has a light and a dark value, and the colors of text, links, and lines get a stronger value when you ask for more contrast in the system settings. Components get all of that for free.

## Links

Links work like in SwiftUI. From the 404 page:

```swift
Link("Back to Homepage", destination: .path(.root))
	.buttonStyle(.primary)

Link("Browse Apps", destination: .path(.apps))
	.buttonStyle(.secondary)
```

Pages are static members, so `.apps` autocompletes, and a page that doesn't exist doesn't compile. After the build, every link and ID in the generated HTML is checked too.

## Scripts

A component with behavior is a custom element. Swift renders the HTML, and the script is the class of the element. A small script lives right in the Swift file, and a larger one in a `.js` file next to it. A script only touches its own element, so it can't break something else on the page. No framework and no bundler.

## Small and fast

A blog post is about 14 KB compressed: 6.6 KB of HTML, 5.4 KB of CSS, and 1.8 KB of JavaScript. An app page, like the one for Lungo, is about 29 KB before the screenshots. Besides a small shared stylesheet, a page only gets the styles and scripts of its own components, there are no web fonts, and images below the fold load lazily. In Chrome, resting the pointer on a link loads the page in the background, so it often opens instantly.

## Content as data

Each app is a Markdown file with typed metadata:

```swift
@Frontmatter
struct Frontmatter {
	@NonEmpty var title: String
	@NonEmpty var subtitle: String
	@CalendarDay var publicationDate: Date
	var platforms: [Platform]
	var isPaid = false
}
```

[`@Frontmatter`](https://github.com/sindresorhus/sindresorhus.github.com/blob/main/Sources/SiteKitMacros/FrontmatterMacro.swift) is a Swift macro that writes the decoder at compile time. `@NonEmpty` rejects an empty value, and `@CalendarDay` turns `'2017-07-26'` into a `Date` and rejects days like `'2026-02-30'`. A mistake, like an unknown platform or a misspelled key, is an error with the file and the line, sometimes with a “Did you mean” suggestion.

The build also gets the ratings, prices, and reviews of each app from the App Store. `swift run website check` catches what the compiler can't, like spelling mistakes, or a page that says an app needs macOS 14 when the App Store says macOS 15.

## Delight

Warnings fail the build, and a few hundred tests check what the types can't, like that every class has a CSS rule. So I make big changes without fear. Everything autocompletes, and a refactor is a rename. The code reads like SwiftUI, with no class soup and no selectors to keep in my head. A component keeps its markup, styles, and script in one place, and when I delete it, its CSS and JavaScript go with it. And `swift run website serve` reloads the page when I save.

Working on the website is now as much fun as working on the apps.

The [source code](https://github.com/sindresorhus/sindresorhus.github.com) is open.

## One more thing

The best stress test of all this is [my home page from 1999](/1999): the site as a personal home page from back then, with a guestbook, an alien game, a virtual unicorn, and a MIDI jukebox. It has 81 custom elements, made with the same components and styles as the rest of the site. Go sign the guestbook.
