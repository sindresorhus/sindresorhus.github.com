---
title: Battery Indicator
subtitle: Remaining battery time in your menu bar
pubDate: 2017-02-18
platforms:
  - macOS
appStoreId: 1206020918
isPaid: true
isMenuBarApp: true
hasSentry: true
olderMacOSVersions:
  - '10.14'
  - '10.15'
  - '11'
  - '12'
  - '13'
  - '14'
---

Quickly glance the remaining battery time or percentage right in your menu bar.

## Frequently Asked Questions {#faq}

#### I have a feature request, bug report, or some feedback

Click the feedback button in the app or [send it here.](https://sindresorhus.com/feedback?product=Battery%20Indicator&referrer=Website-FAQ)

#### The app does not show up in the menu bar

[Try this](/apps/faq#app-not-showing-in-menu-bar)

You may also have enabled the “Hide while on power” preference, which hides the menu bar icon while the power adapter is connected. Launch the app again to reveal the menu bar item for 5 seconds or disconnect the power adapter.

#### The estimated time left is incorrect

The number comes from macOS and the app has no control over it.

#### The menu bar icon is vertically stretched when shown on a secondary display

This is a macOS 11 bug. I have tried to work around this issue, but it's out of my control.

#### Why does the menu bar icon show `…` when I unplug the power adapter?

The system needs some time to accurately calculate the time remaining estimate.

#### How do I remove the system battery menu bar item?

Drag it out of the menu bar while pressing <kbd>Command</kbd>.

#### Can it show “apps using significant energy” like the built-in battery indicator?

It can unfortunately not show this because of restrictions ([sandboxing](/apps/faq#macos-sandbox)) imposed on apps on the App Store. However, you could change the menu bar item type to text instead of the icon and use this app in combination with the system battery indicator.

#### Can it have a “charge to full now” button?

This is not possible for the same reason as mentioned above.

#### Can it play a sound when the battery is charged a certain percentage? {#notification-sound}

The app has a built-in sound when showing notifications. However, if you want a different sound, you can disable the default notification sound in the “Notification Settings” and then follow the below steps.

This is a perfect use case for the built-in Shortcuts app. You can use the `Play Sound` action to play the sound you want. To run the shortcut when the battery is at a certain percentage, you need the [Shortery app](https://apps.apple.com/app/id1594183810). Use its “Power Status” trigger.

You can find sound effects [here](https://pixabay.com/sound-effects/search/interface/).

#### Can the battery icon hide when the battery is charged a certain percentage?

This is a perfect use case for the built-in Shortcuts app. Create a shortcut that quits the app and one that launches it. To run the shortcut when the battery is at a certain percentage, you need the [Shortery app](https://apps.apple.com/app/id1594183810). Use its “Power Status” trigger.

#### [More FAQs…](/apps/faq)

## Older Versions

- [2.18.0](https://github.com/user-attachments/files/19015442/Battery.Indicator.2.18.0.-.macOS.14.zip) for macOS 14
- [2.16.1](https://github.com/sindresorhus/meta/files/13942534/Battery.Indicator.2.16.1.-.macOS.13.zip) for macOS 13
- [2.14.2](https://github.com/sindresorhus/meta/files/10759031/Battery.Indicator.2.14.2.-.macOS.12.zip) for macOS 12
- [2.12.3](https://github.com/sindresorhus/meta/files/8759816/Battery.Indicator.2.12.3.-.macOS.11.zip) for macOS 11
- [2.7.1](https://github.com/sindresorhus/meta/files/6565005/Battery.Indicator.2.7.1.-.macOS.10.15.zip) for macOS 10.15
- [2.1.0](https://github.com/sindresorhus/meta/files/4127047/Battery-Indicator-2.1.0-Mojave.zip) for macOS 10.14

These are free for everyone but they will not run on newer macOS versions.
