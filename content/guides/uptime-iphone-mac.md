---
title: 'How to See How Long Your iPhone or Mac Has Been On'
description: 'See the uptime of your iPhone or Mac, with and without the time in sleep, with a shortcut and the Actions app, or with Terminal on Mac.'
publicationDate: 2026-11-13
topic: 'shortcuts'
apps: [
	'actions'
]
---

@QuickAnswer {
	In the Shortcuts app, run the “Get Device Details (Extended)” action of [Actions](../apps/actions/index.md). It shows how long the iPhone or the Mac has been on, with and without the time in sleep. On a Mac, you can also run `uptime` in Terminal.
}

## With Actions

@Steps {
1. Install [Actions](../apps/actions/index.md), and open it one time.
1. In the Shortcuts app, make a new shortcut, and add the “Get Device Details (Extended)” action.
1. Add the “Show Content” action, and run the shortcut.
}

The result shows “Uptime (with sleep)” and “Uptime (without sleep)” in days, hours, and minutes. The time with sleep is the time since the device started. The time without sleep is the time that it was awake.

To use only one value, tap the “Device Details” variable, and choose “Uptime (including sleep)” or “Uptime (not including sleep)”. Use the “Format Duration” action of Actions to make the value readable text. The same shortcut works on iPhone and Mac.

## Without an app

On a Mac, open the Terminal app, and run:

```console
uptime
```

The text after “up” is the time since the Mac started, like “up 2 days, 15:28”. You can also open System Information (hold ++Option++, and choose “Apple menu › System Information…”), click “Software”, and read “Time since boot”. Both include the time in sleep. For the time without sleep, use Actions.
