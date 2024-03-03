---
title: Speediness
subtitle: Check your internet speed
pubDate: 2021-11-23
platforms:
  - macOS
appStoreId: 1596706466
olderMacOSVersions:
  - '12'
  - '13'
---

<br>

### Tips

#### Show the current internet speed in the menu bar {#menu-bar-output}

<img src="https://github.com/sindresorhus/meta/assets/170270/a7ffaf8f-6fb0-4c90-822f-446ec5ff8960" alt="Speediness output in the menu bar" width="230">

You will need the [One Thing](https://sindresorhus.com/one-thing) and [Shortery](https://apps.apple.com/app/id1594183810) app.

Add [this shortcut](https://www.icloud.com/shortcuts/d073ad4fd89f4c9cb110795780ed2377) and then create a new time trigger in Shortery. I would recommend an interval higher than 10 minutes.

Tip: If you have limited space in the menu bar, you could switch the info shown in One Thing at an interval too. For example, you could show the internet speed for 10 minutes and then the weather for the next 10 minutes.

<br>

### Frequently Asked Questions {#faq}

#### I have a feature request, bug report, or some feedback

[Send it here.](https://sindresorhus.com/feedback?product=Speediness&referrer=Website-FAQ)

#### Why does it show different result from other tools? {#different-result}

By default, tests are run in parallel to better reflect real-world situations (video chat and voice calls). Because of this, speeds may differ from other tools. You can change this in the settings.

#### How does it compare to Speedtest by Ookla? {#ookla}

The Speedtest app uses a nearby server, which means the speed does not reflect real-world usage — it shows the most optimal scenario. Its requests are also often prioritized by ISPs, which skews the numbers even more. Speediness also looks more like a proper macOS app and it has support for Shortcuts.

#### How does it compare to fast.com? {#fast}

The problem with fast.com is that it's run by Netflix, and Netflix's servers are often prioritized (and sometimes throttled), meaning you won't always get a realistic value. It pretty much gives you your speed for watching Netflix.

#### What does the responsiveness (RPM) value mean?

It's a measurement called Round-trips Per Minute (RPM) — the number of sequential round-trips a network can do in one minute under normal working conditions.

[Learn more](https://support.apple.com/en-gb/HT212313)

#### What does the ping value mean?

It's a measurement of the round-trip time for messages sent from the originating host to a destination computer that are echoed back to the source. `ms` is the symbol for milliseconds.

[Learn more](https://xtrium.com/what-is-a-good-ping-speed/)

#### Why should I trust the results?

The app makes use of the built-in [`networkQuality` command-line tool](https://support.apple.com/en-gb/HT212313) under the hood, which is provided by Apple.

#### Can it show the current speed live as it calculates it?

This is not possible as it's not provided by the macOS tool Speediness uses to get the speed.

I have sent a [feature request to Apple](https://github.com/feedback-assistant/reports/issues/346) about it and I encourage you [to do the same](https://www.apple.com/feedback/macos.html). Feel free to copy-paste my report.

#### How can I run it from the menu bar?

Open the Shortcuts app, create a new shortcut, and then drag the “Get Internet Speed” action into the shortcut editor. Enable the “Pin in Menu Bar” shortcut setting. You can now run speed tests directly from the Shortcuts icon in the menu bar.

#### How can I run the speed test automatically every hour? {#scheduled}

Open the Shortcuts app, create a new shortcut, and then drag the “Get Internet Speed” action into the shortcut editor. You may want to enable the “Add to History” action setting. [Get the Shortery app](https://apps.apple.com/no/app/shortery/id1594183810?mt=12) and set it to run this shortcut every hour or at an interval of your choosing.

#### Can you add support for iOS? {#ios}

This is unfortunately not possible at this time as the app relies on the built-in [`networkQuality` command-line tool](https://support.apple.com/en-gb/HT212313), which does not exist on iOS. Someone would have to implement the [“Responsiveness under Working Conditions” RFC](https://github.com/network-quality/draft-ietf-ippm-responsiveness/blob/master/draft-ietf-ippm-responsiveness.txt) in Swift. [Reference implementation in Go.](https://github.com/network-quality/goresponsiveness) Let me know if you end up making a Swift package for this.

#### Is the app native?

Yes, it's native and written in Swift and SwiftUI.

#### Why is this free without ads?

I just enjoy making Mac apps. Consider leaving a nice review on the App Store.

#### Where can I find the changelog?

Go [here](https://apps.apple.com/app/id1596706466) and click “Version History”.

#### Can you localize the app into my language?

I don't plan to localize the app.

#### [More FAQs…](/apps/faq)

<br>

### Older Versions

- [1.6.1](https://github.com/sindresorhus/meta/files/13965129/Speediness.1.6.1.-.macOS.13.zip) for macOS 13+
- [1.5.0](https://github.com/sindresorhus/meta/files/10847708/Speediness.1.5.0.-.macOS.12.zip) for macOS 12+

<br>

### Non-App Store Version

A special version for users that cannot access the App Store. It won't receive automatic updates. I will update it here once a year.

[Download](https://www.dropbox.com/scl/fi/fz7g9b5zjuvj0jehefuuv/Speediness-1.7.0-1705505161.zip?rlkey=d1otns1la8mygh2a4uebb08pg&raw=1) *(1.7.0)*

*Requires macOS 14 or later*
