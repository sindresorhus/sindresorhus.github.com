---
title: 'How to Open Links in a Specific Browser on Mac'
description: 'Use Velja to open each link in the right browser or profile, or change the one default browser of macOS.'
publicationDate: 2026-10-29
topic: 'browsers-links-and-email'
apps: [
	'velja'
]
screenshot: {
	number: 2
	description: 'Velja asks which browser to open a link in'
}
---

@QuickAnswer {
	Use [Velja](../apps/velja/index.md) to make rules, like Google Meet links in Chrome and other links in Safari. macOS itself has only one default browser for all links, which you set in “System Settings › Desktop & Dock › Default web browser”.
}

## With Velja

@Steps {
1. Open [Velja](../apps/velja/index.md) and click “Get Started”. Velja works by being the default browser, so it asks to become it.
1. Choose the browser for most links in “Primary Browser” in the menu bar menu.
1. Open the settings, go to “Rules”, click “Add Rule”, and give the rule a name.
1. Choose the browser in “Open in”. For a browser with profiles, like Chrome, you can choose the profile.
1. Click the plus button next to “URL Matchers”, keep “Domain”, and type the domain, like `figma.com`.
1. Click “Save”.
}

A rule can also match the app that you click the link in, like all links from Slack. Or hold ++Fn++ while you click a link to pick a browser from a prompt.

## Without an app

macOS has one default browser, which opens all links that you click outside a browser. Change it in “System Settings › Desktop & Dock › Default web browser”. You cannot set a browser for some websites or for some apps.

To open one link in another browser, Control-click the link, choose “Copy Link”, and paste it in the address bar of the other browser.
