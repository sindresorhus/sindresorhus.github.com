---
title: 'How to Add a Spacer to the Dock on Mac'
description: 'Group the apps in your Dock with spacers, with a button in Supercharge, or with a command in Terminal.'
publicationDate: 2026-10-31
topic: 'windows-apps-and-dock'
apps: [
	'supercharge'
]
---

@QuickAnswer {
	In the settings of [Supercharge](../apps/supercharge/index.md), click “Tools”, and click “Add Regular” or “Add Small” in “Dock spacers”. Without an app, add a spacer with a `defaults` command in the Terminal app.
}

## With Supercharge

@Steps {
1. Open [Supercharge](../apps/supercharge/index.md), and give it the access that it asks for in [“Device Control and Data Access”](/apps/faq#device-control-access).
1. Click its icon in the menu bar, and open its settings.
1. Click “Tools”.
1. In “Dock spacers”, click “Add Regular” or “Add Small” in “Main section” for the apps, or in “Trash section” for the side with the Trash.
1. Drag the spacer in the Dock to where you want it.
}

A spacer is an empty space that you move like an app icon, so you can put your apps in groups, like work apps and other apps. To remove a spacer, right-click it, and choose to remove it. Supercharge can also make the Dock icons of hidden apps dim, and show the Dock without a delay.

## Without an app

macOS has no setting for this, but the Dock still knows spacers. Open the Terminal app, and run this command. It adds a spacer at the end of the apps, and restarts the Dock:

```console
defaults write com.apple.dock persistent-apps -array-add '{tile-data={};tile-type="spacer-tile";}' && killall Dock
```

Then drag the spacer to where you want it. For a smaller spacer, write `small-spacer-tile` instead of `spacer-tile`. To add a spacer on the side with the Trash, write `persistent-others` instead of `persistent-apps`. To remove a spacer, drag it out of the Dock.

The command is good if you add a spacer one time. Supercharge does the same with a click, and you do not need to type a command.
