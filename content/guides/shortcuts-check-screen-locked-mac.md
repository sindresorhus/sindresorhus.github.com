---
title: 'How to Check if the Screen Is Locked in Shortcuts on Mac'
description: 'Find out in a shortcut if your Mac is locked with the free Actions app, so the shortcut does something only when you are away, or only when you are at the Mac.'
publicationDate: 2026-11-22
topic: 'shortcuts'
apps: [
	'actions'
]
---

@QuickAnswer {
	Add the “Is Screen Locked” action of the free [Actions](/actions) app, and check its result in an “If” action. [Without an app](#without-an-app), a “Run Shell Script” action with a command can check it.
}

## With Actions

@Steps {
1. Install [Actions](/actions), and open it once.
1. In your shortcut, add the [“Is Screen Locked”](/actions#:~:text=Is%20Screen%20Locked) action of Actions. It has no options.
1. Add an “If” action below it that checks if the result is true.
1. Put the actions for when the Mac is locked in the “If” part, and the other actions in the “Otherwise” part.
}

For example, a shortcut that you [run on your Mac from your iPhone](guide:run-mac-shortcut-from-iphone) can stop when you are at the Mac, or show a notification only when the screen is not locked.

@Tips {
- The action is for Mac. It does not work on iPhone.
- To check if the screen saver is on, use “Is Screen Saver Active”.
}

## Without an app

The “Lock Screen” action of Shortcuts locks the Mac, but it does not tell you the state. The “Run Shell Script” action can check it with this command, which gives 1 when the screen is locked and 0 when it is not:

```sh
ioreg -n Root -d1 -a | grep -c CGSSessionScreenIsLocked || true
```

A script needs “Allow Running Scripts”: choose “Shortcuts › Settings”, click “Advanced”, and turn it on. The action of Actions is easier, and it gives a true or false value for “If”.
