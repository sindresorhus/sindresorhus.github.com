---
title: 'How to Add Apps to the Menu Bar on Mac'
description: 'macOS puts apps in the Dock, not in the menu bar. Super Menu adds one menu with the apps that you choose, also as icons, like a small Dock.'
publicationDate: 2026-11-11
topic: 'menu-bar'
apps: [
	'super-menu'
]
---

@QuickAnswer {
	macOS has no setting to put an app in the menu bar. With [Super Menu](../apps/super-menu/index.md), you get one menu in the menu bar with the apps that you choose, as a list or as icons, like a small Dock. Without an app, add the “Open App” control of Shortcuts to Control Center or the menu bar, one for each app.
}

## With Super Menu

@Steps {
1. Open [Super Menu](../apps/super-menu/index.md), and click its icon in the menu bar.
1. Open the “…” submenu at the bottom of the menu, and choose “Manage Menu…”.
1. Click the plus button in the toolbar, and choose “Apps…”.
1. Select the apps, and click “Choose”.
}

Click the menu bar icon, and click an app to open it. You can also drag apps from Finder into the window where you manage the menu.

@Tips {
- To show the apps as icons, in rows like a small Dock, click the plus button, choose “Group…”, give the group a name, and click “Add”. Drag the apps on the group. Then Control-click the group, choose “Edit…”, and turn on “Show as icons”. This works for a group with only apps.
- Set a keyboard shortcut for “Show menu” in the settings to open the menu from the keyboard.
- The same menu can have your files, folders, links, and shortcuts.
}

Super Menu needs macOS 27 or later.

## Without an app

On macOS 26 and later, the Shortcuts app has a control that opens an app:

@Steps {
1. Click Control Center in the menu bar, and click “Edit Controls”.
1. Click “Shortcuts”, and click “Open App”, which opens a single app.
1. Choose “Add to Control Center”, and click “Done”.
}

To have the control in the menu bar, Control-click it in Control Center, and choose “Add to Menu Bar”. [Apple’s instructions.](https://support.apple.com/guide/shortcuts-mac/apd163eb9f95/mac)

Each control opens one app, so this is good for one or two apps. The Dock is still the built-in place for many apps: turn on “Automatically hide and show the Dock” in “[System Settings › Desktop & Dock](x-apple.systempreferences:com.apple.Desktop-Settings.extension)” to keep it out of the way.
