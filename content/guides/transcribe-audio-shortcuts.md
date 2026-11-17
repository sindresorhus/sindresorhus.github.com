---
title: 'How to Transcribe Audio in Shortcuts'
description: 'Turn an audio or video file into text in a shortcut on iPhone or Mac, with the Transcribe Audio action of Shortcuts or of Aiko for about 100 languages.'
publicationDate: 2026-11-18
topic: 'shortcuts'
apps: [
	'aiko'
]
---

@QuickAnswer {
	Add the “Transcribe Audio” action of the Shortcuts app, and give it an audio file. For about 100 languages, subtitles, or video files, use the “Transcribe Audio” action of [Aiko](/aiko), which runs the Whisper model on your device.
}

## With Aiko

On Mac, the action gives the text to the next action:

@Steps {
1. Install [Aiko](/aiko), and open it once.
1. In your shortcut, get the file, like with “Select File”, and add the “Transcribe Audio in the Background (macOS-only)” action of Aiko.
1. Add the action that uses the text, like “Show Content” or “Copy to Clipboard”.
}

On iPhone and iPad, Aiko must be open while it transcribes, so its action copies the text to the clipboard:

@Steps {
1. In your shortcut, get the file, and add the “Transcribe Audio” action of Aiko.
1. Add the “Wait to Return” action, and then the “Get Clipboard” action. “Get Clipboard” gives the text.
}

Expand the action to see its options: “Language” (Aiko finds it itself by default), “Translate to English”, and “Output Type”, like “Text”, “Text with timestamps”, or “SRT (Subtitles)”.

The action takes audio files and MP4 and MOV videos. It cannot take the result of a Voice Memos action, so save the recording as a file first. To transcribe many files, get [the batch shortcut](/aiko#batch). Try Aiko free for 14 days with [the trial](/aiko#trial).

## Without an app

The Shortcuts app has its own “Transcribe Audio” action on iPhone, iPad, and Mac:

@Steps {
1. In your shortcut, get the audio file, like with “Select File”.
1. Add the “Transcribe Audio” action. Its result is the text.
}

It needs Siri or Dictation to be on. It is free and simple, and for a short recording it can be all you need. Aiko is for about 100 languages, translation to English, subtitles, and video files.
