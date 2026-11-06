---
title: 'How to Remove the Caps Lock Delay on Mac'
description: 'Make Caps Lock turn on at once, without the short delay of macOS, with Supercharge or with the hidutil command in Terminal.'
publicationDate: 2026-11-06
topic: 'keyboard-and-trackpad'
apps: [
	'supercharge'
]
---

@QuickAnswer {
	In the settings of [Supercharge](../apps/supercharge/index.md), turn on “Remove Caps Lock activation delay”. Without an app, run `hidutil property --set '{"CapsLockDelayOverride":0}'` in the Terminal app after each restart.
}

On a Mac, a quick press of ++Caps Lock++ often does nothing. macOS waits a moment before it turns on Caps Lock, so that you do not turn it on by accident. If you type fast, the delay makes you miss capital letters.

## With Supercharge

@Steps {
1. Open [Supercharge](../apps/supercharge/index.md), and open its settings.
1. Click “Tweaks”, and in the Keyboard section, turn on “Remove Caps Lock activation delay”. You can also search for “caps” in the settings.
1. Press ++Caps Lock++. It turns on at once.
}

Supercharge removes the delay each time it starts, and again after your Mac wakes from sleep, so it stays off. When you turn the setting off, the delay comes back after the next restart of the Mac.

## Without an app

macOS has no setting for the delay, but the `hidutil` command of macOS can remove it. Open the Terminal app, and run:

```console
hidutil property --set '{"CapsLockDelayOverride":0}'
```

The delay comes back when you restart the Mac, so you must run the command again after each restart. This is the same command that Supercharge runs for you.
