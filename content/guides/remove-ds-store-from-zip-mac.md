---
title: 'How to Remove .DS_Store and __MACOSX from a Zip File on Mac'
description: 'A zip file made on a Mac has .DS_Store files and a __MACOSX folder that people on Windows see. Remove them with the free Actions app, or with zip in Terminal.'
publicationDate: 2026-11-11
topic: 'finder-and-desktop'
apps: [
	'actions'
]
---

@QuickAnswer {
	When you compress a folder in Finder, the zip file gets `.DS_Store` files and a `__MACOSX` folder, which people on Windows and Linux see. The “Clean Zip” action of the free [Actions](../apps/actions/index.md) app removes them from a zip file. Without an app, run `zip -d archive.zip "__MACOSX/*" "*.DS_Store"` in Terminal.
}

## With Actions

Make a shortcut one time, and then use it from the right-click menu of Finder:

@Steps {
1. Install [Actions](../apps/actions/index.md), and open it once.
1. In the Shortcuts app, click the add button to make a new shortcut, and give it a name, like “Clean Zip”.
1. Click the details button in the sidebar, and select “Use as Quick Action”, with “Finder” selected.
1. Add the “Clean Zip” action of Actions. Its file field must show “Shortcut Input”. Then add the “Save File” action of Shortcuts.
1. In Finder, Control-click a zip file, and choose “Quick Actions”, then your shortcut.
1. Choose where to save the clean zip file.
}

If the shortcut is not in “Quick Actions”, choose “Quick Actions › Customize…”, and turn it on. [Apple’s instructions for quick actions.](https://support.apple.com/guide/shortcuts-mac/apd163eb9f95/mac)

The action removes each `.DS_Store` file and the `__MACOSX` folder, and keeps all other files as they are. It does not change the original zip file: you get a clean copy.

## Without an app

Terminal has the `zip` command. To remove the files from a zip file that you already have:

```console
zip -d archive.zip "__MACOSX/*" "*.DS_Store"
```

To make a zip file without them, do not use “Compress” in Finder. Go to the folder that contains your folder, and run:

```console
zip -r archive.zip folder -x "*.DS_Store"
```

The `zip` command does not add a `__MACOSX` folder, and `-x` leaves out the `.DS_Store` files.

Both ways give the same result. Terminal is fast when you know it. The shortcut is easier when you send zip files often, as it is two clicks in Finder.
