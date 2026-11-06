---
title: 'How to Clear the Clipboard on Mac'
description: 'macOS has no command to clear the clipboard. Supercharge clears it from the menu bar, with a keyboard shortcut, or automatically after a minute.'
publicationDate: 2026-11-10
topic: 'text-images-and-sound'
apps: [
	'supercharge'
]
---

@QuickAnswer {
	macOS has no “Clear Clipboard” command. Click [Supercharge](../apps/supercharge/index.md) in the menu bar, and choose “Clear Clipboard”. Supercharge can also clear the clipboard automatically, like after you copy a password.
}

## With Supercharge

@Steps {
1. Open [Supercharge](../apps/supercharge/index.md). Its icon is in the menu bar.
1. Click the icon, and choose “Clear Clipboard”. The clipboard is now empty.
}

For a keyboard shortcut, open the Supercharge settings, click “Shortcuts”, and set a shortcut for “Clear clipboard”.

To clear it automatically, click “Tweaks” in the settings, and in the “System” section, turn on “Automatically clear clipboard for improved privacy”. Supercharge then clears the clipboard about one minute after you copy something, and when your Mac sleeps or locks.

## Without an app

- **Terminal:** Run `pbcopy < /dev/null`. It replaces the clipboard with nothing.
- **Copy something else:** Select a space or a word, and press ++Command+C++. The old content is no longer on the clipboard.

These work when you remember to do it. Supercharge is for when you want it in one click, or done for you.
