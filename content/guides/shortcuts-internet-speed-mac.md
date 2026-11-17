---
title: 'How to Test Your Internet Speed in Shortcuts on Mac'
description: 'Get the download speed, the upload speed, and the ping in a shortcut with the free Speediness app, like to log your speed each day, or with a shell command.'
publicationDate: 2026-11-23
topic: 'shortcuts'
apps: [
	'speediness'
]
---

@QuickAnswer {
	Add the “Get Internet Speed” action of the free [Speediness](/speediness) app to a shortcut. It gives the download speed and the upload speed in Mbps, and the ping in milliseconds. [Without an app](#without-an-app), run `networkQuality -c` in a “Run Shell Script” action, and read the values from its JSON.
}

## With Speediness

@Steps {
1. Install [Speediness](/speediness), and open it one time.
1. In the Shortcuts app, make a new shortcut, and add the “Get Internet Speed” action of Speediness.
1. Add an action that uses the result, like “Show Notification”. Click the variable of the result, and choose a value, like “Download Speed (Mbps)”, “Upload Speed (Mbps)”, or “Ping (Milliseconds)”.
1. Run the shortcut. It shows the result when the test is done.
}

The result also has the responsiveness (RPM) and the name of the Wi-Fi network. Turn on “Add to History” in the action to see the test in the history of Speediness too.

@Tips {
- To log your speed, add “Append to Text File” after the action, and run the shortcut each day with a “Time of Day” automation. On macOS 26 and later, the Shortcuts app on Mac has automations. <source:https://support.apple.com/125148>
- To test the download and the upload one after the other, like other speed tests, turn on “Run Tests Sequentially”.
- To test without Shortcuts, open Speediness. [How to check your internet speed.](guide:check-internet-speed-mac)
}

## Without an app

macOS has the `networkQuality` command, which Speediness also uses:

@Steps {
1. Add the “Run Shell Script” action, and type `networkQuality -c`. The result is JSON.
1. Add the “Get Dictionary from Input” action.
1. Add the “Get Dictionary Value” action, and get the value for the key `dl_throughput`, the download speed. `ul_throughput` is the upload speed.
1. Divide the value by 1,000,000 with the “Calculate” action. The value is in bits per second, so this gives Mbps.
}

A script needs “Allow Running Scripts”: choose “Shortcuts › Settings”, click “Advanced”, and turn it on. This works, but it needs more actions, and the values are not named in Shortcuts. The action of Speediness gives each value with its name.
