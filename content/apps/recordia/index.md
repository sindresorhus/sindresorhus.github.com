---
title: 'Recordia'
subtitle: 'Quickly record audio'
publicationDate: 2020-09-02
platforms: [
	'macOS'
]
isMenuBarApp: true
appStoreID: 1529006487
hasSentry: true
nonAppStoreVersion: {
	version: '2.11.0'
	macOS: 26
	url: 'https://www.dropbox.com/scl/fi/4pzfvx3ixiybchnlka327/Recordia-2.11.0-1769966188.zip?rlkey=27gzy58hhao7ih3jrysp3v68w&raw=1'
}
sharedQuestions: [
	'suggested-filenames'
	'menu-bar-icons'
]
olderVersions: [
	{
		version: '2.10.0'
		macOS: '15'
		url: 'https://www.dropbox.com/scl/fi/xnrlepmmosvk4282red8t/Recordia-2.10.0-macOS-15-1769967108.zip?rlkey=l7t9fmf4ixcfy2pfotg6zrjbg&raw=1'
	}
	{
		version: '2.9.0'
		macOS: '14'
		url: 'https://github.com/user-attachments/files/18787741/Recordia.2.9.0.-.macOS.14.zip'
	}
	{
		version: '2.7.0'
		macOS: '13'
		url: 'https://github.com/sindresorhus/meta/files/13975939/Recordia.2.7.0.-.macOS.13.zip'
	}
	{
		version: '2.6.1'
		macOS: '12'
		url: 'https://github.com/sindresorhus/meta/files/11053013/Recordia.2.6.1.-.macOS.12.zip'
	}
	{
		version: '2.3.0'
		macOS: '11'
		url: 'https://github.com/sindresorhus/meta/files/8798113/Recordia.2.3.0.-.macOS.11.zip'
	}
	{
		version: '1.5.1'
		macOS: '10.15'
		url: 'https://github.com/sindresorhus/meta/files/6538283/Recordia.1.5.1.-.macOS.10.15.zip'
	}
]
pressQuotes: [
	{
		quote: 'A situation that developer Sindre Sorhus, known to ifun.de readers for Dato and Plash, now addresses with the small menu bar helper Recordia. The recording app, free on the Mac App Store at launch, can be triggered with a global keyboard shortcut, so it is always ready to record voice memos, phone calls, meeting notes, interviews, and more.'
		source: 'ifun.de'
		translatedFrom: 'German'
		url: 'https://www.ifun.de/in-der-mac-menueleiste-recordia-erstellt-schnelle-audioaufnahmen-158963/'
		year: 2020
	}
]
---

Click the menu bar icon and choose “Record”, and you are recording. Recordia records the microphone, the audio playing on your Mac, or both at once.

You can also set a keyboard shortcut in the settings to start and stop recording from any app.

**Features**

- Record the microphone, the audio of your Mac, or both
- Pause and resume a recording
- Listen to the microphone while you record (input monitoring)
- Keyboard shortcuts to start, stop, pause, and resume a recording
- Show the duration in the menu bar while recording
- See the audio level in the menu bar and in the menu while you record
- Set how loud the system audio is, relative to the microphone, when you record both
- Choose the output folder and the format of the filenames
- Copy the recording or show it in Finder when done
- Lossless quality (WAV) as an option
- Shortcuts actions to start, stop, and pause a recording, and to get the previous recording

## Frequently Asked Questions {#faq}

### How can I preview the recording when done? {#how-can-i-preview-the-recording-when-done}

First, ensure the “Show recording in Finder” setting is enabled. When the recording is shown in Finder, press the Space key to preview it.

### How can I trim the recording when done? {#how-can-i-trim-the-recording-when-done}

Preview the recording as described above and then click the trim button.

### How can I record system audio? {#record-system-audio}

In the Recordia menu, under “Audio Source”, choose “System Audio” to capture all audio playing on your Mac, or “Microphone + System Audio” to record both into a single file. When you record both, use the “System audio volume” setting to make the sound of the Mac louder or quieter than your voice.

Recording system audio requires macOS 26 or later. On older versions, you can [install the BlackHole audio driver](https://github.com/ExistentialAudio/BlackHole#installation-instructions), [set up a multi-output device](https://github.com/ExistentialAudio/BlackHole/wiki/Multi-Output-Device), and then select “BlackHole” as the input device in Recordia.

### How can I transcribe the audio (speech to text)? {#transcribe}

Recordia does not support transcription, but check out my [Aiko app](/aiko). When Aiko is installed, choose “Previous Recording › Transcribe with Aiko” in the Recordia menu after you finish recording.

### The app or my Mac crashed while recording. Can I get the recording back? {#recover}

Maybe. Recordia records to a temporary folder first. In the Recordia menu, click “…”, and choose “Recover Recordings…” to show that folder in Finder. Do it soon, as macOS cleans up this folder regularly. A crash can also make the recording corrupt.

### Can it show in the Dock with a window? {#dock-icon}

No. Recordia is a menu bar app: click its icon in the menu bar, or set a keyboard shortcut in the settings to start and stop recording from any app.

### How can I sync recordings to iCloud? {#how-can-i-sync-recordings-to-icloud}

Choose “iCloud Drive” as the output directory.

### Why 48 kHz and not 44.1 kHz? {#why-48-khz-and-not-441-khz}

48 kHz is the standard for audio in today’s video production. It’s also the internal production standard for many audio production companies. 44.1 kHz was popularized by music CDs.

### What audio format does it record in? {#audio-format}

By default, it records M4A (AAC, 256 kbps), which is small and works in most apps. To record WAV (PCM, uncompressed) instead, enable “Lossless quality” in the settings. Both are 48 kHz.

### Why WAV over ALAC/FLAC? {#why-wav-over-alacflac}

WAV is supported everywhere.

### Does it do noise reduction? {#does-it-do-noise-reduction}

macOS does some noise reduction by default. For stronger noise reduction, check out [this free app](https://www.utterly.app).

### Can I use my iPhone as a microphone? {#can-i-use-my-iphone-as-a-microphone}

Yes. With Continuity Camera, your iPhone can be a microphone for your Mac. Keep the iPhone near the Mac, and then select it under “Input Device” in the Recordia menu. See [how to use your iPhone as a microphone](https://support.apple.com/guide/mac-help/mchl77879b8a/mac).
