---
title: 'How to Ping an IP Address or Server from iPhone'
description: 'iPhone has no Terminal and no ping command. Ping an IP address or a server from iPhone with the Ping action of the free Actions app in Shortcuts.'
publicationDate: 2026-11-13
topic: 'iphone'
apps: [
	'actions'
]
---

@QuickAnswer {
	iPhone has no Terminal, so it has no `ping` command. The free [Actions](../apps/actions/index.md) app adds a “Ping” action to the Shortcuts app. Type a domain or an IP address, run the shortcut, and see the average time and the packet loss.
}

## With Actions

@Steps {
1. Install [Actions](../apps/actions/index.md), and open it once.
1. In the Shortcuts app, make a new shortcut, and add the “Ping” action.
1. Type a domain or an IP address, like `192.168.1.1` or `apple.com`.
1. Add the “Show Result” action, and run the shortcut.
}

The result is like “12.3ms average” with “0% packet loss”, or “Unreachable”. The action sends 5 pings, and waits up to 10 seconds for each. Expand the action to change the count and the timeout.

To ping a device on your home network, like a router or a printer, the app needs Local Network access. Open Actions, tap “Permissions”, and tap “Grant Local Network Access”.

@Tips {
- To do something only when a server answers, add an “If” action with the “Is Reachable” property of the result.
- To check a port, like a web server on port 443, use the “Is Host Reachable” action.
}

## Without an app

The Shortcuts app has no ping action. On a Mac on the same network, run this in Terminal, with your address:

```console
ping -c 5 192.168.1.1
```

To only see if a website loads, open it in Safari. That shows that the server answers, but not how fast. The Ping action is for when you have only your iPhone.
