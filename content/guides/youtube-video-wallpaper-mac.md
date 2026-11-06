---
title: 'How to Set a YouTube Video as Your Wallpaper on Mac'
description: 'Play a YouTube video as your desktop wallpaper on Mac, muted and in a loop, with the free Plash app and the embed URL of the video.'
publicationDate: 2026-11-11
topic: 'finder-and-desktop'
apps: [
	'plash'
]
---

@QuickAnswer {
	Add the embed URL of the YouTube video as a website in the free [Plash](../apps/plash/index.md) app. The video then plays behind your windows, muted, and in a loop. Without an app, the Wallpaper settings of macOS have aerials that move, and you can add your own photos and image files.
}

## With Plash

@Steps {
1. Open the video on YouTube, and copy its ID: the part after `v=` in the URL.
1. Open [Plash](../apps/plash/index.md), click its icon in the menu bar, and choose “Add Website…”.
1. In “URL”, enter the URL below, with the ID of the video in place of `VIDEO_ID`, in the two places. Then click “Add”.
}

```
https://www.youtube.com/embed/VIDEO_ID?autoplay=1&mute=1&loop=1&playlist=VIDEO_ID&controls=0
```

Use this embed URL, not the normal URL of the video. Its options make the video start by itself, without controls, and play again when it ends.

@Tips {
- The video must be muted to start by itself, so keep `mute=1`. Plash also has “Mute audio” in its settings, which is on by default.
- If the video shows a play button only when your Mac is on battery, [Low Power Mode is a likely cause](../apps/plash/index.md#youtube).
- The video comes from YouTube, so it needs an internet connection.
}

## Without an app

In “[System Settings › Wallpaper](x-apple.systempreferences:com.apple.Wallpaper-Settings.extension)”, macOS has dynamic wallpapers, which become brighter and darker with the time of day, and aerials, which move when you lock or unlock the Mac. For your own wallpaper, you can add a photo, an image file, or a folder of images. [Apple’s instructions.](https://support.apple.com/guide/mac-help/mchlp3013/mac)

If you only want some motion on the desktop, an aerial is enough. Plash is for a video of your choice.
