---
title: 'How to Press a Keyboard Shortcut with Shortcuts on Mac'
description: 'Make a shortcut press keys for you, like Shift+Command+N in Finder, with the Press Keyboard Shortcut action of Shortcutie, or with AppleScript.'
publicationDate: 2026-11-12
topic: 'shortcuts'
apps: [
	'shortcutie'
]
---

@QuickAnswer {
	The Shortcuts app has no action that presses keys. [Shortcutie](/shortcutie) adds the “Press Keyboard Shortcut” action, where you choose the key and the modifier keys, and optionally the app that gets the keys. [Without an app](#without-an-app), the “Run AppleScript” action can press keys with System Events.
}

## With Shortcutie

@Steps {
1. Install [Shortcutie](/shortcutie), and open it once. It asks for Accessibility access, which it needs to press keys.
1. In your shortcut, add the “Press Keyboard Shortcut” action of Shortcutie.
1. Type the key in the field after “Character”, like `n`.
1. Turn on the modifier keys of the shortcut: “Command”, “Option”, “Control”, or “Shift”.
1. Optional: expand the action, and choose the app that gets the keys in “Target App”. When it is empty, the keys go to the app in front, like when you press them.
}

If the target app does not react, turn on “Activate App”, so the app comes to the front first.

@Tips {
- For a key without a character, like ++Return++, ++Esc++, an arrow key, or a function key, change “Character” to “Special Key”, and choose the key.
- The action uses the positions of the keys, like macOS does for shortcuts. For a key of another keyboard layout, like “ø”, change “Character” to “Key Code”, and type the code of the key.
- The ++Fn++ key is not supported.
- To click a menu item instead, which is more reliable when the shortcut of the item changes, use the “Trigger Menu Bar Item” action.
}

## Without an app

The “Run AppleScript” action of Shortcuts can press keys with System Events:

@Steps {
1. In your shortcut, add the “Run AppleScript” action.
1. Replace the text in the action with `tell application "System Events" to keystroke "n" using {shift down, command down}`, with your key and modifier keys.
1. If the shortcut cannot run the script, choose “Shortcuts › Settings”, click “Advanced”, and turn on “Allow Running Scripts”.
1. Run the shortcut. The first time, macOS asks for Accessibility access. Allow it in “[System Settings › Privacy & Security › Accessibility](x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility)”.
}

`keystroke` types characters. For a key without a character, use `key code` with the number of the key, like `key code 36` for ++Return++. This works, but the script is harder to change than the fields of an action.
