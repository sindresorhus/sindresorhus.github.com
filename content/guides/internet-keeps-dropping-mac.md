---
title: 'How to See When Your Internet Drops on Mac'
description: 'When the internet keeps dropping on your Mac, Online Check notes the time of each drop, and exports the list for your internet provider.'
publicationDate: 2026-11-13
topic: 'internet-and-network'
apps: [
	'online-check'
]
---

@QuickAnswer {
	[Online Check](/online-check) notes each time the Mac goes offline and online again. Choose “History…” in its menu to see the times, and export them as a CSV file for your internet provider. [Without an app](#without-an-app), Wireless Diagnostics can monitor the Wi-Fi connection.
}

## With Online Check

@Steps {
1. Open [Online Check](/online-check), and keep it open. Its icon is in the menu bar, and it turns red when the internet drops.
1. Later, click the icon, and choose “History…”.
1. Each row is a time with a dot: green when the Mac came online, and red when it went offline.
1. To keep the list, click the “…” button in the toolbar, and choose “Export…”. The CSV file has a “Timestamp” column and an “Online” column with `true` or `false`.
}

The history is lost when you quit Online Check, so export it first. Online Check checks the real internet connection, not only the Wi-Fi, so the list also shows drops of the router or of your provider. [How it checks.](guide:check-internet-connection-mac)

@Tips {
- Send the CSV file to your internet provider, so they see when and how often the connection drops.
- Online Check notifies you when the Mac goes offline. To also see it on the screen, turn on “Show red screen border when offline” in the “General” settings.
}

## Without an app

Wireless Diagnostics of macOS can watch the Wi-Fi connection ([Apple’s guide](https://support.apple.com/guide/mac-help/mchlf4de377f/mac)):

@Steps {
1. Hold ++Option++, click Wi-Fi in the menu bar, and choose “Open Wireless Diagnostics…”.
1. Follow the steps on the screen. When it finds no problem, choose “Monitor my Wi-Fi connection”.
1. Keep it open while you work. When the connection drops, it shows the time of the drop.
}

It is free, and it can find problems of the Wi-Fi, like interference. It can also save a report with technical details for your provider. But it does not show a list of all the drops.
