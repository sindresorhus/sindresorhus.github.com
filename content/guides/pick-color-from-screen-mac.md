---
title: 'How to Pick a Color from the Screen on Mac'
description: 'Use System Color Picker to pick a color from anywhere with a keyboard shortcut and copy it as Hex, or use the built-in Digital Color Meter app.'
publicationDate: 2026-10-29
topic: 'text-images-and-sound'
apps: [
	'system-color-picker'
]
screenshot: {
	number: 1
	description: 'The color picker of System Color Picker with the color in Hex, HSL, and RGB'
}
---

@QuickAnswer {
	In [System Color Picker](../apps/system-color-picker/index.md), press ++Command+P++, click the color, and press ++Shift+Command+H++ to copy it as Hex. Without an app, open Digital Color Meter, choose “View › Display Values › as Hexadecimal”, move the pointer to the color, and press ++Shift+Command+C++.
}

## With System Color Picker

@Steps {
1. Open [System Color Picker](../apps/system-color-picker/index.md).
1. Click the eyedropper button, or press ++Command+P++. The color sampler opens.
1. Move the sampler to the color, and click.
1. Press ++Shift+Command+H++ to copy the color as Hex. Or click the copy button next to the format that you want, like HSL, RGB, or OKLCH.
}

To pick a color without opening the window first, set a keyboard shortcut for “Pick color” in the “Shortcuts” settings. It has no shortcut by default. Then turn on “Copy color in preferred format after picking” in the “General” settings. The app then copies the color each time you pick one. The preferred format is Hex by default, and you can change it in the “Color” settings.

@Tips {
- Press ++Space++ while you use the color sampler to show the RGB values.
- Hold ++Shift++ when you click a color to keep the color sampler open, so you can pick more colors.
- Press ++Option++ when you copy the Hex color to add or remove the `#`. To always add it, turn on “Prefix Hex color with #” in the “Color” settings.
}

## Without an app

Digital Color Meter is in the Utilities folder of Applications. It shows the color of the pixels below the pointer.

@Steps {
1. Open Digital Color Meter.
1. Choose “View › Display Values › as Hexadecimal”. This works for the RGB color spaces, like “Display in sRGB”.
1. Move the pointer to the color. To stop the values from changing when you move the pointer, press ++Command+L++ to lock the position.
1. Choose “Color › Copy Color as Text”, or press ++Shift+Command+C++.
}

This is good enough if you only need the Hex or RGB value of a color sometimes. It cannot show or copy other formats, like HSL or OKLCH.
