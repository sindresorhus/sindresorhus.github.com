---
title: 'How to Filter a List in Shortcuts on iPhone and Mac'
description: 'Keep or remove the items of a list of text that contain, begin with, or match a text, with the Filter List action of the free Actions app.'
publicationDate: 2026-11-22
topic: 'shortcuts'
apps: [
	'actions'
]
---

@QuickAnswer {
	Add the “Filter List” action of the free [Actions](/actions) app, choose “Keep” or “Remove”, a condition, like “contains”, and the text. [Without an app](#without-an-app), loop over the list with “Repeat with Each”, and add the items that match to a variable.
}

## With Actions

@Steps {
1. Install [Actions](/actions), and open it once.
1. In your shortcut, add the [“Filter List”](/actions#:~:text=Filter%20List) action below the action that makes the list, and select the list in the action.
1. Choose “Keep” to keep the items that match, or “Remove” to remove them.
1. Choose the condition: “contains”, “begins with”, “ends with”, “is”, or “matches regex”. Then type the text.
}

The result is “Filtered List”, in the same order as the list. Upper and lower case do not matter, unless you turn on “Case Sensitive”. To keep only the first matches, turn on “Limit”.

@Tips {
- The action is for a list of text and numbers. For a list of dictionaries, like the result of a JSON API, use “Filter List of Dictionaries”.
- If Shortcuts says that it “couldn't convert from Text to NSString”, change the preview of the result to the list view. This is a bug in the Shortcuts app.
- To remove the items that are in the list two times, [use “Remove Duplicates from List”](guide:shortcuts-remove-duplicates-from-list).
}

## Without an app

The “Filter” actions of Shortcuts, like “Filter Files”, are only for files, photos, and other content, not for a list of text. Use a loop:

@Steps {
1. Add the “Repeat with Each” action, and select the list.
1. In the loop, add an “If” action. Use “Repeat Item” as the input, choose a condition, like “contains”, and type the text.
1. In the “If” part, add the “Add to Variable” action with “Repeat Item”, and name the variable, like “Filtered”.
1. After “End Repeat”, use the variable.
}

This works, but it is three actions for each filter, and “If” has no condition for a regular expression. For a regular expression, combine the list with “Combine Text”, and use “Match Text”.
