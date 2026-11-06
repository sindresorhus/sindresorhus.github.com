---
title: 'How to Calculate the Time Between Two Dates on Mac'
description: 'See the time between two dates, the working days until a deadline, or the date 90 days from today, with the date calculator of Dato, or with Numbers.'
publicationDate: 2026-11-11
topic: 'mac'
apps: [
	'dato'
]
---

@QuickAnswer {
	Click [Dato](../apps/dato/index.md) in the menu bar, press ++C++ to open its calculator, click “Interval”, and choose the two dates. It shows the time between them, and it can count only the weekdays. Without an app, use the `DAYS` function in a Numbers spreadsheet.
}

## With Dato

@Steps {
1. Click [Dato](../apps/dato/index.md) in the menu bar.
1. Press ++C++, or open the “…” menu, and choose “Calculators…”.
1. Click “Interval”.
1. Choose the dates in “From:” and “To:”. The difference shows below them.
1. Click “Copy” to copy the result.
}

The result is in years and days, like “1 year, 60 days”, with the same time in months or weeks below it. So for two dates that are more than a year apart, you do not get one total number of days. Turn on “Exclude weekends” to count only the weekdays, like the working days until a deadline, or “Include end date” to also count the last day. “Show time” adds a time to the two dates, but then the other two options are not available.

The “Add/subtract” tab does the opposite: it gives the date that is some years, months, weeks, days, hours, or minutes after a date, like 90 days from today. Use a negative number, like -10, for a date before it.

## Without an app

Numbers, the spreadsheet app of Apple, has a function for this. In a spreadsheet, click a cell, and type the function with your dates. The end date is first:

```
=DAYS("12/31/2025", "1/1/2025")
```

The cell shows 364. [Apple’s instructions.](https://support.apple.com/guide/functions/days-fd13ea8d75/web) The `DATEDIF` function gives the months or the years between two dates, and `NETWORKDAYS` gives the working days.

Numbers always gives the total number of days, and it is good when you have many dates. For one quick answer, Dato is faster, as its calculator is one click and one key away.
