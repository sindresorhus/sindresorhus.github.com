---
title: 'How to Stop Apple Music from Opening Automatically on Mac'
description: 'Stop the Music app from opening when you press Play on the keyboard or on AirPods, with a setting in Supercharge. macOS has no setting for this.'
publicationDate: 2026-10-31
topic: 'mac'
apps: [
	'supercharge'
]
---

@QuickAnswer {
	In the settings of [Supercharge](../apps/supercharge/index.md), turn on “Prevent Music app from opening”. Then the Play key of the keyboard or of AirPods does not open Music. macOS has no setting for this.
}

## With Supercharge

@Steps {
1. Open [Supercharge](../apps/supercharge/index.md), and give it the access that it asks for in [“Device Control and Data Access”](/apps/faq#device-control-access).
1. Open the Supercharge settings, and click “Tweaks”.
1. In the System section, turn on “Prevent Music app from opening”.
}

By default, “Only when triggered by media keys” is also on, so Supercharge stops Music only when a Play, Pause, or track key opens it. You can still open Music from the Dock or Spotlight. When you turn it off, Supercharge stops Music each time it opens. Then hold ++Shift++ while you open Music to allow it.

To open another player instead, like Spotify, choose it in “Instead launch”.

## Without an app

macOS has no setting to stop this. The Play key goes to the app that played audio last, and when there is no such app, macOS opens Music.

Two things help a little:

- Keep your other player open, and play something in it, so the keys go to it.
- If Music opens when you log in, open “[System Settings › General › Login Items & Extensions](x-apple.systempreferences:com.apple.LoginItems-Settings.extension)”, select Music below “Open at Login”, and click the remove button.

They do not help when you press Play with no other player open, like after you connect AirPods.
