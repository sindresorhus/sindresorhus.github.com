---
title: 'How to Save All Images from a Website on iPhone'
description: 'Save all the images of a web page in Safari to Photos at once with a shortcut and the free Actions app, or with the built-in actions of Shortcuts.'
publicationDate: 2026-11-17
topic: 'iphone'
apps: [
	'actions'
]
---

@QuickAnswer {
	Make a shortcut with the “Get Images from Web Page” action of the free [Actions](/actions) app and the “Save to Photos” action. Turn on “Show in Share Sheet” in the details of the shortcut, and run it from the share button of Safari. [Without an app](#without-an-app), use the “Get Images from Input” action of Shortcuts in place of “Get Images from Web Page”.
}

## With Actions

@Steps {
1. Open the Shortcuts app, and tap the add button (+) to make a new shortcut.
1. Open the details of the shortcut, turn on “Show in Share Sheet”, and tap “Done”.
1. Add the [“Get Images from Web Page”](/actions#:~:text=Get%20Images%20from%20Web%20Page) action of [Actions](/actions). In its URL field, choose “Shortcut Input”.
1. Add the “Save to Photos” action.
1. In Safari, open the page, tap the Page Menu button, and then “Share”. With the Bottom or Top tab layout, tap the Share button. Choose the shortcut.
}

The images go to the Photos app. The action loads the page like a browser does, so it can also get images that a page loads later, like when you scroll. By default, it leaves out images with a side shorter than 50 pixels, like icons, when it knows their size. Tap “Show More” in the action to change this, or to sort the images with “Largest First”.

On iPhone, the actions of other apps can run for only 30 seconds. For a page with very many images, use the “Get Image URLs from Web Page” action, and then “Get Contents of URL” to download each image.

## Without an app

The Shortcuts app can get the images of a page in Safari with its own action ([Apple’s instructions for the share sheet](https://support.apple.com/guide/shortcuts/apd163eb9f95/ios)):

@Steps {
1. Make a new shortcut, turn on “Show in Share Sheet” in its details, and tap “Done”.
1. Add the “Get Images from Input” action, with “Shortcut Input” as its input, and then the “Save to Photos” action.
1. Run the shortcut from the share button of Safari.
}

This works for many pages. If it misses images that you see on the page, use the action of Actions, which loads the page like a browser first.
