---
isDraft: true
title: 'Super Menu'
subtitle: 'Your files, folders, apps, links, and shortcuts in one menu'
publicationDate: '2026-08-31'
platforms: [
	'macOS'
]
isPaid: true
isMenuBarApp: true
---

Build one fast, personal menu for everything you open often.

Super Menu can hold files, folders, apps, websites, Shortcuts, linked Shortcuts folders, recent files, separators, and nested groups. Arrange everything exactly where you want it, then open it from the menu bar or with a global keyboard shortcut.

### Highlights

- One customizable menu for files, folders, apps, links, and Shortcuts
- Nested groups that can appear inline or as submenus
- Cached folder browsing that stays responsive with large folders
- Per-folder sorting, filtering, icon sizing, previews, and presentation settings
- Smart folder views with filename or extension filters and bounded recursion
- Finder Saved Search support
- Linked Shortcuts folders that follow changes made in the Shortcuts app
- App-owned recent files with Pin and Clear actions
- Drag and drop from Finder, Safari, and the Shortcuts app
- Inline Quick Look previews and useful file actions
- Global keyboard shortcut with an option to open the menu at the pointer
- A choice of menu bar icons

## Guide {#guide}

Choose “Manage Menu” from the `…` submenu to open the organizer. Use the toolbar Add button to add an item, or drag an item anywhere into the organizer.

You can drag:

- Files, folders, and apps from Finder
- A website from Safari's address bar
- Shortcuts from the Shortcuts app

Drag rows to reorder them. Create groups for related items, then choose whether each group appears inline as a titled section or as a submenu. The path bar shows where you are when editing nested groups.

### Opening items

- Click a file, folder, app, link, or Shortcut to open or run it.
- A folder remains clickable even when it has a submenu. Click it to open the folder in Finder, or hover over it to browse its contents.
- Item submenus do not repeat an Open command. The main row is always the primary Open action.
- File submenus provide an inline Quick Look preview with compact metadata, Open With, Share, and Copy Path.
- Standalone and recent files show an inline Quick Look preview. Files inside a folder follow that folder's “Show file preview” setting.

### Alternative actions {#alternative-actions}

Hold <kbd>Option</kbd> while clicking an item to use its alternative action:

- File, folder, or app: Show in Finder
- Website link: Copy the URL
- Shortcut: Edit in the Shortcuts app

Linked Shortcuts folders open the Shortcuts app when clicked. Hover over one to browse and run the shortcuts currently in that folder.

### Folder settings {#folder-settings}

Each folder has its own browsing settings:

- **File icon size:** Small, medium, or large
- **Sort order:** Name, date added, date modified, date created, date accessed, kind, or tags
- **Sort direction:** Ascending or descending
- **Keep folders on top:** Group folders before files without changing the selected sort order
- **Browse folder contents:** Show folders as submenus. Turn this off when you only want folders to open directly.
- **Show file preview:** Show an inline Quick Look preview in file submenus. This is off by default.
- **Show hidden items:** Include hidden files
- **Browse package contents:** Treat app and document packages as folders
- **Presentation:** Show the normal hierarchy, folders only, files only, or one flattened level
- **Item limit:** Bound the number of entries shown

Smart folder options can filter by a name containing, beginning with, ending with, or exactly matching text; a file extension; a Finder tag; modification within a number of days; or a minimum or maximum file size. They can recurse through a bounded number of levels and flatten matching results. The same snapshot cache and item limit apply, so smart folders remain predictable and fast.

Quick Look loads previews on demand and manages its own system caching. Super Menu does not create a separate preview cache on disk.

### Finder Saved Searches

Add a `.savedSearch` file to use a Smart Folder created in Finder. Finder owns the query and scope, while Super Menu executes it as a bounded dynamic source. This Mac and explicit-folder scopes are supported. Super Menu asks for home-folder access so it can open matching home results, and omits any result the app cannot access.

### Recent files

Add a Recent Files section to show files opened through Super Menu. This history is local to the app and capped. Use Pin to turn a recent file into a permanent menu item, or Clear to remove the history.

### Keyboard access

Set a global keyboard shortcut in Settings. The menu can open from its menu bar icon or at the current pointer position. After opening it, use the arrow keys and Return to navigate without reaching for the mouse.

#### Privacy

Your menu, recent-file history, and settings stay on your Mac. Super Menu reads only the files and folders you explicitly authorize. Folder snapshots and Quick Look previews are not uploaded anywhere.

## Frequently Asked Questions {#faq}

### How is this different from Folder Peek?

[Folder Peek](/folder-peek) puts folders directly in the menu bar. Super Menu creates one curated hierarchy that can mix folders with individual files, apps, links, Shortcuts, dynamic Shortcut folders, Saved Searches, and recent files.

### How is this different from Short Run?

[Short Run](/short-run) is focused entirely on organizing and running Shortcuts. Super Menu combines Shortcuts with file browsing and other launchable items. Use Short Run when you want a dedicated Shortcut menu and Super Menu when you want one mixed menu.

### Why does a folder both open and have a submenu?

Hover over the row to browse the folder without leaving the menu. Click the row to open that folder in Finder. This keeps the primary action direct while preserving fast hierarchical browsing.

### Are file previews cached on disk?

Super Menu does not maintain its own preview cache. It asks macOS Quick Look for the preview when the file submenu opens and lets the system manage any internal caching.

### Can I browse very large folders?

Yes, but use the per-folder item limit and disable “Browse folder contents” or previews when you do not need them. Folder snapshots are read away from menu tracking, cached in memory, and bounded.

### Can I use aliases and symbolic links?

Yes. Super Menu follows aliases and symbolic links for opening and browsing while keeping the Option-click reveal action pointed at the item you added.

### Can I add a folder from the Shortcuts app?

Yes. Add a linked Shortcuts folder. Its name and contents update when the folder changes in the Shortcuts app.

### Can I export or back up my menu?

[See the app data backup guide](https://github.com/sindresorhus/guides/blob/main/backup-app-settings.md).
