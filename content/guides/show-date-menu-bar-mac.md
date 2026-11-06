---
title: 'How to Show the Date in the Mac Menu Bar'
description: 'Show the date in the menu bar with the clock settings of macOS, or show the full date, the year, and the week number in your own format with Dato.'
publicationDate: 2026-10-30
topic: 'menu-bar'
apps: [
	'dato'
]
screenshot: {
	number: 1
	description: 'The date in the menu bar, with the calendar and the events of Dato below it'
}
---

@QuickAnswer {
	Open “[System Settings › Menu Bar](x-apple.systempreferences:com.apple.ControlCenter-Settings.extension)”, click “Clock Options…” in “Menu Bar Controls”, and set “Show date” to “Always”. macOS then shows the day and the month, but not the year, and you cannot change the format. To show the year, the week number, or your own format, use [Dato](../apps/dato/index.md).
}

## With Dato

@Steps {
1. Open [Dato](../apps/dato/index.md). It shows the day of the week and the time in the menu bar.
1. Right-click the Dato item in the menu bar, and choose “Settings…”.
1. Click “Menu Bar”, and below “Show”, turn on “Date”. Turn on “Week number” too, if you want it.
1. To use your own format, like with the year, write a pattern in “Custom date & time format”, like `EEEE d MMMM yyyy`. Below the setting, Dato shows how the menu bar will look.
}

The custom format replaces the “Show” settings. For example, `yyyy-MM-dd HH:mm` shows the date and the time in the [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format, and `D` shows the day of the year. [More about the format.](https://www.unicode.org/reports/tr35/tr35-dates.html)

Click the date in the menu bar to see a calendar with your events. To show the date above the time, and use less space in a full menu bar, turn on “Two lines”.

macOS always shows its own clock in the menu bar. So that the date does not show two times, set “Show date” to “Never” in the clock options of macOS, like in the steps below. [How to hide the clock of macOS.](../apps/dato/index.md#macos11-hide-clock)

## Without an app

The menu bar clock of macOS can show the date:

@Steps {
1. Open “[System Settings › Menu Bar](x-apple.systempreferences:com.apple.ControlCenter-Settings.extension)”.
1. In “Menu Bar Controls”, click “Clock Options…”.
1. Below “Date”, set “Show date” to “Always”. “When Space Allows” hides the date when the menu bar is full.
1. To show the day of the week, turn on “Show the day of the week”.
}

The order of the day and the month comes from the region in “[System Settings › General › Language & Region](x-apple.systempreferences:com.apple.Localization-Settings.extension)”. This is enough if you only want to see the day and the month. macOS cannot show the year or the week number in the menu bar, and you cannot write your own format.
