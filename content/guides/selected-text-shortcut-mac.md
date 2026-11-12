---
title: 'How to Use the Selected Text in a Shortcut on Mac'
description: 'Get the text that is selected in any app into a shortcut on Mac with the Get Selected Text action of Shortcutie, or run the shortcut as a service.'
publicationDate: 2026-11-13
topic: 'shortcuts'
apps: [
	'shortcutie'
]
---

@QuickAnswer {
	Add the “Get Selected Text” action of [Shortcutie](../apps/shortcutie/index.md) to your shortcut. It gets the text that is selected in the window in front, also when you run the shortcut with a keyboard shortcut. Without an app, turn on “Services Menu” in the details of the shortcut, and run it from the Services menu of the app, which gives the selected text to the shortcut as its input.
}

## With Shortcutie

@Steps {
1. Install [Shortcutie](../apps/shortcutie/index.md), and open it once. It asks for Accessibility access, which it needs to read the selected text.
1. In the Shortcuts app, click the add button to make a new shortcut, and add the “Get Selected Text” action of Shortcutie.
1. Add the actions that use the “Selected Text” variable, like “Translate Text” or “Copy to Clipboard”.
1. Click the details button in the sidebar, click “Add Keyboard Shortcut”, and press the keys.
1. Select text in an app, and press the keyboard shortcut.
}

The action gets nothing when no text is selected, when the window with the text is not in front, when the text is in a password field, or when the app does not support Accessibility.

## Without an app

@Steps {
1. In the Shortcuts app, open the shortcut, click the details button in the sidebar, and select “Services Menu”.
1. In the actions, use the “Shortcut Input” variable for the selected text.
1. Select text in an app, choose the menu with the name of the app, choose “Services”, and choose the shortcut.
}

To run the service with a keyboard shortcut, open “[System Settings › Keyboard](x-apple.systempreferences:com.apple.Keyboard-Settings.extension)”, click “Keyboard Shortcuts”, click “Services”, and give the shortcut a keyboard shortcut. [Apple’s instructions.](https://support.apple.com/guide/shortcuts-mac/apd163eb9f95/mac) This is free, and it is enough for most shortcuts. But a shortcut that you run from the Dock or the menu bar gets no text from the app.
