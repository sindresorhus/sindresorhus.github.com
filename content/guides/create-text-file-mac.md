---
title: 'How to Create a New Text File on Mac'
description: 'Make an empty text file in the current Finder folder with Option+N in Supercharge, or with TextEdit or the touch command in Terminal.'
publicationDate: 2026-10-31
topic: 'finder-and-desktop'
apps: [
	'supercharge'
]
---

@QuickAnswer {
	With [Supercharge](../apps/supercharge/index.md), open the folder in Finder and press ++Option+N++. Then type the name, like `notes.txt`. Without an app, make the file in TextEdit and choose “Format › Make Plain Text” before you save it.
}

## With Supercharge

@Steps {
1. Open [Supercharge](../apps/supercharge/index.md), and give it the access that it asks for in [“Device Control and Data Access”](/apps/faq#device-control-access).
1. In Finder, open the folder for the file.
1. Press ++Option+N++. Finder makes an empty file, and selects its name.
1. Type the name with the extension, like `notes.txt`, and press ++Return++.
}

The shortcut is on by default. To change it, or to set a default extension, like `txt` or `md`, open the Supercharge settings, click “Tweaks”, and go to “Create new text file” in the Finder section. There you can also make the file open in an app after you name it.

You can also add “New Text File” to the right-click menu of Finder: in the same section, click “Configure…” next to “Context menu items”. The context menu items do not show in folders that sync with iCloud Drive, Dropbox, and similar services.

## Without an app

Finder has “New Folder”, but no command for a new text file. Make the file in TextEdit:

@Steps {
1. Open TextEdit, and choose “File › New”.
1. Choose “Format › Make Plain Text”, so the file is plain text and not rich text.
1. Choose “File › Save”, type the name, and choose the folder.
}

To make all new TextEdit documents plain text, open “TextEdit › Settings”, and below “Format”, choose “Plain text”.

**Terminal:** Go to the folder with `cd`, and run the `touch` command with the name of the file:

```console
touch notes.txt
```

TextEdit is good for one file with text in it. For empty files in different folders, a shortcut in Finder is faster.
