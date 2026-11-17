---
title: 'How to Change Smart Quotes to Straight Quotes on Mac'
description: 'Turn off smart quotes when you type in the Keyboard settings of macOS, and change the smart quotes of text that you copy to straight quotes with Pure Paste.'
publicationDate: 2026-11-19
topic: 'text-and-images'
apps: [
	'pure-paste'
]
---

@QuickAnswer {
	To type straight quotes, open “[System Settings › Keyboard](x-apple.systempreferences:com.apple.Keyboard-Settings.extension)”, click “Edit…” for “Input Sources”, and turn off “Use smart quotes and dashes”. To change the smart quotes in text that you copy, like a command from a website, turn on “Normalize quotes” in [Pure Paste](/pure-paste).
}

Smart quotes are the curly quotes, like `“` and `’`. Code and the Terminal need straight quotes, like `"` and `'`, so a command with smart quotes fails.

## With Pure Paste

@Steps {
1. Open [Pure Paste](/pure-paste). Its icon is in the menu bar.
1. Click the icon, choose “Settings…”, and click “Extras”.
1. In “When clearing formatting”, turn on “Normalize quotes”.
1. Copy the text, and paste it. Pure Paste changed the smart quotes to straight quotes when you copied the text.
}

Pure Paste changes `“”`, `‘’`, `«»`, and other quotes. It also removes the formatting of the text, like the fonts and the colors. To keep the formatting of what you copy in an app, like a word processor, add the app in the “Exclude” settings.

## Without an app

macOS changes the quotes that you type to smart quotes. To stop this in all apps:

@Steps {
1. Open “[System Settings › Keyboard](x-apple.systempreferences:com.apple.Keyboard-Settings.extension)”.
1. In “Text Input”, click “Edit…” for “Input Sources”.
1. Select “All Input Sources”, and turn off “Use smart quotes and dashes”.
}

To change it only in one app, like Notes or TextEdit, choose “Edit › Substitutions”, and turn off “Smart Quotes”. Some apps, like Pages and Microsoft Word, have a setting of their own.

These settings change only what you type. To change the quotes in text that is already there, use “Edit › Find › Find and Replace…” in the app, and replace each kind of quote.
