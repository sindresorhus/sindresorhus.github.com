---
title: 'How to Get a Notification When Your MacBook Is Charged'
description: 'Get a notification when the battery of your MacBook is full, or at a level like 80%, with Battery Indicator, or with a Shortcuts automation on macOS 26.'
publicationDate: 2026-11-23
topic: 'mac'
apps: [
	'battery-indicator'
]
---

@QuickAnswer {
	In the settings of [Battery Indicator](/battery-indicator), turn on “Notify when fully charged”. For a level like 80%, select it in the “Charging” column of “Notify at percentages”. [Without an app](#without-an-app), make a Shortcuts automation with the “Battery Level” trigger.
}

## With Battery Indicator

@Steps {
1. Open the settings of [Battery Indicator](/battery-indicator), and click “General”.
1. Turn on “Notify when fully charged”. The notification is “Fully Charged”.
1. For an earlier notification, click “Choose…” next to “Notify at percentages”, and select the percentage in the “Charging” column, like 80%.
}

Unplug the charger when you get the notification, if you want to keep the battery below 100%. If you get no notification, click “Notification Settings” below the settings, and allow notifications for Battery Indicator.

@Tips {
- The “On battery” column of the same settings gives a warning while the battery runs down. [How to get a low battery alert.](guide:low-battery-alert-mac)
- When the charge stops before 100%, macOS holds the charge to make the battery last longer. [Why it says “Charging On Hold”.](/battery-indicator#charging-on-hold)
}

## Without an app

On macOS 26 and later, the Shortcuts app on Mac has automations, also for the battery level. <source:https://support.apple.com/125148>

@Steps {
1. In the Shortcuts app, add an automation with the “Battery Level” trigger, and choose “Rises Above” and a level, like 80%.
1. As the action, add “Show Notification” with a text, like “Unplug the charger”.
}

This works well for one level, and it is free. You need one automation for each level. Battery Indicator has all the levels in one setting.
