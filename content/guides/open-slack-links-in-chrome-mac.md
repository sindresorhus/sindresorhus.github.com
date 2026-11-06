---
title: 'How to Open Slack Links in Chrome (or Another Browser) on Mac'
description: 'Slack has no setting for the browser. With Velja, the links that you click in Slack open in Chrome, or in a Chrome profile, and other links open as before.'
publicationDate: 2026-11-11
topic: 'browsers-links-and-email'
apps: [
	'velja'
]
---

@QuickAnswer {
	Slack has no setting for the browser. It opens links in the default browser of macOS. With [Velja](../apps/velja/index.md), make a rule with Slack as the source app. Then the links that you click in Slack open in Chrome, or in a Chrome profile, and all other links open as before.
}

## With Velja

@Steps {
1. Open [Velja](../apps/velja/index.md), click “Continue”, and then “Get Started”. Velja works by being the default browser, so it asks to become it.
1. Choose the browser for all other links in “Primary Browser” in the menu bar menu.
1. Optional, for a Chrome profile, like your work profile: open the settings, go to “Browsers”, click “Grant Access…” for “Browser profiles”, and click “Allow”. If Velja says that macOS blocks the browser profiles, turn on Chrome in “System Settings › Privacy & Security › Files & Folders › Velja”.
1. In the settings, go to “Rules”, and click “Add Rule”.
1. In “Name”, type a name, like “Slack”.
1. In “Open in”, choose Chrome, or a Chrome profile.
1. Click the plus button next to “Source Apps”, and choose Slack.
1. Click “Save”.
}

Click a link in Slack. It opens in the browser of the rule. The same way works for other apps, like Mail or Messages: add them to the same rule, or make a rule for each app.

To open only some links from Slack in Chrome, also add a domain to “URL Matchers” in the rule. Then the link must match the domain and come from Slack. To set a browser for a website, whatever the app, see [how to open links in a specific browser](open-links-in-specific-browser-mac.md).

## Without an app

Change the default browser in “[System Settings › Desktop & Dock › Default web browser](x-apple.systempreferences:com.apple.Desktop-Settings.extension)”. This changes the browser for all apps, not only for Slack, and you cannot choose a profile.

To open one link in another browser, Control-click the link in Slack, copy the link, and paste it in the address bar of the other browser.
