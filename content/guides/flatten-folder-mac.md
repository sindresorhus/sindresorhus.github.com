---
title: 'How to Flatten a Folder on Mac'
description: 'Move all the files from the subfolders of a folder into the folder itself with one click in Supercharge, or with a search in Finder.'
publicationDate: 2026-11-17
topic: 'finder-and-desktop'
apps: [
	'supercharge'
]
---

@QuickAnswer {
	Right-click the folder in Finder, and choose “Flatten Folder” from [Supercharge](/supercharge). All the files in its subfolders move into the folder, and the empty subfolders are deleted. [Without an app](#without-an-app), search the folder for files in Finder, select them all, and drag them into the folder.
}

## With Supercharge

@Steps {
1. Open the settings of [Supercharge](/supercharge), click “Tweaks”, and click “Configure…” next to “Context menu items”.
1. In the “Main Menu” tab, turn on “Flatten Folder”.
1. Right-click the folder in Finder, and choose “Flatten Folder”. You can also right-click an empty area in the window of the folder.
1. Click “Flatten”.
}

All the files from all levels of subfolders go into the folder. When two files have the same name, Supercharge adds a number to one of them, so no file is replaced. Apps and other packages move as one item. The empty subfolders are deleted, and you cannot undo it, so make a copy of the folder first if you are not sure.

The item shows only when you select one folder that has files in its subfolders. Supercharge also moves hidden files. The right-click items cannot show in synced folders, like iCloud Drive and Dropbox. There, right-click the folder, and choose “Services › Flatten Folder”.

## Without an app

A search in Finder can find all the files in a folder and its subfolders ([Apple’s instructions](https://support.apple.com/guide/mac-help/mh15155/mac)):

@Steps {
1. Open the folder in Finder, and press ++Command+F++.
1. Next to “Search:”, click the name of the folder, not “This Mac”, so the search is only in that folder.
1. Click the Add button (+) at the right, below the search field. Choose “Kind”, and then a kind of file, like “Document” or “Image”, so the results do not have the subfolders.
1. Select all the results with ++Command+A++, and drag them onto the folder in another Finder window.
}

When a file with the same name is already in the folder, Finder asks what to do. Then delete the empty subfolders yourself. This takes more steps, and it is easy to miss files of another kind.
