---
title: 'How to Use Whisper on Mac'
description: 'Run the Whisper speech recognition model of OpenAI locally on your Mac, with the Aiko app, or with whisper.cpp in Terminal.'
publicationDate: 2026-11-12
topic: 'audio-and-video'
apps: [
	'aiko'
]
---

@QuickAnswer {
	[Aiko](/aiko) is a Mac app that runs Whisper on your Mac: drop an audio or video file on its window, and it writes the text. You do not install Python or download a model. [Without an app](#without-an-app), install whisper.cpp with Homebrew, download a model, and run `whisper-cli` in Terminal.
}

Whisper is the speech recognition model of OpenAI. It runs on your Mac, without the internet, so your audio is not uploaded.

## With Aiko

@Steps {
1. Open [Aiko](/aiko), and drop the audio or video file on its window. Aiko transcribes it with Whisper.
1. Click the export button in the toolbar, and choose a format, like “Text” or “SRT (Subtitles)”.
}

Aiko has the large Whisper model in the app on Mac, so it needs no setup. It opens the audio and video formats of macOS, like M4A, MP3, WAV, MP4, and MOV, finds the language itself, and can translate the speech to English.

[More about transcription with Aiko.](guide:transcribe-audio-to-text-mac)

## Without an app

[whisper.cpp](https://github.com/ggml-org/whisper.cpp), an open-source version of Whisper that is fast on Apple silicon, runs in Terminal. Install it and FFmpeg with [Homebrew](https://brew.sh):

```console
brew install whisper.cpp ffmpeg
```

Download a model file, like `ggml-large-v2.bin`, from [the models of whisper.cpp](https://huggingface.co/ggerganov/whisper.cpp/tree/main). `whisper-cli` reads WAV, MP3, FLAC, and OGG files, so convert other files, like M4A or a video, to a WAV file first:

```console
ffmpeg -i recording.m4a -ar 16000 -ac 1 -c:a pcm_s16le recording.wav
```

Then transcribe the WAV file. The text shows in Terminal:

```console
whisper-cli -m ggml-large-v2.bin -f recording.wav
```

This is good for developers and for scripts. For other people, an app is easier, as each file needs the commands, and the result is in Terminal.
