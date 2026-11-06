---
title: 'How to Make TextEdit Directly Open a New Empty Document on Mac'
description: 'With iCloud Drive, TextEdit shows a file dialog each time it opens. Make it open a blank document instead, with Supercharge or with a Terminal command.'
publicationDate: 2026-11-11
topic: 'windows-apps-and-dock'
apps: [
	'supercharge'
]
---

@QuickAnswer {
	With iCloud Drive turned on for TextEdit, TextEdit opens with a file dialog, and you must click “New Document” each time. To get a blank document at once, turn on “Open blank document instead of file picker on launch” in [Supercharge](../apps/supercharge/index.md), or change the hidden setting of TextEdit with a Terminal command.
}

## With Supercharge

@Steps {
1. Open the settings of [Supercharge](../apps/supercharge/index.md), and click “Tweaks”.
1. In the “TextEdit” section, turn on “Open blank document instead of file picker on launch”. Supercharge asks for Full Disk Access, as it needs it to change a hidden setting of another app.
1. If TextEdit is open, let Supercharge restart it.
1. Open TextEdit. A blank document opens.
}

To open a file, choose “File › Open” in TextEdit, as before.

## Without an app

**Each time:** In the dialog, click “New Document” at the bottom left, or choose “File › New”. [Apple’s instructions.](https://support.apple.com/guide/textedit/txtee6663a0e/mac)

**Always:** Quit TextEdit, and run this command in the Terminal app:

```console
defaults write com.apple.TextEdit NSShowAppCentricOpenPanelInsteadOfUntitledFile -bool false
```

To get the dialog back, run `defaults delete com.apple.TextEdit NSShowAppCentricOpenPanelInsteadOfUntitledFile`.

The command changes the same setting as Supercharge. Supercharge needs Full Disk Access to change it, so Terminal can need the same access before the command works. If you only want a place for quick notes, see [how to take quick notes on Mac](quick-notes-mac.md).
