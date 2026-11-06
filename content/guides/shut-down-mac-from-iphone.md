---
title: 'How to Shut Down Your Mac from iPhone'
description: 'iPhone cannot shut down a Mac. With Hyperduck, a shortcut on your iPhone runs a shortcut on your Mac that shuts it down, restarts it, or puts it to sleep.'
publicationDate: 2026-11-11
topic: 'iphone'
apps: [
	'hyperduck'
]
---

@QuickAnswer {
	iPhone has no simple built-in way to shut down a Mac. With [Hyperduck](../apps/hyperduck/index.md) on both devices, a shortcut on your iPhone runs a shortcut on your Mac, and that shortcut shuts it down. It works from anywhere, as it uses iCloud.
}

## With Hyperduck

@Steps {
1. Install [Hyperduck](../apps/hyperduck/index.md) on your iPhone and on your Mac. Both must use the same Apple Account. Open it on the Mac, and keep it running.
1. On the Mac, open the Shortcuts app, and make a shortcut with the “Shut Down” action. Name it “Shut Down Mac”.
1. On the iPhone, open the Shortcuts app, make a new shortcut, and add the “Run Shortcut on Mac” action of Hyperduck.
1. In the shortcut field of the action, type the name of the Mac shortcut: “Shut Down Mac”.
1. Run the iPhone shortcut. The Mac shuts down.
}

@Tips {
- Add the iPhone shortcut to the Home Screen, or say its name to Siri.
- By default, the Shortcuts app comes to the front on the Mac when the shortcut runs. To prevent this, turn on “Open Shortcuts URLs in the background” in the settings of Hyperduck on the Mac.
- The same way works for any Mac shortcut, like one that puts the Mac to sleep, restarts it, or plays music.
}

The Mac must be awake and online to get the command. Hyperduck cannot turn the Mac on again. Apps with unsaved changes can stop the shutdown, like when you shut down at the Mac.

## Without an app

iPhone has no button for this, but there are other ways:

- **Shut down at a time:** On the Mac, run `sudo pmset schedule shutdown "12/31/26 23:00:00"` in the Terminal app, with the date as month, day, and year. The Mac shuts down at that time.
- **Sleep by itself:** In “System Settings › Lock Screen” on the Mac, set the time before the display turns off. The Mac then sleeps when nothing keeps it awake, and a Mac that sleeps uses very little power.
- **SSH:** If you know the Terminal, turn on “Remote Login” in “System Settings › General › Sharing” on the Mac, and use the “Run Script Over SSH” action of Shortcuts on the iPhone to run a shutdown command. It works only when the iPhone can reach the Mac, like on the same network.

Hyperduck is the easy way to shut the Mac down now, from where you are, without a setup of the network.
