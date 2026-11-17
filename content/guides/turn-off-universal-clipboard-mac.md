---
title: 'How to Turn Off Universal Clipboard on Mac'
description: 'macOS turns off Universal Clipboard only together with all of Handoff. Supercharge turns off only the clipboard, so Handoff keeps working.'
publicationDate: 2026-11-10
topic: 'text-and-images'
isForNewMacOwners: true
apps: [
	'supercharge'
]
---

@QuickAnswer {
	Universal Clipboard is part of Handoff, so System Settings turns it off only with all of Handoff. To turn off only the clipboard, so copy and paste no longer syncs between your Mac and your iPhone or iPad, use [Supercharge](/supercharge).
}

## With Supercharge

@Steps {
1. Open the settings of [Supercharge](/supercharge), and click “Tweaks”.
1. In the “System” section, turn on “Disable Universal Clipboard”.
1. Copy text on your iPhone, and paste on the Mac. The Mac does not paste the text from the iPhone.
}

Supercharge changes a hidden setting of macOS, so the clipboard stays off when Supercharge is not open. Turn the setting off to sync the clipboard again.

## Without an app

- **Turn off all of Handoff:** In “[System Settings › General › AirDrop & Continuity](x-apple.systempreferences:com.apple.AirDrop-Handoff-Settings.extension)”, turn off “Allow Handoff between this Mac and your iCloud devices”. This also turns off Handoff of apps, like a Safari page from your iPhone.
- **Terminal:** Run these commands in the Terminal app:

	```console
	defaults write com.apple.coreservices.useractivityd ClipboardSharingEnabled -bool false
	killall useractivityd
	```

	To turn the clipboard on again, run them with `true` in place of `false`.

[About Universal Clipboard.](https://support.apple.com/102430) The Terminal commands change the same hidden setting as Supercharge, so they are enough if you are at ease with Terminal. Supercharge gives you a switch for it.
