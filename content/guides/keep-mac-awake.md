---
title: 'How to Keep Your Mac Awake'
description: 'Keep your Mac awake, like while an AI agent works, with Lungo (an alternative to Amphetamine), the caffeinate command, or the sleep settings of macOS.'
publicationDate: 2026-10-29
topic: 'mac'
apps: [
	'lungo'
]
screenshot: {
	number: 1
	description: 'The menu of Lungo with the times to keep the Mac awake'
}
---

@QuickAnswer {
	Click [Lungo](../apps/lungo/index.md) in the menu bar, and choose how long your Mac must stay awake, like 1 hour. Without an app, run `caffeinate -di` in the Terminal app, and press ++Control+C++ to stop it.
}

## With Lungo

@Steps {
1. Open [Lungo](../apps/lungo/index.md). Its icon is in the menu bar.
1. Click the icon, and below “Keep this Mac awake”, choose a duration, like “1 Hour”, or “Indefinitely”.
1. Your Mac and its screen stay awake until the time ends. To stop earlier, click the icon, and choose “Deactivate”.
}

Lungo is useful for presentations, long downloads, and reading without touching the keyboard. In the settings, you can:

- Turn on “Activate on left-click”, so one click turns it on and off.
- Set a keyboard shortcut to turn it on and off.
- Turn on “Allow display to sleep while keeping computer awake”, so the screen turns off, but the downloads and other tasks continue.
- Turn on “Deactivate when switching to battery”, so it does not empty the battery.

For a duration that is not in the menu, use the “Set Enabled State” action of Lungo in the Shortcuts app.

Amphetamine is a popular free app for this, with triggers and support for a closed lid. Its last update was in November 2023.

## Keep your Mac awake with the lid closed

When you close the lid of a MacBook, macOS puts it to sleep. Lungo can keep it awake only when the Mac is connected to a charger and an external display, as the App Store does not allow apps to keep a closed MacBook awake. [Why Lungo does not do more.](../apps/lungo/index.md#lid-closed)

## Without an app

**Terminal:** The `caffeinate` command of macOS keeps the Mac awake while it runs. Open the Terminal app, and run:

```console
caffeinate -di
```

`-d` keeps the screen on, and `-i` keeps the Mac from going to sleep. Press ++Control+C++, or close the window, to stop it. To stop after a time, add the number of seconds, like `caffeinate -di -t 3600` for one hour. To keep the Mac awake only while a long task runs, put the command after it, like `caffeinate -i claude` for Claude Code. Your Mac stays awake until the command ends, like when the AI agent is done.

**System Settings:** To change the sleep settings for all tasks, not only one:

@Steps {
1. Open “[System Settings › Lock Screen](x-apple.systempreferences:com.apple.Lock-Screen-Settings.extension)”, and choose a longer time, or “Never”, for the time before the display turns off. A MacBook has one setting for battery and one for the power adapter.
1. On a MacBook, open “System Settings › Battery”, click “Options”, and turn on “Prevent automatic sleeping on power adapter when the display is off”. On a desktop Mac, open “System Settings › Energy”, and turn on “Prevent automatic sleeping when the display is off”.
}

The settings are good when your Mac must always stay awake, like a Mac mini that is a server. For a meeting or a download, it is easier to turn on Lungo or `caffeinate` for that time, and not to remember to change the settings back.
