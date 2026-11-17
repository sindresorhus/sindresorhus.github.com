---
title: 'How to Transcribe a Microsoft Teams Recording on Mac'
description: 'Get the text of a Teams meeting recording on your Mac with Aiko, also when nobody turned on the transcript, or let Stream make a transcript.'
publicationDate: 2026-11-18
topic: 'audio-and-video'
apps: [
	'aiko'
]
---

@QuickAnswer {
	Download the recording from the “Shared” tab of the meeting chat in Teams, and drop it on the window of [Aiko](/aiko). Aiko writes the text on your Mac, also when nobody turned on the transcript in the meeting. [Without an app](#without-an-app), Microsoft Stream can make a transcript of the recording in some languages.
}

## With Aiko

@Steps {
1. In Teams, open the chat of the meeting, or the channel for a channel meeting, and select the “Shared” tab. Select the recording, and choose “More options › Download”.
1. Open [Aiko](/aiko), and drop the MP4 file on its window, or click “Import”.
1. Wait while Aiko transcribes. A long meeting takes some minutes.
1. Click the export button in the toolbar, and choose “Text”, “Text with Timestamps”, or “SRT (Subtitles)”.
}

By default, the organizer of the meeting can download the recording. If you cannot download it, ask the organizer for the file. <source:https://support.microsoft.com/en-us/teams/meetings/play-share-and-download-meeting-recordings-in-microsoft-teams>

Aiko uses the Whisper model of OpenAI on your Mac, so the meeting is never uploaded. It finds the language itself. [More about transcribing audio.](guide:transcribe-audio-to-text-mac) Try Aiko free for 14 days with [the trial](/aiko#trial).

@Tips {
- For a meeting that nobody recorded, [record the audio of the call](guide:record-call-audio-mac) with Recordia, and then choose “Previous Recording › Transcribe with Aiko” in its menu.
- See also how to transcribe a [Zoom](guide:transcribe-zoom-recording-mac) or [Google Meet](guide:transcribe-google-meet-recording-mac) recording.
}

## Without an app

When someone turns on transcription in the meeting, Teams saves the transcript with the recording. Transcription does not start when the recording starts: it is a separate option. <source:https://support.microsoft.com/en-us/teams/meetings/start-stop-and-find-meeting-recordings-in-microsoft-teams>

For a recording without a transcript, open the recording in your browser, on its player page in Microsoft 365 (Stream), open “Video settings”, and choose “Generate”. It works for a video that you own or can edit, of less than 4 GB and 4 hours, in 28 languages and dialects. <source:https://support.microsoft.com/office/3cb9acb6-05b2-4f59-a50d-7df61123aa20>
