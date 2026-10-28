---
title: 'How to Stop Command+Q from Quitting Apps by Accident on Mac'
description: 'Make apps ignore a single press of Command+Q with Supercharge, or give the Quit command of one app another shortcut.'
publicationDate: 2026-10-31
topic: 'keyboard-and-trackpad'
apps: [
	'supercharge'
]
---

@QuickAnswer {
	In the settings of [Supercharge](../apps/supercharge/index.md), choose to quit apps only when you hold ++Command+Q++, press ++Q++ twice, or press ++Shift+Command+Q++. Without an app, give the Quit command of an app another shortcut in “System Settings › Keyboard › Keyboard Shortcuts… › App Shortcuts”.
}

## With Supercharge

@Steps {
1. Open [Supercharge](../apps/supercharge/index.md), and give it the access that it asks for in [“Device Control and Data Access”](/apps/faq#device-control-access).
1. Open the Supercharge settings, and click “Tweaks”.
1. In the “Apps & Windows” section, choose one of these in “Prevent accidental quits by quitting apps with”:
	- Press and hold ++Command+Q++.
	- Hold ++Command++ and press ++Q++ twice.
	- Press ++Shift+Command+Q++.
}

Then a single press of ++Command+Q++ does nothing, and the way you chose quits the app. You can make it work only in some apps, or in all apps except some.

## Without an app

macOS has no setting for this, but you can give the Quit command of one app another shortcut, so ++Command+Q++ does nothing in that app:

@Steps {
1. Open “System Settings › Keyboard”, and click “Keyboard Shortcuts…”.
1. Click “App Shortcuts”, and click the add button.
1. Choose the app, and type the name of its Quit command exactly like in its menu, like “Quit Safari”.
1. Click “Keyboard shortcut”, press the new shortcut, and click “Done”.
}

The menu title is different in each app, so you must do this for each app. Supercharge works for all apps at once.
