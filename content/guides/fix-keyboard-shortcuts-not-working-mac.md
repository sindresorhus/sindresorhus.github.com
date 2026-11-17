---
title: 'How to Fix Keyboard Shortcuts That Stopped Working on Mac'
description: 'Keyboard shortcuts or text expansion suddenly stopped working on Mac? Often an app left Secure Input on. Find the app with Shortcutie, and quit it.'
publicationDate: 2026-11-13
topic: 'keyboard-and-trackpad'
apps: [
	'shortcutie'
	'supercharge'
]
---

@QuickAnswer {
	When global keyboard shortcuts and text expansion stop working in all apps at the same time, an app has often left Secure Input on. Find the app with the “Get Apps Using Secure Input” action of [Shortcutie](/shortcutie), and quit it. [Without an app](#without-an-app), quit your password manager and browsers, or lock the Mac and unlock it again.
}

## What Secure Input is

Secure Input is a security feature of macOS. While it is on, other apps cannot read what you type. Apps turn it on in password fields, so no app can record your password. While it is on, the apps that listen for keys, like launchers, text expanders, and apps with global keyboard shortcuts, get no keys.

An app must turn Secure Input off again when you leave the password field. Some apps do not, also when they are in the background. Password managers, like 1Password and Bitwarden, and browsers are often the cause.

## With Shortcutie

@Steps {
1. Install [Shortcutie](/shortcutie), and open it once.
1. In the Shortcuts app, make a new shortcut, and add the “Get Apps Using Secure Input” action.
1. Keep “Only Non-Active Apps” on. These are the apps that block keys while they are not in front.
1. Add the “Show Content” action, and run the shortcut.
1. Quit the app that it shows, and try the keyboard shortcut again.
}

If the result is `loginwindow`, the login window of macOS has Secure Input on. Lock the Mac with ++Control+Command+Q++, and unlock it.

[Supercharge](/supercharge) also checks for such an app. When an app blocks the keys, the Supercharge menu shows a warning at the bottom, like “1Password is blocking keyboard shortcuts”.

## Without an app

Try these steps, one at a time:

@Steps {
1. Quit your password manager and your browsers.
1. Lock the Mac with ++Control+Command+Q++, and unlock it.
1. Quit all apps.
1. Restart the Mac.
}

To see which process has Secure Input on, run this in Terminal:

```console
ioreg -l -w 0 | grep -o '"kCGSSessionSecureInputPID"=[0-9]*'
```

No output means that Secure Input is off. Else, the number is a process ID. Run `ps -p 1234 -o comm=` with that number to see the name of the process. The process is not always the app that caused it, so quitting apps one at a time can still be necessary.

Terminal has its own Secure Input setting: “[Terminal › Secure Keyboard Entry](https://support.apple.com/guide/terminal/trml109/mac)”. When it has a checkmark, Terminal blocks the keys while it is in front. [More in the FAQ.](/apps/faq#secure-input-problem)

When only one keyboard shortcut does not work, and the others do, another app often uses the same keys. [How to find which app uses a keyboard shortcut.](guide:find-which-app-uses-keyboard-shortcut-mac)
