---
title: 'How to Preview an App Icon in the Dock on Mac'
description: 'See your app icon design in the real Dock, next to your other apps, with Icon Preview. It updates when you save the image file.'
publicationDate: 2026-11-11
topic: 'windows-apps-and-dock'
apps: [
	'icon-preview'
]
---

@QuickAnswer {
	Drag the image of your icon onto the Dock icon of [Icon Preview](../apps/icon-preview/index.md). The Dock then shows your icon, next to your other apps, and it updates when the file changes. Without an app, you can give a file or a folder a custom icon in its Info window, which shows in Finder.
}

## With Icon Preview

@Steps {
1. Open [Icon Preview](../apps/icon-preview/index.md). It has an icon in the Dock and an icon in the menu bar.
1. Drag the image file onto the Dock icon. Or click the Dock icon, and choose the file.
1. Change the icon in your design app, and save the file. The Dock shows the new version.
1. For a menu bar icon, drag the image onto the menu bar icon of Icon Preview.
}

To remove the preview, Control-click the Dock icon, and choose “Clear Icon”.

@Tips {
- It supports the common image formats, like PNG, SVG, PDF, ICNS, and TIFF.
- It cannot open an `.icon` file of Icon Composer. [Export the icon as a PNG](../apps/icon-preview/index.md#icon-composer) in Icon Composer first.
- From Sketch, you can drag an artboard directly onto the Dock icon.
- To use it in a shortcut, add the “Set Icon Preview” action in the Shortcuts app.
}

## Without an app

macOS can give a file or a folder a custom icon:

@Steps {
1. Open the image in Preview, and choose “Edit › Copy”.
1. In Finder, select the file or folder, and choose “File › Get Info”.
1. In the Info window, click the small icon at the top, and choose “Edit › Paste”.
}

[Apple’s instructions.](https://support.apple.com/guide/mac-help/mchlp2313/mac) This shows your image as an icon in Finder, and you must paste it again after each change of the design. To remove it, click the small icon again, and choose “Edit › Cut”. Icon Preview is for the Dock and the menu bar, and it follows the file.
