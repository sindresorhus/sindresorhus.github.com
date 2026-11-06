---
title: 'How to Remove Duplicates from a List in Shortcuts on iPhone and Mac'
description: 'Remove the duplicate items of a list in the Shortcuts app with one action: Remove Duplicates from List of the free Actions app.'
publicationDate: 2026-11-11
topic: 'iphone'
apps: [
	'actions'
]
---

@QuickAnswer {
	Add the “Remove Duplicates from List” action of the free [Actions](../apps/actions/index.md) app after the action that makes the list. Its result has each item one time. Without an app, you build a loop with the actions of Shortcuts.
}

## With Actions

@Steps {
1. Install [Actions](../apps/actions/index.md), and open it once.
1. In your shortcut, add the “Remove Duplicates from List” action below the action that makes the list.
1. On iPhone, touch and hold the “List” field, and select the variable that has the list. Do not tap the field quickly.
1. Run the shortcut. The result, “Deduplicated List”, has each item one time.
}

@Tips {
- For the lines of a text, use the “Remove Duplicate Lines” action.
- If Shortcuts says that it “couldn't convert from Text to NSString”, change the preview of the result to the list view. This is a bug in the Shortcuts app.
- To put the list in order after that, [use the “Sort List” action](shortcuts-sort-list.md).
}

## Without an app

The Shortcuts app has the “Repeat with Each”, “If”, and “Add to Variable” actions. With them, you can build a loop that goes through the list and adds an item to a new variable only when the variable does not have it yet.

This is more actions, and you must build it again in each shortcut that needs it. For one shortcut with a short list, it can be enough.
