---
title: 'How to Scan a Document in a Shortcut on iPhone'
description: 'Scan a document in a shortcut on iPhone and use the scan in the next actions, with the Scan Documents action of the free Actions app.'
publicationDate: 2026-11-11
topic: 'iphone'
apps: [
	'actions'
]
---

@QuickAnswer {
	Add the “Scan Documents” action of the free [Actions](../apps/actions/index.md) app to a shortcut. It opens the document scanner of iOS and copies the scan to the clipboard, so the next actions can save it or send it. To only scan a document, use the Files app or the Notes app.
}

## With Actions

@Steps {
1. Install [Actions](../apps/actions/index.md), and open it once.
1. In your shortcut, add the “Scan Documents” action. Turn on “Use PDF” to get one PDF and not one image for each page.
1. Below it, add the “Wait to Return” action, and then the “Get Clipboard” action.
1. Add what must happen with the scan, like the “Save File” action.
1. Run the shortcut. The Actions app opens with the scanner. Scan the pages. The Shortcuts app then comes back, and the shortcut continues.
}

The scan replaces what was on the clipboard. The action is not available on the Mac.

## Without an app

To only scan a document, you do not need a shortcut:

- **Files:** In the Files app, tap the More button, and tap “Scan Documents”. After the scan, choose a location, and tap “Save”.
- **Notes:** Open a note, tap the Attachment button, and tap “Scan Documents”.

[Apple’s instructions.](https://support.apple.com/108963) If a scan in Files or Notes is enough, use that. The Files app also has a “Scan Document” action for Shortcuts, but it only opens the scanner of Files and gives no result to the next actions. The action of Actions is for a shortcut that does more with the scan in its next actions.
