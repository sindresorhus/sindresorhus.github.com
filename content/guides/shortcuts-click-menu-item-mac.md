---
title: 'How to Click a Menu Item of Any App with Shortcuts on Mac'
description: 'Make a shortcut choose a menu item, like “File › Export…”, in any app with the Trigger Menu Bar Item action of Shortcutie, or with AppleScript.'
publicationDate: 2026-11-23
topic: 'shortcuts'
apps: [
	'shortcutie'
]
---

@QuickAnswer {
	Add the “Trigger Menu Bar Item” action of [Shortcutie](/shortcutie), and type the path of the item with `>` between the menus, like `File > Export`. [Without an app](#without-an-app), the “Run AppleScript” action can click a menu item with System Events.
}

## With Shortcutie

@Steps {
1. Install [Shortcutie](/shortcutie), and open it once. It asks for Accessibility access, which it needs to click menu items.
1. In your shortcut, add the “Trigger Menu Bar Item” action of Shortcutie.
1. Type the path of the menu item, like `Apple > System Settings` or `View > Show Sidebar`. The titles must match exactly, also in uppercase and lowercase, but the “…” at the end is optional.
1. Optional: expand the action, and choose the app in “App”. When it is empty, the action uses the app in front.
}

If the app does not react, turn on “Activate App”, so the app comes to the front first.

@Tips {
- For an item that changes its title, type both titles with `||`, like `Edit > Start Dictation || Stop Dictation`.
- For a title that changes, use `*`, like `File > Export*` for all items that start with “Export”.
- When an item is not always there, turn on “Ignore Errors”, so the shortcut does not stop.
- The path of BetterTouchTool works too, like `File;Save As`.
- For the menu that shows when you right-click, use the “Trigger Context Menu Item” action. It uses the menu at the mouse pointer.
- To press the keyboard shortcut of an item instead, use the “Press Keyboard Shortcut” action. <guide:shortcuts-press-keyboard-shortcut-mac>
}

## Without an app

The “Run AppleScript” action of Shortcuts can click a menu item with System Events:

@Steps {
1. In your shortcut, add the “Run AppleScript” action.
1. Replace the text in the action with a script like the one below, with the name of your app, menu, and item.
1. If the shortcut cannot run the script, choose “Shortcuts › Settings”, click “Advanced”, and turn on “Allow Running Scripts”.
1. Run the shortcut. The first time, macOS asks for Accessibility access. Allow it in “[System Settings › Privacy & Security › Accessibility](x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility)”.
}

```applescript
tell application "System Events"
	tell process "Safari"
		set frontmost to true
		click menu item "Pin Tab" of menu "Window" of menu bar 1
	end tell
end tell
```

This is the example of [Apple’s guide to scripting the user interface](https://developer.apple.com/library/archive/documentation/LanguagesUtilities/Conceptual/MacAutomationScriptingGuide/AutomatetheUserInterface.html). An item in a submenu needs a longer path, and the title must be exact, also its “…”. Shortcutie finds the item from a short path.
