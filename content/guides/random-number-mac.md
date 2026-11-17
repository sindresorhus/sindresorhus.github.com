---
title: 'How to Generate a Random Number on Mac'
description: 'Use your Mac as a random number generator: pick a number in a range, like 1 to 100, with the free Randa app, Shortcuts, or Terminal.'
publicationDate: 2026-11-22
topic: 'mac'
apps: [
	'randa'
]
---

@QuickAnswer {
	Open [Randa](/randa), type the minimum and the maximum, like 1 and 100, and press ++Return++ for a number. [Without an app](#without-an-app), use the “Random Number” action in the Shortcuts app, or the `jot` command in Terminal.
}

## With Randa

@Steps {
1. Open [Randa](/randa). Its small window shows the minimum and the maximum, like 1 and 100.
1. Type the minimum and the maximum of your range, like 1 and 6 for a die.
1. Press ++Return++, or click “Generate”. Press it again for the next number.
}

Both the lowest and the highest number can come. To copy the number, press ++Shift+Command+C++. To keep the window above your other windows, like during a game, choose “Window › Stay on Top” (++Control+Command+T++).

@Tips {
- For a yes or no decision, like a coin flip, use 0 and 1.
- To pick from a list, like the winner of a draw, use 1 and the number of items, and take the item at that position.
- To never get the same number two times in a row, turn on “Consecutively unique numbers” in the settings.
}

Randa is free, and also works on iPhone, iPad, Apple Watch, and Apple Vision Pro. On iPhone, see [how to generate a random number on iPhone](guide:random-number-iphone).

## Without an app

**Shortcuts:** Make a shortcut with the “Random Number” action:

@Steps {
1. Open the Shortcuts app, click the add button, and add the “Random Number” action.
1. Set the minimum and the maximum in the action.
1. Add the “Show Content” action, and click the run button.
}

**Terminal:** This command prints a random number from 1 to 100. Change the last two numbers for another range:

```console
jot -r 1 1 100
```

The Shortcuts way works well when you always use the same range. Randa is faster when the range changes.
