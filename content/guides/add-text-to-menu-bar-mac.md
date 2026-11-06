---
title: 'How to Add Text to the Menu Bar on Mac'
description: 'Show your own text in the Mac menu bar, like the main task of the day, with the free One Thing app.'
publicationDate: 2026-11-06
topic: 'menu-bar'
apps: [
	'one-thing'
]
screenshot: {
	number: 1
	description: 'The text “Finish that difficult email” in the menu bar, with the edit window of One Thing'
}
---

@QuickAnswer {
	Open the free [One Thing](../apps/one-thing/index.md) app, click it in the menu bar, and type your own text, like the main task of the day. macOS cannot show your own text in the menu bar without an app.
}

TextBar of Rich Somerfield showed text in the menu bar, often the output of a script. It needs Rosetta on Apple silicon, and Homebrew disabled it in September 2026 because it fails the security check of macOS. One Thing shows the text that you type or set, like from the clipboard or with a shortcut in the Shortcuts app, but it does not run a script on a timer.

## With One Thing

@Steps {
1. Open [One Thing](../apps/one-thing/index.md). Without text, its icon in the menu bar is a 1 in a circle.
1. Click the icon. A small edit window opens.
1. Type your text. The menu bar shows it as you type. Press ++Return++ to close the window.
}

To change the text, click it again. To clear it, click it while you press ++Shift++.

@Tips {
- In the “Shortcuts” settings, set a keyboard shortcut to open the edit window, to clear the text, or to set the text from the clipboard.
- If the text is long, set “Maximum width” in the “Appearance” settings, as macOS hides menu bar items that do not fit. The “Appearance” settings also have the text size, bold text, and the color.
- Use Markdown for bold, italic, strikethrough, and links.
- To change the text automatically, like a different text each day, use the “Set Text” and “Set Text Color” actions of One Thing in the Shortcuts app.
}

## Without an app

macOS cannot show your own text in the menu bar. The nearest built-in way is a note that stays above the other windows:

@Steps {
1. Open the Stickies app, and type your text in a note.
1. Choose “Window › Float on Top”.
}

The note covers a part of the windows below it.
