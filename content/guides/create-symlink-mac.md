---
title: 'How to Create a Symbolic Link on Mac'
description: 'Make a symlink to a file or folder with the ln command in Terminal, or from the right-click menu of Finder with Supercharge.'
publicationDate: 2026-11-17
topic: 'finder-and-desktop'
apps: [
	'supercharge'
]
---

@QuickAnswer {
	In Terminal, type `ln -s`, then the path of the original, then the path of the new link. To make a symlink from the right-click menu of Finder, use “Make Symlink” from [Supercharge](/supercharge).
}

## With Supercharge

@Steps {
1. Open the settings of [Supercharge](/supercharge), click “Tweaks”, and click “Configure…” next to “Context menu items”.
1. In the “Main Menu” tab, turn on “Make Symlink”.
1. Right-click a file or folder in Finder, and choose “Make Symlink”. For many items, choose “Make Symlinks”.
1. The link “Symlink - name” shows next to the original, and Finder selects it. Rename it, and drag it to where you need it.
}

The link has the full path of the original. So it keeps working when you move the link, but not when you move or rename the original. If you cannot write to the folder of the original, the link goes in your Downloads folder.

To find the original of a symlink, also turn on “Show Symlink Original”. Then right-click the symlink, and choose “Show Original”.

The right-click items cannot show in synced folders, like iCloud Drive and Dropbox. There, right-click the item, and choose “Services › Make Symlink”.

## Without an app

Use the `ln -s` command in Terminal. Put the paths in quotes when they have spaces. To type a path, you can drag the item into the Terminal window.

```console
ln -s "/Users/you/Projects/site" "/Users/you/Desktop/site"
```

Finder can make an alias: select the item, and choose “File › Make Alias”, or press ++Control+Command+A++. An alias is another kind of link. Finder and most Mac apps open it, but Terminal and many developer tools do not follow it. For those, use a symlink. [Apple’s instructions for aliases.](https://support.apple.com/guide/mac-help/mchlp1046/mac)

Terminal is fine for a link now and then. Supercharge makes the link with one click, without typing paths.
