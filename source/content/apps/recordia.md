---
title: Recordia
subtitle: Quickly record audio
pubDate: 2020-09-02
platforms:
  - macOS
isPaid: true
appStoreId: 1529006487
---

Record audio directly from the menu bar or with a global keyboard shortcut.

<sup>**Want to see this app included in [Setapp](https://setapp.com)?** Help make it happen by [requesting it here](https://www.facebook.com/groups/setapp/posts/1849644978569967/).</sup>

<br>

### Frequently Asked Questions {#faq}

#### I have a feature request, bug report, or some feedback

[Send it here.](https://sindresorhus.com/feedback?product=Recordia&referrer=Website-FAQ)

#### The app does not show up in the menu bar

macOS hides menu bar apps when there is no space left in the menu bar. This is a common problem on MacBooks with a notch. Try quitting some menu bar apps to free up space. If this does not solve it, try quitting Bartender if you have it installed.

#### How can I preview the recording when done?

First, ensure the “Show recording in Finder after saving” preference is enabled. When the recording is shown in Finder, press the Space key to preview it.

#### How can I trim the recording when done?

Preview the recording as described above and then click the trim button.

#### How can I record system audio? {#record-system-audio}

Recordia doesn't have a built-in way to record system audio because of App Store restrictions. However, you can achieve it by following the below steps:

1. [Install the BlackHole audio driver](https://github.com/ExistentialAudio/BlackHole#installation-instructions)
2. [Set up a multi-output device](https://github.com/ExistentialAudio/BlackHole/wiki/Multi-Output-Device)
3. Select “BlackHole” as the input device in Recordia

#### How can I transcribe the audio (speech to text)? {#transcribe}

Recordia does not support transcription, but check out my [Aiko app](/aiko). You can easily share a recording to Aiko after you finish recording.

#### How can I sync recordings to iCloud?

Choose “iCloud Drive” as the output directory.

#### Why 48 kHz and not 44.1 kHz?

48 kHz is the standard for audio in today's video production. It's also the internal production standard for many audio production companies. 44.1 kHz was popularized by music CDs.

#### Why WAV over ALAC/FLAC?

WAV is supported everywhere.

#### Does it do noise reduction?

macOS does some noise reduction by default. For stronger noise reduction, check out [this free app](https://www.utterly.app).

#### Can I use my iPhone as a microphone?

Yes, follow the guide [here](https://www.switchingtomac.com/tutorials/how-to-use-your-iphone-as-a-microphone-on-a-mac/).

#### How can I export, import, sync, or back up the settings?

[See this guide.](https://github.com/sindresorhus/guides/blob/main/backup-app-settings.md)

#### Where can I find the changelog?

Go [here](https://apps.apple.com/app/id1529006487) and click “Version History”.

<br>

### Older Versions

- [2.6.1](https://github.com/sindresorhus/meta/files/11053013/Recordia.2.6.1.-.macOS.12.zip) for macOS 12
- [2.3.0](https://github.com/sindresorhus/meta/files/8798113/Recordia.2.3.0.-.macOS.11.zip) for macOS 11
- [1.5.1](https://github.com/sindresorhus/meta/files/6538283/Recordia.1.5.1.-.macOS.10.15.zip) for macOS 10.15

These are free for everyone but they will not run on newer macOS versions.
