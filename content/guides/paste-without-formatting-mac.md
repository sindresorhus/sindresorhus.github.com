---
title: 'How to Paste Without Formatting on Mac'
description: 'Press Option+Shift+Command+V to paste as plain text, or use Pure Paste to make Command+V always paste without formatting, in every app.'
publicationDate: 2026-10-29
topic: 'text-images-and-sound'
apps: [
	'pure-paste'
]
screenshot: {
	number: 1
	description: 'Text pasted into a document, with and without its formatting'
}
---

@QuickAnswer {
	Press ++Option+Shift+Command+V++, or choose “Edit › Paste and Match Style”. The text then gets the font and style of the place you paste it in. To make ++Command+V++ always paste without formatting, use [Pure Paste](../apps/pure-paste/index.md).
}

## With Pure Paste

[Pure Paste](../apps/pure-paste/index.md) clears the formatting (fonts, colors, bold, links, and tables) when you copy text, so you paste plain text with the normal ++Command+V++ in every app.

@Steps {
1. Open [Pure Paste](../apps/pure-paste/index.md). Its icon is in the menu bar, and “Automatically clear formatting” is on.
1. Copy text with ++Command+C++, like from a web page or an email.
1. Paste it with ++Command+V++. The text has no formatting.
}

Pure Paste does not change files, images, or passwords that you copy from a password manager.

@Tips {
- To keep the formatting one time, press and release ++Option++, and then press ++Command+C++.
- To keep the formatting in some apps, like Keynote, add them in the “Exclude” settings.
- To clear the formatting only when you want, turn off “Automatically clear formatting”, and set a keyboard shortcut for “Clear formatting and paste” in the “Shortcuts” settings.
- Right-click the menu bar icon to turn the automatic mode on or off.
}

Pure Paste can also keep the links, remove tracking parameters from URLs, change typographic quotes to straight quotes, and remove invisible characters. Turn these on in the “Extras” settings.

## Without an app

### Paste and Match Style

Most Mac apps, like Mail, Notes, Pages, and Safari, have “Paste and Match Style” in the Edit menu, with the shortcut ++Option+Shift+Command+V++. Some apps use another name or shortcut:

- **Google Docs:** Press ++Shift+Command+V++, or choose “Edit › Paste without formatting”.
- **Microsoft Word:** Choose “Edit › Paste and Match Formatting”. It keeps bold and italic on parts of the text.

Some apps do not have the command at all, and the shortcut is hard to remember.

### Make ++Command+V++ paste without formatting

You can give “Paste and Match Style” the ++Command+V++ shortcut in all apps:

@Steps {
1. Open “[System Settings › Keyboard](x-apple.systempreferences:com.apple.Keyboard-Settings.extension)”, and click “Keyboard Shortcuts…”.
1. Choose “App Shortcuts”, and click the add button.
1. Keep “All Applications”, and type `Paste and Match Style` in “Menu title”. Type it exactly like in the Edit menu.
1. Click “Keyboard shortcut”, press ++Command+V++, and click “Done”.
}

This works only in the apps that have a command with exactly this name, so it does not work in Word, which uses another name. To paste with the formatting, choose “Edit › Paste”. [Why Pure Paste does more.](../apps/pure-paste/index.md#why-not-just-remap-the-paste-and-match-style-keyboard-shortcut-to-v)
