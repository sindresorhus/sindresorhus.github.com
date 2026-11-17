---
title: 'How to Restart Wi-Fi Automatically When the Internet Drops on Mac'
description: 'Turn the Wi-Fi off and on again by itself when your Mac goes offline, with Online Check and a shortcut, or turn it off and on by hand.'
publicationDate: 2026-11-23
topic: 'internet-and-network'
apps: [
	'online-check'
]
---

@QuickAnswer {
	Add the [shortcut that restarts the Wi-Fi](https://www.icloud.com/shortcuts/8bbe914b13ff4f3ab9f063e835c92747), and choose it in “Run shortcut on status change” in the settings of [Online Check](/online-check). When the internet drops, Online Check runs it. [Without an app](#without-an-app), turn the Wi-Fi off and on in Control Center.
}

When the Wi-Fi of a Mac stops working, turning it off and on again often fixes it.

## With Online Check

@Steps {
1. Open [Online Check](/online-check). Its icon is in the menu bar.
1. Add the [shortcut that restarts the Wi-Fi](https://www.icloud.com/shortcuts/8bbe914b13ff4f3ab9f063e835c92747) to the Shortcuts app.
1. Open the settings of Online Check, and click “Advanced”.
1. In “Run shortcut on status change”, click the button, and choose the shortcut.
}

Online Check checks the real internet connection, not only the Wi-Fi, so it notices when the Wi-Fi is connected but nothing loads. [How it checks.](guide:check-internet-connection-mac)

@Tips {
- To join another Wi-Fi network when the current one is offline, use the [shortcut that connects to another Wi-Fi](https://www.icloud.com/shortcuts/bf64ec8fd3d24f80b2af845464306614), and type the name of the network in it.
- To make your own shortcut, use an “If” action on the “Shortcut Input”: it is `false` when the Mac goes offline, and `true` when it is online again.
- To see when and how often the internet drops, choose “History…” in the menu of Online Check. [How to see when your internet drops.](guide:internet-keeps-dropping-mac)
}

## Without an app

macOS does not restart the Wi-Fi when the internet drops. Do it by hand: click Control Center in the menu bar, click Wi-Fi to turn it off, and click it again to turn it on.

In the Terminal app, these commands do the same (on most Macs, the Wi-Fi is `en0`):

```console
networksetup -setairportpower en0 off
networksetup -setairportpower en0 on
```

A Shortcuts automation with the “Wi-Fi” trigger runs when the Mac joins or leaves a network, not when the internet stops working, so it cannot do this. <source:https://support.apple.com/125148>
