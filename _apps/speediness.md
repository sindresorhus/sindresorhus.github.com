---
title: Speediness
subtitle: Check your internet speed
date: 2021-11-23
platforms:
  - macOS
app_store_app_id: 1596706466
mac_app_store_url: https://apps.apple.com/app/id1596706466
---

<br>

<h3 id="faq">Frequently Asked Questions</h3>

#### I have a feature request, bug report, or some feedback

[Send it here.](https://sindresorhus.com/feedback/?product=Speediness&referrer=Website-FAQ)

<a id="different-result"></a>
#### Why does it show different result from other tools?

By default, tests are run in parallel to better reflect real-world situations (video chat and voice calls). Because of this, speeds may differ from other tools. You can change this in the preferences.

<a id="ookla"></a>
#### How does it compare to Speedtest by Ookla?

The Speedtest app uses a nearby server, which means the speed does not reflect real-world usage — it shows the most optimal scenario. Its requests are also often prioritized by ISPs, which skews the numbers even more. Speediness also looks more like a proper macOS app and it has support for Shortcuts.

<a id="fast"></a>
#### How does it compare to fast.com?

The problem with fast.com is that it's run by Netflix, and Netflix's servers are often prioritized (and sometimes throttled), meaning you won't always get a realistic value. It pretty much gives you your speed for watching Netflix.

#### Why should I trust the results?

The app makes use of the built-in [`networkQuality` command-line tool](https://support.apple.com/en-gb/HT212313) under the hood, which is provided by Apple.

#### How can I run it from the menu bar?

Open the Shortcuts app, create a new shortcut, and then drag the “Get Internet Speed” action into the shortcut editor. Enable the “Pin in Menu Bar” shortcut setting. You can now run speed tests directly from the Shortcuts icon in the menu bar.

<a id="scheduled"></a>
#### How can I run the speed test automatically every hour?

Open the Shortcuts app, create a new shortcut, and then drag the “Get Internet Speed” action into the shortcut editor. You may want to enable the “Add to History” action setting. [Get the Shortery app](https://apps.apple.com/no/app/shortery/id1594183810?mt=12) and set it to run this shortcut every hour or at an interval of your choosing. (The Shortery app is only needed this year. It's almost certain that Apple will introduce automation for Shortcuts in macOS 13)

#### Can it show the current speed live as it calculates it?

This is not possible as it's not provided by the tool Speediness uses to get the speed.

<a id="ios"></a>
#### Can you add support for iOS?

This is unfortunately not possible at this time as the app relies on the built-in [`networkQuality` command-line tool](https://support.apple.com/en-gb/HT212313), which does not exist on iOS. Someone would have to reverse-engineer `networkQuality` for me to be able to support iOS.

#### Is the app native?

Yes, it's native and written in Swift and SwiftUI.

#### Why is this free without ads?

I just enjoy making Mac apps. Consider leaving a nice review on the App Store.

#### Where can I find the changelog?

Go [here](https://apps.apple.com/app/id1596706466) and click “Version History”.

#### Can you localize the app into my language?

I don't have any immediate plans to localize the app.
