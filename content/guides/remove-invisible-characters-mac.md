---
title: 'How to Remove Invisible Characters from ChatGPT Text on Mac'
description: 'Remove zero-width spaces and other hidden characters from copied text, like from ChatGPT, with Pure Paste, or clean the clipboard with a Terminal command.'
publicationDate: 2026-11-12
topic: 'text-and-images'
apps: [
	'pure-paste'
]
---

@QuickAnswer {
	Turn on “Remove invisible characters” in the “Extras” settings of [Pure Paste](/pure-paste). Then each text that you copy, like an answer of ChatGPT, has no zero-width spaces or other hidden characters when you paste it. [Without an app](#without-an-app), clean the clipboard one time with a command in the Terminal app.
}

Text from AI chatbots, like ChatGPT and Claude, can have invisible characters. Text from web pages and PDF documents can have them too. You cannot see them, but they can break the text in other apps.

## With Pure Paste

@Steps {
1. Open [Pure Paste](/pure-paste). Its icon is in the menu bar.
1. Click the icon, choose “Settings…”, and click “Extras”.
1. In “When clearing formatting”, turn on “Remove invisible characters”.
1. Copy the text, and paste it. Pure Paste removed the invisible characters when you copied the text.
}

Pure Paste removes zero-width spaces and joiners, direction marks, line and paragraph separators, and control characters that cause problems. It keeps accents (like “café”), normal spaces, tabs, and new lines. An emoji that is made of more than one emoji, like 👨‍👩‍👧, becomes separate emoji, as the joiner between them is an invisible character too.

Pure Paste cleans the text each time that it clears the formatting. With “Automatically clear formatting” on (the default), it does this when you copy, but not in the apps in the “Exclude” settings. With that setting off, choose “Clear Formatting Now” in its menu. [How to paste without formatting.](guide:paste-without-formatting-mac)

## Without an app

To clean the text on the clipboard one time, copy the text, and run this command in the Terminal app:

```console
pbpaste | perl -CSD -pe 's/[\x{200B}-\x{200D}\x{2060}\x{FEFF}]//g' | pbcopy
```

It removes the zero-width spaces and joiners, and puts the clean text back on the clipboard as plain text. Then paste it.

This is good for one text. Pure Paste does it for each text that you copy, and it removes more types of invisible characters.
