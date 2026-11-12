---
title: 'How to Add a Quote Widget to the iPhone Home Screen'
description: 'Show your favorite quote, or a new quote each day, in a widget on the iPhone Home Screen and Lock Screen with Any Text, or show a note with the Notes widget.'
publicationDate: 2026-11-12
topic: 'iphone'
apps: [
	'any-text'
]
---

@QuickAnswer {
	Write the quote in [Any Text](../apps/any-text/index.md), and add its widget to the Home Screen. For a new quote each day, make a shortcut that picks a random quote and gives it to the “Set Widget Text” action of Any Text, and run it at a time of day. Without an app, the Notes widget can show a note with your quote.
}

## With Any Text

@Steps {
1. Open [Any Text](../apps/any-text/index.md), tap “Widget 1”, and write the quote.
1. Touch and hold the Home Screen until the apps jiggle, tap “Edit”, and tap “Add Widget”.
1. Choose Any Text, choose the widget of “Widget 1” and a size, and tap “Add Widget”.
1. Tap “Done”.
}

You can change the font and the colors of the widget in the app, and make a part of the quote bold or italic with [Markdown](../apps/any-text/index.md#markdown). The same widget also works on the Lock Screen, on Apple Watch, and on the desktop of a Mac.

**A new quote each day**

@Steps {
1. In the Shortcuts app, make a new shortcut, and add the “List” action with your quotes, one in each item.
1. Add “Get Item from List”, and change “First Item” to “Random Item”.
1. Add the “Set Widget Text” action of Any Text. Keep “Widget 1”, and select “Item from List” as the text.
1. Make the shortcut run each day with a “Time of Day” automation, like at 7:00. [Apple’s instructions for automations.](https://support.apple.com/guide/shortcuts/apdfbdbd7123/ios) Then tap “Edit”, then the Info button of the shortcut, tap “Privacy”, and turn on “Allow Running When Locked”, so it runs without asking.
}

iOS can update the widget some minutes later, not at the second that the shortcut runs.

## Without an app

The Notes widget can show one of your notes:

@Steps {
1. Write the quote in a note in the Notes app.
1. Add the Notes widget to the Home Screen like in the steps above, and choose the widget that shows one note.
1. Touch and hold the widget, tap “Edit Widget”, and choose the note.
}

The widget shows the note with the style of Notes, so you cannot change the font or the colors, and it shows the same quote until you change the note.
