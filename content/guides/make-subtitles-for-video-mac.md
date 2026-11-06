---
title: 'How to Make Subtitles for a Video on Mac'
description: 'Make an SRT or WebVTT subtitle file from the speech in a video on your Mac with Aiko, which transcribes 100 languages offline.'
publicationDate: 2026-11-07
topic: 'text-images-and-sound'
apps: [
	'aiko'
]
---

@QuickAnswer {
	Drop the video on the window of [Aiko](../apps/aiko/index.md). When the transcription is done, click the export button in the toolbar, and choose “SRT (Subtitles)”. macOS cannot make a subtitle file from speech: Live Captions only shows captions while the audio plays.
}

## With Aiko

@Steps {
1. Open the settings of [Aiko](../apps/aiko/index.md), and turn on “Optimize for subtitles”. It keeps each subtitle at 84 characters or less.
1. Drop the video on the Aiko window, or click “Import”.
1. Wait while Aiko transcribes. A long video takes some minutes.
1. Click the export button in the toolbar, and choose “SRT (Subtitles)” or “WebVTT (Subtitles)”.
}

Then add the subtitle file in your video editor, or upload it with the video, like on YouTube. Many video players, like IINA and VLC, show the subtitles when the file is next to the video and has the same name, like `Trip.srt` for `Trip.mp4`.

Aiko opens MP4, MOV, and the other video formats of macOS. It finds the language itself, or you can choose it in “Audio language”. To make English subtitles for a video in another language, turn on “Translate to English”. The transcription runs on your Mac, so the video is never uploaded.

## Without an app

macOS has Live Captions, which shows the speech of any app as text while it plays:

@Steps {
1. Open “[System Settings › Accessibility › Live Captions](x-apple.systempreferences:com.apple.Accessibility-Settings.extension)”, and turn on “Live Captions”.
1. Play the video. The captions show in the Live Captions window.
}

Live Captions needs a Mac with Apple silicon, and it is not in all languages, countries, or regions. It cannot save the captions as a subtitle file. You can write an SRT file by hand in a plain text editor: a number, the time, and the text for each subtitle:

```
1
00:00:01,000 --> 00:00:04,000
Welcome to the trip.
```

That is fine for a short clip. For a longer video, Aiko writes the times and the text for you.
