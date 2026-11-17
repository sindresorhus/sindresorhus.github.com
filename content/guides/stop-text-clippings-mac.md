---
title: 'How to Stop Text Clipping Files on Mac'
description: 'A .textClipping file appears when you drag selected text by accident. Supercharge turns off the dragging of selected text, so no clippings are made.'
publicationDate: 2026-11-21
topic: 'finder-and-desktop'
apps: [
	'supercharge'
]
---

@QuickAnswer {
	In the settings of [Supercharge](/supercharge), turn on “Prevent text clippings by disabling text dragging”, and restart your apps. You can then not drag selected text, so no text clipping files are made. [Without an app](#without-an-app), the same setting is a Terminal command.
}

macOS makes a text clipping (a `.textClipping` file) when you drag selected text to the desktop or to a Finder window. This often happens by accident, when you click a selection and move the mouse a bit.

## With Supercharge

@Steps {
1. Open the settings of [Supercharge](/supercharge), and click “Tweaks”.
1. In the “System” section, turn on “Prevent text clippings by disabling text dragging”.
1. Quit and open your apps again. The setting starts to work in each app when it opens again.
}

The setting stops all dragging of selected text, also inside a document. To move text, cut it and paste it. To drag text again, turn the setting off, and restart your apps.

## Without an app

Run this command in Terminal, and then restart your apps:

```console
defaults write -g NSDragAndDropTextDelay -int 100000
```

This is the setting that Supercharge changes. To drag text normally again, run:

```console
defaults delete -g NSDragAndDropTextDelay
```

To remove a clipping, drag it to the Trash. To use its text, double-click it, or drag it into a document.
