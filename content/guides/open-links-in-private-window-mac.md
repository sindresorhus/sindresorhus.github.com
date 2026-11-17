---
title: 'How to Open Links in a Private Window by Default on Mac'
description: 'Open the links that you click in other apps in a private window of Chrome, Firefox, Edge, or Brave with Velja, or start Safari with a private window.'
publicationDate: 2026-11-16
topic: 'browsers-links-and-email'
apps: [
	'velja'
]
---

@QuickAnswer {
	In the settings of [Velja](/velja), choose a private browser, like “Chrome (Private)” or “Firefox (Private)”, as the browser. The links that you click in other apps then open in a private window. [Without an app](#without-an-app), Safari can open with a private window, which you choose in its settings.
}

## With Velja

@Steps {
1. Open [Velja](/velja), click “Continue”, and then “Get Started”. Velja works by being the default browser, so it asks to become it.
1. Open the settings of Velja, and click “Browsers”.
1. In “Browser”, choose a browser in the “Private Browsing” section, like “Chrome (Private)”.
1. Click a link in another app, like Mail or Slack. It opens in a private window.
}

Velja opens private windows in Chrome, Edge, Brave, Vivaldi, Opera, Firefox, Zen, LibreWolf, and their beta versions. [See the list.](/velja#supported-browsers-for-private-browsing) The browser can open the link in a private window that is already open.

@Tips {
- To open only some links privately, like the links of one website or one app, choose the private browser in a rule. [How to make a rule.](guide:open-links-in-specific-browser-mac)
- To open one link privately, hold ++Fn++ while you click it, right-click a browser in the prompt, and choose “Open in Private Window”.
- For Safari, Velja has no private window, but the free [Safari Private](https://github.com/sindresorhus/Safari-Private) app opens a link in a private Safari window. Install it, and choose “Safari Private” as the browser in Velja.
}

## Without an app

Safari can open with a private window:

@Steps {
1. In Safari, choose “Safari › Settings”, and click “General”.
1. Click the “Safari opens with” menu, and choose “A new private window”.
}

If you do not see this choice, turn on “Close windows when quitting an application” in “[System Settings › Desktop & Dock](x-apple.systempreferences:com.apple.Desktop-Settings.extension)”. <source:https://support.apple.com/guide/safari/ibrw1069/mac> Apple describes this setting for the window that Safari opens with, not for the links from other apps.
