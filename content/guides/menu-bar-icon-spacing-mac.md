---
title: 'How to Change the Spacing of Menu Bar Icons on Mac'
description: 'Fit more icons in the menu bar, like next to the notch of a MacBook, with the free Menu Bar Spacing app or a Terminal command. Not possible on macOS 27.'
publicationDate: 2026-11-11
topic: 'menu-bar'
apps: [
	'menu-bar-spacing'
]
---

@QuickAnswer {
	On macOS 26 and earlier, the free [Menu Bar Spacing](../apps/menu-bar-spacing/index.md) app makes the gap between the menu bar icons smaller, so more icons fit, like next to the notch of a MacBook. On macOS 27, this is no longer possible: Apple rewrote the menu bar, and removed the hidden settings for the spacing.
}

## With Menu Bar Spacing

On macOS 26 and earlier:

@Steps {
1. Open [Menu Bar Spacing](../apps/menu-bar-spacing/index.md).
1. Drag the slider to the left to make the gap smaller. The icons of macOS, like Wi-Fi and the battery, change immediately.
1. For the icons of other apps, click “Relaunch All Apps”, or restart your Mac. The button quits and opens all your apps again, so save your work first. The older version for macOS 15 has no button: it relaunches the apps with menu bar icons by itself.
}

The setting stays, also after a restart, so you can quit the app, or even delete it. To go back to the normal spacing, open the app, and click “Reset”.

## Without an app

Menu Bar Spacing changes two hidden settings of macOS, and you can set them in the Terminal app too. On macOS 26 and earlier, run:

```console
defaults -currentHost write -globalDomain NSStatusItemSpacing -int 8
defaults -currentHost write -globalDomain NSStatusItemSelectionPadding -int 6
```

Then log out and log in again. Smaller numbers give a smaller gap. To go back to the normal spacing:

```console
defaults -currentHost delete -globalDomain NSStatusItemSpacing
defaults -currentHost delete -globalDomain NSStatusItemSelectionPadding
```

The app does the same with a slider, and shows the result at once.

## On macOS 27

macOS 27 has no setting for the spacing, hidden or not, so the app and the commands do nothing. To get more space, remove the icons that you do not need: open “[System Settings › Menu Bar](x-apple.systempreferences:com.apple.ControlCenter-Settings.extension)”, and turn off the items and the apps that you do not use. To keep related icons together, see [how to group menu bar icons](group-menu-bar-icons-mac.md).
