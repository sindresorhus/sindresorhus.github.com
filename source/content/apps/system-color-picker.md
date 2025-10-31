---
title: System Color Picker
subtitle: The familiar color picker supercharged
pubDate: 2021-05-01
platforms:
  - macOS
isMenuBarApp: true
appStoreId: 1545870783
hasSentry: true
forceHasIosAppIcon: true
olderMacOSVersions:
  - '11'
  - '12'
  - '13'
  - '14'
feedbackNote: |
  ## On macOS 26, there is a bug with the color sampler where it does not always pick the color you want. The app uses the system color sampler and has no control over how it works. Apple will need to fix this.

  Note that the app wraps the macOS color picker as an app and adds some features. I have no control over how most things work though, like the tabs, color palettes, etc. Bugs with these must be fixed by macOS, not me. To see how it differs: select an image in Finder, open Quick Look, click the markup button, click the color button, and then click "Show Colors".
---

#### Features

- Palettes
- Recently picked colors
- Quickly copy, paste, and convert colors in Hex, HSL, RGB, Unit RGB (0-1), OKLCH, LCH format
- Show as a normal app or in the menu bar
- Pick a color or toggle the window from anywhere with a global keyboard shortcut
- Make the window stay on top of all other windows
- Launch it at login (when in the menu bar)
- Hide menu bar icon
- Shortcuts support
- Import [Simple Color Palette](https://simplecolorpalette.com) and Adobe Swatch Exchange (ASE) palettes

---

*You may also like my [Simple Color Palette](/simple-color-palette) app.*

---

## Tips

- Press the <kbd>Space</kbd> key while using the color sampler to show the RGB values. The color sampler is a system component and it can unfortunately not show other kinds of color values.
- Press the <kbd>Option</kbd> key when copying the Hex color to invert whether to include `#`.
- Press the <kbd>Shift</kbd> key while selecting a color using the color sampler to prevent it from disappearing after your selection.

### Keyboard shortcuts

You can use the following keyboard shortcuts in the app:

- Pick color: <kbd>Command</kbd> <kbd>p</kbd>
- Copy as Hex: <kbd>Shift</kbd> <kbd>Command</kbd> <kbd>h</kbd>
- Copy as HSL: <kbd>Shift</kbd> <kbd>Command</kbd> <kbd>s</kbd>
- Copy as RGB: <kbd>Shift</kbd> <kbd>Command</kbd> <kbd>r</kbd>
- Copy as Unit RGB: <kbd>Shift</kbd> <kbd>Command</kbd> <kbd>u</kbd>
- Copy as OKLCH: <kbd>Shift</kbd> <kbd>Command</kbd> <kbd>o</kbd>
- Copy as LCH: <kbd>Shift</kbd> <kbd>Command</kbd> <kbd>l</kbd>
- Paste color: <kbd>Shift</kbd> <kbd>Command</kbd> <kbd>v</kbd> *(In the format Hex, HSL, RGB, Unit RGB, OKLCH, or LCH)*
- Reset opacity: <kbd>Control</kbd> <kbd>Shift</kbd> <kbd>o</kbd>

#### Switch between picker tabs

You can quickly switch between different color picker tabs:

- Next tab: <kbd>Control</kbd> <kbd>Tab</kbd>
- Previous tab: <kbd>Shift</kbd> <kbd>Control</kbd> <kbd>Tab</kbd>
- Wheel: <kbd>Control</kbd> <kbd>1</kbd>
- Sliders: <kbd>Control</kbd> <kbd>2</kbd>
- Color Palettes: <kbd>Control</kbd> <kbd>3</kbd>
- Image Palettes: <kbd>Control</kbd> <kbd>4</kbd>
- Pencils: <kbd>Control</kbd> <kbd>5</kbd>
- Extensions: <kbd>Control</kbd> <kbd>6</kbd>-<kbd>9</kbd> *(if installed)*

### Plugins

The built-in color picker supports plugins:

- [Skala Color](https://bjango.com/mac/skalacolor/)
- [Pro Picker](https://formulae.brew.sh/cask/colorpicker-propicker)
- [Material Design](https://github.com/johnyanarella/MaterialDesignColorPicker)
- [Color Picker Plus](https://github.com/viktorstrate/color-picker-plus)

## Frequently Asked Questions

#### The app does not show up in the menu bar

[Try this](/apps/faq#app-not-showing-in-menu-bar)

#### Can the color sampler show Hex values?

No. The color sampler in the app is provided by macOS and only supports showing RGB values when you press the <kbd>Space</kbd> key. To show Hex (or other formats) directly in the sampler would require a completely custom sampler, which in turn would need extra system permissions like “Screen Recording”. For now, the fastest workflow is to pick a color with the sampler and then copy it in Hex format from the app.

#### What is OKLCH color?

[It's a more human-friendly color format.](https://evilmartians.com/chronicles/oklch-in-css-why-quit-rgb-hsl) Prefer this format.

#### How is OKLCH better than LCH?

[OKLCH](https://evilmartians.com/chronicles/oklch-in-css-why-quit-rgb-hsl) improves upon [LCH](https://lea.verou.me/2020/04/lch-colors-in-css-what-why-and-how/) by providing more accurate and consistent colors, particularly in very bright or very saturated areas.

#### What is Unit RGB?

It represents RGB values in the range 0-1 instead of 0-255. This format is commonly used for programming (SwiftUI, AppKit, UIKit, etc.) and other graphics programming contexts. For example, `0.5, 0.5, 0.5` in [Unit RGB](https://rgbcolorpicker.com/0-1) is equivalent to `rgb(128, 128, 128)` in standard RGB. It accepts values in the format `0.1, 0.1, 0.1` and `0.1 0.1 0.1`, including with opacity `0.1, 0.1, 0.1, 0.5`.

#### The color changes if I copy and then paste it

That is because the default color space in the picker is [Display P3](https://en.wikipedia.org/wiki/DCI-P3), which is [part of CSS Color 4](https://drafts.csswg.org/css-color-4/#valdef-color-display-p3), but the color space used for the legacy CSS color formats is [sRGB](https://en.wikipedia.org/wiki/SRGB) (browsers are starting to [handle color spaces](https://css-tricks.com/the-expanding-gamut-of-color-on-the-web/) but they are not all there yet).

#### How do I clear the list of recently picked colors?

In the main app window, click the clock icon in the middle toolbar.

#### How do I use palettes?

You can manage palettes by selecting the third tab in the window toolbar.

The fastest way to add a color to a palette is to paste a Hex color value into the app and then click the `+` button in the palette. You can also drag and drop a color into the palette from anywhere.

Palettes can be accessed both from the app and the menu bar icon (if enabled). You can even access them in other apps that use the system color picker.

You can find palettes on [Coolors](https://coolors.co/palettes/trending). Download the ASE palette type, right-click the file, and select “Open In › Color Picker”.

#### How can I remove a color in a palette or swatch?

Select the color and press the <kbd>Delete</kbd> key or drag and drop the color onto the trash icon in the Dock.

#### How can I remove all the swatch colors at once?

Unfortunately, this is not possible as swatches are managed by macOS. You will need to delete them individually.

#### How can I change the color space?

Right-click the color wheel. You want to select “Display P3” if you use LCH or “sRGB” if you use Hex, HSL, or RGB.

Note that the HSL and RGB formats will always be clamped to [sRGB](https://en.wikipedia.org/wiki/SRGB) color space.

#### Can you support `SwiftUI.Color` / `UIColor` / `NSColor` formats?

The best practice is to use [Asset Catalog for colors](https://devblog.xero.com/managing-ui-colours-with-ios-11-asset-catalogs-16500ba48205) instead of hard-coding the values in code. If you really want to hard-code colors, the [Skala color picker plugin](https://bjango.com/mac/skalacolor/) supports `UIColor` and `NSColor`.

#### Why does the OKLCH chroma value differ from other sources?

The app displays the OKLCH chroma value as a percentage instead of an absolute value for better user-friendliness. For example, `oklch(70% 25% 135)` in the app corresponds to `oklch(70% 0.1 135)` on [oklch.com](https://oklch.com). Both are correct: the percentage form (0-100%) and the decimal form (0-0.4) are standard ways to express [OKLCH chroma](https://developer.mozilla.org/en-US/docs/Web/CSS/color_value/oklch#c).

#### How can I export color palettes?

1. Open Finder
1. Press <kbd>Command</kbd> + <kbd>Shift</kbd> + <kbd>G</kbd>
1. Enter `~/Library/Colors`
1. Copy the desired palette files

#### How can I export swatches?

1. Go to the color palettes folder (see above)
1. Copy `NSColorPanelSwatches.plist`

This file is not viewable or editable. It can only be used for backup or transfer between Macs.

#### Can I contribute localizations?

I don't plan to localize the app.

#### [More FAQs…](/apps/faq)

## Scripting

You can use the “Sample Color from Screen” action for Shortcuts to sample color from the screen and then do something with it.

Tip: You can [run shortcuts from the command-line](https://support.apple.com/guide/shortcuts-mac/run-shortcuts-from-the-command-line-apd455c82f02/mac).

## Older versions

- [2.0.3](https://github.com/sindresorhus/System-Color-Picker/releases/download/older-releases/Color.Picker.2.0.3.-.macOS.14.zip) for macOS 14+
- [1.15.0](https://github.com/sindresorhus/System-Color-Picker/releases/download/older-releases/Color.Picker.1.15.0.-.macOS.13.zip) for macOS 13+
- [1.12.1](https://github.com/sindresorhus/System-Color-Picker/releases/download/older-releases/Color.Picker.1.12.1.-.macOS.12.zip) for macOS 12+
- [1.9.6](https://github.com/sindresorhus/System-Color-Picker/releases/download/older-releases/Color.Picker.1.9.6.-.macOS.11.zip) for macOS 11+

## Non-App Store Version

A special macOS version for users that cannot access the App Store. It won't receive automatic updates. I will update it here once a year.

[Download](https://www.dropbox.com/scl/fi/2lvdt09widz0p3jzfrwd8/Color-Picker-2.1.0-1740424285.zip?rlkey=yuzrr4abjfty60oscd3pcdyvc&raw=1) *(2.1.0 · macOS 15+)*
