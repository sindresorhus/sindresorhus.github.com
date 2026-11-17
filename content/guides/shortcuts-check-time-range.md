---
title: 'How to Check if the Time Is Between Two Times in Shortcuts on iPhone and Mac'
description: 'Check in a shortcut if it is now between two times, also past midnight, like 22:00 to 06:00, with the free Actions app or with the If action of Shortcuts.'
publicationDate: 2026-11-22
topic: 'shortcuts'
apps: [
	'actions'
]
---

@QuickAnswer {
	Add the “Is Time In Range” action of the free [Actions](/actions) app, set the start and the end time, and check its result in an “If” action. It also works for a range past midnight. [Without an app](#without-an-app), use the “If” action with “Current Date” and “is between”.
}

## With Actions

@Steps {
1. Install [Actions](/actions), and open it once.
1. In your shortcut, add the [“Is Time In Range”](/actions#:~:text=Is%20Time%20In%20Range) action of Actions.
1. Set the start and the end of the range, like 22:00 and 06:00. Leave the first field, the time to check, empty to use the time now.
1. Add an “If” action below it that checks if the result is true, and put the actions for that time in the “If” part.
}

The action uses only the time of day, not the date, so the same shortcut works each day. When the start is later than the end, like 22:00 to 06:00, the range goes past midnight. The start and the end time are in the range.

## Without an app

The “If” action can compare dates:

@Steps {
1. Add an “If” action, and choose “Current Date” as the input.
1. Choose “is between”, and type the two times, like 09:00 and 17:00.
1. Put the actions for that time in the “If” part.
}

The times are times of today, so this works when the range is in one day. For a range past midnight, like 22:00 to 06:00, use two conditions with “Add Condition”: “is after” 22:00, and “is before” 06:00. Then choose “Any”, so one of them is enough.

The action of Actions does it in one action.
