---
title: 'How to Change the Screenshot Format on Mac'
description: 'macOS saves screenshots as PNG files. Change the format to JPG, HEIC, or TIFF with one Terminal command, or change it from a shortcut with Shortcutie.'
publicationDate: 2026-11-11
topic: 'text-images-and-sound'
apps: [
	'shortcutie'
]
---

@QuickAnswer {
	macOS saves screenshots as PNG files, which can be large. To save them as JPG, run `defaults write com.apple.screencapture type jpg` in the Terminal app. To change the format without Terminal, or to change it often, use the “Set Screenshot Format” action of [Shortcutie](../apps/shortcutie/index.md) in the Shortcuts app.
}

## With Shortcutie

For a change that you make one time, the Terminal command below is enough. A shortcut is better when you use more than one format, like JPG for the screenshots that you send, and PNG for the ones that must be sharp:

@Steps {
1. Install [Shortcutie](../apps/shortcutie/index.md), and open it once.
1. In the Shortcuts app, click the add button to make a new shortcut.
1. Add the “Set Screenshot Format” action of Shortcutie, and choose “PNG”, “JPEG”, “TIFF”, or “HEIC” in the action.
1. Run the shortcut. The next screenshot that you take has the new format.
}

Make one shortcut for each format that you use. To change the format in one click, [put the shortcuts in the menu bar](add-shortcut-to-menu-bar-mac.md), or [give them a keyboard shortcut](https://support.apple.com/guide/shortcuts-mac/apd163eb9f95/mac). The “Get Screenshot Format” action gives the format that is set now.

## Without an app

Run this command in the Terminal app:

```console
defaults write com.apple.screencapture type jpg
```

Write `heic`, `tiff`, or `png` in place of `jpg` for the other formats. JPG and HEIC files are smaller than PNG files, but they lose some quality. To go back to the normal format, run `defaults delete com.apple.screencapture type`.

The command changes the same setting as the action of Shortcutie, so it is all you need if you are at ease with Terminal.

On the Mac models that support it, macOS 26 and later can also save HDR screenshots in the HEIF format: press ++Shift+Command+5++, click “Options”, and choose “HDR”. [Apple’s instructions.](https://support.apple.com/102646) This menu has no JPG format.
