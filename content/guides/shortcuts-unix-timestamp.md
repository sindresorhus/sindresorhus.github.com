---
title: 'How to Get a Unix Timestamp in Shortcuts on iPhone and Mac'
description: 'Convert a date to a Unix timestamp, or a timestamp to a date, in the Shortcuts app with the free Actions app, or count the seconds with a built-in action.'
publicationDate: 2026-11-11
topic: 'iphone'
apps: [
	'actions'
]
---

@QuickAnswer {
	A Unix timestamp is the number of seconds since 1 January 1970 (UTC), like 1663178163. The free [Actions](../apps/actions/index.md) app adds the “Convert Date to Unix Timestamp” action to the Shortcuts app, and “Convert Unix Timestamp to Date” for the other direction. Without an app, the “Get Time Between Dates” action can count the seconds.
}

## With Actions

@Steps {
1. Install [Actions](../apps/actions/index.md), and open it once.
1. In your shortcut, add the “Convert Date to Unix Timestamp” action of Actions.
1. In the date field, write “current date” for the time of now, or choose a date variable of the shortcut.
1. Use its result, “Unix Timestamp”, in the next action, like in the request to a web API.
}

The result is in seconds. For milliseconds, which JavaScript uses, expand the action, and turn on the milliseconds option.

To read a timestamp, like one from a web API, add the “Convert Unix Timestamp to Date” action, and give it the number. It also has an option for a timestamp in milliseconds. The result is a date that the other actions of Shortcuts can use, like “Format Date”.

## Without an app

**iPhone and Mac:** Add the “Get Time Between Dates” action, and set it to get the seconds between 1 January 1970 at 00:00 and the current date. Write the first date in UTC, or the result can be wrong by the hours of your time zone.

**Mac only:** Add the “Run Shell Script” action, and type `date +%s`.

The built-in ways are fine for the timestamp of now, but the time zone of the first date is easy to get wrong. The actions of Actions convert in the two directions, and do not depend on your time zone.
