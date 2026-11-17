---
title: 'How to Convert a Video to a GIF on Mac'
description: 'Convert a video to an animated GIF with the free Gifski app, an alternative to GIF Brewery, or with the “Make GIF” action of the Shortcuts app.'
publicationDate: 2026-10-29
topic: 'audio-and-video'
apps: [
	'gifski'
]
---

@QuickAnswer {
	Open the video in the free [Gifski](/gifski) app and click “Convert”. Finder and QuickTime Player cannot make a GIF, but the “Make GIF” action of the built-in Shortcuts app can.
}

GIF Brewery was a popular GIF maker. Gfycat bought it in 2016 and made it free. Gfycat shut down in September 2023, and GIF Brewery is no longer on the Mac App Store.

## With Gifski

@Steps {
1. Open [Gifski](/gifski), and drop the video on its window, or click “Open”.
1. Trim the video, and set the dimensions, the speed, the frame rate, and the quality. Click “Preview” to see the result.
1. Click “Convert”.
1. Click “Save”.
}

Gifski uses thousands of colors in each frame, so gradients stay smooth. It converts the video formats that macOS supports, like MP4 and MOV. You can also convert from the Share menu, or with the “Convert Video to Animated GIF” action in Shortcuts. To record the screen first, see [how to turn a screen recording into a GIF](guide:screen-recording-to-gif-mac).

## Without an app

Finder and QuickTime Player cannot export a GIF. Two other tools can do it:

- **Shortcuts:** Make a shortcut with the “Make GIF” action, which makes an animated GIF from the images or the video given to it. It has settings for the time of each frame, the size, and the loops, but not for the quality.
- **ffmpeg:** If you use the Terminal, install [ffmpeg](https://ffmpeg.org) with [Homebrew](https://brew.sh), and run these commands. The second one makes a palette from the video first, which gives better colors:

```console
brew install ffmpeg
ffmpeg -i video.mov -vf "fps=15,scale=640:-1:flags=lanczos,split[a][b];[a]palettegen[p];[b][p]paletteuse" video.gif
```
