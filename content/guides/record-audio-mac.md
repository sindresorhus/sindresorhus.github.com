---
title: 'How to Record Audio on Mac'
description: 'Record the microphone, the system audio of your Mac, or both, with Recordia, an alternative to Soundflower, or with Voice Memos and QuickTime Player.'
publicationDate: 2026-10-29
topic: 'audio-and-video'
apps: [
	'recordia'
]
---

@QuickAnswer {
	Click [Recordia](/recordia) in the menu bar, choose “Microphone”, “System Audio”, or “Microphone + System Audio”, and choose “Record”. [Without an app](#without-an-app), Voice Memos and QuickTime Player record the microphone, and on macOS 27 or later, a screen recording can include the sound of the Mac.
}

Soundflower was a free audio driver that many people used to record the sound of the Mac. Its last release is 2.0b2 from December 2014, and Homebrew disabled it in November 2025 because it is not maintained. Recordia records the sound of the Mac without a driver. To send the sound of one app to another app, like for a stream, use the free [BlackHole](https://github.com/ExistentialAudio/BlackHole) driver, which is maintained.

## With Recordia

@Steps {
1. Open [Recordia](/recordia). Its icon is in the menu bar.
1. Click the icon, and below “Audio Source”, choose “Microphone”, “System Audio”, or “Microphone + System Audio”. “System Audio” is the sound that plays on your Mac, also called internal audio. “Microphone + System Audio” records both to one file.
1. If you record the microphone, click the icon again, and choose the microphone below “Input Device”.
1. Click the icon again, and choose “Record”.
1. To stop, click the icon, and choose “Stop”. Then choose where to save the recording.
}

Recordia saves an M4A file (AAC, 256 kbps, 48 kHz), which works in most apps. For uncompressed WAV, turn on “Lossless quality” in the settings. [More about the audio format.](/recordia#audio-format) Recording the sound of the Mac needs macOS 26 or later. [How to record system audio.](/recordia#record-system-audio)

@Tips {
- To start and stop a recording from any app, set a keyboard shortcut for “Start/stop recording” in the “Shortcuts” settings.
- To save all recordings in one folder without a question, choose a “Default output folder” in the “Advanced” settings. iCloud Drive is good to sync them to your other devices.
- To record both sides of a call, choose “Microphone + System Audio”. [How to record a Zoom or Google Meet call.](guide:record-call-audio-mac)
- Recordia does not transcribe. To get the text of a recording, use [Aiko](/aiko). When Aiko is installed, click the icon, and choose “Previous Recording › Transcribe with Aiko”. <guide:transcribe-audio-to-text-mac>
}

## Without an app

macOS has four ways to record audio:

- **Voice Memos:** Open Voice Memos, and click the record button. It records the microphone. It can also show a transcript of the recording.
- **Notes:** Open a note, click the attachment button in the toolbar, choose “Record Audio”, and click the record button. Notes shows a transcript while you record, on a Mac with Apple silicon (M1 or later) and in a supported language. <source:https://support.apple.com/guide/notes/apdb5106e334/mac>
- **QuickTime Player:** Choose “File › New Audio Recording”, and click the record button. It records the microphone.
- **Screen recording:** Press ++Shift+Command+5++, choose “Record Entire Screen” or “Record Selected Portion”, and in “Options”, choose a microphone. On macOS 27 or later, also choose “Include System Audio” to record the sound of the Mac. It saves a video, not an audio file. To get only the audio, open the video in QuickTime Player, and choose “File › Export As › Audio Only”.

Voice Memos and QuickTime Player are good for a quick voice memo. They cannot record the sound that plays on your Mac, like a call or a video, and the screen recording gives a video file. Recordia records the sound directly to an audio file, and starts from its menu bar icon, or with a keyboard shortcut that you set in its settings.
