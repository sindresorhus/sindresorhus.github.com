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
				source(.srcset(copy.path), .type("image/jxl"))
				image
			}
			// Only a wrapper of the sources, so the image is laid out as if it were alone.
			.style {
				$0.display(.contents)
			}
		} else {
			image
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
	init(asset: ScreenshotAsset, alternativeText: String, loadsImmediately: Bool = false, @ContentBuilder styling: (Elementary.img) -> Image) {
		var attributes: [HTMLAttribute<HTMLTag.img>] = [
			.src(asset.path),
			.width(asset.size.width),
			.height(asset.size.height),
			.alt(alternativeText),
			.asyncDecoding,
		]
		if !loadsImmediately {
			attributes.append(.lazyLoading)
		}

		self.copy = asset.jpegXL
		self.image = styling(img(attributes: attributes))
	}

	var body: some HTML {
		JPEGXLPicture(copy: copy) {
			image
		}
	}
}
