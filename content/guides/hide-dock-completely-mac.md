---
title: 'How to Hide the Dock Completely on Mac'
description: 'A hidden Dock still shows each time the pointer is at the edge of the screen. Supercharge stops that, and a Terminal command can do the same.'
publicationDate: 2026-11-11
topic: 'windows-apps-and-dock'
apps: [
	'supercharge'
]
---

@QuickAnswer {
	“Automatically hide and show the Dock” hides the Dock, but it comes back each time the pointer is at the edge of the screen. To keep it hidden, turn on “Prevent Dock from showing when moving the pointer to the screen edge” in [Supercharge](../apps/supercharge/index.md), or give the Dock a very long delay with a Terminal command.
}

## With Supercharge

@Steps {
1. Open the settings of [Supercharge](../apps/supercharge/index.md), and click “Tweaks”.
1. In the “Dock” section, turn on “Prevent Dock from showing when moving the pointer to the screen edge”.
1. Move the pointer to the edge of the screen. The Dock stays hidden.
}

Supercharge also turns on the automatic hiding of the Dock, and it restores your earlier Dock setting when you turn the tweak off. In a fullscreen app, macOS still shows the Dock at the edge of the screen.

Without the Dock, open apps with Spotlight (++Command+Space++), and switch between them with ++Command+Tab++. To turn the tweak on and off with a keyboard shortcut, make a shortcut in the Shortcuts app with the “Set Dock Edge Activation” action of Supercharge.

## Without an app

Run these commands in the Terminal app:

```console
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 1000
killall Dock
```

Now the Dock waits 1000 seconds before it shows, so you never see it. To get the normal delay back, run `defaults delete com.apple.dock autohide-delay` and `killall Dock`. The Dock is then still hidden until the pointer is at the edge. To always show it, turn off “Automatically hide and show the Dock” in “[System Settings › Desktop & Dock](x-apple.systempreferences:com.apple.Desktop-Settings.extension)”.

The commands change the same hidden setting as Supercharge, so they are enough if you are at ease with Terminal. To only [remove the delay of the Dock](remove-dock-delay-mac.md), there is another guide.
