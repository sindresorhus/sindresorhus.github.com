---
title: 'How to Add a Folder to the Mac Menu Bar'
description: 'Open the files of a folder, like Downloads or a project folder, from the menu bar with Folder Peek, or put the folder in the Dock as a stack.'
publicationDate: 2026-10-30
topic: 'menu-bar'
apps: [
	'folder-peek'
]
screenshot: {
	number: 1
	description: 'The files of a folder in a menu below its icon in the menu bar'
}
---

@QuickAnswer {
	macOS cannot put a folder in the menu bar. [Folder Peek](../apps/folder-peek/index.md) can: choose “Add Folder…” in its menu, and choose the folder. Without an app, drag the folder to the right side of the Dock, where it shows its files as a stack.
}

## With Folder Peek

@Steps {
1. Open [Folder Peek](../apps/folder-peek/index.md). Its icon is in the menu bar.
1. Click the icon, and choose “Add Folder…”.
1. Choose the folder, like Downloads, and click “Add”. The folder is now in the menu bar.
1. Click the folder in the menu bar to see its files, and click a file to open it.
}

Each folder is a menu bar item of its own. To show the name of the folder next to its icon, open the submenu of the first item of the menu (the name of the folder), choose “Configure Folder…”, and set “Show” to “Icon & Title”. In the same window, you can change the icon, the sort order, and the maximum number of items. If the menu bar has little space, set “Show folders” to “in a single menu bar item” in the settings, so all folders share one menu.

@Tips {
- Hold ++Option++ when you click a file to show it in Finder.
- Drag a file from the menu to another app or folder.
- Set a keyboard shortcut for a folder to open its menu from anywhere.
- To use Folder Peek as an app launcher, add the Applications folder, or a folder with aliases of the apps you use. [More about the app launcher.](../apps/folder-peek/index.md#app-launcher)
- To show files and folders from many places in one menu, put aliases of them in one folder, or use [Super Menu](../apps/super-menu/index.md).
}

## Without an app

The menu bar of macOS has no place for folders, but the Dock does:

@Steps {
1. Drag the folder from Finder to the right side of the Dock, next to the Trash.
1. Control-click the folder in the Dock. Set “Display as” to “Folder” or “Stack”, and “View content as” to “Fan”, “Grid”, or “List”. “Sort by” changes the order.
1. Click the folder in the Dock to see its files, and click a file to open it.
}

The Downloads folder is already in the Dock. A folder in the Dock works well when the Dock is always visible. If you hide the Dock, or if you want a preview of the files and a keyboard shortcut, Folder Peek is faster. [How Folder Peek is different from folders in the Dock.](../apps/folder-peek/index.md#dock-folders)

You can also add a folder to the “Favorites” in the sidebar of Finder windows: drag the folder to the sidebar. It is then one click away in each Finder window, but you must open a Finder window first.
