---
title: 'How to Shuffle a List in Shortcuts on iPhone and Mac'
description: 'Put the items of a list in a random order in the Shortcuts app, or pick a few random items without repeats, with the free Actions app.'
publicationDate: 2026-11-22
topic: 'shortcuts'
apps: [
	'actions'
]
---

@QuickAnswer {
	Add the “Shuffle List” action of the free [Actions](/actions) app after the action that makes the list. [Without an app](#without-an-app), the “Get Item from List” action of Shortcuts can get one random item, and on Mac, a “Run Shell Script” action can shuffle a list of text.
}

## With Actions

@Steps {
1. Install [Actions](/actions), and open it once.
1. In your shortcut, add the [“Shuffle List”](/actions#:~:text=Shuffle%20List) action below the action that makes the list, and select the list in the action. On iPhone, touch and hold the field to choose a variable.
1. To get only some of the items, expand the action, turn on “Limit”, and type the number in “Maximum Results”.
}

The result is “Shuffled List”. It has each item one time, so “Limit” gives random items without repeats, like 3 winners from a list of names. It works with any list, also files and photos.

@Tips {
- If Shortcuts says that it “couldn't convert from Text to NSString”, change the preview of the result to the list view. This is a bug in the Shortcuts app.
- To put the list in the opposite order, use “Reverse List”. To sort it, [use “Sort List”](guide:shortcuts-sort-list).
}

## Without an app

For files and photos, the “Filter Files” and “Find Photos” actions can sort by “Random”. For a list of text, Shortcuts has no action that shuffles it. On Mac, add a “Run Shell Script” action after the list, with the list as its input, and use the command `sort -R`. Its result is the text with the lines in a random order. A script needs “Allow Running Scripts”: choose “Shortcuts › Settings”, click “Advanced”, and turn it on. On iPhone, for one random item, add the “Get Item from List” action, and choose “Random Item”.

To get more random items, you can put “Get Item from List” in a “Repeat” action. But the same item can come more than one time, so this is not good for a draw.
