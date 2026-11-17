---
title: 'How to Check if Audio Is Playing in Shortcuts on iPhone'
description: 'Find out in a shortcut if music, a podcast, or other audio plays on your iPhone with the free Actions app, and do something only then.'
publicationDate: 2026-11-18
topic: 'shortcuts'
apps: [
	'actions'
]
---

@QuickAnswer {
	Add the “Is Audio Playing” action of the free [Actions](/actions) app, and check its result in an “If” action. It sees audio from any app, not only the Music app. [Without an app](#without-an-app), the “Get Current Song” action works only for the Music app.
}

## With Actions

@Steps {
1. Install [Actions](/actions), and open it once.
1. In your shortcut, add the [“Is Audio Playing”](/actions#:~:text=Is%20Audio%20Playing) action of Actions.
1. Add an “If” action below it that checks if the result is true.
1. Put the actions for when audio plays in the “If” part, and the other actions in the “Otherwise” part.
}

For example, the shortcut can resume a podcast only when nothing else plays.

The action returns what iOS reports, and iOS is sometimes wrong:

- It returns true while the microphone is on, and for a while after a call ends.
- It returns true when “Sound Recognition” is on in the Accessibility settings.
- It returns false when the audio plays through AirPlay.

The action is for iPhone and iPad. It does not work on Mac.

## Without an app

For the Music app, add the “Get Current Song” action, and an “If” action that checks if its result has any value. The action gets the song that plays in the Music app, so it does not see the audio of other apps, like a podcast app.

If you only want to stop the audio, use the “Play/Pause” action, and set it to “Pause”.
