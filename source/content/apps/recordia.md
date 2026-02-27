---
title: Recordia
subtitle: Quickly record audio
pubDate: 2020-09-02
platforms:
  - macOS
isMenuBarApp: true
appStoreId: 1529006487
hasSentry: true
olderMacOSVersions:
  - '10.15'
  - '11'
  - '12'
  - '13'
  - '14'
  - '15'
---

Record audio directly from the menu bar or with a global keyboard shortcut.

## Frequently Asked Questions {#faq}

#### I have a feature request, bug report, or some feedback

Click the feedback button in the app or [send it here.](https://sindresorhus.com/feedback?product=Recordia&referrer=Website-FAQ)

#### The app does not show up in the menu bar

[Try this](/apps/faq#app-not-showing-in-menu-bar)

#### How can I preview the recording when done?

First, ensure the “Show recording in Finder after saving” setting is enabled. When the recording is shown in Finder, press the Space key to preview it.

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

#### [More FAQs…](/apps/faq)

## Older Versions

- [2.10.0](https://www.dropbox.com/scl/fi/xnrlepmmosvk4282red8t/Recordia-2.10.0-macOS-15-1769967108.zip?rlkey=l7t9fmf4ixcfy2pfotg6zrjbg&raw=1) for macOS 15+
- [2.9.0](https://github.com/user-attachments/files/18787741/Recordia.2.9.0.-.macOS.14.zip) for macOS 14+
- [2.7.0](https://github.com/sindresorhus/meta/files/13975939/Recordia.2.7.0.-.macOS.13.zip) for macOS 13+
- [2.6.1](https://github.com/sindresorhus/meta/files/11053013/Recordia.2.6.1.-.macOS.12.zip) for macOS 12
- [2.3.0](https://github.com/sindresorhus/meta/files/8798113/Recordia.2.3.0.-.macOS.11.zip) for macOS 11
- [1.5.1](https://github.com/sindresorhus/meta/files/6538283/Recordia.1.5.1.-.macOS.10.15.zip) for macOS 10.15

## Non-App Store Version

A special version for users that cannot access the App Store. It won't receive automatic updates. I will update it here once a year.

[Download](https://www.dropbox.com/scl/fi/4pzfvx3ixiybchnlka327/Recordia-2.11.0-1769966188.zip?rlkey=27gzy58hhao7ih3jrysp3v68w&raw=1) *(2.11.0)*

*Requires macOS 26 or later*
