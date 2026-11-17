---
title: 'How to Check the Temperature of Your iPhone'
description: 'iPhone does not show its temperature in degrees, but the free Actions app shows its thermal state, from “Nominal” to “Critical”, so you know if it is too hot.'
publicationDate: 2026-11-19
topic: 'iphone'
apps: [
	'actions'
]
---

@QuickAnswer {
	iOS does not show the temperature of the iPhone in degrees, and apps cannot read it. The closest is the thermal state, which the “Get Device Details (Extended)” action of the free [Actions](/actions) app shows: “Nominal”, “Fair”, “Serious”, or “Critical”. [Without an app](#without-an-app), iOS only tells you when the iPhone is too hot.
}

## With Actions

@Steps {
1. Install [Actions](/actions), and open it once.
1. In the Shortcuts app, make a new shortcut, and add the [“Get Device Details (Extended)”](/actions#:~:text=Get%20Device%20Details%20%28Extended%29) action of Actions.
1. Add the “Show Content” action. Tap “Device Details” in it, and choose “Thermal State”.
1. Run the shortcut.
}

What the thermal states mean:

- **Nominal:** The temperature is normal.
- **Fair:** The iPhone is a bit warm. This is normal while it charges, or while you play a game or use the camera.
- **Serious:** The iPhone is hot. iOS can make it slower and charge it more slowly.
- **Critical:** The iPhone is too hot. Stop using it, and let it cool down.

## Without an app

iOS has no setting or widget that shows the temperature. When the iPhone gets too hot, it can charge more slowly or stop charging, dim the display, and turn off the flash, and it can show a temperature warning ([Apple’s article](https://support.apple.com/118431)). Apple says to use the iPhone where the air is between 0 and 35 °C (32 to 95 °F).
