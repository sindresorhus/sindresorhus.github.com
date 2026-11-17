---
title: 'How to Make a Color Palette on Mac'
description: 'Make a color palette file with names for the colors, like the colors of a brand, with the free Simple Color Palette app, or save colors in the Colors window.'
publicationDate: 2026-11-23
topic: 'text-and-images'
apps: [
	'simple-color-palette'
]
---

@QuickAnswer {
	Open [Simple Color Palette](/simple-color-palette), click the add button, choose a color, give it a name, and click “Add”. Save the palette as a file that you can share. [Without an app](#without-an-app), drag colors to the empty wells at the bottom of the Colors window.
}

## With Simple Color Palette

@Steps {
1. Open [Simple Color Palette](/simple-color-palette), and choose “File › New” (++Command+N++).
1. Click the add button (+) in the toolbar, or press ++Command+Plus++.
1. Choose the color. Type a name, like “Brand Blue”, if you want one.
1. Click “Add”. To add more colors one after the other, press ++Shift+Return++, which keeps the picker open.
1. Press ++Command+S++ to save the palette.
}

The file is a `.color-palette` file, an open format in JSON. Drag a color to change the order, and ++Control++-click a color to edit it or copy it as RGB, OKLCH, or hex. Finder shows a preview of the colors with Quick Look.

@Tips {
- To start from an Adobe Swatch Exchange (`.ase`) file or a color list (`.clr`), drop it on the Dock icon of the app, or choose “File › Import Palettes…”. Simple Color Palette makes a new palette from it. [How to open an ASE file.](guide:open-ase-file-mac)
- Save the palette in iCloud Drive to have it on your iPhone and iPad too.
- The app does not make colors for you. To get ideas, use a palette generator, like Coolors, and import its ASE file.
}

## Without an app

The Colors window of macOS can keep the colors that you use often:

@Steps {
1. In an app, like TextEdit or Pages, press ++Shift+Command+C++ to open the Colors window.
1. Choose a color.
1. Drag the color from the color well on the left of the bottom row to an empty well on the right. <source:https://support.apple.com/guide/mac-help/mchlp1190/mac>
}

The saved colors are in the Colors window of all apps. This is good for a few colors that you use yourself. For named colors, use the Color Palettes tab of the Colors window: it keeps a palette with a name for each color, and can export it as a color list (`.clr`), a format of Apple. For a palette that you share with others, like the colors of a brand, use a palette file.
