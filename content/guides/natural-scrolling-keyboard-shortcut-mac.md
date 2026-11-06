---
title: 'How to Change the Scroll Direction with a Keyboard Shortcut on Mac'
description: 'macOS has no keyboard shortcut for natural scrolling. With Shortcutie, a shortcut turns it on or off, like when you change from the trackpad to a mouse.'
publicationDate: 2026-11-11
topic: 'keyboard-and-trackpad'
apps: [
	'shortcutie'
]
---

@QuickAnswer {
	The scroll direction is the “Natural scrolling” switch in “System Settings › Trackpad” and “System Settings › Mouse”. macOS has no keyboard shortcut for it. [Shortcutie](../apps/shortcutie/index.md) adds the “Set Natural Scrolling” action to the Shortcuts app, so a shortcut with a keyboard shortcut can change the direction.
}

With natural scrolling, the content moves in the same direction as your fingers. Many people like this on a trackpad, but not with the wheel of a mouse.

## With Shortcutie

@Steps {
1. Install [Shortcutie](../apps/shortcutie/index.md), and open it once.
1. In the Shortcuts app, click the add button to make a new shortcut.
1. Add the “Set Natural Scrolling” action of Shortcutie, and set it to off. This is the shortcut for the mouse.
1. Click the details button of the shortcut, click “Add Keyboard Shortcut”, and press the keys that you want.
1. Make a second shortcut in the same way, but keep the action on, and give it another keyboard shortcut. This is the shortcut for the trackpad.
}

The change is immediate. To run the shortcuts in one click, [put them in the menu bar](add-shortcut-to-menu-bar-mac.md).

For one shortcut that changes the direction each time, add the “Get Natural Scrolling” action, and below it an “If” action that checks its result, with a “Set Natural Scrolling” action for each of the two cases.

## Without an app

@Steps {
1. Open System Settings, and click “Trackpad” in the sidebar. With a mouse, click “Mouse”.
1. For a trackpad, click “Scroll & Zoom”.
1. Turn “Natural scrolling” on or off.
}

Apple’s instructions for the [trackpad](https://support.apple.com/guide/mac-help/mchlp1226/mac) and the [mouse](https://support.apple.com/guide/mac-help/mh29222/mac). This is enough when you always use the same device. The shortcut is for when you change between a trackpad and a mouse often, like with a MacBook that you connect to a mouse at your desk.
