---
title: 'How to Show the Battery Time Remaining on Mac'
description: 'Show the battery percentage in the menu bar with macOS, and the time remaining with Battery Indicator, Activity Monitor, or pmset in Terminal.'
publicationDate: 2026-10-29
topic: 'menu-bar'
apps: [
	'battery-indicator'
]
---

@QuickAnswer {
	The battery menu of macOS does not show the time remaining. [Battery Indicator](../apps/battery-indicator/index.md) shows it in the menu bar. Without an app, see “Time remaining” in the Energy tab of Activity Monitor, or run `pmset -g batt` in the Terminal app. To show only the battery percentage, open “[System Settings › Menu Bar](x-apple.systempreferences:com.apple.ControlCenter-Settings.extension)”, click “Battery Options” for “Battery”, and turn on “Show Percentage”.
}

## With Battery Indicator

@Steps {
1. Open [Battery Indicator](../apps/battery-indicator/index.md). Its icon is in the menu bar.
1. Click the icon, click the “…” button at the bottom of the menu, and choose “Settings…”.
1. In “Menu Bar”, set “Show” to “Time remaining”.
1. To show the time as text, like `4:35`, set “Type” to “Text”.
}

Click the icon to see the time remaining and the time when the battery will be empty. While the Mac charges, it shows the time until the battery is full. When you disconnect the charger, the menu bar shows `…` for a short time, and the menu shows “Calculating Time Remaining…”, while macOS calculates the time.

Battery Indicator can also notify you when the battery is full or at the percentages you choose, and hide its icon while the Mac is on power. Press ++Option++ while the menu is open to see the condition, the health, and the cycle count of the battery.

## Show the battery percentage

The battery item of macOS can show the percentage next to its icon:

@Steps {
1. Open “[System Settings › Menu Bar](x-apple.systempreferences:com.apple.ControlCenter-Settings.extension)”.
1. Select “Battery”, click “Battery Options”, and turn on “Show Percentage”.
}

Battery Indicator shows the time remaining by default, and the percentage when you hover over its item in the menu bar. With “Show” set to “Percentage”, it is the other way around.

## Why macOS does not show the time remaining

macOS showed the time remaining in the battery menu until macOS Sierra 10.12.2. Apple then removed it, as the estimate changes much with what you do on the Mac. The time is only an estimate, also in Battery Indicator, which shows the same number that macOS calculates.

## Without an app

macOS still calculates the time remaining. You can see it in two places:

- **Activity Monitor:** Open Activity Monitor, and click “Energy”. The bottom of the window shows “Time remaining”, while the Mac is on battery.
- **Terminal:** Run this command:

```console
pmset -g batt
```

It shows the percentage and the time, like `85%; discharging; 5:12 remaining`. While the Mac calculates, it shows `(no estimate)`.

The battery menu in the menu bar shows the time until the battery is full while the Mac charges, but not the time remaining on battery.
