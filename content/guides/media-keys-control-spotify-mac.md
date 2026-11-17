---
title: 'How to Make the Play Key Control Spotify on Mac'
description: 'The Play key of a Mac controls the app that played audio last, like a video in the browser. Supercharge sends it to Spotify, Music, or Podcasts each time.'
publicationDate: 2026-11-21
topic: 'audio-and-video'
apps: [
	'supercharge'
]
---

@QuickAnswer {
	In the settings of [Supercharge](/supercharge), set “Send media keys to app” to “Spotify”. Then the Play, Next, and Previous keys of the keyboard always control Spotify, also when a video plays in the browser. [Without an app](#without-an-app), macOS sends the keys to the app that played audio last.
}

## With Supercharge

@Steps {
1. Open [Supercharge](/supercharge), and give it the access that it asks for in [“Device Control and Data Access”](/apps/faq#device-control-access).
1. Open the Supercharge settings, and click “Tweaks”.
1. In the “Keyboard” section, set “Send media keys to app” to “Spotify”. You can also choose “Music” or “Podcasts”.
1. Press the Play key. The first time, macOS asks if Supercharge can control Spotify: allow it.
}

When Spotify is not open, the Play key opens it in the background. The keys never go to the browser, so to pause a video, click it or press ++Space++. To get the normal behavior again, choose “System Default”. The menu shows only the apps that are on your Mac, and Supercharge does not support other players.

## Without an app

macOS sends the media keys to the app that played audio last. So after a video in Safari or Chrome, the Play key plays the video, not your music.

To control your player again, play something in it. The keys then go to it, until another app plays audio.

To stop the Play key from opening the Music app, see [how to stop Apple Music from opening](guide:stop-music-opening-mac).
