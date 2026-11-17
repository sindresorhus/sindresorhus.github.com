---
title: 'How to Kill the Process on a Port on Mac'
description: 'Find and stop the process that uses a port, like 3000 or 8080, with two commands in Terminal, or with the Kill Process action of Shortcutie.'
publicationDate: 2026-11-11
topic: 'mac'
apps: [
	'shortcutie'
]
---

@QuickAnswer {
	In the Terminal app, run `lsof -i tcp:3000 -sTCP:LISTEN` to see the process that listens on port 3000, and `kill` with its PID to stop it. To do it without Terminal, like from the menu bar or with a keyboard shortcut, use the “Kill Process” action of [Shortcutie](/shortcutie) in the Shortcuts app.
}

## With Shortcutie

Terminal is the fast way for most developers. A shortcut is better when you do this often, or do not want to open Terminal:

@Steps {
1. Install [Shortcutie](/shortcutie), and open it once.
1. In the Shortcuts app, click the add button to make a new shortcut.
1. Add the “Kill Process” action of Shortcutie. Keep “Port Number” in “Kill By”.
1. Click the port number field, and type the port, like 3000. To choose the port each time, ++Control++-click the field, and choose “Ask Each Time”.
1. Run the shortcut. The result is the number of processes that it stopped.
}

@Tips {
- To see what uses a port before you stop it, use the “Find Listening Port” action, which gives the listening ports of your Mac. To only count the processes that the action would stop, turn on “Dry Run”.
- The action asks the process to quit. Turn on “Force Kill” for a process that does not respond.
- “Kill By” can also be “Process Name” or “Process ID”.
- To run the shortcut in one click, [put it in the menu bar](guide:add-shortcut-to-menu-bar-mac).
}

## Without an app

In the Terminal app, run this with your port number:

```console
lsof -i tcp:3000 -sTCP:LISTEN
```

It shows only the process that listens on the port, not the apps that are connected to it, like a browser. The “PID” column shows the number of the process, and “COMMAND” shows its name. Then stop the process with its PID:

```console
kill 12345
```

If the process does not stop, use `kill -9`. This stops it immediately, and it cannot save its data. To find and stop the process in one command:

```console
kill $(lsof -ti tcp:3000 -sTCP:LISTEN)
```

This is the fast way when Terminal is already open, like for a development server that did not stop.

You can also stop a process in Activity Monitor: select the processes, and click the (x) button in the toolbar. But Activity Monitor does not show which process uses a port, so you must first get its name with `lsof`.
