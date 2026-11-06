---
title: 'How to Stop Command+W from Closing Windows by Accident on Mac'
description: 'Make Command+W close a window only when you hold it or press W twice, in the apps that you choose, with Supercharge, or change the shortcut in System Settings.'
publicationDate: 2026-11-11
topic: 'keyboard-and-trackpad'
apps: [
	'supercharge'
]
---

@QuickAnswer {
	In the settings of [Supercharge](../apps/supercharge/index.md), choose to close windows only when you hold ++Command+W++, press ++W++ twice, or press ++Shift+Command+W++, in the apps that you choose. Without an app, give the Close command of an app another shortcut in “[System Settings › Keyboard › Keyboard Shortcuts… › App Shortcuts](x-apple.systempreferences:com.apple.Keyboard-Settings.extension)”.
}

A wrong ++Command+W++ is worst in an app where the window is the work, like a web app that you added to the Dock from Safari.

## With Supercharge

@Steps {
1. Open [Supercharge](../apps/supercharge/index.md), and give it the access that it asks for in [“Device Control and Data Access”](/apps/faq#device-control-access).
1. Open the Supercharge settings, and click “Tweaks”.
1. In the “Apps & Windows” section, find the setting that prevents accidental ++Command+W++ window closing, and choose one of these:
	- Press and hold ++Command+W++.
	- Hold ++Command++ and press ++W++ twice.
	- Press ++Shift+Command+W++.
1. Choose the apps that it applies to, with the button below the menu. It does nothing until you choose an app.
}

Then a single press of ++Command+W++ does nothing in these apps, and the way you chose closes the window. In all other apps, ++Command+W++ works as before. To also stop ++Command+Q++, see [how to stop Command+Q from quitting apps by accident](prevent-accidental-command-q-mac.md).

## Without an app

macOS has no setting for this, but you can give the Close command of one app another shortcut, so ++Command+W++ does nothing in that app:

@Steps {
1. Open “[System Settings › Keyboard](x-apple.systempreferences:com.apple.Keyboard-Settings.extension)”, and click “Keyboard Shortcuts…”.
1. Click “App Shortcuts”, and click the add button.
1. Choose the app, and type the name of its command that closes the window, exactly like in the menu of the app.
1. Click “Keyboard shortcut”, press the new shortcut, and click “Done”.
}

This is free, and it is enough for one or two apps. The name of the command is different between apps, and you must learn a new shortcut for each. With Supercharge, the keys stay the same, and only a longer press or a second press is needed.
