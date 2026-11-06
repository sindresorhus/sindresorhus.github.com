---
title: 'How to Use Global Variables in Shortcuts on iPhone and Mac'
description: 'A variable in Shortcuts is gone when the shortcut ends. The free Actions app adds global variables that all your shortcuts and devices share.'
publicationDate: 2026-11-11
topic: 'iphone'
apps: [
	'actions'
]
---

@QuickAnswer {
	The Shortcuts app has no global variables: a variable lives only while its shortcut runs. The free [Actions](../apps/actions/index.md) app adds “Global Variable” actions, which save a text, a number, or a true or false value under a name. Any shortcut can read it later, also on your other devices.
}

## With Actions

@Steps {
1. Install [Actions](../apps/actions/index.md), and open it once.
1. In a shortcut, add the “Global Variable: Set Text” action.
1. In the action, type a name for the variable, like `lastRun`, and the text to save, or choose a variable of the shortcut.
1. In the shortcut that needs the value, add the “Global Variable: Get Text” action, and type the same name.
}

There are also actions for numbers (“Global Variable: Set Number” and “Global Variable: Get Number”) and for true or false values (“Global Variable: Set Boolean” and “Global Variable: Get Boolean”). “Global Variable: Delete” removes a variable, and “Global Variable: Get All” gives all of them.

@Tips {
- Use a number as a counter, like how many times a shortcut ran today.
- Use a true or false value as a switch that one shortcut sets and an automation reads, like “at home”.
- To save several values under one name, save a dictionary as text, and give the result of “Global Variable: Get Text” to the “Get Dictionary from Input” action.
}

The variables sync with iCloud between your devices. They are for small values: at most 1000 variables and 1 MB in total. For large data, save a file.

## Without an app

Shortcuts can save a value in a file, which works like a global variable:

@Steps {
1. To save the value, add the “Save File” action. Turn off “Ask Where to Save”, choose a folder, like the Shortcuts folder of iCloud Drive, write a path, like `lastRun.txt`, and turn on “Overwrite If File Exists”.
1. To read the value, add the “Get File from Folder” action with the same folder and path, and then the “Get Text from Input” action.
}

This needs more actions for each value, and a number or a true or false value comes back as text. It is fine for one or two values. The actions of Actions are shorter, and keep the type of the value.
