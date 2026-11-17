---
title: 'How to Copy the Email Address When You Click an Email Link on Mac'
description: 'Stop email links from opening the Mail app. Mailway copies the email address when you click a link, so you can paste it in the email app that you use.'
publicationDate: 2026-11-23
topic: 'browsers-links-and-email'
apps: [
	'mailway'
]
---

@QuickAnswer {
	Make [Mailway](/mailway) the default email app, and choose “Copy to Clipboard” in “Primary email app”. When you click an email link, Mailway copies the address, and no app opens. [Without an app](#without-an-app), ++Control++-click each email link, and copy it.
}

When you click an email link (a `mailto:` link), like an email address on a website, macOS opens the Mail app, also when you do not use Mail.

## With Mailway

@Steps {
1. Open [Mailway](/mailway). Its settings window opens.
1. Click “Set as Default”, and confirm that macOS can use Mailway for email links.
1. In “Primary email app”, choose “Copy to Clipboard” below “Actions”.
1. Click an email link. The address is now on the clipboard. Paste it with ++Command+V++.
}

When a link has more than one recipient, Mailway copies all of them, with a comma between them.

@Tips {
- To open some links in an email app, and copy the others, add a rule in the “Rules” tab, like for the links that you click in Slack.
- To write an email in Gmail or another webmail in place of a copy, choose it in “Primary email app”. [How to change the default email app.](guide:change-default-email-app-mac)
}

## Without an app

++Control++-click the email link, and choose the item that copies it, like “Copy Link” in Safari. Some browsers copy the address with `mailto:` before it, so you must remove that part after you paste. In Mail, ++Control++-click an address, and choose “Copy Address”.

You cannot set macOS to do nothing when you click an email link, as it always opens the default email app. The setting is in Mail: choose “Mail › Settings”, click “General”, and choose an app in “Default email reader”. The right-click works well for a link now and then. Mailway is for when you click the links by habit.
