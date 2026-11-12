---
title: 'How to Change the DNS Server on Mac'
description: 'Change the DNS servers of your Mac, like to 1.1.1.1 or 8.8.8.8, in the Network settings, or switch them with a shortcut and Shortcutie.'
publicationDate: 2026-11-12
topic: 'mac'
apps: [
	'shortcutie'
]
---

@QuickAnswer {
	Open “System Settings › Network”, click your network, like Wi-Fi, click “Details”, and click “DNS”. Then add the servers, like `1.1.1.1` and `1.0.0.1`. To switch between DNS servers often, make a shortcut with the “Set DNS Servers” action of [Shortcutie](../apps/shortcutie/index.md).
}

## With Shortcutie

A shortcut is faster when you switch often, like to a DNS server that blocks ads, and back:

@Steps {
1. Install [Shortcutie](../apps/shortcutie/index.md), and open it once.
1. In the Shortcuts app, click the add button to make a new shortcut.
1. Add the “Set DNS Servers” action of Shortcutie, click its field, and add the addresses, like `1.1.1.1` and `1.0.0.1`.
1. Make a second shortcut with the action, but keep its field empty. It goes back to the DNS servers of your network.
1. Run a shortcut, and enter your password when macOS asks for it.
}

The action changes the network service that your Mac uses now, like Wi-Fi or Ethernet. To see the current servers, use “Get DNS Servers”. Its result is empty when the Mac uses the DNS servers of the network.

To run the shortcuts in one click, [put them in the menu bar](add-shortcut-to-menu-bar-mac.md). If a website still goes to the old address after a change, [flush the DNS cache](flush-dns-cache-mac.md).

## Without an app

@Steps {
1. Open “System Settings › Network”, and click the network service that you use, like Wi-Fi.
1. Click “Details” next to the network, and click “DNS”. You may need to scroll down.
1. Click the add button below “DNS Servers”, and type the address of a server, like `1.1.1.1` (Cloudflare) or `8.8.8.8` (Google). Add a second server in the same way.
1. Click “OK”.
}

[Apple’s instructions](https://support.apple.com/guide/mac-help/mh14127/mac). To go back to the DNS servers of your network, remove the servers from the list.

In Terminal, `sudo networksetup -setdnsservers Wi-Fi 1.1.1.1 1.0.0.1` does the same for Wi-Fi, and `sudo networksetup -setdnsservers Wi-Fi empty` removes the servers. The settings and Terminal are enough when you change the DNS servers once.
