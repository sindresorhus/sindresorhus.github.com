---
title: 'How to Merge Two Folders on Mac'
description: 'Merge two folders with the same name with the Option key in Finder, or combine folders with different names from the right-click menu with Supercharge.'
publicationDate: 2026-11-17
topic: 'finder-and-desktop'
apps: [
	'supercharge'
]
---

@QuickAnswer {
	To merge two folders with the same name, hold ++Option++, drag one folder to the location of the other, and click “Merge”. To combine folders with different names, select them in Finder, right-click, and choose “Combine Contents of Folders” from [Supercharge](/supercharge).
}

## With Supercharge

@Steps {
1. Open the settings of [Supercharge](/supercharge), click “Tweaks”, and click “Configure…” next to “Context menu items”.
1. In the “Main Menu” tab, turn on “Combine Contents of Folders”.
1. Select two or more folders in Finder, right-click, and choose “Combine Contents of Folders”.
1. Click “Combine”.
}

The items go into the folder whose name is first in alphabetical order. The alert shows its name. A file with the same name as a file in that folder gets a new name, so no file is replaced. The other folders are deleted when they are empty. You cannot undo it.

It moves only the items directly in each folder. A subfolder with the same name in two folders is not merged: it moves with a new name. To move the items of all the subfolders into one folder, [flatten the folder](guide:flatten-folder-mac).

The right-click items cannot show in synced folders, like iCloud Drive and Dropbox. There, select the folders, right-click, and choose “Services › Combine Contents of Folders”.

## Without an app

@Steps {
1. Make sure that the two folders have the same name and are in different locations. If necessary, move one folder to another location, and rename it.
1. Hold ++Option++, and drag one folder to the location that has the other folder.
1. Click “Merge”.
}

“Merge” shows only when one folder has items that the other does not have. When the two folders have different versions of a file with the same name, you can only click “Stop” or “Replace”. <source:https://support.apple.com/guide/mac-help/mh26885/mac>

In Terminal, `ditto` copies the items of one folder into another, and merges the subfolders. It replaces the files with the same name, and it does not delete the first folder.

```console
ditto ~/Desktop/Photos-2 ~/Desktop/Photos
```

The Finder way is fine for two folders with the same name. Supercharge combines many folders with different names at once, and keeps all the files.
