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
struct JPEGXLPicture<Image: HTML>: HTML {
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
