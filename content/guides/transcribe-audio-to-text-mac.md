---
title: 'How to Transcribe Audio to Text on Mac'
description: 'Transcribe audio and video files to text or subtitles on your Mac with Aiko, or see the transcript of a recording in Voice Memos.'
publicationDate: 2026-10-29
topic: 'audio-and-video'
apps: [
	'aiko'
]
screenshot: {
	number: 1
	description: 'The transcript of a speech in Aiko'
}
---

@QuickAnswer {
	Drop the audio or video file on the window of [Aiko](/aiko), and it writes the text. It transcribes 100 languages on your Mac, and saves the text as subtitles too. [Without an app](#without-an-app), Voice Memos and Notes show a transcript of the recordings that you make in them.
}

## With Aiko

@Steps {
1. Open [Aiko](/aiko), and drop the audio or video file on its window, or click “Import”. To record now, click “Record”.
1. Wait while Aiko transcribes. A long recording takes some minutes.
1. Click the export button in the toolbar, and choose a format, like “Text”, “Text with Timestamps”, or “SRT (Subtitles)”. Or copy the text.
}

Aiko opens the audio and video formats of macOS, like M4A, MP3, WAV, MP4, and MOV. It uses the [Whisper](guide:whisper-mac) model of OpenAI on your Mac, so your audio is never uploaded. It finds the language itself, or you can choose it in the settings, and it can also translate the speech to English.

@Tips {
- To transcribe a recording of Voice Memos, drag it from Voice Memos to the Aiko window.
- To transcribe a file from Finder, add [the shortcut for Finder](/aiko#finder), ++Control++-click the file, and choose the shortcut in “Quick Actions”. To transcribe many files, use [the batch shortcut](/aiko#batch).
- If the text has no punctuation, write a sentence with punctuation, like `Hello. I like cake.`, in the “Prompt” setting.
}

Aiko is also on iPhone, iPad, and Apple Vision Pro. Try it free for 14 days with [the trial](/aiko#trial).

## Without an app

macOS can transcribe the recordings that you make in some of its apps:

- **Voice Memos:** Record a memo, and click the transcription button to see the text. To copy the text, select it, ++Control++-click it, and choose “Copy”. It needs a Mac with Apple silicon. <guide:transcribe-voice-memo-mac>
- **Notes:** Record audio in a note, and Notes writes a transcript while you record. It needs a Mac with Apple silicon, and the language of the Mac must be a supported one, like English, Spanish, French, German, Japanese, or Chinese.

For an audio file that you already have, the Shortcuts app has a “Transcribe Audio” action. [How to transcribe audio in Shortcuts.](guide:transcribe-audio-shortcuts)

Audio transcription is not available in all countries or regions, and it supports fewer languages than Aiko. It is good for a quick memo in a supported language. For a recorded meeting, like a [Zoom recording](guide:transcribe-zoom-recording-mac), a lecture, or a video, or for [subtitles](guide:make-subtitles-for-video-mac), use Aiko.
