---
title: 'How to Open a Folder in VS Code from Finder on Mac'
description: 'Add “Open in Visual Studio Code” to the right-click menu of Finder with Supercharge, or open a folder with the code command or the Dock.'
publicationDate: 2026-11-17
topic: 'finder-and-desktop'
apps: [
	'supercharge'
]
---

@QuickAnswer {
	Drag the folder onto the Visual Studio Code icon in the Dock. Or install the `code` command from VS Code, and type `code .` in Terminal. To have “Open in Visual Studio Code” at the top of the right-click menu of Finder, use [Supercharge](/supercharge).
}

## With Supercharge

@Steps {
1. Open the settings of [Supercharge](/supercharge), click “Tweaks”, and click “Configure…” next to “Context menu items”.
1. In the “Main Menu” tab, turn on “Open in App”.
1. Click the gear button next to “Open in App”, click the add button (+) below the list, and choose Visual Studio Code.
1. Right-click a folder in Finder, or an empty area of the folder that is open, and choose “Open in Visual Studio Code”.
}

You can add other apps too, like another code editor or an image editor. Each app shows only for the items that it can open, and a code editor also shows for text files.

The right-click items cannot show in synced folders, like iCloud Drive and Dropbox.

## Without an app

Drag the folder onto the icon of Visual Studio Code in the Dock or in the Applications folder. Or install the `code` command:

@Steps {
1. Open VS Code, and press ++Shift+Command+P++ to open the Command Palette.
1. Type `shell command`, and choose “Shell Command: Install 'code' and optionally 'copilot' commands in PATH”. When the AI features of VS Code are off, it is “Shell Command: Install 'code' command in PATH”.
1. In Terminal, [go to the folder](guide:open-terminal-in-folder-mac), and type `code .`.
}

[The instructions of VS Code.](https://code.visualstudio.com/docs/setup/mac)

For an item in the right-click menu, make a shortcut in the Shortcuts app with the “Open File” action, and set it to open in Visual Studio Code. Then turn on “Use as Quick Action” in the details of the shortcut. The item is then in the “Quick Actions” submenu. Supercharge needs no shortcut, and shows the item at the top level of the menu.
