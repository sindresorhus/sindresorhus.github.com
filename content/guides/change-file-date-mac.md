---
title: 'How to Change the Creation and Modification Date of a File on Mac'
description: 'Finder cannot change the dates of a file. Set the date created or the date modified with the free Actions app in Shortcuts, or with touch in Terminal.'
publicationDate: 2026-11-11
topic: 'finder-and-desktop'
apps: [
	'actions'
]
---

@QuickAnswer {
	Finder shows the dates of a file, but cannot change them. The free [Actions](../apps/actions/index.md) app adds the “Set Creation and Modification Date of File” action to the Shortcuts app, which sets the creation date, the modification date, or both. Without an app, use the `touch` command in Terminal.
}

## With Actions

@Steps {
1. Install [Actions](../apps/actions/index.md), and open it once.
1. In the Shortcuts app, click the add button to make a new shortcut.
1. Add the “Set Creation and Modification Date of File” action of Actions.
1. In the action, click the file field, and choose the file.
1. Click “Creation and Modification Date” to choose which date to set: “Creation Date”, “Modification Date”, or both.
1. Click the date field, and set the date and the time.
1. Click the arrow in the action to show more options, and turn on “Modify Original”. Without it, the action changes only a copy inside the shortcut.
1. Run the shortcut.
}

“Modify Original” only works when you choose the file directly in the action, not when the file comes from another action. For a file in iCloud Drive, the modification date may not stay, as iCloud changes it when it syncs.

For a photo or a video, the date that the Photos app shows is the capture date inside the file, not the file date. Use the “Set Image/Video Capture Date” action of Actions for it.

## Without an app

Open the Terminal app, and run `touch` with the date as year, month, day, hour, and minute. This sets the modification date to 1 January 2020 at 12:00:

```console
touch -t 202001011200 ~/Desktop/file.txt
```

When the new date is before the creation date, macOS moves the creation date back to it too. So `touch` can set both dates to a date in the past, but it cannot set only the creation date, or set the creation date to a later date.

To see the dates, select the file in Finder, and press ++Command+I++. `touch` is enough when you only move the dates back. The action can set the creation date, the modification date, or both, also to a later date.
