---
title: 'How to Check the SHA-256 Checksum of a File on Mac'
description: 'Get the SHA-256 checksum of a file with a command in Terminal, or copy it from the right-click menu of Finder with Supercharge.'
publicationDate: 2026-11-07
topic: 'finder-and-desktop'
apps: [
	'supercharge'
]
---

@QuickAnswer {
	Open Terminal, type `shasum -a 256 ` with a space at the end, drag the file into the window, and press ++Return++. Compare the result with the checksum on the download page. To copy the checksum from the right-click menu of Finder, use [Supercharge](../apps/supercharge/index.md).
}

## With Supercharge

@Steps {
1. Open the settings of [Supercharge](../apps/supercharge/index.md), click “Tweaks”, and click “Configure…” next to “Context menu items”.
1. In the “Main Menu” tab, turn on “Copy Checksum”.
1. Right-click the file in Finder, and choose “Copy Checksum › SHA-256”.
1. Paste the checksum next to the one on the download page, or in the search field of the page with ++Command+F++, to see that they are the same.
}

The submenu also has SHA-512, MD5, CRC32, SHA-1, and SHA-384. It only shows for files, not for folders.

The right-click items cannot show in synced folders, like iCloud Drive and Dropbox. There, right-click the file, and choose “Services › Copy SHA-256 Checksum”.

## Without an app

macOS has the commands in Terminal. Replace the path with your file, or drag the file into the window:

```console
shasum -a 256 ~/Downloads/file.dmg
```

The result is the checksum, then the path. For other algorithms:

```console
shasum -a 512 ~/Downloads/file.dmg
md5 ~/Downloads/file.dmg
```

If the checksums are not the same, the file changed or did not download completely. Download it again. The Terminal way is fine for a file now and then. Supercharge is faster when you check files often.
