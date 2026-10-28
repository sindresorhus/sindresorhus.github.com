---
title: 'How to Hide Desktop Icons on Mac'
description: 'Hide the files on your Mac desktop with one click or a keyboard shortcut in Supercharge, or with the “Show items” setting of macOS.'
publicationDate: 2026-10-31
topic: 'finder-and-desktop'
apps: [
	'supercharge'
]
---

@QuickAnswer {
	Click [Supercharge](../apps/supercharge/index.md) in the menu bar, and choose “Desktop Icons”. Choose it again to show the icons. Without an app, open “System Settings › Desktop & Dock”, and turn off “On Desktop” next to “Show items”.
}

## With Supercharge

@Steps {
1. Open [Supercharge](../apps/supercharge/index.md), and give it the access that it asks for in [“Device Control and Data Access”](/apps/faq#device-control-access).
1. Click its icon in the menu bar, and choose “Desktop Icons”. The icons go away.
1. To show them again, choose “Desktop Icons” again. A checkmark shows when the icons are visible.
}

This is good before a presentation, a screen share, or a screenshot. To hide and show the icons with a keyboard shortcut, open the Supercharge settings, click “Shortcuts”, and set a shortcut for “Desktop icons”. In the same menu, “Desktop Widgets” and “Desktop Icons & Widgets” hide the widgets too.

Like the setting of macOS, the hidden icons show again in Mission Control and when you click the wallpaper to show the desktop. To hide them there too, click the button next to “Desktop icons” in the “Shortcuts” settings, and turn on “Hide icons permanently”. Then each change restarts Finder, which brings its windows to the front.

## Without an app

@Steps {
1. Open “System Settings › Desktop & Dock”.
1. Next to “Show items”, turn off “On Desktop”.
}

To show the icons again, turn it on. The files stay in the Desktop folder, so you can still open them in Finder.

To hide them everywhere, also in Mission Control, run this in the Terminal app. It restarts Finder:

```console
defaults write com.apple.finder CreateDesktop false; killall Finder
```

To show them again, run it with `true`. The built-in setting is good when you hide the icons for a long time. Supercharge is faster when you hide them often, like for each screen share.
