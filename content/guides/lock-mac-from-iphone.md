---
title: 'How to Lock Your Mac from iPhone'
description: 'iPhone has no button to lock a Mac. With Hyperduck, a shortcut on your iPhone runs a Mac shortcut that locks the screen, from anywhere.'
publicationDate: 2026-11-16
topic: 'iphone'
apps: [
	'hyperduck'
]
---

@QuickAnswer {
	With [Hyperduck](../apps/hyperduck/index.md) on your iPhone and your Mac, a shortcut on the iPhone runs a Mac shortcut with the “Lock Screen” action. The Mac locks at once, from anywhere, as it uses iCloud. At the Mac, press ++Control+Command+Q++.
}

## With Hyperduck

@Steps {
1. Install [Hyperduck](../apps/hyperduck/index.md) on your iPhone and on your Mac, with the same Apple Account. Open it on the Mac, and keep it running.
1. On the Mac, make a shortcut in the Shortcuts app with only the “Lock Screen” action, and name it “Lock Mac”.
1. On the iPhone, make a shortcut with the “Run Shortcut on Mac” action of Hyperduck, and type “Lock Mac” in its shortcut field.
1. Run the iPhone shortcut. The Mac locks.
}

@Tips {
- Turn on “Open Shortcuts URLs in the background” in the settings of Hyperduck on the Mac, so the Shortcuts app does not come to the front before the Mac locks.
- Add the iPhone shortcut to the Home Screen, or say its name to Siri.
- The same setup can [shut down the Mac](shut-down-mac-from-iphone.md), or [run any Mac shortcut](run-mac-shortcut-from-iphone.md).
}

The Mac must be awake and online to get the command. To unlock it, you must be at the Mac.

## Without an app

iPhone has no button to lock a Mac. At the Mac, there are fast ways ([Apple’s guide](https://support.apple.com/guide/mac-help/mchl8e8b6a34/mac)):

- Press ++Control+Command+Q++, or choose “Apple menu › Lock Screen”.
- Press Touch ID, or the lock key, on a keyboard that has it.
- **SSH:** If you know the Terminal, turn on “Remote Login” in “System Settings › General › Sharing” on the Mac, and use the “Run Script Over SSH” action of Shortcuts on the iPhone to run `pmset displaysleepnow`. It turns off the display, and the Mac asks for the password when “Require password after screen saver begins or display is turned off” in “System Settings › Lock Screen” is “Immediately”. It works only when the iPhone can reach the Mac, like on the same network.

Hyperduck is the easy way when you are not at the Mac, like when you left it open at work.
