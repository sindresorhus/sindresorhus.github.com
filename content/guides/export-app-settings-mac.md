---
title: 'How to Move the Settings of an App to Another Mac'
description: 'Export the settings of the apps that you choose to a file, and import them on another Mac, with Supercharge or with the defaults command.'
publicationDate: 2026-11-23
topic: 'mac'
apps: [
	'supercharge'
]
---

@QuickAnswer {
	In the settings of [Supercharge](/supercharge), click “Tools”, click “Export” below “Export and import settings for any apps”, and choose the apps. On the other Mac, double-click the “.app-settings” file. [Without an app](#without-an-app), use the `defaults export` and `defaults import` commands in Terminal.
}

Migration Assistant moves all your apps, files, and settings to a new Mac. This guide is for the settings of only some apps, like for a clean install or a second Mac.

## With Supercharge

@Steps {
1. Open the settings of [Supercharge](/supercharge), and click “Tools”.
1. Below “Export and import settings for any apps”, click “Export”.
1. Choose the apps, and click “Choose”. Supercharge saves an “.app-settings” file for each app in the Downloads folder.
1. Copy the files to the other Mac, like with AirDrop.
1. On the other Mac, double-click a file, or click “Import” in the same settings, and click “Import” to confirm.
}

The import replaces the settings of the app on that Mac. Supercharge puts a backup of the old settings in the Trash. “Export All” exports the settings of all your apps at once.

Most apps keep their settings in one standard place (UserDefaults), which Supercharge exports. Some apps keep them in another place, mostly apps that are made with web technology (Electron), and their settings are not exported.

The trial of Supercharge exports and imports 4 times each.

## Without an app

The `defaults` command of macOS exports and imports the same settings. You need the bundle ID of the app, like `com.apple.TextEdit`. <guide:find-app-bundle-id-mac>

Quit the app first. Then, in the Terminal app, export the settings to a file:

```console
defaults export com.apple.TextEdit ~/Desktop/TextEdit.plist
```

Copy the file to the other Mac, quit the app there, and import the file:

```console
defaults import com.apple.TextEdit ~/Desktop/TextEdit.plist
```

This works well for one app. Supercharge does many apps at once, finds the bundle IDs for you, and keeps a backup.

To move all your apps, files, and settings to a new Mac, use Migration Assistant. <source:https://support.apple.com/102613>
