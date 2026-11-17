---
title: 'How to Check if Silent Mode Is On in Shortcuts on iPhone'
description: 'Find out in a shortcut if your iPhone is in Silent Mode with the free Actions app, like to play a sound only when the ringer is on.'
publicationDate: 2026-11-21
topic: 'shortcuts'
apps: [
	'actions'
]
---

@QuickAnswer {
	Add the “Is Silent Mode On” action of the free [Actions](/actions) app, and check its result in an “If” action. [Without an app](#without-an-app), a shortcut cannot see if Silent Mode is on: the Shortcuts app has no action that checks it.
}

## With Actions

@Steps {
1. Install [Actions](/actions), and open it once.
1. In your shortcut, add the [“Is Silent Mode On”](/actions#:~:text=Is%20Silent%20Mode%20On) action of Actions.
1. Add an “If” action below it that checks if the result is true.
1. Put the actions for when Silent Mode is on in the “If” part, and the other actions in the “Otherwise” part.
}

For example, a shortcut can show a notification in Silent Mode, and play a sound when the ringer is on.

The action plays a short sound that you cannot hear, and checks if iOS skipped it. So it also returns true while Voice Memos records, and while the Camera app is open, when Silent Mode is off. The action is for iPhone and iPad. It does not work on Mac.

## Without an app

A shortcut cannot check Silent Mode without an app. If you only want Silent Mode on at some times, like at night, add the Silent Mode filter to a Focus. The Focus then sets Silent Mode, and you do not need to check it.
