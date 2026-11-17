---
title: 'How to Copy a List of File Names on Mac'
description: 'Copy the names of many files as text, one on each line, for Numbers or Excel. Use the right-click menu of Finder with Supercharge, TextEdit, or Terminal.'
publicationDate: 2026-11-17
topic: 'finder-and-desktop'
apps: [
	'supercharge'
]
---

@QuickAnswer {
	Select the files in Finder, right-click, and choose “Copy Filenames” from [Supercharge](/supercharge). You get one name on each line, which you can paste in Numbers, Excel, or a document. [Without an app](#without-an-app), copy the files in Finder, and paste them in a plain text document in TextEdit, which gives their names.
}

## With Supercharge

@Steps {
1. Open the settings of [Supercharge](/supercharge), click “Tweaks”, and click “Configure…” next to “Context menu items”.
1. In the “Main Menu” tab, turn on “Copy Filename”.
1. Select the files in Finder. To select all the files of a folder, press ++Command+A++.
1. Right-click the files, and choose “Copy Filenames”. For one file, the item is “Copy Filename”.
1. Paste the names. In a spreadsheet, each name goes in its own row.
}

The names include the file extension, like `report.pdf`. To copy the full paths, use “Copy Path”. See [how to copy a file path](guide:copy-file-path-mac).

The right-click items cannot show in synced folders, like iCloud Drive and Dropbox. There, select the files, right-click, and choose “Services › Copy Filename”.

## Without an app

Finder copies the names of the files as text too:

@Steps {
1. In Finder, select the files, and press ++Command+C++.
1. In TextEdit, make a new document, and choose “Format › Make Plain Text”.
1. Press ++Command+V++. The names show one on each line, and you can copy them from there.
}

In Terminal, [go to the folder](guide:open-terminal-in-folder-mac), and copy the names of all its items, one on each line:

```console
cd ~/Documents/Invoices
ls | pbcopy
```

To copy only some files, use a pattern, like `ls *.pdf | pbcopy`. Supercharge copies the names in one step, without a document in between.
