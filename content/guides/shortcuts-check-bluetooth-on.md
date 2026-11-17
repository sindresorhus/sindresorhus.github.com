---
title: 'How to Check if Bluetooth Is On in Shortcuts on iPhone and Mac'
description: 'Get whether Bluetooth is on or off in a shortcut with the free Actions app, and do something only when it is on.'
publicationDate: 2026-11-22
topic: 'shortcuts'
apps: [
	'actions'
]
---

@QuickAnswer {
	Add the “Is Bluetooth On” action of the free [Actions](/actions) app, and check its result in an “If” action. [Without an app](#without-an-app), Shortcuts can turn Bluetooth on or off with “Set Bluetooth”, but it has no action that tells if it is on. On Mac, a “Run Shell Script” action can check it.
}

## With Actions

@Steps {
1. Install [Actions](/actions), and open it once. On iPhone, allow it to use Bluetooth when it asks. The action does not work without this access.
1. In your shortcut, add the [“Is Bluetooth On”](/actions#:~:text=Is%20Bluetooth%20On) action of Actions. It has no options.
1. Add an “If” action below it that checks if the result is true.
1. Put the actions for when Bluetooth is on in the “If” part, and the other actions in the “Otherwise” part.
}

If the action says “No access to Bluetooth”, give the access in “Settings › Apps › Actions” on iPhone, or turn on Actions in “[System Settings › Privacy & Security › Bluetooth](x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Bluetooth)” on Mac.

@Tips {
- To check one device, use “Is Bluetooth Device Connected” with the identifier that “Get Bluetooth Devices” gives.
- To check if your AirPods play the audio of the iPhone, [use “Get Audio Playback Destination”](guide:shortcuts-check-airpods-connected-iphone).
}

## Without an app

On iPhone, the Shortcuts app can change Bluetooth, but it cannot read it:

- The “Set Bluetooth” action turns Bluetooth on or off. If your shortcut needs Bluetooth, add it with “On” before the actions that need it. This is often enough, as it does nothing when Bluetooth is already on.
- The “Bluetooth” automation runs a shortcut when a device that you choose connects or disconnects.

On Mac, a “Run Shell Script” action can read it with this command, which gives 1 when Bluetooth is on and 0 when it is off:

```sh
system_profiler SPBluetoothDataType | grep -c 'State: On' || true
```

A script needs “Allow Running Scripts”: choose “Shortcuts › Settings”, click “Advanced”, and turn it on.

On iPhone, for a shortcut that must do one thing when Bluetooth is on and another when it is off, use the action of Actions.
