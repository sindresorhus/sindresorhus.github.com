---
title: Recordia
subtitle: Quickly record audio
description: Record audio directly from the menu bar or with a global keyboard shortcut.
date: 2020-09-02
platforms:
  - macOS
is_paid: true
app_store_app_id: 1529006487
mac_app_store_url: https://apps.apple.com/app/id1529006487
---

**Want to see this app included in [Setapp](https://setapp.com)?** Help make it happen by [requesting it here](https://support.setapp.com/hc/en-us/articles/213780569-Can-I-suggest-an-app-).

<div align="center">
	<a href="https://www.producthunt.com/posts/recordia?utm_source=badge-featured&utm_medium=badge&utm_souce=badge-recordia" target="_blank"><img src="https://api.producthunt.com/widgets/embed-image/v1/featured.svg?post_id=256507&theme=light" alt="Recordia - Simple audio recorder that lives in your macOS menu bar | Product Hunt Embed" style="width: 250px; height: 54px;" width="250" height="54" /></a>
</div>

<br>

### Older versions

- [Last macOS 10.15 compatible version (free)](https://github.com/sindresorhus/meta/files/6538283/Recordia.1.5.1.-.macOS.10.15.zip) *(1.5.1)*

*(This build will not run on newer macOS versions)*

<br>

<h3 id="faq">Frequently Asked Questions</h3>

#### I have a feature request, bug report, or some feedback

[Send it here.](https://sindresorhus.com/feedback/?product=Recordia&referrer=Website-FAQ)

#### The app does not show up in the menu bar

macOS hides menu bar apps when there is no space left in the menu bar. This is a common problem on MacBooks with a notch. Try quitting some menu bar apps to free up space. If this does not solve it, try quitting Bartender if you have it installed.

#### How can I preview the recording when done?

First, ensure the “Show recording in Finder after saving” preference is enabled. When the recording is shown in Finder, press the Space key to preview it.

#### How can I trim the recording when done?

Preview the recording as described above and then click the trim button.

<a id="record-system-audio"></a>
#### How can I record system audio?

Recordia doesn't have a built-in way to record system audio because of App Store restrictions. However, you can achieve it by following the below steps:

1. [Install the BlackHole audio driver](https://github.com/ExistentialAudio/BlackHole#installation-instructions)
2. [Set up a multi-output device](https://github.com/ExistentialAudio/BlackHole/wiki/Multi-Output-Device)
3. Select “BlackHole” as the input device in Recordia

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

#### Where can I find the changelog?

Go [here](https://apps.apple.com/app/id1529006487) and click “Version History”.
