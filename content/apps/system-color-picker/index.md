---
title: 'System Color Picker'
subtitle: 'The familiar color picker supercharged'
description: 'A supercharged macOS color picker. Pick a color from anywhere and copy it as Hex, HSL, RGB, OKLCH, and more. Includes palettes and Shortcuts support.'
publicationDate: 2021-05-01
platforms: [
	'macOS'
]
isPaid: true
isMenuBarApp: true
appStoreID: 1545870783
hasSentry: true
feedbackNames: [
	'Color Picker'
]
olderVersions: [
	{
		version: '2.1.4'
		macOS: '15'
		url: 'https://github.com/sindresorhus/System-Color-Picker/releases/download/older-releases/Color.Picker.2.1.4.-.macOS.15.zip'
	}
	{
		version: '2.0.3'
		macOS: '14'
		url: 'https://github.com/sindresorhus/System-Color-Picker/releases/download/older-releases/Color.Picker.2.0.3.-.macOS.14.zip'
	}
	{
		version: '1.15.0'
		macOS: '13'
		url: 'https://github.com/sindresorhus/System-Color-Picker/releases/download/older-releases/Color.Picker.1.15.0.-.macOS.13.zip'
	}
	{
		version: '1.12.1'
		macOS: '12'
		url: 'https://github.com/sindresorhus/System-Color-Picker/releases/download/older-releases/Color.Picker.1.12.1.-.macOS.12.zip'
	}
	{
		version: '1.9.6'
		macOS: '11'
		url: 'https://github.com/sindresorhus/System-Color-Picker/releases/download/older-releases/Color.Picker.1.9.6.-.macOS.11.zip'
	}
]
pressQuotes: [
	{
		quote: 'At first glance it looks a lot like Apple’s regular color picker, but it adds a handful of extra features that can be very helpful in the daily work of developers and designers.'
		source: 'ifun.de'
		translatedFrom: 'German'
		url: 'https://www.ifun.de/system-color-picker-farben-waehlen-farbwerte-kopieren-173486/'
		year: 2021
	}
]
feedbackNote:
	'''
	**On macOS 26, there is a bug with the color sampler where it does not always pick the color you want. The app uses the system color sampler and has no control over how it works. Apple will need to fix this.**

	Note that the app wraps the macOS color picker as an app and adds some features. I have no control over how most things work though, like the tabs, color palettes, etc. Bugs with these must be fixed by macOS, not me. To see how it differs: select an image in Finder, open Quick Look, click the markup button, click the color button, and then click “Show Colors”.
	'''
---

The macOS color picker as an app, with more features. Pick a color from anywhere on the screen, and copy it as Hex, HSL, RGB, OKLCH, and more.

**Features**

- Palettes
- Recently picked colors
- Quickly copy, paste, and convert colors in Hex, HSL, RGB, Unit RGB (0-1), OKLCH, LCH, and CMYK format
- Show as a normal app or in the menu bar
- Pick a color or toggle the window from anywhere with a global keyboard shortcut
- Make the window stay on top of all other windows
- Copy the color in your preferred format after picking, and quit the app after picking
- Show the color sampler when the window opens
- Show the accessibility name of the color, like “very dark blue”
- Launch it at login (when in the menu bar)
- Hide menu bar icon
- Shortcuts support
- Import [Simple Color Palette](https://simplecolorpalette.com) and Adobe Swatch Exchange (ASE) palettes

> [!TIP]
> You may also like my [Simple Color Palette](/simple-color-palette) app.

## Tips

- Press the ++Space++ key while using the color sampler to show the RGB values. The color sampler is a system component and it can unfortunately not show other kinds of color values.
- Press the ++Option++ key when copying the Hex color to invert whether to include `#`.
- Press the ++Shift++ key while selecting a color using the color sampler to prevent it from disappearing after your selection.

### Keyboard shortcuts

You can use the following keyboard shortcuts in the app:

- Pick color: ++Command+P++
- Copy as Hex: ++Shift+Command+H++
- Copy as HSL: ++Shift+Command+S++
- Copy as RGB: ++Shift+Command+R++
- Copy as Unit RGB: ++Shift+Command+U++
- Copy as OKLCH: ++Shift+Command+O++
- Copy as LCH: ++Shift+Command+L++
- Copy as CMYK: ++Shift+Command+K++
- Paste color: ++Shift+Command+V++ *(In the format Hex, HSL, RGB, Unit RGB, OKLCH, LCH, or CMYK)*
- Reset opacity: ++Control+Shift+O++

#### Switch between picker tabs

You can quickly switch between different color picker tabs:

- Next tab: ++Control+Tab++
- Previous tab: ++Control+Shift+Tab++
- Wheel: ++Control+1++
- Sliders: ++Control+2++
- Color Palettes: ++Control+3++
- Image Palettes: ++Control+4++
- Pencils: ++Control+5++
- Extensions: ++Control+6++-++9++ *(if installed)*

### Plugins

The built-in color picker supports plugins. These plugins are old, and they only work on Intel Macs:

- [Pro Picker](https://formulae.brew.sh/cask/colorpicker-propicker)
- [Material Design](https://github.com/johnyanarella/MaterialDesignColorPicker)
- [Color Picker Plus](https://github.com/viktorstrate/color-picker-plus)

## Frequently Asked Questions {#faq}

### Can the color sampler show Hex values? {#can-the-color-sampler-show-hex-values}

No. The color sampler in the app is provided by macOS and only supports showing RGB values when you press the ++Space++ key. To show Hex (or other formats) directly in the sampler would require a completely custom sampler, which in turn would need extra system permissions like “Screen Recording”. For now, the fastest workflow is to pick a color with the sampler and then copy it in Hex format from the app.

### What is OKLCH color? {#what-is-oklch-color}

[It’s a more human-friendly color format.](https://evilmartians.com/chronicles/oklch-in-css-why-quit-rgb-hsl) Prefer this format.

### How is OKLCH better than LCH? {#how-is-oklch-better-than-lch}

[OKLCH](https://evilmartians.com/chronicles/oklch-in-css-why-quit-rgb-hsl) improves upon [LCH](https://lea.verou.me/2020/04/lch-colors-in-css-what-why-and-how/) by providing more accurate and consistent colors, particularly in very bright or very saturated areas.

### What is Unit RGB? {#what-is-unit-rgb}

It represents RGB values in the range 0-1 instead of 0-255. This format is commonly used for programming (SwiftUI, AppKit, UIKit, etc.) and other graphics programming contexts. For example, `0.5, 0.5, 0.5` in [Unit RGB](https://rgbcolorpicker.com/0-1) is equivalent to `rgb(128, 128, 128)` in standard RGB. It accepts values in the format `0.1, 0.1, 0.1` and `0.1 0.1 0.1`, including with opacity `0.1, 0.1, 0.1, 0.5`.

### Can you support HSB? {#can-you-support-hsb}

You can copy a color as HSB by clicking the `(…)` button in the window and selecting “Copy as HSB”. You can also see live HSB values in the “Sliders” tab by selecting “HSB Sliders”.

HSB is intentionally not one of the main formats. HSB has no CSS syntax, while all the main formats can be pasted directly into CSS. HSL is also easier to reason about: lightness goes from black (0%) through the pure color (50%) to white (100%), so making a tint or shade means changing a single value. In HSB, making a color lighter requires both increasing brightness and decreasing saturation. If you want perceptual control, prefer OKLCH.

### The color changes if I copy and then paste it {#the-color-changes-if-i-copy-and-then-paste-it}

That is because the default color space in the picker is [Display P3](https://en.wikipedia.org/wiki/DCI-P3), which is [part of CSS Color 4](https://drafts.csswg.org/css-color-4/#valdef-color-display-p3), but the color space used for the legacy CSS color formats is [sRGB](https://en.wikipedia.org/wiki/SRGB). A Display P3 color outside of sRGB changes when you copy it as Hex, HSL, or RGB. To keep the color in CSS, copy it as OKLCH or LCH, which all current browsers support.

### How do I clear the list of recently picked colors? {#how-do-i-clear-the-list-of-recently-picked-colors}

In the main app window, click the clock icon in the middle toolbar, and then click “Clear”.

### How do I use palettes? {#how-do-i-use-palettes}

You can manage palettes by selecting the third tab in the window toolbar.

The fastest way to add a color to a palette is to paste a Hex color value into the app and then click the `+` button in the palette. You can also drag and drop a color into the palette from anywhere.

Palettes can be accessed both from the app and the menu bar icon (if enabled). You can even access them in other apps that use the system color picker.

You can find palettes on [Coolors](https://coolors.co/palettes/trending). Download the ASE palette type. Then click the `(…)` button in the window and select “Import Palette…” (also in the “File” menu), or right-click the file in Finder and select “Open With › Color Picker”.

### How can I remove a color in a palette or swatch? {#how-can-i-remove-a-color-in-a-palette-or-swatch}

Select the color and press the ++Delete++ key or drag and drop the color onto the trash icon in the Dock.

### How can I remove all the swatch colors at once? {#how-can-i-remove-all-the-swatch-colors-at-once}

Unfortunately, this is not possible as swatches are managed by macOS. You will need to delete them individually.

### How can I change the color space? {#how-can-i-change-the-color-space}

Right-click the color wheel. You want to select “Display P3” if you use LCH or “sRGB” if you use Hex, HSL, or RGB.

Note that the HSL and RGB formats will always be clamped to [sRGB](https://en.wikipedia.org/wiki/SRGB) color space.

### Can you support `SwiftUI.Color` / `UIColor` / `NSColor` formats? {#can-you-support-swiftuicolor--uicolor--nscolor-formats}

The best practice is to use [Asset Catalog for colors](https://devblog.xero.com/managing-ui-colours-with-ios-11-asset-catalogs-16500ba48205) instead of hard-coding the values in code. If you really want to hard-code colors, [Pinwheel](https://bjango.com/mac/pinwheel/) can export colors as SwiftUI code.

### Why does the OKLCH chroma value differ from other sources? {#why-does-the-oklch-chroma-value-differ-from-other-sources}

The app displays the OKLCH chroma value as a percentage instead of an absolute value for better user-friendliness. For example, `oklch(70% 25% 135)` in the app corresponds to `oklch(70% 0.1 135)` on [oklch.com](https://oklch.com). Both are correct: the percentage form (0-100%) and the decimal form (0-0.4) are standard ways to express [OKLCH chroma](https://developer.mozilla.org/en-US/docs/Web/CSS/color_value/oklch#c).

### How can I export color palettes? {#how-can-i-export-color-palettes}

**[Simple Color Palette](https://simplecolorpalette.com) format**
1. Click the `(…)` button in the window and select “Export Palette › All Palettes…”, or one palette (also in the “File” menu)

**CLR format**
1. Open Finder
1. Press ++Shift+Command+G++
1. Enter `~/Library/Colors`
1. Copy the desired palette files

### How can I export swatches? {#how-can-i-export-swatches}

1. Go to the color palettes folder (see above)
1. Copy `NSColorPanelSwatches.plist`

This file is not viewable or editable. It can only be used for backup or transfer between Macs.

### Why is the app suddenly paid? It used to be free. {#why-is-the-app-suddenly-paid-it-used-to-be-free}

While I love making free apps that are available to anyone, the high volume of support requests became unsustainable. After providing the app for free for 5 years with 376K downloads, I made the decision to make it paid. This isn’t about revenue. It’s about managing my time more effectively by reducing the support burden to a sustainable level.

## Scripting

### URL scheme

The app supports the `system-color-picker:` URL scheme for programmatic control:

- `system-color-picker:pick` - Start the color sampler (eyedropper)
- `system-color-picker:toggle` - Toggle the color picker window

Example:

```sh
open --background 'system-color-picker:pick'
```

This can be used to create custom keyboard shortcuts in tools like [Raycast](https://raycast.com) and [Alfred](https://alfredapp.com).

### Shortcuts

The app has the “Sample Color from Screen”, “Get Random Color”, “Import Palettes”, and “Get All Palettes” actions for Shortcuts. For example, sample a color from the screen and then do something with it.

> [!TIP]
> You can [run shortcuts from the command-line](https://support.apple.com/guide/shortcuts-mac/run-shortcuts-from-the-command-line-apd455c82f02/mac).
