---
title: 'How to Check Your Internet Connection on Mac'
description: 'See at a glance if your Mac is online, with a menu bar icon that turns red when the internet stops working, or check it with the ping command in Terminal.'
publicationDate: 2026-11-06
topic: 'menu-bar'
apps: [
	'online-check'
]
screenshot: {
	number: 1
	description: 'The red icon of Online Check in the menu bar, and its menu with “Offline since 5 minutes ago”'
}
---

@QuickAnswer {
	[Online Check](../apps/online-check/index.md) shows an icon in the menu bar that turns red when your Mac is offline, and it can notify you. Without an app, run `ping apple.com` in the Terminal app: if no replies come, the Mac is offline.
}

A Wi-Fi icon with full bars only means that the Mac is connected to the router. The internet can still be down, like when the router has no connection.

## With Online Check

@Steps {
1. Open [Online Check](../apps/online-check/index.md). Its icon is in the menu bar.
1. When the internet stops working, the icon turns red. Click it to see how long the Mac has been offline.
1. In the “General” settings, choose whether to get a notification when the Mac goes offline, or also when it is online again.
}

Online Check loads a small page of Apple, and tries other servers when it fails, so it checks the real internet connection, not only the Wi-Fi. It checks every 10 seconds, and every 2 seconds while offline.

@Tips {
- Turn on “Show red screen border when offline” in the “General” settings, so you notice it at once.
- To show the icon only while you are offline, set “Show icon” to “when offline” in the “Menu Bar” settings.
- To run a shortcut when the status changes, like one that restarts the Wi-Fi, choose it in the “Advanced” settings.
}

## Without an app

Open the Terminal app, and run:

```console
ping apple.com
```

If lines with a time, like `time=12.3 ms`, come, the Mac is online. If you get “Request timeout” or “cannot resolve”, it is offline. Press ++Control+C++ to stop it.

It is good for a quick check. To notice when the connection stops while you work, you must keep the Terminal window open and look at it.
