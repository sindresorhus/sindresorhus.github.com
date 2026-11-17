---
title: 'How to Check if iPhone Is Online in Shortcuts'
description: 'Find out in a shortcut if your iPhone can really reach the internet, not only if it is on Wi-Fi, with the free Actions app, and do something only then.'
publicationDate: 2026-11-19
topic: 'shortcuts'
apps: [
	'actions'
]
---

@QuickAnswer {
	Add the “Is Online” action of the free [Actions](/actions) app, and check its result in an “If” action. It tries to connect to Apple, Google, and Cloudflare, so it knows if the internet works, not only if the iPhone is on a network. The Shortcuts app has no action for this.
}

## With Actions

@Steps {
1. Install [Actions](/actions), and open it once.
1. In your shortcut, add the [“Is Online”](/actions#:~:text=Is%20Online) action of Actions.
1. Add an “If” action below it that checks if the result is true.
1. Put the actions that need the internet in the “If” part, and the other actions in the “Otherwise” part.
}

The action is true when one of the three servers answers, and it waits up to 10 seconds for an answer. For example, upload a file only when the iPhone is online, or show a notification when it is not. The action also works on Mac.

To check one server, like your own, use the “Is Host Reachable” or the “Is Web Server Reachable” action.

## Without an app

The “Get Network Details” action gives the name of the Wi-Fi network or the details of the cellular network, but not if the internet works. The iPhone can be on a network without internet, like the Wi-Fi of a hotel before you sign in. A “Wi-Fi” automation runs when the iPhone joins or leaves a network, but it does not check the internet either.
