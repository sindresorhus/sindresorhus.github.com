---
title: 'How to Convert a Hex Color to OKLCH or RGB on Mac'
description: 'Paste a Hex color in System Color Picker, and copy it as OKLCH, RGB, HSL, or LCH for your CSS, or use a converter on the web.'
publicationDate: 2026-11-17
topic: 'text-and-images'
apps: [
	'system-color-picker'
]
---

@QuickAnswer {
	Copy the Hex color, like `#FF8000`, open [System Color Picker](/system-color-picker), and press ++Shift+Command+V++ to paste it. Then press ++Shift+Command+O++ to copy it as OKLCH, or ++Shift+Command+R++ to copy it as RGB. [Without an app](#without-an-app), use a converter on the web, like [oklch.com](https://oklch.com).
}

## With System Color Picker

@Steps {
1. Copy the Hex color, like from your CSS or a design app.
1. Open [System Color Picker](/system-color-picker), and press ++Shift+Command+V++. Or type the color in the first field (Hex).
1. Click the copy button next to the format that you want, like “OKLCH”. Or press its shortcut, like ++Shift+Command+O++ for OKLCH.
}

You can also paste a color in HSL, RGB, OKLCH, LCH, or CMYK, and the fields show it in the other formats. The app copies OKLCH as a CSS color, like `oklch(…)`, and RGB as `rgb(255 128 0)`. For the older syntax with commas, like `rgb(255, 128, 0)`, turn on “Use legacy syntax for HSL and RGB” in the “Color” settings.

@Tips {
- To show more formats in the window, like LCH or CMYK, choose them in “Shown color formats” in the “Color” settings. All formats are also in the “Color” menu.
- The app is also a color picker: press ++Command+P++, and click a color anywhere on the screen. [How to pick a color from the screen.](guide:pick-color-from-screen-mac)
}

## Without an app

A converter on the web, like [oklch.com](https://oklch.com), shows a Hex color as OKLCH and RGB. Paste the color, and copy the value that you need.

For Hex to RGB, each pair of characters is a number from 0 to 255 in base 16: `#FF8000` is `FF` (255), `80` (128), and `00` (0), so `rgb(255 128 0)`. OKLCH needs a long calculation, so use a converter or an app for it.
