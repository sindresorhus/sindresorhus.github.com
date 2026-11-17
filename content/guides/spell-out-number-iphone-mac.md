---
title: 'How to Write a Number in Words on iPhone and Mac'
description: 'Spell out a number, like 1250 as “one thousand two hundred fifty”, for a check or a contract, in any language, with the free Actions app.'
publicationDate: 2026-11-23
topic: 'shortcuts'
apps: [
	'actions'
]
---

@QuickAnswer {
	Make a shortcut with the “Spell Out Number” action of the free [Actions](/actions) app. It writes a number in words, like 1000 as “one thousand”, in the language of your device or the language that you choose. [Without an app](#without-an-app), on a Mac, the “Run AppleScript” action can do it.
}

## With Actions

@Steps {
1. Install [Actions](/actions), and open it once.
1. In the Shortcuts app, make a new shortcut, and add the “Ask for Input” action. Change its input type to “Number”.
1. Add the [“Spell Out Number”](/actions#:~:text=Spell%20Out%20Number) action of Actions.
1. Optional: expand the action, and choose a language in “Locale”. Without one, it uses the language of your device.
1. Add the “Copy to Clipboard” action.
1. Run the shortcut, type the number, and paste the words where you need them.
}

The action takes whole numbers. For the cents on a check, write them yourself, like “and 50/100”.

## Without an app

On a Mac, the “Run AppleScript” action can spell out a number with the number formatter of macOS:

@Steps {
1. Make a new shortcut, and add the “Ask for Input” action with the input type “Number”.
1. Add the “Run AppleScript” action, and replace its text with the script below.
1. If the shortcut cannot run the script, choose “Shortcuts › Settings”, click “Advanced”, and turn on “Allow Running Scripts”.
}

```applescript
use framework "Foundation"

on run {input, parameters}
	set formatter to current application's NSNumberFormatter's new()
	formatter's setNumberStyle:(current application's NSNumberFormatterSpellOutStyle)
	return (formatter's stringFromNumber:((item 1 of input) as integer)) as text
end run
```

The script uses the language of your Mac, and works only on a Mac. Actions works on iPhone too, and lets you choose the language.
