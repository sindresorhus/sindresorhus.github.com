---
title: 'How to Keep Your Mac Awake While an App Is Open'
description: 'Keep your Mac awake only while an app is open, like Keynote or a game, with Lungo and a Shortcuts automation, or with the caffeinate command.'
publicationDate: 2026-11-23
topic: 'mac'
apps: [
	'lungo'
]
---

@QuickAnswer {
	Make two Shortcuts automations with the “App” trigger: one turns [Lungo](/lungo) on when the app opens, and one turns it off when the app closes. [Without an app](#without-an-app), run `caffeinate -i -w` with the process ID of the app in the Terminal app.
}

## With Lungo

On macOS 26 and later, the Shortcuts app can run a shortcut when an app opens or closes. <source:https://support.apple.com/125148>

@Steps {
1. Install [Lungo](/lungo), and open it. Its icon is in the menu bar.
1. In the Shortcuts app, make a shortcut with the “Set Enabled State” action of Lungo. Set it to turn Lungo on, and keep “Duration to Keep Lungo On” at “Indefinitely”.
1. Make a second shortcut with the same action, set to turn Lungo off.
1. Add an automation with the “App” trigger for when the app is opened, like Keynote, and choose the first shortcut.
1. Add an automation with the “App” trigger for when the same app is closed, and choose the second shortcut.
}

Your Mac and its screen now stay awake while the app is open. To keep only the Mac awake, and let the screen turn off, like for a long download, set “Display Sleep” in the action to “Allow Display to Sleep”.

@Tips {
- The same way, you can turn Lungo on when your Mac connects to power (“Charger”), or joins a Wi-Fi network.
- Lungo stays in the menu bar, so you see when it is on. [More ways to keep your Mac awake.](guide:keep-mac-awake)
}

## Without an app

The `caffeinate` command of macOS keeps the Mac awake until a process ends. Open the Terminal app, and run this command with the name of the app, like Keynote:

```console
caffeinate -i -w $(pgrep -x Keynote)
```

`-i` keeps the Mac from going to sleep, and `-w` stops when the app quits. Add `-d` to also keep the screen on. You must run the command again each time you open the app, and the app must be open before you run it.
