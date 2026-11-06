---
title: 'How to Open a .DS_Store File on Mac'
description: 'See what a .DS_Store file stores, like icon positions, the view, and the sort order of a folder, with the free DS_Store Inspector app.'
publicationDate: 2026-11-06
topic: 'finder-and-desktop'
apps: [
	'ds-store-inspector'
]
screenshot: {
	number: 1
	description: 'The records of the .DS_Store file of the Downloads folder, with their types and values'
}
---

@QuickAnswer {
	Drop the folder, or its `.DS_Store` file, on the window of the free [DS_Store Inspector](../apps/ds-store-inspector/index.md) app. It shows each record in a table, like the icon position, the view, and the sort order of each item. macOS has no app that can read the file, which is in a binary format.
}

A `.DS_Store` file is a hidden file that Finder makes in the folders that you open. It keeps the view settings of the folder, like the icon positions, the window size, and the sort order. It has no documents, but it has the names of the items in the folder, and their Finder comments.

## With DS_Store Inspector

@Steps {
1. Open [DS_Store Inspector](../apps/ds-store-inspector/index.md).
1. Choose “File › Open…”, and select a folder. Or drop the folder, or its `.DS_Store` file, on the window.
1. The table shows each record of the file: the name of the item, the type of the record, like “Icon Location”, and its value.
}

Type in the search field to see only the records of some items. The app does not change the file. To make Finder forget the view settings of the folder, choose “File › Delete .DS_Store”, which moves the file to the Trash.

## Without an app

To see the file in Finder, open the folder, and press ++Shift+Command+.++ to show the hidden files. Press it again to hide them.

macOS has no app that can read the file. To see its raw bytes, open the Terminal app, go to the folder with `cd`, and run:

```console
xxd .DS_Store | less
```

You can find the names of the items in the bytes, but the values are binary, so the settings are hard to read. You can delete the file safely. Finder then uses its default view for the folder, and makes a new file when you change the view.
