---
title: 'How to Find Which App Uses a Keyboard Shortcut on Mac'
description: 'Find which app takes a global keyboard shortcut on Mac with the keyboard shortcut inspector of Supercharge, an alternative to the old ShortcutDetective app.'
publicationDate: 2026-11-09
topic: 'keyboard-and-trackpad'
apps: [
	'supercharge'
]
---

@QuickAnswer {
	macOS does not show which app took a global keyboard shortcut. The keyboard shortcut inspector of [Supercharge](../apps/supercharge/index.md) shows the apps that registered or listen for a shortcut when you press it. It does the job of ShortcutDetective, which is no longer updated.
}

ShortcutDetective was a small free app from the Labs of Irradiated Software, the makers of SizeUp, that detected which app receives a keyboard shortcut. Its page still offers version 1.0, for Mac OS X 10.6 or later. The app has no code for Apple silicon, so it needs Rosetta on newer Macs. Homebrew disabled it in 2025 because it is not maintained, and removed it in 2026.

## With Supercharge

@Steps {
1. Open [Supercharge](../apps/supercharge/index.md), and give it the access that it asks for in [“Device Control and Data Access”](/apps/faq#device-control-access).
1. Open the Supercharge settings, and click “Tools”.
1. In “Keyboard shortcut inspector”, click “Detect”.
1. Press the keyboard shortcut. Supercharge shows the apps that may use it, or “No apps detected”.
1. Click “Stop” when you are done.
}

Right-click an app to show it in Finder, or to copy its path or bundle identifier. Some apps listen to all keys, so Supercharge says when it cannot know if such an app uses this shortcut. It can have false positives, and it cannot detect shortcuts like a double press of ++Command++. In the trial, the inspector works 4 times.

## Without an app

macOS shows its own shortcuts, but not the shortcuts of other apps:

@Steps {
1. Open “[System Settings › Keyboard](x-apple.systempreferences:com.apple.Keyboard-Settings.extension)”, and click “Keyboard Shortcuts…”.
1. Click each category, like “Mission Control” or “Spotlight”, and look for the shortcut.
}

When two shortcuts of macOS are the same, a warning sign shows next to them. To find an app that took a shortcut, quit your apps one at a time, starting with the menu bar apps, and press the shortcut after each one. When the shortcut does something else, the last app that you quit had it. This works, but it takes time. Supercharge tells you at once.
