---
title: 'How to Show the Week Number on iPhone'
description: 'Show the week number on the Lock Screen or the Home Screen of your iPhone with a widget of Any Text, or turn on the week numbers of the Calendar app.'
publicationDate: 2026-11-13
topic: 'iphone'
apps: [
	'any-text'
]
---

@QuickAnswer {
	iOS has no widget for the week number. With [Any Text](../apps/any-text/index.md), a shortcut writes the week number in a widget, an automation runs it each day, and you put the widget on the Lock Screen or the Home Screen. Without an app, turn on “Week Numbers” in the settings of the Calendar app, which shows them in the calendar.
}

## With Any Text

@Steps {
1. In the Shortcuts app, make a new shortcut, and add the “Format Date” action, with “Current Date” as the date. Set “Date Format” to “Custom”, and type `w` in “Format String”.
1. Add the “Set Widget Text” action of [Any Text](../apps/any-text/index.md). Keep “Widget 1”, and type “Week ” and the “Formatted Date” variable as the text.
1. Run the shortcut one time, so the widget gets the number now.
1. Make the shortcut run each day with a “Time of Day” automation, like at 0:05. [Apple’s instructions for automations.](https://support.apple.com/guide/shortcuts/apdfbdbd7123/ios) Then tap the Info button of the shortcut, tap “Privacy”, and turn on “Allow Running When Locked”, so it runs without asking.
1. Add the widget of “Widget 1” to the Lock Screen or the Home Screen. [How to add it.](add-text-to-iphone-lock-screen.md)
}

The number follows the region settings of the iPhone, like the Calendar app does. iOS can update the widget some minutes after the automation runs.

## Without an app

The Calendar app can show week numbers ([Apple’s guide](https://support.apple.com/guide/iphone/iphc37be2016/ios)):

@Steps {
1. Open the Settings app, tap “Apps”, and tap “Calendar”.
1. Turn on “Week Numbers”.
}

The Calendar app then shows the number next to each week. This is free, and it is enough when you look up a week now and then. But you must open the Calendar app to see it.
