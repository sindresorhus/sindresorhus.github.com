---
title: 'How to Check If Two Files Are Identical on Mac'
description: 'See if two files have the same content, from the right-click menu of Finder with Supercharge, or with a command in Terminal.'
publicationDate: 2026-11-17
topic: 'finder-and-desktop'
apps: [
	'supercharge'
]
---

@QuickAnswer {
	Select two files in Finder, right-click, and choose “Is Identical?” from [Supercharge](/supercharge). [Without an app](#without-an-app), run `cmp file1 file2` in Terminal: it prints nothing when the files are identical.
}

## With Supercharge

@Steps {
1. Open the settings of [Supercharge](/supercharge), click “Tweaks”, and click “Configure…” next to “Context menu items”.
1. In the “Main Menu” tab, turn on “Is Identical?”.
1. Select two or more files in Finder, and right-click them.
1. If the sizes are different, the menu shows “Not Identical” at once. If not, choose “Is Identical?”. An alert shows “Identical ✓” or “Not Identical”.
}

The names and the dates of the files are not compared, only the content.

To compare files from different folders, also turn on “Is Identical…”. It opens a window where you can drag more files, and it shows which files are identical.

The right-click items cannot show in synced folders, like iCloud Drive and Dropbox. There, select the files, right-click, and choose “Services › Are Files Identical?”.

## Without an app

Use the `cmp` command in Terminal. Replace the paths with your files, or drag the files into the window:

```console
cmp ~/Desktop/photo.jpg ~/Downloads/photo.jpg
```

If it prints nothing, the files are identical. If not, it shows the first position that is different, like “differ: char 1, line 1”.

For two text files, `diff` shows the lines that are different. You can also compare the [SHA-256 checksums](guide:file-checksum-mac) of the two files.

Terminal is fine for two files now and then. Supercharge checks the files that you select in Finder, without typing paths.
