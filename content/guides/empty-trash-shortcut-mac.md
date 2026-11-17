---
title: 'How to Empty the Trash with a Keyboard Shortcut on Mac'
description: 'Empty the Trash from any app with a keyboard shortcut or from the menu bar with Supercharge, or with Shift+Command+Delete in Finder.'
publicationDate: 2026-11-22
topic: 'finder-and-desktop'
shortcut: 'Shift+Command+Delete'
apps: [
	'supercharge'
]
---

@QuickAnswer {
	In the settings of [Supercharge](/supercharge), click “Shortcuts”, and set a shortcut for “Empty trash”. Then press it in any app. [Without an app](#without-an-app), click the Finder icon in the Dock, and press ++Shift+Command+Delete++.
}

## With Supercharge

@Steps {
1. Open the settings of [Supercharge](/supercharge), and click “Shortcuts”.
1. In the “Action” section, click the field next to “Empty trash”, and press the keyboard shortcut that you want.
1. Press the shortcut in any app. The first time, allow Supercharge to control Finder.
}

Supercharge empties the Trash at once, with no question. To get the question of Finder first, click the settings button next to “Empty trash”, and turn on “Show confirmation dialog”. “Empty Trash” is also in the menu of Supercharge in the menu bar.

## Without an app

Finder has a keyboard shortcut for it, but it works only when Finder is the active app:

- ++Shift+Command+Delete++ empties the Trash after you confirm.
- ++Option+Shift+Command+Delete++ empties it with no question.

For a shortcut that works in all apps, make a shortcut in the Shortcuts app with a “Run AppleScript” action with `tell application "Finder" to empty trash`, and give it a keyboard shortcut in its details, like in [the guide to open an app with a keyboard shortcut](guide:keyboard-shortcut-to-open-app-mac#without-an-app). The first time, macOS asks you to allow access to Finder. A script needs “Allow Running Scripts”: choose “Shortcuts › Settings”, click “Advanced”, and turn it on.

The same command is in the menu bar: “Finder › Empty Trash…”. You can also right-click the Trash in the Dock, and choose “Empty Trash”.

To delete the files that have been in the Trash for 30 days by themselves, open “Finder › Settings”, click “Advanced”, and turn on “Remove items from the Trash after 30 days”. To stop the question each time, turn off “Show warning before emptying the Trash” there.
