import Elementary
import SiteKit

/**
An image with its smaller JPEG XL copy (``JPEGXLCopy``), which browsers that show JPEG XL load instead. Without a copy, it is the image alone.

```swift
JPEGXLPicture(copy: app.iconJPEGXL) {
	img(.src(app.iconPath))
}
```
*/
struct JPEGXLPicture<Image: HTML>: HTML where Image.Tag == HTMLTag.img {
	let copy: JPEGXLCopy?
	@HTMLBuilder let image: Image

	var body: some HTML {
		if let copy {
			picture {
				source(.srcset(copy.path), .type(.jpegXL))
				image
			}
			.style {
				$0.pictureWrapper()
			}
		} else {
			image
		}
	}
}

extension Style {
	/**
	A `<picture>` that is only a wrapper of the sources of its image, so the image is laid out as if it were alone, like an item of a flex or grid parent. The sources are hidden, as each would be an empty item in a flex or grid parent, which adds one more gap. The browser still reads their `srcset`.
	*/
	func pictureWrapper() -> Self {
		display(.contents)
			.children("source") {
				$0.hidden()
			}
	}
}

/**
A screenshot with its intrinsic dimensions and optional JPEG XL source. The caller owns its layout; the same asset markup serves a carousel and a guide.
*/
struct ScreenshotImage<Image: HTML>: HTML where Image.Tag == HTMLTag.img {
	private let copy: JPEGXLCopy?
	private let image: Image

	/**
	Creates the image before the caller styles it, preserving named component styles and one-off element styles alike.
	*/
	init(asset: ScreenshotAsset, alternativeText: String, loadsImmediately: Bool = false, @ContentBuilder styling: (_AttributedContent<Elementary.img>) -> Image) {
		var attributes: [HTMLAttribute<HTMLTag.img>] = [
			.src(asset.path),
			.alt(alternativeText),
			.asyncDecoding,
		]
		if !loadsImmediately {
			attributes.append(.lazyLoading)
		}

		self.copy = asset.jpegXL
		self.image = styling(img(attributes: attributes).intrinsicSize(asset.size))
	}

	var body: some HTML {
		JPEGXLPicture(copy: copy) {
			image
		}
	}
}
