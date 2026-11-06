---
title: 'How to Wake a Computer with Wake on LAN from Mac'
description: 'macOS cannot send a Wake on LAN packet. The free Actions app adds a Wake on LAN action to the Shortcuts app, which wakes a computer from its MAC address.'
publicationDate: 2026-11-09
topic: 'mac'
apps: [
	'actions'
]
---

@QuickAnswer {
	macOS has no built-in way to send a Wake on LAN packet. The free [Actions](../apps/actions/index.md) app adds a “Wake on LAN” action to the Shortcuts app on Mac, which wakes a computer on your network from its MAC address.
}

## With Actions

@Steps {
1. Install [Actions](../apps/actions/index.md), and open it once.
1. In the Shortcuts app, click the add button to make a new shortcut.
1. Add the “Wake on LAN” action of Actions.
1. Enter the MAC address of the computer, like `AA:BB:CC:DD:EE:FF`. For a computer on the same network, keep the default address (`255.255.255.255`) and port (9).
1. Run the shortcut.
}

The computer must have Wake on LAN turned on. A success only means that the packet was sent, not that the computer woke up. To wake it in one click, [put the shortcut in the menu bar](add-shortcut-to-menu-bar-mac.md). The action is only on Mac, as iOS needs a special permission for it.

## Without an app

macOS cannot send the packet, but it can let a Mac be woken by others:

- **Desktop Mac:** Open “System Settings › Energy”, and turn on “Wake for network access”.
- **Mac laptop:** Open “System Settings › Battery”, click “Options”, and choose an option in the pop-up menu next to “Wake for network access”.

[Apple’s instructions.](https://support.apple.com/guide/mac-help/mchle41a6ccd/mac) Then another Mac on the same network can often wake it when it connects to it, like in Finder or Screen Sharing. If you use Terminal, a tool like `wakeonlan` from Homebrew sends the packet too.
