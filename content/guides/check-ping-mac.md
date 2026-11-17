---
title: 'How to Check Your Ping on Mac'
description: 'See the ping of your internet connection in milliseconds with the free Speediness app, or with the ping command in Terminal.'
publicationDate: 2026-11-18
topic: 'internet-and-network'
apps: [
	'speediness'
]
---

@QuickAnswer {
	Open the free [Speediness](/speediness) app. It tests your connection at once, and shows the ping in milliseconds, with the speed. [Without an app](#without-an-app), run `ping -c 4 apple.com` in the Terminal app, and read the `avg` value.
}

The ping is the time that a small message takes to go to a server and back. A low ping is important for video calls and games. Below 50 ms is good, 50 to 99 ms is OK, and 100 ms or more is high.

## With Speediness

@Steps {
1. Open [Speediness](/speediness). The test starts automatically.
1. When the test is done, read the ping, like “23 ms”. Its color and its level show if it is low (good), medium, or high.
1. To test again, press ++Command+R++.
}

Speediness pings `apple.com` four times after the speed test, and shows the average. The “History” window has a “Ping” column, so you can compare your tests over time.

A game shows the ping to its own server, which can be far away. So the ping in a game can be higher than the ping in Speediness.

## Without an app

The `ping` command of macOS sends messages to a server that you choose. Open the Terminal app, and run:

```console
$ ping -c 4 apple.com
round-trip min/avg/max/stddev = 34.548/44.698/57.250/9.179 ms
```

`-c 4` sends four messages and stops. The last line shows the shortest, the average, and the longest time. The average is your ping. Put another server in place of `apple.com`, like the address of a game server, to test the ping to it. Without `-c 4`, the command continues until you press ++Control+C++.

The `ping` command is the best way to test one server. Speediness shows the ping and the speed together with one click, and keeps a history.

If the ping is good most of the time, but the connection stops now and then, [see when your internet drops](guide:internet-keeps-dropping-mac). On iPhone, see [how to ping a server from iPhone](guide:ping-from-iphone).
