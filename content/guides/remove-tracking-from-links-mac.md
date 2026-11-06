---
title: 'How to Remove Tracking from Links on Mac'
description: 'Velja removes tracking parameters, like the UTM parameters of Google, from the links that you open from other apps and the links that you copy.'
publicationDate: 2026-11-10
topic: 'browsers-links-and-email'
apps: [
	'velja'
]
---

@QuickAnswer {
	[Velja](../apps/velja/index.md) removes tracking parameters, like `utm_source`, from the links that you click in other apps before they open in your browser. It can also clean the links that you copy. Safari can remove known tracking parameters in Safari itself.
}

## With Velja

@Steps {
1. Open [Velja](../apps/velja/index.md) and click “Get Started”. Velja works by being the default browser, so it asks to become it.
1. Open the settings, and click “Extras”. “Remove tracking parameters when opening links” is on by default.
1. To also clean the links that you copy, turn on “Remove tracking parameters when copying links”.
}

Velja knows more than 200 tracking parameters, and it has special support for links to X, Facebook, and TikTok. It cleans the links that go through it, like links in Mail, Slack, or Messages, not the links that you click inside a browser. The “Remove Tracking Parameters from URLs” action of Velja cleans links in the Shortcuts app.

## Without an app

In Safari, choose “Safari › Settings”, click “Advanced”, turn on “Use advanced tracking and fingerprinting protection”, and choose “in all browsing”. Safari then removes known tracking parameters from the pages that you open in Safari, but not in other browsers or in the links that you copy.

TrackerZapper, a free app that cleaned copied links, fails the security check of macOS now, and Homebrew disabled it in September 2026.
