---
title: 'How to Redact a Screenshot on Mac'
description: 'Put black boxes over the private parts of a screenshot with Black Out, which also removes the metadata, or draw filled rectangles with Markup in Preview.'
publicationDate: 2026-10-30
topic: 'text-images-and-sound'
apps: [
	'black-out'
]
screenshot: {
	number: 1
	description: 'A passport photo in Black Out with the personal details covered by black boxes'
}
---

@QuickAnswer {
	Drop the screenshot on [Black Out](../apps/black-out/index.md), drag over the parts to hide, and press ++Command+C++ to copy the redacted image. Without an app, open the screenshot in Preview, choose “Tools › Annotate › Rectangle”, give the rectangle a black fill, and move it over the text.
}

To redact is to hide private information, like names, email addresses, or account numbers, before you share an image. Use a box that is fully black. Blurring and pixelation are not safe, as they [can sometimes be reversed](https://dheera.net/projects/blur).

## With Black Out

@Steps {
1. Open [Black Out](../apps/black-out/index.md), and drop the screenshot on its window. Or click “Open”, or paste an image with ++Command+V++.
1. Drag over each part that you want to hide. Each drag makes a black box.
1. To remove a box, click it, and press ++Delete++.
1. Press ++Command+C++ to copy the redacted image, and paste it where you share it. Or click “Export” to save it as PNG, JPEG, or HEIC.
}

Black Out removes the metadata of the image, like the date and the location where a photo was taken, so the image you share has no hidden information. Many image editors, like Preview, keep it.

To redact an image without opening the app, Control-click the image in Finder, and choose “Quick Actions › Black Out”. Draw the boxes, and click “Done”. If Black Out is not in the menu, choose “Quick Actions › Customize…”, and turn it on.

## Without an app

Preview can draw a black rectangle over a part of an image:

@Steps {
1. Open the screenshot in Preview.
1. Choose “Tools › Annotate › Rectangle”. A rectangle shows on the image, and the Markup toolbar opens.
1. With the rectangle selected, click “Fill Color” in the Markup toolbar, and choose black.
1. Drag the rectangle over the text, and drag its handles to change its size. For more boxes, do steps 2 to 4 again.
1. Choose “File › Save”, or “File › Export” to save a copy.
}

Check that the fill is fully black, and not a color with some transparency. You can also do this right after you take a screenshot: click the small image that shows in the corner of the screen, and use the shapes of Markup.

Preview keeps the metadata of the image. To remove the location of a photo, choose “Tools › Show Location Info”, and click “Remove Location Info”. The other metadata, like the date, stays in the image.

A rectangle in a PDF is different: it stays a separate object, so other people can move it or delete it, and the text below it can still be selected and copied. For text in a PDF, use “Tools › Redact” in Preview, which removes the text. Or export the page as an image, and redact the image.
