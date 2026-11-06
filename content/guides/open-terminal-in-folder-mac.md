---
title: 'How to Open Terminal in a Folder on Mac'
description: 'Open a Terminal window at a Finder folder from the path bar, or from the right-click menu with Supercharge, an alternative to Go2Shell.'
publicationDate: 2026-11-07
topic: 'finder-and-desktop'
apps: [
	'supercharge'
]
---

@QuickAnswer {
	In Finder, choose “View › Show Path Bar”, Control-click the folder in the path bar at the bottom of the window, and choose “Open in Terminal”. To open your terminal app from the right-click menu of a folder or of an empty area of a window, use [Supercharge](../apps/supercharge/index.md).
}

Go2Shell of ZipZapMac opened a terminal at the Finder folder from a button in the toolbar. Its last update (2.5) is from 2019, it needs Rosetta on Apple silicon, and Homebrew disabled it in March 2026 because it is not maintained.

## With Supercharge

@Steps {
1. Open the settings of [Supercharge](../apps/supercharge/index.md), click “Tweaks”, and click “Configure…” next to “Context menu items”.
1. In the “Main Menu” tab, turn on “Open in Terminal”. It has the name of your terminal app, like “Open in Ghostty”.
1. Right-click a folder in Finder, or an empty area of the folder that is open, and choose the item.
}

Supercharge opens the terminal app that is running, or one that is installed, like iTerm, Ghostty, kitty, WezTerm, Alacritty, or Warp, and else Terminal.

The right-click items cannot show in synced folders, like iCloud Drive and Dropbox. There, right-click the folder, and choose “Services › Open in Terminal”.

## Without an app

@Steps {
1. Open the folder in Finder. If you do not see the path bar at the bottom of the window, choose “View › Show Path Bar”.
1. Control-click the folder in the path bar, and choose “Open in Terminal”. For a new tab, choose “Services › New Terminal Tab at Folder”.
}

You can also type `cd ` in Terminal, and drag the folder into the window. The built-in way only opens the Terminal app. Supercharge is faster when you do it often, or when you use another terminal app.
