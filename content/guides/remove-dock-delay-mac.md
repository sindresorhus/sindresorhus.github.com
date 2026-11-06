---
title: 'How to Remove the Dock Delay on Mac'
description: 'Make the hidden Dock show at once, without a delay, with Supercharge or with a Terminal command. Supercharge can also stop the Dock from showing.'
publicationDate: 2026-11-10
topic: 'windows-apps-and-dock'
apps: [
	'supercharge'
]
---

@QuickAnswer {
	When the Dock is hidden, macOS waits a moment before it shows the Dock. To remove the delay, set the delay to “None” in [Supercharge](../apps/supercharge/index.md), or change the hidden setting of the Dock with a Terminal command.
}

## With Supercharge

@Steps {
1. In “[System Settings › Desktop & Dock](x-apple.systempreferences:com.apple.Desktop-Settings.extension)”, turn on “Automatically hide and show the Dock”.
1. Open the settings of [Supercharge](../apps/supercharge/index.md), and click “Tweaks”.
1. In the “Dock” section, set “Delay before showing the Dock when hidden” to “None”.
1. Move the pointer to the edge of the screen. The Dock shows at once.
}

The delay does not change the Dock in fullscreen. If the Dock shows when you do not want it, like when you click controls near the edge of the screen, turn on “Prevent Dock from showing when moving the pointer to the screen edge” in the same section instead.

## Without an app

Run these commands in Terminal:

```console
defaults write com.apple.dock autohide-delay -float 0
killall Dock
```

To get the normal delay back, run `defaults delete com.apple.dock autohide-delay` and `killall Dock`.

The commands change the same setting as Supercharge, so they are enough if you are at ease with Terminal. Supercharge gives you a menu with the delays, and the setting to stop the Dock from showing.
