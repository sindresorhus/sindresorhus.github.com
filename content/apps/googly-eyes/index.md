---
title: 'Googly Eyes'
subtitle: 'Watchful eyes in your menu bar'
description: 'A free app that adds playful eyes to your menu bar. They follow your cursor and blink when you click, like xeyes of old Unix desktops. Pure whimsy! 👀'
publicationDate: 2025-03-12
platforms: [
	'macOS'
]
isMenuBarApp: true
appStoreID: 6743048714
script: '/googly-eyes/eyes.js'
nonAppStoreVersion: {
	version: '1.2.0'
	macOS: 26
	url: 'https://www.dropbox.com/scl/fi/t8qoulw2nfo2wbzoekbop/Googly-Eyes-1.2.0-1774281367.zip?rlkey=purr5ntc70na53ndpt06oxcuh&raw=1'
}
olderVersions: [
	{
		version: '1.1.4'
		macOS: '15'
		url: 'https://www.dropbox.com/scl/fi/p4ym425ivfp4ex1enlh1l/Googly-Eyes-1.1.4-macOS-15-1774281617.zip?rlkey=7jbf2llhjjielpvde6rcpvp8n&raw=1'
	}
]
pressQuotes: [
	{
		quote: 'Googly Eyes is developed by Sindre Sorhus. It is his latest app. […] The mouse pointer is tracked and the eyes blink when you click.'
		source: 'Compétence Mac'
		translatedFrom: 'French'
		url: 'https://competencemac.com/macos-quand-la-barre-des-menus-fait-les-yeux-doux-a-votre-mac/'
		year: 2025
	}
]
---

Add playful eyes to your menu bar that follow your cursor and blink when you click, like `xeyes` of old Unix desktops. Pure whimsy! 👀

Change the size of the eyes in the settings, or make the left button blink the left eye and the right button blink the right eye, so they wink at you. The eyes also show where the cursor is when you lose it.

## Frequently Asked Questions {#faq}

### Why is it using a lot of CPU? {#why-is-it-using-a-lot-of-cpu}

The app is optimized as much as possible, but macOS is inefficient at updating menu bar items. Also, make sure you know how to [interpret CPU usage](/apps/faq#high-cpu).

### Does it support multiple screens? {#does-it-support-multiple-screens}

Partly.

The eyes follow your cursor across displays. However, menu bar items on inactive secondary displays are just static macOS clones, so those eyes cannot track independently.

The real eyes live on the display with the active menu bar. macOS only makes another display active when you click something on it, for example a window or the desktop. Moving the pointer there is not enough. So when you move the pointer to another display, the eyes there stay frozen until you click on that display.

This is a macOS limitation and cannot be worked around. There is no supported way for an app to change which display has the active menu bar.
