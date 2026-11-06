---
title: 'How to Make a File Executable on Mac'
description: 'Make a shell script executable with chmod in Terminal, or with a Make Executable item in the right-click menu of Finder from Supercharge.'
publicationDate: 2026-11-07
topic: 'finder-and-desktop'
apps: [
	'supercharge'
]
---

@QuickAnswer {
	Open Terminal, type `chmod +x ` with a space at the end, drag the file into the window, and press ++Return++. To do it from the right-click menu of Finder, use “Make Executable” from [Supercharge](../apps/supercharge/index.md).
}

## With Supercharge

@Steps {
1. Open the settings of [Supercharge](../apps/supercharge/index.md), click “Tweaks”, and click “Configure…” next to “Context menu items”.
1. In the “Main Menu” tab, turn on “Make Executable”.
1. Right-click the file in Finder, and choose “Make Executable”.
}

The item only shows for files that are not executable yet, and not for images, audio, video, PDF files, archives, or fonts. It is useful for shell scripts, like a `.command` file that you then open with a double-click.

The right-click items cannot show in synced folders, like iCloud Drive and Dropbox. There, right-click the file, and choose “Services › Make File Executable”.

## Without an app

macOS does it with a command in Terminal. Replace the path with your file, or drag the file into the window:

```console
chmod +x ~/Desktop/script.sh
```

Then run the script with its path, like `~/Desktop/script.sh`. The Terminal way is fine when you already work in Terminal. Supercharge is faster when you start in Finder.
