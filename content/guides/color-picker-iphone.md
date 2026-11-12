---
isDraft: true
title: 'How to Get the Hex Code of a Color in a Photo on iPhone'
description: 'Pick a color in a photo, and get its hex code, like #3A7BD5, with the Pick Color action of Actions in a shortcut, or with the color picker of Markup.'
publicationDate: 2026-11-13
topic: 'shortcuts'
apps: [
	'actions'
]
---

@QuickAnswer {
	Make a shortcut with the “Pick Color” action of [Actions](../apps/actions/index.md), and give it the photo as “Reference Image”. Pick the color with the eyedropper, and the shortcut gets its hex code. Without an app, the color picker of Markup also has an eyedropper.
}

## With Actions

@Steps {
1. In the Shortcuts app, make a new shortcut, and add the “Select Photos” action.
1. Add the “Pick Color” action of [Actions](../apps/actions/index.md). Tap the arrow of the action, and set “Reference Image” to the photos of “Select Photos”.
1. Add the “Copy to Clipboard” action. Tap its input, choose “Picked Color”, and choose “Hex”.
1. Run the shortcut, and choose a photo. The Actions app opens with the photo below a color well.
1. Tap the color well, tap the eyedropper, and drag it to the color in the photo. Tap the checkmark button to go back to Shortcuts.
}

iOS gives the action 25 seconds, so pick the color quickly.

@Tips {
- To get the main colors of a photo without picking, use the “Get Dominant Colors of Image” action.
- Add the shortcut to the share sheet, so you can run it from a photo in the Photos app.
}

## Without an app

@Steps {
1. Open the photo in the Photos app, tap the Edit button, and tap Markup.
1. Tap the color circle, tap the eyedropper, and drag it to the color in the photo.
1. Tap the color circle again, and tap “Sliders”. The hex code is below the sliders.
}

This is enough when you need one color now and then. You do not need to save the change of the photo. The shortcut is faster when you need the code often, and it puts the code on the clipboard.
