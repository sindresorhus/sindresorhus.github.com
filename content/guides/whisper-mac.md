---
title: 'How to Use Whisper on Mac'
description: 'Run the Whisper speech recognition model of OpenAI locally on your Mac, with the Aiko app, or with whisper.cpp in Terminal.'
publicationDate: 2026-11-12
topic: 'text-images-and-sound'
apps: [
	'aiko'
]
---

@QuickAnswer {
	[Aiko](../apps/aiko/index.md) is a Mac app that runs Whisper on your Mac: drop an audio or video file on its window, and it writes the text. You do not install Python or download a model. Without an app, install whisper.cpp with Homebrew, download a model, and run `whisper-cli` in Terminal.
}

Whisper is the speech recognition model of OpenAI. It runs on your Mac, without the internet, so your audio is not uploaded.

## With Aiko

@Steps {
1. Open [Aiko](../apps/aiko/index.md), and drop the audio or video file on its window. Aiko transcribes it with Whisper.
1. Click the export button in the toolbar, and choose a format, like “Text” or “SRT (Subtitles)”.
}

Aiko has the large Whisper model in the app on Mac, so it needs no setup. It opens the audio and video formats of macOS, like M4A, MP3, WAV, MP4, and MOV, finds the language itself, and can translate the speech to English.

[More about transcription with Aiko.](transcribe-audio-to-text-mac.md)

## Without an app

[whisper.cpp](https://github.com/ggml-org/whisper.cpp), an open-source version of Whisper that is fast on Apple silicon, runs in Terminal. It needs [Homebrew](https://brew.sh) and FFmpeg:

@Steps {
1. Run `brew install whisper.cpp ffmpeg` in the Terminal app.
1. Download a model file, like `ggml-large-v2.bin`, from [the models of whisper.cpp](https://huggingface.co/ggerganov/whisper.cpp/tree/main).
1. `whisper-cli` reads WAV, MP3, FLAC, and OGG files. Convert other files, like M4A or a video, to a WAV file first: `ffmpeg -i recording.m4a -ar 16000 -ac 1 -c:a pcm_s16le recording.wav`
1. Run `whisper-cli -m ggml-large-v2.bin -f recording.wav`. The text shows in Terminal.
}

This is good for developers and for scripts. For other people, an app is easier, as each file needs the commands, and the result is in Terminal.
