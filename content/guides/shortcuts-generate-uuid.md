---
title: 'How to Generate a UUID in Shortcuts on iPhone and Mac'
description: 'The Shortcuts app has no action that makes a UUID. The free Actions app adds a Generate UUID action. On Mac, a shell script can also make one.'
publicationDate: 2026-11-11
topic: 'iphone'
apps: [
	'actions'
]
---

@QuickAnswer {
	The Shortcuts app has no action that makes a UUID, a unique ID like `E621E1F8-C36C-495A-93FC-0C247A3E6E5F`. The free [Actions](../apps/actions/index.md) app adds the “Generate UUID” action, which works on iPhone, iPad, and Mac. On Mac, the “Run Shell Script” action with `uuidgen` also makes one.
}

## With Actions

@Steps {
1. Install [Actions](../apps/actions/index.md), and open it once.
1. In your shortcut, add the “Generate UUID” action of Actions. It has no options.
1. Use its result, “UUID”, in the next action, like in the name of a file, or as the ID of a new row in a table.
}

Each run gives a new UUID, in capital letters with hyphens.

## Without an app

On Mac, Shortcuts can run the `uuidgen` command of macOS:

@Steps {
1. In your shortcut, add the “Run Shell Script” action.
1. Type `uuidgen` in the action.
1. If the shortcut cannot run the script, choose “Shortcuts › Settings”, click “Advanced”, and turn on “Allow Running Scripts”.
}

The result is the same kind of UUID. This is fine for a shortcut that only runs on your Mac. iPhone and iPad have no “Run Shell Script” action, so a shortcut that must also run there needs the action of Actions.
