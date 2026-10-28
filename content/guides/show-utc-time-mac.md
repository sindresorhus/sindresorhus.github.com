---
title: 'How to Show UTC Time on Mac'
description: 'See the time in UTC in the menu bar with the free UTC Time app, and copy it as ISO 8601 or Unix time, or get it with a command in Terminal.'
publicationDate: 2026-10-31
topic: 'menu-bar'
apps: [
	'utc-time'
]
---

@QuickAnswer {
	Open the free [UTC Time](../apps/utc-time/index.md) app. It shows the time in UTC in the menu bar, next to your own clock. Without an app, run `date -u` in the Terminal app.
}

## With UTC Time

@Steps {
1. Open [UTC Time](../apps/utc-time/index.md). The time in UTC shows in the menu bar.
1. Click it to see the date in UTC, and how many hours it is behind or ahead of your time.
1. To copy the time, choose a format below “Copy”, like “ISO8601 Date & Time” or “Unix Time in Seconds”.
}

ISO 8601 is like `2026-10-31T14:05:00Z`, and Unix time is the number of seconds or milliseconds since 1970. In the settings, you can show the date, the day of the week, and the “UTC” text in the menu bar. UTC Time also has a widget, and a “Get Time and Date in UTC” action for the Shortcuts app.

To show other time zones too, use [Zone Bar](../apps/zone-bar/index.md). [How to show time zones in the menu bar.](show-time-zones-menu-bar-mac.md)

## Without an app

The menu bar clock of macOS shows only your own time zone. To see the time in UTC, open the Terminal app, and run this command:

```console
date -u
```

The Clock app and its World Clock widget show the time in cities, not in UTC. A city that uses UTC all year, without daylight saving time, like Reykjavík, shows the same time. This is fine if you only check the time sometimes. If you work with servers, logs, or people in many time zones, it is easier to have UTC in the menu bar.
