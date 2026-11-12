---
title: 'How to Make the Red Close Button Quit an App on Mac'
description: 'Coming from Windows? On Mac, the red close button does not quit the app. Supercharge quits an app when you close its last window.'
publicationDate: 2026-11-13
topic: 'windows-apps-and-dock'
isForWindowsUsers: true
apps: [
	'supercharge'
]
---

@QuickAnswer {
	On Mac, the red close button closes a window, but most apps keep running, with a dot below their icon in the Dock. Press ++Command+Q++ to quit the app. To make the close button quit the app when you close its last window, like on Windows, use [Supercharge](../apps/supercharge/index.md).
}

## With Supercharge

@Steps {
1. Open [Supercharge](../apps/supercharge/index.md), and give it the access that it asks for in [“Device Control and Data Access”](/apps/faq#device-control-access).
1. Open the Supercharge settings, and click “Tweaks”.
1. In the “Experimental” section, turn on “Quit an app when closing its last window”.
1. Optional: click the button below the switch to choose apps that it must not quit, like your mail app. By default, it quits all apps.
1. Close the last window of an app with the red close button or with ++Command+W++. The app quits.
}

With “Right-click” in “Quit trigger”, a normal click on the close button only closes the window, and a right-click quits the app. ++Command+W++ still quits it. Menu bar apps do not quit. The red button of a full-screen window does not quit the app, and windows in other spaces can confuse the count of windows.

## Without an app

- **Quit the app:** Press ++Command+Q++, or choose “Quit” in the app menu, next to the Apple menu.
- **From the Dock:** Right-click the app icon in the Dock, and choose “Quit”.

Some apps, like System Settings, already quit when you close their window. Most apps stay open, so that a new window opens fast. Supercharge is for when you want the Mac to work like Windows.
