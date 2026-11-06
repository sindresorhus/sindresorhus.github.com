---
title: 'How to Convert a Video to a GIF on Mac'
description: 'Use the free Gifski app, an alternative to GIF Brewery, or the “Make GIF” action of the Shortcuts app.'
publicationDate: 2026-10-29
topic: 'text-images-and-sound'
apps: [
	'gifski'
]
---

@QuickAnswer {
	Open the video in the free [Gifski](../apps/gifski/index.md) app and click “Convert”. Finder and QuickTime Player cannot make a GIF, but the “Make GIF” action of the built-in Shortcuts app can.
}

GIF Brewery was a popular GIF maker. Gfycat bought it in 2016 and made it free. Gfycat shut down in September 2023, and GIF Brewery is no longer on the Mac App Store.

## With Gifski

@Steps {
1. Open [Gifski](../apps/gifski/index.md), and drop the video on its window, or click “Open”.
1. Trim the video, and set the dimensions, the speed, the frame rate, and the quality. Click “Preview” to see the result.
1. Click “Convert”.
1. Click “Save”.
}

Gifski uses thousands of colors in each frame, so gradients stay smooth. It converts the video formats that macOS supports, like MP4 and MOV. You can also convert from the Share menu, or with the “Convert Video to Animated GIF” action in Shortcuts.

## Without an app

Finder and QuickTime Player cannot export a GIF. Two other tools can do it:

- **Shortcuts:** Make a shortcut with the “Make GIF” action, which makes an animated GIF from the images or the video given to it. It has settings for the time of each frame, the size, and the loops, but not for the quality.
- **ffmpeg:** If you use the Terminal, install [ffmpeg](https://ffmpeg.org) (`brew install ffmpeg`), and run this command. It makes a palette from the video first, which gives better colors:

```console
ffmpeg -i video.mov -vf "fps=15,scale=640:-1:flags=lanczos,split[a][b];[a]palettegen[p];[b][p]paletteuse" video.gif
```
