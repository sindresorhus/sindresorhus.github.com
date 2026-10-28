---
title: 'How to Quit All Apps on Mac at Once'
description: 'Quit all open apps with one click or a keyboard shortcut in Supercharge, or with the Quit App action of the Shortcuts app.'
publicationDate: 2026-10-31
topic: 'mac'
apps: [
	'supercharge'
]
---

@QuickAnswer {
	Click [Supercharge](../apps/supercharge/index.md) in the menu bar, and choose “Quit All Apps”. Without an app, make a shortcut in the Shortcuts app with the “Quit App” action, and set it to “All Apps”.
}

## With Supercharge

@Steps {
1. Open [Supercharge](../apps/supercharge/index.md), and give it the access that it asks for in [“Device Control and Data Access”](/apps/faq#device-control-access).
1. Click its icon in the menu bar, and choose “Quit All Apps”.
}

The apps quit like when you press ++Command+Q++, so an app with changes that are not saved asks you to save them. Supercharge also closes all Finder windows. It does not quit menu bar apps.

“Quit All Apps Except Frontmost”, in the same menu, keeps the app that you use now open. To set a keyboard shortcut, or to choose apps that must stay open, open the Supercharge settings, click “Shortcuts”, and go to “Quit all apps”.

## Without an app

macOS has no command to quit all apps. Make a shortcut:

@Steps {
1. Open the Shortcuts app, and click the add button to make a new shortcut.
1. Add the “Quit App” action. In the action, click “App”, and choose “All Apps”.
1. To keep some apps open, choose them in the “except” field of the action.
1. Click the run button. Or choose a keyboard shortcut for it in the details of the shortcut.
}

You can also quit each app from the Dock: right-click its icon, and choose “Quit”. The Shortcuts way is good when you already use Shortcuts. Supercharge is faster to set up, and has the action in the menu bar.
