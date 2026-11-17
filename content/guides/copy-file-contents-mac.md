---
title: 'How to Copy the Contents of a File to the Clipboard on Mac'
description: 'Copy the text of a file without opening it, from the right-click menu of Finder with Supercharge, or with a command in Terminal.'
publicationDate: 2026-11-17
topic: 'finder-and-desktop'
apps: [
	'supercharge'
]
---

@QuickAnswer {
	Right-click a text file in Finder, and choose “Copy Contents” from [Supercharge](/supercharge). [Without an app](#without-an-app), run `pbcopy < file.txt` in Terminal. You can then paste the text, like a log or a settings file, in a message or an issue.
}

## With Supercharge

@Steps {
1. Open the settings of [Supercharge](/supercharge), click “Tweaks”, and click “Configure…” next to “Context menu items”.
1. In the “Main Menu” tab, turn on “Copy Contents”.
1. Right-click a text file in Finder, like a `.txt`, `.md`, `.json`, or `.log` file, or a script, and choose “Copy Contents”.
1. Paste the text where you need it.
}

The item shows only for text files, not for documents like PDF or Pages files.

The right-click items cannot show in synced folders, like iCloud Drive and Dropbox. There, right-click the file, and choose “Services › Copy File Contents”.

## Without an app

Open the file in TextEdit, press ++Command+A++ to select all the text, and press ++Command+C++.

Or use the `pbcopy` command in Terminal. Replace the path with your file, or drag the file into the window:

```console
pbcopy < ~/Desktop/notes.txt
```

The built-in ways are fine for a file now and then. Supercharge copies the text with one click, without opening the file.
