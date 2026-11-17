---
title: 'How to Make a Tally Counter on iPhone'
description: 'Make a tally counter shortcut on iPhone that adds 1 with each tap and remembers the count, with the Counter action of the free Actions app.'
publicationDate: 2026-11-13
topic: 'iphone'
apps: [
	'actions'
]
---

@QuickAnswer {
	The Shortcuts app has no action that remembers a number from one run to the next. The “Counter” action of the free [Actions](/actions) app can. Make a shortcut that adds 1 to a counter and shows the count, and put it on the Home Screen, so each tap counts one more.
}

## With Actions

@Steps {
1. Install [Actions](/actions), and open it once.
1. In the Shortcuts app, make a new shortcut, and add the [“Counter”](/actions#:~:text=Counter) action. Keep “Increment”, and type a name for the counter, like `coffee`. With no number, it adds 1.
1. Add the “Show Notification” action, and put the result of the counter in its text.
1. Tap the Details button, tap “Add to Home Screen”, and tap “Add”.
1. Tap the icon to count. The notification shows the new count.
}

To count down, make a second shortcut with “Decrement”. The count never goes below 0. To start again, use “Set” with 0, and to only see the count, use “Get”. Use another name for each thing that you count.

The counters are only on this device. They do not sync to your other devices with iCloud.

## Without an app

The Shortcuts app has no counter. A shortcut can keep the count in a text file with the “Get File from Folder” and “Save File” actions, but it needs more actions, and you must handle the first run, when the file is not there.

To count with no shortcut, use a note in the Notes app, and type a mark for each count. This is fine for a few counts. Actions is faster when you count many times a day, like glasses of water.
