---
isDraft: true
title: 'How to Write an NFC Tag with iPhone'
description: 'iPhone can run a shortcut when it scans an NFC tag, but it cannot write one. The free Actions app adds a Write NFC Tag action to Shortcuts for text and URLs.'
publicationDate: 2026-11-09
topic: 'iphone'
apps: [
	'actions'
]
---

@QuickAnswer {
	iPhone can run a shortcut when it scans an NFC tag, but it cannot write a tag. The free [Actions](../apps/actions/index.md) app adds a “Write NFC Tag” action to the Shortcuts app, which writes text or a URL to a tag.
}

## With Actions

@Steps {
1. Install [Actions](../apps/actions/index.md), and open it once.
1. In the Shortcuts app, tap the add button to make a new shortcut.
1. Add the “Write NFC Tag” action of Actions.
1. Enter the text or the URL, and choose “Text” or “URL” as the type.
1. Run the shortcut, and hold the top of the iPhone near the tag within 20 seconds.
}

Writing replaces everything on the tag. When a tag has a web, email, or phone URL, any iPhone that scans it offers to open it, without an app. This does not work for other URLs, like `shortcuts://` URLs.

- “Make Read-Only” in the action locks the tag after writing. This cannot be undone.
- MIFARE Classic and FeliCa tags do not work, and the tag must be formatted for NFC data (NDEF).
- The “Read NFC Tag” action of Actions reads the ID and the content of a tag.

## Without an app

To run a shortcut when your iPhone scans a tag, you do not need to write it:

@Steps {
1. In the Shortcuts app, tap “Automation”, and tap the add button.
1. Choose “NFC”, tap “Scan”, and hold the iPhone near the tag.
1. Choose the shortcut to run.
}

[Apple’s instructions.](https://support.apple.com/guide/shortcuts/add-automations-apdfbdbd7123/ios) This is enough when you only want a tag that runs a shortcut on your own iPhone. Writing the tag is for a tag that other phones can use too, like a link to a website or a Wi-Fi page.
