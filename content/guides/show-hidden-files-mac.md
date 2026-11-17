---
title: 'How to Show Hidden Files on Mac'
description: 'Show the hidden files and folders in Finder for now with a keyboard shortcut, or always with a setting of Supercharge.'
publicationDate: 2026-11-17
topic: 'finder-and-desktop'
isForNewMacOwners: true
shortcut: 'Shift+Command+.'
apps: [
	'supercharge'
]
---

@QuickAnswer {
	In a Finder window, press ++Shift+Command+.++ to show the hidden files, and press it again to hide them. To always show them, turn on “Show hidden files” in the settings of [Supercharge](/supercharge).
}

Hidden files are files that Finder does not show, like files with a name that starts with a dot, such as `.gitignore` and `.env`.

## With Supercharge

@Steps {
1. Open the settings of [Supercharge](/supercharge), and click “Tweaks”.
1. In the “Finder” section, turn on “Show hidden files”.
1. Finder restarts, and then shows the hidden files in all windows.
}

To hide them again, turn off the setting.

@Tips {
- To show or hide them only for now, turn on “Toggle Hidden Files” in the “Main Menu” tab of “Tweaks › Context menu items › Configure…”. Then right-click an empty area of a Finder window, and choose “Toggle Hidden Files”. This change goes back when Finder restarts.
- To show or hide them with a keyboard shortcut from any app, use the “Toggle Hidden Files in Finder” action of Supercharge in the Shortcuts app, and give the shortcut a keyboard shortcut.
}

## Without an app

**Keyboard shortcut:** In a Finder window, press ++Shift+Command+.++ (period). Press it again to hide the files. The change is temporary.

**Terminal:** To always show hidden files, run this command in the Terminal app. It changes the setting of Finder, and restarts Finder:

```console
defaults write com.apple.finder AppleShowAllFiles -bool true && killall Finder
```

To hide them again, run the same command with `false` instead of `true`.

The keyboard shortcut is enough if you need hidden files sometimes. Use the setting of Supercharge or the command if you often work with them, like with the config files of developer tools.
