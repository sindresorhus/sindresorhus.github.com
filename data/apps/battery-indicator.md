---
title: Battery Indicator
subtitle: Remaining battery time in your menu bar
description:
date: 2017-02-18
platforms:
  - macOS
isPaid: true
appStoreId: 1206020918
---

Battery Indicator lets you quickly glance the remaining battery time or percentage right in your menu bar.

<sup>**Want to see this app included in [Setapp](https://setapp.com)?** Help make it happen by [requesting it here](https://support.setapp.com/hc/en-us/articles/213780569-Can-I-suggest-an-app-).</sup>

<br>

### Frequently Asked Questions {#faq}

#### I have a feature request, bug report, or some feedback

[Send it here.](https://sindresorhus.com/feedback?product=Battery%20Indicator&referrer=Website-FAQ)

#### The app does not show up in the menu bar

macOS hides menu bar apps when there is no space left in the menu bar. This is a common problem on MacBooks with a notch. Try quitting some menu bar apps to free up space. If this does not solve it, try quitting Bartender if you have it installed.

You may also have enabled the “Hide while on power” preference, which hides the menu bar icon while the power adapter is connected. Launch the app again to reveal the menu bar item for 5 seconds or disconnect the power adapter.

#### The menu bar icon is vertically stretched when shown on a secondary display

This is a macOS 11 bug. I have tried to work around this issue, but it's out of my control.

#### Why does the menu bar icon show `…` when I unplug the power adapter?

The system needs some time to accurately calculate the time remaining estimate.

#### Can it show “apps using significant energy” like the built-in battery indicator?

It can unfortunately not show this because of restrictions (sandboxing) imposed on apps on the App Store. However, you could change the menu bar item type to text instead of icon and use this app in combination with the system battery indicator.

#### How can I export, import, sync, or backup the settings?

[See this guide.](https://github.com/sindresorhus/guides/blob/main/backup-app-settings.md)

#### Where can I find the changelog?

Go [here](https://apps.apple.com/app/id1206020918) and click “Version History”.

#### Can you localize the app into my language?

I don't have any immediate plans to localize the app.

<br>

### Older Versions

- [Last macOS 11 compatible version (free)](https://github.com/sindresorhus/meta/files/8759816/Battery.Indicator.2.12.3.-.macOS.11.zip) *(2.12.3)*
- [Last macOS 10.15 compatible version (free)](https://github.com/sindresorhus/meta/files/6565005/Battery.Indicator.2.7.1.-.macOS.10.15.zip) *(2.7.1)*
- [Last macOS 10.14 compatible version (free)](https://github.com/sindresorhus/meta/files/4127047/Battery-Indicator-2.1.0-Mojave.zip) *(2.1.0)*

*(These builds will not run on newer macOS versions)*
