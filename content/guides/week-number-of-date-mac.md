---
title: 'How to Find the Week Number of a Date on Mac'
description: 'See which week a date is in, like a deadline or a holiday, with the free Week Number app in the menu bar, or with the Calendar app.'
publicationDate: 2026-11-17
topic: 'mac'
apps: [
	'week-number'
]
---

@QuickAnswer {
	Click the week number of the free [Week Number](/week-number) app in the menu bar, choose “Find Week Number”, and choose the date. [Without an app](#without-an-app), turn on “Show week numbers” in the settings of the Calendar app, and go to the date.
}

## With Week Number

@Steps {
1. Click the week number of [Week Number](/week-number) in the menu bar, and choose “Find Week Number”. Or press ++F++ while the menu is open.
1. Change the date in the date field of the window.
1. The window shows the week number of the date.
}

The window stays on top of other windows, so you can keep it open while you plan. Click the reset button next to the date to go back to today. To get the week number of a date in a shortcut, use the “Get Week Number” action in the Shortcuts app.

Week Number uses the week numbering of your Mac. If you expect another week number, like in the last days of December, your Mac may use a rule other than the ISO 8601 week numbers. [How to use ISO 8601 week numbers.](/week-number#iso-week-number)

## Without an app

**Calendar:** The Calendar app can show the week numbers:

@Steps {
1. Open the Calendar app, and choose “Calendar › Settings”.
1. Click “Advanced”, and turn on “Show week numbers”.
1. Choose “View › Go to Date…”, type the date, and click “Show”. The week numbers show in the Week, Month, and Year views ([Apple’s instructions](https://support.apple.com/guide/calendar/icl26670/mac)).
}

**Terminal:** This command shows the ISO 8601 week number of a date, like 53 for December 31, 2026:

```console
date -j -f "%Y-%m-%d" 2026-12-31 +%V
```

The Calendar app is good when you plan in it anyway. Week Number is faster for a quick check, and it also shows the current week in the menu bar all the time. [How to show the week number in the menu bar.](guide:show-week-number-menu-bar-mac)
