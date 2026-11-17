---
title: 'How to Get the Bing Photo of the Day as Your Wallpaper on Mac'
description: 'Show the Bing photo of the day as your Mac wallpaper with the free Plash app. It changes by itself each day.'
publicationDate: 2026-11-18
topic: 'finder-and-desktop'
apps: [
	'plash'
]
---

@QuickAnswer {
	Open the free [Plash](/plash) app, choose “Add Website…”, and add `https://bing-photo-of-the-day.netlify.app`. The Bing photo of the day then fills your desktop, and changes when Bing has a new photo. macOS has no setting for the Bing photo.
}

## With Plash

@Steps {
1. Open [Plash](/plash). Its icon is in the menu bar.
1. Click the icon, and choose “Add Website…”.
1. In “URL”, enter `https://bing-photo-of-the-day.netlify.app`, and click “Add”.
}

The page gets the new photo by itself every six hours, so you do not need to set a reload interval in Plash. The photo is 1920 × 1080 pixels, so it can look a little soft on a large Retina display.

@Tips {
- Add other websites too, and switch between them in the menu of Plash. [How to use a website as your wallpaper.](guide:website-wallpaper-mac)
- The page is [open source](https://github.com/sindresorhus/plash-bing-photo-of-the-day). If you know how, you can put your own copy of it on Netlify, and add that URL.
}

## Without an app

macOS cannot get the Bing photo by itself. In “[System Settings › Wallpaper](x-apple.systempreferences:com.apple.Wallpaper-Settings.extension)”, you can choose a folder of your own photos, which macOS changes at an interval, like each day. Or choose an aerial, which moves when you lock or unlock the Mac. <source:https://support.apple.com/guide/mac-help/mchlp3013/mac>

Microsoft also has a Bing Wallpaper app for Mac on [its website](https://bingwallpaper.microsoft.com).
