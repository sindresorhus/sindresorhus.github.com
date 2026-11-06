---
title: 'How to Require Face ID to Run a Shortcut on iPhone'
description: 'Ask for Face ID before a shortcut does its work, with the Authenticate action of the free Actions app. iOS itself can require Face ID to open an app.'
publicationDate: 2026-11-11
topic: 'iphone'
apps: [
	'actions'
]
---

@QuickAnswer {
	Put the “Authenticate” action of the free [Actions](../apps/actions/index.md) app at the start of the shortcut, and continue only when its result is true. Without an app, iOS can require Face ID to open an app, which protects the app, not one shortcut.
}

## With Actions

@Steps {
1. Install [Actions](../apps/actions/index.md), and open it once.
1. In the Shortcuts app, open your shortcut, and add the “Authenticate” action at the top.
1. Below it, add an “If” action that checks the result of the action, “Is Authenticated”. Put the other actions of your shortcut inside the “If” action.
1. Run the shortcut. The Actions app opens for a moment to show the Face ID prompt, and then the Shortcuts app comes back.
}

The action uses Face ID or Touch ID, or the passcode when they fail, and the result is true or false.

@Tips {
- To go to another place than the Shortcuts app after the prompt, set “Open When Authenticated” to a URL.
- “Timeout (seconds)” gives the result false when nobody answers in time. On iPhone, the prompt always stops after 25 seconds.
- A shortcut that runs in the background cannot go back to the app that you were in. Open that app again from the shortcut.
- A person who can edit the shortcut can remove the action. So this stops a run by accident, or by a person who only taps the shortcut.
}

## Without an app

iOS can require Face ID, Touch ID, or the passcode to open an app:

@Steps {
1. On the Home Screen, touch and hold the app.
1. Tap “Require Face ID”, and tap “Require Face ID” again.
}

[Apple’s instructions.](https://support.apple.com/guide/iphone/iph00f208d05/ios) This locks an app, like the app with the data that your shortcut uses. It is the stronger protection when the app is what you want to protect. The “Authenticate” action is for one shortcut.
