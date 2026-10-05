import Elementary
import SiteKit

/**
A Tabler icon, drawn with the current text color.

The shapes are raw SVG strings copied from Tabler, so updating an icon is a copy and paste. Keep them as strings instead of Elementary's typed SVG builder.

```swift
a(.href(.feeds)) {
	Icon.rss
}
```
*/
enum Icon: HTML, CaseIterable {
	case menu
	case rss
	case apps
	case mail
	case github
	case x
	case mastodon
	case bluesky
	case instagram
	case unsplash
	case appStore
	case shuffle
	case share
	case arrowLeft
	case arrowRight
	case chevronLeft
	case chevronRight
	case close
	case sparkles
	case dots

	/**
	Three dots in a row, without the circle of ``dots``, like in a chip.
	*/
	case ellipsis
	case paperclip
	case check
	case copy
	case file
	case star
	case deviceLaptop
	case deviceMobile
	case deviceWatch
	case deviceTV
	case deviceVisionPro

	/**
	The selector of icons, for styles of the icons in a component, like a color.
	*/
	static let selector = ".icon"

	var body: some HTML {
		size(.rootEm(1.25))
	}

	/**
	The icon in a size other than the default 1.25rem. The size is a presentation attribute, so a style can still change it.

	The shapes are in the sprite at ``spritePath``, which browsers download once for all pages. The stroke attributes here apply to the shapes in it.
	*/
	func size(_ size: Length) -> HTMLRaw {
		HTMLRaw(#"<svg class="icon" xmlns="http://www.w3.org/2000/svg" width="\#(size)" height="\#(size)" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><use href="\#(Self.spritePath.versioned)#\#(symbolID)"/></svg>"#)
	}

	/**
	The file with every icon as a symbol.
	*/
	static let spritePath: RoutePath = "/assets/icons.svg"

	/**
	The sprite, for ``spritePath``.
	*/
	static var sprite: String {
		let symbols = allCases.map { #"<symbol id="\#($0.symbolID)" viewBox="0 0 24 24">\#($0.shapes)</symbol>"# }
		return #"<svg xmlns="http://www.w3.org/2000/svg">\#(symbols.joined())</svg>"#
	}

	private var symbolID: String {
		String(describing: self).kebabCased
	}

	private var shapes: String {
		switch self {
		case .menu:
			#"<path d="M4 8h16M4 16h16"/>"#
		case .rss:
			#"<path d="M4 19a1 1 0 1 0 2 0a1 1 0 1 0-2 0"/><path d="M4 4a16 16 0 0 1 16 16M4 11a9 9 0 0 1 9 9"/>"#
		case .apps:
			#"<path d="M4 5a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v4a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1V5M4 15a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v4a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1v-4M14 15a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v4a1 1 0 0 1-1 1h-4a1 1 0 0 1-1-1v-4M14 7h6M17 4v6"/>"#
		case .mail:
			#"<path d="M3 7a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2v10a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V7"/><path d="m3 7 9 6 9-6"/>"#
		case .github:
			#"<path d="M9 19c-4.3 1.4-4.3-2.5-6-3m12 5v-3.5c0-1 .1-1.4-.5-2 2.8-.3 5.5-1.4 5.5-6a4.6 4.6 0 0 0-1.3-3.2 4.2 4.2 0 0 0-.1-3.2s-1.1-.3-3.5 1.3a12.3 12.3 0 0 0-6.2 0C6.5 2.8 5.4 3.1 5.4 3.1a4.2 4.2 0 0 0-.1 3.2A4.6 4.6 0 0 0 4 9.5c0 4.6 2.7 5.7 5.5 6-.6.6-.6 1.2-.5 2V21"/>"#
		case .x:
			#"<path d="m4 4 11.733 16H20L8.267 4H4M4 20l6.768-6.768m2.46-2.46L20 4"/>"#
		case .mastodon:
			#"<path d="M18.648 15.254C16.832 17.017 12 16.88 12 16.88a18.262 18.262 0 0 1-3.288-.256c1.127 1.985 4.12 2.81 8.982 2.475-1.945 2.013-13.598 5.257-13.668-7.636L4 10.309c0-3.036.023-4.115 1.352-5.633C7.023 2.766 12 3.01 12 3.01s4.977-.243 6.648 1.667C19.977 6.195 20 7.274 20 10.31s-.456 4.074-1.352 4.944"/><path d="M12 11.204V8.278C12 7.02 11.105 6 10 6S8 7.02 8 8.278V13m4-4.722C12 7.02 12.895 6 14 6s2 1.02 2 2.278V13"/>"#
		case .bluesky:
			#"<path d="M6.335 5.144C4.681 3.945 2 3.017 2 5.97c0 .59.35 4.953.556 5.661.713 2.463 3.13 2.75 5.444 2.369-4.045.665-4.889 3.208-2.667 5.41C6.363 20.428 7.246 21 8 21c2 0 3.134-2.769 3.5-3.5.333-.667.5-1.167.5-1.5 0 .333.167.833.5 1.5.366.731 1.5 3.5 3.5 3.5.754 0 1.637-.571 2.667-1.59 2.222-2.203 1.378-4.746-2.667-5.41 2.314.38 4.73.094 5.444-2.369.206-.708.556-5.072.556-5.661 0-2.953-2.68-2.025-4.335-.826C15.372 6.806 12.905 10.192 12 12c-.905-1.808-3.372-5.194-5.665-6.856"/>"#
		case .instagram:
			#"<path d="M3 7a4 4 0 0 1 4-4h10a4 4 0 0 1 4 4v10a4 4 0 0 1-4 4H7a4 4 0 0 1-4-4V7"/><path d="M8.5 12a3.5 3.5 0 1 0 7 0 3.5 3.5 0 0 0-7 0M17 7v.01"/>"#
		case .unsplash:
			#"<path d="M4 11h5v4h6v-4h5v9H4v-9M9 4h6v4H9V4"/>"#
		case .appStore:
			#"<path d="M3 12a9 9 0 1 0 18 0 9 9 0 1 0-18 0M8 16l1.106-1.99m1.4-2.522L13 7M7 14h5m2.9 0H17M16 16l-2.51-4.518m-1.487-2.677L11.003 7"/>"#
		case .shuffle:
			#"<path d="m18 4 3 3-3 3m0 10 3-3-3-3M3 7h3a5 5 0 0 1 5 5 5 5 0 0 0 5 5h5m0-10h-5a4.978 4.978 0 0 0-3 1m-4 8a4.984 4.984 0 0 1-3 1H3"/>"#
		case .share:
			#"<path d="M8 9H7a2 2 0 0 0-2 2v8a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2v-8a2 2 0 0 0-2-2h-1M12 14V3M9 6l3-3 3 3"/>"#
		case .arrowLeft:
			#"<path d="M5 12h14M5 12l6 6m-6-6 6-6"/>"#
		case .arrowRight:
			#"<path d="M5 12h14m-6 6 6-6m-6-6 6 6"/>"#
		case .chevronLeft:
			#"<path d="m15 6-6 6 6 6"/>"#
		case .chevronRight:
			#"<path d="m9 6 6 6-6 6"/>"#
		case .close:
			#"<path d="M18 6 6 18M6 6l12 12"/>"#
		case .sparkles:
			#"<path d="M16 18a2 2 0 0 1 2 2 2 2 0 0 1 2-2 2 2 0 0 1-2-2 2 2 0 0 1-2 2m0-12a2 2 0 0 1 2 2 2 2 0 0 1 2-2 2 2 0 0 1-2-2 2 2 0 0 1-2 2M9 18a6 6 0 0 1 6-6 6 6 0 0 1-6-6 6 6 0 0 1-6 6 6 6 0 0 1 6 6"/>"#
		case .dots:
			#"<circle cx="12" cy="12" r="9"/><path d="M8 12h.01M12 12h.01M16 12h.01"/>"#
		case .ellipsis:
			#"<path d="M4 12a1 1 0 1 0 2 0a1 1 0 1 0 -2 0M11 12a1 1 0 1 0 2 0a1 1 0 1 0 -2 0M18 12a1 1 0 1 0 2 0a1 1 0 1 0 -2 0"/>"#
		case .paperclip:
			#"<path d="m21.44 11.05-9.19 9.19a6 6 0 0 1-8.49-8.49l8.57-8.57A4 4 0 1 1 18 8.84l-8.59 8.57a2 2 0 0 1-2.83-2.83l8.49-8.48"/>"#
		case .check:
			#"<path d="M20 6 9 17l-5-5"/>"#
		case .copy:
			#"<path d="M7 9.667a2.667 2.667 0 0 1 2.667-2.667h8.666a2.667 2.667 0 0 1 2.667 2.667v8.666a2.667 2.667 0 0 1-2.667 2.667h-8.666a2.667 2.667 0 0 1-2.667-2.667z"/><path d="M4.012 16.737a2.005 2.005 0 0 1-1.012-1.737v-10c0-1.1.9-2 2-2h10c.75 0 1.158.385 1.5 1"/>"#
		case .file:
			#"<path d="M13 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V9z"/><path d="M13 2v7h7"/>"#
		case .deviceLaptop:
			#"<path d="M3 19h18M5 7a1 1 0 0 1 1-1h12a1 1 0 0 1 1 1v8a1 1 0 0 1-1 1H6a1 1 0 0 1-1-1V7"/>"#
		case .deviceMobile:
			#"<path d="M6 5a2 2 0 0 1 2-2h8a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2V5M11 4h2M12 17v.01"/>"#
		case .deviceWatch:
			#"<path d="M6 9a3 3 0 0 1 3-3h6a3 3 0 0 1 3 3v6a3 3 0 0 1-3 3H9a3 3 0 0 1-3-3V9M9 18v3h6v-3M9 6V3h6v3"/>"#
		case .deviceTV:
			#"<path d="M3 9a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V9M16 3l-4 4-4-4"/>"#
		case .deviceVisionPro:
			#"<path d="M12 7c1.143 0 2.235.035 3.275.104 1.017.068 1.95.207 2.798.42.813.203 1.52.505 2.119.909a3.903 3.903 0 0 1 1.328 1.531c.326.657.48 1.48.48 2.466 0 1.006-.189 1.91-.574 2.707-.375.779-.886 1.396-1.537 1.848a3.696 3.696 0 0 1-2.16.66c-.509 0-.97-.068-1.382-.21a5.84 5.84 0 0 1-1.17-.548 18.45 18.45 0 0 1-1.045-.695 9.104 9.104 0 0 0-1.001-.63 2.376 2.376 0 0 0-1.13-.301c-.373 0-.75.097-1.132.3-.316.17-.65.38-1 .63-.322.23-.67.462-1.047.695a5.78 5.78 0 0 1-1.168.548c-.413.142-.872.21-1.378.21a3.706 3.706 0 0 1-2.165-.659c-.651-.452-1.162-1.07-1.537-1.848-.385-.798-.574-1.7-.574-2.709-.004-.98.15-1.802.477-2.46a3.897 3.897 0 0 1 1.33-1.531c.6-.403 1.307-.704 2.12-.907a16.088 16.088 0 0 1 2.8-.423c1.04-.071 2.13-.107 3.273-.107"/>"#
		case .star:
			// Filled, unlike the other icons.
			#"<path fill="currentColor" stroke="none" d="M8.243 7.34l-6.38 .925l-.113 .023a1 1 0 0 0 -.44 1.684l4.622 4.499l-1.09 6.355l-.013 .11a1 1 0 0 0 1.464 .944l5.706 -3l5.693 3l.1 .046a1 1 0 0 0 1.352 -1.1l-1.091 -6.355l4.624 -4.5l.078 -.085a1 1 0 0 0 -.63 -1.62l-6.38 -.926l-2.852 -5.78a1 1 0 0 0 -1.794 0l-2.853 5.78z"/>"#
		}
	}
}
