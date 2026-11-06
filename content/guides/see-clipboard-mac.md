---
title: 'How to See What Is on the Clipboard on Mac'
description: 'See the clipboard with “Show Clipboard” in Finder, and its history in Spotlight. The free Pasteboard Viewer shows every format that is on the clipboard.'
publicationDate: 2026-11-11
topic: 'text-images-and-sound'
apps: [
	'pasteboard-viewer'
]
---

@QuickAnswer {
	In Finder, choose “Edit › Show Clipboard” to see the text or the image that you copied. To see what you copied before, press ++Command+Space++ to open Spotlight, and then ++Command+4++ (macOS 26 or later). To see everything that an app put on the clipboard, like the plain text, the rich text, and the HTML of one copy, use the free [Pasteboard Viewer](../apps/pasteboard-viewer/index.md).
}

## With Pasteboard Viewer

Pasteboard Viewer is a tool for developers and for the curious. It is not a clipboard manager, and it does not keep a history. To only see the text or the image that you copied, use [the built-in ways](#without-an-app).

@Steps {
1. Open [Pasteboard Viewer](../apps/pasteboard-viewer/index.md). When macOS asks to let it paste from other apps, allow it.
1. Copy something in another app. The window updates immediately.
1. In the sidebar, click a type, like `public.utf8-plain-text`, `public.rtf`, or `public.html`, to see the content in that format.
}

@Tips {
- To see the bytes of the content, choose “Hex” in the “View” menu, or press ++Command+2++.
- The “Pasteboard” menu switches to the other pasteboards of macOS, like the ones for drag and drop and for the Find text.
- To find why an app pastes text with the wrong format, look at which types the copy has. An app that pastes plain text takes `public.utf8-plain-text`.
- To stop the prompt each time, allow the app in “System Settings › Privacy & Security › Paste from Other Apps”.
}

## Without an app

For most people, the built-in ways are enough, and Pasteboard Viewer is more than you need:

- **What is on the clipboard now:** Click the desktop or a Finder window, and choose “Edit › Show Clipboard”. A window shows the text or the image.
- **What you copied before:** On macOS 26 or later, press ++Command+Space++, and then ++Command+4++. The first time, click “Allow”. Spotlight shows the items that you copied, and you can paste one of them again.

Finder shows only one form of the content. When you copy text from a web page, the clipboard has the text in several formats, and each app takes the one that it wants when you paste. Finder cannot show which formats there are.

To empty the clipboard, see [how to clear the clipboard](clear-clipboard-mac.md).
