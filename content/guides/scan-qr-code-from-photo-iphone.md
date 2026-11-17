---
title: 'How to Scan a QR Code in a Photo or Screenshot on iPhone'
description: 'Read the QR code in a saved photo or a screenshot on iPhone in the Photos app, or get its full text, like a Wi-Fi password, with the free Actions app.'
publicationDate: 2026-11-17
topic: 'iphone'
apps: [
	'actions'
]
---

@QuickAnswer {
	Make a shortcut with the “Scan QR Codes in Image” action of the free [Actions](/actions) app, and choose the photo or the screenshot. It gives the text of the code, like a link, or the name and the password of a Wi-Fi network. [Without an app](#without-an-app), open the photo in the Photos app, and touch and hold the code.
}

## With Actions

@Steps {
1. Install [Actions](/actions), and open it once.
1. In the Shortcuts app, make a new shortcut, and add the “Select Photos” action.
1. Add the [“Scan QR Codes in Image”](/actions#:~:text=Scan%20QR%20Codes%20in%20Image) action of [Actions](/actions).
1. Add the “Show Content” action, or “Open URLs” to open a link.
1. Run the shortcut, and choose the photo or the screenshot.
}

The scan is on your iPhone, so it also works offline. By default, the action reads only one code. To read all the codes in the image, turn on “Scan Multiple”.

@Tips {
- A Wi-Fi QR code gives text like `WIFI:S:Home;T:WPA;P:secret123;;`. The name of the network is after `S:`, and the password is after `P:`, so you can read the password without joining the network.
- For the barcode of a product, use the “Scan Barcodes in Image” action.
- To run the shortcut from the share button in Photos, turn on “Show in Share Sheet” in the details of the shortcut, and use the input of the shortcut in place of “Select Photos”.
}

## Without an app

The Photos app reads a QR code in a photo or a screenshot with Live Text:

@Steps {
1. Open the photo or the screenshot in the Photos app.
1. Touch and hold the QR code. If nothing shows, tap the Live Text button in the lower-right corner first.
1. Tap the link or the action that shows.
}

To get the full text of a code, like the password of a Wi-Fi code, use the shortcut above. The Camera app also reads a QR code that the camera sees, like on another screen ([Apple’s instructions](https://support.apple.com/guide/iphone/iphe8bda8762/ios)).

To find your photos and screenshots that have QR codes, open the Photos app, tap “Collections”, tap “Utilities”, and tap the collection of QR codes ([Apple’s instructions](https://support.apple.com/guide/iphone/iph995007f21/ios)).

On a Mac, see [how to scan a QR code on Mac](guide:scan-qr-code-mac).
