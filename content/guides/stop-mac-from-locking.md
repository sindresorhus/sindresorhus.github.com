---
title: 'How to Stop Your Mac from Locking'
description: 'Keep the screen on and unlocked while you read or present with Lungo, or change when the screen saver starts and the display turns off in System Settings.'
publicationDate: 2026-11-18
topic: 'mac'
isForNewMacOwners: true
apps: [
	'lungo'
]
---

@QuickAnswer {
	Click [Lungo](/lungo) in the menu bar, and choose how long the screen must stay on, like “2 Hours”. The display does not turn off, so the Mac does not lock. To change it permanently, open “[System Settings › Lock Screen](x-apple.systempreferences:com.apple.Lock-Screen-Settings.extension)”, and choose longer times, or “Never”.
}

Your Mac locks when the screen saver starts or the display turns off, after some minutes without the keyboard or the mouse. So to stop the lock, keep the display on.

## With Lungo

@Steps {
1. Click the [Lungo](/lungo) icon in the menu bar.
1. Below “Keep this Mac awake”, choose a time, like “2 Hours”, or “Indefinitely”.
1. To let the Mac lock again before the time ends, click the icon, and choose “Deactivate”.
}

“Allow Display to Sleep” in the `…` submenu must be off. When it is on, the display turns off and the Mac locks, but the Mac stays awake. To lock the Mac yourself while Lungo is on, press ++Control+Command+Q++.

Lungo is good for a presentation, a recipe, or a long text, as you do not change the lock settings, and then forget to change them back.

## Without an app

@Steps {
1. Open “[System Settings › Lock Screen](x-apple.systempreferences:com.apple.Lock-Screen-Settings.extension)”.
1. Set “Start Screen Saver when inactive” and “Turn display off when inactive” to longer times, or to “Never”. A MacBook has one setting for battery and one for the power adapter.
1. To lock the Mac only when you lock it yourself, set “Require password after screen saver begins or display is turned off” to a longer time, or “Never”.
}

[Apple’s instructions.](https://support.apple.com/guide/mac-help/mh11784/mac) A Mac from your work can have these settings locked by your company.

The settings change the lock permanently. If someone can use your Mac while you are away, keep a short time, and turn on Lungo only when you need the screen on.

To keep the screen on only for a time, without a change to the settings, run this command in the Terminal app, and press ++Control+C++ to stop it:

```console
caffeinate -d
```

[More ways to keep your Mac awake.](guide:keep-mac-awake)
