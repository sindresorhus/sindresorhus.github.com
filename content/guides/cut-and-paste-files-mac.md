---
title: 'How to Cut and Paste Files on Mac'
description: 'In Finder, copy files with Command+C and move them with Option+Command+V. The Command X app lets you cut and paste with Command+X and Command+V.'
publicationDate: 2026-10-29
topic: 'finder-and-desktop'
apps: [
	'command-x'
]
screenshot: {
	number: 1
	description: 'Files selected in Finder, with the steps to cut and paste them'
}
---

@QuickAnswer {
	Finder has no Cut command for files. Select the files, press ++Command+C++, open the folder to move them to, and press ++Option+Command+V++. To cut and paste with ++Command+X++ and ++Command+V++, like on Windows, use [Command X](../apps/command-x/index.md).
}

## With Command X

@Steps {
1. Open [Command X](../apps/command-x/index.md), and give it the access that it asks for in [“Device Control and Data Access”](/apps/faq#device-control-access). It needs this access to change what the keys do in Finder.
1. Select the files or folders in Finder, and press ++Command+X++.
1. Open the folder to move them to, and press ++Command+V++. The files move.
}

Command X makes Finder copy when you press ++Command+X++ and move when you press ++Command+V++, so Finder itself moves the files. Nothing happens to the files until you paste.

- Open the folder before you paste. Like with copy and paste, a selected folder does not get the files.
- Only the keys work, not the “Paste” command in the menu.
- Command X cannot cut text when you rename a file or type in the search field of Finder. [Supercharge](../apps/supercharge/index.md) has the same feature without this limitation.

## Without an app

Finder can move files with a copy and a “Move Item Here”:

@Steps {
1. Select the files or folders in Finder, and press ++Command+C++.
1. Open the folder to move them to.
1. Press ++Option+Command+V++. Or open the Edit menu, hold ++Option++, and choose “Move Item Here”, which replaces “Paste Item”.
}

You can also drag the files to the other folder. On the same disk, Finder moves them. To another disk, Finder copies them, so hold ++Command++ while you drag to move them.

The built-in way works well when you remember ++Option+Command+V++. Command X is for when your fingers expect ++Command+X++, like when you also use Windows or Linux.
