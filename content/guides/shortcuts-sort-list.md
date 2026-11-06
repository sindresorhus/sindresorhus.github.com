---
title: 'How to Sort a List in Shortcuts on iPhone and Mac'
description: 'Sort a list of text or numbers in the Shortcuts app, ascending or descending, with the Sort List action of the free Actions app.'
publicationDate: 2026-11-11
topic: 'iphone'
apps: [
	'actions'
]
---

@QuickAnswer {
	Add the “Sort List” action of the free [Actions](../apps/actions/index.md) app after the action that makes the list. It sorts text and numbers, ascending or descending. Without an app, the “Find” and “Filter” actions of Shortcuts, like “Filter Files”, sort what they return.
}

## With Actions

@Steps {
1. Install [Actions](../apps/actions/index.md), and open it once.
1. In your shortcut, add the “Sort List” action below the action that makes the list, and select the list in the action.
1. To sort from the end, change “Ascending” to “Descending”.
1. Expand the action, and choose the sort type: “Natural”, “Localized”, “Localized Case Insensitive”, or “Number”.
}

The result is “Sorted List”. “Natural”, the default, sorts text with numbers correctly, like filenames: “006 Bar” comes before “011 Foo”. “Number” needs a list of only numbers, not text that has numbers in it.

@Tips {
- For a list of dictionaries, use “Sort List of Dictionaries”, which sorts by a key.
- “Reverse List” and “Shuffle List” change the order in other ways.
- If Shortcuts says that it “couldn't convert from Text to NSString”, change the preview of the result to the list view. This is a bug in the Shortcuts app.
- To remove items that are in the list two times, [use the “Remove Duplicates from List” action](shortcuts-remove-duplicates-from-list.md).
}

## Without an app

The “Find” and “Filter” actions of the Shortcuts app have a “Sort by” option for what they return, like the files of “Filter Files”.

If you sort files, photos, or other items that such an action returns, use that. “Sort List” is for a list of text or numbers.
