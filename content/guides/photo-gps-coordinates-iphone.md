---
title: 'How to Get the GPS Coordinates of a Photo on iPhone'
description: 'The Photos app shows where a photo was taken on a map. Get the latitude and longitude as text with the free Actions app in Shortcuts.'
publicationDate: 2026-11-16
topic: 'iphone'
apps: [
	'actions'
]
---

@QuickAnswer {
	The Photos app shows where a photo was taken on a map. To get the coordinates as text, like “38.8951, -77.0364”, use the “Get Image/Video Location” action of the free [Actions](../apps/actions/index.md) app in a shortcut.
}

## With Actions

@Steps {
1. Install [Actions](../apps/actions/index.md), and open it once.
1. In the Shortcuts app, make a new shortcut, and add the “Select Photos” action.
1. Add the “Get Image/Video Location” action of Actions.
1. Add the “Copy to Clipboard” action, or “Show Content” to see the coordinates.
1. Run the shortcut, and choose a photo.
}

The coordinates are latitude and longitude, with a comma between them. Paste them into a map app or a website. The action also reads MOV and MP4 videos. If the photo has no location, the action gives nothing.

The “Set Image/Video Location” action does the opposite: it sets the coordinates of a photo in the shortcut. It does not change the original photo.

## Without an app

@Steps {
1. Open the Photos app, and open the photo.
1. Swipe up, or tap the info button.
1. Tap the map or the address to see more.
}

[Apple’s instructions.](https://support.apple.com/guide/iphone/iph390138909/ios) This is enough to see where you took a photo.

The Shortcuts app can also give the numbers without an app: add “Get Details of Images” with “Location”, and then “Get Details of Locations” twice, with “Latitude” and with “Longitude”. Actions gives both in one action, with the comma between them.
