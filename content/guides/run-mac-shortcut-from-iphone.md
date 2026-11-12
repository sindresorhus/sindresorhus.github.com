---
title: 'How to Run a Shortcut on Your Mac from iPhone'
description: 'Run a shortcut on your Mac from a shortcut on your iPhone with Hyperduck, from anywhere, or with the Run Script Over SSH action on the same network.'
publicationDate: 2026-11-12
topic: 'iphone'
apps: [
	'hyperduck'
]
---

@QuickAnswer {
	Install [Hyperduck](../apps/hyperduck/index.md) on your iPhone and your Mac. On the iPhone, add the “Run Shortcut on Mac” action to a shortcut, and type the name of the Mac shortcut. It works from anywhere, as it uses iCloud. Without an app, use the “Run Script Over SSH” action, which needs the iPhone to reach the Mac on the network.
}

## With Hyperduck

@Steps {
1. Install [Hyperduck](../apps/hyperduck/index.md) on your iPhone and on your Mac. Both must use the same Apple Account with iCloud. Open it on the Mac, and keep it running.
1. On the Mac, make the shortcut in the Shortcuts app, like one named “Start Backup”.
1. On the iPhone, open the Shortcuts app, make a new shortcut, and add the “Run Shortcut on Mac” action of Hyperduck.
1. In the “Shortcut” field of the action, type the name of the Mac shortcut, exactly: “Start Backup”.
1. Run the iPhone shortcut. The shortcut runs on the Mac.
}

To give the Mac shortcut text as its input, expand the action, and fill in “Input”.

@Tips {
- By default, the Shortcuts app comes to the front on the Mac when the shortcut runs. To prevent this, turn on “Open Shortcuts URLs in the background” in the settings of Hyperduck on the Mac.
- If the Mac is offline, it gets the command the next time that it is online.
- Add the iPhone shortcut to the Home Screen, or say its name to Siri.
- One use is to [shut down the Mac from the iPhone](shut-down-mac-from-iphone.md).
}

## Without an app

The Shortcuts app on iPhone can run a command on the Mac over SSH:

@Steps {
1. On the Mac, turn on “Remote Login” in “System Settings › General › Sharing”.
1. On the iPhone, make a new shortcut, and add the “Run Script Over SSH” action.
1. Enter the address of the Mac, your user name, and your password, and type the command `shortcuts run "Start Backup"`, with the name of the Mac shortcut.
1. Run the iPhone shortcut.
}

[Apple: Run shortcuts from the command line](https://support.apple.com/guide/shortcuts-mac/run-shortcuts-from-the-command-line-apd455c82f02/mac)

This needs no app, but it works only when the iPhone can reach the Mac, like on the same network. Hyperduck works from anywhere, with no setup of the network.
