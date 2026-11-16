---
title: 'How to Auto Click on Mac'
description: 'Click the mouse again and again, at the pointer or at a position, with a shortcut that repeats the Click Mouse Button action of Shortcutie.'
publicationDate: 2026-11-13
topic: 'shortcuts'
apps: [
	'shortcutie'
]
---

@QuickAnswer {
	macOS has no auto clicker. With [Shortcutie](../apps/shortcutie/index.md), make a shortcut with a “Repeat” action, and put its “Click Mouse Button” action and a “Wait” action in the repeat. Without an app, Dwell clicks when you hold the pointer still, but only one time each time.
}

## With Shortcutie

@Steps {
1. Install [Shortcutie](../apps/shortcutie/index.md), and open it once. It asks for Accessibility access, which it needs to click.
1. In the Shortcuts app, make a new shortcut, and add the “Repeat” action. Set the number of times, like 100.
1. Inside the repeat, add the “Click Mouse Button” action of Shortcutie, and choose “Single Click” and “Left”.
1. Below it, inside the repeat, add the “Wait” action, and set the time between the clicks.
1. Put the pointer where you want the clicks, and run the shortcut, like with a keyboard shortcut.
}

When “X” and “Y” are empty, the action clicks where the pointer is. To click at a fixed position, type it in “X” and “Y”: the top left of the main screen is 0, 0. Use the “Get Mouse Position” action to find the position of the pointer. The pointer moves to the position for a moment, and then goes back.

@Tips {
- “Double Click” and “Triple Click” are also in the action, and so are the right and the middle button.
- The repeat stops after the number of times that you set, so a mistake does not click forever.
}

## Without an app

Dwell of the Accessibility Keyboard clicks for you when you hold the pointer still on an item ([Apple’s guide](https://support.apple.com/guide/mac-help/mchl437b47b0/mac)):

@Steps {
1. Open “System Settings › Accessibility › Keyboard”, and turn on “Accessibility Keyboard”.
1. Click the info button next to it, go to Dwell, and turn on “Show dwell actions in menu bar”.
1. Choose “Left Click” in the Dwell menu, and hold the pointer still on an item.
}

Dwell is for people who cannot click easily. It clicks one time each time the pointer stops, so it cannot click many times in one place.
