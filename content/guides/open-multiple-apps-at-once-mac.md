---
title: 'How to Open Several Apps and Folders at Once on Mac'
description: 'Open the apps, folders, files, and links of a project with one click from a group in Super Menu, or with a shortcut in the Shortcuts app.'
publicationDate: 2026-11-13
topic: 'windows-apps-and-dock'
apps: [
	'super-menu'
]
---

@QuickAnswer {
	In [Super Menu](/super-menu), put the apps, folders, files, and links of a project in a group, and turn on “Open all items on click”. One click on the group opens all of them. [Without an app](#without-an-app), make a shortcut with one “Open App” action for each app.
}

## With Super Menu

@Steps {
1. Click [Super Menu](/super-menu) in the menu bar, open the “…” submenu, and choose “Manage Menu…”.
1. Click the add button in the toolbar, and choose “Group…”.
1. Type a name, like “Client A”, turn on “Open all items on click”, and click “Add”.
1. Drag the apps, folders, files, and links of the project from Finder onto the group.
1. Click the group in the menu to open all of it.
}

You can still point at the group to open one item from its submenu. Shortcuts, scripts, and groups inside the group are not opened. Without “Open all items on click”, hold ++Option++ in the submenu of the group, and choose “Open All”. [More about groups.](/super-menu#open-group-on-click)

## Without an app

The Shortcuts app can open many apps with one shortcut:

@Steps {
1. In the Shortcuts app, make a new shortcut.
1. Add one “Open App” action for each app. For a folder or a file, add the “File” action, and then the “Open File” action.
1. Run the shortcut, or give it a keyboard shortcut in its details. You can also [add it to the menu bar](guide:add-shortcut-to-menu-bar-mac).
}

This is free, and it works well for a few apps. Each item is one more action, so a project with many folders and links takes more time to set up and to change.
