---
title: 'How to Clean Up the Downloads Folder Automatically on Mac'
description: 'macOS never cleans up the Downloads folder by itself. Supercharge moves old downloads to another folder after the number of days you choose.'
publicationDate: 2026-11-10
topic: 'finder-and-desktop'
apps: [
	'supercharge'
]
---

@QuickAnswer {
	macOS does not delete old downloads by itself. [Supercharge](../apps/supercharge/index.md) moves the items that have been in Downloads for more than 30 days, or the number of days you choose, to another folder. Then you can look through them, or delete the files in that folder.
}

## With Supercharge

@Steps {
1. Open the settings of [Supercharge](../apps/supercharge/index.md), and click “Tweaks”.
1. In the “File Automation” section, find “Move items in Downloads added more than 30 days ago to”.
1. Click “Choose…”, and choose a folder, like a new folder named “Old” in Downloads.
1. To change the number of days, click the arrows next to “30 days”.
}

It uses the date when the item came into Downloads, not when the file was made or changed. To keep a file in Downloads, give it the tag “Supercharge Ignore”. It only works with the Downloads folder on your Mac. To turn it off, clear the folder.

## Without an app

@Steps {
1. Open the Downloads folder in Finder, and choose “View › as List”.
1. Choose “View › Show View Options”, turn on “Date Added”, and click the “Date Added” column to sort by it.
1. Select the old items, and press ++Command+⌫++ to move them to the Trash.
}

To empty the Trash automatically, turn on “Remove items from the Trash after 30 days” in “Finder › Settings › Advanced”. This only cleans the Trash, not Downloads.

This is fine once in a while. Supercharge is for when you want Downloads to stay tidy without thinking about it.
