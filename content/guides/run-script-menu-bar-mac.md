---
title: 'How to Run a Script from the Menu Bar on Mac'
description: 'Run your shell scripts and AppleScripts from one menu in the menu bar with Super Menu, which can ask for input, or with the Script menu of macOS.'
publicationDate: 2026-11-23
topic: 'menu-bar'
apps: [
	'super-menu'
]
---

@QuickAnswer {
	Add the script to [Super Menu](/super-menu), and click it in the menu to run it. [Without an app](#without-an-app), turn on the Script menu in the settings of Script Editor, and put the script in the Scripts folder of your Library folder.
}

## With Super Menu

@Steps {
1. Open [Super Menu](/super-menu), and click its icon in the menu bar.
1. Open the “…” submenu at the bottom of the menu, and choose “Manage Menu…”.
1. Click the plus button in the toolbar, choose “Scripts…”, and select the script.
1. Optional: Type the arguments, one on each line. Then click “Add”.
1. The first time, click “Allow” to give Super Menu access to its Scripts folder.
}

Click the script in the menu to run it. Super Menu runs AppleScripts, Automator workflows, and shell scripts, like `.sh`, `.py`, and `.rb` files. A shell script must be executable (`chmod +x`), and its first line must name the interpreter, like `#!/bin/sh`.

@Tips {
- An argument can ask for text when you run the script, like `{input name="Project"}`, or use the copied text, like `{clipboard}`. [All placeholders.](/super-menu#link-placeholders)
- To run a script on a file, turn on “Show in file submenus” in the settings of the script. The script is then in the “Run Script” submenu of the files in the menu.
- To add a folder of scripts, choose “Script Folder…” in place of “Scripts…”. Each script in the folder runs when you click it.
- Hold ++Option++ while you click a script to open it in its editor.
- A script does not show what it prints. To see a result, show it in an alert, like `osascript -e 'display alert "Done"'`.
}

Super Menu needs macOS 27 or later. [More about scripts.](/super-menu#scripts)

## Without an app

macOS has a Script menu, which is off at first:

@Steps {
1. Open the Script Editor app, choose “Script Editor › Settings”, and click “General”.
1. Turn on “Show Script menu in menu bar”. <source:https://support.apple.com/guide/script-editor/scpedt27975/mac>
1. Click the Script menu in the menu bar, and choose “Open Scripts Folder › Open User Scripts Folder”.
1. Put your script in this folder (`~/Library/Scripts`). It now shows in the Script menu.
}

The Script menu runs AppleScripts, Automator workflows, and shell scripts. It is free and good for a few scripts. It cannot give arguments to a script or ask for input, and it shows only the scripts in its folders. Super Menu runs scripts from any folder, asks for input, and has your files, apps, and links in the same menu.
