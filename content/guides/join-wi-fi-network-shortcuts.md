---
title: 'How to Join a Wi-Fi Network with Shortcuts on iPhone and Mac'
description: 'The Shortcuts app can turn Wi-Fi on and off, but not join a network. The free Actions app joins one on iPhone, and Shortcutie on Mac.'
publicationDate: 2026-11-21
topic: 'shortcuts'
apps: [
	'actions'
	'shortcutie'
]
---

@QuickAnswer {
	On iPhone, add the “Join Wi-Fi” action of the free [Actions](/actions) app, and type the name and the password of the network. On Mac, use the “Join Wi-Fi” action of [Shortcutie](/shortcutie). [Without an app](#without-an-app), the “Set Wi-Fi” action of Shortcuts only turns Wi-Fi on or off.
}

## On iPhone with Actions

@Steps {
1. Install [Actions](/actions), and open it once.
1. In your shortcut, add the [“Join Wi-Fi”](/actions#:~:text=Join%20Wi%2DFi) action of Actions.
1. Type the name of the network in “Name (SSID)”, and its password in “Password”. Leave the password empty for an open network.
1. Run the shortcut, and tap “Join” when iOS asks.
}

iOS always asks before an app joins a network, so the shortcut cannot join without you. To ask, the action opens the Actions app for a moment, and then goes back to Shortcuts. When the shortcut runs in the background, like from a widget, add the “Go to Home Screen” action after it.

The action has more options: “Wait for Connection”, “Is WEP” for an old network, and “Is Hidden” for a network that does not show its name.

## On Mac with Shortcutie

@Steps {
1. Install [Shortcutie](/shortcutie), and open it once.
1. In your shortcut, add the “Join Wi-Fi” action of Shortcutie.
1. Type the name of the network, and its password. Leave the password empty for an open network.
1. Run the shortcut. If Wi-Fi is off, the action turns it on first.
}

## Without an app

The “Set Wi-Fi” action of Shortcuts turns Wi-Fi on or off, but it cannot choose a network. To join one, use the settings:

- **iPhone:** Open “Settings › Wi-Fi”, and tap the network.
- **Mac:** Click Wi-Fi in the menu bar, and click the network.

Your devices join known networks by themselves. On Mac, you can also join a network with a Terminal command, where `en0` is usually the Wi-Fi:

```console
networksetup -setairportnetwork en0 'Network Name' 'password'
```
