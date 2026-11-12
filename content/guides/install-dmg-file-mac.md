---
title: 'How to Install an App from a DMG File on Mac'
description: 'Install an app from a DMG file on Mac: drag the app to the Applications folder, and eject the disk. Supercharge does all the steps with one click.'
publicationDate: 2026-11-13
topic: 'windows-apps-and-dock'
isForWindowsUsers: true
apps: [
	'supercharge'
]
---

@QuickAnswer {
	Double-click the DMG file, drag the app in the window that opens to the Applications folder, eject the disk, and move the DMG file to the Trash. A Mac has no installer like Windows for most apps. [Supercharge](../apps/supercharge/index.md) asks to install the app when you open the DMG, and then does all the steps.
}

## With Supercharge

@Steps {
1. Open the settings of [Supercharge](../apps/supercharge/index.md), and click “Tweaks”.
1. In the “File Automation” section, turn on “Offer to install apps from mounted DMG files”. Keep “Move DMG to Trash when done” and “Open app after installation” on.
1. Double-click a DMG file. Supercharge asks if it should install and open the app.
1. Click “Install”. Supercharge moves the app to the Applications folder, ejects the disk, moves the DMG file to the Trash, and opens the app.
}

If the Applications folder already has the app, the new app replaces it. For a large app, Finder copies it, and asks before it replaces the old app. When the DMG has an installer package instead of an app, Supercharge opens the package, but you must eject the disk and trash the DMG file yourself.

## Without an app

@Steps {
1. In the Downloads folder, double-click the DMG file. A disk opens in a Finder window.
1. Drag the app to the Applications folder, often with the shortcut to the folder in the same window.
1. In the Finder sidebar, click the eject button next to the disk.
1. Move the DMG file to the Trash.
}

If the disk has an installer package (an open box), double-click it, and follow the steps on the screen. [Apple’s instructions.](https://support.apple.com/guide/mac-help/mh35835/mac)

**Terminal:**

```console
hdiutil attach ~/Downloads/App.dmg
cp -R "/Volumes/App/App.app" /Applications
diskutil eject "/Volumes/App"
```

Use the names of your DMG file, disk, and app. macOS 27 says that `hdiutil attach` is deprecated, but it still works.

The steps are easy, but you do them for each app, and the DMG files stay in the Downloads folder when you forget. Supercharge is for when you install apps often.
