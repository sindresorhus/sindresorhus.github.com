---
isDraft: true
title: 'How to Put Googly Eyes in the Mac Menu Bar'
description: 'Add eyes to the Mac menu bar that follow your pointer and blink when you click, like xeyes of old Unix desktops, with the free Googly Eyes app.'
publicationDate: 2026-11-06
topic: 'menu-bar'
apps: [
	'googly-eyes'
]
screenshot: {
	number: 1
	description: 'Googly eyes in the menu bar that look at the pointer'
}
---

@QuickAnswer {
	Open the free [Googly Eyes](../apps/googly-eyes/index.md) app. Two eyes show in the menu bar, follow your pointer, and blink when you click. macOS has nothing like it built in.
}

## With Googly Eyes

@Steps {
1. Open [Googly Eyes](../apps/googly-eyes/index.md). The eyes show in the menu bar.
1. Move the pointer. The eyes look at it.
1. Click anywhere. The eyes blink.
}

In the settings, you can change the size of the eyes, and make the left button blink the left eye and the right button the right eye.

With several displays, the eyes on a display that is not active stay still until you click on that display. [Why.](../apps/googly-eyes/index.md#does-it-support-multiple-screens)

## Without an app

macOS has no eyes in the menu bar. The old `xeyes` program of Unix desktops still runs on the Mac, but in a window, not in the menu bar, and only with [XQuartz](https://www.xquartz.org), which you must install first. Then open the Terminal app, and run:

```console
xeyes
```
