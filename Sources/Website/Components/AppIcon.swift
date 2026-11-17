import Elementary
import SiteKit

/**
The icon of an app. It loads when it is about to scroll into view, unless it is at the top of the page. The parent can add styles, like a size, to the box around the image, and picks a larger shadow with `shadow` (``ShadowSize``).

The icon images fill their square, so the soft rim of the icon is cut flat at the sides of the image. The image is clipped to the icon shape, a little inside its edges, so the cut rim does not show. The shadow is on the box, as the clip would also cut a shadow on the image.

```swift
AppIcon(app, size: 64)
	.style(Styles.icon)

// A large icon at the top of the page.
AppIcon(app, size: 256, shadow: .large)

// Next to the name of the app.
AppIcon(decorative: app, size: 32)
```
*/
struct AppIcon: HTML {
	private let path: RoutePath

	/**
	The smaller JPEG XL copy of the icon, which browsers that show JPEG XL load instead.
	*/
	private var jpegXL: JPEGXLCopy?

	/**
	The name of the app, for the text of the image. `nil` for an icon that screen readers skip, as the name of the app is next to it.
	*/
	private let title: String?

	let size: Int

	/**
	Whether the icon is at the top of the page, so it loads at once, before other images.
	*/
	var isAboveFold = false

	/**
	The ID of the image, for a script that changes the image, like the googly eyes of the Googly Eyes page.
	*/
	var imageID: ElementID?

	/**
	The shadow below the icon, larger for a larger icon.
	*/
	var shadowSize = ShadowSize.small

	init(
		_ app: App,
		size: Int,
		isAboveFold: Bool = false,
		imageID: ElementID? = nil,
		shadow: ShadowSize = .small
	) {
		self.path = app.iconPath
		self.jpegXL = app.iconJPEGXL
		self.title = app.title
		self.size = size
		self.isAboveFold = isAboveFold
		self.imageID = imageID
		self.shadowSize = shadow
	}

	/**
	An icon that screen readers skip, because the name of the app is next to it, like `Image(decorative:)` in SwiftUI.
	*/
	init(
		decorative app: App,
		size: Int,
		isAboveFold: Bool = false,
		shadow: ShadowSize = .small
	) {
		self.init(
			decorative: app.iconPath,
			jpegXL: app.iconJPEGXL,
			size: size,
			isAboveFold: isAboveFold
		)
		self.shadowSize = shadow
	}

	/**
	The icon of an app without a page, like a tiny app, or of an app before its page is loaded, like before a link to it in the text, which screen readers skip, because the name of the app is next to it.

	- Parameter jpegXL: The JPEG XL copy of the icon, when it is known.
	*/
	init(
		decorative path: RoutePath,
		jpegXL: JPEGXLCopy? = nil,
		size: Int,
		isAboveFold: Bool = false
	) {
		self.path = path
		self.jpegXL = jpegXL
		self.title = nil
		self.size = size
		self.isAboveFold = isAboveFold
	}

	var body: some HTML<HTMLTag.span> {
		span {
			JPEGXLPicture(copy: jpegXL) {
				image
			}
		}
		.style(Styles.root, shadowSize.style)
	}

	private var image: some HTML<HTMLTag.img> {
		img(
			.src(path),
			.width(size),
			.height(size),
			.alt(title.map { "\($0) app icon" } ?? "")
		)
			.attributes(.fetchPriority(.high), when: isAboveFold)
			.attributes(.lazyLoading, when: !isAboveFold)
			.attributes(optional: imageID.map { .id($0) })
			.style(Styles.image)
	}

	/**
	The faint white line around an app icon in dark mode, like on the App Store website, so a dark icon has an edge on the dark page and cards. It follows the shape of the icon. Put it before other shadows, as each drop shadow of a filter is also a shadow of the shadows before it.
	*/
	static let keyline = Filter.dropShadow(Shadow(y: .zero, blur: .pixels(0.5), color: .lightDark(.transparent, .white.opacity(0.3))))

	/**
	The soft shadow below an app icon, so a white icon has an edge on a white page, and the keyline (``keyline``), as the shadow does not show in dark mode.
	*/
	static let shadow: [Filter] = [keyline, .dropShadow(Shadow(y: .pixels(2), blur: .pixels(2), color: .black.opacity(0.1)))]

	/**
	The size of the shadow below an icon.
	*/
	enum ShadowSize {
		/**
		The soft shadow of ``AppIcon/shadow``, for most icons.
		*/
		case small

		/**
		A larger shadow, for the icon in the box to get the app (``AppCallToAction``).
		*/
		case medium

		/**
		A soft shadow in layers with a glow in the accent of the page, for the large icon at the top of an app page (``AppHero``).
		*/
		case large

		fileprivate var style: Styles {
			switch self {
			case .small:
				.smallShadow
			case .medium:
				.mediumShadow
			case .large:
				.largeShadow
			}
		}
	}

	enum Styles: String, StyleSet {
		case root
		case image
		case smallShadow
		case mediumShadow
		case largeShadow

		var style: Style {
			switch self {
			case .root:
				// As large as the image, unless the parent sets a size. It does not shrink in a row, like next to a title.
				Style()
					.display(.inlineBlock)
					.flexShrink(0)
					.verticalAlign(.top)
			case .smallShadow:
				Style().filter(AppIcon.shadow)
			case .mediumShadow:
				Style().filter(AppIcon.keyline, .dropShadow(Shadow(y: .pixels(4), blur: .pixels(10), color: .black.opacity(0.12))))
			case .largeShadow:
				Style().filter(
					AppIcon.keyline,
					.dropShadow(Shadow(y: .pixels(1), blur: .pixels(2), color: .black.opacity(0.15))),
					.dropShadow(Shadow(y: .pixels(4), blur: .pixels(10), color: .black.opacity(0.1))),
					.dropShadow(Shadow(y: .pixels(12), blur: .pixels(28), color: .black.opacity(0.07))),
					// A soft glow in the color of the icon. Without an accent, it is transparent, as the alpha of `transparent` is 0. In dark mode, a dark accent gets the lightness of the selection (``Color/darkModeHighlightAccent``), as a dark glow does not show on the dark page, so all apps get the same soft glow.
					.dropShadow(
						Shadow(
							y: .pixels(10),
							blur: .pixels(24),
							color: .lightDark(
								Color.accent.value(default: .transparent).opacity(0.5),
								Color.accent(fallback: .transparent, minimumLightness: 0.6).opacity(0.4)
							)
						)
					)
				)
			case .image:
				// The size of the image, or smaller when the parent sets a smaller box, like a hero icon. The corner radius is the one of an icon on the grid of Apple, about 22.5% of its size. The margin is zero, as an image in prose has a margin.
				Style()
					.display(.block)
					.frame(height: .auto, maxWidth: .percent(100))
					.margin(.zero)
					.clipShape(inset: .percent(1.2), cornerRadius: .percent(22.5))
					// A faint fill in the shape of the icon while it loads, so a slow page shows where the icon will be. The loaded icon covers it.
					.background(.lightDark(.black.opacity(0.06), .white.opacity(0.1)))
			}
		}
	}
}
