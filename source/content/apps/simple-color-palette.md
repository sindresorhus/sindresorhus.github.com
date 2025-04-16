---
title: Simple Color Palette
subtitle: Create, view, and edit color palettes
pubDate: 2025-04-12
platforms:
  - macOS
  - iOS
  - visionOS
appStoreId: 6744484427
# olderMacOSVersions:
#   - '15'
---

View, create, and edit color palettes in the [Simple Color Palette](https://github.com/simple-color-palette) format.

The app also provides Quick Look preview and thumbnails for such files.

A color palette is a collection of colors with optional names, essential for designers to maintain consistent branding, create cohesive user interfaces, and share color schemes across projects and teams.

**This is the official app for creating palettes in the Simple Color Palette format. It's intentionally minimal. It's not a palette organizer or palette generator.**

#### Highlights

- Create and edit color palettes in the Simple Color Palette format (`.color-palette`)
- Import Adobe Swatch Exchange (`.ase`) and Color List (`.clr`) files
- Support for [wide gamut colors](https://css-tricks.com/the-expanding-gamut-of-color-on-the-web/)
- Copy colors in multiple formats: RGB, OKLCH, and Hex
- Quick Look preview and thumbnails for color palette files
- Drag and drop support for adding colors and palettes
- Optional color names for better organization
- Support for opacity in colors
- iCloud sync (by storing in iCloud Drive)
- Shortcuts app integration
- Native app
- Less than 3 MB

## Tips

- macOS: Drag and drop a Adobe Swatch Exchange (.ase) or Color List (.clr) file onto the Dock icon to convert it to a Simple Color Palette format. You can also right-click the file in Finder and open with the app.
- iOS: Tap an Adobe Swatch Exchange (.ase) or Color List (.clr) file in the file picker in the app to convert it to Simple Color Palette format.
- macOS: Drop a `.color-palette` file onto the window to add the colors from the dragged palette into the current palette.

## Frequently Asked Questions {#faq}

#### I have a feature request, bug report, or some feedback

Click the feedback button in the app or [send it here.](https://sindresorhus.com/feedback?product=Simple%20Color%20Palette&referrer=Website-FAQ)

#### Is this a palette organizer app?

No. This app is specifically designed for creating and editing color palettes in the Simple Color Palette format. For organizing collections of palettes, use Finder, your preferred file management app, or a dedicated palette organizer app.

#### Why doesn't the app show color values in Hex format by default?

The app supports extended sRGB colors (wide gamut) with values outside the 0-255 range. For example, `-97 197 261`. Hex notation (`#ff69b4`) is limited to standard RGB values and cannot properly represent extended color values. You can optionally enabling showing colors in Hex format, but it won't be shown for wide gamut colors.

#### How can I export palettes to other formats like Adobe Swatch Exchange (ASE)?

The app is focused on the [Simple Color Palette](https://simplecolorpalette.com) format. It doesn't support exporting to other formats.

#### What's the benefit of the Simple Color Palette format over Adobe Swatch Exchange (ASE)?

The Simple Color Palette format is an open JSON-based format that supports wide gamut colors and isn't tied to any specific ecosystem. Unlike ASE, which is a proprietary binary format limited to Adobe products, Simple Color Palette is human-readable, platform-independent, and designed for modern color management needs with support for extended color gamuts.

#### How can I generate a palette? {#generate-palette}

The app is not a palette generator app. You can make palettes with existing colors or colors you choose, but it won't generate nice palettes automatically. You can use a palette generator tool like [Coolors.co](https://coolors.co), download the palette as ASE, and import it into the app.

You can also use my [ChatGPT bot](https://chatgpt.com/g/g-682c8d11e9988191bcc0f2c54cd1fb71-simple-color-palette-generator) to generate palettes with AI.

#### How can I edit a color?

Right-click (macOS) or long-tap (iOS) a color to edit.

#### How can I change the order of colors?

Drag and drop the color to move it to a different position.

#### How can I copy a color’s value?

Right-click (macOS) or long-tap (iOS) a color to copy its value.

#### How can I drag and drop colors between palettes?

Because of a macOS/iOS bug, this is not currently possible.

#### How can I sync palettes between devices?

You can save the palettes to iCloud Drive or any file sharing method. The palettes are just files.

#### How do I import colors from other apps?

You can paste or drop colors from other apps.

#### Why do the color values shown in the app differ from those in the file?

The app shows display RGB values (gamma-corrected) for easier understanding, while the file stores linear RGB values for technical precision. Both represent exactly the same color, just expressed in different formats.

#### Does it support OKLCH?

You can copy colors as OKLCH. Adding color in OKLCH format is planned.

#### What is OKLCH?

[Learn more.](https://evilmartians.com/chronicles/oklch-in-css-why-quit-rgb-hsl)

#### Does it support showing and copying the color as HSL?

No. The app uses [OKLCH](https://evilmartians.com/chronicles/oklch-in-css-why-quit-rgb-hsl) instead, which better matches how humans perceive color differences and makes it easier to create visually harmonious color combinations.

#### Does the app support color spaces other than sRGB?

The Simple Color Palette format stores colors in linear sRGB, which can be converted losslessly to any other RGB color space while supporting extended range values for wide gamut colors.

#### How can I make the window always stay on top on macOS?

Click the “Stay on Top” toggle in the “Window” menu.

#### Can I use the palettes in my own apps?

Yes. The format is [open source](https://github.com/simple-color-palette/spec) and has a [Swift implementation](https://github.com/simple-color-palette/SimpleColorPaletteSwift) available.

#### How can I compare two palettes side by side?

Just open both palettes and move the windows next to each other.

#### Does it support gradients?

No, only flat colors are supported.

#### [More FAQs…](/apps/faq)

<!-- ## Older Versions

- []() for macOS 15+ -->

## Non-App Store Version

A special version for users that cannot access the App Store. It won't receive automatic updates. I will update it here once a year.

[Download](https://www.dropbox.com/scl/fi/6kc3f73j2msm9sygpibnq/Simple-Color-Palette-1.0.1-1744738760.zip?rlkey=9gbm58b8hy23m6rde40a7bomy&raw=1) *(1.0.1)*

*Requires macOS 15 or later*
