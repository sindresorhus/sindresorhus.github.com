---
title: 'How to Open an ASE Color Palette on Mac'
description: 'See the colors of an Adobe Swatch Exchange (.ase) file, and copy their values, with the free Simple Color Palette app.'
publicationDate: 2026-11-06
topic: 'text-images-and-sound'
apps: [
	'simple-color-palette'
]
screenshot: {
	number: 1
	description: 'A palette with five colors and their RGB values in Simple Color Palette'
}
---

@QuickAnswer {
	Drop the `.ase` file on the Dock icon of the free [Simple Color Palette](../apps/simple-color-palette/index.md) app, or choose “File › Import Palettes…” in it. The app shows the colors, and you can copy their values. macOS cannot open ASE files without an app.
}

An ASE file (Adobe Swatch Exchange) is a color palette, like one from Adobe Illustrator, Photoshop, or a palette website like [Coolors](https://coolors.co). macOS has no app that opens it.

## With Simple Color Palette

@Steps {
1. Open [Simple Color Palette](../apps/simple-color-palette/index.md), and choose “File › Import Palettes…”.
1. Select one or more `.ase` files. You can also drop the files on the Dock icon of the app instead.
1. Save the palette. The app converts it to a `.color-palette` file, and opens it.
1. To copy the value of a color, right-click it, and choose a format below “Copy As…”, like RGB or Hex.
}

“File › Open” does not show `.ase` files, as it only opens `.color-palette` files. Use “Import Palettes…” instead.

@Tips {
- To add the colors of an `.ase` file to a palette that is open, drop the file on the window of the palette.
- The app also imports Color List (`.clr`) files, the palettes of the macOS color picker.
- Press ++Space++ on a `.color-palette` file in Finder to see its colors with Quick Look.
}

## Without an app

macOS cannot open ASE files. If you have an Adobe app, like Illustrator or Photoshop, you can load the file in its Swatches panel.
