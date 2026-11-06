---
title: 'How to Send a Link from iPhone to Mac'
description: 'Send a link from the share sheet of your iPhone, and it opens in the browser of your Mac with Hyperduck. Or use AirDrop, Handoff, or iCloud Tabs.'
publicationDate: 2026-10-30
topic: 'browsers-links-and-email'
apps: [
	'hyperduck'
]
screenshot: {
	number: 1
	description: 'A website shared from an iPhone opens in the browser of the Mac'
}
---

@QuickAnswer {
	Install [Hyperduck](../apps/hyperduck/index.md) on your iPhone and your Mac. On the iPhone, tap “Share”, and tap “Send to Mac”. The link opens in the default browser of your Mac. Without an app, use AirDrop when the Mac is near you, or find the page in iCloud Tabs in Safari on the Mac.
}

## With Hyperduck

@Steps {
1. Install [Hyperduck](../apps/hyperduck/index.md) on your iPhone and on your Mac. Both must use the same Apple Account.
1. Open Hyperduck on the Mac. Its icon is in the menu bar. Turn on “Launch at Login” in its settings, so it is always ready.
1. On the iPhone, open the page in Safari, or in another app with links, like X or Reddit, and tap “Share”.
1. Tap “Send to Mac”. If it is not in the list, tap “Edit Actions…” at the bottom of the share sheet, and add it. Sometimes iOS shows it only after you restart the iPhone.
1. The link opens in the default browser of your Mac, in the background.
}

Hyperduck sends the link with iCloud, so the Mac does not need to be near you, or even on. When the Mac is off or offline, the link opens the next time it is online. You can send many links at a time.

@Tips {
- Hyperduck sends to one Mac. Install the Mac app only on the Mac that must open the links.
- To open the links in another browser or a browser profile, use [Velja](../apps/velja/index.md) with a rule for links from Hyperduck. [How to do it.](../apps/hyperduck/index.md#custom-browser)
- Hyperduck can also run a shortcut on your Mac from your iPhone. [How to do it.](../apps/hyperduck/index.md#shortcuts)
- When a link does not open, see the [troubleshooting](../apps/hyperduck/index.md#troubleshooting).
}

## Without an app

Your iPhone and Mac have four ways to move a link. Universal Clipboard, iCloud Tabs, and Handoff need the same Apple Account on both devices. AirDrop also works between different accounts.

**Universal Clipboard:** Copy the link on the iPhone, and soon after, press ++Command+V++ on the Mac. The devices must be near each other, with Wi-Fi, Bluetooth, and Handoff on. [How Hyperduck compares.](../apps/hyperduck/index.md#universal-clipboard)

**AirDrop:** On the iPhone, tap “Share”, tap “AirDrop”, and tap your Mac. The Mac must be awake and near you, with Wi-Fi and Bluetooth on. If the Mac does not show, set “AirDrop” to “Contacts Only” or “Everyone” in “[System Settings › General › AirDrop & Continuity](x-apple.systempreferences:com.apple.AirDrop-Handoff-Settings.extension)” on the Mac. [How Hyperduck compares.](../apps/hyperduck/index.md#airdrop)

**iCloud Tabs:** Safari shows the tabs that are open on your iPhone. In Safari on the Mac, show the sidebar, click your iPhone below “iCloud Tabs”, and click the page. The page must stay open in Safari on the iPhone, and private tabs do not show. Safari must be on in the iCloud settings of both devices. [How Hyperduck compares.](../apps/hyperduck/index.md#icloud-tabs)

**Handoff:** Open the page in Safari on the iPhone, and click the Handoff icon of Safari at the end of the Dock on the Mac. The devices must be near each other. Turn on Handoff in “[System Settings › General › AirDrop & Continuity](x-apple.systempreferences:com.apple.AirDrop-Handoff-Settings.extension)” on the Mac, and in “Settings › General › AirPlay & Continuity” on the iPhone. [How Hyperduck compares.](../apps/hyperduck/index.md#handoff)

These work well when your Mac is next to you. Hyperduck is for links from all apps, to a Mac that can be far away or off, and it opens them in your browser, so you do not forget them.
