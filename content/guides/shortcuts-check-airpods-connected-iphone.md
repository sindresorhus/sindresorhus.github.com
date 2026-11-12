---
title: 'How to Check if AirPods Are Connected in Shortcuts on iPhone'
description: 'Get the device that plays the audio of your iPhone in a shortcut, like your AirPods, with the free Actions app, and do something only when they are connected.'
publicationDate: 2026-11-12
topic: 'shortcuts'
apps: [
	'actions'
]
---

@QuickAnswer {
	Add the “Get Audio Playback Destination” action of the free [Actions](../apps/actions/index.md) app, and check its result in an “If” action, like “contains” `AirPods`. The Shortcuts app has no action that gets the audio output, only an automation that runs when a Bluetooth device connects.
}

## With Actions

@Steps {
1. Install [Actions](../apps/actions/index.md), and open it once.
1. In your shortcut, add the “Get Audio Playback Destination” action of Actions. Its full name is “Get Audio Playback Destination (Does not detect AirPlay devices)”, and it has no options.
1. Add an “If” action below it, choose “contains”, and type `AirPods`.
1. Put the actions for when the AirPods are connected in the “If” part, and the other actions in the “Otherwise” part.
}

The result is the name of the device that plays the audio, like “Anna’s AirPods Pro”. To check one pair of AirPods, use its whole name. When the iPhone plays the audio itself, the result is “iPhone”.

@Tips {
- The action cannot see AirPlay devices, like a HomePod. This is a limit of iOS.
- The action is for iPhone and iPad. It does not work on Mac.
- To change where the audio plays, use the “Change Playback Destination” action of Shortcuts.
}

## Without an app

The Shortcuts app can run a shortcut when the AirPods connect, but it cannot check in a shortcut if they are connected:

@Steps {
1. Make a shortcut with the actions that you want, like to open a podcast app.
1. Add the “Bluetooth” automation trigger to it, and choose your AirPods. [Apple’s instructions for automations.](https://support.apple.com/guide/shortcuts/apdfbdbd7123/ios)
}

This is good to do something each time the AirPods connect. For a shortcut that must do one thing with AirPods and another without them, use the action of Actions.
