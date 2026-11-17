---
title: 'How to Find the Bundle ID of an App on Mac'
description: 'Get the bundle identifier of a Mac app, like com.apple.Safari, with a command in Terminal, or from the right-click menu of Finder with Supercharge.'
publicationDate: 2026-11-17
topic: 'windows-apps-and-dock'
apps: [
	'supercharge'
]
---

@QuickAnswer {
	In Terminal, type `osascript -e 'id of app "Safari"'` with the name of the app. Or right-click the app in Finder: [Supercharge](/supercharge) shows “Bundle ID: com.apple.Safari” in the menu, and a click copies it.
}

The bundle identifier is the unique name of an app. Commands like `tccutil` and `defaults`, and device management profiles, use it to find the app.

## With Supercharge

@Steps {
1. Open the settings of [Supercharge](/supercharge), click “Tweaks”, and click “Configure…” next to “Context menu items”.
1. In the “Main Menu” tab, turn on “App: Bundle Identifier”. To also see the version of the app, turn on “App: Version”.
1. Right-click an app in Finder, like in the Applications folder. The menu shows “Bundle ID:” and the identifier.
1. Click the item to copy the identifier.
}

The item shows only when you select one app.

## Without an app

macOS has two commands for it in Terminal. Use the name of the app, or its path:

```console
$ osascript -e 'id of app "Safari"'
com.apple.Safari
$ mdls -name kMDItemCFBundleIdentifier -r /Applications/Safari.app
com.apple.Safari
```

Without Terminal, right-click the app in Finder, choose “Show Package Contents”, open the “Contents” folder, select “Info.plist”, and press ++Space++. The identifier is on the line below “CFBundleIdentifier”.

Terminal is fine when you need the identifier once. Supercharge shows it every time you right-click an app.
